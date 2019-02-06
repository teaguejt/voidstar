#![feature(panic_info_message,allocator_api,asm,lang_items,compiler_builtins_lib)]
#![no_std]

#[macro_use]
mod screen;
#[cfg(feature="x86")]
mod i386;

use core::fmt::Write;

static OSNAME: &str = &"(void *)OS";
static OSVERSION: &str = &" 0.1";

#[lang = "eh_personality"]
fn eh_personality() {
    abort();
}

#[no_mangle]
fn abort() -> ! {
    loop{}
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop{}
}

#[no_mangle]
pub extern "C" fn _kmain() -> ! {
    let mut k_screen_buffer = screen::ScreenBuffer::new();
    let mut r: i386::registers_t;
    unsafe {
        i386::__asm_getreg(&r);
    }
    k_screen_buffer.set_fmt(10, 0);
    write!(&mut k_screen_buffer, "{}\n", OSNAME);
    
    k_screen_buffer.reset_fmt();

    write!(&mut k_screen_buffer, "Test {}", 1);
    loop {}
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
