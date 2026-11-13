-- Normal: if X follows the normal law with centre μ and spread σ > 0, then P(X ≤ x) is the area under the standard bell to the left of (x - μ)/σ, the band within k spreads has chance 2Φ(k) - 1, and the bell's density has area 1, mean μ and variance σ^2.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Moments.Variance

open MeasureTheory ProbabilityTheory Set Real
open scoped ENNReal NNReal

/-- The card's Φ: the area under the standard bell φ(t) = e^(-t^2/2)/√(2π) to the left of z. -/
noncomputable def Phi (z : ℝ) : ℝ :=
  ∫ t in Iic z, (√(2 * π))⁻¹ * rexp (-t ^ 2 / 2)

-- Helper lemmas.

lemma Phi_eq_gaussianReal_Iic (z : ℝ) : Phi z = (gaussianReal 0 1).real (Iic z) := by
  rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ t))]
  unfold Phi
  refine setIntegral_congr_fun measurableSet_Iic (fun t _ => ?_)
  simp [gaussianPDFReal]

lemma hasLaw_standardise {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {X : Ω → ℝ} (μ σ : ℝ) (hσ : 0 < σ) (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) :
    HasLaw (fun ω => (X ω - μ) / σ) (gaussianReal 0 1) P := by
  have h := gaussianReal_div_const (gaussianReal_sub_const hX μ) σ
  convert h using 2
  · simp
  · ext
    simp [Real.coe_toNNReal _ (sq_nonneg σ), hσ.ne']

lemma gaussianReal_std_Ici (z : ℝ) : (gaussianReal 0 1).real (Ici z) = 1 - Phi z := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [Phi_eq_gaussianReal_Iic, ← measureReal_congr (Iio_ae_eq_Iic (a := z)), ← compl_Ici,
    measureReal_compl measurableSet_Ici]
  simp

lemma Phi_neg (z : ℝ) : Phi (-z) = 1 - Phi z := by
  rw [Phi_eq_gaussianReal_Iic, ← gaussianReal_std_Ici]
  conv_lhs => rw [← neg_zero, ← gaussianReal_map_neg]
  rw [map_measureReal_apply measurable_neg measurableSet_Iic]
  congr 1
  ext x; simp

lemma gaussianReal_std_Icc (k : ℝ) (hk : 0 ≤ k) :
    (gaussianReal 0 1).real {y | |y| ≤ k} = 2 * Phi k - 1 := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have hset : {y : ℝ | |y| ≤ k} = Iic k \ Iio (-k) := by
    ext y; simp [abs_le, and_comm]
  rw [hset, measureReal_sdiff (fun y hy => by simp at hy ⊢; linarith) measurableSet_Iio,
    measureReal_congr (Iio_ae_eq_Iic (a := -k)), ← Phi_eq_gaussianReal_Iic,
    ← Phi_eq_gaussianReal_Iic, Phi_neg]
  ring

lemma normal_pdf_eq (μ σ : ℝ) (hσ : 0 < σ) (x : ℝ) :
    1 / (σ * √(2 * π)) * rexp (-(x - μ) ^ 2 / (2 * σ ^ 2)) =
      gaussianPDFReal μ (σ ^ 2).toNNReal x := by
  rw [gaussianPDFReal, Real.coe_toNNReal _ (sq_nonneg σ)]
  congr 1
  rw [one_div, Real.sqrt_mul (x := 2 * π) (by positivity) (σ ^ 2), Real.sqrt_sq hσ.le,
    mul_comm]

/-- Standardising. If X ~ N(μ, σ^2) with spread σ > 0, then for every value x,
P(X ≤ x) = Φ((x - μ)/σ): count how many spreads x sits from the centre and read the
standard bell's area to the left of that count. -/
theorem prob_le_eq_Phi_standardised
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : Ω → ℝ} (μ σ : ℝ) (hσ : 0 < σ) (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P)
    (x : ℝ) :
    P.real {ω | X ω ≤ x} = Phi ((x - μ) / σ) := by
  have hY := hasLaw_standardise μ σ hσ hX
  have hset : {ω | X ω ≤ x} = {ω | (fun y => y ≤ (x - μ) / σ) ((X ω - μ) / σ)} := by
    ext ω; simp [div_le_div_iff_of_pos_right hσ]
  rw [hset, hY.measureReal_eq (p := fun y => y ≤ (x - μ) / σ) measurableSet_Iic,
    Phi_eq_gaussianReal_Iic]
  rfl

/-- Symmetry and the 68-95-99.7 bands. The standard bell is a mirror image, so
Φ(-z) = 1 - Φ(z) for every z. For X ~ N(μ, σ^2) with σ > 0 and a band k ≥ 0 spreads wide on
each side, the chance of landing within k spreads of the centre is 2Φ(k) - 1, and the chance
of landing beyond k spreads, either way, is 2(1 - Φ(k)). -/
theorem Phi_symm_and_band_within_k_spreads
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : Ω → ℝ} (μ σ : ℝ) (hσ : 0 < σ) (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) :
    (∀ z : ℝ, Phi (-z) = 1 - Phi z) ∧
      ∀ k : ℝ, 0 ≤ k →
        P.real {ω | |X ω - μ| ≤ k * σ} = 2 * Phi k - 1 ∧
          P.real {ω | k * σ < |X ω - μ|} = 2 * (1 - Phi k) := by
  refine ⟨Phi_neg, fun k hk => ?_⟩
  have hY := hasLaw_standardise μ σ hσ hX
  have key : ∀ ω, (|X ω - μ| ≤ k * σ ↔ |(X ω - μ) / σ| ≤ k) := by
    intro ω
    rw [abs_div, abs_of_pos hσ, div_le_iff₀ hσ]
  have h1 : P.real {ω | |X ω - μ| ≤ k * σ} = 2 * Phi k - 1 := by
    have hset : {ω | |X ω - μ| ≤ k * σ} = {ω | (fun y => |y| ≤ k) ((X ω - μ) / σ)} := by
      ext ω; exact key ω
    rw [hset, hY.measureReal_eq (p := fun y => |y| ≤ k)
      (measurableSet_le (by fun_prop) (by fun_prop)), gaussianReal_std_Icc k hk]
  refine ⟨h1, ?_⟩
  have hset : {ω | k * σ < |X ω - μ|} = {ω | (fun y => k < |y|) ((X ω - μ) / σ)} := by
    ext ω; simp only [mem_ofPred_eq]; rw [← not_le, key ω, not_le]
  have hc : {y : ℝ | k < |y|} = {y : ℝ | |y| ≤ k}ᶜ := by ext y; simp
  rw [hset, hY.measureReal_eq (p := fun y => k < |y|)
    (measurableSet_lt (by fun_prop) (by fun_prop)), hc,
    measureReal_compl (measurableSet_le (by fun_prop) (by fun_prop)), gaussianReal_std_Icc k hk]
  simp; ring

/-- The two parameters mean what they say. For σ > 0 the density
f(x) = e^(-(x-μ)^2/(2σ^2)) / (σ√(2π)) has total area exactly 1 and is the density of
N(μ, σ^2); and a variable X ~ N(μ, σ^2) has mean E[X] = μ and variance Var(X) = σ^2. -/
theorem normal_density_area_one_mean_variance
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : Ω → ℝ} (μ σ : ℝ) (hσ : 0 < σ) (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) :
    (∫ x, 1 / (σ * √(2 * π)) * rexp (-(x - μ) ^ 2 / (2 * σ ^ 2)) = 1) ∧
      gaussianReal μ (σ ^ 2).toNNReal =
        volume.withDensity
          (fun x => ENNReal.ofReal (1 / (σ * √(2 * π)) * rexp (-(x - μ) ^ 2 / (2 * σ ^ 2)))) ∧
      P[X] = μ ∧ Var[X; P] = σ ^ 2 := by
  have hv : (σ ^ 2).toNNReal ≠ 0 := by
    simp [Real.toNNReal_eq_zero, hσ.ne']
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp_rw [normal_pdf_eq μ σ hσ]
    exact integral_gaussianPDFReal_eq_one μ hv
  · rw [gaussianReal_of_var_ne_zero μ hv]
    congr 1
    funext x
    rw [normal_pdf_eq μ σ hσ]
    rfl
  · rw [hX.integral_eq, integral_id_gaussianReal]
  · rw [hX.variance_eq, variance_id_gaussianReal, Real.coe_toNNReal _ (sq_nonneg σ)]

-- Worked numbers, centre μ = 0.05 = 1/20 percent, spread σ = 1.2 = 6/5 percent.
-- The variance is the spread squared: 1.2^2 = 1.44.
example : ((6 : ℚ) / 5) ^ 2 = 36 / 25 := by norm_num
-- A loss of 2%: distance from the centre -2 - 0.05 = -2.05, in spreads z = -2.05/1.2 = -41/24
-- (about -1.7083).
example : ((-2 : ℚ) - 1 / 20) / (6 / 5) = -41 / 24 := by norm_num
-- One, two and three spreads out: -1.15% to 1.25%, -2.35% to 2.45%, -3.55% to 3.65%.
example : (1 / 20 : ℚ) - 6 / 5 = -23 / 20 ∧ (1 / 20 : ℚ) + 6 / 5 = 25 / 20 ∧
    (1 / 20 : ℚ) - 2 * (6 / 5) = -47 / 20 ∧ (1 / 20 : ℚ) + 2 * (6 / 5) = 49 / 20 ∧
    (1 / 20 : ℚ) - 3 * (6 / 5) = -71 / 20 ∧ (1 / 20 : ℚ) + 3 * (6 / 5) = 73 / 20 := by
  norm_num
-- Mistake 1, centre not subtracted: z = -2/1.2 = -5/3 (about -1.6667).
example : (-2 : ℚ) / (6 / 5) = -5 / 3 := by norm_num
-- Mistake 2, variance used as the spread: z = -2.05/1.44 = -205/144 (about -1.4236).
example : ((-2 : ℚ) - 1 / 20) / (36 / 25) = -205 / 144 := by norm_num

#print axioms prob_le_eq_Phi_standardised
#print axioms Phi_symm_and_band_within_k_spreads
#print axioms normal_density_area_one_mean_variance
#print axioms Phi_eq_gaussianReal_Iic
#print axioms hasLaw_standardise
#print axioms gaussianReal_std_Ici
#print axioms Phi_neg
#print axioms gaussianReal_std_Icc
#print axioms normal_pdf_eq
