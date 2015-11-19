module zeta.compiler_old;

import zeta.parser;
import zeta.lexer;
import zmachine.codes;

import std.typecons;


class Compiler
{   
    ParserNode[] parser;
    uint[string] symtbl;
    void delegate()[] jMap;
    void delegate()[] bMap;
    ubyte[] binary;
    
    this(string source)
    {
        parser = parse(new TokenStream(source));
    }
    
    void compile(ParserNode node)
    {
        final switch(node.type())
        {
            case "expression":
                compile((cast(Expression)node).exp);
                break;
            case "if":
                If if_ = cast(If)node;
                compile(if_.cond.exp);
                uint then;
                auto later = binary.pushLater(opcode_t.JMC,Register.GR1 | Mode.REG
                    ,then,binary.length);
                then = binary.length;
                compile(if_.then);
                auto later1 = binary.pushLater(opcode_t.JMP,binary.length);
                if (if_.else_ !is null)
                    compile(if_.else_);
                later();later1();
                break;
            case "for":
                For for_ = cast(For)node;
                auto old_jMap = jMap, old_bMap = bMap;
                jMap = new void delegate()[](0);
                bMap = new void delegate()[](0);
                compile(for_.var);
                uint next, start = binary.length;
                compile(for_.cond);
                auto later = binary.pushLater(opcode_t.JMC,Mode.REG | Register.GR1
                    ,next,binary.length);
                compile(for_.step);
                next = binary.length;
                compile(for_.loop);
                binary.push(opcode_t.JMP,start);
                auto old_binary = binary;
                binary = binary[0..start];
                foreach(jmp;jMap)
                    jmp();
                delete jMap;
                jMap = old_jMap;
                binary = old_binary;
                foreach(brk;bMap)
                    brk();
                delete bMap;
                bMap = old_bMap;
                later();
                break;
            case "foreach":
                Foreach foreach_ = cast(Foreach)node;
                break;
            case "while":
                While while_ = cast(While)node;
                auto old_jMap = jMap, old_bMap = bMap;
                jMap = new void delegate()[](0);
                bMap = new void delegate()[](0);
                uint next, start = binary.length;
                compile(while_.cond);
                auto later = binary.pushLater(opcode_t.JMC,next,binary.length);
                next = binary.length;
                compile(while_.loop);
                binary.push(opcode_t.JMP,start);
                auto old_binary = binary;
                binary = binary[0..start];
                foreach(jmp;jMap)
                    jmp();
                binary = old_binary;
                delete jMap;
                jMap = old_jMap;
                foreach(brk;bMap)
                    brk();
                delete bMap;
                bMap = old_bMap;
                later();
                break;
            case "def":
                Def def = cast(Def)node;
                if (def.initializer !is null)
                {
                    compile(def.initializer.exp);
                    binary.push(opcode_t.MOV,Mode.REG | Register.GR1,0,
                        Mode.MEM,symtbl[def.name]);
                }   
                break;
            case "class":
                Class class_ = cast(Class)node;
                break;
            case "interface":
                Interface_ interface_ = cast(Interface_)node;
                break;
            case "function":
                Function function_ = cast(Function)node;
                symtbl[function_.name] = binary.length;
                compile(function_.func);
                binary.push(opcode_t.RET, Mode.LIT,0);
                break;
            case "return":
                compile((cast(Return)node).return_.exp);
                binary.push(opcode_t.RET,Mode.REG | Register.GR1,0);
                break;
            case "break":
                bMap ~= binary.pushLater(opcode_t.JMP,binary.length);
                break;
            case "jump":
                jMap ~= binary.pushLater(opcode_t.JMP,binary.length);
                break;
            case "block":
                Block block = cast(Block)node;
                foreach(nnode;block.body_)
                    compile(nnode);
                break;
        }
    }
    
    void compile(ExpressionNode node){}/*
    {
        switch(node.type())
        {
            case "number":
                NumberLit num = cast(NumberLit)node;
                return new Number().setOwner(this).set(num.number);
            case "string":
                StringLit str = cast(StringLit)node;
                return new String().setOwner(this).set(str.string_);
            case "identifier":
                Identifier id = cast(Identifier)node;
                if (id.id == "true")
                    return true_;
                else if (id.id == "false")
                    return false_;
                else if (id.id == "null")
                    return null_;
                return globals.index(new String().setOwner(this).set(id.id));
            case "call":
                FunctionCall call = cast(FunctionCall)node;
                Var[] args;
                foreach(arg;call.args)
                    args ~= execute(arg);
                return execute(call.from).call(args);
            case "arithmitic":
                Arithmitic op = cast(Arithmitic)node;
                switch(op.op)
                {
                    case "+":
                        return convert(execute(op.lhs),zero).add(execute(op.rhs));
                    case "-":
                        return convert(execute(op.lhs),zero).sub(execute(op.rhs));
                    case "*":
                        return convert(execute(op.lhs),zero).mul(execute(op.rhs));
                    case "/":
                        return convert(execute(op.lhs),zero).div(execute(op.rhs));
                    default:
                        break;
                }
                break;
            case "logic":
                Logic op = cast(Logic)node;
                switch(op.op)
                {
                    case "==":
                        return execute(op.lhs).equals(execute(op.rhs)) ? true_ : false_;
                    case ">":
                        return execute(op.lhs).greater(execute(op.rhs)) ? true_ : false_;
                    case "<":
                        return execute(op.lhs).less(execute(op.rhs)) ? true_ : false_;
                    case ">=":
                        return execute(op.lhs).equals(execute(op.rhs))
                               || execute(op.lhs).greater(execute(op.rhs)) ? true_ : false_;

                    case "<=":
                        return execute(op.lhs).equals(execute(op.rhs))
                               || execute(op.lhs).less(execute(op.rhs)) ? true_ : false_;
                    case "!=":
                        return !execute(op.lhs).equals(execute(op.rhs)) ? true_ : false_;
                    default:
                        return null_;
                }
            case "unary":
                Unary op = cast(Unary)node;
                switch(op.lhs)
                {
                    case "+":
                        return convert(execute(op.rhs),zero).pos();
                    case "-":
                        return convert(execute(op.rhs),zero).neg();
                    case "++":
                        auto ret = convert(execute(op.rhs).cpy(),zero);
                        ret.inc();
                        return ret;
                    case "--":
                        auto ret = convert(execute(op.rhs).cpy(),zero);
                        ret.dec();
                        return ret;
                    default:
                        break;
                }
                break;
            case "unarymod":
                UnaryMod op = cast(UnaryMod)node;
                switch(op.rhs)
                {
                    case "++":
                        Var ret = execute(op.lhs);ret.inc();
                        return ret;
                    case "--":
                        Var ret = execute(op.lhs);ret.dec();
                        return ret;
                    default:
                        break;
                }
                break;
            case "lookup":
                Lookup lookup = cast(Lookup)node;
                if (lookup.assign is null)
                    return execute(lookup.lhs).index(new String().setOwner(this).set(lookup.index.id));
                else
                    execute(lookup.lhs).index(new String().setOwner(this).set(lookup.index.id),execute(lookup.assign));
                break;
            case "index":
                Index index = cast(Index)node;
                if (index.assign is null)
                    return execute(index.lhs).index(execute(index.index));
                else
                    execute(index.lhs).index(execute(index.index),execute(index.assign));
                break;
            case "tinary":
                Tinary tinary = cast(Tinary)node;
                auto cond = execute(tinary.lhs).boolOf();
                if (!cond.isNull() && cond.get())
                    return execute(tinary.ifTrue);
                else
                    return execute(tinary.ifFalse);
            case "bracketed":
                return execute((cast(Bracketed)node).contained);
            case "assign":
                Assign assign = cast(Assign)node;
                Var var = execute(assign.assign);
                globals.index(new String().setOwner(this).set(assign.var.id),var);
                return var;
            default:
                break;   
        }
        return null_;
    }*/
}


void push(T...)(ref ubyte[] block, T args)
{
    import std.traits;
    import zeta.utils;
    foreach(arg;args)
    {
        if (isSigned!(typeof(arg)))
            block ~= toBytes(cast(Unsigned!(typeof(arg)))arg);
        else
            block ~= toBytes(arg);
    }
}

void pushLazy(T...)(ref ubyte[] block, lazy T args)
{
    import std.traits;
    import zeta.utils;
    size_t startPoint = block.length;
    foreach(I;T)
    {
        block.length+=I.sizeof;
    }
    foreach(arg;args)
    {
        if (isSigned!(typeof(arg)))
            block[startPoint..startPoint+arg.sizeof] = toBytes(cast(Unsigned!(typeof(arg)))arg);
        else
            block[startPoint..startPoint+arg.sizeof] = toBytes(arg);
        startPoint+= arg.sizeof;
    }
}

void delegate() pushLater(T...)(ref ubyte[] block, lazy T args)
{
    import std.traits;
    import zeta.utils;
    size_t startPoint = block.length;
    foreach(I;T)
    {
        block.length+=I.sizeof;
    }
    return delegate()
    {
        foreach(arg;args)
        {
            if (isSigned!(typeof(arg)))
                block[startPoint..startPoint+arg.sizeof] = toBytes(cast(Unsigned!(typeof(arg)))arg);
            else
                block[startPoint..startPoint+arg.sizeof] = toBytes(arg);
            startPoint+= arg.sizeof;
        }
    };
}

auto delegateOf(T)(lazy T arg)
{
    return () => arg;
}
