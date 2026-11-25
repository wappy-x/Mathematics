-- Matrix multiplication: the row-by-column rule is the only table that does "B, then A" in one step, grouping a chain never changes it, order can change it at every square size from 2 up, and the card's bakery numbers come out as it says.
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Hadamard
import Mathlib.Data.Matrix.Basis

open Matrix

/-- Row by column is what "do this, then that" forces. Take `B` of size n × p (the first step)
and `A` of size m × n (the second step), with entries plain numbers. A table `M` of size m × p
does both steps in one, on every input list `v`, exactly when each of its entries is a row of `A`
against a column of `B`, multiplied in pairs and added:
`M i j = A i 1 * B 1 j + A i 2 * B 2 j + ... + A i n * B n j`. -/
theorem row_by_column_is_forced_by_chaining {R : Type*} [CommRing R] {m n p : ℕ}
    (A : Matrix (Fin m) (Fin n) R) (B : Matrix (Fin n) (Fin p) R)
    (M : Matrix (Fin m) (Fin p) R) :
    (∀ v : Fin p → R, M *ᵥ v = A *ᵥ (B *ᵥ v)) ↔
      ∀ i j, M i j = ∑ k, A i k * B k j := by
  rw [show (∀ v : Fin p → R, M *ᵥ v = A *ᵥ (B *ᵥ v)) ↔ M = A * B by
    simp_rw [Matrix.mulVec_mulVec]
    exact Matrix.ext_iff_mulVec.symm]
  constructor
  · rintro rfl i j
    exact Matrix.mul_apply
  · intro h
    ext i j
    rw [h i j, Matrix.mul_apply]

/-- Brackets do not carry meaning. For any sizes that fit (`A` is m × n, `B` is n × p, `C` is
p × q) and plain-number entries, multiplying `A` by `B` first and then by `C` gives the same
table as multiplying `B` by `C` first and then `A` by that. -/
theorem grouping_never_matters {R : Type*} [CommRing R] {m n p q : ℕ}
    (A : Matrix (Fin m) (Fin n) R) (B : Matrix (Fin n) (Fin p) R)
    (C : Matrix (Fin p) (Fin q) R) :
    (A * B) * C = A * (B * C) := by
  exact Matrix.mul_assoc A B C

/-- The order carries the meaning. For square tables of every size from 2 × 2 up, with
plain-number entries (so 1 is not 0), there are two tables `A` and `B` for which `A * B` and
`B * A` differ. -/
theorem order_can_change_the_answer {R : Type*} [CommRing R] [Nontrivial R] (n : ℕ)
    (hn : 2 ≤ n) :
    ∃ A B : Matrix (Fin n) (Fin n) R, A * B ≠ B * A := by
  classical
  refine ⟨Matrix.single ⟨0, by omega⟩ ⟨1, by omega⟩ 1,
    Matrix.single ⟨1, by omega⟩ ⟨0, by omega⟩ 1, ?_⟩
  intro h
  have h2 := congrFun (congrFun h ⟨0, by omega⟩) ⟨0, by omega⟩
  rw [Matrix.single_mul_single_same, Matrix.single_mul_single_same, Matrix.single_apply_same,
    Matrix.single_apply_of_ne] at h2
  · simp at h2
  · simp [Fin.ext_iff]

/-- `A`: kilograms per batch. Rows flour and butter, columns brioche and croissant. -/
def recipe : Matrix (Fin 2) (Fin 2) ℤ := !![5, 3; 2, 2]

/-- `B`: batches per day. Rows brioche and croissant, columns Monday and Tuesday. -/
def schedule : Matrix (Fin 2) (Fin 2) ℤ := !![2, 1; 1, 1]

/-- `C`: how many of each weekday in four weeks. Rows Monday and Tuesday, one column. -/
def month : Matrix (Fin 2) (Fin 1) ℤ := !![4; 4]

-- The four entries of AB, worked by hand.
example : (5 : ℤ) * 2 + 3 * 1 = 13 := by norm_num
example : (5 : ℤ) * 1 + 3 * 1 = 8 := by norm_num
example : (2 : ℤ) * 2 + 2 * 1 = 6 := by norm_num
example : (2 : ℤ) * 1 + 2 * 1 = 4 := by norm_num
-- A row 2, column 1 is 2: 2 kg of butter in a batch of brioche.
example : recipe 1 0 = 2 := by decide
-- Monday through both machines: Monday's column (2, 1) of batches becomes 13 kg and 6 kg.
example : recipe *ᵥ ![2, 1] = ![13, 6] := by decide
-- The kilograms-per-day table AB.
example : recipe * schedule = !![13, 8; 6, 4] := by decide
-- The flipped order BA: same tables, different answer.
example : schedule * recipe = !![12, 8; 7, 5] := by decide
example : recipe * schedule ≠ schedule * recipe := by decide
-- Batches per month BC: twelve of brioche and eight of croissants.
example : schedule * month = !![12; 8] := by decide
-- Both groupings of the month: 84 kg of flour and 40 kg of butter.
example : (recipe * schedule) * month = !![84; 40] := by decide
example : recipe * (schedule * month) = !![84; 40] := by decide
-- One column times one row: the outer products, and their sum is AB.
example : vecMulVec (fun i => recipe i 0) (fun j => schedule 0 j) = !![10, 5; 4, 2] := by decide
example : vecMulVec (fun i => recipe i 1) (fun j => schedule 1 j) = !![3, 3; 2, 2] := by decide
example : (!![10, 5; 4, 2] : Matrix (Fin 2) (Fin 2) ℤ) + !![3, 3; 2, 2] = !![13, 8; 6, 4] := by
  decide
-- The mistake: entry by entry gives a different table.
example : recipe ⊙ schedule = !![10, 3; 2, 2] := by decide
-- The slices of AB against C: 52 + 32 and 24 + 16.
example : vecMulVec (fun i => (recipe * schedule) i 0) (fun j => month 0 j) = !![52; 24] := by
  decide
example : vecMulVec (fun i => (recipe * schedule) i 1) (fun j => month 1 j) = !![32; 16] := by
  decide

#print axioms row_by_column_is_forced_by_chaining
#print axioms grouping_never_matters
#print axioms order_can_change_the_answer
