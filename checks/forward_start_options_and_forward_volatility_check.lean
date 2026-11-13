-- Forward-start options: in the Black-Scholes model a call whose strike is set at the reset date as a multiple of the share price then is worth today S e^(-q t₁) times the unit call on a one-dollar share over the life after the reset, whatever the volatility before the reset, and that price rises strictly with the forward volatility onto exactly the interval between its floor and ceiling, so each quote there gives back one forward volatility.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The first distance of the unit call,
`d₁ = (-ln α + (r - q + σ²/2) τ) / (σ√τ)`; the second is `d₂ = d₁ - σ√τ`. -/
noncomputable def unitD1 (α r q σ τ : ℝ) : ℝ :=
  (-log α + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ)

/-- The unit call `c = e^(-qτ) N(d₁) - α e^(-rτ) N(d₂)`: the Black-Scholes call on a share worth
one dollar, struck at the multiple `α`, over the life `τ` left after the reset. -/
noncomputable def unitCall (α r q σ τ : ℝ) : ℝ :=
  exp (-q * τ) * stdNormalCDF (unitD1 α r q σ τ)
    - α * exp (-r * τ) * stdNormalCDF (unitD1 α r q σ τ - σ * √τ)

/-- The ordinary Black-Scholes call on a share at `x`, struck at `K`, over `τ` years:
`x e^(-qτ) N(d₁) - K e^(-rτ) N(d₂)` with `d₁ = (ln(x/K) + (r - q + σ²/2) τ) / (σ√τ)`. -/
noncomputable def bsCall (x K r q σ τ : ℝ) : ℝ :=
  x * exp (-q * τ) * stdNormalCDF ((log (x / K) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ))
    - K * exp (-r * τ) *
      stdNormalCDF ((log (x / K) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ) - σ * √τ)

/-- The forward-start formula `C_fs = S e^(-q t₁) c`, with the unit call run over `τ = T - t₁`
at the volatility `σ` between the reset and expiry. -/
noncomputable def fwdStartPrice (S α r q σ t₁ T : ℝ) : ℝ :=
  S * exp (-q * t₁) * unitCall α r q σ (T - t₁)

lemma stdNormalCDF_eq_real (x : ℝ) : stdNormalCDF x = (gaussianReal 0 1).real (Iic x) :=
  cdf_eq_real _ x

#print axioms stdNormalCDF_eq_real

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [stdNormalCDF_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

#print axioms stdNormalCDF_eq_integral

lemma continuous_stdPDF : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal; fun_prop

#print axioms continuous_stdPDF

lemma hasDerivAt_stdNormalCDF (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI y), stdNormalCDF_eq_integral,
      stdNormalCDF_eq_integral]
    ring
  rw [heq]
  exact ((continuous_stdPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

#print axioms hasDerivAt_stdNormalCDF

lemma continuous_stdNormalCDF : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (hasDerivAt_stdNormalCDF x).continuousAt

#print axioms continuous_stdNormalCDF

lemma stdNormal_real_Ioi (z : ℝ) : (gaussianReal 0 1).real (Ioi z) = stdNormalCDF (-z) := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have h2 : (gaussianReal 0 1).real (Iic (-z)) = (gaussianReal 0 1).real (Ici z) := by
    have := gaussianReal_map_neg (μ := 0) (v := 1)
    rw [neg_zero] at this
    conv_lhs => rw [← this]
    rw [map_measureReal_apply measurable_neg measurableSet_Iic]
    congr 1; ext x; simp
  rw [stdNormalCDF_eq_real, h2, measureReal_congr Ioi_ae_eq_Ici]

#print axioms stdNormal_real_Ioi

lemma stdNormal_tilt (s z : ℝ) :
    ∫ y in Ioi z, exp (s * y) ∂(gaussianReal 0 1) = exp (s ^ 2 / 2) * stdNormalCDF (s - z) := by
  have hpt : ∀ y, gaussianPDFReal 0 1 y * exp (s * y) = exp (s ^ 2 / 2) * gaussianPDFReal s 1 y := by
    intro y
    have key : exp (-y ^ 2 / 2) * exp (s * y) = exp (s ^ 2 / 2) * exp (-(y - s) ^ 2 / 2) := by
      rw [← exp_add, ← exp_add]; ring_nf
    simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
    linear_combination (√(2 * π))⁻¹ * key
  have h1 : ∫ y in Ioi z, exp (s * y) ∂(gaussianReal 0 1)
      = exp (s ^ 2 / 2) * ∫ y in Ioi z, gaussianPDFReal s 1 y := by
    rw [← integral_indicator measurableSet_Ioi, integral_gaussianReal_eq_integral_smul one_ne_zero,
      ← integral_const_mul, ← integral_indicator measurableSet_Ioi]
    congr 1; funext y
    by_cases hy : y ∈ Ioi z
    · simp [indicator_of_mem hy, hpt]
    · simp [indicator_of_notMem hy]
  have h2 : ∫ y in Ioi z, gaussianPDFReal s 1 y = (gaussianReal s 1).real (Ioi z) := by
    rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero, ENNReal.toReal_ofReal]
    exact setIntegral_nonneg measurableSet_Ioi (fun t _ => gaussianPDFReal_nonneg _ _ _)
  have h3 : (gaussianReal s 1).real (Ioi z) = (gaussianReal 0 1).real (Ioi (z - s)) := by
    have := gaussianReal_map_add_const (μ := 0) (v := 1) s
    rw [zero_add] at this
    rw [← this, map_measureReal_apply (measurable_add_const s) measurableSet_Ioi]
    congr 1; ext x; simp [sub_lt_iff_lt_add]
  rw [h1, h2, h3, stdNormal_real_Ioi, neg_sub]

#print axioms stdNormal_tilt

lemma stdNormal_call (c s α : ℝ) (hs : 0 < s) (hα : 0 < α) :
    ∫ y, max (exp (c + s * y) - α) 0 ∂(gaussianReal 0 1)
      = exp (c + s ^ 2 / 2) * stdNormalCDF ((c - log α) / s + s)
        - α * stdNormalCDF ((c - log α) / s) := by
  set z := (log α - c) / s with hz
  have hpt : (fun y => max (exp (c + s * y) - α) 0)
      = indicator (Ioi z) (fun y => exp c * exp (s * y) - α) := by
    funext y
    by_cases hy : y ∈ Ioi z
    · rw [indicator_of_mem hy, ← exp_add]
      refine max_eq_left (sub_nonneg.2 ?_)
      have : log α < c + s * y := by
        have := (div_lt_iff₀ hs).1 (mem_Ioi.1 hy); linarith
      calc α = exp (log α) := (exp_log hα).symm
        _ ≤ exp (c + s * y) := exp_le_exp.2 this.le
    · rw [indicator_of_notMem hy]
      refine max_eq_right (sub_nonpos.2 ?_)
      have : c + s * y ≤ log α := by
        have := (le_div_iff₀ hs).1 (not_lt.1 hy); linarith
      calc exp (c + s * y) ≤ exp (log α) := exp_le_exp.2 this
        _ = α := exp_log hα
  rw [hpt, integral_indicator measurableSet_Ioi, integral_sub, integral_const_mul,
    stdNormal_tilt, setIntegral_const, stdNormal_real_Ioi, smul_eq_mul, exp_add]
  · have e1 : s - z = (c - log α) / s + s := by rw [hz]; field_simp; ring
    have e2 : -z = (c - log α) / s := by rw [hz]; field_simp; ring
    rw [e1, e2]; ring
  · exact ((integrable_exp_mul_gaussianReal s).const_mul _).integrableOn
  · exact integrableOn_const

#print axioms stdNormal_call

lemma gaussian_exp_mean (S a b : ℝ) :
    ∫ x, S * exp (a + b * x) ∂(gaussianReal 0 1) = S * exp a * exp (b ^ 2 / 2) := by
  have h := congrFun (mgf_id_gaussianReal (μ := 0) (v := 1)) b
  simp only [mgf, id, zero_mul, NNReal.coe_one, one_mul, zero_add] at h
  simp_rw [exp_add, ← mul_assoc]
  rw [integral_const_mul, h]

#print axioms gaussian_exp_mean

lemma unitD1_eq (α r q σ τ : ℝ) (hσ : 0 < σ) (hτ : 0 < τ) :
    unitD1 α r q σ τ = ((r - q - σ ^ 2 / 2) * τ - log α) / (σ * √τ) + σ * √τ := by
  have hs : 0 < √τ := sqrt_pos.2 hτ
  have hsq : √τ ^ 2 = τ := sq_sqrt hτ.le
  unfold unitD1
  field_simp
  linear_combination (-2 * σ ^ 2) * hsq

#print axioms unitD1_eq

open Filter in
lemma unit_G_hasDerivAt (a b u : ℝ) (hu : 0 < u) :
    HasDerivAt (fun u => exp a * stdNormalCDF ((a - b) / u + u / 2)
        - exp b * stdNormalCDF ((a - b) / u - u / 2))
      (exp a * gaussianPDFReal 0 1 ((a - b) / u + u / 2)) u := by
  have hinv := (hasDerivAt_inv hu.ne').const_mul (a - b)
  have h1 := hinv.add ((hasDerivAt_id u).div_const 2)
  have h2 := hinv.sub ((hasDerivAt_id u).div_const 2)
  have hN1 := ((hasDerivAt_stdNormalCDF _).comp u h1).const_mul (exp a)
  have hN2 := ((hasDerivAt_stdNormalCDF _).comp u h2).const_mul (exp b)
  have key : exp a * gaussianPDFReal 0 1 ((a - b) / u + u / 2)
      = exp b * gaussianPDFReal 0 1 ((a - b) / u - u / 2) := by
    simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
    rw [mul_left_comm, ← exp_add, mul_left_comm (exp b), ← exp_add]
    congr 2
    field_simp
    ring
  convert hN1.sub hN2 using 1
  · funext y; simp [Function.comp, div_eq_mul_inv]
  · simp only [id, div_eq_mul_inv] at key ⊢
    have hu2 : u ^ 2 ≠ 0 := by positivity
    linear_combination ((a - b) * (u ^ 2)⁻¹ + 2⁻¹) * key

#print axioms unit_G_hasDerivAt

open Filter in
lemma unit_G_continuousOn (a b : ℝ) :
    ContinuousOn (fun u => exp a * stdNormalCDF ((a - b) / u + u / 2)
        - exp b * stdNormalCDF ((a - b) / u - u / 2)) (Ioi 0) :=
  fun x hx => (unit_G_hasDerivAt a b x hx).continuousAt.continuousWithinAt

#print axioms unit_G_continuousOn

open Filter in
lemma unit_G_strictMonoOn (a b : ℝ) :
    StrictMonoOn (fun u => exp a * stdNormalCDF ((a - b) / u + u / 2)
        - exp b * stdNormalCDF ((a - b) / u - u / 2)) (Ioi 0) := by
  refine strictMonoOn_of_deriv_pos (convex_Ioi 0) (unit_G_continuousOn a b) ?_
  intro x hx
  rw [interior_Ioi] at hx
  rw [(unit_G_hasDerivAt a b x hx).deriv]
  exact mul_pos (exp_pos a) (gaussianPDFReal_pos _ _ _ one_ne_zero)

#print axioms unit_G_strictMonoOn

open Filter in
lemma tendsto_stdNormalCDF_atTop : Tendsto stdNormalCDF atTop (nhds 1) :=
  tendsto_cdf_atTop _

#print axioms tendsto_stdNormalCDF_atTop

open Filter in
lemma tendsto_stdNormalCDF_atBot : Tendsto stdNormalCDF atBot (nhds 0) :=
  tendsto_cdf_atBot _

#print axioms tendsto_stdNormalCDF_atBot

open Filter in
lemma unit_G_tendsto_atTop (a b : ℝ) :
    Tendsto (fun u => exp a * stdNormalCDF ((a - b) / u + u / 2)
        - exp b * stdNormalCDF ((a - b) / u - u / 2)) atTop (nhds (exp a)) := by
  have h0 : Tendsto (fun u : ℝ => (a - b) / u) atTop (nhds 0) :=
    tendsto_const_nhds.div_atTop tendsto_id
  have hhalf : Tendsto (fun u : ℝ => u / 2) atTop atTop := tendsto_id.atTop_div_const two_pos
  have hd1 : Tendsto (fun u : ℝ => (a - b) / u + u / 2) atTop atTop := h0.add_atTop hhalf
  have hd2 : Tendsto (fun u : ℝ => (a - b) / u - u / 2) atTop atBot :=
    (h0.add_atBot (tendsto_neg_atTop_atBot.comp hhalf)).congr
      (fun u => by simp [Function.comp, sub_eq_add_neg])
  have := ((tendsto_stdNormalCDF_atTop.comp hd1).const_mul (exp a)).sub
    ((tendsto_stdNormalCDF_atBot.comp hd2).const_mul (exp b))
  simpa using this

#print axioms unit_G_tendsto_atTop

open Filter in
lemma unit_G_tendsto_zero (a b : ℝ) :
    Tendsto (fun u => exp a * stdNormalCDF ((a - b) / u + u / 2)
        - exp b * stdNormalCDF ((a - b) / u - u / 2)) (nhdsWithin 0 (Ioi 0))
      (nhds (max (exp a - exp b) 0)) := by
  have hu2 : Tendsto (fun u : ℝ => u / 2) (nhdsWithin 0 (Ioi 0)) (nhds 0) := by
    have := ((continuous_id.div_const (2 : ℝ)).tendsto 0).mono_left
      (nhdsWithin_le_nhds (s := Ioi (0 : ℝ)))
    simpa using this
  rcases lt_trichotomy (a - b) 0 with hm | hm | hm
  · have hinv : Tendsto (fun u : ℝ => (a - b) / u) (nhdsWithin 0 (Ioi 0)) atBot :=
      (tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg hm).congr
        (fun u => by simp [div_eq_mul_inv])
    have hd1 : Tendsto (fun u : ℝ => (a - b) / u + u / 2) (nhdsWithin 0 (Ioi 0)) atBot :=
      hinv.atBot_add hu2
    have hd2 : Tendsto (fun u : ℝ => (a - b) / u - u / 2) (nhdsWithin 0 (Ioi 0)) atBot :=
      (hinv.atBot_add hu2.neg).congr (fun u => by simp [sub_eq_add_neg])
    have hab : exp a ≤ exp b := exp_le_exp.2 (by linarith)
    rw [max_eq_right (by linarith)]
    have := ((tendsto_stdNormalCDF_atBot.comp hd1).const_mul (exp a)).sub
      ((tendsto_stdNormalCDF_atBot.comp hd2).const_mul (exp b))
    simpa using this
  · have hab : a = b := by linarith
    subst hab
    have hc : Continuous (fun u : ℝ => exp a * stdNormalCDF (u / 2)
        - exp a * stdNormalCDF (-(u / 2))) := by
      have := continuous_stdNormalCDF; fun_prop
    have := (hc.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Ioi (0 : ℝ)))
    simp only [sub_self, max_self]
    simpa [sub_eq_add_neg] using this
  · have hinv : Tendsto (fun u : ℝ => (a - b) / u) (nhdsWithin 0 (Ioi 0)) atTop :=
      (tendsto_inv_nhdsGT_zero.const_mul_atTop hm).congr
        (fun u => by simp [div_eq_mul_inv])
    have hd1 : Tendsto (fun u : ℝ => (a - b) / u + u / 2) (nhdsWithin 0 (Ioi 0)) atTop :=
      hinv.atTop_add hu2
    have hd2 : Tendsto (fun u : ℝ => (a - b) / u - u / 2) (nhdsWithin 0 (Ioi 0)) atTop :=
      (hinv.atTop_add hu2.neg).congr (fun u => by simp [sub_eq_add_neg])
    have hab : exp b ≤ exp a := exp_le_exp.2 (by linarith)
    rw [max_eq_left (by linarith)]
    have := ((tendsto_stdNormalCDF_atTop.comp hd1).const_mul (exp a)).sub
      ((tendsto_stdNormalCDF_atTop.comp hd2).const_mul (exp b))
    simpa using this

#print axioms unit_G_tendsto_zero

open Filter in
lemma image_Ioi_eq_Ioo {F : ℝ → ℝ} {L U : ℝ} (hmono : StrictMonoOn F (Ioi 0))
    (hcont : ContinuousOn F (Ioi 0)) (h0 : Tendsto F (nhdsWithin 0 (Ioi 0)) (nhds L))
    (hinf : Tendsto F atTop (nhds U)) : F '' Ioi 0 = Ioo L U := by
  ext y
  constructor
  · rintro ⟨x, hx, rfl⟩
    have hx : (0 : ℝ) < x := hx
    constructor
    · have hle : L ≤ F (x / 2) := by
        refine le_of_tendsto h0 ?_
        filter_upwards [Ioo_mem_nhdsGT (by positivity : (0 : ℝ) < x / 2)] with z hz
        exact hmono.monotoneOn hz.1 (by simp; positivity) hz.2.le
      exact hle.trans_lt (hmono (by simp; positivity) hx (by linarith))
    · have hle : F (x + 1) ≤ U := by
        refine ge_of_tendsto hinf ?_
        filter_upwards [eventually_ge_atTop (x + 1)] with z hz
        exact hmono.monotoneOn (by simp; linarith) (by simp; linarith) hz
      exact (hmono hx (by simp; linarith) (by linarith)).trans_le hle
  · rintro ⟨hLy, hyU⟩
    obtain ⟨z0, hz0y, hz0⟩ := ((h0.eventually (gt_mem_nhds hLy)).and
      self_mem_nhdsWithin).exists
    obtain ⟨z1, hz1y, hz1⟩ := ((hinf.eventually (lt_mem_nhds hyU)).and
      (eventually_gt_atTop 0)).exists
    have hz0' : (0 : ℝ) < z0 := hz0
    have hlt : z0 ≤ z1 := by
      by_contra h
      have := hmono hz1 hz0 (not_le.1 h)
      linarith
    obtain ⟨w, hw, hwy⟩ := intermediate_value_Icc hlt
      (hcont.mono (fun t ht => lt_of_lt_of_le hz0' ht.1)) ⟨hz0y.le, hz1y.le⟩
    exact ⟨w, lt_of_lt_of_le hz0' hw.1, hwy⟩

#print axioms image_Ioi_eq_Ioo

lemma fwdStartPrice_eq_G (S α r q σ t₁ T : ℝ) (hα : 0 < α) (hσ : 0 < σ) (hT : t₁ < T) :
    fwdStartPrice S α r q σ t₁ T = S * exp (-q * t₁) *
      (exp (-q * (T - t₁)) * stdNormalCDF
          ((-q * (T - t₁) - (log α - r * (T - t₁))) / (σ * √(T - t₁)) + σ * √(T - t₁) / 2)
        - exp (log α - r * (T - t₁)) * stdNormalCDF
          ((-q * (T - t₁) - (log α - r * (T - t₁))) / (σ * √(T - t₁)) - σ * √(T - t₁) / 2)) := by
  have hτ : 0 < T - t₁ := sub_pos.2 hT
  have hs : 0 < √(T - t₁) := sqrt_pos.2 hτ
  have hsq : √(T - t₁) ^ 2 = T - t₁ := sq_sqrt hτ.le
  unfold fwdStartPrice unitCall
  rw [unitD1_eq _ _ _ _ _ hσ hτ, add_sub_cancel_right, exp_sub, exp_log hα]
  have e1 : ((r - q - σ ^ 2 / 2) * (T - t₁) - log α) / (σ * √(T - t₁)) + σ * √(T - t₁)
      = (-q * (T - t₁) - (log α - r * (T - t₁))) / (σ * √(T - t₁)) + σ * √(T - t₁) / 2 := by
    field_simp
    linear_combination (σ ^ 2) * hsq
  have e2 : ((r - q - σ ^ 2 / 2) * (T - t₁) - log α) / (σ * √(T - t₁))
      = (-q * (T - t₁) - (log α - r * (T - t₁))) / (σ * √(T - t₁)) - σ * √(T - t₁) / 2 := by
    field_simp
    linear_combination (σ ^ 2) * hsq
  have e3 : α / exp (r * (T - t₁)) = α * exp (-r * (T - t₁)) := by
    rw [neg_mul, exp_neg, div_eq_mul_inv]
  rw [e1, e2, e3]

#print axioms fwdStartPrice_eq_G

/-- **Forward-start price** (The formula; Why it works, Steps 0 to 3 and the detailed proof).
Under the pricing measure `Q`, Acme starts at `S > 0`, with riskless rate `r` and dividend yield
`q` known throughout. Its log return up to the reset date `t₁ > 0` is bell-curved at a volatility
`σ₁`, and its log return from the reset to expiry `T > t₁` is bell-curved at a volatility `σ > 0`
fixed in advance, driven by independent standard bell-curve draws `Z₁` and `Z₂`:
`S_{t₁} = S e^((r - q - σ₁²/2) t₁ + σ₁√t₁ Z₁)` and
`S_T = S_{t₁} e^((r - q - σ²/2)(T - t₁) + σ√(T - t₁) Z₂)`.
The strike is set on the reset date as the multiple `α > 0` of the share price then, so the
payoff at expiry is `max(S_T - α S_{t₁}, 0)`. Then its price, the payoff's average under `Q`
discounted by `e^(-rT)`, is `S e^(-q t₁) c`: today's share price, times the waiting drag, times
the unit call over the life `T - t₁` left after the reset at the volatility `σ`. The volatility
`σ₁` before the reset does not appear. -/
theorem forward_start_price_is_shares_times_unit_call
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (S α r q σ₁ σ t₁ T : ℝ) (hS : 0 < S) (hα : 0 < α) (hσ : 0 < σ)
    (ht₁ : 0 < t₁) (hT : t₁ < T)
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q) :
    exp (-r * T) * ∫ ω,
        max (S * exp ((r - q - σ₁ ^ 2 / 2) * t₁ + σ₁ * √t₁ * Z₁ ω)
              * exp ((r - q - σ ^ 2 / 2) * (T - t₁) + σ * √(T - t₁) * Z₂ ω)
            - α * (S * exp ((r - q - σ₁ ^ 2 / 2) * t₁ + σ₁ * √t₁ * Z₁ ω))) 0 ∂Q =
      fwdStartPrice S α r q σ t₁ T := by
  have hτ : 0 < T - t₁ := sub_pos.2 hT
  set f : ℝ → ℝ := fun x => S * exp ((r - q - σ₁ ^ 2 / 2) * t₁ + σ₁ * √t₁ * x) with hf
  set g : ℝ → ℝ := fun y =>
    max (exp ((r - q - σ ^ 2 / 2) * (T - t₁) + σ * √(T - t₁) * y) - α) 0 with hg
  have hpt : ∀ ω, max (S * exp ((r - q - σ₁ ^ 2 / 2) * t₁ + σ₁ * √t₁ * Z₁ ω)
              * exp ((r - q - σ ^ 2 / 2) * (T - t₁) + σ * √(T - t₁) * Z₂ ω)
            - α * (S * exp ((r - q - σ₁ ^ 2 / 2) * t₁ + σ₁ * √t₁ * Z₁ ω))) 0
      = f (Z₁ ω) * g (Z₂ ω) := by
    intro ω
    have hP : 0 ≤ f (Z₁ ω) := by simp only [hf]; positivity
    rw [hg, mul_max_of_nonneg _ _ hP, mul_zero, hf]
    congr 1; ring
  simp_rw [hpt]
  rw [hind.integral_fun_comp_mul_comp hZ₁.aemeasurable hZ₂.aemeasurable
    (by rw [hZ₁.map_eq]; exact (by fun_prop : Continuous f).aestronglyMeasurable)
    (by rw [hZ₂.map_eq]; exact (by fun_prop : Continuous g).aestronglyMeasurable)]
  have i1 : ∫ ω, f (Z₁ ω) ∂Q = ∫ x, f x ∂(gaussianReal 0 1) :=
    hZ₁.integral_comp (by fun_prop : Continuous f).aestronglyMeasurable
  have i2 : ∫ ω, g (Z₂ ω) ∂Q = ∫ x, g x ∂(gaussianReal 0 1) :=
    hZ₂.integral_comp (by fun_prop : Continuous g).aestronglyMeasurable
  have hsτ : 0 < σ * √(T - t₁) := mul_pos hσ (sqrt_pos.2 hτ)
  rw [i1, i2, hf, hg, gaussian_exp_mean, stdNormal_call _ _ _ hsτ hα]
  unfold fwdStartPrice unitCall
  rw [unitD1_eq _ _ _ _ _ hσ hτ, add_sub_cancel_right]
  have sq1 : √t₁ ^ 2 = t₁ := sq_sqrt ht₁.le
  have sq2 : √(T - t₁) ^ 2 = T - t₁ := sq_sqrt hτ.le
  have E1 : exp (-r * T) * exp ((r - q - σ₁ ^ 2 / 2) * t₁) * exp ((σ₁ * √t₁) ^ 2 / 2)
      = exp (-q * t₁) * exp (-r * (T - t₁)) := by
    rw [← exp_add, ← exp_add, ← exp_add]; congr 1
    linear_combination (σ₁ ^ 2 / 2) * sq1
  have E2 : exp (-r * (T - t₁)) * exp ((r - q - σ ^ 2 / 2) * (T - t₁) + (σ * √(T - t₁)) ^ 2 / 2)
      = exp (-q * (T - t₁)) := by
    rw [← exp_add]; congr 1
    linear_combination (σ ^ 2 / 2) * sq2
  set X := stdNormalCDF (((r - q - σ ^ 2 / 2) * (T - t₁) - log α) / (σ * √(T - t₁))
    + σ * √(T - t₁))
  set Y := stdNormalCDF (((r - q - σ ^ 2 / 2) * (T - t₁) - log α) / (σ * √(T - t₁)))
  linear_combination
    (S * X * exp ((r - q - σ ^ 2 / 2) * (T - t₁) + (σ * √(T - t₁)) ^ 2 / 2) - S * α * Y) * E1
      + S * X * exp (-q * t₁) * E2

/-- **On the reset date the call is a known number of shares** (Why it works, Step 1, and the
hedge check). An ordinary call scales with its share: with the share at any price `x > 0` and the
strike set at `α x` for a multiple `α > 0`, the Black-Scholes call over `τ` years is worth `x`
times the unit call, `x c`, so the unit call `c` does not depend on the share price. -/
theorem call_struck_at_multiple_is_shares_times_unit_call
    (x α r q σ τ : ℝ) (hx : 0 < x) (hα : 0 < α) :
    bsCall x (α * x) r q σ τ = x * unitCall α r q σ τ := by
  have h : log (x / (α * x)) = -log α := by
    rw [show x / (α * x) = α⁻¹ by field_simp, log_inv]
  unfold bsCall unitCall unitD1
  rw [h]; ring

/-- **From a quote back to the forward volatility** (Why it works, Step 4). With `S > 0`,
`α > 0` and `0 < t₁ < T`, the forward-start price rises strictly with the volatility `σ > 0`
between the reset and expiry, and the prices it reaches are exactly those strictly between the
floor `S e^(-q t₁) max(e^(-q(T - t₁)) - α e^(-r(T - t₁)), 0)` and the ceiling `S e^(-qT)`. So
every quote strictly between them is given by exactly one forward volatility, and a quote at or
beyond either bound is given by none. -/
theorem forward_vol_from_quote_exists_unique
    (S α r q t₁ T : ℝ) (hS : 0 < S) (hα : 0 < α) (ht₁ : 0 < t₁) (hT : t₁ < T) :
    StrictMonoOn (fun σ => fwdStartPrice S α r q σ t₁ T) (Ioi 0) ∧
      (fun σ => fwdStartPrice S α r q σ t₁ T) '' Ioi 0 =
        Ioo (S * exp (-q * t₁) * max (exp (-q * (T - t₁)) - α * exp (-r * (T - t₁))) 0)
          (S * exp (-q * T)) := by
  have hτ : 0 < T - t₁ := sub_pos.2 hT
  have hs : 0 < √(T - t₁) := sqrt_pos.2 hτ
  have hK : 0 < S * exp (-q * t₁) := by positivity
  set a := -q * (T - t₁) with ha
  set b := log α - r * (T - t₁) with hb
  set G := fun u => exp a * stdNormalCDF ((a - b) / u + u / 2)
        - exp b * stdNormalCDF ((a - b) / u - u / 2) with hG
  have hrep : ∀ σ, 0 < σ → fwdStartPrice S α r q σ t₁ T = S * exp (-q * t₁) * G (σ * √(T - t₁)) :=
    fun σ hσ => fwdStartPrice_eq_G S α r q σ t₁ T hα hσ hT
  constructor
  · intro x hx y hy hxy
    simp only
    rw [hrep x hx, hrep y hy]
    refine mul_lt_mul_of_pos_left ?_ hK
    exact unit_G_strictMonoOn a b (mul_pos hx hs) (mul_pos hy hs)
      (mul_lt_mul_of_pos_right hxy hs)
  · have himg : (fun σ => fwdStartPrice S α r q σ t₁ T) '' Ioi 0
        = (fun u => S * exp (-q * t₁) * u) '' (G '' Ioi 0) := by
      rw [Set.image_image]
      ext y; constructor
      · rintro ⟨σ, hσ, rfl⟩
        exact ⟨σ * √(T - t₁), mul_pos hσ hs, (hrep σ hσ).symm⟩
      · rintro ⟨u, hu, rfl⟩
        have hu' : (0 : ℝ) < u := hu
        refine ⟨u / √(T - t₁), div_pos hu' hs, ?_⟩
        simp only
        rw [hrep _ (div_pos hu' hs), div_mul_cancel₀ _ hs.ne']
    rw [himg, image_Ioi_eq_Ioo (unit_G_strictMonoOn a b) (unit_G_continuousOn a b)
      (unit_G_tendsto_zero a b) (unit_G_tendsto_atTop a b), image_mul_left_Ioo hK]
    have hb' : exp b = α * exp (-r * (T - t₁)) := by
      rw [hb, exp_sub, exp_log hα, neg_mul, exp_neg]; field_simp
    have ha' : S * exp (-q * t₁) * exp a = S * exp (-q * T) := by
      rw [mul_assoc, ← exp_add, ha]; congr 2; ring
    rw [hb', ha']

-- House contract: reset t₁ = 1/2, expiry T = 1, so the life after the reset is τ = 1/2.
example : (1 : ℚ) - 1 / 2 = 1 / 2 := by norm_num
-- Discounting: e^(-rT) · e^(r t₁) · e^(rτ) = 1, since -rT + r t₁ + rτ = 0 (r = 5/100).
example : -(5 / 100 : ℚ) * 1 + 5 / 100 * (1 / 2) + 5 / 100 * (1 / 2) = 0 := by norm_num
-- Flat 20%: (r - q + σ²/2) τ = (0.05 - 0.02 + 0.02) × 0.5 = 0.025, the top of d₁ at the money.
example : ((5 / 100 : ℚ) - 2 / 100 + (1 / 5) ^ 2 / 2) * (1 / 2) = 1 / 40 := by norm_num
-- Total variance to the reset, 18% over half a year: w₁ = 0.0162.
example : (18 / 100 : ℚ) ^ 2 * (1 / 2) = 162 / 10000 := by norm_num
-- Total variance to expiry, 20% over one year: w₂ = 0.04.
example : (1 / 5 : ℚ) ^ 2 * 1 = 4 / 100 := by norm_num
-- Forward variance per year: (w₂ - w₁) / (T - t₁) = 0.0476, whose square root is σ_f.
example : ((4 / 100 : ℚ) - 162 / 10000) / (1 - 1 / 2) = 476 / 10000 := by norm_num
-- The chart: reset at $90, Acme $100 at expiry pays max(100 - 1 × 90, 0) = 10.
example : max ((100 : ℤ) - 1 * 90) 0 = 10 := by decide
-- The chart: reset at $110, Acme $105 at expiry pays nothing.
example : max ((105 : ℤ) - 1 * 110) 0 = 0 := by decide
-- The story: strike set at $110, Acme $118 at month 12 pays $8.
example : max ((118 : ℤ) - 1 * 110) 0 = 8 := by decide

#print axioms forward_start_price_is_shares_times_unit_call
#print axioms call_struck_at_multiple_is_shares_times_unit_call
#print axioms forward_vol_from_quote_exists_unique
