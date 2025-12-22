# Morpho Blue - Suggested Commands

## Setup & Installation
```bash
# Install dependencies
yarn

# Or with npm (uses husky + forge install)
npm run prepare
```

## Building
```bash
# Build with Foundry (optimized, production)
yarn build:forge
# or: FOUNDRY_PROFILE=build forge build

# Build with Hardhat
yarn build:hardhat
# or: npx hardhat compile
```

## Testing

### Foundry Tests
```bash
# Run all Forge tests
yarn test:forge
# or: FOUNDRY_PROFILE=test forge test

# Run only invariant tests
yarn test:forge:invariant
# or: FOUNDRY_MATCH_CONTRACT=InvariantTest yarn test:forge

# Run only integration tests
yarn test:forge:integration
# or: FOUNDRY_MATCH_CONTRACT=IntegrationTest yarn test:forge

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testFunctionName
```

### Hardhat Tests
```bash
# Run Hardhat tests
yarn test:hardhat
# or: npx hardhat test
```

### Symbolic Execution (Halmos)
```bash
yarn test:halmos
# or: FOUNDRY_PROFILE=test halmos
```

## Fuzzing

### Echidna
```bash
# Run Echidna fuzzer (configuration in echidna.yaml)
echidna test/recon/CryticTester.sol --contract CryticTester --config echidna.yaml
```

### Medusa
```bash
# Run Medusa fuzzer (configuration in medusa.json)
medusa fuzz
```

## Linting & Formatting
```bash
# Check formatting (all)
yarn lint

# Check Solidity formatting
yarn lint:forge
# or: forge fmt --check

# Check Hardhat TypeScript
yarn lint:hardhat
# or: prettier --check test/hardhat

# Fix formatting (all)
yarn lint:fix

# Fix Solidity formatting
yarn lint:forge:fix
# or: forge fmt

# Fix TypeScript formatting
yarn lint:hardhat:fix
# or: prettier --write test/hardhat
```

## Cleaning
```bash
# Clean all build artifacts
yarn clean
# or: npx hardhat clean && forge clean
```

## Certora Verification
```bash
# Run Certora prover (requires Certora CLI)
# Configuration files in certora/confs/
certoraRun certora/confs/<ConfigFile>.conf
```

## Useful Foundry Commands
```bash
# Show contract sizes
forge build --sizes

# Gas report
forge test --gas-report

# Coverage
forge coverage

# Generate snapshot
forge snapshot

# Compare gas changes
forge snapshot --diff
```

## Git Hooks (via Husky)
Pre-commit hooks automatically run:
- `forge fmt` on .sol files
- `prettier` on .js, .ts, .json, .yml files
