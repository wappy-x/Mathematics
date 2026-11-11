-- Finite fields: every finite field has a prime power number of elements, the n-hour clock is a field exactly when n is prime, and wrapping polynomials over a prime clock by one of degree k gives p ^ k elements and a field exactly when that polynomial does not factor.
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.FieldTheory.Finiteness
import Mathlib.RingTheory.AdjoinRoot
import Mathlib.Algebra.IsPrimePow
import Mathlib.Data.ZMod.Basic

open Polynomial

/-- A finite field's size is always a prime raised to a positive whole power: for every field F
with finitely many elements there is a prime p and a whole number k ≥ 1 with |F| = p ^ k. -/
theorem finite_field_card_eq_prime_pow (F : Type*) [Field F] [Fintype F] :
    ∃ p k : ℕ, p.Prime ∧ 0 < k ∧ Fintype.card F = p ^ k := by
  classical
  obtain ⟨n, hp, hn⟩ := FiniteField.card F (ringChar F)
  exact ⟨ringChar F, n, hp, n.pos, hn⟩

/-- A clock divides only at a prime number of hours: the whole numbers wrapped at n
(the n-hour clock) form a field exactly when n is prime. -/
theorem clock_is_field_iff_prime (n : ℕ) : IsField (ZMod n) ↔ n.Prime := by
  constructor
  · intro h
    by_cases hn : n = 0
    · subst hn
      exact absurd h Int.not_isField
    · have : Nontrivial (ZMod n) := h.nontrivial
      have : IsDomain (ZMod n) := h.isDomain
      rcases CharP.char_is_prime_or_zero (ZMod n) n with hp | hz
      · exact hp
      · exact absurd hz hn
  · intro hp
    have := Fact.mk hp
    exact Field.toIsField (ZMod n)

/-- GF(p ^ k) = GF(p)[x] / (f). Take a prime p and a nonzero polynomial f of degree k with
coefficients on the p-hour clock. Discarding the multiples of f leaves exactly p ^ k elements,
and they form a field exactly when f does not factor (is irreducible). -/
theorem polynomial_quotient_has_prime_pow_size_and_is_field_iff_irreducible
    (p : ℕ) [Fact p.Prime] (f : (ZMod p)[X]) (hf : f ≠ 0) :
    Nat.card (AdjoinRoot f) = p ^ f.natDegree ∧ (IsField (AdjoinRoot f) ↔ Irreducible f) := by
  have hfin : Module.Finite (ZMod p) (AdjoinRoot f) := (AdjoinRoot.powerBasis hf).finite
  refine ⟨?_, AdjoinRoot.isField_iff_irreducible⟩
  rw [Module.natCard_eq_pow_finrank (K := ZMod p) (V := AdjoinRoot f), Nat.card_zmod]
  congr 1
  rw [← AdjoinRoot.powerBasis_dim hf, PowerBasis.finrank]

-- The four-hour clock: 2 times 2 wraps to 0, 1 + 1 = 2, and 2 has no reciprocal.
example : (2 : ZMod 4) * 2 = 0 ∧ (1 : ZMod 4) + 1 = 2 := by decide
example : ∀ r : ZMod 4, (2 : ZMod 4) * r ≠ 1 := by decide
-- The seven-day week: 3 times 5 = 15 wraps to 1; reciprocals of 1 to 6 are 1 4 5 2 3 6.
example : (3 * 5 : ℕ) = 15 ∧ 15 % 7 = 1 := by decide
example : (1 : ZMod 7) * 1 = 1 ∧ (2 : ZMod 7) * 4 = 1 ∧ (3 : ZMod 7) * 5 = 1 ∧
    (4 : ZMod 7) * 2 = 1 ∧ (5 : ZMod 7) * 3 = 1 ∧ (6 : ZMod 7) * 6 = 1 := by decide
-- The twelve-hour clock: 3 times 4 wraps to 0, and only 1, 5, 7, 11 have a reciprocal.
example : (3 : ZMod 12) * 4 = 0 := by decide
example : ∀ a : ZMod 12, (∃ b : ZMod 12, a * b = 1) ↔ (a = 1 ∨ a = 5 ∨ a = 7 ∨ a = 11) := by
  decide
-- x^2 + x + 1 has no root on the two-hour clock: 1 at x = 0, and 1 + 1 + 1 wraps to 1 at x = 1.
example : ∀ x : ZMod 2, x ^ 2 + x + 1 ≠ 0 := by decide
-- Wrapping by x^2 + 1 or by x^2 + x fails: each has a root, and x^2 + 1 = (x + 1)^2 there.
example : (1 : ZMod 2) ^ 2 + 1 = 0 ∧ (0 : ZMod 2) ^ 2 + 0 = 0 ∧
    ∀ x : ZMod 2, (x + 1) ^ 2 = x ^ 2 + 1 := by decide
-- GF(4) in coordinates c + d·a with a^2 = a + 1 (the card's road two), a = (0, 1):
-- a times a + 1 = 1, a + 1 squared = a, the powers of a are 1, a, a + 1, 1,
-- every element added to itself is 0, and every nonzero row of the table holds a 1.
example :
    let mul : ZMod 2 × ZMod 2 → ZMod 2 × ZMod 2 → ZMod 2 × ZMod 2 :=
      fun u v => (u.1 * v.1 + u.2 * v.2, u.1 * v.2 + u.2 * v.1 + u.2 * v.2)
    mul (0, 1) (1, 1) = (1, 0) ∧ mul (1, 1) (1, 1) = (0, 1) ∧
      mul (0, 1) (0, 1) = (1, 1) ∧ mul (mul (0, 1) (0, 1)) (0, 1) = (1, 0) ∧
      (∀ u : ZMod 2 × ZMod 2, u + u = 0) ∧
      (∀ u : ZMod 2 × ZMod 2, u ≠ 0 → ∃ v, mul u v = (1, 0)) := by
  decide
-- Sizes: 4 is a prime power, 6 and 10 are not, so no field has 6 or 10 elements.
example : IsPrimePow 4 ∧ ¬ IsPrimePow 6 ∧ ¬ IsPrimePow 10 := by decide

#print axioms finite_field_card_eq_prime_pow
#print axioms clock_is_field_iff_prime
#print axioms polynomial_quotient_has_prime_pow_size_and_is_field_iff_irreducible
