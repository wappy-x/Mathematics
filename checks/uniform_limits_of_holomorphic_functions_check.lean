-- Limits of holomorphic functions: if holomorphic functions on an open set converge uniformly on every closed disc inside it, the limit is holomorphic there and every derivative of the approximations converges to the same derivative of the limit, and the card's tower (the sum of z^n/n^2) is within 1/N of its first N floors everywhere on the closed unit disc, with slope 2 ln 2 at z = 1/2.
import Mathlib.Analysis.Complex.LocallyUniformLimit
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Calculus.SmoothSeries
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.PSeries

open Set Metric Filter Topology

/-- **Weierstrass's convergence theorem.** Let U be an open set in the complex plane, and let
F 0, F 1, F 2, … be functions that are holomorphic (complex differentiable) on U. Suppose they
converge to f uniformly on every closed disc that sits wholly inside U (uniformly on the whole of
U is not required). Then f is holomorphic on U, and for every k the k-th derivatives of the F n
converge to the k-th derivative of f, uniformly near each point of U. -/
theorem uniform_limit_of_holomorphic_is_holomorphic_with_derivatives
    {U : Set ℂ} (hU : IsOpen U) {F : ℕ → ℂ → ℂ} {f : ℂ → ℂ}
    (hF : ∀ n, DifferentiableOn ℂ (F n) U)
    (hlim : ∀ (c : ℂ) (R : ℝ), closedBall c R ⊆ U → TendstoUniformlyOn F f atTop (closedBall c R)) :
    DifferentiableOn ℂ f U ∧
      ∀ k : ℕ, TendstoLocallyUniformlyOn (fun n => iteratedDeriv k (F n)) (iteratedDeriv k f) atTop U := by
  have hloc : TendstoLocallyUniformlyOn F f atTop U := by
    refine tendstoLocallyUniformlyOn_of_forall_exists_nhds fun x hx => ?_
    obtain ⟨r, hr, hrU⟩ := Metric.isOpen_iff.mp hU x hx
    refine ⟨closedBall x (r / 2), mem_nhdsWithin_of_mem_nhds (closedBall_mem_nhds x (by positivity)),
      hlim x (r / 2) ((closedBall_subset_ball (by linarith)).trans hrU)⟩
  have hf : DifferentiableOn ℂ f U := hloc.differentiableOn (Eventually.of_forall hF) hU
  refine ⟨hf, fun k => ?_⟩
  have key : ∀ k : ℕ, (∀ n, DifferentiableOn ℂ (iteratedDeriv k (F n)) U) ∧
      TendstoLocallyUniformlyOn (fun n => iteratedDeriv k (F n)) (iteratedDeriv k f) atTop U := by
    intro k
    induction k with
    | zero => simpa using ⟨hF, hloc⟩
    | succ k ih =>
      obtain ⟨h1, h2⟩ := ih
      refine ⟨fun n => ?_, ?_⟩
      · rw [iteratedDeriv_succ]
        exact ((h1 n).analyticOnNhd hU).deriv.differentiableOn
      · simp only [iteratedDeriv_succ]
        exact h2.deriv (Eventually.of_forall h1) hU
  exact (key k).2

/-- The card's tower: floor n is z^n/n^2, for n = 1, 2, 3, …, and the tower is their sum. -/
noncomputable def tower (z : ℂ) : ℂ := ∑' n : ℕ, z ^ (n + 1) / ((n + 1 : ℂ) ^ 2)

lemma tower_term_norm_le (z : ℂ) (hz : ‖z‖ ≤ 1) (n : ℕ) :
    ‖z ^ (n + 1) / ((n + 1 : ℂ) ^ 2)‖ ≤ 1 / ((n + 1 : ℝ) ^ 2) := by
  rw [norm_div, norm_pow, norm_pow]
  have h1 : ‖(n + 1 : ℂ)‖ = (n + 1 : ℝ) := by
    exact_mod_cast Complex.norm_natCast (n + 1)
  rw [h1]
  gcongr
  exact pow_le_one₀ (norm_nonneg _) hz

#print axioms tower_term_norm_le

lemma summable_inv_sq_succ : Summable (fun n : ℕ => 1 / ((n + 1 : ℝ) ^ 2)) := by
  have := (summable_nat_add_iff 1).mpr (Real.summable_one_div_nat_pow.mpr (by norm_num : 1 < 2))
  simpa [Nat.cast_add, Nat.cast_one] using this

#print axioms summable_inv_sq_succ

lemma telescope_sum (N : ℕ) (hN : 1 ≤ N) (M : ℕ) :
    ∑ i ∈ Finset.range M, 1 / (((i + N : ℕ) : ℝ) * ((i + N : ℕ) + 1 : ℝ)) =
      1 / (N : ℝ) - 1 / ((M + N : ℕ) : ℝ) := by
  have hN' : (0 : ℝ) < N := by exact_mod_cast hN
  induction M with
  | zero => simp
  | succ M ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (0 : ℝ) < ((M + N : ℕ) : ℝ) := by push_cast; positivity
    have h2 : ((M + 1 + N : ℕ) : ℝ) = ((M + N : ℕ) : ℝ) + 1 := by push_cast; ring
    rw [h2]
    field_simp
    ring

#print axioms telescope_sum

lemma tower_floor_hasDerivAt (n : ℕ) (y : ℂ) :
    HasDerivAt (fun y : ℂ => y ^ (n + 1) / ((n + 1 : ℂ) ^ 2)) (y ^ n / ((n + 1 : ℂ))) y := by
  have h := (hasDerivAt_pow (n + 1) y).div_const ((n + 1 : ℂ) ^ 2)
  convert h using 1
  have hn : (n + 1 : ℂ) ≠ 0 := by exact_mod_cast Nat.succ_ne_zero n
  push_cast
  field_simp

#print axioms tower_floor_hasDerivAt

lemma floor_slope_sum_half :
    HasSum (fun n : ℕ => (1 / 2 : ℂ) ^ n / ((n + 1 : ℂ))) ((2 * Real.log 2 : ℝ) : ℂ) := by
  have h := (Real.hasSum_pow_div_log_of_abs_lt_one (x := 1 / 2) (by norm_num [abs_of_pos])).mul_left 2
  have hl : -Real.log (1 - 1 / 2) = Real.log 2 := by
    rw [show (1 : ℝ) - 1 / 2 = (2 : ℝ)⁻¹ by norm_num, Real.log_inv, neg_neg]
  rw [hl] at h
  have hc := Complex.hasSum_ofReal.mpr h
  convert hc using 1
  funext n
  push_cast
  ring

#print axioms floor_slope_sum_half

/-- **The M-test bound for the tower.** For every N ≥ 1 and every z in the closed unit disc
(|z| ≤ 1), the gap between the tower and its first N floors is at most the sum of the remaining
ceilings 1/n^2 for n > N, and that sum is less than 1/N. The bound does not depend on z, so the
first N floors converge to the tower uniformly on the closed disc. -/
theorem tower_gap_le_tail_lt_inv (N : ℕ) (hN : 1 ≤ N) (z : ℂ) (hz : ‖z‖ ≤ 1) :
    ‖tower z - ∑ n ∈ Finset.range N, z ^ (n + 1) / ((n + 1 : ℂ) ^ 2)‖ ≤
        ∑' n : ℕ, 1 / ((n + N + 1 : ℝ) ^ 2) ∧
      ∑' n : ℕ, 1 / ((n + N + 1 : ℝ) ^ 2) < 1 / (N : ℝ) := by
  set a : ℕ → ℂ := fun n => z ^ (n + 1) / ((n + 1 : ℂ) ^ 2) with ha
  have hsa : Summable a :=
    Summable.of_norm_bounded summable_inv_sq_succ (tower_term_norm_le z hz)
  have hsplit := hsa.sum_add_tsum_nat_add N
  have hgs : Summable (fun n : ℕ => 1 / ((n + N + 1 : ℝ) ^ 2)) := by
    have := (summable_nat_add_iff N).mpr summable_inv_sq_succ
    simpa [Nat.cast_add] using this
  refine ⟨?_, ?_⟩
  · have htower : tower z = ∑' n, a n := rfl
    rw [htower, ← hsplit, add_sub_cancel_left]
    refine tsum_of_norm_bounded hgs.hasSum fun n => ?_
    have := tower_term_norm_le z hz (n + N)
    simpa [ha, Nat.cast_add, add_assoc] using this
  · have hN' : (0 : ℝ) < N := by exact_mod_cast hN
    set g : ℕ → ℝ := fun i => 1 / (((i + N : ℕ) : ℝ) * ((i + N : ℕ) + 1 : ℝ)) with hg
    have g0 : ∀ i, 0 ≤ g i := fun i => by simp only [hg]; positivity
    have gle : ∀ M, ∑ i ∈ Finset.range M, g i ≤ 1 / (N : ℝ) := by
      intro M
      rw [hg, telescope_sum N hN M]
      have : (0 : ℝ) ≤ 1 / ((M + N : ℕ) : ℝ) := by positivity
      linarith
    have hsg : Summable g := summable_of_sum_range_le g0 gle
    have hlt : ∑' n : ℕ, 1 / ((n + N + 1 : ℝ) ^ 2) < ∑' n, g n := by
      refine Summable.tsum_lt_tsum_of_nonneg (i := 0) (fun b => by positivity) (fun b => ?_) ?_ hsg
      · simp only [hg]
        have hb : (0 : ℝ) < ((b + N : ℕ) : ℝ) := by push_cast; positivity
        push_cast at hb ⊢
        apply one_div_le_one_div_of_le (by positivity)
        nlinarith
      · simp only [hg]
        push_cast
        apply one_div_lt_one_div_of_lt (by positivity)
        nlinarith
    exact hlt.trans_le (Real.tsum_le_of_sum_range_le g0 gle)

/-- **The tower's slope is the stack of the floors' slopes.** At every point z of the open unit
disc (|z| < 1), the tower has a complex derivative, and it equals 1 + z/2 + z^2/3 + …, the sum of
the floor slopes z^(n−1)/n. At z = 1/2 that slope is 2 ln 2. -/
theorem tower_hasDerivAt_floor_slopes :
    (∀ z : ℂ, ‖z‖ < 1 → HasDerivAt tower (∑' n : ℕ, z ^ n / ((n + 1 : ℂ))) z) ∧
      HasDerivAt tower ((2 * Real.log 2 : ℝ) : ℂ) (1 / 2) := by
  have main : ∀ z : ℂ, ‖z‖ < 1 → HasDerivAt tower (∑' n : ℕ, z ^ n / ((n + 1 : ℂ))) z := by
    intro z hz
    set r : ℝ := (‖z‖ + 1) / 2 with hr
    have hr0 : 0 ≤ r := by positivity
    have hr1 : r < 1 := by rw [hr]; linarith
    have hzr : z ∈ ball (0 : ℂ) r := by
      rw [mem_ball, dist_zero_right, hr]; linarith
    have hbound : ∀ (n : ℕ) (y : ℂ), y ∈ ball (0 : ℂ) r → ‖y ^ n / ((n + 1 : ℂ))‖ ≤ r ^ n := by
      intro n y hy
      rw [mem_ball, dist_zero_right] at hy
      rw [norm_div, norm_pow]
      have h1 : ‖(n + 1 : ℂ)‖ = (n + 1 : ℝ) := by
        exact_mod_cast Complex.norm_natCast (n + 1)
      rw [h1, div_le_iff₀ (by positivity)]
      have : ‖y‖ ^ n ≤ r ^ n := pow_le_pow_left₀ (norm_nonneg _) hy.le n
      have : 0 ≤ r ^ n := by positivity
      nlinarith
    have h := hasDerivAt_tsum_of_isPreconnected (summable_geometric_of_lt_one hr0 hr1)
      isOpen_ball (convex_ball (0 : ℂ) r).isPreconnected
      (fun n y _ => tower_floor_hasDerivAt n y) hbound (mem_ball_self (by rw [hr]; positivity))
      (by simp) hzr
    exact h
  refine ⟨main, ?_⟩
  have h := main (1 / 2) (by norm_num)
  rwa [floor_slope_sum_half.tsum_eq] at h

-- Step 1: each ceiling 1/n^2 is below 1/((n − 1)n) = 1/(n − 1) − 1/n; for n = 2, 3, 10.
example : (1 : ℚ) / 2 ^ 2 < 1 / 1 - 1 / 2 := by norm_num
example : (1 : ℚ) / 3 ^ 2 < 1 / 2 - 1 / 3 := by norm_num
example : (1 : ℚ) / 10 ^ 2 < 1 / 9 - 1 / 10 := by norm_num
-- Worked numbers: the even floors carry a quarter of the tower, 1/(2k)^2 = (1/4)(1/k^2); k = 1, 2, 3.
example : (1 : ℚ) / (2 * 1) ^ 2 = 1 / 4 * (1 / 1 ^ 2) := by norm_num
example : (1 : ℚ) / (2 * 3) ^ 2 = 1 / 4 * (1 / 3 ^ 2) := by norm_num
-- The tower at −1: −π^2/6 + 2 × (π^2/6)/4 = −π^2/12.
example : -(Real.pi ^ 2 / 6) + 2 * (Real.pi ^ 2 / 6 / 4) = -(Real.pi ^ 2 / 12) := by ring
-- Floor slopes at 1/2: the first four terms 1 + 1/4 + 1/12 + 1/32, i.e. (1/2)^(n−1)/n for n = 1..4.
example : ((1 : ℚ) / 2) ^ 1 / 2 = 1 / 4 ∧ ((1 : ℚ) / 2) ^ 2 / 3 = 1 / 12 ∧ ((1 : ℚ) / 2) ^ 3 / 4 = 1 / 32 := by
  norm_num
-- The Cauchy estimate after 10 floors: (1/10)/0.4 = 1/4.
example : ((1 : ℚ) / 10) / (2 / 5) = 1 / 4 := by norm_num
-- The figure, 80 units per 1 from (180, 120): 1 at 260, −1 at 100, 1/2 at 220, radius 0.4 is 32, i/2 at height 80.
example : (180 : ℚ) + 80 = 260 ∧ (180 : ℚ) - 80 = 100 ∧ (180 : ℚ) + 80 * (1 / 2) = 220 ∧
    (80 : ℚ) * (2 / 5) = 32 ∧ (120 : ℚ) - 80 * (1 / 2) = 80 := by norm_num
-- Zeta link: floor 5 at s = 2 + 3i has size 5^(−2) = 1/25.
example : (1 : ℚ) / 5 ^ 2 = 1 / 25 := by norm_num

#print axioms uniform_limit_of_holomorphic_is_holomorphic_with_derivatives
#print axioms tower_gap_le_tail_lt_inv
#print axioms tower_hasDerivAt_floor_slopes
