-- Mixed finite elements: the saddle-point matrix [[A, Bᵀ], [B, 0]] with A positive definite has an inverse exactly when no pressure is invisible (Bᵀ P = 0 only for P = 0), the best velocity's push on a pressure is √(Pᵀ S P) with S = B A⁻¹ Bᵀ, and an inf-sup constant β > 0 bounds the pressure by 1/β times the force and viscous terms.
import Mathlib.LinearAlgebra.Matrix.SchurComplement
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.QuadraticDiscriminant

open Matrix

variable {n m : Type*} [Fintype n] [Fintype m] [DecidableEq n] [DecidableEq m]

omit [DecidableEq n] in
/-- For a real symmetric matrix, `y ⬝ᵥ (A *ᵥ x) = x ⬝ᵥ (A *ᵥ y)`. -/
theorem mfe_dot_mulVec_symm {A : Matrix n n ℝ} (hA : A.IsHermitian) (x y : n → ℝ) :
    y ⬝ᵥ (A *ᵥ x) = x ⬝ᵥ (A *ᵥ y) := by
  have hT : Aᵀ = A := by
    have := hA.eq
    rwa [conjTranspose_eq_transpose_of_trivial] at this
  rw [dotProduct_mulVec, ← mulVec_transpose, hT, dotProduct_comm]

omit [DecidableEq n] in
/-- Cauchy-Schwarz for a positive semidefinite real matrix, squared form. -/
theorem mfe_cauchy_schwarz_sq {A : Matrix n n ℝ} (hA : A.PosSemidef) (x y : n → ℝ) :
    (x ⬝ᵥ (A *ᵥ y)) ^ 2 ≤ (x ⬝ᵥ (A *ᵥ x)) * (y ⬝ᵥ (A *ᵥ y)) := by
  have hsym := mfe_dot_mulVec_symm hA.isHermitian x y
  have h : ∀ t : ℝ, 0 ≤ (y ⬝ᵥ (A *ᵥ y)) * (t * t) + (2 * (x ⬝ᵥ (A *ᵥ y))) * t
      + (x ⬝ᵥ (A *ᵥ x)) := by
    intro t
    have h0 := hA.dotProduct_mulVec_nonneg (x + t • y)
    simp only [star_trivial, mulVec_add, mulVec_smul, add_dotProduct, dotProduct_add,
      smul_dotProduct, dotProduct_smul, smul_eq_mul, hsym] at h0
    nlinarith [h0]
  have hd := discrim_le_zero h
  rw [discrim] at hd
  nlinarith [hd]

omit [DecidableEq n] in
/-- Cauchy-Schwarz for a positive semidefinite real matrix, square-root form. -/
theorem mfe_cauchy_schwarz {A : Matrix n n ℝ} (hA : A.PosSemidef) (x y : n → ℝ) :
    |x ⬝ᵥ (A *ᵥ y)| ≤ √(x ⬝ᵥ (A *ᵥ x)) * √(y ⬝ᵥ (A *ᵥ y)) := by
  have hx : 0 ≤ x ⬝ᵥ (A *ᵥ x) := by simpa using hA.dotProduct_mulVec_nonneg x
  rw [← Real.sqrt_mul hx]
  exact Real.abs_le_sqrt (mfe_cauchy_schwarz_sq hA x y)

/-- Brezzi's condition in matrix form (Step 3). Let A be the velocity stiffness matrix, symmetric
positive definite, with one row per velocity number, and let B be the divergence matrix, with one
row per pressure number. Then the saddle-point matrix [[A, Bᵀ], [B, 0]] has an inverse, so the mixed
system has a unique answer, exactly when no pressure is invisible: Bᵀ P = 0 only for P = 0. -/
theorem saddle_point_matrix_isUnit_iff_no_invisible_pressure
    {A : Matrix n n ℝ} (hA : A.PosDef) (B : Matrix m n ℝ) :
    IsUnit (fromBlocks A Bᵀ B 0) ↔ ∀ P : m → ℝ, Bᵀ *ᵥ P = 0 → P = 0 := by
  have := hA.isUnit.invertible
  have hdetA : A.det ≠ 0 := (hA.det_pos).ne'
  rw [isUnit_iff_isUnit_det, det_fromBlocks₁₁, invOf_eq_nonsing_inv, zero_sub, det_neg,
    isUnit_iff_ne_zero, mul_ne_zero_iff, mul_ne_zero_iff]
  simp only [hdetA, ne_eq, pow_eq_zero_iff', neg_eq_zero, one_ne_zero, false_and,
    not_false_eq_true, true_and]
  constructor
  · intro hS P hP
    apply Matrix.eq_zero_of_mulVec_eq_zero hS
    rw [← mulVec_mulVec, ← mulVec_mulVec, hP, mulVec_zero, mulVec_zero]
  · intro hinj
    have hvm : Function.Injective B.vecMul := by
      intro a b hab
      have h1 : Bᵀ *ᵥ (a - b) = 0 := by
        rw [mulVec_transpose, sub_vecMul]
        exact sub_eq_zero.mpr hab
      exact sub_eq_zero.mp (hinj _ h1)
    have hS := hA.inv.mul_mul_conjTranspose_same hvm
    rw [conjTranspose_eq_transpose_of_trivial] at hS
    exact (hS.det_pos).ne'

/-- The inf-sup quotient for one pressure is a Schur-complement norm (Step 4). Let A be symmetric
positive definite, B any divergence matrix, P any pressure vector, and S = B A⁻¹ Bᵀ the Schur
complement. Then every velocity V satisfies Pᵀ B V ≤ √(Pᵀ S P) · √(Vᵀ A V) (Cauchy-Schwarz), and the
velocity V = A⁻¹ Bᵀ P gives equality. So the best velocity's push on P, measured against the
velocity's size √(Vᵀ A V), is exactly √(Pᵀ S P). -/
theorem best_velocity_push_eq_sqrt_schur
    {A : Matrix n n ℝ} (hA : A.PosDef) (B : Matrix m n ℝ) (P : m → ℝ) :
    (∀ V : n → ℝ,
        P ⬝ᵥ (B *ᵥ V) ≤ √(P ⬝ᵥ ((B * A⁻¹ * Bᵀ) *ᵥ P)) * √(V ⬝ᵥ (A *ᵥ V))) ∧
      P ⬝ᵥ (B *ᵥ (A⁻¹ *ᵥ (Bᵀ *ᵥ P))) =
        √(P ⬝ᵥ ((B * A⁻¹ * Bᵀ) *ᵥ P)) *
          √((A⁻¹ *ᵥ (Bᵀ *ᵥ P)) ⬝ᵥ (A *ᵥ (A⁻¹ *ᵥ (Bᵀ *ᵥ P)))) := by
  have hdet : IsUnit A.det := isUnit_iff_ne_zero.mpr (hA.det_pos).ne'
  set w := A⁻¹ *ᵥ (Bᵀ *ᵥ P) with hw
  have hAw : A *ᵥ w = Bᵀ *ᵥ P := by
    rw [hw, mulVec_mulVec, mul_nonsing_inv _ hdet, one_mulVec]
  have hpush : ∀ V : n → ℝ, P ⬝ᵥ (B *ᵥ V) = w ⬝ᵥ (A *ᵥ V) := by
    intro V
    rw [dotProduct_mulVec, ← mulVec_transpose, ← hAw, dotProduct_comm,
      mfe_dot_mulVec_symm hA.isHermitian]
  have hS : P ⬝ᵥ ((B * A⁻¹ * Bᵀ) *ᵥ P) = w ⬝ᵥ (A *ᵥ w) := by
    rw [← mulVec_mulVec, ← mulVec_mulVec, ← hw, hpush]
  have hwn : 0 ≤ w ⬝ᵥ (A *ᵥ w) := by simpa using hA.posSemidef.dotProduct_mulVec_nonneg w
  refine ⟨fun V => ?_, ?_⟩
  · rw [hS, hpush]
    exact (le_abs_self _).trans (mfe_cauchy_schwarz hA.posSemidef w V)
  · rw [hS, hpush, Real.mul_self_sqrt hwn]

/-- A positive inf-sup constant bounds the pressure (Step 6), with viscosity μ = 1 so that the
velocity's size is |v|₁ = √(Vᵀ A V). Let A be symmetric positive definite, let the pressure size be
‖q‖₀ = √(Pᵀ Mₚ P), and let c hold the integrals of the pressure shapes, so c ⬝ P = 0 sets the
constant pressure aside. Suppose the inf-sup test passes with constant β > 0: every pressure Q with
c ⬝ Q = 0 has a nonzero velocity V with β ‖q‖₀ |v|₁ ≤ Qᵀ B V. Suppose the force's size is at most
f*, meaning Fᵀ V ≤ f* |v|₁ for every V. Then a solution of A U + Bᵀ P = F whose pressure has
average zero satisfies ‖p‖₀ ≤ (1/β) (f* + |u|₁). -/
theorem pressure_le_inv_inf_sup_mul
    {A : Matrix n n ℝ} (hA : A.PosDef) (B : Matrix m n ℝ) (Mp : Matrix m m ℝ) (c : m → ℝ)
    {β fstar : ℝ} (hβ : 0 < β)
    (hinfsup : ∀ Q : m → ℝ, c ⬝ᵥ Q = 0 → ∃ V : n → ℝ, V ≠ 0 ∧
      β * √(Q ⬝ᵥ (Mp *ᵥ Q)) * √(V ⬝ᵥ (A *ᵥ V)) ≤ Q ⬝ᵥ (B *ᵥ V))
    (F : n → ℝ) (hF : ∀ V : n → ℝ, F ⬝ᵥ V ≤ fstar * √(V ⬝ᵥ (A *ᵥ V)))
    (U : n → ℝ) (P : m → ℝ) (hsol : A *ᵥ U + Bᵀ *ᵥ P = F) (hP : c ⬝ᵥ P = 0) :
    √(P ⬝ᵥ (Mp *ᵥ P)) ≤ (1 / β) * (fstar + √(U ⬝ᵥ (A *ᵥ U))) := by
  obtain ⟨V, hV0, hV⟩ := hinfsup P hP
  have hVpos : 0 < √(V ⬝ᵥ (A *ᵥ V)) :=
    Real.sqrt_pos.mpr (by simpa using hA.dotProduct_mulVec_pos hV0)
  have hBP : Bᵀ *ᵥ P = F - A *ᵥ U := by rw [← hsol]; abel
  have hsplit : P ⬝ᵥ (B *ᵥ V) = F ⬝ᵥ V - U ⬝ᵥ (A *ᵥ V) := by
    rw [dotProduct_mulVec, ← mulVec_transpose, hBP, sub_dotProduct, dotProduct_comm (A *ᵥ U),
      mfe_dot_mulVec_symm hA.isHermitian]
  have hcs := mfe_cauchy_schwarz hA.posSemidef U V
  have hFV := hF V
  have key : (β * √(P ⬝ᵥ (Mp *ᵥ P))) * √(V ⬝ᵥ (A *ᵥ V)) ≤
      (fstar + √(U ⬝ᵥ (A *ᵥ U))) * √(V ⬝ᵥ (A *ᵥ V)) := by
    have := neg_abs_le (U ⬝ᵥ (A *ᵥ V))
    nlinarith [hV, hsplit, hcs, hFV]
  have key2 := le_of_mul_le_mul_right key hVpos
  rw [one_div_mul_eq_div, le_div_iff₀ hβ]
  linarith

/-! Worked numbers from the card, checked exactly. -/

-- One cell's x-weight at a Q1-P0 node: ±1 × h/2 with h = 1/4 gives 1/8 = 0.125.
example : (1 : ℚ) * ((1 / 4) / 2) = 1 / 8 := by norm_num

-- At the ringed node, the four weights of -B (+0.125, -0.125, +0.125, -0.125) against the
-- checkerboard signs (+1, -1, -1, +1) pair to exactly 0.
example : (1 / 8 : ℚ) * 1 + (-1 / 8) * (-1) + (1 / 8) * (-1) + (-1 / 8) * 1 = 0 := by norm_num

-- Unknown counts on the 4 by 4 grid: Q1-P0 has 9 interior nodes × 2 = 18 velocity numbers and
-- 16 pressures; Taylor-Hood has 7 × 7 × 2 = 98 velocity and 5 × 5 = 25 pressure numbers; Q1-Q1 has
-- 25 pressures against 18 velocity numbers, so at least 25 - 18 = 7 pressures are invisible.
example : 3 * 3 * 2 = 18 ∧ 4 * 4 = 16 ∧ 7 * 7 * 2 = 98 ∧ 5 * 5 = 25 ∧ 25 - 18 = 7 := by decide

-- The 1-D bar with flux hats and temperature hats on 4 elements: the zigzag temperature
-- 1, -1, 1, -1, 1 pairs to zero with every flux, Bᵀ z = 0.
example :
    (!![-1/2, 1/2, 0, 0, 0;
        -1/2, 0, 1/2, 0, 0;
        0, -1/2, 0, 1/2, 0;
        0, 0, -1/2, 0, 1/2;
        0, 0, 0, -1/2, 1/2] : Matrix (Fin 5) (Fin 5) ℚ)ᵀ *ᵥ ![1, -1, 1, -1, 1] = 0 := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_five] <;> norm_num

-- The 1-D bar with one temperature per element: every temperature pattern z is seen, since the
-- flux built by adding up from the left, 0, z₀, z₀ + z₁, ..., has exactly those differences.
example (z : Fin 4 → ℚ) :
    (!![-1, 1, 0, 0, 0;
        0, -1, 1, 0, 0;
        0, 0, -1, 1, 0;
        0, 0, 0, -1, 1] : Matrix (Fin 4) (Fin 5) ℚ) *ᵥ
      ![0, z 0, z 0 + z 1, z 0 + z 1 + z 2, z 0 + z 1 + z 2 + z 3] = z := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_five] <;> ring

#print axioms mfe_dot_mulVec_symm
#print axioms mfe_cauchy_schwarz_sq
#print axioms mfe_cauchy_schwarz
#print axioms saddle_point_matrix_isUnit_iff_no_invisible_pressure
#print axioms best_velocity_push_eq_sqrt_schur
#print axioms pressure_le_inv_inf_sup_mul
