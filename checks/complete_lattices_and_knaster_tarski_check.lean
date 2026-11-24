-- Knaster-Tarski: an order-keeping map on a complete lattice has a least and a greatest fixed point, given by Tarski's formulas, and on a finite lattice the climb from the bottom reaches the least one.
import Mathlib.Order.FixedPoints
import Mathlib.Order.Iterate
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Fintype.Card
import Mathlib.Order.CompleteBooleanAlgebra
import Mathlib.Data.Finset.Prod
import Mathlib.Algebra.Field.Rat
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.Pigeonhole

/-- Knaster-Tarski. If a rule `f` keeps order on a complete lattice (every collection has a meet
and a join), it has a least fixed point and a greatest fixed point. The least is the meet of all
closed elements (`f S ≤ S`); the greatest is the join of all elements the rule does not shrink
(`S ≤ f S`). -/
theorem monotone_map_has_least_and_greatest_fixed_point {α : Type*} [CompleteLattice α]
    (f : α → α) (hf : Monotone f) :
    IsLeast (Function.fixedPoints f) (sInf {S | f S ≤ S}) ∧
      IsGreatest (Function.fixedPoints f) (sSup {S | S ≤ f S}) := by
  exact ⟨OrderHom.isLeast_lfp ⟨f, hf⟩, OrderHom.isGreatest_gfp ⟨f, hf⟩⟩

/-- The climb. With finitely many elements, applying an order-keeping rule again and again from
the bottom `⊥` reaches the least fixed point after finitely many steps. -/
theorem climb_from_bottom_reaches_least_fixed_point {α : Type*} [CompleteLattice α] [Finite α]
    (f : α → α) (hf : Monotone f) :
    ∃ n : ℕ, IsLeast (Function.fixedPoints f) (f^[n] ⊥) := by
  have hmono : Monotone fun n => f^[n] ⊥ := Monotone.monotone_iterate_of_le_map hf bot_le
  have hle : ∀ x ∈ Function.fixedPoints f, ∀ k : ℕ, f^[k] ⊥ ≤ x := by
    intro x hx k
    induction k with
    | zero => exact bot_le
    | succ k ih =>
      rw [Function.iterate_succ_apply']
      calc f (f^[k] ⊥) ≤ f x := hf ih
        _ = x := hx
  obtain ⟨m, n, hmn, heq⟩ := Finite.exists_ne_map_eq_of_infinite (fun n : ℕ => f^[n] ⊥)
  wlog h : m < n generalizing m n
  · exact this n m (Ne.symm hmn) heq.symm (lt_of_le_of_ne (not_lt.mp h) (Ne.symm hmn))
  refine ⟨m, ?_, fun x hx => hle x hx m⟩
  have h1 : f^[m] ⊥ ≤ f^[m + 1] ⊥ := hmono (Nat.le_succ m)
  have h2 : f^[m + 1] ⊥ ≤ f^[n] ⊥ := hmono h
  have h3 : f^[m + 1] ⊥ = f^[m] ⊥ := le_antisymm (heq ▸ h2) h1
  show f (f^[m] ⊥) = f^[m] ⊥
  rw [← Function.iterate_succ_apply' f m]
  exact h3

/-- Order-keeping is needed: the complement rule (swap in for out) on the subsets of a nonempty
set has no fixed point at all. -/
theorem complement_rule_has_no_fixed_point {β : Type*} [Nonempty β] (S : Set β) :
    Sᶜ ≠ S := by
  intro h
  obtain ⟨x⟩ := ‹Nonempty β›
  have h' : x ∈ Sᶜ ↔ x ∈ S := by rw [h]
  rw [Set.mem_compl_iff] at h'
  exact (iff_not_self h'.symm).elim

/-! The card's example: the 16 subsets of {1, 2, 3, 4}, and
`f(S) = {1}` plus every step of `S` along the arrows 1 → 2, 3 → 4, 4 → 3. -/

/-- Where each record points: 1 → 2, 3 → 4, 4 → 3. -/
def arrows : ℕ → Finset ℕ
  | 1 => {2}
  | 3 => {4}
  | 4 => {3}
  | _ => ∅

/-- The card's rule: keep record 1, plus everything `S` points to. -/
def rule (S : Finset ℕ) : Finset ℕ := {1} ∪ S.biUnion arrows

/-- The 16 guesses: all subsets of {1, 2, 3, 4}. -/
def guesses : Finset (Finset ℕ) := ({1, 2, 3, 4} : Finset ℕ).powerset

-- The climb from the empty set: {}, {1}, {1, 2}, {1, 2}.
example : rule ∅ = {1} := by decide
example : rule {1} = {1, 2} := by decide
example : rule {1, 2} = {1, 2} := by decide
-- Down from the top: {1, 2, 3, 4} stays.
example : rule {1, 2, 3, 4} = {1, 2, 3, 4} := by decide
-- 16 guesses; order kept on all 81 pairs S inside T.
example : guesses.card = 16 := by decide
example : ((guesses ×ˢ guesses).filter (fun p => p.1 ⊆ p.2)).card = 81 := by decide
example : ∀ p ∈ (guesses ×ˢ guesses).filter (fun p => p.1 ⊆ p.2), rule p.1 ⊆ rule p.2 := by
  decide
-- The fixed points are exactly {1, 2} and {1, 2, 3, 4}.
example : guesses.filter (fun S => rule S = S) = {{1, 2}, {1, 2, 3, 4}} := by decide
-- 2 closed sets (f(S) inside S), sharing {1, 2}; 6 sets inside their own f(S), joined to {1, 2, 3, 4}.
example : (guesses.filter (fun S => rule S ⊆ S)).card = 2 := by decide
example : guesses.filter (fun S => rule S ⊆ S) = {{1, 2}, {1, 2, 3, 4}} := by decide
example : ({1, 2} : Finset ℕ) ∩ {1, 2, 3, 4} = {1, 2} := by decide
example : (guesses.filter (fun S => S ⊆ rule S)).card = 6 := by decide
example : (guesses.filter (fun S => S ⊆ rule S)).sup id = {1, 2, 3, 4} := by decide
-- The climb from {3} cycles: {3}, {1, 4}, {1, 2, 3}, {1, 2, 4}, {1, 2, 3}.
example : rule {3} = {1, 4} := by decide
example : rule {1, 4} = {1, 2, 3} := by decide
example : rule {1, 2, 3} = {1, 2, 4} := by decide
example : rule {1, 2, 4} = {1, 2, 3} := by decide
-- The complement rule has 0 fixed points among the 16 guesses.
example : (guesses.filter (fun S => ({1, 2, 3, 4} : Finset ℕ) \ S = S)).card = 0 := by decide
-- The fractions climb x ↦ (2x + 2) / (x + 2): 0, 1, 4/3, 7/5, 24/17, 41/29.
example : ((2 * (24 / 17 : ℚ) + 2) / (24 / 17 + 2)) = 41 / 29 := by norm_num
example : ((2 * (7 / 5 : ℚ) + 2) / (7 / 5 + 2)) = 24 / 17 := by norm_num

#print axioms monotone_map_has_least_and_greatest_fixed_point
#print axioms climb_from_bottom_reaches_least_fixed_point
#print axioms complement_rule_has_no_fixed_point
