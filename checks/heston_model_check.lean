-- The Heston model: the expected variance is pulled home to its long-run level at the rate set by the pull speed (which fixes the term structure), the Black-Scholes price bends in total variance by the factor (d1 d2 - 1)/(2w) that makes the vol of vol carve a smile, and the Feller condition is exactly when the scale function's slope cannot be integrated down to zero.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrability.Basic
import Mathlib.Analysis.Calculus.MeanValue

open MeasureTheory ProbabilityTheory Real Set

namespace HestonModel

/-! The model's numbers, as on the card: pull speed `κ`, long-run variance `θ`, today's variance
`v₀`, vol of vol `ξ`. The Black-Scholes call is written in total variance `w = σ² T`, with share
price `S`, strike `K`, cash rate `r`, dividend yield `q`, years to expiry `T`. `N(x)` is Mathlib's
`cdf (gaussianReal 0 1) x` and the bell height `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`. -/

/-- `d1 = (ln(S/K) + (r - q) T + w/2) / √w`; then `d2 = d1 - √w`. -/
noncomputable def bsD1 (S K r q T w : ℝ) : ℝ :=
  (log (S / K) + (r - q) * T + w / 2) / √w

/-- The Black-Scholes call at total variance `w`: `C_BS(w) = S e^(-qT) N(d1) - K e^(-rT) N(d2)`. -/
noncomputable def bsCall (S K r q T w : ℝ) : ℝ :=
  S * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q T w) -
    K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q T w - √w)

/-- The card's slope of the call in total variance: `S e^(-qT) φ(d1) / (2 √w)`. -/
noncomputable def bsSlope (S K r q T w : ℝ) : ℝ :=
  S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q T w) / (2 * √w)

/-- The slope of the scale function `s` in the Feller proof:
`s'(v) = v^(-a) e^(2κv/ξ²)` with `a = 2κθ/ξ²`. -/
noncomputable def scaleSlope (κ θ ξ v : ℝ) : ℝ :=
  v ^ (-(2 * κ * θ / ξ ^ 2)) * exp (2 * κ * v / ξ ^ 2)

/-! Helper lemmas used in the proofs below. -/

lemma stdPDF_eq (y : ℝ) :
    gaussianPDFReal 0 1 y = (√(2 * π))⁻¹ * exp (-y ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma continuous_stdPDF : Continuous (gaussianPDFReal 0 1) := by
  have : gaussianPDFReal 0 1 = fun y => (√(2 * π))⁻¹ * exp (-y ^ 2 / 2) := funext stdPDF_eq
  rw [this]; fun_prop

lemma hasDerivAt_stdPDF (y : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-y * gaussianPDFReal 0 1 y) y := by
  have : gaussianPDFReal 0 1 = fun y => (√(2 * π))⁻¹ * exp (-y ^ 2 / 2) := funext stdPDF_eq
  rw [this]
  have h := ((((hasDerivAt_pow 2 y).neg).div_const 2).exp).const_mul (√(2 * π))⁻¹
  convert h using 1
  simp only [Pi.neg_apply]; push_cast; ring

lemma cdf_std_eq (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (integral_nonneg (gaussianPDFReal_nonneg 0 1))]

lemma hasDerivAt_stdCDF (x : ℝ) :
    HasDerivAt (fun y => cdf (gaussianReal 0 1) y) (gaussianPDFReal 0 1 x) x := by
  have hfun : (fun y => cdf (gaussianReal 0 1) y) =
      fun y => (∫ t in Iic 0, gaussianPDFReal 0 1 t) + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [cdf_std_eq, ← intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
      (integrable_gaussianPDFReal 0 1).integrableOn]
    ring
  rw [hfun]
  exact ((continuous_stdPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma hasDerivAt_bsD1 (S K r q T w : ℝ) (hw : 0 < w) :
    HasDerivAt (fun x => bsD1 S K r q T x)
      (1 / (2 * √w) - bsD1 S K r q T w / (2 * w)) w := by
  have hs : 0 < √w := sqrt_pos.mpr hw
  have hsq : √w ^ 2 = w := sq_sqrt hw.le
  have h := (((hasDerivAt_id' w).div_const 2).const_add (log (S / K) + (r - q) * T)).div
    (hasDerivAt_sqrt hw.ne') hs.ne'
  refine h.congr_deriv ?_
  unfold bsD1
  generalize log (S / K) + (r - q) * T = L
  generalize √w = s at hs hsq ⊢
  subst hsq
  field_simp

lemma bs_pdf_balance (S K r q T w : ℝ) (hS : 0 < S) (hK : 0 < K) (hw : 0 < w) :
    K * exp (-(r * T)) * gaussianPDFReal 0 1 (bsD1 S K r q T w - √w) =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q T w) := by
  have hs : 0 < √w := sqrt_pos.mpr hw
  have hsq : √w ^ 2 = w := sq_sqrt hw.le
  have hL : bsD1 S K r q T w * √w - √w ^ 2 / 2 = log (S / K) + (r - q) * T := by
    unfold bsD1
    rw [hsq]
    field_simp
    ring
  rw [stdPDF_eq, stdPDF_eq]
  have he : exp (-(bsD1 S K r q T w - √w) ^ 2 / 2) =
      exp (-(bsD1 S K r q T w) ^ 2 / 2) * exp (bsD1 S K r q T w * √w - √w ^ 2 / 2) := by
    rw [← exp_add]; ring_nf
  rw [he, hL, exp_add, exp_log (div_pos hS hK)]
  have hr : exp (-(r * T)) * exp ((r - q) * T) = exp (-(q * T)) := by
    rw [← exp_add]; ring_nf
  rw [← hr]
  field_simp

#print axioms stdPDF_eq
#print axioms continuous_stdPDF
#print axioms hasDerivAt_stdPDF
#print axioms cdf_std_eq
#print axioms hasDerivAt_stdCDF
#print axioms hasDerivAt_bsD1
#print axioms bs_pdf_balance

/-- **The pull sets the level and the term structure** (Step 1). Let the expected variance `m(t)`
start at today's variance `v₀` and change at the rate `κ (θ - m)` with pull speed `κ > 0`. Then
`m(t) = θ + (v₀ - θ) e^(-κt)`: the gap to the long-run variance shrinks by the factor `e^(-κt)`
and halves every `ln 2 / κ` years. Averaged over a life of `T > 0` years, the expected variance is
`θ + (v₀ - θ)(1 - e^(-κT)) / (κT)`, which travels from `v₀` toward `θ` as the expiry grows. -/
theorem expected_variance_pulled_to_long_run
    (κ θ v₀ : ℝ) (hκ : 0 < κ) (m : ℝ → ℝ) (h0 : m 0 = v₀)
    (hm : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt m (κ * (θ - m t)) (Ici 0) t) :
    (∀ t, 0 ≤ t → m t = θ + (v₀ - θ) * exp (-(κ * t))) ∧
      (∀ t, 0 ≤ t → m (t + log 2 / κ) - θ = (m t - θ) / 2) ∧
      (∀ T, 0 < T →
        (1 / T) * ∫ t in (0 : ℝ)..T, m t = θ + (v₀ - θ) * (1 - exp (-(κ * T))) / (κ * T)) := by
  set g : ℝ → ℝ := fun t => (m t - θ) * exp (κ * t) with hg_def
  have hg : ∀ x ∈ Ici (0 : ℝ), HasDerivWithinAt g 0 (Ici 0) x := by
    intro x hx
    have he : HasDerivAt (fun t => exp (κ * t)) (exp (κ * x) * (κ * 1)) x :=
      ((hasDerivAt_id' x).const_mul κ).exp
    have h := ((hm x hx).sub_const θ).mul he.hasDerivWithinAt
    convert h using 1
    ring
  have hsol : ∀ t, 0 ≤ t → m t = θ + (v₀ - θ) * exp (-(κ * t)) := by
    intro t ht
    have hcont : ContinuousOn g (Icc 0 t) := fun x hx =>
      ((hg x hx.1).continuousWithinAt).mono Icc_subset_Ici_self
    have hder : ∀ x ∈ Ico (0 : ℝ) t, HasDerivWithinAt g 0 (Ici x) x := fun x hx =>
      (hg x hx.1).mono (Ici_subset_Ici.mpr hx.1)
    have hc := constant_of_has_deriv_right_zero hcont hder t ⟨ht, le_refl t⟩
    simp only [hg_def, mul_zero, exp_zero, mul_one, h0] at hc
    rw [exp_neg]
    have hpos := exp_pos (κ * t)
    field_simp
    linarith
  refine ⟨hsol, ?_, ?_⟩
  · intro t ht
    have hl : 0 ≤ log 2 / κ := div_nonneg (log_nonneg (by norm_num)) hκ.le
    rw [hsol t ht, hsol (t + log 2 / κ) (by linarith)]
    rw [show -(κ * (t + log 2 / κ)) = -(κ * t) + -log 2 by field_simp; ring, exp_add, exp_neg (log 2),
      exp_log two_pos]
    ring
  · intro T hT
    have hcongr : ∫ t in (0 : ℝ)..T, m t = ∫ t in (0 : ℝ)..T, (θ + (v₀ - θ) * exp (-(κ * t))) := by
      apply intervalIntegral.integral_congr
      intro t ht
      rw [uIcc_of_le hT.le] at ht
      exact hsol t ht.1
    have hderiv : ∀ x ∈ uIcc 0 T, HasDerivAt (fun t => θ * t - (v₀ - θ) * exp (-(κ * t)) / κ)
        (θ + (v₀ - θ) * exp (-(κ * x))) x := by
      intro x _
      have h := ((hasDerivAt_id' x).const_mul θ).sub
        (((((hasDerivAt_id' x).const_mul κ).neg).exp.const_mul (v₀ - θ)).div_const κ)
      convert h using 1
      simp only [Pi.neg_apply]
      field_simp
      ring
    have hint : IntervalIntegrable (fun t => θ + (v₀ - θ) * exp (-(κ * t))) volume 0 T :=
      (by fun_prop : Continuous fun t => θ + (v₀ - θ) * exp (-(κ * t))).intervalIntegrable _ _
    rw [hcongr, intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint]
    simp only [mul_zero, neg_zero, exp_zero]
    field_simp
    ring

/-- **The vol of vol bends the smile** (Step 4). For `S > 0`, `K > 0` and total variance `w > 0`,
the Black-Scholes call's slope in `w` is `S e^(-qT) φ(d1) / (2√w)`, and its bend is that slope
times `(d1 d2 - 1) / (2w)`. So the bend is negative exactly when `d1 d2 < 1` (near the money,
where averaging over a spread of variances gives less than the price at the average) and
positive when `d1 d2 > 1` (far out in the wings, where it gives more). -/
theorem black_scholes_bend_in_total_variance
    (S K r q T w : ℝ) (hS : 0 < S) (hK : 0 < K) (hw : 0 < w) :
    HasDerivAt (fun x : ℝ => bsCall S K r q T x) (bsSlope S K r q T w) w ∧
      HasDerivAt (fun x : ℝ => bsSlope S K r q T x)
        (bsSlope S K r q T w * (bsD1 S K r q T w * (bsD1 S K r q T w - √w) - 1) / (2 * w)) w ∧
      (bsSlope S K r q T w * (bsD1 S K r q T w * (bsD1 S K r q T w - √w) - 1) / (2 * w) < 0 ↔
        bsD1 S K r q T w * (bsD1 S K r q T w - √w) < 1) ∧
      (0 < bsSlope S K r q T w * (bsD1 S K r q T w * (bsD1 S K r q T w - √w) - 1) / (2 * w) ↔
        1 < bsD1 S K r q T w * (bsD1 S K r q T w - √w)) := by
  have hs : 0 < √w := sqrt_pos.mpr hw
  have hsq : √w ^ 2 = w := sq_sqrt hw.le
  have hd1 := hasDerivAt_bsD1 S K r q T w hw
  have hsqrt := hasDerivAt_sqrt hw.ne'
  have hbal := bs_pdf_balance S K r q T w hS hK hw
  have hslope_pos : 0 < bsSlope S K r q T w := by
    unfold bsSlope
    have := gaussianPDFReal_pos 0 1 (bsD1 S K r q T w) one_ne_zero
    positivity
  refine ⟨?_, ?_, ?_, ?_⟩
  · have h1 := ((hasDerivAt_stdCDF (bsD1 S K r q T w)).comp w hd1).const_mul (S * exp (-(q * T)))
    have h2 := ((hasDerivAt_stdCDF (bsD1 S K r q T w - √w)).comp w (hd1.sub hsqrt)).const_mul
      (K * exp (-(r * T)))
    have h := h1.sub h2
    unfold bsCall
    refine h.congr_deriv ?_
    unfold bsSlope
    rw [← mul_assoc (K * exp (-(r * T))), hbal]
    field_simp
    ring
  · have h1 := (((hasDerivAt_stdPDF (bsD1 S K r q T w)).comp w hd1).const_mul
      (S * exp (-(q * T)))).div (hsqrt.const_mul 2) (by positivity)
    unfold bsSlope
    refine h1.congr_deriv ?_
    simp only [Function.comp_apply]
    generalize bsD1 S K r q T w = d
    generalize gaussianPDFReal 0 1 d = p
    generalize √w = s at hs hsq ⊢
    subst hsq
    field_simp
    ring
  · constructor
    · intro h
      by_contra hc
      push Not at hc
      have : 0 ≤ bsSlope S K r q T w * (bsD1 S K r q T w * (bsD1 S K r q T w - √w) - 1) / (2 * w) := by
        apply div_nonneg (mul_nonneg hslope_pos.le (by linarith)) (by linarith)
      linarith
    · intro h
      apply div_neg_of_neg_of_pos (mul_neg_of_pos_of_neg hslope_pos (by linarith)) (by linarith)
  · constructor
    · intro h
      by_contra hc
      push Not at hc
      have : bsSlope S K r q T w * (bsD1 S K r q T w * (bsD1 S K r q T w - √w) - 1) / (2 * w) ≤ 0 := by
        apply div_nonpos_of_nonpos_of_nonneg (mul_nonpos_of_nonneg_of_nonpos hslope_pos.le (by linarith))
          (by linarith)
      linarith
    · intro h
      apply div_pos (mul_pos hslope_pos (by linarith)) (by linarith)

/-- **The Feller condition, analytic core** (Step 2, folded proof). Take pull speed `κ > 0`,
long-run variance `θ > 0` and vol of vol `ξ > 0`. The slope `s'(v) = v^(-a) e^(2κv/ξ²)`, with
`a = 2κθ/ξ²`, makes the scale function driftless: at every variance `v > 0`,
`s'(v) κ (θ - v) + ½ s''(v) ξ² v = 0`. And for any level `b > 0`, `s'` fails to be integrable
on `(0, b]` (so `s(ε)` runs off to minus infinity as `ε` shrinks, and zero is out of reach)
exactly when the Feller condition `2κθ ≥ ξ²` holds. -/
theorem feller_condition_iff_scale_diverges_at_zero
    (κ θ ξ b : ℝ) (hκ : 0 < κ) (hθ : 0 < θ) (hξ : 0 < ξ) (hb : 0 < b) :
    (∀ v : ℝ, 0 < v → ∃ D : ℝ, HasDerivAt (fun x : ℝ => scaleSlope κ θ ξ x) D v ∧
        scaleSlope κ θ ξ v * (κ * (θ - v)) + 1 / 2 * D * ξ ^ 2 * v = 0) ∧
      (¬ IntegrableOn (fun v : ℝ => scaleSlope κ θ ξ v) (Ioc 0 b) ↔ ξ ^ 2 ≤ 2 * κ * θ) := by
  have hξ2 : 0 < ξ ^ 2 := pow_pos hξ 2
  refine ⟨?_, ?_⟩
  · intro v hv
    have hp := hasDerivAt_rpow_const (x := v) (p := -(2 * κ * θ / ξ ^ 2)) (Or.inl hv.ne')
    have he : HasDerivAt (fun x => exp (2 * κ * x / ξ ^ 2)) (exp (2 * κ * v / ξ ^ 2) * (2 * κ * 1 / ξ ^ 2)) v :=
      (((hasDerivAt_id' v).const_mul (2 * κ)).div_const (ξ ^ 2)).exp
    refine ⟨_, hp.mul he, ?_⟩
    simp only [scaleSlope]
    rw [rpow_sub_one hv.ne']
    field_simp
    ring
  · set a := 2 * κ * θ / ξ ^ 2 with ha
    have hmeasR : AEStronglyMeasurable (fun v : ℝ => v ^ (-a)) (volume.restrict (Ioc 0 b)) :=
      (by fun_prop : Measurable fun v : ℝ => v ^ (-a)).aestronglyMeasurable
    have hmeasS : AEStronglyMeasurable (fun v : ℝ => scaleSlope κ θ ξ v) (volume.restrict (Ioc 0 b)) :=
      (by unfold scaleSlope; fun_prop : Measurable fun v : ℝ => scaleSlope κ θ ξ v).aestronglyMeasurable
    have hiff : IntegrableOn (fun v : ℝ => scaleSlope κ θ ξ v) (Ioc 0 b) ↔
        IntegrableOn (fun v : ℝ => v ^ (-a)) (Ioc 0 b) := by
      constructor
      · intro h
        refine Integrable.mono h hmeasR ((ae_restrict_iff' measurableSet_Ioc).mpr (ae_of_all _ ?_))
        intro v hv
        have h1 : 0 ≤ v ^ (-a) := rpow_nonneg hv.1.le _
        have h2 : 1 ≤ exp (2 * κ * v / ξ ^ 2) := one_le_exp (by have := hv.1; positivity)
        simp only [scaleSlope, ← ha, Real.norm_eq_abs, abs_of_nonneg h1,
          abs_of_nonneg (mul_nonneg h1 (exp_pos _).le)]
        nlinarith
      · intro h
        refine Integrable.mono (h.const_mul (exp (2 * κ * b / ξ ^ 2))) hmeasS
          ((ae_restrict_iff' measurableSet_Ioc).mpr (ae_of_all _ ?_))
        intro v hv
        have h1 : 0 ≤ v ^ (-a) := rpow_nonneg hv.1.le _
        have h2 : exp (2 * κ * v / ξ ^ 2) ≤ exp (2 * κ * b / ξ ^ 2) := by
          apply exp_le_exp.mpr
          apply div_le_div_of_nonneg_right _ hξ2.le
          nlinarith [hv.2]
        simp only [scaleSlope, ← ha, Real.norm_eq_abs,
          abs_of_nonneg (mul_nonneg h1 (exp_pos _).le), abs_of_nonneg (mul_nonneg (exp_pos _).le h1)]
        nlinarith
    rw [hiff, integrableOn_Ioc_iff_integrableOn_Ioo, intervalIntegral.integrableOn_Ioo_rpow_iff hb, not_lt,
      neg_le_neg_iff, ha, le_div_iff₀ hξ2, one_mul]

/-! The card's exact numbers: `κ = 2`, `θ = v₀ = 4/100`, `ξ = 3/10`; the house call has
`S = K = 100`, `r = 5/100`, `q = 2/100`, `T = 1`, total variance `w = 4/100`. -/

-- Feller: 2κθ = 0.1600 against ξ² = 0.0900, so it holds, and a = 16/9 is above 1.
example : (2 : ℚ) * 2 * (4 / 100) = 16 / 100 ∧ ((3 : ℚ) / 10) ^ 2 = 9 / 100 ∧
    ((3 : ℚ) / 10) ^ 2 ≤ 2 * 2 * (4 / 100) ∧ 2 * 2 * (4 / 100) / ((3 : ℚ) / 10) ^ 2 = 16 / 9 := by
  norm_num

-- With v₀ = θ the expected average variance is θ = 0.04 for any expiry.
example : (4 / 100 : ℝ) + (4 / 100 - 4 / 100) * (1 - exp (-(2 * 1))) / (2 * 1) = 4 / 100 := by
  norm_num

-- The house call at 20% for one year: d1 = 0.25 (so d2 = 0.05).
example : bsD1 100 100 (5 / 100) (2 / 100) 1 (4 / 100) = 1 / 4 := by
  have h : √(4 / 100 : ℝ) = 1 / 5 := by
    rw [show (4 / 100 : ℝ) = (1 / 5) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  unfold bsD1
  rw [h]
  norm_num

-- The bend's factor: d1 d2 - 1 = 0.25 × 0.05 - 1 = -79/80, below zero at the money.
example : (1 / 4 : ℚ) * (1 / 20) - 1 = -79 / 80 := by norm_num

-- Var(I)'s prefactor θ ξ² / κ² = 0.04 × 0.09 / 4 = 0.0009.
example : (4 / 100 : ℚ) * (3 / 10) ^ 2 / 2 ^ 2 = 9 / 10000 := by norm_num

#print axioms expected_variance_pulled_to_long_run
#print axioms black_scholes_bend_in_total_variance
#print axioms feller_condition_iff_scale_diverges_at_zero

end HestonModel
