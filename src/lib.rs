#![feature(panic_info_message,allocator_api,asm,lang_items,compiler_builtins_lib)]
#![no_std]

#[macro_use]
mod screen;

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
    let k_screen_buffer = screen::ScreenBuffer::new();
    
    /*for c in "Welcome to ".chars() {
        screen::write(c);
    }*/
    k_screen_buffer.write_str("Welcome to ");
    //k_screen_buffer.write_str(OSNAME);

    loop {}
}

fn quick_return(x: u32) -> Result<(), ()> {
    if x == 1 {
        Ok(())
    }
    else {
        Err(())
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
