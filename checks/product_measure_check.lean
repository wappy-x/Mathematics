-- Product measure: for two sigma-finite measures there is exactly one measure on pairs giving every rectangle width times height, and it equals the integral of section sizes taken in either order.
import Mathlib.MeasureTheory.Measure.Prod
import Mathlib.MeasureTheory.Measure.Count
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

open MeasureTheory Set

/-- A measure on each of two spaces gives exactly one measure on pairs that assigns every
rectangle `A × B` the size `μ(A) ν(B)`, provided both measures are sigma-finite; its value on
any set `E` in the product sigma-algebra is the integral of its section sizes, taken in either
direction: `∫ ν(E_x) dμ(x) = ∫ μ(E^y) dν(y)`. -/
theorem product_measure_exists_unique_and_slices
    {X Y : Type*} [MeasurableSpace X] [MeasurableSpace Y]
    (μ : Measure X) (ν : Measure Y) [SigmaFinite μ] [SigmaFinite ν] :
    ∃ ρ : Measure (X × Y),
      (∀ A : Set X, ∀ B : Set Y, MeasurableSet A → MeasurableSet B →
          ρ (A ×ˢ B) = μ A * ν B) ∧
      (∀ E : Set (X × Y), MeasurableSet E →
          ρ E = ∫⁻ x, ν {y | (x, y) ∈ E} ∂μ ∧
          ρ E = ∫⁻ y, μ {x | (x, y) ∈ E} ∂ν) ∧
      (∀ ρ' : Measure (X × Y),
          (∀ A : Set X, ∀ B : Set Y, MeasurableSet A → MeasurableSet B →
              ρ' (A ×ˢ B) = μ A * ν B) → ρ' = ρ) := by
  refine ⟨μ.prod ν, fun A B _ _ => Measure.prod_prod A B, fun E hE =>
    ⟨Measure.prod_apply hE, Measure.prod_apply_symm hE⟩, fun ρ' h => (Measure.prod_eq h).symm⟩

/-- Sigma-finiteness cannot be dropped: with length on the x-side and counting measure on the
y-side, both on the interval from 0 to 1, the diagonal of the board has vertical sections of one
point each (counted 1, integrating to 1) and horizontal sections of one point each (length 0,
integrating to 0), so the two slicing orders disagree. -/
theorem slicing_orders_disagree_without_sigma_finite :
    let μ : Measure ℝ := volume.restrict (Icc 0 1)
    let ν : Measure ℝ := Measure.count.restrict (Icc 0 1)
    let D : Set (ℝ × ℝ) := {p | p.1 = p.2}
    (∫⁻ x, ν {y | (x, y) ∈ D} ∂μ = 1) ∧ (∫⁻ y, μ {x | (x, y) ∈ D} ∂ν = 0) := by
  intro μ ν D
  constructor
  · have h : ∀ᵐ x ∂μ, ν {y | (x, y) ∈ D} = 1 := by
      filter_upwards [ae_restrict_mem measurableSet_Icc] with x hx
      have hs : {y | (x, y) ∈ D} = {x} := by
        ext y; simp [D, eq_comm]
      rw [hs]
      simp only [ν]
      rw [Measure.restrict_apply (measurableSet_singleton x), Set.singleton_inter_of_mem hx,
        Measure.count_singleton]
    rw [lintegral_congr_ae h, lintegral_one]
    simp [μ, Real.volume_Icc]
  · have h : ∀ y, μ {x | (x, y) ∈ D} = 0 := by
      intro y
      have hs : {x | (x, y) ∈ D} = {y} := by
        ext x; simp [D]
      rw [hs]
      exact measure_mono_null (fun _ h => h) (by
        simp only [μ]
        exact le_antisymm ((Measure.restrict_le_self _).trans (by simp)) zero_le)
    simp [h]

/-- The six-cell board: x bands of widths 2/10, 5/10, 3/10 and y bands of heights 4/10, 6/10.
The event "middle band or high band" gets 8/10 slicing either way:
2/10·6/10 + 5/10·1 + 3/10·6/10 = 4/10·5/10 + 6/10·1 = 8/10. -/
example :
    (2/10 : ℚ) * (6/10) + (5/10) * 1 + (3/10) * (6/10) = 8/10 ∧
    (4/10 : ℚ) * (5/10) + (6/10) * 1 = 8/10 := by
  norm_num

/-- The disc's sections at x = 1/10 and x = 2/10 have lengths 6/10 and 8/10:
(2·3/10)² = 4·(1/4 − (4/10)²) and (2·4/10)² = 4·(1/4 − (3/10)²). -/
example :
    (2 * (3/10) : ℚ)^2 = 4 * (1/4 - (4/10)^2) ∧
    (2 * (4/10) : ℚ)^2 = 4 * (1/4 - (3/10)^2) := by
  norm_num

#print axioms product_measure_exists_unique_and_slices
#print axioms slicing_orders_disagree_without_sigma_finite
