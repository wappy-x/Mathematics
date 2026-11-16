-- Levy's inversion formula: for every probability law on the real line, the cut-off integral of the fingerprint against the interval's spin-back tends to the chance of the open interval plus half the chance on each end, so the fingerprint fixes the law, and a fingerprint of finite area gives a continuous density.
import Mathlib.MeasureTheory.Measure.CharacteristicFunction.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Sinc
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.ExpDecay
import Mathlib.MeasureTheory.Integral.IntegralEqImproper

open MeasureTheory Filter Topology Complex Set

lemma levyInv_dir_inner_exp (x : ℝ) (hx : 0 < x) :
    (∫ t in Set.Ioi (0 : ℝ), Real.exp (-x * t)) = 1 / x := by
  rw [integral_exp_mul_Ioi (by linarith) 0]
  simp


#print axioms levyInv_dir_inner_exp

lemma levyInv_dir_inner_sin (R t : ℝ) :
    (∫ x in (0 : ℝ)..R, Real.sin x * Real.exp (-x * t)) =
      (1 - Real.exp (-R * t) * (t * Real.sin R + Real.cos R)) / (1 + t ^ 2) := by
  have ht : (1 + t ^ 2) ≠ 0 := by positivity
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun x : ℝ => -(Real.exp (-x * t) * (t * Real.sin x + Real.cos x)) / (1 + t ^ 2))]
  · simp only [neg_zero, zero_mul, Real.exp_zero, Real.sin_zero, Real.cos_zero, mul_zero,
      zero_add, one_mul]
    field_simp
    ring
  · intro x _
    have h1 := (((hasDerivAt_id' x).neg.mul_const t).exp)
    have h2 := ((Real.hasDerivAt_sin x).const_mul t).add (Real.hasDerivAt_cos x)
    have hd := ((h1.mul h2).neg).div_const (1 + t ^ 2)
    convert hd using 1
    simp only [Pi.neg_apply, Pi.add_apply]
    field_simp
    ring
  · exact (by fun_prop : Continuous fun x : ℝ => Real.sin x * Real.exp (-x * t)).intervalIntegrable _ _


#print axioms levyInv_dir_inner_sin

lemma levyInv_dir_integrable (R : ℝ) :
    Integrable (Function.uncurry fun x t : ℝ => Real.sin x * Real.exp (-x * t))
      ((volume.restrict (Set.Ioc (0 : ℝ) R)).prod (volume.restrict (Set.Ioi (0 : ℝ)))) := by
  have hc : Continuous (Function.uncurry fun x t : ℝ => Real.sin x * Real.exp (-x * t)) := by
    show Continuous (fun p : ℝ × ℝ => Real.sin p.1 * Real.exp (-p.1 * p.2))
    fun_prop
  refine (integrable_prod_iff hc.aestronglyMeasurable).mpr ⟨?_, ?_⟩
  · filter_upwards [ae_restrict_mem measurableSet_Ioc] with x hx
    exact (exp_neg_integrableOn_Ioi 0 hx.1).const_mul (Real.sin x)
  · have hint : Integrable (fun x : ℝ => |Real.sinc x|) (volume.restrict (Set.Ioc (0 : ℝ) R)) :=
      Continuous.integrableOn_Ioc (by fun_prop)
    refine hint.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioc] with x hx
    have hx0 : 0 < x := hx.1
    show |Real.sinc x| = ∫ t in Set.Ioi (0 : ℝ), ‖Real.sin x * Real.exp (-x * t)‖
    simp_rw [norm_mul, Real.norm_eq_abs, Real.abs_exp]
    rw [integral_const_mul, levyInv_dir_inner_exp x hx0, Real.sinc_of_ne_zero hx0.ne', abs_div,
      abs_of_pos hx0]
    ring


#print axioms levyInv_dir_integrable

lemma levyInv_dir_bound (R t : ℝ) :
    ‖Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)‖ ≤ 2 * Real.exp (-R * t) := by
  have ht : 0 < 1 + t ^ 2 := by positivity
  have he := Real.exp_pos (-R * t)
  rw [Real.norm_eq_abs, abs_div, abs_mul, Real.abs_exp, abs_of_pos ht, div_le_iff₀ ht]
  have h1 : |t * Real.sin R + Real.cos R| ≤ |t| + 1 := by
    calc |t * Real.sin R + Real.cos R| ≤ |t * Real.sin R| + |Real.cos R| := abs_add_le _ _
      _ ≤ |t| * 1 + 1 := by
        rw [abs_mul]
        gcongr
        · exact Real.abs_sin_le_one R
        · exact Real.abs_cos_le_one R
      _ = |t| + 1 := by ring
  have h2 : |t| ≤ 1 + t ^ 2 := by nlinarith [abs_nonneg t, sq_abs t]
  calc Real.exp (-R * t) * |t * Real.sin R + Real.cos R|
      ≤ Real.exp (-R * t) * (2 * (1 + t ^ 2)) := by
        apply mul_le_mul_of_nonneg_left _ he.le
        nlinarith [sq_nonneg t]
    _ = 2 * Real.exp (-R * t) * (1 + t ^ 2) := by ring


#print axioms levyInv_dir_bound

lemma levyInv_dir_partial (R : ℝ) (hR : 0 < R) :
    (∫ x in (0 : ℝ)..R, Real.sinc x) = Real.pi / 2 -
      ∫ t in Set.Ioi (0 : ℝ), Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2) := by
  have hk : IntegrableOn (fun t : ℝ =>
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) (Set.Ioi 0) := by
    refine Integrable.mono' ((exp_neg_integrableOn_Ioi 0 hR).const_mul 2) ?_
      (Eventually.of_forall fun t => levyInv_dir_bound R t)
    exact (Continuous.div (by fun_prop) (by fun_prop) (fun t => by positivity) : Continuous fun t : ℝ =>
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)).aestronglyMeasurable
  rw [intervalIntegral.integral_of_le hR.le]
  calc (∫ x in Set.Ioc 0 R, Real.sinc x)
      = ∫ x in Set.Ioc 0 R, ∫ t in Set.Ioi (0 : ℝ), Real.sin x * Real.exp (-x * t) := by
        refine setIntegral_congr_fun measurableSet_Ioc (fun x hx => ?_)
        have hx0 : 0 < x := hx.1
        rw [integral_const_mul, levyInv_dir_inner_exp x hx0, Real.sinc_of_ne_zero hx0.ne']
        ring
    _ = ∫ t in Set.Ioi (0 : ℝ), ∫ x in Set.Ioc 0 R, Real.sin x * Real.exp (-x * t) :=
        integral_integral_swap (levyInv_dir_integrable R)
    _ = ∫ t in Set.Ioi (0 : ℝ), ((1 + t ^ 2)⁻¹ -
          Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) := by
        refine integral_congr_ae (Eventually.of_forall fun t => ?_)
        simp only
        rw [← intervalIntegral.integral_of_le hR.le, levyInv_dir_inner_sin]
        ring
    _ = Real.pi / 2 - ∫ t in Set.Ioi (0 : ℝ),
          Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2) := by
        rw [integral_sub integrable_inv_one_add_sq.integrableOn hk, integral_Ioi_inv_one_add_sq,
          Real.arctan_zero, sub_zero]


#print axioms levyInv_dir_partial

lemma levyInv_dir_half : Tendsto (fun R : ℝ => ∫ x in (0 : ℝ)..R, Real.sinc x) atTop
    (𝓝 (Real.pi / 2)) := by
  have hE : Tendsto (fun R : ℝ => ∫ t in Set.Ioi (0 : ℝ),
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) atTop (𝓝 0) := by
    have h2 : Tendsto (fun R : ℝ => 2 * R⁻¹) atTop (𝓝 0) := by
      simpa using tendsto_inv_atTop_zero.const_mul (2 : ℝ)
    refine squeeze_zero_norm' ?_ h2
    filter_upwards [eventually_gt_atTop 0] with R hR
    calc _ ≤ ∫ t in Set.Ioi (0 : ℝ), 2 * Real.exp (-R * t) :=
          norm_integral_le_of_norm_le ((exp_neg_integrableOn_Ioi 0 hR).const_mul 2)
            (Eventually.of_forall fun t => levyInv_dir_bound R t)
      _ = 2 * R⁻¹ := by rw [integral_const_mul, levyInv_dir_inner_exp R hR, one_div]
  have := hE.const_sub (Real.pi / 2)
  rw [sub_zero] at this
  refine this.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with R hR
  rw [levyInv_dir_partial R hR]


#print axioms levyInv_dir_half

lemma levyInv_S_odd (y : ℝ) :
    ∫ u in (0:ℝ)..(-y), Real.sinc u = -∫ u in (0:ℝ)..y, Real.sinc u := by
  have h := intervalIntegral.integral_comp_neg (a := (0:ℝ)) (b := y) (f := Real.sinc)
  simp only [Real.sinc_neg, neg_zero] at h
  rw [intervalIntegral.integral_symm (-y) 0, ← h]

#print axioms levyInv_S_odd

lemma levyInv_S_abs_le (y : ℝ) : |∫ u in (0:ℝ)..y, Real.sinc u| ≤ |y| := by
  have := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := y) (C := 1)
    (f := Real.sinc) (fun x _ => by rw [Real.norm_eq_abs]; exact Real.abs_sinc_le_one x)
  simpa [Real.norm_eq_abs] using this

#print axioms levyInv_S_abs_le

lemma levyInv_S_bound_ge_one (y : ℝ) (hy : 1 ≤ y) : |∫ u in (0:ℝ)..y, Real.sinc u| ≤ 4 := by
  have hy0 : 0 < y := by linarith
  rw [levyInv_dir_partial y hy0]
  have hE : ‖∫ t in Set.Ioi (0 : ℝ),
      Real.exp (-y * t) * (t * Real.sin y + Real.cos y) / (1 + t ^ 2)‖ ≤ 2 * y⁻¹ := by
    calc _ ≤ ∫ t in Set.Ioi (0 : ℝ), 2 * Real.exp (-y * t) :=
          norm_integral_le_of_norm_le ((exp_neg_integrableOn_Ioi 0 hy0).const_mul 2)
            (Eventually.of_forall fun t => levyInv_dir_bound y t)
      _ = 2 * y⁻¹ := by rw [integral_const_mul, levyInv_dir_inner_exp y hy0, one_div]
  have h2 : 2 * y⁻¹ ≤ 2 := by have := inv_le_one_of_one_le₀ hy; linarith
  rw [Real.norm_eq_abs] at hE
  obtain ⟨h3, h4⟩ := abs_le.mp (hE.trans h2)
  have hpi := Real.pi_le_four
  have hpi0 := Real.pi_pos
  rw [abs_le]
  constructor <;> linarith

#print axioms levyInv_S_bound_ge_one

lemma levyInv_S_bound (y : ℝ) : |∫ u in (0:ℝ)..y, Real.sinc u| ≤ 4 := by
  rcases le_or_gt 1 y with h | h
  · exact levyInv_S_bound_ge_one y h
  rcases le_or_gt y (-1) with h' | h'
  · have := levyInv_S_bound_ge_one (-y) (by linarith)
    rwa [levyInv_S_odd, abs_neg] at this
  · have := levyInv_S_abs_le y
    have : |y| ≤ 1 := abs_le.mpr ⟨by linarith, by linarith⟩
    linarith

#print axioms levyInv_S_bound

lemma levyInv_S_cont : Continuous (fun y : ℝ => ∫ u in (0:ℝ)..y, Real.sinc u) :=
  intervalIntegral.continuous_primitive (fun a b => Real.continuous_sinc.intervalIntegrable a b) 0

#print axioms levyInv_S_cont

lemma levyInv_S_tendsto_pos (c : ℝ) (hc : 0 < c) :
    Tendsto (fun T : ℝ => ∫ u in (0:ℝ)..(c * T), Real.sinc u) atTop (𝓝 (Real.pi / 2)) :=
  levyInv_dir_half.comp (tendsto_id.const_mul_atTop hc)

#print axioms levyInv_S_tendsto_pos

lemma levyInv_S_tendsto_neg (c : ℝ) (hc : c < 0) :
    Tendsto (fun T : ℝ => ∫ u in (0:ℝ)..(c * T), Real.sinc u) atTop (𝓝 (-(Real.pi / 2))) := by
  refine (levyInv_S_tendsto_pos (-c) (by linarith)).neg.congr (fun T => ?_)
  rw [← levyInv_S_odd]
  congr 1
  ring

#print axioms levyInv_S_tendsto_neg

lemma levyInv_S_tendsto_zero (c : ℝ) (hc : c = 0) :
    Tendsto (fun T : ℝ => ∫ u in (0:ℝ)..(c * T), Real.sinc u) atTop (𝓝 0) := by
  subst hc
  simp

#print axioms levyInv_S_tendsto_zero

lemma levyInv_S_sym (y : ℝ) :
    ∫ u in (-y)..y, Real.sinc u = 2 * ∫ u in (0:ℝ)..y, Real.sinc u := by
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := 0)
    (Real.continuous_sinc.intervalIntegrable _ _) (Real.continuous_sinc.intervalIntegrable _ _)]
  have h := intervalIntegral.integral_comp_neg (a := (0:ℝ)) (b := y) (f := Real.sinc)
  simp only [Real.sinc_neg, neg_zero] at h
  rw [← h]
  ring

#print axioms levyInv_S_sym

lemma levyInv_K_eq (a b t : ℝ) (ht : t ≠ 0) :
    (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I) =
      ∫ y in a..b, cexp (-((t : ℂ) * y) * I) := by
  have hc : (-(t:ℂ) * I) ≠ 0 := by simp [ht]
  have h := integral_exp_mul_complex (a := a) (b := b) hc
  have e : ∀ y : ℝ, cexp (-((t : ℂ) * y) * I) = cexp ((-(t:ℂ) * I) * y) := fun y => by ring_nf
  simp_rw [e, h]
  have ht' : (t : ℂ) ≠ 0 := by exact_mod_cast ht
  field_simp
  ring

#print axioms levyInv_K_eq

lemma levyInv_norm_exp (u : ℝ) : ‖cexp ((u : ℂ) * I)‖ = 1 := norm_exp_ofReal_mul_I u

#print axioms levyInv_norm_exp

lemma levyInv_K_norm (a b t : ℝ) (hab : a ≤ b) :
    ‖(cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I)‖ ≤ b - a := by
  by_cases ht : t = 0
  · simp [ht]; linarith
  · rw [levyInv_K_eq a b t ht]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := a) (b := b) (C := 1)
      (f := fun y : ℝ => cexp (-((t : ℂ) * y) * I)) (fun y _ => by
        have e : -((t:ℂ) * y) = ((-(t*y) : ℝ) : ℂ) := by push_cast; ring
        rw [e, levyInv_norm_exp])
    rw [abs_of_nonneg (by linarith)] at this
    linarith

#print axioms levyInv_K_norm

lemma levyInv_K_meas (a b : ℝ) : Measurable (fun t : ℝ =>
    (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I)) := by
  fun_prop

#print axioms levyInv_K_meas

lemma levyInv_sin_div (c t : ℝ) (ht : t ≠ 0) : Real.sin (c * t) / t = c * Real.sinc (c * t) := by
  by_cases hc : c = 0
  · simp [hc]
  rw [Real.sinc_of_ne_zero (mul_ne_zero hc ht)]
  field_simp

#print axioms levyInv_sin_div

lemma levyInv_pair (a b x t : ℝ) (ht : t ≠ 0) :
    (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I) * cexp (t * x * I) +
    (cexp (-(((-t : ℝ) : ℂ) * a) * I) - cexp (-(((-t : ℝ) : ℂ) * b) * I)) / (((-t : ℝ) : ℂ) * I)
      * cexp (((-t : ℝ) : ℂ) * x * I) =
    ((2 * (Real.sin ((x - a) * t) - Real.sin ((x - b) * t)) / t : ℝ) : ℂ) := by
  have e : ∀ u v : ℝ, cexp (-((u:ℂ) * v) * I) * cexp (u * x * I) =
      (Real.cos ((x - v) * u) : ℂ) + (Real.sin ((x - v) * u) : ℂ) * I := by
    intro u v
    rw [← Complex.exp_add, ofReal_cos, ofReal_sin, ← Complex.exp_mul_I]
    congr 1; push_cast; ring
  rw [div_mul_eq_mul_div, div_mul_eq_mul_div, sub_mul, sub_mul, e, e, e, e]
  have n1 : (x - a) * -t = -((x - a) * t) := by ring
  have n2 : (x - b) * -t = -((x - b) * t) := by ring
  rw [n1, n2, Real.cos_neg, Real.cos_neg, Real.sin_neg, Real.sin_neg]
  have ht' : (t : ℂ) ≠ 0 := by exact_mod_cast ht
  push_cast
  field_simp
  ring_nf

#print axioms levyInv_pair

lemma levyInv_inner (a b x T : ℝ) (hab : a ≤ b) :
    ∫ t in -T..T, (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I)
      * cexp (t * x * I) =
    ((2 * ((∫ u in (0:ℝ)..((x - a) * T), Real.sinc u) -
      ∫ u in (0:ℝ)..((x - b) * T), Real.sinc u) : ℝ) : ℂ) := by
  set h : ℝ → ℂ := fun t => (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) /
    ((t : ℂ) * I) * cexp (t * x * I) with hh
  have hmeas : Measurable h := by
    simp only [hh]
    exact (levyInv_K_meas a b).mul (by fun_prop)
  have hbound : ∀ t, ‖h t‖ ≤ b - a := by
    intro t
    simp only [hh]
    rw [norm_mul, show ‖cexp (↑t * ↑x * I)‖ = 1 by rw [← ofReal_mul]; exact levyInv_norm_exp _,
      mul_one]
    exact levyInv_K_norm a b t hab
  have hint : IntervalIntegrable h volume (-T) T :=
    (intervalIntegrable_const (c := b - a)).mono_fun' hmeas.aestronglyMeasurable
      (Eventually.of_forall hbound)
  have hint' : IntervalIntegrable (fun t => h (-t)) volume (-T) T :=
    (intervalIntegrable_const (c := b - a)).mono_fun'
      (hmeas.comp measurable_neg).aestronglyMeasurable
      (Eventually.of_forall fun t => hbound (-t))
  have hsym : ∫ t in -T..T, h (-t) = ∫ t in -T..T, h t := by
    rw [intervalIntegral.integral_comp_neg, neg_neg]
  have hae : ∀ᵐ t : ℝ, t ≠ 0 := by
    rw [ae_iff]; simp
  have hsum : ∫ t in -T..T, (h t + h (-t)) =
      ∫ t in -T..T, ((2 * ((x - a) * Real.sinc ((x - a) * t) - (x - b) * Real.sinc ((x - b) * t))
        : ℝ) : ℂ) := by
    refine intervalIntegral.integral_congr_ae ?_
    filter_upwards [hae] with t ht _
    simp only [hh]
    rw [levyInv_pair a b x t ht, mul_sub, sub_div, mul_div_assoc, mul_div_assoc,
      levyInv_sin_div _ _ ht, levyInv_sin_div _ _ ht, mul_sub]
  have hc : ∀ c : ℝ, ∫ t in -T..T, c * Real.sinc (c * t) = 2 * ∫ u in (0:ℝ)..(c * T), Real.sinc u := by
    intro c
    rw [intervalIntegral.integral_const_mul, ← smul_eq_mul,
      intervalIntegral.smul_integral_comp_mul_left, mul_neg, levyInv_S_sym]
  have hreal : ∫ t in -T..T,
      (2 * ((x - a) * Real.sinc ((x - a) * t) - (x - b) * Real.sinc ((x - b) * t))) =
      2 * ((2 * ∫ u in (0:ℝ)..((x - a) * T), Real.sinc u) -
        (2 * ∫ u in (0:ℝ)..((x - b) * T), Real.sinc u)) := by
    rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_sub, hc, hc]
    · exact (by fun_prop : Continuous fun t => (x - a) * Real.sinc ((x - a) * t)).intervalIntegrable _ _
    · exact (by fun_prop : Continuous fun t => (x - b) * Real.sinc ((x - b) * t)).intervalIntegrable _ _
  have h2 : 2 * ∫ t in -T..T, h t = ((2 * (2 * ((∫ u in (0:ℝ)..((x - a) * T), Real.sinc u) -
      ∫ u in (0:ℝ)..((x - b) * T), Real.sinc u)) : ℝ) : ℂ) := by
    rw [two_mul]
    nth_rewrite 2 [← hsym]
    rw [← intervalIntegral.integral_add hint hint', hsum, intervalIntegral.integral_ofReal, hreal]
    congr 1
    ring
  have h2' : (2 : ℂ) ≠ 0 := two_ne_zero
  calc ∫ t in -T..T, h t = (2 * ∫ t in -T..T, h t) / 2 := by field_simp
    _ = _ := by rw [h2]; push_cast; ring

#print axioms levyInv_inner

lemma levyInv_pointwise (a b x : ℝ) (hab : a < b) :
    Tendsto (fun T : ℝ => 2 * ((∫ u in (0:ℝ)..((x - a) * T), Real.sinc u) -
      ∫ u in (0:ℝ)..((x - b) * T), Real.sinc u)) atTop
      (𝓝 (2 * Real.pi * (Ioo a b).indicator 1 x + Real.pi * ({a} : Set ℝ).indicator 1 x +
        Real.pi * ({b} : Set ℝ).indicator 1 x)) := by
  rcases lt_trichotomy x a with hxa | rfl | hxa
  · have h1 := levyInv_S_tendsto_neg (x - a) (by linarith)
    have h2 := levyInv_S_tendsto_neg (x - b) (by linarith)
    convert (h1.sub h2).const_mul 2 using 2
    have n1 : x ∉ Ioo a b := fun h => by linarith [h.1]
    have n2 : x ∉ ({a} : Set ℝ) := by simp; linarith
    have n3 : x ∉ ({b} : Set ℝ) := by simp; linarith
    simp [indicator_of_notMem n1, indicator_of_notMem n2, indicator_of_notMem n3]
  · have h1 := levyInv_S_tendsto_zero (x - x) (by ring)
    have h2 := levyInv_S_tendsto_neg (x - b) (by linarith)
    convert (h1.sub h2).const_mul 2 using 2
    have n3 : x ∉ ({b} : Set ℝ) := by simp; linarith
    simp [indicator_of_notMem n3]
    ring
  rcases lt_trichotomy x b with hxb | rfl | hxb
  · have h1 := levyInv_S_tendsto_pos (x - a) (by linarith)
    have h2 := levyInv_S_tendsto_neg (x - b) (by linarith)
    convert (h1.sub h2).const_mul 2 using 2
    have n1 : x ∈ Ioo a b := ⟨hxa, hxb⟩
    have n2 : x ∉ ({a} : Set ℝ) := by simp; linarith
    have n3 : x ∉ ({b} : Set ℝ) := by simp; linarith
    simp [indicator_of_mem n1, indicator_of_notMem n2, indicator_of_notMem n3]
  · have h1 := levyInv_S_tendsto_pos (x - a) (by linarith)
    have h2 := levyInv_S_tendsto_zero (x - x) (by ring)
    convert (h1.sub h2).const_mul 2 using 2
    have n2 : x ∉ ({a} : Set ℝ) := by simp; linarith
    simp [indicator_of_notMem n2]
    ring
  · have h1 := levyInv_S_tendsto_pos (x - a) (by linarith)
    have h2 := levyInv_S_tendsto_pos (x - b) (by linarith)
    convert (h1.sub h2).const_mul 2 using 2
    have n1 : x ∉ Ioo a b := fun h => by linarith [h.2]
    have n2 : x ∉ ({a} : Set ℝ) := by simp; linarith
    have n3 : x ∉ ({b} : Set ℝ) := by simp; linarith
    simp [indicator_of_notMem n1, indicator_of_notMem n2, indicator_of_notMem n3]

#print axioms levyInv_pointwise

lemma levyInv_norm_exp_neg (t x : ℝ) : ‖cexp (-((t : ℂ) * x) * I)‖ = 1 := by
  have e : -((t:ℂ) * x) = ((-(t*x) : ℝ) : ℂ) := by push_cast; ring
  rw [e, levyInv_norm_exp]

#print axioms levyInv_norm_exp_neg

/-- Levy's inversion formula, for any law at all: for ends `a < b`,
`(1/2π) ∫_{-T}^{T} (e^{-ita} - e^{-itb})/(it) φ_X(t) dt` tends, as the even cut-off `T`
grows, to `P(a < X < b) + ½ P(X = a) + ½ P(X = b)`. Here `φ_X = charFun μ` is the
fingerprint `t ↦ E[e^{itX}]` of the law `μ`. -/
theorem levy_inversion_formula (μ : Measure ℝ) [IsProbabilityMeasure μ] {a b : ℝ}
    (hab : a < b) :
    Tendsto
      (fun T : ℝ => (1 / (2 * Real.pi) : ℂ) *
        ∫ t in -T..T,
          (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I) * charFun μ t)
      atTop
      (𝓝 ((μ.real (Ioo a b) + μ.real {a} / 2 + μ.real {b} / 2 : ℝ) : ℂ)) := by
  set F : ℝ → ℝ → ℝ := fun T x => 2 * ((∫ u in (0:ℝ)..((x - a) * T), Real.sinc u) -
      ∫ u in (0:ℝ)..((x - b) * T), Real.sinc u) with hF
  set g : ℝ → ℝ := fun x => 2 * Real.pi * (Ioo a b).indicator 1 x +
    Real.pi * ({a} : Set ℝ).indicator 1 x + Real.pi * ({b} : Set ℝ).indicator 1 x with hg
  have hfub : ∀ T, 0 ≤ T → ∫ t in -T..T,
      (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I) * charFun μ t =
      ((∫ x, F T x ∂μ : ℝ) : ℂ) := by
    intro T hT
    simp_rw [charFun_apply_real, ← integral_const_mul]
    rw [intervalIntegral_integral_swap]
    · rw [show ((∫ x, F T x ∂μ : ℝ) : ℂ) = ∫ x, ((F T x : ℝ) : ℂ) ∂μ from integral_ofReal.symm]
      congr 1
      ext x
      exact levyInv_inner a b x T hab.le
    · rw [uIoc_of_le (by linarith)]
      refine Integrable.mono' (integrable_const (b - a)) ?_ (Eventually.of_forall ?_)
      · exact (((levyInv_K_meas a b).comp measurable_fst).mul
          (by fun_prop)).aestronglyMeasurable
      · intro p
        simp only [Function.uncurry]
        rw [norm_mul, show ‖cexp (↑p.1 * ↑p.2 * I)‖ = 1 by
          rw [← ofReal_mul]; exact levyInv_norm_exp _, mul_one]
        exact levyInv_K_norm a b p.1 hab.le
  have hlim : Tendsto (fun T => ∫ x, F T x ∂μ) atTop (𝓝 (∫ x, g x ∂μ)) := by
    refine tendsto_integral_filter_of_dominated_convergence (fun _ => 16) ?_ ?_
      (integrable_const _) (Eventually.of_forall fun x => levyInv_pointwise a b x hab)
    · refine Eventually.of_forall fun T => Continuous.aestronglyMeasurable ?_
      simp only [hF]
      have := levyInv_S_cont
      fun_prop
    · refine Eventually.of_forall fun T => Eventually.of_forall fun x => ?_
      simp only [hF, Real.norm_eq_abs, abs_mul]
      have h1 := levyInv_S_bound ((x - a) * T)
      have h2 := levyInv_S_bound ((x - b) * T)
      have h3 := abs_sub (∫ u in (0:ℝ)..((x - a) * T), Real.sinc u)
        (∫ u in (0:ℝ)..((x - b) * T), Real.sinc u)
      rw [abs_two]
      linarith
  have hgint : ∫ x, g x ∂μ = 2 * Real.pi * μ.real (Ioo a b) + Real.pi * μ.real {a} +
      Real.pi * μ.real {b} := by
    have i1 : Integrable (fun x => (Ioo a b).indicator (1 : ℝ → ℝ) x) μ :=
      (integrable_const (1 : ℝ)).indicator measurableSet_Ioo
    have i2 : Integrable (fun x => ({a} : Set ℝ).indicator (1 : ℝ → ℝ) x) μ :=
      (integrable_const (1 : ℝ)).indicator (measurableSet_singleton a)
    have i3 : Integrable (fun x => ({b} : Set ℝ).indicator (1 : ℝ → ℝ) x) μ :=
      (integrable_const (1 : ℝ)).indicator (measurableSet_singleton b)
    simp only [hg]
    rw [integral_add ?_ (i3.const_mul _),
      integral_add (i1.const_mul _) (i2.const_mul _), integral_const_mul, integral_const_mul,
      integral_const_mul, integral_indicator_one measurableSet_Ioo,
      integral_indicator_one (measurableSet_singleton a),
      integral_indicator_one (measurableSet_singleton b)]
    exact (i1.const_mul _).add (i2.const_mul _)
  have hfin := ((continuous_ofReal.tendsto _).comp hlim).const_mul (1 / (2 * Real.pi) : ℂ)
  have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  convert hfin.congr' ?_ using 2
  · rw [hgint]
    push_cast
    field_simp
  · filter_upwards [eventually_ge_atTop 0] with T hT
    simp only [Function.comp_apply]
    rw [hfub T hT]

/-- Uniqueness: two laws whose fingerprints agree at every rate `t` are the same law. -/
theorem charFun_determines_law (μ ν : Measure ℝ) [IsProbabilityMeasure μ]
    [IsProbabilityMeasure ν] (h : ∀ t : ℝ, charFun μ t = charFun ν t) : μ = ν := by
  exact Measure.ext_of_charFun (funext h)

/-- The density formula: if the fingerprint has finite area, `∫ |φ_X(t)| dt < ∞`, then
`f(x) = (1/2π) ∫ e^{-itx} φ_X(t) dt` is continuous and is a density of the law:
`F(b) - F(a) = P(a < X ≤ b) = ∫_a^b f(x) dx` for all `a ≤ b`. -/
theorem density_of_integrable_charFun (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (hint : Integrable (charFun μ)) :
    Continuous (fun x : ℝ => (1 / (2 * Real.pi) : ℂ) *
        ∫ t : ℝ, cexp (-((t : ℂ) * x) * I) * charFun μ t) ∧
    ∀ a b : ℝ, a ≤ b →
      ((μ.real (Ioc a b) : ℝ) : ℂ) =
        ∫ x in a..b, (1 / (2 * Real.pi) : ℂ) *
          ∫ t : ℝ, cexp (-((t : ℂ) * x) * I) * charFun μ t := by
  have hmφ : Measurable (charFun μ) := measurable_charFun
  have hae : ∀ᵐ t : ℝ, t ≠ 0 := by
    rw [ae_iff]; simp
  have hcont : Continuous (fun x : ℝ => ∫ t : ℝ, cexp (-((t : ℂ) * x) * I) * charFun μ t) := by
    refine continuous_of_dominated (bound := fun t => ‖charFun μ t‖)
      (fun x => ((by fun_prop : Measurable fun t : ℝ => cexp (-((t : ℂ) * x) * I)).mul
        hmφ).aestronglyMeasurable) (fun x => ae_of_all _ fun t => ?_) hint.norm
      (ae_of_all _ fun t => by fun_prop)
    rw [norm_mul, levyInv_norm_exp_neg, one_mul]
  refine ⟨continuous_const.mul hcont, ?_⟩
  set C : ℝ := (1 / (2 * Real.pi)) * ∫ t, ‖charFun μ t‖ with hCdef
  have hC0 : 0 ≤ C := by
    have := Real.pi_pos
    exact mul_nonneg (by positivity) (integral_nonneg fun t => norm_nonneg _)
  have hfb : ∀ x : ℝ, ‖(1 / (2 * Real.pi) : ℂ) *
      ∫ t : ℝ, cexp (-((t : ℂ) * x) * I) * charFun μ t‖ ≤ C := by
    intro x
    have := Real.pi_pos
    rw [norm_mul, hCdef]
    have e : ‖(1 / (2 * Real.pi) : ℂ)‖ = 1 / (2 * Real.pi) := by
      rw [show (1 / (2 * Real.pi) : ℂ) = ((1 / (2 * Real.pi) : ℝ) : ℂ) by push_cast; ring,
        Complex.norm_real, Real.norm_eq_abs, abs_of_pos (by positivity)]
    rw [e]
    refine mul_le_mul_of_nonneg_left ?_ (by positivity)
    refine (norm_integral_le_integral_norm _).trans (le_of_eq ?_)
    congr 1
    ext t
    rw [norm_mul, levyInv_norm_exp_neg, one_mul]
  have hkey : ∀ a b : ℝ, a < b →
      ∫ x in a..b, (1 / (2 * Real.pi) : ℂ) * ∫ t : ℝ, cexp (-((t : ℂ) * x) * I) * charFun μ t =
      ((μ.real (Ioo a b) + μ.real {a} / 2 + μ.real {b} / 2 : ℝ) : ℂ) := by
    intro a b hab
    have hKm : Measurable (fun t : ℝ =>
        (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I) * charFun μ t) :=
      (levyInv_K_meas a b).mul hmφ
    have hKint : Integrable (fun t : ℝ =>
        (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I) * charFun μ t) := by
      refine (hint.norm.const_mul (b - a)).mono' hKm.aestronglyMeasurable
        (ae_of_all _ fun t => ?_)
      rw [norm_mul]
      exact mul_le_mul_of_nonneg_right (levyInv_K_norm a b t hab.le) (norm_nonneg _)
    have h1 : ∫ x in a..b, (1 / (2 * Real.pi) : ℂ) *
        ∫ t : ℝ, cexp (-((t : ℂ) * x) * I) * charFun μ t =
        (1 / (2 * Real.pi) : ℂ) * ∫ t : ℝ,
          (cexp (-((t : ℂ) * a) * I) - cexp (-((t : ℂ) * b) * I)) / ((t : ℂ) * I) * charFun μ t := by
      rw [intervalIntegral.integral_const_mul, intervalIntegral_integral_swap]
      · congr 1
        refine integral_congr_ae ?_
        filter_upwards [hae] with t ht
        rw [intervalIntegral.integral_mul_const, ← levyInv_K_eq a b t ht]
      · rw [uIoc_of_le hab.le]
        refine Integrable.mono' ((integrable_const (1 : ℝ)).mul_prod hint.norm) ?_
          (ae_of_all _ fun p => ?_)
        · exact (((by fun_prop : Measurable fun p : ℝ × ℝ => cexp (-((p.2 : ℂ) * p.1) * I))).mul
            (hmφ.comp measurable_snd)).aestronglyMeasurable
        · simp only [Function.uncurry]
          rw [norm_mul, levyInv_norm_exp_neg, one_mul]
    have h2 := (intervalIntegral_tendsto_integral hKint tendsto_neg_atTop_atBot
      tendsto_id).const_mul (1 / (2 * Real.pi) : ℂ)
    rw [h1]
    exact tendsto_nhds_unique h2 (levy_inversion_formula μ hab)
  have hatom : ∀ a : ℝ, μ.real {a} = 0 := by
    intro a
    have hle : ∀ ε > 0, μ.real {a} / 2 ≤ C * ε := by
      intro ε hε
      have hn := intervalIntegral.norm_integral_le_of_norm_le_const (a := a) (b := a + ε)
        (fun x _ => hfb x)
      rw [hkey a (a + ε) (by linarith), Complex.norm_real, Real.norm_eq_abs,
        abs_of_nonneg (by positivity), show a + ε - a = ε by ring, abs_of_pos hε] at hn
      have : 0 ≤ μ.real (Ioo a (a + ε)) := measureReal_nonneg
      have : 0 ≤ μ.real {a + ε} := measureReal_nonneg
      linarith
    refine le_antisymm ?_ measureReal_nonneg
    by_contra hpos
    rw [not_le] at hpos
    have h := hle (μ.real {a} / (4 * (C + 1))) (by positivity)
    have h4 : C * (μ.real {a} / (4 * (C + 1))) < μ.real {a} / 2 := by
      rw [mul_div_assoc', div_lt_div_iff₀ (by positivity) (by norm_num)]
      nlinarith
    linarith
  intro a b hab
  rcases hab.lt_or_eq with hab | rfl
  · rw [hkey a b hab, hatom a, hatom b]
    have hb0 : μ {b} = 0 := (measureReal_eq_zero_iff).mp (hatom b)
    rw [measureReal_congr (Ioo_ae_eq_Ioc' hb0).symm]
    simp
  · simp

-- The die with ends 2 and 5: faces 3 and 4 lie strictly inside.
example : ((Finset.Icc 1 6).filter (fun k => 2 < k ∧ k < 5)).card = 2 := by decide

-- Levy's limit on the die, ends 2 and 5: inside 2/6, plus half of 1/6 on each end, is 1/2.
example : (2 : ℚ) / 6 + (1 / 2) * (1 / 6) + (1 / 2) * (1 / 6) = 1 / 2 := by norm_num

-- The die, ends 2 and 5, both ends counted: P(2 ≤ X ≤ 5) = 4/6 = 2/3.
example : ((Finset.Icc 1 6).filter (fun k => 2 ≤ k ∧ k ≤ 5)).card = 4 := by decide
example : (4 : ℚ) / 6 = 2 / 3 := by norm_num

-- The rounding error, uniform with density 1 on [-1/2, 1/2], ends -1/4 and 1/4:
-- the chance is the length, 1/4 - (-1/4) = 1/2.
example : (1 : ℚ) / 4 - (-(1 / 4)) = 1 / 2 := by norm_num

#print axioms levy_inversion_formula
#print axioms charFun_determines_law
#print axioms density_of_integrable_charFun
