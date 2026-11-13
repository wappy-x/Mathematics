-- The exchange option: if two shares are lognormal with a fixed correlation, the right to hand over one share for the other at expiry is worth Margrabe's formula S₁ e^(-q₁T) N(d₁) - S₂ e^(-q₂T) N(d₂) at every bank rate, which is S₂ e^(-q₂T) times a zero-rate Black-Scholes call on the ratio struck at 1, it becomes the ordinary Black-Scholes call when the second share is a bond, and its hedge holds only the two shares.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- A share's price on expiry day in the dollar pretend world (detailed proof): today's price `S`,
bank rate `r`, dividend yield `q`, volatility `σ`, years to expiry `T`, and a standard bell-curve
draw `z`: `S_T = S e^((r - q - σ²/2) T + σ√T z)`. -/
noncomputable def priceAtExpiry (S r q σ T z : ℝ) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z)

/-- The effective volatility, the volatility of the ratio Acme over Birch:
`σ = √(σ₁² + σ₂² - 2ρσ₁σ₂)`. -/
noncomputable def effVol (σ₁ σ₂ ρ : ℝ) : ℝ :=
  √(σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂)

/-- The card's `d₁ = (ln(S₁e^(-q₁T) / (S₂e^(-q₂T))) + σ²T/2) / (σ√T)`; then `d₂ = d₁ - σ√T`. -/
noncomputable def margrabeD1 (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) : ℝ :=
  (log (S₁ * exp (-q₁ * T) / (S₂ * exp (-q₂ * T))) + (effVol σ₁ σ₂ ρ * √T) ^ 2 / 2) /
    (effVol σ₁ σ₂ ρ * √T)

/-- Margrabe's formula `V = S₁e^(-q₁T) N(d₁) - S₂e^(-q₂T) N(d₂)`. There is no bank rate among its
inputs. When the ratio cannot move (`σ√T = 0`), the code's rule applies: the swap is worth
`max(S₁e^(-q₁T) - S₂e^(-q₂T), 0)`. -/
noncomputable def margrabePrice (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) : ℝ :=
  if effVol σ₁ σ₂ ρ * √T = 0 then max (S₁ * exp (-q₁ * T) - S₂ * exp (-q₂ * T)) 0
  else S₁ * exp (-q₁ * T) * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)
    - S₂ * exp (-q₂ * T) *
      stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T)

/-- The Black-Scholes call formula, as on the Black-Scholes call card:
`S e^(-qT) N(d₁) - K e^(-rT) N(d₁ - σ√T)` with `d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`; when
`σ√T = 0` the price does not move and the call is worth `max(S e^(-qT) - K e^(-rT), 0)`. -/
noncomputable def bsCall (S K r q σ T : ℝ) : ℝ :=
  if σ * √T = 0 then max (S * exp (-q * T) - K * exp (-r * T)) 0
  else S * exp (-q * T) *
      stdNormalCDF ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T))
    - K * exp (-r * T) *
      stdNormalCDF ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)


open Set in
lemma mg_gauss_Ioi_neg (d : ℝ) :
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

#print axioms mg_gauss_Ioi_neg

lemma mg_tilt1 (a : ℝ) (f : ℝ → ℝ) :
    ∫ x, exp (a * x) * f x ∂(gaussianReal 0 1) =
      exp (a ^ 2 / 2) * ∫ x, f (x + a) ∂(gaussianReal 0 1) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero,
    integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hpt : ∀ x, gaussianPDFReal 0 1 x • (exp (a * x) * f x) =
      exp (a ^ 2 / 2) * (gaussianPDFReal a 1 x * f x) := by
    intro x
    rw [smul_eq_mul]
    have e : gaussianPDFReal 0 1 x * exp (a * x) = exp (a ^ 2 / 2) * gaussianPDFReal a 1 x := by
      unfold gaussianPDFReal
      simp only [NNReal.coe_one, mul_one]
      rw [mul_assoc, ← exp_add]
      rw [mul_left_comm, ← exp_add]
      congr 2
      ring
    calc _ = (gaussianPDFReal 0 1 x * exp (a * x)) * f x := by ring
      _ = _ := by rw [e]; ring
  simp_rw [hpt]
  rw [integral_const_mul]
  congr 1
  rw [← integral_add_right_eq_self (fun x => gaussianPDFReal a 1 x * f x) a]
  congr 1
  funext x
  rw [smul_eq_mul, gaussianPDFReal_add, sub_self]

#print axioms mg_tilt1

lemma mg_integrable_tilt (a b : ℝ) (f : ℝ × ℝ → ℝ) (hf : Measurable f) (hb : ∀ p, |f p| ≤ 1) :
    Integrable (fun p : ℝ × ℝ => exp (a * p.1 + b * p.2) * f p)
      ((gaussianReal 0 1).prod (gaussianReal 0 1)) := by
  have hi := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) a).mul_prod
    (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) b)
  refine hi.mono ?_ ?_
  · exact (by fun_prop : Measurable fun p : ℝ × ℝ => exp (a * p.1 + b * p.2)).mul hf
      |>.aestronglyMeasurable
  · refine Filter.Eventually.of_forall (fun p => ?_)
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_mul, ← exp_add, abs_of_pos (exp_pos _)]
    exact mul_le_of_le_one_right (exp_pos _).le (hb p)

#print axioms mg_integrable_tilt

lemma mg_tilt2 (a b : ℝ) (f : ℝ × ℝ → ℝ) (hf : Measurable f) (hb : ∀ p, |f p| ≤ 1) :
    ∫ p, exp (a * p.1 + b * p.2) * f p ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) =
      exp ((a ^ 2 + b ^ 2) / 2) *
        ∫ p, f (p.1 + a, p.2 + b) ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) := by
  have i1 := mg_integrable_tilt a b f hf hb
  have hf2 : Measurable fun p : ℝ × ℝ => f (p.1 + a, p.2 + b) :=
    hf.comp (by fun_prop)
  have i2 : Integrable (fun p : ℝ × ℝ => f (p.1 + a, p.2 + b))
      ((gaussianReal 0 1).prod (gaussianReal 0 1)) :=
    Integrable.of_bound hf2.aestronglyMeasurable 1
      (Filter.Eventually.of_forall (fun p => by rw [Real.norm_eq_abs]; exact hb _))
  rw [integral_prod _ i1, integral_prod _ i2]
  have hin : ∀ x : ℝ, ∫ y, exp (a * (x, y).1 + b * (x, y).2) * f (x, y) ∂(gaussianReal 0 1) =
      exp (a * x) * (exp (b ^ 2 / 2) * ∫ y, f (x, y + b) ∂(gaussianReal 0 1)) := by
    intro x
    show ∫ y, exp (a * x + b * y) * f (x, y) ∂(gaussianReal 0 1) = _
    have : ∀ y, exp (a * x + b * y) * f (x, y) = exp (a * x) * (exp (b * y) * f (x, y)) := by
      intro y; rw [exp_add]; ring
    simp_rw [this]
    rw [integral_const_mul, mg_tilt1 b (fun y => f (x, y))]
  simp_rw [hin]
  rw [mg_tilt1 a (fun x => exp (b ^ 2 / 2) * ∫ y, f (x, y + b) ∂(gaussianReal 0 1)),
    integral_const_mul]
  rw [← mul_assoc, ← exp_add]
  congr 2
  ring

#print axioms mg_tilt2

lemma mg_prob {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₂ Zperp : Ω → ℝ}
    (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q) (hZperp : HasLaw Zperp (gaussianReal 0 1) Q)
    (hind : IndepFun Z₂ Zperp Q) (K A B s : ℝ) (hs : 0 < s) (hsq : s ^ 2 = A ^ 2 + B ^ 2) :
    Q.real {ω | 0 < K + A * Z₂ ω + B * Zperp ω} = stdNormalCDF (K / s) := by
  have hX := gaussianReal_const_mul hZ₂ A
  have hY := gaussianReal_const_mul hZperp B
  have hind' : IndepFun (fun ω => A * Z₂ ω) (fun ω => B * Zperp ω) Q :=
    hind.comp (measurable_const_mul A) (measurable_const_mul B)
  have hmap := gaussianReal_add_gaussianReal_of_indepFun hind' hX hY
  have hlaw : HasLaw ((fun ω => A * Z₂ ω) + (fun ω => B * Zperp ω)) ((gaussianReal 0 1).map (s * ·)) Q := by
    refine ⟨hX.aemeasurable.add hY.aemeasurable, ?_⟩
    rw [hmap, gaussianReal_map_const_mul]
    congr 1
    · simp
    · apply NNReal.eq; simp [hsq]
  have hset : {ω | 0 < K + A * Z₂ ω + B * Zperp ω} =
      {ω | (fun w => 0 < K + w) (((fun ω => A * Z₂ ω) + (fun ω => B * Zperp ω)) ω)} := by
    ext ω; simp [add_assoc]
  have hms : MeasurableSet {w : ℝ | 0 < K + w} := measurableSet_lt measurable_const (by fun_prop)
  rw [hset, hlaw.measureReal_eq (p := fun w => 0 < K + w) hms,
    map_measureReal_apply (measurable_const_mul s) hms]
  have hpre : (s * ·) ⁻¹' {w : ℝ | 0 < K + w} = Set.Ioi (-(K / s)) := by
    ext z
    simp only [Set.mem_preimage, Set.mem_ofPred_eq, Set.mem_Ioi]
    rw [neg_lt, lt_div_iff₀ hs]
    constructor <;> intro h <;> linarith
  rw [hpre, mg_gauss_Ioi_neg]

#print axioms mg_prob

lemma mg_log (S₁ S₂ a b : ℝ) (h₁ : 0 < S₁) (h₂ : 0 < S₂) :
    log (S₁ * exp a / (S₂ * exp b)) = log S₁ - log S₂ + a - b := by
  rw [log_div (mul_pos h₁ (exp_pos a)).ne' (mul_pos h₂ (exp_pos b)).ne',
    log_mul h₁.ne' (exp_pos a).ne', log_mul h₂.ne' (exp_pos b).ne', log_exp, log_exp]
  ring

#print axioms mg_log

lemma mg_event (S₁ S₂ r q₁ q₂ σ₁ σ₂ ρ c T x y : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂) :
    priceAtExpiry S₂ r q₂ σ₂ T x < priceAtExpiry S₁ r q₁ σ₁ T (ρ * x + c * y) ↔
      0 < (log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
        (σ₁ * √T * ρ - σ₂ * √T) * x + σ₁ * √T * c * y := by
  unfold priceAtExpiry
  rw [← log_lt_log_iff (mul_pos hS₂ (exp_pos _)) (mul_pos hS₁ (exp_pos _)),
    log_mul hS₂.ne' (exp_pos _).ne', log_mul hS₁.ne' (exp_pos _).ne', log_exp, log_exp]
  constructor <;> intro h <;> linarith

#print axioms mg_event

lemma mg_hasDerivAt_N (x : ℝ) : HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hc : Continuous (gaussianPDFReal 0 1) := by unfold gaussianPDFReal; fun_prop
  have hN : ∀ x, stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
    intro x
    unfold stdNormalCDF
    rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
      ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
        (fun t _ ↦ gaussianPDFReal_nonneg 0 1 t))]
  have hint : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a ↦ (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun y ↦ stdNormalCDF 0 + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [hN, hN, ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint y)]
    ring
  rw [heq]
  exact ((hc.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

#print axioms mg_hasDerivAt_N

lemma mg_pdf_ratio (F K v : ℝ) (hF : 0 < F) (hK : 0 < K) (hv : 0 < v) :
    F * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v) =
      K * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v - v) := by
  set d1 := (log (F / K) + v ^ 2 / 2) / v with hd1
  have hsd : v * d1 = log (F / K) + v ^ 2 / 2 := by rw [hd1]; field_simp
  unfold gaussianPDFReal
  have hexp : -(d1 - v - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) =
      -(d1 - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + log (F / K) := by
    simp only [NNReal.coe_one]
    linear_combination hsd
  rw [hexp, exp_add, exp_log (div_pos hF hK)]
  field_simp

#print axioms mg_pdf_ratio

lemma mg_ratio (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂)
    (hv : 0 < effVol σ₁ σ₂ ρ * √T) :
    S₁ * exp (-q₁ * T) * gaussianPDFReal 0 1 (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T) =
      S₂ * exp (-q₂ * T) *
        gaussianPDFReal 0 1 (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T) := by
  unfold margrabeD1
  exact mg_pdf_ratio _ _ _ (mul_pos hS₁ (exp_pos _)) (mul_pos hS₂ (exp_pos _)) hv

#print axioms mg_ratio

lemma mg_second (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂) (hT : 0 < T) :
    margrabePrice S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T =
      S₂ * exp (-q₂ * T) * bsCall (S₁ / S₂) 1 0 (q₁ - q₂) (effVol σ₁ σ₂ ρ) T := by
  unfold margrabePrice bsCall
  have hpos : 0 < S₂ * exp (-q₂ * T) := mul_pos hS₂ (exp_pos _)
  have e : exp (-q₂ * T) * exp (-(q₁ - q₂) * T) = exp (-q₁ * T) := by
    rw [← exp_add]; ring_nf
  have hratio : S₂ * exp (-q₂ * T) * (S₁ / S₂ * exp (-(q₁ - q₂) * T)) = S₁ * exp (-q₁ * T) := by
    rw [← e]; field_simp
  have h1 : (1 : ℝ) * exp (-0 * T) = 1 := by simp
  rw [h1]
  split_ifs with h
  · rw [mul_max_of_nonneg _ _ hpos.le, mul_sub, hratio, mul_one, mul_zero]
  · have hd : (log (S₁ / S₂ / 1) + (0 - (q₁ - q₂) + effVol σ₁ σ₂ ρ ^ 2 / 2) * T) /
        (effVol σ₁ σ₂ ρ * √T) = margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T := by
      unfold margrabeD1
      rw [mg_log _ _ _ _ hS₁ hS₂, div_one, log_div hS₁.ne' hS₂.ne', mul_pow, sq_sqrt hT.le]
      ring
    rw [hd]
    linear_combination (-(stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T))) * hratio

#print axioms mg_second
/-- **The exchange option is priced with no interest rate at all** (The formula; Why it works,
Steps 0 to 3 and the detailed proof). In the dollar pretend world `Q`, Birch's shock `Z₂` and a
second shock `Z⊥` are independent standard bell-curve draws, and Acme's shock is
`Z₁ = ρZ₂ + √(1 - ρ²) Z⊥`, so the two shocks have correlation `ρ` with `-1 ≤ ρ ≤ 1`. Both log
prices are bell-curved with constant volatilities `σ₁`, `σ₂`, steady dividend yields `q₁`, `q₂`
and bank rate `r`; today's prices are `S₁ > 0` and `S₂ > 0`, and the swap is used only at expiry,
`T > 0` years away. Then, whatever the bank rate `r`, the price of the right to hand over one
Birch share for one Acme share, the average payoff `max(S₁(T) - S₂(T), 0)` brought back to today
by `e^(-rT)`, is Margrabe's formula; and it equals `S₂e^(-q₂T)` Birch shares' worth of a
Black-Scholes call on the ratio `S₁/S₂`, strike 1, bank rate 0, dividend gap `q₁ - q₂`, at the
effective volatility `√(σ₁² + σ₂² - 2ρσ₁σ₂)`. -/
theorem exchange_option_price_is_margrabe_zero_rate_ratio_call
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₂ Zperp : Ω → ℝ}
    (S₁ S₂ r q₁ q₂ σ₁ σ₂ ρ T : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂) (hT : 0 < T)
    (hρlo : -1 ≤ ρ) (hρhi : ρ ≤ 1)
    (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q) (hZperp : HasLaw Zperp (gaussianReal 0 1) Q)
    (hind : IndepFun Z₂ Zperp Q) :
    exp (-r * T) * ∫ ω, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * Z₂ ω + √(1 - ρ ^ 2) * Zperp ω)
        - priceAtExpiry S₂ r q₂ σ₂ T (Z₂ ω)) 0 ∂Q =
        margrabePrice S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T ∧
      margrabePrice S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T =
        S₂ * exp (-q₂ * T) * bsCall (S₁ / S₂) 1 0 (q₁ - q₂) (effVol σ₁ σ₂ ρ) T := by
  refine ⟨?_, mg_second S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T hS₁ hS₂ hT⟩
  have := hZ₂.isProbabilityMeasure
  have hP := hind.hasLaw_prod hZ₂ hZperp
  have hc2 : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := sq_sqrt (by nlinarith)
  have hs2 : √T ^ 2 = T := sq_sqrt hT.le
  have hE2 : effVol σ₁ σ₂ ρ ^ 2 = σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂ := by
    unfold effVol
    have h1 : 0 ≤ 1 - ρ ^ 2 := by nlinarith
    have h2 := mul_nonneg (sq_nonneg σ₁) h1
    have h3 : 0 ≤ σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂ := by nlinarith [sq_nonneg (σ₁ * ρ - σ₂)]
    exact sq_sqrt h3
  have hFm : Measurable (fun p : ℝ × ℝ => max (priceAtExpiry S₁ r q₁ σ₁ T
      (ρ * p.1 + √(1 - ρ ^ 2) * p.2) - priceAtExpiry S₂ r q₂ σ₂ T p.1) 0) := by
    simp only [priceAtExpiry]; fun_prop
  have htr : ∫ ω, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * Z₂ ω + √(1 - ρ ^ 2) * Zperp ω)
        - priceAtExpiry S₂ r q₂ σ₂ T (Z₂ ω)) 0 ∂Q =
      ∫ p, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2) -
        priceAtExpiry S₂ r q₂ σ₂ T p.1) 0 ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) := by
    rw [← hP.integral_comp hFm.aestronglyMeasurable]; rfl
  rw [htr]
  have hX1 : ∀ p : ℝ × ℝ, priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2) =
      S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) *
        exp (σ₁ * √T * ρ * p.1 + σ₁ * √T * √(1 - ρ ^ 2) * p.2) := by
    intro p; unfold priceAtExpiry; rw [mul_assoc S₁, ← exp_add]; congr 2; ring
  have hX2 : ∀ p : ℝ × ℝ, priceAtExpiry S₂ r q₂ σ₂ T p.1 =
      S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T) * exp (σ₂ * √T * p.1 + 0 * p.2) := by
    intro p; unfold priceAtExpiry; rw [mul_assoc S₂, ← exp_add]; congr 2; ring
  rcases (Real.sqrt_nonneg (σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂)).eq_or_lt with hE | hE
  · -- the ratio cannot move
    have hE' : effVol σ₁ σ₂ ρ = 0 := hE.symm
    have h0 : (σ₁ * ρ - σ₂) ^ 2 + (σ₁ * √(1 - ρ ^ 2)) ^ 2 = 0 := by
      have := hE2; rw [hE'] at this
      rw [mul_pow σ₁, hc2]; linear_combination -this
    have hα : σ₁ * ρ - σ₂ = 0 := by
      have : (σ₁ * ρ - σ₂) ^ 2 = 0 := by
        nlinarith [sq_nonneg (σ₁ * ρ - σ₂), sq_nonneg (σ₁ * √(1 - ρ ^ 2))]
      exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
    have hβ : σ₁ * √(1 - ρ ^ 2) = 0 := by
      have : (σ₁ * √(1 - ρ ^ 2)) ^ 2 = 0 := by
        nlinarith [sq_nonneg (σ₁ * ρ - σ₂), sq_nonneg (σ₁ * √(1 - ρ ^ 2))]
      exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
    have hσsq : σ₁ ^ 2 = σ₂ ^ 2 := by
      have h1 : (σ₁ * √(1 - ρ ^ 2)) ^ 2 = 0 := by rw [hβ]; ring
      rw [mul_pow, hc2] at h1
      have : σ₂ = σ₁ * ρ := by linarith
      rw [this]; linear_combination h1
    have hpt : ∀ p : ℝ × ℝ, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2) -
        priceAtExpiry S₂ r q₂ σ₂ T p.1) 0 =
        max (S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) - S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T)) 0 *
          (exp (σ₂ * √T * p.1 + 0 * p.2) * 1) := by
      intro p
      rw [hX1, hX2, show σ₁ * √T * ρ * p.1 + σ₁ * √T * √(1 - ρ ^ 2) * p.2 =
        σ₂ * √T * p.1 + 0 * p.2 by linear_combination (√T * p.1) * hα + (√T * p.2) * hβ,
        ← sub_mul, mul_one, max_mul_of_nonneg _ _ (exp_pos _).le,
        zero_mul (exp (σ₂ * √T * p.1 + 0 * p.2))]
    simp_rw [hpt]
    rw [integral_const_mul, mg_tilt2 _ _ (fun _ => 1) measurable_const (by simp)]
    simp only [integral_const, probReal_univ, smul_eq_mul, mul_one]
    simp only [margrabePrice, hE', zero_mul, ↓reduceIte]
    rw [show exp (-r * T) * (max (S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) -
          S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T)) 0 * exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2)) =
        max (S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) - S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T)) 0 *
          (exp (-r * T) * exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2)) by ring,
      max_mul_of_nonneg _ _ (by positivity), zero_mul]
    have e1 : exp ((r - q₁ - σ₁ ^ 2 / 2) * T) * (exp (-r * T) * exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2))
        = exp (-q₁ * T) := by
      rw [← exp_add, ← exp_add]; congr 1; rw [mul_pow, hs2]; linear_combination (-(T / 2)) * hσsq
    have e2 : exp ((r - q₂ - σ₂ ^ 2 / 2) * T) * (exp (-r * T) * exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2))
        = exp (-q₂ * T) := by
      rw [← exp_add, ← exp_add]; congr 1; rw [mul_pow, hs2]; ring
    rw [sub_mul, mul_assoc S₁, e1, mul_assoc S₂, e2]
  · -- the ratio moves
    have hE' : 0 < effVol σ₁ σ₂ ρ := hE
    have hv : 0 < effVol σ₁ σ₂ ρ * √T := mul_pos hE' (sqrt_pos.2 hT)
    obtain ⟨f, hf⟩ : ∃ f : ℝ × ℝ → ℝ, f = fun p =>
        if priceAtExpiry S₂ r q₂ σ₂ T p.1 < priceAtExpiry S₁ r q₁ σ₁ T
          (ρ * p.1 + √(1 - ρ ^ 2) * p.2) then 1 else 0 := ⟨_, rfl⟩
    have hfm : Measurable f := by
      rw [hf]
      refine Measurable.ite ?_ measurable_const measurable_const
      exact measurableSet_lt (by unfold priceAtExpiry; fun_prop) (by unfold priceAtExpiry; fun_prop)
    have hfb : ∀ p, |f p| ≤ 1 := by
      intro p; rw [hf]; dsimp only; split_ifs <;> simp
    have hpay : ∀ p : ℝ × ℝ, max (priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2) -
        priceAtExpiry S₂ r q₂ σ₂ T p.1) 0 =
        S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T) *
          (exp (σ₁ * √T * ρ * p.1 + σ₁ * √T * √(1 - ρ ^ 2) * p.2) * f p) -
        S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T) * (exp (σ₂ * √T * p.1 + 0 * p.2) * f p) := by
      intro p
      rw [hf]
      dsimp only
      by_cases h : priceAtExpiry S₂ r q₂ σ₂ T p.1 <
          priceAtExpiry S₁ r q₁ σ₁ T (ρ * p.1 + √(1 - ρ ^ 2) * p.2)
      · rw [ite_eq_left h, max_eq_left (by linarith), hX1, hX2]; ring
      · rw [ite_eq_right h, max_eq_right (by linarith)]; ring
    have hprob : ∀ K, ((gaussianReal 0 1).prod (gaussianReal 0 1)).real
        {p : ℝ × ℝ | 0 < K + (σ₁ * √T * ρ - σ₂ * √T) * p.1 + σ₁ * √T * √(1 - ρ ^ 2) * p.2} =
        stdNormalCDF (K / (effVol σ₁ σ₂ ρ * √T)) := by
      intro K
      have hms : MeasurableSet {p : ℝ × ℝ | 0 < K + (σ₁ * √T * ρ - σ₂ * √T) * p.1 +
          σ₁ * √T * √(1 - ρ ^ 2) * p.2} := measurableSet_lt measurable_const (by fun_prop)
      rw [← hP.measureReal_eq (p := fun p : ℝ × ℝ => 0 < K + (σ₁ * √T * ρ - σ₂ * √T) * p.1 +
          σ₁ * √T * √(1 - ρ ^ 2) * p.2) hms]
      apply mg_prob hZ₂ hZperp hind _ _ _ _ hv
      rw [mul_pow, hE2]
      linear_combination (-(√T ^ 2 * σ₁ ^ 2)) * hc2
    have hshift : ∀ a b, ∫ p, f (p.1 + a, p.2 + b) ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) =
        stdNormalCDF (((log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * a + σ₁ * √T * √(1 - ρ ^ 2) * b) / (effVol σ₁ σ₂ ρ * √T)) := by
      intro a b
      rw [← hprob, ← integral_indicator_one (measurableSet_lt measurable_const (by fun_prop))]
      congr 1
      funext p
      rw [hf]
      simp only [Set.indicator, Set.mem_ofPred_eq, Pi.one_apply]
      simp only [mg_event S₁ S₂ r q₁ q₂ σ₁ σ₂ ρ (√(1 - ρ ^ 2)) T _ _ hS₁ hS₂]
      split_ifs with h1 h2 h2 <;> first | rfl | (exfalso; linarith)
    have hi1 := (mg_integrable_tilt (σ₁ * √T * ρ) (σ₁ * √T * √(1 - ρ ^ 2)) f hfm hfb).const_mul
      (S₁ * exp ((r - q₁ - σ₁ ^ 2 / 2) * T))
    have hi2 := (mg_integrable_tilt (σ₂ * √T) 0 f hfm hfb).const_mul
      (S₂ * exp ((r - q₂ - σ₂ ^ 2 / 2) * T))
    simp_rw [hpay]
    rw [integral_sub hi1 hi2, integral_const_mul, integral_const_mul, mg_tilt2 _ _ f hfm hfb,
      mg_tilt2 _ _ f hfm hfb, hshift, hshift]
    have hK1 : ((log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * (σ₁ * √T * ρ) +
          σ₁ * √T * √(1 - ρ ^ 2) * (σ₁ * √T * √(1 - ρ ^ 2))) / (effVol σ₁ σ₂ ρ * √T) =
        margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T := by
      unfold margrabeD1
      rw [mg_log _ _ _ _ hS₁ hS₂]
      congr 1
      rw [mul_pow, hE2]
      linear_combination (σ₁ ^ 2 * ρ ^ 2 - σ₁ * σ₂ * ρ + σ₁ ^ 2 * √(1 - ρ ^ 2) ^ 2 -
        (σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) / 2) * hs2 + T * σ₁ ^ 2 * hc2
    have hnum2 : (log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * (σ₂ * √T) + σ₁ * √T * √(1 - ρ ^ 2) * 0 =
        ((log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * (σ₁ * √T * ρ) +
          σ₁ * √T * √(1 - ρ ^ 2) * (σ₁ * √T * √(1 - ρ ^ 2))) - (effVol σ₁ σ₂ ρ * √T) ^ 2 := by
      linear_combination √T ^ 2 * hE2 - √T ^ 2 * σ₁ ^ 2 * hc2
    have hK2 : ((log S₁ - log S₂ + (r - q₁ - σ₁ ^ 2 / 2) * T - (r - q₂ - σ₂ ^ 2 / 2) * T) +
          (σ₁ * √T * ρ - σ₂ * √T) * (σ₂ * √T) + σ₁ * √T * √(1 - ρ ^ 2) * 0) /
          (effVol σ₁ σ₂ ρ * √T) =
        margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T := by
      rw [hnum2, sub_div, hK1]
      congr 1
      field_simp
    rw [hK1, hK2]
    simp only [margrabePrice, hv.ne', ↓reduceIte]
    have e1 : exp (-r * T) * (exp ((r - q₁ - σ₁ ^ 2 / 2) * T) *
        exp (((σ₁ * √T * ρ) ^ 2 + (σ₁ * √T * √(1 - ρ ^ 2)) ^ 2) / 2)) = exp (-q₁ * T) := by
      rw [← exp_add, ← exp_add]; congr 1
      simp only [mul_pow, hs2, hc2]; ring
    have e2 : exp (-r * T) * (exp ((r - q₂ - σ₂ ^ 2 / 2) * T) *
        exp (((σ₂ * √T) ^ 2 + 0 ^ 2) / 2)) = exp (-q₂ * T) := by
      rw [← exp_add, ← exp_add]; congr 1
      simp only [mul_pow, hs2]; ring
    linear_combination (S₁ * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)) * e1 -
      (S₂ * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T)) * e2

/-- **The vanilla call is the case where Birch is cash** (Step 5). Replace Birch by a bond paying
`K > 0` at expiry: today's price `K e^(-rT)`, no dividend, no volatility. Then Margrabe's formula,
at any correlation, gives the Black-Scholes call on Acme (`S₁ > 0`, volatility `σ₁ ≥ 0`) with the
fixed cash strike `K`, bank rate `r` and `T > 0` years to expiry. -/
theorem margrabe_with_bond_is_black_scholes_call
    (S₁ K r q₁ σ₁ ρ T : ℝ) (hS₁ : 0 < S₁) (hK : 0 < K) (hσ₁ : 0 ≤ σ₁) (hT : 0 < T) :
    margrabePrice S₁ (K * exp (-r * T)) q₁ 0 σ₁ 0 ρ T = bsCall S₁ K r q₁ σ₁ T := by
  have heff : effVol σ₁ 0 ρ = σ₁ := by
    unfold effVol
    rw [show σ₁ ^ 2 + 0 ^ 2 - 2 * ρ * σ₁ * 0 = σ₁ ^ 2 by ring]
    exact sqrt_sq hσ₁
  have e0 : K * exp (-r * T) * exp (-0 * T) = K * exp (-r * T) := by simp
  unfold margrabePrice margrabeD1 bsCall
  rw [heff, e0]
  split_ifs with h
  · rfl
  · have hd : (log (S₁ * exp (-q₁ * T) / (K * exp (-r * T))) + (σ₁ * √T) ^ 2 / 2) / (σ₁ * √T) =
        (log (S₁ / K) + (r - q₁ + σ₁ ^ 2 / 2) * T) / (σ₁ * √T) := by
      rw [mg_log _ _ _ _ hS₁ hK, log_div hS₁.ne' hK.ne', mul_pow, sq_sqrt hT.le]
      ring
    rw [hd]

/-- **The hedge holds shares and no cash** (Step 4). With `S₁ > 0`, `S₂ > 0`, `T > 0` and a ratio
that moves (`effVol σ₁ σ₂ ρ > 0`), the price's sensitivity to Acme is
`Δ₁ = e^(-q₁T) N(d₁)`, its sensitivity to Birch is `Δ₂ = -e^(-q₂T) N(d₂)`, and the price is
exactly `S₁Δ₁ + S₂Δ₂`, with no cash term (Euler's identity for a price of degree one). -/
theorem margrabe_deltas_and_shares_only_hedge
    (S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T : ℝ) (hS₁ : 0 < S₁) (hS₂ : 0 < S₂) (hT : 0 < T)
    (hσ : 0 < effVol σ₁ σ₂ ρ) :
    HasDerivAt (fun x => margrabePrice x S₂ q₁ q₂ σ₁ σ₂ ρ T)
        (exp (-q₁ * T) * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)) S₁ ∧
      HasDerivAt (fun y => margrabePrice S₁ y q₁ q₂ σ₁ σ₂ ρ T)
        (-(exp (-q₂ * T) *
          stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T))) S₂ ∧
      margrabePrice S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T =
        S₁ * (exp (-q₁ * T) * stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)) +
          S₂ * (-(exp (-q₂ * T) *
            stdNormalCDF (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T))) := by
  have hv : 0 < effVol σ₁ σ₂ ρ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have key := mg_ratio S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T hS₁ hS₂ hv
  refine ⟨?_, ?_, ?_⟩
  · have hfun : (fun x => margrabePrice x S₂ q₁ q₂ σ₁ σ₂ ρ T) = fun x =>
        x * exp (-q₁ * T) * stdNormalCDF (margrabeD1 x S₂ q₁ q₂ σ₁ σ₂ ρ T) -
          S₂ * exp (-q₂ * T) *
            stdNormalCDF (margrabeD1 x S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T) := by
      funext x
      simp only [margrabePrice, hv.ne', ↓reduceIte]
    have hin : HasDerivAt (fun x => x * exp (-q₁ * T) / (S₂ * exp (-q₂ * T)))
        (1 * exp (-q₁ * T) / (S₂ * exp (-q₂ * T))) S₁ :=
      ((hasDerivAt_id' S₁).mul_const _).div_const _
    have hne : S₁ * exp (-q₁ * T) / (S₂ * exp (-q₂ * T)) ≠ 0 :=
      (div_pos (mul_pos hS₁ (exp_pos _)) (mul_pos hS₂ (exp_pos _))).ne'
    obtain ⟨d', hd1⟩ : ∃ d', HasDerivAt (fun x => margrabeD1 x S₂ q₁ q₂ σ₁ σ₂ ρ T) d' S₁ :=
      ⟨_, ((hin.log hne).add_const _).div_const _⟩
    have hd2 := hd1.sub_const (effVol σ₁ σ₂ ρ * √T)
    have hN1 := (mg_hasDerivAt_N (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)).comp S₁ hd1
    have hN2 := (mg_hasDerivAt_N
      (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T)).comp S₁ hd2
    have h := (((hasDerivAt_id' S₁).mul_const (exp (-q₁ * T))).mul hN1).sub
      (hN2.const_mul (S₂ * exp (-q₂ * T)))
    rw [hfun]
    refine h.congr_deriv ?_
    simp only [Function.comp_apply]
    linear_combination d' * key
  · have hfun : (fun y => margrabePrice S₁ y q₁ q₂ σ₁ σ₂ ρ T) = fun y =>
        S₁ * exp (-q₁ * T) * stdNormalCDF (margrabeD1 S₁ y q₁ q₂ σ₁ σ₂ ρ T) -
          y * exp (-q₂ * T) *
            stdNormalCDF (margrabeD1 S₁ y q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T) := by
      funext y
      simp only [margrabePrice, hv.ne', ↓reduceIte]
    have hden : HasDerivAt (fun y => y * exp (-q₂ * T)) (1 * exp (-q₂ * T)) S₂ :=
      (hasDerivAt_id' S₂).mul_const _
    have hin := (hasDerivAt_const S₂ (S₁ * exp (-q₁ * T))).div hden
      (mul_pos hS₂ (exp_pos _)).ne'
    have hne : S₁ * exp (-q₁ * T) / (S₂ * exp (-q₂ * T)) ≠ 0 :=
      (div_pos (mul_pos hS₁ (exp_pos _)) (mul_pos hS₂ (exp_pos _))).ne'
    obtain ⟨d', hd1⟩ : ∃ d', HasDerivAt (fun y => margrabeD1 S₁ y q₁ q₂ σ₁ σ₂ ρ T) d' S₂ :=
      ⟨_, ((hin.log hne).add_const _).div_const _⟩
    have hd2 := hd1.sub_const (effVol σ₁ σ₂ ρ * √T)
    have hN1 := (mg_hasDerivAt_N (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T)).comp S₂ hd1
    have hN2 := (mg_hasDerivAt_N
      (margrabeD1 S₁ S₂ q₁ q₂ σ₁ σ₂ ρ T - effVol σ₁ σ₂ ρ * √T)).comp S₂ hd2
    have h := (hN1.const_mul (S₁ * exp (-q₁ * T))).sub
      (((hasDerivAt_id' S₂).mul_const (exp (-q₂ * T))).mul hN2)
    rw [hfun]
    refine h.congr_deriv ?_
    simp only [Function.comp_apply]
    linear_combination d' * key
  · simp only [margrabePrice, hv.ne', ↓reduceIte]
    ring

/-! The card's exact worked numbers (fractions, no decimals). Acme and Birch: S₁ = S₂ = 100,
σ₁ = σ₂ = 1/5, q₁ = q₂ = 2/100, ρ = 1/2, T = 1. -/

-- Acme ends at $120 and Birch at $110: the swap earns $10.
example : max ((120 : ℤ) - 110) 0 = 10 := by decide
-- Acme ends below Birch: the holder walks away with nothing.
example : max ((100 : ℤ) - 110) 0 = 0 := by decide
-- Step 0, the payoff factors: max(120 - 110, 0) = 110 · max(120/110 - 1, 0).
example : max ((120 : ℚ) - 110) 0 = 110 * max (120 / 110 - 1) 0 := by norm_num
-- Step 1: effective variance 0.04 + 0.04 - 2 × 0.5 × 0.2 × 0.2 = 0.04.
example : (1 / 5 : ℚ) ^ 2 + (1 / 5) ^ 2 - 2 * (1 / 2) * (1 / 5) * (1 / 5) = 1 / 25 := by norm_num
-- Effective volatility √0.04 = 0.20.
example : effVol (1 / 5) (1 / 5) (1 / 2) = 1 / 5 := by
  rw [effVol, show (1 / 5 : ℝ) ^ 2 + (1 / 5) ^ 2 - 2 * (1 / 2) * (1 / 5) * (1 / 5) = (1 / 5) ^ 2 by
    norm_num]
  exact Real.sqrt_sq (by norm_num)
-- At correlation -1 the ratio moves 40 percent a year: √0.16 = 0.4.
example : effVol (1 / 5) (1 / 5) (-1) = 2 / 5 := by
  rw [effVol, show (1 / 5 : ℝ) ^ 2 + (1 / 5) ^ 2 - 2 * (-1) * (1 / 5) * (1 / 5) = (2 / 5) ^ 2 by
    norm_num]
  exact Real.sqrt_sq (by norm_num)
-- At correlation +1 the two shares take the same shock, the ratio never moves, and the option
-- on Acme and Birch is worthless.
example : margrabePrice 100 100 (2 / 100) (2 / 100) (1 / 5) (1 / 5) 1 1 = 0 := by
  norm_num [margrabePrice, effVol]
-- d₁ = (ln 1 + 0.5 × 0.04) / 0.20 = 0.1, and d₂ = 0.1 - 0.20 = -0.1.
example : (log 1 + (1 / 2 : ℝ) * (1 / 25)) / (1 / 5) = 1 / 10 := by norm_num
example : (1 / 10 : ℚ) - 1 / 5 = -1 / 10 := by norm_num
-- The price: 52.914 - 45.106 = 7.808, which rounds to $7.81.
example : (52914 / 1000 : ℚ) - 45106 / 1000 = 7808 / 1000 := by norm_num
-- Step 4: 0.52914 × $100 - 0.45106 × $100 = $7.808.
example : (52914 / 100000 : ℚ) * 100 - 45106 / 100000 * 100 = 7808 / 1000 := by norm_num
-- What breaks: no correlation term gives variance 0.08, the plus sign 0.12, the missing 2 0.06.
example : (1 / 5 : ℚ) ^ 2 + (1 / 5) ^ 2 = 2 / 25 := by norm_num
example : (1 / 5 : ℚ) ^ 2 + (1 / 5) ^ 2 + 2 * (1 / 2) * (1 / 5) * (1 / 5) = 3 / 25 := by norm_num
example : (1 / 5 : ℚ) ^ 2 + (1 / 5) ^ 2 - (1 / 2) * (1 / 5) * (1 / 5) = 3 / 50 := by norm_num
-- The profit chart: Birch at $100 and Acme at $110 gives $10 - $7.81 = $2.19; Birch at $110
-- slides the kink, and Acme at $120 gives the same $2.19.
example : max ((110 : ℚ) - 100) 0 - 781 / 100 = 219 / 100 := by norm_num
example : max ((120 : ℚ) - 110) 0 - 781 / 100 = 219 / 100 := by norm_num

#print axioms exchange_option_price_is_margrabe_zero_rate_ratio_call
#print axioms margrabe_with_bond_is_black_scholes_call
#print axioms margrabe_deltas_and_shares_only_hedge
