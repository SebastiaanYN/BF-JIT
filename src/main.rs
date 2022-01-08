use std::ffi::CString;
use std::fs;
use std::os::raw::c_char;

extern "C" {
    fn brainfuck(code: *const c_char);
}

fn main() {
    let mut args = std::env::args().skip(1);

    let filename = args.next().expect("Missing filename");

    let code = fs::read_to_string(filename).expect("Failed to read file");
    let code = CString::new(code).expect("Code is not valid C-string");

    unsafe {
        brainfuck(code.as_ptr());
    }
}
