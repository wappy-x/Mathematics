-- Pricing with local volatility: two models that give the price the same law on every date give the same price to every plain call, put and one-date payoff, yet can price a forward start differently, and at one flat volatility the forward start is worth S₀ e^(-q t₁) C_BS(1, κ, T - t₁, σ).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

namespace LocalVolForwardSmile

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The card's `C_BS(price, strike, years, volatility)`: the Black-Scholes call
`s e^(-qτ) N(d₁) - k e^(-rτ) N(d₂)` with `d₁ = (ln(s/k) + (r - q + σ²/2) τ) / (σ√τ)` and
`d₂ = d₁ - σ√τ`, at riskless rate `r` and dividend yield `q`. -/
noncomputable def bsCall (r q s k τ σ : ℝ) : ℝ :=
  let d₁ := (log (s / k) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ)
  s * exp (-q * τ) * stdNormalCDF d₁ - k * exp (-r * τ) * stdNormalCDF (d₁ - σ * √τ)

open Set in
lemma gauss_Ioi_eq (c : ℝ) : (gaussianReal 0 1).real (Ioi c) = stdNormalCDF (-c) := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [stdNormalCDF, cdf_eq_real]
  have hm : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg]; simp
  conv_rhs => rw [← hm]
  rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
  have : (fun x : ℝ => -x) ⁻¹' Iic (-c) = Ici c := by
    ext x; simp
  rw [this]
  simp only [Measure.real]
  rw [measure_congr Ioi_ae_eq_Ici]

#print axioms gauss_Ioi_eq

open Set in
lemma pdf_tilt (b x : ℝ) :
    gaussianPDFReal 0 1 x * exp (b * x) = exp (b ^ 2 / 2) * gaussianPDFReal b 1 x := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one]
  rw [mul_assoc, ← exp_add, mul_left_comm, ← exp_add]
  congr 2
  ring

#print axioms pdf_tilt

open Set in
lemma gauss_tilt (b c : ℝ) :
    ∫ z in Ioi c, exp (b * z) ∂(gaussianReal 0 1) = exp (b ^ 2 / 2) * stdNormalCDF (b - c) := by
  rw [← integral_indicator measurableSet_Ioi,
    integral_gaussianReal_eq_integral_smul one_ne_zero]
  have h1 : (fun x => gaussianPDFReal 0 1 x • (Ioi c).indicator (fun z => exp (b * z)) x)
      = (Ioi c).indicator (fun x => exp (b ^ 2 / 2) * gaussianPDFReal b 1 x) := by
    ext x
    by_cases hx : x ∈ Ioi c
    · simp [hx, pdf_tilt]
    · simp [hx]
  rw [h1, integral_indicator measurableSet_Ioi, integral_const_mul]
  congr 1
  have h2 := gaussianReal_apply_eq_integral b (v := 1) one_ne_zero (Ioi c)
  have h3 : ∫ x in Ioi c, gaussianPDFReal b 1 x = (gaussianReal b 1).real (Ioi c) := by
    rw [Measure.real, h2, ENNReal.toReal_ofReal]
    exact setIntegral_nonneg measurableSet_Ioi (fun x _ => gaussianPDFReal_nonneg _ _ _)
  rw [h3]
  have hm : (gaussianReal 0 1).map (· + b) = gaussianReal b 1 := by
    rw [gaussianReal_map_add_const]; simp
  rw [← hm, map_measureReal_apply (by fun_prop) measurableSet_Ioi]
  have : (· + b) ⁻¹' Ioi c = Ioi (c - b) := by
    ext x; simp [sub_lt_iff_lt_add]
  rw [this, gauss_Ioi_eq]
  ring_nf

#print axioms gauss_tilt

open Set in
lemma gauss_call (a b κ : ℝ) (hb : 0 < b) (hκ : 0 < κ) :
    ∫ z, max (exp (a + b * z) - κ) 0 ∂(gaussianReal 0 1) =
      exp (a + b ^ 2 / 2) * stdNormalCDF ((a - log κ) / b + b) -
        κ * stdNormalCDF ((a - log κ) / b) := by
  set c := (log κ - a) / b with hc
  have hpt : (fun z => max (exp (a + b * z) - κ) 0)
      = (Ioi c).indicator (fun z => exp a * exp (b * z) - κ) := by
    ext z
    by_cases hz : z ∈ Ioi c
    · rw [indicator_of_mem hz, ← exp_add]
      have : c * b < z * b := mul_lt_mul_of_pos_right hz hb
      have hcb : c * b = log κ - a := by rw [hc]; field_simp
      have : log κ < a + b * z := by linarith
      have : κ < exp (a + b * z) := by
        rw [← exp_log hκ]; exact exp_lt_exp.mpr this
      rw [max_eq_left (by linarith)]
    · rw [indicator_of_notMem hz]
      simp only [mem_Ioi, not_lt] at hz
      have : z * b ≤ c * b := mul_le_mul_of_nonneg_right hz hb.le
      have hcb : c * b = log κ - a := by rw [hc]; field_simp
      have : a + b * z ≤ log κ := by linarith
      have : exp (a + b * z) ≤ κ := by
        rw [← exp_log hκ]; exact exp_le_exp.mpr this
      rw [max_eq_right (by linarith)]
  rw [hpt, integral_indicator measurableSet_Ioi, integral_sub, integral_const_mul,
    setIntegral_const, gauss_tilt, gauss_Ioi_eq]
  · have e1 : b - c = (a - log κ) / b + b := by rw [hc]; field_simp; ring
    have e2 : -c = (a - log κ) / b := by rw [hc]; ring
    rw [e1, e2, exp_add, smul_eq_mul]
    ring
  · exact ((integrable_exp_mul_gaussianReal b).const_mul _).integrableOn
  · exact integrableOn_const (by simp)

#print axioms gauss_call

/-- **Plain options see one date at a time** (Why it works, Step 0; the card's bold claim that
local volatility reproduces every price that depends on one date). Take two pricing-world
models of Acme, on possibly different probability spaces: `S t` and `S' t` are Acme's price on
date `t` in each. If the two give Acme the same distribution on every date, then, however
differently they join the dates, they give the same price `V₀ = e^(-rT) 𝔼[payoff at T]` to
every plain call `max(S_T - K, 0)` and every plain put `max(K - S_T, 0)`, at every strike and
expiry, and to every contract whose payoff depends on Acme's price on one date only. This is
why a local-volatility table fitted to every one-date distribution (Gyöngy's twin) cannot miss
a single vanilla. -/
theorem same_one_date_laws_give_same_vanilla_prices
    {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    (μ : Measure Ω) (ν : Measure Ω') [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (S : ℝ → Ω → ℝ) (S' : ℝ → Ω' → ℝ) (r : ℝ)
    (hS : ∀ t, AEMeasurable (S t) μ) (hS' : ∀ t, AEMeasurable (S' t) ν)
    (hlaw : ∀ t, μ.map (S t) = ν.map (S' t)) :
    (∀ T K : ℝ,
      exp (-r * T) * ∫ ω, max (S T ω - K) 0 ∂μ = exp (-r * T) * ∫ ω, max (S' T ω - K) 0 ∂ν ∧
      exp (-r * T) * ∫ ω, max (K - S T ω) 0 ∂μ = exp (-r * T) * ∫ ω, max (K - S' T ω) 0 ∂ν) ∧
    (∀ (T : ℝ) (f : ℝ → ℝ), Measurable f →
      exp (-r * T) * ∫ ω, f (S T ω) ∂μ = exp (-r * T) * ∫ ω, f (S' T ω) ∂ν) := by
  have key : ∀ (T : ℝ) (f : ℝ → ℝ), Measurable f →
      ∫ ω, f (S T ω) ∂μ = ∫ ω, f (S' T ω) ∂ν := by
    intro T f hf
    rw [← integral_map (hS T) hf.aestronglyMeasurable, hlaw T,
      integral_map (hS' T) hf.aestronglyMeasurable]
  refine ⟨fun T K => ⟨?_, ?_⟩, fun T f hf => by rw [key T f hf]⟩
  · rw [key T (fun x => max (x - K) 0) (by fun_prop)]
  · rw [key T (fun x => max (K - x) 0) (by fun_prop)]

/-- **How two dates hang together is left open** (Why it works, Steps 0 and 5; The usual
mistake). Plain prices fix where Acme may stand on each date, one date at a time, and nothing
about how the dates join. For every strike fraction `κ > 0`, there are two joint laws of
Acme's prices `(S_{t₁}, S_T)` on the reset date and at expiry, both with positive prices, that
give Acme the same distribution on the reset date and the same distribution at expiry (so the
same price to every plain option on either date), yet different prices
`e^(-rT) 𝔼[max(S_T - κ S_{t₁}, 0)]` to the forward start. -/
theorem same_marginals_different_forward_start_price (r T κ : ℝ) (hκ : 0 < κ) :
    ∃ μ ν : Measure (ℝ × ℝ), IsProbabilityMeasure μ ∧ IsProbabilityMeasure ν ∧
      (∀ᵐ p ∂μ, 0 < p.1 ∧ 0 < p.2) ∧ (∀ᵐ p ∂ν, 0 < p.1 ∧ 0 < p.2) ∧
      μ.map Prod.fst = ν.map Prod.fst ∧ μ.map Prod.snd = ν.map Prod.snd ∧
      exp (-r * T) * ∫ p, max (p.2 - κ * p.1) 0 ∂μ ≠
        exp (-r * T) * ∫ p, max (p.2 - κ * p.1) 0 ∂ν := by
  let pμ : Measure (ℝ × ℝ) :=
    (2⁻¹ : ENNReal) • (Measure.dirac ((1 : ℝ), κ) + Measure.dirac ((2 : ℝ), 3 * κ))
  let pν : Measure (ℝ × ℝ) :=
    (2⁻¹ : ENNReal) • (Measure.dirac ((1 : ℝ), 3 * κ) + Measure.dirac ((2 : ℝ), κ))
  have hprob : ∀ x y : ℝ × ℝ,
      IsProbabilityMeasure ((2⁻¹ : ENNReal) • (Measure.dirac x + Measure.dirac y)) := by
    intro x y
    constructor
    simp only [Measure.smul_apply, Measure.add_apply, measure_univ, smul_eq_mul]
    rw [one_add_one_eq_two, ENNReal.inv_mul_cancel (by norm_num) (by norm_num)]
  have hpos : ∀ x y : ℝ × ℝ, 0 < x.1 → 0 < x.2 → 0 < y.1 → 0 < y.2 →
      ∀ᵐ p ∂((2⁻¹ : ENNReal) • (Measure.dirac x + Measure.dirac y)), 0 < p.1 ∧ 0 < p.2 := by
    intro x y hx1 hx2 hy1 hy2
    refine Measure.ae_smul_measure ?_ _
    rw [ae_add_measure_iff]
    exact ⟨by rw [ae_dirac_eq]; exact ⟨hx1, hx2⟩, by rw [ae_dirac_eq]; exact ⟨hy1, hy2⟩⟩
  have hint : ∀ x y : ℝ × ℝ,
      ∫ p, max (p.2 - κ * p.1) 0 ∂((2⁻¹ : ENNReal) • (Measure.dirac x + Measure.dirac y)) =
        2⁻¹ * (max (x.2 - κ * x.1) 0 + max (y.2 - κ * y.1) 0) := by
    intro x y
    rw [integral_smul_measure, integral_add_measure, integral_dirac, integral_dirac]
    · simp
    · exact integrable_dirac (by simp)
    · exact integrable_dirac (by simp)
  refine ⟨pμ, pν, hprob _ _, hprob _ _, hpos _ _ (by norm_num) hκ (by norm_num) (by linarith),
    hpos _ _ (by norm_num) (by linarith) (by norm_num) hκ, ?_, ?_, ?_⟩
  · simp only [pμ, pν]
    rw [Measure.map_smul, Measure.map_smul, Measure.map_add _ _ measurable_fst,
      Measure.map_add _ _ measurable_fst, Measure.map_dirac' measurable_fst,
      Measure.map_dirac' measurable_fst, Measure.map_dirac' measurable_fst,
      Measure.map_dirac' measurable_fst]
    all_goals exact measurable_fst.aemeasurable
  · simp only [pμ, pν]
    rw [Measure.map_smul, Measure.map_smul, Measure.map_add _ _ measurable_snd,
      Measure.map_add _ _ measurable_snd, Measure.map_dirac' measurable_snd,
      Measure.map_dirac' measurable_snd, Measure.map_dirac' measurable_snd,
      Measure.map_dirac' measurable_snd, add_comm (Measure.dirac κ)]
    all_goals exact measurable_snd.aemeasurable
  · simp only [pμ, pν]
    rw [hint, hint]
    have e1 : max (κ - κ * 1) 0 = 0 := by simp
    have e2 : max (3 * κ - κ * 2) 0 = κ := by rw [max_eq_left] <;> linarith
    have e3 : max (3 * κ - κ * 1) 0 = 2 * κ := by rw [max_eq_left] <;> linarith
    have e4 : max (κ - κ * 2) 0 = 0 := by rw [max_eq_right]; linarith
    simp only [e1, e2, e3, e4]
    intro h
    have := mul_left_cancel₀ (exp_pos (-r * T)).ne' h
    linarith

/-- **The forward start at one flat volatility** (The formula). In the Black-Scholes world with
one flat volatility `σ > 0`, Acme starts at `S₀ > 0`, stands at
`S_{t₁} = S₀ e^((r - q - σ²/2) t₁ + σ√t₁ Z₁)` on the reset date `t₁ > 0`, and at
`S_T = S_{t₁} e^((r - q - σ²/2)(T - t₁) + σ√(T - t₁) Z₂)` at expiry `T > t₁`, with `Z₁`, `Z₂`
independent standard bell-curve draws. The forward start pays `max(S_T - κ S_{t₁}, 0)` at `T`,
its strike fixed on the reset date as the fraction `κ > 0` of Acme's price then. Its price
`e^(-rT) 𝔼[payoff]` is `S₀ e^(-q t₁) C_BS(1, κ, T - t₁, σ)`: today's value of receiving
`S_{t₁}` copies of a call on one dollar's worth of Acme struck at `κ` dollars. -/
theorem forward_start_price_flat_vol
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (Z₁ Z₂ : Ω → ℝ) (S₀ r q σ t₁ T κ : ℝ)
    (hS₀ : 0 < S₀) (hσ : 0 < σ) (ht₁ : 0 < t₁) (hT : t₁ < T) (hκ : 0 < κ)
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) P) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) P)
    (hind : IndepFun Z₁ Z₂ P) :
    let St₁ : Ω → ℝ := fun ω => S₀ * exp ((r - q - σ ^ 2 / 2) * t₁ + σ * √t₁ * Z₁ ω)
    let ST : Ω → ℝ := fun ω =>
      St₁ ω * exp ((r - q - σ ^ 2 / 2) * (T - t₁) + σ * √(T - t₁) * Z₂ ω)
    exp (-r * T) * ∫ ω, max (ST ω - κ * St₁ ω) 0 ∂P =
      S₀ * exp (-q * t₁) * bsCall r q 1 κ (T - t₁) σ := by
  intro St₁ ST
  have hZ₁m := hZ₁.aemeasurable
  have hZ₂m := hZ₂.aemeasurable
  set τ := T - t₁ with hτ
  have hτpos : 0 < τ := by rw [hτ]; linarith
  set a := (r - q - σ ^ 2 / 2) * τ with ha
  set b := σ * √τ with hb
  have hbpos : 0 < b := mul_pos hσ (Real.sqrt_pos.mpr hτpos)
  set g : ℝ → ℝ := fun z => max (exp (a + b * z) - κ) 0 with hg
  set f : ℝ → ℝ := fun z => S₀ * exp ((r - q - σ ^ 2 / 2) * t₁ + σ * √t₁ * z) with hf
  have hSt : ∀ ω, St₁ ω = f (Z₁ ω) := fun ω => rfl
  have hpt : ∀ ω, max (ST ω - κ * St₁ ω) 0 = f (Z₁ ω) * g (Z₂ ω) := by
    intro ω
    have hposS : 0 ≤ St₁ ω := by positivity
    show max (St₁ ω * exp (a + b * Z₂ ω) - κ * St₁ ω) 0 = St₁ ω * max (exp (a + b * Z₂ ω) - κ) 0
    rw [mul_max_of_nonneg _ _ hposS, mul_zero, mul_sub, mul_comm κ]
  simp_rw [hpt]
  have hfm : Measurable f := by rw [hf]; fun_prop
  have hgm : Measurable g := by rw [hg]; fun_prop
  have hmul : ∫ ω, f (Z₁ ω) * g (Z₂ ω) ∂P = P[f ∘ Z₁] * P[g ∘ Z₂] :=
    IndepFun.integral_fun_mul_eq_mul_integral (hind.comp hfm hgm)
      (hfm.comp_aemeasurable hZ₁m).aestronglyMeasurable
      (hgm.comp_aemeasurable hZ₂m).aestronglyMeasurable
  rw [hmul]
  have hE2 : P[g ∘ Z₂] = ∫ z, g z ∂(gaussianReal 0 1) :=
    hZ₂.integral_comp hgm.aestronglyMeasurable
  have hE1 : P[f ∘ Z₁] = S₀ * exp ((r - q - σ ^ 2 / 2) * t₁) * exp ((σ * √t₁) ^ 2 / 2) := by
    have hm := mgf_gaussianReal hZ₁ (σ * √t₁)
    simp only [mgf, NNReal.coe_one, zero_mul, zero_add, one_mul] at hm
    rw [← hm, ← integral_const_mul]
    congr 1
    ext ω
    simp only [Function.comp, hf]
    rw [exp_add]; ring
  rw [hE1, hE2, hg, gauss_call a b κ hbpos hκ]
  have hd : (a - log κ) / b = (log (1 / κ) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ) - σ * √τ := by
    rw [one_div, log_inv, ha, hb]
    have : √τ ≠ 0 := (Real.sqrt_pos.mpr hτpos).ne'
    field_simp
    rw [Real.sq_sqrt hτpos.le]
    ring
  have hd1 : (a - log κ) / b + b = (log (1 / κ) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ) := by
    rw [hd, hb]; ring
  simp only [bsCall]
  rw [hd1, hd]
  have hsq1 : (σ * √t₁) ^ 2 = σ ^ 2 * t₁ := by rw [mul_pow, Real.sq_sqrt ht₁.le]
  have hsq2 : b ^ 2 = σ ^ 2 * τ := by rw [hb, mul_pow, Real.sq_sqrt hτpos.le]
  have h1 : exp (-r * T) * exp ((r - q - σ ^ 2 / 2) * t₁) * exp ((σ * √t₁) ^ 2 / 2) =
      exp (-q * t₁) * exp (-r * τ) := by
    rw [← exp_add, ← exp_add, ← exp_add, hsq1, hτ]; congr 1; ring
  have h2 : exp (-r * τ) * exp (a + b ^ 2 / 2) = exp (-q * τ) := by
    rw [← exp_add, hsq2, ha]; congr 1; ring
  linear_combination
    (S₀ * (exp (a + b ^ 2 / 2) * stdNormalCDF ((log (1 / κ) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ)) -
      κ * stdNormalCDF ((log (1 / κ) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ) - σ * √τ))) * h1 +
    S₀ * exp (-q * t₁) * stdNormalCDF ((log (1 / κ) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ)) * h2

/-! The card's surface, exactly. The SSVI total variance
`w(x, T) = θ/2 (1 + ρ φ x + √((φ x + ρ)² + 1 - ρ²))` with `θ = 0.04 T`, `φ = η/√θ`, `ρ = -0.7`
and `η = 0.5` is centred on today's price: at log-strike `x = 0` (the $100 strike) it is
`0.04 T` at every expiry, so the $100 strike sits at 20% volatility at every expiry. -/

/-- The card's SSVI total implied variance at log-strike `x` and expiry `T`. -/
noncomputable def ssvi (ρ η x T : ℝ) : ℝ :=
  let θ := (1 / 25 : ℝ) * T
  let φ := η / √θ
  θ / 2 * (1 + ρ * φ * x + √((φ * x + ρ) ^ 2 + 1 - ρ ^ 2))

-- at the $100 strike the total variance is 0.04 T, whatever the expiry
example (T : ℝ) : ssvi (-7 / 10) (1 / 2) 0 T = (1 / 25) * T := by
  simp [ssvi]
  ring

-- one year: total variance 0.04, the square of 20%
example : ssvi (-7 / 10) (1 / 2) 0 1 = (1 / 5) ^ 2 := by
  simp [ssvi]
  norm_num

#print axioms same_one_date_laws_give_same_vanilla_prices
#print axioms same_marginals_different_forward_start_price
#print axioms forward_start_price_flat_vol

end LocalVolForwardSmile
