-- The spectral theorem: every real square matrix equal to its own transpose can be written as Q D Qᵀ with Qᵀ Q = I and D diagonal, its eigenvectors for different eigenvalues are perpendicular, its eigenvalues are real, and the card's table [[2, 1], [1, 2]] splits along (1, 1) and (1, -1) with factors 3 and 1.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.Tactic.NormNum

open Matrix

/-- The spectral theorem. For every size `n`, every `n × n` matrix `A` of real numbers that
equals its own transpose can be written as `A = Q D Qᵀ`, where `Q` is a real matrix whose
columns are perpendicular and one unit long (`Qᵀ Q = I`) and `D` is a diagonal matrix of real
stretch factors `d`. -/
theorem symmetric_matrix_eq_orthogonal_diagonal_orthogonal_transpose (n : ℕ)
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : Aᵀ = A) :
    ∃ (Q : Matrix (Fin n) (Fin n) ℝ) (d : Fin n → ℝ),
      Qᵀ * Q = 1 ∧ A = Q * diagonal d * Qᵀ := by
  have hH : A.IsHermitian := by
    rw [Matrix.IsHermitian, Matrix.conjTranspose_eq_transpose_of_trivial]; exact hA
  refine ⟨((hH.eigenvectorUnitary : Matrix.unitaryGroup (Fin n) ℝ) : Matrix (Fin n) (Fin n) ℝ),
    hH.eigenvalues, ?_, ?_⟩
  · have h := Unitary.coe_star_mul_self (hH.eigenvectorUnitary)
    rwa [Matrix.star_eq_conjTranspose, Matrix.conjTranspose_eq_transpose_of_trivial] at h
  · have h := hH.spectral_theorem
    rw [Unitary.conjStarAlgAut_apply] at h
    simp only [Matrix.star_eq_conjTranspose, Matrix.conjTranspose_eq_transpose_of_trivial] at h
    simpa using h

/-- Step 1 of the card: two different factors force a right angle. If a real matrix `A`
equals its own transpose, keeps `v` on its line with factor `λ` and keeps `w` on its line with
factor `μ`, and `λ ≠ μ`, then `v · w = 0`. -/
theorem symmetric_eigenvectors_of_different_eigenvalues_perpendicular (n : ℕ)
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : Aᵀ = A) (v w : Fin n → ℝ) (l m : ℝ)
    (hv : A *ᵥ v = l • v) (hw : A *ᵥ w = m • w) (hlm : l ≠ m) :
    v ⬝ᵥ w = 0 := by
  have h1 : v ⬝ᵥ (A *ᵥ w) = (A *ᵥ v) ⬝ᵥ w := by
    rw [Matrix.dotProduct_mulVec]
    conv_lhs => rw [← hA]
    rw [Matrix.vecMul_transpose]
  rw [hw, hv] at h1
  simp only [dotProduct_smul, smul_dotProduct, smul_eq_mul] at h1
  have h2 : (m - l) * (v ⬝ᵥ w) = 0 := by linarith
  rcases mul_eq_zero.mp h2 with h | h
  · exact absurd (by linarith) hlm
  · exact h

/-- The stretch factors are real. If a real matrix `A` equals its own transpose, then every
eigenvalue it has, even when complex numbers are allowed as factors and as vector entries,
has imaginary part zero. -/
theorem symmetric_matrix_eigenvalues_are_real (n : ℕ)
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : Aᵀ = A) (μ : ℂ) (v : Fin n → ℂ) (hv0 : v ≠ 0)
    (hv : (A.map (fun x : ℝ => (x : ℂ))) *ᵥ v = μ • v) :
    μ.im = 0 := by
  set B : Matrix (Fin n) (Fin n) ℂ := A.map (fun x : ℝ => (x : ℂ)) with hB
  have hBH : Bᴴ = B := by
    ext i j
    have h : A j i = A i j := by
      have := congrFun (congrFun hA i) j
      simpa [Matrix.transpose_apply] using this
    simp [hB, Matrix.conjTranspose_apply, h]
  have h1 : star v ⬝ᵥ (B *ᵥ v) = star (B *ᵥ v) ⬝ᵥ v := by
    rw [Matrix.star_mulVec, hBH, Matrix.dotProduct_mulVec]
  rw [hv] at h1
  have hs : star v ⬝ᵥ v ≠ 0 := by
    open scoped ComplexOrder in
    exact fun h => hv0 (dotProduct_star_self_eq_zero.mp h)
  have h2 : (μ - star μ) * (star v ⬝ᵥ v) = 0 := by
    simp only [dotProduct_smul, star_smul, smul_dotProduct, smul_eq_mul] at h1
    linear_combination h1
  have h3 : μ - star μ = 0 := (mul_eq_zero.mp h2).resolve_right hs
  have h4 := congrArg Complex.im h3
  simp at h4
  linarith

-- The card's table: rows (2, 1) and (1, 2), equal to its own transpose.
example : (!![2, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℝ)ᵀ = !![2, 1; 1, 2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num
-- "Both up together", (1, 1), comes out as (3, 3): factor 3.
example : (!![2, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℝ) *ᵥ ![1, 1] = (3 : ℝ) • ![1, 1] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_two]
-- "One up, one down", (1, -1), comes out untouched: factor 1.
example : (!![2, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℝ) *ᵥ ![1, -1] = (1 : ℝ) • ![1, -1] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_two]
-- The two axes meet at a right angle: (1, 1) · (1, -1) = 0.
example : (![1, 1] : Fin 2 → ℝ) ⬝ᵥ ![1, -1] = 0 := by
  norm_num [dotProduct, Fin.sum_univ_two]
-- Trace 4 and determinant 3, so the factors solve L² - 4L + 3 = 0: L = 3 and L = 1.
example : (2 : ℝ) + 2 = 4 ∧ (2 : ℝ) * 2 - 1 * 1 = 3 := by norm_num
example : (3 : ℝ) ^ 2 - 4 * 3 + 3 = 0 ∧ (1 : ℝ) ^ 2 - 4 * 1 + 3 = 0 := by norm_num
-- Under the square root: (a - d)² + 4b² = (2 - 2)² + 4 · 1² = 4.
example : ((2 : ℝ) - 2) ^ 2 + 4 * 1 ^ 2 = 4 := by norm_num
-- The mix (4, 2) goes to (10, 8).
example : (!![2, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℝ) *ᵥ ![4, 2] = ![10, 8] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_two]
-- Q D Qᵀ rebuilds the table. Q is R / √2 with R having columns (1, 1) and (1, -1), so
-- Q D Qᵀ = (1/2) R D Rᵀ, and that is exactly rows (2, 1) and (1, 2).
example : (1 / 2 : ℝ) • (!![1, 1; 1, -1] * !![3, 0; 0, 1] * (!![1, 1; 1, -1])ᵀ :
    Matrix (Fin 2) (Fin 2) ℝ) = !![2, 1; 1, 2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two, vecMul, dotProduct]
-- Qᵀ Q = I, in the same form: (1/2) Rᵀ R = I.
example : (1 / 2 : ℝ) • ((!![1, 1; 1, -1])ᵀ * !![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℝ) = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two, vecMul, dotProduct]
-- Mistake: the raw axes as Q, without shrinking, give rows (4, 2) and (2, 4), twice the table.
example : (!![1, 1; 1, -1] * !![3, 0; 0, 1] * (!![1, 1; 1, -1])ᵀ : Matrix (Fin 2) (Fin 2) ℝ) =
    !![4, 2; 2, 4] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two, vecMul, dotProduct]
-- Mistake: 3 and 1 swapped in D alone give rows (2, -1) and (-1, 2).
example : (1 / 2 : ℝ) • (!![1, 1; 1, -1] * !![1, 0; 0, 3] * (!![1, 1; 1, -1])ᵀ :
    Matrix (Fin 2) (Fin 2) ℝ) = !![2, -1; -1, 2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two, vecMul, dotProduct]

#print axioms symmetric_matrix_eq_orthogonal_diagonal_orthogonal_transpose
#print axioms symmetric_eigenvectors_of_different_eigenvalues_perpendicular
#print axioms symmetric_matrix_eigenvalues_are_real
