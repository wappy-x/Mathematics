-- AC power: for sine-wave voltage and current the average power is V I cos φ, the quarter-cycle power is V I sin φ, they form a right triangle with V I, and three balanced phases cancel in the neutral and deliver steady power.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.BigOperators.Fin

open Real intervalIntegral

/-- Over one period `2π/ω`, the double-frequency cosine averages to zero. -/
theorem cos_double_freq_integral_zero (ω φ : ℝ) (hω : 0 < ω) :
    ∫ t in (0 : ℝ)..2 * π / ω, cos (2 * ω * t - φ) = 0 := by
  have h2 : (2 * ω) ≠ 0 := by positivity
  rw [integral_comp_mul_sub (f := cos) h2, integral_cos]
  have : 2 * ω * (2 * π / ω) - φ = -φ + (2 : ℕ) * (2 * π) := by
    field_simp; push_cast; ring
  rw [this, sin_add_nat_mul_two_pi]; simp

/-- Over one period `2π/ω`, the double-frequency sine averages to zero. -/
theorem sin_double_freq_integral_zero (ω φ : ℝ) (hω : 0 < ω) :
    ∫ t in (0 : ℝ)..2 * π / ω, sin (2 * ω * t - φ) = 0 := by
  have h2 : (2 * ω) ≠ 0 := by positivity
  rw [integral_comp_mul_sub (f := sin) h2, integral_sin]
  have : 2 * ω * (2 * π / ω) - φ = -φ + (2 : ℕ) * (2 * π) := by
    field_simp; push_cast; ring
  rw [this, cos_add_nat_mul_two_pi]; simp

/-- Three cosines a third of a turn apart add to zero. -/
theorem cos_three_phase_sum (x : ℝ) :
    cos x + cos (x - 2 * π / 3) + cos (x - 4 * π / 3) = 0 := by
  have h1 : cos (x - 2 * π / 3) = -(cos x * cos (π / 3) - sin x * sin (π / 3)) := by
    rw [show x - 2 * π / 3 = (x + π / 3) - π by ring, cos_sub_pi, cos_add]
  have h2 : cos (x - 4 * π / 3) = -(cos x * cos (π / 3) + sin x * sin (π / 3)) := by
    rw [show x - 4 * π / 3 = (x - π / 3) - π by ring, cos_sub_pi, cos_sub]
  rw [h1, h2, cos_pi_div_three]
  ring

/-- Product to sum: `(√2 V cos a)(√2 I cos(a - φ)) = V I cos φ + V I cos(2a - φ)`. -/
theorem sqrt2_cos_mul_cos (V I φ a : ℝ) :
    (√2 * V * cos a) * (√2 * I * cos (a - φ)) =
      V * I * cos φ + V * I * cos (2 * a - φ) := by
  have hs : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have h1 : cos (2 * a - φ) = cos a * cos (a - φ) - sin a * sin (a - φ) := by
    rw [← cos_add]; ring_nf
  have h2 : cos φ = cos a * cos (a - φ) + sin a * sin (a - φ) := by
    rw [← cos_sub]; ring_nf
  linear_combination (V * I * cos a * cos (a - φ)) * hs - V * I * h1 - V * I * h2

/-- Product to sum: `(√2 V sin a)(√2 I cos(a - φ)) = V I sin φ + V I sin(2a - φ)`. -/
theorem sqrt2_sin_mul_cos (V I φ a : ℝ) :
    (√2 * V * sin a) * (√2 * I * cos (a - φ)) =
      V * I * sin φ + V * I * sin (2 * a - φ) := by
  have hs : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have h1 : sin (2 * a - φ) = sin a * cos (a - φ) + cos a * sin (a - φ) := by
    rw [← sin_add]; ring_nf
  have h2 : sin φ = sin a * cos (a - φ) - cos a * sin (a - φ) := by
    rw [← sin_sub]; ring_nf
  linear_combination (V * I * sin a * cos (a - φ)) * hs - V * I * h1 - V * I * h2

#print axioms cos_double_freq_integral_zero
#print axioms sin_double_freq_integral_zero
#print axioms cos_three_phase_sum
#print axioms sqrt2_cos_mul_cos
#print axioms sqrt2_sin_mul_cos

/-- The power triangle. Take a voltage `v t = √2 V cos(ω t)` and a current
`i t = √2 I cos(ω t - φ)` lagging it by `φ`, at one frequency `ω > 0`, with
period `T = 2π/ω` (`V`, `I` are the rms values). The real power `P` is the
average of `v t * i t` over one cycle; the reactive power `Q` is the average of
the voltage a quarter cycle late times the current; the apparent power is
`S = V I`. Then `P = S cos φ`, `Q = S sin φ` and `P² + Q² = S²`. -/
theorem ac_power_triangle (V I φ ω : ℝ) (hω : 0 < ω) :
    let T := 2 * π / ω
    let v : ℝ → ℝ := fun t => √2 * V * cos (ω * t)
    let i : ℝ → ℝ := fun t => √2 * I * cos (ω * t - φ)
    let P := T⁻¹ * ∫ t in (0 : ℝ)..T, v t * i t
    let Q := T⁻¹ * ∫ t in (0 : ℝ)..T, v (t - T / 4) * i t
    let S := V * I
    P = S * cos φ ∧ Q = S * sin φ ∧ P ^ 2 + Q ^ 2 = S ^ 2 := by
  intro T v i P Q S
  have hT : T ≠ 0 := by positivity
  have hP_int : (fun t => v t * i t) =
      fun t => V * I * cos φ + V * I * cos (2 * ω * t - φ) := by
    funext t
    simp only [v, i]
    rw [sqrt2_cos_mul_cos, mul_assoc 2 ω t]
  have hQ_int : (fun t => v (t - T / 4) * i t) =
      fun t => V * I * sin φ + V * I * sin (2 * ω * t - φ) := by
    funext t
    simp only [v, i]
    have e0 : ω * (t - T / 4) = ω * t - π / 2 := by
      simp only [T]; field_simp; ring
    rw [e0, cos_sub_pi_div_two, sqrt2_sin_mul_cos, mul_assoc 2 ω t]
  have hP : P = S * cos φ := by
    simp only [P]
    rw [hP_int, integral_add intervalIntegrable_const
      (Continuous.intervalIntegrable (by fun_prop) _ _),
      integral_const, integral_const_mul, cos_double_freq_integral_zero ω φ hω]
    simp only [S, smul_eq_mul, sub_zero]
    field_simp
    ring
  have hQ : Q = S * sin φ := by
    simp only [Q]
    rw [hQ_int, integral_add intervalIntegrable_const
      (Continuous.intervalIntegrable (by fun_prop) _ _),
      integral_const, integral_const_mul, sin_double_freq_integral_zero ω φ hω]
    simp only [S, smul_eq_mul, sub_zero]
    field_simp
    ring
  refine ⟨hP, hQ, ?_⟩
  rw [hP, hQ]
  linear_combination S ^ 2 * sin_sq_add_cos_sq φ

/-- Balanced three phases need no return current: three equal currents, each
lagging its own voltage by the same `φ`, the three a third of a cycle (`2π/3`)
apart, add to zero in the neutral at every instant. -/
theorem three_phase_neutral_current_zero (I φ ω t : ℝ) :
    ∑ k : Fin 3, √2 * I * cos (ω * t - φ - 2 * π * k / 3) = 0 := by
  simp only [Fin.sum_univ_three, Fin.val_zero, Fin.val_one, Fin.val_two]
  push_cast
  rw [show ω * t - φ - 2 * π * 0 / 3 = ω * t - φ by ring,
    show ω * t - φ - 2 * π * 1 / 3 = (ω * t - φ) - 2 * π / 3 by ring,
    show ω * t - φ - 2 * π * 2 / 3 = (ω * t - φ) - 4 * π / 3 by ring]
  linear_combination (√2 * I) * cos_three_phase_sum (ω * t - φ)

/-- Balanced three phases draw perfectly steady power: with voltages
`√2 V cos(ω t - 2πk/3)` and currents `√2 I cos(ω t - φ - 2πk/3)` for
`k = 0, 1, 2`, the total power at every instant is `3 V I cos φ`, the same at
all times. -/
theorem three_phase_power_steady (V I φ ω t : ℝ) :
    ∑ k : Fin 3, (√2 * V * cos (ω * t - 2 * π * k / 3)) *
      (√2 * I * cos (ω * t - φ - 2 * π * k / 3)) = 3 * V * I * cos φ := by
  simp only [Fin.sum_univ_three, Fin.val_zero, Fin.val_one, Fin.val_two]
  push_cast
  rw [show ω * t - φ - 2 * π * 0 / 3 = (ω * t - 2 * π * 0 / 3) - φ by ring,
    show ω * t - φ - 2 * π * 1 / 3 = (ω * t - 2 * π * 1 / 3) - φ by ring,
    show ω * t - φ - 2 * π * 2 / 3 = (ω * t - 2 * π * 2 / 3) - φ by ring,
    sqrt2_cos_mul_cos, sqrt2_cos_mul_cos, sqrt2_cos_mul_cos]
  have h0 : cos (2 * (ω * t - 2 * π * 0 / 3) - φ) = cos (2 * ω * t - φ) := by ring_nf
  have h1 : cos (2 * (ω * t - 2 * π * 1 / 3) - φ) = cos (2 * ω * t - φ - 4 * π / 3) := by
    ring_nf
  have h2 : cos (2 * (ω * t - 2 * π * 2 / 3) - φ) = cos (2 * ω * t - φ - 2 * π / 3) := by
    rw [show 2 * (ω * t - 2 * π * 2 / 3) - φ = (2 * ω * t - φ - 2 * π / 3) - 2 * π by ring,
      cos_sub_two_pi]
  rw [h0, h1, h2]
  linear_combination (V * I) * cos_three_phase_sum (2 * ω * t - φ)

-- Worked numbers: a 5,000 W motor at power factor 4/5 (so sin φ = 3/5).
-- Apparent power S = 5,000 ÷ 4/5 = 6,250 VA.
example : (5000 : ℚ) / (4 / 5) = 6250 := by norm_num
-- Reactive power Q = 6,250 × 3/5 = 3,750 var, and 5,000² + 3,750² = 6,250².
example : (6250 : ℚ) * (3 / 5) = 3750 := by norm_num
example : (5000 : ℕ) ^ 2 + 3750 ^ 2 = 6250 ^ 2 := by norm_num
-- p(t) runs from P - S to P + S: from -1,250 W to 11,250 W.
example : (5000 : ℤ) - 6250 = -1250 ∧ (5000 : ℤ) + 6250 = 11250 := by norm_num
-- The usual mistake S = P + Q gives 8,750, not 6,250.
example : (5000 : ℕ) + 3750 = 8750 := by norm_num

#print axioms ac_power_triangle
#print axioms three_phase_neutral_current_zero
#print axioms three_phase_power_steady
