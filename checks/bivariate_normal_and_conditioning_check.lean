-- Bivariate normal: for a bivariate normal pair with correlation strictly between -1 and 1, the slice of the joint density at a fixed height, divided by its area, is a normal density in weight with mean on the straight line μ_W + ρ σ_W/σ_H (h - μ_H) and variance σ_W^2 (1 - ρ^2) at every height; height alone is normal, and the chance both are above average is 1/4 + arcsin(ρ)/(2π).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open Real MeasureTheory ProbabilityTheory

/-- The card's bivariate normal density, the height of the tilted bell over the point `(h, w)`.
Averages `μH`, `μW`, spreads `σH`, `σW`, correlation `ρ`. With standard scores
`x = (h - μH)/σH` and `y = (w - μW)/σW`, the tilted distance is
`Q = (x^2 - 2ρxy + y^2)/(1 - ρ^2)` and
`f(h, w) = 1/(2π σH σW √(1 - ρ^2)) · e^(-Q/2)`. -/
noncomputable def bivariateNormalPDF (μH μW σH σW ρ : ℝ) (h w : ℝ) : ℝ :=
  let x := (h - μH) / σH
  let y := (w - μW) / σW
  let Q := (x ^ 2 - 2 * ρ * x * y + y ^ 2) / (1 - ρ ^ 2)
  1 / (2 * π * σH * σW * √(1 - ρ ^ 2)) * exp (-Q / 2)

theorem bivariateNormalPDF_eq_mul
    (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW) (hρ : ρ ∈ Set.Ioo (-1 : ℝ) 1)
    (h w : ℝ) :
    bivariateNormalPDF μH μW σH σW ρ h w =
      gaussianPDFReal μH (σH ^ 2).toNNReal h *
      gaussianPDFReal (μW + ρ * (σW / σH) * (h - μH)) (σW ^ 2 * (1 - ρ ^ 2)).toNNReal w := by
  obtain ⟨h1, h2⟩ := hρ
  have hq : 0 < 1 - ρ ^ 2 := by nlinarith
  set c := √(1 - ρ ^ 2) with hc_def
  have hc : 0 < c := Real.sqrt_pos.2 hq
  have hc2 : c ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt hq.le
  simp only [bivariateNormalPDF, gaussianPDFReal]
  rw [Real.coe_toNNReal _ (by positivity), Real.coe_toNNReal _ (by positivity), ← hc2]
  have hs1 : √(2 * π * σH ^ 2) = √(2 * π) * σH := by
    rw [Real.sqrt_mul (by positivity), Real.sqrt_sq hσH.le]
  have hs2 : √(2 * π * (σW ^ 2 * c ^ 2)) = √(2 * π) * (σW * c) := by
    rw [Real.sqrt_mul (by positivity), ← mul_pow, Real.sqrt_sq (by positivity)]
  have hpi : √(2 * π) ^ 2 = 2 * π := Real.sq_sqrt (by positivity)
  have hpi0 : 0 < √(2 * π) := Real.sqrt_pos.2 (by positivity)
  rw [hs1, hs2, mul_mul_mul_comm, ← Real.exp_add]
  congr 1
  · rw [Real.sqrt_sq hc.le]
    field_simp
    rw [hpi]
  · congr 1
    field_simp
    linear_combination σW ^ 2 * (h - μH) ^ 2 * hc2

#print axioms bivariateNormalPDF_eq_mul

theorem integral_Ioi_mul_exp_neg_sq_div_two :
    ∫ r in Set.Ioi (0 : ℝ), r * exp (-r ^ 2 / 2) = 1 := by
  have hderiv : ∀ x ∈ Set.Ici (0 : ℝ),
      HasDerivAt (fun r : ℝ => -exp (-r ^ 2 / 2)) (x * exp (-x ^ 2 / 2)) x := by
    intro x _
    have := (((hasDerivAt_pow 2 x).neg).div_const 2).exp.neg
    convert this using 1
    simp
    ring
  have hlim : Filter.Tendsto (fun r : ℝ => -exp (-r ^ 2 / 2)) Filter.atTop (nhds 0) := by
    have h1 : Filter.Tendsto (fun r : ℝ => -r ^ 2 / 2) Filter.atTop Filter.atBot :=
      (Filter.tendsto_neg_atTop_atBot.comp (Filter.tendsto_pow_atTop two_ne_zero)).atBot_div_const
        (by norm_num)
    simpa using (tendsto_exp_atBot.comp h1).neg
  have := integral_Ioi_of_hasDerivAt_of_nonneg' hderiv (fun x hx => by
    have : (0 : ℝ) < x := hx
    positivity) hlim
  rw [this]
  simp

#print axioms integral_Ioi_mul_exp_neg_sq_div_two

theorem wedge_integral (ρ : ℝ) (hρ : ρ ∈ Set.Ioo (-1 : ℝ) 1) :
    ∫ q in {q : ℝ × ℝ | 0 < q.1 ∧ 0 < ρ * q.1 + √(1 - ρ ^ 2) * q.2},
        exp (-(q.1 ^ 2 + q.2 ^ 2) / 2) / (2 * π) = 1 / 4 + arcsin ρ / (2 * π) := by
  obtain ⟨h1, h2⟩ := hρ
  set c := √(1 - ρ ^ 2) with hc_def
  set α := arcsin ρ with hα_def
  have hα1 : -(π / 2) < α := Real.neg_pi_div_two_lt_arcsin.2 h1
  have hα2 : α < π / 2 := Real.arcsin_lt_pi_div_two.2 h2
  have hsα : sin α = ρ := Real.sin_arcsin h1.le h2.le
  have hcα : cos α = c := Real.cos_arcsin ρ
  have hW : MeasurableSet {q : ℝ × ℝ | 0 < q.1 ∧ 0 < ρ * q.1 + c * q.2} :=
    ((isOpen_lt continuous_const continuous_fst).inter
      (isOpen_lt continuous_const
        (show Continuous (fun q : ℝ × ℝ => ρ * q.1 + c * q.2) by fun_prop))).measurableSet
  have hS : MeasurableSet (Set.Ioi (0 : ℝ) ×ˢ Set.Ioo (-α) (π / 2)) :=
    measurableSet_Ioi.prod measurableSet_Ioo
  have key : ∀ p ∈ polarCoord.target,
      p.1 • ({q : ℝ × ℝ | 0 < q.1 ∧ 0 < ρ * q.1 + c * q.2}.indicator
        (fun q => exp (-(q.1 ^ 2 + q.2 ^ 2) / 2) / (2 * π)) (polarCoord.symm p)) =
      (Set.Ioi (0 : ℝ) ×ˢ Set.Ioo (-α) (π / 2)).indicator
        (fun p : ℝ × ℝ => p.1 * exp (-p.1 ^ 2 / 2) * (1 / (2 * π))) p := by
    rintro ⟨r, θ⟩ ⟨hr, hθ⟩
    simp only [Set.mem_Ioi] at hr
    simp only [Set.mem_Ioo] at hθ
    have hmem : (r * cos θ, r * sin θ) ∈ {q : ℝ × ℝ | 0 < q.1 ∧ 0 < ρ * q.1 + c * q.2} ↔
        (r, θ) ∈ Set.Ioi (0 : ℝ) ×ˢ Set.Ioo (-α) (π / 2) := by
      have e : ρ * (r * cos θ) + c * (r * sin θ) = r * sin (α + θ) := by
        rw [sin_add, hsα, hcα]; ring
      simp only [Set.mem_ofPred_eq, Set.mem_prod, Set.mem_Ioi, Set.mem_Ioo, e,
        mul_pos_iff_of_pos_left hr, hr, true_and]
      constructor
      · rintro ⟨hcos, hsin⟩
        have hlo : -(π / 2) < θ := by
          by_contra hcon
          push Not at hcon
          have : cos (-θ) ≤ 0 :=
            cos_nonpos_of_pi_div_two_le_of_le (by linarith) (by linarith)
          rw [cos_neg] at this
          linarith
        refine ⟨?_, ?_⟩
        · by_contra hcon
          push Not at hcon
          have : sin (α + θ) ≤ 0 :=
            sin_nonpos_of_nonpos_of_neg_pi_le (by linarith) (by linarith)
          linarith
        · by_contra hcon
          push Not at hcon
          have : cos θ ≤ 0 :=
            cos_nonpos_of_pi_div_two_le_of_le hcon (by linarith)
          linarith
      · rintro ⟨ha, hb⟩
        exact ⟨cos_pos_of_mem_Ioo ⟨by linarith, hb⟩, sin_pos_of_pos_of_lt_pi (by linarith)
          (by linarith)⟩
    rw [polarCoord_symm_apply]
    by_cases hin : (r, θ) ∈ Set.Ioi (0 : ℝ) ×ˢ Set.Ioo (-α) (π / 2)
    · rw [Set.indicator_of_mem (hmem.2 hin), Set.indicator_of_mem hin, smul_eq_mul]
      have : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 := by
        have := sin_sq_add_cos_sq θ
        linear_combination r ^ 2 * this
      simp only [this]
      ring
    · rw [Set.indicator_of_notMem (fun h => hin (hmem.1 h)), Set.indicator_of_notMem hin,
        smul_zero]
  have hinter : polarCoord.target ∩ (Set.Ioi (0 : ℝ) ×ˢ Set.Ioo (-α) (π / 2)) =
      Set.Ioi (0 : ℝ) ×ˢ Set.Ioo (-α) (π / 2) := by
    apply Set.inter_eq_right.2
    rintro ⟨r, θ⟩ ⟨hr, hθ⟩
    simp only [Set.mem_Ioo] at hθ
    refine ⟨hr, ?_, ?_⟩
    · show -π < θ
      linarith [pi_pos]
    · show θ < π
      linarith [pi_pos]
  rw [← integral_indicator hW, ← integral_comp_polarCoord_symm,
    setIntegral_congr_fun polarCoord.open_target.measurableSet key,
    setIntegral_indicator hS, hinter, Measure.volume_eq_prod,
    setIntegral_prod_mul (fun r : ℝ => r * exp (-r ^ 2 / 2)) (fun _ : ℝ => 1 / (2 * π)),
    integral_Ioi_mul_exp_neg_sq_div_two, integral_const, measureReal_restrict_apply_univ,
    volume_real_Ioo_of_le (by linarith), smul_eq_mul]
  field_simp
  ring

#print axioms wedge_integral

theorem quadrant_integral_eq_wedge_integral
    (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW) (hρ : ρ ∈ Set.Ioo (-1 : ℝ) 1) :
    ∫ p in {p : ℝ × ℝ | μH < p.1 ∧ μW < p.2}, bivariateNormalPDF μH μW σH σW ρ p.1 p.2 =
      ∫ q in {q : ℝ × ℝ | 0 < q.1 ∧ 0 < ρ * q.1 + √(1 - ρ ^ 2) * q.2},
        exp (-(q.1 ^ 2 + q.2 ^ 2) / 2) / (2 * π) := by
  obtain ⟨h1, h2⟩ := hρ
  have hq : 0 < 1 - ρ ^ 2 := by nlinarith
  set c := √(1 - ρ ^ 2) with hc_def
  have hc : 0 < c := Real.sqrt_pos.2 hq
  have hc2 : c ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt hq.le
  set W := {q : ℝ × ℝ | 0 < q.1 ∧ 0 < ρ * q.1 + c * q.2} with hW_def
  have hW : MeasurableSet W :=
    ((isOpen_lt continuous_const continuous_fst).inter (isOpen_lt continuous_const
        (show Continuous (fun q : ℝ × ℝ => ρ * q.1 + c * q.2) by fun_prop))).measurableSet
  let A : ℝ × ℝ → ℝ × ℝ := fun q => (μH + σH * q.1, μW + σW * (ρ * q.1 + c * q.2))
  let L : ℝ × ℝ →L[ℝ] ℝ × ℝ :=
    (Matrix.toLin (.finTwoProd ℝ) (.finTwoProd ℝ) !![σH, 0; σW * ρ, σW * c]).toContinuousLinearMap
  have hL : ∀ q, L q = (σH * q.1, σW * ρ * q.1 + σW * c * q.2) := by
    intro q
    simp [L, Matrix.toLin_finTwoProd_apply]
  have hA : ∀ q, HasFDerivAt A L q := by
    intro q
    have e : A = fun q => (μH, μW) + L q := by
      funext q
      rw [hL]
      ext <;> simp [A]
      ring
    rw [e]
    exact L.hasFDerivAt.const_add _
  have hdet : L.det = σH * σW * c := by
    simp only [L, LinearMap.det_toContinuousLinearMap, LinearMap.det_toLin,
      Matrix.det_fin_two_of]
    ring
  have hinj : Set.InjOn A W := by
    rintro ⟨a1, a2⟩ _ ⟨b1, b2⟩ _ hab
    simp only [A, Prod.mk.injEq] at hab
    obtain ⟨e1, e2⟩ := hab
    have k1 : a1 = b1 := by
      have := mul_left_cancel₀ hσH.ne' (add_left_cancel e1)
      exact this
    subst k1
    have := mul_left_cancel₀ hσW.ne' (add_left_cancel e2)
    have := mul_left_cancel₀ hc.ne' (add_left_cancel this)
    rw [this]
  have himage : A '' W = {p : ℝ × ℝ | μH < p.1 ∧ μW < p.2} := by
    ext ⟨p1, p2⟩
    constructor
    · rintro ⟨⟨q1, q2⟩, ⟨hq1, hq2⟩, he⟩
      simp only [A, Prod.mk.injEq] at he
      obtain ⟨rfl, rfl⟩ := he
      constructor
      · show μH < μH + σH * q1
        have := mul_pos hσH hq1
        linarith
      · show μW < μW + σW * (ρ * q1 + c * q2)
        have := mul_pos hσW hq2
        linarith
    · rintro ⟨hp1, hp2⟩
      simp only at hp1 hp2
      refine ⟨((p1 - μH) / σH, ((p2 - μW) / σW - ρ * ((p1 - μH) / σH)) / c), ⟨?_, ?_⟩, ?_⟩
      · exact div_pos (by linarith) hσH
      · show 0 < ρ * ((p1 - μH) / σH) + c * (((p2 - μW) / σW - ρ * ((p1 - μH) / σH)) / c)
        have : ρ * ((p1 - μH) / σH) + c * (((p2 - μW) / σW - ρ * ((p1 - μH) / σH)) / c) =
            (p2 - μW) / σW := by
          field_simp
          ring
        rw [this]
        exact div_pos (by linarith) hσW
      · simp only [A, Prod.mk.injEq]
        constructor
        · field_simp
          ring
        · field_simp
          ring
  rw [← himage, integral_image_eq_integral_abs_det_fderiv_smul volume hW
    (fun q _ => (hA q).hasFDerivWithinAt) hinj]
  refine setIntegral_congr_fun hW (fun q _ => ?_)
  rw [hdet, abs_of_pos (by positivity), smul_eq_mul]
  simp only [bivariateNormalPDF, A]
  rw [← hc_def]
  have ex : (μH + σH * q.1 - μH) / σH = q.1 := by field_simp; ring
  have ey : (μW + σW * (ρ * q.1 + c * q.2) - μW) / σW = ρ * q.1 + c * q.2 := by
    field_simp; ring
  have eQ : (q.1 ^ 2 - 2 * ρ * q.1 * (ρ * q.1 + c * q.2) + (ρ * q.1 + c * q.2) ^ 2) /
      (1 - ρ ^ 2) = q.1 ^ 2 + q.2 ^ 2 := by
    rw [div_eq_iff hq.ne']
    linear_combination (q.2 ^ 2) * hc2
  rw [ex, ey, eQ]
  field_simp

#print axioms quadrant_integral_eq_wedge_integral

theorem integral_bivariateNormalPDF_eq
    (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW) (hρ : ρ ∈ Set.Ioo (-1 : ℝ) 1)
    (h : ℝ) :
    ∫ w, bivariateNormalPDF μH μW σH σW ρ h w = gaussianPDFReal μH (σH ^ 2).toNNReal h := by
  simp_rw [bivariateNormalPDF_eq_mul μH μW σH σW ρ hσH hσW hρ h]
  rw [integral_const_mul, integral_gaussianPDFReal_eq_one, mul_one]
  obtain ⟨h1, h2⟩ := hρ
  have hq : 0 < 1 - ρ ^ 2 := by nlinarith
  intro h0
  rw [Real.toNNReal_eq_zero] at h0
  have : 0 < σW ^ 2 * (1 - ρ ^ 2) := by positivity
  linarith

#print axioms integral_bivariateNormalPDF_eq

/-- **Fixing one leaves the other normal, on a straight line, with a fixed spread.** For a
jointly normal pair (the bivariate normal density) with spreads `σH, σW > 0` and correlation
`ρ` strictly between -1 and 1: at every height `h`, the conditional density of weight, the
joint density divided by the density of height (the slice's area over all weights), is the
normal density with centre `μW + ρ (σW/σH) (h - μH)` and variance `σW^2 (1 - ρ^2)`.
The variance does not depend on `h`. -/
theorem conditional_of_bivariate_normal_is_normal_on_straight_line
    (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW) (hρ : ρ ∈ Set.Ioo (-1 : ℝ) 1)
    (h w : ℝ) :
    bivariateNormalPDF μH μW σH σW ρ h w / (∫ w', bivariateNormalPDF μH μW σH σW ρ h w') =
      gaussianPDFReal (μW + ρ * (σW / σH) * (h - μH)) (σW ^ 2 * (1 - ρ ^ 2)).toNNReal w := by
  rw [integral_bivariateNormalPDF_eq μH μW σH σW ρ hσH hσW hρ h,
    bivariateNormalPDF_eq_mul μH μW σH σW ρ hσH hσW hρ h w]
  have : 0 < gaussianPDFReal μH (σH ^ 2).toNNReal h :=
    gaussianPDFReal_pos _ _ _ (by simp [hσH.ne'])
  field_simp

/-- **Height alone is normal** (Step 3). Integrating the bivariate normal density over all
weights leaves the normal density of height, `N(μH, σH^2)`, whatever the correlation in
`(-1, 1)`. -/
theorem marginal_of_bivariate_normal_is_normal
    (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW) (hρ : ρ ∈ Set.Ioo (-1 : ℝ) 1)
    (h : ℝ) :
    ∫ w, bivariateNormalPDF μH μW σH σW ρ h w = gaussianPDFReal μH (σH ^ 2).toNNReal h := by
  exact integral_bivariateNormalPDF_eq μH μW σH σW ρ hσH hσW hρ h

/-- **Both above average** (Step 5). For the bivariate normal with correlation `ρ` in `(-1, 1)`,
the chance of being both taller and heavier than average, the volume under the density over
the quarter-plane `h > μH`, `w > μW`, is `1/4 + arcsin(ρ)/(2π)`. -/
theorem both_above_average_bivariate_normal
    (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW) (hρ : ρ ∈ Set.Ioo (-1 : ℝ) 1) :
    ∫ p in {p : ℝ × ℝ | μH < p.1 ∧ μW < p.2}, bivariateNormalPDF μH μW σH σW ρ p.1 p.2 =
      1 / 4 + arcsin ρ / (2 * π) := by
  rw [quadrant_integral_eq_wedge_integral μH μW σH σW ρ hσH hσW hρ, wedge_integral ρ hρ]

-- The card's adults: μH = 175 cm, σH = 7, μW = 75 kg, σW = 12, ρ = 1/2.
-- Height's standard score at 189 cm is 2.
example : ((189 : ℚ) - 175) / 7 = 2 := by norm_num
-- Average weight at 189 cm: 75 + (1/2)(12/7)(189 - 175) = 87 kg.
example : (75 : ℚ) + 1 / 2 * (12 / 7) * (189 - 175) = 87 := by norm_num
-- The slope is 6/7 kg per cm (0.857143), and the reverse slope 7/24 cm per kg (0.291667).
example : (1 / 2 : ℚ) * 12 / 7 = 6 / 7 ∧ (1 / 2 : ℚ) * 7 / 12 = 7 / 24 := by norm_num
-- Inverting the first slope instead gives 7/6 cm per kg (1.166667).
example : (7 : ℚ) / (1 / 2 * 12) = 7 / 6 := by norm_num
-- Covariance ρ σH σW = 42 cm·kg; covariance matrix entries 49, 42, 42, 144.
example : (1 / 2 : ℚ) * 7 * 12 = 42 ∧ (7 : ℚ) ^ 2 = 49 ∧ (12 : ℚ) ^ 2 = 144 := by norm_num
-- Variance split: 144 = ρ^2·144 + (1 - ρ^2)·144 = 36 + 108, with ρ^2 = 1/4.
example : (1 / 2 : ℚ) ^ 2 * 144 = 36 ∧ (1 - (1 / 2 : ℚ) ^ 2) * 144 = 108 ∧ (36 : ℚ) + 108 = 144 := by
  norm_num
-- Average height among 99 kg adults: 175 + (1/2)(7/12)(99 - 75) = 182 cm, not 189.
example : (175 : ℚ) + 1 / 2 * (7 / 12) * (99 - 75) = 182 := by norm_num
-- The full step without ρ: 75 + 12·2 = 99 kg.
example : (75 : ℚ) + 12 * 2 = 99 := by norm_num
-- The drawn ellipse: at x = 2, y = 1 the tilted distance is Q = 4.
example : ((2 : ℚ) ^ 2 - 2 * (1 / 2) * 2 * 1 + 1 ^ 2) / (1 - (1 / 2) ^ 2) = 4 := by norm_num
-- Ellipse ends: (175 ± 14, 75 ± 12) = (189, 87), (161, 63); (175 ± 7, 75 ± 24) = (182, 99), (168, 51).
example : ((175 : ℤ) + 7 * 2, (75 : ℤ) + 12 * 1) = (189, 87) ∧ ((175 : ℤ) - 7 * 2, (75 : ℤ) - 12 * 1) = (161, 63) ∧
    ((175 : ℤ) + 7 * 1, (75 : ℤ) + 12 * 2) = (182, 99) ∧ ((175 : ℤ) - 7 * 1, (75 : ℤ) - 12 * 2) = (168, 51) := by
  decide
-- Short adults at 161 cm with ρ = 1/2 and tall adults at 189 cm with ρ = -1/2 both average 63 kg.
example : (75 : ℚ) + 1 / 2 * (12 / 7) * (161 - 175) = 63 ∧
    (75 : ℚ) + (-1 / 2) * (12 / 7) * (189 - 175) = 63 := by norm_num
-- The flip pair: 75 + 12·2 = 99 kg at 189 cm; 75 - 12·(5/2) = 45 kg at 192.5 cm, where the
-- line says 75 + (1/2)(12/7)(35/2) = 90 kg.
example : (75 : ℚ) - 12 * (5 / 2) = 45 ∧ (75 : ℚ) + 1 / 2 * (12 / 7) * (385 / 2 - 175) = 90 := by
  norm_num
-- Both above average at ρ = 1/2: 1/4 + arcsin(1/2)/(2π) = 1/3.
example : 1 / 4 + arcsin (1 / 2) / (2 * π) = 1 / 3 := by
  rw [arcsin_eq_of_sin_eq sin_pi_div_six ⟨by linarith [pi_pos], by linarith [pi_pos]⟩]
  field_simp
  ring

#print axioms conditional_of_bivariate_normal_is_normal_on_straight_line
#print axioms marginal_of_bivariate_normal_is_normal
#print axioms both_above_average_bivariate_normal
