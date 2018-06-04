/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by SeCampbell.
 * Written by SeCampbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.runtime.natives.integer_t;

import zeta.runtime.type;
import zeta.runtime.interpreter;
import zeta.runtime.natives.types;

class IntegerType : Type {
	Interpreter interpreter;
	ushort typeID;

	void initialize(Interpreter interpreter, ushort typeID) {
		this.interpreter = interpreter;
		this.typeID = typeID;
	}

	void finalize() {
	}

	@property string name() {
		return "integer";
	}

	Value make(int value) {
		Value result = { typeID: this.typeID, int_: value };
		return result;
	}

	bool op_eval(Value* src) {
		return src.int_ > 0;
	}

	Value op_cast(Value* src, Type type) {
		import std.conv : to;
		if (type == this) return *src;

		else if (type == interpreter.stringType) return interpreter.stringType.make(src.int_.to!string);
		else if (type == interpreter.floatType) return interpreter.floatType.make(cast(float)src.int_);
		else throw new RuntimeException("Cannot convert integer to " ~ interpreter.types[src.typeID].name);
	}

	bool op_equal(Value* lhs, Value* rhs) {
		try return lhs.int_ == interpreter.types[rhs.typeID].op_cast(rhs, this).int_;
		catch (RuntimeException e) return false;
	}

	int op_comp(Value* lhs, Value* rhs) {
		return lhs.int_ - interpreter.types[rhs.typeID].op_cast(rhs, this).int_;
	}

	Value  op_new(Value[] args) {
		throw new RuntimeException("Cannot create new integer");
	}

	Value op_call(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot call integer with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_index(Value* lhs, Value[] args) {
import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot index integer with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_dispatch(Value* lhs, string id) {
		switch(id) {
			default:
				throw new RuntimeException("No member " ~ id ~ "for integer");
		}
	}

	Value op_concat(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot concat integer and " ~ interpreter.types[rhs.typeID].name); 
	}

	void op_concatAssign(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot concat integer and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_add(Value* lhs, Value* rhs) {
		return make(lhs.int_ + interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value  op_subtract(Value* lhs, Value* rhs) {
		return make(lhs.int_ - interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value  op_multiply(Value* lhs, Value* rhs) {
		return make(lhs.int_ * interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value  op_divide(Value* lhs, Value* rhs) {
		return make(lhs.int_ / interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value  op_modulo(Value* lhs, Value* rhs) {
		return make(lhs.int_ % interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value  op_bitAnd(Value* lhs, Value* rhs) {
		return make(lhs.int_ & interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value  op_bitOr(Value* lhs, Value* rhs) {
		return make(lhs.int_ | interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value op_bitXor(Value* lhs, Value* rhs) {
		return make(lhs.int_ ^ interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value op_bitShiftLeft(Value* lhs, Value* rhs) {
		return make(lhs.int_ << interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value op_bitShiftRight(Value* lhs, Value* rhs) {
		return make(lhs.int_ >> interpreter.types[rhs.typeID].op_cast(rhs, this).int_);
	}

	Value op_posative(Value* src) {
		return make(src.int_ < 0 ? -src.int_ : src.int_);
	}

	Value op_negative(Value* src) {
		return make(-src.int_);
	}

	Value op_bitNot(Value* src) {
		return make(~src.int_);
	}

	void op_increment(Value* src) {
		src.int_++;
	}

	void op_decrement(Value* src) {
		src.int_--;
	}
}
