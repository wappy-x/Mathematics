-- Gauss's lemma: on the clock of an odd prime p, a number a that p does not divide is a square exactly when an even number of a, 2a, ..., ((p - 1)/2)a read above p/2, Euler's power test agrees, and -1 and 2 are squares exactly on the clocks the card names.
import Mathlib.NumberTheory.LegendreSymbol.GaussEisensteinLemmas
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity

/-- Gauss's lemma. Take an odd prime clock p and a whole number a that p does not divide.
Multiply a by 1, 2, ... up to (p - 1)/2, and count the readings (remainders on division by p)
that sit in the top half, above p/2. The number a is a square on the p-clock exactly when that
count is even. -/
theorem square_iff_top_half_count_even (p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) (a : ℤ)
    (ha : ¬ (p : ℤ) ∣ a) :
    IsSquare (a : ZMod p) ↔
      Even ((Finset.Icc 1 ((p - 1) / 2)).filter
        (fun k : ℕ => (p : ℤ) < 2 * (a * k % p))).card := by
  have : Fact p.Prime := ⟨hp⟩
  have hodd : p % 2 = 1 := Nat.odd_iff.mp (hp.odd_of_ne_two hp2)
  have ha0 : (a : ZMod p) ≠ 0 := by
    rwa [Ne, ZMod.intCast_zmod_eq_zero_iff_dvd]
  have hset : (Finset.Icc 1 ((p - 1) / 2)).filter
        (fun k : ℕ => (p : ℤ) < 2 * (a * k % p)) =
      (Finset.Ico 1 (p / 2).succ).filter
        (fun x : ℕ => p / 2 < ((a : ZMod p) * (x : ZMod p)).val) := by
    have hI : Finset.Icc 1 ((p - 1) / 2) = Finset.Ico 1 (p / 2).succ := by
      ext x; simp only [Finset.mem_Icc, Finset.mem_Ico]; omega
    rw [hI]
    apply Finset.filter_congr
    intro x _
    have hv : ((((a * x : ℤ)) : ZMod p).val : ℤ) = a * x % p := ZMod.val_intCast _
    have hcast : ((a : ZMod p) * (x : ZMod p)) = (((a * x : ℤ)) : ZMod p) := by push_cast; ring
    rw [hcast]
    constructor
    · intro h; rw [← hv] at h; omega
    · intro h; rw [← hv]; omega
  rw [← legendreSym.eq_one_iff p ha0, ZMod.gauss_lemma hp2 ha0, hset]
  exact neg_one_pow_eq_one_iff_even (by decide)

/-- Euler's test (Euler's criterion). On an odd prime clock p, for a whole number a that p does
not divide, a multiplied in (p - 1)/2 times reads 1 when a is a square and -1 when it is not. -/
theorem euler_test_reads_one_or_neg_one (p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) (a : ℤ)
    (ha : ¬ (p : ℤ) ∣ a) :
    (IsSquare (a : ZMod p) → (a : ZMod p) ^ ((p - 1) / 2) = 1) ∧
      (¬ IsSquare (a : ZMod p) → (a : ZMod p) ^ ((p - 1) / 2) = -1) := by
  have : Fact p.Prime := ⟨hp⟩
  have ha0 : (a : ZMod p) ≠ 0 := by
    rwa [Ne, ZMod.intCast_zmod_eq_zero_iff_dvd]
  have hodd : p % 2 = 1 := Nat.odd_iff.mp (hp.odd_of_ne_two hp2)
  have hdiv : (p - 1) / 2 = p / 2 := by omega
  rw [hdiv]
  refine ⟨fun h => (ZMod.euler_criterion p ha0).mp h, fun h => ?_⟩
  rcases ZMod.pow_div_two_eq_neg_one_or_one p ha0 with h1 | h1
  · exact absurd ((ZMod.euler_criterion p ha0).mpr h1) h
  · exact h1

/-- The rules for -1 and 2. On an odd prime clock p, -1 is a square exactly when p leaves 1 on
division by 4, and 2 is a square exactly when p leaves 1 or 7 on division by 8. -/
theorem neg_one_and_two_square_rules (p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) :
    (IsSquare (-1 : ZMod p) ↔ p % 4 = 1) ∧
      (IsSquare (2 : ZMod p) ↔ p % 8 = 1 ∨ p % 8 = 7) := by
  have : Fact p.Prime := ⟨hp⟩
  have hodd : p % 2 = 1 := Nat.odd_iff.mp (hp.odd_of_ne_two hp2)
  refine ⟨?_, ZMod.exists_sq_eq_two_iff hp2⟩
  rw [ZMod.exists_sq_eq_neg_one_iff]
  omega

-- 3 on the 11-clock: 3 × 1, ..., 3 × 5 read 3, 6, 9, 1, 4.
example : (List.range' 1 5).map (fun k => 3 * k % 11) = [3, 6, 9, 1, 4] := by decide
-- Two of them, 6 and 9, sit above 5.5: an even count.
example : ((Finset.Icc 1 ((11 - 1) / 2)).filter
    (fun k : ℕ => ((11 : ℕ) : ℤ) < 2 * ((3 : ℤ) * k % (11 : ℕ)))).card = 2 := by decide
-- Folded, the readings are 3, 5, 2, 1, 4: each of 1 to 5 once.
example : [3, 6, 9, 1, 4].map (fun r => if 2 * r < 11 then r else 11 - r) = [3, 5, 2, 1, 4] := by
  decide
-- Euler: 3^5 = 243 = 22 × 11 + 1. Root: 5 × 5 = 25 reads 3.
example : 3 ^ 5 = 243 ∧ 243 = 22 * 11 + 1 := by norm_num
example : (5 : ZMod 11) * 5 = 3 := by decide
-- The squares on the 11-clock are 1, 3, 4, 5, 9.
example : (Finset.Icc 1 10).image (fun x => x * x % 11) = {1, 3, 4, 5, 9} := by decide
-- 2 is not a square on the 11-clock.
example : ∀ x : ZMod 11, x * x ≠ 2 := by decide
-- -1 on 11 counts 5 (no root); on 17 counts 8, and 4 × 4 = 16 reads -1.
example : ((Finset.Icc 1 ((11 - 1) / 2)).filter
    (fun k : ℕ => ((11 : ℕ) : ℤ) < 2 * ((-1 : ℤ) * k % (11 : ℕ)))).card = 5 := by decide
example : ∀ x : ZMod 11, x * x ≠ -1 := by decide
example : ((Finset.Icc 1 ((17 - 1) / 2)).filter
    (fun k : ℕ => ((17 : ℕ) : ℤ) < 2 * ((-1 : ℤ) * k % (17 : ℕ)))).card = 8 := by decide
example : (4 : ZMod 17) * 4 = -1 := by decide
-- 2 on the 7, 11, 13, 17 and 23 clocks counts 2, 3, 3, 4 and 6.
example : ((Finset.Icc 1 ((7 - 1) / 2)).filter
    (fun k : ℕ => ((7 : ℕ) : ℤ) < 2 * ((2 : ℤ) * k % (7 : ℕ)))).card = 2 := by decide
example : ((Finset.Icc 1 ((11 - 1) / 2)).filter
    (fun k : ℕ => ((11 : ℕ) : ℤ) < 2 * ((2 : ℤ) * k % (11 : ℕ)))).card = 3 := by decide
example : ((Finset.Icc 1 ((13 - 1) / 2)).filter
    (fun k : ℕ => ((13 : ℕ) : ℤ) < 2 * ((2 : ℤ) * k % (13 : ℕ)))).card = 3 := by decide
example : ((Finset.Icc 1 ((17 - 1) / 2)).filter
    (fun k : ℕ => ((17 : ℕ) : ℤ) < 2 * ((2 : ℤ) * k % (17 : ℕ)))).card = 4 := by decide
example : ((Finset.Icc 1 ((23 - 1) / 2)).filter
    (fun k : ℕ => ((23 : ℕ) : ℤ) < 2 * ((2 : ℤ) * k % (23 : ℕ)))).card = 6 := by decide
-- The roots of 2: 3 × 3 reads 2 on 7, 6 × 6 on 17, 5 × 5 on 23; none on 13.
example : (3 : ZMod 7) * 3 = 2 ∧ (6 : ZMod 17) * 6 = 2 ∧ (5 : ZMod 23) * 5 = 2 := by decide
example : ∀ x : ZMod 13, x * x ≠ 2 := by decide
-- The 15-clock is not prime: 2 counts 4, even, yet 2 is no square there.
example : ((Finset.Icc 1 ((15 - 1) / 2)).filter
    (fun k : ℕ => ((15 : ℕ) : ℤ) < 2 * ((2 : ℤ) * k % (15 : ℕ)))).card = 4 := by decide
example : ∀ x : ZMod 15, x * x ≠ 2 := by decide
-- Mistakes: all ten multiples of 3 on 11 count 5 on top; 2^10 reads 1 on 11.
example : ((Finset.Icc 1 10).filter (fun k => 11 < 2 * (3 * k % 11))).card = 5 := by decide
example : 2 ^ 10 % 11 = 1 := by norm_num

#print axioms square_iff_top_half_count_even
#print axioms euler_test_reads_one_or_neg_one
#print axioms neg_one_and_two_square_rules
