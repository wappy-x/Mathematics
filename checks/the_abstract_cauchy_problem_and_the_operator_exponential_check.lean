-- Evolution as an equation: for a bounded operator A on a Banach space, the exponential series e^(tA) converges with size at most e^(t‖A‖), u(t) = e^(tA) u0 is the one and only solution of u' = A u, u(0) = u0, and for three tanks in a row e^(tA) = e^(-kt)(I + kt S + (kt)^2 S^2 / 2).
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.Normed.Operator.Completeness
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.Analysis.Calculus.Deriv.Mul

open NormedSpace

/-- The abstract Cauchy problem with a bounded operator. Let `X` be a Banach space (a complete
normed space) and `A` a bounded operator on it. Then `u(t) = e^(tA) u0` is a classical solution of
`u' = A u, u(0) = u0`: it starts at `u0`, at every time `t ≥ 0` its rate of change is `A u(t)`, and
that rate is continuous in time. And it is the only one: any map `v` with `v(0) = u0` whose rate of
change at every `t ≥ 0` (one-sided at `t = 0`) is `A v(t)` equals `e^(tA) u0` at every `t ≥ 0`. -/
theorem bounded_operator_exponential_solves_cauchy_problem_uniquely
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (A : X →L[ℝ] X) (u0 : X) :
    (exp ((0 : ℝ) • A) u0 = u0 ∧
      (∀ t : ℝ, 0 ≤ t → HasDerivAt (fun s : ℝ => exp (s • A) u0) (A (exp (t • A) u0)) t) ∧
      Continuous (fun t : ℝ => A (exp (t • A) u0))) ∧
    ∀ v : ℝ → X, v 0 = u0 →
      (∀ t : ℝ, 0 ≤ t → HasDerivWithinAt v (A (v t)) (Set.Ici 0) t) →
      ∀ t : ℝ, 0 ≤ t → v t = exp (t • A) u0 := by
  have hd : ∀ t : ℝ, HasDerivAt (fun s : ℝ => exp (s • A) u0) (A (exp (t • A) u0)) t := by
    intro t
    have h2 := (hasDerivAt_exp_smul_const' (𝕂 := ℝ) A t).clm_apply (hasDerivAt_const t u0)
    simpa using h2
  have hc : Continuous (fun s : ℝ => exp (s • A) u0) :=
    continuous_iff_continuousAt.2 fun t => (hd t).continuousAt
  refine ⟨⟨by simp, fun t _ => hd t, A.continuous.comp hc⟩, ?_⟩
  intro v hv0 hv t ht
  have key := eq_zero_of_abs_deriv_le_mul_abs_self_of_eq_zero_right
    (f := fun s => v s - exp (s • A) u0)
    (f' := fun s => A (v s) - A (exp (s • A) u0)) (K := ‖A‖) (a := 0) (b := t)
    (fun x hx => ((hv x hx.1).continuousWithinAt.mono Set.Icc_subset_Ici_self).sub
      hc.continuousWithinAt)
    (fun x hx => ((hv x hx.1).mono (Set.Ici_subset_Ici.2 hx.1)).sub (hd x).hasDerivWithinAt)
    (by simp [hv0])
    (fun x _ => by rw [← map_sub]; exact A.le_opNorm _)
    t ⟨ht, le_rfl⟩
  exact sub_eq_zero.1 key

/-- The series converges, with a size bound. For a bounded operator `A` on a Banach space and any
time `t ≥ 0`, the series `∑ t^m A^m / m!` converges in operator size to `e^(tA)`, and the gain of
`e^(tA)` is at most `e` to the `t` times the gain of `A`. -/
theorem operator_exponential_series_converges_and_norm_le
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (A : X →L[ℝ] X) (t : ℝ) (ht : 0 ≤ t) :
    HasSum (fun m : ℕ => (t ^ m / (m.factorial : ℝ)) • A ^ m) (exp (t • A)) ∧
      ‖exp (t • A)‖ ≤ Real.exp (t * ‖A‖) := by
  have h := NormedSpace.exp_series_hasSum_exp' (𝕂 := ℝ) (t • A)
  have hs : HasSum (fun m : ℕ => (t ^ m / (m.factorial : ℝ)) • A ^ m) (exp (t • A)) := by
    convert h using 1
    funext m
    rw [smul_pow, smul_smul, div_eq_inv_mul]
  refine ⟨hs, ?_⟩
  have hr := NormedSpace.exp_series_hasSum_exp' (𝕂 := ℝ) (t * ‖A‖)
  rw [← Real.exp_eq_exp_ℝ] at hr
  rw [← hs.tsum_eq]
  refine tsum_of_norm_bounded hr fun m => ?_
  have hA : ‖A ^ m‖ ≤ ‖A‖ ^ m := by
    rcases Nat.eq_zero_or_pos m with rfl | hm
    · rw [pow_zero, pow_zero]; exact ContinuousLinearMap.norm_id_le
    · exact norm_pow_le' A hm
  rw [norm_smul, Real.norm_of_nonneg (by positivity), smul_eq_mul, mul_pow, div_eq_inv_mul,
    mul_assoc]
  gcongr

/-- Three tanks in a row, solved exactly. With the shift `S` moving each tank's salt to the next
tank and flushing rate `k`, the operator is `A = k(S - I)`, and its exponential is
`e^(tA) = e^(-kt) (I + kt S + (kt)^2 S^2 / 2)`, because `S^3 = 0`. -/
theorem three_tank_exponential_closed_form (k t : ℝ) :
    let S : Matrix (Fin 3) (Fin 3) ℝ := !![0, 0, 0; 1, 0, 0; 0, 1, 0]
    exp (t • (k • (S - 1))) =
      Real.exp (-(k * t)) • (1 + (k * t) • S + ((k * t) ^ 2 / 2) • S ^ 2) := by
  intro S
  set c : ℝ := k * t with hc
  have hS3 : S ^ 3 = 0 := by
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [S, pow_succ, Matrix.mul_apply, Fin.sum_univ_three]
  have hsplit : t • (k • (S - 1)) = c • S + (-c) • (1 : Matrix (Fin 3) (Fin 3) ℝ) := by
    rw [hc, smul_sub, smul_sub, smul_smul, smul_smul, neg_smul, sub_eq_add_neg, mul_comm]
  have hcomm : Commute (c • S) ((-c) • (1 : Matrix (Fin 3) (Fin 3) ℝ)) :=
    ((Commute.one_right S).smul_right _).smul_left _
  have hnil : exp (c • S) = 1 + c • S + (c ^ 2 / 2) • S ^ 2 := by
    rw [congrFun (NormedSpace.exp_eq_tsum ℝ) (c • S)]
    rw [tsum_eq_sum (s := Finset.range 3)]
    · simp [Finset.sum_range_succ, smul_pow, smul_smul, Nat.factorial]
      rw [div_eq_inv_mul]
    · intro n hn
      simp only [Finset.mem_range, not_lt] at hn
      obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn
      rw [smul_pow, pow_add S, hS3, zero_mul, smul_zero, smul_zero]
  have hdiag : exp ((-c) • (1 : Matrix (Fin 3) (Fin 3) ℝ)) = Real.exp (-c) • 1 := by
    have h1 : (-c) • (1 : Matrix (Fin 3) (Fin 3) ℝ) = Matrix.diagonal (fun _ => -c) := by
      rw [Matrix.smul_one_eq_diagonal]
    rw [h1, Matrix.exp_diagonal, Matrix.smul_one_eq_diagonal]
    congr 1
    funext i
    rw [Pi.exp_def, Real.exp_eq_exp_ℝ]
  rw [hsplit, Matrix.exp_add_of_commute _ _ hcomm, hnil, hdiag, mul_smul_comm, mul_one]

-- The shift on three tanks dies after three moves: S^3 = 0.
example : (!![0, 0, 0; 1, 0, 0; 0, 1, 0] : Matrix (Fin 3) (Fin 3) ℤ) ^ 3 = 0 := by decide

-- The tanks' matrix: A = k(S - I) with k = 10 L/min over 100 L = 1/10 per minute.
example : (10 : ℚ) / 100 = 1 / 10 := by norm_num
example : ((1 / 10 : ℚ) • ((!![0, 0, 0; 1, 0, 0; 0, 1, 0] : Matrix (Fin 3) (Fin 3) ℚ) - 1)) =
    !![-1 / 10, 0, 0; 1 / 10, -1 / 10, 0; 0, 1 / 10, -1 / 10] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num

-- Moves expected by 15 minutes, kt = 3/2, and the Poisson weights 1, kt, (kt)^2/2 = 1, 3/2, 9/8.
example : (1 / 10 : ℚ) * 15 = 3 / 2 := by norm_num
example : ((3 / 2 : ℚ)) ^ 2 / 2 = 9 / 8 := by norm_num

-- Gain of A_N in total salt: 2k with k = N/30, so N/15; 1/5 per minute for 3 tanks, 200 for 3000.
example : 2 * ((3 : ℚ) / 30) = 1 / 5 := by norm_num
example : 2 * ((3000 : ℚ) / 30) = 200 := by norm_num

#print axioms bounded_operator_exponential_solves_cauchy_problem_uniquely
#print axioms operator_exponential_series_converges_and_norm_le
#print axioms three_tank_exponential_closed_form
