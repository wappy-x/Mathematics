-- Summation by parts: the summation-by-parts identity holds, Dirichlet's test gives a convergent series with tail at most M times the first weight left out, and Abel's test follows.
import Mathlib.Analysis.SpecificLimits.Normed

open Filter Topology Finset

theorem sbp_shift_identity (a b : ℕ → ℝ) (N k : ℕ) :
    ∑ i ∈ range k, a (N + i) * b (N + i) =
      (∑ i ∈ range k, a (N + i)) * b (N + k) +
        ∑ i ∈ range k, (∑ j ∈ range (i + 1), a (N + j)) * (b (N + i) - b (N + i + 1)) := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [sum_range_succ, ih, sum_range_succ, sum_range_succ (fun i => (∑ j ∈ range (i + 1), a (N + j)) * (b (N + i) - b (N + i + 1))), sum_range_succ]
    rw [← add_assoc N k 1]
    ring

#print axioms sbp_shift_identity

theorem sbp_tail_bound (a b : ℕ → ℝ) (M : ℝ)
    (hstretch : ∀ K n, K < n → |∑ i ∈ Ico K n, a i| ≤ M)
    (hb_anti : Antitone b) (hb_zero : Tendsto b atTop (𝓝 0)) (N m : ℕ) (hNm : N ≤ m) :
    |∑ i ∈ Ico N m, a i * b i| ≤ M * b N := by
  have hdrop : ∀ n, 0 ≤ b n - b (n + 1) := fun n => sub_nonneg.mpr (hb_anti (Nat.le_succ n))
  have hM : 0 ≤ M := le_trans (abs_nonneg _) (hstretch 0 1 Nat.zero_lt_one)
  have hpart : ∀ k, |∑ i ∈ range k, a (N + i)| ≤ M := by
    intro k
    rcases Nat.eq_zero_or_pos k with rfl | hk
    · simpa using hM
    · have := hstretch N (N + k) (by omega)
      rwa [sum_Ico_eq_sum_range, Nat.add_sub_cancel_left] at this
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le hNm
  rw [sum_Ico_eq_sum_range, Nat.add_sub_cancel_left, sbp_shift_identity]
  have hbk : 0 ≤ b (N + k) := hb_anti.le_of_tendsto hb_zero _
  have htel : ∑ i ∈ range k, (b (N + i) - b (N + i + 1)) = b N - b (N + k) := by
    exact sum_range_sub' (fun i => b (N + i)) k
  have h1 : |(∑ i ∈ range k, a (N + i)) * b (N + k)| ≤ M * b (N + k) := by
    rw [abs_mul, abs_of_nonneg hbk]
    exact mul_le_mul_of_nonneg_right (hpart k) hbk
  have h2 : |∑ i ∈ range k, (∑ j ∈ range (i + 1), a (N + j)) * (b (N + i) - b (N + i + 1))|
      ≤ M * (b N - b (N + k)) := by
    refine (abs_sum_le_sum_abs _ _).trans ?_
    rw [← htel, mul_sum]
    refine sum_le_sum fun i _ => ?_
    rw [abs_mul, abs_of_nonneg (hdrop (N + i))]
    exact mul_le_mul_of_nonneg_right (hpart (i + 1)) (hdrop (N + i))
  calc _ ≤ _ := abs_add_le _ _
    _ ≤ M * b (N + k) + M * (b N - b (N + k)) := add_le_add h1 h2
    _ = M * b N := by ring

#print axioms sbp_tail_bound

/-- Dirichlet's test with its error bound. If every stretch of terms
`a K + ⋯ + a (n - 1)` (with `K < n`) is at most `M` in size, and the weights `b n`
never grow and head for 0, then the partial sums of `a n * b n` settle on a limit `S`,
and stopping after the first `N` terms misses `S` by at most `M` times the first weight
left out, `b N`. (Terms are counted from 0, so the first `N` terms are `0, …, N - 1`.) -/
theorem dirichlet_test_with_tail_bound (a b : ℕ → ℝ) (M : ℝ)
    (hstretch : ∀ K n, K < n → |∑ i ∈ Ico K n, a i| ≤ M)
    (hb_anti : Antitone b) (hb_zero : Tendsto b atTop (𝓝 0)) :
    ∃ S : ℝ, Tendsto (fun N => ∑ i ∈ range N, a i * b i) atTop (𝓝 S) ∧
      ∀ N, |S - ∑ i ∈ range N, a i * b i| ≤ M * b N := by
  set s : ℕ → ℝ := fun N => ∑ i ∈ range N, a i * b i with hs
  have hdiff : ∀ N m, N ≤ m → |s m - s N| ≤ M * b N := by
    intro N m hNm
    simp only [hs]
    rw [← sum_Ico_eq_sub _ hNm]
    exact sbp_tail_bound a b M hstretch hb_anti hb_zero N m hNm
  have hcauchy : CauchySeq s := by
    refine cauchySeq_of_le_tendsto_0 (fun N => 2 * (M * b N)) ?_ ?_
    · intro n m N hn hm
      rw [Real.dist_eq]
      calc |s n - s m| = |(s n - s N) - (s m - s N)| := by ring_nf
        _ ≤ |s n - s N| + |s m - s N| := abs_sub _ _
        _ ≤ M * b N + M * b N := add_le_add (hdiff N n hn) (hdiff N m hm)
        _ = 2 * (M * b N) := by ring
    · simpa using (hb_zero.const_mul M).const_mul 2
  obtain ⟨S, hS⟩ := cauchySeq_tendsto_of_complete hcauchy
  refine ⟨S, hS, fun N => ?_⟩
  have hlim : Tendsto (fun m => |s m - s N|) atTop (𝓝 |S - s N|) :=
    (hS.sub_const (s N)).abs
  exact le_of_tendsto hlim (eventually_atTop.mpr ⟨N, fun m hm => hdiff N m hm⟩)

/-- Summation by parts. With `A n = a 0 + ⋯ + a n` the running total of the `a`'s,
the weighted sum of the first `N + 1` terms equals the last running total times the last
weight, plus each running total times the drop in weight that follows it. -/
theorem summation_by_parts (a b : ℕ → ℝ) (N : ℕ) :
    ∑ n ∈ range (N + 1), a n * b n =
      (∑ i ∈ range (N + 1), a i) * b N +
        ∑ n ∈ range N, (∑ i ∈ range (n + 1), a i) * (b n - b (n + 1)) := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [sum_range_succ, ih, sum_range_succ (fun i => a i) (N + 1),
      sum_range_succ (fun n => (∑ i ∈ range (n + 1), a i) * (b n - b (n + 1))) N]
    ring

/-- Abel's test. If the series of `a n` converges, and the weights `b n` only move one way
(never grow, or never fall) and stay bounded, then the series of `a n * b n` converges. -/
theorem abel_test (a b : ℕ → ℝ)
    (ha : ∃ T : ℝ, Tendsto (fun N => ∑ i ∈ range N, a i) atTop (𝓝 T))
    (hb_mono : Monotone b ∨ Antitone b) (hb_bdd : ∃ C : ℝ, ∀ n, |b n| ≤ C) :
    ∃ S : ℝ, Tendsto (fun N => ∑ i ∈ range N, a i * b i) atTop (𝓝 S) := by
  obtain ⟨T, hT⟩ := ha
  obtain ⟨C, hC⟩ := hb_bdd
  obtain ⟨R, -, hR⟩ := cauchySeq_bdd hT.cauchySeq
  have hstretch : ∀ K n, K < n → |∑ i ∈ Ico K n, a i| ≤ R := by
    intro K n hKn
    rw [sum_Ico_eq_sub _ hKn.le, ← Real.dist_eq]
    exact (hR n K).le
  have hup : BddAbove (Set.range b) := ⟨C, by rintro _ ⟨n, rfl⟩; exact (le_abs_self _).trans (hC n)⟩
  have hdown : BddBelow (Set.range b) :=
    ⟨-C, by rintro _ ⟨n, rfl⟩; exact neg_le_of_abs_le (hC n)⟩
  rcases hb_mono with hmono | hanti
  · -- weights rise to `L`; use `L - b n`, which falls to 0
    set L := ⨆ n, b n
    have hL : Tendsto b atTop (𝓝 L) := tendsto_atTop_ciSup hmono hup
    have hc_anti : Antitone (fun n => L - b n) := fun m n hmn => sub_le_sub_left (hmono hmn) L
    have hc_zero : Tendsto (fun n => L - b n) atTop (𝓝 0) := by
      simpa using (tendsto_const_nhds (x := L)).sub hL
    obtain ⟨S₁, hS₁, -⟩ := dirichlet_test_with_tail_bound a (fun n => L - b n) R hstretch hc_anti hc_zero
    refine ⟨T * L - S₁, ?_⟩
    have : (fun N => ∑ i ∈ range N, a i * b i) =
        fun N => (∑ i ∈ range N, a i) * L - ∑ i ∈ range N, a i * (L - b i) := by
      funext N
      rw [sum_mul, ← sum_sub_distrib]
      exact sum_congr rfl fun i _ => by ring
    rw [this]
    exact (hT.mul_const L).sub hS₁
  · -- weights fall to `L`; use `b n - L`, which falls to 0
    set L := ⨅ n, b n
    have hL : Tendsto b atTop (𝓝 L) := tendsto_atTop_ciInf hanti hdown
    have hc_anti : Antitone (fun n => b n - L) := fun m n hmn => sub_le_sub_right (hanti hmn) L
    have hc_zero : Tendsto (fun n => b n - L) atTop (𝓝 0) := by
      simpa using hL.sub_const L
    obtain ⟨S₁, hS₁, -⟩ := dirichlet_test_with_tail_bound a (fun n => b n - L) R hstretch hc_anti hc_zero
    refine ⟨S₁ + T * L, ?_⟩
    have : (fun N => ∑ i ∈ range N, a i * b i) =
        fun N => ∑ i ∈ range N, a i * (b i - L) + (∑ i ∈ range N, a i) * L := by
      funext N
      rw [sum_mul, ← sum_add_distrib]
      exact sum_congr rfl fun i _ => by ring
    rw [this]
    exact hS₁.add (hT.mul_const L)

/- The alternating case of Step 4: with `a n = (-1)^n` (terms counted from 0) the running
totals are 1, 0, 1, 0, 1, 0, so every stretch is at most 1 in size. -/
example : (List.range 6).map (fun n => ∑ k ∈ range (n + 1), (-1 : ℤ) ^ k) = [1, 0, 1, 0, 1, 0] := by
  decide

/- Step 1: the three-term regrouping, with running totals `a₁`, `a₁ + a₂`, `a₁ + a₂ + a₃`. -/
example (a₁ a₂ a₃ b₁ b₂ b₃ : ℝ) :
    a₁ * b₁ + a₂ * b₂ + a₃ * b₃ =
      a₁ * (b₁ - b₂) + (a₁ + a₂) * (b₂ - b₃) + (a₁ + a₂ + a₃) * b₃ := by
  ring

#print axioms dirichlet_test_with_tail_bound
#print axioms summation_by_parts
#print axioms abel_test
