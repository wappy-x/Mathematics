-- Spot, forward and par rates: two spot rates force the forward rate between them by no-arbitrage, the par coupon is the one coupon that prices a bond at face, and on a rising curve the forward runs above the spot.
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Algebra.BigOperators.Ring.Finset

open Finset

/-! Annual compounding, dates a whole year apart, certain cash flows.
`z₁` and `z₂` are the one-year and two-year spot rates, so one dollar lent today grows to
`1 + z₁` at year 1 and to `(1 + z₂) ^ 2` at year 2. `x` is the rate a dealer quotes today
for the year from date 1 to date 2.

A trade is three positions of any size and either sign (lending and borrowing on the same terms):
* `a` dollars lent today for two years (negative means borrowed),
* `b` dollars lent today for one year (negative means borrowed),
* `c` dollars placed with the dealer at date 1 for the second year (negative means borrowed).
Its cash flows are `-(a + b)` today, `b * (1 + z₁) - c` at date 1,
and `a * (1 + z₂) ^ 2 + c * (1 + x)` at date 2. -/

/-- Two spot rates force the forward rate between them: no trade costs nothing today,
nets nothing at date 1 and is certain to pay something at date 2 exactly when
`(1 + z₂)² = (1 + z₁)(1 + f₁,₂)` with `f₁,₂ = x`. -/
theorem forward_rate_forced_by_no_arbitrage (z₁ z₂ x : ℝ) :
    (¬ ∃ a b c : ℝ, -(a + b) = 0 ∧ b * (1 + z₁) - c = 0 ∧
        0 < a * (1 + z₂) ^ 2 + c * (1 + x)) ↔
      (1 + z₂) ^ 2 = (1 + z₁) * (1 + x) := by
  constructor
  · intro h
    by_contra hne
    apply h
    have hd : (1 + z₂) ^ 2 - (1 + z₁) * (1 + x) ≠ 0 := sub_ne_zero.mpr hne
    refine ⟨(1 + z₂) ^ 2 - (1 + z₁) * (1 + x), -((1 + z₂) ^ 2 - (1 + z₁) * (1 + x)),
      -((1 + z₂) ^ 2 - (1 + z₁) * (1 + x)) * (1 + z₁), by ring, by ring, ?_⟩
    have hsq := mul_self_pos.mpr hd
    have he : ((1 + z₂) ^ 2 - (1 + z₁) * (1 + x)) * (1 + z₂) ^ 2 +
        -((1 + z₂) ^ 2 - (1 + z₁) * (1 + x)) * (1 + z₁) * (1 + x) =
        ((1 + z₂) ^ 2 - (1 + z₁) * (1 + x)) * ((1 + z₂) ^ 2 - (1 + z₁) * (1 + x)) := by ring
    rw [he]
    exact hsq
  · rintro h ⟨a, b, c, h1, h2, h3⟩
    have hb : b = -a := by linarith
    have hc : c = b * (1 + z₁) := by linarith
    have h0 : a * (1 + z₂) ^ 2 + c * (1 + x) = 0 := by
      rw [hc, hb, h]; ring
    linarith

/-- The par rate: with positive discount factors `D 1, …, D n` (`n ≥ 1`) and face value `N > 0`,
a bond paying coupon `N * c` each year and `N` at year `n` sells for exactly its face value
if and only if `c = (1 - D n) / (D 1 + ⋯ + D n)`. So the par coupon exists and is unique. -/
theorem par_coupon_prices_at_face_iff (n : ℕ) (hn : 1 ≤ n) (D : ℕ → ℝ)
    (hD : ∀ t ∈ Icc 1 n, 0 < D t) (N : ℝ) (hN : 0 < N) (c : ℝ) :
    (∑ t ∈ Icc 1 n, N * c * D t) + N * D n = N ↔
      c = (1 - D n) / ∑ t ∈ Icc 1 n, D t := by
  have hne : (Icc 1 n).Nonempty := ⟨n, mem_Icc.mpr ⟨hn, le_refl n⟩⟩
  have hS : 0 < ∑ t ∈ Icc 1 n, D t := Finset.sum_pos hD hne
  rw [← Finset.mul_sum, eq_div_iff hS.ne']
  constructor
  · intro h
    have h' : N * (c * ∑ t ∈ Icc 1 n, D t + D n) = N * 1 := by
      rw [mul_add, mul_one, ← mul_assoc]; linarith
    have := mul_left_cancel₀ hN.ne' h'
    linarith
  · intro h
    rw [mul_assoc, h]; ring

/-- On a rising curve the forward runs above the spot: if the spot rate to year `t ≥ 1` is `a`
(above minus 100 percent), the spot rate to year `t + 1` is `b > a`, and `f` is the forward
for the year from `t` to `t + 1`, so `(1 + b)^(t+1) = (1 + a)^t (1 + f)`, then `f > b`. -/
theorem forward_above_spot_on_rising_curve (t : ℕ) (ht : 1 ≤ t) (a b f : ℝ)
    (ha : -1 < a) (hrise : a < b)
    (hfwd : (1 + b) ^ (t + 1) = (1 + a) ^ t * (1 + f)) :
    b < f := by
  have h1 : 0 < 1 + a := by linarith
  have h2 : 0 < 1 + b := by linarith
  have hpow : (1 + a) ^ t < (1 + b) ^ t := pow_lt_pow_left₀ (by linarith) h1.le (by omega)
  have hpa : 0 < (1 + a) ^ t := pow_pos h1 t
  rw [pow_succ] at hfwd
  by_contra hle
  push_neg at hle
  have k1 := mul_le_mul_of_nonneg_left (show 1 + f ≤ 1 + b by linarith) hpa.le
  have k2 := mul_lt_mul_of_pos_right hpow h2
  linarith

/-! The card's worked numbers, as exact fractions: 4 percent for one year, 5 percent for two. -/

-- Two years at 5 percent equal one year at 4 percent then the forward 25/416 (6.0096 percent).
example : (1 + (5 : ℝ) / 100) ^ 2 = (1 + 4 / 100) * (1 + 25 / 416) := by norm_num
-- 100 dollars: 110.25 for two years, 104.00 for one year.
example : (100 : ℝ) * (1 + 5 / 100) ^ 2 = 11025 / 100 := by norm_num
example : (100 : ℝ) * (1 + 4 / 100) = 104 := by norm_num
-- The forward as a ratio of discount factors: D(1) / D(2) - 1 = 25/416.
example : (1 / (1 + (4 : ℝ) / 100)) / (1 / (1 + 5 / 100) ^ 2) - 1 = 25 / 416 := by norm_num
-- Two-year par rate: (1 - D(2)) / (D(1) + D(2)) = 1066/21425 (4.9755 percent).
example : (1 - 1 / (1 + (5 : ℝ) / 100) ^ 2) / (1 / (1 + 4 / 100) + 1 / (1 + 5 / 100) ^ 2)
    = 1066 / 21425 := by norm_num
-- A two-year bond paying that coupon on 100 face prices at exactly 100.
example : 100 * (1066 / 21425 : ℝ) * (1 / (1 + 4 / 100)) +
    100 * (1066 / 21425) * (1 / (1 + 5 / 100) ^ 2) + 100 * (1 / (1 + 5 / 100) ^ 2) = 100 := by
  norm_num
-- The par rate sits below the two-year spot rate and above the one-year rate.
example : (4 : ℝ) / 100 < 1066 / 21425 ∧ (1066 / 21425 : ℝ) < 5 / 100 := by norm_num
-- A dealer quoting 6.50 percent for year two leaves 0.51 free on 100 dollars.
example : (100 : ℝ) * (1 + 4 / 100) * (1 + 65 / 1000) - 100 * (1 + 5 / 100) ^ 2 = 51 / 100 := by
  norm_num
-- Rolling at today's one-year rate twice gives 108.16, short by 2.09.
example : (100 : ℝ) * (1 + 4 / 100) ^ 2 = 10816 / 100 ∧
    (100 : ℝ) * (1 + 5 / 100) ^ 2 - 100 * (1 + 4 / 100) ^ 2 = 209 / 100 := by norm_num
-- Using the two-year spot for year two gives 109.20, short by 1.05.
example : (100 : ℝ) * (1 + 4 / 100) * (1 + 5 / 100) = 10920 / 100 ∧
    (100 : ℝ) * (1 + 5 / 100) ^ 2 - 100 * (1 + 4 / 100) * (1 + 5 / 100) = 105 / 100 := by norm_num
-- Averaging the two spots gives 4.5 percent, not the forward 25/416.
example : ((4 : ℝ) / 100 + 5 / 100) / 2 = 9 / 200 ∧ (9 / 200 : ℝ) ≠ 25 / 416 := by norm_num
-- The continuous-compounding straight-line rule gives 2 × 5 − 4 = 6 percent, below 25/416.
example : (2 * (5 : ℝ) / 100 - 4 / 100) = 6 / 100 ∧ (6 / 100 : ℝ) < 25 / 416 := by norm_num

#print axioms forward_rate_forced_by_no_arbitrage
#print axioms par_coupon_prices_at_face_iff
#print axioms forward_above_spot_on_rising_curve
