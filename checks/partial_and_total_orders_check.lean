-- Orders: divides is a partial order on the divisors of any number, a finite order is rebuilt from its covers, and on the divisors of 12 divides is partial but not total while less-than-or-equal is total.
import Mathlib.NumberTheory.Divisors
import Mathlib.Order.Cover
import Mathlib.Order.Interval.Finset.Basic
import Mathlib.Logic.Relation
import Mathlib.Basic.Real.Basic

open Relation

/-- "Divides" passes the three order tests on the divisors of any whole number n:
every divisor divides itself (reflexive); if a divides b and b divides a then a = b
(antisymmetric); if a divides b and b divides c then a divides c (transitive).
So divides is a partial order on the divisors of n. -/
theorem dvd_is_partial_order_on_divisors (n : ℕ) :
    (∀ a ∈ n.divisors, a ∣ a) ∧
    (∀ a ∈ n.divisors, ∀ b ∈ n.divisors, a ∣ b → b ∣ a → a = b) ∧
    (∀ a ∈ n.divisors, ∀ b ∈ n.divisors, ∀ c ∈ n.divisors, a ∣ b → b ∣ c → a ∣ c) := by
  refine ⟨fun a _ => dvd_refl a, fun a _ b _ h1 h2 => Nat.dvd_antisymm h1 h2,
    fun a _ b _ c _ h1 h2 => dvd_trans h1 h2⟩

/-- The Hasse diagram carries the whole order on a finite set: put back the self-pairs
and chain the covers (steps up with nothing strictly in between) over and over, and
you get exactly the pairs a ≤ b. -/
theorem finite_order_rebuilt_from_covers {α : Type*} [PartialOrder α] [Finite α] (a b : α) :
    a ≤ b ↔ ReflTransGen (· ⋖ ·) a b := by
  classical
  haveI := Fintype.ofFinite α
  haveI : LocallyFiniteOrder α := Fintype.toLocallyFiniteOrder
  exact le_iff_reflTransGen_covBy

/-- On the number line there are no covers: between any two points there is another,
so no step up has nothing in between, and there is no Hasse diagram to draw. -/
theorem number_line_has_no_covers (a b : ℝ) : ¬ a ⋖ b := by
  exact not_covBy_of_denselyOrdered

/-! ### The card's worked numbers on the six divisors of 12 -/

-- The six divisors of 12.
example : Nat.divisors 12 = {1, 2, 3, 4, 6, 12} := by decide

-- 6 + 4 + 3 + 2 + 2 + 1 = 18 pairs where the first divides the second.
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter (fun p => p.1 ∣ p.2)).card = 18 := by
  decide

-- Of those, 18 − 6 = 12 pairs of two different divisors (strict divides; it fails reflexivity).
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 ∣ p.2 ∧ p.1 ≠ p.2)).card = 12 := by
  decide

-- 6 + 5 + 4 + 3 + 2 + 1 = 21 pairs where the first is less than or equal to the second.
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter (fun p => p.1 ≤ p.2)).card = 21 := by
  decide

-- 6 × 5 ÷ 2 = 15 pairs of two different divisors in all.
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter (fun p => p.1 < p.2)).card = 15 := by
  decide

-- The 3 pairs that never compare under divides: 2 and 3, 3 and 4, 4 and 6.
example : (Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 < p.2 ∧ ¬ p.1 ∣ p.2 ∧ ¬ p.2 ∣ p.1) = {(2, 3), (3, 4), (4, 6)} := by
  decide

-- Divides fails comparability on the divisors of 12: it is not a total order there.
example : ¬ ∀ a ∈ Nat.divisors 12, ∀ b ∈ Nat.divisors 12, a ∣ b ∨ b ∣ a := by
  decide

-- Less than or equal passes comparability on the same six: a total order.
example : ∀ a ∈ Nat.divisors 12, ∀ b ∈ Nat.divisors 12, a ≤ b ∨ b ≤ a := by
  decide

-- The Hasse diagram of divides: exactly the 7 covers 1-2, 1-3, 2-4, 2-6, 3-6, 4-12, 6-12.
example : (Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 ∣ p.2 ∧ p.1 ≠ p.2 ∧
      ∀ m ∈ Nat.divisors 12, m ≠ p.1 → m ≠ p.2 → ¬ (p.1 ∣ m ∧ m ∣ p.2)) =
    {(1, 2), (1, 3), (2, 4), (2, 6), (3, 6), (4, 12), (6, 12)} := by
  decide

-- The chain under less than or equal takes 5 arrows, each number to the next.
example : (Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 < p.2 ∧ ∀ m ∈ Nat.divisors 12, ¬ (p.1 < m ∧ m < p.2)) =
    {(1, 2), (2, 3), (3, 4), (4, 6), (6, 12)} := by
  decide

-- Try changing: the divisors of 8 stack in one queue under divides.
example : ∀ a ∈ Nat.divisors 8, ∀ b ∈ Nat.divisors 8, a ∣ b ∨ b ∣ a := by
  decide

#print axioms dvd_is_partial_order_on_divisors
#print axioms finite_order_rebuilt_from_covers
#print axioms number_line_has_no_covers
