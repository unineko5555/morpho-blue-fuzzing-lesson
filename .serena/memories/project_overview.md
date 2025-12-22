# Morpho Blue - Project Overview

## Purpose
Morpho Blue is a **noncustodial lending protocol** implemented for the Ethereum Virtual Machine (EVM). It offers a trustless primitive with increased efficiency and flexibility compared to existing lending platforms.

### Key Features
- **Permissionless risk management** and **permissionless market creation**
- **Oracle agnostic pricing**
- **Higher collateralization factors** and **improved interest rates**
- **Lower gas consumption**
- **Singleton implementation** with callbacks and free flash loans
- **Account management features**

## Repository Context
This repository is forked from the original Morpho repo for use with the **Recon Fuzz bootcamp** (https://book.getrecon.xyz//bootcamp/bootcamp_intro.html).

### Branches
- `main` - Original morpho repo with scaffolding
- `day-1` - Scaffolding up to end of part 1
- `day-2` - Scaffolding up to end of part 2

## Technology Stack
- **Solidity**: 0.8.19 (main contracts), ^0.8.0 (libraries/tests)
- **Build Tools**: Foundry (Forge), Hardhat
- **Testing**: 
  - Foundry (unit/integration/invariant tests)
  - Hardhat (TypeScript tests)
  - Halmos (symbolic execution)
  - Echidna (fuzzing)
  - Medusa (fuzzing)
  - Certora (formal verification)
- **Fuzzing Framework**: Chimera + Recon (setup-helpers)

## License
- Main contracts: BUSL-1.1 (Business Source License)
- Interfaces, libraries, mocks, tests: GPL-2.0-or-later

## Audits
Located in `audits/` directory:
- 2023-10-13: OpenZeppelin audit (Morpho Blue + Speed Jump IRM)
- 2023-11-13: Cantina managed review
- 2024-01-05: Cantina competition

## Whitepaper
Full protocol description available in `morpho-blue-whitepaper.pdf`
