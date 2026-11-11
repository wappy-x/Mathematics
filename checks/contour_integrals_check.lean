-- Contour integrals: round the unit circle the integral of z^n dz is 2πi when n = −1 and 0 for every other whole number n, the conjugate's lap round a circle of radius R is 2πiR², and along a path with finitely many smooth pieces the integral's size is at most M times the length.
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

open Complex MeasureTheory Set ComplexConjugate

/-- Round the unit circle, run once anticlockwise, a whole power of z integrates to 2πi
when the power is −1 (that is, 1/z) and to 0 for every other whole number n. -/
theorem circle_integral_zpow_unit_circle (n : ℤ) :
    (∮ z in C(0, 1), z ^ n) = if n = -1 then 2 * Real.pi * I else 0 := by
  split_ifs with hn
  · subst hn
    have h := circleIntegral.integral_sub_inv_of_mem_ball (c := 0) (w := 0) (R := 1)
      (by simp)
    simpa using h
  · have h := circleIntegral.integral_sub_zpow_of_ne hn 0 0 1
    simpa using h

/-- The conjugate z̄ integrated once anticlockwise round the circle of radius R centred at 0
gives 2πiR²; on the unit circle, where z̄ = 1/z, this is 2πi. -/
theorem circle_integral_conj (R : ℝ) :
    (∮ z in C(0, R), conj z) = 2 * Real.pi * I * (R : ℂ) ^ 2 := by
  unfold circleIntegral
  have key : ∀ θ : ℝ, deriv (circleMap 0 R) θ • conj (circleMap 0 R θ) = I * (R : ℂ) ^ 2 := by
    intro θ
    rw [deriv_circleMap, smul_eq_mul, mul_comm (circleMap 0 R θ) I, mul_assoc, Complex.mul_conj,
      Complex.normSq_eq_norm_sq, norm_circleMap_zero]
    push_cast
    rw [← Complex.ofReal_pow, sq_abs, Complex.ofReal_pow]
  simp_rw [key]
  rw [intervalIntegral.integral_const, sub_zero, Complex.real_smul]
  push_cast
  ring

/-- The ML bound. A path z(t), a ≤ t ≤ b, made of finitely many smooth pieces (velocity z'
off a finite set of corners), with f continuous on the path and |f| ≤ M everywhere on it:
the contour integral ∫ f(z(t)) z'(t) dt has size at most M times the length ∫ |z'(t)| dt. -/
theorem norm_contour_integral_le_ml (f : ℂ → ℂ) (z z' : ℝ → ℂ) (a b M : ℝ) (s : Finset ℝ)
    (hab : a ≤ b) (hz : ContinuousOn z (Icc a b))
    (hderiv : ∀ t ∈ Ioo a b \ (s : Set ℝ), HasDerivAt z (z' t) t)
    (hz' : IntervalIntegrable z' volume a b)
    (hf : ContinuousOn f (z '' Icc a b))
    (hM : ∀ t ∈ Icc a b, ‖f (z t)‖ ≤ M) :
    ‖∫ t in a..b, f (z t) * z' t‖ ≤ M * ∫ t in a..b, ‖z' t‖ := by
  have hint : IntervalIntegrable (fun t => M * ‖z' t‖) volume a b := hz'.norm.const_mul M
  rw [← intervalIntegral.integral_const_mul]
  refine intervalIntegral.norm_integral_le_of_norm_le hab (Filter.Eventually.of_forall ?_) hint
  intro t ht
  rw [norm_mul]
  exact mul_le_mul_of_nonneg_right (hM t (Ioc_subset_Icc_self ht)) (norm_nonneg _)

#print axioms circle_integral_zpow_unit_circle
#print axioms circle_integral_conj
#print axioms norm_contour_integral_le_ml
