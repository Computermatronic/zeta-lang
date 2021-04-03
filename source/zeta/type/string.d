/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.string;

import std.conv;
import std.format;
import std.array;
import zeta.type.value;
import zeta.type.integer;
import zeta.type.array;

class ZtString : ZtValue {
    char[] text;
    
    this(){}
    this(string text) {
        this.text = cast(char[])text;
    }
    this(char[] text) {
        this.text = text;
    }
    
    override bool equals(ZtValue var) {
        if (auto str = cast(ZtString)var)
            return text==str.text;
        else
            return false;
    }
    
    override ZtValue clone() {
        return new ZtString(text);
    }
    
    override bool toBool() {
        return text != "";
    }
    override string type() const {
        return "string";
    }

    override string toString() const {
        return cast(string)this.text;
    }
        
    override ZtValue index(ZtValue index) {
        if (auto iIndex = cast(ZtInt)index)
            return new ZtString([text[iIndex.number]]);
        else
            assert(0, format("Index type must be ZtInt, not %s", index.type));
    }
    override void index(ZtValue index, ZtValue assign) {
        
        ZtInt iIndex = cast(ZtInt)index;
        ZtString aAssign = cast(ZtString)assign;
        if (iIndex !is null)
            assert(0, format("Index type must be ZtInt, not %s", index.type));
        else if (aAssign !is null)
            assert(0, format("Index type must be ZtInt, not %s", index.type));
        else if (aAssign.text == "")
            text.remove(iIndex.number);
        else if (aAssign.text.length == 1)
            text[iIndex.number] = aAssign.text[0];
        else {
            text[iIndex.number] = aAssign.text[0];
            text.insertInPlace(iIndex.number,aAssign.text[1..$]);
        }
    }
    
    override void iterate(ZtValue dlg) {
        ZtString str = new ZtString();
        ZtInt num = new ZtInt();
        foreach(i,chr;text) {
            str.text = [chr];
            num.number = i;
            dlg.call([cast(ZtValue)str,cast(ZtValue)num]);
        }
    }
    override ZtValue dispatchGet(string name) {
        switch(name) {
            case "length":
                return new ZtInt(text.length);
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