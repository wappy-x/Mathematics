-- Quadratic residues: on the clock of an odd prime p, exactly half the nonzero remainders are squares, Euler's test a^((p-1)/2) gives 1 for a square and −1 for a non-square, and the Legendre symbol multiplies.
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.NumberTheory.LegendreSymbol.QuadraticChar.Basic

/-- For an odd prime p, p / 2 = (p - 1) / 2. -/
theorem qr_half_eq (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) : p / 2 = (p - 1) / 2 := by
  have := (Fact.out : p.Prime).eq_two_or_odd
  omega

/-- On the clock of an odd prime p, exactly (p - 1)/2 nonzero remainders are squares. -/
theorem qr_card_nonzero_squares (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    ((Finset.univ : Finset (ZMod p)).filter (fun x => x ≠ 0 ∧ IsSquare x)).card = (p - 1) / 2 := by
  classical
  have hF : ringChar (ZMod p) ≠ 2 := by rwa [ZMod.ringChar_zmod_n]
  set U := (Finset.univ : Finset (ZMod p)).filter (fun x => x ≠ 0) with hUdef
  have hS : (Finset.univ : Finset (ZMod p)).filter (fun x => x ≠ 0 ∧ IsSquare x)
      = U.filter (fun x => IsSquare x) := by
    ext x; simp [U]
  have hU : U.card = p - 1 := by
    rw [hUdef, Finset.filter_ne', Finset.card_erase_of_mem (Finset.mem_univ _),
      Finset.card_univ, ZMod.card]
  have hsplit := Finset.card_filter_add_card_filter_not (s := U) (fun x : ZMod p => IsSquare x)
  have hsum : ∑ a : ZMod p, quadraticChar (ZMod p) a = 0 := quadraticChar_sum_zero hF
  have h2 : ∑ a ∈ U, quadraticChar (ZMod p) a = ∑ a : ZMod p, quadraticChar (ZMod p) a := by
    rw [hUdef, Finset.sum_filter_of_ne]
    intro x _ hx h
    exact hx (by rw [h]; exact quadraticChar_zero)
  have h3 : ∑ a ∈ U, quadraticChar (ZMod p) a
      = ((U.filter (fun x => IsSquare x)).card : ℤ) - (U.filter (fun x => ¬ IsSquare x)).card := by
    rw [← Finset.sum_filter_add_sum_filter_not U (fun x => IsSquare x)]
    have hA : ∑ x ∈ U.filter (fun x => IsSquare x), quadraticChar (ZMod p) x
        = ∑ x ∈ U.filter (fun x => IsSquare x), (1 : ℤ) := by
      refine Finset.sum_congr rfl ?_
      intro x hx
      simp only [Finset.mem_filter, U, Finset.mem_univ, true_and] at hx
      exact (quadraticChar_one_iff_isSquare hx.1).mpr hx.2
    have hB : ∑ x ∈ U.filter (fun x => ¬ IsSquare x), quadraticChar (ZMod p) x
        = ∑ x ∈ U.filter (fun x => ¬ IsSquare x), (-1 : ℤ) := by
      refine Finset.sum_congr rfl ?_
      intro x hx
      simp only [Finset.mem_filter, U, Finset.mem_univ, true_and] at hx
      exact quadraticChar_neg_one_iff_not_isSquare.mpr hx.2
    rw [hA, hB]
    simp [sub_eq_add_neg]
  rw [h2, hsum] at h3
  rw [hS]
  omega

#print axioms qr_half_eq
#print axioms qr_card_nonzero_squares

/-- The card's main claim. Let p be an odd prime. On the p-clock (the remainders mod p):
exactly half the nonzero remainders, (p − 1)/2 of them, are squares; a remainder a that is not
a multiple of p is a square exactly when a^((p-1)/2) leaves 1, and is a non-square exactly when
it leaves −1; and the ±1 answer, the Legendre symbol (a/p), multiplies:
(ab/p) = (a/p)(b/p) for all whole numbers a and b. -/
theorem quadratic_residues_half_euler_test_and_product_rule (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    ((Finset.univ : Finset (ZMod p)).filter (fun x => x ≠ 0 ∧ IsSquare x)).card = (p - 1) / 2 ∧
      (∀ a : ℤ, (a : ZMod p) ≠ 0 →
        (IsSquare (a : ZMod p) ↔ (a : ZMod p) ^ ((p - 1) / 2) = 1) ∧
          (¬ IsSquare (a : ZMod p) ↔ (a : ZMod p) ^ ((p - 1) / 2) = -1)) ∧
      ∀ a b : ℤ, legendreSym p (a * b) = legendreSym p a * legendreSym p b := by
  have hhalf := qr_half_eq p hp
  have h2 : 2 < p := lt_of_le_of_ne (Fact.out : p.Prime).two_le (Ne.symm hp)
  have : Fact (2 < p) := ⟨h2⟩
  refine ⟨qr_card_nonzero_squares p hp, ?_, fun a b => legendreSym.mul p a b⟩
  intro a ha
  have he := ZMod.euler_criterion p ha
  rw [hhalf] at he
  refine ⟨he, ?_⟩
  have hd := ZMod.pow_div_two_eq_neg_one_or_one p ha
  rw [hhalf] at hd
  constructor
  · intro hns
    rcases hd with h | h
    · exact absurd (he.mpr h) hns
    · exact h
  · intro hneg hsq
    exact ZMod.neg_one_ne_one (hneg.symm.trans (he.mp hsq))

/-- Euler's criterion as the card writes it: for an odd prime p and every whole number a,
the Legendre symbol (a/p) (+1 for a nonzero square, −1 for a non-square, 0 when p divides a)
leaves the same remainder mod p as a^((p-1)/2). -/
theorem legendre_symbol_eq_euler_power (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) (a : ℤ) :
    (legendreSym p a : ZMod p) = (a : ZMod p) ^ ((p - 1) / 2) := by
  rw [← qr_half_eq p hp]
  exact legendreSym.eq_pow p a

/-- The first payoff (Step 6): on the clock of an odd prime p, −1 is a square exactly when
p leaves remainder 1 on division by 4. -/
theorem neg_one_is_square_iff_mod_four_eq_one (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    IsSquare (-1 : ZMod p) ↔ p % 4 = 1 := by
  rw [ZMod.exists_sq_eq_neg_one_iff]
  have := (Fact.out : p.Prime).eq_two_or_odd
  omega

-- The 13-clock: squaring 1..12 gives 1, 4, 9, 3, 12, 10, then the same six in reverse.
example : (List.range 12).map (fun x => ((x + 1 : ℕ) : ZMod 13) ^ 2)
    = [1, 4, 9, 3, 12, 10, 10, 12, 3, 9, 4, 1] := by decide
-- The six nonzero squares are 1, 3, 4, 9, 10, 12: half of the twelve.
example : ((Finset.univ : Finset (ZMod 13)).filter (fun x => x ≠ 0 ∧ ∃ r, x = r * r))
    = {1, 3, 4, 9, 10, 12} := by decide
-- 3 is a square: 4 × 4 = 16 = 13 + 3, and 9 × 9 = 81 = 6 × 13 + 3.
example : (4 : ZMod 13) * 4 = 3 ∧ (9 : ZMod 13) * 9 = 3 := by decide
-- 2 is not a square on the 13-clock.
example : ¬ ∃ r : ZMod 13, (2 : ZMod 13) = r * r := by decide
-- Euler's test: 3^3 = 27 leaves 1, so 3^6 leaves 1; 2^6 = 64 leaves 12, that is −1.
example : (3 : ZMod 13) ^ 3 = 1 ∧ (3 : ZMod 13) ^ 6 = 1 := by decide
example : (2 : ZMod 13) ^ 6 = -1 ∧ (2 : ZMod 13) ^ 6 = 12 := by decide
-- The row a^6 on the 13-clock, for a = 1..12.
example : (List.range 12).map (fun x => ((x + 1 : ℕ) : ZMod 13) ^ 6)
    = [1, 12, 1, 1, 12, 12, 12, 12, 1, 1, 12, 1] := by decide
-- Primitive root 2: its powers 2^1..2^12 run 2, 4, 8, 3, 6, 12, 11, 9, 5, 10, 7, 1; 3 = 2^4.
example : (List.range 12).map (fun k => (2 : ZMod 13) ^ (k + 1))
    = [2, 4, 8, 3, 6, 12, 11, 9, 5, 10, 7, 1] := by decide
-- Product rule: 2 and 5 are non-squares, so 10 is a square: 6 × 6 = 36 = 2 × 13 + 10.
example : (6 : ZMod 13) * 6 = 10 ∧ (10 : ZMod 13) ^ 6 = 1 := by decide
-- What breaks: Fermat's exponent 12 gives 1 for 2 as well; on the 15-clock 4^7 leaves 4;
-- −1 is a square on the 13-clock, since 5 × 5 = 25 = 13 + 12.
example : (2 : ZMod 13) ^ 12 = 1 := by decide
example : (4 : ZMod 15) ^ 7 = 4 := by decide
example : (5 : ZMod 13) * 5 = -1 := by decide

#print axioms quadratic_residues_half_euler_test_and_product_rule
#print axioms legendre_symbol_eq_euler_power
#print axioms neg_one_is_square_iff_mod_four_eq_one
