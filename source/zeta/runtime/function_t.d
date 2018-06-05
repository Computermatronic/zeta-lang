/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
 module zeta.runtime.function_t;

import zeta.interpreter.type;
import zeta.interpreter.core;
import zeta.runtime;

import zeta.parser.ast;
import zeta.interpreter.context;

class FunctionType : Type {
	Interpreter interpreter;
	ushort typeID;

	void initialize(Interpreter interpreter, ushort typeID) {
		this.interpreter = interpreter;
		this.typeID = typeID;
	}

	void finalize() {
	}

	@property string name() {
		return "null";
	}

	Value make(FunctionNode func, Context ctx) {
		Value result = { typeID: this.typeID, ptr1: cast(void*)func, ptr2: cast(void*)ctx };
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
		else throw new RuntimeException("Cannot convert function to " ~ interpreter.types[src.typeID].name);
	}

	bool op_equal(Value* lhs, Value* rhs) {
		return lhs.typeID == rhs.typeID || 
			(interpreter.types[rhs.typeID] == interpreter.stringType && rhs.string_.length == 0) ||
			(interpreter.types[rhs.typeID] == interpreter.arrayType && rhs.array_.length == 0);
	}

	int op_comp(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot compare function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value  op_new(Value[] args) {
		throw new RuntimeException("Cannot create new function");
	}

	Value op_call(Value* lhs, Value[] args) {
		auto func = cast(FunctionNode)lhs.ptr1;
		auto ctx = cast(Context)lhs.ptr2;
		auto old_ctx = interpreter.context;
		interpreter.context = ctx;
		auto result = interpreter.executeFunction(func, args);
		interpreter.context = old_ctx;
		return result;
	}

	Value* op_index(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot index function with arguments " ~
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
		throw new RuntimeException("Cannot add function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_subtract(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot subtract function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_multiply(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot multiply function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_divide(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot divide function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_modulo(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot modulo function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitAnd(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise and function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitOr(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise or function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitXor(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise exclusive or function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftLeft(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift left function and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftRight(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift right function and " ~ interpreter.types[rhs.typeID].name); 
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
