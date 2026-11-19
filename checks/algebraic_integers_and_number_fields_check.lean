-- Algebraic integers: a number is an algebraic integer exactly when its minimal polynomial has whole-number coefficients, the algebraic integers of a number field are closed under adding and multiplying, and the field made from a number has the degree of its minimal polynomial.
import Mathlib.FieldTheory.Minpoly.IsIntegrallyClosed
import Mathlib.FieldTheory.IntermediateField.Adjoin.Basic
import Mathlib.NumberTheory.NumberField.Basic
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.Tactic.NormNum

open Polynomial IntermediateField

/-- The card's test: an algebraic number `α` (one that solves some nonzero polynomial with
rational coefficients) is an algebraic integer, meaning a root of some monic polynomial with
whole-number coefficients, exactly when every coefficient of its minimal polynomial over `ℚ`
is a whole number. -/
theorem isIntegral_iff_minpoly_coeffs_int {L : Type*} [Field L] [CharZero L] (α : L)
    (hα : IsAlgebraic ℚ α) :
    IsIntegral ℤ α ↔ ∀ n : ℕ, ∃ z : ℤ, (minpoly ℚ α).coeff n = (z : ℚ) := by
  have hint : IsIntegral ℚ α := hα.isIntegral
  constructor
  · intro h n
    rw [minpoly.isIntegrallyClosed_eq_field_fractions' ℚ h, Polynomial.coeff_map]
    exact ⟨(minpoly ℤ α).coeff n, rfl⟩
  · intro h
    have hl : minpoly ℚ α ∈ Polynomial.lifts (algebraMap ℤ ℚ) := by
      rw [Polynomial.lifts_iff_coeff_lifts]
      intro n
      obtain ⟨z, hz⟩ := h n
      exact ⟨z, by rw [hz]; rfl⟩
    obtain ⟨q, hq, -, hmon⟩ :=
      Polynomial.lifts_and_degree_eq_and_monic hl (minpoly.monic hint)
    refine ⟨q, hmon, ?_⟩
    have h0 : Polynomial.aeval α (q.map (algebraMap ℤ ℚ)) = 0 := by
      rw [hq]; exact minpoly.aeval ℚ α
    rw [Polynomial.aeval_map_algebraMap] at h0
    exact h0

/-- Step 4: in a number field `K`, the sum and the product of two algebraic integers are
algebraic integers, so the algebraic integers of `K` form a ring. -/
theorem isIntegral_add_and_mul_of_numberField {K : Type*} [Field K] [NumberField K] {x y : K}
    (hx : IsIntegral ℤ x) (hy : IsIntegral ℤ y) :
    IsIntegral ℤ (x + y) ∧ IsIntegral ℤ (x * y) := by
  exact ⟨hx.add hy, hx.mul hy⟩

/-- Step 3: the field `ℚ(α)` made from an algebraic number `α` has degree over `ℚ` equal to the
degree of the minimal polynomial of `α`. -/
theorem finrank_adjoin_eq_natDegree_minpoly {L : Type*} [Field L] [CharZero L] (α : L)
    (hα : IsAlgebraic ℚ α) :
    Module.finrank ℚ ℚ⟮α⟯ = (minpoly ℚ α).natDegree := by
  exact IntermediateField.adjoin.finrank hα.isIntegral

-- Worked numbers. The house example in Z[√-5]: (1 + √-5)(1 - √-5) = 6 = 2 × 3.
example : (⟨1, 1⟩ : ℤ√(-5)) * ⟨1, -1⟩ = 6 := by decide

-- Minimal polynomial x^2 - 2a x + (a^2 - d b^2), with d = -5:
-- for √-5 (a = 0, b = 1) the constant is 5; for 1 + √-5 it is 6, with middle coefficient -2.
example : (0 : ℤ) ^ 2 - (-5) * 1 ^ 2 = 5 := by norm_num
example : (1 : ℤ) ^ 2 - (-5) * 1 ^ 2 = 6 ∧ -2 * (1 : ℤ) = -2 := by norm_num
-- For the half √-5/2 (a = 0, b = 1/2) the constant is 5/4, not a whole number.
example : (0 : ℚ) ^ 2 - (-5) * (1 / 2) ^ 2 = 5 / 4 := by norm_num
example : ¬ ∃ z : ℤ, ((z : ℚ) = 5 / 4) := by
  rintro ⟨z, hz⟩
  have h : (4 * z : ℚ) = 5 := by rw [hz]; norm_num
  have h2 : 4 * z = 5 := by exact_mod_cast h
  omega
-- Powers of √-5 fold back: (√-5)^2 = -5, (√-5)^4 = 25.
example : (-5 : ℤ) ^ 2 = 25 := by norm_num
-- Step 4 for d = -5: if a and b are both odd, a^2 + 5 b^2 leaves remainder 6 after division by 8.
example : ∀ a b : Fin 8, (a.val % 2 = 1 ∧ b.val % 2 = 1) →
    (a.val ^ 2 + 5 * b.val ^ 2) % 8 = 6 := by decide
-- The search count 13 = 1 + 3 + 9 and the grid 17 × 17 = 289; 41 = 25 + 16 for d = 5.
example : 1 + 3 + 9 = 13 ∧ 17 * 17 = 289 ∧ 25 + 16 = 41 := by norm_num
-- The golden ratio (1 + √5)/2 has minimal polynomial x^2 - x - 1: a = b = 1/2, d = 5.
example : -2 * (1 / 2 : ℚ) = -1 ∧ (1 / 2 : ℚ) ^ 2 - 5 * (1 / 2) ^ 2 = -1 := by norm_num

#print axioms isIntegral_iff_minpoly_coeffs_int
#print axioms isIntegral_add_and_mul_of_numberField
#print axioms finrank_adjoin_eq_natDegree_minpoly
