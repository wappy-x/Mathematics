-- Alternating series: a sum whose signs take turns and whose sizes fall steadily to zero settles on a limit that the first term left out bounds, 1 − 1/2 + 1/3 − ⋯ settles on ln 2 but lands on 3/2 · ln 2 when reordered two up and one down, and an absolutely convergent sum keeps its value under every reordering.
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.PSeries
import Mathlib.NumberTheory.Harmonic.EulerMascheroni

open Finset Filter Topology

/-- The alternating series test with its error bound. Take sizes b₀, b₁, b₂, … that never grow
and head for zero, and add them with signs taking turns: b₀ − b₁ + b₂ − ⋯ (the card counts from
b₁; here the count starts at 0, so after N terms the first size left out is b N). Then the
running totals S_N settle on a limit S, and for every N the miss S − S_N is no bigger than the
first size left out, |S − S_N| ≤ b N, and points the way that term points: (−1)^N (S − S_N) ≥ 0. -/
theorem alternating_series_converges_with_error_bound (b : ℕ → ℝ)
    (hb_never_grows : Antitone b) (hb_to_zero : Tendsto b atTop (𝓝 0)) :
    ∃ S : ℝ, Tendsto (fun N => ∑ n ∈ range N, (-1 : ℝ) ^ n * b n) atTop (𝓝 S) ∧
      ∀ N : ℕ, |S - ∑ n ∈ range N, (-1 : ℝ) ^ n * b n| ≤ b N ∧
        0 ≤ (-1 : ℝ) ^ N * (S - ∑ n ∈ range N, (-1 : ℝ) ^ n * b n) := by
  obtain ⟨S, hS⟩ := hb_never_grows.tendsto_alternating_series_of_tendsto_zero hb_to_zero
  refine ⟨S, hS, fun N => ?_⟩
  have upper := hb_never_grows.alternating_series_le_tendsto hS
  have lower := hb_never_grows.tendsto_le_alternating_series hS
  have I (n : ℕ) : 0 ≤ b n := by
    apply le_of_tendsto hb_to_zero
    filter_upwards [Ici_mem_atTop n] with m hm using hb_never_grows hm
  obtain ⟨k, rfl | rfl⟩ := Nat.even_or_odd' N
  · have u := upper k
    have l := lower k
    rw [sum_range_succ] at l
    have hp : (-1 : ℝ) ^ (2 * k) = 1 := by simp
    rw [hp] at l ⊢
    refine ⟨abs_le.mpr ⟨by linarith [I (2 * k)], by linarith⟩, by linarith⟩
  · have u := upper (k + 1)
    have l := lower k
    rw [show 2 * (k + 1) = 2 * k + 1 + 1 by ring, sum_range_succ] at u
    have hp : (-1 : ℝ) ^ (2 * k + 1) = -1 := by simp [pow_succ]
    rw [hp] at u ⊢
    refine ⟨abs_le.mpr ⟨by linarith, by linarith [I (2 * k + 1)]⟩, by linarith⟩

/-- The two-up, one-down order of the card's reordering, as positions in the original series
1 − 1/2 + 1/3 − 1/4 + ⋯ counted from 0 (position n holds (−1)^n/(n + 1)). Triple m takes the
next two positive terms, 1/(4m + 1) and 1/(4m + 3), then the next negative one, −1/(2m + 2). -/
def twoUpOneDown (k : ℕ) : ℕ :=
  if k % 3 = 0 then 4 * (k / 3) else if k % 3 = 1 then 4 * (k / 3) + 2 else 2 * (k / 3) + 1

/-- Real harmonic numbers minus log tend to the Euler–Mascheroni constant, along `c * m`. -/
lemma acc_harmonic_sub_log_mul (c : ℕ) (hc : 0 < c) :
    Tendsto (fun m : ℕ => ∑ i ∈ range (c * m), (1 : ℝ) / (i + 1) - Real.log ((c * m : ℕ) : ℝ))
      atTop (𝓝 Real.eulerMascheroniConstant) := by
  have h := Real.tendsto_harmonic_sub_log
  have hc' : Tendsto (fun m : ℕ => c * m) atTop atTop :=
    tendsto_id.const_mul_atTop' hc
  refine (h.comp hc').congr fun m => ?_
  simp only [Function.comp, harmonic]
  push_cast
  simp [one_div]

#print axioms acc_harmonic_sub_log_mul

lemma acc_alt_even (m : ℕ) :
    ∑ n ∈ range (2 * m), (-1 : ℝ) ^ n / (n + 1) =
      ∑ i ∈ range (2 * m), (1 : ℝ) / (i + 1) - ∑ i ∈ range m, (1 : ℝ) / (i + 1) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [show 2 * (m + 1) = 2 * m + 1 + 1 by ring, sum_range_succ, sum_range_succ, ih,
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) (2 * m + 1),
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) (2 * m), sum_range_succ]
    have h1 : (-1 : ℝ) ^ (2 * m) = 1 := by simp
    have h2 : (-1 : ℝ) ^ (2 * m + 1) = -1 := by simp [pow_succ]
    rw [h1, h2]
    push_cast
    field_simp
    ring

#print axioms acc_alt_even

lemma acc_reord_triple (m : ℕ) :
    ∑ k ∈ range (3 * m), (-1 : ℝ) ^ (twoUpOneDown k) / ((twoUpOneDown k : ℝ) + 1) =
      ∑ i ∈ range (4 * m), (1 : ℝ) / (i + 1)
        - 1 / 2 * ∑ i ∈ range (2 * m), (1 : ℝ) / (i + 1)
        - 1 / 2 * ∑ i ∈ range m, (1 : ℝ) / (i + 1) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [show 3 * (m + 1) = 3 * m + 1 + 1 + 1 by ring, sum_range_succ, sum_range_succ,
      sum_range_succ, ih,
      show 4 * (m + 1) = 4 * m + 1 + 1 + 1 + 1 by ring,
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) (4 * m + 1 + 1 + 1),
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) (4 * m + 1 + 1),
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) (4 * m + 1),
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) (4 * m),
      show 2 * (m + 1) = 2 * m + 1 + 1 by ring,
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) (2 * m + 1),
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) (2 * m),
      sum_range_succ (fun i : ℕ => (1 : ℝ) / (i + 1)) m]
    have e0 : twoUpOneDown (3 * m) = 4 * m := by unfold twoUpOneDown; split_ifs <;> omega
    have e1 : twoUpOneDown (3 * m + 1) = 4 * m + 2 := by unfold twoUpOneDown; split_ifs <;> omega
    have e2 : twoUpOneDown (3 * m + 1 + 1) = 2 * m + 1 := by
      unfold twoUpOneDown; split_ifs <;> omega
    rw [e0, e1, e2]
    have p0 : (-1 : ℝ) ^ (4 * m) = 1 := by rw [pow_mul]; norm_num
    have p1 : (-1 : ℝ) ^ (4 * m + 2) = 1 := by rw [pow_add, pow_mul]; norm_num
    have p2 : (-1 : ℝ) ^ (2 * m + 1) = -1 := by simp [pow_succ]
    rw [p0, p1, p2]
    push_cast
    field_simp
    ring

#print axioms acc_reord_triple

lemma acc_div3_tendsto : Tendsto (fun N : ℕ => N / 3) atTop atTop := by
  rw [tendsto_atTop_atTop]
  exact fun b => ⟨3 * b, fun n hn => by omega⟩

#print axioms acc_div3_tendsto

lemma acc_reord_tail (q r : ℕ) (hr : r < 3) :
    |∑ k ∈ range (3 * q + r), (-1 : ℝ) ^ (twoUpOneDown k) / ((twoUpOneDown k : ℝ) + 1)
      - ∑ k ∈ range (3 * q), (-1 : ℝ) ^ (twoUpOneDown k) / ((twoUpOneDown k : ℝ) + 1)|
      ≤ 2 / ((q : ℝ) + 1) := by
  have e0 : twoUpOneDown (3 * q) = 4 * q := by unfold twoUpOneDown; split_ifs <;> omega
  have e1 : twoUpOneDown (3 * q + 1) = 4 * q + 2 := by unfold twoUpOneDown; split_ifs <;> omega
  have p0 : (-1 : ℝ) ^ (4 * q) = 1 := by rw [pow_mul]; norm_num
  have p1 : (-1 : ℝ) ^ (4 * q + 2) = 1 := by rw [pow_add, pow_mul]; norm_num
  have hq : (0 : ℝ) ≤ q := by positivity
  have b0 : 1 / ((4 * q : ℕ) + 1 : ℝ) ≤ 1 / ((q : ℝ) + 1) := by
    push_cast
    apply one_div_le_one_div_of_le (by positivity); linarith
  have b1 : 1 / ((4 * q + 2 : ℕ) + 1 : ℝ) ≤ 1 / ((q : ℝ) + 1) := by
    push_cast
    apply one_div_le_one_div_of_le (by positivity); linarith
  have c0 : 0 ≤ 1 / ((4 * q : ℕ) + 1 : ℝ) := by positivity
  have c1 : 0 ≤ 1 / ((4 * q + 2 : ℕ) + 1 : ℝ) := by positivity
  have two : 2 / ((q : ℝ) + 1) = 1 / ((q : ℝ) + 1) + 1 / ((q : ℝ) + 1) := by ring
  have pos : 0 ≤ 1 / ((q : ℝ) + 1) := by positivity
  interval_cases r
  · simp; positivity
  · rw [sum_range_succ, e0, p0, add_sub_cancel_left, abs_of_nonneg (by simpa using c0)]
    rw [two]; simp only [one_div] at *; linarith
  · rw [show 3 * q + 2 = 3 * q + 1 + 1 by ring, sum_range_succ, sum_range_succ, e0, e1, p0, p1,
      add_assoc, add_sub_cancel_left]
    simp only [one_div] at *
    rw [abs_of_nonneg (by linarith), two]; linarith

#print axioms acc_reord_tail

/-- Order is part of the answer. The running totals of 1 − 1/2 + 1/3 − 1/4 + ⋯ settle on ln 2;
the sizes 1, 1/2, 1/3, … alone do not add to a finite total, so the convergence is only
conditional; the two-up, one-down order 1 + 1/3 − 1/2 + 1/5 + 1/7 − 1/4 + ⋯ uses every term
exactly once; and in that order the running totals settle on one and a half times ln 2. -/
theorem alternating_harmonic_reordered_changes_sum :
    Tendsto (fun N => ∑ n ∈ range N, (-1 : ℝ) ^ n / (n + 1)) atTop (𝓝 (Real.log 2)) ∧
      ¬ Summable (fun n : ℕ => |(-1 : ℝ) ^ n / (n + 1)|) ∧
      Function.Bijective twoUpOneDown ∧
      Tendsto (fun N => ∑ k ∈ range N,
          (-1 : ℝ) ^ (twoUpOneDown k) / ((twoUpOneDown k : ℝ) + 1))
        atTop (𝓝 (3 / 2 * Real.log 2)) := by
  have H1 := acc_harmonic_sub_log_mul 1 one_pos
  have H2 := acc_harmonic_sub_log_mul 2 two_pos
  have H4 := acc_harmonic_sub_log_mul 4 (by norm_num)
  simp only [one_mul] at H1
  refine ⟨?_, ?_, ?_, ?_⟩
  · -- converges by the alternating series test; the even subsequence identifies the limit
    have hanti : Antitone (fun n : ℕ => (1 : ℝ) / (n + 1)) := by
      intro a b hab
      apply one_div_le_one_div_of_le (by positivity)
      exact_mod_cast Nat.add_le_add_right hab 1
    obtain ⟨l, hl⟩ := hanti.tendsto_alternating_series_of_tendsto_zero
      tendsto_one_div_add_atTop_nhds_zero_nat
    have hl' : Tendsto (fun N => ∑ n ∈ range N, (-1 : ℝ) ^ n / (n + 1)) atTop (𝓝 l) := by
      refine hl.congr fun N => sum_congr rfl fun n _ => ?_
      ring
    have heven : Tendsto (fun m : ℕ => ∑ n ∈ range (2 * m), (-1 : ℝ) ^ n / (n + 1)) atTop
        (𝓝 (Real.log 2)) := by
      have := (H2.sub H1).add_const (Real.log 2)
      rw [sub_self, zero_add] at this
      refine this.congr' ?_
      filter_upwards [eventually_ge_atTop 1] with m hm
      rw [acc_alt_even]
      have hm' : (m : ℝ) ≠ 0 := by positivity
      push_cast
      rw [Real.log_mul two_ne_zero hm']
      ring
    have hsub : Tendsto (fun m : ℕ => ∑ n ∈ range (2 * m), (-1 : ℝ) ^ n / (n + 1)) atTop (𝓝 l) :=
      hl'.comp (tendsto_id.const_mul_atTop' two_pos)
    rw [tendsto_nhds_unique hsub heven] at hl'
    exact hl'
  · have : (fun n : ℕ => |(-1 : ℝ) ^ n / (n + 1)|) = fun n : ℕ => 1 / ((n + 1 : ℕ) : ℝ) := by
      funext n
      rw [abs_div, abs_pow, abs_neg, abs_one, one_pow]
      push_cast
      rw [abs_of_pos (by positivity)]
    rw [this]
    exact mt (summable_nat_add_iff (f := fun n : ℕ ↦ 1 / (n : ℝ)) 1).mp
      Real.not_summable_one_div_natCast
  · constructor
    · intro a b h
      unfold twoUpOneDown at h
      split_ifs at h <;> omega
    · intro n
      by_cases h0 : n % 4 = 0
      · exact ⟨3 * (n / 4), by unfold twoUpOneDown; split_ifs <;> omega⟩
      by_cases h2 : n % 4 = 2
      · exact ⟨3 * (n / 4) + 1, by unfold twoUpOneDown; split_ifs <;> omega⟩
      · exact ⟨3 * (n / 2) + 2, by unfold twoUpOneDown; split_ifs <;> omega⟩
  · set T : ℕ → ℝ := fun N => ∑ k ∈ range N,
        (-1 : ℝ) ^ (twoUpOneDown k) / ((twoUpOneDown k : ℝ) + 1) with hT
    have h3 : Tendsto (fun m : ℕ => T (3 * m)) atTop (𝓝 (3 / 2 * Real.log 2)) := by
      have := ((H4.sub (H2.const_mul (1 / 2))).sub (H1.const_mul (1 / 2))).add_const
        (3 / 2 * Real.log 2)
      rw [show Real.eulerMascheroniConstant - 1 / 2 * Real.eulerMascheroniConstant
        - 1 / 2 * Real.eulerMascheroniConstant + 3 / 2 * Real.log 2 = 3 / 2 * Real.log 2 by
          ring] at this
      refine this.congr' ?_
      filter_upwards [eventually_ge_atTop 1] with m hm
      simp only [hT]
      rw [acc_reord_triple]
      have hm' : (m : ℝ) ≠ 0 := by positivity
      push_cast
      rw [Real.log_mul (by norm_num : (4 : ℝ) ≠ 0) hm', Real.log_mul two_ne_zero hm',
        show (4 : ℝ) = 2 ^ 2 by norm_num, Real.log_pow]
      push_cast
      ring
    have hmain : Tendsto (fun N : ℕ => T (3 * (N / 3))) atTop (𝓝 (3 / 2 * Real.log 2)) :=
      h3.comp acc_div3_tendsto
    have hzero : Tendsto (fun N : ℕ => 2 / (((N / 3 : ℕ) : ℝ) + 1)) atTop (𝓝 0) := by
      have := (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).const_mul 2
      rw [mul_zero] at this
      refine (this.comp acc_div3_tendsto).congr fun N => ?_
      simp [Function.comp, div_eq_mul_inv]
    have herr : Tendsto (fun N : ℕ => T N - T (3 * (N / 3))) atTop (𝓝 0) := by
      refine squeeze_zero_norm (fun N => ?_) hzero
      have := acc_reord_tail (N / 3) (N % 3) (Nat.mod_lt _ (by norm_num))
      rw [Nat.div_add_mod] at this
      simpa [Real.norm_eq_abs] using this
    have := hmain.add herr
    rw [add_zero] at this
    exact this.congr fun N => by ring

/-- Absolute convergence is the stronger kind, and reordering cannot move it. If the sizes
|a₀|, |a₁|, … add to a finite total, then the running totals of a₀ + a₁ + ⋯ settle on some S,
and the running totals of every reordering of the same terms, each used once, settle on that
same S. -/
theorem absolutely_convergent_series_reorder_keeps_sum (a : ℕ → ℝ)
    (h_abs : Summable (fun n => |a n|)) :
    ∃ S : ℝ, Tendsto (fun N => ∑ n ∈ range N, a n) atTop (𝓝 S) ∧
      ∀ σ : ℕ ≃ ℕ, Tendsto (fun N => ∑ k ∈ range N, a (σ k)) atTop (𝓝 S) := by
  have hs : Summable a := summable_abs_iff.mp h_abs
  refine ⟨∑' n, a n, hs.hasSum.tendsto_sum_nat, fun σ => ?_⟩
  have : HasSum (a ∘ σ) (∑' n, a n) := (Equiv.hasSum_iff σ).mpr hs.hasSum
  exact this.tendsto_sum_nat

/-! The card's exact worked numbers. -/

-- Ten terms: 1 − 1/2 + ⋯ − 1/10 = 1627/2520 (the card's 0.645634921).
example : ∑ n ∈ range 10, (-1 : ℚ) ^ n / (n + 1) = 1627 / 2520 := by
  norm_num [Finset.sum_range_succ]

-- The bound certifies 0.001 first at N = 999: 1/(N + 1) ≤ 1/1000 there, and not at N = 998.
example : (1 : ℚ) / (999 + 1) ≤ 1 / 1000 ∧ ¬ ((1 : ℚ) / (998 + 1) ≤ 1 / 1000) := by
  norm_num

-- Sizes never head for zero: 1 − 1 + 1 − ⋯ has totals 1, 0, 1, 0, 1, 0.
example : (List.range 6).map (fun N => ∑ i ∈ range (N + 1), (-1 : ℤ) ^ i) = [1, 0, 1, 0, 1, 0] := by
  decide

-- Sizes shrink but not steadily: 8 pairs of 1/k − 1/(2k) total 761/560 (the card's 1.358929),
-- which is half of 1 + 1/2 + ⋯ + 1/8.
example : ∑ k ∈ range 8, ((1 : ℚ) / (k + 1) - 1 / (2 * (k + 1))) = 761 / 560 ∧
    ∑ k ∈ range 8, (1 : ℚ) / (k + 1) = 2 * (761 / 560) := by
  norm_num [Finset.sum_range_succ]

-- Step 5 at m = 2: T₆ − S₈ = ½ S₄ (two-up, one-down after 2 triples, against 8 terms in order).
example : ∑ k ∈ range 6, (-1 : ℚ) ^ (twoUpOneDown k) / ((twoUpOneDown k : ℚ) + 1)
      - ∑ n ∈ range 8, (-1 : ℚ) ^ n / (n + 1)
      = 1 / 2 * ∑ n ∈ range 4, (-1 : ℚ) ^ n / (n + 1) := by
  norm_num [Finset.sum_range_succ, twoUpOneDown]

#print axioms alternating_series_converges_with_error_bound
#print axioms alternating_harmonic_reordered_changes_sum
#print axioms absolutely_convergent_series_reorder_keeps_sum
