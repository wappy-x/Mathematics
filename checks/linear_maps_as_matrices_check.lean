-- Linear maps: any rule that respects adding and stretching equals multiplication by the matrix whose columns are where it sends the axis arrows, only that matrix fits, and one rule after another has the product matrix with the first move on the right; the card's shear, quarter turn and corner (1, 1) come out as it says.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.LinearAlgebra.Matrix.ToLin

open Matrix

/-- The matrix built from a rule `T`: column `j` is `T` of the `j`-th axis arrow
(`Pi.single j 1`, a 1 in place `j` and 0 elsewhere). -/
def matrixOf {m n : ℕ} (T : (Fin n → ℝ) → (Fin m → ℝ)) : Matrix (Fin m) (Fin n) ℝ :=
  Matrix.of fun i j => T (Pi.single j 1) i

/-- A rule is secretly a matrix. If a rule `T` passes both tests at every input,
`T (u + v) = T u + T v` and `T (c • u) = c • T u`, then `T` is matrix times vector for the
matrix whose columns are where `T` sends the axis arrows: `T v = A v` for every `v`. This holds
between spaces of any sizes; when they differ, the matrix is rectangular. -/
theorem linear_map_is_matrix_of_axis_images {m n : ℕ} (T : (Fin n → ℝ) → (Fin m → ℝ))
    (hadd : ∀ u v, T (u + v) = T u + T v) (hsmul : ∀ (c : ℝ) u, T (c • u) = c • T u) :
    ∀ v, T v = matrixOf T *ᵥ v := by
  intro v
  let L : (Fin n → ℝ) →ₗ[ℝ] (Fin m → ℝ) :=
    { toFun := T, map_add' := hadd, map_smul' := hsmul }
  have hL : LinearMap.toMatrix' L = matrixOf T := by
    ext i j
    simp [LinearMap.toMatrix'_apply, matrixOf, L]
  rw [← hL, LinearMap.toMatrix'_mulVec]
  rfl

/-- Only one matrix fits. Two matrices that send every axis arrow to the same place share
every column, so they are equal. -/
theorem matrix_fixed_by_axis_images {m n : ℕ} (A B : Matrix (Fin m) (Fin n) ℝ)
    (h : ∀ j, A *ᵥ Pi.single j 1 = B *ᵥ Pi.single j 1) : A = B := by
  ext i j
  have := congrFun (h j) i
  simpa [Matrix.mulVec_single_one] using this

/-- One rule after another is one product, the move made first on the right. If `S` and `T`
both pass the two tests, the matrix of "`S` first, then `T`" is `T`'s matrix times `S`'s. -/
theorem matrix_of_composition_is_product {m n p : ℕ}
    (S : (Fin n → ℝ) → (Fin m → ℝ)) (T : (Fin m → ℝ) → (Fin p → ℝ))
    (hSadd : ∀ u v, S (u + v) = S u + S v) (hSsmul : ∀ (c : ℝ) u, S (c • u) = c • S u)
    (hTadd : ∀ u v, T (u + v) = T u + T v) (hTsmul : ∀ (c : ℝ) u, T (c • u) = c • T u) :
    matrixOf (T ∘ S) = matrixOf T * matrixOf S := by
  ext i j
  have hT := linear_map_is_matrix_of_axis_images T hTadd hTsmul (S (Pi.single j 1))
  simp only [matrixOf, Matrix.of_apply, Function.comp_apply, Matrix.mul_apply]
  rw [hT]
  simp [Matrix.mulVec, dotProduct, matrixOf]

/-- The shear: (x, y) goes to (x + y, y). -/
def shear (v : Fin 2 → ℝ) : Fin 2 → ℝ := ![v 0 + v 1, v 1]
/-- The quarter turn anticlockwise: (x, y) goes to (-y, x). -/
def turn (v : Fin 2 → ℝ) : Fin 2 → ℝ := ![-v 1, v 0]
/-- Squaring the first number: keeps (0, 0) fixed but is not linear. -/
def squareFirst (v : Fin 2 → ℝ) : Fin 2 → ℝ := ![v 0 ^ 2, v 1]

-- The two buttons' matrices, read off the axis arrows.
example : matrixOf shear = !![1, 1; 0, 1] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [matrixOf, shear]
example : matrixOf turn = !![0, -1; 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [matrixOf, turn]
-- The two products: turn then shear is AB, shear then turn is BA.
example : !![(1 : ℝ), 1; 0, 1] * !![0, -1; 1, 0] = !![1, -1; 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]
example : !![(0 : ℝ), -1; 1, 0] * !![1, 1; 0, 1] = !![0, -1; 1, 1] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]
-- The corner (1, 1): turn then shear ends at (0, 1), by two steps and by one matrix.
example : turn ![1, 1] = ![-1, 1] := by
  ext i; fin_cases i <;> simp [turn]
example : shear (turn ![1, 1]) = ![0, 1] := by
  ext i; fin_cases i <;> simp [shear, turn]
example : !![(1 : ℝ), -1; 1, 0] *ᵥ ![1, 1] = ![0, 1] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Shear then turn ends at (-1, 2), by two steps and by one matrix.
example : shear ![1, 1] = ![2, 1] := by
  ext i; fin_cases i <;> norm_num [shear]
example : turn (shear ![1, 1]) = ![-1, 2] := by
  ext i; fin_cases i <;> norm_num [shear, turn]
example : !![(0 : ℝ), -1; 1, 1] *ᵥ ![1, 1] = ![-1, 2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The mistakes: shear laid in as rows sends (1, 1) to (1, 2); the turn with no minus leaves it alone.
example : !![(1 : ℝ), 0; 1, 1] *ᵥ ![1, 1] = ![1, 2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : !![(0 : ℝ), 1; 1, 0] *ᵥ ![1, 1] = ![1, 1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- The code's linearity check on the shear, u = (1, 0), v = (0, 1), c = 3:
-- T(u + v) = (2, 1) = T(u) + T(v), and T(3u) = (3, 0) = 3 T(u).
example : shear (![1, 0] + ![0, 1]) = ![2, 1] ∧ shear ![1, 0] + shear ![0, 1] = ![2, 1] := by
  constructor <;> (ext i; fin_cases i <;> norm_num [shear])
example : shear ((3 : ℝ) • ![1, 0]) = ![3, 0] ∧ (3 : ℝ) • shear ![1, 0] = ![3, 0] := by
  constructor <;> (ext i; fin_cases i <;> norm_num [shear])
-- Sliding right by 1 fails the first test: D(u + v) = (2, 1) but D(u) + D(v) = (3, 1).
example : (![1, 0] + ![0, 1] : Fin 2 → ℝ) + ![1, 0] = ![2, 1] ∧
    ((![1, 0] : Fin 2 → ℝ) + ![1, 0]) + (![0, 1] + ![1, 0]) = ![3, 1] := by
  constructor <;> (ext i; fin_cases i <;> norm_num)
-- A fixed origin is not enough: squaring the first number keeps (0, 0), sends (1, 1) to (1, 1)
-- and (2, 2) to (4, 2), not twice (1, 1).
example : squareFirst 0 = 0 := by
  ext i; fin_cases i <;> simp [squareFirst]
example : squareFirst ![1, 1] = ![1, 1] := by
  ext i; fin_cases i <;> norm_num [squareFirst]
example : squareFirst ![2, 2] = ![4, 2] := by
  ext i; fin_cases i <;> norm_num [squareFirst]
example : squareFirst ((2 : ℝ) • ![1, 1]) ≠ (2 : ℝ) • squareFirst ![1, 1] := by
  intro h; have := congrFun h 0; norm_num [squareFirst] at this

#print axioms linear_map_is_matrix_of_axis_images
#print axioms matrix_fixed_by_axis_images
#print axioms matrix_of_composition_is_product
