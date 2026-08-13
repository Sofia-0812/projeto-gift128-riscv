MEMORY
{
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x10000 /* 64KB de RAM */
}

SECTIONS
{
    .text : {
        *(.text)
    } > ram

    .data : {
        *(.data)
    } > ram

    .bss : {
        *(.bss)
    } > ram
}