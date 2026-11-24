-- Quadratic reciprocity by counting dots: for two different odd primes p and q, "is p a square mod q?" and "is q a square mod p?" have the same answer exactly when the primes are not both 3 mod 4, because the dots below and above the diagonal of the (p-1)/2 by (q-1)/2 rectangle decide the two answers and together fill the rectangle.
import Mathlib.NumberTheory.LegendreSymbol.GaussEisensteinLemmas
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.Tactic.NormNum.LegendreSymbol
import Mathlib.Tactic.NormNum.Prime

instance fact_prime_5 : Fact (Nat.Prime 5) := ⟨by norm_num⟩
instance fact_prime_7 : Fact (Nat.Prime 7) := ⟨by norm_num⟩
instance fact_prime_11 : Fact (Nat.Prime 11) := ⟨by norm_num⟩
instance fact_prime_29 : Fact (Nat.Prime 29) := ⟨by norm_num⟩
instance fact_prime_43 : Fact (Nat.Prime 43) := ⟨by norm_num⟩

theorem Icc_eq_Ico_half (p : ℕ) (hp : p % 2 = 1) :
    Finset.Icc 1 ((p - 1) / 2) = Finset.Ico 1 (p / 2).succ := by
  have : (p - 1) / 2 = p / 2 := by omega
  rw [this, Nat.succ_eq_add_one, Finset.Ico_add_one_right_eq_Icc]

theorem odd_prime_mod_two (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) : p % 2 = 1 :=
  (Nat.Prime.mod_two_eq_one_iff_ne_two Fact.out).mpr hp

#print axioms Icc_eq_Ico_half
#print axioms odd_prime_mod_two

/-- **Quadratic reciprocity, the card's main claim.** For two different odd primes p and q,
"is p a square on the q-clock?" and "is q a square on the p-clock?" have the same answer
exactly when the two primes do not both leave 3 on division by 4.
In Mathlib, `legendreSym q p` is (p/q): 1 if p is a nonzero square mod q, -1 if not. -/
theorem same_answer_iff_not_both_three_mod_four (p q : ℕ) [Fact p.Prime] [Fact q.Prime]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q) :
    legendreSym q p = legendreSym p q ↔ ¬ (p % 4 = 3 ∧ q % 4 = 3) := by
  have hp2 := odd_prime_mod_two p hp
  have hq2 := odd_prime_mod_two q hq
  constructor
  · rintro h ⟨h3p, h3q⟩
    have h' := legendreSym.quadratic_reciprocity_three_mod_four h3p h3q
    have hne : legendreSym p q ≠ 0 := by
      rw [Ne, legendreSym.eq_zero_iff]
      exact_mod_cast ZMod.prime_ne_zero p q hpq
    apply hne
    linarith
  · intro h
    rcases (by omega : p % 4 = 1 ∨ q % 4 = 1) with h1 | h1
    · exact legendreSym.quadratic_reciprocity_one_mod_four h1 hq
    · exact (legendreSym.quadratic_reciprocity_one_mod_four h1 hp).symm

/-- **Step 1 and Step 2: whole clocks decide the answer.** For two different odd primes p and q,
with h = (p-1)/2, let W = ⌊q/p⌋ + ⌊2q/p⌋ + … + ⌊hq/p⌋, the number of dots below the diagonal.
Then (q/p) = (-1)^W: q is a square on the p-clock exactly when W is even. -/
theorem legendreSym_eq_neg_one_pow_dots_below (p q : ℕ) [Fact p.Prime] [Fact q.Prime]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q) :
    legendreSym p q = (-1) ^ (∑ x ∈ Finset.Icc 1 ((p - 1) / 2), x * q / p) := by
  rw [Icc_eq_Ico_half p (odd_prime_mod_two p hp)]
  exact_mod_cast ZMod.eisenstein_lemma hp (odd_prime_mod_two q hq) (ZMod.prime_ne_zero p q hpq)

/-- **Step 4: the dots fill the rectangle.** For two different odd primes p and q, with
h = (p-1)/2 and k = (q-1)/2, the dots below the diagonal, ⌊xq/p⌋ summed over x = 1 to h, and
the dots above it, ⌊yp/q⌋ summed over y = 1 to k, add to h × k; so the two signs multiply to
(-1)^(h × k): (p/q) × (q/p) = (-1)^(h × k). -/
theorem dots_fill_rectangle_and_signs_multiply (p q : ℕ) [Fact p.Prime] [Fact q.Prime]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q) :
    (∑ x ∈ Finset.Icc 1 ((p - 1) / 2), x * q / p) + (∑ y ∈ Finset.Icc 1 ((q - 1) / 2), y * p / q)
        = (p - 1) / 2 * ((q - 1) / 2) ∧
      legendreSym q p * legendreSym p q = (-1) ^ ((p - 1) / 2 * ((q - 1) / 2)) := by
  have hp2 := odd_prime_mod_two p hp
  have hq2 := odd_prime_mod_two q hq
  have ep : (p - 1) / 2 = p / 2 := by omega
  have eq' : (q - 1) / 2 = q / 2 := by omega
  refine ⟨?_, ?_⟩
  · rw [Icc_eq_Ico_half p hp2, Icc_eq_Ico_half q hq2, ep, eq']
    exact ZMod.sum_mul_div_add_sum_mul_div_eq_mul p q (ZMod.prime_ne_zero p q hpq)
  · rw [ep, eq']
    exact legendreSym.quadratic_reciprocity hp hq hpq

-- 5 and 7: below ⌊7/5⌋ + ⌊14/5⌋ = 1 + 2 = 3, above ⌊5/7⌋ + ⌊10/7⌋ + ⌊15/7⌋ = 0 + 1 + 2 = 3, total 6 = 2 × 3.
example : 7 / 5 + 14 / 5 = 3 ∧ 5 / 7 + 10 / 7 + 15 / 7 = 3 ∧ 3 + 3 = 2 * 3 := by decide
example : (∑ x ∈ Finset.Icc 1 2, x * 7 / 5) = 3 ∧ (∑ y ∈ Finset.Icc 1 3, y * 5 / 7) = 3 := by decide
-- (5/7) = -1 and (7/5) = -1: they agree.
example : legendreSym 7 5 = -1 ∧ legendreSym 5 7 = -1 := by norm_num
-- 3 and 7: below ⌊7/3⌋ = 2, above 0 + 0 + 1 = 1, total 3 = 1 × 3, odd.
example : (∑ x ∈ Finset.Icc 1 1, x * 7 / 3) = 2 ∧ (∑ y ∈ Finset.Icc 1 3, y * 3 / 7) = 1 := by decide
-- (3/7) = -1 but (7/3) = 1: they disagree.
example : legendreSym 7 3 = -1 ∧ legendreSym 3 7 = 1 := by norm_num
-- Is 29 a square on the 43-clock? Flip counts 14 × 21 = 294, 5 × 14 = 70, 3 × 5 = 15; 275 = 9 × 29 + 14 = 25 × 11.
example : 14 * 21 = 294 ∧ 5 * 14 = 70 ∧ 3 * 5 = 15 ∧ 275 = 9 * 29 + 14 ∧ 275 = 25 * 11 := by norm_num
example : 43 % 29 = 14 ∧ 29 % 11 = 7 ∧ 11 % 7 = 4 := by norm_num
example : legendreSym 7 11 = 1 ∧ legendreSym 11 7 = -1 ∧ legendreSym 43 29 = -1 := by norm_num
-- Mistakes: 2 on the 5-clock counts 0 dots, yet is no square; on the 15-clock (2/3)(2/5) = 1, yet 2 is no square mod 15.
example : (∑ x ∈ Finset.Icc 1 2, x * 2 / 5) = 0 ∧ legendreSym 5 2 = -1 := by
  constructor
  · decide
  · norm_num
example : legendreSym 3 2 * legendreSym 5 2 = 1 ∧ ¬ IsSquare (2 : ZMod 15) := by
  constructor
  · norm_num
  · decide
-- Try changing: 11 and 19 have 5 × 9 = 45 dots, split 23 and 22.
example : (∑ x ∈ Finset.Icc 1 5, x * 19 / 11) = 23 ∧ (∑ y ∈ Finset.Icc 1 9, y * 11 / 19) = 22 := by
  decide

#print axioms same_answer_iff_not_both_three_mod_four
#print axioms legendreSym_eq_neg_one_pow_dots_below
#print axioms dots_fill_rectangle_and_signs_multiply
