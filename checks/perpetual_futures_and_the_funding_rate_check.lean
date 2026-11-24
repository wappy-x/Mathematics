-- Perpetual futures: the fair perp price is κS/(κ − δ) when δ < κ, shown three ways: funding equals carry, a blend of forwards, and the geometric series of lumpy funding.
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecificLimits.Basic

open Real MeasureTheory Set

/-- The no-arbitrage price of a perpetual future. Funding is charged on the premium
`F - S` at a steady intensity `κ`, and the cost of carry `δ` is below `κ`. The hedge
(short one perp, hold `F / S` coins) is riskless and costs nothing, so the funding it
receives, `κ (F - S)` a year, must equal the carry on coins worth the perp's price,
`δ F`. That happens exactly when `F = κ / (κ - δ) * S`. -/
theorem perpetual_fair_price_iff_funding_eq_carry (S κ δ F : ℝ) (hδκ : δ < κ) :
    κ * (F - S) = δ * F ↔ F = κ / (κ - δ) * S := by
  have hne : κ - δ ≠ 0 := sub_ne_zero.mpr (ne_of_gt hδκ)
  rw [div_mul_eq_mul_div, eq_div_iff hne]
  constructor <;> intro h <;> linarith

/-- The second road: a blend of forwards. A forward for delivery in `u` years is worth
`S e^{δ u}`. Weighting each delivery date by `κ e^{-κ u}` and adding over all dates
gives the same price `κ / (κ - δ) * S`, as long as the carry `δ` is below `κ`. -/
theorem perpetual_price_as_blend_of_forwards (S κ δ : ℝ) (hδκ : δ < κ) :
    ∫ u in Ioi (0 : ℝ), κ * exp (-κ * u) * (S * exp (δ * u)) = κ / (κ - δ) * S := by
  have hfun : (fun u : ℝ => κ * exp (-κ * u) * (S * exp (δ * u)))
      = fun u : ℝ => (κ * S) * exp ((δ - κ) * u) := by
    funext u
    have : exp ((δ - κ) * u) = exp (-κ * u) * exp (δ * u) := by
      rw [← Real.exp_add]; ring_nf
    rw [this]; ring
  rw [hfun, integral_const_mul, integral_exp_mul_Ioi (by linarith) 0]
  have hne : κ - δ ≠ 0 := sub_ne_zero.mpr (ne_of_gt hδκ)
  have hne' : δ - κ ≠ 0 := sub_ne_zero.mpr (ne_of_lt hδκ)
  simp only [mul_zero, Real.exp_zero]
  field_simp
  ring

/-- The third road: funding in lumps. Charging a share `θ` of the premium once per period,
with one period's carry growth `g`, the perp is a forward for `n + 1` periods with weight
`θ (1 - θ)^n`. The series converges to `θ g / (1 - (1 - θ) g) * S` when `θ` is a share
(between 0 and 1), `g > 0`, and `(1 - θ) g < 1`. -/
theorem perpetual_price_lumpy_funding_series (S θ g : ℝ) (hθ0 : 0 ≤ θ) (hθ1 : θ ≤ 1)
    (hg : 0 < g) (hlt : (1 - θ) * g < 1) :
    HasSum (fun n : ℕ => θ * (1 - θ) ^ n * (S * g ^ (n + 1)))
      (θ * g / (1 - (1 - θ) * g) * S) := by
  have hr0 : 0 ≤ (1 - θ) * g := mul_nonneg (by linarith) hg.le
  have hne : 1 - (1 - θ) * g ≠ 0 := by linarith
  have h := (hasSum_geometric_of_lt_one hr0 hlt).mul_left (θ * g * S)
  convert h using 1
  · funext n
    rw [mul_pow, pow_succ]
    ring
  · field_simp

-- Funding intensity: three charges a day for 365 days is 1,095 a year.
example : 3 * 365 = 1095 := by decide

-- The fair perp at spot 60,000, carry 1/20 a year, intensity 1,095 lies between 60,002 and 60,003.
example : (60002 : ℚ) < 1095 / (1095 - 1 / 20) * 60000 ∧
    1095 / (1095 - 1 / 20) * 60000 < (60003 : ℚ) := by norm_num

-- At that price the funding paid a year equals the carry on the perp.
example : (1095 : ℚ) * (1095 / (1095 - 1 / 20) * 60000 - 60000) =
    1 / 20 * (1095 / (1095 - 1 / 20) * 60000) := by norm_num

-- A perp at 60,300 against spot 60,000: premium 300 / 60,000 = 1/200 (0.5%),
-- 300 USD per 8 hours, 900 USD a day, and 1,095/200 = 547.5% a year.
example : (60300 - 60000 : ℚ) / 60000 = 1 / 200 := by norm_num
example : (1 / 200 : ℚ) * 60000 = 300 ∧ 3 * (300 : ℚ) = 900 := by norm_num
example : (1 / 200 : ℚ) * 1095 = 1095 / 200 := by norm_num

-- Exchange clamp: premium 1/200 plus clamp(1/10000 - 1/200, -1/2000, 1/2000) is 9/2000 (0.45%),
-- and the BTCUSDT cap of 3/1000 (0.3%) then binds.
example : (1 / 200 : ℚ) + max (-1 / 2000) (min (1 / 2000) (1 / 10000 - 1 / 200)) = 9 / 2000 := by
  norm_num
example : max (-3 / 1000) (min (3 / 1000) (9 / 2000 : ℚ)) = 3 / 1000 := by norm_num

#print axioms perpetual_fair_price_iff_funding_eq_carry
#print axioms perpetual_price_as_blend_of_forwards
#print axioms perpetual_price_lumpy_funding_series
