-- Even and odd: every whole number is even or odd and never both, whether a sum or product is even follows from the parities going in, and a switch pressed n times is back where it started exactly when n is even.
import Mathlib.Algebra.Ring.Int.Parity
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Logic.Function.Iterate

/-- The parity table. For any two whole numbers a and b (negatives included), you can tell
whether a + b and a × b are even from whether a and b are even, without doing the sum:
a + b is even exactly when a and b have the same parity (even + even, odd + odd), and
a × b is even exactly when at least one of them is even, so only odd × odd stays odd. -/
theorem parity_of_sum_and_product_follows_from_parities (a b : ℤ) :
    (Even (a + b) ↔ (Even a ↔ Even b)) ∧ (Even (a * b) ↔ (Even a ∨ Even b)) := by
  exact ⟨Int.even_add, Int.even_mul⟩

/-- The two-way split. Every whole number either pairs off with nothing left over (even) or
pairs off with exactly one left over (odd), and no number is both. -/
theorem every_integer_is_even_or_odd_and_not_both (n : ℤ) :
    (Even n ∨ Odd n) ∧ ¬(Even n ∧ Odd n) := by
  refine ⟨Int.even_or_odd n, ?_⟩
  rintro ⟨h1, h2⟩
  exact (Int.not_even_iff_odd.mpr h2) h1

/-- The light switch. Whatever state the switch starts in, pressing it n times (each press
flips it) leaves it as it started exactly when n is even; parity gives the change, not the
state. -/
theorem switch_back_to_start_iff_presses_even (n : ℕ) (start : Bool) :
    (fun s : Bool => !s)^[n] start = start ↔ Even n := by
  have key : ∀ (n : ℕ) (b : Bool), (fun s : Bool => !s)^[n] b = (if Even n then b else !b) := by
    intro n
    induction n with
    | zero => intro b; simp
    | succ k ih =>
      intro b
      rw [Function.iterate_succ, Function.comp_apply, ih]
      by_cases h : Even k <;> cases b <;> simp [h, Nat.even_add_one]
  rw [key]
  by_cases h : Even n <;> cases start <;> simp [h]

-- The card's worked numbers.
example : (11 : ℤ) * 3 = 33 ∧ Odd (11 : ℤ) ∧ Odd (3 : ℤ) ∧ Odd (33 : ℤ) := by decide
example : (33 : ℤ) + 4 = 37 ∧ Even (4 : ℤ) ∧ Odd (37 : ℤ) := by decide
example : (37 : ℤ) = 18 * 2 + 1 ∧ (38 : ℤ) = 19 * 2 := by decide
example : (33 : ℤ) + 5 = 38 ∧ Odd (5 : ℤ) ∧ Even (38 : ℤ) := by decide
example : (10 : ℤ) * 3 = 30 ∧ Even (30 : ℤ) := by decide
example : Even (0 : ℤ) ∧ Even (-4 : ℤ) ∧ Odd (-3 : ℤ) := by decide
-- Starting off (false), 37 presses leave the light on, 38 leave it off.
example : (fun s : Bool => !s)^[37] false = true := by decide
example : (fun s : Bool => !s)^[38] false = false := by decide
-- No row for dividing: two evens can divide to an odd.
example : Even (6 : ℤ) ∧ Even (2 : ℤ) ∧ (6 : ℤ) / 2 = 3 ∧ Odd (3 : ℤ) := by decide

#print axioms parity_of_sum_and_product_follows_from_parities
#print axioms every_integer_is_even_or_odd_and_not_both
#print axioms switch_back_to_start_iff_presses_even
