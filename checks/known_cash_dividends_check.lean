-- Known cash dividends: when a known cash dividend paid before expiry is escrowed and the volatility sits on the escrowed spot, the call and put are exactly the no-yield Black-Scholes formulas on S* = S - D₁e^(-rt₁), put-call parity reads C - P = S - D₀ - Ke^(-rT), and the same prices come from Merton's yield formula at q = -ln(S*/S)/T.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The escrow `D₀ = D₁ e^(-r t₁)`: the declared cash `D₁`, paid at `t₁` years, valued today. -/
noncomputable def escrow (D1 r t1 : ℝ) : ℝ := D1 * exp (-r * t1)

/-- The escrowed spot `S* = S - D₀`: the quoted share with the escrow taken out. -/
noncomputable def escrowedSpot (S D1 r t1 : ℝ) : ℝ := S - escrow D1 r t1

/-- The first distance `d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`; the second is `d₁ - σ√T`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Black-Scholes call with continuous yield `q`:
`C = S e^(-qT) N(d₁) - K e^(-rT) N(d₂)`. -/
noncomputable def blackScholesCall (S K r q σ T : ℝ) : ℝ :=
  S * exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T)
    - K * exp (-r * T) * stdNormalCDF (bsD1 S K r q σ T - σ * √T)

/-- The Black-Scholes put with continuous yield `q`:
`P = K e^(-rT) N(-d₂) - S e^(-qT) N(-d₁)`. -/
noncomputable def blackScholesPut (S K r q σ T : ℝ) : ℝ :=
  K * exp (-r * T) * stdNormalCDF (-(bsD1 S K r q σ T - σ * √T))
    - S * exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T)

/-- The card's call: the ordinary formula on the escrowed spot, with no yield term anywhere. -/
noncomputable def escrowedCall (S K r σ T D1 t1 : ℝ) : ℝ :=
  blackScholesCall (escrowedSpot S D1 r t1) K r 0 σ T

/-- The card's put: the ordinary formula on the escrowed spot, with no yield term anywhere. -/
noncomputable def escrowedPut (S K r σ T D1 t1 : ℝ) : ℝ :=
  blackScholesPut (escrowedSpot S D1 r t1) K r 0 σ T

/-- The share on expiry day in the escrow model, given a standard bell-curve draw `z`. The
escrowed part starts at `S*`, grows at the riskless rate `r` and wanders with volatility `σ`, so
on expiry day it is `S* e^((r - σ²/2)T + σ√T z)`; the dividend was paid out at `t₁ ≤ T`, so no
cash is left inside the share and this is the share's whole price. -/
noncomputable def escrowShareAtExpiry (S D1 r t1 σ T z : ℝ) : ℝ :=
  escrowedSpot S D1 r t1 * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)

open Set in
lemma kd_gauss_Ioi_neg (d : ℝ) :
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

#print axioms kd_gauss_Ioi_neg

open Set in
lemma kd_cdf_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  rw [← kd_gauss_Ioi_neg x]
  unfold stdNormalCDF
  rw [cdf_eq_real, ← compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ]
  ring

#print axioms kd_cdf_neg

open Set in
lemma kd_gauss_exp_indicator (b c : ℝ) :
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

#print axioms kd_gauss_exp_indicator

lemma kd_gauss_exp_mean (b : ℝ) :
    ∫ z, exp (b * z) ∂(gaussianReal 0 1) = exp (b ^ 2 / 2) := by
  have h := congrFun (mgf_fun_id_gaussianReal (μ := 0) (v := 1)) b
  rw [mgf] at h
  rw [h]
  congr 1; push_cast; ring

#print axioms kd_gauss_exp_mean

lemma kd_d2 (A K r σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    bsD1 A K r 0 σ T - σ * √T = (log (A / K) + (r - σ ^ 2 / 2) * T) / (σ * √T) := by
  have hb : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hs : √T * √T = T := Real.mul_self_sqrt hT.le
  unfold bsD1
  rw [eq_div_iff hb.ne', sub_mul, div_mul_cancel₀ _ hb.ne']
  linear_combination (-σ ^ 2) * hs

#print axioms kd_d2

lemma kd_price_eq (A r σ T z : ℝ) :
    A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)
      = A * exp ((r - σ ^ 2 / 2) * T) * exp (σ * √T * z) := by
  rw [exp_add]; ring

#print axioms kd_price_eq

lemma kd_event (A K r σ T z : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K < A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) ↔ -(bsD1 A K r 0 σ T - σ * √T) < z := by
  have hb : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hL : log (K / A) = -log (A / K) := by
    rw [← Real.log_inv, inv_div]
  rw [kd_d2 A K r σ T hσ hT, ← div_lt_iff₀' hA, ← Real.log_lt_iff_lt_exp (div_pos hK hA), hL,
    ← neg_div, div_lt_iff₀ hb]
  constructor <;> intro h <;> linarith

#print axioms kd_event

open Set in
lemma kd_event_set (A K r σ T : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    {z | K < A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)} = Ioi (-(bsD1 A K r 0 σ T - σ * √T)) := by
  ext z; simp only [mem_ofPred_eq, mem_Ioi]; exact kd_event A K r σ T z hA hK hσ hT

#print axioms kd_event_set

open Set in
lemma kd_share_fun (A K r σ T : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (fun z => if K < A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) then
        A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) else 0) =
      fun z => A * exp ((r - σ ^ 2 / 2) * T) *
        (Ioi (-(bsD1 A K r 0 σ T - σ * √T))).indicator (fun z => exp (σ * √T * z)) z := by
  funext z
  by_cases h : -(bsD1 A K r 0 σ T - σ * √T) < z
  · have h' := (kd_event A K r σ T z hA hK hσ hT).mpr h
    rw [ite_eq_left h', indicator_of_mem (show z ∈ Ioi _ from h), kd_price_eq]
  · have h' : ¬ K < A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) :=
      fun h' => h ((kd_event A K r σ T z hA hK hσ hT).mp h')
    rw [ite_eq_right h', indicator_of_notMem (show z ∉ Ioi _ from h), mul_zero]

#print axioms kd_share_fun

lemma kd_share_integrable (A K r σ T : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Integrable (fun z => if K < A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) then
        A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) else 0) (gaussianReal 0 1) := by
  rw [kd_share_fun A K r σ T hA hK hσ hT]
  exact ((integrable_exp_mul_gaussianReal _).indicator measurableSet_Ioi).const_mul _

#print axioms kd_share_integrable

lemma kd_share_gauss (A K r σ T : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-r * T) * ∫ z, (if K < A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) then
        A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) else 0) ∂(gaussianReal 0 1) =
      A * stdNormalCDF (bsD1 A K r 0 σ T) := by
  rw [kd_share_fun A K r σ T hA hK hσ hT, integral_const_mul, kd_gauss_exp_indicator,
    show -(bsD1 A K r 0 σ T - σ * √T) - σ * √T = -bsD1 A K r 0 σ T by ring, kd_gauss_Ioi_neg]
  have hb : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, Real.sq_sqrt hT.le]
  rw [hb]
  have he : exp (-r * T) * exp ((r - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2) = 1 := by
    rw [← exp_add, ← exp_add, ← exp_zero]; congr 1; ring
  calc _ = A * (exp (-r * T) * exp ((r - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2)) *
        stdNormalCDF (bsD1 A K r 0 σ T) := by ring
    _ = _ := by rw [he, mul_one]

#print axioms kd_share_gauss

lemma kd_call_fun (A K r σ T : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (fun z => max (A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) - K) 0) = fun z =>
      (if K < A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) then
        A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) else 0) -
        (Set.Ioi (-(bsD1 A K r 0 σ T - σ * √T))).indicator (fun _ => K) z := by
  funext z
  by_cases h : K < A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)
  · have h' := (kd_event A K r σ T z hA hK hσ hT).mp h
    rw [ite_eq_left h, Set.indicator_of_mem (show z ∈ Set.Ioi _ from h'),
      max_eq_left (by linarith)]
  · have h' : ¬ -(bsD1 A K r 0 σ T - σ * √T) < z :=
      fun h' => h ((kd_event A K r σ T z hA hK hσ hT).mpr h')
    rw [ite_eq_right h, Set.indicator_of_notMem (show z ∉ Set.Ioi _ from h'),
      max_eq_right (by linarith)]
    ring

#print axioms kd_call_fun

lemma kd_call_integrable (A K r σ T : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Integrable (fun z => max (A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) - K) 0)
      (gaussianReal 0 1) := by
  rw [kd_call_fun A K r σ T hA hK hσ hT]
  exact (kd_share_integrable A K r σ T hA hK hσ hT).sub
    ((integrable_const K).indicator measurableSet_Ioi)

#print axioms kd_call_integrable

lemma kd_call_gauss (A K r σ T : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-r * T) * ∫ z, max (A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) - K) 0
        ∂(gaussianReal 0 1) =
      A * stdNormalCDF (bsD1 A K r 0 σ T)
        - K * exp (-r * T) * stdNormalCDF (bsD1 A K r 0 σ T - σ * √T) := by
  rw [kd_call_fun A K r σ T hA hK hσ hT, integral_sub (kd_share_integrable A K r σ T hA hK hσ hT)
    ((integrable_const K).indicator measurableSet_Ioi), integral_indicator_const _ measurableSet_Ioi,
    mul_sub, kd_share_gauss A K r σ T hA hK hσ hT, kd_gauss_Ioi_neg, smul_eq_mul]
  ring

#print axioms kd_call_gauss

lemma kd_price_integrable (A r σ T : ℝ) :
    Integrable (fun z => A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) (gaussianReal 0 1) := by
  simp_rw [kd_price_eq]
  exact (integrable_exp_mul_gaussianReal _).const_mul _

#print axioms kd_price_integrable

lemma kd_price_mean (A r σ T : ℝ) (hT : 0 < T) :
    exp (-r * T) * ∫ z, A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) ∂(gaussianReal 0 1) = A := by
  simp_rw [kd_price_eq]
  rw [integral_const_mul, kd_gauss_exp_mean, mul_pow, Real.sq_sqrt hT.le]
  have he : exp (-r * T) * exp ((r - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2) = 1 := by
    rw [← exp_add, ← exp_add, ← exp_zero]; congr 1; ring
  calc _ = A * (exp (-r * T) * exp ((r - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2)) := by ring
    _ = A := by rw [he, mul_one]

#print axioms kd_price_mean

lemma kd_put_gauss (A K r σ T : ℝ) (hA : 0 < A) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-r * T) * ∫ z, max (K - A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) 0
        ∂(gaussianReal 0 1) =
      K * exp (-r * T) * stdNormalCDF (-(bsD1 A K r 0 σ T - σ * √T))
        - A * stdNormalCDF (-bsD1 A K r 0 σ T) := by
  have hpt : (fun z => max (K - A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) 0) = fun z =>
      (max (A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) - K) 0
        - A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) + K := by
    funext z
    rcases le_total K (A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  have hI : Integrable (fun z => max (A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) - K) 0
      - A * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) (gaussianReal 0 1) :=
    (kd_call_integrable A K r σ T hA hK hσ hT).sub (kd_price_integrable A r σ T)
  rw [hpt, integral_add hI (integrable_const K),
    integral_sub (kd_call_integrable A K r σ T hA hK hσ hT) (kd_price_integrable A r σ T),
    integral_const, probReal_univ, one_smul, mul_add, mul_sub, kd_call_gauss A K r σ T hA hK hσ hT,
    kd_price_mean A r σ T hT, kd_cdf_neg, kd_cdf_neg]
  ring

#print axioms kd_put_gauss

/-- **Escrow the dividend, then price the share that is left** (The formula; Steps 0 and 1).
A share quoted at `S` has declared one known cash dividend `D₁`, paid at `t₁` with
`0 ≤ t₁ ≤ T`, before the option expires. The dividend never exceeds the share: the escrowed spot
`S* = S - D₁e^(-rt₁)` is positive. The volatility `σ > 0` sits on `S*`: the share on expiry day is
`S* e^((r - σ²/2)T + σ√T Z)` with `Z` a standard bell-curve draw. The option is European, with
strike `K > 0`, expiry `T > 0` and riskless rate `r`. Then the call's premium, `e^(-rT)` times
the average of `(S_T - K)⁺`, is the ordinary formula on `S*` with no yield,
`S* N(d₁) - K e^(-rT) N(d₂)`, and the put's premium, `e^(-rT)` times the average of
`(K - S_T)⁺`, is `K e^(-rT) N(-d₂) - S* N(-d₁)`, with `d₁` measured on `S*`. -/
theorem escrowed_spot_prices_call_and_put
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {Z : Ω → ℝ}
    (S K r σ T D1 t1 : ℝ) (ht1 : 0 ≤ t1) (ht1T : t1 ≤ T)
    (hS : 0 < escrowedSpot S D1 r t1) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) P) :
    exp (-r * T) * ∫ ω, max (escrowShareAtExpiry S D1 r t1 σ T (Z ω) - K) 0 ∂P
        = escrowedCall S K r σ T D1 t1 ∧
      exp (-r * T) * ∫ ω, max (K - escrowShareAtExpiry S D1 r t1 σ T (Z ω)) 0 ∂P
        = escrowedPut S K r σ T D1 t1 := by
  have hfun : ∀ z, escrowShareAtExpiry S D1 r t1 σ T z
      = escrowedSpot S D1 r t1 * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) := fun z => rfl
  have hm1 : Measurable (fun z =>
      max (escrowedSpot S D1 r t1 * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) - K) 0) := by
    fun_prop
  have hm2 : Measurable (fun z =>
      max (K - escrowedSpot S D1 r t1 * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) 0) := by
    fun_prop
  have htr1 : ∫ ω, max (escrowShareAtExpiry S D1 r t1 σ T (Z ω) - K) 0 ∂P =
      ∫ z, max (escrowedSpot S D1 r t1 * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) - K) 0
        ∂(gaussianReal 0 1) := by
    simp only [hfun]
    exact hZ.integral_comp (f := fun z =>
      max (escrowedSpot S D1 r t1 * exp ((r - σ ^ 2 / 2) * T + σ * √T * z) - K) 0)
      hm1.aestronglyMeasurable
  have htr2 : ∫ ω, max (K - escrowShareAtExpiry S D1 r t1 σ T (Z ω)) 0 ∂P =
      ∫ z, max (K - escrowedSpot S D1 r t1 * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) 0
        ∂(gaussianReal 0 1) := by
    simp only [hfun]
    exact hZ.integral_comp (f := fun z =>
      max (K - escrowedSpot S D1 r t1 * exp ((r - σ ^ 2 / 2) * T + σ * √T * z)) 0)
      hm2.aestronglyMeasurable
  rw [htr1, htr2, kd_call_gauss _ K r σ T hS hK hσ hT, kd_put_gauss _ K r σ T hS hK hσ hT]
  unfold escrowedCall escrowedPut blackScholesCall blackScholesPut
  simp only [neg_zero, zero_mul, exp_zero, mul_one]
  exact ⟨trivial, trivial⟩

/-- **Parity with the escrow on the call's side** (Step 2 and its detailed proof). Parcel A (one
call, a bond paying `K` at `T`, a bond paying `D₁` at `t₁` banked to expiry) and parcel B (one
put and one share, its dividend banked to expiry) pay the same on expiry day whatever the share's
final price `s`: `max(s - K, 0) + K + D₁e^(rτ) = max(K - s, 0) + s + D₁e^(rτ)`, with
`τ = T - t₁`. And the escrowed formulas obey `C - P = S - D₀ - K e^(-rT) = S* - K e^(-rT)`. -/
theorem escrowed_put_call_parity (S K r σ T D1 t1 : ℝ) (ht1 : 0 ≤ t1) (ht1T : t1 ≤ T)
    (hS : 0 < escrowedSpot S D1 r t1) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ s : ℝ, max (s - K) 0 + K + D1 * exp (r * (T - t1))
        = max (K - s) 0 + s + D1 * exp (r * (T - t1))) ∧
      escrowedCall S K r σ T D1 t1 - escrowedPut S K r σ T D1 t1
        = S - escrow D1 r t1 - K * exp (-r * T) := by
  refine ⟨fun s => ?_, ?_⟩
  · rcases le_total K s with h | h
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
  · unfold escrowedCall escrowedPut blackScholesCall blackScholesPut escrowedSpot
    simp only [neg_zero, zero_mul, exp_zero, mul_one]
    rw [kd_cdf_neg, kd_cdf_neg]
    ring

/-- **Escrowing is Merton's yield model at one particular yield** (the folded note in Step 3).
With a quoted share `S > 0`, a positive escrowed spot `S*`, strike `K > 0` and expiry `T > 0`,
choose the yield `q = -ln(S*/S)/T`. Then `S e^(-qT) = S*`, and the yield formula on `S` returns
exactly the escrowed call and the escrowed put. -/
theorem escrow_is_merton_yield_formula (S K r σ T D1 t1 : ℝ) (hS0 : 0 < S)
    (hS : 0 < escrowedSpot S D1 r t1) (hK : 0 < K) (hT : 0 < T) :
    let q := -log (escrowedSpot S D1 r t1 / S) / T
    S * exp (-q * T) = escrowedSpot S D1 r t1 ∧
      blackScholesCall S K r q σ T = escrowedCall S K r σ T D1 t1 ∧
      blackScholesPut S K r q σ T = escrowedPut S K r σ T D1 t1 := by
  intro q
  have hq : -q * T = log (escrowedSpot S D1 r t1 / S) := by
    show -(-log (escrowedSpot S D1 r t1 / S) / T) * T = _
    rw [neg_div, neg_neg, div_mul_cancel₀ _ hT.ne']
  have h1 : S * exp (-q * T) = escrowedSpot S D1 r t1 := by
    rw [hq, exp_log (div_pos hS hS0)]; field_simp
  have hd : bsD1 S K r q σ T = bsD1 (escrowedSpot S D1 r t1) K r 0 σ T := by
    unfold bsD1
    congr 1
    have hl : log (S / K) + log (escrowedSpot S D1 r t1 / S)
        = log (escrowedSpot S D1 r t1 / K) := by
      rw [← log_mul (div_pos hS0 hK).ne' (div_pos hS hS0).ne']; congr 1; field_simp
    linear_combination hl + hq
  refine ⟨h1, ?_, ?_⟩
  · unfold escrowedCall blackScholesCall; rw [h1, hd]; simp
  · unfold escrowedPut blackScholesPut; rw [h1, hd]; simp

-- Acme's drift in the escrowed world: r + σ²/2 = 0.05 + 0.20²/2 = 0.07.
example : (5 : ℚ) / 100 + (20 / 100) ^ 2 / 2 = 7 / 100 := by norm_num
-- One wiggle unit at T = 1: σ√T = 0.20.
example : (1 / 5 : ℝ) * √1 = 1 / 5 := by rw [sqrt_one, mul_one]
-- Across the ex-date: the evening before, 100 with 2.00 due at once; the morning after, 98 with
-- nothing left. The escrowed spot is 98 on both days.
example : (100 : ℚ) - 2 = 98 ∧ (98 : ℚ) - 0 = 98 := by norm_num
-- The forward from the carry ledger equals the escrowed spot carried a year:
-- 100 e^(0.05) - 2 e^(0.05 × 0.5) = (100 - 2 e^(-0.05 × 0.5)) e^(0.05 × 1).
example : (100 : ℝ) * exp (5 / 100) - 2 * exp (5 / 100 * (1 - 1 / 2))
    = escrowedSpot 100 2 (5 / 100) (1 / 2) * exp (5 / 100 * 1) := by
  unfold escrowedSpot escrow
  rw [sub_mul, mul_assoc 2, ← exp_add]
  norm_num
-- The exploded tree: 2,000 steps, 1,000 up to the ex-date. Its last layer holds 1,001 × 1,001
-- prices against 2,001 for a recombining tree, five hundred times as many.
example : (1000 + 1) * (1000 + 1) = 1002001 ∧ 1002001 / (2000 + 1) = 500 := by norm_num

#print axioms escrowed_spot_prices_call_and_put
#print axioms escrowed_put_call_parity
#print axioms escrow_is_merton_yield_formula
