/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.runtime;

public {
	import zeta.runtime.null_t;
	import zeta.runtime.boolean_t;
	import zeta.runtime.integer_t;
	import zeta.runtime.float_t;
	import zeta.runtime.string_t;
	import zeta.runtime.array_t;
	import zeta.runtime.function_t;
}

class RuntimeException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}
