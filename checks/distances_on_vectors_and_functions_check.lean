-- The distance menu: on n coordinates the worst-case, straight-line and grid distances satisfy d_∞ ≤ d_2 ≤ d_1 ≤ n·d_∞ and so give the same open sets, while on continuous functions on [0, 1] the worst-gap and average-gap distances do not.
import Mathlib.Analysis.Normed.Lp.PiLp
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.ContinuousMap.Compact
import Mathlib.MeasureTheory.Constructions.UnitInterval
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory unitInterval

theorem distances_integral_pow (k : ℕ) : ∫ t : I, |(t : ℝ) ^ k| = 1 / (k + 1) := by
  have h1 : ∫ t : I, |(t : ℝ) ^ k| = ∫ x in Set.Icc (0 : ℝ) 1, |x ^ k| :=
    integral_subtype_comap measurableSet_Icc (fun x : ℝ => |x ^ k|)
  rw [h1, integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le zero_le_one]
  have h2 : ∫ x in (0 : ℝ)..1, |x ^ k| = ∫ x in (0 : ℝ)..1, x ^ k := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le zero_le_one] at hx
    exact abs_of_nonneg (pow_nonneg hx.1 k)
  rw [h2, integral_pow]
  simp

#print axioms distances_integral_pow

theorem distances_norm_pow (k : ℕ) :
    1 ≤ ‖(⟨fun t : I => (t : ℝ) ^ k, by fun_prop⟩ : C(I, ℝ))‖ := by
  have := ContinuousMap.norm_coe_le_norm (⟨fun t : I => (t : ℝ) ^ k, by fun_prop⟩ : C(I, ℝ)) 1
  simpa using this

#print axioms distances_norm_pow

/-- The sandwich. For two points x and y with n coordinates, the worst-case distance
(`dist` on `Fin n → ℝ`, the largest coordinate gap) is at most the straight-line distance
(`PiLp 2`), which is at most the grid distance (`PiLp 1`), which is at most n times the
worst-case distance. -/
theorem worst_le_straight_le_grid_le_n_worst (n : ℕ) (x y : Fin n → ℝ) :
    dist x y ≤ dist (WithLp.toLp 2 x : PiLp 2 (fun _ : Fin n => ℝ)) (WithLp.toLp 2 y) ∧
    dist (WithLp.toLp 2 x : PiLp 2 (fun _ : Fin n => ℝ)) (WithLp.toLp 2 y) ≤
      dist (WithLp.toLp 1 x : PiLp 1 (fun _ : Fin n => ℝ)) (WithLp.toLp 1 y) ∧
    dist (WithLp.toLp 1 x : PiLp 1 (fun _ : Fin n => ℝ)) (WithLp.toLp 1 y) ≤ n * dist x y := by
  refine ⟨?_, ?_, ?_⟩
  · rw [dist_pi_le_iff dist_nonneg]
    intro i
    have := PiLp.dist_apply_le (WithLp.toLp 2 x : PiLp 2 (fun _ : Fin n => ℝ))
      (WithLp.toLp 2 y) i
    simpa using this
  · rw [PiLp.dist_eq_of_L2, PiLp.dist_eq_of_L1, Real.sqrt_le_left]
    · exact Finset.sum_sq_le_sq_sum_of_nonneg (fun _ _ => dist_nonneg)
    · exact Finset.sum_nonneg (fun _ _ => dist_nonneg)
  · rw [PiLp.dist_eq_of_L1]
    calc ∑ i, dist ((WithLp.toLp 1 x : PiLp 1 (fun _ : Fin n => ℝ)) i)
          ((WithLp.toLp 1 y : PiLp 1 (fun _ : Fin n => ℝ)) i)
        ≤ ∑ _i : Fin n, dist x y := by
          apply Finset.sum_le_sum
          intro i _
          simpa using dist_le_pi_dist x y i
      _ = n * dist x y := by simp

/-- Same open sets. On n coordinates, a set U is open for the grid distance (every point of U
has an open grid ball round it inside U) exactly when it is open for the worst-case distance,
and the same holds for the straight-line distance. -/
theorem grid_straight_worst_same_open_sets (n : ℕ) (U : Set (Fin n → ℝ)) :
    ((∀ x ∈ U, ∃ r > 0, ∀ y, dist (WithLp.toLp 1 x : PiLp 1 (fun _ : Fin n => ℝ))
        (WithLp.toLp 1 y) < r → y ∈ U) ↔
      (∀ x ∈ U, ∃ r > 0, ∀ y, dist x y < r → y ∈ U)) ∧
    ((∀ x ∈ U, ∃ r > 0, ∀ y, dist (WithLp.toLp 2 x : PiLp 2 (fun _ : Fin n => ℝ))
        (WithLp.toLp 2 y) < r → y ∈ U) ↔
      (∀ x ∈ U, ∃ r > 0, ∀ y, dist x y < r → y ∈ U)) := by
  have hn : (0 : ℝ) < n + 1 := by positivity
  refine ⟨⟨?_, ?_⟩, ⟨?_, ?_⟩⟩
  · intro h x hx
    obtain ⟨r, hr, hU⟩ := h x hx
    refine ⟨r / (n + 1), div_pos hr hn, fun y hy => hU y ?_⟩
    obtain ⟨-, -, h3⟩ := worst_le_straight_le_grid_le_n_worst n x y
    rw [lt_div_iff₀ hn] at hy
    nlinarith [dist_nonneg (x := x) (y := y)]
  · intro h x hx
    obtain ⟨r, hr, hU⟩ := h x hx
    refine ⟨r, hr, fun y hy => hU y ?_⟩
    obtain ⟨h1, h2, -⟩ := worst_le_straight_le_grid_le_n_worst n x y
    linarith
  · intro h x hx
    obtain ⟨r, hr, hU⟩ := h x hx
    refine ⟨r / (n + 1), div_pos hr hn, fun y hy => hU y ?_⟩
    obtain ⟨-, h2, h3⟩ := worst_le_straight_le_grid_le_n_worst n x y
    rw [lt_div_iff₀ hn] at hy
    nlinarith [dist_nonneg (x := x) (y := y)]
  · intro h x hx
    obtain ⟨r, hr, hU⟩ := h x hx
    refine ⟨r, hr, fun y hy => hU y ?_⟩
    obtain ⟨h1, -, -⟩ := worst_le_straight_le_grid_le_n_worst n x y
    linarith

/-- No sandwich on routes. On C[0, 1] (`C(I, ℝ)`, whose `dist` is the worst gap) no constant c
gives worst gap ≤ c · average gap (the average gap being ∫ |f - g| over [0, 1]); and the
worst-gap ball of radius 1/2 round the road 0 is open for the worst gap but not open for the
average gap. -/
theorem worst_gap_and_average_gap_not_equivalent :
    (¬ ∃ c : ℝ, ∀ f g : C(I, ℝ), dist f g ≤ c * ∫ t, |f t - g t|) ∧
    IsOpen (Metric.ball (0 : C(I, ℝ)) (1 / 2)) ∧
    ¬ (∀ f ∈ Metric.ball (0 : C(I, ℝ)) (1 / 2), ∃ ε > 0, ∀ g : C(I, ℝ),
        (∫ t, |f t - g t|) < ε → g ∈ Metric.ball (0 : C(I, ℝ)) (1 / 2)) := by
  refine ⟨?_, Metric.isOpen_ball, ?_⟩
  · rintro ⟨c, hc⟩
    obtain ⟨k, hk⟩ := exists_nat_gt c
    have h := hc (⟨fun t : I => (t : ℝ) ^ k, by fun_prop⟩ : C(I, ℝ)) 0
    have hi : ∫ t : I, |(⟨fun t : I => (t : ℝ) ^ k, by fun_prop⟩ : C(I, ℝ)) t -
        (0 : C(I, ℝ)) t| = 1 / (k + 1) := by
      simpa using distances_integral_pow k
    rw [hi, dist_zero_right] at h
    have hn := distances_norm_pow k
    have hk1 : (0 : ℝ) < k + 1 := by positivity
    have : c * (1 / (k + 1)) < 1 := by
      rw [mul_one_div, div_lt_one hk1]; linarith
    linarith
  · intro h
    obtain ⟨ε, hε, hg⟩ := h 0 (Metric.mem_ball_self (by norm_num))
    obtain ⟨k, hk⟩ := exists_nat_one_div_lt hε
    have hi : ∫ t : I, |(0 : C(I, ℝ)) t -
        (⟨fun t : I => (t : ℝ) ^ k, by fun_prop⟩ : C(I, ℝ)) t| = 1 / (k + 1) := by
      simpa using distances_integral_pow k
    have hmem := hg (⟨fun t : I => (t : ℝ) ^ k, by fun_prop⟩ : C(I, ℝ)) (by rw [hi]; exact hk)
    rw [Metric.mem_ball, dist_zero_right] at hmem
    have hn := distances_norm_pow k
    linarith

-- The van, A = (3, 4) to B = (8, 1): grid 8 km, worst case 5 km, straight line squared 34.
example : |(3 : ℤ) - 8| + |(4 : ℤ) - 1| = 8 := by norm_num
example : max |(3 : ℤ) - 8| |(4 : ℤ) - 1| = 5 := by norm_num
example : ((3 : ℤ) - 8) ^ 2 + (4 - 1) ^ 2 = 34 := by norm_num
-- The sandwich for A to B with n = 2: 5 ≤ √34 ≤ 8 ≤ 2 × 5.
example : (5 : ℝ) ≤ Real.sqrt 34 ∧ Real.sqrt 34 ≤ 8 ∧ (8 : ℝ) ≤ 2 * 5 := by
  refine ⟨?_, ?_, by norm_num⟩
  · rw [Real.le_sqrt (by norm_num) (by norm_num)]; norm_num
  · rw [Real.sqrt_le_left (by norm_num)]; norm_num

-- Hausdorff distance on the grid, drops {A, B} against lockers {(2,2), (8,2), (5,7)}:
-- drops to lockers is 3, lockers to drops is 5, so d_H = 5 km.
example :
    let d := fun p q : ℤ × ℤ => |p.1 - q.1| + |p.2 - q.2|
    let S : List (ℤ × ℤ) := [(3, 4), (8, 1)]
    let T : List (ℤ × ℤ) := [(2, 2), (8, 2), (5, 7)]
    ((∀ s ∈ S, ∃ u ∈ T, d s u ≤ 3) ∧ (∃ s ∈ S, ∀ u ∈ T, 3 ≤ d s u)) ∧
    ((∀ u ∈ T, ∃ s ∈ S, d s u ≤ 5) ∧ (∃ u ∈ T, ∀ s ∈ S, 5 ≤ d s u)) := by
  decide

-- What breaks: the squared straight line is not a metric. A to B is 34, but A to the
-- midpoint (11/2, 5/2) and on to B is 17/2 + 17/2 = 17.
example : ((3 : ℚ) - 8) ^ 2 + (4 - 1) ^ 2 >
    (((3 : ℚ) - 11 / 2) ^ 2 + (4 - 5 / 2) ^ 2) + ((11 / 2 - 8) ^ 2 + (5 / 2 - 1) ^ 2) := by
  norm_num

-- A tent of width 1/1000 and height 1: average gap 1/2 · 1/1000 · 1 = 1/2000, ratio 2000.
example : (1 : ℚ) / 2 * (1 / 1000) * 1 = 1 / 2000 ∧ (1 : ℚ) / (1 / 2000) = 2000 := by norm_num

#print axioms worst_le_straight_le_grid_le_n_worst
#print axioms grid_straight_worst_same_open_sets
#print axioms worst_gap_and_average_gap_not_equivalent
