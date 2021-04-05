/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.typesystem.null_t;

import zeta.typesystem.type;
import zeta.script.interpreter;
import zeta.utils.error;
import zeta.script.exception;
import zeta.typesystem;

class ZtNullType : ZtType {
    ZtScriptInterpreter interpreter;
    ushort typeID;

    ZtValue nullValue;

    ZtValue make() {
        ZtValue result;
        result.type = this;
        return result;
    }

    override void register(ZtScriptInterpreter interpreter) {
        this.interpreter = interpreter;
        nullValue = make();
    }

    override @property string name() {
        return "null";
    }

    override @property string op_tostring(ZtValue* self) {
        return "null";
    }

    override bool op_eval(ZtValue* self) {
        return false;
    }

    override ZtValue op_cast(ZtValue* self, ZtType type) {
        import std.conv : to;

        if (type == this)
            return self.deRefed;
        else if (type == interpreter.stringType)
            return interpreter.stringType.make("");
        else if (type == interpreter.arrayType)
            return interpreter.arrayType.make([]);
        else
            return super.op_cast(self, type);
    }

    override bool op_equal(ZtValue* self, ZtValue rhs) {
        return self.type == rhs.type || (rhs.type == interpreter.stringType
                && rhs.m_string.length == 0)
            || (rhs.type == interpreter.arrayType && rhs.m_array.length == 0);
    }
}
