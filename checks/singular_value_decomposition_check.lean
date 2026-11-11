-- The singular value decomposition: every real matrix of any shape equals an orthogonal matrix times a stretch along perpendicular axes times a second orthogonal matrix, the stretch factors are always its singular values (the square roots of the eigenvalues of A transpose A, largest first, never negative), and the card's sprite numbers are checked exactly.
import Mathlib.Analysis.InnerProductSpace.SingularValues
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix

/-- The stretch matrix `S`: an `m` by `n` grid of zeros with the numbers `d 0, d 1, ...` down its
main diagonal (entry `(i, i)` is `d i`). It stretches input axis `i` by `d i` and lays it on output
axis `i`. -/
def stretchMatrix (m n : ℕ) (d : ℕ → ℝ) : Matrix (Fin m) (Fin n) ℝ :=
  Matrix.of fun i j => if (i : ℕ) = (j : ℕ) then d i else 0

noncomputable def svdColMat {k : ℕ} (b : OrthonormalBasis (Fin k) ℝ (EuclideanSpace ℝ (Fin k))) :
    Matrix (Fin k) (Fin k) ℝ :=
  Matrix.of fun i j => b j i

lemma svdColMat_mem {k : ℕ} (b : OrthonormalBasis (Fin k) ℝ (EuclideanSpace ℝ (Fin k))) :
    svdColMat b ∈ Matrix.orthogonalGroup (Fin k) ℝ := by
  have := (EuclideanSpace.basisFun (Fin k) ℝ).toMatrix_orthonormalBasis_mem_unitary b
  convert this using 1
  ext i j
  simp [svdColMat, Module.Basis.toMatrix_apply]
#print axioms svdColMat_mem

lemma svd_adj_comp_apply {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (x : EuclideanSpace ℝ (Fin n)) :
    (LinearMap.adjoint (Matrix.toEuclideanLin A) ∘ₗ Matrix.toEuclideanLin A) x =
      WithLp.toLp 2 ((Aᵀ * A) *ᵥ WithLp.ofLp x) := by
  rw [← Matrix.toEuclideanLin_conjTranspose_eq_adjoint]
  simp [Matrix.toLpLin_apply, Matrix.mulVec_mulVec]
#print axioms svd_adj_comp_apply

lemma svd_gram_mul {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    (Aᵀ * A) * svdColMat ((Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self.eigenvectorBasis
        finrank_euclideanSpace_fin) =
      svdColMat ((Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self.eigenvectorBasis
        finrank_euclideanSpace_fin) * Matrix.diagonal
        ((Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self.eigenvalues
        finrank_euclideanSpace_fin) := by
  set hT := (Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self
  ext i j
  have h := hT.apply_eigenvectorBasis finrank_euclideanSpace_fin j
  rw [svd_adj_comp_apply] at h
  have h2 := congrArg (fun x : EuclideanSpace ℝ (Fin n) => WithLp.ofLp x i) h
  simp [Matrix.mulVec, dotProduct] at h2
  rw [Matrix.mul_diagonal, Matrix.mul_apply]
  simp only [svdColMat, Matrix.of_apply]
  rw [h2]; ring
#print axioms svd_gram_mul

lemma svd_charpoly_gram {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    (Aᵀ * A).charpoly =
      ∏ k : Fin n, (Polynomial.X - Polynomial.C ((Matrix.toEuclideanLin A).singularValues k ^ 2)) := by
  have hgm := svd_gram_mul A
  set hT := (Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self
  set V := svdColMat (hT.eigenvectorBasis finrank_euclideanSpace_fin) with hVdef
  have hV : V * Vᵀ = 1 := (Matrix.mem_orthogonalGroup_iff _ _).mp (svdColMat_mem _)
  have hVt : Vᵀ * V = 1 := (Matrix.mem_orthogonalGroup_iff' _ _).mp (svdColMat_mem _)
  have hG : Aᵀ * A = V * (Matrix.diagonal (hT.eigenvalues finrank_euclideanSpace_fin) * Vᵀ) := by
    calc Aᵀ * A = Aᵀ * A * (V * Vᵀ) := by rw [hV, Matrix.mul_one]
      _ = (Aᵀ * A * V) * Vᵀ := by rw [Matrix.mul_assoc (Aᵀ * A)]
      _ = _ := by rw [hgm, Matrix.mul_assoc]
  rw [hG, Matrix.charpoly_mul_comm, Matrix.mul_assoc, hVt, Matrix.mul_one, Matrix.charpoly_diagonal]
  refine Finset.prod_congr rfl fun k _ => ?_
  rw [(Matrix.toEuclideanLin A).sq_singularValues_fin finrank_euclideanSpace_fin k]
#print axioms svd_charpoly_gram

lemma svd_roots_prod {n : ℕ} (f : Fin n → ℝ) :
    (∏ j, (Polynomial.X - Polynomial.C (f j))).roots = (List.ofFn f : Multiset ℝ) := by
  rw [Finset.prod_eq_multiset_prod, ← Fin.univ_val_map]
  have : Multiset.map (fun j => Polynomial.X - Polynomial.C (f j)) Finset.univ.val =
      Multiset.map (fun a => Polynomial.X - Polynomial.C a) (Multiset.map f Finset.univ.val) := by
    rw [Multiset.map_map]
    rfl
  rw [this, Polynomial.roots_multiset_prod_X_sub_C]
#print axioms svd_roots_prod

/-- The card's theorem. Every matrix `A` of real numbers, with any number `m` of rows and any
number `n` of columns, is three moves: `A = U S Vᵀ`. Here `V` and `U` are orthogonal matrices
(their columns are perpendicular axes of length 1: a turn, perhaps with a mirror flip), and `S` is
the stretch matrix whose diagonal holds the singular values of `A`, largest first and never
negative. Mathlib's singular values of `A` are the square roots of the eigenvalues of `Aᵀ A`. -/
theorem every_matrix_is_rotate_stretch_rotate {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    ∃ U ∈ Matrix.orthogonalGroup (Fin m) ℝ, ∃ V ∈ Matrix.orthogonalGroup (Fin n) ℝ,
      A = U * stretchMatrix m n (Matrix.toEuclideanLin A).singularValues * Vᵀ := by
  set T := Matrix.toEuclideanLin A with hTdef
  set hT := T.isSymmetric_adjoint_comp_self
  set b := hT.eigenvectorBasis (finrank_euclideanSpace_fin (𝕜 := ℝ) (n := n)) with hb
  set σ := T.singularValues with hσ
  have hinner : ∀ i j : Fin n,
      inner ℝ (T (b i)) (T (b j)) = if i = j then σ i ^ 2 else 0 := by
    intro i j
    rw [← LinearMap.adjoint_inner_right, ← LinearMap.comp_apply, hT.apply_eigenvectorBasis,
      inner_smul_right, orthonormal_iff_ite.mp b.orthonormal i j]
    split_ifs with h
    · subst h
      rw [hσ, T.sq_singularValues_fin finrank_euclideanSpace_fin i]
      simp
    · simp
  have hnorm0 : ∀ j : Fin n, σ j = 0 → T (b j) = 0 := by
    intro j hj
    have := hinner j j
    rw [if_pos rfl, hj, real_inner_self_eq_norm_sq] at this
    simpa using this
  have hσm : ∀ j : ℕ, σ j ≠ 0 → j < m := by
    intro j hj
    have h1 : j < Module.finrank ℝ (LinearMap.range T) := by
      by_contra h
      push Not at h
      exact hj ((T.singularValues_eq_zero_iff_le_finrank_range).mpr h)
    have h2 : Module.finrank ℝ (LinearMap.range T) ≤ m :=
      (Submodule.finrank_le _).trans finrank_euclideanSpace_fin.le
    omega
  have hσn : ∀ j : ℕ, σ j ≠ 0 → j < n := by
    intro j hj
    by_contra h
    push Not at h
    exact hj (T.singularValues_of_finrank_le (by rw [finrank_euclideanSpace_fin]; exact h))
  let v : Fin m → EuclideanSpace ℝ (Fin m) := fun i =>
    if h : (i : ℕ) < n then (σ i)⁻¹ • T (b ⟨i, h⟩) else 0
  let s : Set (Fin m) := {i | σ i ≠ 0}
  have hv : Orthonormal ℝ (s.domRestrict v) := by
    rw [orthonormal_iff_ite]
    rintro ⟨i, hi⟩ ⟨j, hj⟩
    have hin := hσn i hi
    have hjn := hσn j hj
    simp only [Set.domRestrict_apply, v, dif_pos hin, dif_pos hjn, inner_smul_left,
      inner_smul_right, hinner]
    by_cases hij : i = j
    · subst hij
      have hi' : σ i ≠ 0 := hi
      simp
      field_simp
    · have : (⟨(i : ℕ), hin⟩ : Fin n) ≠ ⟨j, hjn⟩ := by
        intro h
        apply hij
        ext
        simpa using congrArg Fin.val h
      simp [this, hij]
  obtain ⟨bU, hbU⟩ := hv.exists_orthonormalBasis_extension_of_card_eq (by simp)
  refine ⟨svdColMat bU, svdColMat_mem bU, svdColMat b, svdColMat_mem b, ?_⟩
  have hV : svdColMat b * (svdColMat b)ᵀ = 1 :=
    (Matrix.mem_orthogonalGroup_iff _ _).mp (svdColMat_mem _)
  have key : A * svdColMat b = svdColMat bU * stretchMatrix m n σ := by
    ext i j
    have lhs : (A * svdColMat b) i j = (T (b j)) i := by
      simp [hTdef, Matrix.mul_apply, svdColMat, Matrix.toLpLin_apply, Matrix.mulVec, dotProduct]
    rw [lhs, Matrix.mul_apply]
    simp only [svdColMat, stretchMatrix, Matrix.of_apply]
    by_cases hj0 : σ j = 0
    · rw [hnorm0 j hj0]
      refine (Finset.sum_eq_zero fun k _ => ?_).symm
      split_ifs with h
      · rw [h, hj0]; ring
      · ring
    · have hjm := hσm j hj0
      rw [Finset.sum_eq_single ⟨j, hjm⟩]
      · have h1 := hbU ⟨j, hjm⟩ hj0
        rw [h1]
        simp [v, j.isLt]
        field_simp
      · intro k _ hk
        rw [if_neg]
        · ring
        · intro h
          apply hk
          ext
          exact h
      · simp
  calc A = A * (svdColMat b * (svdColMat b)ᵀ) := by rw [hV, Matrix.mul_one]
    _ = _ := by rw [← Matrix.mul_assoc, key]

/-- The factors are unique, the axes are not. However `A` is written as `U S Vᵀ`, with `U` and `V`
orthogonal and `S` a stretch matrix whose diagonal numbers are never negative and come largest
first, those diagonal numbers are exactly the singular values of `A`. -/
theorem stretch_factors_are_the_singular_values {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (U : Matrix (Fin m) (Fin m) ℝ) (hU : U ∈ Matrix.orthogonalGroup (Fin m) ℝ)
    (V : Matrix (Fin n) (Fin n) ℝ) (hV : V ∈ Matrix.orthogonalGroup (Fin n) ℝ)
    (d : ℕ → ℝ) (hnonneg : ∀ k, k < min m n → 0 ≤ d k)
    (hsorted : ∀ k l, k ≤ l → l < min m n → d l ≤ d k)
    (hA : A = U * stretchMatrix m n d * Vᵀ) :
    ∀ k, k < min m n → d k = (Matrix.toEuclideanLin A).singularValues k := by
  intro k hk
  have h3 := svd_charpoly_gram A
  set σ := (Matrix.toEuclideanLin A).singularValues with hσ
  have hUt : Uᵀ * U = 1 := (Matrix.mem_orthogonalGroup_iff' _ _).mp hU
  have hVt : Vᵀ * V = 1 := (Matrix.mem_orthogonalGroup_iff' _ _).mp hV
  set S := stretchMatrix m n d with hS
  let e : Fin n → ℝ := fun j => if (j : ℕ) < m then d j ^ 2 else 0
  have hSS : Sᵀ * S = Matrix.diagonal e := by
    ext i j
    rw [Matrix.mul_apply]
    simp only [S, stretchMatrix, Matrix.transpose_apply, Matrix.of_apply, Matrix.diagonal_apply, e]
    by_cases him : (i : ℕ) < m
    · rw [Finset.sum_eq_single ⟨i, him⟩]
      · by_cases hij : i = j
        · subst hij
          simp [him]
          ring
        · have : (i : ℕ) ≠ j := fun h => hij (Fin.ext h)
          simp [hij, this]
      · intro k _ hk
        have : (k : ℕ) ≠ i := fun h => hk (Fin.ext h)
        simp [this]
      · simp
    · rw [Finset.sum_eq_zero]
      · split_ifs <;> simp_all
      · intro k _
        have : (k : ℕ) ≠ i := by omega
        simp [this]
  have hG : (Aᵀ * A).charpoly = ∏ j : Fin n, (Polynomial.X - Polynomial.C (e j)) := by
    have : Aᵀ * A = V * (Sᵀ * S * Vᵀ) := by
      rw [hA]
      simp only [Matrix.transpose_mul, Matrix.transpose_transpose, Matrix.mul_assoc]
      rw [← Matrix.mul_assoc Uᵀ U, hUt, Matrix.one_mul]
    rw [this, Matrix.charpoly_mul_comm, Matrix.mul_assoc, hVt, Matrix.mul_one, hSS,
      Matrix.charpoly_diagonal]
  have hroots := congrArg Polynomial.roots (hG.symm.trans h3)
  rw [svd_roots_prod, svd_roots_prod, Multiset.coe_eq_coe] at hroots
  have he : Antitone e := by
    intro i j hij
    have hij' : (i : ℕ) ≤ j := hij
    simp only [e]
    by_cases hjm : (j : ℕ) < m
    · have him : (i : ℕ) < m := lt_of_le_of_lt hij' hjm
      rw [if_pos hjm, if_pos him]
      have hjmn : (j : ℕ) < min m n := lt_min hjm j.isLt
      have h0 := hnonneg j hjmn
      have h1 := hsorted i j hij' hjmn
      nlinarith
    · rw [if_neg hjm]
      split_ifs <;> positivity
  have hσa : Antitone fun j : Fin n => σ j ^ 2 := by
    intro i j hij
    have h1 := (Matrix.toEuclideanLin A).singularValues_antitone (show (i : ℕ) ≤ j from hij)
    have h0 := (Matrix.toEuclideanLin A).singularValues_nonneg j
    simp only
    nlinarith
  have heq := List.ofFn_injective (hroots.eq_of_sortedGE he.sortedGE_ofFn hσa.sortedGE_ofFn)
  have hkm : k < m := lt_of_lt_of_le hk (min_le_left _ _)
  have hkn : k < n := lt_of_lt_of_le hk (min_le_right _ _)
  have hsq := congrFun heq ⟨k, hkn⟩
  simp only [e, if_pos hkm] at hsq
  exact (pow_left_inj₀ (hnonneg k hk) ((Matrix.toEuclideanLin A).singularValues_nonneg k)
    two_ne_zero).mp hsq

/-- The formula `σᵢ = √λᵢ`. The singular values of `A` are never negative and come largest
first, and their squares are the eigenvalues `λ₁, ..., λₙ` of `G = Aᵀ A`, counted with
repeats: the characteristic polynomial of `Aᵀ A` is `(x - σ₁²) ⋯ (x - σₙ²)`. -/
theorem singular_values_are_square_roots_of_eigenvalues_of_transpose_mul_self {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) :
    Antitone (Matrix.toEuclideanLin A).singularValues ∧
      (∀ k, 0 ≤ (Matrix.toEuclideanLin A).singularValues k) ∧
      (Aᵀ * A).charpoly =
        ∏ k : Fin n, (Polynomial.X - Polynomial.C ((Matrix.toEuclideanLin A).singularValues k ^ 2)) := by
  exact ⟨(Matrix.toEuclideanLin A).singularValues_antitone,
    (Matrix.toEuclideanLin A).singularValues_nonneg, svd_charpoly_gram A⟩

-- The sprite A = [[3, 0], [4, 5]]: G = Aᵀ A is [[25, 20], [20, 25]].
example : (!![3, 0; 4, 5] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ * !![3, 0; 4, 5] = !![25, 20; 20, 25] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Its characteristic equation (25 - λ)(25 - λ) - 20 × 20 = 0 has roots 45 and 5.
example : (25 - 45 : ℤ) * (25 - 45) - 20 * 20 = 0 := by norm_num
example : (25 - 5 : ℤ) * (25 - 5) - 20 * 20 = 0 := by norm_num
-- The input axes, before scaling to length 1: G (1, 1) = 45 (1, 1) and G (1, -1) = 5 (1, -1).
example : (!![25, 20; 20, 25] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 1] = (45 : ℤ) • ![1, 1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (!![25, 20; 20, 25] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, -1] = (5 : ℤ) • ![1, -1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Their images: A (1, 1) = (3, 9) and A (1, -1) = (3, -1), perpendicular (3 × 3 + 9 × (-1) = 0),
-- with squared lengths 90 = 45 × 2 and 10 = 5 × 2.
example : (!![3, 0; 4, 5] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 1] = ![3, 9] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (!![3, 0; 4, 5] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, -1] = ![3, -1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (3 : ℤ) * 3 + 9 * (-1) = 0 ∧ (3 : ℤ) ^ 2 + 9 ^ 2 = 45 * 2 ∧ (3 : ℤ) ^ 2 + (-1) ^ 2 = 5 * 2 := by
  norm_num
-- The singular values: √45 × √5 = 15, the area factor, and det A = 3 × 5 - 0 × 4 = 15.
example : Real.sqrt 45 * Real.sqrt 5 = 15 := by
  rw [← Real.sqrt_mul (by norm_num), show (45 : ℝ) * 5 = 15 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : Matrix.det (!![3, 0; 4, 5] : Matrix (Fin 2) (Fin 2) ℤ) = 15 := by
  norm_num [Matrix.det_fin_two_of]
-- The rebuild, exactly. U = (1/√10) [[1, 3], [3, -1]], S = √5 diag(3, 1), V = (1/√2) [[1, 1], [1, -1]];
-- the square roots combine to √5 / (√10 √2) = 1/2, and (1/2) [[1, 3], [3, -1]] diag(3, 1) [[1, 1], [1, -1]]ᵀ
-- is A.
example : (1 / 2 : ℚ) • (!![1, 3; 3, -1] * !![3, 0; 0, 1] * (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℚ)ᵀ)
    = !![3, 0; 4, 5] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Matrix.vecMul, dotProduct, Matrix.transpose_apply, Fin.sum_univ_two]
example : Real.sqrt 5 / (Real.sqrt 10 * Real.sqrt 2) = 1 / 2 := by
  rw [← Real.sqrt_mul (by norm_num), show (10 : ℝ) * 2 = 2 ^ 2 * 5 by norm_num,
    Real.sqrt_mul (by norm_num), Real.sqrt_sq (by norm_num)]
  have h : Real.sqrt 5 ≠ 0 := by positivity
  field_simp
-- The axes are perpendicular: the unscaled axis grids satisfy Pᵀ P = 10 I and Qᵀ Q = 2 I.
example : (!![1, 3; 3, -1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ * !![1, 3; 3, -1] = (10 : ℤ) • 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ * !![1, 1; 1, -1] = (2 : ℤ) • 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Eigenvalues added: 45 + 5 = 50 = 3² + 0² + 4² + 5².
example : (45 + 5 : ℤ) = 3 ^ 2 + 0 ^ 2 + 4 ^ 2 + 5 ^ 2 := by norm_num
-- The mistakes: A's own eigenvalues are 5 and 3 (det (A - 5 I) = det (A - 3 I) = 0), not the
-- stretches; and the unrooted eigenvalues multiply to 45 × 5 = 225 = 15², not 15.
example : Matrix.det (!![3 - 5, 0; 4, 5 - 5] : Matrix (Fin 2) (Fin 2) ℤ) = 0 ∧
    Matrix.det (!![3 - 3, 0; 4, 5 - 3] : Matrix (Fin 2) (Fin 2) ℤ) = 0 := by
  norm_num [Matrix.det_fin_two_of]
example : (45 * 5 : ℤ) = 225 ∧ (225 : ℤ) = 15 ^ 2 := by norm_num
-- The flat matrix B = [[1, 2], [2, 4]]: det B = 0, Bᵀ B = [[5, 10], [10, 20]] with eigenvalues 25 and 0
-- (singular values 5 and 0, rank 1), and B flattens the axis (2, -1) to zero.
example : Matrix.det (!![1, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℤ) = 0 := by
  norm_num [Matrix.det_fin_two_of]
example : (!![1, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ * !![1, 2; 2, 4] = !![5, 10; 10, 20] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : (!![5, 10; 10, 20] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 2] = (25 : ℤ) • ![1, 2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (!![1, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![2, -1] = 0 := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : Real.sqrt 25 = 5 := by
  rw [show (25 : ℝ) = 5 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)

#print axioms every_matrix_is_rotate_stretch_rotate
#print axioms stretch_factors_are_the_singular_values
#print axioms singular_values_are_square_roots_of_eigenvalues_of_transpose_mul_self
