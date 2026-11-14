-- Convection and radiation: the radiation loss εσ(Ts⁴ - Tsur⁴) is exactly a coefficient h_r = εσ(Ts + Tsur)(Ts² + Tsur²) times the temperature lead, so a warm panel's output is area times two coefficient-times-lead fluxes, and straightening the fourth power at the wall or mean temperature always comes out low.
import Mathlib.Data.Real.Basic
import Mathlib.Order.Monotone.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-- Two routes in parallel, radiation in convection's shape. A surface of area `A > 0` at
absolute temperature `Ts` leads the room air at `Tinf` and the walls at `Tsur > 0` (all in
kelvin, `Tinf < Ts`, `Tsur < Ts`). It loses heat by convection with coefficient `h ≥ 0` and by
radiation with emissivity `ε > 0` and Stefan–Boltzmann constant `σ > 0`, so its output is
`Q = A [h (Ts - Tinf) + ε σ (Ts⁴ - Tsur⁴)]`. Then the radiation part is exactly a radiation
coefficient `h_r = ε σ (Ts + Tsur)(Ts² + Tsur²)` times the lead over the walls, so
`Q = A [h (Ts - Tinf) + h_r (Ts - Tsur)]`; that coefficient is positive, and the output is
positive. -/
theorem output_eq_area_times_convection_plus_radiation_coefficient
    (A h ε σ Ts Tinf Tsur : ℝ) (hA : 0 < A) (hh : 0 ≤ h) (hε : 0 < ε) (hσ : 0 < σ)
    (hTsur : 0 < Tsur) (hinf : Tinf < Ts) (hsur : Tsur < Ts) :
    let hr := ε * σ * (Ts + Tsur) * (Ts ^ 2 + Tsur ^ 2)
    let Q := A * (h * (Ts - Tinf) + ε * σ * (Ts ^ 4 - Tsur ^ 4))
    Q = A * (h * (Ts - Tinf) + hr * (Ts - Tsur)) ∧ 0 < hr ∧ 0 < Q := by
  intro hr Q
  have hTs : 0 < Ts := lt_trans hTsur hsur
  have heq : Q = A * (h * (Ts - Tinf) + hr * (Ts - Tsur)) := by
    simp only [Q, hr]; ring
  have hhr : 0 < hr := by simp only [hr]; positivity
  refine ⟨heq, hhr, ?_⟩
  rw [heq]
  have h1 : 0 ≤ h * (Ts - Tinf) := mul_nonneg hh (by linarith)
  have h2 : 0 < hr * (Ts - Tsur) := mul_pos hhr (by linarith)
  exact mul_pos hA (by linarith)

/-- Straightening the fourth power comes out low. For wall temperature `Tsur > 0` below the
surface temperature `Ts`, with `ε > 0` and `σ > 0`, the straight line taken at the wall
temperature, `4 ε σ Tsur³`, is below the one taken at the mean temperature
`Tm = (Ts + Tsur)/2`, `4 ε σ Tm³`, and that is below the true radiation coefficient
`h_r = ε σ (Ts + Tsur)(Ts² + Tsur²)`. -/
theorem straightened_radiation_coefficient_lt_true
    (ε σ Ts Tsur : ℝ) (hε : 0 < ε) (hσ : 0 < σ) (hTsur : 0 < Tsur) (hsur : Tsur < Ts) :
    4 * ε * σ * Tsur ^ 3 < 4 * ε * σ * ((Ts + Tsur) / 2) ^ 3 ∧
      4 * ε * σ * ((Ts + Tsur) / 2) ^ 3 < ε * σ * (Ts + Tsur) * (Ts ^ 2 + Tsur ^ 2) := by
  have hTs : 0 < Ts := lt_trans hTsur hsur
  have hes : 0 < ε * σ := mul_pos hε hσ
  have hlt : Tsur < (Ts + Tsur) / 2 := by linarith
  have hcube : Tsur ^ 3 < ((Ts + Tsur) / 2) ^ 3 :=
    pow_lt_pow_left₀ hlt hTsur.le (by norm_num)
  have hsum : 0 < Ts + Tsur := by linarith
  have hsq : 0 < (Ts - Tsur) ^ 2 := by
    have : Ts - Tsur ≠ 0 := by linarith
    positivity
  have key : 4 * ((Ts + Tsur) / 2) ^ 3 < (Ts + Tsur) * (Ts ^ 2 + Tsur ^ 2) := by
    nlinarith [mul_pos hsum hsq]
  constructor
  · have := mul_lt_mul_of_pos_left hcube (mul_pos (by norm_num : (0:ℝ) < 4) hes)
    linarith
  · have := mul_lt_mul_of_pos_left key hes
    linarith

/-- The radiation loss only rises with the surface temperature. With `ε > 0` and `σ > 0`,
the net radiation flux `ε σ (Ts⁴ - Tsur⁴)` is strictly increasing in the absolute surface
temperature `Ts ≥ 0`; this is what lets bisection turn the balance round. -/
theorem radiation_flux_strictMonoOn (ε σ Tsur : ℝ) (hε : 0 < ε) (hσ : 0 < σ) :
    StrictMonoOn (fun Ts : ℝ => ε * σ * (Ts ^ 4 - Tsur ^ 4)) (Set.Ici 0) := by
  intro a ha b hb hab
  have ha' : (0 : ℝ) ≤ a := ha
  have h4 : a ^ 4 < b ^ 4 := pow_lt_pow_left₀ hab ha' (by norm_num)
  show ε * σ * (a ^ 4 - Tsur ^ 4) < ε * σ * (b ^ 4 - Tsur ^ 4)
  exact mul_lt_mul_of_pos_left (by linarith) (mul_pos hε hσ)

-- The card's whole-number steps, temperatures in hundredths of a kelvin.
-- 60 °C = 333.15 K and 20 °C = 293.15 K: the surface leads the room by 40 K.
example : (33315 : ℤ) - 29315 = 4000 := by norm_num
-- Film temperature: (60 + 20)/2 + 273.15 = 313.15 K.
example : ((60 : ℚ) + 20) / 2 + 27315 / 100 = 31315 / 100 := by norm_num
-- Step 4's factoring of the fourth powers, at the card's own temperatures.
example : (33315 : ℤ) ^ 4 - 29315 ^ 4
    = (33315 - 29315) * (33315 + 29315) * (33315 ^ 2 + 29315 ^ 2) := by norm_num
-- The Celsius mistake: 60⁴ - 20⁴ = 12,800,000, while in kelvin the difference is far larger.
example : (60 : ℤ) ^ 4 - 20 ^ 4 = 12800000 := by norm_num
example : (60 : ℤ) ^ 4 - 20 ^ 4 < ((33315 : ℤ) ^ 4 - 29315 ^ 4) / 100 ^ 4 := by norm_num
-- Area of both faces: 2 × 0.60 m × 1.00 m = 1.2 m².
example : (2 : ℚ) * (6 / 10) * 1 = 6 / 5 := by norm_num

#print axioms output_eq_area_times_convection_plus_radiation_coefficient
#print axioms straightened_radiation_coefficient_lt_true
#print axioms radiation_flux_strictMonoOn
