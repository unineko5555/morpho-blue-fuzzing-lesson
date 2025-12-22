# Morpho Blue - Code Style and Conventions

## Solidity Version
- Main contract (Morpho.sol): `pragma solidity 0.8.19;`
- Libraries: `pragma solidity ^0.8.0;`
- Tests: `pragma solidity ^0.8.0;`

## File Organization

### SPDX License Headers
```solidity
// SPDX-License-Identifier: BUSL-1.1     // Main contracts
// SPDX-License-Identifier: GPL-2.0-or-later  // Libraries, interfaces, tests
```

### Contract Layout (in order)
1. Imports
2. Constants (IMMUTABLES section)
3. Storage variables (STORAGE section)
4. Constructor
5. Modifiers
6. External functions (grouped by functionality)
7. Internal/Private functions

### Section Comments
Use uppercase section headers:
```solidity
/* IMMUTABLES */
/* STORAGE */
/* CONSTRUCTOR */
/* MODIFIERS */
/* ONLY OWNER FUNCTIONS */
/* SUPPLY MANAGEMENT */
/* BORROW MANAGEMENT */
/* COLLATERAL MANAGEMENT */
/* LIQUIDATION */
/* FLASH LOANS */
/* AUTHORIZATION */
/* INTEREST MANAGEMENT */
/* HEALTH CHECK */
/* STORAGE VIEW */
```

## Naming Conventions

### Variables
- State variables: camelCase (e.g., `totalSupplyAssets`, `feeRecipient`)
- Local variables: camelCase
- Constants: UPPER_SNAKE_CASE (e.g., `MAX_FEE`, `ORACLE_PRICE_SCALE`)
- Internal constants in libraries: UPPER_SNAKE_CASE

### Functions
- Public/External: camelCase (e.g., `supply`, `withdraw`, `createMarket`)
- Internal/Private: _prefixCamelCase (e.g., `_accrueInterest`, `_isHealthy`)

### Types
- Contracts: PascalCase (e.g., `Morpho`, `MathLib`)
- Structs: PascalCase (e.g., `MarketParams`, `Position`, `Market`)
- Custom types: PascalCase (e.g., `type Id is bytes32`)
- Events: PascalCase (e.g., `SetOwner`, `Supply`)
- Errors: UPPER_SNAKE_CASE strings (e.g., `"not owner"`, `"market not created"`)

## Documentation

### NatSpec Comments
```solidity
/// @title Title
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice Brief description
/// @dev Implementation details

/// @param paramName Description
/// @return Description
```

### Library Documentation Pattern
```solidity
/// @title LibraryName
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice Library description.
library LibraryName {
    /// @dev Detailed function description.
    function functionName(...) internal pure returns (...) {
        ...
    }
}
```

## Code Patterns

### Using Statements
```solidity
using MathLib for uint256;
using UtilsLib for uint256;
using SharesMathLib for uint256;
using SafeTransferLib for IERC20;
using MarketParamsLib for MarketParams;
```

### Require Pattern (Error Messages)
```solidity
require(condition, ErrorsLib.ERROR_MESSAGE);
```

### Safe Casting Pattern
```solidity
// Comment: Safe "unchecked" cast.
market[id].lastUpdate = uint128(block.timestamp);
```

### Event Emission
Events are emitted via library:
```solidity
emit EventsLib.EventName(param1, param2);
```

## Library Design

### Errors Library
- All error messages as `string internal constant`
- Lowercase error messages (e.g., `"not owner"`)

### Events Library
- All events defined in EventsLib
- Extensive NatSpec documentation

### Math Libraries
- WAD-based arithmetic (1e18 scale)
- Separate rounding functions (Down/Up variants)

## Assembly Usage
Gas-optimized inline assembly for simple operations:
```solidity
function exactlyOneZero(uint256 x, uint256 y) internal pure returns (bool z) {
    assembly {
        z := xor(iszero(x), iszero(y))
    }
}
```

## Test Conventions (Recon/Chimera)

### Target Functions Pattern
- Import targets in alphabetical order
- Extend from multiple target contracts
- Use modifiers `asAdmin` and `asActor` for prank operations

### File Naming
- Test setup: `Setup.sol`
- Properties: `Properties.sol`
- Targets: `targets/*.sol`
- Tester entry: `CryticTester.sol` (Echidna/Medusa)
- Foundry bridge: `CryticToFoundry.sol`
