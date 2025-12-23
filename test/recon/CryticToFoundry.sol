// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";


// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        targetContract(address(this));
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        morpho_supply_clamped(1e18);
        morpho_supplyCollateral(1e18, _getActor(), hex"");

        // Max borrow = collateral * LLTV = 1e18 * 80% = 0.8e18
        // Borrow slightly less to account for rounding
        morpho_borrow(7e17, 0, _getActor(), _getActor());
    }

    // forge test --match-test test_morpho_setOwner_0 -vvv
    function test_morpho_setOwner_0() public {
        vm.roll(19070);
        vm.warp(69860);
        morpho_setOwner(address(0x30000));
    }
		
}