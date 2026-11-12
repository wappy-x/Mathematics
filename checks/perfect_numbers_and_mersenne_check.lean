-- Perfect numbers and Mersenne primes: whenever one less than a doubling of 1 is prime, that prime times the doubling below it is a perfect number (Euclid), all its divisors add to twice it, a prime Mersenne number needs a prime count of doublings, and the card's numbers 6, 28, 496, 8128 and 2047 = 23 × 89 come out as it says.
import Mathlib.NumberTheory.LucasLehmer
import Mathlib.NumberTheory.Divisors
import Mathlib.Tactic.Simproc.Divisors
import Mathlib.Tactic.NormNum.Prime

open Nat

open ArithmeticFunction in
open scoped ArithmeticFunction.sigma in
theorem helper_sum_divisors (k : ℕ) (hp : (mersenne (k + 1)).Prime) :
    ∑ i ∈ (2 ^ k * mersenne (k + 1)).divisors, i = 2 * (2 ^ k * mersenne (k + 1)) := by
  have h2 : σ 1 (2 ^ k) = mersenne (k + 1) := by
    simp_rw [sigma_one_apply, mersenne, ← one_add_one_eq_two, ← geom_sum_mul_add 1 (k + 1)]
    norm_num
  rw [← mul_assoc, ← pow_succ', ← sigma_one_apply, mul_comm,
    isMultiplicative_sigma.map_mul_of_coprime ((Odd.coprime_two_right (by simp)).pow_right _),
    h2]
  simp [hp, sigma_one_apply]

#print axioms helper_sum_divisors

/-- Euclid's recipe. Double 1 along `k + 1` times to reach `2 ^ (k + 1)`, and take one off to get
the Mersenne number `mersenne (k + 1) = 2 ^ (k + 1) - 1`. If that Mersenne number is prime, then
it times the doubling just below, `2 ^ k`, is perfect: its proper divisors (every divisor except
the number itself) add back up to it. -/
theorem euclid_mersenne_prime_gives_perfect (k : ℕ) (hp : (mersenne (k + 1)).Prime) :
    Nat.Perfect (2 ^ k * mersenne (k + 1)) := by
  rw [Nat.perfect_iff_sum_divisors_eq_two_mul (by positivity)]
  exact helper_sum_divisors k hp

/-- Counting the number itself too: when the Mersenne number `2 ^ (k + 1) - 1` is prime, every
divisor of `2 ^ k * (2 ^ (k + 1) - 1)`, the number included, adds to exactly twice the number. -/
theorem sum_all_divisors_is_twice (k : ℕ) (hp : (mersenne (k + 1)).Prime) :
    ∑ i ∈ (2 ^ k * mersenne (k + 1)).divisors, i = 2 * (2 ^ k * mersenne (k + 1)) := by
  exact helper_sum_divisors k hp

/-- The count of doublings has to be prime too: if `2 ^ p - 1` is prime, then `p` is prime.
(Required, not sufficient: `p = 11` is prime but `2 ^ 11 - 1 = 2047 = 23 × 89` is not.) -/
theorem mersenne_prime_needs_prime_count (p : ℕ) (hp : (mersenne p).Prime) : p.Prime := by
  exact Nat.Prime.of_mersenne hp

-- 28 = 1 + 2 + 4 + 7 + 14: its proper divisors, and they add back to 28.
example : Nat.properDivisors 28 = {1, 2, 4, 7, 14} := by decide
example : ∑ i ∈ Nat.properDivisors 28, i = 28 := by decide
-- Counting 28 itself: every divisor adds to 56, twice 28.
example : ∑ i ∈ Nat.divisors 28, i = 56 := by decide
-- Step 0: the doubling run 1 + 2 + 4 is one short of 8.
example : 1 + 2 + 4 = 8 - 1 := by decide
-- Euclid's two brackets for 28.
example : (1 + 2 + 4) * (1 + 7) = 56 ∧ 56 = 2 * 28 := by decide
-- The recipe on the first four Mersenne primes: 2 × 3, 4 × 7, 16 × 31, 64 × 127.
example : mersenne 2 = 3 ∧ mersenne 3 = 7 ∧ mersenne 5 = 31 ∧ mersenne 7 = 127 := by
  simp [mersenne]
example : (3 : ℕ).Prime ∧ (7 : ℕ).Prime ∧ (31 : ℕ).Prime ∧ (127 : ℕ).Prime := by norm_num
example : 2 * 3 = 6 ∧ 4 * 7 = 28 ∧ 16 * 31 = 496 ∧ 64 * 127 = 8128 := by decide
example : Nat.Perfect 6 := by decide
example : Nat.Perfect 28 := by decide
example : Nat.Perfect 496 := by decide
example : Nat.Perfect 8128 := by
  rw [Nat.perfect_iff_sum_properDivisors (by norm_num)]
  simp [Nat.properDivisors_ofNat]
-- Eleven doublings: 11 is prime, but 2047 = 23 × 89 is not, and 1024 × 2047 = 2096128.
example : mersenne 11 = 2047 ∧ 2047 = 23 * 89 ∧ 1024 * 2047 = 2096128 := by
  simp [mersenne]
example : (11 : ℕ).Prime ∧ ¬ (2047 : ℕ).Prime := by norm_num
-- Six doublings: 2 ^ 6 - 1 = 63, and 7 goes into it.
example : mersenne 6 = 63 ∧ 7 ∣ 63 := by
  simp [mersenne]

#print axioms euclid_mersenne_prime_gives_perfect
#print axioms sum_all_divisors_is_twice
#print axioms mersenne_prime_needs_prime_count
