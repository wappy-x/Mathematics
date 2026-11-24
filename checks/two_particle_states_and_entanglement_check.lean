-- Two particles: a two-spin state is a product exactly when c₀₀c₁₁ − c₀₁c₁₀ = 0, every local model has CHSH value at most 2, and the singlet reaches 2√2.
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Complex.Basic

open Matrix Real
open scoped Kronecker

/-- The product test: a two-particle spin state with amplitudes c₀₀, c₀₁, c₁₀, c₁₁ (first index
electron 1, second index electron 2) is a product u ⊗ v, meaning c_jk = u_j v_k for some
one-electron columns u and v, exactly when D = c₀₀c₁₁ − c₀₁c₁₀ = 0. -/
theorem product_state_iff_product_test (c : Matrix (Fin 2) (Fin 2) ℂ) :
    (∃ u v : Fin 2 → ℂ, ∀ j k, c j k = u j * v k) ↔ c 0 0 * c 1 1 - c 0 1 * c 1 0 = 0 := by
  constructor
  · rintro ⟨u, v, h⟩
    rw [h 0 0, h 1 1, h 0 1, h 1 0]; ring
  · intro hD
    by_cases h00 : c 0 0 = 0
    · have h2 : c 0 1 * c 1 0 = 0 := by rw [h00] at hD; linear_combination -hD
      rcases mul_eq_zero.mp h2 with h01 | h10
      · refine ⟨![0, 1], ![c 1 0, c 1 1], ?_⟩
        intro j k; fin_cases j <;> fin_cases k <;> simp [h00, h01]
      · refine ⟨![c 0 1, c 1 1], ![0, 1], ?_⟩
        intro j k; fin_cases j <;> fin_cases k <;> simp [h00, h10]
    · refine ⟨![1, c 1 0 / c 0 0], ![c 0 0, c 0 1], ?_⟩
      intro j k; fin_cases j <;> fin_cases k
      · simp
      · simp
      · simp [h00]
      · simp
        field_simp
        linear_combination hD

/-- The CHSH bound for local models: if each pair carries instructions i, drawn with chances p i,
that fix lab A's readings A, A' and lab B's readings B, B', each +1 or −1, then the CHSH value
E(a,b) + E(a,b') + E(a',b) − E(a',b'), the average of AB + AB' + A'B − A'B', lies between −2 and 2. -/
theorem chsh_local_bound {ι : Type*} (s : Finset ι) (p : ι → ℝ)
    (hp : ∀ i ∈ s, 0 ≤ p i) (hsum : ∑ i ∈ s, p i = 1)
    (A A' B B' : ι → ℝ)
    (hA : ∀ i, A i = 1 ∨ A i = -1) (hA' : ∀ i, A' i = 1 ∨ A' i = -1)
    (hB : ∀ i, B i = 1 ∨ B i = -1) (hB' : ∀ i, B' i = 1 ∨ B' i = -1) :
    |∑ i ∈ s, p i * (A i * B i + A i * B' i + A' i * B i - A' i * B' i)| ≤ 2 := by
  have hX : ∀ i, |A i * B i + A i * B' i + A' i * B i - A' i * B' i| ≤ 2 := by
    intro i
    rcases hA i with h1 | h1 <;> rcases hA' i with h2 | h2 <;>
      rcases hB i with h3 | h3 <;> rcases hB' i with h4 | h4 <;>
      · rw [h1, h2, h3, h4]; norm_num
  calc |∑ i ∈ s, p i * (A i * B i + A i * B' i + A' i * B i - A' i * B' i)|
      ≤ ∑ i ∈ s, |p i * (A i * B i + A i * B' i + A' i * B i - A' i * B' i)| :=
        Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ i ∈ s, p i * 2 := by
        apply Finset.sum_le_sum
        intro i hi
        rw [abs_mul, abs_of_nonneg (hp i hi)]
        exact mul_le_mul_of_nonneg_left (hX i) (hp i hi)
    _ = 2 := by rw [← Finset.sum_mul, hsum, one_mul]

/-- The spin-reading matrix along the direction at angle a from z in the x–z plane:
cos a σ_z + sin a σ_x, with readings ±1. -/
noncomputable def spinAlong (a : ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  Real.cos a • !![1, 0; 0, -1] + Real.sin a • !![0, 1; 1, 0]

/-- The singlet (up-down − down-up)/√2 as a column of four amplitudes indexed by
(electron 1's reading, electron 2's reading), 0 for up and 1 for down. -/
noncomputable def singlet : Fin 2 × Fin 2 → ℝ := fun q =>
  (1 / Real.sqrt 2) * ((if q = (0, 1) then 1 else 0) - (if q = (1, 0) then 1 else 0))

/-- The correlation E(a,b) of the two labs' readings in the state ψ:
the expected value of σ_a ⊗ σ_b. -/
noncomputable def corr (ψ : Fin 2 × Fin 2 → ℝ) (a b : ℝ) : ℝ :=
  ψ ⬝ᵥ ((spinAlong a ⊗ₖ spinAlong b) *ᵥ ψ)

/-- The singlet's correlation is E(a,b) = −cos(a − b) for every pair of directions, and at the
card's four directions a = 0, a' = π/2, b = −3π/4, b' = 3π/4 its CHSH value
E(a,b) + E(a,b') + E(a',b) − E(a',b') is 2√2, above the local bound of 2. -/
theorem singlet_chsh_eq_two_sqrt_two :
    (∀ a b : ℝ, corr singlet a b = -Real.cos (a - b)) ∧
    corr singlet 0 (-(3 * π / 4)) + corr singlet 0 (3 * π / 4)
      + corr singlet (π / 2) (-(3 * π / 4)) - corr singlet (π / 2) (3 * π / 4)
      = 2 * Real.sqrt 2 := by
  have hc : ∀ a b : ℝ, corr singlet a b = -Real.cos (a - b) := by
    intro a b
    have hs : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
    have hs0 : Real.sqrt 2 ≠ 0 := by positivity
    simp only [corr, singlet, spinAlong, dotProduct, mulVec, Fintype.sum_prod_type,
      Fin.sum_univ_two, kroneckerMap_apply, Matrix.add_apply, Matrix.smul_apply,
      Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.empty_val', Matrix.cons_val_fin_one, smul_eq_mul,
      Prod.mk.injEq]
    simp
    rw [Real.cos_sub]
    field_simp
    linear_combination (cos a * cos b + sin a * sin b) * hs
  refine ⟨hc, ?_⟩
  rw [hc, hc, hc, hc]
  have h1 : (0:ℝ) - -(3 * π / 4) = π - π / 4 := by ring
  have h2 : (0:ℝ) - 3 * π / 4 = -(π - π / 4) := by ring
  have h3 : π / 2 - -(3 * π / 4) = π / 4 + π := by ring
  have h4 : π / 2 - 3 * π / 4 = -(π / 4) := by ring
  rw [h1, h2, h3, h4, Real.cos_neg, Real.cos_neg, Real.cos_pi_sub, Real.cos_add_pi,
    Real.cos_pi_div_four]
  ring

-- All 16 local strategies: each gives exactly +2 or −2.
example : ∀ A ∈ ({1, -1} : Finset ℤ), ∀ A' ∈ ({1, -1} : Finset ℤ),
    ∀ B ∈ ({1, -1} : Finset ℤ), ∀ B' ∈ ({1, -1} : Finset ℤ),
    A * B + A * B' + A' * B - A' * B' = 2 ∨ A * B + A * B' + A' * B - A' * B' = -2 := by
  decide

-- The singlet's table times √2, (0, 1; −1, 0), fails the product test: D = 1 (so 1/2 for the singlet).
example : (0 : ℤ) * 0 - 1 * (-1) = 1 := by norm_num

-- A product table, (1, 0) ⊗ (2, 1) = (2, 1; 0, 0), passes it: D = 0.
example : (2 : ℤ) * 0 - 1 * 0 = 0 := by norm_num

-- Box levels in units of E₁ = n²: singlet both in level 1 costs 2, triplet levels 1 and 2 cost 5, gap 3.
example : (1 ^ 2 + 1 ^ 2 : ℕ) = 2 ∧ (1 ^ 2 + 2 ^ 2 : ℕ) = 5 ∧ 5 - 2 = 3 := by norm_num

-- Trace of S² (in units of ħ²): three triplet states at 2 and the singlet at 0.
example : 3 * 2 + 0 = 6 := by norm_num

#print axioms product_state_iff_product_test
#print axioms chsh_local_bound
#print axioms singlet_chsh_eq_two_sqrt_two
