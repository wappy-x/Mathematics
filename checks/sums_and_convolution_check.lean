-- Adding continuous variables: for independent X and Y with densities f and g, the sum X + Y has density h(s) = ∫ f(x) g(s - x) dx, the convolution integral of two normal densities is again a normal density, and two independent normal variables add to a normal one with the means added and the variances added.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Measure.WithDensity

open MeasureTheory ProbabilityTheory
open scoped ENNReal NNReal

lemma gaussianPDFReal_mul_gaussianPDFReal_sub {μ₁ μ₂ : ℝ} {v₁ v₂ : ℝ≥0}
    (hv₁ : v₁ ≠ 0) (hv₂ : v₂ ≠ 0) (s x : ℝ) :
    gaussianPDFReal μ₁ v₁ x * gaussianPDFReal μ₂ v₂ (s - x) =
      gaussianPDFReal (μ₁ + μ₂) (v₁ + v₂) s *
        gaussianPDFReal ((v₂ * μ₁ + v₁ * (s - μ₂)) / (v₁ + v₂)) (v₁ * v₂ / (v₁ + v₂)) x := by
  have ha : (0 : ℝ) < v₁ := lt_of_le_of_ne v₁.2 (by exact_mod_cast hv₁.symm)
  have hb : (0 : ℝ) < v₂ := lt_of_le_of_ne v₂.2 (by exact_mod_cast hv₂.symm)
  simp only [gaussianPDFReal, NNReal.coe_div, NNReal.coe_mul, NNReal.coe_add]
  set a : ℝ := (v₁ : ℝ)
  set b : ℝ := (v₂ : ℝ)
  have hab : 0 < a + b := by positivity
  have hsq : Real.sqrt (2 * Real.pi * a) * Real.sqrt (2 * Real.pi * b) =
      Real.sqrt (2 * Real.pi * (a + b)) * Real.sqrt (2 * Real.pi * (a * b / (a + b))) := by
    rw [← Real.sqrt_mul (by positivity), ← Real.sqrt_mul (by positivity)]
    congr 1
    field_simp
  have hexp : -(x - μ₁) ^ 2 / (2 * a) + -(s - x - μ₂) ^ 2 / (2 * b) =
      -(s - (μ₁ + μ₂)) ^ 2 / (2 * (a + b)) +
        -(x - (b * μ₁ + a * (s - μ₂)) / (a + b)) ^ 2 / (2 * (a * b / (a + b))) := by
    field_simp
    ring
  calc (Real.sqrt (2 * Real.pi * a))⁻¹ * Real.exp (-(x - μ₁) ^ 2 / (2 * a)) *
        ((Real.sqrt (2 * Real.pi * b))⁻¹ * Real.exp (-(s - x - μ₂) ^ 2 / (2 * b)))
      = (Real.sqrt (2 * Real.pi * a) * Real.sqrt (2 * Real.pi * b))⁻¹ *
          Real.exp (-(x - μ₁) ^ 2 / (2 * a) + -(s - x - μ₂) ^ 2 / (2 * b)) := by
        rw [Real.exp_add, mul_inv]; ring
    _ = _ := by
        rw [hsq, hexp, Real.exp_add, mul_inv]; ring

#print axioms gaussianPDFReal_mul_gaussianPDFReal_sub

/-- **Normal plus normal is normal.** If `X` has the normal law `N(μ₁, v₁)` and `Y` has the
normal law `N(μ₂, v₂)` (centres `μ₁, μ₂`, variances `v₁ = σ₁^2, v₂ = σ₂^2`), and `X` and `Y`
are independent, then their total `X + Y` has the normal law `N(μ₁ + μ₂, v₁ + v₂)`:
the centres add and the variances (squared spreads) add. -/
theorem normal_add_normal_is_normal {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {μ₁ μ₂ : ℝ} {v₁ v₂ : ℝ≥0} {X Y : Ω → ℝ}
    (hXY : IndepFun X Y P)
    (hX : HasLaw X (gaussianReal μ₁ v₁) P) (hY : HasLaw Y (gaussianReal μ₂ v₂) P) :
    P.map (X + Y) = gaussianReal (μ₁ + μ₂) (v₁ + v₂) := by
  exact gaussianReal_add_gaussianReal_of_indepFun hXY hX hY

/-- **The convolution formula** (Step 1). Let `X` and `Y` be independent random variables on a
probability space, `X` with density `f` and `Y` with density `g` (their laws are Lebesgue
measure weighted by `f` and by `g`). Then the total `S = X + Y` has the density
`h(s) = ∫ f(x) g(s - x) dx`: for every value `s`, integrate over every split of `s` into a
first part `x` and a rest `s - x` the product of the two densities. -/
theorem density_of_sum_is_convolution {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    [IsProbabilityMeasure P] {X Y : Ω → ℝ} {f g : ℝ → ℝ≥0∞}
    (hf : Measurable f) (hg : Measurable g)
    (hXY : IndepFun X Y P)
    (hX : HasLaw X (volume.withDensity f) P) (hY : HasLaw Y (volume.withDensity g) P) :
    HasLaw (X + Y) (volume.withDensity (fun s => ∫⁻ x, f x * g (s - x))) P := by
  refine ⟨hX.aemeasurable.add hY.aemeasurable, ?_⟩
  have hXf : IsFiniteMeasure (P.map X) := inferInstance
  have hYf : IsFiniteMeasure (P.map Y) := inferInstance
  rw [hXY.map_add_eq_map_conv_map₀' hX.aemeasurable hY.aemeasurable, hX.map_eq, hY.map_eq,
    conv_withDensity_eq_lconvolution hf hg]
  · congr 1
    funext s
    simp only [lconvolution_def]
    congr 1
    funext x
    congr 2
    ring
  · infer_instance
  · infer_instance

/-- **The convolution of two bells is a bell** (Step 3 and its folded proof). For spreads above
zero (variances `v₁, v₂ ≠ 0`), the convolution integral of the normal density with centre `μ₁`
and variance `v₁` against the normal density with centre `μ₂` and variance `v₂` is, at every
total `s`, exactly the normal density with centre `μ₁ + μ₂` and variance `v₁ + v₂`. -/
theorem convolution_of_normal_densities {μ₁ μ₂ : ℝ} {v₁ v₂ : ℝ≥0}
    (hv₁ : v₁ ≠ 0) (hv₂ : v₂ ≠ 0) (s : ℝ) :
    ∫ x, gaussianPDFReal μ₁ v₁ x * gaussianPDFReal μ₂ v₂ (s - x) =
      gaussianPDFReal (μ₁ + μ₂) (v₁ + v₂) s := by
  simp_rw [gaussianPDFReal_mul_gaussianPDFReal_sub hv₁ hv₂ s]
  rw [integral_const_mul, integral_gaussianPDFReal_eq_one, mul_one]
  have : v₁ + v₂ ≠ 0 := by positivity
  exact div_ne_zero (mul_ne_zero hv₁ hv₂) this

-- The commute: bus N(20, 3^2), train N(35, 4^2), independent; deadline 60 minutes.
-- Centre of the total: 20 + 35 = 55 minutes.
example : (20 : ℤ) + 35 = 55 := by decide
-- Variance of the total: 3^2 + 4^2 = 9 + 16 = 25, so the spread is 5, not 3 + 4 = 7.
example : (3 : ℤ) ^ 2 + 4 ^ 2 = 25 ∧ (5 : ℤ) ^ 2 = 25 ∧ (3 : ℤ) + 4 = 7 ∧ (7 : ℤ) ^ 2 ≠ 25 := by decide
example : Real.sqrt (3 ^ 2 + 4 ^ 2) = 5 := by
  rw [show ((3 : ℝ) ^ 2 + 4 ^ 2) = 5 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
-- The deadline in spreads: (60 - 55) / 5 = 1; with a 65-minute allowance, (65 - 55) / 5 = 2.
example : ((60 : ℚ) - 55) / 5 = 1 ∧ ((65 : ℚ) - 55) / 5 = 2 := by norm_num
-- Busiest split for a 60-minute trip: m_s = 20 + (9/25)(60 - 55) = 21.8 = 109/5 minutes of bus,
-- 60 - 109/5 = 191/5 = 38.2 minutes of train.
example : (20 : ℚ) + 9 / 25 * (60 - 55) = 109 / 5 ∧ (60 : ℚ) - 109 / 5 = 191 / 5 := by norm_num
-- The 5 extra minutes split in proportion to the variances 9 and 16: 9/5 = 1.8 and 16/5 = 3.2.
example : (9 : ℚ) / 25 * 5 = 9 / 5 ∧ (16 : ℚ) / 25 * 5 = 16 / 5 ∧ (9 : ℚ) / 5 + 16 / 5 = 5 := by
  norm_num
-- The coefficient in the completing-the-square identity: σ²/(σ₁²σ₂²) = 1/σ₁² + 1/σ₂², here 25/144.
example : (1 : ℚ) / 9 + 1 / 16 = 25 / (9 * 16) := by norm_num
-- A jumpier bus with spread 6: variance 6^2 + 4^2 = 36 + 16 = 52.
example : (6 : ℤ) ^ 2 + 4 ^ 2 = 52 := by decide
-- Legs correlated 0.5: variance 9 + 16 + 2(1/2)(3)(4) = 37.
example : (9 : ℚ) + 16 + 2 * (1 / 2) * 3 * 4 = 37 := by norm_num
-- Bus plus a platform wait spread evenly over 0..10: mean 20 + 5 = 25, variance 9 + 10^2/12 = 52/3.
example : (20 : ℚ) + 10 / 2 = 25 ∧ (9 : ℚ) + 10 ^ 2 / 12 = 52 / 3 := by norm_num
-- The MGF exponent of N(55, 25) at t = 1/10: 55 t + 25 t^2 / 2 = 45/8, the sum of the legs' exponents.
example : (55 : ℚ) * (1 / 10) + 25 * (1 / 10) ^ 2 / 2 = 45 / 8 ∧
    ((20 : ℚ) * (1 / 10) + 9 * (1 / 10) ^ 2 / 2) + (35 * (1 / 10) + 16 * (1 / 10) ^ 2 / 2) = 45 / 8 := by
  norm_num

#print axioms normal_add_normal_is_normal
#print axioms density_of_sum_is_convolution
#print axioms convolution_of_normal_densities
