-- The central limit theorem in four lines, once you have fingerprints: for independent, identically distributed real readings with finite nonzero variance, the fingerprint of the standardised total tends to exp(-t^2/2) and its chance of being at most x tends to the bell curve's Phi(x).
import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Probability.CDF

open MeasureTheory ProbabilityTheory Filter Finset
open scoped Real Topology

/-- Helper: the fingerprint limit, proved here so the CDF theorem can use it. -/
theorem charFun_standardised_sum_tendsto_exp_aux
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : ℕ → Ω → ℝ}
    (hindep : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hvar : MemLp (X 0) 2 P)
    (hσ : Var[X 0; P] ≠ 0)
    (t : ℝ) :
    Tendsto
      (fun n : ℕ ↦ charFun (P.map (fun ω ↦ (∑ k ∈ range n, X k ω - n * P[X 0]) /
        (√(Var[X 0; P]) * √n))) t)
      atTop (𝓝 (Complex.exp (-(t : ℂ) ^ 2 / 2))) := by
  set Y : ℕ → Ω → ℝ := fun k ω ↦ (X k ω - P[X 0]) / √Var[X 0; P] with hYdef
  have mX0 := (hident 0).aemeasurable_fst
  have intX0 : Integrable (X 0) P := memLp_one_iff_integrable.1 <|
    hvar.mono_exponent (by simp)
  have hfun : ∀ n : ℕ, (fun ω ↦ (∑ k ∈ range n, X k ω - n * P[X 0]) /
      (√(Var[X 0; P]) * √n)) = fun ω ↦ (√n)⁻¹ * ∑ k ∈ range n, Y k ω := by
    intro n
    ext ω
    simp only [hYdef]
    rw [← Finset.sum_div, Finset.sum_sub_distrib]
    simp only [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    ring
  simp_rw [hfun]
  have hindepY : iIndepFun Y P :=
    hindep.comp (fun (_ : ℕ) (y : ℝ) ↦ (y - ∫ ω, X 0 ω ∂P) / √Var[X 0; P]) (by fun_prop)
  have hidentY : ∀ i, IdentDistrib (Y i) (Y 0) P P := fun i ↦
    (hident i).comp (u := fun (y : ℝ) ↦ (y - ∫ ω, X 0 ω ∂P) / √Var[X 0; P]) (by fun_prop)
  simp_rw [charFun_inv_sqrt_mul_sum hindepY hidentY]
  have h0 : P[Y 0] = 0 := by
    simp only [hYdef]
    rw [integral_div, integral_sub intX0 (by simp)]
    simp
  have h1 : P[Y 0 ^ 2] = 1 := by
    simp only [hYdef, Pi.pow_apply, div_pow]
    rw [integral_div, ← variance_eq_integral mX0, Real.sq_sqrt (variance_nonneg _ _), div_self hσ]
  have := tendsto_charFun_inv_sqrt_mul_pow (hidentY 0).aemeasurable_fst h0 h1 t
  convert this using 2

#print axioms charFun_standardised_sum_tendsto_exp_aux

/-- **The central limit theorem.** Let `X 0, X 1, ...` be independent real random quantities
with one common law, finite variance, mean `μ = E[X 0]` and standard deviation
`σ = √Var[X 0] ≠ 0`. Standardise the total over `n` days,
`Z n = (X 0 + ... + X (n-1) - n μ) / (σ √n)`. Then for every level `x`, the chance
`P(Z n ≤ x)` tends to `Φ(x)`, the standard bell curve's chance of being at most `x`. -/
theorem central_limit_theorem_cdf
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : ℕ → Ω → ℝ}
    (hindep : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hvar : MemLp (X 0) 2 P)
    (hσ : Var[X 0; P] ≠ 0)
    (x : ℝ) :
    Tendsto
      (fun n : ℕ ↦ P.real {ω | (∑ k ∈ range n, X k ω - n * P[X 0]) /
        (√(Var[X 0; P]) * √n) ≤ x})
      atTop (𝓝 (cdf (gaussianReal 0 1) x)) := by
  set Z : ℕ → Ω → ℝ := fun n ω ↦ (∑ k ∈ range n, X k ω - n * P[X 0]) /
        (√(Var[X 0; P]) * √n) with hZ
  have mZ : ∀ n, AEMeasurable (Z n) P := fun n ↦ by
    have := fun k ↦ (hident k).aemeasurable_fst
    simp only [hZ]
    fun_prop
  let μs : ℕ → ProbabilityMeasure ℝ := fun n ↦
    ⟨P.map (Z n), inferInstance⟩
  let μ : ProbabilityMeasure ℝ := ⟨gaussianReal 0 1, inferInstance⟩
  have hlim : Tendsto μs atTop (𝓝 μ) := by
    rw [ProbabilityMeasure.tendsto_iff_tendsto_charFun]
    intro t
    simp only [μs, μ, ProbabilityMeasure.coe_mk, charFun_gaussianReal]
    convert charFun_standardised_sum_tendsto_exp_aux hindep hident hvar hσ t using 2
    push_cast
    ring_nf
  have : NullSingletonClass (gaussianReal 0 1) := nullSingletonClass_gaussianReal one_ne_zero
  have hfr : (μ : Measure ℝ) (frontier (Set.Iic x)) = 0 := by
    rw [frontier_Iic]
    simp [μ]
  have key := ProbabilityMeasure.tendsto_measure_of_null_frontier_of_tendsto' hlim hfr
  have key2 := (ENNReal.tendsto_toReal (measure_ne_top _ _)).comp key
  rw [cdf_eq_real]
  convert key2 using 2
  · rename_i n
    simp only [Function.comp_apply, μs, ProbabilityMeasure.coe_mk, measureReal_def]
    rw [Measure.map_apply_of_aemeasurable (mZ n) measurableSet_Iic]
    rfl
  · simp [μ, measureReal_def]

/-- **The four lines, on fingerprints.** Under the same hypotheses, the fingerprint
(characteristic function) of the standardised total `Z n` converges, at every dial `t`,
to `exp(-t^2/2)`, the fingerprint of the standard bell curve. -/
theorem charFun_standardised_sum_tendsto_exp
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : ℕ → Ω → ℝ}
    (hindep : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hvar : MemLp (X 0) 2 P)
    (hσ : Var[X 0; P] ≠ 0)
    (t : ℝ) :
    Tendsto
      (fun n : ℕ ↦ charFun (P.map (fun ω ↦ (∑ k ∈ range n, X k ω - n * P[X 0]) /
        (√(Var[X 0; P]) * √n))) t)
      atTop (𝓝 (Complex.exp (-(t : ℂ) ^ 2 / 2))) := by
  exact charFun_standardised_sum_tendsto_exp_aux hindep hident hvar hσ t

/-- **The product lemma.** Powers of complex numbers of size at most 1 cannot drift apart
faster than `n` times their gap: `|a^n - b^n| ≤ n |a - b|` whenever `|a| ≤ 1` and `|b| ≤ 1`. -/
theorem norm_pow_sub_pow_le_of_norm_le_one (a b : ℂ) (ha : ‖a‖ ≤ 1) (hb : ‖b‖ ≤ 1) (n : ℕ) :
    ‖a ^ n - b ^ n‖ ≤ n * ‖a - b‖ := by
  induction n with
  | zero => simp
  | succ n ih =>
    have key : a ^ (n + 1) - b ^ (n + 1) = a * (a ^ n - b ^ n) + (a - b) * b ^ n := by ring
    rw [key]
    calc ‖a * (a ^ n - b ^ n) + (a - b) * b ^ n‖
        ≤ ‖a * (a ^ n - b ^ n)‖ + ‖(a - b) * b ^ n‖ := norm_add_le _ _
      _ = ‖a‖ * ‖a ^ n - b ^ n‖ + ‖a - b‖ * ‖b‖ ^ n := by rw [norm_mul, norm_mul, norm_pow]
      _ ≤ 1 * (n * ‖a - b‖) + ‖a - b‖ * 1 := by
          gcongr
          · exact pow_le_one₀ (norm_nonneg _) hb
      _ = (↑(n + 1) : ℝ) * ‖a - b‖ := by push_cast; ring

-- Worked numbers: at t = 1 and n = 21 the dial is s with s^2 = 1/21, so 1 - s^2/2 = 1 - 1/42 = 41/42.
example : (1 : ℚ) - (1 / 21) / 2 = 41 / 42 := by norm_num
-- b = 1 - t^2/(2n) lies in [0, 1] once n ≥ t^2/2: true at t = 1, n = 21.
example : (0 : ℚ) ≤ 1 - 1 / (2 * 21) ∧ (1 : ℚ) - 1 / (2 * 21) ≤ 1 := by norm_num
-- A quarter of 84 trading days is four months of 21; 20,000 quarters make 80,000 months.
example : 4 * 21 = 84 ∧ 4 * 20000 = 80000 := by decide

#print axioms central_limit_theorem_cdf
#print axioms charFun_standardised_sum_tendsto_exp
#print axioms norm_pow_sub_pow_le_of_norm_le_one
