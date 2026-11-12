-- Branch and bound: depth-first branch and bound on a yes-or-no budget problem, with any valid ceiling and any free act to split on, returns the best total sales of any booking within budget.
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Data.Rat.Cast.Order
import Mathlib.Order.Bounds.Basic
import Mathlib.Logic.Function.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

open Finset

namespace BranchAndBound

/-- A node: each act is fixed as booked (`some true`), fixed as skipped (`some false`), or still
free (`none`). -/
abbrev Node (n : ℕ) := Fin n → Option Bool

/-- A booking `S` (the set of acts booked) lies in node `N` when it agrees with every fixed act. -/
def InNode {n : ℕ} (N : Node n) (S : Finset (Fin n)) : Prop :=
  ∀ j b, N j = some b → (j ∈ S ↔ b = true)

/-- Depth-first branch and bound, "book it" before "skip it".
`relax N` is the node's relaxation: `none` means infeasible; `some (z, w)` gives the ceiling `z`,
and `w = some S` when the relaxed answer is already a whole booking `S`.
`pick N` is the act to split on. `inc` is the incumbent; the result is the final incumbent.
The first argument is a depth limit: each split fixes one more act. -/
def search {n : ℕ} (relax : Node n → Option (ℚ × Option (Finset (Fin n))))
    (pick : Node n → Fin n) : ℕ → Node n → ℚ → ℚ
  | 0, _, inc => inc
  | k + 1, N, inc =>
    match relax N with
    | none => inc                                   -- infeasible: closed
    | some (z, w) =>
      if z ≤ inc then inc                           -- bound: closed
      else
        match w with
        | some _ => z                               -- whole: new incumbent
        | none =>                                   -- split on `pick N`
          let j := pick N
          search relax pick k (Function.update N j (some false))
            (search relax pick k (Function.update N j (some true)) inc)

/-- A booking in a child of a split lies in the parent. -/
theorem inNode_of_update {n : ℕ} (N : Node n) (j : Fin n) (hj : N j = none) (b : Bool)
    (S : Finset (Fin n)) (h : InNode (Function.update N j (some b)) S) : InNode N S := by
  intro i c hi
  have hij : i ≠ j := by
    rintro rfl
    rw [hj] at hi
    cases hi
  apply h i c
  rw [Function.update_of_ne hij]
  exact hi

/-- A booking in the parent lies in the child that agrees with it on the split act. -/
theorem inNode_update_of {n : ℕ} (N : Node n) (j : Fin n) (S : Finset (Fin n))
    (h : InNode N S) (b : Bool) (hb : j ∈ S ↔ b = true) :
    InNode (Function.update N j (some b)) S := by
  intro i c hi
  by_cases hij : i = j
  · subst hij
    rw [Function.update_self] at hi
    cases hi
    exact hb
  · rw [Function.update_of_ne hij] at hi
    exact h i c hi

/-- Splitting fixes one more act, so the number of free acts drops. -/
theorem free_card_update_lt {n : ℕ} (N : Node n) (j : Fin n) (hj : N j = none) (b : Bool) :
    (univ.filter (fun i => Function.update N j (some b) i = none)).card
      < (univ.filter (fun i => N i = none)).card := by
  apply Finset.card_lt_card
  rw [Finset.ssubset_iff_of_subset]
  · refine ⟨j, by simp [hj], by simp⟩
  · intro i hi
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hi ⊢
    by_cases hij : i = j
    · subst hij; exact hj
    · rwa [Function.update_of_ne hij] at hi

/-- The search invariant: the result is at least the incumbent, at least every fitting booking
in the node, and is either the incumbent or the sales of a fitting booking in the node. -/
theorem search_spec {n : ℕ} (fee sales : Fin n → ℕ) (W : ℕ)
    (relax : Node n → Option (ℚ × Option (Finset (Fin n)))) (pick : Node n → Fin n)
    (h_infeasible : ∀ N, relax N = none → ∀ S, InNode N S → ¬ ∑ j ∈ S, fee j ≤ W)
    (h_ceiling : ∀ N z w, relax N = some (z, w) →
      ∀ S, InNode N S → ∑ j ∈ S, fee j ≤ W → (∑ j ∈ S, (sales j : ℚ)) ≤ z)
    (h_whole : ∀ N z S, relax N = some (z, some S) →
      InNode N S ∧ ∑ j ∈ S, fee j ≤ W ∧ (∑ j ∈ S, (sales j : ℚ)) = z)
    (h_split : ∀ N z, relax N = some (z, none) → N (pick N) = none) (k : ℕ) :
    ∀ (N : Node n) (inc : ℚ), (univ.filter (fun j => N j = none)).card < k →
      inc ≤ search relax pick k N inc ∧
      (∀ S, InNode N S → ∑ j ∈ S, fee j ≤ W →
        (∑ j ∈ S, (sales j : ℚ)) ≤ search relax pick k N inc) ∧
      (search relax pick k N inc = inc ∨ ∃ S, InNode N S ∧ ∑ j ∈ S, fee j ≤ W ∧
        (∑ j ∈ S, (sales j : ℚ)) = search relax pick k N inc) := by
  induction k with
  | zero => intro N inc h; omega
  | succ k ih =>
    intro N inc hk
    rw [search]
    rcases hr : relax N with _ | ⟨z, w⟩
    · refine ⟨le_rfl, fun S hS hfit => absurd hfit (h_infeasible N hr S hS), Or.inl rfl⟩
    · dsimp only
      by_cases hz : z ≤ inc
      · rw [ite_eq_left_of_eq_true _ _ (eq_true hz)]
        exact ⟨le_rfl, fun S hS hfit => (h_ceiling N z w hr S hS hfit).trans hz, Or.inl rfl⟩
      · rw [ite_eq_right_of_eq_false _ _ (eq_false hz)]
        rcases w with _ | S0
        · dsimp only
          have hj := h_split N z hr
          set j := pick N
          have h1 := ih (Function.update N j (some true)) inc
            (by have := free_card_update_lt N j hj true; omega)
          set r1 := search relax pick k (Function.update N j (some true)) inc
          have h2 := ih (Function.update N j (some false)) r1
            (by have := free_card_update_lt N j hj false; omega)
          set r2 := search relax pick k (Function.update N j (some false)) r1
          obtain ⟨a1, b1, c1⟩ := h1
          obtain ⟨a2, b2, c2⟩ := h2
          refine ⟨a1.trans a2, ?_, ?_⟩
          · intro S hS hfit
            by_cases hjS : j ∈ S
            · exact (b1 S (inNode_update_of N j S hS true (by simp [hjS])) hfit).trans a2
            · exact b2 S (inNode_update_of N j S hS false (by simp [hjS])) hfit
          · rcases c2 with e2 | ⟨S, hS, hfit, hs⟩
            · rcases c1 with e1 | ⟨S, hS, hfit, hs⟩
              · exact Or.inl (e2.trans e1)
              · exact Or.inr ⟨S, inNode_of_update N j hj true S hS, hfit, hs.trans e2.symm⟩
            · exact Or.inr ⟨S, inNode_of_update N j hj false S hS, hfit, hs⟩
        · dsimp only
          obtain ⟨hS, hfit, hs⟩ := h_whole N z S0 hr
          refine ⟨le_of_lt (lt_of_not_ge hz), fun S hS' hfit' => h_ceiling N z _ hr S hS' hfit',
            Or.inr ⟨S0, hS, hfit, hs⟩⟩

/-- **Branch and bound finds the best booking.** Take acts with whole-number fees `fee j` and
sales `sales j`, and a budget `W`; a booking's sales are the sum of its acts' sales. Suppose each
node's relaxation reports "infeasible" only when no booking in the node fits the budget, its
ceiling really is a ceiling (no fitting booking in the node sells more), a "whole" answer really
is a fitting booking in the node selling exactly the ceiling, and every split is on a free act.
Then running the search from the root with no booking in hand until no case is left open
returns exactly the best sales of any booking within budget. -/
theorem branch_and_bound_finds_best {n : ℕ} (fee sales : Fin n → ℕ) (W : ℕ)
    (relax : Node n → Option (ℚ × Option (Finset (Fin n)))) (pick : Node n → Fin n)
    (h_infeasible : ∀ N, relax N = none → ∀ S, InNode N S → ¬ ∑ j ∈ S, fee j ≤ W)
    (h_ceiling : ∀ N z w, relax N = some (z, w) →
      ∀ S, InNode N S → ∑ j ∈ S, fee j ≤ W → (∑ j ∈ S, (sales j : ℚ)) ≤ z)
    (h_whole : ∀ N z S, relax N = some (z, some S) →
      InNode N S ∧ ∑ j ∈ S, fee j ≤ W ∧ (∑ j ∈ S, (sales j : ℚ)) = z)
    (h_split : ∀ N z, relax N = some (z, none) → N (pick N) = none) :
    IsGreatest {x : ℚ | ∃ S : Finset (Fin n), ∑ j ∈ S, fee j ≤ W ∧ x = ∑ j ∈ S, (sales j : ℚ)}
      (search relax pick (n + 1) (fun _ => none) (-1)) := by
  obtain ⟨a, b, c⟩ := search_spec fee sales W relax pick h_infeasible h_ceiling h_whole h_split
    (n + 1) (fun _ => none) (-1) (by simp)
  have hroot : ∀ S : Finset (Fin n), InNode (fun _ => none) S := by
    intro S j b h; cases h
  refine ⟨?_, ?_⟩
  · rcases c with e | ⟨S, -, hfit, hs⟩
    · exfalso
      have := b ∅ (hroot ∅) (by simp)
      simp at this
      linarith
    · exact ⟨S, hfit, hs.symm⟩
  · rintro x ⟨S, hfit, rfl⟩
    exact b S (hroot S) hfit

/-- **A split loses nothing and counts nothing twice.** Splitting a node on a free act `j` into
"`j` booked" and "`j` skipped": a booking lies in the node exactly when it lies in one of the two
children, and it never lies in both. -/
theorem split_shares_out {n : ℕ} (N : Node n) (j : Fin n) (hj : N j = none)
    (S : Finset (Fin n)) :
    (InNode N S ↔
      (InNode (Function.update N j (some true)) S ∨ InNode (Function.update N j (some false)) S)) ∧
    ¬ (InNode (Function.update N j (some true)) S ∧ InNode (Function.update N j (some false)) S) := by
  refine ⟨⟨fun h => ?_, fun h => ?_⟩, ?_⟩
  · by_cases hjS : j ∈ S
    · exact Or.inl (inNode_update_of N j S h true (by simp [hjS]))
    · exact Or.inr (inNode_update_of N j S h false (by simp [hjS]))
  · rcases h with h | h
    · exact inNode_of_update N j hj true S h
    · exact inNode_of_update N j hj false S h
  · rintro ⟨h1, h2⟩
    have e1 := h1 j true (by simp)
    have e2 := h2 j false (by simp)
    simp_all

/-- **The price certificate is a ceiling.** Put a price `lam ≥ 0` on each unit of fee. For any
booking in a node, whole or fractional (each act taken in a share between 0 and 1, booked acts in
full, skipped acts not at all, fees within budget), its sales are at most the sales of the acts
already booked, plus `lam` times the budget left, plus `max(0, v_j - lam * f_j)` summed over the
free acts. -/
theorem price_ceiling {n : ℕ} (fee sales : Fin n → ℕ) (W : ℕ) (N : Node n) (lam : ℚ)
    (hlam : 0 ≤ lam) (x : Fin n → ℚ) (hx0 : ∀ j, 0 ≤ x j) (hx1 : ∀ j, x j ≤ 1)
    (hbooked : ∀ j, N j = some true → x j = 1) (hskipped : ∀ j, N j = some false → x j = 0)
    (hfit : ∑ j, (fee j : ℚ) * x j ≤ W) :
    ∑ j, (sales j : ℚ) * x j ≤
      (∑ j ∈ univ.filter (fun j => N j = some true), (sales j : ℚ))
      + lam * ((W : ℚ) - ∑ j ∈ univ.filter (fun j => N j = some true), (fee j : ℚ))
      + ∑ j ∈ univ.filter (fun j => N j = none), max 0 ((sales j : ℚ) - lam * fee j) := by
  have key : ∀ j, (sales j : ℚ) * x j ≤
      ((if N j = some true then (sales j : ℚ) else 0)
        + (if N j = none then max 0 ((sales j : ℚ) - lam * fee j) else 0))
      + lam * ((fee j : ℚ) * x j) - lam * (if N j = some true then (fee j : ℚ) else 0) := by
    intro j
    rcases hN : N j with _ | _ | _
    · simp only [reduceCtorEq, ite_false, ite_true]
      have m1 := le_max_left 0 ((sales j : ℚ) - lam * fee j)
      have m2 := le_max_right 0 ((sales j : ℚ) - lam * fee j)
      nlinarith [mul_nonneg (sub_nonneg.mpr m2) (hx0 j), mul_nonneg m1 (sub_nonneg.mpr (hx1 j))]
    · simp only [hskipped j hN, Option.some.injEq, Bool.false_eq_true, reduceCtorEq, ite_false]
      ring_nf; rfl
    · simp only [hbooked j hN, ite_true, reduceCtorEq, ite_false]
      ring_nf; rfl
  have hsum := Finset.sum_le_sum (fun j (_ : j ∈ (univ : Finset (Fin n))) => key j)
  rw [Finset.sum_sub_distrib, Finset.sum_add_distrib, Finset.sum_add_distrib,
    ← Finset.mul_sum, ← Finset.mul_sum, ← Finset.sum_filter, ← Finset.sum_filter,
    ← Finset.sum_filter] at hsum
  nlinarith [mul_le_mul_of_nonneg_left hfit hlam]

/-! The card's festival: acts A, B, C, D, E are `0, 1, 2, 3, 4`; fees and sales in £k. -/

/-- Fees, £k. -/
def fee : Fin 5 → ℕ := ![30, 80, 80, 30, 90]
/-- Extra ticket sales, £k. -/
def sales : Fin 5 → ℕ := ![70, 130, 115, 40, 90]

/-- 32 possible bookings, and 16 of them fit the £150k budget. -/
example : (univ : Finset (Finset (Fin 5))).card = 32 := by decide
example : ((univ : Finset (Finset (Fin 5))).filter (fun S => ∑ j ∈ S, fee j ≤ 150)).card = 16 := by
  decide

/-- A, B and D cost £140k and sell £240k. -/
example : ∑ j ∈ ({0, 1, 3} : Finset (Fin 5)), fee j = 140 ∧
    ∑ j ∈ ({0, 1, 3} : Finset (Fin 5)), sales j = 240 := by decide

/-- No booking within £150k sells more than £240k, and A, B, D is the only one that reaches it. -/
example : ∀ S : Finset (Fin 5), ∑ j ∈ S, fee j ≤ 150 → ∑ j ∈ S, sales j ≤ 240 := by decide
example : ((univ : Finset (Finset (Fin 5))).filter
    (fun S => ∑ j ∈ S, fee j ≤ 150 ∧ ∑ j ∈ S, sales j = 240)) = {{0, 1, 3}} := by decide

/-- Root ceiling: A and B whole plus half of C gives 70 + 130 + 57.5 = 257.5, and the price
115/80 per £k gives the same number. -/
example : (70 + 130 + (40 : ℚ) / 80 * 115 : ℚ) = 515 / 2 := by norm_num
example : (23 / 16 : ℚ) * 150 + max 0 (70 - 23 / 16 * 30) + max 0 (130 - 23 / 16 * 80)
    + max 0 (115 - 23 / 16 * 80) + max 0 (40 - 23 / 16 * 30) + max 0 (90 - 23 / 16 * 90)
    = 515 / 2 := by norm_num

/-- Node 8 (C skipped, E booked): 90 + 70 + three-eighths of 130 = 208.75, not above 225. -/
example : (90 + 70 + (30 : ℚ) / 80 * 130) = 835 / 4 ∧ (835 / 4 : ℚ) ≤ 225 := by norm_num

/-- What breaks: stopping at A, C, D gives 225; rounding down gives A, B at 200; rounding up
books A, B, C for 190 against 150; biggest-sales-first gives a false ceiling 230.625 below 240;
if A and B together sell 30 less, A, B, D earns 210 and A, C, D's 225 is better. -/
example : ∑ j ∈ ({0, 2, 3} : Finset (Fin 5)), sales j = 225 ∧
    ∑ j ∈ ({0, 1} : Finset (Fin 5)), sales j = 200 ∧
    ∑ j ∈ ({0, 1, 2} : Finset (Fin 5)), fee j = 190 := by decide
example : (130 + 115 * (70 : ℚ) / 80) = 1845 / 8 ∧ (1845 / 8 : ℚ) < 240 := by norm_num
example : (240 - 30 : ℕ) = 210 ∧ 210 < 225 := by norm_num

#print axioms inNode_of_update
#print axioms inNode_update_of
#print axioms free_card_update_lt
#print axioms search_spec
#print axioms branch_and_bound_finds_best
#print axioms split_shares_out
#print axioms price_ceiling

end BranchAndBound
