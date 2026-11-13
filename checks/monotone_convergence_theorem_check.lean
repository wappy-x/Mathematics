-- The monotone convergence theorem: if non-negative measurable functions rise at every point to a limit, their integrals rise to the limit's integral, integrals add, and non-negative series integrate term by term.
import Mathlib.MeasureTheory.Integral.Lebesgue.Add
import Mathlib.Topology.Algebra.InfiniteSum.ENNReal
import Mathlib.Order.Interval.Finset.Nat

open MeasureTheory Filter Topology
open scoped ENNReal

/-- The monotone convergence theorem. On any measure space, let `f 0, f 1, f 2, …` be
measurable functions with values in `[0, ∞]` that rise at every point (`f n x ≤ f (n + 1) x`)
and converge at every point to `F`. Then the integrals of the `f n` rise, and they converge
to the integral of `F`. Infinite values and infinite integrals are allowed. -/
theorem integrals_rise_to_integral_of_limit {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f : ℕ → Ω → ℝ≥0∞) (F : Ω → ℝ≥0∞)
    (hf : ∀ n, Measurable (f n))
    (h_rise : ∀ x, Monotone (fun n => f n x))
    (h_lim : ∀ x, Tendsto (fun n => f n x) atTop (𝓝 (F x))) :
    Monotone (fun n => ∫⁻ x, f n x ∂μ) ∧
      Tendsto (fun n => ∫⁻ x, f n x ∂μ) atTop (𝓝 (∫⁻ x, F x ∂μ)) := by
  refine ⟨fun i j hij => lintegral_mono fun x => h_rise x hij, ?_⟩
  exact lintegral_tendsto_of_tendsto_of_monotone (fun n => (hf n).aemeasurable)
    (Filter.Eventually.of_forall h_rise) (Filter.Eventually.of_forall h_lim)

/-- Additivity: for non-negative measurable functions `f` and `r`, the integral of `f + r`
is the integral of `f` plus the integral of `r`. -/
theorem integral_of_sum_eq_sum_of_integrals {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f r : Ω → ℝ≥0∞) (hf : Measurable f) (hr : Measurable r) :
    ∫⁻ x, (f x + r x) ∂μ = ∫⁻ x, f x ∂μ + ∫⁻ x, r x ∂μ := by
  exact lintegral_add_left hf r

/-- Term-by-term integration: a series of non-negative measurable functions may be integrated
one term at a time, and the two sides agree even when both are infinite. -/
theorem integral_of_series_eq_series_of_integrals {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) (g : ℕ → Ω → ℝ≥0∞) (hg : ∀ k, Measurable (g k)) :
    ∫⁻ x, (∑' k, g k x) ∂μ = ∑' k, ∫⁻ x, g k x ∂μ := by
  exact lintegral_tsum fun k => (hg k).aemeasurable

-- Worked numbers: the first five series terms 1/(m 2^m) add to 661/960.
example : (∑ m ∈ Finset.Icc (1 : ℕ) 5, (1 : ℚ) / ((m : ℚ) * 2 ^ m)) = 661 / 960 := by
  simp [Finset.sum_Icc_succ_top]
  norm_num

-- Worked numbers: the shallowest depth per cell on 4 cells, (0 + 3/4 + 3/4 + 0)/4 = 3/8.
example : ((0 : ℚ) + 3 / 4 + 3 / 4 + 0) / 4 = 3 / 8 := by
  norm_num

-- Worked numbers: the river's integral, 2 - 4/3 = 2/3.
example : (2 : ℚ) - 4 / 3 = 2 / 3 := by
  norm_num

#print axioms integrals_rise_to_integral_of_limit
#print axioms integral_of_sum_eq_sum_of_integrals
#print axioms integral_of_series_eq_series_of_integrals
