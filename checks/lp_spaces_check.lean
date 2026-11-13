-- Lp spaces: on any measure space with exponent p at least 1, the p-norm of a measurable real function ignores changes on null sets and is zero exactly when the function is zero almost everywhere, functions of finite p-norm are closed under adding and scaling, and scaling a function by a scales its p-norm by the size of a.
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.SMul
import Mathlib.MeasureTheory.Function.LpSeminorm.TriangleInequality

open MeasureTheory
open scoped ENNReal

/-- Treat almost-everywhere-equal functions as one: on any measure space, for an exponent
`1 ≤ p ≤ ∞` and measurable real functions `f` and `g`, two functions that agree except on a
null set have the same p-norm, and the p-norm of `f` is zero exactly when `f` is zero
almost everywhere. So the p-norm is well defined on classes and is zero only at the zero class. -/
theorem lp_norm_ignores_null_sets_and_vanishes_only_at_zero
    {α : Type*} [MeasurableSpace α] (μ : Measure α) {p : ℝ≥0∞} (hp : 1 ≤ p)
    {f g : α → ℝ} (hf : Measurable f) (hg : Measurable g) :
    (f =ᵐ[μ] g → eLpNorm f p μ = eLpNorm g p μ) ∧
      (eLpNorm f p μ = 0 ↔ f =ᵐ[μ] 0) := by
  have hp0 : p ≠ 0 := (lt_of_lt_of_le one_pos hp).ne'
  exact ⟨fun h => eLpNorm_congr_ae h, eLpNorm_eq_zero_iff hp0⟩

/-- L^p is a vector space: on any measure space, for an exponent `1 ≤ p ≤ ∞`, if `f` and `g`
have finite p-norm then so does every combination `a • f + b • g` with real scalars `a`, `b`. -/
theorem lp_closed_under_sums_and_scaling
    {α : Type*} [MeasurableSpace α] (μ : Measure α) {p : ℝ≥0∞} (hp : 1 ≤ p)
    {f g : α → ℝ} (hf : MemLp f p μ) (hg : MemLp g p μ) (a b : ℝ) :
    MemLp (a • f + b • g) p μ := by
  exact (hf.const_smul a).add (hg.const_smul b)

/-- The root makes the size scale: on any measure space, for an exponent `1 ≤ p ≤ ∞`, a measurable
real function `f` and a real number `a`, the p-norm of `a • f` is `|a|` times the p-norm of `f`. -/
theorem lp_norm_scales_by_abs
    {α : Type*} [MeasurableSpace α] (μ : Measure α) {p : ℝ≥0∞} (hp : 1 ≤ p)
    {f : α → ℝ} (hf : Measurable f) (a : ℝ) :
    eLpNorm (a • f) p μ = ENNReal.ofReal |a| * eLpNorm f p μ := by
  rw [eLpNorm_const_smul, Real.enorm_eq_ofReal_abs]

-- The card's worked numbers for the week 3, 5, 8, 2, 6, 4, 7.
-- Sum of speeds, of squares, of cubes.
example : ([3, 5, 8, 2, 6, 4, 7] : List ℕ).sum = 35 := by decide
example : (([3, 5, 8, 2, 6, 4, 7] : List ℕ).map (· ^ 2)).sum = 203 := by decide
example : (([3, 5, 8, 2, 6, 4, 7] : List ℕ).map (· ^ 3)).sum = 1295 := by decide
-- Uniform weights 1/7: the sums divided by 7.
example : (35 : ℕ) = 7 * 5 ∧ (203 : ℕ) = 7 * 29 ∧ (1295 : ℕ) = 7 * 185 := by norm_num
-- The worst day: the infinity-norm is 8.
example : ([3, 5, 8, 2, 6, 4, 7] : List ℕ).max? = some 8 := by decide
-- Deviations from the mean 5: squares sum to 28 = 7 * 4, and 29 = 25 + 4.
example : (([-2, 0, 3, -3, 1, -1, 2] : List ℤ).map (· ^ 2)).sum = 28 := by decide
example : (28 : ℕ) = 7 * 4 ∧ (29 : ℕ) = 5 ^ 2 + 2 ^ 2 := by norm_num
-- Doubling the week: the sum of squares grows from 203 to 812, four times.
example : ((([3, 5, 8, 2, 6, 4, 7] : List ℕ).map (fun x => (2 * x) ^ 2)).sum = 812)
    ∧ (812 : ℕ) = 4 * 203 := by decide
-- Exponent 1/2 on Monday plus Tuesday: size (1 + 1)^2 = 4 beats 1 + 1 = 2.
example : ((1 : ℕ) + 1) ^ 2 = 4 ∧ (1 + 1 : ℕ) < 4 := by norm_num
-- Conjugate exponents: 1/p + 1/q = 1 for p = 3/2, q = 3 and p = 2, q = 2.
example : (1 : ℚ) / (3 / 2) + 1 / 3 = 1 ∧ (1 : ℚ) / 2 + 1 / 2 = 1 := by norm_num
-- Non-conjugate p = 2, q = 3: the ratio scales as c^(1 - 1/2 - 1/3) = c^(1/6).
example : (1 : ℚ) - 1 / 2 - 1 / 3 = 1 / 6 := by norm_num

#print axioms lp_norm_ignores_null_sets_and_vanishes_only_at_zero
#print axioms lp_closed_under_sums_and_scaling
#print axioms lp_norm_scales_by_abs
