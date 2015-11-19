module zeta.script;

import zeta.lexer;
import zeta.parser;
import zeta.analyser;

class Script
{
    static Script[string] scripts;
    Script[string] imports;
    DList!(ParserNode) parseTree;
    Analyser analyser;
    this(string file)
    {
        scripts[file] = this;
        analyser = new Analyser();
        foreach(node;parse(new TokenStream(readText(getFile(file)))))
            switch(node.type)
            {
                case "function":
                    parseTree.insertBack(node);
                    analyser.moduleScope.resolve((cast(Function)node).name)
                    break;
                case "import":
                    Import import_ = cast(Import)node;
                    imports ~= (import_.importee in scripts) 
                        ? scripts[import_.importee] : new Script(import_.importee);
                    break;
                case "pragma":
                    break;
                default:
                    parserTree.insertFront(node);
            }
        foreach(import_;imports)
            foreach(node;import_.parserTree)
                switch(node.type)
                {
                    case "def":
                        analyser.moduleScope.resolve((cast(Def)node).name);
                        break;
                    case "function":
                        analyser.moduleScope.resolve((cast(Function)node).name);
                        break;
                    default:
                        break;
                }
        analyser.analyse();
    }
}

class Runnable
{
    Interpreter interpreter;                    
