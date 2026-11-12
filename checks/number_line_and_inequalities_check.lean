-- The number line and inequalities: multiplying both sides by a negative number flips the less-than mark, adding the same number or multiplying by a positive one keeps it, and the midpoint of two different fractions is a fraction strictly between them.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-- Multiplying by a negative flips the mark, once: for any two numbers on the line and any
negative multiplier, the first is less than the second exactly when, after both are multiplied,
the first is greater than the second (17 < 19 becomes -17 > -19). -/
theorem mul_neg_flips_less_than (a b c : ℝ) (hc : c < 0) :
    a < b ↔ c * b < c * a := by
  constructor
  · intro h; nlinarith
  · intro h; nlinarith

/-- Sliding and stretching leave the order alone: adding the same number to both sides keeps the
mark, and so does multiplying both sides by the same positive number. -/
theorem slide_and_stretch_keep_less_than (a b : ℝ) :
    (∀ c : ℝ, a < b ↔ a + c < b + c) ∧ (∀ k : ℝ, 0 < k → (a < b ↔ k * a < k * b)) := by
  refine ⟨fun c => ?_, fun k hk => ?_⟩
  · constructor <;> intro h <;> linarith
  · constructor
    · intro h; nlinarith
    · intro h; by_contra hc; push_neg at hc; nlinarith

/-- Between any two fractions sits another fraction: add two different fractions and halve, and
the answer is a fraction strictly between them, so no two fractions are next door. -/
theorem midpoint_between_fractions (p q : ℚ) (h : p < q) :
    p < (p + q) / 2 ∧ (p + q) / 2 < q := by
  constructor <;> linarith

-- The night, laid on the line left to right: -2, 17, 18, 19, 20, 21, 22.
example : (-2 : ℤ) < 17 ∧ (17 : ℤ) < 18 ∧ (18 : ℤ) < 19 ∧ (19 : ℤ) < 20 ∧ (20 : ℤ) < 21 ∧
    (21 : ℤ) < 22 := by decide
-- At 3am the room was too cold: 17 < 18.
example : (17 : ℤ) < 18 := by decide
-- Five of the six readings hold the band 18 <= reading <= 22.
example : (([22, 20, 18, 17, 19, 21] : List ℤ).filter (fun t => 18 ≤ t ∧ t ≤ 22)).length = 5 := by
  decide
-- Using < at the ends instead of <= loses both ends: 3 inside, not 5.
example : (([22, 20, 18, 17, 19, 21] : List ℤ).filter (fun t => 18 < t ∧ t < 22)).length = 3 := by
  decide
-- Doubling both keeps the mark: 17 < 18 becomes 34 < 36.
example : (2 * 17 : ℤ) = 34 ∧ (2 * 18 : ℤ) = 36 ∧ (34 : ℤ) < 36 := by decide
-- Doubling only the left side: 34 > 18.
example : (2 * 17 : ℤ) > 18 := by decide
-- Times -1 flips the mark: 17 < 19 becomes -17 > -19.
example : (17 : ℤ) < 19 ∧ (-1 * 17 : ℤ) > -1 * 19 := by decide
-- Keeping the mark after the turn is wrong: -17 < -18 is false.
example : ¬ ((-17 : ℤ) < -18) := by decide
-- The readings 17 to 22 times -1 run downhill: -17, -18, -19, -20, -21, -22.
example : ([17, 18, 19, 20, 21, 22] : List ℤ).map (fun t => -t) = [-17, -18, -19, -20, -21, -22] ∧
    (-17 : ℤ) > -18 ∧ (-18 : ℤ) > -19 ∧ (-19 : ℤ) > -20 ∧ (-20 : ℤ) > -21 ∧ (-21 : ℤ) > -22 := by
  decide
-- The shortfalls from 20: 20 - 17 = 3 and 20 - 19 = 1, and the colder room's is bigger.
example : (20 - 17 : ℤ) = 3 ∧ (20 - 19 : ℤ) = 1 ∧ (3 : ℤ) > 1 := by decide
-- Halfway points: 20 between 18 and 22, 19 between 18 and 20.
example : ((18 + 22) / 2 : ℚ) = 20 ∧ ((18 + 20) / 2 : ℚ) = 19 := by norm_num
-- Halfway between 18 and 19 is 37/2, and it sits strictly between them.
example : ((18 + 19) / 2 : ℚ) = 37 / 2 ∧ (18 : ℚ) < 37 / 2 ∧ (37 / 2 : ℚ) < 19 := by norm_num
-- Halfway between 18 and 37/2 is 73/4.
example : ((18 + 37 / 2) / 2 : ℚ) = 73 / 4 := by norm_num
-- With whole numbers only, nothing sits between 18 and 19.
example : Finset.Ioo (18 : ℤ) 19 = ∅ := by decide

#print axioms mul_neg_flips_less_than
#print axioms slide_and_stretch_keep_less_than
#print axioms midpoint_between_fractions
