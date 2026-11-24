-- Lanczos: for a symmetric matrix A and any orthonormal basis Q of a subspace, every eigenvalue of the small matrix T = Qᵀ A Q (a Ritz value) is a Rayleigh quotient of A and lies between A's smallest and largest eigenvalues; symmetry cuts Gram–Schmidt on the Krylov space to a three-term recurrence; and the residual of a Ritz pair is the next β times the last entry of its small eigenvector; the card's diag(1, 2, 3) hand example is checked exactly.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Span.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Analysis.Matrix.PosDef
import Mathlib.Algebra.Order.Star.Real

open Matrix

/-! Matrices are real, indexed by `Fin n`. For a real matrix, `A.IsHermitian` says exactly
`Aᵀ = A` (A is symmetric), and `hA.eigenvalues` lists its n real eigenvalues (Mathlib's
spectral theorem). `Q : Matrix (Fin n) (Fin k) ℝ` with `Qᵀ * Q = 1` has k orthonormal columns
q₁, …, q_k, so `Qᵀ * A * Q` is the card's table T_k. `A *ᵥ x` is the matrix-vector product and
`x ⬝ᵥ y` the dot product. -/

theorem lanczos_dot_transpose {n k : ℕ} (Q : Matrix (Fin n) (Fin k) ℝ) (x : Fin k → ℝ)
    (w : Fin n → ℝ) : (Q *ᵥ x) ⬝ᵥ w = x ⬝ᵥ (Qᵀ *ᵥ w) := by
  rw [dotProduct_comm, dotProduct_mulVec, mulVec_transpose, dotProduct_comm]

theorem lanczos_posDef_sub {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian) (θ : ℝ)
    (h : ∀ i, θ < hA.eigenvalues i) : (A - θ • 1).PosDef := by
  have e : A - θ • 1 = Unitary.conjStarAlgAut ℝ _ hA.eigenvectorUnitary
      (diagonal (fun i => hA.eigenvalues i - θ)) := by
    have : diagonal (fun i => hA.eigenvalues i - θ) =
        diagonal (RCLike.ofReal ∘ hA.eigenvalues) - θ • (1 : Matrix (Fin n) (Fin n) ℝ) := by
      ext i j; by_cases hij : i = j <;> simp [diagonal, hij]
    rw [this, map_sub, map_smul, map_one, ← hA.spectral_theorem]
  rw [e, Unitary.conjStarAlgAut_apply,
    Matrix.IsUnit.posDef_star_right_conjugate_iff Unitary.isUnit_coe, posDef_diagonal_iff]
  intro i; simpa using h i

theorem lanczos_posDef_sub' {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian) (θ : ℝ)
    (h : ∀ i, hA.eigenvalues i < θ) : (θ • 1 - A).PosDef := by
  have e : θ • 1 - A = Unitary.conjStarAlgAut ℝ _ hA.eigenvectorUnitary
      (diagonal (fun i => θ - hA.eigenvalues i)) := by
    have : diagonal (fun i => θ - hA.eigenvalues i) =
        θ • (1 : Matrix (Fin n) (Fin n) ℝ) - diagonal (RCLike.ofReal ∘ hA.eigenvalues) := by
      ext i j; by_cases hij : i = j <;> simp [diagonal, hij]
    rw [this, map_sub, map_smul, map_one, ← hA.spectral_theorem]
  rw [e, Unitary.conjStarAlgAut_apply,
    Matrix.IsUnit.posDef_star_right_conjugate_iff Unitary.isUnit_coe, posDef_diagonal_iff]
  intro i; simpa using h i

/-- Rayleigh–Ritz. Let A be symmetric and let the columns of Q be orthonormal (for Lanczos,
a basis of the Krylov space). If θ is an eigenvalue of T = Qᵀ A Q, with eigenvector s ≠ 0,
then θ is the Rayleigh quotient R(y) = yᵀAy ÷ yᵀy of the full-size Ritz vector y = Q s, and θ
lies inside A's eigenvalue range: some eigenvalue of A is at most θ and some is at least θ.
So a Ritz value never passes the largest eigenvalue λ_n nor drops below the smallest λ₁. -/
theorem ritz_value_between_extreme_eigenvalues {n k : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : A.IsHermitian) (Q : Matrix (Fin n) (Fin k) ℝ) (hQ : Qᵀ * Q = 1)
    (θ : ℝ) (s : Fin k → ℝ) (hs0 : s ≠ 0) (hTs : (Qᵀ * A * Q) *ᵥ s = θ • s) :
    θ = ((Q *ᵥ s) ⬝ᵥ (A *ᵥ (Q *ᵥ s))) / ((Q *ᵥ s) ⬝ᵥ (Q *ᵥ s)) ∧
    (∃ i, hA.eigenvalues i ≤ θ) ∧ (∃ j, θ ≤ hA.eigenvalues j) := by
  have hyy : (Q *ᵥ s) ⬝ᵥ (Q *ᵥ s) = s ⬝ᵥ s := by
    rw [lanczos_dot_transpose, mulVec_mulVec, hQ, one_mulVec]
  have hyAy : (Q *ᵥ s) ⬝ᵥ (A *ᵥ (Q *ᵥ s)) = θ * (s ⬝ᵥ s) := by
    rw [lanczos_dot_transpose, mulVec_mulVec, mulVec_mulVec, hTs,
      dotProduct_smul, smul_eq_mul]
  have hss : 0 < s ⬝ᵥ s := by
    rcases (show 0 ≤ s ⬝ᵥ s by simpa using dotProduct_self_star_nonneg s).lt_or_eq with h | h
    · exact h
    · exact absurd (dotProduct_self_eq_zero.mp h.symm) hs0
  have hy0 : Q *ᵥ s ≠ 0 := by
    intro h; rw [h, zero_dotProduct] at hyy; linarith
  have quad : ∀ c : ℝ, (Q *ᵥ s) ⬝ᵥ ((A - c • 1) *ᵥ (Q *ᵥ s)) = (θ - c) * (s ⬝ᵥ s) := by
    intro c
    rw [sub_mulVec, dotProduct_sub, smul_mulVec, one_mulVec, dotProduct_smul, hyAy, hyy,
      smul_eq_mul]; ring
  refine ⟨by rw [hyAy, hyy]; field_simp, ?_, ?_⟩
  · by_contra hc
    push Not at hc
    have := (lanczos_posDef_sub A hA θ hc).dotProduct_mulVec_pos hy0
    rw [star_trivial, quad] at this
    simp at this
  · by_contra hc
    push Not at hc
    have := (lanczos_posDef_sub' A hA θ hc).dotProduct_mulVec_pos hy0
    rw [star_trivial, sub_mulVec, dotProduct_sub, smul_mulVec, one_mulVec,
      dotProduct_smul, hyAy, hyy, smul_eq_mul] at this
    simp at this

/-- Symmetry leaves only three terms. Let A be symmetric, let q₀, …, q_k be orthonormal, and
let each product A qᵢ lie in the span of q₀, …, q_{i+1} (the Krylov space grows by one
direction a step). Then A q_k has no part along any qᵢ with i ≤ k − 2, so Gram–Schmidt on
A q_k only has to remove its parts along q_k and q_{k−1}. -/
theorem lanczos_three_term_recurrence {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : Aᵀ = A)
    (q : ℕ → Fin n → ℝ) (k : ℕ)
    (horth : ∀ i ≤ k, ∀ j ≤ k, q i ⬝ᵥ q j = if i = j then 1 else 0)
    (hkrylov : ∀ i, i + 2 ≤ k → A *ᵥ q i ∈ Submodule.span ℝ (q '' Set.Iic (i + 1))) :
    ∀ i, i + 2 ≤ k → q i ⬝ᵥ (A *ᵥ q k) = 0 := by
  intro i hi
  have h1 : q i ⬝ᵥ (A *ᵥ q k) = (A *ᵥ q i) ⬝ᵥ q k := by
    rw [dotProduct_mulVec, ← mulVec_transpose, hA]
  rw [h1]
  suffices H : ∀ v ∈ Submodule.span ℝ (q '' Set.Iic (i + 1)), v ⬝ᵥ q k = 0 from
    H _ (hkrylov i hi)
  intro v hmem
  induction hmem using Submodule.span_induction with
  | mem x hx =>
    obtain ⟨j, hj, rfl⟩ := hx
    have hj' : j ≤ i + 1 := hj
    rw [horth j (by omega) k le_rfl]
    exact ite_eq_right_iff.mpr (fun h => absurd h (by omega))
  | zero => simp
  | add x y _ _ hx hy => rw [add_dotProduct, hx, hy, add_zero]
  | smul a x _ hx => rw [smul_dotProduct, hx, smul_zero]

/-- The residual comes free. Suppose the Lanczos relation A Q_k = Q_k T_k + β_k q_{k+1} e_kᵀ
holds, with q_{k+1} of length one and e_k the last column of the identity. If T_k s = θ s and
y = Q_k s, then A y − θ y = β_k s_k q_{k+1}, so ‖A y − θ y‖₂ = |β_k| |s_k|. -/
theorem ritz_residual_from_last_entry {n k : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (Q : Matrix (Fin n) (Fin (k + 1)) ℝ) (T : Matrix (Fin (k + 1)) (Fin (k + 1)) ℝ)
    (β : ℝ) (qnext : Fin n → ℝ) (hnext : qnext ⬝ᵥ qnext = 1)
    (hrel : A * Q = Q * T + vecMulVec (β • qnext) (Pi.single (Fin.last k) 1))
    (θ : ℝ) (s : Fin (k + 1) → ℝ) (hs : T *ᵥ s = θ • s) :
    A *ᵥ (Q *ᵥ s) - θ • (Q *ᵥ s) = (β * s (Fin.last k)) • qnext ∧
    √((A *ᵥ (Q *ᵥ s) - θ • (Q *ᵥ s)) ⬝ᵥ (A *ᵥ (Q *ᵥ s) - θ • (Q *ᵥ s))) =
      |β| * |s (Fin.last k)| := by
  have h1 : A *ᵥ (Q *ᵥ s) - θ • (Q *ᵥ s) = (β * s (Fin.last k)) • qnext := by
    rw [mulVec_mulVec, hrel, add_mulVec, ← mulVec_mulVec, hs, mulVec_smul, vecMulVec_mulVec,
      single_dotProduct, one_mul, op_smul_eq_smul, smul_smul, mul_comm (s (Fin.last k)) β,
      add_sub_cancel_left]
  refine ⟨h1, ?_⟩
  rw [h1, smul_dotProduct, dotProduct_smul, hnext, smul_eq_mul, smul_eq_mul, mul_one,
    ← abs_mul]
  exact Real.sqrt_mul_self_eq_abs _

/-! The card's worked example: A = diag(1, 2, 3), start b = (1, 1, 1). Vectors are kept
unscaled, so each Rayleigh quotient divides by the squared length. -/

-- α₁ = q₁ᵀ A q₁ = bᵀAb ÷ bᵀb = (1 + 2 + 3) ÷ 3 = 2.
example : ((![1, 1, 1] : Fin 3 → ℚ) ⬝ᵥ (diagonal ![1, 2, 3] *ᵥ ![1, 1, 1])) /
    ((![1, 1, 1] : Fin 3 → ℚ) ⬝ᵥ ![1, 1, 1]) = 2 := by
  simp [dotProduct, mulVec_diagonal, Fin.sum_univ_three]; norm_num

-- w = A b − 2 b = (−1, 0, 1), and β₁² = ‖w‖² ÷ ‖b‖² = 2/3.
example : (diagonal ![1, 2, 3] *ᵥ ![1, 1, 1] - (2 : ℚ) • ![1, 1, 1] : Fin 3 → ℚ) =
    ![-1, 0, 1] := by
  ext i; fin_cases i <;> simp [mulVec_diagonal] <;> norm_num

example : ((![-1, 0, 1] : Fin 3 → ℚ) ⬝ᵥ ![-1, 0, 1]) / ((![1, 1, 1] : Fin 3 → ℚ) ⬝ᵥ ![1, 1, 1]) =
    2 / 3 := by
  simp [dotProduct, Fin.sum_univ_three]; norm_num

-- α₂ = (1 + 3) ÷ 2 = 2 along q₂ ∝ (−1, 0, 1); α₃ = (1 + 8 + 3) ÷ 6 = 2 along q₃ ∝ (1, −2, 1).
example : ((![-1, 0, 1] : Fin 3 → ℚ) ⬝ᵥ (diagonal ![1, 2, 3] *ᵥ ![-1, 0, 1])) /
    ((![-1, 0, 1] : Fin 3 → ℚ) ⬝ᵥ ![-1, 0, 1]) = 2 ∧
    ((![1, -2, 1] : Fin 3 → ℚ) ⬝ᵥ (diagonal ![1, 2, 3] *ᵥ ![1, -2, 1])) /
    ((![1, -2, 1] : Fin 3 → ℚ) ⬝ᵥ ![1, -2, 1]) = 2 := by
  simp [dotProduct, mulVec_diagonal, Fin.sum_univ_three]; norm_num

-- T₂ = [[2, √(2/3)], [√(2/3), 2]] has Ritz values 2 ± √(2/3): det(T₂ − θI) = 0 at both.
example : (!![2, √(2/3); √(2/3), 2] - (2 - √(2/3)) • 1 : Matrix (Fin 2) (Fin 2) ℝ).det = 0 ∧
    (!![2, √(2/3); √(2/3), 2] - (2 + √(2/3)) • 1 : Matrix (Fin 2) (Fin 2) ℝ).det = 0 := by
  constructor <;> (rw [det_fin_two]; simp)

-- Both Ritz values sit inside [1, 3], one in each gap of the eigenvalues 1, 2, 3.
example : 1 ≤ 2 - √(2/3) ∧ 2 - √(2/3) ≤ 2 ∧ 2 ≤ 2 + √(2/3) ∧ 2 + √(2/3) ≤ 3 := by
  have h : √(2/3) * √(2/3) = 2/3 := Real.mul_self_sqrt (by norm_num)
  have h0 : 0 ≤ √(2/3) := Real.sqrt_nonneg _
  refine ⟨?_, ?_, ?_, ?_⟩ <;> nlinarith

-- T₃ = [[2, √(2/3), 0], [√(2/3), 2, √(1/3)], [0, √(1/3), 2]] has eigenvalues exactly 1, 2, 3.
example : ∀ c ∈ ({1, 2, 3} : Set ℝ),
    (!![2, √(2/3), 0; √(2/3), 2, √(1/3); 0, √(1/3), 2] - c • 1 :
      Matrix (Fin 3) (Fin 3) ℝ).det = 0 := by
  have h2 : √(2/3) * √(2/3) = 2/3 := Real.mul_self_sqrt (by norm_num)
  have h1 : √(1/3) * √(1/3) = 1/3 := Real.mul_self_sqrt (by norm_num)
  generalize √(2/3) = a at h2 ⊢
  generalize √(1/3) = b at h1 ⊢
  intro c hc
  rw [det_fin_three]
  rcases hc with rfl | rfl | rfl <;> simp <;> nlinarith [h1, h2]

#print axioms ritz_value_between_extreme_eigenvalues
#print axioms lanczos_three_term_recurrence
#print axioms ritz_residual_from_last_entry
#print axioms lanczos_dot_transpose
#print axioms lanczos_posDef_sub
#print axioms lanczos_posDef_sub'
