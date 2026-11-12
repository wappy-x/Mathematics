-- Put-call parity: if prices add up (two packages paying the same cost the same), a call minus a put at one strike costs the prepaid share minus the discounted strike, whatever the share does.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.Algebra.Module.Pi
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-!
How the card's setting is written here.

* A payoff is a function `ℝ → ℝ`: what a ticket pays on expiry day, given the share's
  price `S_T` on that day. The call pays `max (S_T - K) 0`, the put `max (K - S_T) 0`.
  Both are European: the payoff depends only on the one expiry-day price.
* `price` gives today's price of every payoff. The card's one market assumption, that two
  packages paying the same on expiry day cost the same today and that prices of packages
  add up ("free money gets taken", one rate for borrowing and lending, short selling
  allowed), is the statement that `price` is a linear map.
* One dollar paid on expiry day (the cash leg) costs `exp (-r * T)` today.
* One whole share delivered on expiry day (the prepaid share, dividends reinvested at
  yield `q`) costs `S * exp (-q * T)` today.
No model of how the share price moves appears, and no volatility.
-/

/-- Put-call parity. Under any pricing rule where packages that pay the same cost the same
and prices add up, a European call minus a European put on the same share, at the same
strike `K` and expiry, costs exactly the prepaid share minus the discounted strike:
`C - P = S e^{-qT} - K e^{-rT}`. Nothing about how jumpy the share is enters. -/
theorem call_minus_put_eq_prepaid_share_minus_discounted_strike
    (price : (ℝ → ℝ) →ₗ[ℝ] ℝ) (S K r q T : ℝ)
    (h_cash : price (fun _ => 1) = Real.exp (-r * T))
    (h_share : price (fun x => x) = S * Real.exp (-q * T)) :
    price (fun x => max (x - K) 0) - price (fun x => max (K - x) 0)
      = S * Real.exp (-q * T) - K * Real.exp (-r * T) := by
  have hfun : (fun x : ℝ => max (x - K) 0) - (fun x => max (K - x) 0)
      = (fun x : ℝ => x) - K • (fun _ : ℝ => (1 : ℝ)) := by
    funext x
    simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul, mul_one]
    rcases le_total x K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  rw [← map_sub, hfun, map_sub, map_smul, h_cash, h_share, smul_eq_mul]

/-- Step 1 of the card: on expiry day, a call bought minus a put sold at the same strike
pays exactly what a forward pays, `S_T - K`, at every share price. -/
theorem call_payoff_sub_put_payoff (K x : ℝ) :
    max (x - K) 0 - max (K - x) 0 = x - K := by
  rcases le_total x K with h | h
  · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
  · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring

/-- The forward form: with the forward price `F = S e^{(r-q)T}`, the parity gap is the
forward's lead over the strike, discounted back: `S e^{-qT} - K e^{-rT} = e^{-rT} (F - K)`. -/
theorem parity_gap_eq_discounted_forward_minus_strike (S K r q T : ℝ) :
    S * Real.exp (-q * T) - K * Real.exp (-r * T)
      = Real.exp (-r * T) * (S * Real.exp ((r - q) * T) - K) := by
  have h : Real.exp (-q * T) = Real.exp (-r * T) * Real.exp ((r - q) * T) := by
    rw [← Real.exp_add]; ring_nf
  rw [h]; ring

-- The card's whole-number payoff checks, strike 100.
-- At 60: long call 0, short put -40, sum -40, and 60 - 100 = -40.
example : max ((60 : ℤ) - 100) 0 - max (100 - 60) 0 = 60 - 100 := by norm_num
-- At 140: long call 40, short put 0, sum 40, and 140 - 100 = 40.
example : max ((140 : ℤ) - 100) 0 - max (100 - 140) 0 = 140 - 100 := by norm_num
-- At 80 and 120: -20 and 20.
example : max ((80 : ℤ) - 100) 0 - max (100 - 80) 0 = -20 := by norm_num
example : max ((120 : ℤ) - 100) 0 - max (100 - 120) 0 = 20 := by norm_num
-- The two boxes at 60 and 140: call plus cash 100 equals put plus one share, the larger of the two.
example : max ((60 : ℤ) - 100) 0 + 100 = max (100 - 60) 0 + 60 := by norm_num
example : max ((140 : ℤ) - 100) 0 + 100 = max (100 - 140) 0 + 140 := by norm_num

#print axioms call_minus_put_eq_prepaid_share_minus_discounted_strike
#print axioms call_payoff_sub_put_payoff
#print axioms parity_gap_eq_discounted_forward_minus_strike
