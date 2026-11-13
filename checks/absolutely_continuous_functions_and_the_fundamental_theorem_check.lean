-- Absolutely continuous functions and the fundamental theorem: a function on a closed interval is the running integral of an integrable rate exactly when it is absolutely continuous, that rate is then its derivative almost everywhere and integrates back to the total change, and Lipschitz implies absolutely continuous implies continuous with bounded variation.
import Mathlib.MeasureTheory.Function.AbsolutelyContinuous
import Mathlib.MeasureTheory.Integral.IntervalIntegral.AbsolutelyContinuousFun

open MeasureTheory Set
open scoped NNReal

/-- The fundamental theorem for the Lebesgue integral: on a closed interval `[a, b]`, a function
`F` is absolutely continuous (short intervals, however many, move it little in total once their
lengths add up to little) exactly when there is a Lebesgue-integrable rate `f` on `[a, b]` with
`F x = F a + ∫ over [a, x] of f` for every `x` in `[a, b]`. -/
theorem absolutelyContinuous_iff_running_integral {F : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b) :
    AbsolutelyContinuousOnInterval F a b ↔
      ∃ f : ℝ → ℝ, IntegrableOn f (Icc a b) ∧
        ∀ x ∈ Icc a b, F x = F a + ∫ t in Icc a x, f t := by
  constructor
  · intro hF
    refine ⟨deriv F, ?_, ?_⟩
    · exact (intervalIntegrable_iff_integrableOn_Icc_of_le hab).mp hF.intervalIntegrable_deriv
    · intro x hx
      have hAC : AbsolutelyContinuousOnInterval F a x :=
        hF.mono (by
          rw [uIcc_of_le hab, uIcc_of_le hx.1]
          exact Icc_subset_Icc le_rfl hx.2)
      have h := hAC.integral_deriv_eq_sub
      rw [intervalIntegral.integral_of_le hx.1, ← integral_Icc_eq_integral_Ioc] at h
      linarith
  · rintro ⟨f, hf, hFf⟩
    have hII : IntervalIntegrable f volume a b :=
      (intervalIntegrable_iff_integrableOn_Icc_of_le hab).mpr hf
    have hG : AbsolutelyContinuousOnInterval (fun x ↦ ∫ v in a..x, f v) a b :=
      hII.absolutelyContinuousOnInterval_intervalIntegral (by simp)
    have hC : AbsolutelyContinuousOnInterval (fun _ : ℝ ↦ F a) a b :=
      (LipschitzWith.const (F a)).lipschitzOnWith.absolutelyContinuousOnInterval
    refine (hC.add hG).congr ?_
    intro x hx
    rw [uIcc_of_le hab] at hx
    simp only [Pi.add_apply]
    rw [hFf x hx, intervalIntegral.integral_of_le hx.1, integral_Icc_eq_integral_Ioc]

/-- When `F` is the running integral of an integrable rate `f` on `[a, b]`, then `F` has
derivative `f x` at almost every point `x` of `[a, b]`, and the derivative integrates back to the
total change: `F b - F a = ∫ over [a, b] of F'`. -/
theorem running_integral_deriv_eq_rate_ae {F f : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hf : IntegrableOn f (Icc a b))
    (hF : ∀ x ∈ Icc a b, F x = F a + ∫ t in Icc a x, f t) :
    (∀ᵐ x ∂(volume.restrict (Icc a b)), HasDerivAt F (f x) x) ∧
      F b - F a = ∫ t in Icc a b, deriv F t := by
  have hII : IntervalIntegrable f volume a b :=
    (intervalIntegrable_iff_integrableOn_Icc_of_le hab).mpr hf
  have hderiv : ∀ᵐ x ∂(volume.restrict (Icc a b)), HasDerivAt F (f x) x := by
    rw [ae_restrict_iff' measurableSet_Icc]
    have h₁ : ∀ᵐ x : ℝ, x ≠ a := by simp [ae_iff, measure_singleton]
    have h₂ : ∀ᵐ x : ℝ, x ≠ b := by simp [ae_iff, measure_singleton]
    filter_upwards [hII.ae_hasDerivAt_integral, h₁, h₂] with x hx hxa hxb hxI
    have hxI' : x ∈ uIcc a b := by rw [uIcc_of_le hab]; exact hxI
    have hD := hx hxI' a (by simp [hab])
    have hD' : HasDerivAt (fun y ↦ F a + ∫ t in a..y, f t) (f x) x := by
      simpa using hD.const_add (F a)
    apply hD'.congr_of_eventuallyEq
    have hmem : Ioo a b ∈ nhds x :=
      Ioo_mem_nhds (lt_of_le_of_ne hxI.1 (Ne.symm hxa)) (lt_of_le_of_ne hxI.2 hxb)
    filter_upwards [hmem] with y hy
    rw [hF y (Ioo_subset_Icc_self hy), intervalIntegral.integral_of_le hy.1.le,
      integral_Icc_eq_integral_Ioc]
  refine ⟨hderiv, ?_⟩
  have hb := hF b ⟨hab, le_rfl⟩
  have : ∫ t in Icc a b, deriv F t = ∫ t in Icc a b, f t := by
    apply integral_congr_ae
    filter_upwards [hderiv] with x hx
    exact hx.deriv
  rw [this]
  linarith

/-- The chain: a Lipschitz function on `[a, b]` is absolutely continuous there, and an absolutely
continuous function on `[a, b]` is continuous and of bounded variation there. -/
theorem lipschitz_imp_absolutelyContinuous_imp_continuous_boundedVariation
    {F : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b) :
    (∀ L : ℝ≥0, LipschitzOnWith L F (Icc a b) → AbsolutelyContinuousOnInterval F a b) ∧
      (AbsolutelyContinuousOnInterval F a b →
        ContinuousOn F (Icc a b) ∧ BoundedVariationOn F (Icc a b)) := by
  refine ⟨fun L hL ↦ ?_, fun hF ↦ ?_⟩
  · rw [← uIcc_of_le hab] at hL
    exact hL.absolutelyContinuousOnInterval
  · rw [← uIcc_of_le hab]
    exact ⟨hF.continuousOn, hF.boundedVariationOn⟩

-- Worked numbers from the card, in exact fractions (hours, km, km/h).
-- Leg 1: triangle area 1/2 × 0.2 h × 60 km/h = 6 km.
example : (1 / 2 : ℚ) * (1 / 5) * 60 = 6 := by norm_num
-- Leg 2: 90 km/h for 0.3 h; leg 4: 45 km/h for 0.4 h.
example : (90 : ℚ) * (3 / 10) = 27 := by norm_num
example : (45 : ℚ) * (2 / 5) = 18 := by norm_num
-- Integral of the speed equals the odometer change, 51 km.
example : (6 : ℕ) + 27 + 0 + 18 = 51 := by decide
-- delta for eps = 0.1 km with Lipschitz constant 90 is 1/900 h, which is 4 seconds.
example : (1 / 10 : ℚ) / 90 = 1 / 900 := by norm_num
example : (3600 : ℚ) * (1 / 900) = 4 := by norm_num
-- Variation bound: 91 pieces of length 1/91 are each shorter than delta = 1/90.
example : (1 / 91 : ℚ) < 1 / 90 := by norm_num
-- Distance during A = [0.1, 0.3] ∪ [0.45, 0.55] ∪ [0.7, 0.95]: (15 - 1.5) + (33 - 28.5) + (48.75 - 37.5) = 29.25 km.
example : ((15 : ℚ) - 3 / 2) + (33 - 57 / 2) + (195 / 4 - 75 / 2) = 117 / 4 := by norm_num
-- Cantor stages: 2^n kept intervals of total length (2/3)^n; stage 12 is the first below 0.01.
example : (2 : ℕ) ^ 10 = 1024 ∧ (2 : ℕ) ^ 12 = 4096 := by decide
example : (2 / 3 : ℚ) ^ 12 < 1 / 100 ∧ ¬ ((2 / 3 : ℚ) ^ 11 < 1 / 100) := by norm_num
-- Each of the 2^n kept intervals rises 1/2^n, so together they rise 1.
example : (4096 : ℚ) * (1 / 2 ^ 12) = 1 := by norm_num

#print axioms absolutelyContinuous_iff_running_integral
#print axioms running_integral_deriv_eq_rate_ae
#print axioms lipschitz_imp_absolutelyContinuous_imp_continuous_boundedVariation
