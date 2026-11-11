-- The Gaussian integral: the area under e to the minus x squared over the whole real line is the square root of pi, and the bell curve with peak height one over the square root of 2 pi has area exactly 1.
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open Real MeasureTheory Filter Topology

/-- The area under `e^(-x^2)` over the whole real line exists and is the square root of π:
the function is integrable, its integral is `√π`, and the cutoff areas from `-R` to `R`
head for `√π` as `R` heads for infinity. -/
theorem integral_exp_neg_sq_eq_sqrt_pi :
    Integrable (fun x : ℝ => exp (-x ^ 2)) ∧
    ∫ x : ℝ, exp (-x ^ 2) = √π ∧
    Tendsto (fun R : ℝ => ∫ x in (-R)..R, exp (-x ^ 2)) atTop (𝓝 (√π)) := by
  have hi : Integrable (fun x : ℝ => exp (-x ^ 2)) := by
    simpa using integrable_exp_neg_mul_sq (b := 1) one_pos
  have hv : ∫ x : ℝ, exp (-x ^ 2) = √π := by
    simpa using integral_gaussian 1
  refine ⟨hi, hv, ?_⟩
  rw [← hv]
  exact intervalIntegral_tendsto_integral hi (tendsto_neg_atTop_atBot) tendsto_id

/-- For any positive squeeze factor `a`, the area under `e^(-a x^2)` over the whole real line
exists and is the square root of `π / a`. -/
theorem integral_exp_neg_mul_sq_eq_sqrt_pi_div {a : ℝ} (ha : 0 < a) :
    Integrable (fun x : ℝ => exp (-a * x ^ 2)) ∧
    ∫ x : ℝ, exp (-a * x ^ 2) = √(π / a) := by
  exact ⟨integrable_exp_neg_mul_sq ha, integral_gaussian a⟩

/-- The bell curve `e^(-x^2/2) / √(2π)` has total area exactly 1 over the whole real line. -/
theorem integral_bell_curve_eq_one :
    ∫ x : ℝ, exp (-x ^ 2 / 2) / √(2 * π) = 1 := by
  rw [integral_div]
  have h : ∫ x : ℝ, exp (-x ^ 2 / 2) = √(2 * π) := by
    have := integral_gaussian (1 / 2)
    have e : (fun x : ℝ => exp (-(1 / 2) * x ^ 2)) = fun x : ℝ => exp (-x ^ 2 / 2) := by
      funext x; ring_nf
    rw [e] at this
    rw [this]
    congr 1
    field_simp
  rw [h]
  have : 0 < √(2 * π) := Real.sqrt_pos.mpr (by positivity)
  exact div_self this.ne'

#print axioms integral_exp_neg_sq_eq_sqrt_pi
#print axioms integral_exp_neg_mul_sq_eq_sqrt_pi_div
#print axioms integral_bell_curve_eq_one
