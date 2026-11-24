-- Rao-Blackwell and Lehmann-Scheffe: averaging an unbiased rule given a sufficient statistic keeps it unbiased and never raises its variance, and when that statistic is also complete the result is the unique unbiased rule with the least variance; the Poisson total is complete.
import Mathlib.Probability.CondVar
import Mathlib.Probability.Kernel.CondDistrib
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Analysis.Analytic.OfScalars
import Mathlib.Analysis.Analytic.Uniqueness
import Mathlib.Analysis.Analytic.IsolatedZeros

open MeasureTheory ProbabilityTheory
open scoped NNReal

/-- **Rao–Blackwell.** The data live in a space `Ω`, the unknown is `θ`, and `P θ` is the law of
the data when the unknown is `θ`. The statistic `T` is sufficient: once `T = t` is known, the rest
of the data has one law `κ t` that does not depend on the unknown (for every `θ`, `κ` is a version
of the conditional law of the data given `T` under `P θ`). Let `W` be a rule with finite variance
that is unbiased for `target θ` at every `θ`. Then the improved rule `φ(t) = ∫ W d(κ t)` uses no
`θ`, and at every `θ`:
* `φ(T)` is the conditional expectation `E[W | T]`;
* `φ(T)` is still unbiased for `target θ`;
* `Var(φ(T)) = Var(W) − E[Var(W | T)]`;
* so `Var(φ(T)) ≤ Var(W)`. -/
theorem rao_blackwell
    {Θ Ω τ : Type*} [MeasurableSpace Ω] [StandardBorelSpace Ω] [Nonempty Ω] {mτ : MeasurableSpace τ}
    (P : Θ → Measure Ω) [∀ θ, IsProbabilityMeasure (P θ)]
    (T : Ω → τ) (hT : Measurable T)
    (κ : Kernel τ Ω) (hsuff : ∀ θ, condDistrib id T (P θ) =ᵐ[(P θ).map T] κ)
    (target : Θ → ℝ) (W : Ω → ℝ) (hW2 : ∀ θ, MemLp W 2 (P θ))
    (hWunb : ∀ θ, ∫ ω, W ω ∂(P θ) = target θ) :
    ∀ θ,
      (P θ)[W | mτ.comap T] =ᵐ[P θ] (fun ω => ∫ ω', W ω' ∂(κ (T ω))) ∧
      ∫ ω, (∫ ω', W ω' ∂(κ (T ω))) ∂(P θ) = target θ ∧
      Var[fun ω => ∫ ω', W ω' ∂(κ (T ω)); P θ] =
        Var[W; P θ] - ∫ ω, (Var[W; P θ | mτ.comap T]) ω ∂(P θ) ∧
      Var[fun ω => ∫ ω', W ω' ∂(κ (T ω)); P θ] ≤ Var[W; P θ] := by
  intro θ
  have hm : mτ.comap T ≤ ‹MeasurableSpace Ω› := hT.comap_le
  have h1 := condExp_ae_eq_integral_condDistrib_id (μ := P θ) hT ((hW2 θ).integrable one_le_two)
  have hκ : ∀ᵐ ω ∂(P θ), condDistrib id T (P θ) (T ω) = κ (T ω) :=
    ae_of_ae_map hT.aemeasurable (hsuff θ)
  have hce : (P θ)[W | mτ.comap T] =ᵐ[P θ] (fun ω => ∫ ω', W ω' ∂(κ (T ω))) := by
    filter_upwards [h1, hκ] with ω h1ω hκω
    rw [h1ω, hκω]
  have htot := integral_condVar_add_variance_condExp hm (hW2 θ)
  rw [variance_congr hce] at htot
  have hnn : 0 ≤ ∫ ω, (Var[W; P θ | mτ.comap T]) ω ∂(P θ) := by
    apply integral_nonneg_of_ae
    exact condExp_nonneg (Filter.Eventually.of_forall fun ω => sq_nonneg _)
  refine ⟨hce, ?_, ?_, ?_⟩
  · rw [← integral_congr_ae hce, integral_condExp hm, hWunb]
  · linarith
  · linarith

/-- **Lehmann–Scheffé.** Same setting: `T` is sufficient, with the `θ`-free conditional law `κ`.
`T` is also complete: a function `g` of `T` whose average is zero at every `θ` is zero (almost
surely, at every `θ`). Let `φ(T)` be a function of `T` that is unbiased for `target θ` at every
`θ`. Then for every rule `U` (a measurable function of the data) with finite variance that is
unbiased for `target θ` at every `θ`, and at every `θ`: `Var(φ(T)) ≤ Var(U)`, with equality only
when `U = φ(T)`. So `φ(T)` is the unique unbiased rule with the least variance (the UMVUE). -/
theorem lehmann_scheffe
    {Θ Ω τ : Type*} [MeasurableSpace Ω] [StandardBorelSpace Ω] [Nonempty Ω] {mτ : MeasurableSpace τ}
    (P : Θ → Measure Ω) [∀ θ, IsProbabilityMeasure (P θ)]
    (T : Ω → τ) (hT : Measurable T)
    (κ : Kernel τ Ω) (hsuff : ∀ θ, condDistrib id T (P θ) =ᵐ[(P θ).map T] κ)
    (hcomplete : ∀ g : τ → ℝ, Measurable g → (∀ θ, Integrable (g ∘ T) (P θ)) →
      (∀ θ, ∫ ω, g (T ω) ∂(P θ) = 0) → ∀ θ, g ∘ T =ᵐ[P θ] 0)
    (target : Θ → ℝ) (φ : τ → ℝ) (hφm : Measurable φ)
    (hφint : ∀ θ, Integrable (φ ∘ T) (P θ)) (hφunb : ∀ θ, ∫ ω, φ (T ω) ∂(P θ) = target θ)
    (U : Ω → ℝ) (hUm : Measurable U) (hU2 : ∀ θ, MemLp U 2 (P θ))
    (hUunb : ∀ θ, ∫ ω, U ω ∂(P θ) = target θ) :
    ∀ θ, Var[φ ∘ T; P θ] ≤ Var[U; P θ] ∧
      (Var[U; P θ] = Var[φ ∘ T; P θ] → U =ᵐ[P θ] φ ∘ T) := by
  have hRB := rao_blackwell P T hT κ hsuff target U hU2 hUunb
  set ψ : τ → ℝ := fun t => ∫ ω', U ω' ∂(κ t) with hψ
  have hψm : Measurable ψ := (hUm.stronglyMeasurable.integral_kernel (κ := κ)).measurable
  have hm : mτ.comap T ≤ ‹MeasurableSpace Ω› := hT.comap_le
  have hψint : ∀ θ, Integrable (ψ ∘ T) (P θ) := fun θ =>
    integrable_condExp.congr (hRB θ).1
  have hg := hcomplete (ψ - φ) (hψm.sub hφm)
    (fun θ => (hψint θ).sub (hφint θ))
    (fun θ => by
      have := integral_sub (hψint θ) (hφint θ)
      simp only [Function.comp_def, Pi.sub_apply] at this ⊢
      rw [this, hφunb, (hRB θ).2.1, sub_self])
  intro θ
  have heq : φ ∘ T =ᵐ[P θ] ψ ∘ T := by
    filter_upwards [hg θ] with ω hω
    simp only [Function.comp_apply, Pi.sub_apply, Pi.zero_apply, sub_eq_zero] at hω ⊢
    exact hω.symm
  obtain ⟨hce, _, hvar, hle⟩ := hRB θ
  rw [variance_congr heq]
  refine ⟨hle, fun hUV => ?_⟩
  -- the integral of the conditional variance is zero
  have hint0 : ∫ ω, (Var[U; P θ | mτ.comap T]) ω ∂(P θ) = 0 := by
    have : Var[ψ ∘ T; P θ] = Var[U; P θ] := hUV.symm
    change Var[fun ω => ψ (T ω); P θ] = _ at this
    linarith
  have hsq : Integrable ((U - (P θ)[U | mτ.comap T]) ^ 2) (P θ) :=
    ((hU2 θ).sub ((hU2 θ).condExp one_le_two)).integrable_sq
  have hint1 : ∫ ω, ((U - (P θ)[U | mτ.comap T]) ^ 2) ω ∂(P θ) = 0 := by
    rw [← hint0, condVar, integral_condExp hm]
  have hz := (integral_eq_zero_iff_of_nonneg (fun ω => sq_nonneg _) hsq).1 hint1
  filter_upwards [hz, hce, heq] with ω hzω hceω heqω
  simp only [Pi.sub_apply, Pi.zero_apply, pow_eq_zero_iff two_ne_zero,
    sub_eq_zero] at hzω
  rw [hzω, hceω, heqω]; rfl

/-- **The Poisson total is complete.** With `n` hours, each Poisson with rate `λ`, the total `T` is
Poisson with mean `n λ`. If a function `g` of the total has average zero at every rate `λ > 0`,
then `g(t) = 0` for every whole number `t`. -/
theorem poisson_total_complete (n : ℕ) (hn : 0 < n) (g : ℕ → ℝ)
    (hint : ∀ lam : ℝ≥0, 0 < lam → Integrable g (poissonMeasure ((n : ℝ≥0) * lam)))
    (hzero : ∀ lam : ℝ≥0, 0 < lam → ∫ t, g t ∂(poissonMeasure ((n : ℝ≥0) * lam)) = 0) :
    ∀ t, g t = 0 := by
  set c : ℕ → ℝ := fun k => g k / (k.factorial : ℝ) with hc
  set p : FormalMultilinearSeries ℝ ℝ ℝ := FormalMultilinearSeries.ofScalars ℝ c with hp
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  -- summability at radius n
  have hsum : Summable fun k => ‖p k‖ * ((n : ℝ≥0) : ℝ) ^ k := by
    have h1 := (integrable_poissonMeasure_iff.1 (hint 1 one_pos)).mul_left (Real.exp n)
    refine h1.congr fun k => ?_
    simp only [hp, FormalMultilinearSeries.ofScalars_norm, hc, mul_one, NNReal.coe_natCast,
      Real.norm_eq_abs, abs_div, Nat.abs_cast]
    have : Real.exp n * Real.exp (-n) = 1 := by rw [← Real.exp_add]; simp
    field_simp
    rw [this]; ring
  have hrad : (0 : ENNReal) < p.radius := by
    refine lt_of_lt_of_le ?_ (p.le_radius_of_summable hsum)
    exact_mod_cast hn
  have hps : HasFPowerSeriesOnBall p.sum p 0 p.radius := p.hasFPowerSeriesOnBall hrad
  have hzero' : ∀ x : ℝ, 0 < x → p.sum x = 0 := by
    intro x hx
    obtain ⟨lam, hlamv⟩ : ∃ lam : ℝ≥0, (lam : ℝ) = x / n := ⟨⟨x / n, by positivity⟩, rfl⟩
    have hlampos : 0 < lam := by
      rw [← NNReal.coe_pos, hlamv]
      positivity
    have h := hzero lam hlampos
    rw [integral_poissonMeasure] at h
    have hr : (((n : ℝ≥0) * lam : ℝ≥0) : ℝ) = x := by
      rw [NNReal.coe_mul, hlamv, NNReal.coe_natCast]
      field_simp
    rw [hr] at h
    have h2 : p.sum x = ∑' k, c k • x ^ k := FormalMultilinearSeries.ofScalars_sum_eq c x
    rw [h2]
    have h3 : (∑' k, (Real.exp (-x) * x ^ k / (k.factorial : ℝ)) • g k)
        = Real.exp (-x) * ∑' k, c k • x ^ k := by
      rw [← tsum_mul_left]
      congr 1; ext k
      simp only [smul_eq_mul, hc]
      ring
    rw [h3] at h
    exact (mul_eq_zero.1 h).resolve_left (Real.exp_pos _).ne'
  have hfreq : ∃ᶠ z in nhdsWithin (0 : ℝ) {0}ᶜ, p.sum z = 0 := by
    have hev : ∀ᶠ z in nhdsWithin (0 : ℝ) (Set.Ioi 0), p.sum z = 0 :=
      Filter.mem_of_superset self_mem_nhdsWithin fun z hz => hzero' z hz
    exact (hev.frequently).filter_mono (nhdsWithin_mono _ fun z hz => ne_of_gt hz)
  have hev0 : p.sum =ᶠ[nhds 0] 0 := by
    rcases hps.analyticAt.eventually_eq_zero_or_eventually_ne_zero with h | h
    · exact h
    · exact absurd hfreq (Filter.not_frequently.2 h)
  have hp0 : p = 0 := hps.hasFPowerSeriesAt.eq_zero_of_eventually hev0
  have hc0 : c = 0 := (FormalMultilinearSeries.ofScalars_series_eq_zero ℝ).1 hp0
  intro t
  have := congrFun hc0 t
  simp only [hc, Pi.zero_apply, div_eq_zero_iff, Nat.cast_eq_zero] at this
  exact this.resolve_right (Nat.factorial_ne_zero t)

-- The card's whole-number worked examples, exactly.
-- The five hours 2, 3, 0, 1, 4 hold T = 10 calls.
example : 2 + 3 + 0 + 1 + 4 = 10 := by decide
-- The best unbiased estimate (4/5)^10, as an exact fraction (0.107374 on the card).
example : ((4 : ℚ) / 5) ^ 10 = 1048576 / 9765625 := by norm_num
-- The fraction of empty hours: 1 empty hour in 5.
example : ((1 : ℚ) / 5) = 1 / 5 := by norm_num
-- The house poll: E[W | K = 520] = K(n − K)/(n(n − 1)) = 520 × 480 / (1,000 × 999) (0.249850).
example : ((520 : ℚ) * (1000 - 520)) / (1000 * (1000 - 1)) = 416 / 1665 := by norm_num
-- The plug-in p-hat (1 − p-hat) = 0.52 × 0.48 = 0.2496.
example : ((52 : ℚ) / 100) * (48 / 100) = 156 / 625 := by norm_num

#print axioms rao_blackwell
#print axioms lehmann_scheffe
#print axioms poisson_total_complete
