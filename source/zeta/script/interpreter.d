module zeta.script.interpreter;

import std.algorithm;
import std.array;
import std.container.slist;
import zeta.utils;
import zeta.parse.ast;
import zeta.script.variable;
import zeta.script.scope_;

class ZtInterpreter {
    mixin(MultiDispatch!`evaluate`);
    mixin(MultiDispatch!`execute`);
	SList!ZtScope stack;
	Variable returnValue;
	bool isReturning;
	ubyte breakLevel, continueLevel;
	ZtScope[string] modules;

	this() {
		stack.insertFront(new ZtScope);
	}

	void addNative(BuiltinDelegate dg) {
		self.define(dg.name, dg);
	}

	ZtScope doModule(ZtAstModule node) {
		auto moduleScope = new ZtScope(self);
		stack.insertFront(moduleScope);
		execute(cast(ZtAstStatement[])node.members);
		stack.removeFront();
		modules[(node.packageName ~ node.name).join(".")] = moduleScope;
		return moduleScope;
	}

	@property ZtScope self() { return stack.front; }

	void execute(ZtAstStatement[] members) { 
		foreach(member; members) {
			execute(member);
			if (isReturning || breakLevel || continueLevel) return;
		}
	}

	void execute(ZtAstDef node) { 
		self.define(node.name, evaluate(node.initializer));
	}

	void execute(ZtAstImport node) { 
		assert(0, "Not implemented!");
	}

	void execute(ZtAstFunction node) { 
		self.define(node.name, new Delegate(node, self, this));
	}

	void execute(ZtAstIf node) { 
		stack.insertFront(new ZtScope(self));
		if (evaluate(node.subject).eval) execute(node.members);
		else execute(node.elseMembers);
		stack.removeFront();
	}

	void execute(ZtAstSwitch node) { 
		stack.insertFront(new ZtScope(self));
		auto cond = evaluate(node.subject);
		bool isFallthrough = false;
		size_t elseCaseId;
		for(size_t i = 0; i < node.members.length; i++) {
			if (node.members[i].isElseCase) elseCaseId = i;
			auto matches = node.members[i].subjects.any!((exp) => evaluate(exp).equals(cond));
			if(matches || isFallthrough) {
				execute(node.members[i].members);
				if (isReturning) return;
				if (breakLevel > 0) { stack.removeFront(); breakLevel--; return; }
				if (continueLevel > 1) { stack.removeFront(); continueLevel--; return; }
				if (continueLevel == 1) { stack.removeFront(); continueLevel--; isFallthrough = false; }
				isFallthrough = true;
			}
			if (i+1 == node.members.length && !isFallthrough && elseCaseId != 0) {i = elseCaseId-1; isFallthrough = true; continue; }
		}
		stack.removeFront();
	}

	void execute(ZtAstWhile node) { 
		stack.insertFront(new ZtScope(self));
		while(evaluate(node.subject).eval) {
			stack.insertFront(new ZtScope(self));
			execute(node.members);
			if (breakLevel > 0) { stack.removeFront(); breakLevel--; return; }
			if (continueLevel > 1) { stack.removeFront(); continueLevel--; return; }
			if (continueLevel == 1) { stack.removeFront(); continueLevel--; continue; }
			stack.removeFront();
		}
	}

	void execute(ZtAstDoWhile node) { 
		do {
			stack.insertFront(new ZtScope(self));
			execute(node.members);
			if (breakLevel > 0) { stack.removeFront(); breakLevel--; return; }
			if (continueLevel > 1) { stack.removeFront(); continueLevel--; return; }
			if (continueLevel == 1) { stack.removeFront(); continueLevel--; continue; }
			stack.removeFront();
		} while(evaluate(node.subject).eval);
	}

	void execute(ZtAstFor node) { 
		stack.insertFront(new ZtScope(self));
		execute(node.initializer);
		for(; evaluate(node.subject).eval; evaluate(node.step)) {
			stack.insertFront(new ZtScope(self));
			execute(node.members);
			if (breakLevel > 0) { stack.removeFront(2); breakLevel--; return; }
			if (continueLevel > 1) { stack.removeFront(2); continueLevel--; return; }
			if (continueLevel == 1) { stack.removeFront(2); continueLevel--; continue; }
			stack.removeFront();
		}
		stack.removeFront();
	}

	void execute(ZtAstForeach node) { 
		assert(0, "Not implemented!");
	}

	void execute(ZtAstWith node) { 
		assert(0, "Not implemented!");
	}

	void execute(ZtAstReturn node) { 
		returnValue = evaluate(node.subject);
		isReturning = true;
	}

	void execute(ZtAstBreak node) { 
		breakLevel++;
	}

	void execute(ZtAstContinue node) { 
		continueLevel++;
	}

	void execute(ZtAstExpressionStatement node) { 
		evaluate(node.subject);
	}

	Variable evaluate(ZtAstIdentifier node) { 
		return self.get(node.name);
	}

	Variable evaluate(ZtAstDispatch node) { 
		return evaluate(node.subject).dispatchGet(node.name);
	}

	Variable evaluate(ZtAstSubscript node) { 
		return evaluate(node.subject).index(evaluate(node.arguments[0]));
	}

	Variable evaluate(ZtAstBinary node) { 
		with(ZtAstBinary.Operator) switch(node.operator) {
			case add: return evaluate(node.lhs).add(evaluate(node.rhs));
			case subtract: return evaluate(node.lhs).sub(evaluate(node.rhs));
			case multiply: return evaluate(node.lhs).mul(evaluate(node.rhs));
			case divide: return evaluate(node.lhs).div(evaluate(node.rhs));
			case modulo: return evaluate(node.lhs).mod(evaluate(node.rhs));
			case concat: return evaluate(node.lhs).concat(evaluate(node.rhs));
			case equal: return new Bool(evaluate(node.lhs).equals(evaluate(node.rhs)));
			case notEqual: return new Bool(!evaluate(node.lhs).equals(evaluate(node.rhs)));
			case lessThan: return new Bool(evaluate(node.lhs).less(evaluate(node.rhs)));
			case greaterThan: return new Bool(evaluate(node.lhs).greater(evaluate(node.rhs)));
			case lessThanEqual: return new Bool(evaluate(node.lhs).equals(evaluate(node.rhs)) || evaluate(node.lhs).less(evaluate(node.rhs)));
			case greaterThanEqual: return new Bool(evaluate(node.lhs).equals(evaluate(node.rhs)) || evaluate(node.lhs).greater(evaluate(node.rhs)));
			case and: return new Bool(evaluate(node.lhs).eval && evaluate(node.rhs).eval);
			case or: return new Bool(evaluate(node.lhs).eval || evaluate(node.rhs).eval);
			case xor: return new Bool(evaluate(node.lhs).eval != evaluate(node.rhs).eval);
			default: assert(0, "Not implemented!");
		}
	}

	Variable evaluate(ZtAstUnary node) { 
		 with(ZtAstUnary.Operator) switch(node.operator) {
			case increment: auto v = evaluate(node.subject); v.inc(); return v;
			case decrement: auto v = evaluate(node.subject); v.dec(); return v;
			case positive: return evaluate(node.subject).pos;
			case negative: return evaluate(node.subject).neg;
			case not: return new Bool(!evaluate(node.subject).eval);
			case postIncrement: auto v = evaluate(node.subject); auto u = v.refOf; v.inc(); return u;
			case postDecrement: auto v = evaluate(node.subject); auto u = v.refOf; v.dec(); return u;
			default: assert(0, "Not implemented!");
		}
	}

	Variable evaluate(ZtAstTrinaryOperator node) { 
		return evaluate(node.subject) ? evaluate(node.lhs) : evaluate(node.rhs);
	}

	Variable evaluate(ZtAstAssign node) { 
		if (auto identifier = cast(ZtAstIdentifier)node.subject) {
			auto v = evaluate(node.assignment);
			self.set(identifier.name, v);
			return v.refOf;
		} else if (auto dispatch = cast(ZtAstDispatch)node.subject) {
			auto u = evaluate(dispatch.subject);
			auto v = evaluate(node.assignment);
			u.dispatchSet(dispatch.name, v);
			return v.refOf;
		} else if (auto subscript = cast(ZtAstSubscript)node.subject) {
			auto u = evaluate(subscript.subject);
			auto v = evaluate(node.assignment);
			u.index(evaluate(subscript.arguments[0]), v);
			return v.refOf;
		}
		assert(0, "Not implemented!");
	}

	Variable evaluate(ZtAstCall node) { 
		auto fun = evaluate(node.subject);
		auto args = node.arguments.map!((n) => evaluate(n))().array;
		return fun.call(args);
	}

	Variable evaluate(ZtAstApply node) { 
		auto lhs = evaluate(node.subject);
		if (lhs != nullValue) return lhs.dispatchGet(node.name);
		else return nullValue;
	}

	Variable evaluate(ZtAstCast node) { 
		assert(0, "Not implemented!");
	}

	Variable evaluate(ZtAstIs node) { 
		return new Bool(evaluate(node.lhs).type == evaluate(node.rhs).type);
	}

	Variable evaluate(ZtAstNew node) { 
		assert(0, "Not implemented!");
	}

	Variable evaluate(ZtAstArray node) { 
		auto array = new Array();
		foreach(member; node.members) array.array ~= evaluate(member);
		return array;
	}

	Variable evaluate(ZtAstString node) { 
		return new String(node.literal);
	}

	Variable evaluate(ZtAstChar node) { 
		return new String(cast(char[])[node.literal]);
	}

	Variable evaluate(ZtAstInteger node) { 
		return new Integer(node.literal);
	}

	Variable evaluate(ZtAstFloat node) { 
		return new Float(node.literal);
	}
}