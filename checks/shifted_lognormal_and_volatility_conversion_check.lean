-- Shifted lognormal and volatility conversion: sliding the rate and the strike up by the same shift a turns a floor or cap into a Black-76 option on the slid pair, at the money the shifted premium matches the normal model's exactly when σN = G √(2π/T) [2N(w/2) - 1] = G σ R(w), and the shrink factor R(w) lies between 1 - w²/24 and 1 - w²/24 + w⁴/640.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open Real MeasureTheory ProbabilityTheory

/-! The model (The formula; Steps 1 and 2). `Z` is a standard bell-curve draw, the measure
`gaussianReal 0 1`, and `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`.
The rate quoted today is `F`, the strike `K`, the shift `a`; the slid pair is `G = F + a` and
`L = K + a`. The slid rate wanders lognormally with one constant volatility `σ` and no drift,
so after a wait `T` the fixing is `F_T = G e^(-w²/2 + w Z) - a` with `w = σ √T`.
The discount factor is `D = e^(-rT)`. -/

/-- The fixing on the appointed day in the shifted model: `F_T = (F + a) e^(-w²/2 + w z) - a`,
with one wiggle unit `w = σ √T`. -/
noncomputable def shiftedFixing (F a σ T z : ℝ) : ℝ :=
  (F + a) * exp (-(σ * √T) ^ 2 / 2 + σ * √T * z) - a

/-- The first cut-off `d₁ = (ln(G/L) + w²/2) / w` on the slid pair `G = F + a`, `L = K + a`;
the second is `d₂ = d₁ - w`. -/
noncomputable def shiftedD1 (F K a σ T : ℝ) : ℝ :=
  (log ((F + a) / (K + a)) + (σ * √T) ^ 2 / 2) / (σ * √T)

/-- The shrink factor `R(w) = ∫₀¹ e^(-w²u²/8) du`. -/
noncomputable def shrinkFactor (w : ℝ) : ℝ :=
  ∫ u in (0 : ℝ)..1, exp (-(w ^ 2 * u ^ 2 / 8))

/-! Helper lemmas. `φ` below is `gaussianPDFReal 0 1`, the standard bell-curve density. -/

lemma sl_pdf_eq (z : ℝ) :
    gaussianPDFReal 0 1 z = (√(2 * π))⁻¹ * exp (-z ^ 2 / 2) := by
  simp [gaussianPDFReal]

#print axioms sl_pdf_eq

lemma sl_pdf_neg (z : ℝ) : gaussianPDFReal 0 1 (-z) = gaussianPDFReal 0 1 z := by
  simp [sl_pdf_eq]

#print axioms sl_pdf_neg

lemma sl_pdf_continuous : Continuous (gaussianPDFReal 0 1) := by
  have : gaussianPDFReal 0 1 = fun z : ℝ => (√(2 * π))⁻¹ * exp (-z ^ 2 / 2) := by
    funext z; exact sl_pdf_eq z
  rw [this]; fun_prop

#print axioms sl_pdf_continuous

lemma sl_cdf_eq (z : ℝ) :
    cdf (gaussianReal 0 1) z = ∫ t in Set.Iic z, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (integral_nonneg fun t => gaussianPDFReal_nonneg _ _ _)]

#print axioms sl_cdf_eq

lemma sl_cdf_neg (z : ℝ) :
    cdf (gaussianReal 0 1) (-z) = 1 - cdf (gaussianReal 0 1) z := by
  have : NullSingletonClass (gaussianReal 0 1) :=
    nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [cdf_eq_real, cdf_eq_real]
  have hneg : gaussianReal 0 1 = (gaussianReal 0 1).map (fun x : ℝ ↦ -x) := by
    rw [gaussianReal_map_neg, neg_zero]
  conv_lhs => rw [hneg]
  rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
  have h1 : (fun x : ℝ ↦ -x) ⁻¹' Set.Iic (-z) = Set.Ici z := by
    ext x; simp
  rw [h1, ← measureReal_congr (Ioi_ae_eq_Ici' (measure_singleton z)), ← Set.compl_Iic,
    probReal_compl_eq_one_sub measurableSet_Iic]

#print axioms sl_cdf_neg

lemma sl_cdf_zero : cdf (gaussianReal 0 1) 0 = 1 / 2 := by
  have h := sl_cdf_neg 0
  rw [neg_zero] at h
  linarith

#print axioms sl_cdf_zero

/-- The upper tail of a slid bell curve: `∫_{z ≥ c} φ(z - μ) dz = N(μ - c)`. -/
lemma sl_tail (μ c : ℝ) :
    ∫ z in Set.Ici c, gaussianPDFReal 0 1 (z - μ) = cdf (gaussianReal 0 1) (μ - c) := by
  have h1 : ∫ z in Set.Ici c, gaussianPDFReal 0 1 (z - μ) =
      ∫ y in Set.Ici (c - μ), gaussianPDFReal 0 1 y := by
    rw [← integral_indicator measurableSet_Ici, ← integral_indicator measurableSet_Ici,
      ← integral_sub_right_eq_self (fun y => (Set.Ici (c - μ)).indicator (gaussianPDFReal 0 1) y) μ]
    congr 1; ext z
    simp only [Set.indicator, Set.mem_Ici]
    split_ifs with h h' h' <;> first | rfl | (exfalso; linarith)
  rw [h1, integral_Ici_eq_integral_Ioi, sl_cdf_eq, show μ - c = -(c - μ) by ring,
    ← integral_comp_neg_Ioi]
  simp_rw [sl_pdf_neg]

#print axioms sl_tail

/-- The call on a lognormal draw: `E[(G e^(-w²/2 + wZ) - L)⁺] = G N(d) - L N(d - w)`. -/
lemma sl_call (G L w : ℝ) (hG : 0 < G) (hL : 0 < L) (hw : 0 < w) :
    ∫ z, max (G * exp (-w ^ 2 / 2 + w * z) - L) 0 ∂(gaussianReal 0 1) =
      G * cdf (gaussianReal 0 1) ((log (G / L) + w ^ 2 / 2) / w) -
        L * cdf (gaussianReal 0 1) ((log (G / L) + w ^ 2 / 2) / w - w) := by
  set d := (log (G / L) + w ^ 2 / 2) / w with hd
  set c := w - d with hc
  have hwc : w * c = w ^ 2 / 2 - log G + log L := by
    rw [hc, hd, log_div hG.ne' hL.ne']; field_simp; ring
  have key : ∀ z, c ≤ z ↔ L ≤ G * exp (-w ^ 2 / 2 + w * z) := by
    intro z
    rw [← div_le_iff₀' hG, ← exp_log (div_pos hL hG), exp_le_exp, log_div hL.ne' hG.ne']
    constructor
    · intro h; nlinarith [mul_le_mul_of_nonneg_left h hw.le]
    · intro h; by_contra h'; nlinarith [mul_lt_mul_of_pos_left (not_le.mp h') hw]
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Set.Ici c)]
  swap
  · intro z hz
    simp only [Set.mem_Ici] at hz
    have : ¬ L ≤ G * exp (-w ^ 2 / 2 + w * z) := fun h => hz ((key z).2 h)
    rw [max_eq_right (by linarith), smul_zero]
  rw [setIntegral_congr_fun measurableSet_Ici
    (g := fun z => G * gaussianPDFReal 0 1 (z - w) - L * gaussianPDFReal 0 1 (z - 0))]
  swap
  · intro z hz
    have h := (key z).1 hz
    simp only [smul_eq_mul]
    rw [max_eq_left (by linarith), sub_zero]; simp only [sl_pdf_eq]
    have he : exp (-(z - w) ^ 2 / 2) = exp (-z ^ 2 / 2) * exp (-w ^ 2 / 2 + w * z) := by
      rw [← exp_add]; ring_nf
    rw [he]; ring
  have hi : ∀ m : ℝ, Integrable (fun z => gaussianPDFReal 0 1 (z - m)) :=
    fun m => (integrable_gaussianPDFReal 0 1).comp_sub_right m
  rw [integral_sub ((hi w).const_mul G).integrableOn ((hi 0).const_mul L).integrableOn,
    integral_const_mul, integral_const_mul, sl_tail, sl_tail]
  congr 3 <;> simp only [hc] <;> ring

#print axioms sl_call

/-- The average of the lognormal factor is one: `E[e^(-w²/2 + wZ)] = 1`. -/
lemma sl_mean_one (w : ℝ) :
    ∫ z, exp (-w ^ 2 / 2 + w * z) ∂(gaussianReal 0 1) = 1 := by
  have h := congrFun (mgf_id_gaussianReal (μ := 0) (v := 1)) w
  simp only [mgf, id] at h
  simp_rw [exp_add]
  rw [integral_const_mul, h]
  rw [← exp_add]; simp; ring_nf

#print axioms sl_mean_one

/-- The floor on a lognormal draw, by put-call parity. -/
lemma sl_put (G L w : ℝ) (hG : 0 < G) (hL : 0 < L) (hw : 0 < w) :
    ∫ z, max (L - G * exp (-w ^ 2 / 2 + w * z)) 0 ∂(gaussianReal 0 1) =
      L * cdf (gaussianReal 0 1) (-((log (G / L) + w ^ 2 / 2) / w - w)) -
        G * cdf (gaussianReal 0 1) (-((log (G / L) + w ^ 2 / 2) / w)) := by
  have hX : Integrable (fun z => G * exp (-w ^ 2 / 2 + w * z) - L) (gaussianReal 0 1) := by
    have : Integrable (fun z => exp (-w ^ 2 / 2 + w * z)) (gaussianReal 0 1) := by
      simp_rw [exp_add]
      exact (integrable_exp_mul_gaussianReal w).const_mul _
    exact (this.const_mul G).sub (integrable_const L)
  have hpt : ∀ z, max (L - G * exp (-w ^ 2 / 2 + w * z)) 0 =
      max (G * exp (-w ^ 2 / 2 + w * z) - L) 0 - (G * exp (-w ^ 2 / 2 + w * z) - L) := by
    intro z
    rcases le_total (G * exp (-w ^ 2 / 2 + w * z)) L with h | h
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
  simp_rw [hpt]
  rw [integral_sub hX.pos_part hX, sl_call G L w hG hL hw, integral_sub
    ((Integrable.const_mul (by simp_rw [exp_add]; exact
      (integrable_exp_mul_gaussianReal w).const_mul _) G)) (integrable_const L),
    integral_const_mul, sl_mean_one, sl_cdf_neg, sl_cdf_neg]
  simp
  ring

#print axioms sl_put

lemma sl_pdf_hasDerivAt (z : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-z * gaussianPDFReal 0 1 z) z := by
  have h1 : HasDerivAt (fun x : ℝ => -x ^ 2 / 2) (-(2 * z) / 2) z := by
    convert ((hasDerivAt_pow 2 z).neg).div_const 2 using 1
    simp
  have h := (h1.exp).const_mul (√(2 * π))⁻¹
  have hf : gaussianPDFReal 0 1 = fun z : ℝ => (√(2 * π))⁻¹ * exp (-z ^ 2 / 2) := by
    funext z; exact sl_pdf_eq z
  rw [hf]
  convert h using 1
  ring

#print axioms sl_pdf_hasDerivAt

lemma sl_pdf_tendsto_atBot : Filter.Tendsto (gaussianPDFReal 0 1) Filter.atBot (nhds 0) := by
  have hf : gaussianPDFReal 0 1 = fun z : ℝ => (√(2 * π))⁻¹ * exp (-z ^ 2 / 2) := by
    funext z; exact sl_pdf_eq z
  rw [hf]
  have h2 : Filter.Tendsto (fun y : ℝ => y ^ 2 / 2) Filter.atTop Filter.atTop :=
    (Filter.tendsto_pow_atTop two_ne_zero).atTop_div_const (by norm_num)
  have h3 : Filter.Tendsto (fun x : ℝ => -x ^ 2 / 2) Filter.atBot Filter.atBot := by
    have := Filter.tendsto_neg_atTop_atBot.comp (h2.comp Filter.tendsto_neg_atBot_atTop)
    refine this.congr ?_
    intro x; simp [Function.comp, neg_div]
  have h4 := (Real.tendsto_exp_atBot.comp h3).const_mul (√(2 * π))⁻¹
  simpa using h4

#print axioms sl_pdf_tendsto_atBot

lemma sl_integrable_mul_pdf : Integrable (fun t : ℝ => t * gaussianPDFReal 0 1 t) := by
  have h := (integrable_mul_exp_neg_mul_sq (b := 1 / 2) (by norm_num)).const_mul
    (√(2 * π))⁻¹
  refine h.congr (Filter.Eventually.of_forall fun x => ?_)
  simp only [sl_pdf_eq]
  ring_nf

#print axioms sl_integrable_mul_pdf

lemma sl_integral_Iic_mul_pdf (z : ℝ) :
    ∫ t in Set.Iic z, t * gaussianPDFReal 0 1 t = -gaussianPDFReal 0 1 z := by
  have := integral_Iic_of_hasDerivAt_of_tendsto' (a := z) (m := 0)
    (f := fun x => -gaussianPDFReal 0 1 x) (f' := fun t => t * gaussianPDFReal 0 1 t)
    (fun x _ => by
      convert (sl_pdf_hasDerivAt x).neg using 1
      ring)
    sl_integrable_mul_pdf.integrableOn
    (by simpa using sl_pdf_tendsto_atBot.neg)
  simpa using this

#print axioms sl_integral_Iic_mul_pdf

/-- The normal model at the money: `E[(s Z)⁺] = s / √(2π)` for `s > 0`. -/
lemma sl_normal_side (s : ℝ) (hs : 0 < s) :
    ∫ z, max (s * z) 0 ∂(gaussianReal 0 1) = s / √(2 * π) := by
  have hpt : ∀ z : ℝ, max (s * z) 0 = s * max (0 - (-z)) 0 := by
    intro z
    rcases le_total z 0 with h | h
    · rw [max_eq_right (by nlinarith), max_eq_right (by linarith)]; ring
    · rw [max_eq_left (by nlinarith), max_eq_left (by linarith)]; ring
  simp_rw [hpt]
  rw [integral_const_mul, integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hneg := integral_neg_eq_self
    (fun t : ℝ => gaussianPDFReal 0 1 t • max (0 - t) 0) (volume : Measure ℝ)
  simp only [sl_pdf_neg] at hneg
  rw [hneg]
  rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Set.Iic 0)]
  swap
  · intro t ht
    simp only [Set.mem_Iic, not_le] at ht
    rw [max_eq_right (by linarith), smul_zero]
  rw [setIntegral_congr_fun measurableSet_Iic (g := fun t => -(t * gaussianPDFReal 0 1 t))]
  swap
  · intro t ht
    simp only [Set.mem_Iic] at ht
    simp only [smul_eq_mul]
    rw [max_eq_left (by linarith)]
    ring
  rw [integral_neg, sl_integral_Iic_mul_pdf, sl_pdf_eq]
  simp
  ring

#print axioms sl_normal_side

/-- The shrink identity: `2 N(w/2) - 1 = (w / √(2π)) R(w)`. -/
lemma sl_shrink (w : ℝ) :
    2 * cdf (gaussianReal 0 1) (w / 2) - 1 = w / √(2 * π) * shrinkFactor w := by
  rcases eq_or_ne w 0 with rfl | hw
  · simp [sl_cdf_zero]
  have hint : ∀ a : ℝ, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) := fun a =>
    (integrable_gaussianPDFReal 0 1).integrableOn
  have h1 : cdf (gaussianReal 0 1) (w / 2) - cdf (gaussianReal 0 1) 0 =
      ∫ t in (0 : ℝ)..(w / 2), gaussianPDFReal 0 1 t := by
    rw [sl_cdf_eq, sl_cdf_eq, intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint _)]
  have h2 : shrinkFactor w = √(2 * π) * ∫ u in (0 : ℝ)..1, gaussianPDFReal 0 1 (w / 2 * u) := by
    rw [shrinkFactor, ← intervalIntegral.integral_const_mul]
    congr 1; ext u
    rw [sl_pdf_eq, ← mul_assoc, mul_inv_cancel₀ (by positivity), one_mul]
    congr 1; ring
  have h3 := intervalIntegral.integral_comp_mul_left (a := 0) (b := 1)
    (gaussianPDFReal 0 1) (c := w / 2) (div_ne_zero hw two_ne_zero)
  simp only [mul_zero, mul_one, smul_eq_mul] at h3
  rw [h2, h3, ← h1, sl_cdf_zero]
  have : 0 < √(2 * π) := by positivity
  field_simp

#print axioms sl_shrink

/-- For `x ≥ 0`: `1 - x ≤ e^(-x) ≤ 1 - x + x²/2`. -/
lemma sl_exp_neg_le (x : ℝ) (hx : 0 ≤ x) : exp (-x) ≤ 1 - x + x ^ 2 / 2 := by
  have h1 := quadratic_le_exp_of_nonneg hx
  have h2 : 0 < 1 - x + x ^ 2 / 2 := by nlinarith [sq_nonneg (x - 1)]
  rw [exp_neg, inv_le_iff_one_le_mul₀ (exp_pos x)]
  nlinarith [mul_le_mul_of_nonneg_right h1 h2.le, sq_nonneg (x ^ 2)]

#print axioms sl_exp_neg_le
/-- **The shifted premium** (The formula; Step 2 and its detailed proof). Let the slid rate
wander lognormally with one constant volatility `σ > 0` over a wait `T > 0`, so the fixing is
`F_T = G e^(-w²/2 + w Z) - a` with `w = σ√T`, and let both slid numbers be above zero:
`G = F + a > 0` and `L = K + a > 0`. Then the call on the rate, `D` times the average of
`(F_T - K)⁺`, is `D [G N(d₁) - L N(d₂)]`, and the floor, `D` times the average of `(K - F_T)⁺`,
is `D [L N(-d₂) - G N(-d₁)]`: Black-76 on the slid pair, nothing else touched. -/
theorem shifted_lognormal_premium_is_black76_on_slid_pair (F K a r σ T : ℝ)
    (hG : 0 < F + a) (hL : 0 < K + a) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-(r * T)) * ∫ z, max (shiftedFixing F a σ T z - K) 0 ∂(gaussianReal 0 1) =
        exp (-(r * T)) *
          ((F + a) * cdf (gaussianReal 0 1) (shiftedD1 F K a σ T) -
            (K + a) * cdf (gaussianReal 0 1) (shiftedD1 F K a σ T - σ * √T)) ∧
      exp (-(r * T)) * ∫ z, max (K - shiftedFixing F a σ T z) 0 ∂(gaussianReal 0 1) =
        exp (-(r * T)) *
          ((K + a) * cdf (gaussianReal 0 1) (-(shiftedD1 F K a σ T - σ * √T)) -
            (F + a) * cdf (gaussianReal 0 1) (-shiftedD1 F K a σ T)) := by
  have hw : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have e1 : ∀ z, shiftedFixing F a σ T z - K =
      (F + a) * exp (-(σ * √T) ^ 2 / 2 + σ * √T * z) - (K + a) := by
    intro z; unfold shiftedFixing; ring
  have e2 : ∀ z, K - shiftedFixing F a σ T z =
      (K + a) - (F + a) * exp (-(σ * √T) ^ 2 / 2 + σ * √T * z) := by
    intro z; unfold shiftedFixing; ring
  simp_rw [e1, e2]
  rw [sl_call _ _ _ hG hL hw, sl_put _ _ _ hG hL hw]
  exact ⟨rfl, rfl⟩

/-- **The exact conversion at the money** (The formula; Step 4 and its detailed proof). At the
money, strike equal to the rate `F`, with the slid rate `G = F + a > 0`, volatility `σ > 0`,
wait `T > 0` and a normal volatility `σN > 0`: the shifted premium, `D` times the average of
`(F_T - F)⁺`, equals the normal model's premium, `D` times the average of `(σN √T Z)⁺`,
exactly when `σN = G √(2π/T) [2N(w/2) - 1]`; and that conversion equals `G σ R(w)`, with
`w = σ√T` and `R(w) = ∫₀¹ e^(-w²u²/8) du`. -/
theorem atm_normal_volatility_conversion (F a r σ σN T : ℝ)
    (hG : 0 < F + a) (hσ : 0 < σ) (hT : 0 < T) (hσN : 0 < σN) :
    (exp (-(r * T)) * ∫ z, max (shiftedFixing F a σ T z - F) 0 ∂(gaussianReal 0 1) =
        exp (-(r * T)) * ∫ z, max (F + σN * √T * z - F) 0 ∂(gaussianReal 0 1) ↔
      σN = (F + a) * √(2 * π / T) * (2 * cdf (gaussianReal 0 1) (σ * √T / 2) - 1)) ∧
    (F + a) * √(2 * π / T) * (2 * cdf (gaussianReal 0 1) (σ * √T / 2) - 1) =
      (F + a) * σ * shrinkFactor (σ * √T) := by
  have hsT : 0 < √T := sqrt_pos.2 hT
  have hw : 0 < σ * √T := mul_pos hσ hsT
  have hpi : 0 < √(2 * π) := by positivity
  have e1 : ∀ z, shiftedFixing F a σ T z - F =
      (F + a) * exp (-(σ * √T) ^ 2 / 2 + σ * √T * z) - (F + a) := by
    intro z; unfold shiftedFixing; ring
  have e2 : ∀ z, F + σN * √T * z - F = σN * √T * z := by intro z; ring
  simp_rw [e1, e2]
  rw [sl_call _ _ _ hG hG hw, sl_normal_side _ (mul_pos hσN hsT), div_self hG.ne', log_one,
    zero_add]
  have hd : (σ * √T) ^ 2 / 2 / (σ * √T) = σ * √T / 2 := by field_simp
  have hd2 : σ * √T / 2 - σ * √T = -(σ * √T / 2) := by ring
  rw [hd, hd2, sl_cdf_neg, sqrt_div' _ hT.le]
  refine ⟨?_, ?_⟩
  · rw [mul_right_inj' (exp_pos _).ne']
    generalize cdf (gaussianReal 0 1) (σ * √T / 2) = N
    constructor
    · intro h
      field_simp at h ⊢
      linarith
    · intro h
      rw [h]
      field_simp
      ring
  · rw [sl_shrink]
    field_simp

/-- **The rule of thumb and its error** (Step 4, detailed proof). For every wiggle unit `w`,
the shrink factor is `R(w) = 1 - w²/24 + ε` with `0 ≤ ε ≤ w⁴/640`; and `R(w)` sits above zero,
and strictly below one when `w ≠ 0`, so multiplying `G σ` always overstates the absolute wobble. -/
theorem shrink_factor_series_bound (w : ℝ) :
    1 - w ^ 2 / 24 ≤ shrinkFactor w ∧
      shrinkFactor w ≤ 1 - w ^ 2 / 24 + w ^ 4 / 640 ∧
      0 < shrinkFactor w ∧
      (w ≠ 0 → shrinkFactor w < 1) := by
  have hc : Continuous (fun u : ℝ => exp (-(w ^ 2 * u ^ 2 / 8))) := by fun_prop
  have hlow : ∀ u : ℝ, 1 - w ^ 2 * u ^ 2 / 8 ≤ exp (-(w ^ 2 * u ^ 2 / 8)) := by
    intro u; linarith [add_one_le_exp (-(w ^ 2 * u ^ 2 / 8))]
  have hup : ∀ u : ℝ, exp (-(w ^ 2 * u ^ 2 / 8)) ≤
      1 - w ^ 2 * u ^ 2 / 8 + w ^ 4 * u ^ 4 / 128 := by
    intro u
    have := sl_exp_neg_le (w ^ 2 * u ^ 2 / 8) (by positivity)
    nlinarith
  have ii : ∀ f : ℝ → ℝ, Continuous f → IntervalIntegrable f volume 0 1 :=
    fun f hf => hf.intervalIntegrable _ _
  have i1 : ∫ u in (0 : ℝ)..1, (1 - w ^ 2 * u ^ 2 / 8) = 1 - w ^ 2 / 24 := by
    rw [intervalIntegral.integral_sub (ii _ (by fun_prop)) (ii _ (by fun_prop)),
      intervalIntegral.integral_div, intervalIntegral.integral_const_mul]
    simp
    ring
  have i2 : ∫ u in (0 : ℝ)..1, (1 - w ^ 2 * u ^ 2 / 8 + w ^ 4 * u ^ 4 / 128) =
      1 - w ^ 2 / 24 + w ^ 4 / 640 := by
    rw [intervalIntegral.integral_add (ii _ (by fun_prop)) (ii _ (by fun_prop)),
      intervalIntegral.integral_sub (ii _ (by fun_prop)) (ii _ (by fun_prop)),
      intervalIntegral.integral_div, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_div, intervalIntegral.integral_const_mul]
    simp
    ring
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [← i1, shrinkFactor]
    exact intervalIntegral.integral_mono_on zero_le_one (ii _ (by fun_prop)) (ii _ hc)
      (fun u _ => hlow u)
  · rw [← i2, shrinkFactor]
    exact intervalIntegral.integral_mono_on zero_le_one (ii _ hc)
      (ii _ (by fun_prop)) (fun u _ => hup u)
  · rw [shrinkFactor]
    exact intervalIntegral.intervalIntegral_pos_of_pos_on (ii _ hc)
      (fun u _ => exp_pos _) zero_lt_one
  · intro hw
    rw [shrinkFactor]
    refine lt_of_lt_of_eq
      (intervalIntegral.integral_lt_integral_of_continuousOn_of_le_of_exists_lt
        (g := fun _ => (1 : ℝ)) zero_lt_one hc.continuousOn continuousOn_const ?_ ?_) (by simp)
    · intro u _
      rw [exp_le_one_iff]
      have : 0 ≤ w ^ 2 * u ^ 2 / 8 := by positivity
      linarith
    · refine ⟨1, ⟨zero_le_one, le_refl _⟩, ?_⟩
      rw [exp_lt_one_iff]
      have : 0 < w ^ 2 := by positivity
      linarith

/-! The card's whole-number worked steps, rates in basis points. -/

-- The slid pair: G = 50 + 200 = 250, L = 50 + 200 = 250 at the money, L = 0 + 200 = 200 for the floor.
example : (50 : ℤ) + 200 = 250 ∧ (0 : ℤ) + 200 = 200 := by norm_num
-- Step 0: a fixing of -30 bp against a strike of 0 pays 30 bp; slid by 200 bp,
-- 170 against 200 also pays 30 bp.
example : max ((0 : ℤ) - (-30)) 0 = 30 ∧ max ((200 : ℤ) - (-30 + 200)) 0 = 30 := by norm_num
-- At the money d₁ = (0 + 0.3²/2) / 0.3 = 0.15 and d₂ = 0.15 - 0.3 = -0.15.
example : ((0 : ℚ) + (3 / 10) ^ 2 / 2) / (3 / 10) = 3 / 20 ∧
    (3 : ℚ) / 20 - 3 / 10 = -3 / 20 := by norm_num
-- The drag: up 50 percent then down 50 percent leaves the total down 25 percent.
example : (3 : ℚ) / 2 * (1 / 2) = 3 / 4 := by norm_num
-- The napkin rule G σ = 250 × 0.30 = 75 bp, corrected by (1 - w²/24) to 74.71875 bp.
example : (250 : ℚ) * (3 / 10) = 75 ∧
    (250 : ℚ) * (3 / 10) * (1 - (3 / 10) ^ 2 / 24) = 7471875 / 100000 := by norm_num

#print axioms shifted_lognormal_premium_is_black76_on_slid_pair
#print axioms atm_normal_volatility_conversion
#print axioms shrink_factor_series_bound
