/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.typesystem.float_t;

import std.conv;

import zeta.utils;
import zeta.script;
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

    override ZtValue op_binary(ZtValue* self, ZtAstBinary.Operator op, ZtValue rhs) {
        auto do_op(T)(ZtAstBinary.Operator op, T val) {
            with (ZtAstBinary.Operator) switch (op) {
            case add:
                return self.m_float + val;
            case subtract:
                return self.m_float - val;
            case multiply:
                return self.m_float * val;
            case divide:
                return self.m_float / val;
            case modulo:
                return self.m_float % val;
            default:
                super.op_binary(self, op, rhs);
                return T.init;
            }
        }

        if (rhs.type == this)
            return make(do_op(op, rhs.m_float));
        else if (rhs.type == interpreter.integerType)
            return make(do_op(op, rhs.m_int));
        else
            return super.op_binary(self, op, rhs);
    }

    override ZtValue op_unary(ZtValue* self, ZtAstUnary.Operator op) {
        with (ZtAstUnary.Operator) switch (op) {
            case increment:
                self.m_float++;
                return self.deRefed();
            case decrement:
                self.m_float--;
                return self.deRefed();
            case positive:
                return self.deRefed();
            case negative:
                return make(-self.m_float);
            default: 
                return super.op_unary(self, op);
        }
    }
    
    override void op_assignBinary(ZtValue* self, ZtAstBinary.Operator op, ZtValue rhs) {
        void do_op(T)(ZtAstBinary.Operator op, T val) {
            with (ZtAstBinary.Operator) switch (op) {
            case add:
                self.m_float += val;
                return;
            case subtract:
                self.m_float -= val;
                return;
            case multiply:
                self.m_float *= val;
                return;
            case divide:
                self.m_float /= val;
                return;
            case modulo:
                self.m_float %= val;
                return;
            default:
                super.op_assignBinary(self, op, rhs);
            }
        }

        if (rhs.type == this)
            do_op(op, rhs.m_float);
        else if (rhs.type == interpreter.integerType)
            do_op(op, rhs.m_int);
        else
            super.op_assignBinary(self, op, rhs);
    }
}
