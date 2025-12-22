// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

// Morpho imports
import {MarketParams} from "src/interfaces/IMorpho.sol";

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
    function create_new_market(uint8 index) public {
        // Active token collateral
        // Other token is debt

        address loanToken = _getAssets()[index] % (_getAssets().length + 1);
        address collateralToken = _getAssets();

        marketParams = MarketParams({
            loanToken: address(liabirity),
            collateralToken: address(asset),
            oracle: address(oracleMock),
            irm: address(irmMock),
            lltv: 8e17 // 80%
        });

    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
}
