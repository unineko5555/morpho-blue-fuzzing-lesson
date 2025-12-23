// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

// Morpho imports
import {Id, MarketParams, Market} from "src/interfaces/IMorpho.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {MockERC20} from "@recon/MockERC20.sol";

// Targets
// NOTE: Always import and apply them in alphabetical order, so much easier to debug!
import { AdminTargets } from "./targets/AdminTargets.sol";
import { DoomsdayTargets } from "./targets/DoomsdayTargets.sol";
import { ManagersTargets } from "./targets/ManagersTargets.sol";
import { MorphoTargets } from "./targets/MorphoTargets.sol";

abstract contract TargetFunctions is
    AdminTargets,
    DoomsdayTargets,
    ManagersTargets,
    MorphoTargets
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    function oracle_setPrice(uint256 price) public {
        oracleMock.setPrice(price);
    }

    /// @dev Manipulate oracle price within reasonable range
    function oracle_setPrice_clamped(uint256 price) public {
        // Clamp price between 1e30 and 1e42 (reasonable range around 1e36)
        uint256 clampedPrice = (price % 1e12) * 1e30 + 1e30;
        oracleMock.setPrice(clampedPrice);
    }

    function morpho_createMarket_clamped(uint8 index, uint256 lltv) public {
        address loanToken = _getAssets()[index % _getAssets().length];
        address collateralToken = _getAsset();

        marketParams = MarketParams({
            loanToken: loanToken,
            collateralToken: collateralToken,
            oracle: address(oracleMock),
            irm: address(irmMock),
            lltv: lltv
        });

        morpho_createMarket(marketParams);
    }

    /// @dev Warp time forward and accrue interest
    function warp_time(uint256 secondsSeed) public {
        uint256 warpAmount = (secondsSeed % 365 days) + 1;
        vm.warp(block.timestamp + warpAmount);
        morpho.accrueInterest(marketParams);
    }

    /// @dev Combined: supply collateral + borrow in one sequence
    function morpho_leverage(uint256 collateralAmount, uint256 borrowPercent) public asActor {
        address actor = _getActor();
        address collateralToken = marketParams.collateralToken;
        uint256 balance = MockERC20(collateralToken).balanceOf(actor);
        if (balance == 0) return;

        uint256 clampedCollateral = (collateralAmount % balance) + 1;
        morpho.supplyCollateral(marketParams, clampedCollateral, actor, hex"");

        // Borrow between 1-79% of collateral
        uint256 borrowPct = (borrowPercent % 79) + 1;
        uint256 borrowAmount = (clampedCollateral * borrowPct) / 100;
        if (borrowAmount == 0) return;

        morpho.borrow(marketParams, borrowAmount, 0, actor, actor);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
}
