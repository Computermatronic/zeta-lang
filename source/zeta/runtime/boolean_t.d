/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by SeCampbell.
 * Written by SeCampbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.runtime.natives.boolean_t;

import zeta.runtime.type;
import zeta.runtime.interpreter;
import zeta.runtime.natives.types;

class BooleanType : Type {
	Interpreter interpreter;
	ushort typeID;

	Value trueValue, falseValue;

	void initialize(Interpreter interpreter, ushort typeID) {
		this.interpreter = interpreter;
		this.typeID = typeID;

		trueValue = make(true);
		falseValue = make(false);
	}

	void finalize() {
	}

	@property string name() {
		return "boolean";
	}

	Value make(bool value) {
		Value result = { typeID: this.typeID, bool_: value };
		return result;
	}

	bool op_eval(Value* src) {
		return src.bool_;
	}

	Value op_cast(Value* src, Type type) {
		if (type == this) return *src;
		else if (type == interpreter.stringType) return interpreter.stringType.make(src.bool_ ? "true" : "false");
		else if (type == interpreter.integerType) return interpreter.integerType.make(src.bool_ ? 1 : 0);
		else if (type == interpreter.floatType) return interpreter.floatType.make(src.bool_ ? 1.0 : 0.0);
		else throw new RuntimeException("Cannot convert boolean to " ~ interpreter.types[src.typeID].name);
	}

	bool op_equal(Value* lhs, Value* rhs) {
		try return lhs.bool_ == interpreter.types[rhs.typeID].op_cast(rhs, this).bool_;
		catch (RuntimeException e) return false;
	}

	int op_comp(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot compare boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value  op_new(Value[] args) {
		throw new RuntimeException("Cannot create new boolean");
	}

	Value op_call(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot call boolean with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_index(Value* lhs, Value[] args) {
		import std.algorithm : map;
		import std.string : join;
		throw new RuntimeException("Cannot index boolean with arguments " ~
			args.map!((element) => interpreter.types[element.typeID].name).join(", "));
	}

	Value* op_dispatch(Value* lhs, string id) {
		switch(id) {
			default:
				throw new RuntimeException("No member " ~ id ~ "for boolean");
		}
	}

	Value op_concat(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot concat boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	void op_concatAssign(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot concat boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_add(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot add boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_subtract(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot subtract boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_multiply(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot multiply boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_divide(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot divide boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_modulo(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot modulo boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitAnd(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise and boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitOr(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise or boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitXor(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise exclusive or boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftLeft(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift left boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_bitShiftRight(Value* lhs, Value* rhs) {
		throw new RuntimeException("Cannot bitwise shift right boolean and " ~ interpreter.types[rhs.typeID].name); 
	}

	Value op_posative(Value* src) {
		throw new RuntimeException("Cannot denegate boolean");
	}

	Value op_negative(Value* src) {
		throw new RuntimeException("Cannot negate boolean");
	}

	Value op_bitNot(Value* src) {
		throw new RuntimeException("Cannot bitwise not boolean");
	}

	void op_increment(Value* src) {
		throw new RuntimeException("Cannot increment boolean");
	}

	void op_decrement(Value*) {
		throw new RuntimeException("Cannot decrement boolean");
	}
}
