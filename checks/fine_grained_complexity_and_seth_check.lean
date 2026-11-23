-- Fine-grained complexity: split and list turns a CNF formula into two lists of 0-1 vectors whose orthogonal pairs are exactly its satisfying settings.
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Fintype.Pi
import Mathlib.Analysis.SpecialFunctions.Pow.Real

/-! SETH and the Backurs-Indyk gadget step are not stated here: SETH is a conjecture about
running times, and Mathlib has no model of step counts to state it in. This file states the
parts of the card that are exact: the split-and-list step, its cost arithmetic, and the
card's whole-number examples. -/

/-- A literal is a variable with the value that makes it true: `(x, true)` is `x`,
`(x, false)` is `¬x`. A clause is a list of literals, joined by "or". -/
abbrev Literal (V : Type*) := V × Bool

/-- A setting `σ` satisfies a CNF formula with clauses `F 0, …, F (m-1)` when every clause
has a literal that is true under `σ`. -/
def Satisfies {V : Type*} {m : ℕ} (F : Fin m → List (Literal V)) (σ : V → Bool) : Prop :=
  ∀ j, ∃ l ∈ F j, σ l.1 = l.2

instance {V : Type*} {m : ℕ} (F : Fin m → List (Literal V)) (σ : V → Bool) :
    Decidable (Satisfies F σ) := by
  unfold Satisfies; infer_instance

/-- A literal is made true by the first-half setting `α`: it is on a first-half variable
and `α` gives that variable the literal's value. -/
def trueOnFirst {V₁ V₂ : Type*} (α : V₁ → Bool) : Literal (V₁ ⊕ V₂) → Bool
  | (Sum.inl v, s) => α v == s
  | (Sum.inr _, _) => false

/-- A literal is made true by the second-half setting `β`. -/
def trueOnSecond {V₁ V₂ : Type*} (β : V₂ → Bool) : Literal (V₁ ⊕ V₂) → Bool
  | (Sum.inl _, _) => false
  | (Sum.inr v, s) => β v == s

/-- The list-A vector of a first-half setting `α`: one place per clause, 1 where the clause
is still open (no literal of it in the first half is true under `α`), 0 otherwise. -/
def vecA {V₁ V₂ : Type*} {m : ℕ} (F : Fin m → List (Literal (V₁ ⊕ V₂))) (α : V₁ → Bool) :
    Fin m → ℕ :=
  fun j => if (F j).any (trueOnFirst α) then 0 else 1

/-- The list-B vector of a second-half setting `β`, by the same rule. -/
def vecB {V₁ V₂ : Type*} {m : ℕ} (F : Fin m → List (Literal (V₁ ⊕ V₂))) (β : V₂ → Bool) :
    Fin m → ℕ :=
  fun j => if (F j).any (trueOnSecond β) then 0 else 1

/-- A literal is true under the full setting exactly when it is true on one of the halves. -/
theorem literal_true_iff {V₁ V₂ : Type*} (α : V₁ → Bool) (β : V₂ → Bool)
    (l : Literal (V₁ ⊕ V₂)) :
    Sum.elim α β l.1 = l.2 ↔ trueOnFirst α l = true ∨ trueOnSecond β l = true := by
  obtain ⟨v, s⟩ := l
  cases v <;> simp [trueOnFirst, trueOnSecond]

/-- The dot product counts the clauses false under the full setting (helper, stated
before the theorems that use it). -/
theorem dot_eq_false_clauses_aux {V₁ V₂ : Type*} {m : ℕ}
    (F : Fin m → List (Literal (V₁ ⊕ V₂))) (α : V₁ → Bool) (β : V₂ → Bool) :
    vecA F α ⬝ᵥ vecB F β =
      (Finset.univ.filter fun j => ¬ ∃ l ∈ F j, Sum.elim α β l.1 = l.2).card := by
  rw [Finset.card_filter, dotProduct]
  refine Finset.sum_congr rfl fun j _ => ?_
  have h : (∃ l ∈ F j, Sum.elim α β l.1 = l.2) ↔
      ((F j).any (trueOnFirst α) = true ∨ (F j).any (trueOnSecond β) = true) := by
    simp only [literal_true_iff, List.any_eq_true]
    constructor
    · rintro ⟨l, hl, h | h⟩
      · exact Or.inl ⟨l, hl, h⟩
      · exact Or.inr ⟨l, hl, h⟩
    · rintro (⟨l, hl, h⟩ | ⟨l, hl, h⟩)
      · exact ⟨l, hl, Or.inl h⟩
      · exact ⟨l, hl, Or.inr h⟩
  simp only [vecA, vecB, h]
  by_cases hA : (F j).any (trueOnFirst α) = true <;>
    by_cases hB : (F j).any (trueOnSecond β) = true <;> simp [hA, hB]

/-- Split and list (Step 3): split the variables into two halves. A full setting, made of a
first-half setting `α` and a second-half setting `β`, satisfies the formula exactly when the
two vectors are orthogonal: their dot product is 0. -/
theorem satisfies_iff_vectors_orthogonal {V₁ V₂ : Type*} {m : ℕ}
    (F : Fin m → List (Literal (V₁ ⊕ V₂))) (α : V₁ → Bool) (β : V₂ → Bool) :
    Satisfies F (Sum.elim α β) ↔ vecA F α ⬝ᵥ vecB F β = 0 := by
  rw [dot_eq_false_clauses_aux, Finset.card_eq_zero, Finset.filter_eq_empty_iff]
  simp only [Finset.mem_univ, true_implies, not_not]
  rfl

/-- The detailed proof's middle line: the dot product of the two vectors counts the clauses
that are false under the full setting. -/
theorem dot_eq_false_clauses {V₁ V₂ : Type*} {m : ℕ}
    (F : Fin m → List (Literal (V₁ ⊕ V₂))) (α : V₁ → Bool) (β : V₂ → Bool) :
    vecA F α ⬝ᵥ vecB F β =
      (Finset.univ.filter fun j => ¬ ∃ l ∈ F j, Sum.elim α β l.1 = l.2).card :=
  dot_eq_false_clauses_aux F α β

/-- The cost of the conversion's payoff: with `n = 2^(N/2)` vectors per list, a method for
orthogonal vectors in `n^(2-ε)` steps costs `2^((1-ε/2) N)`. -/
theorem split_list_cost (N ε : ℝ) :
    ((2 : ℝ) ^ (N / 2)) ^ (2 - ε) = (2 : ℝ) ^ ((1 - ε / 2) * N) := by
  rw [← Real.rpow_mul (by norm_num : (0 : ℝ) ≤ 2)]
  congr 1
  ring

/-! The card's whole-number examples. -/

/-- The edit-distance table's last cell, by the card's rule
`T[i][j] = min(T[i-1][j] + 1, T[i][j-1] + 1, T[i-1][j-1] + [u_i ≠ v_j])`,
`T[i][0] = i`, `T[0][j] = j`. The two arguments are the strings read from the last letter
back, so each step peels the last letters `u_i` and `v_j`. -/
def tableRev {α : Type*} [DecidableEq α] : List α → List α → ℕ
  | [], v => v.length
  | a :: u, v => go a u (tableRev u) v
where
  /-- One row of the table: `r` is the row above, the distances from the shorter `u`. -/
  go (a : α) (u : List α) (r : List α → ℕ) : List α → ℕ
    | [] => u.length + 1
    | b :: v => min (min (r (b :: v) + 1) (go a u r v + 1)) (r v + if a = b then 0 else 1)

/-- The edit distance table's last cell `T[|u|][|v|]` for strings `u` and `v`. -/
def editTable {α : Type*} [DecidableEq α] (u v : List α) : ℕ := tableRev u.reverse v.reverse

inductive Base | A | C | G | T
  deriving DecidableEq

open Base in
-- GATTACA against GCATGCA: the table's last cell is 3.
example : editTable [G, A, T, T, A, C, A] [G, C, A, T, G, C, A] = 3 := by decide

-- Coordinate gadgets 201112 and 200012 (list A), 200112 and 211112 (list B):
-- distances 0-0, 0-1, 1-0 are 1 and 1-1 is 3.
example : editTable [2, 0, 1, 1, 1, 2] [2, 0, 0, 1, 1, 2] = 1 := by decide
example : editTable [2, 0, 1, 1, 1, 2] [2, 1, 1, 1, 1, 2] = 1 := by decide
example : editTable [2, 0, 0, 0, 1, 2] [2, 0, 0, 1, 1, 2] = 1 := by decide
example : editTable [2, 0, 0, 0, 1, 2] [2, 1, 1, 1, 1, 2] = 3 := by decide

/-- The card's formula on x1..x6, split as x1 x2 x3 (first half, `inl 0, 1, 2`) and
x4 x5 x6 (second half, `inr 0, 1, 2`). -/
def cardFormula : Fin 8 → List (Literal (Fin 3 ⊕ Fin 3)) :=
  ![[(.inl 0, true), (.inl 1, true), (.inr 0, true)],
    [(.inl 0, false), (.inl 2, true), (.inr 1, true)],
    [(.inl 0, true), (.inl 1, false), (.inr 2, true)],
    [(.inl 0, true), (.inl 1, true), (.inr 0, false)],
    [(.inl 0, true), (.inl 1, false), (.inr 2, false)],
    [(.inl 0, false), (.inl 1, true), (.inr 1, false)],
    [(.inl 0, false), (.inl 1, false), (.inr 1, false)],
    [(.inl 0, false), (.inl 1, false), (.inr 1, true)]]

-- x1 x2 x3 = 101 leaves only clause 6 open: 00000100.
example : List.ofFn (vecA cardFormula ![true, false, true]) = [0, 0, 0, 0, 0, 1, 0, 0] := by
  decide
-- x4 x5 x6 = 000 leaves clauses 1, 2, 3 and 8 open: 11100001.
example : List.ofFn (vecB cardFormula ![false, false, false]) = [1, 1, 1, 0, 0, 0, 0, 1] := by
  decide
-- Their dot product is 0, and 101000 satisfies the formula.
example : vecA cardFormula ![true, false, true] ⬝ᵥ vecB cardFormula ![false, false, false] = 0 := by
  decide
example : Satisfies cardFormula (Sum.elim ![true, false, true] ![false, false, false]) := by
  decide
-- Of the 64 pairs of half-settings, exactly 4 are orthogonal.
example : (Finset.univ.filter fun p : (Fin 3 → Bool) × (Fin 3 → Bool) =>
    vecA cardFormula p.1 ⬝ᵥ vecB cardFormula p.2 = 0).card = 4 := by
  decide
-- The 4 satisfying settings are 101000, 101001, 101100 and 101101.
example : ∀ α β : Fin 3 → Bool, Satisfies cardFormula (Sum.elim α β) ↔
    α = ![true, false, true] ∧ β 1 = false := by
  decide

-- Table sizes: 4,600,000 squared and 3,100,000,000 squared.
example : 4600000 ^ 2 = 21160000000000 := by norm_num
example : 3100000000 ^ 2 = 9610000000000000000 := by norm_num
-- DNA strings up to 3 letters: 85 strings, 7,225 pairs.
example : 1 + 4 + 4 ^ 2 + 4 ^ 3 = 85 ∧ 85 ^ 2 = 7225 := by norm_num
-- N = 60: brute force 2^60, 2^30 vectors per side.
example : 2 ^ 60 = 1152921504606846976 ∧ 2 ^ 30 = 1073741824 := by norm_num
-- (2^30)^1.9 = 2^57, written in whole numbers as ((2^30)^19 = (2^57)^10), and 2^60 / 2^57 = 8.
example : (2 ^ 30) ^ 19 = (2 ^ 57) ^ 10 ∧ 2 ^ 57 = 144115188075855872 ∧ 2 ^ 60 / 2 ^ 57 = 8 := by
  norm_num
-- Mistake 2, split 10 and 50: (2^50)^1.9 = 2^95, and 95 > 60.
example : (2 ^ 50) ^ 19 = (2 ^ 95) ^ 10 ∧ 60 < 95 := by norm_num
-- The vector-gadget count: 2 × 20 + 9 × 6 + 9 = 103, and c1 = c0 + 2 = 105.
example : 2 * 20 + 9 * 6 + 9 = 103 ∧ 103 + 2 = 105 := by norm_num

#print axioms literal_true_iff
#print axioms dot_eq_false_clauses_aux
#print axioms satisfies_iff_vectors_orthogonal
#print axioms dot_eq_false_clauses
#print axioms split_list_cost
