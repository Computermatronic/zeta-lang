/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2022 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.runtime.type;

import std.algorithm;
import std.array;

import zeta.utils;
public import zeta.parse: ZtAstFunction, ZtAstBinary, ZtAstUnary;
import zeta.interpret;
import zeta.runtime;

abstract class ZtType {
    abstract void register(ZtScriptInterpreter interpreter);

    abstract @property string name();

    abstract @property string op_tostring(ZtValue* self);
    bool op_eval(ZtValue* self) {
        return true;
    }

    ZtValue op_cast(ZtValue* self, ZtType type) {
        if (type == this)
            return self.deRef;
        else
            throw new ZtRuntimeException("Cannot convert from type " ~ this.name ~ " to " ~ type.name);
    }

    bool op_equal(ZtValue* self, ZtValue rhs) {
        return *self == rhs;
    }

    int op_cmp(ZtValue* self, ZtValue rhs) {
        throw new ZtRuntimeException("Cannot cmp type " ~ this.name ~ " and " ~ rhs.type.name);
    }

    ZtValue op_new(ZtValue[] args) {
        throw new ZtRuntimeException("Cannot new type " ~ this.name);
    }

    ZtValue op_call(ZtValue* self, ZtValue[] args) {
        throw new ZtRuntimeException("Cannot call type " ~ this.name ~ " with (" ~ args.map!(
                (element) => element.type.name).join(", ") ~ ")");
    }

    ZtValue op_unary(ZtValue* self, ZtAstUnary.Operator op) {
        throw new ZtRuntimeException("Cannot '" ~ op ~ "' type " ~ this.name);
    }

    ZtValue op_binary(ZtValue* self, ZtAstBinary.Operator op, ZtValue rhs) {
        throw new ZtRuntimeException(
                "Cannot'" ~ op ~ "' with types " ~ this.name ~ " and " ~ rhs.type.name);
    }

    ZtValue op_index(ZtValue* self, ZtValue[] args) {
        throw new ZtRuntimeException("Cannot index type " ~ this.name ~ " with [" ~ args.map!(
                (element) => element.type.name).join(", ") ~ "]");
    }

    ZtValue op_dispatch(ZtValue* self, string id) {
        throw new ZtRuntimeException("No such member " ~ id ~ " for type " ~ this.name);
    }

    void op_assignBinary(ZtValue* self, ZtAstBinary.Operator op, ZtValue rhs) {
        throw new ZtRuntimeException(
                "Cannot'" ~ op ~ "=' with types " ~ this.name ~ " and " ~ rhs.type.name);
    }

    void op_assignIndex(ZtValue* self, ZtValue[] args, ZtAstBinary op, ZtValue rhs) {
        throw new ZtRuntimeException("Cannot index type " ~ this.name ~ " with [" ~ args.map!(
                (element) => element.type.name).join(", ") ~ "]");
    }

    void op_assignDispatch(ZtValue* self, string id, ZtValue rhs) {
        throw new ZtRuntimeException("No such member " ~ id ~ " for type " ~ this.name);
    }
}

// This is a funky way to implement transparent references. Basically the 
// opDispatch method forwards all requests to the m_ref.
struct ZtValue {
    union Val {
        bool m_bool;
        long m_int;
        double m_float;
        string m_string;
        ZtValue[ZtValue] m_table;
        ZtValue[] m_array;
        ZtClosure m_closure;
        ZtValue delegate(ZtScriptInterpreter, ZtValue[]) m_dfunc;
        ZtType m_type;
        ZtValue* m_ref;
    }

    ZtType _type;
    Val _val;
    bool _isRef;

    @property ZtType type() {
        if (_isRef)
            return _val.m_ref.type;
        else
            return _type;
    }

    @property ZtType type(ZtType assign) {
        if (_isRef)
            return _val.m_ref.type = assign;
        else
            return _type = assign;
    }

    @property bool isRef() {
        return _isRef;
    }

    ZtValue deRef() {
        if (_isRef)
            this = *this._val.m_ref;
        return this;
    }

    ZtValue deRefed() {
        if (_isRef)
            return *this._val.m_ref;
        return this;
    }

    auto opDispatch(string name, Args...)(Args args)
            if (__traits(hasMember, typeof(type), name)) {
        import std.traits : isCallable, Parameters;

        mixin("alias member = ZtType." ~ name ~ ";");
        static if (isCallable!member && is(Parameters!(member)[0] == ZtValue*))
            return mixin("type." ~ name ~ "(&this, args)");
        else static if (isCallable!member)
            return mixin("type." ~ name ~ "(args)");
        else
            return mixin("type." ~ name);
    }

    @property ref typeof(mixin("_val." ~ name)) opDispatch(string name)()
            if (__traits(hasMember, Val, name)) {
        if (_isRef)
            return mixin("_val.m_ref." ~ name);
        else
            return mixin("_val." ~ name);
    }
}

struct ZtClosure {
    ZtLexicalContext context;
    ZtAstFunction node;
}

ZtValue makeRef(ZtValue* value) {
    ZtValue result;
    result.type = value.type;
    result.m_ref = value;
    result._isRef = true;
    return result;
}
