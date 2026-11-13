-- Black–Scholes call: if Acme's price on expiry day is S e^((r - q - σ²/2)T + σ√T Z) with Z a standard bell-curve draw in the pretend world, the call's discounted average payoff is S e^(-qT) N(d₁) - K e^(-rT) N(d₂), the payoff splits into a share half minus a cash half, the cash half is K e^(-rT) N(d₂), the share half is S e^(-qT) N(d₁), and N(d₁) > N(d₂).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Acme's price on expiry day in the pretend world (Step 2): today's price `S`, bank rate `r`,
dividend yield `q`, volatility `σ`, time to expiry `T` in years, and a standard bell-curve draw
`z`: `S_T = S e^((r - q - σ²/2) T + σ√T z)`. -/
noncomputable def priceAtExpiry (S r q σ T z : ℝ) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z)

/-- The card's `d₂ = (ln(S/K) + (r - q - σ²/2) T) / (σ√T)`; then `d₁ = d₂ + σ√T`. -/
noncomputable def bsD2 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * √T)

lemma bs_gauss_real_Ioi (c : ℝ) :
    (gaussianReal 0 1).real (Set.Ioi (-c)) = stdNormalCDF c := by
  have := nullSingletonClass_gaussianReal (μ := (0:ℝ)) (v := 1) one_ne_zero
  have hmap : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
    simpa using gaussianReal_map_neg (μ := (0:ℝ)) (v := 1)
  calc (gaussianReal 0 1).real (Set.Ioi (-c))
      = ((gaussianReal 0 1).map (fun x => -x)).real (Set.Ioi (-c)) := by rw [hmap]
    _ = (gaussianReal 0 1).real ((fun x : ℝ => -x) ⁻¹' Set.Ioi (-c)) :=
        map_measureReal_apply measurable_neg measurableSet_Ioi
    _ = (gaussianReal 0 1).real (Set.Iio c) := by
        congr 1; ext x; simp
    _ = (gaussianReal 0 1).real (Set.Iic c) := measureReal_congr Iio_ae_eq_Iic
    _ = stdNormalCDF c := (cdf_eq_real _ _).symm

#print axioms bs_gauss_real_Ioi

lemma bs_pdf_tilt (b z : ℝ) :
    gaussianPDFReal 0 1 z * exp (b * z) = exp (b ^ 2 / 2) * gaussianPDFReal b 1 z := by
  simp only [gaussianPDFReal, NNReal.coe_one]
  rw [mul_assoc, ← exp_add, mul_left_comm, ← exp_add]
  congr 2
  ring

#print axioms bs_pdf_tilt

lemma bs_gauss_tilted_tail (b c : ℝ) :
    ∫ z, (Set.Ioi (-c)).indicator (fun z => exp (b * z)) z ∂(gaussianReal 0 1)
      = exp (b ^ 2 / 2) * stdNormalCDF (c + b) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hfun : ∀ z, gaussianPDFReal 0 1 z • (Set.Ioi (-c)).indicator (fun z => exp (b * z)) z
      = exp (b ^ 2 / 2) * (Set.Ioi (-c)).indicator (fun z => gaussianPDFReal b 1 z) z := by
    intro z
    by_cases hz : z ∈ Set.Ioi (-c)
    · simp only [Set.indicator_of_mem hz, smul_eq_mul, bs_pdf_tilt]
    · simp [Set.indicator_of_notMem hz]
  simp_rw [hfun]
  rw [integral_const_mul, integral_indicator measurableSet_Ioi]
  have h2 : (gaussianReal b 1).real (Set.Ioi (-c))
      = ∫ z in Set.Ioi (-c), gaussianPDFReal b 1 z := by
    rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
      ENNReal.toReal_ofReal
        (setIntegral_nonneg measurableSet_Ioi fun _ _ => gaussianPDFReal_nonneg _ _ _)]
  rw [← h2]
  congr 1
  have hmap : (gaussianReal 0 1).map (· + b) = gaussianReal b 1 := by
    simpa using gaussianReal_map_add_const (μ := (0:ℝ)) (v := 1) b
  rw [← hmap, map_measureReal_apply (measurable_add_const b) measurableSet_Ioi]
  have hset : (· + b) ⁻¹' Set.Ioi (-c) = Set.Ioi (-(c + b)) := by
    ext x; simp only [Set.mem_preimage, Set.mem_Ioi]; constructor <;> intro h <;> linarith
  rw [hset, bs_gauss_real_Ioi]

#print axioms bs_gauss_tilted_tail

lemma bs_event_iff (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (z : ℝ) : K < priceAtExpiry S r q σ T z ↔ -bsD2 S K r q σ T < z := by
  have hb : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  unfold priceAtExpiry bsD2
  rw [← div_lt_iff₀' hS, ← Real.log_lt_iff_lt_exp (div_pos hK hS),
    neg_lt, lt_div_iff₀ hb, Real.log_div hK.ne' hS.ne', Real.log_div hS.ne' hK.ne']
  constructor <;> intro h <;> linarith

#print axioms bs_event_iff

lemma bs_measurable_price (S r q σ T : ℝ) : Measurable (priceAtExpiry S r q σ T) := by
  unfold priceAtExpiry; fun_prop

#print axioms bs_measurable_price

lemma bs_share_fun (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (fun z => if K < priceAtExpiry S r q σ T z then priceAtExpiry S r q σ T z else 0)
      = fun z => S * exp ((r - q - σ ^ 2 / 2) * T) *
          (Set.Ioi (-bsD2 S K r q σ T)).indicator (fun z => exp (σ * √T * z)) z := by
  funext z
  by_cases hz : -bsD2 S K r q σ T < z
  · have h := (bs_event_iff S K r q σ T hS hK hσ hT z).mpr hz
    rw [if_pos h, Set.indicator_of_mem (show z ∈ Set.Ioi _ from hz)]
    unfold priceAtExpiry; rw [exp_add]; ring
  · have h : ¬ K < priceAtExpiry S r q σ T z := fun h' =>
      hz ((bs_event_iff S K r q σ T hS hK hσ hT z).mp h')
    rw [if_neg h, Set.indicator_of_notMem (show z ∉ Set.Ioi _ from hz), mul_zero]

#print axioms bs_share_fun

lemma bs_cash_fun (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (fun z => if K < priceAtExpiry S r q σ T z then K else 0)
      = (Set.Ioi (-bsD2 S K r q σ T)).indicator (fun _ => K) := by
  funext z
  by_cases hz : -bsD2 S K r q σ T < z
  · rw [if_pos ((bs_event_iff S K r q σ T hS hK hσ hT z).mpr hz),
      Set.indicator_of_mem (show z ∈ Set.Ioi _ from hz)]
  · rw [if_neg (fun h' => hz ((bs_event_iff S K r q σ T hS hK hσ hT z).mp h')),
      Set.indicator_of_notMem (show z ∉ Set.Ioi _ from hz)]

#print axioms bs_cash_fun

lemma bs_share_Q {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    Integrable (fun ω => if K < priceAtExpiry S r q σ T (Z ω) then
        priceAtExpiry S r q σ T (Z ω) else 0) Q ∧
    exp (-r * T) * ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω) then
          priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
        S * exp (-q * T) * stdNormalCDF (bsD2 S K r q σ T + σ * √T) := by
  have hf := bs_share_fun S K r q σ T hS hK hσ hT
  have hint : Integrable (fun z => if K < priceAtExpiry S r q σ T z then
      priceAtExpiry S r q σ T z else 0) (gaussianReal 0 1) := by
    rw [hf]
    exact ((integrable_exp_mul_gaussianReal (σ * √T)).indicator measurableSet_Ioi).const_mul _
  refine ⟨hZ.integrable_comp hint, ?_⟩
  have h1 : ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω) then
        priceAtExpiry S r q σ T (Z ω) else 0) ∂Q
      = ∫ z, (if K < priceAtExpiry S r q σ T z then
        priceAtExpiry S r q σ T z else 0) ∂(gaussianReal 0 1) :=
    hZ.integral_comp hint.aestronglyMeasurable
  rw [h1, hf, integral_const_mul, bs_gauss_tilted_tail, mul_pow, sq_sqrt hT.le]
  rw [show S * exp (-q * T) = S * (exp (-r * T) * exp ((r - q - σ ^ 2 / 2) * T) *
      exp (σ ^ 2 * T / 2)) by rw [← exp_add, ← exp_add]; congr 2; ring]
  ring

#print axioms bs_share_Q

lemma bs_cash_Q {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    Integrable (fun ω => if K < priceAtExpiry S r q σ T (Z ω) then K else 0) Q ∧
    ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω) then K else 0) ∂Q
      = K * stdNormalCDF (bsD2 S K r q σ T) ∧
    Q.real {ω | K < priceAtExpiry S r q σ T (Z ω)} = stdNormalCDF (bsD2 S K r q σ T) := by
  have hf := bs_cash_fun S K r q σ T hS hK hσ hT
  have hint : Integrable (fun z => if K < priceAtExpiry S r q σ T z then K else 0)
      (gaussianReal 0 1) := by
    rw [hf]; exact (integrable_const K).indicator measurableSet_Ioi
  have hset : {z | K < priceAtExpiry S r q σ T z} = Set.Ioi (-bsD2 S K r q σ T) := by
    ext z; exact bs_event_iff S K r q σ T hS hK hσ hT z
  refine ⟨hZ.integrable_comp hint, ?_, ?_⟩
  · have h1 : ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω) then K else 0) ∂Q
        = ∫ z, (if K < priceAtExpiry S r q σ T z then K else 0) ∂(gaussianReal 0 1) :=
      hZ.integral_comp hint.aestronglyMeasurable
    rw [h1, hf, integral_indicator_const _ measurableSet_Ioi, bs_gauss_real_Ioi, smul_eq_mul,
      mul_comm]
  · rw [hZ.measureReal_eq (p := fun z => K < priceAtExpiry S r q σ T z)
      (by show MeasurableSet {z | K < priceAtExpiry S r q σ T z}
          rw [hset]; exact measurableSet_Ioi)]
    show (gaussianReal 0 1).real {z | K < priceAtExpiry S r q σ T z} = _
    rw [hset, bs_gauss_real_Ioi]

#print axioms bs_cash_Q

lemma bs_cdf_strictMono {x y : ℝ} (h : x < y) : stdNormalCDF x < stdNormalCDF y := by
  have hac := gaussianReal_absolutelyContinuous' (0 : ℝ) (v := 1) one_ne_zero
  have hpos : (gaussianReal 0 1) (Set.Ioc x y) ≠ 0 := by
    intro h0
    have h0' := hac h0
    rw [Real.volume_Ioc, ENNReal.ofReal_eq_zero] at h0'
    linarith
  have hmeas : (cdf (gaussianReal 0 1)).measure (Set.Ioc x y)
      = ENNReal.ofReal (cdf (gaussianReal 0 1) y - cdf (gaussianReal 0 1) x) :=
    StieltjesFunction.measure_Ioc _ _ _
  rw [measure_cdf] at hmeas
  rw [hmeas, ne_eq, ENNReal.ofReal_eq_zero, not_le] at hpos
  unfold stdNormalCDF
  linarith

#print axioms bs_cdf_strictMono

lemma bs_payoff_split (s K : ℝ) :
    max (s - K) 0 = (if K < s then s else 0) - (if K < s then K else 0) := by
  split_ifs with h
  · exact max_eq_left (by linarith)
  · rw [sub_self]; exact max_eq_right (by linarith)

#print axioms bs_payoff_split

/-- **The Black–Scholes call** (The formula; Why it works, Steps 1 to 4). In the pretend world
`Q`, Acme's log price follows a bell curve with one fixed volatility `σ > 0`: after `T > 0` years
its price is `S_T = S e^((r - q - σ²/2) T + σ√T Z)` with `Z` a standard bell-curve draw, the bank
rate `r` and the steady dividend yield `q` held fixed. Today's price is `S > 0` and the strike is
`K > 0`, and the option is used only on expiry day. Then the premium, the average payoff
`max(S_T - K, 0)` shrunk back to today by `e^(-rT)`, is `C = S e^(-qT) N(d₁) - K e^(-rT) N(d₂)`. -/
theorem black_scholes_call_formula
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-r * T) * ∫ ω, max (priceAtExpiry S r q σ T (Z ω) - K) 0 ∂Q =
      S * exp (-q * T) * stdNormalCDF (bsD2 S K r q σ T + σ * √T)
        - K * exp (-r * T) * stdNormalCDF (bsD2 S K r q σ T) := by
  obtain ⟨hi1, he1⟩ := bs_share_Q S K r q σ T hS hK hσ hT hZ
  obtain ⟨hi2, he2, -⟩ := bs_cash_Q S K r q σ T hS hK hσ hT hZ
  simp_rw [bs_payoff_split]
  rw [integral_sub hi1 hi2, mul_sub, he1, he2]
  ring

/-- **The payoff is two bets glued together** (Step 1). For any finishing price `s` and strike `K`,
`(s - K)⁺ = s · [s > K] - K · [s > K]`: you get the share and hand over the cash exactly when
the light switch `[s > K]` is on. -/
theorem call_payoff_is_share_half_minus_cash_half (s K : ℝ) :
    max (s - K) 0 = (if K < s then s else 0) - (if K < s then K else 0) := by
  exact bs_payoff_split s K

/-- **Each half has its own chance** (Steps 2 and 3). In the same model, with `S > 0`, `K > 0`,
`σ > 0`, `T > 0` and `Z` a standard bell-curve draw under `Q`: the cash half, `K` handed over
only when Acme finishes above the strike, is worth `K e^(-rT) Q(S_T > K) = K e^(-rT) N(d₂)` today;
the share half, one share received only when Acme finishes above the strike, is worth `e^(-rT)`
times the average of `S_T · [S_T > K]`, which is `S e^(-qT) N(d₁)`; and the chance counted in
shares is always the larger, `N(d₁) > N(d₂)`. -/
theorem black_scholes_cash_half_and_share_half
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    K * exp (-r * T) * Q.real {ω | K < priceAtExpiry S r q σ T (Z ω)} =
        K * exp (-r * T) * stdNormalCDF (bsD2 S K r q σ T) ∧
      exp (-r * T) * ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω) then
          priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
        S * exp (-q * T) * stdNormalCDF (bsD2 S K r q σ T + σ * √T) ∧
      stdNormalCDF (bsD2 S K r q σ T) < stdNormalCDF (bsD2 S K r q σ T + σ * √T) := by
  obtain ⟨-, he1⟩ := bs_share_Q S K r q σ T hS hK hσ hT hZ
  obtain ⟨-, -, hp⟩ := bs_cash_Q S K r q σ T hS hK hσ hT hZ
  refine ⟨by rw [hp], he1, bs_cdf_strictMono ?_⟩
  linarith [mul_pos hσ (Real.sqrt_pos.mpr hT)]

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- Pretend-world drift: r - q - σ²/2 = 0.05 - 0.02 - 0.02 = 0.01.
example : (5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2 = 1 / 100 := by norm_num
-- d₂ = (ln(100/100) + 0.01 · 1) / (0.20 · √1) = 0.05.
example : (log (100 / 100) + ((5 / 100 : ℝ) - 2 / 100 - (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1)
    = 1 / 20 := by norm_num
-- d₁ = d₂ + σ√T = 0.05 + 0.20 = 0.25.
example : (1 / 20 : ℚ) + 1 / 5 * 1 = 1 / 4 := by norm_num
-- Step 1, the light switch at $120: get a $120 share, hand over $100, net $20.
example : max ((120 : ℤ) - 100) 0 = 120 * 1 - 100 * 1 ∧ (120 : ℤ) * 1 - 100 * 1 = 20 := by decide
-- Step 1, the light switch at $80: switch off, nothing happens, net $0.
example : max ((80 : ℤ) - 100) 0 = 80 * 0 - 100 * 0 ∧ (80 : ℤ) * 0 - 100 * 0 = 0 := by decide
-- Expiry day at $105: the option pays exactly $105 - $100 = $5.
example : max ((105 : ℤ) - 100) 0 = 5 := by decide
-- Breakeven at expiry: K + C = 100 + 9.23 = 109.23.
example : (100 : ℚ) + 923 / 100 = 10923 / 100 := by norm_num
-- Prices multiply: $100 up 2% then down 2% is $99.96, not $100.
example : (100 : ℚ) * (102 / 100) * (98 / 100) = 9996 / 100 := by norm_num
-- Wiggling costs you: up 50% then down 50% leaves you down 25%.
example : (3 / 2 : ℚ) * (1 / 2) = 3 / 4 := by norm_num

#print axioms black_scholes_call_formula
#print axioms call_payoff_is_share_half_minus_cash_half
#print axioms black_scholes_cash_half_and_share_half
