-- Precession: a level spinning axle turning steadily obeys torque = rate of change of angular momentum exactly when it turns at the rate m g d / (I₃ ω).
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.Deriv.Pi
import Mathlib.Analysis.Calculus.Deriv.Prod

open Matrix Real

/-- Helper: the derivative of a steadily turning level spin arrow plus a fixed vertical part. -/
theorem gyro_spin_arrow_hasDerivAt (I₃ ω Ωₜ c t : ℝ) :
    HasDerivAt
      (fun s : ℝ => (I₃ * ω) • ![cos (Ωₜ * s), sin (Ωₜ * s), 0] + ![0, 0, c])
      ((I₃ * ω * Ωₜ) • ![-sin (Ωₜ * t), cos (Ωₜ * t), 0]) t := by
  rw [hasDerivAt_pi]
  intro i
  fin_cases i
  · simp
    have h := ((hasDerivAt_id t).const_mul Ωₜ).cos.const_mul (I₃ * ω)
    convert h using 1
    · simp
    · simp; ring
  · simp
    have h := ((hasDerivAt_id t).const_mul Ωₜ).sin.const_mul (I₃ * ω)
    convert h using 1
    · simp
    · simp; ring
  · simp
    exact hasDerivAt_const t c

/-- Step 1: the weight `(0, 0, -m g)` hanging at the hub `(d, 0, 0)` has torque
`r × F = (0, m g d, 0)` about the string: horizontal, and square to both the axle
and the weight. -/
theorem weight_torque_is_sideways (m g d : ℝ) :
    crossProduct ![d, 0, 0] ![0, 0, -(m * g)] = ![0, m * g * d, 0] := by
  rw [cross_apply]
  ext i; fin_cases i <;> simp; ring

/-- The precession rate. A wheel with spin inertia `I₃ > 0` spins at a steady rate
`ω > 0` on a level axle that swings round the string at a steady rate `Ω`, so the axle
points along `(cos Ωt, sin Ωt, 0)`. Its angular momentum is the spin part `I₃ ω` along
the axle plus the turning part `I₁ Ω` straight up, and the weight `m g` acts at the hub,
a distance `d` out along the axle. Then torque equals the rate of change of angular
momentum at every moment exactly when `Ω = m g d / (I₃ ω)`, that is, `Ω = τ / L`. -/
theorem precession_rate_eq_torque_div_angular_momentum
    (m g d I₁ I₃ ω Ω : ℝ) (hI₃ : 0 < I₃) (hω : 0 < ω) :
    (∀ t : ℝ, HasDerivAt
        (fun s : ℝ => (I₃ * ω) • ![cos (Ω * s), sin (Ω * s), 0] + (I₁ * Ω) • ![0, 0, 1])
        (crossProduct (d • ![cos (Ω * t), sin (Ω * t), 0]) ![0, 0, -(m * g)]) t)
      ↔ Ω = m * g * d / (I₃ * ω) := by
  have hf : (fun s : ℝ => (I₃ * ω) • ![cos (Ω * s), sin (Ω * s), 0] + (I₁ * Ω) • ![0, 0, 1])
      = (fun s : ℝ => (I₃ * ω) • ![cos (Ω * s), sin (Ω * s), 0] + ![0, 0, I₁ * Ω]) := by
    funext s; ext i; fin_cases i <;> simp
  have hcross : ∀ t : ℝ, crossProduct (d • ![cos (Ω * t), sin (Ω * t), 0]) ![0, 0, -(m * g)]
      = (m * g * d) • ![-sin (Ω * t), cos (Ω * t), 0] := by
    intro t; rw [cross_apply]; ext i; fin_cases i <;> simp <;> ring
  have hpos : 0 < I₃ * ω := mul_pos hI₃ hω
  rw [hf]
  constructor
  · intro h
    have h0 := (h 0).unique (gyro_spin_arrow_hasDerivAt I₃ ω Ω (I₁ * Ω) 0)
    rw [hcross] at h0
    have h1 := congrFun h0 1
    simp at h1
    rw [eq_div_iff hpos.ne']
    linarith
  · intro hΩ t
    rw [hcross]
    have hk : m * g * d = I₃ * ω * Ω := by
      rw [hΩ]; field_simp
    rw [hk]
    exact gyro_spin_arrow_hasDerivAt I₃ ω Ω (I₁ * Ω) t

/-- Step 5, the stubborn wheel. Turning a spinning wheel's axle by hand at a steady rate
`Ωₜ` (with any fixed up part `c` of the angular momentum) changes the spin arrow at
the rate `L Ωₜ = I₃ ω Ωₜ`, pointing horizontally at right angles to the axle: that is
the torque the hands must supply. -/
theorem stubborn_wheel_torque (I₃ ω Ωₜ c t : ℝ) :
    HasDerivAt
      (fun s : ℝ => (I₃ * ω) • ![cos (Ωₜ * s), sin (Ωₜ * s), 0] + ![0, 0, c])
      ((I₃ * ω * Ωₜ) • ![-sin (Ωₜ * t), cos (Ωₜ * t), 0]) t := by
  exact gyro_spin_arrow_hasDerivAt I₃ ω Ωₜ c t

-- The card's inertias, exactly: a 2 kg hoop of rim radius 0.30 m has I₃ = m R² = 0.18,
-- and about the string 0.10 m away, I₁ = m R² / 2 + m d² = 0.11.
example : (2 : ℚ) * (3 / 10) ^ 2 = 18 / 100 := by norm_num
example : (1 / 2 : ℚ) * 2 * (3 / 10) ^ 2 + 2 * (1 / 10) ^ 2 = 11 / 100 := by norm_num

#print axioms gyro_spin_arrow_hasDerivAt
#print axioms weight_torque_is_sideways
#print axioms precession_rate_eq_torque_div_angular_momentum
#print axioms stubborn_wheel_torque
