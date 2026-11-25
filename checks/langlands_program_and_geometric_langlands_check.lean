-- The Langlands program: a prime other than 5 splits in Q(sqrt 5) (x^2 - x - 1 has two roots mod p) exactly when it leaves remainder 1 or 4 on division by 5, the Frobenius eigenvalues give the Hecke rule a_(p^2) = a_p^2 - p, the Langlands dual swaps type B with type C, and the card's whole-number examples are exact.
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Perm
import Mathlib.LinearAlgebra.Matrix.Cartan.Basic
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp

/-- The smallest case of reciprocity, on the card: for a prime p other than 5, p splits in
Q(sqrt 5), meaning x^2 - x - 1 (whose root is (1 + sqrt 5)/2) has exactly two roots mod p,
exactly when p leaves remainder 1 or 4 on division by 5. -/
theorem prime_splits_in_Q_sqrt_five_iff_mod_five (p : ℕ) [Fact p.Prime] (h5 : p ≠ 5) :
    (Finset.univ.filter (fun x : ZMod p => x ^ 2 - x - 1 = 0)).card = 2 ↔
      p % 5 = 1 ∨ p % 5 = 4 := by
  have hp := (Fact.out : p.Prime)
  by_cases h2 : p = 2
  · subst h2
    simp only [Nat.reduceMod]
    decide +revert
  have two_ne : (2 : ZMod p) ≠ 0 := by
    intro h
    have : ((2 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
    rw [ZMod.natCast_eq_zero_iff] at this
    have := (Nat.prime_dvd_prime_iff_eq hp Nat.prime_two).1 this
    exact h2 this
  have five_ne : (5 : ZMod p) ≠ 0 := by
    intro h
    have : ((5 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
    rw [ZMod.natCast_eq_zero_iff] at this
    have := (Nat.prime_dvd_prime_iff_eq hp Nat.prime_five).1 this
    exact h5 this
  have recip : IsSquare ((5 : ℕ) : ZMod p) ↔ IsSquare ((p : ℕ) : ZMod 5) := by
    have : Fact (Nat.Prime 5) := ⟨Nat.prime_five⟩
    exact (ZMod.exists_sq_eq_prime_iff_of_mod_four_eq_one (p := 5) (q := p) rfl h2).symm
  have mod5 : IsSquare ((p : ℕ) : ZMod 5) ↔ p % 5 = 1 ∨ p % 5 = 4 := by
    have hp5 : p % 5 ≠ 0 := by
      intro h
      have : 5 ∣ p := Nat.dvd_of_mod_eq_zero h
      have := (Nat.prime_dvd_prime_iff_eq Nat.prime_five hp).1 this
      exact h5 this.symm
    have : ((p : ℕ) : ZMod 5) = ((p % 5 : ℕ) : ZMod 5) := by
      rw [ZMod.natCast_mod]
    rw [this]
    have hlt : p % 5 < 5 := Nat.mod_lt _ (by norm_num)
    generalize p % 5 = r at hp5 hlt ⊢
    interval_cases r <;> first | exact absurd rfl hp5 | decide
  rw [← mod5, ← recip]
  push_cast
  constructor
  · intro hc
    obtain ⟨x, hx⟩ : (Finset.univ.filter (fun x : ZMod p => x ^ 2 - x - 1 = 0)).Nonempty := by
      rw [← Finset.card_pos, hc]; norm_num
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hx
    exact ⟨2 * x - 1, by linear_combination (-4 : ZMod p) * hx⟩
  · rintro ⟨s, hs⟩
    have s_ne : s ≠ 0 := by rintro rfl; apply five_ne; simpa using hs
    rw [Finset.card_eq_two]
    refine ⟨(1 + s) / 2, (1 - s) / 2, ?_, ?_⟩
    · intro h
      apply s_ne
      field_simp at h
      have : (2 : ZMod p) * s = 0 := by linear_combination h
      rcases mul_eq_zero.1 this with h' | h'
      · exact absurd h' two_ne
      · exact h'
    · ext x
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_insert,
        Finset.mem_singleton]
      constructor
      · intro hx
        have : (2 * x - 1 - s) * (2 * x - 1 + s) = 0 := by
          linear_combination (4 : ZMod p) * hx + hs
        rcases mul_eq_zero.1 this with h | h
        · left; field_simp; linear_combination h
        · right; field_simp; linear_combination h
      · rintro (rfl | rfl)
        · field_simp; linear_combination (-1 : ZMod p) * hs
        · field_simp; linear_combination (-1 : ZMod p) * hs

/-- The Hecke rule at a good prime, from the Frobenius eigenvalues: if α + β = a_p and
α β = p, then a_(p^2) = α^2 + α β + β^2 equals a_p^2 - p. -/
theorem hecke_rule_from_frobenius_eigenvalues {R : Type*} [CommRing R] (α β a p : R)
    (hsum : α + β = a) (hprod : α * β = p) :
    α ^ 2 + α * β + β ^ 2 = a ^ 2 - p := by
  linear_combination (α + β + a) * hsum - hprod

/-- The Langlands dual swaps roots and coroots, which transposes the Cartan matrix: the dual of
type B_n (SO(2n+1)) is type C_n (Sp(2n)); and B3 is not C3 in any order of its nodes, so SO(7)
is not its own dual. -/
theorem langlands_dual_of_type_B_is_type_C (n : ℕ) :
    (CartanMatrix.B n).transpose = CartanMatrix.C n ∧
      ∀ σ : Equiv.Perm (Fin 3),
        (CartanMatrix.B 3).submatrix σ σ ≠ CartanMatrix.C 3 := by
  refine ⟨CartanMatrix.B_transpose n, ?_⟩
  decide

/-! The card's whole-number examples. -/

-- 11 and 19 split in Q(sqrt 5): x^2 - x - 1 has the roots 4 and 8 mod 11, and 5 and 15 mod 19.
example : (Finset.univ.filter (fun x : ZMod 11 => x ^ 2 - x - 1 = 0)) = {4, 8} := by decide
example : (Finset.univ.filter (fun x : ZMod 19 => x ^ 2 - x - 1 = 0)) = {5, 15} := by decide
-- 7 and 13 stay prime: no roots.
example : (Finset.univ.filter (fun x : ZMod 7 => x ^ 2 - x - 1 = 0)).card = 0 := by decide
example : (Finset.univ.filter (fun x : ZMod 13 => x ^ 2 - x - 1 = 0)).card = 0 := by decide
-- 2 fits too: no root mod 2, and 2 leaves remainder 2 on division by 5.
example : (Finset.univ.filter (fun x : ZMod 2 => x ^ 2 - x - 1 = 0)).card = 0 := by decide
-- Euler's test at 7: 5^3 = 125 = 17 × 7 + 6, so 5^3 is -1 mod 7.
example : 5 ^ 3 % 7 = 6 := by norm_num
-- The wrong rule for Q(sqrt 7) fails at 3: x^2 - 7 has two roots mod 3, yet 3 is not a square mod 7.
example : (Finset.univ.filter (fun x : ZMod 3 => x ^ 2 - 7 = 0)).card = 2 := by decide
example : ¬ IsSquare (3 : ZMod 7) := by decide

-- Point counts on y^2 + y = x^3 - x^2: 4 solutions mod 3, and a_p = p - solutions is
-- -2, -1, 1, -2 at p = 2, 3, 5, 7.
example : (Finset.univ.filter
    (fun q : ZMod 3 × ZMod 3 => q.2 ^ 2 + q.2 = q.1 ^ 3 - q.1 ^ 2)).card = 4 := by decide
example : (2 : ℤ) - (Finset.univ.filter
    (fun q : ZMod 2 × ZMod 2 => q.2 ^ 2 + q.2 = q.1 ^ 3 - q.1 ^ 2)).card = -2 := by decide
example : (3 : ℤ) - (Finset.univ.filter
    (fun q : ZMod 3 × ZMod 3 => q.2 ^ 2 + q.2 = q.1 ^ 3 - q.1 ^ 2)).card = -1 := by decide
example : (5 : ℤ) - (Finset.univ.filter
    (fun q : ZMod 5 × ZMod 5 => q.2 ^ 2 + q.2 = q.1 ^ 3 - q.1 ^ 2)).card = 1 := by decide
example : (7 : ℤ) - (Finset.univ.filter
    (fun q : ZMod 7 × ZMod 7 => q.2 ^ 2 + q.2 = q.1 ^ 3 - q.1 ^ 2)).card = -2 := by decide
-- Forgetting the point at infinity at p = 2: p + 1 - solutions gives -1, not -2.
example : (2 : ℤ) + 1 - (Finset.univ.filter
    (fun q : ZMod 2 × ZMod 2 => q.2 ^ 2 + q.2 = q.1 ^ 3 - q.1 ^ 2)).card = -1 := by decide
-- The wrong curve y^2 = x^3 - x has a_3 = 0, not -1.
example : (3 : ℤ) - (Finset.univ.filter
    (fun q : ZMod 3 × ZMod 3 => q.2 ^ 2 = q.1 ^ 3 - q.1)).card = 0 := by decide

-- The Hecke rule at good primes 2, 3, 7 (a_4 = 2, a_9 = -2, a_49 = -3), the product rule
-- a_6 = a_2 a_3 and a_10 = a_2 a_5, and the bad prime 11, where a_121 = 1, not 1 - 11 = -10.
example : (-2 : ℤ) ^ 2 - 2 = 2 ∧ (-1 : ℤ) ^ 2 - 3 = -2 ∧ (-2 : ℤ) ^ 2 - 7 = -3 := by norm_num
example : (-2 : ℤ) * (-1) = 2 ∧ (-2 : ℤ) * 1 = -2 := by norm_num
example : (1 : ℤ) ^ 2 = 1 ∧ (1 : ℤ) ^ 2 - 11 = -10 := by norm_num
-- Hasse's bound at 89: |a_89| = 15 and 15^2 = 225 ≤ 4 × 89 = 356, so 15 ≤ 2 sqrt 89.
example : (15 : ℤ) ^ 2 ≤ 4 * 89 := by norm_num

#print axioms prime_splits_in_Q_sqrt_five_iff_mod_five
#print axioms hecke_rule_from_frobenius_eigenvalues
#print axioms langlands_dual_of_type_B_is_type_C
