-- Wiener's Tauberian theorem: the shifts of an integrable signal can be mixed to approach every integrable signal in area exactly when its Fourier transform has no zero, and then a limit of averages taken with that signal as weight passes to every integrable weight.
import Mathlib.Analysis.Fourier.FourierTransform
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.Analysis.Fourier.Convolution
import Mathlib.MeasureTheory.Function.ContinuousMapDense
import Mathlib.Topology.UniformSpace.UniformApproximation

/-! Signals are complex-valued functions of time `t : ℝ` in seconds. `𝓕 f ξ` is Mathlib's Fourier
transform in hertz, `∫ e^(−2πiξt) f(t) dt`, the card's `f̂(ξ)`. "In `L¹(ℝ)`" is `Integrable`, and
the area distance `‖g − h‖₁` is `∫ t, ‖g t − h t‖`. A mix of shifts with `K` firings, gains `w k`
and delays `s k` is `∑ k, w k * f (t − s k)`. The average of `y` weighted by `g` at time `x`,
the card's `(g * y)(x)`, is written out as `∫ s, g s * y (x − s)`. A bounded recording is a
measurable `y` with `‖y t‖ ≤ B` for every `t`. -/

open MeasureTheory FourierTransform Filter Topology

/-! ### Helper lemmas for the proofs below -/

lemma wt_e_cont : Continuous (fun x : ℝ => ((𝐞 x : Circle) : ℂ)) := by
  have : (fun x : ℝ => ((𝐞 x : Circle) : ℂ)) = fun x => Complex.exp (↑(2 * Real.pi * x) * Complex.I) := by
    funext x; exact Real.fourierChar_apply x
  rw [this]; fun_prop

lemma wt_e_norm (x : ℝ) : ‖((𝐞 x : Circle) : ℂ)‖ = 1 := Circle.norm_coe _

/-- The bump on the frequency line: 1 on `[-1, 1]`, 0 outside `(-2, 2)`. -/
noncomputable def wtBump : ContDiffBump (0 : ℝ) := ⟨1, 2, one_pos, one_lt_two⟩

noncomputable def wtPhi : ℝ → ℂ := fun ξ => ((wtBump ξ : ℝ) : ℂ)

lemma wtPhi_contDiff : ContDiff ℝ (↑(⊤ : ℕ∞)) wtPhi :=
  Complex.ofRealCLM.contDiff.comp wtBump.contDiff

lemma wtPhi_hcs : HasCompactSupport wtPhi :=
  wtBump.hasCompactSupport.comp_left Complex.ofReal_zero

noncomputable def wtS : SchwartzMap ℝ ℂ := wtPhi_hcs.toSchwartzMap wtPhi_contDiff

/-- The plateau signal: its transform is the bump. -/
noncomputable def wtSi : SchwartzMap ℝ ℂ := 𝓕⁻ wtS

noncomputable def wtP : ℝ → ℂ := ⇑wtSi

lemma wtP_int : Integrable wtP := wtSi.integrable

lemma wtP_cont : Continuous wtP := wtSi.continuous

lemma wtP_bdd : ∃ C, 0 ≤ C ∧ ∀ t, ‖wtP t‖ ≤ C :=
  ⟨SchwartzMap.seminorm ℝ 0 0 wtSi, apply_nonneg _ _,
    fun t => SchwartzMap.norm_le_seminorm ℝ wtSi t⟩

lemma wtP_fourier (ξ : ℝ) : 𝓕 wtP ξ = ((wtBump ξ : ℝ) : ℂ) := by
  have h := congrArg (fun F : SchwartzMap ℝ ℂ => (F : ℝ → ℂ) ξ)
    (FourierTransform.fourier_fourierInv_eq (F := SchwartzMap ℝ ℂ) wtS)
  simp only [SchwartzMap.fourier_coe] at h
  rw [wtP, wtSi, h]
  simp [wtS, wtPhi]

lemma wtP_fourier_one {ξ : ℝ} (h : |ξ| ≤ 1) : 𝓕 wtP ξ = 1 := by
  rw [wtP_fourier, wtBump.one_of_mem_closedBall]
  · simp
  · simpa [Metric.mem_closedBall, Real.dist_eq, wtBump] using h

lemma wtP_fourier_zero {ξ : ℝ} (h : 2 ≤ |ξ|) : 𝓕 wtP ξ = 0 := by
  rw [wtP_fourier, wtBump.zero_of_le_dist]
  · simp
  · simpa [Real.dist_eq, wtBump] using h

/-- Modulated, dilated plateau: `e^(2πiξ₀t) · a · P(a t)`. -/
noncomputable def wtQ (a ξ₀ : ℝ) (t : ℝ) : ℂ := ((𝐞 (ξ₀ * t) : Circle) : ℂ) * ((a : ℂ) * wtP (a * t))

lemma wtQ_cont (a ξ₀ : ℝ) : Continuous (wtQ a ξ₀) := by
  unfold wtQ
  exact (wt_e_cont.comp (continuous_const.mul continuous_id)).mul
    (continuous_const.mul (wtP_cont.comp (continuous_const.mul continuous_id)))

lemma wtQ_int {a : ℝ} (ha : 0 < a) (ξ₀ : ℝ) : Integrable (wtQ a ξ₀) := by
  have h1 : Integrable (fun t => (a : ℂ) * wtP (a * t)) :=
    (wtP_int.comp_mul_left' ha.ne').const_mul _
  refine h1.bdd_mul (c := 1) ?_ (Eventually.of_forall fun t => (wt_e_norm _).le)
  exact (wt_e_cont.comp (continuous_const.mul continuous_id)).aestronglyMeasurable

lemma wtQ_bdd {a : ℝ} (ha : 0 < a) (ξ₀ : ℝ) : ∃ C, 0 ≤ C ∧ ∀ t, ‖wtQ a ξ₀ t‖ ≤ C := by
  obtain ⟨C, hC0, hC⟩ := wtP_bdd
  refine ⟨a * C, by positivity, fun t => ?_⟩
  simp only [wtQ, norm_mul, wt_e_norm, one_mul, Complex.norm_real, Real.norm_of_nonneg ha.le]
  exact mul_le_mul_of_nonneg_left (hC _) ha.le

lemma wtQ_fourier {a : ℝ} (ha : 0 < a) (ξ₀ η : ℝ) :
    𝓕 (wtQ a ξ₀) η = 𝓕 wtP ((η - ξ₀) / a) := by
  rw [Real.fourier_real_eq, Real.fourier_real_eq]
  have key : ∀ v : ℝ, 𝐞 (-(v * η)) • wtQ a ξ₀ v
      = (a : ℂ) • (𝐞 (-((a * v) * ((η - ξ₀) / a))) • wtP (a * v)) := by
    intro v
    simp only [wtQ, Circle.smul_def, smul_eq_mul]
    rw [show -((a * v) * ((η - ξ₀) / a)) = -(v * η) + ξ₀ * v by field_simp; ring,
      AddChar.map_add_eq_mul, Circle.coe_mul]
    ring
  simp_rw [key]
  rw [integral_smul, Measure.integral_comp_mul_left
    (fun u => 𝐞 (-(u * ((η - ξ₀) / a))) • wtP u) a, abs_inv, abs_of_pos ha,
    Complex.real_smul, smul_eq_mul, ← mul_assoc]
  push_cast
  rw [mul_inv_cancel₀ (by exact_mod_cast ha.ne'), one_mul]
  
lemma wtQ_fourier_one {a : ℝ} (ha : 0 < a) {ξ₀ η : ℝ} (h : |η - ξ₀| ≤ a) :
    𝓕 (wtQ a ξ₀) η = 1 := by
  rw [wtQ_fourier ha]
  apply wtP_fourier_one
  rw [abs_div, abs_of_pos ha, div_le_one ha]; exact h

lemma wtQ_fourier_zero {a : ℝ} (ha : 0 < a) {ξ₀ η : ℝ} (h : 2 * a ≤ |η - ξ₀|) :
    𝓕 (wtQ a ξ₀) η = 0 := by
  rw [wtQ_fourier ha]
  apply wtP_fourier_zero
  rw [abs_div, abs_of_pos ha, le_div_iff₀ ha]; exact h

/-! ### Fourier transform: simple rules -/

lemma wt_fint {a : ℝ → ℂ} (ha : Integrable a) (w : ℝ) :
    Integrable (fun v : ℝ => 𝐞 (-(v * w)) • a v) := by
  have := (Real.fourierIntegral_convergent_iff (μ := volume) (f := a) w).2 ha
  simpa [mul_comm] using this

lemma wt_fourier_sub {a b : ℝ → ℂ} (ha : Integrable a) (hb : Integrable b) (w : ℝ) :
    𝓕 (fun x => a x - b x) w = 𝓕 a w - 𝓕 b w := by
  simp only [Real.fourier_real_eq, smul_sub]
  exact integral_sub (wt_fint ha w) (wt_fint hb w)

lemma wt_fourier_add {a b : ℝ → ℂ} (ha : Integrable a) (hb : Integrable b) (w : ℝ) :
    𝓕 (fun x => a x + b x) w = 𝓕 a w + 𝓕 b w := by
  simp only [Real.fourier_real_eq, smul_add]
  exact integral_add (wt_fint ha w) (wt_fint hb w)

lemma wt_fourier_const_mul (a : ℝ → ℂ) (c : ℂ) (w : ℝ) :
    𝓕 (fun x => c * a x) w = c * 𝓕 a w := by
  simp only [Real.fourier_real_eq, Circle.smul_def, smul_eq_mul]
  rw [← integral_const_mul]
  congr 1 with v
  ring

lemma wt_fourier_sum {ι : Type*} (S : Finset ι) {a : ι → ℝ → ℂ} (ha : ∀ i ∈ S, Integrable (a i))
    (w : ℝ) : 𝓕 (fun x => ∑ i ∈ S, a i x) w = ∑ i ∈ S, 𝓕 (a i) w := by
  simp only [Real.fourier_real_eq, Finset.smul_sum]
  exact integral_finsetSum S fun i hi => wt_fint (ha i hi) w

lemma wt_fourier_shift (a : ℝ → ℂ) (s w : ℝ) :
    𝓕 (fun x => a (x - s)) w = ((𝐞 (-(s * w)) : Circle) : ℂ) * 𝓕 a w := by
  simp only [Real.fourier_real_eq, Circle.smul_def, smul_eq_mul]
  rw [← integral_const_mul, ← integral_sub_right_eq_self _ (-s)]
  congr 1 with v
  rw [show v - -s - s = v by ring, show -((v - -s) * w) = -(s * w) + -(v * w) by ring,
    AddChar.map_add_eq_mul, Circle.coe_mul]
  ring

lemma wt_fourier_zero_eq (a : ℝ → ℂ) : 𝓕 a 0 = ∫ x, a x := by
  simp [Real.fourier_real_eq]

/-! ### Convolution -/

/-- Convolution `(a ⋆ b)(x) = ∫ a(t) b(x − t) dt`. -/
noncomputable def wtC (a b : ℝ → ℂ) : ℝ → ℂ :=
  convolution a b (ContinuousLinearMap.mul ℂ ℂ) volume

lemma wtC_apply (a b : ℝ → ℂ) (x : ℝ) : wtC a b x = ∫ t, a t * b (x - t) := by
  simp [wtC, convolution_def]

lemma wtC_int {a b : ℝ → ℂ} (ha : Integrable a) (hb : Integrable b) : Integrable (wtC a b) :=
  ha.integrable_convolution _ hb

lemma wtC_fourier {a b : ℝ → ℂ} (ha : Integrable a) (hb : Integrable b) (w : ℝ) :
    𝓕 (wtC a b) w = 𝓕 a w * 𝓕 b w :=
  Real.fourier_mul_convolution_eq ha hb w

lemma wtC_cont_left {a b : ℝ → ℂ} (ha : Continuous a) (hab : ∃ C, ∀ t, ‖a t‖ ≤ C)
    (hb : Integrable b) : Continuous (wtC a b) := by
  obtain ⟨C, hC⟩ := hab
  exact BddAbove.continuous_convolution_left_of_integrable _
    ⟨C, by rintro _ ⟨t, rfl⟩; exact hC t⟩ ha hb

lemma wtC_norm_le {a b : ℝ → ℂ} (ha : Integrable a) (hb : Integrable b) :
    ∫ x, ‖wtC a b x‖ ≤ (∫ x, ‖a x‖) * ∫ x, ‖b x‖ := by
  have hn : Integrable (convolution (fun x => ‖a x‖) (fun x => ‖b x‖)
      (ContinuousLinearMap.mul ℝ ℝ) volume) :=
    ha.norm.integrable_convolution _ hb.norm
  calc ∫ x, ‖wtC a b x‖
      ≤ ∫ x, convolution (fun x => ‖a x‖) (fun x => ‖b x‖) (ContinuousLinearMap.mul ℝ ℝ) volume x := by
        refine integral_mono (wtC_int ha hb).norm hn fun x => ?_
        rw [wtC_apply, convolution_def]
        refine (norm_integral_le_integral_norm _).trans (le_of_eq ?_)
        simp
    _ = (∫ x, ‖a x‖) * ∫ x, ‖b x‖ := by
        rw [integral_convolution (ContinuousLinearMap.mul ℝ ℝ) ha.norm hb.norm]
        simp

lemma wtC_sub_left_ae {a a' b : ℝ → ℂ} (ha : Integrable a) (ha' : Integrable a')
    (hb : Integrable b) :
    (fun x => wtC a b x - wtC a' b x) =ᵐ[volume] wtC (fun t => a t - a' t) b := by
  filter_upwards [ha.ae_convolution_exists (ContinuousLinearMap.mul ℂ ℂ) hb,
    ha'.ae_convolution_exists (ContinuousLinearMap.mul ℂ ℂ) hb] with x h1 h2
  have i1 : Integrable (fun t => a t * b (x - t)) := by simpa [ConvolutionExistsAt] using h1
  have i2 : Integrable (fun t => a' t * b (x - t)) := by simpa [ConvolutionExistsAt] using h2
  rw [wtC_apply, wtC_apply, wtC_apply, ← integral_sub i1 i2]
  congr 1 with t
  ring

/-! ### The translation modulus `ω_F(u) = ∫ ‖F(t − u) − F(t)‖ dt` -/

lemma wt_omega_le (f : ℝ → ℂ) (hf : Integrable f) (u : ℝ) :
    ∫ t, ‖f (t - u) - f t‖ ≤ 2 * ∫ t, ‖f t‖ := by
  have h1 : Integrable (fun t ↦ f (t - u)) := hf.comp_sub_right u
  calc ∫ t, ‖f (t - u) - f t‖ ≤ ∫ t, (‖f (t - u)‖ + ‖f t‖) :=
        integral_mono (h1.sub hf).norm (h1.norm.add hf.norm) (fun t ↦ norm_sub_le _ _)
    _ = 2 * ∫ t, ‖f t‖ := by
        rw [integral_add h1.norm hf.norm, integral_sub_right_eq_self (fun t ↦ ‖f t‖) u]
        ring

lemma wt_omega_cc (g : ℝ → ℂ) (hg : Continuous g) (hs : HasCompactSupport g) :
    Continuous (fun u ↦ ∫ t, ‖g (t - u) - g t‖) := by
  obtain ⟨R, hR⟩ := hs.isCompact.isBounded.subset_closedBall 0
  obtain ⟨C, hC⟩ := hg.bounded_above_of_compact_support hs
  have hgi : Integrable g := hg.integrable_of_hasCompactSupport hs
  refine continuous_iff_continuousAt.2 fun u₀ ↦ ?_
  refine continuousAt_of_dominated (bound := fun t ↦
    (Set.Icc (u₀ - R - 1) (u₀ + R + 1)).indicator (fun _ ↦ C) t + ‖g t‖) ?_ ?_ ?_ ?_
  · exact Eventually.of_forall fun u ↦ by
      apply Continuous.aestronglyMeasurable; fun_prop
  · filter_upwards [Metric.ball_mem_nhds u₀ one_pos] with u hu
    refine Eventually.of_forall fun t ↦ ?_
    rw [norm_norm]
    refine (norm_sub_le _ _).trans ?_
    gcongr
    by_cases ht : t ∈ Set.Icc (u₀ - R - 1) (u₀ + R + 1)
    · rw [Set.indicator_of_mem ht]; exact hC _
    · rw [Set.indicator_of_notMem ht]
      have hu' : |u - u₀| < 1 := by simpa [Metric.mem_ball, Real.dist_eq] using hu
      have : t - u ∉ tsupport g := by
        intro hm
        have hm' := hR hm
        rw [Metric.mem_closedBall, dist_zero_right, Real.norm_eq_abs] at hm'
        apply ht
        rw [abs_le] at hm'
        rw [abs_lt] at hu'
        constructor <;> linarith [hm'.1, hm'.2, hu'.1, hu'.2]
      rw [image_eq_zero_of_notMem_tsupport this, norm_zero]
  · refine Integrable.add ?_ hgi.norm
    exact (continuous_const.integrableOn_Icc).integrable_indicator measurableSet_Icc
  · refine Eventually.of_forall fun t ↦ ?_
    apply Continuous.continuousAt
    fun_prop

lemma wt_omega_cont (f : ℝ → ℂ) (hf : Integrable f) :
    Continuous (fun u ↦ ∫ t, ‖f (t - u) - f t‖) := by
  refine continuous_of_uniform_approx_of_continuous fun V hV ↦ ?_
  obtain ⟨δ, δpos, hδ⟩ := Metric.mem_uniformity_dist.1 hV
  obtain ⟨g, hgs, hfg, hgc, hgi⟩ := hf.exists_hasCompactSupport_integral_sub_le (ε := δ / 3)
    (by positivity)
  refine ⟨_, wt_omega_cc g hgc hgs, fun u ↦ hδ ?_⟩
  have h1 : Integrable (fun t ↦ f (t - u)) := hf.comp_sub_right u
  have h2 : Integrable (fun t ↦ g (t - u)) := hgi.comp_sub_right u
  have h3 : Integrable (fun t ↦ f (t - u) - g (t - u)) := h1.sub h2
  have h4 : Integrable (fun t ↦ f t - g t) := hf.sub hgi
  have i1 : Integrable (fun t ↦ ‖f (t - u) - f t‖) := (h1.sub hf).norm
  have i2 : Integrable (fun t ↦ ‖g (t - u) - g t‖) := (h2.sub hgi).norm
  rw [Real.dist_eq, ← integral_sub i1 i2]
  calc |∫ t, (‖f (t - u) - f t‖ - ‖g (t - u) - g t‖)|
      ≤ ∫ t, |‖f (t - u) - f t‖ - ‖g (t - u) - g t‖| := by
        simpa only [Real.norm_eq_abs] using
          norm_integral_le_integral_norm (fun t ↦ ‖f (t - u) - f t‖ - ‖g (t - u) - g t‖)
    _ ≤ ∫ t, (‖f (t - u) - g (t - u)‖ + ‖f t - g t‖) := by
        refine integral_mono (i1.sub i2).abs (h3.norm.add h4.norm)
          fun t ↦ ?_
        refine (abs_norm_sub_norm_le _ _).trans ?_
        calc ‖f (t - u) - f t - (g (t - u) - g t)‖
            = ‖(f (t - u) - g (t - u)) - (f t - g t)‖ := by ring_nf
          _ ≤ _ := norm_sub_le _ _
    _ = 2 * ∫ t, ‖f t - g t‖ := by
        rw [integral_add h3.norm h4.norm,
          integral_sub_right_eq_self (fun t ↦ ‖f t - g t‖) u]
        ring
    _ < δ := by linarith

lemma wt_omega_zero (f : ℝ → ℂ) : (∫ t, ‖f (t - 0) - f t‖) = 0 := by simp

/-! ### Minkowski's inequality for the averaged difference -/

lemma wt_mink {K F : ℝ → ℂ} (hK : Integrable K) (hF : Integrable F) :
    ∫ x, ‖∫ s, K s * (F (x - s) - F x)‖ ≤ ∫ s, ‖K s‖ * ∫ x, ‖F (x - s) - F x‖ := by
  set ω : ℝ → ℝ := fun u ↦ ∫ t, ‖F (t - u) - F t‖ with hω
  have hωc : Continuous ω := wt_omega_cont F hF
  have hω0 : ∀ u, 0 ≤ ω u := fun u ↦ integral_nonneg fun t ↦ norm_nonneg _
  have hωb : ∀ u, ω u ≤ 2 * ∫ t, ‖F t‖ := wt_omega_le F hF
  set H : ℝ × ℝ → ℝ := fun p ↦ ‖K p.2‖ * ‖F (p.1 - p.2) - F p.1‖ with hH
  have hHm : AEStronglyMeasurable H (volume.prod volume) := by
    have a1 : AEStronglyMeasurable (fun p : ℝ × ℝ ↦ F (p.1 - p.2)) (volume.prod volume) :=
      hF.aestronglyMeasurable.comp_quasiMeasurePreserving
        (quasiMeasurePreserving_sub_of_right_invariant volume volume)
    have a2 : AEStronglyMeasurable (fun p : ℝ × ℝ ↦ F p.1) (volume.prod volume) :=
      hF.aestronglyMeasurable.comp_fst
    have a3 : AEStronglyMeasurable (fun p : ℝ × ℝ ↦ K p.2) (volume.prod volume) :=
      hK.aestronglyMeasurable.comp_snd
    exact a3.norm.mul (a1.sub a2).norm
  have hKω : Integrable (fun u ↦ ‖K u‖ * ω u) :=
    hK.norm.mul_bdd hωc.aestronglyMeasurable (Eventually.of_forall fun u ↦ by
      rw [Real.norm_of_nonneg (hω0 u)]; exact hωb u)
  have hHi : Integrable H (volume.prod volume) := by
    rw [integrable_prod_iff' hHm]
    refine ⟨Eventually.of_forall fun u ↦ ?_, ?_⟩
    · show Integrable (fun t ↦ ‖K u‖ * ‖F (t - u) - F t‖)
      exact ((hF.comp_sub_right u).sub hF).norm.const_mul _
    · refine hKω.congr (Eventually.of_forall fun u ↦ ?_)
      simp only [hH, hω]
      rw [← integral_const_mul]
      congr 1 with t
      rw [Real.norm_of_nonneg (mul_nonneg (norm_nonneg _) (norm_nonneg _))]
  have stepA : ∀ x, ‖∫ s, K s * (F (x - s) - F x)‖ ≤ ∫ s, H (x, s) := by
    intro x
    refine (norm_integral_le_integral_norm _).trans (le_of_eq ?_)
    congr 1 with s
    simp [hH]
  have stepB : ∫ x, ‖∫ s, K s * (F (x - s) - F x)‖ ≤ ∫ x, ∫ s, H (x, s) :=
    integral_mono_of_nonneg (Eventually.of_forall fun x ↦ norm_nonneg _)
      hHi.integral_prod_left (Eventually.of_forall stepA)
  have stepC : ∫ x, ∫ s, H (x, s) = ∫ s, ‖K s‖ * ω s := by
    rw [integral_integral_swap (f := fun x s ↦ H (x, s)) hHi]
    congr 1 with s
    simp only [hH, hω]
    rw [integral_const_mul]
  rw [stepC] at stepB
  exact stepB

/-! ### Approximate identity, the local estimate, and uniqueness -/

lemma wtQ_integral_zero {R : ℝ} (hR : 0 < R) : ∫ s, wtQ R 0 s = 1 := by
  rw [← wt_fourier_zero_eq, wtQ_fourier hR]
  exact wtP_fourier_one (by simp)

lemma wtQ_norm {R : ℝ} (hR : 0 < R) (ξ₀ s : ℝ) : ‖wtQ R ξ₀ s‖ = R * ‖wtP (R * s)‖ := by
  simp [wtQ, abs_of_pos hR]

lemma wt_approx {g : ℝ → ℂ} (hg : Integrable g) :
    Tendsto (fun R : ℝ => ∫ x, ‖wtC (wtQ R 0) g x - g x‖) atTop (𝓝 0) := by
  set ω : ℝ → ℝ := fun u ↦ ∫ t, ‖g (t - u) - g t‖ with hω
  have hωc : Continuous ω := wt_omega_cont g hg
  have hω0 : ∀ u, 0 ≤ ω u := fun u ↦ integral_nonneg fun t ↦ norm_nonneg _
  have hωb : ∀ u, ω u ≤ 2 * ∫ t, ‖g t‖ := wt_omega_le g hg
  have bound : ∀ R : ℝ, 0 < R →
      ∫ x, ‖wtC (wtQ R 0) g x - g x‖ ≤ ∫ u, ‖wtP u‖ * ω (u / R) := by
    intro R hR
    obtain ⟨C, -, hC⟩ := wtQ_bdd hR 0
    have eq : ∀ x, wtC (wtQ R 0) g x - g x = ∫ s, wtQ R 0 s * (g (x - s) - g x) := by
      intro x
      have i1 : Integrable (fun s => wtQ R 0 s * g (x - s)) :=
        (hg.comp_sub_left x).bdd_mul (wtQ_cont R 0).aestronglyMeasurable
          (Eventually.of_forall hC)
      have i2 : Integrable (fun s => wtQ R 0 s * g x) := (wtQ_int hR 0).mul_const _
      simp_rw [mul_sub]
      rw [integral_sub i1 i2, integral_mul_const, wtQ_integral_zero hR, one_mul, wtC_apply]
    simp_rw [eq]
    refine (wt_mink (wtQ_int hR 0) hg).trans (le_of_eq ?_)
    simp_rw [wtQ_norm hR]
    have h := Measure.integral_comp_mul_left (fun u => ‖wtP u‖ * ω (u / R)) R
    simp only [mul_div_cancel_left₀ _ hR.ne'] at h
    simp_rw [mul_assoc]
    rw [integral_const_mul, h, abs_inv, abs_of_pos hR, smul_eq_mul, ← mul_assoc,
      mul_inv_cancel₀ hR.ne', one_mul]
  have lim : Tendsto (fun R : ℝ => ∫ u, ‖wtP u‖ * ω (u / R)) atTop
      (𝓝 (∫ u, ‖wtP u‖ * ω 0)) := by
    refine tendsto_integral_filter_of_dominated_convergence
      (fun u => ‖wtP u‖ * (2 * ∫ t, ‖g t‖)) ?_ ?_ ?_ ?_
    · exact Eventually.of_forall fun R => by
        apply Continuous.aestronglyMeasurable
        exact wtP_cont.norm.mul (hωc.comp (continuous_id.div_const R))
    · refine Eventually.of_forall fun R => Eventually.of_forall fun u => ?_
      rw [Real.norm_of_nonneg (mul_nonneg (norm_nonneg _) (hω0 _))]
      exact mul_le_mul_of_nonneg_left (hωb _) (norm_nonneg _)
    · exact wtP_int.norm.mul_const _
    · refine Eventually.of_forall fun u => ?_
      have : Tendsto (fun R : ℝ => u / R) atTop (𝓝 0) := tendsto_const_nhds.div_atTop tendsto_id
      exact ((hωc.tendsto 0).comp this).const_mul _
  simp only [hω, wt_omega_zero, mul_zero, integral_zero] at lim
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds lim
    (Eventually.of_forall fun R ↦ integral_nonneg fun t ↦ norm_nonneg _) ?_
  filter_upwards [eventually_gt_atTop 0] with R hR
  exact bound R hR

lemma wt_local_est {f : ℝ → ℂ} (hf : Integrable f) (ξ₀ : ℝ) :
    Tendsto (fun a : ℝ => ∫ x, ‖wtC f (wtQ a ξ₀) x - 𝓕 f ξ₀ * wtQ a ξ₀ x‖) (𝓝[>] 0) (𝓝 0) := by
  set ω : ℝ → ℝ := fun u ↦ ∫ t, ‖wtP (t - u) - wtP t‖ with hω
  have hωc : Continuous ω := wt_omega_cont wtP wtP_int
  have hω0 : ∀ u, 0 ≤ ω u := fun u ↦ integral_nonneg fun t ↦ norm_nonneg _
  have hωb : ∀ u, ω u ≤ 2 * ∫ t, ‖wtP t‖ := wt_omega_le wtP wtP_int
  set f' : ℝ → ℂ := fun s => ((𝐞 (-(s * ξ₀)) : Circle) : ℂ) * f s with hf'
  have hf'i : Integrable f' :=
    hf.bdd_mul (wt_e_cont.comp (continuous_id.mul continuous_const).neg).aestronglyMeasurable
      (c := 1) (Eventually.of_forall fun s => (wt_e_norm _).le)
  have bound : ∀ a : ℝ, 0 < a →
      ∫ x, ‖wtC f (wtQ a ξ₀) x - 𝓕 f ξ₀ * wtQ a ξ₀ x‖ ≤ ∫ s, ‖f s‖ * ω (a * s) := by
    intro a ha
    obtain ⟨C, -, hC⟩ := wtQ_bdd ha ξ₀
    set Pa : ℝ → ℂ := fun y => (a : ℂ) * wtP (a * y) with hPa
    have hPai : Integrable Pa := (wtP_int.comp_mul_left' ha.ne').const_mul _
    have hc : 𝓕 f ξ₀ = ∫ s, f' s := by
      simp [Real.fourier_real_eq, Circle.smul_def, hf']
    have eq : ∀ x, wtC f (wtQ a ξ₀) x - 𝓕 f ξ₀ * wtQ a ξ₀ x
        = ((𝐞 (ξ₀ * x) : Circle) : ℂ) * ∫ s, f' s * (Pa (x - s) - Pa x) := by
      intro x
      have i1 : Integrable (fun s => f s * wtQ a ξ₀ (x - s)) :=
        hf.mul_bdd ((wtQ_cont a ξ₀).comp (continuous_const.sub continuous_id)).aestronglyMeasurable
          (Eventually.of_forall fun s => hC _)
      have i2 : Integrable (fun s => f' s * wtQ a ξ₀ x) := hf'i.mul_const _
      rw [hc, wtC_apply, ← integral_mul_const, ← integral_sub i1 i2, ← integral_const_mul]
      congr 1 with s
      simp only [wtQ, hf', hPa]
      rw [show ξ₀ * (x - s) = ξ₀ * x + -(s * ξ₀) by ring, AddChar.map_add_eq_mul, Circle.coe_mul]
      ring
    simp_rw [eq, norm_mul, wt_e_norm, one_mul]
    refine (wt_mink hf'i hPai).trans (le_of_eq ?_)
    congr 1 with s
    have hn : ‖f' s‖ = ‖f s‖ := by simp [hf']
    rw [hn]
    congr 1
    have h := Measure.integral_comp_mul_left (fun y => ‖wtP (y - a * s) - wtP y‖) a
    have e : ∀ x, ‖Pa (x - s) - Pa x‖ = a * ‖wtP (a * x - a * s) - wtP (a * x)‖ := by
      intro x
      simp only [hPa]
      rw [← mul_sub, norm_mul, Complex.norm_real, Real.norm_of_nonneg ha.le, mul_sub]
    simp_rw [e]
    rw [integral_const_mul, h, abs_inv, abs_of_pos ha, smul_eq_mul, ← mul_assoc,
      mul_inv_cancel₀ ha.ne', one_mul]
  have lim : Tendsto (fun a : ℝ => ∫ s, ‖f s‖ * ω (a * s)) (𝓝[>] 0)
      (𝓝 (∫ s, ‖f s‖ * ω (0 * s))) := by
    refine tendsto_integral_filter_of_dominated_convergence
      (fun s => ‖f s‖ * (2 * ∫ t, ‖wtP t‖)) ?_ ?_ ?_ ?_
    · exact Eventually.of_forall fun a => hf.norm.aestronglyMeasurable.mul
        (hωc.comp (continuous_const.mul continuous_id)).aestronglyMeasurable
    · refine Eventually.of_forall fun a => Eventually.of_forall fun s => ?_
      rw [Real.norm_of_nonneg (mul_nonneg (norm_nonneg _) (hω0 _))]
      exact mul_le_mul_of_nonneg_left (hωb _) (norm_nonneg _)
    · exact hf.norm.mul_const _
    · refine Eventually.of_forall fun s => ?_
      have : Tendsto (fun a : ℝ ↦ a * s) (𝓝[>] 0) (𝓝 (0 * s)) :=
        ((continuous_id.mul continuous_const).tendsto 0).mono_left nhdsWithin_le_nhds
      exact ((hωc.tendsto _).comp this).const_mul _
  simp only [zero_mul, hω, wt_omega_zero, mul_zero, integral_zero] at lim
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds lim
    (Eventually.of_forall fun a ↦ integral_nonneg fun t ↦ norm_nonneg _) ?_
  filter_upwards [self_mem_nhdsWithin] with a (ha : 0 < a)
  exact bound a ha

lemma wt_unique {F : ℝ → ℂ} (hF : Integrable F) (h0 : ∀ ξ, 𝓕 F ξ = 0) : F =ᵐ[volume] 0 := by
  have hz : ∀ R : ℝ, 0 < R → wtC (wtQ R 0) F = 0 := by
    intro R hR
    obtain ⟨C, -, hC⟩ := wtQ_bdd hR 0
    have hc := wtC_cont_left (wtQ_cont R 0) ⟨C, hC⟩ hF
    have hi := wtC_int (wtQ_int hR 0) hF
    have hfz : 𝓕 (wtC (wtQ R 0) F) = 0 := by
      funext ξ; rw [wtC_fourier (wtQ_int hR 0) hF, h0]; simp
    have h := hc.fourierInv_fourier_eq hi (by rw [hfz]; exact integrable_zero _ _ _)
    rw [← h, hfz]
    funext x
    simp [Real.fourierInv_eq]
  have hlim := wt_approx hF
  have hconst : ∀ᶠ R in atTop, ∫ x, ‖wtC (wtQ R 0) F x - F x‖ = ∫ x, ‖F x‖ := by
    filter_upwards [eventually_gt_atTop 0] with R hR
    rw [hz R hR]; simp
  have h1 : ∫ x, ‖F x‖ = 0 :=
    tendsto_nhds_unique (tendsto_const_nhds.congr' (hconst.mono fun R h => h.symm)) hlim
  rw [integral_eq_zero_iff_of_nonneg (fun x => norm_nonneg _) hF.norm] at h1
  filter_upwards [h1] with x hx
  simpa using hx

/-! ### Mixes of shifts -/

/-- `g` can be matched in area, to every tolerance, by finite mixes of shifts of `f`. -/
def wtAppr (f g : ℝ → ℂ) : Prop :=
  ∀ τ : ℝ, 0 < τ → ∃ (K : ℕ) (w : Fin K → ℂ) (s : Fin K → ℝ),
    ∫ t, ‖g t - ∑ k, w k * f (t - s k)‖ < τ

lemma wt_mix_int {f : ℝ → ℂ} (hf : Integrable f) {K : ℕ} (w : Fin K → ℂ) (s : Fin K → ℝ) :
    Integrable (fun t => ∑ k, w k * f (t - s k)) :=
  integrable_finsetSum _ fun k _ => (hf.comp_sub_right (s k)).const_mul (w k)

lemma wt_appr_zero {f F : ℝ → ℂ} (hF : F =ᵐ[volume] 0) : wtAppr f F := by
  intro τ hτ
  refine ⟨0, Fin.elim0, Fin.elim0, ?_⟩
  have : ∫ t, ‖F t - ∑ k : Fin 0, Fin.elim0 k * f (t - Fin.elim0 k)‖ = 0 := by
    apply integral_eq_zero_of_ae
    filter_upwards [hF] with t ht
    simp [ht]
  rw [this]; exact hτ

lemma wt_appr_add {f g₁ g₂ : ℝ → ℂ} (hf : Integrable f) (hg₁ : Integrable g₁)
    (hg₂ : Integrable g₂) (h₁ : wtAppr f g₁) (h₂ : wtAppr f g₂) :
    wtAppr f (fun t => g₁ t + g₂ t) := by
  intro τ hτ
  obtain ⟨K₁, w₁, s₁, e₁⟩ := h₁ (τ / 2) (half_pos hτ)
  obtain ⟨K₂, w₂, s₂, e₂⟩ := h₂ (τ / 2) (half_pos hτ)
  refine ⟨K₁ + K₂, Fin.append w₁ w₂, Fin.append s₁ s₂, ?_⟩
  have hsum : ∀ t, ∑ k, Fin.append w₁ w₂ k * f (t - Fin.append s₁ s₂ k)
      = (∑ k, w₁ k * f (t - s₁ k)) + ∑ k, w₂ k * f (t - s₂ k) := by
    intro t; rw [Fin.sum_univ_add]; simp [Fin.append_left, Fin.append_right]
  simp_rw [hsum]
  have m₁ := wt_mix_int hf w₁ s₁
  have m₂ := wt_mix_int hf w₂ s₂
  have i₁ := (hg₁.sub m₁).norm
  have i₂ := (hg₂.sub m₂).norm
  calc ∫ t, ‖g₁ t + g₂ t - ((∑ k, w₁ k * f (t - s₁ k)) + ∑ k, w₂ k * f (t - s₂ k))‖
      ≤ ∫ t, (‖g₁ t - ∑ k, w₁ k * f (t - s₁ k)‖ + ‖g₂ t - ∑ k, w₂ k * f (t - s₂ k)‖) := by
        refine integral_mono (((hg₁.add hg₂).sub (m₁.add m₂))).norm (i₁.add i₂) fun t => ?_
        refine le_trans (le_of_eq ?_) (norm_add_le _ _)
        congr 1; ring
    _ = _ := integral_add i₁ i₂
    _ < τ := by linarith

lemma wt_appr_closed {f g : ℝ → ℂ} (hf : Integrable f) (hg : Integrable g)
    (h : ∀ ε : ℝ, 0 < ε → ∃ g', Integrable g' ∧ wtAppr f g' ∧ ∫ t, ‖g t - g' t‖ < ε) :
    wtAppr f g := by
  intro τ hτ
  obtain ⟨g', hg', hA, e⟩ := h (τ / 2) (half_pos hτ)
  obtain ⟨K, w, s, e'⟩ := hA (τ / 2) (half_pos hτ)
  refine ⟨K, w, s, ?_⟩
  have m := wt_mix_int hf w s
  have i₁ := (hg.sub hg').norm
  have i₂ := (hg'.sub m).norm
  calc ∫ t, ‖g t - ∑ k, w k * f (t - s k)‖
      ≤ ∫ t, (‖g t - g' t‖ + ‖g' t - ∑ k, w k * f (t - s k)‖) := by
        refine integral_mono (hg.sub m).norm (i₁.add i₂) fun t => ?_
        refine le_trans (le_of_eq ?_) (norm_add_le _ _)
        congr 1; ring
    _ = _ := integral_add i₁ i₂
    _ < τ := by linarith

/-! ### Riemann sums: `X ⋆ f` is a limit of mixes of shifts of `f` -/

lemma wt_minkR {μ : Measure ℝ} [SFinite μ] {D : ℝ × ℝ → ℂ} (hD : Integrable D (volume.prod μ)) :
    ∫ x, ‖∫ s, D (x, s) ∂μ‖ ≤ ∫ s, (∫ x, ‖D (x, s)‖) ∂μ := by
  calc ∫ x, ‖∫ s, D (x, s) ∂μ‖ ≤ ∫ x, ∫ s, ‖D (x, s)‖ ∂μ :=
        integral_mono_of_nonneg (Eventually.of_forall fun x ↦ norm_nonneg _)
          hD.norm.integral_prod_left
          (Eventually.of_forall fun x => norm_integral_le_integral_norm _)
    _ = _ := integral_integral_swap (f := fun x s => ‖D (x, s)‖) hD.norm

lemma wt_riemann_cc {f X : ℝ → ℂ} (hf : Integrable f) (hX : Continuous X)
    (hXs : HasCompactSupport X) : wtAppr f (wtC X f) := by
  intro τ hτ
  obtain ⟨R₀, hR₀⟩ := hXs.isCompact.isBounded.subset_closedBall 0
  set R : ℝ := |R₀| + 1 with hRdef
  have hR : 0 < R := by positivity
  have hXz : ∀ s, R ≤ |s| → X s = 0 := by
    intro s hs
    apply image_eq_zero_of_notMem_tsupport
    intro hm
    have h1 := hR₀ hm
    rw [Metric.mem_closedBall, dist_zero_right, Real.norm_eq_abs] at h1
    have : R₀ ≤ |R₀| := le_abs_self R₀
    linarith
  obtain ⟨M, hM⟩ := hX.bounded_above_of_compact_support hXs
  have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM 0)
  have hXint : Integrable X := hX.integrable_of_hasCompactSupport hXs
  set L : ℝ := ∫ t, ‖f t‖ with hL
  have hL0 : 0 ≤ L := integral_nonneg fun t => norm_nonneg _
  set ω : ℝ → ℝ := fun u ↦ ∫ t, ‖f (t - u) - f t‖ with hω
  have hωc : Continuous ω := wt_omega_cont f hf
  set η : ℝ := τ / (4 * R * (L + M + 1)) with hη
  have hη0 : 0 < η := by positivity
  have hηe : η * (4 * R * (L + M + 1)) = τ := by rw [hη]; field_simp
  obtain ⟨δ₁, hδ₁, hX'⟩ :=
    Metric.uniformContinuous_iff.1 (hXs.uniformContinuous_of_continuous hX) η hη0
  obtain ⟨δ₂, hδ₂, hω'⟩ := Metric.continuousAt_iff.1 (hωc.continuousAt (x := 0)) η hη0
  obtain ⟨N, hN⟩ := exists_nat_gt (2 * R / min δ₁ δ₂)
  have hδ : 0 < min δ₁ δ₂ := lt_min hδ₁ hδ₂
  have hNpos : (0 : ℝ) < N := lt_trans (by positivity) hN
  set h : ℝ := 2 * R / N with hh
  have hh0 : 0 < h := by positivity
  have hhδ : h < min δ₁ δ₂ := by
    rw [hh, div_lt_iff₀ hNpos]
    rw [div_lt_iff₀ hδ] at hN
    linarith
  set a : ℕ → ℝ := fun k => -R + k * h with ha
  have hak : ∀ k : ℕ, a (k + 1) = a k + h := by intro k; simp only [ha]; push_cast; ring
  have hak' : ∀ k : ℕ, a k ≤ a (k + 1) := by intro k; rw [hak]; linarith
  refine ⟨N, fun k => (h : ℂ) * X (a k), fun k => a k, ?_⟩
  set G : ℕ → ℝ → ℂ := fun k x =>
    ∫ s in Set.Ioc (a k) (a (k + 1)), (X s * f (x - s) - X (a k) * f (x - a k)) with hG
  -- the error is the sum of the pieces
  have claim1 : ∀ x, wtC X f x - ∑ k : Fin N, (h : ℂ) * X (a k) * f (x - a k)
      = ∑ k ∈ Finset.range N, G k x := by
    intro x
    rw [Fin.sum_univ_eq_sum_range (fun k => (h : ℂ) * X (a k) * f (x - a k)) N]
    have hint : Integrable (fun s => X s * f (x - s)) :=
      (hf.comp_sub_left x).bdd_mul hX.aestronglyMeasurable (Eventually.of_forall hM)
    have ha0 : a 0 = -R := by simp [ha]
    have haN : a N = R := by simp only [ha, hh]; field_simp; ring
    have e1 : wtC X f x = ∫ s in a 0..a N, X s * f (x - s) := by
      rw [wtC_apply, intervalIntegral.integral_of_le (by rw [ha0, haN]; linarith),
        setIntegral_eq_integral_of_forall_compl_eq_zero]
      intro s hs
      rw [ha0, haN, Set.mem_Ioc, not_and_or, not_lt, not_le] at hs
      rw [hXz s, zero_mul]
      rcases hs with hs | hs
      · rw [abs_of_nonpos (by linarith)]; linarith
      · rw [abs_of_pos (by linarith)]; linarith
    have e2 : ∫ s in a 0..a N, X s * f (x - s)
        = ∑ k ∈ Finset.range N, ∫ s in a k..a (k + 1), X s * f (x - s) :=
      (intervalIntegral.sum_integral_adjacent_intervals fun k _ => hint.intervalIntegrable).symm
    have e3 : ∀ k : ℕ, (h : ℂ) * X (a k) * f (x - a k)
        = ∫ s in a k..a (k + 1), X (a k) * f (x - a k) := by
      intro k
      rw [intervalIntegral.integral_const, hak, Complex.real_smul]
      push_cast; ring
    have e4 : ∀ k : ℕ, G k x = (∫ s in a k..a (k + 1), X s * f (x - s))
        - ∫ s in a k..a (k + 1), X (a k) * f (x - a k) := by
      intro k
      rw [← intervalIntegral.integral_sub hint.intervalIntegrable intervalIntegrable_const,
        intervalIntegral.integral_of_le (hak' k)]
    rw [e1, e2]
    simp_rw [e3, e4]
    rw [Finset.sum_sub_distrib]
  -- each piece is small
  have claim2 : ∀ k : ℕ, Integrable (G k) ∧ ∫ x, ‖G k x‖ ≤ h * (η * L + M * η) := by
    intro k
    set D : ℝ × ℝ → ℂ := fun p => X p.2 * f (p.1 - p.2) - X (a k) * f (p.1 - a k) with hD
    have t1 : Integrable (fun p : ℝ × ℝ => X p.2 * f (p.1 - p.2)) (volume.prod (volume.restrict (Set.Ioc (a k) (a (k + 1))))) := by
      have := (hXint.restrict (s := Set.Ioc (a k) (a (k + 1)))).convolution_integrand
        (ContinuousLinearMap.mul ℂ ℂ) hf (μ := volume)
      simpa using this
    have t2 : Integrable (fun p : ℝ × ℝ => X (a k) * f (p.1 - a k)) (volume.prod (volume.restrict (Set.Ioc (a k) (a (k + 1))))) := by
      exact ((hf.comp_sub_right (a k)).const_mul (X (a k))).comp_fst
        (volume.restrict (Set.Ioc (a k) (a (k + 1))))
    have hDi : Integrable D (volume.prod (volume.restrict (Set.Ioc (a k) (a (k + 1))))) := t1.sub t2
    have hGk : G k = fun x => ∫ s, D (x, s) ∂(volume.restrict (Set.Ioc (a k) (a (k + 1)))) := rfl
    refine ⟨hGk ▸ hDi.integral_prod_left, ?_⟩
    rw [hGk]
    refine (wt_minkR hDi).trans ?_
    have hpt : ∀ s ∈ Set.Ioc (a k) (a (k + 1)), ∫ x, ‖D (x, s)‖ ≤ η * L + M * η := by
      intro s hs
      have hs1 : dist s (a k) < min δ₁ δ₂ := by
        rw [Real.dist_eq, abs_of_pos (by linarith [hs.1])]
        have := hs.2; rw [hak] at this; linarith
      have b1 : ‖X s - X (a k)‖ < η := by
        rw [← dist_eq_norm]; exact hX' (lt_of_lt_of_le hs1 (min_le_left _ _))
      have b2 : ω (s - a k) < η := by
        have := hω' (x := s - a k) (by
          rw [Real.dist_eq, sub_zero, ← Real.dist_eq]; exact lt_of_lt_of_le hs1 (min_le_right _ _))
        rw [Real.dist_eq] at this
        simp only [hω, wt_omega_zero, sub_zero] at this
        exact lt_of_le_of_lt (le_abs_self _) this
      have j1 : Integrable (fun x => ‖X s - X (a k)‖ * ‖f (x - s)‖) :=
        (hf.comp_sub_right s).norm.const_mul _
      have j2 : Integrable (fun x => ‖X (a k)‖ * ‖f (x - s) - f (x - a k)‖) :=
        ((hf.comp_sub_right s).sub (hf.comp_sub_right (a k))).norm.const_mul _
      have tr1 : ∫ x, ‖f (x - s)‖ = L := integral_sub_right_eq_self (fun x => ‖f x‖) s
      have tr2 : ∫ x, ‖f (x - s) - f (x - a k)‖ = ω (s - a k) := by
        have := integral_sub_right_eq_self (μ := volume)
          (fun y => ‖f (y - (s - a k)) - f y‖) (a k)
        simp only [show ∀ x, x - a k - (s - a k) = x - s from fun x => by ring] at this
        exact this
      calc ∫ x, ‖D (x, s)‖
          ≤ ∫ x, (‖X s - X (a k)‖ * ‖f (x - s)‖ + ‖X (a k)‖ * ‖f (x - s) - f (x - a k)‖) := by
            refine integral_mono ?_ (j1.add j2) fun x => ?_
            · exact (((hf.comp_sub_right s).const_mul (X s)).sub
                ((hf.comp_sub_right (a k)).const_mul (X (a k)))).norm
            · simp only [hD]
              rw [show X s * f (x - s) - X (a k) * f (x - a k)
                  = (X s - X (a k)) * f (x - s) + X (a k) * (f (x - s) - f (x - a k)) by ring]
              refine (norm_add_le _ _).trans (le_of_eq ?_)
              rw [norm_mul, norm_mul]
        _ = ‖X s - X (a k)‖ * L + ‖X (a k)‖ * ω (s - a k) := by
            rw [integral_add j1 j2, integral_const_mul, integral_const_mul, tr1, tr2]
        _ ≤ η * L + M * η := by
            gcongr
            · exact hM _
    calc ∫ s, (∫ x, ‖D (x, s)‖) ∂(volume.restrict (Set.Ioc (a k) (a (k + 1)))) ≤ ∫ s in Set.Ioc (a k) (a (k + 1)), (η * L + M * η) :=
          setIntegral_mono_on hDi.norm.integral_prod_right
            (integrable_const (μ := volume.restrict (Set.Ioc (a k) (a (k + 1)))) _)
            measurableSet_Ioc hpt
      _ = h * (η * L + M * η) := by
          rw [setIntegral_const, Real.volume_real_Ioc_of_le (hak' k), hak, smul_eq_mul]
          ring
  have hGi : ∀ k, Integrable (G k) := fun k => (claim2 k).1
  calc ∫ x, ‖wtC X f x - ∑ k : Fin N, (h : ℂ) * X (a k) * f (x - a k)‖
      = ∫ x, ‖∑ k ∈ Finset.range N, G k x‖ := by
        congr 1 with x; rw [claim1]
    _ ≤ ∫ x, ∑ k ∈ Finset.range N, ‖G k x‖ :=
        integral_mono (integrable_finsetSum _ fun k _ => hGi k).norm
          (integrable_finsetSum _ fun k _ => (hGi k).norm) fun x => norm_sum_le _ _
    _ = ∑ k ∈ Finset.range N, ∫ x, ‖G k x‖ :=
        integral_finsetSum _ fun k _ => (hGi k).norm
    _ ≤ ∑ k ∈ Finset.range N, h * (η * L + M * η) :=
        Finset.sum_le_sum fun k _ => (claim2 k).2
    _ = (N * h) * (η * L + M * η) := by simp; ring
    _ < τ := by
        have hNh : (N : ℝ) * h = 2 * R := by simp only [hh]; field_simp
        rw [hNh]
        nlinarith [mul_nonneg (mul_nonneg hR.le hη0.le) hL0,
          mul_nonneg (mul_nonneg hR.le hη0.le) hM0, mul_pos hR hη0]

lemma wt_riemann {f X : ℝ → ℂ} (hf : Integrable f) (hX : Integrable X) :
    wtAppr f (wtC X f) := by
  set L : ℝ := ∫ t, ‖f t‖ with hL
  have hL0 : 0 ≤ L := integral_nonneg fun t => norm_nonneg _
  refine wt_appr_closed hf (wtC_int hX hf) fun ε hε => ?_
  have hc : 0 < ε / (2 * (L + 1)) := by positivity
  obtain ⟨X', hX's, hXX', hX'c, hX'i⟩ := hX.exists_hasCompactSupport_integral_sub_le hc
  refine ⟨wtC X' f, wtC_int hX'i hf, wt_riemann_cc hf hX'c hX's, ?_⟩
  calc ∫ t, ‖wtC X f t - wtC X' f t‖ = ∫ t, ‖wtC (fun t => X t - X' t) f t‖ := by
        apply integral_congr_ae
        filter_upwards [wtC_sub_left_ae hX hX'i hf] with t ht
        rw [← ht]
    _ ≤ (∫ t, ‖X t - X' t‖) * L := wtC_norm_le (hX.sub hX'i) hf
    _ ≤ ε / (2 * (L + 1)) * L := mul_le_mul_of_nonneg_right hXX' hL0
    _ < ε := by
        have e : ε / (2 * (L + 1)) * (2 * (L + 1)) = ε := by field_simp
        nlinarith

/-! ### Wiener's local inverse, by a Neumann series -/

/-- Repeated convolution: `F, F ⋆ u, (F ⋆ u) ⋆ u, …`. -/
noncomputable def wtPow (F u : ℝ → ℂ) : ℕ → ℝ → ℂ
  | 0 => F
  | n + 1 => wtC (wtPow F u n) u

lemma wt_local {f : ℝ → ℂ} (hf : Integrable f) {ξ₀ : ℝ} (hne : 𝓕 f ξ₀ ≠ 0) :
    ∃ δ > 0, ∀ F : ℝ → ℂ, Integrable F → (∀ η, 𝓕 F η ≠ 0 → |η - ξ₀| < δ) → wtAppr f F := by
  set c := 𝓕 f ξ₀ with hc
  have hc0 : 0 < ‖c‖ := norm_pos_iff.2 hne
  obtain ⟨a, ha, hsmall⟩ : ∃ a : ℝ, 0 < a ∧
      ∫ x, ‖wtC f (wtQ a ξ₀) x - c * wtQ a ξ₀ x‖ < ‖c‖ := by
    have h1 := (wt_local_est hf ξ₀).eventually (gt_mem_nhds hc0)
    obtain ⟨a, h2, h3⟩ := (h1.and self_mem_nhdsWithin).exists
    exact ⟨a, h3, h2⟩
  refine ⟨a, ha, fun F hF hsupp => ?_⟩
  have hm := wtQ_int ha ξ₀
  set u : ℝ → ℂ := fun x => wtC f (wtQ a ξ₀) x - c * wtQ a ξ₀ x with hu
  have hui : Integrable u := (wtC_int hf hm).sub (hm.const_mul c)
  set r := ∫ x, ‖u x‖ with hr
  have hr0 : 0 ≤ r := integral_nonneg fun _ => norm_nonneg _
  have hrc : r < ‖c‖ := hsmall
  have hFu : ∀ η, |η - ξ₀| < a → 𝓕 f η = c + 𝓕 u η := by
    intro η hη
    rw [hu, wt_fourier_sub (wtC_int hf hm) (hm.const_mul c), wtC_fourier hf hm,
      wt_fourier_const_mul, wtQ_fourier_one ha hη.le]
    ring
  have hPi : ∀ n, Integrable (wtPow F u n) := by
    intro n
    induction n with
    | zero => exact hF
    | succ n ih => exact wtC_int ih hui
  have hPf : ∀ n η, 𝓕 (wtPow F u n) η = 𝓕 F η * 𝓕 u η ^ n := by
    intro n
    induction n with
    | zero => intro η; simp [wtPow]
    | succ n ih =>
      intro η
      rw [wtPow, wtC_fourier (hPi n) hui, ih, pow_succ]
      ring
  have hPn : ∀ n, ∫ x, ‖wtPow F u n x‖ ≤ (∫ x, ‖F x‖) * r ^ n := by
    intro n
    induction n with
    | zero => simp [wtPow]
    | succ n ih =>
      calc ∫ x, ‖wtPow F u (n + 1) x‖ ≤ (∫ x, ‖wtPow F u n x‖) * r := wtC_norm_le (hPi n) hui
        _ ≤ (∫ x, ‖F x‖) * r ^ n * r := mul_le_mul_of_nonneg_right ih hr0
        _ = _ := by ring
  set Y : ℕ → ℝ → ℂ := fun N x =>
    ∑ n ∈ Finset.range N, (1 / c) * (-1 / c) ^ n * wtPow F u n x with hY
  have hYi : ∀ N, Integrable (Y N) := fun N =>
    integrable_finsetSum _ fun n _ => (hPi n).const_mul _
  have hYf : ∀ N η, 𝓕 (Y N) η
      = ∑ n ∈ Finset.range N, (1 / c) * (-1 / c) ^ n * (𝓕 F η * 𝓕 u η ^ n) := by
    intro N η
    rw [hY, wt_fourier_sum (Finset.range N)
      (a := fun n x => (1 / c) * (-1 / c) ^ n * wtPow F u n x)
      (fun n _ => (hPi n).const_mul _)]
    refine Finset.sum_congr rfl fun n _ => ?_
    rw [wt_fourier_const_mul, hPf]
  have key : ∀ N, (fun x => (wtC (Y N) f x - F x) + (-1 / c) ^ N * wtPow F u N x)
      =ᵐ[volume] 0 := by
    intro N
    have i1 := wtC_int (hYi N) hf
    have i2 : Integrable (fun x => wtC (Y N) f x - F x) := i1.sub hF
    have i3 : Integrable (fun x => (-1 / c) ^ N * wtPow F u N x) := (hPi N).const_mul _
    apply wt_unique (F := fun x => (wtC (Y N) f x - F x) + (-1 / c) ^ N * wtPow F u N x)
      (i2.add i3)
    intro η
    rw [wt_fourier_add i2 i3, wt_fourier_sub i1 hF,
      wtC_fourier (hYi N) hf, wt_fourier_const_mul, hYf, hPf]
    by_cases h0 : 𝓕 F η = 0
    · simp [h0]
    · rw [hFu η (hsupp η h0)]
      set v := 𝓕 u η
      have e1 : ∑ n ∈ Finset.range N, (1 / c) * (-1 / c) ^ n * (𝓕 F η * v ^ n)
          = 𝓕 F η / c * ∑ n ∈ Finset.range N, (-v / c) ^ n := by
        rw [Finset.mul_sum]
        refine Finset.sum_congr rfl fun n _ => ?_
        rw [show (-v / c) ^ n = (-1 / c) ^ n * v ^ n by rw [← mul_pow]; ring]
        ring
      have e2 : (-1 / c) ^ N * (𝓕 F η * v ^ N) = 𝓕 F η * (-v / c) ^ N := by
        rw [show (-v / c) ^ N = (-1 / c) ^ N * v ^ N by rw [← mul_pow]; ring]
        ring
      rw [e1, e2]
      have e3 : 𝓕 F η / c * (∑ n ∈ Finset.range N, (-v / c) ^ n) * (c + v)
          = 𝓕 F η * ((1 - (-v / c)) * ∑ n ∈ Finset.range N, (-v / c) ^ n) := by
        field_simp
        ring
      rw [e3, mul_neg_geom_sum]
      ring
  refine wt_appr_closed hf hF fun ε hε => ?_
  have hq : r / ‖c‖ < 1 := (div_lt_one hc0).2 hrc
  have hq0 : 0 ≤ r / ‖c‖ := div_nonneg hr0 hc0.le
  obtain ⟨N, hN⟩ : ∃ N : ℕ, (∫ x, ‖F x‖) * (r / ‖c‖) ^ N < ε := by
    have h1 := (tendsto_pow_atTop_nhds_zero_of_lt_one hq0 hq).const_mul (∫ x, ‖F x‖)
    rw [mul_zero] at h1
    exact (h1.eventually (gt_mem_nhds hε)).exists
  refine ⟨wtC (Y N) f, wtC_int (hYi N) hf, wt_riemann hf (hYi N), ?_⟩
  calc ∫ x, ‖F x - wtC (Y N) f x‖ = ∫ x, ‖(-1 / c) ^ N * wtPow F u N x‖ := by
        apply integral_congr_ae
        filter_upwards [key N] with x hx
        simp only [Pi.zero_apply] at hx
        rw [show F x - wtC (Y N) f x = (-1 / c) ^ N * wtPow F u N x by linear_combination -hx]
    _ = (1 / ‖c‖) ^ N * ∫ x, ‖wtPow F u N x‖ := by
        simp_rw [norm_mul, norm_pow, norm_div, norm_neg, norm_one]
        rw [integral_const_mul]
    _ ≤ (1 / ‖c‖) ^ N * ((∫ x, ‖F x‖) * r ^ N) :=
        mul_le_mul_of_nonneg_left (hPn N) (by positivity)
    _ = (∫ x, ‖F x‖) * (r / ‖c‖) ^ N := by rw [div_pow, div_pow]; ring
    _ < ε := hN

/-! ### Patching the local inverses together: the density theorem -/

lemma wt_density {f : ℝ → ℂ} (hf : Integrable f) (hne : ∀ ξ, 𝓕 f ξ ≠ 0) :
    ∀ g : ℝ → ℂ, Integrable g → wtAppr f g := by
  choose δ hδ hloc using fun ξ => wt_local hf (hne ξ)
  have patch : ∀ t : Finset ℝ, ∀ F : ℝ → ℂ, Integrable F →
      (∀ η, 𝓕 F η ≠ 0 → ∃ ξ ∈ t, |η - ξ| < δ ξ / 2) → wtAppr f F := by
    intro t
    induction t using Finset.induction_on with
    | empty =>
      intro F hF hcov
      apply wt_appr_zero
      apply wt_unique hF
      intro η
      by_contra h
      obtain ⟨ξ, hξ, -⟩ := hcov η h
      simp at hξ
    | insert ξ t hξt ih =>
      intro F hF hcov
      have hd : 0 < δ ξ / 2 := half_pos (hδ ξ)
      have hψ := wtQ_int hd ξ
      have hFψ := wtC_int hF hψ
      have h1 : wtAppr f (wtC F (wtQ (δ ξ / 2) ξ)) := by
        apply hloc ξ _ hFψ
        intro η hη
        rw [wtC_fourier hF hψ] at hη
        have hψη : 𝓕 (wtQ (δ ξ / 2) ξ) η ≠ 0 := right_ne_zero_of_mul hη
        by_contra hcon
        exact hψη (wtQ_fourier_zero hd (by linarith [not_lt.1 hcon]))
      have h2 : wtAppr f (fun x => F x - wtC F (wtQ (δ ξ / 2) ξ) x) := by
        apply ih (fun x => F x - wtC F (wtQ (δ ξ / 2) ξ) x) (hF.sub hFψ)
        intro η hη
        rw [wt_fourier_sub hF hFψ, wtC_fourier hF hψ] at hη
        have hFη : 𝓕 F η ≠ 0 := by intro h; apply hη; rw [h]; ring
        have hψ1 : 𝓕 (wtQ (δ ξ / 2) ξ) η ≠ 1 := by intro h; apply hη; rw [h]; ring
        obtain ⟨ξ', hξ', hlt⟩ := hcov η hFη
        rcases Finset.mem_insert.1 hξ' with rfl | hmem
        · exact absurd (wtQ_fourier_one hd hlt.le) hψ1
        · exact ⟨ξ', hmem, hlt⟩
      have h3 := wt_appr_add hf hFψ (hF.sub hFψ) h1 h2
      simpa using h3
  intro g hg
  refine wt_appr_closed hf hg fun ε hε => ?_
  obtain ⟨R, hR, hRε⟩ : ∃ R : ℝ, 0 < R ∧ ∫ x, ‖wtC (wtQ R 0) g x - g x‖ < ε := by
    obtain ⟨R, h1, h2⟩ :=
      (((wt_approx hg).eventually (gt_mem_nhds hε)).and (eventually_gt_atTop 0)).exists
    exact ⟨R, h2, h1⟩
  have hQ := wtQ_int hR 0
  refine ⟨wtC (wtQ R 0) g, wtC_int hQ hg, ?_, ?_⟩
  · obtain ⟨t, ht⟩ := (isCompact_Icc (a := -(2 * R)) (b := 2 * R)).elim_finite_subcover
      (fun ξ => Metric.ball ξ (δ ξ / 2)) (fun ξ => Metric.isOpen_ball)
      (fun η _ => Set.mem_iUnion.2 ⟨η, Metric.mem_ball_self (half_pos (hδ η))⟩)
    apply patch t _ (wtC_int hQ hg)
    intro η hη
    rw [wtC_fourier hQ hg] at hη
    have hQη : 𝓕 (wtQ R 0) η ≠ 0 := left_ne_zero_of_mul hη
    have hmem : η ∈ Set.Icc (-(2 * R)) (2 * R) := by
      by_contra hcon
      apply hQη
      apply wtQ_fourier_zero hR
      rw [sub_zero]
      rw [Set.mem_Icc, not_and_or, not_le, not_le] at hcon
      rcases hcon with hcon | hcon
      · rw [abs_of_neg (by linarith)]; linarith
      · rw [abs_of_pos (by linarith)]; linarith
    have h4 := ht hmem
    simp only [Set.mem_iUnion, Metric.mem_ball, Real.dist_eq] at h4
    obtain ⟨ξ, hξ, hlt⟩ := h4
    exact ⟨ξ, hξ, hlt⟩
  · calc ∫ x, ‖g x - wtC (wtQ R 0) g x‖ = ∫ x, ‖wtC (wtQ R 0) g x - g x‖ := by
          congr 1 with x; rw [norm_sub_rev]
      _ < ε := hRε

/-! ### A zero of the spectrum blocks every mix -/

lemma wt_blocks {f g : ℝ → ℂ} (hf : Integrable f) (hg : Integrable g)
    {ξ₀ : ℝ} (h0 : 𝓕 f ξ₀ = 0) (K : ℕ) (w : Fin K → ℂ) (s : Fin K → ℝ) :
    ‖𝓕 g ξ₀‖ ≤ ∫ t, ‖g t - ∑ k, w k * f (t - s k)‖ := by
  have hm := wt_mix_int hf w s
  have hmix : 𝓕 (fun t => ∑ k, w k * f (t - s k)) ξ₀ = 0 := by
    rw [wt_fourier_sum Finset.univ (a := fun k t => w k * f (t - s k))
      (fun k _ => (hf.comp_sub_right (s k)).const_mul (w k))]
    apply Finset.sum_eq_zero
    intro k _
    rw [wt_fourier_const_mul, wt_fourier_shift, h0]
    simp
  have h1 := Real.norm_fourier_le_integral_norm (fun t => g t - ∑ k, w k * f (t - s k)) ξ₀
  rwa [wt_fourier_sub hg hm, hmix, sub_zero] at h1

#print axioms wt_e_cont
#print axioms wt_e_norm
#print axioms wtPhi_contDiff
#print axioms wtPhi_hcs
#print axioms wtP_int
#print axioms wtP_cont
#print axioms wtP_bdd
#print axioms wtP_fourier
#print axioms wtP_fourier_one
#print axioms wtP_fourier_zero
#print axioms wtQ_cont
#print axioms wtQ_int
#print axioms wtQ_bdd
#print axioms wtQ_fourier
#print axioms wtQ_fourier_one
#print axioms wtQ_fourier_zero
#print axioms wt_fint
#print axioms wt_fourier_sub
#print axioms wt_fourier_add
#print axioms wt_fourier_const_mul
#print axioms wt_fourier_sum
#print axioms wt_fourier_shift
#print axioms wt_fourier_zero_eq
#print axioms wtC_apply
#print axioms wtC_int
#print axioms wtC_fourier
#print axioms wtC_cont_left
#print axioms wtC_norm_le
#print axioms wtC_sub_left_ae
#print axioms wt_omega_le
#print axioms wt_omega_cc
#print axioms wt_omega_cont
#print axioms wt_omega_zero
#print axioms wt_mink
#print axioms wtQ_integral_zero
#print axioms wtQ_norm
#print axioms wt_approx
#print axioms wt_local_est
#print axioms wt_unique
#print axioms wt_mix_int
#print axioms wt_appr_zero
#print axioms wt_appr_add
#print axioms wt_appr_closed
#print axioms wt_minkR
#print axioms wt_riemann_cc
#print axioms wt_riemann
#print axioms wt_local
#print axioms wt_density
#print axioms wt_blocks


/-- Wiener's theorem, density form: for an integrable signal `f`, every integrable target `g`
can be matched within every tolerance `τ > 0` in area by a finite mix of shifts of `f` exactly
when the transform of `f` is zero at no frequency. -/
theorem shifts_dense_iff_fourier_ne_zero {f : ℝ → ℂ} (hf : Integrable f) :
    (∀ g : ℝ → ℂ, Integrable g → ∀ τ : ℝ, 0 < τ →
      ∃ (K : ℕ) (w : Fin K → ℂ) (s : Fin K → ℝ),
        ∫ t, ‖g t - ∑ k, w k * f (t - s k)‖ < τ) ↔
    ∀ ξ : ℝ, 𝓕 f ξ ≠ 0 := by
  constructor
  · intro hd ξ h0
    have hQ := wtQ_int one_pos ξ
    obtain ⟨K, w, s, hlt⟩ := hd (wtQ 1 ξ) hQ 1 one_pos
    have hb := wt_blocks hf hQ h0 K w s
    rw [wtQ_fourier_one one_pos (by simp)] at hb
    simp only [norm_one] at hb
    linarith
  · intro hne g hg τ hτ
    exact wt_density hf hne g hg τ hτ

/-- Wiener's Tauberian theorem: if `f` is integrable with a transform that is zero at no
frequency, `y` is a bounded recording, and the `f`-weighted average of `y` tends to `a` times
the area `f̂(0)` of `f`, then for every integrable weight `g` the `g`-weighted average of `y`
tends to `a` times the area `ĝ(0)` of `g`. -/
theorem tauberian_limit_transfer {f y : ℝ → ℂ} (hf : Integrable f) (hfne : ∀ ξ : ℝ, 𝓕 f ξ ≠ 0)
    (hy : AEStronglyMeasurable y) (hbdd : ∃ B : ℝ, ∀ t, ‖y t‖ ≤ B) {a : ℂ}
    (hlim : Tendsto (fun x : ℝ => ∫ s, f s * y (x - s)) atTop (𝓝 (a * 𝓕 f 0))) :
    ∀ g : ℝ → ℂ, Integrable g →
      Tendsto (fun x : ℝ => ∫ s, g s * y (x - s)) atTop (𝓝 (a * 𝓕 g 0)) := by
  intro g hg
  obtain ⟨B, hB⟩ := hbdd
  have hB0 : 0 ≤ B := (norm_nonneg _).trans (hB 0)
  rw [Metric.tendsto_atTop]
  intro ε hε
  set τ := ε / (2 * (B + ‖a‖ + 1)) with hτ
  have hτ0 : 0 < τ := by positivity
  have hτe : τ * (2 * (B + ‖a‖ + 1)) = ε := by rw [hτ]; field_simp
  obtain ⟨K, w, s, hmix⟩ := wt_density hf hfne g hg τ hτ0
  have hm := wt_mix_int hf w s
  have hys : ∀ x, AEStronglyMeasurable (fun t => y (x - t)) volume := fun x =>
    hy.comp_quasiMeasurePreserving (quasiMeasurePreserving_sub_left volume x)
  have hyb : ∀ x, ∀ᵐ t ∂volume, ‖y (x - t)‖ ≤ B := fun x => Eventually.of_forall fun t => hB _
  have hmy : ∀ x, ∫ t, (∑ k, w k * f (t - s k)) * y (x - t)
      = ∑ k, w k * ∫ t, f t * y ((x - s k) - t) := by
    intro x
    simp only [Finset.sum_mul]
    rw [integral_finsetSum _ (fun k _ =>
      ((hf.comp_sub_right (s k)).const_mul (w k)).mul_bdd (hys x) (hyb x))]
    refine Finset.sum_congr rfl fun k _ => ?_
    simp_rw [mul_assoc]
    rw [integral_const_mul]
    congr 1
    have h1 := integral_sub_right_eq_self (μ := volume) (fun u => f u * y (x - s k - u)) (s k)
    simp only [show ∀ t, x - s k - (t - s k) = x - t from fun t => by ring] at h1
    exact h1
  have hm0 : 𝓕 (fun t => ∑ k, w k * f (t - s k)) 0 = ∑ k, w k * 𝓕 f 0 := by
    rw [wt_fourier_sum Finset.univ (a := fun k t => w k * f (t - s k))
      (fun k _ => (hf.comp_sub_right (s k)).const_mul (w k))]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [wt_fourier_const_mul, wt_fourier_shift]
    simp
  have hgm : ∀ x, ‖(∫ t, g t * y (x - t)) - ∫ t, (∑ k, w k * f (t - s k)) * y (x - t)‖
      ≤ B * τ := by
    intro x
    rw [← integral_sub (hg.mul_bdd (hys x) (hyb x)) (hm.mul_bdd (hys x) (hyb x))]
    calc _ ≤ ∫ t, ‖g t * y (x - t) - (∑ k, w k * f (t - s k)) * y (x - t)‖ :=
          norm_integral_le_integral_norm _
      _ ≤ ∫ t, B * ‖g t - ∑ k, w k * f (t - s k)‖ := by
          refine integral_mono ((hg.mul_bdd (hys x) (hyb x)).sub
            (hm.mul_bdd (hys x) (hyb x))).norm ((hg.sub hm).norm.const_mul B) fun t => ?_
          rw [← sub_mul, norm_mul, mul_comm]
          exact mul_le_mul_of_nonneg_right (hB _) (norm_nonneg _)
      _ = B * ∫ t, ‖g t - ∑ k, w k * f (t - s k)‖ := integral_const_mul _ _
      _ ≤ B * τ := mul_le_mul_of_nonneg_left hmix.le hB0
  have hFm : ‖a * 𝓕 (fun t => ∑ k, w k * f (t - s k)) 0 - a * 𝓕 g 0‖ ≤ ‖a‖ * τ := by
    rw [← mul_sub, norm_mul, norm_sub_rev, ← wt_fourier_sub hg hm]
    exact mul_le_mul_of_nonneg_left ((Real.norm_fourier_le_integral_norm _ 0).trans hmix.le)
      (norm_nonneg _)
  have hmlim : Tendsto (fun x : ℝ => ∫ t, (∑ k, w k * f (t - s k)) * y (x - t)) atTop
      (𝓝 (a * 𝓕 (fun t => ∑ k, w k * f (t - s k)) 0)) := by
    simp_rw [hmy, hm0, Finset.mul_sum]
    apply tendsto_finsetSum
    intro k _
    have hsh : Tendsto (fun x : ℝ => x - s k) atTop atTop :=
      (tendsto_atTop_add_const_right atTop (-(s k)) tendsto_id).congr fun x => by
        simp [sub_eq_add_neg]
    have h2 := (hlim.comp hsh).const_mul (w k)
    rw [show a * (w k * 𝓕 f 0) = w k * (a * 𝓕 f 0) by ring]
    exact h2.congr fun x => rfl
  obtain ⟨X, hX⟩ := Metric.tendsto_atTop.1 hmlim (ε / 2) (half_pos hε)
  refine ⟨X, fun x hx => ?_⟩
  have h3 := hX x hx
  rw [dist_eq_norm] at h3 ⊢
  have h4 := hgm x
  calc ‖(∫ t, g t * y (x - t)) - a * 𝓕 g 0‖
      ≤ ‖(∫ t, g t * y (x - t)) - ∫ t, (∑ k, w k * f (t - s k)) * y (x - t)‖
        + ‖(∫ t, (∑ k, w k * f (t - s k)) * y (x - t))
            - a * 𝓕 (fun t => ∑ k, w k * f (t - s k)) 0‖
        + ‖a * 𝓕 (fun t => ∑ k, w k * f (t - s k)) 0 - a * 𝓕 g 0‖ := by
        refine le_trans (le_of_eq ?_) (norm_add₃_le)
        congr 1; ring
    _ < B * τ + ε / 2 + ‖a‖ * τ := by linarith
    _ ≤ ε := by nlinarith [norm_nonneg a]

/-- A zero of the spectrum blocks (Step 1): if `f̂(ξ₀) = 0`, then every finite mix of shifts of
`f` stays at least `|ĝ(ξ₀)|` away from the integrable target `g` in area. -/
theorem fourier_zero_blocks_mixes {f g : ℝ → ℂ} (hf : Integrable f) (hg : Integrable g)
    {ξ₀ : ℝ} (h0 : 𝓕 f ξ₀ = 0) (K : ℕ) (w : Fin K → ℂ) (s : Fin K → ℝ) :
    ‖𝓕 g ξ₀‖ ≤ ∫ t, ‖g t - ∑ k, w k * f (t - s k)‖ := by
  exact wt_blocks hf hg h0 K w s

/-! Worked numbers, by hand: five firings, `N = 2`, spacing `ε = 1/2` s, gate samples
`0, 1/2, 1, 1/2, 0` at `−1, −1/2, 0, 1/2, 1` s (and `0` beyond). The gain at a grid point with
sample `g` and neighbour samples `gm`, `gp` is `ε/2 · (g − (gp − 2g + gm)/ε²)`. -/

/-- The card's gain formula at one grid point. -/
def gain (ε gm g gp : ℚ) : ℚ := ε / 2 * (g - (gp - 2 * g + gm) / ε ^ 2)

-- gain at 0 s is 5/4 (1.25)
example : gain (1/2) (1/2) 1 (1/2) = 5/4 := by norm_num [gain]
-- gains at ±1/2 s are 1/8 (0.125)
example : gain (1/2) 1 (1/2) 0 = 1/8 := by norm_num [gain]
-- gains at ±1 s are −1/2
example : gain (1/2) (1/2) 0 0 = -1/2 := by norm_num [gain]
-- the gains add to 1/2
example : (-1/2 : ℚ) + 1/8 + 5/4 + 1/8 + (-1/2) = 1/2 := by norm_num
-- the sizes of the gains add to N + 1/2 = 5/2
example : |(-1/2 : ℚ)| + |1/8| + |5/4| + |1/8| + |(-1/2)| = 2 + 1/2 := by norm_num [abs_of_neg, abs_of_pos]
-- area of the mix: sum of gains times the pulse's area 2 V·s is the gate's area 1 V·s
example : (1/2 : ℚ) * 2 = 1 := by norm_num

#print axioms shifts_dense_iff_fourier_ne_zero
#print axioms tauberian_limit_transfer
#print axioms fourier_zero_blocks_mixes
