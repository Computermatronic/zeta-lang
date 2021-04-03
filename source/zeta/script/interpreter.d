/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.script.interpreter;

import std.conv : to;
import std.algorithm;
import std.array;
import std.container.slist;
import zeta.parse.ast;
import zeta.script.context;
import zeta.script.interpreter;
import zeta.type;
import zeta.utils.dispatch;

final class ZtScriptInterpreter {
    mixin(MultiDispatch!`evaluate`);
    mixin(MultiDispatch!`execute`);

    SList!ZtLexicalContext stack;
    ZtValue returnValue;
    bool isReturning;
    int continueLevel, breakLevel;

    ZtNullType nullType;
    ZtBooleanType booleanType;
    ZtIntegerType integerType;
    ZtFloatType floatType;
    ZtStringType stringType;
    ZtArrayType arrayType;
    ZtFunctionType functionType;
    ZtNativeType nativeType;
    ZtMetaType metaType;
    ZtType[] types;

    this() {
        stack.insertFront(new ZtLexicalContext);
        types ~= nullType = new ZtNullType;
        types ~= booleanType = new ZtBooleanType;
        types ~= integerType = new ZtIntegerType;
        types ~= floatType = new ZtFloatType;
        types ~= stringType = new ZtStringType;
        types ~= arrayType = new ZtArrayType;
        types ~= functionType = new ZtFunctionType;
        types ~= nativeType = new ZtNativeType;
        types ~= metaType = new ZtMetaType;

        foreach(k, v; types) {
            v.register(this);
            context.define(v.name, metaType.make(v));
        }
        context.define("true", booleanType.trueValue);
        context.define("false", booleanType.falseValue);
        context.define("null", nullType.nullValue);
    }

    @property ZtLexicalContext context() { return stack.front; }

    ZtLexicalContext execute(ZtAstModule node) {
        auto moduleScope = new ZtLexicalContext(context);
        stack.insertFront(moduleScope);
        execute(cast(ZtAstStatement[])node.members);
        stack.removeFront();
        return moduleScope;
    }

    ZtValue evaluate(ZtAstFunction node, ZtLexicalContext ctx, ZtValue[] arguments) {
        auto oldReturnValue = returnValue;
        returnValue = nullType.nullValue;
        stack.insertFront(new ZtLexicalContext(ctx));
        foreach(i, paramater; node.paramaters) {
            bool isRef = paramater.attributes.canFind!((e) => e.name == "ref");
            if (node.isVariadic && i+1 == node.paramaters.length) {
                context.define(paramater.name, arrayType.make(arguments[i..$].map!((e) => isRef ? e : e.deRefed()).array));
                break;
            } if(arguments.length > i) context.define(paramater.name, isRef ? arguments[i] : arguments[i].deRefed());
            else if (paramater.initializer !is null) context.define(paramater.name, isRef ? evaluate(paramater.initializer) : evaluate(paramater.initializer).deRefed());
            else assert(0, "Incorrect number of paramaters when calling function "~node.name);
        }
        execute(node.members);
        stack.removeFront();
        auto result = returnValue;
        returnValue = oldReturnValue;
        return result;
    }

    void execute(ZtAstStatement[] members) { 
        foreach(member; members) {
            execute(member);
            if (isReturning || breakLevel || continueLevel) return;
        }
    }

    ZtValue[] evaluate(ZtAstExpression[] members) {
        return members.map!((e) => evaluate(e)).array;
    }

    void execute(ZtAstDef node) { 
        context.define(node.name, evaluate(node.initializer).deRefed);
    }

    void execute(ZtAstImport node) { 
        assert(0, "Not implemented!");
    }

    void execute(ZtAstFunction node) { 
        context.define(node.name, functionType.make(node, context));
    }

    void execute(ZtAstIf node) { 
        stack.insertFront(new ZtLexicalContext(context));
        if (evaluate(node.subject).op_eval()) execute(node.members);
        else execute(node.elseMembers);
        stack.removeFront();
    }

    void execute(ZtAstSwitch node) { 
        stack.insertFront(new ZtLexicalContext(context));
        auto cond = evaluate(node.subject);
        bool isFallthrough = false;
        size_t elseCaseId;
        for(size_t i = 0; i < node.members.length; i++) {
            if (node.members[i].isElseCase) elseCaseId = i;
            auto matches = node.members[i].subjects.any!((exp) => evaluate(exp).op_equal(cond));
            if(matches || isFallthrough) {
                execute(node.members[i].members);
                if (isReturning) return;
                if (breakLevel > 0) { stack.removeFront(); breakLevel--; return; }
                if (continueLevel > 1) { stack.removeFront(); continueLevel--; return; }
                if (continueLevel == 1) { stack.removeFront(); continueLevel--; isFallthrough = false; }
                isFallthrough = true;
            }
            if (i+1 == node.members.length && !isFallthrough && elseCaseId != 0) {i = elseCaseId-1; isFallthrough = true; continue; }
        }
        stack.removeFront();
    }

    void execute(ZtAstWhile node) { 
        stack.insertFront(new ZtLexicalContext(context));
        while(evaluate(node.subject).op_eval()) {
            stack.insertFront(new ZtLexicalContext(context));
            execute(node.members);
            if (breakLevel > 0) { stack.removeFront(); breakLevel--; return; }
            if (continueLevel > 1) { stack.removeFront(); continueLevel--; return; }
            if (continueLevel == 1) { stack.removeFront(); continueLevel--; continue; }
            stack.removeFront();
        }
    }

    void execute(ZtAstDoWhile node) { 
        do {
            stack.insertFront(new ZtLexicalContext(context));
            execute(node.members);
            if (breakLevel > 0) { stack.removeFront(); breakLevel--; return; }
            if (continueLevel > 1) { stack.removeFront(); continueLevel--; return; }
            if (continueLevel == 1) { stack.removeFront(); continueLevel--; continue; }
            stack.removeFront();
        } while(evaluate(node.subject).op_eval());
    }

    void execute(ZtAstFor node) { 
        stack.insertFront(new ZtLexicalContext(context));
        execute(node.initializer);
        for(; evaluate(node.subject).op_eval(); evaluate(node.step)) {
            stack.insertFront(new ZtLexicalContext(context));
            execute(node.members);
            if (breakLevel > 0) { stack.removeFront(2); breakLevel--; return; }
            if (continueLevel > 1) { stack.removeFront(2); continueLevel--; return; }
            if (continueLevel == 1) { stack.removeFront(2); continueLevel--; continue; }
            stack.removeFront();
        }
        stack.removeFront();
    }

    void execute(ZtAstForeach node) { 
        assert(0, "Not implemented!");
    }

    void execute(ZtAstWith node) { 
        stack.insertFront(new ZtWithContext(evaluate(node.subject), context));
        execute(node.members);
        stack.removeFront();
    }

    void execute(ZtAstReturn node) { 
        returnValue = evaluate(node.subject);
        isReturning = true;
    }

    void execute(ZtAstBreak node) { 
        breakLevel++;
    }

    void execute(ZtAstContinue node) { 
        continueLevel++;
    }

    void execute(ZtAstExpressionStatement node) { 
        evaluate(node.subject);
    }

    ZtValue evaluate(ZtAstIdentifier node) {
        return context.lookup(node.name);
    }

    ZtValue evaluate(ZtAstDispatch node) { 
        return evaluate(node.subject).op_dispatch(node.name);
    }

    ZtValue evaluate(ZtAstSubscript node) { 
        return evaluate(node.subject).op_index(evaluate(node.arguments));
    }

    ZtValue evaluate(ZtAstBinary node) { 
        with(ZtAstBinary.Operator) final switch(node.operator) {
            case add: return evaluate(node.lhs).op_add(evaluate(node.rhs));
            case subtract: return evaluate(node.lhs).op_subtract(evaluate(node.rhs));
            case multiply: return evaluate(node.lhs).op_multiply(evaluate(node.rhs));
            case divide: return evaluate(node.lhs).op_divide(evaluate(node.rhs));
            case modulo: return evaluate(node.lhs).op_modulo(evaluate(node.rhs));
            case concat: return evaluate(node.lhs).op_concat(evaluate(node.rhs));
            case equal: return booleanType.make(evaluate(node.lhs).op_equal(evaluate(node.rhs)));
            case notEqual: return booleanType.make(!evaluate(node.lhs).op_equal(evaluate(node.rhs)));
            case lessThan: return booleanType.make(evaluate(node.lhs).op_cmp(evaluate(node.rhs)) < 0);
            case greaterThan: return booleanType.make(evaluate(node.lhs).op_cmp(evaluate(node.rhs)) > 0);
            case lessThanEqual: return booleanType.make(evaluate(node.lhs).op_cmp(evaluate(node.rhs)) >= 0);
            case greaterThanEqual: return booleanType.make(evaluate(node.lhs).op_cmp(evaluate(node.rhs)) <= 0);
            case and: return booleanType.make(evaluate(node.lhs).op_eval() && evaluate(node.rhs).op_eval());
            case or: return booleanType.make(evaluate(node.lhs).op_eval() || evaluate(node.rhs).op_eval());
            case xor: return booleanType.make(evaluate(node.lhs).op_eval() != evaluate(node.rhs).op_eval());
            case bitwiseAnd: return evaluate(node.lhs).op_bitAnd(evaluate(node.rhs));
            case bitwiseOr: return evaluate(node.lhs).op_bitOr(evaluate(node.rhs));
            case bitwiseXor: return evaluate(node.lhs).op_bitXor(evaluate(node.rhs));
            case bitwiseShiftLeft: return evaluate(node.lhs).op_bitShiftLeft(evaluate(node.rhs));
            case bitwiseShiftRight: return evaluate(node.lhs).op_bitShiftRight(evaluate(node.rhs));
        }
    }

    ZtValue evaluate(ZtAstUnary node) { 
         with(ZtAstUnary.Operator) final switch(node.operator) {
            case increment: auto v = evaluate(node.subject); v.op_increment(); return v;
            case decrement: auto v = evaluate(node.subject); v.op_decrement(); return v;
            case positive: return evaluate(node.subject).op_positive();
            case negative: return evaluate(node.subject).op_negative();
            case bitwiseNot: return evaluate(node.subject).op_bitNot();
            case not: return booleanType.make(!evaluate(node.subject).op_eval());
            case postIncrement: auto v = evaluate(node.subject); auto u = v.deRefed(); v.op_increment(); return u;
            case postDecrement: auto v = evaluate(node.subject); auto u = v.deRefed(); v.op_decrement(); return u;
        }
    }

    ZtValue evaluate(ZtAstTrinaryOperator node) { 
        return evaluate(node.subject).op_eval ? evaluate(node.lhs) : evaluate(node.rhs);
    }

    ZtValue evaluate(ZtAstAssign node) { 
        auto lhs = evaluate(node.subject);
        assert(lhs.isRef, "Error: Cannot assign RValue");
        with(ZtAstAssign.Operator) final switch(node.operator) {
            case assign: *lhs._val.m_ref = evaluate(node.assignment).deRefed; break;
            case add: *lhs._val.m_ref = lhs.op_add(evaluate(node.assignment)); break;
            case subtract: *lhs._val.m_ref = lhs.op_subtract(evaluate(node.assignment)); break;
            case multiply: *lhs._val.m_ref = lhs.op_multiply(evaluate(node.assignment)); break;
            case divide: *lhs._val.m_ref = lhs.op_divide(evaluate(node.assignment)); break;
            case modulo: *lhs._val.m_ref = lhs.op_modulo(evaluate(node.assignment)); break;
            case concat: lhs.op_concatAssign(evaluate(node.assignment)); break;
            case and: *lhs._val.m_ref = lhs.op_bitAnd(evaluate(node.assignment)); break;
            case or: *lhs._val.m_ref = lhs.op_bitOr(evaluate(node.assignment)); break;
            case xor: *lhs._val.m_ref = lhs.op_bitXor(evaluate(node.assignment)); break;
        }
        return lhs.deRefed();
    }

    ZtValue evaluate(ZtAstCall node) { 
        auto fun = evaluate(node.subject);
        auto args = node.arguments.map!((n) => evaluate(n))().array;
        return fun.op_call(args);
    }

    ZtValue evaluate(ZtAstApply node) { 
        auto lhs = evaluate(node.subject);
        if (lhs.type != nullType) return lhs.op_dispatch(node.name);
        else return nullType.nullValue;
    }

    ZtValue evaluate(ZtAstCast node) { 
        auto result = evaluate(node.type);
        if (result.type == metaType) return evaluate(node.subject).op_cast(result.m_type);
        else return evaluate(node.subject).op_cast(result.type);
    }

    ZtValue evaluate(ZtAstIs node) { 
        return booleanType.make(evaluate(node.lhs).type == evaluate(node.rhs).type);
    }

    ZtValue evaluate(ZtAstNew node) { 
        assert(0, "Not implemented!");
    }

    ZtValue evaluate(ZtAstArray node) { 
        return arrayType.make(evaluate(node.members));
    }

    ZtValue evaluate(ZtAstString node) { 
        return stringType.make(node.literal);
    }

    ZtValue evaluate(ZtAstChar node) { 
        return stringType.make(cast(string)[node.literal]);
    }

    ZtValue evaluate(ZtAstInteger node) { 
        return integerType.make(node.literal);
    }

    ZtValue evaluate(ZtAstFloat node) { 
        return floatType.make(node.literal);
    }
}