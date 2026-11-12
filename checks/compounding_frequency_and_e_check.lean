-- Compounding more often, and the number e: cutting a year's interest at a fixed rate into more equal payments always ends the year higher, never reaches the ceiling exp r (which is e at 100%), and gets as close to it as you like, and that ceiling is the sum of the shrinking list 1 + r + r^2/2 + r^3/6 + ...
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum

open Filter Topology

/-- Helper: the general-rate statement, proved once and used by both main theorems. -/
theorem compound_aux (r : ℝ) (hr : 0 < r) :
    (∀ n : ℕ, 1 ≤ n →
      (1 + r / (n : ℝ)) ^ n < (1 + r / ((n + 1 : ℕ) : ℝ)) ^ (n + 1)) ∧
    (∀ n : ℕ, 1 ≤ n → (1 + r / (n : ℝ)) ^ n < Real.exp r) ∧
    Tendsto (fun n : ℕ => (1 + r / (n : ℝ)) ^ n) atTop (𝓝 (Real.exp r)) := by
  refine ⟨?_, ?_, Real.tendsto_one_add_div_pow_exp r⟩
  · intro n hn
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have ha : 0 < 1 + r / (n : ℝ) := by positivity
    have hb : 0 < 1 + r / ((n : ℝ) + 1) := by positivity
    set a := 1 + r / (n : ℝ) with ha_def
    set b := 1 + r / ((n : ℝ) + 1) with hb_def
    have hx : b / a = 1 + (-(r / (((n : ℝ) + 1) * ((n : ℝ) + r)))) := by
      rw [ha_def, hb_def]
      field_simp
      ring
    have hxne : -(r / (((n : ℝ) + 1) * ((n : ℝ) + r))) ≠ 0 := by
      have : 0 < r / (((n : ℝ) + 1) * ((n : ℝ) + r)) := by positivity
      linarith
    have hxge : (-1 : ℝ) ≤ -(r / (((n : ℝ) + 1) * ((n : ℝ) + r))) := by
      have h1 : r / (((n : ℝ) + 1) * ((n : ℝ) + r)) ≤ 1 := by
        rw [div_le_one (by positivity)]
        nlinarith
      linarith
    have hb0 := one_add_mul_self_lt_rpow_one_add hxge hxne
      (show (1 : ℝ) < ((n + 1 : ℕ) : ℝ) by push_cast; linarith)
    have hb1 : 1 + ((n + 1 : ℕ) : ℝ) * (-(r / (((n : ℝ) + 1) * ((n : ℝ) + r)))) <
        (1 + (-(r / (((n : ℝ) + 1) * ((n : ℝ) + r))))) ^ (n + 1) := by
      rwa [Real.rpow_natCast] at hb0
    rw [← hx, div_pow] at hb1
    have e1 : (1 : ℝ) + ((n + 1 : ℕ) : ℝ) * (-(r / (((n : ℝ) + 1) * ((n : ℝ) + r)))) = 1 / a := by
      rw [ha_def]
      push_cast
      field_simp
      ring
    rw [e1, lt_div_iff₀ (by positivity)] at hb1
    have : 1 / a * a ^ (n + 1) = a ^ n := by
      rw [pow_succ]; field_simp
    have hcast : (((n + 1 : ℕ) : ℝ)) = (n : ℝ) + 1 := by push_cast; ring
    rw [hcast]
    rw [this] at hb1
    exact hb1
  · intro n hn
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have h1 : 1 + r / (n : ℝ) < Real.exp (r / (n : ℝ)) := by
      have := Real.add_one_lt_exp (show r / (n : ℝ) ≠ 0 by positivity)
      linarith
    have h0 : (0 : ℝ) ≤ 1 + r / (n : ℝ) := by positivity
    calc (1 + r / (n : ℝ)) ^ n < Real.exp (r / (n : ℝ)) ^ n :=
          pow_lt_pow_left₀ h1 h0 (by omega)
      _ = Real.exp r := by
          rw [← Real.exp_nat_mul]; congr 1; field_simp

/-- One dollar at 100% for a year, with the interest left in the account and the rate cut
into `n` equal slices, ends the year at `(1 + 1/n)^n`. Paying more often always earns more:
`n + 1` payments beat `n` payments. But the total is capped by `e = exp 1`: it stays below `e`
for every number of payments, and it climbs as close to `e` as you like. -/
theorem more_payments_earn_more_but_never_pass_e :
    (∀ n : ℕ, 1 ≤ n →
      (1 + 1 / (n : ℝ)) ^ n < (1 + 1 / ((n + 1 : ℕ) : ℝ)) ^ (n + 1)) ∧
    (∀ n : ℕ, 1 ≤ n → (1 + 1 / (n : ℝ)) ^ n < Real.exp 1) ∧
    Tendsto (fun n : ℕ => (1 + 1 / (n : ℝ)) ^ n) atTop (𝓝 (Real.exp 1)) := by
  have h := compound_aux 1 one_pos
  simpa using h

/-- The same at any fixed yearly rate `r > 0` (5% is `r = 1/20`): one dollar paid `n` equal
slices `r / n`, interest left in, ends at `(1 + r/n)^n`. More payments always earn more, the
total stays below the ceiling `exp r`, and it climbs as close to `exp r` as you like. -/
theorem more_payments_at_any_rate_capped_by_exp (r : ℝ) (hr : 0 < r) :
    (∀ n : ℕ, 1 ≤ n →
      (1 + r / (n : ℝ)) ^ n < (1 + r / ((n + 1 : ℕ) : ℝ)) ^ (n + 1)) ∧
    (∀ n : ℕ, 1 ≤ n → (1 + r / (n : ℝ)) ^ n < Real.exp r) ∧
    Tendsto (fun n : ℕ => (1 + r / (n : ℝ)) ^ n) atTop (𝓝 (Real.exp r)) := by
  exact compound_aux r hr

/-- The ceiling is a shrinking list, added up: `1 + r + r^2/2 + r^3/6 + r^4/24 + ...`, each
term the one before times `r` and divided by the next counting number, adds up to `exp r`.
At `r = 1` this is `1 + 1 + 1/2 + 1/6 + ... = e`. -/
theorem ceiling_is_the_shrinking_list (r : ℝ) :
    HasSum (fun k : ℕ => r ^ k / (Nat.factorial k : ℝ)) (Real.exp r) := by
  have h := NormedSpace.expSeries_div_hasSum_exp (𝔸 := ℝ) r
  rw [Real.exp_eq_exp_ℝ]
  exact h

-- Worked numbers, as exact fractions.
-- One dollar at 100%, paid once a year: 2.
example : (1 + 1 : ℚ) ^ 1 = 2 := by norm_num
-- Paid twice: midyear the account holds 3/2, the second half pays 3/4, the year ends at 9/4.
example : (1 : ℚ) * (1 + 1 / 2) = 3 / 2 := by norm_num
example : (3 / 2 : ℚ) * (1 / 2) = 3 / 4 := by norm_num
example : (1 + 1 / 2 : ℚ) ^ 2 = 9 / 4 := by norm_num
-- The extra quarter is the second payment landing on the first one's interest.
example : (9 / 4 : ℚ) - 2 = 1 / 4 := by norm_num
-- Paid monthly: exactly 13^12 / 12^12.
example : (1 + 1 / 12 : ℚ) ^ 12 = 13 ^ 12 / 12 ^ 12 := by norm_num
-- Taking each payment out instead: 12 or 365 slices of 100% still end at 2.
example : (1 : ℚ) + 12 * (1 / 12) = 2 := by norm_num
example : (1 : ℚ) + 365 * (1 / 365) = 2 := by norm_num
-- $100 at 5%, paid once a year: $105.
example : (100 : ℚ) * (1 + 5 / 100) = 105 := by norm_num
-- The shrinking list: each term is the one before divided by the next counting number.
example : (1 : ℚ) / 2 / 3 = 1 / 6 ∧ (1 : ℚ) / 6 / 4 = 1 / 24 := by norm_num

#print axioms compound_aux
#print axioms more_payments_earn_more_but_never_pass_e
#print axioms more_payments_at_any_rate_capped_by_exp
#print axioms ceiling_is_the_shrinking_list
