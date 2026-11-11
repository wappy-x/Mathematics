-- Inverse trig: for any value u from -1 to 1, the angles whose sine is u are exactly arcsin u and its mirror pi - arcsin u plus whole turns, the angles whose cosine is u are plus or minus arccos u plus whole turns, and a value outside -1 to 1 is never a sine.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Complex

open Real

/-- Every angle with the same sine. For a value u from -1 to 1, an angle θ has sine u exactly
when θ is the button's angle arcsin u plus a whole number of turns, or its mirror image,
half a turn minus it, plus a whole number of turns. -/
theorem sin_eq_iff_arcsin_or_mirror_plus_turns (u : ℝ) (hu₁ : -1 ≤ u) (hu₂ : u ≤ 1) (θ : ℝ) :
    sin θ = u ↔
      ∃ k : ℤ, θ = arcsin u + 2 * π * k ∨ θ = π - arcsin u + 2 * π * k := by
  have hs : sin (arcsin u) = u := sin_arcsin hu₁ hu₂
  constructor
  · intro h
    have h2 : sin (arcsin u) = sin θ := by rw [hs, h]
    obtain ⟨k, hk | hk⟩ := Real.sin_eq_sin_iff.mp h2
    · exact ⟨k, Or.inl (by rw [hk]; ring)⟩
    · exact ⟨k, Or.inr (by rw [hk]; ring)⟩
  · rintro ⟨k, hk | hk⟩
    · rw [← hs]
      exact (Real.sin_eq_sin_iff.mpr ⟨k, Or.inl (by rw [hk]; ring)⟩).symm
    · rw [← hs]
      exact (Real.sin_eq_sin_iff.mpr ⟨k, Or.inr (by rw [hk]; ring)⟩).symm

/-- The cosine version. For a value u from -1 to 1, an angle θ has cosine u exactly when θ is
arccos u or minus arccos u (the mirror across the horizontal axis), plus a whole number of
turns. -/
theorem cos_eq_iff_plus_or_minus_arccos_plus_turns (u : ℝ) (hu₁ : -1 ≤ u) (hu₂ : u ≤ 1)
    (θ : ℝ) :
    cos θ = u ↔ ∃ k : ℤ, θ = arccos u + 2 * π * k ∨ θ = -arccos u + 2 * π * k := by
  have hc : cos (arccos u) = u := cos_arccos hu₁ hu₂
  constructor
  · intro h
    have h2 : cos (arccos u) = cos θ := by rw [hc, h]
    obtain ⟨k, hk | hk⟩ := Real.cos_eq_cos_iff.mp h2
    · exact ⟨k, Or.inl (by rw [hk]; ring)⟩
    · exact ⟨k, Or.inr (by rw [hk]; ring)⟩
  · rintro ⟨k, hk | hk⟩
    · rw [← hc]
      exact (Real.cos_eq_cos_iff.mpr ⟨k, Or.inl (by rw [hk]; ring)⟩).symm
    · rw [← hc]
      exact (Real.cos_eq_cos_iff.mpr ⟨k, Or.inr (by rw [hk]; ring)⟩).symm

/-- Sine needs a value from -1 to 1: outside it, no angle at all has that sine. -/
theorem no_angle_has_sine_outside_minus_one_to_one (u : ℝ) (hu : u < -1 ∨ 1 < u) (θ : ℝ) :
    sin θ ≠ u := by
  intro h
  have h1 := neg_one_le_sin θ
  have h2 := sin_le_one θ
  rcases hu with hu | hu <;> linarith

-- At exactly 1 the two families merge: the button's angle and its mirror are the same angle.
example : π - arcsin 1 = arcsin 1 := by rw [arcsin_one]; ring

-- The other order works only inside the window: the falling crossing's angle, the mirror
-- π - arcsin (1/3), comes back from arcsin as the rising one, arcsin (1/3).
example : arcsin (sin (π - arcsin (1 / 3))) = arcsin (1 / 3) := by
  rw [sin_pi_sub, sin_arcsin (by norm_num) (by norm_num)]

-- ... and the mirror really is a different angle from the one arcsin returns.
example : π - arcsin (1 / 3) ≠ arcsin (1 / 3) := by
  intro h
  have : arcsin (1 / 3) = π / 2 := by linarith
  rw [arcsin_eq_pi_div_two] at this
  norm_num at this

#print axioms sin_eq_iff_arcsin_or_mirror_plus_turns
#print axioms cos_eq_iff_plus_or_minus_arccos_plus_turns
#print axioms no_angle_has_sine_outside_minus_one_to_one
