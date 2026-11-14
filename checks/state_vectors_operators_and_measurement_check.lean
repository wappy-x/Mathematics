-- States as vectors: for a Hermitian matrix with perpendicular unit eigenvectors and a unit state, the readings are real, the Born-rule chances add to 1 and the average reading is the sandwich ψ* A ψ; exits with different readings are perpendicular; a polariser's pass chance is Malus's cos²(α − θ); and the card's 30° photon, 45° splitter and look-alike N are checked exactly.
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.DotProduct
import Mathlib.Analysis.RCLike.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix Complex

theorem hermitian_sandwich_swap {n : ℕ} {A : Matrix (Fin n) (Fin n) ℂ} (hA : A.IsHermitian)
    (x y : Fin n → ℂ) : star x ⬝ᵥ (A *ᵥ y) = star (A *ᵥ x) ⬝ᵥ y := by
  rw [star_mulVec, ← dotProduct_mulVec, hA.eq]

open scoped ComplexOrder in
theorem star_dotProduct_self_ne_zero_of_ne_zero {n : ℕ} {w : Fin n → ℂ} (hw : w ≠ 0) :
    star w ⬝ᵥ w ≠ 0 := fun h => hw (dotProduct_star_self_eq_zero.1 h)

/-- The measurement rule's two theorems. Let `A` be an `n × n` complex matrix that equals its
own conjugate transpose (a Hermitian device), let `ψ` be a unit state (`ψ* ψ = 1`), and let
`u_1, …, u_n` be perpendicular unit eigenvectors of `A` (`u_j* u_k` is 1 when `j = k` and 0
otherwise) with `A u_k = λ_k u_k`. Then every reading `λ_k` is real, the chances
`p_k = |u_k* ψ|²` add to 1, and the average reading `∑ λ_k p_k` equals the sandwich `ψ* A ψ`. -/
theorem born_rule_chances_sum_to_one_and_average_is_sandwich (n : ℕ)
    (A : Matrix (Fin n) (Fin n) ℂ) (hA : A.IsHermitian)
    (ψ : Fin n → ℂ) (hψ : star ψ ⬝ᵥ ψ = 1)
    (u : Fin n → Fin n → ℂ) (lam : Fin n → ℂ)
    (hu : ∀ j k, star (u j) ⬝ᵥ u k = if j = k then 1 else 0)
    (heig : ∀ k, A *ᵥ u k = lam k • u k) :
    (∀ k, (lam k).im = 0) ∧
      ∑ k, ‖star (u k) ⬝ᵥ ψ‖ ^ 2 = 1 ∧
      ∑ k, lam k * ((‖star (u k) ⬝ᵥ ψ‖ ^ 2 : ℝ) : ℂ) = star ψ ⬝ᵥ (A *ᵥ ψ) := by
  -- the matrix whose columns are the eigenvectors
  set U : Matrix (Fin n) (Fin n) ℂ := Matrix.of fun i k => u k i with hUdef
  have hUU : Uᴴ * U = 1 := by
    ext j k
    have := hu j k
    simp only [dotProduct, Pi.star_apply] at this
    simp [U, Matrix.mul_apply, conjTranspose_apply, Matrix.one_apply]
    exact this
  have hUU' : U * Uᴴ = 1 := mul_eq_one_comm.1 hUU
  set c : Fin n → ℂ := Uᴴ *ᵥ ψ with hc
  have hck : ∀ k, c k = star (u k) ⬝ᵥ ψ := by
    intro k
    simp [c, U, mulVec, dotProduct, conjTranspose_apply]
  have hψc : ψ = U *ᵥ c := by
    rw [hc, mulVec_mulVec, hUU', one_mulVec]
  have hstarc : star c = star ψ ᵥ* U := by
    rw [hc, star_mulVec, conjTranspose_conjTranspose]
  have hnorm : ∀ k, (((‖star (u k) ⬝ᵥ ψ‖ ^ 2 : ℝ)) : ℂ) = star (c k) * c k := by
    intro k
    rw [← hck k]
    push_cast
    rw [← Complex.conj_mul']
    rfl
  clear_value c
  refine ⟨?_, ?_, ?_⟩
  · intro k
    have h1 : star (u k) ⬝ᵥ (A *ᵥ u k) = lam k := by
      rw [heig k, dotProduct_smul, hu k k]; simp
    have h2 : star (A *ᵥ u k) ⬝ᵥ u k = star (lam k) := by
      rw [heig k, star_smul, smul_dotProduct, hu k k]; simp
    rw [← Complex.conj_eq_iff_im]
    have := hermitian_sandwich_swap hA (u k) (u k)
    rw [h1, h2] at this
    exact this.symm
  · have hsum : (((∑ k, ‖star (u k) ⬝ᵥ ψ‖ ^ 2 : ℝ)) : ℂ) = 1 := by
      push_cast
      have : ∀ k, ((‖star (u k) ⬝ᵥ ψ‖ : ℂ)) ^ 2 = star (c k) * c k := by
        intro k; rw [← hnorm k]; push_cast; rfl
      simp_rw [this]
      change star c ⬝ᵥ c = 1
      rw [hstarc, ← dotProduct_mulVec, hc, mulVec_mulVec, hUU', one_mulVec, hψ]
    exact_mod_cast hsum
  · have hAU : A * U = U * diagonal lam := by
      ext i k
      rw [mul_diagonal]
      have := congrFun (heig k) i
      simpa [U, mulVec, dotProduct, Matrix.mul_apply, mul_comm] using this
    simp_rw [hnorm]
    have hAψ : A *ᵥ ψ = U *ᵥ (diagonal lam *ᵥ c) := by
      conv_lhs => rw [hψc]
      rw [mulVec_mulVec, hAU, ← mulVec_mulVec]
    rw [hAψ, dotProduct_mulVec, ← hstarc]
    simp [dotProduct, mulVec_diagonal, Pi.star_apply]
    refine Finset.sum_congr rfl fun k _ => by ring

/-- Perpendicular exits. If a Hermitian matrix `A` has `A u = λ u` and `A w = μ w` with
different readings `λ ≠ μ`, then the two directions are perpendicular: `w* u = 0`. -/
theorem hermitian_eigenvectors_of_different_readings_perpendicular (n : ℕ)
    (A : Matrix (Fin n) (Fin n) ℂ) (hA : A.IsHermitian)
    (u w : Fin n → ℂ) (lam mu : ℂ)
    (hu : A *ᵥ u = lam • u) (hw : A *ᵥ w = mu • w) (hne : lam ≠ mu) :
    star w ⬝ᵥ u = 0 := by
  by_cases hw0 : w = 0
  · simp [hw0]
  have hww : star w ⬝ᵥ w ≠ 0 := star_dotProduct_self_ne_zero_of_ne_zero hw0
  have hmu : star mu = mu := by
    have := hermitian_sandwich_swap hA w w
    rw [hw, dotProduct_smul, star_smul, smul_dotProduct, smul_eq_mul, smul_eq_mul] at this
    exact (mul_right_cancel₀ hww this).symm
  have := hermitian_sandwich_swap hA w u
  rw [hu, hw, dotProduct_smul, star_smul, smul_dotProduct, smul_eq_mul, smul_eq_mul, hmu] at this
  have h2 : (lam - mu) * (star w ⬝ᵥ u) = 0 := by rw [sub_mul, this, sub_self]
  rcases mul_eq_zero.1 h2 with h | h
  · exact absurd (sub_eq_zero.1 h) hne
  · exact h

/-- The polariser and Malus's law. For every pass-axis angle `α` the polariser matrix
`A_α = [[cos 2α, sin 2α], [sin 2α, -cos 2α]]` reads +1 on `u₊ = (cos α, sin α)` and -1 on
`u₋ = (-sin α, cos α)`, and for a photon at every angle `θ`, `ψ = (cos θ, sin θ)`, the pass
chance `(u₊* ψ)²` is `cos²(α - θ)`. -/
theorem polariser_pass_chance_is_malus_law (α θ : ℝ) :
    let A : Matrix (Fin 2) (Fin 2) ℝ :=
      !![Real.cos (2 * α), Real.sin (2 * α); Real.sin (2 * α), -Real.cos (2 * α)]
    let up : Fin 2 → ℝ := ![Real.cos α, Real.sin α]
    let um : Fin 2 → ℝ := ![-Real.sin α, Real.cos α]
    let ψ : Fin 2 → ℝ := ![Real.cos θ, Real.sin θ]
    A *ᵥ up = up ∧ A *ᵥ um = -um ∧ (up ⬝ᵥ ψ) ^ 2 = Real.cos (α - θ) ^ 2 := by
  intro A up um ψ
  have hs := Real.sin_sq_add_cos_sq α
  refine ⟨?_, ?_, ?_⟩
  · ext i; fin_cases i <;>
      simp [A, up, mulVec, dotProduct, Fin.sum_univ_two, Real.cos_two_mul, Real.sin_two_mul]
    · linear_combination (2 * Real.cos α) * hs
    · ring
  · ext i; fin_cases i <;>
      simp [A, um, mulVec, dotProduct, Fin.sum_univ_two, Real.cos_two_mul, Real.sin_two_mul]
    · ring
    · linear_combination (-2 * Real.cos α) * hs
  · simp [up, ψ, dotProduct, Fin.sum_univ_two, Real.cos_sub]

/-! The card's worked numbers, checked exactly. The 30° photon is ψ = (√3/2, 1/2); the 45°
splitter is `[[0, 1], [1, 0]]` with exits (1, 1)/√2 and (1, -1)/√2; N = `[[1, 2], [0, -1]]`. -/

-- The 45° splitter equals its own conjugate transpose.
example : (!![0, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ).IsHermitian := by
  ext i j; fin_cases i <;> fin_cases j <;> simp
-- Its readings: (1, 1) reads +1 and (1, -1) reads -1.
example : (!![0, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 1] = (1 : ℤ) • ![1, 1] := by
  decide
example : (!![0, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, -1] = (-1 : ℤ) • ![1, -1] := by
  decide
-- Its two exits are perpendicular: (1, 1) · (1, -1) = 0.
example : (![1, 1] : Fin 2 → ℤ) ⬝ᵥ ![1, -1] = 0 := by decide
-- The state (√3/2, 1/2) has length 1.
example : (Real.sqrt 3 / 2) ^ 2 + (1 / 2 : ℝ) ^ 2 = 1 := by
  norm_num [div_pow]
-- Pass chance ((√3/2 + 1/2)/√2)² = (2 + √3)/4 = 0.9330, blocked ((√3/2 - 1/2)/√2)² = (2 - √3)/4
-- = 0.0670, and the two add to 1.
example : ((Real.sqrt 3 / 2 + 1 / 2) / Real.sqrt 2) ^ 2 = (2 + Real.sqrt 3) / 4 := by
  rw [div_pow, Real.sq_sqrt (by norm_num : (0 : ℝ) ≤ 2)]
  ring_nf; norm_num; ring
example : ((Real.sqrt 3 / 2 - 1 / 2) / Real.sqrt 2) ^ 2 = (2 - Real.sqrt 3) / 4 := by
  rw [div_pow, Real.sq_sqrt (by norm_num : (0 : ℝ) ≤ 2)]
  ring_nf; norm_num; ring
example : (2 + Real.sqrt 3) / 4 + (2 - Real.sqrt 3) / 4 = 1 := by ring
-- Average reading two ways: (+1)(2 + √3)/4 + (-1)(2 - √3)/4 = √3/2 = 2 · (√3/2) · (1/2), 0.8660.
example : (2 + Real.sqrt 3) / 4 - (2 - Real.sqrt 3) / 4 = 2 * (Real.sqrt 3 / 2) * (1 / 2) := by
  ring
-- Counts per second: 933,013 pass and 66,987 blocked out of 1,000,000.
example : 933013 + 66987 = 1000000 := by decide
-- The chain 30° → 45° → 120°: cos² 15° · cos² 75° = (2 + √3)/4 · (2 - √3)/4 = 1/16 = 0.0625.
example : (2 + Real.sqrt 3) / 4 * ((2 - Real.sqrt 3) / 4) = 1 / 16 := by
  ring_nf; norm_num
-- N = [[1, 2], [0, -1]] is not Hermitian.
example : ¬ (!![1, 2; 0, -1] : Matrix (Fin 2) (Fin 2) ℂ).IsHermitian := by
  intro h
  have := congrFun (congrFun h 1) 0
  norm_num [conjTranspose_apply] at this
-- N still reads +1 on (1, 0) and -1 on (1, -1), but those exits are not perpendicular.
example : (!![1, 2; 0, -1] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 0] = (1 : ℤ) • ![1, 0] := by
  decide
example : (!![1, 2; 0, -1] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, -1] = (-1 : ℤ) • ![1, -1] := by
  decide
example : (![1, 0] : Fin 2 → ℤ) ⬝ᵥ ![1, -1] = 1 := by decide
-- N's "chances" add to 3/4 + ((√3/2 - 1/2)/√2)² = (5 - √3)/4 = 0.8170, not 1.
example : 3 / 4 + (2 - Real.sqrt 3) / 4 = (5 - Real.sqrt 3) / 4 := by ring
-- N's "average reading" ψ* N ψ = 3/4 + 2 · (√3/2)(1/2) - 1/4 = (1 + √3)/2 = 1.3660, above 1.
example : (Real.sqrt 3 / 2) ^ 2 + 2 * (Real.sqrt 3 / 2) * (1 / 2) - (1 / 2 : ℝ) ^ 2
    = (1 + Real.sqrt 3) / 2 := by
  norm_num [div_pow]; ring
example : 1 < (1 + Real.sqrt 3) / 2 := by
  have : 1 < Real.sqrt 3 := by
    rw [show (1 : ℝ) = Real.sqrt 1 by simp]
    exact Real.sqrt_lt_sqrt (by norm_num) (by norm_num)
  linarith

#print axioms born_rule_chances_sum_to_one_and_average_is_sandwich
#print axioms hermitian_eigenvectors_of_different_readings_perpendicular
#print axioms polariser_pass_chance_is_malus_law
#print axioms hermitian_sandwich_swap
#print axioms star_dotProduct_self_ne_zero_of_ne_zero
