-- Negative convexity: a mortgage pool is worth its face plus the coupon's excess over the market rate on every discounted balance, for any prepayment path, and at par its exact slope and bend come from those discounted balances alone.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Finset

/-- Telescoping form of the par identity before using the end condition. -/
theorem pool_price_telescope_aux (i j : ℝ) (B : ℕ → ℝ) (hj : 1 + j ≠ 0) (N : ℕ) :
    ∑ m ∈ Icc 1 N, ((1 + i) * B m - B (m + 1)) / (1 + j) ^ m
      = B 1 + (i - j) * ∑ m ∈ Icc 1 N, B m / (1 + j) ^ m - B (N + 1) / (1 + j) ^ N := by
  induction N with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), Finset.sum_Icc_succ_top (by omega), ih]
    have hp : (1 + j) ^ n ≠ 0 := pow_ne_zero _ hj
    rw [pow_succ]
    field_simp
    ring

#print axioms pool_price_telescope_aux

/-- The par identity (Step 2). Take a pool of `N` months whose opening balance in month `m` is
`B m`, with face `B 1 = L` and nothing left after the last month (`B (N+1) = 0`). Each month's
receipt is the opening balance grown by the monthly coupon `i`, minus the closing balance:
`(1+i) B m - B (m+1)`. Discount every receipt at the monthly market rate `j` and add. The result is
the face plus `(i - j)` times `F`, the sum of all discounted opening balances. No prepayment rule
is assumed: the balances can follow any path. -/
theorem pool_price_eq_face_add_coupon_excess_times_discounted_balances
    (N : ℕ) (i j L : ℝ) (B : ℕ → ℝ) (hj : 1 + j ≠ 0)
    (hL : B 1 = L) (hend : B (N + 1) = 0) :
    ∑ m ∈ Icc 1 N, ((1 + i) * B m - B (m + 1)) / (1 + j) ^ m
      = L + (i - j) * ∑ m ∈ Icc 1 N, B m / (1 + j) ^ m := by
  rw [pool_price_telescope_aux i j B hj N, hL, hend]
  simp

/-- Slope and bend at par (Step 3). Write the pool's price as `V y = L + (r - y)/12 * F y`, where
`r` is the yearly coupon rate (6 percent on the card), `y` the market yield and `F` the discounted
balances, which may move with the yield in any smooth way. At `y = r` the price is the face `L`,
the exact duration `-V'/V` is `F / (12 L)`, and the exact convexity `V''/V` is `-F' / (6 L)`. -/
theorem duration_and_convexity_at_par
    (r L : ℝ) (F : ℝ → ℝ) (hF : Differentiable ℝ F)
    (hF' : DifferentiableAt ℝ (deriv F) r) :
    let V : ℝ → ℝ := fun y => L + (r - y) / 12 * F y
    V r = L ∧
    -deriv V r / V r = F r / (12 * L) ∧
    deriv (deriv V) r / V r = -deriv F r / (6 * L) := by
  intro V
  have hV : ∀ y, HasDerivAt V (-1 / 12 * F y + (r - y) / 12 * deriv F y) y := by
    intro y
    have h1 : HasDerivAt (fun y : ℝ => (r - y) / 12) (-1 / 12) y := by
      have := ((hasDerivAt_id y).const_sub r).div_const 12
      simpa using this
    have h2 := h1.mul (hF y).hasDerivAt
    have h3 := h2.const_add L
    convert h3 using 1
  have hdV : deriv V = fun y => -1 / 12 * F y + (r - y) / 12 * deriv F y := by
    funext y; exact (hV y).deriv
  have hVr : V r = L := by simp [V]
  have hd2 : HasDerivAt (deriv V) (-1 / 12 * deriv F r + (-1 / 12 * deriv F r
      + (r - r) / 12 * deriv (deriv F) r)) r := by
    rw [hdV]
    have h1 : HasDerivAt (fun y : ℝ => (r - y) / 12) (-1 / 12) r := by
      have := ((hasDerivAt_id r).const_sub r).div_const 12
      simpa using this
    exact ((hF r).hasDerivAt.const_mul (-1 / 12)).add (h1.mul hF'.hasDerivAt)
  refine ⟨hVr, ?_, ?_⟩
  · rw [(hV r).deriv, hVr]
    ring
  · rw [hd2.deriv, hVr]
    ring

/-- The bump formulas (Step 5). With today's price `V₀`, prices `V₋` and `V₊` after a bump of `δ`
down and up, the down-side duration `(V₋ - V₀)/(V₀ δ)` and the up-side duration
`(V₀ - V₊)/(V₀ δ)`: effective duration is their average, and effective convexity is the up-side
duration subtracted from the down-side one, divided by the bump. -/
theorem effective_duration_and_convexity_from_one_sided_durations
    (V₀ Vm Vp δ : ℝ) :
    let Ddown := (Vm - V₀) / (V₀ * δ)
    let Dup := (V₀ - Vp) / (V₀ * δ)
    (Vm - Vp) / (2 * V₀ * δ) = (Ddown + Dup) / 2 ∧
    (Vm + Vp - 2 * V₀) / (V₀ * δ ^ 2) = (Ddown - Dup) / δ := by
  intro Ddown Dup
  constructor <;> simp only [Ddown, Dup] <;> ring

/-! Worked numbers from the card, as exact fractions. -/

-- The house prepayment rule c(y) = max(2%, 8% + 2.55 (6% - y)).
-- At 5 percent the speed is 10.55 percent.
example : max ((2 : ℚ) / 100) (8 / 100 + 255 / 100 * (6 / 100 - 5 / 100)) = 1055 / 10000 := by
  norm_num
-- At 7 percent the speed is 5.45 percent.
example : max ((2 : ℚ) / 100) (8 / 100 + 255 / 100 * (6 / 100 - 7 / 100)) = 545 / 10000 := by
  norm_num
-- A 3-point bump up, to 9 percent, puts the speed on the 2 percent floor.
example : max ((2 : ℚ) / 100) (8 / 100 + 255 / 100 * (6 / 100 - 9 / 100)) = 2 / 100 := by
  norm_num

-- The hand table: price swing 105.522436 - 93.287528 = 12.234908.
example : (105522436 : ℚ) / 10 ^ 6 - 93287528 / 10 ^ 6 = 12234908 / 10 ^ 6 := by norm_num
-- Effective duration 12.234908 / (2 × 100 × 0.01) = 6.117454.
example : ((12234908 : ℚ) / 10 ^ 6) / (2 * 100 * (1 / 100)) = 6117454 / 10 ^ 6 := by norm_num
-- The miss 105.522436 + 93.287528 - 200 = -1.190036.
example : (105522436 : ℚ) / 10 ^ 6 + 93287528 / 10 ^ 6 - 200 = -1190036 / 10 ^ 6 := by norm_num
-- Half of -1.190036 is -0.595018.
example : ((-1190036 : ℚ) / 10 ^ 6) / 2 = -595018 / 10 ^ 6 := by norm_num
-- A one-point rise: -6.117454 - 0.595018 = -6.712472.
example : (-6117454 : ℚ) / 10 ^ 6 - 595018 / 10 ^ 6 = -6712472 / 10 ^ 6 := by norm_num
-- A one-point fall: 6.117454 - 0.595018 = 5.522436.
example : (6117454 : ℚ) / 10 ^ 6 - 595018 / 10 ^ 6 = 5522436 / 10 ^ 6 := by norm_num

#print axioms pool_price_eq_face_add_coupon_excess_times_discounted_balances
#print axioms duration_and_convexity_at_par
#print axioms effective_duration_and_convexity_from_one_sided_durations
