/* 
 * The official Zeta interpreter.
 * Reference implementation of the Zeta scripting language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module zeta.parser.lexer;

import std.format : format;
import std.algorithm : min, fold;
import std.array : Appender;
import std.uni;

import zeta.parser.token;

auto lexString(string file, string text) {
	auto state = new LexerState(file, text);

	findNextToken: while(!state.empty) {
		if (state.front.isWhite()) {
			state.popFront();
			continue;
		}

		if (state.frontN(2) == `\\`) {
			state.parseLineComment();
			continue;
		}

		if (state.frontN(2) == `\*`) {
			state.parseBlockComment();
			continue;
		}

		//TODO: support nested block comments.

		if (state.front == '\"') {
			state.pushToken(state.parseString());
			continue;
		}

		if (state.front == '`') {
			state.pushToken(state.parseExactString());
			continue;
		}

		if (state.front.isNumber()) {
			state.pushToken(state.parseNumber());
			continue;
		}

		foreach(tokenName; tokenNames) {
			if (state.frontN(tokenName.length) == tokenName && (!tokenName.fold!((bool b, dchar c) => b && c.isAlpha())(true) || state.length <= tokenName.length || 
				!state.frontN(tokenName.length + 1)[$-1].isAlphaNum())) {
				state.pushToken(Token(tokenNameMap[tokenName], state.location, state.popFrontN(tokenName.length)));
				continue findNextToken;
			}
		}

		if (state.front.isAlpha() || state.front == '_' || state.front == '$') {
			state.pushToken(state.parseIdentifier());
			continue;
		}
		import std.stdio; writefln("%s", state.front.isWhite());
		throw new LexerException(format(`Unknown or illegal character '%s'.`, state.front), state.location);
	}
	state.pushToken(Token(TokenType.tk_eof, state.location, "<End of File>"));
	return state.tokens;
}

Token parseLineComment(LexerState state) {
	auto location = state.location;
	Appender!string result;
	state.popFront();
	while (!state.empty && state.front != '\n') {
		result.put(state.popFront());
	}
	return Token(TokenType.ud_comment, location, result.data);
}

Token parseBlockComment(LexerState state) {
	auto location = state.location;
	Appender!string result;
	state.popFront();
	while (!state.empty && state.frontN(2) != "*/") {
		result.put(state.popFront());
	}
	if (state.empty) throw new LexerException("Unterminated block comment.", location);
	state.popFront();
	return Token(TokenType.ud_comment, location, result.data);
}

Token parseString(LexerState state) {
	auto location = state.location;
	Appender!string result;
	state.popFront();
	while (!state.empty && state.front != '\"') {
		result.put(state.parseChar());
	}
	if (state.empty) throw new LexerException("Unterminated string constant.", location);
	state.popFront();
	return Token(TokenType.ud_string, location, result.data);
}

Token parseExactString(LexerState state) {
	auto location = state.location;
	Appender!string result;
	state.popFront();
	while (!state.empty && state.front != '\"') {
		result.put(state.popFront());
	}
	if (state.empty) throw new LexerException("Unterminated string constant.", location);
	state.popFront();
	return Token(TokenType.ud_string, location, result.data);
}

Token parseNumber(LexerState state) {
	auto location = state.location;
	bool isFloat;
	Appender!string result;
	state.popFront();
	while (!state.empty && (state.front.isNumber() || state.front == '.')) {
		if (state.front == '.') {
			if (isFloat || (state.length >= 2 && !state.frontN(2)[1].isNumber())) 
				return Token(isFloat ? TokenType.ud_float : TokenType.ud_integer, location, result.data);
			else isFloat = true;
		}
		result.put(state.popFront());
	}
	return Token(isFloat ? TokenType.ud_float : TokenType.ud_integer, location, result.data);
}

Token parseIdentifier(LexerState state) {
	auto location = state.location;
	Appender!string result;
	while (!state.empty && (state.front.isAlphaNum() || state.front == '_' || state.front == '$')) {
		result.put(state.popFront());
	}
	return Token(TokenType.ud_identifier, location, result.data);
}

dchar parseChar(LexerState state) {
	//TODO: escape sequence parsing.
	return state.popFront();
}

class LexerState {
	string text;
	size_t position;
	string file;
	Appender!(Token[]) tokenBuffer;

	this(string file, string text) {
		this.file = file;
		this.text = text;
	}

	@property bool empty() {
		return position >= text.length;
	}

	@property size_t length() {
		return text.length - position;
	}

	@property dchar front() {
		return text[position];
	}

	dchar popFront() {
		return text[position++];
	}

	string frontN(size_t amount) {
		return text[position..min(position+amount, $)];
	}

	string popFrontN(size_t amount) {
		auto result = this.frontN(amount);
		position += result.length;
		return result;
	}

	@property SourceLocation location() {
		return SourceLocation.fromBuffer(text, position, file);
	}

	void pushToken(Token token) {
		this.tokenBuffer.put(token);
	}

	@property Token[] tokens() {
		return this.tokenBuffer.data;
	}
}

class LexerException : Exception {
	this(string msg, SourceLocation location, string file = __FILE__, size_t line = __LINE__) {
		super(msg ~ " in " ~ location.toString(), file, line);
	}
}
