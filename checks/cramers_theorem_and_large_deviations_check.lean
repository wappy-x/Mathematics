-- Cramer's theorem: for independent copies of one law with a moment generating function finite everywhere, the chance that the average of n copies reaches a level a at or above the mean is at most e^(-n I(a)), where I(a) is the supremum over t of t a - ln M(t), and (1/n) ln of that chance tends to -I(a) when a is below the largest value a copy can take.
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.Moments.MGFAnalytic
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.Analysis.SpecialFunctions.Log.ERealExp

open MeasureTheory ProbabilityTheory Filter Topology

lemma cramer_mgf_sum {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (X i))
    (hindep : iIndepFun X μ) (hident : ∀ i, IdentDistrib (X i) (X 0) μ μ)
    (hmgf : ∀ t : ℝ, Integrable (fun ω => Real.exp (t * X 0 ω)) μ) (n : ℕ) (u : ℝ) :
    mgf (∑ i ∈ Finset.range n, X i) μ u = Real.exp (n * cgf (X 0) μ u) := by
  rw [hindep.mgf_sum hmeas, Finset.prod_congr rfl
    (fun i _ => mgf_congr_of_identDistrib (X i) (X 0) (hident i) u), Finset.prod_const,
    Finset.card_range, Real.exp_nat_mul, exp_cgf (hmgf u)]

lemma cramer_integrable_sum {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (X i))
    (hindep : iIndepFun X μ) (hident : ∀ i, IdentDistrib (X i) (X 0) μ μ)
    (hmgf : ∀ t : ℝ, Integrable (fun ω => Real.exp (t * X 0 ω)) μ) (n : ℕ) (u : ℝ) :
    Integrable (fun ω => Real.exp (u * (∑ i ∈ Finset.range n, X i) ω)) μ := by
  refine hindep.integrable_exp_mul_sum hmeas (fun i _ => ?_)
  have h := (hident i).comp (measurable_const_mul u).exp
  exact h.integrable_iff.2 (hmgf u)

lemma cramer_jensen {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (Y : Ω → ℝ)
    (hmgf : ∀ t : ℝ, Integrable (fun ω => Real.exp (t * Y ω)) μ) (u : ℝ) :
    u * ∫ ω, Y ω ∂μ ≤ cgf Y μ u := by
  have hY : Integrable Y μ := by
    have h0 : (0 : ℝ) ∈ interior (integrableExpSet Y μ) := by
      have : integrableExpSet Y μ = Set.univ := Set.eq_univ_of_forall hmgf
      rw [this, interior_univ]; exact Set.mem_univ _
    exact integrable_of_mem_interior_integrableExpSet h0
  set m := ∫ ω, Y ω ∂μ
  have hpt : ∀ ω, Real.exp (u * m) + Real.exp (u * m) * (u * (Y ω - m)) ≤
      Real.exp (u * Y ω) := by
    intro ω
    have h1 := Real.add_one_le_exp (u * (Y ω - m))
    have h2 : Real.exp (u * Y ω) = Real.exp (u * m) * Real.exp (u * (Y ω - m)) := by
      rw [← Real.exp_add]; ring_nf
    rw [h2]
    have := Real.exp_pos (u * m)
    nlinarith
  have hint : ∫ ω, (Real.exp (u * m) + Real.exp (u * m) * (u * (Y ω - m))) ∂μ =
      Real.exp (u * m) := by
    have hi1 : Integrable (fun ω => Y ω - m) μ := hY.sub (integrable_const m)
    have hi2 : Integrable (fun ω => Real.exp (u * m) * (u * (Y ω - m))) μ :=
      (hi1.const_mul u).const_mul _
    rw [integral_add (integrable_const _) hi2, integral_const_mul, integral_const_mul,
      integral_sub hY (integrable_const m)]
    simp [m]
  have hle : Real.exp (u * m) ≤ mgf Y μ u := by
    rw [← hint]
    have hi2 : Integrable (fun ω => Real.exp (u * m) * (u * (Y ω - m))) μ :=
      ((hY.sub (integrable_const m)).const_mul u).const_mul _
    exact integral_mono ((integrable_const _).add hi2) (hmgf u) hpt
  rw [cgf, Real.le_log_iff_exp_le (mgf_pos (hmgf u))]
  exact hle

lemma cramer_upper {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (X i))
    (hindep : iIndepFun X μ) (hident : ∀ i, IdentDistrib (X i) (X 0) μ μ)
    (hmgf : ∀ t : ℝ, Integrable (fun ω => Real.exp (t * X 0 ω)) μ)
    (a : ℝ) (hmean : ∫ ω, X 0 ω ∂μ ≤ a) (n : ℕ) (t : ℝ) :
    μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n} ≤
      Real.exp (-(n * (t * a - cgf (X 0) μ t))) := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn; simp
  rcases le_or_gt 0 t with ht | ht
  · have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have hset : {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n} =
        {ω | n * a ≤ (∑ i ∈ Finset.range n, X i) ω} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Finset.sum_apply, le_div_iff₀ hn', mul_comm]
    rw [hset]
    refine (measure_ge_le_exp_mul_mgf _ ht
      (cramer_integrable_sum X hmeas hindep hident hmgf n t)).trans (le_of_eq ?_)
    rw [cramer_mgf_sum X hmeas hindep hident hmgf, ← Real.exp_add]
    ring_nf
  · have hj := cramer_jensen (X 0) hmgf t
    have : t * a - cgf (X 0) μ t ≤ 0 := by nlinarith
    refine measureReal_le_one.trans ?_
    apply Real.one_le_exp
    have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    nlinarith
lemma cramer_exists_step {f : ℝ → ℝ} {f' t a b : ℝ} (hf : HasDerivAt f f' t) (ha : a < f')
    (hb : f' < b) : ∃ s > 0, f (t + s) - s * b < f t ∧ f (t - s) + s * a < f t := by
  have h := hasDerivAt_iff_tendsto_slope.1 hf
  have h1 : ∀ᶠ y in 𝓝[≠] t, a < slope f t y ∧ slope f t y < b :=
    (h.eventually (lt_mem_nhds ha)).and (h.eventually (gt_mem_nhds hb))
  rw [eventually_nhdsWithin_iff, Metric.eventually_nhds_iff] at h1
  obtain ⟨ε, hε, hball⟩ := h1
  have hε2 : 0 < ε / 2 := by positivity
  refine ⟨ε / 2, hε2, ?_, ?_⟩
  · have hy := (hball (y := t + ε / 2) (by rw [Real.dist_eq]; rw [abs_of_pos (by linarith)]; linarith)
      (Set.mem_compl_singleton_iff.2 (by linarith))).2
    rw [slope_def_field, show t + ε / 2 - t = ε / 2 by ring, div_lt_iff₀ hε2] at hy
    linarith
  · have hy := (hball (y := t - ε / 2)
      (by rw [Real.dist_eq, show t - ε / 2 - t = -(ε / 2) by ring, abs_neg, abs_of_pos hε2]; linarith)
      (Set.mem_compl_singleton_iff.2 (by linarith))).1
    rw [slope_def_field, show t - ε / 2 - t = -(ε / 2) by ring, div_neg, lt_neg,
      div_lt_iff₀ hε2] at hy
    linarith

lemma cramer_lower_core {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (X i))
    (hindep : iIndepFun X μ) (hident : ∀ i, IdentDistrib (X i) (X 0) μ μ)
    (hmgf : ∀ t : ℝ, Integrable (fun ω => Real.exp (t * X 0 ω)) μ)
    (a b t s : ℝ) (ht : 0 ≤ t) (hs : 0 < s)
    (h1 : cgf (X 0) μ (t + s) - s * b < cgf (X 0) μ t)
    (h2 : cgf (X 0) μ (t - s) + s * a < cgf (X 0) μ t) (δ : ℝ) (hδ : 0 < δ) :
    ∀ᶠ n : ℕ in atTop, 0 < μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n} ∧
      -(t * b - cgf (X 0) μ t) - δ ≤
        Real.log (μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n}) / n := by
  set Λ := cgf (X 0) μ with hΛ
  set c1 := Λ (t + s) - s * b - Λ t with hc1
  set c2 := Λ (t - s) + s * a - Λ t with hc2
  have hr1 : Tendsto (fun n : ℕ => Real.exp c1 ^ n) atTop (𝓝 0) :=
    tendsto_pow_atTop_nhds_zero_of_lt_one (Real.exp_pos _).le (Real.exp_lt_one_iff.2 (by linarith))
  have hr2 : Tendsto (fun n : ℕ => Real.exp c2 ^ n) atTop (𝓝 0) :=
    tendsto_pow_atTop_nhds_zero_of_lt_one (Real.exp_pos _).le (Real.exp_lt_one_iff.2 (by linarith))
  have hlog : Tendsto (fun n : ℕ => Real.log (1 / 2) / (n : ℝ)) atTop (𝓝 0) :=
    tendsto_const_div_atTop_nhds_zero_nat _
  filter_upwards [hr1.eventually (gt_mem_nhds (by norm_num : (0 : ℝ) < 1 / 4)),
    hr2.eventually (gt_mem_nhds (by norm_num : (0 : ℝ) < 1 / 4)),
    hlog.eventually (lt_mem_nhds (neg_lt_zero.2 hδ)), eventually_ge_atTop 1]
    with n hn1 hn2 hn3 hn4
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn4
  set A := {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n} with hAdef
  have hA : MeasurableSet A :=
    measurableSet_le measurable_const ((Finset.measurable_sum _ fun i _ => hmeas i).div_const _)
  set Sf := ∑ i ∈ Finset.range n, X i with hSf
  have hSapp : ∀ ω, Sf ω = ∑ i ∈ Finset.range n, X i ω := fun ω => by
    simp [hSf, Finset.sum_apply]
  have hint : ∀ u, Integrable (fun ω => Real.exp (u * Sf ω)) μ :=
    fun u => cramer_integrable_sum X hmeas hindep hident hmgf n u
  have hmgfS : ∀ u, ∫ ω, Real.exp (u * Sf ω) ∂μ = Real.exp (n * Λ u) :=
    fun u => cramer_mgf_sum X hmeas hindep hident hmgf n u
  have hpt : ∀ ω, Real.exp (t * Sf ω) ≤
      Real.exp (t * n * b) * A.indicator 1 ω + Real.exp ((t + s) * Sf ω) * Real.exp (-(s * n * b))
        + Real.exp ((t - s) * Sf ω) * Real.exp (s * n * a) := by
    intro ω
    have e1 : 0 ≤ Real.exp (t * n * b) * A.indicator 1 ω := by
      apply mul_nonneg (Real.exp_pos _).le
      exact Set.indicator_nonneg (fun _ _ => zero_le_one) _
    have e2 := mul_pos (Real.exp_pos ((t + s) * Sf ω)) (Real.exp_pos (-(s * n * b)))
    have e3 := mul_pos (Real.exp_pos ((t - s) * Sf ω)) (Real.exp_pos (s * n * a))
    rcases le_or_gt (Sf ω) (n * a) with hx | hx
    · have : Real.exp (t * Sf ω) ≤ Real.exp ((t - s) * Sf ω) * Real.exp (s * n * a) := by
        rw [← Real.exp_add]; apply Real.exp_le_exp.2; nlinarith
      linarith
    rcases le_or_gt (n * b) (Sf ω) with hy | hy
    · have : Real.exp (t * Sf ω) ≤ Real.exp ((t + s) * Sf ω) * Real.exp (-(s * n * b)) := by
        rw [← Real.exp_add]; apply Real.exp_le_exp.2; nlinarith
      linarith
    · have hωA : ω ∈ A := by
        show a ≤ (∑ i ∈ Finset.range n, X i ω) / n
        rw [← hSapp, le_div_iff₀ hn']; linarith
      have : Real.exp (t * Sf ω) ≤ Real.exp (t * n * b) * A.indicator 1 ω := by
        rw [Set.indicator_of_mem hωA, Pi.one_apply, mul_one]
        apply Real.exp_le_exp.2
        have := mul_le_mul_of_nonneg_left hy.le ht
        linarith
      linarith
  have hiA : Integrable (fun ω => Real.exp (t * n * b) * A.indicator 1 ω) μ :=
    ((integrable_const (1 : ℝ)).indicator hA).const_mul _
  have hi2 : Integrable (fun ω => Real.exp ((t + s) * Sf ω) * Real.exp (-(s * n * b))) μ :=
    (hint _).mul_const _
  have hi3 : Integrable (fun ω => Real.exp ((t - s) * Sf ω) * Real.exp (s * n * a)) μ :=
    (hint _).mul_const _
  have hi12 : Integrable (fun ω => Real.exp (t * n * b) * A.indicator 1 ω +
      Real.exp ((t + s) * Sf ω) * Real.exp (-(s * n * b))) μ := hiA.add hi2
  have hi123 : Integrable (fun ω => Real.exp (t * n * b) * A.indicator 1 ω +
      Real.exp ((t + s) * Sf ω) * Real.exp (-(s * n * b)) +
      Real.exp ((t - s) * Sf ω) * Real.exp (s * n * a)) μ := hi12.add hi3
  have hmono := integral_mono (hint t) hi123 hpt
  rw [integral_add hi12 hi3, integral_add hiA hi2, integral_const_mul,
    integral_mul_const, integral_mul_const, integral_indicator_one hA, hmgfS, hmgfS,
    hmgfS] at hmono
  set p := μ.real A
  set G := Real.exp (n * (Λ t - t * b))
  set F := Real.exp (t * n * b)
  have hE : Real.exp (n * Λ t) = G * F := by
    simp only [G, F]; rw [← Real.exp_add]; ring_nf
  have hE1 : Real.exp (n * Λ (t + s)) * Real.exp (-(s * n * b)) = G * F * Real.exp c1 ^ n := by
    rw [← hE, ← Real.exp_nat_mul, ← Real.exp_add, ← Real.exp_add]; congr 1; rw [hc1]; ring
  have hE2 : Real.exp (n * Λ (t - s)) * Real.exp (s * n * a) = G * F * Real.exp c2 ^ n := by
    rw [← hE, ← Real.exp_nat_mul, ← Real.exp_add, ← Real.exp_add]; congr 1; rw [hc2]; ring
  rw [hE, hE1, hE2] at hmono
  have hG : 0 < G := Real.exp_pos _
  have hF : 0 < F := Real.exp_pos _
  have hGF : 0 < G * F := mul_pos hG hF
  have hkey : F * (1 / 2 * G) ≤ F * p := by
    nlinarith [mul_lt_mul_of_pos_left hn1 hGF, mul_lt_mul_of_pos_left hn2 hGF]
  have hp : 1 / 2 * G ≤ p := le_of_mul_le_mul_left hkey hF
  have hp0 : 0 < p := lt_of_lt_of_le (by positivity) hp
  refine ⟨hp0, ?_⟩
  have hl := Real.log_le_log (by positivity) hp
  rw [Real.log_mul (by norm_num) hG.ne', Real.log_exp] at hl
  rw [lt_div_iff₀ hn'] at hn3
  rw [le_div_iff₀ hn']
  nlinarith

/-- The rate function of the card: the Legendre transform `I(a) = sup over t of (t a - Λ(t))`
of the log-moment function `Λ = cgf X μ`, taken in the extended reals so that an unbounded
supremum is `+∞` rather than a junk value. -/
noncomputable def rateFunction {Ω : Type*} [MeasurableSpace Ω] (X : Ω → ℝ) (μ : Measure Ω)
    (a : ℝ) : EReal :=
  ⨆ t : ℝ, ((t * a - cgf X μ t : ℝ) : EReal)

lemma cramer_rate_eq_coe {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (Y : Ω → ℝ) (a C : ℝ) (hC : ∀ t, t * a - cgf Y μ t ≤ C) :
    ∃ r : ℝ, rateFunction Y μ a = (r : EReal) ∧ 0 ≤ r ∧ (∀ t, t * a - cgf Y μ t ≤ r) ∧
      ∀ c : ℝ, (∀ t, t * a - cgf Y μ t ≤ c) → r ≤ c := by
  have hle : ∀ c : ℝ, (∀ t, t * a - cgf Y μ t ≤ c) → rateFunction Y μ a ≤ (c : EReal) :=
    fun c hc => iSup_le fun t => EReal.coe_le_coe_iff.2 (hc t)
  have hge : ∀ t, ((t * a - cgf Y μ t : ℝ) : EReal) ≤ rateFunction Y μ a :=
    fun t => le_iSup (fun t : ℝ => ((t * a - cgf Y μ t : ℝ) : EReal)) t
  have h0 : (0 : EReal) ≤ rateFunction Y μ a := by
    have := hge 0
    simpa [cgf_zero] using this
  have htop : rateFunction Y μ a ≠ ⊤ := ne_top_of_le_ne_top (EReal.coe_ne_top C) (hle C hC)
  have hbot : rateFunction Y μ a ≠ ⊥ := ne_bot_of_le_ne_bot (EReal.zero_ne_bot) h0
  refine ⟨(rateFunction Y μ a).toReal, (EReal.coe_toReal htop hbot).symm, ?_, ?_, ?_⟩
  · rw [← EReal.coe_le_coe_iff, EReal.coe_toReal htop hbot]; simpa using h0
  · intro t; rw [← EReal.coe_le_coe_iff, EReal.coe_toReal htop hbot]; exact hge t
  · intro c hc; rw [← EReal.coe_le_coe_iff, EReal.coe_toReal htop hbot]; exact hle c hc

/-- Cramer's theorem on a half-line. Let `X 0, X 1, ...` be independent random variables with
one common law whose moment generating function `M(t) = E e^(t X)` is finite for every real `t`.
For a fixed level `a` at or above the mean and below the largest value a copy can take
(that is, a copy exceeds `a` with positive chance), the logarithm of the chance that the average
of the first `n` copies is at least `a`, divided by `n`, tends to `-I(a)`. -/
theorem cramer_log_chance_tendsto_neg_rate {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (X i))
    (hindep : iIndepFun X μ) (hident : ∀ i, IdentDistrib (X i) (X 0) μ μ)
    (hmgf : ∀ t : ℝ, Integrable (fun ω => Real.exp (t * X 0 ω)) μ)
    (a : ℝ) (hmean : ∫ ω, X 0 ω ∂μ ≤ a) (hreach : 0 < μ {ω | a < X 0 ω}) :
    Tendsto
      (fun n : ℕ =>
        ((Real.log (μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n}) / n : ℝ) : EReal))
      atTop (𝓝 (-rateFunction (X 0) μ a)) := by
  set Λ := cgf (X 0) μ with hΛ
  set m := ∫ ω, X 0 ω ∂μ with hm
  have hint : ∀ v, v ∈ interior (integrableExpSet (X 0) μ) := by
    have : integrableExpSet (X 0) μ = Set.univ := Set.eq_univ_of_forall hmgf
    intro v; rw [this, interior_univ]; exact Set.mem_univ _
  have hdiff : ∀ v, HasDerivAt Λ (deriv Λ v) v :=
    fun v => (analyticAt_cgf (hint v)).differentiableAt.hasDerivAt
  have hcont : Continuous Λ := continuous_iff_continuousAt.2 fun v => (hdiff v).continuousAt
  have hcont' : Continuous (deriv Λ) :=
    continuous_iff_continuousAt.2 fun v => (analyticAt_cgf (hint v)).deriv.continuousAt
  have hd0 : deriv Λ 0 = m := by rw [deriv_cgf_zero (hint 0)]; simp [hm]
  have hpos : ∃ b' > a, 0 < μ.real {ω | b' ≤ X 0 ω} := by
    by_contra hcon
    push Not at hcon
    have hU : {ω | a < X 0 ω} = ⋃ k : ℕ, {ω | a + 1 / ((k : ℝ) + 1) ≤ X 0 ω} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_iUnion]
      constructor
      · intro h
        obtain ⟨k, hk⟩ := exists_nat_one_div_lt (sub_pos.2 h)
        exact ⟨k, by linarith⟩
      · rintro ⟨k, hk⟩
        have : (0 : ℝ) < 1 / ((k : ℝ) + 1) := by positivity
        linarith
    have hzero : μ {ω | a < X 0 ω} = 0 := by
      rw [hU]
      apply measure_iUnion_null
      intro k
      have hk : (0 : ℝ) < 1 / ((k : ℝ) + 1) := by positivity
      have h := hcon (a + 1 / ((k : ℝ) + 1)) (by linarith)
      exact (measureReal_eq_zero_iff).1 (le_antisymm h measureReal_nonneg)
    exact hreach.ne' hzero
  obtain ⟨b', hb', hq⟩ := hpos
  set q := μ.real {ω | b' ≤ X 0 ω} with hqdef
  have hlow : ∀ t, 0 ≤ t → Real.log q + t * b' ≤ Λ t := by
    intro t ht
    have h := mul_meas_ge_le_integral_of_nonneg
      (ae_of_all _ fun ω => (Real.exp_pos (t * X 0 ω)).le) (hmgf t) (Real.exp (t * b'))
    have hsub : q ≤ μ.real {ω | Real.exp (t * b') ≤ Real.exp (t * X 0 ω)} := by
      refine measureReal_mono (fun ω hω => ?_) (measure_ne_top _ _)
      simp only [Set.mem_ofPred_eq] at hω ⊢
      exact Real.exp_le_exp.2 (mul_le_mul_of_nonneg_left hω ht)
    have hm2 : q * Real.exp (t * b') ≤ mgf (X 0) μ t := by
      rw [mul_comm]
      exact le_trans (mul_le_mul_of_nonneg_left hsub (Real.exp_pos _).le) h
    rw [hΛ, cgf, ← Real.log_exp (t * b'), ← Real.log_mul hq.ne' (Real.exp_pos _).ne']
    exact Real.log_le_log (mul_pos hq (Real.exp_pos _)) hm2
  have hjen : ∀ t, t * m ≤ Λ t := cramer_jensen (X 0) hmgf
  have hC : ∀ t, t * a - Λ t ≤ max 0 (-Real.log q) := by
    intro t
    rcases le_or_gt 0 t with ht | ht
    · have h1 := hlow t ht
      have h2 : t * a ≤ t * b' := mul_le_mul_of_nonneg_left hb'.le ht
      exact le_max_of_le_right (by linarith)
    · have h1 := hjen t
      have h2 : t * a ≤ t * m := by nlinarith
      exact le_max_of_le_left (by linarith)
  obtain ⟨r, hr, hr0, hrle, hrmin⟩ := cramer_rate_eq_coe (X 0) a _ hC
  have hba : 0 < b' - a := sub_pos.2 hb'
  set T := (|Real.log q| + 1) / (b' - a) with hTdef
  have hT : 0 < T := div_pos (by positivity) hba
  have hΛT : T * a < Λ T := by
    have h1 := hlow T hT.le
    have h2 : T * (b' - a) = |Real.log q| + 1 := div_mul_cancel₀ _ hba.ne'
    have h3 := neg_abs_le (Real.log q)
    nlinarith
  obtain ⟨ξ, hξ, hξd⟩ := exists_deriv_eq_slope Λ hT hcont.continuousOn
    (fun x _ => (hdiff x).differentiableAt.differentiableWithinAt)
  have hξa : a < deriv Λ ξ := by
    rw [hξd, hΛ, cgf_zero, sub_zero, sub_zero, lt_div_iff₀ hT]
    linarith
  have hlower : ∀ η > 0, ∀ᶠ n : ℕ in atTop,
      0 < μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n} ∧
      -r - η ≤ Real.log (μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n}) / n := by
    intro η hη
    have hξ0 : 0 < ξ := hξ.1
    set ε := min (deriv Λ ξ - a) (η / (2 * ξ)) with hεdef
    have hε : 0 < ε := lt_min (sub_pos.2 hξa) (by positivity)
    have hεD : ε ≤ deriv Λ ξ - a := min_le_left _ _
    have hεξ : ξ * ε ≤ η / 2 := by
      have := min_le_right (deriv Λ ξ - a) (η / (2 * ξ))
      calc ξ * ε ≤ ξ * (η / (2 * ξ)) := mul_le_mul_of_nonneg_left this hξ0.le
        _ = η / 2 := by field_simp
    obtain ⟨t, ht, htd⟩ := intermediate_value_Icc hξ0.le hcont'.continuousOn
      ⟨(by rw [hd0]; linarith : deriv Λ 0 ≤ a + ε / 2), (by linarith : a + ε / 2 ≤ deriv Λ ξ)⟩
    obtain ⟨s, hs, h1, h2⟩ := cramer_exists_step (hdiff t)
      (by rw [htd]; linarith : a < deriv Λ t) (by rw [htd]; linarith : deriv Λ t < a + ε)
    filter_upwards [cramer_lower_core X hmeas hindep hident hmgf a (a + ε) t s ht.1 hs h1 h2
      (η / 2) (by positivity)] with n hn
    refine ⟨hn.1, ?_⟩
    have e1 := hrle t
    have e2 : t * ε ≤ ξ * ε := mul_le_mul_of_nonneg_right ht.2 hε.le
    have e3 := hn.2
    have e4 : t * (a + ε) = t * a + t * ε := by ring
    linarith
  have hupper : ∀ n : ℕ, 0 < μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n} → 1 ≤ n →
      Real.log (μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n}) / n ≤ -r := by
    intro n hp hn
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have hb : ∀ t, t * a - Λ t ≤
        -Real.log (μ.real {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n}) / n := by
      intro t
      have h1 := cramer_upper X hmeas hindep hident hmgf a hmean n t
      rw [← Real.log_le_iff_le_exp hp] at h1
      rw [le_div_iff₀ hn']
      linarith
    have h2 := hrmin _ hb
    rw [le_div_iff₀ hn'] at h2
    rw [div_le_iff₀ hn']
    linarith
  rw [hr, ← EReal.coe_neg, EReal.tendsto_coe, tendsto_order]
  refine ⟨fun c hc => ?_, fun c hc => ?_⟩
  · filter_upwards [hlower ((-r - c) / 2) (by linarith)] with n hn
    linarith [hn.2]
  · filter_upwards [hlower 1 one_pos, eventually_ge_atTop 1] with n hn hn1
    linarith [hupper n hn.1 hn1]

/-- The upper bound, for every `n` (Chernoff's bound at the best dial). For independent copies
of one law with a moment generating function finite everywhere, and a level `a` at or above the
mean, the chance that the average of the first `n` copies is at least `a` is at most
`e^(-n I(a))`. -/
theorem chance_average_ge_le_exp_neg_rate {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (X i))
    (hindep : iIndepFun X μ) (hident : ∀ i, IdentDistrib (X i) (X 0) μ μ)
    (hmgf : ∀ t : ℝ, Integrable (fun ω => Real.exp (t * X 0 ω)) μ)
    (a : ℝ) (hmean : ∫ ω, X 0 ω ∂μ ≤ a) (n : ℕ) :
    μ {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n} ≤
      EReal.exp (-((n : EReal) * rateFunction (X 0) μ a)) := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn; simpa using prob_le_one
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  set S := {ω | a ≤ (∑ i ∈ Finset.range n, X i ω) / n}
  have hμ : μ S = ENNReal.ofReal (μ.real S) := (ofReal_measureReal).symm
  rcases (measureReal_nonneg (μ := μ) (s := S)).eq_or_lt with hc | hc
  · rw [hμ, ← hc]; simp
  have hbound : ∀ t, t * a - cgf (X 0) μ t ≤ -Real.log (μ.real S) / n := by
    intro t
    have h1 := cramer_upper X hmeas hindep hident hmgf a hmean n t
    rw [← Real.log_le_iff_le_exp hc] at h1
    rw [le_div_iff₀ hn']
    linarith
  obtain ⟨r, hr, -, -, hrle⟩ := cramer_rate_eq_coe (X 0) a _ hbound
  have hr' := hrle _ hbound
  rw [hr, hμ, show ((n : EReal)) = ((n : ℝ) : EReal) by simp, ← EReal.coe_mul,
    ← EReal.coe_neg, EReal.exp_coe]
  apply ENNReal.ofReal_le_ofReal
  rw [← Real.log_le_iff_le_exp hc]
  rw [le_div_iff₀ hn'] at hr'
  linarith

/-- For a coin landing heads (value 1) with chance `p` and tails (value 0) otherwise, the rate
is a divergence: the largest value of `t a - ln(1 - p + p e^t)` over all dials `t` equals the
Kullback-Leibler divergence `a ln(a/p) + (1 - a) ln((1 - a)/(1 - p))` of a coin landing heads
with chance `a` from the given coin, for every level `a` strictly between 0 and 1. -/
theorem coin_rate_eq_kl_divergence (p a : ℝ) (hp0 : 0 < p) (hp1 : p < 1)
    (ha0 : 0 < a) (ha1 : a < 1) :
    (⨆ t : ℝ, (t * a - Real.log (1 - p + p * Real.exp t))) =
      a * Real.log (a / p) + (1 - a) * Real.log ((1 - a) / (1 - p)) := by
  have hq : 0 < 1 - p := by linarith
  have hb : 0 < 1 - a := by linarith
  have key : ∀ t : ℝ, t * a - Real.log (1 - p + p * Real.exp t) ≤
      a * Real.log (a / p) + (1 - a) * Real.log ((1 - a) / (1 - p)) := by
    intro t
    have hx : 0 < p * Real.exp t / a := by positivity
    have hy : 0 < (1 - p) / (1 - a) := by positivity
    have hc := (strictConcaveOn_log_Ioi.concaveOn).2 (Set.mem_Ioi.2 hx) (Set.mem_Ioi.2 hy)
      ha0.le hb.le (by ring)
    have hsum : a • (p * Real.exp t / a) + (1 - a) • ((1 - p) / (1 - a)) =
        1 - p + p * Real.exp t := by
      simp only [smul_eq_mul]; field_simp; ring
    rw [hsum] at hc
    simp only [smul_eq_mul] at hc
    rw [Real.log_div (by positivity) ha0.ne', Real.log_mul hp0.ne' (Real.exp_pos t).ne',
      Real.log_exp, Real.log_div hq.ne' hb.ne'] at hc
    rw [Real.log_div ha0.ne' hp0.ne', Real.log_div hb.ne' hq.ne']
    nlinarith
  apply le_antisymm (ciSup_le key)
  have hbdd : BddAbove (Set.range fun t : ℝ => t * a - Real.log (1 - p + p * Real.exp t)) :=
    ⟨_, Set.forall_mem_range.2 key⟩
  refine le_trans (le_of_eq ?_) (le_ciSup hbdd (Real.log (a * (1 - p) / (p * (1 - a)))))
  have he : Real.exp (Real.log (a * (1 - p) / (p * (1 - a)))) = a * (1 - p) / (p * (1 - a)) :=
    Real.exp_log (by positivity)
  have hq' : 1 - p + p * (a * (1 - p) / (p * (1 - a))) = (1 - p) / (1 - a) := by
    field_simp; ring
  rw [he, hq', Real.log_div hq.ne' hb.ne',
    Real.log_div (x := a * (1 - p)) (y := p * (1 - a)) (by positivity) (by positivity),
    Real.log_mul ha0.ne' hq.ne', Real.log_mul hp0.ne' hb.ne', Real.log_div ha0.ne' hp0.ne',
    Real.log_div hb.ne' hq.ne']
  ring

-- The card's whole-number and fraction checks.
-- The tilt: e^θ = 3/2 makes the tilted fair coin land heads with chance 3/5.
example : ((3 : ℚ) / 2) / (1 + 3 / 2) = 3 / 5 := by norm_num
-- Variances: 1/4 for the fair coin, 6/25 (0.24) under the tilted coin.
example : ((1 : ℚ) / 2) * (1 - 1 / 2) = 1 / 4 := by norm_num
example : ((3 : ℚ) / 5) * (1 - 3 / 5) = 6 / 25 := by norm_num
-- At n = 1000, a share of 3/5 is 600 heads, and the window of width 1/50 ends at 620 heads.
example : (1000 : ℚ) * (3 / 5) = 600 := by norm_num
example : (1000 : ℚ) * (3 / 5 + 1 / 50) = 620 := by norm_num
-- The divergence of (3/5, 2/5) from (1/2, 1/2) uses the ratios 6/5 (1.2) and 4/5 (0.8).
example : ((3 : ℚ) / 5) / (1 / 2) = 6 / 5 ∧ ((2 : ℚ) / 5) / (1 / 2) = 4 / 5 := by norm_num
-- Two letters at n = 1000: 1001 possible types, within the count bound (n + 1)^r = 1001^2.
example : (Finset.range 1001).card ≤ (1000 + 1) ^ 2 := by rw [Finset.card_range]; norm_num

#print axioms cramer_mgf_sum
#print axioms cramer_integrable_sum
#print axioms cramer_jensen
#print axioms cramer_upper
#print axioms cramer_exists_step
#print axioms cramer_lower_core
#print axioms cramer_rate_eq_coe
#print axioms cramer_log_chance_tendsto_neg_rate
#print axioms chance_average_ge_le_exp_neg_rate
#print axioms coin_rate_eq_kl_divergence
