-- Ratios and rates: multiplying both sides of a ratio by the same nonzero number leaves it unchanged, scaling one side alone changes it, and splitting a total by a ratio gives two shares that add back to the total and keep the ratio.
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp

/-- A ratio only cares about relative size. Do the same to both sides, multiplying the amount `a`
and the amount `b` by the same number `k` (not zero, or there is nothing left to compare), and the
ratio does not change: `k·a : k·b` is the same as `a : b`. 9 litres to 6 is 3 : 2 times 3. -/
theorem ratio_unchanged_when_both_sides_scaled (a b k : ℝ) (hk : k ≠ 0) :
    (k * a) / (k * b) = a / b := by
  exact mul_div_mul_left a b hk

/-- Splitting a total by a ratio: a total `T` split `p : q` has `p + q` equal parts, one part is
`T / (p + q)`, the first side gets `p` parts and the second gets `q`. The two shares add back to
the total, and they stand in the ratio `p : q`. Amounts and parts are positive. -/
theorem split_total_by_ratio (p q T : ℝ) (hp : 0 < p) (hq : 0 < q) (hT : 0 < T) :
    p * (T / (p + q)) + q * (T / (p + q)) = T ∧
    (p * (T / (p + q))) / (q * (T / (p + q))) = p / q := by
  have hpq : p + q ≠ 0 := by positivity
  have hx : T / (p + q) ≠ 0 := by positivity
  constructor
  · field_simp
  · exact mul_div_mul_right p q hx

/-- Scaling one side only changes the ratio: for nonzero amounts `a` and `b`, multiplying `a` alone
by any number `k` other than 1 gives a different ratio. Nine litres of blue with the original 2 of
white is not the same colour as 3 : 2. -/
theorem scaling_one_side_changes_ratio (a b k : ℝ) (ha : a ≠ 0) (hb : b ≠ 0) (hk : k ≠ 1) :
    (k * a) / b ≠ a / b := by
  intro h
  have h2 : k * a = a := by
    have := (div_left_inj' hb).mp h
    exact this
  have h3 : (k - 1) * a = 0 := by linarith
  rcases mul_eq_zero.mp h3 with h4 | h4
  · exact hk (by linarith)
  · exact ha h4

-- The tin: 3 : 2 is 3 + 2 = 5 parts, one part of 15 litres is 15 ÷ 5 = 3 litres.
example : 3 + 2 = 5 ∧ 15 / 5 = 3 := by decide
-- Blue 3 × 3 = 9 litres, white 2 × 3 = 6 litres, and 9 + 6 = 15 back to the tin.
example : 3 * 3 = 9 ∧ 2 * 3 = 6 ∧ 9 + 6 = 15 := by decide
-- 9 : 6 divided by 3 on both sides is 3 : 2 again.
example : (9 : ℚ) / 6 = 3 / 2 := by norm_num
example : 9 / 3 = 3 ∧ 6 / 3 = 2 := by decide
-- The car: 120 km in 1.5 hours (3/2 of an hour) is 80 km per hour, and 80 × 1.5 = 120 back.
example : (120 : ℚ) / (3 / 2) = 80 := by norm_num
example : (80 : ℚ) * (3 / 2) = 120 := by norm_num
-- At a steady 80 km per hour: 40 km by the half hour, 80 by the hour.
example : (80 : ℚ) * (1 / 2) = 40 ∧ (80 : ℚ) * 1 = 80 := by norm_num
-- Unit price: $2.25 (9/4 dollars) for 3 litres is $0.75 (3/4 of a dollar) a litre.
example : (9 / 4 : ℚ) / 3 = 3 / 4 := by norm_num
-- Twelve litres, two roads: 12 × $0.75 = $9.00, and 12 litres is 4 lots of 3, 4 × $2.25 = $9.00.
example : (12 : ℚ) * (3 / 4) = 9 := by norm_num
example : 12 / 3 = 4 := by decide
example : (4 : ℚ) * (9 / 4) = 9 := by norm_num
-- Mistake: dividing 15 by the 3 blue parts gives parts of 5 litres, and 5 parts of 5 is 25 litres.
example : 15 / 3 = 5 ∧ 5 * 5 = 25 ∧ 15 < 25 := by decide
-- Mistake: 1.5 ÷ 120 is 0.0125 (1/80), hours per kilometre.
example : (3 / 2 : ℚ) / 120 = 1 / 80 := by norm_num
-- Mistake: $2.25 × 12 = $27.00, which buys 27 ÷ 0.75 = 36 litres.
example : (9 / 4 : ℚ) * 12 = 27 := by norm_num
example : (27 : ℚ) / (3 / 4) = 36 := by norm_num
-- Scaling one side only: 9 litres of blue against 2 of white is not 3 : 2.
example : (9 : ℚ) / 2 ≠ 3 / 2 := by norm_num
-- Try changing: a 3 : 1 mix has 4 parts, whole-number 15 ÷ 4 floors to 3, and the tin check is 12.
example : 3 + 1 = 4 ∧ 15 / 4 = 3 ∧ 3 * 3 + 1 * 3 = 12 := by decide
-- Try changing: 120 km in 2 hours is 60 km per hour, and 60 × 2 = 120.
example : (120 : ℚ) / 2 = 60 ∧ (60 : ℚ) * 2 = 120 := by norm_num

#print axioms ratio_unchanged_when_both_sides_scaled
#print axioms split_total_by_ratio
#print axioms scaling_one_side_changes_ratio
