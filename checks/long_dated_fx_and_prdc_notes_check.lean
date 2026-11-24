-- Long-dated FX: the forward's variance rate adds up to the cubic V(T), the rates outweigh the spot past about 12.33 years, and each PRDC coupon is a block of calls.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

/-- With no mean reversion (`a = 0`, so each bond factor `B` is the time left `τ`), the forward's
variance rate `σS² + σd²τ² + σf²τ² + 2ρSd σS σd τ - 2ρSf σS σf τ - 2ρdf σd σf τ·τ`, added up over
the coupon's whole life `0 ≤ τ ≤ T`, is the total variance
`V(T) = σS² T + σS (ρSd σd - ρSf σf) T² + (σd² + σf² - 2ρdf σd σf) T³ / 3`. -/
theorem forward_total_variance_eq_cubic (σS σd σf ρSd ρSf ρdf T : ℝ) :
    ∫ τ in (0 : ℝ)..T,
        (σS ^ 2 + σd ^ 2 * τ ^ 2 + σf ^ 2 * τ ^ 2 + 2 * ρSd * σS * σd * τ
          - 2 * ρSf * σS * σf * τ - 2 * ρdf * σd * σf * τ * τ)
      = σS ^ 2 * T + σS * (ρSd * σd - ρSf * σf) * T ^ 2
          + (σd ^ 2 + σf ^ 2 - 2 * ρdf * σd * σf) * T ^ 3 / 3 := by
  have hd : ∀ x ∈ Set.uIcc (0 : ℝ) T, HasDerivAt
      (fun τ : ℝ => σS ^ 2 * τ + σS * (ρSd * σd - ρSf * σf) * τ ^ 2
          + (σd ^ 2 + σf ^ 2 - 2 * ρdf * σd * σf) * τ ^ 3 / 3)
      (σS ^ 2 + σd ^ 2 * x ^ 2 + σf ^ 2 * x ^ 2 + 2 * ρSd * σS * σd * x
          - 2 * ρSf * σS * σf * x - 2 * ρdf * σd * σf * x * x) x := by
    intro x _
    have h1 := (((hasDerivAt_id x).const_mul (σS ^ 2)).add
      ((hasDerivAt_pow 2 x).const_mul (σS * (ρSd * σd - ρSf * σf)))).add
      (((hasDerivAt_pow 3 x).const_mul (σd ^ 2 + σf ^ 2 - 2 * ρdf * σd * σf)).div_const 3)
    convert h1 using 1
    · rfl
    · push_cast; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd
    (by apply Continuous.intervalIntegrable; fun_prop)]
  ring

/-- The coupon `max(0, c_f S_T / S_0 - c_d)` is `g = c_f / S_0` calls on `S_T` struck at
`K = c_d S_0 / c_f`. -/
theorem prdc_coupon_eq_calls (S₀ c_f c_d S_T : ℝ) (hS₀ : 0 < S₀) (hc_f : 0 < c_f) :
    max 0 (c_f * S_T / S₀ - c_d) = c_f / S₀ * max 0 (S_T - c_d * S₀ / c_f) := by
  rw [mul_max_of_nonneg _ _ (le_of_lt (div_pos hc_f hS₀)), mul_zero]
  congr 1
  field_simp

/-- With the card's numbers (spot volatility 10%, both rate volatilities 1%, correlations
0.2, -0.2, 0.5), for a coupon `T > 0` years away the spot's term `σS² T` is less than the cross
term plus the rate term exactly when `T` is past the root `-6 + √336 ≈ 12.33` of
`T² + 12T - 300 = 0`. -/
theorem rates_outweigh_spot_iff (T : ℝ) (hT : 0 < T) :
    (1 / 10 : ℝ) ^ 2 * T
        < (1 / 10) * ((1 / 5) * (1 / 100) - (-1 / 5) * (1 / 100)) * T ^ 2
          + ((1 / 100) ^ 2 + (1 / 100) ^ 2 - 2 * (1 / 2) * (1 / 100) * (1 / 100)) * T ^ 3 / 3
      ↔ -6 + Real.sqrt 336 < T := by
  have key : (1 / 10 : ℝ) ^ 2 * T
        < (1 / 10) * ((1 / 5) * (1 / 100) - (-1 / 5) * (1 / 100)) * T ^ 2
          + ((1 / 100) ^ 2 + (1 / 100) ^ 2 - 2 * (1 / 2) * (1 / 100) * (1 / 100)) * T ^ 3 / 3
      ↔ 300 < T ^ 2 + 12 * T := by
    constructor
    · intro h
      by_contra hc
      push Not at hc
      nlinarith [mul_le_mul_of_nonneg_left hc hT.le]
    · intro h
      nlinarith [mul_lt_mul_of_pos_left h hT]
  rw [key, neg_add_lt_iff_lt_add, add_comm, Real.sqrt_lt' (by linarith)]
  constructor <;> intro h <;> nlinarith

-- V(10) = 0.100000 + 0.040000 + 0.033333 = 0.173333 = 13/75.
example : (1 / 10 : ℚ) ^ 2 * 10 + (1 / 10) * ((1 / 5) * (1 / 100) - (-1 / 5) * (1 / 100)) * 10 ^ 2
    + ((1 / 100) ^ 2 + (1 / 100) ^ 2 - 2 * (1 / 2) * (1 / 100) * (1 / 100)) * 10 ^ 3 / 3
    = 13 / 75 := by norm_num

-- V(30) = 0.30 + 0.36 + 0.90 = 1.56; the rates carry 1.26 of it.
example : (1 / 10 : ℚ) ^ 2 * 30 + (1 / 10) * ((1 / 5) * (1 / 100) - (-1 / 5) * (1 / 100)) * 30 ^ 2
    + ((1 / 100) ^ 2 + (1 / 100) ^ 2 - 2 * (1 / 2) * (1 / 100) * (1 / 100)) * 30 ^ 3 / 3
    = 39 / 25 := by norm_num

-- The strike K = 0.03 × 1.10 / 0.06 = 0.55, and the rate-differential variance is 0.0001.
example : (3 / 100 : ℚ) * (11 / 10) / (6 / 100) = 11 / 20 := by norm_num
example : ((1 / 100 : ℚ) ^ 2 + (1 / 100) ^ 2 - 2 * (1 / 2) * (1 / 100) * (1 / 100)) = 1 / 10000 := by
  norm_num

-- Coupons: 3% at S_T = 1.10, 3.6% at 1.21, zero at 0.55.
example : max 0 ((6 / 100 : ℚ) * (11 / 10) / (11 / 10) - 3 / 100) = 3 / 100 := by norm_num
example : max 0 ((6 / 100 : ℚ) * (121 / 100) / (11 / 10) - 3 / 100) = 9 / 250 := by norm_num
example : max 0 ((6 / 100 : ℚ) * (55 / 100) / (11 / 10) - 3 / 100) = 0 := by norm_num

#print axioms forward_total_variance_eq_cubic
#print axioms prdc_coupon_eq_calls
#print axioms rates_outweigh_spot_iff
