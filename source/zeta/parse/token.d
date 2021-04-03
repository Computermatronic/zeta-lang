/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.parse.token;

import std.algorithm: sort, reverse;
import std.range: retro;
import std.array: array;
import std.format: format;
import std.variant: Algebraic;
import std.traits: EnumMembers;

struct ZtToken {
    enum Type:string {
        tk_plus = "+",
        tk_minus = "-",
        tk_multiply = "*",
        tk_divide = "/",
        tk_modulo = "%",
        tk_tilde = "~",
        tk_bitAnd = "&",
        tk_bitOr = "|",
        tk_bitXor = "^",
        tk_shiftLeft = "<<",
        tk_shiftRight = ">>",
        tk_logicalAnd = "&&",
        tk_logicalOr = "||",
        tk_logicalXor = "^^",

        tk_assign = "=",
        tk_assignAdd = "+=",
        tk_assignSubtract = "-=",
        tk_assignMultiply = "*=",
        tk_assignDivide = "/=",
        tk_assignModulo = "%=",
        tk_assignConcat = "~=",
        tk_assignAnd = "&=",
        tk_assignOr = "|=",
        tk_assignXor = "^=",

        tk_equal = "==",
        tk_notEqual = "!=",
        tk_greaterThan = ">",
        tk_lessThan = "<",
        tk_greaterThanEqual = ">=",
        tk_lessThanEqual = "<=",

        tk_increment = "++",
        tk_decrement = "--",
        tk_not = "!",

        tk_question = "?",

        tk_dot = ".",
        tk_apply = ".?",
        tk_comma = ",",
        tk_colon = ":",
        tk_semicolon = ";",
        tk_variadic = "...",

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

        ud_eof = "<End of File>",
        ud_identifier = "<Identifier>",
        ud_attribute = "<Attribute>",
        ud_string = "<String Literal>",
        ud_char = "<Charecter Literal>",
        ud_integer = "<Integer Literal>",
        ud_float = "<Floating Point Literal>",
        ud_unknown = "<Unknown>"
    }
    alias Literal = Algebraic!(ulong, long, double, dchar, string);

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
        auto lines = text[0..position].splitLines();
        return ZtSrcLocation(lines.length, lines.length == 0 ? 1 : lines[$-1].length, position, file);
    }

    @property string toString() const {
        return format("%s:(line: %s, column:%s)", file, line, column);
    }
}

//The last 8 members of ZtToken.Type are user defined, so we don't want to include them in token names.
enum tokenNames = sort(cast(string[])[EnumMembers!(ZtToken.Type)][0..$-8]).reverse;