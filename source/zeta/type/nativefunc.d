/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.nativefunc;

import std.functional;
import std.format;
import zeta.type.value;

class ZtNative : ZtValue {
    ZtValue delegate(ZtValue[]) dlg;
    string name;
    this(ZtValue delegate(ZtValue[]) dlg, string name) {
        this.name = name;
        this.dlg = dlg;
    }
    
    this(ZtValue function(ZtValue[]) dlg, string name) {
        this.name = name;
        this.dlg = toDelegate(dlg);
    }
    
    override bool toBool() {
        return true;
    }
    
    override ZtValue clone() {
        return this;
    }
    
    override bool equals(ZtValue var) {
        return this == var;
    }
    override string type() const {
        return "function";
    }
    
    override string toString() const {
        return format("function:%s", name);
    }
    
    override ZtValue call(ZtValue[] args) {
        return dlg(args);
    }
}