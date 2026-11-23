-- Fermat's last theorem, proved in 1995 and reported formalised in 2026: this file proves that exponent 4 and the odd prime exponents together cover every exponent of at least 3.
import Mathlib.NumberTheory.FLT.Basic
import Mathlib.Data.Nat.Factors
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

/-- The card's reduction: if exponent 4 has no solution and no odd prime exponent has one,
then no exponent of 3 or more has one. In Mathlib's terms, `FermatLastTheoremFor 4` and
`FermatLastTheoremFor p` for every odd prime `p` give `FermatLastTheorem`. -/
theorem fermat_last_theorem_of_four_and_odd_primes
    (h4 : FermatLastTheoremFor 4)
    (hp : ∀ p : ℕ, p.Prime → Odd p → FermatLastTheoremFor p) :
    FermatLastTheorem := by
  intro n hn
  rcases Nat.four_dvd_or_exists_odd_prime_and_dvd_of_two_lt (by omega : 2 < n) with
    h | ⟨p, hpp, hpd, hpo⟩
  · exact FermatLastTheoremFor.mono h h4
  · exact FermatLastTheoremFor.mono hpd (hp p hpp hpo)

/-- A solution with exponent `d * m` gives one with exponent `m`, since
`a ^ (d * m) = (a ^ d) ^ m`; so no solution with exponent `m` means none with exponent `d * m`. -/
theorem fermat_last_theorem_for_mul (d m : ℕ) (hm : FermatLastTheoremFor m) :
    FermatLastTheoremFor (d * m) := by
  exact FermatLastTheoremFor.mono (Dvd.intro_left d rfl) hm

/-- Every exponent `n` of at least 3 is a multiple of 4 or has an odd prime factor. -/
theorem four_dvd_or_odd_prime_factor (n : ℕ) (hn : 3 ≤ n) :
    4 ∣ n ∨ ∃ p : ℕ, p.Prime ∧ Odd p ∧ p ∣ n := by
  rcases Nat.four_dvd_or_exists_odd_prime_and_dvd_of_two_lt (by omega : 2 < n) with h | ⟨p, hp, hd, ho⟩
  · exact Or.inl h
  · exact Or.inr ⟨p, hp, ho, hd⟩

-- Squares can add up to a square.
example : 3 ^ 2 + 4 ^ 2 = 5 ^ 2 := by norm_num

-- Drop a ≠ 0 and the statement is false: 0^3 + 1^3 = 1^3.
example : 0 ^ 3 + 1 ^ 3 = 1 ^ 3 := by norm_num

-- The near miss: 1782^12 + 1841^12 is not 1922^12.
example : 1782 ^ 12 + 1841 ^ 12 ≠ 1922 ^ 12 := by norm_num

-- Parity settles it: the left side is odd, the right side even.
example : (1782 ^ 12 + 1841 ^ 12) % 2 = 1 ∧ 1922 ^ 12 % 2 = 0 := by norm_num

-- The second near miss: parity fails, mod 3 settles it (left 0, right 1).
example : (3987 ^ 12 + 4365 ^ 12) % 2 = 0 ∧ 4472 ^ 12 % 2 = 0 := by norm_num
example : (3987 ^ 12 + 4365 ^ 12) % 3 = 0 ∧ 4472 ^ 12 % 3 = 1 := by norm_num

-- The exponents from 3 to 1,000 with no odd prime factor are the 8 powers of 2 from 4 to 512.
example : ((Finset.range 10).filter (fun k => 3 ≤ 2 ^ k ∧ 2 ^ k ≤ 1000)).card = 8 := by decide

-- 37 is irregular: the sum of a^32 for a = 1 to 36 is divisible by 37^2 (so 37 divides the top of B_32).
example : (∑ a ∈ Finset.range 37, a ^ 32) % (37 ^ 2) = 0 := by decide

-- The arithmetic of the eleven days, whole parts.
example : 29511 / 11 = 2682 := by norm_num
example : 13400000 / 11 = 1218181 := by norm_num
example : 13400000 / 29511 = 454 := by norm_num
example : 1995 - 1637 = 358 ∧ 2026 - 1995 = 31 := by norm_num

#print axioms fermat_last_theorem_of_four_and_odd_primes
#print axioms fermat_last_theorem_for_mul
#print axioms four_dvd_or_odd_prime_factor
