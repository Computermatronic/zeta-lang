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
    ZtAstExpression subject;
    ZtAstStatement[] members;
    ZtAstStatement[] elseMembers;
}

class ZtAstSwitch : ZtAstStatement {
    ZtAstExpression subject;
    ZtAstCase[] members;
}

class ZtAstCase : ZtAstStatement {
    ZtAstExpression[] subjects;
    ZtAstStatement[] members;

    bool isElseCase;
}

class ZtAstWhile : ZtAstStatement {
    ZtAstExpression subject;
    ZtAstStatement[] members;
}

class ZtAstDoWhile : ZtAstStatement {
    ZtAstExpression subject;
    ZtAstStatement[] members;
}

class ZtAstFor : ZtAstStatement {
    ZtAstDef initializer;
    ZtAstExpression subject;
    ZtAstExpression step;
    ZtAstStatement[] members;
}

class ZtAstForeach : ZtAstDeclaration {
    ZtAstDef[] initializers;
    ZtAstExpression subject;
    ZtAstStatement[] members;
}

class ZtAstWith : ZtAstStatement {
    ZtAstExpression subject;
    ZtAstReference type;
    ZtAstStatement[] members;

    bool isCast;
}

class ZtAstReturn : ZtAstStatement {
    ZtAstExpression subject;
}

class ZtAstBreak : ZtAstStatement {
}

class ZtAstContinue : ZtAstStatement {
}

class ZtAstExpressionStatement : ZtAstStatement {
    ZtAstExpression subject;
}

class ZtAstIdentifier : ZtAstReference {
    string name;
}

class ZtAstDispatch : ZtAstReference {
    ZtAstExpression subject;
    string name;
}

class ZtAstSubscript : ZtAstReference {
    ZtAstExpression subject;
    ZtAstExpression[] arguments;
}

class ZtAstTypeOf : ZtAstReference {
    ZtAstExpression subject;
}

class ZtAstBinary : ZtAstExpression {
    enum Operator : string {
        add = ZtToken.Type.tk_plus,
        subtract = ZtToken.Type.tk_minus,
        multiply = ZtToken.Type.tk_multiply,
        divide = ZtToken.Type.tk_divide,
        modulo = ZtToken.Type.tk_modulo,
        concat = ZtToken.Type.tk_tilde,
        equal = ZtToken.Type.tk_equal,
        notEqual = ZtToken.Type.tk_notEqual,
        lessThan = ZtToken.Type.tk_lessThan,
        greaterThan = ZtToken.Type.tk_greaterThan,
        lessThanEqual = ZtToken.Type.tk_lessThanEqual,
        greaterThanEqual = ZtToken.Type.tk_greaterThanEqual,
        and = ZtToken.Type.tk_logicalAnd,
        or = ZtToken.Type.tk_logicalOr,
        xor = ZtToken.Type.tk_logicalXor,
        bitAnd = ZtToken.Type.tk_bitAnd,
        bitOr = ZtToken.Type.tk_bitOr,
        bitXor = ZtToken.Type.tk_bitXor,
        bitShiftLeft = ZtToken.Type.tk_shiftLeft,
        bitShiftRight = ZtToken.Type.tk_shiftRight,
    }

    ZtAstExpression lhs, rhs;
    Operator operator;
}

class ZtAstUnary : ZtAstExpression {
    enum Operator : string {
        increment = ZtToken.Type.tk_increment,
        decrement = ZtToken.Type.tk_decrement,
        positive = ZtToken.Type.tk_plus,
        negative = ZtToken.Type.tk_minus,
        not = ZtToken.Type.tk_not,
        bitNot = ZtToken.Type.tk_tilde,
        postIncrement = "post-increment(++)",
        postDecrement = "post-decrement(--)"
    }

    ZtAstExpression subject;
    Operator operator;
}

class ZtAstAssign : ZtAstExpression {
    enum Operator : string {
        assign = ZtToken.Type.tk_assign,
        add = ZtToken.Type.tk_assignAdd,
        subtract = ZtToken.Type.tk_assignSubtract,
        multiply = ZtToken.Type.tk_assignMultiply,
        divide = ZtToken.Type.tk_assignDivide,
        modulo = ZtToken.Type.tk_assignModulo,
        concat = ZtToken.Type.tk_assignConcat,
        and = ZtToken.Type.tk_assignAnd,
        or = ZtToken.Type.tk_assignOr,
        xor = ZtToken.Type.tk_assignXor
    }

    ZtAstExpression subject, assignment;
    Operator operator;
}

class ZtAstTrinaryOperator : ZtAstExpression {
    ZtAstExpression subject, lhs, rhs;
}

class ZtAstCall : ZtAstExpression {
    ZtAstExpression subject;
    ZtAstExpression[] arguments;
}

class ZtAstApply : ZtAstExpression {
    ZtAstExpression subject;
    string name;
}

class ZtAstCast : ZtAstExpression {
    ZtAstReference type;
    ZtAstExpression subject;
}

class ZtAstIs : ZtAstExpression {
    ZtAstExpression lhs, rhs;
}

class ZtAstNew : ZtAstExpression {
    ZtAstReference type;
    ZtAstExpression[] arguments;
}

class ZtAstArray : ZtAstExpression {
    ZtAstExpression[] members;
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
