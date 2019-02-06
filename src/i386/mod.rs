#[repr(C)]
pub struct registers_t {
    ds: u32,
    edi: u32,
    esi: u32,
    ebp: u32,
    esp: u32,
    ebx: u32,
    edx: u32,
    ecx: u32,
    eax: u32,
    interrupt: u32,
    err: u32,
    eip: u32,
    cs: u32,
    flags: u32,
    uesp: u32,
    ss: u32,
}

impl registers_t {
    pub fn new() -> registers_t {
        let t = 

extern {
    pub fn __asm_getreg(r: &registers_t);
}
