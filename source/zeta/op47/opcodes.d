/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.op47.opcodes;

enum Op47Opcode : ubyte {
//  Name           = Opcode   = Format and size                                = Description                                                                  =
//  -------------- = -------- = ---------------------------------------------- = ---------------------------------------------------------------------------- =
    load_bool      = 0x01, // = `[code][addr a][byte val]`                     = Loads bool with value `val` into `addr a`.                                   =
    load_int       = 0x02, // = `[code][addr a][byte * 8 val]`                 = Loads long with value `val` into `addr a`.                                   =
    load_float     = 0x03, // = `[code][addr a][byte * 8 val]`                 = Loads double with value `val` into `addr a`.                                 =
    load_string    = 0x04, // = `[code][addr a][str val]`                      = Loads string with value `val` into `addr a`.                                  =
    math_add       = 0x05, // = `[code][addr a][addr b][addr c]`               = Adds contents of `addr a` and `addr b`, storing result in `addr c`.          =
    math_subtract  = 0x06, // = `[code][addr a][addr b][addr c]`               = Subtracts contents of `addr a` and `addr b`, storing result in `addr c`.     =
    math_multiply  = 0x07, // = `[code][addr a][addr b][addr c]`               = Multiply contents of `addr a` and `addr b`, storing result in `addr c`.      =
    math_divide    = 0x08, // = `[code][addr a][addr b][addr c]`               = Divides contents of `addr a` and `addr b`, storing result in `addr c`.       =
    math_modulo    = 0x09, // = `[code][addr a][addr b][addr c]`               = Modulos contents of `addr a` and `addr b`, storing result in `addr c`.       =
    math_increment = 0x0A, // = `[code][addr a]`                               = Increments contents of `addr a`.                                             =
    math_decrement = 0x0B, // = `[code][addr a]`                               = Decrements contents of `addr a`.                                             =
    math_negative  = 0x0C, // = `[code][addr a][addr b]`                       = Negates contents of `addr a`, storing result in addr b.                      =
    bit_and        = 0x0D, // = `[code][addr a][addr b][addr c]`               = Performs bitwise AND with `addr a` and `addr b`, storing result in `addr c`. =
    bit_or         = 0x0E, // = `[code][addr a][addr b][addr c]`               = Performs bitwise OR with `addr a` and `addr b`, storing result in `addr c`.  =
    bit_xor        = 0x0F, // = `[code][addr a][addr b][addr c]`               = Performs bitwise XOR with `addr a` and `addr b`, storing result in `addr c`. =
    bit_shiftLeft  = 0x10, // = `[code][addr a][addr b][addr c]`               = Bitwise shifts `addr a` by `addr b` places, storing result in `addr c`.      =
    bit_shiftRight = 0x11, // = `[code][addr a][addr b][addr c]`               = Bitwise shifts `addr a` by -`addr b` places, storing result in `addr c`.     =
    bit_not        = 0x12, // = `[code][addr a][addr b]`                       = Performs bitwise NOT on `addr a`, storing result in `addr c`.                =
    logic_equal    = 0x13, // = `[code][addr a][addr b][addr c]`               = Performs equity test on `addr a` and `addr b`, storing result in `addr c`.   =
    logic_cmp      = 0x14, // = `[code][addr a][addr b][addr c]`               = Comparse `addr a` and `addr b`, storing result in `addr c`.                  =
    op_move        = 0x15, // = `[code][addr a][addr b]`                       = Copies contents of `addr a` into `addr b`.                                   =
    op_jump        = 0x16, // = `[code][byte * 4 loc]`                         = Sets instruction pointer to `loc`.                                           =
    op_jumpIf      = 0x17, // = `[code][addr a][byte * 4 loc]`                 = Sets instruction pointer to `loc`, if `addr a` evaluates to true.            =
    op_call        = 0x18, // = `[code][addr a][addr b]`                       = Calls closure or function `addr a` with argument `addr b`.                   =
    op_ret         = 0x19, // = `[code][addr a]`                               = Loads last stack-frame and instruction pointer.                              =
    op_setstack    = 0x1A, // = `[code][byte * 2 len]`                         = Sets stack top offset to value of `len`.                                     =
    op_closure     = 0x1B, // = `[code][byte * 4 loc][addr a]`                 = Creates closure from current stackframe and `loc`, storing in `addr a`.      =
    op_concat      = 0x1C, // = `[code][addr a][addr b]`                       = Appends contents of `addr b` to `addr a`.                                    =
    op_index       = 0x1D, // = `[code][addr a][addr b][addr c]`               = Indexes `addr a` with index `addr b`, storing result in `addr c`.            =
    op_indexAssign = 0x1E, // = `[code][addr a][addr b][addr c]`               = Index assigns `addr a` using index `addr b`, with `addr c`.                  =
    op_dispatchGet = 0x1F, // = `[code][addr a][addr b][str nam]`              = Dispatches on `addr a` using `nam`, storing result in `addr b`.              =
    op_dispatchSet = 0x20, // = `[code][addr a][addr b][str nam]`              = Dispatch assigns `addr a` using `nam`, with `addr b`.                        =
}