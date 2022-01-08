fn main() {
    let mut builder = cc::Build::new();

    if cfg!(feature = "interpreter") {
        builder.file("src/brainfuck_interpreter.S");
    } else {
        builder.file("src/brainfuck.S");
    }

    if std::env::var("PROFILE").unwrap() == "debug" {
        builder.define("DEBUG", None);
    }

    builder.compile("brainfuck");
}
