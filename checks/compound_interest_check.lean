-- Compound interest: a balance that earns the same rate once a year with the interest left in is the start times the growth factor raised to the number of years, it beats the same rate taken out from the second year on by a gap that keeps widening, and the card's account comes out at the cents it says.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

/-- Helper: strict Bernoulli for two or more years. -/
theorem helper_bernoulli_strict (r : ℝ) (hr : 0 < r) (m : ℕ) :
    1 + ((m : ℝ) + 2) * r < (1 + r) ^ (m + 2) := by
  induction m with
  | zero =>
    have : (1 + r) ^ (0 + 2) = 1 + 2 * r + r * r := by ring
    rw [this]
    push_cast
    nlinarith [mul_pos hr hr]
  | succ k ih =>
    have hk : (0 : ℝ) ≤ (k : ℝ) := Nat.cast_nonneg k
    have h1 : (0 : ℝ) < 1 + r := by linarith
    have : (1 + r) ^ (k + 1 + 2) = (1 + r) ^ (k + 2) * (1 + r) := by ring
    rw [this]
    push_cast
    nlinarith [mul_lt_mul_of_pos_right ih h1, mul_nonneg hk (mul_pos hr hr).le, mul_pos hr hr]

#print axioms helper_bernoulli_strict

/-- Compound interest, `A = P × (1 + r)^n`: start an account at `P`, and once a year
add `r` times whatever is in it (the interest stays in, the rate is the same every year,
interest is paid once a year). Then after `n` years the balance is `P` times the growth
factor `1 + r`, multiplied in once for every year. -/
theorem compound_interest_formula (P r : ℝ) (A : ℕ → ℝ)
    (h0 : A 0 = P) (hstep : ∀ k, A (k + 1) = A k + A k * r) (n : ℕ) :
    A n = P * (1 + r) ^ n := by
  induction n with
  | zero => simp [h0]
  | succ k ih => rw [hstep, ih]; ring

/-- Interest left in beats interest taken out: with a positive deposit `P` and a positive
rate `r`, the compound account `A` (each year adds `r` times its own balance) and the simple
account `S` (each year adds `r` times the first deposit only) agree for one year, then from
the second year on the compound balance is strictly larger. -/
theorem compound_beats_simple_from_year_two (P r : ℝ) (hP : 0 < P) (hr : 0 < r)
    (A S : ℕ → ℝ) (hA0 : A 0 = P) (hA : ∀ k, A (k + 1) = A k + A k * r)
    (hS0 : S 0 = P) (hS : ∀ k, S (k + 1) = S k + P * r) (n : ℕ) (hn : 2 ≤ n) :
    S n < A n := by
  have hAn := compound_interest_formula P r A hA0 hA n
  have hSn : ∀ k, S k = P + k * (P * r) := by
    intro k
    induction k with
    | zero => simp [hS0]
    | succ j ih => rw [hS, ih]; push_cast; ring
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  have hb := helper_bernoulli_strict r hr m
  rw [hAn, hSn]
  push_cast
  nlinarith [mul_lt_mul_of_pos_left hb hP]

/-- The gap never stops widening: with a positive deposit and a positive rate, from the
first year on, the amount by which the compound account leads the simple account is
strictly larger every year than the year before. -/
theorem compound_gap_keeps_widening (P r : ℝ) (hP : 0 < P) (hr : 0 < r)
    (A S : ℕ → ℝ) (hA0 : A 0 = P) (hA : ∀ k, A (k + 1) = A k + A k * r)
    (hS0 : S 0 = P) (hS : ∀ k, S (k + 1) = S k + P * r) (n : ℕ) (hn : 1 ≤ n) :
    A n - S n < A (n + 1) - S (n + 1) := by
  have hAn := compound_interest_formula P r A hA0 hA n
  have hSn : ∀ k, S k = P + k * (P * r) := by
    intro k
    induction k with
    | zero => simp [hS0]
    | succ j ih => rw [hS, ih]; push_cast; ring
  have h1 : 1 < (1 + r) ^ n := one_lt_pow₀ (by linarith) (by omega)
  rw [hA, hS, hAn, hSn n]
  have : 0 < P * r * ((1 + r) ^ n - 1) := mul_pos (mul_pos hP hr) (by linarith)
  nlinarith [this]

-- The card's account: $100 at 5% a year, in exact fractions of a dollar.
example : (100 : ℚ) * (105 / 100) = 105 := by norm_num                     -- year 1
example : (100 : ℚ) * (105 / 100) ^ 2 = 11025 / 100 := by norm_num         -- year 2: 110.25
example : (100 : ℚ) * (105 / 100) ^ 3 = 11576250 / 100000 := by norm_num   -- year 3: 115.7625
-- Year 10 to the cent: 10000 × 1.05^10 cents lies within half a cent of 16289.
example : (16288.5 : ℚ) ≤ 10000 * (105 / 100) ^ 10 ∧
    (10000 : ℚ) * (105 / 100) ^ 10 < 16289.5 := by norm_num
-- The card's whole-number road: 105^10, divided down to cents and rounded.
example : (105 ^ 10 + 5 * 10 ^ 15) / 10 ^ 16 = 16289 := by norm_num
-- Simple interest, in cents: $100 plus ten payments of $5.
example : 10000 + 10 * 500 = 15000 := by norm_num
-- The gap, in cents.
example : 16289 - 15000 = 1289 := by norm_num
-- Interest earned in years 1 and 2, in cents: 500 then 525.
example : 10000 * 105 / 100 - 10000 = 500 := by norm_num
example : 10500 * 105 / 100 - 10500 = 525 := by norm_num
-- Five years of growth, applied twice, is the ten-year growth.
example : ((105 : ℕ) ^ 5) ^ 2 = 105 ^ 10 := by norm_num
-- The mistakes, in cents.
example : 10000 * 105 / 100 = 10500 := by norm_num              -- 1.05 once for the decade
example : 10000 * 105 / 100 * 95 / 100 = 9975 := by norm_num    -- 5% up then 5% down

#print axioms compound_interest_formula
#print axioms compound_beats_simple_from_year_two
#print axioms compound_gap_keeps_widening
