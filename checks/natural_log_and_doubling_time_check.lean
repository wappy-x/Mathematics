-- Natural log and doubling time: money growing at a steady yearly rate r, interest left in and paid once a year, doubles exactly at ln 2 / ln (1 + r) years, that time is always longer than ln 2 / r, and with continuous compounding it is exactly ln 2 / r.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Complex.ExponentialBounds

/-- Doubling time. Any amount `P > 0` grows at a steady yearly rate `r > 0`, with the interest
left in and paid once a year, so one year multiplies it by the growth factor `1 + r`. After `t`
years it is `P * (1 + r)^t`. It is exactly double, `2 * P`, at one time only:
`t = ln 2 / ln (1 + r)`. The answer does not depend on how much money `P` there is. -/
theorem doubling_time_eq_log_two_div_log_growth_factor (r P t : ℝ) (hr : 0 < r) (hP : 0 < P) :
    P * (1 + r) ^ t = 2 * P ↔ t = Real.log 2 / Real.log (1 + r) := by
  have h1 : (0:ℝ) < 1 + r := by linarith
  have hl : 0 < Real.log (1 + r) := Real.log_pos (by linarith)
  have hcancel : P * (1 + r) ^ t = 2 * P ↔ (1 + r) ^ t = 2 := by
    rw [mul_comm P]
    exact mul_left_inj' hP.ne'
  rw [hcancel]
  constructor
  · intro h
    have h2 := congrArg Real.log h
    rw [Real.log_rpow h1] at h2
    field_simp
    linarith
  · intro h
    rw [Real.rpow_def_of_pos h1, h]
    have : Real.log (1 + r) * (Real.log 2 / Real.log (1 + r)) = Real.log 2 := by
      field_simp
    rw [this, Real.exp_log (by norm_num)]

/-- Where 72 comes from. For a positive rate `r`, `ln (1 + r)` is a shade under `r`, so the true
doubling time `ln 2 / ln (1 + r)` sits above `ln 2 / r`, which is 69.3147 over the rate in percent.
Rounding that top number up to 72 is safe: `100 * ln 2 < 72`. -/
theorem doubling_time_above_log_two_div_rate (r : ℝ) (hr : 0 < r) :
    Real.log 2 / r < Real.log 2 / Real.log (1 + r) ∧ 100 * Real.log 2 < 72 := by
  have h1 : Real.log (1 + r) < r := by
    have := Real.log_lt_sub_one_of_pos (x := 1 + r) (by linarith) (by intro h; linarith)
    linarith
  have hl : 0 < Real.log (1 + r) := Real.log_pos (by linarith)
  have h2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  refine ⟨div_lt_div_of_pos_left h2 hl h1, ?_⟩
  have := Real.log_two_lt_d9
  norm_num at this
  linarith

/-- Continuous compounding makes the swap exact. Any amount `P > 0` at rate `r > 0`, paid
continuously, is `P * exp (r * t)` after `t` years, and it is exactly double at one time only:
`t = ln 2 / r`. -/
theorem continuous_doubling_time_eq_log_two_div_rate (r P t : ℝ) (hr : 0 < r) (hP : 0 < P) :
    P * Real.exp (r * t) = 2 * P ↔ t = Real.log 2 / r := by
  constructor
  · intro h
    have h' : Real.exp (r * t) = 2 := by
      have := h
      rw [mul_comm P] at this
      exact (mul_left_inj' hP.ne').mp this
    have h2 := congrArg Real.log h'
    rw [Real.log_exp] at h2
    field_simp
    linarith
  · intro h
    have : r * t = Real.log 2 := by
      rw [h]; field_simp
    rw [this, Real.exp_log (by norm_num), mul_comm]

-- Worked numbers, as exact fractions.
-- The rule of 72: 72 ÷ 8 = 9 years, and 72 ÷ 5 = 14.4 years.
example : (72 : ℚ) / 8 = 9 := by norm_num
example : (72 : ℚ) / 5 = 14 + 2 / 5 := by norm_num
-- The usual mistake: 100 ÷ 8 = 12.5 years, which is what interest taken out each year gives.
example : (100 : ℚ) / 8 = 25 / 2 := by norm_num
example : (1 : ℚ) + 25 / 2 * (8 / 100) = 2 := by norm_num
-- The check without logs: 1.08 nine times is just under 2, ten times is over 2.
example : (27 / 25 : ℚ) ^ 9 < 2 ∧ 2 < (27 / 25 : ℚ) ^ 10 := by norm_num
-- 1.08 nine times rounds to 1.999005, ten times to 2.158925.
example : (3998009 / 2000000 : ℚ) ≤ (27 / 25) ^ 9 ∧ (27 / 25 : ℚ) ^ 9 < 3998011 / 2000000 := by
  norm_num
example : (4317849 / 2000000 : ℚ) ≤ (27 / 25) ^ 10 ∧ (27 / 25 : ℚ) ^ 10 < 4317851 / 2000000 := by
  norm_num
-- $100 at 5%: under $200 after 14 years, over $200 after 15.
example : (100 : ℚ) * (21 / 20) ^ 14 < 200 ∧ 200 < (100 : ℚ) * (21 / 20) ^ 15 := by norm_num
-- To the cent: $197.99 after 14 years, $207.89 after 15.
example : (39597 / 200 : ℚ) ≤ 100 * (21 / 20) ^ 14 ∧ (100 : ℚ) * (21 / 20) ^ 14 < 39599 / 200 := by
  norm_num
example : (41577 / 200 : ℚ) ≤ 100 * (21 / 20) ^ 15 ∧ (100 : ℚ) * (21 / 20) ^ 15 < 41579 / 200 := by
  norm_num

#print axioms doubling_time_eq_log_two_div_log_growth_factor
#print axioms doubling_time_above_log_two_div_rate
#print axioms continuous_doubling_time_eq_log_two_div_rate
