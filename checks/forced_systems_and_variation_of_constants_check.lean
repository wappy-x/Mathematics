-- Forced systems: for a constant real matrix A and a continuous input b, a path solves x' = Ax + b(t) with x(0) = x₀ exactly when x(t) = e^(At)x₀ + ∫₀ᵗ e^(A(t−s)) b(s) ds, and for constant b with A invertible this equals x_eq + e^(At)(x₀ − x_eq) with x_eq = −A⁻¹b; the card's whole-number room checks are verified exactly.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.Calculus.Deriv.Pi
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Analysis.Matrix.Normed
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic

open Matrix

/-! The state `x t` is a vector in `Fin n → ℝ`, the rate matrix `A` is a constant real
n × n matrix, and `A *ᵥ v` is A applied to the vector `v`. The propagator `e^(At)` is Mathlib's
matrix exponential `NormedSpace.exp (t • A)`. The forced system `x' = Ax + b(t)` is
`∀ t, HasDerivAt x (A *ᵥ x t + b t) t`. The input `b` is taken continuous, as in the card's
detailed proof. -/

section
open scoped Norms.Operator

theorem fsvc_hasDerivAt_exp_mulVec {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    {v : ℝ → Fin n → ℝ} {v' : Fin n → ℝ} {t : ℝ} (hv : HasDerivAt v v' t) :
    HasDerivAt (fun u => NormedSpace.exp (u • A) *ᵥ v u)
      (A *ᵥ (NormedSpace.exp (t • A) *ᵥ v t) + NormedSpace.exp (t • A) *ᵥ v') t := by
  let B : Matrix (Fin n) (Fin n) ℝ →L[ℝ] (Fin n → ℝ) →L[ℝ] (Fin n → ℝ) :=
    LinearMap.mkContinuous₂ (Matrix.mulVecBilin ℝ ℝ) 1
      (fun M w => by simpa using Matrix.linfty_opNorm_mulVec M w)
  have hE := hasDerivAt_exp_smul_const' (𝕂 := ℝ) A t
  have := B.hasDerivAt_of_bilinear (fun _ => hE) (fun _ => hv)
  refine this.congr_deriv ?_
  change NormedSpace.exp (t • A) *ᵥ v' + (A * NormedSpace.exp (t • A)) *ᵥ v t = _
  rw [← Matrix.mulVec_mulVec]
  abel

end

theorem fsvc_continuous_exp {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) :
    Continuous (fun u : ℝ => NormedSpace.exp (u • A)) := by
  open scoped Norms.Operator in
  exact (differentiable_exp_smul_const ℝ A).continuous

theorem fsvc_exp_sub {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (u w : ℝ) :
    NormedSpace.exp ((u - w) • A) = NormedSpace.exp (u • A) * NormedSpace.exp ((-w) • A) := by
  rw [← Matrix.exp_add_of_commute _ _ (((Commute.refl A).smul_left u).smul_right (-w))]
  congr 1
  rw [sub_eq_add_neg, add_smul]

theorem fsvc_exp_comm {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (u : ℝ) :
    A * NormedSpace.exp (u • A) = NormedSpace.exp (u • A) * A :=
  (((Commute.refl A).smul_right u).exp_right).eq

/-- **Variation of constants: the only solution of a forced linear system.** Let `A` be a
constant real n × n matrix and `b` a continuous input. A path `x` solves `x' = Ax + b(t)` with
`x(0) = x₀` exactly when, at every time `t`, the state is the start carried forward `t`,
`e^(At) x₀`, plus every past input `b(s)` carried forward the `t − s` since it arrived:
`x(t) = e^(At) x₀ + ∫₀ᵗ e^(A(t−s)) b(s) ds`. -/
theorem forced_system_solution_is_start_plus_propagated_inputs
    {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (b : ℝ → Fin n → ℝ) (hb : Continuous b)
    (x₀ : Fin n → ℝ) (x : ℝ → Fin n → ℝ) :
    ((∀ t, HasDerivAt x (A *ᵥ x t + b t) t) ∧ x 0 = x₀) ↔
      ∀ t, x t = NormedSpace.exp (t • A) *ᵥ x₀ +
        ∫ s in (0 : ℝ)..t, NormedSpace.exp ((t - s) • A) *ᵥ b s := by
  have hEinv : ∀ u : ℝ, NormedSpace.exp (u • A) * NormedSpace.exp ((-u) • A) = 1 := by
    intro u; rw [← fsvc_exp_sub, sub_self, zero_smul, NormedSpace.exp_zero]
  have hcont : Continuous (fun s : ℝ => NormedSpace.exp ((-s) • A) *ᵥ b s) :=
    ((fsvc_continuous_exp A).comp continuous_neg).matrix_mulVec hb
  let g : ℝ → Fin n → ℝ := fun u => ∫ s in (0 : ℝ)..u, NormedSpace.exp ((-s) • A) *ᵥ b s
  have hg : ∀ t, HasDerivAt g (NormedSpace.exp ((-t) • A) *ᵥ b t) t := fun t =>
    intervalIntegral.integral_hasDerivAt_right (hcont.intervalIntegrable _ _)
      (hcont.stronglyMeasurableAtFilter _ _) hcont.continuousAt
  let F : ℝ → Fin n → ℝ := fun u => NormedSpace.exp (u • A) *ᵥ (x₀ + g u)
  have hF : ∀ t, HasDerivAt F (A *ᵥ F t + b t) t := by
    intro t
    refine (fsvc_hasDerivAt_exp_mulVec A ((hasDerivAt_const t x₀).add (hg t))).congr_deriv ?_
    rw [zero_add, show NormedSpace.exp (t • A) *ᵥ (NormedSpace.exp ((-t) • A) *ᵥ b t) = b t by
      rw [Matrix.mulVec_mulVec, hEinv, Matrix.one_mulVec]]
    rfl
  have hF0 : F 0 = x₀ := by
    simp [F, g]
  have hFeq : ∀ t, F t = NormedSpace.exp (t • A) *ᵥ x₀ +
      ∫ s in (0 : ℝ)..t, NormedSpace.exp ((t - s) • A) *ᵥ b s := by
    intro t
    let L : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ) :=
      LinearMap.toContinuousLinearMap (Matrix.mulVecLin (NormedSpace.exp (t • A)))
    have hL := L.intervalIntegral_comp_comm (hcont.intervalIntegrable (μ := MeasureTheory.volume) (0 : ℝ) t)
    simp only [F, g, Matrix.mulVec_add]
    congr 1
    refine (hL.symm.trans ?_)
    refine intervalIntegral.integral_congr (fun s _ => ?_)
    simp only [L, LinearMap.coe_toContinuousLinearMap', Matrix.mulVecLin_apply,
      Matrix.mulVec_mulVec, fsvc_exp_sub A t s]
  have hv : ∀ t, LipschitzOnWith
      ‖LinearMap.toContinuousLinearMap (Matrix.mulVecLin A)‖₊
      (fun y => A *ᵥ y + b t) Set.univ := by
    intro t
    refine (LipschitzWith.of_dist_le_mul fun y z => ?_).lipschitzOnWith
    rw [dist_eq_norm, dist_eq_norm, add_sub_add_right_eq_sub, ← Matrix.mulVec_sub]
    exact (LinearMap.toContinuousLinearMap (Matrix.mulVecLin A)).le_opNorm (y - z)
  constructor
  · rintro ⟨hx, h0⟩ t
    have hxF : x = F := ODE_solution_unique_univ (v := fun t y => A *ᵥ y + b t)
      (s := fun _ => Set.univ) (t₀ := 0) hv (fun t => ⟨hx t, trivial⟩)
      (fun t => ⟨hF t, trivial⟩) (h0.trans hF0.symm)
    rw [hxF]
    exact hFeq t
  · intro h
    have hxF : x = F := funext fun t => (h t).trans (hFeq t).symm
    subst hxF
    exact ⟨hF, hF0⟩

/-- **Constant input: the settled state plus the start's gap decaying freely** (Step 5). If the
input `b` is constant and `A` is invertible (`det A ≠ 0`), the settled state
`x_eq = −A⁻¹ b` is where the rates stop, `A x_eq + b = 0`, and the variation-of-constants
formula equals `x_eq + e^(At)(x₀ − x_eq)` at every time `t`. -/
theorem constant_input_settled_state_shortcut
    {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : IsUnit A.det) (b x₀ : Fin n → ℝ) (t : ℝ) :
    A *ᵥ (-(A⁻¹ *ᵥ b)) + b = 0 ∧
      NormedSpace.exp (t • A) *ᵥ x₀ + ∫ s in (0 : ℝ)..t, NormedSpace.exp ((t - s) • A) *ᵥ b =
        -(A⁻¹ *ᵥ b) + NormedSpace.exp (t • A) *ᵥ (x₀ - -(A⁻¹ *ᵥ b)) := by
  have hAc : A *ᵥ (A⁻¹ *ᵥ b) = b := by
    rw [Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv A hA, Matrix.one_mulVec]
  refine ⟨by rw [Matrix.mulVec_neg, hAc, neg_add_cancel], ?_⟩
  set c := A⁻¹ *ᵥ b
  have hderiv : ∀ s : ℝ, HasDerivAt (fun s : ℝ => -(NormedSpace.exp ((t - s) • A) *ᵥ c))
      (NormedSpace.exp ((t - s) • A) *ᵥ b) s := by
    intro s
    have h1 := fsvc_hasDerivAt_exp_mulVec A (hasDerivAt_const (t - s) c)
    have h2 := (h1.scomp s ((hasDerivAt_id' s).const_sub t)).neg
    refine h2.congr_deriv ?_
    rw [Matrix.mulVec_zero, add_zero, Matrix.mulVec_mulVec, fsvc_exp_comm,
      ← Matrix.mulVec_mulVec, hAc]
    simp
  have hcont : Continuous (fun s : ℝ => NormedSpace.exp ((t - s) • A) *ᵥ b) :=
    ((fsvc_continuous_exp A).comp (continuous_const.sub continuous_id)).matrix_mulVec
      continuous_const
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun s _ => hderiv s)
    (hcont.intervalIntegrable _ _)]
  simp only [sub_self, zero_smul, NormedSpace.exp_zero, Matrix.one_mulVec, sub_zero,
    Matrix.mulVec_sub, Matrix.mulVec_neg]
  abel

/-! The card's whole-number checks on the two rooms: A = [[-2, 1], [1, -2]], b = (15, 0). -/

-- Determinant of A: (−2)(−2) − (1)(1) = 3.
example : (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℚ).det = 3 := by
  rw [det_fin_two_of]; norm_num
-- A⁻¹ = −(1/3)[[2, 1], [1, 2]]: check A × (−(1/3)[[2, 1], [1, 2]]) = I.
example : (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℚ) * (-(1 / 3 : ℚ) • !![2, 1; 1, 2]) = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> norm_num
-- Settled state: −A⁻¹(15, 0) = (1/3)(2 × 15, 1 × 15) = (10, 5).
example : (1 / 3 : ℚ) • (!![2, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![15, 0] = ![10, 5] := by
  ext i; fin_cases i <;> simp <;> norm_num
-- At (10, 5) the rates stop: A(10, 5) + (15, 0) = 0.
example : (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![10, 5] + ![15, 0] = 0 := by
  ext i; fin_cases i <;> simp <;> norm_num
-- Cold start's gap: (0, 0) − (10, 5) = (−10, −5) = −(15/2)(1, 1) − (5/2)(1, −1).
example : (![0, 0] : Fin 2 → ℚ) - ![10, 5] = ![-10, -5] := by
  ext i; fin_cases i <;> simp
example : (-(15 / 2) : ℚ) • (![1, 1] : Fin 2 → ℚ) + (-(5 / 2) : ℚ) • ![1, -1] = ![-10, -5] := by
  ext i; fin_cases i <;> simp <;> norm_num
-- At t = 0 the mode formulas give 10 − 15/2 − 5/2 = 0 and 5 − 15/2 + 5/2 = 0: the cold start.
example : (10 : ℚ) - 15 / 2 - 5 / 2 = 0 ∧ (5 : ℚ) - 15 / 2 + 5 / 2 = 0 := by norm_num
-- Room 2's starting rate is 15/2 − 15/2 = 0: from cold, Ax₀ + b = (15, 0), nothing in room 2.
example : (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![0, 0] + ![15, 0] = ![15, 0] := by
  ext i; fin_cases i <;> simp
-- Room 2 is 5 − (15/2)e^(−t) + (5/2)e^(−3t); its rate at 0 is −(15/2)(−1) + (5/2)(−3) = 0.
example : -(15 / 2 : ℚ) * (-1) + (5 / 2) * (-3) = 0 := by norm_num
-- Each half-hour slice of heat puts in 15 × 1/2 = 15/2 C; the mistake "heat added, never
-- propagated" gives 15 × 2 = 30 C.
example : (15 : ℚ) * (1 / 2) = 15 / 2 ∧ (15 : ℚ) * 2 = 30 := by norm_num
-- Insulated walls: A = [[-1, 1], [1, -1]] has determinant 0, so no settled state exists, and
-- the average temperature climbs at (15 + 0)/2 = 15/2 C per hour because (1, 1)A = 0.
example : (!![-1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℚ).det = 0 := by
  rw [det_fin_two_of]; norm_num
example : (![1, 1] : Fin 2 → ℚ) ᵥ* (!![-1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℚ) = 0 := by
  ext j; fin_cases j <;> simp [vecMul, dotProduct, Fin.sum_univ_two]
example : ((15 : ℚ) + 0) / 2 = 15 / 2 := by norm_num

#print axioms forced_system_solution_is_start_plus_propagated_inputs
#print axioms constant_input_settled_state_shortcut
#print axioms fsvc_hasDerivAt_exp_mulVec
#print axioms fsvc_continuous_exp
#print axioms fsvc_exp_sub
#print axioms fsvc_exp_comm
