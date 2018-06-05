/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.interpreter.core;

import std.conv : to;
import zeta.parser.ast;
import zeta.interpreter.context;
import zeta.interpreter.type;
import zeta.runtime;

class Interpreter : ASTVisitor {
	Context context;
	Type[] types;

	NullType nullType;
	BooleanType booleanType;
	IntegerType integerType;
	FloatType floatType;
	StringType stringType;
	ArrayType arrayType;
	FunctionType functionType;

	bool shouldReturn;
	int continueCount, breakCount;

	Value realValue;
	Value* value;

	this() {
		types ~= nullType = new NullType;
		types ~= booleanType = new BooleanType;
		types ~= integerType = new IntegerType;
		types ~= floatType = new FloatType;
		types ~= stringType = new StringType;
		types ~= arrayType = new ArrayType;
		types ~= functionType = new FunctionType;

		foreach(k, v; types) {
			v.initialize(this, cast(ushort)k);
		}
	}

	void pushContext() {
		context = new Context(context);
	}

	void popContext() {
		context = context.outer;
	}

	template opDispatch(string op) {
		auto opDispatch(Args...)(Args args) if (op[0..3] == "op_") {
			mixin("return types[args[0].typeID]." ~ op ~ "(args);");
		}
	}

	Value executeFunction(FunctionNode node, Value[] arguments) {
		Value result = nullType.nullValue;
		pushContext();
		for(size_t i; i < node.paramaters.length; i++) {
			if (i < arguments.length) {
				context.define(node.paramaters[i].name, arguments[i]);
			} else if (node.paramaters[i].initializer !is null) {
				node.paramaters[i].initializer.accept(this);
				context.define(node.paramaters[i].name, *value);
			} else {
				context.define(node.paramaters[i].name, nullType.nullValue);
			}
		}
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn) {
				result = *value;
				break;
			}
		}
		shouldReturn = false;
		continueCount = breakCount = 0;
		popContext();
		return result;
	}

	void visit(ModuleNode node) {
		pushContext();
		foreach(member; node.members) {
			member.accept(this);
		}
	}

	void visit(ImportNode node) {
	}

	void visit(DefNode node) {
		if (node.initializer !is null) {
			node.initializer.accept(this);
			context.define(node.name, *value);
		} else {
			context.define(node.name, nullType.nullValue);
		}
	}

	void visit(FunctionNode node) {
		context.define(node.name, functionType.make(node, context));
		//foreach(paramater; node.paramaters) {
		//	paramater.accept(this);
		//}
		//foreach(member; node.members) {
		//	member.accept(this);
		//}
	}

	void visit(ClassNode node) {
		//foreach(inherit; node.inherits) {
		//	inherit.accept(this);
		//}
		//foreach(member; node.members) {
		//	member.accept(this);
		//}
	}

	void visit(AttributeNode node) {
		//foreach(argument; node.arguments) {
		//	argument.accept(this);
		//}
	}

	void visit(FunctionParamaterNode node) {
		//if (node.initializer !is null) {
		//	node.initializer.accept(this);
		//}
	}

	void visit(IfNode node) {
		node.subject.accept(this);
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn || breakCount > 1 || continueCount > 1) return;
		}
		if (node.else_ !is null) {
			node.else_.accept(this);
			if (shouldReturn || breakCount > 1 || continueCount > 1) return;
		}
	}

	void visit(ElseNode node) {
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn || breakCount > 1 || continueCount > 1) return;
		}
	}

	void visit(SwitchNode node) {
		node.subject.accept(this);
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn) return;
			else if (continueCount > 1) {
				continueCount--;
				break;
			} else if (continueCount == 1) {
				continueCount --;
				continue;
			} else if (breakCount > 0) {
				breakCount--;
				break;
			}
		}
	}

	void visit(SwitchCaseNode node) {
		foreach(argument; node.arguments) {
			argument.accept(this);
		}
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn || breakCount > 1 || continueCount > 1) return;
		}
	}

	void visit(ForNode node) {
		if (node.initializer !is null) node.initializer.accept(this);
		while(true) {
			if (node.subject !is null) node.subject.accept(this);
			if (!this.op_eval(value)) break;
			foreach(member; node.members) {
				member.accept(this);
				if (shouldReturn) return;
				else if (continueCount > 1) {
					continueCount--;
					break;
				} else if (continueCount == 1) {
					continueCount --;
					continue;
				} else if (breakCount > 0) {
					breakCount--;
					break;
				}
			}
			if (node.step !is null) node.step.accept(this);
		}
	}

	void visit(ForeachNode node) {
		foreach(initializer; node.initializers) {
			initializer.accept(this);
		}
		if (node.subject !is null) node.subject.accept(this);
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn) return;
			else if (continueCount > 1) {
				continueCount--;
				break;
			} else if (continueCount == 1) {
				continueCount --;
				continue;
			} else if (breakCount > 0) {
				breakCount--;
				break;
			}
		}
	}

	void visit(WhileNode node) {
		node.subject.accept(this);
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn) return;
			else if (continueCount > 1) {
				continueCount--;
				break;
			} else if (continueCount == 1) {
				continueCount --;
				continue;
			} else if (breakCount > 0) {
				breakCount--;
				break;
			}
		}
	}

	void visit(WithNode node) {
		node.subject.accept(this);
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn || breakCount > 1 || continueCount > 1) return;
		}
	}

	void visit(DoWhileNode node) {
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn) return;
			else if (continueCount > 1) {
				continueCount--;
				break;
			} else if (continueCount == 1) {
				continueCount --;
				continue;
			} else if (breakCount > 0) {
				breakCount--;
				break;
			}
		}
		node.subject.accept(this);
	}

	void visit(BreakNode node) {
		if (node.subject !is null) {
			node.subject.accept(this);
			breakCount = this.op_cast(value, integerType).int_;
		} else breakCount++;
	}

	void visit(ContinueNode node) {

		if (node.subject !is null) {
			node.subject.accept(this);
			continueCount = this.op_cast(value, integerType).int_;
		} else continueCount++;
	}

	void visit(ReturnNode node) {
		if (node.subject !is null) node.subject.accept(this);
		else {
			realValue = nullType.nullValue;
			value = &realValue;
		}
		shouldReturn = true;
	}

	void visit(ExpressionStatementNode node) {
		node.subject.accept(this);
	}

	void visit(UnaryNode node) {
		node.subject.accept(this);

		final switch(node.operator) with(UnaryNode.Operator) {
			case increment:
				this.op_increment(value);
				break;

			case decrement:
				this.op_decrement(value);
				break;

			case posative:
				realValue = this.op_posative(value);
				value = &realValue;
				break;

			case negative:
				realValue = this.op_negative(value);
				value = &realValue;
				break;

			case not:
				realValue = this.op_eval(value) ? booleanType.falseValue : booleanType.trueValue;
				value = &realValue;
				break;

			case bitwiseNot:
				realValue = this.op_bitNot(value);
				value = &realValue;
				break;

			case postIncrement:
				realValue = *value;
				this.op_increment(value);
				value = &realValue;
				break;

			case postDecrement:
				realValue = *value;
				this.op_decrement(value);
				value = &realValue;
				break;
		}
	}

	void visit(BinaryNode node) {
		Value lhs, rhs;

		node.lhs.accept(this);
		lhs = *value;

		node.rhs.accept(this);
		rhs = *value;

		final switch(node.operator) with(BinaryNode.Operator) {
			case multiply:
				realValue = this.op_multiply(&lhs, &rhs);
				break;

			case divide:
				realValue = this.op_divide(&lhs, &rhs);
				break;

			case modulo:
				realValue = this.op_modulo(&lhs, &rhs);
				break;

			case add:
				realValue = this.op_add(&lhs, &rhs);
				break;

			case subtract:
				realValue = this.op_subtract(&lhs, &rhs);
				break;

			case bitwiseShiftLeft:
				realValue = this.op_bitShiftLeft(&lhs, &rhs);
				break;

			case bitwiseShiftRight:
				realValue = this.op_bitShiftRight(&lhs, &rhs);
				break;

			case greaterThan:
				if (this.op_comp(&lhs, &rhs) > 0) realValue = booleanType.trueValue;
				else realValue = booleanType.falseValue;
				break;

			case lessThan:
				if (this.op_comp(&lhs, &rhs) < 0) realValue = booleanType.trueValue;
				else realValue = booleanType.falseValue;
				break;

			case greaterThanEqual: 
				if (this.op_comp(&lhs, &rhs) >= 0) realValue = booleanType.trueValue;
				else realValue = booleanType.falseValue;
				break;

			case lessThanEqual:
				if (this.op_comp(&lhs, &rhs) <= 0) realValue = booleanType.trueValue;
				else realValue = booleanType.falseValue;
				break;

			case bitwiseAnd:
				realValue = this.op_bitAnd(&lhs, &rhs);
				break;

			case bitwiseOr:
				realValue = this.op_bitOr(&lhs, &rhs);
				break;

			case bitwiseXor:
				realValue = this.op_bitXor(&lhs, &rhs);
				break;

			case and:
				realValue = this.op_eval(&lhs) && this.op_eval(&rhs) ? booleanType.trueValue : booleanType.falseValue;
				break;

			case or:
				realValue = this.op_eval(&lhs) || this.op_eval(&rhs) ? booleanType.trueValue : booleanType.falseValue;
				break;

			case xor:
				realValue = this.op_eval(&lhs) ^^ this.op_eval(&rhs) ? booleanType.trueValue : booleanType.falseValue;
				break;

			case slice:
				break;

			case concat:
				realValue = this.op_concat(&lhs, &rhs);
				break;

			case equal:
				realValue = this.op_equal(&lhs, &rhs) ? booleanType.trueValue : booleanType.falseValue;
				break;

			case notEqual:
				realValue = this.op_equal(&lhs, &rhs) ? booleanType.falseValue : booleanType.trueValue;
				break;
		}
		value = &realValue;
	}

	void visit(TinaryNode node) {
		node.subject.accept(this);
		if (this.op_eval(value)) node.lhs.accept(this);
		else node.rhs.accept(this);
	}

	void visit(FunctionCallNode node) {
		Value subject;
		Value[] arguments;

		node.subject.accept(this);
		subject = *value;

		arguments.reserve(node.arguments.length);
		foreach(argument; node.arguments) {
			argument.accept(this);
			arguments ~= *value;
		}

		realValue = this.op_call(&subject, arguments);
		value = &realValue;
	}

	void visit(NewNode node) {
		//Value type;
		//Value[] arguments;
		//
		//node.type.accept(this);
		//type = value;
		//
		//if (.types[type.typeID] != typeType) assert(0, "Attempted to new non-type");
		//
		//
		//arguments.reserve(node.arguments.length);
		//foreach(argument; arguments) {
		//	argument.accept(this);
		//	arguments ~= value;
		//}
		//
		//value = typeType.makeNew(&type, arguments);
	}

	void visit(AssignmentNode node) {
		Value* subject;
		Value argument;

		node.subject.accept(this);
		subject = value;

		node.argument.accept(this);
		argument = *value;

		final switch(node.operator) with (AssignmentNode.Operator) {
			case assign:
				*subject = argument;
				break;

			case concat:
				this.op_concatAssign(subject, &argument);
				break;

			case add:
				*subject = this.op_add(subject, &argument);
				break;

			case subtract:
				*subject = this.op_subtract(subject, &argument);
				break;

			case multiply:
				*subject = this.op_multiply(subject, &argument);
				break;

			case divide:
				*subject = this.op_divide(subject, &argument);
				break;

			case modulo:
				*subject = this.op_modulo(subject, &argument);
				break;

			case and:
				*subject = this.op_bitAnd(subject, &argument);
				break;

			case or:
				*subject = this.op_bitOr(subject, &argument);
				break;

			case xor:
				*subject = this.op_bitXor(subject, &argument);
				break;
		}
	}

	void visit(ArrayLiteralNode node) {
		Value[] arguments;

		arguments.reserve(node.value.length);
		foreach(argument; node.value) {
			argument.accept(this);
			arguments ~= *value;
		}

		realValue = arrayType.make(arguments);
		value = &realValue;
	}

	void visit(IntegerLiteralNode node) {
		realValue = integerType.make(node.value.to!int);
		value = &realValue;
	}

	void visit(FloatLiteralNode node) {
		realValue = floatType.make(node.value.to!float);
		value = &realValue;
	}

	void visit(StringLiteralNode node) {
		realValue = stringType.make(node.value);
		value = &realValue;
	}

	void visit(IdentifierNode node) {
		value = context.lookup(node.identifier);
	}

	void visit(DispatchNode node) {
		Value subject;

		node.subject.accept(this);
		subject = *value;

		value = this.op_dispatch(&subject, node.identifier);
	}

	void visit(SubscriptNode node) {
		Value subject;
		Value[] arguments;

		node.subject.accept(this);
		subject = *value;

		arguments.reserve(node.arguments.length);
		foreach(argument; node.arguments) {
			argument.accept(this);
			arguments ~= *value;
		}

		value = this.op_index(&subject, arguments);
	}
}

