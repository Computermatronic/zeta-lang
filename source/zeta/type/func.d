/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.func;

import std.format;
import zeta.type.value;
import zeta.script.context;
import zeta.script.interpreter;
import zeta.parse.ast;
import zeta.type.nullval;
import zeta.type.array;

class ZtFunction : ZtValue {
    ZtLexicalContext parent;
    ZtAstFunction node;
    ZtInterpreter interpreter;
    
    this(ZtAstFunction node, ZtLexicalContext parent, ZtInterpreter interpreter) {
        this.node = node;
        this.parent = parent;
        this.interpreter = interpreter;
    }
    
    override bool toBool() {
        return true;
    }
    
    override ZtValue clone() {
        return this;
    }
    
    override bool equals(ZtValue var) {
        return this == var;
    }
    override string type() const {
        return "function";
    }
    
    override string toString() const {
        return format("function:%s", node.name);
    }
    
    override ZtValue call(ZtValue[] arguments) {
        auto oldReturnValue = interpreter.returnValue;
        interpreter.returnValue = nullValue;
        auto self = new ZtLexicalContext(parent);
        foreach(i, paramater; node.paramaters) {
            if (node.isVariadic && i+1 == node.paramaters.length) {
                self.define(paramater.name, new ZtArray(arguments[i..$]));
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