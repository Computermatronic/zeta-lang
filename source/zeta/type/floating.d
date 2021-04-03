/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.floating;

import std.conv;
import std.format;
import zeta.type.value;
import zeta.type.integer;

class ZtFloat : ZtValue {
    real number;
    
    this(){}
    this(real number) {
        this.number = number;
    }
    override bool toBool() {
        return number !is real.nan;
    }
    
    override ZtValue clone() {
        return new ZtFloat(number);
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
        return "float";
    }
    
    override string toString() const {
        return text(number);
    }
    
    override ZtValue add(ZtValue var) {
        if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number+num.number);
        else if (auto num = cast(ZtInt)var)
            return new ZtFloat(number+num.number);
        else
            assert(0, format("Cannot add %s and %s",type,var.type));
    }
    override ZtValue sub(ZtValue var) {
        if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number-num.number);
        else if (auto num = cast(ZtInt)var)
            return new ZtFloat(number-num.number);
        else
            assert(0, format("Cannot subtract %s and %s",type,var.type));
    }
    override ZtValue mul(ZtValue var) {
        if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number*num.number);
        else if (auto num = cast(ZtInt)var)
            return new ZtFloat(number*num.number);
        else
            assert(0, format("Cannot multiply %s and %s",type,var.type));
    }
    override ZtValue div(ZtValue var) {
        if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number/num.number);
        else if (auto num = cast(ZtInt)var)
            return new ZtFloat(number/num.number);
        else
            assert(0, format("Cannot divide %s and %s",type,var.type));
    }
    override ZtValue mod(ZtValue var) {
        if (auto num = cast(ZtFloat)var)
            return new ZtFloat(number%num.number);
        else if (auto num = cast(ZtInt)var)
            return new ZtFloat(number%num.number);
        else
            assert(0, format("Cannot modulo %s and %s",type,var.type));
    }
    
    override ZtValue pos() {
        return new ZtFloat(number > 0 ? number : -number);
    }
    
    override ZtValue neg() {
        return new ZtFloat(-number);
    }
    
    override void inc() {
        number++;
    }
    override void dec() {
        number--;
    }
    
    override bool greater(ZtValue var) {
        if (auto num = cast(ZtFloat)var)
            return number>num.number;
        else if (auto num = cast(ZtInt)var)
            return number>num.number;
        else
            return false;
    }
    override bool less(ZtValue var) {
        if (auto num = cast(ZtFloat)var)
            return number<num.number;
        else if (auto num = cast(ZtInt)var)
            return number<num.number;
        else
            return false;
    }
    
    override ZtValue dispatchGet(string name) {
        switch(name) {
            case "nan":
                return new ZtFloat(real.nan);
            default:
                assert(0, format("No such field %s for %s",name,type));
        }
    }
    override void dispatchSet(string name, ZtValue var) {
        assert(0, format("Cannot set field %s for %s",name,type));
    }
    
    override ZtValue dispatchCall(string name, ZtValue[] args) {
        assert(0, format("Cannot call field %s for %s",name,type));
    }
}