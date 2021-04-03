/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.integer;

import std.conv;
import std.format;
import zeta.type.value;
import zeta.type.floating;

class ZtInt : ZtValue {
    size_t number;
    
    this(){}
    this(size_t number) {
        this.number = number;
    }
    override bool toBool() {
        return number != 0;
    }
    
    override ZtValue clone() {
        return new ZtInt(number);
    }
    
    override bool equals(ZtValue var) {
        if (auto num = cast(ZtFloat)var)
            return number==num.number;
        else if (auto num = cast(ZtInt)var)
            return number==num.number;
        else
            return false;
    }
    
    override string type() const {
        return "integer";
    }
    
    override string toString() const {
        return text(number);
    }
    
    override ZtValue add(ZtValue var) {
        if (auto num = cast(ZtInt)var)
            return new ZtInt(number+num.number);
        else if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number+num.number);
        else
            assert(0, format("Cannot add %s and %s",type,var.type));
    }
    override ZtValue sub(ZtValue var) {
        if (auto num = cast(ZtInt)var)
            return new ZtInt(number-num.number);
        else if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number-num.number);
        else
            assert(0, format("Cannot subtract %s and %s",type,var.type));
    }
    override ZtValue mul(ZtValue var) {
        if (auto num = cast(ZtInt)var)
            return new ZtInt(number*num.number);
        else if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number*num.number);
        else
            assert(0, format("Cannot multiply %s and %s",type,var.type));
    }
    override ZtValue div(ZtValue var) {
        if (auto num = cast(ZtInt)var)
            return new ZtFloat(number/num.number);
        else if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number/num.number);
        else
            assert(0, format("Cannot divide %s and %s",type,var.type));
    }
    override ZtValue mod(ZtValue var) {
        if (auto num = cast(ZtInt)var)
            return new ZtInt(number%num.number);
        else if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number%num.number);
        else
            assert(0, format("Cannot modulo %s and %s",type,var.type));
    }
    
    override ZtValue pos() {
        return new ZtInt(number > 0 ? number : -number);
    }
    
    override ZtValue neg() {
        return new ZtInt(-number);
    }
    
    override void inc() {
        number++;
    }
    override void dec() {
        number--;
    }
    
    override bool greater(ZtValue var) {
        if (auto num = cast(ZtInt)var)
            return number>num.number;
        else if (auto num = cast(ZtFloat)var)
            return number>num.number;
        else
            return false;
    }
    override bool less(ZtValue var) {
        if (auto num = cast(ZtInt)var)
            return number<num.number;
        else if (auto num = cast(ZtFloat)var)
            return number<num.number;
        else
            return false;
    }
}