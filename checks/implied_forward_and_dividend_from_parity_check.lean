-- Implied forward and dividend from parity: put-call parity solved backwards gives the forward from one call-put pair, the dividend yield from the forward, a unique answer whenever the put is cheaper than the call plus the discounted strike, and the rate from two strikes.
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open Real

/-- One strike, rate given. If the call and put at strike `K` obey put-call parity
`C - P = e^(-rT) (F - K)` and the forward obeys cash and carry `F = S e^((r-q)T)`,
with a positive share price and a positive time to expiry, then the forward is
`F = K + (C - P) e^(rT)` and the dividend yield is `q = r - ln(F/S)/T`. -/
theorem implied_forward_and_yield_from_parity
    (S K C P r q T F : ℝ) (hS : 0 < S) (hT : 0 < T)
    (hparity : C - P = exp (-r * T) * (F - K))
    (hcarry : F = S * exp ((r - q) * T)) :
    F = K + (C - P) * exp (r * T) ∧ q = r - log (F / S) / T := by
  have hE : exp (-r * T) * exp (r * T) = 1 := by
    rw [← Real.exp_add]; simp
  refine ⟨?_, ?_⟩
  · rw [hparity]
    have : exp (-r * T) * (F - K) * exp (r * T) = (F - K) * (exp (-r * T) * exp (r * T)) := by ring
    rw [this, hE]; ring
  · have hFS : F / S = exp ((r - q) * T) := by
      rw [hcarry]; field_simp
    rw [hFS, Real.log_exp]
    field_simp
    ring

/-- An answer exists and it is the only one. When the put costs less than the call
plus the strike's value today, `C - P > -K e^(-rT)`, there is exactly one forward `F`
and one dividend yield `q` that make put-call parity and cash and carry both hold. -/
theorem implied_forward_and_yield_exists_unique
    (S K C P r T : ℝ) (hS : 0 < S) (hT : 0 < T)
    (hnoarb : -K * exp (-r * T) < C - P) :
    ∃! Fq : ℝ × ℝ, C - P = exp (-r * T) * (Fq.1 - K) ∧
      Fq.1 = S * exp ((r - Fq.2) * T) := by
  have hE : exp (-r * T) * exp (r * T) = 1 := by
    rw [← Real.exp_add]; simp
  have hEpos : 0 < exp (r * T) := Real.exp_pos _
  set F0 := K + (C - P) * exp (r * T) with hF0
  have hF0pos : 0 < F0 := by
    have h1 : -K * exp (-r * T) * exp (r * T) < (C - P) * exp (r * T) :=
      mul_lt_mul_of_pos_right hnoarb hEpos
    have h2 : -K * exp (-r * T) * exp (r * T) = -K := by
      rw [mul_assoc, hE]; ring
    rw [h2] at h1
    rw [hF0]; linarith
  refine ⟨(F0, r - log (F0 / S) / T), ⟨?_, ?_⟩, ?_⟩
  · simp only
    rw [hF0]
    have : exp (-r * T) * (K + (C - P) * exp (r * T) - K)
        = (C - P) * (exp (-r * T) * exp (r * T)) := by ring
    rw [this, hE]; ring
  · simp only
    have : (r - (r - log (F0 / S) / T)) * T = log (F0 / S) := by
      field_simp; ring
    rw [this, Real.exp_log (div_pos hF0pos hS)]
    field_simp
  · rintro ⟨F, q⟩ ⟨hpar, hcar⟩
    simp only at hpar hcar
    obtain ⟨h1, h2⟩ := implied_forward_and_yield_from_parity S K C P r q T F hS hT hpar hcar
    have hF : F = F0 := by rw [h1]
    subst hF
    rw [Prod.mk.injEq]
    exact ⟨rfl, h2⟩

/-- Two strikes, no rate given: the box. If the call-minus-put gaps at strikes
`K₁ < K₂` both obey parity, `g₁ = e^(-rT)(F - K₁)` and `g₂ = e^(-rT)(F - K₂)`, then the
discount factor is `D = (g₁ - g₂)/(K₂ - K₁)`, the rate is `r = -ln D / T`, and the
forward is `F = K₁ + g₁ / D`. -/
theorem implied_rate_and_forward_from_box
    (K₁ K₂ g₁ g₂ r T F : ℝ) (hT : 0 < T) (hK : K₁ < K₂)
    (h₁ : g₁ = exp (-r * T) * (F - K₁))
    (h₂ : g₂ = exp (-r * T) * (F - K₂)) :
    exp (-r * T) = (g₁ - g₂) / (K₂ - K₁) ∧
      r = -log ((g₁ - g₂) / (K₂ - K₁)) / T ∧
      F = K₁ + g₁ / ((g₁ - g₂) / (K₂ - K₁)) := by
  have hEpos : 0 < exp (-r * T) := Real.exp_pos _
  have hKpos : 0 < K₂ - K₁ := sub_pos.mpr hK
  have hD : exp (-r * T) = (g₁ - g₂) / (K₂ - K₁) := by
    rw [h₁, h₂]
    field_simp
    ring
  refine ⟨hD, ?_, ?_⟩
  · rw [← hD, Real.log_exp]
    field_simp
  · rw [← hD, h₁]
    field_simp
    ring

#print axioms implied_forward_and_yield_from_parity
#print axioms implied_forward_and_yield_exists_unique
#print axioms implied_rate_and_forward_from_box
