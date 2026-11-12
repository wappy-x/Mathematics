-- Log laws and log scales: for positive numbers the base-10 log of a product is the sum of the logs, the log of a quotient is the difference, and a count in steps of 100 is the count in tens divided by the log of 100.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Tactic.NormNum.NatLog

open Real

/-- The count of a product is the sum of the counts: for any two positive numbers `x` and `y`,
the base-10 log of `x * y` equals the base-10 log of `x` plus the base-10 log of `y`. On a log
scale, multiplying two numbers adds their distances from the 1 mark. -/
theorem log10_of_product_is_sum_of_logs (x y : ℝ) (hx : 0 < x) (hy : 0 < y) :
    logb 10 (x * y) = logb 10 x + logb 10 y := by
  rw [logb, logb, logb, Real.log_mul hx.ne' hy.ne', add_div]

/-- Dividing subtracts: for any two positive numbers `x` and `y`, the base-10 log of `x / y`
equals the base-10 log of `x` minus the base-10 log of `y`. -/
theorem log10_of_quotient_is_difference_of_logs (x y : ℝ) (hx : 0 < x) (hy : 0 < y) :
    logb 10 (x / y) = logb 10 x - logb 10 y := by
  rw [logb, logb, logb, Real.log_div hx.ne' hy.ne', sub_div]

/-- Change of base: counting a positive number `x` in steps of 100 gives its count in tens
divided by how many tens one step of 100 is worth, `log10 (100)`. -/
theorem log100_is_log10_divided_by_log10_of_100 (x : ℝ) (hx : 0 < x) :
    logb 100 x = logb 10 x / logb 10 100 := by
  rw [logb, logb, logb]
  rw [div_div_div_cancel_right₀]
  exact (Real.log_pos (by norm_num : (1:ℝ) < 10)).ne'

-- The counts of the village, the town and the city: 2, 4 and 7 tens.
example : Nat.log 10 100 = 2 ∧ Nat.log 10 10000 = 4 ∧ Nat.log 10 10000000 = 7 := by norm_num
-- Village times town: 100 x 10,000 = 1,000,000, count 6 = 2 + 4.
example : 100 * 10000 = 1000000 ∧ Nat.log 10 1000000 = 6 ∧ 10 ^ 2 * 10 ^ 4 = 10 ^ (2 + 4) := by
  norm_num
-- City over village: 10,000,000 / 100 = 100,000, count 5 = 7 - 2.
example : 10000000 / 100 = 100000 ∧ Nat.log 10 100000 = 5 ∧ 10 ^ 7 / 10 ^ 2 = 10 ^ (7 - 2) := by
  norm_num
-- The town squared: 10,000 x 10,000 = 100,000,000, count 8 = 4 + 4.
example : 10000 * 10000 = 100000000 ∧ Nat.log 10 100000000 = 8 := by norm_num
-- In villages: 1,000,000 is three steps of 100, and 6 / 2 = 3.
example : 100 * 100 * 100 = 1000000 ∧ Nat.log 100 1000000 = 3 ∧ 6 / 2 = 3 := by norm_num
-- Halfway from the 100 mark to the 10,000 mark is count (2 + 4) / 2 = 3, the 1,000 mark.
example : (2 + 4) / 2 = 3 ∧ 10 ^ ((2 + 4) / 2) = 1000 := by norm_num
-- The three mistakes: 100 + 10,000 = 10,100, its half 5,050, and 2 x 4 = 8.
example : 100 + 10000 = 10100 ∧ (100 + 10000) / 2 = 5050 ∧ 2 * 4 = 8 := by norm_num

#print axioms log10_of_product_is_sum_of_logs
#print axioms log10_of_quotient_is_difference_of_logs
#print axioms log100_is_log10_divided_by_log10_of_100
