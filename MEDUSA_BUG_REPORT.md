# Medusa Bug Report: Coverage Issue with Immutable Variables

## Title
`[Bug]: Coverage shows 0% for contracts with immutable variables due to bytecode mismatch`

---

## Description

Coverage tracking fails for contracts that contain `immutable` variables. The deployed runtime bytecode differs from the compiled bytecode because immutable variable values are embedded into the bytecode at deployment time. This causes crytic-compile's bytecode matching to fail, resulting in 0% coverage even when the contract's functions are demonstrably being executed.

**Root Cause:**
When a Solidity contract has immutable variables (e.g., `bytes32 public immutable DOMAIN_SEPARATOR`), the compiler generates placeholder bytecode. At deployment time, the constructor fills in the actual values, which become part of the runtime bytecode. This causes a mismatch between:
- The compiled bytecode that crytic-compile uses for source mapping
- The actual deployed runtime bytecode in the EVM

**Evidence that code IS being executed:**
- Canary invariants designed to fail when specific functions are called DO fail
- Other library contracts (MathLib, SharesMathLib, UtilsLib) show coverage correctly
- Only contracts with immutable variables show 0% coverage

**Attempted workarounds (none worked):**
- `USE_FULL_BYTECODE=true` environment variable
- `forge build --via-ir` compilation
- `--compile-force-framework foundry` flag
- Same issue occurs in Echidna v2.2.7 (confirming this is a crytic-compile issue)

---

## Reproduction Steps

1. Clone Morpho Blue repository or any project with immutable variables:
```bash
git clone https://github.com/morpho-org/morpho-blue
cd morpho-blue
```

2. Note that `src/Morpho.sol` contains an immutable variable (line 49):
```solidity
bytes32 public immutable DOMAIN_SEPARATOR;
```

3. Set up a basic fuzzing harness that calls Morpho functions (supply, borrow, etc.)

4. Create `medusa.json`:
```json
{
  "fuzzing": {
    "workers": 10,
    "testLimit": 10000,
    "targetContracts": ["YourTestContract"],
    "coverageEnabled": true,
    "testing": {
      "testAllContracts": true,
      "propertyTesting": {
        "enabled": true,
        "testPrefixes": ["invariant_"]
      }
    }
  },
  "compilation": {
    "platform": "crytic-compile",
    "platformConfig": {
      "target": ".",
      "args": ["--foundry-compile-all", "--compile-force-framework", "foundry"]
    }
  }
}
```

5. Run Medusa:
```bash
medusa fuzz
```

6. Observe coverage results:
```
src/Morpho.sol                    0.0%    (0/703)
src/libraries/MathLib.sol        38.5%   (5/13)
src/libraries/SharesMathLib.sol  66.7%   (8/12)
```

**Expected:** Morpho.sol should show coverage since functions are being called
**Actual:** Morpho.sol shows 0% coverage while libraries show correct coverage

---

## Medusa Version
```
1.3.1
```

---

## Slither Version
```
0.10.4
```

---

## Crytic-Compile Version
```
0.3.7
```

---

## Operating System
```
macOS (Darwin 24.1.0)
```

---

## Additional Context

This issue affects any contract with immutable variables, which is a common pattern in production Solidity code (e.g., for storing deployment-time constants like DOMAIN_SEPARATOR for EIP-712 signatures, token addresses, etc.).

The same behavior is observed in Echidna v2.2.7, suggesting this is a fundamental limitation in crytic-compile's bytecode matching approach rather than a Medusa-specific issue.

A potential solution could involve:
1. Detecting immutable variable placeholders in compiled bytecode
2. Using fuzzy bytecode matching that ignores immutable variable regions
3. Using source-level instrumentation instead of bytecode matching for coverage

---

## Related Files in This Repository

- `src/Morpho.sol:49` - Contains the problematic immutable variable
- `test/recon/targets/MorphoTargets.sol` - Clamped target functions for fuzzing
- `test/recon/Properties.sol` - Invariants and canary tests
- `medusa.json` - Medusa configuration
- `echidna.yaml` - Echidna configuration (same issue observed)
