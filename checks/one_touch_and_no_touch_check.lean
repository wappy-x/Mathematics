-- One-touch and no-touch: under geometric Brownian motion the chance of touching a barrier above today's price is the chance of finishing past it plus a weighted mirror term, one-touch plus no-touch is always a discounted dollar, and discounting the first-passage density at the hit gives the same density with a steeper drift.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory Real
open scoped NNReal

section OneTouchHelpers

open Filter Topology
open scoped ENNReal

lemma otnt_pdf_shift (a d u : ℝ) (hd : d ≠ 0) :
    gaussianPDF 0 1 (-(2 * a / d) - u) *
      ENNReal.ofReal (Real.exp (-(2 * a / d ^ 2) * (a + d * (-(2 * a / d) - u)))) =
    gaussianPDF 0 1 u := by
  simp only [gaussianPDF, gaussianPDFReal, NNReal.coe_one]
  rw [← ENNReal.ofReal_mul (by positivity)]
  congr 1
  rw [mul_assoc, ← Real.exp_add]
  congr 2
  field_simp
  ring

#print axioms otnt_pdf_shift

lemma otnt_gauss_reflect (a d : ℝ) (hd : d ≠ 0) (g : ℝ → ℝ≥0∞) (hg : Measurable g) :
    ∫⁻ u, g (a + d * u) ∂gaussianReal 0 1 =
      ∫⁻ u, g (-(a + d * u)) * ENNReal.ofReal (Real.exp (-(2 * a / d ^ 2) * (a + d * u)))
        ∂gaussianReal 0 1 := by
  rw [gaussianReal_of_var_ne_zero 0 one_ne_zero,
    lintegral_withDensity_eq_lintegral_mul _ (measurable_gaussianPDF 0 1) (by fun_prop),
    lintegral_withDensity_eq_lintegral_mul _ (measurable_gaussianPDF 0 1) (by fun_prop)]
  conv_rhs => rw [← lintegral_sub_left_eq_self _ (-(2 * a / d))]
  congr 1
  ext u
  simp only [Pi.mul_apply]
  have h1 : -(a + d * (-(2 * a / d) - u)) = a + d * u := by field_simp; ring
  rw [h1, ← otnt_pdf_shift a d u hd]
  ring

#print axioms otnt_gauss_reflect

lemma otnt_indicator_continuousAt (p q y : ℝ) (f : ℝ → ℝ≥0∞) (hf : Continuous f)
    (hp : y ≠ p) (hq : y ≠ q) : ContinuousAt ((Set.Ioo p q).indicator f) y := by
  rcases lt_or_gt_of_ne hp with h1 | h1
  · refine (continuousAt_const (y := (0 : ℝ≥0∞))).congr ?_
    filter_upwards [Iio_mem_nhds h1] with x hx
    rw [Set.indicator_of_notMem (fun (h : x ∈ Set.Ioo p q) => absurd h.1 (not_lt.2 (le_of_lt (Set.mem_Iio.1 hx))))]
  rcases lt_or_gt_of_ne hq with h2 | h2
  · refine hf.continuousAt.congr ?_
    filter_upwards [Ioo_mem_nhds h1 h2] with x hx
    rw [Set.indicator_of_mem hx]
  · refine (continuousAt_const (y := (0 : ℝ≥0∞))).congr ?_
    filter_upwards [Ioi_mem_nhds h2] with x hx
    rw [Set.indicator_of_notMem (fun (h : x ∈ Set.Ioo p q) => absurd h.2 (not_lt.2 (le_of_lt (Set.mem_Ioi.1 hx))))]

#print axioms otnt_indicator_continuousAt

lemma otnt_G_tendsto (ν σ : ℝ) (hσ : 0 < σ) (ψ : ℝ → ℝ≥0∞) (hψ : Measurable ψ) (C : ℝ≥0∞)
    (hC : C ≠ ∞) (hψC : ∀ y, ψ y ≤ C) (p q : ℝ)
    (hψc : ∀ y, y ≠ p → y ≠ q → ContinuousAt ψ y) (s0 : ℝ) (hs0 : 0 < s0) :
    Tendsto (fun x : ℝ × ℝ => ∫⁻ u, ψ (x.1 + (ν * x.2 + σ * √x.2 * u)) ∂gaussianReal 0 1)
      (𝓝 (0, s0)) (𝓝 (∫⁻ u, ψ (0 + (ν * s0 + σ * √s0 * u)) ∂gaussianReal 0 1)) := by
  have hd : σ * √s0 ≠ 0 := by positivity
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  refine tendsto_lintegral_filter_of_dominated_convergence (fun _ => C) ?_ ?_ ?_ ?_
  · exact Eventually.of_forall fun x => by fun_prop
  · exact Eventually.of_forall fun x => ae_of_all _ fun u => hψC _
  · simp [hC]
  · filter_upwards [Measure.ae_ne (gaussianReal 0 1) ((p - ν * s0) / (σ * √s0)),
      Measure.ae_ne (gaussianReal 0 1) ((q - ν * s0) / (σ * √s0))] with u hu1 hu2
    have hcont : ContinuousAt ψ (0 + (ν * s0 + σ * √s0 * u)) := by
      apply hψc
      · intro h; apply hu1; field_simp; linarith
      · intro h; apply hu2; field_simp; linarith
    refine hcont.tendsto.comp ?_
    have : Continuous (fun x : ℝ × ℝ => x.1 + (ν * x.2 + σ * √x.2 * u)) := by fun_prop
    exact this.tendsto (0, s0)

#print axioms otnt_G_tendsto

/-- The log price `ν t + σ B_t`. -/

noncomputable def otntX {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ : ℝ) (t : ℝ≥0) (ω : Ω) : ℝ :=
  ν * t + σ * B t ω

/-- The path reaches the level `b` by time `t`. -/

def otntHit {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (t : ℝ≥0) (ω : Ω) : Prop :=
  ∃ s ≤ t, b ≤ otntX B ν σ s ω

/-- The countable set of probe times `q T`. -/

noncomputable def otntPt (T : ℝ≥0) (q : ℚ) : ℝ≥0 := Real.toNNReal (q * T)

/-- The path seen at the probe times, frozen after `t₀`. -/

noncomputable def otntWc {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (T t₀ : ℝ≥0) (ω : Ω) : ℚ → ℝ :=
  fun q => B (min (otntPt T q) t₀) ω

/-- The countable version of "reaches `b` by time `t`". -/

def otntHitC (ν σ b : ℝ) (T t : ℝ≥0) (c : ℚ → ℝ) : Prop :=
  ∀ m : ℕ, ∃ q : ℚ, otntPt T q ≤ t ∧ b - 1 / ((m : ℝ) + 1) < ν * (otntPt T q : ℝ) + σ * c q

lemma otnt_measurableSet_hitC (ν σ b : ℝ) (T t : ℝ≥0) :
    MeasurableSet {c : ℚ → ℝ | otntHitC ν σ b T t c} := by
  simp only [otntHitC, Set.ofPred_forall, Set.ofPred_exists]
  refine MeasurableSet.iInter fun m => MeasurableSet.iUnion fun q => ?_
  by_cases h : otntPt T q ≤ t
  · simp only [h, true_and]
    exact measurableSet_lt measurable_const (by fun_prop)
  · simp [h]

#print axioms otnt_measurableSet_hitC

lemma otnt_hit_iff {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (hT : 0 < T) (ω : Ω)
    (hc : Continuous (fun t => B t ω)) (qt : ℚ) (t₀ : ℝ≥0) (ht : otntPt T qt ≤ t₀) :
    otntHit B ν σ b (otntPt T qt) ω ↔ otntHitC ν σ b T (otntPt T qt) (otntWc B T t₀ ω) := by
  set t := otntPt T qt with ht_def
  have hX : Continuous (fun s => otntX B ν σ s ω) := by
    unfold otntX; fun_prop
  have hW : ∀ q, otntPt T q ≤ t → otntWc B T t₀ ω q = B (otntPt T q) ω := by
    intro q hq
    simp only [otntWc, min_eq_left (hq.trans ht)]
  constructor
  · rintro ⟨s, hst, hbs⟩ m
    have hε : (0 : ℝ) < 1 / ((m : ℝ) + 1) := by positivity
    suffices ∃ q : ℚ, otntPt T q ≤ t ∧ b - 1 / ((m : ℝ) + 1) < otntX B ν σ (otntPt T q) ω by
      obtain ⟨q, hq1, hq2⟩ := this
      exact ⟨q, hq1, by rw [hW q hq1]; exact hq2⟩
    rcases eq_or_lt_of_le hst with h | h
    · exact ⟨qt, le_rfl, by rw [← ht_def, ← h]; linarith⟩
    obtain ⟨δ, hδ, hδX⟩ := Metric.continuousAt_iff.1 hX.continuousAt _ hε
    have hT' : (0 : ℝ) < T := hT
    have hst' : (s : ℝ) < t := h
    have hc : (s : ℝ) / T < min ((s : ℝ) + δ) t / T := by
      apply div_lt_div_of_pos_right _ hT'
      exact lt_min (by linarith) hst'
    obtain ⟨q, hq1, hq2⟩ := exists_rat_btwn hc
    have hs0 : (0 : ℝ) ≤ s := s.2
    have hqT1 : (s : ℝ) < q * T := by rwa [div_lt_iff₀ hT'] at hq1
    have hqT2 : (q : ℝ) * T < min ((s : ℝ) + δ) t := by rwa [lt_div_iff₀ hT'] at hq2
    have hpt : ((otntPt T q : ℝ≥0) : ℝ) = q * T := by
      simp only [otntPt]; rw [Real.coe_toNNReal _ (by linarith)]
    refine ⟨q, ?_, ?_⟩
    · rw [← NNReal.coe_le_coe, hpt]; exact le_trans hqT2.le (min_le_right _ _)
    · have hd : dist (otntPt T q) s < δ := by
        rw [NNReal.dist_eq, hpt, abs_lt]
        constructor <;> linarith [min_le_left ((s : ℝ) + δ) t]
      have := hδX hd
      rw [Real.dist_eq, abs_lt] at this
      linarith [this.1]
  · intro hC
    obtain ⟨s, hs, hmax⟩ := (isCompact_Icc (a := (0 : ℝ≥0)) (b := t)).exists_isMaxOn
      (Set.nonempty_Icc.2 (by simp)) hX.continuousOn
    refine ⟨s, hs.2, ?_⟩
    by_contra hlt
    replace hlt := not_le.1 hlt
    obtain ⟨m, hm⟩ := exists_nat_one_div_lt (sub_pos.2 hlt)
    obtain ⟨q, hq1, hq2⟩ := hC m
    rw [hW q hq1] at hq2
    have := hmax ⟨by simp, hq1⟩
    simp only [Set.mem_setOf_eq] at this
    have h3 : otntX B ν σ (otntPt T q) ω ≤ otntX B ν σ s ω := this
    unfold otntX at h3 hm
    linarith

#print axioms otnt_hit_iff

lemma otnt_indep_lintegral {Ω β : Type*} [MeasurableSpace Ω] [MeasurableSpace β] {P : Measure Ω}
    [IsProbabilityMeasure P] {W : Ω → β} {V : Ω → ℝ} (hW : AEMeasurable W P)
    (hV : AEMeasurable V P) (hind : IndepFun W V P) {μV : Measure ℝ} (hlaw : P.map V = μV)
    (F : β → ℝ → ℝ≥0∞) (hF : Measurable (Function.uncurry F)) :
    ∫⁻ ω, F (W ω) (V ω) ∂P = ∫⁻ ω, ∫⁻ v, F (W ω) v ∂μV ∂P := by
  have h1 := (indepFun_iff_map_prod_eq_prod_map_map hW hV).1 hind
  calc ∫⁻ ω, F (W ω) (V ω) ∂P
      = ∫⁻ p, Function.uncurry F p ∂(P.map fun ω => (W ω, V ω)) :=
        (lintegral_map' hF.aemeasurable (hW.prodMk hV)).symm
    _ = ∫⁻ p, Function.uncurry F p ∂((P.map W).prod (P.map V)) := by rw [h1]
    _ = ∫⁻ w, ∫⁻ v, F w v ∂(P.map V) ∂(P.map W) := lintegral_prod _ hF.aemeasurable
    _ = ∫⁻ ω, ∫⁻ v, F (W ω) v ∂(P.map V) ∂P :=
        lintegral_map' hF.lintegral_prod_right'.aemeasurable hW
    _ = ∫⁻ ω, ∫⁻ v, F (W ω) v ∂μV ∂P := by rw [hlaw]

#print axioms otnt_indep_lintegral

/-- The Gaussian average that replaces the future after time `t`. -/

noncomputable def otntG (ν σ : ℝ) (ψ : ℝ → ℝ≥0∞) (z s : ℝ) : ℝ≥0∞ :=
  ∫⁻ u, ψ (z + (ν * s + σ * √s * u)) ∂gaussianReal 0 1

lemma otnt_gauss_scale (ψ : ℝ → ℝ≥0∞) (hψ : Measurable ψ) (z ν σ : ℝ) (s : ℝ≥0) :
    ∫⁻ v, ψ (z + (ν * s + σ * v)) ∂gaussianReal 0 s = otntG ν σ ψ z s := by
  have h : gaussianReal 0 s = (gaussianReal 0 1).map (fun u => √(s : ℝ) * u) := by
    rw [gaussianReal_map_const_mul]
    congr 1
    · simp
    · ext; simp
  rw [h, lintegral_map (by fun_prop) (by fun_prop), otntG]
  congr 1; ext u; congr 2; ring

#print axioms otnt_gauss_scale

lemma otnt_measurable_G (ν σ : ℝ) (ψ : ℝ → ℝ≥0∞) (hψ : Measurable ψ) (s : ℝ) :
    Measurable (fun z => otntG ν σ ψ z s) := by
  unfold otntG
  exact (by fun_prop : Measurable (Function.uncurry
    fun (z u : ℝ) => ψ (z + (ν * s + σ * √s * u)))).lintegral_prod_right'

#print axioms otnt_measurable_G

lemma otnt_step {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (ν σ b : ℝ) (T : ℝ≥0) (qt : ℚ) (s : ℝ≥0)
    (A : Set (ℚ → ℝ)) (hA : MeasurableSet A) (ψ : ℝ → ℝ≥0∞) (hψ : Measurable ψ)
    (t₀ t₁ : ℝ≥0) (ht₀ : otntPt T qt = t₀) (ht₁ : t₀ + s = t₁) :
    ∫⁻ ω, A.indicator 1 (otntWc B T t₀ ω) * ψ (otntX B ν σ t₁ ω - b) ∂P =
      ∫⁻ ω, A.indicator 1 (otntWc B T t₀ ω) * otntG ν σ ψ (otntX B ν σ t₀ ω - b) s ∂P := by
  subst ht₁
  rw [eq_comm] at ht₀
  set W := otntWc B T t₀ with hW_def
  set V : Ω → ℝ := fun ω => B (t₀ + s) ω - B t₀ ω with hV_def
  have hWm : AEMeasurable W P := AEMeasurable.of_eval (fun q => hB.aemeasurable _)
  have hVm : AEMeasurable V P := (hB.aemeasurable _).sub (hB.aemeasurable _)
  have hind : IndepFun W V P := by
    have h := (hB.indepFun_shift t₀).comp (φ := fun f : ℝ≥0 → ℝ => f s)
      (ψ := fun (w : Set.Iic t₀ → ℝ) (q : ℚ) => w ⟨min (otntPt T q) t₀, Set.mem_Iic.2 (min_le_right _ _)⟩)
      (measurable_pi_apply (X := fun _ : ℝ≥0 => ℝ) s) (Measurable.of_eval (fun q => measurable_pi_apply (X := fun _ : Set.Iic t₀ => ℝ)
        (⟨min (otntPt T q) t₀, Set.mem_Iic.2 (min_le_right _ _)⟩ : Set.Iic t₀)))
    exact h.symm
  have hlaw : P.map V = gaussianReal 0 s := by
    have := (hB.hasLaw_sub (t₀ + s) t₀).map_eq
    rw [show V = B (t₀ + s) - B t₀ from rfl, this]
    congr 1
    ext
    simp
  have hWq : ∀ ω, W ω qt = B t₀ ω := fun ω => by simp [hW_def, otntWc, ← ht₀]
  set F : (ℚ → ℝ) → ℝ → ℝ≥0∞ := fun c v =>
    A.indicator 1 c * ψ ((ν * t₀ + σ * c qt - b) + (ν * s + σ * v)) with hF_def
  have hF : Measurable (Function.uncurry F) := by
    refine Measurable.mul ?_ ?_
    · exact (measurable_const.indicator hA).comp measurable_fst
    · exact hψ.comp (by fun_prop)
  have h1 : ∀ ω, A.indicator 1 (W ω) * ψ (otntX B ν σ (t₀ + s) ω - b) = F (W ω) (V ω) := by
    intro ω
    simp only [hF_def, hWq, hV_def, otntX]
    congr 2
    push_cast
    ring
  simp_rw [h1]
  rw [otnt_indep_lintegral hWm hVm hind hlaw F hF]
  congr 1
  ext ω
  simp only [hF_def]
  rw [lintegral_const_mul' _ _ (by
    by_cases h : W ω ∈ A <;> simp [Set.indicator, h]), hWq]
  congr 1
  rw [← otnt_gauss_scale ψ hψ]
  simp [otntX]

#print axioms otnt_step

/-- The grid point `k T / (n + 1)`. -/

noncomputable def otntGrid (T : ℝ≥0) (n k : ℕ) : ℝ≥0 := otntPt T ((k : ℚ) / ((n : ℚ) + 1))

lemma otnt_grid_coe (T : ℝ≥0) (n k : ℕ) :
    ((otntGrid T n k : ℝ≥0) : ℝ) = k / ((n : ℝ) + 1) * T := by
  simp only [otntGrid, otntPt]
  rw [Real.coe_toNNReal _ (by positivity)]
  push_cast
  ring

#print axioms otnt_grid_coe

lemma otnt_grid_le (T : ℝ≥0) (n k l : ℕ) (h : k ≤ l) : otntGrid T n k ≤ otntGrid T n l := by
  rw [← NNReal.coe_le_coe, otnt_grid_coe, otnt_grid_coe]
  gcongr

#print axioms otnt_grid_le

lemma otnt_grid_zero (T : ℝ≥0) (n : ℕ) : otntGrid T n 0 = 0 := by
  rw [← NNReal.coe_inj, otnt_grid_coe]; simp

#print axioms otnt_grid_zero

lemma otnt_grid_last (T : ℝ≥0) (n : ℕ) : otntGrid T n (n + 1) = T := by
  rw [← NNReal.coe_inj, otnt_grid_coe]; push_cast; field_simp

#print axioms otnt_grid_last

lemma otnt_grid_succ (T : ℝ≥0) (n k : ℕ) :
    ((otntGrid T n (k + 1) : ℝ≥0) : ℝ) = otntGrid T n k + T / ((n : ℝ) + 1) := by
  rw [otnt_grid_coe, otnt_grid_coe]; push_cast; field_simp

#print axioms otnt_grid_succ

open Classical in

lemma otnt_sum_single (p : ℕ → Prop) (hmono : ∀ k l, k ≤ l → p k → p l) (h0 : ¬p 0) (N : ℕ)
    (f : ℕ → ℝ≥0∞) :
    (p N → ∃ j < N, p (j + 1) ∧ ¬p j ∧
      ∑ k ∈ Finset.range N, (if p (k + 1) ∧ ¬p k then f k else 0) = f j) ∧
    (¬p N → ∑ k ∈ Finset.range N, (if p (k + 1) ∧ ¬p k then f k else 0) = 0) := by
  constructor
  · intro hN
    have hex : ∃ i, p i := ⟨N, hN⟩
    have hpi : p (Nat.find hex) := Nat.find_spec hex
    have hmin : ∀ m < Nat.find hex, ¬p m := fun m hm => Nat.find_min hex hm
    have hi0 : Nat.find hex ≠ 0 := fun h => h0 (h ▸ hpi)
    obtain ⟨j, hj⟩ : ∃ j, Nat.find hex = j + 1 := Nat.exists_eq_succ_of_ne_zero hi0
    rw [hj] at hpi hmin
    have hnj : ¬p j := hmin j (by omega)
    have hjN : j < N := by
      by_contra h
      exact hnj (hmono N j (by omega) hN)
    refine ⟨j, hjN, hpi, hnj, ?_⟩
    rw [Finset.sum_eq_single j]
    · simp [hpi, hnj]
    · intro k _ hkj
      rw [if_neg]
      rintro ⟨hk1, hk2⟩
      rcases lt_or_gt_of_ne hkj with h | h
      · exact hnj (hmono (k + 1) j (by omega) hk1)
      · exact hk2 (hmono (j + 1) k (by omega) hpi)
    · intro h; exact absurd (Finset.mem_range.2 hjN) h
  · intro hN
    refine Finset.sum_eq_zero fun k hk => ?_
    rw [if_neg]
    rintro ⟨hk1, _⟩
    exact hN (hmono (k + 1) N (by have := Finset.mem_range.1 hk; omega) hk1)

#print axioms otnt_sum_single

/-- The first time the log price reaches `b`. -/

noncomputable def otntTau {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (ω : Ω) : ℝ≥0 :=
  sInf {s : ℝ≥0 | b ≤ otntX B ν σ s ω}

lemma otnt_tau_props {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (hb : 0 < b) (T : ℝ≥0) (ω : Ω)
    (hc : Continuous (fun t => B t ω)) (h0 : B 0 ω = 0) (hH : otntHit B ν σ b T ω) :
    (∀ t, otntHit B ν σ b t ω ↔ otntTau B ν σ b ω ≤ t) ∧
      otntX B ν σ (otntTau B ν σ b ω) ω = b ∧ 0 < otntTau B ν σ b ω := by
  have hX : Continuous (fun s => otntX B ν σ s ω) := by
    unfold otntX; fun_prop
  set S := {s : ℝ≥0 | b ≤ otntX B ν σ s ω} with hS_def
  have hS : IsClosed S := isClosed_le continuous_const hX
  obtain ⟨s₀, -, hs₀⟩ := hH
  have hne : S.Nonempty := ⟨s₀, hs₀⟩
  have hmem : otntTau B ν σ b ω ∈ S := hS.csInf_mem hne (OrderBot.bddBelow S)
  have hX0 : otntX B ν σ 0 ω = 0 := by simp [otntX, h0]
  have hiff : ∀ t, otntHit B ν σ b t ω ↔ otntTau B ν σ b ω ≤ t := by
    intro t
    constructor
    · rintro ⟨s, hst, hs⟩
      exact (csInf_le (OrderBot.bddBelow S) hs).trans hst
    · intro h
      exact ⟨_, h, hmem⟩
  refine ⟨hiff, ?_, ?_⟩
  · refine le_antisymm ?_ hmem
    have hb' : b ∈ Set.Icc (otntX B ν σ 0 ω) (otntX B ν σ (otntTau B ν σ b ω) ω) :=
      ⟨by rw [hX0]; exact hb.le, hmem⟩
    obtain ⟨c, hc1, hc2⟩ := intermediate_value_Icc (by simp) hX.continuousOn hb'
    have hc2 : otntX B ν σ c ω = b := hc2
    have : otntTau B ν σ b ω ≤ c := csInf_le (OrderBot.bddBelow S) (show c ∈ S from hc2.ge)
    have hceq : c = otntTau B ν σ b ω := le_antisymm hc1.2 this
    rw [← hceq, hc2]
  · refine pos_iff_ne_zero.2 (fun h => ?_)
    have : b ≤ otntX B ν σ 0 ω := by rw [← h]; exact hmem
    rw [hX0] at this; linarith

#print axioms otnt_tau_props

open Classical in

/-- The grid version of the reflected payoff, before the limit. -/

noncomputable def otntGn {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0)
    (ψ : ℝ → ℝ≥0∞) (n : ℕ) (ω : Ω) : ℝ≥0∞ :=
  ∑ k ∈ Finset.range (n + 1),
    if otntHit B ν σ b (otntGrid T n (k + 1)) ω ∧ ¬otntHit B ν σ b (otntGrid T n k) ω then
      otntG ν σ ψ (otntX B ν σ (otntGrid T n (k + 1)) ω - b) ((T - otntGrid T n (k + 1) : ℝ≥0) : ℝ)
    else 0

/-- The grid event "first reached between grid points `k` and `k + 1`", seen in the probes. -/

def otntAset (ν σ b : ℝ) (T : ℝ≥0) (n k : ℕ) : Set (ℚ → ℝ) :=
  {c | otntHitC ν σ b T (otntGrid T n (k + 1)) c ∧ ¬otntHitC ν σ b T (otntGrid T n k) c}

lemma otnt_measurableSet_Aset (ν σ b : ℝ) (T : ℝ≥0) (n k : ℕ) :
    MeasurableSet (otntAset ν σ b T n k) :=
  (otnt_measurableSet_hitC ν σ b T _).inter (otnt_measurableSet_hitC ν σ b T _).compl

#print axioms otnt_measurableSet_Aset

open Classical in

lemma otnt_ind_eq' {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (hT : 0 < T) (ω : Ω)
    (hc : Continuous (fun t => B t ω)) (n k : ℕ) (t₀ : ℝ≥0) (ht₀ : otntGrid T n (k + 1) ≤ t₀) :
    (otntAset ν σ b T n k).indicator 1 (otntWc B T t₀ ω) =
      if otntHit B ν σ b (otntGrid T n (k + 1)) ω ∧ ¬otntHit B ν σ b (otntGrid T n k) ω then
        (1 : ℝ≥0∞) else 0 := by
  have h1 := otnt_hit_iff B ν σ b T hT ω hc _ t₀ ht₀
  have h2 := otnt_hit_iff B ν σ b T hT ω hc _ t₀
    ((otnt_grid_le T n k (k + 1) (Nat.le_succ k)).trans ht₀)
  have hmem : otntWc B T t₀ ω ∈ otntAset ν σ b T n k ↔
      otntHit B ν σ b (otntGrid T n (k + 1)) ω ∧ ¬otntHit B ν σ b (otntGrid T n k) ω := by
    simp only [otntAset, Set.mem_setOf_eq, otntGrid] at h1 h2 ⊢
    rw [h1, h2]
  by_cases hA : otntHit B ν σ b (otntGrid T n (k + 1)) ω ∧ ¬otntHit B ν σ b (otntGrid T n k) ω
  · rw [if_pos hA, Set.indicator_of_mem (hmem.2 hA), Pi.one_apply]
  · rw [if_neg hA, Set.indicator_of_notMem (fun h => hA (hmem.1 h))]

#print axioms otnt_ind_eq'

open Classical in

lemma otnt_ind_eq {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (hT : 0 < T) (ω : Ω)
    (hc : Continuous (fun t => B t ω)) (n k : ℕ) :
    (otntAset ν σ b T n k).indicator 1 (otntWc B T (otntGrid T n (k + 1)) ω) =
      if otntHit B ν σ b (otntGrid T n (k + 1)) ω ∧ ¬otntHit B ν σ b (otntGrid T n k) ω then
        (1 : ℝ≥0∞) else 0 :=
  otnt_ind_eq' B ν σ b T hT ω hc n k _ le_rfl

#print axioms otnt_ind_eq

lemma otnt_aemeasurable_X {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (ν σ : ℝ) (t : ℝ≥0) :
    AEMeasurable (otntX B ν σ t) P := by
  unfold otntX
  exact aemeasurable_const.add ((hB.aemeasurable t).const_mul σ)

#print axioms otnt_aemeasurable_X

open Classical in

lemma otnt_lhs_eq_Gn {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (hc : ∀ ω, Continuous (fun t => B t ω))
    (h0 : ∀ ω, B 0 ω = 0) (ν σ b : ℝ) (hb : 0 < b) (T : ℝ≥0) (hT : 0 < T)
    (ψ : ℝ → ℝ≥0∞) (hψ : Measurable ψ) (n : ℕ) :
    ∫⁻ ω, (if otntHit B ν σ b T ω then ψ (otntX B ν σ T ω - b) else 0) ∂P =
      ∫⁻ ω, otntGn B ν σ b T ψ n ω ∂P := by
  have hWm : ∀ t₀, AEMeasurable (otntWc B T t₀) P :=
    fun t₀ => AEMeasurable.of_eval (fun q => hB.aemeasurable _)
  have hmono : ∀ ω, ∀ k l, k ≤ l → otntHit B ν σ b (otntGrid T n k) ω →
      otntHit B ν σ b (otntGrid T n l) ω := by
    rintro ω k l hkl ⟨s, hs, hbs⟩
    exact ⟨s, hs.trans (otnt_grid_le T n k l hkl), hbs⟩
  have hnot0 : ∀ ω, ¬otntHit B ν σ b (otntGrid T n 0) ω := by
    rintro ω ⟨s, hs, hbs⟩
    rw [otnt_grid_zero, nonpos_iff_eq_zero] at hs
    subst hs
    simp [otntX, h0] at hbs
    linarith
  have hlast : otntGrid T n (n + 1) = T := otnt_grid_last T n
  -- Step 1: split the left side over the grid cells.
  have hsplit : ∀ ω, (if otntHit B ν σ b T ω then ψ (otntX B ν σ T ω - b) else 0) =
      ∑ k ∈ Finset.range (n + 1), (otntAset ν σ b T n k).indicator 1
        (otntWc B T (otntGrid T n (k + 1)) ω) * ψ (otntX B ν σ T ω - b) := by
    intro ω
    simp_rw [otnt_ind_eq B ν σ b T hT ω (hc ω) n, ite_mul, one_mul, zero_mul]
    have hs := otnt_sum_single (fun k => otntHit B ν σ b (otntGrid T n k) ω) (hmono ω)
      (hnot0 ω) (n + 1) (fun _ => ψ (otntX B ν σ T ω - b))
    simp only [hlast] at hs
    by_cases hH : otntHit B ν σ b T ω
    · obtain ⟨j, -, -, -, hj⟩ := hs.1 hH
      rw [if_pos hH, hj]
    · rw [if_neg hH, hs.2 hH]
  -- Step 2: the same for the right side.
  have hsplit2 : ∀ ω, otntGn B ν σ b T ψ n ω =
      ∑ k ∈ Finset.range (n + 1), (otntAset ν σ b T n k).indicator 1
        (otntWc B T (otntGrid T n (k + 1)) ω) *
          otntG ν σ ψ (otntX B ν σ (otntGrid T n (k + 1)) ω - b)
            ((T - otntGrid T n (k + 1) : ℝ≥0) : ℝ) := by
    intro ω
    simp_rw [otnt_ind_eq B ν σ b T hT ω (hc ω) n, ite_mul, one_mul, zero_mul]
    rfl
  simp_rw [hsplit, hsplit2]
  rw [lintegral_finsetSum' _, lintegral_finsetSum' _]
  · refine Finset.sum_congr rfl fun k hk => ?_
    have hle : otntGrid T n (k + 1) ≤ T := by
      exact (otnt_grid_le T n (k + 1) (n + 1) (by have := Finset.mem_range.1 hk; omega)).trans
        hlast.le
    have := otnt_step hB ν σ b T ((((k + 1 : ℕ) : ℚ)) / ((n : ℚ) + 1)) (T - otntGrid T n (k + 1))
      (otntAset ν σ b T n k) (otnt_measurableSet_Aset ν σ b T n k) ψ hψ
      (otntGrid T n (k + 1)) T rfl (add_tsub_cancel_of_le hle)
    exact this
  · intro k _
    exact (((measurable_const.indicator (otnt_measurableSet_Aset ν σ b T n k))).comp_aemeasurable
      (hWm _)).mul ((otnt_measurable_G ν σ ψ hψ _).comp_aemeasurable
        ((otnt_aemeasurable_X hB ν σ _).sub_const b))
  · intro k _
    exact (((measurable_const.indicator (otnt_measurableSet_Aset ν σ b T n k))).comp_aemeasurable
      (hWm _)).mul (hψ.comp_aemeasurable ((otnt_aemeasurable_X hB ν σ _).sub_const b))

#print axioms otnt_lhs_eq_Gn

lemma otnt_G_le (ν σ : ℝ) (ψ : ℝ → ℝ≥0∞) (C : ℝ≥0∞) (hψC : ∀ y, ψ y ≤ C) (z s : ℝ) :
    otntG ν σ ψ z s ≤ C := by
  unfold otntG
  calc ∫⁻ u, ψ (z + (ν * s + σ * √s * u)) ∂gaussianReal 0 1 ≤ ∫⁻ _, C ∂gaussianReal 0 1 :=
        lintegral_mono fun u => hψC _
    _ = C := by simp

#print axioms otnt_G_le

open Classical in

lemma otnt_Gn_props {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (hb : 0 < b) (T : ℝ≥0)
    (ψ : ℝ → ℝ≥0∞) (ω : Ω) (h0 : B 0 ω = 0) (n : ℕ) :
    (¬otntHit B ν σ b T ω → otntGn B ν σ b T ψ n ω = 0) ∧
    (otntHit B ν σ b T ω → ∃ j < n + 1, otntHit B ν σ b (otntGrid T n (j + 1)) ω ∧
      ¬otntHit B ν σ b (otntGrid T n j) ω ∧
      otntGn B ν σ b T ψ n ω = otntG ν σ ψ (otntX B ν σ (otntGrid T n (j + 1)) ω - b)
        ((T - otntGrid T n (j + 1) : ℝ≥0) : ℝ)) := by
  have hmono : ∀ k l, k ≤ l → otntHit B ν σ b (otntGrid T n k) ω →
      otntHit B ν σ b (otntGrid T n l) ω := by
    rintro k l hkl ⟨s, hs, hbs⟩
    exact ⟨s, hs.trans (otnt_grid_le T n k l hkl), hbs⟩
  have hnot0 : ¬otntHit B ν σ b (otntGrid T n 0) ω := by
    rintro ⟨s, hs, hbs⟩
    rw [otnt_grid_zero, nonpos_iff_eq_zero] at hs
    subst hs
    simp [otntX, h0] at hbs
    linarith
  have hs := otnt_sum_single (fun k => otntHit B ν σ b (otntGrid T n k) ω) hmono hnot0 (n + 1)
    (fun k => otntG ν σ ψ (otntX B ν σ (otntGrid T n (k + 1)) ω - b)
      ((T - otntGrid T n (k + 1) : ℝ≥0) : ℝ))
  simp only [otnt_grid_last] at hs
  exact hs.symm.imp id id |>.symm |> fun h => ⟨h.2, h.1⟩

#print axioms otnt_Gn_props

lemma otnt_Gn_tendsto {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (hσ : 0 < σ) (hb : 0 < b)
    (T : ℝ≥0) (ψ : ℝ → ℝ≥0∞) (hψ : Measurable ψ) (C : ℝ≥0∞) (hC : C ≠ ∞)
    (hψC : ∀ y, ψ y ≤ C) (p q : ℝ) (hψc : ∀ y, y ≠ p → y ≠ q → ContinuousAt ψ y)
    (ω : Ω) (hc : Continuous (fun t => B t ω)) (h0 : B 0 ω = 0)
    (hH : otntHit B ν σ b T ω) (hτ : otntTau B ν σ b ω < T) :
    Tendsto (fun n => otntGn B ν σ b T ψ n ω) atTop
      (𝓝 (otntG ν σ ψ 0 ((T - otntTau B ν σ b ω : ℝ≥0) : ℝ))) := by
  obtain ⟨hiff, hXτ, -⟩ := otnt_tau_props B ν σ b hb T ω hc h0 hH
  set τ := otntTau B ν σ b ω with hτ_def
  have hX : Continuous (fun s => otntX B ν σ s ω) := by
    unfold otntX; fun_prop
  choose j hj using fun n => (otnt_Gn_props B ν σ b hb T ψ ω h0 n).2 hH
  set r : ℕ → ℝ≥0 := fun n => otntGrid T n (j n + 1) with hr_def
  have hr1 : ∀ n, (τ : ℝ) ≤ r n := fun n => NNReal.coe_le_coe.2 ((hiff _).1 (hj n).2.1)
  have hr2 : ∀ n, (r n : ℝ) ≤ τ + T * (1 / ((n : ℝ) + 1)) := by
    intro n
    have h1 : otntGrid T n (j n) < τ := lt_of_not_ge fun h => (hj n).2.2.1 ((hiff _).2 h)
    have h1' : (otntGrid T n (j n) : ℝ) < τ := h1
    simp only [hr_def]
    rw [otnt_grid_succ]
    have : (T : ℝ) / ((n : ℝ) + 1) = T * (1 / ((n : ℝ) + 1)) := by ring
    linarith
  have hrlim : Tendsto r atTop (𝓝 τ) := by
    rw [← NNReal.tendsto_coe]
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds ?_ hr1 hr2
    have := (tendsto_one_div_add_atTop_nhds_zero_nat).const_mul (T : ℝ)
    simpa using this.const_add (τ : ℝ)
  have hs0 : (0 : ℝ) < ((T - τ : ℝ≥0) : ℝ) := NNReal.coe_pos.2 (tsub_pos_of_lt hτ)
  have hlim1 : Tendsto (fun n => otntX B ν σ (r n) ω - b) atTop (𝓝 0) := by
    have := ((hX.tendsto τ).comp hrlim).sub_const b
    rwa [Function.comp_def, hXτ, sub_self] at this
  have hlim2 : Tendsto (fun n => ((T - r n : ℝ≥0) : ℝ)) atTop (𝓝 ((T - τ : ℝ≥0) : ℝ)) := by
    have hcont : Continuous (fun x : ℝ≥0 => ((T - x : ℝ≥0) : ℝ)) := by fun_prop
    exact (hcont.tendsto τ).comp hrlim
  have hG := (otnt_G_tendsto ν σ hσ ψ hψ C hC hψC p q hψc _ hs0).comp (hlim1.prodMk_nhds hlim2)
  refine hG.congr fun n => ?_
  simp only [Function.comp_apply]
  rw [(hj n).2.2.2]
  rfl

#print axioms otnt_Gn_tendsto

open Classical in

lemma otnt_limit_eq {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (hc : ∀ ω, Continuous (fun t => B t ω))
    (h0 : ∀ ω, B 0 ω = 0) (ν σ b : ℝ) (hσ : 0 < σ) (hb : 0 < b) (T : ℝ≥0) (hT : 0 < T)
    (ψ : ℝ → ℝ≥0∞) (hψ : Measurable ψ) (C : ℝ≥0∞) (hC : C ≠ ∞)
    (hψC : ∀ y, ψ y ≤ C) (p q : ℝ) (hψc : ∀ y, y ≠ p → y ≠ q → ContinuousAt ψ y) :
    ∫⁻ ω, (if otntHit B ν σ b T ω then ψ (otntX B ν σ T ω - b) else 0) ∂P =
      ∫⁻ ω, (if otntHit B ν σ b T ω ∧ otntTau B ν σ b ω < T then
        otntG ν σ ψ 0 ((T - otntTau B ν σ b ω : ℝ≥0) : ℝ) else 0) ∂P := by
  have hconst := otnt_lhs_eq_Gn hB hc h0 ν σ b hb T hT ψ hψ
  -- measurability of the grid sums
  have hmeas : ∀ n, AEMeasurable (otntGn B ν σ b T ψ n) P := by
    intro n
    have hWm : AEMeasurable (otntWc B T T) P :=
      AEMeasurable.of_eval (fun q => hB.aemeasurable _)
    set Φ : (ℚ → ℝ) → ℝ≥0∞ := fun c => ∑ k ∈ Finset.range (n + 1),
      (otntAset ν σ b T n k).indicator 1 c *
        otntG ν σ ψ (ν * (otntGrid T n (k + 1) : ℝ) + σ * c (((k + 1 : ℕ) : ℚ) / ((n : ℚ) + 1)) - b)
          ((T - otntGrid T n (k + 1) : ℝ≥0) : ℝ) with hΦ
    have hΦm : Measurable Φ := by
      refine Finset.measurable_sum _ fun k _ => ?_
      refine (measurable_const.indicator (otnt_measurableSet_Aset ν σ b T n k)).mul ?_
      exact (otnt_measurable_G ν σ ψ hψ _).comp (by fun_prop)
    refine (hΦm.comp_aemeasurable hWm).congr (ae_of_all _ fun ω => ?_)
    simp only [Function.comp_apply, hΦ, otntGn]
    refine Finset.sum_congr rfl fun k hk => ?_
    have hle : otntGrid T n (k + 1) ≤ T :=
      (otnt_grid_le T n (k + 1) (n + 1) (by have := Finset.mem_range.1 hk; omega)).trans
        (otnt_grid_last T n).le
    rw [otnt_ind_eq' B ν σ b T hT ω (hc ω) n k T hle, ite_mul, one_mul, zero_mul]
    congr 3
    simp only [otntX, otntWc, otntGrid] at hle ⊢
    rw [min_eq_left hle]
  -- the null set where the first touch is exactly at `T`
  have hnull : ∀ᵐ ω ∂P, B T ω ≠ (b - ν * T) / σ := by
    have : NullSingletonClass (gaussianReal 0 T) :=
      nullSingletonClass_gaussianReal (ne_of_gt hT)
    have h1 : ∀ᵐ x ∂(P.map (B T)), x ≠ (b - ν * T) / σ := by
      rw [(hB.hasLaw_eval T).map_eq]
      exact Measure.ae_ne _ _
    exact ae_of_ae_map (hB.aemeasurable T) h1
  have hlim : Tendsto (fun n => ∫⁻ ω, otntGn B ν σ b T ψ n ω ∂P) atTop
      (𝓝 (∫⁻ ω, (if otntHit B ν σ b T ω ∧ otntTau B ν σ b ω < T then
        otntG ν σ ψ 0 ((T - otntTau B ν σ b ω : ℝ≥0) : ℝ) else 0) ∂P)) := by
    refine tendsto_lintegral_of_dominated_convergence' (fun _ => C) hmeas ?_ (by simp [hC]) ?_
    · intro n
      refine ae_of_all _ fun ω => ?_
      have h := otnt_Gn_props B ν σ b hb T ψ ω (h0 ω) n
      by_cases hH : otntHit B ν σ b T ω
      · obtain ⟨j, -, -, -, hj⟩ := h.2 hH
        rw [hj]; exact otnt_G_le ν σ ψ C hψC _ _
      · rw [h.1 hH]; exact bot_le
    · filter_upwards [hnull] with ω hω
      by_cases hH : otntHit B ν σ b T ω
      · have hτT : otntTau B ν σ b ω < T := by
          obtain ⟨hiff, hXτ, -⟩ := otnt_tau_props B ν σ b hb T ω (hc ω) (h0 ω) hH
          refine lt_of_le_of_ne ((hiff T).1 hH) fun h => hω ?_
          rw [h] at hXτ
          simp only [otntX] at hXτ
          field_simp
          linarith
        rw [if_pos ⟨hH, hτT⟩]
        exact otnt_Gn_tendsto B ν σ b hσ hb T ψ hψ C hC hψC p q hψc ω (hc ω) (h0 ω) hH hτT
      · rw [if_neg (fun h => hH h.1)]
        refine tendsto_const_nhds.congr fun n => ?_
        rw [(otnt_Gn_props B ν σ b hb T ψ ω (h0 ω) n).1 hH]
  refine tendsto_nhds_unique (tendsto_const_nhds.congr fun n => hconst n) hlim

#print axioms otnt_limit_eq

/-- The truncated "finish below the barrier" payoff, in terms of `y = X_T - b`. -/

noncomputable def otntPsi1 (M : ℝ) : ℝ → ℝ≥0∞ := (Set.Ioo (-M) 0).indicator (fun _ => 1)

/-- The truncated mirror payoff, weighted by `e^{-2νy/σ²}`. -/

noncomputable def otntPsi2 (ν σ M : ℝ) : ℝ → ℝ≥0∞ :=
  (Set.Ioo 0 M).indicator (fun y => ENNReal.ofReal (Real.exp (-(2 * ν / σ ^ 2) * y)))

lemma otnt_measurable_psi1 (M : ℝ) : Measurable (otntPsi1 M) :=
  measurable_const.indicator measurableSet_Ioo

#print axioms otnt_measurable_psi1

lemma otnt_measurable_psi2 (ν σ M : ℝ) : Measurable (otntPsi2 ν σ M) :=
  (by fun_prop : Measurable fun y : ℝ => ENNReal.ofReal (Real.exp (-(2 * ν / σ ^ 2) * y))).indicator
    measurableSet_Ioo

#print axioms otnt_measurable_psi2

lemma otnt_G_reflect (ν σ : ℝ) (hσ : 0 < σ) (M s : ℝ) (hs : 0 < s) :
    otntG ν σ (otntPsi1 M) 0 s = otntG ν σ (otntPsi2 ν σ M) 0 s := by
  unfold otntG
  simp only [zero_add]
  rw [otnt_gauss_reflect (ν * s) (σ * √s) (by positivity) _ (otnt_measurable_psi1 M)]
  have hκ : 2 * (ν * s) / (σ * √s) ^ 2 = 2 * ν / σ ^ 2 := by
    rw [mul_pow, Real.sq_sqrt hs.le]; field_simp
  rw [hκ]
  congr 1
  ext u
  generalize ν * s + σ * √s * u = y
  by_cases hy : y ∈ Set.Ioo 0 M
  · have hy' : -y ∈ Set.Ioo (-M) 0 := ⟨by linarith [hy.2], by linarith [hy.1]⟩
    simp [otntPsi1, otntPsi2, Set.indicator_of_mem hy, Set.indicator_of_mem hy']
  · have hy' : -y ∉ Set.Ioo (-M) 0 := fun h => hy ⟨by linarith [h.2], by linarith [h.1]⟩
    simp [otntPsi1, otntPsi2, Set.indicator_of_notMem hy, Set.indicator_of_notMem hy']

#print axioms otnt_G_reflect

open Classical in

lemma otnt_LM_eq_RM {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (hc : ∀ ω, Continuous (fun t => B t ω))
    (h0 : ∀ ω, B 0 ω = 0) (ν σ b : ℝ) (hσ : 0 < σ) (hb : 0 < b) (T : ℝ≥0) (hT : 0 < T)
    (M : ℝ) :
    ∫⁻ ω, (if otntHit B ν σ b T ω then otntPsi1 M (otntX B ν σ T ω - b) else 0) ∂P =
      ∫⁻ ω, otntPsi2 ν σ M (otntX B ν σ T ω - b) ∂P := by
  have hR : ∀ ω, otntPsi2 ν σ M (otntX B ν σ T ω - b) =
      (if otntHit B ν σ b T ω then otntPsi2 ν σ M (otntX B ν σ T ω - b) else 0) := by
    intro ω
    by_cases hH : otntHit B ν σ b T ω
    · rw [if_pos hH]
    · rw [if_neg hH]
      have : otntX B ν σ T ω - b ∉ Set.Ioo 0 M := fun h => hH ⟨T, le_rfl, by linarith [h.1]⟩
      simp [otntPsi2, Set.indicator_of_notMem this]
  rw [lintegral_congr hR]
  have hC2 : ∀ y, otntPsi2 ν σ M y ≤ ENNReal.ofReal (Real.exp (|2 * ν / σ ^ 2| * |M|)) := by
    intro y
    by_cases hy : y ∈ Set.Ioo 0 M
    · rw [otntPsi2, Set.indicator_of_mem hy]
      refine ENNReal.ofReal_le_ofReal (Real.exp_le_exp.2 ?_)
      calc -(2 * ν / σ ^ 2) * y ≤ |-(2 * ν / σ ^ 2) * y| := le_abs_self _
        _ = |2 * ν / σ ^ 2| * |y| := by rw [abs_mul, abs_neg]
        _ ≤ |2 * ν / σ ^ 2| * |M| := by
          have : |y| ≤ |M| := by
            rw [abs_of_pos hy.1, abs_of_pos (hy.1.trans hy.2)]; exact hy.2.le
          exact mul_le_mul_of_nonneg_left this (abs_nonneg _)
    · rw [otntPsi2, Set.indicator_of_notMem hy]; exact bot_le
  have hC1 : ∀ y, otntPsi1 M y ≤ 1 := by
    intro y
    by_cases hy : y ∈ Set.Ioo (-M) 0
    · rw [otntPsi1, Set.indicator_of_mem hy]
    · rw [otntPsi1, Set.indicator_of_notMem hy]; exact bot_le
  rw [otnt_limit_eq hB hc h0 ν σ b hσ hb T hT (otntPsi1 M) (otnt_measurable_psi1 M) 1
      ENNReal.one_ne_top hC1 (-M) 0
      (fun y hp hq => otnt_indicator_continuousAt _ _ y _ continuous_const hp hq),
    otnt_limit_eq hB hc h0 ν σ b hσ hb T hT (otntPsi2 ν σ M) (otnt_measurable_psi2 ν σ M) _
      ENNReal.ofReal_ne_top hC2 0 M
      (fun y hp hq => otnt_indicator_continuousAt _ _ y _
        (ENNReal.continuous_ofReal.comp (by fun_prop)) hp hq)]
  congr 1
  ext ω
  split_ifs with h
  · exact otnt_G_reflect ν σ hσ M _ (NNReal.coe_pos.2 (tsub_pos_of_lt h.2))
  · rfl

#print axioms otnt_LM_eq_RM

lemma otnt_pt_one (T : ℝ≥0) : otntPt T 1 = T := by
  simp [otntPt]

#print axioms otnt_pt_one

open Classical in

lemma otnt_ite_hit {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ν σ b : ℝ) (T : ℝ≥0) (hT : 0 < T) (ω : Ω)
    (hc : Continuous (fun t => B t ω)) (f : ℝ≥0∞) :
    (if otntHit B ν σ b T ω then f else 0) =
      {c | otntHitC ν σ b T T c}.indicator 1 (otntWc B T T ω) * f := by
  have h := otnt_hit_iff B ν σ b T hT ω hc 1 T (by rw [otnt_pt_one])
  rw [otnt_pt_one] at h
  by_cases hH : otntHit B ν σ b T ω
  · rw [if_pos hH, Set.indicator_of_mem (show _ ∈ {c | otntHitC ν σ b T T c} from h.1 hH)]
    simp
  · rw [if_neg hH, Set.indicator_of_notMem (show _ ∉ {c | otntHitC ν σ b T T c} from
      fun h' => hH (h.2 h'))]
    simp

#print axioms otnt_ite_hit

lemma otnt_lintegral_XT {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (ν σ : ℝ) (T : ℝ≥0)
    (h : ℝ → ℝ≥0∞) (hh : Measurable h) :
    ∫⁻ ω, h (otntX B ν σ T ω) ∂P = otntG ν σ h 0 T := by
  rw [← otnt_gauss_scale h hh 0 ν σ T, ← (hB.hasLaw_eval T).map_eq,
    lintegral_map' (by fun_prop) (hB.aemeasurable T)]
  simp [otntX]

#print axioms otnt_lintegral_XT

lemma otnt_N01_preimage (a d : ℝ) (S : Set ℝ) (hS : MeasurableSet S) :
    ∫⁻ u, S.indicator 1 (a + d * u) ∂gaussianReal 0 1 =
      gaussianReal 0 1 ((fun u => a + d * u) ⁻¹' S) := by
  rw [← lintegral_indicator_one (hS.preimage (by fun_prop))]
  rfl

#print axioms otnt_N01_preimage

lemma otnt_N01_Ici (c : ℝ) :
    gaussianReal 0 1 (Set.Ici c) = ENNReal.ofReal (cdf (gaussianReal 0 1) (-c)) := by
  rw [cdf_eq_real, ofReal_measureReal]
  have h := (gaussianReal_map_neg (μ := 0) (v := 1))
  rw [neg_zero] at h
  conv_rhs => rw [← h]
  rw [Measure.map_apply (by fun_prop) measurableSet_Iic]
  congr 1
  ext x; simp

#print axioms otnt_N01_Ici

lemma otnt_N01_Iio (c : ℝ) :
    gaussianReal 0 1 (Set.Iio c) = ENNReal.ofReal (cdf (gaussianReal 0 1) c) := by
  have : NullSingletonClass (gaussianReal 0 1) := nullSingletonClass_gaussianReal one_ne_zero
  rw [cdf_eq_real, ofReal_measureReal]
  exact measure_congr Iio_ae_eq_Iic

#print axioms otnt_N01_Iio

lemma otnt_eventually_psi1 (y : ℝ) :
    Tendsto (fun M : ℕ => otntPsi1 M y) atTop (𝓝 ((Set.Iio 0).indicator 1 y)) := by
  refine tendsto_atTop_of_eventually_const (i₀ := ⌈|y|⌉₊ + 1) fun M hM => ?_
  have hM' : |y| < M := by
    have := Nat.le_ceil |y|
    have h2 : ((⌈|y|⌉₊ + 1 : ℕ) : ℝ) ≤ M := by exact_mod_cast hM
    push_cast at h2; linarith
  by_cases hy : y < 0
  · have h1 : y ∈ Set.Ioo (-(M : ℝ)) 0 := ⟨by linarith [neg_abs_le y], hy⟩
    simp [otntPsi1, Set.indicator_of_mem h1, Set.indicator_of_mem (show y ∈ Set.Iio 0 from hy)]
  · have h1 : y ∉ Set.Ioo (-(M : ℝ)) 0 := fun h => hy h.2
    simp [otntPsi1, Set.indicator_of_notMem h1,
      Set.indicator_of_notMem (show y ∉ Set.Iio 0 from hy)]

#print axioms otnt_eventually_psi1

lemma otnt_eventually_psi2 (ν σ y : ℝ) :
    Tendsto (fun M : ℕ => otntPsi2 ν σ M y) atTop
      (𝓝 ((Set.Ioi 0).indicator (fun y => ENNReal.ofReal (Real.exp (-(2 * ν / σ ^ 2) * y))) y)) := by
  refine tendsto_atTop_of_eventually_const (i₀ := ⌈|y|⌉₊ + 1) fun M hM => ?_
  have hM' : |y| < M := by
    have := Nat.le_ceil |y|
    have h2 : ((⌈|y|⌉₊ + 1 : ℕ) : ℝ) ≤ M := by exact_mod_cast hM
    push_cast at h2; linarith
  by_cases hy : 0 < y
  · have h1 : y ∈ Set.Ioo 0 (M : ℝ) := ⟨hy, by linarith [le_abs_self y]⟩
    simp [otntPsi2, Set.indicator_of_mem h1, Set.indicator_of_mem (show y ∈ Set.Ioi 0 from hy)]
  · have h1 : y ∉ Set.Ioo 0 (M : ℝ) := fun h => hy h.1
    simp [otntPsi2, Set.indicator_of_notMem h1,
      Set.indicator_of_notMem (show y ∉ Set.Ioi 0 from hy)]

#print axioms otnt_eventually_psi2

lemma otnt_mono_psi1 (y : ℝ) : Monotone (fun M : ℕ => otntPsi1 M y) := by
  intro M M' h
  refine Set.indicator_le_indicator_of_subset ?_ (fun _ => bot_le) y
  intro x hx
  exact ⟨lt_of_le_of_lt (neg_le_neg (by exact_mod_cast h)) hx.1, hx.2⟩

#print axioms otnt_mono_psi1

lemma otnt_mono_psi2 (ν σ y : ℝ) : Monotone (fun M : ℕ => otntPsi2 ν σ M y) := by
  intro M M' h
  refine Set.indicator_le_indicator_of_subset ?_ (fun _ => bot_le) y
  intro x hx
  exact ⟨hx.1, lt_of_lt_of_le hx.2 (by exact_mod_cast h)⟩

#print axioms otnt_mono_psi2

open Classical in

lemma otnt_core {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (hc : ∀ ω, Continuous (fun t => B t ω))
    (h0 : ∀ ω, B 0 ω = 0) (ν σ b : ℝ) (hσ : 0 < σ) (hb : 0 < b) (T : ℝ≥0) (hT : 0 < T) :
    P {ω | otntHit B ν σ b T ω} =
      ENNReal.ofReal (cdf (gaussianReal 0 1) ((ν * T - b) / (σ * √(T : ℝ)))) +
        ENNReal.ofReal (Real.exp (2 * ν / σ ^ 2 * b)) *
          ENNReal.ofReal (cdf (gaussianReal 0 1) ((-b - ν * T) / (σ * √(T : ℝ)))) := by
  set HC := {c | otntHitC ν σ b T T c} with hHC_def
  have hHC : MeasurableSet HC := otnt_measurableSet_hitC ν σ b T T
  have hWm : AEMeasurable (otntWc B T T) P := AEMeasurable.of_eval (fun q => hB.aemeasurable _)
  have hXm := otnt_aemeasurable_X hB ν σ T
  have hT' : (0 : ℝ) < T := hT
  have hd : 0 < σ * √(T : ℝ) := by positivity
  have hκ : 2 * (ν * T) / (σ * √(T : ℝ)) ^ 2 = 2 * ν / σ ^ 2 := by
    rw [mul_pow, Real.sq_sqrt hT'.le]; field_simp
  -- Step 1: the touch chance as an integral.
  have h1 : P {ω | otntHit B ν σ b T ω} =
      ∫⁻ ω, (if otntHit B ν σ b T ω then 1 else 0) ∂P := by
    have hset : {ω | otntHit B ν σ b T ω} = otntWc B T T ⁻¹' HC := by
      ext ω
      have h := otnt_hit_iff B ν σ b T hT ω (hc ω) 1 T (by rw [otnt_pt_one])
      rw [otnt_pt_one] at h
      exact h
    rw [hset, ← lintegral_indicator_one₀ (hWm.nullMeasurableSet_preimage hHC)]
    congr 1; ext ω
    rw [otnt_ite_hit B ν σ b T hT ω (hc ω), mul_one]
    simp [Set.indicator_apply, hHC_def]
  -- Step 2: split into "finish at or above b" and "touch, then finish below b".
  have h2 : ∀ ω, (if otntHit B ν σ b T ω then (1 : ℝ≥0∞) else 0) =
      (Set.Ici b).indicator 1 (otntX B ν σ T ω) +
        (if otntHit B ν σ b T ω then (Set.Iio 0).indicator 1 (otntX B ν σ T ω - b) else 0) := by
    intro ω
    by_cases hx : b ≤ otntX B ν σ T ω
    · have hH : otntHit B ν σ b T ω := ⟨T, le_rfl, hx⟩
      have hx' : otntX B ν σ T ω - b ∉ Set.Iio 0 := by simp; linarith
      simp [hH, Set.indicator_of_mem (show _ ∈ Set.Ici b from hx), Set.indicator_of_notMem hx']
    · have hx' : otntX B ν σ T ω - b ∈ Set.Iio 0 := by simp; linarith
      simp [Set.indicator_of_notMem (show _ ∉ Set.Ici b from hx), Set.indicator_of_mem hx']
  rw [h1, lintegral_congr h2, lintegral_add_left'
    (f := fun ω => (Set.Ici b).indicator 1 (otntX B ν σ T ω))
    ((measurable_const.indicator measurableSet_Ici).comp_aemeasurable hXm)]
  -- Step 3: the first piece.
  have h3 : ∫⁻ ω, (Set.Ici b).indicator 1 (otntX B ν σ T ω) ∂P =
      ENNReal.ofReal (cdf (gaussianReal 0 1) ((ν * T - b) / (σ * √(T : ℝ)))) := by
    rw [otnt_lintegral_XT hB ν σ T ((Set.Ici b).indicator 1)
      (measurable_const.indicator measurableSet_Ici), otntG]
    simp only [zero_add]
    rw [otnt_N01_preimage _ _ _ measurableSet_Ici]
    have : (fun u => ν * T + σ * √(T : ℝ) * u) ⁻¹' Set.Ici b =
        Set.Ici ((b - ν * T) / (σ * √(T : ℝ))) := by
      ext u
      simp only [Set.mem_preimage, Set.mem_Ici]
      rw [div_le_iff₀ hd]
      constructor <;> intro h <;> linarith
    rw [this, otnt_N01_Ici]
    congr 3
    ring
  -- Step 4: the second piece, through the truncations.
  set Rinf : ℝ → ℝ≥0∞ :=
    (Set.Ioi 0).indicator (fun y => ENNReal.ofReal (Real.exp (-(2 * ν / σ ^ 2) * y))) with hRinf
  have hRm : Measurable Rinf :=
    (by fun_prop : Measurable fun y : ℝ => ENNReal.ofReal (Real.exp (-(2 * ν / σ ^ 2) * y))).indicator
      measurableSet_Ioi
  have hL : Tendsto (fun M : ℕ => ∫⁻ ω, (if otntHit B ν σ b T ω then
        otntPsi1 M (otntX B ν σ T ω - b) else 0) ∂P) atTop
      (𝓝 (∫⁻ ω, (if otntHit B ν σ b T ω then
        (Set.Iio 0).indicator 1 (otntX B ν σ T ω - b) else 0) ∂P)) := by
    refine lintegral_tendsto_of_tendsto_of_monotone (fun M => ?_) (ae_of_all _ fun ω => ?_)
      (ae_of_all _ fun ω => ?_)
    · have : (fun ω => if otntHit B ν σ b T ω then otntPsi1 M (otntX B ν σ T ω - b) else 0) =
          fun ω => HC.indicator 1 (otntWc B T T ω) * otntPsi1 M (otntX B ν σ T ω - b) := by
        ext ω; exact otnt_ite_hit B ν σ b T hT ω (hc ω) _
      rw [this]
      exact ((measurable_const.indicator hHC).comp_aemeasurable hWm).mul
        ((otnt_measurable_psi1 _).comp_aemeasurable (hXm.sub_const b))
    · intro M M' h
      by_cases hH : otntHit B ν σ b T ω
      · simp only [hH, if_true]; exact otnt_mono_psi1 _ h
      · simp [hH]
    · by_cases hH : otntHit B ν σ b T ω
      · simp only [hH, if_true]; exact otnt_eventually_psi1 _
      · simp only [hH, if_false]; exact tendsto_const_nhds
  have hR : Tendsto (fun M : ℕ => ∫⁻ ω, otntPsi2 ν σ M (otntX B ν σ T ω - b) ∂P) atTop
      (𝓝 (∫⁻ ω, Rinf (otntX B ν σ T ω - b) ∂P)) := by
    refine lintegral_tendsto_of_tendsto_of_monotone (fun M => ?_) (ae_of_all _ fun ω => ?_)
      (ae_of_all _ fun ω => ?_)
    · exact (otnt_measurable_psi2 _ _ _).comp_aemeasurable (hXm.sub_const b)
    · intro M M' h; exact otnt_mono_psi2 _ _ _ h
    · exact otnt_eventually_psi2 _ _ _
  have hLR : (fun M : ℕ => ∫⁻ ω, (if otntHit B ν σ b T ω then
        otntPsi1 M (otntX B ν σ T ω - b) else 0) ∂P) =
      fun M : ℕ => ∫⁻ ω, otntPsi2 ν σ M (otntX B ν σ T ω - b) ∂P := by
    ext M; exact otnt_LM_eq_RM hB hc h0 ν σ b hσ hb T hT M
  rw [hLR] at hL
  rw [h3, tendsto_nhds_unique hL hR]
  congr 1
  -- Step 5: the mirror piece is a Gaussian tail after reflection.
  rw [otnt_lintegral_XT hB ν σ T (fun x => Rinf (x - b)) (hRm.comp (measurable_id.sub_const b)),
    otntG]
  simp only [zero_add]
  have hpt : ∀ u, Rinf (ν * T + σ * √(T : ℝ) * u - b) =
      ENNReal.ofReal (Real.exp (2 * ν / σ ^ 2 * b)) *
        ((Set.Iio (-b)).indicator 1 (-(ν * T + σ * √(T : ℝ) * u)) *
          ENNReal.ofReal (Real.exp (-(2 * (ν * T) / (σ * √(T : ℝ)) ^ 2) *
            (ν * T + σ * √(T : ℝ) * u)))) := by
    intro u
    rw [hκ]
    generalize ν * T + σ * √(T : ℝ) * u = x
    by_cases hx : b < x
    · have h1 : x - b ∈ Set.Ioi 0 := by simp; linarith
      have h2 : -x ∈ Set.Iio (-b) := by simp; linarith
      rw [hRinf, Set.indicator_of_mem h1, Set.indicator_of_mem h2, Pi.one_apply, one_mul,
        ← ENNReal.ofReal_mul (Real.exp_pos _).le, ← Real.exp_add]
      congr 2; ring
    · have h1 : x - b ∉ Set.Ioi 0 := by simp; linarith
      have h2 : -x ∉ Set.Iio (-b) := by simp; linarith
      rw [hRinf, Set.indicator_of_notMem h1, Set.indicator_of_notMem h2]
      simp
  simp_rw [hpt]
  have hgm : Measurable ((Set.Iio (-b)).indicator (1 : ℝ → ℝ≥0∞)) :=
    measurable_const.indicator measurableSet_Iio
  rw [lintegral_const_mul' _ _ ENNReal.ofReal_ne_top,
    ← otnt_gauss_reflect (ν * T) (σ * √(T : ℝ)) hd.ne' _ hgm,
    otnt_N01_preimage _ _ _ measurableSet_Iio]
  have : (fun u => ν * T + σ * √(T : ℝ) * u) ⁻¹' Set.Iio (-b) =
      Set.Iio ((-b - ν * T) / (σ * √(T : ℝ))) := by
    ext u
    simp only [Set.mem_preimage, Set.mem_Iio]
    rw [lt_div_iff₀ hd]
    constructor <;> intro h <;> linarith
  rw [this, otnt_N01_Iio]

#print axioms otnt_core

end OneTouchHelpers

/-- The touch chance. Let `B` be a Brownian motion under the pretend-world measure `P`, and let
Acme's price be `S * exp (ν t + σ B t)` with log drift `ν = r - q - σ²/2`. For a barrier `H`
above today's price `S`, the chance that the price reaches `H` at some moment up to `T` is
`N((νT - b)/(σ√T)) + (H/S)^(2ν/σ²) N((-b - νT)/(σ√T))`, where `b = ln(H/S)` and `N` is the
standard normal distribution function. The one-touch paid at expiry is `e^(-rT)` times this. -/
theorem touch_probability_reflection_formula
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P)
    (S H r q σ : ℝ) (T : ℝ≥0) (hS : 0 < S) (hSH : S < H) (hσ : 0 < σ) (hT : 0 < T) :
    let ν := r - q - σ ^ 2 / 2
    let b := Real.log (H / S)
    P.real {ω | ∃ t : ℝ≥0, t ≤ T ∧ H ≤ S * Real.exp (ν * t + σ * B t ω)} =
      cdf (gaussianReal 0 1) ((ν * T - b) / (σ * Real.sqrt T)) +
        (H / S) ^ (2 * ν / σ ^ 2) * cdf (gaussianReal 0 1) ((-b - ν * T) / (σ * Real.sqrt T)) := by
  intro ν b
  set good : Set Ω := {ω | Continuous (fun t => B t ω) ∧ B 0 ω = 0} with hgood_def
  have hgood : ∀ᵐ ω ∂P, ω ∈ good := by
    filter_upwards [hB.cont, hB.eval_zero_ae_eq_zero] with ω h1 h2
    exact ⟨h1, h2⟩
  set B' : ℝ≥0 → Ω → ℝ := fun t => good.indicator (B t) with hB'_def
  have hB' : IsPreBrownianReal B' P := by
    refine hB.toIsPreBrownianReal.congr fun t => ?_
    filter_upwards [hgood] with ω hω
    simp [hB'_def, Set.indicator_of_mem hω]
  have hc' : ∀ ω, Continuous (fun t => B' t ω) := by
    intro ω
    by_cases hω : ω ∈ good
    · simp only [hB'_def, Set.indicator_of_mem hω]; exact hω.1
    · simp only [hB'_def, Set.indicator_of_notMem hω]; exact continuous_const
  have h0' : ∀ ω, B' 0 ω = 0 := by
    intro ω
    by_cases hω : ω ∈ good
    · simp only [hB'_def, Set.indicator_of_mem hω]; exact hω.2
    · simp only [hB'_def, Set.indicator_of_notMem hω]
  have hHS : 0 < H / S := div_pos (hS.trans hSH) hS
  have hb : 0 < b := Real.log_pos ((one_lt_div hS).2 hSH)
  have hcore := otnt_core hB' hc' h0' ν σ b hσ hb T hT
  have hset : {ω | ∃ t : ℝ≥0, t ≤ T ∧ H ≤ S * Real.exp (ν * t + σ * B t ω)} =ᵐ[P]
      {ω | otntHit B' ν σ b T ω} := by
    refine Filter.eventuallyEq_set.2 ?_
    filter_upwards [hgood] with ω hω
    have hBB : ∀ t, B' t ω = B t ω := fun t => by simp [hB'_def, Set.indicator_of_mem hω]
    have hiff : ∀ x : ℝ, H ≤ S * Real.exp x ↔ b ≤ x := by
      intro x
      rw [← div_le_iff₀' hS, Real.log_le_iff_le_exp hHS]
    simp only [otntHit, otntX, hBB, hiff]
  rw [measureReal_def, measure_congr hset, hcore,
    ENNReal.toReal_add (by simp) (by finiteness), ENNReal.toReal_mul,
    ENNReal.toReal_ofReal (cdf_nonneg _ _), ENNReal.toReal_ofReal (Real.exp_pos _).le,
    ENNReal.toReal_ofReal (cdf_nonneg _ _), Real.rpow_def_of_pos hHS, mul_comm (Real.log (H / S))]

/-- Model-free parity. Whatever the price paths `X` and whatever the pretend-world measure `P`,
the one-touch paid at expiry (a discounted dollar if the path reaches `H` by time `T`) plus the
no-touch (a discounted dollar if it never does) costs exactly a dollar due at `T`, `e^(-rT)`. -/
theorem one_touch_add_no_touch_eq_discount
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℝ≥0 → Ω → ℝ) (H r : ℝ) (T : ℝ≥0)
    (hmeas : NullMeasurableSet {ω | ∃ t : ℝ≥0, t ≤ T ∧ H ≤ X t ω} P) :
    Real.exp (-r * T) * P.real {ω | ∃ t : ℝ≥0, t ≤ T ∧ H ≤ X t ω} +
      Real.exp (-r * T) * P.real {ω | ¬ ∃ t : ℝ≥0, t ≤ T ∧ H ≤ X t ω} = Real.exp (-r * T) := by
  have h := measureReal_add_measureReal_compl₀ (μ := P) hmeas
  rw [← mul_add]
  rw [show {ω | ¬∃ t : ℝ≥0, t ≤ T ∧ H ≤ X t ω} = {ω | ∃ t : ℝ≥0, t ≤ T ∧ H ≤ X t ω}ᶜ from rfl, h,
    probReal_univ, mul_one]

/-- The steeper drift. For a rate `r ≥ 0`, the first-passage density to the log level `b` with
drift `ν`, `f(t) = b / (σ √(2π t³)) · exp(-(b - ν t)² / (2σ² t))`, discounted by `e^(-rt)`, equals
the constant `e^(b(ν - ν̃)/σ²)` times the same density with the steeper drift
`ν̃ = √(ν² + 2rσ²)`. Adding it up over `0..T` gives the one-touch paid at the hit. -/
theorem discounted_first_passage_density_steeper_drift
    (b ν r σ t : ℝ) (hr : 0 ≤ r) (hσ : 0 < σ) (ht : 0 < t) :
    let νt := Real.sqrt (ν ^ 2 + 2 * r * σ ^ 2)
    Real.exp (-r * t) *
        (b / (σ * Real.sqrt (2 * π * t ^ 3)) * Real.exp (-(b - ν * t) ^ 2 / (2 * σ ^ 2 * t))) =
      Real.exp (b * (ν - νt) / σ ^ 2) *
        (b / (σ * Real.sqrt (2 * π * t ^ 3)) * Real.exp (-(b - νt * t) ^ 2 / (2 * σ ^ 2 * t))) := by
  intro νt
  have hsq : νt ^ 2 = ν ^ 2 + 2 * r * σ ^ 2 := Real.sq_sqrt (by positivity)
  rw [mul_left_comm, ← Real.exp_add, mul_left_comm (Real.exp _), ← Real.exp_add]
  congr 2
  field_simp
  linear_combination t ^ 2 * hsq

-- The house market: r = 5%, q = 2%, σ = 20%. The log drift ν = r - q - σ²/2 is 1/100.
example : (5 / 100 : ℚ) - 2 / 100 - (20 / 100) ^ 2 / 2 = 1 / 100 := by norm_num
-- The mirror weight's exponent 2ν/σ² is 1/2, so the weight is 1.2^(1/2).
example : 2 * (1 / 100 : ℚ) / (20 / 100) ^ 2 = 1 / 2 := by norm_num
-- The steeper drift squared: ν² + 2rσ² = 0.0001 + 2 × 0.05 × 0.04 = 41/10000.
example : (1 / 100 : ℚ) ^ 2 + 2 * (5 / 100) * (20 / 100) ^ 2 = 41 / 10000 := by norm_num
-- The payoff picture: at every year's high on the chart, one-touch plus no-touch pays exactly 1.
example : ∀ h ∈ [100, 105, 110, 115, 119, 120, 125, 130],
    (if 120 ≤ h then 1 else 0) + (if 120 ≤ h then 0 else 1) = 1 := by decide

#print axioms touch_probability_reflection_formula
#print axioms one_touch_add_no_touch_eq_discount
#print axioms discounted_first_passage_density_steeper_drift
