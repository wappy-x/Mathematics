-- Bishop-Gromov: if the ratio of two positive shell densities never rises, the ratio of their running totals never rises either, and on the globe of radius R the ball's area divided by the flat area π r² never rises up to the antipode and never exceeds 1.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum

open Real MeasureTheory

namespace BishopGromov

/-! Mathlib has no Riemannian volume or Ricci curvature, so the theorem on a complete space is
not stated here. This file states exactly the card's averaging step (Step 4), which turns a
falling ratio of shell densities into a falling ratio of ball volumes, and the theorem's
content on the 6,371 km globe of radius `R` against the flat plane (`k = 0`, `n = 2`), where the
ball of radius `r ≤ πR` has area `2πR²(1 − cos(r/R))` and the flat disc has area `πr²`. -/

/-- **The ratio of running totals never rises.** Take two positive functions `u₁` and `u₂` of the
distance `s > 0` (the shell sizes of the ball and of the model ball) whose ratio `u₁/u₂` never
rises as `s` grows. Then the ratio of their running totals, `∫₀^r u₁ / ∫₀^r u₂` (the ball's volume
over the model ball's volume), never rises as `r` grows. -/
theorem running_total_ratio_antitone {u₁ u₂ : ℝ → ℝ}
    (h₁ : ∀ s, 0 < s → 0 < u₁ s) (h₂ : ∀ s, 0 < s → 0 < u₂ s)
    (hi₁ : ∀ r, IntervalIntegrable u₁ volume 0 r) (hi₂ : ∀ r, IntervalIntegrable u₂ volume 0 r)
    (hanti : AntitoneOn (fun s => u₁ s / u₂ s) (Set.Ioi 0)) :
    AntitoneOn (fun r => (∫ s in (0 : ℝ)..r, u₁ s) / (∫ s in (0 : ℝ)..r, u₂ s)) (Set.Ioi 0) := by
  intro a ha b hb hab
  have ha' : (0:ℝ) < a := ha
  have hb' : (0:ℝ) < b := hb
  have i1ab : IntervalIntegrable u₁ volume a b := (hi₁ a).symm.trans (hi₁ b)
  have i2ab : IntervalIntegrable u₂ volume a b := (hi₂ a).symm.trans (hi₂ b)
  have e1 : (∫ s in (0:ℝ)..b, u₁ s) = (∫ s in (0:ℝ)..a, u₁ s) + ∫ s in a..b, u₁ s :=
    (intervalIntegral.integral_add_adjacent_intervals (hi₁ a) i1ab).symm
  have e2 : (∫ s in (0:ℝ)..b, u₂ s) = (∫ s in (0:ℝ)..a, u₂ s) + ∫ s in a..b, u₂ s :=
    (intervalIntegral.integral_add_adjacent_intervals (hi₂ a) i2ab).symm
  have hu2a := h₂ a ha'
  have L : (u₁ a / u₂ a) * (∫ s in (0:ℝ)..a, u₂ s) ≤ ∫ s in (0:ℝ)..a, u₁ s := by
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_mono_on_of_le_Ioo ha'.le ((hi₂ a).const_mul _) (hi₁ a)
    intro s hs
    have hs0 : 0 < s := hs.1
    have h := hanti hs0 ha' hs.2.le
    have hu2s := h₂ s hs0
    simp only at h
    rw [div_le_div_iff₀ hu2a hu2s] at h
    rw [div_mul_eq_mul_div, div_le_iff₀ hu2a]
    linarith
  have U : (∫ s in a..b, u₁ s) ≤ (u₁ a / u₂ a) * ∫ s in a..b, u₂ s := by
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_mono_on hab i1ab (i2ab.const_mul _)
    intro s hs
    have hs0 : 0 < s := lt_of_lt_of_le ha' hs.1
    have h := hanti ha' hs0 hs.1
    have hu2s := h₂ s hs0
    simp only at h
    rw [div_le_div_iff₀ hu2s hu2a] at h
    rw [div_mul_eq_mul_div, le_div_iff₀ hu2a]
    linarith
  have Y : 0 ≤ ∫ s in a..b, u₂ s :=
    intervalIntegral.integral_nonneg hab (fun s hs => (h₂ s (lt_of_lt_of_le ha' hs.1)).le)
  have P2a : 0 < ∫ s in (0:ℝ)..a, u₂ s :=
    intervalIntegral.intervalIntegral_pos_of_pos_on (hi₂ a) (fun s hs => h₂ s hs.1) ha'
  have P2b : 0 < ∫ s in (0:ℝ)..b, u₂ s := by rw [e2]; linarith
  simp only
  rw [div_le_div_iff₀ P2b P2a, e1, e2]
  nlinarith [mul_le_mul_of_nonneg_left U P2a.le, mul_le_mul_of_nonneg_left L Y]

/-- **On the globe the ratio only falls.** On a globe of radius `R > 0` the ball of radius `r`
has area `2πR²(1 − cos(r/R))`. Its ratio to the flat disc's area `πr²` never rises as `r` grows
from just above 0 up to the antipode, `r = πR`. -/
theorem globe_ball_ratio_antitone (R : ℝ) (hR : 0 < R) :
    AntitoneOn (fun r => 2 * π * R ^ 2 * (1 - cos (r / R)) / (π * r ^ 2))
      (Set.Ioc 0 (π * R)) := by
  have key : ∀ t : ℝ, 0 < t → t < π → t * sin t ≤ 2 * (1 - cos t) := by
    intro t ht0 htπ
    have hx0 : 0 < t / 2 := by linarith
    have hxπ : t / 2 < π / 2 := by linarith
    have hcos : 0 < cos (t / 2) := cos_pos_of_mem_Ioo ⟨by linarith, hxπ⟩
    have hsin : 0 < sin (t / 2) := sin_pos_of_pos_of_lt_pi hx0 (by linarith)
    have htan := lt_tan hx0 hxπ
    rw [tan_eq_sin_div_cos, lt_div_iff₀ hcos] at htan
    have ht : t = 2 * (t / 2) := by ring
    rw [ht, sin_two_mul, cos_two_mul]
    nlinarith [mul_pos hsin (sub_pos.mpr htan), sin_sq_add_cos_sq (t / 2)]
  have hRne : R ≠ 0 := hR.ne'
  have hderiv : ∀ x : ℝ, x ≠ 0 → HasDerivAt (fun r => 2 * π * R ^ 2 * (1 - cos (r / R)) / (π * r ^ 2))
      ((2 * π * R ^ 2 * (-(-sin (x / R) * (1 / R))) * (π * x ^ 2)
        - 2 * π * R ^ 2 * (1 - cos (x / R)) * (π * (2 * x))) / (π * x ^ 2) ^ 2) x := by
    intro x hx
    have h1 : HasDerivAt (fun r => r / R) (1 / R) x := by
      simpa using (hasDerivAt_id x).div_const R
    have h2 := ((h1.cos).const_sub 1).const_mul (2 * π * R ^ 2)
    have h3 : HasDerivAt (fun r => π * r ^ 2) (π * (2 * x)) x := by
      simpa using (hasDerivAt_pow 2 x).const_mul π
    exact h2.div h3 (by positivity)
  apply antitoneOn_of_deriv_nonpos (convex_Ioc 0 (π * R))
  · apply ContinuousOn.div (by fun_prop) (by fun_prop)
    intro x hx
    have : 0 < x := hx.1
    positivity
  · intro x hx
    rw [interior_Ioc] at hx
    exact (hderiv x hx.1.ne').differentiableAt.differentiableWithinAt
  · intro x hx
    rw [interior_Ioc] at hx
    obtain ⟨hx0, hxπ⟩ := hx
    rw [(hderiv x hx0.ne').deriv]
    apply div_nonpos_of_nonpos_of_nonneg _ (by positivity)
    have ht0 : 0 < x / R := div_pos hx0 hR
    have htπ : x / R < π := by rw [div_lt_iff₀ hR]; linarith
    have k := key (x / R) ht0 htπ
    have hxe : x = R * (x / R) := by field_simp
    set t := x / R with htdef
    rw [hxe]
    have hπ := pi_pos
    have : 0 ≤ 2 * π ^ 2 * R ^ 3 * t * (2 * (1 - cos t) - t * sin t) :=
      mul_nonneg (by positivity) (by linarith)
    field_simp
    nlinarith [this]

/-- **Bishop's inequality on the globe.** The globe has curvature `1/R² ≥ 0`, so its ball of
radius `r` is no bigger than the flat disc of the same radius:
`2πR²(1 − cos(r/R)) ≤ πr²`. (The formula is the ball's area for `0 ≤ r ≤ πR`; the inequality
holds for every `r`.) -/
theorem globe_ball_area_le_flat_disc (R r : ℝ) (hR : 0 < R) :
    2 * π * R ^ 2 * (1 - cos (r / R)) ≤ π * r ^ 2 := by
  have h := one_sub_sq_div_two_le_cos (x := r / R)
  have hπ := pi_pos
  have : 1 - cos (r / R) ≤ (r / R) ^ 2 / 2 := by linarith
  calc 2 * π * R ^ 2 * (1 - cos (r / R)) ≤ 2 * π * R ^ 2 * ((r / R) ^ 2 / 2) :=
        mul_le_mul_of_nonneg_left this (by positivity)
    _ = π * r ^ 2 := by field_simp

/-! The card's exact worked numbers. -/

-- At the antipode, r = πR, the whole globe 4πR² over the flat π(πR)² is exactly 4/π².
example (R : ℝ) (hR : 0 < R) :
    2 * π * R ^ 2 * (1 - cos (π * R / R)) / (π * (π * R) ^ 2) = 4 / π ^ 2 := by
  have hπ := pi_pos
  rw [mul_div_cancel_right₀ π hR.ne', cos_pi]
  field_simp
  ring

-- The model ball on the globe adds up shells of size 2π R sin(s/R): its area is 2πR²(1 − cos(r/R)).
example (R r : ℝ) (hR : 0 < R) :
    ∫ s in (0 : ℝ)..r, 2 * π * (R * sin (s / R)) = 2 * π * R ^ 2 * (1 - cos (r / R)) := by
  have hd : ∀ x ∈ Set.uIcc (0:ℝ) r, HasDerivAt (fun s => -(2 * π * R ^ 2 * cos (s / R)))
      (2 * π * (R * sin (x / R))) x := by
    intro x _
    have h1 : HasDerivAt (fun s => s / R) (1 / R) x := by
      simpa using (hasDerivAt_id x).div_const R
    convert ((h1.cos).const_mul (2 * π * R ^ 2)).neg using 1
    field_simp
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd
    ((by fun_prop : Continuous fun s => 2 * π * (R * sin (s / R))).intervalIntegrable _ _)]
  simp only [zero_div, cos_zero]
  ring

-- The 3D ball of the round sphere of radius R adds up shells 4π (R sin(s/R))²:
-- its volume is πR²(2r − R sin(2r/R)).
example (R r : ℝ) (hR : 0 < R) :
    ∫ s in (0 : ℝ)..r, 4 * π * (R * sin (s / R)) ^ 2 = π * R ^ 2 * (2 * r - R * sin (2 * r / R)) := by
  have hd : ∀ x ∈ Set.uIcc (0:ℝ) r, HasDerivAt (fun s => π * R ^ 2 * (2 * s - R * sin (2 * s / R)))
      (4 * π * (R * sin (x / R)) ^ 2) x := by
    intro x _
    have h1 : HasDerivAt (fun s => 2 * s / R) (2 / R) x := by
      simpa using ((hasDerivAt_id x).const_mul 2).div_const R
    have h2 : HasDerivAt (fun s => 2 * s) 2 x := by
      simpa using (hasDerivAt_id x).const_mul 2
    convert ((h2.sub ((h1.sin).const_mul R)).const_mul (π * R ^ 2)) using 1
    have : 2 * x / R = 2 * (x / R) := by ring
    rw [this, cos_two_mul]
    have := sin_sq_add_cos_sq (x / R)
    field_simp
    nlinarith [this]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd
    ((by fun_prop : Continuous fun s => 4 * π * (R * sin (s / R)) ^ 2).intervalIntegrable _ _)]
  simp

-- Flat doubling, the cap for Ric ≥ 0 in dimension 2: the disc of radius 2r is exactly 2² = 4 times the disc of radius r.
example (r : ℝ) : π * (2 * r) ^ 2 = 2 ^ 2 * (π * r ^ 2) := by
  ring

-- A 3D round sphere of radius R has Ric = 2g/R² = (n − 1) k g with n = 3, so k = 1/R², not 2/R².
example (R : ℝ) (hR : 0 < R) : ((3 : ℝ) - 1) * (1 / R ^ 2) = 2 / R ^ 2 := by
  ring

#print axioms running_total_ratio_antitone
#print axioms globe_ball_ratio_antitone
#print axioms globe_ball_area_le_flat_disc

end BishopGromov
