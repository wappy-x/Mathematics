-- Transfer functions: for a car of mass m with linear drag b, the Laplace transform of the impulse response (1/m) e^(-b t/m) is the transfer function 1/(m s + b), an exponential force e^(s t) is answered by the same exponential times 1/(m s + b), and a constant extra force r from rest raises the speed as (r/b)(1 - e^(-b t/m)) toward r/b.
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Exp

open Filter Topology MeasureTheory Set

/-- The transfer function is the Laplace transform of the impulse response. A car of mass `m > 0`
with constant drag `b` per unit speed obeys `m v' + b v = u`. Its impulse response is
`h(t) = (1/m) e^(-b t/m)`, and for every rate `s` (complex in general) to the right of the pole,
`Re s > -b/m`, the transform `∫₀^∞ h(t) e^(-s t) dt` equals `G(s) = 1/(m s + b)`. -/
theorem transfer_function_eq_laplace_transform_of_impulse_response (m b : ℝ) (hm : 0 < m)
    (s : ℂ) (hs : -(b / m) < s.re) :
    ∫ t in Ioi (0 : ℝ), ((Real.exp (-(b * t / m)) / m : ℝ) : ℂ) * Complex.exp (-(s * t))
      = 1 / ((m : ℂ) * s + b) := by
  set a : ℂ := -(s + ((b / m : ℝ) : ℂ)) with ha_def
  have ha : a.re < 0 := by
    rw [ha_def, Complex.neg_re, Complex.add_re, Complex.ofReal_re]; linarith
  have hm' : (m : ℂ) ≠ 0 := by exact_mod_cast hm.ne'
  have key : ∀ t : ℝ, ((Real.exp (-(b * t / m)) / m : ℝ) : ℂ) * Complex.exp (-(s * t))
      = (1 / (m : ℂ)) * Complex.exp (a * t) := by
    intro t
    rw [show a * t = -((b : ℂ) * t / m) + -(s * t) by rw [ha_def]; push_cast; field_simp; ring,
      Complex.exp_add]
    push_cast
    ring
  simp_rw [key]
  rw [integral_const_mul, integral_exp_mul_complex_Ioi ha 0]
  have hne : (m : ℂ) * s + b ≠ 0 := by
    intro h
    have := congrArg Complex.re h
    simp at this
    have h2 : -b < s.re * m := by
      rw [← neg_div] at hs
      exact (div_lt_iff₀ hm).mp hs
    linarith
  have ha0 : a ≠ 0 := by intro h; rw [h] at ha; simp at ha
  rw [ha_def] at ha0 ⊢
  push_cast
  simp only [mul_zero, Complex.exp_zero]
  field_simp

/-- An exponential goes through the car scaled by one number. For a rate `s` with `m s + b ≠ 0`,
the speed `v(t) = q e^(s t)` solves `m v' + b v = e^(s t)` for all time exactly when
`q = 1/(m s + b)`. -/
theorem exponential_force_gives_scaled_exponential_speed (m b : ℝ) (s q : ℂ)
    (hs : (m : ℂ) * s + b ≠ 0) :
    (∀ t : ℝ, (m : ℂ) * deriv (fun τ : ℝ => q * Complex.exp (s * τ)) t
        + b * (q * Complex.exp (s * t)) = Complex.exp (s * t))
      ↔ q = 1 / ((m : ℂ) * s + b) := by
  have hd : ∀ t : ℝ, deriv (fun τ : ℝ => q * Complex.exp (s * τ)) t = q * (Complex.exp (s * t) * s) := by
    intro t
    have h1 : HasDerivAt (fun τ : ℝ => s * (τ : ℂ)) (s * 1) t := by
      simpa using ((hasDerivAt_id (t : ℝ)).ofReal_comp).const_mul s
    have h2 := (h1.cexp).const_mul q
    rw [h2.deriv]; ring
  simp_rw [hd]
  rw [eq_div_iff hs]
  constructor
  · intro h
    have := h 0
    simp at this
    linear_combination this
  · intro h t
    linear_combination Complex.exp (s * t) * h

/-- The step response. A car of mass `m > 0` and drag `b > 0`, at rest in the deviation sense,
pushed by a constant extra force `r`, has speed `v(t) = (r/b)(1 - e^(-b t/m))`: it starts at `0`,
solves `m v' + b v = r`, and settles at the steady gain times the force, `G(0) r = r/b`. -/
theorem step_response_rises_to_steady_gain (m b r : ℝ) (hm : 0 < m) (hb : 0 < b) :
    let v : ℝ → ℝ := fun t => r / b * (1 - Real.exp (-(b * t / m)))
    v 0 = 0 ∧ (∀ t, HasDerivAt v (r / m * Real.exp (-(b * t / m))) t ∧
      m * (r / m * Real.exp (-(b * t / m))) + b * v t = r) ∧
      Tendsto v atTop (𝓝 (r / b)) := by
  intro v
  refine ⟨by simp [v], fun t => ⟨?_, ?_⟩, ?_⟩
  · have h1 : HasDerivAt (fun t : ℝ => -(b * t / m)) (-(b * 1 / m)) t :=
      (((hasDerivAt_id t).const_mul b).div_const m).neg
    have h2 := ((h1.exp).const_sub 1).const_mul (r / b)
    convert h2 using 1
    field_simp
  · simp only [v]
    field_simp
    ring
  · have hneg : Tendsto (fun t : ℝ => -(b * t / m)) atTop atBot := by
      have : Tendsto (fun t : ℝ => (b / m) * t) atTop atTop :=
        tendsto_id.const_mul_atTop (div_pos hb hm)
      refine (tendsto_neg_atTop_atBot.comp this).congr fun t => ?_
      simp; ring
    have he := Real.tendsto_exp_atBot.comp hneg
    have : Tendsto v atTop (𝓝 (r / b * (1 - 0))) :=
      (tendsto_const_nhds.sub he).const_mul (r / b)
    simpa using this

-- The car: m = 1000 kg, c = 1/2 N s^2/m^2, cruise v0 = 25 m/s.
-- Cruise push c v0^2 = 312.5 N.
example : (1 / 2 : ℚ) * 25 * 25 = 625 / 2 := by norm_num
-- Drag per extra m/s, b = 2 c v0 = 25 N s/m.
example : 2 * (1 / 2 : ℚ) * 25 = 25 := by norm_num
-- Time constant τ = m / b = 40 s, and the pole -b/m = -1/40 1/s.
example : (1000 : ℚ) / 25 = 40 := by norm_num
example : -((25 : ℚ) / 1000) = -(1 / 40) := by norm_num
-- Steady gain G(0) = 1/25 (m/s)/N, and G(1/20) = 1/75 (m/s)/N.
example : (1 : ℚ) / (1000 * 0 + 25) = 1 / 25 := by norm_num
example : (1 : ℚ) / (1000 * (1 / 20) + 25) = 1 / 75 := by norm_num
-- A 500 N s shove: h(0+) = 1/1000, so the speed jumps by 500 × 1/1000 = 1/2 m/s.
example : (500 : ℚ) * (1 / 1000) = 1 / 2 := by norm_num
-- A 100 N step, for good: 100 × G(0) = 4 m/s.
example : (100 : ℚ) * (1 / 25) = 4 := by norm_num
-- Partial fractions: 100 / (s (1000 s + 25)) = 4/s - 4/(s + 1/40).
example (s : ℚ) (h0 : s ≠ 0) (h1 : 1000 * s + 25 ≠ 0) :
    100 / (s * (1000 * s + 25)) = 4 / s - 4 / (s + 1 / 40) := by
  have h2 : s + 1 / 40 ≠ 0 := by
    intro h; apply h1; linear_combination 1000 * h
  rw [div_sub_div _ _ h0 h2, div_eq_div_iff (mul_ne_zero h0 h1) (mul_ne_zero h0 h2)]
  ring
-- Engine lag 1/2 s in series: G_total(1/20) = 1 / ((1/2 × 1/20 + 1)(1000 × 1/20 + 25)) = 8/615.
example : (1 : ℚ) / ((1 / 2 * (1 / 20) + 1) * (1000 * (1 / 20) + 25)) = 8 / 615 := by norm_num
-- Its residue coefficient (1/500) / (2 - 1/40) = 2/1975, and h2'(0+) = 1/500 m/s^2 per N s.
example : (1 / 500 : ℚ) / (2 - 1 / 40) = 2 / 1975 := by norm_num
example : (2 / 1975 : ℚ) * (2 - 1 / 40) = 1 / 500 := by norm_num
-- Mistake 3, mass dropped: G(0) = 1 / (0 + 1/40) = 40 (m/s)/N, not 1/25.
example : (1 : ℚ) / (0 + 1 / 40) = 40 := by norm_num

#print axioms transfer_function_eq_laplace_transform_of_impulse_response
#print axioms exponential_force_gives_scaled_exponential_speed
#print axioms step_response_rises_to_steady_gain
