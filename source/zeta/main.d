module zeta.main;

import std.stdio;
import std.conv;
import std.file : readText;
import std.algorithm;
import zeta.parse;
import zeta.script;
import zeta.type;

void main()
{
    auto sourceFile = "test.zs";

    auto lexer = ZtLexer(sourceFile, sourceFile.readText);
    auto ztModule = ZtParser(lexer).parseModule();
    auto interpreter = new ZtScriptInterpreter;
    interpreter.context.define("writeln", interpreter.nativeType.make(&zt_writeln));
    interpreter.context.define("isRef", interpreter.nativeType.make(&zt_isRef));
    interpreter.context.define("refPtr", interpreter.nativeType.make(&zt_refPtr));
    auto context = interpreter.execute(ztModule);
    auto result = context.lookup("main").op_call(null);
}

ZtValue zt_writeln(ZtScriptInterpreter interpreter, ZtValue[] args) {
    writefln("%-(%s %)", args.map!((e) => (e.type == interpreter.stringType ? e.m_string : e.op_tostring)));
    return interpreter.nullType.nullValue;
}

ZtValue zt_isRef(ZtScriptInterpreter interpreter, ZtValue[] args) {
    return interpreter.booleanType.make(args[0].isRef);
}

ZtValue zt_refPtr(ZtScriptInterpreter interpreter, ZtValue[] args) {
    if (args[0].isRef) return interpreter.stringType.make(args[0]._val.ptr1.text);
    else return interpreter.stringType.make("Not ref");
}