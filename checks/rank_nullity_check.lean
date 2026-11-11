-- Rank and nullity: for every matrix of real numbers, the directions it keeps plus the directions it kills add up to its number of columns, two inputs collide exactly when their difference is killed, and nullity 0 means different inputs always give different outputs.
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum

open Matrix

/-! A matrix with `m` rows and `n` columns of real numbers is `A : Matrix (Fin m) (Fin n) ℝ`.
An input is a list of `n` real numbers, `x : Fin n → ℝ`, and `A *ᵥ x` is the output.
`A.mulVecLin` is the matrix read as a machine (a linear map) from inputs to outputs.
Mathlib's `A.rank` is the dimension of the column space: everything the matrix hits
(the range of `A.mulVecLin`). The nullity is the dimension of the null space: every input the
matrix sends to zero, `Module.finrank ℝ (LinearMap.ker A.mulVecLin)`. -/

/-- Rank plus nullity is the number of columns. For every matrix of real numbers, with any
finite number `m` of rows and `n` of columns, the number of independent directions it keeps
(the rank, the size of the column space) plus the number of independent directions it sends to
zero (the nullity, the size of the null space) is `n`, the number of numbers fed in. -/
theorem rank_add_nullity_eq_columns {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    A.rank + Module.finrank ℝ (LinearMap.ker A.mulVecLin) = n := by
  have h := A.mulVecLin.finrank_range_add_finrank_ker
  rw [Module.finrank_fin_fun] at h
  exact h

/-- Step 0: two inputs collide exactly when their difference dies. For every real matrix `A`
and any two inputs `x` and `y`, `A` gives them the same output exactly when `A` sends their
difference `x - y` to zero. -/
theorem collide_iff_difference_killed {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (x y : Fin n → ℝ) :
    A *ᵥ x = A *ᵥ y ↔ A *ᵥ (x - y) = 0 := by
  rw [Matrix.mulVec_sub, sub_eq_zero]

/-- Nullity 0 is one-to-one. For every real matrix `A`, different inputs always give different
outputs exactly when the nullity of `A` is 0. -/
theorem one_to_one_iff_nullity_zero {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    Function.Injective (fun x : Fin n → ℝ => A *ᵥ x) ↔
      Module.finrank ℝ (LinearMap.ker A.mulVecLin) = 0 := by
  rw [Submodule.finrank_eq_zero, LinearMap.ker_eq_bot]
  rfl

-- The projector P = [[1, 0, 0], [0, 1, 0]] sends (3, 4, 5) and (3, 4, 9) both to (3, 4).
example : (!![1, 0, 0; 0, 1, 0] : Matrix (Fin 2) (Fin 3) ℤ) *ᵥ ![3, 4, 5] = ![3, 4] ∧
    (!![1, 0, 0; 0, 1, 0] : Matrix (Fin 2) (Fin 3) ℤ) *ᵥ ![3, 4, 9] = ![3, 4] := by decide
-- Their difference is (0, 0, 4) = 4 × (0, 0, 1), and the projector kills both.
example : (![3, 4, 9] : Fin 3 → ℤ) - ![3, 4, 5] = ![0, 0, 4] ∧
    (![0, 0, 4] : Fin 3 → ℤ) = (4 : ℤ) • ![0, 0, 1] ∧
    (!![1, 0, 0; 0, 1, 0] : Matrix (Fin 2) (Fin 3) ℤ) *ᵥ ![0, 0, 4] = 0 ∧
    (!![1, 0, 0; 0, 1, 0] : Matrix (Fin 2) (Fin 3) ℤ) *ᵥ ![0, 0, 1] = 0 := by decide
-- The projector keeps 2 and kills 1: 2 + 1 = 3, the number of columns.
example : (2 : ℕ) + 1 = 3 := by decide
-- The flattener B = [[1, 2, 3], [2, 4, 6]]: row 2 is twice row 1, and B kills (-2, 1, 0) and (-3, 0, 1).
example : (!![1, 2, 3; 2, 4, 6] : Matrix (Fin 2) (Fin 3) ℤ) 1 =
      (2 : ℤ) • (!![1, 2, 3; 2, 4, 6] : Matrix (Fin 2) (Fin 3) ℤ) 0 ∧
    (!![1, 2, 3; 2, 4, 6] : Matrix (Fin 2) (Fin 3) ℤ) *ᵥ ![-2, 1, 0] = 0 ∧
    (!![1, 2, 3; 2, 4, 6] : Matrix (Fin 2) (Fin 3) ℤ) *ᵥ ![-3, 0, 1] = 0 := by decide
-- The flattener keeps 1 and kills 2: 1 + 2 = 3.
example : (1 : ℕ) + 2 = 3 := by decide
-- The mistakes: rows minus rank gives nullity 2 - 2 = 0 for P; reading B's rank as 2 gives 2 + 2 = 4, not 3.
example : (2 : ℕ) - 2 = 0 ∧ (2 : ℕ) + 2 = 4 ∧ (2 : ℕ) + 2 ≠ 3 := by decide
-- Try changing: B's second row as (2, 4, 7) still kills (-2, 1, 0), and the sum is 2 + 1 = 3.
example : (!![1, 2, 3; 2, 4, 7] : Matrix (Fin 2) (Fin 3) ℤ) *ᵥ ![-2, 1, 0] = 0 ∧
    (2 : ℕ) + 1 = 3 := by decide
-- Try changing: a dead fourth column on P kills (0, 0, 0, 1) as well as (0, 0, 1, 0); 2 + 2 = 4.
example : (!![1, 0, 0, 0; 0, 1, 0, 0] : Matrix (Fin 2) (Fin 4) ℤ) *ᵥ ![0, 0, 1, 0] = 0 ∧
    (!![1, 0, 0, 0; 0, 1, 0, 0] : Matrix (Fin 2) (Fin 4) ℤ) *ᵥ ![0, 0, 0, 1] = 0 ∧
    (2 : ℕ) + 2 = 4 := by decide
-- Try changing: P with a third row (0, 0, 1) sends (3, 4, 5) to itself.
example : (!![1, 0, 0; 0, 1, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![3, 4, 5] = ![3, 4, 5] := by
  decide

#print axioms rank_add_nullity_eq_columns
#print axioms collide_iff_difference_killed
#print axioms one_to_one_iff_nullity_zero
