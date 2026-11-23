-- Twin primes: for every odd prime p the share of whole numbers n with neither n nor n + 2 a multiple of p, divided by the share for two independent numbers, is exactly 1 − 1/(p − 1)^2, the only three primes in a row two apart are 3, 5 and 7, and the sum of 1/(p − 1)^2 over the odd primes stays below 1, so the twin prime constant's product converges.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring

open Finset

theorem filter_eq_aux (p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) :
    {r ∈ range p | ¬ p ∣ r ∧ ¬ p ∣ r + 2} = ((range p).erase 0).erase (p - 2) := by
  have h3 : 3 ≤ p := by have := hp.two_le; omega
  ext r
  simp only [mem_filter, mem_range, mem_erase]
  constructor
  · rintro ⟨hr, h1, h2⟩
    refine ⟨?_, ?_, hr⟩
    · rintro rfl
      exact h2 (by rw [show p - 2 + 2 = p by omega])
    · rintro rfl
      exact h1 (dvd_zero p)
  · rintro ⟨hne, hne0, hr⟩
    refine ⟨hr, ?_, ?_⟩
    · intro h
      exact hne0 (Nat.eq_zero_of_dvd_of_lt h hr)
    · intro h
      by_cases hle : p ≤ r + 2
      · have h' : p ∣ r + 2 - p := Nat.dvd_sub h dvd_rfl
        have := Nat.eq_zero_of_dvd_of_lt h' (by omega)
        omega
      · have := Nat.eq_zero_of_dvd_of_lt h (by omega)
        omega

theorem sum_inv_sq_succ_succ_le (n : ℕ) :
    ∑ k ∈ range n, (1 : ℚ) / ((k : ℚ) + 2) ^ 2 ≤ 1 - 1 / ((n : ℚ) + 1) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [sum_range_succ]
    have key : (1 : ℚ) / (n + 1) - 1 / (n + 2) - 1 / (n + 2) ^ 2
        = 1 / ((n + 1) * (n + 2) ^ 2) := by
      field_simp
      ring
    have hpos : (0 : ℚ) ≤ 1 / ((n + 1) * (n + 2) ^ 2) := by positivity
    push_cast
    have : ((n : ℚ) + 1 + 1) = n + 2 := by ring
    rw [this]
    linarith

#print axioms filter_eq_aux
#print axioms sum_inv_sq_succ_succ_le

/-- Step 2, the correction at each odd prime. Fix an odd prime p and look at the p
remainders r = 0, 1, …, p − 1. Exactly p − 2 of them keep p off both r and r + 2, and the
share of such remainders, (p − 2)/p, divided by the share for two independent numbers,
(1 − 1/p)^2, equals 1 − 1/(p − 1)^2: the factor at p in the twin prime constant C_2. -/
theorem twin_correction_factor_at_odd_prime (p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) :
    #{r ∈ range p | ¬ p ∣ r ∧ ¬ p ∣ r + 2} = p - 2 ∧
    ((#{r ∈ range p | ¬ p ∣ r ∧ ¬ p ∣ r + 2} : ℚ) / p) / (1 - 1 / (p : ℚ)) ^ 2
      = 1 - 1 / ((p : ℚ) - 1) ^ 2 := by
  have h3 : 3 ≤ p := by have := hp.two_le; omega
  have hc : #{r ∈ range p | ¬ p ∣ r ∧ ¬ p ∣ r + 2} = p - 2 := by
    rw [filter_eq_aux p hp hp2, card_erase_of_mem, card_erase_of_mem, card_range]
    · omega
    · simp; omega
    · simp; omega
  refine ⟨hc, ?_⟩
  rw [hc, Nat.cast_sub (by omega), Nat.cast_ofNat]
  have hp0 : (p : ℚ) ≠ 0 := by positivity
  have hp1 : (p : ℚ) - 1 ≠ 0 := by
    have : (3 : ℚ) ≤ p := by exact_mod_cast h3
    linarith
  field_simp
  ring

/-- When it holds, the pattern n, n + 2, n + 4: one of the three is always a multiple of 3,
so the only whole number n with n, n + 2 and n + 4 all prime is n = 3 (the triple 3, 5, 7). -/
theorem prime_triple_two_apart_iff_eq_three (n : ℕ) :
    (n.Prime ∧ (n + 2).Prime ∧ (n + 4).Prime) ↔ n = 3 := by
  constructor
  · rintro ⟨h0, h2, h4⟩
    have hm : n % 3 = 0 ∨ n % 3 = 1 ∨ n % 3 = 2 := by omega
    rcases hm with hm | hm | hm
    · have hd : 3 ∣ n := by omega
      rcases h0.eq_one_or_self_of_dvd 3 hd with h | h <;> omega
    · have hd : 3 ∣ n + 2 := by omega
      rcases h2.eq_one_or_self_of_dvd 3 hd with h | h
      · omega
      · have : n = 1 := by omega
        subst this; norm_num at h0
    · have hd : 3 ∣ n + 4 := by omega
      rcases h4.eq_one_or_self_of_dvd 3 hd with h | h <;> omega
  · rintro rfl
    norm_num

/-- Why the product converges: over the odd primes p below any bound N, the amounts
1/(p − 1)^2 removed by the factors of C_2 add up to less than 1, since they are at most
1/2^2 + 1/3^2 + … < 1/(1·2) + 1/(2·3) + … = 1. -/
theorem sum_inv_sq_pred_odd_primes_lt_one (N : ℕ) :
    ∑ p ∈ (range N).filter (fun p => p.Prime ∧ p ≠ 2), (1 : ℚ) / ((p : ℚ) - 1) ^ 2 < 1 := by
  have hsub : (range N).filter (fun p => p.Prime ∧ p ≠ 2) ⊆ Ico 3 N := by
    intro p hp
    simp only [mem_filter, mem_range] at hp
    have := hp.2.1.two_le
    simp only [mem_Ico]
    omega
  calc ∑ p ∈ (range N).filter (fun p => p.Prime ∧ p ≠ 2), (1 : ℚ) / ((p : ℚ) - 1) ^ 2
      ≤ ∑ p ∈ Ico 3 N, (1 : ℚ) / ((p : ℚ) - 1) ^ 2 :=
        sum_le_sum_of_subset_of_nonneg hsub (fun _ _ _ => by positivity)
    _ = ∑ k ∈ range (N - 3), (1 : ℚ) / ((k : ℚ) + 2) ^ 2 := by
        rw [sum_Ico_eq_sum_range]
        refine sum_congr rfl (fun k _ => ?_)
        push_cast
        ring_nf
    _ ≤ 1 - 1 / (((N - 3 : ℕ) : ℚ) + 1) := sum_inv_sq_succ_succ_le _
    _ < 1 := by
        have : (0 : ℚ) < 1 / (((N - 3 : ℕ) : ℚ) + 1) := by positivity
        linarith

-- The card's whole-number examples.

-- The example twin pair: 1,000,000,007 and 1,000,000,009 are both prime, two apart, and the
-- first twin pair from 1,000,000,000 up (1,000,000,001 is not prime).
set_option maxRecDepth 100000 in
example : Nat.Prime 1000000007 ∧ Nat.Prime 1000000009 ∧ 1000000009 - 1000000007 = 2 := by
  norm_num
example : ¬ Nat.Prime 1000000001 := by norm_num
set_option maxRecDepth 100000 in
example : ∀ n : ℕ, 1000000000 ≤ n → n < 1000000007 → ¬ (n.Prime ∧ (n + 2).Prime) := by
  intro n h1 h2
  interval_cases n <;> norm_num
-- Step 2's table: remainders mod p that keep p off both r and r + 2.
-- p = 2: 1 of 2; p = 3: 1 of 3; p = 5: 3 of 5; p = 7: 5 of 7; p = 11: 9 of 11.
example : #{r ∈ range 2 | ¬ 2 ∣ r ∧ ¬ 2 ∣ r + 2} = 1 := by decide
example : #{r ∈ range 3 | ¬ 3 ∣ r ∧ ¬ 3 ∣ r + 2} = 1 := by decide
example : #{r ∈ range 5 | ¬ 5 ∣ r ∧ ¬ 5 ∣ r + 2} = 3 := by decide
example : #{r ∈ range 7 | ¬ 7 ∣ r ∧ ¬ 7 ∣ r + 2} = 5 := by decide
example : #{r ∈ range 11 | ¬ 11 ∣ r ∧ ¬ 11 ∣ r + 2} = 9 := by decide
-- The ratios: 2 at p = 2, then 3/4, 15/16, 35/36, 99/100.
example : ((1 : ℚ) / 2) / (1 - 1 / 2) ^ 2 = 2 := by norm_num
example : ((1 : ℚ) / 3) / (1 - 1 / 3) ^ 2 = 3 / 4 ∧ 1 - 1 / ((3 : ℚ) - 1) ^ 2 = 3 / 4 := by norm_num
example : ((3 : ℚ) / 5) / (1 - 1 / 5) ^ 2 = 15 / 16 ∧ 1 - 1 / ((5 : ℚ) - 1) ^ 2 = 15 / 16 := by
  norm_num
example : ((5 : ℚ) / 7) / (1 - 1 / 7) ^ 2 = 35 / 36 ∧ 1 - 1 / ((7 : ℚ) - 1) ^ 2 = 35 / 36 := by
  norm_num
example : ((9 : ℚ) / 11) / (1 - 1 / 11) ^ 2 = 99 / 100 ∧ 1 - 1 / ((11 : ℚ) - 1) ^ 2 = 99 / 100 := by
  norm_num
-- Gap 6: the prime 3 divides p + 6 exactly when it divides p, so 2 of the 3 remainders pass,
-- twice the 1 of 3 for twins.
example : #{r ∈ range 3 | ¬ 3 ∣ r ∧ ¬ 3 ∣ r + 6} = 2 := by decide
-- The triple 3, 5, 7.
example : Nat.Prime 3 ∧ Nat.Prime 5 ∧ Nat.Prime 7 := by norm_num
-- The gap from 2 to 3 is 1, the only odd gap; the first twin pairs are 3, 5 and 5, 7.
example : 3 - 2 = 1 ∧ Nat.Prime 2 ∧ Nat.Prime 3 := by norm_num
-- The widest gap below a million: 114, from 492,113 to the next prime 492,227.
example : Nat.Prime 492113 ∧ Nat.Prime 492227 ∧ 492227 - 492113 = 114 := by norm_num
example : ∀ m : ℕ, 492113 < m → m < 492227 → ¬ m.Prime := by
  intro m h1 h2
  interval_cases m <;> norm_num

#print axioms twin_correction_factor_at_odd_prime
#print axioms prime_triple_two_apart_iff_eq_three
#print axioms sum_inv_sq_pred_odd_primes_lt_one
