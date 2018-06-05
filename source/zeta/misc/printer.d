/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.misc.printer;

import std.array : Appender;
import std.format : formattedWrite;
import zeta.parser.ast;

class ASTPrinter : ASTVisitor {
	Appender!string output;

	void acceptList(T)(T[] nodes, string delim, string start = null, string end = null) {
		output.put(start);
		foreach(i, node; nodes) {
			node.accept(this);
			if (i != nodes.length - 1) output.put(delim);
		}
		output.put(end);
	}

	void visit(ModuleNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		if (node.packageName !is null) output.formattedWrite("module %s.%s;\n", node.packageName, node.name);
		else output.formattedWrite("module %s;\n", node.name);
		acceptList(node.members, "\n");
	}

	void visit(ImportNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		if (node.packageName !is null) output.formattedWrite("import %s.%s;", node.packageName, node.name);
		else output.formattedWrite("import %s;", node.name);
	}

	void visit(DefNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.formattedWrite("def %s", node.name);
		if (node.initializer !is null) {
			output.put(" = ");
			node.initializer.accept(this);
		}
		output.put(";");
	}

	void visit(FunctionNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.formattedWrite("function %s", node.name);
		acceptList(node.paramaters, ", ", "(", ")");
		acceptList(node.members, "\n", " {\n", "\n}");
	}

	void visit(ClassNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.formattedWrite("class %s", node.name);
		if (node.inherits.length > 0) acceptList(node.inherits, ", ", " ");
		acceptList(node.members, "\n", " {\n", "\n}");
	}

	void visit(AttributeNode node) {
		output.formattedWrite("@%s", node.name);
		if (node.arguments !is null) acceptList(node.arguments, ", ", "(", ")");
	}

	void visit(FunctionParamaterNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put(node.name);
		if (node.initializer !is null) {
			output.put(" = ");
			node.initializer.accept(this);
		}
	}

	void visit(IfNode node) {
		output.put("if(");
		node.subject.accept(this);
		acceptList(node.members, "\n", ") {\n", "\n}");
		if (node.else_ !is null) {
			output.put(" ");
			node.else_.accept(this);
		}
	}
	
	void visit(ElseNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		acceptList(node.members, "\n", "else {\n", "\n}");
	}
	
	void visit(SwitchNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("switch(");
		node.subject.accept(this);
		acceptList(node.members, "\n", ") {\n", "\n}");
	}
	
	void visit(SwitchCaseNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("case");
		acceptList(node.arguments, ", ", "(", "):");
		acceptList(node.members, "\n", "", "");
	}
	
	void visit(ForNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("for(");
		if (node.initializer !is null) node.initializer.accept(this);
		output.put(";");
		if (node.subject !is null) node.subject.accept(this);
		output.put(";");
		if (node.step !is null) node.step.accept(this);
		acceptList(node.members, "\n", ") {\n", "\n}");
	}
	
	void visit(ForeachNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("foreach(");
		if (node.initializers !is null) acceptList(node.initializers, "", ";", ",");
		if (node.subject !is null) node.subject.accept(this);
		acceptList(node.members, "\n", ") {\n", "\n}");
	}
	
	void visit(WhileNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("while(");
		node.subject.accept(this);
		acceptList(node.members, "\n", ") {\n", "\n}");
	}
	
	void visit(WithNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("with(");
		node.subject.accept(this);
		acceptList(node.members, "\n", ") {\n", "\n}");
	}
	
	void visit(DoWhileNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("do");
		acceptList(node.members, "\n", "{\n", "} ");
		output.put("while(");
		node.subject.accept(this);
		output.put(");");
	}
	
	void visit(BreakNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("break;");
	}
	
	void visit(ContinueNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("continue;");
	}
	
	void visit(ReturnNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("return ");
		if (node.subject !is null) node.subject.accept(this);
		output.put(";");
	}
	
	void visit(ExpressionStatementNode node) {
		node.subject.accept(this);
		output.put(";");
	}

	void visit(UnaryNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		final switch(node.operator) with(UnaryNode.Operator) {
			case increment:
				output.put("++");
				node.subject.accept(this);
				break;
			case decrement:
				output.put("--");
				node.subject.accept(this);
				break;
			case posative:
				output.put("+");
				node.subject.accept(this);
				break;
			case negative:
				output.put("-");
				node.subject.accept(this);
				break;
			case not:
				output.put("!");
				node.subject.accept(this);
				break;
			case bitwiseNot:
				output.put("~");
				node.subject.accept(this);
				break;
			case postIncrement:
				node.subject.accept(this);
				output.put("++");
				break;
			case postDecrement:
				node.subject.accept(this);
				output.put("--");
				break;
		}
	}

	void visit(BinaryNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		node.lhs.accept(this);
		output.put(" ");
		final switch(node.operator) with(BinaryNode.Operator) {
			case multiply:
				output.put("*");
				break;
			case divide:
				output.put("/");
				break;
			case modulo:
				output.put("%");
				break;
			case add:
				output.put("+");
				break;
			case subtract:
				output.put("-");
				break;
			case bitwiseShiftLeft:
				output.put("<<");
				break;
			case bitwiseShiftRight:
				output.put(">>");
				break;
			case greaterThan: 
				output.put(">");
				break;
			case lessThan:
				output.put("<");
				break;
			case greaterThanEqual: 
				output.put(">=");
				break;
			case lessThanEqual:
				output.put("<=");
				break;
			case bitwiseAnd:
				output.put("&");
				break;
			case bitwiseOr:
				output.put("|");
				break;
			case bitwiseXor:
				output.put("^");
				break;
			case and:
				output.put("&&");
				break;
			case or:
				output.put("||");
				break;
			case xor:
				output.put("^^");
				break;
			case slice:
				output.put("..");
				break;
			case concat:
				output.put("~");
				break;
			case equal:
				output.put("==");
				break;
			case notEqual:
				output.put("!=");
				break;
		}
		output.put(" ");
		node.rhs.accept(this);
	}

	void visit(TinaryNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		node.subject.accept(this);
		output.put(" ? (");
		node.lhs.accept(this);
		output.put(") : (");
		node.rhs.accept(this);
		output.put(")");
	}

	void visit(FunctionCallNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		node.subject.accept(this);
		acceptList(node.arguments, ", ", "(", ")");
	}

	void visit(NewNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put("new:");
		node.type.accept(this);
		acceptList(node.arguments, ", ", "(", ")");
	}

	void visit(AssignmentNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		node.subject.accept(this);
		output.put(" ");
		final switch(node.operator) with (AssignmentNode.Operator) {
			case assign:
				output.put("=");
				break;
			case add:
				output.put("+=");
				break;
			case subtract:
				output.put("-=");
				break;
			case multiply:
				output.put("*=");
				break;
			case divide:
				output.put("/=");
				break;
			case modulo:
				output.put("%=");
				break;
			case concat:
				output.put("~=");
				break;
			case and:
				output.put("&=");
				break;
			case or:
				output.put("|=");
				break;
			case xor:
				output.put("^=");
				break;
		}
		output.put(" ");
		node.argument.accept(this);
	}

	void visit(ArrayLiteralNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		acceptList(node.value, ", ", "[", "]");
	}

	void visit(IntegerLiteralNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put(node.value);
	}

	void visit(FloatLiteralNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put(node.value);
	}

	void visit(StringLiteralNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.formattedWrite("`%s`", node.value); //TODO: implement string sanitization.
	}

	void visit(IdentifierNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		output.put(node.identifier);
	}

	void visit(DispatchNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		node.subject.accept(this);
		output.formattedWrite(".%s", node.identifier);
	}

	void visit(SubscriptNode node) {
		if (node.attributes !is null) acceptList(node.attributes, " ", "", " ");
		node.subject.accept(this);
		acceptList(node.arguments, ", ", "[", "]");
	}
}
