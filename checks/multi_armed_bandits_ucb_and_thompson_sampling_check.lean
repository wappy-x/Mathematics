-- Multi-armed bandits: regret is each rule's gap times its expected number of uses, and the deterministic steps of UCB1's count bound hold.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory

/-- Regret splits rule by rule (Step 1). Rule `i` is used in hour `t` when `I t ω = i`, and the
hour's result `X t ω` lies between 0 and 1. If, given that rule `i` is chosen, the result averages
to the rule's fixed chance `μ i` (so `E[X_t ; I_t = i] = μ_i P(I_t = i)`), then after `T` hours
the shortfall against `T` times the reference chance `μstar` (the best chance `μ*`) equals
`∑ i, (μstar - μ i) * E[N_i(T)]`, where `N_i(T)` counts the hours rule `i` was used. -/
theorem regret_eq_sum_gap_mul_expected_pulls {Ω ι : Type*} [MeasurableSpace Ω] [Fintype ι]
    [DecidableEq ι] (P : Measure Ω) [IsProbabilityMeasure P] (I : ℕ → Ω → ι) (X : ℕ → Ω → ℝ)
    (μ : ι → ℝ) (μstar : ℝ) (T : ℕ)
    (hI : ∀ t i, MeasurableSet {ω | I t ω = i})
    (hXm : ∀ t, Measurable (X t))
    (hX01 : ∀ t ω, X t ω ∈ Set.Icc (0 : ℝ) 1)
    (hmean : ∀ t i, ∫ ω in {ω | I t ω = i}, X t ω ∂P = μ i * P.real {ω | I t ω = i}) :
    (T : ℝ) * μstar - ∫ ω, ∑ t ∈ Finset.range T, X t ω ∂P
      = ∑ i, (μstar - μ i) *
          ∫ ω, (((Finset.range T).filter (fun t => I t ω = i)).card : ℝ) ∂P := by
  have hint : ∀ t, Integrable (X t) P := fun t =>
    Integrable.of_bound (hXm t).aestronglyMeasurable 1 (ae_of_all _ fun ω => by
      have := hX01 t ω
      rw [Real.norm_eq_abs, abs_le]
      constructor <;> linarith [this.1, this.2])
  have hsplit : ∀ t (f : Ω → ℝ) ω, f ω = ∑ i, {ω | I t ω = i}.indicator f ω := by
    intro t f ω
    simp only [Set.indicator_apply, Set.mem_ofPred_eq]
    rw [Finset.sum_ite_eq]
    simp
  have key1 : ∀ t, ∫ ω, X t ω ∂P = ∑ i, μ i * P.real {ω | I t ω = i} := by
    intro t
    have : (fun ω => X t ω) = fun ω => ∑ i, {ω | I t ω = i}.indicator (X t) ω :=
      funext fun ω => hsplit t (X t) ω
    rw [this, integral_finsetSum _ (fun i _ => (hint t).indicator (hI t i))]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [integral_indicator (hI t i), hmean]
  have hi1 : ∀ t i, Integrable ({ω | I t ω = i}.indicator (1 : Ω → ℝ)) P :=
    fun t i => (integrable_const (1 : ℝ)).indicator (hI t i)
  have key2 : ∀ t, ∑ i, P.real {ω | I t ω = i} = 1 := by
    intro t
    have h1 : (fun _ : Ω => (1 : ℝ)) = fun ω => ∑ i, {ω | I t ω = i}.indicator 1 ω :=
      funext fun ω => hsplit t 1 ω
    have h2 := congrArg (fun f => ∫ ω, f ω ∂P) h1
    simp only at h2
    rw [integral_finsetSum _ (fun i _ => hi1 t i)] at h2
    simp only [integral_const, probReal_univ, smul_eq_mul, mul_one] at h2
    rw [h2]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [integral_indicator_one (hI t i)]
  have key3 : ∀ i, ∫ ω, (((Finset.range T).filter (fun t => I t ω = i)).card : ℝ) ∂P
      = ∑ t ∈ Finset.range T, P.real {ω | I t ω = i} := by
    intro i
    have : (fun ω => (((Finset.range T).filter (fun t => I t ω = i)).card : ℝ))
        = fun ω => ∑ t ∈ Finset.range T, {ω | I t ω = i}.indicator 1 ω := by
      funext ω
      rw [Finset.card_filter]
      push_cast
      refine Finset.sum_congr rfl fun t _ => ?_
      simp [Set.indicator_apply]
    rw [this, integral_finsetSum _ (fun t _ => hi1 t i)]
    refine Finset.sum_congr rfl fun t _ => ?_
    rw [integral_indicator_one (hI t i)]
  rw [integral_finsetSum _ (fun t _ => hint t)]
  simp_rw [key3, key1, Finset.mul_sum, sub_mul, Finset.sum_sub_distrib]
  rw [Finset.sum_comm (f := fun i t => μstar * P.real {ω | I t ω = i}),
    Finset.sum_comm (f := fun i t => μ i * P.real {ω | I t ω = i})]
  simp_rw [← Finset.mul_sum, key2]
  simp [mul_comm]

/-- UCB1's bonus is small enough after enough tries (Step 3, case (c) fails): if a worse rule
with gap `Δ > 0` has been tried `m ≥ ⌈8 ln T / Δ²⌉` times, then at every hour `t ≤ T` twice its
bonus `√(2 ln t / m)` is at most the gap. -/
theorem two_mul_ucb_bonus_le_gap (T t m : ℕ) (Δ : ℝ) (hΔ : 0 < Δ) (ht : t ≤ T)
    (hm : ⌈8 * Real.log T / Δ ^ 2⌉₊ ≤ m) :
    2 * Real.sqrt (2 * Real.log t / m) ≤ Δ := by
  rcases Nat.eq_zero_or_pos m with rfl | hm0
  · simp; linarith
  have hlogt : Real.log t ≤ Real.log T := by
    rcases Nat.eq_zero_or_pos t with rfl | ht0
    · simpa using Real.log_natCast_nonneg T
    · exact Real.log_le_log (by exact_mod_cast ht0) (by exact_mod_cast ht)
  have hlogt0 : 0 ≤ Real.log t := Real.log_natCast_nonneg t
  have hmR : (0 : ℝ) < m := by exact_mod_cast hm0
  have hc : 8 * Real.log T / Δ ^ 2 ≤ m := (Nat.le_ceil _).trans (by exact_mod_cast hm)
  have hc' : 8 * Real.log T ≤ m * Δ ^ 2 := (div_le_iff₀ (by positivity)).mp hc
  have hle : 2 * Real.log t / m ≤ (Δ / 2) ^ 2 := by
    rw [div_le_iff₀ hmR]
    nlinarith
  have := Real.sqrt_le_sqrt hle
  rw [Real.sqrt_sq (by linarith)] at this
  linarith

/-- The three-way split in the proof of UCB1's count bound: if the best rule's index is at most
rule `i`'s index, `x̄* + c* ≤ x̄ᵢ + cᵢ`, then (a) the best rule's average undershot by its bonus,
or (b) rule `i`'s average overshot by its bonus, or (c) the gap is less than twice rule `i`'s bonus. -/
theorem ucb_index_order_split (xstar cstar xi ci μstar μi : ℝ)
    (h : xstar + cstar ≤ xi + ci) :
    xstar ≤ μstar - cstar ∨ μi + ci ≤ xi ∨ μstar < μi + 2 * ci := by
  by_contra hc
  push Not at hc
  obtain ⟨h1, h2, h3⟩ := hc
  linarith

-- The card's hand state after 30 hours: 6 + 10 + 14 tries, and Thompson's beta laws
-- Beta(1 + s, 1 + N - s) are Beta(2, 6), Beta(6, 6) and Beta(9, 7).
example : 6 + 10 + 14 = 30 ∧ (1 + 1, 1 + 6 - 1) = (2, 6) ∧ (1 + 5, 1 + 10 - 5) = (6, 6) ∧
    (1 + 8, 1 + 14 - 8) = (9, 7) := by decide

#print axioms regret_eq_sum_gap_mul_expected_pulls
#print axioms two_mul_ucb_bonus_le_gap
#print axioms ucb_index_order_split
