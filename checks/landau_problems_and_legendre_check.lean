-- Landau's four problems: a table of prime gaps proves Legendre's conjecture for every n it reaches, since a prime-free interval between n squared and (n + 1) squared forces a gap of at least 2n + 3, and an odd prime divides some n squared plus one exactly when it leaves remainder 1 on division by 4.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.IntervalCases

/-- Helper: the square of a positive whole number is never prime. -/
theorem sq_not_prime_of_one_le (k : ℕ) (hk : 1 ≤ k) : ¬ (k ^ 2).Prime := by
  intro hpk
  rw [sq] at hpk
  rcases Nat.prime_mul_iff.mp hpk with ⟨h, rfl⟩ | ⟨h, rfl⟩ <;> exact Nat.not_prime_one h

/-- The card's proved claim (Step 3, the gap argument). Let `n ≥ 1`. Suppose that after
every prime p below a limit `L` the next prime comes within `g`: some prime q has
`p < q ≤ p + g`. If the limit reaches `(n + 1)^2` and `g < 2n + 3`, then Legendre's
conjecture holds at n: some prime lies strictly between `n^2` and `(n + 1)^2`.
(Below a million `g = 114`, which clears every n from 56 up; below `4 × 10^18`
`g = 1476`, which clears every n from 737 up to `n + 1 = 2 × 10^9`.) -/
theorem legendre_of_prime_gaps_lt_two_n_add_three (L g n : ℕ) (hn : 1 ≤ n)
    (hgap : ∀ p : ℕ, p.Prime → p < L → ∃ q : ℕ, q.Prime ∧ p < q ∧ q ≤ p + g)
    (hL : (n + 1) ^ 2 ≤ L) (hg : g < 2 * n + 3) :
    ∃ p : ℕ, p.Prime ∧ n ^ 2 < p ∧ p < (n + 1) ^ 2 := by
  -- n = 1: the prime 2 lies between 1 and 4.
  rcases Nat.lt_or_ge n 2 with h1 | h2
  · obtain rfl : n = 1 := by omega
    exact ⟨2, Nat.prime_two, by norm_num, by norm_num⟩
  by_contra hcon
  push Not at hcon
  have hnone : ∀ m : ℕ, n ^ 2 < m → m < (n + 1) ^ 2 → ¬ m.Prime :=
    fun m h1 h2 hm => absurd h2 (not_lt.mpr (hcon m hm h1))
  have h2le : 2 ≤ n ^ 2 := by nlinarith
  set p := Nat.findGreatest Nat.Prime (n ^ 2) with hpdef
  have hp : p.Prime := Nat.findGreatest_spec h2le Nat.prime_two
  have hpn : p ≤ n ^ 2 := Nat.findGreatest_le _
  have hpL : p < L := by
    have : n ^ 2 < (n + 1) ^ 2 := by nlinarith
    omega
  obtain ⟨q, hq, hpq, hqg⟩ := hgap p hp hpL
  have hqn : n ^ 2 < q := by
    by_contra hle
    push Not at hle
    have := Nat.le_findGreatest hle hq
    omega
  have hpne : p ≠ n ^ 2 := by
    intro h
    rw [h] at hp
    exact sq_not_prime_of_one_le n hn hp
  have hqge : (n + 1) ^ 2 ≤ q := hcon q hq hqn
  have hqne : q ≠ (n + 1) ^ 2 := by
    rintro rfl
    exact sq_not_prime_of_one_le (n + 1) (by omega) hq
  have hexp : (n + 1) ^ 2 = n ^ 2 + 2 * n + 1 := by ring
  omega

/-- Step 3, the key step: if `n ≥ 1` and no prime lies strictly between `n^2` and
`(n + 1)^2`, then any prime p at or below `n^2` and any prime q above `n^2` are at
least `2n + 3` apart, since p is at most `n^2 - 1` and q at least `(n + 1)^2 + 1`. -/
theorem prime_gap_ge_two_n_add_three_of_no_prime_between_squares (n : ℕ) (hn : 1 ≤ n)
    (hnone : ∀ m : ℕ, n ^ 2 < m → m < (n + 1) ^ 2 → ¬ m.Prime)
    (p q : ℕ) (hp : p.Prime) (hq : q.Prime) (hpn : p ≤ n ^ 2) (hqn : n ^ 2 < q) :
    2 * n + 3 ≤ q - p := by
  have hsq := sq_not_prime_of_one_le
  have hpne : p ≠ n ^ 2 := by
    rintro rfl
    exact hsq n hn hp
  have hqge : (n + 1) ^ 2 ≤ q := by
    by_contra hlt
    push Not at hlt
    exact hnone q hqn hlt hq
  have hqne : q ≠ (n + 1) ^ 2 := by
    rintro rfl
    exact hsq (n + 1) (by omega) hq
  have hexp : (n + 1) ^ 2 = n ^ 2 + 2 * n + 1 := by ring
  omega

/-- Step 4: an odd prime p divides `n^2 + 1` for some whole number n exactly when p
leaves remainder 1 on division by 4. So 3, 7, 11, 19 and every prime that leaves
remainder 3 never divide `n^2 + 1`. -/
theorem odd_prime_dvd_sq_add_one_iff_mod_four_eq_one (p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) :
    (∃ n : ℕ, p ∣ n ^ 2 + 1) ↔ p % 4 = 1 := by
  have := Fact.mk hp
  have hodd : p % 2 = 1 := hp.mod_two_eq_one_iff_ne_two.mpr hp2
  constructor
  · rintro ⟨n, hn⟩
    have h0 : ((n ^ 2 + 1 : ℕ) : ZMod p) = 0 := (ZMod.natCast_eq_zero_iff _ _).mpr hn
    have hsq : IsSquare (-1 : ZMod p) := by
      refine ⟨(n : ZMod p), ?_⟩
      push_cast at h0
      linear_combination -h0
    have := ZMod.exists_sq_eq_neg_one_iff.mp hsq
    omega
  · intro h
    obtain ⟨y, hy⟩ := (ZMod.exists_sq_eq_neg_one_iff (p := p)).mpr (by omega)
    refine ⟨y.val, ?_⟩
    rw [← ZMod.natCast_eq_zero_iff]
    push_cast
    rw [ZMod.natCast_zmod_val]
    linear_combination -hy

-- The card's worked whole-number examples.

-- The two squares: 961 = 31^2 and 1,024 = 32^2, with 62 whole numbers strictly between.
example : (31 : ℕ) ^ 2 = 961 ∧ (32 : ℕ) ^ 2 = 1024 ∧ 1023 - 962 + 1 = 62 := by norm_num
-- 962 to 966 are not prime: 963 = 3 × 321 and 965 = 5 × 193.
example : 963 = 3 * 321 ∧ 965 = 5 * 193 := by norm_num
example : ∀ m : ℕ, 961 < m → m < 967 → ¬ m.Prime := by
  intro m h1 h2
  interval_cases m <;> norm_num
-- 967 is prime, and leaves remainders 1, 1, 2, 1, 10, 5, 15, 17, 1, 10, 6 on division by
-- the primes 2 to 31.
example : Nat.Prime 967 := by norm_num
example : [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31].map (967 % ·) =
    [1, 1, 2, 1, 10, 5, 15, 17, 1, 10, 6] := by decide
-- The primes strictly between 961 and 1,024 are exactly these ten, from 967 to 1,021.
example : ∀ m : ℕ, 961 < m → m < 1024 →
    (m.Prime ↔ m ∈ [967, 971, 977, 983, 991, 997, 1009, 1013, 1019, 1021]) := by
  intro m h1 h2
  interval_cases m <;> norm_num
-- Legendre at n = 1: 2 and 3 lie between 1 and 4. At n = 0 nothing lies strictly
-- between 0 and 1.
example : Nat.Prime 2 ∧ Nat.Prime 3 ∧ 1 ^ 2 < 2 ∧ 3 < (1 + 1) ^ 2 := by norm_num
example : ∀ m : ℕ, 0 ^ 2 < m → m < (0 + 1) ^ 2 → False := by
  intro m h1 h2
  norm_num at h1 h2
  omega
-- The gap after 492,113 is 114, and 2n + 3 ≤ 114 exactly for n ≤ 55.
example : Nat.Prime 492113 ∧ Nat.Prime 492227 ∧ 492227 - 492113 = 114 := by norm_num
example : ∀ m : ℕ, 492113 < m → m < 492227 → ¬ m.Prime := by
  intro m h1 h2
  interval_cases m <;> norm_num
example : 2 * 55 + 3 ≤ 114 ∧ 114 < 2 * 56 + 3 := by norm_num
-- The record gap 1,476 below 4 × 10^18: 2n + 3 ≤ 1,476 exactly for n ≤ 736, and
-- (n + 1)^2 reaches 4 × 10^18 at n + 1 = 2,000,000,000.
example : 2 * 736 + 3 ≤ 1476 ∧ 1476 < 2 * 737 + 3 := by norm_num
example : (2000000000 : ℕ) ^ 2 = 4 * 10 ^ 18 := by norm_num
-- The windows x^0.525 and 2 x^0.5 cross at x = 2^40.
example : (2 : ℕ) ^ 40 = 1099511627776 := by norm_num
-- Goldbach: 11 - 2 = 9 is not prime; the hardest even number below a million,
-- 503,222, is 523 + 502,699.
example : ¬ Nat.Prime (11 - 2) := by norm_num
example : Nat.Prime 523 ∧ Nat.Prime 502699 ∧ 523 + 502699 = 503222 := by norm_num
-- n^2 + 1: 5 = 2^2 + 1 and 17 = 4^2 + 1 are prime; 5 divides n^2 + 1 for n = 2 and 3.
example : Nat.Prime (2 ^ 2 + 1) ∧ Nat.Prime (4 ^ 2 + 1) := by norm_num
example : 5 ∣ 2 ^ 2 + 1 ∧ 5 ∣ 3 ^ 2 + 1 := by norm_num

#print axioms sq_not_prime_of_one_le
#print axioms legendre_of_prime_gaps_lt_two_n_add_three
#print axioms prime_gap_ge_two_n_add_three_of_no_prime_between_squares
#print axioms odd_prime_dvd_sq_add_one_iff_mod_four_eq_one
