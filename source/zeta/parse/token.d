/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.parse.token;

import std.variant;
import std.format;
import std.traits;
import std.algorithm;

struct ZtToken {
    alias Literal = Algebraic!(ulong, long, double, dchar, string);
    enum Type : string {
        op_plus = "+",
        op_minus = "-",
        op_asterisk = "*",
        op_slash = "/",
        op_percent = "%",
        op_tilde = "~",
        op_ampersand = "&",
        op_poll = "|",
        op_circumflex = "^",
        op_shiftLeft = "<<",
        op_shiftRight = ">>",

        op_increment = "++",
        op_decrement = "--",
        op_not = "!",

        op_assign = "=",
        op_assignAdd = "+=",
        op_assignSubtract = "-=",
        op_assignMultiply = "*=",
        op_assignDivide = "/=",
        op_assignModulo = "%=",
        op_assignConcat = "~=",
        op_assignBitAnd = "&=",
        op_assignBitOr = "|=",
        op_assignBitXor = "^=",
        op_assignShiftLeft = "=<<",
        op_assignShiftRight = "=>>",

        op_and = "&&",
        op_or = "||",

        op_equal = "==",
        op_notEqual = "!=",
        op_greaterThan = ">",
        op_lessThan = "<",
        op_greaterThanEqual = ">=",
        op_lessThanEqual = "<=",

        tk_dot = ".",
        tk_apply = ".?",
        tk_comma = ",",
        tk_colon = ":",
        tk_semicolon = ";",
        tk_variadic = "...",
        tk_slice = "..",

        tk_leftParen = "(",
        tk_rightParen = ")",
        tk_leftBracket = "[",
        tk_rightBracket = "]",
        tk_leftBrace = "{",
        tk_rightBrace = "}",

        kw_module = "module",
        kw_import = "import",
        kw_enum = "enum",
        kw_template = "template",
        kw_struct = "struct",
        kw_class = "class",
        kw_interface = "interface",
        kw_function = "function",
        kw_def = "def",
        kw_alias = "alias",

        kw_if = "if",
        kw_else = "else",
        kw_while = "while",
        kw_do = "do",
        kw_for = "for",
        kw_foreach = "foreach",
        kw_switch = "switch",
        kw_case = "case",
        kw_with = "with",

        kw_cast = "cast",
        kw_typeof = "typeof",
        kw_break = "break",
        kw_continue = "continue",
        kw_return = "return",
        kw_is = "is",
        kw_new = "new",
        kw_delete = "delete",

        ud_identifier = "<Identifier>",
        ud_attribute = "<Attribute>",
        ud_string = "<String Literal>",
        ud_char = "<Character Literal>",
        ud_integer = "<Integer Literal>",
        ud_float = "<Floating Point Literal>",
        eof = "<End of File>",
        unknown = "<Unknown Token>",
        no_op = ""
    }

    Type type;
    ZtSrcLocation location;
    string lexeme;
    Literal literal;
}

struct ZtSrcLocation {
    size_t line, column, position;
    string file;

    static ZtSrcLocation fromBuffer(string text, size_t position, string file) {
        import std.string : splitLines;

        auto lines = text[0 .. position].splitLines();
        return ZtSrcLocation(lines.length, lines.length == 0
                ? 1 : lines[$ - 1].length, position, file);
    }

    @property string toString() const {
        return format("%s:(line: %s, column:%s)", file, line, column);
    }
}

enum tokenNames = sort(cast(string[])[EnumMembers!(ZtToken.Type)][0 .. $ - 9]).reverse;
