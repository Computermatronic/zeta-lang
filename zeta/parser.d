module zeta.parser;

import zeta.lexer;
import zeta.utils;

import std.conv : to;
import std.format : format;
public import std.container : DList;

class ParserException : Exception
{
    this(T...)(string msg,T t)
    {
        static if (T.length == 0)
            super(msg);
        else
            super(format(msg,t));
    }
}

enum Precedence:uint
{
    dispatch = 1,
    index = 2,
    call = 4,
    operate = 8,
    all = dispatch | index | call | operate
}

bool hasPrecedence(uint wanted, uint gotten)
{
    return (gotten & wanted) == wanted;
}

interface ExpressionNode
{
    @property string str();
    @property string type();
    @property uint line();
}


class NumberLit : ExpressionNode
{
    string number;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        number = stream.advance().text;
    }
    @property string str()
    {
        return number;
    }
    @property uint line()
    {
        return iline;
    }
    
    @property string type() { return "number"; }
}

class StringLit : ExpressionNode
{
    string string_;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        string_ = stream.advance().text;
    }
    @property string str()
    {
        return '"'~string_~'"';
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "string"; }
}

class ArrayLit : ExpressionNode
{
    ExpressionNode[] elements;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now.line;
        advanceTest(TokenType.br_ixo,stream);
        foreach(i;stream.tokens)
        {
            elements ~= parseExpression(stream);
            if (stream.now().type == TokenType.br_ixc)
            {
                stream.advance();
                break;
            }
            else advanceTest(TokenType.sy_comma,stream);
        }
    }
    
    @property string str()
    {
        string str = "[";
        foreach(i,element;elements)
        {
            str ~= element.str ~ (i==elements.length-1 ? "]" : ", ");
        }
        return str;
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "array"; }
}

class Identifier : ExpressionNode
{
    string id;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        id = stream.advance().text;
    }
    @property string str()
    {
        return id;
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "identifier"; }
}

class FunctionCall : ExpressionNode
{
    ExpressionNode from;
    ExpressionNode[] args;
    uint iline;
    this(ExpressionNode lhs, TokenStream stream)
    {
        iline = lhs.line;
        from = lhs;
        advanceTest(TokenType.br_exo,stream);
        if (stream.now().type == TokenType.br_exc)
        {
            stream.advance();
            return;
        }
        foreach(i;stream.tokens)
        {
            args ~= parseExpression(stream);
            if (stream.now().type == TokenType.br_exc)
            {
                stream.advance();
                break;
            }
            else advanceTest(TokenType.sy_comma,stream);
        }
    }
    @property string str()
    {
        string base = from.str()~"(";
        foreach(i,arg;args)
        {
            base ~= arg.str ~ (i==args.length-1 ? "" : ", ");
        }
        return base ~ ")";
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "call"; }
}

class BinaryOp : ExpressionNode
{
    ExpressionNode lhs, rhs;
    string op;
    uint iline;
    this(ExpressionNode lhs,TokenStream stream)
    {
        iline = lhs.line;
        this.lhs = lhs;
        this.op = stream.advance().text;
        this.rhs = parseExpression(stream,
            Precedence.call | Precedence.dispatch | Precedence.index);
    }
    @property string str()
    {
        return lhs.str() ~ op ~ rhs.str();
    }
    @property uint line()
    {
        return iline;
    }   
    @property string type() { return "binaryop"; }
}

class Unary : ExpressionNode
{
    ExpressionNode rhs;
    string lhs;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        if (stream.next().type == stream.now().type)
        {
            lhs = stream.advance().text;
        }
        else
            lhs = stream.now().text;
        stream.advance();
        rhs = parseExpression(stream);
    }
    
    @property string str()
    {
        return lhs ~ rhs.str();
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "unary"; }
}

class UnaryMod : ExpressionNode
{
    ExpressionNode lhs;
    string rhs;
    uint iline;
    this(ExpressionNode lhs,TokenStream stream)
    {
        iline = lhs.line;
        this.lhs = lhs;
        this.rhs = stream.advance().text;
    }
    @property string str()
    {
        return lhs.str() ~ rhs;
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "unarymod"; }
}

class Dispatch : ExpressionNode
{
    ExpressionNode lhs;
    string index;
    uint iline;
    this(ExpressionNode lhs, TokenStream stream)
    {
        iline = lhs.line;
        this.lhs = lhs;
        advanceTest(TokenType.sy_dot,stream);
        this.index = advanceTest(TokenType.cu_word,stream).text;
    }
    @property string str()
    {
        return lhs.str() ~ '.' ~ index;
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "dispatch"; }
}

class Index : ExpressionNode
{
    ExpressionNode lhs,index;
    uint iline;
    this(ExpressionNode lhs,TokenStream stream)
    {
        iline = lhs.line;
        this.lhs = lhs;
        advanceTest(TokenType.br_ixo,stream);
        index = parseExpression(stream);
        advanceTest(TokenType.br_ixc,stream);
    }
    @property string str()
    {
        return lhs.str() ~ '[' ~ index.str() ~ "]";
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "index"; }
}

class Tinary : ExpressionNode
{
    ExpressionNode lhs,ifTrue, ifFalse;
    uint iline;
    this(ExpressionNode lhs,TokenStream stream)
    {
        iline = lhs.line;
        this.lhs = lhs;
        advanceTest(TokenType.sy_tinary,stream);
        ifTrue = parseExpression(stream);
        advanceTest(TokenType.sy_colan,stream);
        ifFalse = parseExpression(stream);
    }
    @property string str()
    {
        return lhs.str() ~ '?' ~ ifTrue.str ~ ':' ~ ifFalse.str;
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "tinary"; }
}

class Bracketed : ExpressionNode
{
    ExpressionNode contained;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.br_exo,stream);
        contained = parseExpression(stream);
        advanceTest(TokenType.br_exc,stream);
    }
    @property string str()
    {
        return '(' ~ contained.str() ~ ')';
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "bracketed"; }
}

class New : ExpressionNode
{
    string what;
    ExpressionNode[] args;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now.line;
        advanceTest(TokenType.kw_new,stream);
        what = advanceTest(TokenType.cu_word,stream).text;
        advanceTest(TokenType.br_exo,stream);
        if (stream.now().type == TokenType.br_exc)
        {
            stream.advance();
            return;
        }
        foreach(i;stream.tokens)
        {
            args ~= parseExpression(stream);
            if (stream.now().type == TokenType.br_exc)
            {
                stream.advance();
                break;
            }
            else advanceTest(TokenType.sy_comma,stream);
        }
    }
    @property string str()
    {
        string base = "new "~what~"(";
        foreach(i,arg;args)
        {
            base ~= arg.str ~ (i==args.length-1 ? "" : ", ");
        }
        return base ~ ")";
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "new"; }
}

class Assign : ExpressionNode
{
    ExpressionNode what;
    ExpressionNode assign;
    uint iline;
    this(ExpressionNode lhs,TokenStream stream)
    {
        iline = lhs.line;
        if (lhs.type != "identifier" &&
            lhs.type != "index" &&
            lhs.type != "dispatch")
            throw new ParserException(
                "%s is not an lvalue\nat line: %s"
                ,lhs.str,iline);
        what = lhs;
        advanceTest(TokenType.sy_ass,stream);
        assign = parseExpression(stream);
    }
    @property string str()
    {
        return what.str() ~ " = " ~assign.str();
    }
    @property uint line()
    {
        return iline;
    }
    @property string type() { return "assign"; }
}

ExpressionNode parseExpression(TokenStream stream, int prec = Precedence.all)
{
    if (stream.tryNow() is null)
        throw new ParserException("Unexpected end of expression a line %s",
            stream.now.line);
    switch(stream.now().type)
    {
        case TokenType.cu_number:
            return forward(new NumberLit(stream),stream,prec);
        case TokenType.cu_string:
            return forward(new StringLit(stream),stream,prec);
        case TokenType.br_ixo:
            return forward(new ArrayLit(stream),stream,prec);
        case TokenType.cu_word:
            return forward(new Identifier(stream),stream,prec);
        case TokenType.op_add:
        case TokenType.op_sub:
        case TokenType.op_inc:
        case TokenType.op_dec:
        case TokenType.lo_not:
            return forward(new Unary(stream),stream,prec);
        case TokenType.br_exo:
            return forward(new Bracketed(stream),stream,prec);
        case TokenType.kw_new:
            return forward(new New(stream),stream,prec);
        default:
            throw new ParserException(
                "Expected expression got %s\nat line: %s",stream.now.text,stream.now.line);
    }
}

ExpressionNode forward(ExpressionNode lhs, TokenStream stream, int prec = Precedence.all)
{
    if (stream.tryNow() is null)
        return lhs;
    switch(stream.now().type)
    {
        case TokenType.br_exo:
            if (!hasPrecedence(Precedence.call,prec))
                return lhs;
            else
                return forward(new FunctionCall(lhs,stream),stream,);
        case TokenType.op_inc:
        case TokenType.op_dec:
            if (!hasPrecedence(Precedence.call,prec))
                return lhs;
            else
                return forward(new UnaryMod(lhs,stream),stream);
        case TokenType.op_add:
        case TokenType.op_sub:
        case TokenType.op_mul:
        case TokenType.op_div:
        case TokenType.op_mod:
        case TokenType.sy_gr:
        case TokenType.sy_le:
        case TokenType.sy_eq:
        case TokenType.sy_gre:
        case TokenType.sy_lee:
        case TokenType.sy_neq:
        case TokenType.lo_and:
        case TokenType.lo_or:
            if (!hasPrecedence(Precedence.operate,prec))
                return lhs;
            else
                return forward(new BinaryOp(lhs,stream),stream);
        case TokenType.br_ixo:
            if (!hasPrecedence(Precedence.index,prec))
                return lhs;
            else
                return forward(new Index(lhs,stream),stream);
        case TokenType.sy_tinary:
            return forward(new Tinary(lhs,stream),stream);
        case TokenType.sy_dot:
            if (!hasPrecedence(Precedence.dispatch,prec))
                return lhs;
            else
                return forward(new Dispatch(lhs,stream),stream);
        case TokenType.sy_ass:
                return forward(new Assign(lhs,stream),stream);
        default:
            return lhs;
    }
}

Token nowTest(TokenType expected,TokenStream stream)
{
        if (stream.tryNow() is null)
        throw new ParserException("expected %s but got <EOF>",
                ErrorMap[expected]);
    else if (stream.tryNow().type != expected)
        throw new ParserException("expected %s but got %s\nat line: %s",
                ErrorMap[expected],
                ErrorMap[stream.now().type],
                stream.tryNow.line);
    else
        return stream.tryNow();
}

Token advanceTest(TokenType expected,TokenStream stream)
{
        if (stream.tryNow() is null)
            throw new ParserException("expected %s but got <EOF>",
                ErrorMap[expected]);
        else if (stream.tryNow().type != expected)
            throw new ParserException("expected %s but got %s\nat line: %s",
                ErrorMap[expected],
                ErrorMap[stream.now().type],
                stream.tryNow.line);
    else
        return stream.tryAdvance();
}

interface ParserNode
{
    @property string str();
    @property string type();
    @property uint line();
}

class Pragma : ParserNode
{
    string pragma_;
    string flag;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now.line;
        advanceTest(TokenType.kw_pragma,stream);
        advanceTest(TokenType.br_exo,stream);
        pragma_ = advanceTest(TokenType.cu_word,stream).text;
        advanceTest(TokenType.sy_comma,stream);
        flag = advanceTest(TokenType.cu_string,stream).text;
        advanceTest(TokenType.br_exc,stream);
    }
    @property string str()
    {
        return "pragma("~pragma_~","~flag~")";
    }
    @property string type()
    {
        return "pragma";
    }
    @property uint line()
    {
        return iline;
    }
}

class Expression : ParserNode
{
    ExpressionNode exp;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        exp = parseExpression(stream);
    }
    @property string str()
    {
        return exp.str();
    }
    @property string type()
    {
        return "expression";
    }
    @property uint line()
    {
        return iline;
    }
}

class If : ParserNode
{
    Expression cond;
    Block then;
    Block else_;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_if,stream);
        advanceTest(TokenType.br_exo,stream);
        cond = new Expression(stream);
        advanceTest(TokenType.br_exc,stream);
        then = new Block(stream);
        if (stream.tryNow() !is null && stream.now().type == TokenType.kw_else)
        {
            stream.advance();
            else_ = new Block(stream);
        }
    }
    @property string str()
    {
        return "if " ~ cond.str() ~ '\n'~ then.str() ~
            (else_ !is null ? " else\n" ~ else_.str() : "");
    }
    @property string type()
    {
        return "if";
    }
    @property uint line()
    {
        return iline;
    }
}

class For : ParserNode
{
    Def var;
    Expression cond;
    Expression step;
    Block loop;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_for,stream);
        advanceTest(TokenType.br_exo,stream);
        var = new Def(stream);
        advanceTest(TokenType.sy_term,stream);
        cond = new Expression(stream);
        advanceTest(TokenType.sy_term,stream);
        step = new Expression(stream);
        advanceTest(TokenType.br_exc,stream);
        loop = new Block(stream);
    }
    @property string str()
    {
        return "for " ~ var.str() ~ ';' ~ cond.str() ~ ';' ~ step.str()
            ~ '\n' ~ loop.str();
    }
    @property string type()
    {
        return "for";
    }
    @property uint line()
    {
        return iline;
    }
}

class Foreach : ParserNode
{
    string init;
    Expression iterator;
    Block loop;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_foreach,stream);
        advanceTest(TokenType.br_exo,stream);
        init = advanceTest(TokenType.cu_word,stream).text;
        advanceTest(TokenType.sy_term,stream);
        iterator = new Expression(stream);
        advanceTest(TokenType.br_exc,stream);
        loop = new Block(stream);
    }
    @property string str()
    {
        return "foreach" ~ init ~ ';' ~ iterator.str() ~ '\n' ~ loop.str();
    }
    @property string type()
    {
        return "foreach";
    }
    @property uint line()
    {
        return iline;
    }
}

class Until : ParserNode
{
    Expression cond;
    Block loop;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_do,stream);
        loop = new Block(stream);
        advanceTest(TokenType.kw_until,stream);
        advanceTest(TokenType.br_exo,stream);
        cond = new Expression(stream);
        advanceTest(TokenType.br_exc,stream);
    }
    @property string str()
    {
        return "do\n"~loop.str()~"\nuntil "~cond.str();
    }
    @property string type()
    {
        return "until";
    }
    @property uint line()
    {
        return iline;
    }
}

class While : ParserNode
{
    Expression cond;
    Block loop;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_while,stream);
        advanceTest(TokenType.br_exo,stream);
        cond = new Expression(stream);
        advanceTest(TokenType.br_exc,stream);
        loop = new Block(stream);
    }
    @property string str()
    {
        return "while "~cond.str~'\n'~loop.str;
    }
    @property string type()
    {
        return "while";
    }
    @property uint line()
    {
        return iline;
    }
}

class Def : ParserNode
{
    string name;
    Expression initializer;
    bool isStatic;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        if (stream.now().type == TokenType.kw_static)
        {
            isStatic = true;
            stream.advance();
        }
        advanceTest(TokenType.kw_def,stream);
        name = advanceTest(TokenType.cu_word,stream).text;
        if (stream.tryNow() !is null && stream.now().type == TokenType.sy_ass)
        {
            stream.advance();
            initializer = new Expression(stream);
        }
    }
    @property string str()
    {
        return "def "~name~(initializer !is null ? '=' ~ initializer.str : "");
    }
    @property string type()
    {
        return "def";
    }
    @property uint line()
    {
        return iline;
    }
}

class Param : ParserNode
{
    string name;
    Expression initializer;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        name = advanceTest(TokenType.cu_word,stream).text;
        if (stream.advance().type == TokenType.sy_ass)
            initializer = new Expression(stream);
        else
            stream.retreat();
    }
    @property string str()
    {
        return name~(initializer !is null ? '=' ~ initializer.str : "");
    }
    @property string type()
    {
        return "param";
    }
    @property uint line()
    {
        return iline;
    }
}

class Class : ParserNode
{
    string name;
    string[] parents;
    ClassBlock cBlock;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_class,stream);
        name = advanceTest(TokenType.cu_word,stream).text;
        if (stream.now().type == TokenType.kw_inherits)
        {
            stream.advance();
            parents ~= advanceTest(TokenType.cu_word,stream).text;
            while(true)
            {
                if (stream.now().type == TokenType.sy_comma)
                {
                    stream.advance();
                    parents ~= advanceTest(TokenType.cu_word,stream).text;
                }
                else
                {
                    break;
                }
            }
        }
        cBlock = new ClassBlock(stream);
    }
    @property string str()
    {
        return "class " ~ name ~ " inherits "~to!string(parents)~'\n'~
            cBlock.str();
    }
    @property string type()
    {
        return "class";
    }
    @property uint line()
    {
        return iline;
    }
}

class Interface_ : ParserNode
{
    InterfaceBlock iBlock;
    string name;
    string[] parents;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_interface,stream);
        name = advanceTest(TokenType.cu_word,stream).text;
        if (stream.now().type == TokenType.kw_inherits)
        {
            stream.advance();
            parents ~= advanceTest(TokenType.cu_word,stream).text;
            while(true)
            {
                if (stream.advance().type == TokenType.sy_comma)
                {
                    parents ~= advanceTest(TokenType.cu_word,stream).text;
                }
                else
                {
                    stream.retreat();
                    break;
                }
            }
        }
        iBlock = new InterfaceBlock(stream);
    }
    @property string str()
    {
        return "interface " ~ name ~ " inherits "~to!string(parents)~'\n'~
            iBlock.str();
    }
    @property string type()
    {
        return "interface";
    }
    @property uint line()
    {
        return iline;
    }
}

class Function : ParserNode
{
    string name;
    Param[] args;
    Block func;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_function,stream);
        name = advanceTest(TokenType.cu_word,stream).text;
        advanceTest(TokenType.br_exo,stream);
        if (stream.now().type != TokenType.br_exc)
            args ~= new Param(stream);
        while(true)
        {
            if (stream.now().type == TokenType.br_exc)
                break;
            else if (stream.now().type == TokenType.sy_comma)
                args ~= new Param(stream);
        }
        advanceTest(TokenType.br_exc,stream);
        func = new Block(stream);
    }
    @property string str()
    {
        return "function "~name~to!string(args)~'\n'~func.str();
    }
    @property string type()
    {
        return "function";
    }
    @property uint line()
    {
        return iline;
    }
}

class Return : ParserNode
{
    Expression return_;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_return,stream);
        if (stream.now().type != TokenType.sy_term)
            return_ = new Expression(stream);
    }
    @property string str()
    {
        return "return " ~ (return_ !is null ? return_.str() : "");
    }
    @property string type()
    {
        return "return";
    }
    @property uint line()
    {
        return iline;
    }
}

class Break : ParserNode
{
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_break,stream);
    }
    @property string str()
    {
        return "break";
    }
    @property string type()
    {
        return "break";
    }
    @property uint line()
    {
        return iline;
    }
}
class Jump : ParserNode
{
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_jump,stream);
    }
    @property string str()
    {
        return "jump";
    }
    @property string type()
    {
        return "jump";
    }
    @property uint line()
    {
        return iline;
    }
}

class Block : ParserNode
{
    ParserNode[] body_;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        if (stream.now().type == TokenType.br_blo)
        {
            stream.advance();
            while(stream.now().type != TokenType.br_blc)
            {
                body_ ~= statement(stream);
            }
            stream.advance();
        }
        else
           body_ ~= statement(stream);
    }
    @property string str()
    {
        string result = "{\n";
        foreach(line;body_)
            result ~= line.str() ~ '\n';
        return result ~ "}";
    }
    @property string type()
    {
        return "block";
    }
    @property uint line()
    {
        return iline;
    }
}

class ClassBlock : ParserNode
{
    ParserNode[] members;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        if (stream.advance().type == TokenType.br_blo)
        {
            while(stream.now().type != TokenType.br_blc)
            {
                next(stream);
            }
        }
        else
            next(stream);
    }
    void next(TokenStream stream)
    {
        switch(stream.now().type)
        {
            case TokenType.kw_function:
                members ~= new Function(stream);
                break;
            case TokenType.kw_def:
                members ~= new Def(stream);
                advanceTest(TokenType.sy_term,stream);
                break;
            default:
                throw new ParserException(
                    "unrecognised decleration "~stream.now().text);
        }
    }
    @property string str()
    {
        string result = "{\n";
        foreach(line;members)
            result ~= line.str() ~ '\n';
        return result ~ "}";
    }
    @property string type()
    {
        return "classblock";
    }
    @property uint line()
    {
        return iline;
    }
}

class InterfaceBlock : ParserNode
{
    FunctionPrototype[] members;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        if (stream.advance().type == TokenType.br_blo)
        {
            while(stream.now().type != TokenType.br_blc)
            {
                next(stream);
            }
        }
        else
           next(stream);
    }
    void next(TokenStream stream)
    {
        switch(stream.now().type)
        {
            case TokenType.kw_function:
                members ~= new FunctionPrototype(stream);
                advanceTest(TokenType.sy_term,stream);
                break;
            default:
                throw new ParserException(
                    "unrecognised decleration "~stream.now().text);
        }
    }
    @property string str()
    {
        string result = "{\n";
        foreach(line;members)
            result ~= line.str() ~ '\n';
        return result ~ "}";
    }
    @property string type()
    {
        return "interfaceblock";
    }
    @property uint line()
    {
        return iline;
    }
}

class FunctionPrototype : ParserNode
{
    string name;
    Param[] args;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_function,stream);
        name = advanceTest(TokenType.cu_word,stream).text;
        advanceTest(TokenType.br_exo,stream);
        if (stream.now().type != TokenType.br_exc)
            args ~= new Param(stream);
        while(true)
        {
            if (stream.now().type == TokenType.br_exc)
                break;
            else if (stream.now().type == TokenType.sy_comma)
                args ~= new Param(stream);
        }
        advanceTest(TokenType.br_exc,stream);
    }
    @property string str()
    {
        return "function "~name~to!string(args);
    }
    @property string type()
    {
        return "protofunction";
    }
    @property uint line()
    {
        return iline;
    }
}

class Import : ParserNode
{
    string importee;
    uint iline;
    this(TokenStream stream)
    {
        iline = stream.now().line;
        advanceTest(TokenType.kw_import,stream);
        while(true)
        {
            auto now = stream.now();
            if (now.type == TokenType.cu_word || now.type == TokenType.sy_dot)
            {
                importee~=now.text;
                stream.advance();
            }
            else
                break;
        }
    }
    @property string str()
    {
        return "import " ~ importee;
    }
    @property string type()
    {
        return "import";
    }
    @property uint line()
    {
        return iline;
    }
}

DList!ParserNode parse(TokenStream stream)
{
    DList!ParserNode result;
    while(stream.tryNow() !is null)
    {
        result.insertBack(statement(stream));
    }
    return result;
}

ParserNode statement(TokenStream stream)
{
    ParserNode result;
    switch(stream.now().type)
    {
        case TokenType.kw_pragma:
            result = new Pragma(stream);
            advanceTest(TokenType.sy_term,stream);
            break;
        case TokenType.kw_if:
            result = new If(stream);
            break;
        case TokenType.kw_for:
            result = new For(stream);
            break;
        case TokenType.kw_foreach:
            result = new Foreach(stream);
            break;
        case TokenType.kw_until:
            result = new Until(stream);
            break;
        case TokenType.kw_while:
            result = new While(stream);
            break;
        case TokenType.kw_do:
            result = new Until(stream);
            break;
        case TokenType.kw_def:
        case TokenType.kw_static:
            result = new Def(stream);
            advanceTest(TokenType.sy_term,stream);
            break;
        case TokenType.kw_class:
            result = new Class(stream);
            break;
        case TokenType.kw_interface:
            result = new Interface_(stream);
            break;
        case TokenType.kw_function:
            result = new Function(stream);
            break;
        case TokenType.kw_return:
            result = new Return(stream);
            advanceTest(TokenType.sy_term,stream);
            break;
        case TokenType.kw_break:
            result = new Break(stream);
            advanceTest(TokenType.sy_term,stream);
            break;
        case TokenType.kw_jump:
            result = new Jump(stream);
            advanceTest(TokenType.sy_term,stream);
            break;
        case TokenType.kw_import:
            result = new Import(stream);
            advanceTest(TokenType.sy_term,stream);
            break;
        default:
            result = new Expression(stream);
            advanceTest(TokenType.sy_term,stream);
            break;
    }
    return result;
}
