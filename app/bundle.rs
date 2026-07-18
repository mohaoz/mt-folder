use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::LazyLock;

use anyhow::{Context, Result, bail};
use regex::Regex;

use crate::library::GENERATED_BANNER;

static INCLUDE_RE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r#"^\s*#\s*include\s*(?:<([^>]+)>|"([^"]+)")\s*(?://.*|/\*.*\*/)?\s*$"#).unwrap()
});
static PRAGMA_ONCE_RE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^\s*#\s*pragma\s+once\s*(?://.*)?$").unwrap());
static CONDITIONAL_START_RE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^\s*#\s*(?:if|ifdef|ifndef)\b").unwrap());
static CONDITIONAL_END_RE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^\s*#\s*endif\b").unwrap());

pub struct Bundler {
    include_dir: PathBuf,
    prefix: String,
    expanded: HashSet<PathBuf>,
    active: Vec<PathBuf>,
}

impl Bundler {
    pub fn new(include_dir: &Path, prefix: &str) -> Result<Self> {
        let include_dir = include_dir.canonicalize().with_context(|| {
            format!(
                "include directory does not exist: {}",
                include_dir.display()
            )
        })?;
        if !include_dir.is_dir() {
            bail!("include path is not a directory: {}", include_dir.display());
        }
        let prefix = prefix.trim_matches('/');
        if prefix.is_empty() || prefix.contains("..") || prefix.contains('\\') {
            bail!("invalid internal include prefix: {prefix}");
        }
        Ok(Self {
            include_dir,
            prefix: format!("{prefix}/"),
            expanded: HashSet::new(),
            active: Vec::new(),
        })
    }

    pub fn bundle(&mut self, source: &str, source_path: &Path) -> Result<String> {
        self.expand_text(source, source_path, true)
    }

    fn expand_file(&mut self, path: &Path) -> Result<String> {
        let path = path
            .canonicalize()
            .with_context(|| format!("internal header does not exist: {}", path.display()))?;
        if self.expanded.contains(&path) {
            return Ok(String::new());
        }
        if let Some(index) = self.active.iter().position(|active| active == &path) {
            let mut cycle = self.active[index..]
                .iter()
                .map(|item| item.display().to_string())
                .collect::<Vec<_>>();
            cycle.push(path.display().to_string());
            bail!("cyclic internal include: {}", cycle.join(" -> "));
        }

        let source = fs::read_to_string(&path)
            .with_context(|| format!("cannot read internal header {}", path.display()))?;
        self.active.push(path.clone());
        let result = self.expand_text(&source, &path, false);
        self.active.pop();
        let expanded = result?;
        self.expanded.insert(path);
        Ok(expanded)
    }

    fn expand_text(&mut self, source: &str, source_path: &Path, is_root: bool) -> Result<String> {
        let mut output = String::new();
        let mut conditional_depth = 0usize;

        for (line_index, line) in source.split_inclusive('\n').enumerate() {
            let directive = line
                .strip_suffix('\n')
                .unwrap_or(line)
                .strip_suffix('\r')
                .unwrap_or_else(|| line.strip_suffix('\n').unwrap_or(line));

            if CONDITIONAL_START_RE.is_match(directive) {
                conditional_depth += 1;
                output.push_str(line);
                continue;
            }
            if CONDITIONAL_END_RE.is_match(directive) {
                conditional_depth = conditional_depth.saturating_sub(1);
                output.push_str(line);
                continue;
            }
            if !is_root
                && (PRAGMA_ONCE_RE.is_match(directive) || directive == GENERATED_BANNER.trim_end())
            {
                continue;
            }

            let Some(captures) = INCLUDE_RE.captures(directive) else {
                output.push_str(line);
                continue;
            };
            let include = captures
                .get(1)
                .or_else(|| captures.get(2))
                .unwrap()
                .as_str();
            if !include.starts_with(&self.prefix) {
                output.push_str(line);
                continue;
            }
            if conditional_depth != 0 {
                bail!(
                    "{}:{}: conditional internal includes are not supported",
                    source_path.display(),
                    line_index + 1
                );
            }

            let header = self.resolve_internal(include, source_path, line_index + 1)?;
            let expanded = self.expand_file(&header)?;
            if !expanded.is_empty() {
                output.push_str(&expanded);
                if !expanded.ends_with('\n') {
                    output.push('\n');
                }
            }
        }
        Ok(output)
    }

    fn resolve_internal(&self, include: &str, source: &Path, line: usize) -> Result<PathBuf> {
        if include.contains('\\') || include.split('/').any(|part| part == "..") {
            bail!(
                "{}:{line}: internal include escapes include root: {include}",
                source.display()
            );
        }
        let unresolved = self.include_dir.join(include);
        let resolved = unresolved.canonicalize().with_context(|| {
            format!(
                "{}:{line}: internal header not found: {include}",
                source.display()
            )
        })?;
        if !resolved.starts_with(&self.include_dir) || !resolved.is_file() {
            bail!(
                "{}:{line}: internal include escapes include root: {include}",
                source.display()
            );
        }
        Ok(resolved)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    fn fixture() -> (tempfile::TempDir, PathBuf) {
        let directory = tempdir().unwrap();
        let include = directory.path().join("include");
        fs::create_dir_all(include.join("mtf")).unwrap();
        fs::write(
            include.join("mtf/prelude.hpp"),
            format!("{GENERATED_BANNER}#pragma once\n#include <vector>\nusing i64 = long long;\n"),
        )
        .unwrap();
        fs::write(
            include.join("mtf/a.hpp"),
            format!("{GENERATED_BANNER}#pragma once\n#include <mtf/prelude.hpp>\nstruct A {{}};\n"),
        )
        .unwrap();
        (directory, include)
    }

    #[test]
    fn expands_once_without_generator_noise() {
        let (_directory, include) = fixture();
        let mut bundler = Bundler::new(&include, "mtf").unwrap();
        let source = "#include <mtf/a.hpp>\n#include <mtf/a.hpp>\nint main() {}\n";
        let output = bundler.bundle(source, Path::new("main.cpp")).unwrap();
        assert_eq!(output.matches("struct A").count(), 1);
        assert!(!output.contains("Generated by mtf"));
        assert!(!output.contains("#pragma once"));
        assert!(!output.contains("#include <mtf/"));
        assert!(output.contains("#include <vector>"));
    }

    #[test]
    fn rejects_conditional_internal_include() {
        let (_directory, include) = fixture();
        let mut bundler = Bundler::new(&include, "mtf").unwrap();
        let source = "#ifdef X\n#include <mtf/a.hpp>\n#endif\n";
        assert!(bundler.bundle(source, Path::new("main.cpp")).is_err());
    }

    #[test]
    fn rejects_cycles() {
        let (_directory, include) = fixture();
        fs::write(
            include.join("mtf/a.hpp"),
            "#pragma once\n#include <mtf/b.hpp>\n",
        )
        .unwrap();
        fs::write(
            include.join("mtf/b.hpp"),
            "#pragma once\n#include <mtf/a.hpp>\n",
        )
        .unwrap();
        let mut bundler = Bundler::new(&include, "mtf").unwrap();
        assert!(
            bundler
                .bundle("#include <mtf/a.hpp>\n", Path::new("main.cpp"))
                .is_err()
        );
    }
}
