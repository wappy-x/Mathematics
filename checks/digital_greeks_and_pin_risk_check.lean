-- Digital Greeks and pin risk: in the Black-Scholes model the cash digital's delta, gamma, vega, theta and rho are the discounted bell-curve height e^(-rT) φ(d₂) times the slope of d₂ (plus a discount term for theta and rho), its vega and gamma are negative exactly above S* = K e^(-(r - q + σ²/2)T) and positive below it, and its delta at the strike grows without limit as expiry nears.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real MeasureTheory ProbabilityTheory Filter Topology

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `φ(x) = e^(-x²/2) / √(2π)`: the bell curve's height at `x`, the standard normal density. -/
noncomputable def stdNormalPDF (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- The cash-side distance to the strike, `d₂ = (ln(S/K) + (r - q - σ²/2) T) / (σ√T)`. -/
noncomputable def bsD2 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * √T)

/-- The share-side distance to the strike, `d₁ = d₂ + σ√T`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  bsD2 S K r q σ T + σ * √T

/-- The price of the $1 cash digital: `c = e^(-rT) N(d₂)`. -/
noncomputable def cashDigital (S K r q σ T : ℝ) : ℝ :=
  exp (-r * T) * stdNormalCDF (bsD2 S K r q σ T)

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral 0 one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg 0 1 t)

#print axioms stdNormalCDF_eq_integral

lemma continuous_stdNormalPDF : Continuous stdNormalPDF := by
  unfold stdNormalPDF gaussianPDFReal; fun_prop

#print axioms continuous_stdNormalPDF

lemma hasDerivAt_stdNormalCDF (x : ℝ) : HasDerivAt stdNormalCDF (stdNormalPDF x) x := by
  have hi := (integrable_gaussianPDFReal 0 1).integrableOn (s := Set.Iic (0:ℝ))
  have h : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
      ← intervalIntegral.integral_Iic_sub_Iic hi (integrable_gaussianPDFReal 0 1).integrableOn]
    ring
  have hc : Continuous (gaussianPDFReal 0 1) := continuous_stdNormalPDF
  rw [h]
  exact (intervalIntegral.integral_hasDerivAt_right (hc.intervalIntegrable 0 x)
    (hc.stronglyMeasurableAtFilter _ _) hc.continuousAt).const_add _

#print axioms hasDerivAt_stdNormalCDF

lemma stdNormalPDF_eq (x : ℝ) : stdNormalPDF x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [stdNormalPDF, gaussianPDFReal]

#print axioms stdNormalPDF_eq

lemma stdNormalPDF_pos (x : ℝ) : 0 < stdNormalPDF x :=
  gaussianPDFReal_pos 0 1 x one_ne_zero

#print axioms stdNormalPDF_pos

lemma hasDerivAt_stdNormalPDF (x : ℝ) : HasDerivAt stdNormalPDF (-x * stdNormalPDF x) x := by
  have : stdNormalPDF = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext stdNormalPDF_eq
  rw [this]
  have h := ((((hasDerivAt_pow 2 x).neg).div_const 2).exp).const_mul (√(2 * π))⁻¹
  convert h using 1
  simp only [Pi.neg_apply]
  ring

#print axioms hasDerivAt_stdNormalPDF

lemma hasDerivAt_bsD2_S (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => bsD2 x K r q σ T) (1 / (S * σ * √T)) S := by
  unfold bsD2
  have h := ((((hasDerivAt_id' S).div_const K).log (by positivity)).add_const
    ((r - q - σ ^ 2 / 2) * T)).div_const (σ * √T)
  convert h using 1
  have : 0 < √T := Real.sqrt_pos.2 hT
  field_simp

#print axioms hasDerivAt_bsD2_S

lemma hasDerivAt_bsD2_σ (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun s => bsD2 S K r q s T) (-bsD1 S K r q σ T / σ) σ := by
  unfold bsD1 bsD2
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have h := ((((hasDerivAt_pow 2 σ).div_const 2).const_sub (r - q)).mul_const T
    |>.const_add (log (S / K))).div ((hasDerivAt_id' σ).mul_const √T) (by positivity)
  convert h using 1
  have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
  generalize √T = s at hT2 hsT ⊢
  subst hT2
  field_simp
  ring

#print axioms hasDerivAt_bsD2_σ

lemma hasDerivAt_bsD2_r (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun ρ => bsD2 S K ρ q σ T) (√T / σ) r := by
  unfold bsD2
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have h := ((((hasDerivAt_id' r).sub_const (q + σ ^ 2 / 2)).mul_const T).const_add
    (log (S / K))).div_const (σ * √T)
  convert h using 1
  · funext ρ; ring
  · have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
    generalize √T = s at hT2 hsT ⊢
    subst hT2
    field_simp

#print axioms hasDerivAt_bsD2_r

lemma hasDerivAt_bsD2_T (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun t => bsD2 S K r q σ t)
      (-(bsD1 S K r q σ T / (2 * T) - (r - q) / (σ * √T))) T := by
  unfold bsD1 bsD2
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have h := (((hasDerivAt_id' T).const_mul (r - q - σ ^ 2 / 2)).const_add
    (log (S / K))).div ((Real.hasDerivAt_sqrt hT.ne').const_mul σ) (by positivity)
  convert h using 1
  have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
  generalize √T = s at hT2 hsT ⊢
  subst hT2
  field_simp
  ring

#print axioms hasDerivAt_bsD2_T

lemma hasDerivAt_cash_S (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => cashDigital x K r q σ T)
      (exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) / (S * σ * √T)) S := by
  have h := ((hasDerivAt_stdNormalCDF _).comp S (hasDerivAt_bsD2_S S K r q σ T hS hK hσ hT)).const_mul
    (exp (-r * T))
  refine h.congr_deriv ?_
  ring

#print axioms hasDerivAt_cash_S

lemma hasDerivAt_cash_delta (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => exp (-r * T) * stdNormalPDF (bsD2 x K r q σ T) / (x * σ * √T))
      (-(exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) * bsD1 S K r q σ T)
          / (S ^ 2 * σ ^ 2 * T)) S := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have h := (((hasDerivAt_stdNormalPDF _).comp S (hasDerivAt_bsD2_S S K r q σ T hS hK hσ hT)).const_mul
    (exp (-r * T))).div (((hasDerivAt_id' S).mul_const σ).mul_const √T) (by positivity)
  refine h.congr_deriv ?_
  simp only [Function.comp_apply]
  rw [bsD1]
  generalize bsD2 S K r q σ T = d
  generalize stdNormalPDF d = p
  generalize exp (-r * T) = e
  have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
  generalize √T = s at hT2 hsT ⊢
  subst hT2
  field_simp
  ring

#print axioms hasDerivAt_cash_delta

lemma bsD1_eq (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    bsD1 S K r q σ T = (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) := by
  unfold bsD1 bsD2
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
  generalize √T = s at hT2 hsT ⊢
  subst hT2
  field_simp
  ring

#print axioms bsD1_eq

lemma bsD1_pos_iff (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    0 < bsD1 S K r q σ T ↔ K * exp (-(r - q + σ ^ 2 / 2) * T) < S := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  rw [bsD1_eq S K r q σ T hσ hT, lt_div_iff₀ (by positivity), zero_mul, ← lt_div_iff₀' hK,
    ← Real.lt_log_iff_exp_lt (by positivity)]
  constructor <;> intro h <;> linarith

#print axioms bsD1_pos_iff

lemma bsD1_neg_iff (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    bsD1 S K r q σ T < 0 ↔ S < K * exp (-(r - q + σ ^ 2 / 2) * T) := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  rw [bsD1_eq S K r q σ T hσ hT, div_lt_iff₀ (by positivity), zero_mul, ← div_lt_iff₀' hK,
    ← Real.log_lt_iff_lt_exp (by positivity)]
  constructor <;> intro h <;> linarith

#print axioms bsD1_neg_iff

/-- **The cash digital's five Greeks** (The formula; Why it works, Steps 0 to 4 and the detailed
proof). In the Black-Scholes model with one fixed volatility `σ > 0`, constant bank rate `r` and
dividend yield `q`, strike `K > 0`, time left `T > 0` and share price `S > 0`, the cash digital
`c = e^(-rT) N(d₂)` has
* delta `∂c/∂S = e^(-rT) φ(d₂) / (S σ √T)`,
* gamma, the slope of delta in `S`, `-e^(-rT) φ(d₂) d₁ / (S² σ² T)`,
* vega `∂c/∂σ = -e^(-rT) φ(d₂) d₁ / σ`,
* theta `-∂c/∂T = r c + e^(-rT) φ(d₂) (d₁/(2T) - (r - q)/(σ√T))`,
* rho `∂c/∂r = -T c + e^(-rT) φ(d₂) √T / σ`:
each one the discounted bell-curve height times how fast `d₂` moves, plus a discount term
for theta and rho. -/
theorem cash_digital_greeks_are_bell_height_times_slope
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => cashDigital x K r q σ T)
        (exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) / (S * σ * √T)) S ∧
      HasDerivAt (deriv (fun x => cashDigital x K r q σ T))
        (-(exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) * bsD1 S K r q σ T)
          / (S ^ 2 * σ ^ 2 * T)) S ∧
      HasDerivAt (fun s => cashDigital S K r q s T)
        (-(exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) * bsD1 S K r q σ T) / σ) σ ∧
      HasDerivAt (fun t => cashDigital S K r q σ t)
        (-(r * cashDigital S K r q σ T + exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T)
          * (bsD1 S K r q σ T / (2 * T) - (r - q) / (σ * √T)))) T ∧
      HasDerivAt (fun ρ => cashDigital S K ρ q σ T)
        (-T * cashDigital S K r q σ T
          + exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) * √T / σ) r := by
  refine ⟨hasDerivAt_cash_S S K r q σ T hS hK hσ hT, ?_, ?_, ?_, ?_⟩
  · refine (hasDerivAt_cash_delta S K r q σ T hS hK hσ hT).congr_of_eventuallyEq ?_
    filter_upwards [Ioi_mem_nhds hS] with x hx
    exact (hasDerivAt_cash_S x K r q σ T hx hK hσ hT).deriv
  · have h := ((hasDerivAt_stdNormalCDF _).comp σ (hasDerivAt_bsD2_σ S K r q σ T hσ hT)).const_mul
      (exp (-r * T))
    refine h.congr_deriv ?_
    ring
  · have h := ((hasDerivAt_id' T).const_mul (-r)).exp.mul
      ((hasDerivAt_stdNormalCDF _).comp T (hasDerivAt_bsD2_T S K r q σ T hσ hT))
    refine h.congr_deriv ?_
    unfold cashDigital
    simp only [Function.comp_apply]
    ring
  · have h := (((hasDerivAt_id' r).neg.mul_const T).exp).mul
      ((hasDerivAt_stdNormalCDF _).comp r (hasDerivAt_bsD2_r S K r q σ T hσ hT))
    refine h.congr_deriv ?_
    unfold cashDigital
    simp only [Function.comp_apply, Pi.neg_apply]
    ring

/-- **Vega and gamma turn negative below the strike** (Step 3). With `S > 0`, `K > 0`, `σ > 0`,
`T > 0` and any rates `r`, `q`, let `S* = K e^(-(r - q + σ²/2) T)`, the price where `d₁ = 0`.
The cash digital's vega and its gamma are both negative exactly when `S > S*`, and both
positive exactly when `S < S*`: more volatility makes the bet cheaper above `S*`, and the delta
hump peaks at `S*`, not at the strike. -/
theorem cash_digital_vega_and_gamma_change_sign_at_S_star
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (deriv (fun s => cashDigital S K r q s T) σ < 0 ↔
        K * exp (-(r - q + σ ^ 2 / 2) * T) < S) ∧
      (0 < deriv (fun s => cashDigital S K r q s T) σ ↔
        S < K * exp (-(r - q + σ ^ 2 / 2) * T)) ∧
      (deriv (deriv (fun x => cashDigital x K r q σ T)) S < 0 ↔
        K * exp (-(r - q + σ ^ 2 / 2) * T) < S) ∧
      (0 < deriv (deriv (fun x => cashDigital x K r q σ T)) S ↔
        S < K * exp (-(r - q + σ ^ 2 / 2) * T)) := by
  obtain ⟨-, hg, hv, -, -⟩ := cash_digital_greeks_are_bell_height_times_slope S K r q σ T hS hK hσ hT
  rw [hg.deriv, hv.deriv, ← bsD1_pos_iff S K r q σ T hS hK hσ hT,
    ← bsD1_neg_iff S K r q σ T hS hK hσ hT]
  have hE : 0 < exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) :=
    mul_pos (exp_pos _) (stdNormalPDF_pos _)
  have hden : 0 < S ^ 2 * σ ^ 2 * T := by positivity
  generalize exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) = E at hE
  generalize bsD1 S K r q σ T = d
  generalize S ^ 2 * σ ^ 2 * T = M at hden
  rw [neg_div, neg_div, neg_lt_zero, neg_pos, neg_lt_zero, neg_pos, div_pos_iff_of_pos_right hσ,
    div_lt_iff₀ hσ, zero_mul, div_pos_iff_of_pos_right hden, div_lt_iff₀ hden, zero_mul]
  have hn : E * d < 0 ↔ d < 0 := by
    constructor
    · intro h
      by_contra h'
      nlinarith [mul_nonneg hE.le (not_lt.mp h')]
    · exact mul_neg_of_pos_of_neg hE
  exact ⟨mul_pos_iff_of_pos_left hE, hn, mul_pos_iff_of_pos_left hE, hn⟩

/-- **Pin risk: the delta at the strike explodes near expiry** (Step 6). With the share at the
strike, `S = K > 0`, volatility `σ > 0` and any rates `r`, `q`, the cash digital's delta grows
without limit as the time left `T` shrinks to zero, although the payout never exceeds $1. -/
theorem cash_digital_delta_at_strike_unbounded_near_expiry
    (K r q σ : ℝ) (hK : 0 < K) (hσ : 0 < σ) :
    Tendsto (fun T => deriv (fun x => cashDigital x K r q σ T) K) (𝓝[>] 0) atTop := by
  set g : ℝ → ℝ := fun T => exp (-r * T) * stdNormalPDF ((r - q - σ ^ 2 / 2) * √T / σ) / (K * σ)
    with hg_def
  have hgc : Continuous g := by
    rw [hg_def]
    exact ((continuous_exp.comp (by fun_prop)).mul
      (continuous_stdNormalPDF.comp (by fun_prop))).div_const _
  have hg0 : 0 < g 0 := div_pos (mul_pos (exp_pos _) (stdNormalPDF_pos _)) (by positivity)
  have h1 : Tendsto g (𝓝[>] 0) (𝓝 (g 0)) := (hgc.tendsto 0).mono_left nhdsWithin_le_nhds
  have h2 : Tendsto (fun T : ℝ => √T) (𝓝[>] 0) (𝓝[>] 0) := by
    refine tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within _ ?_ ?_
    · have := (Real.continuous_sqrt.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
      simpa using this
    · filter_upwards [self_mem_nhdsWithin] with T hT
      exact Real.sqrt_pos.2 hT
  have h3 := h1.pos_mul_atTop hg0 (tendsto_inv_nhdsGT_zero.comp h2)
  refine h3.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with T hT
  have hT : 0 < T := hT
  rw [(hasDerivAt_cash_S K K r q σ T hK hK hσ hT).deriv]
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hd : bsD2 K K r q σ T = (r - q - σ ^ 2 / 2) * √T / σ := by
    unfold bsD2
    rw [div_self hK.ne', log_one, zero_add]
    have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
    generalize √T = s at hT2 hsT ⊢
    subst hT2
    field_simp
  simp only [hg_def, Function.comp, hd]
  field_simp

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- d₂ = (ln 1 + (0.05 - 0.02 - 0.02) · 1) / (0.20 · √1) = 0.05.
example : bsD2 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 20 := by
  norm_num [bsD2]
-- d₁ = d₂ + σ√T = 0.05 + 0.20 = 0.25.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 4 := by
  norm_num [bsD1, bsD2]
-- Delta's denominator S σ √T = 100 × 0.20 × 1 = 20.
example : (100 : ℝ) * (1 / 5) * √1 = 20 := by norm_num
-- Gamma's denominator S² σ² T = 100 × 100 × 0.04 = 400.
example : (100 : ℚ) ^ 2 * (1 / 5) ^ 2 * 1 = 400 := by norm_num
-- Vega's factor d₁ / σ = 0.25 / 0.20 = 5/4.
example : (1 / 4 : ℚ) / (1 / 5) = 5 / 4 := by norm_num
-- Theta's bracket d₁/(2T) - (r - q)/(σ√T) = 0.125 - 0.15 = -1/40.
example : (1 / 4 : ℝ) / (2 * 1) - (5 / 100 - 2 / 100) / (1 / 5 * √1) = -1 / 40 := by norm_num
-- Rho's factor √T / σ = 1 / 0.20 = 5.
example : √(1 : ℝ) / (1 / 5) = 5 := by norm_num
-- Cash crossover exponent r - q + σ²/2 = 0.05, so S* = 100 e^(-1/20) (95.122942).
example : (5 / 100 : ℚ) - 2 / 100 + (1 / 5) ^ 2 / 2 = 1 / 20 := by norm_num
-- Asset crossover exponent r - q - σ²/2 = 0.01, so the asset digital's turn is 100 e^(-1/100).
example : (5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2 = 1 / 100 := by norm_num

#print axioms cash_digital_greeks_are_bell_height_times_slope
#print axioms cash_digital_vega_and_gamma_change_sign_at_S_star
#print axioms cash_digital_delta_at_strike_unbounded_near_expiry
