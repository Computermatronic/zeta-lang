/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.boolean;

import zeta.type.value;

class Bool : ZtValue {
    bool boolean;
    
    this(){}
    this(bool boolean) {
        this.boolean = boolean;
    }
    
    override bool toBool() {
        return boolean;
    }
    override ZtValue clone() {
        return new Bool(boolean);
    }
    override bool equals(ZtValue var) {
        if (auto boo = cast(Bool)var)
            return boolean==boo.boolean;
        else
            return false;
    }
    
    override string toString() const {
        return boolean ? "true" : "false";
    }
    
    override string type() const {
        return "boolean";
    }
}