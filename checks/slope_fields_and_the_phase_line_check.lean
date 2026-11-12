-- Slope fields and the phase line: for a clock-free rate law v' = f(v) with f Lipschitz, a solution that starts between two rests stays between them, moves one way, and settles on the rest its arrow points to; a rest where f has negative slope has arrows pointing in (positive slope: pointing out); and every skydiver speed under v' = 9.8 - 0.2 v closes in on 49 m/s.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Topology.EMetricSpace.Lipschitz
import Mathlib.Tactic.NormNum

open Filter Topology Set

/-- Backward uniqueness at a rest: a solution that reaches a rest `c` at some time `s ≥ 0`
was already at `c` at time `0`. -/
theorem sf_back_unique (f : ℝ → ℝ) (K : NNReal) (hf : LipschitzWith K f) (c : ℝ) (hc : f c = 0)
    (v : ℝ → ℝ) (hv : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt v (f (v t)) (Ici 0) t)
    (s : ℝ) (hs : 0 ≤ s) (hvs : v s = c) : v 0 = c := by
  have hd : ∀ t, 0 < t → HasDerivAt v (f (v t)) t := fun t ht =>
    (hv t (le_of_lt ht)).hasDerivAt (Ici_mem_nhds ht)
  have hcont : ContinuousOn v (Ici 0) := fun t ht => (hv t ht).continuousWithinAt
  have hneg : LipschitzWith K (fun x => -f x) :=
    LipschitzWith.of_dist_le_mul fun x y => by
      rw [dist_neg_neg]; exact hf.dist_le_mul x y
  set u : ℝ → ℝ := fun r => v (s - r) with hu_def
  have hu_cont : ContinuousOn u (Icc 0 s) := by
    refine hcont.comp (continuous_const.sub continuous_id).continuousOn ?_
    intro r hr; simp only [mem_Ici]; linarith [hr.2]
  have hu' : ∀ r ∈ Ico 0 s, HasDerivWithinAt u (-f (u r)) (Ici r) r := by
    intro r hr
    have := (hd (s - r) (by linarith [hr.2])).comp_const_sub s r
    exact this.hasDerivWithinAt
  have hg' : ∀ r ∈ Ico 0 s, HasDerivWithinAt (fun _ => c) (-f c) (Ici r) r := by
    intro r _; rw [hc, neg_zero]; exact hasDerivWithinAt_const _ _ _
  have key := dist_le_of_trajectories_ODE (v := fun _ x => -f x) (K := K) (δ := 0)
    (fun _ => hneg) hu_cont hu' continuousOn_const hg'
    (by simp [u, hvs]) s (right_mem_Icc.2 hs)
  have : dist (u s) c = 0 := le_antisymm (by simpa using key) dist_nonneg
  simpa [u] using dist_eq_zero.1 this

/-- A solution starting strictly between two rests stays strictly between them. -/
theorem sf_stays_between (f : ℝ → ℝ) (K : NNReal) (hf : LipschitzWith K f)
    (a b : ℝ) (ha : f a = 0) (hb : f b = 0)
    (v : ℝ → ℝ) (hv : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt v (f (v t)) (Ici 0) t)
    (hv0 : v 0 ∈ Ioo a b) : ∀ t ∈ Ici (0 : ℝ), v t ∈ Ioo a b := by
  have hcont : ContinuousOn v (Ici 0) := fun t ht => (hv t ht).continuousWithinAt
  intro t ht
  have ht0 : (0 : ℝ) ≤ t := ht
  have hc : ContinuousOn v (Icc 0 t) := hcont.mono Icc_subset_Ici_self
  constructor
  · by_contra h
    push Not at h
    obtain ⟨s, hs, hvs⟩ := intermediate_value_Icc' ht0 hc ⟨h, le_of_lt hv0.1⟩
    have := sf_back_unique f K hf a ha v hv s hs.1 hvs
    linarith [hv0.1]
  · by_contra h
    push Not at h
    obtain ⟨s, hs, hvs⟩ := intermediate_value_Icc ht0 hc ⟨le_of_lt hv0.2, h⟩
    have := sf_back_unique f K hf b hb v hv s hs.1 hvs
    linarith [hv0.2]

/-- With no rest between `a` and `b`, the rate keeps one sign there. -/
theorem sf_sign_const (f : ℝ → ℝ) (hc : Continuous f) (a b : ℝ)
    (hno : ∀ x ∈ Ioo a b, f x ≠ 0) (x y : ℝ) (hx : x ∈ Ioo a b) (hy : y ∈ Ioo a b)
    (hfx : 0 < f x) : 0 < f y := by
  by_contra h
  push Not at h
  have hy' : f y < 0 := lt_of_le_of_ne h (hno y hy)
  obtain ⟨z, hz, hfz⟩ := intermediate_value_uIcc (hc.continuousOn (s := uIcc x y))
    (show (0 : ℝ) ∈ uIcc (f x) (f y) from mem_uIcc.2 (Or.inr ⟨le_of_lt hy', le_of_lt hfx⟩))
  exact hno z ((ordConnected_Ioo).uIcc_subset hx hy hz) hfz

/-- Rising case: a solution inside `(a, b)` where the rate is positive rises strictly and
tends to `b`. -/
theorem sf_rising (f : ℝ → ℝ) (hc : Continuous f) (a b : ℝ)
    (hpos : ∀ x ∈ Ioo a b, 0 < f x)
    (v : ℝ → ℝ) (hv : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt v (f (v t)) (Ici 0) t)
    (hin : ∀ t ∈ Ici (0 : ℝ), v t ∈ Ioo a b) :
    StrictMonoOn v (Ici 0) ∧ Tendsto v atTop (𝓝 b) := by
  have hd : ∀ t, 0 < t → HasDerivAt v (f (v t)) t := fun t ht =>
    (hv t (le_of_lt ht)).hasDerivAt (Ici_mem_nhds ht)
  have hcont : ContinuousOn v (Ici 0) := fun t ht => (hv t ht).continuousWithinAt
  have hmono : StrictMonoOn v (Ici 0) := by
    refine strictMonoOn_of_deriv_pos (convex_Ici 0) hcont fun x hx => ?_
    rw [interior_Ici] at hx
    rw [(hd x hx).deriv]
    exact hpos _ (hin x (mem_Ici.2 (le_of_lt hx)))
  refine ⟨hmono, ?_⟩
  rw [tendsto_order]
  constructor
  · intro a' ha'
    set c := max a' (v 0) with hc_def
    have hcb : c < b := max_lt ha' (hin 0 self_mem_Ici).2
    by_cases hex : ∃ T ∈ Ici (0 : ℝ), c < v T
    · obtain ⟨T, hT, hcT⟩ := hex
      refine eventually_atTop.2 ⟨T, fun t ht => ?_⟩
      have hT0 : (0 : ℝ) ≤ T := hT
      have : v T ≤ v t := hmono.monotoneOn hT (show (0:ℝ) ≤ t by linarith) ht
      exact lt_of_le_of_lt (le_max_left _ _) (lt_of_lt_of_le hcT this)
    · exfalso
      push Not at hex
      have hv0c : v 0 ≤ c := le_max_right _ _
      obtain ⟨x0, hx0, hmin⟩ := isCompact_Icc.exists_isMinOn (nonempty_Icc.2 hv0c)
        hc.continuousOn
      have hx0in : x0 ∈ Ioo a b :=
        ⟨lt_of_lt_of_le (hin 0 self_mem_Ici).1 hx0.1, lt_of_le_of_lt hx0.2 hcb⟩
      set m := f x0 with hm_def
      have hm : 0 < m := hpos x0 hx0in
      have hrange : ∀ t ∈ Ici (0 : ℝ), v t ∈ Icc (v 0) c := fun t ht =>
        ⟨hmono.monotoneOn self_mem_Ici ht ht, hex t ht⟩
      have hh : MonotoneOn (fun t => v t - m * t) (Ici 0) := by
        have hd2 : ∀ t, 0 < t → HasDerivAt (fun t => v t - m * t) (f (v t) - m) t := by
          intro t ht
          exact ((hd t ht).sub ((hasDerivAt_id' t).const_mul m)).congr_deriv (by ring)
        refine monotoneOn_of_deriv_nonneg (convex_Ici 0)
          (hcont.sub (continuous_const.mul continuous_id).continuousOn) ?_ ?_
        · rw [interior_Ici]
          exact fun t ht => (hd2 t ht).differentiableAt.differentiableWithinAt
        · rw [interior_Ici]
          intro t ht
          rw [(hd2 t ht).deriv]
          have := hmin (hrange t (mem_Ici.2 (le_of_lt ht)))
          simp only [mem_ofPred_eq] at this
          linarith
      set T := (c - v 0) / m + 1 with hT_def
      have hT0 : 0 ≤ T := by
        have : 0 ≤ (c - v 0) / m := div_nonneg (by linarith) (le_of_lt hm)
        linarith
      have h1 := hh self_mem_Ici hT0 hT0
      simp only [mul_zero, sub_zero] at h1
      have h2 : v T ≤ c := hex T hT0
      have h3 : m * T = c - v 0 + m := by
        rw [hT_def, mul_add, mul_div_cancel₀ _ (ne_of_gt hm), mul_one]
      linarith
  · intro b' hb'
    exact eventually_atTop.2 ⟨0, fun t ht => (hin t ht).2.trans hb'⟩

#print axioms sf_back_unique
#print axioms sf_stays_between
#print axioms sf_sign_const
#print axioms sf_rising

/-- Between rests, the motion is one way and settles on a rest. Take a rate law `v' = f(v)`
that ignores the clock, with `f` Lipschitz (bounded slope, so solutions are unique and `f` is
continuous). Let `a < b` be two rests (`f a = 0`, `f b = 0`) with no rest between them. Then any
solution `v` on `[0, ∞)` that starts strictly between `a` and `b` stays strictly between them
for all time, never crossing a rest; if its starting arrow points up (`f (v 0) > 0`) it rises
strictly and tends to `b`, and if it points down (`f (v 0) < 0`) it falls strictly and tends
to `a`. -/
theorem solution_between_rests_moves_one_way_and_settles
    (f : ℝ → ℝ) (K : NNReal) (hf : LipschitzWith K f)
    (a b : ℝ) (hab : a < b) (ha : f a = 0) (hb : f b = 0)
    (hno : ∀ x ∈ Ioo a b, f x ≠ 0)
    (v : ℝ → ℝ) (hv : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt v (f (v t)) (Ici 0) t)
    (hv0 : v 0 ∈ Ioo a b) :
    (∀ t ∈ Ici (0 : ℝ), v t ∈ Ioo a b) ∧
    (0 < f (v 0) → StrictMonoOn v (Ici 0) ∧ Tendsto v atTop (𝓝 b)) ∧
    (f (v 0) < 0 → StrictAntiOn v (Ici 0) ∧ Tendsto v atTop (𝓝 a)) := by
  have hc : Continuous f := hf.continuous
  have hin := sf_stays_between f K hf a b ha hb v hv hv0
  refine ⟨hin, ?_, ?_⟩
  · intro hpos0
    exact sf_rising f hc a b (fun x hx => sf_sign_const f hc a b hno (v 0) x hv0 hx hpos0)
      v hv hin
  · intro hneg0
    have hneg : ∀ x ∈ Ioo a b, f x < 0 := by
      intro x hx
      rcases lt_or_gt_of_ne (hno x hx) with h | h
      · exact h
      · exact absurd (sf_sign_const f hc a b hno x (v 0) hx hv0 h) (not_lt.2 (le_of_lt hneg0))
    set g : ℝ → ℝ := fun x => -f (-x) with hg_def
    have hgc : Continuous g := (hc.comp continuous_neg).neg
    have hgpos : ∀ x ∈ Ioo (-b) (-a), 0 < g x := by
      intro x hx
      have : -x ∈ Ioo a b := ⟨by linarith [hx.2], by linarith [hx.1]⟩
      simp only [g]; linarith [hneg (-x) this]
    have hw : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt (fun t => -v t) (g (-v t)) (Ici 0) t := by
      intro t ht
      exact (hv t ht).neg.congr_deriv (by simp [g])
    have hwin : ∀ t ∈ Ici (0 : ℝ), -v t ∈ Ioo (-b) (-a) := fun t ht =>
      ⟨by linarith [(hin t ht).2], by linarith [(hin t ht).1]⟩
    obtain ⟨hm, ht⟩ := sf_rising g hgc (-b) (-a) hgpos (fun t => -v t) hw hwin
    refine ⟨fun x hx y hy hxy => ?_, ?_⟩
    · have := hm hx hy hxy
      simp only at this
      linarith
    · simpa using ht.neg

/-- The slope test. At a rest `v*` (`f v* = 0`) where the rate law has slope `d`: if `d < 0`,
the arrows point in from both sides (`f > 0` just below `v*`, `f < 0` just above), so the rest
is stable; if `d > 0`, the arrows point away on both sides, so the rest is unstable. -/
theorem slope_test_for_rests (f : ℝ → ℝ) (vstar d : ℝ) (hrest : f vstar = 0)
    (hd : HasDerivAt f d vstar) :
    (d < 0 → ∃ δ > 0, (∀ x ∈ Ioo (vstar - δ) vstar, 0 < f x) ∧
                       (∀ x ∈ Ioo vstar (vstar + δ), f x < 0)) ∧
    (0 < d → ∃ δ > 0, (∀ x ∈ Ioo (vstar - δ) vstar, f x < 0) ∧
                       (∀ x ∈ Ioo vstar (vstar + δ), 0 < f x)) := by
  rw [hasDerivAt_iff_tendsto_slope] at hd
  have hδ : ∀ {p : ℝ → Prop}, (∀ᶠ x in 𝓝[≠] vstar, p x) →
      ∃ δ > 0, ∀ x, dist x vstar < δ → x ≠ vstar → p x := by
    intro p hp
    rw [eventually_nhdsWithin_iff, Metric.eventually_nhds_iff] at hp
    obtain ⟨δ, hδ, h⟩ := hp
    exact ⟨δ, hδ, fun x hx hne => h hx hne⟩
  have hsl : ∀ x, slope f vstar x = f x / (x - vstar) := by
    intro x; rw [slope_def_field, hrest, sub_zero]
  constructor
  · intro hdn
    obtain ⟨δ, hδpos, h⟩ := hδ (hd.eventually (eventually_lt_nhds hdn))
    refine ⟨δ, hδpos, fun x hx => ?_, fun x hx => ?_⟩
    · have hne : x ≠ vstar := ne_of_lt hx.2
      have hdist : dist x vstar < δ := by
        rw [Real.dist_eq, abs_sub_lt_iff]; constructor <;> linarith [hx.1, hx.2]
      have := h x hdist hne
      rw [hsl] at this
      have hneg : x - vstar < 0 := by linarith [hx.2]
      rcases div_neg_iff.1 this with h | h <;> linarith [h.1, h.2]
    · have hne : x ≠ vstar := ne_of_gt hx.1
      have hdist : dist x vstar < δ := by
        rw [Real.dist_eq, abs_sub_lt_iff]; constructor <;> linarith [hx.1, hx.2]
      have := h x hdist hne
      rw [hsl] at this
      have hpos : 0 < x - vstar := by linarith [hx.1]
      rcases div_neg_iff.1 this with h | h <;> linarith [h.1, h.2]
  · intro hdp
    obtain ⟨δ, hδpos, h⟩ := hδ (hd.eventually (eventually_gt_nhds hdp))
    refine ⟨δ, hδpos, fun x hx => ?_, fun x hx => ?_⟩
    · have hne : x ≠ vstar := ne_of_lt hx.2
      have hdist : dist x vstar < δ := by
        rw [Real.dist_eq, abs_sub_lt_iff]; constructor <;> linarith [hx.1, hx.2]
      have := h x hdist hne
      rw [hsl] at this
      have hneg : x - vstar < 0 := by linarith [hx.2]
      rcases div_pos_iff.1 this with h | h <;> linarith [h.1, h.2]
    · have hne : x ≠ vstar := ne_of_gt hx.1
      have hdist : dist x vstar < δ := by
        rw [Real.dist_eq, abs_sub_lt_iff]; constructor <;> linarith [hx.1, hx.2]
      have := h x hdist hne
      rw [hsl] at this
      have hpos : 0 < x - vstar := by linarith [hx.1]
      rcases div_pos_iff.1 this with h | h <;> linarith [h.1, h.2]

/-- The skydiver. Every solution on `[0, ∞)` of `v' = 9.8 - 0.2 v` (written `49/5 - v/5`) is
`v(t) = 49 + (v₀ - 49) e^(-0.2 t)`, so every diver, whatever the starting speed, is pushed
toward the terminal speed of 49 m/s. -/
theorem skydiver_speed_tends_to_terminal_velocity
    (v : ℝ → ℝ) (hv : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt v (49 / 5 - v t / 5) (Ici 0) t) :
    (∀ t ∈ Ici (0 : ℝ), v t = 49 + (v 0 - 49) * Real.exp (-(t / 5))) ∧
    Tendsto v atTop (𝓝 49) := by
  set w : ℝ → ℝ := fun t => (v t - 49) * Real.exp (t / 5) with hw_def
  have hcont : ContinuousOn v (Ici 0) := fun t ht => (hv t ht).continuousWithinAt
  have hwd : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt w 0 (Ici 0) t := by
    intro t ht
    have he : HasDerivAt (fun x : ℝ => Real.exp (x / 5)) (Real.exp (t / 5) * (1 / 5)) t :=
      ((hasDerivAt_id t).div_const 5).exp
    have := ((hv t ht).sub_const 49).mul he.hasDerivWithinAt
    refine this.congr_deriv ?_
    ring
  have hform : ∀ t ∈ Ici (0 : ℝ), v t = 49 + (v 0 - 49) * Real.exp (-(t / 5)) := by
    intro t ht
    have ht0 : (0 : ℝ) ≤ t := ht
    have hwc : ContinuousOn w (Icc 0 t) :=
      ((hcont.sub continuousOn_const).mul
        ((continuous_id.div_const 5).rexp.continuousOn)).mono Icc_subset_Ici_self
    have key := constant_of_has_deriv_right_zero hwc
      (fun x hx => (hwd x hx.1).mono (Ici_subset_Ici.2 hx.1)) t (right_mem_Icc.2 ht0)
    simp only [w, zero_div, Real.exp_zero, mul_one] at key
    have hexp : Real.exp (t / 5) * Real.exp (-(t / 5)) = 1 := by
      rw [← Real.exp_add, add_neg_cancel, Real.exp_zero]
    have : v t - 49 = (v t - 49) * Real.exp (t / 5) * Real.exp (-(t / 5)) := by
      rw [mul_assoc, hexp, mul_one]
    rw [key] at this
    linarith
  refine ⟨hform, ?_⟩
  have hlim : Tendsto (fun t : ℝ => 49 + (v 0 - 49) * Real.exp (-(t / 5))) atTop
      (𝓝 (49 + (v 0 - 49) * 0)) :=
    tendsto_const_nhds.add (tendsto_const_nhds.mul
      (Real.tendsto_exp_neg_atTop_nhds_zero.comp (tendsto_id.atTop_div_const (by norm_num))))
  rw [mul_zero, add_zero] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_ge_atTop 0] with t ht
  exact (hform t ht).symm

/-! The card's worked numbers, with 9.8 = 49/5 and 0.2 = 1/5, checked exactly. -/

-- The rest: 9.8 - 0.2 × 49 = 0.
example : (49 / 5 : ℚ) - 1 / 5 * 49 = 0 := by norm_num

-- Sign below: the rate at 0 is 9.8 (arrow up). Sign above: the rate at 70 is -4.2 (arrow down).
example : (49 / 5 : ℚ) - 1 / 5 * 0 = 49 / 5 ∧ (0 : ℚ) < 49 / 5 := by norm_num
example : (49 / 5 : ℚ) - 1 / 5 * 70 = -21 / 5 ∧ (-21 / 5 : ℚ) < 0 := by norm_num

-- A row of ticks: the rate at 45 is 0.8; at 5 it is 8.8; at 75 it is -5.2.
example : (49 / 5 : ℚ) - 1 / 5 * 45 = 4 / 5 := by norm_num
example : (49 / 5 : ℚ) - 1 / 5 * 5 = 44 / 5 ∧ (49 / 5 : ℚ) - 1 / 5 * 75 = -26 / 5 := by norm_num

-- 90% of 49 is 44.1.
example : (9 / 10 : ℚ) * 49 = 441 / 10 := by norm_num

-- The parachute: drag 1.96 per s gives the new rest 9.8 ÷ 1.96 = 5 m/s.
example : (49 / 5 : ℚ) / (49 / 25) = 5 := by norm_num

-- The coffee T' = -0.1 (T - 20) rests at 20.
example : -(1 / 10 : ℚ) * (20 - 20) = 0 := by norm_num

-- Mistake 2: Euler steps of 10 s from 70 go 70, 28, 70: each step multiplies the gap by -1.
example : (70 : ℚ) + 10 * (49 / 5 - 1 / 5 * 70) = 28 ∧
    (28 : ℚ) + 10 * (49 / 5 - 1 / 5 * 28) = 70 := by norm_num

-- Try changing: one step of 5 s from 70 lands on 49 at once (the gap is multiplied by 0).
example : (70 : ℚ) + 5 * (49 / 5 - 1 / 5 * 70) = 49 ∧ (1 : ℚ) - 1 / 5 * 5 = 0 := by norm_num

-- Too coarse: steps of 12 s multiply the gap by -1.4, giving 19.6 after one step.
example : (1 : ℚ) - 1 / 5 * 12 = -7 / 5 ∧ (70 : ℚ) + 12 * (49 / 5 - 1 / 5 * 70) = 98 / 5 := by
  norm_num

-- Halve the drag: with 0.1 per s the rest is 98.
example : (49 / 5 : ℚ) - 1 / 10 * 98 = 0 := by norm_num

-- Mistake 3: with the drag sign flipped, v' = 9.8 + 0.2 v rests at -49 with slope +0.2.
example : (49 / 5 : ℚ) + 1 / 5 * (-49) = 0 := by norm_num

#print axioms solution_between_rests_moves_one_way_and_settles
#print axioms slope_test_for_rests
#print axioms skydiver_speed_tends_to_terminal_velocity
