-- Negative numbers: wherever every number has an opposite and the spreading law holds, subtracting is adding the opposite, same signs multiply to a plus and different signs to a minus, and in the integers dividing by a number other than 0 undoes multiplying by it.
import Mathlib.Algebra.Ring.Defs
import Mathlib.Algebra.Group.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.DivMod

/-- The sign rules for multiplying, as the card proves them from the spreading law: in any number
system where every number has an opposite and multiplying spreads over adding (a ring), a plus
times a minus is a minus, a minus times a plus is a minus, and a minus times a minus is a plus. -/
theorem sign_rules_for_multiplying {R : Type*} [Ring R] (a b : R) :
    a * -b = -(a * b) ∧ -a * b = -(a * b) ∧ -a * -b = a * b := by
  refine ⟨mul_neg a b, neg_mul a b, ?_⟩
  rw [neg_mul, mul_neg, neg_neg]

/-- Subtracting is adding the opposite: once every number has an opposite, taking `b` away from
`a` gives the same answer as adding the opposite of `b` (40 − 65 is 40 + (−65)). -/
theorem subtracting_is_adding_the_opposite {R : Type*} [Ring R] (a b : R) :
    a - b = a + -b := by
  exact sub_eq_add_neg a b

/-- Dividing undoes multiplying, for whole numbers of either sign: when you divide by a number
other than 0, multiplying by it and then dividing by it gets you back where you started
(3 × (−25) = −75, and −75 ÷ 3 = −25). -/
theorem dividing_undoes_multiplying (a b : ℤ) (hb : b ≠ 0) :
    a * b / b = a := by
  exact Int.mul_ediv_cancel a hb

-- The opposite of 65 cancels it.
example : (65 : ℤ) + -65 = 0 := by norm_num
-- Paid in 40, then a bill of 65: −25, the same both ways.
example : (40 : ℤ) - 65 = -25 := by norm_num
example : (40 : ℤ) + -65 = -25 := by norm_num
-- Three below zero, five degrees colder: −8.
example : (-3 : ℤ) - 5 = -8 := by norm_num
example : (-3 : ℤ) + -5 = -8 := by norm_num
-- Step 2: three lots of a bracket worth zero, spread out, forces 3 × (−25) = −75.
example : (3 : ℤ) * 25 + 3 * -25 = 0 := by norm_num
example : (3 : ℤ) * -25 = -75 := by norm_num
-- Step 3: the same move, minus three lots, forces (−3) × (−25) = 75.
example : (-3 : ℤ) * 25 + -3 * -25 = 0 := by norm_num
example : (-3 : ℤ) * -25 = 75 := by norm_num
-- Dividing undoes it: −75 ÷ 3 = −25 and −75 ÷ (−25) = 3.
example : (-75 : ℤ) / 3 = -25 := by norm_num
example : (-75 : ℤ) / -25 = 3 := by norm_num
-- The running balance: 0, 40, −25, −100, −25.
example : (0 : ℤ) + 40 = 40 ∧ (40 : ℤ) - 65 = -25 ∧ (-25 : ℤ) + 3 * -25 = -100 ∧
    (-100 : ℤ) + -3 * -25 = -25 := by norm_num
-- Taking the fees back off: −100 − (−75) = −100 + 75 = −25.
example : (-100 : ℤ) - -75 = -25 ∧ (-100 : ℤ) + 75 = -25 := by norm_num
-- The three mistakes: −175, 25 and 2.
example : (-25 : ℤ) + 3 * -25 + -3 * 25 = -175 := by norm_num
example : (-100 : ℤ) - 75 = -175 := by norm_num
example : (65 : ℤ) - 40 = 25 := by norm_num
example : (-3 : ℤ) + 5 = 2 := by norm_num
-- A bigger debt is a smaller number: −100 sits left of −25.
example : (-100 : ℤ) < -25 := by norm_num
-- Lifts: two floors up from −1 is 1.
example : (-1 : ℤ) + 2 = 1 := by norm_num

#print axioms sign_rules_for_multiplying
#print axioms subtracting_is_adding_the_opposite
#print axioms dividing_undoes_multiplying
