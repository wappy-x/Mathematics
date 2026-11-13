-- Black-Scholes put: if the finishing price is S e^((r - q - σ²/2)T + σ√T Z) with Z a standard bell-curve draw under the pricing measure, the put's discounted average payoff is K e^(-rT) N(-d₂) - S e^(-qT) N(-d₁), its cash half is K e^(-rT) N(-d₂) and its share half S e^(-qT) N(-d₁) with N(-d₁) < N(-d₂), and the put equals the call minus S e^(-qT) plus K e^(-rT).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Acme's price on expiry day in the pricing world: today's price `S`, bank rate `r`, dividend
yield `q`, volatility `σ`, time to expiry `T`, and a standard bell-curve draw `z`:
`S_T = S e^((r - q - σ²/2) T + σ√T z)`. -/
noncomputable def priceAtExpiry (S r q σ T z : ℝ) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z)

/-- The cash-side distance `d₂ = (ln(S/K) + (r - q - σ²/2) T) / (σ√T)`; the share-side distance
is `d₁ = d₂ + σ√T`. -/
noncomputable def bsD2 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * √T)

lemma bs_gauss_singleton (a : ℝ) : gaussianReal 0 1 {a} = 0 :=
  gaussianReal_absolutelyContinuous 0 one_ne_zero (Real.volume_singleton)

lemma bs_real_Iio (a : ℝ) : (gaussianReal 0 1).real (Set.Iio a) = stdNormalCDF a := by
  rw [stdNormalCDF, cdf_eq_real]
  exact measureReal_congr (Iio_ae_eq_Iic' (bs_gauss_singleton a))

lemma bs_pdf_tilt (s x : ℝ) :
    gaussianPDFReal 0 1 x * exp (s * x) = exp (s ^ 2 / 2) * gaussianPDFReal s 1 x := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  rw [mul_assoc, ← exp_add, mul_left_comm, ← exp_add]
  congr 2
  ring

lemma bs_tilt_integral (s a : ℝ) :
    ∫ x, (Set.Iio a).indicator (fun x => exp (s * x)) x ∂(gaussianReal 0 1)
      = exp (s ^ 2 / 2) * stdNormalCDF (a - s) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have h1 : (fun x => gaussianPDFReal 0 1 x • (Set.Iio a).indicator (fun x => exp (s * x)) x)
      = (Set.Iio a).indicator (fun x => exp (s ^ 2 / 2) * gaussianPDFReal s 1 x) := by
    funext x
    by_cases hx : x ∈ Set.Iio a
    · simp only [Set.indicator_of_mem hx, smul_eq_mul, bs_pdf_tilt]
    · simp [Set.indicator_of_notMem hx]
  rw [h1, integral_indicator measurableSet_Iio, integral_const_mul]
  congr 1
  have h2 : ∫ x in Set.Iio a, gaussianPDFReal s 1 x = (gaussianReal s 1).real (Set.Iio a) := by
    rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero, ENNReal.toReal_ofReal]
    exact setIntegral_nonneg measurableSet_Iio (fun x _ => gaussianPDFReal_nonneg _ _ _)
  rw [h2, ← bs_real_Iio]
  have h3 : gaussianReal s 1 = (gaussianReal 0 1).map (· + s) := by
    rw [gaussianReal_map_add_const, zero_add]
  rw [h3, map_measureReal_apply (by fun_prop) measurableSet_Iio, Set.preimage_add_const_Iio]

lemma bs_measurable_price (S r q σ T : ℝ) : Measurable (priceAtExpiry S r q σ T) := by
  unfold priceAtExpiry; fun_prop

lemma bs_price_lt_iff (S K r q σ T x : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    priceAtExpiry S r q σ T x < K ↔ x < -bsD2 S K r q σ T := by
  have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  unfold priceAtExpiry bsD2
  have key : ∀ y : ℝ, S * exp y < K ↔ y < log K - log S := by
    intro y
    rw [← lt_div_iff₀' hS, ← lt_log_iff_exp_lt (div_pos hK hS), log_div hK.ne' hS.ne']
  rw [key, log_div hS.ne' hK.ne', ← neg_div, lt_div_iff₀ hs]
  constructor <;> intro h <;> linarith

lemma bs_set_eq (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    {x | priceAtExpiry S r q σ T x < K} = Set.Iio (-bsD2 S K r q σ T) := by
  ext x; exact bs_price_lt_iff S K r q σ T x hS hK hσ hT

lemma bs_discount (S r q σ T : ℝ) (hT : 0 < T) :
    exp (-r * T) * (S * exp ((r - q - σ ^ 2 / 2) * T) * exp ((σ * √T) ^ 2 / 2))
      = S * exp (-q * T) := by
  have h : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, sq_sqrt hT.le]
  rw [h, show exp (-r * T) * (S * exp ((r - q - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2))
      = S * (exp (-r * T) * exp ((r - q - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2)) by ring,
    ← exp_add, ← exp_add]
  congr 2
  ring

lemma bs_price_eq (S r q σ T : ℝ) :
    priceAtExpiry S r q σ T = fun x => S * exp ((r - q - σ ^ 2 / 2) * T) * exp (σ * √T * x) := by
  funext x
  rw [priceAtExpiry, exp_add]
  ring

lemma bs_price_integrable (S r q σ T : ℝ) :
    Integrable (priceAtExpiry S r q σ T) (gaussianReal 0 1) := by
  rw [bs_price_eq]
  exact (integrable_exp_mul_gaussianReal _).const_mul _

lemma bs_price_integral (S r q σ T : ℝ) :
    ∫ x, priceAtExpiry S r q σ T x ∂(gaussianReal 0 1)
      = S * exp ((r - q - σ ^ 2 / 2) * T) * exp ((σ * √T) ^ 2 / 2) := by
  rw [bs_price_eq, integral_const_mul]
  have h := congrFun (mgf_fun_id_gaussianReal (μ := 0) (v := 1)) (σ * √T)
  simp only [mgf, zero_mul, NNReal.coe_one, one_mul, zero_add] at h
  rw [h]

lemma bs_share_ind (S K r q σ T : ℝ) :
    ∫ x, (Set.Iio (-bsD2 S K r q σ T)).indicator (priceAtExpiry S r q σ T) x ∂(gaussianReal 0 1)
      = S * exp ((r - q - σ ^ 2 / 2) * T) * exp ((σ * √T) ^ 2 / 2)
          * stdNormalCDF (-(bsD2 S K r q σ T + σ * √T)) := by
  have h : (Set.Iio (-bsD2 S K r q σ T)).indicator (priceAtExpiry S r q σ T)
      = fun x => S * exp ((r - q - σ ^ 2 / 2) * T) *
          (Set.Iio (-bsD2 S K r q σ T)).indicator (fun x => exp (σ * √T * x)) x := by
    funext x
    by_cases hx : x ∈ Set.Iio (-bsD2 S K r q σ T)
    · simp only [Set.indicator_of_mem hx, bs_price_eq]
    · simp [Set.indicator_of_notMem hx]
  rw [h, integral_const_mul, bs_tilt_integral, neg_add, ← sub_eq_add_neg]
  ring

lemma bs_cdf_strictMono : StrictMono stdNormalCDF := by
  intro a b hab
  have hlt : gaussianReal 0 1 (Set.Iic a) < gaussianReal 0 1 (Set.Iic b) := by
    rw [← Set.Iic_union_Ioc_eq_Iic hab.le,
      measure_union (Set.Iic_disjoint_Ioc le_rfl) measurableSet_Ioc]
    refine ENNReal.lt_add_right (measure_ne_top _ _) ?_
    intro h0
    have := gaussianReal_absolutelyContinuous' 0 one_ne_zero h0
    rw [Real.volume_Ioc, ENNReal.ofReal_eq_zero] at this
    linarith
  rw [← ofReal_cdf, ← ofReal_cdf] at hlt
  exact (ENNReal.ofReal_lt_ofReal_iff'.1 hlt).1

lemma bs_cdf_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  rw [← bs_real_Iio x, stdNormalCDF, cdf_eq_real]
  have hmap : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  rw [← hmap, map_measureReal_apply measurable_neg measurableSet_Iic, hmap,
    ← probReal_compl_eq_one_sub measurableSet_Iio]
  congr 1
  ext y
  simp

lemma bs_put_on_gaussian (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    ∫ x, max (K - priceAtExpiry S r q σ T x) 0 ∂(gaussianReal 0 1)
      = K * stdNormalCDF (-bsD2 S K r q σ T)
        - S * exp ((r - q - σ ^ 2 / 2) * T) * exp ((σ * √T) ^ 2 / 2)
          * stdNormalCDF (-(bsD2 S K r q σ T + σ * √T)) := by
  have h : (fun x => max (K - priceAtExpiry S r q σ T x) 0)
      = fun x => (Set.Iio (-bsD2 S K r q σ T)).indicator (fun _ => K) x
          - (Set.Iio (-bsD2 S K r q σ T)).indicator (priceAtExpiry S r q σ T) x := by
    funext x
    by_cases hx : x ∈ Set.Iio (-bsD2 S K r q σ T)
    · have hlt := (bs_price_lt_iff S K r q σ T x hS hK hσ hT).2 hx
      rw [Set.indicator_of_mem hx, Set.indicator_of_mem hx, max_eq_left (by linarith)]
    · have hlt : ¬ priceAtExpiry S r q σ T x < K :=
        fun h => hx ((bs_price_lt_iff S K r q σ T x hS hK hσ hT).1 h)
      rw [Set.indicator_of_notMem hx, Set.indicator_of_notMem hx, max_eq_right (by linarith)]
      ring
  rw [h, integral_sub ((integrable_const K).indicator measurableSet_Iio)
      ((bs_price_integrable S r q σ T).indicator measurableSet_Iio),
    integral_indicator_const _ measurableSet_Iio, bs_share_ind, bs_real_Iio, smul_eq_mul, mul_comm K]

#print axioms bs_gauss_singleton
#print axioms bs_real_Iio
#print axioms bs_pdf_tilt
#print axioms bs_tilt_integral
#print axioms bs_measurable_price
#print axioms bs_price_lt_iff
#print axioms bs_set_eq
#print axioms bs_discount
#print axioms bs_price_eq
#print axioms bs_price_integrable
#print axioms bs_price_integral
#print axioms bs_share_ind
#print axioms bs_cdf_strictMono
#print axioms bs_cdf_neg
#print axioms bs_put_on_gaussian

/-- **Black-Scholes put** (The formula; Why it works, Steps 0 to 4). Under the pricing measure
`Q`, Acme wanders with one fixed volatility `σ > 0`, with the bank rate `r` and the dividend yield
`q` held constant, so that on expiry day, after `T > 0` years, its price is
`S_T = S e^((r - q - σ²/2) T + σ√T Z)` with `Z` a standard bell-curve draw; today's price is
`S > 0`, the strike is `K > 0`, and the put is used on expiry day only. Then the put's price, its
average payoff `max(K - S_T, 0)` shrunk back to today by `e^(-rT)`, is
`K e^(-rT) N(-d₂) - S e^(-qT) N(-d₁)`: the strike cash you might collect minus the share you might
hand over, each weighted by its own chance. -/
theorem black_scholes_put_is_discounted_average_payoff
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-r * T) * ∫ ω, max (K - priceAtExpiry S r q σ T (Z ω)) 0 ∂Q =
      K * exp (-r * T) * stdNormalCDF (-bsD2 S K r q σ T)
        - S * exp (-q * T) * stdNormalCDF (-(bsD2 S K r q σ T + σ * √T)) := by
  have hI : ∫ ω, max (K - priceAtExpiry S r q σ T (Z ω)) 0 ∂Q
      = ∫ x, max (K - priceAtExpiry S r q σ T x) 0 ∂(gaussianReal 0 1) :=
    hZ.integral_comp (f := fun x => max (K - priceAtExpiry S r q σ T x) 0)
      ((measurable_const.sub (bs_measurable_price S r q σ T)).max measurable_const).aestronglyMeasurable
  rw [hI, bs_put_on_gaussian S K r q σ T hS hK hσ hT, mul_sub, ← bs_discount S r q σ T hT]
  ring

/-- **The two halves, each with its own chance** (Steps 1, 2 and 3). In the same model, with
`S > 0`, `K > 0`, `σ > 0`, `T > 0` and `Z` a standard bell-curve draw under `Q`: the cash half,
`K` collected only when Acme finishes below the strike, is worth
`K e^(-rT) Q(S_T < K) = K e^(-rT) N(-d₂)` today; the share half, one share handed over only when
Acme finishes below the strike, is worth `e^(-rT)` times the average of `S_T · [S_T < K]`, which
is `S e^(-qT) N(-d₁)`; and the chance counted in shares is always the smaller,
`N(-d₁) < N(-d₂)`. -/
theorem black_scholes_put_cash_half_and_share_half
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    K * exp (-r * T) * Q.real {ω | priceAtExpiry S r q σ T (Z ω) < K} =
        K * exp (-r * T) * stdNormalCDF (-bsD2 S K r q σ T) ∧
      exp (-r * T) * ∫ ω, (if priceAtExpiry S r q σ T (Z ω) < K then
          priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
        S * exp (-q * T) * stdNormalCDF (-(bsD2 S K r q σ T + σ * √T)) ∧
      stdNormalCDF (-(bsD2 S K r q σ T + σ * √T)) < stdNormalCDF (-bsD2 S K r q σ T) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [hZ.measureReal_eq (p := fun x => priceAtExpiry S r q σ T x < K)
      (measurableSet_lt (bs_measurable_price S r q σ T) measurable_const),
      bs_set_eq S K r q σ T hS hK hσ hT, bs_real_Iio]
  · have hpt : ∀ ω, (if priceAtExpiry S r q σ T (Z ω) < K then priceAtExpiry S r q σ T (Z ω) else 0)
        = (Set.Iio (-bsD2 S K r q σ T)).indicator (priceAtExpiry S r q σ T) (Z ω) := by
      intro ω
      by_cases h : priceAtExpiry S r q σ T (Z ω) < K
      · rw [Set.indicator_of_mem ((bs_price_lt_iff S K r q σ T _ hS hK hσ hT).1 h)]
        simp [h]
      · rw [Set.indicator_of_notMem
          (fun hx => h ((bs_price_lt_iff S K r q σ T _ hS hK hσ hT).2 hx))]
        simp [h]
    simp_rw [hpt]
    have hI : ∫ ω, (Set.Iio (-bsD2 S K r q σ T)).indicator (priceAtExpiry S r q σ T) (Z ω) ∂Q
        = ∫ x, (Set.Iio (-bsD2 S K r q σ T)).indicator (priceAtExpiry S r q σ T) x
            ∂(gaussianReal 0 1) :=
      hZ.integral_comp ((bs_measurable_price S r q σ T).indicator
        measurableSet_Iio).aestronglyMeasurable
    rw [hI, bs_share_ind, ← mul_assoc, ← mul_assoc, ← bs_discount S r q σ T hT]
    ring
  · apply bs_cdf_strictMono
    have : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
    linarith

/-- **The put from the call, with no bell curve** (The formula; Step 4). The bell curve is
symmetric, `N(-x) = 1 - N(x)` for every `x`; for any finishing price `x`,
`max(K - x, 0) - max(x - K, 0) = K - x`; and in the same model, with `S > 0`, `K > 0`, `σ > 0`,
`T > 0` and `Z` a standard bell-curve draw under `Q`, the put's price equals the call's price at
the same strike and date, minus `S e^(-qT)`, plus `K e^(-rT)`: put-call parity. -/
theorem black_scholes_put_from_call_by_parity
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    (∀ x : ℝ, stdNormalCDF (-x) = 1 - stdNormalCDF x) ∧
      (∀ x : ℝ, max (K - x) 0 - max (x - K) 0 = K - x) ∧
      exp (-r * T) * ∫ ω, max (K - priceAtExpiry S r q σ T (Z ω)) 0 ∂Q =
        exp (-r * T) * ∫ ω, max (priceAtExpiry S r q σ T (Z ω) - K) 0 ∂Q
          - S * exp (-q * T) + K * exp (-r * T) := by
  have hmax : ∀ x : ℝ, max (K - x) 0 - max (x - K) 0 = K - x := by
    intro x
    rcases le_total x K with h | h
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]
      ring
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]
      ring
  refine ⟨bs_cdf_neg, hmax, ?_⟩
  have hP := bs_price_integrable S r q σ T
  have hIput : ∫ ω, max (K - priceAtExpiry S r q σ T (Z ω)) 0 ∂Q
      = ∫ x, max (K - priceAtExpiry S r q σ T x) 0 ∂(gaussianReal 0 1) :=
    hZ.integral_comp (f := fun x => max (K - priceAtExpiry S r q σ T x) 0)
      ((measurable_const.sub (bs_measurable_price S r q σ T)).max measurable_const).aestronglyMeasurable
  have hIcall : ∫ ω, max (priceAtExpiry S r q σ T (Z ω) - K) 0 ∂Q
      = ∫ x, max (priceAtExpiry S r q σ T x - K) 0 ∂(gaussianReal 0 1) :=
    hZ.integral_comp (f := fun x => max (priceAtExpiry S r q σ T x - K) 0)
      (((bs_measurable_price S r q σ T).sub measurable_const).max measurable_const).aestronglyMeasurable
  have hcall_int : Integrable (fun x => max (priceAtExpiry S r q σ T x - K) 0) (gaussianReal 0 1) :=
    (hP.sub (integrable_const K)).sup (integrable_const 0)
  have hsplit : (fun x => max (K - priceAtExpiry S r q σ T x) 0)
      = fun x => max (priceAtExpiry S r q σ T x - K) 0 + (K - priceAtExpiry S r q σ T x) := by
    funext x
    linarith [hmax (priceAtExpiry S r q σ T x)]
  have hKP : Integrable (fun x => K - priceAtExpiry S r q σ T x) (gaussianReal 0 1) :=
    (integrable_const K).sub hP
  rw [hIput, hIcall, hsplit, integral_add hcall_int hKP,
    integral_sub (integrable_const K) hP, integral_const, bs_price_integral, probReal_univ,
    one_smul, mul_add, mul_sub, bs_discount S r q σ T hT]
  ring

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- Pretend-world drift: r - q - σ²/2 = 0.05 - 0.02 - 0.02 = 0.01.
example : (5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2 = 1 / 100 := by norm_num
-- d₂ = (ln(100/100) + 0.01 · 1) / (0.20 · √1) = 0.05.
example : (log (100 / 100) + ((5 / 100 : ℝ) - 2 / 100 - (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1)
    = 1 / 20 := by norm_num
-- d₁ = d₂ + σ√T = 0.05 + 0.20 = 0.25.
example : (1 / 20 : ℚ) + 1 / 5 = 1 / 4 := by norm_num
-- Acme at $80: the put pays $20; the light switch is on, $100 collected, an $80 share handed over.
example : max ((100 : ℤ) - 80) 0 = 20 ∧ max ((100 : ℤ) - 80) 0 = 100 * 1 - 80 * 1 := by decide
-- Acme at $120: the ticket is thrown away; the light switch is off.
example : max ((100 : ℤ) - 120) 0 = 0 ∧ max ((100 : ℤ) - 120) 0 = 100 * 0 - 120 * 0 := by decide
-- Step 4, the parity identity checked on each side of the strike, at $80 and at $120.
example : max ((100 : ℤ) - 80) 0 - max (80 - 100) 0 = 100 - 80 := by decide
example : max ((100 : ℤ) - 120) 0 - max (120 - 100) 0 = 100 - 120 := by decide
-- Break even at expiry: 100 - 6.33 = 93.67.
example : (100 : ℚ) - 633 / 100 = 9367 / 100 := by norm_num

#print axioms black_scholes_put_is_discounted_average_payoff
#print axioms black_scholes_put_cash_half_and_share_half
#print axioms black_scholes_put_from_call_by_parity
