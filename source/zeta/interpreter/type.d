/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.interpreter.type;

import zeta.interpreter.core;

struct Value {
	ushort typeID;
	union {
		struct {
			void* ptr1;
			void* ptr2;
		}
		bool bool_;
		int int_;
		float float_;
		string string_;
		Value[] array_;
	}
}

interface Type {
	void initialize(Interpreter interpreter, ushort typeID);
	void finalize();

	@property string name();

	bool   op_eval(Value* src);
	Value  op_cast(Value* src, Type type);

	bool   op_equal(Value* lhs, Value* rhs);
	int    op_comp(Value* lhs, Value* rhs);

	Value  op_new(Value[] args);
	Value  op_call(Value* lhs, Value[] args);

	Value* op_index(Value* lhs, Value[] args);
	Value* op_dispatch(Value* lhs, string id);

	Value  op_concat(Value* lhs, Value* rhs);
	void   op_concatAssign(Value* lhs, Value* rhs);

	Value  op_add(Value* lhs, Value* rhs);
	Value  op_subtract(Value* lhs, Value* rhs);
	Value  op_multiply(Value* lhs, Value* rhs);
	Value  op_divide(Value* lhs, Value* rhs);
	Value  op_modulo(Value* lhs, Value* rhs);

	Value  op_bitAnd(Value* lhs, Value* rhs);
	Value  op_bitOr(Value* lhs, Value* rhs);
	Value  op_bitXor(Value* lhs, Value* rhs);
	Value  op_bitShiftLeft(Value* lhs, Value* rhs);
	Value  op_bitShiftRight(Value* lhs, Value* rhs);

	Value  op_posative(Value* src);
	Value  op_negative(Value* src);

	Value  op_bitNot(Value* src);

	void   op_increment(Value* src);
	void   op_decrement(Value*);
}
