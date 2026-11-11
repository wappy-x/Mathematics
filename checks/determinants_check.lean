-- Determinants: applying a square matrix multiplies the area (volume) of every shape by the size of its determinant, a zero determinant means two different points land on the same spot so nothing can undo the map, determinants of products multiply, and a staircase matrix's determinant is its diagonal multiplied out.
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Block

open MeasureTheory

/-- The determinant is the area multiplier, and zero means flattened. Take any square matrix A
of real numbers, of any size n. Applying A (sending each point v to A v) multiplies the area
(in higher sizes, the volume) of every shape s by the size of det A. And det A = 0 exactly when
A is not one-to-one: two different points land on the same spot, so nothing can send the
picture back. -/
theorem det_multiplies_every_area_and_zero_means_flattened {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) :
    (∀ s : Set (Fin n → ℝ),
        volume ((fun v => A.mulVec v) '' s) = ENNReal.ofReal |A.det| * volume s) ∧
      (A.det = 0 ↔ ¬ Function.Injective (fun v => A.mulVec v)) := by
  refine ⟨fun s => ?_, ?_⟩
  · have h := MeasureTheory.Measure.addHaar_image_linearMap (μ := (volume : Measure (Fin n → ℝ)))
      (Matrix.toLin' A) s
    have hf : ⇑(Matrix.toLin' A) = fun v => A.mulVec v := funext (Matrix.toLin'_apply A)
    rw [LinearMap.det_toLin', hf] at h
    exact h
  · rw [show (fun v => A.mulVec v) = A.mulVec from rfl, Matrix.mulVec_injective_iff_isUnit,
      Matrix.isUnit_iff_isUnit_det, isUnit_iff_ne_zero, not_not]

/-- Multipliers multiply. For any two square matrices A and B of the same size,
det (A B) = det A × det B. -/
theorem det_of_product_is_product_of_dets {n : ℕ} (A B : Matrix (Fin n) (Fin n) ℝ) :
    (A * B).det = A.det * B.det := by
  exact Matrix.det_mul A B

/-- Staircases. If every number below the main diagonal of a square matrix is zero (upper
triangular), its determinant is the numbers on the diagonal multiplied together. -/
theorem det_of_staircase_is_diagonal_product {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (h : ∀ i j, j < i → A i j = 0) :
    A.det = ∏ i, A i i := by
  exact Matrix.det_of_isUpperTriangular (fun i j hij => h i j hij)

-- The formula ad - bc on the card's five 2 by 2 matrices.
-- The shear [[1, 1], [0, 1]]: 1.
example : Matrix.det !![(1 : ℤ), 1; 0, 1] = 1 := by norm_num [Matrix.det_fin_two_of]
-- The cafe matrix [[2, 1], [1, 1]]: 1.
example : Matrix.det !![(2 : ℤ), 1; 1, 1] = 1 := by norm_num [Matrix.det_fin_two_of]
-- The stretch [[3, 0], [0, 2]]: 6.
example : Matrix.det !![(3 : ℤ), 0; 0, 2] = 6 := by norm_num [Matrix.det_fin_two_of]
-- The mirror [[0, 1], [1, 0]]: -1.
example : Matrix.det !![(0 : ℤ), 1; 1, 0] = -1 := by norm_num [Matrix.det_fin_two_of]
-- The flattener [[2, 4], [1, 2]]: 0.
example : Matrix.det !![(2 : ℤ), 4; 1, 2] = 0 := by norm_num [Matrix.det_fin_two_of]
-- Stretch after shear is [[3, 3], [0, 2]], determinant 6 = 6 x 1.
example : !![(3 : ℤ), 0; 0, 2] * !![1, 1; 0, 1] = !![3, 3; 0, 2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : Matrix.det !![(3 : ℤ), 3; 0, 2] = 6 := by norm_num [Matrix.det_fin_two_of]
-- Stretch plus shear is [[4, 1], [0, 3]], determinant 12, not 6 + 1 = 7.
example : !![(3 : ℤ), 0; 0, 2] + !![1, 1; 0, 1] = !![4, 1; 0, 3] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num
example : Matrix.det !![(4 : ℤ), 1; 0, 3] = 12 := by norm_num [Matrix.det_fin_two_of]
-- The 3 by 3 [[2, 1, 1], [0, 1, 1], [1, 0, 4]]: 8 + 1 - 1 = 8.
example : Matrix.det !![(2 : ℤ), 1, 1; 0, 1, 1; 1, 0, 4] = 8 := by
  norm_num [Matrix.det_fin_three]
-- Its staircase [[2, 1, 1], [0, 1, 1], [0, 0, 4]]: 2 x 1 x 4 = 8.
example : Matrix.det !![(2 : ℤ), 1, 1; 0, 1, 1; 0, 0, 4] = 8 := by
  norm_num [Matrix.det_fin_three]
-- The mistakes: ad + bc on the cafe matrix gives 3, its diagonal gives 2, adding all three
-- cofactor terms on the 3 by 3 gives 6.
example : (2 : ℤ) * 1 + 1 * 1 = 3 ∧ (2 : ℤ) * 1 = 2 := by decide
example : (2 : ℤ) * (1 * 4 - 1 * 0) + 1 * (0 * 4 - 1 * 1) + 1 * (0 * 0 - 1 * 1) = 6 := by decide
-- Try changing: the cafe matrix with rows swapped gives -1; the 3 by 3 with its top row doubled gives 16.
example : Matrix.det !![(1 : ℤ), 1; 2, 1] = -1 := by norm_num [Matrix.det_fin_two_of]
example : Matrix.det !![(4 : ℤ), 2, 2; 0, 1, 1; 1, 0, 4] = 16 := by
  norm_num [Matrix.det_fin_three]

#print axioms det_multiplies_every_area_and_zero_means_flattened
#print axioms det_of_product_is_product_of_dets
#print axioms det_of_staircase_is_diagonal_product
