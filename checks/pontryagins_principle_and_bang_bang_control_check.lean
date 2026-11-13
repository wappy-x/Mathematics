-- Pontryagin's principle: a car whose acceleration is capped at a needs at least 2√(D/a) seconds to go D metres from rest to rest, the full-throttle-then-full-brake plan takes exactly that long, and a Hamiltonian linear in the control is maximised only at a limit.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue

/-- The tent bound (Step 5): a car that starts at rest at position 0, stops at rest at
position `D` at time `T`, and whose speed `v` changes by at most `a` per second
(acceleration capped at `a`), needs at least `T ≥ 2 √(D / a)`. For `D = 100`, `a = 2`
this is `T ≥ √200 ≈ 14.14 s`: nothing is faster than full throttle then full brake. -/
theorem parking_time_at_least_tent_bound (a D T : ℝ) (x v : ℝ → ℝ)
    (ha : 0 < a) (hT : 0 ≤ T)
    (hx : ContinuousOn x (Set.Icc 0 T))
    (hderiv : ∀ t ∈ Set.Ioo 0 T, HasDerivAt x (v t) t)
    (hcap : ∀ s ∈ Set.Icc 0 T, ∀ t ∈ Set.Icc 0 T, |v t - v s| ≤ a * |t - s|)
    (hv0 : v 0 = 0) (hvT : v T = 0) (hx0 : x 0 = 0) (hxT : x T = D) :
    2 * Real.sqrt (D / a) ≤ T := by
  set m := T / 2 with hm
  have hm0 : 0 ≤ m := by positivity
  have hmT : m ≤ T := by linarith
  -- first half: x t ≤ a t² / 2
  have h1 : x m ≤ a * m ^ 2 / 2 := by
    have hmono : MonotoneOn (fun t => a * t ^ 2 / 2 - x t) (Set.Icc 0 m) := by
      apply monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc 0 m)
        (f' := fun t => a * t - v t)
      · apply ContinuousOn.sub (by fun_prop)
        exact hx.mono (Set.Icc_subset_Icc le_rfl hmT)
      · intro t ht
        rw [interior_Icc] at ht ⊢
        have hd := hderiv t ⟨ht.1, lt_of_lt_of_le ht.2 hmT⟩
        have h2 : HasDerivAt (fun t : ℝ => a * t ^ 2 / 2) (a * t) t := by
          have := ((hasDerivAt_pow 2 t).const_mul a).div_const 2
          convert this using 1; push_cast; ring
        exact (h2.sub hd).hasDerivWithinAt
      · intro t ht
        rw [interior_Icc] at ht
        have := hcap 0 ⟨le_rfl, hT⟩ t ⟨ht.1.le, by linarith [ht.2]⟩
        rw [hv0, sub_zero, sub_zero, abs_of_pos ht.1] at this
        have := le_abs_self (v t)
        show 0 ≤ a * t - v t
        linarith
    have := hmono ⟨le_rfl, hm0⟩ ⟨hm0, le_rfl⟩ hm0
    simp only [hx0] at this
    linarith
  -- second half: x t + a (T - t)² / 2 is antitone
  have h2 : D ≤ x m + a * (T - m) ^ 2 / 2 := by
    have hanti : AntitoneOn (fun t => x t + a * (T - t) ^ 2 / 2) (Set.Icc m T) := by
      apply antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc m T)
        (f' := fun t => v t - a * (T - t))
      · apply ContinuousOn.add _ (by fun_prop)
        exact hx.mono (Set.Icc_subset_Icc hm0 le_rfl)
      · intro t ht
        rw [interior_Icc] at ht ⊢
        have hd := hderiv t ⟨lt_of_le_of_lt hm0 ht.1, ht.2⟩
        have h2 : HasDerivAt (fun t : ℝ => a * (T - t) ^ 2 / 2) (-(a * (T - t))) t := by
          have h3 : HasDerivAt (fun t : ℝ => T - t) (-1) t := by
            simpa using (hasDerivAt_id t).const_sub T
          have := ((h3.pow 2).const_mul a).div_const 2
          convert this using 1; push_cast; ring
        convert (hd.add h2).hasDerivWithinAt using 1
      · intro t ht
        rw [interior_Icc] at ht
        have := hcap T ⟨hT, le_rfl⟩ t ⟨by linarith [ht.1], ht.2.le⟩
        have habs : |t - T| = T - t := by
          rw [abs_sub_comm]; exact abs_of_pos (by linarith [ht.2])
        rw [hvT, sub_zero, habs] at this
        have := le_abs_self (v t)
        show v t - a * (T - t) ≤ 0
        linarith
    have := hanti ⟨le_rfl, hmT⟩ ⟨hmT, le_rfl⟩ hmT
    simp only [hxT, sub_self] at this
    linarith
  have hD : D ≤ a * T ^ 2 / 4 := by
    have : T - m = m := by rw [hm]; ring
    rw [this] at h2
    have : a * T ^ 2 / 4 = a * m ^ 2 / 2 + a * m ^ 2 / 2 := by rw [hm]; ring
    linarith
  have key : Real.sqrt (D / a) ≤ T / 2 := by
    rw [Real.sqrt_le_left (by positivity), div_le_iff₀ ha]
    nlinarith
  linarith

/-- The bang-bang plan reaches the bound: with `T = 2 √(D / a)`, the speed
`a · min(t, T − t)` (full throttle until `T / 2`, then full brake) changes by at most `a`
per second, starts and ends at rest, and covers exactly `D`. -/
theorem bang_bang_plan_parks_in_tent_time (a D T : ℝ) (ha : 0 < a) (hD : 0 ≤ D)
    (hT : T = 2 * Real.sqrt (D / a)) :
    (∀ s t : ℝ, |a * min t (T - t) - a * min s (T - s)| ≤ a * |t - s|) ∧
      a * min 0 (T - 0) = 0 ∧ a * min T (T - T) = 0 ∧
      ∫ t in (0 : ℝ)..T, a * min t (T - t) = D := by
  have hs : 0 ≤ Real.sqrt (D / a) := Real.sqrt_nonneg _
  have hT0 : 0 ≤ T := by rw [hT]; positivity
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro s t
    rw [← mul_sub, abs_mul, abs_of_pos ha]
    apply mul_le_mul_of_nonneg_left _ ha.le
    calc |min t (T - t) - min s (T - s)| ≤ max |t - s| |(T - t) - (T - s)| :=
          abs_min_sub_min_le_max _ _ _ _
      _ = |t - s| := by
          have : (T - t) - (T - s) = -(t - s) := by ring
          rw [this, abs_neg, max_self]
  · simp [hT0]
  · simp [hT0]
  · have hm0 : 0 ≤ T / 2 := by positivity
    have hint : ∀ u w : ℝ, IntervalIntegrable (fun t => a * min t (T - t)) MeasureTheory.volume u w :=
      fun u w => (by fun_prop : Continuous (fun t : ℝ => a * min t (T - t))).intervalIntegrable u w
    rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 (T / 2)) (hint (T / 2) T)]
    have e1 : ∫ t in (0 : ℝ)..T / 2, a * min t (T - t) = ∫ t in (0 : ℝ)..T / 2, a * t := by
      apply intervalIntegral.integral_congr
      intro t ht
      rw [Set.uIcc_of_le hm0] at ht
      simp only
      rw [min_eq_left (by linarith [ht.2])]
    have e2 : ∫ t in T / 2..T, a * min t (T - t) = ∫ t in T / 2..T, a * (T - t) := by
      apply intervalIntegral.integral_congr
      intro t ht
      rw [Set.uIcc_of_le (by linarith)] at ht
      simp only
      rw [min_eq_right (by linarith [ht.1])]
    rw [e1, e2, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      integral_id, intervalIntegral.integral_sub intervalIntegrable_const intervalIntegral.intervalIntegrable_id,
      integral_id, intervalIntegral.integral_const]
    simp only [smul_eq_mul]
    have hsq : Real.sqrt (D / a) ^ 2 = D / a := Real.sq_sqrt (by positivity)
    rw [hT]
    ring_nf
    rw [← div_eq_mul_inv, hsq]
    field_simp

/-- Bang-bang: when the control `u ∈ [−a, a]` enters the Hamiltonian in a straight line,
`H = c + σ u`, and the switching function `σ` is not zero, the controls that maximise `H`
are exactly the limit `+a` when `σ > 0` and `−a` when `σ < 0`. -/
theorem linear_hamiltonian_max_at_limit (c σ a u : ℝ) (ha : 0 < a) (hσ : σ ≠ 0)
    (hu : u ∈ Set.Icc (-a) a) :
    (∀ w ∈ Set.Icc (-a) a, c + σ * w ≤ c + σ * u) ↔ u = (if 0 < σ then a else -a) := by
  obtain ⟨hl, hr⟩ := hu
  constructor
  · intro h
    split_ifs with hpos
    · have := h a ⟨by linarith, le_rfl⟩
      have : a ≤ u := le_of_mul_le_mul_left (by linarith) hpos
      linarith
    · have hneg : σ < 0 := lt_of_le_of_ne (not_lt.mp hpos) hσ
      have := h (-a) ⟨le_rfl, by linarith⟩
      nlinarith
  · intro h w hw
    obtain ⟨wl, wr⟩ := hw
    split_ifs at h with hpos
    · subst h; nlinarith
    · have hneg : σ < 0 := lt_of_le_of_ne (not_lt.mp hpos) hσ
      subst h; nlinarith

-- Rest to rest, 100 m with a = 2: T² = 4D / a = 200, so T = √200.
example : (4 : ℚ) * 100 / 2 = 200 := by norm_num
-- H = 0 at the start, where the speed is 0: p₂(0) × 2 − 1 = 0 with p₂(0) = 1/2.
example : (1 / 2 : ℚ) * 2 - 1 = 0 := by norm_num
-- Half throttle (a = 1) for 20 s: the tent covers 1 × 20² / 4 = 100 m.
example : (1 : ℚ) * 20 ^ 2 / 4 = 100 := by norm_num
-- Top speed capped at 10 m/s: 5 s up, 5 s down, 5 s cruising the remaining 50 m: 15 s.
example : (10 : ℚ) / 2 * 2 + (100 - 10 * 10 / 2) / 10 = 15 := by norm_num
-- Switch late at 8 s: 64 m at 16 m/s, then 64 m of braking, stopping at 128 m.
example : (2 : ℚ) * 8 ^ 2 / 2 + (2 * 8) ^ 2 / (2 * 2) = 128 := by norm_num

#print axioms parking_time_at_least_tent_bound
#print axioms bang_bang_plan_parks_in_tent_time
#print axioms linear_hamiltonian_max_at_limit
