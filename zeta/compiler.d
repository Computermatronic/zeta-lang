module zeta.compiler;

import std.outbuffer;

import zeta.parser;
import zeta.lexer;


class Compiler
{
    DList!ParserNode parseTree;
    VScope vs;
    this(string source)
    {
        parseTree = parse(new TokenStream(source));
    }
    void compile()
    {
        foreach(parserNode; parseTree)
            compile(parserNode);
    }
    void compile(ParserNode parserNode)
    {
        final switch(parserNode.type())
        {
            case "expression":
                ExpressionNode exp = (cast(Expression)parserNode).exp;
                compile(exp);
                break;
            case "if":
                If if_ = cast(If)parserNode;
                break;
            case "for":
                For for_ = cast(For)parserNode;
                break;
            case "foreach":
                Foreach foreach_ = cast(Foreach)parserNode;
                break;
            case "until":
                Until until = cast(Until)parserNode;
                break;
            case "while":
                While while_ = cast(While)parserNode;
                break;
            case "def":
                Def def = cast(Def)parserNode; 
                break;
            case "class":
                Class class_ = cast(Class)parserNode;
                break;
            case "interface":
                Interface_ interface_ = cast(Interface_)parserNode;
                break;
            case "function":
                Function func = cast(Function)parserNode;
                break;
            case "return":
                Return return_ = cast(Return)parserNode;
                break;
            case "break":
                break;
            case "jump":
                break;
            case "import":
                Import import_ = cast(Import)parserNode;
                break;
            case "block":
                Block block = cast(Block)parserNode;
                foreach(nparserNode;block.body_)
                    compile(nparserNode);
                break;
        }
    }
    
    void compile(ExpressionNode expressionNode)
    {
        final switch(expressionNode.type())
        {
            case "number":
                NumberLit numberLit = cast(NumberLit)expressionNode;
                break;
            case "string":
                StringLit stringLit = cast(StringLit)expressionNode;
                break;
            case "identifier":
                Identifier identifier = cast(Identifier)expressionNode;
                break;
            case "call":
                FunctionCall functionCall = cast(FunctionCall)expressionNode;
                break;
            case "binaryop":
                BinaryOp arithmitic = cast(BinaryOp)expressionNode;
                break;
            case "unary":
                Unary unary = cast(Unary)expressionNode;
                break;
            case "unarymod":
                UnaryMod unaryMod = cast(UnaryMod)expressionNode;
                break;
            case "dispatch":
                Dispatch dispatch = cast(Dispatch)expressionNode;
                break;
            case "index":
                Index index = cast(Index)expressionNode;
                break;
            case "tinary":
                Tinary tinary = cast(Tinary)expressionNode;
                break;
            case "bracketed":
                Bracketed bracketed = cast(Bracketed)expressionNode;
                break;
            case "assign":
                Assign assign = cast(Assign)expressionNode;
                break;
        }
    }
}
