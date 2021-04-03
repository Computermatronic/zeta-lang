/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
 module zeta.type.function_t;

import std.conv;
import zeta.type.type_t;
import zeta.script.interpreter;
import zeta.utils.error;
import zeta.type;

import zeta.parse.ast;
import zeta.script.context;

class ZtFunctionType : ZtType {
    ZtScriptInterpreter interpreter;

    ZtValue make(ZtAstFunction func, ZtLexicalContext ctx) {
        ZtValue result;
        result.type = this;
        result.ptr1 = cast(void*)ctx;
        result.ptr2 = cast(void*)func;
        return result;
    }

    override void register(ZtScriptInterpreter interpreter) { this.interpreter= interpreter; }

    override @property string name() { return "function"; }
    
    override @property string op_tostring(ZtValue* self) {
        return "function:"~self.ptr2.text;
    }

    override ZtValue op_cast(ZtValue* self, ZtType type) {
        import std.conv : to;
        if (type == this) return *self;
        else return super.op_cast(self, type);
    }

    override ZtValue op_call(ZtValue* self, ZtValue[] args) {
        auto ctx = cast(ZtLexicalContext)self.ptr1;
        auto func = cast(ZtAstFunction)self.ptr2;
        interpreter.stack.insertFront(ctx);
        auto result = interpreter.evaluate(func, ctx, args);
        interpreter.stack.removeFront();
        return result;
    }
}
