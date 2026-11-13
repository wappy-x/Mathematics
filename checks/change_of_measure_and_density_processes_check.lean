-- Changing the measure: a positive martingale with mean 1 reweights a probability into an equivalent one whose averages are the old averages times the density, with Bayes' rule for conditional averages and the martingale transfer rule.
import Mathlib.Probability.Martingale.Basic
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap
import Mathlib.MeasureTheory.Function.ConditionalExpectation.PullOut
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open MeasureTheory

lemma com_integral_withDensity {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω)
    {f : Ω → ℝ} (hf : Measurable f) (hpos : ∀ᵐ ω ∂P, 0 < f ω) (X : Ω → ℝ) :
    ∫ ω, X ω ∂(P.withDensity fun ω => ENNReal.ofReal (f ω)) = ∫ ω, X ω * f ω ∂P := by
  have h := integral_withDensity_eq_integral_smul (μ := P) hf.real_toNNReal X
  rw [show (fun ω => ENNReal.ofReal (f ω)) = fun ω => ((f ω).toNNReal : ENNReal) from rfl, h]
  apply integral_congr_ae
  filter_upwards [hpos] with ω h
  simp [NNReal.smul_def, Real.coe_toNNReal _ h.le, mul_comm]

lemma com_integrable_withDensity_iff {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω)
    {f : Ω → ℝ} (hf : Measurable f) (hpos : ∀ᵐ ω ∂P, 0 < f ω) (X : Ω → ℝ) :
    Integrable X (P.withDensity fun ω => ENNReal.ofReal (f ω)) ↔
      Integrable (fun ω => X ω * f ω) P := by
  rw [show (fun ω => ENNReal.ofReal (f ω)) = fun ω => ((f ω).toNNReal : ENNReal) from rfl,
    integrable_withDensity_iff_integrable_smul hf.real_toNNReal]
  apply integrable_congr
  filter_upwards [hpos] with ω h
  simp [NNReal.smul_def, Real.coe_toNNReal _ h.le, mul_comm]

lemma com_trim_eq {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω) [IsProbabilityMeasure P]
    (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (hZ : Martingale Z ℱ P)
    (hpos : ∀ n, ∀ᵐ ω ∂P, 0 < Z n ω) {k N : ℕ} (hkN : k ≤ N) :
    (P.withDensity fun ω => ENNReal.ofReal (Z N ω)).trim (ℱ.le k) =
      (P.withDensity fun ω => ENNReal.ofReal (Z k ω)).trim (ℱ.le k) := by
  refine @Measure.ext _ (ℱ k) _ _ fun s hs => ?_
  rw [trim_measurableSet_eq _ hs, trim_measurableSet_eq _ hs,
    withDensity_apply _ (ℱ.le k s hs), withDensity_apply _ (ℱ.le k s hs),
    ← ofReal_integral_eq_lintegral_ofReal (hZ.integrable N).integrableOn
      (ae_restrict_of_ae ((hpos N).mono fun ω h => h.le)),
    ← ofReal_integral_eq_lintegral_ofReal (hZ.integrable k).integrableOn
      (ae_restrict_of_ae ((hpos k).mono fun ω h => h.le)),
    hZ.setIntegral_eq hkN hs]

lemma com_Z_measurable {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω)
    (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (hZ : Martingale Z ℱ P) (k : ℕ) :
    Measurable (Z k) :=
  ((hZ.1 k).mono (ℱ.le k)).measurable

lemma com_transfer {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω) [IsProbabilityMeasure P]
    (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (hZ : Martingale Z ℱ P)
    (hpos : ∀ n, ∀ᵐ ω ∂P, 0 < Z n ω) {k N : ℕ} (hkN : k ≤ N) {f : Ω → ℝ}
    (hf : StronglyMeasurable[ℱ k] f) :
    (Integrable f (P.withDensity fun ω => ENNReal.ofReal (Z N ω)) ↔
      Integrable (fun ω => f ω * Z k ω) P) ∧
    ∫ ω, f ω ∂(P.withDensity fun ω => ENNReal.ofReal (Z N ω)) = ∫ ω, f ω * Z k ω ∂P := by
  have htrim := com_trim_eq P ℱ Z hZ hpos hkN
  refine ⟨?_, ?_⟩
  · rw [← com_integrable_withDensity_iff P (com_Z_measurable P ℱ Z hZ k) (hpos k)]
    constructor
    · intro h
      exact integrable_of_integrable_trim (ℱ.le k) (htrim ▸ h.trim (ℱ.le k) hf)
    · intro h
      exact integrable_of_integrable_trim (ℱ.le k) (htrim.symm ▸ h.trim (ℱ.le k) hf)
  · rw [integral_trim (ℱ.le k) hf, htrim, ← integral_trim (ℱ.le k) hf,
      com_integral_withDensity P (com_Z_measurable P ℱ Z hZ k) (hpos k)]

#print axioms com_integral_withDensity
#print axioms com_integrable_withDensity_iff
#print axioms com_trim_eq
#print axioms com_Z_measurable
#print axioms com_transfer

/-- Changing the measure with a density process. Let Z be a martingale under the probability P,
positive almost surely at every time, with mean 1. Fix a finite horizon N and define the new
measure Q by Q(A) = E^P[Z_N; A]. Then Q is a probability, Q and P are equivalent (each one's
null sets are the other's), every average under Q is the P-average of the quantity times Z_N,
and on events decided by time M ≤ N the density of Q against P is Z_M, so the measures built
from different horizons agree. -/
theorem change_of_measure_by_positive_martingale
    {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω) [IsProbabilityMeasure P]
    (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (hZ : Martingale Z ℱ P)
    (hpos : ∀ n, ∀ᵐ ω ∂P, 0 < Z n ω) (hmean : ∫ ω, Z 0 ω ∂P = 1) (N : ℕ) :
    IsProbabilityMeasure (P.withDensity fun ω => ENNReal.ofReal (Z N ω)) ∧
    P.withDensity (fun ω => ENNReal.ofReal (Z N ω)) ≪ P ∧
    P ≪ P.withDensity (fun ω => ENNReal.ofReal (Z N ω)) ∧
    (∀ X : Ω → ℝ, ∫ ω, X ω ∂(P.withDensity fun ω => ENNReal.ofReal (Z N ω)) =
      ∫ ω, X ω * Z N ω ∂P) ∧
    (∀ M ≤ N, ∀ A, MeasurableSet[ℱ M] A →
      P.withDensity (fun ω => ENNReal.ofReal (Z N ω)) A =
        ∫⁻ ω in A, ENNReal.ofReal (Z M ω) ∂P) := by
  have hmeas := com_Z_measurable P ℱ Z hZ N
  have h5 : ∀ M ≤ N, ∀ A, MeasurableSet[ℱ M] A →
      P.withDensity (fun ω => ENNReal.ofReal (Z N ω)) A =
        ∫⁻ ω in A, ENNReal.ofReal (Z M ω) ∂P := by
    intro M hM A hA
    rw [← trim_measurableSet_eq (ℱ.le M) hA, com_trim_eq P ℱ Z hZ hpos hM,
      trim_measurableSet_eq (ℱ.le M) hA, withDensity_apply _ (ℱ.le M A hA)]
  refine ⟨⟨?_⟩, withDensity_absolutelyContinuous _ _, ?_, ?_, h5⟩
  · rw [h5 0 (Nat.zero_le N) Set.univ MeasurableSet.univ, Measure.restrict_univ,
      ← ofReal_integral_eq_lintegral_ofReal (hZ.integrable 0)
        ((hpos 0).mono fun ω h => h.le), hmean, ENNReal.ofReal_one]
  · refine withDensity_absolutelyContinuous' hmeas.ennreal_ofReal.aemeasurable ?_
    filter_upwards [hpos N] with ω h
    simpa using h
  · exact com_integral_withDensity P hmeas (hpos N)

/-- Bayes' rule under a changed measure. With Z and Q as above, for n ≤ N and any X integrable
under Q, the conditional average of X under Q given the first n steps is the conditional
P-average of X times Z_N, divided by the weight already earned, Z_n. -/
theorem bayes_rule_for_changed_measure
    {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω) [IsProbabilityMeasure P]
    (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (hZ : Martingale Z ℱ P)
    (hpos : ∀ n, ∀ᵐ ω ∂P, 0 < Z n ω) (hmean : ∫ ω, Z 0 ω ∂P = 1)
    {n N : ℕ} (hnN : n ≤ N) (X : Ω → ℝ)
    (hX : Integrable X (P.withDensity fun ω => ENNReal.ofReal (Z N ω))) :
    (P.withDensity fun ω => ENNReal.ofReal (Z N ω))[X | ℱ n] =ᵐ[P]
      fun ω => P[fun ω => X ω * Z N ω | ℱ n] ω / Z n ω := by
  have hprob := (change_of_measure_by_positive_martingale P ℱ Z hZ hpos hmean N).1
  have hPQ := (change_of_measure_by_positive_martingale P ℱ Z hZ hpos hmean N).2.2.1
  have hZNm := com_Z_measurable P ℱ Z hZ N
  have hXZ : Integrable (fun ω => X ω * Z N ω) P :=
    (com_integrable_withDensity_iff P hZNm (hpos N) X).1 hX
  set g : Ω → ℝ := fun ω => P[fun ω => X ω * Z N ω | ℱ n] ω / Z n ω with hg_def
  have hgm : StronglyMeasurable[ℱ n] g :=
    (Measurable.div (stronglyMeasurable_condExp.measurable) (hZ.1 n).measurable).stronglyMeasurable
  have hgZ : (fun ω => g ω * Z n ω) =ᵐ[P] P[fun ω => X ω * Z N ω | ℱ n] := by
    filter_upwards [hpos n] with ω h
    simp only [hg_def]
    field_simp
  have hgint : Integrable g (P.withDensity fun ω => ENNReal.ofReal (Z N ω)) :=
    (com_transfer P ℱ Z hZ hpos hnN hgm).1.2 (integrable_condExp.congr hgZ.symm)
  apply hPQ.ae_eq
  refine (ae_eq_condExp_of_forall_setIntegral_eq (ℱ.le n) hX
    (fun s _ _ => hgint.integrableOn) ?_ hgm.aestronglyMeasurable).symm
  intro s hs _
  have hs0 : MeasurableSet s := ℱ.le n s hs
  rw [← integral_indicator hs0,
    (com_transfer P ℱ Z hZ hpos hnN (hgm.indicator hs)).2]
  have hind : (fun ω => s.indicator g ω * Z n ω) = s.indicator (fun ω => g ω * Z n ω) := by
    funext ω
    by_cases h : ω ∈ s <;> simp [h]
  rw [hind, integral_indicator hs0, setIntegral_congr_ae hs0 (hgZ.mono fun ω h _ => h),
    setIntegral_condExp (ℱ.le n) hXZ hs, restrict_withDensity hs0,
    com_integral_withDensity (P.restrict s) hZNm (ae_restrict_of_ae (hpos N))]

/-- A fair game under Q is a P-fair game after multiplying by Z. With Z and Q as above, let Y be
adapted, with Y_n integrable under Q for n ≤ N. Then Y is a Q-martingale up to time N exactly
when Y_n Z_n is a P-martingale up to time N. -/
theorem q_martingale_iff_density_times_p_martingale
    {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω) [IsProbabilityMeasure P]
    (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (hZ : Martingale Z ℱ P)
    (hpos : ∀ n, ∀ᵐ ω ∂P, 0 < Z n ω) (hmean : ∫ ω, Z 0 ω ∂P = 1) (N : ℕ)
    (Y : ℕ → Ω → ℝ) (hY : Adapted ℱ Y)
    (hYint : ∀ n ≤ N, Integrable (Y n) (P.withDensity fun ω => ENNReal.ofReal (Z N ω))) :
    (∀ n < N, (P.withDensity fun ω => ENNReal.ofReal (Z N ω))[Y (n + 1) | ℱ n] =ᵐ[P] Y n) ↔
    (∀ n < N, P[fun ω => Y (n + 1) ω * Z (n + 1) ω | ℱ n] =ᵐ[P] fun ω => Y n ω * Z n ω) := by
  have hB : ∀ n < N, (P.withDensity fun ω => ENNReal.ofReal (Z N ω))[Y (n + 1) | ℱ n] =ᵐ[P]
      fun ω => P[fun ω => Y (n + 1) ω * Z (n + 1) ω | ℱ n] ω / Z n ω := by
    intro n hn
    have hYZ : Integrable (fun ω => Y (n + 1) ω * Z N ω) P :=
      (com_integrable_withDensity_iff P (com_Z_measurable P ℱ Z hZ N) (hpos N) _).1
        (hYint (n + 1) hn)
    have hpull : P[fun ω => Y (n + 1) ω * Z N ω | ℱ (n + 1)] =ᵐ[P]
        fun ω => Y (n + 1) ω * Z (n + 1) ω := by
      have h1 := condExp_mul_of_stronglyMeasurable_left (m := ℱ (n + 1)) (μ := P)
        (f := Y (n + 1)) (g := Z N) (hY (n + 1)).stronglyMeasurable hYZ (hZ.integrable N)
      filter_upwards [h1, hZ.condExp_ae_eq (Nat.succ_le_of_lt hn)] with ω h1 h2
      simp only [Pi.mul_apply] at h1
      rw [show (fun ω => Y (n + 1) ω * Z N ω) = Y (n + 1) * Z N from rfl, h1, h2]
    have htower : P[fun ω => Y (n + 1) ω * Z N ω | ℱ n] =ᵐ[P]
        P[fun ω => Y (n + 1) ω * Z (n + 1) ω | ℱ n] :=
      (condExp_condExp_of_le (ℱ.mono (Nat.le_succ n)) (ℱ.le (n + 1))).symm.trans
        (condExp_congr_ae hpull)
    refine (bayes_rule_for_changed_measure P ℱ Z hZ hpos hmean hn.le (Y (n + 1))
      (hYint (n + 1) hn)).trans ?_
    filter_upwards [htower] with ω h
    rw [h]
  constructor
  · intro h n hn
    filter_upwards [h n hn, hB n hn, hpos n] with ω h1 h2 h3
    rw [h2, div_eq_iff h3.ne'] at h1
    exact h1
  · intro h n hn
    filter_upwards [h n hn, hB n hn, hpos n] with ω h1 h2 h3
    rw [h2, h1]
    field_simp

-- The card's coin: P has heads 3/5, Q (fair) has heads 1/2, ten tosses.
-- Each factor averages 1 under P: 3/5 * 5/6 + 2/5 * 5/4 = 1.
example : (3 / 5 : ℚ) * (5 / 6) + (2 / 5) * (5 / 4) = 1 := by norm_num
-- The traced run THHHHTHHHT (7 heads, 3 tails): loaded chance times weight is the fair 1/1024.
example : (3 / 5 : ℚ) ^ 7 * (2 / 5) ^ 3 * ((5 / 6) ^ 7 * (5 / 4) ^ 3) = 1 / 1024 ∧
    (1 / 2 : ℚ) ^ 10 = 1 / 1024 := by norm_num
-- E^P[Z_10] = 1, summing over the heads count k.
example : ∑ k ∈ Finset.range 11, (Nat.choose 10 k : ℚ) * (3 / 5) ^ k * (2 / 5) ^ (10 - k) *
    ((5 / 6) ^ k * (5 / 4) ^ (10 - k)) = 1 := by
  simp [Finset.sum_range_succ, Nat.choose]; norm_num
-- Winnings S_10 = 2k - 10: unweighted P-average 2, weighted P-average 0 (the fair average).
example : ∑ k ∈ Finset.range 11, (Nat.choose 10 k : ℚ) * (3 / 5) ^ k * (2 / 5) ^ (10 - k) *
    (2 * k - 10) = 2 := by
  simp [Finset.sum_range_succ, Nat.choose]; norm_num
example : ∑ k ∈ Finset.range 11, (Nat.choose 10 k : ℚ) * (3 / 5) ^ k * (2 / 5) ^ (10 - k) *
    ((5 / 6) ^ k * (5 / 4) ^ (10 - k)) * (2 * k - 10) = 0 := by
  simp [Finset.sum_range_succ, Nat.choose]; norm_num
-- Seven or more heads: 176 of the 1,024 runs, and E^P[Z_10; 7+] = 176/1024.
example : ∑ k ∈ Finset.Icc 7 10, Nat.choose 10 k = 176 := by decide
example : ∑ k ∈ Finset.Icc 7 10, (Nat.choose 10 k : ℚ) * (3 / 5) ^ k * (2 / 5) ^ (10 - k) *
    ((5 / 6) ^ k * (5 / 4) ^ (10 - k)) = 176 / 1024 := by
  simp [Finset.sum_Icc_succ_top, Nat.choose]; norm_num
-- The ratio upside down (6/5 on heads, 4/5 on tails) averages (26/25)^10, not 1.
example : ∑ k ∈ Finset.range 11, (Nat.choose 10 k : ℚ) * (3 / 5) ^ k * (2 / 5) ^ (10 - k) *
    ((6 / 5) ^ k * (4 / 5) ^ (10 - k)) = (26 / 25) ^ 10 := by
  simp [Finset.sum_range_succ, Nat.choose]; norm_num
-- Bayes after four heads: E^P[S_10 Z_10 | HHHH] divided by Z_4 = (5/6)^4 is 4.
example : (∑ k ∈ Finset.range 7, (Nat.choose 6 k : ℚ) * (3 / 5) ^ k * (2 / 5) ^ (6 - k) *
    ((5 / 6) ^ (4 + k) * (5 / 4) ^ (6 - k)) * (2 * (4 + k) - 10)) / (5 / 6) ^ 4 = 4 := by
  simp [Finset.sum_range_succ, Nat.choose]; norm_num

#print axioms change_of_measure_by_positive_martingale
#print axioms bayes_rule_for_changed_measure
#print axioms q_martingale_iff_density_times_p_martingale
