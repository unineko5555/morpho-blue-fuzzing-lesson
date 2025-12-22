// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import "src/Morpho.sol";

import {ERC20Mock} from "src/mocks/ERC20Mock.sol";
import {OracleMock} from "src/mocks/OracleMock.sol";
import {MockIRM} from "test/recon/Mocks/MockIRM.sol";

import {MarketParams, Market} from "src/interfaces/IMorpho.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    Morpho morpho;

    // Deploy MockIRM and set it in Morpho if needed
    MockIRM irmMock;
    OracleMock oracleMock;
    ERC20Mock asset;
    ERC20Mock liabirity;

    MarketParams marketParams;

    // Canaries
    bool hasLiquidated;
    bool hasRepaid;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        morpho = new Morpho(address(this)); // TODO: Add parameters here
        //address(this)
        _addActor(address(0x413c));
        _addActor(address(0xb0b));

        _newAsset(18);
        _newAsset(18);

        irmMock = new MockIRM();
        oracleMock = new OracleMock();
        asset = new ERC20Mock();
        liabirity = new ERC20Mock();

        // Resister a market
        morpho.enableIrm(address(irmMock));
        morpho.enableLltv(8e17); // 80%

        marketParams = MarketParams({
            loanToken: address(liabirity),
            collateralToken: address(asset),
            oracle: address(oracleMock),
            irm: address(irmMock),
            lltv: 8e17 // 80%
        });

        morpho.createMarket(marketParams);

        asset.setBalance(address(this), type(uint88).max);
        liabirity.setBalance(address(this), type(uint88).max);

        asset.approve(address(morpho), type(uint256).max);
        liabirity.approve(address(morpho), type(uint256).max);

    }

    /// === MODIFIERS === ///
    /// Prank admin and actor

    modifier asAdmin() {
        vm.prank(address(this));
        _;
    }

    modifier asActor() {
        vm.prank(address(_getActor()));
        _;
    }
}
