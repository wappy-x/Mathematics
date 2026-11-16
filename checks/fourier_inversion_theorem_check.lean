-- Fourier inversion: fading an integrable signal's spectrum by a narrowing bell and adding up the waves blurs the signal by a bell, which tends to the midpoint at a clean jump and to the signal where it is continuous, and with an integrable spectrum the plain inverse gives the signal back.
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.MeasureTheory.Function.ContinuousMapDense
import Mathlib.MeasureTheory.Group.Prod
import Mathlib.Topology.UniformSpace.UniformApproximation
import Mathlib.Topology.Order.LeftRight

open MeasureTheory Filter Real
open scoped Topology FourierTransform

/-- The bell rebuild `G_ε f(t) = ∫ f̂(ξ) e^(−π ε² ξ²) e^(2πiξt) dξ`: the spectrum faded by a
frequency bell of width `ε`, then summed back into waves. Mathlib's `𝓕 f ξ` is the card's
`f̂(ξ) = ∫ f(t) e^(−2πiξt) dt`, with `ξ` in hertz. -/
noncomputable def bellRebuild (ε : ℝ) (f : ℝ → ℂ) (t : ℝ) : ℂ :=
  ∫ ξ : ℝ, Complex.exp (-(π : ℂ) * (ε : ℂ) ^ 2 * (ξ : ℂ) ^ 2)
    * Complex.exp (2 * (π : ℂ) * Complex.I * (ξ : ℂ) * (t : ℂ)) * 𝓕 f ξ

theorem fit_rebuild_eq_blur (f : ℝ → ℂ) (hf : Integrable f) {ε : ℝ} (hε : 0 < ε) (t : ℝ) :
    bellRebuild ε f t =
      ∫ s : ℝ, f s * ((1 / ε * Real.exp (-π * (t - s) ^ 2 / ε ^ 2) : ℝ) : ℂ) := by
  have hb : 0 < ((π * ε ^ 2 : ℝ) : ℂ).re := by rw [Complex.ofReal_re]; positivity
  have J : Integrable (fun w : ℝ ↦ Complex.exp (-((π * ε ^ 2 : ℝ) : ℂ) * ‖w‖ ^ 2
      + 2 * π * Complex.I * (inner ℝ t w : ℝ))) :=
    GaussianFourier.integrable_cexp_neg_mul_sq_norm_add hb _ _
  have key := (VectorFourier.integral_fourierIntegral_smul_eq_flip (L := innerₗ ℝ)
      Real.continuous_fourierChar continuous_inner J hf)
  have e1 : ∀ s : ℝ, VectorFourier.fourierIntegral 𝐞 volume (innerₗ ℝ) (fun w : ℝ ↦ Complex.exp (-((π * ε ^ 2 : ℝ) : ℂ) * ‖w‖ ^ 2
      + 2 * π * Complex.I * (inner ℝ t w : ℝ))) s = 𝓕 (fun w : ℝ ↦ Complex.exp (-((π * ε ^ 2 : ℝ) : ℂ) * ‖w‖ ^ 2
      + 2 * π * Complex.I * (inner ℝ t w : ℝ))) s := fun s ↦ rfl
  simp only [e1] at key
  rw [show (VectorFourier.fourierIntegral 𝐞 volume (innerₗ ℝ).flip f) = 𝓕 f from ?_] at key
  swap
  · ext ξ
    rw [fourier_real_eq]
    simp [VectorFourier.fourierIntegral, mul_comm]
  simp only [fourier_gaussian_innerProductSpace' hb] at key
  unfold bellRebuild
  rw [show (∫ ξ : ℝ, Complex.exp (-(π : ℂ) * (ε : ℂ) ^ 2 * (ξ : ℂ) ^ 2) * Complex.exp (2 * (π : ℂ) * Complex.I * (ξ : ℂ) * (t : ℂ)) * 𝓕 f ξ) = ∫ x : ℝ, Complex.exp (-((π * ε ^ 2 : ℝ) : ℂ) * ‖x‖ ^ 2 + 2 * π * Complex.I * (inner ℝ t x : ℝ)) • 𝓕 f x from ?_, ← key]
  · congr 1 with s
    have h1 : ((π:ℂ) / ((π * ε ^ 2 : ℝ) : ℂ)) ^ ((Module.finrank ℝ ℝ : ℂ) / 2)
        = ((1/ε : ℝ) : ℂ) := by
      rw [Module.finrank_self, show ((π:ℂ) / ((π * ε ^ 2 : ℝ) : ℂ)) = (((ε⁻¹)^2 : ℝ) : ℂ) by
        push_cast; field_simp, show ((1:ℕ):ℂ)/2 = ((1/2 : ℝ) : ℂ) by push_cast; ring,
        ← Complex.ofReal_cpow (by positivity), ← Real.sqrt_eq_rpow, Real.sqrt_sq (by positivity),
        one_div]
    have h2 : ((‖t-s‖:ℝ):ℂ)^2 = ((t-s:ℝ):ℂ)^2 := by
      rw [← Complex.ofReal_pow, Real.norm_eq_abs, sq_abs, Complex.ofReal_pow]
    rw [smul_eq_mul, mul_comm _ (f s), h1, h2]
    push_cast
    congr 3
    field_simp
  · congr 1 with x
    have h2 : ((‖x‖:ℝ):ℂ)^2 = ((x:ℝ):ℂ)^2 := by
      rw [← Complex.ofReal_pow, Real.norm_eq_abs, sq_abs, Complex.ofReal_pow]
    rw [smul_eq_mul, Complex.exp_add, h2]
    simp only [RCLike.inner_apply, conj_trivial]
    push_cast
    ring_nf


#print axioms fit_rebuild_eq_blur

theorem fit_blur_tendsto (g : ℝ → ℂ) (hg : Integrable g) (v : ℝ) (hc : ContinuousAt g v) :
    Tendsto (fun ε : ℝ ↦ ∫ s : ℝ, g s * ((1 / ε * Real.exp (-π * (v - s) ^ 2 / ε ^ 2) : ℝ) : ℂ))
      (𝓝[>] 0) (𝓝 (g v)) := by
  have A := Real.tendsto_integral_gaussian_smul' hg hc
  have B : Tendsto (fun ε : ℝ ↦ 1 / (π * ε ^ 2)) (𝓝[>] 0) atTop := by
    have : Tendsto (fun ε : ℝ ↦ π * ε ^ 2) (𝓝[>] 0) (𝓝[>] 0) := by
      apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
      · have hc : Continuous (fun ε : ℝ ↦ π * ε ^ 2) := by fun_prop
        simpa using (hc.tendsto 0).mono_left nhdsWithin_le_nhds
      · filter_upwards [self_mem_nhdsWithin] with ε (hε : 0 < ε)
        exact Set.mem_Ioi.2 (by positivity)
    exact (tendsto_inv_nhdsGT_zero.comp this).congr (fun ε ↦ by simp only [Function.comp, one_div])
  refine (A.comp B).congr' ?_
  filter_upwards [self_mem_nhdsWithin] with ε (hε : 0 < ε)
  simp only [Function.comp]
  congr 1 with s
  have h1 : ((π:ℂ) * ((1 / (π * ε ^ 2) : ℝ) : ℂ)) ^ ((Module.finrank ℝ ℝ : ℂ) / 2)
      = ((1/ε : ℝ) : ℂ) := by
    rw [Module.finrank_self, show ((π:ℂ) * ((1 / (π * ε ^ 2) : ℝ) : ℂ)) = (((ε⁻¹)^2 : ℝ) : ℂ) by
      push_cast; field_simp, show ((1:ℕ):ℂ)/2 = ((1/2 : ℝ) : ℂ) by push_cast; ring,
      ← Complex.ofReal_cpow (by positivity), ← Real.sqrt_eq_rpow, Real.sqrt_sq (by positivity),
      one_div]
  have h2 : ((‖v-s‖:ℝ):ℂ)^2 = ((v-s:ℝ):ℂ)^2 := by
    rw [← Complex.ofReal_pow, Real.norm_eq_abs, sq_abs, Complex.ofReal_pow]
  rw [smul_eq_mul, mul_comm _ (g s), h1, h2]
  push_cast
  congr 3
  field_simp

#print axioms fit_blur_tendsto

theorem fit_kernel_norm_le {ε : ℝ} (hε : 0 < ε) (u : ℝ) :
    ‖((1 / ε * Real.exp (-π * u ^ 2 / ε ^ 2) : ℝ) : ℂ)‖ ≤ 1 / ε := by
  rw [Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg (by positivity)]
  have : Real.exp (-π * u ^ 2 / ε ^ 2) ≤ 1 := by
    rw [Real.exp_le_one_iff]
    have : 0 ≤ π * u ^ 2 / ε ^ 2 := by positivity
    rw [neg_mul, neg_div]; linarith
  calc 1 / ε * Real.exp (-π * u ^ 2 / ε ^ 2) ≤ 1 / ε * 1 := by gcongr
    _ = 1 / ε := mul_one _

#print axioms fit_kernel_norm_le

theorem fit_tendsto_add (t : ℝ) : Tendsto (fun u : ℝ ↦ t + u) (𝓝[>] 0) (𝓝[>] t) := by
  apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
  · have hc : Continuous (fun u : ℝ ↦ t + u) := by fun_prop
    simpa using (hc.tendsto 0).mono_left nhdsWithin_le_nhds
  · filter_upwards [self_mem_nhdsWithin] with u (hu : 0 < u)
    exact Set.mem_Ioi.2 (by linarith)

theorem fit_tendsto_sub (t : ℝ) : Tendsto (fun u : ℝ ↦ t - u) (𝓝[>] 0) (𝓝[<] t) := by
  apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
  · have hc : Continuous (fun u : ℝ ↦ t - u) := by fun_prop
    simpa using (hc.tendsto 0).mono_left nhdsWithin_le_nhds
  · filter_upwards [self_mem_nhdsWithin] with u (hu : 0 < u)
    exact Set.mem_Iio.2 (by linarith)

theorem fit_tendsto_add' (t : ℝ) : Tendsto (fun u : ℝ ↦ t + u) (𝓝[<] 0) (𝓝[<] t) := by
  apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
  · have hc : Continuous (fun u : ℝ ↦ t + u) := by fun_prop
    simpa using (hc.tendsto 0).mono_left nhdsWithin_le_nhds
  · filter_upwards [self_mem_nhdsWithin] with u (hu : u < 0)
    exact Set.mem_Iio.2 (by linarith)

theorem fit_tendsto_sub' (t : ℝ) : Tendsto (fun u : ℝ ↦ t - u) (𝓝[<] 0) (𝓝[>] t) := by
  apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
  · have hc : Continuous (fun u : ℝ ↦ t - u) := by fun_prop
    simpa using (hc.tendsto 0).mono_left nhdsWithin_le_nhds
  · filter_upwards [self_mem_nhdsWithin] with u (hu : u < 0)
    exact Set.mem_Ioi.2 (by linarith)

#print axioms fit_tendsto_add
#print axioms fit_tendsto_sub
#print axioms fit_tendsto_add'
#print axioms fit_tendsto_sub'

theorem fit_midpoint (f : ℝ → ℂ) (hf : Integrable f) (t : ℝ) (a b : ℂ)
    (ha : Tendsto f (𝓝[>] t) (𝓝 a)) (hb : Tendsto f (𝓝[<] t) (𝓝 b)) :
    Tendsto (fun ε ↦ bellRebuild ε f t) (𝓝[>] 0) (𝓝 ((a + b) / 2)) := by
  set h : ℝ → ℂ := fun u ↦ if u = 0 then (a + b) / 2 else (f (t + u) + f (t - u)) / 2 with hh
  have hae : (fun u ↦ (f (t + u) + f (t - u)) / 2) =ᵐ[volume] h := by
    filter_upwards [(Set.countable_singleton (0:ℝ)).ae_notMem volume] with u hu
    simp only [Set.mem_singleton_iff] at hu
    simp [hh, hu]
  have hi1 : Integrable (fun u ↦ f (t + u)) := hf.comp_add_left t
  have hi2 : Integrable (fun u ↦ f (t - u)) := hf.comp_sub_left t
  have hint : Integrable h := ((hi1.add hi2).div_const 2).congr hae
  have hcont : ContinuousAt h 0 := by
    rw [continuousAt_iff_continuous_left'_right']
    constructor
    · have T : Tendsto (fun u ↦ (f (t + u) + f (t - u)) / 2) (𝓝[<] 0) (𝓝 ((a + b) / 2)) := by
        rw [add_comm a b]
        exact ((hb.comp (fit_tendsto_add' t)).add (ha.comp (fit_tendsto_sub' t))).div_const 2
      have h0 : h 0 = (a + b) / 2 := by simp [hh]
      rw [ContinuousWithinAt, h0]
      refine T.congr' ?_
      filter_upwards [self_mem_nhdsWithin] with u (hu : u < 0)
      simp [hh, hu.ne]
    · have T : Tendsto (fun u ↦ (f (t + u) + f (t - u)) / 2) (𝓝[>] 0) (𝓝 ((a + b) / 2)) :=
        ((ha.comp (fit_tendsto_add t)).add (hb.comp (fit_tendsto_sub t))).div_const 2
      have h0 : h 0 = (a + b) / 2 := by simp [hh]
      rw [ContinuousWithinAt, h0]
      refine T.congr' ?_
      filter_upwards [self_mem_nhdsWithin] with u (hu : 0 < u)
      simp [hh, hu.ne']
  have L := fit_blur_tendsto h hint 0 hcont
  have h0 : h 0 = (a + b) / 2 := by simp [hh]
  rw [h0] at L
  refine L.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with ε (hε : 0 < ε)
  rw [fit_rebuild_eq_blur f hf hε t]
  set K : ℝ → ℂ := fun u ↦ ((1 / ε * Real.exp (-π * u ^ 2 / ε ^ 2) : ℝ) : ℂ) with hK
  have hKm : AEStronglyMeasurable K volume := by
    apply Continuous.aestronglyMeasurable
    simp only [hK]; fun_prop
  have hKb : ∀ᵐ u ∂volume, ‖K u‖ ≤ 1 / ε := Eventually.of_forall (fit_kernel_norm_le hε)
  have e1 : (∫ s, h s * ((1 / ε * Real.exp (-π * (0 - s) ^ 2 / ε ^ 2) : ℝ) : ℂ))
      = ∫ s, (f (t + s) * K s + f (t - s) * K s) / 2 := by
    apply integral_congr_ae
    filter_upwards [hae] with s hs
    rw [← hs]
    simp only [hK, zero_sub, neg_sq]
    ring
  have e2 : (∫ s, f s * ((1 / ε * Real.exp (-π * (t - s) ^ 2 / ε ^ 2) : ℝ) : ℂ))
      = ∫ u, f (t - u) * K u := by
    rw [← integral_sub_left_eq_self _ volume t]
    simp [hK]
  have e3 : (∫ u, f (t + u) * K u) = ∫ u, f (t - u) * K u := by
    rw [← integral_neg_eq_self]
    simp [hK, sub_eq_add_neg]
  rw [e1, e2, integral_div, integral_add (hi1.mul_bdd hKm hKb) (hi2.mul_bdd hKm hKb), e3]
  ring

#print axioms fit_midpoint

theorem fit_kernel_eq {ε : ℝ} :
    (fun u : ℝ ↦ 1 / ε * Real.exp (-π * u ^ 2 / ε ^ 2))
      = fun u : ℝ ↦ 1 / ε * Real.exp (-(π / ε ^ 2) * u ^ 2) := by
  funext u; congr 2; ring

theorem fit_kernel_integral {ε : ℝ} (hε : 0 < ε) :
    ∫ u : ℝ, 1 / ε * Real.exp (-π * u ^ 2 / ε ^ 2) = 1 := by
  rw [fit_kernel_eq, integral_const_mul, integral_gaussian,
    show π / (π / ε ^ 2) = ε ^ 2 by field_simp, Real.sqrt_sq hε.le]
  field_simp

theorem fit_kernel_integrable {ε : ℝ} (hε : 0 < ε) :
    Integrable (fun u : ℝ ↦ 1 / ε * Real.exp (-π * u ^ 2 / ε ^ 2)) := by
  rw [fit_kernel_eq]
  exact (integrable_exp_neg_mul_sq (by positivity)).const_mul _

#print axioms fit_kernel_eq
#print axioms fit_kernel_integral
#print axioms fit_kernel_integrable

theorem fit_omega_le (f : ℝ → ℂ) (hf : Integrable f) (u : ℝ) :
    ∫ t, ‖f (t - u) - f t‖ ≤ 2 * ∫ t, ‖f t‖ := by
  have h1 : Integrable (fun t ↦ f (t - u)) := hf.comp_sub_right u
  calc ∫ t, ‖f (t - u) - f t‖ ≤ ∫ t, (‖f (t - u)‖ + ‖f t‖) :=
        integral_mono (h1.sub hf).norm (h1.norm.add hf.norm) (fun t ↦ norm_sub_le _ _)
    _ = 2 * ∫ t, ‖f t‖ := by
        rw [integral_add h1.norm hf.norm, integral_sub_right_eq_self (fun t ↦ ‖f t‖) u]
        ring

#print axioms fit_omega_le

theorem fit_omega_cc (g : ℝ → ℂ) (hg : Continuous g) (hs : HasCompactSupport g) :
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

#print axioms fit_omega_cc

theorem fit_omega_continuous (f : ℝ → ℂ) (hf : Integrable f) :
    Continuous (fun u ↦ ∫ t, ‖f (t - u) - f t‖) := by
  refine continuous_of_uniform_approx_of_continuous fun V hV ↦ ?_
  obtain ⟨δ, δpos, hδ⟩ := Metric.mem_uniformity_dist.1 hV
  obtain ⟨g, hgs, hfg, hgc, hgi⟩ := hf.exists_hasCompactSupport_integral_sub_le (ε := δ / 3)
    (by positivity)
  refine ⟨_, fit_omega_cc g hgc hgs, fun u ↦ hδ ?_⟩
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

#print axioms fit_omega_continuous

theorem fit_mean_bound (f : ℝ → ℂ) (hf : Integrable f) {ε : ℝ} (hε : 0 < ε) :
    ∫ t : ℝ, ‖bellRebuild ε f t - f t‖
      ≤ ∫ v : ℝ, (∫ t, ‖f (t - ε * v) - f t‖) * Real.exp (-π * v ^ 2) := by
  set ω : ℝ → ℝ := fun u ↦ ∫ t, ‖f (t - u) - f t‖ with hω
  set K : ℝ → ℝ := fun u ↦ 1 / ε * Real.exp (-π * u ^ 2 / ε ^ 2) with hK
  have hKi : Integrable K := fit_kernel_integrable hε
  have hK1 : ∫ u, K u = 1 := fit_kernel_integral hε
  have hK0 : ∀ u, 0 ≤ K u := fun u ↦ by simp only [hK]; positivity
  have hωc : Continuous ω := fit_omega_continuous f hf
  have hω0 : ∀ u, 0 ≤ ω u := fun u ↦ integral_nonneg fun t ↦ norm_nonneg _
  have hωb : ∀ u, ω u ≤ 2 * ∫ t, ‖f t‖ := fit_omega_le f hf
  have hKcm : AEStronglyMeasurable (fun u ↦ (K u : ℂ)) volume := by
    apply Continuous.aestronglyMeasurable; simp only [hK]; fun_prop
  have hKcb : ∀ᵐ u ∂volume, ‖(K u : ℂ)‖ ≤ 1 / ε := Eventually.of_forall (fit_kernel_norm_le hε)
  -- step a: pointwise bound
  have stepA : ∀ t, ‖bellRebuild ε f t - f t‖ ≤ ∫ u, ‖f (t - u) - f t‖ * K u := by
    intro t
    have e2 : bellRebuild ε f t = ∫ u, f (t - u) * (K u : ℂ) := by
      rw [fit_rebuild_eq_blur f hf hε t, ← integral_sub_left_eq_self _ volume t]
      simp [hK]
    have e3 : f t = ∫ u, f t * (K u : ℂ) := by
      rw [integral_const_mul, integral_complex_ofReal, hK1]; simp
    have i1 : Integrable (fun u ↦ f (t - u) * (K u : ℂ)) :=
      (hf.comp_sub_left t).mul_bdd hKcm hKcb
    have i2 : Integrable (fun u ↦ f t * (K u : ℂ)) := hKi.ofReal.const_mul _
    conv_lhs => rw [e2, e3, ← integral_sub i1 i2]
    refine (norm_integral_le_integral_norm _).trans (le_of_eq ?_)
    congr 1 with u
    rw [← sub_mul, norm_mul, Complex.norm_real, Real.norm_of_nonneg (hK0 u)]
  -- product integrability
  set H : ℝ × ℝ → ℝ := fun p ↦ ‖f (p.1 - p.2) - f p.1‖ * K p.2 with hH
  have hHm : AEStronglyMeasurable H (volume.prod volume) := by
    have a1 : AEStronglyMeasurable (fun p : ℝ × ℝ ↦ f (p.1 - p.2)) (volume.prod volume) :=
      hf.aestronglyMeasurable.comp_quasiMeasurePreserving
        (quasiMeasurePreserving_sub_of_right_invariant volume volume)
    have a2 : AEStronglyMeasurable (fun p : ℝ × ℝ ↦ f p.1) (volume.prod volume) :=
      hf.aestronglyMeasurable.comp_fst
    have a3 : AEStronglyMeasurable (fun p : ℝ × ℝ ↦ K p.2) (volume.prod volume) := by
      apply Continuous.aestronglyMeasurable; simp only [hK]; fun_prop
    exact (a1.sub a2).norm.mul a3
  have hωK : Integrable (fun u ↦ ω u * K u) :=
    hKi.bdd_mul hωc.aestronglyMeasurable (Eventually.of_forall fun u ↦ by
      rw [Real.norm_of_nonneg (hω0 u)]; exact hωb u)
  have hHi : Integrable H (volume.prod volume) := by
    rw [integrable_prod_iff' hHm]
    refine ⟨Eventually.of_forall fun u ↦ ?_, ?_⟩
    · show Integrable (fun t ↦ ‖f (t - u) - f t‖ * K u)
      exact ((hf.comp_sub_right u).sub hf).norm.mul_const _
    · refine hωK.congr (Eventually.of_forall fun u ↦ ?_)
      simp only [hH, hω]
      rw [← integral_mul_const]
      congr 1 with t
      rw [Real.norm_of_nonneg (mul_nonneg (norm_nonneg _) (hK0 u))]
  -- steps b, c
  have stepB : ∫ t, ‖bellRebuild ε f t - f t‖ ≤ ∫ t, ∫ u, H (t, u) :=
    integral_mono_of_nonneg (Eventually.of_forall fun t ↦ norm_nonneg _)
      hHi.integral_prod_left (Eventually.of_forall stepA)
  have stepC : ∫ t, ∫ u, H (t, u) = ∫ u, ω u * K u := by
    rw [integral_integral_swap (f := fun t u ↦ H (t, u)) hHi]
    congr 1 with u
    simp only [hH, hω]
    rw [integral_mul_const]
  -- step d: rescale
  have stepD : ∫ u, ω u * K u = ∫ v, ω (ε * v) * Real.exp (-π * v ^ 2) := by
    have := Measure.integral_comp_mul_left (fun u ↦ ω u * K u) ε
    have e : (fun v ↦ ω (ε * v) * K (ε * v))
        = fun v ↦ ε⁻¹ * (ω (ε * v) * Real.exp (-π * v ^ 2)) := by
      funext v
      simp only [hK]
      rw [show -π * (ε * v) ^ 2 / ε ^ 2 = -π * v ^ 2 by field_simp]
      ring
    rw [e, integral_const_mul, abs_of_pos (inv_pos.2 hε), smul_eq_mul] at this
    exact (mul_left_cancel₀ (inv_ne_zero hε.ne') this).symm
  rw [stepC, stepD] at stepB
  exact stepB

#print axioms fit_mean_bound

theorem fit_in_mean (f : ℝ → ℂ) (hf : Integrable f) :
    Tendsto (fun ε ↦ ∫ t : ℝ, ‖bellRebuild ε f t - f t‖) (𝓝[>] 0) (𝓝 0) := by
  set ω : ℝ → ℝ := fun u ↦ ∫ t, ‖f (t - u) - f t‖ with hω
  have hωc : Continuous ω := fit_omega_continuous f hf
  have hω0 : ∀ u, 0 ≤ ω u := fun u ↦ integral_nonneg fun t ↦ norm_nonneg _
  have hωb : ∀ u, ω u ≤ 2 * ∫ t, ‖f t‖ := fit_omega_le f hf
  have hωz : ω 0 = 0 := by simp [hω]
  have lim : Tendsto (fun ε : ℝ ↦ ∫ v : ℝ, ω (ε * v) * Real.exp (-π * v ^ 2)) (𝓝[>] 0)
      (𝓝 (∫ v : ℝ, ω (0 * v) * Real.exp (-π * v ^ 2))) := by
    refine tendsto_integral_filter_of_dominated_convergence
      (fun v ↦ (2 * ∫ t, ‖f t‖) * Real.exp (-π * v ^ 2)) ?_ ?_ ?_ ?_
    · exact Eventually.of_forall fun ε ↦ by
        apply Continuous.aestronglyMeasurable
        exact (hωc.comp (continuous_const.mul continuous_id)).mul (by fun_prop)
    · refine Eventually.of_forall fun ε ↦ Eventually.of_forall fun v ↦ ?_
      rw [Real.norm_of_nonneg (mul_nonneg (hω0 _) (Real.exp_pos _).le)]
      exact mul_le_mul_of_nonneg_right (hωb _) (Real.exp_pos _).le
    · exact (integrable_exp_neg_mul_sq Real.pi_pos).const_mul _
    · refine Eventually.of_forall fun v ↦ ?_
      have : Tendsto (fun ε : ℝ ↦ ε * v) (𝓝[>] 0) (𝓝 (0 * v)) :=
        ((continuous_id.mul continuous_const).tendsto 0).mono_left nhdsWithin_le_nhds
      exact ((hωc.tendsto _).comp this).mul_const _
  simp only [zero_mul, hωz, integral_zero] at lim
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds lim
    (Eventually.of_forall fun ε ↦ integral_nonneg fun t ↦ norm_nonneg _) ?_
  filter_upwards [self_mem_nhdsWithin] with ε (hε : 0 < ε)
  exact fit_mean_bound f hf hε

#print axioms fit_in_mean

/-- **Fourier inversion theorem.** For an integrable signal `f` and a time `t`: as the bell width
`ε` shrinks to 0, the bell rebuild tends to `f(t)` where `f` is continuous, and to the midpoint
`(f(t⁺) + f(t⁻))/2` at a clean jump; and when the spectrum is integrable too (finite area under
`|f̂|`), the plain inverse `∫ f̂(ξ) e^(2πiξt) dξ`, with no factor in front, equals `f(t)` wherever
`f` is continuous. -/
theorem fourier_inversion_theorem (f : ℝ → ℂ) (hf : Integrable f) (t : ℝ) :
    (ContinuousAt f t →
      Tendsto (fun ε ↦ bellRebuild ε f t) (𝓝[>] 0) (𝓝 (f t))) ∧
    (∀ a b : ℂ, Tendsto f (𝓝[>] t) (𝓝 a) → Tendsto f (𝓝[<] t) (𝓝 b) →
      Tendsto (fun ε ↦ bellRebuild ε f t) (𝓝[>] 0) (𝓝 ((a + b) / 2))) ∧
    (Integrable (𝓕 f) → ContinuousAt f t → 𝓕⁻ (𝓕 f) t = f t) := by
  refine ⟨fun hc ↦ ?_, fun a b ha hb ↦ fit_midpoint f hf t a b ha hb,
    fun hF hc ↦ hf.fourierInv_fourier_eq hF hc⟩
  have := fit_midpoint f hf t (f t) (f t) (hc.tendsto.mono_left nhdsWithin_le_nhds)
    (hc.tendsto.mono_left nhdsWithin_le_nhds)
  rwa [add_self_div_two] at this

/-- **Fading the spectrum is blurring the signal.** For an integrable signal and a bell width
`ε > 0`, the bell rebuild equals the signal averaged against the time bell
`g_ε(u) = (1/ε) e^(−π u²/ε²)`: `G_ε f(t) = ∫ f(s) g_ε(t − s) ds`. -/
theorem bell_rebuild_eq_blur (f : ℝ → ℂ) (hf : Integrable f) {ε : ℝ} (hε : 0 < ε) (t : ℝ) :
    bellRebuild ε f t =
      ∫ s : ℝ, f s * ((1 / ε * Real.exp (-π * (t - s) ^ 2 / ε ^ 2) : ℝ) : ℂ) := by
  exact fit_rebuild_eq_blur f hf hε t

/-- **Convergence in the mean.** For every integrable signal, the area under
`|G_ε f − f|` tends to 0 as the bell width `ε` shrinks to 0. -/
theorem bell_rebuild_tendsto_in_mean (f : ℝ → ℂ) (hf : Integrable f) :
    Tendsto (fun ε ↦ ∫ t : ℝ, ‖bellRebuild ε f t - f t‖) (𝓝[>] 0) (𝓝 0) := by
  exact fit_in_mean f hf

#print axioms fourier_inversion_theorem
#print axioms bell_rebuild_eq_blur
#print axioms bell_rebuild_tendsto_in_mean
