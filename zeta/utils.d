module zeta.utils;

import std.container;
import std.string;
import std.traits;

struct Stack(T)
{
	private SList!T stack;
	
	public void push(T value)
    {
		stack.stableInsertFront(value);
	}
	
	public T peek()
    {
		assert(!stack.empty);
		return (stack.front());
	}
	
	public T pop()
    {
		assert(!stack.empty);
		T Temp = stack.front();
		stack.stableRemoveFront();
		return Temp;
	}
	
	@property const bool empty()
	{
		return stack.empty();
	}
	
	public void unwind()
    {
		while(!empty)
		{
			pop();
		}
	}
}

uint toLine(string str, uint i)
{
	return str[0..i].splitLines().length;
}

uint toColunm(string str, uint i)
{
	string[] lines = str[0..i].splitLines();
    if (lines.length>0)
        return lines[$-1].length;
    else
        return i;
}

T fromBytes(T)(in ubyte[] bytes)
{
    assert(T.sizeof <= bytes.length);
    return *cast(T*)bytes.ptr;
}

ubyte[] toBytes(T)(in T to)
{
	return (cast(ubyte*)&to)[0..T.sizeof].dup();    
}

auto backMap(T)(T map) if (isAssociativeArray!T)
{
    KeyType!T[ValueType!T] backmap;
    foreach(k,v;map)
    {
        backmap[v] = k;
    }
    return backmap;
}

T merge(T)(T to, T from) if (isAssociativeArray!T)
{
    foreach(k,v;from)
    {
        to[k] = v;
    }
    return to;
}

bool isLvalue(string id)
{
    switch(id)
    {
        case "null":
            return false;
        case "true":
            return false;
        case "false":
            return false;
        default:
            return true;
    }
}

version(D_LP64)
{
    alias integer = long;
}
else
{
    alias integer = int;
}
