use std::ffi::CString;
use std::fs;
use std::io::BufRead;
use std::os::raw::c_char;
use std::path::Path;

extern "C" {
    fn brainfuck(code: *const c_char);
}

fn main() {
    let mut args = std::env::args().skip(1);

    let code = match args.next() {
        Some(arg) => {
            if Path::new(&arg).exists() {
                fs::read_to_string(arg).expect("Failed to read file")
            } else {
                arg
            }
        }
        _ => std::io::stdin()
            .lock()
            .lines()
            .collect::<Result<_, _>>()
            .expect("Unable to read code from stdin"),
    };

    let code = CString::new(code).expect("Code is not valid C-string");

    unsafe {
        brainfuck(code.as_ptr());
    }

    std::mem::forget(code);
}
