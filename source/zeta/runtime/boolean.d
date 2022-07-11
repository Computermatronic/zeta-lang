/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2022 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.runtime.boolean;

import zeta.utils;
import zeta.script;
import zeta.runtime;

class ZtBooleanType : ZtType {
    ZtScriptInterpreter interpreter;

    ZtValue trueValue, falseValue;

    ZtValue make(bool value) {
        ZtValue result;
        result.type = this;
        result.m_bool = value;
        return result;
    }

    override void register(ZtScriptInterpreter interpreter) {
        this.interpreter = interpreter;

        trueValue = make(true);
        falseValue = make(false);
    }

    override @property string name() {
        return "boolean";
    }

    override @property string op_tostring(ZtValue* self) {
        return self.m_bool ? "true" : "false";
    }

    override bool op_eval(ZtValue* self) {
        return self.m_bool;
    }

    override ZtValue op_cast(ZtValue* self, ZtType type) {
        if (type == this)
            return self.deRefed;
        else if (type == interpreter.stringType)
            return interpreter.stringType.make(self.m_bool ? "true" : "false");
        else if (type == interpreter.integerType)
            return interpreter.integerType.make(self.m_bool ? 1 : 0);
        else if (type == interpreter.floatType)
            return interpreter.floatType.make(self.m_bool ? 1.0 : 0.0);
        else
            return super.op_cast(self, type);
    }

    override bool op_equal(ZtValue* self, ZtValue rhs) {
        return self.m_bool == rhs.op_eval();
    }
}
