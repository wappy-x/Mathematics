-- Uniform convergence: a uniform limit of continuous functions is continuous, number caps with a finite sum make a series converge uniformly with the caps' leftover bounding the error, and x^n settles on [0, 1] input by input but uniformly only on a cut interval such as [0, 9/10].
import Mathlib.Topology.UniformSpace.UniformApproximation
import Mathlib.Analysis.Normed.Group.FunctionSeries
import Mathlib.Analysis.SpecificLimits.Normed

open Finset Filter Topology

/-- Theorem 1: continuity survives a uniform limit. Let every stage f n be continuous on a set
D of real numbers, and let f n head for f uniformly on D: for every tolerance there is one stage
after which every gap |f n x − f x| with x in D is within it (the worst gap E_n heads for 0).
Then the limit f is continuous on D. -/
theorem uniform_limit_of_continuous_functions_is_continuous {D : Set ℝ}
    (f : ℕ → ℝ → ℝ) (g : ℝ → ℝ)
    (h_cont : ∀ n, ContinuousOn (f n) D)
    (h_unif : TendstoUniformlyOn f g atTop D) :
    ContinuousOn g D := by
  exact h_unif.continuousOn (Filter.Eventually.frequently (Filter.Eventually.of_forall h_cont))

/-- Theorem 2, the Weierstrass M-test. Let the terms g k of a series obey |g k x| ≤ M k for every
x in D, with caps M k that are plain numbers with a finite sum. Then the partial sums
S_N x = g 0 x + ⋯ + g (N − 1) x converge uniformly on D to the sum S x = ∑ g k x, and at every
x in D the leftover |S x − S_N x| is at most the caps' leftover M N + M (N + 1) + ⋯.
(The card counts terms from 1; here the count starts at 0, so S_N holds the first N terms.) -/
theorem weierstrass_m_test_uniform_with_tail_bound {D : Set ℝ}
    (g : ℕ → ℝ → ℝ) (M : ℕ → ℝ)
    (h_cap : ∀ k, ∀ x ∈ D, |g k x| ≤ M k)
    (h_sum : Summable M) :
    TendstoUniformlyOn (fun N x => ∑ k ∈ range N, g k x) (fun x => ∑' k, g k x) atTop D ∧
      ∀ N : ℕ, ∀ x ∈ D, |(∑' k, g k x) - ∑ k ∈ range N, g k x| ≤ ∑' k, M (k + N) := by
  have hg : ∀ x ∈ D, ∀ k, ‖g k x‖ ≤ M k := fun x hx k => by
    rw [Real.norm_eq_abs]; exact h_cap k x hx
  refine ⟨tendstoUniformlyOn_tsum_nat h_sum (fun k x hx => hg x hx k), ?_⟩
  intro N x hx
  have hsx : Summable (fun k => g k x) := Summable.of_norm_bounded h_sum (hg x hx)
  have hMN : Summable (fun k => M (k + N)) := (summable_nat_add_iff N).2 h_sum
  have hgN : Summable (fun k => ‖g (k + N) x‖) :=
    Summable.of_nonneg_of_le (fun k => norm_nonneg _) (fun k => hg x hx (k + N)) hMN
  rw [← hsx.sum_add_tsum_nat_add N, add_sub_cancel_left, ← Real.norm_eq_abs]
  calc ‖∑' k, g (k + N) x‖ ≤ ∑' k, ‖g (k + N) x‖ := norm_tsum_le_tsum_norm hgN
    _ ≤ ∑' k, M (k + N) := hgN.tsum_le_tsum (fun k => hg x hx (k + N)) hMN

/-- The card's example x^n. On [0, 1] every input settles: x^n heads for 0 when x is below 1
and for 1 at x = 1. The convergence is not uniform on [0, 1]: for every stage n ≥ 1 the worst
gap E_n (the least upper bound of |x^n − f x| over [0, 1]) is 1, yet no input reaches a gap of 1.
On the cut interval [0, 9/10] the convergence to 0 is uniform. -/
theorem pow_converges_pointwise_not_uniformly_on_unit_interval :
    let f : ℝ → ℝ := fun x => if x = 1 then 1 else 0
    (∀ x ∈ Set.Icc (0 : ℝ) 1, Tendsto (fun n : ℕ => x ^ n) atTop (𝓝 (f x))) ∧
      ¬ TendstoUniformlyOn (fun (n : ℕ) (x : ℝ) => x ^ n) f atTop (Set.Icc 0 1) ∧
      (∀ n : ℕ, 1 ≤ n →
        sSup ((fun x => |x ^ n - f x|) '' Set.Icc (0 : ℝ) 1) = 1 ∧
          ∀ x ∈ Set.Icc (0 : ℝ) 1, |x ^ n - f x| < 1) ∧
      TendstoUniformlyOn (fun (n : ℕ) (x : ℝ) => x ^ n) (fun _ => 0) atTop
        (Set.Icc 0 (9 / 10)) := by
  intro f
  -- every gap is below 1, for n ≥ 1
  have hlt : ∀ n : ℕ, 1 ≤ n → ∀ x ∈ Set.Icc (0 : ℝ) 1, |x ^ n - f x| < 1 := by
    intro n hn x hx
    by_cases h1 : x = 1
    · simp [f, h1]
    · have hx1 : x < 1 := lt_of_le_of_ne hx.2 h1
      have h0 : 0 ≤ x ^ n := pow_nonneg hx.1 n
      simp only [f, h1, ite_false, sub_zero, abs_of_nonneg h0]
      exact pow_lt_one₀ hx.1 hx1 (by omega)
  have hsup : ∀ n : ℕ, 1 ≤ n → sSup ((fun x => |x ^ n - f x|) '' Set.Icc (0 : ℝ) 1) = 1 := by
    intro n hn
    apply csSup_eq_of_forall_le_of_forall_lt_exists_gt
    · exact ⟨_, Set.mem_image_of_mem _ (Set.left_mem_Icc.2 zero_le_one)⟩
    · rintro a ⟨x, hx, rfl⟩
      exact (hlt n hn x hx).le
    · intro w hw
      have h1 : Tendsto (fun x : ℝ => x ^ n) (𝓝[<] 1) (𝓝 1) := by
        have := ((continuous_pow n).tendsto (1 : ℝ)).mono_left
          (nhdsWithin_le_nhds (s := Set.Iio (1 : ℝ)))
        simpa using this
      have h2 : ∀ᶠ x in 𝓝[<] (1 : ℝ), w < x ^ n := h1.eventually (lt_mem_nhds hw)
      have h3 : ∀ᶠ x in 𝓝[<] (1 : ℝ), x ∈ Set.Ioo 0 1 := Ioo_mem_nhdsLT (by norm_num)
      obtain ⟨x, hxw, hx⟩ := (h2.and h3).exists
      refine ⟨_, ⟨x, ⟨hx.1.le, hx.2.le⟩, rfl⟩, ?_⟩
      have hne : x ≠ 1 := hx.2.ne
      have h0 : 0 ≤ x ^ n := pow_nonneg hx.1.le n
      simp only [f, hne, ite_false, sub_zero, abs_of_nonneg h0]
      exact hxw
  refine ⟨?_, ?_, fun n hn => ⟨hsup n hn, hlt n hn⟩, ?_⟩
  · intro x hx
    by_cases h1 : x = 1
    · simp only [f, h1, ite_true, one_pow]; exact tendsto_const_nhds
    · simp only [f, h1, ite_false]
      exact tendsto_pow_atTop_nhds_zero_of_lt_one hx.1 (lt_of_le_of_ne hx.2 h1)
  · intro hU
    rw [Metric.tendstoUniformlyOn_iff] at hU
    obtain ⟨n, hn⟩ := ((hU (1 / 2) (by norm_num)).and (eventually_ge_atTop 1)).exists
    have hle : sSup ((fun x => |x ^ n - f x|) '' Set.Icc (0 : ℝ) 1) ≤ 1 / 2 := by
      apply csSup_le
      · exact ⟨_, Set.mem_image_of_mem _ (Set.left_mem_Icc.2 zero_le_one)⟩
      · rintro a ⟨x, hx, rfl⟩
        have := hn.1 x hx
        rw [Real.dist_eq, abs_sub_comm] at this
        exact this.le
    rw [hsup n hn.2] at hle
    norm_num at hle
  · rw [Metric.tendstoUniformlyOn_iff]
    intro ε hε
    have ht : Tendsto (fun n : ℕ => (9 / 10 : ℝ) ^ n) atTop (𝓝 0) :=
      tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num) (by norm_num)
    filter_upwards [ht.eventually (gt_mem_nhds hε)] with n hn x hx
    rw [Real.dist_eq, zero_sub, abs_neg, abs_of_nonneg (pow_nonneg hx.1 n)]
    exact lt_of_le_of_lt (pow_le_pow_left₀ hx.1 hx.2 n) hn

/-! The card's exact worked numbers. -/

-- Cutoffs for the tolerance 1/1000: the first stage n with x^n below it is 10 at x = 1/2,
-- 66 at x = 9/10, 688 at x = 99/100, and 6905 at x = 999/1000.
example : (1 / 2 : ℚ) ^ 10 < 1 / 1000 ∧ ¬ ((1 / 2 : ℚ) ^ 9 < 1 / 1000) := by norm_num
example : (9 / 10 : ℚ) ^ 66 < 1 / 1000 ∧ ¬ ((9 / 10 : ℚ) ^ 65 < 1 / 1000) := by norm_num
-- The last two are cleared of fractions: (a/b)^n < 1/1000 means 1000 · a^n < b^n.
set_option exponentiation.threshold 7000 in
example : 1000 * 99 ^ 688 < 100 ^ 688 ∧ ¬ (1000 * 99 ^ 687 < 100 ^ 687) := by decide
set_option exponentiation.threshold 7000 in
example : 1000 * 999 ^ 6905 < 1000 ^ 6905 ∧ ¬ (1000 * 999 ^ 6904 < 1000 ^ 6904) := by decide

-- M-test for (x/2)^k: the caps' leftover after N terms is 1/2^N. It is 1/1024 at N = 10, under
-- 1/1000; and N = 12 is the first stage under a third of the tolerance, 1/3000.
example : (1 : ℚ) / 2 ^ 10 = 1 / 1024 ∧ (1 : ℚ) / 2 ^ 10 < 1 / 1000 := by norm_num
example : (1 : ℚ) / 2 ^ 12 < 1 / 3000 ∧ ¬ ((1 : ℚ) / 2 ^ 11 < 1 / 3000) := by norm_num

#print axioms uniform_limit_of_continuous_functions_is_continuous
#print axioms weierstrass_m_test_uniform_with_tail_bound
#print axioms pow_converges_pointwise_not_uniformly_on_unit_interval
