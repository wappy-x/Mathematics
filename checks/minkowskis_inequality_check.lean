-- Minkowski's inequality: for every exponent p from 1 to infinity, on any measure space, the p-size of a sum of two measurable functions is at most the sum of their p-sizes, and with it the p-size is a norm, so Lp is a normed space.
import Mathlib.MeasureTheory.Function.LpSpace.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ENNReal

/-- Minkowski's inequality. For measurable real functions f and g on any measure space and any
exponent p with 1 ≤ p ≤ ∞, the p-size of the sum is at most the p-size of the first plus the
p-size of the second: ‖f + g‖_p ≤ ‖f‖_p + ‖g‖_p. Sizes may be infinite; then the inequality holds
with ∞ on the right. -/
theorem minkowski_inequality {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (p : ℝ≥0∞) (hp : 1 ≤ p) (f g : Ω → ℝ) (hf : Measurable f) (hg : Measurable g) :
    eLpNorm (f + g) p μ ≤ eLpNorm f p μ + eLpNorm g p μ := by
  exact eLpNorm_add_le hp

/-- The other two norm axioms for the p-size of a measurable function, 1 ≤ p ≤ ∞: size zero
means zero almost everywhere (not everywhere), and scaling a function by a number c scales its
size by |c|. -/
theorem p_size_zero_iff_ae_zero_and_scales {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (p : ℝ≥0∞) (hp : 1 ≤ p) (f : Ω → ℝ) (hf : Measurable f) :
    (eLpNorm f p μ = 0 ↔ f =ᵐ[μ] 0) ∧
      ∀ c : ℝ, eLpNorm (c • f) p μ = ENNReal.ofReal |c| * eLpNorm f p μ := by
  refine ⟨eLpNorm_eq_zero_iff (by
    intro h; rw [h] at hp; exact absurd hp (by norm_num)), fun c => ?_⟩
  rw [eLpNorm_const_smul, Real.enorm_eq_ofReal_abs]

/-- Lp is a normed space. For 1 ≤ p ≤ ∞, on the space of functions of finite p-size, with
functions that agree almost everywhere counted as one, the p-norm has all three norm properties:
only the zero element has size zero, ‖c f‖_p = |c| ‖f‖_p, and the triangle inequality. -/
theorem lp_is_normed_space {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (p : ℝ≥0∞) [Fact (1 ≤ p)] (f g : Lp ℝ p μ) (c : ℝ) :
    (‖f‖ = 0 ↔ f = 0) ∧ ‖c • f‖ = |c| * ‖f‖ ∧ ‖f + g‖ ≤ ‖f‖ + ‖g‖ := by
  exact ⟨norm_eq_zero, by rw [norm_smul, Real.norm_eq_abs], norm_add_le f g⟩

-- The card's worked numbers: turbine A = [3, 5, 8, 2, 6, 4, 7], turbine B = [5, 2, 4, 6, 1, 3, 2] (m/s).
-- A + B day by day.
example : List.zipWith (· + ·) [3, 5, 8, 2, 6, 4, 7] [5, 2, 4, 6, 1, 3, 2]
    = ([8, 7, 12, 8, 7, 7, 9] : List ℕ) := by decide
-- Sums of squares: A gives 203, B gives 95, A + B gives 500.
example : (([3, 5, 8, 2, 6, 4, 7] : List ℕ).map (· ^ 2)).sum = 203 := by decide
example : (([5, 2, 4, 6, 1, 3, 2] : List ℕ).map (· ^ 2)).sum = 95 := by decide
example : (([8, 7, 12, 8, 7, 7, 9] : List ℕ).map (· ^ 2)).sum = 500 := by decide
-- The cross term is 101, and the expansion checks: 203 + 2 × 101 + 95 = 500.
example : (List.zipWith (· * ·) [3, 5, 8, 2, 6, 4, 7] [5, 2, 4, 6, 1, 3, 2] : List ℕ).sum = 101 := by
  decide
example : (203 : ℕ) + 2 * 101 + 95 = 500 := by decide
-- Minkowski at p = 2 for the turbines, squared out in whole numbers:
-- √500 ≤ √203 + √95 ⇔ 500 - 298 ≤ 2√(203·95) ⇔ 202² ≤ 4·203·95.
example : (500 - (203 + 95) : ℕ) ^ 2 ≤ 4 * 203 * 95 := by decide
-- p = 1: sizes 35 and 23 add to 58, the size of the sum (all values positive).
example : ([3, 5, 8, 2, 6, 4, 7] : List ℕ).sum = 35 ∧ ([5, 2, 4, 6, 1, 3, 2] : List ℕ).sum = 23 ∧
    ([8, 7, 12, 8, 7, 7, 9] : List ℕ).sum = 58 := by decide
-- p = ∞: largest values 8 and 6 add to 14; the sum's largest value is 12.
example : ([3, 5, 8, 2, 6, 4, 7] : List ℕ).max? = some 8 ∧ ([5, 2, 4, 6, 1, 3, 2] : List ℕ).max? = some 6 ∧
    ([8, 7, 12, 8, 7, 7, 9] : List ℕ).max? = some 12 ∧ 12 ≤ 8 + 6 := by decide
-- The usual mistake, no root at p = 2: 500 > 203 + 95 = 298.
example : (203 : ℕ) + 95 = 298 ∧ 298 < 500 := by decide

#print axioms minkowski_inequality
#print axioms p_size_zero_iff_ae_zero_and_scales
#print axioms lp_is_normed_space
