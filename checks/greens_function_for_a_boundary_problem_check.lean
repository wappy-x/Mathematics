-- Green's function: for every load f continuous on [0, 1], the tent sum y(x) = ∫₀¹ min(x, s)(1 − max(x, s)) f(s) ds solves −y'' = f with y(0) = y(1) = 0, it is the only solution, and for the even load f = 1 it is x(1 − x)/2.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Set

theorem green_aux_cont (f : ℝ → ℝ) (hf : ContinuousOn f (Icc 0 1)) (x : ℝ) :
    ContinuousOn (fun s => min x s * (1 - max x s) * f s) (Icc 0 1) :=
  ((continuous_const.min continuous_id).mul
    (continuous_const.sub (continuous_const.max continuous_id))).continuousOn.mul hf

theorem green_split (f : ℝ → ℝ) (hf : ContinuousOn f (Icc 0 1)) (x : ℝ)
    (hx : x ∈ Icc (0 : ℝ) 1) :
    ∫ s in (0 : ℝ)..1, min x s * (1 - max x s) * f s
      = (1 - x) * (∫ s in (0 : ℝ)..x, s * f s) + x * ∫ s in x..1, (1 - s) * f s := by
  have hsub1 : uIcc (0 : ℝ) x ⊆ Icc 0 1 := by
    rw [uIcc_of_le hx.1]; exact Icc_subset_Icc le_rfl hx.2
  have hsub2 : uIcc x 1 ⊆ Icc 0 1 := by
    rw [uIcc_of_le hx.2]; exact Icc_subset_Icc hx.1 le_rfl
  have hc := green_aux_cont f hf x
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := x)
    ((hc.mono hsub1).intervalIntegrable) ((hc.mono hsub2).intervalIntegrable)]
  rw [← intervalIntegral.integral_const_mul, ← intervalIntegral.integral_const_mul]
  congr 1
  · apply intervalIntegral.integral_congr
    intro s hs
    rw [uIcc_of_le hx.1] at hs
    simp only
    rw [min_eq_right hs.2, max_eq_left hs.2]; ring
  · apply intervalIntegral.integral_congr
    intro s hs
    rw [uIcc_of_le hx.2] at hs
    simp only
    rw [min_eq_left hs.1, max_eq_right hs.1]; ring

theorem green_hasDeriv (f : ℝ → ℝ) (hf : ContinuousOn f (Icc 0 1)) (x : ℝ)
    (hx : x ∈ Ioo (0 : ℝ) 1) :
    HasDerivAt (fun x => (1 - x) * (∫ s in (0 : ℝ)..x, s * f s) + x * ∫ s in x..1, (1 - s) * f s)
      (-(∫ s in (0 : ℝ)..x, s * f s) + ∫ s in x..1, (1 - s) * f s) x ∧
    HasDerivAt (fun x => -(∫ s in (0 : ℝ)..x, s * f s) + ∫ s in x..1, (1 - s) * f s)
      (-f x) x := by
  have hIcc : Icc (0 : ℝ) 1 ∈ nhds x := Icc_mem_nhds hx.1 hx.2
  have h1c : ContinuousOn (fun s => s * f s) (Icc 0 1) := continuousOn_id.mul hf
  have h2c : ContinuousOn (fun s => (1 - s) * f s) (Icc 0 1) :=
    (continuousOn_const.sub continuousOn_id).mul hf
  have hA : HasDerivAt (fun x => ∫ s in (0 : ℝ)..x, s * f s) (x * f x) x := by
    apply intervalIntegral.integral_hasDerivAt_right
    · apply (h1c.mono _).intervalIntegrable
      rw [uIcc_of_le hx.1.le]; exact Icc_subset_Icc le_rfl hx.2.le
    · exact (h1c.mono Ioo_subset_Icc_self).stronglyMeasurableAtFilter isOpen_Ioo x hx
    · exact h1c.continuousAt hIcc
  have hB : HasDerivAt (fun x => ∫ s in x..1, (1 - s) * f s) (-((1 - x) * f x)) x := by
    apply intervalIntegral.integral_hasDerivAt_left
    · apply (h2c.mono _).intervalIntegrable
      rw [uIcc_of_le hx.2.le]; exact Icc_subset_Icc hx.1.le le_rfl
    · exact (h2c.mono Ioo_subset_Icc_self).stronglyMeasurableAtFilter isOpen_Ioo x hx
    · exact h2c.continuousAt hIcc
  constructor
  · have := (((hasDerivAt_id' x).const_sub 1).mul hA).add ((hasDerivAt_id' x).mul hB)
    convert this using 1; ring
  · have := hA.neg.add hB
    convert this using 1; ring

#print axioms green_aux_cont
#print axioms green_split
#print axioms green_hasDeriv

/-- The sag under any load is the sum of tents. Take a load f that is continuous on the shelf
[0, 1]. Add up the tent G(x, s) = min(x, s)(1 − max(x, s)), weighted by the load f(s) at each
place s: y(x) = ∫₀¹ G(x, s) f(s) ds. This y is zero at both brackets, and at every point
strictly between them it has a slope y' whose own slope is −f(x), so −y'' = f. -/
theorem green_sum_solves_boundary_problem (f : ℝ → ℝ) (hf : ContinuousOn f (Icc 0 1)) :
    let y : ℝ → ℝ := fun x => ∫ s in (0 : ℝ)..1, min x s * (1 - max x s) * f s
    y 0 = 0 ∧ y 1 = 0 ∧
      ∃ y' : ℝ → ℝ, ∀ x ∈ Ioo (0 : ℝ) 1, HasDerivAt y (y' x) x ∧ HasDerivAt y' (-f x) x := by
  intro y
  refine ⟨?_, ?_, ?_⟩
  · show ∫ s in (0 : ℝ)..1, min 0 s * (1 - max 0 s) * f s = 0
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ))]
    · simp
    · intro s hs
      rw [uIcc_of_le zero_le_one] at hs
      simp [min_eq_left hs.1]
  · show ∫ s in (0 : ℝ)..1, min 1 s * (1 - max 1 s) * f s = 0
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ))]
    · simp
    · intro s hs
      rw [uIcc_of_le zero_le_one] at hs
      simp [max_eq_left hs.2]
  · refine ⟨fun x => -(∫ s in (0 : ℝ)..x, s * f s) + ∫ s in x..1, (1 - s) * f s,
      fun x hx => ?_⟩
    obtain ⟨h1, h2⟩ := green_hasDeriv f hf x hx
    refine ⟨h1.congr_of_eventuallyEq ?_, h2⟩
    filter_upwards [isOpen_Ioo.mem_nhds hx] with z hz
    exact green_split f hf z (Ioo_subset_Icc_self hz)

/-- Nothing else solves it. Any sag y that is continuous on the shelf [0, 1], zero at both
brackets, and satisfies −y'' = f at every point strictly between them, is the tent sum
∫₀¹ min(x, s)(1 − max(x, s)) f(s) ds at every point of the shelf. -/
theorem boundary_problem_solution_is_green_sum (f y y' : ℝ → ℝ) (hf : ContinuousOn f (Icc 0 1))
    (hy : ContinuousOn y (Icc 0 1)) (h0 : y 0 = 0) (h1 : y 1 = 0)
    (hd : ∀ x ∈ Ioo (0 : ℝ) 1, HasDerivAt y (y' x) x ∧ HasDerivAt y' (-f x) x) :
    ∀ x ∈ Icc (0 : ℝ) 1, y x = ∫ s in (0 : ℝ)..1, min x s * (1 - max x s) * f s := by
  intro x hx
  rw [green_split f hf x hx]
  set Y : ℝ → ℝ := fun x =>
    (1 - x) * (∫ s in (0 : ℝ)..x, s * f s) + x * ∫ s in x..1, (1 - s) * f s with hYdef
  set Y' : ℝ → ℝ := fun x => -(∫ s in (0 : ℝ)..x, s * f s) + ∫ s in x..1, (1 - s) * f s
    with hY'def
  have h1c : ContinuousOn (fun s => s * f s) (Icc 0 1) := continuousOn_id.mul hf
  have h2c : ContinuousOn (fun s => (1 - s) * f s) (Icc 0 1) :=
    (continuousOn_const.sub continuousOn_id).mul hf
  have hYc : ContinuousOn Y (Icc 0 1) := by
    have hA := intervalIntegral.continuousOn_primitive_interval (μ := MeasureTheory.volume)
      (a := 0) (b := 1) (f := fun s => s * f s)
      (by rw [uIcc_of_le zero_le_one]; exact h1c.integrableOn_Icc)
    have hB := intervalIntegral.continuousOn_primitive_interval_left (μ := MeasureTheory.volume)
      (a := 0) (b := 1) (f := fun s => (1 - s) * f s)
      (by rw [uIcc_of_le zero_le_one]; exact h2c.integrableOn_Icc)
    rw [uIcc_of_le zero_le_one] at hA hB
    exact ((continuousOn_const.sub continuousOn_id).mul hA).add (continuousOn_id.mul hB)
  set z : ℝ → ℝ := fun x => y x - Y x with hzdef
  set z' : ℝ → ℝ := fun x => y' x - Y' x with hz'def
  have hzc : ContinuousOn z (Icc 0 1) := hy.sub hYc
  have hzd : ∀ t ∈ Ioo (0 : ℝ) 1, HasDerivAt z (z' t) t := fun t ht =>
    (hd t ht).1.sub (green_hasDeriv f hf t ht).1
  have hzd2 : ∀ t ∈ Ioo (0 : ℝ) 1, HasDerivAt z' 0 t := fun t ht => by
    have h := (hd t ht).2.sub (green_hasDeriv f hf t ht).2
    rw [sub_self] at h
    exact h
  have hz0 : z 0 = 0 := by simp [z, Y, h0]
  have hz1 : z 1 = 0 := by simp [z, Y, h1]
  have hconst : ∀ a ∈ Ioo (0 : ℝ) 1, ∀ b ∈ Ioo (0 : ℝ) 1, a < b → z' a = z' b := by
    intro a ha b hb hab
    obtain ⟨c, hc, hc'⟩ := exists_hasDerivAt_eq_slope z' (fun _ => (0 : ℝ)) hab
      (fun t ht => (hzd2 t ⟨ha.1.trans_le ht.1, ht.2.trans_lt hb.2⟩).continuousAt.continuousWithinAt)
      (fun t ht => hzd2 t ⟨ha.1.trans ht.1, ht.2.trans hb.2⟩)
    have hne : b - a ≠ 0 := sub_ne_zero.2 hab.ne'
    have h0' : (z' b - z' a) / (b - a) = 0 := hc'.symm
    rcases div_eq_zero_iff.1 h0' with h | h
    · linarith
    · exact absurd h hne
  obtain ⟨c, hc, hc'⟩ := exists_hasDerivAt_eq_slope z z' zero_lt_one hzc hzd
  rw [hz0, hz1] at hc'
  have hc0 : z' c = 0 := by simpa using hc'
  have hall : ∀ t ∈ Ioo (0 : ℝ) 1, z' t = 0 := by
    intro t ht
    rcases lt_trichotomy t c with h | h | h
    · rw [hconst t ht c hc h, hc0]
    · rw [h, hc0]
    · rw [← hconst c hc t ht h, hc0]
  have hzx : z x = 0 := by
    rcases hx.1.eq_or_lt with h | h
    · rw [← h]; exact hz0
    · obtain ⟨d, hd', hd''⟩ := exists_hasDerivAt_eq_slope z z' h
        (hzc.mono (Icc_subset_Icc le_rfl hx.2)) (fun t ht => hzd t ⟨ht.1, ht.2.trans_le hx.2⟩)
      rw [hall d ⟨hd'.1, hd'.2.trans_le hx.2⟩, hz0] at hd''
      have hq : (z x - 0) / (x - 0) = 0 := hd''.symm
      rcases div_eq_zero_iff.1 hq with h' | h'
      · linarith
      · linarith
  have : y x - Y x = 0 := hzx
  linarith

/-- The books: an even load f = 1 along the shelf. Adding up the tents gives the smooth curve
x(1 − x)/2 at every point x of the shelf. -/
theorem green_sum_of_even_load (x : ℝ) (hx : x ∈ Icc (0 : ℝ) 1) :
    ∫ s in (0 : ℝ)..1, min x s * (1 - max x s) = x * (1 - x) / 2 := by
  have h := green_split (fun _ => (1 : ℝ)) continuousOn_const x hx
  simp only [mul_one] at h
  rw [h, intervalIntegral.integral_sub intervalIntegrable_const intervalIntegral.intervalIntegrable_id]
  simp [integral_id]
  ring

-- The shelf: tension 98.1 N (10 kg at 9.81 N per kg), the 5 kg bag 49.05 N, so P = 1/2.
example : (10 : ℚ) * (981 / 100) = 981 / 10 ∧ (5 : ℚ) * (981 / 100) = 4905 / 100 := by norm_num
example : ((4905 : ℚ) / 100) / (981 / 10) = 1 / 2 := by norm_num
-- Step 3 at s = 0.3: A = 0.7 and B = 0.3 meet both conditions, equal heights and a slope drop of 1.
example : (7 / 10 : ℚ) * (3 / 10) = 3 / 10 * (1 - 3 / 10) ∧ -(3 / 10 : ℚ) - 7 / 10 = -1 := by norm_num
-- The unit tent's peak G(0.3, 0.3) = 0.21, and the bag's peak 0.5 × 0.21 = 0.105 m.
example : min (3 / 10 : ℚ) (3 / 10) * (1 - max (3 / 10 : ℚ) (3 / 10)) = 21 / 100 := by norm_num
example : (1 / 2 : ℚ) * (21 / 100) = 105 / 1000 := by norm_num
-- Slopes beside the bag, 0.35 and −0.15, and the slope drop −0.5 = −P.
example : (1 / 2 : ℚ) * (7 / 10) = 35 / 100 ∧ -(1 / 2 : ℚ) * (3 / 10) = -15 / 100 ∧
    (-15 / 100 : ℚ) - 35 / 100 = -(1 / 2) := by norm_num
-- Books, middle of the shelf: (1 − 0.5) × 0.5²/2 + 0.5 × 0.5²/2 = 0.125 m, the same as x(1 − x)/2.
example : (1 - 1 / 2 : ℚ) * (1 / 2) ^ 2 / 2 + 1 / 2 * (1 - 1 / 2) ^ 2 / 2 = 125 / 1000 ∧
    (1 / 2 : ℚ) * (1 - 1 / 2) / 2 = 125 / 1000 := by norm_num
-- Reciprocity: a bag at 0.3 sags x = 0.7 by 0.5 × G(0.7, 0.3) = 0.045 m, and the bag at 0.7 sags x = 0.3 by the same.
example : (1 / 2 : ℚ) * (min (7 / 10 : ℚ) (3 / 10) * (1 - max (7 / 10 : ℚ) (3 / 10))) = 45 / 1000 ∧
    (1 / 2 : ℚ) * (min (3 / 10 : ℚ) (7 / 10) * (1 - max (3 / 10 : ℚ) (7 / 10))) = 45 / 1000 := by
  norm_num
-- The mistakes: no corner leaves the far end at 0.5 × 0.7 × 1 = 0.35 m; loads on the left only give
-- 0.0625 m at the middle; a slope rise of 1 lifts the bag point to −0.105 m.
example : (1 / 2 : ℚ) * (7 / 10) * 1 = 35 / 100 := by norm_num
example : (1 - 1 / 2 : ℚ) * (1 / 2) ^ 2 / 2 = 625 / 10000 := by norm_num
example : (1 / 2 : ℚ) * (-(7 / 10) * (3 / 10)) = -105 / 1000 := by norm_num

#print axioms green_sum_solves_boundary_problem
#print axioms boundary_problem_solution_is_green_sum
#print axioms green_sum_of_even_load
