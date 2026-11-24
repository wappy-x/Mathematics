-- Cramer's rule: each unknown of a square system with nonzero determinant is det A_j over det A, A adj(A) = adj(A) A = (det A) I, and the inverse is the flipped cofactor table over det A.
import Mathlib.LinearAlgebra.Matrix.Adjugate
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse

open Matrix

/-- Cramer's rule: for a square system `A x = b` whose determinant is not zero, unknown `j` is the
determinant of `A` with `b` put in column `j`, divided by the determinant of `A`. -/
theorem cramers_rule {K : Type*} [Field K] {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n K) (b x : n → K) (hA : A.det ≠ 0) (hx : A *ᵥ x = b) (j : n) :
    x j = (A.updateCol j b).det / A.det := by
  have hu : IsUnit A.det := isUnit_iff_ne_zero.mpr hA
  have hxb : x = A⁻¹ *ᵥ b := by
    rw [← hx, mulVec_mulVec, nonsing_inv_mul A hu, one_mulVec]
  have h := congrFun (det_smul_inv_mulVec_eq_cramer A b hu) j
  rw [cramer_apply, ← hxb, Pi.smul_apply, smul_eq_mul] at h
  rw [eq_div_iff hA, ← h, mul_comm]

/-- The counts times their adjugate, in either order, is the determinant times the identity.
It uses only multiplying, adding and subtracting, so it holds for whole numbers too. -/
theorem mul_adjugate_eq_det_smul_one {R : Type*} [CommRing R] {n : Type*} [Fintype n]
    [DecidableEq n] (A : Matrix n n R) :
    A * adjugate A = A.det • (1 : Matrix n n R) ∧ adjugate A * A = A.det • (1 : Matrix n n R) := by
  exact ⟨mul_adjugate A, adjugate_mul A⟩

/-- When the determinant is not zero, entry `(i, j)` of the inverse is the cofactor `C_ji`
(the minor with row `j` and column `i` crossed out, with checkerboard sign `(-1)^(j+i)`),
divided by the determinant: the flipped cofactor table over `det A`. -/
theorem inv_eq_flipped_cofactors_div_det {K : Type*} [Field K] {n : ℕ}
    (A : Matrix (Fin (n + 1)) (Fin (n + 1)) K) (hA : A.det ≠ 0) (i j : Fin (n + 1)) :
    A⁻¹ i j = (-1) ^ ((j : ℕ) + (i : ℕ)) * (A.submatrix j.succAbove i.succAbove).det / A.det := by
  rw [inv_def, Ring.inverse_eq_inv', Matrix.smul_apply, adjugate_fin_succ_eq_det_submatrix,
    smul_eq_mul, div_eq_mul_inv, mul_comm]

-- The cafe: counts A, takings (13, 11, 12).  det A = -4.
example : (!![2, 1, 1; 1, 1, 2; 1, 2, 1] : Matrix (Fin 3) (Fin 3) ℤ).det = -4 := by
  norm_num [Matrix.det_fin_three]

-- Takings swapped into the coffee, pastry and juice columns: determinants -16, -12, -8.
example : ((!![2, 1, 1; 1, 1, 2; 1, 2, 1] : Matrix (Fin 3) (Fin 3) ℤ).updateCol 0 ![13, 11, 12]).det
    = -16 := by
  norm_num [Matrix.det_fin_three, Matrix.updateCol_apply]

example : ((!![2, 1, 1; 1, 1, 2; 1, 2, 1] : Matrix (Fin 3) (Fin 3) ℤ).updateCol 1 ![13, 11, 12]).det
    = -12 := by
  norm_num [Matrix.det_fin_three, Matrix.updateCol_apply]

example : ((!![2, 1, 1; 1, 1, 2; 1, 2, 1] : Matrix (Fin 3) (Fin 3) ℤ).updateCol 2 ![13, 11, 12]).det
    = -8 := by
  norm_num [Matrix.det_fin_three, Matrix.updateCol_apply]

-- The prices (4, 3, 2) give the takings.
example : (!![2, 1, 1; 1, 1, 2; 1, 2, 1] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![4, 3, 2] = ![13, 11, 12] := by
  ext i; fin_cases i <;> rfl

-- The adjugate is [[-3, 1, 1], [1, 1, -3], [1, -3, 1]].
example : adjugate (!![2, 1, 1; 1, 1, 2; 1, 2, 1] : Matrix (Fin 3) (Fin 3) ℤ)
    = !![-3, 1, 1; 1, 1, -3; 1, -3, 1] := by
  rw [Matrix.adjugate_fin_three]; norm_num

-- adj(A) b = (-16, -12, -8).
example : adjugate (!![2, 1, 1; 1, 1, 2; 1, 2, 1] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![13, 11, 12]
    = ![-16, -12, -8] := by
  rw [Matrix.adjugate_fin_three]
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three]

#print axioms cramers_rule
#print axioms mul_adjugate_eq_det_smul_one
#print axioms inv_eq_flipped_cofactors_div_det
