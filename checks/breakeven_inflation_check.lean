-- Breakeven inflation: a linker and a nominal bond of the same maturity pay the same dollars exactly when inflation equals nominal growth over real growth minus one, coupons do not change this, and subtracting yields overstates it by the real yield times the breakeven.
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.Order.Field.Power
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open Finset

/-- Helper: the map `x ↦ ∑_{t=1}^T c x^t + x^T` is strictly increasing on `x ≥ 0` when `c ≥ 0`
and `T ≥ 1`. -/
theorem breakeven_helper_strict (T : ℕ) (hT : 0 < T) (c x y : ℝ) (hc : 0 ≤ c)
    (hx : 0 ≤ x) (hxy : x < y) :
    (∑ t ∈ Icc 1 T, c * x ^ t) + x ^ T < (∑ t ∈ Icc 1 T, c * y ^ t) + y ^ T := by
  have h1 : (∑ t ∈ Icc 1 T, c * x ^ t) ≤ ∑ t ∈ Icc 1 T, c * y ^ t := by
    apply Finset.sum_le_sum
    intro t _
    exact mul_le_mul_of_nonneg_left (pow_le_pow_left₀ hx hxy.le t) hc
  have h2 : x ^ T < y ^ T := pow_lt_pow_left₀ hxy hx (Nat.pos_iff_ne_zero.mp hT)
  linarith

#print axioms breakeven_helper_strict

/-- Breakeven inflation, zero-coupon bonds: over `T ≥ 1` years, with nominal yield `n` and real
yield `r` both above −100 percent, a constant inflation rate `b` above −100 percent makes the
linker's dollars `(1+r)^T (1+b)^T` equal the nominal bond's dollars `(1+n)^T` exactly when
`b = (1+n)/(1+r) − 1`. The number of years does not matter. -/
theorem breakeven_closed_form (T : ℕ) (hT : 0 < T) (n r b : ℝ)
    (hn : -1 < n) (hr : -1 < r) (hb : -1 < b) :
    (1 + n) ^ T = (1 + r) ^ T * (1 + b) ^ T ↔ b = (1 + n) / (1 + r) - 1 := by
  have h1 : 0 < 1 + n := by linarith
  have h2 : 0 < 1 + r := by linarith
  have h3 : 0 < 1 + b := by linarith
  rw [← mul_pow, pow_left_inj₀ h1.le (mul_pos h2 h3).le (Nat.pos_iff_ne_zero.mp hT)]
  constructor
  · intro h
    rw [h]
    field_simp
    ring
  · intro h
    rw [h]
    field_simp
    ring

/-- Coupons do not move the breakeven: a linker with real coupon `c ≥ 0`, priced at
`P = ∑_{t=1}^T c/(1+r)^t + 1/(1+r)^T` from its real yield `r`, has its index-scaled flows under a
constant inflation `π > −1`, discounted at the nominal yield `n`, worth exactly `P` if and only if
`π = (1+n)/(1+r) − 1`. -/
theorem coupon_linker_breakeven_eq_closed_form (T : ℕ) (hT : 0 < T) (c n r π : ℝ)
    (hc : 0 ≤ c) (hn : -1 < n) (hr : -1 < r) (hπ : -1 < π) :
    (∑ t ∈ Icc 1 T, c * (1 + π) ^ t / (1 + n) ^ t) + (1 + π) ^ T / (1 + n) ^ T
        = (∑ t ∈ Icc 1 T, c / (1 + r) ^ t) + 1 / (1 + r) ^ T
      ↔ π = (1 + n) / (1 + r) - 1 := by
  have h1 : 0 < 1 + n := by linarith
  have h2 : 0 < 1 + r := by linarith
  have h3 : 0 < 1 + π := by linarith
  set x := (1 + π) / (1 + n) with hxdef
  set y := 1 / (1 + r) with hydef
  have hx : 0 < x := div_pos h3 h1
  have hy : 0 < y := div_pos one_pos h2
  have eL : (∑ t ∈ Icc 1 T, c * (1 + π) ^ t / (1 + n) ^ t) + (1 + π) ^ T / (1 + n) ^ T
      = (∑ t ∈ Icc 1 T, c * x ^ t) + x ^ T := by
    rw [hxdef, div_pow]
    congr 1
    apply Finset.sum_congr rfl
    intro t _
    rw [div_pow, mul_div_assoc]
  have eR : (∑ t ∈ Icc 1 T, c / (1 + r) ^ t) + 1 / (1 + r) ^ T
      = (∑ t ∈ Icc 1 T, c * y ^ t) + y ^ T := by
    rw [hydef, one_div_pow]
    congr 1
    apply Finset.sum_congr rfl
    intro t _
    rw [one_div_pow, div_eq_mul_inv, one_div]
  rw [eL, eR]
  have key : (∑ t ∈ Icc 1 T, c * x ^ t) + x ^ T = (∑ t ∈ Icc 1 T, c * y ^ t) + y ^ T
      ↔ x = y := by
    constructor
    · intro h
      rcases lt_trichotomy x y with hlt | heq | hgt
      · have := breakeven_helper_strict T hT c x y hc hx.le hlt
        linarith
      · exact heq
      · have := breakeven_helper_strict T hT c y x hc hy.le hgt
        linarith
    · intro h
      rw [h]
  rw [key, hxdef, hydef]
  constructor
  · intro h
    rw [div_eq_div_iff h1.ne' h2.ne'] at h
    field_simp
    linarith
  · intro h
    rw [h]
    field_simp
    ring

/-- The shortcut overstates: the yield spread `n − r` minus the breakeven `b = (1+n)/(1+r) − 1`
equals the real yield times the breakeven, `r b`. -/
theorem yield_spread_sub_breakeven (n r : ℝ) (hr : -1 < r) :
    (n - r) - ((1 + n) / (1 + r) - 1) = r * ((1 + n) / (1 + r) - 1) := by
  have h2 : 0 < 1 + r := by linarith
  field_simp
  ring

-- The card's example: n = 3.525% = 141/4000, r = 1% = 1/100 give b = 2.5% = 1/40.
example : ((1 : ℚ) + 141 / 4000) / (1 + 1 / 100) - 1 = 1 / 40 := by norm_num
-- The ten-year tie holds exactly at b = 1/40: 1.03525^10 = 1.01^10 * 1.025^10.
example : ((1 : ℚ) + 141 / 4000) ^ 10 = (1 + 1 / 100) ^ 10 * (1 + 1 / 40) ^ 10 := by norm_num
-- And at thirty years, with the same yields.
example : ((1 : ℚ) + 141 / 4000) ^ 30 = (1 + 1 / 100) ^ 30 * (1 + 1 / 40) ^ 30 := by norm_num
-- Shortcut s = n - r = 2.525% = 101/4000; its error is r * b = 2.5 bp = 1/4000.
example : (141 : ℚ) / 4000 - 1 / 100 = 101 / 4000 := by norm_num
example : (101 : ℚ) / 4000 - 1 / 40 = (1 / 100) * (1 / 40) := by norm_num
-- Swap minus breakeven: 2.6% - 2.5% = 10 bp = 1/1000.
example : (26 : ℚ) / 1000 - 1 / 40 = 1 / 1000 := by norm_num
-- Swap quoted at 2.5%: the synthetic real yield is exactly the cash linker's 1%.
example : ((1 : ℚ) + 141 / 4000) / (1 + 1 / 40) - 1 = 1 / 100 := by norm_num
-- Wrong way round, real over nominal: -2.439% = -1/41.
example : ((1 : ℚ) + 1 / 100) / (1 + 141 / 4000) - 1 = -1 / 41 := by norm_num
-- Boundary: n = 0.5%, r = 1% gives b = -0.495% = -1/202.
example : ((1 : ℚ) + 5 / 1000) / (1 + 1 / 100) - 1 = -1 / 202 := by norm_num
-- Try: real yield 2% gives 61/4080 (1.4951%); nominal yield 5% gives 4/101 (3.9604%).
example : ((1 : ℚ) + 141 / 4000) / (1 + 2 / 100) - 1 = 61 / 4080 := by norm_num
example : ((1 : ℚ) + 5 / 100) / (1 + 1 / 100) - 1 = 4 / 101 := by norm_num

#print axioms breakeven_closed_form
#print axioms coupon_linker_breakeven_eq_closed_form
#print axioms yield_spread_sub_breakeven
