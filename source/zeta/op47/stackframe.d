/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.op47.stackframe;

import zeta.op47;

struct Op47Stackframe {
    union {
        struct {
            uint sbp, stp;
        }
        Op47Value[] virtualStack;
    }
    uint ret;
    Op47Stackframe* prev, outer;
    bool isVirtual;

    this(uint sbp, uint stp, uint ret, Op47Stackframe* prev, Op47Stackframe* outer) {
        this.sbp = sbp;
        this.stp = stp;
        this.ret = ret;
        this.prev = prev;
        this.outer = outer;
    }

    void virtualize(Op47Value[] stack) {
        virtualStack = stack[sbp..stp];
        isVirtual = true;
    }

    Op47Stackframe* getOuter(uint index) {
        if (index == 1) return outer;
        else return outer.getOuter(index - 1);
    }
}