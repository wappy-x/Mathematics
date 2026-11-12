-- There are infinitely many primes: the set of primes is infinite, because multiplying any finite list of primes and adding one gives a number with a prime factor the list does not hold.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Algebra.BigOperators.Group.Finset.Piecewise
import Mathlib.Algebra.BigOperators.GroupWithZero.Finset
import Mathlib.Data.Nat.Prime.Infinite
import Mathlib.Data.Set.Finite.Lattice

/-- There are infinitely many primes: no finite list holds them all, so the set of
prime numbers is infinite. -/
theorem set_of_primes_is_infinite : {p : ℕ | p.Prime}.Infinite := by
  exact fun h => Nat.not_bddAbove_setOfPred_prime h.bddAbove

/-- Euclid's machine. Take any finite list of primes, multiply them all together and add one.
That number has a prime factor, and every prime factor of it is a prime the list did not have. -/
theorem euclid_number_prime_factors_are_new (S : Finset ℕ) (hS : ∀ p ∈ S, p.Prime) :
    (∃ q : ℕ, q.Prime ∧ q ∣ (∏ p ∈ S, p) + 1) ∧
      ∀ q : ℕ, q.Prime → q ∣ (∏ p ∈ S, p) + 1 → q ∉ S := by
  have hne : (∏ p ∈ S, p) + 1 ≠ 1 := by
    have : 0 < ∏ p ∈ S, p := Nat.pos_of_ne_zero (Finset.prod_ne_zero_iff.mpr (fun p hp => (hS p hp).ne_zero))
    omega
  refine ⟨⟨Nat.minFac ((∏ p ∈ S, p) + 1), Nat.minFac_prime hne, Nat.minFac_dvd _⟩, ?_⟩
  intro q hq hqd hqS
  have h1 : q ∣ ∏ p ∈ S, p := Finset.dvd_prod_of_mem _ hqS
  have h2 : q ∣ 1 := (Nat.dvd_add_right h1).mp hqd
  exact hq.one_lt.ne' (Nat.dvd_one.mp h2)

/-- Every prime on the list divides the product exactly, so each one leaves remainder 1
when it divides the product plus one. -/
theorem euclid_number_leaves_remainder_one (S : Finset ℕ) (hS : ∀ p ∈ S, p.Prime) :
    ∀ p ∈ S, ((∏ q ∈ S, q) + 1) % p = 1 := by
  intro p hp
  have h1 : p ∣ ∏ q ∈ S, q := Finset.dvd_prod_of_mem _ hp
  have h2 := (hS p hp).one_lt
  obtain ⟨k, hk⟩ := h1
  rw [hk, Nat.mul_add_mod]
  exact Nat.mod_eq_of_lt h2

-- The card's list: multiply the first six primes, then add one.
example : 2 * 3 * 5 * 7 * 11 * 13 = 30030 ∧ 30030 + 1 = 30031 := by norm_num
example : (∏ p ∈ ({2, 3, 5, 7, 11, 13} : Finset ℕ), p) = 30030 := by decide
example : ∀ p ∈ ({2, 3, 5, 7, 11, 13} : Finset ℕ), p.Prime := by decide
-- Each listed prime leaves remainder 1 on 30031.
example : 30031 % 2 = 1 ∧ 30031 % 3 = 1 ∧ 30031 % 5 = 1 ∧ 30031 % 7 = 1 ∧
    30031 % 11 = 1 ∧ 30031 % 13 = 1 := by decide
-- 30031 is not prime: it splits as 59 × 509, its smallest prime factor is 59.
example : 59 * 509 = 30031 ∧ 30031 / 59 = 509 := by norm_num
example : Nat.minFac 30031 = 59 ∧ ¬ Nat.Prime 30031 := by norm_num
-- Both factors are prime, and neither was on the list.
example : Nat.Prime 59 ∧ Nat.Prime 509 ∧ Nat.minFac 509 = 509 := by norm_num
example : (59 : ℕ) ∉ ({2, 3, 5, 7, 11, 13} : Finset ℕ) ∧
    (509 : ℕ) ∉ ({2, 3, 5, 7, 11, 13} : Finset ℕ) := by decide
-- Dropped pieces: without the plus one, 30030's smallest prime factor is 2, already listed;
-- adding one to 13 alone gives 14 = 2 × 7, both already listed.
example : Nat.minFac 30030 = 2 ∧ 13 + 1 = 14 ∧ Nat.minFac 14 = 2 ∧ 14 = 2 * 7 := by norm_num
-- New, not big: from the list 5, 7 the machine gives 36 = 2 × 2 × 3 × 3.
example : 5 * 7 + 1 = 36 ∧ 36 = 2 * 2 * 3 * 3 := by norm_num

#print axioms set_of_primes_is_infinite
#print axioms euclid_number_prime_factors_are_new
#print axioms euclid_number_leaves_remainder_one
