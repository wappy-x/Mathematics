-- Vibration modes: two modes K v = λ M v of a symmetric mass-spring system with different λ are perpendicular when weighted by M, by K and by Rayleigh damping α M + β K, and the two-span bridge's determinant and damping formulas hold exactly.
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic

open Matrix

/-- A symmetric matrix gives the same weighted product in either order. -/
theorem sym_dot {n : Type*} [Fintype n] (A : Matrix n n ℝ) (hA : A.IsSymm) (v w : n → ℝ) :
    v ⬝ᵥ (A *ᵥ w) = w ⬝ᵥ (A *ᵥ v) := by
  rw [dotProduct_mulVec, ← hA.eq, vecMul_transpose, dotProduct_comm, hA.eq]

#print axioms sym_dot

/-- The modes split the structure into separate one-mass problems: for any number `n`
of masses, with a symmetric mass matrix `M` and a symmetric stiffness matrix `K`
(linear springs), if `v₁` and `v₂` are modes, `K v₁ = l₁ M v₁` and `K v₂ = l₂ M v₂` (the card writes λ for l),
with `l₁ ≠ l₂`, then they are perpendicular weighted by mass, `v₁ · M v₂ = 0`,
weighted by stiffness, `v₁ · K v₂ = 0`, and weighted by any Rayleigh damping
`C = α M + β K`, `v₁ · C v₂ = 0`. -/
theorem modes_orthogonal_mass_stiffness_rayleigh_damping {n : Type*} [Fintype n]
    (M K : Matrix n n ℝ) (hM : M.IsSymm) (hK : K.IsSymm) (α β : ℝ)
    (v₁ v₂ : n → ℝ) (l₁ l₂ : ℝ)
    (h₁ : K *ᵥ v₁ = l₁ • (M *ᵥ v₁)) (h₂ : K *ᵥ v₂ = l₂ • (M *ᵥ v₂))
    (hne : l₁ ≠ l₂) :
    v₁ ⬝ᵥ (M *ᵥ v₂) = 0 ∧ v₁ ⬝ᵥ (K *ᵥ v₂) = 0 ∧ v₁ ⬝ᵥ ((α • M + β • K) *ᵥ v₂) = 0 := by
  have e1 : v₁ ⬝ᵥ (K *ᵥ v₂) = l₂ * (v₁ ⬝ᵥ (M *ᵥ v₂)) := by
    rw [h₂, dotProduct_smul, smul_eq_mul]
  have e2 : v₁ ⬝ᵥ (K *ᵥ v₂) = l₁ * (v₁ ⬝ᵥ (M *ᵥ v₂)) := by
    rw [sym_dot K hK, h₁, dotProduct_smul, smul_eq_mul, sym_dot M hM]
  have hm : v₁ ⬝ᵥ (M *ᵥ v₂) = 0 := by
    have : (l₁ - l₂) * (v₁ ⬝ᵥ (M *ᵥ v₂)) = 0 := by rw [sub_mul]; linarith
    rcases mul_eq_zero.mp this with h | h
    · exact absurd (sub_eq_zero.mp h) hne
    · exact h
  have hk : v₁ ⬝ᵥ (K *ᵥ v₂) = 0 := by rw [e1, hm, mul_zero]
  refine ⟨hm, hk, ?_⟩
  rw [add_mulVec, smul_mulVec, smul_mulVec, dotProduct_add, dotProduct_smul,
    dotProduct_smul, hm, hk, smul_zero, smul_zero, add_zero]

/-- Two masses give a quadratic for `λ`: for the two-span frame with masses `m₁`, `m₂`
and three springs of stiffness `k`, `det(K - λ M) = m₁ m₂ λ² - 2 k (m₁ + m₂) λ + 3 k²`. -/
theorem two_mass_frame_det (m₁ m₂ k l : ℝ) :
    (!![2 * k, -k; -k, 2 * k] - l • !![m₁, 0; 0, m₂]).det
      = m₁ * m₂ * l ^ 2 - 2 * k * (m₁ + m₂) * l + 3 * k ^ 2 := by
  rw [det_fin_two]
  simp
  ring

/-- Rayleigh damping gives the chosen damping ratio in both modes: with
`α = 2 ζ ω₁ ω₂ / (ω₁ + ω₂)` and `β = 2 ζ / (ω₁ + ω₂)`, the damping ratio of mode `r`,
`α / (2 ω_r) + β ω_r / 2`, equals `ζ` for `r = 1` and `r = 2`. -/
theorem rayleigh_damping_ratio_both_modes (ζ ω₁ ω₂ : ℝ) (h₁ : 0 < ω₁) (h₂ : 0 < ω₂) :
    let α := 2 * ζ * ω₁ * ω₂ / (ω₁ + ω₂)
    let β := 2 * ζ / (ω₁ + ω₂)
    α / (2 * ω₁) + β * ω₁ / 2 = ζ ∧ α / (2 * ω₂) + β * ω₂ / 2 = ζ := by
  intro α β
  have hs : ω₁ + ω₂ ≠ 0 := by positivity
  constructor
  · simp only [α, β]; field_simp; ring
  · simp only [α, β]; field_simp

-- The card's quadratic coefficients: m₁ m₂ = 2.4 × 10^9, 2 k (m₁ + m₂) = 400 × 10^9,
-- 3 k² = 12000 × 10^9, for m₁ = 60000 kg, m₂ = 40000 kg, k = 2000000 N/m.
example : (60000 : ℕ) * 40000 = 2400000000 := by norm_num
example : 2 * (2000000 : ℕ) * (60000 + 40000) = 400000000000 := by norm_num
example : 3 * (2000000 : ℕ) ^ 2 = 12000000000000 := by norm_num

-- The in-step crowd: 60 walkers on span 1 and 40 on span 2, 25 N each, gives F = (1500, 1000) N.
example : 25 * 60 = 1500 ∧ 25 * 40 = 1000 := by decide

-- The push held still: K x = F with x = (2/3 mm, 7/12 mm), the card's 0.6667 mm and 0.5833 mm.
example : !![(4000000 : ℚ), -2000000; -2000000, 4000000] *ᵥ ![2 / 3000, 7 / 12000]
    = ![1500, 1000] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- Resonance gain 1 / (2 ζ) with ζ = 1/100 is 50.
example : (1 : ℚ) / (2 * (1 / 100)) = 50 := by norm_num

#print axioms modes_orthogonal_mass_stiffness_rayleigh_damping
#print axioms two_mass_frame_det
#print axioms rayleigh_damping_ratio_both_modes
