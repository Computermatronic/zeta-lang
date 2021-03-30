module zeta.script.variable;

import std.format;
import std.conv;
import std.array;
import std.functional: toDelegate;
import zeta.parse.ast;
import zeta.script.scope_;
import zeta.script.interpreter;

Null nullValue;

static this() {
    nullValue = new Null();
}

abstract class Variable {
    abstract bool eval();
    abstract bool equals(Variable var);
    abstract Variable refOf();
    abstract string type() const;
    abstract override string toString() const;
    
    Variable add(Variable var) { assert(0, "Not implemented!"); }
    Variable sub(Variable var) { assert(0, "Not implemented!"); }
    Variable mul(Variable var) { assert(0, "Not implemented!"); }
    Variable div(Variable var) { assert(0, "Not implemented!"); }
    Variable mod(Variable var) { assert(0, "Not implemented!"); }
    
    Variable pos() { assert(0, "Not implemented!"); }
    Variable neg() { assert(0, "Not implemented!"); }
    
    void inc() { assert(0, "Not implemented!"); }
    void dec() { assert(0, "Not implemented!"); }
    
    bool greater(Variable var) { assert(0, "Not implemented!"); }
    bool less(Variable var) { assert(0, "Not implemented!"); }
    
    Variable concat(Variable val) { assert(0, "Not implemented!"); }
    Variable index(Variable index) { assert(0, "Not implemented!"); }
    void index(Variable index, Variable assign) { assert(0, "Not implemented!"); }
    
    Variable call(Variable[] args) { assert(0, "Not implemented!"); }

    void iterate(Variable dlg) { assert(0, "Not implemented!"); }
    
    Variable dispatchGet(string name) { assert(0, "Not implemented!"); }
    void dispatchSet(string name, Variable var) { assert(0, "Not implemented!"); }
    
    Variable dispatchCall(string name, Variable[] args) { assert(0, "Not implemented!"); }
}

class Float : Variable {
    real number;
    
    this(){}
    this(real number) {
        this.number = number;
    }
    override bool eval() {
        return number !is real.nan;
    }
    
    override Variable refOf() {
        return new Float(number);
    }
    
    override bool equals(Variable var) {
        if (auto num = cast(Float)var)
            return number==num.number;
        else if (auto num = cast(Integer)var)
            return number==num.number;
        else
            return false;
    }
    
    override string type() const {
        return "float";
    }
    
    override string toString() const {
        return text(number);
    }
    
    override Variable add(Variable var) {
        if (auto num = cast(Float)var)
            return new Float(number+num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number+num.number);
        else
            assert(0, format("Cannot add %s and %s",type,var.type));
    }
    override Variable sub(Variable var) {
        if (auto num = cast(Float)var)
            return new Float(number-num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number-num.number);
        else
            assert(0, format("Cannot subtract %s and %s",type,var.type));
    }
    override Variable mul(Variable var) {
        if (auto num = cast(Float)var)
            return new Float(number*num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number*num.number);
        else
            assert(0, format("Cannot multiply %s and %s",type,var.type));
    }
    override Variable div(Variable var) {
        if (auto num = cast(Float)var)
            return new Float(number/num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number/num.number);
        else
            assert(0, format("Cannot divide %s and %s",type,var.type));
    }
    override Variable mod(Variable var) {
        if (auto num = cast(Float)var)
            return new Float(number%num.number);
        else if (auto num = cast(Integer)var)
            return new Float(number%num.number);
        else
            assert(0, format("Cannot modulo %s and %s",type,var.type));
    }
    
    override Variable pos() {
        return new Float(number > 0 ? number : -number);
    }
    
    override Variable neg() {
        return new Float(-number);
    }
    
    override void inc() {
        number++;
    }
    override void dec() {
        number--;
    }
    
    override bool greater(Variable var) {
        if (auto num = cast(Float)var)
            return number>num.number;
        else if (auto num = cast(Integer)var)
            return number>num.number;
        else
            return false;
    }
    override bool less(Variable var) {
        if (auto num = cast(Float)var)
            return number<num.number;
        else if (auto num = cast(Integer)var)
            return number<num.number;
        else
            return false;
    }
    
    override Variable dispatchGet(string name) {
        switch(name) {
            case "nan":
                return new Float(real.nan);
            default:
                assert(0, format("No such field %s for %s",name,type));
        }
    }
    override void dispatchSet(string name, Variable var) {
        assert(0, format("Cannot set field %s for %s",name,type));
    }
    
    override Variable dispatchCall(string name, Variable[] args) {
        assert(0, format("Cannot call field %s for %s",name,type));
    }
}

class Integer : Variable {
    size_t number;
    
    this(){}
    this(size_t number) {
        this.number = number;
    }
    override bool eval() {
        return number != 0;
    }
    
    override Variable refOf() {
        return new Integer(number);
    }
    
    override bool equals(Variable var) {
        if (auto num = cast(Float)var)
            return number==num.number;
        else if (auto num = cast(Integer)var)
            return number==num.number;
        else
            return false;
    }
    
    override string type() const {
        return "integer";
    }
    
    override string toString() const {
        return text(number);
    }
    
    override Variable add(Variable var) {
        if (auto num = cast(Integer)var)
            return new Integer(number+num.number);
        else if (auto num = cast(Float)var)
            return new Float(number+num.number);
        else
            assert(0, format("Cannot add %s and %s",type,var.type));
    }
    override Variable sub(Variable var) {
        if (auto num = cast(Integer)var)
            return new Integer(number-num.number);
        else if (auto num = cast(Float)var)
            return new Float(number-num.number);
        else
            assert(0, format("Cannot subtract %s and %s",type,var.type));
    }
    override Variable mul(Variable var) {
        if (auto num = cast(Integer)var)
            return new Integer(number*num.number);
        else if (auto num = cast(Float)var)
            return new Float(number*num.number);
        else
            assert(0, format("Cannot multiply %s and %s",type,var.type));
    }
    override Variable div(Variable var) {
        if (auto num = cast(Integer)var)
            return new Float(number/num.number);
        else if (auto num = cast(Float)var)
            return new Float(number/num.number);
        else
            assert(0, format("Cannot divide %s and %s",type,var.type));
    }
    override Variable mod(Variable var) {
        if (auto num = cast(Integer)var)
            return new Integer(number%num.number);
        else if (auto num = cast(Float)var)
            return new Float(number%num.number);
        else
            assert(0, format("Cannot modulo %s and %s",type,var.type));
    }
    
    override Variable pos() {
        return new Integer(number > 0 ? number : -number);
    }
    
    override Variable neg() {
        return new Integer(-number);
    }
    
    override void inc() {
        number++;
    }
    override void dec() {
        number--;
    }
    
    override bool greater(Variable var) {
        if (auto num = cast(Integer)var)
            return number>num.number;
        else if (auto num = cast(Float)var)
            return number>num.number;
        else
            return false;
    }
    override bool less(Variable var) {
        if (auto num = cast(Integer)var)
            return number<num.number;
        else if (auto num = cast(Float)var)
            return number<num.number;
        else
            return false;
    }
}

class String : Variable {
    
    char[] text;
    
    this(){}
    this(string text) {
        this.text = cast(char[])text;
    }
    this(char[] text) {
        this.text = text;
    }
    
    override bool equals(Variable var) {
        if (auto str = cast(String)var)
            return text==str.text;
        else
            return false;
    }
    
    override Variable refOf() {
        return new String(text);
    }
    
    override bool eval() {
        return text != "";
    }
    override string type() const {
        return "string";
    }

    override string toString() const {
        return cast(string)this.text;
    }
        
    override Variable index(Variable index) {
        if (auto iIndex = cast(Integer)index)
            return new String([text[iIndex.number]]);
        else
            assert(0, format("Index type must be Integer, not %s", index.type));
    }
    override void index(Variable index, Variable assign) {
        
        Integer iIndex = cast(Integer)index;
        String aAssign = cast(String)assign;
        if (iIndex !is null)
            assert(0, format("Index type must be Integer, not %s", index.type));
        else if (aAssign !is null)
            assert(0, format("Index type must be Integer, not %s", index.type));
        else if (aAssign.text == "")
            text.remove(iIndex.number);
        else if (aAssign.text.length == 1)
            text[iIndex.number] = aAssign.text[0];
        else {
            text[iIndex.number] = aAssign.text[0];
            text.insertInPlace(iIndex.number,aAssign.text[1..$]);
        }
    }
    
    override void iterate(Variable dlg) {
        String str = new String();
        Integer num = new Integer();
        foreach(i,chr;text) {
            str.text = [chr];
            num.number = i;
            dlg.call([cast(Variable)str,cast(Variable)num]);
        }
    }
    override Variable dispatchGet(string name) {
        switch(name) {
            case "length":
                return new Integer(text.length);
            default:
                assert(0, format("No such field %s for %s",name,type));
        }
    }
    override void dispatchSet(string name, Variable var) {
        assert(0, format("Cannot set field %s for %s",name,type));
    }
    
    override Variable dispatchCall(string name, Variable[] args) {
        assert(0, format("Cannot call field %s for %s",name,type));
    }
}

class Bool : Variable {
    bool boolean;
    
    this(){}
    this(bool boolean) {
        this.boolean = boolean;
    }
    
    override bool eval() {
        return boolean;
    }
    override Variable refOf() {
        return new Bool(boolean);
    }
    override bool equals(Variable var) {
        if (auto boo = cast(Bool)var)
            return boolean==boo.boolean;
        else
            return false;
    }
    
    override string toString() const {
        return boolean ? "true" : "false";
    }
    
    override string type() const {
        return "boolean";
    }
}

class Array : Variable {
    Variable[] array;
    
    this(){}

    this(Variable[] array) {
        this.array = array;
    }
    
    override bool eval() {
        return array.length != 0;
    }
    
    override bool equals(Variable var) {
        if (auto arr = cast(Array)var)
            return array==arr.array;
        else
            return false;
    }
    override Variable refOf() {
        return this;
    }
    
    override string type() const {
        return "array";
    }
    
    override string toString() const {
        string str = "[";
        foreach(i,element;array)
            str ~= element.toString ~ (array.length == i+1 ? "]" :", ");
        return format("%s: %s",type,str);
    }
    
    override Variable index(Variable index) {
        if (auto iIndex = cast(Integer)index)
            return array[iIndex.number];
        else
            assert(0, format("Index type must be Integer, not %s", index.type));
    }
    override void index(Variable index, Variable assign) {
        if (auto iIndex = cast(Integer)index)
            array[iIndex.number] = assign;
        else
            assert(0, format("Index type must be Integer, not %s", index.type));
    }
    
    override void iterate(Variable dlg) {
        auto num = new Integer();
        foreach(i,element;array) {
            num.number = i;
            dlg.call([element,num]);
        }
    }
    
    override Variable dispatchGet(string name) {
        switch(name) {
            case "length":
                return new Integer(array.length);
            default:
                assert(0, format("No such field %s for %s",name,type));
        }
    }
    override void dispatchSet(string name, Variable var) {
        switch(name) {
            case "length":
                if (auto vVar = cast(Integer)var)
                    array.length = vVar.number;
                else
                    assert(0, format("Index type must be whole number"));
                break;
            default:
                assert(0, format("No such field %s for %s",name,type));
        }
    }

    override Variable dispatchCall(string name, Variable[] args) {
        assert(0, format("Cannot call field %s for %s",name,type));
    }
}

void remove(T)(ref T[] array, size_t index) {
    size_t j;
    for(size_t i;i<array.length;i++) {
        array[j] = array[i];
        j+= i==index ? 2 : 1;
    }
}

class BuiltinDelegate : Variable {
    Variable delegate(Variable[]) dlg;
    string name;
    this(Variable delegate(Variable[]) dlg, string name) {
        this.name = name;
        this.dlg = dlg;
    }
    
    this(Variable function(Variable[]) dlg, string name) {
        this.name = name;
        this.dlg = toDelegate(dlg);
    }
    
    override bool eval() {
        return true;
    }
    
    override Variable refOf() {
        return this;
    }
    
    override bool equals(Variable var) {
        return this == var;
    }
    override string type() const {
        return "function";
    }
    
    override string toString() const {
        return format("function:%s", name);
    }
    
    override Variable call(Variable[] args) {
        return dlg(args);
    }
}

class Delegate : Variable {
    ZtScope parent;
    ZtAstFunction node;
    ZtInterpreter interpreter;
    
    this(ZtAstFunction node, ZtScope parent, ZtInterpreter interpreter) {
        this.node = node;
        this.parent = parent;
        this.interpreter = interpreter;
    }
    
    override bool eval() {
        return true;
    }
    
    override Variable refOf() {
        return this;
    }
    
    override bool equals(Variable var) {
        return this == var;
    }
    override string type() const {
        return "function";
    }
    
    override string toString() const {
        return format("function:%s", node.name);
    }
    
    override Variable call(Variable[] arguments) {
        auto oldReturnValue = interpreter.returnValue;
        interpreter.returnValue = nullValue;
        auto self = new ZtScope(parent);
        foreach(i, paramater; node.paramaters) {
            if (node.isVariadic && i+1 == node.paramaters.length) {
                self.define(paramater.name, new Array(arguments[i..$]));
                break;
            } if(arguments.length > i) self.define(paramater.name, arguments[i]);
            else if (paramater.initializer !is null) self.define(paramater.name, interpreter.evaluate(paramater.initializer));
            else assert(0, format("Incorrect number of paramaters in "~"call function %s", node.name));
        }
        interpreter.stack.insertFront(self);
        interpreter.execute(node.members);
        interpreter.stack.removeFront();
        auto result = interpreter.returnValue;
        interpreter.returnValue = oldReturnValue;
        return result;
    }
}

class Null : Variable {
    
    this(){}
    
    override bool eval() {
        return false;
    }
    override Variable refOf() {
        return this;
    }
    override bool equals(Variable var) {
        return var == this;
    }
    
    override string toString() const {
        return "null";
    }
    
    override string type() const {
        return "Null";
    }
}
