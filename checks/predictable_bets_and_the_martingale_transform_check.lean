-- Betting on a martingale: a bounded predictable betting strategy on a martingale gives a martingale with average gain zero, only a martingale passes that test, and capped doubling has mean gain 0 and mean deepest debt N/2.
import Mathlib.Probability.Martingale.Basic

open MeasureTheory

/-! Setting. `Ω` with probability measure `μ` and filtration `𝓕` (`𝓕 n` is what is known after
round `n`). `M n` is what $1 a round would have won after `n` rounds. The stake on round `k + 1`
is `H (k + 1)`; it is predictable when it is fixed by `𝓕 k`, that is, when the process
`fun k => H (k + 1)` is adapted to `𝓕`. The martingale transform is
`G n = ∑ k < n, H (k + 1) * (M (k + 1) - M k)`, so `G 0 = 0`. -/

/-- The card's theorem: if `M` is a martingale and every stake `H k` is predictable (fixed by
what is known before its round) and bounded by a constant `c_k`, then the gambler's running gain
`G n = ∑_{k=1}^{n} H_k (M_k - M_{k-1})` is a martingale, and its average is zero at every round. -/
theorem predictable_bounded_bets_on_martingale_are_martingale
    {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]
    {𝓕 : Filtration ℕ m0} {M H : ℕ → Ω → ℝ}
    (hM : Martingale M 𝓕 μ)
    (hpred : StronglyAdapted 𝓕 fun k => H (k + 1))
    (hbdd : ∀ k, ∃ c : ℝ, ∀ ω, |H k ω| ≤ c) :
    Martingale (fun n ω => ∑ k ∈ Finset.range n, H (k + 1) ω * (M (k + 1) ω - M k ω)) 𝓕 μ ∧
      ∀ n, ∫ ω, (∑ k ∈ Finset.range n, H (k + 1) ω * (M (k + 1) ω - M k ω)) ∂μ = 0 := by
  choose C hC using hbdd
  have hD : ∀ k, Integrable (fun ω => M (k + 1) ω - M k ω) μ := fun k =>
    (hM.integrable (k + 1)).sub (hM.integrable k)
  have hterm : ∀ k, Integrable (fun ω => H (k + 1) ω * (M (k + 1) ω - M k ω)) μ := fun k =>
    (hD k).bdd_mul (c := C (k + 1)) (hpred.stronglyMeasurable (i := k)).aestronglyMeasurable
      (ae_of_all _ fun ω => by simpa [Real.norm_eq_abs] using hC (k + 1) ω)
  have hint : ∀ n, Integrable
      (fun ω => ∑ k ∈ Finset.range n, H (k + 1) ω * (M (k + 1) ω - M k ω)) μ := fun n =>
    integrable_finsetSum _ fun k _ => hterm k
  have hadp : StronglyAdapted 𝓕
      (fun n ω => ∑ k ∈ Finset.range n, H (k + 1) ω * (M (k + 1) ω - M k ω)) := by
    intro n
    refine Finset.stronglyMeasurable_fun_sum _ fun k hk => ?_
    rw [Finset.mem_range] at hk
    exact (hpred.stronglyMeasurable_le hk.le).mul
      ((hM.stronglyAdapted.stronglyMeasurable_le (Nat.succ_le_of_lt hk)).sub
        (hM.stronglyAdapted.stronglyMeasurable_le hk.le))
  have hmart : Martingale
      (fun n ω => ∑ k ∈ Finset.range n, H (k + 1) ω * (M (k + 1) ω - M k ω)) 𝓕 μ := by
    refine martingale_of_condExp_sub_eq_zero_nat hadp hint fun i => ?_
    have heq : ((fun ω => ∑ k ∈ Finset.range (i + 1), H (k + 1) ω * (M (k + 1) ω - M k ω)) -
        fun ω => ∑ k ∈ Finset.range i, H (k + 1) ω * (M (k + 1) ω - M k ω)) =
        (fun ω => H (i + 1) ω) * (fun ω => M (i + 1) ω - M i ω) := by
      funext ω
      simp [Finset.sum_range_succ]
    rw [heq]
    have hDz : μ[fun ω => M (i + 1) ω - M i ω | 𝓕 i] =ᵐ[μ] 0 := by
      have h1 := condExp_sub (m := 𝓕 i) (hM.integrable (i + 1)) (hM.integrable i)
      have h2 := hM.condExp_ae_eq (Nat.le_succ i)
      have h3 : μ[M i | 𝓕 i] = M i :=
        condExp_of_stronglyMeasurable (𝓕.le i) (hM.stronglyAdapted i) (hM.integrable i)
      have h4 : (fun ω => M (i + 1) ω - M i ω) = M (i + 1) - M i := rfl
      rw [h4]
      filter_upwards [h1, h2] with ω hω1 hω2
      simp [hω1, hω2, h3]
    filter_upwards [condExp_mul_of_stronglyMeasurable_left (m := 𝓕 i) (μ := μ) (hpred i)
      (hterm i) (hD i), hDz] with ω hω1 hω2
    simp [hω1, hω2]
  refine ⟨hmart, fun n => ?_⟩
  have h := hmart.condExp_ae_eq (Nat.zero_le n)
  rw [← integral_condExp (𝓕.le 0), integral_congr_ae h]
  simp

/-- The converse: if an adapted, integrable game `M` gives average gain zero at every round to
every bounded predictable strategy, then `M` is a martingale. Being fair and being unbeatable by
predictable bets are the same property. -/
theorem martingale_of_every_predictable_bet_fair
    {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]
    {𝓕 : Filtration ℕ m0} {M : ℕ → Ω → ℝ}
    (hadapt : StronglyAdapted 𝓕 M) (hint : ∀ n, Integrable (M n) μ)
    (hfair : ∀ H : ℕ → Ω → ℝ, StronglyAdapted 𝓕 (fun k => H (k + 1)) →
      (∀ k, ∃ c : ℝ, ∀ ω, |H k ω| ≤ c) →
      ∀ n, ∫ ω, (∑ k ∈ Finset.range n, H (k + 1) ω * (M (k + 1) ω - M k ω)) ∂μ = 0) :
    Martingale M 𝓕 μ := by
  refine martingale_of_setIntegral_eq_succ hadapt hint fun i s hs => ?_
  classical
  let H : ℕ → Ω → ℝ := fun k => if k = i + 1 then s.indicator (fun _ => (1 : ℝ)) else 0
  have hH : StronglyAdapted 𝓕 (fun k => H (k + 1)) := by
    intro k
    by_cases hk : k = i
    · subst hk
      simp only [H, ite_true]
      exact (stronglyMeasurable_const.indicator hs)
    · have : k + 1 ≠ i + 1 := by omega
      simp only [H, this, ite_false]
      exact stronglyMeasurable_const
  have hb : ∀ k, ∃ c : ℝ, ∀ ω, |H k ω| ≤ c := by
    intro k
    refine ⟨1, fun ω => ?_⟩
    simp only [H]
    split_ifs
    · by_cases hω : ω ∈ s <;> simp [hω]
    · simp
  have h := hfair H hH hb (i + 1)
  have hsum : ∀ ω, (∑ k ∈ Finset.range (i + 1), H (k + 1) ω * (M (k + 1) ω - M k ω)) =
      s.indicator (fun ω => M (i + 1) ω - M i ω) ω := by
    intro ω
    rw [Finset.sum_range_succ, Finset.sum_eq_zero]
    · by_cases hω : ω ∈ s <;> simp [H, hω]
    · intro k hk
      rw [Finset.mem_range] at hk
      have : k ≠ i := by omega
      simp [H, this]
  simp_rw [hsum] at h
  rw [integral_indicator (𝓕.le i s hs), integral_sub (hint (i + 1)).integrableOn
    (hint i).integrableOn] at h
  linarith

/-- Doubling with a pocket of `2^N - 1` dollars on a fair coin: the first win comes at round `k`
with chance `2^{-k}` and leaves the gambler $1 ahead after a deepest debt of `2^{k-1} - 1`; all
`N` tosses lose with chance `2^{-N}`, a loss and deepest debt of `2^N - 1`. The average gain is
exactly 0 and the average deepest debt is `N / 2`. -/
theorem capped_doubling_mean_gain_zero_and_mean_debt_half_N (N : ℕ) :
    (∑ k ∈ Finset.Icc 1 N, (1 / 2 : ℚ) ^ k * 1) + (1 / 2 : ℚ) ^ N * (-((2 : ℚ) ^ N - 1)) = 0 ∧
    (∑ k ∈ Finset.Icc 1 N, (1 / 2 : ℚ) ^ k * ((2 : ℚ) ^ (k - 1) - 1))
        + (1 / 2 : ℚ) ^ N * ((2 : ℚ) ^ N - 1) = N / 2 := by
  have hgeo : ∀ n : ℕ, ∑ k ∈ Finset.Icc 1 n, (1 / 2 : ℚ) ^ k = 1 - (1 / 2 : ℚ) ^ n := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Finset.sum_Icc_succ_top (by omega), ih, pow_succ]
      ring
  have hpow : ∀ n : ℕ, (1 / 2 : ℚ) ^ n * (2 : ℚ) ^ n = 1 := by
    intro n
    rw [← mul_pow]; norm_num
  have hterm : ∀ k ∈ Finset.Icc 1 N,
      (1 / 2 : ℚ) ^ k * ((2 : ℚ) ^ (k - 1) - 1) = 1 / 2 - (1 / 2 : ℚ) ^ k := by
    intro k hk
    obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by simp at hk; omega⟩
    simp only [Nat.add_sub_cancel]
    rw [pow_succ, mul_sub, mul_one]
    have := hpow j
    linear_combination (1 / 2 : ℚ) * this
  constructor
  · simp only [mul_one]
    rw [hgeo]
    linear_combination (-1 : ℚ) * hpow N
  · rw [Finset.sum_congr rfl hterm, Finset.sum_sub_distrib, hgeo]
    rw [Finset.sum_const, Nat.card_Icc, nsmul_eq_mul, Nat.add_sub_cancel]
    linear_combination hpow N

/-! The card's worked numbers: the $15 pocket, N = 4, sixteen equally likely toss sequences. -/

-- The pocket pays for four bets: 1 + 2 + 4 + 8 = 15 = 2^4 - 1.
example : 1 + 2 + 4 + 8 = 2 ^ 4 - 1 ∧ 2 ^ 4 - 1 = 15 := by norm_num

-- Each first win repays the earlier losses and leaves $1.
example : (1 : ℤ) = 1 ∧ -1 + 2 = (1 : ℤ) ∧ -1 - 2 + 4 = (1 : ℤ) ∧ -1 - 2 - 4 + 8 = (1 : ℤ) ∧
    -1 - 2 - 4 - 8 = (-15 : ℤ) := by norm_num

-- Chance of finishing ahead: 1/2 + 1/4 + 1/8 + 1/16 = 15/16 = 0.9375.
example : (1 / 2 + 1 / 4 + 1 / 8 + 1 / 16 : ℚ) = 15 / 16 := by norm_num

-- Average gain: 15/16 × 1 − 1/16 × 15 = 0.
example : (15 / 16 * 1 - 1 / 16 * 15 : ℚ) = 0 := by norm_num

-- Average money staked: 1 + 2 × 1/2 + 4 × 1/4 + 8 × 1/8 = 4.
example : (1 + 2 * (1 / 2) + 4 * (1 / 4) + 8 * (1 / 8) : ℚ) = 4 := by norm_num

-- Average deepest debt: 0 × 1/2 + 1 × 1/4 + 3 × 1/8 + 7 × 1/16 + 15 × 1/16 = 2 = N/2.
example : (0 * (1 / 2) + 1 * (1 / 4) + 3 * (1 / 8) + 7 * (1 / 16) + 15 * (1 / 16) : ℚ) = 4 / 2 := by
  norm_num

-- Ten doublings: the pocket is $1,023, and the chance of a winning session is 1 − 1/1024 = 1023/1024.
example : (2 : ℤ) ^ 10 - 1 = 1023 ∧ (1 - 1 / 2 ^ 10 : ℚ) = 1023 / 1024 := by norm_num

-- Letting the stake peek (stake = the toss itself, ±1) wins $4 on every one of the 16 sequences.
example : ∀ w : Fin 4 → Bool,
    ∑ i, (if w i then (1 : ℤ) else -1) * (if w i then (1 : ℤ) else -1) = 4 := by decide

#print axioms predictable_bounded_bets_on_martingale_are_martingale
#print axioms martingale_of_every_predictable_bet_fair
#print axioms capped_doubling_mean_gain_zero_and_mean_debt_half_N
