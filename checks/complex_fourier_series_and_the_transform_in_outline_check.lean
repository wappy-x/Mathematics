-- The complex form: for every real function integrable over one cycle the complex coefficient c_n is (a_n - i b_n)/2 and c_(-n) is (a_n + i b_n)/2, the square wave's coefficients are (1 - (-1)^n)/(iπn), and the width-2 pulse has transform 2 sin ω / ω with F(0) = 2.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Basic.Real.Sign
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory Complex Real

/-! Conventions, as on the card.
* Real coefficients on `[-π, π]`: `a_n = (1/π) ∫ f(x) cos(nx) dx`, `b_n = (1/π) ∫ f(x) sin(nx) dx`.
* Complex coefficient: `c_n = (1/(2π)) ∫ f(x) e^(-inx) dx`.
* Transform: `F(ω) = ∫ f(t) e^(-iωt) dt` over the whole line.
* The square wave is `+1` on `(0, π)` and `-1` on `(-π, 0)`, which is Mathlib's `Real.sign`
  on that interval (its value `0` at the single point `x = 0` does not change any integral).
* The radar pulse is `1` for `-1 < t < 1` and `0` otherwise. -/

/-- The conversion is exact whenever the real coefficients exist: for a real function `f`
integrable over one cycle `[-π, π]` and every tone number `n ≥ 0`, the forward arrow's
coefficient is `c_n = (a_n - i b_n)/2` and the backward arrow's is `c_(-n) = (a_n + i b_n)/2`.
(At `n = 0`, `b_0 = 0`, so this says `c_0 = a_0/2`.) -/
theorem complex_coeff_eq_half_a_sub_i_b (f : ℝ → ℝ)
    (hf : IntervalIntegrable f volume (-π) π) (n : ℕ) :
    (1 / (2 * π) * ∫ x in (-π)..π, (f x : ℂ) * cexp (-((n : ℂ) * x) * I)) =
        ((1 / π * ∫ x in (-π)..π, f x * Real.cos (n * x) : ℝ) -
          I * (1 / π * ∫ x in (-π)..π, f x * Real.sin (n * x) : ℝ)) / 2 ∧
      (1 / (2 * π) * ∫ x in (-π)..π, (f x : ℂ) * cexp (-((-(n : ℂ)) * x) * I)) =
        ((1 / π * ∫ x in (-π)..π, f x * Real.cos (n * x) : ℝ) +
          I * (1 / π * ∫ x in (-π)..π, f x * Real.sin (n * x) : ℝ)) / 2 := by
  have hc : IntervalIntegrable (fun x => f x * Real.cos (n * x)) volume (-π) π :=
    hf.mul_continuousOn (by fun_prop)
  have hs : IntervalIntegrable (fun x => f x * Real.sin (n * x)) volume (-π) π :=
    hf.mul_continuousOn (by fun_prop)
  have hc' : IntervalIntegrable (fun x => ((f x * Real.cos (n * x) : ℝ) : ℂ)) volume (-π) π :=
    ⟨hc.1.ofReal, hc.2.ofReal⟩
  have hs' : IntervalIntegrable (fun x => I * ((f x * Real.sin (n * x) : ℝ) : ℂ)) volume (-π) π :=
    (show IntervalIntegrable (fun x => ((f x * Real.sin (n * x) : ℝ) : ℂ)) volume (-π) π from
      ⟨hs.1.ofReal, hs.2.ofReal⟩).const_mul I
  have e1 : ∀ x : ℝ, (f x : ℂ) * cexp (-((n : ℂ) * x) * I) =
      ((f x * Real.cos (n * x) : ℝ) : ℂ) - I * ((f x * Real.sin (n * x) : ℝ) : ℂ) := by
    intro x
    have : -((n : ℂ) * x) * I = ((-(n * x) : ℝ) : ℂ) * I := by push_cast; ring
    rw [this, Complex.exp_mul_I, ← Complex.ofReal_cos, ← Complex.ofReal_sin]
    push_cast [Real.cos_neg, Real.sin_neg]
    ring
  have e2 : ∀ x : ℝ, (f x : ℂ) * cexp (-((-(n : ℂ)) * x) * I) =
      ((f x * Real.cos (n * x) : ℝ) : ℂ) + I * ((f x * Real.sin (n * x) : ℝ) : ℂ) := by
    intro x
    have : -((-(n : ℂ)) * x) * I = ((n * x : ℝ) : ℂ) * I := by push_cast; ring
    rw [this, Complex.exp_mul_I, ← Complex.ofReal_cos, ← Complex.ofReal_sin]
    push_cast
    ring
  simp_rw [e1, e2]
  rw [intervalIntegral.integral_sub hc' hs', intervalIntegral.integral_add hc' hs',
    intervalIntegral.integral_const_mul, intervalIntegral.integral_ofReal,
    intervalIntegral.integral_ofReal]
  have hpi : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  constructor <;> (push_cast; field_simp)

/-- The square wave's arrows: for the wave that is `+1` on `(0, π)` and `-1` on `(-π, 0)`,
the complex coefficient of every nonzero tone number `n` is `c_n = (1 - (-1)^n)/(iπn)`,
which is `2/(iπn)` on odd `n` and `0` on even `n`. -/
theorem square_wave_complex_coeff (n : ℤ) (hn : n ≠ 0) :
    (1 / (2 * π) * ∫ x in (-π)..π, (Real.sign x : ℂ) * cexp (-((n : ℂ) * x) * I)) =
      (1 - (-1 : ℂ) ^ n) / (I * π * n) := by
  have hpi := Real.pi_pos
  have hcont : ∀ a b : ℝ, IntervalIntegrable (fun x : ℝ => cexp (-((n : ℂ) * x) * I)) volume a b :=
    fun a b => (by fun_prop : Continuous fun x : ℝ => cexp (-((n : ℂ) * x) * I)).intervalIntegrable a b
  have eqneg : Set.EqOn (fun x : ℝ => -cexp (-((n : ℂ) * x) * I))
      (fun x : ℝ => (Real.sign x : ℂ) * cexp (-((n : ℂ) * x) * I)) (Set.uIoo (-π) 0) := by
    intro x hx
    rw [Set.uIoo_of_le (by linarith)] at hx
    simp only
    rw [Real.sign_of_neg hx.2]; push_cast; ring
  have eqpos : Set.EqOn (fun x : ℝ => cexp (-((n : ℂ) * x) * I))
      (fun x : ℝ => (Real.sign x : ℂ) * cexp (-((n : ℂ) * x) * I)) (Set.uIoo 0 π) := by
    intro x hx
    rw [Set.uIoo_of_le (by linarith)] at hx
    simp only
    rw [Real.sign_of_pos hx.1]; push_cast; ring
  have i1 := ((hcont (-π) 0).neg).congr_uIoo eqneg
  have i2 := (hcont 0 π).congr_uIoo eqpos
  rw [← intervalIntegral.integral_add_adjacent_intervals i1 i2,
    ← intervalIntegral.integral_congr_uIoo eqneg, ← intervalIntegral.integral_congr_uIoo eqpos,
    intervalIntegral.integral_neg]
  have hc : (-(n : ℂ) * I) ≠ 0 := by simp [hn]
  have : (fun x : ℝ => cexp (-((n : ℂ) * x) * I)) = fun x : ℝ => cexp ((-(n : ℂ) * I) * x) := by
    ext x; ring_nf
  rw [this, integral_exp_mul_complex hc, integral_exp_mul_complex hc]
  have ea : cexp (-(n : ℂ) * I * π) = (-1) ^ n := by
    rw [show -(n : ℂ) * I * π = n * (-(π * I)) by ring, Complex.exp_int_mul, Complex.exp_neg_pi_mul_I]
  have eb : cexp (-(n : ℂ) * I * ((-π : ℝ) : ℂ)) = (-1) ^ n := by
    rw [show -(n : ℂ) * I * ((-π : ℝ) : ℂ) = n * (π * I) by push_cast; ring, Complex.exp_int_mul,
      Complex.exp_pi_mul_I]
  rw [ea, eb]
  have hn' : (n : ℂ) ≠ 0 := by exact_mod_cast hn
  have hpi' : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  push_cast
  simp only [mul_zero, Complex.exp_zero]
  field_simp
  ring_nf

/-- The radar pulse's transform: the pulse that is `1` for `-1 < t < 1` and `0` otherwise has
`F(ω) = ∫ f(t) e^(-iωt) dt = 2 sin ω / ω` for every `ω ≠ 0`, and `F(0) = 2`, the pulse's area. -/
theorem rect_pulse_fourier_transform (ω : ℝ) :
    (∫ t : ℝ, (Set.Ioo (-1 : ℝ) 1).indicator (fun _ => (1 : ℂ)) t * cexp (-((ω : ℂ) * t) * I)) =
      if ω = 0 then 2 else ((2 * Real.sin ω / ω : ℝ) : ℂ) := by
  have e : (fun t : ℝ => (Set.Ioo (-1 : ℝ) 1).indicator (fun _ => (1 : ℂ)) t * cexp (-((ω : ℂ) * t) * I))
      = (Set.Ioo (-1 : ℝ) 1).indicator (fun t => cexp (-((ω : ℂ) * t) * I)) := by
    ext t
    by_cases h : t ∈ Set.Ioo (-1 : ℝ) 1 <;> simp [h]
  rw [e, integral_indicator measurableSet_Ioo, ← integral_Ioc_eq_integral_Ioo,
    ← intervalIntegral.integral_of_le (by norm_num)]
  split_ifs with hω
  · subst hω; simp; norm_num
  · have hc : (-(ω : ℂ) * I) ≠ 0 := by
      simp [hω]
    have : (fun t : ℝ => cexp (-((ω : ℂ) * t) * I)) = fun t : ℝ => cexp ((-(ω : ℂ) * I) * t) := by
      ext t; ring_nf
    rw [this, integral_exp_mul_complex hc]
    have hω' : (ω : ℂ) ≠ 0 := by exact_mod_cast hω
    push_cast
    rw [Complex.sin]
    rw [mul_one, show -(ω : ℂ) * I * -1 = ω * I by ring]
    field_simp
    ring_nf
    simp only [Complex.I_sq]
    ring

/-- The card's whole-number pattern: the numerator `1 - (-1)^n` is `2` on odd `n` and `0` on
even `n`, checked for `n = 1, 2, 3, 5`. -/
example : (1 - (-1 : ℤ) ^ 1 = 2) ∧ (1 - (-1 : ℤ) ^ 2 = 0) ∧ (1 - (-1 : ℤ) ^ 3 = 2) ∧
    (1 - (-1 : ℤ) ^ 5 = 2) := by
  norm_num

#print axioms complex_coeff_eq_half_a_sub_i_b
#print axioms square_wave_complex_coeff
#print axioms rect_pulse_fourier_transform
