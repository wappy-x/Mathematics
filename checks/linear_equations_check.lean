-- Linear equations: for real numbers with a not zero, a x + b = c holds exactly when x = (c - b) / a, an unknown that cancels leaves no answer or every number, and solving a x + b < c flips the sign when a is negative.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith

/-- Undo the story backwards. When the unknown x is multiplied by a number a that is not zero and
then b is added, the equation a x + b = c is true for exactly one number: subtract b from both
sides, divide both sides by a, and x = (c - b) / a. -/
theorem linear_equation_solution (a b c x : ℝ) (ha : a ≠ 0) :
    a * x + b = c ↔ x = (c - b) / a := by
  rw [eq_div_iff ha]
  constructor <;> intro h <;> linarith

/-- When the unknown cancels (a is zero), a plain number faces a plain number. If b = c the
equation is true for every number; if b ≠ c it is true for none. -/
theorem linear_equation_unknown_cancels (b c : ℝ) :
    (b = c → ∀ x : ℝ, 0 * x + b = c) ∧ (b ≠ c → ∀ x : ℝ, 0 * x + b ≠ c) := by
  constructor
  · intro h x
    simpa using h
  · intro h x
    simpa using h

/-- A less-than is solved by the same two steps. Dividing by a positive a keeps the sign:
a x + b < c means x < (c - b) / a. Dividing by a negative a flips it: a x + b < c means
x > (c - b) / a. -/
theorem linear_inequality_flips_for_negative (a b c x : ℝ) :
    (0 < a → (a * x + b < c ↔ x < (c - b) / a)) ∧
    (a < 0 → (a * x + b < c ↔ (c - b) / a < x)) := by
  constructor
  · intro ha
    rw [lt_div_iff₀ ha]
    constructor <;> intro h <;> linarith
  · intro ha
    rw [div_lt_iff_of_neg ha]
    constructor <;> intro h <;> linarith

-- The 15-dollar meter: take the 3 off, then halve.
example : (15 : ℝ) - 3 = 12 ∧ (12 : ℝ) / 2 = 6 := by norm_num
-- Check by substituting: 3 + 2 × 6 = 15.
example : (3 : ℕ) + 2 * 6 = 15 := by decide
-- The 45-dollar fare: (45 − 3) ÷ 2 = 21, and 3 + 2 × 21 = 45.
example : ((45 : ℝ) - 3) / 2 = 21 := by norm_num
example : (3 : ℕ) + 2 * 21 = 45 := by decide
-- Staying under 15 dollars: at 5 miles the fare is 13, at 7 miles it is 17.
example : (3 : ℕ) + 2 * 5 = 13 ∧ (3 : ℕ) + 2 * 7 = 17 := by decide
-- The flip: -2m > -12 divides out to m < 6, with (-12 - 0) / (-2) = 6.
example : ((-12 : ℝ) - 0) / (-2) = 6 := by norm_num
-- The rival taxi: 3 + 2m = 5 + 2m comes down to 3 = 5, which is false.
example : (3 : ℕ) ≠ 5 := by decide
-- The same taxi in different clothes: 3 + m + m = 3 + 2m for every m.
example : ∀ m : ℝ, 3 + m + m = 3 + 2 * m := by intro m; ring

#print axioms linear_equation_solution
#print axioms linear_equation_unknown_cancels
#print axioms linear_inequality_flips_for_negative
