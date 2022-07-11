/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2022 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.runtime;

public:
import zeta.runtime.exception;
import zeta.runtime.type;
import zeta.runtime.nil;
import zeta.runtime.boolean;
import zeta.runtime.integer;
import zeta.runtime.float_;
import zeta.runtime.string;
import zeta.runtime.array;
import zeta.runtime.closure;
import zeta.runtime.ffunction;
import zeta.runtime.metatype;
