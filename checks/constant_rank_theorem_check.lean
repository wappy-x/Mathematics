-- Constant rank theorem: this file proves that a map with continuous partial derivatives whose Jacobian has the same rank r at every point near p becomes "keep the first r coordinates, write zeros for the rest" after a smooth renaming of its inputs and of its outputs.
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.ContDiff
import Mathlib.Analysis.Calculus.FDeriv.Pi
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.Isomorphisms
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.LinearAlgebra.Finsupp.VectorSpace
import Mathlib.Topology.Algebra.Module.FiniteDimension

open Filter Topology

/-- The projection form: from `m` numbers to `n` numbers, keep the first `r` coordinates and
write `0` for the other `n - r`. -/
def projectionForm (m n r : ℕ) (u : Fin m → ℝ) : Fin n → ℝ :=
  fun i => if h : (i : ℕ) < r ∧ (i : ℕ) < m then u ⟨i, h.2⟩ else 0

/-- `projectionForm` as a linear map. -/
def projectionFormL (m n r : ℕ) : (Fin m → ℝ) →ₗ[ℝ] (Fin n → ℝ) where
  toFun := projectionForm m n r
  map_add' u v := by
    funext i; simp only [projectionForm, Pi.add_apply]; split_ifs <;> simp
  map_smul' c u := by
    funext i; simp only [projectionForm, Pi.smul_apply, RingHom.id_apply]; split_ifs <;> simp

/-- Splitting `Fin b` as the first `a` places followed by the remaining `b - a`. -/
def splitFin (a b : ℕ) (h : a ≤ b) : Fin a ⊕ Fin (b - a) ≃ Fin b :=
  finSumFinEquiv.trans (finCongr (by omega))

theorem splitFin_inl (a b : ℕ) (h : a ≤ b) (i : Fin a) :
    ((splitFin a b h (Sum.inl i) : Fin b) : ℕ) = i := by
  simp [splitFin]

theorem splitFin_inr (a b : ℕ) (h : a ≤ b) (i : Fin (b - a)) :
    ((splitFin a b h (Sum.inr i) : Fin b) : ℕ) = a + i := by
  simp [splitFin]

/-- Linear normal form: a linear map of rank `r` becomes `projectionForm` after a linear change
of coordinates on each side. -/
theorem linear_normal_form {m n r : ℕ} (L : (Fin m → ℝ) →ₗ[ℝ] (Fin n → ℝ))
    (hL : Module.finrank ℝ (LinearMap.range L) = r) :
    ∃ (P : (Fin m → ℝ) ≃ₗ[ℝ] (Fin m → ℝ)) (Q : (Fin n → ℝ) ≃ₗ[ℝ] (Fin n → ℝ)),
      ∀ v, Q (L (P v)) = projectionForm m n r v := by
  obtain ⟨C, hC⟩ := (LinearMap.ker L).exists_isCompl
  obtain ⟨C', hC'⟩ := (LinearMap.range L).exists_isCompl
  let eC : C ≃ₗ[ℝ] LinearMap.range L :=
    ((LinearMap.ker L).quotientEquivOfIsCompl C hC).symm.trans L.quotKerEquivRange
  have heC : ∀ c : C, (eC c : Fin n → ℝ) = L c := fun c => rfl
  have hCr : Module.finrank ℝ C = r := eC.finrank_eq.trans hL
  have h1 := Submodule.finrank_add_eq_of_isCompl hC
  have h2 := Submodule.finrank_add_eq_of_isCompl hC'
  simp only [Module.finrank_fin_fun] at h1 h2
  have hrm : r ≤ m := by omega
  have hrn : r ≤ n := by omega
  have hK : Module.finrank ℝ (LinearMap.ker L) = m - r := by omega
  have hC'r : Module.finrank ℝ C' = n - r := by omega
  let bC := Module.finBasisOfFinrankEq ℝ C hCr
  let bK := Module.finBasisOfFinrankEq ℝ (LinearMap.ker L) hK
  let bR := bC.map eC
  let bC' := Module.finBasisOfFinrankEq ℝ C' hC'r
  let bE := ((bC.prod bK).map (Submodule.prodEquivOfIsCompl C _ hC.symm)).reindex
    (splitFin r m hrm)
  let bG := ((bR.prod bC').map (Submodule.prodEquivOfIsCompl _ C' hC')).reindex
    (splitFin r n hrn)
  refine ⟨bE.equivFun.symm, bG.equivFun, fun v => ?_⟩
  have key : bG.equivFun.toLinearMap ∘ₗ L ∘ₗ bE.equivFun.symm.toLinearMap =
      projectionFormL m n r := by
    refine (Pi.basisFun ℝ (Fin m)).ext fun j => ?_
    obtain ⟨s, rfl⟩ := (splitFin r m hrm).surjective j
    simp only [LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply, Pi.basisFun_apply,
      Basis.equivFun_symm_single]
    have hbE : bE (splitFin r m hrm s) =
        Submodule.prodEquivOfIsCompl C _ hC.symm ((bC.prod bK) s) := by
      simp [bE, Module.Basis.reindex_apply]
    rw [hbE]
    funext i
    rcases s with s | s
    · have hLs : L (Submodule.prodEquivOfIsCompl C _ hC.symm ((bC.prod bK) (Sum.inl s))) =
          bG (splitFin r n hrn (Sum.inl s)) := by
        simp [bG, bR, Module.Basis.reindex_apply, Submodule.coe_prodEquivOfIsCompl', heC]
      rw [hLs, Module.Basis.equivFun_self]
      simp only [projectionFormL, LinearMap.coe_mk, AddHom.coe_mk, projectionForm, Pi.single_apply]
      have a1 := splitFin_inl r m hrm s
      have a2 := splitFin_inl r n hrn s
      split_ifs <;> simp_all [Fin.ext_iff]
      omega
    · have hLs : L (Submodule.prodEquivOfIsCompl C _ hC.symm ((bC.prod bK) (Sum.inr s))) = 0 := by
        simp [Submodule.coe_prodEquivOfIsCompl']
      rw [hLs, map_zero]
      simp only [projectionFormL, LinearMap.coe_mk, AddHom.coe_mk, projectionForm, Pi.single_apply]
      have a1 := splitFin_inr r m hrm s
      split_ifs <;> simp_all [Fin.ext_iff]
      omega
  exact congrArg (fun f => f v) key

/-- Writing a vector's first `r` places into the first `r` places of the output, and the rest
from a second vector. -/
noncomputable def headMix (m n r : ℕ) (hrn : r ≤ n) :
    (Fin n → ℝ) × (Fin m → ℝ) →L[ℝ] (Fin m → ℝ) :=
  ContinuousLinearMap.pi fun i => if h : (i : ℕ) < r then
    (ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin n => ℝ)
      ⟨i, lt_of_lt_of_le h hrn⟩).comp (ContinuousLinearMap.fst ℝ _ _)
    else (ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin m => ℝ) i).comp
      (ContinuousLinearMap.snd ℝ _ _)

theorem headMix_apply {m n r : ℕ} (hrn : r ≤ n) (y : Fin n → ℝ) (z : Fin m → ℝ) (i : Fin m) :
    headMix m n r hrn (y, z) i = if h : (i : ℕ) < r then y ⟨i, lt_of_lt_of_le h hrn⟩ else z i := by
  simp only [headMix, ContinuousLinearMap.pi_apply]
  split_ifs <;> rfl

/-- Zero out the first `r` places. -/
def tailZero (n r : ℕ) (y : Fin n → ℝ) : Fin n → ℝ := fun i => if (i : ℕ) < r then 0 else y i

/-- Keep the first `r` places of `z` and fill the rest from `c`. -/
def headWith (m n r : ℕ) (hrn : r ≤ n) (c : Fin m → ℝ) (z : Fin n → ℝ) : Fin m → ℝ :=
  fun i => if h : (i : ℕ) < r then z ⟨i, lt_of_lt_of_le h hrn⟩ else c i

theorem contDiff_tailZero (n r : ℕ) : ContDiff ℝ 1 (tailZero n r) := by
  rw [contDiff_pi]; intro i
  by_cases h : (i : ℕ) < r
  · simp only [tailZero, h, ite_true]; exact contDiff_const
  · simp only [tailZero, h, ite_false]; exact contDiff_apply _ _ _

theorem contDiff_headWith {m n r : ℕ} (hrn : r ≤ n) (c : Fin m → ℝ) :
    ContDiff ℝ 1 (headWith m n r hrn c) := by
  rw [contDiff_pi]; intro i
  by_cases h : (i : ℕ) < r
  · simp only [headWith, h, dite_true]; exact contDiff_apply _ _ _
  · simp only [headWith, h, dite_false]; exact contDiff_const

theorem headWith_add_tailZero {m n r : ℕ} (hrn : r ≤ n) (c : Fin m → ℝ) (z y : Fin n → ℝ) :
    headWith m n r hrn c (z + tailZero n r y) = headWith m n r hrn c z := by
  funext i; simp only [headWith, tailZero, Pi.add_apply]; split_ifs <;> simp_all

theorem headWith_sub_tailZero {m n r : ℕ} (hrn : r ≤ n) (c : Fin m → ℝ) (z y : Fin n → ℝ) :
    headWith m n r hrn c (z - tailZero n r y) = headWith m n r hrn c z := by
  funext i; simp only [headWith, tailZero, Pi.sub_apply]; split_ifs <;> simp_all

/-- Changing coordinates by linear equivalences on both sides keeps the rank. -/
theorem finrank_range_comp_equiv {m n : ℕ} (T : (Fin m → ℝ) →L[ℝ] (Fin n → ℝ))
    (A : (Fin n → ℝ) ≃L[ℝ] (Fin n → ℝ)) (B : (Fin m → ℝ) ≃L[ℝ] (Fin m → ℝ)) :
    Module.finrank ℝ (LinearMap.range
      ((A : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ)).comp (T.comp (B : (Fin m → ℝ) →L[ℝ] _))).toLinearMap) =
      Module.finrank ℝ (LinearMap.range T.toLinearMap) := by
  have hB : LinearMap.range (B : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ)).toLinearMap = ⊤ :=
    LinearMap.range_eq_top.2 B.surjective
  change Module.finrank ℝ (LinearMap.range ((A.toLinearEquiv : (Fin n → ℝ) →ₗ[ℝ] (Fin n → ℝ)).comp
    (T.toLinearMap.comp (B : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ)).toLinearMap))) = _
  rw [LinearMap.range_comp, LinearMap.range_comp_of_range_eq_top _ hB]
  exact LinearEquiv.finrank_map_eq A.toLinearEquiv _

/-- If a rank-`r` map copies the first `r` input places to the first `r` output places, it sends
every vector with zeros in its first `r` places to zero. -/
theorem tail_kill {m n r : ℕ} (hrn : r ≤ n) (T : (Fin m → ℝ) →L[ℝ] (Fin n → ℝ))
    (hT : Module.finrank ℝ (LinearMap.range T.toLinearMap) = r)
    (hhead : ∀ (w : Fin m → ℝ) (i : Fin m) (hi : (i : ℕ) < r),
      T w ⟨i, lt_of_lt_of_le hi hrn⟩ = w i)
    (w : Fin m → ℝ) (hw : ∀ i : Fin m, (i : ℕ) < r → w i = 0) : T w = 0 := by
  have hrm : r ≤ m := by
    rw [← hT]; exact (LinearMap.finrank_range_le _).trans (by simp)
  let π : (Fin n → ℝ) →ₗ[ℝ] (Fin r → ℝ) :=
    LinearMap.funLeft ℝ ℝ (fun j : Fin r => (⟨j, lt_of_lt_of_le j.2 hrn⟩ : Fin n))
  let πR := π.domRestrict (LinearMap.range T.toLinearMap)
  have hπT : ∀ (v : Fin m → ℝ) (j : Fin r), π (T v) j = v ⟨j, lt_of_lt_of_le j.2 hrm⟩ := by
    intro v j
    exact hhead v ⟨j, lt_of_lt_of_le j.2 hrm⟩ j.2
  have hsurj : Function.Surjective πR := by
    intro z
    refine ⟨⟨T (fun i => if h : (i : ℕ) < r then z ⟨i, h⟩ else 0), LinearMap.mem_range_self _ _⟩, ?_⟩
    funext j
    simp only [πR, LinearMap.domRestrict_apply]
    rw [hπT]; simp
  have hinj : Function.Injective πR :=
    (LinearMap.injective_iff_surjective_of_finrank_eq_finrank (by simp [hT])).2 hsurj
  have h0 : πR ⟨T w, LinearMap.mem_range_self _ _⟩ = πR 0 := by
    funext j
    simp only [πR, LinearMap.domRestrict_apply, map_zero]
    rw [hπT]; exact hw _ j.2
  have := hinj h0
  simpa using congrArg Subtype.val this

/-- The constant rank theorem. Let `F` take `m` numbers to `n` numbers, with continuous partial
derivatives near `p`, and suppose its Jacobian has the same rank `r` at every point near `p`.
Then there are diffeomorphisms `φ` near `p` (on the inputs) and `ψ` near `F p` (on the outputs),
each continuously differentiable with a continuously differentiable undo, such that near `φ p`
the map `ψ ∘ F ∘ φ⁻¹` keeps the first `r` coordinates and writes zeros for the rest. -/
theorem constant_rank_theorem {m n r : ℕ} (F : (Fin m → ℝ) → (Fin n → ℝ)) (p : Fin m → ℝ)
    (hF : ContDiffAt ℝ 1 F p)
    (hrank : ∀ᶠ x in 𝓝 p, Module.finrank ℝ (LinearMap.range (fderiv ℝ F x).toLinearMap) = r) :
    ∃ (φ : OpenPartialHomeomorph (Fin m → ℝ) (Fin m → ℝ))
      (ψ : OpenPartialHomeomorph (Fin n → ℝ) (Fin n → ℝ)),
      p ∈ φ.source ∧ F p ∈ ψ.source ∧
      ContDiffOn ℝ 1 φ φ.source ∧ ContDiffOn ℝ 1 φ.symm φ.target ∧
      ContDiffOn ℝ 1 ψ ψ.source ∧ ContDiffOn ℝ 1 ψ.symm ψ.target ∧
      ∀ᶠ u in 𝓝 (φ p), F (φ.symm u) ∈ ψ.source ∧
        ψ (F (φ.symm u)) = projectionForm m n r u := by
  classical
  have hLr : Module.finrank ℝ (LinearMap.range (fderiv ℝ F p).toLinearMap) = r :=
    hrank.self_of_nhds
  have hrn : r ≤ n := by
    rw [← hLr]; exact (Submodule.finrank_le _).trans (by simp)
  have hrm : r ≤ m := by
    rw [← hLr]; exact (LinearMap.finrank_range_le _).trans (by simp)
  obtain ⟨P0, Q0, hPQ⟩ := linear_normal_form (fderiv ℝ F p).toLinearMap hLr
  set P := P0.toContinuousLinearEquiv with hP
  set Q := Q0.toContinuousLinearEquiv with hQ
  -- the input renaming: first `r` places from `Q ∘ F`, the rest from `P⁻¹`
  set φf : (Fin m → ℝ) → (Fin m → ℝ) := fun x => headMix m n r hrn (Q (F x), P.symm x) with hφf
  have hφC : ∀ x, ContDiffAt ℝ 1 F x → ContDiffAt ℝ 1 φf x := fun x hx =>
    (headMix m n r hrn).contDiff.contDiffAt.comp x
      ((Q.contDiff.contDiffAt.comp x hx).prodMk P.symm.contDiff.contDiffAt)
  have hφD : ∀ x, DifferentiableAt ℝ F x → HasFDerivAt φf ((headMix m n r hrn).comp
      (((Q : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ)).comp (fderiv ℝ F x)).prod
        (P.symm : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ)))) x := fun x hx =>
    (headMix m n r hrn).hasFDerivAt.comp x
      ((Q.hasFDerivAt.comp x hx.hasFDerivAt).prodMk P.symm.hasFDerivAt)
  have hD0 : (headMix m n r hrn).comp
      (((Q : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ)).comp (fderiv ℝ F p)).prod
        (P.symm : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ))) = (P.symm : (Fin m → ℝ) →L[ℝ] _) := by
    ext z i
    simp only [ContinuousLinearMap.comp_apply, ContinuousLinearMap.prod_apply, headMix_apply]
    split_ifs with h
    · have := congrFun (hPQ (P0.symm z)) ⟨i, lt_of_lt_of_le h hrn⟩
      simp only [LinearEquiv.apply_symm_apply, projectionForm, ContinuousLinearMap.coe_coe] at this
      simp only [h, i.isLt, and_self, ↓reduceDIte] at this
      exact this
    · rfl
  have hpd : HasFDerivAt φf ((P.symm : (Fin m → ℝ) ≃L[ℝ] _) : (Fin m → ℝ) →L[ℝ] _) p := by
    rw [← hD0]; exact hφD p (hF.differentiableAt (by norm_num))
  set Φ := (hφC p hF).toOpenPartialHomeomorph φf hpd one_ne_zero with hΦdef
  have hΦ : ∀ x, Φ x = φf x := fun x => rfl
  have hpΦ : p ∈ Φ.source := (hφC p hF).mem_toOpenPartialHomeomorph_source hpd one_ne_zero
  have hcontD : ContinuousAt (fderiv ℝ φf) p :=
    ((hφC p hF).fderiv_right (m := 0) (by norm_num)).continuousAt
  have hU : ∀ᶠ x in 𝓝 p, ContDiffAt ℝ 1 F x ∧
      (∃ D : (Fin m → ℝ) ≃L[ℝ] (Fin m → ℝ), (D : (Fin m → ℝ) →L[ℝ] _) = fderiv ℝ φf x) ∧
      Module.finrank ℝ (LinearMap.range (fderiv ℝ F x).toLinearMap) = r := by
    have h1 := hF.eventually (by simp)
    have h2 : ∀ᶠ x in 𝓝 p, fderiv ℝ φf x ∈
        Set.range ((↑) : ((Fin m → ℝ) ≃L[ℝ] (Fin m → ℝ)) → ((Fin m → ℝ) →L[ℝ] _)) :=
      hcontD.preimage_mem_nhds (by
        rw [hpd.fderiv]; exact ContinuousLinearEquiv.isOpen.mem_nhds ⟨_, rfl⟩)
    filter_upwards [h1, h2, hrank] with x hx1 hx2 hx3
    obtain ⟨D, hD⟩ := hx2
    exact ⟨hx1, ⟨D, hD⟩, hx3⟩
  set c := Φ p with hc
  have hcΦ : Φ.symm c = p := Φ.left_inv hpΦ
  have hnhds : Φ.target ∩ Φ.symm ⁻¹' {x | ContDiffAt ℝ 1 F x ∧
      (∃ D : (Fin m → ℝ) ≃L[ℝ] (Fin m → ℝ), (D : (Fin m → ℝ) →L[ℝ] _) = fderiv ℝ φf x) ∧
      Module.finrank ℝ (LinearMap.range (fderiv ℝ F x).toLinearMap) = r} ∈ 𝓝 c := by
    refine Filter.inter_mem (Φ.open_target.mem_nhds (Φ.map_source hpΦ)) ?_
    apply (Φ.continuousAt_symm (Φ.map_source hpΦ)).preimage_mem_nhds
    rw [hcΦ]; exact hU
  obtain ⟨ε, εpos, hball⟩ := Metric.mem_nhds_iff.1 hnhds
  have hD : ∀ u ∈ Metric.ball c ε, u ∈ Φ.target ∧ ContDiffAt ℝ 1 F (Φ.symm u) ∧
      (∃ D : (Fin m → ℝ) ≃L[ℝ] (Fin m → ℝ),
        (D : (Fin m → ℝ) →L[ℝ] _) = fderiv ℝ φf (Φ.symm u)) ∧
      Module.finrank ℝ (LinearMap.range (fderiv ℝ F (Φ.symm u)).toLinearMap) = r :=
    fun u hu => hball hu
  -- the derivative of the renaming at `Φ⁻¹ u`
  have hΦd : ∀ u ∈ Metric.ball c ε, ∃ Dx : (Fin m → ℝ) ≃L[ℝ] (Fin m → ℝ),
      HasFDerivAt Φ (Dx : (Fin m → ℝ) →L[ℝ] _) (Φ.symm u) ∧
      (Dx : (Fin m → ℝ) →L[ℝ] _) = (headMix m n r hrn).comp
        (((Q : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ)).comp (fderiv ℝ F (Φ.symm u))).prod
          (P.symm : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ))) := by
    intro u hu
    obtain ⟨-, hFx, ⟨Dx, hDx⟩, -⟩ := hD u hu
    have hdiff : DifferentiableAt ℝ F (Φ.symm u) := hFx.differentiableAt (by norm_num)
    refine ⟨Dx, ?_, hDx.trans (hφD _ hdiff).fderiv⟩
    rw [hDx]; exact (hφD _ hdiff).differentiableAt.hasFDerivAt
  have hsymmC : ∀ u ∈ Metric.ball c ε, ContDiffAt ℝ 1 Φ.symm u := by
    intro u hu
    obtain ⟨hut, hFx, -, -⟩ := hD u hu
    obtain ⟨Dx, hDx, -⟩ := hΦd u hu
    exact Φ.contDiffAt_symm hut hDx (hφC _ hFx)
  -- `G = Q ∘ F ∘ Φ⁻¹`
  set Gf : (Fin m → ℝ) → (Fin n → ℝ) := fun u => Q (F (Φ.symm u)) with hGf
  have hhead : ∀ u ∈ Metric.ball c ε, ∀ (i : Fin n) (hi : (i : ℕ) < r),
      Gf u i = u ⟨i, lt_of_lt_of_le hi hrm⟩ := by
    intro u hu i hi
    have h := congrFun (Φ.right_inv (hD u hu).1) ⟨i, lt_of_lt_of_le hi hrm⟩
    rw [hΦ] at h
    simp only [hφf, headMix_apply, hi, ↓reduceDIte] at h
    rw [← h]
  have hderiv : ∀ u ∈ Metric.ball c ε, ∃ T : (Fin m → ℝ) →L[ℝ] (Fin n → ℝ),
      HasFDerivAt Gf T u ∧ ∀ w : Fin m → ℝ, (∀ i : Fin m, (i : ℕ) < r → w i = 0) → T w = 0 := by
    intro u hu
    obtain ⟨hut, hFx, -, hrx⟩ := hD u hu
    obtain ⟨Dx, hDx, hDxe⟩ := hΦd u hu
    have hdiff : DifferentiableAt ℝ F (Φ.symm u) := hFx.differentiableAt (by norm_num)
    have hsymm := Φ.hasFDerivAt_symm hut hDx
    refine ⟨(Q : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ)).comp
      ((fderiv ℝ F (Φ.symm u)).comp (Dx.symm : (Fin m → ℝ) →L[ℝ] _)),
      Q.hasFDerivAt.comp u (hdiff.hasFDerivAt.comp u hsymm), ?_⟩
    intro w hw
    refine tail_kill hrn _ ?_ ?_ w hw
    · rw [finrank_range_comp_equiv]; exact hrx
    · intro w' i hi
      have := congrArg (fun f : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ) => f (Dx.symm w') i) hDxe
      simp only [ContinuousLinearEquiv.coe_coe, ContinuousLinearEquiv.apply_symm_apply,
        ContinuousLinearMap.comp_apply, ContinuousLinearMap.prod_apply, headMix_apply,
        hi, ↓reduceDIte] at this
      exact this.symm
  have hGC : ∀ u ∈ Metric.ball c ε, ContDiffAt ℝ 1 Gf u := by
    intro u hu
    exact Q.contDiff.contDiffAt.comp u ((hD u hu).2.1.comp u (hsymmC u hu))
  -- keep the first `r` places, take the rest from `c`
  set κ := headWith m n r hrn c with hκ
  have hκG : ∀ u ∈ Metric.ball c ε, ∀ i : Fin m, (i : ℕ) < r → κ (Gf u) i = u i := by
    intro u hu i hi
    simp only [hκ, headWith, hi, ↓reduceDIte]
    rw [hhead u hu _ hi]
  have hstar : ∀ u ∈ Metric.ball c ε, κ (Gf u) ∈ Metric.ball c ε := by
    intro u hu
    rw [Metric.mem_ball, dist_pi_lt_iff εpos]
    intro i
    by_cases hi : (i : ℕ) < r
    · rw [hκG u hu i hi]; exact lt_of_le_of_lt (dist_le_pi_dist u c i) hu
    · simp [hκ, headWith, hi, εpos]
  have hconst : ∀ u ∈ Metric.ball c ε, Gf (κ (Gf u)) = Gf u := by
    intro u hu
    set a := κ (Gf u) with ha_def
    have ha := hstar u hu
    have hw : ∀ i : Fin m, (i : ℕ) < r → (u - a) i = 0 := by
      intro i hi; simp [Pi.sub_apply, ha_def, hκG u hu i hi]
    have hseg : ∀ t ∈ Set.Icc (0 : ℝ) 1, a + t • (u - a) ∈ Metric.ball c ε :=
      fun t ht => (convex_ball c ε).add_smul_sub_mem ha hu ht
    have hdt : ∀ t ∈ Set.Icc (0 : ℝ) 1,
        HasDerivAt (fun t : ℝ => Gf (a + t • (u - a))) 0 t := by
      intro t ht
      obtain ⟨T, hT, hTk⟩ := hderiv _ (hseg t ht)
      have hl : HasDerivAt (fun t : ℝ => a + t • (u - a)) ((1 : ℝ) • (u - a)) t :=
        ((hasDerivAt_id' t).smul_const (u - a)).const_add a
      have := hT.comp_hasDerivAt t hl
      rwa [one_smul, hTk _ hw] at this
    have := constant_of_has_deriv_right_zero (f := fun t : ℝ => Gf (a + t • (u - a)))
      (a := 0) (b := 1) (fun t ht => (hdt t ht).continuousAt.continuousWithinAt)
      (fun t ht => (hdt t (Set.Ico_subset_Icc_self ht)).hasDerivWithinAt) 1 (by simp)
    simpa using this.symm
  -- the output renaming `ψ y = Q y - tailZero (G (κ (Q y)))`
  set hfun : (Fin n → ℝ) → (Fin n → ℝ) := fun z => tailZero n r (Gf (κ z)) with hhfun
  have hκC : ContDiff ℝ 1 κ := contDiff_headWith hrn c
  have hGOn : ContDiffOn ℝ 1 Gf (Metric.ball c ε) := fun u hu => (hGC u hu).contDiffWithinAt
  have hhOn : ContDiffOn ℝ 1 hfun (κ ⁻¹' Metric.ball c ε) :=
    (contDiff_tailZero n r).comp_contDiffOn (hGOn.comp hκC.contDiffOn (fun z hz => hz))
  have hκh : ∀ z, κ (z + hfun z) = κ z := fun z => headWith_add_tailZero hrn c z _
  have hκh' : ∀ z, κ (z - hfun z) = κ z := fun z => headWith_sub_tailZero hrn c z _
  have hh1 : ∀ z, hfun (z + hfun z) = hfun z := by
    intro z; show tailZero n r (Gf (κ (z + hfun z))) = _; rw [hκh]
  have hh2 : ∀ z, hfun (z - hfun z) = hfun z := by
    intro z; show tailZero n r (Gf (κ (z - hfun z))) = _; rw [hκh']
  have hSopen : IsOpen (κ ⁻¹' Metric.ball c ε) := Metric.isOpen_ball.preimage hκC.continuous
  let ψ : OpenPartialHomeomorph (Fin n → ℝ) (Fin n → ℝ) :=
    { toFun := fun y => Q y - hfun (Q y)
      invFun := fun z => Q.symm (z + hfun z)
      source := Q ⁻¹' (κ ⁻¹' Metric.ball c ε)
      target := κ ⁻¹' Metric.ball c ε
      map_source' := fun y hy => by
        show κ (Q y - hfun (Q y)) ∈ Metric.ball c ε
        rw [hκh']; exact hy
      map_target' := fun z hz => by
        show κ (Q (Q.symm (z + hfun z))) ∈ Metric.ball c ε
        rw [Q.apply_symm_apply, hκh]; exact hz
      left_inv' := fun y _ => by
        show Q.symm ((Q y - hfun (Q y)) + hfun (Q y - hfun (Q y))) = y
        rw [hh2, sub_add_cancel, Q.symm_apply_apply]
      right_inv' := fun z _ => by
        show Q (Q.symm (z + hfun z)) - hfun (Q (Q.symm (z + hfun z))) = z
        rw [Q.apply_symm_apply, hh1, add_sub_cancel_right]
      open_source := hSopen.preimage Q.continuous
      open_target := hSopen
      continuousOn_toFun := Q.continuous.continuousOn.sub
        (hhOn.continuousOn.comp Q.continuous.continuousOn (fun y hy => hy))
      continuousOn_invFun := Q.symm.continuous.comp_continuousOn
        (continuousOn_id.add hhOn.continuousOn) }
  let φ₀ := (Φ.symm.restrOpen (Metric.ball c ε) Metric.isOpen_ball).symm
  have hφ₀s : ∀ x, x ∈ φ₀.source ↔ x ∈ Φ.source ∧ Φ x ∈ Metric.ball c ε := fun x => Iff.rfl
  have hφ₀t : ∀ u, u ∈ φ₀.target ↔ u ∈ Φ.target ∧ u ∈ Metric.ball c ε := fun u => Iff.rfl
  refine ⟨φ₀, ψ, (hφ₀s p).2 ⟨hpΦ, Metric.mem_ball_self εpos⟩, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · show κ (Q (F p)) ∈ Metric.ball c ε
    have := hstar c (Metric.mem_ball_self εpos)
    simp only [hGf, hcΦ] at this
    exact this
  · intro x hx
    obtain ⟨hxs, hxb⟩ := (hφ₀s x).1 hx
    have := (hD _ hxb).2.1
    rw [Φ.left_inv hxs] at this
    exact (hφC x this).contDiffWithinAt
  · intro u hu
    exact (hsymmC u ((hφ₀t u).1 hu).2).contDiffWithinAt
  · exact Q.contDiff.contDiffOn.sub (hhOn.comp Q.contDiff.contDiffOn (fun y hy => hy))
  · exact Q.symm.contDiff.comp_contDiffOn (contDiffOn_id.add hhOn)
  · show ∀ᶠ u in 𝓝 c, F (Φ.symm u) ∈ ψ.source ∧ ψ (F (Φ.symm u)) = projectionForm m n r u
    filter_upwards [Metric.ball_mem_nhds c εpos] with u hu
    refine ⟨hstar u hu, ?_⟩
    show Gf u - tailZero n r (Gf (κ (Gf u))) = projectionForm m n r u
    rw [hconst u hu]
    funext i
    simp only [Pi.sub_apply, tailZero, projectionForm]
    by_cases hi : (i : ℕ) < r
    · simp [hi, hhead u hu i hi, lt_of_lt_of_le hi hrm]
    · simp [hi]

/-- Full rank at `p` is enough: if `F` has continuous partial derivatives near `p` and its
Jacobian at `p` has rank `m` (the number of inputs) or `n` (the number of outputs), then the
Jacobian has that same rank at every point near `p`. -/
theorem rank_constant_near_of_full_rank {m n : ℕ} (F : (Fin m → ℝ) → (Fin n → ℝ))
    (p : Fin m → ℝ) (hF : ContDiffAt ℝ 1 F p)
    (hfull : Module.finrank ℝ (LinearMap.range (fderiv ℝ F p).toLinearMap) = m ∨
      Module.finrank ℝ (LinearMap.range (fderiv ℝ F p).toLinearMap) = n) :
    ∀ᶠ x in 𝓝 p, Module.finrank ℝ (LinearMap.range (fderiv ℝ F x).toLinearMap) =
      Module.finrank ℝ (LinearMap.range (fderiv ℝ F p).toLinearMap) := by
  have hcont : ContinuousAt (fderiv ℝ F) p :=
    (hF.fderiv_right (m := 0) (by norm_num)).continuousAt
  rcases hfull with h | h
  · have hk : Module.finrank ℝ (LinearMap.ker (fderiv ℝ F p).toLinearMap) = 0 := by
      have := LinearMap.finrank_range_add_finrank_ker (fderiv ℝ F p).toLinearMap
      simp only [Module.finrank_fin_fun] at this
      omega
    obtain ⟨g, hg⟩ := LinearMap.exists_leftInverse_of_injective _ (Submodule.finrank_eq_zero.1 hk)
    let M : (Fin n → ℝ) →L[ℝ] (Fin m → ℝ) := LinearMap.toContinuousLinearMap g
    have hM : M.comp (fderiv ℝ F p) = (ContinuousLinearEquiv.refl ℝ (Fin m → ℝ) :
        (Fin m → ℝ) →L[ℝ] (Fin m → ℝ)) := by
      ext v i
      exact congrFun (LinearMap.congr_fun hg v) i
    have hev : ∀ᶠ x in 𝓝 p, M.comp (fderiv ℝ F x) ∈
        Set.range ((↑) : ((Fin m → ℝ) ≃L[ℝ] (Fin m → ℝ)) → ((Fin m → ℝ) →L[ℝ] _)) := by
      have hc : ContinuousAt (fun x => M.comp (fderiv ℝ F x)) p :=
        (continuous_const.clm_comp continuous_id).continuousAt.comp hcont
      apply hc.preimage_mem_nhds
      simp only [hM]
      exact ContinuousLinearEquiv.isOpen.mem_nhds ⟨_, rfl⟩
    filter_upwards [hev] with x ⟨e, he⟩
    have hinj : Function.Injective (fderiv ℝ F x).toLinearMap := by
      intro a b hab
      apply e.injective
      have ha := congrArg (fun f : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ) => f a) he
      have hb := congrArg (fun f : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ) => f b) he
      simp only [ContinuousLinearEquiv.coe_coe, ContinuousLinearMap.comp_apply] at ha hb
      rw [ha, hb]
      exact congrArg M hab
    rw [h, LinearMap.finrank_range_of_inj hinj]
    simp
  · have htop : LinearMap.range (fderiv ℝ F p).toLinearMap = ⊤ :=
      Submodule.eq_top_of_finrank_eq (h.trans (by simp))
    obtain ⟨M, hM⟩ := (fderiv ℝ F p).exists_rightInverse_of_surjective htop
    have hev : ∀ᶠ x in 𝓝 p, (fderiv ℝ F x).comp M ∈
        Set.range ((↑) : ((Fin n → ℝ) ≃L[ℝ] (Fin n → ℝ)) → ((Fin n → ℝ) →L[ℝ] _)) := by
      have hc : ContinuousAt (fun x => (fderiv ℝ F x).comp M) p :=
        (continuous_id.clm_comp continuous_const).continuousAt.comp hcont
      apply hc.preimage_mem_nhds
      simp only [hM]
      exact ContinuousLinearEquiv.isOpen.mem_nhds ⟨ContinuousLinearEquiv.refl ℝ _, rfl⟩
    filter_upwards [hev] with x ⟨e, he⟩
    have hsurj : LinearMap.range (fderiv ℝ F x).toLinearMap = ⊤ := by
      rw [LinearMap.range_eq_top]
      intro y
      refine ⟨M (e.symm y), ?_⟩
      have := congrArg (fun f : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ) => f (e.symm y)) he
      simp only [ContinuousLinearEquiv.coe_coe, ContinuousLinearMap.comp_apply,
        ContinuousLinearEquiv.apply_symm_apply] at this
      exact this.symm
    rw [h, hsurj, finrank_top]
    simp

/-- The pipe map `F(x, y) = (x + y, (x + y)^2)`: total flow and pressure drop. -/
def pipe (x : Fin 2 → ℝ) : Fin 2 → ℝ := ![x 0 + x 1, (x 0 + x 1) ^ 2]

/-- The pipe: its Jacobian has rank 1 at every point, and with the input renaming
`φ(x, y) = (x + y, y)`, whose undo is `(u, v) ↦ (u - v, v)`, and the output renaming
`ψ(s, t) = (s, t - s^2)`, the map becomes `(u, v) ↦ (u, 0)` everywhere. -/
theorem pipe_rank_one_and_projection_form :
    (∀ x : Fin 2 → ℝ, Module.finrank ℝ (LinearMap.range (fderiv ℝ pipe x).toLinearMap) = 1) ∧
    (∀ x : Fin 2 → ℝ, (fun u : Fin 2 → ℝ => ![u 0 - u 1, u 1]) ![x 0 + x 1, x 1] = x) ∧
    (∀ u : Fin 2 → ℝ, (fun s : Fin 2 → ℝ => ![s 0, s 1 - s 0 ^ 2])
        (pipe ![u 0 - u 1, u 1]) = ![u 0, 0]) := by
  refine ⟨fun x => ?_, fun x => ?_, fun u => ?_⟩
  · let w : Fin 2 → ℝ := ![1, 2 * (x 0 + x 1)]
    let L : (Fin 2 → ℝ) →L[ℝ] (Fin 2 → ℝ) :=
      (ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin 2 => ℝ) 0 +
        ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin 2 => ℝ) 1).smulRight w
    have hs : HasFDerivAt (fun y : Fin 2 → ℝ => y 0 + y 1)
        (ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin 2 => ℝ) 0 +
          ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin 2 => ℝ) 1) x :=
      (hasFDerivAt_apply 0 x).add (hasFDerivAt_apply 1 x)
    have hd : HasFDerivAt pipe L x := by
      rw [hasFDerivAt_pi']
      intro i
      fin_cases i
      · refine hs.congr_fderiv ?_
        ext v; simp [L, w]
      · have h2 := hs.mul hs
        refine (h2.congr_fderiv ?_).congr_of_eventuallyEq ?_
        · ext v; simp [L, w]; ring
        · exact Filter.Eventually.of_forall fun y => by simp [pipe]; ring
    have hrange : LinearMap.range (fderiv ℝ pipe x).toLinearMap = Submodule.span ℝ {w} := by
      rw [hd.fderiv]
      ext y
      simp only [LinearMap.mem_range, Submodule.mem_span_singleton, ContinuousLinearMap.coe_coe]
      constructor
      · rintro ⟨v, rfl⟩
        exact ⟨v 0 + v 1, by simp [L]⟩
      · rintro ⟨a, rfl⟩
        exact ⟨![a, 0], by simp [L]⟩
    rw [hrange, finrank_span_singleton]
    intro h
    have := congrFun h 0
    simp [w] at this
  · ext i; fin_cases i <;> simp
  · ext i; fin_cases i <;> simp [pipe]

/-- Worked numbers: at (1, 2) the readings are (3, 9); the new inputs are (3, 2) and undoing
them gives back (1, 2); the output renaming sends (3, 9) to (3, 9 - 3^2) = (3, 0). -/
example : ((1 : ℤ) + 2, ((1 : ℤ) + 2) ^ 2) = (3, 9) := by norm_num
example : ((1 : ℤ) + 2, (2 : ℤ)) = (3, 2) ∧ ((3 : ℤ) - 2, (2 : ℤ)) = (1, 2) := by norm_num
example : ((3 : ℤ), (9 : ℤ) - 3 ^ 2) = (3, 0) := by norm_num

/-- The Jacobian at (1, 2) has determinant 1·6 - 1·6 = 0, and the renaming matrices give
Q J P = [[1, 0], [0, 0]]. -/
example : Matrix.det !![(1 : ℤ), 1; 6, 6] = 0 := by norm_num [Matrix.det_fin_two_of]
example : !![(1 : ℤ), 0; -6, 1] * !![(1 : ℤ), 1; 6, 6] * !![(1 : ℤ), -1; 0, 1] =
    !![(1 : ℤ), 0; 0, 0] := by decide

/-- The input renaming's Jacobian [[1, 1], [0, 1]] has determinant 1; taking v = x + y instead
gives [[1, 1], [1, 1]] with determinant 0. -/
example : Matrix.det !![(1 : ℤ), 1; 0, 1] = 1 ∧ Matrix.det !![(1 : ℤ), 1; 1, 1] = 0 := by
  norm_num [Matrix.det_fin_two_of]

/-- The usual mistakes: correcting with t - s gives 9 - 3 = 6, not 0; the tangent correction
t - 6s + 9 on the curve t = s^2 gives 0 at s = 3 but 1 at s = 4. -/
example : (9 : ℤ) - 3 = 6 := by norm_num
example : (3 : ℤ) ^ 2 - 6 * 3 + 9 = 0 ∧ (4 : ℤ) ^ 2 - 6 * 4 + 9 = 1 := by norm_num

#print axioms constant_rank_theorem
#print axioms rank_constant_near_of_full_rank
#print axioms pipe_rank_one_and_projection_form
#print axioms splitFin_inl
#print axioms splitFin_inr
#print axioms linear_normal_form
#print axioms headMix_apply
#print axioms contDiff_tailZero
#print axioms contDiff_headWith
#print axioms headWith_add_tailZero
#print axioms headWith_sub_tailZero
#print axioms finrank_range_comp_equiv
#print axioms tail_kill
