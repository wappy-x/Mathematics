-- The matrix exponential: for every square real matrix A, x(t) = e^(tA) x₀ solves x' = Ax with x(0) = x₀ and is the only solution, e^((s+t)A) = e^(sA) e^(tA), and the heater matrix with a missing eigenvector has e^(tJ) = e^(-t) [[1, t], [0, 1]].
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.MeanValue

open Matrix NormedSpace

theorem entry_deriv (n : ℕ) (A : Matrix (Fin n) (Fin n) ℝ) (t : ℝ) (i j : Fin n) :
    HasDerivAt (fun u : ℝ => exp (u • A) i j) ((exp (t • A) * A) i j) t := by
  open scoped Norms.Operator in
  have h := hasDerivAt_exp_smul_const (𝕂 := ℝ) A t
  open scoped Norms.Operator in
  let L : Matrix (Fin n) (Fin n) ℝ →L[ℝ] ℝ :=
    LinearMap.toContinuousLinearMap (Matrix.entryLinearMap ℝ ℝ i j)
  exact HasFDerivAt.comp_hasDerivAt t L.hasFDerivAt h

#print axioms entry_deriv

theorem mulVec_deriv (n : ℕ) (M : ℝ → Matrix (Fin n) (Fin n) ℝ) (M' : Matrix (Fin n) (Fin n) ℝ)
    (v : ℝ → Fin n → ℝ) (v' : Fin n → ℝ) (t : ℝ)
    (hM : ∀ i j, HasDerivAt (fun u => M u i j) (M' i j) t) (hv : HasDerivAt v v' t) :
    HasDerivAt (fun u => M u *ᵥ v u) (M' *ᵥ v t + M t *ᵥ v') t := by
  rw [hasDerivAt_pi] at hv ⊢
  intro i
  simp only [Pi.add_apply, mulVec, dotProduct]
  rw [← Finset.sum_add_distrib]
  apply HasDerivAt.fun_sum
  intro j _
  exact (hM i j).mul (hv j)

#print axioms mulVec_deriv

theorem exp_deriv (n : ℕ) (A : Matrix (Fin n) (Fin n) ℝ) (x₀ : Fin n → ℝ) (t : ℝ) :
    HasDerivAt (fun s : ℝ => exp (s • A) *ᵥ x₀) (A *ᵥ (exp (t • A) *ᵥ x₀)) t := by
  have h := mulVec_deriv n (fun u => exp (u • A)) (exp (t • A) * A) (fun _ => x₀) 0 t
    (entry_deriv n A t) (hasDerivAt_const t x₀)
  have hc : Commute A (exp (t • A)) := (Commute.refl A).smul_right t |>.exp_right
  convert h using 1
  rw [mulVec_zero, add_zero, mulVec_mulVec, hc.eq]

#print axioms exp_deriv

/-- For every square matrix A (any size n, real entries, fixed in time) and every starting
state x₀, the state x(t) = e^(tA) x₀ built from the power series starts at x₀, has rate
A x(t) at every time t, and is the only function with that rate and that start: multiplying
the start by e^(tA) gives the state at time t. No eigenvectors are needed. -/
theorem matrix_exponential_solves_linear_system (n : ℕ) (A : Matrix (Fin n) (Fin n) ℝ)
    (x₀ : Fin n → ℝ) :
    exp ((0 : ℝ) • A) *ᵥ x₀ = x₀ ∧
    (∀ t : ℝ, HasDerivAt (fun s : ℝ => exp (s • A) *ᵥ x₀) (A *ᵥ (exp (t • A) *ᵥ x₀)) t) ∧
    (∀ y : ℝ → Fin n → ℝ, (∀ t, HasDerivAt y (A *ᵥ y t) t) → y 0 = x₀ →
      ∀ t, y t = exp (t • A) *ᵥ x₀) := by
  refine ⟨by simp, exp_deriv n A x₀, ?_⟩
  intro y hy h0 t
  set z : ℝ → Fin n → ℝ := fun u => exp (u • -A) *ᵥ y u with hz
  have hzd : ∀ u, HasDerivAt z 0 u := by
    intro u
    have h := mulVec_deriv n (fun u => exp (u • -A)) (exp (u • -A) * -A) y (A *ᵥ y u) u
      (entry_deriv n (-A) u) (hy u)
    convert h using 1
    rw [mulVec_mulVec, Matrix.mul_neg, Matrix.neg_mulVec, neg_add_cancel]
  have hconst : z t = z 0 := is_const_of_deriv_eq_zero
    (fun u => (hzd u).differentiableAt) (fun u => (hzd u).deriv) t 0
  have hz0 : z 0 = x₀ := by simp [hz, h0]
  have hinv : exp (t • A) * exp (t • -A) = 1 := by
    rw [← Matrix.exp_add_of_commute _ _ (((Commute.refl A).smul_left t).neg_right.smul_right t)]
    simp
  calc y t = (exp (t • A) * exp (t • -A)) *ᵥ y t := by rw [hinv, one_mulVec]
    _ = exp (t • A) *ᵥ z t := by rw [← mulVec_mulVec]
    _ = exp (t • A) *ᵥ x₀ := by rw [hconst, hz0]

/-- Running forward s hours and then t more is running s + t hours:
e^((s+t)A) = e^(sA) e^(tA), for every square matrix A and all real s, t. -/
theorem matrix_exponential_add_time (n : ℕ) (A : Matrix (Fin n) (Fin n) ℝ) (s t : ℝ) :
    exp ((s + t) • A) = exp (s • A) * exp (t • A) := by
  rw [add_smul]
  exact Matrix.exp_add_of_commute _ _ (((Commute.refl A).smul_left s).smul_right t)

/-- When eigenvectors run out the series still sums: for the heater matrix
J = [[-1, 1], [0, -1]], whose repeated eigenvalue -1 has only one eigenvector,
e^(tJ) = e^(-t) [[1, t], [0, 1]], and the factor t marks the missing eigenvector. -/
theorem matrix_exponential_jordan_block (t : ℝ) :
    exp (t • !![(-1 : ℝ), 1; 0, -1]) = Real.exp (-t) • !![(1 : ℝ), t; 0, 1] := by
  have hsplit : t • !![(-1 : ℝ), 1; 0, -1] = (-t) • (1 : Matrix (Fin 2) (Fin 2) ℝ) + t • !![0, 1; 0, 0] := by
    ext i j; fin_cases i <;> fin_cases j <;> simp
  have hc : Commute ((-t) • (1 : Matrix (Fin 2) (Fin 2) ℝ)) (t • !![(0:ℝ), 1; 0, 0]) :=
    ((Commute.one_left _).smul_left _)
  rw [hsplit, Matrix.exp_add_of_commute _ _ hc]
  have h1 : exp ((-t) • (1 : Matrix (Fin 2) (Fin 2) ℝ)) = Real.exp (-t) • (1 : Matrix (Fin 2) (Fin 2) ℝ) := by
    have hd : (-t) • (1 : Matrix (Fin 2) (Fin 2) ℝ) = diagonal (fun _ => -t) := by
      ext i j; fin_cases i <;> fin_cases j <;> simp
    rw [hd, Matrix.exp_diagonal, Pi.exp_def, ← Real.exp_eq_exp_ℝ]
    ext i j; fin_cases i <;> fin_cases j <;> simp
  have h2 : exp (t • !![(0:ℝ), 1; 0, 0]) = 1 + t • !![(0:ℝ), 1; 0, 0] := by
    have hN : !![(0:ℝ), 1; 0, 0] * !![(0:ℝ), 1; 0, 0] = 0 := by
      ext i j; fin_cases i <;> fin_cases j <;> simp
    rw [congrFun (exp_eq_tsum ℝ) _]
    rw [tsum_eq_sum (s := Finset.range 2)]
    · simp [Finset.sum_range_succ]
    · intro k hk
      simp only [Finset.mem_range, not_lt] at hk
      obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hk
      have hp : !![(0:ℝ), 1; 0, 0] ^ (2 + m) = 0 := by
        rw [pow_add, pow_two, hN, zero_mul]
      rw [smul_pow, hp]
      simp
  rw [h1, h2]
  ext i j; fin_cases i <;> fin_cases j <;> simp

-- The rooms' eigenvalues: (-2 - λ)^2 - 1 = 0 at λ = -1 and λ = -3.
example : ((-2 : ℝ) - (-1)) ^ 2 - 1 = 0 ∧ ((-2 : ℝ) - (-3)) ^ 2 - 1 = 0 := by norm_num

-- "Rooms equal" (1, 1) shrinks at -1 per hour; "rooms opposite" (1, -1) at -3 per hour.
example : !![(-2 : ℝ), 1; 1, -2] *ᵥ ![1, 1] = (-1 : ℝ) • ![1, 1] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num
example : !![(-2 : ℝ), 1; 1, -2] *ᵥ ![1, -1] = (-3 : ℝ) • ![1, -1] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- Split the start: (30, 10) = 20 (1, 1) + 10 (1, -1).
example : (![30, 10] : Fin 2 → ℝ) = (20 : ℝ) • ![1, 1] + (10 : ℝ) • ![1, -1] := by
  ext i; fin_cases i <;> simp <;> norm_num

-- Starting rates: room 1 at -50 C per hour, room 2 at 30 - 2 × 10 = +10 C per hour.
example : !![(-2 : ℝ), 1; 1, -2] *ᵥ ![30, 10] = ![-50, 10] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- The wall split into one-way flows: A = -2I + P + Q, and PQ ≠ QP.
example : !![(-2 : ℝ), 1; 1, -2] =
    (-2 : ℝ) • (1 : Matrix (Fin 2) (Fin 2) ℝ) + !![0, 1; 0, 0] + !![0, 0; 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp
example : !![(0 : ℝ), 1; 0, 0] * !![0, 0; 1, 0] ≠ !![0, 0; 1, 0] * !![0, 1; 0, 0] := by
  intro h
  have := congrFun (congrFun h 0) 0
  simp at this

-- The heater: J = -I + N with N N = 0, and (1, 0) is J's eigenvector for -1.
example : !![(-1 : ℝ), 1; 0, -1] = -1 + !![0, 1; 0, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp
example : !![(0 : ℝ), 1; 0, 0] * !![0, 1; 0, 0] = 0 := by
  ext i j; fin_cases i <;> fin_cases j <;> simp
example : !![(-1 : ℝ), 1; 0, -1] *ᵥ ![1, 0] = (-1 : ℝ) • ![1, 0] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two]

#print axioms matrix_exponential_solves_linear_system
#print axioms matrix_exponential_add_time
#print axioms matrix_exponential_jordan_block
