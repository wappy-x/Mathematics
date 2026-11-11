-- The elementary functions: complex cosine and sine are built from two exponentials and turn into cosh and i sinh up the imaginary axis, |sin(x + iy)|^2 = sin^2 x + sinh^2 y so complex sine is unbounded, and the exponential is the sum of its series, its own derivative, never 0 and repeats every 2πi.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

/-! The plane is `ℂ`; `Complex.I` is i. `Complex.exp`, `Complex.cos`, `Complex.sin` are
Mathlib's exponential, cosine and sine of a complex input. `Real.cosh` and `Real.sinh` are
the real hyperbolic functions, `(e^y + e^-y)/2` and `(e^y - e^-y)/2`. A real number `y`
placed in `ℂ` is written `(y : ℂ)`. -/

open Complex

/-- Cosine and sine of any complex z are fixed by two exponentials:
cos z = (e^(iz) + e^(-iz)) / 2 and sin z = (e^(iz) - e^(-iz)) / (2i).
Turning the input a quarter, to a point y up the imaginary axis, turns them into the
hyperbolic functions: cos(iy) = cosh y and sin(iy) = i sinh y. -/
theorem cos_sin_by_exponentials_and_quarter_turn (z : ℂ) (y : ℝ) :
    Complex.cos z = (Complex.exp (I * z) + Complex.exp (-(I * z))) / 2 ∧
    Complex.sin z = (Complex.exp (I * z) - Complex.exp (-(I * z))) / (2 * I) ∧
    Complex.cos (I * y) = (Real.cosh y : ℂ) ∧
    Complex.sin (I * y) = I * (Real.sinh y : ℂ) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [Complex.cos, mul_comm I z, ← neg_mul]
  · rw [Complex.sin, mul_comm I z, ← neg_mul, eq_div_iff (mul_ne_zero two_ne_zero I_ne_zero)]
    ring_nf
    rw [I_sq]
    ring
  · rw [mul_comm, cos_mul_I, ← ofReal_cosh]
  · rw [mul_comm, sin_mul_I, ← ofReal_sinh, mul_comm]

/-- For real x and y, the size of sine at x + iy satisfies
|sin(x + iy)|^2 = sin^2 x + sinh^2 y, so sine of a complex input is unbounded:
no number M bounds |sin z| for every complex z. -/
theorem norm_sin_sq_eq_and_sin_unbounded (x y : ℝ) :
    ‖Complex.sin (x + y * I)‖ ^ 2 = Real.sin x ^ 2 + Real.sinh y ^ 2 ∧
    ¬ ∃ M : ℝ, ∀ w : ℂ, ‖Complex.sin w‖ ≤ M := by
  have key : ∀ a b : ℝ, ‖Complex.sin (a + b * I)‖ ^ 2 = Real.sin a ^ 2 + Real.sinh b ^ 2 := by
    intro a b
    rw [sin_add_mul_I, ← ofReal_sin, ← ofReal_cos, ← ofReal_cosh, ← ofReal_sinh,
      ← ofReal_mul, ← ofReal_mul, Complex.sq_norm, normSq_add_mul_I]
    have h1 := Real.sin_sq_add_cos_sq a
    have h2 := Real.cosh_sq b
    linear_combination (Real.sin a ^ 2) * h2 + (Real.sinh b ^ 2) * h1
  refine ⟨key x y, ?_⟩
  rintro ⟨M, hM⟩
  set t : ℝ := |M| + 1
  have ht : 0 ≤ t := by positivity
  have hs : t ≤ Real.sinh t := Real.self_le_sinh_iff.mpr ht
  have hk := key 0 t
  rw [Real.sin_zero] at hk
  have hn := hM ((0 : ℝ) + t * I)
  have hpos : 0 ≤ ‖Complex.sin ((0 : ℝ) + t * I)‖ := norm_nonneg _
  have : Real.sinh t ≤ ‖Complex.sin ((0 : ℝ) + t * I)‖ := by
    nlinarith
  have : M < t := by simp only [t]; linarith [le_abs_self M]
  linarith

/-- For every complex z, e^z is the sum of the series z^n / n!, its rate of change is
e^z itself, it is never 0, and it repeats every 2πi: e^(z + 2πi) = e^z. -/
theorem exp_series_deriv_ne_zero_periodic (z : ℂ) :
    HasSum (fun n : ℕ => z ^ n / (n.factorial : ℂ)) (Complex.exp z) ∧
    HasDerivAt Complex.exp (Complex.exp z) z ∧
    Complex.exp z ≠ 0 ∧
    Complex.exp (z + 2 * Real.pi * I) = Complex.exp z := by
  refine ⟨?_, hasDerivAt_exp z, exp_ne_zero z, exp_periodic z⟩
  rw [exp_eq_exp_ℂ]
  exact NormedSpace.expSeries_div_hasSum_exp z

/-- The card's worked values, exactly: cos(i) = cosh 1, the cable one unit out. -/
example : Complex.cos I = (Real.cosh 1 : ℂ) := by
  simpa using (cos_sin_by_exponentials_and_quarter_turn 0 1).2.2.1

/-- sin(i) = i sinh 1. -/
example : Complex.sin I = I * (Real.sinh 1 : ℂ) := by
  simpa using (cos_sin_by_exponentials_and_quarter_turn 0 1).2.2.2

/-- sin(1 + 3i) = sin 1 cosh 3 + i cos 1 sinh 3. -/
example : Complex.sin (1 + 3 * I) =
    (Real.sin 1 * Real.cosh 3 : ℂ) + I * (Real.cos 1 * Real.sinh 3 : ℂ) := by
  rw [sin_add_mul_I, ← ofReal_one, ← ofReal_ofNat, ← ofReal_sin, ← ofReal_cos, ← ofReal_cosh,
    ← ofReal_sinh]
  push_cast
  ring

#print axioms cos_sin_by_exponentials_and_quarter_turn
#print axioms norm_sin_sq_eq_and_sin_unbounded
#print axioms exp_series_deriv_ne_zero_periodic
