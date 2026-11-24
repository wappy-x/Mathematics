-- Generalised linear models: for Poisson regression with the log link, each iteratively reweighted least-squares step is exactly a Newton step on the log-likelihood, the log-likelihood is concave, and its slopes are the likelihood-equation sums.
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Real Finset Matrix

/-! Setup. There are `n` hours and `p` coefficients. `X` is the predictor table, with entry
`X i j` in row `i`, column `j` (for the help desk: rows `(1, x i)`, so `p = 2`). `β` is the list
of coefficients and `y i` is the count in hour `i`. The linear predictor is `η = X β`, the log
link makes the mean `μ i = e^(η i)`, and each count is Poisson with that mean. -/

/-- The mean of hour `i` under the log link: `μ i = e^(η i)` with `η = X β`. -/
noncomputable def poissonMean {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (β : Fin p → ℝ)
    (i : Fin n) : ℝ :=
  Real.exp ((X *ᵥ β) i)

/-- The Poisson log-likelihood `ℓ(β) = ∑ i, (y i * ln μ i - μ i - ln (y i)!)`, with `ln μ i = (X β) i`. -/
noncomputable def poissonLogLik {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (y : Fin n → ℕ)
    (β : Fin p → ℝ) : ℝ :=
  ∑ i, ((y i : ℝ) * (X *ᵥ β) i - poissonMean X β i - Real.log ((y i).factorial : ℝ))

/-- The working response of hour `i`: `z i = η i + (y i - μ i) / μ i`, the count moved onto the
log scale by a first-order Taylor step. -/
noncomputable def workingResponse {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (y : Fin n → ℕ)
    (β : Fin p → ℝ) (i : Fin n) : ℝ :=
  (X *ᵥ β) i + ((y i : ℝ) - poissonMean X β i) / poissonMean X β i

/-- A finite sum of concave functions is concave (helper). -/
theorem glm_concaveOn_sum {ι E : Type*} [AddCommGroup E] [Module ℝ E] (u : Finset ι)
    (f : ι → E → ℝ) (hf : ∀ i ∈ u, ConcaveOn ℝ Set.univ (f i)) :
    ConcaveOn ℝ Set.univ (fun x => ∑ i ∈ u, f i x) := by
  refine ⟨convex_univ, ?_⟩
  intro x _ z _ a b ha hb hab
  simp only [smul_eq_mul, Finset.mul_sum, ← Finset.sum_add_distrib]
  refine Finset.sum_le_sum fun i hi => ?_
  have := (hf i hi).2 (Set.mem_univ x) (Set.mem_univ z) ha hb hab
  simpa [smul_eq_mul] using this

/-- **IRLS is Newton's method.** For Poisson regression with the log link, take the weights
`W = diag(μ)`. When the table `Xᵀ W X` can be inverted, the Newton step
`β + (Xᵀ W X)⁻¹ Xᵀ (y - μ)` (inverse curvature times the slopes, added to the current guess)
equals the weighted least-squares fit `(Xᵀ W X)⁻¹ Xᵀ W z` of the working responses `z`. -/
theorem irls_step_eq_newton_step {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (y : Fin n → ℕ)
    (β : Fin p → ℝ)
    (hA : IsUnit (Xᵀ * diagonal (poissonMean X β) * X).det) :
    β + (Xᵀ * diagonal (poissonMean X β) * X)⁻¹ *ᵥ
        (Xᵀ *ᵥ (fun i => (y i : ℝ) - poissonMean X β i)) =
      (Xᵀ * diagonal (poissonMean X β) * X)⁻¹ *ᵥ
        ((Xᵀ * diagonal (poissonMean X β)) *ᵥ workingResponse X y β) := by
  have hμ : ∀ i, poissonMean X β i ≠ 0 := fun i => (Real.exp_pos _).ne'
  set A := Xᵀ * diagonal (poissonMean X β) * X with hAdef
  have hz : (Xᵀ * diagonal (poissonMean X β)) *ᵥ workingResponse X y β =
      A *ᵥ β + Xᵀ *ᵥ (fun i => (y i : ℝ) - poissonMean X β i) := by
    rw [hAdef, ← Matrix.mulVec_mulVec, ← Matrix.mulVec_mulVec, ← Matrix.mulVec_mulVec,
      ← Matrix.mulVec_add]
    congr 1
    ext i
    simp only [Matrix.mulVec_diagonal, Pi.add_apply, workingResponse]
    field_simp [hμ i]
  rw [hz, Matrix.mulVec_add, Matrix.mulVec_mulVec β A⁻¹ A, Matrix.nonsing_inv_mul _ hA,
    Matrix.one_mulVec]

/-- **One peak.** The Poisson log-likelihood is concave in the coefficients, for any predictor
table and any counts, so it has at most one top. -/
theorem poisson_loglik_concave {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (y : Fin n → ℕ) :
    ConcaveOn ℝ Set.univ (poissonLogLik X y) := by
  have hterm : ∀ i ∈ (Finset.univ : Finset (Fin n)), ConcaveOn ℝ Set.univ
      (fun β : Fin p → ℝ => (y i : ℝ) * (X *ᵥ β) i - poissonMean X β i
        - Real.log ((y i).factorial : ℝ)) := by
    intro i _
    let g : (Fin p → ℝ) →ₗ[ℝ] ℝ := (LinearMap.proj i).comp (Matrix.mulVecLin X)
    have hg : ∀ β, g β = (X *ᵥ β) i := fun β => rfl
    have h1 : ConcaveOn ℝ Set.univ (fun β : Fin p → ℝ => (y i : ℝ) * (X *ᵥ β) i) := by
      have := ((y i : ℝ) • g).concaveOn (convex_univ (𝕜 := ℝ))
      convert this using 1
      funext β
      simp [hg]
    have h2 : ConvexOn ℝ Set.univ (fun β : Fin p → ℝ => poissonMean X β i) := by
      have := convexOn_exp.comp_linearMap g
      simpa [Function.comp_def, hg, poissonMean] using this
    have h3 := (h1.sub h2).sub (convexOn_const (Real.log ((y i).factorial : ℝ))
      (convex_univ (𝕜 := ℝ)))
    exact h3
  exact glm_concaveOn_sum _ _ hterm

/-- **The slopes of the log-likelihood.** Moving the coefficients from `β` in any direction `d`,
the log-likelihood changes at the rate `∑ i, (y i - μ i) * (X d) i`. So the slopes are the sums
`∑ i, X i j * (y i - μ i)`, and setting them to zero gives the likelihood equations. -/
theorem poisson_loglik_slope {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (y : Fin n → ℕ)
    (β d : Fin p → ℝ) :
    HasDerivAt (fun t : ℝ => poissonLogLik X y (β + t • d))
      (∑ i, ((y i : ℝ) - poissonMean X β i) * (X *ᵥ d) i) 0 := by
  have hexp : ∀ t : ℝ, poissonLogLik X y (β + t • d) =
      ∑ i, ((y i : ℝ) * ((X *ᵥ β) i + t * (X *ᵥ d) i) - Real.exp ((X *ᵥ β) i + t * (X *ᵥ d) i)
        - Real.log ((y i).factorial : ℝ)) := by
    intro t
    simp [poissonLogLik, poissonMean, Matrix.mulVec_add, Matrix.mulVec_smul]
  simp_rw [hexp]
  have hlin : ∀ i, HasDerivAt (fun t : ℝ => (X *ᵥ β) i + t * (X *ᵥ d) i) ((X *ᵥ d) i) 0 := by
    intro i
    simpa using ((hasDerivAt_id (0 : ℝ)).mul_const ((X *ᵥ d) i)).const_add ((X *ᵥ β) i)
  apply HasDerivAt.fun_sum
  intro i _
  have h1 := (hlin i).const_mul (y i : ℝ)
  have h2 := (hlin i).exp
  have h3 := (h1.sub h2).sub_const (Real.log ((y i).factorial : ℝ))
  convert h3 using 1
  simp [poissonMean]
  ring

/-! The help-desk data: staff `1, 2, 3, 4`, emails `14, 10, 7, 5`. -/

-- The mean count is 36 ÷ 4 = 9, the starting mean of every hour.
example : ((14 + 10 + 7 + 5 : ℚ)) / 4 = 9 := by norm_num

-- At the start (every mean 9) the slopes of ℓ are 0 and −15.
example : ((14 - 9) + (10 - 9) + (7 - 9) + (5 - 9) : ℚ) = 0 := by norm_num
example : (1 * (14 - 9) + 2 * (10 - 9) + 3 * (7 - 9) + 4 * (5 - 9) : ℚ) = -15 := by norm_num

-- First IRLS step, equal weights: slope = ∑ (x i - 2.5)(z i - ln 9) ÷ ∑ (x i - 2.5)², with
-- z i - ln 9 = (y i - 9)/9; this is −1.6667 ÷ 5 = −1/3.
example : ((-3/2 : ℚ) * (5/9) + (-1/2) * (1/9) + (1/2) * (-2/9) + (3/2) * (-4/9)) /
    ((-3/2 : ℚ)^2 + (-1/2)^2 + (1/2)^2 + (3/2)^2) = -1/3 := by norm_num

-- The same step by Newton: with every weight 9, `Xᵀ W X = [[36, 90], [90, 270]]`, and the step
-- (5/6, −1/3) added to (ln 9, 0) solves `Xᵀ W X · step = slopes = (0, −15)`.
example : !![(36 : ℚ), 90; 90, 270] *ᵥ ![5/6, -1/3] = ![0, -15] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- Least squares as a GLM (normal family, identity link): slope −15 ÷ 5 = −3, intercept
-- 9 + 3 × 2.5 = 16.5, and the line predicts 16.5 − 3 × 6 = −1.5 emails at 6 staff.
example : ((-3/2 : ℚ) * 5 + (-1/2) * 1 + (1/2) * (-2) + (3/2) * (-4)) /
    ((-3/2 : ℚ)^2 + (-1/2)^2 + (1/2)^2 + (3/2)^2) = -3 := by norm_num
example : (9 : ℚ) - (-3) * (5/2) = 33/2 := by norm_num
example : (33/2 : ℚ) - 3 * 6 = -3/2 := by norm_num

#print axioms glm_concaveOn_sum
#print axioms irls_step_eq_newton_step
#print axioms poisson_loglik_concave
#print axioms poisson_loglik_slope
