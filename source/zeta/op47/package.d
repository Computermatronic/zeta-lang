/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.op47;

public:
import zeta.op47.opcodes;
import zeta.op47.value;
import zeta.op47.thread;
import zeta.op47.stackframe;