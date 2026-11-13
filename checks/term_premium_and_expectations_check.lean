-- What a curve says: two zero rates fix one forward rate by arithmetic, the term premium is the expected extra log return of the long bond over rolling short, and a curve inverts exactly when the forward sits below today's short rate.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.NormNum

open Finset

/-- The forward rate. With continuously compounded zero rates `y`, so that the discount factor is
`D(T) = e^(-y(T) T)`, and two dates `a < b`: a rate `F` makes "lend to `a`, then lock `F` from `a`
to `b`" cost the same as "lend to `b`" (that is, `e^((b - a) F) = D(a) / D(b)`) exactly when
`F = (ln D(a) - ln D(b)) / (b - a)`, so there is one and only one such forward; and that forward
equals `(b y(b) - a y(a)) / (b - a)`. -/
theorem forward_rate_from_zero_rates (y D : ℝ → ℝ) (hD : ∀ T, D T = Real.exp (-(y T * T)))
    {a b : ℝ} (hab : a < b) :
    (∀ F : ℝ, (Real.exp ((b - a) * F) = D a / D b ↔
        F = (Real.log (D a) - Real.log (D b)) / (b - a))) ∧
      (Real.log (D a) - Real.log (D b)) / (b - a) = (b * y b - a * y a) / (b - a) := by
  simp only [hD, Real.log_exp, ← Real.exp_sub]
  have hne : b - a ≠ 0 := by linarith
  refine ⟨fun F => ?_, ?_⟩
  · rw [Real.exp_eq_exp, eq_div_iff hne]
    constructor <;> intro h <;> linear_combination h
  · congr 1; ring

/-- The premium is an expected extra return. One dollar in the `b`-year zero, sold at date `a`
when the rate for the remaining stretch is `R`, is worth `e^(b y(b)) e^(-(b - a) R)`; one dollar
rolled in the `a`-year zero is worth `e^(a y(a))`. For any finite set of scenarios for `R` with
probabilities `p`, the probability-weighted average of the log of their ratio equals `b - a` times
the term premium `F - E[R]`, where `F = (b y(b) - a y(a)) / (b - a)` is the forward. -/
theorem term_premium_eq_expected_excess_log_return {ι : Type*} (s : Finset ι) (p R : ι → ℝ)
    (hp : ∀ i ∈ s, 0 ≤ p i) (hsum : ∑ i ∈ s, p i = 1) (y : ℝ → ℝ) {a b : ℝ} (hab : a < b) :
    ∑ i ∈ s, p i * Real.log (Real.exp (b * y b) * Real.exp (-((b - a) * R i)) / Real.exp (a * y a))
      = (b - a) * ((b * y b - a * y a) / (b - a) - ∑ i ∈ s, p i * R i) := by
  have hne : b - a ≠ 0 := by linarith
  have key : ∀ i, p i * Real.log (Real.exp (b * y b) * Real.exp (-((b - a) * R i)) / Real.exp (a * y a))
      = (b * y b - a * y a) * p i - (b - a) * (p i * R i) := by
    intro i
    rw [← Real.exp_add, ← Real.exp_sub, Real.log_exp]
    ring
  rw [Finset.sum_congr rfl (fun i _ => key i), Finset.sum_sub_distrib, ← Finset.mul_sum,
    ← Finset.mul_sum, hsum]
  field_simp

/-- The inversion rule. For dates `0 ≤ a < b` and forward `F = (b y(b) - a y(a)) / (b - a)`:
the slope of the curve is `y(b) - y(a) = ((b - a) / b) (F - y(a))`, so the longer rate is below
the shorter one exactly when the forward is below the shorter rate. -/
theorem inversion_iff_forward_below_short_rate (y : ℝ → ℝ) {a b : ℝ} (ha : 0 ≤ a) (hab : a < b) :
    y b - y a = (b - a) / b * ((b * y b - a * y a) / (b - a) - y a) ∧
      (y b < y a ↔ (b * y b - a * y a) / (b - a) < y a) := by
  have hb : 0 < b := by linarith
  have hne : b - a ≠ 0 := by linarith
  have h1 : y b - y a = (b - a) / b * ((b * y b - a * y a) / (b - a) - y a) := by
    field_simp
    ring
  refine ⟨h1, ?_⟩
  have hpos : 0 < (b - a) / b := div_pos (by linarith) hb
  rw [← sub_neg, h1, ← sub_neg (b := y a)]
  constructor
  · intro h
    by_contra hc
    replace hc := not_lt.mp hc
    nlinarith [mul_nonneg hpos.le hc]
  · intro h
    nlinarith [mul_neg_of_pos_of_neg hpos h]

/-! ### The card's worked numbers, in percent, as exact fractions -/

-- Forward from year 2 to year 4: zero rates 3 and 4.5 (= 9/2) percent give 6 percent.
example : ((4 : ℚ) * (9 / 2) - 2 * 3) / (4 - 2) = 6 := by norm_num
-- Expected rate: 1, 4 or 7 percent with probabilities 1/4, 1/2, 1/4 averages to 4 percent.
example : (1 / 4 : ℚ) * 1 + 1 / 2 * 4 + 1 / 4 * 7 = 4 := by norm_num
-- Term premium: forward 6 minus expected 4 is 2 percentage points.
example : (6 : ℚ) - 4 = 2 := by norm_num
-- Extra log return over two years, 2 (F - R), in each scenario: 10, 4 and -2 percent.
example : (2 : ℚ) * (6 - 1) = 10 ∧ (2 : ℚ) * (6 - 4) = 4 ∧ (2 : ℚ) * (6 - 7) = -2 := by norm_num
-- Their average is 4 percent over two years, which is 2 percent a year: the premium again.
example : ((1 / 4 : ℚ) * 10 + 1 / 2 * 4 + 1 / 4 * (-2)) / 2 = 2 := by norm_num
-- One-year forwards on the rising curve 2.5, 3, 3.8, 4.5: years 3 and 4 give 5.4 and 6.6,
-- which average to the 6 percent two-year forward.
example : (3 : ℚ) * (19 / 5) - 2 * 3 = 27 / 5 ∧ (4 : ℚ) * (9 / 2) - 3 * (19 / 5) = 33 / 5 ∧
    ((27 / 5 : ℚ) + 33 / 5) / 2 = 6 := by norm_num
-- Inversion: 1-year zero at 5, 2-year zero at 4 give F(1,2) = 3, and -1 = (1/2)(3 - 5).
example : ((2 : ℚ) * 4 - 1 * 5) / (2 - 1) = 3 ∧ (4 : ℚ) - 5 = 1 / 2 * (3 - 5) := by norm_num
-- Premiums +1, 0, -1, -2 read the 3 percent forward as expected rates 2, 3, 4, 5.
example : (3 : ℚ) - 1 = 2 ∧ (3 : ℚ) - 0 = 3 ∧ (3 : ℚ) - (-1) = 4 ∧ (3 : ℚ) - (-2) = 5 := by norm_num
-- What breaks: averaging the zero rates gives 3.75, dividing by b gives 3, the slope is 1.5.
example : ((3 : ℚ) + 9 / 2) / 2 = 15 / 4 ∧ ((4 : ℚ) * (9 / 2) - 2 * 3) / 4 = 3 ∧
    (9 / 2 : ℚ) - 3 = 3 / 2 := by norm_num
-- Try changing: a 5 percent 4-year rate gives a 7 percent forward and a 3 pp premium;
-- a 4.5 percent 2-year rate in the inversion gives F(1,2) = 4.
example : ((4 : ℚ) * 5 - 2 * 3) / 2 = 7 ∧ (7 : ℚ) - 4 = 3 ∧ (2 : ℚ) * (9 / 2) - 1 * 5 = 4 := by
  norm_num

#print axioms forward_rate_from_zero_rates
#print axioms term_premium_eq_expected_excess_log_return
#print axioms inversion_iff_forward_below_short_rate
