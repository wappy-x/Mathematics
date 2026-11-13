-- Impulses: unit-area pulses narrowing to zero width read off a continuous signal's value at the blow, their transforms tend to e^(-as), and the struck car's motion leaves level at velocity 1 and rings down by y'' + 2y' + 5y = 0.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Complex.Trigonometric
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-! Setting, in the card's notation.
* `pulse ε a t` is the card's `δ_ε(t - a)`: strength `1/ε` from `a` to `a + ε`, zero elsewhere,
  so its area is 1.
* "Weighting a signal by the pulse and adding up" is the integral over `t > 0`,
  `∫ t in Set.Ioi 0, pulse ε a t * g t`.
* `ε → 0` from above is the filter `𝓝[>] 0`.
* The struck car's height is `carHeight t = u(t - 1) · ½ e^(-(t-1)) sin 2(t - 1)`. -/

open Real Filter Topology MeasureTheory Set

namespace Impulses

/-- The card's pulse `δ_ε(t - a)`: strength `1/ε` on `[a, a + ε)`, zero elsewhere. -/
noncomputable def pulse (ε a t : ℝ) : ℝ := (Ico a (a + ε)).indicator (fun _ => 1 / ε) t

/-- The card's struck car: zero before the blow at `t = 1`, then `½ e^(-(t-1)) sin 2(t - 1)`. -/
noncomputable def carHeight (t : ℝ) : ℝ :=
  if t < 1 then 0 else (1 / 2) * exp (-(t - 1)) * sin (2 * (t - 1))

lemma pulse_integral_eq (g : ℝ → ℝ) (a ε : ℝ) (ha : 0 < a) (hε : 0 < ε) :
    ∫ t in Ioi 0, pulse ε a t * g t = ε⁻¹ * ∫ x in a..(a + ε), g x := by
  have h1 : (fun t => pulse ε a t * g t) = (Ico a (a + ε)).indicator (fun t => ε⁻¹ * g t) := by
    funext t
    simp only [pulse, indicator]
    split_ifs <;> simp
  rw [h1, setIntegral_indicator measurableSet_Ico]
  have h2 : Ioi (0:ℝ) ∩ Ico a (a + ε) = Ico a (a + ε) := by
    apply inter_eq_right.mpr
    intro x hx; exact lt_of_lt_of_le ha hx.1
  rw [h2, integral_Ico_eq_integral_Ioo, ← integral_Ioc_eq_integral_Ioo,
    ← intervalIntegral.integral_of_le (by linarith), intervalIntegral.integral_const_mul]

lemma pulse_integral_tendsto (g : ℝ → ℝ) (hg : Continuous g) (a : ℝ) (ha : 0 < a) :
    Tendsto (fun ε => ∫ t in Ioi 0, pulse ε a t * g t) (𝓝[>] 0) (𝓝 (g a)) := by
  have hd : HasDerivAt (fun u => ∫ x in a..u, g x) (g a) a :=
    intervalIntegral.integral_hasDerivAt_right (hg.intervalIntegrable _ _)
      hg.aestronglyMeasurable.stronglyMeasurableAtFilter hg.continuousAt
  have ht := hd.tendsto_slope_zero_right
  apply ht.congr'
  filter_upwards [self_mem_nhdsWithin] with ε hε
  rw [pulse_integral_eq g a ε ha hε]
  simp [smul_eq_mul]

lemma car_hasDeriv (t : ℝ) :
    HasDerivAt (fun t => (1 / 2) * exp (-(t - 1)) * sin (2 * (t - 1)))
      (exp (-(t - 1)) * (cos (2 * (t - 1)) - (1/2) * sin (2 * (t - 1)))) t := by
  have h1 : HasDerivAt (fun t : ℝ => -(t - 1)) (-1) t := ((hasDerivAt_id' t).sub_const 1).neg
  have h3 : HasDerivAt (fun t : ℝ => 2 * (t - 1)) (2 * 1) t :=
    ((hasDerivAt_id' t).sub_const 1).const_mul 2
  have := (h1.exp.const_mul (1/2)).mul h3.sin
  convert this using 1; ring

lemma car_hasDeriv2 (t : ℝ) :
    HasDerivAt (fun t => exp (-(t - 1)) * (cos (2 * (t - 1)) - (1/2) * sin (2 * (t - 1))))
      (exp (-(t - 1)) * (-2 * cos (2 * (t - 1)) - (3/2) * sin (2 * (t - 1)))) t := by
  have h1 : HasDerivAt (fun t : ℝ => -(t - 1)) (-1) t := ((hasDerivAt_id' t).sub_const 1).neg
  have h3 : HasDerivAt (fun t : ℝ => 2 * (t - 1)) (2 * 1) t :=
    ((hasDerivAt_id' t).sub_const 1).const_mul 2
  have := h1.exp.mul (h3.cos.sub (h3.sin.const_mul (1/2)))
  convert this using 1
  simp only [Pi.sub_apply]; ring

#print axioms pulse_integral_eq
#print axioms pulse_integral_tendsto
#print axioms car_hasDeriv
#print axioms car_hasDeriv2

/-- The delta reads off a signal's value at the blow. For every continuous signal `g` and every
blow time `a > 0`, weighting `g` by the area-1 pulse of width `ε` starting at `a` and adding up
over `t > 0` tends to `g(a)` as the width shrinks to zero. -/
theorem pulse_integral_tends_to_value_at_blow (g : ℝ → ℝ) (hg : Continuous g)
    (a : ℝ) (ha : 0 < a) :
    Tendsto (fun ε => ∫ t in Ioi 0, pulse ε a t * g t) (𝓝[>] 0) (𝓝 (g a)) := by
  exact pulse_integral_tendsto g hg a ha

/-- The transform of the delta is `e^(-as)`. For a blow at `a > 0` and a real `s > 0`, the
pulse of width `ε > 0` has transform exactly `e^(-as) (1 - e^(-sε)) / (sε)`, and as the width
shrinks to zero these transforms tend to `e^(-as)`. -/
theorem pulse_transform_tends_to_exp_neg_as (a s : ℝ) (ha : 0 < a) (hs : 0 < s) :
    (∀ ε > 0, ∫ t in Ioi 0, pulse ε a t * exp (-s * t) =
        exp (-a * s) * (1 - exp (-s * ε)) / (s * ε)) ∧
    Tendsto (fun ε => ∫ t in Ioi 0, pulse ε a t * exp (-s * t)) (𝓝[>] 0)
      (𝓝 (exp (-a * s))) := by
  refine ⟨fun ε hε => ?_, ?_⟩
  · rw [pulse_integral_eq _ a ε ha hε]
    have hF : ∀ x ∈ uIcc a (a + ε),
        HasDerivAt (fun x => -exp (-s * x) / s) (exp (-s * x)) x := by
      intro x _
      have h := (((hasDerivAt_id' x).const_mul (-s)).exp.neg).div_const s
      convert h using 1
      field_simp
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF
      ((continuous_exp.comp (continuous_const.mul continuous_id)).intervalIntegrable _ _)]
    have he : exp (-s * (a + ε)) = exp (-a * s) * exp (-s * ε) := by
      rw [← exp_add]; ring_nf
    have he2 : exp (-s * a) = exp (-a * s) := by ring_nf
    rw [he, he2]
    field_simp
    ring
  · have h := pulse_integral_tendsto (fun t => exp (-s * t))
      (continuous_exp.comp (continuous_const.mul continuous_id)) a ha
    have he2 : exp (-s * a) = exp (-a * s) := by ring_nf
    rw [he2] at h
    exact h

/-- The struck car. The height `u(t - 1) · ½ e^(-(t-1)) sin 2(t - 1)` does not jump at the blow,
its velocity jumps from 0 just before `t = 1` to 1 just after, and after the blow it rings down
freely: `y'' + 2y' + 5y = 0` for every `t > 1`. -/
theorem struck_car_velocity_jumps_by_one_then_rings_down :
    ContinuousAt carHeight 1 ∧
    HasDerivWithinAt carHeight 0 (Iic 1) 1 ∧
    HasDerivWithinAt carHeight 1 (Ici 1) 1 ∧
    (∀ t > 1, deriv (deriv carHeight) t + 2 * deriv carHeight t + 5 * carHeight t = 0) := by
  set f : ℝ → ℝ := fun t => (1 / 2) * exp (-(t - 1)) * sin (2 * (t - 1)) with hf_def
  set f' : ℝ → ℝ := fun t => exp (-(t - 1)) * (cos (2 * (t - 1)) - (1/2) * sin (2 * (t - 1)))
    with hf'_def
  have hL : HasDerivWithinAt carHeight 0 (Iic 1) 1 := by
    apply (hasDerivWithinAt_const (1:ℝ) (Iic 1) (0:ℝ)).congr
    · intro y hy
      simp only [carHeight]
      split_ifs with h
      · rfl
      · have : y = 1 := le_antisymm hy (not_lt.mp h)
        subst this; simp
    · simp [carHeight]
  have hR : HasDerivWithinAt carHeight 1 (Ici 1) 1 := by
    have h := (car_hasDeriv 1).hasDerivWithinAt (s := Ici 1)
    have h1 : exp (-((1:ℝ) - 1)) * (cos (2 * ((1:ℝ) - 1)) - (1/2) * sin (2 * ((1:ℝ) - 1))) = 1 := by
      simp
    rw [h1] at h
    apply h.congr
    · intro y hy
      simp only [carHeight, not_lt.mpr (mem_Ici.mp hy), ↓reduceIte]
    · simp [carHeight]
  refine ⟨?_, hL, hR, ?_⟩
  · exact continuousAt_iff_continuous_left_right.mpr
      ⟨hL.continuousWithinAt, hR.continuousWithinAt⟩
  · intro t ht
    have hev : ∀ y > 1, carHeight =ᶠ[𝓝 y] f := by
      intro y hy
      filter_upwards [lt_mem_nhds hy] with x hx
      simp [carHeight, f, not_lt.mpr hx.le]
    have hd1 : ∀ y > 1, deriv carHeight y = f' y := by
      intro y hy
      rw [(hev y hy).deriv_eq]
      exact (car_hasDeriv y).deriv
    have hd2 : deriv (deriv carHeight) t =
        exp (-(t - 1)) * (-2 * cos (2 * (t - 1)) - (3/2) * sin (2 * (t - 1))) := by
      have : deriv carHeight =ᶠ[𝓝 t] f' := by
        filter_upwards [lt_mem_nhds ht] with x hx
        exact hd1 x hx
      rw [this.deriv_eq]
      exact (car_hasDeriv2 t).deriv
    rw [hd2, hd1 t ht]
    simp only [carHeight, not_lt.mpr (le_of_lt ht), ↓reduceIte, f']
    ring

-- Completing the square: s² + 2s + 5 = (s + 1)² + 4.
example : ∀ s : ℝ, s ^ 2 + 2 * s + 5 = (s + 1) ^ 2 + 4 := by intro s; ring
-- The characteristic roots are -1 ± 2i.
example : (-1 + 2 * Complex.I) ^ 2 + 2 * (-1 + 2 * Complex.I) + 5 = 0 := by
  ring_nf; rw [Complex.I_sq]; ring
example : (-1 - 2 * Complex.I) ^ 2 + 2 * (-1 - 2 * Complex.I) + 5 = 0 := by
  ring_nf; rw [Complex.I_sq]; ring
-- Velocity just after the blow: ½ (2 cos 0 - sin 0) = 1.
example : (1 / 2 : ℝ) * (2 * cos 0 - sin 0) = 1 := by simp
-- The check at s = 2 divides by 2² + 2·2 + 5 = 13.
example : (2 : ℤ) ^ 2 + 2 * 2 + 5 = 13 := by norm_num
-- Before the blow the car sits still: the switch u(t - 1) is off at t = 0.
example : carHeight 0 = 0 := by norm_num [carHeight]
-- Every pulse has area 1: strength 1/ε times width ε.
example : ∀ ε : ℝ, ε ≠ 0 → 1 / ε * ε = 1 := by intro ε hε; field_simp

#print axioms pulse_integral_tends_to_value_at_blow
#print axioms pulse_transform_tends_to_exp_neg_as
#print axioms struck_car_velocity_jumps_by_one_then_rings_down

end Impulses
