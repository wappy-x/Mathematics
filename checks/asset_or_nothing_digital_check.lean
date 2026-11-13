-- Asset-or-nothing digital: if the finishing price is S e^((r - q - σ²/2)T + σ√T Z) with Z a standard bell-curve draw under the pricing measure, the discounted average of the share-if-above payoff is S e^(-qT) N(d₁), the share-if-at-or-below payoff is worth S e^(-qT) N(-d₁) so the two together are one prepaid share S e^(-qT), and in any model at all the ordinary call is worth the asset digital minus K cash digitals.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Acme's price on expiry day under the pricing measure (Step 0 and the detailed proof): today's
price `S`, riskless rate `r`, dividend yield `q`, volatility `σ`, time to expiry `T`, and a
standard bell-curve draw `z`: `S_T = S e^((r - q - σ²/2) T + σ√T z)`. -/
noncomputable def priceAtExpiry (S r q σ T z : ℝ) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z)

/-- `d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`: the distance from the strike in wiggle units,
counted in shares. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

lemma aon_pdf_tilt (a b x : ℝ) :
    gaussianPDFReal 0 1 x * exp (a + b * x) = exp (a + b ^ 2 / 2) * gaussianPDFReal b 1 x := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one]
  rw [mul_assoc, ← exp_add, mul_left_comm, ← exp_add]
  congr 2
  ring

lemma aon_integral_indicator_exp (A a b : ℝ) {s : Set ℝ} (hs : MeasurableSet s) :
    ∫ x, s.indicator (fun x => A * exp (a + b * x)) x ∂(gaussianReal 0 1) =
      A * exp (a + b ^ 2 / 2) * (gaussianReal b 1).real s := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have h : (fun x => gaussianPDFReal 0 1 x • s.indicator (fun x => A * exp (a + b * x)) x) =
      s.indicator (fun x => A * exp (a + b ^ 2 / 2) * gaussianPDFReal b 1 x) := by
    funext x
    by_cases hx : x ∈ s
    · simp only [Set.indicator_of_mem hx, smul_eq_mul]
      rw [mul_left_comm, aon_pdf_tilt]; ring
    · simp [Set.indicator_of_notMem hx]
  rw [h, integral_indicator hs, integral_const_mul, measureReal_def,
    gaussianReal_apply_eq_integral _ one_ne_zero, ENNReal.toReal_ofReal]
  exact setIntegral_nonneg hs (fun x _ => gaussianPDFReal_nonneg _ _ _)

lemma aon_gauss_Ioi (b c : ℝ) :
    (gaussianReal b 1).real (Set.Ioi c) = stdNormalCDF (b - c) := by
  have hmap := gaussianReal_map_const_sub (μ := 0) (v := 1) b
  rw [sub_zero] at hmap
  rw [← hmap, map_measureReal_apply (by fun_prop) measurableSet_Ioi]
  have hpre : (fun y : ℝ => b - y) ⁻¹' Set.Ioi c = Set.Iio (b - c) := by
    ext y; simp only [Set.mem_preimage, Set.mem_Ioi, Set.mem_Iio]; constructor <;> intro h <;> linarith
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [hpre, stdNormalCDF, cdf_eq_real, measureReal_def, measureReal_def,
    measure_congr Iio_ae_eq_Iic]

lemma aon_gauss_Iic (b c : ℝ) :
    (gaussianReal b 1).real (Set.Iic c) = stdNormalCDF (c - b) := by
  have hmap := gaussianReal_map_add_const (μ := 0) (v := 1) b
  rw [zero_add] at hmap
  rw [← hmap, map_measureReal_apply (by fun_prop) measurableSet_Iic]
  have hpre : (fun y : ℝ => y + b) ⁻¹' Set.Iic c = Set.Iic (c - b) := by
    ext y; simp only [Set.mem_preimage, Set.mem_Iic]; constructor <;> intro h <;> linarith
  rw [hpre, stdNormalCDF, cdf_eq_real]

lemma aon_cond {S K a b x : ℝ} (hS : 0 < S) (hK : 0 < K) (hb : 0 < b) :
    K < S * exp (a + b * x) ↔ (log (K / S) - a) / b < x := by
  rw [div_lt_iff₀ hb, ← div_lt_iff₀' hS, ← Real.log_lt_iff_lt_exp (div_pos hK hS)]
  constructor <;> intro h <;> linarith

lemma aon_b_sq (σ T : ℝ) (hT : 0 < T) : (σ * √T) ^ 2 = σ ^ 2 * T := by
  rw [mul_pow, sq_sqrt hT.le]

lemma aon_d1 (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    σ * √T - (log (K / S) - (r - q - σ ^ 2 / 2) * T) / (σ * √T) = bsD1 S K r q σ T := by
  have hb : 0 < σ * √T := mul_pos hσ (sqrt_pos.mpr hT)
  have hlog : log (S / K) = -log (K / S) := by
    rw [← inv_div, Real.log_inv]
  have h2 := aon_b_sq σ T hT
  unfold bsD1
  rw [hlog]
  field_simp
  rw [sq_sqrt hT.le]
  ring

lemma aon_disc (r q σ T : ℝ) (hT : 0 < T) :
    exp (-r * T) * exp ((r - q - σ ^ 2 / 2) * T + (σ * √T) ^ 2 / 2) = exp (-q * T) := by
  rw [← exp_add, aon_b_sq σ T hT]
  congr 1
  ring

lemma aon_call_Q {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω)
        then priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
      S * exp ((r - q - σ ^ 2 / 2) * T + (σ * √T) ^ 2 / 2) *
        (gaussianReal (σ * √T) 1).real
          (Set.Ioi ((log (K / S) - (r - q - σ ^ 2 / 2) * T) / (σ * √T))) := by
  have hb : 0 < σ * √T := mul_pos hσ (sqrt_pos.mpr hT)
  have hf : (fun x => if K < priceAtExpiry S r q σ T x then priceAtExpiry S r q σ T x else 0) =
      (Set.Ioi ((log (K / S) - (r - q - σ ^ 2 / 2) * T) / (σ * √T))).indicator
        (fun x => S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * x)) := by
    funext x
    by_cases h : (log (K / S) - (r - q - σ ^ 2 / 2) * T) / (σ * √T) < x
    · rw [Set.indicator_of_mem (Set.mem_Ioi.mpr h)]
      exact ite_eq_left ((aon_cond hS hK hb).mpr h)
    · rw [Set.indicator_of_notMem (fun h' => h (Set.mem_Ioi.mp h'))]
      exact ite_eq_right (fun h' => h ((aon_cond hS hK hb).mp h'))
  have h1 : ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω)
        then priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
      ∫ x, (fun x => if K < priceAtExpiry S r q σ T x then priceAtExpiry S r q σ T x else 0) x
        ∂(gaussianReal 0 1) :=
    hZ.integral_comp (f := fun x =>
        if K < priceAtExpiry S r q σ T x then priceAtExpiry S r q σ T x else 0) (by
      rw [hf]
      exact (Measurable.indicator (by fun_prop) measurableSet_Ioi).aestronglyMeasurable)
  rw [h1, hf, aon_integral_indicator_exp _ _ _ measurableSet_Ioi]

lemma aon_put_Q {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    ∫ ω, (if priceAtExpiry S r q σ T (Z ω) ≤ K
        then priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
      S * exp ((r - q - σ ^ 2 / 2) * T + (σ * √T) ^ 2 / 2) *
        (gaussianReal (σ * √T) 1).real
          (Set.Iic ((log (K / S) - (r - q - σ ^ 2 / 2) * T) / (σ * √T))) := by
  have hb : 0 < σ * √T := mul_pos hσ (sqrt_pos.mpr hT)
  have hf : (fun x => if priceAtExpiry S r q σ T x ≤ K then priceAtExpiry S r q σ T x else 0) =
      (Set.Iic ((log (K / S) - (r - q - σ ^ 2 / 2) * T) / (σ * √T))).indicator
        (fun x => S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * x)) := by
    funext x
    by_cases h : (log (K / S) - (r - q - σ ^ 2 / 2) * T) / (σ * √T) < x
    · rw [Set.indicator_of_notMem (fun h' => (not_lt.mpr (Set.mem_Iic.mp h')) h)]
      exact ite_eq_right (fun h' => (not_lt.mpr h') ((aon_cond hS hK hb).mpr h))
    · rw [Set.indicator_of_mem (Set.mem_Iic.mpr (not_lt.mp h))]
      exact ite_eq_left (not_lt.mp (fun h' => h ((aon_cond hS hK hb).mp h')))
  have h1 : ∫ ω, (if priceAtExpiry S r q σ T (Z ω) ≤ K
        then priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
      ∫ x, (fun x => if priceAtExpiry S r q σ T x ≤ K then priceAtExpiry S r q σ T x else 0) x
        ∂(gaussianReal 0 1) :=
    hZ.integral_comp (f := fun x =>
        if priceAtExpiry S r q σ T x ≤ K then priceAtExpiry S r q σ T x else 0) (by
      rw [hf]
      exact (Measurable.indicator (by fun_prop) measurableSet_Iic).aestronglyMeasurable)
  rw [h1, hf, aon_integral_indicator_exp _ _ _ measurableSet_Iic]

#print axioms aon_pdf_tilt
#print axioms aon_integral_indicator_exp
#print axioms aon_gauss_Ioi
#print axioms aon_gauss_Iic
#print axioms aon_cond
#print axioms aon_b_sq
#print axioms aon_d1
#print axioms aon_disc
#print axioms aon_call_Q
#print axioms aon_put_Q

/-- **Asset-or-nothing call digital** (The formula; Why it works, Steps 0 to 3). Under the pricing
measure `Q`, let Acme's price have one constant volatility `σ > 0`, a steady dividend yield `q`
and riskless rate `r`, so that on expiry day, after `T > 0` years, it is
`S_T = S e^((r - q - σ²/2) T + σ√T Z)` with `Z` a standard bell-curve draw; today's price is
`S > 0` and the strike is `K > 0`; the contract looks once, at expiry, and hands over the share
(worth `S_T`) if Acme closes above the strike and nothing otherwise. Then its price, the average
payoff under `Q` pulled back to today by `e^(-rT)`, is `S e^(-qT) N(d₁)`: one prepaid share times
the share-weighted chance of finishing above the strike. -/
theorem asset_or_nothing_call_is_prepaid_share_times_share_weighted_chance
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-r * T) * ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω)
        then priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
      S * exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T) := by
  rw [aon_call_Q S K r q σ T hS hK hσ hT hZ, aon_gauss_Ioi, aon_d1 S K r q σ T hσ hT,
    ← aon_disc r q σ T hT]
  ring

/-- **The asset put, and the two asset digitals make a prepaid share** (Step 5 and the end of the
detailed proof). In the same model, with `S > 0`, `K > 0`, `σ > 0`, `T > 0` and `Z` a standard
bell-curve draw under `Q`: the contract handing over the share when Acme closes at or below the
strike costs `S e^(-qT) N(-d₁)`, and the asset call plus the asset put costs
`S e^(-qT)`, one share delivered for certain at expiry, valued today. -/
theorem asset_or_nothing_put_and_pair_is_prepaid_share
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-r * T) * ∫ ω, (if priceAtExpiry S r q σ T (Z ω) ≤ K
        then priceAtExpiry S r q σ T (Z ω) else 0) ∂Q =
        S * exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T) ∧
      exp (-r * T) * ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω)
          then priceAtExpiry S r q σ T (Z ω) else 0) ∂Q +
        exp (-r * T) * ∫ ω, (if priceAtExpiry S r q σ T (Z ω) ≤ K
          then priceAtExpiry S r q σ T (Z ω) else 0) ∂Q = S * exp (-q * T) := by
  constructor
  · rw [aon_put_Q S K r q σ T hS hK hσ hT hZ, aon_gauss_Iic, ← aon_d1 S K r q σ T hσ hT,
      ← aon_disc r q σ T hT, neg_sub]
    ring
  · rw [aon_call_Q S K r q σ T hS hK hσ hT hZ, aon_put_Q S K r q σ T hS hK hσ hT hZ,
      ← aon_disc r q σ T hT]
    have h := probReal_add_probReal_compl (μ := gaussianReal (σ * √T) 1)
      (measurableSet_Ioi (a := (log (K / S) - (r - q - σ ^ 2 / 2) * T) / (σ * √T)))
    rw [Set.compl_Ioi] at h
    linear_combination (exp (-r * T) * S * exp ((r - q - σ ^ 2 / 2) * T + (σ * √T) ^ 2 / 2)) * h

/-- **The call is two digitals, in every market** (Step 4). Whatever the finishing price `S_T`
does, as long as it is a random quantity with a finite average under a pricing measure `Q` (a
probability measure), and whatever strike `K`, rate `r` and time `T`: in every future the call's
payoff `max(S_T - K, 0)` equals the asset digital's payoff (`S_T` above `K`, else 0) minus `K`
times the cash digital's payoff ($1 above `K`, else 0), so the call's price is the asset digital's
price minus `K` cash digitals' prices. -/
theorem call_is_asset_digital_minus_strike_cash_digitals
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} [IsProbabilityMeasure Q] {ST : Ω → ℝ}
    (hST : Integrable ST Q) (K r T : ℝ) :
    exp (-r * T) * ∫ ω, max (ST ω - K) 0 ∂Q =
      exp (-r * T) * ∫ ω, (if K < ST ω then ST ω else 0) ∂Q -
        K * (exp (-r * T) * ∫ ω, (if K < ST ω then (1 : ℝ) else 0) ∂Q) := by
  have hm := hST.aestronglyMeasurable.aemeasurable
  have hA : Integrable (fun ω => if K < ST ω then ST ω else 0) Q := by
    have hg : Measurable (fun x : ℝ => if K < x then x else 0) :=
      Measurable.ite measurableSet_Ioi measurable_id measurable_const
    refine hST.mono (hg.comp_aemeasurable hm).aestronglyMeasurable (ae_of_all _ fun ω => ?_)
    split_ifs <;> simp
  have hB : Integrable (fun ω => if K < ST ω then (1 : ℝ) else 0) Q := by
    have hg : Measurable (fun x : ℝ => if K < x then (1 : ℝ) else 0) :=
      Measurable.ite measurableSet_Ioi measurable_const measurable_const
    refine (integrable_const (1 : ℝ)).mono (hg.comp_aemeasurable hm).aestronglyMeasurable
      (ae_of_all _ fun ω => ?_)
    split_ifs <;> simp
  have hpt : (fun ω => max (ST ω - K) 0) =
      fun ω => (if K < ST ω then ST ω else 0) - K * (if K < ST ω then (1 : ℝ) else 0) := by
    funext ω
    split_ifs with h
    · rw [max_eq_left (by linarith)]; ring
    · rw [max_eq_right (by linarith)]; ring
  rw [hpt, integral_sub hA (hB.const_mul K), integral_const_mul]
  ring

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- Worked numbers: d₁ = (ln(100/100) + (0.05 - 0.02 + 0.02) · 1) / (0.20 · √1) = 0.25.
example : (log (100 / 100) + ((5 / 100 : ℝ) - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1)
    = 1 / 4 := by norm_num
-- d₂ = d₁ - σ√T = 0.25 - 0.20 = 0.05.
example : (1 / 4 : ℚ) - 1 / 5 = 1 / 20 := by norm_num
-- Detailed proof: m + v²/2 = (r - q)T, here 0.01 + 0.02 = 0.03.
example : ((5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2) * 1 + (1 / 5) ^ 2 * 1 / 2
    = (5 / 100 - 2 / 100) * 1 := by norm_num
-- Prepaid share to six places: 100 × 0.980199 = 98.0199.
example : (100 : ℚ) * (980199 / 1000000) = 980199 / 10000 := by norm_num
-- The call, rebuilt: 58.69 - 49.46 = 9.23.
example : (5869 / 100 : ℚ) - 4946 / 100 = 923 / 100 := by norm_num
-- Step 5, the asset put: 98.02 - 58.69 = 39.33.
example : (9802 / 100 : ℚ) - 5869 / 100 = 3933 / 100 := by norm_num

#print axioms asset_or_nothing_call_is_prepaid_share_times_share_weighted_chance
#print axioms asset_or_nothing_put_and_pair_is_prepaid_share
#print axioms call_is_asset_digital_minus_strike_cash_digitals
