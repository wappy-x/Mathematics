-- From one equation to a system: an equation in the nth rate of one unknown has exactly the same solutions as the first-order system for its state (the unknown and its first n - 1 rates), a linear one becomes x' = A x with the companion matrix A, and the eigenvalues of A are the roots of the characteristic equation.
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Complex.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Complex.Basic
import Mathlib.Tactic

open Matrix Complex

/-- The rate of the state in the first-order system built from `y⁽ⁿ⁾ = f t (y, y', …, y⁽ⁿ⁻¹⁾)`:
each entry's rate is the next entry, and the last entry's rate is the equation's right-hand side. -/
def systemRate {n : ℕ} (f : ℝ → (Fin n → ℝ) → ℝ) (t : ℝ) (x : Fin n → ℝ) : Fin n → ℝ :=
  fun k => if h : (k : ℕ) + 1 < n then x ⟨k + 1, h⟩ else f t x

/-- The companion matrix of `y⁽ⁿ⁾ + aₙ₋₁ y⁽ⁿ⁻¹⁾ + … + a₀ y = 0`: 1s just above the diagonal,
and the coefficients, sign-flipped, along the bottom row. -/
def companion {K : Type*} [Ring K] {n : ℕ} (a : Fin n → K) : Matrix (Fin n) (Fin n) K :=
  Matrix.of fun i j => if (i : ℕ) + 1 < n then (if (j : ℕ) = i + 1 then 1 else 0) else -a j

/-- Entry `i` of the companion matrix times a vector: the next entry, or on the bottom row
minus the coefficient-weighted sum. -/
theorem companion_mulVec_apply {K : Type*} [Ring K] {n : ℕ} (a : Fin n → K) (v : Fin n → K)
    (i : Fin n) :
    (companion a *ᵥ v) i = if h : (i : ℕ) + 1 < n then v ⟨i + 1, h⟩ else -∑ j, a j * v j := by
  simp only [Matrix.mulVec, dotProduct, companion, Matrix.of_apply]
  split_ifs with h
  · rw [Finset.sum_eq_single ⟨i + 1, h⟩]
    · simp
    · intro j _ hj
      have : (j : ℕ) ≠ i + 1 := fun hj' => hj (Fin.ext hj')
      simp [this]
    · simp
  · simp [neg_mul, Finset.sum_neg_distrib]

#print axioms companion_mulVec_apply

/-- Any equation in the nth rate of one unknown, solved for the top rate, `y⁽ⁿ⁾ = f(t, y, …, y⁽ⁿ⁻¹⁾)`,
is n first-order equations in a state vector: a vector function `x` solves the system
(each entry's rate is the next entry, the last entry's rate is `f`) exactly when it is the state
`(y, y', …, y⁽ⁿ⁻¹⁾)` of an n-times differentiable solution `y` of the equation.
Nothing is lost and nothing is gained, and the starting numbers match entry by entry. -/
theorem higher_order_equation_iff_first_order_system (n : ℕ) (f : ℝ → (Fin n → ℝ) → ℝ)
    (x : ℝ → Fin n → ℝ) :
    (∀ t, HasDerivAt x (systemRate f t (x t)) t) ↔
      ∃ y : ℝ → ℝ, (∀ k < n, Differentiable ℝ (iteratedDeriv k y)) ∧
        (∀ t, iteratedDeriv n y t = f t (fun k => iteratedDeriv (k : ℕ) y t)) ∧
        x = fun t (k : Fin n) => iteratedDeriv (k : ℕ) y t := by
  constructor
  · intro hx
    have hcomp : ∀ (k : Fin n) t, HasDerivAt (fun s => x s k) (systemRate f t (x t) k) t :=
      fun k t => hasDerivAt_pi.1 (hx t) k
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · refine ⟨fun t => f t Fin.elim0, by simp, ?_, ?_⟩
      · intro t
        simp only [iteratedDeriv_zero]
        congr 1
        funext k
        exact k.elim0
      · funext t k
        exact k.elim0
    · let y := fun t => x t ⟨0, hn⟩
      have key : ∀ k (hk : k < n), iteratedDeriv k y = fun t => x t ⟨k, hk⟩ := by
        intro k
        induction k with
        | zero => intro hk; simp [iteratedDeriv_zero, y]
        | succ k ih =>
          intro hk
          rw [iteratedDeriv_succ, ih (by omega)]
          funext t
          rw [(hcomp ⟨k, by omega⟩ t).deriv]
          simp [systemRate, hk]
      refine ⟨y, fun k hk => ?_, fun t => ?_, ?_⟩
      · rw [key k hk]
        exact fun t => (hcomp ⟨k, hk⟩ t).differentiableAt
      · obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
        rw [iteratedDeriv_succ, key m (by omega), (hcomp ⟨m, by omega⟩ t).deriv]
        simp only [systemRate, lt_self_iff_false, dite_false]
        congr 1
        funext k
        rw [key k k.2]
      · funext t k
        rw [key k k.2]
  · rintro ⟨y, hd, heq, rfl⟩ t
    rw [hasDerivAt_pi]
    intro k
    have h1 := (hd k k.2 t).hasDerivAt
    rw [← iteratedDeriv_succ] at h1
    simp only [systemRate]
    split_ifs with h
    · exact h1
    · have h2 : (k : ℕ) + 1 = n := by omega
      rw [h2, heq t] at h1
      exact h1

/-- A linear equation with fixed coefficients, `y⁽ⁿ⁾ + aₙ₋₁ y⁽ⁿ⁻¹⁾ + … + a₀ y = 0`, is the single line
`x' = A x` with `A` the companion matrix: `x` solves `x' = A x` exactly when it is the state of a solution. -/
theorem linear_equation_iff_companion_system (n : ℕ) (a : Fin n → ℝ) (x : ℝ → Fin n → ℝ) :
    (∀ t, HasDerivAt x (companion a *ᵥ x t) t) ↔
      ∃ y : ℝ → ℝ, (∀ k < n, Differentiable ℝ (iteratedDeriv k y)) ∧
        (∀ t, iteratedDeriv n y t + ∑ k : Fin n, a k * iteratedDeriv (k : ℕ) y t = 0) ∧
        x = fun t (k : Fin n) => iteratedDeriv (k : ℕ) y t := by
  have hrate : ∀ t v, companion a *ᵥ v = systemRate (fun _ w => -∑ k, a k * w k) t v := by
    intro t v
    funext i
    rw [companion_mulVec_apply]
    rfl
  have hiff : (∀ t, HasDerivAt x (companion a *ᵥ x t) t) ↔
      (∀ t, HasDerivAt x (systemRate (fun _ w => -∑ k, a k * w k) t (x t)) t) :=
    forall_congr' fun t => by rw [hrate t]
  rw [hiff, higher_order_equation_iff_first_order_system]
  refine exists_congr fun y => and_congr_right fun _ => and_congr_left fun _ =>
    forall_congr' fun t => ?_
  exact eq_neg_iff_add_eq_zero

/-- The characteristic equation survives: a number `λ` is an eigenvalue of the companion matrix
exactly when it is a root of `λⁿ + aₙ₋₁ λⁿ⁻¹ + … + a₀ = 0`, and then `(1, λ, …, λⁿ⁻¹)` is an eigenvector. -/
theorem companion_eigenvalue_iff_characteristic_root {K : Type*} [Field K] (n : ℕ) (a : Fin n → K)
    (μ : K) :
    ((∃ v : Fin n → K, v ≠ 0 ∧ companion a *ᵥ v = μ • v) ↔
        μ ^ n + ∑ k : Fin n, a k * μ ^ (k : ℕ) = 0) ∧
      (μ ^ n + ∑ k : Fin n, a k * μ ^ (k : ℕ) = 0 →
        companion a *ᵥ (fun k : Fin n => μ ^ (k : ℕ)) = μ • fun k : Fin n => μ ^ (k : ℕ)) := by
  have hsecond : μ ^ n + ∑ k : Fin n, a k * μ ^ (k : ℕ) = 0 →
      companion a *ᵥ (fun k : Fin n => μ ^ (k : ℕ)) = μ • fun k : Fin n => μ ^ (k : ℕ) := by
    intro hp
    funext i
    rw [companion_mulVec_apply]
    simp only [Pi.smul_apply, smul_eq_mul]
    split_ifs with h
    · rw [pow_succ']
    · have h2 : (i : ℕ) + 1 = n := by omega
      rw [← pow_succ', h2]
      linear_combination -hp
  refine ⟨⟨?_, fun hp => ⟨_, ?_, hsecond hp⟩⟩, hsecond⟩
  · rintro ⟨v, hv, hmv⟩
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · exact absurd (funext fun k => k.elim0) hv
    have hrow : ∀ i (h : i + 1 < n), v ⟨i + 1, h⟩ = μ * v ⟨i, by omega⟩ := by
      intro i h
      have := congrFun hmv ⟨i, by omega⟩
      rw [companion_mulVec_apply] at this
      simpa [h] using this
    have hpow : ∀ k (hk : k < n), v ⟨k, hk⟩ = μ ^ k * v ⟨0, hn⟩ := by
      intro k
      induction k with
      | zero => intro hk; simp
      | succ k ih =>
        intro hk
        rw [hrow k hk, ih (by omega)]
        ring
    have hv0 : v ⟨0, hn⟩ ≠ 0 := by
      intro h0
      apply hv
      funext k
      rw [show v k = _ from hpow k k.2, h0, mul_zero]
      rfl
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
    have hlast := congrFun hmv ⟨m, by omega⟩
    rw [companion_mulVec_apply] at hlast
    simp only [lt_self_iff_false, dite_false, Pi.smul_apply, smul_eq_mul] at hlast
    have hpm := hpow m (by omega)
    have hsum : ∑ j, a j * v j = (∑ j : Fin (m + 1), a j * μ ^ (j : ℕ)) * v ⟨0, hn⟩ := by
      rw [Finset.sum_mul]
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [show v j = _ from hpow j j.2]
      ring
    refine (mul_eq_zero.1 ?_).resolve_right hv0
    linear_combination -hlast - hsum - μ * hpm
  · intro h
    have h0 : 0 < n := by
      rcases Nat.eq_zero_or_pos n with rfl | hn
      · simp at hp
      · exact hn
    have := congrFun h ⟨0, h0⟩
    simp at this

/-! The card's worked numbers. -/

-- Dividing 400 y'' + 800 y' + 2000 y = 0 by the mass: damping 2 per s, stiffness 5 per s².
example : (800 : ℕ) / 400 = 2 ∧ (2000 : ℕ) / 400 = 5 := by
  decide

-- The shock absorber's matrix is the companion matrix of y'' + 2y' + 5y = 0.
example : companion (![5, 2] : Fin 2 → ℤ) = !![0, 1; -5, -2] := by
  ext i j
  fin_cases i <;> fin_cases j <;> rfl

-- Rate at release: A times (10, 0) is (0, -50).
example : (!![0, 1; -5, -2] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![10, 0] = ![0, -50] := by
  ext i
  fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two]

-- -1 + 2i is a root of r² + 2r + 5 = 0, and A (1, λ) = λ (1, λ) = (-1 + 2i, -3 - 4i).
example : (-1 + 2 * I) ^ 2 + 2 * (-1 + 2 * I) + 5 = 0 := by
  linear_combination 4 * I_sq

example : (!![0, 1; -5, -2] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, -1 + 2 * I] = ![-1 + 2 * I, -3 - 4 * I] ∧
    (-1 + 2 * I) • (![1, -1 + 2 * I] : Fin 2 → ℂ) = ![-1 + 2 * I, -3 - 4 * I] := by
  constructor
  · ext i
    fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> ring
  · ext i
    fin_cases i
    · simp
    · simp only [Fin.mk_one, Pi.smul_apply, Matrix.cons_val_one, Matrix.cons_val_zero,
        smul_eq_mul]
      linear_combination 4 * I_sq

-- The third-order case y''' + 3y'' + 3y' + y = 0 has the companion matrix on the card.
example : companion (![1, 3, 3] : Fin 3 → ℤ) = !![0, 1, 0; 0, 0, 1; -1, -3, -3] := by
  ext i j
  fin_cases i <;> fin_cases j <;> rfl

#print axioms higher_order_equation_iff_first_order_system
#print axioms linear_equation_iff_companion_system
#print axioms companion_eigenvalue_iff_characteristic_root
