-- Convolution: for any two signals on the line with finite area under their absolute values, the Fourier transform (with e^(−iωt) and no constant in front) of their convolution is the product of their transforms, the convolution itself has finite area, and the unflipped version (correlation) with a real second signal transforms to f-hat times the conjugate of g-hat.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.Order.Antidiag.Prod
import Mathlib.Analysis.Convolution
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.MeasureTheory.Measure.Haar.Unique

open MeasureTheory Complex ComplexConjugate

/-- The card's Fourier transform, frequency `ω` in radians per unit length:
`f-hat(ω) = ∫ f(t) e^(−iωt) dt` over the whole real line, with no constant in front.
(Mathlib's `𝓕` uses `e^(−2πiωt)` instead, so the card's convention is written out here.) -/
noncomputable def fourierHat (f : ℝ → ℂ) (ω : ℝ) : ℂ :=
  ∫ t : ℝ, f t * cexp (-(I * ω * t))

/-- The card's convolution, "f smeared by g": `(f * g)(t) = ∫ f(s) g(t − s) ds`,
with the second signal flipped and slid to `t`. -/
noncomputable def conv (f g : ℝ → ℂ) (t : ℝ) : ℂ :=
  ∫ s : ℝ, f s * g (t - s)

/-- Helper: the convolution integrand `(t, s) ↦ f s * g (t - s)` is integrable on the plane. -/
lemma conv_integrand_integrable (f g : ℝ → ℂ) (hf : Integrable f) (hg : Integrable g) :
    Integrable (fun p : ℝ × ℝ => f p.2 * g (p.1 - p.2)) (volume.prod volume) :=
  hf.convolution_integrand (ContinuousLinearMap.mul ℂ ℂ) hg

/-- Helper: the wave `e^(−iωt)` has size 1. -/
lemma norm_cexp_neg_I_mul (ω t : ℝ) : ‖cexp (-(I * ω * t))‖ = 1 := by
  rw [show -(I * (ω:ℂ) * t) = ((-(ω * t) : ℝ) : ℂ) * I by push_cast; ring]
  exact Complex.norm_exp_ofReal_mul_I _

#print axioms conv_integrand_integrable
#print axioms norm_cexp_neg_I_mul

/-- The convolution theorem: if the areas under `|f|` and `|g|` are finite, then at every
frequency `ω` the transform of the smear `f * g` is the transform of `f` times the
transform of `g`. -/
theorem fourier_transform_of_convolution_is_product (f g : ℝ → ℂ)
    (hf : Integrable f) (hg : Integrable g) (ω : ℝ) :
    fourierHat (conv f g) ω = fourierHat f ω * fourierHat g ω := by
  have hcont : Continuous (fun t : ℝ => cexp (-(I * ω * t))) := by fun_prop
  have hint : Integrable (Function.uncurry fun t s : ℝ => f s * g (t - s) * cexp (-(I * ω * t)))
      (volume.prod volume) :=
    (conv_integrand_integrable f g hf hg).mul_bdd (c := 1)
      ((hcont.comp continuous_fst).aestronglyMeasurable)
      (Filter.Eventually.of_forall fun p => (norm_cexp_neg_I_mul ω p.1).le)
  unfold fourierHat conv
  simp_rw [← integral_mul_const]
  rw [integral_integral_swap hint]
  congr 1
  funext s
  rw [← integral_sub_right_eq_self (fun t => g t * cexp (-(I * ω * t))) s, ← integral_const_mul]
  congr 1
  funext t
  have : cexp (-(I * ω * t)) = cexp (-(I * ω * s)) * cexp (-(I * ω * ↑(t - s))) := by
    rw [← Complex.exp_add]; congr 1; push_cast; ring
  rw [this]; ring

/-- From the detailed proof: if the areas under `|f|` and `|g|` are finite, then so is the
area under `|f * g|`, so the smear has a transform. -/
theorem convolution_is_integrable (f g : ℝ → ℂ) (hf : Integrable f) (hg : Integrable g) :
    Integrable (conv f g) := by
  exact (conv_integrand_integrable f g hf hg).integral_prod_left

/-- Without the flip the operation is correlation, `∫ f(s) g(s − t) ds`; for a real `g`
with finite area, its transform at every `ω` is `f-hat(ω)` times the conjugate of `g-hat(ω)`. -/
theorem fourier_transform_of_correlation (f : ℝ → ℂ) (g : ℝ → ℝ)
    (hf : Integrable f) (hg : Integrable g) (ω : ℝ) :
    fourierHat (fun t => ∫ s : ℝ, f s * (g (s - t) : ℂ)) ω
      = fourierHat f ω * conj (fourierHat (fun t => (g t : ℂ)) ω) := by
  have hg' : Integrable (fun t : ℝ => ((g (-t) : ℝ) : ℂ)) :=
    (hg.ofReal (𝕜 := ℂ)).comp_neg
  have h1 := fourier_transform_of_convolution_is_product f (fun t => ((g (-t) : ℝ) : ℂ)) hf hg' ω
  have e : (fun t => ∫ s : ℝ, f s * (g (s - t) : ℂ)) = conv f (fun t => ((g (-t) : ℝ) : ℂ)) := by
    funext t; unfold conv; congr 1; funext s; simp only [neg_sub]
  rw [e, h1]
  congr 1
  unfold fourierHat
  rw [← integral_conj]
  rw [← integral_neg_eq_self (fun t => conj ((g t : ℂ) * cexp (-(I * ω * t))))]
  congr 1; funext t
  simp only [map_mul, Complex.conj_ofReal, ← Complex.exp_conj, map_neg, Complex.conj_I]
  congr 2
  push_cast; ring

-- Worked numbers, exact.
-- The tent at t = 0.25 mm: 1 − |1/4| = 3/4.
example : (1 : ℝ) - |(1 / 4 : ℝ)| = 3 / 4 := by
  rw [abs_of_pos (by norm_num)]; norm_num
-- The box at ω = π: sin(π/2)/(π/2) = 2/π.
example : Real.sin (Real.pi / 2) / (Real.pi / 2) = 2 / Real.pi := by
  rw [Real.sin_pi_div_two]; field_simp
-- The theorem's value for b * b at ω = π: (2/π)² = 4/π².
example : (2 / Real.pi) ^ 2 = 4 / Real.pi ^ 2 := by ring
-- The tent's transform directly: 2 × ∫₀¹ (1 − t) cos(πt) dt = 2 × 2/π² = 4/π².
example : 2 * (2 / Real.pi ^ 2) = 4 / Real.pi ^ 2 := by ring
-- The one-sided box at ω = π: (1 − e^(−iπ))/(iπ) = 2/(iπ).
example : (1 - cexp (-(I * Real.pi))) / (I * Real.pi) = 2 / (I * Real.pi) := by
  congr 1
  rw [show -(I * (Real.pi:ℂ)) = -(Real.pi * I) by ring, Complex.exp_neg, Complex.exp_pi_mul_I]
  norm_num
-- Its square: (2/(iπ))² = 4/(i² π²) = −4/π².
example : (2 / (I * Real.pi)) ^ 2 = -(4 / (Real.pi : ℂ) ^ 2) := by
  rw [div_pow, mul_pow, I_sq]; ring
-- A 3-pixel box blur applied twice: weights 1, 2, 3, 2, 1 (over 9).
example : (List.range 5).map (fun k => ∑ p ∈ Finset.antidiagonal k,
    (if p.1 < 3 then 1 else 0) * (if p.2 < 3 then 1 else 0)) = [1, 2, 3, 2, 1] := by decide
-- Two dice: six equal weights convolved with themselves give the ways to make 2 to 12.
example : (List.range' 2 11).map (fun n => ∑ p ∈ Finset.antidiagonal n,
    (if 1 ≤ p.1 ∧ p.1 ≤ 6 then 1 else 0) * (if 1 ≤ p.2 ∧ p.2 ≤ 6 then 1 else 0))
      = [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] := by decide
-- The same counts by listing all 36 rolls.
example : (List.range' 2 11).map (fun n =>
    ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun p : ℕ × ℕ => p.1 + p.2 = n)).card)
      = [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] := by decide

#print axioms fourier_transform_of_convolution_is_product
#print axioms convolution_is_integrable
#print axioms fourier_transform_of_correlation
