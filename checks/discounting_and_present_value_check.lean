-- Discounting: dividing a payment by the growth factor once per year of waiting gives the one deposit that grows back into it, the yearly cuts shrink as the wait grows, multiplying by one minus the rate instead comes out too low, and the card's $100 at 5% lands on the cents it says.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

/-- Present value: a payment `F` is due after `n` years, and money earns the same rate `r`
every year of the wait (growth factor `1 + r`, taken to be positive). Walk the payment back a
year at a time, dividing by `1 + r` once per year: `V 0 = F`, `V (k + 1) = V k / (1 + r)`.
Then `V n` is the break-even deposit: banked today it grows to exactly `F` after `n` years,
and it is the only amount that does. -/
theorem present_value_is_the_deposit_that_grows_into_the_payment (F r : ℝ) (hr : -1 < r)
    (V : ℕ → ℝ) (h0 : V 0 = F) (hstep : ∀ k, V (k + 1) = V k / (1 + r)) (n : ℕ) :
    V n * (1 + r) ^ n = F ∧ ∀ D : ℝ, D * (1 + r) ^ n = F → D = V n := by
  have ha : (0:ℝ) < 1 + r := by linarith
  have hpow : (0:ℝ) < (1 + r) ^ n := pow_pos ha n
  have key : V n * (1 + r) ^ n = F := by
    induction n with
    | zero => simp [h0]
    | succ m ih =>
      have hm : (0:ℝ) < (1 + r) ^ m := pow_pos ha m
      rw [hstep m, pow_succ]
      have : V m / (1 + r) * ((1 + r) ^ m * (1 + r)) = V m * (1 + r) ^ m := by
        field_simp
      rw [this]
      exact ih hm
  refine ⟨key, fun D hD => ?_⟩
  have : D * (1 + r) ^ n = V n * (1 + r) ^ n := by rw [hD, key]
  exact mul_right_cancel₀ hpow.ne' this

/-- The drop is not a straight line: for a positive payment and a positive rate, each extra
year of waiting cuts today's value by a positive amount, and each year's cut is strictly
smaller than the year before's, because the cut is taken off what is left, not off the
original payment. -/
theorem discount_cuts_shrink (F r : ℝ) (hF : 0 < F) (hr : 0 < r)
    (V : ℕ → ℝ) (h0 : V 0 = F) (hstep : ∀ k, V (k + 1) = V k / (1 + r)) (k : ℕ) :
    0 < V (k + 1) - V (k + 2) ∧ V (k + 1) - V (k + 2) < V k - V (k + 1) := by
  have ha : (0:ℝ) < 1 + r := by linarith
  have hpos : ∀ j, 0 < V j := by
    intro j
    induction j with
    | zero => rw [h0]; exact hF
    | succ m ih => rw [hstep m]; exact div_pos ih ha
  have e1 : V (k + 1) - V (k + 2) = V (k + 1) * (r / (1 + r)) := by
    rw [show k + 2 = (k + 1) + 1 from rfl, hstep (k + 1)]
    field_simp
    ring
  have e0 : V k - V (k + 1) = V k * (r / (1 + r)) := by
    rw [hstep k]
    field_simp
    ring
  have hq : 0 < r / (1 + r) := div_pos hr ha
  have hlt : V (k + 1) < V k := by
    rw [hstep k]
    have := hpos k
    rw [div_lt_iff₀ ha]
    nlinarith
  rw [e1, e0]
  exact ⟨mul_pos (hpos (k + 1)) hq, mul_lt_mul_of_pos_right hlt hq⟩

/-- The usual mistake: a fall of `r` does not undo a rise of `r`. For a positive payment, a
positive rate below 100%, and a wait of at least one year, taking `r` off the payment once per
year (multiplying by `1 - r`) comes out strictly below the true present value, which divides
by `1 + r` once per year. -/
theorem taking_the_rate_off_undershoots (F r : ℝ) (hF : 0 < F) (hr : 0 < r) (hr1 : r < 1)
    (n : ℕ) (hn : 1 ≤ n) :
    F * (1 - r) ^ n < F / (1 + r) ^ n := by
  have ha : (0:ℝ) < 1 + r := by linarith
  have hpow : (0:ℝ) < (1 + r) ^ n := pow_pos ha n
  have h1 : 0 < 1 - r := by linarith
  have hprod : (1 - r) ^ n * (1 + r) ^ n = (1 - r ^ 2) ^ n := by
    rw [← mul_pow]; congr 1; ring
  have hr2 : 0 < r ^ 2 := by positivity
  have hlt : (1 - r ^ 2) ^ n < 1 := by
    have h0 : 0 ≤ 1 - r ^ 2 := by nlinarith
    have h1' : 1 - r ^ 2 < 1 := by linarith
    calc (1 - r ^ 2) ^ n < 1 ^ n := pow_lt_pow_left₀ h1' h0 (by omega)
      _ = 1 := one_pow n
  rw [lt_div_iff₀ hpow]
  calc F * (1 - r) ^ n * (1 + r) ^ n = F * ((1 - r) ^ n * (1 + r) ^ n) := by ring
    _ = F * (1 - r ^ 2) ^ n := by rw [hprod]
    _ < F * 1 := mul_lt_mul_of_pos_left hlt hF
    _ = F := mul_one F

-- The card's $100 at 5%, in exact fractions. Dividing by 1.05 is multiplying by 20/21.
example : (100 : ℚ) / (105 / 100) = 100 * (20 / 21) := by norm_num
-- One year back, in cents: 10000 × 20/21 lies within half a cent of 9524 ($95.24).
example : (19047 / 2 : ℚ) ≤ 10000 * (20 / 21) ∧ (10000 : ℚ) * (20 / 21) < 19049 / 2 := by
  norm_num
-- $95.24 banked for a year at 5% lands on $100.00 to the cent.
example : (19999 / 2 : ℚ) ≤ 9524 * (105 / 100) ∧ (9524 : ℚ) * (105 / 100) < 20001 / 2 := by
  norm_num
-- Two years back: within half a cent of 9070 ($90.70).
example : (18139 / 2 : ℚ) ≤ 10000 * (20 / 21) ^ 2 ∧ (10000 : ℚ) * (20 / 21) ^ 2 < 18141 / 2 := by
  norm_num
-- Ten years back: within half a cent of 6139 ($61.39).
example : (12277 / 2 : ℚ) ≤ 10000 * (20 / 21) ^ 10 ∧
    (10000 : ℚ) * (20 / 21) ^ 10 < 12279 / 2 := by norm_num
-- The card's whole-number road to the ten-year answer, rounded to the nearest cent.
example : (2 * 10000 * 20 ^ 10 + 21 ^ 10) / (2 * 21 ^ 10) = 6139 := by norm_num
-- $61.39 grown ten years at 5% returns to $100.00, to the cent.
example : (19999 / 2 : ℚ) ≤ 6139 * (105 / 100) ^ 10 ∧
    (6139 : ℚ) * (105 / 100) ^ 10 < 20001 / 2 := by norm_num
-- Discount factors: 20/21 rounds to 0.952381 and (20/21)^10 to 0.613913, to six places.
example : (1904761 / 2000000 : ℚ) ≤ 20 / 21 ∧ (20 / 21 : ℚ) < 1904763 / 2000000 := by norm_num
example : (1227825 / 2000000 : ℚ) ≤ (20 / 21) ^ 10 ∧
    ((20 : ℚ) / 21) ^ 10 < 1227827 / 2000000 := by norm_num
-- The mistakes, in cents: 5% off the payment gives 9500 ($95.00); multiplying by 0.95 ten
-- times gives within half a cent of 5987 ($59.87).
example : (10000 : ℚ) * (95 / 100) = 9500 := by norm_num
example : (11973 / 2 : ℚ) ≤ 10000 * (95 / 100) ^ 10 ∧
    (10000 : ℚ) * (95 / 100) ^ 10 < 11975 / 2 := by norm_num

#print axioms present_value_is_the_deposit_that_grows_into_the_payment
#print axioms discount_cuts_shrink
#print axioms taking_the_rate_off_undershoots
