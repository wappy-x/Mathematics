-- Adaptive quadrature and awkward integrals: the substitutions x = u/(1-u) and x = u^m turn an infinite range or an end spike into an integral on (0, 1) with a bounded integrand.
import Mathlib.MeasureTheory.Function.JacobianOneDim
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory Set

/-- An infinite range becomes a finite one: substituting x = u/(1-u) gives
∫₀^∞ f(x) dx = ∫₀¹ f(u/(1-u)) / (1-u)² du, and when f(x) falls at least as fast as
1/(1+x)², with |f(x)| ≤ C/(1+x)², the new integrand f(x)(1+x)² stays below C on [0, 1). -/
theorem infinite_range_substitution (f : ℝ → ℝ) (C : ℝ)
    (hf : ∀ x, 0 ≤ x → |f x| ≤ C / (1 + x) ^ 2) :
    (∫ x in Ioi (0 : ℝ), f x) = ∫ u in Ioo (0 : ℝ) 1, f (u / (1 - u)) / (1 - u) ^ 2 ∧
      ∀ u ∈ Ico (0 : ℝ) 1, |f (u / (1 - u)) / (1 - u) ^ 2| ≤ C := by
  constructor
  · have himg : (fun u : ℝ => u / (1 - u)) '' Ioo (0 : ℝ) 1 = Ioi 0 := by
      ext x
      simp only [mem_image, mem_Ioo, mem_Ioi]
      constructor
      · rintro ⟨u, ⟨h0, h1⟩, rfl⟩
        exact div_pos h0 (by linarith)
      · intro hx
        refine ⟨x / (1 + x), ⟨div_pos hx (by linarith), ?_⟩, ?_⟩
        · rw [div_lt_one (by linarith)]; linarith
        · have h1 : (1 + x) ≠ 0 := by linarith
          have h2 : 1 - x / (1 + x) = 1 / (1 + x) := by field_simp; ring
          rw [h2]; field_simp
    have hderiv : ∀ u ∈ Ioo (0 : ℝ) 1,
        HasDerivWithinAt (fun u : ℝ => u / (1 - u)) (1 / (1 - u) ^ 2) (Ioo 0 1) u := by
      intro u hu
      have hne : (1 - u) ≠ 0 := by linarith [hu.2]
      have h1 : HasDerivAt (fun y : ℝ => 1 - y) (-1) u := by
        simpa using (hasDerivAt_id u).const_sub (1:ℝ)
      have := (hasDerivAt_id' u).div h1 hne
      apply HasDerivAt.hasDerivWithinAt
      convert this using 1
      field_simp; ring
    have hinj : InjOn (fun u : ℝ => u / (1 - u)) (Ioo 0 1) := by
      intro u hu v hv huv
      have hu' : (1 - u) ≠ 0 := by linarith [hu.2]
      have hv' : (1 - v) ≠ 0 := by linarith [hv.2]
      simp only at huv
      rw [div_eq_div_iff hu' hv'] at huv
      linarith
    have key := integral_image_eq_integral_abs_deriv_smul measurableSet_Ioo hderiv hinj f
    rw [himg] at key
    rw [key]
    refine setIntegral_congr_fun measurableSet_Ioo (fun u hu => ?_)
    have hpos : 0 < 1 / (1 - u) ^ 2 := by
      have : 0 < 1 - u := by linarith [hu.2]
      positivity
    simp only [smul_eq_mul, abs_of_pos hpos]
    ring
  · intro u hu
    have hpos : 0 < 1 - u := by linarith [hu.2]
    have hx : 0 ≤ u / (1 - u) := div_nonneg hu.1 hpos.le
    have h := hf _ hx
    have he : 1 + u / (1 - u) = 1 / (1 - u) := by field_simp; ring
    rw [he] at h
    have h2 : C / (1 / (1 - u)) ^ 2 = C * (1 - u) ^ 2 := by field_simp
    rw [h2] at h
    rw [abs_div, abs_of_pos (by positivity : (0:ℝ) < (1 - u) ^ 2), div_le_iff₀ (by positivity)]
    exact h

/-- An end spike, by the substitution x = u²: ∫₀¹ f(x) dx = ∫₀¹ f(u²) · 2u du. -/
theorem end_spike_substitution (f : ℝ → ℝ) :
    (∫ x in Ioo (0 : ℝ) 1, f x) = ∫ u in Ioo (0 : ℝ) 1, f (u ^ 2) * (2 * u) := by
  have himg : (fun u : ℝ => u ^ 2) '' Ioo (0 : ℝ) 1 = Ioo 0 1 := by
    ext x
    simp only [mem_image, mem_Ioo]
    constructor
    · rintro ⟨u, ⟨h0, h1⟩, rfl⟩
      exact ⟨by positivity, by nlinarith⟩
    · rintro ⟨h0, h1⟩
      refine ⟨Real.sqrt x, ⟨Real.sqrt_pos.2 h0, ?_⟩, Real.sq_sqrt h0.le⟩
      rw [Real.sqrt_lt' one_pos]; linarith
  have hderiv : ∀ u ∈ Ioo (0 : ℝ) 1,
      HasDerivWithinAt (fun u : ℝ => u ^ 2) (2 * u) (Ioo 0 1) u := by
    intro u _
    have := hasDerivAt_pow 2 u
    apply HasDerivAt.hasDerivWithinAt
    convert this using 1
    ring
  have hinj : InjOn (fun u : ℝ => u ^ 2) (Ioo 0 1) := by
    intro u hu v hv huv
    simp only at huv
    exact (pow_left_inj₀ hu.1.le hv.1.le two_ne_zero).1 huv
  have key := integral_image_eq_integral_abs_deriv_smul measurableSet_Ioo hderiv hinj f
  rw [himg] at key
  rw [key]
  refine setIntegral_congr_fun measurableSet_Ioo (fun u hu => ?_)
  have hpos : 0 < 2 * u := by linarith [hu.1]
  simp only [smul_eq_mul, abs_of_pos hpos]
  ring

/-- A spike x^(-p) with 0 < p < 1 becomes bounded under x = u^m once m(1-p) ≥ 1:
the new integrand (u^m)^(-p) · m u^(m-1) equals m u^(m(1-p)-1), it lies between 0 and m
on (0, 1], and its integral over (0, 1) equals the integral of x^(-p). -/
theorem power_substitution_bounds_spike (p m : ℝ) (hp0 : 0 < p) (hp1 : p < 1)
    (hm : 1 ≤ m * (1 - p)) :
    (∫ x in Ioo (0 : ℝ) 1, x ^ (-p)) = ∫ u in Ioo (0 : ℝ) 1, m * u ^ (m * (1 - p) - 1) ∧
      ∀ u ∈ Ioc (0 : ℝ) 1,
        (u ^ m) ^ (-p) * (m * u ^ (m - 1)) = m * u ^ (m * (1 - p) - 1) ∧
          0 ≤ m * u ^ (m * (1 - p) - 1) ∧ m * u ^ (m * (1 - p) - 1) ≤ m := by
  have hm0 : 0 < m := by
    by_contra h
    have h' : m ≤ 0 := le_of_not_gt h
    nlinarith
  have hid : ∀ u : ℝ, 0 < u →
      (u ^ m) ^ (-p) * (m * u ^ (m - 1)) = m * u ^ (m * (1 - p) - 1) := by
    intro u hu
    rw [← Real.rpow_mul hu.le, mul_left_comm, ← Real.rpow_add hu]
    congr 2
    ring
  refine ⟨?_, fun u hu => ⟨hid u hu.1, ?_, ?_⟩⟩
  · have himg : (fun u : ℝ => u ^ m) '' Ioo (0 : ℝ) 1 = Ioo 0 1 := by
      ext x
      simp only [mem_image, mem_Ioo]
      constructor
      · rintro ⟨u, ⟨h0, h1⟩, rfl⟩
        exact ⟨Real.rpow_pos_of_pos h0 m, Real.rpow_lt_one h0.le h1 hm0⟩
      · rintro ⟨h0, h1⟩
        refine ⟨x ^ (1 / m), ⟨Real.rpow_pos_of_pos h0 _, Real.rpow_lt_one h0.le h1 (by positivity)⟩, ?_⟩
        rw [← Real.rpow_mul h0.le, one_div_mul_cancel hm0.ne', Real.rpow_one]
    have hderiv : ∀ u ∈ Ioo (0 : ℝ) 1,
        HasDerivWithinAt (fun u : ℝ => u ^ m) (m * u ^ (m - 1)) (Ioo 0 1) u := by
      intro u hu
      exact (Real.hasDerivAt_rpow_const (Or.inl hu.1.ne')).hasDerivWithinAt
    have hinj : InjOn (fun u : ℝ => u ^ m) (Ioo 0 1) := by
      intro u hu v hv huv
      simp only at huv
      have := congrArg (fun y => y ^ (1 / m)) huv
      rwa [← Real.rpow_mul hu.1.le, ← Real.rpow_mul hv.1.le, mul_one_div_cancel hm0.ne',
        Real.rpow_one, Real.rpow_one] at this
    have key := integral_image_eq_integral_abs_deriv_smul measurableSet_Ioo hderiv hinj
      (fun x : ℝ => x ^ (-p))
    rw [himg] at key
    rw [key]
    refine setIntegral_congr_fun measurableSet_Ioo (fun u hu => ?_)
    have hpos : 0 < m * u ^ (m - 1) := mul_pos hm0 (Real.rpow_pos_of_pos hu.1 _)
    simp only [smul_eq_mul, abs_of_pos hpos]
    rw [mul_comm]
    exact hid u hu.1
  · exact mul_nonneg hm0.le (Real.rpow_nonneg hu.1.le _)
  · have : u ^ (m * (1 - p) - 1) ≤ 1 := Real.rpow_le_one hu.1.le hu.2 (by linarith)
    nlinarith

-- 1/sqrt(x) is the spike p = 1/2; m = 2 gives m(1-p) = 1, so the new integrand is the constant 2.
example : (2 : ℚ) * (1 - 1 / 2) = 1 := by norm_num
example : (2 : ℚ) * (1 - 1 / 2) - 1 = 0 := by norm_num
-- Function values: 15 × (2 × panels − 1) at tolerances 1e-3, 1e-6, 1e-9, 1e-12.
example : 15 * (2 * 9 - 1) = 255 := by decide
example : 15 * (2 * 11 - 1) = 315 := by decide
example : 15 * (2 * 14 - 1) = 405 := by decide
example : 15 * (2 * 25 - 1) = 735 := by decide
-- Uniform panels: 32 panels of 15 values; the 24-hour start ends with 32 panels: 15 × (2 × 32 − 24).
example : 15 * 32 = 480 := by decide
example : 15 * (2 * 32 - 24) = 600 := by decide
-- Sampling density: 15 points over 3/4 hour near 18:00, over 12 hours at night.
example : (15 : ℚ) / (3 / 4) = 20 := by norm_num
example : (15 : ℚ) / 12 = 5 / 4 := by norm_num
-- Ten-minute readings over a day: 144 steps, 145 values.
example : 24 * 6 + 1 = 145 := by decide

#print axioms infinite_range_substitution
#print axioms end_spike_substitution
#print axioms power_substitution_bounds_spike
