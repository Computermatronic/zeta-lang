module zeta.interpreter.context;

import zeta.interpreter.type;

class Context {
	Context outer;
	Value[string] table;

	this(Context outer = null) {
		this.outer = outer;
	}

	Value* lookup(string name) {
		auto result = name in table;
		if (result !is null ) return result;
		else if (outer !is null) return outer.lookup(name);
		else return null;
	}

	void define(string name, Value value) {
		auto result = this.lookup(name);
		if (result !is null) *result = value;
		else table[name] = value;
	}
}
