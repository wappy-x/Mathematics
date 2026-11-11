-- Substitution: if the inner function g has a continuous rate from a to b and the outer function f is continuous at every value g takes there, then f(g(x)) g'(x) accumulated from a to b equals f(u) accumulated from g(a) to g(b), and the card's area under x e^(x^2) from 0 to 1 is (e - 1)/2.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

open Set

/-- Helper: `e^(x^2)/2` has rate `x e^(x^2)`. -/
theorem hasDerivAt_half_exp_sq (x : ℝ) :
    HasDerivAt (fun x : ℝ => Real.exp (x ^ 2) / 2) (x * Real.exp (x ^ 2)) x := by
  have h := (HasDerivAt.exp (hasDerivAt_pow 2 x)).div_const 2
  convert h using 1
  push_cast
  ring

/-- Helper: the area under `x e^(x^2)` from `a` to `b` is `(e^(b^2) - e^(a^2))/2`. -/
theorem integral_x_exp_x_sq (a b : ℝ) :
    ∫ x in a..b, x * Real.exp (x ^ 2) = (Real.exp (b ^ 2) - Real.exp (a ^ 2)) / 2 := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hasDerivAt_half_exp_sq x)]
  · ring
  · apply Continuous.intervalIntegrable
    fun_prop

#print axioms hasDerivAt_half_exp_sq
#print axioms integral_x_exp_x_sq

/-- Substitution: suppose the inner function `g` has rate `g' x` at every `x` from `a` to `b`,
that rate `g'` is continuous from `a` to `b`, and the outer function `f` is continuous at every
value `g` takes from `a` to `b`. Then `f (g x) * g' x` accumulated from `a` to `b` equals `f u`
accumulated from `g a` to `g b`. The limits keep their order, even when `g` runs downhill, and
`g` need not be one-to-one. -/
theorem integral_substitution (f g g' : ℝ → ℝ) (a b : ℝ)
    (hg : ∀ x ∈ uIcc a b, HasDerivAt g (g' x) x)
    (hg' : ContinuousOn g' (uIcc a b))
    (hf : ContinuousOn f (g '' uIcc a b)) :
    ∫ x in a..b, f (g x) * g' x = ∫ u in g a..g b, f u := by
  exact intervalIntegral.integral_comp_mul_deriv' hg hg' hf

/-- The card's example: the area under `x e^(x^2)` from `x = 0` to `x = 1` is `(e - 1)/2`,
the same as the area under `e^u / 2` from `u = 0` to `u = 1`. -/
theorem integral_x_exp_x_sq_zero_one :
    ∫ x in (0 : ℝ)..1, x * Real.exp (x ^ 2) = (Real.exp 1 - 1) / 2 := by
  rw [integral_x_exp_x_sq]
  norm_num

/-- When `u = x^2` turns back: from `x = -1` to `x = 2`, `u` runs 1 down to 0 and up to 4, the
retraced stretch cancels, and the area is `(e^4 - e)/2`, the same as from `x = 1` to `x = 2`. -/
theorem integral_x_exp_x_sq_neg_one_two :
    ∫ x in (-1 : ℝ)..2, x * Real.exp (x ^ 2) = (Real.exp 4 - Real.exp 1) / 2 := by
  rw [integral_x_exp_x_sq]
  norm_num

-- Moving the limits for x from 0 to 1 and for x from 1 to 2: u = x^2.
example : ((0 : ℕ) ^ 2, (1 : ℕ) ^ 2) = (0, 1) := by decide
example : ((1 : ℕ) ^ 2, (2 : ℕ) ^ 2) = (1, 4) := by decide
-- x from -1 to 1: u runs from 1 to 1, so the right side is empty.
example : ((-1 : ℤ) ^ 2, (1 : ℤ) ^ 2) = (1, 1) := by decide
-- Step 1: the four quarter strips in x land as u strips of width 1/16, 3/16, 5/16, 7/16,
-- each equal to 2 times its centre times 1/4.
example : ((1 / 4 : ℚ) ^ 2 - 0 ^ 2 = 2 * (1 / 8) * (1 / 4)) ∧ ((1 / 4 : ℚ) ^ 2 = 1 / 16) := by
  norm_num
example : ((1 / 2 : ℚ) ^ 2 - (1 / 4) ^ 2 = 2 * (3 / 8) * (1 / 4)) ∧
    ((1 / 2 : ℚ) ^ 2 - (1 / 4) ^ 2 = 3 / 16) := by norm_num
example : ((3 / 4 : ℚ) ^ 2 - (1 / 2) ^ 2 = 2 * (5 / 8) * (1 / 4)) ∧
    ((3 / 4 : ℚ) ^ 2 - (1 / 2) ^ 2 = 5 / 16) := by norm_num
example : ((1 : ℚ) ^ 2 - (3 / 4) ^ 2 = 2 * (7 / 8) * (1 / 4)) ∧
    ((1 : ℚ) ^ 2 - (3 / 4) ^ 2 = 7 / 16) := by norm_num

#print axioms integral_substitution
#print axioms integral_x_exp_x_sq_zero_one
#print axioms integral_x_exp_x_sq_neg_one_two
