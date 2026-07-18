use std::env;
use std::ffi::OsString;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

const SNIPPET_QUERY: &str = "query(metadata).map(it => it.value)";

fn main() {
    println!("cargo:rerun-if-env-changed=MTF_TYPST");
    println!("cargo:rerun-if-changed=book.typ");
    println!("cargo:rerun-if-changed=template.typ");
    println!("cargo:rerun-if-changed=src");

    let root = PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").unwrap());
    let typst = env::var_os("MTF_TYPST").unwrap_or_else(|| OsString::from("typst"));
    let output = Command::new(&typst)
        .current_dir(&root)
        .args(["eval", SNIPPET_QUERY, "--in", "book.typ", "--root"])
        .arg(&root)
        .output()
        .unwrap_or_else(|error| {
            panic!("failed to execute Typst while embedding the template snapshot: {error}")
        });

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        panic!("Typst failed while embedding the template snapshot:\n{stderr}");
    }

    let output_dir = PathBuf::from(env::var_os("OUT_DIR").unwrap());
    fs::write(output_dir.join("mtf-snippets.json"), output.stdout)
        .expect("failed to write embedded Typst metadata");
}
