-- Black-Scholes by expectation: if the finishing price is S e^((r - q - σ²/2)T + σ√T Z) with Z a standard bell-curve draw under the pricing measure, the call's discounted average payoff is S e^(-qT) N(d₁) - K e^(-rT) N(d₂), the cash leg is K e^(-rT) N(d₂) and the share leg S e^(-qT) N(d₁) with N(d₁) > N(d₂), and the average finishing price is the forward S e^((r - q)T).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Acme's price on expiry day under the pricing measure (Step 1): today's price `S`, bank rate
`r`, dividend yield `q`, volatility `σ`, time to expiry `T`, and a standard bell-curve draw `z`:
`S_T = S e^((r - q - σ²/2) T + σ√T z)`. -/
noncomputable def priceAtExpiry (S r q σ T z : ℝ) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z)

/-- The second distance `d₂ = (ln(S/K) + (r - q - σ²/2) T) / (σ√T)`; the first is
`d₁ = d₂ + σ√T`. -/
noncomputable def bsD2 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * √T)

open Set in
lemma bs_gauss_Ioi_neg (d : ℝ) :
    (gaussianReal 0 1).real (Ioi (-d)) = stdNormalCDF d := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have h : gaussianReal 0 1 = (gaussianReal 0 1).map (fun x => -x) := by
    rw [gaussianReal_map_neg]; simp
  unfold stdNormalCDF
  rw [cdf_eq_real]
  conv_lhs => rw [h]
  rw [map_measureReal_apply measurable_neg measurableSet_Ioi]
  have hs : (fun x : ℝ => -x) ⁻¹' Ioi (-d) = Iio d := by
    ext x; simp
  rw [hs]
  exact measureReal_congr Iio_ae_eq_Iic

#print axioms bs_gauss_Ioi_neg

open Set in
lemma bs_gauss_exp_indicator (b c : ℝ) :
    ∫ z, (Ioi c).indicator (fun z => exp (b * z)) z ∂(gaussianReal 0 1) =
      exp (b ^ 2 / 2) * (gaussianReal 0 1).real (Ioi (c - b)) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hpt : ∀ z, gaussianPDFReal 0 1 z • (Ioi c).indicator (fun z => exp (b * z)) z =
      exp (b ^ 2 / 2) * (Ioi c).indicator (gaussianPDFReal b 1) z := by
    intro z
    by_cases hz : z ∈ Ioi c
    · rw [indicator_of_mem hz, indicator_of_mem hz, smul_eq_mul, gaussianPDFReal,
        gaussianPDFReal]
      have e : exp (-(z - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))) * exp (b * z) =
          exp (b ^ 2 / 2) * exp (-(z - b) ^ 2 / (2 * ((1 : NNReal) : ℝ))) := by
        rw [← exp_add, ← exp_add]; congr 1; push_cast; ring
      calc _ = (√(2 * π * ((1 : NNReal) : ℝ)))⁻¹ *
            (exp (-(z - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))) * exp (b * z)) := by ring
        _ = _ := by rw [e]; ring
    · simp [indicator_of_notMem hz]
  simp_rw [hpt]
  rw [integral_const_mul, integral_indicator measurableSet_Ioi]
  congr 1
  have h1 : (gaussianReal b 1).real (Ioi c) = ∫ z in Ioi c, gaussianPDFReal b 1 z := by
    rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
      ENNReal.toReal_ofReal]
    exact setIntegral_nonneg measurableSet_Ioi (fun x _ => gaussianPDFReal_nonneg _ _ x)
  rw [← h1]
  have h2 : gaussianReal b 1 = (gaussianReal 0 1).map (· + b) := by
    rw [gaussianReal_map_add_const]; simp
  rw [h2, map_measureReal_apply (measurable_add_const b) measurableSet_Ioi]
  congr 1
  ext x; simp [sub_lt_iff_lt_add]

#print axioms bs_gauss_exp_indicator

lemma bs_cdf_strictMono {x y : ℝ} (h : x < y) : stdNormalCDF x < stdNormalCDF y := by
  unfold stdNormalCDF
  rw [cdf_eq_real, cdf_eq_real]
  have hsub : Set.Iic x ⊆ Set.Iic y := Set.Iic_subset_Iic.mpr h.le
  have hd := measureReal_sdiff (μ := gaussianReal 0 1) hsub measurableSet_Iic
  have hset : Set.Iic y \ Set.Iic x = Set.Ioc x y := by
    ext z; simp [and_comm]
  rw [hset] at hd
  have hpos : 0 < (gaussianReal 0 1).real (Set.Ioc x y) := by
    rw [measureReal_def]
    apply ENNReal.toReal_pos
    · intro h0
      have := gaussianReal_absolutelyContinuous' 0 (v := 1) one_ne_zero h0
      rw [Real.volume_Ioc] at this
      simp at this; linarith
    · finiteness
  linarith

#print axioms bs_cdf_strictMono

lemma bs_price_eq (S r q σ T z : ℝ) :
    priceAtExpiry S r q σ T z = S * exp ((r - q - σ ^ 2 / 2) * T) * exp (σ * √T * z) := by
  rw [priceAtExpiry, exp_add]; ring

#print axioms bs_price_eq

lemma bs_event (S K r q σ T z : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K < priceAtExpiry S r q σ T z ↔ -bsD2 S K r q σ T < z := by
  have hb : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hL : log (K / S) = -log (S / K) := by
    rw [← Real.log_inv, inv_div]
  rw [priceAtExpiry, bsD2, ← div_lt_iff₀' hS, ← Real.log_lt_iff_lt_exp (div_pos hK hS), hL,
    ← neg_div, div_lt_iff₀ hb]
  constructor <;> intro h <;> linarith

#print axioms bs_event

open Set in
lemma bs_event_set (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    {z | K < priceAtExpiry S r q σ T z} = Ioi (-bsD2 S K r q σ T) := by
  ext z; simp only [mem_ofPred_eq, mem_Ioi]; exact bs_event S K r q σ T z hS hK hσ hT

#print axioms bs_event_set

lemma bs_cash_gauss (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (gaussianReal 0 1).real {z | K < priceAtExpiry S r q σ T z} = stdNormalCDF (bsD2 S K r q σ T) := by
  rw [bs_event_set S K r q σ T hS hK hσ hT, bs_gauss_Ioi_neg]

#print axioms bs_cash_gauss

open Set in
lemma bs_share_fun (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (fun z => if K < priceAtExpiry S r q σ T z then priceAtExpiry S r q σ T z else 0) =
      fun z => S * exp ((r - q - σ ^ 2 / 2) * T) *
        (Ioi (-bsD2 S K r q σ T)).indicator (fun z => exp (σ * √T * z)) z := by
  funext z
  by_cases h : -bsD2 S K r q σ T < z
  · have h' := (bs_event S K r q σ T z hS hK hσ hT).mpr h
    rw [ite_eq_left h', indicator_of_mem (show z ∈ Ioi _ from h), bs_price_eq]
  · have h' : ¬ K < priceAtExpiry S r q σ T z := fun h' => h ((bs_event S K r q σ T z hS hK hσ hT).mp h')
    rw [ite_eq_right h', indicator_of_notMem (show z ∉ Ioi _ from h), mul_zero]

#print axioms bs_share_fun

lemma bs_share_integrable (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Integrable (fun z => if K < priceAtExpiry S r q σ T z then priceAtExpiry S r q σ T z else 0)
      (gaussianReal 0 1) := by
  rw [bs_share_fun S K r q σ T hS hK hσ hT]
  exact ((integrable_exp_mul_gaussianReal _).indicator measurableSet_Ioi).const_mul _

#print axioms bs_share_integrable

lemma bs_share_gauss (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-r * T) * ∫ z, (if K < priceAtExpiry S r q σ T z then priceAtExpiry S r q σ T z else 0)
      ∂(gaussianReal 0 1) =
        S * exp (-q * T) * stdNormalCDF (bsD2 S K r q σ T + σ * √T) := by
  rw [bs_share_fun S K r q σ T hS hK hσ hT, integral_const_mul, bs_gauss_exp_indicator,
    show -bsD2 S K r q σ T - σ * √T = -(bsD2 S K r q σ T + σ * √T) by ring, bs_gauss_Ioi_neg]
  have hb : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, Real.sq_sqrt hT.le]
  rw [hb]
  have he : exp (-r * T) * exp ((r - q - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2) = exp (-q * T) := by
    rw [← exp_add, ← exp_add]; congr 1; ring
  calc _ = S * (exp (-r * T) * exp ((r - q - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2)) *
        stdNormalCDF (bsD2 S K r q σ T + σ * √T) := by ring
    _ = _ := by rw [he]

#print axioms bs_share_gauss

lemma bs_measurable_price (S r q σ T : ℝ) : Measurable (priceAtExpiry S r q σ T) := by
  unfold priceAtExpiry; fun_prop

#print axioms bs_measurable_price


/-- **Black-Scholes by expectation** (The formula; Why it works, Steps 1 to 5). Under the pricing
measure `Q`, let Acme's price follow geometric Brownian motion with the bank rate `r`, dividend
yield `q` and volatility `σ > 0` held fixed, so that on expiry day, after `T > 0` years, it is
`S_T = S e^((r - q - σ²/2) T + σ√T Z)` with `Z` a standard bell-curve draw; today's price is
`S > 0` and the strike is `K > 0`; the call is used on expiry day only, and one rate `r` does the
growing and the discounting. Then the call's price, its average payoff `max(S_T - K, 0)` under `Q`
shrunk back to today by `e^(-rT)`, is `S e^(-qT) N(d₁) - K e^(-rT) N(d₂)`. -/
theorem black_scholes_call_is_discounted_average_payoff
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-r * T) * ∫ ω, max (priceAtExpiry S r q σ T (Z ω) - K) 0 ∂Q =
      S * exp (-q * T) * stdNormalCDF (bsD2 S K r q σ T + σ * √T)
        - K * exp (-r * T) * stdNormalCDF (bsD2 S K r q σ T) := by
  have hmeas : Measurable (fun z => max (priceAtExpiry S r q σ T z - K) 0) :=
    ((bs_measurable_price S r q σ T).sub_const K).max measurable_const
  have htr : ∫ ω, max (priceAtExpiry S r q σ T (Z ω) - K) 0 ∂Q =
      ∫ z, max (priceAtExpiry S r q σ T z - K) 0 ∂(gaussianReal 0 1) :=
    hZ.integral_comp (f := fun z => max (priceAtExpiry S r q σ T z - K) 0)
      hmeas.aestronglyMeasurable
  have hpt : (fun z => max (priceAtExpiry S r q σ T z - K) 0) = fun z =>
      (if K < priceAtExpiry S r q σ T z then priceAtExpiry S r q σ T z else 0) -
        (Set.Ioi (-bsD2 S K r q σ T)).indicator (fun _ => K) z := by
    funext z
    by_cases h : K < priceAtExpiry S r q σ T z
    · have h' := (bs_event S K r q σ T z hS hK hσ hT).mp h
      rw [ite_eq_left h, Set.indicator_of_mem (show z ∈ Set.Ioi _ from h'), max_eq_left (by linarith)]
    · have h' : ¬ -bsD2 S K r q σ T < z := fun h' => h ((bs_event S K r q σ T z hS hK hσ hT).mpr h')
      rw [ite_eq_right h, Set.indicator_of_notMem (show z ∉ Set.Ioi _ from h'), max_eq_right (by linarith)]
      ring
  rw [htr, hpt, integral_sub (bs_share_integrable S K r q σ T hS hK hσ hT)
    ((integrable_const K).indicator measurableSet_Ioi), integral_indicator_const _ measurableSet_Ioi,
    mul_sub, bs_share_gauss S K r q σ T hS hK hσ hT, bs_gauss_Ioi_neg, smul_eq_mul]
  ring

/-- **The two legs, each with its own weight** (Steps 2, 3 and 4). In the same model, with
`S > 0`, `K > 0`, `σ > 0`, `T > 0` and `Z` a standard bell-curve draw under `Q`: the cash leg,
`K` paid only when Acme finishes above the strike, is worth `K e^(-rT) Q(S_T > K) = K e^(-rT) N(d₂)`
today; the share leg, one share received only when Acme finishes above the strike, is worth
`e^(-rT)` times the average of `S_T · [S_T > K]`, which is `S e^(-qT) N(d₁)`; and the chance
counted in shares is always the larger, `N(d₁) > N(d₂)`. -/
theorem black_scholes_cash_leg_and_share_leg
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    K * exp (-r * T) * Q.real {ω | K < priceAtExpiry S r q σ T (Z ω)} =
        K * exp (-r * T) * stdNormalCDF (bsD2 S K r q σ T) ∧
      exp (-r * T) * ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω) then
          priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
        S * exp (-q * T) * stdNormalCDF (bsD2 S K r q σ T + σ * √T) ∧
      stdNormalCDF (bsD2 S K r q σ T) < stdNormalCDF (bsD2 S K r q σ T + σ * √T) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [hZ.measureReal_eq (p := fun z => K < priceAtExpiry S r q σ T z)
      (by rw [bs_event_set S K r q σ T hS hK hσ hT]; exact measurableSet_Ioi),
      bs_cash_gauss S K r q σ T hS hK hσ hT]
  · have hmeas : Measurable
        (fun z => if K < priceAtExpiry S r q σ T z then priceAtExpiry S r q σ T z else 0) := by
      rw [bs_share_fun S K r q σ T hS hK hσ hT]
      exact ((measurable_exp.comp (measurable_const_mul _)).indicator measurableSet_Ioi).const_mul _
    have htr : ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω) then
          priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
        ∫ z, (if K < priceAtExpiry S r q σ T z then priceAtExpiry S r q σ T z else 0)
          ∂(gaussianReal 0 1) :=
      hZ.integral_comp
        (f := fun z => if K < priceAtExpiry S r q σ T z then priceAtExpiry S r q σ T z else 0)
        hmeas.aestronglyMeasurable
    rw [htr, bs_share_gauss S K r q σ T hS hK hσ hT]
  · apply bs_cdf_strictMono
    have : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
    linarith

/-- **The average finish is the forward** (Step 1). In the same model, with `S > 0`, `σ > 0`,
`T > 0` and `Z` a standard bell-curve draw under `Q`, the average finishing price is the forward
price `S e^((r - q) T)`, and shrunk back to today by `e^(-rT)` it is `S e^(-qT)`, the cost today
of holding one share at expiry: the discounted share is a fair game. -/
theorem average_finish_is_forward
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    ∫ ω, priceAtExpiry S r q σ T (Z ω) ∂Q = S * exp ((r - q) * T) ∧
      exp (-r * T) * ∫ ω, priceAtExpiry S r q σ T (Z ω) ∂Q = S * exp (-q * T) := by
  have hm : ∫ ω, exp (σ * √T * Z ω) ∂Q = exp (σ ^ 2 * T / 2) := by
    have h := mgf_gaussianReal hZ (σ * √T)
    rw [mgf] at h
    rw [h, mul_pow, Real.sq_sqrt hT.le]
    congr 1; push_cast; ring
  have h1 : ∫ ω, priceAtExpiry S r q σ T (Z ω) ∂Q = S * exp ((r - q) * T) := by
    simp_rw [bs_price_eq]
    rw [integral_const_mul, hm, mul_assoc, ← exp_add]
    congr 2; ring
  refine ⟨h1, ?_⟩
  rw [h1]
  calc _ = S * (exp (-r * T) * exp ((r - q) * T)) := by ring
    _ = _ := by rw [← exp_add]; congr 2; ring

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- Growth under Q: r - q - σ²/2 = 0.05 - 0.02 - 0.02 = 0.01.
example : (5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2 = 1 / 100 := by norm_num
-- d₂ = (ln(100/100) + 0.01 · 1) / (0.20 · √1) = 0.05.
example : (log (100 / 100) + ((5 / 100 : ℝ) - 2 / 100 - (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1)
    = 1 / 20 := by norm_num
-- d₁ = d₂ + σ√T = 0.05 + 0.20 = 0.25.
example : (1 / 20 : ℚ) + 1 / 5 = 1 / 4 := by norm_num
-- Step 2, the light switch at $120: share in, $100 out, net $20, the payoff max(120 - 100, 0).
example : max ((120 : ℤ) - 100) 0 = 120 * 1 - 100 * 1 := by decide
-- Step 2, the light switch at $80: switch off, net $0, the payoff max(80 - 100, 0).
example : max ((80 : ℤ) - 100) 0 = 80 * 0 - 100 * 0 := by decide
-- Step 1: up 20 percent then down 20 percent leaves 96 percent.
example : (6 / 5 : ℚ) * (4 / 5) = 96 / 100 := by norm_num

#print axioms black_scholes_call_is_discounted_average_payoff
#print axioms black_scholes_cash_leg_and_share_leg
#print axioms average_finish_is_forward
