import std.stdio;
import std.file : readText;
import zeta.parser;
import zeta.misc;

void main()
{
	auto sourceFile = "test.zs";
	auto tokens = lexString(sourceFile, sourceFile.readText);
	auto module_ = parseTokens(tokens);
	auto printer = new ASTPrinter;

	module_.accept(printer);
	writeln(printer.output.data);
}
