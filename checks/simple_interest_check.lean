-- Simple interest: when the same charge, principal times rate, is added every year, the balance after n years is the principal plus principal times rate times n, the balance climbs in equal steps along a straight line, interest that earns interest ends up strictly higher from year two on, and the card's cousin-loan numbers come out as it says.
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-- Simple interest, interest = principal × rate × years: if a loan of `P` at rate `r`
(a decimal, per year) starts at `P` and each year adds the percent taken of the principal
only, `P × r`, then after `n` years the balance is `P + P × r × n`, so the interest added
up is `P × r × n`. -/
theorem simple_interest_balance (P r : ℝ) (b : ℕ → ℝ)
    (h0 : b 0 = P) (hstep : ∀ n, b (n + 1) = b n + P * r) :
    ∀ n : ℕ, b n = P + P * r * n := by
  intro n
  induction n with
  | zero => simp [h0]
  | succ k ih =>
    rw [hstep, ih]
    push_cast
    ring

/-- A straight line: under simple interest the balance rises by the same yearly charge
`P × r` for every year that passes, so between any two years `m` and `n` the balance
changes by `P × r × (n - m)`. -/
theorem simple_interest_straight_line (P r : ℝ) (b : ℕ → ℝ)
    (h0 : b 0 = P) (hstep : ∀ n, b (n + 1) = b n + P * r) :
    ∀ m n : ℕ, b n - b m = P * r * ((n : ℝ) - m) := by
  intro m n
  have h := simple_interest_balance P r b h0 hstep
  rw [h n, h m]
  ring

/-- Taking the percent of the balance instead of the principal is a different deal: if the
interest earns interest (each year adds `r` times the current balance), then for a positive
principal and a positive rate the bill is strictly higher than the simple-interest bill
from the second year on. -/
theorem interest_on_interest_bill_higher (P r : ℝ) (hP : 0 < P) (hr : 0 < r)
    (b c : ℕ → ℝ)
    (hb0 : b 0 = P) (hb : ∀ n, b (n + 1) = b n + P * r)
    (hc0 : c 0 = P) (hc : ∀ n, c (n + 1) = c n + c n * r) :
    ∀ n : ℕ, 2 ≤ n → b n < c n := by
  have hc1 : c 1 = P + P * r := by rw [hc 0, hc0]
  have hc2 : c 2 = P + 2 * P * r + P * r ^ 2 := by
    have := hc 1
    rw [hc1] at this
    rw [show (2:ℕ) = 1 + 1 from rfl, this]; ring
  have hcpos : ∀ n : ℕ, 0 < c n := by
    intro n
    induction n with
    | zero => rw [hc0]; exact hP
    | succ k ih => rw [hc]; nlinarith [mul_pos ih hr]
  have key : ∀ n : ℕ, 2 ≤ n → P + P * r * n < c n := by
    intro n hn
    induction n, hn using Nat.le_induction with
    | base =>
      rw [hc2]; push_cast
      nlinarith [mul_pos hP (pow_pos hr 2)]
    | succ k hk ih =>
      rw [hc]
      push_cast
      have hk0 : (0:ℝ) ≤ k := Nat.cast_nonneg k
      nlinarith [mul_pos hP hr, mul_pos (mul_pos hP hr) hr, mul_nonneg (mul_nonneg (mul_pos hP hr).le hr.le) hk0, mul_lt_mul_of_pos_right ih hr]
  intro n hn
  have h := simple_interest_balance P r b hb0 hb n
  rw [h]
  exact key n hn

-- The card's worked numbers, in whole dollars (4% is 4 per 100).
example : 500 * 4 / 100 = 20 := by decide              -- one year's interest
example : 500 + 20 = 520 := by decide                  -- after year 1
example : 520 + 20 = 540 := by decide                  -- after year 2
example : 540 + 20 = 560 := by decide                  -- after year 3
example : 560 + 20 = 580 := by decide                  -- after year 4
example : 580 + 20 = 600 := by decide                  -- after year 5
example : 20 * 5 = 100 := by decide                    -- five years' interest, added up
example : 500 * 4 * 5 / 100 = 100 := by decide         -- principal × rate × years
example : 500 + 500 * 4 * 5 / 100 = 600 := by decide   -- the same, in one move
-- The same in the main theorem's form, with the rate 4/100 as an exact fraction.
example : (500 : ℝ) + 500 * (4 / 100) * 5 = 600 := by norm_num
-- The mistakes.
example : 500 + 500 * 4 * 5 = 10500 := by decide       -- 4% read as 4
-- Interest on interest: 500 × 1.04^5 is exactly 608.3264512, which is $608.33 to the cent.
example : (500 : ℚ) * (1 + 4 / 100) ^ 5 = 6083264512 / 10000000 := by norm_num
example : (60832.5 : ℚ) ≤ 500 * (1 + 4 / 100) ^ 5 * 100 ∧
    (500 : ℚ) * (1 + 4 / 100) ^ 5 * 100 < 60833.5 := by norm_num

#print axioms simple_interest_balance
#print axioms simple_interest_straight_line
#print axioms interest_on_interest_bill_higher
