-- Solving a swap backwards: a plain swap's value turns back into exactly one fixed rate, and a par quote with the earlier discount factors known turns back into exactly one discount factor, positive exactly when the quote lies between -100 percent and 1/B.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.LinearCombination

open Finset

/-- Value today, to whoever receives fixed, of an `n`-year swap with annual payments
(accrual fraction 1), notional `N` and fixed rate `K`, priced payment by payment on the
discount curve `D` (with `D 0 = 1`). Year `i + 1` pays fixed `N * K` and floating
`N * f`, where `f = D i / D (i + 1) - 1` is the forward rate the same curve sets for
that year; both payments are discounted by `D (i + 1)`. -/
noncomputable def receiverValue (N K : ℝ) (D : ℕ → ℝ) (n : ℕ) : ℝ :=
  ∑ i ∈ range n, (N * K * D (i + 1) - N * (D i / D (i + 1) - 1) * D (i + 1))

/-- The annuity: what one dollar a year for `n` years costs today, `D 1 + ... + D n`. -/
def annuity (D : ℕ → ℝ) (n : ℕ) : ℝ := ∑ i ∈ range n, D (i + 1)

/-- The swap value telescopes: the floating leg collapses to `N (D 0 - D m)`. -/
theorem receiverValue_telescope (N K : ℝ) (D : ℕ → ℝ) (n : ℕ)
    (hD : ∀ i ∈ Icc 1 n, 0 < D i) :
    ∀ m, m ≤ n → receiverValue N K D m = N * K * annuity D m - N * (D 0 - D m) := by
  intro m
  induction m with
  | zero => intro _; simp [receiverValue, annuity]
  | succ k ih =>
    intro hk
    have hpos : 0 < D (k + 1) := hD (k + 1) (by simp [mem_Icc]; omega)
    have h := ih (by omega)
    unfold receiverValue annuity at *
    rw [sum_range_succ, sum_range_succ, h]
    field_simp
    ring

/-- The fixed rate from a value. For a plain swap with positive notional and positive
discount factors, one curve both forecasting and discounting the floating rates, every
value `V` to the fixed receiver is reached by exactly one fixed rate, namely the par rate
`(1 - D n) / A` plus the value spread across the annuity, `V / (N A)`. -/
theorem fixed_rate_from_value (N : ℝ) (D : ℕ → ℝ) (n : ℕ) (hn : 1 ≤ n)
    (hN : 0 < N) (hD0 : D 0 = 1) (hD : ∀ i ∈ Icc 1 n, 0 < D i) (V K : ℝ) :
    receiverValue N K D n = V ↔
      K = (1 - D n) / annuity D n + V / (N * annuity D n) := by
  have hA : 0 < annuity D n := by
    unfold annuity
    apply sum_pos
    · intro i hi
      exact hD (i + 1) (by simp [mem_Icc] at hi ⊢; omega)
    · exact ⟨0, by simp; omega⟩
  rw [receiverValue_telescope N K D n hD n le_rfl, hD0]
  have hNA : 0 < N * annuity D n := mul_pos hN hA
  rw [div_add_div _ _ hA.ne' hNA.ne', eq_div_iff (mul_pos hA hNA).ne']
  constructor
  · intro h
    rw [← h]; ring
  · intro h
    have h2 : N * annuity D n * (N * K * annuity D n - N * (1 - D n) - V) = 0 := by
      linear_combination N * h
    rcases mul_eq_zero.mp h2 with h3 | h3
    · exact absurd h3 hNA.ne'
    · linarith

/-- A curve point from a par quote. With the earlier discount factors `D 1, ..., D (n-1)`
known (their sum is `B`), a par quote `S` above -100 percent makes the par equation
`S (B + d) = 1 - d` hold for exactly one new discount factor `d`, namely
`(1 - S B) / (1 + S)`. -/
theorem discount_factor_from_par_quote (D : ℕ → ℝ) (n : ℕ)
    (hD : ∀ i ∈ Ico 1 n, 0 < D i) (S : ℝ) (hS : -1 < S) (d : ℝ) :
    S * ((∑ i ∈ Ico 1 n, D i) + d) = 1 - d ↔
      d = (1 - S * ∑ i ∈ Ico 1 n, D i) / (1 + S) := by
  have h1 : (1 + S) ≠ 0 := by linarith
  rw [eq_div_iff h1]
  constructor <;> intro h <;> linarith

/-- The edges of the curve inversion. When at least one earlier discount factor is known
(so `B > 0`), the par equation `S (B + d) = 1 - d` has a positive solution `d`, a genuine
price, exactly when the quote lies strictly between -100 percent and `1 / B`. -/
theorem par_quote_positive_point_iff (D : ℕ → ℝ) (n : ℕ) (hn : 2 ≤ n)
    (hD : ∀ i ∈ Ico 1 n, 0 < D i) (S : ℝ) :
    (∃ d : ℝ, 0 < d ∧ S * ((∑ i ∈ Ico 1 n, D i) + d) = 1 - d) ↔
      -1 < S ∧ S < 1 / ∑ i ∈ Ico 1 n, D i := by
  set B := ∑ i ∈ Ico 1 n, D i with hBdef
  have hB : 0 < B := by
    apply sum_pos
    · exact hD
    · exact ⟨1, by simp [mem_Ico]; omega⟩
  rw [lt_div_iff₀ hB]
  constructor
  · rintro ⟨d, hd, h⟩
    refine ⟨?_, ?_⟩
    · by_contra hc
      push Not at hc
      nlinarith [mul_nonpos_of_nonpos_of_nonneg (by linarith : S + 1 ≤ 0) (by linarith : 0 ≤ B + d)]
    · nlinarith [mul_pos hd (by
        by_contra hc
        push Not at hc
        nlinarith [mul_nonpos_of_nonpos_of_nonneg (by linarith : S + 1 ≤ 0) (by linarith : 0 ≤ B + d)] : (0:ℝ) < 1 + S)]
  · rintro ⟨h1, h2⟩
    have hS1 : (1 + S) ≠ 0 := by linarith
    refine ⟨(1 - S * B) / (1 + S), div_pos (by linarith) (by linarith), ?_⟩
    field_simp
    ring

/- The card's curve, built exactly from its quotes: a one-year deposit at 4.20 percent and
par swaps at 4.40, 4.55, 4.62 and 4.65 percent, each rung `(1 - S B) / (1 + S)`.
The five-year discount factor lies within 5e-9 of the card's 0.79621728. -/
example :
    let D1 : ℚ := 1 / (1 + 42 / 1000)
    let D2 : ℚ := (1 - 44 / 1000 * D1) / (1 + 44 / 1000)
    let D3 : ℚ := (1 - 455 / 10000 * (D1 + D2)) / (1 + 455 / 10000)
    let D4 : ℚ := (1 - 462 / 10000 * (D1 + D2 + D3)) / (1 + 462 / 10000)
    let D5 : ℚ := (1 - 465 / 10000 * (D1 + D2 + D3 + D4)) / (1 + 465 / 10000)
    79621728 / 100000000 - 5 / 1000000000 < D5 ∧
      D5 < 79621728 / 100000000 + 5 / 1000000000 := by
  intro D1 D2 D3 D4 D5
  norm_num [D1, D2, D3, D4, D5]

/- On the same exact curve, the fixed rate that 100,000 dollars buys on 10,000,000
dollars, `(1 - D5) / A + V / (N A)`, rounds to the card's 4.8782 percent. -/
example :
    let D1 : ℚ := 1 / (1 + 42 / 1000)
    let D2 : ℚ := (1 - 44 / 1000 * D1) / (1 + 44 / 1000)
    let D3 : ℚ := (1 - 455 / 10000 * (D1 + D2)) / (1 + 455 / 10000)
    let D4 : ℚ := (1 - 462 / 10000 * (D1 + D2 + D3)) / (1 + 462 / 10000)
    let D5 : ℚ := (1 - 465 / 10000 * (D1 + D2 + D3 + D4)) / (1 + 465 / 10000)
    let A : ℚ := D1 + D2 + D3 + D4 + D5
    let K : ℚ := (1 - D5) / A + 100000 / (10000000 * A)
    487815 / 10000000 < K ∧ K < 487825 / 10000000 := by
  intro D1 D2 D3 D4 D5 A K
  norm_num [D1, D2, D3, D4, D5, A, K]

#print axioms receiverValue_telescope
#print axioms fixed_rate_from_value
#print axioms discount_factor_from_par_quote
#print axioms par_quote_positive_point_iff
