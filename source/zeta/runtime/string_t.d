/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.runtime.string_t;

import zeta.interpreter.type;
import zeta.interpreter.core;
import zeta.runtime;

class StringType : Type {
	Interpreter interpreter;
	ushort typeID;

	void initialize(Interpreter interpreter, ushort typeID) {
		this.interpreter = interpreter;
		this.typeID = typeID;
	}

	void finalize() {
	}

	@property string name() {
		return "string";
	}

	Value make(string value) {
		Value result = { typeID: this.typeID, string_: value };
		return result;
	}

	bool op_eval(Value* src) {
		return src.string_.length > 0 && src.string_ != "false";
	}

	Value op_cast(Value* src, Type type) {
		import std.conv : to;
		if (type == this) return *src;

		else if (type == interpreter.nullType) return make("");
		else if (type == interpreter.integerType) return interpreter.integerType.make(src.string_.to!int());
		else if (type == interpreter.floatType) return interpreter.floatType.make(src.string_.to!float());
		else throw new RuntimeException("Cannot convert string to " ~ interpreter.types[src.typeID].name);
	}

	bool op_equal(Value* lhs, Value* rhs) {
		try return lhs.string_ == interpreter.types[rhs.typeID].op_cast(rhs, this).string_;
		catch (RuntimeException e) return false;
	}

	int op_comp(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot compare string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value  op_new(Value[] args) {
		throw new RuntimeException("Cannot create new string");
	}

	Value op_call(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot call string with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_index(Value* lhs, Value[] args) {
		if (args.length != 1) throw new RuntimeException("Incorrect number of arguments to index string");
		auto index = interpreter.types[args[0].typeID].op_cast(&args[0], interpreter.integerType).int_;
		if (index < 0 || index > lhs.string_.length) throw new RuntimeException("Out of bounds argument for string index");
		interpreter.realValue = make(lhs.string_[index .. index + 1]);
		return &interpreter.realValue;
	}

	Value* op_dispatch(Value* lhs, string id) {
		switch(id) {
			case "length":
				interpreter.realValue = interpreter.integerType.make(cast(int)lhs.string_.length);
				return &interpreter.realValue;
			default:
				throw new RuntimeException("No member " ~ id ~ "for string");
		}
	}

	Value op_concat(Value* lhs, Value* rhs) {
		return make(lhs.string_ ~ interpreter.types[rhs.typeID].op_cast(rhs, this).string_);
	}

	void op_concatAssign(Value* lhs, Value* rhs) {
		lhs.string_ ~= interpreter.types[rhs.typeID].op_cast(rhs, this).string_;
	}

	Value op_add(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot add string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_subtract(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot subtract string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_multiply(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot multiply string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_divide(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot divide string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_modulo(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot modulo string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitAnd(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise and string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitOr(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise or string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitXor(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise exclusive or string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftLeft(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift left string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftRight(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift right string and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_posative(Value* src) {
		throw new RuntimeException("Cannot denegate string");
	}

	Value op_negative(Value* src) {
		throw new RuntimeException("Cannot negate string");
	}

	Value op_bitNot(Value* src) {
		throw new RuntimeException("Cannot bitwise not string");
	}

	void op_increment(Value* src) {
		throw new RuntimeException("Cannot increment string");
	}

	void op_decrement(Value*) {
		throw new RuntimeException("Cannot decrement string");
	}
}
