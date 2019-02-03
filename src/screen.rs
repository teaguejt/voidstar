/* The screen module. Based on what type of hardware we're running, a lot of
   this can be highly architecture-dependent. */

use core::fmt::{Write, Error};

#[cfg(feature="x86")]
mod screen_config {
    pub static ADDR: usize      = 0x000B_8000;
    pub static PARAMS: bool     = true;
    pub static WIDTH: isize     = 80;
    pub static HEIGHT: isize    = 25;
}

#[cfg(feature="x86")]
static SCREEN_SIZE_BYTES: u32 = 4000;

#[cfg(feature="x86")]
enum CharParams {
    BLACK   = 0b0000,
    BLUE    = 0b0001,
    GREEN   = 0b0010,
    CYAN    = 0b0011,
    RED     = 0b0100,
    PURPLE  = 0b0101,
    BROWN   = 0b0110,
    GRAY    = 0b0111,
    DGRAY   = 0b1000,
    LBLUE   = 0b1001,
    LGREEN  = 0b1010,
    LCYAN   = 0b1011,
    LRED    = 0b1100,
    LPURPLE = 0b1101,
    YELLOW  = 0b1110,
    WHITE   = 0b1111
}

/* For now, just iterate over the screen and black out the whole thing
   char-by-char */
pub struct ScreenBuffer {
    xpos: isize,
    ypos: isize,
    char_size: isize,
}

impl ScreenBuffer {
    pub fn new() -> ScreenBuffer {
        let s = ScreenBuffer {xpos: 0, ypos: 7, char_size: 2};
        s
    }

    pub fn clear(&mut self) {
        let height = screen_config::HEIGHT;
        let width  = screen_config::WIDTH;
        let csize  = self.char_size;
        let cparam = CharParams::BLACK as u8;
        let address = screen_config::ADDR as *mut u8;
        for i in (0..height * width * csize).step_by(csize as usize) {
            let fmt:u8 = cparam << 4 | cparam;
            let c = ' ' as u8;
            unsafe {
                address.offset(i as isize).write_volatile(c);
                address.offset(i as isize + 1).write_volatile(cparam);
                self.xpos = 0;
                self.ypos= 0;
            }
        }
    }

    fn write(&mut self, c: char) {
        self.write_fmt(c, CharParams::GRAY as u8, CharParams::BLACK as u8);
    }

    pub fn write_fmt(&mut self, c: char, fg: u8, bg: u8) {
        let fmt: u8 = bg << 4 | fg;
        let cpr = screen_config::WIDTH;
        let width = self.char_size;

        unsafe {
            let addr = screen_config::ADDR as *mut u8;
            let mut ypos = self.xpos;
            let mut xpos = self.ypos;
            let off: isize = self.ypos * width * cpr + self.xpos * width;
            addr.offset(off).write_volatile(c as u8);
            addr.offset(off + 1).write_volatile(fmt);
            self.xpos += 1
        }
    }
}

impl Write for &mut ScreenBuffer {
    fn write_str(&mut self, s: &str) -> Result<(), Error> {
        for c in s.chars() {
            self.write(c);
        }
        Ok(())
    }
}
