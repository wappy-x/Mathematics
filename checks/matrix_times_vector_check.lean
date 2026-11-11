-- Matrix times vector: for every table of m rows and n columns and every list of n weights, mixing the columns with those weights gives the same list as running each row along the weights, that list is Mathlib's matrix-times-vector product, it always lands in the span of the columns, and the card's cafe numbers come out as it says.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Defs
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

open Matrix

/-! A table of `m` rows and `n` columns is `A : Matrix (Fin m) (Fin n) R`, with `A i j` the
entry in row `i`, column `j`. A list of `n` weights, one per column, is `x : Fin n → R`, so the
lengths match by the types themselves. `A.col j` is column `j`, read down the table, as one
list of `m` numbers. Mathlib's product `A *ᵥ x` is defined row by row: entry `i` is row `i`
paired with `x` (Mathlib's dot product). The numbers `R` may be any commutative semiring:
whole numbers, integers, real numbers and so on. `!![2, 1; 1, 1]` is the cafe's table
`[[2, 1], [1, 1]]`, and `![4, 3]` is the price list (4, 3). -/

/-- The two roads agree. For any table of `m` rows and `n` columns and any list of `n` weights,
one per column: road 1 scales each column by its own weight and adds the scaled columns;
road 2 runs each row along the weights, multiplying each entry by the weight of its own
column and adding. Both roads give the same list, entry for entry. -/
theorem mixing_the_columns_equals_running_each_row {R : Type*} [CommSemiring R] {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) R) (x : Fin n → R) :
    (∑ j, x j • A.col j) = fun i => ∑ j, A i j * x j := by
  funext i
  simp only [Finset.sum_apply, Pi.smul_apply, Matrix.col_apply, smul_eq_mul]
  exact Finset.sum_congr rfl fun j _ => mul_comm _ _

/-- The product is the mix of the columns. Mathlib's matrix-times-vector product `A *ᵥ x`
equals the columns of `A` mixed together with the entries of `x` as the weights. -/
theorem matrix_times_vector_is_the_column_mix {R : Type*} [CommSemiring R] {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) R) (x : Fin n → R) :
    A *ᵥ x = ∑ j, x j • A.col j := by
  rw [mixing_the_columns_equals_running_each_row]
  rfl

/-- Whatever list goes in, `A x` lands in the span of the columns: it is something the
columns of `A` can build between them. -/
theorem matrix_times_vector_lands_in_the_column_span {R : Type*} [CommSemiring R] {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) R) (x : Fin n → R) :
    A *ᵥ x ∈ Submodule.span R (Set.range A.col) := by
  rw [matrix_times_vector_is_the_column_mix]
  exact Submodule.sum_mem _ fun j _ =>
    Submodule.smul_mem _ _ (Submodule.subset_span ⟨j, rfl⟩)

-- Road 1: the coffee column (2, 1) weighed by 4 is (8, 4), the pastry column (1, 1) weighed
-- by 3 is (3, 3), and the two added give (11, 7).
example : (4 : ℕ) • (![2, 1] : Fin 2 → ℕ) = ![8, 4] ∧ (3 : ℕ) • (![1, 1] : Fin 2 → ℕ) = ![3, 3] ∧
    (4 : ℕ) • (![2, 1] : Fin 2 → ℕ) + (3 : ℕ) • ![1, 1] = ![11, 7] := by decide
-- The columns of the cafe's table are (2, 1) and (1, 1).
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℕ).col 0 = ![2, 1] ∧
    (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℕ).col 1 = ![1, 1] := by decide
-- Road 2: Monday 2*4 + 1*3 = 11, Tuesday 1*4 + 1*3 = 7.
example : 2 * 4 + 1 * 3 = 11 ∧ 1 * 4 + 1 * 3 = 7 := by norm_num
-- The product itself: [[2, 1], [1, 1]] times (4, 3) is (11, 7).
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℕ) *ᵥ ![4, 3] = ![11, 7] := by decide
-- Wednesday added, 3 coffees + 2 pastries: the 3 by 2 table gives (11, 7, 18).
example : (!![2, 1; 1, 1; 3, 2] : Matrix (Fin 3) (Fin 2) ℕ) *ᵥ ![4, 3] = ![11, 7, 18] := by decide
-- The mistakes: the columns added with no prices give (3, 2); prices swapped give (10, 7).
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℕ) *ᵥ ![1, 1] = ![3, 2] ∧
    (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℕ) *ᵥ ![3, 4] = ![10, 7] := by decide
-- This table reads the same both ways, which hides the row-column mix-up.
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℕ)ᵀ = !![2, 1; 1, 1] := by decide
-- Try changing: give the pastry away, prices (4, 0), and both roads give (8, 4).
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℕ) *ᵥ ![4, 0] = ![8, 4] := by decide
-- Try changing: a fourth day [5, 0] gives (11, 7, 18, 20).
example : (!![2, 1; 1, 1; 3, 2; 5, 0] : Matrix (Fin 4) (Fin 2) ℕ) *ᵥ ![4, 3] = ![11, 7, 18, 20] := by
  decide
-- Step 4: the prices (4, 3) solve 2x + y = 11 and x + y = 7.
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![4, 3] = ![11, 7] := by decide

#print axioms mixing_the_columns_equals_running_each_row
#print axioms matrix_times_vector_is_the_column_mix
#print axioms matrix_times_vector_lands_in_the_column_span
