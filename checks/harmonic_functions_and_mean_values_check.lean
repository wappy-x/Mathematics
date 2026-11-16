-- Harmonic functions: a function is harmonic exactly when it equals its sphere and ball averages, which makes it infinitely smooth and rules out an inside maximum or minimum unless it is constant.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.MeasureTheory.Constructions.HaarToSphere
import Mathlib.MeasureTheory.Integral.Average
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Analysis.Calculus.LineDeriv.IntegrationByParts
import Mathlib.Analysis.Calculus.BumpFunction.InnerProduct
import Mathlib.Analysis.Calculus.ContDiff.Convolution
import Mathlib.Analysis.Calculus.MeanValue

open MeasureTheory Metric InnerProductSpace
open scoped ContDiff

section Helpers

open Set Filter Topology Laplacian
open scoped RealInnerProductSpace Convolution

set_option linter.unusedSectionVars false

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]
  [MeasurableSpace E] [BorelSpace E] (μ : Measure E) [μ.IsAddHaarMeasure]

/-- Antiderivative profile used for the radial weights. -/
noncomputable def radH (h : ℝ → ℝ) (q : ℝ) : ℝ := -(1/2) * ∫ τ in q..1, h τ

theorem hasDerivAt_radH {h : ℝ → ℝ} (hh : Continuous h) (q : ℝ) :
    HasDerivAt (radH h) (h q / 2) q := by
  have := intervalIntegral.integral_hasDerivAt_left (hh.intervalIntegrable q 1)
    (hh.stronglyMeasurableAtFilter _ _) hh.continuousAt (b := 1)
  have h2 := this.const_mul (-(1/2 : ℝ))
  unfold radH
  convert h2 using 1
  ring

theorem radH_eq_zero {h : ℝ → ℝ} (hsupp : ∀ q, 1 ≤ q → h q = 0) {q : ℝ} (hq : 1 ≤ q) :
    radH h q = 0 := by
  unfold radH
  rw [intervalIntegral.integral_symm, intervalIntegral.integral_congr (g := fun _ => (0:ℝ))]
  · simp
  · intro τ hτ
    rw [uIcc_of_le hq] at hτ
    exact hsupp τ hτ.1


theorem hasFDerivAt_radH_normsq {h : ℝ → ℝ} (hh : Continuous h) (y : E) :
    HasFDerivAt (fun y : E => radH h (‖y‖ ^ 2)) (h (‖y‖ ^ 2) • innerSL ℝ y) y := by
  have := HasDerivAt.comp_hasFDerivAt (f := fun y : E => ‖y‖ ^ 2) y (hasDerivAt_radH hh (‖y‖ ^ 2))
    (hasStrictFDerivAt_norm_sq y).hasFDerivAt
  convert this using 1
  · rfl
  ext w; simp; ring

theorem fderiv_radH_normsq_apply {h : ℝ → ℝ} (hh : Continuous h) (y w : E) :
    fderiv ℝ (fun y : E => radH h (‖y‖ ^ 2)) y w = h (‖y‖ ^ 2) * ⟪y, w⟫ := by
  rw [(hasFDerivAt_radH_normsq hh y).fderiv]; simp

theorem continuous_radH {h : ℝ → ℝ} (hh : Continuous h) : Continuous (radH h) :=
  continuous_iff_continuousAt.2 fun q => (hasDerivAt_radH hh q).continuousAt

theorem weight_eq_zero {g : ℝ → ℝ} (hsupp : ∀ q, 1 ≤ q → g q = 0) {y : E}
    (hy : y ∉ ball (0:E) 1) : g (‖y‖ ^ 2) = 0 := by
  apply hsupp
  simp only [mem_ball, dist_zero_right, not_lt] at hy
  nlinarith

theorem hasCompactSupport_weight {g : ℝ → ℝ} (hsupp : ∀ q, 1 ≤ q → g q = 0) :
    HasCompactSupport (fun y : E => g (‖y‖ ^ 2)) :=
  HasCompactSupport.intro (isCompact_closedBall (0:E) 1) fun _ hy =>
    weight_eq_zero hsupp (fun h => hy (ball_subset_closedBall h))


theorem polar_integral [Nontrivial E] {F : E → ℝ} (hF : Integrable F μ) :
    ∫ y, F y ∂μ = ∫ s in Ioi (0:ℝ), s ^ (Module.finrank ℝ E - 1) *
      ∫ z : sphere (0 : E) 1, F (s • (z : E)) ∂(μ.toSphere) := by
  have hmp := μ.measurePreserving_homeomorphUnitSphereProd
  set ν := Measure.volumeIoiPow (Module.finrank ℝ E - 1)
  set g : sphere (0:E) 1 × Ioi (0:ℝ) → ℝ := fun p => F (p.2.1 • (p.1 : E)) with hg
  have hgc : g ∘ homeomorphUnitSphereProd E = fun x => F x.1 := by
    ext ⟨x, hx⟩
    have : ‖x‖ ≠ 0 := by simpa using hx
    simp [g, smul_smul, this]
  have h1 : ∫ y, F y ∂μ = ∫ x : ({(0:E)}ᶜ : Set E), F x.1 ∂(μ.comap (↑)) := by
    rw [integral_subtype_comap (measurableSet_singleton _).compl, restrict_compl_singleton]
  have h2 : ∫ x : ({(0:E)}ᶜ : Set E), F x.1 ∂(μ.comap (↑)) =
      ∫ p, g p ∂(μ.toSphere.prod ν) := by
    rw [← hmp.integral_comp (Homeomorph.measurableEmbedding _) g, ← hgc]; rfl
  have hgi : Integrable g (μ.toSphere.prod ν) := by
    rw [← hmp.integrable_comp_emb (Homeomorph.measurableEmbedding _), hgc]
    exact (integrableOn_iff_comap_subtypeVal (measurableSet_singleton _).compl).1 hF.integrableOn
  rw [h1, h2, integral_prod_symm g hgi]
  simp only [ν, Measure.volumeIoiPow, g, ENNReal.ofReal]
  rw [integral_withDensity_eq_integral_smul, integral_subtype_comap measurableSet_Ioi
    (fun a => Real.toNNReal (a ^ (Module.finrank ℝ E - 1)) • ∫ z : sphere (0 : E) 1, F (a • (z : E)) ∂(μ.toSphere))]
  · refine setIntegral_congr_fun measurableSet_Ioi fun x hx ↦ ?_
    rw [NNReal.smul_def, Real.coe_toNNReal _ (pow_nonneg hx.out.le _), smul_eq_mul]
  · exact (measurable_subtype_coe.pow_const _).real_toNNReal

theorem hasDerivAt_weighted {v : E → ℝ} (hv : ContDiff ℝ 1 v) {g : ℝ → ℝ} (hg : Continuous g)
    (hsupp : ∀ q, 1 ≤ q → g q = 0) (x : E) (t₀ : ℝ) :
    HasDerivAt (fun t => ∫ y, v (x + t • y) * g (‖y‖ ^ 2) ∂μ)
      (∫ y, fderiv ℝ v (x + t₀ • y) y * g (‖y‖ ^ 2) ∂μ) t₀ := by
  have hΦc : Continuous (fun y : E => g (‖y‖ ^ 2)) := hg.comp (continuous_norm.pow 2)
  have hΦs := hasCompactSupport_weight (E := E) hsupp
  have hv' : Continuous (fderiv ℝ v) := hv.continuous_fderiv one_ne_zero
  have hdiff : Differentiable ℝ v := hv.differentiable one_ne_zero
  obtain ⟨M, hM⟩ : ∃ M, ∀ p ∈ closedBall t₀ 1 ×ˢ closedBall (0:E) 1,
      ‖fderiv ℝ v (x + p.1 • p.2) p.2 * g (‖p.2‖ ^ 2)‖ ≤ M := by
    refine ((isCompact_closedBall _ _).prod (isCompact_closedBall _ _)).exists_bound_of_continuousOn ?_
    apply Continuous.continuousOn
    exact ((hv'.comp (by fun_prop)).clm_apply continuous_snd).mul (hΦc.comp continuous_snd)
  refine (hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := μ) (s := ball t₀ 1)
    (F := fun t y => v (x + t • y) * g (‖y‖ ^ 2))
    (F' := fun t y => fderiv ℝ v (x + t • y) y * g (‖y‖ ^ 2))
    (bound := (closedBall (0:E) 1).indicator (fun _ => M)) (ball_mem_nhds _ one_pos) ?_ ?_ ?_ ?_
    ?_ ?_).2
  · exact Eventually.of_forall fun t =>
      ((hdiff.continuous.comp (by fun_prop)).mul hΦc).aestronglyMeasurable
  · exact ((hdiff.continuous.comp (by fun_prop)).mul hΦc).integrable_of_hasCompactSupport
      hΦs.mul_left
  · exact (((hv'.comp (by fun_prop)).clm_apply continuous_id).mul hΦc).aestronglyMeasurable
  · refine Eventually.of_forall fun y t ht => ?_
    by_cases hy : y ∈ closedBall (0:E) 1
    · rw [indicator_of_mem hy]
      exact hM (t, y) ⟨ball_subset_closedBall ht, hy⟩
    · rw [indicator_of_notMem hy, weight_eq_zero hsupp (fun h => hy (ball_subset_closedBall h))]
      simp
  · exact (integrable_indicator_iff measurableSet_closedBall).2
      (integrableOn_const (measure_closedBall_lt_top).ne)
  · refine Eventually.of_forall fun y t _ => ?_
    have h1 : HasDerivAt (fun t : ℝ => x + t • y) y t := by
      simpa using ((hasDerivAt_id t).smul_const y).const_add x
    exact ((hdiff (x + t • y)).hasFDerivAt.comp_hasDerivAt t h1).mul_const _

theorem ibp_identity {v : E → ℝ} (hv : ContDiff ℝ 2 v) {g : ℝ → ℝ} (hg : Continuous g)
    (hsupp : ∀ q, 1 ≤ q → g q = 0) (x : E) (t : ℝ) :
    ∫ y, fderiv ℝ v (x + t • y) y * g (‖y‖ ^ 2) ∂μ =
      -(t * ∫ y, Δ v (x + t • y) * radH g (‖y‖ ^ 2) ∂μ) := by
  set b := stdOrthonormalBasis ℝ E
  set P : E → ℝ := fun y => radH g (‖y‖ ^ 2) with hPdef
  set G : Fin (Module.finrank ℝ E) → E → ℝ := fun i y => fderiv ℝ v (x + t • y) (b i) with hGdef
  have hPs : HasCompactSupport P := hasCompactSupport_weight (fun q hq => radH_eq_zero hsupp hq)
  have hPc : Continuous P := (continuous_radH hg).comp (continuous_norm.pow 2)
  have hPd : Differentiable ℝ P := fun y => (hasFDerivAt_radH_normsq hg y).differentiableAt
  have hdP : ∀ i, (fun y => fderiv ℝ P y (b i)) = fun y => g (‖y‖ ^ 2) * ⟪y, b i⟫ := fun i =>
    funext fun y => fderiv_radH_normsq_apply hg y (b i)
  have hv1 : ContDiff ℝ 1 (fderiv ℝ v) := hv.fderiv_right (by norm_num)
  have hvc : Continuous (fderiv ℝ v) := hv1.continuous
  have hdd : Differentiable ℝ (fderiv ℝ v) := hv1.differentiable one_ne_zero
  have hddc : Continuous (fderiv ℝ (fderiv ℝ v)) := hv1.continuous_fderiv one_ne_zero
  have haff : ∀ y : E, HasFDerivAt (fun y : E => x + t • y) (t • ContinuousLinearMap.id ℝ E) y :=
    fun y => ((hasFDerivAt_id y).const_smul t).const_add x
  have hG : ∀ i y, HasFDerivAt (G i)
      ((ContinuousLinearMap.apply ℝ ℝ (b i)).comp
        ((fderiv ℝ (fderiv ℝ v) (x + t • y)).comp (t • ContinuousLinearMap.id ℝ E))) y := by
    intro i y
    exact (ContinuousLinearMap.apply ℝ ℝ (b i)).hasFDerivAt.comp y
      ((hdd (x + t • y)).hasFDerivAt.comp y (haff y))
  have hdG : ∀ i, (fun y => fderiv ℝ (G i) y (b i)) =
      fun y => t * fderiv ℝ (fderiv ℝ v) (x + t • y) (b i) (b i) := by
    intro i; funext y
    rw [(hG i y).fderiv]; simp
  have hdP' : ∀ i y, fderiv ℝ P y (b i) = g (‖y‖ ^ 2) * ⟪y, b i⟫ := fun i y =>
    congrFun (hdP i) y
  have hdG' : ∀ i y, fderiv ℝ (G i) y (b i) =
      t * fderiv ℝ (fderiv ℝ v) (x + t • y) (b i) (b i) := fun i y => congrFun (hdG i) y
  have hGc : ∀ i, Continuous (G i) := fun i =>
    (hvc.comp (by fun_prop)).clm_apply continuous_const
  have hdGc : ∀ i, Continuous (fun y => fderiv ℝ (G i) y (b i)) := by
    intro i; rw [hdG i]
    exact continuous_const.mul (((hddc.comp (by fun_prop)).clm_apply continuous_const).clm_apply
      continuous_const)
  have hwc : ∀ i, Continuous (fun y : E => g (‖y‖ ^ 2) * ⟪y, b i⟫) := fun i =>
    (hg.comp (continuous_norm.pow 2)).mul (continuous_id.inner continuous_const)
  have hws : ∀ i, HasCompactSupport (fun y : E => g (‖y‖ ^ 2) * ⟪y, b i⟫) := fun i =>
    (hasCompactSupport_weight hsupp).mul_right
  have hpt : ∀ y, fderiv ℝ v (x + t • y) y * g (‖y‖ ^ 2) =
      ∑ i, G i y * (g (‖y‖ ^ 2) * ⟪y, b i⟫) := by
    intro y
    rw [show fderiv ℝ v (x + t • y) y = fderiv ℝ v (x + t • y) (∑ i, ⟪b i, y⟫ • b i) by
      rw [b.sum_repr' y]]
    rw [map_sum, Finset.sum_mul]
    refine Finset.sum_congr rfl fun i _ => ?_
    simp only [map_smul, smul_eq_mul, G, real_inner_comm (b i) y]
    ring
  have hint1 : ∀ i, Integrable (fun y => G i y * (g (‖y‖ ^ 2) * ⟪y, b i⟫)) μ := fun i =>
    ((hGc i).mul (hwc i)).integrable_of_hasCompactSupport (hws i).mul_left
  have hibp : ∀ i, ∫ y, G i y * (g (‖y‖ ^ 2) * ⟪y, b i⟫) ∂μ =
      -∫ y, t * fderiv ℝ (fderiv ℝ v) (x + t • y) (b i) (b i) * P y ∂μ := by
    intro i
    have := integral_mul_fderiv_eq_neg_fderiv_mul_of_integrable (μ := μ) (f := G i) (g := P)
      (v := b i) ?_ ?_ ?_ (fun y _ => (hG i y).differentiableAt) (fun y _ => hPd y)
    · simp only [hdP' i, hdG' i] at this; exact this
    · exact ((hdGc i).mul hPc).integrable_of_hasCompactSupport hPs.mul_left
    · simp only [hdP' i]; exact hint1 i
    · exact ((hGc i).mul hPc).integrable_of_hasCompactSupport hPs.mul_left
  have hlap : ∀ y, Δ v (x + t • y) * P y =
      ∑ i, fderiv ℝ (fderiv ℝ v) (x + t • y) (b i) (b i) * P y := by
    intro y
    rw [laplacian_eq_iteratedFDeriv_stdOrthonormalBasis, Finset.sum_mul]
    simp [iteratedFDeriv_two_apply, b]
  have hint2 : ∀ i, Integrable
      (fun y => fderiv ℝ (fderiv ℝ v) (x + t • y) (b i) (b i) * P y) μ := fun i =>
    ((((hddc.comp (by fun_prop)).clm_apply continuous_const).clm_apply continuous_const).mul
      hPc).integrable_of_hasCompactSupport hPs.mul_left
  rw [integral_congr_ae (Eventually.of_forall hpt), integral_finsetSum _ fun i _ => hint1 i,
    integral_congr_ae (Eventually.of_forall hlap), integral_finsetSum _ fun i _ => hint2 i,
    Finset.mul_sum, ← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [hibp i, ← integral_const_mul]
  simp only [mul_assoc]

theorem core_hasDerivAt {v : E → ℝ} (hv : ContDiff ℝ 2 v) {g : ℝ → ℝ} (hg : Continuous g)
    (hsupp : ∀ q, 1 ≤ q → g q = 0) (x : E) (t : ℝ) :
    HasDerivAt (fun t => ∫ y, v (x + t • y) * g (‖y‖ ^ 2) ∂μ)
      (-(t * ∫ y, Δ v (x + t • y) * radH g (‖y‖ ^ 2) ∂μ)) t := by
  rw [← ibp_identity μ hv hg hsupp x t]
  exact hasDerivAt_weighted μ (hv.of_le (by norm_num)) hg hsupp x t

theorem polar_eq [Nontrivial E] {F G : E → ℝ} (hF : Integrable F μ) (hG : Integrable G μ) (c : ℝ)
    (h : ∀ s : ℝ, 0 < s → ∫ z : sphere (0:E) 1, F (s • (z:E)) ∂μ.toSphere =
      c * ∫ z : sphere (0:E) 1, G (s • (z:E)) ∂μ.toSphere) :
    ∫ y, F y ∂μ = c * ∫ y, G y ∂μ := by
  rw [polar_integral μ hF, polar_integral μ hG, ← integral_const_mul]
  refine setIntegral_congr_fun measurableSet_Ioi fun s hs => ?_
  rw [h s hs]; ring

theorem norm_smul_sphere {s : ℝ} (hs : 0 ≤ s) (z : sphere (0:E) 1) : ‖s • (z:E)‖ = s := by
  rw [norm_smul, Real.norm_of_nonneg hs, norm_eq_of_mem_sphere z, mul_one]

theorem sphere_integrable {f : sphere (0:E) 1 → ℝ} (hf : Continuous f) :
    Integrable f μ.toSphere :=
  hf.integrable_of_hasCompactSupport (HasCompactSupport.of_compactSpace f)

theorem sphere_integral_weight (f : E → ℝ) (g : ℝ → ℝ) (t : ℝ) {s : ℝ} (hs : 0 < s) :
    ∫ z : sphere (0:E) 1, f (t • (s • (z:E))) * g (‖s • (z:E)‖ ^ 2) ∂μ.toSphere =
      (∫ z : sphere (0:E) 1, f ((t * s) • (z:E)) ∂μ.toSphere) * g (s ^ 2) := by
  simp_rw [norm_smul_sphere hs.le, smul_smul]
  exact integral_mul_const _ _

theorem exists_cutoff {n : ℕ∞} {u : E → ℝ} {U : Set E} (hU : IsOpen U)
    (hu : ContDiffOn ℝ n u U) {x : E} {ρ R : ℝ} (hρ : 0 < ρ) (hρR : ρ < R)
    (hball : ball x R ⊆ U) :
    ∃ v : E → ℝ, ContDiff ℝ n v ∧ HasCompactSupport v ∧ EqOn v u (closedBall x ρ) := by
  let χ : ContDiffBump x := ⟨ρ, (ρ + R) / 2, hρ, by linarith⟩
  refine ⟨fun y => χ y * u y, ?_, χ.hasCompactSupport.mul_right, ?_⟩
  · rw [contDiff_iff_contDiffAt]; intro y
    by_cases hy : y ∈ U
    · exact (χ.contDiff.contDiffAt).mul (hu.contDiffAt (hU.mem_nhds hy))
    · have hy' : y ∉ tsupport χ := by
        rw [χ.tsupport_eq]; intro h
        exact hy (hball (closedBall_subset_ball (by simp [χ]; linarith) h))
      have h0 : (fun y => χ y * u y) =ᶠ[𝓝 y] fun _ => 0 := by
        filter_upwards [notMem_tsupport_iff_eventuallyEq.1 hy'] with z hz
        simp [hz]
      exact contDiffAt_const.congr_of_eventuallyEq h0
  · intro y hy
    simp [χ.one_of_mem_closedBall hy]

theorem continuous_laplacian {v : E → ℝ} (hv : ContDiff ℝ 2 v) : Continuous (Δ v) := by
  rw [laplacian_eq_iteratedFDeriv_stdOrthonormalBasis]
  refine continuous_finsetSum _ fun i _ => ?_
  have := hv.continuous_iteratedFDeriv (m := 2) le_rfl
  fun_prop

theorem continuous_sphere_mean {w : E → ℝ} (hw : Continuous w) (x : E) :
    Continuous (fun τ : ℝ => ∫ z : sphere (0:E) 1, w (x + τ • (z:E)) ∂μ.toSphere) := by
  have := continuous_parametric_integral_of_continuous (μ := μ.toSphere)
    (f := fun (τ : ℝ) (z : sphere (0:E) 1) => w (x + τ • (z:E))) (by fun_prop)
    (isCompact_univ (X := sphere (0:E) 1))
  simpa using this

theorem dubois {f : ℝ → ℝ} (hf : Continuous f) (n : ℕ)
    (h : ∀ g : ℝ → ℝ, Continuous g → (∀ q, 1 ≤ q → g q = 0) →
      ∫ s in Ioi (0:ℝ), s ^ n * (f s * g (s ^ 2)) = 0)
    {s0 : ℝ} (hs0 : 0 < s0) (hs1 : s0 < 1) : f s0 = 0 := by
  by_contra hne
  set c := f s0
  have hF : Continuous (fun s => c * f s) := continuous_const.mul hf
  have hpos : 0 < c * f s0 := mul_self_pos.2 hne
  obtain ⟨η, hη, hηF⟩ : ∃ η > 0, ∀ s, dist s s0 < η → 0 < c * f s :=
    Metric.eventually_nhds_iff.1 (hF.continuousAt.eventually (lt_mem_nhds hpos))
  set η1 := min η (1 - s0) with hη1
  have hη1pos : 0 < η1 := lt_min hη (by linarith)
  have hη1η : η1 ≤ η := min_le_left _ _
  have hη1s : η1 ≤ 1 - s0 := min_le_right _ _
  set ε := s0 * η1 / 2 with hε
  have hεpos : 0 < ε := by positivity
  set g : ℝ → ℝ := fun q => max 0 (ε - |q - s0 ^ 2|) with hgdef
  have hgc : Continuous g := by fun_prop
  have hgs : ∀ q, 1 ≤ q → g q = 0 := by
    intro q hq
    have : ε - |q - s0 ^ 2| ≤ 0 := by
      have h1 : s0 ^ 2 + ε ≤ 1 := by nlinarith
      have h2 : q - s0 ^ 2 ≤ |q - s0 ^ 2| := le_abs_self _
      linarith
    simp [g, this]
  have hint := h g hgc hgs
  set φ : ℝ → ℝ := fun s => c * (s ^ n * (f s * g (s ^ 2))) with hφ
  have hφint : ∫ s in Ioi (0:ℝ), φ s = 0 := by
    simp only [φ]; rw [integral_const_mul, hint, mul_zero]
  have hφc : Continuous φ := by simp only [φ]; fun_prop
  have hφs : HasCompactSupport φ := by
    refine HasCompactSupport.intro (isCompact_closedBall (0:ℝ) 1) fun s hs => ?_
    simp only [mem_closedBall, dist_zero_right, not_le, Real.norm_eq_abs] at hs
    have : 1 ≤ s ^ 2 := by nlinarith [sq_abs s, abs_nonneg s]
    simp [φ, hgs _ this]
  have hφnn : ∀ s, 0 < s → 0 ≤ φ s := by
    intro s hs
    by_cases hg0 : g (s ^ 2) = 0
    · simp [φ, hg0]
    · have hgpos : 0 < ε - |s ^ 2 - s0 ^ 2| := by
        by_contra hcon
        rw [not_lt] at hcon
        exact hg0 (by simp [g, hcon])
      have hclose : dist s s0 < η := by
        rw [Real.dist_eq]
        have h1 : |s ^ 2 - s0 ^ 2| = |s - s0| * (s + s0) := by
          rw [show s ^ 2 - s0 ^ 2 = (s - s0) * (s + s0) by ring, abs_mul,
            abs_of_pos (by linarith : 0 < s + s0)]
        have h2 : |s - s0| * s0 ≤ |s - s0| * (s + s0) :=
          mul_le_mul_of_nonneg_left (by linarith) (abs_nonneg _)
        have h3 : |s - s0| * s0 < s0 * η1 := by nlinarith
        have h4 : |s - s0| < η1 := by
          by_contra h5; rw [not_lt] at h5; nlinarith
        linarith
      have := hηF s hclose
      have hg' : 0 ≤ g (s ^ 2) := le_max_left _ _
      have : φ s = (c * f s) * (s ^ n * g (s ^ 2)) := by simp only [φ]; ring
      rw [this]; positivity
  set δ := min (s0 / 2) (ε / (3 * s0)) with hδ
  have hδpos : 0 < δ := lt_min (by linarith) (by positivity)
  have hδ1 : δ ≤ s0 / 2 := min_le_left _ _
  have hδ2 : δ ≤ ε / (3 * s0) := min_le_right _ _
  have hsupp : Ioo (s0 - δ) (s0 + δ) ⊆ Function.support φ ∩ Ioi 0 := by
    intro s hs
    have hs0' : 0 < s := by linarith [hs.1]
    refine ⟨?_, hs0'⟩
    have habs : |s - s0| < δ := abs_sub_lt_iff.2 ⟨by linarith [hs.2], by linarith [hs.1]⟩
    have hclose2 : |s ^ 2 - s0 ^ 2| < ε := by
      rw [show s ^ 2 - s0 ^ 2 = (s - s0) * (s + s0) by ring, abs_mul,
        abs_of_pos (by linarith : 0 < s + s0)]
      have h1 : s + s0 < 3 * s0 := by linarith [hs.2]
      have h2 : δ * (3 * s0) ≤ ε := by
        have := mul_le_mul_of_nonneg_right hδ2 (by positivity : (0:ℝ) ≤ 3 * s0)
        rwa [div_mul_cancel₀ _ (by positivity)] at this
      calc |s - s0| * (s + s0) ≤ |s - s0| * (3 * s0) :=
            mul_le_mul_of_nonneg_left h1.le (abs_nonneg _)
        _ < δ * (3 * s0) := mul_lt_mul_of_pos_right habs (by positivity)
        _ ≤ ε := h2
    have hgpos : 0 < g (s ^ 2) := by simp only [g]; exact lt_max_of_lt_right (by linarith)
    have hδη : δ < η := by
      have : ε / (3 * s0) = η1 / 6 := by rw [hε]; field_simp; ring
      linarith
    have hcf : 0 < c * f s := hηF s (by rw [Real.dist_eq]; linarith [habs])
    have : φ s = (c * f s) * (s ^ n * g (s ^ 2)) := by simp only [φ]; ring
    rw [Function.mem_support, this]
    exact (mul_pos hcf (mul_pos (pow_pos hs0' n) hgpos)).ne'
  have hpos' : 0 < ∫ s in Ioi (0:ℝ), φ s := by
    rw [setIntegral_pos_iff_support_of_nonneg_ae]
    · refine lt_of_lt_of_le ?_ (measure_mono hsupp)
      rw [Real.volume_Ioo]; simp; linarith
    · exact (ae_restrict_iff' measurableSet_Ioi).2 (Eventually.of_forall fun s hs => hφnn s hs)
    · exact (hφc.integrable_of_hasCompactSupport hφs).integrableOn
  linarith

theorem weighted_const_of_laplacian_zero {v : E → ℝ} (hv : ContDiff ℝ 2 v) {x : E} {ρ : ℝ}
    (hΔ : ∀ y ∈ ball x ρ, Δ v y = 0) {g : ℝ → ℝ} (hg : Continuous g)
    (hgs : ∀ q, 1 ≤ q → g q = 0) {t : ℝ} (ht0 : 0 ≤ t) (htρ : t < ρ) :
    ∫ y, v (x + t • y) * g (‖y‖ ^ 2) ∂μ = v x * ∫ y, g (‖y‖ ^ 2) ∂μ := by
  set I := fun t : ℝ => ∫ y, v (x + t • y) * g (‖y‖ ^ 2) ∂μ with hI
  have hder : ∀ t' : ℝ, |t'| < ρ → HasDerivAt I 0 t' := by
    intro t' ht'
    have h1 := core_hasDerivAt μ hv hg hgs x t'
    have hK : ∫ y, Δ v (x + t' • y) * radH g (‖y‖ ^ 2) ∂μ = 0 := by
      refine integral_eq_zero_of_ae (Eventually.of_forall fun y => ?_)
      by_cases hy : y ∈ ball (0:E) 1
      · have : x + t' • y ∈ ball x ρ := by
          rw [mem_ball, dist_eq_norm, add_sub_cancel_left, norm_smul, Real.norm_eq_abs]
          rw [mem_ball, dist_zero_right] at hy
          calc |t'| * ‖y‖ ≤ |t'| * 1 := mul_le_mul_of_nonneg_left hy.le (abs_nonneg _)
            _ < ρ := by linarith
        simp [hΔ _ this]
      · simp [weight_eq_zero (g := radH g) (fun q hq => radH_eq_zero hgs hq) hy]
    simpa [hK] using h1
  have hc := constant_of_has_deriv_right_zero (f := I) (a := 0) (b := t)
    (fun t' ht' => (hder t' (by rw [abs_of_nonneg ht'.1]; linarith [ht'.2])).continuousAt.continuousWithinAt)
    (fun t' ht' => (hder t' (by rw [abs_of_nonneg ht'.1]; linarith [ht'.2])).hasDerivWithinAt)
    t ⟨ht0, le_rfl⟩
  simp only [hI] at hc
  rw [hc]
  simp only [zero_smul, add_zero]
  exact integral_const_mul _ _

theorem sphere_mean_of_laplacian_zero [Nontrivial E] {v : E → ℝ} (hv : ContDiff ℝ 2 v) {x : E}
    {ρ : ℝ} (hΔ : ∀ y ∈ ball x ρ, Δ v y = 0) {τ : ℝ} (hτ0 : 0 < τ) (hτ : τ < ρ) :
    ∫ z : sphere (0:E) 1, v (x + τ • (z:E)) ∂μ.toSphere = μ.toSphere.real univ * v x := by
  set m := fun τ : ℝ => ∫ z : sphere (0:E) 1, v (x + τ • (z:E)) ∂μ.toSphere with hm
  have hzero : ∀ t, 0 ≤ t → t < ρ → ∀ g : ℝ → ℝ, Continuous g → (∀ q, 1 ≤ q → g q = 0) →
      ∫ s in Ioi (0:ℝ), s ^ (Module.finrank ℝ E - 1) *
        ((m (t * s) - μ.toSphere.real univ * v x) * g (s ^ 2)) = 0 := by
    intro t ht0 htρ g hg hgs
    have hwc : Continuous (fun y : E => g (‖y‖ ^ 2)) := hg.comp (continuous_norm.pow 2)
    have hint1 : Integrable (fun y : E => v (x + t • y) * g (‖y‖ ^ 2)) μ :=
      ((hv.continuous.comp (by fun_prop)).mul hwc).integrable_of_hasCompactSupport
        (hasCompactSupport_weight hgs).mul_left
    have hint2 : Integrable (fun y : E => v x * g (‖y‖ ^ 2)) μ :=
      (continuous_const.mul hwc).integrable_of_hasCompactSupport
        (hasCompactSupport_weight hgs).mul_left
    have hF : ∫ y, (v (x + t • y) - v x) * g (‖y‖ ^ 2) ∂μ = 0 := by
      simp_rw [sub_mul]
      rw [integral_sub hint1 hint2, weighted_const_of_laplacian_zero μ hv hΔ hg hgs ht0 htρ,
        integral_const_mul, sub_self]
    rw [polar_integral μ (hint1.sub hint2 |>.congr (Eventually.of_forall fun y => by
      simp only [Pi.sub_apply]; ring))] at hF
    refine Eq.trans ?_ hF
    refine setIntegral_congr_fun measurableSet_Ioi fun s hs => ?_
    have := sphere_integral_weight μ (fun y => v (x + y) - v x) g t hs
    simp only [this]
    congr 2
    rw [integral_sub (sphere_integrable μ (by fun_prop)) (integrable_const _), integral_const,
      smul_eq_mul]
  set t := (τ + ρ) / 2 with ht
  have htpos : 0 < t := by linarith
  have hd := dubois (f := fun s => m (t * s) - μ.toSphere.real univ * v x)
    (((continuous_sphere_mean μ hv.continuous x).comp (continuous_const.mul continuous_id)).sub
      continuous_const) (Module.finrank ℝ E - 1)
    (fun g hg hgs => hzero t htpos.le (by linarith) g hg hgs)
    (s0 := τ / t) (div_pos hτ0 htpos) ((div_lt_one htpos).2 (by linarith))
  simp only [mul_div_cancel₀ _ htpos.ne'] at hd
  simp only [hm] at hd
  linarith

theorem weighted_mean_of_sphere_mean [Nontrivial E] {Ω : Set E} {u : E → ℝ}
    (hcont : ContinuousOn u Ω)
    (hmean : ∀ x ∈ Ω, ∀ r : ℝ, 0 < r → closedBall x r ⊆ Ω →
      u x = ⨍ z : sphere (0 : E) 1, u (x + r • (z : E)) ∂(μ.toSphere))
    {x : E} (hx : x ∈ Ω) {t : ℝ} (ht : 0 < t) (hball : closedBall x t ⊆ Ω) {g : ℝ → ℝ}
    (hg : Continuous g) (hgs : ∀ q, 1 ≤ q → g q = 0) :
    ∫ y, u (x + t • y) * g (‖y‖ ^ 2) ∂μ = u x * ∫ y, g (‖y‖ ^ 2) ∂μ := by
  have hwc : Continuous (fun y : E => g (‖y‖ ^ 2)) := hg.comp (continuous_norm.pow 2)
  have hmaps : MapsTo (fun y : E => x + t • y) (closedBall 0 1) Ω := by
    intro y hy
    apply hball
    rw [mem_closedBall, dist_eq_norm, add_sub_cancel_left, norm_smul, Real.norm_of_nonneg ht.le]
    rw [mem_closedBall, dist_zero_right] at hy
    nlinarith
  have hF : Integrable (fun y : E => u (x + t • y) * g (‖y‖ ^ 2)) μ := by
    refine IntegrableOn.integrable_of_forall_notMem_eq_zero (s := closedBall 0 1) ?_ ?_
    · exact ((hcont.comp (by fun_prop) hmaps).mul hwc.continuousOn).integrableOn_compact
        (isCompact_closedBall _ _)
    · intro y hy
      rw [weight_eq_zero hgs (fun h => hy (ball_subset_closedBall h)), mul_zero]
  have hG : Integrable (fun y : E => g (‖y‖ ^ 2)) μ :=
    hwc.integrable_of_hasCompactSupport (hasCompactSupport_weight hgs)
  refine polar_eq μ hF hG (u x) fun s hs => ?_
  have h1 := sphere_integral_weight μ (fun y => u (x + y)) g t hs
  rw [h1]
  simp_rw [norm_smul_sphere hs.le]
  rw [integral_const, smul_eq_mul]
  by_cases hgz : g (s ^ 2) = 0
  · simp [hgz]
  have hs1 : s < 1 := by
    by_contra h; rw [not_lt] at h
    exact hgz (hgs _ (by nlinarith))
  have hts : 0 < t * s := mul_pos ht hs
  have hsub : closedBall x (t * s) ⊆ Ω :=
    (closedBall_subset_closedBall (by nlinarith)).trans hball
  have hm := hmean x hx (t * s) hts hsub
  have : NeZero μ.toSphere := ⟨Measure.toSphere_ne_zero _⟩
  rw [average_eq, smul_eq_mul] at hm
  have hσ : μ.toSphere.real univ ≠ 0 := measureReal_univ_ne_zero
  have : ∫ z : sphere (0:E) 1, u (x + (t * s) • (z:E)) ∂μ.toSphere = μ.toSphere.real univ * u x := by
    rw [hm, ← mul_assoc, mul_inv_cancel₀ hσ, one_mul]
  rw [this]; ring

theorem contDiff_weighted_shift {w : E → ℝ} (hw : Continuous w) {Φ : E → ℝ}
    (hΦ : ContDiff ℝ (⊤ : ℕ∞) Φ) (hΦs : HasCompactSupport Φ) (hΦeven : ∀ y, Φ (-y) = Φ y)
    {ε : ℝ} (hε : 0 < ε) :
    ContDiff ℝ (⊤ : ℕ∞) (fun x' => ∫ y, w (x' + ε • y) * Φ y ∂μ) := by
  set Ψ : E → ℝ := fun y => Φ (ε⁻¹ • y) with hΨ
  have hΨc : ContDiff ℝ (⊤ : ℕ∞) Ψ := hΦ.comp (contDiff_const_smul _)
  have hΨs : HasCompactSupport Ψ := hΦs.comp_smul (inv_ne_zero hε.ne')
  have heq : (fun x' => ∫ y, w (x' + ε • y) * Φ y ∂μ) =
      fun x' => |(ε ^ Module.finrank ℝ E)⁻¹| • (Ψ ⋆[ContinuousLinearMap.lsmul ℝ ℝ, μ] w) x' := by
    funext x'
    have h1 := Measure.integral_comp_smul μ (fun y => w (x' + y) * Φ (ε⁻¹ • y)) ε
    simp only [smul_smul, inv_mul_cancel₀ hε.ne', one_smul] at h1
    rw [h1, convolution_def]
    congr 1
    rw [← integral_neg_eq_self]
    refine integral_congr_ae (Eventually.of_forall fun y => ?_)
    simp only [Ψ, ContinuousLinearMap.lsmul_apply, smul_eq_mul, smul_neg, hΦeven, sub_eq_add_neg]
    ring
  rw [heq]
  exact (hΨs.contDiff_convolution_left _ hΨc hw.locallyIntegrable).const_smul _

theorem integral_radH_neg :
    ∫ y, radH (fun q => max 0 (1 - q)) (‖y‖ ^ 2) ∂μ < 0 := by
  set g1 : ℝ → ℝ := fun q => max 0 (1 - q) with hg1
  have hg1c : Continuous g1 := by fun_prop
  have hg1s : ∀ q, 1 ≤ q → g1 q = 0 := fun q hq => by simp [g1]; linarith
  have hle : ∀ q, radH g1 q ≤ 0 := by
    intro q
    by_cases hq : q ≤ 1
    · unfold radH
      have : 0 ≤ ∫ τ in q..1, g1 τ :=
        intervalIntegral.integral_nonneg hq (fun τ _ => le_max_left _ _)
      linarith
    · exact (radH_eq_zero hg1s (le_of_lt (not_le.1 hq))).le
  have h0 : radH g1 0 < 0 := by
    unfold radH
    have : 0 < ∫ τ in (0:ℝ)..1, g1 τ :=
      intervalIntegral.intervalIntegral_pos_of_pos_on (hg1c.intervalIntegrable _ _)
        (fun τ hτ => by simp only [g1]; exact lt_max_of_lt_right (by linarith [hτ.2])) zero_lt_one
    linarith
  have hc : Continuous (fun y : E => -radH g1 (‖y‖ ^ 2)) :=
    ((continuous_radH hg1c).comp (continuous_norm.pow 2)).neg
  have hs : HasCompactSupport (fun y : E => -radH g1 (‖y‖ ^ 2)) :=
    (hasCompactSupport_weight (fun q hq => radH_eq_zero hg1s hq)).neg
  have hpos : 0 < ∫ y, -radH g1 (‖y‖ ^ 2) ∂μ :=
    hc.integral_pos_of_hasCompactSupport_nonneg_ne_zero hs (fun y => neg_nonneg.2 (hle _))
      (x := 0) (by simp only [norm_zero]; norm_num; exact h0.ne)
  rw [integral_neg] at hpos
  linarith

theorem euclidean_nontrivial {d : ℕ} (hd : 0 < d) : Nontrivial (EuclideanSpace ℝ (Fin d)) :=
  Module.nontrivial_of_finrank_pos (by rw [finrank_euclideanSpace_fin]; exact hd)


#print axioms hasDerivAt_radH
#print axioms radH_eq_zero
#print axioms hasFDerivAt_radH_normsq
#print axioms fderiv_radH_normsq_apply
#print axioms continuous_radH
#print axioms weight_eq_zero
#print axioms hasCompactSupport_weight
#print axioms polar_integral
#print axioms hasDerivAt_weighted
#print axioms ibp_identity
#print axioms core_hasDerivAt
#print axioms polar_eq
#print axioms norm_smul_sphere
#print axioms sphere_integrable
#print axioms sphere_integral_weight
#print axioms exists_cutoff
#print axioms continuous_laplacian
#print axioms continuous_sphere_mean
#print axioms dubois
#print axioms weighted_const_of_laplacian_zero
#print axioms sphere_mean_of_laplacian_zero
#print axioms weighted_mean_of_sphere_mean
#print axioms contDiff_weighted_shift
#print axioms integral_radH_neg
#print axioms euclidean_nontrivial

end Helpers

/-- The mean value property. Let `u` be harmonic in the region `Ω` of `d`-dimensional space
(`d ≥ 1`), and let the closed ball of radius `r` round `x` lie inside `Ω`. Then the value
`u x` equals the average of `u` over the sphere `∂B(x, r)` (written with the unit sphere's
surface measure, `z ↦ x + r z`) and also equals the average of `u` over the ball `B(x, r)`. -/
theorem harmonic_eq_sphere_average_and_ball_average {d : ℕ} (hd : 0 < d)
    {Ω : Set (EuclideanSpace ℝ (Fin d))} {u : EuclideanSpace ℝ (Fin d) → ℝ}
    (hu : HarmonicOnNhd u Ω) {x : EuclideanSpace ℝ (Fin d)} {r : ℝ} (hr : 0 < r)
    (hball : closedBall x r ⊆ Ω) :
    (u x = ⨍ z : sphere (0 : EuclideanSpace ℝ (Fin d)) 1,
        u (x + r • (z : EuclideanSpace ℝ (Fin d))) ∂(volume.toSphere)) ∧
      (u x = ⨍ y in ball x r, u y) := by
  classical
  have := euclidean_nontrivial hd
  obtain ⟨δ, hδ, hthick⟩ := (isCompact_closedBall x r).exists_thickening_subset_open
    (isOpen_setOfPred_harmonicAt u) (fun y hy => hu y (hball hy))
  rw [thickening_closedBall hδ hr.le] at hthick
  have hU2 : ContDiffOn ℝ 2 u {y | HarmonicAt u y} := fun y hy => hy.1.contDiffWithinAt
  obtain ⟨v, hv, -, hvu⟩ := exists_cutoff (n := 2) (isOpen_setOfPred_harmonicAt u) hU2 (x := x)
    (ρ := r + δ / 2) (R := δ + r) (by positivity) (by linarith) hthick
  have hΔ : ∀ y ∈ ball x (r + δ / 2), Laplacian.laplacian v y = 0 := by
    intro y hy
    have hev : v =ᶠ[nhds y] u := Filter.eventuallyEq_of_mem (isOpen_ball.mem_nhds hy)
      (fun z hz => hvu (ball_subset_closedBall hz))
    rw [(laplacian_congr_nhds hev).self_of_nhds]
    have hH : HarmonicAt u y := hthick (ball_subset_ball (by linarith) hy)
    exact hH.2.self_of_nhds
  have : NeZero (volume : Measure (EuclideanSpace ℝ (Fin d))).toSphere :=
    ⟨Measure.toSphere_ne_zero _⟩
  have hσpos : (volume : Measure (EuclideanSpace ℝ (Fin d))).toSphere.real Set.univ ≠ 0 :=
    measureReal_univ_ne_zero
  have hm : ∀ τ, 0 < τ → τ ≤ r →
      ∫ z : sphere (0 : EuclideanSpace ℝ (Fin d)) 1, u (x + τ • (z : EuclideanSpace ℝ (Fin d)))
        ∂(volume.toSphere) =
        (volume : Measure (EuclideanSpace ℝ (Fin d))).toSphere.real Set.univ * u x := by
    intro τ hτ0 hτr
    have h1 := sphere_mean_of_laplacian_zero volume hv hΔ hτ0 (by linarith)
    rw [hvu (mem_closedBall_self (by positivity))] at h1
    rw [← h1]
    refine integral_congr_ae (Filter.Eventually.of_forall fun z => ?_)
    refine (hvu ?_).symm
    rw [mem_closedBall, dist_eq_norm, add_sub_cancel_left, norm_smul_sphere hτ0.le]
    linarith
  constructor
  · rw [average_eq, hm r hr le_rfl, smul_eq_mul, ← mul_assoc, inv_mul_cancel₀ hσpos, one_mul]
  · rw [setAverage_eq]
    have hint_u : IntegrableOn u (closedBall x r) :=
      (hu.continuousOn.mono hball).integrableOn_compact (isCompact_closedBall x r)
    set F : EuclideanSpace ℝ (Fin d) → ℝ := fun y => (ball x r).indicator u (x + y) with hFdef
    set G : EuclideanSpace ℝ (Fin d) → ℝ := (ball (0 : EuclideanSpace ℝ (Fin d)) r).indicator
      (fun _ => (1:ℝ)) with hGdef
    have hFint : Integrable F :=
      ((integrable_indicator_iff measurableSet_ball).2
        (hint_u.mono_set ball_subset_closedBall)).comp_add_left x
    have hGint : Integrable G :=
      (integrable_indicator_iff measurableSet_ball).2 (integrableOn_const measure_ball_lt_top.ne)
    have hmem : ∀ s : ℝ, 0 < s → ∀ z : sphere (0 : EuclideanSpace ℝ (Fin d)) 1,
        (x + s • (z : EuclideanSpace ℝ (Fin d)) ∈ ball x r ↔ s < r) ∧
        (s • (z : EuclideanSpace ℝ (Fin d)) ∈ ball (0 : EuclideanSpace ℝ (Fin d)) r ↔ s < r) := by
      intro s hs z
      rw [mem_ball, dist_eq_norm, add_sub_cancel_left, norm_smul_sphere hs.le, mem_ball,
        dist_zero_right, norm_smul_sphere hs.le]
      exact ⟨Iff.rfl, Iff.rfl⟩
    have key := polar_eq volume hFint hGint (u x) (fun s hs => by
      by_cases hsr : s < r
      · have hF' : ∀ z : sphere (0 : EuclideanSpace ℝ (Fin d)) 1,
            F (s • (z : EuclideanSpace ℝ (Fin d))) = u (x + s • (z : EuclideanSpace ℝ (Fin d))) :=
          fun z => by simp only [F]; rw [Set.indicator_of_mem ((hmem s hs z).1.2 hsr)]
        have hG' : ∀ z : sphere (0 : EuclideanSpace ℝ (Fin d)) 1,
            G (s • (z : EuclideanSpace ℝ (Fin d))) = 1 :=
          fun z => by simp only [G]; rw [Set.indicator_of_mem ((hmem s hs z).2.2 hsr)]
        simp_rw [hF', hG']
        rw [hm s hs hsr.le, integral_const, smul_eq_mul, mul_one, mul_comm]
      · have hF' : ∀ z : sphere (0 : EuclideanSpace ℝ (Fin d)) 1,
            F (s • (z : EuclideanSpace ℝ (Fin d))) = 0 :=
          fun z => by
            simp only [F]; rw [Set.indicator_of_notMem (fun h => hsr ((hmem s hs z).1.1 h))]
        have hG' : ∀ z : sphere (0 : EuclideanSpace ℝ (Fin d)) 1,
            G (s • (z : EuclideanSpace ℝ (Fin d))) = 0 :=
          fun z => by
            simp only [G]; rw [Set.indicator_of_notMem (fun h => hsr ((hmem s hs z).2.1 h))]
        simp_rw [hF', hG']
        simp)
    have h1 : ∫ y in ball x r, u y = ∫ y, F y := by
      rw [← integral_indicator measurableSet_ball]
      exact (integral_add_left_eq_self _ x).symm
    have h2 : ∫ y, G y = volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) r) := by
      rw [hGdef, integral_indicator measurableSet_ball]; simp
    have h3 : volume.real (ball x r) = volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) r) :=
      Measure.addHaar_real_ball_center _ _ _
    have h4 : volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) r) ≠ 0 :=
      by
        rw [measureReal_def]
        exact ENNReal.toReal_ne_zero.2 ⟨(measure_ball_pos _ _ hr).ne', measure_ball_lt_top.ne⟩
    rw [h1, key, h2, h3, smul_eq_mul, mul_comm (u x), ← mul_assoc, inv_mul_cancel₀ h4, one_mul]

/-- The converse, with smoothness. Let `Ω` be an open region of `d`-dimensional space and let
`u` be continuous on `Ω`. If `u x` equals the average of `u` over the sphere `∂B(x, r)` for every
ball whose closure lies in `Ω`, then `u` has derivatives of every order on `Ω` and is harmonic
there. -/
theorem sphere_mean_value_property_implies_smooth_and_harmonic {d : ℕ} (hd : 0 < d)
    {Ω : Set (EuclideanSpace ℝ (Fin d))} (hΩ : IsOpen Ω) {u : EuclideanSpace ℝ (Fin d) → ℝ}
    (hcont : ContinuousOn u Ω)
    (hmean : ∀ x ∈ Ω, ∀ r : ℝ, 0 < r → closedBall x r ⊆ Ω →
      u x = ⨍ z : sphere (0 : EuclideanSpace ℝ (Fin d)) 1,
        u (x + r • (z : EuclideanSpace ℝ (Fin d))) ∂(volume.toSphere)) :
    ContDiffOn ℝ ∞ u Ω ∧ HarmonicOnNhd u Ω := by
  have := euclidean_nontrivial hd
  have hsmooth : ∀ x0 ∈ Ω, ContDiffAt ℝ (⊤ : ℕ∞) u x0 := by
    intro x0 hx0
    obtain ⟨R, hR, hRsub⟩ := Metric.isOpen_iff.1 hΩ x0 hx0
    obtain ⟨w, hw, -, hwu⟩ := exists_cutoff (n := 0) hΩ (contDiffOn_zero.2 hcont) (x := x0)
      (ρ := R / 2) (R := R) (by positivity) (by linarith) hRsub
    have hε : 0 < R / 4 := by positivity
    set g0 : ℝ → ℝ := fun q => Real.smoothTransition (1 - q) with hg0
    have hg0c : ContDiff ℝ (⊤ : ℕ∞) g0 :=
      Real.smoothTransition.contDiff.comp (contDiff_const.sub contDiff_id)
    have hg0s : ∀ q, 1 ≤ q → g0 q = 0 := fun q hq =>
      Real.smoothTransition.zero_of_nonpos (by linarith)
    set Φ : EuclideanSpace ℝ (Fin d) → ℝ := fun y => g0 (‖y‖ ^ 2) with hΦ
    have hΦc : ContDiff ℝ (⊤ : ℕ∞) Φ := hg0c.comp (contDiff_norm_sq ℝ)
    have hΦs : HasCompactSupport Φ := hasCompactSupport_weight hg0s
    have hΦeven : ∀ y, Φ (-y) = Φ y := by simp [Φ]
    have hcΦ : 0 < ∫ y, Φ y :=
      hΦc.continuous.integral_pos_of_hasCompactSupport_nonneg_ne_zero hΦs
        (fun y => Real.smoothTransition.nonneg _) (x := 0) (by simp [Φ, g0])
    have hW := contDiff_weighted_shift volume hw.continuous hΦc hΦs hΦeven hε
    have hev : u =ᶠ[nhds x0] fun x' => (∫ y, Φ y)⁻¹ * ∫ y, w (x' + (R / 4) • y) * Φ y := by
      filter_upwards [ball_mem_nhds x0 hε] with x' hx'
      have hcb : closedBall x' (R / 4) ⊆ closedBall x0 (R / 2) := by
        apply closedBall_subset_closedBall'
        rw [mem_ball] at hx'
        linarith
      have hx'Ω : x' ∈ Ω := hRsub (ball_subset_ball (by linarith) hx')
      have hA := weighted_mean_of_sphere_mean volume hcont hmean hx'Ω hε
        ((hcb.trans (closedBall_subset_ball (by linarith))).trans hRsub) hg0c.continuous hg0s
      have hB : ∫ y, w (x' + (R / 4) • y) * Φ y = ∫ y, u (x' + (R / 4) • y) * Φ y := by
        refine integral_congr_ae (Filter.Eventually.of_forall fun y => ?_)
        by_cases hy : y ∈ ball (0 : EuclideanSpace ℝ (Fin d)) 1
        · have : x' + (R / 4) • y ∈ closedBall x' (R / 4) := by
            rw [mem_closedBall, dist_eq_norm, add_sub_cancel_left, norm_smul,
              Real.norm_of_nonneg hε.le]
            rw [mem_ball, dist_zero_right] at hy
            nlinarith
          simp only
          rw [hwu (hcb this)]
        · simp [Φ, weight_eq_zero hg0s hy]
      rw [hB, hA]
      field_simp
      rfl
    exact (contDiffAt_const.mul hW.contDiffAt).congr_of_eventuallyEq hev
  have hsmoothOn : ContDiffOn ℝ ∞ u Ω := fun x hx => (hsmooth x hx).contDiffWithinAt
  have hΔ : ∀ x ∈ Ω, Laplacian.laplacian u x = 0 := by
    intro x hx
    obtain ⟨R, hR, hRsub⟩ := Metric.isOpen_iff.1 hΩ x hx
    obtain ⟨v, hv, -, hvu⟩ := exists_cutoff (n := 2) hΩ (hsmoothOn.of_le (by exact_mod_cast le_top))
      (x := x) (ρ := R / 2) (R := R) (by positivity) (by linarith) hRsub
    set g1 : ℝ → ℝ := fun q => max 0 (1 - q) with hg1
    have hg1c : Continuous g1 := by fun_prop
    have hg1s : ∀ q, 1 ≤ q → g1 q = 0 := fun q hq => by simp [g1]; linarith
    set I : ℝ → ℝ := fun t => ∫ y, v (x + t • y) * g1 (‖y‖ ^ 2) with hI
    set K : ℝ → ℝ := fun t => ∫ y, Laplacian.laplacian v (x + t • y) * radH g1 (‖y‖ ^ 2)
      with hK
    have hIconst : ∀ t ∈ Set.Ioo 0 (R / 2),
        I t = u x * ∫ y : EuclideanSpace ℝ (Fin d), g1 (‖y‖ ^ 2) := by
      intro t ht
      rw [← weighted_mean_of_sphere_mean volume hcont hmean hx ht.1
        ((closedBall_subset_ball (by linarith [ht.2])).trans hRsub) hg1c hg1s]
      refine integral_congr_ae (Filter.Eventually.of_forall fun y => ?_)
      by_cases hy : y ∈ ball (0 : EuclideanSpace ℝ (Fin d)) 1
      · have : x + t • y ∈ closedBall x (R / 2) := by
          rw [mem_closedBall, dist_eq_norm, add_sub_cancel_left, norm_smul,
            Real.norm_of_nonneg ht.1.le]
          rw [mem_ball, dist_zero_right] at hy
          have := mul_le_mul_of_nonneg_left hy.le ht.1.le
          linarith [ht.2]
        simp only
        rw [hvu this]
      · simp [weight_eq_zero hg1s hy]
    have hK0 : ∀ t ∈ Set.Ioo 0 (R / 2), K t = 0 := by
      intro t ht
      have h1 := core_hasDerivAt volume hv hg1c hg1s x t
      have h2 : HasDerivAt I 0 t :=
        (hasDerivAt_const t (u x * ∫ y : EuclideanSpace ℝ (Fin d), g1 (‖y‖ ^ 2))).congr_of_eventuallyEq
          (by filter_upwards [Ioo_mem_nhds ht.1 ht.2] with t' ht' using hIconst t' ht')
      have h3 := h1.unique h2
      have h4 : t * K t = 0 := by simpa [K] using h3
      exact (mul_eq_zero.1 h4).resolve_left ht.1.ne'
    have hKc : Continuous K := by
      have hc' := continuous_parametric_integral_of_continuous (μ := volume)
        (f := fun (t : ℝ) (y : EuclideanSpace ℝ (Fin d)) =>
          Laplacian.laplacian v (x + t • y) * radH g1 (‖y‖ ^ 2))
        (((continuous_laplacian hv).comp (by fun_prop)).mul
          ((continuous_radH hg1c).comp (by fun_prop)))
        (isCompact_closedBall (0 : EuclideanSpace ℝ (Fin d)) 1)
      convert hc' using 1
      funext t
      refine (setIntegral_eq_integral_of_forall_compl_eq_zero fun y hy => ?_).symm
      rw [weight_eq_zero (g := radH g1) (fun q hq => radH_eq_zero hg1s hq)
        (fun h => hy (ball_subset_closedBall h)), mul_zero]
    have hK00 : K 0 = 0 := by
      by_contra hne
      obtain ⟨δ, hδ, hδK⟩ := Metric.eventually_nhds_iff.1 (hKc.continuousAt.eventually_ne hne)
      have hmin : 0 < min δ (R / 2) := lt_min hδ (by positivity)
      have ht : min δ (R / 2) / 2 ∈ Set.Ioo 0 (R / 2) :=
        ⟨by positivity, by linarith [min_le_right δ (R / 2)]⟩
      have hdist : dist (min δ (R / 2) / 2) 0 < δ := by
        rw [Real.dist_eq, sub_zero, abs_of_pos (by positivity)]
        linarith [min_le_left δ (R / 2)]
      exact hδK hdist (hK0 _ ht)
    have hK0eq : K 0 = Laplacian.laplacian v x *
        ∫ y : EuclideanSpace ℝ (Fin d), radH g1 (‖y‖ ^ 2) := by
      simp only [K, zero_smul, add_zero]
      exact integral_const_mul _ _
    have hPne := (integral_radH_neg (volume : Measure (EuclideanSpace ℝ (Fin d)))).ne
    have hΔv : Laplacian.laplacian v x = 0 := by
      rw [hK00] at hK0eq
      exact (mul_eq_zero.1 hK0eq.symm).resolve_right hPne
    have hev : v =ᶠ[nhds x] u := Filter.eventuallyEq_of_mem (ball_mem_nhds x (by positivity))
      (fun z hz => hvu (ball_subset_closedBall hz))
    rw [← (laplacian_congr_nhds hev).self_of_nhds]
    exact hΔv
  refine ⟨hsmoothOn, fun x hx => ⟨?_, ?_⟩⟩
  · exact (hsmooth x hx).of_le (by simp)
  · filter_upwards [hΩ.mem_nhds hx] with y hy using hΔ y hy

/-- The strong maximum principle. If `u` is harmonic in an open connected region `Ω` and reaches
its largest value, or its smallest value, over `Ω` at an inside point `x₀`, then `u` is constant
on `Ω`. -/
theorem harmonic_inside_max_or_min_implies_constant {d : ℕ}
    {Ω : Set (EuclideanSpace ℝ (Fin d))} (hΩ : IsOpen Ω) (hconn : IsConnected Ω)
    {u : EuclideanSpace ℝ (Fin d) → ℝ} (hu : HarmonicOnNhd u Ω)
    {x₀ : EuclideanSpace ℝ (Fin d)} (hx₀ : x₀ ∈ Ω)
    (hext : IsMaxOn u Ω x₀ ∨ IsMinOn u Ω x₀) :
    ∀ y ∈ Ω, u y = u x₀ := by
  have key : ∀ w : EuclideanSpace ℝ (Fin d) → ℝ, HarmonicOnNhd w Ω → IsMaxOn w Ω x₀ →
      ∀ y ∈ Ω, w y = w x₀ := by
    intro w hw hmax
    rcases Nat.eq_zero_or_pos d with hd0 | hd
    · subst hd0
      intro y _
      rw [Subsingleton.elim y x₀]
    have hAopen : IsOpen {y | y ∈ Ω ∧ w y = w x₀} := by
      rw [isOpen_iff_mem_nhds]
      rintro y ⟨hyΩ, hy⟩
      obtain ⟨R, hR, hRsub⟩ := Metric.isOpen_iff.1 hΩ y hyΩ
      have hr : 0 < R / 2 := by positivity
      have hcb : closedBall y (R / 2) ⊆ Ω :=
        (closedBall_subset_ball (by linarith)).trans hRsub
      have hmv := (harmonic_eq_sphere_average_and_ball_average hd hw hr hcb).2
      have hcont : ContinuousOn w (closedBall y (R / 2)) := hw.continuousOn.mono hcb
      have hint : MeasureTheory.IntegrableOn w (ball y (R / 2)) :=
        (hcont.integrableOn_compact (isCompact_closedBall _ _)).mono_set ball_subset_closedBall
      have hvol : volume.real (ball y (R / 2)) ≠ 0 := by
        rw [measureReal_def]
        exact ENNReal.toReal_ne_zero.2 ⟨(measure_ball_pos _ _ hr).ne', measure_ball_lt_top.ne⟩
      have hI : ∫ z in ball y (R / 2), (w x₀ - w z) = 0 := by
        rw [integral_sub (integrableOn_const measure_ball_lt_top.ne) hint, setIntegral_const,
          smul_eq_mul]
        rw [setAverage_eq, smul_eq_mul, hy] at hmv
        field_simp at hmv
        linarith
      have hae := (setIntegral_eq_zero_iff_of_nonneg_ae
        ((ae_restrict_iff' measurableSet_ball).2 (Filter.Eventually.of_forall fun z hz =>
          sub_nonneg.2 (hmax (hcb (ball_subset_closedBall hz)))))
        ((integrableOn_const measure_ball_lt_top.ne).sub hint)).1 hI
      have heq := Measure.eqOn_open_of_ae_eq hae isOpen_ball
        (continuousOn_const.sub (hcont.mono ball_subset_closedBall)) continuousOn_const
      filter_upwards [ball_mem_nhds y hr] with z hz
      refine ⟨hcb (ball_subset_closedBall hz), ?_⟩
      have := heq hz
      simp only [Pi.zero_apply] at this
      linarith
    have hBopen : IsOpen (Ω ∩ w ⁻¹' {w x₀}ᶜ) :=
      hw.continuousOn.isOpen_inter_preimage hΩ isOpen_compl_singleton
    by_contra hcon
    push Not at hcon
    obtain ⟨y, hy, hne⟩ := hcon
    obtain ⟨z, _, ⟨_, h1⟩, ⟨_, h2⟩⟩ := hconn.isPreconnected _ _ hAopen hBopen
      (fun z hz => by
        by_cases h : w z = w x₀
        · exact Or.inl ⟨hz, h⟩
        · exact Or.inr ⟨hz, h⟩)
      ⟨x₀, hx₀, hx₀, rfl⟩ ⟨y, hy, hy, hne⟩
    exact h2 h1
  rcases hext with hmax | hmin
  · exact key u hu hmax
  · intro y hy
    have := key (-u) hu.neg hmin.neg y hy
    simpa using this

-- The card's worked numbers, in exact rationals.
-- Each of the six faces of a cube (d = 3) gets a share 1 / (2 d) = 1/6 of the centre.
example : (1 : ℚ) / (2 * 3) = 1 / 6 := by norm_num
-- Centre of the room: cold walls 18 °C plus one sixth of the sunny wall's 12 K lead.
example : (18 : ℚ) + 12 / 6 = 20 := by norm_num
-- The plane's quarter rule used wrongly in three dimensions gives 21 °C, not 20 °C.
example : (18 : ℚ) + 12 / 4 = 21 := by norm_num
-- Slope cap at the centre: (d / r) * max |u - 24| with d = 3, r = 3/2 m, max |u - 24| = 30 - 24.
example : (3 : ℚ) / (3 / 2) * (30 - 24) = 12 := by norm_num
-- Heater shortfall f r^2 / (2 d) with f = 3 K per m^2, r = 1 m, d = 3: half a kelvin.
example : (3 : ℚ) * 1 ^ 2 / (2 * 3) = 1 / 2 := by norm_num

#print axioms harmonic_eq_sphere_average_and_ball_average
#print axioms sphere_mean_value_property_implies_smooth_and_harmonic
#print axioms harmonic_inside_max_or_min_implies_constant
