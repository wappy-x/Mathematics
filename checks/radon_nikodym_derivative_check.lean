-- The Radon-Nikodym derivative: multiplying by dν/dμ inside an integral switches the measure from ν to μ, two derivatives multiply through a middle measure, and for equivalent measures the derivative back is the reciprocal.
import Mathlib.MeasureTheory.Measure.Decomposition.RadonNikodym
import Mathlib.Tactic.NormNum

open MeasureTheory
open scoped ENNReal

variable {Ω : Type*} [MeasurableSpace Ω]

/-- Change of measure (rule 1). Let μ and ν be σ-finite measures with ν ≪ μ, and let
dν/dμ be the Radon-Nikodym derivative. For every measurable g ≥ 0,
∫ g dν = ∫ g · (dν/dμ) dμ (both sides may be +∞). For every g integrable against ν,
g · (dν/dμ) is integrable against μ and the same equality holds. -/
theorem change_of_measure (μ ν : Measure Ω) [SigmaFinite μ] [SigmaFinite ν]
    (hνμ : ν ≪ μ) :
    (∀ g : Ω → ℝ≥0∞, Measurable g →
        ∫⁻ x, g x ∂ν = ∫⁻ x, g x * ν.rnDeriv μ x ∂μ) ∧
    (∀ g : Ω → ℝ, Integrable g ν →
        Integrable (fun x => g x * (ν.rnDeriv μ x).toReal) μ ∧
        ∫ x, g x ∂ν = ∫ x, g x * (ν.rnDeriv μ x).toReal ∂μ) := by
  refine ⟨fun g hg => ?_, fun g hg => ?_⟩
  · rw [← lintegral_rnDeriv_mul hνμ hg.aemeasurable]
    congr 1
    ext x
    exact mul_comm _ _
  · have hint : Integrable (fun x => g x * (ν.rnDeriv μ x).toReal) μ := by
      have h := (integrable_toReal_rnDeriv_mul_iff hνμ (f := g)).2 hg
      simpa only [mul_comm] using h
    refine ⟨hint, ?_⟩
    rw [← integral_toReal_rnDeriv_mul hνμ]
    congr 1
    ext x
    exact mul_comm _ _

/-- Chain rule (rule 2). For σ-finite measures with ρ ≪ ν ≪ μ,
dρ/dμ = (dρ/dν) · (dν/dμ) μ-almost everywhere. -/
theorem radon_nikodym_chain_rule (μ ν ρ : Measure Ω) [SigmaFinite μ] [SigmaFinite ν] [SigmaFinite ρ]
    (hρν : ρ ≪ ν) (hνμ : ν ≪ μ) :
    ρ.rnDeriv μ =ᵐ[μ] fun x => ρ.rnDeriv ν x * ν.rnDeriv μ x := by
  filter_upwards [Measure.rnDeriv_mul_rnDeriv (κ := μ) hρν] with x hx
  exact hx.symm

/-- Reciprocal rule (rule 3). If the σ-finite measures μ and ν are equivalent (μ ≪ ν and ν ≪ μ),
then dν/dμ > 0 almost everywhere, and dμ/dν = 1 / (dν/dμ) almost everywhere, both μ-a.e.
and ν-a.e. -/
theorem radon_nikodym_reciprocal_rule (μ ν : Measure Ω) [SigmaFinite μ] [SigmaFinite ν]
    (hμν : μ ≪ ν) (hνμ : ν ≪ μ) :
    (∀ᵐ x ∂μ, 0 < ν.rnDeriv μ x) ∧
    (μ.rnDeriv ν =ᵐ[μ] fun x => (ν.rnDeriv μ x)⁻¹) ∧
    (μ.rnDeriv ν =ᵐ[ν] fun x => (ν.rnDeriv μ x)⁻¹) := by
  refine ⟨Measure.rnDeriv_pos' hμν, ?_, ?_⟩
  · filter_upwards [Measure.inv_rnDeriv' hμν] with x hx
    exact hx.symm
  · filter_upwards [Measure.inv_rnDeriv hνμ] with x hx
    exact hx.symm

/-! The card's dice, in exact fractions: fair die P = 1/6 each, loaded die
Q = 1/10, 1/10, 1/10, 1/10, 1/5, 2/5, third die R = 1/4, 1/4, 1/5, 1/10, 1/10, 1/10. -/

-- Z = dQ/dP on faces 1 to 4, face 5 and face 6: 3/5, 6/5, 12/5.
example : ((1 : ℚ) / 10) / (1 / 6) = 3 / 5 ∧ ((1 : ℚ) / 5) / (1 / 6) = 6 / 5 ∧
    ((2 : ℚ) / 5) / (1 / 6) = 12 / 5 := by norm_num

-- E_P[Z] = 1.
example : (1 : ℚ) / 6 * (4 * (3 / 5) + 6 / 5 + 12 / 5) = 1 := by norm_num

-- E_Q of the face, directly: 22/5.
example : (1 : ℚ) / 10 * (1 + 2 + 3 + 4) + 1 / 5 * 5 + 2 / 5 * 6 = 22 / 5 := by norm_num

-- E_P of face × Z, by the change of measure: 22/5 again.
example : (1 : ℚ) / 6 * (3 / 5 * (1 + 2 + 3 + 4) + 6 / 5 * 5 + 12 / 5 * 6) = 22 / 5 := by
  norm_num

-- Chain rule on the dice: dQ/dR × dR/dP = Z on every face.
example : ((2 : ℚ) / 5) * (3 / 2) = 3 / 5 ∧ ((1 : ℚ) / 2) * (6 / 5) = 3 / 5 ∧
    (1 : ℚ) * (3 / 5) = 3 / 5 ∧ (2 : ℚ) * (3 / 5) = 6 / 5 ∧ (4 : ℚ) * (3 / 5) = 12 / 5 := by
  norm_num

-- Reciprocal rule on the dice: dP/dQ = 5/3, 5/6, 5/12, each times Z is 1,
-- and E_Q of face × dP/dQ is the fair die's 7/2.
example : (5 : ℚ) / 3 * (3 / 5) = 1 ∧ (5 : ℚ) / 6 * (6 / 5) = 1 ∧ (5 : ℚ) / 12 * (12 / 5) = 1 ∧
    (1 : ℚ) / 10 * (5 / 3) * (1 + 2 + 3 + 4) + 1 / 5 * (5 / 6) * 5 + 2 / 5 * (5 / 12) * 6
      = 7 / 2 := by
  norm_num

#print axioms change_of_measure
#print axioms radon_nikodym_chain_rule
#print axioms radon_nikodym_reciprocal_rule
