/* The screen module. Based on what type of hardware we're running, a lot of
   this can be highly architecture-dependent. */

use core::fmt::{Write, Error};

#[cfg(feature="x86")]
mod screen_config {
    pub static ADDR: usize      = 0x000B_8000;
    pub static PARAMS: bool     = true;
    pub static WIDTH: usize     = 80;
    pub static HEIGHT: usize    = 25;
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
    WHITE   = 0b1111,
    /* Some good presets */
    /*GRAY_ON_BLACK   = 0b0000_0111,
    LGREEN_ON_BLACK = 0b0000_1010,
    BLACK_ON_LGREEN = 0b1010_0000,  // Watch out for blink - BIOS may screw up
    BLACK_ON_GREEN  = 0b0010_0000,  // Universal alternative for above
    WHITE_ON_GREEN  = 0b0010_1111,*/
}

/* For now, just iterate over the screen and black out the whole thing
   char-by-char */
pub struct ScreenBuffer {
    xpos: usize,
    ypos: usize,
    char_size: usize,
#[cfg(feature="x86")]
    fmt: u8,
}

impl ScreenBuffer {
    pub fn new() -> ScreenBuffer {
        let bg = CharParams::BLACK as u8;
        let fg = CharParams::GRAY as u8;
        let cfmt = (bg << 4) | fg;
        let s = ScreenBuffer {xpos: 0, ypos: 7, char_size: 2, fmt: cfmt};
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
                address.offset(i as isize + 1).write_volatile(fmt);
            }
        }
        self.xpos = 0;
        self.ypos= 0;
    }

    pub fn set_fmt(&mut self, fg: u8, bg: u8) {
        self.fmt = (bg << 4) | fg;
    }

    pub fn reset_fmt(&mut self) {
        self.set_fmt(CharParams::GRAY as u8, CharParams::BLACK as u8);
    }

    pub fn putc(&mut self, ch: char) -> Result<(), ()> {
        let cpr = screen_config::WIDTH;
        let width = self.char_size;
        let base: usize = screen_config::ADDR;
        let pos = base + self.ypos * width * cpr + self.xpos * width;
        let c = ch as u8;
        
        match c {
            b'\n'   => {
                self.xpos = 0;
                self.ypos += 1;
                return Ok(())
            },
            _       => unsafe {
                (pos as *mut u8).write_volatile(c as u8);
                (pos as *mut u8).offset(1).write_volatile(self.fmt);
            },
        }
        self.xpos += 1;
        if self.xpos == screen_config::WIDTH {
            self.ypos += 1;
            self.xpos = 0;
        }

        Ok(())
    }
}

impl Write for ScreenBuffer {
    fn write_str(&mut self, s: &str) -> Result<(), Error> {
        for c in s.chars() {
            match self.putc(c) {
                Ok(())  => Ok(()),
                _       => Err(())
            };
        }
        Ok(())
    }
}
