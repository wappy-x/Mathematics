-- The credit default swap: bond plus protection is worth par at default exactly when the payout is the notional times one minus the recovery, premiums counted day by day equal the ACT/360 quarterly premiums, and the upfront is paid by the buyer exactly when the quoted spread is above the coupon.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

open Finset

/-! Notation, as on the card. `N` is the notional, `R` the recovery rate (the auction's
final price per dollar of face value), `s` the yearly spread as a fraction of `N`,
`c` the standard coupon, `A` the risky annuity, and `d i` the actual days in quarter `i`.
At a credit event the bond is worth `R * N`; the seller pays `p`.
ACT/360: quarter `i` costs `s * N * (d i / 360)`. -/

/-- Bond plus protection is worth its face value at default, and that fixes the payout:
a holder of `N` of face value whose bond is now worth `R * N` ends with exactly `N`
(par) if and only if the protection seller pays `N * (1 - R)`, the loss, not the recovery. -/
theorem bond_plus_protection_worth_par_iff_payout_is_loss (N R p : ℝ) :
    R * N + p = N ↔ p = N * (1 - R) := by
  constructor <;> intro h <;> linarith

/-- The day-by-day ledger agrees with the quarterly premiums: adding one day's fee
`s * N / 360` for every day of quarters `0, …, k - 1` gives the same total as the
ACT/360 premiums `s * N * (d i / 360)` of those quarters, whatever the day counts. -/
theorem daily_ledger_eq_act360_premiums (s N : ℝ) (d : ℕ → ℕ) (k : ℕ) :
    ∑ i ∈ range k, ∑ _j ∈ range (d i), s * N / 360 = ∑ i ∈ range k, s * N * ((d i : ℝ) / 360) := by
  refine sum_congr rfl (fun i _ => ?_)
  rw [sum_const, card_range, nsmul_eq_mul]
  ring

/-- Who pays the upfront `U = (s - c) * A * N`: with a positive notional and a positive
risky annuity, the buyer pays (`U > 0`) exactly when the quoted spread is above the
standard coupon; when the quote is below the coupon the seller pays (`U < 0`). -/
theorem upfront_paid_by_buyer_iff_spread_above_coupon (s c A N : ℝ) (hA : 0 < A) (hN : 0 < N) :
    (0 < (s - c) * A * N ↔ c < s) ∧ ((s - c) * A * N < 0 ↔ s < c) := by
  have hAN : 0 < A * N := mul_pos hA hN
  have e : (s - c) * A * N = (s - c) * (A * N) := by ring
  rw [e]
  constructor
  · constructor
    · intro h
      by_contra hc
      have hc' : s - c ≤ 0 := by linarith [not_lt.mp hc]
      nlinarith
    · intro h
      have : 0 < s - c := by linarith
      positivity
  · constructor
    · intro h
      by_contra hc
      have hc' : 0 ≤ s - c := by linarith [not_lt.mp hc]
      nlinarith
    · intro h
      have : s - c < 0 := by linarith
      nlinarith

/-! The card's worked numbers, exactly, in ℚ. 1 bp = 1/10000, so 120 bp = 120/10000. -/

-- Yearly fee: 120 bp on $10 million is $120,000; the idealised quarter is $30,000.
example : (120 / 10000 : ℚ) * 10000000 = 120000 := by norm_num
example : (120000 : ℚ) / 4 = 30000 := by norm_num
-- Quarter 20 Dec 2026 to 20 Mar 2027, 90 days, ACT/360: exactly $30,000.
example : (120 / 10000 : ℚ) * 10000000 * (90 / 360) = 30000 := by norm_num
-- A 92-day quarter: $30,666.67, exactly 92000/3. A 91-day quarter: 91000/3.
example : (120000 : ℚ) * 92 / 360 = 92000 / 3 := by norm_num
example : (120000 : ℚ) * 91 / 360 = 91000 / 3 := by norm_num
-- The first year has 90 + 92 + 92 + 91 = 365 days and costs $121,666.67 = 365000/3.
example : 90 + 92 + 92 + 91 = 365 := by decide
example : (120000 : ℚ) * 365 / 360 = 365000 / 3 := by norm_num
-- Five years from 20 Dec 2026 have 1826 days (2028 is a leap year): $608,666.67 = 1826000/3.
example : [90, 92, 92, 91, 91, 92, 92, 91, 90, 92, 92, 91, 90, 92, 92, 91, 90, 92, 92, 91].sum
    = 1826 := by decide
example : (120000 : ℚ) * 1826 / 360 = 1826000 / 3 := by norm_num
-- Nine quarters paid before the event on 19 May 2029: 821 days, $273,666.67 = 821000/3.
example : [90, 92, 92, 91, 91, 92, 92, 91, 90].sum = 821 := by decide
example : (120000 : ℚ) * 821 / 360 = 821000 / 3 := by norm_num
-- Accrued premium, 60 days from 20 Mar to 19 May 2029: $20,000.
example : (120000 : ℚ) * 60 / 360 = 20000 := by norm_num
-- Payout at 40% recovery: $6,000,000. Paying the recovery instead would give $4,000,000.
example : (10000000 : ℚ) * (1 - 40 / 100) = 6000000 := by norm_num
example : (10000000 : ℚ) * (40 / 100) = 4000000 := by norm_num
-- Physical delivery gives the same: par minus the cost of $10m of bonds at 40 cents.
example : (10000000 : ℚ) - 10000000 * 40 / 100 = 6000000 := by norm_num
-- Seller's premium income with accrued, $293,666.67, and the buyer's net gain, $5,706,333.33.
example : (821000 / 3 : ℚ) + 20000 = 881000 / 3 := by norm_num
example : (6000000 : ℚ) - 881000 / 3 = 17119000 / 3 := by norm_num
-- Toy auction: the five dealer midpoints average to 41.2 = 206/5 cents.
example : (((40 + 42) / 2 + (81 / 2 + 85 / 2) / 2 + (41 + 43) / 2 + (79 / 2 + 83 / 2) / 2
    + (40 + 42) / 2) / 5 : ℚ) = 206 / 5 := by norm_num
-- Bids from the top: 40 + 50 = 90 falls short of 150 ($ millions); adding 80 reaches 170,
-- so the bid at 40 is the last one needed and the final price is 40.
example : 40 + 50 < 150 ∧ 150 ≤ 40 + 50 + 80 := by decide
-- Lehman 2008: final price 8.625 cents, payout $9,137,500 per $10 million.
example : (10000000 : ℚ) * (1 - 8625 / 100000) = 9137500 := by norm_num
-- Mistakes: the spread charged each quarter is $120,000; 120 bp read as 12% is $300,000.
example : (120 / 10000 : ℚ) * 10000000 = 120000 := by norm_num
example : (12 / 100 : ℚ) * 10000000 / 4 = 300000 := by norm_num
-- Sensitivities: 1 bp moves the idealised quarterly premium by $250;
-- one point of recovery moves the payout by $100,000.
example : (1 / 10000 : ℚ) * 10000000 / 4 = 250 := by norm_num
example : (10000000 : ℚ) * (1 - 41 / 100) - 10000000 * (1 - 40 / 100) = -100000 := by norm_num
-- Payoff chart: at final prices 0, 10, …, 100 the payout in $ millions is 10, 9, …, 0.
example : (List.range 11).map (fun k => 10 - k) = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0] := by decide

#print axioms bond_plus_protection_worth_par_iff_payout_is_loss
#print axioms daily_ledger_eq_act360_premiums
#print axioms upfront_paid_by_buyer_iff_spread_above_coupon
