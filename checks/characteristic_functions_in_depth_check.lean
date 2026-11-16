-- Characteristic functions: every probability law's fingerprint is positive definite, has size 1 at a nonzero rate only for a law on evenly spaced points, and fades to 0 at high rates when the law has a density.
import Mathlib.MeasureTheory.Measure.CharacteristicFunction.Basic
import Mathlib.Analysis.Complex.Order
import Mathlib.Analysis.Fourier.RiemannLebesgueLemma
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.MeasureTheory.Measure.Decomposition.RadonNikodym

open MeasureTheory Complex Filter Topology
open scoped ComplexOrder

/-- Helper: `x ↦ exp(i s x)` is integrable against any probability law. -/
lemma integrable_exp_mul_I (μ : Measure ℝ) [IsProbabilityMeasure μ] (s : ℝ) :
    Integrable (fun x : ℝ => exp (s * x * I)) μ := by
  have h : (fun x : ℝ => exp (s * x * I)) = ⇑(BoundedContinuousFunction.innerProbChar s) := by
    ext x; simp [BoundedContinuousFunction.innerProbChar_apply, mul_comm]
  rw [h]; exact (BoundedContinuousFunction.innerProbChar s).integrable μ

/-- Helper: `x ↦ exp(i g(x))` is integrable against any probability law when `g` is continuous. -/
lemma integrable_exp_continuous_mul_I (μ : Measure ℝ) [IsProbabilityMeasure μ] {g : ℝ → ℝ}
    (hg : Continuous g) : Integrable (fun x : ℝ => exp (g x * I)) μ := by
  refine Integrable.mono' (integrable_const (1 : ℝ)) ?_ (ae_of_all _ fun x => ?_)
  · exact (by fun_prop : Continuous fun x : ℝ => exp (g x * I)).aestronglyMeasurable
  · rw [norm_exp_ofReal_mul_I]

/-- Every fingerprint is positive definite: for any probability law `μ` on the real line,
any rates `t₁, …, tₘ` and any complex weights `c₁, …, cₘ`, the weighted sum
`∑ⱼ ∑ₖ cⱼ · conj cₖ · φ(tⱼ − tₖ)` is a real number that is 0 or more. -/
theorem charFun_positive_definite (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (m : ℕ) (t : Fin m → ℝ) (c : Fin m → ℂ) :
    0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * charFun μ (t j - t k) := by
  have key : ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * charFun μ (t j - t k)
      = ((∫ x, ‖∑ j, c j * exp (t j * x * I)‖ ^ 2 ∂μ : ℝ) : ℂ) := by
    rw [← integral_complex_ofReal]
    have hpt : ∀ x : ℝ, ((‖∑ j, c j * exp (t j * x * I)‖ ^ 2 : ℝ) : ℂ)
        = ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * exp (((t j - t k : ℝ) : ℂ) * x * I) := by
      intro x
      push_cast
      rw [← mul_conj', map_sum, Finset.sum_mul_sum]
      refine Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun k _ => ?_
      rw [map_mul, ← exp_conj]
      simp only [map_mul, conj_ofReal, conj_I]
      rw [show c j * exp (t j * x * I) * ((starRingEnd ℂ) (c k) * exp (t k * x * -I))
          = c j * (starRingEnd ℂ) (c k) * (exp (t j * x * I) * exp (t k * x * -I)) by ring,
        ← exp_add]
      congr 2
      ring
    simp_rw [hpt]
    rw [integral_finsetSum _ (fun j _ => integrable_finsetSum _ fun k _ =>
      (integrable_exp_mul_I μ _).const_mul _)]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [integral_finsetSum _ (fun k _ => (integrable_exp_mul_I μ _).const_mul _)]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [integral_const_mul, charFun_apply_real]
  rw [key]
  exact zero_le_real.mpr (integral_nonneg fun x => by positivity)

/-- Size 1 away from rate 0 means a comb: if a probability law's fingerprint has size 1
at some rate `t₀ ≠ 0`, then for one offset `b` the law lives on the evenly spaced points
`b + 2πk/t₀`, `k` a whole number. -/
theorem charFun_norm_eq_one_imp_lattice (μ : Measure ℝ) [IsProbabilityMeasure μ]
    {t₀ : ℝ} (ht₀ : t₀ ≠ 0) (h : ‖charFun μ t₀‖ = 1) :
    ∃ b : ℝ, ∀ᵐ x ∂μ, ∃ k : ℤ, x = b + 2 * Real.pi * k / t₀ := by
  set θ := arg (charFun μ t₀) with hθ
  have hz : exp (θ * I) = charFun μ t₀ := by
    have := norm_mul_exp_arg_mul_I (charFun μ t₀)
    rwa [h, ofReal_one, one_mul] at this
  have hcont : Continuous fun x : ℝ => t₀ * x - θ := by fun_prop
  have h1 : ∫ x, exp (((t₀ * x - θ : ℝ) : ℂ) * I) ∂μ = 1 := by
    have : ∀ x : ℝ, exp (((t₀ * x - θ : ℝ) : ℂ) * I) = exp (t₀ * x * I) * exp (-(θ * I)) := by
      intro x
      rw [← exp_add]
      congr 1
      push_cast
      ring
    simp_rw [this]
    rw [integral_mul_const, ← charFun_apply_real, ← hz, ← exp_add, add_neg_cancel, exp_zero]
  have h2 : ∫ x, Real.cos (t₀ * x - θ) ∂μ = 1 := by
    have h4 := integral_re (integrable_exp_continuous_mul_I μ hcont)
    simp only [RCLike.re_to_complex, exp_ofReal_mul_I_re, h1, one_re] at h4
    exact h4
  have hcosi : Integrable (fun x : ℝ => Real.cos (t₀ * x - θ)) μ := by
    refine Integrable.mono' (integrable_const (1 : ℝ)) ?_ (ae_of_all _ fun x => ?_)
    · exact (by fun_prop : Continuous fun x : ℝ => Real.cos (t₀ * x - θ)).aestronglyMeasurable
    · simpa using Real.abs_cos_le_one (t₀ * x - θ)
  have h3 : ∫ x, (1 - Real.cos (t₀ * x - θ)) ∂μ = 0 := by
    rw [integral_sub (integrable_const _) hcosi, h2]
    simp
  rw [integral_eq_zero_iff_of_nonneg (f := fun x => 1 - Real.cos (t₀ * x - θ)) (fun x => by simpa using Real.cos_le_one _)
    ((integrable_const _).sub hcosi)] at h3
  refine ⟨θ / t₀, ?_⟩
  filter_upwards [h3] with x hx
  have hc : Real.cos (t₀ * x - θ) = 1 := by
    simp only [Pi.zero_apply] at hx
    linarith
  obtain ⟨n, hn⟩ := (Real.cos_eq_one_iff _).mp hc
  refine ⟨n, ?_⟩
  field_simp
  linarith

/-- Densities fade: if a probability law has a density (it is absolutely continuous with
respect to length), its fingerprint tends to 0 as `|t| → ∞`. -/
theorem charFun_tendsto_zero_of_density (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (hμ : μ ≪ volume) :
    Tendsto (charFun μ) (cocompact ℝ) (𝓝 0) := by
  set g : ℝ → ℂ := fun x => ((μ.rnDeriv volume x).toReal : ℂ) with hg
  have hc : -(2 * Real.pi)⁻¹ ≠ 0 := by
    simp [Real.pi_ne_zero]
  have hφ : charFun μ = fun t => ∫ v, Real.fourierChar (-(v * (-(2 * Real.pi)⁻¹ * t))) • g v := by
    funext t
    rw [charFun_apply_real, ← integral_rnDeriv_smul hμ]
    congr 1
    funext v
    rw [Circle.smul_def, Real.fourierChar_apply, hg]
    simp only [Complex.real_smul]
    rw [mul_comm]
    congr 2
    push_cast
    field_simp
  rw [hφ]
  exact (Real.tendsto_integral_exp_smul_cocompact g).comp
    (Homeomorph.mulLeft₀ _ hc).map_cocompact.le

-- The coin's squared point chances: 0.5² + 0.5² = 0.5.
example : (1 / 2 : ℚ) ^ 2 + (1 / 2) ^ 2 = 1 / 2 := by norm_num
-- One die's squared point chances: 6 × (1/6)² = 1/6.
example : 6 * (1 / 6 : ℚ) ^ 2 = 1 / 6 := by norm_num
-- The fake e^(-t^4) falls 2⁴ = 16 times as far over 2t as over t, beyond the cap of 4.
example : (2 : ℕ) ^ 4 = 16 ∧ 4 < 16 := by decide

#print axioms integrable_exp_mul_I
#print axioms integrable_exp_continuous_mul_I
#print axioms charFun_positive_definite
#print axioms charFun_norm_eq_one_imp_lattice
#print axioms charFun_tendsto_zero_of_density
