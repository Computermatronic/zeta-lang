/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type.array;

import std.conv;
import std.format;
import zeta.type.value;
import zeta.type.integer;

class ZtArray : ZtValue {
    ZtValue[] array;
    
    this(){}

    this(ZtValue[] array) {
        this.array = array;
    }
    
    override bool toBool() {
        return array.length != 0;
    }
    
    override bool equals(ZtValue var) {
        if (auto arr = cast(ZtArray)var)
            return array==arr.array;
        else
            return false;
    }
    override ZtValue clone() {
        return this;
    }
    
    override string type() const {
        return "array";
    }
    
    override string toString() const {
        string str = "[";
        foreach(i,element;array)
            str ~= element.toString ~ (array.length == i+1 ? "]" :", ");
        return format("%s: %s",type,str);
    }
    
    override ZtValue index(ZtValue index) {
        if (auto iIndex = cast(ZtInt)index)
            return array[iIndex.number];
        else
            assert(0, format("Index type must be ZtInt, not %s", index.type));
    }
    override void index(ZtValue index, ZtValue assign) {
        if (auto iIndex = cast(ZtInt)index)
            array[iIndex.number] = assign;
        else
            assert(0, format("Index type must be ZtInt, not %s", index.type));
    }
    
    override void iterate(ZtValue dlg) {
        auto num = new ZtInt();
        foreach(i,element;array) {
            num.number = i;
            dlg.call([element,num]);
        }
    }
    
    override ZtValue dispatchGet(string name) {
        switch(name) {
            case "length":
                return new ZtInt(array.length);
            default:
                assert(0, format("No such field %s for %s",name,type));
        }
    }
    override void dispatchSet(string name, ZtValue var) {
        switch(name) {
            case "length":
                if (auto vVar = cast(ZtInt)var)
                    array.length = vVar.number;
                else
                    assert(0, format("Index type must be whole number"));
                break;
            default:
                assert(0, format("No such field %s for %s",name,type));
        }
    }

    override ZtValue dispatchCall(string name, ZtValue[] args) {
        assert(0, format("Cannot call field %s for %s",name,type));
    }
}

void remove(T)(ref T[] array, size_t index) {
    size_t j;
    for(size_t i;i<array.length;i++) {
        array[j] = array[i];
        j+= i==index ? 2 : 1;
    }
}