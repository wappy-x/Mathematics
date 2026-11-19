-- Closed and exact forms: every exact form is closed, a closed form of degree at least one on a star-shaped open region is exact, and the angle form round a hole is closed but not exact.
import Mathlib.Analysis.Calculus.DifferentialForm.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Star
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral

open Set

open ContinuousAlternatingMap in
theorem poincare_alternatize_flip {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {k : ℕ}
    (C : (E [⋀^Fin (k + 1)]→L[ℝ] ℝ) →L[ℝ] (E →L[ℝ] E [⋀^Fin k]→L[ℝ] ℝ))
    (hC : ∀ f, C f = f.curryLeft)
    (L : E →L[ℝ] E [⋀^Fin (k + 1)]→L[ℝ] ℝ) (u : E)
    (hL : alternatizeUncurryFin L = 0) :
    alternatizeUncurryFin (C.flip u ∘L L) = L u := by
  ext v
  have h0 : alternatizeUncurryFin L (Matrix.vecCons u v) = 0 := by rw [hL]; rfl
  simp only [alternatizeUncurryFin_apply] at h0 ⊢
  rw [Fin.sum_univ_succ] at h0
  have hr : ∀ i : Fin (k + 1), Fin.removeNth i.succ (Matrix.vecCons u v) =
      Matrix.vecCons u (Fin.removeNth i v) := by
    intro i; ext j; refine Fin.cases ?_ (fun j => ?_) j <;> simp [Fin.removeNth_apply]
  simp [hr, pow_succ] at h0
  simp [hC]
  linarith

open Metric in
open scoped Interval in
theorem poincare_hasFDerivAt_integral {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] {k : ℕ} {U : Set E} {c : E} (hU : IsOpen U)
    (hseg : ∀ x ∈ U, ∀ t ∈ Icc (0:ℝ) 1, c + t • (x - c) ∈ U)
    (ω : E → E [⋀^Fin (k + 1)]→L[ℝ] ℝ) (hω : ContDiffOn ℝ 1 ω U)
    (C : (E [⋀^Fin (k + 1)]→L[ℝ] ℝ) →L[ℝ] (E →L[ℝ] E [⋀^Fin k]→L[ℝ] ℝ))
    {x₀ : E} (hx₀ : x₀ ∈ U) :
    ContinuousOn (fun t : ℝ => (t ^ k) • (C (ω (c + t • (x₀ - c))) +
          t • (C.flip (x₀ - c) ∘L fderiv ℝ ω (c + t • (x₀ - c))))) (Icc 0 1) ∧
    HasFDerivAt (fun x => ∫ t in (0:ℝ)..1, (t ^ k) • C (ω (c + t • (x - c))) (x - c))
      (∫ t in (0:ℝ)..1, (t ^ k) • (C (ω (c + t • (x₀ - c))) +
          t • (C.flip (x₀ - c) ∘L fderiv ℝ ω (c + t • (x₀ - c))))) x₀ := by
  let _ : NormedAddCommGroup (E →L[ℝ] E [⋀^Fin k]→L[ℝ] ℝ) := inferInstance
  have hωc : ContinuousOn ω U := hω.continuousOn
  have hDc : ContinuousOn (fderiv ℝ ω) U := hω.continuousOn_fderiv_of_isOpen hU le_rfl
  have hωd : ∀ z ∈ U, HasFDerivAt ω (fderiv ℝ ω z) z := fun z hz =>
    ((hω.differentiableOn one_ne_zero).differentiableAt (hU.mem_nhds hz)).hasFDerivAt
  have hgc : Continuous (fun p : E × ℝ => c + p.2 • (p.1 - c)) := by fun_prop
  have hK : IsCompact ((fun t : ℝ => c + t • (x₀ - c)) '' Icc 0 1) :=
    isCompact_Icc.image (by fun_prop)
  have hKU : (fun t : ℝ => c + t • (x₀ - c)) '' Icc 0 1 ⊆ U := by
    rintro _ ⟨t, ht, rfl⟩; exact hseg x₀ hx₀ t ht
  obtain ⟨δ, δpos, hδ⟩ := hK.exists_cthickening_subset_open hU hKU
  have hyU : ∀ p ∈ closedBall x₀ δ ×ˢ Icc (0:ℝ) 1, c + p.2 • (p.1 - c) ∈ U := by
    rintro ⟨x, t⟩ ⟨hx, ht⟩
    apply hδ
    refine Metric.mem_cthickening_of_dist_le _ (c + t • (x₀ - c)) δ
      ((fun t : ℝ => c + t • (x₀ - c)) '' Icc 0 1) (mem_image_of_mem _ ht) ?_
    rw [dist_eq_norm]
    have : c + t • (x - c) - (c + t • (x₀ - c)) = t • (x - x₀) := by
      simp only [smul_sub]; abel
    rw [this, norm_smul, Real.norm_eq_abs, abs_of_nonneg ht.1, ← dist_eq_norm]
    have := mem_closedBall.1 hx
    calc t * dist x x₀ ≤ 1 * δ := mul_le_mul ht.2 this dist_nonneg zero_le_one
      _ = δ := one_mul δ
  set S := closedBall x₀ δ ×ˢ Icc (0:ℝ) 1 with hS
  have hSc : IsCompact S := (isCompact_closedBall x₀ δ).prod isCompact_Icc
  have hmaps : MapsTo (fun p : E × ℝ => c + p.2 • (p.1 - c)) S U := hyU
  have hω' : ContinuousOn (fun p : E × ℝ => ω (c + p.2 • (p.1 - c))) S :=
    hωc.comp hgc.continuousOn hmaps
  have hD' : ContinuousOn (fun p : E × ℝ => fderiv ℝ ω (c + p.2 • (p.1 - c))) S :=
    hDc.comp hgc.continuousOn hmaps
  have hF'c : ContinuousOn (fun p : E × ℝ => (p.2 ^ k) • (C (ω (c + p.2 • (p.1 - c))) +
          p.2 • (C.flip (p.1 - c) ∘L fderiv ℝ ω (c + p.2 • (p.1 - c))))) S := by
    apply ContinuousOn.fun_smul (by fun_prop)
    apply ContinuousOn.add (C.continuous.comp_continuousOn hω')
    apply ContinuousOn.fun_smul (by fun_prop)
    have h1 : ContinuousOn (fun p : E × ℝ => C.flip (p.1 - c)) S :=
      (C.flip.continuous.comp (by fun_prop : Continuous fun p : E × ℝ => p.1 - c)).continuousOn
    exact h1.clm_comp hD'
  have hFc : ContinuousOn
      (fun p : E × ℝ => (p.2 ^ k) • C (ω (c + p.2 • (p.1 - c))) (p.1 - c)) S := by
    apply ContinuousOn.fun_smul (by fun_prop)
    exact (C.continuous.comp_continuousOn hω').clm_apply (by fun_prop)
  obtain ⟨B, hB⟩ := IsCompact.exists_bound_of_continuousOn
    (E := E →L[ℝ] E [⋀^Fin k]→L[ℝ] ℝ) hSc hF'c
  have hIoc : Ι (0:ℝ) 1 ⊆ Icc 0 1 := by
    intro t ht; rw [uIoc_of_le zero_le_one] at ht; exact ⟨ht.1.le, ht.2⟩
  have hFx : ∀ x ∈ closedBall x₀ δ, ContinuousOn
      (fun t : ℝ => (t ^ k) • C (ω (c + t • (x - c))) (x - c)) (Icc 0 1) :=
    fun x hx => hFc.comp (Continuous.continuousOn (by fun_prop : Continuous fun t : ℝ => (x, t)))
      (fun t ht => ⟨hx, ht⟩)
  have hF'x : ∀ x ∈ closedBall x₀ δ, ContinuousOn
      (fun t : ℝ => (t ^ k) • (C (ω (c + t • (x - c))) +
          t • (C.flip (x - c) ∘L fderiv ℝ ω (c + t • (x - c))))) (Icc 0 1) :=
    fun x hx => hF'c.comp (Continuous.continuousOn (by fun_prop : Continuous fun t : ℝ => (x, t)))
      (fun t ht => ⟨hx, ht⟩)
  have hx₀b : x₀ ∈ closedBall x₀ δ := mem_closedBall_self δpos.le
  refine ⟨hF'x x₀ hx₀b, ?_⟩
  refine intervalIntegral.hasFDerivAt_integral_of_dominated_of_fderiv_le (𝕜 := ℝ) (bound := fun _ => B)
    (F := fun x t => (t ^ k) • C (ω (c + t • (x - c))) (x - c))
    (F' := fun x t => (t ^ k) • (C (ω (c + t • (x - c))) +
          t • (C.flip (x - c) ∘L fderiv ℝ ω (c + t • (x - c)))))
    (ball_mem_nhds x₀ δpos) ?_ ?_ ?_ ?_ ?_ ?_
  · filter_upwards [ball_mem_nhds x₀ δpos] with x hx
    exact ((hFx x (ball_subset_closedBall hx)).mono hIoc).aestronglyMeasurable measurableSet_uIoc
  · exact (hFx x₀ hx₀b).intervalIntegrable_of_Icc zero_le_one
  · exact ((hF'x x₀ hx₀b).mono hIoc).aestronglyMeasurable measurableSet_uIoc
  · refine Filter.Eventually.of_forall (fun t ht x hx => ?_)
    exact hB (x, t) ⟨ball_subset_closedBall hx, hIoc ht⟩
  · exact intervalIntegrable_const
  · refine Filter.Eventually.of_forall (fun t ht x hx => ?_)
    have hyx : c + t • (x - c) ∈ U := hyU (x, t) ⟨ball_subset_closedBall hx, hIoc ht⟩
    have h1 : HasFDerivAt (fun x : E => c + t • (x - c)) (t • ContinuousLinearMap.id ℝ E) x :=
      (((hasFDerivAt_id x).sub_const c).const_smul t).const_add c
    have h2 := ((C.hasFDerivAt.comp x ((hωd _ hyx).comp x h1)).clm_apply
      ((hasFDerivAt_id x).sub_const c)).const_smul (t ^ k)
    convert h2 using 1
    all_goals try rfl
    ext h v
    simp

#print axioms poincare_alternatize_flip
#print axioms poincare_hasFDerivAt_integral

/-- The Poincaré lemma: on an open region of `ℝ^m` that is star-shaped about a centre `c`,
a differential form of degree `k + 1 ≥ 1` with continuous partial rates whose exterior
derivative is zero (a closed form) is the exterior derivative of some `k`-form `α`
(an exact form): a potential exists. -/
theorem closed_form_on_star_shaped_region_is_exact {m k : ℕ}
    {U : Set (EuclideanSpace ℝ (Fin m))} {c : EuclideanSpace ℝ (Fin m)}
    (hU : IsOpen U) (hstar : StarConvex ℝ c U)
    (ω : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin m) [⋀^Fin (k + 1)]→L[ℝ] ℝ)
    (hω : ContDiffOn ℝ 1 ω U) (hclosed : ∀ x ∈ U, extDeriv ω x = 0) :
    ∃ α : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin m) [⋀^Fin k]→L[ℝ] ℝ,
      DifferentiableOn ℝ α U ∧ ∀ x ∈ U, extDeriv α x = ω x := by
  set C := (ContinuousAlternatingMap.curryLeftLI (𝕜 := ℝ) (E := EuclideanSpace ℝ (Fin m))
    (F := ℝ) (n := k)).toContinuousLinearMap with hCdef
  have hC : ∀ f, C f = f.curryLeft := fun f => rfl
  have hseg : ∀ x ∈ U, ∀ t ∈ Icc (0:ℝ) 1, c + t • (x - c) ∈ U :=
    fun x hx t ht => hstar.add_smul_sub_mem hx ht.1 ht.2
  refine ⟨fun x => ∫ t in (0:ℝ)..1, (t ^ k) • C (ω (c + t • (x - c))) (x - c), ?_, ?_⟩
  · intro x hx
    exact (poincare_hasFDerivAt_integral hU hseg ω hω C hx).2.differentiableAt.differentiableWithinAt
  · intro x hx
    obtain ⟨hcont, hd⟩ := poincare_hasFDerivAt_integral hU hseg ω hω C hx
    have hint := ContinuousOn.intervalIntegrable_of_Icc (μ := MeasureTheory.volume)
      (E := EuclideanSpace ℝ (Fin m) →L[ℝ] EuclideanSpace ℝ (Fin m) [⋀^Fin k]→L[ℝ] ℝ) zero_le_one hcont
    unfold extDeriv
    rw [hd.fderiv, ← ContinuousAlternatingMap.alternatizeUncurryFinCLM_apply]
    have hcomm := ContinuousLinearMap.intervalIntegral_comp_comm (𝕜 := ℝ)
      (E := EuclideanSpace ℝ (Fin m) →L[ℝ] EuclideanSpace ℝ (Fin m) [⋀^Fin k]→L[ℝ] ℝ)
      (F := EuclideanSpace ℝ (Fin m) [⋀^Fin (k + 1)]→L[ℝ] ℝ)
      (ContinuousAlternatingMap.alternatizeUncurryFinCLM ℝ (EuclideanSpace ℝ (Fin m)) ℝ (n := k))
      hint
    refine hcomm.symm.trans ?_
    simp only [ContinuousAlternatingMap.alternatizeUncurryFinCLM_apply]
    have hyU : ∀ t ∈ uIcc (0:ℝ) 1, c + t • (x - c) ∈ U := fun t ht =>
      hseg x hx t (by rwa [uIcc_of_le zero_le_one] at ht)
    have hωd : ∀ z ∈ U, HasFDerivAt ω (fderiv ℝ ω z) z := fun z hz =>
      ((hω.differentiableOn one_ne_zero).differentiableAt (hU.mem_nhds hz)).hasFDerivAt
    have key : ∀ t ∈ uIcc (0:ℝ) 1, ContinuousAlternatingMap.alternatizeUncurryFin
        ((t ^ k) • (C (ω (c + t • (x - c))) +
          t • (C.flip (x - c) ∘L fderiv ℝ ω (c + t • (x - c))))) =
        (t ^ (k + 1)) • fderiv ℝ ω (c + t • (x - c)) (x - c) +
          ((↑(k + 1) : ℝ) * t ^ (k + 1 - 1)) • ω (c + t • (x - c)) := by
      intro t ht
      have hcl : ContinuousAlternatingMap.alternatizeUncurryFin
          (fderiv ℝ ω (c + t • (x - c))) = 0 := hclosed _ (hyU t ht)
      have h1 := poincare_alternatize_flip C hC (fderiv ℝ ω (c + t • (x - c))) (x - c) hcl
      simp only [ContinuousAlternatingMap.alternatizeUncurryFin_smul,
        ContinuousAlternatingMap.alternatizeUncurryFin_add, h1, hC,
        ContinuousAlternatingMap.alternatizeUncurryFin_curryLeft]
      ext v
      simp
      ring
    rw [intervalIntegral.integral_congr key]
    have hderiv : ∀ t ∈ uIcc (0:ℝ) 1,
        HasDerivAt (fun t : ℝ => (t ^ (k + 1)) • ω (c + t • (x - c)))
        ((t ^ (k + 1)) • fderiv ℝ ω (c + t • (x - c)) (x - c) +
          ((↑(k + 1) : ℝ) * t ^ (k + 1 - 1)) • ω (c + t • (x - c))) t := by
      intro t ht
      have hl : HasDerivAt (fun t : ℝ => c + t • (x - c)) (x - c) t := by
        simpa using ((hasDerivAt_id t).smul_const (x - c)).const_add c
      exact (hasDerivAt_pow (k + 1) t).smul ((hωd _ (hyU t ht)).comp_hasDerivAt t hl)
    have hcont2 : ContinuousOn (fun t : ℝ => (t ^ (k + 1)) • fderiv ℝ ω (c + t • (x - c)) (x - c) +
        ((↑(k + 1) : ℝ) * t ^ (k + 1 - 1)) • ω (c + t • (x - c))) (uIcc 0 1) := by
      have hDc : ContinuousOn (fderiv ℝ ω) U := hω.continuousOn_fderiv_of_isOpen hU le_rfl
      have hl : ContinuousOn (fun t : ℝ => c + t • (x - c)) (uIcc 0 1) := by fun_prop
      have hm : MapsTo (fun t : ℝ => c + t • (x - c)) (uIcc 0 1) U := hyU
      apply ContinuousOn.add
      · exact (continuousOn_pow _).smul ((hDc.comp hl hm).clm_apply continuousOn_const)
      · exact (by fun_prop : ContinuousOn (fun t : ℝ => ((↑(k + 1) : ℝ) * t ^ (k + 1 - 1))) _).smul
          (hω.continuousOn.comp hl hm)
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hcont2.intervalIntegrable]
    simp

/-- Every exact form is closed: if `ω = dα` on an open region, where the potential `α` has
continuous second partial rates, then `dω = 0` there, because `d(dα) = 0`. -/
theorem exact_form_is_closed {m k : ℕ} {U : Set (EuclideanSpace ℝ (Fin m))} (hU : IsOpen U)
    (α : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin m) [⋀^Fin k]→L[ℝ] ℝ)
    (hα : ContDiffOn ℝ 2 α U)
    (ω : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin m) [⋀^Fin (k + 1)]→L[ℝ] ℝ)
    (hexact : ∀ x ∈ U, ω x = extDeriv α x) :
    ∀ x ∈ U, extDeriv ω x = 0 := by
  intro x hx
  have h1 : ω =ᶠ[nhds x] extDeriv α :=
    Filter.eventually_of_mem (hU.mem_nhds hx) hexact
  rw [h1.extDeriv_eq]
  exact extDeriv_extDeriv_apply (hα.contDiffAt (hU.mem_nhds hx)) (by simp)

/-- The angle form round a carousel's centre, `(-y dx + x dy) / (x² + y²)`, written as the
linear map it applies to a small step `(dx, dy)` at the point `p = (x, y)`. -/
noncomputable def angleForm (p : ℝ × ℝ) : ℝ × ℝ →L[ℝ] ℝ :=
  (p.1 ^ 2 + p.2 ^ 2)⁻¹ •
    (p.1 • ContinuousLinearMap.snd ℝ ℝ ℝ - p.2 • ContinuousLinearMap.fst ℝ ℝ ℝ)

/-- What a hole does: on the plane with its centre removed, the angle form is closed (its
cross rates agree: its derivative is symmetric at every point other than the centre), yet
it is not exact: no function on the punctured plane has it as its derivative. -/
theorem angle_form_closed_but_not_exact :
    (∀ p : ℝ × ℝ, p ≠ 0 → ∀ u v : ℝ × ℝ, fderiv ℝ angleForm p u v = fderiv ℝ angleForm p v u) ∧
    ¬ ∃ f : ℝ × ℝ → ℝ, ∀ p : ℝ × ℝ, p ≠ 0 → HasFDerivAt f (angleForm p) p := by
  constructor
  · intro p hp u v
    have hN : p.1 ^ 2 + p.2 ^ 2 ≠ 0 := by
      intro h
      apply hp
      have h1 : p.1 = 0 := by nlinarith [sq_nonneg p.1, sq_nonneg p.2]
      have h2 : p.2 = 0 := by nlinarith [sq_nonneg p.1, sq_nonneg p.2]
      exact Prod.ext h1 h2
    have hNd : HasFDerivAt (fun q : ℝ × ℝ => q.1 ^ 2 + q.2 ^ 2)
        ((2 * p.1) • ContinuousLinearMap.fst ℝ ℝ ℝ + (2 * p.2) • ContinuousLinearMap.snd ℝ ℝ ℝ) p := by
      have h1 : HasFDerivAt (fun q : ℝ × ℝ => q.1 ^ 2) _ p := (hasFDerivAt_fst (𝕜 := ℝ) (E := ℝ) (F := ℝ) (p := p)).pow 2
      have h2 : HasFDerivAt (fun q : ℝ × ℝ => q.2 ^ 2) _ p := (hasFDerivAt_snd (𝕜 := ℝ) (E := ℝ) (F := ℝ) (p := p)).pow 2
      convert h1.add h2 using 1
      ext <;> simp
    have hL : HasFDerivAt (fun q : ℝ × ℝ => q.1 • ContinuousLinearMap.snd ℝ ℝ ℝ - q.2 • ContinuousLinearMap.fst ℝ ℝ ℝ)
        ((ContinuousLinearMap.fst ℝ ℝ ℝ).smulRight (ContinuousLinearMap.snd ℝ ℝ ℝ) -
          (ContinuousLinearMap.snd ℝ ℝ ℝ).smulRight (ContinuousLinearMap.fst ℝ ℝ ℝ)) p :=
      by
        have h1 : HasFDerivAt (fun q : ℝ × ℝ => q.1 • ContinuousLinearMap.snd ℝ ℝ ℝ) _ p :=
          (hasFDerivAt_fst (𝕜 := ℝ) (E := ℝ) (F := ℝ) (p := p)).smul_const (ContinuousLinearMap.snd ℝ ℝ ℝ)
        have h2 : HasFDerivAt (fun q : ℝ × ℝ => q.2 • ContinuousLinearMap.fst ℝ ℝ ℝ) _ p :=
          (hasFDerivAt_snd (𝕜 := ℝ) (E := ℝ) (F := ℝ) (p := p)).smul_const (ContinuousLinearMap.fst ℝ ℝ ℝ)
        exact h1.sub h2
    have h := ((hasFDerivAt_inv hN).comp p hNd).smul hL
    have hA : HasFDerivAt angleForm _ p := h
    rw [hA.fderiv]
    simp
    field_simp
    ring
  · rintro ⟨f, hf⟩
    have hγ : ∀ t : ℝ, HasDerivAt (fun t => f (Real.cos t, Real.sin t)) 1 t := by
      intro t
      have hne : (Real.cos t, Real.sin t) ≠ 0 := by
        intro h
        have h1 := congrArg Prod.fst h
        have h2 := congrArg Prod.snd h
        simp at h1 h2
        have := Real.cos_sq_add_sin_sq t
        rw [h1, h2] at this; norm_num at this
      have hd := (hf _ hne).comp_hasDerivAt t ((Real.hasDerivAt_cos t).prodMk (Real.hasDerivAt_sin t))
      have h1 : angleForm (Real.cos t, Real.sin t) (-Real.sin t, Real.cos t) = 1 := by
        have := Real.cos_sq_add_sin_sq t
        simp [angleForm, this]
        nlinarith [this]
      rw [h1] at hd
      exact hd
    have hg : ∀ t : ℝ, HasDerivAt (fun t => f (Real.cos t, Real.sin t) - t) 0 t := by
      intro t
      have := (hγ t).sub (hasDerivAt_id' t)
      simp only [sub_self] at this
      exact this
    have hconst := is_const_of_deriv_eq_zero (f := fun t => f (Real.cos t, Real.sin t) - t)
      (fun t => (hg t).differentiableAt) (fun t => (hg t).deriv) (2 * Real.pi) 0
    simp at hconst

-- The straight-line rule p_i = 1/3 + (x^i - x^(i+1))/300 round the lap: buy 100 Wind
-- (Wind price 1/3 + w/300, w from 0 to 100), buy 100 Rain (Rain price 1/3 + (r - 100)/300),
-- sell the Wind (price 1/3 + w/300, w from 100 to 0), sell the Rain (price 1/3 + r/300,
-- r from 100 to 0). The trader pays -100/3 dollars, that is she nets 100/3 = 33.33 dollars,
-- which is the defect 1/300 times the area 100 × 100.
example :
    (∫ w in (0 : ℝ)..100, (1 / 3 + w / 300)) + (∫ r in (0 : ℝ)..100, (1 / 3 + (r - 100) / 300))
      + (∫ w in (100 : ℝ)..0, (1 / 3 + w / 300)) + (∫ r in (100 : ℝ)..0, (1 / 3 + r / 300))
      = -(1 / 300 * (100 * 100)) := by
  norm_num [intervalIntegral.integral_comp_div, integral_id, intervalIntegral.integral_add,
    intervalIntegral.integral_sub, intervalIntegral.integral_div,
    intervalIntegral.integral_comp_sub_right (fun r : ℝ => 1 / 3 + r / 300)]

-- The ray weight in degree two: β at t·x is t·β at x, and with the weight t the ray integral
-- is the integral of t² from 0 to 1, which is 1/3.
example : ∫ t in (0 : ℝ)..1, t ^ 2 = 1 / 3 := by
  norm_num [integral_pow]

-- The mistake of dropping the weight: the integral of t is 1/2, so the gate's circulation
-- comes out 3/2 times too big (1.5 instead of 1).
example : (∫ t in (0 : ℝ)..1, t) / (∫ t in (0 : ℝ)..1, t ^ 2) = 3 / 2 := by
  norm_num [integral_pow, integral_id]

-- The wind v = (x, y, -2z): its divergence 1 + 1 - 2 is zero, and the potential
-- α = (1/3)(v × position) has parts (yz, -xz, 0).
example (x y z : ℝ) :
    (1 / 3 : ℝ) • crossProduct ![x, y, -2 * z] ![x, y, z] = ![y * z, -(x * z), 0] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> ring

-- At (1, 1, 1/2) km the wind is (1, 1, -1) m/s and α has parts (1/2, -1/2, 0).
example : (1 / 3 : ℚ) • crossProduct ![(1 : ℚ), 1, -1] ![1, 1, 1 / 2] = ![1 / 2, -1 / 2, 0] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num

#print axioms closed_form_on_star_shaped_region_is_exact
#print axioms exact_form_is_closed
#print axioms angle_form_closed_but_not_exact
