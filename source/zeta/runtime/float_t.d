/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.runtime.float_t;

import zeta.interpreter.type;
import zeta.interpreter.core;
import zeta.runtime;

class FloatType : Type {
	Interpreter interpreter;
	ushort typeID;

	void initialize(Interpreter interpreter, ushort typeID) {
		this.interpreter = interpreter;
		this.typeID = typeID;
	}

	void finalize() {
	}

	@property string name() {
		return "float";
	}

	Value make(float value) {
		Value result = { typeID: this.typeID, float_: value };
		return result;
	}

	bool op_eval(Value* src) {
		return src.float_ > 0;
	}

	Value op_cast(Value* src, Type type) {
		import std.conv : to;
		if (type == this) return *src;

		else if (type == interpreter.stringType) return interpreter.stringType.make(src.float_.to!string);
		else if (type == interpreter.integerType) return interpreter.floatType.make(cast(int)src.float_);
		else throw new RuntimeException("Cannot convert float to " ~ interpreter.types[src.typeID].name);
	}

	bool op_equal(Value* lhs, Value* rhs) {
		try return lhs.float_ == interpreter.types[rhs.typeID].op_cast(rhs, this).float_;
		catch (RuntimeException e) return false;
	}

	int op_comp(Value* lhs, Value* rhs) {
		return (lhs.float_ - interpreter.types[rhs.typeID].op_cast(rhs, this).float_) > 0 ? 1 : 0;
	}

	Value  op_new(Value[] args) {
		throw new RuntimeException("Cannot create new float");
	}

	Value op_call(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot call float with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_index(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot index float with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_dispatch(Value* lhs, string id) {
		switch(id) {
			default:
				throw new RuntimeException("No member " ~ id ~ "for float");
		}
	}

	Value op_concat(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot concat float and " ~ interpreter.types[rhs.typeID].name); 
	}

	void op_concatAssign(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot concat float and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_add(Value* lhs, Value* rhs) {
		return make(lhs.float_ + interpreter.types[rhs.typeID].op_cast(rhs, this).float_);
	}

	Value  op_subtract(Value* lhs, Value* rhs) {
		return make(lhs.float_ - interpreter.types[rhs.typeID].op_cast(rhs, this).float_);
	}

	Value  op_multiply(Value* lhs, Value* rhs) {
		return make(lhs.float_ * interpreter.types[rhs.typeID].op_cast(rhs, this).float_);
	}

	Value  op_divide(Value* lhs, Value* rhs) {
		return make(lhs.float_ / interpreter.types[rhs.typeID].op_cast(rhs, this).float_);
	}

	Value  op_modulo(Value* lhs, Value* rhs) {
		return make(lhs.float_ % interpreter.types[rhs.typeID].op_cast(rhs, this).float_);
	}

	Value op_bitAnd(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise and float and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitOr(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise or float and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitXor(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise exclusive or float and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftLeft(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift left float and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftRight(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift right float and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value  op_posative(Value* src) {
		return make(src.float_ < 0 ? -src.float_ : src.float_);
	}

	Value  op_negative(Value* src) {
		return make(-src.float_);
	}

	Value  op_bitNot(Value* src) {
		throw new RuntimeException("Cannot bitwise not float");
	}

	void   op_increment(Value* src) {
		src.float_++;
	}

	void   op_decrement(Value* src) {
		src.float_--;
	}
}
