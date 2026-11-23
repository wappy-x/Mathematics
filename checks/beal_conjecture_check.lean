-- Beal's conjecture: this file states the conjecture, proves that its equal-exponent case says exactly the same as Fermat's last theorem, proves the shared-factor family and the two-bases-share-a-prime rule, and checks the card's whole-number examples.
import Mathlib.NumberTheory.FLT.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.NormNum.GCD

/-- Beal's conjecture (open as of 2026-11-23; nothing here proves it): if A^x + B^y = C^z
with A, B, C positive whole numbers and all three exponents x, y, z at least 3, then the
three bases share a prime factor, that is gcd(A, B, C) > 1. -/
def BealConjecture : Prop :=
  ∀ A B C x y z : ℕ, 0 < A → 0 < B → 0 < C → 3 ≤ x → 3 ≤ y → 3 ≤ z →
    A ^ x + B ^ y = C ^ z → 1 < Nat.gcd (Nat.gcd A B) C

/-- Equal exponents give exactly Fermat's last theorem: Beal's conjecture with all three
exponents equal to one n of 3 or more (if A^n + B^n = C^n with A, B, C positive, then
gcd(A, B, C) > 1) holds if and only if Fermat's last theorem holds. -/
theorem beal_equal_exponents_iff_fermat :
    (∀ A B C n : ℕ, 0 < A → 0 < B → 0 < C → 3 ≤ n →
      A ^ n + B ^ n = C ^ n → 1 < Nat.gcd (Nat.gcd A B) C) ↔ FermatLastTheorem := by
  constructor
  · intro H n hn a b c ha hb hc habc
    have ha' : 0 < a := Nat.pos_of_ne_zero ha
    have hb' : 0 < b := Nat.pos_of_ne_zero hb
    have hc' : 0 < c := Nat.pos_of_ne_zero hc
    set d := Nat.gcd (Nat.gcd a b) c with hd
    have hdpos : 0 < d := Nat.gcd_pos_of_pos_right _ hc'
    have hda : d ∣ a := (Nat.gcd_dvd_left _ _).trans (Nat.gcd_dvd_left _ _)
    have hdb : d ∣ b := (Nat.gcd_dvd_left _ _).trans (Nat.gcd_dvd_right _ _)
    have hdc : d ∣ c := Nat.gcd_dvd_right _ _
    obtain ⟨a', ha2⟩ := hda
    obtain ⟨b', hb2⟩ := hdb
    obtain ⟨c', hc2⟩ := hdc
    have hdn : 0 < d ^ n := pow_pos hdpos n
    have key : a' ^ n + b' ^ n = c' ^ n := by
      have : d ^ n * (a' ^ n + b' ^ n) = d ^ n * c' ^ n := by
        rw [mul_add, ← mul_pow, ← mul_pow, ← mul_pow, ← ha2, ← hb2, ← hc2]; exact habc
      exact Nat.eq_of_mul_eq_mul_left hdn this
    have hg : Nat.gcd (Nat.gcd a' b') c' = 1 := by
      have h1 : d * Nat.gcd (Nat.gcd a' b') c' = d * 1 := by
        rw [mul_one, ← Nat.gcd_mul_left, ← Nat.gcd_mul_left, ← ha2, ← hb2, ← hc2]
      exact Nat.eq_of_mul_eq_mul_left hdpos h1
    have hpos : ∀ u, 0 < d * u → 0 < u := fun u hu => Nat.pos_of_mul_pos_left hu
    have := H a' b' c' n (hpos _ (ha2 ▸ ha')) (hpos _ (hb2 ▸ hb')) (hpos _ (hc2 ▸ hc')) hn key
    omega
  · intro hF A B C n hA hB hC hn h
    exact absurd h (hF n hn A B C hA.ne' hB.ne' hC.ne')

/-- Shared-factor solutions are endless: for any positive seeds a, b and any exponent m,
with s = a^m + b^m, the identity (a s)^m + (b s)^m = s^(m+1) holds, and the three bases
a s, b s and s have a common factor greater than 1. -/
theorem shared_factor_family (a b m : ℕ) (ha : 0 < a) (hb : 0 < b) :
    (a * (a ^ m + b ^ m)) ^ m + (b * (a ^ m + b ^ m)) ^ m = (a ^ m + b ^ m) ^ (m + 1) ∧
      1 < Nat.gcd (Nat.gcd (a * (a ^ m + b ^ m)) (b * (a ^ m + b ^ m))) (a ^ m + b ^ m) := by
  have hs : 1 < a ^ m + b ^ m := by
    have := Nat.one_le_pow m a ha
    have := Nat.one_le_pow m b hb
    omega
  refine ⟨by rw [mul_pow, mul_pow, pow_succ]; ring, ?_⟩
  rw [Nat.gcd_eq_right (Nat.dvd_gcd (Dvd.intro_left _ rfl) (Dvd.intro_left _ rfl))]
  exact hs

/-- A prime in two bases is in all three: if A^x + B^y = C^z with x and y positive, then
A and B are coprime exactly when A, B and C have no common factor, gcd(A, B, C) = 1. -/
theorem coprime_two_iff_coprime_three (A B C x y z : ℕ) (hx : 0 < x) (hy : 0 < y)
    (h : A ^ x + B ^ y = C ^ z) :
    Nat.Coprime A B ↔ Nat.gcd (Nat.gcd A B) C = 1 := by
  constructor
  · intro hAB
    rw [Nat.Coprime] at hAB
    rw [hAB, Nat.gcd_one_left]
  · intro hg
    have hdA : Nat.gcd A B ∣ A ^ x := (Nat.gcd_dvd_left A B).trans (dvd_pow_self A hx.ne')
    have hdB : Nat.gcd A B ∣ B ^ y := (Nat.gcd_dvd_right A B).trans (dvd_pow_self B hy.ne')
    have hdC : Nat.gcd A B ∣ C ^ z := h ▸ Nat.dvd_add hdA hdB
    have hcop : Nat.Coprime (Nat.gcd A B) (C ^ z) := Nat.Coprime.pow_right z hg
    exact Nat.Coprime.eq_one_of_dvd hcop hdC

-- The card's example: 3^3 + 6^3 = 3^5, that is 27 + 216 = 243, with gcd(3, 6, 3) = 3
-- and gcd(27, 216, 243) = 27.
example : 3 ^ 3 + 6 ^ 3 = 3 ^ 5 ∧ 27 + 216 = 243 ∧
    Nat.gcd (Nat.gcd 3 6) 3 = 3 ∧ Nat.gcd (Nat.gcd 27 216) 243 = 27 := by norm_num
-- Dividing by 3^3 leaves 1 + 2^3 = 3^2: the last exponent falls from 5 to 2.
example : 3 ^ 3 / 3 ^ 3 + 6 ^ 3 / 3 ^ 3 = 3 ^ 5 / 3 ^ 3 ∧ 1 + 2 ^ 3 = 3 ^ 2 := by norm_num
-- Family 1, k = 1 to 4: (3^k)^3 + (2 * 3^k)^3 = 3^(3k+2); k = 2 is 9^3 + 18^3 = 3^8 = 6,561.
example : (3 ^ 1) ^ 3 + (2 * 3 ^ 1) ^ 3 = 3 ^ 5 ∧ (3 ^ 2) ^ 3 + (2 * 3 ^ 2) ^ 3 = 3 ^ 8 ∧
    (3 ^ 3) ^ 3 + (2 * 3 ^ 3) ^ 3 = 3 ^ 11 ∧ (3 ^ 4) ^ 3 + (2 * 3 ^ 4) ^ 3 = 3 ^ 14 ∧
    9 ^ 3 + 18 ^ 3 = 6561 ∧ 3 ^ 8 = 6561 := by norm_num
-- Family 2 with a = 1, b = 2, m = 3: s = 9 and 9^3 + 18^3 = 9^4.
example : 1 ^ 3 + 2 ^ 3 = 9 ∧ 9 ^ 3 + 18 ^ 3 = 9 ^ 4 := by norm_num
-- Exponent 2 must be excluded: 2^5 + 7^2 = 3^4 = 81 with gcd 1, and 3^2 + 4^2 = 5^2.
example : 2 ^ 5 + 7 ^ 2 = 3 ^ 4 ∧ 3 ^ 4 = 81 ∧ Nat.gcd (Nat.gcd 2 7) 3 = 1 ∧
    3 ^ 2 + 4 ^ 2 = 5 ^ 2 ∧ Nat.gcd (Nat.gcd 3 4) 5 = 1 := by norm_num
-- The ten coprime solutions with an exponent 2 listed in 1997, each with gcd(A, B) = 1.
example : 1 ^ 7 + 2 ^ 3 = 3 ^ 2 ∧ 2 ^ 5 + 7 ^ 2 = 3 ^ 4 ∧ 7 ^ 3 + 13 ^ 2 = 2 ^ 9 ∧
    2 ^ 7 + 17 ^ 3 = 71 ^ 2 ∧ 3 ^ 5 + 11 ^ 4 = 122 ^ 2 ∧
    17 ^ 7 + 76271 ^ 3 = 21063928 ^ 2 ∧ 1414 ^ 3 + 2213459 ^ 2 = 65 ^ 7 ∧
    9262 ^ 3 + 15312283 ^ 2 = 113 ^ 7 ∧ 43 ^ 8 + 96222 ^ 3 = 30042907 ^ 2 ∧
    33 ^ 8 + 1549034 ^ 2 = 15613 ^ 3 := by norm_num
example : Nat.Coprime 1 2 ∧ Nat.Coprime 2 7 ∧ Nat.Coprime 7 13 ∧ Nat.Coprime 2 17 ∧
    Nat.Coprime 3 11 ∧ Nat.Coprime 17 76271 ∧ Nat.Coprime 1414 2213459 ∧
    Nat.Coprime 9262 15312283 ∧ Nat.Coprime 43 96222 ∧ Nat.Coprime 33 1549034 := by
  norm_num [Nat.coprime_iff_gcd_eq_one]
-- Their sums, as in the card's table.
example : 3 ^ 2 = 9 ∧ 3 ^ 4 = 81 ∧ 2 ^ 9 = 512 ∧ 71 ^ 2 = 5041 ∧ 122 ^ 2 = 14884 ∧
    21063928 ^ 2 = 443689062789184 ∧ 65 ^ 7 = 4902227890625 ∧
    113 ^ 7 = 235260548044817 ∧ 30042907 ^ 2 = 902576261010649 ∧
    15613 ^ 3 = 3805914951397 := by norm_num
-- The exponent sums: 1/3 + 1/3 + 1/3 = 1 and 1/3 + 1/3 + 1/4 = 11/12, in whole numbers.
example : 3 * 3 + 3 * 3 + 3 * 3 = 3 * 3 * 3 ∧ 3 * 4 + 3 * 4 + 3 * 3 = 11 * 3 := by norm_num

#print axioms beal_equal_exponents_iff_fermat
#print axioms shared_factor_family
#print axioms coprime_two_iff_coprime_three
