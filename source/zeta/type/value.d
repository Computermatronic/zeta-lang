/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.value;

abstract class ZtValue {
    abstract bool toBool();
    abstract bool equals(ZtValue var);
    abstract ZtValue clone();
    abstract string type() const;
    abstract override string toString() const;
    
    ZtValue add(ZtValue var) { assert(0, "Not implemented!"); }
    ZtValue sub(ZtValue var) { assert(0, "Not implemented!"); }
    ZtValue mul(ZtValue var) { assert(0, "Not implemented!"); }
    ZtValue div(ZtValue var) { assert(0, "Not implemented!"); }
    ZtValue mod(ZtValue var) { assert(0, "Not implemented!"); }
    
    ZtValue pos() { assert(0, "Not implemented!"); }
    ZtValue neg() { assert(0, "Not implemented!"); }
    
    void inc() { assert(0, "Not implemented!"); }
    void dec() { assert(0, "Not implemented!"); }
    
    bool greater(ZtValue var) { assert(0, "Not implemented!"); }
    bool less(ZtValue var) { assert(0, "Not implemented!"); }
    
    ZtValue concat(ZtValue val) { assert(0, "Not implemented!"); }
    ZtValue index(ZtValue index) { assert(0, "Not implemented!"); }
    void index(ZtValue index, ZtValue assign) { assert(0, "Not implemented!"); }
    
    ZtValue call(ZtValue[] args) { assert(0, "Not implemented!"); }

    void iterate(ZtValue dlg) { assert(0, "Not implemented!"); }
    
    ZtValue dispatchGet(string name) { assert(0, "Not implemented!"); }
    void dispatchSet(string name, ZtValue var) { assert(0, "Not implemented!"); }
    
    ZtValue dispatchCall(string name, ZtValue[] args) { assert(0, "Not implemented!"); }
}