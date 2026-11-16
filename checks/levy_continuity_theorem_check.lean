-- Levy's continuity theorem: if the fingerprints of probability laws on the line converge at every dial to a limit continuous at zero, that limit is the fingerprint of a law and the laws converge to it, and conversely convergent laws have convergent fingerprints.
import Mathlib.MeasureTheory.Measure.LevyConvergence
import Mathlib.Probability.Distributions.Poisson.PoissonLimitThm

open MeasureTheory ProbabilityTheory Filter Topology Complex
open scoped NNReal unitInterval

/-- Helper: the fingerprint of the binomial law `Bin(n, q)` on the line is
`(1 + q (e^{it} - 1))^n`, by the binomial theorem. -/
lemma charFun_map_cast_binomial_aux (n : ℕ) (q : I) (t : ℝ) :
    charFun Bin(ℝ, n, q) t = (1 + (q : ℂ) * (cexp (t * Complex.I) - 1)) ^ n := by
  rw [charFun_apply, integral_map_cast_binomial]
  rw [show (1 + (q : ℂ) * (cexp (t * Complex.I) - 1))
      = (q : ℂ) * cexp (t * Complex.I) + (1 - (q : ℂ)) by ring,
    add_pow, ← Nat.range_succ_eq_Iic]
  refine Finset.sum_congr rfl fun k _ ↦ ?_
  simp_rw [Real.inner_apply]
  rw [mul_pow, ← Complex.exp_nat_mul]
  push_cast
  rw [Complex.real_smul]
  push_cast
  ring_nf

#print axioms charFun_map_cast_binomial_aux

/-- **Lévy's continuity theorem, part (b).** If the fingerprints (characteristic functions)
of a sequence of probability laws on the real line converge at every dial `t` to a limit `g`,
and `g` is continuous at `0`, then `g` is the fingerprint of some probability law `μ₀`, and the
laws converge in distribution (weakly) to `μ₀`. -/
theorem levy_continuity_theorem (μ : ℕ → ProbabilityMeasure ℝ) (g : ℝ → ℂ)
    (hconv : ∀ t : ℝ, Tendsto (fun n ↦ charFun (μ n : Measure ℝ) t) atTop (𝓝 (g t)))
    (hg : ContinuousAt g 0) :
    ∃ μ₀ : ProbabilityMeasure ℝ,
      charFun (μ₀ : Measure ℝ) = g ∧ Tendsto μ atTop (𝓝 μ₀) := by
  have h_tight : IsTightMeasureSet (Set.range fun n ↦ (μ n : Measure ℝ)) :=
    isTightMeasureSet_of_tendsto_charFun hg hconv
  have h_compact : IsCompact (closure (Set.range μ)) := by
    apply isCompact_closure_of_isTightMeasureSet
    convert h_tight using 1
    ext ν; simp
  obtain ⟨μ₀, -, hμ₀⟩ := h_compact.exists_clusterPt (f := map μ atTop)
    (le_principal_iff.2 (mem_of_superset (range_mem_map) subset_closure))
  have hchar : charFun (μ₀ : Measure ℝ) = g := by
    obtain ⟨U, hU, hUμ⟩ := mapClusterPt_iff_ultrafilter.1 hμ₀
    funext t
    have h1 := (ProbabilityMeasure.tendsto_iff_forall_integral_rclike_tendsto ℂ).1 hUμ
      (BoundedContinuousFunction.innerProbChar t)
    have h2 := (hconv t).mono_left hU
    simp_rw [← charFun_eq_integral_innerProbChar] at h1
    exact tendsto_nhds_unique h1 h2
  refine ⟨μ₀, hchar, ProbabilityMeasure.tendsto_of_tendsto_charFun fun t ↦ ?_⟩
  rw [hchar]; exact hconv t

/-- **Lévy's continuity theorem, part (a).** If probability laws on the real line converge in
distribution (weakly) to a law `μ₀`, then their fingerprints converge to the fingerprint of
`μ₀` at every dial `t`. -/
theorem tendsto_charFun_of_tendsto_in_distribution (μ : ℕ → ProbabilityMeasure ℝ)
    (μ₀ : ProbabilityMeasure ℝ) (h : Tendsto μ atTop (𝓝 μ₀)) (t : ℝ) :
    Tendsto (fun n ↦ charFun (μ n : Measure ℝ) t) atTop
      (𝓝 (charFun (μ₀ : Measure ℝ) t)) := by
  exact ProbabilityMeasure.tendsto_iff_tendsto_charFun.1 h t

/-- **The fingerprint road to the Poisson law.** Let `B_n` count the failures among `n`
requests, each failing with chance `p n = λ / n` (for all large `n`). Then the binomial laws
`Bin(n, λ / n)`, viewed on the real line, converge in distribution to the Poisson law with
average `λ`. -/
theorem binomial_tendsto_poisson (lam : ℝ≥0) (p : ℕ → I)
    (hp : ∀ᶠ n : ℕ in atTop, (p n : ℝ) = (lam : ℝ) / n) :
    Tendsto (β := ProbabilityMeasure ℝ) (fun n ↦ ⟨Bin(ℝ, n, p n), inferInstance⟩) atTop
      (𝓝 ⟨Po(ℝ, lam), inferInstance⟩) := by
  refine ProbabilityMeasure.tendsto_of_tendsto_charFun fun t ↦ ?_
  simp only [ProbabilityMeasure.coe_mk, charFun_map_cast_binomial_aux,
    charFun_map_cast_poissonMeasure]
  refine Complex.tendsto_one_add_pow_exp_of_tendsto (tendsto_nhds_of_eventually_eq ?_)
  filter_upwards [hp, eventually_ge_atTop 1] with n hn h1
  have : (n : ℂ) ≠ 0 := by exact_mod_cast (by omega : n ≠ 0)
  have hc : ((p n : ℝ) : ℂ) = (lam : ℂ) / n := by rw [hn]; push_cast; rfl
  rw [hc]; field_simp

-- The card's paging sum: the Poisson chance of 5 or fewer failures with average 2 is
-- e^(-2) times 1 + 2 + 2 + 4/3 + 2/3 + 4/15 = 109/15.
example : (1 : ℚ) + 2 + 2 + 4 / 3 + 2 / 3 + 4 / 15 = 109 / 15 := by norm_num

-- The same sum written as the Poisson terms 2^k / k! for k = 0, ..., 5.
example : (∑ k ∈ Finset.range 6, (2 : ℚ) ^ k / (Nat.factorial k)) = 109 / 15 := by
  simp [Finset.sum_range_succ, Nat.factorial]
  norm_num

-- The worked example's scaling: 1,000 requests at chance 2/1000 each average 2 failures.
example : (1000 : ℚ) * (2 / 1000) = 2 := by norm_num

#print axioms levy_continuity_theorem
#print axioms tendsto_charFun_of_tendsto_in_distribution
#print axioms binomial_tendsto_poisson
