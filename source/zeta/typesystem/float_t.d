/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.typesystem.float_t;

import std.conv;
import zeta.typesystem.type;
import zeta.script.interpreter;
import zeta.utils.error;
import zeta.script.exception;
import zeta.typesystem;

class ZtFloatType : ZtType {
    ZtScriptInterpreter interpreter;

    ZtValue make(float value) {
        ZtValue result;
        result.type = this;
        result.m_float = value;
        return result;
    }

    override void register(ZtScriptInterpreter interpreter) {
        this.interpreter = interpreter;
    }

    override @property string name() {
        return "float";
    }

    override @property string op_tostring(ZtValue* self) {
        return self.m_float.text;
    }

    override bool op_eval(ZtValue* self) {
        return self.m_float > 0;
    }

    override ZtValue op_cast(ZtValue* self, ZtType type) {
        if (type == this)
            return self.deRefed;

        else if (type == interpreter.stringType)
            return interpreter.stringType.make(self.m_float.text);
        else if (type == interpreter.integerType)
            return interpreter.floatType.make(cast(int) self.m_float);
        else
            return super.op_cast(self, type);
    }

    override bool op_equal(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return self.m_float == rhs.m_float;
        else if (rhs.type == interpreter.integerType)
            return self.m_float == rhs.m_int;
        else if (rhs.type == interpreter.booleanType)
            return self.op_eval == rhs.m_bool;
        else
            return false;
    }

    override int op_cmp(ZtValue* self, ZtValue rhs) {
        float result;
        if (rhs.type == this)
            result = self.m_float - rhs.m_float;
        else if (rhs.type == interpreter.integerType)
            result = self.m_float - rhs.m_int;
        else
            return super.op_cmp(self, rhs);
        if (result > 0)
            return 1;
        else if (result < 0)
            return -1;
        else
            return 0;
    }

    override ZtValue op_add(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_float + rhs.m_float);
        else if (rhs.type == interpreter.integerType)
            return make(self.m_float + rhs.m_int);
        else
            return super.op_add(self, rhs);
    }

    override ZtValue op_subtract(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_float - rhs.m_float);
        else if (rhs.type == interpreter.integerType)
            return make(self.m_float - rhs.m_int);
        else
            return super.op_subtract(self, rhs);
    }

    override ZtValue op_multiply(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_float * rhs.m_float);
        else if (rhs.type == interpreter.integerType)
            return make(self.m_float * rhs.m_int);
        else
            return super.op_multiply(self, rhs);
    }

    override ZtValue op_divide(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_float / rhs.m_float);
        else if (rhs.type == interpreter.integerType)
            return make(self.m_float / rhs.m_int);
        else
            return super.op_divide(self, rhs);
    }

    override ZtValue op_modulo(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_float % rhs.m_float);
        else if (rhs.type == interpreter.integerType)
            return make(self.m_float % rhs.m_int);
        else
            return super.op_modulo(self, rhs);
    }

    override ZtValue op_positive(ZtValue* self) {
        return make(self.m_float < 0 ? -self.m_float : self.m_float);
    }

    override ZtValue op_negative(ZtValue* self) {
        return make(-self.m_float);
    }

    override void op_increment(ZtValue* self) {
        self.m_float++;
    }

    override void op_decrement(ZtValue* self) {
        self.m_float--;
    }
}
