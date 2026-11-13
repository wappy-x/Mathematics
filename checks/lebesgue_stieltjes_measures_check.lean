-- Distribution functions and Lebesgue-Stieltjes measures: every increasing right-continuous function on the real line gives exactly one Borel measure with mass F(b) - F(a) on each (a, b], single points get the jump of F, and probability laws match distribution functions running from 0 to 1.
import Mathlib.MeasureTheory.Measure.Stieltjes
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Topology.Order.LeftRightLim
import Mathlib.Tactic.NormNum
import Mathlib.Probability.CDF

open MeasureTheory Set Filter Topology

/-- From a function to a measure: if `F` is increasing and right-continuous, exactly one
measure `μ` on the Borel sets of the real line gives every half-open interval `(a, b]`
the mass `F(b) - F(a)`. -/
theorem lebesgue_stieltjes_measure_exists_unique (F : ℝ → ℝ) (hmono : Monotone F)
    (hright : ∀ x, ContinuousWithinAt F (Ici x) x) :
    ∃! μ : Measure ℝ, ∀ a b : ℝ, a < b → μ (Ioc a b) = ENNReal.ofReal (F b - F a) := by
  let f : StieltjesFunction ℝ := ⟨F, hmono, hright⟩
  refine ⟨f.measure, fun a b _ => f.measure_Ioc a b, fun ν hν => ?_⟩
  refine (Measure.ext_of_Ioc f.measure ν fun a b hab => ?_).symm
  rw [hν a b hab]
  exact f.measure_Ioc a b

/-- From a law to a function: if `μ` is a probability measure on the Borel sets of the real
line, then `F(x) = μ((-∞, x])` is increasing and right-continuous, tends to 0 at the far left
and to 1 at the far right, and no other probability law has the same distribution function. -/
theorem distribution_function_of_probability_law (μ : Measure ℝ) [IsProbabilityMeasure μ] :
    let F : ℝ → ℝ := fun x => (μ (Iic x)).toReal
    Monotone F ∧ (∀ x, ContinuousWithinAt F (Ici x) x) ∧
      Tendsto F atBot (𝓝 0) ∧ Tendsto F atTop (𝓝 1) ∧
      ∀ ν : Measure ℝ, IsProbabilityMeasure ν → (∀ x, ν (Iic x) = μ (Iic x)) → ν = μ := by
  intro F
  have hF : ∀ x, F x = ProbabilityTheory.cdf μ x := fun x => by
    simp [F, ProbabilityTheory.cdf_eq_real, measureReal_def]
  have hFe : F = ProbabilityTheory.cdf μ := funext hF
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · rw [hFe]; exact ProbabilityTheory.monotone_cdf μ
  · intro x; rw [hFe]; exact (ProbabilityTheory.cdf μ).right_continuous x
  · rw [hFe]; exact ProbabilityTheory.tendsto_cdf_atBot μ
  · rw [hFe]; exact ProbabilityTheory.tendsto_cdf_atTop μ
  · intro ν hν h
    exact (Measure.ext_of_Iic μ ν fun a => (h a).symm).symm

/-- Jumps are points, and the match is one to one: if `μ` is the Lebesgue-Stieltjes measure of
an increasing right-continuous `F`, then the mass of each single point `x` is the jump
`F(x) - F(x-)`, and when `F` runs from 0 to 1, `μ` is a probability measure whose
distribution function is `F` again. -/
theorem lebesgue_stieltjes_jump_and_distribution_function (F : ℝ → ℝ) (hmono : Monotone F)
    (hright : ∀ x, ContinuousWithinAt F (Ici x) x) (μ : Measure ℝ)
    (hμ : ∀ a b : ℝ, a < b → μ (Ioc a b) = ENNReal.ofReal (F b - F a)) :
    (∀ x, μ {x} = ENNReal.ofReal (F x - Function.leftLim F x)) ∧
      (Tendsto F atBot (𝓝 0) → Tendsto F atTop (𝓝 1) →
        IsProbabilityMeasure μ ∧ ∀ x, μ (Iic x) = ENNReal.ofReal (F x)) := by
  let f : StieltjesFunction ℝ := ⟨F, hmono, hright⟩
  have hμf : μ = f.measure := by
    refine (Measure.ext_of_Ioc f.measure μ fun a b hab => ?_).symm
    rw [hμ a b hab]
    exact f.measure_Ioc a b
  subst hμf
  refine ⟨fun x => f.measure_singleton x, fun h0 h1 => ⟨f.isProbabilityMeasure h0 h1, fun x => ?_⟩⟩
  rw [f.measure_Iic h0 x, sub_zero]

/-- The card's insurance claim: $0 with chance 3/10, otherwise spread evenly over $0 to $1,000. -/
def claimF (x : ℚ) : ℚ := if x < 0 then 0 else if x < 1000 then 3 / 10 + 7 / 10 * x / 1000 else 1

-- F(200) = 0.44 and F(500) = 0.65.
example : claimF 200 = 44 / 100 ∧ claimF 500 = 65 / 100 := by norm_num [claimF]
-- The mass of ($200, $500] is F(500) - F(200) = 0.21.
example : claimF 500 - claimF 200 = 21 / 100 := by norm_num [claimF]
-- The jump at $0: F(0) - F(0-) = 0.3 - 0, with F equal to 0 on every negative amount.
example : claimF 0 = 3 / 10 ∧ ∀ x : ℚ, x < 0 → claimF x = 0 := by
  refine ⟨by norm_num [claimF], fun x hx => by simp [claimF, hx]⟩
-- The mass of ($0, $500] is 0.35, and of [$0, $500] it is F(500) - F(0-) = 0.65.
example : claimF 500 - claimF 0 = 35 / 100 ∧ claimF 500 - claimF (-1) = 65 / 100 := by
  norm_num [claimF]
-- The claim exceeds a $200 deductible with chance 1 - F(200) = 0.56.
example : 1 - claimF 200 = 56 / 100 := by norm_num [claimF]
-- A dip breaks it: subtracting 0.1 from $400 on gives ($350, $400] the mass -0.065.
example : (claimF 400 - 1 / 10) - claimF 350 = -65 / 1000 := by norm_num [claimF]

#print axioms lebesgue_stieltjes_measure_exists_unique
#print axioms distribution_function_of_probability_law
#print axioms lebesgue_stieltjes_jump_and_distribution_function
