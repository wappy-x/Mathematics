-- Options on a futures price: if the futures quote ends lognormally at F e^(-σ²T/2 + σ√T Z), the average call payoff is the Black-76 bracket F N(d₁) - K N(d₂), the up-front call and put are that average discounted once to the option's expiry, the margined quote is the up-front call divided by the discount factor, the spot price drops out of every spot-and-yield route that reproduces the quote, and a margined option is always worth at least its exercise value.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The futures quote on the option's expiry day in the card's model: today's quote `F`, the
quote's volatility `σ`, the time `T` to the option's expiry, and a standard bell-curve draw `z`:
`F_T = F e^(-σ²T/2 + σ√T z)`. The quote drifts nowhere (Step 0). -/
noncomputable def futuresAtExpiry (F σ T z : ℝ) : ℝ :=
  F * exp (-(σ ^ 2 * T) / 2 + σ * √T * z)

/-- The first distance `d₁ = (ln(F/K) + σ²T/2) / (σ√T)`; the second is `d₂ = d₁ - σ√T`. -/
noncomputable def black76D1 (F K σ T : ℝ) : ℝ :=
  (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)

/-- The Black-76 bracket `F N(d₁) - K N(d₂)`: the margined quote `V`. -/
noncomputable def black76Bracket (F K σ T : ℝ) : ℝ :=
  F * stdNormalCDF (black76D1 F K σ T) - K * stdNormalCDF (black76D1 F K σ T - σ * √T)

/-- The Black-76 call premium paid up front, `C = e^(-rT) [F N(d₁) - K N(d₂)]`. -/
noncomputable def black76Call (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * black76Bracket F K σ T

/-- The Black-76 put premium paid up front, `P = e^(-rT) [K N(-d₂) - F N(-d₁)]`. -/
noncomputable def black76Put (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * (K * stdNormalCDF (-(black76D1 F K σ T - σ * √T))
    - F * stdNormalCDF (-black76D1 F K σ T))

/-- The spot route (Step 3): the Black-Scholes call on a spot price `S` that earns a net
convenience yield `y` in the dividend's place,
`C = S e^(-yT) N(d₁) - K e^(-rT) N(d₁ - σ√T)`, with
`d₁ = (ln(S/K) + (r - y + σ²/2) T) / (σ√T)`. -/
noncomputable def blackScholesCallWithYield (S K r y σ T : ℝ) : ℝ :=
  let d1 := (log (S / K) + (r - y + σ ^ 2 / 2) * T) / (σ * √T)
  S * exp (-y * T) * stdNormalCDF d1 - K * exp (-r * T) * stdNormalCDF (d1 - σ * √T)

section helpers
open Set

lemma b76_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal; fun_prop

lemma b76_N_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ ↦ gaussianPDFReal_nonneg 0 1 t))]

lemma b76_hasDerivAt_N (x : ℝ) : HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hint : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Iic a) :=
    fun a ↦ (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun y ↦ stdNormalCDF 0 + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [b76_N_eq_integral, b76_N_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic (hint 0)
      (hint y)]
    ring
  rw [heq]
  exact ((b76_continuous_pdf.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma b76_continuous_N : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x ↦ (b76_hasDerivAt_N x).continuousAt

lemma b76_real_Ioi (b : ℝ) : (gaussianReal 0 1).real (Ioi b) = 1 - stdNormalCDF b := by
  rw [← compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic, stdNormalCDF, cdf_eq_real]

lemma b76_N_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  rw [← b76_real_Ioi]
  have hmap : (gaussianReal 0 1).map (fun x ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  have hsing : gaussianReal 0 1 {x} = 0 :=
    gaussianReal_absolutelyContinuous 0 one_ne_zero (Real.volume_singleton)
  rw [stdNormalCDF, cdf_eq_real, ← hmap, map_measureReal_apply measurable_neg measurableSet_Iic,
    hmap, measureReal_congr (Ioi_ae_eq_Ici' hsing)]
  congr 1
  ext t; simp

lemma b76_real_Ioi' (b : ℝ) : (gaussianReal 0 1).real (Ioi b) = stdNormalCDF (-b) := by
  rw [b76_real_Ioi, b76_N_neg]

lemma b76_pdf_shift (s z : ℝ) :
    gaussianPDFReal 0 1 z * exp (-s ^ 2 / 2 + s * z) = gaussianPDFReal s 1 z := by
  unfold gaussianPDFReal
  simp only [NNReal.coe_one, mul_one]
  rw [mul_assoc, ← exp_add]
  congr 2
  ring

lemma b76_setIntegral_exp (s : ℝ) {A : Set ℝ} (hA : MeasurableSet A) :
    ∫ z in A, exp (-s ^ 2 / 2 + s * z) ∂(gaussianReal 0 1) = (gaussianReal s 1).real A := by
  rw [← integral_indicator hA, integral_gaussianReal_eq_integral_smul one_ne_zero]
  have : ∀ z, gaussianPDFReal 0 1 z • A.indicator (fun z ↦ exp (-s ^ 2 / 2 + s * z)) z
      = A.indicator (gaussianPDFReal s 1) z := by
    intro z
    by_cases hz : z ∈ A
    · simp [hz, b76_pdf_shift]
    · simp [hz]
  simp_rw [this]
  rw [integral_indicator hA, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg hA (fun t _ ↦ gaussianPDFReal_nonneg s 1 t))]

lemma b76_shift_Ioi (s b : ℝ) :
    (gaussianReal s 1).real (Ioi b) = stdNormalCDF (s - b) := by
  have h := gaussianReal_map_add_const (μ := 0) (v := 1) s
  rw [zero_add] at h
  rw [← h, map_measureReal_apply (measurable_add_const s) measurableSet_Ioi,
    preimage_add_const_Ioi, b76_real_Ioi']
  ring_nf

lemma b76_integrable_exp (s : ℝ) :
    Integrable (fun z ↦ exp (-s ^ 2 / 2 + s * z)) (gaussianReal 0 1) := by
  have := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) s).const_mul (exp (-s ^ 2 / 2))
  simpa [← exp_add] using this

lemma b76_forward_eq (F σ T : ℝ) (hT : 0 < T) (z : ℝ) :
    futuresAtExpiry F σ T z = F * exp (-(σ * √T) ^ 2 / 2 + (σ * √T) * z) := by
  unfold futuresAtExpiry
  rw [mul_pow, sq_sqrt hT.le]

lemma b76_continuous_forward (F σ T : ℝ) : Continuous (futuresAtExpiry F σ T) := by
  unfold futuresAtExpiry; fun_prop

lemma b76_integrable_forward (F σ T : ℝ) (hT : 0 < T) :
    Integrable (futuresAtExpiry F σ T) (gaussianReal 0 1) := by
  have : futuresAtExpiry F σ T = fun z ↦ F * exp (-(σ * √T) ^ 2 / 2 + (σ * √T) * z) :=
    funext (b76_forward_eq F σ T hT)
  rw [this]
  exact (b76_integrable_exp _).const_mul F

lemma b76_integral_forward (F σ T : ℝ) (hT : 0 < T) :
    ∫ z, futuresAtExpiry F σ T z ∂(gaussianReal 0 1) = F := by
  have : futuresAtExpiry F σ T = fun z ↦ F * exp (-(σ * √T) ^ 2 / 2 + (σ * √T) * z) :=
    funext (b76_forward_eq F σ T hT)
  rw [this, integral_const_mul, ← setIntegral_univ, b76_setIntegral_exp _ MeasurableSet.univ]
  simp

lemma b76_call_integral (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    ∫ z, max (futuresAtExpiry F σ T z - K) 0 ∂(gaussianReal 0 1) =
      F * stdNormalCDF (black76D1 F K σ T) - K * stdNormalCDF (black76D1 F K σ T - σ * √T) := by
  set s := σ * √T with hs_def
  have hs : 0 < s := mul_pos hσ (sqrt_pos.2 hT)
  have hd1 : black76D1 F K σ T = (log (F / K) + s ^ 2 / 2) / s := by
    unfold black76D1
    rw [hs_def, mul_pow, sq_sqrt hT.le]
  set d1 := black76D1 F K σ T
  set b := -(d1 - s) with hb
  have key : ∀ z, (0 < F * exp (-s ^ 2 / 2 + s * z) - K ↔ b < z) := by
    intro z
    have hsb : s * b = s ^ 2 / 2 - log (F / K) := by
      rw [hb, hd1]; field_simp; ring
    have hlog : log (F / K) = log F - log K := log_div hF.ne' hK.ne'
    rw [sub_pos, ← Real.log_lt_log_iff hK (by positivity), Real.log_mul hF.ne' (exp_pos _).ne',
      Real.log_exp]
    constructor
    · intro h
      have : s * b < s * z := by rw [hsb, hlog]; linarith
      exact lt_of_mul_lt_mul_left this hs.le
    · intro h
      have := mul_lt_mul_of_pos_left h hs
      rw [hsb, hlog] at this
      linarith
  have hpt : ∀ z, max (futuresAtExpiry F σ T z - K) 0 =
      (Ioi b).indicator (fun z ↦ F * exp (-s ^ 2 / 2 + s * z) - K) z := by
    intro z
    rw [b76_forward_eq F σ T hT z]
    by_cases hz : b < z
    · rw [indicator_of_mem (show z ∈ Ioi b from hz), max_eq_left ((key z).2 hz).le]
    · rw [indicator_of_notMem (show z ∉ Ioi b from hz), max_eq_right (not_lt.1 (mt (key z).1 hz))]
  simp_rw [hpt]
  rw [integral_indicator measurableSet_Ioi, integral_sub, integral_const_mul,
    b76_setIntegral_exp _ measurableSet_Ioi, setIntegral_const, b76_shift_Ioi, b76_real_Ioi']
  · simp only [smul_eq_mul, hb]
    ring_nf
  · exact ((b76_integrable_exp s).const_mul F).integrableOn
  · exact integrableOn_const

lemma b76_put_integral (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    ∫ z, max (K - futuresAtExpiry F σ T z) 0 ∂(gaussianReal 0 1) =
      F * stdNormalCDF (black76D1 F K σ T) - K * stdNormalCDF (black76D1 F K σ T - σ * √T)
        - (F - K) := by
  have hpt : ∀ z, max (K - futuresAtExpiry F σ T z) 0 =
      max (futuresAtExpiry F σ T z - K) 0 - (futuresAtExpiry F σ T z - K) := by
    intro z
    rcases max_cases (K - futuresAtExpiry F σ T z) 0 with h | h <;>
      rcases max_cases (futuresAtExpiry F σ T z - K) 0 with h' | h' <;> linarith
  have hfwd := b76_integrable_forward F σ T hT
  simp_rw [hpt]
  have h1 : Integrable (fun z ↦ futuresAtExpiry F σ T z - K) (gaussianReal 0 1) :=
    hfwd.sub (integrable_const K)
  rw [integral_sub h1.pos_part h1, integral_sub hfwd (integrable_const K), b76_call_integral F K σ T hF hK hσ hT,
    b76_integral_forward F σ T hT]
  simp

#print axioms b76_continuous_pdf
#print axioms b76_N_eq_integral
#print axioms b76_hasDerivAt_N
#print axioms b76_continuous_N
#print axioms b76_real_Ioi
#print axioms b76_N_neg
#print axioms b76_real_Ioi'
#print axioms b76_pdf_shift
#print axioms b76_setIntegral_exp
#print axioms b76_shift_Ioi
#print axioms b76_integrable_exp
#print axioms b76_forward_eq
#print axioms b76_continuous_forward
#print axioms b76_integrable_forward
#print axioms b76_integral_forward
#print axioms b76_call_integral
#print axioms b76_put_integral

end helpers

/-- **An option on a commodity future is Black-76 on the futures quote** (The formula; Steps 1,
2 and 4). Take the futures quote to wander lognormally with one volatility `σ > 0` and no drift,
so that on the option's expiry day, `T > 0` years away, it is `F_T = F e^(-σ²T/2 + σ√T Z)` with
`Z` a standard bell-curve draw; take today's quote `F > 0` and the strike `K > 0`; the option is
exercised on its expiry day and the cash moves that day; the bank rate `r` is known, giving the
discount factor `D = e^(-rT)`. Then the plain average of the call's payoff `(F_T - K)⁺` is the
bracket `F N(d₁) - K N(d₂)`; the call paid up front, `D` times that average, is
`C = D [F N(d₁) - K N(d₂)]`; the put paid up front, `D` times the average of `(K - F_T)⁺`, is
`P = D [K N(-d₂) - F N(-d₁)]`; and the margined quote, the average with no discount, is
`V = C / D`. -/
theorem futures_option_is_black76_on_the_futures_quote
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {Z : Ω → ℝ}
    (F K r σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) P) :
    ∫ ω, max (futuresAtExpiry F σ T (Z ω) - K) 0 ∂P = black76Bracket F K σ T ∧
      exp (-r * T) * ∫ ω, max (futuresAtExpiry F σ T (Z ω) - K) 0 ∂P = black76Call F K r σ T ∧
      exp (-r * T) * ∫ ω, max (K - futuresAtExpiry F σ T (Z ω)) 0 ∂P = black76Put F K r σ T ∧
      ∫ ω, max (futuresAtExpiry F σ T (Z ω) - K) 0 ∂P = black76Call F K r σ T / exp (-r * T) := by
  have hc : Continuous (fun z ↦ max (futuresAtExpiry F σ T z - K) 0) :=
    ((b76_continuous_forward F σ T).sub continuous_const).max continuous_const
  have hp : Continuous (fun z ↦ max (K - futuresAtExpiry F σ T z) 0) :=
    (continuous_const.sub (b76_continuous_forward F σ T)).max continuous_const
  have e1 := hZ.integral_comp hc.aestronglyMeasurable
  have e2 := hZ.integral_comp hp.aestronglyMeasurable
  simp only [Function.comp_def] at e1 e2
  rw [e1, e2, b76_call_integral F K σ T hF hK hσ hT, b76_put_integral F K σ T hF hK hσ hT]
  unfold black76Call black76Put black76Bracket
  rw [b76_N_neg, b76_N_neg]
  refine ⟨rfl, rfl, by ring, ?_⟩
  rw [mul_div_cancel_left₀ _ (exp_pos _).ne']

/-- **The spot drops out** (Step 3). For any spot price `S > 0` and net convenience yield `y`
chosen so that the futures quote is `F = S e^((r - y)T)`, with strike `K > 0`, volatility
`σ > 0` and time `T > 0` to the option's expiry, the Black-Scholes call fed with the spot and
the yield equals the Black-76 call on the futures quote: the spot and the yield enter only
through `F`. -/
theorem spot_drops_out_of_the_futures_option
    (S F K r y σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hFS : F = S * exp ((r - y) * T)) :
    blackScholesCallWithYield S K r y σ T = black76Call F K r σ T := by
  subst hFS
  unfold blackScholesCallWithYield black76Call black76Bracket black76D1
  have hlog : log (S * exp ((r - y) * T) / K) = log (S / K) + (r - y) * T := by
    rw [mul_div_right_comm, log_mul (div_pos hS hK).ne' (exp_pos _).ne', log_exp]
  have hd : (log (S / K) + (r - y + σ ^ 2 / 2) * T) / (σ * √T) =
      (log (S * exp ((r - y) * T) / K) + σ ^ 2 * T / 2) / (σ * √T) := by
    rw [hlog]; ring
  have he : exp (-r * T) * (S * exp ((r - y) * T)) = S * exp (-y * T) := by
    rw [mul_left_comm, ← exp_add]; ring_nf
  dsimp only
  rw [hd]
  set X := (log (S * exp ((r - y) * T) / K) + σ ^ 2 * T / 2) / (σ * √T)
  linear_combination (-(stdNormalCDF X)) * he

/-- **A margined option is never worth exercising early** (Step 4). Under the pricing rule, a
probability, let the futures quote at expiry `X` be integrable with average equal to the quote
`F'` now (the quote averages to itself). Then keeping the margined call, worth the plain average
of `(X - K)⁺`, is worth at least exercising it now for `(F' - K)⁺`. -/
theorem margined_call_worth_at_least_exercise_value
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P] {X : Ω → ℝ}
    (F' K : ℝ) (hX : Integrable X P) (hmean : ∫ ω, X ω ∂P = F') :
    max (F' - K) 0 ≤ ∫ ω, max (X ω - K) 0 ∂P := by
  have h1 : Integrable (fun ω ↦ X ω - K) P := hX.sub (integrable_const K)
  have hpos : Integrable (fun ω ↦ max (X ω - K) 0) P := h1.pos_part
  have hlow : F' - K ≤ ∫ ω, max (X ω - K) 0 ∂P := by
    have : ∫ ω, X ω - K ∂P = F' - K := by
      rw [integral_sub hX (integrable_const K), hmean]; simp
    rw [← this]
    exact integral_mono h1 hpos (fun ω ↦ le_max_left _ _)
  have hnn : 0 ≤ ∫ ω, max (X ω - K) 0 ∂P :=
    integral_nonneg (fun ω ↦ le_max_right _ _)
  exact max_le hlow hnn

/-- The card's chart: the call's settlement per barrel, `max(F_T - 85, 0)`, at the futures prices
65, 70, ..., 105 on expiry day. -/
example :
    [65, 70, 75, 80, 85, 90, 95, 100, 105].map (fun x : ℤ => max (x - 85) 0) =
      [0, 0, 0, 0, 0, 5, 10, 15, 20] := by
  decide

#print axioms futures_option_is_black76_on_the_futures_quote
#print axioms spot_drops_out_of_the_futures_option
#print axioms margined_call_worth_at_least_exercise_value
