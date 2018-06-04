/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.runtime.null_t;

import zeta.runtime.type;
import zeta.runtime.interpreter;
import zeta.runtime.natives.types;

class NullType : Type {
	Interpreter interpreter;
	ushort typeID;

	Value nullValue;

	void initialize(Interpreter interpreter, ushort typeID) {
		this.interpreter = interpreter;
		this.typeID = typeID;

		nullValue = make();
	}

	void finalize() {
	}

	@property string name() {
		return "null";
	}

	Value make() {
		Value result = { typeID: this.typeID };
		return result;
	}

	bool op_eval(Value* src) {
		return false;
	}

	Value op_cast(Value* src, Type type) {
		import std.conv : to;
		if (type == this) return *src;
		else if (type == interpreter.stringType) return interpreter.stringType.make("");
		else if (type == interpreter.arrayType) return interpreter.arrayType.make([]);
		else throw new RuntimeException("Cannot convert null to " ~ interpreter.types[src.typeID].name);
	}

	bool op_equal(Value* lhs, Value* rhs) {
		return lhs.typeID == rhs.typeID || 
			(interpreter.types[rhs.typeID] == interpreter.stringType && rhs.string_.length == 0) ||
			(interpreter.types[rhs.typeID] == interpreter.arrayType && rhs.array_.length == 0);
	}

	int op_comp(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot compare null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value  op_new(Value[] args) {
		throw new RuntimeException("Cannot create new null");
	}

	Value op_call(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot call null with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_index(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot index null with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_dispatch(Value* lhs, string id) {
		switch(id) {
			default:
				throw new RuntimeException("No member " ~ id ~ "for null");
		}
	}

	Value op_concat(Value* lhs, Value* rhs) {
		return *rhs;
	}

	void op_concatAssign(Value* lhs, Value* rhs) {
	}

	Value op_add(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot add null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_subtract(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot subtract null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_multiply(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot multiply null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_divide(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot divide null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_modulo(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot modulo null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitAnd(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise and null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitOr(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise or null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitXor(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise exclusive or null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftLeft(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift left null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftRight(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift right null and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_posative(Value* src) {
		throw new RuntimeException("Cannot denegate null");
	}

	Value op_negative(Value* src) {
		throw new RuntimeException("Cannot negate null");
	}

	Value op_bitNot(Value* src) {
		throw new RuntimeException("Cannot bitwise not null");
	}

	void op_increment(Value* src) {
		throw new RuntimeException("Cannot increment null");
	}

	void op_decrement(Value*) {
		throw new RuntimeException("Cannot decrement null");
	}
}
