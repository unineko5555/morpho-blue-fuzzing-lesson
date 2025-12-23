// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {Id} from "src/interfaces/IMorpho.sol";
import {MockERC20} from "@recon/MockERC20.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
    struct Vars {
        // Market State
        uint128 totalSupplyAssets;
        uint128 totalSupplyShares;
        uint128 totalBorrowAssets;
        uint128 totalBorrowShares;
        uint128 lastUpdate;
        uint128 fee;

        // Token Balances (Morpho contract balances)
        uint256 morphoLoanTokenBalance;
        uint256 morphoCollateralTokenBalance;

        // Aggregated Position Sums
        uint256 sumOfSupplyShares;
        uint256 sumOfBorrowShares;
        uint256 sumOfCollateral;
    }

    Vars internal _before;
    Vars internal _after;

    modifier updateGhosts {
        __before();
        _;
        __after();
    }

    function __before() internal {
        _before = _captureState();
    }

    function __after() internal {
        _after = _captureState();
    }

    function _captureState() internal view returns (Vars memory vars) {
        Id id = MarketParamsLib.id(marketParams);

        // Capture market state
        (
            vars.totalSupplyAssets,
            vars.totalSupplyShares,
            vars.totalBorrowAssets,
            vars.totalBorrowShares,
            vars.lastUpdate,
            vars.fee
        ) = morpho.market(id);

        // Capture Morpho's token balances
        vars.morphoLoanTokenBalance = MockERC20(marketParams.loanToken).balanceOf(address(morpho));
        vars.morphoCollateralTokenBalance = MockERC20(marketParams.collateralToken).balanceOf(address(morpho));

        // Aggregate position sums across all actors
        address[] memory actors = _getActors();
        for (uint256 i = 0; i < actors.length; i++) {
            (uint256 supplyShares, uint128 borrowShares, uint128 collateral) = morpho.position(id, actors[i]);
            vars.sumOfSupplyShares += supplyShares;
            vars.sumOfBorrowShares += borrowShares;
            vars.sumOfCollateral += collateral;
        }
    }
}