-- Spread options: a spread call minus a spread put is worth the discounted forward gap minus the strike, the strike can take off at most its present value, and Kirk's formula at a zero strike is exactly Margrabe's.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF

open MeasureTheory ProbabilityTheory

/-- Margrabe's price of the exchange option (spread call with strike zero), written with
forwards: `e^{-rT} [F₁ N(d₁) - F₂ N(d₂)]` with ratio volatility
`σ = √(σ₁² - 2ρσ₁σ₂ + σ₂²)`, `d₁ = (ln(F₁/F₂) + σ²T/2)/(σ√T)` and `d₂ = d₁ - σ√T`.
`N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`. -/
noncomputable def margrabePrice (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) : ℝ :=
  let σ := Real.sqrt (σ₁ ^ 2 - 2 * ρ * σ₁ * σ₂ + σ₂ ^ 2)
  let d₁ := (Real.log (F₁ / F₂) + σ ^ 2 * T / 2) / (σ * Real.sqrt T)
  let d₂ := d₁ - σ * Real.sqrt T
  Real.exp (-r * T) * (F₁ * cdf (gaussianReal 0 1) d₁ - F₂ * cdf (gaussianReal 0 1) d₂)

/-- Kirk's approximation to the spread call with strike `K`, as on the card:
`e^{-rT} [F₁ N(d₁) - (F₂ + K) N(d₂)]` with weight `w = F₂/(F₂ + K)`, Kirk volatility
`σ_K = √(σ₁² - 2ρσ₁σ₂w + σ₂²w²)`, `d₁ = (ln(F₁/(F₂+K)) + σ_K²T/2)/(σ_K√T)` and
`d₂ = d₁ - σ_K√T`. -/
noncomputable def kirkPrice (r T F₁ F₂ σ₁ σ₂ ρ K : ℝ) : ℝ :=
  let w := F₂ / (F₂ + K)
  let σK := Real.sqrt (σ₁ ^ 2 - 2 * ρ * σ₁ * σ₂ * w + σ₂ ^ 2 * w ^ 2)
  let d₁ := (Real.log (F₁ / (F₂ + K)) + σK ^ 2 * T / 2) / (σK * Real.sqrt T)
  let d₂ := d₁ - σK * Real.sqrt T
  Real.exp (-r * T) * (F₁ * cdf (gaussianReal 0 1) d₁ - (F₂ + K) * cdf (gaussianReal 0 1) d₂)

/-- Spread put-call parity: the spread call minus the spread put on the same strike pays
`S₁ - S₂ - K` in every outcome, so today `C - P = e^{-rT}(F₁ - F₂ - K)`, where each forward
`Fᵢ` is the pricing-world average of share `i`'s final price. Here `μ` is the pricing-world
joint law of the two final prices `(S₁, S₂)`, `r` the bank rate and `T` the time to expiry;
no model for the joint law is needed beyond both prices having an average. -/
theorem spread_call_sub_spread_put_eq_discounted_forward_gap
    (μ : Measure (ℝ × ℝ)) [IsProbabilityMeasure μ] (r T K F₁ F₂ : ℝ)
    (h₁ : Integrable (fun p : ℝ × ℝ => p.1) μ) (h₂ : Integrable (fun p : ℝ × ℝ => p.2) μ)
    (hF₁ : ∫ p, p.1 ∂μ = F₁) (hF₂ : ∫ p, p.2 ∂μ = F₂) :
    Real.exp (-r * T) * ∫ p, max (p.1 - p.2 - K) 0 ∂μ -
        Real.exp (-r * T) * ∫ p, max (K - (p.1 - p.2)) 0 ∂μ =
      Real.exp (-r * T) * (F₁ - F₂ - K) := by
  have hd : Integrable (fun p : ℝ × ℝ => p.1 - p.2) μ := h₁.sub h₂
  have hdK : Integrable (fun p : ℝ × ℝ => p.1 - p.2 - K) μ := hd.sub (integrable_const K)
  have hKd : Integrable (fun p : ℝ × ℝ => K - (p.1 - p.2)) μ := (integrable_const K).sub hd
  have hc : Integrable (fun p : ℝ × ℝ => max (p.1 - p.2 - K) 0) μ := hdK.pos_part
  have hp : Integrable (fun p : ℝ × ℝ => max (K - (p.1 - p.2)) 0) μ := hKd.pos_part
  rw [← mul_sub, ← integral_sub hc hp]
  have hpt : (fun p : ℝ × ℝ => max (p.1 - p.2 - K) 0 - max (K - (p.1 - p.2)) 0) =
      fun p => p.1 - p.2 - K := by
    funext p
    rcases le_total 0 (p.1 - p.2 - K) with h | h
    · rw [max_eq_left h, max_eq_right (by linarith)]; ring
    · rw [max_eq_right h, max_eq_left (by linarith)]; ring
  rw [hpt, integral_sub hd (integrable_const K), integral_sub h₁ h₂, hF₁, hF₂,
    integral_const]
  simp

/-- A strike `K ≥ 0` lowers the spread call's price, but by no more than the strike's present
value: Margrabe's price (strike zero) minus `e^{-rT} K` is a floor on the spread call, and
Margrabe's price is a ceiling. Here `μ` is the pricing-world joint law of the two final
prices `(S₁, S₂)`. -/
theorem exchange_sub_pv_strike_le_spread_call_le_exchange
    (μ : Measure (ℝ × ℝ)) [IsProbabilityMeasure μ] (r T K : ℝ) (hK : 0 ≤ K)
    (h₁ : Integrable (fun p : ℝ × ℝ => p.1) μ) (h₂ : Integrable (fun p : ℝ × ℝ => p.2) μ) :
    Real.exp (-r * T) * ∫ p, max (p.1 - p.2) 0 ∂μ - Real.exp (-r * T) * K ≤
        Real.exp (-r * T) * ∫ p, max (p.1 - p.2 - K) 0 ∂μ ∧
      Real.exp (-r * T) * ∫ p, max (p.1 - p.2 - K) 0 ∂μ ≤
        Real.exp (-r * T) * ∫ p, max (p.1 - p.2) 0 ∂μ := by
  have he : 0 ≤ Real.exp (-r * T) := (Real.exp_pos _).le
  have hd : Integrable (fun p : ℝ × ℝ => p.1 - p.2) μ := h₁.sub h₂
  have hdK : Integrable (fun p : ℝ × ℝ => p.1 - p.2 - K) μ := hd.sub (integrable_const K)
  have hc : Integrable (fun p : ℝ × ℝ => max (p.1 - p.2 - K) 0) μ := hdK.pos_part
  have hx : Integrable (fun p : ℝ × ℝ => max (p.1 - p.2) 0) μ := hd.pos_part
  have hxK : Integrable (fun p : ℝ × ℝ => max (p.1 - p.2) 0 - K) μ :=
    hx.sub (integrable_const K)
  constructor
  · rw [← mul_sub]
    apply mul_le_mul_of_nonneg_left _ he
    have hK' : ∫ p, max (p.1 - p.2) 0 ∂μ - K = ∫ p, (max (p.1 - p.2) 0 - K) ∂μ := by
      rw [integral_sub hx (integrable_const K), integral_const]; simp
    rw [hK']
    apply integral_mono hxK hc
    intro p
    show max (p.1 - p.2) 0 - K ≤ max (p.1 - p.2 - K) 0
    rcases le_total 0 (p.1 - p.2) with h | h
    · rw [max_eq_left h]; exact le_max_left _ _
    · rw [max_eq_right h]; linarith [le_max_right (p.1 - p.2 - K) 0]
  · apply mul_le_mul_of_nonneg_left _ he
    apply integral_mono hc hx
    intro p
    exact max_le_max (by linarith) le_rfl

/-- At a zero strike the weight is `w = 1`, and Kirk's approximation is Margrabe's formula
exactly. The folded asset `F₂ + K = F₂` must be above zero. -/
theorem kirk_price_zero_strike_eq_margrabe (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₂ : 0 < F₂) :
    kirkPrice r T F₁ F₂ σ₁ σ₂ ρ 0 = margrabePrice r T F₁ F₂ σ₁ σ₂ ρ := by
  simp only [kirkPrice, margrabePrice, add_zero, div_self hF₂.ne', mul_one, one_pow]

-- The card's payoff chart, strike $5: spreads of -$10, $5 and $25 at expiry pay $0, $0 and $20.
example : max ((-10 : ℤ) - 5) 0 = 0 := by decide
example : max ((5 : ℤ) - 5) 0 = 0 := by decide
example : max ((25 : ℤ) - 5) 0 = 20 := by decide
-- Call payoff minus put payoff is the spread minus the strike, in every outcome shown.
example : max ((25 : ℤ) - 5) 0 - max (5 - 25) 0 = 25 - 5 := by decide
example : max ((-10 : ℤ) - 5) 0 - max (5 - (-10)) 0 = -10 - 5 := by decide

#print axioms spread_call_sub_spread_put_eq_discounted_forward_gap
#print axioms exchange_sub_pv_strike_le_spread_call_le_exchange
#print axioms kirk_price_zero_strike_eq_margrabe
