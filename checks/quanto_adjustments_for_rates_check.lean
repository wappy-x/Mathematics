-- Quanto rates: the fair strike of a foreign rate paid in domestic currency at a frozen conversion is the foreign forward average reweighted by one over the forward exchange rate, and in the lognormal model it equals F times exp(-rho sigma_F sigma_G T).
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap
import Mathlib.MeasureTheory.Measure.Prod

open MeasureTheory ProbabilityTheory Real

lemma gauss_exp_integral (t : ℝ) :
    ∫ x, exp (t * x) ∂(gaussianReal 0 1) = exp (t ^ 2 / 2) := by
  have h := congrFun (mgf_fun_id_gaussianReal (μ := 0) (v := 1)) t
  simp only [mgf] at h
  rw [h]; congr 1; simp

#print axioms gauss_exp_integral

/-- The exact quanto strike, in any model without free money. Let `μ` be the yen forward measure
and `G` the forward exchange rate at fixing (dollars per yen, always positive), with the no-free-money
pin `E^{f,U}[1/G_T] = 1/G₀`. The dollar forward measure is `μ` reweighted by the density `G₀ / G_T`.
Then that reweighting is a probability measure, and the dollar average of the yen rate `L`, which is
the fair dollar strike `K_q`, equals `E^{f,U}[L / G_T] / E^{f,U}[1 / G_T]`. The only integrability
needed is that `1/G_T` and `L/G_T` have finite averages. -/
theorem quanto_strike_eq_forward_reweighted_by_inverse_fx
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (L G : Ω → ℝ) (G₀ : ℝ) (hG : Measurable G) (hGpos : ∀ ω, 0 < G ω) (hG₀ : 0 < G₀)
    (hw : Integrable (fun ω => 1 / G ω) μ) (hLw : Integrable (fun ω => L ω / G ω) μ)
    (hpin : ∫ ω, 1 / G ω ∂μ = 1 / G₀) :
    IsProbabilityMeasure (μ.withDensity (fun ω => ENNReal.ofReal (G₀ / G ω))) ∧
      ∫ ω, L ω ∂(μ.withDensity (fun ω => ENNReal.ofReal (G₀ / G ω))) =
        (∫ ω, L ω / G ω ∂μ) / (∫ ω, 1 / G ω ∂μ) := by
  have hmeas : Measurable (fun ω => ENNReal.ofReal (G₀ / G ω)) :=
    ENNReal.measurable_ofReal.comp (measurable_const.div hG)
  have hint : Integrable (fun ω => G₀ / G ω) μ := by
    have := hw.const_mul G₀
    refine this.congr (Filter.Eventually.of_forall fun ω => ?_)
    simp [div_eq_mul_inv]
  refine ⟨⟨?_⟩, ?_⟩
  · rw [withDensity_apply _ MeasurableSet.univ, Measure.restrict_univ,
      ← ofReal_integral_eq_lintegral_ofReal hint
        (Filter.Eventually.of_forall fun ω => (div_pos hG₀ (hGpos ω)).le)]
    have : ∫ ω, G₀ / G ω ∂μ = G₀ * ∫ ω, 1 / G ω ∂μ := by
      rw [← integral_const_mul]; congr 1; ext ω; simp [div_eq_mul_inv]
    rw [this, hpin, mul_one_div_cancel hG₀.ne', ENNReal.ofReal_one]
  · rw [integral_withDensity_eq_integral_toReal_smul hmeas
      (Filter.Eventually.of_forall fun _ => ENNReal.ofReal_lt_top), hpin]
    have : ∀ ω, (ENNReal.ofReal (G₀ / G ω)).toReal • L ω = G₀ * (L ω / G ω) := by
      intro ω
      rw [ENNReal.toReal_ofReal (div_pos hG₀ (hGpos ω)).le, smul_eq_mul]; ring
    simp_rw [this]
    rw [integral_const_mul]; field_simp

/-- The covariance form: the quanto strike is the yen forward `E^{f,U}[L]` plus the covariance of
the rate with the weight `1/G_T`, divided by the average weight. -/
theorem quanto_strike_eq_forward_add_covariance
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (L G : Ω → ℝ) (hGpos : ∀ ω, 0 < G ω) (hL : Integrable L μ)
    (hw : Integrable (fun ω => 1 / G ω) μ) (hLw : Integrable (fun ω => L ω / G ω) μ) :
    (∫ ω, L ω / G ω ∂μ) / (∫ ω, 1 / G ω ∂μ) =
      (∫ ω, L ω ∂μ) + cov[L, fun ω => 1 / G ω; μ] / (∫ ω, 1 / G ω ∂μ) := by
  have hpos : 0 < ∫ ω, 1 / G ω ∂μ := by
    rw [integral_pos_iff_support_of_nonneg (fun ω => (one_div_pos.mpr (hGpos ω)).le) hw]
    have : Function.support (fun ω => 1 / G ω) = Set.univ := by
      ext ω; simp [(hGpos ω).ne']
    rw [this]; simp
  set a := ∫ ω, L ω ∂μ
  set b := ∫ ω, 1 / G ω ∂μ
  have hcov : cov[L, fun ω => 1 / G ω; μ] = (∫ ω, L ω / G ω ∂μ) - a * b := by
    rw [covariance]
    have : ∀ ω, (L ω - μ[L]) * (1 / G ω - μ[fun ω => 1 / G ω])
        = (L ω / G ω - b * L ω) - (a * (1 / G ω) - a * b) := by
      intro ω; simp only [a, b]; ring
    simp_rw [this]
    rw [integral_sub (f := fun ω => L ω / G ω - b * L ω) (g := fun ω => a * (1 / G ω) - a * b)
        (hLw.sub (hL.const_mul b)) ((hw.const_mul a).sub (integrable_const _)),
      integral_sub (f := fun ω => L ω / G ω) (g := fun ω => b * L ω) hLw (hL.const_mul b),
      integral_sub (f := fun ω => a * (1 / G ω)) (g := fun ω => a * b) (hw.const_mul a)
        (integrable_const _),
      integral_const_mul, integral_const_mul, integral_const, probReal_univ, one_smul]
    simp only [a, b]; ring
  rw [hcov]; field_simp; ring

/-- The lognormal model. Under the yen forward measure the yen forward rate is driftless lognormal,
`F_T = F exp(σ_F √T Z₁ - σ_F² T / 2)`, and the forward exchange rate is lognormal with volatility
`σ_G` and correlation `ρ` to the rate, `G_T = exp(g + σ_G √T (ρ Z₁ + √(1 - ρ²) Z₂))`, where
`Z₁, Z₂` are independent standard normals and `g` is any constant. Then the fair quanto strike
`E[F_T / G_T] / E[1 / G_T]` equals `F exp(-ρ σ_F σ_G T)`. -/
theorem quanto_strike_lognormal
    (F σF σG ρ T g : ℝ) (hT : 0 ≤ T) (hρ : ρ ∈ Set.Icc (-1 : ℝ) 1) :
    (∫ p : ℝ × ℝ, (F * exp (σF * √T * p.1 - σF ^ 2 * T / 2)) /
          exp (g + σG * √T * (ρ * p.1 + √(1 - ρ ^ 2) * p.2))
          ∂((gaussianReal 0 1).prod (gaussianReal 0 1))) /
      (∫ p : ℝ × ℝ, 1 / exp (g + σG * √T * (ρ * p.1 + √(1 - ρ ^ 2) * p.2))
          ∂((gaussianReal 0 1).prod (gaussianReal 0 1))) =
      F * exp (-(ρ * σF * σG * T)) := by
  set s := √T
  set r := √(1 - ρ ^ 2)
  have hs : s ^ 2 = T := Real.sq_sqrt hT
  have hnum : ∀ p : ℝ × ℝ, (F * exp (σF * s * p.1 - σF ^ 2 * T / 2)) /
          exp (g + σG * s * (ρ * p.1 + r * p.2)) =
      (F * exp (-(σF ^ 2 * T / 2) - g) * exp ((σF * s - σG * s * ρ) * p.1)) *
        exp ((-(σG * s * r)) * p.2) := by
    intro p
    rw [mul_div_assoc, ← Real.exp_sub]
    simp only [mul_assoc, ← Real.exp_add]
    congr 2; ring
  have hden : ∀ p : ℝ × ℝ, 1 / exp (g + σG * s * (ρ * p.1 + r * p.2)) =
      (exp (-g) * exp ((-(σG * s * ρ)) * p.1)) * exp ((-(σG * s * r)) * p.2) := by
    intro p
    rw [one_div, ← Real.exp_neg, ← Real.exp_add, ← Real.exp_add]
    congr 1; ring
  simp_rw [hnum, hden]
  rw [integral_prod_mul (fun x : ℝ => F * exp (-(σF ^ 2 * T / 2) - g) * exp ((σF * s - σG * s * ρ) * x))
      (fun y : ℝ => exp ((-(σG * s * r)) * y)),
    integral_prod_mul (fun x : ℝ => exp (-g) * exp ((-(σG * s * ρ)) * x))
      (fun y : ℝ => exp ((-(σG * s * r)) * y))]
  rw [integral_const_mul, integral_const_mul, gauss_exp_integral, gauss_exp_integral,
    gauss_exp_integral]
  have h1 : 0 < exp ((-(σG * s * r)) ^ 2 / 2) := exp_pos _
  have h2 : 0 < exp (-g) := exp_pos _
  have h3 : 0 < exp ((-(σG * s * ρ)) ^ 2 / 2) := exp_pos _
  rw [mul_div_mul_right _ _ h1.ne']
  rw [div_eq_iff (mul_pos h2 h3).ne']
  rw [mul_assoc, mul_assoc, mul_assoc]
  congr 1
  simp only [← Real.exp_add]
  congr 1
  rw [← hs]; ring

-- Worked numbers: rho * sigma_F * sigma_G * T = 0.40 * 0.30 * 0.10 * 1 = 0.012.
example : (2 / 5 : ℚ) * (3 / 10) * (1 / 10) * 1 = 3 / 250 := by norm_num
-- Dollars at U per unit of rate: 0.01 * 100,000,000 * 0.25 = 250,000; today: 250,000 * 0.98 = 245,000.
example : (1 / 100 : ℚ) * 100000000 * (1 / 4) = 250000 := by norm_num
example : (250000 : ℚ) * (98 / 100) = 245000 := by norm_num

-- Three-state world: weights 1/X_T are 125, 100, 250/3.
example : (1 : ℚ) / (8 / 1000) = 125 ∧ (1 : ℚ) / (10 / 1000) = 100 ∧
    (1 : ℚ) / (12 / 1000) = 250 / 3 := by norm_num
-- Average weight 1225/12 (about 102.08), and the implied dollar bond 0.01 * 0.96 * 1225/12 = 0.98.
example : (1 / 4 : ℚ) * 125 + 1 / 2 * 100 + 1 / 4 * (250 / 3) = 1225 / 12 := by norm_num
example : (1 / 100 : ℚ) * (96 / 100) * (1225 / 12) = 98 / 100 := by norm_num
-- Dollar probabilities 15/49, 24/49, 10/49.
example : (1 / 4 : ℚ) * 125 / (1225 / 12) = 15 / 49 ∧ (1 / 2 : ℚ) * 100 / (1225 / 12) = 24 / 49 ∧
    (1 / 4 : ℚ) * (250 / 3) / (1225 / 12) = 10 / 49 := by norm_num
-- Fair quanto rate (15 * 1% + 24 * 3% + 10 * 5%) / 49 = 137/49 percent (about 2.7959%).
example : ((15 : ℚ) * 1 + 24 * 3 + 10 * 5) / 49 = 137 / 49 := by norm_num
-- Covariance route: the covariance of the rate with the weight is -5/24 (about -0.2083),
-- and 3% + (-5/24) / (1225/12) gives the same 137/49 percent.
example : (1 / 4 : ℚ) * (1 / 100) * 125 + 1 / 2 * (3 / 100) * 100 + 1 / 4 * (5 / 100) * (250 / 3)
    - (3 / 100) * (1225 / 12) = -5 / 24 := by norm_num
example : (3 / 100 : ℚ) + (-5 / 24) / (1225 / 12) = 137 / 4900 := by norm_num
-- Value struck at 3%: 245,000 * (137/4900 - 3/100) = -500.
example : (245000 : ℚ) * (137 / 4900 - 3 / 100) = -500 := by norm_num

#print axioms quanto_strike_eq_forward_reweighted_by_inverse_fx
#print axioms quanto_strike_eq_forward_add_covariance
#print axioms quanto_strike_lognormal
