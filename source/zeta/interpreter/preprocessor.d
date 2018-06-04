module zeta.analyser;

import zeta.parser;
import zeta.utils;

class Analyser
{
    DList!ParserNode parseTree;
    LexicalScope moduleScope;
    Stack!LexicalScope localScope;
    LexicalScope[] analysedScopes;
    
    this()
    {
        moduleScope = new LexicalScope();
        localScope.push(moduleScope);
    }
    this(DList!ParserNode pTree)
    {
        moduleScope = new LexicalScope();
        localScope.push(moduleScope);
        foreach(node;pTree)
            if (node.type == "function")
            {
                localScope.peek().resolve((cast(Function)node).name);
                parseTree.insertFront(node);
            }
            else
                parseTree.insertBack(node);
    }
    void analyse()
    {
        foreach(node;parseTree)
            analyse(node);
    }
    void analyse(ParserNode parserNode)
    {
        switch(parserNode.type())
        {
            case "expression":
                analyse((cast(Expression)parserNode).exp);
                break;
            case "pragma":
                Pragma pragma_ = cast(Pragma)parserNode;
                throw new AnalyserException("pragma not supported/nat line: %s",
                    pragma_.line);
                break;
            case "if":
                If if_ = cast(If)parserNode;
                localScope.push(new LexicalScope(localScope.peek(),if_));
                analyse(if_.then);
                analysedScopes~=localScope.pop();
                if (if_.else_ !is null)
                {
                    localScope.push(new LexicalScope(localScope.peek(),if_));
                    analyse(if_.else_);
                    analysedScopes~=localScope.pop();
                }
                break;
            case "for":
                For for_ = cast(For)parserNode;
                localScope.push(new LexicalScope(localScope.peek(),for_));
                analyse(for_.var);
                analyse(for_.cond.exp);
                analyse(for_.loop);
                analysedScopes~=localScope.pop();
                break;
            case "foreach":
                Foreach foreach_ = cast(Foreach)parserNode;
                localScope.push(new LexicalScope(localScope.peek(),foreach_));
                analyse(foreach_.iterator);
                analyse(foreach_.loop);
                analysedScopes~=localScope.pop();
                break;
            case "until":
                Until until = cast(Until)parserNode;
                localScope.push(new LexicalScope(localScope.peek(),until));
                analyse(until.loop);
                analyse(until.cond);
                analysedScopes~=localScope.pop();
                break;
            case "while":
                While while_ = cast(While)parserNode;
                localScope.push(new LexicalScope(localScope.peek(),while_));
                analyse(while_.cond.exp);
                analyse(while_.loop);
                analysedScopes~=localScope.pop();
                break;
            case "def":
                Def def = cast(Def)parserNode;
                analyse(def.initializer);
                if (!localScope.peek().defined(def.name))
                    localScope.peek().resolve(def.name);
                else
                    throw new AnalyserException("decleration duplication %s\nat line: %s",
                        def.name,def.line);
                break;
            case "class":
                Class class_ = cast(Class)parserNode;
                throw new AnalyserException("classes not supportered\nat line: %s",
                    class_.line);
            case "interface":
                Interface_ interface_ = cast(Interface_)parserNode;
                throw new AnalyserException("interfaces not supportered\nat line: %s",
                    interface_.line);
            case "function":
                Function func = cast(Function)parserNode;
                localScope.push(new LexicalScope(localScope.peek(),func));
                if (!localScope.peek().defined(func.name))
                    localScope.peek().resolve(func.name);
                else
                    throw new AnalyserException("function duplication %s\nat line: %s"
                        ,func.name,func.line);
                foreach(arg;func.args)
                {
                    analyse(arg.initializer);
                    localScope.peek().resolve(arg.name);
                }
                analyse(func.func);
                analysedScopes~=localScope.pop();
                break;
            case "return":
                Return return_ = cast(Return)parserNode;
                if (!inFunc(localScope.peek()))
                    throw new AnalyserException("Return statement not in function"~
                        "\nat line: %s",return_.line);
                analyse(return_.return_.exp);
                break;
            case "break":
                if (!inLoop(localScope.peek()))
                    throw new AnalyserException("Break statement not in loop"~
                        "\nat line: %s",parserNode.line);
                break;
            case "jump":
                if (!inLoop(localScope.peek()))
                    throw new AnalyserException("Jump statement not in loop"~
                        "\nat line: %s",parserNode.line);
                break;
            case "import":
                Import import_ = cast(Import)parserNode;
                break;
            case "block":
                Block block = cast(Block)parserNode;
                foreach(nparserNode;block.body_)
                {
                    analyse(nparserNode);
                }
                break;
            default:
                throw new AnalyserException("unrecognised decleration %s", parserNode);
        }
    }
    void analyse(ExpressionNode expressionNode)
    {
        switch(expressionNode.type())
        {
            case "number":
            case "string":
                break;
            case "identifier":
                Identifier id = cast(Identifier)expressionNode;
                if (isLvalue(id.id))
                    localScope.peek().request(id.id);
                break;
            case "call":
                FunctionCall call = cast(FunctionCall)expressionNode;
                analyse(call.from);
                foreach(arg;call.args)
                    analyse(arg);
                break;
            case "binaryop":
                BinaryOp op = cast(BinaryOp)expressionNode;
                analyse(op.lhs);
                analyse(op.rhs);
                break;
            case "unary":
                Unary op = cast(Unary)expressionNode;
                analyse(op.rhs);
                break;
            case "unarymod":
                UnaryMod op = cast(UnaryMod)expressionNode;
                analyse(op.lhs);
                break;
            case "dispatch":
                Dispatch dispatch = cast(Dispatch)expressionNode;
                analyse(dispatch.lhs);
               break;
            case "index":
                Index index = cast(Index)expressionNode;
                analyse(index.lhs);
                break;
            case "tinary":
                Tinary tinary = cast(Tinary)expressionNode;
                analyse(tinary.lhs);
                analyse(tinary.ifTrue);
                analyse(tinary.ifFalse);
                break;
            case "bracketed":
                analyse((cast(Bracketed)expressionNode).contained);
                break;
            case "new":
                New new_ = cast(New)expressionNode;
                throw new AnalyserException("new expression not supported");
            case "assign":
                Assign assign = cast(Assign)expressionNode;
                analyse(assign.what);
                analyse(assign.assign);
                break;
            default:
                throw new AnalyserException("unrecognised expression %s",expressionNode);
        }
    }
}

class LexicalScope
{
    LexicalScope parent;
    ParserNode owner;
    bool[string] namespace;
    
    this(){}
    this(LexicalScope parent, ParserNode owner)
    {
        this.parent = parent;
        this.owner = owner;
    }
    
    bool request(string name)
    {
        if ((name in namespace) !is null ||
            (parent !is null ? parent.request(name) : false))
            return true;
        else
            throw new AnalyserException("Unidentified identifier %s", name);
    }
    
    bool defined(string name)
    {
        if ((name in namespace) !is null ||
            (parent !is null ? parent.request(name) : false))
            return true;
        else
            return false;
    }
    
    void resolve(string name)
    {
        namespace[name] = true;
    }
}

class AnalyserException : Exception
{
    this(T...)(string message, T args)
    {
        import std.format;
        super(format(message,args));
    }
}

bool inLoop(LexicalScope scope_)
{
    switch(scope_.owner.type())
    {
        case "for":
        case "foreach":
        case "until":
        case "while":
            return true;
        case "function":
            return false;
        default:
            return scope_.parent is null ? false : inLoop(scope_.parent);
    }
}

bool inFunc(LexicalScope scope_)
{
    switch(scope_.owner.type())
    {
        case "function":
            return true;
        default:
            return scope_.parent is null ? false : inLoop(scope_.parent);
    }
}
