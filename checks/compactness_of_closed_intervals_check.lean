-- Compactness of [a, b]: every list in [a, b] has a subsequence settling at a point of [a, b], every open cover of [a, b] has a finite subcover, on the real line both tests mean "closed and bounded", and (0, 1] and [0, infinity) fail both.
import Mathlib.Topology.Order.Compact
import Mathlib.Topology.Sequences
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecificLimits.Basic

open Filter Topology Set

universe u

/-- Helper: on the real line, compact means closed and inside some `[a, b]`. -/
theorem compactness_helper_compact_iff (K : Set ℝ) :
    IsCompact K ↔ (IsClosed K ∧ ∃ a b : ℝ, K ⊆ Icc a b) := by
  rw [Metric.isCompact_iff_isClosed_bounded]
  refine and_congr Iff.rfl ⟨fun h => ?_, fun ⟨a, b, h⟩ => (Metric.isBounded_Icc a b).subset h⟩
  obtain ⟨r, hr⟩ := h.subset_closedBall 0
  exact ⟨0 - r, 0 + r, by rwa [← Real.closedBall_eq_Icc]⟩

/-- Helper: the finite-subcover test for index types in any universe gives compactness. -/
theorem compactness_helper_cover_compact (K : Set ℝ)
    (h : ∀ (ι : Type u) (U : ι → Set ℝ), (∀ i, IsOpen (U i)) → K ⊆ ⋃ i, U i →
        ∃ t : Finset ι, K ⊆ ⋃ i ∈ t, U i) : IsCompact K := by
  rw [isCompact_iff_finite_subcover]
  intro ι U hU hcov
  obtain ⟨t, ht⟩ := h (ULift.{u} ι) (fun i => U i.down) (fun i => hU i.down) (by
    intro x hx
    obtain ⟨i, hi⟩ := mem_iUnion.1 (hcov hx)
    exact mem_iUnion.2 ⟨⟨i⟩, hi⟩)
  refine ⟨t.map ⟨ULift.down, ULift.down_injective⟩, ?_⟩
  intro x hx
  obtain ⟨i, hi, hxi⟩ := mem_iUnion₂.1 (ht hx)
  exact mem_iUnion₂.2 ⟨i.down, Finset.mem_map_of_mem _ hi, hxi⟩

/-- On a closed, bounded interval `[a, b]` of real numbers, every list `x` whose terms all lie
in `[a, b]` has a subsequence `x (φ 0), x (φ 1), ...` (with `φ` strictly increasing) that
settles at some point `c` of `[a, b]` (Bolzano–Weierstrass), and every cover of `[a, b]` by
open sets `U i` can be cut down to finitely many of them that still cover it (Heine–Borel). -/
theorem closed_interval_seq_and_cover_compact (a b : ℝ) :
    (∀ x : ℕ → ℝ, (∀ n, x n ∈ Icc a b) →
        ∃ c ∈ Icc a b, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (x ∘ φ) atTop (𝓝 c)) ∧
    (∀ (ι : Type u) (U : ι → Set ℝ), (∀ i, IsOpen (U i)) → Icc a b ⊆ ⋃ i, U i →
        ∃ t : Finset ι, Icc a b ⊆ ⋃ i ∈ t, U i) := by
  have hK : IsCompact (Icc a b) := isCompact_Icc
  exact ⟨fun x hx => hK.tendsto_subseq hx,
    fun ι U hU hcov => hK.elim_finite_subcover U hU hcov⟩

/-- On the real line, a set `K` passes the cover test (every open cover has a finite subcover)
exactly when it is closed and bounded (it fits inside some interval `[a, b]`), and it passes the
subsequence test (every list in `K` has a subsequence settling at a point of `K`) exactly when
it is closed and bounded. So the two tests agree. -/
theorem real_cover_test_and_seq_test_iff_closed_bounded (K : Set ℝ) :
    ((∀ (ι : Type u) (U : ι → Set ℝ), (∀ i, IsOpen (U i)) → K ⊆ ⋃ i, U i →
        ∃ t : Finset ι, K ⊆ ⋃ i ∈ t, U i) ↔ (IsClosed K ∧ ∃ a b : ℝ, K ⊆ Icc a b)) ∧
    ((∀ x : ℕ → ℝ, (∀ n, x n ∈ K) →
        ∃ c ∈ K, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (x ∘ φ) atTop (𝓝 c)) ↔
      (IsClosed K ∧ ∃ a b : ℝ, K ⊆ Icc a b)) := by
  refine ⟨⟨fun h => (compactness_helper_compact_iff K).1 (compactness_helper_cover_compact K h),
    fun h ι U hU hcov => ((compactness_helper_compact_iff K).2 h).elim_finite_subcover U hU hcov⟩,
    ⟨fun h => (compactness_helper_compact_iff K).1 (isCompact_iff_isSeqCompact.2 fun x hx => h x hx),
    fun h x hx => ((compactness_helper_compact_iff K).2 h).tendsto_subseq hx⟩⟩

/-- `(0, 1]` and `[0, infinity)` fail both tests. On `(0, 1]` some list has no subsequence
settling inside it, and the open sets `(1/n, 2)` for `n = 1, 2, 3, ...` cover it with no finite
subcover. On `[0, infinity)` some list has no subsequence settling inside it, and the open sets
`(-1, n)` cover it with no finite subcover. -/
theorem half_open_and_unbounded_intervals_fail_both_tests :
    (¬ (∀ x : ℕ → ℝ, (∀ n, x n ∈ Ioc 0 1) →
        ∃ c ∈ Ioc (0 : ℝ) 1, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (x ∘ φ) atTop (𝓝 c)) ∧
      Ioc (0 : ℝ) 1 ⊆ ⋃ n : ℕ, Ioo (1 / ((n : ℝ) + 1)) 2 ∧
      ∀ t : Finset ℕ, ¬ Ioc (0 : ℝ) 1 ⊆ ⋃ n ∈ t, Ioo (1 / ((n : ℝ) + 1)) 2) ∧
    (¬ (∀ x : ℕ → ℝ, (∀ n, x n ∈ Ici 0) →
        ∃ c ∈ Ici (0 : ℝ), ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (x ∘ φ) atTop (𝓝 c)) ∧
      Ici (0 : ℝ) ⊆ ⋃ n : ℕ, Ioo (-1) (n : ℝ) ∧
      ∀ t : Finset ℕ, ¬ Ici (0 : ℝ) ⊆ ⋃ n ∈ t, Ioo (-1) (n : ℝ)) := by
  refine ⟨⟨?_, ?_, ?_⟩, ⟨?_, ?_, ?_⟩⟩
  · intro h
    obtain ⟨c, hc, φ, hφ, hlim⟩ := h (fun n => 1 / ((n : ℝ) + 1)) (fun n => by
      refine ⟨by positivity, ?_⟩
      rw [div_le_one (by positivity)]
      have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
      linarith)
    have h0 : Tendsto ((fun n : ℕ => 1 / ((n : ℝ) + 1)) ∘ φ) atTop (𝓝 0) :=
      tendsto_one_div_add_atTop_nhds_zero_nat.comp hφ.tendsto_atTop
    have := tendsto_nhds_unique hlim h0
    exact (ne_of_gt hc.1) this
  · intro x hx
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt hx.1
    exact mem_iUnion.2 ⟨n, hn, by linarith [hx.2]⟩
  · intro t ht
    set M := t.sup id
    have hpos : (0 : ℝ) < (M : ℝ) + 1 := by positivity
    have hx : 1 / ((M : ℝ) + 1) ∈ Ioc (0 : ℝ) 1 := by
      refine ⟨by positivity, ?_⟩
      rw [div_le_one hpos]
      have : (0 : ℝ) ≤ M := Nat.cast_nonneg M
      linarith
    obtain ⟨n, hn, hxn⟩ := mem_iUnion₂.1 (ht hx)
    have hnM : (n : ℝ) ≤ M := by exact_mod_cast (Finset.le_sup (f := id) hn)
    have : 1 / ((M : ℝ) + 1) ≤ 1 / ((n : ℝ) + 1) :=
      one_div_le_one_div_of_le (by positivity) (by linarith)
    linarith [hxn.1]
  · intro h
    obtain ⟨c, -, φ, hφ, hlim⟩ := h (fun n => (n : ℝ)) (fun n => mem_Ici.2 (Nat.cast_nonneg n))
    have htop : Tendsto ((fun n : ℕ => (n : ℝ)) ∘ φ) atTop atTop :=
      tendsto_natCast_atTop_atTop.comp hφ.tendsto_atTop
    exact not_tendsto_nhds_of_tendsto_atTop htop c hlim
  · intro x hx
    obtain ⟨n, hn⟩ := exists_nat_gt x
    exact mem_iUnion.2 ⟨n, by linarith [show (0 : ℝ) ≤ x from hx], hn⟩
  · intro t ht
    set M := t.sup id
    have hx : (M : ℝ) ∈ Ici (0 : ℝ) := mem_Ici.2 (Nat.cast_nonneg M)
    obtain ⟨n, hn, hxn⟩ := mem_iUnion₂.1 (ht hx)
    have hnM : (n : ℝ) ≤ M := by exact_mod_cast (Finset.le_sup (f := id) hn)
    linarith [hxn.2]

-- The card's list x_n = (-1)^n (1 + 1/n): x_3 = -4/3 and x_17 = -18/17.
example : (-1 : ℚ) ^ 3 * (1 + 1 / 3) = -4 / 3 := by norm_num
example : (-1 : ℚ) ^ 17 * (1 + 1 / 17) = -18 / 17 := by norm_num

-- Odd terms sit exactly 1/n below -1: for every odd n, x_n = -1 - 1/n.
example (k : ℕ) : (-1 : ℚ) ^ (2 * k + 1) * (1 + 1 / ((2 * k + 1 : ℕ) : ℚ)) =
    -1 - 1 / ((2 * k + 1 : ℕ) : ℚ) := by
  rw [pow_succ, pow_mul]
  norm_num
  ring

-- Stage 20: the kept half has width 4 / 2^20, and the pick n = 262145 lies within it of -1.
example : (1 : ℚ) / 262145 ≤ 4 / 2 ^ 20 := by norm_num

-- The whole list does not settle: x_1000 - x_1001 = 2 + 1/1000 + 1/1001.
example : (-1 : ℚ) ^ 1000 * (1 + 1 / 1000) - (-1 : ℚ) ^ 1001 * (1 + 1 / 1001) =
    2 + 1 / 1000 + 1 / 1001 := by norm_num

-- 0.1 lies inside (1/11, 2) with room 1/10 - 1/11 = 1/110 on its left.
example : (1 : ℚ) / 11 < 1 / 10 ∧ (1 : ℚ) / 10 - 1 / 11 = 1 / 110 := by norm_num

-- Two sets, (-1/10, 1/10) and (1/11, 2), already cover [0, 1].
example : Icc (0 : ℝ) 1 ⊆ Ioo (-1 / 10) (1 / 10) ∪ Ioo (1 / 11) 2 := by
  intro x hx
  by_cases h : x < 1 / 10
  · left; exact ⟨by linarith [hx.1], h⟩
  · right; exact ⟨by linarith, by linarith [hx.2]⟩

#print axioms compactness_helper_compact_iff
#print axioms compactness_helper_cover_compact
#print axioms closed_interval_seq_and_cover_compact
#print axioms real_cover_test_and_seq_test_iff_closed_bounded
#print axioms half_open_and_unbounded_intervals_fail_both_tests
