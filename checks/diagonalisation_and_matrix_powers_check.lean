-- Diagonalisation: a real square matrix whose eigenvectors fill the columns of an invertible matrix P has n-th power P D^n P⁻¹ with each eigenvalue raised to the n-th power on the diagonal, the card's car fleet after n months is (600 + 400 × 0.5^n, 400 − 400 × 0.5^n), the shear has no such factorisation, and the card's worked numbers come out as it says.
import Mathlib.Data.Matrix.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix

/-! A square matrix with real entries and rows and columns labelled by a finite set `ι` is
`Matrix ι ι ℝ`; a column of numbers is `ι → ℝ`, and `A *ᵥ v` is the matrix applied to it.
Column `j` of `P` is `Pᵀ j` (row `j` of the transpose). "The columns are independent" is
Mathlib's `LinearIndependent ℝ Pᵀ`. `diagonal d` is the matrix with `d` down the diagonal and
zeros elsewhere, `P⁻¹` is Mathlib's inverse, and `A ^ k` is the matrix applied `k` times.
The 2 × 2 matrix with rows (a, b) and (c, d) is `!![a, b; c, d]`, and `![x, y]` is (x, y).
The card's decimals are written as exact fractions: 0.8 is 4/5, 0.3 is 3/10, 0.5 is 1/2. -/

/-- Diagonalisation and powers. Take a real square matrix `A`. Put a full set of independent
eigenvectors of `A` in the columns of `P`, column `j` stretched by `A` by the eigenvalue `d j`.
Then for every whole number `k`, `A` applied `k` times is `P D^k P⁻¹`, where `D^k` is the
diagonal matrix holding each eigenvalue raised to the `k`-th power: translate into eigenvector
amounts, stretch each amount alone, translate back. -/
theorem pow_eq_P_diagonal_pow_P_inv {ι : Type*} [Fintype ι] [DecidableEq ι]
    (A P : Matrix ι ι ℝ) (d : ι → ℝ)
    (h_eigen : ∀ j, A *ᵥ Pᵀ j = d j • Pᵀ j)
    (h_indep : LinearIndependent ℝ Pᵀ) (k : ℕ) :
    A ^ k = P * diagonal (fun i => d i ^ k) * P⁻¹ := by
  have hU : IsUnit Pᵀ := Matrix.linearIndependent_row_iff_isUnit.mp h_indep
  have hP : IsUnit P := by simpa using hU
  have hdet : IsUnit P.det := (Matrix.isUnit_iff_isUnit_det P).mp hP
  have hAP : A * P = P * diagonal d := by
    ext i j
    have := congrFun (h_eigen j) i
    simp only [mulVec, dotProduct, transpose_apply, Pi.smul_apply, smul_eq_mul] at this
    rw [mul_diagonal]
    exact this.trans (mul_comm _ _)
  have hinv : P * P⁻¹ = 1 := Matrix.mul_nonsing_inv P hdet
  have hinv' : P⁻¹ * P = 1 := Matrix.nonsing_inv_mul P hdet
  have hA : A = P * diagonal d * P⁻¹ := by
    rw [← hAP, Matrix.mul_assoc, hinv, Matrix.mul_one]
  induction k with
  | zero =>
    simp [hinv]
  | succ k ih =>
    have e : diagonal (fun i => d i ^ (k + 1)) = diagonal (fun i => d i ^ k) * diagonal d := by
      rw [diagonal_mul_diagonal]
      simp [pow_succ]
    calc A ^ (k + 1) = A ^ k * A := pow_succ A k
      _ = (P * diagonal (fun i => d i ^ k) * P⁻¹) * (P * diagonal d * P⁻¹) := by
          rw [← ih, ← hA]
      _ = P * (diagonal (fun i => d i ^ k) * (P⁻¹ * P) * diagonal d) * P⁻¹ := by
          simp only [Matrix.mul_assoc]
      _ = P * diagonal (fun i => d i ^ (k + 1)) * P⁻¹ := by
          rw [hinv', Matrix.mul_one, e]

/-- The fleet. One month moves 80% of city A's cars to stay and 20% to B, and 70% of B's to
stay and 30% back to A. Starting from 1,000 cars in A and none in B, after `n` months city A
holds 600 + 400 × 0.5^n cars and city B holds 400 − 400 × 0.5^n, for every whole `n`. -/
theorem fleet_after_n_months (n : ℕ) :
    (!![4/5, 3/10; 1/5, 7/10] : Matrix (Fin 2) (Fin 2) ℝ) ^ n *ᵥ ![1000, 0] =
      ![600 + 400 * (1/2) ^ n, 400 - 400 * (1/2) ^ n] := by
  induction n with
  | zero =>
    ext i; fin_cases i <;> norm_num
  | succ n ih =>
    rw [pow_succ', ← Matrix.mulVec_mulVec, ih]
    ext i; fin_cases i <;>
      simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, pow_succ] <;> ring

/-- The matrix this cannot be done to. The shear `[[1, 1], [0, 1]]` after `n` months is
`[[1, n], [0, 1]]`, yet it has no two independent eigenvectors, so there is no invertible `P`
and diagonal `D` with shear = P D P⁻¹. -/
theorem shear_is_not_diagonalisable :
    (∀ n : ℕ, (!![1, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℝ) ^ n = !![1, (n : ℝ); 0, 1]) ∧
    ¬ ∃ (P : Matrix (Fin 2) (Fin 2) ℝ) (d : Fin 2 → ℝ),
      (∀ j, !![1, 1; 0, 1] *ᵥ Pᵀ j = d j • Pᵀ j) ∧ LinearIndependent ℝ Pᵀ := by
  constructor
  · intro n
    induction n with
    | zero =>
      ext i j; fin_cases i <;> fin_cases j <;> simp
    | succ n ih =>
      rw [pow_succ, ih]
      ext i j; fin_cases i <;> fin_cases j <;>
        simp [Matrix.mul_apply, Fin.sum_univ_two]; ring
  · rintro ⟨P, d, hE, hI⟩
    have hz : ∀ j, P 1 j = 0 := by
      intro j
      have h0 := congrFun (hE j) 0
      have h1 := congrFun (hE j) 1
      simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] at h0 h1
      by_contra hne
      have hd : d j = 1 := by
        have : (d j - 1) * P 1 j = 0 := by linarith
        rcases mul_eq_zero.mp this with h | h
        · linarith
        · exact absurd h hne
      rw [hd] at h0
      apply hne
      linarith
    have hU : IsUnit Pᵀ := Matrix.linearIndependent_row_iff_isUnit.mp hI
    have hdet := (Matrix.isUnit_iff_isUnit_det Pᵀ).mp hU
    rw [det_transpose, det_fin_two, hz 0, hz 1] at hdet
    simp at hdet

-- Step 0: the fleet matrix leaves (3, 2) untouched and halves (1, -1).
example : (!![4/5, 3/10; 1/5, 7/10] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![3, 2] = ![3, 2] ∧
    (!![4/5, 3/10; 1/5, 7/10] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, -1] = (1/2 : ℚ) • ![1, -1] := by
  constructor <;> ext i <;> fin_cases i <;>
    norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- P inverse really is the inverse of P: [[3, 1], [2, -1]] times [[0.2, 0.2], [0.4, -0.6]] is I.
example : (!![3, 1; 2, -1] : Matrix (Fin 2) (Fin 2) ℚ) * !![1/5, 1/5; 2/5, -3/5] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- P D P inverse rebuilds A.
example : (!![3, 1; 2, -1] : Matrix (Fin 2) (Fin 2) ℚ) * !![1, 0; 0, 1/2] * !![1/5, 1/5; 2/5, -3/5] =
    !![4/5, 3/10; 1/5, 7/10] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Step 3: P inverse applied to (1000, 0) gives the amounts (200, 400).
example : (!![1/5, 1/5; 2/5, -3/5] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1000, 0] = ![200, 400] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Rebuilding: 200 lots of (3, 2) is (600, 400), 400 lots of (1, -1) is (400, -400), sum (1000, 0).
example : (200 : ℤ) • (![3, 2] : Fin 2 → ℤ) = ![600, 400] ∧
    (400 : ℤ) • (![1, -1] : Fin 2 → ℤ) = ![400, -400] ∧
    (![600, 400] : Fin 2 → ℤ) + ![400, -400] = ![1000, 0] := by decide
-- One month: (600, 400) + 0.5 × (400, -400) = (800, 200).
example : (600 : ℚ) + 400 * (1/2) = 800 ∧ (400 : ℚ) - 400 * (1/2) = 200 := by norm_num
-- Twelve months exactly: city A 600 + 400 × 0.5^12 = 153625/256 (600.097656...), city B
-- 102375/256 (399.902343...), together 1,000; city A to one decimal is 600.1.
example : (600 : ℚ) + 400 * (1/2) ^ 12 = 153625 / 256 ∧ (400 : ℚ) - 400 * (1/2) ^ 12 = 102375 / 256 ∧
    (153625 / 256 : ℚ) + 102375 / 256 = 1000 ∧
    (60005 / 100 : ℚ) ≤ 153625 / 256 ∧ (153625 / 256 : ℚ) < 60015 / 100 := by norm_num
-- Step 4: the shear after twelve months is [[1, 12], [0, 1]]; it fixes (1, 0) and sends (1, 1) to (2, 1).
example : (!![1, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) ^ 12 = !![1, 12; 0, 1] := by decide
example : (!![1, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 0] = ![1, 0] ∧
    (!![1, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 1] = ![2, 1] := by decide
-- The mistake "P where P inverse belongs": P D^12 P applied to (1000, 0) is
-- (9000 + 125/256, 6000 - 125/256), that is (9000.488281..., 5999.511718...).
example : ((!![3, 1; 2, -1] : Matrix (Fin 2) (Fin 2) ℚ) * !![1, 0; 0, (1/2) ^ 12] * !![3, 1; 2, -1])
    *ᵥ ![1000, 0] = ![9000 + 125/256, 6000 - 125/256] := by
  ext i; fin_cases i <;>
    norm_num [Matrix.mulVec, dotProduct, Matrix.mul_apply, Fin.sum_univ_two]

#print axioms pow_eq_P_diagonal_pow_P_inv
#print axioms fleet_after_n_months
#print axioms shear_is_not_diagonalisable
