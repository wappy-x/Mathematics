-- Abel's limit theorem: if a real power series converges at x = 1, its values for x rising to 1 tend to that edge sum, which gives ln 2 and pi/4, and the converse fails.
import Mathlib.Analysis.Complex.AbelLimit
import Mathlib.Analysis.Real.Pi.Leibniz
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open Filter Finset
open scoped Topology

/-- **Abel's limit theorem.** If the edge series `a 0 + a 1 + a 2 + ⋯` converges to `s`
(its partial sums tend to `s`), then the power series `∑ a n * x ^ n`, summed at `x` and
with `x` rising to 1 from below, tends to the same `s`. -/
theorem power_series_tendsto_edge_sum (a : ℕ → ℝ) (s : ℝ)
    (h : Tendsto (fun N => ∑ n ∈ range N, a n) atTop (𝓝 s)) :
    Tendsto (fun x => ∑' n, a n * x ^ n) (𝓝[<] 1) (𝓝 s) := by
  exact Real.tendsto_tsum_powerSeries_nhdsWithin_lt h

/-- **ln 2 and π/4 from the edge.** The edge series `1 - 1/2 + 1/3 - ⋯` adds up to `ln 2`,
and the edge series `1 - 1/3 + 1/5 - ⋯` adds up to `π/4`. -/
theorem alternating_harmonic_log_two_and_leibniz_pi_div_four :
    Tendsto (fun N => ∑ i ∈ range N, (-1 : ℝ) ^ i / (i + 1)) atTop (𝓝 (Real.log 2)) ∧
    Tendsto (fun N => ∑ i ∈ range N, (-1 : ℝ) ^ i / (2 * i + 1)) atTop (𝓝 (Real.pi / 4)) := by
  refine ⟨?_, Real.tendsto_sum_pi_div_four⟩
  obtain ⟨l, h⟩ :
      ∃ l, Tendsto (fun n ↦ ∑ i ∈ range n, (-1 : ℝ) ^ i / (i + 1)) atTop (𝓝 l) := by
    have := Antitone.tendsto_alternating_series_of_tendsto_zero
      (f := fun i : ℕ => 1 / ((i : ℝ) + 1)) ?_ ?_
    · obtain ⟨l, hl⟩ := this
      exact ⟨l, hl.congr fun n => sum_congr rfl fun i _ => by ring⟩
    · exact antitone_iff_forall_lt.mpr fun _ _ _ ↦ by gcongr
    · exact tendsto_one_div_add_atTop_nhds_zero_nat
  have abel := Real.tendsto_tsum_powerSeries_nhdsWithin_lt h
  have m : 𝓝[<] (1 : ℝ) ≤ 𝓝 1 := nhdsWithin_le_nhds
  replace abel := abel.mul (tendsto_id.mono_left m)
  rw [mul_one] at abel
  replace abel : Tendsto (fun x : ℝ => Real.log (1 + x)) (𝓝[<] 1) (𝓝 l) := by
    apply abel.congr'
    rw [eventuallyEq_nhdsWithin_iff, Metric.eventually_nhds_iff]
    refine ⟨1, zero_lt_one, fun y hy1 hy2 => ?_⟩
    rw [Real.dist_eq, abs_sub_lt_iff] at hy1
    rw [Set.mem_Iio] at hy2
    have ny : |-y| < 1 := by rw [abs_neg, abs_lt]; constructor <;> linarith
    have hs := Real.hasSum_pow_div_log_of_abs_lt_one ny
    rw [sub_neg_eq_add] at hs
    rw [← neg_neg (Real.log (1 + y)), ← hs.tsum_eq, ← tsum_neg, ← tsum_mul_right]
    congr 1; ext n
    simp only [id]
    rw [neg_pow y]
    ring
  have hc : Tendsto (fun x : ℝ => Real.log (1 + x)) (𝓝[<] 1) (𝓝 (Real.log (1 + 1))) :=
    ((Real.continuousAt_log (by norm_num)).tendsto.comp
      ((continuous_const.add continuous_id).tendsto 1)).mono_left m
  rw [tendsto_nhds_unique abel hc] at h
  norm_num at h
  exact h

/-- **The converse fails.** Inside the interval, `1 - x + x^2 - ⋯` equals `1/(1 + x)` and
tends to `1/2` as `x` rises to 1, yet the edge series `1 - 1 + 1 - ⋯` has no sum. -/
theorem abel_converse_fails :
    (∀ x : ℝ, -1 < x → x < 1 → ∑' n, (-1 : ℝ) ^ n * x ^ n = 1 / (1 + x)) ∧
    Tendsto (fun x : ℝ => ∑' n, (-1 : ℝ) ^ n * x ^ n) (𝓝[<] 1) (𝓝 (1 / 2)) ∧
    ¬ ∃ s : ℝ, Tendsto (fun N => ∑ i ∈ range N, (-1 : ℝ) ^ i) atTop (𝓝 s) := by
  have key : ∀ x : ℝ, -1 < x → x < 1 → ∑' n, (-1 : ℝ) ^ n * x ^ n = 1 / (1 + x) := by
    intro x h1 h2
    have hx : |-x| < 1 := by rw [abs_neg, abs_lt]; constructor <;> linarith
    simp_rw [← mul_pow, neg_one_mul]
    rw [tsum_geometric_of_abs_lt_one hx, one_div, sub_neg_eq_add]
  refine ⟨key, ?_, ?_⟩
  · have m : 𝓝[<] (1 : ℝ) ≤ 𝓝 1 := nhdsWithin_le_nhds
    have hc : Tendsto (fun x : ℝ => 1 / (1 + x)) (𝓝[<] 1) (𝓝 (1 / 2)) := by
      have : Tendsto (fun x : ℝ => 1 / (1 + x)) (𝓝 1) (𝓝 (1 / (1 + 1))) :=
        tendsto_const_nhds.div (tendsto_const_nhds.add tendsto_id) (by norm_num)
      norm_num at this
      simpa only [one_div] using this.mono_left m
    apply hc.congr'
    rw [eventuallyEq_nhdsWithin_iff, Metric.eventually_nhds_iff]
    refine ⟨1, zero_lt_one, fun y hy1 hy2 => ?_⟩
    rw [Real.dist_eq, abs_sub_lt_iff] at hy1
    rw [Set.mem_Iio] at hy2
    exact (key y (by linarith) hy2).symm
  · rintro ⟨s, hs⟩
    have h1 := (hs.comp (tendsto_add_atTop_nat 1)).sub hs
    rw [sub_self] at h1
    have h2 : Tendsto (fun N : ℕ => (-1 : ℝ) ^ N) atTop (𝓝 0) :=
      h1.congr fun N => by rw [Function.comp_apply, sum_range_succ]; ring
    have h3 := h2.norm
    simp only [norm_pow, norm_neg, norm_one, one_pow, norm_zero] at h3
    exact one_ne_zero (tendsto_nhds_unique tendsto_const_nhds h3)

/-- The edge partial sums of `1 - 1 + 1 - ⋯` run 1, 0, 1, 0, 1, 0. -/
example : (List.range 6).map (fun N => ∑ i ∈ range (N + 1), (-1 : ℤ) ^ i)
    = [1, 0, 1, 0, 1, 0] := by
  decide

/-- The edge partial sums of `1 - 2 + 3 - ⋯` run 1, -1, 2, -2, 3, -3. -/
example : (List.range 6).map (fun N => ∑ i ∈ range (N + 1), (-1 : ℤ) ^ i * (i + 1))
    = [1, -1, 2, -2, 3, -3] := by
  decide

#print axioms power_series_tendsto_edge_sum
#print axioms alternating_harmonic_log_two_and_leibniz_pi_div_four
#print axioms abel_converse_fails
