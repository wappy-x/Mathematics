-- Chooser options: when put-call parity holds on the choice date, the better of the call and the put equals the call plus e^(-q(T-τ)) puts struck at K' = K e^(-(r-q)(T-τ)), the put is picked exactly when the share is below K', and so the chooser's price today is the call's price plus that many puts expiring on the choice date.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Probability.Notation

open Real MeasureTheory

/-- The chooser split. On the choice date, τ years from today, the call and the put (same strike K,
same expiry T) are worth C and P, and Acme trades at S. If put-call parity holds on that date,
C - P = S e^(-q(T-τ)) - K e^(-r(T-τ)), then the dearer of the two legs is the call plus
e^(-q(T-τ)) units of a put payoff struck at K' = K e^(-(r-q)(T-τ)) that pays on the choice date:
max(C, P) = C + e^(-q(T-τ)) max(K' - S, 0). -/
theorem chooser_payoff_eq_call_add_put (C P S K r q T τ : ℝ)
    (hparity : C - P = S * exp (-q * (T - τ)) - K * exp (-r * (T - τ))) :
    max C P = C + exp (-q * (T - τ)) * max (K * exp (-(r - q) * (T - τ)) - S) 0 := by
  have he : 0 < exp (-q * (T - τ)) := exp_pos _
  have hk : K * exp (-(r - q) * (T - τ)) * exp (-q * (T - τ)) = K * exp (-r * (T - τ)) := by
    rw [mul_assoc, ← exp_add]; ring_nf
  have hPC : P - C = exp (-q * (T - τ)) * (K * exp (-(r - q) * (T - τ)) - S) := by
    linear_combination -hparity - hk
  rcases le_total (K * exp (-(r - q) * (T - τ)) - S) 0 with h | h
  · rw [max_eq_right h, mul_zero, add_zero]
    have : exp (-q * (T - τ)) * (K * exp (-(r - q) * (T - τ)) - S) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos he.le h
    exact max_eq_left (by linarith)
  · rw [max_eq_left h]
    have : 0 ≤ exp (-q * (T - τ)) * (K * exp (-(r - q) * (T - τ)) - S) := mul_nonneg he.le h
    rw [max_eq_right (by linarith)]
    linarith

/-- The critical price. Under the same parity, the put is the dearer leg on the choice date exactly
when the share is below K' = K e^(-(r-q)(T-τ)), not below the strike K. -/
theorem chooser_put_picked_iff_below_critical_price (C P S K r q T τ : ℝ)
    (hparity : C - P = S * exp (-q * (T - τ)) - K * exp (-r * (T - τ))) :
    C < P ↔ S < K * exp (-(r - q) * (T - τ)) := by
  have he : 0 < exp (-q * (T - τ)) := exp_pos _
  have hk : K * exp (-(r - q) * (T - τ)) * exp (-q * (T - τ)) = K * exp (-r * (T - τ)) := by
    rw [mul_assoc, ← exp_add]; ring_nf
  have hPC : P - C = exp (-q * (T - τ)) * (K * exp (-(r - q) * (T - τ)) - S) := by
    linear_combination -hparity - hk
  rw [← sub_pos, hPC, mul_pos_iff_of_pos_left he, sub_pos]

/-- Pricing today. In the pretend (risk-neutral) world μ, let the call, the put and the share on the
choice date be random amounts C, P and S, with the call and put prices finite (integrable) and parity
holding on every path. Then the chooser's price today, the discounted average e^(-rτ) E[max(C, P)],
equals the discounted average of the call plus e^(-q(T-τ)) times the price today of a put struck at
K' that expires on the choice date, e^(-rτ) E[max(K' - S, 0)]. -/
theorem chooser_price_eq_call_price_add_put_price
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (C P S : Ω → ℝ) (K r q T τ : ℝ)
    (hC : Integrable C μ) (hP : Integrable P μ)
    (hparity : ∀ ω, C ω - P ω = S ω * exp (-q * (T - τ)) - K * exp (-r * (T - τ))) :
    exp (-r * τ) * ∫ ω, max (C ω) (P ω) ∂μ
      = exp (-r * τ) * ∫ ω, C ω ∂μ
        + exp (-q * (T - τ)) * (exp (-r * τ) * ∫ ω, max (K * exp (-(r - q) * (T - τ)) - S ω) 0 ∂μ) := by
  have hpt : ∀ ω, max (C ω) (P ω)
      = C ω + exp (-q * (T - τ)) * max (K * exp (-(r - q) * (T - τ)) - S ω) 0 :=
    fun ω => chooser_payoff_eq_call_add_put (C ω) (P ω) (S ω) K r q T τ (hparity ω)
  have hint : Integrable (fun ω => exp (-q * (T - τ)) * max (K * exp (-(r - q) * (T - τ)) - S ω) 0) μ := by
    have h1 : Integrable (fun ω => max (C ω) (P ω) - C ω) μ := (hC.sup hP).sub hC
    refine h1.congr (Filter.Eventually.of_forall fun ω => ?_)
    simp only [hpt ω]; ring
  simp_rw [hpt]
  rw [integral_add hC hint, integral_const_mul]
  ring

#print axioms chooser_payoff_eq_call_add_put
#print axioms chooser_put_picked_iff_below_critical_price
#print axioms chooser_price_eq_call_price_add_put_price
