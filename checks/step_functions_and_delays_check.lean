-- Step functions: restarting a signal a hours late multiplies its Laplace transform by e^(-as), multiplying it by e^(ct) turns F(s) into F(s - c), and the switched room T = 20 + 10(1 - e^(-0.5(t - 2)))u(t - 2) solves T' = -0.5(T - 20 - 10u(t - 2)) with T(0) = 20.
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Tactic.NormNum

open MeasureTheory Set Real

/-- The card's Laplace transform of a real signal `f`, read at a real `s`:
`F(s) = ∫₀^∞ e^(−st) f(t) dt`. -/
noncomputable def laplace (f : ℝ → ℝ) (s : ℝ) : ℝ :=
  ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * f t

/-- The unit step `u`: a switch that reads 0 before time zero and 1 from time zero on. -/
noncomputable def unitStep (t : ℝ) : ℝ := if 0 ≤ t then 1 else 0

/-- Helper: a signal below `M e^(αt)` in size has an absolutely convergent transform integral
at every `s > α`. -/
theorem laplace_integrand_integrableOn (f : ℝ → ℝ) (M α s : ℝ)
    (hmeas : AEStronglyMeasurable f (volume.restrict (Ioi 0)))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → |f t| ≤ M * Real.exp (α * t))
    (hs : α < s) :
    IntegrableOn (fun t : ℝ => Real.exp (-(s * t)) * f t) (Ioi 0) := by
  have hb : α - s < 0 := by linarith
  have hint : IntegrableOn (fun t : ℝ => M * Real.exp ((α - s) * t)) (Ioi 0) :=
    (integrableOn_exp_mul_Ioi hb 0).const_mul M
  refine Integrable.mono' hint ?_ ?_
  · exact (Real.continuous_exp.comp (continuous_const.mul continuous_id).neg).aestronglyMeasurable.mul
      hmeas
  · refine (ae_restrict_iff' measurableSet_Ioi).mpr (Filter.Eventually.of_forall fun t ht => ?_)
    have h1 := hgrowth t (le_of_lt ht)
    rw [Real.norm_eq_abs, abs_mul, abs_of_pos (Real.exp_pos _)]
    calc Real.exp (-(s * t)) * |f t| ≤ Real.exp (-(s * t)) * (M * Real.exp (α * t)) :=
          mul_le_mul_of_nonneg_left h1 (Real.exp_pos _).le
      _ = M * Real.exp ((α - s) * t) := by
          rw [mul_left_comm, ← Real.exp_add]; congr 2; ring

#print axioms laplace_integrand_integrableOn

/-- The delay rule: let the signal `f` be measurable from time zero on and stay below
`M e^(αt)` in size there. Restart it `a ≥ 0` hours late, as `f(t − a) u(t − a)`. Then at every
`s > α` the delayed signal's transform integral converges and equals `e^(−as) F(s)`. -/
theorem laplace_delay (f : ℝ → ℝ) (M α a s : ℝ)
    (hmeas : AEStronglyMeasurable f (volume.restrict (Ioi 0)))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → |f t| ≤ M * Real.exp (α * t))
    (ha : 0 ≤ a) (hs : α < s) :
    IntegrableOn (fun t : ℝ => Real.exp (-(s * t)) * (f (t - a) * unitStep (t - a))) (Ioi 0) ∧
      laplace (fun t => f (t - a) * unitStep (t - a)) s = Real.exp (-(a * s)) * laplace f s := by
  set h : ℝ → ℝ := (Ioi (0 : ℝ)).indicator (fun x => Real.exp (-(s * x)) * f x) with hh
  have hint : Integrable h :=
    (integrable_indicator_iff measurableSet_Ioi).mpr
      (laplace_integrand_integrableOn f M α s hmeas hgrowth (by linarith))
  set g : ℝ → ℝ := fun t => Real.exp (-(s * t)) * (f (t - a) * unitStep (t - a)) with hg
  have hae : (Ioi (0 : ℝ)).indicator g =ᵐ[volume] fun t => Real.exp (-(a * s)) * h (t - a) := by
    have hnull : ∀ᵐ t ∂(volume : Measure ℝ), t ≠ a := by
      rw [ae_iff]; simp
    filter_upwards [hnull] with t ht
    rcases lt_or_gt_of_ne ht with hlt | hgt
    · have h1 : ¬ (0 ≤ t - a) := by linarith
      have h2 : t - a ∉ Ioi (0 : ℝ) := by simp only [mem_Ioi]; linarith
      have h4 : unitStep (t - a) = 0 := if_neg h1
      simp [hh, hg, h4, h2, Set.indicator]
    · have h1 : 0 ≤ t - a := by linarith
      have h2 : t - a ∈ Ioi (0 : ℝ) := by simp only [mem_Ioi]; linarith
      have h3 : t ∈ Ioi (0 : ℝ) := by simp only [mem_Ioi]; linarith
      rw [Set.indicator_of_mem h3, hh, Set.indicator_of_mem h2]
      simp only [hg, unitStep, if_pos h1, mul_one]
      rw [← mul_assoc, ← Real.exp_add]; congr 2; ring
  have hint2 : Integrable (fun t => Real.exp (-(a * s)) * h (t - a)) :=
    (hint.comp_sub_right a).const_mul _
  refine ⟨?_, ?_⟩
  · exact (integrable_indicator_iff measurableSet_Ioi).mp (hint2.congr hae.symm)
  · unfold laplace
    rw [← integral_indicator measurableSet_Ioi, integral_congr_ae hae, integral_const_mul,
      integral_sub_right_eq_self (fun t => h t) a, hh, integral_indicator measurableSet_Ioi]

/-- The s-shift rule: for the same kind of signal `f`, below `M e^(αt)` in size from time zero
on, multiplying by `e^(ct)` gives a signal whose transform integral converges at every `s` with
`s − c > α`, and its transform there is `F(s − c)`. -/
theorem laplace_exp_mul (f : ℝ → ℝ) (M α c s : ℝ)
    (hmeas : AEStronglyMeasurable f (volume.restrict (Ioi 0)))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → |f t| ≤ M * Real.exp (α * t))
    (hs : α < s - c) :
    IntegrableOn (fun t : ℝ => Real.exp (-(s * t)) * (Real.exp (c * t) * f t)) (Ioi 0) ∧
      laplace (fun t => Real.exp (c * t) * f t) s = laplace f (s - c) := by
  have heq : (fun t : ℝ => Real.exp (-(s * t)) * (Real.exp (c * t) * f t)) =
      fun t => Real.exp (-((s - c) * t)) * f t := by
    funext t; rw [← mul_assoc, ← Real.exp_add]; congr 2; ring
  refine ⟨?_, ?_⟩
  · rw [heq]; exact laplace_integrand_integrableOn f M α (s - c) hmeas hgrowth hs
  · unfold laplace; rw [heq]

/-- The room the card solves: `T(t) = 20 + 10(1 − e^(−0.5(t − 2))) u(t − 2)` starts at 20 C,
has no jumps, and away from the switch at 2 h obeys the rate law
`T' = −0.5 (T − 20 − 10 u(t − 2))`. -/
theorem switched_room_solves :
    let T : ℝ → ℝ := fun t => 20 + 10 * (1 - Real.exp (-(1 / 2) * (t - 2))) * unitStep (t - 2)
    T 0 = 20 ∧ Continuous T ∧
      ∀ t : ℝ, t ≠ 2 → HasDerivAt T (-(1 / 2) * (T t - 20 - 10 * unitStep (t - 2))) t := by
  intro T
  have hT : T = fun t => 20 + 10 * (1 - Real.exp (-(1 / 2) * max (t - 2) 0)) := by
    funext t
    simp only [T, unitStep]
    by_cases h : 0 ≤ t - 2
    · rw [if_pos h, max_eq_left h, mul_one]
    · rw [if_neg h, max_eq_right (by linarith)]; simp
  refine ⟨?_, ?_, ?_⟩
  · simp [T, unitStep]
  · rw [hT]; fun_prop
  · intro t ht
    rcases lt_or_gt_of_ne ht with hlt | hgt
    · have hev : T =ᶠ[nhds t] fun _ => (20 : ℝ) := by
        filter_upwards [Iio_mem_nhds hlt] with x hx
        have : ¬ (0 ≤ x - 2) := by simp only [mem_Iio] at hx; linarith
        have h4 : unitStep (x - 2) = 0 := if_neg this
        simp [T, h4]
      have : ¬ (0 ≤ t - 2) := by linarith
      have hval : -(1 / 2) * (T t - 20 - 10 * unitStep (t - 2)) = 0 := by
        have h4 : unitStep (t - 2) = 0 := if_neg this
        simp [T, h4]
      rw [hval]
      exact (hasDerivAt_const t (20 : ℝ)).congr_of_eventuallyEq hev
    · let S : ℝ → ℝ := fun x => 20 + 10 * (1 - Real.exp (-(1 / 2) * (x - 2)))
      have hev : T =ᶠ[nhds t] S := by
        filter_upwards [Ioi_mem_nhds hgt] with x hx
        have : 0 ≤ x - 2 := by simp only [mem_Ioi] at hx; linarith
        have h4 : unitStep (x - 2) = 1 := if_pos this
        simp [T, S, h4]
      have : 0 ≤ t - 2 := by linarith
      have hval : -(1 / 2) * (T t - 20 - 10 * unitStep (t - 2)) =
          10 * ((1 / 2) * Real.exp (-(1 / 2) * (t - 2))) := by
        simp only [T, unitStep, if_pos this]; ring
      rw [hval]
      have hd : HasDerivAt S (10 * ((1 / 2) * Real.exp (-(1 / 2) * (t - 2)))) t := by
        have h1 : HasDerivAt (fun x : ℝ => -(1 / 2) * (x - 2)) (-(1 / 2) * 1) t :=
          ((hasDerivAt_id t).sub_const 2).const_mul _
        have h2 := h1.exp
        have h3 := ((h2.const_sub 1).const_mul 10).const_add 20
        convert h3 using 1; ring
      exact hd.congr_of_eventuallyEq hev

-- Worked numbers, exact.
-- The target 20 + 10u(t - 2) reads 20 before 2 h and 30 after.
example : (20 : ℤ) + 10 * 0 = 20 ∧ (20 : ℤ) + 10 * 1 = 30 := by norm_num
-- The forcing: the 10 C jump in target times the rate 0.5 is 5.
example : (10 : ℚ) * (1 / 2) = 5 := by norm_num
-- The time constant: 1/0.5 = 2 hours.
example : (1 : ℚ) / (1 / 2) = 2 := by norm_num
-- Partial fractions 5/(s(s + 0.5)) = 10/s − 10/(s + 0.5), checked at s = 1 and s = 2.
example : (5 : ℚ) / (1 * (1 + 1 / 2)) = 10 / 1 - 10 / (1 + 1 / 2) := by norm_num
example : (5 : ℚ) / (2 * (2 + 1 / 2)) = 10 / 2 - 10 / (2 + 1 / 2) := by norm_num
-- X(1) = 5e^(-2)/1.5: the rational factor 5/1.5 is 10/3.
example : (5 : ℚ) / (1 * (1 + 1 / 2)) = 10 / 3 := by norm_num
-- The s-shift check: 1/(s + 0.5)^2 at s = 1 is 4/9 = 0.444444...
example : (1 : ℚ) / (1 + 1 / 2) ^ 2 = 4 / 9 := by norm_num

#print axioms laplace_delay
#print axioms laplace_exp_mul
#print axioms switched_room_solves
