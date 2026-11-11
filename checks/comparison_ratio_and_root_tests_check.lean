-- Convergence tests: one over n to the power p adds to a finite total exactly when p > 1, the ratio test decides when the limit of neighbour ratios is not 1, and the integral test traps the running totals between two areas.
import Mathlib.Analysis.PSeries
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.SumIntegralComparisons

open Filter Topology Finset

/-- The p-series: the running totals of 1/1^p + 1/2^p + 1/3^p + ... settle to a finite
limit exactly when p is bigger than one, for every real power p. -/
theorem p_series_converges_iff_one_lt (p : ℝ) :
    (∃ S : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, 1 / ((n : ℝ) + 1) ^ p) atTop (𝓝 S)) ↔
      1 < p := by
  have hnn : ∀ n : ℕ, 0 ≤ 1 / ((n : ℝ) + 1) ^ p := fun n => by positivity
  have hsum : Summable (fun n : ℕ => 1 / ((n : ℝ) + 1) ^ p) ↔ 1 < p := by
    rw [← Real.summable_one_div_nat_rpow (p := p),
      ← summable_nat_add_iff 1 (f := fun n : ℕ => 1 / (n : ℝ) ^ p)]
    simp
  rw [← hsum]
  constructor
  · rintro ⟨S, hS⟩
    exact ((hasSum_iff_tendsto_nat_of_nonneg hnn S).2 hS).summable
  · intro h
    exact ⟨_, h.hasSum.tendsto_sum_nat⟩

/-- The ratio test: for terms that are positive from some position on, if the ratio of each
term to the one before tends to a limit L below 1, the running totals converge; if L is above 1,
or the ratios grow without end, they do not. -/
theorem ratio_test (a : ℕ → ℝ) (hpos : ∀ᶠ n in atTop, 0 < a n) :
    (∀ L : ℝ, Tendsto (fun n => a (n + 1) / a n) atTop (𝓝 L) → L < 1 →
      ∃ S : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n) atTop (𝓝 S)) ∧
    (∀ L : ℝ, Tendsto (fun n => a (n + 1) / a n) atTop (𝓝 L) → 1 < L →
      ¬ ∃ S : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n) atTop (𝓝 S)) ∧
    (Tendsto (fun n => a (n + 1) / a n) atTop atTop →
      ¬ ∃ S : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n) atTop (𝓝 S)) := by
  -- If the ratios are eventually above 1, the partial sums cannot converge.
  have key : (∀ᶠ n in atTop, 1 < a (n + 1) / a n) →
      ¬ ∃ S : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n) atTop (𝓝 S) := by
    rintro hr ⟨S, hS⟩
    have h0 : Tendsto a atTop (𝓝 0) := by
      have h1 : Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), a n) atTop (𝓝 S) :=
        hS.comp (tendsto_add_atTop_nat 1)
      have := h1.sub hS
      simp only [sub_self] at this
      refine this.congr ?_
      intro N
      simp [Finset.sum_range_succ]
    obtain ⟨N, hN⟩ := eventually_atTop.1 (hpos.and hr)
    have hmono : ∀ n, N ≤ n → a N ≤ a n := by
      intro n hn
      induction n, hn using Nat.le_induction with
      | base => exact le_refl _
      | succ m hm ih =>
        obtain ⟨hp, hq⟩ := hN m hm
        have : a m < a (m + 1) := by
          rw [lt_div_iff₀ hp, one_mul] at hq
          exact hq
        linarith
    have hpN : 0 < a N := (hN N le_rfl).1
    have hev := (h0.eventually (gt_mem_nhds hpN))
    obtain ⟨M, hM⟩ := eventually_atTop.1 hev
    have := hM (max M N) (le_max_left _ _)
    have := hmono (max M N) (le_max_right _ _)
    linarith
  refine ⟨?_, ?_, ?_⟩
  · intro L hL hL1
    have hs : Summable a := by
      refine summable_of_ratio_test_tendsto_lt_one hL1 ?_ ?_
      · filter_upwards [hpos] with n hn using hn.ne'
      · refine hL.congr' ?_
        filter_upwards [hpos, (tendsto_add_atTop_nat 1).eventually hpos] with n hn hn1
        rw [Real.norm_of_nonneg hn.le, Real.norm_of_nonneg hn1.le]
    exact ⟨_, hs.hasSum.tendsto_sum_nat⟩
  · intro L hL hL1
    exact key (hL.eventually (lt_mem_nhds hL1))
  · intro h
    exact key (h.eventually_gt_atTop 1)

/-- The integral test's sandwich: if a curve f is positive and falling from x = 1 on, and the
terms are a_n = f(n), then for every N ≥ 1 the running total S_N = f(1) + ... + f(N) satisfies
(area under f from 1 to N + 1) ≤ S_N ≤ f(1) + (area under f from 1 to N). -/
theorem integral_test_sandwich (f : ℝ → ℝ) (hpos : ∀ x, 1 ≤ x → 0 < f x)
    (hfall : AntitoneOn f (Set.Ici 1)) (N : ℕ) (hN : 1 ≤ N) :
    ∫ x in (1 : ℝ)..(N + 1), f x ≤ ∑ n ∈ range N, f (n + 1) ∧
      ∑ n ∈ range N, f (n + 1) ≤ f 1 + ∫ x in (1 : ℝ)..N, f x := by
  constructor
  · have h := AntitoneOn.integral_le_sum (x₀ := (1 : ℝ)) (a := N) (f := f)
      (hfall.mono Set.Icc_subset_Ici_self)
    simpa [add_comm] using h
  · obtain ⟨M, rfl⟩ : ∃ M, N = M + 1 := ⟨N - 1, by omega⟩
    have h := AntitoneOn.sum_le_integral (x₀ := (1 : ℝ)) (a := M) (f := f)
      (hfall.mono Set.Icc_subset_Ici_self)
    rw [Finset.sum_range_succ']
    push_cast
    simp only [Nat.cast_add, Nat.cast_one] at h
    simp only [zero_add]
    rw [show (M : ℝ) + 1 = 1 + M by ring]
    have : ∑ i ∈ range M, f ((i : ℝ) + 1 + 1) = ∑ i ∈ range M, f (1 + ((i : ℝ) + 1)) := by
      refine Finset.sum_congr rfl fun i _ => ?_
      ring_nf
    rw [this]
    linarith

-- The harmonic series after 2^10 = 1024 terms is at least the doubling floor 1 + 10/2 = 6.
example : (∑ n ∈ range 1024, (1 : ℚ) / (n + 1)) ≥ 1 + 10 / 2 := by
  decide +kernel

-- The squares' ceiling at N = 1000: 1 + the telescoping sum of 1/((n - 1)n), n = 2 to 1000,
-- is exactly 2 - 1/1000, and the first 1000 squares add to no more than that.
example : (1 : ℚ) + ∑ n ∈ range 999, 1 / (((n : ℚ) + 1) * (n + 2)) = 2 - 1 / 1000 := by
  decide +kernel

example : (∑ n ∈ range 1000, (1 : ℚ) / ((n + 1) * (n + 1))) ≤ 2 - 1 / 1000 := by
  decide +kernel

-- The first 20 terms of n/2^n add to 2 - (20 + 2)/2^20.
example : (∑ n ∈ range 20, ((n : ℚ) + 1) / 2 ^ (n + 1)) = 2 - 22 / 2 ^ 20 := by
  norm_num [Finset.sum_range_succ]

#print axioms p_series_converges_iff_one_lt
#print axioms ratio_test
#print axioms integral_test_sandwich
