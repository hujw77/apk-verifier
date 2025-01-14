// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../../../src/common/bw6761/Fr.sol";

contract BW6FRTest is Test {
    using BW6FR for Bw6Fr;

    function test_square() public {
        Bw6Fr memory x = Bw6Fr(0, 205713981876823471916128338707288082226);
        Bw6Fr memory z = x.square();
        Bw6Fr memory e = Bw6Fr(0, 42318242339618055853036318227838751709998714903245007906081872034932937115076);
        assertTrue(z.eq(e));
    }

    function test_add() public {
        Bw6Fr memory a =
            Bw6Fr(0x199e1755a3a4cdfa17454dba7fa7ac4, 0x0715e575b43a4ed1f47408dc2e2c97d5433a142af15266349437b343298b4b94);
        Bw6Fr memory b =
            Bw6Fr(0x192a7f9914c19174cfc3a865e64bc8d, 0xa3952c1ed52e4e8f41fb45596faa52a6990f4e33da271b475122542ba8d5cf88);
        Bw6Fr memory e =
            Bw6Fr(0x17e4f28d3c1550c283589a199bdee16, 0x908837a1887389d2177bec05e3cda27bc53e051a9b79817b6051476ed2611b1b);
        Bw6Fr memory c = a.add(b);
        Bw6Fr memory d = b.add(a);
        assertTrue(e.eq(c));
        assertTrue(e.eq(d));
    }

    function test_sub1() public {
        Bw6Fr memory a =
            Bw6Fr(0x199e1755a3a4cdfa17454dba7fa7ac4, 0x0715e575b43a4ed1f47408dc2e2c97d5433a142af15266349437b343298b4b94);
        Bw6Fr memory b =
            Bw6Fr(0x192a7f9914c19174cfc3a865e64bc8d, 0xa3952c1ed52e4e8f41fb45596faa52a6990f4e33da271b475122542ba8d5cf88);
        Bw6Fr memory e =
            Bw6Fr(0x7397bc8ee33c854781a554995be36, 0x6380b956df0c0042b278c382be82452eaa2ac5f7172b4aed43155f1780b57c0c);
        Bw6Fr memory c = a.sub(b);
        assertTrue(e.eq(c));
    }

    function test_sub2() public {
        Bw6Fr memory a =
            Bw6Fr(0x199e1755a3a4cdfa17454dba7fa7ac4, 0x0715e575b43a4ed1f47408dc2e2c97d5433a142af15266349437b343298b4b94);
        Bw6Fr memory b =
            Bw6Fr(0x192a7f9914c19174cfc3a865e64bc8d, 0xa3952c1ed52e4e8f41fb45596faa52a6990f4e33da271b475122542ba8d5cf88);
        Bw6Fr memory e =
            Bw6Fr(0x1a700ca4ed6dd2271c2eb6b230b8b04, 0xb6a2209c21e9134c6c7a9eacfb8702d16ce0974d18d4b51341f360e87f4a83f5);
        Bw6Fr memory c = b.sub(a);
        assertTrue(e.eq(c));
    }

    function test_sub_square() public {
        Bw6Fr memory a =
            Bw6Fr(0x199e1755a3a4cdfa17454dba7fa7ac4, 0x0715e575b43a4ed1f47408dc2e2c97d5433a142af15266349437b343298b4b94);
        Bw6Fr memory b =
            Bw6Fr(0x192a7f9914c19174cfc3a865e64bc8d, 0xa3952c1ed52e4e8f41fb45596faa52a6990f4e33da271b475122542ba8d5cf88);
        Bw6Fr memory e =
            Bw6Fr(0x48f6e3d6443474913ae894664d1132, 0xc989742cc9294c9c935b5b7c57955912b348dba83d69e87af0d54f4716c5974a);
        assertTrue(a.sub(b).square().eq(e));
        assertTrue(b.sub(a).square().eq(e));
    }

    function test_mul1() public {
        Bw6Fr memory a =
            Bw6Fr(0x199e1755a3a4cdfa17454dba7fa7ac4, 0x0715e575b43a4ed1f47408dc2e2c97d5433a142af15266349437b343298b4b94);
        Bw6Fr memory b =
            Bw6Fr(0x192a7f9914c19174cfc3a865e64bc8d, 0xa3952c1ed52e4e8f41fb45596faa52a6990f4e33da271b475122542ba8d5cf88);
        Bw6Fr memory e =
            Bw6Fr(0x17782192b3528ac9750390a3acb857e, 0x25f15cd965a1dfe7a748eb6522f2559c6ad9b0fb2bb02058fd03555ce1b151b5);
        Bw6Fr memory c = a.mul(b);
        Bw6Fr memory d = b.mul(a);
        assertTrue(e.eq(c));
        assertTrue(e.eq(d));
    }

    function test_mul2() public {
        Bw6Fr memory a =
            Bw6Fr(0x199e1755a3a4cdfa17454dba7fa7ac4, 0x0715e575b43a4ed1f47408dc2e2c97d5433a142af15266349437b343298b4b94);
        Bw6Fr memory e =
            Bw6Fr(0x11eb00d817a0b7f29496baea288664a, 0x9f96769b51738614a28b2487a54f673f46cc53116cb3eea6d9e74015ba2c704d);
        Bw6Fr memory c = a.mul(a);
        assertTrue(e.eq(c));
    }

    function test_from_random_bytes() public {
        bytes16 input = 0x72f666c660cd4a19ce7be97ae2234c57;
        Bw6Fr memory a = BW6FR.from_random_bytes(input);
        Bw6Fr memory e = Bw6Fr(0, 116038178022476619441708140207551215218);
        assertTrue(e.eq(a));
    }

    function test_serialize() public {
        Bw6Fr memory a =
            Bw6Fr(0x199e1755a3a4cdfa17454dba7fa7ac4, 0x0715e575b43a4ed1f47408dc2e2c97d5433a142af15266349437b343298b4b94);
        bytes memory e =
            hex"944b8b2943b33794346652f12a143a43d5972c2edc0874f4d14e3ab475e51507c47afaa7db5474a1df4c3a5a75e19901";
        assertEq(a.serialize(), e);
    }

    function test_inverse() public {
        Bw6Fr memory a = Bw6Fr(0, 256);
        a.inverse();
        Bw6Fr memory e =
            Bw6Fr(0x1ac8c0bd1ad4bd9db74cabaac34a7f1, 0xdf08b7190df41e7b8fd46ecd8a4f3eb816f451e6ebd000008483b74000000001);
        assertTrue(e.eq(a));
    }

    function test_powers() public {
        Bw6Fr memory r = Bw6Fr({a: 0, b: 133321539823602459806599945304366977715});
        Bw6Fr[] memory powers_of_r = r.powers(0);
        Bw6Fr memory e = Bw6Fr(0, 1);
        assertEq(powers_of_r.length, 1);
        assertTrue(e.eq(powers_of_r[0]));
    }

    function test_mix() public {
        Bw6Fr memory two = BW6FR.two();
        Bw6Fr memory r = Bw6Fr({a: 0, b: 133321539823602459806599945304366977715});
        Bw6Fr memory a_zeta_omega1 =
            Bw6Fr(0x12c44f75be8135d89e72c7407273ed9, 0xce3698b9639bf3618953f61038f8cac68890d607172c9d5311b0543a2a3c362e);
        Bw6Fr memory a = two.add((r.mul(two.pow(255).inverse()).sub(two)).mul(a_zeta_omega1));
        Bw6Fr memory e =
            Bw6Fr(0x11d37ccfaff155313af1e1a98bdfacd, 0xdde0eea8987b8379ca84ffbeaf9c9705c1683ecf9192872e2481e73e037516a3);
        assertTrue(e.eq(a));
    }
}
