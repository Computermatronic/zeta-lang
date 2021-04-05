module zeta.main;

import std.stdio;
import std.conv;
import std.array;
import std.file : readText;
import std.algorithm;
import zeta.parse;
import zeta.script;
import zeta.typesystem;

void main() {
    auto sourceFile = "test.zs";
    auto lexer = ZtLexer(sourceFile, sourceFile.readText);
    auto parser = ZtParser(lexer);
    auto ztModule = parser.parseModule();
    if (lexer.errorCount + parser.errorCount > 0) {
        lexer.messages.each!((e) => e.writeln);
        parser.messages.each!((e) => e.writeln);
    } else {
        auto interpreter = new ZtScriptInterpreter;
        interpreter.context.define("writeln", interpreter.nativeType.make(&zt_writeln));
        interpreter.context.define("isRef", interpreter.nativeType.make(&zt_isRef));
        interpreter.context.define("refPtr", interpreter.nativeType.make(&zt_refPtr));
        auto context = interpreter.execute(ztModule);
        if (auto ztMain = context.tryLookup("main"))
            ztMain.op_call(null);
        else
            writeln("Error: no entry point defined");
    }
}

ZtValue zt_writeln(ZtScriptInterpreter interpreter, ZtValue[] args) {
    writefln("%-(%s %)", args.map!((e) => (e.type == interpreter.stringType
            ? e.m_string : e.op_tostring)));
    return interpreter.nullType.nullValue;
}

ZtValue zt_isRef(ZtScriptInterpreter interpreter, ZtValue[] args) {
    return interpreter.booleanType.make(args[0].isRef);
}

ZtValue zt_refPtr(ZtScriptInterpreter interpreter, ZtValue[] args) {
    if (args[0].isRef)
        return interpreter.stringType.make(args[0].m_int.text);
    else
        return interpreter.stringType.make("Not ref");
}
