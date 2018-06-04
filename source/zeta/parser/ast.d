/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.parser.ast;

import zeta.parser.token;

mixin template Visitor(VisitorType) {
	override void accept(VisitorType visitor) {
		visitor.visit(this);
	}
}

abstract class ASTNode {
	AttributeNode[] attributes;
	SourceLocation location;
	ASTNode parent;

	abstract void accept(ASTVisitor);
}

abstract class StatementNode : ASTNode {
}

abstract class DeclarationNode : StatementNode {
	string name;

	override string toString() {
		return name ~ "[" ~ location.toString() ~ "]";
	}
}

abstract class ExpressionNode : ASTNode {
}

abstract class ReferenceNode : ExpressionNode {
}

interface ASTVisitor {
	void visit(ModuleNode);
	void visit(ImportNode);
	void visit(DefNode);
	void visit(FunctionNode);
	void visit(ClassNode);
	void visit(AttributeNode);
	void visit(FunctionParamaterNode);
	void visit(IfNode);
	void visit(ElseNode);
	void visit(SwitchNode);
	void visit(SwitchCaseNode);
	void visit(ForNode);
	void visit(ForeachNode);
	void visit(WhileNode);
	void visit(WithNode);
	void visit(DoWhileNode);
	void visit(BreakNode);
	void visit(ContinueNode);
	void visit(ReturnNode);
	void visit(ExpressionStatementNode);
	void visit(UnaryNode);
	void visit(BinaryNode);
	void visit(TinaryNode);
	void visit(FunctionCallNode);
	void visit(NewNode);
	void visit(AssignmentNode);
	void visit(ArrayLiteralNode);
	void visit(IntegerLiteralNode);
	void visit(FloatLiteralNode);
	void visit(StringLiteralNode);
	void visit(IdentifierNode);
	void visit(DispatchNode);
	void visit(SubscriptNode);
}

class ModuleNode : DeclarationNode {
	string packageName;
	DeclarationNode[] members;

	mixin Visitor!(ASTVisitor);
}

class ImportNode : DeclarationNode {
	string packageName;
	
	mixin Visitor!(ASTVisitor);
}

class DefNode : DeclarationNode {
	ExpressionNode initializer;

	mixin Visitor!(ASTVisitor);
}

class FunctionNode : DeclarationNode {
	FunctionParamaterNode[] paramaters;
	StatementNode[] members;

	mixin Visitor!(ASTVisitor);
}
class ClassNode : DeclarationNode {
	DeclarationNode[] members;
	ReferenceNode[] inherits;

	mixin Visitor!(ASTVisitor);
}

class AttributeNode : DeclarationNode {
	ExpressionNode[] arguments;

	mixin Visitor!(ASTVisitor);
}

class FunctionParamaterNode : DeclarationNode {
	ExpressionNode initializer;

	mixin Visitor!(ASTVisitor);
}

class IfNode : StatementNode {
	ExpressionNode subject;
	StatementNode[] members;
	ElseNode else_;

	mixin Visitor!(ASTVisitor);
}

class ElseNode : StatementNode {
	StatementNode[] members;

	mixin Visitor!(ASTVisitor);
}

class SwitchNode : StatementNode {
	ExpressionNode subject;
	SwitchCaseNode[] members;

	mixin Visitor!(ASTVisitor);
}

class SwitchCaseNode : StatementNode {
	ExpressionNode[] arguments;
	StatementNode[] members;
	bool isElseCase;

	mixin Visitor!(ASTVisitor);
}

class ForNode : StatementNode {
	DefNode initializer;
	ExpressionNode subject;
	ExpressionNode step;
	StatementNode[] members;

	mixin Visitor!(ASTVisitor);
}

class ForeachNode : StatementNode {
	DefNode[] initializers;
	ExpressionNode subject;
	StatementNode[] members;

	mixin Visitor!(ASTVisitor);
}

class WhileNode : StatementNode {
	ExpressionNode subject;
	StatementNode[] members;

	mixin Visitor!(ASTVisitor);
}
class WithNode : StatementNode {
	ExpressionNode subject;
	StatementNode[] members;

	mixin Visitor!(ASTVisitor);
}

class DoWhileNode : StatementNode {
	ExpressionNode subject;
	StatementNode[] members;

	mixin Visitor!(ASTVisitor);
}

class BreakNode : StatementNode {
	ASTNode subject;

	mixin Visitor!(ASTVisitor);
}

class ContinueNode : StatementNode {
	ASTNode subject;

	mixin Visitor!(ASTVisitor);
}

class ReturnNode : StatementNode {
	ExpressionNode subject;

	mixin Visitor!(ASTVisitor);
}

class ExpressionStatementNode : StatementNode {
	ExpressionNode subject;

	mixin Visitor!(ASTVisitor);
}

class UnaryNode : ExpressionNode {
	enum Operator:int {
		increment = TokenType.tk_increment, 
		decrement = TokenType.tk_decrement,
		posative = TokenType.tk_plus,
		negative = TokenType.tk_minus,
		not = TokenType.tk_not, 
		bitwiseNot = TokenType.tk_tilde, 
		postIncrement = 75, 
		postDecrement = 76
	}

	Operator operator;
	ExpressionNode subject;

	mixin Visitor!(ASTVisitor);
}

class BinaryNode : ExpressionNode {
	enum Operator {
		add = TokenType.tk_plus, 
		subtract = TokenType.tk_minus, 
		multiply = TokenType.tk_asterick, 
		divide = TokenType.tk_slash, 
		modulo = TokenType.tk_percent, 
		concat = TokenType.tk_tilde, 
		equal = TokenType.tk_equal, 
		notEqual = TokenType.tk_notEqual, 
		lessThan = TokenType.tk_lessThan, 
		greaterThan = TokenType.tk_greaterThan, 
		lessThanEqual = TokenType.tk_lessThanEqual, 
		greaterThanEqual = TokenType.tk_greaterThanEqual, 
		and = TokenType.tk_logicalAnd, 
		or = TokenType.tk_logicalOr, 
		xor = TokenType.tk_logicalXor, 
		bitwiseAnd = TokenType.tk_ampersand, 
		bitwiseOr = TokenType.tk_poll, 
		bitwiseXor = TokenType.tk_hash,
		bitwiseShiftLeft = TokenType.tk_shiftLeft, 
		bitwiseShiftRight = TokenType.tk_shiftRight,
		slice = TokenType.tk_slice
	}

	Operator operator;
	ExpressionNode lhs, rhs;

	mixin Visitor!(ASTVisitor);
}

class TinaryNode : ExpressionNode {
	ExpressionNode subject;
	ExpressionNode lhs, rhs;

	mixin Visitor!(ASTVisitor);
}

class FunctionCallNode : ExpressionNode {
	ExpressionNode subject;
	ExpressionNode[] arguments;

	mixin Visitor!(ASTVisitor);
}



class SubscriptNode : ExpressionNode {
	ExpressionNode subject;
	ExpressionNode[] arguments;


	mixin Visitor!(ASTVisitor);
}

class NewNode : ExpressionNode {
	ReferenceNode type;
	ExpressionNode[] arguments;

	mixin Visitor!(ASTVisitor);
}

class AssignmentNode : ExpressionNode {
	enum Operator { 
		assign = TokenType.tk_assign, 
		add = TokenType.tk_assignAdd, 
		subtract = TokenType.tk_assignSubtract, 
		multiply = TokenType.tk_assignMultiply, 
		divide = TokenType.tk_assignDivide, 
		modulo = TokenType.tk_assignModulo, 
		concat = TokenType.tk_assignConcat, 
		and = TokenType.tk_assignAnd, 
		or = TokenType.tk_assignOr, 
		xor = TokenType.tk_assignXor
	}

	Operator operator;
	ExpressionNode subject;
	ExpressionNode argument;

	mixin Visitor!(ASTVisitor);
}

class ArrayLiteralNode : ExpressionNode {
	ExpressionNode[] value;

	mixin Visitor!(ASTVisitor);
}

class IntegerLiteralNode : ExpressionNode {
	string value;

	mixin Visitor!(ASTVisitor);
}

class FloatLiteralNode : ExpressionNode {
	string value;

	mixin Visitor!(ASTVisitor);
}

class StringLiteralNode : ExpressionNode {
	string value;

	mixin Visitor!(ASTVisitor);
}

class IdentifierNode : ReferenceNode {
	string identifier;

	mixin Visitor!(ASTVisitor);
}

class DispatchNode : ReferenceNode {
	ExpressionNode subject;
	string identifier;

	mixin Visitor!(ASTVisitor);
}
