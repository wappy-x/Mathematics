-- Black-Cox: for assets V_t = V₀ exp(νt + σW_t) driven by a Brownian motion, the chance of touching a flat barrier H below V₀ by time T is the finish-below term N((b - νT)/(σ√T)) plus the reflection term (H/V₀)^(2ν/σ²) N((b + νT)/(σ√T)), with the drifted mirror density and the bridge chance behind it.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum


open MeasureTheory ProbabilityTheory Real
open scoped NNReal

/-! Setting. Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a standard Brownian
motion under `P`: it starts at 0, has independent normal steps with variance equal to the elapsed
time, and has continuous paths almost surely (so the assets move without jumps).

The firm's assets are `V_t = V₀ exp(ν t + σ W_t)` with the pricing-world drift of log assets
`ν = r - σ²/2`, a constant riskless rate `r` and a constant volatility `σ > 0`. The barrier `H` is
flat, positive and below today's value `V₀`; the lenders watch every instant `t ∈ [0, T]`, so the
firm defaults within `T` years exactly when `V_t ≤ H` at some such `t`. `b = ln(H/V₀)` is the
barrier in log units and `N = cdf (gaussianReal 0 1)` is the bell-curve area to the left. -/

section BlackCoxHelpers

open Filter Topology
open scoped ENNReal

lemma bc_pdf_shift (ν σ : ℝ) (u : ℝ≥0) (hσ : σ ≠ 0) (hu : u ≠ 0) (d : ℝ) :
    gaussianPDFReal 0 u (-2 * ν * u / σ - d) * exp (2 * ν * (ν * u + σ * d) / σ ^ 2)
      = gaussianPDFReal 0 u d := by
  have hu' : (u : ℝ) ≠ 0 := by exact_mod_cast hu
  simp only [gaussianPDFReal]
  rw [mul_assoc, ← Real.exp_add]
  congr 2
  field_simp
  ring

lemma bc_reflect_gauss (ν σ a : ℝ) (u : ℝ≥0) (hσ : σ ≠ 0) (ha : 0 ≤ a) :
    ∫⁻ d, {d : ℝ | a < ν * u + σ * d}.indicator (fun _ => (1 : ℝ≥0∞)) d ∂(gaussianReal 0 u) =
    ∫⁻ d, {d : ℝ | ν * u + σ * d < -a}.indicator
      (fun d => ENNReal.ofReal (exp (-2 * ν * (ν * u + σ * d) / σ ^ 2))) d ∂(gaussianReal 0 u) := by
  by_cases hu : u = 0
  · subst hu
    simp only [gaussianReal_zero_var]
    rw [lintegral_dirac, lintegral_dirac]
    have h1 : ¬ a < ν * ((0 : ℝ≥0) : ℝ) + σ * 0 := by simp; linarith
    have h2 : ¬ ν * ((0 : ℝ≥0) : ℝ) + σ * 0 < -a := by simp; linarith
    rw [Set.indicator_of_notMem (by simpa using h1), Set.indicator_of_notMem (by simpa using h2)]
  rw [gaussianReal_of_var_ne_zero _ hu]
  have m1 : Measurable ({d : ℝ | a < ν * u + σ * d}.indicator (fun _ => (1 : ℝ≥0∞))) :=
    measurable_const.indicator (measurableSet_lt measurable_const (by fun_prop))
  have m2 : Measurable ({d : ℝ | ν * u + σ * d < -a}.indicator
      (fun d => ENNReal.ofReal (exp (-2 * ν * (ν * u + σ * d) / σ ^ 2)))) :=
    (by fun_prop : Measurable fun d : ℝ => ENNReal.ofReal (exp (-2 * ν * (ν * u + σ * d) / σ ^ 2))).indicator
      (measurableSet_lt (by fun_prop) measurable_const)
  rw [lintegral_withDensity_eq_lintegral_mul _ (measurable_gaussianPDF _ _) m1,
    lintegral_withDensity_eq_lintegral_mul _ (measurable_gaussianPDF _ _) m2]
  rw [← lintegral_sub_left_eq_self _ (-2 * ν * u / σ)]
  apply lintegral_congr
  intro d
  simp only [Pi.mul_apply, Set.indicator_apply, Set.mem_setOf_eq]
  have key : ν * u + σ * (-2 * ν * u / σ - d) = -(ν * u + σ * d) := by field_simp; ring
  rw [key]
  by_cases hc : ν * u + σ * d < -a
  · rw [if_pos (by linarith), if_pos hc]
    rw [gaussianPDF, gaussianPDF, ← ENNReal.ofReal_mul (gaussianPDFReal_nonneg _ _ _), mul_one]
    congr 1
    rw [← bc_pdf_shift ν σ u hσ hu d, mul_assoc (gaussianPDFReal _ _ _), ← Real.exp_add]
    have : 2 * ν * (ν * u + σ * d) / σ ^ 2 + -2 * ν * (ν * u + σ * d) / σ ^ 2 = 0 := by ring
    rw [this, Real.exp_zero, mul_one]
  · rw [if_neg (by linarith), if_neg hc, mul_zero, mul_zero]
lemma bc_lintegral_indep {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α] {P : Measure Ω}
    [IsProbabilityMeasure P] {Z : Ω → α} {D : Ω → ℝ} {μ : Measure ℝ} [IsProbabilityMeasure μ]
    (hind : IndepFun Z D P) (hZ : AEMeasurable Z P) (hD : HasLaw D μ P)
    {F : α → ℝ → ℝ≥0∞} (hF : Measurable (Function.uncurry F)) :
    ∫⁻ ω, F (Z ω) (D ω) ∂P = ∫⁻ ω, ∫⁻ d, F (Z ω) d ∂μ ∂P := by
  have hmap := (indepFun_iff_map_prod_eq_prod_map_map hZ hD.aemeasurable).1 hind
  rw [hD.map_eq] at hmap
  have h1 : ∫⁻ ω, F (Z ω) (D ω) ∂P = ∫⁻ p, Function.uncurry F p ∂(P.map (fun ω => (Z ω, D ω))) := by
    rw [lintegral_map' hF.aemeasurable (hZ.prodMk hD.aemeasurable)]
    rfl
  rw [h1, hmap, lintegral_prod _ hF.aemeasurable]
  have hm : Measurable fun z => ∫⁻ d, F z d ∂μ := hF.lintegral_prod_right'
  exact lintegral_map' hm.aemeasurable hZ

lemma bc_step {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsPreBrownianReal W P) (ν σ b : ℝ) (hσ : σ ≠ 0) (T s : ℝ≥0) (hsT : s ≤ T)
    (g : ℕ → ℝ≥0) (hg : ∀ j, g j ≤ s) (S : Set (ℝ × (ℕ → ℝ))) (hS : MeasurableSet S)
    (hSb : ∀ p ∈ S, ν * s + σ * p.1 ≤ b) :
    ∫⁻ ω, {ω | (W s ω, fun j => W (g j) ω) ∈ S}.indicator 1 ω
        * {ω | b < ν * T + σ * W T ω}.indicator 1 ω ∂P =
    ∫⁻ ω, {ω | (W s ω, fun j => W (g j) ω) ∈ S}.indicator 1 ω
        * {ω | ν * T + σ * W T ω < 2 * (ν * s + σ * W s ω) - b}.indicator
          (fun ω => ENNReal.ofReal (exp (-2 * ν * ((ν * T + σ * W T ω) - (ν * s + σ * W s ω)) / σ ^ 2))) ω ∂P := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  set Z : Ω → ℝ × (ℕ → ℝ) := fun ω => (W s ω, fun j => W (g j) ω) with hZdef
  set D : Ω → ℝ := fun ω => W (s + (T - s)) ω - W s ω with hDdef
  have hTs : s + (T - s) = T := add_tsub_cancel_of_le hsT
  have hWT : ∀ ω, W T ω = W s ω + D ω := by intro ω; simp only [hDdef, hTs]; ring
  have hψ : Measurable (fun f : Set.Iic s → ℝ => (f ⟨s, Set.mem_Iic.mpr le_rfl⟩, fun j => f ⟨g j, Set.mem_Iic.mpr (hg j)⟩)) :=
    (measurable_pi_apply (⟨s, Set.mem_Iic.mpr le_rfl⟩ : Set.Iic s)).prodMk
      (Measurable.of_eval fun j => measurable_pi_apply (⟨g j, Set.mem_Iic.mpr (hg j)⟩ : Set.Iic s))
  have hφ : Measurable (fun f : ℝ≥0 → ℝ => f (T - s)) := measurable_pi_apply (T - s)
  have hind : IndepFun Z D P := by
    have h := (hW.indepFun_shift s).comp hφ hψ
    exact h.symm
  have hZ1 : ∀ ω, (Z ω).1 = W s ω := fun _ => rfl
  have hZ : AEMeasurable Z P :=
    (hW.aemeasurable s).prodMk (AEMeasurable.of_eval fun j => hW.aemeasurable (g j))
  have hD : HasLaw D (gaussianReal 0 (T - s)) P := (hW.shift s).hasLaw_eval (T - s)
  have hu : ((T - s : ℝ≥0) : ℝ) = T - s := NNReal.coe_sub hsT
  let F1 : ℝ × (ℕ → ℝ) → ℝ → ℝ≥0∞ := fun p d =>
    (S ×ˢ Set.univ).indicator 1 (p, d) *
      {q : (ℝ × (ℕ → ℝ)) × ℝ | b < ν * T + σ * (q.1.1 + q.2)}.indicator 1 (p, d)
  let F2 : ℝ × (ℕ → ℝ) → ℝ → ℝ≥0∞ := fun p d =>
    (S ×ˢ Set.univ).indicator 1 (p, d) *
      {q : (ℝ × (ℕ → ℝ)) × ℝ | ν * T + σ * (q.1.1 + q.2) < 2 * (ν * s + σ * q.1.1) - b}.indicator
        (fun q => ENNReal.ofReal (exp (-2 * ν * ((ν * T + σ * (q.1.1 + q.2)) - (ν * s + σ * q.1.1)) / σ ^ 2))) (p, d)
  have hF1 : Measurable (Function.uncurry F1) :=
    (measurable_const.indicator (hS.prod MeasurableSet.univ)).mul
      (measurable_const.indicator (measurableSet_lt measurable_const (by fun_prop)))
  have hF2 : Measurable (Function.uncurry F2) :=
    (measurable_const.indicator (hS.prod MeasurableSet.univ)).mul
      ((by fun_prop : Measurable fun q : (ℝ × (ℕ → ℝ)) × ℝ =>
        ENNReal.ofReal (exp (-2 * ν * ((ν * T + σ * (q.1.1 + q.2)) - (ν * s + σ * q.1.1)) / σ ^ 2))).indicator
        (measurableSet_lt (by fun_prop) (by fun_prop)))
  have e1 : ∫⁻ ω, {ω | Z ω ∈ S}.indicator 1 ω * {ω | b < ν * T + σ * W T ω}.indicator 1 ω ∂P
      = ∫⁻ ω, F1 (Z ω) (D ω) ∂P := by
    apply lintegral_congr; intro ω
    by_cases h : Z ω ∈ S <;> simp [F1, Set.indicator_apply, h, hWT, hZ1]
  have e2 : ∫⁻ ω, {ω | Z ω ∈ S}.indicator 1 ω
        * {ω | ν * T + σ * W T ω < 2 * (ν * s + σ * W s ω) - b}.indicator
          (fun ω => ENNReal.ofReal (exp (-2 * ν * ((ν * T + σ * W T ω) - (ν * s + σ * W s ω)) / σ ^ 2))) ω ∂P
      = ∫⁻ ω, F2 (Z ω) (D ω) ∂P := by
    apply lintegral_congr; intro ω
    by_cases h : Z ω ∈ S <;> simp [F2, Set.indicator_apply, h, hWT, hZ1]
  rw [e1, e2, bc_lintegral_indep hind hZ hD hF1, bc_lintegral_indep hind hZ hD hF2]
  apply lintegral_congr; intro ω
  by_cases hmem : Z ω ∈ S
  · have hx := hSb _ hmem
    set w := (Z ω).1
    have := bc_reflect_gauss ν σ (b - (ν * s + σ * w)) (T - s) hσ (by linarith)
    convert this using 1
    · apply lintegral_congr; intro d
      simp only [F1, Set.indicator, Set.mem_prod, Set.mem_univ, and_true, hmem, ite_true,
        Set.mem_ofPred_eq, Pi.one_apply, one_mul, hu, w]
      split_ifs <;> first | rfl | (exfalso; linarith)
    · apply lintegral_congr; intro d
      simp only [F2, Set.indicator, Set.mem_prod, Set.mem_univ, and_true, hmem, ite_true,
        Set.mem_ofPred_eq, Pi.one_apply, one_mul, hu, w]
      split_ifs <;> first | rfl | (exfalso; linarith) | (congr 3; ring)
  · simp [F1, F2, Set.indicator, hmem]

lemma bc_first_exists (p : ℕ → Prop) (m : ℕ) (h : ∃ k ≤ m, p k) :
    ∃ k ≤ m, p k ∧ ∀ j < k, ¬ p j := by
  classical
  have h' : ∃ k, p k := let ⟨k, _, hk⟩ := h; ⟨k, hk⟩
  refine ⟨Nat.find h', ?_, Nat.find_spec h', fun j hj => Nat.find_min h' hj⟩
  obtain ⟨k, hkm, hk⟩ := h
  exact (Nat.find_min' h' hk).trans hkm

lemma bc_sum_first {q : ℕ → Prop} {dq : DecidablePred q} (hq : ∀ j k, q j → q k → j = k)
    (a : ℕ → ℝ≥0∞) (m k0 : ℕ) (hk0 : k0 ≤ m) (h : q k0) :
    ∑ k ∈ Finset.range (m + 1), (if q k then a k else 0) = a k0 := by
  rw [Finset.sum_eq_single_of_mem k0 (Finset.mem_range.2 (Nat.lt_succ_of_le hk0))]
  · simp [h]
  · intro k _ hk
    rw [if_neg]
    intro hqk
    exact hk (hq _ _ hqk h)

lemma bc_sum_none {q : ℕ → Prop} {dq : DecidablePred q} (a : ℕ → ℝ≥0∞) (m : ℕ)
    (h : ∀ k ≤ m, ¬ q k) :
    ∑ k ∈ Finset.range (m + 1), (if q k then a k else 0) = 0 := by
  apply Finset.sum_eq_zero
  intro k hk
  rw [if_neg (h k (Nat.lt_succ_iff.1 (Finset.mem_range.1 hk)))]

lemma bc_det (g : ℝ → ℝ) (hg : Continuous g) (T b : ℝ) (hT : 0 < T) (h0 : b < g 0)
    (φ : ℝ → ℝ≥0∞) (hφ : ContinuousAt φ b) (hφ0 : b < g T → φ b = 0) :
    Tendsto (fun n : ℕ => ∑ k ∈ Finset.range (n + 2),
      if g (k * T / (n + 1)) ≤ b ∧ ∀ j < k, b < g (j * T / (n + 1))
      then φ (g (k * T / (n + 1))) else 0) atTop (𝓝 (φ b)) := by
  rw [Filter.tendsto_def]
  intro U hU
  have hU' : φ ⁻¹' U ∈ 𝓝 b := hφ hU
  obtain ⟨ε, hε, hball⟩ := Metric.mem_nhds_iff.1 hU'
  have huc : UniformContinuousOn g (Set.Icc 0 T) :=
    isCompact_Icc.uniformContinuousOn_of_continuous hg.continuousOn
  obtain ⟨δ, hδ, hδ'⟩ := Metric.uniformContinuousOn_iff.1 huc ε hε
  obtain ⟨N, hN⟩ := exists_nat_gt (T / δ)
  rw [Filter.mem_atTop_sets]
  refine ⟨N, fun n hn => ?_⟩
  simp only [Set.mem_preimage]
  have hn1 : (0 : ℝ) < n + 1 := by positivity
  have hstep : T / (n + 1) < δ := by
    have h1 : (N : ℝ) ≤ n := by exact_mod_cast hn
    have h2 : T / δ < n + 1 := by linarith
    rw [div_lt_iff₀ hδ] at h2
    rw [div_lt_iff₀ hn1]
    linarith
  have hsT : ∀ k : ℕ, k ≤ n + 1 → (k : ℝ) * T / (n + 1) ∈ Set.Icc 0 T := by
    intro k hk
    have hk' : (k : ℝ) ≤ n + 1 := by exact_mod_cast hk
    refine ⟨by positivity, ?_⟩
    rw [div_le_iff₀ hn1]
    nlinarith
  have hlast : ((n + 1 : ℕ) : ℝ) * T / (n + 1) = T := by
    push_cast
    field_simp
  have huniq : ∀ j k : ℕ, (g (j * T / (n + 1)) ≤ b ∧ ∀ i < j, b < g (i * T / (n + 1))) →
      (g (k * T / (n + 1)) ≤ b ∧ ∀ i < k, b < g (i * T / (n + 1))) → j = k := by
    intro j k hj hk
    rcases lt_trichotomy j k with h | h | h
    · exact absurd (hk.2 j h) (not_lt.2 hj.1)
    · exact h
    · exact absurd (hj.2 k h) (not_lt.2 hk.1)
  by_cases hex : ∃ k ≤ n + 1, g (k * T / (n + 1)) ≤ b
  · obtain ⟨k0, hk0, hA1, hA2⟩ := bc_first_exists (fun k : ℕ => g (k * T / (n + 1)) ≤ b) (n + 1) hex
    rw [bc_sum_first huniq _ (n + 1) k0 hk0 ⟨hA1, fun j hj => not_le.1 (hA2 j hj)⟩]
    apply hball
    obtain ⟨m, rfl⟩ : ∃ m, k0 = m + 1 := by
      rcases k0 with _ | m
      · exfalso
        have : g ((0 : ℕ) * T / (n + 1)) = g 0 := by simp
        rw [this] at hA1
        linarith
      · exact ⟨m, rfl⟩
    have hprev : b < g (m * T / (n + 1)) := not_le.1 (hA2 m (Nat.lt_succ_self m))
    have hd : dist ((m : ℝ) * T / (n + 1)) (((m + 1 : ℕ) : ℝ) * T / (n + 1)) < δ := by
      rw [Real.dist_eq]
      have : (m : ℝ) * T / (n + 1) - ((m + 1 : ℕ) : ℝ) * T / (n + 1) = -(T / (n + 1)) := by
        push_cast; ring
      rw [this, abs_neg, abs_of_pos (by positivity)]
      exact hstep
    have hc := hδ' _ (hsT m (by omega)) _ (hsT (m + 1) hk0) hd
    rw [Real.dist_eq] at hc
    rw [Metric.mem_ball, Real.dist_eq, abs_lt]
    have := (abs_lt.1 hc)
    constructor <;> linarith
  · rw [bc_sum_none]
    · have hgT : b < g T := by
        by_contra hcon
        apply hex
        exact ⟨n + 1, le_rfl, by rw [hlast]; exact not_lt.1 hcon⟩
      rw [hφ0 hgT] at hU
      exact mem_of_mem_nhds hU
    · intro k hk hA
      exact hex ⟨k, hk, hA.1⟩

lemma bc_gauss_eq (T : ℝ≥0) :
    gaussianReal 0 T = (gaussianReal 0 1).map (fun e => √(T : ℝ) * e) := by
  rw [gaussianReal_map_const_mul]
  congr 1
  · simp
  · ext
    simp [Real.sq_sqrt T.2]

lemma bc_gauss_Iic (T : ℝ≥0) (hT : 0 < T) (c : ℝ) :
    gaussianReal 0 T (Set.Iic c) = ENNReal.ofReal (cdf (gaussianReal 0 1) (c / √(T : ℝ))) := by
  have hs : 0 < √(T : ℝ) := Real.sqrt_pos.2 (by exact_mod_cast hT)
  rw [ofReal_cdf, bc_gauss_eq T, Measure.map_apply (by fun_prop) measurableSet_Iic]
  congr 1
  ext e
  simp only [Set.mem_preimage, Set.mem_Iic]
  rw [le_div_iff₀ hs, mul_comm]

lemma bc_gauss_Ioi (T : ℝ≥0) (hT : 0 < T) (c : ℝ) :
    gaussianReal 0 T (Set.Ioi c) = ENNReal.ofReal (cdf (gaussianReal 0 1) (-c / √(T : ℝ))) := by
  have hT0 : T ≠ 0 := ne_of_gt hT
  haveI := nullSingletonClass_gaussianReal (μ := 0) hT0
  have h1 : gaussianReal 0 T (Set.Ioi c) = gaussianReal 0 T (Set.Iio (-c)) := by
    conv_lhs => rw [← neg_zero, ← gaussianReal_map_neg]
    rw [Measure.map_apply measurable_neg measurableSet_Ioi]
    congr 1
    ext x
    simp [lt_neg]
  rw [h1, measure_congr Iio_ae_eq_Iic, bc_gauss_Iic T hT]

/-- Log assets at time `s`. -/
noncomputable def bcX {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ : ℝ) (s : ℝ≥0) (ω : Ω) : ℝ :=
  ν * s + σ * W s ω

/-- The `k`-th point of the grid with `n + 1` equal steps on `[0, T]`. -/
noncomputable def bcT (T : ℝ≥0) (n k : ℕ) : ℝ≥0 := (k : ℝ≥0) * T / ((n : ℝ≥0) + 1)

/-- The grid point `k` is the first one at or below the barrier. -/
def bcA {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (n k : ℕ) : Set Ω :=
  {ω | bcX W ν σ (bcT T n k) ω ≤ b ∧ ∀ j < k, b < bcX W ν σ (bcT T n j) ω}

/-- Some grid point is at or below the barrier. -/
def bcE {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (n : ℕ) : Set Ω :=
  {ω | ∃ k ≤ n + 1, bcX W ν σ (bcT T n k) ω ≤ b}

/-- The reflected, reweighted end point seen from grid point `k`. -/
noncomputable def bcC {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (n k : ℕ) (ω : Ω) : ℝ≥0∞ :=
  {ω | ν * T + σ * W T ω < 2 * (ν * (bcT T n k : ℝ) + σ * W (bcT T n k) ω) - b}.indicator
    (fun ω => ENNReal.ofReal (exp (-2 * ν * ((ν * T + σ * W T ω)
      - (ν * (bcT T n k : ℝ) + σ * W (bcT T n k) ω)) / σ ^ 2))) ω

noncomputable def bcR {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (n : ℕ) (ω : Ω) : ℝ≥0∞ :=
  ∑ k ∈ Finset.range (n + 2), (bcA W ν σ b T n k).indicator 1 ω * bcC W ν σ b T n k ω

noncomputable def bcL {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (ω : Ω) : ℝ≥0∞ :=
  {ω | bcX W ν σ T ω < b}.indicator
    (fun ω => ENNReal.ofReal (exp (-2 * ν * (bcX W ν σ T ω - b) / σ ^ 2))) ω

lemma bcT_coe (T : ℝ≥0) (n k : ℕ) : ((bcT T n k : ℝ≥0) : ℝ) = (k : ℝ) * T / ((n : ℝ) + 1) := by
  simp [bcT]

lemma bcT_last (T : ℝ≥0) (n : ℕ) : bcT T n (n + 1) = T := by
  apply NNReal.eq
  rw [bcT_coe]
  push_cast
  field_simp

lemma bcT_le (T : ℝ≥0) (n k : ℕ) (hk : k ≤ n + 1) : bcT T n k ≤ T := by
  rw [← NNReal.coe_le_coe, bcT_coe]
  have hk' : (k : ℝ) ≤ n + 1 := by exact_mod_cast hk
  rw [div_le_iff₀ (by positivity)]
  nlinarith [NNReal.coe_nonneg T]

lemma bcT_mono (T : ℝ≥0) (n j k : ℕ) (h : j ≤ k) : bcT T n j ≤ bcT T n k := by
  rw [← NNReal.coe_le_coe, bcT_coe, bcT_coe]
  have h' : (j : ℝ) ≤ k := by exact_mod_cast h
  apply div_le_div_of_nonneg_right _ (by positivity)
  nlinarith [NNReal.coe_nonneg T]

lemma bc_split {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsPreBrownianReal W P) (hm : ∀ t, Measurable (W t)) (ν σ b : ℝ) (T : ℝ≥0)
    (hσ : 0 < σ) (n : ℕ) :
    P (bcE W ν σ b T n) = P {ω | bcX W ν σ T ω ≤ b} + ∫⁻ ω, bcR W ν σ b T n ω ∂P := by
  have hX : ∀ s, Measurable (bcX W ν σ s) := fun s =>
    measurable_const.add (measurable_const.mul (hm s))
  have hEeq : bcE W ν σ b T n = ⋃ k ∈ Finset.range (n + 2), {ω | bcX W ν σ (bcT T n k) ω ≤ b} := by
    ext ω
    simp [bcE, Nat.lt_succ_iff]
  have hEm : MeasurableSet (bcE W ν σ b T n) := by
    rw [hEeq]
    exact Finset.measurableSet_biUnion _ fun k _ => measurableSet_le (hX _) measurable_const
  have hAm : ∀ k, MeasurableSet (bcA W ν σ b T n k) := by
    intro k
    have : bcA W ν σ b T n k = {ω | bcX W ν σ (bcT T n k) ω ≤ b} ∩
        ⋂ j ∈ Finset.range k, {ω | b < bcX W ν σ (bcT T n j) ω} := by
      ext ω
      simp [bcA]
    rw [this]
    exact (measurableSet_le (hX _) measurable_const).inter
      (Finset.measurableSet_biInter _ fun j _ => measurableSet_lt measurable_const (hX _))
  have huniq : ∀ (ω : Ω) (j k : ℕ), ω ∈ bcA W ν σ b T n j → ω ∈ bcA W ν σ b T n k → j = k := by
    intro ω j k hj hk
    rcases lt_trichotomy j k with h | h | h
    · exact absurd (hk.2 j h) (not_lt.2 hj.1)
    · exact h
    · exact absurd (hj.2 k h) (not_lt.2 hk.1)
  have hpt : ∀ ω, (bcE W ν σ b T n).indicator 1 ω =
      {ω | bcX W ν σ T ω ≤ b}.indicator 1 ω +
        ∑ k ∈ Finset.range (n + 2), (bcA W ν σ b T n k).indicator 1 ω
          * {ω | b < bcX W ν σ T ω}.indicator (1 : Ω → ℝ≥0∞) ω := by
    intro ω
    classical
    have hrw : ∀ k, (bcA W ν σ b T n k).indicator 1 ω
        * {ω | b < bcX W ν σ T ω}.indicator (1 : Ω → ℝ≥0∞) ω =
        if ω ∈ bcA W ν σ b T n k then {ω | b < bcX W ν σ T ω}.indicator (1 : Ω → ℝ≥0∞) ω else 0 := by
      intro k
      by_cases h : ω ∈ bcA W ν σ b T n k <;> simp [h]
    simp_rw [hrw]
    by_cases hE : ω ∈ bcE W ν σ b T n
    · obtain ⟨k0, hk0, hA1, hA2⟩ :=
        bc_first_exists (fun k => bcX W ν σ (bcT T n k) ω ≤ b) (n + 1) hE
      rw [bc_sum_first (huniq ω) _ (n + 1) k0 hk0 ⟨hA1, fun j hj => not_le.1 (hA2 j hj)⟩,
        Set.indicator_of_mem hE]
      by_cases h : bcX W ν σ T ω ≤ b
      · rw [Set.indicator_of_mem (show ω ∈ {ω | bcX W ν σ T ω ≤ b} from h),
          Set.indicator_of_notMem (show ω ∉ {ω | b < bcX W ν σ T ω} from not_lt.2 h)]
        simp
      · rw [Set.indicator_of_notMem (show ω ∉ {ω | bcX W ν σ T ω ≤ b} from h),
          Set.indicator_of_mem (show ω ∈ {ω | b < bcX W ν σ T ω} from not_le.1 h)]
        simp
    · rw [bc_sum_none _ (n + 1) (fun k hk hA => hE ⟨k, hk, hA.1⟩), Set.indicator_of_notMem hE]
      have h : ¬ bcX W ν σ T ω ≤ b := by
        intro h
        apply hE
        exact ⟨n + 1, le_rfl, by rw [bcT_last]; exact h⟩
      rw [Set.indicator_of_notMem (show ω ∉ {ω | bcX W ν σ T ω ≤ b} from h)]
      simp
  have hm1 : ∀ k ∈ Finset.range (n + 2), Measurable (fun ω => (bcA W ν σ b T n k).indicator
      (1 : Ω → ℝ≥0∞) ω * {ω | b < bcX W ν σ T ω}.indicator (1 : Ω → ℝ≥0∞) ω) := fun k _ =>
    (measurable_one.indicator (hAm k)).mul
      (measurable_one.indicator (measurableSet_lt measurable_const (hX _)))
  have hm2 : ∀ k ∈ Finset.range (n + 2), Measurable (fun ω => (bcA W ν σ b T n k).indicator
      (1 : Ω → ℝ≥0∞) ω * bcC W ν σ b T n k ω) := by
    intro k _
    apply (measurable_one.indicator (hAm k)).mul
    apply Measurable.indicator _ (measurableSet_lt (by fun_prop) (by fun_prop))
    fun_prop
  rw [← lintegral_indicator_one hEm, lintegral_congr hpt,
    lintegral_add_left (measurable_one.indicator (measurableSet_le (hX _) measurable_const)),
    lintegral_indicator_one (measurableSet_le (hX _) measurable_const),
    lintegral_finsetSum _ hm1]
  congr 1
  unfold bcR
  rw [lintegral_finsetSum _ hm2]
  apply Finset.sum_congr rfl
  intro k hk
  have hk' : k ≤ n + 1 := Nat.lt_succ_iff.1 (Finset.mem_range.1 hk)
  let S : Set (ℝ × (ℕ → ℝ)) := {p | ν * (bcT T n k : ℝ) + σ * p.1 ≤ b} ∩
    ⋂ j ∈ Finset.range k, {p | b < ν * (bcT T n j : ℝ) + σ * p.2 j}
  have hS : MeasurableSet S :=
    (measurableSet_le (by fun_prop) measurable_const).inter
      (Finset.measurableSet_biInter _ fun j _ => measurableSet_lt measurable_const (by fun_prop))
  have hAeq : bcA W ν σ b T n k =
      {ω | (W (bcT T n k) ω, fun j => W (bcT T n (min j k)) ω) ∈ S} := by
    ext ω
    simp only [bcA, bcX, S, Set.mem_ofPred_eq, Set.mem_inter_iff, Set.mem_iInter, Finset.mem_range]
    constructor
    · rintro ⟨h1, h2⟩
      exact ⟨h1, fun j hj => by rw [min_eq_left hj.le]; exact h2 j hj⟩
    · rintro ⟨h1, h2⟩
      exact ⟨h1, fun j hj => by have := h2 j hj; rwa [min_eq_left hj.le] at this⟩
  have := bc_step hW ν σ b hσ.ne' T (bcT T n k) (bcT_le T n k hk')
    (fun j => bcT T n (min j k)) (fun j => bcT_mono T n _ _ (min_le_right j k)) S hS
    (fun p hp => hp.1)
  rw [hAeq]
  exact this

lemma bc_XT_le {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsPreBrownianReal W P) (hm : ∀ t, Measurable (W t)) (ν σ b : ℝ) (T : ℝ≥0)
    (hσ : 0 < σ) (hT : 0 < T) :
    P {ω | bcX W ν σ T ω ≤ b} =
      ENNReal.ofReal (cdf (gaussianReal 0 1) ((b - ν * T) / (σ * √(T : ℝ)))) := by
  have hL := hW.hasLaw_eval T
  have hset : {ω | bcX W ν σ T ω ≤ b} = W T ⁻¹' Set.Iic ((b - ν * T) / σ) := by
    ext ω
    simp only [bcX, Set.mem_ofPred_eq, Set.mem_preimage, Set.mem_Iic]
    rw [le_div_iff₀ hσ]
    constructor <;> intro h <;> linarith
  rw [hset, ← Measure.map_apply (hm T) measurableSet_Iic, hL.map_eq, bc_gauss_Iic T hT, div_div]

lemma bc_L_int {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsPreBrownianReal W P) (hm : ∀ t, Measurable (W t)) (ν σ b : ℝ) (T : ℝ≥0)
    (hσ : 0 < σ) (hT : 0 < T) (hb : b ≤ 0) :
    ∫⁻ ω, bcL W ν σ b T ω ∂P =
      ENNReal.ofReal (exp (2 * ν * b / σ ^ 2)
        * cdf (gaussianReal 0 1) ((b + ν * T) / (σ * √(T : ℝ)))) := by
  have hL := hW.hasLaw_eval T
  let G : ℝ → ℝ≥0∞ := fun d => {d : ℝ | ν * T + σ * d < -(-b)}.indicator
    (fun d => ENNReal.ofReal (exp (-2 * ν * (ν * T + σ * d) / σ ^ 2))) d
  have hG : Measurable G :=
    Measurable.indicator (by fun_prop) (measurableSet_lt (by fun_prop) measurable_const)
  have h1 : ∀ ω, bcL W ν σ b T ω = ENNReal.ofReal (exp (2 * ν * b / σ ^ 2)) * G (W T ω) := by
    intro ω
    by_cases h : ν * T + σ * W T ω < b
    · simp only [bcL, G, bcX, Set.indicator, Set.mem_ofPred_eq, neg_neg, h, ↓reduceIte]
      rw [← ENNReal.ofReal_mul (exp_pos _).le, ← exp_add]
      congr 2
      ring
    · simp only [bcL, G, bcX, Set.indicator, Set.mem_ofPred_eq, neg_neg, h, ↓reduceIte, mul_zero]
  rw [lintegral_congr h1, lintegral_const_mul _ (f := fun ω => G (W T ω)) (hG.comp (hm T))]
  have h2 : (∫⁻ ω, G (W T ω) ∂P) = ∫⁻ d, G d ∂(gaussianReal 0 T) := by
    rw [← hL.map_eq, lintegral_map hG (hm T)]
  rw [h2]
  simp only [G]
  rw [← bc_reflect_gauss ν σ (-b) T hσ.ne' (by linarith),
    lintegral_indicator_const (measurableSet_lt measurable_const (by fun_prop)), one_mul]
  have hset : {d : ℝ | -b < ν * T + σ * d} = Set.Ioi ((-b - ν * T) / σ) := by
    ext d
    simp only [Set.mem_ofPred_eq, Set.mem_Ioi]
    rw [div_lt_iff₀ hσ]
    constructor <;> intro h <;> linarith
  have harg : -((-b - ν * T) / σ) / √(T : ℝ) = (b + ν * T) / (σ * √(T : ℝ)) := by
    rw [← neg_div, div_div]
    congr 1
    ring
  rw [hset, bc_gauss_Ioi T hT, harg, ← ENNReal.ofReal_mul (exp_pos _).le]

lemma bc_A_unique {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (n : ℕ) (ω : Ω) :
    ∀ j k : ℕ, ω ∈ bcA W ν σ b T n j → ω ∈ bcA W ν σ b T n k → j = k := by
  intro j k hj hk
  rcases lt_trichotomy j k with h | h | h
  · exact absurd (hk.2 j h) (not_lt.2 hj.1)
  · exact h
  · exact absurd (hj.2 k h) (not_lt.2 hk.1)

lemma bc_R_le {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (n : ℕ) (ω : Ω)
    (hσ : 0 < σ) : bcR W ν σ b T n ω ≤ 1 + bcL W ν σ b T ω := by
  classical
  unfold bcR
  have hrw : ∀ k, (bcA W ν σ b T n k).indicator 1 ω * bcC W ν σ b T n k ω =
      if ω ∈ bcA W ν σ b T n k then bcC W ν σ b T n k ω else 0 := by
    intro k
    by_cases h : ω ∈ bcA W ν σ b T n k <;> simp [h]
  simp_rw [hrw]
  by_cases hex : ∃ k ≤ n + 1, ω ∈ bcA W ν σ b T n k
  · obtain ⟨k0, hk0, hA⟩ := hex
    rw [bc_sum_first (bc_A_unique W ν σ b T n ω) _ (n + 1) k0 hk0 hA]
    have hx : ν * (bcT T n k0 : ℝ) + σ * W (bcT T n k0) ω ≤ b := hA.1
    unfold bcC bcL
    by_cases h1 : ν * T + σ * W T ω < 2 * (ν * (bcT T n k0 : ℝ) + σ * W (bcT T n k0) ω) - b
    · have h2 : ν * T + σ * W T ω < b := by linarith
      rw [Set.indicator_of_mem (show ω ∈ {ω | ν * T + σ * W T ω <
          2 * (ν * (bcT T n k0 : ℝ) + σ * W (bcT T n k0) ω) - b} from h1),
        Set.indicator_of_mem (show ω ∈ {ω | bcX W ν σ T ω < b} from h2)]
      simp only [bcX]
      rw [← ENNReal.ofReal_one, ← ENNReal.ofReal_add zero_le_one (exp_pos _).le]
      apply ENNReal.ofReal_le_ofReal
      rcases le_or_gt 0 ν with hν | hν
      · have : -2 * ν * (ν * T + σ * W T ω - (ν * (bcT T n k0 : ℝ) + σ * W (bcT T n k0) ω)) / σ ^ 2
            ≤ -2 * ν * (ν * T + σ * W T ω - b) / σ ^ 2 := by
          apply div_le_div_of_nonneg_right _ (by positivity)
          nlinarith
        linarith [exp_le_exp.2 this, exp_pos (-2 * ν * (ν * T + σ * W T ω - b) / σ ^ 2)]
      · have : -2 * ν * (ν * T + σ * W T ω - (ν * (bcT T n k0 : ℝ) + σ * W (bcT T n k0) ω)) / σ ^ 2
            ≤ 0 := by
          apply div_nonpos_of_nonpos_of_nonneg _ (by positivity)
          nlinarith
        linarith [exp_le_one_iff.2 this, exp_pos (-2 * ν * (ν * T + σ * W T ω - b) / σ ^ 2)]
    · rw [Set.indicator_of_notMem (show ω ∉ {ω | ν * T + σ * W T ω <
          2 * (ν * (bcT T n k0 : ℝ) + σ * W (bcT T n k0) ω) - b} from h1)]
      positivity
  · push_neg at hex
    rw [bc_sum_none _ (n + 1) hex]
    positivity

lemma bc_R_tendsto_pt {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0)
    (hσ : 0 < σ) (hT : 0 < T) (hb : b < 0) (ω : Ω) (f : ℝ≥0 → ℝ) (hf : Continuous f)
    (hf0 : f 0 = 0) (hfW : ∀ n k : ℕ, W (bcT T n k) ω = f (bcT T n k))
    (hne : bcX W ν σ T ω ≠ b) :
    Tendsto (fun n => bcR W ν σ b T n ω) atTop (𝓝 (bcL W ν σ b T ω)) := by
  classical
  let g : ℝ → ℝ := fun s => ν * s + σ * f s.toNNReal
  have hg : Continuous g :=
    (continuous_const.mul continuous_id).add (continuous_const.mul (hf.comp continuous_real_toNNReal))
  have hWT : W T ω = f T := by
    have h := hfW 0 1
    have hT1 : bcT T 0 1 = T := by simpa using bcT_last T 0
    rwa [hT1] at h
  have hgT : ν * (T : ℝ) + σ * W T ω = g T := by simp [g, hWT]
  have hgk : ∀ n k : ℕ, ν * (bcT T n k : ℝ) + σ * W (bcT T n k) ω = g (k * T / (n + 1)) := by
    intro n k
    rw [← bcT_coe]
    simp [g, hfW]
  let φ : ℝ → ℝ≥0∞ := fun y => {y : ℝ | g T < 2 * y - b}.indicator
    (fun y => ENNReal.ofReal (exp (-2 * ν * (g T - y) / σ ^ 2))) y
  have hne' : g T ≠ b := by rw [← hgT]; exact hne
  have hφ : ContinuousAt φ b := by
    rcases lt_or_gt_of_ne hne' with hlt | hgt
    · have hopen : IsOpen {y : ℝ | g T < 2 * y - b} := isOpen_lt continuous_const (by fun_prop)
      have hmem : b ∈ {y : ℝ | g T < 2 * y - b} := by
        simp only [Set.mem_ofPred_eq]; linarith
      have hcont : ContinuousAt (fun y => ENNReal.ofReal (exp (-2 * ν * (g T - y) / σ ^ 2))) b :=
        (ENNReal.continuous_ofReal.comp (Real.continuous_exp.comp
          (by fun_prop : Continuous fun y : ℝ => -2 * ν * (g T - y) / σ ^ 2))).continuousAt
      apply hcont.congr
      filter_upwards [hopen.mem_nhds hmem] with y hy
      simp only [φ]
      rw [Set.indicator_of_mem hy]
    · have hopen : IsOpen {y : ℝ | 2 * y - b < g T} := isOpen_lt (by fun_prop) continuous_const
      have hmem : b ∈ {y : ℝ | 2 * y - b < g T} := by
        simp only [Set.mem_ofPred_eq]; linarith
      apply (continuousAt_const (y := (0 : ℝ≥0∞))).congr
      filter_upwards [hopen.mem_nhds hmem] with y hy
      simp only [φ]
      rw [Set.indicator_of_notMem]
      simp only [Set.mem_ofPred_eq, not_lt]
      exact le_of_lt hy
  have hφ0 : b < g T → φ b = 0 := by
    intro h
    simp only [φ]
    rw [Set.indicator_of_notMem]
    simp only [Set.mem_ofPred_eq, not_lt]
    linarith
  have h0 : b < g 0 := by simp [g, hf0]; linarith
  have key := bc_det g hg T b (by exact_mod_cast hT) h0 φ hφ hφ0
  have hL : bcL W ν σ b T ω = φ b := by
    simp only [bcL, φ, Set.indicator, Set.mem_ofPred_eq, bcX, hgT]
    have : 2 * b - b = b := by ring
    rw [this]
  have hR : ∀ n : ℕ, bcR W ν σ b T n ω = ∑ k ∈ Finset.range (n + 2),
      if g (k * T / (n + 1)) ≤ b ∧ ∀ j < k, b < g (j * T / (n + 1))
      then φ (g (k * T / (n + 1))) else 0 := by
    intro n
    unfold bcR
    apply Finset.sum_congr rfl
    intro k _
    unfold bcA bcC
    simp only [Set.indicator, Set.mem_ofPred_eq, Pi.one_apply, bcX, hgk, hgT, φ]
    split_ifs <;> simp
  rw [hL]
  exact key.congr (fun n => (hR n).symm)

lemma bc_E_meas {Ω : Type*} [MeasurableSpace Ω] {W : ℝ≥0 → Ω → ℝ}
    (hm : ∀ t, Measurable (W t)) (ν σ b : ℝ) (T : ℝ≥0) (n : ℕ) :
    MeasurableSet (bcE W ν σ b T n) := by
  have hX : ∀ s, Measurable (bcX W ν σ s) := fun s =>
    measurable_const.add (measurable_const.mul (hm s))
  have hEeq : bcE W ν σ b T n = ⋃ k ∈ Finset.range (n + 2), {ω | bcX W ν σ (bcT T n k) ω ≤ b} := by
    ext ω
    simp [bcE, Nat.lt_succ_iff]
  rw [hEeq]
  exact Finset.measurableSet_biUnion _ fun k _ => measurableSet_le (hX _) measurable_const

lemma bc_R_meas {Ω : Type*} [MeasurableSpace Ω] {W : ℝ≥0 → Ω → ℝ}
    (hm : ∀ t, Measurable (W t)) (ν σ b : ℝ) (T : ℝ≥0) (n : ℕ) :
    Measurable (bcR W ν σ b T n) := by
  have hX : ∀ s, Measurable (bcX W ν σ s) := fun s =>
    measurable_const.add (measurable_const.mul (hm s))
  have hAm : ∀ k, MeasurableSet (bcA W ν σ b T n k) := by
    intro k
    have : bcA W ν σ b T n k = {ω | bcX W ν σ (bcT T n k) ω ≤ b} ∩
        ⋂ j ∈ Finset.range k, {ω | b < bcX W ν σ (bcT T n j) ω} := by
      ext ω
      simp [bcA]
    rw [this]
    exact (measurableSet_le (hX _) measurable_const).inter
      (Finset.measurableSet_biInter _ fun j _ => measurableSet_lt measurable_const (hX _))
  unfold bcR
  apply Finset.measurable_sum
  intro k _
  apply (measurable_one.indicator (hAm k)).mul
  apply Measurable.indicator _ (measurableSet_lt (by fun_prop) (by fun_prop))
  fun_prop

lemma bc_limit {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsPreBrownianReal W P) (hm : ∀ t, Measurable (W t)) (ν σ b : ℝ) (T : ℝ≥0)
    (hσ : 0 < σ) (hT : 0 < T) (hb : b < 0)
    (hgood : ∀ᵐ ω ∂P, ∃ f : ℝ≥0 → ℝ, Continuous f ∧ f 0 = 0 ∧
      ∀ n k : ℕ, W (bcT T n k) ω = f (bcT T n k)) :
    Tendsto (fun n => P (bcE W ν σ b T n)) atTop
      (𝓝 (ENNReal.ofReal (cdf (gaussianReal 0 1) ((b - ν * T) / (σ * √(T : ℝ)))
        + exp (2 * ν * b / σ ^ 2) * cdf (gaussianReal 0 1) ((b + ν * T) / (σ * √(T : ℝ)))))) := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  have hne : ∀ᵐ ω ∂P, bcX W ν σ T ω ≠ b := by
    have hL := hW.hasLaw_eval T
    have := nullSingletonClass_gaussianReal (μ := 0) (ne_of_gt hT)
    rw [ae_iff]
    have hset : {ω | ¬ bcX W ν σ T ω ≠ b} = W T ⁻¹' {(b - ν * T) / σ} := by
      ext ω
      simp only [bcX, ne_eq, not_not, Set.mem_ofPred_eq, Set.mem_preimage, Set.mem_singleton_iff]
      rw [eq_div_iff hσ.ne']
      constructor <;> intro h <;> linarith
    rw [hset, ← Measure.map_apply (hm T) (measurableSet_singleton _), hL.map_eq, measure_singleton]
  have hlim : Tendsto (fun n => ∫⁻ ω, bcR W ν σ b T n ω ∂P) atTop
      (𝓝 (∫⁻ ω, bcL W ν σ b T ω ∂P)) := by
    apply tendsto_lintegral_of_dominated_convergence' (fun ω => 1 + bcL W ν σ b T ω)
    · intro n
      exact (bc_R_meas hm ν σ b T n).aemeasurable
    · intro n
      exact Filter.Eventually.of_forall (fun ω => bc_R_le W ν σ b T n ω hσ)
    · rw [lintegral_add_left measurable_const, lintegral_const, measure_univ, mul_one,
        bc_L_int hW hm ν σ b T hσ hT hb.le]
      exact ENNReal.add_ne_top.2 ⟨ENNReal.one_ne_top, ENNReal.ofReal_ne_top⟩
    · filter_upwards [hgood, hne] with ω ⟨f, hf, hf0, hfW⟩ hω
      exact bc_R_tendsto_pt W ν σ b T hσ hT hb ω f hf hf0 hfW hω
  have h := hlim.const_add (P {ω | bcX W ν σ T ω ≤ b})
  rw [bc_L_int hW hm ν σ b T hσ hT hb.le, bc_XT_le hW hm ν σ b T hσ hT,
    ← ENNReal.ofReal_add (cdf_nonneg _ _) (mul_nonneg (exp_pos _).le (cdf_nonneg _ _))] at h
  refine h.congr (fun n => ?_)
  rw [bc_split hW hm ν σ b T hσ n, bc_XT_le hW hm ν σ b T hσ hT]

lemma bc_core {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsBrownianReal W P) (ν σ b : ℝ) (T : ℝ≥0) (hσ : 0 < σ) (hT : 0 < T) (hb : b < 0) :
    P.real {ω | ∃ t ≤ T, ν * (t : ℝ) + σ * W t ω ≤ b} =
      cdf (gaussianReal 0 1) ((b - ν * T) / (σ * √(T : ℝ)))
        + exp (2 * ν * b / σ ^ 2) * cdf (gaussianReal 0 1) ((b + ν * T) / (σ * √(T : ℝ))) := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  let W' : ℝ≥0 → Ω → ℝ := fun t => (hW.aemeasurable t).mk (W t)
  have hW'm : ∀ t, Measurable (W' t) := fun t => (hW.aemeasurable t).measurable_mk
  have hWW' : ∀ t, W t =ᵐ[P] W' t := fun t => (hW.aemeasurable t).ae_eq_mk
  have hW' : IsPreBrownianReal W' P := hW.toIsPreBrownianReal.congr hWW'
  have hgrid : ∀ᵐ ω ∂P, ∀ n k : ℕ, W (bcT T n k) ω = W' (bcT T n k) ω := by
    rw [ae_all_iff]
    intro n
    rw [ae_all_iff]
    intro k
    exact hWW' _
  have hgood : ∀ᵐ ω ∂P, ∃ f : ℝ≥0 → ℝ, Continuous f ∧ f 0 = 0 ∧
      ∀ n k : ℕ, W' (bcT T n k) ω = f (bcT T n k) := by
    filter_upwards [hW.cont, hW.eval_zero_ae_eq_zero, hgrid] with ω h1 h2 h3
    exact ⟨fun t => W t ω, h1, h2, fun n k => (h3 n k).symm⟩
  let G : ℝ → ℝ := fun c => cdf (gaussianReal 0 1) ((c - ν * T) / (σ * √(T : ℝ)))
    + exp (2 * ν * c / σ ^ 2) * cdf (gaussianReal 0 1) ((c + ν * T) / (σ * √(T : ℝ)))
  have hlim : ∀ c < 0, Tendsto (fun n => P (bcE W' ν σ c T n)) atTop (𝓝 (ENNReal.ofReal (G c))) :=
    fun c hc => bc_limit hW' hW'm ν σ c T hσ hT hc hgood
  have hG0 : 0 ≤ G b := add_nonneg (cdf_nonneg _ _) (mul_nonneg (exp_pos _).le (cdf_nonneg _ _))
  let Ev : Set Ω := {ω | ∃ t ≤ T, ν * (t : ℝ) + σ * W t ω ≤ b}
  have hlow : ENNReal.ofReal (G b) ≤ P Ev := by
    apply le_of_tendsto' (hlim b hb)
    intro n
    apply measure_mono_ae
    filter_upwards [hgrid] with ω hω hE
    obtain ⟨k, hk, hX⟩ := hE
    refine ⟨bcT T n k, bcT_le T n k hk, ?_⟩
    simpa [bcX, hω] using hX
  have hsT : 0 < √(T : ℝ) := Real.sqrt_pos.2 (by exact_mod_cast hT)
  have hup : ∀ c, b < c → c < 0 → P Ev ≤ ENNReal.ofReal (G c) := by
    intro c hbc hc0
    let fn : ℕ → Ω → ℝ≥0∞ := fun n => (bcE W' ν σ c T n).indicator 1
    have hfn : ∀ n, Measurable (fn n) := fun n =>
      measurable_one.indicator (bc_E_meas hW'm ν σ c T n)
    have hev2 : ∀ᵐ ω ∂P, ω ∈ Ev → ω ∈ {ω | 1 ≤ liminf (fun n => fn n ω) atTop} := by
      filter_upwards [hW.cont, hgrid] with ω hcont hω hEv
      obtain ⟨t, htT, hXt⟩ := hEv
      have hcontX : Continuous (fun s : ℝ≥0 => ν * (s : ℝ) + σ * W s ω) := by fun_prop
      obtain ⟨δ, hδ, hδ'⟩ := Metric.continuous_iff.1 hcontX t (c - (ν * (t : ℝ) + σ * W t ω))
        (by linarith)
      have hev3 : ∀ᶠ n in atTop, fn n ω = 1 := by
        obtain ⟨N, hN⟩ := exists_nat_gt (T / δ)
        filter_upwards [eventually_ge_atTop N] with n hn
        have hn1 : (0 : ℝ) < n + 1 := by positivity
        have hT' : (0 : ℝ) < T := by exact_mod_cast hT
        have htT' : (t : ℝ) ≤ T := by exact_mod_cast htT
        have hstep : (T : ℝ) / (n + 1) < δ := by
          have h1 : (N : ℝ) ≤ n := by exact_mod_cast hn
          have h2 : T / δ < n + 1 := by linarith
          rw [div_lt_iff₀ hδ] at h2
          rw [div_lt_iff₀ hn1]
          linarith
        apply Set.indicator_of_mem
        set k := ⌈(t : ℝ) * (n + 1) / T⌉₊ with hkdef
        have hk1 : (t : ℝ) * (n + 1) / T ≤ k := Nat.le_ceil _
        have hk2 : (k : ℝ) < (t : ℝ) * (n + 1) / T + 1 := Nat.ceil_lt_add_one (by positivity)
        refine ⟨k, ?_, ?_⟩
        · have : (t : ℝ) * (n + 1) / T ≤ ((n + 1 : ℕ) : ℝ) := by
            rw [div_le_iff₀ hT']
            push_cast
            nlinarith
          exact Nat.ceil_le.2 this
        · have hd : dist (bcT T n k) t < δ := by
            rw [NNReal.dist_eq, bcT_coe, abs_lt]
            have e1 : (t : ℝ) ≤ k * T / (n + 1) := by
              rw [le_div_iff₀ hn1]
              rw [div_le_iff₀ hT'] at hk1
              linarith
            have e2 : (k : ℝ) * T / (n + 1) < t + T / (n + 1) := by
              have h3 : (k : ℝ) * T < t * (n + 1) + T := by
                have := hk2
                rw [div_add_one hT'.ne', lt_div_iff₀ hT'] at this
                linarith
              rw [div_lt_iff₀ hn1, add_mul, div_mul_cancel₀ _ hn1.ne']
              linarith
            constructor <;> linarith
          have := hδ' _ hd
          rw [Real.dist_eq, abs_lt] at this
          show bcX W' ν σ (bcT T n k) ω ≤ c
          simp only [bcX, ← hω]
          linarith [this.2]
      have ht1 : Tendsto (fun n => fn n ω) atTop (𝓝 1) :=
        tendsto_const_nhds.congr' (hev3.mono fun n h => h.symm)
      show 1 ≤ liminf (fun n => fn n ω) atTop
      rw [ht1.liminf_eq]
    calc P Ev ≤ P {ω | 1 ≤ liminf (fun n => fn n ω) atTop} := measure_mono_ae hev2
      _ ≤ ∫⁻ ω, liminf (fun n => fn n ω) atTop ∂P := by
          have := mul_meas_ge_le_lintegral₀ (μ := P)
            (f := fun ω => liminf (fun n => fn n ω) atTop) (Measurable.liminf hfn).aemeasurable 1
          simpa using this
      _ ≤ liminf (fun n => ∫⁻ ω, fn n ω ∂P) atTop := lintegral_liminf_le hfn
      _ = ENNReal.ofReal (G c) := by
          simp only [fn, lintegral_indicator_one (bc_E_meas hW'm ν σ c T _)]
          exact (hlim c hc0).liminf_eq
  have hGc : Tendsto (fun c => ENNReal.ofReal (G c)) (𝓝[>] b) (𝓝 (ENNReal.ofReal (G b))) := by
    have hpos : 0 < σ * √(T : ℝ) := mul_pos hσ hsT
    have hc1 : ContinuousWithinAt (fun c => cdf (gaussianReal 0 1) ((c - ν * T) / (σ * √(T : ℝ))))
        (Set.Ioi b) b := by
      apply ContinuousWithinAt.comp ((cdf (gaussianReal 0 1)).right_continuous _)
        (by fun_prop : Continuous fun c : ℝ => (c - ν * T) / (σ * √(T : ℝ))).continuousWithinAt
      intro c hc
      simp only [Set.mem_Ici]
      apply div_le_div_of_nonneg_right _ hpos.le
      have : b < c := hc
      linarith
    have hc2 : ContinuousWithinAt (fun c => cdf (gaussianReal 0 1) ((c + ν * T) / (σ * √(T : ℝ))))
        (Set.Ioi b) b := by
      apply ContinuousWithinAt.comp ((cdf (gaussianReal 0 1)).right_continuous _)
        (by fun_prop : Continuous fun c : ℝ => (c + ν * T) / (σ * √(T : ℝ))).continuousWithinAt
      intro c hc
      simp only [Set.mem_Ici]
      apply div_le_div_of_nonneg_right _ hpos.le
      have : b < c := hc
      linarith
    have hc3 : ContinuousWithinAt (fun c : ℝ => exp (2 * ν * c / σ ^ 2)) (Set.Ioi b) b :=
      (by fun_prop : Continuous fun c : ℝ => exp (2 * ν * c / σ ^ 2)).continuousWithinAt
    have hG : ContinuousWithinAt G (Set.Ioi b) b := hc1.add (hc3.mul hc2)
    exact (ENNReal.continuous_ofReal.continuousAt.comp_continuousWithinAt hG)
  have hEq : P Ev = ENNReal.ofReal (G b) := by
    apply le_antisymm _ hlow
    apply ge_of_tendsto hGc
    filter_upwards [Ioo_mem_nhdsGT hb] with c hc
    exact hup c hc.1 hc.2
  rw [measureReal_def, hEq, ENNReal.toReal_ofReal hG0]

end BlackCoxHelpers

#print axioms bc_pdf_shift
#print axioms bc_reflect_gauss
#print axioms bc_lintegral_indep
#print axioms bc_step
#print axioms bc_first_exists
#print axioms bc_sum_first
#print axioms bc_sum_none
#print axioms bc_det
#print axioms bc_gauss_eq
#print axioms bc_gauss_Iic
#print axioms bc_gauss_Ioi
#print axioms bcT_coe
#print axioms bcT_last
#print axioms bcT_le
#print axioms bcT_mono
#print axioms bc_split
#print axioms bc_XT_le
#print axioms bc_L_int
#print axioms bc_A_unique
#print axioms bc_R_le
#print axioms bc_R_tendsto_pt
#print axioms bc_E_meas
#print axioms bc_R_meas
#print axioms bc_limit
#print axioms bc_core

/-- **Black-Cox first-passage default** (the card's main claim). Let the assets follow
`V_t = V₀ e^{νt + σW_t}` with `W` a Brownian motion, `ν = r - σ²/2`, `σ > 0`, and let the barrier
`H` be flat with `0 < H < V₀`. Then the chance that the assets touch the barrier at some instant
of `[0, T]` (`T > 0`) is the chance of finishing below it plus the reflection term:
`P(τ ≤ T) = N((b - νT)/(σ√T)) + (H/V₀)^{2ν/σ²} N((b + νT)/(σ√T))`, where `b = ln(H/V₀)`. -/
theorem black_cox_first_passage_default_probability
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsBrownianReal W P) (V₀ H r σ : ℝ) (T : ℝ≥0)
    (hH : 0 < H) (hHV : H < V₀) (hσ : 0 < σ) (hT : 0 < T) :
    let ν : ℝ := r - σ ^ 2 / 2
    let b : ℝ := log (H / V₀)
    let V : ℝ≥0 → Ω → ℝ := fun t ω => V₀ * exp (ν * t + σ * W t ω)
    P.real {ω | ∃ t ≤ T, V t ω ≤ H} =
      cdf (gaussianReal 0 1) ((b - ν * T) / (σ * √(T : ℝ)))
        + (H / V₀) ^ (2 * ν / σ ^ 2) * cdf (gaussianReal 0 1) ((b + ν * T) / (σ * √(T : ℝ))) := by
  intro ν b V
  have hV₀ : 0 < V₀ := hH.trans hHV
  have hHV0 : 0 < H / V₀ := div_pos hH hV₀
  have hb : b < 0 := Real.log_neg hHV0 ((div_lt_one hV₀).2 hHV)
  have hev : {ω | ∃ t ≤ T, V t ω ≤ H} = {ω | ∃ t ≤ T, ν * (t : ℝ) + σ * W t ω ≤ b} := by
    ext ω
    simp only [Set.mem_ofPred_eq]
    apply exists_congr
    intro t
    apply and_congr_right
    intro _
    show V₀ * exp (ν * t + σ * W t ω) ≤ H ↔ ν * t + σ * W t ω ≤ log (H / V₀)
    rw [Real.le_log_iff_exp_le hHV0, le_div_iff₀ hV₀, mul_comm]
  have hw : (H / V₀) ^ (2 * ν / σ ^ 2) = exp (2 * ν * b / σ ^ 2) := by
    rw [Real.rpow_def_of_pos hHV0]
    congr 1
    show log (H / V₀) * (2 * ν / σ ^ 2) = 2 * ν * log (H / V₀) / σ ^ 2
    ring
  rw [hev, hw]
  exact bc_core hW ν σ b T hσ hT hb

/-- **Drift tilts the mirror by one weight** (Why it works, Step 2, "Adding drift"). Let `p₀` be
the bell-curve density with centre 0 and variance `σ²T`, and `p_ν` the one with centre `νT` and
the same variance. For the barrier `b` in log units and any end point `y`, the driftless density
of touched paths ending at `y`, `p₀(2b - y)`, times the drift's likelihood ratio
`exp(νy/σ² - ν²T/(2σ²))`, equals the weight `e^{2νb/σ²}` times the drifted density at the
shifted point `y - 2b`. -/
theorem drifted_reflection_density (ν σ T b y : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    gaussianPDFReal 0 (σ ^ 2 * T).toNNReal (2 * b - y)
        * exp (ν * y / σ ^ 2 - ν ^ 2 * T / (2 * σ ^ 2))
      = exp (2 * ν * b / σ ^ 2) * gaussianPDFReal (ν * T) (σ ^ 2 * T).toNNReal (y - 2 * b) := by
  have hv : 0 ≤ σ ^ 2 * T := by positivity
  simp only [gaussianPDFReal, Real.coe_toNNReal _ hv]
  have hσ2 : σ ^ 2 ≠ 0 := by positivity
  have hT' : T ≠ 0 := hT.ne'
  rw [mul_assoc, ← Real.exp_add, mul_left_comm (rexp _), ← Real.exp_add]
  congr 2
  field_simp
  ring

/-- **The bridge chance has no drift** (Why it works, "The bridge chance", and Step 4). Dividing
the density of touched paths ending at `y`, `e^{2νb/σ²} p_ν(y - 2b)`, by the density of all paths
ending at `y`, `p_ν(y)`, gives `exp(2b(y - b)/(σ²T))`, the chance that a path from log level 0 to
`y` touched `b` on the way: the drift `ν` has cancelled. -/
theorem bridge_touch_chance_eq (ν σ T b y : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    exp (2 * ν * b / σ ^ 2) * gaussianPDFReal (ν * T) (σ ^ 2 * T).toNNReal (y - 2 * b)
        / gaussianPDFReal (ν * T) (σ ^ 2 * T).toNNReal y
      = exp (2 * b * (y - b) / (σ ^ 2 * T)) := by
  have hv : 0 ≤ σ ^ 2 * T := by positivity
  have hpos : 0 < gaussianPDFReal (ν * T) (σ ^ 2 * T).toNNReal y :=
    gaussianPDFReal_pos _ _ _ (by simp; positivity)
  rw [div_eq_iff hpos.ne']
  simp only [gaussianPDFReal, Real.coe_toNNReal _ hv]
  have hσ2 : σ ^ 2 ≠ 0 := by positivity
  have hT' : T ≠ 0 := hT.ne'
  rw [mul_left_comm, ← Real.exp_add, mul_left_comm (exp _), ← Real.exp_add]
  congr 2
  field_simp
  ring

/-! The card's exact worked numbers, as fractions: V₀ = 100, H = 80, 70, 60, r = 5%, σ = 20%. -/

-- Drift of log assets: ν = 0.05 - ½(0.20)² = 0.03.
example : ((5 : ℚ) / 100 - (20 / 100) ^ 2 / 2) = 3 / 100 := by norm_num
-- Weight exponent: 2ν/σ² = 0.06/0.04 = 1.5.
example : 2 * ((3 : ℚ) / 100) / (20 / 100) ^ 2 = 3 / 2 := by norm_num
-- The barriers as fractions of today's value: 80/100 = 0.8, 70/100 = 0.7, 60/100 = 0.6.
example : (80 : ℚ) / 100 = 4 / 5 ∧ (70 : ℚ) / 100 = 7 / 10 ∧ (60 : ℚ) / 100 = 3 / 5 := by norm_num
-- The reflection weight 0.8^1.5 = 0.715542 to six places: its square 0.8³ = 0.512 lies between
-- 0.7155415² and 0.7155425².
example : ((4 : ℚ) / 5) ^ 3 = 64 / 125 ∧
    ((7155415 : ℚ) / 10 ^ 7) ^ 2 ≤ 64 / 125 ∧ (64 : ℚ) / 125 < ((7155425 : ℚ) / 10 ^ 7) ^ 2 := by
  norm_num
-- No drift: r = 2% gives ν = 0.02 - ½(0.20)² = 0, so the weight is 1.
example : ((2 : ℚ) / 100 - (20 / 100) ^ 2 / 2) = 0 := by norm_num
-- More volatile assets: σ = 30% gives ν = 0.05 - ½(0.30)² = 0.005.
example : ((5 : ℚ) / 100 - (30 / 100) ^ 2 / 2) = 5 / 1000 := by norm_num
-- Real-world drift: 8% expected growth gives 0.08 - 0.02 = 0.06.
example : ((8 : ℚ) / 100 - (20 / 100) ^ 2 / 2) = 6 / 100 := by norm_num
-- Total default chance at $80m: 0.102807 + 0.119562 = 0.222369.
example : (102807 : ℕ) + 119562 = 222369 := by norm_num


#print axioms black_cox_first_passage_default_probability
#print axioms drifted_reflection_density
#print axioms bridge_touch_chance_eq
