/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.nullval;

import zeta.type.value;

Null nullValue;

static this() {
    nullValue = new Null();
}

class Null : ZtValue {
    
    this(){}
    
    override bool toBool() {
        return false;
    }
    override ZtValue clone() {
        return this;
    }
    override bool equals(ZtValue var) {
        return var == this;
    }
    
    override string toString() const {
        return "null";
    }
    
    override string type() const {
        return "Null";
    }
}