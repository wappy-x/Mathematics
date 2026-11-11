-- Fields: in any field, a times x equals b with a nonzero has exactly one answer x, two nonzero elements never multiply to zero, and the n-day cycle (n at least 2) is a field exactly when n is prime.
import Mathlib.Algebra.Field.Basic
import Mathlib.Algebra.Field.IsField
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Field.Rat
import Mathlib.Algebra.Field.ZMod
import Mathlib.Tactic.NormNum.Prime

/-- In a field, dividing is legal: for any coefficient a that is not zero and any target b,
the equation a × x = b has exactly one answer x. -/
theorem linear_equation_has_exactly_one_answer {K : Type*} [Field K] (a b : K) (ha : a ≠ 0) :
    ∃! x : K, a * x = b := by
  refine ⟨a⁻¹ * b, ?_, ?_⟩
  · simp [← mul_assoc, mul_inv_cancel₀ ha]
  · intro y hy
    rw [← hy]
    simp [← mul_assoc, inv_mul_cancel₀ ha]

/-- No zero divisors: in a field, if a × b = 0 and a is not zero, then b is zero. So two
nonzero elements never multiply to zero. -/
theorem field_has_no_zero_divisors {K : Type*} [Field K] (a b : K) (ha : a ≠ 0)
    (hab : a * b = 0) : b = 0 := by
  exact (mul_eq_zero.mp hab).resolve_left ha

/-- The n-day cycle, the labels 0 to n − 1 added and multiplied on the cycle, is a field
exactly when n is prime, for every n at least 2. -/
theorem cycle_is_field_iff_prime (n : ℕ) (hn : 2 ≤ n) : IsField (ZMod n) ↔ n.Prime := by
  constructor
  · intro h
    have : Fact (1 < n) := ⟨by omega⟩
    have : Nontrivial (ZMod n) := ZMod.nontrivial n
    let _inst : Field (ZMod n) := h.toField
    have : IsDomain (ZMod n) := inferInstance
    exact (CharP.char_is_prime_of_two_le (ZMod n) n hn)
  · intro h
    have _hp : Fact n.Prime := ⟨h⟩
    exact Field.toIsField (ZMod n)

-- The rota: 18 days after a Monday lands on Friday, day 4.
example : 18 % 7 = 4 := by norm_num
-- The reciprocal of 3 on the week is 5, and 2 × 4 and 6 × 6 also give 1.
example : (3 : ZMod 7) * 5 = 1 ∧ (2 : ZMod 7) * 4 = 1 ∧ (6 : ZMod 7) * 6 = 1 := by decide
-- By hand: 3 × 5 = 15 and 15 − 14 = 1; 5 × 4 = 20 and 20 − 14 = 6; 3 × 6 = 18 and 18 − 14 = 4.
example : 3 * 5 = 15 ∧ 15 - 14 = 1 ∧ 5 * 4 = 20 ∧ 20 - 14 = 6 ∧ 3 * 6 = 18 ∧ 18 - 14 = 4 := by
  norm_num
-- 3x ≡ 4 (mod 7) has exactly one answer, x = 6.
example : (Finset.univ.filter fun x : ZMod 7 => 3 * x = 4) = {6} := by decide
-- Days 1 to 6 have reciprocals 1, 4, 5, 2, 3 and 6, in order.
example : (1 : ZMod 7) * 1 = 1 ∧ (2 : ZMod 7) * 4 = 1 ∧ (3 : ZMod 7) * 5 = 1 ∧
    (4 : ZMod 7) * 2 = 1 ∧ (5 : ZMod 7) * 3 = 1 ∧ (6 : ZMod 7) * 6 = 1 := by decide
-- All 42 equations a × x ≡ b (mod 7) with a nonzero have exactly one answer.
example : ∀ a b : ZMod 7, a ≠ 0 → (Finset.univ.filter fun x : ZMod 7 => a * x = b).card = 1 := by
  decide
-- A zero coefficient: 0x ≡ 1 (mod 7) has no answer, 0x ≡ 0 (mod 7) has all seven.
example : (Finset.univ.filter fun x : ZMod 7 => 0 * x = 1).card = 0 ∧
    (Finset.univ.filter fun x : ZMod 7 => 0 * x = 0).card = 7 := by decide
-- The additive partner is not the reciprocal: 3 + 4 ≡ 0 but 3 × 4 ≡ 5, and x = 2 gives 3 × 2 ≡ 6.
example : (3 : ZMod 7) + 4 = 0 ∧ (3 : ZMod 7) * 4 = 5 ∧ (4 : ZMod 7) * 4 = 2 ∧
    (3 : ZMod 7) * 2 = 6 := by decide
-- The six-day cycle: 2 × 3 ≡ 0, only 1 and 5 have reciprocals, 2x ≡ 1 has no answer, 2x ≡ 2 has 1 and 4.
example : (2 : ZMod 6) * 3 = 0 ∧
    (Finset.univ.filter fun a : ZMod 6 => ∃ b : ZMod 6, a * b = 1) = {1, 5} ∧
    (Finset.univ.filter fun x : ZMod 6 => 2 * x = 1) = ∅ ∧
    (Finset.univ.filter fun x : ZMod 6 => 2 * x = 2) = {1, 4} := by decide
-- The twelve-hour clock: 3 × 4 ≡ 0, only 1, 5, 7 and 11 have reciprocals, 3x ≡ 0 has 0, 4 and 8.
example : (3 : ZMod 12) * 4 = 0 ∧
    (Finset.univ.filter fun a : ZMod 12 => ∃ b : ZMod 12, a * b = 1) = {1, 5, 7, 11} ∧
    (Finset.univ.filter fun x : ZMod 12 => 3 * x = 0) = {0, 4, 8} := by decide
-- The four-day cycle: only 2 of the 3 nonzero labels have a reciprocal.
example : (Finset.univ.filter fun a : ZMod 4 => ∃ b : ZMod 4, a * b = 1).card = 2 := by decide
-- Euclid's combination for 3 on the week: 5 × 3 − 2 × 7 = 1.
example : (5 : ℤ) * 3 - 2 * 7 = 1 := by norm_num
-- In the whole numbers 2k = 1 has no answer; among fractions, (3/4) × (4/3) = 1.
example : ∀ k : ℤ, 2 * k ≠ 1 := by omega
example : (3 / 4 : ℚ) * (4 / 3) = 1 := by norm_num
-- The cycle sizes from 2 to 12 that are prime: 2, 3, 5, 7 and 11.
example : (Finset.Icc 2 12).filter Nat.Prime = {2, 3, 5, 7, 11} := by decide

#print axioms linear_equation_has_exactly_one_answer
#print axioms field_has_no_zero_divisors
#print axioms cycle_is_field_iff_prime
