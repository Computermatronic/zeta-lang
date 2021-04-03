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
import zeta.type.value;
import zeta.type.nativefunc;
import zeta.type.func;
import zeta.type.nullval;

void main(string[] args) {
    ZtInterpreter interpreter = new ZtInterpreter;
    interpreter.addNative(new ZtNative(&zt_writeln, "writeln"));
    ZtFunction ztMain;
    foreach(file; args[1..$]) {
	    auto lexer = ZtLexer(file, file.readText());
	    auto parser = ZtParser(lexer);
	    auto astModule = parser.parseModule();
	    if (lexer.errorCount + parser.errorCount > 0) {
		    writefln("%-(%s\n%)", lexer.messages ~ parser.messages);
		    return;
		}
	    auto moduleScope = interpreter.doModule(astModule);
	    if (auto moduleEntryPoint = cast(ZtFunction)(moduleScope.tryGet("main"))) ztMain = moduleEntryPoint;
	}
    if (ztMain is null) {
	    writeln("Error: no main function defined in script.");
	    return;
	}
    writeln("Script compiled correctly, running...");
    auto result = ztMain.call(null);
}
ZtValue zt_writeln(ZtValue[] args) {
    writefln("%(%s %)", args);
    return nullValue;
}