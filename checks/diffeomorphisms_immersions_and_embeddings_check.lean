-- Diffeomorphism, immersion, submersion: in charts, a smooth map whose differential keeps all source directions straightens to "add zeros", one that reaches all target directions straightens to "forget the last coordinates", and one that does both is reversible nearby with a smooth undo.
import Mathlib.Geometry.Manifold.LocalDiffeomorph
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.ContDiff

open scoped ContDiff Manifold Topology

/-- Inverse function theorem packaged as a `PartialDiffeomorph` whose forward map is `g`. -/
theorem exists_partialDiffeomorph_of_hasFDerivAt_injective
    {E F : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    [NormedAddCommGroup F] [NormedSpace ℝ F] [FiniteDimensional ℝ F]
    (g : E → F) (a : E) (hg : ContDiff ℝ ∞ g) (D : E →L[ℝ] F) (hD : HasFDerivAt g D a)
    (hinj : Function.Injective D) (hdim : Module.finrank ℝ E = Module.finrank ℝ F) :
    ∃ Φ : PartialDiffeomorph 𝓘(ℝ, E) 𝓘(ℝ, F) E F ∞, a ∈ Φ.source ∧ ∀ x, Φ x = g x := by
  have hsurj : Function.Surjective (D : E →ₗ[ℝ] F) :=
    (LinearMap.injective_iff_surjective_of_finrank_eq_finrank hdim).1 hinj
  let e : E ≃L[ℝ] F :=
    (LinearEquiv.ofBijective (D : E →ₗ[ℝ] F) ⟨hinj, hsurj⟩).toContinuousLinearEquiv
  have he : (e : E →L[ℝ] F) = D := by ext x; rfl
  have hd : HasFDerivAt g (e : E →L[ℝ] F) a := he ▸ hD
  have hga : ContDiffAt ℝ ∞ g a := hg.contDiffAt
  let h0 := hga.toOpenPartialHomeomorph g hd (by simp)
  let s : Set E := fderiv ℝ g ⁻¹' Set.range ((↑) : (E ≃L[ℝ] F) → E →L[ℝ] F)
  have hs : IsOpen s :=
    ContinuousLinearEquiv.isOpen.preimage (hg.continuous_fderiv (by simp))
  have has : a ∈ s := ⟨e, hd.fderiv.symm⟩
  let h := h0.restrOpen s hs
  have hcoe : (h : E → F) = g := rfl
  refine ⟨{ toPartialEquiv := h.toPartialEquiv
            open_source := h.open_source
            open_target := h.open_target
            contMDiffOn_toFun := ?_
            contMDiffOn_invFun := ?_ }, ?_, fun x => rfl⟩
  · rw [contMDiffOn_iff_contDiffOn]
    exact hg.contDiffOn
  · rw [contMDiffOn_iff_contDiffOn]
    intro y hy
    have hy' : h.symm y ∈ h.source := h.map_target hy
    have hys : h.symm y ∈ s := by
      have := hy'
      rw [OpenPartialHomeomorph.restrOpen_source] at this
      exact this.2
    obtain ⟨e', he'⟩ := hys
    have hd' : HasFDerivAt h (e' : E →L[ℝ] F) (h.symm y) := by
      rw [hcoe, he']
      exact (hg.differentiable (by simp) _).hasFDerivAt
    exact (h.contDiffAt_symm hy hd' (hcoe ▸ (hg.contDiffAt : ContDiffAt ℝ ∞ g (h.symm y)))).contDiffWithinAt
  · show a ∈ h.source
    rw [OpenPartialHomeomorph.restrOpen_source]
    exact ⟨hga.mem_toOpenPartialHomeomorph_source hd (by simp), has⟩

#print axioms exists_partialDiffeomorph_of_hasFDerivAt_injective

/-- Reversible nearby: a smooth map from m-space to n-space whose differential at `p` has
rank `r` with `r = m` and `r = n` is a local diffeomorphism at `p`: near `p` it has a
smooth undo. -/
theorem full_rank_both_ways_is_local_diffeomorphism {m n : ℕ}
    (f : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin n)) (p : EuclideanSpace ℝ (Fin m))
    (hf : ContDiff ℝ ∞ f)
    (hm : Module.finrank ℝ (LinearMap.range (fderiv ℝ f p : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))) = m)
    (hn : Module.finrank ℝ (LinearMap.range (fderiv ℝ f p : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))) = n) :
    IsLocalDiffeomorphAt 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) ∞ f p := by
  have hD : HasFDerivAt f (fderiv ℝ f p) p := (hf.differentiable (by simp) p).hasFDerivAt
  have hinj : Function.Injective (fderiv ℝ f p) := by
    have h := LinearMap.finrank_range_add_finrank_ker
      (fderiv ℝ f p : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))
    rw [hm, finrank_euclideanSpace_fin] at h
    have hk : LinearMap.ker
        (fderiv ℝ f p : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n)) = ⊥ :=
      Submodule.finrank_eq_zero.1 (by omega)
    exact LinearMap.ker_eq_bot.1 hk
  have hdim : Module.finrank ℝ (EuclideanSpace ℝ (Fin m)) =
      Module.finrank ℝ (EuclideanSpace ℝ (Fin n)) := by
    rw [finrank_euclideanSpace_fin, finrank_euclideanSpace_fin, ← hm, hn]
  obtain ⟨Φ, ha, hΦ⟩ :=
    exists_partialDiffeomorph_of_hasFDerivAt_injective f p hf _ hD hinj hdim
  exact ⟨Φ, ha, fun x _ => (hΦ x).symm⟩

/-- Immersion, "add zeros": if a smooth map from m-space to n-space has differential of
rank `m` at `p`, then a smooth change of coordinates `Ψ` on the target, defined near `f p`
and smooth with a smooth undo, turns the map into `x ↦ (x, 0)` near `p`. -/
theorem immersion_local_form_add_zeros {m n : ℕ}
    (f : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin n)) (p : EuclideanSpace ℝ (Fin m))
    (hf : ContDiff ℝ ∞ f)
    (hr : Module.finrank ℝ (LinearMap.range (fderiv ℝ f p : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))) = m) :
    ∃ Ψ : PartialDiffeomorph 𝓘(ℝ, EuclideanSpace ℝ (Fin n))
        𝓘(ℝ, EuclideanSpace ℝ (Fin m) × EuclideanSpace ℝ (Fin (n - m)))
        (EuclideanSpace ℝ (Fin n)) (EuclideanSpace ℝ (Fin m) × EuclideanSpace ℝ (Fin (n - m))) ∞,
      ∀ᶠ x in 𝓝 p, f x ∈ Ψ.source ∧ Ψ (f x) = (x, 0) := by
  set D := fderiv ℝ f p with hDdef
  have hD : HasFDerivAt f D p := (hf.differentiable (by simp) p).hasFDerivAt
  have hinj : Function.Injective D := by
    have h := LinearMap.finrank_range_add_finrank_ker
      (D : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))
    rw [hr, finrank_euclideanSpace_fin] at h
    have hk : LinearMap.ker
        (D : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n)) = ⊥ :=
      Submodule.finrank_eq_zero.1 (by omega)
    exact LinearMap.ker_eq_bot.1 hk
  set W := LinearMap.range (D : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))
    with hW
  have hmn : m ≤ n := by
    have := Submodule.finrank_le W
    rw [hr, finrank_euclideanSpace_fin] at this
    exact this
  obtain ⟨C, hC⟩ := W.exists_isCompl
  have hCdim : Module.finrank ℝ C = n - m := by
    have := Submodule.finrank_add_eq_of_isCompl hC
    rw [hr, finrank_euclideanSpace_fin] at this
    omega
  let j : EuclideanSpace ℝ (Fin (n - m)) ≃ₗ[ℝ] C :=
    LinearEquiv.ofFinrankEq _ _ (by rw [hCdim, finrank_euclideanSpace_fin])
  let J : EuclideanSpace ℝ (Fin (n - m)) →L[ℝ] EuclideanSpace ℝ (Fin n) :=
    LinearMap.toContinuousLinearMap (C.subtype ∘ₗ j.toLinearMap)
  let G : EuclideanSpace ℝ (Fin m) × EuclideanSpace ℝ (Fin (n - m)) →
      EuclideanSpace ℝ (Fin n) := fun q => f q.1 + J q.2
  have hG : ContDiff ℝ ∞ G := (hf.comp contDiff_fst).add (J.contDiff.comp contDiff_snd)
  let DG : (EuclideanSpace ℝ (Fin m) × EuclideanSpace ℝ (Fin (n - m))) →L[ℝ]
      EuclideanSpace ℝ (Fin n) :=
    D.comp (ContinuousLinearMap.fst ℝ _ _) + J.comp (ContinuousLinearMap.snd ℝ _ _)
  have hDG : HasFDerivAt G DG (p, 0) :=
    (hD.comp (p, 0) hasFDerivAt_fst).add (J.hasFDerivAt.comp (p, 0) hasFDerivAt_snd)
  have hDGinj : Function.Injective DG := by
    rw [injective_iff_map_eq_zero]
    rintro ⟨x, z⟩ hxz
    have hsum : D x + J z = 0 := hxz
    have hJz : J z ∈ C := (j z).2
    have hDx : D x ∈ W := ⟨x, rfl⟩
    have hDxC : D x ∈ C := by
      rw [eq_neg_of_add_eq_zero_left hsum]
      exact C.neg_mem hJz
    have hDx0 : D x = 0 := (Submodule.disjoint_def.1 hC.disjoint) _ hDx hDxC
    have hx0 : x = 0 := hinj (by rw [hDx0, map_zero])
    have hJz0 : J z = 0 := by rw [hDx0, zero_add] at hsum; exact hsum
    have hjz : j z = 0 := Subtype.ext hJz0
    have hz0 : z = 0 := by
      have := congrArg j.symm hjz
      simpa using this
    simp [hx0, hz0]
  have hdim : Module.finrank ℝ (EuclideanSpace ℝ (Fin m) × EuclideanSpace ℝ (Fin (n - m))) =
      Module.finrank ℝ (EuclideanSpace ℝ (Fin n)) := by
    rw [Module.finrank_prod, finrank_euclideanSpace_fin, finrank_euclideanSpace_fin,
      finrank_euclideanSpace_fin]
    omega
  obtain ⟨Φ, ha, hΦ⟩ :=
    exists_partialDiffeomorph_of_hasFDerivAt_injective G (p, 0) hG DG hDG hDGinj hdim
  refine ⟨Φ.symm, ?_⟩
  have hcont : Continuous (fun x : EuclideanSpace ℝ (Fin m) =>
      (x, (0 : EuclideanSpace ℝ (Fin (n - m))))) :=
    continuous_id.prodMk continuous_const
  have hmem : ∀ᶠ x in 𝓝 p, (x, (0 : EuclideanSpace ℝ (Fin (n - m)))) ∈ Φ.source :=
    hcont.continuousAt.preimage_mem_nhds (Φ.open_source.mem_nhds ha)
  filter_upwards [hmem] with x hx
  have hfx : f x = Φ (x, 0) := by rw [hΦ]; simp [G]
  rw [hfx]
  exact ⟨Φ.map_source hx, Φ.left_inv hx⟩

/-- Submersion, "forget the last coordinates": if a smooth map from m-space to n-space has
differential of rank `n` at `p`, then a smooth change of coordinates `Φ` on the source,
whose image contains `p` and which is smooth with a smooth undo, turns the map into
`(y, z) ↦ y`. -/
theorem submersion_local_form_forget_coordinates {m n : ℕ}
    (f : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin n)) (p : EuclideanSpace ℝ (Fin m))
    (hf : ContDiff ℝ ∞ f)
    (hr : Module.finrank ℝ (LinearMap.range (fderiv ℝ f p : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))) = n) :
    ∃ Φ : PartialDiffeomorph 𝓘(ℝ, EuclideanSpace ℝ (Fin n) × EuclideanSpace ℝ (Fin (m - n)))
        𝓘(ℝ, EuclideanSpace ℝ (Fin m))
        (EuclideanSpace ℝ (Fin n) × EuclideanSpace ℝ (Fin (m - n))) (EuclideanSpace ℝ (Fin m)) ∞,
      p ∈ Φ.target ∧ ∀ q ∈ Φ.source, f (Φ q) = q.1 := by
  set D := fderiv ℝ f p with hDdef
  have hD : HasFDerivAt f D p := (hf.differentiable (by simp) p).hasFDerivAt
  set K := LinearMap.ker (D : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))
    with hKdef
  have hrk := LinearMap.finrank_range_add_finrank_ker
    (D : EuclideanSpace ℝ (Fin m) →ₗ[ℝ] EuclideanSpace ℝ (Fin n))
  rw [hr, finrank_euclideanSpace_fin] at hrk
  have hK' : n + Module.finrank ℝ K = m := hrk
  have hKdim : Module.finrank ℝ K = m - n := by omega
  obtain ⟨P, hP⟩ := K.subtype.exists_leftInverse_of_injective K.ker_subtype
  let j : K ≃ₗ[ℝ] EuclideanSpace ℝ (Fin (m - n)) :=
    LinearEquiv.ofFinrankEq _ _ (by rw [hKdim, finrank_euclideanSpace_fin])
  let Q : EuclideanSpace ℝ (Fin m) →L[ℝ] EuclideanSpace ℝ (Fin (m - n)) :=
    LinearMap.toContinuousLinearMap (j.toLinearMap ∘ₗ P)
  let G : EuclideanSpace ℝ (Fin m) →
      EuclideanSpace ℝ (Fin n) × EuclideanSpace ℝ (Fin (m - n)) := fun x => (f x, Q x)
  have hG : ContDiff ℝ ∞ G := hf.prodMk Q.contDiff
  have hDG : HasFDerivAt G (D.prod Q) p := hD.prodMk Q.hasFDerivAt
  have hDGinj : Function.Injective (D.prod Q) := by
    rw [injective_iff_map_eq_zero]
    intro x hx
    have h1 : D x = 0 := congrArg Prod.fst hx
    have h2 : Q x = 0 := congrArg Prod.snd hx
    have hxK : x ∈ K := h1
    have hPx : P x = 0 := by
      have : j (P x) = 0 := h2
      simpa using congrArg j.symm this
    have hPx' : P x = ⟨x, hxK⟩ := by
      have := congrArg (fun L => L ⟨x, hxK⟩) hP
      simpa using this
    have : (⟨x, hxK⟩ : K) = 0 := hPx'.symm.trans hPx
    exact congrArg Subtype.val this
  have hdim : Module.finrank ℝ (EuclideanSpace ℝ (Fin m)) =
      Module.finrank ℝ (EuclideanSpace ℝ (Fin n) × EuclideanSpace ℝ (Fin (m - n))) := by
    rw [Module.finrank_prod, finrank_euclideanSpace_fin, finrank_euclideanSpace_fin,
      finrank_euclideanSpace_fin]
    omega
  obtain ⟨Φ, ha, hΦ⟩ :=
    exists_partialDiffeomorph_of_hasFDerivAt_injective G p hG (D.prod Q) hDG hDGinj hdim
  refine ⟨Φ.symm, ha, ?_⟩
  intro q hq
  have h := Φ.right_inv hq
  have h' : G (Φ.symm q) = q := by rw [← hΦ]; exact h
  exact congrArg Prod.fst h'

#print axioms full_rank_both_ways_is_local_diffeomorphism
#print axioms immersion_local_form_add_zeros
#print axioms submersion_local_form_forget_coordinates
