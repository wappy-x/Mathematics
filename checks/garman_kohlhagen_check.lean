-- Garman-Kohlhagen: if EURUSD on expiry day is S e^((r_d - r_f - σ²/2)T + σ√T Z) with Z a standard bell-curve draw in the pricing world, the call's dollar-discounted average payoff is S e^(-r_f T) N(d₁) - K e^(-r_d T) N(d₂), the put's is K e^(-r_d T) N(-d₂) - S e^(-r_f T) N(-d₁), and call minus put is S e^(-r_f T) - K e^(-r_d T) with the average future spot equal to the parity forward S e^((r_d - r_f)T).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The spot rate on expiry day in the pricing world (Step 2): today's spot `S` (dollars per
euro), dollar rate `rd`, euro rate `rf`, volatility `σ`, time to expiry `T` in years, and a
standard bell-curve draw `z`: `S_T = S e^((r_d - r_f - σ²/2) T + σ√T z)`. -/
noncomputable def spotAtExpiry (S rd rf σ T z : ℝ) : ℝ :=
  S * exp ((rd - rf - σ ^ 2 / 2) * T + σ * √T * z)

/-- The card's `d₁ = (ln(S/K) + (r_d - r_f + σ²/2) T) / (σ√T)`; then `d₂ = d₁ - σ√T`. -/
noncomputable def gkD1 (S K rd rf σ T : ℝ) : ℝ :=
  (log (S / K) + (rd - rf + σ ^ 2 / 2) * T) / (σ * √T)


open Set in
lemma gk_gauss_Ioi_neg (d : ℝ) :
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

#print axioms gk_gauss_Ioi_neg

open Set in
lemma gk_N_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  rw [← gk_gauss_Ioi_neg, neg_neg, ← compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic,
    stdNormalCDF, cdf_eq_real]

#print axioms gk_N_neg

open Set in
lemma gk_gauss_exp_indicator (b c : ℝ) :
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

#print axioms gk_gauss_exp_indicator

lemma gk_spot_eq (S rd rf σ T z : ℝ) :
    spotAtExpiry S rd rf σ T z = S * exp ((rd - rf - σ ^ 2 / 2) * T) * exp (σ * √T * z) := by
  rw [spotAtExpiry, exp_add]; ring

#print axioms gk_spot_eq

lemma gk_event (S K rd rf σ T z : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K < spotAtExpiry S rd rf σ T z ↔ -(gkD1 S K rd rf σ T - σ * √T) < z := by
  have hb : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hL : log (K / S) = -log (S / K) := by
    rw [← Real.log_inv, inv_div]
  have hd : gkD1 S K rd rf σ T - σ * √T = (log (S / K) + (rd - rf - σ ^ 2 / 2) * T) / (σ * √T) := by
    rw [gkD1]; field_simp; rw [Real.sq_sqrt hT.le]; ring
  rw [hd, spotAtExpiry, ← div_lt_iff₀' hS, ← Real.log_lt_iff_lt_exp (div_pos hK hS), hL,
    ← neg_div, div_lt_iff₀ hb]
  constructor <;> intro h <;> linarith

#print axioms gk_event

open Set in
lemma gk_share_fun (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (fun z => if K < spotAtExpiry S rd rf σ T z then spotAtExpiry S rd rf σ T z else 0) =
      fun z => S * exp ((rd - rf - σ ^ 2 / 2) * T) *
        (Ioi (-(gkD1 S K rd rf σ T - σ * √T))).indicator (fun z => exp (σ * √T * z)) z := by
  funext z
  by_cases h : -(gkD1 S K rd rf σ T - σ * √T) < z
  · have h' := (gk_event S K rd rf σ T z hS hK hσ hT).mpr h
    rw [ite_eq_left h', indicator_of_mem (show z ∈ Ioi _ from h), gk_spot_eq]
  · have h' : ¬ K < spotAtExpiry S rd rf σ T z :=
      fun h' => h ((gk_event S K rd rf σ T z hS hK hσ hT).mp h')
    rw [ite_eq_right h', indicator_of_notMem (show z ∉ Ioi _ from h), mul_zero]

#print axioms gk_share_fun

lemma gk_share_integrable (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Integrable (fun z => if K < spotAtExpiry S rd rf σ T z then spotAtExpiry S rd rf σ T z else 0)
      (gaussianReal 0 1) := by
  rw [gk_share_fun S K rd rf σ T hS hK hσ hT]
  exact ((integrable_exp_mul_gaussianReal _).indicator measurableSet_Ioi).const_mul _

#print axioms gk_share_integrable

lemma gk_share_gauss (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-rd * T) * ∫ z, (if K < spotAtExpiry S rd rf σ T z then spotAtExpiry S rd rf σ T z else 0)
      ∂(gaussianReal 0 1) =
        S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T) := by
  rw [gk_share_fun S K rd rf σ T hS hK hσ hT, integral_const_mul, gk_gauss_exp_indicator,
    show -(gkD1 S K rd rf σ T - σ * √T) - σ * √T = -gkD1 S K rd rf σ T by ring, gk_gauss_Ioi_neg]
  have hb : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, Real.sq_sqrt hT.le]
  rw [hb]
  have he : exp (-rd * T) * exp ((rd - rf - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2) =
      exp (-rf * T) := by
    rw [← exp_add, ← exp_add]; congr 1; ring
  calc _ = S * (exp (-rd * T) * exp ((rd - rf - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2)) *
        stdNormalCDF (gkD1 S K rd rf σ T) := by ring
    _ = _ := by rw [he]

#print axioms gk_share_gauss

lemma gk_measurable_spot (S rd rf σ T : ℝ) : Measurable (spotAtExpiry S rd rf σ T) := by
  unfold spotAtExpiry; fun_prop

#print axioms gk_measurable_spot

lemma gk_spot_integrable (S rd rf σ T : ℝ) :
    Integrable (spotAtExpiry S rd rf σ T) (gaussianReal 0 1) := by
  have h : spotAtExpiry S rd rf σ T =
      fun z => S * exp ((rd - rf - σ ^ 2 / 2) * T) * exp (σ * √T * z) := by
    funext z; exact gk_spot_eq S rd rf σ T z
  rw [h]
  exact (integrable_exp_mul_gaussianReal _).const_mul _

#print axioms gk_spot_integrable

lemma gk_spot_integral (S rd rf σ T : ℝ) (hT : 0 < T) :
    ∫ z, spotAtExpiry S rd rf σ T z ∂(gaussianReal 0 1) = S * exp ((rd - rf) * T) := by
  have hm : ∫ z, exp (σ * √T * z) ∂(gaussianReal 0 1) = exp (σ ^ 2 * T / 2) := by
    have h := mgf_gaussianReal (HasLaw.id (μ := gaussianReal 0 1)) (σ * √T)
    rw [mgf] at h
    simp only [id] at h
    rw [h, mul_pow, Real.sq_sqrt hT.le]
    congr 1; push_cast; ring
  simp_rw [gk_spot_eq]
  rw [integral_const_mul, hm, mul_assoc, ← exp_add]
  congr 2; ring

#print axioms gk_spot_integral

lemma gk_call_gauss (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-rd * T) * ∫ z, max (spotAtExpiry S rd rf σ T z - K) 0 ∂(gaussianReal 0 1) =
      S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)
        - K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T) := by
  have hpt : (fun z => max (spotAtExpiry S rd rf σ T z - K) 0) = fun z =>
      (if K < spotAtExpiry S rd rf σ T z then spotAtExpiry S rd rf σ T z else 0) -
        (Set.Ioi (-(gkD1 S K rd rf σ T - σ * √T))).indicator (fun _ => K) z := by
    funext z
    by_cases h : K < spotAtExpiry S rd rf σ T z
    · have h' := (gk_event S K rd rf σ T z hS hK hσ hT).mp h
      rw [ite_eq_left h, Set.indicator_of_mem (show z ∈ Set.Ioi _ from h'),
        max_eq_left (by linarith)]
    · have h' : ¬ -(gkD1 S K rd rf σ T - σ * √T) < z :=
        fun h' => h ((gk_event S K rd rf σ T z hS hK hσ hT).mpr h')
      rw [ite_eq_right h, Set.indicator_of_notMem (show z ∉ Set.Ioi _ from h'),
        max_eq_right (by linarith)]
      ring
  rw [hpt, integral_sub (gk_share_integrable S K rd rf σ T hS hK hσ hT)
    ((integrable_const K).indicator measurableSet_Ioi), integral_indicator_const _ measurableSet_Ioi,
    mul_sub, gk_share_gauss S K rd rf σ T hS hK hσ hT, gk_gauss_Ioi_neg, smul_eq_mul]
  ring

#print axioms gk_call_gauss

lemma gk_put_gauss (S K rd rf σ T : ℝ) :
    ∫ z, max (K - spotAtExpiry S rd rf σ T z) 0 ∂(gaussianReal 0 1) =
      ∫ z, max (spotAtExpiry S rd rf σ T z - K) 0 ∂(gaussianReal 0 1)
        - (∫ z, spotAtExpiry S rd rf σ T z ∂(gaussianReal 0 1) - K) := by
  have hi := gk_spot_integrable S rd rf σ T
  have hc : Integrable (fun z => max (spotAtExpiry S rd rf σ T z - K) 0) (gaussianReal 0 1) :=
    (hi.sub (integrable_const K)).pos_part
  have hpt : (fun z => max (K - spotAtExpiry S rd rf σ T z) 0) = fun z =>
      max (spotAtExpiry S rd rf σ T z - K) 0 - (spotAtExpiry S rd rf σ T z - K) := by
    funext z
    rcases le_total K (spotAtExpiry S rd rf σ T z) with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  have h1 : Integrable (fun z => spotAtExpiry S rd rf σ T z - K) (gaussianReal 0 1) :=
    hi.sub (integrable_const K)
  have e1 := integral_sub hc h1
  have e2 := integral_sub hi (integrable_const (μ := gaussianReal 0 1) K)
  rw [hpt, e1, e2]
  simp

#print axioms gk_put_gauss

lemma gk_transfer {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (hZ : HasLaw Z (gaussianReal 0 1) Q) {f : ℝ → ℝ} (hf : Measurable f) :
    ∫ ω, f (Z ω) ∂Q = ∫ z, f z ∂(gaussianReal 0 1) :=
  hZ.integral_comp (f := f) hf.aestronglyMeasurable

#print axioms gk_transfer

/-- **Garman-Kohlhagen call** (The formula; Why it works, Steps 0 to 4). In the pricing world `Q`,
EURUSD wanders with one fixed volatility `σ > 0` and no jumps, the dollar rate `rd` and euro rate
`rf` are constant and known (either may be negative), and after `T > 0` years the spot is
`S_T = S e^((r_d - r_f - σ²/2) T + σ√T Z)` with `Z` a standard bell-curve draw, so it drifts at
the rate gap. Today's spot is `S > 0`, the strike is `K > 0`, and the option is used only on
expiry day. Then the EUR call / USD put, the average payoff `max(S_T - K, 0)` discounted at the
dollar rate, costs `C = S e^(-r_f T) N(d₁) - K e^(-r_d T) N(d₂)` dollars per euro: a Black-Scholes
call with the euro rate in the dividend slot. -/
theorem garman_kohlhagen_call_formula
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-rd * T) * ∫ ω, max (spotAtExpiry S rd rf σ T (Z ω) - K) 0 ∂Q =
      S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)
        - K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T) := by
  rw [gk_transfer (f := fun z => max (spotAtExpiry S rd rf σ T z - K) 0) hZ
      (((gk_measurable_spot S rd rf σ T).sub_const K).max measurable_const)]
  exact gk_call_gauss S K rd rf σ T hS hK hσ hT

/-- **Garman-Kohlhagen put** (The formula; Detailed proof, last line). Same model and hypotheses:
the EUR put / USD call, the average payoff `max(K - S_T, 0)` discounted at the dollar rate, costs
`P = K e^(-r_d T) N(-d₂) - S e^(-r_f T) N(-d₁)` dollars per euro. -/
theorem garman_kohlhagen_put_formula
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-rd * T) * ∫ ω, max (K - spotAtExpiry S rd rf σ T (Z ω)) 0 ∂Q =
      K * exp (-rd * T) * stdNormalCDF (-(gkD1 S K rd rf σ T - σ * √T))
        - S * exp (-rf * T) * stdNormalCDF (-(gkD1 S K rd rf σ T)) := by
  rw [gk_transfer (f := fun z => max (K - spotAtExpiry S rd rf σ T z) 0) hZ
      ((measurable_const.sub (gk_measurable_spot S rd rf σ T)).max measurable_const),
    gk_put_gauss, mul_sub, gk_call_gauss S K rd rf σ T hS hK hσ hT, gk_spot_integral S rd rf σ T hT,
    gk_N_neg, gk_N_neg]
  have he : exp (-rd * T) * (S * exp ((rd - rf) * T)) = S * exp (-rf * T) := by
    rw [mul_left_comm, ← exp_add]; congr 2; ring
  rw [mul_sub, he]
  ring

/-- **Parity with two discount factors, and the forward** (Step 2 and Step 5). Same model and
hypotheses: the average spot on expiry day is the covered-interest-parity forward
`F = S e^((r_d - r_f) T)`, and a call bought and a put sold at the same strike are worth
`C - P = S e^(-r_f T) - K e^(-r_d T)`: the euro leg discounted at the euro rate, the dollar leg at
the dollar rate. -/
theorem garman_kohlhagen_forward_and_parity
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    ∫ ω, spotAtExpiry S rd rf σ T (Z ω) ∂Q = S * exp ((rd - rf) * T) ∧
      exp (-rd * T) * ∫ ω, max (spotAtExpiry S rd rf σ T (Z ω) - K) 0 ∂Q
        - exp (-rd * T) * ∫ ω, max (K - spotAtExpiry S rd rf σ T (Z ω)) 0 ∂Q =
        S * exp (-rf * T) - K * exp (-rd * T) := by
  rw [gk_transfer (f := fun z => spotAtExpiry S rd rf σ T z) hZ (gk_measurable_spot S rd rf σ T),
    gk_transfer (f := fun z => max (spotAtExpiry S rd rf σ T z - K) 0) hZ
      (((gk_measurable_spot S rd rf σ T).sub_const K).max measurable_const),
    gk_transfer (f := fun z => max (K - spotAtExpiry S rd rf σ T z) 0) hZ
      ((measurable_const.sub (gk_measurable_spot S rd rf σ T)).max measurable_const),
    gk_spot_integral S rd rf σ T hT, gk_put_gauss, gk_spot_integral S rd rf σ T hT]
  refine ⟨rfl, ?_⟩
  have he : exp (-rd * T) * (S * exp ((rd - rf) * T)) = S * exp (-rf * T) := by
    rw [mul_left_comm, ← exp_add]; congr 2; ring
  rw [mul_sub, mul_sub, he]
  ring

-- House example: S = K = 1.10, r_d = 5%, r_f = 3%, σ = 10%, T = 1 year.
-- Drift plus half variance: 0.05 - 0.03 + 0.005 = 0.025.
example : (5 / 100 : ℚ) - 3 / 100 + (1 / 10) ^ 2 / 2 = 1 / 40 := by norm_num
-- d₁ = (ln(1.10/1.10) + 0.025 · 1) / (0.10 · √1) = 0.25.
example : (log ((11 / 10) / (11 / 10)) + ((5 / 100 : ℝ) - 3 / 100 + (1 / 10) ^ 2 / 2) * 1)
    / (1 / 10 * √1) = 1 / 4 := by norm_num
-- d₂ = d₁ - σ√T = 0.25 - 0.10 = 0.15.
example : (1 / 4 : ℝ) - 1 / 10 * √1 = 3 / 20 := by norm_num
-- A pip is 0.0001 of the quote: 535.56 pips is 0.053556 dollars per euro.
example : (53556 / 100 : ℚ) * (1 / 10000) = 53556 / 1000000 := by norm_num

#print axioms garman_kohlhagen_call_formula
#print axioms garman_kohlhagen_put_formula
#print axioms garman_kohlhagen_forward_and_parity
