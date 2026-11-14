-- Time delays: a delay multiplies a loop by a factor of size one that turns its phase back by frequency times delay, an exact Smith predictor takes the delay out of the loop's characteristic factor, and the shower loop's ultimate gain is pi tau / (2 theta).
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Complex

/-- A delay of `θ` seconds, seen at angular frequency `ω`, is the factor `e^(-jωθ)`.
Multiplying any loop value `z = L(jω)` by it leaves the size unchanged and turns the
phase back by exactly `ωθ`: the result is `|z| e^(j(arg z - ωθ))`. -/
theorem delay_keeps_gain_and_subtracts_phase (z : ℂ) (ω θ : ℝ) :
    ‖z * exp (-(ω * θ : ℝ) * I)‖ = ‖z‖ ∧
      z * exp (-(ω * θ : ℝ) * I) = (‖z‖ : ℂ) * exp (((arg z - ω * θ : ℝ) : ℂ) * I) := by
  have hn : ‖exp (-(ω * θ : ℝ) * I)‖ = 1 := by
    have : -((ω * θ : ℝ) : ℂ) * I = ((-(ω * θ) : ℝ) : ℂ) * I := by push_cast; ring
    rw [this]
    exact norm_exp_ofReal_mul_I _
  refine ⟨by rw [norm_mul, hn, mul_one], ?_⟩
  conv_lhs => rw [← norm_mul_exp_arg_mul_I z]
  rw [mul_assoc, ← Complex.exp_add]
  congr 2
  push_cast
  ring

/-- The Smith predictor with an exact model. The plant is `y = G0 e u` (mixer `G0`, delay
factor `e`); the controller `C` acts on the target `r` minus the fed-back signal
`y + Gm (1 - em) u`. If the model is right (`Gm = G0`, `em = e`), then
`(1 + C G0) y = C G0 e r`: the closed loop is `C G0 / (1 + C G0)` followed by the delay,
and the characteristic factor `1 + C G0` contains no delay. -/
theorem smith_predictor_moves_delay_outside_loop
    (C G0 Gm e em r u y : ℂ)
    (hplant : y = G0 * e * u)
    (hctrl : u = C * (r - (y + Gm * (1 - em) * u)))
    (hGm : Gm = G0) (hem : em = e) :
    (1 + C * G0) * y = C * G0 * e * r := by
  rw [hGm, hem] at hctrl
  linear_combination (1 + C * G0 - G0 * e * C) * hplant + G0 * e * hctrl

/-- The shower loop `L(jω) = Kp e^(-jωθ) / (jωτ)`, with mixer lag `τ > 0` and delay `θ > 0`.
At `ω180 = π / (2θ)` its phase is `-180°`, and the loop sits on the edge of oscillation
(`L(jω180) = -1`) exactly when `Kp = π τ / (2θ)`, the ultimate gain; the swing period
`2π / ω180` is `4θ`. -/
theorem shower_ultimate_gain (Kp τ θ : ℝ) (hτ : 0 < τ) (hθ : 0 < θ) :
    let ω := Real.pi / (2 * θ)
    ((Kp : ℂ) * exp (-(ω * θ : ℝ) * I) / (I * (ω : ℂ) * (τ : ℂ)) = -1 ↔
        Kp = Real.pi * τ / (2 * θ)) ∧
      2 * Real.pi / ω = 4 * θ := by
  intro ω
  have hθ' : (θ : ℝ) ≠ 0 := hθ.ne'
  have hωθ : ω * θ = Real.pi / 2 := by
    simp only [ω]; field_simp
  have hω : 0 < ω := by positivity
  have hE : exp (-(ω * θ : ℝ) * I) = -I := by
    rw [hωθ]
    have : -((Real.pi / 2 : ℝ) : ℂ) * I = ((-(Real.pi / 2) : ℝ) : ℂ) * I := by push_cast; ring
    rw [this, Complex.exp_mul_I]
    rw [← Complex.ofReal_cos, ← Complex.ofReal_sin, Real.cos_neg, Real.sin_neg, Real.cos_pi_div_two,
      Real.sin_pi_div_two]
    push_cast; ring
  have hωτ : (ω : ℂ) * (τ : ℂ) ≠ 0 := by
    have : ω * τ ≠ 0 := by positivity
    exact_mod_cast this
  have key : (Kp : ℂ) * exp (-(ω * θ : ℝ) * I) / (I * (ω : ℂ) * (τ : ℂ))
      = ((-(Kp / (ω * τ)) : ℝ) : ℂ) := by
    rw [hE]
    have hτ' : (τ : ℂ) ≠ 0 := by exact_mod_cast hτ.ne'
    have hω' : (ω : ℂ) ≠ 0 := by exact_mod_cast hω.ne'
    push_cast
    field_simp
  constructor
  · rw [key]
    constructor
    · intro h
      have h2 : -(Kp / (ω * τ)) = -1 := by exact_mod_cast h
      have h3 : Kp = ω * τ := by
        have : ω * τ ≠ 0 := by positivity
        field_simp at h2
        linarith
      rw [h3]; simp only [ω]; field_simp
    · intro h
      have : -(Kp / (ω * τ)) = -1 := by
        rw [h]; simp only [ω]; field_simp
      rw [this]; push_cast; ring
  · simp only [ω]; field_simp; ring

-- Worked numbers from the card (τ = 2 s, θ = 4 s, fast gain Kp = 2).
-- Fast crossover Kp / τ = 2 / 2 = 1 rad/s.
example : (2 : ℚ) / 2 = 1 := by norm_num
-- Swing period at the ultimate gain: 4θ = 4 × 4 = 16 s.
example : (4 : ℕ) * 4 = 16 := by decide
-- First-order Padé edge 2τ / θ = 2 × 2 / 4 = 1.
example : (2 : ℚ) * 2 / 4 = 1 := by norm_num

#print axioms delay_keeps_gain_and_subtracts_phase
#print axioms smith_predictor_moves_delay_outside_loop
#print axioms shower_ultimate_gain
