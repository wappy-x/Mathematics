-- Two-ports: the waves leaving a two-port are S = (Z − Z₀1)(Z + Z₀1)⁻¹ times the waves arriving, the chain matrix of two boxes in a row is the product of their chain matrices, and a pi pad designed for a voltage ratio K in Z₀ reflects nothing and passes 1/K of the wave per pad.
import Mathlib.Analysis.Complex.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

open Matrix

/-! A linear two-port at one frequency. Port `k` (`k = 0` for port 1, `k = 1` for port 2) has
voltage `V k` and current `I k` flowing in; both are complex numbers (phasors). The reference
impedance `Z₀` is a positive real number (50 Ω on the card). The wave arriving at a port is
`a = (V + Z₀ I)/2` and the wave leaving it is `b = (V − Z₀ I)/2`. The chain (ABCD) matrix takes
port 2's voltage and the current leaving port 2, `(V₂, −I₂)`, to port 1's `(V₁, I₁)`. -/

/-- The chain matrix of a series resistor `R`: `[[1, R], [0, 1]]`. -/
def seriesABCD (R : ℝ) : Matrix (Fin 2) (Fin 2) ℝ := !![1, R; 0, 1]

/-- The chain matrix of a shunt resistor `R` to the return wire: `[[1, 0], [1/R, 1]]`. -/
noncomputable def shuntABCD (R : ℝ) : Matrix (Fin 2) (Fin 2) ℝ := !![1, 0; 1 / R, 1]

/-- The pi pad: a shunt `R_p`, then a series `R_s`, then a shunt `R_p`. -/
noncomputable def piPadABCD (Rp Rs : ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  shuntABCD Rp * seriesABCD Rs * shuntABCD Rp

/-- Step 3, the S matrix from the Z matrix. A linear two-port at one frequency has impedance
matrix `Z`: its port voltages are `V = Z I`. Measure waves against a reference impedance
`Z₀ > 0`, with arriving waves `a = (V + Z₀ I)/2` and leaving waves `b = (V − Z₀ I)/2`. Where
`Z + Z₀1` is invertible, the leaving waves are the scattering matrix
`S = (Z − Z₀1)(Z + Z₀1)⁻¹` times the arriving waves: `b = S a`. -/
theorem s_matrix_from_z_matrix (Z₀ : ℝ) (hZ₀ : 0 < Z₀) (Z : Matrix (Fin 2) (Fin 2) ℂ)
    (hinv : IsUnit (Z + (Z₀ : ℂ) • (1 : Matrix (Fin 2) (Fin 2) ℂ)).det)
    (V I a b : Fin 2 → ℂ)
    (hZ : V = Z *ᵥ I)
    (ha : a = (1 / 2 : ℂ) • (V + (Z₀ : ℂ) • I))
    (hb : b = (1 / 2 : ℂ) • (V - (Z₀ : ℂ) • I)) :
    b = ((Z - (Z₀ : ℂ) • (1 : Matrix (Fin 2) (Fin 2) ℂ)) *
        (Z + (Z₀ : ℂ) • (1 : Matrix (Fin 2) (Fin 2) ℂ))⁻¹) *ᵥ a := by
  set M := Z + (Z₀ : ℂ) • (1 : Matrix (Fin 2) (Fin 2) ℂ) with hM
  have haM : a = (1 / 2 : ℂ) • (M *ᵥ I) := by
    rw [ha, hZ, hM, Matrix.add_mulVec, Matrix.smul_mulVec, Matrix.one_mulVec]
  have hinvI : M⁻¹ *ᵥ a = (1 / 2 : ℂ) • I := by
    rw [haM, Matrix.mulVec_smul, Matrix.mulVec_mulVec, Matrix.nonsing_inv_mul _ hinv,
      Matrix.one_mulVec]
  rw [← Matrix.mulVec_mulVec, hinvI, Matrix.mulVec_smul, Matrix.sub_mulVec, Matrix.smul_mulVec,
    Matrix.one_mulVec, hb, hZ]

/-- Step 2, chaining is matrix multiplication. The first box has chain matrix `T₁`:
`(V₁, I₁) = T₁ (V₂, −I₂)`. The second box has chain matrix `T₂`:
`(V₁', I₁') = T₂ (V₂', −I₂')`. Wire the first box's port 2 to the second box's port 1, so the
voltages agree, `V₁' = V₂`, and the current leaving the first box enters the second,
`I₁' = −I₂`. Then the chain's matrix is the product: `(V₁, I₁) = (T₁ T₂) (V₂', −I₂')`. -/
theorem abcd_of_chain_is_product (T₁ T₂ : Matrix (Fin 2) (Fin 2) ℂ)
    (V₁ I₁ V₂ I₂ V₁' I₁' V₂' I₂' : ℂ)
    (h₁ : ![V₁, I₁] = T₁ *ᵥ ![V₂, -I₂])
    (h₂ : ![V₁', I₁'] = T₂ *ᵥ ![V₂', -I₂'])
    (hV : V₁' = V₂) (hI : I₁' = -I₂) :
    ![V₁, I₁] = (T₁ * T₂) *ᵥ ![V₂', -I₂'] := by
  rw [← Matrix.mulVec_mulVec, ← h₂, hV, hI, h₁]

/-- Steps 4 and 5, the matched pad and a chain of them. Design a pi pad for a voltage ratio
`K > 1` in a reference impedance `Z₀ > 0`: shunts `R_p = Z₀ (K + 1)/(K − 1)` and series
`R_s = Z₀ (K² − 1)/(2K)`. Chain `n` such pads and end the last port in `Z₀`, so no wave arrives
there (`a₂ = (V₂ + Z₀ I₂)/2 = 0`). Then nothing is reflected at port 1 (`b₁ = 0`, so
`S₁₁ = 0`), and the wave leaving port 2 is `1/Kⁿ` of the wave arriving at port 1
(`S₂₁ = 1/Kⁿ`): one pad passes `1/K`, two pads `1/K²`, and the losses in decibels add. -/
theorem matched_pi_pads_in_chain (Z₀ K : ℝ) (hZ₀ : 0 < Z₀) (hK : 1 < K) (n : ℕ)
    (V₁ I₁ V₂ I₂ : ℝ)
    (hchain : ![V₁, I₁] =
      piPadABCD (Z₀ * (K + 1) / (K - 1)) (Z₀ * (K ^ 2 - 1) / (2 * K)) ^ n *ᵥ ![V₂, -I₂])
    (hload : (V₂ + Z₀ * I₂) / 2 = 0) :
    (V₁ - Z₀ * I₁) / 2 = 0 ∧ (V₂ - Z₀ * I₂) / 2 = (1 / K) ^ n * ((V₁ + Z₀ * I₁) / 2) := by
  set M := piPadABCD (Z₀ * (K + 1) / (K - 1)) (Z₀ * (K ^ 2 - 1) / (2 * K)) with hM
  have hK0 : K ≠ 0 := by linarith
  have hK1 : K - 1 ≠ 0 := by linarith
  have hK2 : K + 1 ≠ 0 := by linarith
  have hZ0 : Z₀ ≠ 0 := hZ₀.ne'
  have heig : M *ᵥ ![Z₀, 1] = K • ![Z₀, 1] := by
    ext i
    fin_cases i <;>
      simp [hM, piPadABCD, shuntABCD, seriesABCD, Matrix.mulVec, dotProduct,
        Fin.sum_univ_two] <;> field_simp <;> ring
  have hpow : ∀ m : ℕ, M ^ m *ᵥ ![Z₀, 1] = K ^ m • ![Z₀, 1] := by
    intro m
    induction m with
    | zero => simp
    | succ m ih =>
      rw [pow_succ, ← Matrix.mulVec_mulVec, heig, Matrix.mulVec_smul, ih, smul_smul, pow_succ,
        mul_comm]
  have hV₂ : V₂ = -(Z₀ * I₂) := by linarith
  have hvec : ![V₂, -I₂] = (-I₂) • ![Z₀, (1 : ℝ)] := by
    ext i; fin_cases i <;> simp [hV₂]; ring
  rw [hvec, Matrix.mulVec_smul, hpow, smul_smul] at hchain
  have e0 := congrFun hchain 0
  have e1 := congrFun hchain 1
  simp at e0 e1
  refine ⟨?_, ?_⟩
  · rw [e0, e1]; ring
  · rw [e0, e1, hV₂]
    have : (1 / K) ^ n * K ^ n = 1 := by rw [← mul_pow]; simp [hK0]
    linear_combination (Z₀ * I₂) * this

-- The 20 dB pad for 50 Ω: K = 10, shunts 50·11/9 = 550/9 ≈ 61.11 Ω, series 50·99/20 = 247.50 Ω.
example : (50 : ℚ) * (10 + 1) / (10 - 1) = 550 / 9 ∧ (50 : ℚ) * (10 ^ 2 - 1) / (2 * 10) = 495 / 2 := by
  norm_num
-- Its chain matrix A = D = 1 + R_s/R_p, B = R_s, C = (2 + R_s/R_p)/R_p gives A + B/Z₀ = C Z₀ + D = 10,
-- so S₁₁ = 0 and S₂₁ = 2/20 = 0.1000.
example :
    let Rp : ℚ := 550 / 9; let Rs : ℚ := 495 / 2
    let A := 1 + Rs / Rp; let B := Rs; let C := (2 + Rs / Rp) / Rp; let D := 1 + Rs / Rp
    A + B / 50 = 10 ∧ C * 50 + D = 10 ∧ (A + B / 50 - C * 50 - D) / (A + B / 50 + C * 50 + D) = 0 ∧
      2 / (A + B / 50 + C * 50 + D) = 1 / 10 ∧ A * D - B * C = 1 := by
  norm_num
-- Even mode for the 20 dB pad: Z_e = R_p reflects (550/9 − 50)/(550/9 + 50) = 1/10 = 1/K,
-- and Z_e Z_o = Z₀² = 2500 Ω², with Z_o = R_p ∥ (R_s/2).
example : ((550 : ℚ) / 9 - 50) / (550 / 9 + 50) = 1 / 10 ∧
    (550 : ℚ) / 9 * ((550 / 9) * (495 / 4) / (550 / 9 + 495 / 4)) = 2500 := by
  norm_num
-- A bare 75 Ω load on 50 Ω cable reflects (75 − 50)/(75 + 50) = 0.2000.
example : ((75 : ℚ) - 50) / (75 + 50) = 1 / 5 := by norm_num

#print axioms s_matrix_from_z_matrix
#print axioms abcd_of_chain_is_product
#print axioms matched_pi_pads_in_chain
