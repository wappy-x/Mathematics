-- Branching processes: the chance of being dead by generation n climbs to the smallest fixed point of the offspring generating function, a fixed point below 1 exists exactly when the mean number of children is above 1, and with at most two children that point is min(1, p0/p2).
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Topology.Order.MonotoneConvergence
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination
import Mathlib.Analysis.Normed.Group.FunctionSeries
import Mathlib.Topology.Order.IntermediateValue

open Filter Topology

lemma gw_summable (p : ℕ → ℝ) (hp : ∀ k, 0 ≤ p k) (hs : Summable p) {s : ℝ} (h0 : 0 ≤ s)
    (h1 : s ≤ 1) : Summable (fun k : ℕ => p k * s ^ k) :=
  Summable.of_nonneg_of_le (fun k => mul_nonneg (hp k) (pow_nonneg h0 k))
    (fun k => mul_le_of_le_one_right (hp k) (pow_le_one₀ h0 h1)) hs

lemma gw_mono (p : ℕ → ℝ) (hp : ∀ k, 0 ≤ p k) (hs : Summable p) {s t : ℝ} (h0 : 0 ≤ s)
    (hst : s ≤ t) (ht : t ≤ 1) : ∑' k : ℕ, p k * s ^ k ≤ ∑' k : ℕ, p k * t ^ k :=
  (gw_summable p hp hs h0 (hst.trans ht)).tsum_le_tsum
    (fun k => mul_le_mul_of_nonneg_left (pow_le_pow_left₀ h0 hst k) (hp k))
    (gw_summable p hp hs (h0.trans hst) ht)

lemma gw_cont (p : ℕ → ℝ) (hp : ∀ k, 0 ≤ p k) (hs : Summable p) :
    ContinuousOn (fun s : ℝ => ∑' k : ℕ, p k * s ^ k) (Set.Icc 0 1) :=
  continuousOn_tsum (fun k => (continuous_const.mul (continuous_pow k)).continuousOn) hs
    (fun k s hs' => by
      rw [Real.norm_eq_abs, abs_of_nonneg (mul_nonneg (hp k) (pow_nonneg hs'.1 k))]
      exact mul_le_of_le_one_right (hp k) (pow_le_one₀ hs'.1 hs'.2))

lemma gw_one (p : ℕ → ℝ) (hsum : HasSum p 1) : ∑' k : ℕ, p k * (1 : ℝ) ^ k = 1 := by
  simp [hsum.tsum_eq]

lemma gw_zero (p : ℕ → ℝ) : ∑' k : ℕ, p k * (0 : ℝ) ^ k = p 0 := by
  rw [tsum_eq_single 0]
  · simp
  · intro k hk; simp [hk]

lemma gw_one_sub_pow_le {s : ℝ} (h0 : 0 ≤ s) (h1 : s ≤ 1) (k : ℕ) :
    1 - s ^ k ≤ (k : ℝ) * (1 - s) := by
  induction k with
  | zero => simp
  | succ n ih =>
    have := pow_le_one₀ h0 h1 (n := n)
    push_cast
    rw [pow_succ]
    nlinarith

lemma gw_one_sub_pow_lt {s : ℝ} (h0 : 0 ≤ s) (h1 : s < 1) (n : ℕ) :
    1 - s ^ (n + 2) < ((n + 2 : ℕ) : ℝ) * (1 - s) := by
  have h := gw_one_sub_pow_le h0 h1.le (n + 1)
  have hlt : s ^ (n + 1) < 1 := pow_lt_one₀ h0 h1 (by omega)
  have h1s : 0 < 1 - s := by linarith
  have : s ^ (n + 2) = s ^ (n + 1) * s := pow_succ s (n + 1)
  push_cast at h ⊢
  nlinarith

lemma gw_le_one_sub_pow {s : ℝ} (h0 : 0 ≤ s) (h1 : s ≤ 1) (k : ℕ) :
    (k : ℝ) * s ^ k * (1 - s) ≤ 1 - s ^ k := by
  induction k with
  | zero => simp
  | succ n ih =>
    have hle : s ^ (n + 1) ≤ s ^ n := pow_le_pow_of_le_one h0 h1 (by omega)
    have hpos : 0 ≤ s ^ (n + 1) := pow_nonneg h0 _
    have h1s : 0 ≤ 1 - s := by linarith
    have e : s ^ (n + 1) = s ^ n * s := pow_succ s n
    have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    push_cast
    nlinarith [mul_le_mul_of_nonneg_left hle (mul_nonneg hn h1s)]

/-- Extinction is the smallest fixed point. Let `p k` be the chance that one person has
exactly `k` children (`p k ≥ 0`, the chances add up to 1), and let
`f s = ∑ p k s^k` be the offspring generating function. The chance of being dead by
generation `n` is `q_n = f(f(…f(0)))`, `f` applied `n` times to 0. These chances climb to a
limit `q`, and `q` is the smallest `s` in `[0, 1]` with `f s = s`. -/
theorem extinction_prob_eq_smallest_fixed_point
    (p : ℕ → ℝ) (hp : ∀ k, 0 ≤ p k) (hsum : HasSum p 1) :
    ∃ q : ℝ,
      IsLeast {s : ℝ | s ∈ Set.Icc (0 : ℝ) 1 ∧ ∑' k : ℕ, p k * s ^ k = s} q ∧
      Tendsto (fun n : ℕ => (fun s : ℝ => ∑' k : ℕ, p k * s ^ k)^[n] 0) atTop (𝓝 q) := by
  have hs := hsum.summable
  set f := fun s : ℝ => ∑' k : ℕ, p k * s ^ k with hf
  have hf0 : 0 ≤ f 0 := by
    show 0 ≤ ∑' k : ℕ, p k * (0 : ℝ) ^ k
    rw [gw_zero]; exact hp 0
  have hfm : ∀ x y : ℝ, 0 ≤ x → x ≤ y → y ≤ 1 → f x ≤ f y :=
    fun x y hx hxy hy => gw_mono p hp hs hx hxy hy
  have hf1 : f 1 = 1 := gw_one p hsum
  have hI : ∀ n : ℕ, f^[n] 0 ∈ Set.Icc (0 : ℝ) 1 := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Function.iterate_succ_apply']
      exact ⟨hf0.trans (hfm 0 _ le_rfl ih.1 ih.2), (hfm _ 1 ih.1 ih.2 le_rfl).trans hf1.le⟩
  have hmono : Monotone (fun n : ℕ => f^[n] 0) := by
    refine monotone_nat_of_le_succ ?_
    intro n
    induction n with
    | zero => simpa using hf0
    | succ n ih =>
      rw [Function.iterate_succ_apply', Function.iterate_succ_apply' f (n + 1)]
      exact hfm _ _ (hI n).1 (by simpa [Function.iterate_succ_apply'] using ih) (hI (n + 1)).2
  have hbdd : BddAbove (Set.range (fun n : ℕ => f^[n] 0)) :=
    ⟨1, by rintro _ ⟨n, rfl⟩; exact (hI n).2⟩
  have hT := tendsto_atTop_ciSup hmono hbdd
  set q := ⨆ n : ℕ, f^[n] 0 with hq
  have hq0 : 0 ≤ q := by
    have := le_ciSup hbdd 0
    simpa using this
  have hq1 : q ≤ 1 := ciSup_le fun n => (hI n).2
  have hqI : q ∈ Set.Icc (0 : ℝ) 1 := ⟨hq0, hq1⟩
  have hbelow : ∀ s ∈ Set.Icc (0 : ℝ) 1, f s = s → ∀ n, f^[n] 0 ≤ s := by
    intro s hsI hfs n
    induction n with
    | zero => simpa using hsI.1
    | succ n ih =>
      rw [Function.iterate_succ_apply', ← hfs]
      exact hfm _ _ (hI n).1 ih hsI.2
  have hfix : f q = q := by
    have h1 : Tendsto (fun n : ℕ => f (f^[n] 0)) atTop (𝓝 (f q)) :=
      ((gw_cont p hp hs) q hqI).tendsto.comp
        (tendsto_nhdsWithin_iff.2 ⟨hT, Eventually.of_forall hI⟩)
    have h2 : Tendsto (fun n : ℕ => f (f^[n] 0)) atTop (𝓝 q) := by
      have := hT.comp (tendsto_add_atTop_nat 1)
      refine this.congr ?_
      intro n
      simp [Function.iterate_succ_apply']
    exact tendsto_nhds_unique h1 h2
  refine ⟨q, ⟨⟨hqI, hfix⟩, ?_⟩, hT⟩
  rintro s ⟨hsI, hfs⟩
  exact ciSup_le (hbelow s hsI hfs)

/-- The threshold at an average of one child. With `p 1 < 1` (something must vary) and a
finite mean `m = ∑ k p k`, the offspring generating function has a fixed point in `[0, 1)`,
so the family survives with positive chance, exactly when `m > 1`. When `m ≤ 1` the only
fixed point in `[0, 1]` is 1 and the family dies out for certain. -/
theorem exists_fixed_point_lt_one_iff_one_lt_mean
    (p : ℕ → ℝ) (hp : ∀ k, 0 ≤ p k) (hsum : HasSum p 1) (hp1 : p 1 < 1)
    (hm : Summable (fun k : ℕ => (k : ℝ) * p k)) :
    (∃ s ∈ Set.Ico (0 : ℝ) 1, ∑' k : ℕ, p k * s ^ k = s) ↔ 1 < ∑' k : ℕ, (k : ℝ) * p k := by
  have hs := hsum.summable
  have hdiff : ∀ s : ℝ, 0 ≤ s → s ≤ 1 →
      HasSum (fun k : ℕ => p k * (1 - s ^ k)) (1 - ∑' k : ℕ, p k * s ^ k) := by
    intro s h0 h1
    have := hsum.sub (gw_summable p hp hs h0 h1).hasSum
    convert this using 1
    funext k; ring
  constructor
  · rintro ⟨s, ⟨hs0, hs1⟩, hfs⟩
    have h1s : 0 < 1 - s := by linarith
    by_cases hk : ∃ k, 2 ≤ k ∧ 0 < p k
    · obtain ⟨k, hk2, hpk⟩ := hk
      have hA : HasSum (fun j : ℕ => p j * (1 - s ^ j)) (1 - s) := by
        have := hdiff s hs0 hs1.le
        rwa [hfs] at this
      have hB := hm.hasSum.mul_right (1 - s)
      have hle : (fun j : ℕ => p j * (1 - s ^ j)) ≤ fun j : ℕ => (j : ℝ) * p j * (1 - s) := by
        intro j
        have := mul_le_mul_of_nonneg_left (gw_one_sub_pow_le hs0 hs1.le j) (hp j)
        simp only
        nlinarith
      have hlt : p k * (1 - s ^ k) < (k : ℝ) * p k * (1 - s) := by
        obtain ⟨n, rfl⟩ : ∃ n, k = n + 2 := ⟨k - 2, by omega⟩
        have := mul_lt_mul_of_pos_left (gw_one_sub_pow_lt hs0 hs1 n) hpk
        nlinarith
      have := hasSum_lt hle hlt hA hB
      by_contra hc
      push Not at hc
      nlinarith
    · push Not at hk
      have hz : ∀ k ∉ Finset.range 2, p k = 0 := by
        intro k hk'
        simp only [Finset.mem_range, not_lt] at hk'
        exact le_antisymm (hk k hk') (hp k)
      have e1 : (1 : ℝ) = p 0 + p 1 := by
        rw [← hsum.tsum_eq, tsum_eq_sum hz]
        simp [Finset.sum_range_succ]
      have e2 : ∑' k : ℕ, p k * s ^ k = p 0 + p 1 * s := by
        rw [tsum_eq_sum (s := Finset.range 2)]
        · simp [Finset.sum_range_succ]
        · intro k hk'; simp [hz k hk']
      rw [e2] at hfs
      nlinarith
  · intro hm1
    set m := ∑' k : ℕ, (k : ℝ) * p k with hmdef
    have hT := hm.hasSum.tendsto_sum_nat
    obtain ⟨N, hN⟩ := (hT.eventually (lt_mem_nhds hm1)).exists
    set A := ∑ i ∈ Finset.range N, (i : ℝ) * p i with hAdef
    have hc : Tendsto (fun s : ℝ => s ^ N * A) (𝓝[<] 1) (𝓝 (1 ^ N * A)) :=
      ((continuous_pow N).mul continuous_const).continuousAt.tendsto.mono_left
        nhdsWithin_le_nhds
    rw [one_pow, one_mul] at hc
    obtain ⟨s, hsA, hsI⟩ :=
      ((hc.eventually (lt_mem_nhds hN)).and (Ioo_mem_nhdsLT (show (0 : ℝ) < 1 by norm_num))).exists
    have hs0 : 0 ≤ s := hsI.1.le
    have hs1 : s < 1 := hsI.2
    have h1s : 0 < 1 - s := by linarith
    -- 1 - f s > 1 - s
    have hlow : s ^ N * A * (1 - s) ≤ 1 - ∑' k : ℕ, p k * s ^ k := by
      rw [← (hdiff s hs0 hs1.le).tsum_eq]
      have hsum2 : Summable (fun k : ℕ => p k * (1 - s ^ k)) := (hdiff s hs0 hs1.le).summable
      have hnn : ∀ k, 0 ≤ p k * (1 - s ^ k) := fun k =>
        mul_nonneg (hp k) (by linarith [pow_le_one₀ hs0 hs1.le (n := k)])
      refine le_trans ?_ (hsum2.sum_le_tsum (Finset.range N) (fun k _ => hnn k))
      rw [hAdef, Finset.mul_sum, Finset.sum_mul]
      refine Finset.sum_le_sum ?_
      intro k hk
      simp only [Finset.mem_range] at hk
      have h1 := gw_le_one_sub_pow hs0 hs1.le k
      have h2 : s ^ N ≤ s ^ k := pow_le_pow_of_le_one hs0 hs1.le hk.le
      have hk0 : (0 : ℝ) ≤ k := Nat.cast_nonneg k
      have h3 := mul_le_mul_of_nonneg_left h1 (hp k)
      have h4 : s ^ N * ((k : ℝ) * p k) * (1 - s) ≤ (k : ℝ) * s ^ k * (1 - s) * p k := by
        have := mul_le_mul_of_nonneg_right h2 (mul_nonneg (mul_nonneg hk0 (hp k)) h1s.le)
        nlinarith
      nlinarith
    have hlt : ∑' k : ℕ, p k * s ^ k < s := by nlinarith
    -- intermediate value theorem on [0, s]
    have hcont : ContinuousOn (fun t : ℝ => ∑' k : ℕ, p k * t ^ k - t) (Set.Icc 0 s) :=
      ((gw_cont p hp hs).mono (Set.Icc_subset_Icc le_rfl hs1.le)).sub continuousOn_id
    have hmem : (0 : ℝ) ∈ Set.Icc (∑' k : ℕ, p k * s ^ k - s) (∑' k : ℕ, p k * (0 : ℝ) ^ k - 0) := by
      rw [gw_zero]
      exact ⟨by linarith, by linarith [hp 0]⟩
    obtain ⟨t, ⟨ht0, hts⟩, hteq⟩ := intermediate_value_Icc' hs0 hcont hmem
    exact ⟨t, ⟨ht0, by linarith⟩, by simp only at hteq; linarith⟩

/-- The shortcut for at most two children: with chances `p0, p1, p2` of 0, 1, 2 children
(`p2 > 0`), `f s = s` factors as `(s - 1)(p2 s - p0) = 0`, so the smallest fixed point in
`[0, 1]`, the extinction chance, is `min 1 (p0 / p2)`. -/
theorem smallest_fixed_point_two_children
    (p0 p1 p2 : ℝ) (h0 : 0 ≤ p0) (h1 : 0 ≤ p1) (h2 : 0 < p2) (hs : p0 + p1 + p2 = 1) :
    IsLeast {s : ℝ | s ∈ Set.Icc (0 : ℝ) 1 ∧ p0 + p1 * s + p2 * s ^ 2 = s} (min 1 (p0 / p2)) := by
  have hp1 : p1 = 1 - p0 - p2 := by linarith
  have key : ∀ s : ℝ, p0 + p1 * s + p2 * s ^ 2 - s = (1 - s) * (p0 - p2 * s) := by
    intro s; rw [hp1]; ring
  have hq0 : 0 ≤ p0 / p2 := div_nonneg h0 h2.le
  refine ⟨⟨⟨le_min zero_le_one hq0, min_le_left _ _⟩, ?_⟩, ?_⟩
  · rcases min_choice 1 (p0 / p2) with h | h <;> rw [h]
    · linear_combination hs
    · have hx : p2 * (p0 / p2) = p0 := mul_div_cancel₀ p0 h2.ne'
      linear_combination key (p0 / p2) - (1 - p0 / p2) * hx
  · rintro s ⟨⟨hs0, hs1⟩, hfs⟩
    have := key s
    have hz : (1 - s) * (p0 - p2 * s) = 0 := by linarith
    rcases mul_eq_zero.1 hz with h | h
    · exact (min_le_left _ _).trans (by linarith)
    · refine (min_le_right _ _).trans ?_
      rw [div_le_iff₀ h2]; linarith

-- Our family: chances 1/4, 1/4, 1/2 of 0, 1, 2 children; mean m = 5/4 and variance 11/16.
example : (0 : ℚ) * (1/4) + 1 * (1/4) + 2 * (1/2) = 5/4 := by norm_num
example : ((0 : ℚ) * (1/4) + 1 * (1/4) + 4 * (1/2)) - (5/4) ^ 2 = 11/16 := by norm_num

-- f(s) = s times 4 is 2s^2 - 3s + 1 = (2s - 1)(s - 1): the fixed points 1/2 and 1.
example : ∀ s : ℚ, 4 * ((1/4) + (1/4) * s + (1/2) * s ^ 2 - s) = (2 * s - 1) * (s - 1) := by
  intro s; ring
example : (1/4 : ℚ) + (1/4) * (1/2) + (1/2) * (1/2) ^ 2 = 1/2 := by norm_num
example : (1/4 : ℚ) + (1/4) * 1 + (1/2) * 1 ^ 2 = 1 := by norm_num

-- Dead by generation 1, 2, 3: f(0) = 1/4, f(1/4) = 11/32, f(11/32) = 809/2048.
example : (1/4 : ℚ) + (1/4) * 0 + (1/2) * 0 ^ 2 = 1/4 := by norm_num
example : (1/4 : ℚ) + (1/4) * (1/4) + (1/2) * (1/4) ^ 2 = 11/32 := by norm_num
example : (1/4 : ℚ) + (1/4) * (11/32) + (1/2) * (11/32) ^ 2 = 809/2048 := by norm_num

-- The shortcut: q = min(1, p0/p2) = (1/4)/(1/2) = 1/2; three founders all die with chance 1/8.
example : min (1 : ℚ) ((1/4) / (1/2)) = 1/2 := by norm_num
example : (1/2 : ℚ) ^ 3 = 1/8 := by norm_num

-- Other laws: 1/8, 3/8, 1/2 gives q = 1/4; 1/2, 1/4, 1/4 gives q = 1; 3/8, 0, 5/8 gives 3/5.
example : min (1 : ℚ) ((1/8) / (1/2)) = 1/4 := by norm_num
example : min (1 : ℚ) ((1/2) / (1/4)) = 1 := by norm_num
example : min (1 : ℚ) ((3/8) / (5/8)) = 3/5 := by norm_num

-- Spread of the limit: Var(W) = sigma^2 / (m (m - 1)) = (11/16) / ((5/4)(1/4)) = 11/5 = 2.2,
-- and a surviving family's size factor averages E[W] / P(survives) = 1 / (1/2) = 2.
example : (11/16 : ℚ) / ((5/4) * (5/4 - 1)) = 11/5 := by norm_num
example : (1 : ℚ) / (1 - 1/2) = 2 := by norm_num

#print axioms extinction_prob_eq_smallest_fixed_point
#print axioms exists_fixed_point_lt_one_iff_one_lt_mean
#print axioms smallest_fixed_point_two_children
#print axioms gw_summable
#print axioms gw_mono
#print axioms gw_cont
#print axioms gw_one
#print axioms gw_zero
#print axioms gw_one_sub_pow_le
#print axioms gw_one_sub_pow_lt
#print axioms gw_le_one_sub_pow
