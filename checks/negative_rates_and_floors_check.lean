-- Negative rates: a floored coupon is the plain coupon plus a put struck at the floor, the normal model's floorlet has a closed form, and a shifted lognormal model can match the normal at-the-money price exactly when the shift clears a minimum.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF

open MeasureTheory ProbabilityTheory Real

section Helpers

open Set Filter Topology

lemma stdPDF_eq (z : ℝ) :
    gaussianPDFReal 0 1 z = (√(2 * π))⁻¹ * rexp (-(1/2) * z ^ 2) := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  congr 2; ring

lemma continuous_stdPDF : Continuous (gaussianPDFReal 0 1) := by
  have : gaussianPDFReal 0 1 = fun z => (√(2 * π))⁻¹ * rexp (-(1/2) * z ^ 2) :=
    funext stdPDF_eq
  rw [this]; fun_prop

lemma integrable_stdPDF : Integrable (gaussianPDFReal 0 1) :=
  integrable_gaussianPDFReal 0 1

lemma cdf_std_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma hasDerivAt_cdf_std (x : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 x) x := by
  have h : cdf (gaussianReal 0 1) =
      fun y => cdf (gaussianReal 0 1) 0 + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [cdf_std_eq_integral, cdf_std_eq_integral,
      ← intervalIntegral.integral_Iic_sub_Iic integrable_stdPDF.integrableOn
        integrable_stdPDF.integrableOn]
    ring
  rw [h]
  exact (intervalIntegral.integral_hasDerivAt_right
    (continuous_stdPDF.intervalIntegrable _ _)
    (continuous_stdPDF.stronglyMeasurableAtFilter _ _)
    continuous_stdPDF.continuousAt).const_add _

lemma strictMono_cdf_std : StrictMono (cdf (gaussianReal 0 1)) :=
  strictMono_of_deriv_pos fun x => by
    rw [(hasDerivAt_cdf_std x).deriv]
    exact gaussianPDFReal_pos _ _ _ one_ne_zero

lemma continuous_cdf_std : Continuous (cdf (gaussianReal 0 1)) :=
  continuous_iff_continuousAt.2 fun x => (hasDerivAt_cdf_std x).continuousAt

lemma cdf_std_zero : cdf (gaussianReal 0 1) 0 = 1 / 2 := by
  have hsym : ∀ z, gaussianPDFReal 0 1 (-z) = gaussianPDFReal 0 1 z := by
    intro z; simp [stdPDF_eq]
  have h1 : ∫ t in Iic (0:ℝ), gaussianPDFReal 0 1 t = ∫ t in Ioi (0:ℝ), gaussianPDFReal 0 1 t := by
    have := integral_comp_neg_Iic (0:ℝ) (gaussianPDFReal 0 1)
    simpa only [hsym, neg_zero] using this
  have h2 := intervalIntegral.integral_Iic_add_Ioi (b := (0:ℝ))
    integrable_stdPDF.integrableOn integrable_stdPDF.integrableOn
  rw [integral_gaussianPDFReal_eq_one _ one_ne_zero] at h2
  rw [cdf_std_eq_integral]
  linarith

lemma cdf_std_lt_one (x : ℝ) : cdf (gaussianReal 0 1) x < 1 :=
  lt_of_lt_of_le (strictMono_cdf_std (lt_add_one x)) (cdf_le_one _ _)

lemma hasDerivAt_neg_stdPDF (z : ℝ) :
    HasDerivAt (fun z => -gaussianPDFReal 0 1 z) (z * gaussianPDFReal 0 1 z) z := by
  have hf : (fun z => -gaussianPDFReal 0 1 z) =
      fun z => -((√(2 * π))⁻¹ * rexp (-(1/2) * z ^ 2)) := funext fun z => by rw [stdPDF_eq]
  rw [hf, stdPDF_eq]
  have h1 : HasDerivAt (fun z : ℝ => -(1/2) * z ^ 2) (-(1/2) * (2 * z)) z := by
    simpa using ((hasDerivAt_pow 2 z).const_mul (-(1/2) : ℝ))
  have h2 := ((h1.exp).const_mul (√(2 * π))⁻¹).neg
  convert h2 using 1
  ring

lemma tendsto_neg_stdPDF_atBot :
    Tendsto (fun z => -gaussianPDFReal 0 1 z) atBot (𝓝 0) := by
  have h1 : Tendsto (fun z : ℝ => -(1/2) * z ^ 2) atBot atBot := by
    have : Tendsto (fun z : ℝ => z ^ 2) atBot atTop := by
      have := (tendsto_pow_atTop (two_ne_zero : (2:ℕ) ≠ 0)).comp (tendsto_neg_atBot_atTop (G := ℝ))
      simpa [Function.comp_def] using this
    exact this.const_mul_atTop_of_neg (by norm_num)
  have h2 := ((tendsto_exp_atBot.comp h1).const_mul (√(2 * π))⁻¹).neg
  simp only [mul_zero, neg_zero] at h2
  refine h2.congr fun z => ?_
  simp [stdPDF_eq]

lemma integral_Iic_mul_stdPDF (d : ℝ) :
    ∫ z in Iic d, z * gaussianPDFReal 0 1 z = -gaussianPDFReal 0 1 d := by
  have hint : Integrable (fun z => z * gaussianPDFReal 0 1 z) := by
    have := (integrable_mul_exp_neg_mul_sq (b := 1/2) (by norm_num)).const_mul (√(2 * π))⁻¹
    refine this.congr (ae_of_all _ fun z => ?_)
    simp only [stdPDF_eq]; ring_nf
  rw [integral_Iic_of_hasDerivAt_of_tendsto' (fun x _ => hasDerivAt_neg_stdPDF x)
    hint.integrableOn tendsto_neg_stdPDF_atBot]
  ring

end Helpers

#print axioms stdPDF_eq
#print axioms continuous_stdPDF
#print axioms integrable_stdPDF
#print axioms cdf_std_eq_integral
#print axioms hasDerivAt_cdf_std
#print axioms strictMono_cdf_std
#print axioms continuous_cdf_std
#print axioms cdf_std_zero
#print axioms cdf_std_lt_one
#print axioms hasDerivAt_neg_stdPDF
#print axioms tendsto_neg_stdPDF_atBot
#print axioms integral_Iic_mul_stdPDF

/-- The coupon split: at every fixing `L` and every strike `K`, the coupon floored at `K` equals
the plain coupon plus a floorlet (a put on the rate struck at `K`), and it also equals the strike
plus a caplet struck at `K` (with `K = 0`: the floored leg is a zero-strike cap). -/
theorem floored_coupon_eq_coupon_add_put (L K : ℝ) :
    max L K = L + max (K - L) 0 ∧ max L K = K + max (L - K) 0 := by
  constructor
  · rcases le_total L K with h | h
    · rw [max_eq_right h, max_eq_left (by linarith)]; ring
    · rw [max_eq_left h, max_eq_right (by linarith)]; ring
  · rcases le_total L K with h | h
    · rw [max_eq_right h, max_eq_right (by linarith)]; ring
    · rw [max_eq_left h, max_eq_left (by linarith)]; ring

/-- The normal model's floorlet: if the fixing is `F + w Z` with `Z` a standard bell-curve draw and
one wiggle unit `w > 0`, the average floorlet payoff `max (K - F - w Z) 0` is
`(K - F) N(d) + w φ(d)` with `d = (K - F) / w`. -/
theorem normal_floorlet_eq (F K w : ℝ) (hw : 0 < w) :
    ∫ z, max (K - F - w * z) 0 ∂(gaussianReal 0 1) =
      (K - F) * cdf (gaussianReal 0 1) ((K - F) / w) + w * gaussianPDFReal 0 1 ((K - F) / w) := by
  set d := (K - F) / w with hd
  have hKF : K - F = w * d := by rw [hd]; field_simp
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hpt : (fun z => gaussianPDFReal 0 1 z • max (K - F - w * z) 0) =
      (Set.Iic d).indicator (fun z => (K - F) * gaussianPDFReal 0 1 z -
        w * (z * gaussianPDFReal 0 1 z)) := by
    funext z
    by_cases hz : z ≤ d
    · rw [Set.indicator_of_mem (by exact hz), smul_eq_mul,
        max_eq_left (by rw [hKF]; nlinarith)]
      ring
    · rw [Set.indicator_of_notMem (by exact hz), smul_eq_mul,
        max_eq_right (by rw [hKF]; push Not at hz; nlinarith)]
      ring
  have hint : Integrable (fun z => z * gaussianPDFReal 0 1 z) := by
    have := (integrable_mul_exp_neg_mul_sq (b := 1/2) (by norm_num)).const_mul (√(2 * π))⁻¹
    refine this.congr (ae_of_all _ fun z => ?_)
    simp only [stdPDF_eq]; ring_nf
  rw [hpt, integral_indicator measurableSet_Iic,
    integral_sub (integrable_stdPDF.const_mul _).integrableOn
      (hint.const_mul _).integrableOn,
    integral_const_mul, integral_const_mul, integral_Iic_mul_stdPDF, ← cdf_std_eq_integral]
  ring

/-- The smallest shift: with normal volatility `σN > 0` and time to fixing `T > 0`, a shifted
lognormal volatility `σa > 0` whose at-the-money premium `(F + a) (2 N(σa √T / 2) - 1)` equals the
normal at-the-money premium `σN √(T / (2π))` exists, and is unique, exactly when
`a > -F + σN √(T / (2π))`. -/
theorem shifted_atm_match_exists_unique_iff (F a σN T : ℝ) (hσN : 0 < σN) (hT : 0 < T) :
    (∃! σa : ℝ, 0 < σa ∧
        (F + a) * (2 * cdf (gaussianReal 0 1) (σa * √T / 2) - 1) = σN * √(T / (2 * π))) ↔
      a > -F + σN * √(T / (2 * π)) := by
  set c := σN * √(T / (2 * π)) with hc
  have hcpos : 0 < c := mul_pos hσN (Real.sqrt_pos.2 (by positivity))
  have hs : 0 < √T := Real.sqrt_pos.2 hT
  set Φ := cdf (gaussianReal 0 1) with hΦ
  have hmono : StrictMono Φ := strictMono_cdf_std
  have hg_pos : ∀ σ, 0 < σ → 0 < 2 * Φ (σ * √T / 2) - 1 := by
    intro σ hσ
    have := hmono (show (0:ℝ) < σ * √T / 2 by positivity)
    rw [hΦ, cdf_std_zero] at this
    rw [hΦ]; linarith
  have hg_lt : ∀ σ, 2 * Φ (σ * √T / 2) - 1 < 1 := by
    intro σ; have := cdf_std_lt_one (σ * √T / 2); rw [hΦ]; linarith
  constructor
  · rintro ⟨σ, ⟨hσ, heq⟩, -⟩
    have hgp := hg_pos σ hσ
    have hgl := hg_lt σ
    have hFa : 0 < F + a := by
      by_contra h
      push Not at h
      have : (F + a) * (2 * Φ (σ * √T / 2) - 1) ≤ 0 :=
        mul_nonpos_of_nonpos_of_nonneg h hgp.le
      linarith
    have : (F + a) * (2 * Φ (σ * √T / 2) - 1) < F + a := by
      calc (F + a) * (2 * Φ (σ * √T / 2) - 1) < (F + a) * 1 :=
            mul_lt_mul_of_pos_left hgl hFa
        _ = F + a := mul_one _
    linarith
  · intro ha
    have hFa : 0 < F + a := by linarith
    set y := c / (F + a) with hy
    have hy0 : 0 < y := div_pos hcpos hFa
    have hy1 : y < 1 := (div_lt_one hFa).2 (by linarith)
    set t := (1 + y) / 2 with ht
    obtain ⟨M, hM⟩ : ∃ M, t < Φ M := by
      have := (tendsto_cdf_atTop (μ := gaussianReal 0 1)).eventually (lt_mem_nhds
        (show t < 1 by rw [ht]; linarith))
      exact this.exists
    have h0 : Φ 0 = 1 / 2 := cdf_std_zero
    have hM0 : 0 ≤ M := by
      by_contra h; push Not at h
      have := hmono h; rw [h0] at this; rw [ht] at hM; linarith
    obtain ⟨x, hx, hxt⟩ := intermediate_value_Icc hM0 continuous_cdf_std.continuousOn
      (show t ∈ Set.Icc (Φ 0) (Φ M) by
        rw [h0]; exact ⟨by rw [ht]; linarith, hM.le⟩)
    have hx0 : 0 < x := by
      rcases hx.1.eq_or_lt with h | h
      · rw [← h, h0, ht] at hxt; linarith
      · exact h
    have hsol : ∀ σ, 0 < σ ∧ (F + a) * (2 * Φ (σ * √T / 2) - 1) = c ↔
        0 < σ ∧ Φ (σ * √T / 2) = t := by
      intro σ
      constructor
      · rintro ⟨h1, h2⟩
        refine ⟨h1, ?_⟩
        rw [ht, hy]; field_simp; linarith
      · rintro ⟨h1, h2⟩
        refine ⟨h1, ?_⟩
        rw [h2, ht, hy]; field_simp; ring
    refine ⟨2 * x / √T, (hsol _).2 ⟨by positivity, ?_⟩, fun τ hτ => ?_⟩
    · rw [show 2 * x / √T * √T / 2 = x by field_simp]; exact hxt
    · obtain ⟨_, hτ2⟩ := (hsol τ).1 hτ
      have hinj := hmono.injective (hτ2.trans hxt.symm)
      field_simp
      linarith

-- Step 0, in basis points: a fixing of -30 bp floors to 0 = -30 + 30.
example : max (-30 : ℤ) 0 = -30 + max (0 - (-30)) 0 ∧ max (-30 : ℤ) 0 = 0 := by decide
-- Step 0, in basis points: a fixing of +20 bp floors to 20 = 20 + 0.
example : max (20 : ℤ) 0 = 20 + max (0 - 20) 0 ∧ max (20 : ℤ) 0 = 20 := by decide
-- Year 2: the strike sits (0 - (-50)) / 50 = 1 wiggle unit above the forward.
example : ((0 : ℚ) - (-50)) / 50 = 1 := by norm_num
-- One basis point on 10,000,000 dollars for one year is 1,000 dollars.
example : (10000000 : ℚ) / 10000 = 1000 := by norm_num
-- Floored leg in cents: plain leg -15,151,259 plus floor 16,585,364 is 1,434,105.
example : (-15151259 : ℤ) + 16585364 = 1434105 := by decide
-- Time value in cents: floor 16,585,364 minus intrinsic 15,151,259 is 1,434,105.
example : (16585364 : ℤ) - 15151259 = 1434105 := by decide

#print axioms floored_coupon_eq_coupon_add_put
#print axioms normal_floorlet_eq
#print axioms shifted_atm_match_exists_unique_iff
