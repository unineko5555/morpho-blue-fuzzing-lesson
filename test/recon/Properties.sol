// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {Id} from "src/interfaces/IMorpho.sol";
import {MockERC20} from "@recon/MockERC20.sol";

abstract contract Properties is BeforeAfter, Asserts {

    function canary_hasDoneRepay() public {
        t(!hasRepaid, "canary_hasDoneRepay");
    }

    function canary_hasLiquidated() public {
        t(!hasLiquidated, "canary_hasLiquidated");
    }

    function canary_morphoHasCode() public {
        t(address(morpho).code.length > 0, "morpho_has_no_code");
    }

    /// @dev Verify Morpho is the correct local deployment (not a fork/etch)
    function canary_morphoIsLocal() public view {
        // Check code exists
        require(address(morpho).code.length > 0, "morpho has no code");

        // Check owner is this contract (Setup deploys with address(this))
        require(morpho.owner() == address(this), "morpho owner mismatch");
    }

    /// @dev Verify market exists and is properly configured
    function canary_marketExists() public view {
        Id id = MarketParamsLib.id(marketParams);
        // market() returns tuple: (totalSupplyAssets, totalSupplyShares, totalBorrowAssets, totalBorrowShares, lastUpdate, fee)
        (,,,, uint128 lastUpdate,) = morpho.market(id);
        require(lastUpdate > 0, "market not created");
    }

    /// @dev Invariant: totalSupplyAssets >= totalBorrowAssets
    function invariant_supplyGteBorrow() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);
        (uint128 totalSupply,, uint128 totalBorrow,,,) = morpho.market(id);
        return totalSupply >= totalBorrow;
    }

    // ============ NEW CRITICAL INVARIANTS ============ //

    /// @dev Invariant 2: Sum of all supplyShares == totalSupplyShares
    /// Note: Must include feeRecipient's shares when fees are enabled
    /// If fee is set but feeRecipient is address(0), shares go to address(0)
    function invariant_supplySharesConsistency() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);
        (, uint128 totalSupplyShares,,,, uint128 fee) = morpho.market(id);

        uint256 sumShares = 0;
        address[] memory actors = _getActors();
        for (uint256 i = 0; i < actors.length; i++) {
            (uint256 supplyShares,,) = morpho.position(id, actors[i]);
            sumShares += supplyShares;
        }

        // Include feeRecipient's shares (fee accrual creates shares for feeRecipient)
        // When fee > 0 and feeRecipient == address(0), shares go to address(0)
        address feeRecipient = morpho.feeRecipient();
        if (fee > 0) {
            (uint256 feeRecipientShares,,) = morpho.position(id, feeRecipient);
            sumShares += feeRecipientShares;
        }

        return sumShares == totalSupplyShares;
    }

    /// @dev Invariant 3: Sum of all borrowShares == totalBorrowShares
    function invariant_borrowSharesConsistency() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);
        (,,, uint128 totalBorrowShares,,) = morpho.market(id);

        uint256 sumShares = 0;
        address[] memory actors = _getActors();
        for (uint256 i = 0; i < actors.length; i++) {
            (, uint128 borrowShares,) = morpho.position(id, actors[i]);
            sumShares += borrowShares;
        }

        return sumShares == totalBorrowShares;
    }

    /// @dev Invariant 4: Morpho holds enough collateral for all positions
    function invariant_collateralBalanceConsistency() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);

        uint256 sumCollateral = 0;
        address[] memory actors = _getActors();
        for (uint256 i = 0; i < actors.length; i++) {
            (,, uint128 collateral) = morpho.position(id, actors[i]);
            sumCollateral += collateral;
        }

        uint256 morphoBalance = MockERC20(marketParams.collateralToken).balanceOf(address(morpho));
        return morphoBalance >= sumCollateral;
    }

    /// @dev Invariant 5: Morpho holds enough loanToken for withdrawals
    /// loanToken.balanceOf(morpho) >= totalSupplyAssets - totalBorrowAssets
    function invariant_loanTokenSolvency() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);
        (uint128 totalSupply,, uint128 totalBorrow,,,) = morpho.market(id);

        uint256 morphoBalance = MockERC20(marketParams.loanToken).balanceOf(address(morpho));

        // Morpho should hold at least (totalSupply - totalBorrow) in loanToken
        // This represents the available liquidity
        if (totalSupply >= totalBorrow) {
            return morphoBalance >= (totalSupply - totalBorrow);
        }
        return false; // This should never happen (covered by invariant_supplyGteBorrow)
    }
}
