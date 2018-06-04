/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.parser.parser;

import std.traits : ReturnType;
import std.container : DList;
import std.string : join;
import std.format : format;
import zeta.parser.ast;
import zeta.parser.token;

ModuleNode parseTokens(Token[] tokens) {
	auto state = new ParserState(tokens);
	state.parseAttributes();
	return state.parseModule();
}

ModuleNode parseModule(ParserState state) {
	auto node = new ModuleNode;
	node.location = state.front.location;
	if (state.popTestToken(TokenType.kw_module)) {
		node.attributes = state.attributes;
		state.attributes = null;
		auto nameInfo = state.parseList!((ParserState state) => state.expectToken(TokenType.ud_identifier).text)(TokenType.tk_dot);
		node.packageName = nameInfo.length > 1 ? nameInfo[0..$-1].join('.') : null;
		node.name = nameInfo[$-1];
		state.expectToken(TokenType.tk_semicolon);
	} else {
		import std.path : baseName, stripExtension;
		node.name = state.front.location.file.baseName().stripExtension();
	}
	state.pushNode(node);
	do {
		node.members ~= state.parseDeclaration();
	} while (!state.empty);
	return node;
}

ImportNode parseImport(ParserState state) {
	auto node = state.makeNode!ImportNode();
	auto nameInfo = state.parseList!((ParserState state) => state.expectToken(TokenType.ud_identifier).text)(TokenType.tk_dot);
	node.packageName = nameInfo.length > 1 ? nameInfo[0..$-1].join('.') : null;
	node.name = nameInfo[$-1];
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

DefNode parseDef(ParserState state) {
	auto node = state.makeNode!DefNode();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.popTestToken(TokenType.tk_assign)) node.initializer = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

FunctionNode parseFunction(ParserState state) {
	auto node = state.makeNode!FunctionNode();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	node.paramaters = state.parseList!(parseFunctionParamater)(TokenType.tk_leftParen, TokenType.tk_rightParen);
	if (!state.popTestToken(TokenType.tk_semicolon)) node.members = state.parseBlock!(parseStatement)();
	return node;
}

FunctionParamaterNode parseFunctionParamater(ParserState state) {
	auto node = state.makeNode!FunctionParamaterNode(false);
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.popTestToken(TokenType.tk_assign)) node.initializer = state.parseExpression();
	return node;
}

ClassNode parseClass(ParserState state) {
	auto node = state.makeNode!ClassNode();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.popTestToken(TokenType.tk_colon)) node.inherits = state.parseList!parseReference(TokenType.tk_comma);
	if (!state.popTestToken(TokenType.tk_semicolon)) node.members = state.parseBlock!(parseDeclaration)();
	return node;
}

IfNode parseIf(ParserState state) {
	auto node = state.makeNode!IfNode();
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!(parseStatement)();
	if (state.testToken(TokenType.kw_else)) node.else_ = state.parseElse();
	return node;
}

ElseNode parseElse(ParserState state) {
	auto node = state.makeNode!ElseNode();
	node.members = state.parseBlock!(parseStatement)();
	return node;
}

SwitchNode parseSwitch(ParserState state) {
	auto node = state.makeNode!SwitchNode();
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!(parseSwitchCase)();
	return node;
}

SwitchCaseNode parseSwitchCase(ParserState state) {
	auto node = state.makeNode!SwitchCaseNode();
	if (state.popTestToken(TokenType.kw_else)) node.isElseCase = true;
	else node.arguments = state.parseList!(parseExpression)(TokenType.tk_leftParen, TokenType.tk_rightParen);
	state.expectToken(TokenType.tk_colon);
	while(!state.testToken(TokenType.kw_case) && !state.testToken(TokenType.tk_rightBrace)) {
		node.members ~= state.parseBlock!(parseStatement)();
	}
	return node;
}

ForNode parseFor(ParserState state) {
	auto node = state.makeNode!ForNode();
	state.expectToken(TokenType.tk_leftParen);
	if (state.testToken(TokenType.kw_def)) node.initializer = state.parseDef();
	else state.expectToken(TokenType.tk_semicolon);
	if (!state.testToken(TokenType.tk_semicolon)) node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	if (!state.testToken(TokenType.tk_leftParen)) node.step = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!(parseStatement)();
	return node;
}

ForeachNode parseForeach(ParserState state) {
	auto node = state.makeNode!ForeachNode();
	state.expectToken(TokenType.tk_leftParen);
	node.initializers = state.parseList!(parseDef)(TokenType.tk_comma);
	state.expectToken(TokenType.tk_semicolon);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!(parseStatement)();
	return node;
}

WhileNode parseWhile(ParserState state) {
	auto node = state.makeNode!WhileNode();
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!(parseStatement)();
	return node;
}

WithNode parseWith(ParserState state) {
	auto node = state.makeNode!WithNode();
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!(parseStatement)();
	return node;
}

DoWhileNode parseDoWhile(ParserState state) {
	auto node = state.makeNode!DoWhileNode();
	node.members = state.parseBlock!(parseStatement)();
	state.expectToken(TokenType.kw_while);
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	return node;
}

BreakNode parseBreak(ParserState state) {
	auto node = state.makeNode!BreakNode();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ContinueNode parseContinue(ParserState state) {
	auto node = state.makeNode!ContinueNode();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ReturnNode parseReturn(ParserState state) {
	auto node = state.makeNode!ReturnNode();
	if (!state.popTestToken(TokenType.tk_semicolon)) {
		node.subject = state.parseExpression();
		state.expectToken(TokenType.tk_semicolon);
	}
	return node;
}

DeclarationNode parseDeclaration(ParserState state) {
	doNextNode: switch(state.front.type) with(TokenType) {
		case kw_import: return state.parseImport();
		case kw_class: return state.parseClass();
		case kw_function: return state.parseFunction();
		case kw_def: return state.parseDef();
		case tk_at: state.parseAttributes(); goto doNextNode;
		default: throw new ParserException(format("Unrecognized declaration %s.", state.front.text), state.front.location);
	}
}

StatementNode parseStatement(ParserState state) {
	doNextNode: switch(state.front.type) with(TokenType) {
		case kw_import: return state.parseImport();
		case kw_class: return state.parseClass();
		case kw_function: return state.parseFunction();
		case kw_def: return state.parseDef();
		case kw_if: return state.parseIf();
		case tk_at: state.parseAttributes(); goto doNextNode;
		case kw_while: return state.parseWhile();
		case kw_with: return state.parseWith();
		case kw_do: return state.parseDoWhile();
		case kw_for: return state.parseFor();
		case kw_foreach: return state.parseForeach();
		case kw_switch: return state.parseSwitch();
		case kw_break: return state.parseBreak();
		case kw_continue: return state.parseContinue();
		case kw_return: return state.parseReturn();
		default: 
			auto node = state.makeNode!ExpressionStatementNode(false);
			node.subject = state.parseExpression();
			state.expectToken(TokenType.tk_semicolon);
			return node;
	}
}

ExpressionNode parseExpression(ParserState state, OperatorPrecedence precedence = OperatorPrecedence.max) {
	ExpressionNode expression;

	nextExpression: switch(state.front.type) with(TokenType) {
		case ud_identifier:
			auto node = state.makeNode!IdentifierNode(false);
			node.identifier = state.popFront().text;
			expression = node;
			break;
		case ud_string:
			auto node = state.makeNode!StringLiteralNode(false);
			node.value = state.popFront().text;
			expression = node;
			break;
		case ud_integer:
			auto node = state.makeNode!IntegerLiteralNode(false);
			node.value = state.popFront().text;
			expression = node;
			break;
		case ud_float:
			auto node = state.makeNode!FloatLiteralNode(false);
			node.value = state.popFront().text;
			expression = node;
			break;
		case tk_leftBracket:
			auto node = state.makeNode!ArrayLiteralNode(false);
			node.value = state.parseList!(parseExpression)(TokenType.tk_leftBracket, TokenType.tk_rightBracket);
			expression = node;
			break;
		case tk_increment, tk_decrement:
			auto node = state.makeNode!UnaryNode(false);
			node.operator = cast(UnaryNode.Operator)state.popFront().type;
			node.subject = state.parseExpression(OperatorPrecedence.unary1);
			expression = node;
			break;
		case tk_plus, tk_minus:
			auto node = state.makeNode!UnaryNode(false);
			node.operator = cast(UnaryNode.Operator)state.popFront().type;
			node.subject = state.parseExpression(OperatorPrecedence.unary2);
			expression = node;
			break;
		case tk_not, tk_tilde:
			auto node = state.makeNode!UnaryNode(false);
			node.operator = cast(UnaryNode.Operator)state.popFront().type;
			node.subject = state.parseExpression(OperatorPrecedence.unary3);
			expression = node;
			break;
		case kw_new:
			auto node = state.makeNode!NewNode();
			state.expectToken(TokenType.tk_colon);
			node.type = state.parseReference(OperatorPrecedence.resolution2);
			node.arguments = state.parseList!(parseExpression)(TokenType.tk_leftParen, TokenType.tk_rightParen);
			expression = node;
			break;
		case tk_at:
			state.parseAttributes();
			goto nextExpression;
		default:
			throw new ParserException(format("Unrecognized expresssion %s", state.front.text), state.front.location);
	}

	nextSubExpression: switch(state.front.type) with(TokenType) {
		case tk_asterick, tk_slash, tk_power, tk_percent:
			if (OperatorPrecedence.arithmatic1 > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.arithmatic1);
			expression = node;
			goto nextSubExpression;
		case tk_greaterThan, tk_lessThan, tk_greaterThanEqual, tk_lessThanEqual:
			if (OperatorPrecedence.relational > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.relational);
			expression = node;
			goto nextSubExpression;
		case tk_equal, tk_notEqual:
			if (OperatorPrecedence.equity > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.equity);
			expression = node;
			goto nextSubExpression;
		case tk_shiftLeft, tk_shiftRight:
			if (OperatorPrecedence.binaryShift > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.binaryShift);
			expression = node;
			goto nextSubExpression;
		case tk_tilde, tk_slice:
			if (OperatorPrecedence.range > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.range);
			expression = node;
			goto nextSubExpression;
		case tk_plus, tk_minus:
			if (OperatorPrecedence.arithmatic2 > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.arithmatic2);
			expression = node;
			goto nextSubExpression;
		case tk_ampersand:
			if (OperatorPrecedence.binaryAnd > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.binaryAnd);
			expression = node;
			goto nextSubExpression;
		case tk_poll:
			if (OperatorPrecedence.binaryOr > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.binaryOr);
			expression = node;
			goto nextSubExpression;
		case tk_hash:
			if (OperatorPrecedence.binaryXor > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.binaryXor);
			expression = node;
			goto nextSubExpression;
		case tk_logicalAnd:
			if (OperatorPrecedence.logicalAnd > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.logicalAnd);
			expression = node;
			goto nextSubExpression;
		case tk_logicalOr:
			if (OperatorPrecedence.logicalOr > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.logicalOr);
			expression = node;
			goto nextSubExpression;
		case tk_logicalXor:
			if (OperatorPrecedence.logicXor > precedence) break;
			auto node = state.makeNode!BinaryNode(false);
			node.lhs = expression;
			node.operator = cast(BinaryNode.Operator)state.popFront().type;
			node.rhs = state.parseExpression(OperatorPrecedence.logicXor);
			expression = node;
			goto nextSubExpression;
		case tk_question:
			if (OperatorPrecedence.tinary > precedence) break;
			auto node = state.makeNode!TinaryNode();
			node.subject = expression;
			state.expectToken(TokenType.tk_leftParen);
			node.lhs = state.parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			state.expectToken(TokenType.tk_colon);
			state.expectToken(TokenType.tk_leftParen);
			node.rhs = state.parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			expression = node;
			goto nextSubExpression;
		case TokenType.tk_leftParen:
			if (OperatorPrecedence.paramatized > precedence) break;
			auto node = state.makeNode!FunctionCallNode(false);
			node.subject = expression;
			node.arguments = state.parseList!(parseExpression)(TokenType.tk_leftParen, TokenType.tk_rightParen);
			expression = node;
			goto nextSubExpression;
		case TokenType.tk_leftBracket:
			if (OperatorPrecedence.paramatized > precedence) break;
			auto node = state.makeNode!SubscriptNode(false);
			node.subject = expression;
			node.arguments = state.parseList!(parseExpression)(TokenType.tk_leftBracket, TokenType.tk_rightBracket);
			expression = node;
			goto nextSubExpression;
		case tk_assign, tk_assignAdd, tk_assignSubtract, tk_assignMultiply, tk_assignDivide, tk_assignModulo, tk_assignPower,
		tk_assignConcat, tk_assignAnd, tk_assignOr, tk_assignXor:
			if (OperatorPrecedence.assignment > precedence) break;
			auto node = state.makeNode!AssignmentNode(false);
			node.subject = expression;
			node.operator = cast(AssignmentNode.Operator)state.popFront().type;
			node.argument = state.parseExpression(OperatorPrecedence.assignment);
			expression = node;
			goto nextSubExpression;
		case tk_dot:
			if (OperatorPrecedence.resolution1 > precedence) break;
			auto node = state.makeNode!DispatchNode();
			node.subject = expression;
			node.identifier = state.expectToken(TokenType.ud_identifier).text;
			expression = node;
			goto nextSubExpression;
		case tk_increment, tk_decrement:
			if (OperatorPrecedence.unary4 > precedence) break;
			auto node = state.makeNode!UnaryNode(false);
			node.subject = expression;
			node.operator = state.popFront().type == tk_increment ? UnaryNode.Operator.increment : UnaryNode.Operator.decrement;
			expression = node;
			goto nextSubExpression;
		default:
			break;
	}
	return expression;
}

ReferenceNode parseReference(ParserState state, OperatorPrecedence precedence = OperatorPrecedence.max) {
	ReferenceNode reference;

	nextReference: switch(state.front.type) with(TokenType) {
		case ud_identifier:
			auto node = state.makeNode!IdentifierNode(false);
			node.identifier = state.popFront().text;
			reference = node;
			break;
		default:
			throw new ParserException(format("Unrecognized expresssion %s", state.front.text), state.front.location);
	}

	nextSubReference: switch(state.front.type) with(TokenType) {
		case tk_dot:
			if (OperatorPrecedence.resolution1 > precedence) break;
			auto node = state.makeNode!DispatchNode();
			node.subject = reference;
			node.identifier = state.expectToken(TokenType.ud_identifier).text;
			reference = node;
			goto nextSubReference;
		default:
			break;
	}
	return reference;
}

void parseAttributes(ParserState state) {
	while(!state.empty && state.front.type == TokenType.tk_at) {
		auto node = new AttributeNode;
		node.location = state.expectToken(TokenType.tk_at).location;
		node.parent = state.peekNode();
		if (state.popTestToken(TokenType.kw_module)) node.name = "module";
		else node.name = state.expectToken(TokenType.ud_identifier).text;
		if (state.testToken(TokenType.tk_leftParen)) {
			node.arguments = state.parseList!(parseExpression)(TokenType.tk_leftParen, TokenType.tk_rightParen);
		}
		state.attributes ~= node;
	}
}

auto parseBlock(alias parseFun)(ParserState state) {
	ReturnType!(parseFun)[] result;
	if(state.popTestToken(TokenType.tk_leftBrace)) {
		if (state.popTestToken(TokenType.tk_rightBrace)) return result;
		do {
			result ~= parseFun(state);
		} while (!state.empty && !state.testToken(TokenType.tk_rightBrace));
		state.expectToken(TokenType.tk_rightBrace);
	} else {
		result ~= parseFun(state);
	}
	return result;
}

auto parseList(alias parseFun)(ParserState state, TokenType left, TokenType right) {
	ReturnType!(parseFun)[] result;
	state.expectToken(left);
	if (state.popTestToken(right)) return result;
	do {
		result ~= parseFun(state);
	} while(state.popTestToken(TokenType.tk_comma));
	state.popTestToken(TokenType.tk_comma);
	state.expectToken(right);
	return result;
}

auto parseList(alias parseFun)(ParserState state, TokenType delimiter) {
	ReturnType!(parseFun)[] result;
	do {
		result ~= parseFun(state);
	} while(state.popTestToken(delimiter));
	return result;
}

enum OperatorPrecedence {
	reserved,
	resolution1,
	resolution2,
	paramatized,
	unary1,
	unary2,
	unary3,
	unary4,
	arithmatic1,
	arithmatic2,
	range,
	binaryShift,
	binaryAnd,
	binaryOr,
	binaryXor,
	logicalAnd,
	logicalOr,
	logicXor,
	equity,
	inequity,
	relational,
	tinary,
	assignment,
}

class ParserState {
	Token[] tokens;
	size_t position;
	DList!ASTNode parents;
	AttributeNode[] attributes;

	this(Token[] tokens) {
		this.tokens = tokens;
	}

	@property bool empty() {
		return position >= tokens.length-1; //EOF
	}

	@property size_t length() {
		return tokens.length - position;
	}

	@property Token front() {
		return tokens[position];
	}

	Token popFront() {
		return tokens[position++];
	}

	Token[] frontN(size_t amount) {
		import std.algorithm : min;
		return tokens[position..min(position+amount, $)];
	}

	Token[] popFrontN(size_t amount) {
		auto result = this.frontN(amount);
		position += result.length;
		return result;
	}

	void pushNode(ASTNode node) {
		parents.insertFront(node);
	}

	ASTNode peekNode() {
		return parents.front;
	}

	ASTNode popNode() {
		auto result = parents.front;
		parents.removeFront();
		return result;
	}

	bool testToken(TokenType tokenType) {
		return this.front.type == tokenType;
	}

	bool popTestToken(TokenType tokenType) {
		if (this.front.type == tokenType) {
			this.popFront();
			return true;
		} else {
			return false;
		}
	}

	Token expectToken(TokenType tokenType) {
		if (this.front.type == tokenType) return this.popFront();
		else throw new ParserException(format("Expected %s, got '%s'", tokenDescriptionMap[tokenType], front.text), front.location);
	}

	Type makeNode(Type)(bool popNextToken = true) {
		auto node = new Type;
		node.location = this.front.location;
		node.attributes = this.attributes;
		this.attributes = [];
		node.parent = this.peekNode();
		if (popNextToken) this.popFront();
		return node;
	}
}

class ParserException : Exception {
	this(string msg, SourceLocation location, string file = __FILE__, size_t line = __LINE__) {
		super(msg ~ " in " ~ location.toString(), file, line);
	}
}
