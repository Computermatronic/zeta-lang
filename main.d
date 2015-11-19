module main;

import zeta.parser;
import zeta.lexer;
import zeta.interpreter;

import std.stdio;

void main()
{
    try
    {
        repl();
    }
    catch(Throwable t)
    {
        writeln(t.toString());
    }
    stdin.readln();
}

void repl()
{
    string input;
    string ln;
    import zeta.var;
    Interpreter engine = new Interpreter();
    writeln("Zeta command line REPL");
start:
    try
    {
        while((input = replIn(">")) != "exit\n")
        {
            while((ln = replIn(">>")) != "\n")
            {
                input ~= ln;
            }
            auto ts = new TokenStream(input).process();
            auto result = parse(ts);
            foreach(state;result)
                if (state.type == "expression")
                    writeln(engine.execute((cast(Expression)state).exp).desc());
                else
                    engine.execute(state);
        }
    }
    catch(ParserException e)
    {
        writeln(e.msg);
        goto start;
    }
    catch(LexerException e)
    {
        writeln(e.msg);
        goto start;
    }
    catch(RuntimeException e)
    {
        writeln(e.msg);
        goto start;
    }
}

string replIn(string mask)
{
    write(mask);
    stdout.flush();
    return readln();
}
