# Brainfuck JIT

Brainfuck JIT compiler written in Assembly.

## Usage

There are 3 possible modes of input:

- Passing a file path: `cargo run -- examples/hello.b`
- Passing code as a string: `cargo run -- "++++++[->+++++++<]>."`
- Stdin: `cat examples/hello.b | cargo run`

By default `cargo run` builds in debug mode, which causes the compiler to write the machine code to disk as `jit.out`. You can analyze the machine code by running `./decompile.sh`. When running cargo with the `--release` flag this file will not be created.

Additionally, a Brainfuck interpreter, also implemented in Assembly, is provided. To use the interpreter you need to turn the `interpreter` feature on. This can be done by passing `--features interpreter` when calling cargo.

## Optimizations

The Brainfuck JIT compiler outputs machine code to achieve high performance execution. However, by optimizing common Brainfuck instructions we can achieve even higher speeds.

### Contraction

Repeated sequences of `<`, `>`, `+`, and `-` are grouped together into single `add` and `sub` instructions.

Where before you would compile `++++<<` to

```asm
incb (%r13)
incb (%r13)
incb (%r13)
incb (%r13)
decq %r13
decq %r13
```

it is instead compiled to

```asm
addb $4, (%r13)
subq $2, %r13
```

### Clear loops

Clear loops are very common in Brainfuck programs. Instead of compiling `[-]` to a loop that decrements the current cell until it's 0, we can directly set the current cell to 0.

Thus `[-]` is compiled to

```asm
movb $0, (%r13)
```

### Fixed loop offsets

When writing an interpreter it's possible to iterate over the code until you find the matching loop bracket. When compiling Brainfuck to machine code this is not possible so we are forced to calculate the loop offsets.

`[++]` is compiled to

```asm
cmpb $0, (%r13)
je <offset>

addb $2, (%r13)

cmpb $0, (%r13)
jne <offset>
```

## Potential optimizations

Because the compiler is written in Assembly it takes a lot of code to detect optimizations. This leaves for a lot of potential optimizations that are not being utilized, such as copy loops `[->+>+<<]` and multiplication loops `[->+++>+++++++<<]`.
