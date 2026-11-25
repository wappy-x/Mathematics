-- Haar measure: every locally compact group has a left Haar measure, unique up to one scale factor, with a modular function for right moves, and dx/x is the fair measure on the positive reals.
import Mathlib.MeasureTheory.Group.ModularCharacter
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.MeasureTheory.Function.JacobianOneDim

open MeasureTheory Measure Set
open scoped NNReal ENNReal

namespace HaarMeasureCard

/-- **Haar's theorem.** On a locally compact (Hausdorff) topological group, with its Borel
sets, a left Haar measure exists: a nonzero Radon measure `μ` with `μ (g E) = μ E` for every
member `g` and Borel set `E`. In Mathlib's terms this is `IsHaarMeasure μ` (finite on compact
sets, left invariant, positive on nonempty open sets) together with `μ.Regular` (Radon). And
any two left Haar measures differ only by the choice of unit: `ν = c • μ` for one `c > 0`. -/
theorem left_haar_measure_exists_unique
    (G : Type*) [Group G] [TopologicalSpace G] [IsTopologicalGroup G]
    [LocallyCompactSpace G] [T2Space G] [MeasurableSpace G] [BorelSpace G] :
    (∃ μ : Measure G, IsHaarMeasure μ ∧ μ.Regular) ∧
    ∀ μ ν : Measure G, IsHaarMeasure μ → μ.Regular → IsHaarMeasure ν → ν.Regular →
      ∃ c : ℝ≥0, 0 < c ∧ ν = c • μ := by
  refine ⟨⟨haarMeasure (Classical.arbitrary (TopologicalSpace.PositiveCompacts G)),
    inferInstance, inferInstance⟩, ?_⟩
  intro μ ν hμ hμr hν hνr
  exact ⟨haarScalarFactor ν μ, haarScalarFactor_pos_of_isHaarMeasure ν μ,
    isMulLeftInvariant_eq_smul_of_regular ν μ⟩

/-- **The modular function.** On a locally compact group there is one multiplicative map
`Δ : G → (0, ∞)` such that moving a set from the right by `g` scales every left Haar measure
by `Δ g`: `μ (E g) = Δ g * μ E` for every left Haar (Radon) measure `μ` and Borel set `E`.
It satisfies `Δ (g k) = Δ g * Δ k`, and it does not depend on which Haar measure is used. -/
theorem modular_function_exists
    (G : Type*) [Group G] [TopologicalSpace G] [IsTopologicalGroup G]
    [LocallyCompactSpace G] [T2Space G] [MeasurableSpace G] [BorelSpace G] :
    ∃ Δ : G →* ℝ≥0, (∀ g, 0 < Δ g) ∧
      ∀ μ : Measure G, IsHaarMeasure μ → μ.Regular →
        ∀ (g : G) (E : Set G), MeasurableSet E →
          μ ((fun x => x * g) '' E) = (Δ g : ℝ≥0∞) * μ E := by
  let Δ : G →* ℝ≥0 :=
    { toFun := fun g => modularCharacter g⁻¹
      map_one' := by simp
      map_mul' := fun g k => by simp [mul_inv_rev, map_mul, mul_comm] }
  refine ⟨Δ, fun g => modularCharacterFun_pos g⁻¹, ?_⟩
  intro μ hμ hμr g E hE
  have hreg : (map (· * g⁻¹) μ).Regular := by
    have := Regular.map (μ := μ) (Homeomorph.mulRight g⁻¹)
    simpa using this
  have h1 : map (· * g⁻¹) μ = haarScalarFactor (map (· * g⁻¹) μ) μ • μ :=
    isMulLeftInvariant_eq_smul_of_regular _ _
  have h2 : modularCharacterFun g⁻¹ = haarScalarFactor (map (· * g⁻¹) μ) μ :=
    modularCharacterFun_eq_haarScalarFactor μ g⁻¹
  have h3 : (fun x => x * g) '' E = (· * g⁻¹) ⁻¹' E := Set.image_mul_right
  rw [h3, ← map_apply (measurable_mul_const g⁻¹) hE, h1]
  show _ = ((modularCharacterFun g⁻¹ : ℝ≥0) : ℝ≥0∞) * μ E
  rw [h2]
  rfl

/-- **The positive reals.** The measure `dx/x` (Lebesgue measure with density `1/x`) is fair
under multiplication: stretching any Borel set of positive reals by a factor `g > 0` keeps its
size, and the interval `[a, b]` with `0 < a ≤ b` has size `ln (b / a)`. -/
theorem dx_div_x_mul_invariant_and_interval :
    let μ : Measure ℝ := volume.withDensity (fun x => ENNReal.ofReal x⁻¹)
    (∀ g : ℝ, 0 < g → ∀ E : Set ℝ, MeasurableSet E → E ⊆ Ioi 0 →
        μ ((fun x => g * x) '' E) = μ E) ∧
    (∀ a b : ℝ, 0 < a → a ≤ b → μ (Icc a b) = ENNReal.ofReal (Real.log (b / a))) := by
  intro μ
  refine ⟨?_, ?_⟩
  · intro g hg E hE _
    have himg : MeasurableSet ((fun x => g * x) '' E) := by
      have : (fun x => g * x) '' E = (fun x => g⁻¹ * x) ⁻¹' E := by
        ext y; constructor
        · rintro ⟨x, hx, rfl⟩; simpa [← mul_assoc, inv_mul_cancel₀ hg.ne'] using hx
        · intro hy; exact ⟨g⁻¹ * y, hy, by simp [← mul_assoc, mul_inv_cancel₀ hg.ne']⟩
      rw [this]; exact (measurable_const_mul g⁻¹) hE
    simp only [μ, withDensity_apply _ himg, withDensity_apply _ hE]
    have hd : ∀ x ∈ E, HasDerivWithinAt (fun x => g * x) g E x := fun x _ => by
      simpa using ((hasDerivAt_id x).const_mul g).hasDerivWithinAt
    rw [lintegral_image_eq_lintegral_abs_deriv_mul hE hd
      (fun x _ y _ h => mul_left_cancel₀ hg.ne' h)]
    congr 1
    funext x
    rw [abs_of_pos hg, ← ENNReal.ofReal_mul hg.le, mul_inv, ← mul_assoc,
      mul_inv_cancel₀ hg.ne', one_mul]
  · intro a b ha hab
    simp only [μ, withDensity_apply _ measurableSet_Icc]
    have hcont : ContinuousOn (fun x : ℝ => x⁻¹) (Icc a b) :=
      continuousOn_inv₀.mono (fun x hx => (ha.trans_le hx.1).ne')
    have hint : IntegrableOn (fun x : ℝ => x⁻¹) (Icc a b) := hcont.integrableOn_Icc
    rw [← ofReal_integral_eq_lintegral_ofReal hint]
    · rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le hab,
        integral_inv_of_pos ha (ha.trans_le hab)]
    · filter_upwards [ae_restrict_mem measurableSet_Icc] with x hx
      exact inv_nonneg.mpr (ha.le.trans hx.1)

-- The card's worked examples, in exact arithmetic.
-- [1, 2] and [5, 10] have the same fair size: ln (10 / 5) = ln (2 / 1).
example : Real.log (10 / 5) = Real.log (2 / 1) := by norm_num
-- ax + b group, E = [1,2] × [0,1], g = (2, 3): left size of E is 1 - 1/2,
-- of gE is 2 × (1/2 - 1/4), of Eg is 1/2 - 1/4; so Δ(2, 3) = (1/4) / (1/2) = 1/2.
example : (1 : ℚ) - 1 / 2 = 1 / 2 := by norm_num
example : (2 : ℚ) * (1 / 2 - 1 / 4) = 1 / 2 := by norm_num
example : ((1 : ℚ) / 2 - 1 / 4) / (1 / 2) = 1 / 2 := by norm_num
-- GL₂(ℝ): A = [[2, 1], [0, 1]] has det A = 2, so plain volume dX grows by (det A)² = 4.
example : Matrix.det !![(2 : ℤ), 1; 0, 1] = 2 := by norm_num [Matrix.det_fin_two]
example : (Matrix.det !![(2 : ℤ), 1; 0, 1]) ^ 2 = 4 := by norm_num [Matrix.det_fin_two]
-- The clock ℤ/12, Haar measure of total 1: each hour gets 1/12, and a 30-degree arc
-- of the circle gets 30/360 = 1/12.
example : (12 : ℚ) * (1 / 12) = 1 := by norm_num
example : (30 : ℚ) / 360 = 1 / 12 := by norm_num

#print axioms left_haar_measure_exists_unique
#print axioms modular_function_exists
#print axioms dx_div_x_mul_invariant_and_interval

end HaarMeasureCard
