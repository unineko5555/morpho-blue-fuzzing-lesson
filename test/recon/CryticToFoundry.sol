// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {Id} from "src/interfaces/IMorpho.sol";


// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        targetContract(address(this));
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        address actor = _getActor();
        vm.startPrank(actor);

        morpho.supply(marketParams, 1e18, 0, actor, hex"");
        morpho.supplyCollateral(marketParams, 1e18, actor, hex"");

        // Max borrow = collateral * LLTV = 1e18 * 80% = 0.8e18
        // Borrow slightly less to account for rounding
        morpho.borrow(marketParams, 7e17, 0, actor, actor);

        vm.stopPrank();
    }

    // forge test --match-test test_morpho_setOwner_0 -vvv
    function test_morpho_setOwner_0() public {
        vm.roll(19070);
        vm.warp(69860);
        morpho_setOwner(address(0x30000));
    }

    /// @dev Smoke test: verify Morpho deployment and basic state reads
    // forge test --match-test test_smoke_morpho_deployment -vvv
    function test_smoke_morpho_deployment() public view {
        // Check 1: Morpho has code
        uint256 codeSize = address(morpho).code.length;
        console2.log("Morpho address:", address(morpho));
        console2.log("Morpho code size:", codeSize);
        require(codeSize > 0, "Morpho has no code");

        // Check 2: Owner is this contract
        address owner = morpho.owner();
        console2.log("Morpho owner:", owner);
        console2.log("Expected owner (this):", address(this));
        require(owner == address(this), "Owner mismatch");

        // Check 3: Market exists
        Id id = MarketParamsLib.id(marketParams);
        // market() returns: (totalSupplyAssets, totalSupplyShares, totalBorrowAssets, totalBorrowShares, lastUpdate, fee)
        (,,,, uint128 lastUpdate,) = morpho.market(id);
        console2.log("Market lastUpdate:", lastUpdate);
        require(lastUpdate > 0, "Market not created");

        // Check 4: IRM and LLTV enabled
        require(morpho.isIrmEnabled(address(irmMock)), "IRM not enabled");
        require(morpho.isLltvEnabled(8e17), "LLTV not enabled");

        console2.log("=== All smoke checks passed ===");
    }

    /// @dev Full flow test: supply -> borrow -> repay -> withdraw
    // forge test --match-test test_smoke_full_flow -vvv
    function test_smoke_full_flow() public {
        Id id = MarketParamsLib.id(marketParams);
        address actor = _getActor();

        console2.log("=== Starting full flow test ===");
        console2.log("Actor:", actor);

        vm.startPrank(actor);

        // Step 1: Supply loanToken (as liquidity provider)
        console2.log("Step 1: Supply 10e18 loanToken");
        morpho.supply(marketParams, 10e18, 0, actor, hex"");
        (uint128 totalSupplyAssets,,,,,) = morpho.market(id);
        console2.log("  totalSupplyAssets:", totalSupplyAssets);

        // Step 2: Supply collateral
        console2.log("Step 2: Supply 10e18 collateral");
        morpho.supplyCollateral(marketParams, 10e18, actor, hex"");
        // position() returns: (supplyShares, borrowShares, collateral)
        (,, uint128 collateral) = morpho.position(id, actor);
        console2.log("  collateral:", collateral);

        // Step 3: Borrow (within LLTV limit: 10e18 * 80% = 8e18 max)
        console2.log("Step 3: Borrow 5e18");
        morpho.borrow(marketParams, 5e18, 0, actor, actor);
        (, uint128 borrowSharesPos,) = morpho.position(id, actor);
        (,, uint128 totalBorrowAssets,,,) = morpho.market(id);
        console2.log("  borrowShares:", borrowSharesPos);
        console2.log("  totalBorrowAssets:", totalBorrowAssets);

        // Step 4: Accrue interest
        console2.log("Step 4: Accrue interest");
        vm.warp(block.timestamp + 1 days);
        morpho.accrueInterest(marketParams);
        (,, uint128 totalBorrowAfter,,,) = morpho.market(id);
        console2.log("  totalBorrowAssets after interest:", totalBorrowAfter);

        // Step 5: Repay all borrowed
        console2.log("Step 5: Repay all");
        (, uint128 borrowShares,) = morpho.position(id, actor);
        morpho.repay(marketParams, 0, borrowShares, actor, hex"");
        (, uint128 borrowSharesAfterRepay,) = morpho.position(id, actor);
        console2.log("  borrowShares after repay:", borrowSharesAfterRepay);

        // Step 6: Withdraw collateral
        console2.log("Step 6: Withdraw collateral");
        (,, uint128 collateralBefore) = morpho.position(id, actor);
        morpho.withdrawCollateral(marketParams, collateralBefore, actor, actor);
        (,, uint128 collateralAfter) = morpho.position(id, actor);
        console2.log("  collateral after withdraw:", collateralAfter);

        vm.stopPrank();

        console2.log("=== Full flow test completed ===");
    }
}