mod bundle;
mod cli;
mod io_util;
mod library;
mod workspace;

use std::path::{Path, PathBuf};
use std::process::ExitCode;

use anyhow::{Context, Result, bail};
use clap::Parser;

use crate::bundle::Bundler;
use crate::cli::{Cli, Command};
use crate::io_util::{absolute, find_parent_with, is_stdio_path, read_source, write_payload};

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("mtf: error: {error:#}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Command::Sync(arguments) => {
            let root = library::resolve_library_root(arguments.root.as_deref())?;
            library::sync_live(&root, arguments.check)
        }
        Command::Render(arguments) => {
            let root = library::resolve_library_root(arguments.root.as_deref())?;
            let output = match arguments.output_dir {
                Some(path) => absolute(&path)?,
                None => root.join("book"),
            };
            library::render(&root, arguments.target, &output)
        }
        Command::Bundle(arguments) => {
            reject_in_place(arguments.source.as_deref(), arguments.output.as_deref())?;
            let (bytes, source_path) = read_source(arguments.source.as_deref())?;
            let source =
                std::str::from_utf8(&bytes).context("submission source must be valid UTF-8")?;
            let cwd = std::env::current_dir().context("cannot determine current directory")?;
            let label = match source_path.as_deref() {
                Some(path) => absolute(path)?,
                None => cwd.join("<stdin>"),
            };
            let include_dir = resolve_bundle_include(
                arguments.include_dir.as_deref(),
                source_path.as_deref().unwrap_or(&cwd),
            )?;
            let mut bundler = Bundler::new(&include_dir, &arguments.prefix)?;
            let bundled = bundler.bundle(source, &label)?;
            write_payload(bundled.as_bytes(), arguments.output.as_deref())
        }
        Command::Init(arguments) => {
            let root = workspace::initialize(
                &arguments.path,
                arguments.compiler,
                arguments.standard,
                arguments.flags,
                arguments.library.as_deref(),
                arguments.force,
            )?;
            workspace::warm_pch(&root)
        }
        Command::New(arguments) => {
            let cwd = std::env::current_dir().context("cannot determine current directory")?;
            let root = workspace::resolve_workspace_root(arguments.root.as_deref(), &cwd)?;
            workspace::create_sources(&root, &arguments.names)
        }
        Command::Compile(arguments) => {
            let root =
                workspace::resolve_workspace_root(arguments.root.as_deref(), &arguments.source)?;
            workspace::compile_source(&root, &arguments.source, arguments.output.as_deref())?;
            Ok(())
        }
        Command::Run(arguments) => {
            let root =
                workspace::resolve_workspace_root(arguments.root.as_deref(), &arguments.source)?;
            workspace::run_source(&root, &arguments.source, &arguments.arguments)
        }
        Command::Check(arguments) => {
            reject_in_place(arguments.source.as_deref(), arguments.output.as_deref())?;
            let (bytes, source_path) = read_source(arguments.source.as_deref())?;
            let cwd = std::env::current_dir().context("cannot determine current directory")?;
            let start = source_path.as_deref().unwrap_or(&cwd);
            let root = match arguments.root.as_deref() {
                Some(path) => Some(workspace::resolve_workspace_root(Some(path), start)?),
                None => workspace::find_workspace_root(start),
            };
            workspace::check_source(
                &bytes,
                root.as_deref(),
                arguments.compiler.as_deref(),
                arguments.standard.as_deref(),
            )?;
            write_payload(&bytes, arguments.output.as_deref())
        }
        Command::Update(arguments) => {
            let cwd = std::env::current_dir().context("cannot determine current directory")?;
            let root = workspace::resolve_workspace_root(arguments.root.as_deref(), &cwd)?;
            workspace::update(&root, arguments.library.as_deref())?;
            workspace::warm_pch(&root)
        }
    }
}

fn reject_in_place(source: Option<&Path>, output: Option<&Path>) -> Result<()> {
    let (Some(source), Some(output)) = (source, output) else {
        return Ok(());
    };
    if is_stdio_path(source) || is_stdio_path(output) {
        return Ok(());
    }
    if absolute(source)? == absolute(output)? {
        bail!("refusing to overwrite the input source file");
    }
    Ok(())
}

fn resolve_bundle_include(explicit: Option<&Path>, start: &Path) -> Result<PathBuf> {
    if let Some(path) = explicit {
        return absolute(path);
    }

    if let Some(root) = workspace::find_workspace_root(start) {
        return Ok(root.join(".mtf/include"));
    }

    if let Ok(root) = find_parent_with(start, "book.typ") {
        let root = library::resolve_library_root(Some(&root))?;
        library::sync_live(&root, false)?;
        return Ok(root.join("include"));
    }

    bail!("cannot locate MTF headers; run `mtf init` or pass --include-dir")
}
