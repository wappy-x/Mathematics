-- Adaptive steps: the gap between an order-(p+1) and an order-p answer equals the order-p error to leading order, step doubling's fine error is the gap over 2^p - 1, and the step rule lands the leading error on the allowance.
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Filter.Basic

open Asymptotics Filter Topology

/-- Two answers of different accuracy for the same step differ by about the error of the
worse one: if the order-p answer `v4 h` has error `C h^(p+1) + O(h^(p+2))` against the exact
value `u h` and the order-(p+1) answer `v5 h` has error `O(h^(p+2))`, then the gap
`v4 h - v5 h` is `C h^(p+1) + O(h^(p+2))`, as the step length `h` goes to 0. -/
theorem pair_gap_eq_lower_order_error_to_leading_order
    (p : ℕ) (C : ℝ) (u v4 v5 : ℝ → ℝ)
    (h4 : (fun h => v4 h - u h - C * h ^ (p + 1)) =O[𝓝 0] (fun h => h ^ (p + 2)))
    (h5 : (fun h => v5 h - u h) =O[𝓝 0] (fun h => h ^ (p + 2))) :
    (fun h => (v4 h - v5 h) - C * h ^ (p + 1)) =O[𝓝 0] (fun h => h ^ (p + 2)) := by
  exact (h4.sub h5).congr_left (fun h => by ring)

/-- Step doubling: if one step of length `h` has error `C h^(p+1) + O(h^(p+2))` and two half
steps have the two half-step errors added, `2 C (h/2)^(p+1) + O(h^(p+2))`, then the fine
answer's error is the coarse-minus-fine gap divided by `2^p - 1`, up to `O(h^(p+2))`. -/
theorem step_doubling_fine_error_eq_gap_div
    (p : ℕ) (hp : 0 < p) (C : ℝ) (u Yc Yf : ℝ → ℝ)
    (hc : (fun h => Yc h - u h - C * h ^ (p + 1)) =O[𝓝 0] (fun h => h ^ (p + 2)))
    (hf : (fun h => Yf h - u h - 2 * C * (h / 2) ^ (p + 1)) =O[𝓝 0] (fun h => h ^ (p + 2))) :
    (fun h => (Yf h - u h) - (Yc h - Yf h) / (2 ^ p - 1)) =O[𝓝 0] (fun h => h ^ (p + 2)) := by
  have h2 : (2 : ℝ) ^ p - 1 ≠ 0 := by
    have : (2 : ℝ) ≤ 2 ^ p := by
      calc (2 : ℝ) = 2 ^ 1 := by norm_num
        _ ≤ 2 ^ p := pow_le_pow_right₀ (by norm_num) hp
    linarith
  refine (hf.sub ((hc.sub hf).const_mul_left (1 / (2 ^ p - 1)))).congr_left (fun h => ?_)
  have e : (h / 2) ^ (p + 1) = h ^ (p + 1) / (2 ^ p * 2) := by rw [div_pow, pow_succ 2]
  rw [e]
  field_simp
  ring

/-- The step rule: if the estimate is `E = C h^(p+1)` and the constant `C` stays the same,
the new length `h (τ/E)^(1/(p+1))` makes the leading error exactly the allowance `τ`. -/
theorem step_rule_hits_allowance
    (p : ℕ) (C h τ : ℝ) (hC : 0 < C) (hh : 0 < h) (hτ : 0 < τ) :
    C * (h * (τ / (C * h ^ (p + 1))) ^ (1 / ((p : ℝ) + 1))) ^ (p + 1) = τ := by
  have hE : 0 ≤ τ / (C * h ^ (p + 1)) := by positivity
  have hx : (1 / ((p : ℝ) + 1)) = ((p + 1 : ℕ) : ℝ)⁻¹ := by push_cast; ring
  rw [mul_pow, hx, Real.rpow_inv_natCast_pow hE (by omega)]
  have : h ^ (p + 1) ≠ 0 := by positivity
  field_simp

-- The pair's gap per unit of 49 - v at z = -0.2: D(-1/5) = 2.8e-7 exactly.
example : -(97 : ℚ) / 120000 * (-1 / 5) ^ 5 + 39 / 120000 * (-1 / 5) ^ 6
    - 5 / 120000 * (-1 / 5) ^ 7 = 7 / 25000000 := by norm_num

-- The first estimate: 49 × D(-1/5) = 1.372e-5 m/s.
example : (49 : ℚ) * (7 / 25000000) = 343 / 25000000 := by norm_num

-- The order-4 member's z^5 coefficient, 1/120 - (-97/120000) = 1097/120000.
example : (1 : ℚ) / 120 + 97 / 120000 = 1097 / 120000 := by norm_num

-- Step doubling with Runge-Kutta four divides by 2^4 - 1 = 15; the mistake uses 2^5 - 1 = 31.
example : 2 ^ 4 - 1 = 15 ∧ 2 ^ 5 - 1 = 31 := by decide

#print axioms pair_gap_eq_lower_order_error_to_leading_order
#print axioms step_doubling_fine_error_eq_gap_div
#print axioms step_rule_hits_allowance
