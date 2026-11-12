-- The three rearranging laws: for every three whole numbers, adding and multiplying both swap and regroup freely and a multiplier spreads over a sum, subtraction and division neither swap nor regroup, and the card's apple-bill numbers come out as it says.
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum

/-- The three rearranging laws, for any three whole numbers `a`, `b`, `c`.
Swapping: `a + b = b + a` and `a × b = b × a`.
Regrouping: `(a + b) + c = a + (b + c)` and `(a × b) × c = a × (b × c)`.
Spreading: `a × (b + c) = a × b + a × c`, the multiplier outside the bracket hits every piece. -/
theorem swap_regroup_spread_whole_numbers (a b c : ℕ) :
    (a + b = b + a ∧ a * b = b * a) ∧
      ((a + b) + c = a + (b + c) ∧ (a * b) * c = a * (b * c)) ∧
      a * (b + c) = a * b + a * c := by
  exact ⟨⟨Nat.add_comm a b, Nat.mul_comm a b⟩, ⟨Nat.add_assoc a b c, Nat.mul_assoc a b c⟩,
    Nat.mul_add a b c⟩

/-- Where the laws stop: subtraction and division neither swap nor regroup. For each, some
numbers give a different answer once swapped, and some give a different answer once the
brackets move (the card's trap is `1000 − (900 − 100)`, which is not `(1000 − 900) − 100`).
Subtraction is stated on the integers and division on the rationals, so that neither failure
comes from whole-number subtraction stopping at zero or whole-number division dropping a
remainder. -/
theorem minus_and_divide_neither_swap_nor_regroup :
    (¬ ∀ a b : ℤ, a - b = b - a) ∧ (¬ ∀ a b c : ℤ, a - (b - c) = (a - b) - c) ∧
      (¬ ∀ a b : ℚ, a / b = b / a) ∧ (¬ ∀ a b c : ℚ, a / (b / c) = (a / b) / c) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro h
    have := h 0 1
    norm_num at this
  · intro h
    have := h 1 1 1
    norm_num at this
  · intro h
    have := h 1 2
    norm_num at this
  · intro h
    have := h 1 1 2
    norm_num at this

-- The apple bill in cents: twelve apples at 75 cents.
example : 12 * 75 = 900 := by decide
-- Swap, as a check.
example : 75 * 12 = 900 := by decide
-- Regroup: four friends with three apples each.
example : (4 * 3) * 75 = 900 := by decide
example : 4 * (3 * 75) = 900 := by decide
-- Spread: cut the price, 75 = 70 + 5.
example : 12 * (70 + 5) = 12 * 70 + 12 * 5 := by decide
example : 12 * 70 = 840 := by decide
example : 12 * 5 = 60 := by decide
example : 840 + 60 = 900 := by decide
-- Change from the bill, and each friend's share two ways.
example : 1000 - 900 = 100 := by decide
example : 900 / 4 = 225 ∧ 900 % 4 = 0 := by decide
example : 3 * 75 = 225 := by decide
-- The turned tray: four rows of three is three rows of four.
example : 4 * 3 = 3 * 4 := by decide
-- Half a spread: the 5 never got its twelve apples.
example : 12 * 70 + 5 = 845 := by decide
example : 12 * 70 + 5 ≠ 12 * (70 + 5) := by decide
-- Regrouping a subtraction: 200 cents you never had, against the true 0.
example : 1000 - (900 - 100) = 200 := by decide
example : (1000 - 900) - 100 = 0 := by decide

#print axioms swap_regroup_spread_whole_numbers
#print axioms minus_and_divide_neither_swap_nor_regroup
