/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.typesystem.int_t;

import std.conv;
import zeta.typesystem.type;
import zeta.script.interpreter;
import zeta.utils.error;
import zeta.script.exception;
import zeta.typesystem;

class ZtIntType : ZtType {
    ZtScriptInterpreter interpreter;

    ZtValue make(sizediff_t value) {
        ZtValue result;
        result.type = this;
        result.m_int = value;
        return result;
    }

    override void register(ZtScriptInterpreter interpreter) {
        this.interpreter = interpreter;
    }

    override @property string name() {
        return "integer";
    }

    override @property string op_tostring(ZtValue* self) {
        return self.m_int.text;
    }

    override bool op_eval(ZtValue* self) {
        return self.m_int > 0;
    }

    override ZtValue op_cast(ZtValue* self, ZtType type) {
        import std.conv : to;

        if (type == this)
            return self.deRefed;
        else if (type == interpreter.stringType)
            return interpreter.stringType.make(self.m_int.to!string);
        else if (type == interpreter.floatType)
            return interpreter.floatType.make(cast(float) self.m_int);
        else
            return super.op_cast(self, type);
    }

    override bool op_equal(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return self.m_int == rhs.m_int;
        else if (rhs.type == interpreter.floatType)
            return self.m_int == rhs.m_float;
        else if (rhs.type == interpreter.booleanType)
            return self.op_eval() == rhs.m_bool;
        return false;
    }

    override int op_cmp(ZtValue* self, ZtValue rhs) {
        return cast(int)(self.m_int - rhs.type.op_cast(&rhs, this).m_int);
    }

    override ZtValue op_add(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int + rhs.m_int);
        else if (rhs.type == interpreter.integerType)
            return interpreter.floatType.make(self.m_int + rhs.m_float);
        else
            return super.op_add(self, rhs);
    }

    override ZtValue op_subtract(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int - rhs.m_int);
        else if (rhs.type == interpreter.integerType)
            return interpreter.floatType.make(self.m_int - rhs.m_float);
        else
            return super.op_subtract(self, rhs);
    }

    override ZtValue op_multiply(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int * rhs.m_int);
        else if (rhs.type == interpreter.integerType)
            return interpreter.floatType.make(self.m_int * rhs.m_float);
        else
            return super.op_multiply(self, rhs);
    }

    override ZtValue op_divide(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int / rhs.m_int);
        else if (rhs.type == interpreter.integerType)
            return interpreter.floatType.make(self.m_int / rhs.m_float);
        else
            return super.op_divide(self, rhs);
    }

    override ZtValue op_modulo(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int % rhs.m_int);
        else if (rhs.type == interpreter.integerType)
            return interpreter.floatType.make(self.m_int % rhs.m_float);
        else
            return super.op_modulo(self, rhs);
    }

    override ZtValue op_bitAnd(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int & rhs.m_int);
        else
            return super.op_bitAnd(self, rhs);
    }

    override ZtValue op_bitOr(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int | rhs.m_int);
        else
            return super.op_bitOr(self, rhs);
    }

    override ZtValue op_bitXor(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int ^ rhs.m_int);
        else
            return super.op_bitXor(self, rhs);
    }

    override ZtValue op_bitShiftLeft(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int << rhs.m_int);
        else
            return super.op_bitShiftLeft(self, rhs);
    }

    override ZtValue op_bitShiftRight(ZtValue* self, ZtValue rhs) {
        if (rhs.type == this)
            return make(self.m_int >> rhs.m_int);
        else
            return super.op_bitShiftRight(self, rhs);
    }

    override ZtValue op_positive(ZtValue* self) {
        return make(self.m_int < 0 ? -self.m_int : self.m_int);
    }

    override ZtValue op_negative(ZtValue* self) {
        return make(-self.m_int);
    }

    override ZtValue op_bitNot(ZtValue* self) {
        return make(~self.m_int);
    }

    override void op_increment(ZtValue* self) {
        self.m_int++;
    }

    override void op_decrement(ZtValue* self) {
        self.m_int--;
    }
}
