-- Normed and Banach spaces: this file proves that a normed space is complete exactly when every series whose term lengths add to a finite total converges, and that continuous curves are complete under the worst-case norm but not under the area norm.
import Mathlib.Analysis.Normed.Group.Completeness
import Mathlib.Analysis.Normed.Module.Basic
import Mathlib.Topology.ContinuousMap.Compact
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Intervals

open Filter Topology Finset

/-- The series test. A normed space has no holes (every Cauchy sequence converges in it) exactly
when every series whose term lengths add to a finite total, `∑ ‖x k‖ < ∞`, has its partial sums
converging to a vector inside the space. -/
theorem complete_iff_series_of_finite_length_converge
    (X : Type*) [NormedAddCommGroup X] [NormedSpace ℝ X] :
    CompleteSpace X ↔
      ∀ x : ℕ → X, Summable (fun k => ‖x k‖) →
        ∃ s : X, Tendsto (fun n => ∑ k ∈ range n, x k) atTop (𝓝 s) := by
  exact ⟨fun _ u hu => NormedAddCommGroup.summable_imp_tendsto_of_complete u hu,
    fun h => NormedAddCommGroup.completeSpace_of_summable_imp_tendsto h⟩

/-- Continuous curves on a closed time window `[a, b]`, measured by the worst-case norm
`‖f‖ = max |f(t)|`, form a Banach space: every Cauchy sequence converges to a continuous curve. -/
theorem continuous_curves_complete_under_worst_case_norm (a b : ℝ) :
    CompleteSpace C(Set.Icc a b, ℝ) := by
  infer_instance

/-- Continuous price curves over the week `[0, 168]`, measured by the area norm
`‖f‖₁ = ∫ |f(t)| dt`, have a hole: some sequence of continuous curves is Cauchy in the area norm
(the ramps closing in on a sudden jump) yet no continuous curve is its limit in that norm. -/
theorem continuous_curves_incomplete_under_area_norm :
    ∃ f : ℕ → ℝ → ℝ, (∀ n, Continuous (f n)) ∧
      (∀ ε > 0, ∃ N : ℕ, ∀ m ≥ N, ∀ n ≥ N, ∫ t in (0 : ℝ)..168, |f m t - f n t| < ε) ∧
      ¬ ∃ g : ℝ → ℝ, ContinuousOn g (Set.Icc 0 168) ∧
        Tendsto (fun n => ∫ t in (0 : ℝ)..168, |f n t - g t|) atTop (𝓝 0) := by
  set f : ℕ → ℝ → ℝ := fun n t => max 0 (min 1 (((n : ℝ) + 1) * (t - 84))) with hf
  have hcont : ∀ n, Continuous (f n) := fun n => by
    simp only [hf]; fun_prop
  have h0 : ∀ n t, t ≤ 84 → f n t = 0 := by
    intro n t ht
    have : ((n : ℝ) + 1) * (t - 84) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (by positivity) (by linarith)
    simp only [hf]
    exact max_eq_left (le_trans (min_le_right _ _) this)
  have h1 : ∀ (n : ℕ) (t : ℝ), 84 + 1 / ((n : ℝ) + 1) ≤ t → f n t = 1 := by
    intro n t ht
    have hn : (0 : ℝ) < (n : ℝ) + 1 := by positivity
    have : 1 ≤ ((n : ℝ) + 1) * (t - 84) := by
      have h' : 1 / ((n : ℝ) + 1) ≤ t - 84 := by linarith
      rw [div_le_iff₀ hn] at h'
      linarith
    simp only [hf]
    rw [min_eq_left this]
    exact max_eq_right zero_le_one
  have hb : ∀ n t, 0 ≤ f n t ∧ f n t ≤ 1 := by
    intro n t
    simp only [hf]
    exact ⟨le_max_left _ _, max_le zero_le_one (min_le_left _ _)⟩
  have h1' : ∀ (N n : ℕ) (t : ℝ), N ≤ n → 84 + 1 / ((N : ℝ) + 1) ≤ t → f n t = 1 := by
    intro N n t hNn ht
    apply h1
    have : 1 / ((n : ℝ) + 1) ≤ 1 / ((N : ℝ) + 1) := by
      apply one_div_le_one_div_of_le (by positivity)
      have : (N : ℝ) ≤ n := by exact_mod_cast hNn
      linarith
    linarith
  refine ⟨f, hcont, ?_, ?_⟩
  · intro ε hε
    obtain ⟨N, hN⟩ := exists_nat_one_div_lt hε
    refine ⟨N, fun m hm n hn => ?_⟩
    set c : ℝ := 84 + 1 / ((N : ℝ) + 1) with hc
    have hcpos : 0 < 1 / ((N : ℝ) + 1) := by positivity
    have hcle : 1 / ((N : ℝ) + 1) ≤ 1 := by
      rw [div_le_one (by positivity)]; have : (0 : ℝ) ≤ N := N.cast_nonneg; linarith
    have hint : ∀ a b : ℝ, IntervalIntegrable (fun t => |f m t - f n t|) MeasureTheory.volume a b :=
      fun a b => ((hcont m).sub (hcont n)).abs.intervalIntegrable a b
    rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 84) (hint 84 168),
      ← intervalIntegral.integral_add_adjacent_intervals (hint 84 c) (hint c 168)]
    have e1 : ∫ t in (0 : ℝ)..84, |f m t - f n t| = 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ))]
      · simp
      intro t ht
      rw [Set.uIcc_of_le (by norm_num)] at ht
      simp [h0 m t ht.2, h0 n t ht.2]
    have e3 : ∫ t in c..168, |f m t - f n t| = 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ))]
      · simp
      intro t ht
      rw [Set.uIcc_of_le (by linarith)] at ht
      simp [h1' N m t hm ht.1, h1' N n t hn ht.1]
    have e2 : ∫ t in (84 : ℝ)..c, |f m t - f n t| ≤ 1 * |c - 84| := by
      refine le_trans (le_abs_self _) ?_
      rw [← Real.norm_eq_abs]
      apply intervalIntegral.norm_integral_le_of_norm_le_const
      intro t _
      rw [Real.norm_eq_abs, abs_abs, abs_le]
      have := hb m t; have := hb n t
      constructor <;> linarith
    have : |c - 84| = 1 / ((N : ℝ) + 1) := by
      rw [hc, add_sub_cancel_left, abs_of_pos hcpos]
    rw [e1, e3]
    rw [this] at e2
    linarith
  · rintro ⟨g, hg, ht⟩
    have hgc : ContinuousWithinAt g (Set.Icc 0 168) 84 := hg 84 ⟨by norm_num, by norm_num⟩
    rw [Metric.continuousWithinAt_iff] at hgc
    obtain ⟨δ₀, hδ₀, hδ⟩ := hgc (1 / 4) (by norm_num)
    set δ := min δ₀ 1 with hδdef
    have hδpos : 0 < δ := lt_min hδ₀ one_pos
    have hδle : δ ≤ 1 := min_le_right _ _
    have hδle0 : δ ≤ δ₀ := min_le_left _ _
    set c := g 84
    have hnear : ∀ t, 84 - δ / 2 ≤ t → t ≤ 84 + 3 * δ / 4 → |g t - c| < 1 / 4 := by
      intro t h1 h2
      have := hδ (x := t) ⟨by linarith, by linarith⟩ (by
        rw [Real.dist_eq, abs_lt]; constructor <;> linarith)
      rwa [Real.dist_eq] at this
    have hint : ∀ n, IntervalIntegrable (fun t => |f n t - g t|) MeasureTheory.volume 0 168 := by
      intro n
      apply ContinuousOn.intervalIntegrable
      rw [Set.uIcc_of_le (by norm_num)]
      exact ((hcont n).continuousOn.sub hg).abs
    have hsmall : ∀ᶠ n in atTop, ∫ t in (0 : ℝ)..168, |f n t - g t| < δ / 16 :=
      ht.eventually (gt_mem_nhds (by positivity))
    obtain ⟨M, hM⟩ := exists_nat_one_div_lt (show 0 < δ / 2 by positivity)
    obtain ⟨n, hn, hnM⟩ := (hsmall.and (eventually_ge_atTop M)).exists
    have hsub : ∀ a b, 0 ≤ a → a ≤ b → b ≤ 168 →
        ∫ t in a..b, |f n t - g t| ≤ ∫ t in (0 : ℝ)..168, |f n t - g t| := by
      intro a b ha hab hb
      apply intervalIntegral.integral_mono_interval ha hab hb
      · exact Filter.Eventually.of_forall (fun t => abs_nonneg _)
      · exact hint n
    have hsubint : ∀ a b, 0 ≤ a → a ≤ b → b ≤ 168 →
        IntervalIntegrable (fun t => |f n t - g t|) MeasureTheory.volume a b := by
      intro a b ha hab hb
      apply ContinuousOn.intervalIntegrable
      rw [Set.uIcc_of_le hab]
      exact (((hcont n).continuousOn.sub hg).abs).mono (Set.Icc_subset_Icc ha hb)
    by_cases hc : 1 / 2 ≤ |c|
    · have hlow : ∫ t in (84 - δ / 2)..84, (1 / 4 : ℝ) ≤ ∫ t in (84 - δ / 2)..84, |f n t - g t| := by
        apply intervalIntegral.integral_mono_on (by linarith) intervalIntegrable_const
          (hsubint _ _ (by linarith) (by linarith) (by norm_num))
        intro t htt
        rw [h0 n t htt.2, zero_sub, abs_neg]
        have := hnear t htt.1 (by linarith [htt.2])
        have := abs_sub_abs_le_abs_sub c (g t)
        rw [abs_sub_comm c] at this
        linarith
      rw [intervalIntegral.integral_const, smul_eq_mul] at hlow
      have := hsub (84 - δ / 2) 84 (by linarith) (by linarith) (by norm_num)
      nlinarith
    · have hc' : 1 / 2 ≤ |1 - c| := by
        replace hc := not_le.mp hc
        have := abs_sub_abs_le_abs_sub 1 (1 - c)
        rw [sub_sub_cancel, abs_one] at this
        linarith
      have hlow : ∫ t in (84 + δ / 2)..(84 + 3 * δ / 4), (1 / 4 : ℝ) ≤
          ∫ t in (84 + δ / 2)..(84 + 3 * δ / 4), |f n t - g t| := by
        apply intervalIntegral.integral_mono_on (by linarith) intervalIntegrable_const
          (hsubint _ _ (by linarith) (by linarith) (by linarith))
        intro t htt
        have hMn : 1 / ((n : ℝ) + 1) ≤ 1 / ((M : ℝ) + 1) := by
          apply one_div_le_one_div_of_le (by positivity)
          have : (M : ℝ) ≤ n := by exact_mod_cast hnM
          linarith
        rw [h1 n t (by linarith [htt.1])]
        have := hnear t (by linarith [htt.1]) htt.2
        have := abs_sub_abs_le_abs_sub (1 - c) (1 - g t)
        rw [sub_sub_sub_cancel_left] at this
        linarith
      rw [intervalIntegral.integral_const, smul_eq_mul] at hlow
      have := hsub (84 + δ / 2) (84 + 3 * δ / 4) (by linarith) (by linarith) (by linarith)
      nlinarith

-- The error week: +60, +80, +40 at Tuesday 17:00-20:00 (hours 41-43), -20 at Saturday 11:00-15:00
-- (hours 131-134), zero in every other of the 168 hours.
-- Worst hour: 80 GBP/MWh.
example : ((List.range 168).map (fun h : ℕ =>
    (if h = 41 then (60 : ℤ) else if h = 42 then 80 else if h = 43 then 40
     else if 131 ≤ h ∧ h ≤ 134 then -20 else 0).natAbs)).foldr max 0 = 80 := by decide +kernel
-- Area norm: 260 GBP/MW.
example : ((List.range 168).map (fun h : ℕ =>
    (if h = 41 then (60 : ℤ) else if h = 42 then 80 else if h = 43 then 40
     else if 131 ≤ h ∧ h ≤ 134 then -20 else 0).natAbs)).sum = 260 := by decide +kernel
-- Sum of squares under the square-root norm: 13200, so the norm is √13200 = 114.891...
example : ((List.range 168).map (fun h : ℕ =>
    (if h = 41 then (60 : ℤ) else if h = 42 then 80 else if h = 43 then 40
     else if 131 ≤ h ∧ h ≤ 134 then -20 else 0) ^ 2)).sum = 13200 := by decide +kernel
-- Hand formulas for the three error sizes, and the area-norm triangle 260 ≤ 180 + 80 (equality).
example : max (max 60 80) (max 40 20) = (80 : ℕ) := by norm_num
example : (60 + 80 + 40 + 4 * 20 : ℕ) = 260 ∧ (60 + 80 + 40 : ℕ) + 4 * 20 = 180 + 80 := by norm_num
example : (60 ^ 2 + 80 ^ 2 + 40 ^ 2 + 4 * 20 ^ 2 : ℕ) = 13200 := by norm_num
-- The forecast bill and the actual bill for a steady 1 MW load.
example : 7 * 4 * (55 + 70 + 90 + 75 + 120 + 80 : ℕ) = 13720 := by norm_num
example : (13720 + 180 - 80 : ℕ) = 13820 := by norm_num
-- The sandwich 80 × 1 h ≤ 260 ≤ 168 h × 80 = 13440.
example : (80 : ℕ) ≤ 260 ∧ 260 ≤ 168 * 80 ∧ 168 * 80 = 13440 := by norm_num
-- What breaks: a flat 10 GBP/MWh error has range 0 but area 1680; dropping the square root,
-- doubling e takes the sum of squares from 13200 to 52800, not 26400.
example : (168 * 10 : ℕ) = 1680 := by norm_num
example : (2 * 60) ^ 2 + (2 * 80) ^ 2 + (2 * 40) ^ 2 + 4 * (2 * 20) ^ 2 = (52800 : ℕ) ∧
    (52800 : ℕ) ≠ 2 * 13200 := by norm_num
-- Ramps: ‖f_n - f_2n‖₁ = 50 (1/n - 1/(2n)) = 25/n, and 25/64 at n = 64.
example : (50 : ℚ) * (1 / 64 - 1 / 128) = 25 / 64 := by norm_num
-- The series of corrections: lengths 25, 25/2, ..., 25/2^6 total 50 (1 - 2^-7) after 7 terms.
example : ∑ k ∈ range 7, (25 : ℚ) / 2 ^ k = 50 * (1 - 1 / 2 ^ 7) := by
  norm_num [Finset.sum_range_succ]

#print axioms complete_iff_series_of_finite_length_converge
#print axioms continuous_curves_complete_under_worst_case_norm
#print axioms continuous_curves_incomplete_under_area_norm
