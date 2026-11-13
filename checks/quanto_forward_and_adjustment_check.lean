-- The quanto adjustment: in the two-price lognormal model the dollar investor's average of a euro share's final price is exactly `S e^((r_f - q - ρσ_Sσ_X)T)`, so that is the zero-cost level, and no other share drift makes the dollar share fairly priced.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.NormNum

open Real MeasureTheory ProbabilityTheory

/-- The share's euro price at time `T` in the euro world: it drifts at `r_f - q` with
volatility `σ_S`, driven by the bell-curve draw `z₁`:
`S_T = S e^((r_f - q - σ_S²/2)T + σ_S √T z₁)`. -/
noncomputable def shareEuroWorld (S rf q σS T z₁ : ℝ) : ℝ :=
  S * exp ((rf - q - σS ^ 2 / 2) * T + σS * √T * z₁)

/-- The exchange rate's draw, correlated at `ρ` with the share's draw `z₁`:
`ρ z₁ + √(1 - ρ²) z₂`, where `z₂` is a fresh independent draw. -/
noncomputable def fxDraw (ρ z₁ z₂ : ℝ) : ℝ :=
  ρ * z₁ + √(1 - ρ ^ 2) * z₂

/-- One dollar's euro value at time `T` in the euro world, `Y_T = 1/X_T`: it starts at `1/X₀`,
drifts at `r_f - r_d` with volatility `σ_X`, and its driver is minus the exchange rate's draw `w`
(a stronger euro is a weaker dollar): `Y_T = (1/X₀) e^((r_f - r_d - σ_X²/2)T - σ_X √T w)`. -/
noncomputable def dollarInEuros (X₀ rd rf σX T w : ℝ) : ℝ :=
  (1 / X₀) * exp ((rf - rd - σX ^ 2 / 2) * T - σX * √T * w)

/-- The card's quanto forward `F_Q = S e^((r_f - q - ρσ_Sσ_X)T)`. -/
noncomputable def quantoForward (S rf q ρ σS σX T : ℝ) : ℝ :=
  S * exp ((rf - q - ρ * σS * σX) * T)

/-- The card's euro forward `F = S e^((r_f - q)T)`. -/
noncomputable def euroForward (S rf q T : ℝ) : ℝ :=
  S * exp ((rf - q) * T)

/-- The share's euro price at time `T` in the dollar world, grown at a drift `μ`:
`S e^((μ - σ_S²/2)T + σ_S √T z₁)`. -/
noncomputable def shareDollarWorld (S μ σS T z₁ : ℝ) : ℝ :=
  S * exp ((μ - σS ^ 2 / 2) * T + σS * √T * z₁)

/-- The exchange rate (dollars per euro) at time `T` in the dollar world, drifting at
`r_d - r_f` (covered interest parity): `X_T = X₀ e^((r_d - r_f - σ_X²/2)T + σ_X √T w)`. -/
noncomputable def fxDollarWorld (X₀ rd rf σX T w : ℝ) : ℝ :=
  X₀ * exp ((rd - rf - σX ^ 2 / 2) * T + σX * √T * w)


section QuantoHelpers

variable {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₁ Z₂ : Ω → ℝ}

lemma quanto_gauss2_integral
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q) (a b : ℝ) :
    ∫ ω, exp (a * Z₁ ω + b * Z₂ ω) ∂Q = exp ((a ^ 2 + b ^ 2) / 2) := by
  simp_rw [exp_add]
  have h1 : AEStronglyMeasurable (fun ω => exp (a * Z₁ ω)) Q :=
    (by fun_prop : Continuous fun x : ℝ => exp (a * x)).aestronglyMeasurable.comp_aemeasurable
      hZ₁.aemeasurable
  have h2 : AEStronglyMeasurable (fun ω => exp (b * Z₂ ω)) Q :=
    (by fun_prop : Continuous fun x : ℝ => exp (b * x)).aestronglyMeasurable.comp_aemeasurable
      hZ₂.aemeasurable
  have hm := (hind.exp_mul a b).integral_mul_eq_mul_integral h1 h2
  simp only [Pi.mul_apply] at hm
  rw [hm]
  have e1 := mgf_gaussianReal hZ₁ a
  have e2 := mgf_gaussianReal hZ₂ b
  simp only [mgf] at e1 e2
  rw [e1, e2, ← exp_add]
  congr 1
  simp only [NNReal.coe_one]
  ring

lemma quanto_gauss2_integrable
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q) (a b : ℝ) :
    Integrable (fun ω => exp (a * Z₁ ω + b * Z₂ ω)) Q :=
  Integrable.of_integral_ne_zero (by rw [quanto_gauss2_integral hZ₁ hZ₂ hind]; positivity)

lemma quanto_gauss2_affine_integral
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q) (c d a b : ℝ) :
    ∫ ω, c * exp (d + (a * Z₁ ω + b * Z₂ ω)) ∂Q = c * exp (d + (a ^ 2 + b ^ 2) / 2) := by
  simp_rw [Real.exp_add d, ← mul_assoc]
  rw [integral_const_mul, quanto_gauss2_integral hZ₁ hZ₂ hind]

lemma quanto_gauss2_affine_integrable
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q) (c d a b : ℝ) :
    Integrable (fun ω => c * exp (d + (a * Z₁ ω + b * Z₂ ω))) Q := by
  refine ((quanto_gauss2_integrable hZ₁ hZ₂ hind a b).const_mul (c * exp d)).congr
    (ae_of_all _ fun ω => ?_)
  simp only [Real.exp_add d]
  ring

lemma quanto_num_eq (S X₀ rd rf q σS σX ρ T : ℝ) (z₁ z₂ : ℝ) :
    shareEuroWorld S rf q σS T z₁ * dollarInEuros X₀ rd rf σX T (fxDraw ρ z₁ z₂) =
      S / X₀ * exp (((rf - q - σS ^ 2 / 2) * T + (rf - rd - σX ^ 2 / 2) * T) +
        ((σS * √T - σX * √T * ρ) * z₁ + (-(σX * √T * √(1 - ρ ^ 2))) * z₂)) := by
  simp only [shareEuroWorld, dollarInEuros, fxDraw]
  calc _ = S / X₀ * (exp ((rf - q - σS ^ 2 / 2) * T + σS * √T * z₁) *
        exp ((rf - rd - σX ^ 2 / 2) * T - σX * √T * (ρ * z₁ + √(1 - ρ ^ 2) * z₂))) := by ring
    _ = _ := by rw [← exp_add]; congr 2; ring

lemma quanto_den_eq (X₀ rd rf σX ρ T : ℝ) (z₁ z₂ : ℝ) :
    dollarInEuros X₀ rd rf σX T (fxDraw ρ z₁ z₂) =
      1 / X₀ * exp ((rf - rd - σX ^ 2 / 2) * T +
        ((-(σX * √T * ρ)) * z₁ + (-(σX * √T * √(1 - ρ ^ 2))) * z₂)) := by
  simp only [dollarInEuros, fxDraw]
  congr 2
  ring

lemma quanto_num_integral
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q) (S X₀ rd rf q σS σX ρ T : ℝ) :
    Integrable (fun ω => shareEuroWorld S rf q σS T (Z₁ ω) *
        dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω))) Q ∧
    ∫ ω, shareEuroWorld S rf q σS T (Z₁ ω) *
        dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q =
      S / X₀ * exp (((rf - q - σS ^ 2 / 2) * T + (rf - rd - σX ^ 2 / 2) * T) +
        ((σS * √T - σX * √T * ρ) ^ 2 + (-(σX * √T * √(1 - ρ ^ 2))) ^ 2) / 2) := by
  simp_rw [quanto_num_eq]
  exact ⟨quanto_gauss2_affine_integrable hZ₁ hZ₂ hind _ _ _ _,
    quanto_gauss2_affine_integral hZ₁ hZ₂ hind _ _ _ _⟩

lemma quanto_den_integral
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q) (X₀ rd rf σX ρ T : ℝ) :
    Integrable (fun ω => dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω))) Q ∧
    ∫ ω, dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q =
      1 / X₀ * exp ((rf - rd - σX ^ 2 / 2) * T +
        ((-(σX * √T * ρ)) ^ 2 + (-(σX * √T * √(1 - ρ ^ 2))) ^ 2) / 2) := by
  simp_rw [quanto_den_eq]
  exact ⟨quanto_gauss2_affine_integrable hZ₁ hZ₂ hind _ _ _ _,
    quanto_gauss2_affine_integral hZ₁ hZ₂ hind _ _ _ _⟩

end QuantoHelpers

#print axioms quanto_gauss2_integral
#print axioms quanto_gauss2_integrable
#print axioms quanto_gauss2_affine_integral
#print axioms quanto_gauss2_affine_integrable
#print axioms quanto_num_eq
#print axioms quanto_den_eq
#print axioms quanto_num_integral
#print axioms quanto_den_integral

/-- **The quanto forward is the share's average in the dollar world** (The formula; Why it
works, Step 4 and the detailed proof). Work in the euro world `Q`, with two independent
standard bell-curve draws `Z₁`, `Z₂`. The share drifts at `r_f - q` with fixed volatility `σ_S`;
the dollar's euro value `Y_T` drifts at `r_f - r_d` with fixed volatility `σ_X`, its driver
correlated with the share's at a fixed `ρ` between -1 and 1; today's rate `X₀` is positive and
`T ≥ 0`. The dollar world reweights the euro world by the dollar's euro value, so its average of
`S_T` is `E[S_T Y_T] / E[Y_T]`. That average is exactly `S e^((r_f - q - ρσ_Sσ_X)T)`: the share
grows at the euro rate, less the dividend, less correlation times the two volatilities, and
neither the dollar rate nor today's exchange rate enters. -/
theorem quanto_forward_is_dollar_world_mean_of_share
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q)
    (S X₀ rd rf q σS σX ρ T : ℝ) (hX₀ : 0 < X₀) (hρ₁ : -1 ≤ ρ) (hρ₂ : ρ ≤ 1) (hT : 0 ≤ T) :
    (∫ ω, shareEuroWorld S rf q σS T (Z₁ ω) *
        dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q) /
      (∫ ω, dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q) =
      quantoForward S rf q ρ σS σX T := by
  have hsT : √T ^ 2 = T := Real.sq_sqrt hT
  rw [(quanto_num_integral hZ₁ hZ₂ hind S X₀ rd rf q σS σX ρ T).2,
    (quanto_den_integral hZ₁ hZ₂ hind X₀ rd rf σX ρ T).2, quantoForward]
  rw [show ((rf - q - σS ^ 2 / 2) * T + (rf - rd - σX ^ 2 / 2) * T) +
        ((σS * √T - σX * √T * ρ) ^ 2 + (-(σX * √T * √(1 - ρ ^ 2))) ^ 2) / 2 =
      (rf - q - ρ * σS * σX) * T + ((rf - rd - σX ^ 2 / 2) * T +
        ((-(σX * √T * ρ)) ^ 2 + (-(σX * √T * √(1 - ρ ^ 2))) ^ 2) / 2) by
    linear_combination (σS ^ 2 / 2 - σS * σX * ρ) * hsT, exp_add]
  field_simp

/-- **The zero-cost level is the quanto forward** (General Overview; Why it works, Step 4). In
the same model, a contract that pays `X̄ (S_T - K)` dollars at `T`, for a fixed rate `X̄ > 0` (written `Xbar`),
is worth today its dollar-world average discounted at the dollar rate,
`X̄ e^(-r_d T) E[(S_T - K) Y_T] / E[Y_T]`. It costs nothing exactly when the agreed level is
`K = S e^((r_f - q - ρσ_Sσ_X)T)`, whatever the fixed rate. -/
theorem quanto_contract_costs_nothing_iff_level_is_quanto_forward
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q)
    (S X₀ Xbar K rd rf q σS σX ρ T : ℝ) (hX₀ : 0 < X₀) (hXbar : 0 < Xbar)
    (hρ₁ : -1 ≤ ρ) (hρ₂ : ρ ≤ 1) (hT : 0 ≤ T) :
    Xbar * exp (-(rd * T)) *
        ((∫ ω, (shareEuroWorld S rf q σS T (Z₁ ω) - K) *
            dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q) /
          (∫ ω, dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q)) = 0 ↔
      K = quantoForward S rf q ρ σS σX T := by
  obtain ⟨hi1, he1⟩ := quanto_num_integral hZ₁ hZ₂ hind S X₀ rd rf q σS σX ρ T
  obtain ⟨hi2, he2⟩ := quanto_den_integral hZ₁ hZ₂ hind X₀ rd rf σX ρ T
  have h1 := quanto_forward_is_dollar_world_mean_of_share hZ₁ hZ₂ hind S X₀ rd rf q σS σX ρ T
    hX₀ hρ₁ hρ₂ hT
  have hden : (∫ ω, dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q) ≠ 0 := by
    rw [he2]; positivity
  have hsplit : (∫ ω, (shareEuroWorld S rf q σS T (Z₁ ω) - K) *
        dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q) =
      (∫ ω, shareEuroWorld S rf q σS T (Z₁ ω) *
        dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q) -
      K * ∫ ω, dollarInEuros X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂Q := by
    rw [← integral_const_mul, ← integral_sub hi1 (hi2.const_mul K)]
    congr 1
    funext ω
    ring
  rw [hsplit, sub_div, mul_div_cancel_right₀ _ hden, h1]
  have hc : Xbar * exp (-(rd * T)) ≠ 0 := by positivity
  rw [mul_eq_zero, or_iff_right hc, sub_eq_zero, eq_comm]

/-- **No-arbitrage forces the quanto drift** (Why it works, Steps 1 to 3). Work in the dollar
world `P` with two independent standard bell-curve draws. The exchange rate drifts at
`r_d - r_f` with fixed volatility `σ_X`; the share, priced in euros, has fixed volatility
`σ_S`, a driver correlated with the rate's at a fixed `ρ` between -1 and 1, and some drift `μ`.
Take a positive share price `S`, a positive rate `X₀` and `T > 0` years. The dollar value of one
share averages to the required `S X₀ e^((r_d - q)T)` exactly when `μ = r_f - q - ρσ_Sσ_X`; any
other drift, the euro world's `r_f - q` included, leaves the dollar share mispriced. -/
theorem dollar_share_fair_iff_quanto_drift
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) P) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) P)
    (hind : IndepFun Z₁ Z₂ P)
    (S X₀ rd rf q σS σX ρ T μ : ℝ) (hS : 0 < S) (hX₀ : 0 < X₀)
    (hρ₁ : -1 ≤ ρ) (hρ₂ : ρ ≤ 1) (hT : 0 < T) :
    ∫ ω, shareDollarWorld S μ σS T (Z₁ ω) *
        fxDollarWorld X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) ∂P =
      S * X₀ * exp ((rd - q) * T) ↔
      μ = rf - q - ρ * σS * σX := by
  have hsT : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hs : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt (by nlinarith)
  have heq : ∀ ω, shareDollarWorld S μ σS T (Z₁ ω) *
      fxDollarWorld X₀ rd rf σX T (fxDraw ρ (Z₁ ω) (Z₂ ω)) =
      S * X₀ * exp (((μ - σS ^ 2 / 2) * T + (rd - rf - σX ^ 2 / 2) * T) +
        ((σS * √T + σX * √T * ρ) * Z₁ ω + (σX * √T * √(1 - ρ ^ 2)) * Z₂ ω)) := by
    intro ω
    simp only [shareDollarWorld, fxDollarWorld, fxDraw]
    calc _ = S * X₀ * (exp ((μ - σS ^ 2 / 2) * T + σS * √T * Z₁ ω) *
          exp ((rd - rf - σX ^ 2 / 2) * T + σX * √T * (ρ * Z₁ ω + √(1 - ρ ^ 2) * Z₂ ω))) := by
          ring
      _ = _ := by rw [← exp_add]; congr 2; ring
  simp_rw [heq]
  rw [quanto_gauss2_affine_integral hZ₁ hZ₂ hind]
  rw [show ((μ - σS ^ 2 / 2) * T + (rd - rf - σX ^ 2 / 2) * T) +
        ((σS * √T + σX * √T * ρ) ^ 2 + (σX * √T * √(1 - ρ ^ 2)) ^ 2) / 2 =
      (μ - rf + rd + ρ * σS * σX) * T by
    linear_combination (σS ^ 2 / 2 + σS * σX * ρ + σX ^ 2 * ρ ^ 2 / 2 +
      σX ^ 2 * (1 - ρ ^ 2) / 2) * hsT + (σX ^ 2 * √T ^ 2 / 2) * hs]
  rw [mul_right_inj' (by positivity : S * X₀ ≠ 0), exp_eq_exp]
  constructor
  · intro h
    have := mul_right_cancel₀ hT.ne' h
    linarith
  · intro h
    subst h
    ring

-- The house market's adjustment: 0.30 × 0.20 × 0.10 = 0.006.
example : (3 / 10 : ℚ) * (2 / 10) * (1 / 10) = 6 / 1000 := by norm_num

-- The quanto drift: 0.03 - 0.01 - 0.006 = 0.014.
example : (3 / 100 : ℚ) - 1 / 100 - 6 / 1000 = 14 / 1000 := by norm_num

-- The dollar share's required growth: r_d - q = 0.05 - 0.01 = 0.04.
example : (5 / 100 : ℚ) - 1 / 100 = 4 / 100 := by norm_num

-- At correlation 1 the quanto forward is exactly EUR 100: the 2 percent carry and the
-- 2 percent adjustment cancel.
example : quantoForward 100 (3 / 100) (1 / 100) 1 (2 / 10) (1 / 10) 1 = 100 := by
  norm_num [quantoForward]

-- The gap in logs between the euro forward and the quanto forward is exactly 0.006.
example : log (euroForward 100 (3 / 100) (1 / 100) 1 /
    quantoForward 100 (3 / 100) (1 / 100) (3 / 10) (2 / 10) (1 / 10) 1) = 6 / 1000 := by
  rw [euroForward, quantoForward, mul_div_mul_left _ _ (by norm_num : (100 : ℝ) ≠ 0),
    ← exp_sub, log_exp]
  norm_num

-- One day, one move each: 1.01 × 1.01 = 1.0201 and 1.01 × 0.99 = 0.9999.
example : (101 / 100 : ℚ) * (101 / 100) = 10201 / 10000 := by norm_num
example : (101 / 100 : ℚ) * (99 / 100) = 9999 / 10000 := by norm_num

-- The two-state story: the strong-euro state gets dollar-world weight 0.45, and the
-- dollar-world averages are 100.20 (moving together) and 103.80 (moving apart), against 102.
example : ((1 / 2) / (121 / 100) : ℚ) / ((1 / 2) / (121 / 100) + (1 / 2) / (99 / 100)) =
    45 / 100 := by norm_num
example : (1 / 2 : ℚ) * 120 + (1 / 2) * 84 = 102 := by norm_num
example : (45 / 100 : ℚ) * 120 + (55 / 100) * 84 = 1002 / 10 := by norm_num
example : (55 / 100 : ℚ) * 120 + (45 / 100) * 84 = 1038 / 10 := by norm_num

#print axioms quanto_forward_is_dollar_world_mean_of_share
#print axioms quanto_contract_costs_nothing_iff_level_is_quanto_forward
#print axioms dollar_share_fair_iff_quanto_drift
