-- Nonlinear least squares: the Levenberg-Marquardt damped step is the best step of its own scaled length for the straight-line model, and the Hessian of half the sum of squared misses is J-transpose-J plus the misses times their own curvatures.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Data.Real.Basic

open Matrix

/-- The straight-line model of `F`: half the sum of squared misses when each miss is replaced
by its straight line, `m(d) = ½ ‖r + J d‖²`. -/
noncomputable def lineModel {m n : ℕ} (J : Matrix (Fin m) (Fin n) ℝ) (r : Fin m → ℝ)
    (d : Fin n → ℝ) : ℝ :=
  (1 / 2) * ∑ i, (r i + (J *ᵥ d) i) ^ 2

/-- Marquardt's scaling `D = diag(JᵀJ)`: entry `j` is the sum of squares of column `j` of `J`. -/
def marquardtDiag {m n : ℕ} (J : Matrix (Fin m) (Fin n) ℝ) (j : Fin n) : ℝ :=
  ∑ i, J i j ^ 2

/-- The squared scaled length `‖d‖_D² = Σ_j D_jj d_j²`. -/
def scaledLengthSq {m n : ℕ} (J : Matrix (Fin m) (Fin n) ℝ) (d : Fin n → ℝ) : ℝ :=
  ∑ j, marquardtDiag J j * d j ^ 2

/-- The damped step is the best step of its own length: if `d` solves
`(JᵀJ + λ D) d = -Jᵀ r` with `λ ≥ 0` and `D = diag(JᵀJ)`, then no step `d'` with
`‖d'‖_D ≤ ‖d‖_D` gives the straight-line model a lower value than `d` does. -/
theorem damped_step_is_best_in_its_ball {m n : ℕ} (J : Matrix (Fin m) (Fin n) ℝ)
    (r : Fin m → ℝ) (lam : ℝ) (hlam : 0 ≤ lam) (d : Fin n → ℝ)
    (hstep : (Jᵀ * J + lam • diagonal (marquardtDiag J)) *ᵥ d = -(Jᵀ *ᵥ r))
    (d' : Fin n → ℝ) (hd' : scaledLengthSq J d' ≤ scaledLengthSq J d) :
    lineModel J r d ≤ lineModel J r d' := by
  have hD : ∀ j, 0 ≤ marquardtDiag J j := fun j => Finset.sum_nonneg (fun i _ => sq_nonneg _)
  have key : ∀ j, ∑ i, J i j * (r i + (J *ᵥ d) i) = -(lam * (marquardtDiag J j * d j)) := by
    intro j
    have h := congrFun hstep j
    rw [add_mulVec, ← mulVec_mulVec, smul_mulVec] at h
    simp only [Pi.add_apply, Pi.smul_apply, Pi.neg_apply, smul_eq_mul, mulVec_diagonal] at h
    simp only [mulVec, dotProduct, transpose_apply] at h ⊢
    simp only [mul_add, Finset.sum_add_distrib]
    linarith
  -- cross term
  have cross : ∑ i, (r i + (J *ᵥ d) i) * (J *ᵥ (d' - d)) i
      = ∑ j, (d' j - d j) * -(lam * (marquardtDiag J j * d j)) := by
    simp_rw [← key]
    simp only [mulVec, dotProduct, Pi.sub_apply, Finset.mul_sum]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun i _ => ?_
    ring
  have hlin : ∀ i, (J *ᵥ d') i = (J *ᵥ d) i + (J *ᵥ (d' - d)) i := by
    intro i
    rw [mulVec_sub]; simp
  have expand : lineModel J r d' = lineModel J r d
      + ∑ i, (r i + (J *ᵥ d) i) * (J *ᵥ (d' - d)) i + (1 / 2) * ∑ i, ((J *ᵥ (d' - d)) i) ^ 2 := by
    unfold lineModel
    simp_rw [hlin]
    rw [Finset.mul_sum, Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib,
      ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    ring
  have hball : 0 ≤ ∑ j, (d' j - d j) * -(lam * (marquardtDiag J j * d j)) := by
    have : ∑ j, (d' j - d j) * -(lam * (marquardtDiag J j * d j))
        = lam * (∑ j, (marquardtDiag J j / 2) * (d' j - d j) ^ 2
          + (1 / 2) * (scaledLengthSq J d - scaledLengthSq J d')) := by
      unfold scaledLengthSq
      rw [mul_sub, Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib,
        ← Finset.sum_add_distrib, Finset.mul_sum]
      refine Finset.sum_congr rfl fun j _ => ?_
      ring
    rw [this]
    apply mul_nonneg hlam
    apply add_nonneg
    · exact Finset.sum_nonneg fun j _ => mul_nonneg (div_nonneg (hD j) (by norm_num)) (sq_nonneg _)
    · linarith
  have hsq : 0 ≤ (1 / 2 : ℝ) * ∑ i, ((J *ᵥ (d' - d)) i) ^ 2 :=
    mul_nonneg (by norm_num) (Finset.sum_nonneg fun i _ => sq_nonneg _)
  rw [expand, cross]
  linarith

/-- Gradient and Hessian of `F = ½ Σ rᵢ²` for smooth misses: `∇F = Jᵀ r` and
`∇²F = JᵀJ + S` with `S = Σᵢ rᵢ ∇²rᵢ`, the curvature Gauss-Newton leaves out. Here the
`JᵀJ` term is `Σᵢ (∇rᵢ)(∇rᵢ)ᵀ`, written `(fderiv rᵢ).smulRight (fderiv rᵢ)`. -/
theorem gradient_and_hessian_of_half_sum_of_squares {m n : ℕ}
    (r : Fin m → (Fin n → ℝ) → ℝ) (hr : ∀ i, ContDiff ℝ 2 (r i)) (θ : Fin n → ℝ) :
    fderiv ℝ (fun x => (1 / 2 : ℝ) * ∑ i, r i x ^ 2) θ
        = ∑ i, r i θ • fderiv ℝ (r i) θ ∧
    fderiv ℝ (fderiv ℝ (fun x => (1 / 2 : ℝ) * ∑ i, r i x ^ 2)) θ
        = ∑ i, ((fderiv ℝ (r i) θ).smulRight (fderiv ℝ (r i) θ)
                + r i θ • fderiv ℝ (fderiv ℝ (r i)) θ) := by
  have hd : ∀ i, Differentiable ℝ (r i) := fun i => (hr i).differentiable (by norm_num)
  have hd2 : ∀ i, Differentiable ℝ (fderiv ℝ (r i)) := fun i =>
    ((hr i).fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have grad : ∀ x, fderiv ℝ (fun x => (1 / 2 : ℝ) * ∑ i, r i x ^ 2) x
      = ∑ i, r i x • fderiv ℝ (r i) x := by
    intro x
    have h : HasFDerivAt (fun x => (1 / 2 : ℝ) * ∑ i, r i x * r i x)
        ((1 / 2 : ℝ) • ∑ i, (r i x • fderiv ℝ (r i) x + r i x • fderiv ℝ (r i) x)) x := by
      apply HasFDerivAt.const_mul
      exact HasFDerivAt.fun_sum fun i _ => ((hd i x).hasFDerivAt).mul ((hd i x).hasFDerivAt)
    simp_rw [sq]
    rw [h.fderiv, Finset.smul_sum]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← two_smul ℝ, smul_smul]
    norm_num
  have gfun : fderiv ℝ (fun x => (1 / 2 : ℝ) * ∑ i, r i x ^ 2)
      = fun x => ∑ i, r i x • fderiv ℝ (r i) x := funext grad
  refine ⟨grad θ, ?_⟩
  rw [gfun]
  have h : HasFDerivAt (fun x => ∑ i, r i x • fderiv ℝ (r i) x)
      (∑ i, (r i θ • fderiv ℝ (fderiv ℝ (r i)) θ
        + (fderiv ℝ (r i) θ).smulRight (fderiv ℝ (r i) θ))) θ :=
    HasFDerivAt.fun_sum fun i _ => ((hd i θ).hasFDerivAt).fun_smul ((hd2 i θ).hasFDerivAt)
  rw [h.fderiv]
  exact Finset.sum_congr rfl fun i _ => add_comm _ _

-- Rosenbrock as two misses, `10 (y - x²)` and `1 - x`: half their squared sum is half the function.
example (x y : ℚ) : (1 / 2) * ((10 * (y - x ^ 2)) ^ 2 + (1 - x) ^ 2)
    = (1 / 2) * (100 * (y - x ^ 2) ^ 2 + (1 - x) ^ 2) := by ring

-- Gauss-Newton step 1 from (-1.2, 1) lands at (1, -3.84): the move (2.2, -4.84) solves
-- `J d = -r`, with slope rows (-20x, 10) and (-1, 0).
example : let x : ℚ := -6 / 5; let y : ℚ := 1; let x' : ℚ := 1; let y' : ℚ := -96 / 25
    (-20 * x) * (x' - x) + 10 * (y' - y) = -(10 * (y - x ^ 2)) ∧
    (-1) * (x' - x) + 0 * (y' - y) = -(1 - x) := by norm_num

-- Gauss-Newton step 2 from (1, -3.84) lands at the minimum (1, 1), where both misses are zero.
example : let x : ℚ := 1; let y : ℚ := -96 / 25; let x' : ℚ := 1; let y' : ℚ := 1
    ((-20 * x) * (x' - x) + 10 * (y' - y) = -(10 * (y - x ^ 2)) ∧
      (-1) * (x' - x) + 0 * (y' - y) = -(1 - x)) ∧
    10 * (y' - x' ^ 2) = 0 ∧ 1 - x' = 0 := by norm_num

-- The damping ladder: 0.001 tripled six times is 0.729, and after eight accepted steps
-- (each dividing by 3) the ninth step's damping is 0.000111..., that is 1/9000.
example : (1 / 1000 : ℚ) * 3 ^ 6 = 729 / 1000 := by norm_num
example : (729 / 1000 : ℚ) / 3 ^ 8 = 1 / 9000 := by norm_num

#print axioms damped_step_is_best_in_its_ball
#print axioms gradient_and_hessian_of_half_sum_of_squares
