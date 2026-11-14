-- Feedback: solving the loop equations gives every output as its forward path over one plus the loop gain, the reading over the dial as L over one plus L, and every closed-loop ratio as a polynomial over δ + n, so its poles are zeros of one plus L.
import Mathlib.FieldTheory.RatFunc.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.LinearCombination

open Polynomial

/-! Transfer functions are elements of a field `K`: the field of rational functions in `s`,
or their values at one `s` (for instance in `ℂ`). Each block is a multiplication, which is
what "linear, time-invariant, not loading each other, no delay" means in transforms, and the
junction subtracts the reading, which is the minus sign of the loop as drawn. -/

/-- The card's formula. The thermostat `C`, radiator `P_r`, room `P_m` and sensor `H` sit round
one loop with loop gain `L = C P_r P_m H`. The error is `E = R - M`, the reading is `M = H Y`,
and the room is `Y = (C P_r P_m) E + UA P_m D`. Then the room's change is the forward path from
the dial over one plus the loop gain, times the dial's change, plus the outside air's path
over the same one plus the loop gain, times the outside change; and seen at the sensor, the
dial's path is the loop gain over one plus the loop gain, `T = L/(1 + L)`. -/
theorem closed_loop_eq_forward_path_div_one_add_loop_gain {K : Type*} [Field K]
    (C Pr Pm H UA R D E M Y : K)
    (hE : E = R - M) (hM : M = H * Y) (hY : Y = C * Pr * Pm * E + UA * Pm * D)
    (hL : 1 + C * Pr * Pm * H ≠ 0) :
    Y = C * Pr * Pm / (1 + C * Pr * Pm * H) * R + UA * Pm / (1 + C * Pr * Pm * H) * D ∧
    M = C * Pr * Pm * H / (1 + C * Pr * Pm * H) * R
        + H * (UA * Pm) / (1 + C * Pr * Pm * H) * D := by
  have key : Y * (1 + C * Pr * Pm * H) = C * Pr * Pm * R + UA * Pm * D := by
    linear_combination hY + (C * Pr * Pm) * hE - (C * Pr * Pm) * hM
  have hY' : Y = C * Pr * Pm / (1 + C * Pr * Pm * H) * R + UA * Pm / (1 + C * Pr * Pm * H) * D := by
    rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div, eq_div_iff hL]
    exact key
  refine ⟨hY', ?_⟩
  rw [hM, hY']
  field_simp

/-- Any single loop. The loop carries blocks `B₁, B₂, …` with one minus sign, so the loop gain
`L` is the product of all of them. The signal `X` just before the injection point is the
injected `W` plus what comes back after one trip round the loop, `-L X`. An output `Z` is the
forward path `F` from the injection point times `X`. Then `X = W/(1 + L)` and
`Z = F W/(1 + L)`: every input to every output is its forward path over one plus the loop. -/
theorem single_loop_output_eq_forward_path_div_one_add_loop {K : Type*} [Field K]
    (B : List K) (W X F Z : K)
    (hX : X = W - B.prod * X) (hZ : Z = F * X) (hL : 1 + B.prod ≠ 0) :
    X = W / (1 + B.prod) ∧ Z = F * W / (1 + B.prod) := by
  have hX' : X = W / (1 + B.prod) := by
    rw [eq_div_iff hL]
    linear_combination hX
  refine ⟨hX', ?_⟩
  rw [hZ, hX', mul_div_assoc]

/-- Poles are zeros of one plus L. Write the loop gain as `L = n/δ` and a forward path as
`F = n_F/δ_F`, with numerators and denominators the products of the blocks' own, nothing
cancelled. Then `1 + L = (δ + n)/δ`, and since every block of `F` is a block of `L`
(`δ_F` divides `δ`), the closed-loop ratio `F/(1 + L)` is a polynomial over `δ + n`. -/
theorem closed_loop_ratio_eq_polynomial_div_delta_add_n {K : Type*} [Field K]
    (n δ nF δF : K[X]) (hδ : δ ≠ 0) (hdiv : δF ∣ δ) :
    1 + algebraMap K[X] (RatFunc K) n / algebraMap K[X] (RatFunc K) δ
        = algebraMap K[X] (RatFunc K) (δ + n) / algebraMap K[X] (RatFunc K) δ ∧
    ∃ q : K[X],
      (algebraMap K[X] (RatFunc K) nF / algebraMap K[X] (RatFunc K) δF)
          / (1 + algebraMap K[X] (RatFunc K) n / algebraMap K[X] (RatFunc K) δ)
        = algebraMap K[X] (RatFunc K) q / algebraMap K[X] (RatFunc K) (δ + n) := by
  obtain ⟨k, hk⟩ := hdiv
  have hinj := IsFractionRing.injective K[X] (RatFunc K)
  have hδ' : algebraMap K[X] (RatFunc K) δ ≠ 0 := by
    rw [Ne, ← map_zero (algebraMap K[X] (RatFunc K))]
    exact fun h => hδ (hinj h)
  have hδF : δF ≠ 0 := by
    rintro rfl; exact hδ (by simp [hk])
  have hδF' : algebraMap K[X] (RatFunc K) δF ≠ 0 := by
    rw [Ne, ← map_zero (algebraMap K[X] (RatFunc K))]
    exact fun h => hδF (hinj h)
  have h1 : 1 + algebraMap K[X] (RatFunc K) n / algebraMap K[X] (RatFunc K) δ
        = algebraMap K[X] (RatFunc K) (δ + n) / algebraMap K[X] (RatFunc K) δ := by
    rw [map_add, add_div, div_self hδ']
  refine ⟨h1, nF * k, ?_⟩
  rw [h1, div_div_eq_mul_div, map_mul, hk, map_mul]
  rw [div_mul_eq_mul_div, div_div, ← mul_assoc,
    mul_comm (algebraMap K[X] (RatFunc K) δF) (algebraMap K[X] (RatFunc K) (δF * k + n)),
    mul_right_comm _ (algebraMap K[X] (RatFunc K) δF), mul_div_mul_right _ _ hδF']

/-- The card's closed-loop denominator: `(5s+1)(20s+1)(s+1) + 5 = 100 s³ + 125 s² + 26 s + 6`. -/
example : ((5 * X + 1) * (20 * X + 1) * (X + 1) + 5 : ℤ[X])
    = 100 * X ^ 3 + 125 * X ^ 2 + 26 * X + 6 := by
  ring

/-- The open-loop denominator multiplied out: `δ = 100 s³ + 125 s² + 26 s + 1`. -/
example : ((5 * X + 1) * (20 * X + 1) * (X + 1) : ℤ[X])
    = 100 * X ^ 3 + 125 * X ^ 2 + 26 * X + 1 := by
  ring

/-- Loop gain at `s = 0`: 500 W/K × 1 × 0.01 K/W × 1 = 5. -/
example : (500 : ℚ) * 1 * (1 / 100) * 1 = 5 := by norm_num

/-- Steady state at `k = 5`: room over dial `5/(1+5) = 5/6`, error `1/(1+5) = 1/6`, outside air
to room `UA P_m(0)/(1+5) = 1/6`, so a −5 °C cold snap costs `−5/6` °C. -/
example : (5 : ℚ) / (1 + 5) = 5 / 6 ∧ (1 : ℚ) / (1 + 5) = 1 / 6 ∧
    (100 : ℚ) * (1 / 100) / (1 + 5) = 1 / 6 ∧ (-5 : ℚ) / (1 + 5) = -5 / 6 := by
  norm_num

/-- The stability bound: `125 × 26 / 100 − 1 = 31.5`, also `(5+20+1)(1/5+1/20+1) − 1`, a
thermostat gain of 3150 W/K; and `k = 5` passes the test `125 × 26 > 100 × (1 + k)`. -/
example : (125 : ℚ) * 26 / 100 - 1 = 63 / 2 ∧
    ((5 : ℚ) + 20 + 1) * (1 / 5 + 1 / 20 + 1) - 1 = 63 / 2 ∧
    (63 / 2 : ℚ) * 100 = 3150 ∧ (125 : ℚ) * 26 > 100 * (1 + 5) := by
  norm_num

/-- Wired backwards, `L/(1 − L)` at `s = 0` reads `5/(1 − 5) = −1.25`. -/
example : (5 : ℚ) / (1 - 5) = -5 / 4 := by norm_num

#print axioms closed_loop_eq_forward_path_div_one_add_loop_gain
#print axioms single_loop_output_eq_forward_path_div_one_add_loop
#print axioms closed_loop_ratio_eq_polynomial_div_delta_add_n
