-- Payoffs: a call minus a put at the same strike pays exactly what a forward pays, a long call bought for a positive premium breaks even only at strike plus premium, and a straddle pays the distance from the strike.
import Mathlib.Algebra.Order.Group.PosPart
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

/-- Call minus put is a forward: for any expiry price `S` and strike `K`, neither negative,
the call payoff `(S - K)⁺` minus the put payoff `(K - S)⁺` equals the forward payoff `S - K`. -/
theorem call_payoff_sub_put_payoff_eq_forward (S K : ℝ) (hS : 0 ≤ S) (hK : 0 ≤ K) :
    (S - K)⁺ - (K - S)⁺ = S - K := by
  rcases le_total S K with h | h
  · rw [posPart_eq_zero.mpr (by linarith), posPart_eq_self.mpr (by linarith)]; ring
  · rw [posPart_eq_self.mpr (by linarith), posPart_eq_zero.mpr (by linarith)]; ring

/-- Break-even of a long call: if the call cost a positive premium `V₀`, its profit at expiry,
`(S - K)⁺ - V₀`, is zero at exactly one price, `S = K + V₀`. -/
theorem long_call_break_even_iff (S K V₀ : ℝ) (hS : 0 ≤ S) (hK : 0 ≤ K) (hV : 0 < V₀) :
    (S - K)⁺ - V₀ = 0 ↔ S = K + V₀ := by
  rcases le_total S K with h | h
  · rw [posPart_eq_zero.mpr (by linarith)]
    constructor
    · intro h'; linarith
    · intro h'; linarith
  · rw [posPart_eq_self.mpr (by linarith)]
    constructor
    · intro h'; linarith
    · intro h'; linarith

/-- A straddle (one call and one put at the same strike) pays the distance from the strike,
`|S - K|`, and if it cost a positive amount `C`, its profit is zero exactly at `K - C` and `K + C`. -/
theorem straddle_payoff_and_break_evens (S K C : ℝ) (hS : 0 ≤ S) (hK : 0 ≤ K) (hC : 0 < C) :
    (S - K)⁺ + (K - S)⁺ = |S - K| ∧
      ((S - K)⁺ + (K - S)⁺ - C = 0 ↔ S = K - C ∨ S = K + C) := by
  have key : (S - K)⁺ + (K - S)⁺ = |S - K| := by
    rcases le_total S K with h | h
    · rw [posPart_eq_zero.mpr (by linarith), posPart_eq_self.mpr (by linarith),
        abs_of_nonpos (by linarith)]; ring
    · rw [posPart_eq_self.mpr (by linarith), posPart_eq_zero.mpr (by linarith),
        abs_of_nonneg (by linarith)]; ring
  refine ⟨key, ?_⟩
  rw [key]
  rcases le_total S K with h | h
  · rw [abs_of_nonpos (by linarith)]
    constructor
    · intro h'; left; linarith
    · rintro (h' | h') <;> linarith
  · rw [abs_of_nonneg (by linarith)]
    constructor
    · intro h'; right; linarith
    · rintro (h' | h') <;> linarith

-- The card's whole-dollar worked numbers, strike 100.
-- Call payoff at 90, 110 and 140.
example : ((90 : ℝ) - 100)⁺ = 0 := by norm_num [posPart]
example : ((110 : ℝ) - 100)⁺ = 10 := by norm_num [posPart]
example : ((140 : ℝ) - 100)⁺ = 40 := by norm_num [posPart]
-- Put payoff at 90.
example : ((100 : ℝ) - 90)⁺ = 10 := by norm_num [posPart]
-- Call minus put at 90 is -10, the forward's payoff.
example : ((90 : ℝ) - 100)⁺ - ((100 : ℝ) - 90)⁺ = -10 := by norm_num [posPart]
-- Call minus put at 120 is 20.
example : ((120 : ℝ) - 100)⁺ - ((100 : ℝ) - 120)⁺ = 20 := by norm_num [posPart]

#print axioms call_payoff_sub_put_payoff_eq_forward
#print axioms long_call_break_even_iff
#print axioms straddle_payoff_and_break_evens
