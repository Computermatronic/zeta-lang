/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2022 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.runtime.metatype;

import zeta.utils;
import zeta.interpret;
import zeta.runtime;

class ZtMetaType : ZtType {
    ZtScriptInterpreter interpreter;
    ushort typeID;

    ZtValue make(ZtType type) {
        ZtValue result;
        result.type = this;
        result.m_type = type;
        return result;
    }

    override void register(ZtScriptInterpreter interpreter) {
        this.interpreter = interpreter;
    }

    override @property string name() {
        return "type";
    }

    override @property string op_tostring(ZtValue* self) {
        return "type:" ~ self.m_type.name;
    }

    override bool op_eval(ZtValue* self) {
        return true;
    }

    override ZtValue op_cast(ZtValue* self, ZtType type) {
        import std.conv : to;

        if (type == this)
            return self.deRefed;
        else
            return super.op_cast(self, type);
    }

    override bool op_equal(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return self.m_type == rhs.m_type;
        else
            return false;
    }
}
