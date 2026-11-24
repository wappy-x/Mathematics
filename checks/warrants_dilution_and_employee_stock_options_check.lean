-- Warrants and employee options: a warrant on N old shares with M new shares pays exactly N/(N+M) of a call's payoff on the equity per old share, and the employee's leaving chances add up to one.
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.Field.GeomSum
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

/-- The dilution theorem at expiry: with `N > 0` old shares and `M` warrants of strike `K`,
if the equity per old share at expiry is `v`, the warrant pays
`max ((N v + M K)/(N + M) - K) 0`, and this is exactly `N/(N+M)` times the payoff
`max (v - K) 0` of a plain call on `v`. -/
theorem warrant_payoff_eq_dilution_factor_mul_call_payoff
    (N M : ℕ) (hN : 0 < N) (K v : ℝ) :
    max (((N : ℝ) * v + (M : ℝ) * K) / ((N : ℝ) + M) - K) 0
      = (N : ℝ) / ((N : ℝ) + M) * max (v - K) 0 := by
  have hs : (0:ℝ) < (N:ℝ) + M := by positivity
  have hNs : (0:ℝ) ≤ (N:ℝ) / ((N:ℝ) + M) := by positivity
  have key : ((N : ℝ) * v + (M : ℝ) * K) / ((N : ℝ) + M) - K
      = (N : ℝ) / ((N : ℝ) + M) * (v - K) := by
    field_simp
    ring
  rw [key, mul_max_of_nonneg _ _ hNs, mul_zero]

/-- Warrant holders exercise exactly when a plain call holder would: the new share is worth
more than the strike, `(N v + M K)/(N + M) > K`, exactly when `v > K`. -/
theorem warrant_exercised_iff_call_in_the_money
    (N M : ℕ) (hN : 0 < N) (K v : ℝ) :
    K < ((N : ℝ) * v + (M : ℝ) * K) / ((N : ℝ) + M) ↔ K < v := by
  have hs : (0:ℝ) < (N:ℝ) + M := by positivity
  have hNpos : (0:ℝ) < (N:ℝ) := by exact_mod_cast hN
  rw [lt_div_iff₀ hs]
  constructor
  · intro h
    nlinarith
  · intro h
    nlinarith

/-- The employee option ends in exactly one way: first leaving at step `i < n`, with chance
`(1 - ℓ)^i ℓ`, or staying all `n` steps, with chance `(1 - ℓ)^n`; these chances add up to one,
which is why the option is a weighted sum of plain calls. -/
theorem leaving_chances_sum_to_one (ℓ : ℝ) (n : ℕ) :
    (∑ i ∈ Finset.range n, (1 - ℓ) ^ i * ℓ) + (1 - ℓ) ^ n = 1 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ]
    linear_combination ih

-- Acme: 1,000,000 shares, 100,000 warrants, strike 100; the dilution factor is 1/1.1 = 10/11.
example : ((1000000 : ℚ) / (1000000 + 100000)) = 10 / 11 := by norm_num

-- Equity per old share 120 at expiry: each share after exercise is worth 1300/11 (118.18...),
-- and the warrant pays 200/11 = 20/1.1 (18.18...), against the plain call's 20.
example : ((1000000 : ℚ) * 120 + 100000 * 100) / (1000000 + 100000) = 1300 / 11 := by norm_num
example : ((1000000 : ℚ) * 120 + 100000 * 100) / (1000000 + 100000) - 100 = 200 / 11 := by norm_num
example : max (((1000000 : ℚ) * 120 + 100000 * 100) / (1000000 + 100000) - 100) 0
    = (1000000 : ℚ) / (1000000 + 100000) * max (120 - 100) 0 := by norm_num

#print axioms warrant_payoff_eq_dilution_factor_mul_call_payoff
#print axioms warrant_exercised_iff_call_in_the_money
#print axioms leaving_chances_sum_to_one
