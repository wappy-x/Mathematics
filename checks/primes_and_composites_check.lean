-- Primes and composites: a whole number bigger than 1 is prime exactly when nothing but 1 and itself divides it, and exactly when no trial divisor d from 2 up, with d × d at or below the number, goes in; a number is prime exactly when it has two divisors, and 2 is the only even prime.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.NumberTheory.Divisors
import Mathlib.Tactic.NormNum.Prime

/-- The definition and the stop rule. Take a whole number n bigger than 1. It is prime exactly when
nothing divides it but 1 and itself. And you can find out by trial division: it is prime exactly
when no trial divisor d = 2, 3, 4, ... goes in with nothing left over, where you only try d while
d × d is at or below n. -/
theorem prime_iff_no_trial_divisor_up_to_the_stop (n : ℕ) (hn : 1 < n) :
    (Nat.Prime n ↔ ∀ d : ℕ, d ∣ n → d = 1 ∨ d = n) ∧
      (Nat.Prime n ↔ ∀ d : ℕ, 2 ≤ d → d * d ≤ n → n % d ≠ 0) := by
  have h2 : Nat.Prime n ↔ ∀ d : ℕ, d ∣ n → d = 1 ∨ d = n := by
    rw [Nat.prime_def]
    exact ⟨fun h => h.2, fun h => ⟨hn, h⟩⟩
  refine ⟨h2, ?_⟩
  rw [Nat.prime_def_le_sqrt]
  constructor
  · rintro ⟨_, h⟩ d hd hdd hmod
    exact h d hd (Nat.le_sqrt.2 hdd) (Nat.dvd_of_mod_eq_zero hmod)
  · intro h
    refine ⟨hn, fun m hm hms hdvd => ?_⟩
    exact h m hm (Nat.le_sqrt.1 hms) (Nat.mod_eq_zero_of_dvd hdvd)

/-- The second road, and the bar chart. A whole number is prime exactly when it has two divisors,
1 and itself. (1 has only one divisor, so it is not prime.) -/
theorem prime_iff_exactly_two_divisors (n : ℕ) :
    Nat.Prime n ↔ n.divisors.card = 2 := by
  constructor
  · intro h
    rw [Nat.Prime.divisors h]
    have : 1 ≠ n := h.one_lt.ne
    simp [Finset.card_pair this]
  · intro h
    have hn0 : n ≠ 0 := by
      rintro rfl
      simp at h
    have hn1 : n ≠ 1 := by
      rintro rfl
      simp at h
    rw [Nat.prime_def]
    refine ⟨by omega, fun d hd => ?_⟩
    have h1 : (1 : ℕ) ∈ n.divisors := Nat.mem_divisors.2 ⟨one_dvd n, hn0⟩
    have hn : n ∈ n.divisors := Nat.mem_divisors.2 ⟨dvd_refl n, hn0⟩
    have hdm : d ∈ n.divisors := Nat.mem_divisors.2 ⟨hd, hn0⟩
    obtain ⟨a, b, hab, hs⟩ := Finset.card_eq_two.1 h
    rw [hs] at h1 hn hdm
    simp only [Finset.mem_insert, Finset.mem_singleton] at h1 hn hdm
    omega

/-- 2 is prime, and it is the only even prime: a prime number is even exactly when it is 2. -/
theorem two_is_the_only_even_prime (p : ℕ) :
    Nat.Prime p ∧ Even p ↔ p = 2 := by
  constructor
  · rintro ⟨hp, he⟩
    exact (hp.even_iff).1 he
  · rintro rfl
    exact ⟨Nat.prime_two, even_two⟩

-- 97 in rows of 2 to 9: leftovers 1, 1, 1, 2, 1, 6, 1, 7.
example : (List.range' 2 8).map (97 % ·) = [1, 1, 1, 2, 1, 6, 1, 7] := by decide
-- The stop: 9 × 9 = 81 is under 97, 10 × 10 = 100 is past it.
example : 9 * 9 = 81 ∧ 81 < 97 ∧ 10 * 10 = 100 ∧ 97 < 100 := by decide
-- 97 is prime.
example : Nat.Prime 97 := by norm_num
-- 91 in rows of 2 to 7: leftovers 1, 1, 3, 1, 1, then 0.
example : (List.range' 2 6).map (91 % ·) = [1, 1, 3, 1, 1, 0] := by decide
-- 91 = 7 × 13, so 91 is composite.
example : 91 = 7 * 13 ∧ ¬ Nat.Prime 91 := by norm_num
-- The divisors: 97 has 1 and 97; 91 has 1, 7, 13, 91.
example : Nat.divisors 97 = {1, 97} ∧ Nat.divisors 91 = {1, 7, 13, 91} := by decide
-- The bar chart: how many divisors, 91 to 100.
example : (List.range' 91 10).map (fun n => (Nat.divisors n).card) = [4, 6, 4, 4, 4, 12, 2, 6, 6, 9] := by
  decide
-- 1 has one divisor, so it is neither prime nor composite.
example : (Nat.divisors 1).card = 1 ∧ ¬ Nat.Prime 1 := by decide
-- 25 primes below 100; counting 1 as prime gives 26.
example : ((Finset.range 100).filter Nat.Prime).card = 25 := by decide
example : ((Finset.range 100).filter (fun n => n = 1 ∨ Nat.Prime n)).card = 26 := by decide
-- Stopping the trials at 5: 49, 77 and 91 slip through, so 28 pass as prime.
example : ((Finset.range 100).filter
      (fun n => 2 ≤ n ∧ ¬ Nat.Prime n ∧ n % 2 ≠ 0 ∧ n % 3 ≠ 0 ∧ n % 4 ≠ 0 ∧ n % 5 ≠ 0)) =
      {49, 77, 91} := by
  decide
example : ((Finset.range 100).filter
      (fun n => 2 ≤ n ∧ ∀ d ∈ Finset.Icc 2 5, d < n → n % d ≠ 0)).card = 28 := by
  decide
-- 49 odd numbers above 1 and below 100; only 25 primes.
example : ((Finset.range 100).filter (fun n => 1 < n ∧ n % 2 = 1)).card = 49 := by decide

#print axioms prime_iff_no_trial_divisor_up_to_the_stop
#print axioms prime_iff_exactly_two_divisors
#print axioms two_is_the_only_even_prime
