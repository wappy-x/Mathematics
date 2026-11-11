-- Eigenvalues and eigenvectors: a number is an eigenvalue of a 2 by 2 real matrix [[a, b], [c, d]] exactly when it solves the quadratic lambda^2 - (a + d) lambda + (ad - bc) = 0, at every size a number is an eigenvalue exactly when det (A - lambda I) = 0, and when the discriminant is not negative the two roots of the quadratic are eigenvalues that add to the trace and multiply to the determinant; the card's rental-fleet numbers are checked exactly.
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith

open Matrix

theorem det_shift_helper {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (lam : ℝ) :
    (∃ v : Fin n → ℝ, v ≠ 0 ∧ A *ᵥ v = lam • v) ↔ (A - lam • (1 : Matrix (Fin n) (Fin n) ℝ)).det = 0 := by
  rw [← Matrix.exists_mulVec_eq_zero_iff]
  refine exists_congr fun v => and_congr_right fun _ => ?_
  rw [Matrix.sub_mulVec, Matrix.smul_mulVec, Matrix.one_mulVec, sub_eq_zero]

#print axioms det_shift_helper

/-- The card's theorem. Take any 2 by 2 matrix of real numbers, `[[a, b], [c, d]]`, and any real
number `lam`. Some pattern `v` that is not all zeros comes back from the matrix as `lam` times
itself (`A v = lam v`, so `lam` is an eigenvalue) exactly when `lam` solves the characteristic
quadratic `lam^2 - (a + d) lam + (ad - bc) = 0`: lambda squared, minus the trace times lambda,
plus the determinant. -/
theorem eigenvalue_iff_root_of_characteristic_quadratic (a b c d lam : ℝ) :
    (∃ v : Fin 2 → ℝ, v ≠ 0 ∧ !![a, b; c, d] *ᵥ v = lam • v) ↔
      lam ^ 2 - (a + d) * lam + (a * d - b * c) = 0 := by
  rw [det_shift_helper, Matrix.det_fin_two]
  simp
  constructor <;> intro h <;> nlinarith [h]

/-- Step 0 and Step 1, the determinant test. For a square matrix `A` of real numbers of any
size `n`, a number `lam` is an eigenvalue (some pattern `v`, not all zeros, has `A v = lam v`)
exactly when the shift `A - lam I`, the matrix with `lam` taken off every diagonal entry,
has determinant zero: it flattens the space. -/
theorem eigenvalue_iff_det_shift_eq_zero {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (lam : ℝ) :
    (∃ v : Fin n → ℝ, v ≠ 0 ∧ A *ᵥ v = lam • v) ↔ (A - lam • (1 : Matrix (Fin n) (Fin n) ℝ)).det = 0 := by
  exact det_shift_helper A lam

/-- Step 2 and Step 4. Take a 2 by 2 real matrix `[[a, b], [c, d]]` whose discriminant
`(a + d)^2 - 4 (ad - bc)` is zero or more. The quadratic formula's two roots,
`((a + d) + root) / 2` and `((a + d) - root) / 2`, are both eigenvalues of the matrix, they add
to the trace `a + d`, and they multiply to the determinant `ad - bc`. -/
theorem quadratic_roots_are_eigenvalues_summing_to_trace_and_multiplying_to_det
    (a b c d : ℝ) (hdisc : 0 ≤ (a + d) ^ 2 - 4 * (a * d - b * c)) :
    let r := Real.sqrt ((a + d) ^ 2 - 4 * (a * d - b * c))
    let lam1 := ((a + d) + r) / 2
    let lam2 := ((a + d) - r) / 2
    (∃ v : Fin 2 → ℝ, v ≠ 0 ∧ !![a, b; c, d] *ᵥ v = lam1 • v) ∧
      (∃ v : Fin 2 → ℝ, v ≠ 0 ∧ !![a, b; c, d] *ᵥ v = lam2 • v) ∧
      lam1 + lam2 = Matrix.trace !![a, b; c, d] ∧
      lam1 * lam2 = Matrix.det !![a, b; c, d] := by
  intro r lam1 lam2
  have hr : r ^ 2 = (a + d) ^ 2 - 4 * (a * d - b * c) := Real.sq_sqrt hdisc
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [eigenvalue_iff_root_of_characteristic_quadratic]
    simp only [lam1]
    nlinarith [hr]
  · rw [eigenvalue_iff_root_of_characteristic_quadratic]
    simp only [lam2]
    nlinarith [hr]
  · rw [Matrix.trace_fin_two_of]
    simp only [lam1, lam2]; ring
  · rw [Matrix.det_fin_two_of]
    simp only [lam1, lam2]; nlinarith [hr]

-- The fleet matrix [[0.8, 0.3], [0.2, 0.7]], written exactly as fractions: [[4/5, 3/10], [1/5, 7/10]].
-- Trace 1.5 = 3/2 and determinant 0.5 = 1/2.
example : Matrix.trace !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] = 3 / 2 := by
  norm_num [Matrix.trace_fin_two_of]
example : Matrix.det !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] = 1 / 2 := by
  norm_num [Matrix.det_fin_two_of]
-- Discriminant 1.5 x 1.5 - 4 x 0.5 = 0.25 = 1/4, and the roots (1.5 +- 0.5) / 2 are 1 and 1/2.
example : (3 / 2 : ℚ) ^ 2 - 4 * (1 / 2) = 1 / 4 := by norm_num
example : ((3 / 2 : ℚ) + 1 / 2) / 2 = 1 ∧ ((3 / 2 : ℚ) - 1 / 2) / 2 = 1 / 2 := by norm_num
-- Both roots solve lambda^2 - 1.5 lambda + 0.5 = 0.
example : (1 : ℚ) ^ 2 - 3 / 2 * 1 + 1 / 2 = 0 := by norm_num
example : (1 / 2 : ℚ) ^ 2 - 3 / 2 * (1 / 2) + 1 / 2 = 0 := by norm_num
-- They add to the trace and multiply to the determinant: 1 + 0.5 = 1.5, 1 x 0.5 = 0.5.
example : (1 : ℚ) + 1 / 2 = 3 / 2 ∧ (1 : ℚ) * (1 / 2) = 1 / 2 := by norm_num
-- The shift for 1 is [[-0.2, 0.3], [0.2, -0.3]] and it kills (3, 2): A (3, 2) = (3, 2).
example : !![(4 / 5 : ℚ) - 1, 3 / 10; 1 / 5, 7 / 10 - 1] *ᵥ ![3, 2] = 0 := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] *ᵥ ![3, 2] = ![3, 2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The shift for 0.5 is [[0.3, 0.3], [0.2, 0.2]] and it kills (1, -1): A (1, -1) = 0.5 (1, -1).
example : !![(4 / 5 : ℚ) - 1 / 2, 3 / 10; 1 / 5, 7 / 10 - 1 / 2] *ᵥ ![1, -1] = 0 := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] *ᵥ ![1, -1] = (1 / 2 : ℚ) • ![1, -1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The steady fleet: 600 in A and 400 in B stays 600 and 400.
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] *ᵥ ![600, 400] = ![600, 400] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- All 1000 in A: 800 and 200 after one month, 700 and 300 after two, 650 and 350 after three,
-- 625 and 375 after four; the gap above 600 halves each month: 400, 200, 100, 50, 25.
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] *ᵥ ![1000, 0] = ![800, 200] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] *ᵥ ![800, 200] = ![700, 300] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] *ᵥ ![700, 300] = ![650, 350] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] *ᵥ ![650, 350] = ![625, 375] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The guessed split (3, -2) goes to (1.8, -0.8) = (9/5, -4/5): not a multiple of (3, -2).
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] *ᵥ ![3, -2] = ![9 / 5, -4 / 5] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : ¬ ∃ t : ℚ, ![(9 / 5 : ℚ), -4 / 5] = t • ![3, -2] := by
  rintro ⟨t, ht⟩
  have h0 := congrFun ht 0
  have h1 := congrFun ht 1
  simp at h0 h1
  linarith
-- Cayley-Hamilton at size 2: A A - 1.5 A + 0.5 I is the zero matrix.
example : !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] * !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10]
    - (3 / 2 : ℚ) • !![(4 / 5 : ℚ), 3 / 10; 1 / 5, 7 / 10] + (1 / 2 : ℚ) • (1 : Matrix (Fin 2) (Fin 2) ℚ)
    = 0 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- The mistakes: ad + bc as the determinant gives discriminant -0.23 = -23/100; the diagonal
-- entries 0.8 and 0.7 multiply to 0.56 = 14/25, not 1/2; lambda off the top-left only leaves
-- the straight line (0.8 - lambda) 0.7 - 0.06 = 0 with the one root 0.5 / 0.7 = 5/7.
example : (3 / 2 : ℚ) ^ 2 - 4 * ((4 / 5) * (7 / 10) + (3 / 10) * (1 / 5)) = -23 / 100 := by norm_num
example : (4 / 5 : ℚ) * (7 / 10) = 14 / 25 := by norm_num
example : ((4 / 5 : ℚ) - 5 / 7) * (7 / 10) - (3 / 10) * (1 / 5) = 0 := by norm_num

#print axioms eigenvalue_iff_root_of_characteristic_quadratic
#print axioms eigenvalue_iff_det_shift_eq_zero
#print axioms quadratic_roots_are_eigenvalues_summing_to_trace_and_multiplying_to_det
