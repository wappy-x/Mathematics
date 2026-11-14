-- Liquidity and leverage: the LCR passes exactly when the 30-day stock stays non-negative and then covers a quarter of the run, the two HQLA caps become the card's fractions, and the leverage ratio holds exactly up to the breach loss.
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-- Steps 1 and 3 of the card. Let `H` be the liquid stock, `O > 0` the 30-day stressed
outflows and `I` the inflows, counted only up to 75% of the outflows. The LCR
`H / (O - min(I, 0.75 O))` is at least 100% exactly when the stock left on day 30,
`H - O + min(I, 0.75 O)`, is at least zero. And when the LCR is at least 100%, the
stock alone covers at least a quarter of the run: `H ≥ O / 4`, whatever the inflows. -/
theorem lcr_ge_one_iff_day_thirty_stock_nonneg (H O I : ℝ) (hO : 0 < O) :
    (1 ≤ H / (O - min I (3 / 4 * O)) ↔ 0 ≤ H - O + min I (3 / 4 * O)) ∧
    (1 ≤ H / (O - min I (3 / 4 * O)) → O / 4 ≤ H) := by
  have hm : min I (3 / 4 * O) ≤ 3 / 4 * O := min_le_right _ _
  have hD : 0 < O - min I (3 / 4 * O) := by linarith
  rw [one_le_div hD]
  constructor
  · constructor <;> intro h <;> linarith
  · intro h; linarith

/-- Step 2 of the card. With level 1 stock `L1`, level 2A `L2A` and level 2B `L2B` (after
haircuts): the 40% cap `L2 ≤ 0.4 (L1 + L2)` on the level-2 total `L2 = L2A + L2B` is the same
as `L2 ≤ (2/3) L1`; the 15% cap `L2B ≤ 0.15 (L1 + L2A + L2B)` is the same as
`L2B ≤ (15/85)(L1 + L2A)`; and when the 40% cap binds, 15% of the whole stock is `(15/60) L1`. -/
theorem hqla_caps_as_fractions_of_level_one (L1 L2A L2B : ℝ) :
    (L2A + L2B ≤ 2 / 5 * (L1 + (L2A + L2B)) ↔ L2A + L2B ≤ 2 / 3 * L1) ∧
    (L2B ≤ 15 / 100 * (L1 + L2A + L2B) ↔ L2B ≤ 15 / 85 * (L1 + L2A)) ∧
    (L2A + L2B = 2 / 3 * L1 → 15 / 100 * (L1 + (L2A + L2B)) = 15 / 60 * L1) := by
  refine ⟨⟨fun h => by linarith, fun h => by linarith⟩,
    ⟨fun h => by linarith, fun h => by linarith⟩, fun h => by rw [h]; linarith⟩

/-- Step 5 of the card. A loss `x` comes off Tier 1 capital `T1` and off the exposure `E`
together (with `x < E`, so some exposure is left). The leverage ratio stays at or above 3%,
`(T1 - x) / (E - x) ≥ 0.03`, exactly when `x ≤ (T1 - 0.03 E) / 0.97`. -/
theorem leverage_floor_iff_loss_le_breach (T1 E x : ℝ) (hx : x < E) :
    3 / 100 ≤ (T1 - x) / (E - x) ↔ x ≤ (T1 - 3 / 100 * E) / (97 / 100) := by
  have hD : 0 < E - x := by linarith
  rw [le_div_iff₀ hD, le_div_iff₀ (by norm_num : (0:ℝ) < 97 / 100)]
  constructor <;> intro h <;> linarith

-- The card's bank, in millions of dollars. Both sides of the balance sheet total 1,450.
example : 80 + 170 + 50 + 20 + 600 + 100 + 300 + 100 + 30 = 1450 := by decide
example : 500 + 300 + 200 + 100 + 200 + 90 + 60 = 1450 := by decide

-- Liquid stock H = 302.50: level 1, then level 2A and 2B after 15% and 50% haircuts.
example : (80 + 170 : ℝ) + 85 / 100 * 50 + 50 / 100 * 20 = 605 / 2 := by norm_num

-- Outflows O = 255, counted inflows I = 20 (under the 75% cap), net outflows 235.
example : (100 / 100 * 100 + 40 / 100 * 200 + 10 / 100 * 300 + 5 / 100 * 500
    + 10 / 100 * 200 : ℝ) = 255 := by norm_num
example : min (50 / 100 * 40 : ℝ) (3 / 4 * 255) = 20 := by norm_num
example : (255 : ℝ) - 20 = 235 := by norm_num

-- LCR = 302.50 / 235 = 121/94 (128.72%), and 67.50 is left on day 30.
example : (605 / 2 : ℝ) / 235 = 121 / 94 := by norm_num
example : (605 / 2 : ℝ) - 255 + 20 = 135 / 2 := by norm_num

-- Largest run the day-30 test passes: (302.50 + 20) / 255 = 43/34 (1.2647).
example : ((605 / 2 : ℝ) + 20) / 255 = 43 / 34 := by norm_num

-- Available stable funding 1,105 and required stable funding 846: NSFR = 1105/846 (130.61%).
example : (100 / 100 * (60 + 200) + 95 / 100 * 500 + 90 / 100 * 300 + 50 / 100 * 200 : ℝ)
    = 1105 := by norm_num
example : (0 / 100 * 80 + 5 / 100 * 170 + 15 / 100 * 50 + 50 / 100 * 20 + 65 / 100 * 600
    + 50 / 100 * 100 + 85 / 100 * 300 + 85 / 100 * 100 + 100 / 100 * 30
    + 5 / 100 * 200 : ℝ) = 846 := by norm_num

-- Exposure E = 1,530; leverage ratio 60 / 1530 = 2/51 (3.92%); 1530 / 60 = 25.5 dollars per dollar.
example : (1450 + 40 / 100 * 200 : ℝ) = 1530 := by norm_num
example : (60 : ℝ) / 1530 = 2 / 51 := by norm_num
example : (1530 : ℝ) / 60 = 51 / 2 := by norm_num

-- Breach loss: (60 - 0.03 × 1530) / 0.97 = 1410/97 (14.54).
example : ((60 : ℝ) - 3 / 100 * 1530) / (97 / 100) = 1410 / 97 := by norm_num

-- The checks' cap test case L1 = 100, L2A = 100, L2B = 60: cut15 = 35, cut40 = 175/3, H = 500/3.
example : max (max ((60 : ℝ) - 15 / 85 * (100 + 100)) (60 - 15 / 60 * 100)) 0 = 35 := by
  norm_num [max_def]
example : max ((100 : ℝ) + 60 - 35 - 2 / 3 * 100) 0 = 175 / 3 := by norm_num [max_def]
example : (100 + 100 + 60 - 35 - 175 / 3 : ℝ) = 500 / 3 := by norm_num

#print axioms lcr_ge_one_iff_day_thirty_stock_nonneg
#print axioms hqla_caps_as_fractions_of_level_one
#print axioms leverage_floor_iff_loss_le_breach
