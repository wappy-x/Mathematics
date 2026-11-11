-- The rules of sum and product: for finite sets, picks made in stages multiply (also when a stage's options change with earlier picks but always number the same), cases that share nothing add, and the card's lunch, captain and rye-or-chilli numbers come out as it says.
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Sigma
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Algebra.BigOperators.Group.Finset.Sigma

/-- The rules of sum and product, for any finite sets.
Rule of product: taking one member of `A` and then one member of `B` (an ordered pair,
a member of `A × B`) can be done in `|A| × |B|` ways.
Rule of sum: when two cases `C` and `D` share no member, everything in either numbers
`|C| + |D|`. -/
theorem rules_of_sum_and_product {α β γ : Type*} [DecidableEq γ]
    (A : Finset α) (B : Finset β) (C D : Finset γ) :
    (A ×ˢ B).card = A.card * B.card ∧
      (Disjoint C D → (C ∪ D).card = C.card + D.card) := by
  exact ⟨Finset.card_product A B, fun h => Finset.card_union_of_disjoint h⟩

/-- A second stage whose options depend on the first pick still multiplies, as long as every
first pick leaves the same number `n` of options (the card's captain and vice-captain:
each of 20 captains leaves 19 vice-captains). The completed two-stage choices number
`|A| × n`. -/
theorem equal_branches_multiply {α : Type*} {β : α → Type*}
    (A : Finset α) (B : (a : α) → Finset (β a)) (n : ℕ)
    (hB : ∀ a ∈ A, (B a).card = n) :
    (A.sigma B).card = A.card * n := by
  rw [Finset.card_sigma, Finset.sum_const_nat hB]

/-- Any number `k` of stages: picking one option from each stage's set, in order, can be
done in as many ways as the product of the stage sizes. Each further stage adds a factor. -/
theorem stages_multiply {k : ℕ} {β : Fin k → Type*} [∀ i, DecidableEq (β i)]
    (S : (i : Fin k) → Finset (β i)) :
    (Fintype.piFinset S).card = ∏ i, (S i).card := by
  exact Fintype.card_piFinset S

-- The lunch deal: 4 breads, 5 fillings, 3 sauces, or one of 3 soups.
-- Breads and fillings: 20 pairs.
example : (Finset.range 4 ×ˢ Finset.range 5).card = 20 := by decide
-- Sandwiches: 4 × 5 × 3 = 60.
example : (Finset.range 4 ×ˢ Finset.range 5 ×ˢ Finset.range 3).card = 60 := by decide
example : 4 * 5 * 3 = 60 := by decide
-- Lunches: a sandwich or a soup, never both, 60 + 3 = 63.
example : Fintype.card ((Fin 4 × Fin 5 × Fin 3) ⊕ Fin 3) = 63 := by decide
example : 60 + 3 = 63 := by decide
-- Captain then a different vice-captain from 20 players: 20 × 19 = 380.
set_option maxRecDepth 20000 in
example : ((Finset.range 20 ×ˢ Finset.range 20).filter (fun p => p.1 ≠ p.2)).card = 380 := by
  decide
example : 20 * 19 = 380 := by decide
-- Rye sandwiches 15, chilli sandwiches 20, both 5, rye or chilli 30, not 15 + 20 = 35.
example :
    ((Finset.univ : Finset (Fin 4 × Fin 5 × Fin 3)).filter (fun s => s.1 = 0)).card = 15 ∧
      ((Finset.univ : Finset (Fin 4 × Fin 5 × Fin 3)).filter (fun s => s.2.2 = 0)).card = 20 ∧
      ((Finset.univ : Finset (Fin 4 × Fin 5 × Fin 3)).filter
        (fun s => s.1 = 0 ∧ s.2.2 = 0)).card = 5 ∧
      ((Finset.univ : Finset (Fin 4 × Fin 5 × Fin 3)).filter
        (fun s => s.1 = 0 ∨ s.2.2 = 0)).card = 30 := by
  decide
example : 15 + 20 = 35 := by decide
-- The mistakes: stages added give 12, cases multiplied give 180, a vice-captain from all 20 gives 400.
example : 4 + 5 + 3 = 12 := by decide
example : 60 * 3 = 180 := by decide
example : 20 * 20 = 400 := by decide

#print axioms rules_of_sum_and_product
#print axioms equal_branches_multiply
#print axioms stages_multiply
