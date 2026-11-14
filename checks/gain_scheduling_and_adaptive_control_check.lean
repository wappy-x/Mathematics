-- Adapting as you go: the scheduled PI gains cancel the load from the loop, the matched controller turns the sampled belt into the reference model, and the recursive least-squares update equals the batch least-squares solution.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.LinearAlgebra.Matrix.PosDef

open Matrix

/-- The schedule gives every load the same loop. Take a belt with inertia `J > 0`, friction `b`
and drive lag `τ`, so `G(s) = 1 / ((J s + b)(τ s + 1))`, and a target lag `Tc > 0`. Set the PI gains
`Kp = J / Tc` and `Ki = b / Tc`. Then at every `s` where the controller and the belt are defined,
the loop gain `L = (Kp + Ki / s) G(s)` is `1 / (Tc s (τ s + 1))`, whatever `J` is, and the closed
loop from command to speed is `L / (1 + L) = 1 / (Tc τ s² + Tc s + 1)`. -/
theorem gain_schedule_gives_every_load_the_same_loop (J b τ Tc : ℝ) (hJ : 0 < J) (hTc : 0 < Tc)
    (s : ℂ) (hs : s ≠ 0) (hbelt : (J : ℂ) * s + b ≠ 0) (hlag : (τ : ℂ) * s + 1 ≠ 0) :
    let Kp : ℂ := (J : ℂ) / Tc
    let Ki : ℂ := (b : ℂ) / Tc
    let G : ℂ := 1 / (((J : ℂ) * s + b) * ((τ : ℂ) * s + 1))
    let L : ℂ := (Kp + Ki / s) * G
    L = 1 / ((Tc : ℂ) * s * ((τ : ℂ) * s + 1)) ∧
      L / (1 + L) = 1 / ((Tc : ℂ) * τ * s ^ 2 + Tc * s + 1) := by
  intro Kp Ki G L
  have hTc' : (Tc : ℂ) ≠ 0 := by exact_mod_cast hTc.ne'
  have hL : L = 1 / ((Tc : ℂ) * s * ((τ : ℂ) * s + 1)) := by
    simp only [L, Kp, Ki, G]
    field_simp
  refine ⟨hL, ?_⟩
  rw [hL]
  set D : ℂ := (Tc : ℂ) * s * ((τ : ℂ) * s + 1) with hD
  have hD0 : D ≠ 0 := by simp [hD, hTc', hs, hlag]
  have hpoly : (Tc : ℂ) * τ * s ^ 2 + Tc * s + 1 = D + 1 := by rw [hD]; ring
  rw [hpoly]
  by_cases h1 : D + 1 = 0
  · have : 1 + 1 / D = 0 := by
      rw [show (1 : ℂ) + 1 / D = (D + 1) / D by field_simp, h1, zero_div]
    rw [this, h1, div_zero, div_zero]
  · field_simp

/-- The matched controller makes the belt copy the reference model. The sampled belt obeys
`v' = a v + g u`. With the estimates equal to the truth and `g ≠ 0`, the controller
`u = ((a_m - a) v + (1 - a_m) r) / g` gives `v' = a_m v + (1 - a_m) r`: the reference model exactly. -/
theorem matched_controller_copies_reference_model (a g a_m v r : ℝ) (hg : g ≠ 0) :
    a * v + g * (((a_m - a) * v + (1 - a_m) * r) / g) = a_m * v + (1 - a_m) * r := by
  field_simp
  ring

/-- Recursive least squares is ordinary least squares, kept up to date. Let the weighted normal
equations be `R θ = q` with `R` positive definite, `P = R⁻¹` and `θ = P q`, and let `λ > 0` be the
forgetting factor. A new sample (regressor `φ`, measured speed `y`) changes `R` to `λ R + φ φᵀ` and
`q` to `λ q + φ y`. With the update gain `K = P φ / (λ + φᵀ P φ)`, the new inverse is
`(P - K φᵀ P) / λ` and the new batch solution is `θ + K (y - φᵀ θ)`. -/
theorem recursive_least_squares_eq_batch {n : ℕ} (R : Matrix (Fin n) (Fin n) ℝ) (hR : R.PosDef)
    (q φ : Fin n → ℝ) (y lam : ℝ) (hlam : 0 < lam) :
    let P := R⁻¹
    let θ := P *ᵥ q
    let K := (1 / (lam + φ ⬝ᵥ (P *ᵥ φ))) • (P *ᵥ φ)
    (lam • R + vecMulVec φ φ)⁻¹ = (1 / lam) • (P - vecMulVec K (φ ᵥ* P)) ∧
      (lam • R + vecMulVec φ φ)⁻¹ *ᵥ (lam • q + y • φ) = θ + (y - φ ⬝ᵥ θ) • K := by
  intro P θ K
  classical
  have hu : IsUnit R.det := (Matrix.isUnit_iff_isUnit_det R).mp hR.isUnit
  have hRP : R * P = 1 := Matrix.mul_nonsing_inv R hu
  have hc : 0 ≤ φ ⬝ᵥ (P *ᵥ φ) := by
    have := hR.inv.posSemidef.dotProduct_mulVec_nonneg φ
    simpa using this
  set c := φ ⬝ᵥ (P *ᵥ φ) with hcdef
  have hpos : 0 < lam + c := by linarith
  set d := 1 / (lam + c) with hd
  have hdc : 1 - d * c = lam * d := by
    rw [hd]; field_simp; ring
  have hlam0 : lam ≠ 0 := hlam.ne'
  have hKd : K = d • (P *ᵥ φ) := by simp only [K, hd, hcdef]
  have hRK : R *ᵥ K = d • φ := by
    rw [hKd, Matrix.mulVec_smul, Matrix.mulVec_mulVec, hRP, Matrix.one_mulVec]
  have hφK : φ ⬝ᵥ K = d * c := by
    simp only [K, dotProduct_smul, smul_eq_mul, hd, hcdef]
  have hinv : (lam • R + vecMulVec φ φ) * ((1 / lam) • (P - vecMulVec K (φ ᵥ* P))) = 1 := by
    rw [Matrix.mul_smul, Matrix.mul_sub, Matrix.add_mul, Matrix.add_mul, Matrix.smul_mul,
      Matrix.smul_mul, hRP, Matrix.mul_vecMulVec, hRK, Matrix.vecMulVec_mul,
      Matrix.vecMulVec_mul_vecMulVec, hφK]
    ext i j
    simp only [Matrix.smul_apply, Matrix.sub_apply, Matrix.add_apply, Matrix.vecMulVec_apply,
      Pi.smul_apply, smul_eq_mul]
    field_simp
    linear_combination (φ i * (φ ᵥ* P) j) * hdc
  have hA : (lam • R + vecMulVec φ φ)⁻¹ = (1 / lam) • (P - vecMulVec K (φ ᵥ* P)) :=
    Matrix.inv_eq_right_inv hinv
  refine ⟨hA, ?_⟩
  rw [hA]
  have hwq : (φ ᵥ* P) ⬝ᵥ q = φ ⬝ᵥ θ := by
    simp only [θ, Matrix.dotProduct_mulVec]
  have hwφ : (φ ᵥ* P) ⬝ᵥ φ = c := by
    simp only [hcdef, Matrix.dotProduct_mulVec]
  simp only [Matrix.smul_mulVec, Matrix.sub_mulVec, Matrix.mulVec_add, Matrix.mulVec_smul,
    Matrix.vecMulVec_mulVec, op_smul_eq_smul, hwq, hwφ]
  rw [hKd]
  ext i
  simp only [Pi.add_apply, Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
  field_simp
  linear_combination (y * (P *ᵥ φ) i) * hdc

-- Worked numbers on the card, as exact fractions.
-- The drive roller radius squared: (0.05 m)² = 0.0025.
example : ((5 : ℚ) / 100) ^ 2 = 25 / 10000 := by norm_num
-- Inertia at 60 kg: 0.20 + 0.0025 × 60 = 0.35 kg·m².
example : (20 : ℚ) / 100 + 25 / 10000 * 60 = 35 / 100 := by norm_num
-- Proportional gain Kp = J / Tc at 0, 40, 60 and 80 kg: 0.800, 1.200, 1.400 and 1.600.
example : ((20 : ℚ) / 100 + 25 / 10000 * 0) / (25 / 100) = 4 / 5 := by norm_num
example : ((20 : ℚ) / 100 + 25 / 10000 * 40) / (25 / 100) = 6 / 5 := by norm_num
example : ((20 : ℚ) / 100 + 25 / 10000 * 60) / (25 / 100) = 7 / 5 := by norm_num
example : ((20 : ℚ) / 100 + 25 / 10000 * 80) / (25 / 100) = 8 / 5 := by norm_num
-- Integral gain, any load: Ki = b / Tc = 0.40 / 0.25 = 1.600.
example : ((40 : ℚ) / 100) / (25 / 100) = 8 / 5 := by norm_num
-- Closed-loop polynomial 0.005 s² + 0.25 s + 1: Tc τ = 0.25 × 0.02 = 0.005,
-- and its discriminant 0.0625 - 0.02 = 0.0425.
example : (25 : ℚ) / 100 * (2 / 100) = 5 / 1000 := by norm_num
example : ((25 : ℚ) / 100) ^ 2 - 4 * (5 / 1000) = 425 / 10000 := by norm_num
-- Too fast, Tc = τ = 0.02 s: damping ratio ½ √(Tc / τ) = 0.500,
-- and Kp = 0.20 / 0.02 asks 5 × 10 = 50 N·m for a 5 rad/s step on the empty belt.
example : (1 / 2 : ℝ) * Real.sqrt ((2 / 100) / (2 / 100)) = 1 / 2 := by norm_num
example : (5 : ℚ) * ((20 / 100) / (2 / 100)) = 50 := by norm_num

#print axioms gain_schedule_gives_every_load_the_same_loop
#print axioms matched_controller_copies_reference_model
#print axioms recursive_least_squares_eq_batch
