/* 
 * Reference implementation of the zeta-lang scripting language.
 * Copyright (c) 2015-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module zeta.type;

public {
    import zeta.type.type_t;
    import zeta.type.null_t;
    import zeta.type.boolean_t;
    import zeta.type.integer_t;
    import zeta.type.float_t;
    import zeta.type.string_t;
    import zeta.type.array_t;
    import zeta.type.function_t;
    import zeta.type.native_t;
    import zeta.type.meta_t;
}