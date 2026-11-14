-- The check script: the half-unit rule never rejects a correctly rounded number, and a changed number with the same digit count passes it only on an exact rounding tie one unit away.
import Mathlib.Algebra.Order.Round
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Tactic.NormNum

/-! A number printed with `d` digits after the decimal point is `m / 10 ^ d` for a whole
number `m` (707.1 is `7071 / 10 ^ 1`). The half-unit allowance is `1 / (2 * 10 ^ d)`.
A claim `c` passes against the true value `x` when `|x - c| ≤ 1 / (2 * 10 ^ d)`.
"The printed digits are honest" means the card's `c` is within half a unit of `x`. -/

/-- Helper: two different whole-number prints with `d` digits differ by `|m' - m|` units. -/
lemma typo_gap_aux (x : ℝ) (d : ℕ) (m m' : ℤ) :
    |((m' : ℝ) - m)| / 10 ^ d ≤ |x - (m : ℝ) / 10 ^ d| + |x - (m' : ℝ) / 10 ^ d| := by
  have hu : (0 : ℝ) < 10 ^ d := by positivity
  have h1 : |((m' : ℝ) - m)| / 10 ^ d = |(m' : ℝ) / 10 ^ d - (m : ℝ) / 10 ^ d| := by
    rw [← sub_div, abs_div, abs_of_pos hu]
  rw [h1]
  calc |(m' : ℝ) / 10 ^ d - (m : ℝ) / 10 ^ d|
      = |(x - (m : ℝ) / 10 ^ d) - (x - (m' : ℝ) / 10 ^ d)| := by ring_nf
    _ ≤ |x - (m : ℝ) / 10 ^ d| + |x - (m' : ℝ) / 10 ^ d| := abs_sub _ _

/-- Helper: different integers are at least one apart, as reals. -/
lemma one_le_abs_int_sub_aux (m m' : ℤ) (typo : m' ≠ m) : (1 : ℝ) ≤ |((m' : ℝ) - m)| := by
  have h : (1 : ℤ) ≤ |m' - m| := Int.one_le_abs (sub_ne_zero.mpr typo)
  have h2 : ((|m' - m| : ℤ) : ℝ) = |((m' : ℝ) - m)| := by push_cast; rfl
  rw [← h2]; exact_mod_cast h

#print axioms typo_gap_aux
#print axioms one_le_abs_int_sub_aux

/-- The half-unit rule. Let the true value `x` be honestly printed as `m / 10 ^ d`
(within half a unit of it). If a typo changes the printed digits to a different
`m' / 10 ^ d` with the same digit count, and the typo still passes the half-unit test,
then the typo moved exactly one unit and the true value sat exactly on a rounding tie.
In every other case the typo fails. -/
theorem half_unit_rule_rejects_typo_except_on_tie (x : ℝ) (d : ℕ) (m m' : ℤ)
    (honest : |x - (m : ℝ) / 10 ^ d| ≤ 1 / (2 * (10 : ℝ) ^ d))
    (typo : m' ≠ m)
    (passes : |x - (m' : ℝ) / 10 ^ d| ≤ 1 / (2 * (10 : ℝ) ^ d)) :
    |x - (m : ℝ) / 10 ^ d| = 1 / (2 * (10 : ℝ) ^ d) ∧ |m' - m| = 1 := by
  have hu : (0 : ℝ) < 10 ^ d := by positivity
  have hg := typo_gap_aux x d m m'
  have h1 := one_le_abs_int_sub_aux m m' typo
  have hh : 1 / (2 * (10 : ℝ) ^ d) = (1 / 2) / 10 ^ d := by field_simp
  rw [hh] at honest passes ⊢
  have hle : |((m' : ℝ) - m)| / 10 ^ d ≤ 1 / 10 ^ d := by
    have : (1 / 2 : ℝ) / 10 ^ d + (1 / 2) / 10 ^ d = 1 / 10 ^ d := by ring
    linarith
  have hle' : |((m' : ℝ) - m)| ≤ 1 := by
    rwa [div_le_div_iff_of_pos_right hu] at hle
  have hge : 1 / 10 ^ d ≤ |((m' : ℝ) - m)| / 10 ^ d :=
    div_le_div_of_nonneg_right h1 hu.le
  refine ⟨?_, ?_⟩
  · have : (1 / 2 : ℝ) / 10 ^ d + (1 / 2) / 10 ^ d = 1 / 10 ^ d := by ring
    linarith
  · have hr : ((|m' - m| : ℤ) : ℝ) = 1 := by
      push_cast
      exact le_antisymm hle' h1
    exact_mod_cast hr

/-- No false alarms: rounding any value to `d` digits moves it by at most half a unit
in the last place, so a correctly rounded claim always passes the half-unit test. -/
theorem rounding_within_half_unit (x : ℝ) (d : ℕ) :
    |x - (round (x * 10 ^ d) : ℝ) / 10 ^ d| ≤ 1 / (2 * (10 : ℝ) ^ d) := by
  have hu : (0 : ℝ) < 10 ^ d := by positivity
  have h := abs_sub_round (x * 10 ^ d)
  have e : x - (round (x * 10 ^ d) : ℝ) / 10 ^ d = (x * 10 ^ d - round (x * 10 ^ d)) / 10 ^ d := by
    field_simp
  rw [e, abs_div, abs_of_pos hu, div_le_iff₀ hu]
  have : 1 / (2 * (10 : ℝ) ^ d) * 10 ^ d = 1 / 2 := by field_simp
  rw [this]; exact h

/-- The typo bound from Step 1: if the true value is within half a unit of the printed
`m / 10 ^ d`, then it is at least half a unit from any other `m' / 10 ^ d` with the
same number of digits. -/
theorem typo_at_least_half_unit_away (x : ℝ) (d : ℕ) (m m' : ℤ)
    (honest : |x - (m : ℝ) / 10 ^ d| ≤ 1 / (2 * (10 : ℝ) ^ d))
    (typo : m' ≠ m) :
    1 / (2 * (10 : ℝ) ^ d) ≤ |x - (m' : ℝ) / 10 ^ d| := by
  have hu : (0 : ℝ) < 10 ^ d := by positivity
  have hg := typo_gap_aux x d m m'
  have h1 := one_le_abs_int_sub_aux m m' typo
  have hh : 1 / (2 * (10 : ℝ) ^ d) = (1 / 2) / 10 ^ d := by field_simp
  rw [hh] at honest ⊢
  have hge : 1 / 10 ^ d ≤ |((m' : ℝ) - m)| / 10 ^ d :=
    div_le_div_of_nonneg_right h1 hu.le
  have : (1 / 2 : ℝ) / 10 ^ d + (1 / 2) / 10 ^ d = 1 / 10 ^ d := by ring
  linarith

/-! The card's worked numbers, as exact fractions. -/

-- Allowances: 0.05 for one digit (707.1), 0.0005 for three digits (10.083).
example : 1 / (2 * (10 : ℚ) ^ 1) = 1 / 20 := by norm_num
example : 1 / (2 * (10 : ℚ) ^ 3) = 1 / 2000 := by norm_num
-- Butter: Q*^2 = 2 K D / h = 2 * 125 * 5200 / (26/10) = 500000.
example : (2 * 125 * 5200 : ℚ) / (26 / 10) = 500000 := by norm_num
-- 707.1 passes: Q* = sqrt 500000 lies within 0.05 of 707.1 (checked by squaring).
example : (7071 / 10 - 1 / 20 : ℚ) ^ 2 ≤ 500000 ∧ (500000 : ℚ) ≤ (7071 / 10 + 1 / 20) ^ 2 := by
  norm_num
-- The typo 701.7 fails: Q* is more than 0.05 above it.
example : (7017 / 10 + 1 / 20 : ℚ) ^ 2 < 500000 := by norm_num
-- Yearly cost sqrt(2 K D h) = sqrt 3380000 lies within 0.005 of 1838.48.
example : (2 * 125 * 5200 * (26 / 10) : ℚ) = 3380000 := by norm_num
example : (183848 / 100 - 1 / 200 : ℚ) ^ 2 ≤ 3380000 ∧
    (3380000 : ℚ) ≤ (183848 / 100 + 1 / 200) ^ 2 := by norm_num
-- Deliveries a year D / Q*: (D / Q*)^2 = 5200^2 / 500000, within 0.005 of 7.35.
example : (735 / 100 - 1 / 200 : ℚ) ^ 2 ≤ 5200 ^ 2 / 500000 ∧
    (5200 ^ 2 / 500000 : ℚ) ≤ (735 / 100 + 1 / 200) ^ 2 := by norm_num
-- The best whole order is 707: cheaper than its neighbours 706 and 708.
example : (125 * 5200 / 707 + (26 / 10) * 707 / 2 : ℚ) ≤ 125 * 5200 / 706 + (26 / 10) * 706 / 2 ∧
    (125 * 5200 / 707 + (26 / 10) * 707 / 2 : ℚ) ≤ 125 * 5200 / 708 + (26 / 10) * 708 / 2 := by
  norm_num
-- Queue, rho = 55/60 = 11/12, within 0.00005 of 0.9167.
example : |(55 / 60 : ℚ) - 9167 / 10000| ≤ 1 / 20000 := by norm_num
-- Lq = rho^2 / (1 - rho) = 121/12 = 10.0833..., within 0.0005 of 10.083.
example : (11 / 12 : ℚ) ^ 2 / (1 - 11 / 12) = 121 / 12 := by norm_num
example : |(121 / 12 : ℚ) - 10083 / 1000| ≤ 1 / 2000 := by norm_num
-- The typo 10.038 fails the half-unit rule (off by 0.0453)...
example : ¬ (|(121 / 12 : ℚ) - 10038 / 1000| ≤ 1 / 2000) := by norm_num
-- ...but passes a 1% relative rule, since 1% of 10.038 is 0.10038.
example : |(121 / 12 : ℚ) - 10038 / 1000| ≤ 1 / 100 * (10038 / 1000) := by norm_num
-- Wq = 60 rho / (mu - lambda) = 11 minutes; W = 60 / (mu - lambda) = 12 minutes.
example : 60 * (11 / 12 : ℚ) / (60 - 55) = 11 := by norm_num
example : 60 / (60 - 55 : ℚ) = 12 := by norm_num
-- Two tills: P(wait) = 121/420, within 0.00005 of 0.2881.
example : let a : ℚ := 55 / 60; let top := a * a / 2 / (1 - a / 2);
    top / (1 + a + top) = 121 / 420 := by norm_num
example : |(121 / 420 : ℚ) - 2881 / 10000| ≤ 1 / 20000 := by norm_num
-- Two tills: Wq = 60 * P(wait) / (2 mu - lambda) = 121/455 minutes, within 0.005 of 0.27,
-- but the 1% rule rejects it: off by more than 1% of 0.27.
example : 60 * (121 / 420 : ℚ) / (2 * 60 - 55) = 121 / 455 := by norm_num
example : |(121 / 455 : ℚ) - 27 / 100| ≤ 1 / 200 := by norm_num
example : ¬ (|(121 / 455 : ℚ) - 27 / 100| ≤ 1 / 100 * (27 / 100)) := by norm_num

#print axioms half_unit_rule_rejects_typo_except_on_tie
#print axioms rounding_within_half_unit
#print axioms typo_at_least_half_unit_away
