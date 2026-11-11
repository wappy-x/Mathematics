-- Euler's formula: for every real angle θ the exponential power series at iθ adds up to cos θ + i sin θ, a point at distance 1 from 0; the series converges at every complex number, exponents add, and e^(x + iy) = e^x (cos y + i sin y).
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Normed.Algebra.Exponential
import Mathlib.Analysis.SpecialFunctions.Exponential

open Complex

/-- Helper: e^(ln 2 + iπ/2) = 2i. -/
theorem exp_log_two_add_pi_div_two_mul_I :
    Complex.exp ((Real.log 2 : ℂ) + (Real.pi / 2 : ℂ) * I) = 2 * I := by
  rw [Complex.exp_add_mul_I, ← Complex.ofReal_exp, Real.exp_log two_pos]
  have h : (Real.pi : ℂ) / 2 = ((Real.pi / 2 : ℝ) : ℂ) := by push_cast; ring
  rw [h, ← Complex.ofReal_cos, ← Complex.ofReal_sin, Real.cos_pi_div_two, Real.sin_pi_div_two]
  push_cast; ring

/-- **Euler's formula.** For every real angle θ (in radians), the exponential power series
1 + iθ + (iθ)^2/2! + (iθ)^3/3! + ⋯ converges, and its sum, e^(iθ), is cos θ + i sin θ: the point
at angle θ on the circle of radius 1. That point is at distance exactly 1 from 0. -/
theorem exp_series_at_I_mul_angle_eq_cos_add_I_sin (θ : ℝ) :
    HasSum (fun n : ℕ => ((θ : ℂ) * I) ^ n / (n.factorial : ℂ))
        ((Real.cos θ : ℂ) + (Real.sin θ : ℂ) * I) ∧
      ‖(Real.cos θ : ℂ) + (Real.sin θ : ℂ) * I‖ = 1 := by
  constructor
  · have h := NormedSpace.expSeries_div_hasSum_exp ((θ : ℂ) * I)
    rw [← Complex.exp_eq_exp_ℂ] at h
    rwa [Complex.exp_mul_I, ← Complex.ofReal_cos, ← Complex.ofReal_sin] at h
  · rw [Complex.ofReal_cos, Complex.ofReal_sin]
    exact Complex.norm_cos_add_sin_mul_I θ

/-- **The series converges for every complex exponent.** For every complex number z, the power
series 1 + z + z^2/2! + z^3/3! + ⋯ converges, and its sum is the complex exponential e^z
(Mathlib's `Complex.exp`). So `Complex.exp` is the card's e^z, defined by the series. -/
theorem exp_series_converges_to_exp (z : ℂ) :
    HasSum (fun n : ℕ => z ^ n / (n.factorial : ℂ)) (Complex.exp z) := by
  rw [Complex.exp_eq_exp_ℂ]
  exact NormedSpace.expSeries_div_hasSum_exp z

/-- **Exponents add, so a real part stretches.** For all complex z and w,
e^(z + w) = e^z · e^w. In particular, for all real x and y, e^(x + iy) = e^x (cos y + i sin y):
the real part of the exponent sets the length e^x, the imaginary part sets the angle y. -/
theorem exp_add_and_exp_real_add_I_mul :
    (∀ z w : ℂ, Complex.exp (z + w) = Complex.exp z * Complex.exp w) ∧
      ∀ x y : ℝ, Complex.exp ((x : ℂ) + (y : ℂ) * I) =
        (Real.exp x : ℂ) * ((Real.cos y : ℂ) + (Real.sin y : ℂ) * I) := by
  refine ⟨fun z w => Complex.exp_add z w, fun x y => ?_⟩
  rw [Complex.exp_add_mul_I, ← Complex.ofReal_exp, ← Complex.ofReal_cos, ← Complex.ofReal_sin]

-- The card's exact worked values.
-- Half turn (Euler's identity): e^(iπ) + 1 = 0.
example : Complex.exp ((Real.pi : ℂ) * I) + 1 = 0 := by rw [Complex.exp_pi_mul_I]; ring
-- Stretch, then turn: e^(ln 2 + iπ/2) = 2i.
example : Complex.exp ((Real.log 2 : ℂ) + (Real.pi / 2 : ℂ) * I) = 2 * I := by exact exp_log_two_add_pi_div_two_mul_I
-- One more full turn changes nothing: e^(ln 2 + iπ/2 + 2πi) = 2i.
example : Complex.exp ((Real.log 2 : ℂ) + (Real.pi / 2 : ℂ) * I + 2 * (Real.pi : ℂ) * I) = 2 * I := by
  rw [Complex.exp_add, Complex.exp_two_pi_mul_I, mul_one, exp_log_two_add_pi_div_two_mul_I]
-- A full turn returns the arrow: e^(2πi) = 1.
example : Complex.exp (2 * (Real.pi : ℂ) * I) = 1 := by exact Complex.exp_two_pi_mul_I

#print axioms exp_log_two_add_pi_div_two_mul_I
#print axioms exp_series_at_I_mul_angle_eq_cos_add_I_sin
#print axioms exp_series_converges_to_exp
#print axioms exp_add_and_exp_real_add_I_mul
