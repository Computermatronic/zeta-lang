/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.array_t;

import std.algorithm;
import std.array;
import zeta.type.type_t;
import zeta.script.interpreter;
import zeta.utils.error;
import zeta.script.exception;
import zeta.type;

class ZtArrayType : ZtType {
    ZtScriptInterpreter interpreter;

    ZtValue make(ZtValue[] value) {
        ZtValue result;
        result.type = this;
        result.m_array = value;
        return result;
    }

    override void register(ZtScriptInterpreter interpreter) { this.interpreter = interpreter; }

    override @property string name() { return "array"; }

    override @property string op_tostring(ZtValue* self) {
        return "[" ~ self.m_array.map!((e) => e.op_tostring).join(",") ~ "]";
    }

    override bool op_eval(ZtValue* self) { return self.m_array.length > 0; }

    override ZtValue op_cast(ZtValue* self, ZtType type) {
        import std.conv : to;
        if (type == this) return self.deRefed;
        else if (type == interpreter.nullType) return make([]);
        else return super.op_cast(self, type);
    }

    override bool op_equal(ZtValue* self, ZtValue rhs) {
        return (rhs.type == interpreter.nullType && self.m_array.length == 0) ||
            (rhs.type == this && self.m_array == rhs.m_array);
    }

    override ZtValue op_index(ZtValue* self, ZtValue[] args) {
        if (args.length != 1 || args[0].type != interpreter.integerType) return super.op_index(self, args);
        auto index = args[0].m_int;
        if (index < 0 || index > self.m_array.length) throw new RuntimeException("Out of bounds argument for array index");
        return makeRef(&(self.m_array)[index]);
    }

    override ZtValue op_dispatch(ZtValue* self, string id) {
        switch(id) {
            case "length": return interpreter.integerType.make(cast(int)self.m_array.length);
            default: return super.op_dispatch(self, id);
        }
    }

    override ZtValue op_concat(ZtValue* self, ZtValue rhs) {
        return make(self.m_array ~ rhs.type.op_cast(&rhs, this).m_array);
    }

    override void op_concatAssign(ZtValue* self, ZtValue rhs) {
        self.m_array ~= rhs.type.op_cast(&rhs, this).m_array;
    }
}
