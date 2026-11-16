-- Densities add by convolution: this file states that the sum of two independent quantities with densities f and g has density f * g and Fourier transform equal to the product of theirs.
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Probability.Independence.CharacteristicFunction
import Mathlib.MeasureTheory.Group.LIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open MeasureTheory ProbabilityTheory
open scoped ENNReal

theorem conv_withDensity_eq {f g : ℝ → ℝ≥0∞} (hf : Measurable f) (hg : Measurable g) :
    (volume.withDensity f) ∗ (volume.withDensity g) =
      volume.withDensity (fun s => ∫⁻ x, f x * g (s - x)) := by
  ext s hs
  have hind : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  rw [← lintegral_indicator_one hs, Measure.lintegral_conv hind, withDensity_apply _ hs]
  rw [lintegral_withDensity_eq_lintegral_mul _ hf (by fun_prop)]
  have inner : ∀ x, ∫⁻ y, s.indicator 1 (x + y) ∂(volume.withDensity g)
      = ∫⁻ t, g (t - x) * s.indicator 1 t := by
    intro x
    rw [lintegral_withDensity_eq_lintegral_mul _ hg (by fun_prop)]
    rw [← lintegral_add_right_eq_self (fun t => g (t - x) * s.indicator 1 t) x]
    simp only [Pi.mul_apply, add_sub_cancel_right, add_comm x]
  simp only [Pi.mul_apply, inner]
  rw [← lintegral_indicator hs]
  have hm : Measurable (Function.uncurry fun x t => f x * (g (t - x) * s.indicator 1 t)) := by
    apply Measurable.mul (hf.comp measurable_fst)
    apply Measurable.mul (hg.comp (measurable_snd.sub measurable_fst))
    exact hind.comp measurable_snd
  calc ∫⁻ x, f x * ∫⁻ t, g (t - x) * s.indicator 1 t
      = ∫⁻ x, ∫⁻ t, f x * (g (t - x) * s.indicator 1 t) := by
        congr 1; ext x
        rw [lintegral_const_mul _ (by
          exact (hg.comp (measurable_id.sub_const x)).mul hind)]
    _ = ∫⁻ t, ∫⁻ x, f x * (g (t - x) * s.indicator 1 t) :=
        lintegral_lintegral_swap hm.aemeasurable
    _ = _ := by
        congr 1; ext t
        by_cases ht : t ∈ s <;> simp [ht]

#print axioms conv_withDensity_eq

theorem vol_Iic_inter_Ico (a : ℝ) (_ha : 0 ≤ a) :
    volume (Set.Iic a ∩ Set.Ico (0 : ℝ) 3) = ENNReal.ofReal (min a 3) := by
  rcases lt_or_ge a 3 with h | h
  · have : Set.Iic a ∩ Set.Ico (0 : ℝ) 3 = Set.Icc 0 a := by
      ext t; simp only [Set.mem_inter_iff, Set.mem_Iic, Set.mem_Ico, Set.mem_Icc]
      constructor
      · rintro ⟨h1, h2, _⟩; exact ⟨h2, h1⟩
      · rintro ⟨h1, h2⟩; exact ⟨h2, h1, by linarith⟩
    rw [this, Real.volume_Icc, min_eq_left h.le, sub_zero]
  · have : Set.Iic a ∩ Set.Ico (0 : ℝ) 3 = Set.Ico 0 3 := by
      ext t; simp only [Set.mem_inter_iff, Set.mem_Iic, Set.mem_Ico]
      constructor
      · rintro ⟨_, h2⟩; exact h2
      · rintro ⟨h1, h2⟩; exact ⟨by linarith, h1, h2⟩
    rw [this, Real.volume_Ico, min_eq_right h, sub_zero]

#print axioms vol_Iic_inter_Ico

theorem integral_min_four_sub :
    ∫ x in (0 : ℝ)..2, min (4 - x) 3 = 11 / 2 := by
  have hc : Continuous fun x : ℝ => min (4 - x) 3 := by fun_prop
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := 1)
    (hc.intervalIntegrable _ _) (hc.intervalIntegrable _ _)]
  have h1 : ∫ x in (0 : ℝ)..1, min (4 - x) 3 = ∫ x in (0 : ℝ)..1, (3 : ℝ) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by norm_num)] at hx
    simp only
    rw [min_eq_right (by linarith [hx.2])]
  have h2 : ∫ x in (1 : ℝ)..2, min (4 - x) 3 = ∫ x in (1 : ℝ)..2, (4 - x) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by norm_num)] at hx
    simp only
    rw [min_eq_left (by linarith [hx.1])]
  rw [h1, h2, intervalIntegral.integral_sub (by simp) (by simp)]
  simp
  norm_num

#print axioms integral_min_four_sub

/-- If `X` and `Y` are independent and have densities `f` and `g` (chance per unit,
with respect to length on the line), then their sum `S = X + Y` has the density
`h(s) = ∫ f(x) g(s - x) dx`, the convolution `f * g`. -/
theorem density_of_independent_sum_eq_convolution
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X Y : Ω → ℝ} {f g : ℝ → ℝ≥0∞} (hf : Measurable f) (hg : Measurable g)
    (hX : HasLaw X (volume.withDensity f) P) (hY : HasLaw Y (volume.withDensity g) P)
    (hXY : IndepFun X Y P) :
    HasLaw (X + Y) (volume.withDensity (fun s => ∫⁻ x, f x * g (s - x))) P := by
  refine ⟨hX.aemeasurable.add hY.aemeasurable, ?_⟩
  rw [hXY.map_add_eq_map_conv_map₀ hX.aemeasurable hY.aemeasurable, hX.map_eq, hY.map_eq,
    conv_withDensity_eq hf hg]

/-- In frequency, convolution becomes multiplication: for independent `X` and `Y`
(any laws, so the check exists for every law), the transform of the sum,
`E[e^(-2πiξ(X+Y))]`, is the product of the transforms `E[e^(-2πiξX)]` and
`E[e^(-2πiξY)]`, at every frequency `ξ`. -/
theorem fourier_transform_of_independent_sum_eq_product
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X Y : Ω → ℝ} (hX : AEMeasurable X P) (hY : AEMeasurable Y P)
    (hXY : IndepFun X Y P) (ξ : ℝ) :
    ∫ ω, Complex.exp (-2 * Real.pi * Complex.I * ξ * ((X ω + Y ω : ℝ) : ℂ)) ∂P =
      (∫ ω, Complex.exp (-2 * Real.pi * Complex.I * ξ * (X ω : ℂ)) ∂P) *
        ∫ ω, Complex.exp (-2 * Real.pi * Complex.I * ξ * (Y ω : ℂ)) ∂P := by
  have h := congrFun (hXY.charFun_map_add_eq_mul hX hY) (-2 * Real.pi * ξ)
  have key : ∀ (Z : Ω → ℝ), AEMeasurable Z P →
      charFun (P.map Z) (-2 * Real.pi * ξ) =
        ∫ ω, Complex.exp (-2 * Real.pi * Complex.I * ξ * (Z ω : ℂ)) ∂P := by
    intro Z hZ
    rw [charFun_apply_real, integral_map hZ (by fun_prop)]
    congr 1; ext ω; congr 1; push_cast; ring
  rw [Pi.mul_apply, key _ (hX.add hY), key _ hX, key _ hY] at h
  simpa using h

/-- The delivery example: a packing wait flat on `[0, 2)` hours (density 1/2) and an
independent van wait flat on `[0, 3)` hours (density 1/3) give a total that is at most
the promised 4 hours with chance 11/12. -/
theorem delivery_within_four_hours_eq_eleven_twelfths
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X Y : Ω → ℝ}
    (hX : HasLaw X (volume.withDensity ((Set.Ico (0 : ℝ) 2).indicator fun _ => (1 / 2 : ℝ≥0∞))) P)
    (hY : HasLaw Y (volume.withDensity ((Set.Ico (0 : ℝ) 3).indicator fun _ => (1 / 3 : ℝ≥0∞))) P)
    (hXY : IndepFun X Y P) :
    P {ω | X ω + Y ω ≤ 4} = 11 / 12 := by
  have hmap := hXY.map_add_eq_map_conv_map₀ hX.aemeasurable hY.aemeasurable
  rw [hX.map_eq, hY.map_eq, withDensity_indicator measurableSet_Ico,
    withDensity_indicator measurableSet_Ico, withDensity_const, withDensity_const] at hmap
  have hS : MeasurableSet (Set.Iic (4 : ℝ)) := measurableSet_Iic
  have hset : {ω | X ω + Y ω ≤ 4} = (X + Y) ⁻¹' Set.Iic 4 := rfl
  rw [hset, ← Measure.map_apply₀ (hX.aemeasurable.add hY.aemeasurable) hS.nullMeasurableSet,
    hmap, ← lintegral_indicator_one hS,
    Measure.lintegral_conv (measurable_one.indicator hS), lintegral_smul_measure]
  have inner : ∀ x ∈ Set.Ico (0 : ℝ) 2,
      ∫⁻ y, (Set.Iic (4 : ℝ)).indicator 1 (x + y) ∂((1 / 3 : ℝ≥0∞) • volume.restrict (Set.Ico 0 3))
        = (1 / 3 : ℝ≥0∞) * ENNReal.ofReal (min (4 - x) 3) := by
    intro x hx
    have hpre : (fun y => (Set.Iic (4 : ℝ)).indicator (1 : ℝ → ℝ≥0∞) (x + y))
        = (Set.Iic (4 - x)).indicator 1 := by
      ext y
      simp only [Set.indicator, Set.mem_Iic]
      congr 1
      exact propext ⟨fun h => by linarith, fun h => by linarith⟩
    rw [lintegral_smul_measure, hpre, lintegral_indicator_one measurableSet_Iic,
      Measure.restrict_apply measurableSet_Iic, vol_Iic_inter_Ico _ (by linarith [hx.2]),
      smul_eq_mul]
  rw [setLIntegral_congr_fun measurableSet_Ico inner, lintegral_const_mul _ (by fun_prop),
    ← ofReal_integral_eq_lintegral_ofReal, integral_Ico_eq_integral_Ioc,
    ← intervalIntegral.integral_of_le (by norm_num), integral_min_four_sub]
  · rw [smul_eq_mul, ← mul_assoc]
    have e1 : (1 / 2 : ℝ≥0∞) = ENNReal.ofReal (1 / 2) := by
      rw [ENNReal.ofReal_div_of_pos (by norm_num)]; simp
    have e2 : (1 / 3 : ℝ≥0∞) = ENNReal.ofReal (1 / 3) := by
      rw [ENNReal.ofReal_div_of_pos (by norm_num)]; simp
    have e3 : (11 / 12 : ℝ≥0∞) = ENNReal.ofReal (11 / 12) := by
      rw [ENNReal.ofReal_div_of_pos (by norm_num)]; simp
    rw [e1, e2, e3, ← ENNReal.ofReal_mul (by norm_num), ← ENNReal.ofReal_mul (by norm_num)]
    norm_num
  · exact ((by fun_prop : Continuous fun x : ℝ => min (4 - x) 3).integrableOn_Icc).mono_set
      Set.Ico_subset_Icc_self
  · exact (ae_restrict_iff' measurableSet_Ico).2
      (Filter.Eventually.of_forall fun x hx => show (0 : ℝ) ≤ min (4 - x) 3 from
        le_min (by linarith [hx.2]) (by norm_num))

-- Step 2: the density of the total at 2.5 hours is the overlap 2 hours over A B = 6.
example : (2 : ℚ) / (2 * 3) = 1 / 3 := by norm_num
-- At 4 hours the overlap of [0, 2] and [1, 4] is 1 hour, so h(4) = 1/6.
example : (1 : ℚ) / (2 * 3) = 1 / 6 := by norm_num
-- The late corner: a triangle of base 1 hour and height 1/6 has area 1/12.
example : (1 : ℚ) * (1 / 6) / 2 = 1 / 12 := by norm_num
-- The promise is kept with chance 1 - 1/12 = 11/12.
example : (1 : ℚ) - 1 / 12 = 11 / 12 := by norm_num
-- Average total 1 + 1.5 = 2.5 hours.
example : (1 : ℚ) + 3 / 2 = 5 / 2 := by norm_num
-- Bell model: variances A^2/12 + B^2/12 = 4/12 + 9/12 = 13/12 square hours.
example : (2 : ℚ) ^ 2 / 12 + 3 ^ 2 / 12 = 13 / 12 := by norm_num
-- Young: the squared 2-size of h is (B - A/3)/B^2 = 7/27, below the squared 2-size of g, 1/3.
example : ((3 : ℚ) - 2 / 3) / 3 ^ 2 = 7 / 27 ∧ (7 : ℚ) / 27 < 1 / 3 := by norm_num
-- Smoothing: the bound 2/(A B) = 1/3 on the slope is twice the true steepest slope 1/6.
example : (2 : ℚ) / (2 * 3) = 2 * (1 / 6) := by norm_num
-- Tied delays (van wait = 1.5 x packing wait): total flat on [0, 5], on time D/(A+B) = 4/5.
example : (4 : ℚ) / (2 + 3) = 4 / 5 := by norm_num

#print axioms density_of_independent_sum_eq_convolution
#print axioms fourier_transform_of_independent_sum_eq_product
#print axioms delivery_within_four_hours_eq_eleven_twelfths
