/* The screen module. Based on what type of hardware we're running, a lot of
   this can be highly architecture-dependent. */

#[cfg(feature="x86")]
mod screen_config {
    pub static ADDR: usize      = 0x000B_8000;
    pub static PARAMS: bool     = true;
    pub static WIDTH: isize     = 80;
    pub static HEIGHT: isize    = 25;
    pub static CHAR_SIZE: isize = 2;
    pub static mut XPOS: isize  = 0;
    pub static mut YPOS: isize  = 7;
}

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

pub struct Screen {

}

impl Screen {
    /* For now, just iterate over the screen and black out the whole thing
       char-by-char */
    pub fn clear() {
        let height = screen_config::HEIGHT;
        let width  = screen_config::WIDTH;
        let csize  = screen_config::CHAR_SIZE;
        let cparam = CharParams::BLACK as u8;
        let address = screen_config::ADDR as *mut u8;
        for i in (0..height * width * csize).step_by(csize as usize) {
            let fmt:u8 = cparam << 4 | cparam;
            let c = ' ' as u8;
            unsafe {
                address.offset(i as isize).write_volatile(c);
                address.offset(i as isize + 1).write_volatile(cparam);
                screen_config::XPOS = 0;
                screen_config::YPOS = 0;
            }
        }
    }

    pub fn write(c: char) {
        Screen::write_fmt(c, CharParams::GRAY as u8, CharParams::BLACK as u8);
    }

    pub fn write_fmt(c: char, fg: u8, bg: u8) {
        let fmt: u8 = bg << 4 | fg;
        let width = screen_config::CHAR_SIZE;
        let cpr = screen_config::WIDTH;
        
        unsafe {
            let addr = screen_config::ADDR as *mut u8;
            let mut ypos = &mut screen_config::YPOS;
            let mut xpos = &mut screen_config::XPOS;
            let off: isize = *ypos * width * cpr + *xpos * width;
            addr.offset(off).write_volatile(c as u8);
            addr.offset(off + 1).write_volatile(fmt);
            *xpos += 1
        }
    }


}
