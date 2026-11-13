-- Real rates: the real rate measured in baskets satisfies Fisher's exact relation 1 + i = (1 + r)(1 + π), the shortcut i - π overstates it by exactly (i - π)π/(1 + π) = rπ, and in continuous rates the subtraction is exact.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.NormNum

/-! Notation, as on the card. `i` is the nominal rate, `π` is inflation and `r` is the real rate,
all for the same one year. `M` is the dollars deposited and `P₀` is a basket's price at the start,
so the basket costs `P₀ * (1 + π)` a year later and the account holds `M * (1 + i)` dollars.
The real rate is defined by `1 + r` = baskets bought at the end / baskets bought at the start. -/

/-- Fisher's exact relation. Define the real rate as the growth in baskets the money buys:
`1 + r` is (`M(1 + i)` dollars over a basket price of `P₀(1 + π)`) divided by (`M / P₀` baskets
at the start). If the deposit and prices are above zero (`1 + π > 0`), then dollar growth is
goods growth times price growth, `1 + i = (1 + r)(1 + π)`, and `r = (1 + i)/(1 + π) - 1 = (i - π)/(1 + π)`. -/
theorem real_rate_fisher_relation (M P₀ i π r : ℝ) (hM : 0 < M) (hP₀ : 0 < P₀) (hπ : 0 < 1 + π)
    (hr : 1 + r = (M * (1 + i) / (P₀ * (1 + π))) / (M / P₀)) :
    1 + i = (1 + r) * (1 + π) ∧ r = (1 + i) / (1 + π) - 1 ∧ r = (i - π) / (1 + π) := by
  have hπ0 : (1 + π) ≠ 0 := ne_of_gt hπ
  have h : 1 + r = (1 + i) / (1 + π) := by
    rw [hr]; field_simp
  have h1 : 1 + i = (1 + r) * (1 + π) := by
    rw [h]; field_simp
  refine ⟨h1, by linarith, ?_⟩
  rw [eq_div_iff hπ0]
  nlinarith

/-- The shortcut `r ≈ i - π` is off by exactly `(i - π)π/(1 + π)`, which equals `rπ`,
the real rate times inflation. With positive inflation and a positive real rate,
the shortcut always overstates the real rate. -/
theorem fisher_shortcut_error (i π r : ℝ) (hπ : 0 < 1 + π) (hr : 1 + r = (1 + i) / (1 + π)) :
    (i - π) - r = (i - π) * π / (1 + π) ∧ (i - π) - r = r * π ∧
      (0 < π → 0 < r → r < i - π) := by
  have hπ0 : (1 + π) ≠ 0 := ne_of_gt hπ
  have h1 : (1 + r) * (1 + π) = 1 + i := by
    rw [hr]; field_simp
  have h2 : (i - π) - r = r * π := by linarith
  refine ⟨?_, h2, ?_⟩
  · rw [eq_div_iff hπ0]
    nlinarith
  · intro hp hr0
    have : 0 < r * π := mul_pos hr0 hp
    linarith

/-- In continuous rates the relation is a plain subtraction with no approximation:
if `1 + i = (1 + r)(1 + π)` with `1 + π > 0` and `1 + i > 0` (money not wiped out),
then `ln(1 + r) = ln(1 + i) - ln(1 + π)`, that is `r_c = i_c - π_c`. -/
theorem continuous_real_rate_is_difference (i π r : ℝ) (hπ : 0 < 1 + π) (hi : 0 < 1 + i)
    (hfisher : 1 + i = (1 + r) * (1 + π)) :
    Real.log (1 + r) = Real.log (1 + i) - Real.log (1 + π) := by
  have hr0 : 0 < 1 + r := by
    by_contra hc
    push_neg at hc
    nlinarith
  rw [hfisher, Real.log_mul (ne_of_gt hr0) (ne_of_gt hπ)]
  ring

/-! The card's worked numbers, as exact fractions: `i = 4.5%` is `9/200`, `π = 2.5%` is `1/40`. -/

-- $1,000 grows to $1,045; the $100 basket costs $102.50 = 205/2; the money buys 1045/(205/2) = 418/41 baskets.
example : (1000 : ℚ) * (1 + 9 / 200) = 1045 := by norm_num
example : (100 : ℚ) * (1 + 1 / 40) = 205 / 2 := by norm_num
example : (1045 : ℚ) / (205 / 2) = 418 / 41 := by norm_num
-- The exact real rate: 1.045 / 1.025 - 1 = 2/102.5 = 4/205, about 1.9512 percent.
example : (1 + 9 / 200 : ℚ) / (1 + 1 / 40) - 1 = 4 / 205 := by norm_num
-- The shortcut's error: 0.02 × 0.025 / 1.025 = 1/2050 (0.000487805), equal to r × π.
example : (9 / 200 - 1 / 40 : ℚ) - 4 / 205 = 1 / 2050 := by norm_num
example : (4 / 205 : ℚ) * (1 / 40) = 1 / 2050 := by norm_num
-- 110 percent nominal, 100 percent inflation: exact real rate 5 percent, half the shortcut's 10.
example : (1 + 11 / 10 : ℚ) / (1 + 1) - 1 = 1 / 20 := by norm_num
-- 102 percent nominal, 100 percent inflation: exactly 1 percent real.
example : (1 + 102 / 100 : ℚ) / (1 + 1) - 1 = 1 / 100 := by norm_num
-- Wrong: multiplying instead of dividing gives 7.1125 percent.
example : (1 + 9 / 200 : ℚ) * (1 + 1 / 40) - 1 = 569 / 8000 := by norm_num
-- The shelf bond: 1 percent real and 2.5 percent inflation give 3.525 percent nominal.
example : (1 + 1 / 100 : ℚ) * (1 + 1 / 40) - 1 = 141 / 4000 := by norm_num
-- Inflation of 4.5 percent against 4.5 percent nominal: real rate exactly zero.
example : (1 + 9 / 200 : ℚ) / (1 + 9 / 200) - 1 = 0 := by norm_num

#print axioms real_rate_fisher_relation
#print axioms fisher_shortcut_error
#print axioms continuous_real_rate_is_difference
