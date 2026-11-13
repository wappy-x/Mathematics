-- Delta method: for independent readings with one common law and finite spread, a function with a nonzero slope at the mean, applied to the average, has a miss that, magnified by √n, settles into a bell of variance slope² × σ², and dividing the miss by an estimated standard error that settles on the true one gives the standard bell.
import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Probability.Moments.Variance
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure
import Mathlib.Analysis.Calculus.Deriv.Basic

open MeasureTheory ProbabilityTheory Filter Topology

lemma dm_cheb {Ω : Type*} [MeasurableSpace Ω]
    {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (μ σ : ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL2 : MemLp (X 0) 2 P)
    (hmean : ∫ ω, X 0 ω ∂P = μ)
    (hvar : Var[X 0; P] = σ ^ 2) (n : ℕ) {t : ℝ} (ht : 0 < t) :
    P.real {ω | t ≤ |(Real.sqrt n)⁻¹ * (∑ k ∈ Finset.range n, X k ω - n * μ)|} ≤ σ ^ 2 / t ^ 2 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · have : {ω | t ≤ |(Real.sqrt ((0:ℕ):ℝ))⁻¹ * (∑ k ∈ Finset.range 0, X k ω - (0:ℕ) * μ)|}
        = (∅ : Set Ω) := by
      ext ω; simp [not_le.2 ht]
    rw [this]; simp; positivity
  have hL2i : ∀ i, MemLp (X i) 2 P := fun i => (hident i).memLp_iff.2 hL2
  set S : Ω → ℝ := ∑ k ∈ Finset.range n, X k with hS
  have hSapp : ∀ ω, S ω = ∑ k ∈ Finset.range n, X k ω := fun ω => by simp [hS]
  have hSL2 : MemLp S 2 P := memLp_finsetSum' _ (fun i _ => hL2i i)
  have hSmean : P[S] = n * μ := by
    rw [hS]
    simp only [Finset.sum_apply]
    rw [integral_finsetSum _ (fun i _ => (hL2i i).integrable (by norm_num))]
    simp [fun i => (hident i).integral_eq, hmean]
  have hSvar : Var[S; P] = n * σ ^ 2 := by
    rw [hS, IndepFun.variance_sum (fun i _ => hL2i i)
      (fun i _ j _ hij => hind.indepFun hij)]
    simp [fun i => (hident i).variance_eq, hvar]
  have hsq : 0 < Real.sqrt n := Real.sqrt_pos.2 (by exact_mod_cast hn)
  have hcheb := meas_ge_le_variance_div_sq hSL2 (mul_pos ht hsq)
  have hsub : {ω | t ≤ |(Real.sqrt n)⁻¹ * (∑ k ∈ Finset.range n, X k ω - n * μ)|}
      ⊆ {ω | t * Real.sqrt n ≤ |S ω - P[S]|} := by
    intro ω hω
    simp only [Set.mem_ofPred_eq] at hω ⊢
    rw [hSmean, hSapp]
    rw [abs_mul, abs_inv, abs_of_pos hsq, ← div_eq_inv_mul, le_div_iff₀ hsq] at hω
    exact hω
  have hfin : (n : ℝ) * σ ^ 2 / (t * Real.sqrt n) ^ 2 = σ ^ 2 / t ^ 2 := by
    rw [mul_pow, Real.sq_sqrt (by positivity)]
    field_simp
  rw [measureReal_def]
  refine ENNReal.toReal_le_of_le_ofReal (by positivity) ?_
  calc P _ ≤ P {ω | t * Real.sqrt n ≤ |S ω - P[S]|} := measure_mono hsub
    _ ≤ _ := hcheb
    _ = _ := by rw [hSvar, hfin]

#print axioms dm_cheb

lemma dm_scale (n : ℕ) (S μ : ℝ) :
    (Real.sqrt n)⁻¹ * (S - n * μ) = Real.sqrt n * (S / n - μ) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have hn' : (0:ℝ) < n := by exact_mod_cast hn
  have hsq : 0 < Real.sqrt n := Real.sqrt_pos.2 hn'
  have h2 : Real.sqrt n * Real.sqrt n = n := Real.mul_self_sqrt hn'.le
  field_simp
  rw [Real.sq_sqrt hn'.le]

#print axioms dm_scale

lemma dm_remainder {Ω : Type*} [MeasurableSpace Ω]
    {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (μ σ : ℝ) (g : ℝ → ℝ) (d : ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL2 : MemLp (X 0) 2 P)
    (hmean : ∫ ω, X 0 ω ∂P = μ)
    (hvar : Var[X 0; P] = σ ^ 2)
    (hg : HasDerivAt g d μ) :
    TendstoInMeasure P
      ((fun (n : ℕ) ω ↦ Real.sqrt n * (g ((∑ i ∈ Finset.range n, X i ω) / n) - g μ)) -
        (fun (n : ℕ) ω ↦ d * ((Real.sqrt n)⁻¹ * (∑ k ∈ Finset.range n, X k ω - n * μ))))
      atTop 0 := by
  rw [tendstoInMeasure_iff_measureReal_norm]
  intro ε hε
  rw [Metric.tendsto_atTop]
  intro η hη
  set s := σ ^ 2 with hs_def
  have hs : 0 ≤ s := sq_nonneg σ
  set c' := ε * Real.sqrt (η / (2 * (s + 1))) with hc'_def
  have hc' : 0 < c' := mul_pos hε (Real.sqrt_pos.2 (by positivity))
  obtain ⟨δ, hδ, hδg⟩ := Metric.eventually_nhds_iff.1 (hg.isLittleO.def hc')
  obtain ⟨N, hN⟩ : ∃ N : ℕ, 2 * s / (δ ^ 2 * η) < N := exists_nat_gt _
  refine ⟨N + 1, fun n hn => ?_⟩
  have hnpos : (0:ℝ) < n := by
    have : (0:ℝ) < (N + 1 : ℕ) := by positivity
    exact this.trans_le (by exact_mod_cast hn)
  have hNn : (N:ℝ) ≤ n := by exact_mod_cast (Nat.le_succ N).trans hn
  have hsq : 0 < Real.sqrt n := Real.sqrt_pos.2 hnpos
  rw [Real.dist_eq, sub_zero, abs_of_nonneg measureReal_nonneg]
  set Z : Ω → ℝ := fun ω ↦ (Real.sqrt n)⁻¹ * (∑ k ∈ Finset.range n, X k ω - n * μ) with hZ
  have hsub : {x | ε ≤ ‖((fun (n : ℕ) ω ↦ Real.sqrt n * (g ((∑ i ∈ Finset.range n, X i ω) / n) - g μ)) -
        (fun (n : ℕ) ω ↦ d * ((Real.sqrt n)⁻¹ * (∑ k ∈ Finset.range n, X k ω - n * μ)))) n x
        - (0 : Ω → ℝ) x‖}
      ⊆ {ω | ε / c' ≤ |Z ω|} ∪ {ω | δ * Real.sqrt n ≤ |Z ω|} := by
    intro ω hω
    simp only [Set.mem_ofPred_eq, Pi.sub_apply, Pi.zero_apply, sub_zero, Real.norm_eq_abs] at hω
    set a := (∑ i ∈ Finset.range n, X i ω) / n with ha
    have hz : Z ω = Real.sqrt n * (a - μ) := by
      simp only [hZ, ha]; exact dm_scale n _ μ
    have habsz : |Z ω| = Real.sqrt n * |a - μ| := by rw [hz, abs_mul, abs_of_pos hsq]
    change ε ≤ |Real.sqrt n * (g a - g μ) - d * Z ω| at hω
    have hrw : Real.sqrt n * (g a - g μ) - d * Z ω = Real.sqrt n * (g a - g μ - (a - μ) • d) := by
      rw [hz, smul_eq_mul]; ring
    rw [hrw, abs_mul, abs_of_pos hsq] at hω
    by_cases hA : dist a μ < δ
    · left
      have h1 := hδg hA
      simp only [Real.norm_eq_abs] at h1
      simp only [Set.mem_ofPred_eq]
      rw [div_le_iff₀ hc', habsz]
      calc ε ≤ Real.sqrt n * |g a - g μ - (a - μ) • d| := hω
        _ ≤ Real.sqrt n * (c' * |a - μ|) := by gcongr
        _ = _ := by ring
    · right
      simp only [Set.mem_ofPred_eq]
      rw [not_lt, Real.dist_eq] at hA
      rw [habsz]
      nlinarith
  have hb1 := dm_cheb X μ σ hind hident hL2 hmean hvar n (div_pos hε hc')
  have hb2 := dm_cheb X μ σ hind hident hL2 hmean hvar n (mul_pos hδ hsq)
  have he1 : σ ^ 2 / (ε / c') ^ 2 < η / 2 := by
    rw [← hs_def, div_pow, hc'_def, mul_pow, Real.sq_sqrt (by positivity)]
    rw [div_div_eq_mul_div]
    have hε2 : 0 < ε ^ 2 := by positivity
    field_simp
    nlinarith
  have he2 : σ ^ 2 / (δ * Real.sqrt n) ^ 2 < η / 2 := by
    rw [← hs_def, mul_pow, Real.sq_sqrt hnpos.le]
    rw [div_lt_iff₀ (by positivity)]
    rw [div_lt_iff₀ (by positivity)] at hN
    nlinarith
  calc P.real _ ≤ P.real ({ω | ε / c' ≤ |Z ω|} ∪ {ω | δ * Real.sqrt n ≤ |Z ω|}) :=
        measureReal_mono hsub
    _ ≤ P.real {ω | ε / c' ≤ |Z ω|} + P.real {ω | δ * Real.sqrt n ≤ |Z ω|} :=
        measureReal_union_le _ _
    _ ≤ σ ^ 2 / (ε / c') ^ 2 + σ ^ 2 / (δ * Real.sqrt n) ^ 2 := add_le_add hb1 hb2
    _ < η := by linarith

#print axioms dm_remainder

lemma dm_congr_eventually {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    {P : Measure Ω} [IsProbabilityMeasure P] {P' : Measure Ω'} [IsProbabilityMeasure P']
    {U V : ℕ → Ω → ℝ} {Y : Ω' → ℝ}
    (h : TendstoInDistribution U atTop Y (fun _ ↦ P) P')
    (hUV : ∀ᶠ n in atTop, U n = V n) (hV : ∀ n, AEMeasurable (V n) P) :
    TendstoInDistribution V atTop Y (fun _ ↦ P) P' where
  forall_aemeasurable := hV
  aemeasurable_limit := h.aemeasurable_limit
  tendsto := by
    refine h.tendsto.congr' ?_
    filter_upwards [hUV] with n hn
    exact Subtype.ext (congrArg (fun f => P.map f) hn)

#print axioms dm_congr_eventually

/-- **The delta method.** Let `X 0, X 1, X 2, …` be independent readings, all with the same law
as `X 0`, with finite spread: mean `μ` and variance `σ²`. Let `g` be a function with slope
`d = g'(μ)` at the mean, and `d ≠ 0`. Then the function's miss magnified by root n,
`√n · (g(average of the first n readings) − g(μ))`, converges in distribution to the normal law
`N(0, d² σ²)`: the law of any `Y` with that law.
(`g` is asked to be measurable only so that `g(average)` is a random variable at all; the card's
functions, such as the log odds, all are.) -/
theorem delta_method {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    {P : Measure Ω} [IsProbabilityMeasure P] {P' : Measure Ω'} [IsProbabilityMeasure P']
    (X : ℕ → Ω → ℝ) (μ σ : ℝ) (g : ℝ → ℝ) (d : ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL2 : MemLp (X 0) 2 P)
    (hmean : ∫ ω, X 0 ω ∂P = μ)
    (hvar : Var[X 0; P] = σ ^ 2)
    (hg_meas : Measurable g)
    (hg : HasDerivAt g d μ)
    (hd : d ≠ 0)
    (Y : Ω' → ℝ) (hY : HasLaw Y (gaussianReal 0 (d ^ 2 * σ ^ 2).toNNReal) P') :
    TendstoInDistribution
      (fun (n : ℕ) ω ↦ Real.sqrt n * (g ((∑ i ∈ Finset.range n, X i ω) / n) - g μ))
      atTop Y (fun _ ↦ P) P' := by
  have hmeasX : ∀ i, AEMeasurable (X i) P := fun i => (hident i).aemeasurable_fst
  have hW : HasLaw (fun ω ↦ Y ω / d) (gaussianReal 0 Var[X 0; P].toNNReal) P' := by
    convert gaussianReal_div_const hY d using 2
    · simp
    · rw [hvar]
      ext
      simp only [NNReal.coe_div, NNReal.coe_mk, Real.coe_toNNReal _ (sq_nonneg σ),
        Real.coe_toNNReal _ (by positivity : (0:ℝ) ≤ d ^ 2 * σ ^ 2)]
      field_simp
  have hclt := tendstoInDistribution_inv_sqrt_mul_sum_sub hW hL2 hind hident
  have hdZ : TendstoInDistribution
      (fun (n : ℕ) ω ↦ d * ((Real.sqrt n)⁻¹ * (∑ k ∈ Finset.range n, X k ω - n * μ)))
      atTop Y (fun _ ↦ P) P' := by
    have := hclt.continuous_comp (g := fun x => d * x) (continuous_const.mul continuous_id)
    rw [hmean] at this
    convert this using 2
    · ext ω
      simp only [Function.comp_apply]
    · ext ω
      simp only [Function.comp_apply]
      field_simp
  refine tendstoInDistribution_of_tendstoInMeasure_sub _ Y hdZ ?_ ?_
  · exact dm_remainder X μ σ g d hind hident hL2 hmean hvar hg
  · intro n
    refine AEMeasurable.const_mul (AEMeasurable.sub_const ?_ _) _
    refine hg_meas.comp_aemeasurable (AEMeasurable.div_const ?_ _)
    exact Finset.aemeasurable_fun_sum _ (fun i _ => hmeasX i)

/-- **Slutsky's theorem, in the card's form.** Under the same hypotheses, let
`SE n = |d| σ / √n` be the delta method's standard error, and let `S n` be a standard error
computed from the data (a random variable) whose ratio to `SE n` settles on 1 in probability.
Then the studentised miss `(g(average of the first n readings) − g(μ)) / S n` converges in
distribution to the standard bell `N(0, 1)`. -/
theorem studentised_delta_method {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    {P : Measure Ω} [IsProbabilityMeasure P] {P' : Measure Ω'} [IsProbabilityMeasure P']
    (X : ℕ → Ω → ℝ) (μ σ : ℝ) (g : ℝ → ℝ) (d : ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL2 : MemLp (X 0) 2 P)
    (hmean : ∫ ω, X 0 ω ∂P = μ)
    (hvar : Var[X 0; P] = σ ^ 2)
    (hg_meas : Measurable g)
    (hg : HasDerivAt g d μ)
    (hd : d ≠ 0)
    (S : ℕ → Ω → ℝ) (hS_meas : ∀ n, AEMeasurable (S n) P)
    (hS : TendstoInMeasure P (fun (n : ℕ) ω ↦ S n ω / (|d| * σ / Real.sqrt n)) atTop
      (fun _ ↦ 1))
    (Y : Ω' → ℝ) (hY : HasLaw Y (gaussianReal 0 1) P') :
    TendstoInDistribution
      (fun (n : ℕ) ω ↦ (g ((∑ i ∈ Finset.range n, X i ω) / n) - g μ) / S n ω)
      atTop Y (fun _ ↦ P) P' := by
  have hmeasX : ∀ i, AEMeasurable (X i) P := fun i => (hident i).aemeasurable_fst
  have hdiff_meas : ∀ n : ℕ, AEMeasurable
      (fun ω ↦ g ((∑ i ∈ Finset.range n, X i ω) / n) - g μ) P := by
    intro n
    refine AEMeasurable.sub_const ?_ _
    refine hg_meas.comp_aemeasurable (AEMeasurable.div_const ?_ _)
    exact Finset.aemeasurable_fun_sum _ (fun i _ => hmeasX i)
  -- the spread is not zero, otherwise `hS` says `0 → 1`
  have hσ : σ ≠ 0 := by
    rintro rfl
    have h1 := (tendstoInMeasure_iff_dist.1 hS) (1 / 2) (by norm_num)
    have h2 : ∀ n : ℕ, P {x | (1 / 2 : ℝ) ≤ dist (S n x / (|d| * 0 / Real.sqrt n)) 1} = 1 := by
      intro n
      have : {x | (1 / 2 : ℝ) ≤ dist (S n x / (|d| * 0 / Real.sqrt n)) 1} = Set.univ := by
        ext x; simp [Real.dist_eq]; norm_num
      rw [this, measure_univ]
    simp only [h2] at h1
    exact one_ne_zero (tendsto_nhds_unique tendsto_const_nhds h1)
  set c := |d| * σ with hc_def
  have hc : c ≠ 0 := mul_ne_zero (abs_ne_zero.2 hd) hσ
  have hY' : HasLaw (fun ω ↦ c * Y ω) (gaussianReal 0 (d ^ 2 * σ ^ 2).toNNReal) P' := by
    convert gaussianReal_const_mul hY c using 2
    · simp
    · ext
      simp only [NNReal.coe_mk, mul_one,
        Real.coe_toNNReal _ (by positivity : (0:ℝ) ≤ d ^ 2 * σ ^ 2), hc_def, mul_pow, sq_abs]
  have hD := delta_method X μ σ g d hind hident hL2 hmean hvar hg_meas hg hd _ hY'
  set A : ℕ → Ω → ℝ := fun n ω ↦
    Real.sqrt n * (g ((∑ i ∈ Finset.range n, X i ω) / n) - g μ) / c with hA_def
  have hA : TendstoInDistribution A atTop Y (fun _ ↦ P) P' := by
    have := hD.continuous_comp (g := fun x => x / c) (continuous_id.div_const c)
    convert this using 2
    · ext ω
      simp only [Function.comp_apply, hA_def]
    · ext ω
      simp only [Function.comp_apply]
      field_simp
  set R : ℕ → Ω → ℝ := fun n ω ↦ S n ω / (|d| * σ / Real.sqrt n) with hR_def
  have hR_meas : ∀ n, AEMeasurable (R n) P := fun n => (hS_meas n).div_const _
  have hA_meas : ∀ n, AEMeasurable (A n) P :=
    fun n => ((hdiff_meas n).const_mul _).div_const _
  have hB := hA.continuous_comp_prodMk_of_tendstoInMeasure_const
    (g := fun p : ℝ × ℝ => p.1 / max p.2 (1 / 2))
    (Continuous.div continuous_fst (continuous_snd.max continuous_const)
      (fun p => by positivity)) hS hR_meas
  simp only [max_eq_left (by norm_num : (1 / 2 : ℝ) ≤ 1), div_one] at hB
  have hC : TendstoInDistribution (fun n ω ↦ A n ω / R n ω) atTop Y (fun _ ↦ P) P' := by
    refine tendstoInDistribution_of_tendstoInMeasure_sub _ Y hB ?_
      (fun n => (hA_meas n).div (hR_meas n))
    rw [tendstoInMeasure_iff_norm]
    intro ε hε
    have h1 := (tendstoInMeasure_iff_dist.1 hS) (1 / 2) (by norm_num)
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds h1
      (fun _ => bot_le) (fun n => measure_mono ?_)
    intro ω hω
    simp only [Set.mem_ofPred_eq, Pi.sub_apply, Pi.zero_apply, sub_zero] at hω ⊢
    by_contra hlt
    rw [not_le, Real.dist_eq] at hlt
    have hR : (1 / 2 : ℝ) ≤ R n ω := by
      have := (abs_lt.1 hlt).1
      linarith
    rw [max_eq_left hR, sub_self, norm_zero] at hω
    linarith
  refine dm_congr_eventually hC ?_ (fun n => (hdiff_meas n).div (hS_meas n))
  filter_upwards [eventually_ge_atTop 1] with n hn
  ext ω
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hsq : Real.sqrt n ≠ 0 := (Real.sqrt_pos.2 hn').ne'
  simp only [hA_def, hR_def, ← hc_def]
  by_cases hS0 : S n ω = 0
  · simp [hS0]
  · field_simp

/-- **Slope times spread is Woolf's term (Step 2).** For a true chance `p` strictly between 0
and 1 and `n > 0` patients, the log odds' slope `1/(p(1 − p))` times the share's spread
`√(p(1 − p)/n)`, squared, equals `1/(np) + 1/(n(1 − p))`: one over each expected count. -/
theorem log_odds_slope_times_spread (p n : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (hn : 0 < n) :
    (1 / (p * (1 - p))) ^ 2 * (p * (1 - p) / n) = 1 / (n * p) + 1 / (n * (1 - p)) := by
  have h1 : (1 - p) ≠ 0 := by linarith
  field_simp
  ring

-- The trial's odds: drug 60/340 = 3/17, placebo 100/300 = 1/3; odds ratio 9/17 (0.529412).
example : (60 / 340 : ℚ) = 3 / 17 := by norm_num
example : (100 / 300 : ℚ) = 1 / 3 := by norm_num
example : ((60 / 340) / (100 / 300) : ℚ) = 9 / 17 := by norm_num
-- Shares: 60/400 = 3/20 (0.15) and 100/400 = 1/4 (0.25); expected counts 400 × 3/20 = 60 and 400 × 17/20 = 340.
example : (60 / 400 : ℚ) = 3 / 20 ∧ (100 / 400 : ℚ) = 1 / 4 := by norm_num
example : (400 : ℚ) * (3 / 20) = 60 ∧ (400 : ℚ) * (1 - 3 / 20) = 340 := by norm_num
-- One drug patient's variance 0.15 × 0.85 = 51/400; slope of the log odds 1/(0.15 × 0.85) = 400/51 (7.843137).
example : (3 / 20 : ℚ) * (1 - 3 / 20) = 51 / 400 := by norm_num
example : 1 / ((3 / 20 : ℚ) * (1 - 3 / 20)) = 400 / 51 := by norm_num
-- Placebo slope 1/(0.25 × 0.75) = 16/3 (5.333333).
example : 1 / ((1 / 4 : ℚ) * (1 - 1 / 4)) = 16 / 3 := by norm_num
-- Step 2: slope² × variance of the share = 1/60 + 1/340 = 1/51 (0.140028²).
example : (400 / 51 : ℚ) ^ 2 * (51 / 400 / 400) = 1 / 60 + 1 / 340 := by norm_num
example : (1 / 60 + 1 / 340 : ℚ) = 1 / 51 := by norm_num
-- Placebo: (16/3)² × (3/16)/400 = 1/100 + 1/300 = 1/75 (0.115470²).
example : (16 / 3 : ℚ) ^ 2 * ((1 / 4) * (3 / 4) / 400) = 1 / 100 + 1 / 300 := by norm_num
example : (1 / 100 + 1 / 300 : ℚ) = 1 / 75 := by norm_num
-- Step 4, Woolf: the variances add, 1/60 + 1/340 + 1/100 + 1/300 = 14/425 (0.032941).
example : (1 / 60 + 1 / 340 + 1 / 100 + 1 / 300 : ℚ) = 14 / 425 := by norm_num
example : (1 / 51 + 1 / 75 : ℚ) = 14 / 425 := by norm_num
-- The exact count runs over every outcome pair of a trial: 401 × 401 = 160801.
example : (401 : ℕ) * 401 = 160801 := by norm_num

#print axioms delta_method
#print axioms studentised_delta_method
#print axioms log_odds_slope_times_spread
