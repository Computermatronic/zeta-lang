module test;

function main() {
    def variable = 9;
    def $123 = "12345";
    def foo = "zzzz";
    writeln("hello from zeta-lang land");
    writeln(2+2);
    writeln(variable*8);
    writeln($123[1]);
    switch(foo) {
        case "cat": writeln("cat");
        case "flow": writeln("flow"); 
        case "tart": writeln("tart");
        case else: writeln("else");
    }
    def buffer = "";
    for(def i = 0; i < 10; i++) {
        buffer ~= cast:string(i);
        buffer ~= " ";
        with(buffer) {
            writeln(length);
        }
    }
    writeln(buffer);

    if (variable >= 10) {
        writeln("greater than or equal to 10");
    } else {
        writeln("less than 10");
    }

    writeln(variable);
    test(variable);
    writeln(variable);
    vargs(variable, 20, "string", [ 1, 2, 3] );

    //def f = new:integer(5);

    return 0;
}

function test(def arg) {
    //arg += 1;
    arg = 44;
    writeln("arg:", arg);
}

function vargs(def $1st, def args...) {
    writeln(args);
}