/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.utils.error;

enum OnError {
    sink,
    throwException,
    assert0
}

mixin template ErrorSink(OnError onError = OnError.sink, ExceptionType = Exception) {
    import std.format;
    import zeta.parse.token;

    enum ZtSrcLocation unknown = ZtSrcLocation(0, 0, 0, "unknown");

    string[] messages;
    size_t warnCount, errorCount;

    void internalError(Args...)(ZtSrcLocation location, string fmt, Args args) {
        this.errorCount += 1;
        messages ~= format("Internal Error: %s caused by %s", format(fmt, args), location == unknown ? "unknown" : location.toString);
        static if (onError == OnError.assert0)
            assert(0, messages[$ - 1]);
        else static if (onError == OnError.throwException)
            throw new ExceptionType(messages[$ - 1]);
    }

    void error(Args...)(ZtSrcLocation location, string fmt, Args args) {
        this.errorCount += 1;
        messages ~= format("Error: %s in %s", format(fmt, args), location == unknown ? "unknown" : location.toString);
        static if (onError == OnError.assert0)
            assert(0, messages[$ - 1]);
        else static if (onError == OnError.throwException)
            throw new ExceptionType(messages[$ - 1]);
    }

    void warn(Args...)(ZtSrcLocation location, string fmt, Args args) {
        this.warnCount += 1;
        messages ~= format("Warning: %s in %s", format(fmt, args), location == unknown ? "unknown" : location.toString);
    }

    void info(Args...)(ZtSrcLocation location, string fmt, Args args) {
        messages ~= format("Info: %s in %s", format(fmt, args), location == unknown ? "unknown" : location.toString);
    }
}
