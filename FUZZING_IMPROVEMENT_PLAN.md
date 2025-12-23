# Morpho Blue Fuzzing Framework 改善計画

## 現状分析

### 現在の構成
- **Setup.sol**: 2アクター（0x413c, 0xb0b）、2アセット、1マーケット
- **BeforeAfter.sol**: 空のVars構造体（未使用）
- **Properties.sol**: 1インバリアント + 4カナリア
- **MorphoTargets.sol**: 6つのclamped関数 + 2つの未clamp清算関数

### 発見された問題
1. `canary_hasLiquidated` が発火していない → 清算ロジックが未テスト
2. Ghost変数が未実装 → 状態遷移の追跡不可
3. インバリアントが1つのみ → 会計整合性の検証不足
4. 価格操作と清算の連携なし → 清算シナリオの探索不足

---

## 改善計画

### 1. BeforeAfter.sol - Ghost変数の追加

**目的**: 操作前後の状態を追跡し、状態遷移の正確性を検証

```solidity
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {Id} from "src/interfaces/IMorpho.sol";
import {MockERC20} from "@recon/MockERC20.sol";

abstract contract BeforeAfter is Setup {
    struct Vars {
        // Market State
        uint128 totalSupplyAssets;
        uint128 totalSupplyShares;
        uint128 totalBorrowAssets;
        uint128 totalBorrowShares;
        uint128 lastUpdate;
        uint128 fee;

        // Token Balances (Morpho contract balances)
        uint256 morphoLoanTokenBalance;
        uint256 morphoCollateralTokenBalance;

        // Aggregated Position Sums
        uint256 sumOfSupplyShares;
        uint256 sumOfBorrowShares;
        uint256 sumOfCollateral;
    }

    Vars internal _before;
    Vars internal _after;

    modifier updateGhosts {
        __before();
        _;
        __after();
    }

    function __before() internal {
        _before = _captureState();
    }

    function __after() internal {
        _after = _captureState();
    }

    function _captureState() internal view returns (Vars memory vars) {
        Id id = MarketParamsLib.id(marketParams);

        // Capture market state
        (
            vars.totalSupplyAssets,
            vars.totalSupplyShares,
            vars.totalBorrowAssets,
            vars.totalBorrowShares,
            vars.lastUpdate,
            vars.fee
        ) = morpho.market(id);

        // Capture Morpho's token balances
        vars.morphoLoanTokenBalance = MockERC20(marketParams.loanToken).balanceOf(address(morpho));
        vars.morphoCollateralTokenBalance = MockERC20(marketParams.collateralToken).balanceOf(address(morpho));

        // Aggregate position sums across all actors
        address[] memory actors = _getActors();
        for (uint256 i = 0; i < actors.length; i++) {
            (uint256 supplyShares, uint128 borrowShares, uint128 collateral) = morpho.position(id, actors[i]);
            vars.sumOfSupplyShares += supplyShares;
            vars.sumOfBorrowShares += borrowShares;
            vars.sumOfCollateral += collateral;
        }
    }
}
```

---

### 2. Properties.sol - インバリアント追加

**優先度順に実装するインバリアント**

| # | インバリアント名 | 説明 | 重要度 |
|---|-----------------|------|--------|
| 1 | `invariant_supplyGteBorrow` | totalSupply >= totalBorrow | Critical (既存) |
| 2 | `invariant_supplySharesConsistency` | Σ position.supplyShares == totalSupplyShares | Critical |
| 3 | `invariant_borrowSharesConsistency` | Σ position.borrowShares == totalBorrowShares | Critical |
| 4 | `invariant_collateralBalanceConsistency` | Σ position.collateral <= collateralToken.balanceOf(morpho) | Critical |
| 5 | `invariant_loanTokenSolvency` | loanToken.balanceOf(morpho) >= totalSupply - totalBorrow | Critical |
| 6 | `invariant_noNegativeShares` | 全てのシェア値 >= 0 (uint128なので自動的に満たす) | High |
| 7 | `invariant_marketStateConsistency` | lastUpdate > 0 なら市場は有効 | Medium |

```solidity
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {Id} from "src/interfaces/IMorpho.sol";
import {MockERC20} from "@recon/MockERC20.sol";

abstract contract Properties is BeforeAfter, Asserts {

    // ============ CANARY TESTS ============ //

    function canary_hasDoneRepay() public {
        t(!hasRepaid, "canary_hasDoneRepay");
    }

    function canary_hasLiquidated() public {
        t(!hasLiquidated, "canary_hasLiquidated");
    }

    function canary_morphoHasCode() public {
        t(address(morpho).code.length > 0, "morpho_has_no_code");
    }

    function canary_morphoIsLocal() public view {
        require(address(morpho).code.length > 0, "morpho has no code");
        require(morpho.owner() == address(this), "morpho owner mismatch");
    }

    function canary_marketExists() public view {
        Id id = MarketParamsLib.id(marketParams);
        (,,,, uint128 lastUpdate,) = morpho.market(id);
        require(lastUpdate > 0, "market not created");
    }

    // ============ CRITICAL INVARIANTS ============ //

    /// @dev Invariant 1: totalSupplyAssets >= totalBorrowAssets
    function invariant_supplyGteBorrow() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);
        (uint128 totalSupply,, uint128 totalBorrow,,,) = morpho.market(id);
        return totalSupply >= totalBorrow;
    }

    /// @dev Invariant 2: Sum of all supplyShares == totalSupplyShares
    function invariant_supplySharesConsistency() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);
        (, uint128 totalSupplyShares,,,,) = morpho.market(id);

        uint256 sumShares = 0;
        address[] memory actors = _getActors();
        for (uint256 i = 0; i < actors.length; i++) {
            (uint256 supplyShares,,) = morpho.position(id, actors[i]);
            sumShares += supplyShares;
        }

        return sumShares == totalSupplyShares;
    }

    /// @dev Invariant 3: Sum of all borrowShares == totalBorrowShares
    function invariant_borrowSharesConsistency() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);
        (,,, uint128 totalBorrowShares,,) = morpho.market(id);

        uint256 sumShares = 0;
        address[] memory actors = _getActors();
        for (uint256 i = 0; i < actors.length; i++) {
            (, uint128 borrowShares,) = morpho.position(id, actors[i]);
            sumShares += borrowShares;
        }

        return sumShares == totalBorrowShares;
    }

    /// @dev Invariant 4: Morpho holds enough collateral for all positions
    function invariant_collateralBalanceConsistency() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);

        uint256 sumCollateral = 0;
        address[] memory actors = _getActors();
        for (uint256 i = 0; i < actors.length; i++) {
            (,, uint128 collateral) = morpho.position(id, actors[i]);
            sumCollateral += collateral;
        }

        uint256 morphoBalance = MockERC20(marketParams.collateralToken).balanceOf(address(morpho));
        return morphoBalance >= sumCollateral;
    }

    /// @dev Invariant 5: Morpho holds enough loanToken for withdrawals
    /// loanToken.balanceOf(morpho) >= totalSupplyAssets - totalBorrowAssets
    function invariant_loanTokenSolvency() public view returns (bool) {
        Id id = MarketParamsLib.id(marketParams);
        (uint128 totalSupply,, uint128 totalBorrow,,,) = morpho.market(id);

        uint256 morphoBalance = MockERC20(marketParams.loanToken).balanceOf(address(morpho));

        // Morpho should hold at least (totalSupply - totalBorrow) in loanToken
        // This represents the available liquidity
        if (totalSupply >= totalBorrow) {
            return morphoBalance >= (totalSupply - totalBorrow);
        }
        return false; // This should never happen (covered by invariant_supplyGteBorrow)
    }

    // ============ HIGH PRIORITY INVARIANTS ============ //

    /// @dev Invariant 6: Interest accrual is monotonic (totalBorrow only increases over time)
    /// Note: This uses ghost variables from BeforeAfter
    function invariant_interestMonotonicity() public view returns (bool) {
        // After accrueInterest, totalBorrowAssets should be >= before
        // Only check if time has passed and there was outstanding debt
        if (_before.totalBorrowAssets > 0 && _after.lastUpdate > _before.lastUpdate) {
            return _after.totalBorrowAssets >= _before.totalBorrowAssets;
        }
        return true;
    }
}
```

---

### 3. MorphoTargets.sol - ターゲット関数追加

**追加すべきターゲット関数**

#### A. 清算のClamp版
```solidity
/// @dev Liquidate after making position unhealthy via price manipulation
function morpho_liquidate_clamped(uint8 borrowerSeed) public {
    address[] memory actors = _getActors();
    address borrower = actors[borrowerSeed % actors.length];

    Id id = MarketParamsLib.id(marketParams);
    (, uint128 borrowShares, uint128 collateral) = morpho.position(id, borrower);

    // Skip if no borrow position
    if (borrowShares == 0 || collateral == 0) return;

    // Drop oracle price to make position unhealthy
    // Current price is 1e36, drop to 50% to ensure liquidatable
    uint256 currentPrice = oracleMock.price();
    oracleMock.setPrice(currentPrice / 2);

    // Now liquidate with 1 unit of seized collateral
    vm.prank(_getActor());
    try morpho.liquidate(marketParams, borrower, 1, 0, hex"") {
        hasLiquidated = true;
    } catch {}

    // Restore price
    oracleMock.setPrice(currentPrice);
}
```

#### B. 時間経過シミュレーション
```solidity
/// @dev Warp time forward and accrue interest
function warp_time(uint256 secondsSeed) public {
    uint256 warpAmount = (secondsSeed % 365 days) + 1;
    vm.warp(block.timestamp + warpAmount);
    morpho.accrueInterest(marketParams);
}
```

#### C. アグレッシブなBorrow（LLTVギリギリ）
```solidity
/// @dev Borrow at 79% of collateral (just under 80% LLTV)
function morpho_borrow_aggressive(uint256 assets) public asActor {
    address actor = _getActor();
    Id id = MarketParamsLib.id(marketParams);
    (,, uint128 collateral) = morpho.position(id, actor);
    if (collateral == 0) return;

    // Check current borrow
    (, uint128 currentBorrowShares,) = morpho.position(id, actor);
    (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) = morpho.market(id);

    // Calculate current borrowed amount
    uint256 currentBorrowed = 0;
    if (totalBorrowShares > 0) {
        currentBorrowed = uint256(currentBorrowShares) * totalBorrowAssets / totalBorrowShares;
    }

    // Max borrow at 79% LLTV
    uint256 maxBorrow = (uint256(collateral) * 79) / 100;
    if (maxBorrow <= currentBorrowed) return;

    uint256 availableToBorrow = maxBorrow - currentBorrowed;
    uint256 clampedAssets = (assets % availableToBorrow) + 1;

    morpho.borrow(marketParams, clampedAssets, 0, actor, actor);
}
```

#### D. 認可テスト
```solidity
/// @dev Test unauthorized access (should revert)
function morpho_withdraw_unauthorized(uint256 shares) public asActor {
    address[] memory actors = _getActors();
    address otherActor = actors[(actorIndex + 1) % actors.length];

    Id id = MarketParamsLib.id(marketParams);
    (uint256 supplyShares,,) = morpho.position(id, otherActor);
    if (supplyShares == 0) return;

    uint256 clampedShares = (shares % supplyShares) + 1;

    // This should revert with UNAUTHORIZED
    try morpho.withdraw(marketParams, 0, clampedShares, otherActor, _getActor()) {
        // If it doesn't revert, that's a bug!
        revert("UNAUTHORIZED_ACCESS_ALLOWED");
    } catch {}
}
```

---

### 4. TargetFunctions.sol - 追加のカスタム関数

```solidity
/// @dev Manipulate oracle price
function oracle_setPrice_clamped(uint256 price) public {
    // Clamp price between 1e30 and 1e42 (reasonable range around 1e36)
    uint256 clampedPrice = (price % 1e12) * 1e30 + 1e30;
    oracleMock.setPrice(clampedPrice);
}

/// @dev Combined: supply collateral + borrow in one sequence
function morpho_leverage(uint256 collateralAmount, uint256 borrowPercent) public asActor {
    address actor = _getActor();
    uint256 balance = MockERC20(marketParams.collateralToken).balanceOf(actor);
    if (balance == 0) return;

    uint256 clampedCollateral = (collateralAmount % balance) + 1;
    morpho.supplyCollateral(marketParams, clampedCollateral, actor, hex"");

    // Borrow between 1-79% of collateral
    uint256 borrowPct = (borrowPercent % 79) + 1;
    uint256 borrowAmount = (clampedCollateral * borrowPct) / 100;
    if (borrowAmount == 0) return;

    morpho.borrow(marketParams, borrowAmount, 0, actor, actor);
}
```

---

### 5. 実装優先順位

| 順序 | ファイル | 変更内容 | 理由 |
|-----|---------|---------|------|
| 1 | Properties.sol | `invariant_supplySharesConsistency` 追加 | 会計の基本整合性 |
| 2 | Properties.sol | `invariant_borrowSharesConsistency` 追加 | 会計の基本整合性 |
| 3 | Properties.sol | `invariant_collateralBalanceConsistency` 追加 | トークン残高整合性 |
| 4 | Properties.sol | `invariant_loanTokenSolvency` 追加 | 支払い能力検証 |
| 5 | MorphoTargets.sol | `morpho_liquidate_clamped` 追加 | 清算カナリア発火 |
| 6 | TargetFunctions.sol | `warp_time` 追加 | 利息テスト |
| 7 | BeforeAfter.sol | Ghost変数実装 | 状態遷移追跡 |
| 8 | MorphoTargets.sol | `morpho_borrow_aggressive` 追加 | エッジケース探索 |

---

### 6. 期待される成果

**実装後の検証項目**:
- [ ] `canary_hasLiquidated` が発火する
- [ ] 全インバリアントがPASSする（バグがなければ）
- [ ] Medusaのカバレッジが向上（ライブラリ経由）
- [ ] より多様なコールシーケンスがコーパスに蓄積

**潜在的な発見**:
- シェア計算の丸め誤差
- 利息計算のエッジケース
- 清算インセンティブの計算ミス
- 認可バイパス

---

## 注意事項

1. **カバレッジ問題**: Morpho.solのimmutable変数によりカバレッジ0%のままだが、ライブラリ経由で内部ロジックはテストされている

2. **ガスリミット**: 複雑なインバリアント（全アクターループ）はガスを消費するため、アクター数は適切に制限

3. **フォーク非対応**: ローカルデプロイ前提のため、メインネットフォークテストとは別途実施

4. **テスト実行**: 変更後は `forge test --match-contract CryticToFoundry` で基本動作確認後、`medusa fuzz` を実行
