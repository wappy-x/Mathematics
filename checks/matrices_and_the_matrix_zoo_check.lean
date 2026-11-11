-- Matrices: transposing an m by n table gives an n by m table with each entry's row and column numbers swapped, doing it twice gives the table back, the column totals of a table are the row totals of its transpose, and a square table is symmetric exactly when every entry a_ij equals a_ji off the diagonal; the cafe's own tables are checked number by number.
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.LinearAlgebra.Matrix.Notation

open Matrix

/-- The transpose tips the table over. For every size m by n and every table A of that size,
the transpose is n by m, the entry in its row j, column i is A's entry in row i, column j,
and transposing twice puts every number back where it started. -/
theorem transpose_swaps_entries_and_twice_gives_back {α : Type*} (m n : ℕ)
    (A : Matrix (Fin m) (Fin n) α) :
    (∀ i : Fin m, ∀ j : Fin n, Aᵀ j i = A i j) ∧ Aᵀᵀ = A := by
  exact ⟨fun i j => rfl, Matrix.transpose_transpose A⟩

/-- The same totals read two ways. For every m by n table of numbers, adding down column j
of the table gives the same total as adding across row j of its transpose. -/
theorem column_totals_are_row_totals_of_transpose {α : Type*} [AddCommMonoid α] (m n : ℕ)
    (A : Matrix (Fin m) (Fin n) α) (j : Fin n) :
    ∑ i : Fin m, A i j = ∑ i : Fin m, Aᵀ j i := by
  rfl

/-- Symmetric is tested pair by pair. A square table is symmetric (its transpose equals it)
exactly when every pair of entries across the diagonal agrees: a_ij equals a_ji for every row i
and column j off the diagonal (i different from j). The diagonal entries never need checking. -/
theorem symmetric_iff_entries_match_off_diagonal {α : Type*} (n : ℕ)
    (A : Matrix (Fin n) (Fin n) α) :
    A.IsSymm ↔ ∀ i j : Fin n, i ≠ j → A i j = A j i := by
  constructor
  · intro h i j _
    have := congrFun (congrFun h j) i
    simpa [Matrix.transpose_apply] using this
  · intro h
    ext i j
    by_cases hij : j = i
    · subst hij; rfl
    · exact (h i j (Ne.symm hij)).symm

-- The cafe's week: five days by two products, and its transpose, two by five.
example : (!![2, 1; 1, 1; 3, 2; 2, 1; 4, 3] : Matrix (Fin 5) (Fin 2) ℤ)ᵀ
    = !![2, 1, 3, 2, 4; 1, 1, 2, 1, 3] := by decide
-- Coffees 12 and pastries 8, down the columns of the week.
example : ∑ i : Fin 5, (!![2, 1; 1, 1; 3, 2; 2, 1; 4, 3] : Matrix (Fin 5) (Fin 2) ℤ) i 0 = 12 ∧
    ∑ i : Fin 5, (!![2, 1; 1, 1; 3, 2; 2, 1; 4, 3] : Matrix (Fin 5) (Fin 2) ℤ) i 1 = 8 := by decide
-- 12 coffees and 8 pastries: 20 items in all.
example : (12 : ℤ) + 8 = 20 := by decide
-- The same 12 and 8 across the rows of the transpose.
example : ∑ j : Fin 5, (!![2, 1, 3, 2, 4; 1, 1, 2, 1, 3] : Matrix (Fin 2) (Fin 5) ℤ) 0 j = 12 ∧
    ∑ j : Fin 5, (!![2, 1, 3, 2, 4; 1, 1, 2, 1, 3] : Matrix (Fin 2) (Fin 5) ℤ) 1 j = 8 := by decide
-- The mistake: totals across the rows are the day totals 3, 2, 5, 3, 7.
example : (fun i : Fin 5 => ∑ j : Fin 2, (!![2, 1; 1, 1; 3, 2; 2, 1; 4, 3] : Matrix (Fin 5) (Fin 2) ℤ) i j)
    = ![3, 2, 5, 3, 7] := by decide
-- Two weeks of both days, and a doubled pair of days.
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ) + !![3, 2; 2, 1] = !![5, 3; 3, 2] := by decide
example : (2 : ℤ) • (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ) = !![4, 2; 2, 2] := by decide
-- A = [[2, 1], [1, 1]] is symmetric; its trace is 2 + 1 = 3. Its entry a_21 is 1.
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ = !![2, 1; 1, 1] := by decide
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ).IsSymm := by decide
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ).trace = 3 := by decide
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ) 1 0 = 1 := by decide
-- The upper triangular table [[2, 1], [0, 1]]: row 2, column 1 is 0, row 1, column 2 is 1,
-- zeros below the diagonal, trace 3, and its transpose [[2, 0], [1, 1]] is not equal to it.
example : (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) 1 0 = 0 ∧
    (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) 0 1 = 1 := by decide
example : (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).BlockTriangular id := by decide
example : (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).trace = 3 := by decide
example : (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ = !![2, 0; 1, 1] ∧
    (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ ≠ !![2, 1; 0, 1] := by decide
-- The prices table is diagonal, $4 and $3, with trace 7.
example : (!![4, 0; 0, 3] : Matrix (Fin 2) (Fin 2) ℤ) = diagonal ![4, 3] := by decide
example : (!![4, 0; 0, 3] : Matrix (Fin 2) (Fin 2) ℤ).trace = 7 := by decide
-- The identity: 1s down the diagonal, 0s elsewhere, trace 2.
example : (1 : Matrix (Fin 2) (Fin 2) ℤ) = !![1, 0; 0, 1] := by decide
example : (1 : Matrix (Fin 2) (Fin 2) ℤ).trace = 2 := by decide

#print axioms transpose_swaps_entries_and_twice_gives_back
#print axioms column_totals_are_row_totals_of_transpose
#print axioms symmetric_iff_entries_match_off_diagonal
