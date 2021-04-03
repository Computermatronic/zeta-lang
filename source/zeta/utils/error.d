/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.utils.error;

enum ErrorMethod { sink, throwRtException, assert0 }

mixin template ErrorSink(ErrorMethod errorMethod = ErrorMethod.sink) {
    import std.format;
    static if(errorMethod == ErrorMethod.throwRtException) import zeta.script.exception;
    string[] messages;
    size_t warnCount, errorCount;

    void error(Args...)(ZtSrcLocation location, string fmt, Args args) {
        this.errorCount += 1;
        messages ~= format("Error: %s in %s", format(fmt, args), location);
        static if(errorMethod == ErrorMethod.assert0) assert(0, messages[$-1]);
        else static if (errorMethod == ErrorMethod.throwRtException) throw new RuntimeException(messages[$-1]);
    }

    void warn(Args...)(ZtSrcLocation location, string fmt, Args args) {
        this.warnCount += 1;
        messages ~= format("Warning: %s in %s", format(fmt, args), location);
    }

    void info(Args...)(ZtSrcLocation location, string fmt, Args args) {
        messages ~= format("Info: %s in %s", format(fmt, args), location);
    }
}