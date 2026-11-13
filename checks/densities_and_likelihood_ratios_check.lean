-- Densities and likelihood ratios: if two probability laws have densities p and q against one σ-finite reference measure and Q ≪ P, then dQ/dP is q/p almost everywhere, averages under Q are averages under P weighted by q/p, and the Kullback-Leibler divergence is never negative and is zero only when Q = P.
import Mathlib.MeasureTheory.Measure.LogLikelihoodRatio
import Mathlib.MeasureTheory.Measure.Decomposition.RadonNikodym
import Mathlib.Tactic.NormNum
import Mathlib.InformationTheory.KullbackLeibler.Basic

open MeasureTheory
open scoped ENNReal

/-- Pointwise splitting of the extended norm of a real number into positive and negative parts. -/
theorem enorm_eq_ofReal_add_ofReal_neg (x : ℝ) :
    ‖x‖ₑ = ENNReal.ofReal x + ENNReal.ofReal (-x) := by
  rw [Real.enorm_eq_ofReal_abs]
  rcases le_total 0 x with h | h
  · rw [abs_of_nonneg h, ENNReal.ofReal_of_nonpos (p := -x) (by linarith), add_zero]
  · rw [abs_of_nonpos h, ENNReal.ofReal_of_nonpos (p := x) h, zero_add]

/-- For `t ≥ 0`, `t * (-log t) ≤ 1`. -/
theorem mul_neg_log_le_one (t : ℝ) (ht : 0 ≤ t) : t * (-Real.log t) ≤ 1 := by
  rcases ht.eq_or_lt with h | h
  · subst h; simp
  · have h1 := Real.one_sub_inv_le_log_of_pos h
    have h2 : t * (1 - t⁻¹) = t - 1 := by field_simp
    nlinarith [mul_le_mul_of_nonneg_left h1 h.le]

/-- The negative part of the log-likelihood ratio has finite integral. -/
theorem neg_part_llr_ne_top {Ω : Type*} [MeasurableSpace Ω]
    (P Q : Measure Ω) [IsProbabilityMeasure P] [IsProbabilityMeasure Q] (hQP : Q ≪ P) :
    ∫⁻ x, ENNReal.ofReal (-llr Q P x) ∂Q ≠ ∞ := by
  rw [← lintegral_rnDeriv_mul hQP (f := fun x => ENNReal.ofReal (-llr Q P x))
    ((measurable_llr Q P).neg.ennreal_ofReal).aemeasurable]
  refine (lt_of_le_of_lt (lintegral_mono (g := fun _ => (1 : ℝ≥0∞)) ?_) ?_).ne
  · intro x
    simp only [llr_def]
    by_cases hx : Q.rnDeriv P x = ∞
    · simp [hx]
    · rw [← ENNReal.ofReal_toReal hx, ← ENNReal.ofReal_mul ENNReal.toReal_nonneg,
        ENNReal.ofReal_toReal hx]
      calc ENNReal.ofReal ((Q.rnDeriv P x).toReal * -Real.log (Q.rnDeriv P x).toReal)
          ≤ ENNReal.ofReal 1 := ENNReal.ofReal_le_ofReal (mul_neg_log_le_one _ ENNReal.toReal_nonneg)
        _ = 1 := ENNReal.ofReal_one
  · simp


/-- The likelihood ratio is a Radon-Nikodym derivative: if probability measures P and Q
have measurable densities p and q against the same σ-finite reference measure ν, and Q puts
no mass where P puts none (Q ≪ P), then dQ/dP equals q/p at P-almost every point. -/
theorem rnDeriv_eq_ratio_of_densities {Ω : Type*} [MeasurableSpace Ω]
    (ν : Measure Ω) [SigmaFinite ν] (p q : Ω → ℝ≥0∞) (hp : Measurable p) (hq : Measurable q)
    (P Q : Measure Ω) [IsProbabilityMeasure P] [IsProbabilityMeasure Q]
    (hP : P = ν.withDensity p) (hQ : Q = ν.withDensity q) (hQP : Q ≪ P) :
    ∀ᵐ x ∂P, Q.rnDeriv P x = q x / p x := by
  subst hP hQ
  have hPν : ν.withDensity p ≪ ν := withDensity_absolutelyContinuous ν p
  have hQν : ν.withDensity q ≪ ν := withDensity_absolutelyContinuous ν q
  filter_upwards [Measure.rnDeriv_eq_div (ξ := ν) hQν hPν,
    hPν (Measure.rnDeriv_withDensity ν hp), hPν (Measure.rnDeriv_withDensity ν hq)]
    with x h1 h2 h3
  rw [h1, h2, h3]

/-- The reweighting rule: under the same hypotheses, with L = q/p where p > 0 and L = 0
elsewhere, the average of any non-negative measurable g under Q equals the average of g · L
under P. Taking g to be the indicator of a set A gives Q(A) = ∫_A L dP. -/
theorem reweighting_rule {Ω : Type*} [MeasurableSpace Ω]
    (ν : Measure Ω) [SigmaFinite ν] (p q : Ω → ℝ≥0∞) (hp : Measurable p) (hq : Measurable q)
    (P Q : Measure Ω) [IsProbabilityMeasure P] [IsProbabilityMeasure Q]
    (hP : P = ν.withDensity p) (hQ : Q = ν.withDensity q) (hQP : Q ≪ P)
    (g : Ω → ℝ≥0∞) (hg : Measurable g) :
    ∫⁻ x, g x ∂Q = ∫⁻ x, g x * (if p x = 0 then 0 else q x / p x) ∂P := by
  have hpos : ∀ᵐ x ∂P, p x ≠ 0 := by
    rw [hP, ae_withDensity_iff hp]
    exact ae_of_all _ (fun x hx => hx)
  have hr := rnDeriv_eq_ratio_of_densities ν p q hp hq P Q hP hQ hQP
  rw [← lintegral_rnDeriv_mul hQP hg.aemeasurable]
  refine lintegral_congr_ae ?_
  filter_upwards [hpos, hr] with x h1 h2
  simp only [h2, h1, ite_false, mul_comm]

/-- Gibbs' inequality: for probability measures with Q ≪ P, the Kullback-Leibler divergence
D(Q ‖ P) = ∫ ln (dQ/dP) dQ is never negative, and it is zero only when Q = P.
The divergence is written as (positive part) minus (negative part) of the log-ratio,
each integrated against Q, so that it may be +∞: "never negative" says the negative part is
at most the positive part, and "zero only when Q = P" says the two parts are equal exactly
when Q = P. -/
theorem kl_divergence_nonneg_and_zero_iff {Ω : Type*} [MeasurableSpace Ω]
    (P Q : Measure Ω) [IsProbabilityMeasure P] [IsProbabilityMeasure Q] (hQP : Q ≪ P) :
    (∫⁻ x, ENNReal.ofReal (-llr Q P x) ∂Q ≤ ∫⁻ x, ENNReal.ofReal (llr Q P x) ∂Q) ∧
    (∫⁻ x, ENNReal.ofReal (llr Q P x) ∂Q = ∫⁻ x, ENNReal.ofReal (-llr Q P x) ∂Q ↔ Q = P) := by
  set A := ∫⁻ x, ENNReal.ofReal (llr Q P x) ∂Q with hA
  set B := ∫⁻ x, ENNReal.ofReal (-llr Q P x) ∂Q with hB
  have hBfin : B ≠ ∞ := neg_part_llr_ne_top P Q hQP
  have hsplit : ∫⁻ x, ‖llr Q P x‖ₑ ∂Q = A + B := by
    rw [hA, hB, ← lintegral_add_left]
    · exact lintegral_congr (fun x => enorm_eq_ofReal_add_ofReal_neg _)
    · exact ENNReal.measurable_ofReal.comp (measurable_llr Q P)
  by_cases hint : Integrable (llr Q P) Q
  · have hAfin : A ≠ ∞ := by
      have h := (hasFiniteIntegral_iff_enorm.mp hint.hasFiniteIntegral)
      rw [hsplit] at h
      exact (ENNReal.add_lt_top.mp h).1.ne
    have hint_eq : ∫ x, llr Q P x ∂Q = A.toReal - B.toReal :=
      integral_eq_lintegral_pos_part_sub_lintegral_neg_part hint
    have hnn : 0 ≤ ∫ x, llr Q P x ∂Q := by
      have := InformationTheory.integral_llr_add_sub_measure_univ_nonneg hQP hint
      simpa using this
    have hkl : (InformationTheory.klDiv Q P).toReal = ∫ x, llr Q P x ∂Q :=
      InformationTheory.toReal_klDiv_of_measure_eq hQP (by simp)
    have hklfin : InformationTheory.klDiv Q P ≠ ∞ := InformationTheory.klDiv_ne_top hQP hint
    refine ⟨?_, ?_⟩
    · rw [← ENNReal.toReal_le_toReal hBfin hAfin]
      linarith
    · have hz : InformationTheory.klDiv Q P = 0 ↔ (InformationTheory.klDiv Q P).toReal = 0 := by
        rw [ENNReal.toReal_eq_zero_iff]; simp [hklfin]
      rw [← InformationTheory.klDiv_eq_zero_iff, ← ENNReal.toReal_eq_toReal_iff' hAfin hBfin,
        hz, hkl, hint_eq, sub_eq_zero]
  · have hAinf : A = ∞ := by
      have h : ¬ HasFiniteIntegral (llr Q P) Q := fun h =>
        hint ⟨(measurable_llr Q P).aestronglyMeasurable, h⟩
      rw [hasFiniteIntegral_iff_enorm, hsplit, not_lt, top_le_iff] at h
      by_contra hne
      exact (ENNReal.add_ne_top.mpr ⟨hne, hBfin⟩) h
    refine ⟨by rw [hAinf]; exact le_top, ?_⟩
    constructor
    · intro h
      rw [hAinf] at h
      exact absurd h.symm hBfin
    · intro h
      subst h
      exact absurd ((integrable_zero Ω ℝ Q).congr (llr_self Q).symm) hint

-- The loaded die (1/10, 1/10, 1/10, 1/10, 2/10, 4/10) is a probability law with mean 22/5 = 4.4.
example : (1/10 + 1/10 + 1/10 + 1/10 + 2/10 + 4/10 : ℚ) = 1 := by norm_num
example : (1 * (1/10) + 2 * (1/10) + 3 * (1/10) + 4 * (1/10) + 5 * (2/10) + 6 * (4/10) : ℚ)
    = 22/5 := by norm_num

-- The fair die has mean 7/2 = 3.5.
example : ((1 + 2 + 3 + 4 + 5 + 6) * (1/6) : ℚ) = 7/2 := by norm_num

-- The bus tilt: M(θ) = 1/(1 - θ) at θ = -1 is 1/2.
example : (1 / (1 - (-1)) : ℚ) = 1/2 := by norm_num

-- The die has no density against length: probability 1/6 over a window of length 2h
-- gives 5/6, 25/3, 250/3 (0.8333, 8.3333, 83.3333) for h = 1/10, 1/100, 1/1000.
example : ((1/6) / (2 * (1/10)) : ℚ) = 5/6 := by norm_num
example : ((1/6) / (2 * (1/100)) : ℚ) = 25/3 := by norm_num
example : ((1/6) / (2 * (1/1000)) : ℚ) = 250/3 := by norm_num

-- Q uniform on [0, 2] against P uniform on [0, 1]: q/p = (1/2)/1 on [0, 1], which has
-- P-mass 1, so the ratio integrates to 1/2, and Q puts the other 1/2 where p = 0.
example : ((1/2) / 1 * 1 : ℚ) = 1/2 := by norm_num
example : ((1/2) * (2 - 1) : ℚ) = 1/2 := by norm_num

#print axioms enorm_eq_ofReal_add_ofReal_neg
#print axioms mul_neg_log_le_one
#print axioms neg_part_llr_ne_top
#print axioms rnDeriv_eq_ratio_of_densities
#print axioms reweighting_rule
#print axioms kl_divergence_nonneg_and_zero_iff
