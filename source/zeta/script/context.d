/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.script.context;

import zeta.type.value;

class ZtLexicalContext {
    ZtLexicalContext parent;
    ZtValue[string] namespace;
    bool isRoot;
    
    this() {
        isRoot = true;
    }
    
    this(ZtLexicalContext parent) {
        this.parent = parent;
    }
    
    ZtValue get(string name) {
        if (auto result = name in namespace) return *result;
        else if (parent !is null) return parent.get(name);
        else assert(0, "ZtValue "~name~" doesn't exist!");
    }
    
    ZtValue tryGet(string name) {
        if (auto result = name in namespace) return *result;
        else if (parent !is null) return parent.tryGet(name);
        else return null;
    }
    
    void define(string name, ZtValue assign) {
        if (name in namespace) assert(0, "ZtValue "~name~" is already defined");
        namespace[name] = assign;
    }

    void set(string name, ZtValue assign) {
        assert(!isRoot, "Cannot redefine system constants.");
        if (name in namespace)
            namespace[name] = assign;
        else if (parent !is null)
            parent.set(name,assign);
        else assert(0, "ZtValue "~name~" doesn't exist!");
    }
}