-- First-order recurrences: a rule that multiplies by a factor other than 1 and adds a constant has exactly one fixed point, its value after n steps is the factor to the n times the starting gap to that fixed point plus the fixed point, a loan's balance lands on zero at month n exactly when the payment is the level-payment formula, and the card's car loan comes out at the cents it says.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Logic.Function.Iterate
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

/-- The closed form of a first-order recurrence, `a(n) = r^n (a(0) − a*) + a*` with
`a* = c / (1 − r)`: if every step multiplies the value before it by a fixed factor `r`
and then adds a fixed amount `c`, and the factor is not 1, then after `n` steps the value
is the fixed point `c / (1 − r)` plus the starting gap to it, multiplied by `r` once per
step. -/
theorem first_order_recurrence_closed_form (r c : ℝ) (hr : r ≠ 1) (a : ℕ → ℝ)
    (hstep : ∀ k, a (k + 1) = r * a k + c) (n : ℕ) :
    a n = r ^ n * (a 0 - c / (1 - r)) + c / (1 - r) := by
  have hs : (1 - r) ≠ 0 := sub_ne_zero.mpr (Ne.symm hr)
  induction n with
  | zero => simp
  | succ k ih =>
    rw [hstep k, ih]
    field_simp
    ring

/-- The fixed point is the one value a step leaves alone: when the factor `r` is not 1,
a value `x` comes back unchanged from "multiply by `r`, add `c`" exactly when
`x = c / (1 − r)`. -/
theorem fixed_point_iff (r c x : ℝ) (hr : r ≠ 1) :
    r * x + c = x ↔ x = c / (1 - r) := by
  have hs : (1 - r) ≠ 0 := sub_ne_zero.mpr (Ne.symm hr)
  rw [eq_div_iff hs]
  constructor <;> intro h <;> linarith

/-- The level payment of a loan, `P = B₀ (r − 1) rⁿ / (rⁿ − 1)`: borrow `B₀`, and each
month multiply the balance by the growth factor `r` (positive interest, so `r > 1`) and
take off the payment `P`. Then the balance is exactly zero after `n ≥ 1` months if and
only if the payment is `B₀ (r − 1) rⁿ / (rⁿ − 1)`, so exactly one payment clears the
debt on time. -/
theorem loan_clears_iff_level_payment (r B₀ P : ℝ) (hr : 1 < r) (B : ℕ → ℝ)
    (h0 : B 0 = B₀) (hstep : ∀ k, B (k + 1) = r * B k - P) (n : ℕ) (hn : 0 < n) :
    B n = 0 ↔ P = B₀ * ((r - 1) * r ^ n) / (r ^ n - 1) := by
  have hr1 : r - 1 ≠ 0 := sub_ne_zero.mpr (ne_of_gt hr)
  have hpow : 1 < r ^ n := one_lt_pow₀ hr hn.ne'
  have hpn : r ^ n - 1 ≠ 0 := sub_ne_zero.mpr (ne_of_gt hpow)
  have key : ∀ m, B m * (r - 1) = r ^ m * (B₀ * (r - 1) - P) + P := by
    intro m
    induction m with
    | zero => simp [h0]
    | succ k ih =>
      rw [hstep k, pow_succ]
      linear_combination r * ih
  rw [eq_div_iff hpn]
  constructor
  · intro h
    have := key n
    rw [h] at this
    linear_combination this
  · intro h
    have h2 : B n * (r - 1) = 0 := by
      rw [key n]
      linear_combination -h
    rcases mul_eq_zero.mp h2 with h3 | h3
    · exact h3
    · exact absurd h3 hr1

-- The card's loan: $20,000 at half a percent a month (factor 201/200) over 48 months,
-- in exact fractions of a dollar.
-- Month 1 with the billed payment $469.70: interest $100.00, balance $19,630.30.
example : (20000 : ℚ) * (1 / 200) = 100 := by norm_num
example : (20000 : ℚ) * (201 / 200) - 46970 / 100 = 1963030 / 100 := by norm_num
-- Month 2: interest $98.15 (to the cent), balance $19,258.75 (to the cent).
example : (19629 / 200 : ℚ) ≤ 1963030 / 100 * (1 / 200) ∧
    (1963030 / 100 : ℚ) * (1 / 200) < 19631 / 200 := by norm_num
example : (3851749 / 200 : ℚ) ≤ 1963030 / 100 * (201 / 200) - 46970 / 100 ∧
    (1963030 / 100 : ℚ) * (201 / 200) - 46970 / 100 < 3851751 / 200 := by norm_num
-- The level payment rounds to $469.70: within half a cent of 46970 cents.
example : (93939 / 200 : ℚ) ≤ 20000 * ((201 / 200 - 1) * (201 / 200) ^ 48) /
      ((201 / 200) ^ 48 - 1) ∧
    20000 * ((201 / 200 - 1) * (201 / 200) ^ 48) / ((201 / 200 : ℚ) ^ 48 - 1) <
      93941 / 200 := by norm_num
-- The fixed point, payment / rate, rounds to $93,940.12.
example : (18788023 / 200 : ℚ) ≤ 200 * (20000 * ((201 / 200 - 1) * (201 / 200) ^ 48) /
      ((201 / 200) ^ 48 - 1)) ∧
    200 * (20000 * ((201 / 200 - 1) * (201 / 200) ^ 48) / ((201 / 200 : ℚ) ^ 48 - 1)) <
      18788025 / 200 := by norm_num
-- Paying only the interest, $100.00, leaves the balance on its own fixed point.
example : (20000 : ℚ) * (201 / 200) - 100 = 20000 := by norm_num
-- Left unpaid, the debt grows to $25,409.78 (to the cent).
example : (5081955 / 200 : ℚ) ≤ 20000 * (201 / 200) ^ 48 ∧
    (20000 : ℚ) * (201 / 200) ^ 48 < 5081957 / 200 := by norm_num
-- Interest paid in all, 48 payments less the $20,000 borrowed: $2,545.63 (to the cent).
example : (509125 / 200 : ℚ) ≤ 48 * (20000 * ((201 / 200 - 1) * (201 / 200) ^ 48) /
      ((201 / 200) ^ 48 - 1)) - 20000 ∧
    48 * (20000 * ((201 / 200 - 1) * (201 / 200) ^ 48) / ((201 / 200 : ℚ) ^ 48 - 1)) - 20000 <
      509127 / 200 := by norm_num
-- Mistake 1: $20,000 / 48 a month, stepped 48 times, leaves $2,869.02 owing.
example : (573803 / 200 : ℚ) ≤ (fun b : ℚ => b * (201 / 200) - 20000 / 48)^[48] 20000 ∧
    (fun b : ℚ => b * (201 / 200) - 20000 / 48)^[48] 20000 < 573805 / 200 := by
  norm_num [Function.iterate_succ_apply']
-- Mistake 2: 6% a month (factor 106/100) gives a payment of $1,277.95.
example : (255589 / 200 : ℚ) ≤ 20000 * ((106 / 100 - 1) * (106 / 100) ^ 48) /
      ((106 / 100) ^ 48 - 1) ∧
    20000 * ((106 / 100 - 1) * (106 / 100) ^ 48) / ((106 / 100 : ℚ) ^ 48 - 1) <
      255591 / 200 := by norm_num
-- Mistake 3: billing $469.00, stepped 48 times, leaves $37.90 owing.
example : (7579 / 200 : ℚ) ≤ (fun b : ℚ => b * (201 / 200) - 469)^[48] 20000 ∧
    (fun b : ℚ => b * (201 / 200) - 469)^[48] 20000 < 7581 / 200 := by
  norm_num [Function.iterate_succ_apply']

#print axioms first_order_recurrence_closed_form
#print axioms fixed_point_iff
#print axioms loan_clears_iff_level_payment
