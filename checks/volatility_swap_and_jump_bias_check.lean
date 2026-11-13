-- The volatility swap and the jump bias: the fair vol strike E[√v̄] never exceeds the root of the variance strike √E[v̄] (with equality only when realised variance is certain), one price gap leaves the strip-plus-hedge position a residual 2(e^J − 1 − J) whatever the price was before it, and with Merton's normal log jumps the strip strike minus the true expected variance is exactly 2λE[e^J − 1 − J − J²/2].
import Mathlib.Analysis.Convex.Integral
import Mathlib.Analysis.Convex.SpecificFunctions.Pow
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- **The vol strike sits below the root of the variance strike** (Steps 1 and the formula).
Realised variance `v̄ ≥ 0` is a random number on a pricing-world probability space with a
finite average (the variance strike `K_var = E[v̄]`). Then the fair vol strike
`K_vol = E[√v̄]` is at most `√E[v̄] = √K_var`, with equality only if realised variance is
certain (almost surely a constant). -/
theorem vol_strike_le_sqrt_variance_strike
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (vbar : Ω → ℝ) (hnonneg : ∀ᵐ ω ∂P, 0 ≤ vbar ω) (hint : Integrable vbar P) :
    (∫ ω, Real.sqrt (vbar ω) ∂P ≤ Real.sqrt (∫ ω, vbar ω ∂P)) ∧
      (∫ ω, Real.sqrt (vbar ω) ∂P = Real.sqrt (∫ ω, vbar ω ∂P) →
        ∃ c : ℝ, vbar =ᵐ[P] fun _ => c) := by
  have hgi : Integrable (Real.sqrt ∘ vbar) P := by
    refine Integrable.mono' ((integrable_const (1 : ℝ)).add hint.abs)
      (Real.continuous_sqrt.comp_aestronglyMeasurable hint.aestronglyMeasurable) ?_
    refine Filter.Eventually.of_forall fun ω => ?_
    simp only [Function.comp_apply, Real.norm_eq_abs, Pi.add_apply]
    rw [abs_of_nonneg (Real.sqrt_nonneg _), Real.sqrt_le_iff]
    constructor
    · positivity
    · nlinarith [abs_nonneg (vbar ω), le_abs_self (vbar ω)]
  have hfs : ∀ᵐ ω ∂P, vbar ω ∈ Set.Ici (0 : ℝ) := hnonneg
  refine ⟨Real.strictConcaveOn_sqrt.concaveOn.le_map_integral
    Real.continuous_sqrt.continuousOn isClosed_Ici hfs hint hgi, fun heq => ?_⟩
  rcases Real.strictConcaveOn_sqrt.ae_eq_const_or_lt_map_average
    Real.continuous_sqrt.continuousOn isClosed_Ici hfs hint hgi with h | h
  · exact ⟨_, h⟩
  · simp only [average_eq_integral] at h
    exact absurd heq (ne_of_lt h)

/-- **What one gap leaves behind** (Step 6, the jump accounting). With the strip payoff
`f(X) = 2(X − 1) − 2 ln X` and a hedge of `2(1 − 1/X)` units of forward held just before the
gap, a jump of the forward ratio from `X > 0` to `X e^J` changes `f` by the hedge gain plus
`2(e^J − 1 − J)`, whatever `X` was. Realised variance gains `J²`, so each gap leaves the
strip a leftover of `2(e^J − 1 − J) − J²`. -/
theorem strip_residual_at_a_gap (X J : ℝ) (hX : 0 < X) :
    (2 * (X * Real.exp J - 1) - 2 * Real.log (X * Real.exp J))
        - (2 * (X - 1) - 2 * Real.log X)
        - 2 * (1 - 1 / X) * (X * Real.exp J - X)
      = 2 * (Real.exp J - 1 - J) := by
  rw [Real.log_mul hX.ne' (Real.exp_pos J).ne', Real.log_exp]
  field_simp
  ring

/-- **The jump bias under Merton's lognormal jumps** (the formula and the closed forms).
Let the log jump `J` be normal with mean `μ_J` and spread `δ`, gaps arriving at rate `λ`,
over a diffusion volatility `σ`. Then the jump-bias average `2λ E[e^J − 1 − J − J²/2]`
equals the strip strike `σ² + 2λ(e^{μ_J + δ²/2} − 1 − μ_J)` minus the true expected
realised variance `σ² + λ(μ_J² + δ²)`. -/
theorem merton_jump_bias (σ lam muJ δ : ℝ) :
    2 * lam * ∫ J, (Real.exp J - 1 - J - J ^ 2 / 2) ∂(gaussianReal muJ (δ ^ 2).toNNReal)
      = (σ ^ 2 + 2 * lam * (Real.exp (muJ + δ ^ 2 / 2) - 1 - muJ))
        - (σ ^ 2 + lam * (muJ ^ 2 + δ ^ 2)) := by
  set G := gaussianReal muJ (δ ^ 2).toNNReal
  have hv : (((δ ^ 2).toNNReal : NNReal) : ℝ) = δ ^ 2 := Real.coe_toNNReal _ (sq_nonneg δ)
  have hexp_int : Integrable (fun x => Real.exp x) G := by
    simpa using integrable_exp_mul_gaussianReal (μ := muJ) (v := (δ ^ 2).toNNReal) 1
  have hexp : ∫ x, Real.exp x ∂G = Real.exp (muJ + δ ^ 2 / 2) := by
    have := congrFun (mgf_id_gaussianReal (μ := muJ) (v := (δ ^ 2).toNNReal)) 1
    simp only [mgf, id, one_mul, mul_one, one_pow, hv] at this
    exact this
  have hL2 : MemLp id 2 G := memLp_id_gaussianReal 2
  have hid_int : Integrable (fun x : ℝ => x) G := (memLp_id_gaussianReal 1).integrable le_rfl
  have hsq_int : Integrable (fun x : ℝ => x ^ 2) G := hL2.integrable_sq
  have hmean : ∫ x, x ∂G = muJ := integral_id_gaussianReal
  have hsq : ∫ x, x ^ 2 ∂G = muJ ^ 2 + δ ^ 2 := by
    have h1 := variance_eq_sub hL2
    rw [variance_id_gaussianReal, hv] at h1
    have h2 : ∫ x, (id x) ^ 2 ∂G = ∫ x, x ^ 2 ∂G := rfl
    simp only [Pi.pow_apply] at h1
    rw [h2] at h1
    have h3 : ∫ x, id x ∂G = muJ := hmean
    rw [h3] at h1
    linarith
  have : ∫ J, (Real.exp J - 1 - J - J ^ 2 / 2) ∂G
      = ∫ x, Real.exp x ∂G - 1 - ∫ x, x ∂G - (∫ x, x ^ 2 ∂G) / 2 := by
    rw [integral_sub, integral_sub, integral_sub, integral_const, integral_div]
    · simp
    · exact hexp_int
    · exact integrable_const _
    · exact hexp_int.sub (integrable_const _)
    · exact hid_int
    · exact (hexp_int.sub (integrable_const _)).sub hid_int
    · exact hsq_int.div_const _
  rw [this, hexp, hmean, hsq]
  ring

-- Two-point picture: realised variance 0.02 or 0.06 with even chance averages to 0.04.
example : (1 / 2 : ℚ) * (1 / 50 + 3 / 50) = 1 / 25 := by norm_num
-- Payoff chart: the variance swap pays (s² − 400)/40 at realised vol s = 10, 15, 20, 25, 30,
-- that is −7.50, −4.375, 0, 5.625, 12.50; the vol swap pays s − 20.
example : ((10 : ℚ) ^ 2 - 400) / 40 = -15 / 2 ∧ ((15 : ℚ) ^ 2 - 400) / 40 = -35 / 8 ∧
    ((20 : ℚ) ^ 2 - 400) / 40 = 0 ∧ ((25 : ℚ) ^ 2 - 400) / 40 = 45 / 8 ∧
    ((30 : ℚ) ^ 2 - 400) / 40 = 25 / 2 := by norm_num
-- Eighth-rule denominator: 0.04 = (1/5)², so 8 × 0.04^{3/2} = 8 × (1/25) × (1/5) = 0.064.
example : ((1 : ℚ) / 5) ^ 2 = 1 / 25 ∧ 8 * (1 / 25 : ℚ) * (1 / 5) = 8 / 125 := by norm_num
-- Merton table: exponent −0.10 + 0.15²/2 = −0.08875; average squared log jump 0.0325;
-- true expected variance 0.04 + 0.5 × 0.0325 = 0.05625.
example : (-1 / 10 : ℚ) + (3 / 20) ^ 2 / 2 = -71 / 800 := by norm_num
example : (-1 / 10 : ℚ) ^ 2 + (3 / 20) ^ 2 = 13 / 400 := by norm_num
example : (1 / 25 : ℚ) + 1 / 2 * ((-1 / 10) ^ 2 + (3 / 20) ^ 2) = 9 / 160 := by norm_num
-- Third-moment term λE[J³]/3 with E[J³] = μ³ + 3μδ²: 0.5 × (−0.001 − 0.00675)/3 = −31/24000.
example : (1 / 2 : ℚ) * ((-1 / 10) ^ 3 + 3 * (-1 / 10) * (3 / 20) ^ 2) / 3 = -31 / 24000 := by
  norm_num
-- Fourth moment E[J⁴] = μ⁴ + 6μ²δ² + 3δ⁴ = 0.00296875.
example : (-1 / 10 : ℚ) ^ 4 + 6 * (-1 / 10) ^ 2 * (3 / 20) ^ 2 + 3 * (3 / 20) ^ 4 = 19 / 6400 := by
  norm_num

#print axioms vol_strike_le_sqrt_variance_strike
#print axioms strip_residual_at_a_gap
#print axioms merton_jump_bias
