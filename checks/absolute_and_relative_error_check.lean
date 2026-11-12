-- Absolute and relative error: the relative error fixes the number of correct significant digits to within one.
import Mathlib.Data.Int.Log
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Tactic.NormNum

/-! The true value is `x`, the computed value is `x̂` (written `xhat`).
The absolute error is `|xhat - x|` and the relative error is `|xhat - x| / |x|`.
The power `k` in the scientific notation of `x` is Mathlib's `Int.log 10 |x|`,
the unique integer with `10 ^ k ≤ |x| < 10 ^ (k + 1)` when `x ≠ 0`.
`xhat` has `p` correct significant digits when `|xhat - x| ≤ 1/2 * 10 ^ (k - p + 1)`. -/

/-- The relative error pins the number of correct significant digits to within one:
for a nonzero true value `x` with `10 ^ k ≤ |x| < 10 ^ (k + 1)`,
a relative error of at most `5 * 10 ^ (-(p + 1))` guarantees `p` correct digits
(miss at most half a unit in digit `p`), and `p` correct digits force
a relative error of at most `5 * 10 ^ (-p)`. -/
theorem relative_error_pins_correct_digits (x xhat : ℝ) (hx : x ≠ 0) (p : ℕ) :
    (|xhat - x| / |x| ≤ 5 * (10 : ℝ) ^ (-((p : ℤ) + 1)) →
        |xhat - x| ≤ 1 / 2 * (10 : ℝ) ^ (Int.log 10 |x| - p + 1)) ∧
    (|xhat - x| ≤ 1 / 2 * (10 : ℝ) ^ (Int.log 10 |x| - p + 1) →
        |xhat - x| / |x| ≤ 5 * (10 : ℝ) ^ (-(p : ℤ))) := by
  have hax : 0 < |x| := abs_pos.mpr hx
  have hlo : (10 : ℝ) ^ Int.log 10 |x| ≤ |x| := by
    have := Int.zpow_log_le_self (b := 10) (r := |x|) (by norm_num) hax
    exact_mod_cast this
  have hhi : |x| < (10 : ℝ) ^ (Int.log 10 |x| + 1) := by
    have := Int.lt_zpow_succ_log_self (b := 10) (R := ℝ) (by norm_num) |x|
    exact_mod_cast this
  generalize Int.log 10 |x| = k at hlo hhi ⊢
  have h10 : (10 : ℝ) ≠ 0 := by norm_num
  have key1 : (1 : ℝ) / 2 * (10 : ℝ) ^ (k - p + 1) =
      5 * (10 : ℝ) ^ (-((p : ℤ) + 1)) * 10 ^ (k + 1) := by
    rw [mul_assoc, ← zpow_add₀ h10]
    have : k - p + 1 = (-((p : ℤ) + 1) + (k + 1)) + 1 := by ring
    rw [this, zpow_add_one₀ h10]; ring
  have key2 : (1 : ℝ) / 2 * (10 : ℝ) ^ (k - p + 1) = 5 * (10 : ℝ) ^ (-(p : ℤ)) * 10 ^ k := by
    rw [mul_assoc, ← zpow_add₀ h10]
    have : k - p + 1 = (-(p : ℤ) + k) + 1 := by ring
    rw [this, zpow_add_one₀ h10]; ring
  constructor
  · intro h
    rw [div_le_iff₀ hax] at h
    rw [key1]
    calc |xhat - x| ≤ 5 * (10 : ℝ) ^ (-((p : ℤ) + 1)) * |x| := h
      _ ≤ 5 * (10 : ℝ) ^ (-((p : ℤ) + 1)) * 10 ^ (k + 1) :=
        mul_le_mul_of_nonneg_left hhi.le (mul_pos (by norm_num) (zpow_pos (by norm_num) _)).le
  · intro h
    rw [div_le_iff₀ hax]
    rw [key2] at h
    calc |xhat - x| ≤ 5 * (10 : ℝ) ^ (-(p : ℤ)) * 10 ^ k := h
      _ ≤ 5 * (10 : ℝ) ^ (-(p : ℤ)) * |x| :=
        mul_le_mul_of_nonneg_left hlo (mul_pos (by norm_num) (zpow_pos (by norm_num) _)).le

/-- The relative error has no units: changing units multiplies the true and computed
values by the same nonzero factor `c`, and the relative error does not change. -/
theorem relative_error_unchanged_by_units (x xhat c : ℝ) (hc : c ≠ 0) :
    |c * xhat - c * x| / |c * x| = |xhat - x| / |x| := by
  rw [← mul_sub, abs_mul, abs_mul]
  exact mul_div_mul_left _ _ (abs_ne_zero.mpr hc)

/-- Dividing by the result instead of the truth: for a short result `0 < xhat ≤ x`,
the miss divided by `xhat` equals `E_rel / (1 - E_rel)`, where `E_rel` is the true
relative error. -/
theorem divide_by_result_gives_rel_over_one_minus_rel (x xhat : ℝ) (hxhat : 0 < xhat)
    (hshort : xhat ≤ x) :
    |xhat - x| / |xhat| = (|xhat - x| / |x|) / (1 - |xhat - x| / |x|) := by
  have hx : 0 < x := lt_of_lt_of_le hxhat hshort
  rw [abs_of_nonpos (by linarith), abs_of_pos hx, abs_of_pos hxhat]
  have : 1 - -(xhat - x) / x = xhat / x := by field_simp; ring
  rw [this, div_div_div_cancel_right₀ hx.ne']

/-! The card's whole-number worked examples, in millimetres. -/

-- Beam: x = 3000, xhat = 2998. Absolute error 2, relative error 2/3000.
example : |(2998 : ℝ) - 3000| = 2 := by norm_num
example : |(2998 : ℝ) - 3000| / |(3000 : ℝ)| = 2 / 3000 := by norm_num
-- Beam in scientific notation: k = 3.
example : (10 : ℝ) ^ (3 : ℤ) ≤ 3000 ∧ (3000 : ℝ) < 10 ^ ((3 : ℤ) + 1) := by norm_num
-- Beam: passes the half-unit test at digit 3 (5 mm), fails it at digit 4 (1/2 mm): 3 digits.
example : |(2998 : ℝ) - 3000| ≤ 1 / 2 * (10 : ℝ) ^ ((3 : ℤ) - 3 + 1) := by norm_num
example : ¬ (|(2998 : ℝ) - 3000| ≤ 1 / 2 * (10 : ℝ) ^ ((3 : ℤ) - 4 + 1)) := by norm_num
-- Bolt: x = 20, xhat = 18. Relative error 1/10, k = 1, one correct digit.
example : |(18 : ℝ) - 20| / |(20 : ℝ)| = 1 / 10 := by norm_num
example : (10 : ℝ) ^ (1 : ℤ) ≤ 20 ∧ (20 : ℝ) < 10 ^ ((1 : ℤ) + 1) := by norm_num
example : |(18 : ℝ) - 20| ≤ 1 / 2 * (10 : ℝ) ^ ((1 : ℤ) - 1 + 1) ∧
    ¬ (|(18 : ℝ) - 20| ≤ 1 / 2 * (10 : ℝ) ^ ((1 : ℤ) - 2 + 1)) := by norm_num
-- The bolt is 150 times worse than the beam.
example : (2 / 20 : ℝ) / (2 / 3000) = 150 := by norm_num
-- A tape rated at 1/1000: 3 mm on the beam, 1/50 mm on the bolt.
example : (1 / 1000 : ℝ) * 3000 = 3 ∧ (1 / 1000 : ℝ) * 20 = 1 / 50 := by norm_num
-- Dividing by the cut length for the bolt: 2/18 = (1/10) / (1 - 1/10).
example : (2 / 18 : ℝ) = (1 / 10) / (1 - 1 / 10) := by norm_num
-- Two rails with the same relative error 4/10000, one digit apart.
example : (4 : ℝ) / 10000 = 39 / 97500 := by norm_num
-- 10 m rail: k = 4, passes digit 4 (5 mm), fails digit 5: 4 digits.
example : (4 : ℝ) ≤ 1 / 2 * (10 : ℝ) ^ ((4 : ℤ) - 4 + 1) ∧
    ¬ ((4 : ℝ) ≤ 1 / 2 * (10 : ℝ) ^ ((4 : ℤ) - 5 + 1)) := by norm_num
-- 97.5 m rail: k = 4, passes digit 3 (50 mm), fails digit 4 (5 mm): 3 digits.
example : (10 : ℝ) ^ (4 : ℤ) ≤ 97500 ∧ (97500 : ℝ) < 10 ^ ((4 : ℤ) + 1) := by norm_num
example : (39 : ℝ) ≤ 1 / 2 * (10 : ℝ) ^ ((4 : ℤ) - 3 + 1) ∧
    ¬ ((39 : ℝ) ≤ 1 / 2 * (10 : ℝ) ^ ((4 : ℤ) - 4 + 1)) := by norm_num
-- Clearance: true 1 mm, got 3 mm, relative error 2 (200 percent).
example : |(3 : ℝ) - 1| / |(1 : ℝ)| = 2 := by norm_num

#print axioms relative_error_pins_correct_digits
#print axioms relative_error_unchanged_by_units
#print axioms divide_by_result_gives_rel_over_one_minus_rel
