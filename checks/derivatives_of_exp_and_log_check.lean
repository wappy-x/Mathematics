-- Derivatives of exp and log: e^x has rate e^x everywhere, ln x has rate 1/x for x > 0, any positive base b picks up the factor ln b, and the log of a positive function has rate f'/f.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Tactic.NormNum

/-- The function `e^x` changes at a rate equal to its own value at every real `x`,
and its inverse, the natural log `ln x`, changes at rate `1/x` at every positive `x`. -/
theorem exp_rate_is_itself_and_log_rate_is_reciprocal :
    (∀ x : ℝ, HasDerivAt Real.exp (Real.exp x) x) ∧
    (∀ x : ℝ, 0 < x → HasDerivAt Real.log (1 / x) x) := by
  refine ⟨fun x => Real.hasDerivAt_exp x, fun x hx => ?_⟩
  simpa [one_div] using Real.hasDerivAt_log hx.ne'

/-- Every other base picks up the factor `ln b`: for a positive base `b`, `b^x` has rate
`b^x · ln b` at every real `x`; and when also `b ≠ 1`, the log to base `b` has rate
`1 / (x · ln b)` at every positive `x`. -/
theorem other_base_rate_picks_up_log_b (b : ℝ) (hb : 0 < b) :
    (∀ x : ℝ, HasDerivAt (fun y => b ^ y) (b ^ x * Real.log b) x) ∧
    (b ≠ 1 → ∀ x : ℝ, 0 < x → HasDerivAt (Real.logb b) (1 / (x * Real.log b)) x) := by
  refine ⟨fun x => (Real.hasStrictDerivAt_const_rpow hb x).hasDerivAt, fun _ x hx => ?_⟩
  have h := (Real.hasDerivAt_log hx.ne').div_const (Real.log b)
  have e : x⁻¹ / Real.log b = 1 / (x * Real.log b) := by ring
  rw [e] at h
  exact h

/-- Logarithmic differentiation: if a quantity `f` is positive at `x` and has rate `f'` there,
then its log has rate `f' / f(x)` at `x`, its relative rate. -/
theorem log_rate_is_relative_rate (f : ℝ → ℝ) (f' x : ℝ)
    (hf : HasDerivAt f f' x) (hpos : 0 < f x) :
    HasDerivAt (fun y => Real.log (f y)) (f' / f x) x := by
  exact hf.log hpos.ne'

-- Worked numbers, by hand.
-- Step 1 walls at h = 0.01 and h = −0.01: 1/(1 − 0.01) = 1.010101, 1/(1 + 0.01) = 0.990099.
example : (1 : ℚ) / (1 - 1 / 100) = 100 / 99 ∧ (1 : ℚ) / (1 + 1 / 100) = 100 / 101 := by norm_num
-- Time per extra dollar at 200: 1 ÷ (0.05 × 200) = 0.1 year.
example : (1 : ℚ) / ((1 / 20) * 200) = 1 / 10 := by norm_num
-- Fund shares at ten years: 100 + 10 × 10 = 200.
example : (100 : ℕ) + 10 * 10 = 200 := by norm_num
-- Fund relative rate: 10 ÷ 200 + 0.05 = 0.10 per year.
example : (10 : ℚ) / 200 + 1 / 20 = 1 / 10 := by norm_num

#print axioms exp_rate_is_itself_and_log_rate_is_reciprocal
#print axioms other_base_rate_picks_up_log_b
#print axioms log_rate_is_relative_rate
