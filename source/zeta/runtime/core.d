/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.runtime.core;

import zeta.runtime.type;
import zeta.runtime.null_t;
import zeta.runtime.boolean_t;
import zeta.runtime.integer_t;
import zeta.runtime.float_t;
import zeta.runtime.string_t;
import zeta.runtime.array_t;

class Runtime {
	Type[] types;

	NullType nullType;
	BooleanType booleanType;
	IntegerType integerType;
	FloatType floatType;
	StringType stringType;
	ArrayType arrayType;

	this() {
		types ~= nullType = new NullType;
		types ~= booleanType = new BooleanType;
		types ~= integerType = new IntegerType;
		types ~= floatType = new FloatType;
		types ~= stringType = new StringType;
		types ~= arrayType = new ArrayType;

		foreach(k, v; types) {
			v.initialize(this, cast(ushort)k);
		}
	}

	template opDispatch(string op) {
		auto opDispatch(Args...)(Args args) if (op[0..3] == "op_") {
			mixin("return types[arg[0].typeID]." ~ op ~ "(args);");
		}
	}
}

class RuntimeException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}
