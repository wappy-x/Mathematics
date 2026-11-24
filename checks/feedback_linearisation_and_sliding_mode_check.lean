-- Nonlinear design: if the distance s from the sliding surface obeys s s' ≤ -η|s|, then s reaches zero within |s₀|/η, the gain 0.2|Γ| + 1.2η meets that condition for every mass error in ±20%, and exact cancellation leaves (1 - r)(g/l) sin θ - r k (θ + ω).
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Basic.Real.Sign
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Abs

open Set

/-- The reaching-time bound. Let `s t` be the distance from the sliding surface at time `t`,
continuous from time 0 on, with rate `s' t` wherever it is not yet zero. If the reaching
condition `s s' ≤ -η |s|` holds with `η > 0`, then `s` reaches zero no later than `|s 0| / η`,
and before it does, its size falls at least at speed `η`: `|s t| ≤ |s 0| - η t`. -/
theorem reaching_time_le_abs_s0_div_eta (s s' : ℝ → ℝ) (η : ℝ) (hη : 0 < η)
    (hcont : ContinuousOn s (Ici 0))
    (hderiv : ∀ t, 0 < t → s t ≠ 0 → HasDerivAt s (s' t) t)
    (hreach : ∀ t, 0 < t → s t ≠ 0 → s t * s' t ≤ -η * |s t|) :
    (∃ t, 0 ≤ t ∧ t ≤ |s 0| / η ∧ s t = 0) ∧
      ∀ t, 0 ≤ t → (∀ u ∈ Icc 0 t, s u ≠ 0) → |s t| ≤ |s 0| - η * t := by
  have key : ∀ t, 0 ≤ t → (∀ u ∈ Icc 0 t, s u ≠ 0) → |s t| ≤ |s 0| - η * t := by
    intro t ht hne
    rcases ht.eq_or_lt with h0 | htpos
    · subst h0; simp
    · have hfc : ContinuousOn (fun u => |s u|) (Icc 0 t) :=
        continuous_abs.comp_continuousOn (hcont.mono Icc_subset_Ici_self)
      have hff' : ∀ x ∈ Ioo 0 t, HasDerivAt (fun u => |s u|)
          (if 0 < s x then s' x else -s' x) x := by
        intro x hx
        have hsx : s x ≠ 0 := hne x (Ioo_subset_Icc_self hx)
        have hd := hderiv x hx.1 hsx
        rcases hsx.lt_or_gt with hneg | hpos
        · have h1 := (hasDerivAt_abs_neg hneg).comp x hd
          have e : (if 0 < s x then s' x else -s' x) = -1 * s' x := by
            simp [not_lt.mpr hneg.le]
          rw [e]
          exact h1
        · have h1 := (hasDerivAt_abs_pos hpos).comp x hd
          have e : (if 0 < s x then s' x else -s' x) = 1 * s' x := by
            simp [hpos]
          rw [e]
          exact h1
      obtain ⟨c, hc, hceq⟩ := exists_hasDerivAt_eq_slope (fun u => |s u|) _ htpos hfc hff'
      have hsc : s c ≠ 0 := hne c (Ioo_subset_Icc_self hc)
      have hr := hreach c hc.1 hsc
      have hbound : (if 0 < s c then s' c else -s' c) ≤ -η := by
        rcases hsc.lt_or_gt with hneg | hpos
        · have e : (if 0 < s c then s' c else -s' c) = -s' c := by
            simp [not_lt.mpr hneg.le]
          rw [e]
          rw [abs_of_neg hneg] at hr
          nlinarith
        · have e : (if 0 < s c then s' c else -s' c) = s' c := by
            simp [hpos]
          rw [e]
          rw [abs_of_pos hpos] at hr
          nlinarith
      rw [hceq, sub_zero, div_le_iff₀ htpos] at hbound
      linarith
  refine ⟨?_, key⟩
  by_contra hcon
  push Not at hcon
  have hT : 0 ≤ |s 0| / η := div_nonneg (abs_nonneg _) hη.le
  have hne : ∀ u ∈ Icc 0 (|s 0| / η), s u ≠ 0 := fun u hu => hcon u hu.1 hu.2
  have h1 := key _ hT hne
  rw [mul_div_cancel₀ _ hη.ne', sub_self] at h1
  exact hcon _ hT le_rfl (abs_nonpos_iff.mp h1)

/-- The switching gain sized to ±20% in mass. With `r = M̂ / M` anywhere from `5/6` to `5/4`,
the rate of `s` under the sliding law, `s' = (1 - r) Γ - r K sgn s` with
`K = 0.2 |Γ| + 1.2 η`, meets the reaching condition `s s' ≤ -η |s|`. -/
theorem sliding_gain_meets_reaching_condition (r Γ η s : ℝ)
    (hr₁ : 5 / 6 ≤ r) (hr₂ : r ≤ 5 / 4) (hη : 0 < η) :
    s * ((1 - r) * Γ - r * (|Γ| / 5 + 6 / 5 * η) * Real.sign s) ≤ -η * |s| := by
  have hΓ1 : (1 - r) * Γ ≤ r / 5 * |Γ| := by
    rcases le_or_gt 0 Γ with hg | hg
    · rw [abs_of_nonneg hg]; nlinarith
    · rw [abs_of_neg hg]; nlinarith
  have hΓ2 : -((1 - r) * Γ) ≤ r / 5 * |Γ| := by
    rcases le_or_gt 0 Γ with hg | hg
    · rw [abs_of_nonneg hg]; nlinarith
    · rw [abs_of_neg hg]; nlinarith
  have hη' : η ≤ 6 / 5 * r * η := by nlinarith
  rcases lt_trichotomy s 0 with hs | hs | hs
  · rw [Real.sign_of_neg hs, abs_of_neg hs]
    nlinarith
  · subst hs; simp
  · rw [Real.sign_of_pos hs, abs_of_pos hs]
    nlinarith

/-- Feedback linearisation, Step 1. With true mass `M`, assumed mass `M̂` and `r = M̂ / M`,
putting the cancelling push `F = (M̂ l / cos θ) ((g/l) sin θ + k θ + k ω)` into
`θ'' = (g/l) sin θ - cos θ F / (M l)` leaves `(1 - r)(g/l) sin θ - r k (θ + ω)`,
when the pole is not horizontal. With `r = 1` this is `-k θ - k ω`. -/
theorem feedback_linearisation_leftover (g l M Mhat k θ ω : ℝ)
    (hl : 0 < l) (hM : 0 < M) (hcos : Real.cos θ ≠ 0) :
    g / l * Real.sin θ
        - Real.cos θ / (M * l) * (Mhat * l / Real.cos θ * (g / l * Real.sin θ + k * θ + k * ω))
      = (1 - Mhat / M) * (g / l * Real.sin θ) - Mhat / M * k * (θ + ω) := by
  field_simp
  ring

-- The card's exact worked numbers.
-- Start on the surface: s₀ = 0 + λ θ₀ = 2 × 1/2 = 1 rad/s; bound |s₀|/η = 1/2 s.
example : (0 : ℚ) + 2 * (1 / 2) = 1 := by norm_num
example : |(1 : ℚ)| / 2 = 1 / 2 := by norm_num
-- The mass guess: r = 2/2.4 = 5/6 and r = 2/1.6 = 5/4.
example : (2 : ℚ) / (12 / 5) = 5 / 6 := by norm_num
example : (2 : ℚ) / (8 / 5) = 5 / 4 := by norm_num
-- The gain at the heavy end: 6/5 - 1 = 1/5 (the 0.2) and 1/r = 6/5 (the 1.2).
example : (1 : ℚ) / (5 / 6) - 1 = 1 / 5 ∧ (1 : ℚ) / (5 / 6) = 6 / 5 := by norm_num
-- Cancellation loses upright when r < 16/(16 + 4) = 4/5, that is M > 2 × 5/4 = 5/2 kg.
example : (16 : ℚ) / (16 + 4) = 4 / 5 := by norm_num
example : (2 : ℚ) * (16 + 4) / 16 = 5 / 2 := by norm_num
-- Boundary layer Φ = 1/10: reached by (1 - 1/10)/2 = 9/20 s; lean held within Φ/λ = 1/20 rad.
example : ((1 : ℚ) - 1 / 10) / 2 = 9 / 20 := by norm_num
example : ((1 : ℚ) / 10) / 2 = 1 / 20 := by norm_num

#print axioms reaching_time_le_abs_s0_div_eta
#print axioms sliding_gain_meets_reaching_condition
#print axioms feedback_linearisation_leftover
