# Morpho Blue - Codebase Structure

## Directory Layout
```
morpho-blue/
├── src/                          # Source code
│   ├── Morpho.sol               # Main lending protocol contract
│   ├── interfaces/              # Contract interfaces
│   │   ├── IMorpho.sol          # Main interface with types
│   │   ├── IMorphoCallbacks.sol # Callback interfaces
│   │   ├── IIrm.sol             # Interest Rate Model interface
│   │   ├── IOracle.sol          # Oracle interface
│   │   └── IERC20.sol           # ERC20 interface
│   ├── libraries/               # Internal libraries
│   │   ├── ConstantsLib.sol     # Protocol constants
│   │   ├── ErrorsLib.sol        # Error messages
│   │   ├── EventsLib.sol        # Event definitions
│   │   ├── MathLib.sol          # Fixed-point math (WAD)
│   │   ├── SharesMathLib.sol    # Share/asset conversion
│   │   ├── MarketParamsLib.sol  # Market parameter helpers
│   │   ├── UtilsLib.sol         # Utility functions
│   │   ├── SafeTransferLib.sol  # Safe ERC20 transfers
│   │   └── periphery/           # Helper libs for integrators
│   │       ├── MorphoLib.sol
│   │       ├── MorphoBalancesLib.sol
│   │       └── MorphoStorageLib.sol
│   └── mocks/                   # Test mock contracts
│       ├── ERC20Mock.sol
│       ├── IrmMock.sol
│       ├── OracleMock.sol
│       └── FlashBorrowerMock.sol
├── test/                        # Test files
│   └── recon/                   # Recon/Chimera fuzzing setup
│       ├── Setup.sol            # Test setup (actors, assets)
│       ├── Properties.sol       # Invariant properties
│       ├── BeforeAfter.sol      # State snapshots
│       ├── TargetFunctions.sol  # Target function aggregator
│       ├── CryticTester.sol     # Echidna/Medusa entry
│       ├── CryticToFoundry.sol  # Foundry integration
│       └── targets/             # Target function modules
│           ├── AdminTargets.sol
│           ├── DoomsdayTargets.sol
│           ├── ManagersTargets.sol
│           └── MorphoTargets.sol
├── certora/                     # Formal verification
│   ├── specs/                   # Certora spec files (.spec)
│   ├── confs/                   # Configuration files (.conf)
│   ├── helpers/                 # Verification helpers
│   └── dispatch/                # ERC20 dispatch contracts
├── audits/                      # Security audit reports
├── lib/                         # Dependencies (git submodules)
│   ├── forge-std/               # Foundry testing stdlib
│   ├── chimera/                 # Chimera fuzzing framework
│   ├── setup-helpers/           # Recon setup helpers
│   └── halmos-cheatcodes/       # Halmos symbolic execution
├── foundry.toml                 # Foundry configuration
├── echidna.yaml                 # Echidna configuration
├── medusa.json                  # Medusa configuration
├── halmos.toml                  # Halmos configuration
├── hardhat.config.ts            # Hardhat configuration
├── package.json                 # npm scripts & dependencies
├── remappings.txt               # Solidity import remappings
└── morpho-blue-whitepaper.pdf   # Protocol whitepaper
```

## Key Contracts

### Morpho.sol (Main Contract)
The singleton lending protocol implementing:
- **Supply Management**: `supply()`, `withdraw()`
- **Borrow Management**: `borrow()`, `repay()`
- **Collateral Management**: `supplyCollateral()`, `withdrawCollateral()`
- **Liquidation**: `liquidate()`
- **Flash Loans**: `flashLoan()`
- **Authorization**: `setAuthorization()`, `setAuthorizationWithSig()`
- **Admin Functions**: `setOwner()`, `enableIrm()`, `enableLltv()`, `setFee()`, `setFeeRecipient()`
- **Market Creation**: `createMarket()`

### Core Data Types (IMorpho.sol)
```solidity
type Id is bytes32;  // Market identifier

struct MarketParams {
    address loanToken;
    address collateralToken;
    address oracle;
    address irm;
    uint256 lltv;
}

struct Position {
    uint256 supplyShares;
    uint128 borrowShares;
    uint128 collateral;
}

struct Market {
    uint128 totalSupplyAssets;
    uint128 totalSupplyShares;
    uint128 totalBorrowAssets;
    uint128 totalBorrowShares;
    uint128 lastUpdate;
    uint128 fee;
}
```

### Key Constants (ConstantsLib.sol)
- `MAX_FEE`: 0.25e18 (25%)
- `ORACLE_PRICE_SCALE`: 1e36
- `LIQUIDATION_CURSOR`: 0.3e18
- `MAX_LIQUIDATION_INCENTIVE_FACTOR`: 1.15e18

## Import Remappings
```
chimera/=lib/chimera/src/
forge-std/=lib/forge-std/src/
halmos-cheatcodes/=lib/halmos-cheatcodes/src/
@chimera/=lib/chimera/src/
@recon/=lib/setup-helpers/src/
```

## Test Structure (Recon Framework)

### Inheritance Chain
```
Setup (BaseSetup, ActorManager, AssetManager, Utils)
    ↓
BeforeAfter
    ↓
Properties (Asserts)
    ↓
TargetFunctions (AdminTargets, DoomsdayTargets, ManagersTargets, MorphoTargets)
    ↓
CryticTester (for Echidna/Medusa)
CryticToFoundry (for Foundry)
```

## Certora Verification Specs
- `AccrueInterest.spec` - Interest accrual correctness
- `AssetsAccounting.spec` - Asset/share accounting
- `ConsistentState.spec` - State consistency
- `ExchangeRate.spec` - Share exchange rate properties
- `Health.spec` - Position health checks
- `Liveness.spec` - Protocol liveness
- `Reentrancy.spec` - Reentrancy protection
- `Reverts.spec` - Revert conditions
- `StayHealthy.spec` - Health preservation
- `Transfer.spec` - Token transfer safety
