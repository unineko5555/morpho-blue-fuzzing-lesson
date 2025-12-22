# Morpho Blue - Task Completion Checklist

## Before Committing Code

### 1. Code Quality
- [ ] Code follows Solidity style conventions
- [ ] NatSpec documentation added for public/external functions
- [ ] No unused imports or variables
- [ ] No hardcoded values (use constants)

### 2. Formatting
```bash
# Run formatter
forge fmt

# Verify formatting
yarn lint
```

### 3. Build Verification
```bash
# Build must pass
yarn build:forge

# Check contract sizes
forge build --sizes
```

### 4. Testing

#### Unit/Integration Tests
```bash
# All Forge tests must pass
yarn test:forge

# Run with verbosity for debugging
forge test -vvv
```

#### Invariant Tests
```bash
# Invariant tests must pass
yarn test:forge:invariant
```

#### Fuzz Testing (if modifying core logic)
```bash
# Run Echidna
echidna test/recon/CryticTester.sol --contract CryticTester --config echidna.yaml

# Run Medusa
medusa fuzz
```

### 5. Gas Considerations
```bash
# Generate gas report
forge test --gas-report

# Check for gas regressions
forge snapshot --diff
```

## After Adding New Features

### Contract Changes
- [ ] Update relevant interfaces (IMorpho.sol, IMorphoBase.sol)
- [ ] Add events to EventsLib.sol if needed
- [ ] Add errors to ErrorsLib.sol if needed
- [ ] Update tests to cover new functionality

### Library Changes
- [ ] Ensure library functions are `internal pure` or `internal view`
- [ ] Add comprehensive NatSpec documentation
- [ ] Test edge cases (overflow, underflow, zero inputs)

### Test Changes (Recon Framework)
- [ ] Update Setup.sol if new contracts/actors needed
- [ ] Add target functions in appropriate target file
- [ ] Update Properties.sol for new invariants
- [ ] Ensure BeforeAfter.sol captures state changes

## Security Checklist

### Before PR
- [ ] No reentrancy vulnerabilities
- [ ] Integer overflow/underflow handled
- [ ] Access control properly implemented
- [ ] External calls handled safely
- [ ] State changes before external calls (CEI pattern)

### For Significant Changes
- [ ] Consider Certora verification rules
- [ ] Run symbolic execution with Halmos
- [ ] Extensive fuzz testing campaign

## Commit Message Convention
Follow Conventional Commits:
```
feat: add new feature
fix: resolve bug
docs: update documentation
test: add/update tests
refactor: code restructuring
chore: maintenance tasks
```
