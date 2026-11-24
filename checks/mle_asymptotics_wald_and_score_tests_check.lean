-- Large-sample likelihood: for recover-or-not patients the MLE is asymptotically normal with variance one over the Fisher information, the average log-likelihood peaks only at the truth, and the score statistic equals the trial's closed form.
import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Probability.IdentDistrib
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Filter Finset

/-- Fisher information of one recover-or-not patient with recovery rate `p`:
`I(p) = 1 / (p (1 - p))`. -/
noncomputable def bernFisherInfo (p : ℝ) : ℝ := 1 / (p * (1 - p))

/-- The trial's log-likelihood for `x` recoveries in `n` patients:
`ℓ(p) = x ln p + (n - x) ln (1 - p)`. -/
noncomputable def binLogLik (x n : ℕ) (p : ℝ) : ℝ :=
  (x : ℝ) * Real.log p + ((n : ℝ) - x) * Real.log (1 - p)

/-- The Wald statistic `z = (p̂ - p₀) √(n I(p̂))`, with `p̂ = x / n` the MLE. -/
noncomputable def waldZ (x n : ℕ) (p₀ : ℝ) : ℝ :=
  ((x : ℝ) / n - p₀) * Real.sqrt (n * bernFisherInfo ((x : ℝ) / n))

/-- The score statistic `z = ℓ'(p₀) / √(n I(p₀))`: the slope of the log-likelihood at the
null, divided by its own spread under the null. -/
noncomputable def scoreZ (x n : ℕ) (p₀ : ℝ) : ℝ :=
  deriv (binLogLik x n) p₀ / Real.sqrt (n * bernFisherInfo p₀)

/-- The long-run average log-likelihood per patient, `K(θ) = E_{θ*}[ln f(Y; θ)]`, for a model
`f` giving each value `θ` a law on a finite set of outcomes, when the truth is `θ*`. -/
noncomputable def avgLogLik {Θ Y : Type*} [Fintype Y] (f : Θ → Y → ℝ) (θstar θ : Θ) : ℝ :=
  ∑ y, f θstar y * Real.log (f θ y)

theorem binLogLik_deriv (x n : ℕ) (p₀ : ℝ) (h0 : 0 < p₀) (h1 : p₀ < 1) :
    deriv (binLogLik x n) p₀ = (x : ℝ) / p₀ - ((n : ℝ) - x) / (1 - p₀) := by
  have hd : HasDerivAt (binLogLik x n)
      ((x : ℝ) * p₀⁻¹ + ((n : ℝ) - x) * ((-1) / (1 - p₀))) p₀ := by
    unfold binLogLik
    have h2 : HasDerivAt (fun p : ℝ => 1 - p) (-1) p₀ := by
      simpa using (hasDerivAt_id p₀).const_sub 1
    exact ((Real.hasDerivAt_log h0.ne').const_mul _).add
      ((h2.log (by linarith)).const_mul _)
  rw [hd.deriv]
  ring

#print axioms binLogLik_deriv

/-- **The MLE is nearly normal, with variance one over n times the Fisher information.**
Patients are independent and all follow one model: each recovers (outcome 1) or not
(outcome 0), with recovery chance `p` strictly between 0 and 1. The MLE after `n` patients is
the fraction who recovered, `p̂ₙ = (X₁ + ⋯ + Xₙ)/n`. Then `√n (p̂ₙ - p)` converges in law to
a normal with mean 0 and variance `1 / I(p) = p(1 - p)`. -/
theorem mle_asymptotically_normal_bernoulli
    {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    {P : Measure Ω} {P' : Measure Ω'} [IsProbabilityMeasure P] [IsProbabilityMeasure P']
    (X : ℕ → Ω → ℝ) (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1)
    (hmeas : ∀ k, Measurable (X k))
    (hval : ∀ k ω, X k ω = 0 ∨ X k ω = 1)
    (hrate : P.real {ω | X 0 ω = 1} = p)
    (hindep : iIndepFun X P)
    (hident : ∀ k, IdentDistrib (X k) (X 0) P P)
    (Z : Ω' → ℝ) (hZ : HasLaw Z (gaussianReal 0 (1 / bernFisherInfo p).toNNReal) P') :
    TendstoInDistribution
      (fun (n : ℕ) ω => Real.sqrt n * ((∑ k ∈ range n, X k ω) / n - p))
      atTop Z (fun _ => P) P' := by
  have hS : MeasurableSet {ω | X 0 ω = 1} := hmeas 0 (measurableSet_singleton 1)
  have hind : X 0 = {ω | X 0 ω = 1}.indicator 1 := by
    funext ω
    rcases hval 0 ω with h | h <;> simp [Set.indicator, h]
  have hsq : X 0 ^ 2 = X 0 := by
    funext ω
    rcases hval 0 ω with h | h <;> simp [h]
  have hmean : P[X 0] = p := by
    rw [hind, integral_indicator_one hS, hrate]
  have hL2 : MemLp (X 0) 2 P := by
    refine memLp_of_bounded (a := 0) (b := 1) (Filter.Eventually.of_forall fun ω => ?_)
      (hmeas 0).aestronglyMeasurable 2
    rcases hval 0 ω with h | h <;> simp [h]
  have hvar : Var[X 0; P] = 1 / bernFisherInfo p := by
    rw [variance_eq_sub hL2, hsq, hmean, bernFisherInfo]
    field_simp
  rw [← hvar] at hZ
  have key := tendstoInDistribution_inv_sqrt_mul_sum_sub hZ hL2 hindep hident
  rw [hmean] at key
  convert key using 2 with n
  funext ω
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn; simp
  · have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have hs : 0 < Real.sqrt n := Real.sqrt_pos.mpr hn'
    have hsq' : Real.sqrt n * Real.sqrt n = n := Real.mul_self_sqrt hn'.le
    rw [eq_comm, inv_mul_eq_iff_eq_mul₀ hs.ne', ← mul_assoc, hsq']
    field_simp

/-- **The average log-likelihood peaks only at the truth (the heart of consistency).**
Take a model that gives each value `θ` a law `f θ` on a finite set of outcomes, every outcome
possible under every value (the outcome set does not move with `θ`), and different values
giving different laws (identifiability). Then for every `θ ≠ θ*`,
`K(θ) = E_{θ*}[ln f(Y; θ)]` is strictly below `K(θ*)`. -/
theorem avg_loglik_lt_at_truth {Θ Y : Type*} [Fintype Y] (f : Θ → Y → ℝ)
    (hpos : ∀ θ y, 0 < f θ y) (hsum : ∀ θ, ∑ y, f θ y = 1)
    (hident : Function.Injective f) {θ θstar : Θ} (hne : θ ≠ θstar) :
    avgLogLik f θstar θ < avgLogLik f θstar θstar := by
  have hne' : f θ ≠ f θstar := fun h => hne (hident h)
  obtain ⟨y0, hy0⟩ : ∃ y, f θ y ≠ f θstar y := by
    by_contra h
    push Not at h
    exact hne' (funext h)
  have hlt : ∑ y, f θstar y * (Real.log (f θ y) - Real.log (f θstar y))
      < ∑ y, (f θ y - f θstar y) := by
    apply Finset.sum_lt_sum
    · intro y _
      have hq := hpos θstar y
      have hr : 0 < f θ y / f θstar y := div_pos (hpos θ y) hq
      have := Real.log_le_sub_one_of_pos hr
      rw [Real.log_div (hpos θ y).ne' hq.ne'] at this
      have h2 := mul_le_mul_of_nonneg_left this hq.le
      have e : f θstar y * (f θ y / f θstar y - 1) = f θ y - f θstar y := by
        field_simp
      rw [mul_sub]
      linarith
    · refine ⟨y0, Finset.mem_univ _, ?_⟩
      have hq := hpos θstar y0
      have hr : 0 < f θ y0 / f θstar y0 := div_pos (hpos θ y0) hq
      have hr1 : f θ y0 / f θstar y0 ≠ 1 := by
        intro h
        exact hy0 ((div_eq_one_iff_eq hq.ne').mp h)
      have := Real.log_lt_sub_one_of_pos hr hr1
      rw [Real.log_div (hpos θ y0).ne' hq.ne'] at this
      have h2 := mul_lt_mul_of_pos_left this hq
      have e : f θstar y0 * (f θ y0 / f θstar y0 - 1) = f θ y0 - f θstar y0 := by
        field_simp
      rw [mul_sub]
      linarith
  rw [Finset.sum_sub_distrib, hsum, hsum, sub_self] at hlt
  unfold avgLogLik
  have : ∑ y, f θstar y * (Real.log (f θ y) - Real.log (f θstar y))
      = ∑ y, f θstar y * Real.log (f θ y) - ∑ y, f θstar y * Real.log (f θstar y) := by
    rw [← Finset.sum_sub_distrib]
    congr 1; funext y; ring
  linarith

/-- **The score statistic for the trial.** For `x` recoveries in `n > 0` patients and a null
rate `p₀` strictly between 0 and 1, the slope of the log-likelihood at `p₀` divided by
`√(n I(p₀))` is `(p̂ - p₀) / √(p₀(1 - p₀)/n)`, with `p̂ = x / n`. -/
theorem score_z_eq_closed_form (x n : ℕ) (hn : 0 < n) (p₀ : ℝ) (h0 : 0 < p₀) (h1 : p₀ < 1) :
    scoreZ x n p₀ = ((x : ℝ) / n - p₀) / Real.sqrt (p₀ * (1 - p₀) / n) := by
  unfold scoreZ
  rw [binLogLik_deriv x n p₀ h0 h1, bernFisherInfo]
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hq : 0 < p₀ * (1 - p₀) := mul_pos h0 (by linarith)
  have h1' : (0:ℝ) < 1 - p₀ := by linarith
  rw [Real.sqrt_div' _ hn'.le, mul_one_div, Real.sqrt_div' _ hq.le]
  have e3 : (x : ℝ) / p₀ - ((n : ℝ) - x) / (1 - p₀) = ((x : ℝ) - n * p₀) / (p₀ * (1 - p₀)) := by
    field_simp
    ring
  rw [e3]
  have hsn : 0 < Real.sqrt n := Real.sqrt_pos.mpr hn'
  have hsq : 0 < Real.sqrt (p₀ * (1 - p₀)) := Real.sqrt_pos.mpr hq
  have e1 : Real.sqrt n * Real.sqrt n = n := Real.mul_self_sqrt hn'.le
  have e2 : Real.sqrt (p₀ * (1 - p₀)) * Real.sqrt (p₀ * (1 - p₀)) = p₀ * (1 - p₀) :=
    Real.mul_self_sqrt hq.le
  generalize Real.sqrt (n : ℝ) = a at *
  generalize Real.sqrt (p₀ * (1 - p₀)) = b at *
  rw [← e2, ← e1]
  field_simp

-- The trial: 45 of 100 recovered, null rate 0.35 = 7/20, MLE 0.45 = 9/20.
-- Information of the whole trial at the MLE and at the null: 404.0404 and 439.5604.
example : (100 : ℝ) * bernFisherInfo (9 / 20) = 40000 / 99 := by
  unfold bernFisherInfo; norm_num
example : (100 : ℝ) * bernFisherInfo (7 / 20) = 40000 / 91 := by
  unfold bernFisherInfo; norm_num
-- The slope of the log-likelihood at the null, 43.9560.
example : (45 : ℝ) / (7 / 20) - 55 / (1 - 7 / 20) = 4000 / 91 := by norm_num
-- Wald z squared is 4.0404 and score z squared is 4.3956, as on the chart at 0.35.
example : waldZ 45 100 (7 / 20) ^ 2 = 400 / 99 := by
  unfold waldZ bernFisherInfo
  rw [mul_pow, Real.sq_sqrt (by norm_num)]
  norm_num
example : scoreZ 45 100 (7 / 20) ^ 2 = 400 / 91 := by
  rw [score_z_eq_closed_form 45 100 (by norm_num) (7 / 20) (by norm_num) (by norm_num),
    div_pow, Real.sq_sqrt (by norm_num)]
  norm_num

#print axioms mle_asymptotically_normal_bernoulli
#print axioms avg_loglik_lt_at_truth
#print axioms score_z_eq_closed_form
