-- Euler's totient: for every whole number n, the count of numbers from 1 to n sharing no factor with n equals n times one bracket (1 - 1/p) for each different prime p dividing n, the count multiplies across coprime parts, and a prime p gives p - 1.
import Mathlib.Data.Nat.Totient
import Mathlib.Data.Nat.PrimeFin
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Tactic.NormNum

/-- Euler's totient from the factorisation. For every whole number n, the count of the numbers
1, 2, up to n that share no factor with n equals n × (1 − 1/p) × ... with one bracket for each
different prime p dividing n: one bracket per prime, no matter how many copies of it n holds. -/
theorem count_coprime_eq_n_times_prime_brackets (n : ℕ) :
    ((((Finset.Icc 1 n).filter (fun k => Nat.Coprime k n)).card : ℕ) : ℚ) =
      (n : ℚ) * ∏ p ∈ n.primeFactors, (1 - 1 / (p : ℚ)) := by
  have hcard : ((Finset.Icc 1 n).filter (fun k => Nat.Coprime k n)).card = Nat.totient n := by
    have h := Nat.filter_coprime_Ico_eq_totient n 1
    have e : Finset.Ico 1 (1 + n) = Finset.Icc 1 n := by
      ext x; simp only [Finset.mem_Ico, Finset.mem_Icc]; omega
    rw [e] at h
    rw [← h]
    congr 1
    ext k
    simp only [Finset.mem_filter, Nat.coprime_comm]
  rw [hcard, Nat.totient_eq_mul_prod_factors]
  simp [one_div]

/-- Coprime parts multiply. If m and n share no factor above 1, the totient of m × n is the
totient of m times the totient of n. (Mathlib's `Nat.totient`, written φ, counts the numbers below
n that share no factor with n, which is the same count as 1 to n.) -/
theorem totient_mul_of_coprime_parts (m n : ℕ) (h : Nat.Coprime m n) :
    Nat.totient (m * n) = Nat.totient m * Nat.totient n := by
  exact Nat.totient_mul h

/-- A prime clock. For a prime p, every number from 1 to p − 1 shares no factor with p, so the
totient of p is p − 1. -/
theorem totient_of_prime (p : ℕ) (hp : Nat.Prime p) : Nat.totient p = p - 1 := by
  exact Nat.totient_prime hp

-- Jump 7 from C round the 12-note clock: 0 7 2 9 4 11 6 1 8 3 10 5, then back to 0.
example : (List.range 12).map (fun k => 7 * k % 12) = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5] := by
  decide
-- Notes visited by jumps 1 to 12: 12 6 4 3 12 2 12 3 4 6 12 1.
example : (List.range' 1 12).map (fun j => ((Finset.range 12).image (fun k => j * k % 12)).card) =
    [12, 6, 4, 3, 12, 2, 12, 3, 4, 6, 12, 1] := by decide
-- The numbers 1 to 12 sharing no factor with 12 are 1, 5, 7 and 11, so phi(12) = 4.
example : (Finset.Icc 1 12).filter (fun k => Nat.Coprime k 12) = {1, 5, 7, 11} := by decide
example : Nat.totient 12 = 4 := by decide
-- From the primes: 12 = 2 × 2 × 3, and 12 × (1 − 1/2) × (1 − 1/3) = 12 × 1/2 × 2/3 = 4.
example : (12 : ℕ) = 2 * 2 * 3 := by decide
example : Nat.primeFactors 12 = {2, 3} := by decide +kernel
example : (12 : ℚ) * (1 - 1 / 2) * (1 - 1 / 3) = 4 ∧ (12 : ℚ) * (1 / 2) * (2 / 3) = 4 := by norm_num
-- Crossing out: 6 multiples of 2, 4 of 3, 2 counted twice, so 6 + 4 − 2 = 8 out and 4 stand.
example : ((Finset.Icc 1 12).filter (2 ∣ ·)).card = 6 ∧ ((Finset.Icc 1 12).filter (3 ∣ ·)).card = 4 ∧
    ((Finset.Icc 1 12).filter (6 ∣ ·)).card = 2 ∧ 12 - (6 + 4 - 2) = 4 := by decide
-- Coprime parts: 4 and 3 share no factor, phi(4) × phi(3) = 2 × 2 = 4.
example : Nat.Coprime 4 3 ∧ Nat.totient 4 = 2 ∧ Nat.totient 3 = 2 ∧
    Nat.totient 4 * Nat.totient 3 = Nat.totient 12 := by decide
example : (4 : ℚ) * (1 - 1 / 2) = 2 ∧ (3 : ℚ) * (1 - 1 / 3) = 2 := by norm_num
-- A prime clock: phi(7) = 7 × (1 − 1/7) = 7 − 1 = 6; and phi(9) = 6.
example : Nat.totient 7 = 6 ∧ Nat.totient 9 = 6 := by decide
example : (7 : ℚ) * (1 - 1 / 7) = 6 := by norm_num
-- The three mistakes: 12 − 1 = 11, a bracket per copy gives 2, stopping after the evens gives 6.
example : 12 - 1 = 11 ∧ Nat.totient 12 ≠ 11 := by decide
example : (12 : ℚ) * (1 - 1 / 2) * (1 - 1 / 2) * (1 - 1 / 3) = 2 ∧ (12 : ℚ) * (1 - 1 / 2) = 6 := by
  norm_num
-- Parts that share a factor do not multiply: 12 = 2 × 6, but phi(2) × phi(6) = 2, not phi(12) = 4.
example : Nat.totient 2 * Nat.totient 6 = 2 ∧ Nat.totient 2 * Nat.totient 6 ≠ Nat.totient 12 := by
  decide
-- The two roads agree on every clock size from 1 to 60 (listing 1 to n against Mathlib's totient).
example : ∀ n ∈ Finset.Icc 1 60,
    ((Finset.Icc 1 n).filter (fun k => Nat.Coprime k n)).card = Nat.totient n := by decide

#print axioms count_coprime_eq_n_times_prime_brackets
#print axioms totient_mul_of_coprime_parts
#print axioms totient_of_prime
