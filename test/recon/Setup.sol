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
import {MockERC20} from "@recon/MockERC20.sol";  // For _newAsset() tokens
import {SafeMockERC20} from "test/recon/Mocks/SafeMockERC20.sol";

import {MarketParams, Market} from "src/interfaces/IMorpho.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    // Track our safe assets separately for internal use
    address[] private _safeAssets;
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
        morpho = new Morpho(address(this));

        // Add actors (address(this) is automatically added by ActorManager constructor)
        _addActor(address(0x413c)); // actor 1
        _addActor(address(0xb0b));  // actor 2

        // Use SafeMockERC20 to prevent unrestricted burn during fuzzing
        _newSafeAsset(18);
        _newSafeAsset(18);

        irmMock = new MockIRM();
        oracleMock = new OracleMock();
        // asset = new ERC20Mock();
        // liabirity = new ERC20Mock();
        oracleMock.setPrice(1e36);

        // Mints to all actors and approves allowances to Morpho
        _setupAssetsAndApprovals();

        // Resister a market
        morpho.enableIrm(address(irmMock));
        morpho.enableLltv(8e17); // 80%

        address[] memory assets = _getAssets();
        marketParams = MarketParams({
            loanToken: assets[1],
            collateralToken: assets[0],
            oracle: address(oracleMock),
            irm: address(irmMock),
            lltv: 8e17 // 80%
        });

        morpho.createMarket(marketParams);

        // asset.setBalance(address(this), type(uint88).max);
        // liabirity.setBalance(address(this), type(uint88).max);

        // asset.approve(address(morpho), type(uint256).max);
        // liabirity.approve(address(morpho), type(uint256).max);

    }

    function _setupAssetsAndApprovals() internal {
        address[] memory actors = _getActors();
        uint256 amount = type(uint88).max;

        // Process each asset separately to reduce stack depth
        for (uint256 assetIndex = 0; assetIndex < _getAssets().length; assetIndex++) {
            address token = _getAssets()[assetIndex];  // renamed to avoid shadowing

            // Mint to actors (MockERC20 from _newAsset uses mint, not setBalance)
            for (uint256 i = 0; i < actors.length; i++) {
                MockERC20(token).mint(actors[i], amount);
            }

            // Approve to morpho (approve needs prank for msg.sender)
            for (uint256 i = 0; i < actors.length; i++) {
                vm.prank(actors[i]);
                MockERC20(token).approve(address(morpho), type(uint256).max);
            }
        }
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

    /// @notice Creates a new SafeMockERC20 (burn requires approval) and adds to assets
    function _newSafeAsset(uint8 decimals) internal returns (address) {
        address asset_ = address(new SafeMockERC20("Safe Token", "SAFE", decimals));
        _addAsset(asset_);
        return asset_;
    }
}
