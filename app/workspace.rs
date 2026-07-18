use std::collections::HashSet;
use std::ffi::OsString;
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};
use std::time::UNIX_EPOCH;

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use tempfile::{Builder, tempdir};

use crate::io_util::{absolute, atomic_write, find_parent_with};
use crate::library::{
    Snapshot, embedded_snapshot, live_snapshot, resolve_library_root, sync_header_set,
};

const CONFIG_FILE: &str = "mtf.toml";
const SNAPSHOT_INCLUDE: &str = ".mtf/include/mtf";
const CPP_STARTER: &str = ".mtf/starter.cpp";
const PCH_CACHE_VERSION: u32 = 1;
const BUILD_CACHE_VERSION: u32 = 1;
const PCH_SOURCE: &str = "#pragma once\n#include <bits/stdc++.h>\n";

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
struct FileStamp {
    path: PathBuf,
    len: u64,
    modified_secs: u64,
    modified_nanos: u32,
}

#[derive(Debug, Deserialize, Serialize)]
struct PchManifest {
    profile: PchProfile,
    dependencies: Vec<FileStamp>,
}

#[derive(Debug, Deserialize, Eq, PartialEq, Serialize)]
struct PchProfile {
    version: u32,
    compiler: String,
    standard: String,
    flags: Vec<String>,
    identity: Vec<u8>,
    executable: Option<FileStamp>,
    source: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct BuildDependency {
    path: PathBuf,
    digest: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct BuildManifest {
    version: u32,
    signature: String,
    source: PathBuf,
    output_digest: String,
    dependencies: Vec<BuildDependency>,
    pch_dependencies: Vec<FileStamp>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct WorkspaceConfig {
    #[serde(default = "config_version")]
    pub version: u32,
    #[serde(default)]
    pub cpp: CppConfig,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CppConfig {
    #[serde(default = "default_compiler")]
    pub compiler: String,
    #[serde(default = "default_standard")]
    pub standard: String,
    #[serde(default = "default_flags")]
    pub flags: Vec<String>,
}

impl Default for WorkspaceConfig {
    fn default() -> Self {
        Self {
            version: config_version(),
            cpp: CppConfig::default(),
        }
    }
}

impl Default for CppConfig {
    fn default() -> Self {
        Self {
            compiler: default_compiler(),
            standard: default_standard(),
            flags: default_flags(),
        }
    }
}

fn config_version() -> u32 {
    1
}

fn default_compiler() -> String {
    "g++".to_owned()
}

fn default_standard() -> String {
    "gnu++23".to_owned()
}

fn default_flags() -> Vec<String> {
    ["-pipe", "-Wall", "-Wextra"]
        .into_iter()
        .map(str::to_owned)
        .collect()
}

pub fn resolve_workspace_root(explicit: Option<&Path>, start: &Path) -> Result<PathBuf> {
    let root = match explicit {
        Some(path) => absolute(path)?,
        None => find_parent_with(start, CONFIG_FILE)?,
    };
    if !root.join(CONFIG_FILE).is_file() {
        bail!(
            "{} is not an MTF contest workspace ({CONFIG_FILE} missing)",
            root.display()
        );
    }
    Ok(root)
}

pub fn find_workspace_root(start: &Path) -> Option<PathBuf> {
    find_parent_with(start, CONFIG_FILE).ok()
}

pub fn load_config(root: &Path) -> Result<WorkspaceConfig> {
    let path = root.join(CONFIG_FILE);
    let source = fs::read_to_string(&path)
        .with_context(|| format!("cannot read workspace config {}", path.display()))?;
    let config: WorkspaceConfig = toml::from_str(&source)
        .with_context(|| format!("cannot parse workspace config {}", path.display()))?;
    if config.version != config_version() {
        bail!(
            "unsupported mtf.toml version {}; expected {}",
            config.version,
            config_version()
        );
    }
    if config.cpp.compiler.is_empty() || config.cpp.standard.is_empty() {
        bail!("workspace compiler and standard must not be empty");
    }
    Ok(config)
}

pub fn initialize(
    path: &Path,
    compiler: String,
    standard: String,
    flags: Vec<String>,
    library: Option<&Path>,
    force: bool,
) -> Result<PathBuf> {
    fs::create_dir_all(path)
        .with_context(|| format!("cannot create workspace directory {}", path.display()))?;
    let root = path
        .canonicalize()
        .with_context(|| format!("cannot resolve workspace directory {}", path.display()))?;

    let owned = [CONFIG_FILE, ".clangd", "compile_flags.txt", "mtf.lock"];
    if !force {
        let conflicts = owned
            .iter()
            .map(|name| root.join(name))
            .filter(|path| path.exists())
            .collect::<Vec<_>>();
        if !conflicts.is_empty() {
            let names = conflicts
                .iter()
                .map(|path| format!("  {}", path.display()))
                .collect::<Vec<_>>()
                .join("\n");
            bail!("refusing to replace existing workspace files:\n{names}");
        }
    }

    let config = WorkspaceConfig {
        version: config_version(),
        cpp: CppConfig {
            compiler,
            standard,
            flags: if flags.is_empty() {
                default_flags()
            } else {
                flags
            },
        },
    };
    let snapshot = select_snapshot(library)?;
    write_workspace(&root, &config, &snapshot)?;
    eprintln!("initialized MTF workspace in {}", root.display());
    Ok(root)
}

pub fn update(root: &Path, library: Option<&Path>) -> Result<()> {
    let config = load_config(root)?;
    let snapshot = select_snapshot(library)?;
    write_workspace(root, &config, &snapshot)?;
    eprintln!("updated MTF workspace in {}", root.display());
    Ok(())
}

fn select_snapshot(library: Option<&Path>) -> Result<Snapshot> {
    match library {
        Some(path) => {
            let root = resolve_library_root(Some(path))?;
            live_snapshot(&root)
        }
        None => embedded_snapshot(),
    }
}

fn write_workspace(root: &Path, config: &WorkspaceConfig, snapshot: &Snapshot) -> Result<()> {
    let starter = snapshot.starter("cpp")?;
    let config_text = toml::to_string_pretty(config).context("cannot serialize mtf.toml")?;
    atomic_write(&root.join(CONFIG_FILE), config_text.as_bytes())?;
    atomic_write(&root.join(".clangd"), clangd_config(config).as_bytes())?;
    atomic_write(
        &root.join("compile_flags.txt"),
        compile_flags(config).as_bytes(),
    )?;
    ensure_gitignore(root)?;

    let include_root = root.join(SNAPSHOT_INCLUDE);
    sync_header_set(&include_root, &snapshot.headers, false)?;
    atomic_write(&root.join(CPP_STARTER), starter.as_bytes())?;
    atomic_write(&root.join("mtf.lock"), snapshot_lock(snapshot).as_bytes())?;
    Ok(())
}

fn clangd_config(config: &WorkspaceConfig) -> String {
    let compiler = serde_json::to_string(&config.cpp.compiler).unwrap();
    format!("CompileFlags:\n  Compiler: {compiler}\n")
}

fn compile_flags(config: &WorkspaceConfig) -> String {
    let mut output = format!("-std={}\n-I.mtf/include\n", config.cpp.standard);
    for flag in &config.cpp.flags {
        output.push_str(flag);
        output.push('\n');
    }
    output
}

fn ensure_gitignore(root: &Path) -> Result<()> {
    let path = root.join(".gitignore");
    let mut source = match fs::read_to_string(&path) {
        Ok(source) => source,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => String::new(),
        Err(error) => {
            return Err(error).with_context(|| format!("cannot read {}", path.display()));
        }
    };
    if !source.is_empty() && !source.ends_with('\n') {
        source.push('\n');
    }
    for entry in ["/.mtf/", "*.submit.cpp"] {
        if !source.lines().any(|line| line == entry) {
            source.push_str(entry);
            source.push('\n');
        }
    }
    atomic_write(&path, source.as_bytes())
}

fn snapshot_lock(snapshot: &Snapshot) -> String {
    let mut hash = 0xcbf29ce484222325u64;
    for header in &snapshot.headers {
        update_hash(&mut hash, header.path.as_bytes());
        update_hash(&mut hash, &[0]);
        update_hash(&mut hash, header.content.as_bytes());
    }
    for starter in &snapshot.starters {
        update_hash(&mut hash, starter.language.as_bytes());
        update_hash(&mut hash, &[0]);
        update_hash(&mut hash, starter.content.as_bytes());
    }
    format!(
        "version = 1\nmtf_version = {:?}\nsnapshot = \"fnv1a64:{hash:016x}\"\n",
        env!("CARGO_PKG_VERSION")
    )
}

fn update_hash(hash: &mut u64, bytes: &[u8]) {
    for byte in bytes {
        *hash ^= u64::from(*byte);
        *hash = hash.wrapping_mul(0x100000001b3);
    }
}

pub fn create_sources(root: &Path, names: &[String]) -> Result<()> {
    let starter_path = root.join(CPP_STARTER);
    let starter = fs::read(&starter_path).with_context(|| {
        format!(
            "workspace starter is missing; run `mtf update` ({})",
            starter_path.display()
        )
    })?;
    let mut destinations = Vec::new();
    let mut unique = HashSet::new();
    for name in names {
        let destination = source_path(root, name)?;
        if destination.exists() {
            bail!(
                "refusing to replace existing source {}",
                destination.display()
            );
        }
        if !unique.insert(destination.clone()) {
            bail!("duplicate contest source name: {name}");
        }
        destinations.push(destination);
    }
    for destination in destinations {
        atomic_write(&destination, &starter)?;
        eprintln!("created {}", destination.display());
    }
    Ok(())
}

fn source_path(root: &Path, name: &str) -> Result<PathBuf> {
    let path = Path::new(name);
    if path.is_absolute()
        || path.components().count() != 1
        || !matches!(path.components().next(), Some(Component::Normal(_)))
    {
        bail!("problem name must be a single relative filename: {name}");
    }
    let file = if path.extension().is_none() {
        format!("{name}.cpp")
    } else if path.extension().and_then(|value| value.to_str()) == Some("cpp") {
        name.to_owned()
    } else {
        bail!("contest source must have the .cpp suffix: {name}");
    };
    Ok(root.join(file))
}

pub fn compile_source(root: &Path, source: &Path, output: Option<&Path>) -> Result<PathBuf> {
    compile_source_impl(root, source, output, false)
}

fn compile_source_impl(
    root: &Path,
    source: &Path,
    output: Option<&Path>,
    reuse: bool,
) -> Result<PathBuf> {
    let config = load_config(root)?;
    ensure_snapshot(root)?;
    let source = absolute(source)?;
    if !source.is_file() {
        bail!("source file does not exist: {}", source.display());
    }
    let cacheable = output.is_none();
    let output = match output {
        Some(path) => absolute(path)?,
        None => {
            let stem = source
                .file_stem()
                .ok_or_else(|| anyhow::anyhow!("source has no filename"))?;
            root.join(".mtf/bin").join(stem)
        }
    };
    if source == output {
        bail!("refusing to overwrite the input source file");
    }
    if let Some(parent) = output.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("cannot create output directory {}", parent.display()))?;
    }

    let signature = cacheable
        .then(|| build_signature(root, &config))
        .transpose()?;
    let manifest_path = build_manifest_path(&output);
    if reuse
        && output.is_file()
        && signature
            .as_deref()
            .is_some_and(|value| build_is_reusable(&manifest_path, value, &source, &output))
    {
        eprintln!("reused {}", output.display());
        return Ok(output);
    }

    if cacheable {
        match fs::remove_file(&manifest_path) {
            Ok(()) => {}
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => {
                return Err(error)
                    .with_context(|| format!("cannot remove {}", manifest_path.display()));
            }
        }
    }

    let parent = output
        .parent()
        .ok_or_else(|| anyhow::anyhow!("compiler output has no parent directory"))?;
    let temporary_binary = Builder::new()
        .prefix(".mtf-bin-")
        .tempfile_in(parent)
        .with_context(|| format!("cannot create temporary output in {}", parent.display()))?
        .into_temp_path();
    let depfile = cacheable
        .then(|| {
            Builder::new()
                .prefix(".mtf-deps-")
                .tempfile_in(parent)
                .with_context(|| {
                    format!(
                        "cannot create temporary dependency file in {}",
                        parent.display()
                    )
                })
                .map(|file| file.into_temp_path())
        })
        .transpose()?;
    let pch_include = pch_include_or_warn(&config, root);
    let mut command = compiler_command(&config, Some(root), pch_include.as_deref());
    if let Some(depfile) = depfile.as_deref() {
        command.arg("-MD").arg("-MF").arg(depfile);
    }
    let status = command
        .arg(&source)
        .arg("-o")
        .arg(&temporary_binary)
        .status()
        .with_context(|| format!("cannot execute compiler {}", config.cpp.compiler))?;
    require_success(status, "C++ compilation")?;

    let dependencies = depfile
        .as_deref()
        .map(|path| parse_depfile(path, root).and_then(|paths| build_dependencies(paths, &source)));
    fs::rename(&temporary_binary, &output)
        .with_context(|| format!("cannot persist compiler output {}", output.display()))?;
    if let (Some(signature), Some(dependencies)) = (signature, dependencies) {
        match dependencies.and_then(|dependencies| {
            digest_file(&output).map(|output_digest| (dependencies, output_digest))
        }) {
            Ok((dependencies, output_digest)) => {
                let manifest = BuildManifest {
                    version: BUILD_CACHE_VERSION,
                    signature,
                    source: source.clone(),
                    output_digest,
                    dependencies,
                    pch_dependencies: load_pch_dependencies(pch_include.as_deref()),
                };
                match serde_json::to_vec(&manifest)
                    .context("cannot serialize build cache manifest")
                    .and_then(|bytes| atomic_write(&manifest_path, &bytes))
                {
                    Ok(()) => {}
                    Err(error) => {
                        eprintln!("mtf: warning: cannot save the build cache: {error:#}");
                    }
                }
            }
            Err(error) => {
                eprintln!("mtf: warning: cannot cache this build: {error:#}");
            }
        }
    }
    eprintln!("wrote {}", output.display());
    Ok(output)
}

pub fn run_source(root: &Path, source: &Path, arguments: &[OsString]) -> Result<()> {
    let binary = compile_source_impl(root, source, None, true)?;
    let status = Command::new(&binary)
        .args(arguments)
        .status()
        .with_context(|| format!("cannot execute {}", binary.display()))?;
    require_success(status, "program")
}

pub fn check_source(
    bytes: &[u8],
    workspace_root: Option<&Path>,
    compiler_override: Option<&str>,
    standard_override: Option<&str>,
) -> Result<()> {
    let mut config = match workspace_root {
        Some(root) => load_config(root)?,
        None => WorkspaceConfig::default(),
    };
    if let Some(compiler) = compiler_override {
        config.cpp.compiler = compiler.to_owned();
    }
    if let Some(standard) = standard_override {
        config.cpp.standard = standard.to_owned();
    }

    let temporary = tempdir().context("cannot create temporary check directory")?;
    let source = temporary.path().join("submission.cpp");
    fs::write(&source, bytes).context("cannot write temporary submission source")?;
    let pch_include = workspace_root.and_then(|root| pch_include_or_warn(&config, root));
    let status = compiler_command(&config, workspace_root, pch_include.as_deref())
        .arg("-fsyntax-only")
        .arg(&source)
        .status()
        .with_context(|| format!("cannot execute compiler {}", config.cpp.compiler))?;
    require_success(status, "C++ check")
}

pub fn warm_pch(root: &Path) -> Result<()> {
    let config = load_config(root)?;
    let _ = pch_include_or_warn(&config, root);
    Ok(())
}

fn compiler_command(
    config: &WorkspaceConfig,
    root: Option<&Path>,
    pch_include: Option<&Path>,
) -> Command {
    let mut command = Command::new(&config.cpp.compiler);
    command.arg(format!("-std={}", config.cpp.standard));
    command.args(&config.cpp.flags);
    if let Some(include) = pch_include {
        command.arg(format!("-I{}", include.display()));
    }
    if let Some(root) = root {
        command
            .arg(format!("-I{}", root.join(".mtf/include").display()))
            .current_dir(root);
    }
    command
}

fn pch_include_or_warn(config: &WorkspaceConfig, root: &Path) -> Option<PathBuf> {
    match prepare_pch(config, root) {
        Ok(include) => include,
        Err(error) => {
            eprintln!("mtf: warning: cannot use the precompiled header: {error:#}");
            None
        }
    }
}

fn prepare_pch(config: &WorkspaceConfig, root: &Path) -> Result<Option<PathBuf>> {
    if pch_is_disabled(config) {
        return Ok(None);
    }

    let macros = Command::new(&config.cpp.compiler)
        .args(["-dM", "-E", "-x", "c++", "-"])
        .current_dir(root)
        .stdin(Stdio::null())
        .output()
        .with_context(|| format!("cannot inspect compiler {}", config.cpp.compiler))?;
    if !macros.status.success() {
        return Ok(None);
    }
    let macros = String::from_utf8_lossy(&macros.stdout);
    if !macros.contains("#define __GNUC__ ") || macros.contains("#define __clang__ ") {
        return Ok(None);
    }

    let version = Command::new(&config.cpp.compiler)
        .arg("--version")
        .current_dir(root)
        .stdin(Stdio::null())
        .output()
        .with_context(|| format!("cannot inspect compiler {}", config.cpp.compiler))?;
    if !version.status.success() {
        return Ok(None);
    }
    let mut identity = version.stdout;
    identity.extend_from_slice(&version.stderr);
    let target = Command::new(&config.cpp.compiler)
        .arg("-dumpmachine")
        .current_dir(root)
        .stdin(Stdio::null())
        .output()
        .with_context(|| format!("cannot inspect compiler target for {}", config.cpp.compiler))?;
    identity.extend_from_slice(&target.stdout);
    identity.extend_from_slice(&target.stderr);

    let pch_profile = PchProfile {
        version: PCH_CACHE_VERSION,
        compiler: config.cpp.compiler.clone(),
        standard: config.cpp.standard.clone(),
        flags: config.cpp.flags.clone(),
        identity,
        executable: resolve_executable(&config.cpp.compiler, root)
            .and_then(|path| file_stamp(&path).ok()),
        source: PCH_SOURCE.to_owned(),
    };
    let profile_bytes = serde_json::to_vec(&pch_profile).context("cannot serialize PCH profile")?;

    let mut hash = 0xcbf29ce484222325u64;
    update_hash(&mut hash, &profile_bytes);

    let Some(cache_root) = pch_cache_root() else {
        return Ok(None);
    };
    let profile = cache_root.join(format!("pch/{hash:016x}"));
    let include = profile.join("include");
    let pch = include.join("bits/stdc++.h.gch");
    let manifest_path = profile.join("manifest.json");
    if pch.is_file() && pch_manifest_is_valid(&manifest_path, &pch_profile) {
        return Ok(Some(include));
    }

    eprintln!(
        "building shared C++ precompiled header at {} ...",
        pch.display()
    );
    build_pch(config, root, &profile, &pch, &manifest_path, pch_profile)?;
    eprintln!("built shared C++ precompiled header");
    Ok(Some(include))
}

fn pch_is_disabled(config: &WorkspaceConfig) -> bool {
    if std::env::var_os("MTF_PCH").is_some_and(|value| value == "0" || value == "false") {
        return true;
    }
    if ["CPATH", "CPLUS_INCLUDE_PATH", "C_INCLUDE_PATH"]
        .into_iter()
        .any(|name| std::env::var_os(name).is_some_and(|value| !value.is_empty()))
    {
        return true;
    }
    const PATH_FLAGS: &[&str] = &[
        "-I",
        "-isystem",
        "-iquote",
        "-idirafter",
        "-include",
        "-imacros",
        "-nostdinc",
        "--sysroot",
        "-isysroot",
        "-B",
    ];
    config.cpp.flags.iter().any(|flag| {
        flag.starts_with('@') || PATH_FLAGS.iter().any(|prefix| flag.starts_with(prefix))
    })
}

fn pch_cache_root() -> Option<PathBuf> {
    if let Some(path) = nonempty_env_path("MTF_CACHE_DIR") {
        return absolutize_cache_path(path);
    }
    if let Some(path) = nonempty_env_path("XDG_CACHE_HOME") {
        return absolutize_cache_path(path.join("mtf"));
    }
    if let Some(path) = nonempty_env_path("HOME") {
        return absolutize_cache_path(path.join(".cache/mtf"));
    }
    None
}

fn absolutize_cache_path(path: PathBuf) -> Option<PathBuf> {
    if path.is_absolute() {
        Some(path)
    } else {
        std::env::current_dir()
            .ok()
            .map(|current| current.join(path))
    }
}

fn nonempty_env_path(name: &str) -> Option<PathBuf> {
    std::env::var_os(name)
        .filter(|value| !value.is_empty())
        .map(PathBuf::from)
}

fn build_pch(
    config: &WorkspaceConfig,
    root: &Path,
    profile: &Path,
    pch: &Path,
    manifest_path: &Path,
    pch_profile: PchProfile,
) -> Result<()> {
    let bits = pch
        .parent()
        .ok_or_else(|| anyhow::anyhow!("precompiled header has no parent directory"))?;
    fs::create_dir_all(bits)
        .with_context(|| format!("cannot create PCH cache directory {}", bits.display()))?;
    let cache_parent = profile
        .parent()
        .ok_or_else(|| anyhow::anyhow!("PCH profile has no parent directory"))?;
    fs::create_dir_all(cache_parent)
        .with_context(|| format!("cannot create PCH cache root {}", cache_parent.display()))?;
    let temporary = Builder::new()
        .prefix(".pch-build-")
        .tempdir_in(cache_parent)
        .with_context(|| {
            format!(
                "cannot create PCH build directory in {}",
                cache_parent.display()
            )
        })?;
    let source = temporary.path().join("stdcpp.hpp");
    let depfile = temporary.path().join("dependencies.d");
    fs::write(&source, PCH_SOURCE).context("cannot write PCH source")?;
    let temporary_pch = Builder::new()
        .prefix(".stdc++.h-")
        .suffix(".gch")
        .tempfile_in(bits)
        .with_context(|| format!("cannot create temporary PCH in {}", bits.display()))?
        .into_temp_path();

    let compiler = resolve_executable(&config.cpp.compiler, root)
        .unwrap_or_else(|| PathBuf::from(&config.cpp.compiler));
    let status = Command::new(compiler)
        .arg(format!("-std={}", config.cpp.standard))
        .args(&config.cpp.flags)
        .arg("-x")
        .arg("c++-header")
        .arg("stdcpp.hpp")
        .arg("-MD")
        .arg("-MF")
        .arg(&depfile)
        .arg("-o")
        .arg(&temporary_pch)
        .current_dir(temporary.path())
        .status()
        .with_context(|| format!("cannot execute compiler {}", config.cpp.compiler))?;
    require_success(status, "precompiled-header build")?;
    if !temporary_pch.is_file() {
        bail!("compiler did not produce a precompiled header");
    }

    let source = temporary.path().join("stdcpp.hpp");
    let dependencies = parse_depfile(&depfile, temporary.path())?
        .into_iter()
        .filter(|path| path != &source)
        .map(|path| file_stamp(&path))
        .collect::<Result<Vec<_>>>()?;
    if dependencies.is_empty() {
        bail!("compiler did not report PCH dependencies");
    }
    fs::rename(&temporary_pch, pch)
        .with_context(|| format!("cannot persist precompiled header {}", pch.display()))?;
    let manifest = PchManifest {
        profile: pch_profile,
        dependencies,
    };
    let bytes = serde_json::to_vec(&manifest).context("cannot serialize PCH manifest")?;
    atomic_write(manifest_path, &bytes)?;
    Ok(())
}

fn pch_manifest_is_valid(path: &Path, profile: &PchProfile) -> bool {
    let Ok(bytes) = fs::read(path) else {
        return false;
    };
    let Ok(manifest) = serde_json::from_slice::<PchManifest>(&bytes) else {
        return false;
    };
    manifest.profile == *profile
        && !manifest.dependencies.is_empty()
        && manifest.dependencies.iter().all(file_stamp_matches)
}

fn file_stamp(path: &Path) -> Result<FileStamp> {
    let metadata = fs::metadata(path)
        .with_context(|| format!("cannot inspect dependency {}", path.display()))?;
    let modified = metadata
        .modified()
        .with_context(|| format!("cannot read modification time for {}", path.display()))?
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    Ok(FileStamp {
        path: path.to_path_buf(),
        len: metadata.len(),
        modified_secs: modified.as_secs(),
        modified_nanos: modified.subsec_nanos(),
    })
}

fn file_stamp_matches(expected: &FileStamp) -> bool {
    file_stamp(&expected.path).is_ok_and(|actual| {
        actual.len == expected.len
            && actual.modified_secs == expected.modified_secs
            && actual.modified_nanos == expected.modified_nanos
    })
}

fn build_manifest_path(output: &Path) -> PathBuf {
    let mut path = output.as_os_str().to_os_string();
    path.push(".mtf-build.json");
    PathBuf::from(path)
}

fn build_signature(root: &Path, config: &WorkspaceConfig) -> Result<String> {
    let mut hash = 0xcbf29ce484222325u64;
    update_hash(&mut hash, b"mtf-build");
    update_hash(&mut hash, &BUILD_CACHE_VERSION.to_le_bytes());
    update_hash(&mut hash, env!("CARGO_PKG_VERSION").as_bytes());
    for path in [root.join(CONFIG_FILE), root.join("mtf.lock")] {
        let bytes = fs::read(&path)
            .with_context(|| format!("cannot read build input {}", path.display()))?;
        update_hash(&mut hash, &bytes);
        update_hash(&mut hash, &[0]);
    }
    hash_compiler_file(&mut hash, &config.cpp.compiler, root);
    for name in [
        "CPATH",
        "CPLUS_INCLUDE_PATH",
        "C_INCLUDE_PATH",
        "LIBRARY_PATH",
    ] {
        update_hash(&mut hash, name.as_bytes());
        if let Some(value) = std::env::var_os(name) {
            update_hash(&mut hash, value.to_string_lossy().as_bytes());
        }
        update_hash(&mut hash, &[0]);
    }
    Ok(format!("fnv1a64:{hash:016x}"))
}

fn hash_compiler_file(hash: &mut u64, compiler: &str, root: &Path) {
    update_hash(hash, compiler.as_bytes());
    let Some(path) = resolve_executable(compiler, root) else {
        return;
    };
    update_hash(hash, path.to_string_lossy().as_bytes());
    if let Ok(stamp) = file_stamp(&path) {
        update_hash(hash, &stamp.len.to_le_bytes());
        update_hash(hash, &stamp.modified_secs.to_le_bytes());
        update_hash(hash, &stamp.modified_nanos.to_le_bytes());
    }
}

fn resolve_executable(executable: &str, root: &Path) -> Option<PathBuf> {
    let path = Path::new(executable);
    if path.components().count() > 1 {
        let candidate = if path.is_absolute() {
            path.to_path_buf()
        } else {
            root.join(path)
        };
        return candidate.canonicalize().ok();
    }
    let search = std::env::var_os("PATH")?;
    std::env::split_paths(&search).find_map(|directory| {
        let directory = if directory.is_absolute() {
            directory
        } else {
            root.join(directory)
        };
        let candidate = directory.join(executable);
        candidate
            .is_file()
            .then(|| candidate.canonicalize().ok())
            .flatten()
    })
}

fn build_is_reusable(path: &Path, signature: &str, source: &Path, output: &Path) -> bool {
    let Ok(bytes) = fs::read(path) else {
        return false;
    };
    let Ok(manifest) = serde_json::from_slice::<BuildManifest>(&bytes) else {
        return false;
    };
    manifest.version == BUILD_CACHE_VERSION
        && manifest.signature == signature
        && manifest.source == source
        && digest_file(output).is_ok_and(|digest| digest == manifest.output_digest)
        && !manifest.dependencies.is_empty()
        && manifest.pch_dependencies.iter().all(file_stamp_matches)
        && manifest.dependencies.iter().all(|dependency| {
            digest_file(&dependency.path).is_ok_and(|digest| digest == dependency.digest)
        })
}

fn load_pch_dependencies(include: Option<&Path>) -> Vec<FileStamp> {
    let Some(path) = include
        .and_then(Path::parent)
        .map(|profile| profile.join("manifest.json"))
    else {
        return Vec::new();
    };
    fs::read(path)
        .ok()
        .and_then(|bytes| serde_json::from_slice::<PchManifest>(&bytes).ok())
        .map(|manifest| manifest.dependencies)
        .unwrap_or_default()
}

fn build_dependencies(paths: Vec<PathBuf>, source: &Path) -> Result<Vec<BuildDependency>> {
    let mut paths = paths;
    if !paths.iter().any(|path| path == source) {
        paths.push(source.to_path_buf());
    }
    let mut seen = HashSet::new();
    paths
        .into_iter()
        .filter(|path| seen.insert(path.clone()))
        .map(|path| {
            Ok(BuildDependency {
                digest: digest_file(&path)?,
                path,
            })
        })
        .collect()
}

fn digest_file(path: &Path) -> Result<String> {
    let bytes = fs::read(path)
        .with_context(|| format!("cannot read build dependency {}", path.display()))?;
    let mut hash = 0xcbf29ce484222325u64;
    update_hash(&mut hash, &bytes);
    Ok(format!("fnv1a64:{hash:016x}"))
}

fn parse_depfile(path: &Path, directory: &Path) -> Result<Vec<PathBuf>> {
    let source = fs::read_to_string(path)
        .with_context(|| format!("cannot read dependency file {}", path.display()))?;
    let bytes = source.as_bytes();
    let mut escaped = false;
    let colon = bytes
        .iter()
        .position(|byte| {
            let is_separator = *byte == b':' && !escaped;
            escaped = *byte == b'\\' && !escaped;
            is_separator
        })
        .ok_or_else(|| anyhow::anyhow!("dependency file has no target separator"))?;

    let mut paths = Vec::new();
    let mut token = Vec::new();
    let mut index = colon + 1;
    while index < bytes.len() {
        match bytes[index] {
            b'\\' if bytes.get(index + 1) == Some(&b'\n') => index += 2,
            b'\\'
                if bytes.get(index + 1) == Some(&b'\r') && bytes.get(index + 2) == Some(&b'\n') =>
            {
                index += 3;
            }
            b'\\' if index + 1 < bytes.len() => {
                token.push(bytes[index + 1]);
                index += 2;
            }
            b'$' if bytes.get(index + 1) == Some(&b'$') => {
                token.push(b'$');
                index += 2;
            }
            byte if byte.is_ascii_whitespace() => {
                push_depfile_path(&mut paths, &mut token, directory)?;
                index += 1;
            }
            byte => {
                token.push(byte);
                index += 1;
            }
        }
    }
    push_depfile_path(&mut paths, &mut token, directory)?;
    if paths.is_empty() {
        bail!("compiler produced an empty dependency file");
    }
    Ok(paths)
}

fn push_depfile_path(
    paths: &mut Vec<PathBuf>,
    token: &mut Vec<u8>,
    directory: &Path,
) -> Result<()> {
    if token.is_empty() {
        return Ok(());
    }
    let value =
        String::from_utf8(std::mem::take(token)).context("dependency path is not valid UTF-8")?;
    let path = PathBuf::from(value);
    paths.push(if path.is_absolute() {
        path
    } else {
        directory.join(path)
    });
    Ok(())
}

fn ensure_snapshot(root: &Path) -> Result<()> {
    let prelude = root.join(SNAPSHOT_INCLUDE).join("prelude.hpp");
    if !prelude.is_file() {
        bail!(
            "workspace template snapshot is missing; run `mtf update` ({})",
            prelude.display()
        );
    }
    Ok(())
}

fn require_success(status: ExitStatus, action: &str) -> Result<()> {
    if !status.success() {
        bail!("{action} failed with {status}");
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn initializes_offline_workspace() {
        let directory = tempdir().unwrap();
        initialize(
            directory.path(),
            "g++".to_owned(),
            "gnu++23".to_owned(),
            Vec::new(),
            None,
            false,
        )
        .unwrap();
        assert!(directory.path().join("mtf.toml").is_file());
        assert!(
            directory
                .path()
                .join(".mtf/include/mtf/prelude.hpp")
                .is_file()
        );
        let expected = embedded_snapshot()
            .unwrap()
            .starter("cpp")
            .unwrap()
            .to_owned();
        assert_eq!(
            fs::read_to_string(directory.path().join(CPP_STARTER)).unwrap(),
            expected
        );
        create_sources(directory.path(), &["A".to_owned()]).unwrap();
        assert_eq!(
            fs::read_to_string(directory.path().join("A.cpp")).unwrap(),
            expected
        );
        let flags = fs::read_to_string(directory.path().join("compile_flags.txt")).unwrap();
        assert!(flags.contains("-I.mtf/include"));
        assert!(!flags.lines().any(|flag| flag.starts_with("-O")));
    }

    #[test]
    fn source_names_cannot_escape_workspace() {
        let directory = tempdir().unwrap();
        assert!(source_path(directory.path(), "../A").is_err());
        assert!(
            source_path(directory.path(), "A")
                .unwrap()
                .ends_with("A.cpp")
        );
    }

    #[test]
    fn parses_compiler_depfiles_with_escaped_paths() {
        let directory = tempdir().unwrap();
        let depfile = directory.path().join("deps.d");
        fs::write(
            &depfile,
            "output: source.cpp include/with\\ space.hpp \\\n nested/header.hpp\n",
        )
        .unwrap();
        assert_eq!(
            parse_depfile(&depfile, directory.path()).unwrap(),
            [
                directory.path().join("source.cpp"),
                directory.path().join("include/with space.hpp"),
                directory.path().join("nested/header.hpp"),
            ]
        );
    }

    #[test]
    fn custom_include_search_disables_pch() {
        let mut config = WorkspaceConfig::default();
        config.cpp.flags.push("-Ivendor".to_owned());
        assert!(pch_is_disabled(&config));
    }
}
