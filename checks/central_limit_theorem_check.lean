-- Central limit theorem: for independent readings with one common law and a finite, positive spread, the chance that the average's miss from the mean, measured in units of σ/√n, is at most z tends to the standard bell's area Φ(z), and the chance that it lies within z of those units tends to 2Φ(z) − 1.
import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Probability.CDF
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.Moments.MGFAnalytic

open MeasureTheory ProbabilityTheory Filter Topology

lemma clt_aux_identity (s μ σ : ℝ) (n : ℕ) (hσ : 0 < σ) :
    (Real.sqrt n)⁻¹ * ((s - n * μ) / σ) = (s / n - μ) / (σ / Real.sqrt n) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hs : 0 < Real.sqrt n := Real.sqrt_pos.2 hn'
  have hsq : Real.sqrt n ^ 2 = n := Real.sq_sqrt hn'.le
  generalize Real.sqrt n = r at *
  field_simp
  rw [hsq]

lemma clt_aux_tendsto_measure {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (S : ℕ → Ω → ℝ)
    (h : TendstoInDistribution S atTop id (fun _ => P) (gaussianReal 0 1))
    (E : Set ℝ) (hE : MeasurableSet E) (hfr : gaussianReal 0 1 (frontier E) = 0) :
    Tendsto (fun n => P.real (S n ⁻¹' E)) atTop (𝓝 ((gaussianReal 0 1).real E)) := by
  have key := ProbabilityMeasure.tendsto_measure_of_null_frontier_of_tendsto' h.tendsto
    (E := E) (by simpa using hfr)
  have key2 := (ENNReal.tendsto_toReal (by simp)).comp key
  simp only [Measure.map_id] at key2
  convert key2 using 2 with n
  · simp [Measure.real, Measure.map_apply_of_aemeasurable (h.forall_aemeasurable n) hE]
  · rfl

lemma clt_aux_normalized {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (μ σ : ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL2 : MemLp (X 0) 2 P)
    (hmean : ∫ ω, X 0 ω ∂P = μ)
    (hvar : variance (X 0) P = σ ^ 2)
    (hσ : 0 < σ) :
    TendstoInDistribution
      (fun (n : ℕ) ω ↦ (Real.sqrt n)⁻¹ * ∑ k ∈ Finset.range n, (fun ω => (X k ω - μ) / σ) ω)
      atTop id (fun _ ↦ P) (gaussianReal 0 1) := by
  have mX0 := (hident 0).aemeasurable_fst
  have intX0 : Integrable (X 0) P := hL2.integrable one_le_two
  refine tendstoInDistribution_inv_sqrt_mul_sum HasLaw.id ?_ ?_ ?_ ?_
  · show ∫ ω, (X 0 ω - μ) / σ ∂P = 0
    rw [integral_div, integral_sub intX0 (integrable_const _)]
    simp [hmean]
  · show ∫ ω, ((X 0 ω - μ) / σ) ^ 2 ∂P = 1
    simp only [div_pow]
    rw [integral_div, ← hmean, ← variance_eq_integral mX0, hvar]
    field_simp
  · exact hind.comp (fun _ x ↦ (x - μ) / σ) (fun _ => by fun_prop)
  · exact fun n ↦ (hident n).comp (u := fun x ↦ (x - μ) / σ) (by fun_prop)

lemma clt_aux_cdf_neg (z : ℝ) :
    cdf (gaussianReal 0 1) (-z) = 1 - cdf (gaussianReal 0 1) z := by
  have : NullSingletonClass (gaussianReal 0 1) :=
    nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [cdf_eq_real, cdf_eq_real]
  have hneg : gaussianReal 0 1 = (gaussianReal 0 1).map (fun x : ℝ ↦ -x) := by
    rw [gaussianReal_map_neg, neg_zero]
  conv_lhs => rw [hneg]
  rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
  have h1 : (fun x : ℝ ↦ -x) ⁻¹' Set.Iic (-z) = Set.Ici z := by
    ext x; simp
  rw [h1, ← measureReal_congr (Ioi_ae_eq_Ici' (measure_singleton z)), ← Set.compl_Iic,
    probReal_compl_eq_one_sub measurableSet_Iic]

lemma clt_aux_window_value (z : ℝ) (hz : 0 ≤ z) :
    (gaussianReal 0 1).real (Set.Icc (-z) z) = 2 * cdf (gaussianReal 0 1) z - 1 := by
  have : NullSingletonClass (gaussianReal 0 1) :=
    nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [← measureReal_congr (Ioc_ae_eq_Icc' (measure_singleton (-z)))]
  have hle : -z ≤ z := by linarith
  have hu := measureReal_union (μ := gaussianReal 0 1) (Set.Iic_disjoint_Ioc le_rfl)
    measurableSet_Ioc (s₁ := Set.Iic (-z)) (s₂ := Set.Ioc (-z) z)
  rw [Set.Iic_union_Ioc_eq_Iic hle, ← cdf_eq_real, ← cdf_eq_real, clt_aux_cdf_neg] at hu
  linarith

lemma clt_aux_integrable_exp {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (Y : Ω → ℝ) (hY : AEMeasurable Y P) (c : ℝ)
    (hbdd : ∀ᵐ ω ∂P, |Y ω| ≤ c) (s : ℝ) :
    Integrable (fun ω => Real.exp (s * Y ω)) P := by
  refine Integrable.of_bound (by fun_prop) (Real.exp (|s| * c)) ?_
  filter_upwards [hbdd] with ω hω
  rw [Real.norm_eq_abs, Real.abs_exp]
  refine Real.exp_le_exp.2 ?_
  calc s * Y ω ≤ |s * Y ω| := le_abs_self _
    _ = |s| * |Y ω| := abs_mul _ _
    _ ≤ |s| * c := mul_le_mul_of_nonneg_left hω (abs_nonneg _)

lemma clt_aux_taylor_mgf {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (Y : Ω → ℝ)
    (hint : ∀ s : ℝ, Integrable (fun ω => Real.exp (s * Y ω)) P)
    (hmean : ∫ ω, Y ω ∂P = 0) (hvar : ∫ ω, Y ω ^ 2 ∂P = 1) :
    (fun s => mgf Y P s - (1 + s ^ 2 / 2)) =o[𝓝 0] fun s => s ^ 2 := by
  have hset : integrableExpSet Y P = Set.univ := by
    ext s; simp [integrableExpSet, hint s]
  have h0 : (0 : ℝ) ∈ interior (integrableExpSet Y P) := by simp [hset]
  have han : AnalyticOnNhd ℝ (mgf Y P) Set.univ := by
    have := analyticOnNhd_mgf (X := Y) (μ := P)
    rwa [hset, interior_univ] at this
  have hcd : ContDiff ℝ 2 (mgf Y P) := han.contDiff
  have hT := taylor_isLittleO_univ hcd (x₀ := 0)
  have heval : ∀ s, taylorWithinEval (mgf Y P) 2 Set.univ 0 s = 1 + s ^ 2 / 2 := by
    intro s
    simp only [taylor_within_apply, iteratedDerivWithin_univ, iteratedDeriv_mgf_zero h0,
      Finset.sum_range_succ, Finset.sum_range_zero]
    simp [Pi.pow_apply, hmean, hvar]
    ring
  simp only [heval, sub_zero] at hT
  exact hT

/-- **The central limit theorem.** Let `X 0, X 1, X 2, …` be independent readings, all with
the same law as `X 0`, whose mean is `μ` and whose spread (standard deviation) is `σ`, finite
and positive. Write `Z n = (average of the first n readings − μ) / (σ / √n)` for the
standardised error. Then for every number `z`, the chance that `Z n ≤ z` tends, as `n` grows,
to `Φ(z)`, the standard bell's area to the left of `z`. -/
theorem central_limit_theorem {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (μ σ : ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL2 : MemLp (X 0) 2 P)
    (hmean : ∫ ω, X 0 ω ∂P = μ)
    (hvar : variance (X 0) P = σ ^ 2)
    (hσ : 0 < σ) (z : ℝ) :
    Tendsto
      (fun n : ℕ => P.real
        {ω | ((∑ i ∈ Finset.range n, X i ω) / n - μ) / (σ / Real.sqrt n) ≤ z})
      atTop (𝓝 (cdf (gaussianReal 0 1) z)) := by
  have h := clt_aux_tendsto_measure _ (clt_aux_normalized X μ σ hind hident hL2 hmean hvar hσ)
    (Set.Iic z) measurableSet_Iic ?_
  · rw [cdf_eq_real]
    convert h using 3 with n
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_preimage, Set.mem_Iic]
    rw [← clt_aux_identity _ μ σ n hσ, ← Finset.sum_div, Finset.sum_sub_distrib]
    simp
  · have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    exact measure_mono_null (frontier_Iic_subset z) (measure_singleton z)

/-- **The window rule.** Under the same hypotheses, for every count of spreads `z ≥ 0`, the
chance that the average of the first `n` readings lands within `z` of its own spreads
`σ / √n` of the mean `μ` tends to `2 Φ(z) − 1`, the standard bell's area within `z` of its
centre. -/
theorem window_rule {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (μ σ : ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL2 : MemLp (X 0) 2 P)
    (hmean : ∫ ω, X 0 ω ∂P = μ)
    (hvar : variance (X 0) P = σ ^ 2)
    (hσ : 0 < σ) (z : ℝ) (hz : 0 ≤ z) :
    Tendsto
      (fun n : ℕ => P.real
        {ω | |(∑ i ∈ Finset.range n, X i ω) / n - μ| ≤ z * (σ / Real.sqrt n)})
      atTop (𝓝 (2 * cdf (gaussianReal 0 1) z - 1)) := by
  have hle : -z ≤ z := by linarith
  have h := clt_aux_tendsto_measure _ (clt_aux_normalized X μ σ hind hident hL2 hmean hvar hσ)
    (Set.Icc (-z) z) measurableSet_Icc ?_
  · rw [← clt_aux_window_value z hz]
    refine h.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with n hn
    congr 1
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_preimage, Set.mem_Icc]
    rw [← Finset.sum_div, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_range,
      nsmul_eq_mul, clt_aux_identity _ μ σ n hσ]
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have hd : 0 < σ / Real.sqrt n := div_pos hσ (Real.sqrt_pos.2 hn')
    rw [← abs_le, abs_div, abs_of_pos hd, div_le_iff₀ hd]
  · have : NullSingletonClass (gaussianReal 0 1) :=
      nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    rw [frontier_Icc hle]
    exact (Set.toFinite _).measure_zero _

/-- **The generating function of the miss tends to the bell's (Step 3, Detailed proof).**
Let `Y 0, Y 1, Y 2, …` be independent standardised readings, all with the same law as `Y 0`,
bounded by a constant `c`, with mean 0 and variance 1. Then for every `t`, the moment
generating function of `(Y 0 + ⋯ + Y (n−1)) / √n` at `t` tends to `e^(t²/2)`, and
`e^(t²/2)` is exactly the moment generating function of the standard bell at `t`. -/
theorem mgf_of_standardised_sum_tends_to_bell {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (Y : ℕ → Ω → ℝ) (c : ℝ)
    (hind : iIndepFun Y P)
    (hident : ∀ i, IdentDistrib (Y i) (Y 0) P P)
    (hbdd : ∀ᵐ ω ∂P, |Y 0 ω| ≤ c)
    (hmean : ∫ ω, Y 0 ω ∂P = 0)
    (hvar : ∫ ω, Y 0 ω ^ 2 ∂P = 1) (t : ℝ) :
    Tendsto
      (fun n : ℕ => mgf (fun ω => (∑ i ∈ Finset.range n, Y i ω) / Real.sqrt n) P t)
      atTop (𝓝 (Real.exp (t ^ 2 / 2))) ∧
      mgf id (gaussianReal 0 1) t = Real.exp (t ^ 2 / 2) := by
  refine ⟨?_, ?_⟩
  · have hmeas : ∀ i, AEMeasurable (Y i) P := fun i => (hident i).aemeasurable_fst
    set f := mgf (Y 0) P with hf
    have key : ∀ n : ℕ, 0 < n →
        mgf (fun ω => (∑ i ∈ Finset.range n, Y i ω) / Real.sqrt n) P t
          = f (t / Real.sqrt n) ^ n := by
      intro n hn
      have h1 : mgf (fun ω => (∑ i ∈ Finset.range n, Y i ω) / Real.sqrt n) P t
          = mgf (∑ i ∈ Finset.range n, Y i) P (t / Real.sqrt n) := by
        simp only [mgf]
        congr 1
        ext ω
        rw [Finset.sum_apply]
        congr 1
        ring
      rw [h1, mgf_sum_of_identDistrib₀ hmeas hind
        (fun i _ j _ => (hident i).trans (hident j).symm) (Finset.mem_range.2 hn),
        Finset.card_range]
    have hT := clt_aux_taylor_mgf (Y 0)
      (clt_aux_integrable_exp (Y 0) (hmeas 0) c hbdd) hmean hvar
    have hs : Tendsto (fun n : ℕ => t / Real.sqrt n) atTop (𝓝 0) := by
      have : Tendsto (fun n : ℕ => t * (Real.sqrt n)⁻¹) atTop (𝓝 (t * 0)) :=
        tendsto_const_nhds.mul (tendsto_inv_atTop_zero.comp <| Real.tendsto_sqrt_atTop.comp
          tendsto_natCast_atTop_atTop)
      simpa [div_eq_mul_inv] using this
    have hc := (hT.comp_tendsto hs).mul_isBigO (Asymptotics.isBigO_refl (fun n : ℕ => (n : ℝ)) atTop)
    have hO : (fun n : ℕ => (fun s : ℝ => s ^ 2) (t / Real.sqrt n) * (n : ℝ))
        =O[atTop] (fun _ => (1 : ℝ)) := by
      refine (Asymptotics.isBigO_const_const (t ^ 2) one_ne_zero atTop).congr' ?_ (by rfl)
      filter_upwards [eventually_gt_atTop 0] with n hn
      have hn' : (0 : ℝ) < n := by exact_mod_cast hn
      simp only [div_pow, Real.sq_sqrt hn'.le]
      field_simp
    have hlim := (Asymptotics.isLittleO_one_iff ℝ).1 (hc.trans_isBigO hO)
    have hg : Tendsto (fun n : ℕ => (n : ℝ) * (f (t / Real.sqrt n) - 1)) atTop (𝓝 (t ^ 2 / 2)) := by
      have := hlim.add_const (t ^ 2 / 2)
      rw [zero_add] at this
      refine this.congr' ?_
      filter_upwards [eventually_gt_atTop 0] with n hn
      have hn' : (0 : ℝ) < n := by exact_mod_cast hn
      simp only [Function.comp_apply, div_pow, Real.sq_sqrt hn'.le]
      field_simp
      ring
    refine (Real.tendsto_one_add_pow_exp_of_tendsto hg).congr' ?_
    filter_upwards [eventually_gt_atTop 0] with n hn
    rw [key n hn]
    ring
  · rw [mgf_id_gaussianReal]
    simp

-- One fair die: mean (1 + 2 + … + 6)/6 = 7/2, mean square (1 + 4 + … + 36)/6 = 91/6.
example : ((1 + 2 + 3 + 4 + 5 + 6 : ℚ)) / 6 = 7 / 2 := by norm_num
example : ((1 + 4 + 9 + 16 + 25 + 36 : ℚ)) / 6 = 91 / 6 := by norm_num
-- Its variance: σ² = 91/6 − (7/2)² = 35/12.
example : (91 / 6 : ℚ) - (7 / 2) ^ 2 = 35 / 12 := by norm_num
-- The sum of 1,000 rolls: mean 1000 × 7/2 = 3,500 and variance 1000 × 35/12 = 8750/3 (2,916.67).
example : (1000 : ℚ) * (7 / 2) = 3500 := by norm_num
example : (1000 : ℚ) * (35 / 12) = 8750 / 3 := by norm_num
-- Window 0.1 at 1,000 rolls, in spreads: z² = (1/10)² × 1000 / (35/12) = 24/7, so z = √(24/7).
example : (1 / 10 : ℚ) ^ 2 * 1000 / (35 / 12) = 24 / 7 := by norm_num
-- Window 0.05 with 4,000 rolls gives the same z² as window 0.1 with 1,000 rolls.
example : (1 / 20 : ℚ) ^ 2 * 4000 = (1 / 10) ^ 2 * 1000 := by norm_num
-- Four times the rolls quarters the average's variance, so halves its spread.
example : (35 / 12 : ℚ) / 4000 = (1 / 2) ^ 2 * ((35 / 12) / 1000) := by norm_num
-- The lopsided die: a one with chance 1/2, each other face 1/10. Chances add to 1.
example : (1 / 2 : ℚ) + 5 * (1 / 10) = 1 := by norm_num
-- Its mean is 5/2, its mean square 19/2, its variance 13/4 (spread √(13/4) = 1.802776).
example : (1 / 2 : ℚ) * 1 + (1 / 10) * (2 + 3 + 4 + 5 + 6) = 5 / 2 := by norm_num
example : (1 / 2 : ℚ) * 1 + (1 / 10) * (4 + 9 + 16 + 25 + 36) = 19 / 2 := by norm_num
example : (19 / 2 : ℚ) - (5 / 2) ^ 2 = 13 / 4 := by norm_num
-- Ten rolls have 6^10 equally likely outcomes.
example : (6 : ℕ) ^ 10 = 60466176 := by norm_num

#print axioms central_limit_theorem
#print axioms window_rule
#print axioms mgf_of_standardised_sum_tends_to_bell
#print axioms clt_aux_identity
#print axioms clt_aux_tendsto_measure
#print axioms clt_aux_normalized
#print axioms clt_aux_cdf_neg
#print axioms clt_aux_window_value
#print axioms clt_aux_integrable_exp
#print axioms clt_aux_taylor_mgf
