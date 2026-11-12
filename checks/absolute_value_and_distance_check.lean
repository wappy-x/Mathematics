-- Absolute value: for all real numbers, |a + b| is at most |a| + |b| (equal exactly when a and b point the same way), and the distance |x - y| is the same whichever number you subtract first.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Ring.Abs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.Order.Group.Abs

/-- The triangle rule. Start at zero, walk a, then walk b: where you end up, |a + b|, is never
further from zero than the ground you walked, |a| + |b|. -/
theorem triangle_rule (a b : ℝ) : |a + b| ≤ |a| + |b| := by
  rcases le_total 0 a with ha | ha <;> rcases le_total 0 b with hb | hb <;>
    rcases le_total 0 (a + b) with hab | hab <;>
    simp [abs_of_nonneg, abs_of_nonpos, *] <;> linarith

/-- "At most", not "equals": the triangle rule is an equality exactly when both walks go the same
way (their product is 0 or more, so neither points against the other). -/
theorem triangle_rule_equal_iff_same_direction (a b : ℝ) :
    |a + b| = |a| + |b| ↔ 0 ≤ a * b := by
  rcases le_total 0 a with ha | ha <;> rcases le_total 0 b with hb | hb
  · have : 0 ≤ a * b := mul_nonneg ha hb
    simp [abs_of_nonneg, ha, hb, add_nonneg ha hb, this]
  · constructor
    · intro h
      rcases le_total 0 (a + b) with hab | hab
      · rw [abs_of_nonneg hab, abs_of_nonneg ha, abs_of_nonpos hb] at h
        have : b = 0 := by linarith
        simp [this]
      · rw [abs_of_nonpos hab, abs_of_nonneg ha, abs_of_nonpos hb] at h
        have : a = 0 := by linarith
        simp [this]
    · intro h
      have : a = 0 ∨ b = 0 := by
        by_contra hc
        rw [not_or] at hc
        have h1 : 0 < a := lt_of_le_of_ne ha (Ne.symm hc.1)
        have h2 : b < 0 := lt_of_le_of_ne hb hc.2
        nlinarith
      rcases this with h0 | h0 <;> subst h0 <;> simp
  · constructor
    · intro h
      rcases le_total 0 (a + b) with hab | hab
      · rw [abs_of_nonneg hab, abs_of_nonpos ha, abs_of_nonneg hb] at h
        have : a = 0 := by linarith
        simp [this]
      · rw [abs_of_nonpos hab, abs_of_nonpos ha, abs_of_nonneg hb] at h
        have : b = 0 := by linarith
        simp [this]
    · intro h
      have : a = 0 ∨ b = 0 := by
        by_contra hc
        rw [not_or] at hc
        have h1 : a < 0 := lt_of_le_of_ne ha hc.1
        have h2 : 0 < b := lt_of_le_of_ne hb (Ne.symm hc.2)
        nlinarith
      rcases this with h0 | h0 <;> subst h0 <;> simp
  · have : 0 ≤ a * b := mul_nonneg_of_nonpos_of_nonpos ha hb
    have hab : a + b ≤ 0 := add_nonpos ha hb
    simp [abs_of_nonpos, ha, hb, hab, this, add_comm]

/-- Absolute value is how far a number sits from zero: a number 0 or more is its own size, a
number below 0 has its minus flipped, and the bars never give a negative. The distance between
two numbers, |x - y|, is the same whichever one you subtract first. -/
theorem abs_is_size_and_distance_is_symmetric (x y : ℝ) :
    |x| = (if 0 ≤ x then x else -x) ∧ 0 ≤ |x| ∧ |x - y| = |y - x| := by
  refine ⟨?_, abs_nonneg x, abs_sub_comm x y⟩
  split_ifs with h
  · exact abs_of_nonneg h
  · exact abs_of_neg (not_le.mp h)

-- The card's street: bus stop 0, bakery 40, chemist 65, laundrette -30.
example : |(40 : ℤ)| = 40 ∧ |(65 : ℤ)| = 65 ∧ |(-30 : ℤ)| = 30 ∧ |(0 : ℤ)| = 0 := by decide
example : |(-30 : ℤ)| = -(-30) := by decide
example : |(40 : ℤ) - 65| = 25 ∧ |(65 : ℤ) - 40| = 25 := by decide
example : |(40 : ℤ) - (-30)| = 70 := by decide
-- One trip out: end and ground walked agree.
example : |(40 : ℤ) + 25| = 65 ∧ |(40 : ℤ)| + |(25 : ℤ)| = 65 := by decide
-- Doubling back: ends 30 out, walks 110.
example : |(40 : ℤ) + (-70)| = 30 ∧ |(40 : ℤ)| + |(-70 : ℤ)| = 110 := by decide
-- The three mistakes: stopping after the subtraction, dropping the laundrette's minus, reading "at most" as "equals".
example : (40 : ℤ) - 65 = -25 ∧ |(40 : ℤ) - 30| = 10 ∧ |(40 : ℤ)| + |(-70 : ℤ)| = 110 := by decide
-- Turning the minus in the middle into a plus gives 105, not 25.
example : (40 : ℤ) + 65 = 105 := by decide

#print axioms triangle_rule
#print axioms triangle_rule_equal_iff_same_direction
#print axioms abs_is_size_and_distance_is_symmetric
