-- The interest rate a forward implies: for any positive spot, forward and term, exactly one foreign rate makes covered interest parity hold, it is r_d - ln(F/S)/T, the basis read from the euro side equals the basis read from the dollar side, and the basis is negative exactly when the forward sits above the parity forward.
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open Real

/-- Parity run backwards. For any positive spot `S`, any positive forward `F`, any
positive term `T` and any dollar rate `r_d`, a euro rate `y` makes covered interest
parity `F = S e^((r_d - y)T)` hold if and only if `y = r_d - ln(F/S)/T`. So the
implied euro rate exists, it is the only one, and it is given by the closed form. -/
theorem implied_yield_exists_unique
    (S F T rd : ℝ) (hS : 0 < S) (hF : 0 < F) (hT : 0 < T) :
    ∀ y : ℝ, F = S * exp ((rd - y) * T) ↔ y = rd - log (F / S) / T := by
  intro y
  have key : F = S * exp ((rd - y) * T) ↔ (rd - y) * T = log (F / S) := by
    constructor
    · intro h
      rw [h, mul_div_cancel_left₀ _ hS.ne', log_exp]
    · intro h
      rw [h, exp_log (div_pos hF hS)]
      field_simp
  rw [key]
  constructor
  · intro h
    rw [← h]
    field_simp
    ring
  · intro h
    rw [h]
    field_simp
    ring

/-- The two readings of the basis are one number. With the implied euro rate
`y_f = r_d - ln(F/S)/T` and the implied dollar rate `y_d = r_f + ln(F/S)/T`, the
basis from the euro side, `y_f - r_f`, equals the basis from the dollar side,
`r_d - y_d`, always. -/
theorem basis_euro_side_eq_dollar_side (S F T rd rf : ℝ) :
    (rd - log (F / S) / T) - rf = rd - (rf + log (F / S) / T) := by
  ring

/-- The sign of the basis. For positive spot, forward and term, the basis
`b = y_f - r_f` is negative (dollars dear through the FX market) exactly when the
quoted forward is above the parity forward `S e^((r_d - r_f)T)`, that is, when it
carries more points than fair. -/
theorem basis_neg_iff_forward_above_parity
    (S F T rd rf : ℝ) (hS : 0 < S) (hF : 0 < F) (hT : 0 < T) :
    (rd - log (F / S) / T) - rf < 0 ↔ S * exp ((rd - rf) * T) < F := by
  have h1 : (rd - log (F / S) / T) - rf < 0 ↔ (rd - rf) * T < log (F / S) := by
    rw [← lt_div_iff₀ hT]
    constructor <;> intro h <;> linarith
  rw [h1, ← exp_lt_exp, exp_log (div_pos hF hS), lt_div_iff₀ hS, mul_comm (exp _)]

-- The +249 pip screen: spot 1.10 plus 249 pips of 0.0001 is a forward of 1.1249.
example : (11 / 10 : ℚ) + 249 * (1 / 10000) = 11249 / 10000 := by norm_num

-- The house forward: spot 1.10 plus 222.21 pips is 1.122221.
example : (11 / 10 : ℚ) + (22221 / 100) * (1 / 10000) = 1122221 / 1000000 := by norm_num

-- The +195 pip screen: spot 1.10 plus 195 pips is 1.1195.
example : (11 / 10 : ℚ) + 195 * (1 / 10000) = 11195 / 10000 := by norm_num

-- No points at all, F = S = 1.10, one year, dollars at 5%: the implied euro rate is 5%.
example : (5 / 100 : ℝ) - log ((11 / 10) / (11 / 10)) / 1 = 5 / 100 := by norm_num

#print axioms implied_yield_exists_unique
#print axioms basis_euro_side_eq_dollar_side
#print axioms basis_neg_iff_forward_above_parity
