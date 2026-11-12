-- The eigenvalue method: for a constant real 2 × 2 system x' = Ax with two independent eigenvectors, every start is a mix c₁v₁ + c₂v₂ and the only solution is c₁e^(μ₁t)v₁ + c₂e^(μ₂t)v₂; the card's whole-number checks on the rooms are verified exactly.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Pi
import Mathlib.LinearAlgebra.LinearIndependent.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas

open Matrix

/-! The state `x t` is a vector in `Fin 2 → ℝ`, the rate matrix `A` is a constant real
2 × 2 matrix, and `A *ᵥ x t` is A times the state. `x' = Ax` with no input is
`∀ t, HasDerivAt x (A *ᵥ x t) t`. The eigenvalues are written `μ₁, μ₂` (the card's
`λ₁, λ₂`; `λ` is a reserved word in Lean). -/

/-- **The eigenvalue method gives the only solution.** Let `A` be a constant real 2 × 2
matrix with real eigenvalues `μ₁, μ₂` and eigenvectors `v₁, v₂` (`A v₁ = μ₁ v₁`,
`A v₂ = μ₂ v₂`) that are independent (neither a multiple of the other). Then every start `x₀`
is a mix `c₁ v₁ + c₂ v₂ = x₀`, and a path `x` solves `x' = Ax` with `x(0) = x₀` exactly when
`x(t) = c₁ e^(μ₁ t) v₁ + c₂ e^(μ₂ t) v₂` for every time `t`. -/
theorem eigenvalue_method_gives_the_only_solution
    (A : Matrix (Fin 2) (Fin 2) ℝ) (μ₁ μ₂ : ℝ) (v₁ v₂ : Fin 2 → ℝ)
    (h₁ : A *ᵥ v₁ = μ₁ • v₁) (h₂ : A *ᵥ v₂ = μ₂ • v₂)
    (hind : LinearIndependent ℝ ![v₁, v₂]) (x₀ : Fin 2 → ℝ) :
    ∃ c₁ c₂ : ℝ, c₁ • v₁ + c₂ • v₂ = x₀ ∧
      ∀ x : ℝ → Fin 2 → ℝ,
        ((∀ t, HasDerivAt x (A *ᵥ x t) t) ∧ x 0 = x₀) ↔
          ∀ t, x t = (c₁ * Real.exp (μ₁ * t)) • v₁ + (c₂ * Real.exp (μ₂ * t)) • v₂ := by
  classical
  let b := basisOfPiSpaceOfLinearIndependent hind
  have hb : ∀ i, b i = ![v₁, v₂] i := by
    intro i; simp only [b, coe_basisOfPiSpaceOfLinearIndependent]
  have hsum := b.sum_repr x₀
  rw [Fin.sum_univ_two, hb, hb] at hsum
  refine ⟨b.repr x₀ 0, b.repr x₀ 1, by simpa using hsum, ?_⟩
  set c₁ := b.repr x₀ 0
  set c₂ := b.repr x₀ 1
  set y : ℝ → Fin 2 → ℝ :=
    fun t => (c₁ * Real.exp (μ₁ * t)) • v₁ + (c₂ * Real.exp (μ₂ * t)) • v₂ with hy
  have hyd : ∀ t, HasDerivAt y (A *ᵥ y t) t := by
    intro t
    have e1 : HasDerivAt (fun s => c₁ * Real.exp (μ₁ * s)) (c₁ * (Real.exp (μ₁ * t) * μ₁)) t :=
      ((((hasDerivAt_id t).const_mul μ₁).exp).congr_deriv (by simp)).const_mul c₁
    have e2 : HasDerivAt (fun s => c₂ * Real.exp (μ₂ * s)) (c₂ * (Real.exp (μ₂ * t) * μ₂)) t :=
      ((((hasDerivAt_id t).const_mul μ₂).exp).congr_deriv (by simp)).const_mul c₂
    have := (e1.smul_const v₁).add (e2.smul_const v₂)
    convert this using 1
    simp only [hy, Matrix.mulVec_add, Matrix.mulVec_smul, h₁, h₂, smul_smul]
    congr 1 <;> congr 1 <;> ring
  have hy0 : y 0 = x₀ := by simpa [hy] using hsum
  have hlip : ∀ _t : ℝ, LipschitzOnWith ‖LinearMap.toContinuousLinearMap (Matrix.mulVecLin A)‖₊
      (fun z => A *ᵥ z) Set.univ := fun _ =>
    (LinearMap.toContinuousLinearMap (Matrix.mulVecLin A)).lipschitzWith.lipschitzOnWith
  intro x
  constructor
  · rintro ⟨hx, hx0⟩
    have := ODE_solution_unique_univ (t₀ := 0) hlip (fun t => ⟨hx t, Set.mem_univ _⟩)
      (fun t => ⟨hyd t, Set.mem_univ _⟩) (by rw [hx0, hy0])
    intro t
    exact congrFun this t
  · intro hxt
    have : x = y := funext hxt
    subst this
    exact ⟨hyd, hy0⟩

/-- **Along an eigenvector the system only stretches** (Step 0). If `A v = μ v`, the state
that keeps the shape `v` and changes size as `e^(μ t)`, `x(t) = e^(μ t) v`, solves `x' = Ax`
at every time `t`. -/
theorem eigenvector_mode_solves_system
    (A : Matrix (Fin 2) (Fin 2) ℝ) (μ : ℝ) (v : Fin 2 → ℝ) (hv : A *ᵥ v = μ • v) :
    ∀ t, HasDerivAt (fun s => Real.exp (μ * s) • v) (A *ᵥ (Real.exp (μ * t) • v)) t := by
  intro t
  have e : HasDerivAt (fun s => Real.exp (μ * s)) (Real.exp (μ * t) * μ) t :=
    (((hasDerivAt_id t).const_mul μ).exp).congr_deriv (by simp)
  convert e.smul_const v using 1
  rw [Matrix.mulVec_smul, hv, smul_smul]

/-- **Distinct eigenvalues guarantee two independent eigenvectors.** If `v₁` and `v₂` are
nonzero, `A v₁ = μ₁ v₁`, `A v₂ = μ₂ v₂` and `μ₁ ≠ μ₂`, then neither is a multiple of the other:
`v₁, v₂` are linearly independent. -/
theorem distinct_eigenvalues_give_independent_eigenvectors
    (A : Matrix (Fin 2) (Fin 2) ℝ) (μ₁ μ₂ : ℝ) (v₁ v₂ : Fin 2 → ℝ)
    (hv₁ : v₁ ≠ 0) (hv₂ : v₂ ≠ 0) (h₁ : A *ᵥ v₁ = μ₁ • v₁) (h₂ : A *ᵥ v₂ = μ₂ • v₂)
    (hμ : μ₁ ≠ μ₂) :
    LinearIndependent ℝ ![v₁, v₂] := by
  rw [LinearIndependent.pair_iff]
  intro s t hst
  have hA : A *ᵥ (s • v₁ + t • v₂) = 0 := by rw [hst, Matrix.mulVec_zero]
  rw [Matrix.mulVec_add, Matrix.mulVec_smul, Matrix.mulVec_smul, h₁, h₂, smul_smul,
    smul_smul] at hA
  have hs : (s * (μ₁ - μ₂)) • v₁ = 0 := by
    have : (s * μ₁) • v₁ + (t * μ₂) • v₂ - μ₂ • (s • v₁ + t • v₂) = 0 := by
      rw [hA, hst, smul_zero, sub_zero]
    rw [← this, smul_add, smul_smul, smul_smul]
    rw [mul_sub, sub_smul, mul_comm μ₂ t, mul_comm μ₂ s]
    abel
  rcases smul_eq_zero.mp hs with h | h
  · rcases mul_eq_zero.mp h with h | h
    · subst h
      simp only [zero_smul, zero_add] at hst
      exact ⟨rfl, (smul_eq_zero.mp hst).resolve_right hv₂⟩
    · exact absurd (sub_eq_zero.mp h) hμ
  · exact absurd h hv₁

/-! The card's whole-number checks. -/

-- The rooms: A = [[-2, 1], [1, -2]]. Diagonal sum −4, determinant 4 − 1 = 3.
example : (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℚ).trace = -4 := by
  simp [Matrix.trace, Fin.sum_univ_two]; norm_num
example : (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℚ).det = 3 := by
  rw [det_fin_two_of]; norm_num
-- Characteristic equation: det(A − λI) = (−2 − λ)² − 1 = λ² + 4λ + 3 = (λ + 1)(λ + 3).
example (l : ℚ) : (-2 - l) * (-2 - l) - 1 * 1 = l ^ 2 + 4 * l + 3 := by ring
example (l : ℚ) : l ^ 2 + 4 * l + 3 = (l + 1) * (l + 3) := by ring
-- A times (1, 1) is (−1, −1) = −1 × (1, 1); A times (1, −1) is (−3, 3) = −3 × (1, −1).
example : (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, 1] = ![-1, -1] ∧
    (![-1, -1] : Fin 2 → ℚ) = (-1 : ℚ) • ![1, 1] := by
  refine ⟨?_, ?_⟩ <;> ext i <;> fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;>
    norm_num
example : (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, -1] = ![-3, 3] ∧
    (![-3, 3] : Fin 2 → ℚ) = (-3 : ℚ) • ![1, -1] := by
  refine ⟨?_, ?_⟩ <;> ext i <;> fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;>
    norm_num
-- Weights: 20 (1, 1) + 10 (1, −1) = (30, 10).
example : (20 : ℚ) • (![1, 1] : Fin 2 → ℚ) + (10 : ℚ) • ![1, -1] = ![30, 10] := by
  ext i; fin_cases i <;> simp <;> norm_num
-- Adding the rows gives 2c₁ = 40, subtracting gives 2c₂ = 20.
example : (30 : ℚ) + 10 = 2 * 20 ∧ (30 : ℚ) - 10 = 2 * 10 := by norm_num

-- The half-size room: B = [[-3, 1], [2, -4]]. Diagonal sum −7, determinant 12 − 2 = 10,
-- λ² + 7λ + 10 = (λ + 2)(λ + 5).
example : (!![-3, 1; 2, -4] : Matrix (Fin 2) (Fin 2) ℚ).det = 10 := by
  rw [det_fin_two_of]; norm_num
example (l : ℚ) : (-3 - l) * (-4 - l) - 1 * 2 = (l + 2) * (l + 5) := by ring
-- Eigenvectors (1, 1) for −2 and (1, −2) for −5.
example : (!![-3, 1; 2, -4] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, 1] = (-2 : ℚ) • ![1, 1] ∧
    (!![-3, 1; 2, -4] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, -2] = (-5 : ℚ) • ![1, -2] := by
  refine ⟨?_, ?_⟩ <;> ext i <;> fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;>
    norm_num
-- They are not at right angles: 1 × 1 + 1 × (−2) = −1.
example : (1 : ℚ) * 1 + 1 * (-2) = -1 := by norm_num
-- Weights c₁ = 70/3 (23.333) and c₂ = 20/3 (6.667) rebuild (30, 10).
example : (70 / 3 : ℚ) • (![1, 1] : Fin 2 → ℚ) + (20 / 3 : ℚ) • ![1, -2] = ![30, 10] := by
  ext i; fin_cases i <;> simp <;> norm_num

-- Mistake: weights from P times the start, P = [[1, 1], [1, -1]], give (40, 20), which rebuild
-- (60, 20), not (30, 10).
example : (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![30, 10] = ![40, 20] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num
example : (40 : ℚ) • (![1, 1] : Fin 2 → ℚ) + (20 : ℚ) • ![1, -1] = ![60, 20] := by
  ext i; fin_cases i <;> simp <;> norm_num
-- Mistake: dot-product weights on the half-size room, (30 + 10)/2 = 20 and (30 − 20)/5 = 2,
-- rebuild (22, 16), not (30, 10).
example : ((30 : ℚ) * 1 + 10 * 1) / (1 * 1 + 1 * 1) = 20 ∧
    ((30 : ℚ) * 1 + 10 * (-2)) / (1 * 1 + (-2) * (-2)) = 2 := by norm_num
example : (20 : ℚ) • (![1, 1] : Fin 2 → ℚ) + (2 : ℚ) • ![1, -2] = ![22, 16] := by
  ext i; fin_cases i <;> simp <;> norm_num
-- Repeated eigenvalue: J = [[-1, 1], [0, -1]] has det(J − λI) = (λ + 1)², and (1, 0) is a
-- direction it only stretches, by −1.
example (l : ℚ) : (-1 - l) * (-1 - l) - 1 * 0 = (l + 1) ^ 2 := by ring
example : (!![-1, 1; 0, -1] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, 0] = (-1 : ℚ) • ![1, 0] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two]

#print axioms eigenvalue_method_gives_the_only_solution
#print axioms eigenvector_mode_solves_system
#print axioms distinct_eigenvalues_give_independent_eigenvectors
