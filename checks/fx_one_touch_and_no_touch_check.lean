-- One-touch and no-touch: a one-touch plus a no-touch paid at the same date is always one discounted dollar in any model, discounting the first-touch density at the touch gives the same density with the tilted drift, and the mirror weight e^(2νb/σ²) equals (H/S)^(2λ).
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory Real
open scoped NNReal

/-! Notation. `S` is EURUSD today in dollars per euro, `H` the wall, `r_d` and `r_f` the dollar
and euro rates (continuously compounded), `σ` the volatility and `T` the years to expiry.
In the dollar pricing world the log rate `X_t = ln(S_t/S)` drifts at `ν = r_d - r_f - σ²/2`,
`b = ln(H/S)` is the wall on the log scale, and `λ = ν/σ²`.

The card's mirror formula for the touch chance,
`P(τ ≤ T) = N((νT - b)/(σ√T)) + (H/S)^(2λ) N((-b - νT)/(σ√T))`, is not stated here: its proof
needs the reflection principle (the law of the running maximum of Brownian motion with drift),
which Mathlib does not have. The card's Python and Rust checks cover it, against the
first-touch-time integral and a simulation. -/

/-- **The no-touch is the discount factor minus the one-touch, in every model** (Step 7). Whatever
the EURUSD paths `X` and the pricing measure `P`, and whatever the monitoring rule (the set `M` of
times at which the wall is checked), as long as both contracts use the same rule and pay one dollar
at expiry: the no-touch, `e^(-r_d T)` times the chance of no touch, equals `e^(-r_d T)` minus the
one-touch, `e^(-r_d T)` times the chance of a touch. -/
theorem no_touch_eq_discount_sub_one_touch
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℝ≥0 → Ω → ℝ) (M : Set ℝ≥0) (H rd : ℝ) (T : ℝ≥0)
    (hmeas : NullMeasurableSet {ω | ∃ t ∈ M, t ≤ T ∧ H ≤ X t ω} P) :
    Real.exp (-rd * T) * P.real {ω | ¬ ∃ t ∈ M, t ≤ T ∧ H ≤ X t ω} =
      Real.exp (-rd * T) - Real.exp (-rd * T) * P.real {ω | ∃ t ∈ M, t ≤ T ∧ H ≤ X t ω} := by
  have h := probReal_compl_eq_one_sub₀ hmeas
  have e : {ω | ¬ ∃ t ∈ M, t ≤ T ∧ H ≤ X t ω} = {ω | ∃ t ∈ M, t ≤ T ∧ H ≤ X t ω}ᶜ := rfl
  rw [e, h]; ring

/-- **Paying at the touch tilts the drift** (Step 5). When the tilted drift is real,
`ν² + 2 r_d σ² ≥ 0`, put `ν̂ = √(ν² + 2 r_d σ²)`. Then the first-touch density of the log level
`b` with drift `ν`, `f_ν(t) = b / (σ √(2π t³)) · exp(-(b - ν t)² / (2σ² t))`, discounted by
`e^(-r_d t)`, is the constant `e^((ν - ν̂) b/σ²) = (H/S)^((ν - ν̂)/σ²)` times the same density with
drift `ν̂`. Adding it up over `0..T` gives the pay-at-hit one-touch
`(H/S)^((ν - ν̂)/σ²) P_ν̂(τ ≤ T)`. -/
theorem discounted_first_touch_density_tilted_drift
    (b ν rd σ t : ℝ) (htilt : 0 ≤ ν ^ 2 + 2 * rd * σ ^ 2) (hσ : 0 < σ) (ht : 0 < t) :
    let νh := Real.sqrt (ν ^ 2 + 2 * rd * σ ^ 2)
    Real.exp (-rd * t) *
        (b / (σ * Real.sqrt (2 * π * t ^ 3)) * Real.exp (-(b - ν * t) ^ 2 / (2 * σ ^ 2 * t))) =
      Real.exp ((ν - νh) * b / σ ^ 2) *
        (b / (σ * Real.sqrt (2 * π * t ^ 3)) * Real.exp (-(b - νh * t) ^ 2 / (2 * σ ^ 2 * t))) := by
  intro νh
  have hsq : νh ^ 2 = ν ^ 2 + 2 * rd * σ ^ 2 := Real.sq_sqrt htilt
  have key : -rd * t + -(b - ν * t) ^ 2 / (2 * σ ^ 2 * t) =
      (ν - νh) * b / σ ^ 2 + -(b - νh * t) ^ 2 / (2 * σ ^ 2 * t) := by
    field_simp
    linear_combination (t ^ 2) * hsq
  calc _ = b / (σ * Real.sqrt (2 * π * t ^ 3)) *
        Real.exp (-rd * t + -(b - ν * t) ^ 2 / (2 * σ ^ 2 * t)) := by rw [Real.exp_add]; ring
    _ = _ := by rw [key, Real.exp_add]; ring

/-- **The mirror weight on the price scale** (The formula; Step 4). With today's rate `S > 0`, a
wall `H > 0`, `b = ln(H/S)` and `λ = ν/σ²`, the Girsanov weight on the mirror term,
`e^(2νb/σ²)`, is exactly `(H/S)^(2λ)`. -/
theorem mirror_weight_exp_eq_rpow
    (S H ν σ : ℝ) (hS : 0 < S) (hH : 0 < H) :
    Real.exp (2 * ν * Real.log (H / S) / σ ^ 2) = (H / S) ^ (2 * (ν / σ ^ 2)) := by
  rw [Real.rpow_def_of_pos (div_pos hH hS)]
  congr 1
  ring

-- The house market, exact fractions: r_d = 5%, r_f = 3%, σ = 10%.
-- Drift in dollars ν = 0.05 - 0.03 - 0.005 = 0.015.
example : (5 / 100 : ℚ) - 3 / 100 - (1 / 10) ^ 2 / 2 = 3 / 200 := by norm_num
-- Drift in euros ν_f = ν + σ² = 0.025.
example : (5 / 100 : ℚ) - 3 / 100 + (1 / 10) ^ 2 / 2 = 1 / 40 := by norm_num
-- λ = ν/σ² = 1.5, so the mirror weight's exponent 2λ is 3.
example : (3 / 200 : ℚ) / (1 / 10) ^ 2 = 3 / 2 := by norm_num
-- Mirror weight (1.20/1.10)^3 = 1728/1331 (about 1.298272).
example : ((6 / 5 : ℚ) / (11 / 10)) ^ 3 = 1728 / 1331 := by norm_num
-- Tilted drift: ν² + 2 r_d σ² = 0.000225 + 0.001 = 0.035², so ν̂ = 0.035.
example : (3 / 200 : ℚ) ^ 2 + 2 * (5 / 100) * (1 / 10) ^ 2 = (7 / 200) ^ 2 := by norm_num
-- Pay-at-hit exponent (ν - ν̂)/σ² = -2, so the factor is (1.10/1.20)^2.
example : ((3 / 200 : ℚ) - 7 / 200) / (1 / 10) ^ 2 = -2 := by norm_num
-- The payoff picture, in hundredths of a dollar per euro: at every year's high on the chart,
-- the one-touch at 1.20 plus the no-touch pays exactly 1.
example : ∀ h ∈ [110, 112, 114, 116, 118, 120, 122, 124, 126],
    (if 120 ≤ h then 1 else 0) + (if 120 ≤ h then 0 else 1) = 1 := by decide

#print axioms no_touch_eq_discount_sub_one_touch
#print axioms discounted_first_touch_density_tilted_drift
#print axioms mirror_weight_exp_eq_rpow
