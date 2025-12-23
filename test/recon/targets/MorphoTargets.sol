// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {MockERC20} from "@recon/MockERC20.sol";

import "src/Morpho.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";

abstract contract MorphoTargets is
    BaseTargetFunctions,
    Properties
{
    /// ============ CLAMPED TARGET FUNCTIONS ============ ///
    /// These functions clamp inputs to valid ranges to ensure Morpho code is reached

    /// @dev Supply loanToken with assets clamped to actor's balance, shares=0
    function morpho_supply_clamped(uint256 assets) public asActor {
        address actor = _getActor();
        uint256 balance = MockERC20(marketParams.loanToken).balanceOf(actor);
        if (balance == 0) return;
        uint256 clampedAssets = (assets % balance) + 1;
        morpho.supply(marketParams, clampedAssets, 0, actor, hex"");
    }

    /// @dev Supply collateral with assets clamped to actor's balance
    function morpho_supplyCollateral_clamped(uint256 assets) public asActor {
        address actor = _getActor();
        uint256 balance = MockERC20(marketParams.collateralToken).balanceOf(actor);
        if (balance == 0) return;
        uint256 clampedAssets = (assets % balance) + 1;
        morpho.supplyCollateral(marketParams, clampedAssets, actor, hex"");
    }

    /// @dev Borrow with assets clamped to 70% of collateral (below 80% LLTV)
    function morpho_borrow_clamped(uint256 assets) public asActor {
        address actor = _getActor();
        Id id = MarketParamsLib.id(marketParams);
        // position returns: (uint256 supplyShares, uint128 borrowShares, uint128 collateral)
        (,, uint128 collateral) = morpho.position(id, actor);
        if (collateral == 0) return;

        // Max safe borrow: collateral * 70% (below 80% LLTV)
        uint256 maxBorrow = (uint256(collateral) * 7) / 10;
        if (maxBorrow == 0) return;

        uint256 clampedAssets = (assets % maxBorrow) + 1;
        morpho.borrow(marketParams, clampedAssets, 0, actor, actor);
    }

    /// @dev Withdraw supply shares clamped to actor's position
    function morpho_withdraw_clamped(uint256 shares) public asActor {
        address actor = _getActor();
        Id id = MarketParamsLib.id(marketParams);
        // position returns: (uint256 supplyShares, uint128 borrowShares, uint128 collateral)
        (uint256 supplyShares,,) = morpho.position(id, actor);
        if (supplyShares == 0) return;

        uint256 clampedShares = (shares % supplyShares) + 1;
        morpho.withdraw(marketParams, 0, clampedShares, actor, actor);
    }

    /// @dev Withdraw collateral clamped to actor's collateral position
    function morpho_withdrawCollateral_clamped(uint256 assets) public asActor {
        address actor = _getActor();
        Id id = MarketParamsLib.id(marketParams);
        // position returns: (uint256 supplyShares, uint128 borrowShares, uint128 collateral)
        (,, uint128 collateral) = morpho.position(id, actor);
        if (collateral == 0) return;

        uint256 clampedAssets = (assets % uint256(collateral)) + 1;
        morpho.withdrawCollateral(marketParams, clampedAssets, actor, actor);
    }

    /// @dev Repay with shares clamped to actor's borrow position
    function morpho_repay_clamped(uint256 shares) public asActor {
        address actor = _getActor();
        Id id = MarketParamsLib.id(marketParams);
        // position returns: (uint256 supplyShares, uint128 borrowShares, uint128 collateral)
        (, uint128 borrowShares,) = morpho.position(id, actor);
        if (borrowShares == 0) return;

        uint256 clampedShares = (shares % uint256(borrowShares)) + 1;
        morpho.repay(marketParams, 0, clampedShares, actor, hex"");
        hasRepaid = true;
    }

    /// @dev Liquidate with seizedAssets (repaidShares=0)
    function morpho_liquidate_assets(address borrower, uint256 seizedAssets) public asActor {
        morpho.liquidate(marketParams, borrower, seizedAssets, 0, hex"");
        hasLiquidated = true;
    }

    /// @dev Liquidate with repaidShares (seizedAssets=0)
    function morpho_liquidate_shares(address borrower, uint256 repaidShares) public asActor {
        morpho.liquidate(marketParams, borrower, 0, repaidShares, hex"");
        hasLiquidated = true;
    }

    /// ============ SIMPLE TARGET FUNCTIONS (no exactlyOneZero issue) ============ ///

    function morpho_accrueInterest() public asActor {
        morpho.accrueInterest(marketParams);
    }

    function morpho_createMarket(MarketParams memory _marketParams) public asActor {
        morpho.createMarket(_marketParams);
    }

    function morpho_setAuthorization(address authorized, bool newIsAuthorized) public asActor {
        morpho.setAuthorization(authorized, newIsAuthorized);
    }

    function morpho_setAuthorizationWithSig(Authorization memory authorization, Signature memory signature) public asActor {
        morpho.setAuthorizationWithSig(authorization, signature);
    }

    /// ============ ADMIN FUNCTIONS (require onlyOwner) ============ ///
    /// Note: These use asActor but should use asAdmin for owner-only functions

    function morpho_enableIrm(address irm) public asActor {
        morpho.enableIrm(irm);
    }

    function morpho_enableLltv(uint256 lltv) public asActor {
        morpho.enableLltv(lltv);
    }

    function morpho_setFee(uint256 newFee) public asActor {
        morpho.setFee(marketParams, newFee);
    }

    function morpho_setFeeRecipient(address newFeeRecipient) public asActor {
        morpho.setFeeRecipient(newFeeRecipient);
    }

    function morpho_setOwner(address newOwner) public asActor {
        morpho.setOwner(newOwner);
    }

    /// ============ INTERNAL HELPERS (called by clamped functions) ============ ///
    /// The unclamped versions are kept internal to prevent Medusa from calling them directly

    function _morpho_supply(uint256 assets, uint256 shares, address onBehalf, bytes memory data) internal {
        morpho.supply(marketParams, assets, shares, onBehalf, data);
    }

    function _morpho_supplyCollateral(uint256 assets, address onBehalf, bytes memory data) internal {
        morpho.supplyCollateral(marketParams, assets, onBehalf, data);
    }

    function _morpho_borrow(uint256 assets, uint256 shares, address onBehalf, address receiver) internal {
        morpho.borrow(marketParams, assets, shares, onBehalf, receiver);
    }

    function _morpho_withdraw(uint256 assets, uint256 shares, address onBehalf, address receiver) internal {
        morpho.withdraw(marketParams, assets, shares, onBehalf, receiver);
    }

    function _morpho_withdrawCollateral(uint256 assets, address onBehalf, address receiver) internal {
        morpho.withdrawCollateral(marketParams, assets, onBehalf, receiver);
    }

    function _morpho_repay(uint256 assets, uint256 shares, address onBehalf, bytes memory data) internal {
        morpho.repay(marketParams, assets, shares, onBehalf, data);
        hasRepaid = true;
    }

    function _morpho_liquidate(address borrower, uint256 seizedAssets, uint256 repaidShares, bytes memory data) internal {
        morpho.liquidate(marketParams, borrower, seizedAssets, repaidShares, data);
        hasLiquidated = true;
    }

    function _morpho_flashLoan(address token, uint256 assets, bytes memory data) internal {
        morpho.flashLoan(token, assets, data);
    }
}
