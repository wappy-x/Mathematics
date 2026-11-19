-- Baker-Campbell-Hausdorff: e^X e^Y equals e^(X + Y + [X, Y]/2) up to third-order terms, the log series converges when the norms add to less than ln 2, and the second- and third-order terms are half a bracket and a twelfth of two nested brackets.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.CStarAlgebra.Matrix
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Algebra.Lie.OfAssociative
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Tactic.Module
import Mathlib.Tactic.NoncommRing

open NormedSpace Filter Asymptotics Topology Matrix
open scoped Matrix.Norms.L2Operator

variable {n : Type*} [Fintype n] [DecidableEq n]

/-- Helper: `‖e^X - 1‖ ≤ e^‖X‖ - 1`, comparing the two exponential series term by term. -/
theorem bch_norm_exp_sub_one_le (X : Matrix n n ℝ) :
    ‖exp X - 1‖ ≤ Real.exp ‖X‖ - 1 := by
  have h1 : HasSum (fun k : ℕ => ((k + 1).factorial⁻¹ : ℝ) • X ^ (k + 1)) (exp X - 1) := by
    have := exp_series_hasSum_exp' (𝕂 := ℝ) X
    rw [← hasSum_nat_add_iff' 1] at this
    simpa using this
  have h2 : HasSum (fun k : ℕ => ((k + 1).factorial⁻¹ : ℝ) • ‖X‖ ^ (k + 1))
      (Real.exp ‖X‖ - 1) := by
    have := exp_series_hasSum_exp' (𝕂 := ℝ) ‖X‖
    rw [← hasSum_nat_add_iff' 1] at this
    simpa [Real.exp_eq_exp_ℝ] using this
  refine h1.norm_le_of_bounded h2 fun k => ?_
  rw [norm_smul, smul_eq_mul, Real.norm_of_nonneg (by positivity)]
  gcongr
  exact norm_pow_le' X (Nat.succ_pos k)

/-- Helper: Taylor's formula for the matrix exponential to second order,
`e^Z = 1 + Z + Z²/2 + O(‖Z‖³)` near `Z = 0`. -/
theorem bch_exp_sub_taylor_two_isBigO :
    (fun Z : Matrix n n ℝ => exp Z - (1 + Z + (1 / 2 : ℝ) • Z ^ 2))
      =O[𝓝 0] (fun Z => ‖Z‖ ^ 3) := by
  have := (exp_hasFPowerSeriesAt_zero (𝕂 := ℝ) (𝔸 := Matrix n n ℝ)).isBigO_sub_partialSum_pow 3
  refine this.congr_left fun Z => ?_
  simp [FormalMultilinearSeries.partialSum, Finset.sum_range_succ, expSeries_apply_eq]

/-- Helper: the same Taylor bound along a path `Z t` that is `O(t)`. -/
theorem bch_exp_comp_sub_taylor_two_isBigO (Z : ℝ → Matrix n n ℝ)
    (hZ : Z =O[𝓝 0] (fun t : ℝ => t)) :
    (fun t => exp (Z t) - (1 + Z t + (1 / 2 : ℝ) • Z t ^ 2)) =O[𝓝 0] (fun t : ℝ => t ^ 3) := by
  have hT : Tendsto Z (𝓝 0) (𝓝 0) := hZ.trans_tendsto (tendsto_id : Tendsto (fun t : ℝ => t) _ _)
  refine ((bch_exp_sub_taylor_two_isBigO (n := n)).comp_tendsto hT).trans ?_
  simpa [Function.comp_def] using hZ.norm_left.pow 3

/-- Helper: a scalar that is `O(t^k)` times a matrix path with a limit is `O(t^k)`. -/
theorem bch_smul_isBigO_of_tendsto (c : ℝ → ℝ) (V : ℝ → Matrix n n ℝ) (k : ℕ)
    (hc : c =O[𝓝 0] (fun t : ℝ => t ^ k)) (hV : Tendsto V (𝓝 0) (𝓝 (V 0))) :
    (fun t => c t • V t) =O[𝓝 0] (fun t : ℝ => t ^ k) := by
  simpa using hc.smul (hV.isBigO_one ℝ)

#print axioms bch_norm_exp_sub_one_le
#print axioms bch_exp_sub_taylor_two_isBigO
#print axioms bch_exp_comp_sub_taylor_two_isBigO
#print axioms bch_smul_isBigO_of_tendsto

/-- Two turns in a row equal one turn by their sum plus half their bracket, up to
terms with three or more factors: for square matrices `X`, `Y` scaled by a small
factor `t`, `e^(tX) e^(tY)` and `e^(t(X + Y) + (t²/2)[X, Y])` differ by at most a
constant times `t³` near `t = 0`. This is a local statement about small turns. -/
theorem exp_mul_exp_eq_exp_add_half_bracket_up_to_third_order (X Y : Matrix n n ℝ) :
    (fun t : ℝ => exp (t • X) * exp (t • Y)
        - exp (t • (X + Y) + (t ^ 2 / 2) • ⁅X, Y⁆))
      =O[𝓝 0] (fun t : ℝ => t ^ 3) := by
  set E : Matrix n n ℝ → Matrix n n ℝ := fun Z => 1 + Z + (1 / 2 : ℝ) • Z ^ 2 with hE
  set W : ℝ → Matrix n n ℝ := fun t => t • (X + Y) + (t ^ 2 / 2) • ⁅X, Y⁆ with hW
  have hid : ∀ t : ℝ, exp (t • X) * exp (t • Y) - exp (W t)
      = (E (t • X) * E (t • Y) - E (W t)) + (exp (t • X) - E (t • X)) * exp (t • Y)
        + E (t • X) * (exp (t • Y) - E (t • Y)) - (exp (W t) - E (W t)) := by
    intro t; noncomm_ring
  set C3 : Matrix n n ℝ := (1 / 2 : ℝ) • (X * Y ^ 2) + (1 / 2 : ℝ) • (X ^ 2 * Y)
      - (1 / 4 : ℝ) • ((X + Y) * ⁅X, Y⁆ + ⁅X, Y⁆ * (X + Y)) with hC3
  set C4 : Matrix n n ℝ := (1 / 4 : ℝ) • (X ^ 2 * Y ^ 2) - (1 / 8 : ℝ) • (⁅X, Y⁆ ^ 2) with hC4
  have hpoly : ∀ t : ℝ, E (t • X) * E (t • Y) - E (W t) = t ^ 3 • (C3 + t • C4) := by
    intro t
    simp only [hE, hW, hC3, hC4, Ring.lie_def, pow_succ, pow_zero, one_mul, mul_one, mul_add,
      add_mul, sub_mul, mul_sub, smul_mul_assoc, mul_smul_comm, smul_add, smul_sub, smul_smul,
      mul_assoc]
    module
  -- O(t) bounds for the arguments
  have hO1 : ∀ V : Matrix n n ℝ, (fun t : ℝ => t • V) =O[𝓝 0] (fun t : ℝ => t) := by
    intro V
    simpa using bch_smul_isBigO_of_tendsto (fun t => t) (fun _ => V) 1 (by simpa using isBigO_refl _ _)
      tendsto_const_nhds
  have hWO : W =O[𝓝 0] (fun t : ℝ => t) := by
    have h2 : (fun t : ℝ => (t ^ 2 / 2) • ⁅X, Y⁆) =O[𝓝 0] (fun t : ℝ => t) := by
      have : (fun t : ℝ => t ^ 2 / 2) =O[𝓝 0] (fun t : ℝ => t ^ 1) := by
        have h := (isBigO_refl (fun t : ℝ => t ^ 1) (𝓝 0)).mul
          (((continuous_id.div_const (2 : ℝ)).tendsto 0).isBigO_one ℝ)
        exact h.congr (fun t => by simp; ring) (fun t => by simp)
      simpa using bch_smul_isBigO_of_tendsto _ (fun _ => ⁅X, Y⁆) 1 this tendsto_const_nhds
    exact (hO1 (X + Y)).add h2
  have hcont : ∀ V : Matrix n n ℝ, Tendsto (fun t : ℝ => exp (t • V)) (𝓝 0) (𝓝 1) := by
    intro V
    have h0 : Tendsto (fun t : ℝ => t • V) (𝓝 0) (𝓝 0) :=
      (hO1 V).trans_tendsto (tendsto_id : Tendsto (fun t : ℝ => t) _ _)
    have h1 := ((exp_analytic (𝕂 := ℝ) (0 : Matrix n n ℝ)).continuousAt.tendsto).comp h0
    simpa [Function.comp_def] using h1
  have hEcont : ∀ V : Matrix n n ℝ, Tendsto (fun t : ℝ => E (t • V)) (𝓝 0) (𝓝 1) := by
    intro V
    have hc : Continuous (fun t : ℝ => E (t • V)) := by
      simp only [hE]; fun_prop
    simpa [hE] using hc.tendsto 0
  have hRX := bch_exp_comp_sub_taylor_two_isBigO _ (hO1 X)
  have hRY := bch_exp_comp_sub_taylor_two_isBigO _ (hO1 Y)
  have hRW := bch_exp_comp_sub_taylor_two_isBigO _ hWO
  have hP : (fun t : ℝ => t ^ 3 • (C3 + t • C4)) =O[𝓝 0] (fun t : ℝ => t ^ 3) :=
    bch_smul_isBigO_of_tendsto _ (fun t => C3 + t • C4) 3 (isBigO_refl _ _)
      ((by fun_prop : Continuous fun t : ℝ => C3 + t • C4).tendsto 0)
  have h1 : (fun t : ℝ => (exp (t • X) - E (t • X)) * exp (t • Y)) =O[𝓝 0]
      (fun t : ℝ => t ^ 3) := by
    exact (hRX.mul ((hcont Y).isBigO_one ℝ)).congr_right (fun t => by simp)
  have h2 : (fun t : ℝ => E (t • X) * (exp (t • Y) - E (t • Y))) =O[𝓝 0]
      (fun t : ℝ => t ^ 3) := by
    exact (((hEcont X).isBigO_one ℝ).mul hRY).congr_right (fun t => by simp)
  have key := ((hP.add h1).add h2).sub hRW
  refine key.congr_left fun t => ?_
  show _ = exp (t • X) * exp (t • Y) - exp (W t)
  rw [hid t, hpoly t]

/-- When the operator norms of `X` and `Y` add to less than `ln 2`, the matrix
`M = e^X e^Y - I` has norm below 1, so the log series `M - M²/2 + M³/3 - ⋯`
converges. -/
theorem log_series_converges_of_norm_add_lt_log_two (X Y : Matrix n n ℝ)
    (h : ‖X‖ + ‖Y‖ < Real.log 2) :
    ‖exp X * exp Y - 1‖ < 1 ∧
      Summable (fun k : ℕ =>
        ((-1 : ℝ) ^ k / (k + 1)) • (exp X * exp Y - 1) ^ (k + 1)) := by
  have hM : ‖exp X * exp Y - 1‖ < 1 := by
    have hid : exp X * exp Y - 1
        = (exp X - 1) * (exp Y - 1) + (exp X - 1) + (exp Y - 1) := by noncomm_ring
    have ha := bch_norm_exp_sub_one_le X
    have hb := bch_norm_exp_sub_one_le Y
    have ha0 : 0 ≤ Real.exp ‖X‖ - 1 := by
      have := Real.add_one_le_exp ‖X‖; linarith [norm_nonneg X]
    have hb0 : 0 ≤ Real.exp ‖Y‖ - 1 := by
      have := Real.add_one_le_exp ‖Y‖; linarith [norm_nonneg Y]
    have hexp : Real.exp (‖X‖ + ‖Y‖) < 2 := by
      calc Real.exp (‖X‖ + ‖Y‖) < Real.exp (Real.log 2) := Real.exp_lt_exp.mpr h
        _ = 2 := Real.exp_log (by norm_num)
    rw [Real.exp_add] at hexp
    calc ‖exp X * exp Y - 1‖
        ≤ ‖exp X - 1‖ * ‖exp Y - 1‖ + ‖exp X - 1‖ + ‖exp Y - 1‖ := by
          rw [hid]
          refine (norm_add_le _ _).trans ?_
          gcongr
          refine (norm_add_le _ _).trans ?_
          gcongr
          exact norm_mul_le _ _
      _ ≤ (Real.exp ‖X‖ - 1) * (Real.exp ‖Y‖ - 1) + (Real.exp ‖X‖ - 1)
            + (Real.exp ‖Y‖ - 1) := by
          gcongr
      _ < 1 := by nlinarith
  refine ⟨hM, ?_⟩
  refine Summable.of_norm_bounded
    (g := fun k : ℕ => ‖exp X * exp Y - 1‖ ^ (k + 1)) ?_ fun k => ?_
  · exact (summable_geometric_of_lt_one (norm_nonneg _) hM).mul_left _ |>.congr
      fun k => by ring
  · rw [norm_smul]
    calc ‖(-1 : ℝ) ^ k / (k + 1)‖ * ‖(exp X * exp Y - 1) ^ (k + 1)‖
        ≤ 1 * ‖exp X * exp Y - 1‖ ^ (k + 1) := by
          gcongr
          · rw [norm_div, norm_pow, norm_neg, norm_one, one_pow]
            rw [Real.norm_of_nonneg (by positivity)]
            rw [div_le_one (by positivity)]
            linarith [(k.cast_nonneg : (0:ℝ) ≤ k)]
          · exact norm_pow_le' _ (Nat.succ_pos k)
      _ = _ := one_mul _

/-- Collecting the log series of `e^X e^Y` by number of factors: with
`M₁ = X + Y`, `M₂ = X²/2 + XY + Y²/2`, `M₃ = X³/6 + X²Y/2 + XY²/2 + Y³/6`,
the two-factor part `M₂ - M₁²/2` is half the bracket `[X, Y]`, and the
three-factor part `M₃ - (M₁M₂ + M₂M₁)/2 + M₁³/3` is one twelfth of
`[X, [X, Y]] + [Y, [Y, X]]`. -/
theorem log_exp_mul_exp_second_and_third_order_terms (X Y : Matrix n n ℝ) :
    ((1 / 2 : ℝ) • X ^ 2 + X * Y + (1 / 2 : ℝ) • Y ^ 2)
        - (1 / 2 : ℝ) • (X + Y) ^ 2 = (1 / 2 : ℝ) • ⁅X, Y⁆ ∧
    ((1 / 6 : ℝ) • X ^ 3 + (1 / 2 : ℝ) • (X ^ 2 * Y) + (1 / 2 : ℝ) • (X * Y ^ 2)
        + (1 / 6 : ℝ) • Y ^ 3)
      - (1 / 2 : ℝ) • ((X + Y) * ((1 / 2 : ℝ) • X ^ 2 + X * Y + (1 / 2 : ℝ) • Y ^ 2)
          + ((1 / 2 : ℝ) • X ^ 2 + X * Y + (1 / 2 : ℝ) • Y ^ 2) * (X + Y))
      + (1 / 3 : ℝ) • (X + Y) ^ 3
      = (1 / 12 : ℝ) • (⁅X, ⁅X, Y⁆⁆ + ⁅Y, ⁅Y, X⁆⁆) := by
  constructor <;>
  · simp only [Ring.lie_def, pow_succ, pow_zero, one_mul, mul_add, add_mul, sub_mul, mul_sub,
      smul_mul_assoc, mul_smul_comm, smul_add, smul_sub, smul_smul, mul_assoc]
    module

-- The card's word coefficients in the three-factor part of the log.
-- XXY (and XYY, YYX by mirror): 1/2 - 1/2 (1 + 1/2) + 1/3 = 1/12
example : (1 / 2 : ℚ) - 1 / 2 * (1 + 1 / 2) + 1 / 3 = 1 / 12 := by norm_num
-- XYX (and YXY): 0 - 1/2 (0 + 1) + 1/3 = -1/6
example : (0 : ℚ) - 1 / 2 * (0 + 1) + 1 / 3 = -1 / 6 := by norm_num
-- YXX: 0 - 1/2 (1/2 + 0) + 1/3 = 1/12
example : (0 : ℚ) - 1 / 2 * (1 / 2 + 0) + 1 / 3 = 1 / 12 := by norm_num
-- XXX (and YYY): 1/6 - 1/2 (1/2 + 1/2) + 1/3 = 0
example : (1 / 6 : ℚ) - 1 / 2 * (1 / 2 + 1 / 2) + 1 / 3 = 0 := by norm_num
-- [X, [X, Y]] = X²Y - 2XYX + YX², divided by 12, gives XYX the coefficient -1/6.
example : (1 / 12 : ℚ) * (-2) = -1 / 6 := by norm_num

-- The gimbal: pan u = (0, 0, a), tilt v = (0, -b, 0) give the pure roll u × v = (ab, 0, 0).
example (a b : ℝ) : crossProduct ![0, 0, a] ![0, -b, 0] = ![a * b, 0, 0] := by
  norm_num [cross_apply]
-- Two pans about the same axis leave no bracket.
example (a b : ℝ) : crossProduct ![0, 0, a] ![0, 0, b] = ![0, 0, 0] := by
  norm_num [cross_apply]

#print axioms exp_mul_exp_eq_exp_add_half_bracket_up_to_third_order
#print axioms log_series_converges_of_norm_add_lt_log_two
#print axioms log_exp_mul_exp_second_and_third_order_terms
