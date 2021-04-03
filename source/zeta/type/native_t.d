/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
 module zeta.type.native_t;

import std.conv;
import std.functional: toDelegate;
import zeta.type.type_t;
import zeta.script.interpreter;
import zeta.utils.error;
import zeta.type;

import zeta.parse.ast;
import zeta.script.context;

class ZtNativeType : ZtType {
    ZtScriptInterpreter interpreter;

    ZtValue make(ZtValue delegate(ZtScriptInterpreter, ZtValue[]) fun) {
        ZtValue result;
        result.type = this;
        result.m_native = fun;
        return result;
    }

    ZtValue make(ZtValue function(ZtScriptInterpreter, ZtValue[]) fun) {
        ZtValue result;
        result.type = this;
        result.m_native = fun.toDelegate();
        return result;
    }

    override void register(ZtScriptInterpreter interpreter) { this.interpreter= interpreter; }

    override @property string name() { return "function"; }
    
    override @property string op_tostring(ZtValue* self) {
        return "native_function:"~self.ptr2.text;
    }

    override ZtValue op_cast(ZtValue* self, ZtType type) {
        import std.conv : to;
        if (type == this) return self.deRefed;
        else return super.op_cast(self, type);
    }

    override ZtValue op_call(ZtValue* self, ZtValue[] args) {
        auto native =  self.m_native; //Work around for properties + delegates not working.
        return native(interpreter, args);
    }
}
