-- Normal matrices and the polar form: a complex square matrix commutes with its conjugate transpose exactly when it is Q D Q* with Q unitary and D diagonal, every complex square matrix is U P with U unitary and P a positive semidefinite square root of A* A, the turn and the stretch commute exactly when A is normal, and the card's 2 by 2 numbers check out.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.ConjTranspose
import Mathlib.Analysis.Complex.Order
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Analysis.Matrix.Order
import Mathlib.Analysis.InnerProductSpace.JointEigenspace

namespace NormalMatricesAndPolarDecomposition

open Matrix Complex
open scoped ComplexOrder

lemma colMat_unitary {n : ℕ} (b : OrthonormalBasis (Fin n) ℂ (EuclideanSpace ℂ (Fin n))) :
    (Matrix.of fun i j => b j i)ᴴ * Matrix.of (fun i j => b j i) = 1 := by
  ext i j
  have h := (orthonormal_iff_ite.mp b.orthonormal) i j
  rw [EuclideanSpace.inner_eq_star_dotProduct] at h
  rw [Matrix.mul_apply, Matrix.one_apply, ← h, dotProduct]
  refine Finset.sum_congr rfl fun k _ => ?_
  simp [mul_comm]

#print axioms colMat_unitary

lemma colMat_unitary' {n : ℕ} (b : OrthonormalBasis (Fin n) ℂ (EuclideanSpace ℂ (Fin n))) :
    Matrix.of (fun i j => b j i) * (Matrix.of fun i j => b j i)ᴴ = 1 :=
  mul_eq_one_comm.mp (colMat_unitary b)

#print axioms colMat_unitary'

lemma eq_of_eigenbasis {n : ℕ} (A : Matrix (Fin n) (Fin n) ℂ)
    (b : OrthonormalBasis (Fin n) ℂ (EuclideanSpace ℂ (Fin n))) (d : Fin n → ℂ)
    (h : ∀ j, A *ᵥ ⇑(b j) = d j • ⇑(b j)) :
    A = Matrix.of (fun i j => b j i) * diagonal d * (Matrix.of fun i j => b j i)ᴴ := by
  have hAQ : A * Matrix.of (fun i j => b j i) = Matrix.of (fun i j => b j i) * diagonal d := by
    ext i j
    have := congrFun (h j) i
    simp only [mulVec, dotProduct, Pi.smul_apply, smul_eq_mul] at this
    rw [Matrix.mul_apply, mul_diagonal, of_apply]
    simp only [of_apply]
    rw [this, mul_comm]
  calc A = A * (Matrix.of (fun i j => b j i) * (Matrix.of fun i j => b j i)ᴴ) := by
        rw [colMat_unitary', mul_one]
    _ = _ := by rw [← Matrix.mul_assoc, hAQ]

#print axioms eq_of_eigenbasis

lemma exists_eigenbasis_of_normal {n : ℕ} (A : Matrix (Fin n) (Fin n) ℂ) (hN : A * Aᴴ = Aᴴ * A) :
    ∃ (b : OrthonormalBasis (Fin n) ℂ (EuclideanSpace ℂ (Fin n))) (d : Fin n → ℂ),
      ∀ j, A *ᵥ ⇑(b j) = d j • ⇑(b j) := by
  obtain ⟨H, hHdef⟩ : ∃ H : Matrix (Fin n) (Fin n) ℂ, H = (1/2 : ℂ) • (A + Aᴴ) := ⟨_, rfl⟩
  obtain ⟨K, hKdef⟩ : ∃ K : Matrix (Fin n) (Fin n) ℂ, K = (-I/2 : ℂ) • (A - Aᴴ) := ⟨_, rfl⟩
  have hAHK : A = H + I • K := by
    have : I * (-I/2) = 1/2 := by rw [mul_div_assoc', mul_neg, I_mul_I]; norm_num
    rw [hHdef, hKdef, smul_smul, this, ← smul_add]
    rw [add_add_sub_cancel, ← two_smul ℂ A, smul_smul]; norm_num
  have hH : H.IsHermitian := by
    simp only [IsHermitian, hHdef, conjTranspose_smul, conjTranspose_add,
      conjTranspose_conjTranspose, add_comm Aᴴ A]
    congr 1; simp
  have hK : K.IsHermitian := by
    simp only [IsHermitian, hKdef, conjTranspose_smul, conjTranspose_sub,
      conjTranspose_conjTranspose]
    rw [← neg_sub A Aᴴ, smul_neg, ← neg_smul]
    congr 1; simp [star_div₀, neg_div]
  have hHK : H * K = K * H := by
    rw [hHdef, hKdef, smul_mul_smul_comm, smul_mul_smul_comm, mul_comm (1/2 : ℂ)]
    congr 1
    simp only [add_mul, mul_add, sub_mul, mul_sub, hN]
    abel
  have hTH := (isSymmetric_toEuclideanLin_iff (A := H)).mpr hH
  have hTK := (isSymmetric_toEuclideanLin_iff (A := K)).mpr hK
  have hC : Commute (toEuclideanLin H) (toEuclideanLin K) := by
    change toEuclideanLin H * toEuclideanLin K = toEuclideanLin K * toEuclideanLin H
    rw [Module.End.mul_eq_comp, Module.End.mul_eq_comp, ← toLpLin_mul_same, ← toLpLin_mul_same,
      hHK]
  obtain ⟨V, hVdef⟩ : ∃ V : ℂ × ℂ → Submodule ℂ (EuclideanSpace ℂ (Fin n)),
      V = fun p => Module.End.eigenspace (toEuclideanLin H) p.2 ⊓
        Module.End.eigenspace (toEuclideanLin K) p.1 := ⟨_, rfl⟩
  have hV0 : DirectSum.IsInternal V := by
    rw [hVdef]; exact LinearMap.IsSymmetric.directSum_isInternal_of_commute hTH hTK hC
  have hV0' : OrthogonalFamily ℂ (fun i => V i) (fun i => (V i).subtypeₗᵢ) := by
    rw [hVdef]; exact LinearMap.IsSymmetric.orthogonalFamily_eigenspace_inf_eigenspace hTH hTK
  have hVle : ∀ q, V q ≤ Module.End.eigenspace (toEuclideanLin H) q.2 ∧
      V q ≤ Module.End.eigenspace (toEuclideanLin K) q.1 := by
    intro q; rw [hVdef]; exact ⟨inf_le_left, inf_le_right⟩
  have hV := DirectSum.isInternal_ne_bot_iff.mpr hV0
  have hV' := hV0'.comp (Subtype.val_injective (p := fun p : ℂ × ℂ => V p ≠ ⊥))
  have hfin : Finite {p : ℂ × ℂ // V p ≠ ⊥} := by
    refine Finite.of_injective (β := Module.End.Eigenvalues (toEuclideanLin K) × Module.End.Eigenvalues (toEuclideanLin H))
      (fun p => (⟨p.1.1, ?_⟩, ⟨p.1.2, ?_⟩)) ?_
    · exact Module.End.hasEigenvalue_iff.mpr fun h => p.2 (eq_bot_iff.mpr (le_trans (hVle _).2 h.le))
    · exact Module.End.hasEigenvalue_iff.mpr fun h => p.2 (eq_bot_iff.mpr (le_trans (hVle _).1 h.le))
    · intro p q hpq
      have h1 := congrArg (fun x => (x.1 : ℂ)) hpq
      have h2 := congrArg (fun x => (x.2 : ℂ)) hpq
      exact Subtype.ext (Prod.ext h1 h2)
  have := Fintype.ofFinite {p : ℂ × ℂ // V p ≠ ⊥}
  classical
  obtain ⟨b, idx, hb⟩ : ∃ (b : OrthonormalBasis (Fin n) ℂ (EuclideanSpace ℂ (Fin n)))
      (idx : Fin n → {p : ℂ × ℂ // V p ≠ ⊥}), ∀ j, b j ∈ V (idx j) :=
    ⟨hV.subordinateOrthonormalBasis finrank_euclideanSpace_fin hV',
      fun j => hV.subordinateOrthonormalBasisIndex finrank_euclideanSpace_fin j hV',
      fun j => hV.subordinateOrthonormalBasis_subordinate finrank_euclideanSpace_fin j hV'⟩
  refine ⟨b, fun j => (idx j).1.2 + I * (idx j).1.1, fun j => ?_⟩
  have hm1 := Module.End.mem_eigenspace_iff.mp ((hVle _).1 (hb j))
  have hm2 := Module.End.mem_eigenspace_iff.mp ((hVle _).2 (hb j))
  have h1 : H *ᵥ ⇑(b j) = (idx j).1.2 • ⇑(b j) := congrArg WithLp.ofLp hm1
  have h2 : K *ᵥ ⇑(b j) = (idx j).1.1 • ⇑(b j) := congrArg WithLp.ofLp hm2
  rw [hAHK, add_mulVec, smul_mulVec, h1, h2, smul_smul, ← add_smul]

#print axioms exists_eigenbasis_of_normal

open scoped MatrixOrder in
lemma psd_eq_of_mul_self_eq {n : ℕ} {X Y : Matrix (Fin n) (Fin n) ℂ} (hX : X.PosSemidef)
    (hY : Y.PosSemidef) (h : X * X = Y * Y) : X = Y :=
  (CFC.mul_self_eq_mul_self_iff X Y hX.nonneg hY.nonneg).mp h

#print axioms psd_eq_of_mul_self_eq

open scoped MatrixOrder in
lemma exists_psd_mul_self_eq {n : ℕ} (M : Matrix (Fin n) (Fin n) ℂ) (hM : M.PosSemidef) :
    ∃ P : Matrix (Fin n) (Fin n) ℂ, P.PosSemidef ∧ P * P = M :=
  ⟨CFC.sqrt M, nonneg_iff_posSemidef.mp (CFC.sqrt_nonneg M), CFC.sqrt_mul_sqrt_self M hM.nonneg⟩

#print axioms exists_psd_mul_self_eq

lemma inner_toEuclideanLin_toEuclideanLin {n : ℕ} (A : Matrix (Fin n) (Fin n) ℂ)
    (x y : EuclideanSpace ℂ (Fin n)) :
    inner ℂ (toEuclideanLin A x) (toEuclideanLin A y) = inner ℂ x (toEuclideanLin (Aᴴ * A) y) := by
  rw [toLpLin_mul_same, LinearMap.comp_apply, toEuclideanLin_conjTranspose_eq_adjoint,
    LinearMap.adjoint_inner_right]

#print axioms inner_toEuclideanLin_toEuclideanLin

/-- The card's first theorem. For every size `n`, an `n × n` complex matrix `A` commutes with its
conjugate transpose (`A A* = A* A`, so `A` is normal) exactly when `A = Q D Q*` for a complex
matrix `Q` whose columns are perpendicular unit vectors (`Q* Q = I`, so `Q` is unitary) and a
diagonal matrix `D` of complex stretch factors `d`. -/
theorem normal_iff_unitarily_diagonalizable (n : ℕ) (A : Matrix (Fin n) (Fin n) ℂ) :
    A * Aᴴ = Aᴴ * A ↔
      ∃ (Q : Matrix (Fin n) (Fin n) ℂ) (d : Fin n → ℂ),
        Qᴴ * Q = 1 ∧ A = Q * diagonal d * Qᴴ := by
  constructor
  · intro hN
    obtain ⟨b, d, hb⟩ := exists_eigenbasis_of_normal A hN
    exact ⟨_, d, colMat_unitary b, eq_of_eigenbasis A b d hb⟩
  · rintro ⟨Q, d, hQ, rfl⟩
    have key : ∀ X Y : Matrix (Fin n) (Fin n) ℂ,
        Q * X * Qᴴ * (Q * Y * Qᴴ) = Q * (X * Y) * Qᴴ := by
      intro X Y
      simp only [Matrix.mul_assoc]
      rw [← Matrix.mul_assoc Qᴴ Q, hQ, Matrix.one_mul]
    have hct : (Q * diagonal d * Qᴴ)ᴴ = Q * diagonal (star d) * Qᴴ := by
      rw [conjTranspose_mul, conjTranspose_mul, conjTranspose_conjTranspose,
        diagonal_conjTranspose, Matrix.mul_assoc]
    rw [hct, key, key, diagonal_mul_diagonal, diagonal_mul_diagonal]
    congr 3
    ext i
    exact mul_comm _ _

/-- The card's second theorem, the polar form. Every `n × n` complex matrix `A`, normal or not,
is `A = U P` with `U` unitary (`U* U = I`) and `P` positive semidefinite (equal to its conjugate
transpose, with no negative eigenvalue) and `P² = A* A`, so `P = √(A* A)`. -/
theorem exists_polar_decomposition (n : ℕ) (A : Matrix (Fin n) (Fin n) ℂ) :
    ∃ (U P : Matrix (Fin n) (Fin n) ℂ),
      Uᴴ * U = 1 ∧ P.PosSemidef ∧ P * P = Aᴴ * A ∧ A = U * P := by
  obtain ⟨P, hP, hPP⟩ := exists_psd_mul_self_eq (Aᴴ * A) (posSemidef_conjTranspose_mul_self A)
  set v := hP.1.eigenvectorBasis with hv
  set s : Fin n → ℝ := hP.1.eigenvalues with hs
  have hs0 : ∀ j, 0 ≤ s j := hP.eigenvalues_nonneg
  have hPv : ∀ j, P *ᵥ ⇑(v j) = (s j : ℂ) • ⇑(v j) := by
    intro j
    rw [hP.1.mulVec_eigenvectorBasis j, ← Complex.coe_smul]
  have hPv' : ∀ j, toEuclideanLin P (v j) = (s j : ℂ) • v j := by
    intro j
    rw [toLpLin_apply, hPv j]; rfl
  have hAA : ∀ i j, inner ℂ (toEuclideanLin A (v i)) (toEuclideanLin A (v j)) =
      ((s j : ℂ) * s j) * inner ℂ (v i) (v j) := by
    intro i j
    rw [inner_toEuclideanLin_toEuclideanLin, ← hPP, toLpLin_mul_same, LinearMap.comp_apply,
      hPv', map_smul, hPv', smul_smul, inner_smul_right]
  set w : Fin n → EuclideanSpace ℂ (Fin n) := fun j => ((s j : ℂ)⁻¹) • toEuclideanLin A (v j)
    with hw
  have horth : Orthonormal ℂ ({j | s j ≠ 0}.domRestrict w) := by
    rw [orthonormal_iff_ite]
    rintro ⟨i, hi⟩ ⟨j, hj⟩
    change inner ℂ (w i) (w j) = if (⟨i, hi⟩ : {j | s j ≠ 0}) = ⟨j, hj⟩ then 1 else 0
    simp only [Subtype.mk.injEq]
    rw [hw]
    simp only [inner_smul_left, inner_smul_right, hAA,
      (orthonormal_iff_ite.mp v.orthonormal) i j]
    split_ifs with hij
    · subst hij
      have : (s i : ℂ) ≠ 0 := by exact_mod_cast hi
      simp only [map_inv₀, Complex.conj_ofReal]
      field_simp
    · simp
  obtain ⟨c, hc⟩ := horth.exists_orthonormalBasis_extension_of_card_eq (by simp)
  have hAv : ∀ j, A *ᵥ ⇑(v j) = (s j : ℂ) • ⇑(c j) := by
    intro j
    have key : toEuclideanLin A (v j) = (s j : ℂ) • c j := by
      by_cases hj : s j = 0
      · rw [hj, Complex.ofReal_zero, zero_smul, ← inner_self_eq_zero (𝕜 := ℂ), hAA, hj]
        simp
      · rw [hc j hj, hw, smul_smul, mul_inv_cancel₀ (by exact_mod_cast hj), one_smul]
    have := congrArg WithLp.ofLp key
    simpa using this
  refine ⟨Matrix.of (fun i j => c j i) * (Matrix.of fun i j => v j i)ᴴ, P,
    ?_, hP, hPP, ?_⟩
  · rw [conjTranspose_mul, conjTranspose_conjTranspose, Matrix.mul_assoc,
      ← Matrix.mul_assoc _ (Matrix.of fun i j => c j i), colMat_unitary, Matrix.one_mul,
      colMat_unitary']
  · have hAV : A * Matrix.of (fun i j => v j i) =
        Matrix.of (fun i j => c j i) * diagonal (fun j => (s j : ℂ)) := by
      ext i j
      have := congrFun (hAv j) i
      simp only [mulVec, dotProduct, Pi.smul_apply, smul_eq_mul] at this
      rw [Matrix.mul_apply, mul_diagonal, of_apply]
      simp only [of_apply]
      rw [this, mul_comm]
    rw [eq_of_eigenbasis P v (fun j => (s j : ℂ)) hPv]
    calc A = A * (Matrix.of (fun i j => v j i) * (Matrix.of fun i j => v j i)ᴴ) := by
          rw [colMat_unitary', Matrix.mul_one]
      _ = Matrix.of (fun i j => c j i) * diagonal (fun j => (s j : ℂ)) *
            (Matrix.of fun i j => v j i)ᴴ := by rw [← Matrix.mul_assoc, hAV]
      _ = _ := by
        simp only [Matrix.mul_assoc]
        rw [← Matrix.mul_assoc (Matrix.of fun i j => v j i)ᴴ, colMat_unitary, Matrix.one_mul]

/-- Step 5 of the card: in a polar form `A = U P` (`U` unitary, `P` positive semidefinite), the
turn and the stretch commute, `U P = P U`, exactly when `A` is normal. -/
theorem polar_factors_commute_iff_normal (n : ℕ) (A U P : Matrix (Fin n) (Fin n) ℂ)
    (hU : Uᴴ * U = 1) (hP : P.PosSemidef) (hA : A = U * P) :
    U * P = P * U ↔ A * Aᴴ = Aᴴ * A := by
  have hU' : U * Uᴴ = 1 := mul_eq_one_comm.mp hU
  have hPh : Pᴴ = P := hP.1
  have hAA : Aᴴ * A = P * P := by
    rw [hA, conjTranspose_mul, hPh, Matrix.mul_assoc, ← Matrix.mul_assoc Uᴴ, hU, Matrix.one_mul]
  have hAA' : A * Aᴴ = U * (P * P) * Uᴴ := by
    rw [hA, conjTranspose_mul, hPh]; simp only [Matrix.mul_assoc]
  rw [hAA, hAA']
  constructor
  · intro h
    calc U * (P * P) * Uᴴ = (U * P) * P * Uᴴ := by simp only [Matrix.mul_assoc]
      _ = (P * U) * P * Uᴴ := by rw [h]
      _ = P * (U * P) * Uᴴ := by simp only [Matrix.mul_assoc]
      _ = P * (P * U) * Uᴴ := by rw [h]
      _ = P * P * (U * Uᴴ) := by simp only [Matrix.mul_assoc]
      _ = P * P := by rw [hU', Matrix.mul_one]
  · intro h
    have hQ : (U * P * Uᴴ).PosSemidef := hP.mul_mul_conjTranspose_same U
    have hQQ : (U * P * Uᴴ) * (U * P * Uᴴ) = P * P := by
      rw [← h]
      calc U * P * Uᴴ * (U * P * Uᴴ) = U * P * (Uᴴ * U) * P * Uᴴ := by
            simp only [Matrix.mul_assoc]
        _ = U * (P * P) * Uᴴ := by rw [hU, Matrix.mul_one]; simp only [Matrix.mul_assoc]
    have hQP : U * P * Uᴴ = P := psd_eq_of_mul_self_eq hQ hP hQQ
    calc U * P = U * P * Uᴴ * U := by rw [Matrix.mul_assoc _ Uᴴ, hU, Matrix.mul_one]
      _ = P * U := by rw [hQP]

/-! The card's matrices: the quarter turn `R`, the rubber matrix `A`, the Hermitian `H` and
`N = I + 2R`. -/

-- R = [[0, -1], [1, 0]] is normal: R R* = R* R (both are I).
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) * (!![0, -1; 1, 0])ᴴ = 1 ∧
    (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ)ᴴ * !![0, -1; 1, 0] = 1 := by
  constructor <;> ext i j <;> fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]
-- R sends (1, -i) to i (1, -i): eigenvalue i.
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, -I] = I • ![1, -I] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two]
-- R sends (1, i) to -i (1, i): eigenvalue -i.
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, I] = (-I) • ![1, I] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two]
-- The two eigenvectors are perpendicular: conjugate the first, multiply, add, and get 0.
example : star (![1, -I] : Fin 2 → ℂ) ⬝ᵥ ![1, I] = 0 := by
  simp [dotProduct, Fin.sum_univ_two]
-- Mistake 1: the plain transpose gives 2 for the raw vectors, so 1 at unit length (each over √2).
example : (![1, -I] : Fin 2 → ℂ) ⬝ᵥ ![1, I] = 2 := by
  simp [dotProduct, Fin.sum_univ_two]; norm_num
-- Q D Q* rebuilds R: Q's columns are (1, -i) and (1, i) over √2, D = diag(i, -i).
example : (1 / 2 : ℂ) • (!![1, 1; -I, I] * diagonal ![I, -I] * (!![1, 1; -I, I])ᴴ :
    Matrix (Fin 2) (Fin 2) ℂ) = !![0, -1; 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, diagonal_apply, vecMul, dotProduct] <;> ring_nf
-- Q* Q = I in the same form: (1/2) Q0* Q0 = I.
example : (1 / 2 : ℂ) • ((!![1, 1; -I, I])ᴴ * !![1, 1; -I, I] : Matrix (Fin 2) (Fin 2) ℂ) = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> ring_nf
-- The rubber matrix A = [[0, -2], [1, 0]] is not normal: A A* = diag(4, 1), A* A = diag(1, 4).
example : (!![0, -2; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) * (!![0, -2; 1, 0])ᴴ = diagonal ![4, 1] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, map_ofNat]; norm_num
example : (!![0, -2; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ)ᴴ * !![0, -2; 1, 0] = diagonal ![1, 4] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, map_ofNat]; norm_num
-- A's sum of squared entry sizes is 5, its eigenvalues ±√2 i are worth 2 + 2 = 4, corner 5 - 4 = 1.
example : (0 : ℤ) ^ 2 + 2 ^ 2 + 1 ^ 2 + 0 ^ 2 = 5 ∧ (5 : ℤ) - (2 + 2) = 1 := by
  norm_num
-- The polar form of A: the turn U = R times the stretch P = diag(1, 2) rebuilds A.
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) * diagonal ![1, 2] = !![0, -2; 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, diagonal_apply]
-- P = diag(1, 2) squares to A* A = diag(1, 4).
example : (diagonal ![1, 2] : Matrix (Fin 2) (Fin 2) ℂ) * diagonal ![1, 2] =
    (!![0, -2; 1, 0])ᴴ * !![0, -2; 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, diagonal_apply, map_ofNat]
-- The left form: P' = diag(2, 1) = √(A A*), and P' U = A.
example : (diagonal ![2, 1] : Matrix (Fin 2) (Fin 2) ℂ) * !![0, -1; 1, 0] = !![0, -2; 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, diagonal_apply]
-- Mistake 2: the order swapped, P U = [[0, -1], [2, 0]], not A.
example : (diagonal ![1, 2] : Matrix (Fin 2) (Fin 2) ℂ) * !![0, -1; 1, 0] = !![0, -1; 2, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, diagonal_apply]
-- H = [[2, i], [-i, 2]] is Hermitian, so normal.
example : (!![2, I; -I, 2] : Matrix (Fin 2) (Fin 2) ℂ)ᴴ = !![2, I; -I, 2] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp
-- N = I + 2R = [[1, -2], [2, 1]] is normal: N N* = N* N = 5 I.
example : (!![1, -2; 2, 1] : Matrix (Fin 2) (Fin 2) ℂ) * (!![1, -2; 2, 1])ᴴ =
    (!![1, -2; 2, 1])ᴴ * !![1, -2; 2, 1] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, map_ofNat]

#print axioms normal_iff_unitarily_diagonalizable
#print axioms exists_polar_decomposition
#print axioms polar_factors_commute_iff_normal

end NormalMatricesAndPolarDecomposition
