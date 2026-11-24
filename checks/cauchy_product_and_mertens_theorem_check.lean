-- The Cauchy product: if one series converges absolutely and the other converges, their diagonal-by-diagonal product converges to the product of the sums.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.Normed.Group.Tannery
import Mathlib.Topology.Algebra.InfiniteSum.Real

open Finset Filter Topology

/-- Helper: the first N diagonals of the Cauchy product, regrouped by the first factor's index. -/
theorem cauchy_product_partial_sum_eq (a b : ℕ → ℝ) (N : ℕ) :
    ∑ n ∈ range N, ∑ k ∈ range (n + 1), a k * b (n - k)
      = ∑ k ∈ range N, a k * ∑ j ∈ range (N - k), b j := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [sum_range_succ, ih, sum_range_succ (fun k => a k * ∑ j ∈ range (N + 1 - k), b j) N,
      sum_range_succ (fun k => a k * b (N - k)) N]
    have h : ∀ k ∈ range N, a k * ∑ j ∈ range (N + 1 - k), b j
        = a k * ∑ j ∈ range (N - k), b j + a k * b (N - k) := by
      intro k hk
      rw [mem_range] at hk
      rw [show N + 1 - k = (N - k) + 1 by omega, sum_range_succ, mul_add]
    rw [sum_congr rfl h, sum_add_distrib]
    simp only [Nat.sub_self, Nat.add_sub_cancel_left, sum_range_one]
    ring

#print axioms cauchy_product_partial_sum_eq

/-- Mertens' theorem. Let the first factor converge absolutely (its sizes |a n| add to a finite
total) with sum `A`, and let the second factor converge, perhaps only conditionally, to `B`.
Then the Cauchy product, whose term n is `a 0 * b n + a 1 * b (n - 1) + ... + a n * b 0`,
converges to `A * B`. Convergence here means the partial sums head for the limit. -/
theorem cauchy_product_tendsto_mul_of_abs_summable (a b : ℕ → ℝ) (A B : ℝ)
    (ha : Summable fun n => |a n|)
    (hA : Tendsto (fun N => ∑ n ∈ range N, a n) atTop (𝓝 A))
    (hB : Tendsto (fun N => ∑ n ∈ range N, b n) atTop (𝓝 B)) :
    Tendsto (fun N => ∑ n ∈ range N, ∑ k ∈ range (n + 1), a k * b (n - k)) atTop
      (𝓝 (A * B)) := by
  set β : ℕ → ℝ := fun m => ∑ j ∈ range m, b j - B with hβdef
  have hβ : Tendsto β atTop (𝓝 0) := by simpa [β] using hB.sub_const B
  obtain ⟨M, hM⟩ : ∃ M, ∀ m, |β m| ≤ M := by
    obtain ⟨C, hC⟩ := isBounded_iff_forall_norm_le.1 (Metric.isBounded_range_of_tendsto β hβ)
    exact ⟨C, fun m => hC _ ⟨m, rfl⟩⟩
  have key : ∀ N, ∑ n ∈ range N, ∑ k ∈ range (n + 1), a k * b (n - k)
      = (∑ n ∈ range N, a n) * B + ∑' k, (if k < N then a k * β (N - k) else 0) := by
    intro N
    rw [tsum_eq_sum (s := range N) (fun k hk => by
      rw [mem_range] at hk; simp [hk])]
    rw [cauchy_product_partial_sum_eq, sum_mul, ← sum_add_distrib]
    apply sum_congr rfl
    intro k hk
    have hk' := mem_range.1 hk
    simp only [hk', ↓reduceIte, β]
    ring
  have hT : Tendsto (fun N => ∑' k, (if k < N then a k * β (N - k) else 0)) atTop (𝓝 0) := by
    have := tendsto_tsum_of_dominated_convergence
      (f := fun N k => if k < N then a k * β (N - k) else 0) (g := fun _ => (0 : ℝ))
      (bound := fun k => |a k| * M) (𝓕 := atTop) (ha.mul_right M) ?_ ?_
    · simpa using this
    · intro k
      have h1 : Tendsto (fun N => a k * β (N - k)) atTop (𝓝 0) := by
        simpa using (hβ.comp (tendsto_sub_atTop_nat k)).const_mul (a k)
      apply h1.congr'
      filter_upwards [eventually_gt_atTop k] with N hN
      simp [hN]
    · exact Eventually.of_forall fun N k => by
        split_ifs
        · rw [Real.norm_eq_abs, abs_mul]
          exact mul_le_mul_of_nonneg_left (hM _) (abs_nonneg _)
        · simpa using mul_nonneg (abs_nonneg (a k)) ((abs_nonneg _).trans (hM 0))
  refine Tendsto.congr (fun N => (key N).symm) ?_
  simpa using (hA.mul_const B).add hT

/-- Without absolute convergence it fails. The series 1 - 1/√2 + 1/√3 - ... converges, but every
term of its Cauchy square has size at least 1, so the square has no sum. -/
theorem cauchy_square_alternating_inv_sqrt_diverges :
    let a : ℕ → ℝ := fun n => (-1) ^ n / Real.sqrt (n + 1)
    (∃ S, Tendsto (fun N => ∑ n ∈ range N, a n) atTop (𝓝 S)) ∧
    (∀ n, 1 ≤ |∑ k ∈ range (n + 1), a k * a (n - k)|) ∧
    ¬ ∃ L, Tendsto (fun N => ∑ n ∈ range N, ∑ k ∈ range (n + 1), a k * a (n - k)) atTop
      (𝓝 L) := by
  intro a
  have h2 : ∀ n, 1 ≤ |∑ k ∈ range (n + 1), a k * a (n - k)| := by
    intro n
    have hterm : ∀ k ∈ range (n + 1), a k * a (n - k)
        = (-1) ^ n * (1 / (Real.sqrt ((k : ℝ) + 1) * Real.sqrt (((n - k : ℕ) : ℝ) + 1))) := by
      intro k hk
      have hk' : k ≤ n := Nat.lt_succ_iff.1 (mem_range.1 hk)
      simp only [a]
      rw [show ((-1 : ℝ)) ^ n = (-1) ^ k * (-1) ^ (n - k) by
        rw [← pow_add, Nat.add_sub_cancel' hk']]
      rw [div_mul_div_comm, mul_one_div]
    rw [sum_congr rfl hterm, ← mul_sum, abs_mul, abs_pow, abs_neg, abs_one, one_pow, one_mul]
    have hlow : ∀ k ∈ range (n + 1), 2 / ((n : ℝ) + 2)
        ≤ 1 / (Real.sqrt ((k : ℝ) + 1) * Real.sqrt (((n - k : ℕ) : ℝ) + 1)) := by
      intro k hk
      have hk' : k ≤ n := Nat.lt_succ_iff.1 (mem_range.1 hk)
      have hx : Real.sqrt ((k : ℝ) + 1) ^ 2 = (k : ℝ) + 1 := Real.sq_sqrt (by positivity)
      have hy : Real.sqrt (((n - k : ℕ) : ℝ) + 1) ^ 2 = ((n - k : ℕ) : ℝ) + 1 :=
        Real.sq_sqrt (by positivity)
      have hsum : ((n - k : ℕ) : ℝ) + k = n := by exact_mod_cast Nat.sub_add_cancel hk'
      have hxpos : 0 < Real.sqrt ((k : ℝ) + 1) := Real.sqrt_pos.2 (by positivity)
      have hypos : 0 < Real.sqrt (((n - k : ℕ) : ℝ) + 1) := Real.sqrt_pos.2 (by positivity)
      rw [div_le_div_iff₀ (by positivity) (by positivity)]
      nlinarith [sq_nonneg (Real.sqrt ((k : ℝ) + 1) - Real.sqrt (((n - k : ℕ) : ℝ) + 1))]
    have hs := sum_le_sum hlow
    rw [sum_const, card_range, nsmul_eq_mul] at hs
    rw [abs_of_nonneg (sum_nonneg fun k _ => by positivity)]
    refine le_trans ?_ hs
    rw [mul_div_assoc', le_div_iff₀ (by positivity)]
    push_cast
    linarith [(Nat.cast_nonneg n : (0 : ℝ) ≤ n)]
  refine ⟨?_, h2, ?_⟩
  · have hanti : Antitone fun n : ℕ => (Real.sqrt ((n : ℝ) + 1))⁻¹ := by
      intro m n hmn
      apply inv_anti₀ (Real.sqrt_pos.2 (by positivity))
      apply Real.sqrt_le_sqrt
      have : (m : ℝ) ≤ n := by exact_mod_cast hmn
      linarith
    have h0 : Tendsto (fun n : ℕ => (Real.sqrt ((n : ℝ) + 1))⁻¹) atTop (𝓝 0) := by
      apply tendsto_inv_atTop_zero.comp
      apply Real.tendsto_sqrt_atTop.comp
      exact tendsto_atTop_add_const_right _ 1 tendsto_natCast_atTop_atTop
    obtain ⟨l, hl⟩ := hanti.tendsto_alternating_series_of_tendsto_zero h0
    exact ⟨l, by simpa [a, div_eq_mul_inv] using hl⟩
  · rintro ⟨L, hL⟩
    have hc : Tendsto (fun n => ∑ k ∈ range (n + 1), a k * a (n - k)) atTop (𝓝 0) := by
      have := (hL.comp (tendsto_add_atTop_nat 1)).sub hL
      rw [sub_self] at this
      refine this.congr (fun n => ?_)
      simp [Function.comp, sum_range_succ]
    have := ge_of_tendsto' hc.abs h2
    norm_num at this

/-- The house series squared: the Cauchy product of 1 + 1/2 + 1/4 + ... with itself has terms
(n + 1)/2^n, and they add up to 2 × 2 = 4. -/
theorem cauchy_square_geometric_half :
    (∀ n : ℕ, ∑ k ∈ range (n + 1), (1 / 2 : ℝ) ^ k * (1 / 2) ^ (n - k) = (n + 1) / 2 ^ n) ∧
    HasSum (fun n : ℕ => ∑ k ∈ range (n + 1), (1 / 2 : ℝ) ^ k * (1 / 2) ^ (n - k)) 4 := by
  have h1 : ∀ n : ℕ, ∑ k ∈ range (n + 1), (1 / 2 : ℝ) ^ k * (1 / 2) ^ (n - k)
      = (n + 1) / 2 ^ n := by
    intro n
    rw [sum_congr rfl (fun k hk => by
      rw [← pow_add, Nat.add_sub_cancel' (Nat.lt_succ_iff.1 (mem_range.1 hk))])]
    rw [sum_const, card_range, nsmul_eq_mul]
    push_cast
    rw [one_div_pow, mul_one_div]
  refine ⟨h1, ?_⟩
  simp_rw [h1]
  have hn := hasSum_coe_mul_geometric_of_norm_lt_one (r := (1 / 2 : ℝ)) (by norm_num)
  have := hn.add hasSum_geometric_two
  convert this using 1
  · funext n
    rw [one_div_pow]
    field_simp
  · norm_num

-- Worked numbers: the house series' diagonal totals 1, 1, 3/4, 1/2, 5/16, 3/16.
example : (List.range 6).map (fun n => ∑ k ∈ range (n + 1), (1 / 2 : ℚ) ^ k * (1 / 2) ^ (n - k))
    = [1, 1, 3 / 4, 1 / 2, 5 / 16, 3 / 16] := by
  norm_num [List.range_succ, Finset.sum_range_succ]

-- Through diagonal 10 the total is 4 - 13/1024, matching C_N = 4 - (N + 3)/2^N.
example : ∑ n ∈ range 11, ∑ k ∈ range (n + 1), (1 / 2 : ℚ) ^ k * (1 / 2) ^ (n - k)
    = 4 - 13 / 1024 := by
  simp [Finset.sum_range_succ]; norm_num

-- The rising perpetual bond at 5%: 21 × 20 = 420.
example : (21 : ℕ) * 20 = 420 := by norm_num

#print axioms cauchy_product_tendsto_mul_of_abs_summable
#print axioms cauchy_square_alternating_inv_sqrt_diverges
#print axioms cauchy_square_geometric_half
