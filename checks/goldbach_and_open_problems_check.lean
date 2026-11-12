-- Goldbach, twin primes and friends: one even number from 4 up with no pair of primes would disprove Goldbach's claim, two primes always add to at least 4, an odd total needs 2 as one of its primes, and the card's pair counts for 4, 98, 100, 102, 11 and 2 are exact.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum.Prime

/-- One miss settles it: Goldbach's claim ("every even number from 4 up is two primes
added together") is false exactly when there is an even number from 4 up that is not
two primes added together. The claim itself is open; this is what a counterexample means. -/
theorem goldbach_false_iff_one_miss :
    (¬ ∀ n : ℕ, Even n → 4 ≤ n → ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p + q = n) ↔
      ∃ n : ℕ, Even n ∧ 4 ≤ n ∧ ∀ p q : ℕ, p.Prime → q.Prime → p + q ≠ n := by
  constructor
  · intro h
    push_neg at h
    obtain ⟨n, h1, h2, h3⟩ := h
    exact ⟨n, h1, h2, h3⟩
  · rintro ⟨n, h1, h2, h3⟩ h
    obtain ⟨p, q, hp, hq, hpq⟩ := h n h1 h2
    exact h3 p q hp hq hpq

/-- Why the claim starts at 4: any two primes added together come to at least 4,
so 2 (and 3) have no pair. -/
theorem two_primes_sum_at_least_four {p q : ℕ} (hp : p.Prime) (hq : q.Prime) :
    4 ≤ p + q := by
  have := hp.two_le
  have := hq.two_le
  omega

/-- Why "even" matters: if two primes add to an odd number, one of them is 2.
So 11 would need 2 + 9, and 9 is not prime. -/
theorem odd_sum_of_two_primes_uses_two {p q : ℕ} (hp : p.Prime) (hq : q.Prime)
    (hodd : Odd (p + q)) : p = 2 ∨ q = 2 := by
  obtain ⟨k, hk⟩ := hodd
  rcases hp.eq_two_or_odd with h | h
  · exact Or.inl h
  · rcases hq.eq_two_or_odd with h' | h'
    · exact Or.inr h'
    · omega

/-! The card's numbers. `pairs n` lists the smaller prime of each pair p + q = n,
each pair counted once, smaller first. `orderedPairs n` counts 3 + 97 and 97 + 3 as two. -/

def pairs (n : ℕ) : Finset ℕ :=
  (Finset.Icc 2 (n / 2)).filter (fun p => p.Prime ∧ (n - p).Prime)

def orderedPairs (n : ℕ) : Finset ℕ :=
  (Finset.Icc 2 n).filter (fun p => p.Prime ∧ (n - p).Prime)

-- 100 = 3 + 97 = 11 + 89 = 17 + 83 = 29 + 71 = 41 + 59 = 47 + 53, six ways.
example : pairs 100 = {3, 11, 17, 29, 41, 47} := by decide
example : (pairs 100).card = 6 := by decide
example : 3 + 97 = 100 ∧ 11 + 89 = 100 ∧ 17 + 83 = 100 ∧ 29 + 71 = 100 ∧
    41 + 59 = 100 ∧ 47 + 53 = 100 := by decide
-- 5 is tried and fails: 95 = 5 x 19.
example : 100 - 5 = 95 ∧ 95 = 5 * 19 ∧ ¬ (95 : ℕ).Prime := by norm_num
-- The neighbours: 4 has 1 way (2 + 2), 98 has 3, 102 has 8.
example : pairs 4 = {2} := by decide
example : (pairs 98).card = 3 := by decide
example : (pairs 102).card = 8 := by decide
-- The three mistakes: ordered pairs of 100 come to 12, 11 has 0 ways, 2 has 0 ways.
example : (orderedPairs 100).card = 12 := by decide
example : (pairs 11).card = 0 := by decide
example : (pairs 2).card = 0 := by decide
-- Twin primes just above 100: 101 and 103, two apart and both prime.
example : (101 : ℕ).Prime ∧ (103 : ℕ).Prime := by norm_num
example : 101 + 2 = 103 := by decide

#print axioms goldbach_false_iff_one_miss
#print axioms two_primes_sum_at_least_four
#print axioms odd_sum_of_two_primes_uses_two
