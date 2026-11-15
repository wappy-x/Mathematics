-- Bounded and symmetric: every bounded self-adjoint operator on a complex Hilbert space is multiplication by a real function after an energy-keeping change of variables, functions of it are functions of the multiplier, and the fade has no eigenvectors.
import Mathlib.Analysis.CStarAlgebra.ContinuousLinearMap
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Basic
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Instances
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.RieszMarkovKakutani.Real
import Mathlib.MeasureTheory.Function.ContinuousMapDense
import Mathlib.Analysis.Normed.Operator.Extend
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Topology.ContinuousMap.StoneWeierstrass
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure

open MeasureTheory

universe u

section Helpers

open Filter Topology
open scoped ENNReal ComplexConjugate CompactlySupported

section Slices
variable {ι X : Type*} [MeasurableSpace ι] [MeasurableSingletonClass ι] [MeasurableSpace X]
  (M : ι → Measure X)

/-- The disjoint-union measure on `ι × X`. -/
noncomputable def sumMeas : Measure (ι × X) := Measure.sum (fun i => (M i).map (Prod.mk i))

theorem measurableSet_slice (i : ι) : MeasurableSet ({i} ×ˢ Set.univ : Set (ι × X)) :=
  (measurableSet_singleton i).prod MeasurableSet.univ

theorem sumMeas_restrict (i : ι) :
    (sumMeas M).restrict ({i} ×ˢ Set.univ) = (M i).map (Prod.mk i) := by
  ext A hA
  rw [Measure.restrict_apply hA, sumMeas,
    Measure.sum_apply _ (hA.inter (measurableSet_slice i)), tsum_eq_single i]
  · rw [Measure.map_apply measurable_prodMk_left (hA.inter (measurableSet_slice i)),
      Measure.map_apply measurable_prodMk_left hA]
    congr 1; ext x; simp
  · intro j hj
    rw [Measure.map_apply measurable_prodMk_left (hA.inter (measurableSet_slice i))]
    convert measure_empty (μ := M j)
    ext x; simp [hj]

theorem ae_slice {i : ι} {P : X → Prop} (h : ∀ᵐ x ∂M i, P x) :
    ∀ᵐ ω ∂sumMeas M, ω.1 = i → P ω.2 := by
  rw [ae_iff] at h ⊢
  have hsub : {ω : ι × X | ¬(ω.1 = i → P ω.2)} ⊆ Prod.mk i '' {x | ¬P x} := by
    rintro ⟨j, x⟩ hω
    simp only [Set.mem_setOf_eq, not_imp] at hω
    obtain ⟨rfl, hx⟩ := hω
    exact ⟨x, hx, rfl⟩
  refine measure_mono_null hsub ?_
  have hS : Prod.mk i '' {x | ¬P x} ⊆ {i} ×ˢ Set.univ := by rintro _ ⟨x, -, rfl⟩; simp
  rw [← Set.inter_eq_left.mpr hS, ← Measure.restrict_apply' (measurableSet_slice i),
    sumMeas_restrict, (measurableEmbedding_prodMk_left i).map_apply,
    Set.preimage_image_eq _ (Prod.mk_right_injective i)]
  exact h

theorem lintegral_sumMeas (f : ι × X → ℝ≥0∞) :
    ∫⁻ ω, f ω ∂sumMeas M = ∑' i, ∫⁻ x, f (i, x) ∂M i := by
  rw [sumMeas, lintegral_sum_measure]
  congr 1; ext i
  rw [(measurableEmbedding_prodMk_left i).lintegral_map]

theorem lintegral_sumMeas_slice (i : ι) (f : ι × X → ℝ≥0∞) (hf : ∀ ω, ω.1 ≠ i → f ω = 0) :
    ∫⁻ ω, f ω ∂sumMeas M = ∫⁻ x, f (i, x) ∂M i := by
  rw [lintegral_sumMeas, tsum_eq_single i]
  intro j hj
  simp [hf (j, _) hj]

theorem integral_sumMeas_slice (i : ι) (f : ι × X → ℂ) (hf : ∀ ω, ω.1 ≠ i → f ω = 0) :
    ∫ ω, f ω ∂sumMeas M = ∫ x, f (i, x) ∂M i := by
  rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := {i} ×ˢ Set.univ)
    (fun ω hω => hf ω (by simpa using hω)), sumMeas_restrict,
    (measurableEmbedding_prodMk_left i).integral_map]

/-- Extension by zero from the slice `{i} × X`. -/
noncomputable def ext0 (i : ι) (f : X → ℂ) : ι × X → ℂ :=
  ({i} ×ˢ Set.univ : Set (ι × X)).indicator (f ∘ Prod.snd)

theorem ext0_same (i : ι) (f : X → ℂ) (x : X) : ext0 i f (i, x) = f x := by
  simp [ext0]

theorem ext0_ne (i : ι) (f : X → ℂ) (ω : ι × X) (h : ω.1 ≠ i) : ext0 i f ω = 0 := by
  simp [ext0, h]

theorem ext0_apply (i : ι) (f : X → ℂ) (ω : ι × X) (h : ω.1 = i) : ext0 i f ω = f ω.2 := by
  obtain ⟨j, x⟩ := ω; simp only at h; subst h; exact ext0_same _ _ _

theorem ext0_sm (i : ι) (f : X → ℂ) (hf : StronglyMeasurable f) :
    StronglyMeasurable (ext0 i f) :=
  (hf.comp_measurable measurable_snd).indicator (measurableSet_slice i)

theorem eLpNorm_ext0 (i : ι) (f : X → ℂ) (hf : StronglyMeasurable f) :
    eLpNorm (ext0 i f) 2 (sumMeas M) = eLpNorm f 2 (M i) := by
  rw [eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num)
      (ext0_sm i f hf).aestronglyMeasurable,
    eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num) hf.aestronglyMeasurable]
  congr 1
  rw [lintegral_sumMeas_slice M i]
  · simp [ext0_same]
  · intro ω h
    rw [ext0_ne i f ω h]; simp

theorem memLp_ext0 (i : ι) (ψ : Lp ℂ 2 (M i)) : MemLp (ext0 i ψ) 2 (sumMeas M) := by
  rw [memLp_iff, eLpNorm_ext0 M i _ (Lp.stronglyMeasurable ψ)]; exact Lp.eLpNorm_lt_top ψ

/-- Extension by zero as a linear isometry. -/
noncomputable def Jmap (i : ι) : Lp ℂ 2 (M i) →ₗᵢ[ℂ] Lp ℂ 2 (sumMeas M) where
  toFun ψ := (memLp_ext0 M i ψ).toLp _
  map_add' ψ φ := by
    rw [← MemLp.toLp_add (memLp_ext0 M i ψ) (memLp_ext0 M i φ)]
    apply MemLp.toLp_congr
    filter_upwards [ae_slice M (Lp.coeFn_add ψ φ)] with ω h
    by_cases hω : ω.1 = i
    · simp only [Pi.add_apply, ext0_apply i _ ω hω, h hω]
    · simp only [Pi.add_apply, ext0_ne i _ ω hω, add_zero]
  map_smul' c ψ := by
    rw [RingHom.id_apply, ← MemLp.toLp_const_smul c (memLp_ext0 M i ψ)]
    apply MemLp.toLp_congr
    filter_upwards [ae_slice M (Lp.coeFn_smul c ψ)] with ω h
    by_cases hω : ω.1 = i
    · simp only [Pi.smul_apply, ext0_apply i _ ω hω, h hω, RingHom.id_apply]
    · simp only [Pi.smul_apply, ext0_ne i _ ω hω, smul_zero]
  norm_map' ψ := by
    simp only [LinearMap.coe_mk, AddHom.coe_mk]
    rw [Lp.norm_toLp, eLpNorm_ext0 M i _ (Lp.stronglyMeasurable ψ), Lp.norm_def]

theorem Jmap_coe (i : ι) (ψ : Lp ℂ 2 (M i)) :
    (Jmap M i ψ : ι × X → ℂ) =ᵐ[sumMeas M] ext0 i ψ :=
  (memLp_ext0 M i ψ).coeFn_toLp

theorem Jmap_orth : OrthogonalFamily ℂ (fun i => Lp ℂ 2 (M i)) (Jmap M) := by
  intro i j hij ψ φ
  rw [L2.inner_def]
  refine (integral_congr_ae ?_).trans (integral_zero _ _)
  filter_upwards [Jmap_coe M i ψ, Jmap_coe M j φ] with ω h1 h2
  rw [h1, h2]
  by_cases hω : ω.1 = i
  · rw [ext0_ne j φ ω (by rw [hω]; exact hij), inner_zero_right]
  · rw [ext0_ne i ψ ω hω, inner_zero_left]

theorem Jmap_total (φ : Lp ℂ 2 (sumMeas M))
    (h : ∀ i (ψ : Lp ℂ 2 (M i)), inner ℂ (Jmap M i ψ) φ = 0) : φ = 0 := by
  set s : ι → X → ℂ := fun i x => φ (i, x)
  have hsm : ∀ i, StronglyMeasurable (s i) := fun i =>
    (Lp.stronglyMeasurable φ).comp_measurable measurable_prodMk_left
  have hle : ∀ i, eLpNorm (s i) 2 (M i) ≤ eLpNorm φ 2 (sumMeas M) := by
    intro i
    rw [eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num)
        (hsm i).aestronglyMeasurable,
      eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num)
        (Lp.aestronglyMeasurable φ), lintegral_sumMeas]
    gcongr
    exact ENNReal.le_tsum (f := fun j => ∫⁻ x, ‖φ (j, x)‖ₑ ^ (2 : ℝ≥0∞).toReal ∂M j) i
  have hmem : ∀ i, MemLp (s i) 2 (M i) := fun i =>
    memLp_iff.mpr (lt_of_le_of_lt (hle i) (Lp.eLpNorm_lt_top φ))
  have hzero : ∀ i, s i =ᵐ[M i] 0 := by
    intro i
    set ψ := (hmem i).toLp (s i)
    have hψ : (ψ : X → ℂ) =ᵐ[M i] s i := MemLp.coeFn_toLp _
    have h1 := h i ψ
    rw [L2.inner_def] at h1
    have h2 : ∫ ω, inner ℂ ((Jmap M i ψ) ω) (φ ω) ∂sumMeas M =
        ∫ ω, inner ℂ (ext0 i ψ ω) (φ ω) ∂sumMeas M := by
      refine integral_congr_ae ?_
      filter_upwards [Jmap_coe M i ψ] with ω hω
      rw [hω]
    rw [h2, integral_sumMeas_slice M i _ (fun ω hω => by rw [ext0_ne i _ ω hω, inner_zero_left])]
      at h1
    simp only [ext0_same] at h1
    have h3 : inner ℂ ψ ψ = 0 := by
      rw [L2.inner_def, ← h1]
      refine integral_congr_ae ?_
      filter_upwards [hψ] with x hx
      rw [hx]
    have h4 : ψ = 0 := inner_self_eq_zero.mp h3
    filter_upwards [hψ, Lp.eq_zero_iff_ae_eq_zero.mp h4] with x h5 h6
    rw [← h5, h6]
  rw [Lp.eq_zero_iff_ae_eq_zero, ← eLpNorm_eq_zero_iff two_ne_zero,
    eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num)
      (Lp.aestronglyMeasurable φ), lintegral_sumMeas]
  have : ∀ i, ∫⁻ x, ‖φ (i, x)‖ₑ ^ (2 : ℝ≥0∞).toReal ∂M i = 0 := by
    intro i
    rw [lintegral_eq_zero_iff']
    · filter_upwards [hzero i] with x hx
      simp only [s] at hx
      simp [hx]
    · exact ((hsm i).enorm.pow_const _).aemeasurable
  simp only [this, tsum_zero]
  exact ENNReal.zero_rpow_of_pos (by norm_num)

end Slices

section Cyclic
variable {H : Type u} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

/-- The continuous functional calculus of a self-adjoint operator, with complex functions on its
complex spectrum. -/
noncomputable abbrev cfcC (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) :
    C(spectrum ℂ T, ℂ) →⋆ₐ[ℂ] (H →L[ℂ] H) := cfcHom hT.isStarNormal

theorem cfcC_inner (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (a b : C(spectrum ℂ T, ℂ)) (v w : H) :
    inner ℂ (cfcC T hT a v) (cfcC T hT b w) = inner ℂ v (cfcC T hT (star a * b) w) := by
  rw [map_mul, map_star, ContinuousLinearMap.star_eq_adjoint, ContinuousLinearMap.mul_apply,
    ContinuousLinearMap.adjoint_inner_right]

/-- A real continuous function, viewed as a complex one. -/
noncomputable def toC {X : Type*} [TopologicalSpace X] (r : X → ℝ) (hr : Continuous r) :
    C(X, ℂ) := ⟨fun x => (r x : ℂ), by fun_prop⟩

theorem cyc_nonneg (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) (r : spectrum ℂ T → ℝ)
    (hr : Continuous r) (h0 : ∀ x, 0 ≤ r x) :
    0 ≤ (inner ℂ v (cfcC T hT (toC r hr) v)).re := by
  set b : C(spectrum ℂ T, ℂ) := toC (fun x => Real.sqrt (r x)) (by fun_prop)
  have hb : toC r hr = star b * b := by
    ext x
    simp only [toC, b, ContinuousMap.coe_mk, ContinuousMap.mul_apply, ContinuousMap.star_apply,
      Complex.star_def, Complex.conj_ofReal]
    rw [← Complex.ofReal_mul, Real.mul_self_sqrt (h0 x)]
  rw [hb, ← cfcC_inner]
  exact inner_self_nonneg (𝕜 := ℂ)

/-- The positive functional `r ↦ ⟨v, r(T) v⟩` on continuous functions on the spectrum. -/
noncomputable def cycFun (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) :
    C_c(spectrum ℂ T, ℝ) →ₚ[ℝ] ℝ where
  toFun r := (inner ℂ v (cfcC T hT (toC r r.continuous) v)).re
  map_add' r s := by
    have : toC (⇑(r + s)) (r + s).continuous = toC r r.continuous + toC s s.continuous := by
      ext x; simp [toC]
    rw [this, map_add, ContinuousLinearMap.add_apply, inner_add_right, Complex.add_re]
  map_smul' c r := by
    have : toC (⇑(c • r)) (c • r).continuous = (c : ℂ) • toC r r.continuous := by
      ext x; simp [toC]
    rw [this, map_smul, ContinuousLinearMap.smul_apply, inner_smul_right, Complex.re_ofReal_mul]
    rfl
  monotone' r s h := by
    have hd := cyc_nonneg T hT v (s - r) (s - r).continuous (fun x => by
      simp only [CompactlySupportedContinuousMap.coe_sub, Pi.sub_apply, sub_nonneg]; exact h x)
    have : toC (⇑s - ⇑r) (s - r).continuous = toC s s.continuous - toC r r.continuous := by
      ext x; simp [toC]
    dsimp only
    rw [this, map_sub, ContinuousLinearMap.sub_apply, inner_sub_right, Complex.sub_re,
      sub_nonneg] at hd
    exact hd

/-- The spectral measure of the vector `v`. -/
noncomputable def cycMeas (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) :
    Measure (spectrum ℂ T) := RealRMK.rieszMeasure (cycFun T hT v)

instance (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) : IsFiniteMeasure (cycMeas T hT v) := by
  unfold cycMeas; infer_instance

theorem integral_cycMeas (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) (r : spectrum ℂ T → ℝ)
    (hr : Continuous r) :
    ∫ x, r x ∂cycMeas T hT v = (inner ℂ v (cfcC T hT (toC r hr) v)).re := by
  have := RealRMK.integral_rieszMeasure (cycFun T hT v)
    ⟨⟨r, hr⟩, HasCompactSupport.of_compactSpace _⟩
  convert this using 1 <;> rfl

theorem norm_toLp_cyc (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) (a : C(spectrum ℂ T, ℂ)) :
    ‖cfcC T hT a v‖ = ‖ContinuousMap.toLp (E := ℂ) 2 (cycMeas T hT v) ℂ a‖ := by
  have h1 := ContinuousMap.inner_toLp (μ := cycMeas T hT v) a a
  rw [inner_self_eq_norm_sq_to_K] at h1
  have h2 : ∀ x, a x * conj (a x) = ((‖a x‖ ^ 2 : ℝ) : ℂ) := by
    intro x; rw [Complex.mul_conj, Complex.normSq_eq_norm_sq]
  simp_rw [h2] at h1
  rw [integral_complex_ofReal, integral_cycMeas T hT v _ (by fun_prop)] at h1
  have h3 : toC (fun x => ‖a x‖ ^ 2) (by fun_prop) = star a * a := by
    ext x
    simp only [toC, ContinuousMap.coe_mk, ContinuousMap.mul_apply, ContinuousMap.star_apply,
      Complex.star_def]
    rw [mul_comm, Complex.mul_conj, Complex.normSq_eq_norm_sq]
  rw [h3, ← cfcC_inner, inner_self_eq_norm_sq_to_K] at h1
  have h4 : ‖ContinuousMap.toLp (E := ℂ) 2 (cycMeas T hT v) ℂ a‖ ^ 2 = ‖cfcC T hT a v‖ ^ 2 := by
    have := congrArg Complex.re h1
    norm_cast at this
  have := (sq_eq_sq₀ (norm_nonneg _) (norm_nonneg _)).mp h4
  exact this.symm


/-- `a ↦ a(T) v` as a linear map. -/
noncomputable def cycLin (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) :
    C(spectrum ℂ T, ℂ) →ₗ[ℂ] H where
  toFun a := cfcC T hT a v
  map_add' a b := by simp
  map_smul' c a := by simp

theorem cyc_dense (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) :
    DenseRange (ContinuousMap.toLp (E := ℂ) 2 (cycMeas T hT v) ℂ :
      C(spectrum ℂ T, ℂ) →L[ℂ] Lp ℂ 2 (cycMeas T hT v)) :=
  ContinuousMap.toLp_denseRange ℂ (cycMeas T hT v) ℂ (by simp)

/-- The cyclic subspace of `v`, realised as `L²` of the spectral measure of `v`. -/
noncomputable def cycIso (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) :
    Lp ℂ 2 (cycMeas T hT v) →ₗᵢ[ℂ] H :=
  (cycLin T hT v).extendOfIsometry
    (e := (ContinuousMap.toLp (E := ℂ) 2 (cycMeas T hT v) ℂ).toLinearMap)
    (cyc_dense T hT v) (fun a => norm_toLp_cyc T hT v a)

theorem cycIso_toLp (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v : H) (a : C(spectrum ℂ T, ℂ)) :
    cycIso T hT v (ContinuousMap.toLp (E := ℂ) 2 (cycMeas T hT v) ℂ a) = cfcC T hT a v :=
  LinearMap.extendOfIsometry_eq _ _ _ a

theorem cycIso_orth (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v w : H)
    (h : ∀ c : C(spectrum ℂ T, ℂ), inner ℂ v (cfcC T hT c w) = 0)
    (ψ : Lp ℂ 2 (cycMeas T hT v)) (φ : Lp ℂ 2 (cycMeas T hT w)) :
    inner ℂ (cycIso T hT v ψ) (cycIso T hT w φ) = 0 := by
  refine (cyc_dense T hT v).induction_on ψ
    (isClosed_eq ((cycIso T hT v).continuous.inner continuous_const) continuous_const)
    (fun a => ?_)
  refine (cyc_dense T hT w).induction_on φ
    (isClosed_eq (continuous_const.inner (cycIso T hT w).continuous) continuous_const)
    (fun b => ?_)
  rw [cycIso_toLp, cycIso_toLp, cfcC_inner]
  exact h _

/-- Two vectors generate orthogonal cyclic subspaces. -/
def CycOrth (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (v w : H) : Prop :=
  ∀ c : C(spectrum ℂ T, ℂ), inner ℂ v (cfcC T hT c w) = 0

theorem exists_maximal_cyc (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) :
    ∃ F : Set H, Maximal (fun F : Set H => F.Pairwise (CycOrth T hT)) F := by
  obtain ⟨m, hm⟩ := zorn_subset {F : Set H | F.Pairwise (CycOrth T hT)}
    (fun c hc hchain => ⟨⋃₀ c, (Set.pairwise_sUnion hchain.directedOn).mpr hc,
      fun s hs => Set.subset_sUnion_of_mem hs⟩)
  exact ⟨m, hm⟩

theorem cyc_total (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (F : Set H)
    (hF : Maximal (fun F : Set H => F.Pairwise (CycOrth T hT)) F) :
    ⊤ ≤ (⨆ i : F, LinearMap.range (cycIso T hT i.1).toLinearMap).topologicalClosure := by
  rw [top_le_iff, Submodule.topologicalClosure_eq_top_iff, Submodule.eq_bot_iff]
  intro w hw
  have hA : ∀ v ∈ F, ∀ a : C(spectrum ℂ T, ℂ), inner ℂ (cfcC T hT a v) w = 0 := by
    intro v hv a
    rw [← cycIso_toLp]
    exact (Submodule.mem_orthogonal _ _).mp hw _
      (Submodule.mem_iSup_of_mem ⟨v, hv⟩ (LinearMap.mem_range_self _ _))
  have hins : (insert w F).Pairwise (CycOrth T hT) := by
    rw [Set.pairwise_insert]
    refine ⟨hF.1, fun v hv _ => ⟨fun c => ?_, fun c => ?_⟩⟩
    · rw [inner_eq_zero_symm]; exact hA v hv c
    · rw [← ContinuousLinearMap.adjoint_inner_left, ← ContinuousLinearMap.star_eq_adjoint,
        ← map_star]
      exact hA v hv (star c)
  have hwF : w ∈ F := hF.2 hins (Set.subset_insert w F) (Set.mem_insert w F)
  have := hA w hwF 1
  rw [map_one, ContinuousLinearMap.one_apply, inner_self_eq_zero] at this
  exact this

theorem T_cfcC (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (a : C(spectrum ℂ T, ℂ)) (v : H) :
    T (cfcC T hT a v) =
      cfcC T hT (((ContinuousMap.id ℂ).restrict (spectrum ℂ T)) * a) v := by
  rw [map_mul, ContinuousLinearMap.mul_apply, cfcHom_id]

end Cyclic

section MulSet
variable {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}

/-- The vectors on which an operator acts as multiplication by `g`. -/
def mulSubmodule (A : Lp ℂ 2 μ →L[ℂ] Lp ℂ 2 μ) (g : Ω → ℂ) : Submodule ℂ (Lp ℂ 2 μ) where
  carrier := {ψ | (A ψ : Ω → ℂ) =ᵐ[μ] fun θ => g θ * ψ θ}
  add_mem' := by
    intro ψ φ hψ hφ
    simp only [Set.mem_setOf_eq, map_add] at *
    filter_upwards [Lp.coeFn_add (A ψ) (A φ), Lp.coeFn_add ψ φ, hψ, hφ] with θ h1 h2 h3 h4
    rw [h1, h2, Pi.add_apply, Pi.add_apply, h3, h4]; ring
  zero_mem' := by
    simp only [Set.mem_setOf_eq, map_zero]
    filter_upwards [Lp.coeFn_zero ℂ 2 μ] with θ h
    rw [h]; simp
  smul_mem' := by
    intro c ψ hψ
    simp only [Set.mem_setOf_eq, map_smul] at *
    filter_upwards [Lp.coeFn_smul c (A ψ), Lp.coeFn_smul c ψ, hψ] with θ h1 h2 h3
    rw [h1, h2, Pi.smul_apply, Pi.smul_apply, h3, smul_eq_mul, smul_eq_mul]; ring

theorem mulSubmodule_closed (A : Lp ℂ 2 μ →L[ℂ] Lp ℂ 2 μ) (g : Ω → ℂ) :
    IsClosed (mulSubmodule A g : Set (Lp ℂ 2 μ)) := by
  refine isClosed_of_closure_subset (fun ψ hψ => ?_)
  obtain ⟨s, hs, hlim⟩ := mem_closure_iff_seq_limit.mp hψ
  obtain ⟨n1, hn1, h1⟩ := (tendstoInMeasure_of_tendsto_Lp hlim).exists_seq_tendsto_ae
  have hlim2 : Tendsto (fun k => A (s (n1 k))) atTop (𝓝 (A ψ)) :=
    ((A.continuous.tendsto ψ).comp hlim).comp hn1.tendsto_atTop
  obtain ⟨n2, hn2, h2⟩ := (tendstoInMeasure_of_tendsto_Lp hlim2).exists_seq_tendsto_ae
  have h3 : ∀ᵐ θ ∂μ, ∀ n, (A (s n) : Ω → ℂ) θ = g θ * s n θ := ae_all_iff.mpr (fun n => hs n)
  show (A ψ : Ω → ℂ) =ᵐ[μ] fun θ => g θ * ψ θ
  filter_upwards [h1, h2, h3] with θ ha hb hc
  simp only [hc] at hb
  exact tendsto_nhds_unique hb ((ha.comp hn2.tendsto_atTop).const_mul (g θ))

end MulSet

theorem spectral_multiplication_aux
    {H : Type u} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]
    (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) :
    ∃ (Ω : Type u) (_ : MeasurableSpace Ω) (μ : Measure Ω) (U : H ≃ₗᵢ[ℂ] Lp ℂ 2 μ) (g : Ω → ℝ),
      Measurable g ∧ (∀ θ, g θ ∈ spectrum ℝ T) ∧
      ∀ ψ : Lp ℂ 2 μ, (U (T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) * ψ θ := by
  classical
  obtain ⟨F, hF⟩ := exists_maximal_cyc T hT
  let mF : MeasurableSpace F := ⊤
  have : MeasurableSingletonClass F := ⟨fun _ => MeasurableSpace.measurableSet_top⟩
  let M : F → Measure (spectrum ℂ T) := fun i => cycMeas T hT i.1
  let V : ∀ i : F, Lp ℂ 2 (M i) →ₗᵢ[ℂ] H := fun i => cycIso T hT i.1
  have hVo : OrthogonalFamily ℂ (fun i : F => Lp ℂ 2 (M i)) V := by
    intro i j hij ψ φ
    exact cycIso_orth T hT i.1 j.1 (hF.1 i.2 j.2 (fun h => hij (Subtype.ext h))) ψ φ
  have hHS : IsHilbertSum ℂ (fun i : F => Lp ℂ 2 (M i)) V :=
    IsHilbertSum.mk hVo (cyc_total T hT F hF)
  have hJt : ⊤ ≤ (⨆ i, LinearMap.range (Jmap M i).toLinearMap).topologicalClosure := by
    rw [top_le_iff, Submodule.topologicalClosure_eq_top_iff, Submodule.eq_bot_iff]
    intro φ hφ
    exact Jmap_total M φ (fun i ψ => (Submodule.mem_orthogonal _ _).mp hφ _
      (Submodule.mem_iSup_of_mem i (LinearMap.mem_range_self _ ψ)))
  have hΩ : IsHilbertSum ℂ (fun i : F => Lp ℂ 2 (M i)) (Jmap M) :=
    IsHilbertSum.mk (Jmap_orth M) hJt
  let U : H ≃ₗᵢ[ℂ] Lp ℂ 2 (sumMeas M) :=
    hHS.linearIsometryEquiv.trans hΩ.linearIsometryEquiv.symm
  have hUV : ∀ i ψ, U.symm (Jmap M i ψ) = V i ψ := by
    intro i ψ
    rw [LinearIsometryEquiv.symm_apply_eq]
    have := hHS.linearIsometryEquiv_symm_apply_single (i := i) ψ
    simp only [U, LinearIsometryEquiv.trans_apply]
    rw [← this, LinearIsometryEquiv.apply_symm_apply, hΩ.linearIsometryEquiv_symm_apply_single]
  let g : F × spectrum ℂ T → ℝ := fun ω => (ω.2 : ℂ).re
  have hgre : ∀ x : spectrum ℂ T, (x : ℂ) = ((x : ℂ).re : ℂ) := fun x =>
    hT.mem_spectrum_eq_re x.2
  refine ⟨F × spectrum ℂ T, inferInstance, sumMeas M, U, g, ?_, ?_, ?_⟩
  · exact Complex.measurable_re.comp (measurable_subtype_coe.comp measurable_snd)
  · intro ω
    have h := ω.2.2
    rw [hgre ω.2] at h
    exact (spectrum.algebraMap_mem_iff ℂ).mp h
  · let A : Lp ℂ 2 (sumMeas M) →L[ℂ] Lp ℂ 2 (sumMeas M) :=
      U.toContinuousLinearEquiv.toContinuousLinearMap ∘L T ∘L
        U.symm.toContinuousLinearEquiv.toContinuousLinearMap
    let G := mulSubmodule A (fun ω => (g ω : ℂ))
    have hGc : IsClosed (G : Set (Lp ℂ 2 (sumMeas M))) := mulSubmodule_closed A _
    have hJG : ∀ i ψ, Jmap M i ψ ∈ G := by
      intro i ψ
      refine (cyc_dense T hT i.1).induction_on ψ (hGc.preimage (Jmap M i).continuous)
        (fun a => ?_)
      set idX : C(spectrum ℂ T, ℂ) := (ContinuousMap.id ℂ).restrict (spectrum ℂ T)
      have hA : A (Jmap M i (ContinuousMap.toLp (E := ℂ) 2 (M i) ℂ a)) =
          Jmap M i (ContinuousMap.toLp (E := ℂ) 2 (M i) ℂ (idX * a)) := by
        simp only [A, ContinuousLinearMap.comp_apply]
        change U (T (U.symm (Jmap M i (ContinuousMap.toLp (E := ℂ) 2 (M i) ℂ a)))) = _
        rw [hUV]
        show U (T (cycIso T hT i.1 _)) = _
        rw [cycIso_toLp, T_cfcC, ← cycIso_toLp, ← hUV i, LinearIsometryEquiv.apply_symm_apply]
      show (A _ : F × spectrum ℂ T → ℂ) =ᵐ[sumMeas M] _
      rw [hA]
      filter_upwards [Jmap_coe M i (ContinuousMap.toLp (E := ℂ) 2 (M i) ℂ (idX * a)),
        Jmap_coe M i (ContinuousMap.toLp (E := ℂ) 2 (M i) ℂ a),
        ae_slice M (ContinuousMap.coeFn_toLp (p := 2) (𝕜 := ℂ) (M i) (idX * a)),
        ae_slice M (ContinuousMap.coeFn_toLp (p := 2) (𝕜 := ℂ) (M i) a)] with ω h1 h2 h3 h4
      rw [h1, h2]
      by_cases hω : ω.1 = i
      · rw [ext0_apply i _ ω hω, ext0_apply i _ ω hω, h3 hω, h4 hω]
        simp only [ContinuousMap.mul_apply, idX, ContinuousMap.restrict_apply,
          ContinuousMap.id_apply, g]
        rw [← hgre]
      · rw [ext0_ne i _ ω hω, ext0_ne i _ ω hω, mul_zero]
    have hle : ⊤ ≤ G := hJt.trans (Submodule.topologicalClosure_minimal _
      (iSup_le fun i => by rintro _ ⟨ψ, rfl⟩; exact hJG i ψ) hGc)
    intro ψ
    exact hle Submodule.mem_top

section T2
variable {H : Type u} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}

theorem conj_pow_ae (T : H →L[ℂ] H) (U : H ≃ₗᵢ[ℂ] Lp ℂ 2 μ) (g : Ω → ℝ)
    (hUT : ∀ ψ : Lp ℂ 2 μ, (U (T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) * ψ θ)
    (n : ℕ) (ψ : Lp ℂ 2 μ) :
    (U ((T ^ n) (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) ^ n * ψ θ := by
  induction n generalizing ψ with
  | zero => simp
  | succ n ih =>
    have h1 := hUT (U ((T ^ n) (U.symm ψ)))
    rw [LinearIsometryEquiv.symm_apply_apply] at h1
    rw [pow_succ', ContinuousLinearMap.mul_apply]
    filter_upwards [h1, ih ψ] with θ h1 h2
    rw [h1, h2]; ring

theorem conj_aeval_ae (T : H →L[ℂ] H) (U : H ≃ₗᵢ[ℂ] Lp ℂ 2 μ) (g : Ω → ℝ)
    (hUT : ∀ ψ : Lp ℂ 2 μ, (U (T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) * ψ θ)
    (q : Polynomial ℝ) (ψ : Lp ℂ 2 μ) :
    (U (Polynomial.aeval T q (U.symm ψ)) : Ω → ℂ) =ᵐ[μ]
      fun θ => ((q.eval (g θ) : ℝ) : ℂ) * ψ θ := by
  induction q using Polynomial.induction_on' with
  | add p q hp hq =>
    rw [map_add, ContinuousLinearMap.add_apply, map_add]
    filter_upwards [Lp.coeFn_add (U (Polynomial.aeval T p (U.symm ψ)))
      (U (Polynomial.aeval T q (U.symm ψ))), hp, hq] with θ h1 h2 h3
    rw [h1, Pi.add_apply, h2, h3, Polynomial.eval_add]; push_cast; ring
  | monomial n c =>
    rw [Polynomial.aeval_monomial, ContinuousLinearMap.mul_apply, Algebra.algebraMap_eq_smul_one,
      ContinuousLinearMap.smul_apply, ContinuousLinearMap.one_apply, ← Complex.coe_smul, map_smul]
    filter_upwards [Lp.coeFn_smul (c : ℂ) (U ((T ^ n) (U.symm ψ))), conj_pow_ae T U g hUT n ψ]
      with θ h1 h2
    rw [h1, Pi.smul_apply, h2, Polynomial.eval_monomial, smul_eq_mul]; push_cast; ring

theorem conj_vanish_near (T : H →L[ℂ] H) (U : H ≃ₗᵢ[ℂ] Lp ℂ 2 μ) (g : Ω → ℝ)
    (hg : Measurable g)
    (hUT : ∀ ψ : Lp ℂ 2 μ, (U (T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) * ψ θ)
    (l : ℝ) (hl : l ∉ spectrum ℝ T) :
    ∃ δ > 0, ∀ ψ : Lp ℂ 2 μ, ∀ᵐ θ ∂μ, |g θ - l| < δ → ψ θ = 0 := by
  rw [spectrum.notMem_iff] at hl
  obtain ⟨R, hR⟩ := hl
  set R0 : H →L[ℂ] H := (↑R⁻¹ : H →L[ℂ] H)
  refine ⟨1 / (‖R0‖ + 1), by positivity, fun ψ => ?_⟩
  set E := {θ | |g θ - l| < 1 / (‖R0‖ + 1)}
  have hE : MeasurableSet E := measurableSet_lt (continuous_abs.measurable.comp (hg.sub_const l)) measurable_const
  set φ : Lp ℂ 2 μ := ((Lp.memLp ψ).indicator hE.nullMeasurableSet).toLp (E.indicator ψ)
  have hφ : (φ : Ω → ℂ) =ᵐ[μ] E.indicator ψ := MemLp.coeFn_toLp _
  set χ : Lp ℂ 2 μ := U (R0 (U.symm φ))
  have key : U ((algebraMap ℝ (H →L[ℂ] H) l - T) (U.symm χ)) = φ := by
    simp only [χ, LinearIsometryEquiv.symm_apply_apply, R0, ← hR, ← ContinuousLinearMap.mul_apply,
      Units.mul_inv, ContinuousLinearMap.one_apply, LinearIsometryEquiv.apply_symm_apply]
  have key2 : φ = (l : ℂ) • χ - U (T (U.symm χ)) := by
    rw [← key, ContinuousLinearMap.sub_apply, Algebra.algebraMap_eq_smul_one,
      ContinuousLinearMap.smul_apply, ContinuousLinearMap.one_apply, ← Complex.coe_smul, map_sub,
      map_smul, LinearIsometryEquiv.apply_symm_apply]
  have hφ2 : (φ : Ω → ℂ) =ᵐ[μ] fun θ => ((l : ℂ) - g θ) * χ θ := by
    rw [key2]
    filter_upwards [Lp.coeFn_sub ((l : ℂ) • χ) (U (T (U.symm χ))), Lp.coeFn_smul (l : ℂ) χ,
      hUT χ] with θ h1 h2 h3
    rw [h1, Pi.sub_apply, h2, h3, Pi.smul_apply, smul_eq_mul]; ring
  have hle : ∀ᵐ θ ∂μ, ‖φ θ‖ ≤ 1 / (‖R0‖ + 1) * ‖χ θ‖ := by
    filter_upwards [hφ, hφ2] with θ h1 h2
    by_cases hθ : θ ∈ E
    · rw [h2, norm_mul]
      gcongr
      rw [← Complex.ofReal_sub, Complex.norm_real, Real.norm_eq_abs, abs_sub_comm]
      exact le_of_lt hθ
    · rw [h1, Set.indicator_of_notMem hθ, norm_zero]; positivity
  have hn : ‖φ‖ ≤ 1 / (‖R0‖ + 1) * ‖χ‖ := Lp.norm_le_mul_norm_of_ae_le_mul hle
  have hχ : ‖χ‖ ≤ ‖R0‖ * ‖φ‖ := by
    simp only [χ, LinearIsometryEquiv.norm_map]
    calc ‖R0 (U.symm φ)‖ ≤ ‖R0‖ * ‖U.symm φ‖ := R0.le_opNorm _
      _ = ‖R0‖ * ‖φ‖ := by rw [LinearIsometryEquiv.norm_map]
  have hφ0 : ‖φ‖ = 0 := by
    rw [one_div, inv_mul_eq_div, le_div_iff₀ (by positivity)] at hn
    nlinarith [norm_nonneg φ, norm_nonneg R0]
  have hφ00 : φ = 0 := norm_eq_zero.mp hφ0
  filter_upwards [hφ, Lp.eq_zero_iff_ae_eq_zero.mp hφ00] with θ h1 h2 hθ
  rw [h2, Set.indicator_of_mem (show θ ∈ E from hθ)] at h1
  exact h1.symm

theorem conj_vanish_off_spectrum (T : H →L[ℂ] H) (U : H ≃ₗᵢ[ℂ] Lp ℂ 2 μ) (g : Ω → ℝ)
    (hg : Measurable g)
    (hUT : ∀ ψ : Lp ℂ 2 μ, (U (T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) * ψ θ)
    (ψ : Lp ℂ 2 μ) : ∀ᵐ θ ∂μ, g θ ∉ spectrum ℝ T → ψ θ = 0 := by
  have h := fun l : {l : ℝ // l ∉ spectrum ℝ T} => conj_vanish_near T U g hg hUT l.1 l.2
  choose δ hδ hδψ using h
  obtain ⟨S, hS, hSU⟩ := TopologicalSpace.isOpen_iUnion_countable
    (fun l => Metric.ball l.1 (δ l)) (fun _ => Metric.isOpen_ball)
  have hae : ∀ᵐ θ ∂μ, ∀ l ∈ S, |g θ - l.1| < δ l → ψ θ = 0 :=
    (ae_ball_iff hS).mpr (fun l _ => hδψ l ψ)
  filter_upwards [hae] with θ hθ hns
  have : g θ ∈ ⋃ l, Metric.ball l.1 (δ l) :=
    Set.mem_iUnion.mpr ⟨⟨g θ, hns⟩, Metric.mem_ball_self (hδ _)⟩
  rw [← hSU] at this
  simp only [Set.mem_iUnion, Metric.mem_ball, Real.dist_eq] at this
  obtain ⟨l, hl, h⟩ := this
  exact hθ l hl h

theorem function_of_operator_aux
    (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (U : H ≃ₗᵢ[ℂ] Lp ℂ 2 μ) (g : Ω → ℝ)
    (hg : Measurable g)
    (hUT : ∀ ψ : Lp ℂ 2 μ, (U (T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) * ψ θ)
    (f : ℝ → ℝ) (hf : ContinuousOn f (spectrum ℝ T)) :
    ∀ ψ : Lp ℂ 2 μ, (U (cfc f T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (f (g θ) : ℂ) * ψ θ := by
  intro ψ
  set s := spectrum ℝ T
  let F : C(s, ℝ) := ⟨s.restrict f, hf.restrict⟩
  have hFmem : F ∈ (polynomialFunctions s).topologicalClosure := by
    rw [polynomialFunctions.topologicalClosure s]; trivial
  have happrox : ∀ n : ℕ, ∃ p : Polynomial ℝ, ∀ x ∈ s, dist (f x) (p.eval x) < 1 / (n + 1) := by
    intro n
    obtain ⟨b, hb, hdist⟩ := Metric.mem_closure_iff.mp hFmem (1 / (n + 1)) (by positivity)
    obtain ⟨p, -, rfl⟩ := hb
    refine ⟨p, fun x hx => ?_⟩
    have := ContinuousMap.dist_apply_le_dist (f := F) (g := Polynomial.toContinuousMapOnAlgHom s p)
      ⟨x, hx⟩
    simp only [F, Polynomial.toContinuousMapOnAlgHom_apply, Polynomial.toContinuousMapOn_apply,
      ContinuousMap.coe_mk, Set.domRestrict_apply, Polynomial.toContinuousMap_apply] at this
    exact lt_of_le_of_lt this hdist
  choose p hp using happrox
  have hunif : TendstoUniformlyOn (fun n => (p n).eval) f atTop s := by
    rw [Metric.tendstoUniformlyOn_iff]
    intro ε hε
    obtain ⟨N, hN⟩ := exists_nat_one_div_lt hε
    filter_upwards [eventually_ge_atTop N] with n hn x hx
    refine lt_of_lt_of_le (hp n x hx) (le_trans ?_ hN.le)
    gcongr
  have hcont : Tendsto (fun n => cfc (p n).eval T) atTop (𝓝 (cfc f T)) :=
    tendsto_cfc_fun hunif (Eventually.of_forall fun n => (p n).continuous.continuousOn)
  have hL : Tendsto (fun n => U (cfc (p n).eval T (U.symm ψ))) atTop
      (𝓝 (U (cfc f T (U.symm ψ)))) :=
    ((U.continuous.comp (ContinuousLinearMap.apply ℂ H (U.symm ψ)).continuous).tendsto _).comp
      hcont
  obtain ⟨ns, hns, hae⟩ := (tendstoInMeasure_of_tendsto_Lp hL).exists_seq_tendsto_ae
  have hpoly : ∀ n, (U (cfc (p n).eval T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ]
      fun θ => (((p n).eval (g θ) : ℝ) : ℂ) * ψ θ := by
    intro n; rw [cfc_polynomial (p n) T hT]; exact conj_aeval_ae T U g hUT (p n) ψ
  filter_upwards [hae, ae_all_iff.mpr hpoly, conj_vanish_off_spectrum T U g hg hUT ψ] with θ h1 h2 h3
  simp only [h2] at h1
  by_cases hθ : g θ ∈ s
  · have h4 : Tendsto (fun i => (((p (ns i)).eval (g θ) : ℝ) : ℂ) * ψ θ) atTop
        (𝓝 ((f (g θ) : ℂ) * ψ θ)) := by
      have := (hunif.tendsto_at hθ).comp hns.tendsto_atTop
      exact ((Complex.continuous_ofReal.tendsto _).comp this).mul_const _
    exact tendsto_nhds_unique h1 h4
  · have h0 := h3 hθ
    simp only [h0, mul_zero] at h1 ⊢
    exact tendsto_nhds_unique h1 tendsto_const_nhds

end T2

end Helpers

#print axioms measurableSet_slice
#print axioms sumMeas_restrict
#print axioms ae_slice
#print axioms lintegral_sumMeas
#print axioms lintegral_sumMeas_slice
#print axioms integral_sumMeas_slice
#print axioms ext0_same
#print axioms ext0_ne
#print axioms ext0_apply
#print axioms ext0_sm
#print axioms eLpNorm_ext0
#print axioms memLp_ext0
#print axioms Jmap_coe
#print axioms Jmap_orth
#print axioms Jmap_total
#print axioms cfcC_inner
#print axioms cyc_nonneg
#print axioms integral_cycMeas
#print axioms norm_toLp_cyc
#print axioms cyc_dense
#print axioms cycIso_toLp
#print axioms cycIso_orth
#print axioms exists_maximal_cyc
#print axioms cyc_total
#print axioms T_cfcC
#print axioms mulSubmodule_closed
#print axioms spectral_multiplication_aux
#print axioms conj_pow_ae
#print axioms conj_aeval_ae
#print axioms conj_vanish_near
#print axioms conj_vanish_off_spectrum
#print axioms function_of_operator_aux

/-- The spectral theorem, multiplication form: a bounded self-adjoint operator T on a complex
Hilbert space H becomes, after an energy-keeping change of variables U from H onto the signals
L²(Ω, μ), multiplication by a measurable real function g whose values lie in the spectrum of T:
U T U⁻¹ ψ = g · ψ for every ψ. -/
theorem bounded_self_adjoint_is_multiplication_by_real_function
    {H : Type u} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]
    (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) :
    ∃ (Ω : Type u) (_ : MeasurableSpace Ω) (μ : Measure Ω) (U : H ≃ₗᵢ[ℂ] Lp ℂ 2 μ) (g : Ω → ℝ),
      Measurable g ∧ (∀ θ, g θ ∈ spectrum ℝ T) ∧
      ∀ ψ : Lp ℂ 2 μ, (U (T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) * ψ θ := by
  exact spectral_multiplication_aux T hT

/-- Functions of the operator: if the change of variables U turns the self-adjoint T into
multiplication by g, then for any function f continuous on the spectrum of T, the same U turns
f(T) into multiplication by f ∘ g. -/
theorem function_of_operator_is_function_of_multiplier
    {H : Type u} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    (T : H →L[ℂ] H) (hT : IsSelfAdjoint T) (U : H ≃ₗᵢ[ℂ] Lp ℂ 2 μ) (g : Ω → ℝ)
    (hg : Measurable g)
    (hUT : ∀ ψ : Lp ℂ 2 μ, (U (T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (g θ : ℂ) * ψ θ)
    (f : ℝ → ℝ) (hf : ContinuousOn f (spectrum ℝ T)) :
    ∀ ψ : Lp ℂ 2 μ, (U (cfc f T (U.symm ψ)) : Ω → ℂ) =ᵐ[μ] fun θ => (f (g θ) : ℂ) * ψ θ := by
  exact function_of_operator_aux T hT U g hg hUT f hf

/-- The fade, multiplication by t on signals of finite energy on the clip (0, 1), has no
eigenvectors: if t·u(t) = λ·u(t) for almost every t then u = 0. Yet every gain λ in [0, 1] is an
approximate eigenvalue: for each ε > 0 some signal of energy 1 has ‖(t − λ)·u‖ < ε, so λ is in the
spectrum. -/
theorem fade_has_no_eigenvectors_but_spectrum_zero_one :
    (∀ (l : ℝ) (u : Lp ℂ 2 (volume.restrict (Set.Ioo (0 : ℝ) 1))),
      (∀ᵐ t : ℝ ∂(volume.restrict (Set.Ioo (0 : ℝ) 1)), (t : ℂ) * u t = (l : ℂ) * u t) → u = 0) ∧
    (∀ l ∈ Set.Icc (0 : ℝ) 1, ∀ ε > 0, ∃ u : Lp ℂ 2 (volume.restrict (Set.Ioo (0 : ℝ) 1)),
      ‖u‖ = 1 ∧
      eLpNorm (fun t : ℝ => ((t : ℂ) - l) * u t) 2 (volume.restrict (Set.Ioo (0 : ℝ) 1))
        < ENNReal.ofReal ε) := by
  constructor
  · intro l u hu
    rw [Lp.eq_zero_iff_ae_eq_zero]
    have hl : ∀ᵐ t : ℝ ∂(volume.restrict (Set.Ioo (0 : ℝ) 1)), t ≠ l := by
      refine ae_restrict_of_ae ?_
      rw [ae_iff]
      simp
    filter_upwards [hu, hl] with t ht htl
    have h1 : ((t : ℂ) - l) * u t = 0 := by rw [sub_mul, ht, sub_self]
    have h2 : (t : ℂ) - l ≠ 0 := by
      rw [sub_ne_zero]; exact_mod_cast htl
    simpa [h2] using h1
  · intro l hl ε hε
    set μ := volume.restrict (Set.Ioo (0 : ℝ) 1)
    set δ : ℝ := min (ε / 2) (1 / 2) with hδ
    have hδpos : 0 < δ := lt_min (by linarith) (by norm_num)
    have hδε : δ < ε := lt_of_le_of_lt (min_le_left _ _) (by linarith)
    have hδh : δ ≤ 1 / 2 := min_le_right _ _
    set a : ℝ := min l (1 - δ) with ha
    have ha0 : 0 ≤ a := le_min hl.1 (by linarith)
    have ha1 : a + δ ≤ 1 := by have := min_le_right l (1 - δ); linarith
    have hal : a ≤ l := min_le_left _ _
    have hla : l ≤ a + δ := by
      rcases min_cases l (1 - δ) with h | h <;> linarith [hl.2, h.1]
    have hsub : Set.Ioo a (a + δ) ⊆ Set.Ioo (0 : ℝ) 1 :=
      Set.Ioo_subset_Ioo ha0 ha1
    have hμs : μ (Set.Ioo a (a + δ)) = ENNReal.ofReal δ := by
      simp only [μ]
      rw [Measure.restrict_apply measurableSet_Ioo, Set.inter_eq_left.mpr hsub, Real.volume_Ioo]
      congr 1; ring
    have hμs' : μ (Set.Ioo a (a + δ)) ≠ ⊤ := by rw [hμs]; exact ENNReal.ofReal_ne_top
    have hμr : μ.real (Set.Ioo a (a + δ)) = δ := by
      rw [measureReal_def, hμs, ENNReal.toReal_ofReal hδpos.le]
    set c : ℂ := (((Real.sqrt δ)⁻¹ : ℝ) : ℂ)
    refine ⟨indicatorConstLp 2 measurableSet_Ioo hμs' c, ?_, ?_⟩
    · rw [norm_indicatorConstLp (by norm_num) (by norm_num), hμr]
      have hs : 0 < Real.sqrt δ := Real.sqrt_pos.mpr hδpos
      simp only [c, Complex.norm_real, Real.norm_eq_abs, abs_inv, abs_of_pos hs]
      rw [show (1 / (2 : ENNReal).toReal) = (1 / 2 : ℝ) by norm_num, ← Real.sqrt_eq_rpow]
      field_simp
    · have hb : ∀ᵐ t : ℝ ∂μ, ‖((t : ℂ) - l) * (indicatorConstLp 2 measurableSet_Ioo hμs' c) t‖
          ≤ δ * ‖(indicatorConstLp 2 measurableSet_Ioo hμs' c) t‖ := by
        filter_upwards [indicatorConstLp_coeFn (p := 2) (hs := measurableSet_Ioo) (hμs := hμs')
          (c := c)] with t ht
        rw [ht, norm_mul]
        by_cases hts : t ∈ Set.Ioo a (a + δ)
        · gcongr
          rw [← Complex.ofReal_sub, Complex.norm_real, Real.norm_eq_abs, abs_le]
          constructor <;> linarith [hts.1, hts.2]
        · simp [hts]
      refine lt_of_le_of_lt (eLpNorm_le_mul_eLpNorm_of_ae_le_mul
        (((Complex.continuous_ofReal.sub continuous_const).aestronglyMeasurable).mul
          (Lp.aestronglyMeasurable _)) hb 2) ?_
      rw [← Lp.enorm_def, ← ofReal_norm]
      rw [norm_indicatorConstLp (by norm_num) (by norm_num), hμr]
      have hs : 0 < Real.sqrt δ := Real.sqrt_pos.mpr hδpos
      simp only [c, Complex.norm_real, Real.norm_eq_abs, abs_inv, abs_of_pos hs]
      rw [show (1 / (2 : ENNReal).toReal) = (1 / 2 : ℝ) by norm_num, ← Real.sqrt_eq_rpow,
        inv_mul_cancel₀ hs.ne', ENNReal.ofReal_one, mul_one]
      exact (ENNReal.ofReal_lt_ofReal_iff hε).mpr hδε

-- The fade's average gain on the steady note: ∫₀¹ t dt = 1/2.
example : ∫ t in (0 : ℝ)..1, t = 1 / 2 := by norm_num [integral_id]

-- The fade's output energy on the steady note: ∫₀¹ t² dt = 1/3.
example : ∫ t in (0 : ℝ)..1, t ^ 2 = 1 / 3 := by norm_num [integral_pow]

-- The same energy on 10 midpoint samples is 0.3325, short of 1/3 by exactly 1/(12·10²).
example : ∑ k ∈ Finset.range 10, (((k : ℚ) + 1 / 2) / 10) ^ 2 / 10 = 133 / 400 := by
  norm_num [Finset.sum_range_succ]
example : (1 : ℚ) / 3 - 133 / 400 = 1 / (12 * 10 ^ 2) := by norm_num

-- Energy after one blur on the click: (1 + 4 + 1)/16 = C(4, 2)/4² = 3/8.
example : ((1 + 4 + 1 : ℚ)) / 16 = 3 / 8 := by norm_num
example : (Nat.choose 4 2 : ℚ) / 4 ^ 2 = 3 / 8 := by norm_num [Nat.choose]

-- ⟨click, B¹⁰ click⟩ = C(20, 10)/4¹⁰ = 46189/262144 ≈ 0.176197.
example : (Nat.choose 20 10 : ℚ) / 4 ^ 10 = 46189 / 262144 := by
  rw [show Nat.choose 20 10 = 184756 by decide]; norm_num

#print axioms bounded_self_adjoint_is_multiplication_by_real_function
#print axioms function_of_operator_is_function_of_multiplier
#print axioms fade_has_no_eigenvectors_but_spectrum_zero_one
