module zeta.var;

import std.conv;
import std.typecons;

import zeta.interpreter : RuntimeException;

Null nullValue;

static this()
{
    nullValue = new Null();
}

interface Var
{
    bool eval();
    bool equals(Var var);
    Var refOf();
    string type();
    string desc();
}

interface Numeric
{
    Var add(Var var);
    Var sub(Var var);
    Var mul(Var var);
    Var div(Var var);
    Var mod(Var var);
    
    Var pos();
    Var neg();
    
    void inc();
    void dec();
    
    bool greater(Var var);
    bool less(Var var);
}

interface Indexable
{
    Var index(Var index);
    void index(Var index, Var assign);
}

interface Callable
{
    Var call(Var[] args);
}

interface Iteratable
{
    void iterate(Callable dlg);
}

interface Objective
{
    Var dispatchGet(string name);
    void dispatchSet(string name, Var var);
    
    Var dispatchCall(string name, Var[] args);
}

class Float : Var, Numeric, Objective
{
    import std.math;
    real number;
    
    this(){}
    this(real number)
    {
        this.number = number;
    }
    bool eval()
    {
        return number !is real.nan;
    }
    
    Var refOf()
    {
        return new Float(number);
    }
    
    bool equals(Var var)
    {
        if (auto num = cast(Float)var)
            return number==num.number;
        else if (auto num = cast(Integer)var)
            return number==num.number;
        else
            return false;
    }
    
    string type()
    {
        return "float";
    }
    
    string desc()
    {
        import std.format : format;
        return format("%s: %s",type,number);
    }
    
    Var add(Var var)
    {
        if (auto num = cast(Float)var)
            return new Float(number+num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number+num.number);
        else
            throw new RuntimeException("Cannot add %s and %s",type,var.type);
    }
    Var sub(Var var)
    {
        if (auto num = cast(Float)var)
            return new Float(number-num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number-num.number);
        else
            throw new RuntimeException("Cannot subtract %s and %s",type,var.type);
    }
    Var mul(Var var)
    {
        if (auto num = cast(Float)var)
            return new Float(number*num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number*num.number);
        else
            throw new RuntimeException("Cannot multiply %s and %s",type,var.type);
    }
    Var div(Var var)
    {
        if (auto num = cast(Float)var)
            return new Float(number/num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number/num.number);
        else
            throw new RuntimeException("Cannot divide %s and %s",type,var.type);
    }
    Var mod(Var var)
    {
        if (auto num = cast(Float)var)
            return new Float(number%num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number%num.number);
        else
            throw new RuntimeException("Cannot modulo %s and %s",type,var.type);
    }
    
    Var pos()
    {
        return new Float(number > 0 ? number : -number);
    }
    
    Var neg()
    {
        return new Float(-number);
    }
    
    void inc()
    {
        number++;
    }
    void dec()
    {
        number--;
    }
    
    bool greater(Var var)
    {
        if (auto num = cast(Float)var)
            return number>num.number;
        else if (auto num = cast(Integer)var)
            return number>num.number;
        else
            return false;
    }
    bool less(Var var)
    {
        if (auto num = cast(Float)var)
            return number<num.number;
        else if (auto num = cast(Integer)var)
            return number<num.number;
        else
            return false;
    }
    
    Var dispatchGet(string name)
    {
        switch(name)
        {
            case "nan":
                return new Float(real.nan);
            default:
                throw new RuntimeException("No such field %s for %s",name,type);
        }
    }
    void dispatchSet(string name, Var var)
    {
        throw new RuntimeException("Cannot set field %s for %s",name,type);
    }
    
    Var dispatchCall(string name, Var[] args)
    {
        throw new RuntimeException("Cannot call field %s for %s",name,type);
    }
}

class Integer : Var, Numeric
{
    import std.math;
    import zeta.utils : integer;
    
    integer number;
    
    this(){}
    this(integer number)
    {
        this.number = number;
    }
    bool eval()
    {
        return number != 0;
    }
    
    Var refOf()
    {
        return new Integer(number);
    }
    
    bool equals(Var var)
    {
        if (auto num = cast(Float)var)
            return number==num.number;
        else if (auto num = cast(Integer)var)
            return number==num.number;
        else
            return false;
    }
    
    string type()
    {
        return "integer";
    }
    
    string desc()
    {
        import std.format : format;
        return format("%s: %s",type,number);
    }
    
    Var add(Var var)
    {
        if (auto num = cast(Integer)var)
            return new Integer(number+num.number);
        else if (auto num = cast(Float)var)
            return new Float(number+num.number);
        else
            throw new RuntimeException("Cannot add %s and %s",type,var.type);
    }
    Var sub(Var var)
    {
        if (auto num = cast(Integer)var)
            return new Integer(number-num.number);
        else if (auto num = cast(Float)var)
            return new Float(number-num.number);
        else
            throw new RuntimeException("Cannot subtract %s and %s",type,var.type);
    }
    Var mul(Var var)
    {
        if (auto num = cast(Integer)var)
            return new Integer(number*num.number);
        else if (auto num = cast(Float)var)
            return new Float(number*num.number);
        else
            throw new RuntimeException("Cannot multiply %s and %s",type,var.type);
    }
    Var div(Var var)
    {
        if (auto num = cast(Integer)var)
            return new Float(number/num.number);
        else if (auto num = cast(Float)var)
            return new Float(number/num.number);
        else
            throw new RuntimeException("Cannot divide %s and %s",type,var.type);
    }
    Var mod(Var var)
    {
        if (auto num = cast(Integer)var)
            return new Integer(number%num.number);
        else if (auto num = cast(Float)var)
            return new Float(number%num.number);
        else
            throw new RuntimeException("Cannot modulo %s and %s",type,var.type);
    }
    
    Var pos()
    {
        return new Integer(number > 0 ? number : -number);
    }
    
    Var neg()
    {
        return new Integer(-number);
    }
    
    void inc()
    {
        number++;
    }
    void dec()
    {
        number--;
    }
    
    bool greater(Var var)
    {
        if (auto num = cast(Integer)var)
            return number>num.number;
        else if (auto num = cast(Float)var)
            return number>num.number;
        else
            return false;
    }
    bool less(Var var)
    {
        if (auto num = cast(Integer)var)
            return number<num.number;
        else if (auto num = cast(Float)var)
            return number<num.number;
        else
            return false;
    }
}

class String : Var, Indexable, Iteratable, Objective
{
    import std.array;
    
    char[] text;
    
    this(){}
    this(string text)
    {
        this.text = cast(char[])text;
    }
    this(char[] text)
    {
        this.text = text;
    }
    
    bool equals(Var var)
    {
        if (auto str = cast(String)var)
            return text==str.text;
        else
            return false;
    }
    
    Var refOf()
    {
        return new String(text);
    }
    
    bool eval()
    {
        return text != "";
    }
    string type()
    {
        return "string";
    }

    string desc()
    {
        import std.format : format;
        return format("%s: '%s'",type,text);
    }
        
    Var index(Var index)
    {
        if (auto iIndex = cast(Integer)index)
            return new String([text[iIndex.number]]);
        else
            throw new RuntimeException("Index type must be Integer, not %s",
                index.type);
    }
    void index(Var index, Var assign)
    {
        
        Integer iIndex = cast(Integer)index;
        String aAssign = cast(String)assign;
        if (iIndex !is null)
            throw new RuntimeException("Index type must be Integer, not %s",
                index.type);
        else if (aAssign !is null)
            throw new RuntimeException("Index type must be Integer, not %s",
                index.type);
        else if (aAssign.text == "")
            text.remove(iIndex.number);
        else if (aAssign.text.length == 1)
            text[iIndex.number] = aAssign.text[0];
        else
            text[iIndex.number] = aAssign.text[0];
            text.insertInPlace(iIndex.number,aAssign.text[1..$]);
    }
    
    void iterate(Callable dlg)
    {
        String str = new String();
        Integer num = new Integer();
        foreach(i,chr;text)
        {
            str.text = [chr];
            num.number = i;
            dlg.call([cast(Var)str,cast(Var)num]);
        }
    }
    Var dispatchGet(string name)
    {
        switch(name)
        {
            case "length":
                return new Integer(text.length);
            default:
                throw new RuntimeException("No such field %s for %s",name,type);
        }
    }
    void dispatchSet(string name, Var var)
    {
        throw new RuntimeException("Cannot set field %s for %s",name,type);
    }
    
    Var dispatchCall(string name, Var[] args)
    {
        throw new RuntimeException("Cannot call field %s for %s",name,type);
    }
}

class Bool : Var
{
    bool boolean;
    
    this(){}
    this(bool boolean)
    {
        this.boolean = boolean;
    }
    
    bool eval()
    {
        return boolean;
    }
    Var refOf()
    {
        return new Bool(boolean);
    }
    bool equals(Var var)
    {
        if (auto boo = cast(Bool)var)
            return boolean==boo.boolean;
        else
            return false;
    }
    
    string desc()
    {
        import std.format : format;
        return format("%s: %s",type,boolean);
    }
    
    string type()
    {
        return "boolean";
    }
}

class Array : Var, Indexable, Iteratable, Objective
{
    import std.array;
    import std.algorithm;
    Var[] array;
    
    this(){}
    
    bool eval()
    {
        return array.length != 0;
    }
    
    bool equals(Var var)
    {
        if (auto arr = cast(Array)var)
            return array==arr.array;
        else
            return false;
    }
    Var refOf()
    {
        return this;
    }
    
    string type()
    {
        return "array";
    }
    
    string desc()
    {
        import std.format : format;
        string str = "[";
        foreach(i,element;array)
            str ~= element.desc ~ (array.length-1 == i ? "]" :", ");
        return format("%s: %s",type,str);
    }
    
    Var index(Var index)
    {
        if (auto iIndex = cast(Integer)index)
            return array[iIndex.number];
        else
            throw new RuntimeException("Index type must be Integer, not %s",
                index.type);
    }
    void index(Var index, Var assign)
    {
        if (auto iIndex = cast(Integer)index)
            array[iIndex.number] = assign;
        else
            throw new RuntimeException("Index type must be Integer, not %s",
                index.type);
    }
    
    void iterate(Callable dlg)
    {
        auto num = new Integer();
        foreach(i,element;array)
        {
            num.number = i;
            dlg.call([element,num]);
        }
    }
    
    Var dispatchGet(string name)
    {
        switch(name)
        {
            case "length":
                return new Integer(array.length);
            default:
                throw new RuntimeException("No such field %s for %s",name,type);
        }
    }
    void dispatchSet(string name, Var var)
    {
        switch(name)
        {
            case "length":
                if (auto vVar = cast(Integer)var)
                    array.length = vVar.number;
                else
                    throw new RuntimeException("Index type must be whole number");
                break;
            default:
                throw new RuntimeException("No such field %s for %s",name,type);
        }
    }

    Var dispatchCall(string name, Var[] args)
    {
        throw new RuntimeException("Cannot call field %s for %s",name,type);
    }
}

void remove(T)(ref T[] array, size_t index)
{
    size_t j;
    for(size_t i;i<array.length;i++)
    {
        array[j] = array[i];
        j+= i==index ? 2 : 1;
    }
}

class BuiltinDelegate : Var, Callable
{
    Var delegate(Var[]) dlg;
    string name;
    this(Var delegate(Var[]) dlg, string name)
    {
        this.name = name;
        this.dlg = dlg;
    }
    
    this(Var function(Var[]) dlg, string name)
    {
        import std.functional : toDelegate;
        this.name = name;
        this.dlg = toDelegate(dlg);
    }
    
    bool eval()
    {
        return true;
    }
    
    Var refOf()
    {
        return this;
    }
    
    bool equals(Var var)
    {
        return this == var;
    }
    string type()
    {
        return "function";
    }
    
    string desc()
    {
        import std.format : format;
        return format("%s: %s",type,name);
    }
    
    Var call(Var[] args)
    {
        return dlg(args);
    }
}

class Delegate : Var, Callable
{
    import zeta.parser;
    import zeta.interpreter;
    Scope context;
    Function func;
    Interpreter owner;
    
    this(Function func, Scope parent, Interpreter owner)
    {
        this.func = func;
        this.context = new Scope(parent);
        this.owner = owner;
    }
    
    bool eval()
    {
        return true;
    }
    
    Var refOf()
    {
        return this;
    }
    
    bool equals(Var var)
    {
        return this == var;
    }
    string type()
    {
        return "function";
    }
    
    string desc()
    {
        import std.format : format;
        return format("%s: %s",type,func.name);
    }
    
    Var call(Var[] args)
    {
        context.define(".__return",nullValue);
        foreach(i,arg;func.args)
        {
            if(args.length>i)
                context.define(arg.name,args[i]);
            else if (arg.initializer !is null)
                context.define(arg.name,owner.execute(arg.initializer.exp));
            else
                throw new RuntimeException("Incorrect number of paramaters in "~
                    "call function %s",func.name);
        }
        auto context_old = owner.context;
        owner.context = context;
        owner.execute(func.func);
        auto ret = context.get(".__return");
        owner.context = context_old;
        return ret;
    }
}

class Null : Var
{
    
    this(){}
    
    bool eval()
    {
        return false;
    }
    Var refOf()
    {
        return this;
    }
    bool equals(Var var)
    {
        return var == this;
    }
    
    string desc()
    {
        return "Null";
    }
    
    string type()
    {
        return "Null";
    }
}
