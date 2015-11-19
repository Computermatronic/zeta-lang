module zeta.natives;

import zeta.var;
import zeta.utils;
import std.conv;

Var toFloat(Var[] args)
{
    if(args.length<1)
        throw new RuntimeException("Incorrect number of paramaters in function call");
    else if(args[0].type == "float")
        return args[0].refOf();
    else if (args[0].type == "integer")
        return new Float((cast(Integer)args[0]).number);
    else if (args[0].type == "string")
        return new Float(to!real((cast(String)args[0]).text));
    else if (args[0].type == "boolean")
        return new Float(args[0].eval ? 1 : real.nan);
    else
        throw new RuntimeException("cannot convert %s to float",args[0].type);
}

Var toInteger(Var[] args)
{
    if(args.length<1)
        throw new RuntimeException("Incorrect number of paramaters in function call");
    else if(args[0].type == "float")
        return new Integer(cast(integer)(cast(Float)args[0]).number);
    else if (args[0].type == "integer")
        return args[0].refOf();
    else if (args[0].type == "string")
        return new Integer(to!int((cast(String)args[0]).text));
    else if (args[0].type == "boolean")
        return new Integer(args[0].eval ? 1 : 0);
    else
        throw new RuntimeException("cannot convert %s to int",args[0].type);
}

Var toString(Var[] args)
{
    if(args.length<1)
        throw new RuntimeException("Incorrect number of paramaters in function call");
    else if(args[0].type == "float")
        return new String(to!string((cast(Float)args[0]).number));
    else if (args[0].type == "integer")
        return new String(to!string((cast(Integer)args[0]).number));
    else if (args[0].type == "string")
        return args[0].refOf();
    else if (args[0].type == "boolean")
        return new String(args[0].eval ? "true" : "false");
    else
        throw new RuntimeException("cannot convert %s to string",args[0].type);
}

Var toBool(Var[] args)
{
    if(args.length<1)
        throw new RuntimeException("Incorrect number of paramaters in function call");
    else
        return new Bool(args[0].eval());
}
