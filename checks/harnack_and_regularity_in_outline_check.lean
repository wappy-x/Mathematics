-- Harnack and regularity: in the plane, a harmonic function that is never negative on a disc is pinned between fixed multiples of its centre value, a harmonic function is real-analytic, and a bounded or nonnegative harmonic function on the whole plane is constant.
import Mathlib.Analysis.Complex.Harmonic.Analytic
import Mathlib.Analysis.Complex.Harmonic.Liouville
import Mathlib.Analysis.Complex.Harmonic.MeanValue
import Mathlib.Analysis.Complex.Harmonic.Poisson
import Mathlib.Tactic.NormNum

open InnerProductSpace Metric

/-! The plane is `ℂ`, with `‖x‖` the distance from the origin. Mathlib's theory of harmonic
functions (the Poisson formula, analyticity, Liouville) is built on `ℂ`, so this file covers
the card's flat plate, `d = 2`. -/

/-- Bounds on the Poisson kernel of the circle of radius `ρ` round the origin. -/
theorem harnack_aux_kernel {x z : ℂ} {ρ : ℝ} (hxρ : ‖x‖ < ρ) (hz : ‖z‖ = ρ) :
    (ρ - ‖x‖) / (ρ + ‖x‖) ≤ poissonKernel 0 x z ∧
      poissonKernel 0 x z ≤ (ρ + ‖x‖) / (ρ - ‖x‖) := by
  rw [poissonKernel_def]
  simp only [sub_zero, hz]
  have hr : 0 ≤ ‖x‖ := norm_nonneg _
  have h1 : ρ - ‖x‖ ≤ ‖z - x‖ := by have := norm_sub_norm_le z x; linarith
  have h2 : ‖z - x‖ ≤ ρ + ‖x‖ := by have := norm_sub_le z x; linarith
  have hd : 0 < ‖z - x‖ := by linarith
  have hd2 : ‖z - x‖ ^ 2 ≤ (ρ + ‖x‖) ^ 2 := by nlinarith
  have hd3 : (ρ - ‖x‖) ^ 2 ≤ ‖z - x‖ ^ 2 := by nlinarith
  constructor
  · rw [div_le_div_iff₀ (by linarith) (by positivity)]
    nlinarith [mul_le_mul_of_nonneg_left hd2 (by linarith : (0:ℝ) ≤ ρ - ‖x‖)]
  · rw [div_le_div_iff₀ (by positivity) (by linarith)]
    nlinarith [mul_le_mul_of_nonneg_left hd3 (by linarith : (0:ℝ) ≤ ρ + ‖x‖)]

/-- Harnack's inequality on a closed disc `ρ` inside the region of harmonicity. -/
theorem harnack_aux_rho {u : ℂ → ℝ} {R : ℝ}
    (hu : HarmonicOnNhd u (ball 0 R))
    (hpos : ∀ y ∈ ball (0 : ℂ) R, 0 ≤ u y)
    {x : ℂ} {ρ : ℝ} (hxρ : ‖x‖ < ρ) (hρR : ρ < R) :
    (ρ - ‖x‖) / (ρ + ‖x‖) * u 0 ≤ u x ∧ u x ≤ (ρ + ‖x‖) / (ρ - ‖x‖) * u 0 := by
  have hρ : 0 < ρ := lt_of_le_of_lt (norm_nonneg x) hxρ
  have hsub : closedBall (0 : ℂ) ρ ⊆ ball 0 R := closedBall_subset_ball hρR
  have hh : HarmonicOnNhd u (closedBall 0 ρ) := hu.mono hsub
  have hh' : HarmonicOnNhd u (closedBall 0 |ρ|) := by rwa [abs_of_pos hρ]
  have hxb : x ∈ ball (0 : ℂ) ρ := by simpa using hxρ
  have hP := hh.circleAverage_poissonKernel_smul hxb
  have hM := hh'.circleAverage_eq
  have hsph : ∀ z ∈ sphere (0 : ℂ) |ρ|, ‖z‖ = ρ := by
    intro z hz; simpa [abs_of_pos hρ] using hz
  have hcu : ContinuousOn u (sphere (0 : ℂ) |ρ|) :=
    hh'.continuousOn.mono sphere_subset_closedBall
  have hcP : ContinuousOn (poissonKernel 0 x) (sphere (0 : ℂ) |ρ|) := by
    intro z hz
    have hzx : z - x ≠ 0 := by
      intro h
      have : z = x := sub_eq_zero.mp h
      have := hsph z hz
      subst_vars; linarith
    have : ‖(z - 0) - (x - 0)‖ ^ 2 ≠ 0 := by simpa using hzx
    unfold poissonKernel
    apply ContinuousAt.continuousWithinAt
    fun_prop (disch := assumption)
  have hiu : CircleIntegrable u 0 ρ := hcu.circleIntegrable'
  have hiPu : CircleIntegrable (poissonKernel 0 x • u) 0 ρ := (hcP.smul hcu).circleIntegrable'
  have hia : ∀ a : ℝ, CircleIntegrable (a • u) 0 ρ := fun a =>
    (continuousOn_const.smul hcu).circleIntegrable'
  have hupos : ∀ z ∈ sphere (0 : ℂ) |ρ|, 0 ≤ u z := fun z hz =>
    hpos z (hsub (mem_closedBall_zero_iff.mpr (hsph z hz).le))
  constructor
  · have := Real.circleAverage_mono (hia ((ρ - ‖x‖) / (ρ + ‖x‖))) hiPu (fun z hz => by
      simp only [Pi.smul_apply, smul_eq_mul]
      exact mul_le_mul_of_nonneg_right (harnack_aux_kernel hxρ (hsph z hz)).1 (hupos z hz))
    rw [Real.circleAverage_smul, hP, hM, smul_eq_mul] at this
    exact this
  · have := Real.circleAverage_mono hiPu (hia ((ρ + ‖x‖) / (ρ - ‖x‖))) (fun z hz => by
      simp only [Pi.smul_apply, smul_eq_mul]
      exact mul_le_mul_of_nonneg_right (harnack_aux_kernel hxρ (hsph z hz)).2 (hupos z hz))
    rw [Real.circleAverage_smul, hP, hM, smul_eq_mul] at this
    exact this

#print axioms harnack_aux_kernel
#print axioms harnack_aux_rho

/-- If `(R - r) a ≤ (R + r) b` for every `R > r`, then `a ≤ b`. -/
theorem liouville_aux {a b r : ℝ} (hr : 0 ≤ r)
    (h : ∀ R, r < R → (R - r) * a ≤ (R + r) * b) : a ≤ b := by
  by_contra hlt
  rw [not_le] at hlt
  have hab : 0 < a - b := by linarith
  have hq : 0 ≤ r * (a + b) / (a - b) ∨ r * (a + b) / (a - b) < 0 := le_or_gt _ _
  have hk : (r * (a + b) / (a - b)) * (a - b) = r * (a + b) := div_mul_cancel₀ _ hab.ne'
  set q := r * (a + b) / (a - b)
  have := h (r + 1 + |q|) (by have := abs_nonneg q; linarith)
  rcases hq with hq | hq
  · rw [abs_of_nonneg hq] at this
    nlinarith [mul_nonneg hr hab.le]
  · rw [abs_of_neg hq] at this
    nlinarith [mul_nonneg hr hab.le]

#print axioms liouville_aux

/-- Harnack's inequality in the plane (`d = 2`): if `u` is harmonic and never negative on the
disc of radius `R` round the origin, and `|x| = r < R`, then
`(R - r) / (R + r) · u(0) ≤ u(x) ≤ (R + r) / (R - r) · u(0)`. -/
theorem harnack_inequality_disc {u : ℂ → ℝ} {R : ℝ}
    (hu : HarmonicOnNhd u (ball 0 R))
    (hpos : ∀ y ∈ ball (0 : ℂ) R, 0 ≤ u y)
    {x : ℂ} (hx : ‖x‖ < R) :
    (R - ‖x‖) / (R + ‖x‖) * u 0 ≤ u x ∧ u x ≤ (R + ‖x‖) / (R - ‖x‖) * u 0 := by
  have hev : ∀ᶠ ρ in nhdsWithin R (Set.Iio R), ‖x‖ < ρ ∧ ρ < R := by
    have h1 : ∀ᶠ ρ in nhdsWithin R (Set.Iio R), ‖x‖ < ρ :=
      nhdsWithin_le_nhds (lt_mem_nhds hx)
    have h2 : ∀ᶠ ρ in nhdsWithin R (Set.Iio R), ρ < R := self_mem_nhdsWithin
    exact h1.and h2
  have hne : R + ‖x‖ ≠ 0 := by have := norm_nonneg x; linarith
  have hne' : R - ‖x‖ ≠ 0 := by linarith
  have hc1 : Filter.Tendsto (fun ρ => (ρ - ‖x‖) / (ρ + ‖x‖) * u 0) (nhdsWithin R (Set.Iio R))
      (nhds ((R - ‖x‖) / (R + ‖x‖) * u 0)) := by
    apply tendsto_nhdsWithin_of_tendsto_nhds
    exact (((continuousAt_id.sub continuousAt_const).div
      (continuousAt_id.add continuousAt_const) hne).mul continuousAt_const).tendsto
  have hc2 : Filter.Tendsto (fun ρ => (ρ + ‖x‖) / (ρ - ‖x‖) * u 0) (nhdsWithin R (Set.Iio R))
      (nhds ((R + ‖x‖) / (R - ‖x‖) * u 0)) := by
    apply tendsto_nhdsWithin_of_tendsto_nhds
    exact (((continuousAt_id.add continuousAt_const).div
      (continuousAt_id.sub continuousAt_const) hne').mul continuousAt_const).tendsto
  constructor
  · exact le_of_tendsto hc1 (hev.mono fun ρ h => (harnack_aux_rho hu hpos h.1 h.2).1)
  · exact ge_of_tendsto hc2 (hev.mono fun ρ h => (harnack_aux_rho hu hpos h.1 h.2).2)

/-- Regularity in the plane: a harmonic function is real-analytic (equal to its own Taylor
series near each inside point) everywhere inside its region, whatever its boundary data. -/
theorem harmonic_is_real_analytic {u : ℂ → ℝ} {s : Set ℂ} (hu : HarmonicOnNhd u s) :
    AnalyticOnNhd ℝ u s := by
  exact fun x hx => HarmonicAt.analyticAt (hu x hx)

/-- Liouville's theorem in the plane: a harmonic function on the whole plane that is bounded,
or merely never negative, is constant. -/
theorem liouville_harmonic {u : ℂ → ℝ}
    (hu : HarmonicOnNhd u Set.univ)
    (hb : (∃ M : ℝ, ∀ x, |u x| ≤ M) ∨ (∀ x, 0 ≤ u x)) :
    ∃ c : ℝ, ∀ x, u x = c := by
  refine ⟨u 0, fun x => ?_⟩
  rcases hb with ⟨M, hM⟩ | hnn
  · have hbd : Bornology.IsBounded (Set.range u) := by
      rw [isBounded_iff_forall_norm_le]
      exact ⟨M, by rintro _ ⟨y, rfl⟩; simpa [Real.norm_eq_abs] using hM y⟩
    exact bounded_harmonic_on_complex_plane_is_constant u hu hbd x 0
  · have hr : 0 ≤ ‖x‖ := norm_nonneg x
    have key : ∀ R, ‖x‖ < R → (R - ‖x‖) / (R + ‖x‖) * u 0 ≤ u x ∧
        u x ≤ (R + ‖x‖) / (R - ‖x‖) * u 0 := fun R hR =>
      harnack_inequality_disc (hu.mono (Set.subset_univ _)) (fun y _ => hnn y) hR
    apply le_antisymm
    · apply liouville_aux hr
      intro R hR
      have h := (key R hR).2
      rw [div_mul_eq_mul_div, le_div_iff₀ (by linarith)] at h
      linarith
    · apply liouville_aux hr
      intro R hR
      have h := (key R hR).1
      rw [div_mul_eq_mul_div, div_le_iff₀ (by linarith)] at h
      linarith

-- The plate: R = 10 cm, r = 5 cm, centre 50 °C. Harnack's factors in the plane are 1/3 and 3.
example : ((10 : ℚ) - 5) / (10 + 5) = 1 / 3 := by norm_num
example : ((10 : ℚ) + 5) / (10 - 5) = 3 := by norm_num
-- The floor and cap on the 5 cm circle: 50/3 °C and 150 °C.
example : (50 : ℚ) * (1 / 3) = 50 / 3 ∧ (50 : ℚ) * 3 = 150 := by norm_num
-- Half-ball short form: max/min at most 3^d, 9 in a plate and 27 in a solid.
example : (3 : ℕ) ^ 2 = 9 ∧ (3 : ℕ) ^ 3 = 27 := by norm_num
-- At r = R/2 the upper factor 3·2^(d-2) over the lower factor (1/2)(2/3)^(d-1) is 3^d (d = 2, 3).
example : (3 * 2 ^ 0 : ℚ) / ((1 / 2) * (2 / 3) ^ 1) = 3 ^ 2 := by norm_num
example : (3 * 2 ^ 1 : ℚ) / ((1 / 2) * (2 / 3) ^ 2) = 3 ^ 3 := by norm_num
-- Slope bound at the centre, d = 2, M = 50 °C, s = 0.1 m: 2 · 50 / 0.1 = 1000 K/m.
example : (2 * 50 : ℚ) / (1 / 10) = 1000 := by norm_num
-- Slope bound 2M/t at 50 mm, 10 mm and 1 mm from the jump: 2000, 10000 and 100000 K/m.
example : (2 * 50 : ℚ) / (50 / 1000) = 2000 ∧ (2 * 50 : ℚ) / (10 / 1000) = 10000 ∧
    (2 * 50 : ℚ) / (1 / 1000) = 100000 := by norm_num
-- Higher-slope bounds M (2k)^k with M = 50, k = 1, 3, 5, 7.
example : 50 * (2 * 1) ^ 1 = 100 ∧ 50 * (2 * 3) ^ 3 = 10800 ∧ 50 * (2 * 5) ^ 5 = 5000000 ∧
    50 * (2 * 7) ^ 7 = 5270675200 := by norm_num

#print axioms harnack_inequality_disc
#print axioms harmonic_is_real_analytic
#print axioms liouville_harmonic
