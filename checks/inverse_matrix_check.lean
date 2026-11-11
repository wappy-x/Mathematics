-- The inverse matrix: the 2 by 2 swap-flip-divide formula gives a matrix that undoes A from both sides whenever ps - qr is not zero, a square matrix over a field has an inverse exactly when its determinant is not zero (equivalently its columns are independent, equivalently only the zero vector goes to zero), and an inverse is unique.
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.TFAE

open Matrix

/-- The 2 by 2 formula. Take A = [[p, q], [r, s]] with entries from any number system where
nonzero numbers can be divided by (a field). If ps - qr is not zero, then swapping the main
diagonal, flipping the sign of the other two entries and dividing every entry by ps - qr gives
a matrix that undoes A from both sides: A times it is the identity I, and it times A is I.
So it is the inverse of A. -/
theorem two_by_two_inverse_is_swap_flip_divide {K : Type*} [Field K] (p q r s : K)
    (h : p * s - q * r ≠ 0) :
    !![p, q; r, s] * ((p * s - q * r)⁻¹ • !![s, -q; -r, p]) = 1 ∧
      ((p * s - q * r)⁻¹ • !![s, -q; -r, p]) * !![p, q; r, s] = 1 ∧
      (!![p, q; r, s])⁻¹ = (p * s - q * r)⁻¹ • !![s, -q; -r, p] := by
  have e1 : !![p, q; r, s] * !![s, -q; -r, p] = (p * s - q * r) • (1 : Matrix (Fin 2) (Fin 2) K) := by
    ext i j
    fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> ring
  have e2 : !![s, -q; -r, p] * !![p, q; r, s] = (p * s - q * r) • (1 : Matrix (Fin 2) (Fin 2) K) := by
    ext i j
    fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> ring
  have hmul : !![p, q; r, s] * ((p * s - q * r)⁻¹ • !![s, -q; -r, p]) = 1 := by
    rw [Matrix.mul_smul, e1, smul_smul, inv_mul_cancel₀ h, one_smul]
  refine ⟨hmul, ?_, Matrix.inv_eq_right_inv hmul⟩
  rw [Matrix.smul_mul, e2, smul_smul, inv_mul_cancel₀ h, one_smul]

/-- When an inverse exists. For a square matrix A of any size n, with entries from a field,
these four say the same thing, so if one fails all fail: A has a matrix B that undoes it from
both sides (A B = I and B A = I); the determinant of A is not zero; no column of A is a mix of
the other columns (the columns are linearly independent); and the only list x that A sends to
all zeros is the all-zero list. -/
theorem inverse_exists_iff_det_ne_zero {K : Type*} [Field K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K) :
    List.TFAE
      [∃ B : Matrix (Fin n) (Fin n) K, A * B = 1 ∧ B * A = 1,
       A.det ≠ 0,
       LinearIndependent K (fun j : Fin n => fun i : Fin n => A i j),
       ∀ x : Fin n → K, A *ᵥ x = 0 → x = 0] := by
  have h1 : (∃ B : Matrix (Fin n) (Fin n) K, A * B = 1 ∧ B * A = 1) ↔ IsUnit A := by
    constructor
    · rintro ⟨B, hAB, hBA⟩
      exact ⟨⟨A, B, hAB, hBA⟩, rfl⟩
    · intro hA
      have hd : IsUnit A.det := (Matrix.isUnit_iff_isUnit_det A).mp hA
      exact ⟨A⁻¹, Matrix.mul_nonsing_inv A hd, Matrix.nonsing_inv_mul A hd⟩
  have h2 : A.det ≠ 0 ↔ IsUnit A := by
    rw [Matrix.isUnit_iff_isUnit_det, isUnit_iff_ne_zero]
  have h3 : LinearIndependent K (fun j : Fin n => fun i : Fin n => A i j) ↔ IsUnit A :=
    Matrix.linearIndependent_col_iff_isUnit
  have h4 : (∀ x : Fin n → K, A *ᵥ x = 0 → x = 0) ↔ A.det ≠ 0 := by
    rw [Ne, ← Matrix.exists_mulVec_eq_zero_iff]
    constructor
    · rintro h ⟨v, hv, hAv⟩
      exact hv (h v hAv)
    · intro h x hx
      by_contra hne
      exact h ⟨x, hne, hx⟩
  tfae_have 1 ↔ 2 := h1.trans h2.symm
  tfae_have 2 ↔ 3 := h2.trans h3.symm
  tfae_have 4 ↔ 2 := h4
  tfae_finish

/-- At most one matrix undoes A. If B and C each undo the square matrix A from both sides,
then B and C are the same matrix, so "the" inverse is safe. -/
theorem inverse_matrix_is_unique {K : Type*} [Field K] {n : ℕ}
    (A B C : Matrix (Fin n) (Fin n) K)
    (hB : A * B = 1 ∧ B * A = 1) (hC : A * C = 1 ∧ C * A = 1) :
    B = C := by
  calc B = B * (A * C) := by rw [hC.1, Matrix.mul_one]
    _ = (B * A) * C := (Matrix.mul_assoc B A C).symm
    _ = C := by rw [hB.2, Matrix.one_mul]

-- The cafe: counts [[2, 1], [1, 1]] have determinant 2 x 1 - 1 x 1 = 1.
example : Matrix.det !![(2 : ℚ), 1; 1, 1] = 1 := by norm_num [Matrix.det_fin_two_of]
-- Its inverse [[1, -1], [-1, 2]] undoes it from both sides.
example : !![(2 : ℚ), 1; 1, 1] * !![1, -1; -1, 2] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : !![(1 : ℚ), -1; -1, 2] * !![2, 1; 1, 1] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Swap, flip and divide by the determinant 1 gives exactly that matrix.
example : ((2 : ℚ) * 1 - 1 * 1)⁻¹ • !![(1 : ℚ), -1; -1, 2] = !![1, -1; -1, 2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num
-- Prices (4, 3) give takings (11, 7), and the inverse sends (11, 7) back to (4, 3).
example : !![(2 : ℚ), 1; 1, 1] *ᵥ ![4, 3] = ![11, 7] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(1 : ℚ), -1; -1, 2] *ᵥ ![11, 7] = ![4, 3] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Cramer's rule: det [[11, 1], [7, 1]] = 4 (the coffee), det [[2, 11], [1, 7]] = 3 (the pastry).
example : Matrix.det !![(11 : ℚ), 1; 7, 1] = 4 := by norm_num [Matrix.det_fin_two_of]
example : Matrix.det !![(2 : ℚ), 11; 1, 7] = 3 := by norm_num [Matrix.det_fin_two_of]
-- The singular [[2, 4], [1, 2]]: determinant 0, and swap-and-flip times it is all zeros.
example : Matrix.det !![(2 : ℚ), 4; 1, 2] = 0 := by norm_num [Matrix.det_fin_two_of]
example : !![(2 : ℚ), -4; -1, 2] * !![2, 4; 1, 2] = 0 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Three items: [[2, 1, 1], [1, 1, 1], [1, 2, 1]] has determinant -1 and inverse
-- [[1, -1, 0], [0, -1, 1], [-1, 3, -1]], which sends takings (17, 13, 16) to prices (4, 3, 6).
example : Matrix.det !![(2 : ℚ), 1, 1; 1, 1, 1; 1, 2, 1] = -1 := by
  norm_num [Matrix.det_fin_three]
example : !![(2 : ℚ), 1, 1; 1, 1, 1; 1, 2, 1] * !![1, -1, 0; 0, -1, 1; -1, 3, -1] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_succ]
example : !![(1 : ℚ), -1, 0; 0, -1, 1; -1, 3, -1] *ᵥ ![17, 13, 16] = ![4, 3, 6] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_succ]
-- The mistakes: no swap gives (15, -4); no minus signs gives (18, 25); skipping the divide by
-- -1 on the three items gives (-4, -3, -6).
example : !![(2 : ℚ), -1; -1, 1] *ᵥ ![11, 7] = ![15, -4] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(1 : ℚ), 1; 1, 2] *ᵥ ![11, 7] = ![18, 25] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : ((-1 : ℚ) • !![(1 : ℚ), -1, 0; 0, -1, 1; -1, 3, -1]) *ᵥ ![17, 13, 16] = ![-4, -3, -6] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_succ]
-- Try changing: takings (13, 8) give prices (5, 3) with the same inverse.
example : !![(1 : ℚ), -1; -1, 2] *ᵥ ![13, 8] = ![5, 3] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- On a 4-hour clock, 2 is not zero, yet nothing multiplies it to 1.
example : (2 : ZMod 4) ≠ 0 ∧ ∀ x : ZMod 4, 2 * x ≠ 1 := by decide

#print axioms two_by_two_inverse_is_swap_flip_divide
#print axioms inverse_exists_iff_det_ne_zero
#print axioms inverse_matrix_is_unique
