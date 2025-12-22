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
        // TODO: add failing property tests here for debugging

        // morpho_supply_assets_clamped(1e18);
        // morpho_supply_collateral_clamped(1e18);

        // oracleMock_setPrice(1e30);

        // morpho_borrow(1e6, 0, address(this), address(this));

        // morpho_repay(1e6, 0, address(this), bytes(""));
        // // oracleMock_setPrice(0);
        // // // Liquidation
        // // morpho_liquidate(address(this), 1e6, 0, bytes(""));

    }

    // forge test --match-test test_morpho_setOwner_0 -vvv
    function test_morpho_setOwner_0() public {
        vm.roll(19070);
        vm.warp(69860);
        morpho_setOwner(address(0x30000));
    }
		
}