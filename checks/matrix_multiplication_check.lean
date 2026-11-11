-- Matrix multiplication: the row-by-column rule is the only table that does "B, then A" in one step, grouping a chain never changes it, order can change it at every square size from 2 up, and the card's workshop numbers come out as it says.
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

/-- `A`: grams per product. Rows beans and flour, columns brew and loaf. -/
def recipe : Matrix (Fin 2) (Fin 2) ℤ := !![20, 0; 0, 60]

/-- `B`: products per day. Rows brew and loaf, columns Monday and Tuesday. -/
def schedule : Matrix (Fin 2) (Fin 2) ℤ := !![2, 1; 1, 1]

/-- `C`: how many of each weekday in four weeks. Rows Monday and Tuesday, one column. -/
def month : Matrix (Fin 2) (Fin 1) ℤ := !![4; 4]

-- The four entries of AB, worked by hand.
example : (20 : ℤ) * 2 + 0 * 1 = 40 := by norm_num
example : (20 : ℤ) * 1 + 0 * 1 = 20 := by norm_num
example : (0 : ℤ) * 2 + 60 * 1 = 60 := by norm_num
example : (0 : ℤ) * 1 + 60 * 1 = 60 := by norm_num
-- A row 2, column 1 is 0: no flour in a brew.
example : recipe 1 0 = 0 := by decide
-- Monday through both machines: Monday's column (2, 1) of products becomes 40 g and 60 g.
example : recipe *ᵥ ![2, 1] = ![40, 60] := by decide
-- The grams-per-day table AB.
example : recipe * schedule = !![40, 20; 60, 60] := by decide
-- The flipped order BA: same tables, different answer.
example : schedule * recipe = !![40, 60; 20, 60] := by decide
example : recipe * schedule ≠ schedule * recipe := by decide
-- Products per month BC: twelve brews and eight loaves.
example : schedule * month = !![12; 8] := by decide
-- Both groupings of the month: 240 g of beans and 480 g of flour.
example : (recipe * schedule) * month = !![240; 480] := by decide
example : recipe * (schedule * month) = !![240; 480] := by decide
-- One column times one row: the outer products, and their sum is AB.
example : vecMulVec (fun i => recipe i 0) (fun j => schedule 0 j) = !![40, 20; 0, 0] := by decide
example : vecMulVec (fun i => recipe i 1) (fun j => schedule 1 j) = !![0, 0; 60, 60] := by decide
example : (!![40, 20; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ) + !![0, 0; 60, 60] = !![40, 20; 60, 60] := by
  decide
-- The mistake: entry by entry gives a different table.
example : recipe ⊙ schedule = !![40, 0; 0, 60] := by decide
-- The slices of AB against C: 160 + 80 and 240 + 240.
example : vecMulVec (fun i => (recipe * schedule) i 0) (fun j => month 0 j) = !![160; 240] := by
  decide
example : vecMulVec (fun i => (recipe * schedule) i 1) (fun j => month 1 j) = !![80; 240] := by
  decide

#print axioms row_by_column_is_forced_by_chaining
#print axioms grouping_never_matters
#print axioms order_can_change_the_answer
