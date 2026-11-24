-- Gibson-Schwartz: when log spot at delivery is normal with the model's mean and variance, the futures price is the card's closed form; two futures' returns correlate strictly below one in absolute value; and the level absorbs the correlation term exactly.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Real MeasureTheory ProbabilityTheory

/-! ## The model's pieces

Spot `S`, today's net convenience yield `y`, interest `r`, the yield's level `α`, its speed
`κ`, spot volatility `σS`, yield volatility `σy`, correlation `ρ`, years to delivery `T`. -/

/-- `B(T) = (1 - e^(-κT))/κ`: the years of today's yield gap still felt by delivery. -/
noncomputable def gsB (κ T : ℝ) : ℝ := (1 - exp (-κ * T)) / κ

/-- `I₁(T) = (T - B(T))/κ`: the closed form of the integral of `B(u)` from `0` to `T`. -/
noncomputable def gsI1 (κ T : ℝ) : ℝ := (T - gsB κ T) / κ

/-- `I₂(T) = (T - 2B(T) + (1 - e^(-2κT))/(2κ))/κ²`: the closed form of the integral of `B(u)²`. -/
noncomputable def gsI2 (κ T : ℝ) : ℝ :=
  (T - 2 * gsB κ T + (1 - exp (-2 * κ * T)) / (2 * κ)) / κ ^ 2

/-- The card's futures formula:
`F(T) = S exp((r - α)T - (y - α)B(T) - ρ σS σy I₁(T) + ½ σy² I₂(T))`. -/
noncomputable def gsFutures (S y r α κ σS σy ρ T : ℝ) : ℝ :=
  S * exp ((r - α) * T - (y - α) * gsB κ T - ρ * σS * σy * gsI1 κ T
    + 1 / 2 * σy ^ 2 * gsI2 κ T)

/-- `σ_F(T)²` written through `b = B(T)`: `σS² - 2ρ σS σy b + σy² b²`. -/
noncomputable def gsFutVar (σS σy ρ b : ℝ) : ℝ :=
  σS ^ 2 - 2 * ρ * σS * σy * b + σy ^ 2 * b ^ 2

/-- `c(T₁, T₂)` written through `b₁ = B(T₁)`, `b₂ = B(T₂)`:
`(σS² - ρ σS σy (b₁ + b₂) + σy² b₁ b₂) / (σ_F(T₁) σ_F(T₂))`. -/
noncomputable def gsFutCorr (σS σy ρ b₁ b₂ : ℝ) : ℝ :=
  (σS ^ 2 - ρ * σS * σy * (b₁ + b₂) + σy ^ 2 * b₁ * b₂)
    / (√(gsFutVar σS σy ρ b₁) * √(gsFutVar σS σy ρ b₂))

theorem gs_int_yield (α y κ T : ℝ) (hκ : 0 < κ) :
    (∫ t in (0 : ℝ)..T, (α + (y - α) * exp (-κ * t))) = α * T + (y - α) * gsB κ T := by
  have hκ0 : κ ≠ 0 := hκ.ne'
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun t => α * t - (y - α) * exp (-κ * t) / κ)]
  · simp only [gsB, mul_zero, Real.exp_zero]
    field_simp
    ring
  · intro t _
    have h1 : HasDerivAt (fun t => -κ * t) (-κ) t := by
      simpa using (hasDerivAt_id t).const_mul (-κ)
    have h2 := (h1.exp.const_mul (y - α)).div_const κ
    have h3 : HasDerivAt (fun t => α * t - (y - α) * exp (-κ * t) / κ)
        (α * 1 - (y - α) * (exp (-κ * t) * -κ) / κ) t :=
      ((hasDerivAt_id' t).const_mul α).sub h2
    convert h3 using 1
    field_simp
    ring
  · exact (continuous_const.add (continuous_const.mul
      (Real.continuous_exp.comp (continuous_const.mul continuous_id)))).intervalIntegrable _ _

theorem gs_int_B (κ T : ℝ) (hκ : 0 < κ) :
    (∫ u in (0 : ℝ)..T, gsB κ u) = gsI1 κ T := by
  have hκ0 : κ ≠ 0 := hκ.ne'
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun u => (u + exp (-κ * u) / κ) / κ)]
  · simp only [gsI1, gsB, mul_zero, Real.exp_zero]
    field_simp
    ring
  · intro t _
    have h1 : HasDerivAt (fun t => -κ * t) (-κ) t := by
      simpa using (hasDerivAt_id t).const_mul (-κ)
    have h3 : HasDerivAt (fun u => (u + exp (-κ * u) / κ) / κ)
        ((1 + exp (-κ * t) * -κ / κ) / κ) t :=
      (((hasDerivAt_id' t).add (h1.exp.div_const κ))).div_const κ
    convert h3 using 1
    simp only [gsB]
    field_simp
    ring
  · exact (Continuous.div_const (continuous_const.sub
      (Real.continuous_exp.comp (continuous_const.mul continuous_id))) κ).intervalIntegrable _ _

theorem gs_int_B_sq (κ T : ℝ) (hκ : 0 < κ) :
    (∫ u in (0 : ℝ)..T, gsB κ u ^ 2) = gsI2 κ T := by
  have hκ0 : κ ≠ 0 := hκ.ne'
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun u => (u + 2 * exp (-κ * u) / κ - exp (-2 * κ * u) / (2 * κ)) / κ ^ 2)]
  · simp only [gsI2, gsB, mul_zero, Real.exp_zero]
    field_simp
    ring
  · intro t _
    have h1 : HasDerivAt (fun t => -κ * t) (-κ) t := by
      simpa using (hasDerivAt_id t).const_mul (-κ)
    have h2 : HasDerivAt (fun t => -2 * κ * t) (-2 * κ) t := by
      simpa using (hasDerivAt_id t).const_mul (-2 * κ)
    have h3 : HasDerivAt
        (fun u => (u + 2 * exp (-κ * u) / κ - exp (-2 * κ * u) / (2 * κ)) / κ ^ 2)
        ((1 + 2 * (exp (-κ * t) * -κ) / κ - exp (-2 * κ * t) * (-2 * κ) / (2 * κ)) / κ ^ 2) t :=
      ((((hasDerivAt_id' t).add ((h1.exp.const_mul 2).div_const κ))).sub
        (h2.exp.div_const (2 * κ))).div_const (κ ^ 2)
    convert h3 using 1
    have he : exp (-2 * κ * t) = exp (-κ * t) ^ 2 := by
      rw [← Real.exp_nat_mul]; ring_nf
    rw [he]
    simp only [gsB]
    field_simp
    ring
  · exact ((Continuous.div_const (continuous_const.sub
      (Real.continuous_exp.comp (continuous_const.mul continuous_id))) κ).pow 2).intervalIntegrable _ _

#print axioms gs_int_yield
#print axioms gs_int_B
#print axioms gs_int_B_sq

theorem gsFutVar_pos (σS σy ρ b : ℝ) (hσS : 0 < σS) (hρ : |ρ| < 1) :
    0 < gsFutVar σS σy ρ b := by
  have hρ2 : ρ ^ 2 < 1 := by rw [← sq_abs]; nlinarith [abs_nonneg ρ]
  have he : gsFutVar σS σy ρ b = (1 - ρ ^ 2) * σS ^ 2 + (ρ * σS - σy * b) ^ 2 := by
    unfold gsFutVar; ring
  rw [he]
  nlinarith [sq_nonneg (ρ * σS - σy * b), mul_pos (sub_pos.2 hρ2) (pow_pos hσS 2)]

#print axioms gsFutVar_pos

theorem gsFutCorr_abs_lt_one (σS σy ρ b₁ b₂ : ℝ) (hσS : 0 < σS) (hσy : 0 < σy)
    (hρ : |ρ| < 1) (hb : b₁ ≠ b₂) : |gsFutCorr σS σy ρ b₁ b₂| < 1 := by
  have h1 := gsFutVar_pos σS σy ρ b₁ hσS hρ
  have h2 := gsFutVar_pos σS σy ρ b₂ hσS hρ
  have hρ2 : ρ ^ 2 < 1 := by rw [← sq_abs]; nlinarith [abs_nonneg ρ]
  have key : (σS ^ 2 - ρ * σS * σy * (b₁ + b₂) + σy ^ 2 * b₁ * b₂) ^ 2
      < gsFutVar σS σy ρ b₁ * gsFutVar σS σy ρ b₂ := by
    have he : gsFutVar σS σy ρ b₁ * gsFutVar σS σy ρ b₂
        - (σS ^ 2 - ρ * σS * σy * (b₁ + b₂) + σy ^ 2 * b₁ * b₂) ^ 2
        = (1 - ρ ^ 2) * σS ^ 2 * σy ^ 2 * (b₁ - b₂) ^ 2 := by
      unfold gsFutVar; ring
    have hd : 0 < (b₁ - b₂) ^ 2 :=
      lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 (sub_ne_zero.2 hb)))
    have hp : 0 < (1 - ρ ^ 2) * σS ^ 2 * σy ^ 2 * (b₁ - b₂) ^ 2 :=
      mul_pos (mul_pos (mul_pos (sub_pos.2 hρ2) (pow_pos hσS 2)) (pow_pos hσy 2)) hd
    linarith
  have hq := Real.sqrt_pos.2 (mul_pos h1 h2)
  unfold gsFutCorr
  rw [← Real.sqrt_mul h1.le, abs_div, abs_of_pos hq, div_lt_one hq,
    Real.lt_sqrt (abs_nonneg _), sq_abs]
  exact key

#print axioms gsFutCorr_abs_lt_one

/-- **The Gibson-Schwartz futures price** (The formula; Why it works, Steps 0-4). In the pricing
world, with spot `S > 0`, a yield pulled toward `α` at speed `κ > 0`, and delivery `T ≥ 0` years
out: if the log of spot at delivery, `X = ln S_T`, is normal with average
`m(T) = ln S + (r - ½σS²)T - ∫₀ᵀ (α + (y - α)e^(-κt)) dt` (the yield's expected total taken off)
and variance `v(T) = σS² T + σy² ∫₀ᵀ B(u)² du - 2ρ σS σy ∫₀ᵀ B(u) du`, then the futures price
`E[S_T] = E[e^X]` equals the closed form
`S exp((r - α)T - (y - α)B(T) - ρ σS σy I₁(T) + ½ σy² I₂(T))`. -/
theorem gibson_schwartz_futures_price
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (S y r α κ σS σy ρ T : ℝ) (hS : 0 < S) (hκ : 0 < κ) (hT : 0 ≤ T)
    (X : Ω → ℝ) (v : NNReal)
    (hv : (v : ℝ) = σS ^ 2 * T + σy ^ 2 * (∫ u in (0 : ℝ)..T, gsB κ u ^ 2)
      - 2 * ρ * σS * σy * (∫ u in (0 : ℝ)..T, gsB κ u))
    (hX : HasLaw X
      (gaussianReal (log S + (r - σS ^ 2 / 2) * T - ∫ t in (0 : ℝ)..T, (α + (y - α) * exp (-κ * t)))
        v) P) :
    ∫ ω, exp (X ω) ∂P = gsFutures S y r α κ σS σy ρ T := by
  have hm := mgf_gaussianReal hX 1
  simp only [mgf, one_mul, one_pow, mul_one] at hm
  rw [hm, gs_int_yield α y κ T hκ, hv, gs_int_B κ T hκ, gs_int_B_sq κ T hκ]
  unfold gsFutures
  conv_rhs => rw [← Real.exp_log hS]
  rw [← Real.exp_add]
  congr 1
  ring

/-- **Short and long futures stop moving in lockstep** (The formula, the helper formulas; Why it
works, Step 5). With spot and the yield both random (`σS > 0`, `σy > 0`), their kicks not one
shock (`|ρ| < 1`), speed `κ > 0`, and two different delivery dates `T₁ ≠ T₂`: the correlation of
the two futures' returns is strictly between `-1` and `1`. -/
theorem futures_correlation_below_one
    (κ σS σy ρ T₁ T₂ : ℝ) (hκ : 0 < κ) (hσS : 0 < σS) (hσy : 0 < σy) (hρ : |ρ| < 1)
    (hT : T₁ ≠ T₂) :
    |gsFutCorr σS σy ρ (gsB κ T₁) (gsB κ T₂)| < 1 := by
  apply gsFutCorr_abs_lt_one σS σy ρ _ _ hσS hσy hρ
  intro h
  unfold gsB at h
  rw [div_left_inj' hκ.ne'] at h
  have h' : exp (-κ * T₁) = exp (-κ * T₂) := by linarith
  exact hT (mul_left_cancel₀ (neg_ne_zero.mpr hκ.ne') (Real.exp_injective h'))

/-- **The level absorbs the correlation** (Why it works, Step 7, "Not the level apart from the
correlation"). For a fixed speed `κ > 0`, setting the correlation to `0` and raising the level by
`ρ σS σy / κ` leaves every futures price unchanged. -/
theorem level_absorbs_correlation
    (S y r α κ σS σy ρ T : ℝ) (hκ : 0 < κ) :
    gsFutures S y r α κ σS σy ρ T = gsFutures S y r (α + ρ * σS * σy / κ) κ σS σy 0 T := by
  unfold gsFutures gsI1
  congr 2
  ring

-- Step 4: at three years the carry piece is (r - α)T = (0.05 - 0.03) × 3 = +0.0600.
example : ((5 : ℚ) / 100 - 3 / 100) * 3 = 6 / 100 := by norm_num
-- The long end's volatility: σS² - 2ρσSσy/κ + σy²/κ² = 0.09 - 0.08 + 0.0625/2.25 = 17/450,
-- and its square root is 19.44 percent to two decimals.
example : ((3 : ℚ) / 10) ^ 2 - 2 * (8 / 10) * (3 / 10) * (25 / 100) / (3 / 2)
    + (25 / 100) ^ 2 / (3 / 2) ^ 2 = 17 / 450 := by norm_num
example : ((19435 : ℚ) / 100000) ^ 2 < 17 / 450 ∧ (17 : ℚ) / 450 < (19445 / 100000) ^ 2 := by
  norm_num

#print axioms gibson_schwartz_futures_price
#print axioms futures_correlation_below_one
#print axioms level_absorbs_correlation
