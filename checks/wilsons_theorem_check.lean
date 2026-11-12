-- Wilson's theorem: for a clock size n of at least 2, the product 1 × 2 × ... × (n - 1) reads -1 on the n-clock exactly when n is prime, every composite clock reads 0 except the 4-clock, which reads 2, and on a prime clock only 1 and -1 are their own partner.
import Mathlib.NumberTheory.Wilson
import Mathlib.Tactic.NormNum.Basic

open Nat

/-- Helper: for 0 < a < b, a * b divides b!. -/
theorem helper_mul_dvd_factorial (a b : ℕ) (ha : 0 < a) (hab : a < b) : a * b ∣ b ! := by
  obtain ⟨c, rfl⟩ : ∃ c, b = c + 1 := ⟨b - 1, by omega⟩
  have h : a ∣ c ! := Nat.dvd_factorial ha (by omega)
  rw [Nat.factorial_succ, mul_comm a]
  exact mul_dvd_mul_left _ h

/-- Helper: a composite n other than 4 divides (n - 1)!. -/
theorem helper_composite_dvd_factorial (n : ℕ) (hn : 2 ≤ n) (hnp : ¬ n.Prime) (h4 : n ≠ 4) :
    n ∣ (n - 1)! := by
  have hn1 : n ≠ 1 := by omega
  have hap : (n.minFac).Prime := Nat.minFac_prime hn1
  have ha2 : 2 ≤ n.minFac := hap.two_le
  have hab : n.minFac ≤ n / n.minFac := Nat.minFac_le_div (by omega) hnp
  obtain ⟨a, b, hab', ha2', hb, hn'⟩ : ∃ a b : ℕ, a ≤ b ∧ 2 ≤ a ∧ n = a * b ∧ True :=
    ⟨n.minFac, n / n.minFac, hab, ha2, (Nat.mul_div_cancel' (Nat.minFac_dvd n)).symm, trivial⟩
  have hbn : b < n := by rw [hb]; nlinarith
  rcases Nat.lt_or_ge a b with h | h
  · have h1 : a * b ∣ b ! := helper_mul_dvd_factorial a b (by omega) h
    have h2 : b ! ∣ (n - 1)! := Nat.factorial_dvd_factorial (by omega)
    rw [hb] at h2 ⊢
    exact h1.trans h2
  · have hba : b = a := le_antisymm h hab'
    rw [hba] at hb hbn
    have ha3 : 3 ≤ a := by
      by_contra hlt
      have : a = 2 := by omega
      apply h4; rw [hb, this]
    have h1 : a * (2 * a) ∣ (2 * a)! := helper_mul_dvd_factorial a (2 * a) (by omega) (by omega)
    have h5 : 2 * a + 1 ≤ n := by nlinarith
    have h2 : (2 * a)! ∣ (n - 1)! := Nat.factorial_dvd_factorial (by omega)
    have h3 : n ∣ a * (2 * a) := by rw [hb]; exact ⟨2, by ring⟩
    exact h3.trans (h1.trans h2)

#print axioms helper_mul_dvd_factorial
#print axioms helper_composite_dvd_factorial

/-- Wilson's theorem, both directions. Take a clock size n of at least 2. Multiply every number
from 1 up to n - 1 together, that is (n - 1)!. The n-clock reads -1 exactly when n is prime:
every prime clock reads -1, and no clock that is not prime ever does. -/
theorem prime_iff_product_below_reads_neg_one (n : ℕ) (hn : 2 ≤ n) :
    n.Prime ↔ (((n - 1)! : ℕ) : ZMod n) = -1 := by
  exact Nat.prime_iff_fac_equiv_neg_one (by omega)

/-- Backwards, every composite fails. On a clock size n of at least 2 that is not prime, the
product 1 × 2 × ... × (n - 1) reads 0, except on the 4-clock, where it reads 2. -/
theorem composite_clock_reads_zero_or_two (n : ℕ) (hn : 2 ≤ n) (hnp : ¬ n.Prime) :
    (((n - 1)! : ℕ) : ZMod n) = if n = 4 then 2 else 0 := by
  have h0 : n ≠ 1 := by omega
  by_cases h4 : n = 4
  · subst h4
    simp only [ite_true]
    decide
  · simp only [h4, ite_false]
    have := helper_composite_dvd_factorial n hn hnp h4
    exact (ZMod.natCast_eq_zero_iff _ _).mpr this

/-- Step 1: on a prime clock, the only numbers that are their own partner (times themselves
read 1) are 1 and the top hour p - 1, which is -1. -/
theorem own_partner_iff_one_or_neg_one (p : ℕ) (hp : p.Prime) (x : ZMod p) :
    x * x = 1 ↔ x = 1 ∨ x = -1 := by
  have := Fact.mk hp
  constructor
  · intro h
    have h' : (x - 1) * (x + 1) = 0 := by linear_combination h
    rcases mul_eq_zero.mp h' with h1 | h1
    · left; linear_combination h1
    · right; linear_combination h1
  · rintro (h | h) <;> subst h <;> ring

-- The row on the 7-clock: 1 × 2 × 3 × 4 × 5 × 6 = 720 = 102 × 7 + 6, and 6 - 7 = -1.
example : 1 * 2 * 3 * 4 * 5 * 6 = 720 ∧ 6 ! = 720 := by decide
example : 720 = 102 * 7 + 6 ∧ 720 % 7 = 6 := by decide
example : (6 : ℤ) - 7 = -1 := by norm_num
example : ((720 : ℕ) : ZMod 7) = -1 := by decide
-- Who undoes who on the 7-clock: 2 × 4 = 8 and 3 × 5 = 15 read 1; 1 × 1 = 1 and 6 × 6 = 36 read 1.
example : 2 * 4 = 8 ∧ 8 % 7 = 1 ∧ 3 * 5 = 15 ∧ 15 % 7 = 1 := by decide
example : 1 * 1 % 7 = 1 ∧ 6 * 6 = 36 ∧ 36 % 7 = 1 := by decide
-- The partner table: dancers 1 to 6 have partners 1, 4, 5, 2, 3, 6.
example : (1 * 1) % 7 = 1 ∧ (2 * 4) % 7 = 1 ∧ (3 * 5) % 7 = 1 ∧ (4 * 2) % 7 = 1 ∧
    (5 * 3) % 7 = 1 ∧ (6 * 6) % 7 = 1 := by decide
-- The pairing road: 1 × (2 × 4) × (3 × 5) × 6 reads 6.
example : (1 * (2 * 4) * (3 * 5) * 6) % 7 = 6 := by decide
-- Dancer 3: 3 × 3 - 1 = 8 = 2 × 4.
example : 3 * 3 - 1 = 8 ∧ 8 = 2 * 4 := by decide
-- An 8-clock: 7! = 5040 reads 0. A 4-clock: 3! = 6 reads 2.
example : 7 ! = 5040 ∧ 5040 % 8 = 0 := by decide
example : 3 ! = 6 ∧ 6 % 4 = 2 := by decide
-- A 9-clock: 3 × 6 = 18 is two whole clocks, and 8! reads 0.
example : 3 * 6 = 18 ∧ 18 = 2 * 9 ∧ 8 ! % 9 = 0 := by decide
-- A 5-clock: 1 × 2 × 3 × 4 = 24 is four clocks and 4 over, one short of 5.
example : 4 ! = 24 ∧ 24 = 4 * 5 + 4 ∧ ((24 : ℕ) : ZMod 5) = -1 := by decide
-- The numbers with an undo on an 8-clock (1, 3, 5, 7) and a 12-clock (1, 5, 7, 11) multiply to 1.
example : (1 * 3 * 5 * 7) % 8 = 1 ∧ (1 * 5 * 7 * 11) % 12 = 1 := by decide

#print axioms prime_iff_product_below_reads_neg_one
#print axioms composite_clock_reads_zero_or_two
#print axioms own_partner_iff_one_or_neg_one
