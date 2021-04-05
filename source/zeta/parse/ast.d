/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.parse.ast;

import zeta.utils;
import zeta.parse.token;

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
    ZtAstDeclaration[] members;
}

// class ZtAstAlias: ZtAstDeclaration {
//     ZtAstReference type;
//     ZtAstExpression initializer;
// }

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
    ZtAstDef[] paramaters;
    ZtAstStatement[] members;

    bool isVariadic;
    bool isLinkage;
}

// class ZtAstEnum: ZtAstDeclaration {
//     // ZtAstReference type;
//     ZtAstEnumMember[] members;
// }

// class ZtAstEnumMember: ZtAstDeclaration {
//     ZtAstExpression initializer;
// }

class ZtAstClass : ZtAstDeclaration {
    ZtAstReference[] baseTypes;
    ZtAstDeclaration[] members;
}

// class ZtAstInterface: ZtAstDeclaration {
//     ZtAstReference[] baseTypes;
//     ZtAstDeclaration[] members;
// }

class ZtAstAttribute : ZtAstNode {
    string name;
    ZtAstExpression[] arguments;
}

class ZtAstIf : ZtAstDeclaration {
    ZtAstExpression condition;
    ZtAstStatement[] members;
    ZtAstStatement[] elseMembers;
}

class ZtAstSwitch : ZtAstStatement {
    ZtAstExpression condition;
    ZtAstCase[] members;
}

class ZtAstCase : ZtAstStatement {
    ZtAstExpression[] conditions;
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
    ZtAstDef definition;
    ZtAstExpression condition;
    ZtAstExpression step;
    ZtAstStatement[] members;
}

class ZtAstForeach : ZtAstDeclaration {
    ZtAstDef[] definitions;
    ZtAstExpression aggregate;
    ZtAstStatement[] members;
}

class ZtAstWith : ZtAstStatement {
    ZtAstExpression aggregate;
    ZtAstReference castType;
    ZtAstStatement[] members;
}

class ZtAstReturn : ZtAstStatement {
    ZtAstExpression expression;
}

class ZtAstBreak : ZtAstStatement {
    ZtAstExpression expression;
}

class ZtAstContinue : ZtAstStatement {
    ZtAstExpression expression;
}

class ZtAstExpressionStatement : ZtAstStatement {
    ZtAstExpression expression;
}

class ZtAstIdentifier : ZtAstReference {
    string name;
}

class ZtAstDispatch : ZtAstReference {
    ZtAstExpression lhs;
    string name;
}

class ZtAstSubscript : ZtAstReference {
    ZtAstExpression lhs;
    ZtAstExpression[] arguments;
}

class ZtAstTypeOf : ZtAstReference {
    ZtAstExpression expression;
}

class ZtAstLogical : ZtAstExpression {
    enum Operator : string {
        and = ZtToken.Type.op_logicalAnd,
        or = ZtToken.Type.op_logicalOr,
        xor = ZtToken.Type.op_logicalXor,
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
    enum Operator : string {
        add = ZtToken.Type.op_plus,
        subtract = ZtToken.Type.op_minus,
        multiply = ZtToken.Type.op_multiply,
        divide = ZtToken.Type.op_divide,
        modulo = ZtToken.Type.op_modulo,
        concat = ZtToken.Type.op_tilde,
        bitAnd = ZtToken.Type.op_bitAnd,
        bitOr = ZtToken.Type.op_bitOr,
        bitXor = ZtToken.Type.op_bitXor,
        bitShiftLeft = ZtToken.Type.op_shiftLeft,
        bitShiftRight = ZtToken.Type.op_shiftRight,
    }

    ZtAstExpression lhs, rhs;
    Operator operator;
}

class ZtAstUnary : ZtAstExpression {
    enum Operator : string {
        increment = ZtToken.Type.op_increment,
        decrement = ZtToken.Type.op_decrement,
        positive = ZtToken.Type.op_plus,
        negative = ZtToken.Type.op_minus,
        not = ZtToken.Type.op_not,
        bitNot = ZtToken.Type.op_tilde
    }

    ZtAstExpression rhs;
    Operator operator;
    bool isPostOp;
}

class ZtAstAssign : ZtAstExpression {
    ZtAstExpression lhs, rhs;
    ZtAstBinary.Operator operator;
    bool isPlainAssign;
}

class ZtAstTrinaryOperator : ZtAstExpression {
    ZtAstExpression condition, lhs, rhs;
}

class ZtAstCall : ZtAstExpression {
    ZtAstExpression lhs;
    ZtAstExpression[] arguments;
}

class ZtAstApply : ZtAstExpression {
    ZtAstExpression lhs;
    string name;
}

class ZtAstCast : ZtAstExpression {
    ZtAstReference type;
    ZtAstExpression rhs;
}

class ZtAstIs : ZtAstExpression {
    ZtAstExpression lhs, rhs;
}

class ZtAstNew : ZtAstExpression {
    ZtAstReference type;
    ZtAstExpression[] arguments;
}

class ZtAstArray : ZtAstExpression {
    ZtAstExpression[] expressions;
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
