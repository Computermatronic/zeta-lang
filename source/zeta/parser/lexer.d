module zeta.lexer;

import std.string;
import std.stdio;
import std.algorithm : sort;
import std.range : retro;
import std.regex;

import zeta.utils;

enum TokenType
{
	op_add,
	op_sub,
	op_mul,
	op_div,
	op_mod,
    op_inc,
    op_dec,
	lo_and,
	lo_or,
	lo_not,
	sy_ass,
	sy_eq,
    sy_neq,
	sy_gr,
	sy_le,
	sy_gre,
	sy_lee,
	sy_term,
	sy_comma,
    sy_colan,
	sy_dot,
    sy_tinary,
	kw_if,
    kw_else,
	kw_for,
	kw_foreach,
	kw_do,
	kw_until,
	kw_while,
	kw_def,
	kw_class,
	kw_inherits,
	kw_static,
	kw_abstract,
	kw_interface,
	kw_function,
	kw_return,
    kw_break,
    kw_jump,
    kw_block,
	kw_import,
	kw_module,
    kw_new,
    kw_pragma,
	br_exo,
	br_exc,
	br_ixo,
	br_ixc,
	br_blo,
	br_blc,
	cu_word,
	cu_number,
	cu_string,
}

enum TokenType[string] TokenMap =
[
	"+":TokenType.op_add,
	"-":TokenType.op_sub,
	"*":TokenType.op_mul,
	"/":TokenType.op_div,
	"%":TokenType.op_mod,
    "++":TokenType.op_inc,
    "--":TokenType.op_dec,
	"&":TokenType.lo_and,
	"|":TokenType.lo_or,
	"!":TokenType.lo_not,
	"=":TokenType.sy_ass,
	"==":TokenType.sy_eq,
    "!=":TokenType.sy_neq,
	">":TokenType.sy_gr,
	"<":TokenType.sy_le,
	">=":TokenType.sy_gre,
	"<=":TokenType.sy_lee,
	";":TokenType.sy_term,
	",":TokenType.sy_comma,
    ":":TokenType.sy_colan,
	".":TokenType.sy_dot,
    "?":TokenType.sy_tinary,
	"if":TokenType.kw_if,
    "else":TokenType.kw_else,
	"for":TokenType.kw_for,
	"foreach":TokenType.kw_foreach,
	"do":TokenType.kw_do,
	"until":TokenType.kw_until,
	"while":TokenType.kw_while,
	"def":TokenType.kw_def,
	"class":TokenType.kw_class,
	"inherits":TokenType.kw_inherits,
	"static":TokenType.kw_static,
	"abstract":TokenType.kw_abstract,
	"interface":TokenType.kw_interface,
	"function":TokenType.kw_function,
	"return":TokenType.kw_return,
    "break":TokenType.kw_break,
    "jump":TokenType.kw_jump,
	"import":TokenType.kw_import,
	"module":TokenType.kw_module,
    "new":TokenType.kw_new,
    "pragma":TokenType.kw_pragma,
	"(":TokenType.br_exo,
	")":TokenType.br_exc,
	"[":TokenType.br_ixo,
	"]":TokenType.br_ixc,
	"{":TokenType.br_blo,
	"}":TokenType.br_blc,
];

enum ErrorMap = backMap(TokenMap).merge(
[
	TokenType.cu_word:"identifier",
	TokenType.cu_string:"string literal",
	TokenType.cu_number:"number"
]);

enum TokensSorted = sort(TokenMap.keys).retro();

enum bool[TokenType] Delimiters =
[
	TokenType.op_add:true,
	TokenType.op_sub:true,
	TokenType.op_mul:true,
	TokenType.op_div:true,
	TokenType.op_mod:true,
    TokenType.op_inc:true,
    TokenType.op_dec:true,
	TokenType.lo_and:true,
	TokenType.lo_or:true,
	TokenType.lo_not:true,
	TokenType.sy_ass:true,
	TokenType.sy_eq:true,
    TokenType.sy_neq:true,
	TokenType.sy_gr:true,
	TokenType.sy_le:true,
	TokenType.sy_gre:true,
	TokenType.sy_lee:true,
	TokenType.sy_term:true,
	TokenType.sy_comma:true,
    TokenType.sy_colan:true,
	TokenType.sy_dot:true,
    TokenType.sy_tinary:true,
	TokenType.kw_if:false,
    TokenType.kw_else:false,
	TokenType.kw_for:false,
	TokenType.kw_foreach:false,
	TokenType.kw_do:false,
	TokenType.kw_until:false,
	TokenType.kw_while:false,
	TokenType.kw_def:false,
	TokenType.kw_class:false,
	TokenType.kw_inherits:false,
	TokenType.kw_static:false,
	TokenType.kw_abstract:false,
	TokenType.kw_interface:false,
	TokenType.kw_function:false,
	TokenType.kw_return:false,
    TokenType.kw_break:false,
    TokenType.kw_jump:false,
	TokenType.kw_import:false,
	TokenType.kw_module:false,
    TokenType.kw_new:false,
    TokenType.kw_pragma:false,
	TokenType.br_exo:true,
	TokenType.br_exc:true,
	TokenType.br_ixo:true,
	TokenType.br_ixc:true,
	TokenType.br_blo:true,
	TokenType.br_blc:true,
	TokenType.cu_word:false,
	TokenType.cu_number:false,
	TokenType.cu_string:false,
];

alias Token = TokenStream.Token;

class TokenStream
{
	uint i;
	string str;
    Token[] tokens;
    
	class Token
	{
		TokenType type;
		string text;
		uint line;
		uint colunm;
		this(string text,TokenType type)
		{
			this.text=text;
			this.type = type;
			this.colunm = toColunm(str,i);
			this.line = toLine(str,i);
		}
	}
    
	this(string str)
	{
		this.str = str;
	}
    Token tryAdvance()
    {
        return i<tokens.length ? tokens[i++] : null;
    }
    Token tryNow()
    {
        return i<tokens.length ? tokens[i] : null;
    }
    Token tryNext()
    {
        return i+1<tokens.length ? tokens[i+1] : null;
    }
    Token advance()
    {
        if (i<tokens.length)
            return tokens[i++];
        else
            throw new LexerException("unexpected end of file");
    }
    Token retreat()
    {
        i--;
        if (i<tokens.length)
            return tokens[i+1];
        else
            throw new LexerException("unexpected end of file");
    }
    Token now()
    {
        if (i<tokens.length)
            return tokens[i];
        else
            throw new LexerException("unexpected end of file");
    }
    Token previous()
    {
        if(i-1<tokens.length)
            return tokens[i-1];
        else 
            throw new LexerException("unexpected end of file");
    }
    Token next()
    {
        if(i+1<tokens.length)
            return tokens[i+1];
        else
            throw new LexerException("unexpected end of file");
    }
    
    TokenStream process()
    {
        charLoop: for(;i<str.length;i++)
        {
            if (str[i].isWhiteSpace())
            {
                continue;
            }
            foreach(k;TokensSorted)
            {
                TokenType v = TokenMap[k];
                string slice = i+k.length<str.length ? str[i..i+k.length] : "";
                if (k == slice && Delimiters[v])
                {
                    i+=k.length-1;
                    tokens~=new Token(k,v);
                    continue charLoop;
                }
                else if(k == slice && (i+k.length>=str.length
                    || str[i+k.length].isWhiteSpace()))
                {
                    i+=k.length-1;
                    tokens~=new Token(k,v);
                    continue charLoop;
                }
                else if (k == slice)
                {
                    uint j = i+k.length;
                    foreach(k1,v1;TokenMap)
                    {
                        string slice = j+k1.length<str.length ?
                             str[j..j+k1.length] : "";
                        if (k1 == slice && Delimiters[v1])
                        {
                            i+=k.length-1;
                            tokens~=new Token(k,v);
                            continue charLoop;
                        }
                    }
                }
                else
                    continue;
            }
            LexResult id,num,istr;
            if ((num = str[i..$].number()).success)
            {
                if ((num.length > 2
                    && (num.value[0..2] == "0x" || num.value[0..2] == "0X"))
                    && !(num.length == 1+2
                        || num.length == 2+2
                        || num.length == 4+2
                        || num.length == 8+2
                        || num.length == 16+2))
                    throw new LexerException("Incorrect length for hexdecimal %s"
                        ~"\nat line: %s",
                        num.length-2,
                        toLine(str,i),
                        toColunm(str,i));
                tokens~=new Token(num,TokenType.cu_number);
				i+=num.length-1;
            }
            else if ((id = str[i..$].identifier()).success)
            {
				tokens~=new Token(id,TokenType.cu_word);
				i+=id.length-1;
            }
            else if ((istr = str[i..$].str()).success)
            {
				tokens~=new Token(istr[1..$-1],TokenType.cu_string);
				i+=istr.length-1;
            }
            else if (str[i..$] != "")
            {
                throw new LexerException("Invalid symbol %s\nat line: %s\ncolunm: %s"
                        ,str[i],toLine(str,i),toColunm(str,i)
                    );
            }
        }
        i = 0;
        return this;
    }
}

bool isWhiteSpace(char chr)
{
	return chr == '\r' || chr == '\n' || chr == '\t' || chr == ' ';
}

struct LexResult
{
    string value;
    bool success;
    alias toString this;
    this(string value, bool success = true)
    {
        this.success = success;
        this.value = value;
    }
    @property string toString()
    {
        return value;
    }
    T opCast(T)() if(is(T == bool))
    {
        return sucess;
    }
}

auto identifier(string str)
{
	enum alnumRegex = ctRegex!(`^[A-Z_a-z][A-Z_a-z0-9]*`);
	auto captures = matchFirst(str, alnumRegex);
	if (captures.empty)
	    return LexResult("",false);
    else
        return LexResult(captures.hit,true);
}

auto number(string str)
{
    enum decRegex = ctRegex!(`^[0-9]+(\.[0-9]+)?`);
    enum hexRegex = ctRegex!(`^0[xX][0-9a-fA-F]+`);
    auto captures = matchFirst(str,hexRegex);
    if (!captures.empty)
        return LexResult(captures.hit,true);
	captures = matchFirst(str,decRegex);
    if (!captures.empty)
        return LexResult(captures.hit,true);
    return LexResult("",false);
}

auto str(string str)
{
    enum singleStringRegex = ctRegex!(`\'.*\'`);
    enum doubleStringRegex = ctRegex!(`\".*\"`);
    auto captures = matchFirst(str,singleStringRegex);
    if (!captures.empty)
        return LexResult(captures.hit,true);
	captures = matchFirst(str,doubleStringRegex);
    if (!captures.empty)
        return LexResult(captures.hit,true);
	return LexResult("",false);
}

class LexerException : Exception
{
    this(T...)(string msg, T t)
    {
        static if(T.length == 0)
            super(msg);
        else
            super(format(msg,t));
    }
}
