-- Polar decomposition: every bounded operator T on a complex Hilbert space equals U |T|, with |T| = sqrt(T* T) and U a partial isometry that kills exactly what T kills, and U is unitary exactly when T kills nothing and has a dense range.
import Mathlib.Analysis.SpecialFunctions.ContinuousFunctionalCalculus.Abs
import Mathlib.Analysis.CStarAlgebra.ContinuousLinearMap
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Instances
import Mathlib.Analysis.InnerProductSpace.StarOrder
import Mathlib.Analysis.InnerProductSpace.Projection.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Normed.Operator.Extend

open ContinuousLinearMap

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

lemma polar_abs_adjoint (T : H →L[ℂ] H) : adjoint (CFC.abs T) = CFC.abs T :=
  (CFC.abs_nonneg T).isSelfAdjoint.adjoint_eq

lemma polar_norm_abs_apply (T : H →L[ℂ] H) (x : H) : ‖CFC.abs T x‖ = ‖T x‖ := by
  have h1 := apply_norm_sq_eq_inner_adjoint_left (CFC.abs T) x
  have h2 := apply_norm_sq_eq_inner_adjoint_left T x
  have h3 : adjoint (CFC.abs T) ∘L CFC.abs T = adjoint T ∘L T := by
    rw [polar_abs_adjoint]
    exact CFC.abs_mul_abs T
  rw [h3, ← h2] at h1
  exact (sq_eq_sq₀ (norm_nonneg _) (norm_nonneg _)).mp h1

lemma polar_ker_abs (T : H →L[ℂ] H) :
    LinearMap.ker ((CFC.abs T : H →L[ℂ] H) : H →ₗ[ℂ] H) = LinearMap.ker (T : H →ₗ[ℂ] H) := by
  ext x
  simp only [LinearMap.mem_ker, ContinuousLinearMap.coe_coe]
  rw [← norm_eq_zero, polar_norm_abs_apply, norm_eq_zero]

lemma polar_orthogonal_range_abs (T : H →L[ℂ] H) :
    (LinearMap.range ((CFC.abs T : H →L[ℂ] H) : H →ₗ[ℂ] H))ᗮ = LinearMap.ker (T : H →ₗ[ℂ] H) := by
  have := orthogonal_range (CFC.abs T)
  rw [polar_abs_adjoint] at this
  rw [← polar_ker_abs]
  exact this

lemma polar_denseRange_abs (T : H →L[ℂ] H) (h : LinearMap.ker (T : H →ₗ[ℂ] H) = ⊥) :
    DenseRange (CFC.abs T : H →L[ℂ] H) := by
  have : (LinearMap.range ((CFC.abs T : H →L[ℂ] H) : H →ₗ[ℂ] H)).topologicalClosure = ⊤ := by
    rw [Submodule.topologicalClosure_eq_top_iff, polar_orthogonal_range_abs, h]
  have h2 := Submodule.dense_iff_topologicalClosure_eq_top.mpr this
  rw [LinearMap.coe_range, ContinuousLinearMap.coe_coe] at h2
  exact h2

#print axioms polar_abs_adjoint
#print axioms polar_norm_abs_apply
#print axioms polar_ker_abs
#print axioms polar_orthogonal_range_abs
#print axioms polar_denseRange_abs

/-- Polar decomposition. Every bounded operator T on a Hilbert space is a stretch followed by a
partial turn: T = U |T|, where |T| = sqrt(T* T) is Mathlib's absolute value `CFC.abs T`.
U* U is the projection onto the closure of the range of |T| (U keeps lengths there and sends
the rest to 0), U U* is the projection onto the closure of the range of T, and ker U = ker T.
Mathlib builds |T| only for complex scalars (bounded operators form a C*-algebra there), so
the Hilbert space is complex; the card's real matrices are the special case of real entries. -/
theorem polar_decomposition (T : H →L[ℂ] H) :
    ∃ U : H →L[ℂ] H,
      T = U * CFC.abs T ∧
      star U * U = (LinearMap.range ((CFC.abs T : H →L[ℂ] H) : H →ₗ[ℂ] H)).topologicalClosure.starProjection ∧
      U * star U = (LinearMap.range (T : H →ₗ[ℂ] H)).topologicalClosure.starProjection ∧
      LinearMap.ker (U : H →ₗ[ℂ] H) = LinearMap.ker (T : H →ₗ[ℂ] H) := by
  set A : H →L[ℂ] H := CFC.abs T with hAdef
  set R := LinearMap.range (A : H →ₗ[ℂ] H) with hR
  set K := R.topologicalClosure with hK
  set L := (LinearMap.range (T : H →ₗ[ℂ] H)).topologicalClosure with hL
  have hAK : ∀ x, A x ∈ K := fun x =>
    R.le_topologicalClosure (LinearMap.mem_range_self (A : H →ₗ[ℂ] H) x)
  let e : H →ₗ[ℂ] K := (A : H →ₗ[ℂ] H).codRestrict K hAK
  have he : ∀ x, (e x : H) = A x := fun x => rfl
  have hdense : DenseRange e := by
    rw [DenseRange, Subtype.dense_iff]
    intro y hy
    have hy' : y ∈ (K : Set H) := hy
    rw [hK, Submodule.topologicalClosure_coe, hR, LinearMap.coe_range,
      ContinuousLinearMap.coe_coe] at hy'
    refine closure_mono (fun z hz => ?_) hy'
    obtain ⟨x, rfl⟩ := hz
    exact ⟨e x, ⟨x, rfl⟩, rfl⟩
  have hnorm : ∀ x, ‖(T : H →ₗ[ℂ] H) x‖ = ‖e x‖ := fun x => by
    show ‖T x‖ = ‖A x‖
    rw [polar_norm_abs_apply]
  let V : K →ₗᵢ[ℂ] H := (T : H →ₗ[ℂ] H).extendOfIsometry hdense hnorm
  have hV : ∀ x, V (e x) = T x := fun x => LinearMap.extendOfIsometry_eq _ hdense hnorm x
  let U : H →L[ℂ] H := V.toContinuousLinearMap ∘L K.orthogonalProjectionOnto
  have hUapply : ∀ y, U y = V (K.orthogonalProjectionOnto y) := fun _ => rfl
  have hUA : ∀ x, U (A x) = T x := by
    intro x
    rw [hUapply]
    have : K.orthogonalProjectionOnto (A x) = e x :=
      Submodule.orthogonalProjectionOnto_mem_subspace_eq_self (e x)
    rw [this, hV]
  have hT : T = U * A := by
    ext1 x
    rw [mul_apply_eq_comp, hUA]
  have h1 : star U * U = K.starProjection := by
    ext1 x
    refine ext_inner_left ℂ fun y => ?_
    rw [mul_apply_eq_comp, star_eq_adjoint, adjoint_inner_right, hUapply, hUapply,
      LinearIsometry.inner_map_map, Submodule.inner_orthogonalProjectionOnto_eq_of_mem_right,
      Submodule.starProjection_apply]
  have hUP : U * K.starProjection = U := by
    ext1 x
    rw [mul_apply_eq_comp, hUapply, hUapply, Submodule.starProjection_apply,
      Submodule.orthogonalProjectionOnto_mem_subspace_eq_self]
  have hUUU : U * star U * U = U := by rw [mul_assoc, h1, hUP]
  have hVL : ∀ k, V k ∈ L := by
    intro k
    refine hdense.induction_on (p := fun k => V k ∈ L) k ?_ ?_
    · exact (LinearMap.range (T : H →ₗ[ℂ] H)).isClosed_topologicalClosure.preimage V.continuous
    · intro x
      show V (e x) ∈ L
      rw [hV]
      exact (LinearMap.range (T : H →ₗ[ℂ] H)).le_topologicalClosure
        (LinearMap.mem_range_self (T : H →ₗ[ℂ] H) x)
  have h2 : U * star U = L.starProjection := by
    ext1 x
    symm
    apply Submodule.eq_starProjection_of_mem_of_inner_eq_zero
    · rw [mul_apply_eq_comp, hUapply]
      exact hVL _
    · intro w hw
      have key : ∀ z, inner ℂ (x - (U * star U) x) (T z) = 0 := by
        intro z
        have hsa : adjoint (U * star U) = U * star U := by
          rw [← star_eq_adjoint, star_mul, star_star]
        have hP : (U * star U) (T z) = T z := by
          conv_lhs => rw [hT]
          rw [← mul_apply_eq_comp, ← mul_assoc, hUUU]
          conv_rhs => rw [hT]
        rw [inner_sub_left, ← adjoint_inner_right, hsa, hP, sub_self]
      have hle : L ≤ (ℂ ∙ (x - (U * star U) x))ᗮ := by
        apply Submodule.topologicalClosure_minimal _ _ (Submodule.isClosed_orthogonal _)
        rintro _ ⟨z, rfl⟩
        rw [Submodule.mem_orthogonal_singleton_iff_inner_right]
        exact key z
      exact Submodule.mem_orthogonal_singleton_iff_inner_right.mp (hle hw)
  have hker : LinearMap.ker (U : H →ₗ[ℂ] H) = LinearMap.ker (T : H →ₗ[ℂ] H) := by
    ext x
    have hnU : ‖U x‖ = ‖K.orthogonalProjectionOnto x‖ := V.norm_map _
    simp only [LinearMap.mem_ker, ContinuousLinearMap.coe_coe]
    rw [← norm_eq_zero, hnU, norm_eq_zero, Submodule.orthogonalProjectionOnto_eq_zero_iff, hK,
      Submodule.orthogonal_closure, hR, polar_orthogonal_range_abs]
    rfl
  exact ⟨U, hT, h1, h2, hker⟩

/-- When U is unitary. Any U with T = U |T| and ker U = ker T (the polar turn) is unitary exactly
when T sends no nonzero input to 0 and the range of T is dense. An invertible T is one such case. -/
theorem polar_factor_unitary_iff (T U : H →L[ℂ] H) (hT : T = U * CFC.abs T)
    (hU : LinearMap.ker (U : H →ₗ[ℂ] H) = LinearMap.ker (T : H →ₗ[ℂ] H)) :
    U ∈ unitary (H →L[ℂ] H) ↔ LinearMap.ker (T : H →ₗ[ℂ] H) = ⊥ ∧ Dense (Set.range T) := by
  have hTfun : (T : H → H) = (U : H → H) ∘ (CFC.abs T : H →L[ℂ] H) := by
    conv_lhs => rw [hT]
    rfl
  constructor
  · intro hUu
    have h1 : star U * U = 1 := Unitary.star_mul_self_of_mem hUu
    have h2 : U * star U = 1 := Unitary.mul_star_self_of_mem hUu
    have hker : LinearMap.ker (T : H →ₗ[ℂ] H) = ⊥ := by
      rw [← hU, LinearMap.ker_eq_bot']
      intro x hx
      have : (star U * U) x = x := by rw [h1]; rfl
      have hx' : U x = 0 := hx
      rw [mul_apply_eq_comp, hx', map_zero] at this
      exact this.symm
    refine ⟨hker, ?_⟩
    have hUsurj : Function.Surjective U := fun y => ⟨star U y, by
      rw [← mul_apply_eq_comp, h2]; rfl⟩
    have := hUsurj.denseRange.comp (polar_denseRange_abs T hker) U.continuous
    rw [hTfun]
    exact this
  · rintro ⟨hker, hdense⟩
    have hAd := polar_denseRange_abs T hker
    have hiso : ∀ y, ‖U y‖ = ‖y‖ := by
      intro y
      refine hAd.induction_on (p := fun y => ‖U y‖ = ‖y‖) y
        (isClosed_eq (by fun_prop) (by fun_prop)) ?_
      intro x
      show ‖U (CFC.abs T x)‖ = ‖CFC.abs T x‖
      rw [polar_norm_abs_apply, ← Function.comp_apply (f := U), ← hTfun]
    have h1 : star U * U = 1 := by
      rw [star_eq_adjoint]
      exact (norm_map_iff_adjoint_comp_self U).mp hiso
    have hclosed : IsClosed (Set.range U) := by
      have : Isometry U := AddMonoidHomClass.isometry_iff_norm U |>.mpr hiso
      exact this.isClosedEmbedding.isClosed_range
    have hsurj : Set.range U = Set.univ := by
      have hsub : Set.range T ⊆ Set.range U := by
        rintro _ ⟨x, rfl⟩
        rw [hTfun]
        exact ⟨_, rfl⟩
      have := closure_mono hsub
      rw [hdense.closure_eq, hclosed.closure_eq] at this
      exact Set.eq_univ_of_univ_subset this
    have h2 : U * star U = 1 := by
      ext1 y
      obtain ⟨x, rfl⟩ : y ∈ Set.range U := hsurj ▸ Set.mem_univ y
      rw [mul_apply_eq_comp, ← mul_apply_eq_comp (star U), h1]
      rfl
    exact Unitary.mem_iff.mpr ⟨h1, h2⟩

/-- An isometry S (S* S = I) that misses some output, like the delay on l2, has |S| = I, and no
unitary W gives S = W |S|: its polar turn is S itself and cannot be completed to a full turn. -/
theorem isometry_not_onto_has_no_unitary_polar_factor (S : H →L[ℂ] H) (hS : star S * S = 1)
    (hmiss : ¬ Function.Surjective S) :
    CFC.abs S = 1 ∧ ¬ ∃ W ∈ unitary (H →L[ℂ] H), S = W * CFC.abs S := by
  have habs : CFC.abs S = 1 := by
    rw [CFC.abs, hS, CFC.sqrt_one]
  refine ⟨habs, ?_⟩
  rintro ⟨W, hW, hSW⟩
  rw [habs, mul_one] at hSW
  apply hmiss
  intro y
  refine ⟨star W y, ?_⟩
  rw [hSW, ← mul_apply_eq_comp, Unitary.mul_star_self_of_mem hW]
  rfl

/-! The card's two-sample effect T = [[0, 2], [0, 0]], with |T| = diag(0, 2) and U = [[0, 1], [0, 0]]. -/

-- T* T = diag(0, 4), and |T| = diag(0, 2) squares to it.
example : (!![0, 2; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ).transpose * !![0, 2; 0, 0] = !![0, 0; 0, 4] := by
  decide
example : (!![0, 0; 0, 2] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, 0; 0, 2] = !![0, 0; 0, 4] := by
  decide
-- U |T| rebuilds T.
example : (!![0, 1; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, 0; 0, 2] = !![0, 2; 0, 0] := by
  decide
-- U* U keeps span(e2), U U* keeps span(e1).
example : (!![0, 1; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ).transpose * !![0, 1; 0, 0] = !![0, 0; 0, 1] := by
  decide
example : (!![0, 1; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ) * (!![0, 1; 0, 0]).transpose = !![1, 0; 0, 0] := by
  decide
-- x = (3, 5): T x = (10, 0) and |T| x = (0, 10), both of squared length 100.
example : (!![0, 2; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ).mulVec ![3, 5] = ![10, 0] := by decide
example : (!![0, 0; 0, 2] : Matrix (Fin 2) (Fin 2) ℤ).mulVec ![3, 5] = ![0, 10] := by decide
-- The swap W also gives W |T| = T, and W* W = I.
example : (!![0, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, 0; 0, 2] = !![0, 2; 0, 0] := by
  decide
example : (!![0, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ).transpose * !![0, 1; 1, 0] = 1 := by decide
-- Advance then delay on (3, 1, 4, 1, 5) gives (0, 1, 4, 1, 5): energy 52 down to 43.
example : (3 ^ 2 + 1 ^ 2 + 4 ^ 2 + 1 ^ 2 + 5 ^ 2 : ℕ) = 52 ∧ (0 ^ 2 + 1 ^ 2 + 4 ^ 2 + 1 ^ 2 + 5 ^ 2 : ℕ) = 43 := by
  norm_num

#print axioms polar_decomposition
#print axioms polar_factor_unitary_iff
#print axioms isometry_not_onto_has_no_unitary_polar_factor
