-- Tolerances: a relative tolerance set inside the card's window passes every answer within the rounding noise and fails every mistake of the size worth catching, a relative test against zero fails any nonzero leftover, and closeness does not chain.
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.Order.AbsoluteValue.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-! The card's test: `a` and `b` count as the same answer when
`|a - b| ≤ max (τr * max |a| |b|) τa`, with relative tolerance `τr` and absolute floor `τa`.
The rounding noise of a correct computation of the true answer `b` is at most
`κ * n * u * |b|` (`n` roundings, unit roundoff `u`, condition number `κ`), and `Δ` is the
smallest mistake worth catching. The card's window for `τr` is
`10 * κ * n * u ≤ τr ≤ Δ / (10 * |b|)`. -/

/-- The tolerance window works: if the relative tolerance sits inside the window
`10 κ n u ≤ τr ≤ Δ / (10 |b|)` and the floor `τa` sits below `Δ`,
then every computed `a` within the rounding noise `κ n u |b|` of `b` passes the test,
and every wrong value `w` that misses `b` by at least `Δ` fails it.
Here `Δ` is positive and no bigger than the answer itself, as a penny is beside £4.37. -/
theorem tolerance_in_window_passes_noise_and_catches_mistakes
    (a w b τr τa κ u Δ : ℝ) (n : ℕ)
    (hΔ : 0 < Δ) (hΔb : Δ ≤ |b|)
    (hlow : 10 * κ * n * u ≤ τr) (hhigh : τr ≤ Δ / (10 * |b|))
    (hτa : τa < Δ)
    (hnoise : |a - b| ≤ κ * n * u * |b|) (hmistake : Δ ≤ |w - b|) :
    |a - b| ≤ max (τr * max |a| |b|) τa ∧ ¬ |w - b| ≤ max (τr * max |w| |b|) τa := by
  have hB : 0 < |b| := lt_of_lt_of_le hΔ hΔb
  have hk : 0 ≤ κ * n * u := by
    have h0 : 0 ≤ κ * n * u * |b| := le_trans (abs_nonneg _) hnoise
    exact nonneg_of_mul_nonneg_left h0 hB
  have hτr0 : 0 ≤ τr := le_trans (by linarith) hlow
  have hτb : τr * |b| ≤ Δ / 10 := by
    rw [le_div_iff₀ (by positivity)] at hhigh
    linarith
  have hτ1 : τr ≤ 1 / 10 := by nlinarith
  refine ⟨?_, ?_⟩
  · have hm : |b| ≤ max |a| |b| := le_max_right _ _
    have h1 : τr * |b| ≤ τr * max |a| |b| := mul_le_mul_of_nonneg_left hm hτr0
    have h2 : κ * n * u * |b| ≤ τr * |b| := by nlinarith
    exact le_trans hnoise (le_trans (le_trans h2 h1) (le_max_left _ _))
  · rw [not_le, max_lt_iff]
    refine ⟨?_, by linarith⟩
    rcases le_total |w| |b| with h | h
    · rw [max_eq_right h]
      linarith
    · rw [max_eq_left h]
      have hw : |w| ≤ |w - b| + |b| := by
        have := abs_sub_abs_le_abs_sub w b
        linarith
      have : τr * |w| ≤ τr * (|w - b| + |b|) := mul_le_mul_of_nonneg_left hw hτr0
      nlinarith

/-- Near zero the share fails: with no floor, a relative test of any nonzero leftover `a`
against the answer 0 fails at every relative tolerance below 1. -/
theorem relative_test_against_zero_fails (a τr : ℝ) (ha : a ≠ 0) (hτr : τr < 1) :
    ¬ |a - 0| ≤ max (τr * max |a| |0|) 0 := by
  have hpos : 0 < |a| := abs_pos.mpr ha
  simp only [sub_zero, abs_zero, max_eq_left (abs_nonneg a)]
  rw [not_le, max_lt_iff]
  refine ⟨by nlinarith, hpos⟩

/-- Closeness does not chain: for every positive tolerance there are numbers `a`, `b`, `c`
with `a` close to `b` and `b` close to `c`, yet `a` not close to `c`. -/
theorem closeness_does_not_chain (τ : ℝ) (hτ : 0 < τ) :
    ∃ a b c : ℝ, |a - b| ≤ τ ∧ |b - c| ≤ τ ∧ ¬ |a - c| ≤ τ := by
  refine ⟨0, τ, 2 * τ, ?_, ?_, ?_⟩
  · rw [zero_sub, abs_neg, abs_of_pos hτ]
  · rw [show τ - 2 * τ = -τ by linarith, abs_neg, abs_of_pos hτ]
  · rw [show (0 : ℝ) - 2 * τ = -(2 * τ) by linarith, abs_neg, abs_of_pos (by linarith)]
    linarith

/-! The card's whole-number worked examples, in pennies and in tenths of a penny. -/

-- The receipt in pennies: 99 + 119 + 219 = 437, with no rounding, so `==` is right here.
example : 99 + 119 + 219 = 437 := by decide
-- The 98p typo: 98 + 119 + 219 = 436, one penny short of 437.
example : 98 + 119 + 219 = 436 ∧ 437 - 436 = 1 := by decide
-- The chain in tenths of a penny with half a penny (5) allowed:
-- 4366 is close to 4370, 4370 is close to 4374, but 4366 is not close to 4374.
example : |(4366 : ℝ) - 4370| ≤ 5 ∧ |(4370 : ℝ) - 4374| ≤ 5 ∧ ¬ |(4366 : ℝ) - 4374| ≤ 5 := by
  norm_num [abs_of_neg, abs_of_pos]
-- 100,000 receipts: 437 × 100000 = 43,700,000 pennies, so the true total is £437,000.
example : 437 * 100000 = 43700000 := by decide
-- The refund of 100,000 receipts: 600,003 roundings (300,003 up, 300,000 down).
example : (3 * 100000 + 3) + 3 * 100000 = 600003 := by decide

#print axioms tolerance_in_window_passes_noise_and_catches_mistakes
#print axioms relative_test_against_zero_fails
#print axioms closeness_does_not_chain
