/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2022 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.parse.ast;

import zeta.utils;
import zeta.parse;

abstract class ZtAstNode {
    ZtSrcLocation location;
}

abstract class ZtAstStatement : ZtAstNode {
    ZtAstAttribute[] attributes;
}

abstract class ZtAstDeclaration : ZtAstStatement {
    string name;
}

abstract class ZtAstExpression : ZtAstNode {
}

abstract class ZtAstReference : ZtAstExpression {
}

class ZtAstModule : ZtAstDeclaration {
    string[] packageName;
    ZtAstStatement[] members;
}

class ZtAstDef : ZtAstDeclaration {
    ZtAstReference type;
    ZtAstExpression initializer;
}

class ZtAstImport : ZtAstDeclaration {
    string[] packageName;
    string[] memberWhitelist;
}

class ZtAstFunction : ZtAstDeclaration {
    ZtAstReference type;
    ZtAstDef[] parameters;
    ZtAstStatement[] members;

    bool isVariadic;
}

class ZtAstEnum : ZtAstDeclaration {
    ZtAstReference type;
    ZtAstEnumMember[] members;
}

class ZtAstEnumMember : ZtAstDeclaration {
    ZtAstExpression initializer;
}

class ZtAstStruct : ZtAstDeclaration {
    ZtAstReference[] baseTypes;
    ZtAstStatement[] members;
}

class ZtAstClass : ZtAstDeclaration {
    ZtAstReference[] baseTypes;
    ZtAstStatement[] members;
}

class ZtAstInterface : ZtAstDeclaration {
    ZtAstReference[] baseTypes;
    ZtAstStatement[] members;
}

class ZtAstAttribute : ZtAstNode {
    string name;
    ZtAstExpression[] arguments;
}

class ZtAstIf : ZtAstStatement {
    ZtAstExpression condition;
    ZtAstStatement[] members;
    ZtAstStatement[] elseMembers;
}

class ZtAstSwitch : ZtAstStatement {
    ZtAstExpression condition;
    ZtAstCase[] members;
}

class ZtAstCase : ZtAstStatement {
    ZtAstExpression[] matches;
    ZtAstStatement[] members;

    bool isElseCase;
}

class ZtAstWhile : ZtAstStatement {
    ZtAstExpression condition;
    ZtAstStatement[] members;
}

class ZtAstDoWhile : ZtAstStatement {
    ZtAstExpression condition;
    ZtAstStatement[] members;
}

class ZtAstFor : ZtAstStatement {
    ZtAstDef initializer;
    ZtAstExpression condition;
    ZtAstExpression step;
    ZtAstStatement[] members;
}

class ZtAstForeach : ZtAstStatement {
    ZtAstDef[] initializers;
    ZtAstExpression aggregate;
    ZtAstStatement[] members;
}

class ZtAstWith : ZtAstStatement {
    ZtAstExpression aggregate;
    ZtAstReference type;
    ZtAstStatement[] members;

    bool isCast;
}

class ZtAstDelete : ZtAstStatement {
    ZtAstExpression expression;
}

class ZtAstReturn : ZtAstStatement {
    ZtAstExpression expression;
}

class ZtAstBreak : ZtAstStatement {
}

class ZtAstContinue : ZtAstStatement {
}

class ZtAstExpressionStatement : ZtAstStatement {
    ZtAstExpression expression;
}

class ZtAstIdentifier : ZtAstReference {
    string name;
}

class ZtAstTuple : ZtAstReference {
    ZtAstExpression[] arguments;
}

class ZtAstDispatch : ZtAstReference {
    ZtAstExpression expression;
    string name;
}

class ZtAstSubscript : ZtAstReference {
    ZtAstExpression expression;
    ZtAstExpression[] arguments;
}

class ZtAstTypeOf : ZtAstReference {
    ZtAstExpression expression;
}

class ZtAstLogical : ZtAstExpression {
    enum Operator : ZtToken.Type {
        and = ZtToken.Type.op_and,
        or = ZtToken.Type.op_or,
        equal = ZtToken.Type.op_equal,
        notEqual = ZtToken.Type.op_notEqual,
        lessThan = ZtToken.Type.op_lessThan,
        greaterThan = ZtToken.Type.op_greaterThan,
        lessThanEqual = ZtToken.Type.op_lessThanEqual,
        greaterThanEqual = ZtToken.Type.op_greaterThanEqual
    }

    ZtAstExpression lhs, rhs;
    Operator operator;
}

class ZtAstBinary : ZtAstExpression {
    enum Operator : ZtToken.Type {
        no_op = ZtToken.Type.no_op,
        add = ZtToken.Type.op_plus,
        subtract = ZtToken.Type.op_minus,
        multiply = ZtToken.Type.op_asterisk,
        divide = ZtToken.Type.op_slash,
        modulo = ZtToken.Type.op_percent,
        concat = ZtToken.Type.op_tilde,
        bitAnd = ZtToken.Type.op_ampersand,
        bitOr = ZtToken.Type.op_poll,
        bitXor = ZtToken.Type.op_circumflex,
        bitShiftLeft = ZtToken.Type.op_shiftLeft,
        bitShiftRight = ZtToken.Type.op_shiftRight
    }

    ZtAstExpression lhs, rhs;
    Operator operator;
}

class ZtAstUnary : ZtAstExpression {
    enum Operator : ZtToken.Type {
        increment = ZtToken.Type.op_increment,
        decrement = ZtToken.Type.op_decrement,
        positive = ZtToken.Type.op_plus,
        negative = ZtToken.Type.op_minus,
        not = ZtToken.Type.op_not,
        bitNot = ZtToken.Type.op_tilde
    }

    ZtAstExpression expression;
    Operator operator;
    bool isPostOp;
}

class ZtAstAssign : ZtAstExpression {
    ZtAstExpression lhs, rhs;
    ZtAstBinary.Operator operator;
}

class ZtAstTrinary : ZtAstExpression {
    ZtAstExpression condition, lhs, rhs;
}

class ZtAstCall : ZtAstExpression {
    ZtAstExpression expression;
    ZtAstExpression[] arguments;
}

class ZtAstApply : ZtAstExpression {
    ZtAstExpression expression;
    string name;
}

class ZtAstCast : ZtAstExpression {
    ZtAstReference type;
    ZtAstExpression expression;
}

class ZtAstIs : ZtAstExpression {
    ZtAstExpression lhs, rhs;
}

class ZtAstNew : ZtAstExpression {
    ZtAstReference type;
    ZtAstExpression[] arguments;
}

class ZtAstArray : ZtAstExpression {
    ZtAstExpression[] arguments;
}

class ZtAstString : ZtAstExpression {
    string literal;
}

class ZtAstChar : ZtAstExpression {
    dchar literal;
}

class ZtAstInteger : ZtAstExpression {
    long literal;
}

class ZtAstFloat : ZtAstExpression {
    double literal;
}
