-- Tonelli and Fubini: on two sigma-finite measure spaces a measurable function on the product may be integrated one variable at a time in either order, with no condition when it is never negative and once the integral of its absolute value is finite when it is signed, and the same holds for double series on 1, 2, 3, ...
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Topology.Algebra.InfiniteSum.Real

open MeasureTheory
open scoped ENNReal

/-- Tonelli: on sigma-finite measure spaces, for a function from the product to [0, ∞] that is
measurable for the product sigma-algebra, both slice integrals are measurable, and the integral over
the product equals the iterated integral in either order (the value ∞ is allowed throughout). -/
theorem tonelli_iterated_integrals_either_order
    {X Y : Type*} [MeasurableSpace X] [MeasurableSpace Y]
    (μ : Measure X) (ν : Measure Y) [SigmaFinite μ] [SigmaFinite ν]
    (f : X × Y → ℝ≥0∞) (hf : Measurable f) :
    Measurable (fun x => ∫⁻ y, f (x, y) ∂ν) ∧
    Measurable (fun y => ∫⁻ x, f (x, y) ∂μ) ∧
    ∫⁻ z, f z ∂(μ.prod ν) = ∫⁻ x, ∫⁻ y, f (x, y) ∂ν ∂μ ∧
    ∫⁻ z, f z ∂(μ.prod ν) = ∫⁻ y, ∫⁻ x, f (x, y) ∂μ ∂ν := by
  exact ⟨hf.lintegral_prod_right', hf.lintegral_prod_left', lintegral_prod f hf.aemeasurable,
    lintegral_prod_symm f hf.aemeasurable⟩

/-- Fubini: on sigma-finite measure spaces, let f be real-valued and measurable for the product
sigma-algebra, with finite integral of |f| over the product. Then for almost every x the section
y ↦ f (x, y) is integrable, the slice integral (Lean's integral is 0 where a section is not
integrable) is integrable in x, the same holds with the roles of x and y swapped, f is integrable
on the product, and the integral over the product equals both iterated integrals. -/
theorem fubini_iterated_integrals_either_order
    {X Y : Type*} [MeasurableSpace X] [MeasurableSpace Y]
    (μ : Measure X) (ν : Measure Y) [SigmaFinite μ] [SigmaFinite ν]
    (f : X × Y → ℝ) (hf : Measurable f)
    (habs : ∫⁻ z, ENNReal.ofReal |f z| ∂(μ.prod ν) < ∞) :
    (∀ᵐ x ∂μ, Integrable (fun y => f (x, y)) ν) ∧
    Integrable (fun x => ∫ y, f (x, y) ∂ν) μ ∧
    (∀ᵐ y ∂ν, Integrable (fun x => f (x, y)) μ) ∧
    Integrable (fun y => ∫ x, f (x, y) ∂μ) ν ∧
    Integrable f (μ.prod ν) ∧
    ∫ z, f z ∂(μ.prod ν) = ∫ x, ∫ y, f (x, y) ∂ν ∂μ ∧
    ∫ z, f z ∂(μ.prod ν) = ∫ y, ∫ x, f (x, y) ∂μ ∂ν := by
  have hint : Integrable f (μ.prod ν) := by
    refine ⟨hf.aestronglyMeasurable, ?_⟩
    simpa [HasFiniteIntegral, Real.enorm_eq_ofReal_abs] using habs
  exact ⟨hint.prod_right_ae, hint.integral_prod_left, hint.prod_left_ae, hint.integral_prod_right,
    hint, integral_prod f hint, integral_prod_symm f hint⟩

/-- Double series, indexed by 1, 2, 3, ...: a double series with entries in [0, ∞] has the same
sum rows first or columns first (possibly ∞); and a real double series whose absolute values have
a finite total has every row and every column summable and the same sum rows first or columns
first. -/
theorem double_series_either_order :
    (∀ a : ℕ+ → ℕ+ → ℝ≥0∞, ∑' i, ∑' j, a i j = ∑' j, ∑' i, a i j) ∧
    (∀ a : ℕ+ → ℕ+ → ℝ, Summable (fun p : ℕ+ × ℕ+ => |a p.1 p.2|) →
      (∀ i, Summable (fun j => a i j)) ∧ (∀ j, Summable (fun i => a i j)) ∧
      ∑' i, ∑' j, a i j = ∑' j, ∑' i, a i j) := by
  refine ⟨fun a => tsum_comm, fun a ha => ?_⟩
  have hs : Summable (Function.uncurry a) := by
    refine Summable.of_norm ?_
    simpa [Real.norm_eq_abs, Function.uncurry] using ha
  exact ⟨hs.prod_factor, hs.prod_symm.prod_factor, (hs.tsum_comm).symm⟩

/-- The card's table: +1 when j = i, -1 when j = i + 1, 0 elsewhere. -/
def pmTable (i j : ℕ) : ℤ := if j = i then 1 else if j = i + 1 then -1 else 0

-- every row sums to 0 (rows 1 to 10, all of whose entries lie in columns 1 to 11)
example : ∀ i ∈ Finset.Icc 1 10, ∑ j ∈ Finset.Icc 1 11, pmTable i j = 0 := by decide
-- column 1 holds only a +1; columns 2 to 10 each sum to 0
example : ∑ i ∈ Finset.Icc 1 10, pmTable i 1 = 1 := by decide
example : ∀ j ∈ Finset.Icc 2 10, ∑ i ∈ Finset.Icc 1 10, pmTable i j = 0 := by decide
-- the 10 × 10 corner sums to 1, the 10 × 11 corner to 0
example : ∑ i ∈ Finset.Icc 1 10, ∑ j ∈ Finset.Icc 1 10, pmTable i j = 1 := by decide
example : ∑ i ∈ Finset.Icc 1 10, ∑ j ∈ Finset.Icc 1 11, pmTable i j = 0 := by decide
-- the first 10 rows carry absolute values totalling 20
example : ∑ i ∈ Finset.Icc 1 10, ∑ j ∈ Finset.Icc 1 11, |pmTable i j| = 20 := by decide

#print axioms tonelli_iterated_integrals_either_order
#print axioms fubini_iterated_integrals_either_order
#print axioms double_series_either_order
