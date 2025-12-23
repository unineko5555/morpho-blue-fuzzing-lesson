// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {MockERC20} from "@recon/MockERC20.sol";

/// @notice MockERC20 with restricted burn - only owner or approved can burn
/// @dev This prevents unrealistic burn scenarios during fuzzing
contract SafeMockERC20 is MockERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        MockERC20(_name, _symbol, _decimals)
    {}

    /// @notice Override burn to only allow burning own tokens or with allowance
    function burn(address from, uint256 value) public override {
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "INSUFFICIENT_ALLOWANCE");
                allowance[from][msg.sender] = allowed - value;
            }
        }
        _burn(from, value);
    }
}
