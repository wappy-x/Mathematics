-- Weather and carbon: heating minus cooling degree days is a plain sum of (65 - T), a capped call is a call spread, and a bankable allowance's forward is pinned by carry at spot grown at the interest rate.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Order.BigOperators.Group.Finset

/-- One day with average temperature `A`: heating degree days minus cooling degree days is
`65 - A`, whatever the day's temperature. -/
theorem hdd_sub_cdd (A : ℝ) : max (65 - A) 0 - max (A - 65) 0 = 65 - A := by
  rcases le_total A 65 with h | h
  · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring

/-- Any set of days: the HDD index minus the CDD index is the sum of `65 - A_d`. -/
theorem hdd_index_sub_cdd_index {ι : Type*} (s : Finset ι) (A : ι → ℝ) :
    ∑ d ∈ s, max (65 - A d) 0 - ∑ d ∈ s, max (A d - 65) 0 = ∑ d ∈ s, (65 - A d) := by
  rw [← Finset.sum_sub_distrib]
  exact Finset.sum_congr rfl (fun d _ => hdd_sub_cdd (A d))

/-- A call capped at `L ≥ 0` degree days above the strike `K` is a call bought at `K` minus a
call sold at `K + L`, for every index value `X`. -/
theorem capped_call_eq_call_spread (X K L : ℝ) (hL : 0 ≤ L) :
    min (max (X - K) 0) L = max (X - K) 0 - max (X - K - L) 0 := by
  rcases le_total X K with h1 | h1
  · rw [max_eq_right (by linarith), max_eq_right (by linarith), min_eq_left hL]; ring
  · rcases le_total (X - K) L with h2 | h2
    · rw [max_eq_left (by linarith), max_eq_right (by linarith), min_eq_left h2]; ring
    · rw [max_eq_left (by linarith), max_eq_left (by linarith), min_eq_right h2]; ring

/-- At a forward quote `q`, the carry trade (borrow `S`, buy the allowance, bank it, deliver it,
repay `S e^{rT}`) earns `q - S e^{rT}`, and the reverse trade (sell a held allowance, deposit
the cash, buy it back through the forward) earns `S e^{rT} - q`. If neither trade makes money,
the forward is `S e^{rT}`. -/
theorem allowance_forward_pinned_by_carry (S r T q : ℝ)
    (hcarry : q - S * Real.exp (r * T) ≤ 0) (hreverse : S * Real.exp (r * T) - q ≤ 0) :
    q = S * Real.exp (r * T) := by
  linarith

/-- Banking for `T₁` years and then `T₂` more gives the `T₁ + T₂` forward. -/
theorem carry_compounds (S r T₁ T₂ : ℝ) :
    S * Real.exp (r * T₁) * Real.exp (r * T₂) = S * Real.exp (r * (T₁ + T₂)) := by
  rw [mul_assoc, ← Real.exp_add, mul_add]

/-- Continuous compounding beats simple interest: `70 × 1.03 = 72.10` lies below `70 e^{0.03}`. -/
theorem simple_interest_undershoots : (70 : ℝ) * 1.03 = 72.1 ∧ (70 : ℝ) * 1.03 < 70 * Real.exp 0.03 := by
  have h := Real.add_one_lt_exp (show (0.03 : ℝ) ≠ 0 by norm_num)
  constructor
  · norm_num
  · linarith

-- The week averaging 58, 62, 67, 71, 64, 55 and 60°F scores 26 HDD and 8 CDD, and 7 × 65 minus the sum of the averages is 18.
example : (([58, 62, 67, 71, 64, 55, 60] : List ℤ).map (fun a => max (65 - a) 0)).sum = 26 ∧
    (([58, 62, 67, 71, 64, 55, 60] : List ℤ).map (fun a => max (a - 65) 0)).sum = 8 ∧
    7 * 65 - ([58, 62, 67, 71, 64, 55, 60] : List ℤ).sum = 18 := by decide

-- A day with high 72 and low 52 averages 62°F and scores 3 HDD.
example : ((72 + 52) / 2 : ℚ) = 62 ∧ max (65 - (72 + 52) / 2 : ℚ) 0 = 3 := by norm_num

-- The cap is 2,000,000 / 5,000 = 400 degree days, and the payoff chart's points from 2,600 to 3,600.
example : (2000000 : ℚ) / 5000 = 400 ∧
    ([2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600] : List ℤ).map
      (fun x => 5000 * min (max (x - 3000) 0) 400) =
      [0, 0, 0, 0, 0, 500000, 1000000, 1500000, 2000000, 2000000, 2000000] := by
  constructor
  · norm_num
  · decide

#print axioms hdd_sub_cdd
#print axioms hdd_index_sub_cdd_index
#print axioms capped_call_eq_call_spread
#print axioms allowance_forward_pinned_by_carry
#print axioms carry_compounds
#print axioms simple_interest_undershoots
