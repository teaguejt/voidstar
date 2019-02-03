static GSB: ScreenBuffer = ScreenBuffer {xpos: 0, ypos: 7};

pub struct ScreenBuffer {
    xpos: u32,
    ypos: u32,
}

impl ScreenBuffer {
    pub fn get_screen_buffer() -> &'static ScreenBuffer {
        &GSB
    }

    fn get_buffer_start() -> *mut u8 {
        return 0xB8000 as *mut u8;
    }

    pub fn set_cursor_pos(&mut self, xpos: u32, ypos: u32) {
        self.xpos = xpos;
        self.ypos = ypos;
    }

    pub fn write_string(&self, fmt: u8, chars: &[u8]) {
        let buf = ScreenBuffer::get_buffer_start();
        let mut wr_buf = buf;

        unsafe {
            wr_buf = wr_buf.offset(self.ypos as isize * 160);
            wr_buf = wr_buf.offset(self.xpos as isize * 2);
        }
        for (i, &byte) in chars.iter().enumerate() {
            unsafe {
                *wr_buf.offset(i as isize * 2) = byte;
                *wr_buf.offset(i as isize * 2 + 1) = fmt;
            }
        }
    }
}

pub fn test() -> u32 {
    4 as u32
}
