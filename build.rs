fn main() {
    cc::Build::new()
        .file("src/brainfuck.s")
        .compile("brainfuck");
}
