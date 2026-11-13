-- Model risk: two volatility paths with the same total variance give the same one-year price law and so the same call at every strike, and a mid-year split exists only while the first half stays under the sqrt 2 wall.
import Mathlib.Probability.Distributions.Gaussian.Real

open MeasureTheory ProbabilityTheory

/-- A one-year call sees only where Acme finishes. Desk B runs volatility `σ₁` for the first
half-year and `σ₂` for the second; desk A runs one volatility `σA` for the whole year. In the
pricing world each half's log-move is an independent bell curve with drift `(r - q - σ²/2)`
per year and variance `σ²` per year, so desk B's one-year log-move has the law of the
convolution of the two halves. If the two halves' variances add up to desk A's year,
`σ₁² T/2 + σ₂² T/2 = σA² T`, then both desks give the same discounted call price
`e^{-rT} E[(S e^Y - K)⁺]` at every strike `K`: the fit to one-expiry quotes cannot tell them apart. -/
theorem equal_total_variance_gives_equal_call_prices
    (S K r q σ₁ σ₂ σA T : ℝ) (hT : 0 ≤ T)
    (hvar : σ₁ ^ 2 * (T / 2) + σ₂ ^ 2 * (T / 2) = σA ^ 2 * T) :
    Real.exp (-r * T) * ∫ y, max (S * Real.exp y - K) 0 ∂
        ((gaussianReal ((r - q - σ₁ ^ 2 / 2) * (T / 2)) (σ₁ ^ 2 * (T / 2)).toNNReal) ∗
          (gaussianReal ((r - q - σ₂ ^ 2 / 2) * (T / 2)) (σ₂ ^ 2 * (T / 2)).toNNReal))
      = Real.exp (-r * T) * ∫ y, max (S * Real.exp y - K) 0 ∂
        (gaussianReal ((r - q - σA ^ 2 / 2) * T) (σA ^ 2 * T).toNNReal) := by
  rw [gaussianReal_conv_gaussianReal]
  have hm : (r - q - σ₁ ^ 2 / 2) * (T / 2) + (r - q - σ₂ ^ 2 / 2) * (T / 2)
      = (r - q - σA ^ 2 / 2) * T := by linarith
  have hv : (σ₁ ^ 2 * (T / 2)).toNNReal + (σ₂ ^ 2 * (T / 2)).toNNReal = (σA ^ 2 * T).toNNReal := by
    rw [← Real.toNNReal_add (by positivity) (by positivity), hvar]
  rw [hm, hv]

/-- The calendar wall. With both half-years of length `τ` and the year's variance fixed at
`σA² · 2τ`, a second-half volatility that completes the year exists exactly when the first
half's volatility is at most `σA · √2`; past that the second half would need negative variance. -/
theorem second_half_exists_iff_below_wall
    (σ₁ σA τ : ℝ) (hτ : 0 < τ) (h₁ : 0 ≤ σ₁) (hA : 0 ≤ σA) :
    (∃ σ₂ : ℝ, σ₁ ^ 2 * τ + σ₂ ^ 2 * τ = σA ^ 2 * (2 * τ)) ↔ σ₁ ≤ σA * Real.sqrt 2 := by
  constructor
  · rintro ⟨σ₂, h⟩
    have h2 : σ₁ ^ 2 ≤ σA ^ 2 * 2 := by nlinarith [sq_nonneg σ₂]
    have hs : (σA * Real.sqrt 2) ^ 2 = σA ^ 2 * 2 := by
      rw [mul_pow, Real.sq_sqrt (by norm_num)]
    have hnn : 0 ≤ σA * Real.sqrt 2 := by positivity
    nlinarith [hs, hnn]
  · intro h
    refine ⟨Real.sqrt (σA ^ 2 * 2 - σ₁ ^ 2), ?_⟩
    have hs : (σA * Real.sqrt 2) ^ 2 = σA ^ 2 * 2 := by
      rw [mul_pow, Real.sq_sqrt (by norm_num)]
    have h2 : σ₁ ^ 2 ≤ σA ^ 2 * 2 := by
      rw [← hs]; exact pow_le_pow_left₀ h₁ h 2
    rw [Real.sq_sqrt (by linarith)]
    ring

/-- Volatilities do not add over time. Splitting a year at `σA` into halves whose volatilities
average to `σA` (`σ₁ + σ₂ = 2 σA`) with `σ₁ ≠ σA` puts strictly more variance into the year than
`σA² T`, so it cannot reproduce the one-year quotes. -/
theorem subtracting_volatilities_overshoots_variance
    (σ₁ σ₂ σA T : ℝ) (hT : 0 < T) (hsum : σ₁ + σ₂ = 2 * σA) (hne : σ₁ ≠ σA) :
    σA ^ 2 * T < σ₁ ^ 2 * (T / 2) + σ₂ ^ 2 * (T / 2) := by
  have hd : σ₁ - σA ≠ 0 := sub_ne_zero.mpr hne
  have hpos : 0 < (σ₁ - σA) ^ 2 := by positivity
  have h2 : σ₂ = 2 * σA - σ₁ := by linarith
  subst h2
  nlinarith [mul_pos hpos hT]

-- Worked numbers: desk A's year of variance at 20%.
example : ((1 : ℚ) / 5) ^ 2 * 1 = 1 / 25 := by norm_num
-- Desk B's first half at 10%.
example : ((1 : ℚ) / 10) ^ 2 * (1 / 2) = 1 / 200 := by norm_num
-- What the second half must supply.
example : (1 : ℚ) / 25 - 1 / 200 = 7 / 200 := by norm_num
-- Desk B's split: 10%, then √(7/100) (26.4575%), totals desk A's year exactly.
example : ((1 : ℝ) / 10) ^ 2 * (1 / 2) + (Real.sqrt (7 / 100)) ^ 2 * (1 / 2) = ((1 : ℝ) / 5) ^ 2 * 1 := by
  rw [Real.sq_sqrt (by norm_num)]; norm_num
-- Family's last point: 26% first half leaves √(31/2500) (11.1355%) for the second.
example : ((26 : ℚ) / 100) ^ 2 * (1 / 2) + (31 / 2500) * (1 / 2) = ((1 : ℚ) / 5) ^ 2 * 1 := by norm_num
-- Thursday's 28.01% is under the wall 20% · √2; Friday's 28.81% is past it.
example : ((2801 : ℚ) / 10000) ^ 2 < 2 * ((1 : ℚ) / 5) ^ 2 := by norm_num
example : 2 * ((1 : ℚ) / 5) ^ 2 < ((2881 : ℚ) / 10000) ^ 2 := by norm_num

#print axioms equal_total_variance_gives_equal_call_prices
#print axioms second_half_exists_iff_below_wall
#print axioms subtracting_volatilities_overshoots_variance
