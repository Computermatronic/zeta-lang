import std.stdio;
import std.file : readText;
import zeta.parser;
import zeta.interpreter;

void main()
{
	auto sourceFile = "test.zs";

	auto tokens = lexString(sourceFile, sourceFile.readText);
	auto module_ = parseTokens(tokens);

	auto interpreter = new Interpreter;

	module_.accept(interpreter);
	auto result = interpreter.op_call(interpreter.context.lookup("main"), null);
	auto str = interpreter.op_cast(&result, interpreter.stringType);
	writeln(str.string_);
}
