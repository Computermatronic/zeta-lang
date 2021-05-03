/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.op47.value;

import zeta.utils;
import zeta.op47;

struct Op47Closure {
    uint ip;
    Op47Stackframe* outer;
}

alias Op47ForeignFunction = Op47Value delegate(Op47Value[]);

struct Op47Value {
    Union!(void*, bool, long, float, string, Op47Value[], Op47ForeignFunction, Op47Closure) tuple;
    ushort typeID;

    this(Rhs)(Rhs rhs) {
        static if (is(Rhs == typeof(this)))
            this = rhs;
        foreach (i, v; this.tuple) {
            static if (__traits(compiles, v = rhs)) {
                v = rhs;
                typeID = i;
            }
        }
    }

    @property bool isNull() {
        if (typeID == 0)
            return true;
        foreach (i, v; tuple) {
            static if (__traits(compiles, v is null)) {
                if (i == typeID)
                    return v is null;
            } else static if (is(typeof(v) == Op47Closure)) {
                if (i == typeID)
                    return v.ip == 0;
            }
        }
        return false;
    }

    @property string name() const {
        foreach (i, v; this.tuple) {
            if (i == this.typeID)
                return typeof(v).stringof;
        }
        assert(0, "Illegal or unknown type");
    }

    bool isType(Type)() {
        foreach (i, v; this.tuple) {
            static if (is(typeof(v) == Type)) {
                if (this.typeID == i)
                    return true;
            }
        }
        return false;
    }

    Type asType(Type)() {
        foreach (i, v; this.tuple) {
            static if (is(typeof(v) == Type)) {
                if (this.typeID == i)
                    return v;
            }
        }
        assert(0, "Error: Incorrect type");
    }

    typeof(this) opAssign(Rhs)(const Rhs rhs) {
        static if (is(typeof(Rhs) == typeof(this)))
            this = rhs;
        foreach (i, v; this.tuple) {
            static if (__traits(compiles, v = rhs)) {
                v = rhs;
                this.typeID = i;
                return this;
            }
        }
        assert(0, "Illegal or unknown type");
    }

    typeof(this) opOpAssign(string op, Rhs)(Rhs rhs) {
        foreach (i, ref v; this.tuple) {
            static if (is(Rhs == typeof(this))) {
                foreach (j, u; rhs.tuple) {
                    static if (__traits(compiles, mixin("v" ~ op ~ "=u"))) {
                        if (i == this.typeID && j + 1 == rhs.typeID) {
                            mixin("v" ~ op ~ "=u;");
                            return this;
                        }
                    }
                }
            } else static if (__traits(compiles, mixin("v" ~ op ~ "=rhs"))) {
                if (i == this.typeID) {
                    mixin("v" ~ op ~ "=rhs;");
                    return this;
                }
            }
        }
        assert(0, "Error: Cannot " ~ op ~ " with " ~ this.name ~ "and " ~ rhs.name);
    }

    typeof(this) opUnary(string op)() {
        foreach (i, v; this.tuple) {
            static if (__traits(compiles, mixin(op ~ "v"))) {
                if (i == this.typeID)
                    return typeof(this)(mixin(op ~ "v"));
            }
        }
        assert(0, "Error: Cannot " ~ op ~ " type " ~ this.name);
    }

    typeof(this) opBinary(string op, Rhs)(const Rhs rhs) const {
        foreach (i, v; this.tuple) {
            static if (is(Rhs == typeof(this))) {
                foreach (j, u; rhs.tuple) {
                    static if (__traits(compiles, mixin("v" ~ op ~ "u"))) {
                        if (i == this.typeID && j + 1 == rhs.typeID)
                            return typeof(this)(mixin("v" ~ op ~ "u"));
                    }
                }
            } else static if (__traits(compiles, mixin("v" ~ op ~ "rhs"))) {
                if (i == this.typeID)
                    return typeof(this)(mixin("v" ~ op ~ "rhs"));
            }
        }
        assert(0, "Error: Cannot " ~ op ~ " with " ~ this.name ~ "and " ~ rhs.name);
    }

    int opCmp(Rhs)(const Rhs rhs) const {
        foreach (i, v; this.tuple) {
            foreach (j, u; rhs.tuple) {
                static if (__traits(compiles, v < u)) {
                    if (i == this.typeID && j == rhs.typeID) {
                        if (u < v)
                            return 1;
                        if (v < u)
                            return -1;
                        return 0;
                    }
                }
            }
        }
        assert(0, "Error: Cannot cmp " ~ rhs.name);
    }

    bool opCast(T : bool)() const {
        foreach (i, v; this.tuple) {
            static if (__traits(compiles, cast(bool) v)) {
                if (i == this.typeID)
                    return cast(bool) v;
            }
        }
        return false;
    }

    typeof(this) opIndex(Idx)(Idx idx) {
        foreach (i, ref v; this.tuple) {
            static if (is(Idx == typeof(this))) {
                foreach (j, u; idx.tuple) {
                    static if (__traits(compiles, typeof(this)(v[u]))) {
                        if (i == this.typeID && j + 1 == idx.typeID)
                            return typeof(this)(v[u]);
                    }
                }
            } else static if (__traits(compiles, typeof(this)(v[idx]))) {
                if (i == this.typeID)
                    return typeof(this)(v[idx]);
            }
        }
        assert(0);
    }

    typeof(this) opIndexAssign(Idx, Rhs)(Idx idx, Rhs rhs) {
        foreach (i, ref v; this.tuple) {
            static if (is(Idx == typeof(this))) {
                foreach (j, u; idx.tuple) {
                    static if (__traits(compiles, mixin("v[u] = rhs"))) {
                        if (i == this.typeID && j + 1 == idx.typeID)
                            return typeof(this)(v[u] = typeof(this)(rhs));
                    }
                }
            } else static if (__traits(compiles, mixin("v[idx] = rhs"))) {
                if (i == this.typeID)
                    return typeof(this)(v[idx] = typeof(this)(rhs));
            }
        }
        assert(0);
    }
}
