-- Optimisation: a positive slope on an interval makes a function rise and a negative one makes it fall, a continuous function on a closed interval takes its lowest and highest values at an end or where its slope is zero or missing, and a closed can of fixed volume uses least metal exactly when its height equals its diameter.
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Topology.Order.Compact
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Inv

open Set

/-- The sign test. Let f be a real function on an interval D with no gaps. Suppose f has no jump
anywhere on D (it is continuous there, ends included) and has a slope f'(x) at every inside point x.
If the slope is positive at every inside point, f rises on D: x₁ < x₂ in D gives f(x₁) < f(x₂).
If the slope is negative at every inside point, f falls on D: x₁ < x₂ in D gives f(x₁) > f(x₂). -/
theorem sign_of_slope_gives_rise_or_fall (D : Set ℝ) (hD : D.OrdConnected) (f f' : ℝ → ℝ)
    (hcont : ContinuousOn f D) (hslope : ∀ x ∈ interior D, HasDerivAt f (f' x) x) :
    ((∀ x ∈ interior D, 0 < f' x) → StrictMonoOn f D) ∧
    ((∀ x ∈ interior D, f' x < 0) → StrictAntiOn f D) := by
  have hcv : Convex ℝ D := hD.convex
  constructor
  · intro hpos
    exact strictMonoOn_of_deriv_pos hcv hcont (fun x hx => by
      rw [(hslope x hx).deriv]; exact hpos x hx)
  · intro hneg
    exact strictAntiOn_of_deriv_neg hcv hcont (fun x hx => by
      rw [(hslope x hx).deriv]; exact hneg x hx)

/-- The candidates on a closed interval. A continuous function f on a closed interval from a to b
reaches a lowest value and a highest value there, and each is reached at a candidate: an end a or b,
a point where f has no slope, or a point where the slope is zero. -/
theorem extremes_on_closed_interval_are_candidates (f : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hf : ContinuousOn f (Icc a b)) :
    (∃ c ∈ Icc a b, IsMinOn f (Icc a b) c ∧
      (c = a ∨ c = b ∨ ¬ DifferentiableAt ℝ f c ∨ deriv f c = 0)) ∧
    (∃ d ∈ Icc a b, IsMaxOn f (Icc a b) d ∧
      (d = a ∨ d = b ∨ ¬ DifferentiableAt ℝ f d ∨ deriv f d = 0)) := by
  have hne : (Icc a b).Nonempty := nonempty_Icc.2 hab
  constructor
  · obtain ⟨c, hc, hmin⟩ := isCompact_Icc.exists_isMinOn hne hf
    refine ⟨c, hc, hmin, ?_⟩
    by_cases hca : c = a
    · exact Or.inl hca
    by_cases hcb : c = b
    · exact Or.inr (Or.inl hcb)
    have hlt1 : a < c := lt_of_le_of_ne hc.1 (Ne.symm hca)
    have hlt2 : c < b := lt_of_le_of_ne hc.2 hcb
    exact Or.inr (Or.inr (Or.inr (hmin.isLocalMin (Icc_mem_nhds hlt1 hlt2)).deriv_eq_zero))
  · obtain ⟨c, hc, hmax⟩ := isCompact_Icc.exists_isMaxOn hne hf
    refine ⟨c, hc, hmax, ?_⟩
    by_cases hca : c = a
    · exact Or.inl hca
    by_cases hcb : c = b
    · exact Or.inr (Or.inl hcb)
    have hlt1 : a < c := lt_of_le_of_ne hc.1 (Ne.symm hca)
    have hlt2 : c < b := lt_of_le_of_ne hc.2 hcb
    exact Or.inr (Or.inr (Or.inr (hmax.isLocalMax (Icc_mem_nhds hlt1 hlt2)).deriv_eq_zero))

/-- The best can. A closed cylinder of radius r > 0 holding the fixed volume V > 0 has height
h = V / (π r²) and uses metal A(r) = 2π r² + 2π r h (two lids and the wall). A radius r gives the
least metal among all positive radii exactly when the height equals the diameter, h = 2r. -/
theorem can_least_metal_iff_height_eq_diameter (V : ℝ) (hV : 0 < V) (r : ℝ) (hr : 0 < r) :
    IsMinOn (fun s : ℝ => 2 * Real.pi * s ^ 2 + 2 * Real.pi * s * (V / (Real.pi * s ^ 2)))
      (Ioi 0) r ↔ V / (Real.pi * r ^ 2) = 2 * r := by
  have hpi : 0 < Real.pi := Real.pi_pos
  have hr2 : 0 < Real.pi * r ^ 2 := by positivity
  rw [div_eq_iff hr2.ne']
  constructor
  · intro hmin
    have hloc := hmin.isLocalMin (Ioi_mem_nhds hr)
    have hd : HasDerivAt (fun s : ℝ => 2 * Real.pi * s ^ 2 + 2 * Real.pi * s * (V / (Real.pi * s ^ 2)))
        (2 * Real.pi * (2 * r) + (2 * Real.pi * (V / (Real.pi * r ^ 2)) +
          2 * Real.pi * r * (-(V * (Real.pi * (2 * r))) / (Real.pi * r ^ 2) ^ 2))) r := by
      have h1 : HasDerivAt (fun s : ℝ => s ^ 2) (2 * r) r := by
        simpa using hasDerivAt_pow 2 r
      have h2 : HasDerivAt (fun s : ℝ => Real.pi * s ^ 2) (Real.pi * (2 * r)) r := h1.const_mul _
      have h3 : HasDerivAt (fun s : ℝ => V / (Real.pi * s ^ 2))
          (-(V * (Real.pi * (2 * r))) / (Real.pi * r ^ 2) ^ 2) r := by
        have := (hasDerivAt_const (𝕜 := ℝ) r V).div h2 hr2.ne'
        convert this using 1
        ring
      have h4 : HasDerivAt (fun s : ℝ => 2 * Real.pi * s) (2 * Real.pi) r := by
        simpa using (hasDerivAt_id r).const_mul (2 * Real.pi)
      have h5 := h4.mul h3
      exact (h1.const_mul (2 * Real.pi)).add h5
    have h0 := hloc.hasDerivAt_eq_zero hd
    field_simp at h0
    nlinarith [h0, hpi, hr]
  · intro hVeq s hs
    simp only [mem_Ioi] at hs
    have hs2 : 0 < Real.pi * s ^ 2 := by positivity
    rw [hVeq]
    have hk : 2 * Real.pi * s * (2 * r * (Real.pi * r ^ 2) / (Real.pi * s ^ 2))
        = 4 * Real.pi * r ^ 3 / s := by
      field_simp
      ring
    have hk2 : 2 * Real.pi * s ^ 2 + 4 * Real.pi * r ^ 3 / s
        - (2 * Real.pi * r ^ 2 + 2 * Real.pi * r * (2 * r))
        = 2 * Real.pi * (s - r) ^ 2 * (s + 2 * r) / s := by
      field_simp
      ring
    simp only [Set.mem_ofPred_eq]
    have hk3 : 2 * r * (Real.pi * r ^ 2) / (Real.pi * r ^ 2) = 2 * r := by
      field_simp
    rw [hk, hk3, ← sub_nonneg, hk2]
    positivity

-- The 330 ml can: 2V = 660 and 4V = 1320, the numbers in A'(r) = 4πr - 660/r² and A''(r) = 4π + 1320/r³.
example : (2 * 330 : ℕ) = 660 ∧ (4 * 330 : ℕ) = 1320 := by decide
-- A gap in the domain: f(x) = -1/x has slope 1/x² = 1 at -1 and at 1, yet f(-1) = 1 > f(1) = -1.
example : (1 / (-1) ^ 2 : ℚ) = 1 ∧ (1 / 1 ^ 2 : ℚ) = 1 ∧ -1 / (-1 : ℚ) = 1 ∧ -1 / (1 : ℚ) = -1 ∧
    -1 / (1 : ℚ) < -1 / (-1 : ℚ) := by norm_num
-- Flat is not a turn: x³ has slope 3x² = 0 at 0, yet (-1/10)³ = -1/1000 < 0 < 1/1000 = (1/10)³.
example : (3 * 0 ^ 2 : ℚ) = 0 ∧ (-1 / 10 : ℚ) ^ 3 = -1 / 1000 ∧ (1 / 10 : ℚ) ^ 3 = 1 / 1000 ∧
    (-1 / 10 : ℚ) ^ 3 < 0 ∧ (0 : ℚ) < (1 / 10) ^ 3 := by norm_num

#print axioms sign_of_slope_gives_rise_or_fall
#print axioms extremes_on_closed_interval_are_candidates
#print axioms can_least_metal_iff_height_eq_diameter
