module zeta.interpreter;

import zeta.parser;
import zeta.lexer;
import zeta.var;
import zeta.utils;
import zeta.natives;
import std.functional;

class Interpreter
{
    DList!ParserNode parseTree;
    Scope context;
    this()
    {
        initialize();
    }
    this(string source)
    {
        foreach(node;parse(new TokenStream(source)))
            if (node.type == "function")
                parseTree.insertFront(node);
            else
                parseTree.insertBack(node);
        initialize();
    }
    void initialize()
    {
        context = new Scope();
        context.define("toFloat",new BuiltinDelegate(&toFloat,"toFloat"));
        context.define("toInteger",new BuiltinDelegate(&toInteger,"toInteger"));
        context.define("toBool",new BuiltinDelegate(&toBool,"toBool"));
        context.define("toString",new BuiltinDelegate(&zeta.natives.toString,"toString"));
    }
    void execute()
    {
        foreach(parserNode; parseTree)
            execute(parserNode);
    }
    ExitMethod execute(ParserNode parserNode)
    {
        final switch(parserNode.type())
        {
            case "expression":
                ExpressionNode exp = (cast(Expression)parserNode).exp;
                execute(exp);
                break;
            case "pragma":
                Pragma pragma_ = cast(Pragma)parserNode;
                break;
            case "if":
                If if_ = cast(If)parserNode;
                context = new Scope(context);
                if (execute(if_.cond.exp).eval())
                {
                    auto exitMethod = execute(if_.then);
                    context = context.parent;
                    return exitMethod;
                }
                else if (if_.else_ !is null)
                {
                    context = context.parent;
                    context = new Scope(context);
                    auto exitMethod = execute(if_.else_);
                    context = context.parent;
                    return exitMethod;
                }
                break;
            case "for":
                For for_ = cast(For)parserNode;
                break;
            case "foreach":
                Foreach foreach_ = cast(Foreach)parserNode;
                break;
            case "until":
                Until until = cast(Until)parserNode;
                context = new Scope(context);
                do
                {
                    auto exitMethod = execute(until.loop);
                    if (exitMethod == ExitMethod.Break)
                        break;
                    else if (exitMethod == ExitMethod.Jump)
                        continue;
                    else if (exitMethod == ExitMethod.Return)
                    {
                        context = context.parent;
                        return exitMethod;
                    }
                }
                while(execute(until.cond.exp).eval());
                context = context.parent;
                break;
            case "while":
                While while_ = cast(While)parserNode;
                context = new Scope(context);
                while(execute(while_.cond.exp).eval())
                {
                    auto exitMethod = execute(while_.loop);
                    if (exitMethod == ExitMethod.Break)
                        break;
                    else if (exitMethod == ExitMethod.Jump)
                        continue;
                    else if (exitMethod == ExitMethod.Return)
                    {
                        context = context.parent;
                        return exitMethod;
                    }
                }
                context = context.parent;
                break;
            case "def":
                Def def = cast(Def)parserNode;
                context.define(def.name,execute(def.initializer.exp));
                break;
            case "class":
                Class class_ = cast(Class)parserNode;
                break;
            case "interface":
                Interface_ interface_ = cast(Interface_)parserNode;
                break;
            case "function":
                Function func = cast(Function)parserNode;
                context.define(func.name,new Delegate(func,context,
                    this));
                break;
            case "return":
                Return return_ = cast(Return)parserNode;
                if (context.get(".__return") !is null)
                    context.set(".__return",execute(return_.return_.exp));
                return ExitMethod.Return;
            case "break":
                return ExitMethod.Break;
            case "jump":
                return ExitMethod.Jump;
            case "import":
                Import import_ = cast(Import)parserNode;
                break;
            case "block":
                Block block = cast(Block)parserNode;
                foreach(nParserNode;block.body_)
                {
                    auto exitMethod = execute(nParserNode);
                    if (exitMethod != ExitMethod.None)
                        return exitMethod;
                }
                break;
        }
        return ExitMethod.None;
    }
    Var execute(ExpressionNode expressionNode)
    {
        import std.string: indexOf;
        final switch(expressionNode.type())
        {
            case "number":
                NumberLit numberLit = cast(NumberLit)expressionNode;
                if (numberLit.number.indexOf(".") != -1)
                    return new Float(to!real(numberLit.number));
                else
                    return new Integer(to!size_t(numberLit.number));
            case "string":
                StringLit stringLit = cast(StringLit)expressionNode;
                return new String(stringLit.string_);
            case "array":
                ArrayLit arrayLit = cast(ArrayLit)expressionNode;
                auto array = new Array();
                foreach(element;arrayLit.elements)
                    array.array ~= execute(element);
                return array;
            case "identifier":
                Identifier identifier = cast(Identifier)expressionNode;
                switch(identifier.id)
                {
                    case "true":
                        return new Bool(true);
                    case "false":
                        return new Bool(false);
                    case "null":
                        return nullValue;
                    default:
                        return context.get(identifier.id);
                }
            case "call":
                FunctionCall functionCall = cast(FunctionCall)expressionNode;
                auto operand = execute(functionCall.from);
                if (auto func = cast(Callable)operand)
                {
                    Var[] args;
                    foreach(arg;functionCall.args)
                        args~=execute(arg);
                    return func.call(args);
                }
                else
                    throw new RuntimeException("Cannot call %s",operand.type);
            case "binaryop":
                BinaryOp binaryOp = cast(BinaryOp)expressionNode;
                final switch(binaryOp.op)
                {
                    case "==":
                        return new Bool(execute(binaryOp.lhs).equals(execute(binaryOp.rhs)));
                    case "!=":
                        return new Bool(!execute(binaryOp.lhs).equals(execute(binaryOp.rhs)));
                    case "|":
                        return new Bool(execute(binaryOp.lhs).eval() | (execute(binaryOp.rhs).eval()));
                    case "&":
                        return new Bool(execute(binaryOp.lhs).eval() & (execute(binaryOp.rhs).eval()));
                    case "+":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                            return numeric.add(execute(binaryOp.rhs));
                        else
                            throw new RuntimeException("Cannot add %s and %s",
                                operand.type,execute(binaryOp.rhs).type);
                    case "-":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                            return numeric.sub(execute(binaryOp.rhs));
                        else
                            throw new RuntimeException("Cannot subtract %s and %s",
                                operand.type,execute(binaryOp.rhs).type);
                    case "*":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                            return numeric.mul(execute(binaryOp.rhs));
                        else
                            throw new RuntimeException("Cannot multiply %s and %s",
                                operand.type,execute(binaryOp.rhs).type);
                    case "/":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                            return numeric.div(execute(binaryOp.rhs));
                        else
                            throw new RuntimeException("Cannot divide %s and %s",
                                operand.type,execute(binaryOp.rhs).type);
                    case "%":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                            return numeric.mod(execute(binaryOp.rhs));
                        else
                            throw new RuntimeException("Cannot modulo %s and %s",
                                operand.type,execute(binaryOp.rhs).type);
                    case ">":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                            return new Bool(numeric.greater(execute(binaryOp.rhs)));
                        else
                            return new Bool(false);
                    case "<":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                            return new Bool(numeric.greater(execute(binaryOp.rhs)));
                        else
                            return new Bool(false);
                    case ">=":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                        {
                            auto operand2 = execute(binaryOp.rhs);
                            return new Bool(numeric.greater(operand2)
                                | operand.equals(operand2));
                        }
                        else
                            return new Bool(operand.equals(execute(binaryOp.rhs)));
                    case "<=":
                        auto operand = execute(binaryOp.lhs);
                        if (auto numeric = cast(Numeric)operand)
                        {
                            auto operand2 = execute(binaryOp.rhs);
                            return new Bool(numeric.less(operand2)
                                | operand.equals(operand2));
                        }
                        else
                            return new Bool(operand.equals(execute(binaryOp.rhs)));
                }
            case "unary":
                Unary unary = cast(Unary)expressionNode;
                auto operand = execute(unary.rhs);
                if (unary.lhs == "!")
                    return new Bool(!operand.eval());
                else if(auto numeric = cast(Numeric)operand)
                    final switch(unary.lhs)
                    {
                        case "+":
                            return numeric.pos();
                        case "-":
                            return numeric.neg();
                        case "++":
                            numeric.inc();
                            return operand;
                        case "--":
                            numeric.dec();
                            return operand;
                    }
                else
                    throw new RuntimeException("cannot peform unary %s on %s",
                        unary.lhs, operand.type);
            case "unarymod":
                UnaryMod unaryMod = cast(UnaryMod)expressionNode;
                auto operand = execute(unaryMod.lhs);
                if (auto numeric = cast(Numeric)operand)
                    final switch(unaryMod.rhs)
                    {
                        case "++":
                            auto ret = operand.refOf();
                            numeric.inc();
                            return ret;
                        case "--":
                            auto ret = operand.refOf();
                            numeric.dec();
                            return ret;
                    }
                else
                    throw new RuntimeException("cannot peform unary %s on %s",
                        unaryMod.rhs, operand.type);
            case "dispatch":
                Dispatch dispatch = cast(Dispatch)expressionNode;
                auto operand = execute(dispatch.lhs);
                if (auto objective = cast(Objective)operand)
                    return objective.dispatchGet(dispatch.index);
                else
                    throw new RuntimeException("cannot dispatch %s on %s",
                        dispatch.index,operand.type);
            case "index":
                Index index = cast(Index)expressionNode;
                auto operand = execute(index.lhs);
                if (auto indexable = cast(Indexable)operand)
                    return indexable.index(execute(index.index));
                else
                    throw new RuntimeException("cannot index %s",
                        operand.type);
            case "tinary":
                Tinary tinary = cast(Tinary)expressionNode;
                if (execute(tinary.lhs))
                    return execute(tinary.ifTrue);
                else
                    return execute(tinary.ifFalse);
            case "bracketed":
                Bracketed bracketed = cast(Bracketed)expressionNode;
                return execute(bracketed.contained);
            case "new":
                New new_ = cast(New)expressionNode;
                return nullValue;
            case "assign":
                Assign assign = cast(Assign)expressionNode;
                auto assignee = execute(assign.assign);
                final switch(assign.what.type)
                {
                    case "identifier":
                        if (!isLvalue((cast(Identifier)assign.what).id))
                            throw new RuntimeException("%s is not an lvalue",
                               (cast(Identifier)assign.what).id);
                        else
                            context.set((cast(Identifier)assign.what).id,assignee);
                        break;
                    case "index":
                        auto operand = execute((cast(Index)assign.what).lhs);
                        if (auto indexable = cast(Indexable)operand)
                            indexable.index(execute((cast(Index)assign.what).index),
                                assignee);
                        else
                            throw new RuntimeException("cannot index %s",
                                operand.type);
                        break;
                    case "dispatch":
                        auto operand = execute((cast(Dispatch)assign.what).lhs);
                        if (auto objective = cast(Objective)operand)
                            objective.dispatchSet((cast(Dispatch)assign.what).index,
                                assignee);
                        else
                            throw new RuntimeException("cannot dispatch %s on %s",
                                (cast(Dispatch)assign.what).index,operand.type);
                        break;
                }
                return assignee;
        }
    }
}
enum ExitMethod
{
    None,
    Jump,
    Break,
    Return
}
class Scope
{
    ParserNode owner;
    Scope parent;
    Var[string] namespace;
    
    this(){}
    this(Scope parent)
    {
        this.parent = parent;
    }
    
    Var get(string name)
    {
        if ((name in namespace) is null)
            return parent is null ? nullValue : parent.get(name);
        else
            return namespace[name];
    }
    
    void define(string name, Var assign)
    {
        namespace[name] = assign;
    }
    void set(string name, Var assign)
    {
        if ((name in namespace) !is null)
            namespace[name] = assign;
        else if (parent !is null)
            parent.set(name,assign);
    }
}
class RuntimeException : Exception
{
    this(T...)(string msg, T args)
    {
        import std.format;
        super(format(msg,args));
    }
}
