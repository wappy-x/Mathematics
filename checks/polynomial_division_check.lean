-- Polynomial long division: when the divisor is not zero and its leading number can be divided by, there is exactly one quotient and remainder with the remainder of lower degree, and dividing by x - r leaves the value p(r).
import Mathlib.Algebra.Polynomial.Div
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

open Polynomial

/-- Division with a remainder, for polynomials. Let d be a divisor that is not the zero
polynomial and whose leading number can be divided by (it has an inverse). Then for every
polynomial p there is exactly one pair, a quotient q and a remainder s, with
p(x) = d(x) q(x) + s(x) and the remainder of lower degree than the divisor. -/
theorem polynomial_division_with_remainder_exists_and_is_unique {R : Type*} [CommRing R]
    (p d : R[X]) (hd : d ≠ 0) (hlead : IsUnit d.leadingCoeff) :
    ∃! qs : R[X] × R[X], p = d * qs.1 + qs.2 ∧ qs.2.degree < d.degree := by
  rcases subsingleton_or_nontrivial R with hR | hR
  · exact absurd (Subsingleton.elim d 0) hd
  obtain ⟨u, hu⟩ := hlead
  have hbu : C (↑u⁻¹ : R) * C (↑u : R) = 1 := by rw [← C_mul, Units.inv_mul, C_1]
  have hm : Monic (d * C (↑u⁻¹ : R)) :=
    monic_mul_C_of_leadingCoeff_mul_eq_one (by rw [← hu, Units.mul_inv])
  have hle : ∀ (f : R[X]) (a : R), (f * C a).degree ≤ f.degree := by
    intro f a
    have h := degree_mul_le_of_le (p := f) (q := C a) le_rfl degree_C_le
    rwa [add_zero] at h
  have hdeg : (d * C (↑u⁻¹ : R)).degree = d.degree := by
    apply le_antisymm (hle _ _)
    have : d = d * C (↑u⁻¹ : R) * C (↑u : R) := by rw [mul_assoc, hbu, mul_one]
    conv_lhs => rw [this]
    exact hle _ _
  refine ⟨(C (↑u⁻¹ : R) * (p /ₘ (d * C (↑u⁻¹ : R))), p %ₘ (d * C (↑u⁻¹ : R))), ⟨?_, ?_⟩, ?_⟩
  · have h := modByMonic_add_div p (d * C (↑u⁻¹ : R))
    calc p = p %ₘ (d * C (↑u⁻¹ : R)) + d * C (↑u⁻¹ : R) * (p /ₘ (d * C (↑u⁻¹ : R))) := h.symm
      _ = _ := by ring
  · rw [← hdeg]; exact degree_modByMonic_lt _ hm
  · rintro ⟨q', s'⟩ ⟨hp, hs⟩
    have key := div_modByMonic_unique (f := p) (C (↑u : R) * q') s' hm
      ⟨by
        calc s' + d * C (↑u⁻¹ : R) * (C (↑u : R) * q')
            = s' + d * (C (↑u⁻¹ : R) * C (↑u : R)) * q' := by ring
          _ = p := by rw [hbu, mul_one, hp, add_comm],
       by rw [hdeg]; exact hs⟩
    rw [key.1, key.2, ← mul_assoc, hbu, one_mul]

/-- The remainder theorem, as a formula. Dividing p by x minus a number r leaves the plain
number p(r): p(x) = (x - r) q(x) + p(r) for some polynomial q. -/
theorem dividing_by_x_minus_r_leaves_p_of_r {R : Type*} [CommRing R] (p : R[X]) (r : R) :
    ∃ q : R[X], p = (X - C r) * q + C (p.eval r) := by
  refine ⟨p /ₘ (X - C r), ?_⟩
  rw [← modByMonic_X_sub_C_eq_C_eval, add_comm, modByMonic_add_div]

/-- The remainder is the value at the root (Step 3). Whatever quotient q and remainder s
come out of dividing p by x - r, as long as the remainder has lower degree than x - r,
the remainder is the plain number p(r). -/
theorem remainder_on_dividing_by_x_minus_r_is_p_of_r {R : Type*} [CommRing R]
    (p : R[X]) (r : R) (q s : R[X]) (hdiv : p = (X - C r) * q + s)
    (hdeg : s.degree < (X - C r).degree) :
    s = C (p.eval r) := by
  rw [← modByMonic_X_sub_C_eq_C_eval]
  exact ((div_modByMonic_unique q s (monic_X_sub_C r) ⟨by rw [hdiv, add_comm], hdeg⟩).2).symm

-- The whole-number original: 17 = 5 × 3 + 2, and 2 is smaller than 5.
example : (17 : ℕ) = 5 * 3 + 2 ∧ 2 < 5 := by decide
-- The box: x^3 + 6x^2 + 11x + 6 divided by the edge x + 1 is x^2 + 5x + 6, remainder 0.
example : (X ^ 3 + 6 * X ^ 2 + 11 * X + 6 : ℤ[X]) = (X + 1) * (X ^ 2 + 5 * X + 6) + 0 := by
  ring
-- The loop's leftovers: after x^2 lots of x + 1, then 5x lots, then 6 lots.
example : (X ^ 3 + 6 * X ^ 2 + 11 * X + 6 : ℤ[X]) - X ^ 2 * (X + 1) = 5 * X ^ 2 + 11 * X + 6 := by
  ring
example : (5 * X ^ 2 + 11 * X + 6 : ℤ[X]) - 5 * X * (X + 1) = 6 * X + 6 := by ring
example : (6 * X + 6 : ℤ[X]) - 6 * (X + 1) = 0 := by ring
-- The face un-multiplies: x^2 + 5x + 6 = (x + 2)(x + 3).
example : (X ^ 2 + 5 * X + 6 : ℤ[X]) = (X + 2) * (X + 3) := by ring
-- At x = 2 the box is 3 by 4 by 5, holding 60 cubic cm.
example : (2 + 1 : ℤ) * (2 + 2) * (2 + 3) = 60 ∧ (3 * 4 * 5 : ℤ) = 60 := by decide
-- The same box divided by x - 2: quotient x^2 + 8x + 27, remainder 60.
example : (X ^ 3 + 6 * X ^ 2 + 11 * X + 6 : ℤ[X]) = (X - 2) * (X ^ 2 + 8 * X + 27) + 60 := by
  ring
-- The volume at the root -1 of x + 1 is 0, at 2 it is 60, and at 1 (the wrong sign) it is 24.
example : (X ^ 3 + 6 * X ^ 2 + 11 * X + 6 : ℤ[X]).eval (-1) = 0 ∧
    (X ^ 3 + 6 * X ^ 2 + 11 * X + 6 : ℤ[X]).eval 2 = 60 ∧
    (X ^ 3 + 6 * X ^ 2 + 11 * X + 6 : ℤ[X]).eval 1 = 24 := by norm_num
-- The chart: for r = -3 to 3, the volume at r is 0, 0, 0, 6, 24, 60, 120.
example : [-3, -2, -1, 0, 1, 2, 3].map (fun x : ℤ => x ^ 3 + 6 * x ^ 2 + 11 * x + 6) =
    [0, 0, 0, 6, 24, 60, 120] := by decide
-- Drop the degree rule and the pair is not unique: quotient x^2 + 5x, leftover 6x + 6.
example : (X ^ 3 + 6 * X ^ 2 + 11 * X + 6 : ℤ[X]) = (X + 1) * (X ^ 2 + 5 * X) + (6 * X + 6) := by
  ring
-- Plain numbers at x = 10: the box is 11 by 12 by 13, and 1716 / 11 = 156 with nothing left.
example : (11 * 12 * 13 : ℕ) = 1716 ∧ 1716 / 11 = 156 ∧ 1716 % 11 = 0 ∧
    (10 ^ 2 + 5 * 10 + 6 : ℕ) = 156 := by decide

#print axioms polynomial_division_with_remainder_exists_and_is_unique
#print axioms dividing_by_x_minus_r_leaves_p_of_r
#print axioms remainder_on_dividing_by_x_minus_r_is_p_of_r
