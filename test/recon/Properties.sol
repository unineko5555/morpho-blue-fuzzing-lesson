// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {Id} from "src/interfaces/IMorpho.sol";

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
}
