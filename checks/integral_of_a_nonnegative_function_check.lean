-- The integral of a non-negative function: the integral of a measurable function with values in [0, ∞] is the supremum of the integrals of the simple functions under it, it is monotone, it satisfies Markov's inequality, it is zero exactly when the function is zero almost everywhere, and it ignores changes on null sets.
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.Lebesgue.Markov

open MeasureTheory
open scoped ENNReal NNReal

/-- The integral of a non-negative measurable function `f` (values in `[0, ∞]`, infinity
allowed) is the supremum, over all simple functions `s` with finitely many finite values
lying under `f`, of the simple integrals `∑ aᵢ μ(Aᵢ)` (with `0 × ∞ = 0`). -/
theorem lintegral_eq_sup_of_simple_below {α : Type*} [MeasurableSpace α] (μ : Measure α)
    (f : α → ℝ≥0∞) (hf : Measurable f) :
    ∫⁻ x, f x ∂μ =
      ⨆ (s : SimpleFunc α ℝ≥0) (_ : ∀ x, (s x : ℝ≥0∞) ≤ f x),
        ∑ a ∈ s.range, (a : ℝ≥0∞) * μ (s ⁻¹' {a}) := by
  rw [lintegral_eq_nnreal]
  simp only [SimpleFunc.map_lintegral]

/-- Markov's inequality: for a non-negative measurable `f` and any level `t` with
`0 < t < ∞`, the set where `f` is at least `t` has size at most the integral divided by `t`. -/
theorem markov_inequality_lintegral {α : Type*} [MeasurableSpace α] (μ : Measure α)
    (f : α → ℝ≥0∞) (hf : Measurable f) (t : ℝ≥0∞) (ht0 : 0 < t) (ht : t ≠ ∞) :
    μ {x | t ≤ f x} ≤ (∫⁻ x, f x ∂μ) / t := by
  exact meas_ge_le_lintegral_div hf.aemeasurable ht0.ne' ht

/-- For non-negative measurable `f` and `g`: a bigger function has a bigger integral;
the integral is zero exactly when `f` is zero almost everywhere; and functions equal
almost everywhere have equal integrals. -/
theorem lintegral_monotone_and_ignores_null_sets {α : Type*} [MeasurableSpace α]
    (μ : Measure α) (f g : α → ℝ≥0∞) (hf : Measurable f) (hg : Measurable g) :
    (f ≤ g → ∫⁻ x, f x ∂μ ≤ ∫⁻ x, g x ∂μ) ∧
    (∫⁻ x, f x ∂μ = 0 ↔ f =ᵐ[μ] 0) ∧
    (f =ᵐ[μ] g → ∫⁻ x, f x ∂μ = ∫⁻ x, g x ∂μ) := by
  exact ⟨fun h => lintegral_mono h, lintegral_eq_zero_iff hf, fun h => lintegral_congr_ae h⟩

-- The river: depth 4x(1 − x) is 1 m at the middle, x = 1/2.
example : (4 : ℚ) * (1 / 2) * (1 - 1 / 2) = 1 := by norm_num
-- Its antiderivative 2x² − 4x³/3 at x = 1 gives the integral 2/3.
example : (2 : ℚ) * 1 ^ 2 - 4 * 1 ^ 3 / 3 = 2 / 3 := by norm_num
-- Markov at t = 3/4: the river is 3/4 m deep or more on at most (2/3)/(3/4) = 8/9 km.
example : (2 / 3 : ℚ) / (3 / 4) = 8 / 9 := by norm_num
-- Tight case: 3/4 m deep on the middle half holds 3/8, and (3/8)/(3/4) = 1/2, its true length.
example : (3 / 4 : ℚ) * (1 / 2) = 3 / 8 ∧ (3 / 8 : ℚ) / (3 / 4) = 1 / 2 := by norm_num

#print axioms lintegral_eq_sup_of_simple_below
#print axioms markov_inequality_lintegral
#print axioms lintegral_monotone_and_ignores_null_sets
