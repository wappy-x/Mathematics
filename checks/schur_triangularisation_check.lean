-- Schur's triangle: every complex square matrix is Q T Q* with Q unitary and T upper triangular, T's diagonal holds the eigenvalues, and a real quarter turn has no real triangle.
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.Projection.FiniteDimensional
import Mathlib.LinearAlgebra.Eigenspace.Triangularizable
import Mathlib.Analysis.Complex.Polynomial.Basic

open Matrix Polynomial
open scoped InnerProductSpace ComplexConjugate

lemma schur_aux_basis (n : ℕ) :
    ∀ (V : Type) [NormedAddCommGroup V] [InnerProductSpace ℂ V] [FiniteDimensional ℂ V],
      Module.finrank ℂ V = n → ∀ f : V →ₗ[ℂ] V,
      ∃ b : OrthonormalBasis (Fin n) ℂ V, ∀ i j : Fin n, j < i → ⟪b i, f (b j)⟫_ℂ = 0 := by
  induction n with
  | zero =>
    intro V _ _ _ hV f
    exact ⟨(stdOrthonormalBasis ℂ V).reindex (finCongr hV), fun i => i.elim0⟩
  | succ n ih =>
    intro V _ _ _ hV f
    have : Nontrivial V := Module.nontrivial_of_finrank_eq_succ hV
    obtain ⟨μ, hμ⟩ := Module.End.exists_eigenvalue (LinearMap.adjoint f)
    obtain ⟨v, hv⟩ := hμ.exists_hasEigenvector
    have hv0 : v ≠ 0 := hv.2
    have hfv : LinearMap.adjoint f v = μ • v := Module.End.mem_eigenspace_iff.mp hv.1
    have : Fact (Module.finrank ℂ V = n + 1) := ⟨hV⟩
    have hWdim : Module.finrank ℂ (ℂ ∙ v)ᗮ = n := Submodule.finrank_orthogonal_span_singleton hv0
    have hinv : ∀ w ∈ (ℂ ∙ v)ᗮ, f w ∈ (ℂ ∙ v)ᗮ := by
      intro w hw
      rw [Submodule.mem_orthogonal_singleton_iff_inner_right] at hw ⊢
      rw [← LinearMap.adjoint_inner_left, hfv, inner_smul_left, hw, mul_zero]
    obtain ⟨c, hc⟩ := ih (ℂ ∙ v)ᗮ hWdim (f.restrict hinv)
    set u : V := ((‖v‖ : ℂ)⁻¹) • v with hu
    have hu_norm : ‖u‖ = 1 := by
      rw [hu, norm_smul]
      simp [hv0]
    have huW : ∀ w ∈ (ℂ ∙ v)ᗮ, ⟪u, w⟫_ℂ = 0 := by
      intro w hw
      rw [Submodule.mem_orthogonal_singleton_iff_inner_right] at hw
      rw [hu, inner_smul_left, hw, mul_zero]
    let e : Fin (n+1) → V := Fin.snoc (fun i => (c i : V)) u
    have he_cast : ∀ i : Fin n, e i.castSucc = c i := fun i => Fin.snoc_castSucc (α := fun _ => V) ..
    have he_last : e (Fin.last n) = u := Fin.snoc_last (α := fun _ => V) ..
    have hon : Orthonormal ℂ e := by
      rw [orthonormal_iff_ite]
      intro i j
      induction i using Fin.lastCases with
      | last =>
        induction j using Fin.lastCases with
        | last => simp [he_last, inner_self_eq_norm_sq_to_K, hu_norm]
        | cast j =>
          rw [he_last, he_cast, huW _ (c j).2, ite_eq_right (Fin.castSucc_lt_last j).ne']
      | cast i =>
        induction j using Fin.lastCases with
        | last =>
          rw [he_last, he_cast, ← inner_conj_symm, huW _ (c i).2, map_zero,
            ite_eq_right (Fin.castSucc_lt_last i).ne]
        | cast j =>
          rw [he_cast, he_cast, ← Submodule.coe_inner, orthonormal_iff_ite.mp c.orthonormal]
          simp only [Fin.castSucc_inj]
    have hsp : ⊤ ≤ Submodule.span ℂ (Set.range e) :=
      (hon.linearIndependent.span_eq_top_of_card_eq_finrank' (by simp [hV])).ge
    refine ⟨OrthonormalBasis.mk hon hsp, ?_⟩
    intro i j hij
    simp only [OrthonormalBasis.coe_mk]
    induction i using Fin.lastCases with
    | last =>
      induction j using Fin.lastCases with
      | last => exact absurd hij (lt_irrefl _)
      | cast j =>
        rw [he_last, he_cast]
        exact huW _ (hinv _ (c j).2)
    | cast i =>
      induction j using Fin.lastCases with
      | last => exact absurd hij (not_lt.mpr (Fin.le_last _))
      | cast j =>
        rw [he_cast, he_cast]
        have := hc i j (Fin.castSucc_lt_castSucc_iff.mp hij)
        rwa [Submodule.coe_inner, LinearMap.coe_restrict_apply] at this

lemma schur_exists_unitary (n : ℕ) (A : Matrix (Fin n) (Fin n) ℂ) :
    ∃ Q ∈ Matrix.unitaryGroup (Fin n) ℂ, ∀ i j : Fin n, j < i → (star Q * A * Q) i j = 0 := by
  obtain ⟨b, hb⟩ := schur_aux_basis n (EuclideanSpace ℂ (Fin n)) (finrank_euclideanSpace_fin)
    (Matrix.toEuclideanLin A)
  let Q : Matrix (Fin n) (Fin n) ℂ := Matrix.of fun i j => b j i
  have key : ∀ (M : Matrix (Fin n) (Fin n) ℂ) i j,
      (star Q * M * Q) i j = ⟪b i, Matrix.toEuclideanLin M (b j)⟫_ℂ := by
    intro M i j
    simp [Q, Matrix.mul_apply, PiLp.inner_apply, mulVec, dotProduct]
    simp_rw [Finset.sum_mul]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun x _ => Finset.sum_congr rfl fun y _ => ?_
    ring
  refine ⟨Q, ?_, fun i j hij => by rw [key]; exact hb i j hij⟩
  rw [mem_unitaryGroup_iff']
  ext i j
  have : (star Q * Q) i j = ⟪b i, b j⟫_ℂ := by
    simp [Q, Matrix.mul_apply, PiLp.inner_apply, mul_comm]
  rw [this, orthonormal_iff_ite.mp b.orthonormal, Matrix.one_apply]

lemma schur_diag_aux (n : ℕ) (A Q : Matrix (Fin n) (Fin n) ℂ)
    (hQ : Q ∈ Matrix.unitaryGroup (Fin n) ℂ)
    (hT : ∀ i j : Fin n, j < i → (star Q * A * Q) i j = 0) :
    A.charpoly = ∏ i, (X - C ((star Q * A * Q) i i)) ∧
    A.trace = ∑ i, (star Q * A * Q) i i ∧
    A.det = ∏ i, (star Q * A * Q) i i := by
  have h1 : Q * star Q = 1 := mem_unitaryGroup_iff.mp hQ
  have hut : (star Q * A * Q).IsUpperTriangular := fun i j hij => hT i j hij
  refine ⟨?_, ?_, ?_⟩
  · rw [← charpoly_of_isUpperTriangular _ hut, Matrix.mul_assoc, Matrix.charpoly_mul_comm,
      Matrix.mul_assoc, h1, Matrix.mul_one]
  · change _ = (star Q * A * Q).trace
    rw [Matrix.mul_assoc, Matrix.trace_mul_comm, Matrix.mul_assoc, h1, Matrix.mul_one]
  · rw [← det_of_isUpperTriangular hut, Matrix.mul_assoc, Matrix.det_mul_comm,
      Matrix.mul_assoc, h1, Matrix.mul_one]

#print axioms schur_aux_basis
#print axioms schur_exists_unitary
#print axioms schur_diag_aux


/-- Schur's theorem: for every n by n complex matrix A there is a unitary matrix Q
(Q* Q = I, its columns perpendicular unit axes) such that T = Q* A Q is upper triangular
(zero below the diagonal) and A = Q T Q*. The diagonal of T holds A's eigenvalues, counted
with repetition: A's characteristic polynomial is the product of (X - t_ii). So the diagonal
entries add to the trace of A and multiply to its determinant. A real matrix is covered by
reading its entries as complex numbers. -/
theorem schur_triangularisation (n : ℕ) (A : Matrix (Fin n) (Fin n) ℂ) :
    ∃ Q ∈ Matrix.unitaryGroup (Fin n) ℂ, ∃ T : Matrix (Fin n) (Fin n) ℂ,
      T = star Q * A * Q ∧ A = Q * T * star Q ∧
      (∀ i j : Fin n, j < i → T i j = 0) ∧
      A.charpoly = ∏ i, (X - C (T i i)) ∧
      A.trace = ∑ i, T i i ∧
      A.det = ∏ i, T i i := by
  obtain ⟨Q, hQ, hT⟩ := schur_exists_unitary n A
  obtain ⟨h1, h2, h3⟩ := schur_diag_aux n A Q hQ hT
  have hQQ : Q * star Q = 1 := mem_unitaryGroup_iff.mp hQ
  refine ⟨Q, hQ, star Q * A * Q, rfl, ?_, hT, h1, h2, h3⟩
  rw [← Matrix.mul_assoc, ← Matrix.mul_assoc, hQQ, Matrix.one_mul, Matrix.mul_assoc, hQQ,
    Matrix.mul_one]

/-- Every Schur triangle shows the eigenvalues (Step 5): Q and T are not unique, but for
any unitary Q that makes T = Q* A Q upper triangular, the diagonal of T holds A's
eigenvalues with repetition (A's characteristic polynomial is the product of (X - t_ii)),
and those diagonal entries add to the trace and multiply to the determinant. -/
theorem schur_triangle_diagonal_is_eigenvalues (n : ℕ) (A Q : Matrix (Fin n) (Fin n) ℂ)
    (hQ : Q ∈ Matrix.unitaryGroup (Fin n) ℂ)
    (hT : ∀ i j : Fin n, j < i → (star Q * A * Q) i j = 0) :
    A.charpoly = ∏ i, (X - C ((star Q * A * Q) i i)) ∧
    A.trace = ∑ i, (star Q * A * Q) i i ∧
    A.det = ∏ i, (star Q * A * Q) i i := by
  exact schur_diag_aux n A Q hQ hT

/-- A real matrix can need complex axes (Step 6): for the quarter turn R = [[0, -1], [1, 0]],
no real orthogonal matrix Q (real unitary, Qᵀ Q = I) makes Qᵀ R Q upper triangular. -/
theorem quarter_turn_no_real_schur_triangle :
    ¬ ∃ Q ∈ Matrix.orthogonalGroup (Fin 2) ℝ,
      ∀ i j : Fin 2, j < i → (Qᵀ * !![(0 : ℝ), -1; 1, 0] * Q) i j = 0 := by
  rintro ⟨Q, hQ, hT⟩
  rw [mem_orthogonalGroup_iff'] at hQ
  have h00 := congrFun (congrFun hQ 0) 0
  have h01 := congrFun (congrFun hQ 0) 1
  have h11 := congrFun (congrFun hQ 1) 1
  have h := hT 1 0 (by decide)
  simp [Matrix.mul_apply, Fin.sum_univ_two] at h00 h01 h11 h
  have : (Q 0 0 * Q 1 1 - Q 0 1 * Q 1 0) ^ 2 = 1 := by
    linear_combination (Q 0 1 ^ 2 + Q 1 1 ^ 2) * h00 + h11 - (Q 0 0 * Q 0 1 + Q 1 0 * Q 1 1) * h01
  nlinarith [this, h]

/-! ### The card's worked numbers, checked exactly -/

-- A = [[1, 1], [-1, 3]]: trace 4, determinant 4.
example : (!![(1 : ℤ), 1; -1, 3]).trace = 4 := by simp [Matrix.trace, Fin.sum_univ_two]
example : (!![(1 : ℤ), 1; -1, 3]).det = 4 := by simp [Matrix.det_fin_two]

-- A - 2I = [[-1, 1], [-1, 1]], and A sends (1, 1) to (2, 2): eigenvalue 2, eigenvector (1, 1).
example : !![(1 : ℤ), 1; -1, 3] - 2 • (1 : Matrix (Fin 2) (Fin 2) ℤ) = !![-1, 1; -1, 1] := by
  decide
example : !![(1 : ℤ), 1; -1, 3] *ᵥ ![1, 1] = ![2, 2] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two]

-- The characteristic polynomial is λ² - 4λ + 4 = (λ - 2)²: the eigenvalue 2, twice.
example : (!![(1 : ℤ), 1; -1, 3]).charpoly = (X - C 2) ^ 2 := by
  rw [charpoly_fin_two]
  simp [Matrix.trace, Fin.sum_univ_two, Matrix.det_fin_two]
  ring

-- With unit axes (1, 1)/√2 and (1, -1)/√2, Q is orthogonal and Qᵀ A Q = [[2, -2], [0, 2]].
example : (Real.sqrt 2)⁻¹ • !![(1 : ℝ), 1; 1, -1] ∈ Matrix.orthogonalGroup (Fin 2) ℝ := by
  rw [mem_orthogonalGroup_iff']
  have h : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have h0 : Real.sqrt 2 ≠ 0 := by positivity
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> field_simp <;> linarith
example : ((Real.sqrt 2)⁻¹ • !![(1 : ℝ), 1; 1, -1])ᵀ * !![(1 : ℝ), 1; -1, 3] *
    ((Real.sqrt 2)⁻¹ • !![(1 : ℝ), 1; 1, -1]) = !![2, -2; 0, 2] := by
  have h : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have h0 : Real.sqrt 2 ≠ 0 := by positivity
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> field_simp <;> linarith

-- A^10 = [[-4096, 5120], [-5120, 6144]].
example : !![(1 : ℤ), 1; -1, 3] ^ 10 = !![-4096, 5120; -5120, 6144] := by decide

-- The quarter turn: complex axes (-1, i)/√2 and (-i, 1)/√2 give Q* R Q = [[i, 0], [0, -i]].
-- Without the 1/√2 the axes N have N* N = 2I and N* R N = [[2i, 0], [0, -2i]].
example : star !![(-1 : ℂ), -Complex.I; Complex.I, 1] * !![(-1 : ℂ), -Complex.I; Complex.I, 1]
    = 2 • (1 : Matrix (Fin 2) (Fin 2) ℂ) := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.star_eq_conjTranspose] <;> norm_num
example : star !![(-1 : ℂ), -Complex.I; Complex.I, 1] * !![(0 : ℂ), -1; 1, 0] *
    !![(-1 : ℂ), -Complex.I; Complex.I, 1] = !![2 * Complex.I, 0; 0, -2 * Complex.I] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.star_eq_conjTranspose] <;> ring

-- Mistake 1: axes (1, 1) and (1, 0), transpose used as inverse: [[4, 0], [2, 1]], diagonal sum 5.
example : (!![(1 : ℤ), 1; 1, 0])ᵀ * !![(1 : ℤ), 1; -1, 3] * !![(1 : ℤ), 1; 1, 0]
    = !![4, 0; 2, 1] := by decide

-- Mistake 2: axes not shrunk to length 1: [[4, -4], [0, 4]], diagonal 4 and 4.
example : (!![(1 : ℤ), 1; 1, -1])ᵀ * !![(1 : ℤ), 1; -1, 3] * !![(1 : ℤ), 1; 1, -1]
    = !![4, -4; 0, 4] := by decide

-- Squared entries: A gives 1 + 1 + 1 + 9 = 12, T gives 4 + 4 + 4 = 12.
example : (1 : ℤ) ^ 2 + 1 ^ 2 + (-1) ^ 2 + 3 ^ 2 = 12 ∧ (2 : ℤ) ^ 2 + (-2) ^ 2 + 0 ^ 2 + 2 ^ 2 = 12 := by
  norm_num

#print axioms schur_triangularisation
#print axioms schur_triangle_diagonal_is_eigenvalues
#print axioms quarter_turn_no_real_schur_triangle
