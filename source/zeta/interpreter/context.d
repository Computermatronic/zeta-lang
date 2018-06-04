/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.interpreter.context;

import std.format : format;
import zeta.parser.ast;

class Context {
	Context outer;
	DeclarationNode[][string] table;

	bool define(string name, DeclarationNode node) {
		auto entries = name in table;
		if (entries !is null && cast(FunctionNode)node) {
			auto paramaters = (cast(FunctionNode)node).paramaters.length;
			foreach(entry; *entries) {
				if ((cast(FunctionNode)entry) || (cast(FunctionNode)entry).paramaters.length == paramaters)
					return false;
			}
			(*entries) ~= node;
		} else table[name] = [node];
		return true;
	}

	bool isDefined(string name, int paramaters = -1) {
		return get(name, paramaters) !is null;
	}

	DeclarationNode get(string name, int paramaters = -1) {
		auto entries = node.name in table;
		if (entries !is null) {
			foreach(entry; *entries) {
				if (paramaters == -1 || (cast(FunctionNode)entry) && (cast(FunctionNode)entry).paramaters.length == paramaters))
					return entry;
			}
		} else if (outer !is null) return outer.get(name, paramaters);
		else return null;
	}
}
