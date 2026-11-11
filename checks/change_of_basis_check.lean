-- Change of basis: if n new directions in n-dimensional space are independent and sit down the columns of a matrix P, then P turns a new address into the old one, P inverse turns an old address into the unique new one, a linear map with matrix A has matrix P^-1 A P in the new basis (so both routes move a point to the same place, and trace and determinant do not change), and the card's treasure numbers come out as it says.
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum

open Matrix

/-! A point's address is a column of `n` real numbers, `Fin n → ℝ`. The new directions are the
columns of the square matrix `P`: direction number `j` is `fun i => P i j`. "The new directions
are independent" is Mathlib's `LinearIndependent ℝ` of those columns. `P *ᵥ c` is `P` times the
column `c`, and `P⁻¹` is Mathlib's inverse. A linear movement rule with matrix `A` (in the old,
standard book) is `Matrix.toLin' A`, and `LinearMap.toMatrix b b f` is Mathlib's matrix of a
linear map `f` in the basis `b`: its column `j` is the new address of where `f` sends direction
`j`. Both books share the origin because addresses are plain columns with no shift. -/

/-- Change of basis. Take `n` new directions in `n`-dimensional space and put them down the
columns of a matrix `P`. If the directions are independent, they form a basis `b`, and:
an old address `v` and a new address `c` name the same point exactly when `c = P⁻¹ v`
(so `P` turns a new address into the old one, `P⁻¹` goes back, and each point has exactly one
new address); the new address that the basis itself assigns to `v` is `P⁻¹ v`; and a linear map
whose matrix in the old book is `A` has matrix `P⁻¹ A P` in the new book. -/
theorem change_of_basis_is_p_inverse_a_p {n : ℕ} (P A : Matrix (Fin n) (Fin n) ℝ)
    (hP : LinearIndependent ℝ (fun j : Fin n => fun i : Fin n => P i j)) :
    let b : Module.Basis (Fin n) ℝ (Fin n → ℝ) :=
      basisOfLinearIndependentOfCardEqFinrank' (fun j : Fin n => fun i : Fin n => P i j) hP
        (by rw [Module.finrank_fin_fun, Fintype.card_fin])
    (∀ v c : Fin n → ℝ, P *ᵥ c = v ↔ c = P⁻¹ *ᵥ v) ∧
      (∀ v : Fin n → ℝ, ⇑(b.repr v) = P⁻¹ *ᵥ v) ∧
      LinearMap.toMatrix b b (Matrix.toLin' A) = P⁻¹ * A * P := by
  intro b
  have hU : IsUnit P := by
    rw [← Matrix.linearIndependent_col_iff_isUnit]
    exact hP
  have hdet : IsUnit P.det := (Matrix.isUnit_iff_isUnit_det P).mp hU
  have hinvP : P⁻¹ * P = 1 := Matrix.nonsing_inv_mul P hdet
  have hPinv : P * P⁻¹ = 1 := Matrix.mul_nonsing_inv P hdet
  have hb : ∀ j, b j = fun i => P i j := by
    intro j
    simp [b]
  have hrepr : ∀ v : Fin n → ℝ, P *ᵥ (b.repr v) = v := by
    intro v
    conv_rhs => rw [← b.sum_repr v]
    ext i
    simp [Matrix.mulVec, dotProduct, hb, Finset.sum_apply, mul_comm]
  have hrepr' : ∀ v : Fin n → ℝ, ⇑(b.repr v) = P⁻¹ *ᵥ v := by
    intro v
    conv_rhs => rw [← hrepr v]
    rw [Matrix.mulVec_mulVec, hinvP, Matrix.one_mulVec]
  refine ⟨?_, hrepr', ?_⟩
  · intro v c
    constructor
    · intro h
      rw [← h, Matrix.mulVec_mulVec, hinvP, Matrix.one_mulVec]
    · intro h
      rw [h, Matrix.mulVec_mulVec, hPinv, Matrix.one_mulVec]
  · ext i j
    rw [LinearMap.toMatrix_apply, hrepr']
    have : b j = P *ᵥ (Pi.single j 1) := by
      rw [hb]
      ext k
      simp [Matrix.mulVec, dotProduct, Pi.single_apply]
    rw [this]
    simp [Matrix.mul_apply, Matrix.mulVec, dotProduct]
    simp only [Finset.mul_sum, Finset.sum_mul]
    rw [Finset.sum_comm]
    simp only [mul_assoc]

/-- Both roads agree. With independent new directions down the columns of `P`, take any point
with old address `v`. Moving it by `A` and then reading its new address gives the same answer
as reading its new address first and then moving it by `P⁻¹ A P`. -/
theorem both_roads_give_the_same_point {n : ℕ} (P A : Matrix (Fin n) (Fin n) ℝ)
    (hP : LinearIndependent ℝ (fun j : Fin n => fun i : Fin n => P i j)) (v : Fin n → ℝ) :
    P⁻¹ *ᵥ (A *ᵥ v) = (P⁻¹ * A * P) *ᵥ (P⁻¹ *ᵥ v) := by
  have hU : IsUnit P := by
    rw [← Matrix.linearIndependent_col_iff_isUnit]
    exact hP
  have hdet : IsUnit P.det := (Matrix.isUnit_iff_isUnit_det P).mp hU
  have hPinv : P * P⁻¹ = 1 := Matrix.mul_nonsing_inv P hdet
  have hinvP : P⁻¹ * P = 1 := Matrix.nonsing_inv_mul P hdet
  rw [Matrix.mulVec_mulVec, Matrix.mulVec_mulVec]
  simp only [Matrix.mul_assoc, hPinv, Matrix.mul_one]

/-- What an address book cannot change. With independent new directions down the columns of
`P`, the rewritten matrix `P⁻¹ A P` has the same area factor (determinant) and the same trace
(sum down the main diagonal) as `A`. -/
theorem change_of_basis_keeps_det_and_trace {n : ℕ} (P A : Matrix (Fin n) (Fin n) ℝ)
    (hP : LinearIndependent ℝ (fun j : Fin n => fun i : Fin n => P i j)) :
    (P⁻¹ * A * P).det = A.det ∧ (P⁻¹ * A * P).trace = A.trace := by
  have hU : IsUnit P := by
    rw [← Matrix.linearIndependent_col_iff_isUnit]
    exact hP
  have hdet : IsUnit P.det := (Matrix.isUnit_iff_isUnit_det P).mp hU
  have hPinv : P * P⁻¹ = 1 := Matrix.mul_nonsing_inv P hdet
  have hinvP : P⁻¹ * P = 1 := Matrix.nonsing_inv_mul P hdet
  constructor
  · rw [Matrix.det_mul, Matrix.det_mul, mul_right_comm, ← Matrix.det_mul, hinvP]
    simp
  · rw [Matrix.trace_mul_comm, ← Matrix.mul_assoc, hPinv, Matrix.one_mul]

-- P = [[1, -1], [1, 1]] (columns (1, 1) and (-1, 1)) has det 1 × 1 - (-1) × 1 = 2.
example : Matrix.det !![(1 : ℚ), -1; 1, 1] = 2 := by norm_num [Matrix.det_fin_two_of]
-- P inverse is [[1/2, 1/2], [-1/2, 1/2]] (the card's 0.5 entries, written exactly).
example : (!![(1 : ℚ), -1; 1, 1])⁻¹ = !![1/2, 1/2; -1/2, 1/2] := by
  rw [Matrix.inv_def, Matrix.adjugate_fin_two_of, Matrix.det_fin_two_of]
  ext i j; fin_cases i <;> fin_cases j <;> norm_num
example : !![(1 : ℚ), -1; 1, 1] * !![1/2, 1/2; -1/2, 1/2] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- P times (1, 0) is the first new direction (1, 1).
example : !![(1 : ℚ), -1; 1, 1] *ᵥ ![1, 0] = ![1, 1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The treasure: P inverse sends (5, 3) to (4, -1), and P sends (4, -1) back to (5, 3).
example : !![(1/2 : ℚ), 1/2; -1/2, 1/2] *ᵥ ![5, 3] = ![4, -1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(1 : ℚ), -1; 1, 1] *ᵥ ![4, -1] = ![5, 3] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The shear [[1, 1], [0, 1]] sends the new directions to (2, 1) and (0, 1): A P = [[2, 0], [1, 1]].
example : !![(1 : ℚ), 1; 0, 1] * !![1, -1; 1, 1] = !![2, 0; 1, 1] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- P^-1 A P = [[3/2, 1/2], [-1/2, 1/2]] (the card's 1.5 and 0.5), with trace 2 and determinant 1.
example : !![(1/2 : ℚ), 1/2; -1/2, 1/2] * !![1, 1; 0, 1] * !![1, -1; 1, 1] =
    !![3/2, 1/2; -1/2, 1/2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : Matrix.trace !![(3/2 : ℚ), 1/2; -1/2, 1/2] = 2 ∧
    Matrix.det !![(3/2 : ℚ), 1/2; -1/2, 1/2] = 1 := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]
example : Matrix.trace !![(1 : ℚ), 1; 0, 1] = 2 ∧ Matrix.det !![(1 : ℚ), 1; 0, 1] = 1 := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]
-- Road one: the shear sends (5, 3) to (8, 3), whose new address is (11/2, -5/2).
-- Road two: the rewritten shear sends (4, -1) to the same (11/2, -5/2).
example : !![(1 : ℚ), 1; 0, 1] *ᵥ ![5, 3] = ![8, 3] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(1/2 : ℚ), 1/2; -1/2, 1/2] *ᵥ ![8, 3] = ![11/2, -5/2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(3/2 : ℚ), 1/2; -1/2, 1/2] *ᵥ ![4, -1] = ![11/2, -5/2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The second treasure (2, 6): new address (4, 2); sheared to (8, 6), new address (7, -1);
-- the rewritten shear sends (4, 2) to (7, -1) too.
example : !![(1/2 : ℚ), 1/2; -1/2, 1/2] *ᵥ ![2, 6] = ![4, 2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(1 : ℚ), 1; 0, 1] *ᵥ ![2, 6] = ![8, 6] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(1/2 : ℚ), 1/2; -1/2, 1/2] *ᵥ ![8, 6] = ![7, -1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(3/2 : ℚ), 1/2; -1/2, 1/2] *ᵥ ![4, 2] = ![7, -1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The mistakes: P v instead of P^-1 v gives (2, 8); the directions as rows, [[1, 1], [-1, 1]],
-- whose inverse is [[1/2, -1/2], [1/2, 1/2]], give (1, 4); the backwards sandwich P A P^-1
-- sends (4, -1) to (3/2, -7/2).
example : !![(1 : ℚ), -1; 1, 1] *ᵥ ![5, 3] = ![2, 8] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(1 : ℚ), 1; -1, 1] * !![1/2, -1/2; 1/2, 1/2] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : !![(1/2 : ℚ), -1/2; 1/2, 1/2] *ᵥ ![5, 3] = ![1, 4] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (!![(1 : ℚ), -1; 1, 1] * !![1, 1; 0, 1] * !![1/2, 1/2; -1/2, 1/2]) *ᵥ ![4, -1] =
    ![3/2, -7/2] := by
  ext i; fin_cases i <;>
    norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two, Matrix.mul_apply]
-- Two directions on one line, (1, 1) and (2, 2): area factor 1 × 2 - 2 × 1 = 0, no inverse.
example : Matrix.det !![(1 : ℚ), 2; 1, 2] = 0 := by norm_num [Matrix.det_fin_two_of]
-- Try changing: the treasure moved to (1, 1) has new address (1, 0).
example : !![(1/2 : ℚ), 1/2; -1/2, 1/2] *ᵥ ![1, 1] = ![1, 0] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]

#print axioms change_of_basis_is_p_inverse_a_p
#print axioms both_roads_give_the_same_point
#print axioms change_of_basis_keeps_det_and_trace
