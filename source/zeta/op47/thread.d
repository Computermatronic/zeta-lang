/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.op47.thread;

import std.range : ElementType;

import zeta.op47;

struct Op47Thread {
    immutable ubyte[] program;
    uint ip;
    Op47Stackframe* self;
    Op47Value[] stack;

    pragma(inline, true) Type decode(Type)() {
        auto result = *cast(Type*)&program[ip];
        ip += Type.sizeof;
        return result;
    }

    pragma(inline, true) Type decodeArray(Type)(uint len) {
        auto result = cast(Type) program[ip .. ip + len * ElementType!(Type).sizeof];
        ip += len * ElementType!(Type).sizeof;
        return result;
    }

    pragma(inline, true) Op47Value* decodeAddress() {
        ubyte frm = decode!ubyte();
        ushort off = decode!ushort();
        if (frm == -1) {
            assert(!self.isVirtual);
            return &stack[self.stp + off];
        } else if (frm == 0) {
            return &stack[self.sbp + off];
        } else {
            auto frame = self.getOuter(frm);
            if (frame.isVirtual)
                return &frame.virtualStack[off];
            else
                return &stack[frame.sbp];
        }
    }

    void execute(uint count) {
        for (uint done = 0; done < count; done++)
            with (Op47Opcode) switch (program[ip++]) {
        case load_bool:
            auto dst = decodeAddress(), val = decode!bool();
            *dst = Op47Value(val);
            break;

        case load_int:
            auto dst = decodeAddress(), val = decode!long();
            *dst = Op47Value(val);
            break;

        case load_float:
            auto dst = decodeAddress(), val = decode!double();
            *dst = Op47Value(val);
            break;

        case load_string:
            auto dst = decodeAddress(), len = decode!uint();
            auto val = decodeArray!string(len);
            *dst = Op47Value(val);
            break;

        case math_add:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs + *rhs;
            break;

        case math_subtract:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs - *rhs;
            break;

        case math_multiply:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs * *rhs;
            break;

        case math_divide:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs / *rhs;
            break;

        case math_modulo:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs % *rhs;
            break;

        case math_increment:
            auto src = decodeAddress();
            (*src)++;
            break;

        case math_decrement:
            auto src = decodeAddress();
            (*src)--;
            break;

        case math_negative:
            auto src = decodeAddress(), dst = decodeAddress();
            *dst = -*src;
            break;

        case bit_and:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs & *rhs;
            break;

        case bit_or:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs | *rhs;
            break;

        case bit_xor:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs ^ *rhs;
            break;

        case bit_shiftLeft:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs << *rhs;
            break;

        case bit_shiftRight:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = *lhs >> *rhs;
            break;

        case bit_not:
            auto src = decodeAddress(), dst = decodeAddress();
            *dst = ~*src;
            break;

        case logic_equal:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = Op47Value(*lhs == *rhs);
            break;

        case logic_cmp:
            auto lhs = decodeAddress(), rhs = decodeAddress(), dst = decodeAddress();
            *dst = lhs.opCmp(*rhs);
            break;

        case op_move:
            auto src = decodeAddress(), dst = decodeAddress();
            *dst = *src;
            break;

        case op_jump:
            auto loc = decode!uint();
            ip = loc;
            break;
        
        case op_jumpIf:
            auto cnd = decodeAddress(), loc = decode!uint();
            if (*cnd)
                ip = loc;
            break;

        case op_call:
            auto func = decodeAddress(), args = decodeAddress();
            if (func.isType!Op47Closure) {
                auto closure = func.asType!Op47Closure;
                self = new Op47Stackframe(self.stp, self.stp + 1, ip, self, closure.outer);
                ip = closure.ip;
                stack[self.sbp] = *args;
            } else if (func.isType!Op47ForeignFunction) {
                if (args.isType!(Op47Value[]))
                    stack[self.stp] = func.asType!Op47ForeignFunction()(
                            args.asType!(Op47Value[]));
                else
                    stack[self.stp] = func.asType!Op47ForeignFunction()([*args]);
            } else
                assert(0, "Error: Cannot call type " ~ func.name);
            break;

        case op_ret:
            auto ret = *decodeAddress();
            ip = self.ret;
            self = self.prev;
            stack[self.stp] = ret;
            break;

        case op_setstack:
            auto off = decode!ushort();
            self.stp = self.sbp + off;
            break;

        case op_closure:
            auto loc = decode!uint(), dst = decodeAddress();
            *dst = Op47Closure(loc, self);
            break;

        case op_concat:
            auto dst = decodeAddress(), src = decodeAddress();
            *dst ~= *src;
            break;

        case op_index:
            auto src = decodeAddress(), idx = decodeAddress(), dst = decodeAddress();
            *dst = (*src)[*idx];
            break;

        case op_indexAssign:
            auto dst = decodeAddress(), idx = decodeAddress(), src = decodeAddress();
            (*dst)[*idx] = *src;
            break;

        default:
            break;
        }
    }

    void op_call(Op47Closure closure, Op47Value args) {
        self = new Op47Stackframe(self.stp, self.stp + 1, ip, self, closure.outer);
        ip = closure.ip;
        stack[self.sbp + 1] = args;
    }

    void op_ret(Op47Value arg) {
        ip = self.ret;
        self = self.prev;
    }

    Op47Value op_closure(uint ip) {
        return Op47Value(Op47Closure(ip, self));
    }

    void op_setstack(ubyte offset) {
        assert(!self.isVirtual);
        self.stp = self.sbp + offset;
    }
}
