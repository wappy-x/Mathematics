-- Quanto option: if the foreign share ends at S e^((μ - σ_S²/2)T + σ_S√T Z) with the slowed growth μ = r_f - q - ρσ_Sσ_X, the fixed-rate call's discounted average payoff is X̄ [S e^((μ - r_d)T) N(d₁) - K e^(-r_d T) N(d₂)], that μ is the one growth that makes a share held in dollars grow at r_d - q, and call minus put is X̄ e^(-r_d T)(S e^(μT) - K).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The quanto drift `μ = r_f - q - ρ σ_S σ_X`: the euro growth `r_f - q` slowed by correlation
times the two volatilities. -/
def quantoDrift (rf q ρ σS σX : ℝ) : ℝ := rf - q - ρ * σS * σX

/-- The share's euro price on expiry day in the dollar pricing world: today's price `S`, growth
`μ`, share volatility `σ_S`, years `T`, and a standard bell-curve draw `z`:
`S_T = S e^((μ - σ_S²/2) T + σ_S √T z)`. -/
noncomputable def shareAtExpiry (S μ σS T z : ℝ) : ℝ :=
  S * exp ((μ - σS ^ 2 / 2) * T + σS * √T * z)

/-- The dollars-per-euro rate on expiry day: today's rate `X₀`, growth `μ_X`, currency volatility
`σ_X`, years `T`. Its bell-curve draw is `ρ z + √(1 - ρ²) w`, which moves with the share's draw
`z` with correlation `ρ` when `z` and `w` are independent standard draws. -/
noncomputable def rateAtExpiry (X₀ μX σX ρ T z w : ℝ) : ℝ :=
  X₀ * exp ((μX - σX ^ 2 / 2) * T + σX * √T * (ρ * z + √(1 - ρ ^ 2) * w))

/-- The card's cut-off `d₁ = (ln(S/K) + (μ + σ_S²/2) T) / (σ_S √T)`; then `d₂ = d₁ - σ_S √T`. -/
noncomputable def quantoD1 (S K μ σS T : ℝ) : ℝ :=
  (log (S / K) + (μ + σS ^ 2 / 2) * T) / (σS * √T)


open Set in
lemma qo_gauss_Ioi_neg (d : ℝ) :
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

#print axioms qo_gauss_Ioi_neg

open Set in
lemma qo_gauss_exp_indicator (b c : ℝ) :
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

#print axioms qo_gauss_exp_indicator

lemma qo_share_eq (S μ σ T z : ℝ) :
    shareAtExpiry S μ σ T z = S * exp ((μ - σ ^ 2 / 2) * T) * exp (σ * √T * z) := by
  rw [shareAtExpiry, exp_add]; ring

#print axioms qo_share_eq

lemma qo_event (S K μ σ T z : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K < shareAtExpiry S μ σ T z ↔ -(quantoD1 S K μ σ T - σ * √T) < z := by
  have hb : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hL : log (K / S) = -log (S / K) := by
    rw [← Real.log_inv, inv_div]
  have hd : quantoD1 S K μ σ T - σ * √T = (log (S / K) + (μ - σ ^ 2 / 2) * T) / (σ * √T) := by
    rw [quantoD1]; field_simp; rw [Real.sq_sqrt hT.le]; ring
  rw [hd, shareAtExpiry, ← div_lt_iff₀' hS, ← Real.log_lt_iff_lt_exp (div_pos hK hS), hL,
    ← neg_div, div_lt_iff₀ hb]
  constructor <;> intro h <;> linarith

#print axioms qo_event

open Set in
lemma qo_share_fun (S K μ σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (fun z => if K < shareAtExpiry S μ σ T z then shareAtExpiry S μ σ T z else 0) =
      fun z => S * exp ((μ - σ ^ 2 / 2) * T) *
        (Ioi (-(quantoD1 S K μ σ T - σ * √T))).indicator (fun z => exp (σ * √T * z)) z := by
  funext z
  by_cases h : -(quantoD1 S K μ σ T - σ * √T) < z
  · have h' := (qo_event S K μ σ T z hS hK hσ hT).mpr h
    rw [ite_eq_left h', indicator_of_mem (show z ∈ Ioi _ from h), qo_share_eq]
  · have h' : ¬ K < shareAtExpiry S μ σ T z :=
      fun h' => h ((qo_event S K μ σ T z hS hK hσ hT).mp h')
    rw [ite_eq_right h', indicator_of_notMem (show z ∉ Ioi _ from h), mul_zero]

#print axioms qo_share_fun

lemma qo_share_integrable (S K μ σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Integrable (fun z => if K < shareAtExpiry S μ σ T z then shareAtExpiry S μ σ T z else 0)
      (gaussianReal 0 1) := by
  rw [qo_share_fun S K μ σ T hS hK hσ hT]
  exact ((integrable_exp_mul_gaussianReal _).indicator measurableSet_Ioi).const_mul _

#print axioms qo_share_integrable

lemma qo_share_gauss (S K μ rd σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-rd * T) * ∫ z, (if K < shareAtExpiry S μ σ T z then shareAtExpiry S μ σ T z else 0)
      ∂(gaussianReal 0 1) =
        S * exp ((μ - rd) * T) * stdNormalCDF (quantoD1 S K μ σ T) := by
  rw [qo_share_fun S K μ σ T hS hK hσ hT, integral_const_mul, qo_gauss_exp_indicator,
    show -(quantoD1 S K μ σ T - σ * √T) - σ * √T = -quantoD1 S K μ σ T by ring, qo_gauss_Ioi_neg]
  have hb : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, Real.sq_sqrt hT.le]
  rw [hb]
  have he : exp (-rd * T) * exp ((μ - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2) =
      exp ((μ - rd) * T) := by
    rw [← exp_add, ← exp_add]; congr 1; ring
  calc _ = S * (exp (-rd * T) * exp ((μ - σ ^ 2 / 2) * T) * exp (σ ^ 2 * T / 2)) *
        stdNormalCDF (quantoD1 S K μ σ T) := by ring
    _ = _ := by rw [he]

#print axioms qo_share_gauss

lemma qo_measurable_share (S μ σ T : ℝ) : Measurable (shareAtExpiry S μ σ T) := by
  unfold shareAtExpiry; fun_prop

#print axioms qo_measurable_share

lemma qo_share_integrable' (S μ σ T : ℝ) :
    Integrable (shareAtExpiry S μ σ T) (gaussianReal 0 1) := by
  have h : shareAtExpiry S μ σ T =
      fun z => S * exp ((μ - σ ^ 2 / 2) * T) * exp (σ * √T * z) := by
    funext z; exact qo_share_eq S μ σ T z
  rw [h]
  exact (integrable_exp_mul_gaussianReal _).const_mul _

#print axioms qo_share_integrable'

lemma qo_share_integral (S μ σ T : ℝ) (hT : 0 < T) :
    ∫ z, shareAtExpiry S μ σ T z ∂(gaussianReal 0 1) = S * exp (μ * T) := by
  have hm : ∫ z, exp (σ * √T * z) ∂(gaussianReal 0 1) = exp (σ ^ 2 * T / 2) := by
    have h := mgf_gaussianReal (HasLaw.id (μ := gaussianReal 0 1)) (σ * √T)
    rw [mgf] at h
    simp only [id] at h
    rw [h, mul_pow, Real.sq_sqrt hT.le]
    congr 1; push_cast; ring
  simp_rw [qo_share_eq]
  rw [integral_const_mul, hm, mul_assoc, ← exp_add]
  congr 2; ring

#print axioms qo_share_integral

lemma qo_call_gauss (S K μ rd σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-rd * T) * ∫ z, max (shareAtExpiry S μ σ T z - K) 0 ∂(gaussianReal 0 1) =
      S * exp ((μ - rd) * T) * stdNormalCDF (quantoD1 S K μ σ T)
        - K * exp (-rd * T) * stdNormalCDF (quantoD1 S K μ σ T - σ * √T) := by
  have hpt : (fun z => max (shareAtExpiry S μ σ T z - K) 0) = fun z =>
      (if K < shareAtExpiry S μ σ T z then shareAtExpiry S μ σ T z else 0) -
        (Set.Ioi (-(quantoD1 S K μ σ T - σ * √T))).indicator (fun _ => K) z := by
    funext z
    by_cases h : K < shareAtExpiry S μ σ T z
    · have h' := (qo_event S K μ σ T z hS hK hσ hT).mp h
      rw [ite_eq_left h, Set.indicator_of_mem (show z ∈ Set.Ioi _ from h'),
        max_eq_left (by linarith)]
    · have h' : ¬ -(quantoD1 S K μ σ T - σ * √T) < z :=
        fun h' => h ((qo_event S K μ σ T z hS hK hσ hT).mpr h')
      rw [ite_eq_right h, Set.indicator_of_notMem (show z ∉ Set.Ioi _ from h'),
        max_eq_right (by linarith)]
      ring
  rw [hpt, integral_sub (qo_share_integrable S K μ σ T hS hK hσ hT)
    ((integrable_const K).indicator measurableSet_Ioi), integral_indicator_const _ measurableSet_Ioi,
    mul_sub, qo_share_gauss S K μ rd σ T hS hK hσ hT, qo_gauss_Ioi_neg, smul_eq_mul]
  ring

#print axioms qo_call_gauss

lemma qo_put_gauss (S K μ σ T : ℝ) :
    ∫ z, max (K - shareAtExpiry S μ σ T z) 0 ∂(gaussianReal 0 1) =
      ∫ z, max (shareAtExpiry S μ σ T z - K) 0 ∂(gaussianReal 0 1)
        - (∫ z, shareAtExpiry S μ σ T z ∂(gaussianReal 0 1) - K) := by
  have hi := qo_share_integrable' S μ σ T
  have hc : Integrable (fun z => max (shareAtExpiry S μ σ T z - K) 0) (gaussianReal 0 1) :=
    (hi.sub (integrable_const K)).pos_part
  have hpt : (fun z => max (K - shareAtExpiry S μ σ T z) 0) = fun z =>
      max (shareAtExpiry S μ σ T z - K) 0 - (shareAtExpiry S μ σ T z - K) := by
    funext z
    rcases le_total K (shareAtExpiry S μ σ T z) with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  have h1 : Integrable (fun z => shareAtExpiry S μ σ T z - K) (gaussianReal 0 1) :=
    hi.sub (integrable_const K)
  have e1 := integral_sub hc h1
  have e2 := integral_sub hi (integrable_const (μ := gaussianReal 0 1) K)
  rw [hpt, e1, e2]
  simp

#print axioms qo_put_gauss

lemma qo_transfer {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (hZ : HasLaw Z (gaussianReal 0 1) Q) {f : ℝ → ℝ} (hf : Measurable f) :
    ∫ ω, f (Z ω) ∂Q = ∫ z, f z ∂(gaussianReal 0 1) :=
  hZ.integral_comp (f := f) hf.aestronglyMeasurable

#print axioms qo_transfer

lemma qo_exp_mean {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (hZ : HasLaw Z (gaussianReal 0 1) Q) (a : ℝ) :
    ∫ ω, exp (a * Z ω) ∂Q = exp (a ^ 2 / 2) := by
  have h := mgf_gaussianReal hZ a
  rw [mgf] at h
  rw [h]; congr 1; push_cast; ring

#print axioms qo_exp_mean

/-- **The quanto call** (The formula; Why it works, Steps 3 and 4). In the dollar pricing world `Q`
the share's log price follows a bell curve with constant volatility `σ_S > 0`, and its growth is
the quanto drift `μ = r_f - q - ρ σ_S σ_X` (constant rates `r_d`, `r_f`, dividend yield `q`,
currency volatility `σ_X`, correlation `ρ`): after `T > 0` years the share is
`S_T = S e^((μ - σ_S²/2) T + σ_S √T Z)` with `Z` a standard bell-curve draw. Today's price is
`S > 0`, the strike is `K > 0`, the fixed rate is `X̄`, and the option is used only on expiry day.
Then the price, `X̄` times the average payoff `max(S_T - K, 0)` discounted at the home rate, is
`X̄ [S e^((μ - r_d) T) N(d₁) - K e^(-r_d T) N(d₂)]`: the Black–Scholes call with the slowed
growth, discounted at home, times the fixed rate. Today's exchange rate appears nowhere. -/
theorem quanto_call_formula
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K Xbar rd rf q σS σX ρ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσS : 0 < σS) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    Xbar * (exp (-rd * T) *
        ∫ ω, max (shareAtExpiry S (quantoDrift rf q ρ σS σX) σS T (Z ω) - K) 0 ∂Q) =
      Xbar * (S * exp ((quantoDrift rf q ρ σS σX - rd) * T) *
            stdNormalCDF (quantoD1 S K (quantoDrift rf q ρ σS σX) σS T)
          - K * exp (-rd * T) *
            stdNormalCDF (quantoD1 S K (quantoDrift rf q ρ σS σX) σS T - σS * √T)) := by
  rw [qo_transfer (f := fun z => max (shareAtExpiry S (quantoDrift rf q ρ σS σX) σS T z - K) 0) hZ
      (((qo_measurable_share _ _ _ _).sub_const K).max measurable_const),
    qo_call_gauss S K _ rd σS T hS hK hσS hT]

/-- **The slowed growth is forced** (Why it works, Steps 1 to 3). Share and exchange rate are two
linked lognormal walks: the share's draw is `Z`, the rate's draw is `ρ Z + √(1 - ρ²) W` with `Z`,
`W` independent standard bell-curve draws, so the two moves have correlation `ρ` with
`-1 ≤ ρ ≤ 1`. The currency grows at `r_d - r_f` (covered interest parity). With `S > 0`,
`X₀ > 0`, `T > 0`: the average dollar value of one share, `S_T X_T`, is `S X₀ e^((r_d - q) T)`,
as a share paying dividend `q` must be in the dollar pricing world, exactly when the share's
growth is `μ = r_f - q - ρ σ_S σ_X`. -/
theorem quanto_drift_iff_share_in_dollars_grows_at_rd_minus_q
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z W : Ω → ℝ}
    (S X₀ μ rd rf q σS σX ρ T : ℝ) (hS : 0 < S) (hX₀ : 0 < X₀) (hT : 0 < T)
    (hρ : -1 ≤ ρ ∧ ρ ≤ 1)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) (hW : HasLaw W (gaussianReal 0 1) Q)
    (hZW : IndepFun Z W Q) :
    ∫ ω, shareAtExpiry S μ σS T (Z ω) * rateAtExpiry X₀ (rd - rf) σX ρ T (Z ω) (W ω) ∂Q =
        S * X₀ * exp ((rd - q) * T) ↔
      μ = quantoDrift rf q ρ σS σX := by
  have hρ2 : 0 ≤ 1 - ρ ^ 2 := by nlinarith [hρ.1, hρ.2]
  set a := σS * √T + σX * √T * ρ with ha
  set b := σX * √T * √(1 - ρ ^ 2) with hb
  set A := (μ - σS ^ 2 / 2) * T + ((rd - rf) - σX ^ 2 / 2) * T with hA
  clear_value a b A
  have hpt : ∀ ω, shareAtExpiry S μ σS T (Z ω) * rateAtExpiry X₀ (rd - rf) σX ρ T (Z ω) (W ω) =
      S * X₀ * exp A * (exp (a * Z ω) * exp (b * W ω)) := by
    intro ω
    unfold shareAtExpiry rateAtExpiry
    rw [mul_assoc (S * X₀) (exp A), ← exp_add, ← exp_add, mul_mul_mul_comm, ← exp_add]
    congr 2
    rw [ha, hb, hA]; ring
  simp_rw [hpt]
  rw [integral_const_mul,
    hZW.integral_fun_comp_mul_comp (f := fun z => exp (a * z)) (g := fun w => exp (b * w))
      hZ.aemeasurable hW.aemeasurable (by fun_prop) (by fun_prop),
    qo_exp_mean hZ, qo_exp_mean hW]
  have hab : A + a ^ 2 / 2 + b ^ 2 / 2 - (rd - q) * T = T * (μ - quantoDrift rf q ρ σS σX) := by
    have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
    have hr2 : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt hρ2
    rw [ha, hb, hA, quantoDrift]
    linear_combination ((σS + σX * ρ) ^ 2 / 2 + σX ^ 2 * √(1 - ρ ^ 2) ^ 2 / 2) * hT2
      + σX ^ 2 * T / 2 * hr2
  have hSX : S * X₀ ≠ 0 := (mul_pos hS hX₀).ne'
  rw [show S * X₀ * exp A * (exp (a ^ 2 / 2) * exp (b ^ 2 / 2)) =
      S * X₀ * exp (A + a ^ 2 / 2 + b ^ 2 / 2) by rw [exp_add, exp_add]; ring,
    mul_right_inj' hSX, exp_eq_exp]
  constructor
  · intro h
    have h0 : T * (μ - quantoDrift rf q ρ σS σX) = 0 := by rw [← hab, h]; ring
    rcases mul_eq_zero.mp h0 with h1 | h1
    · exact absurd h1 hT.ne'
    · linarith
  · intro h
    have h0 : T * (μ - quantoDrift rf q ρ σS σX) = 0 := by rw [h]; ring
    linarith

/-- **Quanto put-call parity** (The formula). In the same model, with `S > 0`, `K > 0`,
`σ_S > 0`, `T > 0` and `Z` a standard bell-curve draw: the quanto call minus the quanto put,
each `X̄` times its discounted average payoff, is a forward paid at the fixed rate,
`C - P = X̄ e^(-r_d T) (S e^(μ T) - K)`, with `S e^(μT)` the quanto forward. -/
theorem quanto_put_call_parity
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K Xbar rd rf q σS σX ρ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσS : 0 < σS) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    Xbar * (exp (-rd * T) *
        ∫ ω, max (shareAtExpiry S (quantoDrift rf q ρ σS σX) σS T (Z ω) - K) 0 ∂Q)
      - Xbar * (exp (-rd * T) *
        ∫ ω, max (K - shareAtExpiry S (quantoDrift rf q ρ σS σX) σS T (Z ω)) 0 ∂Q) =
      Xbar * exp (-rd * T) * (S * exp (quantoDrift rf q ρ σS σX * T) - K) := by
  rw [qo_transfer (f := fun z => max (shareAtExpiry S (quantoDrift rf q ρ σS σX) σS T z - K) 0) hZ
      (((qo_measurable_share _ _ _ _).sub_const K).max measurable_const),
    qo_transfer (f := fun z => max (K - shareAtExpiry S (quantoDrift rf q ρ σS σX) σS T z) 0) hZ
      ((measurable_const.sub (qo_measurable_share _ _ _ _)).max measurable_const),
    qo_put_gauss, qo_share_integral _ _ _ _ hT]
  ring

-- House quanto: S = K = 100 EUR, X̄ = 1.10, r_d = 5%, r_f = 3%, q = 1%, σ_S = 20%, σ_X = 10%,
-- ρ = 0.30, T = 1 year.
-- Step 1: moving together, 1.01 × 1.01 = 1.0201; moving apart, 1.01 × 0.99 = 0.9999.
example : (101 / 100 : ℚ) * (101 / 100) = 10201 / 10000 := by norm_num
example : (101 / 100 : ℚ) * (99 / 100) = 9999 / 10000 := by norm_num
-- Euro growth r_f - q = 2%; currency growth r_d - r_f = 2%.
example : (3 / 100 : ℚ) - 1 / 100 = 2 / 100 ∧ (5 / 100 : ℚ) - 3 / 100 = 2 / 100 := by norm_num
-- The adjustment ρ σ_S σ_X = 0.30 × 0.20 × 0.10 = 0.006.
example : (30 / 100 : ℚ) * (20 / 100) * (10 / 100) = 6 / 1000 := by norm_num
-- Quanto drift μ = 0.03 - 0.01 - 0.006 = 0.014.
example : quantoDrift (3 / 100) (1 / 100) (30 / 100) (20 / 100) (10 / 100) = 14 / 1000 := by
  norm_num [quantoDrift]
-- d₁ = (ln(100/100) + (0.014 + 0.02) · 1) / (0.20 · √1) = 0.17.
example : quantoD1 100 100 (14 / 1000) (20 / 100) 1 = 17 / 100 := by
  norm_num [quantoD1]
-- d₂ = 0.17 - 0.20 = -0.03.
example : (17 / 100 : ℚ) - 20 / 100 * 1 = -3 / 100 := by norm_num
-- Step 3: μ + (r_d - r_f) + ρ σ_S σ_X = r_d - q, that is 0.014 + 0.02 + 0.006 = 0.04.
example : (14 / 1000 : ℚ) + (5 / 100 - 3 / 100) + 6 / 1000 = 5 / 100 - 1 / 100 := by norm_num
-- The other door: q* = r_d - r_f + q + ρ σ_S σ_X = 3.6%, and r_d - q* = μ.
example : (5 / 100 : ℚ) - 3 / 100 + 1 / 100 + 6 / 1000 = 36 / 1000 ∧
    (5 / 100 : ℚ) - 36 / 1000 = 14 / 1000 := by norm_num
-- Premium on 10,000 shares: 10,000 × 9.151629 = 91,516.29 USD.
example : (10000 : ℚ) * (9151629 / 1000000) = 9151629 / 100 := by norm_num
-- Hand-worked call: 1.10 × (54.742848 - 46.423185) = 9.1516293.
example : (110 / 100 : ℚ) * (54742848 / 1000000 - 46423185 / 1000000) = 91516293 / 10000000 := by
  norm_num
-- Profit chart: X̄ max(S_T - K, 0) - 9.15 at 90, 105 and 110 EUR is -9.15, -3.65 and 1.85 USD.
example : (110 / 100 : ℚ) * max (90 - 100) 0 - 915 / 100 = -915 / 100 := by norm_num
example : (110 / 100 : ℚ) * max (105 - 100) 0 - 915 / 100 = -365 / 100 := by norm_num
example : (110 / 100 : ℚ) * max (110 - 100) 0 - 915 / 100 = 185 / 100 := by norm_num

#print axioms quanto_call_formula
#print axioms quanto_drift_iff_share_in_dollars_grows_at_rd_minus_q
#print axioms quanto_put_call_parity
