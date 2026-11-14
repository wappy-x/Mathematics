-- Magnetic fields: in the long-coil model the induced voltage is minus the inductance mu0 N^2 A / l times the rate the current changes, and the Lorentz force never does work on a moving charge.
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.LinearAlgebra.CrossProduct

open Matrix

/-- Faraday's law for the long coil: with field `B = μ₀ (N/ℓ) I(t)` inside, flux `Φ = B A`
through each turn, and flux linkage `N Φ`, the induced voltage `-d(N Φ)/dt` equals
`-L dI/dt` with inductance `L = μ₀ N² A / ℓ`, whenever the current has a finite rate of
change `dI/dt` at that moment. -/
theorem emf_eq_neg_inductance_mul_rate (μ₀ N ℓ A : ℝ) (I : ℝ → ℝ) (I' t : ℝ)
    (hI : HasDerivAt I I' t) :
    HasDerivAt (fun s => -(N * ((μ₀ * (N / ℓ) * I s) * A))) (-(μ₀ * N ^ 2 * A / ℓ) * I') t := by
  have h : HasDerivAt (fun s => -(N * ((μ₀ * (N / ℓ) * I s) * A)))
      (-(N * ((μ₀ * (N / ℓ) * I') * A))) t :=
    HasDerivAt.neg (((hI.const_mul (μ₀ * (N / ℓ))).mul_const A).const_mul N)
  rw [show -(μ₀ * N ^ 2 * A / ℓ) * I' = -(N * ((μ₀ * (N / ℓ) * I') * A)) by ring]
  exact h

/-- Inductance is flux linkage per amp: for any nonzero current `I`, the linkage
`N Φ = N (μ₀ (N/ℓ) I) A` divided by `I` is `μ₀ N² A / ℓ`, whatever the current. -/
theorem inductance_eq_flux_linkage_div_current (μ₀ N ℓ A I : ℝ) (hI : I ≠ 0) :
    N * ((μ₀ * (N / ℓ) * I) * A) / I = μ₀ * N ^ 2 * A / ℓ := by
  rw [show N * ((μ₀ * (N / ℓ) * I) * A) = (μ₀ * N ^ 2 * A / ℓ) * I by ring,
    mul_div_assoc, div_self hI, mul_one]

/-- The Lorentz force `F = q v × B` is square to the velocity: its power `F · v` is zero,
so it bends the path and never speeds the charge up. -/
theorem lorentz_force_dot_velocity_eq_zero (q : ℝ) (v B : Fin 3 → ℝ) :
    (q • crossProduct v B) ⬝ᵥ v = 0 := by
  rw [smul_dotProduct, dotProduct_comm, dot_self_cross, smul_zero]

-- turns per metre: 1000 turns on 0.25 m
example : (1000 : ℚ) / (1 / 4) = 4000 := by norm_num
-- Ampère loop: a 75 mm rectangle holds 300 turns, carrying 900 A in all
example : (4000 : ℚ) * (75 / 1000) = 300 := by norm_num
example : (300 : ℚ) * 3 = 900 := by norm_num
-- rate of fall: 3 A in 10 ms, 1 ms and 10 µs
example : (3 : ℚ) / (1 / 100) = 300 := by norm_num
example : (3 : ℚ) / (1 / 1000) = 3000 := by norm_num
example : (3 : ℚ) / (1 / 100000) = 300000 := by norm_num
-- doubling the turns quadruples N²; the diameter for the radius quadruples r²
example : ((2 * 1000 : ℕ) ^ 2) = 4 * 1000 ^ 2 := by norm_num
example : ((2 * 25 : ℕ) ^ 2) = 4 * 25 ^ 2 := by norm_num
-- flyback diode: the switch sees 12 V plus the 0.7 V diode drop
example : (12 : ℚ) + 7 / 10 = 127 / 10 := by norm_num

#print axioms emf_eq_neg_inductance_mul_rate
#print axioms inductance_eq_flux_linkage_div_current
#print axioms lorentz_force_dot_velocity_eq_zero
