use std::ffi::OsString;
use std::path::PathBuf;

use clap::{Args, Parser, Subcommand, ValueEnum};

#[derive(Debug, Parser)]
#[command(
    name = "mtf",
    version,
    about = "Typst-backed algorithm templates and contest workspaces"
)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Command,
}

#[derive(Debug, Subcommand)]
pub enum Command {
    /// Generate public headers from Typst raw values.
    Sync(SyncArgs),
    /// Render the template book as PDF and/or HTML.
    #[command(visible_alias = "build")]
    Render(RenderArgs),
    /// Expand used <mtf/...> headers into one submission source.
    Bundle(BundleArgs),
    /// Initialize a self-contained contest workspace.
    Init(InitArgs),
    /// Create one or more contest source files.
    New(NewArgs),
    /// Compile a contest source with the workspace toolchain.
    Compile(CompileArgs),
    /// Build a changed contest source and run it.
    Run(RunArgs),
    /// Compile-check a source and pass its exact bytes through on success.
    Check(CheckArgs),
    /// Refresh a workspace's pinned template snapshot.
    Update(UpdateArgs),
}

#[derive(Debug, Args)]
pub struct SyncArgs {
    /// Fail instead of writing when generated headers are stale.
    #[arg(long)]
    pub check: bool,

    /// Template-library root; defaults to searching parent directories.
    #[arg(long, value_name = "PATH")]
    pub root: Option<PathBuf>,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, ValueEnum)]
pub enum RenderTarget {
    All,
    Pdf,
    Html,
}

#[derive(Debug, Args)]
pub struct RenderArgs {
    /// Output target.
    #[arg(long, alias = "format", value_enum, default_value = "all")]
    pub target: RenderTarget,

    /// Output directory; defaults to <library>/book.
    #[arg(long, value_name = "PATH")]
    pub output_dir: Option<PathBuf>,

    /// Template-library root; defaults to searching parent directories.
    #[arg(long, value_name = "PATH")]
    pub root: Option<PathBuf>,
}

#[derive(Debug, Args)]
pub struct BundleArgs {
    /// Source file, or -/omitted for stdin.
    #[arg(value_name = "SOURCE")]
    pub source: Option<PathBuf>,

    /// Write to this path instead of stdout; - means stdout.
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,

    /// Root containing the mtf include directory.
    #[arg(short = 'I', long, value_name = "PATH")]
    pub include_dir: Option<PathBuf>,

    /// Internal include prefix.
    #[arg(long, default_value = "mtf")]
    pub prefix: String,
}

#[derive(Debug, Args)]
pub struct InitArgs {
    /// Directory to initialize.
    #[arg(default_value = ".")]
    pub path: PathBuf,

    /// C++ compiler executable.
    #[arg(long, default_value = "g++")]
    pub compiler: String,

    /// C++ language standard.
    #[arg(long = "std", default_value = "gnu++23")]
    pub standard: String,

    /// Additional compiler flag; may be repeated.
    #[arg(long = "flag", allow_hyphen_values = true)]
    pub flags: Vec<String>,

    /// Use live Typst sources from this template-library checkout.
    #[arg(long, value_name = "PATH")]
    pub library: Option<PathBuf>,

    /// Replace mtf-owned configuration files if present.
    #[arg(long)]
    pub force: bool,
}

#[derive(Debug, Args)]
pub struct NewArgs {
    /// Problem names, with or without the .cpp suffix.
    #[arg(required = true)]
    pub names: Vec<String>,

    /// Contest-workspace root; defaults to searching parent directories.
    #[arg(long, value_name = "PATH")]
    pub root: Option<PathBuf>,
}

#[derive(Debug, Args)]
pub struct CompileArgs {
    /// Contest source file.
    pub source: PathBuf,

    /// Binary output path; defaults to .mtf/bin/<source-stem>.
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,

    /// Contest-workspace root; defaults to searching parent directories.
    #[arg(long, value_name = "PATH")]
    pub root: Option<PathBuf>,
}

#[derive(Debug, Args)]
pub struct RunArgs {
    /// Contest source file.
    pub source: PathBuf,

    /// Contest-workspace root; defaults to searching parent directories.
    #[arg(long, value_name = "PATH")]
    pub root: Option<PathBuf>,

    /// Arguments passed to the compiled program.
    #[arg(last = true)]
    pub arguments: Vec<OsString>,
}

#[derive(Debug, Args)]
pub struct CheckArgs {
    /// Source file, or -/omitted for stdin.
    #[arg(value_name = "SOURCE")]
    pub source: Option<PathBuf>,

    /// Write unchanged source to this path instead of stdout.
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,

    /// Override the configured compiler.
    #[arg(long)]
    pub compiler: Option<String>,

    /// Override the configured language standard.
    #[arg(long = "std")]
    pub standard: Option<String>,

    /// Contest-workspace root; defaults to searching parent directories.
    #[arg(long, value_name = "PATH")]
    pub root: Option<PathBuf>,
}

#[derive(Debug, Args)]
pub struct UpdateArgs {
    /// Contest-workspace root; defaults to searching parent directories.
    #[arg(long, value_name = "PATH")]
    pub root: Option<PathBuf>,

    /// Use live Typst sources from this template-library checkout.
    #[arg(long, value_name = "PATH")]
    pub library: Option<PathBuf>,
}
