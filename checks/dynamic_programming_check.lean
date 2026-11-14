-- Dynamic programming: the rucksack table rule computes the most value of any packing that fits, and the plain recursion makes 2^(n+1) - 1 calls when every item fits.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Monoid.Canonical.Defs
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Data.Finset.Powerset

open Finset

namespace DynamicProgramming

/-- The table rule from the card. Items are numbered from 0, so item `i` here is item `i + 1`
on the card. `m i` is its weight in whole kilograms, `v i` is the money it sells for.
`K m v i w` is the cell for the first `i` items with `w` kg of room:
`K(0, w) = 0`, and `K(i+1, w) = max(K(i, w), v + K(i, w - m))`, the second option only when the item fits. -/
def K {α : Type*} [Add α] [Zero α] [Max α] (m : ℕ → ℕ) (v : ℕ → α) : ℕ → ℕ → α
  | 0, _ => 0
  | i + 1, w => if m i ≤ w then max (K m v i w) (v i + K m v i (w - m i)) else K m v i w

/-- The calls a plain recursion (no notebook) makes to answer `K(i, w)`: one for itself,
one sub-call for "leave the item out", and one more for "put it in" when the item fits. -/
def calls (m : ℕ → ℕ) : ℕ → ℕ → ℕ
  | 0, _ => 1
  | i + 1, w => 1 + calls m i w + (if m i ≤ w then calls m i (w - m i) else 0)

/-- The card's main claim: with whole-number weights and each item used at most once,
the table cell `K(i, w)` equals the most money over all packings (sets of items) drawn
from the first `i` items whose total weight is at most `w`. -/
theorem table_gives_best_packing {α : Type*} [AddCommMonoid α] [LinearOrder α] [OrderBot α]
    [CanonicallyOrderedAdd α] (m : ℕ → ℕ) (v : ℕ → α) (i w : ℕ) :
    K m v i w =
      ((range i).powerset.filter (fun S => ∑ j ∈ S, m j ≤ w)).sup (fun S => ∑ j ∈ S, v j) := by
  induction i generalizing w with
  | zero =>
    simp [K, filter_singleton]
  | succ i ih =>
    rw [range_add_one, powerset_insert, filter_union, sup_union, filter_image, sup_image]
    have himg : ∀ S ∈ (range i).powerset, ∑ j ∈ insert i S, m j = m i + ∑ j ∈ S, m j ∧
        ∑ j ∈ insert i S, v j = v i + ∑ j ∈ S, v j := by
      intro S hS
      have hiS : i ∉ S := fun h => by
        have := mem_powerset.1 hS h
        simp at this
      exact ⟨sum_insert hiS, sum_insert hiS⟩
    have hsup2 : (((range i).powerset.filter fun S => ∑ j ∈ insert i S, m j ≤ w).sup
        ((fun S => ∑ j ∈ S, v j) ∘ insert i)) =
        ((range i).powerset.filter fun S => m i + ∑ j ∈ S, m j ≤ w).sup
        (fun S => v i + ∑ j ∈ S, v j) := by
      rw [filter_congr (q := fun S => m i + ∑ j ∈ S, m j ≤ w)
        (fun S hS => by rw [(himg S hS).1])]
      apply sup_congr rfl
      intro S hS
      simp only [Function.comp_apply]
      exact (himg S (mem_filter.1 hS).1).2
    rw [hsup2, K, ← ih]
    split_ifs with hm
    · have hfil : ((range i).powerset.filter fun S => m i + ∑ j ∈ S, m j ≤ w) =
          ((range i).powerset.filter fun S => ∑ j ∈ S, m j ≤ w - m i) :=
        filter_congr (fun S _ => by omega)
      rw [hfil]
      have hne : ((range i).powerset.filter fun S => ∑ j ∈ S, m j ≤ w - m i).Nonempty :=
        ⟨∅, by simp⟩
      have hmono : Monotone (fun x : α => v i + x) := fun a b hab => by dsimp only; gcongr
      rw [← Function.comp_def (fun x : α => v i + x),
        ← apply_sup_eq_sup_comp_of_nonempty hmono hne, ← ih]
    · have hfil : ((range i).powerset.filter fun S => m i + ∑ j ∈ S, m j ≤ w) = ∅ :=
        filter_false_of_mem (fun S _ => by omega)
      rw [hfil, sup_empty, sup_bot_eq]

/-- Overlapping subproblems, counted: when every item fits (the total weight of all `n`
items is at most the room `w`), a plain recursion on `n` items makes `2^(n+1) - 1` calls. -/
theorem plain_recursion_calls_when_all_fit (m : ℕ → ℕ) (n w : ℕ)
    (hfit : ∑ j ∈ range n, m j ≤ w) :
    calls m n w = 2 ^ (n + 1) - 1 := by
  induction n generalizing w with
  | zero => simp [calls]
  | succ n ih =>
    rw [sum_range_succ] at hfit
    have h1 : m n ≤ w := by omega
    have h2 := ih w (by omega)
    have h3 := ih (w - m n) (by omega)
    have h4 : 1 ≤ 2 ^ (n + 1) := Nat.one_le_two_pow
    simp only [calls, h1, ↓reduceIte, h2, h3]
    rw [pow_succ 2 (n + 1)]
    omega

/-- The trader's six items: books, soap, wool, cheese, honey, candles. -/
def kg (i : ℕ) : ℕ := [6, 4, 7, 5, 3, 2].getD i 0
def gbp (i : ℕ) : ℕ := [100, 60, 135, 95, 80, 50].getD i 0

-- The last cell: £310 from six items in 15 kg.
example : K kg gbp 6 15 = 310 := by decide
-- Cells from the picture and the table.
example : K kg gbp 3 10 = 160 := by decide
example : K kg gbp 5 13 = 240 := by decide
example : K kg gbp 5 15 = 310 := by decide
example : K kg gbp 4 15 = 255 := by decide
example : K kg gbp 4 12 = 230 := by decide
example : K kg gbp 3 15 = 235 := by decide
-- Wool, cheese and honey (items 3, 4, 5 on the card) weigh exactly 15 kg and fetch £310.
example : ∑ j ∈ ({2, 3, 4} : Finset ℕ), kg j = 15 ∧ ∑ j ∈ ({2, 3, 4} : Finset ℕ), gbp j = 310 := by
  decide
-- 64 packings, 40 of which fit in 15 kg.
example : (range 6).powerset.card = 64 := by decide
example : ((range 6).powerset.filter (fun S => ∑ j ∈ S, kg j ≤ 15)).card = 40 := by decide
-- Brute force over all 64 packings agrees: the best is £310.
example : ((range 6).powerset.filter (fun S => ∑ j ∈ S, kg j ≤ 15)).sup
    (fun S => ∑ j ∈ S, gbp j) = 310 := by decide
-- A plain recursion on the six items makes 96 calls.
example : calls kg 6 15 = 96 := by decide
-- Items of 1, 2, 4, 8, 16, 32 kg in 63 kg of room: 127 calls.
example : calls (fun i => 2 ^ i) 6 63 = 127 := by decide
-- T(8) = 511 and 12 items take 8,191 calls when all fit.
example : 2 ^ (8 + 1) - 1 = 511 := by decide
example : 2 ^ (12 + 1) - 1 = 8191 := by decide
-- Small questions: 7 × 16 = 112; table cells: 6 × 16 = 96; 20 items allow 1,048,576 packings.
example : (6 + 1) * (15 + 1) = 112 ∧ 6 * (15 + 1) = 96 ∧ 2 ^ 20 = 1048576 := by decide

#print axioms table_gives_best_packing
#print axioms plain_recursion_calls_when_all_fit

end DynamicProgramming
