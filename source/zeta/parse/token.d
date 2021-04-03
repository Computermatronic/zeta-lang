/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.parse.token;

import std.algorithm : sort;
import std.range : retro;
import std.array : array;
import std.format : format;
import std.variant : Algebraic;

struct ZtToken {
    alias Literal = Algebraic!(ulong, long, double, dchar, string);
    enum Type {
	    tk_eof,
	    tk_plus,
	    tk_minus,
	    tk_asterisk,
	    tk_slash,
	    tk_percent,
	    tk_power,
	    tk_tilde,
	    tk_ampersand,
	    tk_poll,
	    tk_hash,
	    tk_shiftLeft,
	    tk_shiftRight,
	    tk_logicalAnd,
	    tk_logicalOr,
	    tk_logicalXor,

	    tk_assign,
	    tk_assignAdd,
	    tk_assignSubtract,
	    tk_assignMultiply,
	    tk_assignDivide,
	    tk_assignModulo,
	    tk_assignPower,
	    tk_assignConcat,
	    tk_assignAnd,
	    tk_assignOr,
	    tk_assignXor,

	    tk_equal,
	    tk_notEqual,
	    tk_greaterThan,
	    tk_lessThan,
	    tk_greaterThanEqual,
	    tk_lessThanEqual,

	    tk_increment,
	    tk_decrement,
	    tk_not,

	    tk_question,

	    tk_dot,
	    tk_apply,
	    tk_comma,
	    tk_colon,
	    tk_semicolon,
	    tk_variadic,
	    tk_slice,

	    tk_leftParen,
	    tk_rightParen,
	    tk_leftBracket,
	    tk_rightBracket,
	    tk_leftBrace,
	    tk_rightBrace,

	    kw_module,
	    kw_import,
	    kw_enum,
	    kw_template,
	    kw_struct,
	    kw_class,
	    kw_interface,
	    kw_function,
	    kw_def,
	    kw_alias,

	    kw_if,
	    kw_else,
	    kw_while,
	    kw_do,
	    kw_for,
	    kw_foreach,
	    kw_switch,
	    kw_case,
	    kw_with,

	    kw_cast,
	    kw_typeof,
	    kw_break,
	    kw_continue,
	    kw_return,
	    kw_is,
	    kw_new,
	    kw_delete,

	    ud_identifier,
	    ud_attribute,
	    ud_string,
	    ud_char,
	    ud_integer,
	    ud_float,
	    ud_unknown
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
	    auto lines = text[0..position].splitLines();
	    return ZtSrcLocation(lines.length, lines.length == 0 ? 1 : lines[$-1].length, position, file);
	}

	@property string toString() const {
	    return format("%s:(line: %s, column:%s)", file, line, column);
	}
}

string describeToken(ZtToken.Type tokenType) {
    switch(tokenType) {
	    case ZtToken.Type.ud_identifier: return "<Identifier>";
	    case ZtToken.Type.ud_attribute: return "<Attribute>";
	    case ZtToken.Type.ud_string: return "<String Literal>";
	    case ZtToken.Type.ud_char: return "<Charecter Literal>";
	    case ZtToken.Type.ud_integer: return "<Integer Literal>";
	    case ZtToken.Type.ud_float: return "<Floating Point Literal>";
	    default: static foreach(key, value; tokenLiterals) if (value == tokenType) return key;
	}
    assert(0, "Unknown or illegal token detected.");
}

enum ZtToken.Type[string] tokenLiterals = [
	"+": ZtToken.Type.tk_plus,
	"-": ZtToken.Type.tk_minus,
	"*": ZtToken.Type.tk_asterisk,
	"/": ZtToken.Type.tk_slash,
	"%": ZtToken.Type.tk_percent,
	"^": ZtToken.Type.tk_power,
	"~": ZtToken.Type.tk_tilde,
	"&": ZtToken.Type.tk_ampersand,
	"|": ZtToken.Type.tk_poll,
	"#": ZtToken.Type.tk_hash,
	"<<": ZtToken.Type.tk_shiftLeft,
	">>": ZtToken.Type.tk_shiftRight,
	"&&": ZtToken.Type.tk_logicalAnd,
	"||": ZtToken.Type.tk_logicalOr,
	"##": ZtToken.Type.tk_logicalXor,

	"=": ZtToken.Type.tk_assign,
	"+=": ZtToken.Type.tk_assignAdd,
	"-=": ZtToken.Type.tk_assignSubtract,
	"*=": ZtToken.Type.tk_assignMultiply,
	"/=": ZtToken.Type.tk_assignDivide,
	"%=": ZtToken.Type.tk_assignModulo,
	"^=": ZtToken.Type.tk_assignPower,
	"~=": ZtToken.Type.tk_assignConcat,
	"&=": ZtToken.Type.tk_assignAnd,
	"|=": ZtToken.Type.tk_assignOr,
	"#=": ZtToken.Type.tk_assignXor,

	"==": ZtToken.Type.tk_equal,
	"!=": ZtToken.Type.tk_notEqual,
	">": ZtToken.Type.tk_greaterThan,
	"<": ZtToken.Type.tk_lessThan,
	">=": ZtToken.Type.tk_greaterThanEqual,
	"<=": ZtToken.Type.tk_lessThanEqual,

	"++": ZtToken.Type.tk_increment,
	"--": ZtToken.Type.tk_decrement,
	"!": ZtToken.Type.tk_not,

	"?": ZtToken.Type.tk_question,

	".": ZtToken.Type.tk_dot,
	".?": ZtToken.Type.tk_apply,
	",": ZtToken.Type.tk_comma,
	":": ZtToken.Type.tk_colon,
	";": ZtToken.Type.tk_semicolon,
	"...": ZtToken.Type.tk_variadic,
	"..": ZtToken.Type.tk_slice,

	"(": ZtToken.Type.tk_leftParen,
	")": ZtToken.Type.tk_rightParen,
	"[": ZtToken.Type.tk_leftBracket,
	"]": ZtToken.Type.tk_rightBracket,
	"{": ZtToken.Type.tk_leftBrace,
	"}": ZtToken.Type.tk_rightBrace,

	"module": ZtToken.Type.kw_module,
	"import": ZtToken.Type.kw_import,
	"enum": ZtToken.Type.kw_enum,
	"template": ZtToken.Type.kw_template,
	"struct": ZtToken.Type.kw_struct,
	"class": ZtToken.Type.kw_class,
	"interface": ZtToken.Type.kw_interface,
	"function": ZtToken.Type.kw_function,
	"def": ZtToken.Type.kw_def,
	"alias": ZtToken.Type.kw_alias,

	"if": ZtToken.Type.kw_if,
	"else": ZtToken.Type.kw_else,
	"while": ZtToken.Type.kw_while,
	"do": ZtToken.Type.kw_do,
	"for": ZtToken.Type.kw_for,
	"foreach": ZtToken.Type.kw_foreach,
	"switch": ZtToken.Type.kw_switch,
	"case": ZtToken.Type.kw_case,
	"with": ZtToken.Type.kw_with,

	"cast": ZtToken.Type.kw_cast,
	"typeof": ZtToken.Type.kw_typeof,
	"break": ZtToken.Type.kw_break,
	"continue": ZtToken.Type.kw_continue,
	"return": ZtToken.Type.kw_return,
	"is": ZtToken.Type.kw_is,
	"new": ZtToken.Type.kw_new,
	"delete": ZtToken.Type.kw_delete
];

enum tokenNames = sort(tokenLiterals.keys).retro().array();
