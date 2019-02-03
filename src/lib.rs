#![feature(panic_info_message,allocator_api,asm,lang_items,compiler_builtins_lib)]
#![no_std]

mod screen;

static GREETING: &[u8] = b"VoidStar v0.1 - IN RUST\n";
static TRUE_STR: &[u8] = b"True";
static FALSE_STR: &[u8] = b"False";

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
    let greeting = "VoidStar 0.1";
    //screen::Screen::clear();
    for c in greeting.chars() {
        screen::Screen::write_fmt(c, 4, 7);
    }
    /*let sb: &video::ScreenBuffer = video::ScreenBuffer::get_screen_buffer();
    //let mut sb = ScreenBuffer {xpos: 0, ypos: 7};
    sb.write_string(0xb as u8, GREETING);

    for j in 0..2 {
        match quick_return(j) {
            Ok(_)   => {
                let buf2 = 0xb86e0 as *mut u8;
                for (i, &byte) in TRUE_STR.iter().enumerate() {
                    unsafe {
                        *buf2.offset(i as isize * 2) = byte;
                        *buf2.offset(i as isize * 2 + 1) = 0xb;
                    }
                }
            },
            Err(_)  => {
                let buf2 = 0xb8780 as *mut u8;
                for (i, &byte) in FALSE_STR.iter().enumerate() {
                    unsafe {
                        *buf2.offset(i as isize * 2) = byte;
                        *buf2.offset(i as isize * 2 + 1) = 0xb;
                    }
                }
            },
        }
        //memcpy_test();
        video::test(); 
    }*/

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
