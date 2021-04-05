/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.script.context;

import zeta.typesystem.type;
import zeta.script.exception;

class ZtLexicalContext {
    ZtLexicalContext outer;
    ZtValue[string] table;

    this(ZtLexicalContext outer = null) {
        this.outer = outer;
    }

    ZtValue lookup(string name) {
        if (auto result = tryLookup(name))
            return makeRef(result);
        else
            assert(0, `Error: no such def or function '` ~ name ~ `'exists`);
    }

    ZtValue* tryLookup(string name) {
        auto result = name in table;
        if (result !is null)
            return result;
        if (outer !is null)
            result = outer.tryLookup(name);
        return result;
    }

    void define(string name, ZtValue value) {
        auto result = this.tryLookup(name);
        if (result !is null)
            *result = value;
        else
            table[name] = value;
    }
}

class ZtWithContext : ZtLexicalContext {
    ZtLexicalContext outer;
    ZtValue[string] table;
    ZtValue subject;

    this(ZtValue subject, ZtLexicalContext outer = null) {
        this.outer = outer;
        this.subject = subject;
    }

    override ZtValue lookup(string name) {
        auto result = name in table;
        if (result !is null)
            return makeRef(result);
        try
            return subject.op_dispatch(name);
        catch (RuntimeException e) {
            //swallow
        }
        if (outer !is null)
            return outer.lookup(name);
        else
            assert(0, "Error: no such variable " ~ name);
    }

    override ZtValue* tryLookup(string name) {
        auto result = name in table;
        if (result !is null)
            return result;
        else if (outer !is null)
            return outer.tryLookup(name);
        else
            return null;
    }

    override void define(string name, ZtValue value) {
        auto result = this.tryLookup(name);
        if (result !is null)
            *result = value;
        else
            table[name] = value;
    }
}
