-- Characteristic functions: two random quantities with the same characteristic function have the same law, a normal error's characteristic function is the bell e^(iμt − σ²t²/2), and the inversion integral returns a density at its points of continuity.
import Mathlib.MeasureTheory.Measure.CharacteristicFunction.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.Data.Nat.Factorial.DoubleFactorial

open MeasureTheory ProbabilityTheory Complex
open scoped Nat

/-- Uniqueness theorem: two random quantities whose characteristic functions agree at every
real rate `t` have the same distribution. -/
theorem same_char_fun_same_law {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    {P : Measure Ω} {Q : Measure Ω'} [IsProbabilityMeasure P] [IsProbabilityMeasure Q]
    {X : Ω → ℝ} {Y : Ω' → ℝ} (hX : AEMeasurable X P) (hY : AEMeasurable Y Q)
    (h : ∀ t : ℝ, charFun (P.map X) t = charFun (Q.map Y) t) :
    P.map X = Q.map Y := by
  exact Measure.ext_of_charFun (funext h)

/-- A normal error with mean `μ` and standard deviation `σ` has characteristic function
`e^(iμt − σ²t²/2)`: the mean turns the average, the spread shrinks it along a bell in `t`. -/
theorem char_fun_normal (μ σ t : ℝ) :
    charFun (gaussianReal μ (σ ^ 2).toNNReal) t =
      cexp (I * μ * t - σ ^ 2 * t ^ 2 / 2) := by
  rw [charFun_gaussianReal]
  congr 1
  rw [Real.coe_toNNReal _ (sq_nonneg σ)]
  push_cast
  ring

/-- Density inversion: for a law with density `f` whose characteristic function has finite
total size (is integrable), at every `x` where `f` is continuous,
`f(x) = (1/(2π)) ∫ e^(−itx) φ(t) dt`. -/
theorem density_inversion {f : ℝ → ℝ} (hf_nonneg : ∀ x, 0 ≤ f x) (hf_int : Integrable f)
    (hf_one : ∫ x, f x = 1)
    (hφ : Integrable (charFun (volume.withDensity (fun x => ENNReal.ofReal (f x)))))
    {x : ℝ} (hx : ContinuousAt f x) :
    (f x : ℂ) = (1 / (2 * Real.pi)) *
      ∫ t : ℝ, cexp (-(t * x) * I) *
        charFun (volume.withDensity (fun y => ENNReal.ofReal (f y))) t := by
  set ψ := charFun (volume.withDensity (fun y => ENNReal.ofReal (f y))) with hψdef
  set g : ℝ → ℂ := fun y => (f y : ℂ) with hg
  have hpi : (2 * Real.pi) ≠ 0 := by positivity
  have hchar : ∀ t, ψ t = FourierTransform.fourier g (-(2 * Real.pi)⁻¹ * t) := by
    intro t
    rw [hψdef, charFun_apply_real, Real.fourier_real_eq_integral_exp_smul,
      integral_withDensity_eq_integral_toReal_smul₀ (f := fun y => ENNReal.ofReal (f y))
        hf_int.aemeasurable.ennreal_ofReal
        (Filter.Eventually.of_forall fun _ => ENNReal.ofReal_lt_top)]
    congr 1
    ext y
    rw [ENNReal.toReal_ofReal (hf_nonneg y)]
    simp only [hg, Complex.real_smul, smul_eq_mul]
    rw [mul_comm]
    congr 2
    push_cast
    field_simp
  have hFg : FourierTransform.fourier g = fun w => ψ (-(2 * Real.pi) * w) := by
    ext w
    rw [hchar, ← mul_assoc, neg_mul_neg, inv_mul_cancel₀ hpi, one_mul]
  have hgi : Integrable g := hf_int.ofReal
  have hFgi : Integrable (FourierTransform.fourier g) := by
    rw [hFg]
    exact hφ.comp_mul_left' (neg_ne_zero.mpr hpi)
  have hgc : ContinuousAt g x := Complex.continuous_ofReal.continuousAt.comp hx
  have key := hgi.fourierInv_fourier_eq hFgi hgc
  have e1 : (f x : ℂ) = g x := rfl
  rw [e1, ← key, Real.fourierInv_eq']
  have hcv := Measure.integral_comp_mul_left (fun t : ℝ => cexp (-(↑t * ↑x) * I) * ψ t) (-(2 * Real.pi))
  have habs : |(-(2 * Real.pi))⁻¹| = (2 * Real.pi)⁻¹ := by
    rw [inv_neg, abs_neg, abs_of_pos (by positivity)]
  rw [habs] at hcv
  have hrhs : (1 / (2 * (Real.pi : ℂ))) * ∫ t : ℝ, cexp (-(↑t * ↑x) * I) * ψ t =
      ∫ w : ℝ, cexp (-(↑(-(2 * Real.pi) * w) * ↑x) * I) * ψ (-(2 * Real.pi) * w) := by
    rw [hcv, Complex.real_smul]
    push_cast
    ring
  rw [hrhs]
  congr 1
  ext w
  rw [hFg]
  simp only [smul_eq_mul]
  congr 2
  rw [Real.inner_apply]
  push_cast
  ring

-- Step 2: the even moments of the standard normal, 1 × 3 × … × (2k − 1), are 1, 1, 3, 15, 105.
example : (List.range 5).map (fun k => (2 * k - 1)‼) = [1, 1, 3, 15, 105] := by decide

-- Step 2: (2k)! = (1 × 3 × … × (2k − 1)) × 2^k × k!, so moment / (2k)! = 1 / (2^k k!), k = 0..7.
example : ∀ k < 8, (2 * k)! = (2 * k - 1)‼ * 2 ^ k * k ! := by decide

-- Worked numbers: the scale's exponent σ²t²/2 with σ = 2 is 1/2 at t = 1/2 and 2 at t = 1.
example : (2 : ℚ) ^ 2 * (1 / 2) ^ 2 / 2 = 1 / 2 := by norm_num
example : (2 : ℚ) ^ 2 * 1 ^ 2 / 2 = 2 := by norm_num

-- Step 1: the scale's error is 2Z, so the exponent (2t)²/2 equals 2t².
example (t : ℚ) : (2 * t) ^ 2 / 2 = 2 * t ^ 2 := by ring

#print axioms same_char_fun_same_law
#print axioms char_fun_normal
#print axioms density_inversion
