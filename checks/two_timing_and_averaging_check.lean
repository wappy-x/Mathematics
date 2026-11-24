-- Two-timing and averaging: the closed form solves van der Pol's slow amplitude equation and tends to 2, and the one-swing averages give the van der Pol drift and the Duffing frequency shift exactly.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Real Filter Topology

lemma sin_four_mul_two_pi : Real.sin (4 * (2 * π)) = 0 := by
  have : 4 * (2 * π) = ((8 : ℕ) : ℝ) * π := by push_cast; ring
  rw [this, Real.sin_nat_mul_pi]

#print axioms sin_four_mul_two_pi

lemma integral_sin_mul_cos_cube_two_pi :
    ∫ θ in (0 : ℝ)..2 * π, Real.sin θ * Real.cos θ ^ 3 = 0 := by
  have := integral_sin_pow_odd_mul_cos_pow (a := 0) (b := 2 * π) 0 3
  simp only [Nat.mul_zero, zero_add, pow_one] at this
  rw [this, Real.cos_two_pi, Real.cos_zero, intervalIntegral.integral_same]

#print axioms integral_sin_mul_cos_cube_two_pi

lemma integral_cos_four_two_pi :
    ∫ θ in (0 : ℝ)..2 * π, Real.cos θ ^ 4 = 3 * π / 4 := by
  have := integral_cos_pow (a := 0) (b := 2 * π) (n := 2)
  norm_num at this
  rw [this]; ring

#print axioms integral_cos_four_two_pi

/-- The card's slow amplitude law for van der Pol: for a positive strength `ε` and a
positive starting size `r₀`, the closed form
`r(t) = 2 / √(1 + (4/r₀² - 1) e^(-ε t))` starts at `r₀`, solves the slow equation
`r' = (ε/2) r (1 - r²/4)` at every time `t ≥ 0`, and tends to size 2 as `t` grows:
every start other than 0 settles at amplitude 2. -/
theorem vdp_slow_amplitude_closed_form (ε r₀ : ℝ) (hε : 0 < ε) (hr₀ : 0 < r₀)
    (r : ℝ → ℝ)
    (hr : ∀ t, r t = 2 / Real.sqrt (1 + (4 / r₀ ^ 2 - 1) * Real.exp (-ε * t))) :
    r 0 = r₀ ∧
      (∀ t, 0 ≤ t → HasDerivAt r (ε / 2 * r t * (1 - r t ^ 2 / 4)) t) ∧
      Tendsto r atTop (𝓝 2) := by
  have hfun : r = fun t => 2 / Real.sqrt (1 + (4 / r₀ ^ 2 - 1) * Real.exp (-ε * t)) :=
    funext hr
  set c := 4 / r₀ ^ 2 - 1 with hc
  refine ⟨?_, ?_, ?_⟩
  · rw [hr]
    have h1 : 1 + c * Real.exp (-ε * 0) = (2 / r₀) ^ 2 := by
      rw [hc]; simp; field_simp; ring
    rw [h1, Real.sqrt_sq (by positivity)]
    field_simp
  · intro t ht
    have he : Real.exp (-ε * t) ≤ 1 := Real.exp_le_one_iff.mpr (by nlinarith)
    have hepos := Real.exp_pos (-ε * t)
    have h4 : 0 < 4 / r₀ ^ 2 := by positivity
    have hu : 0 < 1 + c * Real.exp (-ε * t) := by
      rw [hc]; nlinarith
    have h0 : HasDerivAt (fun t => Real.exp (-ε * t)) (Real.exp (-ε * t) * (-ε * 1)) t :=
      ((hasDerivAt_id t).const_mul (-ε)).exp
    have h1 : HasDerivAt (fun t => 1 + c * Real.exp (-ε * t))
        (c * (Real.exp (-ε * t) * (-ε * 1))) t :=
      (h0.const_mul c).const_add 1
    have h2 := h1.sqrt hu.ne'
    have hs : 0 < Real.sqrt (1 + c * Real.exp (-ε * t)) := Real.sqrt_pos.mpr hu
    have h3 := (hasDerivAt_const t (2 : ℝ)).div h2 hs.ne'
    rw [hr t, hfun]
    convert h3 using 1
    have hs2 := Real.sq_sqrt hu.le
    set s := Real.sqrt (1 + c * Real.exp (-ε * t))
    set e := Real.exp (-ε * t)
    field_simp
    rw [hs2]
    ring
  · have h0 : Tendsto (fun t => Real.exp (-ε * t)) atTop (𝓝 0) := by
      apply Real.tendsto_exp_atBot.comp
      exact tendsto_id.const_mul_atTop_of_neg (by linarith)
    have h1 : Tendsto (fun t => 1 + c * Real.exp (-ε * t)) atTop (𝓝 (1 + c * 0)) :=
      tendsto_const_nhds.add (tendsto_const_nhds.mul h0)
    rw [mul_zero, add_zero] at h1
    have h2 := h1.sqrt
    rw [Real.sqrt_one] at h2
    have h3 := (tendsto_const_nhds (x := (2 : ℝ))).div h2 one_ne_zero
    rw [div_one] at h3
    rw [hfun]
    exact h3

/-- The card's averaging step for van der Pol: with `h = (x² - 1) x'` on the sine wave
`x = r cos θ`, `x' = -r sin θ`, the size rate `ε ⟨h sin θ⟩` (the average over one swing,
`θ` from 0 to `2π`) is exactly `(ε/2) r (1 - r²/4)`, and the timing rate `ε ⟨h cos θ⟩`
is exactly 0, so the phase lag does not drift. -/
theorem vdp_averaged_rates (ε r : ℝ) :
    ε * ((1 / (2 * π)) *
        ∫ θ in (0 : ℝ)..2 * π, ((r * cos θ) ^ 2 - 1) * (-r * sin θ) * sin θ)
        = ε / 2 * r * (1 - r ^ 2 / 4) ∧
      ε * ((1 / (2 * π)) *
        ∫ θ in (0 : ℝ)..2 * π, ((r * cos θ) ^ 2 - 1) * (-r * sin θ) * cos θ) = 0 := by
  have hpi : π ≠ 0 := Real.pi_ne_zero
  constructor
  · have hf : (fun θ => ((r * cos θ) ^ 2 - 1) * (-r * sin θ) * sin θ)
        = fun θ => r * sin θ ^ 2 - r ^ 3 * (sin θ ^ 2 * cos θ ^ 2) := by
      funext θ; ring
    rw [hf, intervalIntegral.integral_sub, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul, integral_sin_sq, integral_sin_sq_mul_cos_sq,
      sin_four_mul_two_pi]
    · simp
      field_simp
      ring
    · apply Continuous.intervalIntegrable; fun_prop
    · apply Continuous.intervalIntegrable; fun_prop
  · have hf : (fun θ => ((r * cos θ) ^ 2 - 1) * (-r * sin θ) * cos θ)
        = fun θ => r * (sin θ * cos θ) - r ^ 3 * (sin θ * cos θ ^ 3) := by
      funext θ; ring
    rw [hf, intervalIntegral.integral_sub, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul, integral_sin_mul_cos₁,
      integral_sin_mul_cos_cube_two_pi]
    · simp
    · apply Continuous.intervalIntegrable; fun_prop
    · apply Continuous.intervalIntegrable; fun_prop

/-- The card's Duffing step: with `h = x³` on the sine wave `x = a cos θ`, the size rate
`ε ⟨h sin θ⟩` is 0 (the size stays fixed), and the timing rate `ε ⟨h cos θ⟩` equals
`a · (3 ε a² / 8)`, so the phase lag drifts at `3 ε a² / 8` and the swing runs at
frequency `1 + 3 ε a² / 8`. -/
theorem duffing_averaged_rates (ε a : ℝ) :
    ε * ((1 / (2 * π)) * ∫ θ in (0 : ℝ)..2 * π, (a * cos θ) ^ 3 * sin θ) = 0 ∧
      ε * ((1 / (2 * π)) * ∫ θ in (0 : ℝ)..2 * π, (a * cos θ) ^ 3 * cos θ)
        = a * (3 * ε * a ^ 2 / 8) := by
  have hpi : π ≠ 0 := Real.pi_ne_zero
  constructor
  · have hf : (fun θ => (a * cos θ) ^ 3 * sin θ)
        = fun θ => a ^ 3 * (sin θ * cos θ ^ 3) := by
      funext θ; ring
    rw [hf, intervalIntegral.integral_const_mul, integral_sin_mul_cos_cube_two_pi]
    simp
  · have hf : (fun θ => (a * cos θ) ^ 3 * cos θ)
        = fun θ => a ^ 3 * cos θ ^ 4 := by
      funext θ; ring
    rw [hf, intervalIntegral.integral_const_mul, integral_cos_four_two_pi]
    field_simp
    ring

-- Worked numbers from the card (strength 1/10, start 1/2).
-- Drift at the start: 0.05 × 0.5 × (1 - 0.5²/4) = 3/128 = 0.0234375.
example : (1 / 10 : ℚ) / 2 * (1 / 2) * (1 - (1 / 2) ^ 2 / 4) = 3 / 128 := by norm_num
-- Resting size: the drift factor 1 - r²/4 is zero at r = 2.
example : (1 : ℚ) - 2 ^ 2 / 4 = 0 := by norm_num
-- The start's offset: 4/0.5² - 1 = 15.
example : (4 : ℚ) / (1 / 2) ^ 2 - 1 = 15 := by norm_num
-- Hopf normal form: growth ε/2 over cubic ε/8 is 4, so the radius is 2.
example (ε : ℚ) (hε : ε ≠ 0) : (ε / 2) / (ε / 8) = 2 ^ 2 := by field_simp; norm_num
-- Duffing at size 1: 1 + 0.1 × 3/8 = 1.0375 = 83/80.
example : (1 : ℚ) + 1 / 10 * 3 / 8 = 83 / 80 := by norm_num
-- Mistake 3: shift 3/4 instead of 3/8 gives 1.075 = 43/40.
example : (1 : ℚ) + 1 / 10 * 3 / 4 = 43 / 40 := by norm_num

#print axioms vdp_slow_amplitude_closed_form
#print axioms vdp_averaged_rates
#print axioms duffing_averaged_rates
