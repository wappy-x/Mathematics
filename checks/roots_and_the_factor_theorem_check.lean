-- Roots and factors: over any commutative ring, p(r) = 0 exactly when x - r divides p, and over numbers with no zero divisors a polynomial that is not zero has at most as many different roots as its degree.
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Algebra.Polynomial.Div
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

open Polynomial

/-- The root ceiling. Work in numbers where a product is zero only when a factor is zero
(a commutative ring with no zero divisors, such as the whole numbers, fractions or reals).
A polynomial p that is not the flat zero, with degree n, has at most n different roots:
any finite set of different numbers that all make p come out zero has at most n members. -/
theorem polynomial_of_degree_n_has_at_most_n_roots {R : Type*} [CommRing R] [IsDomain R]
    (p : R[X]) (hp : p ≠ 0) (S : Finset R) (hS : ∀ r ∈ S, p.eval r = 0) :
    S.card ≤ p.natDegree := by
  classical
  calc S.card ≤ p.roots.toFinset.card :=
        Finset.card_le_card (fun r hr => by
          rw [Multiset.mem_toFinset, mem_roots hp]
          exact hS r hr)
    _ ≤ Multiset.card p.roots := Multiset.toFinset_card_le _
    _ ≤ p.natDegree := card_roots' p

/-- The factor theorem. A polynomial p comes out zero at r exactly when the bracket x - r
divides it with nothing left over: p(x) = (x - r) q(x) for some polynomial q. -/
theorem root_iff_x_minus_r_is_a_factor {R : Type*} [CommRing R] (p : R[X]) (r : R) :
    p.eval r = 0 ↔ ∃ q : R[X], p = (X - C r) * q := by
  exact (dvd_iff_isRoot (a := r) (p := p)).symm

/-- The remainder theorem (Step 0). Dividing p by x - r leaves a plain number, and that
number is p(r): p(x) = (x - r) q(x) + p(r) for some polynomial q. -/
theorem dividing_by_x_minus_r_leaves_p_of_r {R : Type*} [CommRing R] (p : R[X]) (r : R) :
    ∃ q : R[X], p = (X - C r) * q + C (p.eval r) := by
  refine ⟨p /ₘ (X - C r), ?_⟩
  rw [← modByMonic_X_sub_C_eq_C_eval, add_comm]
  exact (modByMonic_add_div p (q := X - C r)).symm

-- The tank's cubic x^3 - 6x^2 + 11x - 6 comes out 0 at 1, 2 and 3.
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℤ[X]).eval 1 = 0 ∧
    (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℤ[X]).eval 2 = 0 ∧
    (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℤ[X]).eval 3 = 0 := by norm_num
-- Peeling: the cubic is (x - 1)(x^2 - 5x + 6), and x^2 - 5x + 6 = (x - 2)(x - 3).
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℤ[X]) = (X - 1) * (X ^ 2 - 5 * X + 6) := by ring
example : (X ^ 2 - 5 * X + 6 : ℤ[X]) = (X - 2) * (X - 3) := by ring
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℤ[X]) = (X - 1) * (X - 2) * (X - 3) := by ring
-- The edges 1, 2, 3: sum 6, pairwise products 11, volume 6.
example : (1 + 2 + 3 : ℤ) = 6 ∧ (1 * 2 + 1 * 3 + 2 * 3 : ℤ) = 11 ∧ (1 * 2 * 3 : ℤ) = 6 := by decide
-- The cubic at -1 is -24 (so x + 1 is not a factor), and at 4 it is 6.
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℤ[X]).eval (-1) = -24 ∧
    (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℤ[X]).eval 4 = 6 := by norm_num
-- At the divisors of 6, the cubic is -504, -120, -60, -24, 0, 0, 0 and 60.
example : [-6, -3, -2, -1, 1, 2, 3, 6].map (fun x : ℤ => x ^ 3 - 6 * x ^ 2 + 11 * x - 6) =
    [-504, -120, -60, -24, 0, 0, 0, 60] := by decide
-- The sweep from -20 to 20: the tank's cubic is zero only at 1, 2, 3.
example : ∀ x ∈ Finset.Icc (-20 : ℤ) 20,
    (x ^ 3 - 6 * x ^ 2 + 11 * x - 6 = 0 ↔ x = 1 ∨ x = 2 ∨ x = 3) := by decide
-- Volume 12: x^3 - 6x^2 + 11x - 12 is zero only at 4 in the sweep.
example : ∀ x ∈ Finset.Icc (-20 : ℤ) 20, (x ^ 3 - 6 * x ^ 2 + 11 * x - 12 = 0 ↔ x = 4) := by
  decide
-- The repeated root: x^3 - 6x^2 + 9x - 4 = (x - 1)(x - 1)(x - 4), zero only at 1 and 4.
example : (X ^ 3 - 6 * X ^ 2 + 9 * X - 4 : ℤ[X]) = (X - 1) * (X - 1) * (X - 4) := by ring
example : ∀ x ∈ Finset.Icc (-20 : ℤ) 20, (x ^ 3 - 6 * x ^ 2 + 9 * x - 4 = 0 ↔ x = 1 ∨ x = 4) := by
  decide
-- Clock arithmetic breaks the ceiling: on a 12-hour clock, x^2 - 1 (degree 2) has 4 roots.
example : ∀ x : ZMod 12, (x ^ 2 - 1 = 0 ↔ x = 1 ∨ x = 5 ∨ x = 7 ∨ x = 11) := by decide

#print axioms polynomial_of_degree_n_has_at_most_n_roots
#print axioms root_iff_x_minus_r_is_a_factor
#print axioms dividing_by_x_minus_r_leaves_p_of_r
