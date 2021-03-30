module zeta.script.scope_;

import zeta.script.variable;

class ZtScope
{
    ZtScope parent;
    Variable[string] namespace;
    
    this(){}
    this(ZtScope parent) {
        this.parent = parent;
    }
    
    Variable get(string name) {
        if (auto result = name in namespace) return *result;
        else if (parent !is null) return parent.get(name);
        else assert(0, "Variable "~name~" doesn't exist!");
    }
    
    Variable tryGet(string name) {
        if (auto result = name in namespace) return *result;
        else if (parent !is null) return parent.tryGet(name);
        else return null;
    }
    
    void define(string name, Variable assign) {
        if (name in namespace) assert(0, "Variable "~name~" is already defined");
        namespace[name] = assign;
    }

    void set(string name, Variable assign) {
        if (name in namespace)
            namespace[name] = assign;
        else if (parent !is null)
            parent.set(name,assign);
        else assert(0, "Variable "~name~" doesn't exist!");
    }
}