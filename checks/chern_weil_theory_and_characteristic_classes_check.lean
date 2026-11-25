-- Chern-Weil: the monopole bundle's curvature over the globe integrates to exactly one turn, adding the card's global one-form to its connection leaves that total at exactly one, and det(I + tX) does not change when X is replaced by g⁻¹Xg.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum

open Real Matrix

namespace ChernWeil

/-! On the globe, `φ` is the angle down from the North Pole (0 to π) and `θ` the longitude east
(0 to 2π). A two-form `f(φ, θ) dφ ∧ dθ` is integrated over the globe as the iterated integral of
its density `f` over these ranges. The monopole curvature is `F = ½ sin φ dφ ∧ dθ`; its first
Chern number is the integral of `F / 2π`. -/

/-- The monopole (Hopf) line bundle over the globe has first Chern number 1: its curvature
`F = ½ sin φ dφ ∧ dθ`, divided by `2π` and integrated over the whole globe, gives exactly one
turn, `(1/4π) × 2 × 2π = 1`. -/
theorem monopole_first_chern_number_eq_one :
    (1 / (2 * π)) * ∫ θ in (0 : ℝ)..2 * π, ∫ φ in (0 : ℝ)..π, (1 / 2) * sin φ = 1 := by
  rw [intervalIntegral.integral_const_mul, integral_sin]
  simp only [cos_zero, cos_pi, intervalIntegral.integral_const, smul_eq_mul]
  field_simp
  ring

/-- Changing the connection does not change the Chern number. Adding the card's global one-form
`b = ½ (z (x dy − y dx) + x (y dz − z dy))` to the monopole connection changes the curvature density
from `½ sin φ` to `½ sin φ (1 + x² − 2y² + z²)`, with `x = sin φ cos θ`, `y = sin φ sin θ`,
`z = cos φ` the globe's coordinates; the curvature moves from point to point, but its integral
over the globe, divided by `2π`, is still exactly 1. -/
theorem first_chern_number_unchanged_by_new_connection :
    (1 / (2 * π)) * ∫ θ in (0 : ℝ)..2 * π, ∫ φ in (0 : ℝ)..π,
      (1 / 2) * sin φ * (1 + (sin φ * cos θ) ^ 2 - 2 * (sin φ * sin θ) ^ 2 + cos φ ^ 2) = 1 := by
  have hin : ∀ θ : ℝ, (∫ φ in (0 : ℝ)..π,
      (1 / 2) * sin φ * (1 + (sin φ * cos θ) ^ 2 - 2 * (sin φ * sin θ) ^ 2 + cos φ ^ 2))
      = 2 * cos θ ^ 2 := by
    intro θ
    have hpt : ∀ φ : ℝ,
        (1 / 2) * sin φ * (1 + (sin φ * cos θ) ^ 2 - 2 * (sin φ * sin θ) ^ 2 + cos φ ^ 2)
          = sin φ - (3 / 2 * sin θ ^ 2) * sin φ ^ 3 := by
      intro φ
      have hφ := sin_sq_add_cos_sq φ
      have hθ := sin_sq_add_cos_sq θ
      linear_combination (1 / 2 * sin φ) * hφ + (1 / 2 * sin φ * sin φ ^ 2) * hθ
    simp_rw [hpt]
    rw [intervalIntegral.integral_sub, intervalIntegral.integral_const_mul, integral_sin,
      integral_sin_pow_three]
    · simp only [cos_zero, cos_pi]
      have hθ := sin_sq_add_cos_sq θ
      linear_combination (-2 : ℝ) * hθ
    · exact continuous_sin.intervalIntegrable _ _
    · exact (continuous_const.mul (continuous_sin.pow 3)).intervalIntegrable _ _
  simp_rw [hin]
  rw [intervalIntegral.integral_const_mul, integral_cos_sq]
  simp only [cos_zero, sin_zero, sin_two_pi, cos_two_pi]
  field_simp
  ring

/-- Invariant polynomials ignore the gauge: for every square matrix `X`, every invertible matrix
`g` (a gauge change) and every number `t`, `det(I + t g⁻¹Xg) = det(I + tX)`. So every coefficient
of `t^k` in `det(I + tX)`, which gives the Chern and Pontryagin forms, is the same in every gauge. -/
theorem det_one_add_smul_gauge_change {n R : Type*} [Fintype n] [DecidableEq n] [CommRing R]
    (g : (Matrix n n R)ˣ) (X : Matrix n n R) (t : R) :
    det (1 + t • ((g⁻¹ : (Matrix n n R)ˣ).val * X * g.val)) = det (1 + t • X) := by
  have h : (1 : Matrix n n R) + t • ((g⁻¹ : (Matrix n n R)ˣ).val * X * g.val)
      = (g⁻¹ : (Matrix n n R)ˣ).val * (1 + t • X) * g.val := by
    rw [Matrix.mul_add, Matrix.add_mul, Matrix.mul_one, Matrix.mul_smul, Matrix.smul_mul,
      ← Units.val_mul, inv_mul_cancel, Units.val_one]
  rw [h, det_units_conj']

/-! The card's worked numbers, checked exactly. -/

-- Monopole bundle: (1/4π) × 2 × 2π = 1.
example : (1 / (4 * π)) * 2 * (2 * π) = 1 := by
  field_simp; norm_num

-- North cap in the north gauge plus the rest in the south gauge, split at any latitude: one turn.
example (φ₀ : ℝ) : (1 / 2) * (1 - cos φ₀) + (1 / 2) * (1 + cos φ₀) = 1 := by
  ring

/-- The Pfaffian of a 4 by 4 antisymmetric matrix: `W₁₂ W₃₄ − W₁₃ W₂₄ + W₁₄ W₂₃`. -/
def pf4 (W : Matrix (Fin 4) (Fin 4) ℤ) : ℤ := W 0 1 * W 2 3 - W 0 2 * W 1 3 + W 0 3 * W 1 2

/-- The card's antisymmetric test matrix. -/
def W : Matrix (Fin 4) (Fin 4) ℤ := !![0, 1, 2, 3; -1, 0, 4, 5; -2, -4, 0, 6; -3, -5, -6, 0]

/-- The same matrix after the reflection that flips the first axis. -/
def Wr : Matrix (Fin 4) (Fin 4) ℤ := !![0, -1, -2, -3; 1, 0, 4, 5; 2, -4, 0, 6; 3, -5, -6, 0]

-- Pfaffian 8, after a reflection −8; Pfaffian squared 64, the determinant.
example : pf4 W = 8 := by decide
example : pf4 Wr = -8 := by decide
example : pf4 W ^ 2 = W.det := by
  norm_num [pf4, W, Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]

-- Unit 4-sphere: the Pfaffian 3 times the volume 8π²/3, over 4π², gives χ = 2.
example : 3 * (8 * π ^ 2 / 3) / (4 * π ^ 2) = 2 := by
  field_simp; norm_num

-- Unit 4-sphere: (|Rm|² − 4|Ric|² + S²) times the volume, over 32π², gives χ = 2.
example : ((24 : ℝ) - 4 * 36 + 144) * (8 * π ^ 2 / 3) / (32 * π ^ 2) = 2 := by
  field_simp; norm_num

-- Cells of the boundary of a 5-simplex: 6 − 15 + 20 − 15 + 6 = 2.
example : ∑ k ∈ Finset.range 5, (-1 : ℤ) ^ k * (Nat.choose 6 (k + 1) : ℤ) = 2 := by decide

-- Möbius band: transition signs +1 and −1, so a section returns as −1 and w₁ = 1.
example : (1 - (1 : ℤ) * (-1)) / 2 = 1 := by decide

#print axioms monopole_first_chern_number_eq_one
#print axioms first_chern_number_unchanged_by_new_connection
#print axioms det_one_add_smul_gauge_change

end ChernWeil
