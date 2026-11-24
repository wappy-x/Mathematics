-- Op-amps: the non-inverting stage's gain A/(1 + Aβ) tends to 1 + R_f/R_1 as the op-amp's gain grows, solving the loop gives that gain, and a one-lag op-amp under feedback is one lag again whose gain times corner is fixed.
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

open Filter Topology

/-! The op-amp is a gain block: `v_out = A (v₊ - v₋)`. In the non-inverting stage the input sits
on the + input and the divider `R_f`, `R_1` feeds back `v₋ = β v_out` with feedback fraction
`β = R_1/(R_1 + R_f)`. Feedback to the − input is what puts the plus sign in `1 + Aβ`. -/

/-- The card's formula. With resistors `R_1 > 0` and `R_f ≥ 0` and feedback fraction
`β = R_1/(R_1 + R_f)`, the closed-loop gain `A/(1 + Aβ)` tends to `1/β = 1 + R_f/R_1` as the
op-amp's open-loop gain `A` grows without bound: two resistors set the gain. -/
theorem closed_loop_gain_tendsto_one_add_ratio (R1 Rf : ℝ) (hR1 : 0 < R1) (hRf : 0 ≤ Rf) :
    Tendsto (fun A : ℝ => A / (1 + A * (R1 / (R1 + Rf)))) atTop (𝓝 (1 + Rf / R1)) := by
  have hS : 0 < R1 + Rf := by linarith
  have hc : 0 < R1 / (R1 + Rf) := div_pos hR1 hS
  have h1 : Tendsto (fun A : ℝ => (A⁻¹ + R1 / (R1 + Rf))⁻¹) atTop (𝓝 ((0 + R1 / (R1 + Rf))⁻¹)) :=
    (tendsto_inv_atTop_zero.add tendsto_const_nhds).inv₀ (by rw [zero_add]; exact hc.ne')
  have hlim : (0 + R1 / (R1 + Rf))⁻¹ = 1 + Rf / R1 := by
    rw [zero_add, inv_div]; field_simp
  rw [hlim] at h1
  refine h1.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with A hA
  field_simp

/-- Step 1. Solving the loop: if the output obeys `v_out = A (v_in - β v_out)` with `A ≥ 0` and
`β ≥ 0`, then `v_out = A/(1 + Aβ) · v_in`, the forward path over one plus the loop gain. -/
theorem noninverting_loop_solution (A β vin vout : ℝ) (hA : 0 ≤ A) (hβ : 0 ≤ β)
    (hloop : vout = A * (vin - β * vout)) :
    vout = A / (1 + A * β) * vin := by
  have hpos : 0 < 1 + A * β := by nlinarith [mul_nonneg hA hβ]
  rw [div_mul_eq_mul_div, eq_div_iff hpos.ne']
  linear_combination hloop

/-- Step 5. Gain times bandwidth stays fixed. Give the op-amp one lag,
`A(s) = A₀/(1 + s/ω_a)`, with `A₀ ≥ 0`, `β ≥ 0`, corner `ω_a > 0`, and `s` away from the
op-amp's own pole `-ω_a`. Then the closed loop `A(s)/(1 + A(s) β)` is one lag again, with gain
`A₀/(1 + A₀β)` and corner `ω_a (1 + A₀β)`, and the gain times the corner is `A₀ ω_a`, the same
whatever the resistors. -/
theorem closed_loop_one_lag_gain_bandwidth (A0 β ωa : ℝ) (s : ℂ) (hA0 : 0 ≤ A0) (hβ : 0 ≤ β)
    (hωa : 0 < ωa) (hs : s ≠ -(ωa : ℂ)) :
    ((A0 : ℂ) / (1 + s / ωa)) / (1 + (A0 : ℂ) / (1 + s / ωa) * β)
        = ((A0 : ℂ) / (1 + A0 * β)) * (1 / (1 + s / (ωa * (1 + A0 * β)))) ∧
      A0 / (1 + A0 * β) * (ωa * (1 + A0 * β)) = A0 * ωa := by
  have hk : (0 : ℝ) < 1 + A0 * β := by nlinarith [mul_nonneg hA0 hβ]
  have hωc : (ωa : ℂ) ≠ 0 := by exact_mod_cast hωa.ne'
  have hkc : (1 + (A0 : ℂ) * β) ≠ 0 := by exact_mod_cast hk.ne'
  have hu : (1 + s / ωa) ≠ 0 := by
    intro h
    apply hs
    field_simp at h
    linear_combination h
  refine ⟨?_, ?_⟩
  · have e1 : (1 + s / ωa) = (ωa + s) / ωa := by field_simp
    have e2 : (1 + s / (ωa * (1 + A0 * β))) = (ωa * (1 + A0 * β) + s) / (ωa * (1 + A0 * β)) := by
      field_simp
    have hws : (ωa : ℂ) + s ≠ 0 := by
      intro h; apply hs; linear_combination h
    rw [e1, e2]
    by_cases hD : (ωa : ℂ) * (1 + A0 * β) + s = 0
    · have hD' : (1 + (A0 : ℂ) / ((ωa + s) / ωa) * β) = 0 := by
        field_simp
        linear_combination hD
      rw [hD', hD]; simp
    · have hD' : (1 + (A0 : ℂ) / ((ωa + s) / ωa) * β) ≠ 0 := by
        intro h; apply hD
        field_simp at h
        linear_combination h
      have hD2 : (A0 : ℂ) * ωa * β + ωa + s ≠ 0 := by
        intro h; apply hD; linear_combination h
      rw [div_eq_iff hD']
      field_simp
      ring
  · field_simp

-- The audio stage: R_f = 90 kΩ, R_1 = 10 kΩ, A₀ = 100,000, f_T = 1 MHz.
example : (10 : ℚ) / (10 + 90) = 1 / 10 := by norm_num
example : 1 + (90 : ℚ) / 10 = 10 := by norm_num
example : (100000 : ℚ) * (1 / 10) = 10000 := by norm_num
example : (100000 : ℚ) / (1 + 100000 * (1 / 10)) = 100000 / 10001 := by norm_num
example : (9999 : ℚ) / 1000 < 100000 / 10001 ∧ (100000 : ℚ) / 10001 < 10 := by norm_num
example : (50000 : ℚ) / (1 + 50000 * (1 / 10)) = 50000 / 5001 := by norm_num
-- Inverting stage with the same resistors: ideal -9, finite gain -9 · Aβ/(1 + Aβ).
example : -(90 : ℚ) / 10 = -9 := by norm_num
example : -(90 : ℚ) / 10 * (10000 / (1 + 10000)) = -90000 / 10001 := by norm_num
-- Bandwidth: f_a = 1,000,000/100,000 = 10 Hz, f_CL = 10 · 10,001 = 100,010 Hz, gain × f_CL = 1 MHz.
example : (1000000 : ℚ) / 100000 = 10 := by norm_num
example : (10 : ℚ) * (1 + 100000 * (1 / 10)) = 100010 := by norm_num
example : (100000 : ℚ) / 10001 * 100010 = 1000000 := by norm_num
-- Inputs swapped: the formula -A/(1 - Aβ) still gives a tidy 100,000/9,999, about 10.0010.
example : -(100000 : ℚ) / (1 - 100000 * (1 / 10)) = 100000 / 9999 := by norm_num

#print axioms closed_loop_gain_tendsto_one_add_ratio
#print axioms noninverting_loop_solution
#print axioms closed_loop_one_lag_gain_bandwidth
