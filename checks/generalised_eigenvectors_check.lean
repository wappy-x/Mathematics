-- Generalised eigenvectors: for a square matrix whose characteristic polynomial splits, each generalised eigenspace is kept by the matrix, has as many directions as its eigenvalue's multiplicity, and together they split every vector into one piece per eigenvalue in one way only.
import Mathlib.LinearAlgebra.Eigenspace.Zero
import Mathlib.LinearAlgebra.Eigenspace.Triangularizable
import Mathlib.LinearAlgebra.Charpoly.ToMatrix
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.DirectSum.Module
import Mathlib.Algebra.Polynomial.Splits
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Matrix Polynomial Module

/-! A square matrix of size `n` with entries in a field `K` is `Matrix (Fin n) (Fin n) K`; a
column of `n` numbers is `Fin n → K`, and `A *ᵥ v` is the matrix applied to it. Working in a
field is the card's "exact arithmetic"; `K = ℝ` or `K = ℂ` are the card's cases. `A - μ • 1` is
`A − λI`, and `M ^ k` is `M` applied `k` times. `A.charpoly` is the characteristic polynomial
`p(t) = det(tI − A)`, `A.charpoly.Splits` says it splits into factors `t − λ`, and
`A.charpoly.rootMultiplicity μ` is the multiplicity `m_λ`. The eigenvalues are the roots of
`p(t)`, the subtype `{μ : K // A.charpoly.IsRoot μ}`.

The generalised eigenspace `G_λ` is Mathlib's `maxGenEigenspace` of the linear map
`Matrix.toLin' A` (the map `v ↦ A *ᵥ v`): every `v` sent to zero by some power of `A − λI`,
which `mem_generalisedEigenspace_iff` below spells out. `finrank K` counts independent
directions, and `DirectSum.IsInternal G` says every vector is a sum of one piece from each `G_λ`
in exactly one way. (Naming the pieces needs equality of eigenvalues to be decidable, which
`open scoped Classical in` supplies; it adds no hypothesis.) -/

theorem toLin'_sub_smul_pow_apply {K : Type*} [Field K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K) (μ : K) (k : ℕ) (v : Fin n → K) :
    ((Matrix.toLin' A - μ • (1 : End K (Fin n → K))) ^ k) v = (A - μ • 1) ^ k *ᵥ v := by
  rw [← Matrix.toLin'_apply, Matrix.toLin'_pow, map_sub, map_smul, Matrix.toLin'_one,
    Module.End.one_eq_id]

#print axioms toLin'_sub_smul_pow_apply

theorem finrank_biSup_maxGenEigenspace {K : Type*} [Field K] {n : ℕ}
    (f : End K (Fin n → K)) (s : Finset K) :
    finrank K (⨆ μ ∈ s, f.maxGenEigenspace μ : Submodule K (Fin n → K)) =
      ∑ μ ∈ s, finrank K (f.maxGenEigenspace μ) := by
  classical
  induction s using Finset.induction_on with
  | empty => simp
  | insert a s ha ih =>
    rw [Finset.iSup_insert, Finset.sum_insert ha, ← ih]
    have hd : Disjoint (f.maxGenEigenspace a) (⨆ μ ∈ s, f.maxGenEigenspace μ) :=
      f.independent_maxGenEigenspace.disjoint_biSup ha
    have := Submodule.finrank_sup_add_finrank_inf_eq (f.maxGenEigenspace a)
      (⨆ μ ∈ s, f.maxGenEigenspace μ)
    rw [hd.eq_bot, finrank_bot, add_zero] at this
    exact this

#print axioms finrank_biSup_maxGenEigenspace


open scoped Classical in
/-- Generalised eigenspaces. Take a square matrix `A` over a field whose characteristic
polynomial splits into factors `t − λ`. For each eigenvalue `λ`, the generalised eigenspace
`G_λ` is kept by `A` (if `v` is in it, so is `A v`), it has as many independent directions as
`λ`'s multiplicity as a root of the characteristic polynomial, and the whole space is the direct
sum of the `G_λ`: every vector splits into one piece from each, in one way only. -/
theorem generalised_eigenspaces_fill_the_space {K : Type*} [Field K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K) (h_split : A.charpoly.Splits) :
    (∀ μ : K, ∀ v ∈ End.maxGenEigenspace (Matrix.toLin' A) μ,
        A *ᵥ v ∈ End.maxGenEigenspace (Matrix.toLin' A) μ) ∧
    (∀ μ : K, A.charpoly.IsRoot μ →
        finrank K (End.maxGenEigenspace (Matrix.toLin' A) μ) = A.charpoly.rootMultiplicity μ) ∧
    DirectSum.IsInternal
        (fun μ : {μ : K // A.charpoly.IsRoot μ} => End.maxGenEigenspace (Matrix.toLin' A) μ.1) := by
  set f : End K (Fin n → K) := Matrix.toLin' A
  have hfin : ∀ μ, finrank K (f.maxGenEigenspace μ) = A.charpoly.rootMultiplicity μ := by
    intro μ
    rw [LinearMap.finrank_maxGenEigenspace_eq, Matrix.charpoly_toLin']
  refine ⟨fun μ v hv => ?_, fun μ _ => hfin μ, ?_⟩
  · rw [← Matrix.toLin'_apply]
    exact Module.End.mapsTo_maxGenEigenspace_of_comm (Commute.refl f) μ hv
  apply DirectSum.isInternal_submodule_of_iSupIndep_of_iSup_eq_top
  · exact f.independent_maxGenEigenspace.comp Subtype.val_injective
  · have hne : A.charpoly ≠ 0 := (Matrix.charpoly_monic A).ne_zero
    set S := A.charpoly.roots.toFinset
    have htop : (⨆ μ ∈ S, f.maxGenEigenspace μ : Submodule K (Fin n → K)) = ⊤ := by
      apply Submodule.eq_top_of_finrank_eq
      rw [finrank_biSup_maxGenEigenspace]
      simp only [hfin, S, ← Polynomial.count_roots]
      rw [Multiset.toFinset_sum_count_eq, ← h_split.natDegree_eq_card_roots,
        Matrix.charpoly_natDegree_eq_dim]
      simp
    rw [eq_top_iff, ← htop]
    refine iSup₂_le fun μ hμ => ?_
    have hr : A.charpoly.IsRoot μ := by
      rw [Multiset.mem_toFinset, Polynomial.mem_roots hne] at hμ; exact hμ
    exact le_iSup (fun μ : {μ : K // A.charpoly.IsRoot μ} => f.maxGenEigenspace μ.1) ⟨μ, hr⟩

/-- What the generalised eigenspace is, and the power that is always enough. A vector `v` lies
in `G_λ` exactly when some power of `A − λI` sends it to zero, and exactly when the power
`m_λ`, the multiplicity of `λ`, sends it to zero: `G_λ = ker (A − λI)^{m_λ}`. -/
theorem mem_generalisedEigenspace_iff {K : Type*} [Field K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K) (μ : K) (v : Fin n → K) :
    (v ∈ End.maxGenEigenspace (Matrix.toLin' A) μ ↔ ∃ k : ℕ, (A - μ • 1) ^ k *ᵥ v = 0) ∧
    (v ∈ End.maxGenEigenspace (Matrix.toLin' A) μ ↔
        (A - μ • 1) ^ A.charpoly.rootMultiplicity μ *ᵥ v = 0) := by
  have h1 : v ∈ End.maxGenEigenspace (Matrix.toLin' A) μ ↔ ∃ k : ℕ, (A - μ • 1) ^ k *ᵥ v = 0 := by
    rw [Module.End.mem_maxGenEigenspace]
    simp only [toLin'_sub_smul_pow_apply]
  refine ⟨h1, ?_, fun h => h1.2 ⟨_, h⟩⟩
  intro hv
  set f := Matrix.toLin' A
  set G := End.maxGenEigenspace f μ
  have hG : ∀ x ∈ G, (f - μ • (1 : End K (Fin n → K))) x ∈ G := by
    intro x hx
    have := Module.End.mapsTo_maxGenEigenspace_of_comm
      (f := f) (g := f - μ • (1 : End K (Fin n → K))) ?_ μ hx
    · exact this
    · exact (Commute.refl f).sub_right (Commute.smul_right (Commute.one_right f) μ)
  set g := (f - μ • (1 : End K (Fin n → K))).restrict hG
  have hfin : finrank K G = A.charpoly.rootMultiplicity μ := by
    rw [LinearMap.finrank_maxGenEigenspace_eq, Matrix.charpoly_toLin']
  obtain ⟨k, hk⟩ := (Module.End.mem_maxGenEigenspace _ _ _).1 hv
  have hx : (⟨v, hv⟩ : G) ∈ LinearMap.ker (g ^ k) := by
    rw [LinearMap.mem_ker, Module.End.pow_restrict]
    ext1; simpa using hk
  have := Module.End.ker_pow_le_ker_pow_finrank g k hx
  rw [hfin, LinearMap.mem_ker, Module.End.pow_restrict] at this
  have := congrArg Subtype.val this
  simp only [LinearMap.coe_restrict_apply, ZeroMemClass.coe_zero] at this
  rw [← toLin'_sub_smul_pow_apply]; exact this

/-- The kernels grow, then stop. For any square matrix `M` of size `n`, a vector sent to zero by
`M^k` is sent to zero by `M^(k+1)`; once two kernels in a row are equal, all later ones equal
them; and the growth has stopped by the power `n`. -/
theorem kernels_grow_then_stop {K : Type*} [Field K] {n : ℕ}
    (M : Matrix (Fin n) (Fin n) K) :
    (∀ k : ℕ, ∀ v : Fin n → K, M ^ k *ᵥ v = 0 → M ^ (k + 1) *ᵥ v = 0) ∧
    (∀ k : ℕ, (∀ v : Fin n → K, M ^ (k + 1) *ᵥ v = 0 → M ^ k *ᵥ v = 0) →
        ∀ j : ℕ, ∀ v : Fin n → K, M ^ (k + j) *ᵥ v = 0 → M ^ k *ᵥ v = 0) ∧
    (∀ j : ℕ, ∀ v : Fin n → K, M ^ (n + j) *ᵥ v = 0 → M ^ n *ᵥ v = 0) := by
  refine ⟨fun k v hv => ?_, fun k hk j => ?_, fun j v hv => ?_⟩
  · rw [pow_succ', ← mulVec_mulVec, hv, mulVec_zero]
  · induction j with
    | zero => intro v hv; simpa using hv
    | succ j ih =>
      intro v hv
      apply ih
      have h1 : M ^ (k + 1) *ᵥ (M ^ j *ᵥ v) = 0 := by
        rw [mulVec_mulVec, ← pow_add]; rw [← hv]; congr 2; ring
      have h2 := hk _ h1
      rw [mulVec_mulVec, ← pow_add] at h2
      exact h2
  · have key := Module.End.ker_pow_eq_ker_pow_finrank_of_le (f := Matrix.toLin' M)
      (m := n + j) (by simp)
    have hv' : v ∈ LinearMap.ker (Matrix.toLin' M ^ (n + j)) := by
      rw [LinearMap.mem_ker, ← Matrix.toLin'_pow, Matrix.toLin'_apply]; exact hv
    rw [key] at hv'
    simpa [LinearMap.mem_ker, ← Matrix.toLin'_pow, Matrix.toLin'_apply] using hv'

/-! The card's worked numbers, for the van `A = [[1, 1, 0], [0, 1, 0], [1, 0, 0]]`, in whole numbers. -/

-- The characteristic polynomial is t³ − 2t² + t = t (t − 1)².
example : (!![1, 1, 0; 0, 1, 0; 1, 0, 0] : Matrix (Fin 3) (Fin 3) ℤ).charpoly =
    X ^ 3 - 2 * X ^ 2 + X := by
  rw [Matrix.charpoly, det_fin_three]
  simp
  ring
example : (X ^ 3 - 2 * X ^ 2 + X : ℤ[X]) = X * (X - 1) ^ 2 := by ring

-- The chain: A − I sends (1, 1, 0) to (1, 0, 1), and (1, 0, 1) to zero.
example : (!![1, 1, 0; 0, 1, 0; 1, 0, 0] - (1 : ℤ) • 1 : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![1, 1, 0] =
    ![1, 0, 1] := by decide
example : (!![1, 1, 0; 0, 1, 0; 1, 0, 0] - (1 : ℤ) • 1 : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![1, 0, 1] =
    0 := by decide

-- The powers of A − I: the square is [[0, 0, 0], [0, 0, 0], [−1, 1, 1]], and the cube is its negative.
example : (!![1, 1, 0; 0, 1, 0; 1, 0, 0] - (1 : ℤ) • 1 : Matrix (Fin 3) (Fin 3) ℤ) ^ 2 =
    !![0, 0, 0; 0, 0, 0; -1, 1, 1] := by decide
example : (!![1, 1, 0; 0, 1, 0; 1, 0, 0] - (1 : ℤ) • 1 : Matrix (Fin 3) (Fin 3) ℤ) ^ 3 =
    !![0, 0, 0; 0, 0, 0; 1, -1, -1] := by decide

-- Bezout: (2 − t) t + (t − 1)² = 1.
example : ((2 - X) * X + (X - 1) ^ 2 : ℤ[X]) = 1 := by ring

-- The projectors P₁ = (2I − A) A and P₀ = (A − I)² add to I, multiply to zero,
-- and split (3, 1, 0) into (3, 1, 2) + (0, 0, −2).
example : (((2 : ℤ) • 1 - !![1, 1, 0; 0, 1, 0; 1, 0, 0]) * !![1, 1, 0; 0, 1, 0; 1, 0, 0] :
    Matrix (Fin 3) (Fin 3) ℤ) = !![1, 0, 0; 0, 1, 0; 1, -1, 0] := by decide
example : (!![1, 0, 0; 0, 1, 0; 1, -1, 0] + !![0, 0, 0; 0, 0, 0; -1, 1, 1] : Matrix (Fin 3) (Fin 3) ℤ) =
    1 := by decide
example : (!![1, 0, 0; 0, 1, 0; 1, -1, 0] * !![0, 0, 0; 0, 0, 0; -1, 1, 1] : Matrix (Fin 3) (Fin 3) ℤ) =
    0 := by decide
example : (!![1, 0, 0; 0, 1, 0; 1, -1, 0] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![3, 1, 0] = ![3, 1, 2] ∧
    (!![0, 0, 0; 0, 0, 0; -1, 1, 1] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![3, 1, 0] = ![0, 0, -2] := by decide

-- Cayley-Hamilton for A: A³ − 2A² + A = 0.
example : let A : Matrix (Fin 3) (Fin 3) ℤ := !![1, 1, 0; 0, 1, 0; 1, 0, 0]
    A ^ 3 - 2 • A ^ 2 + A = 0 := by decide

-- Ten minutes: A¹⁰ (3, 1, 0) = (13, 1, 12), which is (3, 1, 2) + 10 × (1, 0, 1).
example : (!![1, 1, 0; 0, 1, 0; 1, 0, 0] : Matrix (Fin 3) (Fin 3) ℤ) ^ 10 *ᵥ ![3, 1, 0] =
    ![13, 1, 12] := by decide
example : (3 : ℤ) + 10 * 1 = 13 ∧ (2 : ℤ) + 10 * 1 = 12 := by norm_num

-- The usual mistakes: powering as if diagonal leaves the piece (3, 1, 2) where it was, and the
-- bare factor A sends (3, 1, 0) to (4, 1, 3), not to its plane piece (3, 1, 2).
example : (!![1, 1, 0; 0, 1, 0; 1, 0, 0] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![3, 1, 0] =
    ![4, 1, 3] := by decide

#print axioms generalised_eigenspaces_fill_the_space
#print axioms mem_generalisedEigenspace_iff
#print axioms kernels_grow_then_stop
