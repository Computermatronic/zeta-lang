/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.utils.range;

import std.range;

auto takeFront(Range)(ref Range range) {
    auto result = range.front;
    range.popFront();
    return result;
}
