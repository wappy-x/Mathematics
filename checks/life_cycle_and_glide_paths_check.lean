-- Investing over a lifetime: a pot that takes out a fixed amount c at the start of each year and then grows by that year's factor pays all n withdrawals exactly when the starting pot is at least c times the realised discount sum S_n, for any positive growth factors at all, and the card's crash-first and crash-last stories check out exactly.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.Ring
import Mathlib.Algebra.Order.BigOperators.Ring.Finset

namespace LifeCycleAndGlidePaths

open Finset

/-! Setting. `G t` is year `t`'s growth factor after inflation, for years `t = 1, 2, 3, ...`
(`G 0` is never used). `W₀` is the starting pot and `c` the yearly withdrawal, both in today's
dollars. Each year the owner takes out `c` first, then the rest grows by that year's factor.
No return model is assumed: the theorems hold for every sequence of positive growth factors. -/

/-- `P_k = G_1 G_2 ⋯ G_k`, the growth of the first `k` years multiplied together; `P_0 = 1`. -/
def growthUpTo (G : ℕ → ℝ) (k : ℕ) : ℝ := ∏ t ∈ range k, G (t + 1)

/-- The realised discount sum `S_n = 1/P_0 + 1/P_1 + ⋯ + 1/P_{n-1}`: the price today, counted
in withdrawals, of `n` withdrawals, each discounted at the growth earned before it. -/
noncomputable def discountSum (G : ℕ → ℝ) (n : ℕ) : ℝ := ∑ k ∈ range n, 1 / growthUpTo G k

/-- The pot `W_k` after `k` years, just before the next withdrawal:
`W_0 = W₀` and `W_k = (W_{k-1} - c) G_k`. -/
def potAfter (W₀ c : ℝ) (G : ℕ → ℝ) : ℕ → ℝ
  | 0 => W₀
  | k + 1 => (potAfter W₀ c G k - c) * G (k + 1)

/-- Every `P_k` is positive when the growth factors are. -/
theorem growthUpTo_pos (G : ℕ → ℝ) (hG : ∀ t, 0 < G t) (k : ℕ) : 0 < growthUpTo G k := by
  unfold growthUpTo
  exact Finset.prod_pos (fun t _ => hG (t + 1))

/-- The discount sums grow with the number of withdrawals. -/
theorem discountSum_mono (G : ℕ → ℝ) (hG : ∀ t, 0 < G t) {m n : ℕ} (hmn : m ≤ n) :
    discountSum G m ≤ discountSum G n := by
  unfold discountSum
  apply Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_mono hmn)
  intro k _ _
  exact le_of_lt (one_div_pos.mpr (growthUpTo_pos G hG k))

/-- Helper: the unrolled pot. -/
theorem potAfter_eq_aux (W₀ c : ℝ) (G : ℕ → ℝ) (hG : ∀ t, 0 < G t) (k : ℕ) :
    potAfter W₀ c G k = growthUpTo G k * (W₀ - c * discountSum G k) := by
  induction k with
  | zero => simp [potAfter, growthUpTo, discountSum]
  | succ k ih =>
    have hP := growthUpTo_pos G hG k
    have hS : discountSum G (k + 1) = discountSum G k + 1 / growthUpTo G k := by
      simp [discountSum, Finset.sum_range_succ]
    have hP1 : growthUpTo G (k + 1) = growthUpTo G k * G (k + 1) := by
      simp [growthUpTo, Finset.prod_range_succ]
    rw [potAfter, ih, hS, hP1]
    field_simp
    ring

/-- Helper: one withdrawal at a time. -/
theorem payable_iff_aux (W₀ c : ℝ) (G : ℕ → ℝ) (hG : ∀ t, 0 < G t) (k : ℕ) :
    c ≤ potAfter W₀ c G k ↔ c * discountSum G (k + 1) ≤ W₀ := by
  have hP := growthUpTo_pos G hG k
  have hS : discountSum G (k + 1) = discountSum G k + 1 / growthUpTo G k := by
    simp [discountSum, Finset.sum_range_succ]
  rw [potAfter_eq_aux W₀ c G hG k, hS, mul_add, ← le_sub_iff_add_le', mul_one_div,
    div_le_iff₀ hP, mul_comm]

/-- The card's main claim (Steps 1 and 2). Take any positive growth factors, a withdrawal
`c ≥ 0` taken at the start of each year, and `n ≥ 1` planned withdrawals. Withdrawal `k + 1`
can be paid when the pot then holds at least `c`. The pot pays all `n` withdrawals exactly
when it covers every withdrawal discounted at the growth the pot actually earned before it:
`W₀ ≥ c S_n`. -/
theorem pot_survives_iff_covers_discount_sum (W₀ c : ℝ) (G : ℕ → ℝ) (hG : ∀ t, 0 < G t)
    (hc : 0 ≤ c) (n : ℕ) (hn : 0 < n) :
    (∀ k < n, c ≤ potAfter W₀ c G k) ↔ c * discountSum G n ≤ W₀ := by
  constructor
  · intro h
    have h1 := (payable_iff_aux W₀ c G hG (n - 1)).mp (h (n - 1) (by omega))
    rwa [Nat.sub_add_cancel hn] at h1
  · intro h k hk
    rw [payable_iff_aux W₀ c G hG k]
    have := discountSum_mono G hG (show k + 1 ≤ n by omega)
    nlinarith

/-- The unrolled pot (Step 1). For any positive growth factors and any withdrawal `c`, the pot
after `k` years is the growth so far times what is left of the starting pot once the first
`k` withdrawals are paid at their discounted prices:
`W_k = P_k (W₀ - c (1/P_0 + ⋯ + 1/P_{k-1}))`. -/
theorem pot_after_unrolled (W₀ c : ℝ) (G : ℕ → ℝ) (hG : ∀ t, 0 < G t) (k : ℕ) :
    potAfter W₀ c G k = growthUpTo G k * (W₀ - c * discountSum G k) := by
  exact potAfter_eq_aux W₀ c G hG k

/-- One withdrawal at a time (Step 2). For any positive growth factors and any withdrawal `c`,
the pot can pay withdrawal `k + 1`, that is `W_k ≥ c`, exactly when `W₀ ≥ c S_{k+1}`. -/
theorem withdrawal_payable_iff (W₀ c : ℝ) (G : ℕ → ℝ) (hG : ∀ t, 0 < G t) (k : ℕ) :
    c ≤ potAfter W₀ c G k ↔ c * discountSum G (k + 1) ≤ W₀ := by
  exact payable_iff_aux W₀ c G hG k

/-! The card's worked numbers, as exact fractions. The story: $1,000,000, $40,000 a year,
30 withdrawals; minus 15 percent (factor 17/20) three years running and plus 6 percent
(factor 53/50) in the other 27 years. -/

/-- Crash first: the three bad years come in years 1 to 3. -/
noncomputable def crashFirst (t : ℕ) : ℝ := if t ≤ 3 then 17 / 20 else 53 / 50

/-- Crash last: the three bad years come in years 28 to 30. -/
noncomputable def crashLast (t : ℕ) : ℝ := if t ≤ 27 then 53 / 50 else 17 / 20

-- The pot in withdrawals: 1,000,000 / 40,000 = 25.
example : (1000000 : ℝ) / 40000 = 25 := by norm_num

-- Crash first, by hand: $816,000, $659,600, $526,660 after years 1, 2, 3.
example : potAfter 1000000 40000 crashFirst 1 = 816000 ∧
    potAfter 1000000 40000 crashFirst 2 = 659600 ∧
    potAfter 1000000 40000 crashFirst 3 = 526660 := by
  norm_num [potAfter, crashFirst]

-- Crash first: S_30 = 26.3624 is above 25, so the pot fails.
example : 25 < discountSum crashFirst 30 := by
  norm_num [discountSum, growthUpTo, crashFirst, Finset.sum_range_succ, Finset.prod_range_succ]

-- Crash last: S_30 = 14.7415 is at most 25, so the pot lasts.
example : discountSum crashLast 30 ≤ 25 := by
  norm_num [discountSum, growthUpTo, crashLast, Finset.sum_range_succ, Finset.prod_range_succ]

-- Crash first runs dry in year 27: withdrawal 26 is paid, withdrawal 27 is not.
example : 40000 ≤ potAfter 1000000 40000 crashFirst 25 ∧
    potAfter 1000000 40000 crashFirst 26 < 40000 := by
  norm_num [potAfter, crashFirst]

-- Crash last pays all 30 withdrawals.
example : ∀ k < 30, (40000 : ℝ) ≤ potAfter 1000000 40000 crashLast k := by
  intro k hk
  interval_cases k <;> norm_num [potAfter, crashLast]

-- The same 30 factors in either order multiply to the same P_30.
example : growthUpTo crashFirst 30 = growthUpTo crashLast 30 := by
  norm_num [growthUpTo, crashFirst, crashLast, Finset.prod_range_succ]

-- The 60/40 pot: a = 0.6 × 0.08 + 0.4 × 0.03 = 0.06.
example : (6 / 10 : ℝ) * (8 / 100) + 4 / 10 * (3 / 100) = 6 / 100 := by norm_num

-- s² = (0.6 × 0.20)² + (0.4 × 0.08)² = 0.0144 + 0.001024 = 0.015424.
example : ((6 / 10 : ℝ) * (20 / 100)) ^ 2 + (4 / 10 * (8 / 100)) ^ 2 = 15424 / 1000000 := by
  norm_num

-- m = 0.06 - 0.5 × 0.015424 = 0.052288.
example : (6 / 100 : ℝ) - 1 / 2 * (15424 / 1000000) = 52288 / 1000000 := by norm_num

#print axioms growthUpTo_pos
#print axioms discountSum_mono
#print axioms potAfter_eq_aux
#print axioms payable_iff_aux
#print axioms pot_survives_iff_covers_discount_sum
#print axioms pot_after_unrolled
#print axioms withdrawal_payable_iff

end LifeCycleAndGlidePaths
