-- Convolution and mollifiers: averaging a function against a narrowing smooth symmetric bump of area 1 makes it smooth, never larger, and returns it in every Lp size with p finite and uniformly when it is uniformly continuous.
import Mathlib.Analysis.Calculus.ContDiff.Convolution
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.Function.ContinuousMapDense
import Mathlib.MeasureTheory.Function.LpSeminorm.CompareExp
import Mathlib.MeasureTheory.Measure.Haar.NormedSpace
import Mathlib.MeasureTheory.Measure.Haar.Unique
import Mathlib.Analysis.Calculus.ContDiff.Operations

open MeasureTheory Filter Topology
open scoped Convolution ContDiff ENNReal

open scoped Pointwise

lemma moll_aux_contDiff {η : ℝ → ℝ} (hη : ContDiff ℝ ∞ η) (ε : ℝ) :
    ContDiff ℝ ∞ (fun s => ε⁻¹ * η (s / ε)) :=
  ContDiff.mul contDiff_const (hη.comp (contDiff_id.div_const ε))

lemma moll_aux_support {η : ℝ → ℝ} (hsupp : Function.support η ⊆ Set.Icc (-1) 1)
    {ε : ℝ} (hε : 0 < ε) :
    Function.support (fun s => ε⁻¹ * η (s / ε)) ⊆ Set.Icc (-ε) ε := by
  intro s hs
  have h : s / ε ∈ Set.Icc (-1 : ℝ) 1 := hsupp (fun h => hs (by simp [h]))
  rw [Set.mem_Icc, le_div_iff₀ hε, div_le_iff₀ hε] at h
  constructor <;> linarith [h.1, h.2]

lemma moll_aux_hasCompactSupport {η : ℝ → ℝ} (hsupp : Function.support η ⊆ Set.Icc (-1) 1)
    {ε : ℝ} (hε : 0 < ε) :
    HasCompactSupport (fun s => ε⁻¹ * η (s / ε)) :=
  HasCompactSupport.of_support_subset_isCompact isCompact_Icc (moll_aux_support hsupp hε)

lemma moll_aux_nonneg {η : ℝ → ℝ} (hnn : ∀ u, 0 ≤ η u) {ε : ℝ} (hε : 0 < ε) (s : ℝ) :
    0 ≤ ε⁻¹ * η (s / ε) :=
  mul_nonneg (inv_nonneg.2 hε.le) (hnn _)

lemma moll_aux_integral {η : ℝ → ℝ} (harea : ∫ u, η u = 1) {ε : ℝ} (hε : 0 < ε) :
    ∫ s, ε⁻¹ * η (s / ε) = 1 := by
  rw [integral_const_mul, Measure.integral_comp_div, harea, abs_of_pos hε, smul_eq_mul,
    mul_one, inv_mul_cancel₀ hε.ne']

lemma jensen_aux_lintegral {Φ G : ℝ → ℝ≥0∞} (hΦ : Measurable Φ) (hΦ1 : ∫⁻ t, Φ t = 1)
    (hG : Measurable G) {r : ℝ} (hr : 1 ≤ r) :
    (∫⁻ t, Φ t * G t) ^ r ≤ ∫⁻ t, Φ t * G t ^ r := by
  set ν := volume.withDensity Φ
  have : IsProbabilityMeasure ν := ⟨by simp [ν, withDensity_apply _ MeasurableSet.univ, hΦ1]⟩
  have h1 : ∫⁻ t, Φ t * G t = ∫⁻ t, G t ∂ν :=
    (lintegral_withDensity_eq_lintegral_mul _ hΦ hG).symm
  have h2 : ∫⁻ t, Φ t * G t ^ r = ∫⁻ t, G t ^ r ∂ν :=
    (lintegral_withDensity_eq_lintegral_mul _ hΦ (hG.pow_const r)).symm
  rw [h1, h2]
  have hle : (1 : ℝ≥0∞) ≤ ENNReal.ofReal r := by simpa using ENNReal.ofReal_le_ofReal hr
  have := eLpNorm_le_eLpNorm_of_exponent_le (μ := ν) (f := G) hle
  rw [eLpNorm_one_eq_lintegral_enorm hG.aestronglyMeasurable,
    eLpNorm_eq_lintegral_rpow_enorm_toReal (by positivity) ENNReal.ofReal_ne_top
      hG.aestronglyMeasurable, ENNReal.toReal_ofReal (by linarith)] at this
  simp only [enorm_eq_self] at this
  calc (∫⁻ t, G t ∂ν) ^ r ≤ ((∫⁻ t, G t ^ r ∂ν) ^ (1 / r)) ^ r :=
        ENNReal.rpow_le_rpow this (by linarith)
    _ = ∫⁻ t, G t ^ r ∂ν := by
        rw [← ENNReal.rpow_mul, one_div_mul_cancel (by linarith), ENNReal.rpow_one]

lemma young_aux_eLpNorm_one {φ : ℝ → ℝ} (hφn : ∀ u, 0 ≤ φ u) (hφi : ∫ u, φ u = 1) :
    eLpNorm φ 1 volume = 1 := by
  have hint : Integrable φ := integrable_of_integral_eq_one hφi
  rw [eLpNorm_one_eq_lintegral_enorm hint.aestronglyMeasurable]
  simp_rw [Real.enorm_eq_ofReal (hφn _)]
  rw [← ofReal_integral_eq_lintegral_ofReal hint (Eventually.of_forall hφn), hφi,
    ENNReal.ofReal_one]

lemma young_aux_lintegral {φ : ℝ → ℝ} (hφn : ∀ u, 0 ≤ φ u) (hφi : ∫ u, φ u = 1) :
    ∫⁻ u, ENNReal.ofReal (φ u) = 1 := by
  have hint : Integrable φ := integrable_of_integral_eq_one hφi
  rw [← ofReal_integral_eq_lintegral_ofReal hint (Eventually.of_forall hφn), hφi,
    ENNReal.ofReal_one]

lemma young_aux {φ : ℝ → ℝ} (hφc : Continuous φ) (hφn : ∀ u, 0 ≤ φ u)
    (hφi : ∫ u, φ u = 1) {p : ℝ≥0∞} (hp1 : 1 ≤ p) {f : ℝ → ℝ} (hf : MemLp f p) :
    eLpNorm (φ ⋆ f) p volume ≤ eLpNorm f p volume := by
  set g := hf.aestronglyMeasurable.mk f with hg_def
  have hfg : f =ᵐ[volume] g := hf.aestronglyMeasurable.ae_eq_mk
  have hg : StronglyMeasurable g := hf.aestronglyMeasurable.stronglyMeasurable_mk
  rw [convolution_congr _ (EventuallyEq.refl _ _) hfg, eLpNorm_congr_ae hfg]
  by_cases hp : p = ⊤
  · subst hp
    have hcm : AEStronglyMeasurable (φ ⋆ g) volume :=
      hφc.aestronglyMeasurable.convolution _ hg.aestronglyMeasurable
    rw [eLpNorm_exponent_top hcm]
    apply eLpNormEssSup_le_of_ae_enorm_bound
    filter_upwards with x
    have hL : ‖(ContinuousLinearMap.lsmul ℝ ℝ : ℝ →L[ℝ] ℝ →L[ℝ] ℝ)‖ₑ ≤ 1 := by
      rw [← ofReal_norm]
      exact ENNReal.ofReal_le_one.2 ContinuousLinearMap.opNorm_lsmul_le
    calc ‖(φ ⋆ g) x‖ₑ ≤ ‖(ContinuousLinearMap.lsmul ℝ ℝ : ℝ →L[ℝ] ℝ →L[ℝ] ℝ)‖ₑ *
          eLpNorm φ 1 volume * eLpNorm g ⊤ volume :=
          enorm_convolution_le (p := 1) (q := ⊤) _ hφc.aestronglyMeasurable
            hg.aestronglyMeasurable x
      _ ≤ 1 * 1 * eLpNorm g ⊤ volume := by
          rw [young_aux_eLpNorm_one hφn hφi]; gcongr
      _ = eLpNorm g ⊤ volume := by simp
  · have hp0 : p ≠ 0 := (lt_of_lt_of_le zero_lt_one hp1).ne'
    set r := p.toReal with hr_def
    have hr : 1 ≤ r := by
      rw [hr_def]
      have := ENNReal.toReal_mono hp hp1
      simpa using this
    have hcm : AEStronglyMeasurable (φ ⋆ g) volume :=
      hφc.aestronglyMeasurable.convolution _ hg.aestronglyMeasurable
    rw [eLpNorm_eq_lintegral_rpow_enorm_toReal hp0 hp hcm,
      eLpNorm_eq_lintegral_rpow_enorm_toReal hp0 hp hg.aestronglyMeasurable]
    refine ENNReal.rpow_le_rpow ?_ (by positivity)
    set Φ : ℝ → ℝ≥0∞ := fun t => ENNReal.ofReal (φ t)
    have hΦ : Measurable Φ := hφc.measurable.ennreal_ofReal
    have hΦ1 : ∫⁻ t, Φ t = 1 := young_aux_lintegral hφn hφi
    have hgm : Measurable g := hg.measurable
    have hpt : ∀ x, ‖(φ ⋆ g) x‖ₑ ^ r ≤ ∫⁻ t, Φ t * ‖g (x - t)‖ₑ ^ r := by
      intro x
      have h1 : ‖(φ ⋆ g) x‖ₑ ≤ ∫⁻ t, Φ t * ‖g (x - t)‖ₑ := by
        rw [convolution_def]
        refine (enorm_integral_le_lintegral_enorm _).trans (lintegral_mono fun t => ?_)
        simp only [ContinuousLinearMap.lsmul_apply, smul_eq_mul, enorm_mul, Φ,
          Real.enorm_eq_ofReal (hφn t), le_refl]
      calc ‖(φ ⋆ g) x‖ₑ ^ r ≤ (∫⁻ t, Φ t * ‖g (x - t)‖ₑ) ^ r :=
            ENNReal.rpow_le_rpow h1 (by linarith)
        _ ≤ _ := jensen_aux_lintegral hΦ hΦ1 ((hgm.comp (measurable_const.sub measurable_id)).enorm) hr
    calc ∫⁻ x, ‖(φ ⋆ g) x‖ₑ ^ r ≤ ∫⁻ x, ∫⁻ t, Φ t * ‖g (x - t)‖ₑ ^ r := lintegral_mono hpt
      _ = ∫⁻ t, ∫⁻ x, Φ t * ‖g (x - t)‖ₑ ^ r := by
          apply lintegral_lintegral_swap
          exact ((hΦ.comp measurable_snd).mul
            ((hgm.comp (measurable_fst.sub measurable_snd)).enorm.pow_const r)).aemeasurable
      _ = ∫⁻ t, Φ t * ∫⁻ x, ‖g x‖ₑ ^ r := by
          congr 1; ext t
          rw [lintegral_const_mul (Φ t) (f := fun x => ‖g (x - t)‖ₑ ^ r) ((hgm.comp (measurable_id.sub measurable_const)).enorm.pow_const r)]
          congr 1
          exact lintegral_sub_right_eq_self (fun x => ‖g x‖ₑ ^ r) t
      _ = ∫⁻ x, ‖g x‖ₑ ^ r := by
          rw [lintegral_mul_const _ hΦ, hΦ1, one_mul]

lemma moll_aux_close {η : ℝ → ℝ} (hη_nonneg : ∀ u, 0 ≤ η u)
    (hη_supp : Function.support η ⊆ Set.Icc (-1) 1) (hη_area : ∫ u, η u = 1)
    {g : ℝ → ℝ} (hgc : Continuous g) {ρ δ : ℝ} (hδ : 0 ≤ δ)
    (hρ : ∀ x y, dist x y < ρ → dist (g x) (g y) ≤ δ) {ε : ℝ} (hε : 0 < ε) (hερ : ε < ρ)
    (x : ℝ) : dist (((fun s => ε⁻¹ * η (s / ε)) ⋆ g) x) (g x) ≤ δ := by
  have hsupp : Function.support (fun s => ε⁻¹ * η (s / ε)) ⊆ Metric.ball (0 : ℝ) ρ := by
    intro s hs
    have h := moll_aux_support hη_supp hε hs
    rw [Metric.mem_ball, dist_zero_right, Real.norm_eq_abs, abs_lt]
    constructor <;> linarith [h.1, h.2]
  exact dist_convolution_le hδ hsupp (moll_aux_nonneg hη_nonneg hε)
    (moll_aux_integral hη_area hε) hgc.aestronglyMeasurable (fun y hy => hρ y x hy)

lemma moll_aux_Lp_compact {η : ℝ → ℝ} (hη_smooth : ContDiff ℝ ∞ η)
    (hη_nonneg : ∀ u, 0 ≤ η u)
    (hη_supp : Function.support η ⊆ Set.Icc (-1) 1) (hη_area : ∫ u, η u = 1)
    {p : ℝ≥0∞} {g : ℝ → ℝ} (hgc : Continuous g) (hgs : HasCompactSupport g)
    {δ : ℝ≥0∞} (hδ : 0 < δ) :
    ∀ᶠ ε in 𝓝[>] (0 : ℝ),
      eLpNorm ((fun s => ε⁻¹ * η (s / ε)) ⋆ g - g) p volume ≤ δ := by
  set K : Set ℝ := Set.Icc (-1 : ℝ) 1 + tsupport g with hK_def
  have hK : IsCompact K := isCompact_Icc.add hgs.isCompact
  set C : ℝ≥0∞ := (volume K) ^ p.toReal⁻¹ with hC_def
  have hC : C ≠ ⊤ := ENNReal.rpow_ne_top_of_nonneg (by positivity) hK.measure_lt_top.ne
  have hlim : Tendsto (fun t : ℝ => C * ENNReal.ofReal t) (𝓝 0) (𝓝 0) := by
    have := ENNReal.Tendsto.const_mul (ENNReal.tendsto_ofReal (tendsto_id (x := 𝓝 (0 : ℝ))))
      (a := C) (Or.inr hC)
    simpa using this
  obtain ⟨δ', hδ'pos, hδ'⟩ : ∃ δ' : ℝ, 0 < δ' ∧ C * ENNReal.ofReal δ' < δ := by
    have h1 := (hlim.mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))).eventually (gt_mem_nhds hδ)
    have h2 : ∀ᶠ t in 𝓝[>] (0 : ℝ), 0 < t := self_mem_nhdsWithin
    obtain ⟨t, ht1, ht2⟩ := (h1.and h2).exists
    exact ⟨t, ht2, ht1⟩
  obtain ⟨ρ, hρpos, hρ⟩ :=
    Metric.uniformContinuous_iff.1 (hgs.uniformContinuous_of_continuous hgc) δ' hδ'pos
  have hmem : Set.Ioo (0 : ℝ) (min ρ 1) ∈ 𝓝[>] (0 : ℝ) := Ioo_mem_nhdsGT (lt_min hρpos one_pos)
  filter_upwards [hmem] with ε hε
  have hε0 : 0 < ε := hε.1
  have hερ : ε < ρ := lt_of_lt_of_le hε.2 (min_le_left _ _)
  have hε1 : ε ≤ 1 := (lt_of_lt_of_le hε.2 (min_le_right _ _)).le
  set φ : ℝ → ℝ := fun s => ε⁻¹ * η (s / ε) with hφ_def
  have hφc : Continuous φ := (moll_aux_contDiff hη_smooth ε).continuous
  have hφs : HasCompactSupport φ := moll_aux_hasCompactSupport hη_supp hε0
  have hcont : Continuous (φ ⋆ g - g) :=
    (hφs.continuous_convolution_left _ hφc hgc.locallyIntegrable).sub hgc
  have hsub : Function.support (φ ⋆ g - g) ⊆ K := by
    refine (Function.support_sub _ _).trans (Set.union_subset ?_ ?_)
    · refine (support_convolution_subset _).trans (Set.add_subset_add ?_ (subset_tsupport g))
      intro s hs
      have h := moll_aux_support hη_supp hε0 hs
      exact ⟨by linarith [h.1], by linarith [h.2]⟩
    · intro s hs
      exact ⟨0, ⟨by norm_num, by norm_num⟩, s, subset_tsupport g hs, zero_add s⟩
  rw [← eLpNorm_restrict_eq_of_support_subset hcont.aestronglyMeasurable hsub]
  have hbound : ∀ᵐ x ∂(volume.restrict K), ‖(φ ⋆ g - g) x‖ ≤ δ' := by
    refine Eventually.of_forall fun x => ?_
    rw [Pi.sub_apply, ← dist_eq_norm]
    exact moll_aux_close hη_nonneg hη_supp hη_area hgc hδ'pos.le
      (fun a b hab => (hρ hab).le) hε0 hερ x
  refine (eLpNorm_le_of_ae_bound hcont.aestronglyMeasurable.restrict hbound).trans ?_
  rw [Measure.restrict_apply_univ]
  exact hδ'.le

#print axioms moll_aux_contDiff
#print axioms moll_aux_support
#print axioms moll_aux_hasCompactSupport
#print axioms moll_aux_nonneg
#print axioms moll_aux_integral
#print axioms jensen_aux_lintegral
#print axioms young_aux_eLpNorm_one
#print axioms young_aux_lintegral
#print axioms young_aux
#print axioms moll_aux_close
#print axioms moll_aux_Lp_compact

/-- The mollifier recovers every Lp track. Let `η` be a smooth bump: non-negative, zero outside
`[-1, 1]`, of area 1 and symmetric. Narrow it to half-width `ε` as `η_ε(s) = η(s / ε) / ε`.
For `1 ≤ p < ∞` and every `f` in `Lp`, the Lp size of the gap `η_ε * f - f` tends to 0 as the
width `ε` shrinks to 0. -/
theorem mollifier_convolution_tendsto_in_Lp {η : ℝ → ℝ} (hη_smooth : ContDiff ℝ ∞ η)
    (hη_nonneg : ∀ u, 0 ≤ η u) (hη_supp : Function.support η ⊆ Set.Icc (-1) 1)
    (hη_area : ∫ u, η u = 1) (hη_symm : ∀ u, η (-u) = η u)
    {p : ℝ≥0∞} (hp1 : 1 ≤ p) (hp : p ≠ ⊤) {f : ℝ → ℝ} (hf : MemLp f p) :
    Tendsto (fun ε : ℝ => eLpNorm ((fun s => ε⁻¹ * η (s / ε)) ⋆ f - f) p volume)
      (𝓝[>] 0) (𝓝 0) := by
  rw [ENNReal.tendsto_nhds_zero]
  intro δ hδ
  have hδ3 : δ / 3 ≠ 0 := (ENNReal.div_pos hδ.ne' (by norm_num)).ne'
  obtain ⟨g, hgs, hfg, hgc, hgm⟩ := hf.exists_hasCompactSupport_eLpNorm_sub_le hp hδ3
  have hfl : LocallyIntegrable f volume := hf.locallyIntegrable hp1
  have hgl : LocallyIntegrable g volume := hgc.locallyIntegrable
  filter_upwards [moll_aux_Lp_compact hη_smooth hη_nonneg hη_supp hη_area (p := p) hgc hgs
      (pos_iff_ne_zero.2 hδ3), self_mem_nhdsWithin] with ε hε hε0
  have hε0 : (0 : ℝ) < ε := hε0
  set φ : ℝ → ℝ := fun s => ε⁻¹ * η (s / ε) with hφ_def
  have hφc : Continuous φ := (moll_aux_contDiff hη_smooth ε).continuous
  have hφs : HasCompactSupport φ := moll_aux_hasCompactSupport hη_supp hε0
  have e1 : φ ⋆ f = φ ⋆ (f - g) + φ ⋆ g := by
    rw [← ConvolutionExists.distrib_add (hφs.convolutionExists_left _ hφc (hfl.sub hgl))
      (hφs.convolutionExists_left _ hφc hgl), sub_add_cancel]
  have e2 : φ ⋆ f - f = (φ ⋆ (f - g) + (φ ⋆ g - g)) + (g - f) := by rw [e1]; abel
  rw [e2]
  have m1 : AEStronglyMeasurable (φ ⋆ (f - g)) volume :=
    (hφs.continuous_convolution_left _ hφc (hfl.sub hgl)).aestronglyMeasurable
  have m2 : AEStronglyMeasurable (φ ⋆ g - g) volume :=
    ((hφs.continuous_convolution_left _ hφc hgl).sub hgc).aestronglyMeasurable
  have m3 : AEStronglyMeasurable (g - f) volume :=
    hgm.aestronglyMeasurable.sub hf.aestronglyMeasurable
  have hy : eLpNorm (φ ⋆ (f - g)) p volume ≤ eLpNorm (f - g) p volume :=
    young_aux hφc (moll_aux_nonneg hη_nonneg hε0) (moll_aux_integral hη_area hε0) hp1
      (hf.sub hgm)
  calc eLpNorm (φ ⋆ (f - g) + (φ ⋆ g - g) + (g - f)) p volume
      ≤ eLpNorm (φ ⋆ (f - g) + (φ ⋆ g - g)) p volume + eLpNorm (g - f) p volume :=
        eLpNorm_add_le hp1
    _ ≤ eLpNorm (φ ⋆ (f - g)) p volume + eLpNorm (φ ⋆ g - g) p volume +
          eLpNorm (g - f) p volume := by
        gcongr
        exact eLpNorm_add_le hp1
    _ ≤ δ / 3 + δ / 3 + δ / 3 := by
        gcongr
        · exact hy.trans hfg
        · rw [eLpNorm_sub_comm]; exact hfg
    _ = δ := ENNReal.add_thirds δ

/-- The worst-case gap closes for a uniformly continuous track. With the same bump, if `f` is
bounded and uniformly continuous, then `η_ε * f` tends to `f` uniformly (in the sup norm) as
`ε` shrinks to 0. -/
theorem mollifier_convolution_tendsto_uniformly {η : ℝ → ℝ} (hη_smooth : ContDiff ℝ ∞ η)
    (hη_nonneg : ∀ u, 0 ≤ η u) (hη_supp : Function.support η ⊆ Set.Icc (-1) 1)
    (hη_area : ∫ u, η u = 1) (hη_symm : ∀ u, η (-u) = η u)
    {f : ℝ → ℝ} (hf_bdd : ∃ C, ∀ x, |f x| ≤ C) (hf_uc : UniformContinuous f) :
    TendstoUniformly (fun ε : ℝ => (fun s => ε⁻¹ * η (s / ε)) ⋆ f) f (𝓝[>] 0) := by
  rw [Metric.tendstoUniformly_iff]
  intro δ hδ
  obtain ⟨ρ, hρpos, hρ⟩ := Metric.uniformContinuous_iff.1 hf_uc (δ / 2) (by positivity)
  filter_upwards [Ioo_mem_nhdsGT hρpos] with ε hε x
  rw [dist_comm]
  have := moll_aux_close hη_nonneg hη_supp hη_area hf_uc.continuous
    (by positivity : (0 : ℝ) ≤ δ / 2) (fun a b hab => (hρ hab).le) hε.1 hε.2 x
  linarith

/-- Smoothing makes the track infinitely smooth and never larger. With the same bump, for every
width `ε > 0`, every `1 ≤ p ≤ ∞` and every `f` in `Lp`: `η_ε * f` has derivatives of every order,
its derivative falls on the bump, `(η_ε * f)' = η_ε' * f`, and `‖η_ε * f‖_p ≤ ‖f‖_p`. -/
theorem mollifier_convolution_smooth_and_no_larger {η : ℝ → ℝ} (hη_smooth : ContDiff ℝ ∞ η)
    (hη_nonneg : ∀ u, 0 ≤ η u) (hη_supp : Function.support η ⊆ Set.Icc (-1) 1)
    (hη_area : ∫ u, η u = 1) (hη_symm : ∀ u, η (-u) = η u)
    {ε : ℝ} (hε : 0 < ε) {p : ℝ≥0∞} (hp1 : 1 ≤ p) {f : ℝ → ℝ} (hf : MemLp f p) :
    ContDiff ℝ ∞ ((fun s => ε⁻¹ * η (s / ε)) ⋆ f) ∧
      deriv ((fun s => ε⁻¹ * η (s / ε)) ⋆ f) = deriv (fun s => ε⁻¹ * η (s / ε)) ⋆ f ∧
      eLpNorm ((fun s => ε⁻¹ * η (s / ε)) ⋆ f) p volume ≤ eLpNorm f p volume := by
  have hφs := moll_aux_hasCompactSupport hη_supp hε
  have hφd := moll_aux_contDiff hη_smooth ε
  have hfl : LocallyIntegrable f volume := hf.locallyIntegrable hp1
  refine ⟨hφs.contDiff_convolution_left _ hφd hfl, ?_, ?_⟩
  · funext x
    exact (hφs.hasDerivAt_convolution_left _ (hφd.of_le (by simp)) hfl x).deriv
  · exact young_aux hφd.continuous (moll_aux_nonneg hη_nonneg hε)
      (moll_aux_integral hη_area hε) hp1 hf

-- The 11 fixes, in metres: their total, which is also the joined track's area in m·s, is 10.
example : ([0, 2, -1, 3, 1, 4, 0, 2, -2, 1, 0] : List ℤ).sum = 10 := by decide

-- The change of slope at the 5 s corner: in at 4 - 1 = 3 m/s, out at 0 - 4 = -4 m/s.
example : ((0 : ℤ) - 4) - (4 - 1) = -7 := by decide

-- The held track's jumps, at 1, 2, ..., 10 s, add to 28 m.
example : (List.zipWith (fun a b => |b - a|) [0, 2, -1, 3, 1, 4, 0, 2, -2, 1]
    [2, -1, 3, 1, 4, 0, 2, -2, 1, 0] : List ℤ).sum = 28 := by decide

-- The smoothed slope at the 5 s corner is the average of the slopes in and out: -1/2 m/s.
example : ((3 : ℚ) + (-4)) / 2 = -1 / 2 := by norm_num

-- The joined track's slopes, zero outside 0..10 s; its largest bend, in size, is 7 m/s.
example : ((List.zipWith (fun a b => |b - a|) [0, 2, -3, 4, -2, 3, -4, 2, -4, 3, -1]
    [2, -3, 4, -2, 3, -4, 2, -4, 3, -1, 0] : List ℤ).foldl max 0) = 7 := by decide

#print axioms mollifier_convolution_tendsto_in_Lp
#print axioms mollifier_convolution_tendsto_uniformly
#print axioms mollifier_convolution_smooth_and_no_larger
