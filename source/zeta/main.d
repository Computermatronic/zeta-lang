/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.main;

import std.stdio;
import std.array;
import std.file : readText;
import zeta.parse.lexer;
import zeta.parse.parser;
import zeta.script.interpreter;
import zeta.script.variable;

void main(string[] args) {
	ZtInterpreter interpreter = new ZtInterpreter;
	interpreter.addNative(new BuiltinDelegate(&zt_writeln, "writeln"));
	Delegate ztMain;
	foreach(file; args[1..$]) {
		auto lexer = ZtLexer(file, file.readText());
		auto parser = ZtParser(lexer);
		auto astModule = parser.parseModule();
		if (lexer.errorCount + parser.errorCount > 0) {
			writefln("%-(%s\n%)", lexer.messages ~ parser.messages);
			return;
		}
		auto moduleScope = interpreter.doModule(astModule);
		if (auto moduleEntryPoint = cast(Delegate)(moduleScope.tryGet("main"))) ztMain = moduleEntryPoint;
	}
	if (ztMain is null) {
		writeln("Error: no main function defined in script.");
		return;
	}
	writeln("Script compiled correctly, running...");
	auto result = ztMain.call(null);
}
Variable zt_writeln(Variable[] args) {
	writefln("%(%s %)", args);
	return nullValue;
}