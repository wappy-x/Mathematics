-- Bond price and yield: discounting every coupon and the face at one yield collapses to coupon times the annuity factor plus the discounted face, equals the face plus the excess coupon times that factor, and so the bond sells at a premium, at par or at a discount exactly as the coupon is above, equal to or below the yield times the face.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.BigOperators.Ring.Finset

open Finset

/-- Helper: the coupons alone, summed in closed form with an ordinary power. -/
theorem bond_coupon_sum_closed (c y : ℝ) (N : ℕ) (h1 : 1 + y ≠ 0) (hy : y ≠ 0) :
    ∑ t ∈ Icc 1 N, c / (1 + y) ^ t = c * ((1 - ((1 + y) ^ N)⁻¹) / y) := by
  induction N with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    field_simp
    ring

/-- Helper: price minus face is the excess coupon `c - (q - 1) * F`, discounted and summed. -/
theorem bond_price_sub_face (c F q : ℝ) (N : ℕ) (hq : q ≠ 0) :
    ∑ t ∈ Icc 1 N, c / q ^ t + F / q ^ N =
      F + ∑ t ∈ Icc 1 N, (c - (q - 1) * F) / q ^ t := by
  induction N with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), Finset.sum_Icc_succ_top (by omega)]
    have key : F / q ^ n = F * q / q ^ (n + 1) := by
      rw [pow_succ]; field_simp
    have e1 : (c - (q - 1) * F) / q ^ (n + 1) = c / q ^ (n + 1) - F * q / q ^ (n + 1)
        + F / q ^ (n + 1) := by ring
    rw [e1]
    linarith [ih, key]

#print axioms bond_coupon_sum_closed
#print axioms bond_price_sub_face

/-! A bond with face `F`, a coupon `c` paid at the end of each of `N` periods, and the face
handed back with the last coupon. At a yield `y` per period, the payment due after `t` periods
is divided by `(1 + y) ^ t`. The price is
`P = ∑ t ∈ Icc 1 N, c / (1 + y) ^ t + F / (1 + y) ^ N`, and the annuity factor is
`a_N(y) = (1 - (1 + y) ^ (-N)) / y`. -/

/-- The bond price in closed form: every coupon and the face, each divided by `1 + y` once per
period of waiting and added up, equals the coupon times the annuity factor
`(1 - (1 + y) ^ (-N)) / y` plus the face discounted once over the whole `N` periods. The
closed form divides by `y`, so the yield is not zero (and `1 + y ≠ 0`, so that every discount
factor is defined). -/
theorem bond_price_closed_form (c F y : ℝ) (N : ℕ) (h1 : 1 + y ≠ 0) (hy : y ≠ 0) :
    ∑ t ∈ Icc 1 N, c / (1 + y) ^ t + F / (1 + y) ^ N =
      c * ((1 - (1 + y) ^ (-(N : ℤ))) / y) + F * (1 + y) ^ (-(N : ℤ)) := by
  rw [bond_coupon_sum_closed c y N h1 hy, zpow_neg, zpow_natCast, div_eq_mul_inv F]

/-- Face plus excess coupon: split the coupon into the interest the market demands on the
face, `y * F`, and what is left over; the first part prices to exactly the face, so the price
is the face plus the leftover coupon `c - y * F` times the annuity factor (yield not zero,
`1 + y ≠ 0`). -/
theorem bond_price_eq_face_add_excess_coupon (c F y : ℝ) (N : ℕ) (h1 : 1 + y ≠ 0)
    (hy : y ≠ 0) :
    ∑ t ∈ Icc 1 N, c / (1 + y) ^ t + F / (1 + y) ^ N =
      F + (c - y * F) * ((1 - (1 + y) ^ (-(N : ℤ))) / y) := by
  rw [bond_price_closed_form c F y N h1 hy]
  field_simp
  ring

/-- Premium, par and discount: for a yield above `-1` (every discount factor positive) and at
least one payment still to come, the bond sells above face exactly when the coupon is above
`y * F`, at face exactly when they are equal, and below face exactly when the coupon is below
`y * F`. -/
theorem bond_premium_par_discount (c F y : ℝ) (N : ℕ) (hy : -1 < y) (hN : 0 < N) :
    (F < ∑ t ∈ Icc 1 N, c / (1 + y) ^ t + F / (1 + y) ^ N ↔ y * F < c) ∧
    (∑ t ∈ Icc 1 N, c / (1 + y) ^ t + F / (1 + y) ^ N = F ↔ c = y * F) ∧
    (∑ t ∈ Icc 1 N, c / (1 + y) ^ t + F / (1 + y) ^ N < F ↔ c < y * F) := by
  have hq : 0 < 1 + y := by linarith
  have hA : 0 < ∑ t ∈ Icc 1 N, 1 / (1 + y) ^ t := by
    apply Finset.sum_pos
    · intro t _; positivity
    · exact ⟨1, Finset.mem_Icc.mpr ⟨le_rfl, hN⟩⟩
  have hP : ∑ t ∈ Icc 1 N, c / (1 + y) ^ t + F / (1 + y) ^ N =
      F + (c - y * F) * ∑ t ∈ Icc 1 N, 1 / (1 + y) ^ t := by
    rw [bond_price_sub_face c F (1 + y) N hq.ne', Finset.mul_sum]
    congr 1
    refine Finset.sum_congr rfl fun t _ => ?_
    ring
  rw [hP]
  set A := ∑ t ∈ Icc 1 N, 1 / (1 + y) ^ t
  refine ⟨⟨fun h => ?_, fun h => ?_⟩, ⟨fun h => ?_, fun h => ?_⟩, ⟨fun h => ?_, fun h => ?_⟩⟩
  · by_contra hc; push Not at hc; nlinarith
  · nlinarith
  · have : (c - y * F) * A = 0 := by linarith
    rcases mul_eq_zero.mp this with h' | h'
    · linarith
    · linarith
  · rw [h]; ring
  · by_contra hc; push Not at hc; nlinarith
  · nlinarith

/-! The card's house bond, in exact fractions: face 1000, coupon 60, five annual payments.
A yield of 5% is `1/20`, so `1 + y = 21/20`. -/

-- At the 6% coupon rate the price is the face exactly: par, 1,000.
example : ∑ t ∈ Icc 1 5, (60 : ℚ) / (1 + 6 / 100) ^ t + 1000 / (1 + 6 / 100) ^ 5 = 1000 := by
  simp [Finset.sum_Icc_succ_top]
  norm_num

-- With no discounting at all (yield 0) the payments just add up: 1,300.
example : ∑ t ∈ Icc 1 5, (60 : ℚ) / (1 + 0) ^ t + 1000 / (1 + 0) ^ 5 = 1300 := by
  simp [Finset.sum_Icc_succ_top]
  norm_num

-- At 5% the price is within half a cent of $1,043.29.
example : (208657 / 200 : ℚ) ≤ ∑ t ∈ Icc 1 5, (60 : ℚ) / (21 / 20) ^ t + 1000 / (21 / 20) ^ 5 ∧
    ∑ t ∈ Icc 1 5, (60 : ℚ) / (21 / 20) ^ t + 1000 / (21 / 20) ^ 5 < 208659 / 200 := by
  simp [Finset.sum_Icc_succ_top]
  norm_num

-- The premium: the price is the face plus 10 a year times the five-year annuity factor.
example : ∑ t ∈ Icc 1 5, (60 : ℚ) / (21 / 20) ^ t + 1000 / (21 / 20) ^ 5 =
    1000 + 10 * ((1 - (21 / 20 : ℚ) ^ (-(5 : ℤ))) / (1 / 20)) := by
  simp [Finset.sum_Icc_succ_top]
  norm_num

-- Spend it: the 5% price banked at 5%, with 60 paid out each year, leaves exactly 1,000.
example :
    let P : ℚ := ∑ t ∈ Icc 1 5, (60 : ℚ) / (21 / 20) ^ t + 1000 / (21 / 20) ^ 5
    ((((P * (21 / 20) - 60) * (21 / 20) - 60) * (21 / 20) - 60) * (21 / 20) - 60) * (21 / 20)
      - 60 = 1000 := by
  simp [Finset.sum_Icc_succ_top]
  norm_num

-- The yield typed as 5 instead of 0.05: within half a cent of $12.13.
example : (2425 / 200 : ℚ) ≤ ∑ t ∈ Icc 1 5, (60 : ℚ) / (1 + 5) ^ t + 1000 / (1 + 5) ^ 5 ∧
    ∑ t ∈ Icc 1 5, (60 : ℚ) / (1 + 5) ^ t + 1000 / (1 + 5) ^ 5 < 2427 / 200 := by
  simp [Finset.sum_Icc_succ_top]
  norm_num

-- Accrued interest for 184 days of a 365-day coupon year: within half a cent of $30.25.
example : (6049 / 200 : ℚ) ≤ 60 * (184 / 365) ∧ (60 : ℚ) * (184 / 365) < 6051 / 200 := by
  norm_num

#print axioms bond_price_closed_form
#print axioms bond_price_eq_face_add_excess_coupon
#print axioms bond_premium_par_discount
