-- Collateral in several currencies: when the poster may choose, the trade is discounted at the highest collateral rate in dollar terms, which equals SOFR plus the positive part of the spread and gives a discount factor below each single-currency one, and the average switch rate is the Bachelier call on the spread struck at zero, never below today's gap.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory

/-! The model, in the card's notation.
* `r u` is SOFR at date `u`, known today (the card's `r`, with `D(T) = exp (-∫₀ᵀ r)`).
* `rE ω u` is €STR and `y ω u` the euro rate implied by the currency forward, on path `ω`.
* Euro collateral earns `rE + (r - y)` in dollars; its spread over dollar collateral is
  `s = rE - y`.
* The collateral rate with the choice is `max (r u) (rE ω u + (r u - y ω u))`.
* `P` is the pricing probability; `∫ ω, … ∂P` is the card's average `𝔼`.
* For the switch rate, `Z` is a standard bell-curve draw, the measure `gaussianReal 0 1`;
  `N(x)` is `cdf (gaussianReal 0 1) x` and `φ(x)` is `gaussianPDFReal 0 1 x`. -/

section CsaHelpers

open Filter Topology Set

lemma gaussPDF_hasDerivAt (x : ℝ) :
    HasDerivAt (fun z => -gaussianPDFReal 0 1 z) (x * gaussianPDFReal 0 1 x) x := by
  have h0 : HasDerivAt (fun z : ℝ => z ^ 2) (2 * x) x := by simpa using hasDerivAt_pow 2 x
  have h : HasDerivAt (fun z : ℝ => -z ^ 2 / 2) (-x) x := by
    convert h0.neg.div_const 2 using 1; ring
  have h2 := (h.exp.const_mul (√(2 * Real.pi))⁻¹).neg
  convert h2 using 1
  · funext z; simp [gaussianPDFReal]
  · simp only [gaussianPDFReal, NNReal.coe_one, sub_zero, mul_one]; ring

lemma gaussPDF_tendsto : Tendsto (fun z => -gaussianPDFReal 0 1 z) atTop (𝓝 0) := by
  have h1 : Tendsto (fun z : ℝ => -(z - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))) atTop atBot := by
    simp only [sub_zero, NNReal.coe_one, mul_one]
    have := (tendsto_pow_atTop (α := ℝ) two_ne_zero)
    exact (tendsto_neg_atTop_atBot.comp this).atBot_div_const (by norm_num)
  have h2 := (Real.tendsto_exp_atBot.comp h1).const_mul (√(2 * Real.pi * ((1 : NNReal) : ℝ)))⁻¹
  simpa [gaussianPDFReal] using h2.neg

lemma gaussPDF_mul_integrable : Integrable (fun z => z * gaussianPDFReal 0 1 z) := by
  have := (integrable_mul_exp_neg_mul_sq (b := 1/2) (by norm_num)).const_mul
    (√(2 * Real.pi * ((1 : NNReal) : ℝ)))⁻¹
  convert this using 2 with z
  simp only [gaussianPDFReal, NNReal.coe_one]; ring_nf

lemma gauss_setIntegral_id (c : ℝ) :
    ∫ z in Ioi c, z ∂(gaussianReal 0 1) = gaussianPDFReal 0 1 c := by
  rw [← integral_indicator measurableSet_Ioi,
    integral_gaussianReal_eq_integral_smul (by norm_num)]
  have : (fun x => gaussianPDFReal 0 1 x • (Ioi c).indicator (fun z => z) x) =
      (Ioi c).indicator (fun z => z * gaussianPDFReal 0 1 z) := by
    ext x; by_cases hx : x ∈ Ioi c <;> simp [hx, mul_comm]
  rw [this, integral_indicator measurableSet_Ioi,
    integral_Ioi_of_hasDerivAt_of_tendsto' (fun x _ => gaussPDF_hasDerivAt x)
      gaussPDF_mul_integrable.integrableOn gaussPDF_tendsto]
  ring

lemma gauss_real_Ioi_neg (d : ℝ) :
    (gaussianReal 0 1).real (Ioi (-d)) = (gaussianReal 0 1).real (Iic d) := by
  have hm : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg]; simp
  have : (gaussianReal 0 1).real (Ioi (-d)) = (gaussianReal 0 1).real (Iio d) := by
    conv_lhs => rw [← hm]
    rw [map_measureReal_apply measurable_neg measurableSet_Ioi]
    congr 1; ext x; simp
  rw [this]
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) (by norm_num)
  simp [measureReal_def, measure_congr Iio_ae_eq_Iic]

lemma gaussPDF_neg (d : ℝ) : gaussianPDFReal 0 1 (-d) = gaussianPDFReal 0 1 d := by
  simp [gaussianPDFReal]

end CsaHelpers

#print axioms gaussPDF_hasDerivAt
#print axioms gaussPDF_tendsto
#print axioms gaussPDF_mul_integrable
#print axioms gauss_setIntegral_id
#print axioms gauss_real_Ioi_neg
#print axioms gaussPDF_neg

/-- Highest-rate discounting with two collateral currencies: euro collateral's edge over
dollar collateral is `s = rE - y` (the overnight levels cancel); the collateral rate, the
best on the list at every instant, is `r + max(s, 0)`; so the cheapest-to-deliver discount
factor to `T` is `D(T)` times the average of `exp (-∫₀ᵀ max(s, 0))`, and on every path it is
at most the dollar-only factor and at most the euro-only factor. -/
theorem ctd_discount_at_highest_rate {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (r : ℝ → ℝ) (rE y : Ω → ℝ → ℝ) (T : ℝ) (hT : 0 ≤ T)
    (hr : IntervalIntegrable r volume 0 T)
    (hrE : ∀ ω, IntervalIntegrable (rE ω) volume 0 T)
    (hy : ∀ ω, IntervalIntegrable (y ω) volume 0 T) :
    (∀ ω u, (rE ω u + (r u - y ω u)) - r u = rE ω u - y ω u) ∧
    (∀ ω u, max (r u) (rE ω u + (r u - y ω u)) = r u + max (rE ω u - y ω u) 0) ∧
    (∫ ω, Real.exp (-∫ u in (0 : ℝ)..T, max (r u) (rE ω u + (r u - y ω u))) ∂P =
      Real.exp (-∫ u in (0 : ℝ)..T, r u) *
        ∫ ω, Real.exp (-∫ u in (0 : ℝ)..T, max (rE ω u - y ω u) 0) ∂P) ∧
    (∀ ω,
      Real.exp (-∫ u in (0 : ℝ)..T, max (r u) (rE ω u + (r u - y ω u))) ≤
          Real.exp (-∫ u in (0 : ℝ)..T, r u) ∧
      Real.exp (-∫ u in (0 : ℝ)..T, max (r u) (rE ω u + (r u - y ω u))) ≤
          Real.exp (-∫ u in (0 : ℝ)..T, (rE ω u + (r u - y ω u)))) := by
  have h2 : ∀ ω u, max (r u) (rE ω u + (r u - y ω u)) = r u + max (rE ω u - y ω u) 0 := by
    intro ω u
    simp only [max_def]
    split_ifs <;> linarith
  have hsi : ∀ ω, IntervalIntegrable (fun u => rE ω u - y ω u) volume 0 T :=
    fun ω => (hrE ω).sub (hy ω)
  have hs : ∀ ω, IntervalIntegrable (fun u => max (rE ω u - y ω u) 0) volume 0 T :=
    fun ω => ⟨(hsi ω).1.pos_part, (hsi ω).2.pos_part⟩
  have hI : ∀ ω, ∫ u in (0 : ℝ)..T, max (r u) (rE ω u + (r u - y ω u)) =
      (∫ u in (0 : ℝ)..T, r u) + ∫ u in (0 : ℝ)..T, max (rE ω u - y ω u) 0 := by
    intro ω
    simp_rw [h2 ω]
    exact intervalIntegral.integral_add hr (hs ω)
  refine ⟨fun ω u => by ring, h2, ?_, fun ω => ⟨?_, ?_⟩⟩
  · simp_rw [hI, neg_add, Real.exp_add]
    exact integral_const_mul _ _
  · rw [Real.exp_le_exp, neg_le_neg_iff, hI]
    have : 0 ≤ ∫ u in (0 : ℝ)..T, max (rE ω u - y ω u) 0 :=
      intervalIntegral.integral_nonneg hT (fun u _ => le_max_right _ _)
    linarith
  · rw [Real.exp_le_exp, neg_le_neg_iff, hI]
    have e1 : ∫ u in (0 : ℝ)..T, (rE ω u + (r u - y ω u)) =
        (∫ u in (0 : ℝ)..T, r u) + ∫ u in (0 : ℝ)..T, (rE ω u - y ω u) := by
      rw [← intervalIntegral.integral_add hr (hsi ω)]
      congr 1; funext u; ring
    have e2 : ∫ u in (0 : ℝ)..T, (rE ω u - y ω u) ≤
        ∫ u in (0 : ℝ)..T, max (rE ω u - y ω u) 0 :=
      intervalIntegral.integral_mono_on hT (hsi ω) (hs ω) (fun u _ => le_max_left _ _)
    linarith

/-- The poster picks the highest rate, whatever the trade's sign: with a shared list of
collateral currencies (rates in dollar terms) and a trade worth `V ≠ 0`, whoever posts
`|V|` earns `rate k * |V|` on currency `k`, and a currency gives the poster the most
interest exactly when its rate is the highest on the list. -/
theorem poster_picks_highest_rate {ι : Type*} (S : Finset ι) (hS : S.Nonempty)
    (rate : ι → ℝ) (V : ℝ) (hV : V ≠ 0) (k : ι) (hk : k ∈ S) :
    (∀ j ∈ S, rate j * |V| ≤ rate k * |V|) ↔ rate k = S.sup' hS rate := by
  have hV' : 0 < |V| := abs_pos.mpr hV
  simp_rw [mul_le_mul_iff_left₀ hV']
  constructor
  · intro h
    exact le_antisymm (Finset.le_sup' rate hk) (Finset.sup'_le hS rate h)
  · intro h j hj
    rw [h]
    exact Finset.le_sup' rate hj

/-- The switch rate is a Bachelier call on the spread struck at zero: with the spread at
date `u > 0` equal to `s₀ + σ √u Z` for a standard bell-curve draw `Z` and a positive normal
volatility `σ`, the average of `max(s, 0)` is `s₀ N(d) + σ √u φ(d)` with `d = s₀ / (σ √u)`,
and it is at least today's gap `max(s₀, 0)` (the average of a maximum is at least the
maximum of the averages, so the time value is never negative). -/
theorem switch_rate_bachelier (s₀ σ u : ℝ) (hσ : 0 < σ) (hu : 0 < u) :
    ∫ z, max (s₀ + σ * Real.sqrt u * z) 0 ∂(gaussianReal 0 1) =
        s₀ * cdf (gaussianReal 0 1) (s₀ / (σ * Real.sqrt u)) +
          σ * Real.sqrt u * gaussianPDFReal 0 1 (s₀ / (σ * Real.sqrt u)) ∧
      max s₀ 0 ≤ ∫ z, max (s₀ + σ * Real.sqrt u * z) 0 ∂(gaussianReal 0 1) := by
  set a := σ * Real.sqrt u with ha_def
  have ha : 0 < a := mul_pos hσ (Real.sqrt_pos.mpr hu)
  set d := s₀ / a with hd
  have hid : Integrable (fun z : ℝ => z) (gaussianReal 0 1) :=
    memLp_one_iff_integrable.mp (memLp_id_gaussianReal' 1 (by simp))
  have hlin : Integrable (fun z => s₀ + a * z) (gaussianReal 0 1) :=
    (integrable_const s₀).add (hid.const_mul a)
  refine ⟨?_, ?_⟩
  · have hmax : (fun z => max (s₀ + a * z) 0) = (Set.Ioi (-d)).indicator (fun z => s₀ + a * z) := by
      funext z
      by_cases hz : z ∈ Set.Ioi (-d)
      · rw [Set.indicator_of_mem hz]
        have : -s₀ < z * a := by
          have := hz.out; rw [hd, ← neg_div, div_lt_iff₀ ha] at this; exact this
        exact max_eq_left (by linarith)
      · rw [Set.indicator_of_notMem hz]
        have : z * a ≤ -s₀ := by
          have := not_lt.mp (show ¬ (-d < z) from hz); rw [hd, ← neg_div, le_div_iff₀ ha] at this; exact this
        exact max_eq_right (by linarith)
    rw [hmax, integral_indicator measurableSet_Ioi,
      integral_add (integrableOn_const (by simp)) (hid.const_mul a).integrableOn,
      setIntegral_const, integral_const_mul, gauss_setIntegral_id, gaussPDF_neg,
      gauss_real_Ioi_neg, cdf_eq_real, smul_eq_mul, mul_comm]
  · apply max_le
    · have e : ∫ z, (s₀ + a * z) ∂(gaussianReal 0 1) = s₀ := by
        rw [integral_add (integrable_const s₀) (hid.const_mul a), integral_const,
          integral_const_mul, integral_id_gaussianReal]
        simp
      calc s₀ = ∫ z, (s₀ + a * z) ∂(gaussianReal 0 1) := e.symm
        _ ≤ _ := integral_mono hlin hlin.pos_part (fun z => le_max_left _ _)
    · exact integral_nonneg (fun z => le_max_right _ _)

-- The card's worked numbers, as exact fractions (rates as fractions of 1, money in cents).
-- Euro collateral in dollars: 2.00% + (4.00% - 1.90%) = 4.10%.
example : (2 : ℚ) / 100 + (4 / 100 - 19 / 1000) = 41 / 1000 := by norm_num
-- The spread today: 4.10% - 4.00% = 10 bp, the same as €STR minus the implied rate.
example : (41 : ℚ) / 1000 - 4 / 100 = 1 / 1000 ∧ (2 : ℚ) / 100 - 19 / 1000 = 1 / 1000 := by
  norm_num
-- The collateral rate today: max(4.00%, 4.10%) = 4.00% + max(10 bp, 0) = 4.10%.
example : max ((4 : ℚ) / 100) (41 / 1000) = 4 / 100 + max (1 / 1000) 0 := by norm_num
-- Raw rates compared without the FX swap: max(2.00% - 4.00%, 0) = 0, the card's $0.00 mistake.
example : max ((2 : ℚ) / 100 - 4 / 100) 0 = 0 := by norm_num
-- d at one year: 10 bp over 15 bp is 2/3 (the card's 0.6667).
example : (10 : ℚ) / 15 = 2 / 3 := by norm_num
-- ColVA = 4,065,292.01 - 4,081,579.13 = -16,287.12 dollars.
example : (406529201 : ℤ) - 408157913 = -1628712 := by norm_num
-- Intrinsic part: 4,069,682.14 - 4,081,579.13 = -11,896.99; switch part: 4,065,292.01 - 4,069,682.14 = -4,390.13.
example : (406968214 : ℤ) - 408157913 = -1189699 ∧ (406529201 : ℤ) - 406968214 = -439013 := by
  norm_num
-- The two parts add up to ColVA.
example : (-1189699 : ℤ) + -439013 = -1628712 := by norm_num
-- The poster's saving on the first cash flow: 882,891.11 - 882,008.66 = 882.45 dollars.
example : (88289111 : ℤ) - 88200866 = 88245 := by norm_num

#print axioms ctd_discount_at_highest_rate
#print axioms poster_picks_highest_rate
#print axioms switch_rate_bachelier
