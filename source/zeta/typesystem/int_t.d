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

    override ZtValue op_binary(ZtValue* self, ZtAstBinary.Operator op, ZtValue rhs) {
        auto do_op(T)(ZtAstBinary.Operator op, T val) {
            with (ZtAstBinary.Operator) switch (op) {
            case add:
                return self.m_int + val;
            case subtract:
                return self.m_int - val;
            case multiply:
                return self.m_int * val;
            case divide:
                return self.m_int / val;
            case modulo:
                return self.m_int % val;
                static if (is(typeof(self.m_int) == typeof(val))) {
            case bitAnd:
                    return self.m_int & val;
            case bitOr:
                    return self.m_int | val;
            case bitXor:
                    return self.m_int ^ val;
            case bitShiftLeft:
                    return self.m_int << val;
            case bitShiftRight:
                    return self.m_int >> val;
                }
            default:
                super.op_binary(self, op, rhs);
                return T.init;
            }
        }

        if (rhs.type == this)
            return make(do_op(op, rhs.m_int));
        else if (rhs.type == interpreter.integerType)
            return interpreter.floatType.make(do_op(op, rhs.m_float));
        else
            return super.op_binary(self, op, rhs);
    }

    override ZtValue op_unary(ZtValue* self, ZtAstUnary.Operator op) {
        with (ZtAstUnary.Operator) switch (op) {
        case increment:
            self.m_int++;
            return self.deRefed();
        case decrement:
            self.m_int--;
            return self.deRefed();
        case positive:
            return self.deRefed();
        case negative:
            return make(-self.m_int);
        default:
            return super.op_unary(self, op);
        }
    }

    override void op_assignBinary(ZtValue* self, ZtAstBinary.Operator op, ZtValue rhs) {
        void do_op(T)(ZtAstBinary.Operator op, T val) {
            with (ZtAstBinary.Operator) switch (op) {
            case add:
                self.m_int += val;
                return;
            case subtract:
                self.m_int -= val;
                return;
            case multiply:
                self.m_int *= val;
                return;
            case divide:
                self.m_int /= val;
                return;
            case modulo:
                self.m_int %= val;
                return;
            static if (is(typeof(self.m_int) == typeof(val))) {
            case bitAnd:
                    self.m_int &= val;
                    return;
            case bitOr:
                    self.m_int |= val;
                    return;
            case bitXor:
                    self.m_int ^= val;
                    return;
            case bitShiftLeft:
                    self.m_int = self.m_int << val;
                    return;
            case bitShiftRight:
                    self.m_int = self.m_int >> val;
                    return;
                }
            default:
                super.op_assignBinary(self, op, rhs);
            }
        }

        if (rhs.type == this)
            do_op(op, rhs.m_int);
        else
            super.op_assignBinary(self, op, rhs);
    }
}
