fn main() {
    let mut builder = cc::Build::new();
    builder.file("src/brainfuck.S");

    if std::env::var("PROFILE").unwrap() == "debug" {
        builder.define("DEBUG", None);
    }

    builder.compile("brainfuck");
}
