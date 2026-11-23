-- Qubits: a unitary gate keeps the total chance of a state of n qubits at 1, a two-qubit state passes the product test exactly when it is a product state, and no hidden coin matches the 98% that H gives on the coin.
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Basic.Complex.BigOperators
import Mathlib.Tactic.NormNum

open Matrix

theorem sum_normSq_eq_star_dotProduct {ι : Type*} [Fintype ι] (v : ι → ℂ) :
    ((∑ x, Complex.normSq (v x) : ℝ) : ℂ) = star v ⬝ᵥ v := by
  simp only [dotProduct, Pi.star_apply, Complex.ofReal_sum]
  refine Finset.sum_congr rfl fun x _ => ?_
  rw [← Complex.mul_conj, mul_comm]
  rfl

/-- A gate keeps the total chance at 1: if the state `ψ` of `n` qubits is a unit vector of
`2 ^ n` complex amplitudes (its chances `|ψ x|²` add to 1) and the gate `U` is unitary
(`U† U = I`), then the chances of the new state `U ψ` still add to 1. -/
theorem unitary_gate_keeps_total_chance {n : ℕ}
    (U : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) (hU : U ∈ Matrix.unitaryGroup (Fin (2 ^ n)) ℂ)
    (ψ : Fin (2 ^ n) → ℂ) (hψ : ∑ x, Complex.normSq (ψ x) = 1) :
    ∑ x, Complex.normSq ((U *ᵥ ψ) x) = 1 := by
  have h1 : star U * U = 1 := (Matrix.mem_unitaryGroup_iff').mp hU
  apply Complex.ofReal_injective
  rw [sum_normSq_eq_star_dotProduct, Matrix.star_mulVec, ← Matrix.dotProduct_mulVec,
    Matrix.mulVec_mulVec, ← Matrix.star_eq_conjTranspose, h1, Matrix.one_mulVec,
    ← sum_normSq_eq_star_dotProduct, hψ]

/-- The product test: a two-qubit state with amplitudes `c a b` (A's bit `a`, B's bit `b`)
is a product state `(c₀, c₁) ⊗ (d₀, d₁)`, so that `c a b = c_a * d_b`, exactly when
`D = c₀₀ c₁₁ - c₀₁ c₁₀` is zero. -/
theorem product_test_zero_iff_product_state (c : Fin 2 → Fin 2 → ℂ) :
    c 0 0 * c 1 1 - c 0 1 * c 1 0 = 0 ↔
      ∃ u v : Fin 2 → ℂ, ∀ a b, c a b = u a * v b := by
  constructor
  · intro hD
    by_cases h00 : c 0 0 = 0
    · by_cases h01 : c 0 1 = 0
      · refine ⟨![0, 1], c 1, ?_⟩
        intro a b
        fin_cases a <;> fin_cases b <;> simp [h00, h01]
      · have h10 : c 1 0 = 0 := by
          rw [h00, zero_mul, zero_sub, neg_eq_zero] at hD
          exact (mul_eq_zero.mp hD).resolve_left h01
        refine ⟨![1, c 1 1 / c 0 1], c 0, ?_⟩
        intro a b
        fin_cases a <;> fin_cases b <;> simp [h10, h00]
        field_simp
    · refine ⟨![1, c 1 0 / c 0 0], c 0, ?_⟩
      intro a b
      fin_cases a <;> fin_cases b <;> simp
      · field_simp
      · field_simp
        rw [mul_comm (c 1 1), mul_comm (c 1 0)]
        exact sub_eq_zero.mp hD
  · rintro ⟨u, v, h⟩
    rw [h 0 0, h 1 1, h 0 1, h 1 0]
    ring

/-- No hidden coin matches the gate: a coin secretly decided as `|0⟩` with chance `p` and `|1⟩`
with chance `1 - p`, then sent through the Hadamard gate `H`, reads 0 with chance 1/2 for every
`p`; the coin qubit `(4/5)|0⟩ + (3/5)|1⟩` sent through `H` reads 0 with chance 49/50. -/
theorem hidden_coin_reads_half_but_qubit_reads_49_50 (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    let H : Matrix (Fin 2) (Fin 2) ℂ := ((Real.sqrt 2 : ℂ)⁻¹) • !![1, 1; 1, -1]
    p * Complex.normSq ((H *ᵥ ![1, 0]) 0) + (1 - p) * Complex.normSq ((H *ᵥ ![0, 1]) 0) = 1 / 2 ∧
      Complex.normSq ((H *ᵥ ![4 / 5, 3 / 5]) 0) = 49 / 50 := by
  intro H
  have hs : Complex.normSq ((Real.sqrt 2 : ℂ)⁻¹) = 1 / 2 := by
    rw [map_inv₀, Complex.normSq_ofReal, Real.mul_self_sqrt (by norm_num)]
    norm_num
  have e1 : (H *ᵥ ![1, 0]) 0 = (Real.sqrt 2 : ℂ)⁻¹ := by
    simp [H, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
  have e2 : (H *ᵥ ![0, 1]) 0 = (Real.sqrt 2 : ℂ)⁻¹ := by
    simp [H, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
  have e3 : (H *ᵥ ![4 / 5, 3 / 5]) 0 = (Real.sqrt 2 : ℂ)⁻¹ * (7 / 5 : ℝ) := by
    simp [H, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
    ring
  refine ⟨?_, ?_⟩
  · rw [e1, e2, hs]; ring
  · rw [e3, map_mul, hs, Complex.normSq_ofReal]; norm_num

/-- CNOT on the four basis inputs, in the order 00, 01, 10, 11: 00 -> 00, 01 -> 01, 10 -> 11,
11 -> 10. A is kept and B becomes the half adder's sum bit, A xor B. -/
example :
    let CNOT : Matrix (Fin 4) (Fin 4) ℚ := !![1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 0, 1; 0, 0, 1, 0]
    CNOT *ᵥ ![1, 0, 0, 0] = ![1, 0, 0, 0] ∧ CNOT *ᵥ ![0, 1, 0, 0] = ![0, 1, 0, 0] ∧
      CNOT *ᵥ ![0, 0, 1, 0] = ![0, 0, 0, 1] ∧ CNOT *ᵥ ![0, 0, 0, 1] = ![0, 0, 1, 0] := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;>
    norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_four]

/-- CNOT on `(4/5, 0, 3/5, 0)`, the coin joined with `|0⟩`, gives `(4/5, 0, 0, 3/5)`. -/
example : (!![1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 0, 1; 0, 0, 1, 0] : Matrix (Fin 4) (Fin 4) ℚ) *ᵥ
    ![4 / 5, 0, 3 / 5, 0] = ![4 / 5, 0, 0, 3 / 5] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_four]

/-- The chances after the gate, 16/25 and 9/25, add to 1. -/
example : (4 / 5 : ℚ) ^ 2 + 0 ^ 2 + 0 ^ 2 + (3 / 5) ^ 2 = 1 := by norm_num

/-- The product test after the gate is 12/25, and before it is 0. -/
example : (4 / 5 : ℚ) * (3 / 5) - 0 * 0 = 12 / 25 ∧ (4 / 5 : ℚ) * 0 - 0 * (3 / 5) = 0 := by
  norm_num

/-- The amplitude counts the card prints: 2^n amplitudes for n = 1, 2, 10, 20, 50. -/
example : 2 ^ 1 = 2 ∧ 2 ^ 2 = 4 ∧ 2 ^ 10 = 1024 ∧ 2 ^ 20 = 1048576 ∧
    2 ^ 50 = 1125899906842624 := by norm_num

/-- One gate on 50 qubits updates 2^49 pairs; 16 bytes per amplitude fill 16 * 2^50 bytes. -/
example : 2 ^ 49 = 562949953421312 ∧ 16 * 2 ^ 50 = 18014398509481984 := by norm_num

#print axioms sum_normSq_eq_star_dotProduct
#print axioms unitary_gate_keeps_total_chance
#print axioms product_test_zero_iff_product_state
#print axioms hidden_coin_reads_half_but_qubit_reads_49_50
