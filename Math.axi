/* The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is math library to expand on the base math functionality
 * provided by the NetLinx language.
 *
 * The Initial Developer of the Original Code is Queensland Department of
 * Justice and Attorney-General.
 * Portions created by the Initial Developer are Copyright (C) 2010 the
 * Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * 	Kim Burgess <kim.burgess@justice.qld.gov.au>
 *
 */
PROGRAM_NAME='Math'


DEFINE_VARIABLE

constant double MATH_E = 2.718281828459045
constant double MATH_PI = 3.141592653589793

// Psuedo constants for non-normal numbers - these are injected with their
// relevant bit patterns on boot
volatile double MATH_NaN
volatile double MATH_POSITIVE_INFINITY
volatile double MATH_NEGATIVE_INFINITY


/**
 * Load 4 bytes of big endian data contained in a character array into a long.
 *
 * Note: Array position 1 should contain MSB.
 *
 * @param	a	a 4 byte character array containg the data to load
 * @return		a long filled with the passed data
 */
define_function long math_raw_be_to_long(char raw[4]) {
    stack_var char byte
    stack_var long bits
    FOR (byte = 4; byte; byte--) {
	bits = bits + (raw[byte] << ((4 - byte) << 3))
    }
    return bits
}

/**
 * Load a signed long's bit pattern into a long.
 *
 * @param	a	the slong to load
 * @return		a long filled with the bit pattern of the slong
 */
define_function long math_slong_to_bits(slong a) {
    return math_raw_be_to_long(raw_be(a))
}

/**
 * Load a float value's IEEE 754 bit pattern into a long.
 *
 * @param	a	the float to load
 * @return		a long filled with the IEEE 754 bit pattern of the float
 */
define_function long math_float_to_bits(float a) {
    return math_raw_be_to_long(RAW_BE(a))
}

/**
 * Load the raw data stored in bits 63 - 32 of a DOUBLE into a LONG.
 *
 * @param	a	the double to load
 * @return		a long filled binary data stored in the high DWord of the double
 */
define_function long math_double_high_to_bits(double a) {
    stack_var char raw[8]
    raw = raw_be(a)
    return math_raw_be_to_long("raw[1], raw[2], raw[3], raw[4]")
}

/**
 * Load the raw data stored in bits 31 - 0 of a DOUBLE into a LONG.
 *
 * @param	a	the double to load
 * @return		a long filled binary data stored in the low DWord of the double
 */
define_function long math_double_low_to_bits(double a) {
    stack_var char raw[8]
    raw = raw_be(a)
    return math_raw_be_to_long("raw[5], raw[6], raw[7], raw[8]")
}

/**
 * Build a float using a IEEE754 bit pattern stored in a long.
 *
 * @param	bits	a long containg the raw data
 * @return		a float built from the passed data
 */
define_function float math_build_float(long bits) {
    stack_var char serialized[6]
    stack_var float f
    serialized = "$E3, raw_be(bits)"
    string_to_variable(f, serialized, 1)
    return f
}

/**
 * Build a double using the binary info stored across two longs. It is assumed
 * that the data is stored as per the IEEE754 standard.
 *
 * @param	high	a long containg bits 63 - 32
 * @param	low	a long containing bits 31 - 0
 * @return		a double built from the passed data
 */
define_function double math_build_double(long high, long low) {
    stack_var char serialized[10]			// For some reason the buffer
    stack_var double d					// passed to string_to_variable()
    serialized = "$E4, raw_be(high), raw_be(low)"	// has to have an extra trailing byte
    string_to_variable(d, serialized, 1)
    return d
}

/**
 * Right shift (>>) a double (passed as two long components) 1 bit.
 *
 * NOTE: this will directly manipulate the passed values.
 *
 * @param	high	a long containg bits 63 - 32
 * @param	low	a long containing bits 31 - 0
 */
define_function math_rshift_double(long high, long low) {
    low = low >> 1 + ((high & 1) << 15)
    high = high >> 1
}

/**
 * Left shift (<<) a double (passed as two long components) 1 bit.
 *
 * NOTE: this will directly manipulate the passed values.
 *
 * @param	high	a long containg bits 63 - 32
 * @param	low	a long containing bits 31 - 0
 */
define_function math_lshift_double(long high, long low) {
    high = ((high & $7FFFFFFF) << 1) + ((low & $80000000) >> 15)
    low = (low & $7FFFFFFF) << 1
}

/**
 * Returns TRUE if the argument has no decimal component, otherwise returns
 * FALSE.
 *
 * @param	a	the double to check
 * @return		a boolean representing the number's 'wholeness'
 */
define_function char math_is_whole_number(double a) {
    stack_var slong wholeComponent
    wholeComponent = type_cast(a)
    return wholeComponent == a
}


/**
 * Returns the smallest (closest to negative infinity) long value that is not
 * less than the argument and is equal to a mathematical integer.
 *
 * @param	a	the double to round
 * @return		a signed long containing the rounded number
 */
define_function slong math_ceil(double a) {
    if (a > 0 && !math_is_whole_number(a)) {
	return type_cast(a + 1.0)
    } else {
	return type_cast(a)
    }
}

/**
 * Returns the largest (closest to positive infinity) long value that is not
 * greater than the argument and is equal to a mathematical integer.
 *
 * @param	a	a double to round
 * @return		a signed long containing the rounded number
 */
define_function slong math_floor(double a) {
    if (a < 0 && !math_is_whole_number(a)) {
	return type_cast(a - 1.0)
    } else {
	return type_cast(a)
    }
}

/**
 * Rounds a flouting point number to it's closest whole number.
 *
 * @param	a	a double to round
 * @return		a signed long containing the rounded number
 */
define_function slong math_round(DOUBLE a) {
    return math_floor(a + 0.5)
}

/**
 * Approximate the inverse square root of the passed number.
 *
 * This method uses a integer shift and single Newton refinement aka Quake 3
 * method. Original algorithm by Greg Walsh.
 *
 * @param	x	the float to find the inverse square root of
 * @return		a float containing an approximation of the inverse square root
 */
define_function float math_inv_sqrt(float x) {
    stack_var long bits
    stack_var float temp
    bits = $5F3759DF - (math_float_to_bits(x) >> 1)
    temp = math_build_float(bits)
    return temp * (1.5 - 0.5 * x * temp * temp)
}

/**
 * Approximate the square root of the passed number based on the inverse square
 * root algorithm in mathInvSqrt(x). This is MUCH faster than mathSqrt(x) and
 * recommended over mathsQRT() for use anywhere a precise square root is not
 * required. Error is approx +/-0.15%.
 *
 * @param	a	the float to find the square root of
 * @return		a float containing an approximation of the square root
 */
define_function float math_fast_sqrt(float x) {
    return x * math_inv_sqrt(x)
}

/**
 * Calcultate the logarithm of the passed number in the specified base.
 *
 * @param	x	the float to find the log of
 * @param	base	the base to use
 * @param	epsilon	calculation tolerance
 * @return		a float containing the passed numbers logarithm
 */
define_function float math_log(float x, float base, float epsilon) {
    stack_var float temp
    stack_var integer int
    stack_var float partial
    stack_var float decimal
    if (x < 1 && base < 1) {
	return -1.0	// cannot compute
    }
    temp = x + 0.0
    while (temp < 1) {
	int = int - 1
	temp = temp * base
    }
    while (temp >= base) {
	int = int + 1
	temp = temp / base
    }
    partial = 0.5
    temp = temp * temp
    while (partial > epsilon) {
	if (temp >= base) {
	    decimal = decimal + partial
	    temp = temp / base
	}
	partial = partial * 0.5
	temp = temp * temp
    }
    return int + decimal
}

/**
 * Calcultate the natural logarithm of the passed number.
 *
 * @param	x	the float to find the natural log of
 * @return		a float containing the passed numbers log base e
 */
define_function float math_ln(float x) {
    return math_log(x, MATH_E, 1.0e-13)
}

/**
 * Calcultate the binary logarithm of the passed number.
 *
 * @param	x	the float to find the natural log of
 * @return		a float containing the passed numbers log base 2
 */
define_function float math_log2(float x) {
    return math_log(x, 2, 1.0e-13)
}

/**
 * Calcultate the base 10 logarithm of the passed number.
 *
 * @param	x	the float to find the natural log of
 * @return		a float containing the passed numbers log base 10
 */
define_function float math_log10(float x) {
    return math_log(x, 10, 1.0e-13)
}

/**
 * Calcultate x raised to the n.
 *
 * @param	x	the float to find the natural log of
 * @param	n	the power to raise x to
 * @return		a float containing the x^n
 */
define_function float math_power(float x, integer n) {
    stack_var float result
    stack_var float base
    stack_var integer exp
    result = 1.0
    base = x + 0.0
    exp = n + 0
    while (exp > 0) {
	if (exp & 1) {
	    result = result * base
	    exp = exp - 1
	}
	base = base * base
	exp = type_cast(math_round(exp * 0.5))
    }
    return result
}


DEFINE_START

MATH_NaN = math_build_double($FFFFFFFF, $FFFFFFFF)
MATH_POSITIVE_INFINITY = math_build_double($7FF00000, $00000000)
MATH_NEGATIVE_INFINITY = math_build_double($FFF00000, $00000000)