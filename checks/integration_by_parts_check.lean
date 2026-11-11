-- Integration by parts: for u and v with continuous rates on a closed interval, the integral of u times the rate of v is the change in u v between the ends minus the integral of v times the rate of u, and this gives the card's reduction formula and its two areas of 1.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Set Real

/-- Integration by parts. Let u and v have continuous rates u' and v' on the closed interval
from a to b (one-sided rates at the two ends). Then the integral of u times v' from a to b
equals the product's change between the ends, u(b) v(b) - u(a) v(a), minus the integral with
the roles swapped, v times u'. -/
theorem integration_by_parts (a b : ℝ) (hab : a ≤ b) (u v u' v' : ℝ → ℝ)
    (hu : ∀ x ∈ Icc a b, HasDerivWithinAt u (u' x) (Icc a b) x)
    (hv : ∀ x ∈ Icc a b, HasDerivWithinAt v (v' x) (Icc a b) x)
    (hu' : ContinuousOn u' (Icc a b)) (hv' : ContinuousOn v' (Icc a b)) :
    ∫ x in a..b, u x * v' x = (u b * v b - u a * v a) - ∫ x in a..b, v x * u' x := by
  have hab' : uIcc a b = Icc a b := uIcc_of_le hab
  have hu'' : ∀ x ∈ uIcc a b, HasDerivWithinAt u (u' x) (uIcc a b) x := by
    rw [hab']; exact hu
  have hv'' : ∀ x ∈ uIcc a b, HasDerivWithinAt v (v' x) (uIcc a b) x := by
    rw [hab']; exact hv
  have hui : IntervalIntegrable u' MeasureTheory.volume a b :=
    (hab' ▸ hu').intervalIntegrable
  have hvi : IntervalIntegrable v' MeasureTheory.volume a b :=
    (hab' ▸ hv').intervalIntegrable
  rw [intervalIntegral.integral_mul_deriv_eq_deriv_mul_of_hasDerivWithinAt hu'' hv'' hui hvi]
  congr 1
  refine intervalIntegral.integral_congr fun x _ => ?_
  simp only [mul_comm]

/-- The reduction formula. Write J_n for the area under x^n e^x from 0 to 1. The start is
J_0 = e - 1, and for every whole number n from 1 up, J_n = e - n J_(n-1). -/
theorem reduction_formula_x_pow_mul_exp :
    (∫ x in (0 : ℝ)..1, x ^ 0 * exp x) = exp 1 - 1 ∧
    ∀ n : ℕ, 1 ≤ n →
      (∫ x in (0 : ℝ)..1, x ^ n * exp x) = exp 1 - n * ∫ x in (0 : ℝ)..1, x ^ (n - 1) * exp x := by
  refine ⟨?_, fun n hn => ?_⟩
  · simp [integral_exp]
  · have key := intervalIntegral.integral_mul_deriv_eq_deriv_mul (a := (0:ℝ)) (b := 1)
      (u := fun x : ℝ => x ^ n) (v := exp) (u' := fun x : ℝ => (n : ℝ) * x ^ (n - 1)) (v' := exp)
      (fun x _ => hasDerivAt_pow n x) (fun x _ => hasDerivAt_exp x)
      (by apply Continuous.intervalIntegrable; fun_prop)
      (by apply Continuous.intervalIntegrable; fun_prop)
    rw [key]
    have : (∫ x in (0:ℝ)..1, (n : ℝ) * x ^ (n - 1) * exp x)
        = (n : ℝ) * ∫ x in (0:ℝ)..1, x ^ (n - 1) * exp x := by
      rw [← intervalIntegral.integral_const_mul]
      refine intervalIntegral.integral_congr fun x _ => ?_
      simp only [mul_assoc]
    rw [this]
    simp [one_pow, exp_zero]; omega

/-- The card's two worked areas are both exactly 1 square unit: the area under x e^x from 0 to 1,
and the area under ln x from 1 to e. -/
theorem area_x_mul_exp_and_area_log_eq_one :
    (∫ x in (0 : ℝ)..1, x * exp x) = 1 ∧ (∫ x in (1 : ℝ)..exp 1, log x) = 1 := by
  refine ⟨?_, ?_⟩
  · have h := (reduction_formula_x_pow_mul_exp.2 1 le_rfl)
    simp only [pow_one, Nat.cast_one, one_mul, Nat.sub_self, pow_zero] at h
    rw [h, integral_exp]
    simp
  · rw [integral_log]
    simp

#print axioms integration_by_parts
#print axioms reduction_formula_x_pow_mul_exp
#print axioms area_x_mul_exp_and_area_log_eq_one
