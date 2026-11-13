-- Markov and Chebyshev: a non-negative measurable function reaches level a on a set of measure at most its integral over a, and from this Chebyshev's and Chernoff's tail bounds follow.
import Mathlib.MeasureTheory.Integral.Lebesgue.Markov
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Basic

open MeasureTheory ENNReal

/-- Markov's inequality. On any measure space, if `f` is a measurable function with values
in `[0, ∞]` and `a > 0` is a number, then the set where `f` reaches at least `a` has
measure at most the integral of `f` divided by `a`. -/
theorem markov_inequality {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f : Ω → ℝ≥0∞) (hf : Measurable f) (a : ℝ) (ha : 0 < a) :
    μ {ω | ENNReal.ofReal a ≤ f ω} ≤ (ENNReal.ofReal a)⁻¹ * ∫⁻ ω, f ω ∂μ := by
  have h0 : ENNReal.ofReal a ≠ 0 := by simpa using ha
  rw [mul_comm, ← div_eq_mul_inv]
  exact meas_ge_le_lintegral_div hf.aemeasurable h0 ENNReal.ofReal_ne_top

/-- Chebyshev's inequality. For a probability measure `P`, a measurable real random variable
`X` with `∫ X² dP` finite, its mean `m = ∫ X dP`, its variance `σ² = ∫ (X - m)² dP`, and a
distance `ε > 0`, the probability that `X` lands at least `ε` from its mean is at most
`σ² / ε²`. -/
theorem chebyshev_inequality {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (hX : Measurable X)
    (hX2 : ∫⁻ ω, ENNReal.ofReal (X ω ^ 2) ∂P < ∞) (ε : ℝ) (hε : 0 < ε) :
    P {ω | ε ≤ |X ω - ∫ x, X x ∂P|}
      ≤ ENNReal.ofReal ((∫ ω, (X ω - ∫ x, X x ∂P) ^ 2 ∂P) / ε ^ 2) := by
  have hint : Integrable (fun ω => X ω ^ 2) P := by
    refine ⟨(hX.pow_const 2).aestronglyMeasurable, ?_⟩
    rw [hasFiniteIntegral_iff_ofReal (Filter.Eventually.of_forall fun ω => sq_nonneg (X ω))]
    exact hX2
  have hL2 : MemLp X 2 P := (memLp_two_iff_integrable_sq hX.aestronglyMeasurable).2 hint
  have h := ProbabilityTheory.meas_ge_le_variance_div_sq hL2 hε
  rwa [ProbabilityTheory.variance_eq_integral hX.aemeasurable] at h

/-- The Chernoff bound. For a probability measure `P`, a measurable real random variable `X`,
a level `a`, and any `t ≥ 0` for which `M(t) = ∫ e^{tX} dP` is finite, the probability that
`X` reaches at least `a` is at most `e^{-ta} M(t)`. -/
theorem chernoff_bound {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (hX : Measurable X) (a t : ℝ) (ht : 0 ≤ t)
    (hM : ∫⁻ ω, ENNReal.ofReal (Real.exp (t * X ω)) ∂P < ∞) :
    P {ω | a ≤ X ω}
      ≤ ENNReal.ofReal (Real.exp (-t * a) * ∫ ω, Real.exp (t * X ω) ∂P) := by
  have hint : Integrable (fun ω => Real.exp (t * X ω)) P := by
    refine ⟨(Real.measurable_exp.comp (hX.const_mul t)).aestronglyMeasurable, ?_⟩
    rw [hasFiniteIntegral_iff_ofReal
      (Filter.Eventually.of_forall fun ω => (Real.exp_pos (t * X ω)).le)]
    exact hM
  have h := ProbabilityTheory.measure_ge_le_exp_mul_mgf (μ := P) (X := X) a ht hint
  rw [← ENNReal.ofReal_toReal (measure_ne_top P {ω | a ≤ X ω})]
  exact ENNReal.ofReal_le_ofReal h

/-! Worked numbers from the card, in exact fractions. -/

-- Average depth: 4/2 - 4/3 = 2/3.
example : (4 : ℚ) / 2 - 4 / 3 = 2 / 3 := by norm_num
-- Average squared depth: 16/3 - 8 + 16/5 = 8/15.
example : (16 : ℚ) / 3 - 8 + 16 / 5 = 8 / 15 := by norm_num
-- Variance: 8/15 - (2/3)^2 = 4/45.
example : (8 : ℚ) / 15 - (2 / 3) ^ 2 = 4 / 45 := by norm_num
-- Markov ceiling at 0.9 m: (2/3) / (9/10) = 20/27.
example : ((2 : ℚ) / 3) / (9 / 10) = 20 / 27 := by norm_num
-- Chebyshev ceiling at ε = 1/2: (4/45) / (1/2)^2 = 16/45.
example : ((4 : ℚ) / 45) / (1 / 2) ^ 2 = 16 / 45 := by norm_num
-- Markov on 1 - d for the shallow side: (1/3) / (5/6) = 2/5.
example : ((1 : ℚ) / 3) / (5 / 6) = 2 / 5 := by norm_num
-- Tight Markov channel: 9/10 m deep on 20/27 km has integral 2/3.
example : (9 : ℚ) / 10 * (20 / 27) = 2 / 3 := by norm_num
-- Tight Chebyshev channel: depths 1/6, 2/3, 7/6 on 8/45, 29/45, 8/45 km.
example : (8 : ℚ) / 45 + 29 / 45 + 8 / 45 = 1 := by norm_num
example : (8 : ℚ) / 45 * (1 / 6) + 29 / 45 * (2 / 3) + 8 / 45 * (7 / 6) = 2 / 3 := by norm_num
example : (8 : ℚ) / 45 * (1 / 6 - 2 / 3) ^ 2 + 29 / 45 * (2 / 3 - 2 / 3) ^ 2
    + 8 / 45 * (7 / 6 - 2 / 3) ^ 2 = 4 / 45 := by norm_num
example : (8 : ℚ) / 45 + 8 / 45 = 16 / 45 := by norm_num
-- Chebyshev with σ²/ε instead of σ²/ε² on the tight law: 8/45, below the true tail 16/45.
example : ((4 : ℚ) / 45) / (1 / 2) = 8 / 45 ∧ (8 : ℚ) / 45 < 16 / 45 := by norm_num

#print axioms markov_inequality
#print axioms chebyshev_inequality
#print axioms chernoff_bound
