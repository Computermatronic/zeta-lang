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
import zeta.runtime;

class Interpreter : ASTVisitor {
	Runtime runtime;

	bool shouldReturn;
	int continueCount, breakCount;

	Value realValue;
	Value* value;

	void pushScope() {
		scopeBlock = new ScopeBlock(scopeBlock);
	}

	void popScope() {
		scopeBlock = scopeBlock.outer;
	}

	Value executeFunction(FunctionNode node, Value[] arguments) {
		Value result = runtime.nullValue;
		pushScope();
		for(size_t i; i < node.paramaters.length; i++) {
			if (i < arguments.length) {
				scopeBlock.define(node.paramaters[i].name, arguments[i]);
			} else if (node.paramaters[i].initializer !is null) {
				node.paramaters[i[.initializer.accept(this);
				scopeBlock.define(node.paramaters[i].name, *value);
			} else {
				scopeBlock.define(node.paramaters[i].name, runtime.nullValue);
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
		popScope();
		return result;
	}

	void visit(ModuleNode node) {
		//foreach(member; node.members) {
		//	member.accept(this);
		//}
	}

	void visit(ImportNode node) {
	}

	void visit(DefNode node) {
		if (node.initializer !is null) {
			node.initializer.accept(this);
			scopeBlock.define(node.name, *value);
		} else {
			scopeBlock.define(node.name, runtime.nullValue);
		}
	}

	void visit(FunctionNode node) {
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
			else if (continueCount == 1) {
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
		if (node.subject !is null) node.subject.accept(this);
		if (node.step !is null) node.step.accept(this);
		foreach(member; node.members) {
			member.accept(this);
		foreach(member; node.members) {
			member.accept(this);
			if (shouldReturn) return;
			else if (continueCount > 1) {
				continueCount--;
				break;
			else if (continueCount == 1) {
				continueCount --;
				continue;
			} else if (breakCount > 0) {
				breakCount--;
				break;
			}
		}
	}

	void visit(ForeachNode node) {
		foreach(initializer; node.initializers) {
			initializer.accept(this);
		}
		if (node.subject !is null) node.subject.accept(this);
		foreach(member; node.members) {
			member.accept(this);
		foreach(member; node.members) {
			member.accept(this);


			if (shouldReturn) return;
			else if (continueCount > 1) {
				continueCount--;
				break;
			else if (continueCount == 1) {
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
		foreach(member; node.members) {
			member.accept(this);


			if (shouldReturn) return;
			else if (continueCount > 1) {
				continueCount--;
				break;
			else if (continueCount == 1) {
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
			else if (continueCount == 1) {
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
			breakCount = runtime.op_cast(value, integerType).int_;
		} else breakCount++;
	}

	void visit(ContinueNode node) {

		if (node.subject !is null) {
			node.subject.accept(this);
			continueCount = runtime.op_cast(value, integerType).int_;
		} else continueCount++;
	}

	void visit(ReturnNode node) {
		if (node.subject !is null) node.subject.accept(this);
		else {
			realValue = runtime.nullValue;
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
				runtime.op_increment(value);
				break;

			case decrement:
				runtime.op_decrement(value);
				break;

			case posative:
				realValue = runtime.op_posative(value);
				value = &realValue;
				break;

			case negative:
				realValue = runtime.op_negative(value);
				value = &realValue;
				break;

			case not:
				realValue = runtime.op_eval(value) ? runtime.falseValue : runtime.trueValue;
				value = &realValue;
				break;

			case bitwiseNot:
				realValue = runtime.op_bitNot(value);
				value = &realValue;
				break;

			case postIncrement:
				realValue = *value;
				runtime.op_increment(value);
				value = &realValue;
				break;

			case postDecrement:
				realValue = *value;
				runtime.op_decrement(value);
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
				realValue = runtime.op_multiply(&lhs, &rhs);
				break;

			case divide:
				realValue = runtime.op_divide(&lhs, &rhs);
				break;

			case modulo:
				realValue = runtime.op_modulo(&lhs, &rhs);
				break;

			case add:
				realValue = runtime.op_add(&lhs, &rhs);
				break;

			case subtract:
				realValue = runtime.op_subtract(&lhs, &rhs);
				break;

			case bitwiseShiftLeft:
				realValue = runtime.op_bitShiftLeft(&lhs, &rhs);
				break;

			case bitwiseShiftRight:
				realValue = runtime.op_bitShiftRight(&lhs, &rhs);
				break;

			case greaterThan:
				if (runtime.op_comp(&lhs, &rhs) > 0) realValue = runtime.trueValue;
				else realValue = runtime.falseValue;
				break;

			case lessThan:
				if (runtime.op_comp(&lhs, &rhs) < 0) realValue = runtime.trueValue;
				else realValue = runtime.falseValue;
				break;

			case greaterThanEqual: 
				if (runtime.op_comp(&lhs, &rhs) >= 0) realValue = runtime.trueValue;
				else realValue = runtime.falseValue;
				break;

			case lessThanEqual:
				if (runtime.op_comp(&lhs, &rhs) <= 0) realValue = runtime.trueValue;
				else realValue = runtime.falseValue;
				break;

			case bitwiseAnd:
				realValue = runtime.op_bitAnd(&lhs, &rhs);
				break;

			case bitwiseOr:
				realValue = runtime.op_bitOr(&lhs, &rhs);
				break;

			case bitwiseXor:
				realValue = runtime.op_bitXor(&lhs, &rhs);
				break;

			case and:
				realValue = runtime.op_eval(&lhs) && runtime.op_eval(&rhs) ? runtime.trueValue : runtime.falseValue;
				break;

			case or:
				realValue = runtime.op_eval(&lhs) || runtime.op_eval(&rhs) ? runtime.trueValue : runtime.falseValue;
				break;

			case xor:
				realValue = runtime.op_eval(&lhs) ^^ runtime.op_eval(&rhs) ? runtime.trueValue : runtime.falseValue;
				break;

			case slice:
				break;

			case concat:
				realValue = runtime.op_concat(&lhs, &rhs);
				break;

			case equal:
				realValue = runtime.op_equal(&lhs, &rhs) ? runtime.trueValue : runtime.falseValue;
				break;

			case notEqual:
				realValue = runtime.op_equal(&lhs, &rhs) ? runtime.falseValue : runtime.trueValue;
				break;
		}
		value = &realValue;
	}

	void visit(TinaryNode node) {
		node.subject.accept(this);
		if (runtime.op_eval(value)) node.lhs.accept(this);
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

		realValue = runtime.op_call(&subject, arguments);
		value = &realValue;
	}

	void visit(NewNode node) {
		//Value type;
		//Value[] arguments;
		//
		//node.type.accept(this);
		//type = value;
		//
		//if (runtime.types[type.typeID] != typeType) assert(0, "Attempted to new non-type");
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
				runtime.op_concatAssign(subject, &argument);
				break;

			case add:
				*subject = runtime.op_add(subject, &argument);
				break;

			case subtract:
				*subject = runtime.op_subtract(subject, &argument);
				break;

			case multiply:
				*subject = runtime.op_multiply(subject, &argument);
				break;

			case divide:
				*subject = runtime.op_divide(subject, &argument);
				break;

			case modulo:
				*subject = runtime.op_modulo(subject, &argument);
				break;

			case and:
				*subject = runtime.op_bitAnd(subject, &argument);
				break;

			case or:
				*subject = runtime.op_bitOr(subject, &argument);
				break;

			case xor:
				*subject = runtime.op_bitXor(subject, &argument);
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
		value = scopeBlock.lookup(node.identifier);
	}

	void visit(DispatchNode node) {
		Value subject;

		node.subject.accept(this);
		subject = *value;

		value = runtime.op_dispatch(&subject, node.identifier);
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

		value = runtime.op_index(&subject, arguments);
	}
}

