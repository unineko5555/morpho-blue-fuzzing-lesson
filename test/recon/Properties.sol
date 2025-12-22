// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {

    function canary_hasDoneRepay() public {
        t(!hasRepaid, "canary_hasDoneRepay");
    }

    function canary_hasLiquidated() public {
        t(!hasLiquidated, "canary_hasLiquidated");
    }
}