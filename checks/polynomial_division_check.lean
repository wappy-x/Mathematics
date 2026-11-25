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
-- The tray: x cm cut from each corner of a 30 by 20 card holds x(30 - 2x)(20 - 2x) cubic cm,
-- and that minus one litre is p = 4x^3 - 100x^2 + 600x - 1000.
example : (X * (30 - 2 * X) * (20 - 2 * X) - 1000 : ℤ[X]) =
    4 * X ^ 3 - 100 * X ^ 2 + 600 * X - 1000 := by ring
-- A 5 cm cut holds a litre: 5 by 20 by 10.
example : (5 : ℤ) * (30 - 2 * 5) * (20 - 2 * 5) = 1000 := by decide
-- p divided by x - 5 is 4x^2 - 80x + 200, remainder 0.
example : (4 * X ^ 3 - 100 * X ^ 2 + 600 * X - 1000 : ℤ[X]) =
    (X - 5) * (4 * X ^ 2 - 80 * X + 200) + 0 := by ring
-- The loop's leftovers: after 4x^2 lots of x - 5, then -80x lots, then 200 lots.
example : (4 * X ^ 3 - 100 * X ^ 2 + 600 * X - 1000 : ℤ[X]) - 4 * X ^ 2 * (X - 5) =
    -80 * X ^ 2 + 600 * X - 1000 := by ring
example : (-80 * X ^ 2 + 600 * X - 1000 : ℤ[X]) - (-80) * X * (X - 5) = 200 * X - 1000 := by ring
example : (200 * X - 1000 : ℤ[X]) - 200 * (X - 5) = 0 := by ring
-- The same p divided by x - 4: quotient 4x^2 - 84x + 264, remainder 56.
example : (4 * X ^ 3 - 100 * X ^ 2 + 600 * X - 1000 : ℤ[X]) =
    (X - 4) * (4 * X ^ 2 - 84 * X + 264) + 56 := by ring
-- p at 5 is 0, at 4 it is 56 (the 4 by 22 by 12 tray holds 1056), and at -5 (the wrong sign) -7000.
example : (4 * X ^ 3 - 100 * X ^ 2 + 600 * X - 1000 : ℤ[X]).eval 5 = 0 ∧
    (4 * X ^ 3 - 100 * X ^ 2 + 600 * X - 1000 : ℤ[X]).eval 4 = 56 ∧
    (4 * X ^ 3 - 100 * X ^ 2 + 600 * X - 1000 : ℤ[X]).eval (-5) = -7000 := by norm_num
example : (4 * 22 * 12 : ℤ) = 1056 := by decide
-- The chart: for r = 0 to 10, p(r) is -1000, -496, -168, 8, 56, 0, -136, -328, -552, -784, -1000.
example : [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map
    (fun x : ℤ => 4 * x ^ 3 - 100 * x ^ 2 + 600 * x - 1000) =
    [-1000, -496, -168, 8, 56, 0, -136, -328, -552, -784, -1000] := by decide
-- Drop the degree rule and the pair is not unique: quotient 4x^2 - 80x, leftover 200x - 1000.
example : (4 * X ^ 3 - 100 * X ^ 2 + 600 * X - 1000 : ℤ[X]) =
    (X - 5) * (4 * X ^ 2 - 80 * X) + (200 * X - 1000) := by ring
-- Plain numbers at x = 20: p is 3000, x - 5 is 15, and 3000 / 15 = 200 with nothing left, the quotient at 20.
example : (4 * 20 ^ 3 - 100 * 20 ^ 2 + 600 * 20 - 1000 : ℤ) = 3000 ∧ (3000 : ℤ) / 15 = 200 ∧
    (3000 : ℤ) % 15 = 0 ∧ (4 * 20 ^ 2 - 80 * 20 + 200 : ℤ) = 200 := by decide

#print axioms polynomial_division_with_remainder_exists_and_is_unique
#print axioms dividing_by_x_minus_r_leaves_p_of_r
#print axioms remainder_on_dividing_by_x_minus_r_is_p_of_r
