/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2022 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.utils.meta;

template Choose(bool condition, alias lhs, alias rhs) {
    static if (condition)
        alias Choose = lhs;
    else
        alias Choose = rhs;
}

/* 
 * This was loosely inspired from asrd.mvd by Adam D. Ruppe, and utilizes some of the same ideas;
 * Usage is simple: just add mixin(MultiDispatch!name); to your class and multiple dispatch will automagically work (or not).
 * Currently it is non-virtual and does not support inheriting from Multi-dispatch classes very well.
 * Subclass overloads will not be considered and multiple MultiDispatch's that overload the same name in both the base class 
 * and sub-class will not compile (as the compiler does not know which version to call).
 * Consequently some invalid calls can be caught at compile time.
 * This was really designed to replace the Visitor patten, rather than implement full multiple virtual dispatch.
 * Also, in cases where there are multiple potential return types for a given call, MultiDispatch will automatically place them
 * into an Algebraic of all possible types.
 * Additionally, MultiDispatch will consider overloads with an underscore (_) appended to their name, to ensure that certain
 * calls are virtualised.
 */
enum MultiDispatch(string name) = `mixin MultiDispatchImpl!"` ~ name ~ `" `
    ~ name ~ `impl; alias ` ~ name ~ ` = ` ~ name ~ `impl.payload;`;
mixin template MultiDispatchImpl(string name) {
    import std.traits, std.meta, std.variant, std.typecons;

    auto payload(Args...)(Args args) {
        enum isCompatibleOverload(alias T) = isCompatibleWith!(Tuple!(Parameters!T),
                    Tuple!(Args)) && !is(T == payload);
        static if(__traits(hasMember, typeof(this), name ~ "_"))
            alias CompatibleOverloads = Filter!(isCompatibleOverload,
                AliasSeq!(__traits(getOverloads, typeof(this), name), __traits(getOverloads, typeof(
                    this), name ~ "_")));
        else
            alias CompatibleOverloads = Filter!(isCompatibleOverload,
                    __traits(getOverloads, typeof(this), name));
        static assert(CompatibleOverloads.length > 0,
                "Cannot find valid overload for " ~ name ~ Args.stringof);
        alias CompatibleReturnTypes = NoDuplicates!(staticMap!(ReturnType, CompatibleOverloads));
        static if (CompatibleReturnTypes.length == 1)
            alias CommonReturnType = CompatibleReturnTypes[0];
        else
            alias CommonReturnType = Algebraic!CompatibleReturnTypes;
        int maxScore;
        bool isAmbiguous;
        CommonReturnType delegate() bestMatch;
        foreach (overload; CompatibleOverloads) {
            alias Params = Parameters!overload;
            Params params;
            int score;
            static foreach (i; 0 .. Args.length) {
                params[i] = cast(Params[i]) args[i];
                static if (is(Params[i] == class))
                    if (params[i]!is null)
                        score += BaseClassesTuple!(Params[i]).length + 1;
                static if (is(Params[i] == interface))
                    if (params[i]!is null)
                        score += InterfacesTuple!(Params[i]).length + 1;
            }
            if (score == maxScore)
                isAmbiguous = true;
            if (score > maxScore) {
                isAmbiguous = false;
                maxScore = score;
                static if (CompatibleReturnTypes.length > 1 && !is(ReturnType!overload == void))
                    bestMatch = () => CommonReturnType(overload(params));
                else static if (CompatibleReturnTypes.length > 1)
                    bestMatch = () { overload(params); return CommonReturnType(); };
                else
                    bestMatch = () => overload(params);
            }
        }
        assert(maxScore != 0, "Cannot find valid overload for " ~ name ~ args.argumentDescription);
        assert(!isAmbiguous, "Multiple overloads match" ~ name ~ args.argumentDescription);
        return bestMatch();
    }

    template isCompatibleWith(alias tuple1, alias tuple2) {
        static if (tuple1.length != tuple2.length)
            enum isCompatibleWith = false;
        static foreach (i; 0 .. tuple2.length) {
            static if (!is(typeof(isCompatibleWith) == bool)
                    && !(is(typeof(tuple1[i]) == typeof(tuple2[i]))
                        || is(typeof(tuple1[i]) : typeof(tuple2[i]))
                        || is(typeof(tuple1[i]) == interface))) {
                enum isCompatibleWith = false;
            }
        }
        static if (!is(typeof(isCompatibleWith) == bool))
            enum isCompatibleWith = true;
    }
}

string argumentDescription(Args...)(Args args) {
    string buffer = "(";
    foreach(i, arg; args) {
        buffer ~= typeid(arg).toString;
        if (i - 1 < args.length) buffer ~= ", ";
    }
    return buffer ~ ")";
}