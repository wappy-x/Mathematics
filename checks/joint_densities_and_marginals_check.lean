-- Joint densities: integrating a joint density over every value of one variable gives the other variable's own density, and for the tilted bell that marginal is a plain normal bell.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory Real
open scoped ENNReal

/-- The tilted bell of the card: centre (μH, μW), spreads σH and σW, tilt ρ.
With zh = (h - μH)/σH, zw = (w - μW)/σW and c = √(1 - ρ^2), it is
1 / (2π σH σW c) · e^(-Q/2), where Q = (zh^2 - 2ρ zh zw + zw^2) / c^2. -/
noncomputable def tiltedBell (μH μW σH σW ρ : ℝ) (h w : ℝ) : ℝ :=
  1 / (2 * π * σH * σW * √(1 - ρ ^ 2)) *
    exp (-(((h - μH) / σH) ^ 2 - 2 * ρ * ((h - μH) / σH) * ((w - μW) / σW)
      + ((w - μW) / σW) ^ 2) / (√(1 - ρ ^ 2)) ^ 2 / 2)

/-- The plain normal bell with average μ and spread σ: 1 / (σ √(2π)) · e^(-z^2/2), z = (x - μ)/σ. -/
noncomputable def normalBell (μ σ : ℝ) (x : ℝ) : ℝ :=
  1 / (σ * √(2 * π)) * exp (-((x - μ) / σ) ^ 2 / 2)

/-- The marginal rule. Suppose the pair (H, W) has joint density f: a surface that never dips
below zero (its values are in [0, ∞]) such that, for every region R of the plane, the chance
that (H, W) lands in R is the volume under f above R. Then integrating out the other variable
over every one of its values gives each variable's own density: the chance that H lands in A
is the area above A under h ↦ ∫ f(h, w) dw, and the same with the roles swapped for W. -/
theorem marginal_of_joint_density {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (H W : Ω → ℝ) (hH : Measurable H) (hW : Measurable W)
    (f : ℝ → ℝ → ℝ≥0∞) (hf : Measurable (Function.uncurry f))
    (hjoint : ∀ R : Set (ℝ × ℝ), MeasurableSet R →
      P {ω | (H ω, W ω) ∈ R} = ∫⁻ p in R, f p.1 p.2) :
    (∀ A : Set ℝ, MeasurableSet A → P {ω | H ω ∈ A} = ∫⁻ h in A, ∫⁻ w, f h w) ∧
    (∀ B : Set ℝ, MeasurableSet B → P {ω | W ω ∈ B} = ∫⁻ w in B, ∫⁻ h, f h w) := by
  have hf' : Measurable (fun p : ℝ × ℝ => f p.1 p.2) := hf
  constructor
  · intro A hA
    have h1 := hjoint (A ×ˢ Set.univ) (hA.prod MeasurableSet.univ)
    have hset : {ω | (H ω, W ω) ∈ A ×ˢ (Set.univ : Set ℝ)} = {ω | H ω ∈ A} := by
      ext ω; simp
    rw [hset] at h1
    rw [h1, Measure.volume_eq_prod, setLIntegral_prod _ hf'.aemeasurable, Measure.restrict_univ]
  · intro B hB
    have h1 := hjoint (Set.univ ×ˢ B) (MeasurableSet.univ.prod hB)
    have hset : {ω | (H ω, W ω) ∈ (Set.univ : Set ℝ) ×ˢ B} = {ω | W ω ∈ B} := by
      ext ω; simp
    rw [hset] at h1
    rw [h1, Measure.volume_eq_prod, ← Measure.prod_restrict, lintegral_prod_symm _ hf'.aemeasurable,
      Measure.restrict_univ]

/-- Step 3: for the tilted bell, integrating across every weight leaves a plain normal bell in
height, with the same centre and spread; the tilt ρ vanishes. -/
theorem tiltedBell_marginal (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW)
    (hρ : |ρ| < 1) (h : ℝ) :
    ∫ w, tiltedBell μH μW σH σW ρ h w = normalBell μH σH h := by
  have hc2 : 0 < 1 - ρ ^ 2 := by
    have : ρ ^ 2 < 1 := by
      have := sq_lt_sq' (abs_lt.mp hρ).1 (abs_lt.mp hρ).2
      simpa using this
    linarith
  set c := √(1 - ρ ^ 2) with hc
  have hcpos : 0 < c := Real.sqrt_pos.mpr hc2
  have hcsq : c ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt hc2.le
  set zh := (h - μH) / σH with hzh
  set b := 1 / (2 * c ^ 2 * σW ^ 2) with hb
  have hbpos : 0 < b := by positivity
  set m := μW + ρ * zh * σW with hm
  have key : ∀ w, tiltedBell μH μW σH σW ρ h w =
      (1 / (2 * π * σH * σW * c) * exp (-zh ^ 2 / 2)) * exp (-b * (w - m) ^ 2) := by
    intro w
    unfold tiltedBell
    rw [← hc, ← hzh, mul_assoc (1 / _) (rexp _) (rexp _), ← Real.exp_add]
    congr 2
    rw [hb, hm, hcsq]
    field_simp
    ring
  simp_rw [key]
  rw [integral_const_mul, integral_sub_right_eq_self (fun x => exp (-b * x ^ 2)) m,
    integral_gaussian]
  unfold normalBell
  rw [← hzh]
  have hpi : 0 < π := Real.pi_pos
  have h2pi : (0:ℝ) < √(2 * π) := Real.sqrt_pos.mpr (by positivity)
  have hs : √(π / b) = √(2 * π) * c * σW := by
    rw [hb, Real.sqrt_eq_iff_mul_self_eq (by positivity) (by positivity)]
    have : √(2 * π) * √(2 * π) = 2 * π := Real.mul_self_sqrt (by positivity)
    have h2 : √(π * 2) ^ 2 = π * 2 := Real.sq_sqrt (by positivity)
    field_simp
    nlinarith [this, h2]
  rw [hs]
  have : √(2 * π) * √(2 * π) = 2 * π := Real.mul_self_sqrt (by positivity)
  field_simp
  nlinarith [this]

/-- Step 4: the tilted bell is the product of its two marginals at every point exactly when
the tilt is zero. -/
theorem tiltedBell_eq_product_iff (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW)
    (hρ : |ρ| < 1) :
    (∀ h w, tiltedBell μH μW σH σW ρ h w = normalBell μH σH h * normalBell μW σW w) ↔
      ρ = 0 := by
  have hpi : 0 < π := Real.pi_pos
  have h2pi : (0:ℝ) < √(2 * π) := Real.sqrt_pos.mpr (by positivity)
  have hss : √(2 * π) * √(2 * π) = 2 * π := Real.mul_self_sqrt (by positivity)
  constructor
  · intro H
    have hc2 : 0 < 1 - ρ ^ 2 := by
      have : ρ ^ 2 < 1 := by
        have := sq_lt_sq' (abs_lt.mp hρ).1 (abs_lt.mp hρ).2
        simpa using this
      linarith
    have hcpos : 0 < √(1 - ρ ^ 2) := Real.sqrt_pos.mpr hc2
    have h0 := H μH μW
    unfold tiltedBell normalBell at h0
    simp only [sub_self, zero_div, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow,
      mul_zero, zero_sub, add_zero, neg_zero, zero_div, Real.exp_zero, mul_one] at h0
    have hc1 : √(1 - ρ ^ 2) = 1 := by
      field_simp at h0
      nlinarith [hss]
    have : 1 - ρ ^ 2 = 1 := by
      have := Real.sq_sqrt hc2.le
      rw [hc1] at this; linarith
    have : ρ ^ 2 = 0 := by linarith
    exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
  · rintro rfl h w
    unfold tiltedBell normalBell
    simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, sub_zero, Real.sqrt_one,
      mul_one, zero_mul, one_pow, div_one]
    rw [show (1 / (σH * √(2 * π)) * exp (-((h - μH) / σH) ^ 2 / 2)) *
        (1 / (σW * √(2 * π)) * exp (-((w - μW) / σW) ^ 2 / 2)) =
        1 / (σH * σW * (√(2 * π) * √(2 * π))) *
          (exp (-((h - μH) / σH) ^ 2 / 2) * exp (-((w - μW) / σW) ^ 2 / 2)) by
          field_simp, hss, ← Real.exp_add]
    congr 1
    · ring
    · congr 1; ring

-- The card's exact numbers: covariance 0.5 × 7 × 12 = 42 cm kg.
example : (1 / 2 : ℚ) * 7 * 12 = 42 := by norm_num
-- Standardised weight at 90 kg is 1; standardised height at 185 cm is 10/7.
example : ((90 : ℚ) - 78) / 12 = 1 := by norm_num
example : ((185 : ℚ) - 175) / 7 = 10 / 7 := by norm_num
-- Standardised heights at 170 cm and 180 cm are -5/7 and 5/7.
example : ((170 : ℚ) - 175) / 7 = -5 / 7 ∧ ((180 : ℚ) - 175) / 7 = 5 / 7 := by norm_num
-- The squeeze factor squared: 1 - 0.5^2 = 3/4.
example : (1 : ℚ) - (1 / 2) ^ 2 = 3 / 4 := by norm_num
-- At the centre, the peak divided by the product of the marginals is 1/c = 1/√(3/4).
example : tiltedBell 175 78 7 12 (1 / 2) 175 78 /
    (normalBell 175 7 175 * normalBell 78 12 78) = 1 / √(3 / 4) := by
  have hpi : 0 < π := Real.pi_pos
  have h2pi : (0:ℝ) < √(2 * π) := Real.sqrt_pos.mpr (by positivity)
  have hss : √(2 * π) * √(2 * π) = 2 * π := Real.mul_self_sqrt (by positivity)
  have h34 : (0:ℝ) < √(3 / 4) := Real.sqrt_pos.mpr (by norm_num)
  unfold tiltedBell normalBell
  have e : (1 : ℝ) - (1 / 2) ^ 2 = 3 / 4 := by norm_num
  rw [e]
  simp only [sub_self, zero_div, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow,
      mul_zero, zero_sub, add_zero, neg_zero, Real.exp_zero, mul_one]
  field_simp
  nlinarith [hss]

#print axioms marginal_of_joint_density
#print axioms tiltedBell_marginal
#print axioms tiltedBell_eq_product_iff
