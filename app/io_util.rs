use std::fs;
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;

use anyhow::{Context, Result, bail};
use tempfile::NamedTempFile;

pub fn is_stdio_path(path: &Path) -> bool {
    path.as_os_str() == "-"
}

pub fn read_source(path: Option<&Path>) -> Result<(Vec<u8>, Option<PathBuf>)> {
    match path {
        Some(path) if !is_stdio_path(path) => {
            let bytes =
                fs::read(path).with_context(|| format!("cannot read source {}", path.display()))?;
            Ok((bytes, Some(path.to_path_buf())))
        }
        _ => {
            let mut bytes = Vec::new();
            io::stdin()
                .read_to_end(&mut bytes)
                .context("cannot read source from stdin")?;
            Ok((bytes, None))
        }
    }
}

pub fn write_payload(bytes: &[u8], path: Option<&Path>) -> Result<()> {
    match path {
        Some(path) if !is_stdio_path(path) => atomic_write(path, bytes),
        _ => {
            let mut stdout = io::stdout().lock();
            stdout.write_all(bytes).context("cannot write stdout")?;
            stdout.flush().context("cannot flush stdout")
        }
    }
}

pub fn atomic_write(path: &Path, bytes: &[u8]) -> Result<()> {
    let parent = path
        .parent()
        .filter(|parent| !parent.as_os_str().is_empty())
        .unwrap_or_else(|| Path::new("."));
    fs::create_dir_all(parent)
        .with_context(|| format!("cannot create directory {}", parent.display()))?;

    let mut temporary = NamedTempFile::new_in(parent)
        .with_context(|| format!("cannot create temporary file in {}", parent.display()))?;
    temporary
        .write_all(bytes)
        .with_context(|| format!("cannot write temporary file for {}", path.display()))?;
    #[cfg(unix)]
    {
        let mode = fs::metadata(path)
            .map(|metadata| metadata.permissions().mode())
            .unwrap_or(0o644);
        temporary
            .as_file()
            .set_permissions(fs::Permissions::from_mode(mode))
            .with_context(|| format!("cannot set permissions for {}", path.display()))?;
    }
    temporary
        .flush()
        .with_context(|| format!("cannot flush temporary file for {}", path.display()))?;

    temporary
        .persist(path)
        .map_err(|error| error.error)
        .with_context(|| format!("cannot persist {}", path.display()))?;
    Ok(())
}

pub fn absolute(path: &Path) -> Result<PathBuf> {
    if path.is_absolute() {
        Ok(path.to_path_buf())
    } else {
        Ok(std::env::current_dir()
            .context("cannot determine current directory")?
            .join(path))
    }
}

pub fn find_parent_with(start: &Path, marker: &str) -> Result<PathBuf> {
    let mut current = if start.is_dir() {
        absolute(start)?
    } else {
        absolute(start)?
            .parent()
            .map(Path::to_path_buf)
            .ok_or_else(|| anyhow::anyhow!("{} has no parent directory", start.display()))?
    };

    loop {
        if current.join(marker).is_file() {
            return Ok(current);
        }
        if !current.pop() {
            bail!("could not find {marker} in this directory or any parent");
        }
    }
}
