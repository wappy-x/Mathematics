-- Pascal's rule: each count C(n + 1, k + 1) is C(n, k) + C(n, k + 1), the picks of a finite set split exactly by one singled-out item kept in or left out, and row n of the triangle adds to 2^n, with the card's five-song numbers checked.
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum

open Finset

/-- Pascal's rule: every entry of the triangle is the sum of the two above it.
For every `n` and `k`, `C(n + 1, k + 1) = C(n, k) + C(n, k + 1)`.
Mathlib's `Nat.choose` already reads `0` past the end of a row (`C(n, k) = 0` when `k > n`),
which is the card's zero convention. -/
theorem pascals_rule (n k : ℕ) :
    (n + 1).choose (k + 1) = n.choose k + n.choose (k + 1) := by
  exact Nat.choose_succ_succ' n k

/-- The in-or-out split behind the rule. Take a finite set `s` with `n + 1` items and single
out one item `a` of it. Among the picks of `k + 1` items from `s`, those that leave `a` out
number `C(n, k + 1)`, and those that keep `a` in number `C(n, k)`. -/
theorem picks_split_by_one_item {α : Type*} [DecidableEq α] (s : Finset α) (a : α)
    (ha : a ∈ s) (k : ℕ) :
    ((s.powersetCard (k + 1)).filter (fun t => a ∉ t)).card = (s.card - 1).choose (k + 1) ∧
      ((s.powersetCard (k + 1)).filter (fun t => a ∈ t)).card = (s.card - 1).choose k := by
  have hcard : (s.erase a).card = s.card - 1 := card_erase_of_mem ha
  constructor
  · have : (s.powersetCard (k + 1)).filter (fun t => a ∉ t) = (s.erase a).powersetCard (k + 1) := by
      ext t
      simp only [mem_filter, mem_powersetCard, subset_erase]
      tauto
    rw [this, card_powersetCard, hcard]
  · rw [← hcard, ← card_powersetCard]
    apply card_nbij' (fun t => t.erase a) (fun t => insert a t)
    · intro t ht
      have ht' : (t ⊆ s ∧ t.card = k + 1) ∧ a ∈ t := by simpa using ht
      have : t.erase a ⊆ s.erase a ∧ (t.erase a).card = k := by
        refine ⟨erase_subset_erase a ht'.1.1, ?_⟩
        rw [card_erase_of_mem ht'.2, ht'.1.2]; rfl
      simpa using this
    · intro t ht
      have ht' : t ⊆ s.erase a ∧ t.card = k := by simpa using ht
      have hat : a ∉ t := (subset_erase.mp ht'.1).2
      have : (insert a t ⊆ s ∧ (insert a t).card = k + 1) ∧ a ∈ insert a t :=
        ⟨⟨insert_subset ha (ht'.1.trans (erase_subset a s)), by
          rw [card_insert_of_notMem hat, ht'.2]⟩, mem_insert_self a t⟩
      simpa using this
    · intro t ht
      have ht' : (t ⊆ s ∧ t.card = k + 1) ∧ a ∈ t := by simpa using ht
      exact insert_erase ht'.2
    · intro t ht
      have ht' : t ⊆ s.erase a ∧ t.card = k := by simpa using ht
      exact erase_insert (subset_erase.mp ht'.1).2

/-- A row adds to `2^n`: `C(n, 0) + C(n, 1) + ⋯ + C(n, n) = 2^n`, for every `n`. -/
theorem row_sum_eq_two_pow (n : ℕ) :
    ∑ k ∈ range (n + 1), n.choose k = 2 ^ n := by
  exact Nat.sum_range_choose n

-- The two-song sets from five songs: 6 leave Ember out, 4 keep it in, 10 in all.
example : Nat.choose 5 2 = 10 := by decide
example : Nat.choose 4 2 = 6 ∧ Nat.choose 4 1 = 4 ∧ 6 + 4 = 10 := by decide
-- The same split, by listing every two-song set of five songs (song 4 is Ember).
example : ((univ : Finset (Fin 5)).powersetCard 2).card = 10 := by decide
example : (((univ : Finset (Fin 5)).powersetCard 2).filter (fun t => (4 : Fin 5) ∉ t)).card = 6 := by
  decide
example : (((univ : Finset (Fin 5)).powersetCard 2).filter (fun t => (4 : Fin 5) ∈ t)).card = 4 := by
  decide
-- The ends of a row: C(n, 0) = 0 + 1 at n = 5, and nothing past the end.
example : Nat.choose 5 0 = 1 ∧ Nat.choose 4 0 = 1 ∧ Nat.choose 4 5 = 0 := by decide
-- Row 3 is 1 3 3 1, so row 4 is 1 4 6 4 1: the 6 is 3 + 3, each 4 is 1 + 3.
example : (List.range 4).map (Nat.choose 3) = [1, 3, 3, 1] := by decide
example : (List.range 5).map (Nat.choose 4) = [1, 4, 6, 4, 1] := by decide
example : Nat.choose 4 2 = 3 + 3 ∧ Nat.choose 4 1 = 1 + 3 := by decide
-- Row 5 is 1 5 10 10 5 1 and adds to 32.
example : (List.range 6).map (Nat.choose 5) = [1, 5, 10, 10, 5, 1] := by decide
example : ∑ k ∈ range 6, Nat.choose 5 k = 32 ∧ 2 ^ 5 = 32 := by decide
example : 1 + 5 + 10 + 10 + 5 + 1 = 32 := by decide
-- Row 10 is 1 10 45 120 210 252 210 120 45 10 1 and adds to 1024.
example : (List.range 11).map (Nat.choose 10) = [1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1] := by
  decide
example : ∑ k ∈ range 11, Nat.choose 10 k = 1024 ∧ 2 ^ 10 = 1024 := by decide
-- Row 4 read as one number is 11 multiplied in 4 times; row 5 carries to 11^5.
example : 10000 + 4000 + 600 + 40 + 1 = 14641 ∧ 11 * 11 * 11 * 11 = 14641 := by decide
example : 100000 + 5 * 10000 + 10 * 1000 + 10 * 100 + 5 * 10 + 1 = 161051 ∧ 11 ^ 5 = 161051 := by
  norm_num
-- The mistakes: dropping the empty and full sets gives 30; adding C(4,2) twice gives 12;
-- counting running orders of two of five songs gives 20.
example : 32 - 2 = 30 ∧ Nat.choose 4 2 + Nat.choose 4 2 = 12 := by decide
example : ((univ : Finset (Fin 5 × Fin 5)).filter (fun p => p.1 ≠ p.2)).card = 20 := by decide
-- Starting the rows at one: row 4 adds to 16, not 32.
example : ∑ k ∈ range 5, Nat.choose 4 k = 16 := by decide

#print axioms pascals_rule
#print axioms picks_split_by_one_item
#print axioms row_sum_eq_two_pow
