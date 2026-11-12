-- Euclid's lemma: if a prime divides a product of two whole numbers and misses one of them, it divides the other, a prime that misses a number shares only 1 with it, and every composite divides some product while dividing neither factor.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.NormNum.GCD

/-- Euclid's lemma. Take a prime p and two whole numbers a and b. If p divides the product
a × b and p does not divide a, then p divides b: the prime is in the total, not in the first
factor, so it is in the second. -/
theorem prime_dividing_product_and_missing_one_factor_divides_the_other
    (p a b : ℕ) (hp : p.Prime) (hab : p ∣ a * b) (ha : ¬ p ∣ a) : p ∣ b := by
  exact ((Nat.Prime.dvd_mul hp).mp hab).resolve_left ha

/-- Step 0. A prime that does not divide a whole number shares nothing with it but 1:
their greatest common divisor is 1, so they are coprime. -/
theorem prime_missing_a_number_is_coprime_to_it
    (p a : ℕ) (hp : p.Prime) (ha : ¬ p ∣ a) : Nat.Coprime p a := by
  exact (Nat.Prime.coprime_iff_not_dvd hp).mpr ha

/-- Composites carry no such promise. Every composite n (above 1 and not prime) splits its
factors across two whole numbers: there are a and b with n dividing a × b while n divides
neither a nor b. -/
theorem composite_divides_a_product_but_neither_factor
    (n : ℕ) (h1 : 1 < n) (hn : ¬ n.Prime) :
    ∃ a b : ℕ, n ∣ a * b ∧ ¬ n ∣ a ∧ ¬ n ∣ b := by
  obtain ⟨m, hmn, hm2, hmlt⟩ := Nat.exists_dvd_of_not_prime2 (by omega) hn
  obtain ⟨k, hk⟩ := hmn
  have hkpos : 0 < k := by
    rcases Nat.eq_zero_or_pos k with h | h
    · subst h; omega
    · exact h
  have hk2 : 2 ≤ k := by
    by_contra hcon
    have : k = 1 := by omega
    subst this
    omega
  have hklt : k < n := by
    have : 2 * k ≤ m * k := Nat.mul_le_mul_right k hm2
    omega
  refine ⟨m, k, ⟨1, by rw [Nat.mul_one]; exact hk.symm⟩, ?_, ?_⟩
  · intro h
    exact absurd (Nat.le_of_dvd (by omega) h) (by omega)
  · intro h
    exact absurd (Nat.le_of_dvd (by omega) h) (by omega)

-- The office: 4 gifts of $21 make $84, and 7 is prime.
example : 4 * 21 = 84 := by decide
example : Nat.Prime 7 := by norm_num
-- 7 divides the total: 84 = 7 × 12.
example : 84 = 7 * 12 ∧ 7 ∣ 84 := by decide
-- 7 misses the gift count: 4 shared by 7 leaves 4.
example : 4 % 7 = 4 ∧ ¬ 7 ∣ 4 := by decide
-- So 7 and 4 share only 1.
example : Nat.gcd 7 4 = 1 := by norm_num
-- A mix landing on 1, and that line times 21.
example : (4 : ℤ) * 2 + 7 * (-1) = 1 := by decide
example : (84 : ℤ) * 2 + 147 * (-1) = 21 ∧ (84 : ℤ) = 4 * 21 ∧ (147 : ℤ) = 7 * 21 := by decide
-- Pull the 7 out: 84 × 2 = 7 × 24, 147 = 7 × 21, and 7 × (24 − 21) = 7 × 3 = 21.
example : 84 * 2 = 7 * 24 ∧ 7 * (24 - 21) = 7 * 3 ∧ 7 * 3 = 21 := by decide
-- The 7 is inside the gift: 21 shared by 7 leaves 0.
example : 21 % 7 = 0 ∧ 7 ∣ 21 := by decide
-- The composite 6 = 2 × 3 divides 36 = 4 × 9 but neither 4 nor 9.
example : ¬ Nat.Prime 6 := by norm_num
example : 6 = 2 * 3 ∧ 36 = 4 * 9 ∧ 6 ∣ 36 := by decide
example : 4 % 6 = 4 ∧ 9 % 6 = 3 ∧ ¬ 6 ∣ 4 ∧ ¬ 6 ∣ 9 := by decide
-- The 2 goes into the 4 and the 3 goes into the 9.
example : 2 ∣ 4 ∧ 3 ∣ 9 := by decide
-- 6 and 4 share the factor 2, so no mix of them lands on 1.
example : Nat.gcd 6 4 = 2 := by norm_num

#print axioms prime_dividing_product_and_missing_one_factor_divides_the_other
#print axioms prime_missing_a_number_is_coprime_to_it
#print axioms composite_divides_a_product_but_neither_factor
