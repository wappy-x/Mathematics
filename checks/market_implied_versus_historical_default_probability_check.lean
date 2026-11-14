-- Two default probabilities: on finitely many states, normalised state prices form a pricing law that is the real-world law reweighted by the pricing weight, it exceeds the real-world chance of an event exactly when that weight covaries positively with the event, and the rating table's five-year default chances are exact.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Algebra.Group.Indicator
import Mathlib.Data.Real.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Finset

/-- The reweighting identity. Take finitely many future states, each with a real-world chance
`p ω > 0` (the chances add to 1) and a state price `π ω > 0`. Let the pricing weight be
`M ω = π ω / p ω` and the pricing law be the normalised state prices `Q ω = π ω / ∑ π`.
Then `Q` is a probability law, `E_P[M]` is the sum of the state prices (the discount factor),
and for every event `A`, `Q(A) = E_P[M 1_A] / E_P[M]`. -/
theorem pricing_probability_is_reweighted_real_world_probability
    {Ω : Type*} [Fintype Ω] (p π : Ω → ℝ)
    (hp : ∀ ω, 0 < p ω) (hp1 : ∑ ω, p ω = 1) (hπ : ∀ ω, 0 < π ω) :
    (∀ ω, 0 < π ω / ∑ ω', π ω') ∧
    (∑ ω, π ω / ∑ ω', π ω' = 1) ∧
    (∑ ω, p ω * (π ω / p ω) = ∑ ω, π ω) ∧
    ∀ A : Finset Ω,
      ∑ ω ∈ A, π ω / ∑ ω', π ω' =
        (∑ ω, p ω * ((π ω / p ω) * (A : Set Ω).indicator (fun _ => (1 : ℝ)) ω)) /
          ∑ ω, p ω * (π ω / p ω) := by
  classical
  have hS : 0 < ∑ ω', π ω' := by
    by_cases hΩ : Nonempty Ω
    · obtain ⟨ω0⟩ := hΩ
      exact Finset.sum_pos (fun ω _ => hπ ω) ⟨ω0, Finset.mem_univ _⟩
    · exfalso
      have : (∑ ω, p ω) = 0 := by
        rw [Finset.univ_eq_empty_iff.mpr (not_nonempty_iff.mp hΩ)]; simp
      linarith
  have hpm : ∀ ω, p ω * (π ω / p ω) = π ω := fun ω => mul_div_cancel₀ _ (hp ω).ne'
  have hE : ∑ ω, p ω * (π ω / p ω) = ∑ ω, π ω := Finset.sum_congr rfl (fun ω _ => hpm ω)
  refine ⟨fun ω => div_pos (hπ ω) hS, ?_, hE, ?_⟩
  · rw [← Finset.sum_div, div_self hS.ne']
  · intro A
    rw [hE, ← Finset.sum_div]
    congr 1
    have : ∀ ω, p ω * ((π ω / p ω) * (A : Set Ω).indicator (fun _ => (1 : ℝ)) ω)
        = if ω ∈ A then π ω else 0 := by
      intro ω
      rw [← mul_assoc, hpm ω, Set.indicator_apply]
      simp
    rw [Finset.sum_congr rfl (fun ω _ => this ω), Finset.sum_ite_mem, Finset.univ_inter]

/-- The covariance form. In the same setting, the pricing chance of an event minus its
real-world chance equals the covariance of the pricing weight with the event's indicator,
`Cov_P(M, 1_A) = E_P[M 1_A] - E_P[M] E_P[1_A]`, divided by `E_P[M]`. So the pricing chance
exceeds the real-world chance precisely when that covariance is positive. -/
theorem pricing_minus_real_world_probability_eq_covariance
    {Ω : Type*} [Fintype Ω] (p π : Ω → ℝ)
    (hp : ∀ ω, 0 < p ω) (hp1 : ∑ ω, p ω = 1) (hπ : ∀ ω, 0 < π ω) (A : Finset Ω) :
    let M : Ω → ℝ := fun ω => π ω / p ω
    let one_A : Ω → ℝ := (A : Set Ω).indicator (fun _ => (1 : ℝ))
    let cov : ℝ := ∑ ω, p ω * (M ω * one_A ω) - (∑ ω, p ω * M ω) * (∑ ω, p ω * one_A ω)
    (∑ ω ∈ A, π ω / ∑ ω', π ω') - ∑ ω ∈ A, p ω = cov / ∑ ω, p ω * M ω ∧
      ((∑ ω ∈ A, p ω) < ∑ ω ∈ A, π ω / ∑ ω', π ω' ↔ 0 < cov) := by
  intro M one_A cov
  classical
  have hS : 0 < ∑ ω', π ω' := by
    by_cases hΩ : Nonempty Ω
    · obtain ⟨ω0⟩ := hΩ
      exact Finset.sum_pos (fun ω _ => hπ ω) ⟨ω0, Finset.mem_univ _⟩
    · exfalso
      have : (∑ ω, p ω) = 0 := by
        rw [Finset.univ_eq_empty_iff.mpr (not_nonempty_iff.mp hΩ)]; simp
      linarith
  have hpm : ∀ ω, p ω * M ω = π ω := fun ω => mul_div_cancel₀ _ (hp ω).ne'
  have hE : ∑ ω, p ω * M ω = ∑ ω, π ω := Finset.sum_congr rfl (fun ω _ => hpm ω)
  have h1 : ∑ ω, p ω * (M ω * one_A ω) = ∑ ω ∈ A, π ω := by
    have : ∀ ω, p ω * (M ω * one_A ω) = if ω ∈ A then π ω else 0 := by
      intro ω
      rw [← mul_assoc, hpm ω]
      simp only [one_A, Set.indicator_apply, Finset.mem_coe]
      split_ifs <;> simp
    rw [Finset.sum_congr rfl (fun ω _ => this ω), Finset.sum_ite_mem, Finset.univ_inter]
  have h2 : ∑ ω, p ω * one_A ω = ∑ ω ∈ A, p ω := by
    have : ∀ ω, p ω * one_A ω = if ω ∈ A then p ω else 0 := by
      intro ω
      simp only [one_A, Set.indicator_apply, Finset.mem_coe]
      split_ifs <;> simp
    rw [Finset.sum_congr rfl (fun ω _ => this ω), Finset.sum_ite_mem, Finset.univ_inter]
  have hcov : cov = ∑ ω ∈ A, π ω - (∑ ω, π ω) * ∑ ω ∈ A, p ω := by
    show ∑ ω, p ω * (M ω * one_A ω) - (∑ ω, p ω * M ω) * (∑ ω, p ω * one_A ω) = _
    rw [h1, h2, hE]
  have key : (∑ ω ∈ A, π ω / ∑ ω', π ω') - ∑ ω ∈ A, p ω = cov / ∑ ω, p ω * M ω := by
    rw [hE, hcov, ← Finset.sum_div]
    field_simp
  refine ⟨key, ?_⟩
  rw [← sub_pos, key, hE]
  exact div_pos_iff_of_pos_right hS

/-- The odds form. With two states at the horizon, default (`A`, real-world chance `pA`,
state price `πA`) and survival (chance `1 - pA`, state price `πN`), the pricing odds of default
equal the ratio of the pricing weights `m_A / m_notA` times the real-world odds of default. -/
theorem pricing_odds_eq_weight_ratio_mul_real_world_odds
    (pA πA πN : ℝ) (hpA0 : 0 < pA) (hpA1 : pA < 1) (hπA : 0 < πA) (hπN : 0 < πN) :
    let mA := πA / pA
    let mN := πN / (1 - pA)
    let qA := πA / (πA + πN)
    qA / (1 - qA) = (mA / mN) * (pA / (1 - pA)) := by
  intro mA mN qA
  have h0 : pA ≠ 0 := hpA0.ne'
  have h3 : πN ≠ 0 := hπN.ne'
  have h4 : πA ≠ 0 := hπA.ne'
  have h1 : (1 - pA) ≠ 0 := by linarith
  have h2 : πA + πN ≠ 0 := by linarith
  have hq : 1 - qA = πN / (πA + πN) := by
    simp only [qA]; field_simp; ring
  rw [hq]
  simp only [mA, mN, qA]
  rw [div_div_div_cancel_right₀ h2, div_div_div_eq, div_mul_div_comm]
  rw [div_eq_div_iff (by positivity) (mul_ne_zero (mul_ne_zero h0 h3) h1)]
  ring

-- The rating table (Solid, Shaky, Default) and its fifth power: the historical five-year
-- default chance from Solid is exactly 0.10805311, and from Shaky exactly 0.3504457.
example :
    ((!![(9 : ℚ) / 10, 9 / 100, 1 / 100; 1 / 10, 8 / 10, 1 / 10; 0, 0, 1] :
        Matrix (Fin 3) (Fin 3) ℚ) ^ 5) 0 2 = 10805311 / 100000000 := by
  norm_num [pow_succ, Matrix.mul_apply, Fin.sum_univ_three]

example :
    ((!![(9 : ℚ) / 10, 9 / 100, 1 / 100; 1 / 10, 8 / 10, 1 / 10; 0, 0, 1] :
        Matrix (Fin 3) (Fin 3) ℚ) ^ 5) 1 2 = 3504457 / 10000000 := by
  norm_num [pow_succ, Matrix.mul_apply, Fin.sum_univ_three]

-- Year-by-year historical default chances from Solid (1.00%, 2.80%, 5.15%, 7.86%), exactly.
example :
    ((!![(9 : ℚ) / 10, 9 / 100, 1 / 100; 1 / 10, 8 / 10, 1 / 10; 0, 0, 1] :
        Matrix (Fin 3) (Fin 3) ℚ) ^ 2) 0 2 = 7 / 250 := by
  norm_num [pow_succ, Matrix.mul_apply, Fin.sum_univ_three]

example :
    ((!![(9 : ℚ) / 10, 9 / 100, 1 / 100; 1 / 10, 8 / 10, 1 / 10; 0, 0, 1] :
        Matrix (Fin 3) (Fin 3) ℚ) ^ 3) 0 2 = 5149 / 100000 := by
  norm_num [pow_succ, Matrix.mul_apply, Fin.sum_univ_three]

example :
    ((!![(9 : ℚ) / 10, 9 / 100, 1 / 100; 1 / 10, 8 / 10, 1 / 10; 0, 0, 1] :
        Matrix (Fin 3) (Fin 3) ℚ) ^ 4) 0 2 = 629 / 8000 := by
  norm_num [pow_succ, Matrix.mul_apply, Fin.sum_univ_three]

#print axioms pricing_probability_is_reweighted_real_world_probability
#print axioms pricing_minus_real_world_probability_eq_covariance
#print axioms pricing_odds_eq_weight_ratio_mul_real_world_odds
