/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.runtime.natives.array_t;

import zeta.runtime.type;
import zeta.runtime.interpreter;
import zeta.runtime.natives.types;

class ArrayType : Type {
	Interpreter interpreter;
	ushort typeID;

	void initialize(Interpreter interpreter, ushort typeID) {
		this.interpreter = interpreter;
		this.typeID = typeID;
	}

	void finalize() {
	}

	@property string name() {
		return "array";
	}

	Value make(Value[] value) {
		Value result = { typeID: this.typeID, array_: value };
		return result;
	}

	bool op_eval(Value* src) {
		return src.array_.length > 0;
	}

	Value op_cast(Value* src, Type type) {
		import std.conv : to;
		if (type == this) return *src;
		else if (type == interpreter.nullType) return make([]);
		else throw new RuntimeException("Cannot convert array to " ~ interpreter.types[src.typeID].name);
	}

	bool op_equal(Value* lhs, Value* rhs) {
		try return lhs.array_ == interpreter.types[rhs.typeID].op_cast(rhs, this).array_;
		catch (RuntimeException e) return false;
	}

	int op_comp(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot compare array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value  op_new(Value[] args) {
		throw new RuntimeException("Cannot create new array");
	}

	Value op_call(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot call array with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_index(Value* lhs, Value[] args) {
		if (args.length != 1) throw new RuntimeException("Incorrect number of arguments to index array");
		auto index = interpreter.types[args[0].typeID].op_cast(&args[0], interpreter.integerType).int_;
		if (index < 0 || index > lhs.array_.length) throw new RuntimeException("Out of bounds argument for array index");
		return &(lhs.array_)[index];
	}

	Value* op_dispatch(Value* lhs, string id) {
		switch(id) {
			case "length":
				interpreter.realValue = interpreter.integerType.make(cast(int)lhs.array_.length);
				return &interpreter.realValue;
			default:
				throw new RuntimeException("No member " ~ id ~ "for array");
		}
	}

	Value op_concat(Value* lhs, Value* rhs) {
		return make(lhs.array_ ~ interpreter.types[rhs.typeID].op_cast(rhs, this).array_);
	}

	void op_concatAssign(Value* lhs, Value* rhs) {
		lhs.array_ ~= interpreter.types[rhs.typeID].op_cast(rhs, this).array_;
	}

	Value op_add(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot add array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_subtract(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot subtract array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_multiply(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot multiply array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_divide(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot divide array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_modulo(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot modulo array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitAnd(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise and array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitOr(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise or array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitXor(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise exclusive or array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftLeft(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift left array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftRight(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift right array and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_posative(Value* src) {
		throw new RuntimeException("Cannot denegate array");
	}

	Value op_negative(Value* src) {
		throw new RuntimeException("Cannot negate array");
	}

	Value op_bitNot(Value* src) {
		throw new RuntimeException("Cannot bitwise not array");
	}

	void op_increment(Value* src) {
		throw new RuntimeException("Cannot increment array");
	}

	void op_decrement(Value*) {
		throw new RuntimeException("Cannot decrement array");
	}
}
