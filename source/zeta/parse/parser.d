/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.parse.parser;

import std.range;
import std.traits;
import std.container.slist;

import zeta.utils;
import zeta.parse;

struct ZtParser {
    alias TokenRange = ForwardRange!ZtToken;
    mixin ErrorSink!(OnError.assert0);

    private TokenRange buffer;
    private ZtAstAttribute[] attributes;

    this(Range)(Range buffer)
            if (isForwardRange!Range && is(ElementType!Range == ZtToken)) {
        this.buffer = inputRangeObject(buffer);
        this.attributes = null;
    }

    //Node based parsing functions.
    ZtAstModule parseModule() {
        auto node = this.makeNode!ZtAstModule();
        if (this.advanceForToken(ZtToken.Type.kw_module)) {
            string[] packageName;
            do {
                packageName ~= this.expectToken(ZtToken.Type.ud_identifier).lexeme;
            }
            while (!this.isEof && this.advanceForToken(ZtToken.Type.tk_dot));
            node.name = packageName[$ - 1];
            node.packageName = packageName[0 .. $ - 1];
            this.expectToken(ZtToken.Type.tk_semicolon);
        } else {
            import std.path : baseName, stripExtension;

            node.name = node.location.file.baseName().stripExtension();
        }
        while (!this.isEof) {
            node.members ~= this.parseDeclaration();
        }
        return node;
    }

private:
    // ZtAstAlias parseAlias() {
    //     auto node = this.makeNode!ZtAstAlias(ZtToken.Type.kw_alias);
    //     if (this.advanceForToken(ZtToken.Type.tk_colon))
    //         node.type = this.parseReference();
    //     node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     this.expectToken(ZtToken.Type.op_assign);
    //     node.initializer = this.parseExpression();
    //     this.expectToken(ZtToken.Type.tk_semicolon);
    //     return node;
    // }

    ZtAstDef[] parseDef() {
        ZtAstDef[] defs = [this.parseDefParameter()];
        if (this.advanceForToken(ZtToken.Type.tk_comma))
            defs ~= parseList!parseDefBody(defs[0].type);
        this.expectToken(ZtToken.Type.tk_semicolon);
        return defs;
    }

    ZtAstDef parseDefBody(ZtAstReference type) {
        auto node = this.makeNode!ZtAstDef();
        node.type = type;
        node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
        if (this.advanceForToken(ZtToken.Type.op_assign))
            node.initializer = this.parseExpression();
        return node;
    }

    ZtAstImport parseImport() {
        auto node = this.makeNode!ZtAstImport(ZtToken.Type.kw_import);
        string[] fullName;
        do {
            fullName ~= this.expectToken(ZtToken.Type.ud_identifier).lexeme;
        }
        while (!this.isEof && this.advanceForToken(ZtToken.Type.tk_dot));
        node.name = fullName[$ - 1];
        node.packageName = fullName[0 .. $ - 1];
        this.expectToken(ZtToken.Type.tk_semicolon);
        return node;
    }

    ZtAstFunction parseFunction() {
        auto node = this.makeNode!ZtAstFunction(ZtToken.Type.kw_function);
        if (this.advanceForToken(ZtToken.Type.tk_colon))
            node.type = this.parseReference();
        node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
        auto paramaters = this.parseParamaters!parseDefParameter();
        node.paramaters = paramaters[0];
        node.isVariadic = paramaters[1];
        if (this.advanceForToken(ZtToken.Type.tk_semicolon))
            node.isLinkage = true;
        else
            node.members = this.parseBlock!parseStatement();
        return node;
    }

    // ZtAstTemplate parseTemplate() {
    //     auto node = this.makeNode!ZtAstTemplate(ZtToken.Type.kw_template);
    //     if (!this.testForToken(ZtToken.Type.ud_identifier))
    //         node.isAnonymous = true;
    //     else
    //         node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     auto paramaters = this.parseParamaters!parseTemplateParamater();
    //     node.paramaters = paramaters[0];
    //     node.isVariadic = paramaters[1];
    //     if (node.isAnonymous)
    //         node.members ~= this.parseDeclaration();
    //     else
    //         node.members ~= this.parseBlock!parseDeclaration();
    //     return node;
    // }

    ZtAstDef parseDefParameter() {
        ZtAstReference type;
        this.expectToken(ZtToken.Type.kw_def);
        if (this.advanceForToken(ZtToken.Type.tk_colon))
            type = this.parseReference();
        return parseDefBody(type);
    }

    // ZtAstTypeParamater parseTypeParamater() {
    //     auto node = this.makeNode!ZtAstTypeParamater();
    //     node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     if (this.advanceForToken(ZtToken.Type.tk_colon))
    //         node.type = this.parseReference();
    //     if (this.advanceForToken(ZtToken.Type.op_assign))
    //         node.initializer = this.parseReference();
    //     return node;
    // }

    // ZtAstAliasParamater parseAliasParamater() {
    //     auto node = this.makeNode!ZtAstAliasParamater(ZtToken.Type.kw_alias);
    //     if (this.advanceForToken(ZtToken.Type.tk_colon))
    //         node.type = this.parseReference();
    //     node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     if (this.advanceForToken(ZtToken.Type.op_assign))
    //         node.initializer = this.parseExpression();
    //     return node;
    // }

    // ZtAstEnum parseEnum() {
    //     auto node = this.makeNode!ZtAstEnum(ZtToken.Type.kw_enum);
    //     if (this.advanceForToken(ZtToken.Type.tk_colon))
    //         node.type = this.parseReference();
    //     node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     this.expectToken(ZtToken.Type.tk_leftBrace);
    //     node.members = this.parseList!parseEnumMember();
    //     this.expectToken(ZtToken.Type.tk_rightBrace);
    //     return node;
    // }

    // ZtAstEnumMember parseEnumMember() {
    //     auto node = this.makeNode!ZtAstEnumMember();
    //     node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     if (this.advanceForToken(ZtToken.Type.op_assign))
    //         node.initializer = this.parseExpression();
    //     return node;
    // }

    // ZtAstStruct parseStruct() {
    //     auto node = this.makeNode!ZtAstStruct(ZtToken.Type.kw_struct);
    //     node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     if (this.advanceForToken(ZtToken.Type.tk_colon))
    //         node.baseTypes = this.parseList!parseReference();
    //     if (this.advanceForToken(ZtToken.Type.tk_semicolon))
    //         node.isLinkage = true;
    //     else
    //         node.members = this.parseBlock!parseDeclaration();
    //     return node;
    // }

    // ZtAstClass parseClass() {
    //     auto node = this.makeNode!ZtAstClass(ZtToken.Type.kw_class);
    //     node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     if (this.advanceForToken(ZtToken.Type.tk_colon))
    //         node.baseTypes = this.parseList!parseReference();
    //     else
    //         node.members = this.parseBlock!parseDeclaration();
    //     return node;
    // }

    // ZtAstInterface parseInterface() {
    //     auto node = this.makeNode!ZtAstInterface(ZtToken.Type.kw_interface);
    //     node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
    //     if (this.advanceForToken(ZtToken.Type.tk_colon))
    //         node.baseTypes = this.parseList!parseReference();
    //     else
    //         node.members = this.parseBlock!parseDeclaration();
    //     return node;
    // }

    ZtAstIf parseIf() {
        auto node = this.makeNode!ZtAstIf(ZtToken.Type.kw_if);
        this.expectToken(ZtToken.Type.tk_leftParen);
        node.condition = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_rightParen);
        node.members = this.parseBlock!parseStatement();
        if (this.advanceForToken(ZtToken.Type.kw_else))
            node.elseMembers = this.parseBlock!parseStatement();
        return node;
    }

    ZtAstSwitch parseSwitch() {
        auto node = this.makeNode!ZtAstSwitch(ZtToken.Type.kw_switch);
        this.expectToken(ZtToken.Type.tk_leftParen);
        node.condition = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_rightParen);
        node.members = this.parseBlock!parseCase();
        return node;
    }

    ZtAstCase parseCase() {
        auto node = this.makeNode!ZtAstCase(ZtToken.Type.kw_case);
        if (this.advanceForToken(ZtToken.Type.kw_else)) {
            node.isElseCase = true;
        } else {
            // this.expectToken(ZtToken.Type.tk_leftParen);
            node.matches = this.parseList!parseExpression();
            // this.expectToken(ZtToken.Type.tk_rightParen);
        }
        this.expectToken(ZtToken.Type.tk_colon);
        while (!this.testForToken(ZtToken.Type.kw_case)
                && !this.testForToken(ZtToken.Type.tk_rightBrace)) {
            node.members ~= this.parseStatement();
        }
        return node;
    }

    ZtAstWhile parseWhile() {
        auto node = this.makeNode!ZtAstWhile(ZtToken.Type.kw_while);
        this.expectToken(ZtToken.Type.tk_leftParen);
        node.condition = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_rightParen);
        node.members = this.parseBlock!parseStatement();
        return node;
    }

    ZtAstDoWhile parseDoWhile() {
        auto node = this.makeNode!ZtAstDoWhile(ZtToken.Type.kw_do);
        node.members = this.parseBlock!parseStatement();
        this.expectToken(ZtToken.Type.kw_while);
        this.expectToken(ZtToken.Type.tk_leftParen);
        node.condition = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_rightParen);
        return node;
    }

    ZtAstFor parseFor() {
        auto node = this.makeNode!ZtAstFor(ZtToken.Type.kw_for);
        this.expectToken(ZtToken.Type.tk_leftParen);
        if (this.testForToken(ZtToken.Type.kw_def))
            node.initializer = this.parseDefParameter();
        this.expectToken(ZtToken.Type.tk_semicolon);
        if (!this.testForToken(ZtToken.Type.tk_semicolon))
            node.condition = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_semicolon);
        if (!this.testForToken(ZtToken.Type.tk_leftParen))
            node.step = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_rightParen);
        node.members = this.parseBlock!parseStatement();
        return node;
    }

    ZtAstForeach parseForeach() {
        auto node = this.makeNode!ZtAstForeach(ZtToken.Type.kw_foreach);
        this.expectToken(ZtToken.Type.tk_leftParen);
        node.initializers = this.parseList!parseDefParameter();
        this.expectToken(ZtToken.Type.tk_semicolon);
        node.aggregate = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_rightParen);
        node.members = this.parseBlock!parseStatement();
        return node;
    }

    ZtAstWith parseWith() {
        auto node = this.makeNode!ZtAstWith(ZtToken.Type.kw_with);
        if (this.advanceForToken(ZtToken.Type.tk_colon))
            node.type = this.parseReference();
        this.expectToken(ZtToken.Type.tk_leftParen);
        node.aggregate = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_rightParen);
        node.members = this.parseBlock!parseStatement();
        return node;
    }

    ZtAstDelete parseDelete() {
        auto node = this.makeNode!ZtAstDelete(ZtToken.Type.kw_delete);
        if (!this.testForToken(ZtToken.Type.tk_semicolon))
            node.expression = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_semicolon);
        return node;
    }

    ZtAstReturn parseReturn() {
        auto node = this.makeNode!ZtAstReturn(ZtToken.Type.kw_return);
        if (!this.testForToken(ZtToken.Type.tk_semicolon))
            node.expression = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_semicolon);
        return node;
    }

    ZtAstBreak parseBreak() {
        auto node = this.makeNode!ZtAstBreak(ZtToken.Type.kw_break);
        //if (!this.testForToken(ZtToken.Type.tk_semicolon)) node.subject = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_semicolon);
        return node;
    }

    ZtAstContinue parseContinue() {
        auto node = this.makeNode!ZtAstContinue(ZtToken.Type.kw_continue);
        //if (!this.testForToken(ZtToken.Type.tk_semicolon)) node.subject = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_semicolon);
        return node;
    }

    ZtAstExpressionStatement parseExpressionStatement() {
        auto node = this.makeNode!ZtAstExpressionStatement();
        node.expression = this.parseExpression();
        this.expectToken(ZtToken.Type.tk_semicolon);
        return node;
    }

    ZtAstAttribute parseAttribute() { //TODO: implement @attribute:
        auto node = this.makeNode!ZtAstAttribute();
        node.name = this.expectToken(ZtToken.Type.ud_attribute).lexeme;
        if (this.advanceForToken(ZtToken.Type.tk_leftParen)) {
            node.arguments = this.parseList!parseExpression();
            this.expectToken(ZtToken.Type.tk_rightParen);
        }
        return node;
    }

    //Category based parsing functions.
    ZtAstStatement[] parseStatement() {
    nextStatement:
        switch (buffer.front.type) with (ZtToken.Type) {
        case kw_enum, kw_alias, kw_def, kw_function, kw_template, kw_struct, kw_class,
                kw_interface, kw_import:
                return cast(ZtAstStatement[]) this.parseDeclaration();
        case kw_if:
            return [this.parseIf()];
        case kw_switch:
            return [this.parseSwitch()];
        case kw_case:
            return [this.parseCase()];
        case kw_for:
            return [this.parseFor()];
        case kw_foreach:
            return [this.parseForeach()];
        case kw_while:
            return [this.parseWhile()];
        case kw_do:
            return [this.parseDoWhile()];
        case kw_with:
            return [this.parseWith()];
        case kw_return:
            return [this.parseReturn()];
        case kw_break:
            return [this.parseBreak()];
        case kw_continue:
            return [this.parseContinue()];
        case ud_attribute:
            this.parseAttributes();
            goto nextStatement;
        default:
            return [this.parseExpressionStatement()];
        }
    }

    ZtAstDeclaration[] parseDeclaration() {
    nextDeclaration:
        switch (buffer.front.type) with (ZtToken.Type) {
        // case kw_enum:
        //     return [this.parseEnum()];
        // case kw_alias:
        //     return [this.parseAlias()];
        case kw_def:
            return cast(ZtAstDeclaration[]) this.parseDef();
        case kw_function:
            return [this.parseFunction()];
        // case kw_template:
        //     return [this.parseTemplate()];
        // case kw_struct:
        //     return [this.parseStruct()];
        // case kw_class:
        //     return [this.parseClass()];
        // case kw_interface:
        //     return [this.parseInterface()];
        case kw_import:
            return [this.parseImport()];
        case ud_attribute:
            this.parseAttributes();
            goto nextDeclaration;
        default:
            error(buffer.front.location, "Unrecognized declaration %s", buffer.front.lexeme);
            this.takeFront();
            return null;
        }
    }

    ZtAstExpression parseExpression(int precedence = int.max) {
        ZtAstExpression expression;

        switch (buffer.front.type) with (ZtToken.Type) {
        case ud_identifier:
            auto node = this.makeNode!ZtAstIdentifier();
            node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
            expression = node;
            break;

        case tk_leftParen:
            this.expectToken(ZtToken.Type.tk_leftParen);
            auto arguments = this.parseList!parseExpression();
            this.expectToken(ZtToken.Type.tk_rightParen);
            //Unwrap tuples of 1 value since that's just a parenthesized expression.
            if (arguments.length == 1) {
                expression = arguments[0];
            } else {
                error(arguments[0].location, "Tuples not supported!");
                // auto node = this.makeNode!ZtAstTuple();
                // node.arguments = arguments;
                // expression = node;
            }
            break;

        case kw_typeof:
            auto node = this.makeNode!ZtAstTypeOf(ZtToken.Type.kw_typeof);
            this.expectToken(ZtToken.Type.tk_leftParen);
            node.expression = this.parseExpression();
            this.expectToken(ZtToken.Type.tk_rightParen);
            expression = node;
            break;

        case op_asterisk, op_ampersand:
            auto node = this.makeNode!ZtAstUnary();
            node.operator = cast(ZtAstUnary.Operator) this.takeFront().type;
            node.expression = this.parseExpression(Precedence.unaryPointerOperator);
            expression = node;
            break;

        case op_plus, op_minus:
            auto node = this.makeNode!ZtAstUnary();
            node.operator = cast(ZtAstUnary.Operator) this.takeFront().type;
            node.expression = this.parseExpression(Precedence.unaryNegationOperator);
            expression = node;
            break;

        case op_increment, op_decrement:
            auto node = this.makeNode!ZtAstUnary();
            node.operator = cast(ZtAstUnary.Operator) this.takeFront().type;
            node.expression = this.parseExpression(Precedence.unaryIncrementOperator);
            expression = node;
            break;

        case kw_if:
            auto node = this.makeNode!ZtAstTrinary(ZtToken.Type.kw_if);
            this.expectToken(ZtToken.Type.tk_leftParen);
            node.condition = this.parseExpression();
            this.expectToken(ZtToken.Type.tk_rightParen);
            node.lhs = this.parseExpression();
            this.expectToken(ZtToken.Type.kw_else);
            node.rhs = this.parseExpression();
            break;

        case kw_cast:
            auto node = this.makeNode!ZtAstCast(ZtToken.Type.kw_cast);
            this.expectToken(ZtToken.Type.tk_colon);
            node.type = this.parseReference();
            this.expectToken(ZtToken.Type.tk_leftParen);
            node.expression = this.parseExpression();
            this.expectToken(ZtToken.Type.tk_rightParen);
            expression = node;
            break;

        case kw_new:
            auto node = this.makeNode!ZtAstNew(ZtToken.Type.kw_new);
            this.expectToken(ZtToken.Type.tk_colon);
            node.type = this.parseReference();
            this.expectToken(ZtToken.Type.tk_leftParen);
            if (!this.testForToken(ZtToken.Type.tk_rightParen))
                node.arguments = this.parseList!parseExpression();
            this.expectToken(ZtToken.Type.tk_rightParen);
            expression = node;
            break;

        case tk_leftBracket:
            auto node = this.makeNode!ZtAstArray(ZtToken.Type.tk_leftBracket);
            if (!this.testForToken(ZtToken.Type.tk_rightParen))
                node.arguments = this.parseList!parseExpression();
            this.expectToken(ZtToken.Type.tk_rightBracket);
            expression = node;
            break;

        case ud_string:
            auto node = this.makeNode!ZtAstString();
            node.literal = this.expectToken(ZtToken.Type.ud_string).literal.get!string;
            expression = node;
            break;

        case ud_char:
            auto node = this.makeNode!ZtAstChar();
            node.literal = this.expectToken(ZtToken.Type.ud_char).literal.get!dchar;
            expression = node;
            break;

        case ud_integer:
            auto node = this.makeNode!ZtAstInteger();
            node.literal = this.expectToken(ZtToken.Type.ud_integer).literal.get!long;
            expression = node;
            break;

        case ud_float:
            auto node = this.makeNode!ZtAstFloat();
            node.literal = this.expectToken(ZtToken.Type.ud_float).literal.get!double;
            expression = node;
            break;

        default:
            error(buffer.front.location, "Unrecognized expression %s", buffer.front.lexeme);
            this.takeFront();
            return null;
        }

    nextExpression:
        switch (buffer.front.type) with (ZtToken.Type) {
        case ZtToken.Type.tk_dot:
            if (Precedence.dispatch > precedence)
                break;
            auto node = this.makeNode!ZtAstDispatch(ZtToken.Type.tk_dot);
            node.expression = expression;
            node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
            expression = node;
            goto nextExpression;

        case tk_leftBracket:
            if (Precedence.subscript > precedence)
                break;
            auto node = this.makeNode!ZtAstSubscript(ZtToken.Type.tk_leftBracket);
            node.expression = expression;
            if (!this.testForToken(ZtToken.Type.tk_rightBracket))
                node.arguments = this.parseList!parseExpression();
            this.expectToken(ZtToken.Type.tk_rightBracket);
            expression = node;
            goto nextExpression;

        // case tk_colon:
        //     if (Precedence.templateInstance > precedence)
        //         break;
        //     auto node = this.makeNode!ZtAstTemplateInstance(ZtToken.Type.tk_colon);
        //     node.expression = expression;
        //     if (this.advanceForToken(ZtToken.Type.tk_leftParen)) {
        //         if (!this.testForToken(ZtToken.Type.tk_rightParen))
        //             node.arguments = this.parseList!parseExpression();
        //         this.expectToken(ZtToken.Type.tk_rightParen);
        //     } else {
        //         node.arguments ~= this.parseExpression();
        //     }
        //     expression = node;
        //     goto nextExpression;

        case op_asterisk:
            // auto next = buffer.save.take(2).array[$ - 1].type;
            // if (ud_identifier != next && ud_string != next && ud_char != next && ud_integer != next
            //         && ud_float != next && tk_leftParen != next
            //         && op_increment != next && op_decrement != next && op_plus != next
            //         && op_minus != next && op_ampersand != next && op_asterisk != next && op_not != next
            //         && op_tilde != next && kw_new != next && cast(ZtAstReference) expression !is null) {
            //     auto node = this.makeNode!ZtAstPointerType(ZtToken.Type.op_asterisk);
            //     node.baseType = cast(ZtAstReference) expression;
            //     expression = node;
            //     goto nextExpression;
            // } else
                goto case;

        case op_slash, op_percent:
            if (Precedence.multiplacativeOperator > precedence)
                break;
            auto node = this.makeNode!ZtAstBinary();
            node.lhs = expression;
            node.operator = cast(ZtAstBinary.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.multiplacativeOperator);
            expression = node;
            goto nextExpression;

        case op_plus, op_minus:
            if (Precedence.additiveOperator > precedence)
                break;
            auto node = this.makeNode!ZtAstBinary();
            node.lhs = expression;
            node.operator = cast(ZtAstBinary.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.additiveOperator);
            expression = node;
            goto nextExpression;

        case op_greaterThan, op_lessThan, op_greaterThanEqual, op_lessThanEqual:
            if (Precedence.comparativeOperator > precedence)
                break;
            auto node = this.makeNode!ZtAstLogical();
            node.lhs = expression;
            node.operator = cast(ZtAstLogical.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.comparativeOperator);
            expression = node;
            goto nextExpression;

        case op_equal, op_notEqual:
            if (Precedence.equityOperator > precedence)
                break;
            auto node = this.makeNode!ZtAstLogical();
            node.lhs = expression;
            node.operator = cast(ZtAstLogical.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.equityOperator);
            expression = node;
            goto nextExpression;

        case op_shiftLeft, op_shiftRight:
            if (Precedence.bitShiftOperator > precedence)
                break;
            auto node = this.makeNode!ZtAstBinary();
            node.lhs = expression;
            node.operator = cast(ZtAstBinary.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.bitShiftOperator);
            expression = node;
            goto nextExpression;

        case op_ampersand:
            if (Precedence.bitAnd > precedence)
                break;
            auto node = this.makeNode!ZtAstLogical();
            node.lhs = expression;
            node.operator = cast(ZtAstLogical.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.bitAnd);
            expression = node;
            goto nextExpression;

        case op_poll:
            if (Precedence.bitOr > precedence)
                break;
            auto node = this.makeNode!ZtAstLogical();
            node.lhs = expression;
            node.operator = cast(ZtAstLogical.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.bitOr);
            expression = node;
            goto nextExpression;

        case op_and:
            if (Precedence.and > precedence)
                break;
            auto node = this.makeNode!ZtAstBinary();
            node.lhs = expression;
            node.operator = cast(ZtAstBinary.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.and);
            expression = node;
            goto nextExpression;

        case op_or:
            if (Precedence.or > precedence)
                break;
            auto node = this.makeNode!ZtAstBinary();
            node.lhs = expression;
            node.operator = cast(ZtAstBinary.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.or);
            expression = node;
            goto nextExpression;

        case op_xor:
            if (Precedence.xor > precedence)
                break;
            auto node = this.makeNode!ZtAstBinary();
            node.lhs = expression;
            node.operator = cast(ZtAstBinary.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.xor);
            expression = node;
            goto nextExpression;

        case op_tilde, tk_slice:
            if (Precedence.concat > precedence)
                break;
            auto node = this.makeNode!ZtAstBinary();
            node.lhs = expression;
            node.operator = cast(ZtAstBinary.Operator) this.takeFront().type;
            node.rhs = this.parseExpression(Precedence.concat);
            expression = node;
            goto nextExpression;

        case op_increment, op_decrement:
            if (Precedence.unaryPostIncrementOperator > precedence)
                break;
            auto node = this.makeNode!ZtAstUnary();
            node.operator = cast(ZtAstUnary.Operator) this.takeFront().type;
            node.isPostOp = true;
            node.expression = expression;
            expression = node;
            break;

        case op_assign:
            if (Precedence.assignmentOperator > precedence)
                break;
            auto node = this.makeNode!ZtAstAssign();
            node.lhs = expression;
            node.operator = ZtAstBinary.Operator.no_op;
            this.takeFront();
            node.rhs = this.parseExpression(Precedence.assignmentOperator);
            expression = node;
            goto nextExpression;

        case op_assignAdd, op_assignSubtract, op_assignMultiply,
                op_assignDivide, op_assignModulo, op_assignConcat, op_assignBitAnd,
                op_assignBitOr, op_assignBitXor:
                if (Precedence.assignmentOperator > precedence) break;
            auto node = this.makeNode!ZtAstAssign();
            node.lhs = expression;
            node.operator = cast(ZtAstBinary.Operator)(this.takeFront().type[0 .. $ - 1]);
            node.rhs = this.parseExpression(Precedence.assignmentOperator);
            expression = node;
            goto nextExpression;

        case tk_leftParen:
            if (Precedence.call > precedence)
                break;
            auto node = this.makeNode!ZtAstCall(ZtToken.Type.tk_leftParen);
            node.expression = expression;
            if (!this.testForToken(ZtToken.Type.tk_rightParen))
                node.arguments = this.parseList!parseExpression();
            this.expectToken(ZtToken.Type.tk_rightParen);
            expression = node;
            goto nextExpression;

        case tk_apply:
            if (Precedence.apply > precedence)
                break;
            auto node = this.makeNode!ZtAstApply(ZtToken.Type.tk_apply);
            node.expression = expression;
            node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
            goto nextExpression;

        case kw_is:
            if (Precedence.is_ > precedence)
                break;
            auto node = this.makeNode!ZtAstIs(ZtToken.Type.kw_is);
            node.lhs = expression;
            node.rhs = this.parseExpression(Precedence.is_);
            goto nextExpression;

        default:
            break;
        }
        return expression;
    }

    ZtAstReference parseReference(int precedence = int.max) {
        ZtAstReference reference;

        switch (buffer.front.type) with (ZtToken.Type) {
        case ud_identifier:
            auto node = this.makeNode!ZtAstIdentifier();
            node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
            reference = node;
            break;

        case tk_leftParen:
            this.expectToken(ZtToken.Type.tk_leftParen);
            auto arguments = this.parseList!parseReference();
            this.expectToken(ZtToken.Type.tk_rightParen);
            //Unwrap tuples of 1 value since that's just a parenthesized expression.
            if (arguments.length == 1) {
                reference = arguments[0];
            } else {
                error(arguments[0].location, "Tuples not supported!");
                // auto node = this.makeNode!ZtAstTuple();
                // node.arguments = cast(ZtAstExpression[]) arguments;
                // reference = node;
            }
            break;

        case kw_typeof:
            auto node = this.makeNode!ZtAstTypeOf(ZtToken.Type.kw_typeof);
            this.expectToken(ZtToken.Type.tk_leftParen);
            node.expression = this.parseExpression();
            this.expectToken(ZtToken.Type.tk_rightParen);
            reference = node;
            break;
        default:
            error(buffer.front.location, "Unrecognized expression %s", buffer.front.lexeme);
            this.takeFront();
            return null;
        }

    nextReference:
        switch (buffer.front.type) with (ZtToken.Type) {
        case ZtToken.Type.tk_dot:
            if (Precedence.dispatch > precedence)
                break;
            auto node = this.makeNode!ZtAstDispatch(ZtToken.Type.tk_dot);
            node.expression = reference;
            node.name = this.expectToken(ZtToken.Type.ud_identifier).lexeme;
            reference = node;
            goto nextReference;

        case tk_leftBracket:
            if (Precedence.subscript > precedence)
                break;
            auto node = this.makeNode!ZtAstSubscript(ZtToken.Type.tk_leftBracket);
            node.expression = reference;
            if (!this.testForToken(ZtToken.Type.tk_rightBracket))
                node.arguments = cast(ZtAstExpression[]) this.parseList!parseReference();
            this.expectToken(ZtToken.Type.tk_rightBracket);
            reference = node;
            goto nextReference;

        // case tk_colon:
        //     if (Precedence.templateInstance > precedence)
        //         break;
        //     auto node = this.makeNode!ZtAstTemplateInstance(ZtToken.Type.tk_colon);
        //     node.expression = reference;
        //     if (this.advanceForToken(ZtToken.Type.tk_leftParen)) {
        //         node.arguments = this.parseList!parseExpression();
        //         this.expectToken(ZtToken.Type.tk_rightParen);
        //     } else {
        //         node.arguments ~= this.parseReference();
        //     }
        //     reference = node;
        //     goto nextReference;

        // case op_asterisk:
        //     auto node = this.makeNode!ZtAstPointerType(ZtToken.Type.op_asterisk);
        //     node.baseType = cast(ZtAstReference) reference;
        //     reference = node;
        //     goto nextReference;

        default:
            break;
        }
        return reference;
    }

    // ZtAstDeclaration parseTemplateParamater() {
    //     switch (buffer.front.type) with (ZtToken.Type) {
    //     case ZtToken.Type.ud_identifier:
    //         return this.parseTypeParamater();
    //     case ZtToken.Type.kw_alias:
    //         return this.parseAliasParamater();
    //     case ZtToken.Type.kw_def:
    //         return this.parseDefParameter();
    //     default:
    //         error(buffer.front.location, "Unrecognized declaration %s", buffer.front.lexeme);
    //         this.takeFront();
    //         return null;
    //     }
    // }

    //Syntactic group based parsing functions.

    auto parseBlock(alias func)() {
        import std.traits : ReturnType;

        static if (isArray!(ReturnType!(func)))
            ReturnType!(func) block;
        else
            ReturnType!(func)[] block;
        if (this.advanceForToken(ZtToken.Type.tk_leftBrace)) {
            do {
                block ~= func();
            }
            while (!this.isEof && !this.testForToken(ZtToken.Type.tk_rightBrace));
            this.expectToken(ZtToken.Type.tk_rightBrace);
        } else {
            block ~= func();
        }
        return block;
    }

    auto parseList(alias func, Args...)(Args args) {
        import std.traits : ReturnType;

        ReturnType!(func)[] list;
        do {
            list ~= func(args);
        }
        while (!this.isEof && this.advanceForToken(ZtToken.Type.tk_comma));
        return list;
    }

    auto parseParamaters(alias func)() {
        import std.traits : ReturnType;
        import std.typecons : tuple;

        ReturnType!(func)[] paramaters;
        bool isVariadic;
        this.expectToken(ZtToken.Type.tk_leftParen);
        if (!this.advanceForToken(ZtToken.Type.tk_rightParen)) {
            paramaters = this.parseList!func();
            if (this.advanceForToken(ZtToken.Type.tk_variadic))
                isVariadic = true;
            this.expectToken(ZtToken.Type.tk_rightParen);
        }
        return tuple(paramaters, isVariadic);
    }

    void parseAttributes() {
        while (this.testForToken(ZtToken.Type.ud_attribute)) {
            this.attributes ~= this.parseAttribute();
        }
    }

    bool testForToken(ZtToken.Type tokenType) {
        return buffer.front.type == tokenType;
    }

    bool advanceForToken(ZtToken.Type tokenType) {
        if (buffer.front.type == tokenType) {
            this.takeFront();
            return true;
        } else {
            return false;
        }
    }

    ZtToken expectToken(ZtToken.Type tokenType) {
        if (buffer.front.type != tokenType)
            error(buffer.front.location, "Expected %s, got '%s'", tokenType, buffer.front.lexeme);
        return this.takeFront;
    }

    ZtToken takeFront() {
        if (!this.isEof)
            return buffer.stealFront;
        else
            return buffer.front;
    }

    @property bool isEof() {
        return buffer.empty || buffer.front.type == ZtToken.Type.eof;
    }

    Type makeNode(Type)() {
        auto node = new Type();
        static if (is(Type : ZtAstStatement)) {
            if (this.testForToken(ZtToken.Type.ud_attribute))
                this.parseAttributes();
            node.attributes = this.attributes;
            this.attributes = null;
        }
        node.location = buffer.front.location;
        return node;
    }

    Type makeNode(Type)(ZtToken.Type tokenType) {
        auto result = makeNode!Type();
        this.expectToken(tokenType);
        return result;
    }
}

enum Precedence {
    dispatch,
    is_,
    apply,
    templateInstance,
    call,
    subscript,
    unaryPointerOperator,
    unaryNegationOperator,
    unaryIncrementOperator,
    unaryPostIncrementOperator,
    multiplacativeOperator,
    additiveOperator,
    comparativeOperator,
    equityOperator,
    bitShiftOperator,
    bitAnd,
    bitOr,
    bitXor,
    and,
    or,
    xor,
    concat,
    trinary,
    assignmentOperator
}
