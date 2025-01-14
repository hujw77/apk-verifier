// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../math/Math.sol";
import "../bytes/ByteOrder.sol";

/// @dev BW6-761 scalar field.
/// @param a High-order part 256 bits.
/// @param b Low-order part 256 bits.
struct Bw6Fr {
    uint256 a;
    uint256 b;
}

/// @title BW6FR
library BW6FR {
    using Math for uint256;

    /// @dev MOD_EXP precompile address.
    uint256 private constant MOD_EXP = 0x05;

    /// @dev Returns scalar field: r = 0x1ae3a4617c510eac63b05c06ca1493b1a22d9f300f5138f1ef3622fba094800170b5d44300000008508c00000000001
    /// @return Scalar field.
    function r() internal pure returns (Bw6Fr memory) {
        return
            Bw6Fr(0x1ae3a4617c510eac63b05c06ca1493b, 0x1a22d9f300f5138f1ef3622fba094800170b5d44300000008508c00000000001);
    }

    /// @dev Returns the additive identity element of Bw6Fr.
    /// @return Bw6Fr(0, 0)
    function zero() internal pure returns (Bw6Fr memory) {
        return Bw6Fr(0, 0);
    }

    /// @dev Returns the multiplicative identity element of Bw6Fr.
    /// @return Bw6Fr(0, 1)
    function one() internal pure returns (Bw6Fr memory) {
        return Bw6Fr(0, 1);
    }

    /// @dev Returns the two of Bw6Fr.
    /// @return Bw6Fr(0, 2)
    function two() internal pure returns (Bw6Fr memory) {
        return Bw6Fr(0, 2);
    }

    /// @dev Returns `true` if `self` is equal to the additive identity.
    /// @param self Bw6Fr.
    /// @return Result of zero check.
    function is_zero(Bw6Fr memory self) internal pure returns (bool) {
        return eq(self, zero());
    }

    /// @dev Returns `true` if `self` is equal or larger than r.
    /// @param self Bw6Fr.
    /// @return Result of check.
    function is_geq_modulus(Bw6Fr memory self) internal pure returns (bool) {
        return (eq(self, r()) || gt(self, r()));
    }

    /// @dev Returns `true` if `x` is equal to `y`.
    /// @param x Bw6Fr.
    /// @param y Bw6Fr.
    /// @return Result of equal check.
    function eq(Bw6Fr memory x, Bw6Fr memory y) internal pure returns (bool) {
        return (x.a == y.a && x.b == y.b);
    }

    /// @dev Returns `true` if `x` is larger than `y`.
    /// @param x Bw6Fr.
    /// @param y Bw6Fr.
    /// @return Result of gt check.
    function gt(Bw6Fr memory x, Bw6Fr memory y) internal pure returns (bool) {
        return (x.a > y.a || (x.a == y.a && x.b > y.b));
    }

    /// @dev Returns the result of `x + y`.
    /// @param x Bw6Fr.
    /// @param y Bw6Fr.
    /// @return z `x + y`.
    function add_nomod(Bw6Fr memory x, Bw6Fr memory y) internal pure returns (Bw6Fr memory z) {
        unchecked {
            uint8 carry = 0;
            (carry, z.b) = x.b.adc(y.b, carry);
            (, z.a) = x.a.adc(y.a, carry);
        }
    }

    /// @dev Returns the result of `(x + y) % p`.
    /// @param x Bw6Fp.
    /// @param y Bw6Fp.
    /// @return z `(x + y) % p`.
    function add(Bw6Fr memory x, Bw6Fr memory y) internal pure returns (Bw6Fr memory z) {
        z = add_nomod(x, y);
        z = subtract_modulus_to_norm(z);
    }

    function subtract_modulus_to_norm(Bw6Fr memory self) internal pure returns (Bw6Fr memory z) {
        z = self;
        if (is_geq_modulus(self)) {
            z = sub(self, r());
        }
    }

    /// @dev Returns the result of `(x - y) % p`.
    /// @param x Bls12Fp.
    /// @param y Bls12Fp.
    /// @return z `(x - y) % p`.
    function sub(Bw6Fr memory x, Bw6Fr memory y) internal pure returns (Bw6Fr memory z) {
        Bw6Fr memory m = x;
        if (gt(y, x)) {
            m = add_nomod(m, r());
        }
        unchecked {
            uint8 borrow = 0;
            (borrow, z.b) = m.b.sbb(y.b, borrow);
            (, z.a) = m.a.sbb(y.a, borrow);
        }
    }

    /// @dev Returns the result of `x - y`.
    /// @param x Bls12Fp[2].
    /// @param y Bls12Fp[2].
    /// @return z `x - y`.
    function sub(Bw6Fr[2] memory x, Bw6Fr[2] memory y) internal pure returns (Bw6Fr[2] memory z) {
        unchecked {
            uint8 borrow = 0;
            (borrow, z[1].b) = x[1].b.sbb(y[1].b, borrow);
            (borrow, z[1].a) = x[1].a.sbb(y[1].a, borrow);
            (borrow, z[0].b) = x[0].b.sbb(y[0].b, borrow);
            (, z[0].a) = x[0].a.sbb(y[0].a, borrow);
        }
    }

    /// @dev (x * y) = ((x + y)^2 - (x - y)^2) / 4
    /// @param x Bw6Fr.
    /// @param y Bw6Fr.
    /// @return z Bw6Fr.
    function mul(Bw6Fr memory x, Bw6Fr memory y) internal view returns (Bw6Fr memory z) {
        if (eq(x, y)) {
            z = square(x);
        } else {
            Bw6Fr memory lhs = add_nomod(x, y);
            Bw6Fr[2] memory fst = square_nomod(lhs);
            Bw6Fr memory rhs = gt(x, y) ? sub(x, y) : sub(y, x);
            Bw6Fr[2] memory snd = square_nomod(rhs);
            Bw6Fr[2] memory rst = sub(fst, snd);
            rst = div2(rst);
            rst = div2(rst);
            z = norm(rst);
        }
    }

    /// @dev Sum of the list of Bw6Fr.
    /// @param xs Bw6Fr[].
    /// @return Result of sum.
    function sum(Bw6Fr[] memory xs) internal pure returns (Bw6Fr memory) {
        Bw6Fr memory s = zero();
        for (uint256 i = 0; i < xs.length; i++) {
            s = add(s, xs[i]);
        }
        return s;
    }

    /// @dev Mul and Add.
    /// @param xs Bw6Fr[].
    /// @param ys Bw6Fr[].
    /// @return z Result of mul and add.
    function mul_sum(Bw6Fr[] memory xs, Bw6Fr[] memory ys) internal view returns (Bw6Fr memory z) {
        require(xs.length == ys.length, "!len");
        uint256 k = xs.length;
        z = zero();
        for (uint256 i = 0; i < k; i++) {
            Bw6Fr memory x = xs[i];
            Bw6Fr memory y = ys[i];
            z = add(z, mul(x, y));
        }
    }

    /// @dev self / two
    /// @param self Bw6Fr[2].
    /// @return z Result of div2.
    function div2(Bw6Fr[2] memory self) internal pure returns (Bw6Fr[2] memory z) {
        z = self;
        z[1].b = z[1].b >> 1 | z[1].a << 255;
        z[1].a = z[1].a >> 1 | z[0].b << 255;
        z[0].b = z[0].b >> 1 | z[0].a << 255;
        z[0].a = z[0].a >> 1;
    }

    /// @dev Constant time inversion using Fermat's little theorem.
    /// For a prime p and for any a < p, a^p = a % p => a^(p-1) = 1 % p => a^(p-2) = a^-1 % p
    /// @param self Bw6Fr.
    /// @return Result of inverse.
    function inverse(Bw6Fr memory self) internal view returns (Bw6Fr memory) {
        if (is_zero(self)) return self;
        Bw6Fr memory r2 = sub(r(), two());
        uint256[9] memory input;
        input[0] = 0x40;
        input[1] = 0x40;
        input[2] = 0x40;
        input[3] = self.a;
        input[4] = self.b;
        input[5] = r2.a;
        input[6] = r2.b;
        input[7] = r().a;
        input[8] = r().b;
        uint256[2] memory output;

        assembly ("memory-safe") {
            if iszero(staticcall(gas(), MOD_EXP, input, 288, output, 64)) {
                let p := mload(0x40)
                returndatacopy(p, 0, returndatasize())
                revert(p, returndatasize())
            }
        }

        self.a = output[0];
        self.b = output[1];

        return self;
    }

    /// @dev self^2 % r.
    /// @param self Bw6Fr.
    /// @return Result of square.
    function square(Bw6Fr memory self) internal view returns (Bw6Fr memory) {
        return pow(self, 2);
    }

    /// @dev base^exp % r
    /// @param base Bw6Fr.
    /// @param exp Bw6Fr.
    /// @return Result of pow.
    function pow(Bw6Fr memory base, uint256 exp) internal view returns (Bw6Fr memory) {
        return mod_exp(base, exp, r());
    }

    /// @dev base^base % modulus
    /// @param base Bw6Fr.
    /// @param exp Bw6Fr.
    /// @param modulus Bw6Fr.
    /// @return Result of mod_exp.
    function mod_exp(Bw6Fr memory base, uint256 exp, Bw6Fr memory modulus) internal view returns (Bw6Fr memory) {
        uint256[8] memory input;
        input[0] = 0x40;
        input[1] = 0x20;
        input[2] = 0x40;
        input[3] = base.a;
        input[4] = base.b;
        input[5] = exp;
        input[6] = modulus.a;
        input[7] = modulus.b;
        uint256[2] memory output;

        assembly ("memory-safe") {
            if iszero(staticcall(gas(), MOD_EXP, input, 256, output, 64)) {
                let p := mload(0x40)
                returndatacopy(p, 0, returndatasize())
                revert(p, returndatasize())
            }
        }

        return Bw6Fr(output[0], output[1]);
    }

    /// @dev self^2
    /// @param self Bw6Fr.
    /// @return Result of square withoud mod.
    function square_nomod(Bw6Fr memory self) internal view returns (Bw6Fr[2] memory) {
        uint256[10] memory input;
        input[0] = 0x40;
        input[1] = 0x20;
        input[2] = 0x80;
        input[3] = self.a;
        input[4] = self.b;
        input[5] = 2;
        input[6] = type(uint256).max;
        input[7] = type(uint256).max;
        input[8] = type(uint256).max;
        input[9] = type(uint256).max;
        uint256[4] memory output;

        assembly ("memory-safe") {
            if iszero(staticcall(gas(), MOD_EXP, input, 320, output, 128)) {
                let p := mload(0x40)
                returndatacopy(p, 0, returndatasize())
                revert(p, returndatasize())
            }
        }
        return [Bw6Fr(output[0], output[1]), Bw6Fr(output[2], output[3])];
    }

    /// @dev Normalize Bw6Fr[2].
    /// @param self Bw6Fr[2].
    /// @return `self % r`.
    function norm(Bw6Fr[2] memory self) internal view returns (Bw6Fr memory) {
        uint256[10] memory input;
        input[0] = 0x80;
        input[1] = 0x20;
        input[2] = 0x40;
        input[3] = self[0].a;
        input[4] = self[0].b;
        input[5] = self[1].a;
        input[6] = self[1].b;
        input[7] = 1;
        input[8] = r().a;
        input[9] = r().b;
        uint256[2] memory output;

        assembly ("memory-safe") {
            if iszero(staticcall(gas(), MOD_EXP, input, 320, output, 64)) {
                let p := mload(0x40)
                returndatacopy(p, 0, returndatasize())
                revert(p, returndatasize())
            }
        }
        return Bw6Fr(output[0], output[1]);
    }

    /// @dev (max_exp+1)-sized vec: 1, base, base^2,... ,base^{max_exp}
    /// @param base Bw6Fr.
    /// @param max_exp uint256.
    /// @return Result of powers.
    function powers(Bw6Fr memory base, uint256 max_exp) internal view returns (Bw6Fr[] memory) {
        uint256 cap = max_exp + 1;
        Bw6Fr[] memory result = new Bw6Fr[](cap);
        result[0] = one();
        if (max_exp > 0) {
            result[1] = base;
        }
        for (uint256 i = 2; i < cap; i++) {
            result[i] = pow(base, i);
        }
        return result;
    }

    /// @dev Horner field
    /// @param bases Bw6Fr[].
    /// @param nu Bw6Fr.
    /// @return Result of horner_field.
    function horner_field(Bw6Fr[] memory bases, Bw6Fr memory nu) internal view returns (Bw6Fr memory) {
        Bw6Fr memory acc = zero();
        uint256 k = bases.length;
        for (uint256 i = 0; i < k; i++) {
            Bw6Fr memory b = bases[k - i - 1];
            acc = add(mul(acc, nu), b);
        }
        return acc;
    }

    /// @dev Derive Bw6Fr from bytes in LE order.
    /// @param input bytes16.
    /// @return Bw6Fr.
    function from_random_bytes(bytes16 input) internal pure returns (Bw6Fr memory) {
        return Bw6Fr(0, ByteOrder.reverse128(uint128(input)));
    }

    /// @dev Serialize Bw6Fr.
    /// @param self Bw6Fr.
    /// @return Compressed serialized bytes of Bls12G1.
    function serialize(Bw6Fr memory self) internal pure returns (bytes memory) {
        uint128 a = ByteOrder.reverse128(uint128(self.a));
        uint256 b = ByteOrder.reverse256(self.b);
        return abi.encodePacked(b, a);
    }

    /// @dev Debug Bw6Fr in bytes.
    /// @param self Bw6Fr.
    /// @return Uncompressed serialized bytes of Bw6Fr.
    function debug(Bw6Fr memory self) internal pure returns (bytes memory) {
        return abi.encodePacked(self.a, self.b);
    }
}
