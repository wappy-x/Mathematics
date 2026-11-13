-- Carry and roll-down: on a curve held still by years left, a zero's log return is carry plus roll-down, the breakeven rise over cash lands exactly on the forward yield, and on the forward curve every bond earns cash.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Finset

/-- Carry plus roll-down is the whole return on a still curve.
A zero-coupon bond with face `N > 0` maturing in `T` years costs `N e^{-T y(T)}` today,
where `y` is today's continuously compounded zero curve. Held `h` years on a curve that
does not move (read by years left), it sells for `N e^{-(T-h) y(T-h)}`. Its log return is
carry `C = h y(T)` plus roll-down `R = (T-h)(y(T) - y(T-h))`, and that sum equals
`T y(T) - (T-h) y(T-h)`, the forward rate for the stretch of maturities the bond slides through. -/
theorem log_return_eq_carry_add_roll_down (y : ℝ → ℝ) (N T h : ℝ) (hN : 0 < N) :
    Real.log ((N * Real.exp (-((T - h) * y (T - h)))) / (N * Real.exp (-(T * y T))))
        = h * y T + (T - h) * (y T - y (T - h))
      ∧ h * y T + (T - h) * (y T - y (T - h)) = T * y T - (T - h) * y (T - h) := by
  rw [mul_div_mul_left _ _ hN.ne', ← Real.exp_sub, Real.log_exp]
  constructor <;> ring

/-- The breakeven rise lands on the forward curve.
If the yield at the bond's years left at sale is `y(T-h) + δ` instead of `y(T-h)`, the bond's
log return equals cash's `h y(h)` exactly when `δ = (C + R - h y(h)) / (T - h)`, so this
breakeven exists and is unique; and it equals `f - y(T-h)`, where
`f = (T y(T) - h y(h)) / (T - h)` is the forward yield locked in by today's curve. -/
theorem breakeven_rise_eq_forward_sub_spot (y : ℝ → ℝ) (N T h δ : ℝ) (hN : 0 < N)
    (hhT : h < T) :
    (Real.log ((N * Real.exp (-((T - h) * (y (T - h) + δ)))) / (N * Real.exp (-(T * y T))))
          = h * y h
        ↔ δ = (h * y T + (T - h) * (y T - y (T - h)) - h * y h) / (T - h))
      ∧ (h * y T + (T - h) * (y T - y (T - h)) - h * y h) / (T - h)
          = (T * y T - h * y h) / (T - h) - y (T - h) := by
  have hT : T - h ≠ 0 := sub_ne_zero.mpr (ne_of_gt hhT)
  rw [mul_div_mul_left _ _ hN.ne', ← Real.exp_sub, Real.log_exp]
  constructor
  · rw [eq_div_iff hT]
    constructor
    · intro hE
      linarith
    · intro hE
      linarith
  · field_simp
    ring

/-- On the forward curve, every bond earns cash.
Take any bond with fixed payments `c t` at the finitely many times `t ∈ s` (years from today),
none before the sale date `h`. Its price today is `∑ c t D(t)` with `D(t) = e^{-t y(t)}`.
If a year from now the curve is the forward curve, so a payment due at `t > h` is discounted
by `D(t) / D(h)`, then its wealth at the sale date (the coupon paid at `h`, plus the rest priced
on the forward curve) is today's price grown at the cash rate: `P₀ e^{h y(h)}`. -/
theorem forward_curve_horizon_wealth_eq_cash (y : ℝ → ℝ) (c : ℝ → ℝ) (s : Finset ℝ) (h : ℝ)
    (hs : ∀ t ∈ s, h ≤ t) :
    (∑ t ∈ s.filter (fun t => t = h), c t)
        + ∑ t ∈ s.filter (fun t => h < t),
            c t * (Real.exp (-(t * y t)) / Real.exp (-(h * y h)))
      = (∑ t ∈ s, c t * Real.exp (-(t * y t))) * Real.exp (h * y h) := by
  have hE : Real.exp (h * y h) = 1 / Real.exp (-(h * y h)) := by
    rw [Real.exp_neg, one_div, inv_inv]
  rw [Finset.sum_filter, Finset.sum_filter, ← Finset.sum_add_distrib, Finset.sum_mul]
  refine Finset.sum_congr rfl (fun t ht => ?_)
  rcases eq_or_ne t h with rfl | hne
  · simp [Real.exp_neg]
  · have hlt : h < t := lt_of_le_of_ne (hs t ht) (Ne.symm hne)
    simp only [hne, ite_false, hlt, ite_true, zero_add]
    rw [hE]
    ring

/-! The card's worked numbers, exactly, in rationals. Yields: 1y 3.00%, 2y 3.30%, 3y 3.65%,
4y 4.05%, 5y 4.50%. Five-year zero held one year. -/

-- carry 4.50% plus roll-down 4 × 0.45% = 1.80% is 6.30%
example : (1 : ℚ) * (450 / 10000) + 4 * (450 / 10000 - 405 / 10000) = 630 / 10000 := by norm_num
-- the same 6.30% is T y(T) - (T-h) y(T-h): 5 × 4.50% - 4 × 4.05%
example : (5 : ℚ) * (450 / 10000) - 4 * (405 / 10000) = 630 / 10000 := by norm_num
-- net carry 1.50% plus roll-down 1.80% is the 3.30% excess over one-year cash
example : (450 / 10000 - 300 / 10000 : ℚ) + 180 / 10000 = 630 / 10000 - 300 / 10000 := by norm_num
-- forward four-year yield: (5 × 4.50% - 1 × 3.00%) / 4 = 4.875%
example : ((5 : ℚ) * (450 / 10000) - 1 * (300 / 10000)) / 4 = 4875 / 100000 := by norm_num
-- breakeven against cash: 3.30% / 4 = 82.5 bp = 4.875% - 4.05%
example : ((630 : ℚ) / 10000 - 300 / 10000) / 4 = 825 / 100000 := by norm_num
example : (4875 : ℚ) / 100000 - 405 / 10000 = 825 / 100000 := by norm_num
-- breakeven against a zero return: 6.30% / 4 = 157.5 bp
example : ((630 : ℚ) / 10000) / 4 = 1575 / 100000 := by norm_num
-- the mistakes: roll times 5 years gives 2.25%; excess over 5 years gives 66 bp
example : (5 : ℚ) * (450 / 10000 - 405 / 10000) = 225 / 10000 := by norm_num
example : ((330 : ℚ) / 10000) / 5 = 66 / 10000 := by norm_num
-- every bond on the curve: carry + roll and breakeven vs cash for the 2-, 3- and 4-year zeros
example : (330 : ℚ) / 10000 + 1 * (330 / 10000 - 300 / 10000) = 360 / 10000 ∧
    ((360 : ℚ) / 10000 - 300 / 10000) / 1 = 60 / 10000 := by norm_num
example : (365 : ℚ) / 10000 + 2 * (365 / 10000 - 330 / 10000) = 435 / 10000 ∧
    ((435 : ℚ) / 10000 - 300 / 10000) / 2 = 675 / 100000 := by norm_num
example : (405 : ℚ) / 10000 + 3 * (405 / 10000 - 365 / 10000) = 525 / 10000 ∧
    ((525 : ℚ) / 10000 - 300 / 10000) / 3 = 75 / 10000 := by norm_num
-- the breakeven curve ((1+u) y(1+u) - y(1)) / u for u = 1, 2, 3, 4: 3.60%, 3.975%, 4.40%, 4.875%
example : (2 * (330 : ℚ) / 10000 - 300 / 10000) / 1 = 360 / 10000 ∧
    (3 * (365 : ℚ) / 10000 - 300 / 10000) / 2 = 3975 / 100000 ∧
    (4 * (405 : ℚ) / 10000 - 300 / 10000) / 3 = 440 / 10000 ∧
    (5 * (450 : ℚ) / 10000 - 300 / 10000) / 4 = 4875 / 100000 := by norm_num

#print axioms log_return_eq_carry_add_roll_down
#print axioms breakeven_rise_eq_forward_sub_spot
#print axioms forward_curve_horizon_wealth_eq_cash
