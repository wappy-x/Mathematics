-- Multilevel Monte Carlo: the multilevel estimate, a coarse-grid average plus a telescoping ladder of paired corrections, has exactly the finest grid's average, and the path counts N_l proportional to √(V_l / C_l) meet the noise budget ε²/2 at the Cauchy–Schwarz floor on work.
import Mathlib.Probability.IdentDistrib
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open MeasureTheory ProbabilityTheory Finset

/-- The telescoping sum keeps the fine-grid answer (Step 1 of the card).
`P l` is the discounted payoff of one path walked on level `l`'s grid (`2^l` steps), for
`l = 0, …, L`. On level `l` the run draws `N l ≥ 1` correction samples; sample `i` records a
fine payoff `fine l i` and a coarse payoff `coarse l i`, and on level 0 there is no coarse
path (`coarse 0 i = 0`). Each fine payoff has level `l`'s law, and, because the coarse path
uses the same kicks added in pairs, each coarse payoff on level `l + 1` has exactly level `l`'s
law. Then the multilevel estimate
`P̂ = ∑_{l=0}^{L} (1/N_l) ∑_{i} (fine l i − coarse l i)` has average `E[P_L]`: the finest
grid's price, with no extra bias. (The payoffs are integrable, so every average exists.) -/
theorem multilevel_estimate_mean_eq_finest_grid_price
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]
    (L : ℕ) (P : ℕ → Ω → ℝ) (hP : ∀ l, Integrable (P l) μ)
    (N : ℕ → ℕ) (hN : ∀ l, 0 < N l)
    (fine coarse : ℕ → ℕ → Ω → ℝ)
    (hfine : ∀ l i, IdentDistrib (fine l i) (P l) μ μ)
    (hcoarse0 : ∀ i, coarse 0 i = 0)
    (hcoarse : ∀ l i, IdentDistrib (coarse (l + 1) i) (P l) μ μ) :
    ∫ ω, (∑ l ∈ range (L + 1),
        (1 / (N l : ℝ)) * ∑ i ∈ range (N l), (fine l i ω - coarse l i ω)) ∂μ
      = ∫ ω, P L ω ∂μ := by
  have hfi : ∀ l i, Integrable (fine l i) μ := fun l i => (hfine l i).integrable_iff.mpr (hP l)
  have hci : ∀ l i, Integrable (coarse l i) μ := by
    intro l i
    cases l with
    | zero => rw [hcoarse0]; exact integrable_zero _ _ _
    | succ l => exact (hcoarse l i).integrable_iff.mpr (hP l)
  have hterm : ∀ l, ∫ ω, (1 / (N l : ℝ)) * ∑ i ∈ range (N l), (fine l i ω - coarse l i ω) ∂μ
      = ∫ ω, P l ω ∂μ - (if l = 0 then 0 else ∫ ω, P (l - 1) ω ∂μ) := by
    intro l
    have hNl : (N l : ℝ) ≠ 0 := by exact_mod_cast (hN l).ne'
    have hc : ∀ i, ∫ ω, coarse l i ω ∂μ = (if l = 0 then 0 else ∫ ω, P (l - 1) ω ∂μ) := by
      intro i
      cases l with
      | zero => simp [hcoarse0]
      | succ l => simpa using (hcoarse l i).integral_eq
    rw [integral_const_mul, integral_finsetSum (f := fun i ω => fine l i ω - coarse l i ω) _ (fun i _ => (hfi l i).sub (hci l i))]
    simp_rw [integral_sub (hfi l _) (hci l _), (hfine l _).integral_eq, hc]
    rw [sum_const, card_range, nsmul_eq_mul]
    field_simp
  rw [integral_finsetSum (f := fun l ω => (1 / (N l : ℝ)) * ∑ i ∈ range (N l), (fine l i ω - coarse l i ω)) _ (fun l _ => (integrable_finsetSum _
    (fun i _ => (hfi l i).sub (hci l i))).const_mul _)]
  simp_rw [hterm]
  induction L with
  | zero => simp
  | succ L ih => rw [sum_range_succ, ih]; simp

/-- The floor no plan can beat (Step 3, by Cauchy–Schwarz). For levels `l = 0, …, L` with
correction variances `V_l ≥ 0`, work per sample `C_l ≥ 0` and path counts `N_l ≥ 1`, the total
work `∑ N_l C_l` times the estimate's variance `∑ V_l / N_l` is at least `(∑ √(V_l C_l))²`. -/
theorem plan_work_times_variance_ge_floor
    (L : ℕ) (V C : ℕ → ℝ) (hV : ∀ l, 0 ≤ V l) (hC : ∀ l, 0 ≤ C l)
    (N : ℕ → ℕ) (hN : ∀ l, 0 < N l) :
    (∑ l ∈ range (L + 1), √(V l * C l)) ^ 2
      ≤ (∑ l ∈ range (L + 1), (N l : ℝ) * C l) * (∑ l ∈ range (L + 1), V l / (N l : ℝ)) := by
  apply sum_sq_le_sum_mul_sum_of_sq_le_mul
  · intro l _; exact mul_nonneg (Nat.cast_nonneg _) (hC l)
  · intro l _; exact div_nonneg (hV l) (Nat.cast_nonneg _)
  · intro l _
    have hNl : (N l : ℝ) ≠ 0 := by exact_mod_cast (hN l).ne'
    rw [Real.sq_sqrt (mul_nonneg (hV l) (hC l))]
    apply le_of_eq
    field_simp

/-- The best path counts (Step 3, the plan that reaches the floor). With variances `V_l > 0`,
costs `C_l > 0` and a target root-mean-square error `ε > 0`, set
`λ = (2/ε²) ∑ √(V_k C_k)` and `N_l = λ √(V_l / C_l)`. Then the sampling noise `∑ V_l / N_l`
is exactly the budget `ε²/2`, and the work `∑ N_l C_l` is `(2/ε²) (∑ √(V_k C_k))²`, the floor. -/
theorem optimal_plan_meets_budget_at_floor
    (L : ℕ) (V C : ℕ → ℝ) (hV : ∀ l, 0 < V l) (hC : ∀ l, 0 < C l) (ε : ℝ) (hε : 0 < ε) :
    let lam := 2 / ε ^ 2 * ∑ k ∈ range (L + 1), √(V k * C k)
    let N : ℕ → ℝ := fun l => lam * √(V l / C l)
    (∑ l ∈ range (L + 1), V l / N l = ε ^ 2 / 2) ∧
      (∑ l ∈ range (L + 1), N l * C l = 2 / ε ^ 2 * (∑ k ∈ range (L + 1), √(V k * C k)) ^ 2) := by
  intro lam N
  have hS : 0 < ∑ k ∈ range (L + 1), √(V k * C k) :=
    sum_pos (fun k _ => Real.sqrt_pos.mpr (mul_pos (hV k) (hC k))) nonempty_range_add_one
  have hlam : 0 < lam := mul_pos (by positivity) hS
  have h1 : ∀ l, V l / N l = √(V l * C l) / lam := by
    intro l
    have hv := Real.sqrt_pos.mpr (hV l)
    have hc := Real.sqrt_pos.mpr (hC l)
    simp only [N]
    rw [Real.sqrt_div' _ (hC l).le, Real.sqrt_mul (hV l).le]
    have : √(V l) ^ 2 = V l := Real.sq_sqrt (hV l).le
    field_simp
    exact this.symm
  have h2 : ∀ l, N l * C l = lam * √(V l * C l) := by
    intro l
    have hv := Real.sqrt_pos.mpr (hV l)
    have hc := Real.sqrt_pos.mpr (hC l)
    simp only [N]
    rw [Real.sqrt_div' _ (hC l).le, Real.sqrt_mul (hV l).le]
    have : C l = √(C l) ^ 2 := (Real.sq_sqrt (hC l).le).symm
    nth_rewrite 2 [this]
    field_simp
  constructor
  · simp_rw [h1, ← sum_div]
    simp only [lam]
    field_simp
  · simp_rw [h2, ← mul_sum]
    simp only [lam]
    ring

/-! The card's whole-number worked examples. -/

-- work per correction sample, C_l = 2^l + 2^(l-1) (and 1 on level 0): 1, 3, 6, 12, 24, 48, 96
example : (List.range 7).map (fun l => if l = 0 then 1 else 2 ^ l + 2 ^ (l - 1))
    = [1, 3, 6, 12, 24, 48, 96] := by decide

-- step-evaluations on each level of the one-cent run, N_l × C_l
example : 6735774 * 1 = 6735774 ∧ 469658 * 3 = 1408974 ∧ 246589 * 6 = 1479534 ∧
    124966 * 12 = 1499592 ∧ 65483 * 24 = 1571592 ∧ 33163 * 48 = 1591824 ∧
    16943 * 96 = 1626528 := by norm_num

-- total multilevel work: ∑ N_l C_l = 15,913,818 step-evaluations
example : 6735774 * 1 + 469658 * 3 + 246589 * 6 + 124966 * 12 + 65483 * 24 + 33163 * 48 +
    16943 * 96 = 15913818 := by norm_num

-- plain Monte Carlo at h = 1/64: 3,865,716 paths times 64 steps
example : 3865716 * 64 = 247405824 := by norm_num

-- plain over multilevel lies between 15 and 16 (the card's 15.5 times)
example : 15 * 15913818 < 247405824 ∧ 247405824 < 16 * 15913818 := by norm_num

-- the same path count on every level: 2,938,845 paths times 1 + 3 + 6 + 12 + 24 + 48 + 96 = 190
example : 2938845 * (1 + 3 + 6 + 12 + 24 + 48 + 96) = 558380550 := by norm_num

-- on 4 steps, plain Monte Carlo: 3,576,303 paths times 4 steps
example : 3576303 * 4 = 14305212 := by norm_num

#print axioms multilevel_estimate_mean_eq_finest_grid_price
#print axioms plan_work_times_variance_ge_floor
#print axioms optimal_plan_meets_budget_at_floor
