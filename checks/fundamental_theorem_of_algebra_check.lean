-- The fundamental theorem of algebra: every polynomial of degree n ≥ 1 with complex coefficients is its leading coefficient times n brackets (x - r), one per root counted with repeats, so it has a root and exactly n roots.
import Mathlib.Analysis.Complex.Polynomial.Basic

open Polynomial Complex

/-- The fundamental theorem of algebra. Take any polynomial P with complex coefficients and
degree n of at least 1. Then there are n complex numbers r_1, …, r_n, repeats allowed, with
P(x) = a_n (x - r_1)(x - r_2) … (x - r_n), where a_n is the leading coefficient; and these are
all the roots: a complex number s is a root of P exactly when s is one of r_1, …, r_n. -/
theorem polynomial_is_leading_coefficient_times_one_bracket_per_root (P : ℂ[X])
    (hP : 1 ≤ P.natDegree) :
    ∃ r : Fin P.natDegree → ℂ,
      P = C P.leadingCoeff * ∏ i, (X - C (r i)) ∧ ∀ s : ℂ, P.IsRoot s ↔ ∃ i, s = r i := by
  have hcard : Multiset.card P.roots = P.natDegree := IsAlgClosed.card_roots_eq_natDegree
  have hP0 : P ≠ 0 := by
    rintro rfl
    simp at hP
  have hlen : P.roots.toList.length = P.natDegree := by
    rw [Multiset.length_toList]; exact hcard
  refine ⟨fun i => P.roots.toList.get (Fin.cast hlen.symm i), ?_, ?_⟩
  · have h1 : P = C P.leadingCoeff * (P.roots.map fun a => X - C a).prod :=
      (C_leadingCoeff_mul_prod_multiset_X_sub_C hcard).symm
    have h2 : ∏ i : Fin P.natDegree, (X - C (P.roots.toList.get (Fin.cast hlen.symm i)))
        = (P.roots.map fun a => X - C a).prod := by
      conv_rhs => rw [← Multiset.coe_toList P.roots, Multiset.map_coe, Multiset.prod_coe]
      rw [← List.prod_ofFn]
      congr 1
      apply List.ext_getElem
      · simp [hlen]
      · intro n h1 h2
        simp
    rw [h2]; exact h1
  · intro s
    rw [← mem_roots hP0, ← Multiset.mem_toList, List.mem_iff_get]
    constructor
    · rintro ⟨i, hi⟩
      exact ⟨Fin.cast hlen i, hi.symm⟩
    · rintro ⟨i, hi⟩
      exact ⟨Fin.cast hlen.symm i, hi.symm⟩

/-- Step 0, the hard content: every polynomial of degree at least 1 with complex coefficients
has at least one complex root. -/
theorem complex_polynomial_of_degree_at_least_one_has_a_root (P : ℂ[X])
    (hP : 1 ≤ P.natDegree) : ∃ z : ℂ, P.IsRoot z := by
  exact Complex.exists_root (natDegree_pos_iff_degree_pos.mp hP)

/-- Exactly n roots, counted with repeats: for a complex polynomial of degree n ≥ 1, the roots,
each listed as many times as its multiplicity, number exactly n. -/
theorem degree_n_gives_exactly_n_roots_counted_with_repeats (P : ℂ[X])
    (hP : 1 ≤ P.natDegree) : Multiset.card P.roots = P.natDegree := by
  exact IsAlgClosed.card_roots_eq_natDegree

-- The one new rule: i × i = -1.
example : I * I = -1 := I_mul_I
-- The ball at 25 metres: the discriminant of 5t^2 - 20t + 25 is -100.
example : (-20 : ℤ) ^ 2 - 4 * 5 * 25 = -100 := by norm_num
-- Its square root is 10i: 10i × 10i = -100.
example : (10 * I) * (10 * I) = -100 := by linear_combination (100 : ℂ) * I_mul_I
-- The quadratic formula's answers 2 + i and 2 - i are roots of 5t^2 - 20t + 25.
example : 5 * (2 + I) ^ 2 - 20 * (2 + I) + 25 = 0 := by linear_combination (5 : ℂ) * I_sq
example : 5 * (2 - I) ^ 2 - 20 * (2 - I) + 25 = 0 := by linear_combination (5 : ℂ) * I_sq
-- Their brackets multiply back with no i left: (t - 2 - i)(t - 2 + i) = t^2 - 4t + 5.
example : (X - C (2 + I)) * (X - C (2 - I)) = X ^ 2 - 4 * X + 5 := by
  have hI : C I * C I = -1 := by rw [← C_mul, I_mul_I, C_neg, C_1]
  rw [C_add, C_sub, C_ofNat]
  linear_combination -hI
-- Restore the 5: 5(t - 2 - i)(t - 2 + i) = 5t^2 - 20t + 25.
example : 5 * (X - C (2 + I)) * (X - C (2 - I)) = 5 * X ^ 2 - 20 * X + 25 := by
  have hI : C I * C I = -1 := by rw [← C_mul, I_mul_I, C_neg, C_1]
  rw [C_add, C_sub, C_ofNat]
  linear_combination -5 * hI
-- Drop the leading 5 and the constant term is (2 + i)(2 - i) = 5, not 25.
example : (2 + I) * (2 - I) = 5 := by linear_combination (-1 : ℂ) * I_sq
-- Real roots were complex all along: x^3 - 6x^2 + 11x - 6 = (x - 1)(x - 2)(x - 3).
example : (X - 1 : ℂ[X]) * (X - 2) * (X - 3) = X ^ 3 - 6 * X ^ 2 + 11 * X - 6 := by ring
-- Repeats counted: x^2 - 2x + 1 = (x - 1)(x - 1), two brackets, one distinct root.
example : (X - 1 : ℂ[X]) * (X - 1) = X ^ 2 - 2 * X + 1 := by ring
-- On the real line 5t^2 - 20t + 25 has no root ...
example : ∀ t : ℝ, 5 * t ^ 2 - 20 * t + 25 ≠ 0 := by
  intro t h
  nlinarith [sq_nonneg (t - 2)]
-- ... because the height 20t - 5t^2 never passes 20 metres, reached at t = 2.
example : (∀ t : ℝ, 20 * t - 5 * t ^ 2 ≤ 20) ∧ 20 * 2 - 5 * 2 ^ 2 = (20 : ℤ) := by
  refine ⟨fun t => by nlinarith [sq_nonneg (t - 2)], by norm_num⟩
-- Reading the square root of -100 as -10 gives t = 1 and 3, where the polynomial is 10, not 0.
example : (5 * 1 ^ 2 - 20 * 1 + 25 : ℤ) = 10 ∧ (5 * 3 ^ 2 - 20 * 3 + 25 : ℤ) = 10 := by decide

#print axioms polynomial_is_leading_coefficient_times_one_bracket_per_root
#print axioms complex_polynomial_of_degree_at_least_one_has_a_root
#print axioms degree_n_gives_exactly_n_roots_counted_with_repeats
