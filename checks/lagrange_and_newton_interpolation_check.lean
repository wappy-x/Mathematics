-- One polynomial through n points: exactly one polynomial of degree at most n passes through n + 1 points with different x-values, the Vandermonde determinant is the product of the node gaps, and the divided-difference rule gives the interpolant's leading coefficient.
import Mathlib.LinearAlgebra.Vandermonde
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum

open Polynomial Finset

theorem deg_le_iff_lt_succ (p : ℝ[X]) (n : ℕ) : p.degree ≤ n ↔ p.degree < ↑(n + 1) := by
  constructor
  · intro h
    exact lt_of_le_of_lt h (by exact_mod_cast Nat.lt_succ_self n)
  · intro h
    rw [Polynomial.degree_le_iff_coeff_zero]
    rw [Polynomial.degree_lt_iff_coeff_zero] at h
    intro m hm
    exact h m (by exact_mod_cast hm)

#print axioms deg_le_iff_lt_succ

theorem eq_C_mul_prod_of_eval_eq_zero (T : Finset ℝ) (p : ℝ[X]) (hp : p.degree ≤ #T)
    (h : ∀ t ∈ T, p.eval t = 0) : p = C (p.coeff #T) * ∏ t ∈ T, (X - C t) := by
  have hW : (∏ t ∈ T, (X - C t)).Monic := monic_prod_X_sub_C (fun t => t) T
  have hWd : (∏ t ∈ T, (X - C t)).natDegree = #T := by
    rw [natDegree_prod_of_monic _ _ (fun t _ => monic_X_sub_C t)]
    simp
  rw [← sub_eq_zero]
  refine Polynomial.eq_zero_of_degree_lt_of_eval_finset_eq_zero T ?_ ?_
  · rw [Polynomial.degree_lt_iff_coeff_zero]
    intro m hm
    rw [coeff_sub, coeff_C_mul]
    rcases hm.eq_or_lt with hm | hm
    · subst hm
      rw [← hWd, hW.coeff_natDegree, hWd]; ring
    · have e1 : (∏ t ∈ T, (X - C t)).coeff m = 0 :=
        coeff_eq_zero_of_natDegree_lt (by rw [hWd]; exact hm)
      have e2 : p.coeff m = 0 := coeff_eq_zero_of_degree_lt (lt_of_le_of_lt hp (by exact_mod_cast hm))
      rw [e1, e2]
      ring
  · intro t ht
    rw [eval_sub, eval_mul, eval_prod, prod_eq_zero ht (by simp), h t ht]
    ring

#print axioms eq_C_mul_prod_of_eval_eq_zero

/-- Through n + 1 points whose x-values (the nodes) are all different passes exactly one
polynomial of degree at most n. -/
theorem exists_unique_interpolating_polynomial (n : ℕ) (x y : Fin (n + 1) → ℝ)
    (hx : Function.Injective x) :
    ∃! p : ℝ[X], p.degree ≤ n ∧ ∀ j, p.eval (x j) = y j := by
  refine ⟨Lagrange.interpolate Finset.univ x y, ⟨?_, ?_⟩, ?_⟩
  · rw [deg_le_iff_lt_succ]
    have := Lagrange.degree_interpolate_lt (s := Finset.univ) (r := y) hx.injOn
    simpa using this
  · intro j
    exact Lagrange.eval_interpolate_at_node y hx.injOn (mem_univ j)
  · rintro q ⟨hq, hqe⟩
    have hp : (Lagrange.interpolate Finset.univ x y).degree ≤ n := by
      rw [deg_le_iff_lt_succ]
      have := Lagrange.degree_interpolate_lt (s := Finset.univ) (r := y) hx.injOn
      simpa using this
    refine Polynomial.eq_of_degree_sub_lt_of_eval_finset_eq (Finset.univ.image x) ?_ ?_
    · rw [card_image_of_injective _ hx, card_univ, Fintype.card_fin, ← deg_le_iff_lt_succ]
      exact (degree_sub_le _ _).trans (max_le hq hp)
    · intro t ht
      obtain ⟨j, -, rfl⟩ := mem_image.1 ht
      rw [hqe j, Lagrange.eval_interpolate_at_node y hx.injOn (mem_univ j)]

/-- The Vandermonde matrix, whose row j holds 1, x_j, x_j^2, ..., x_j^n, has determinant equal
to the product of every gap x_j - x_i with i < j; so it is zero exactly when two nodes coincide. -/
theorem det_vandermonde_eq_prod_node_gaps (n : ℕ) (x : Fin (n + 1) → ℝ) :
    (Matrix.vandermonde x).det = ∏ i : Fin (n + 1), ∏ j ∈ Ioi i, (x j - x i) ∧
      ((Matrix.vandermonde x).det ≠ 0 ↔ Function.Injective x) := by
  exact ⟨Matrix.det_vandermonde x, Matrix.det_vandermonde_ne_zero_iff⟩

/-- The divided-difference rule. Take different nodes: a shared set S of inner nodes and two end
nodes a ≠ b outside it. Let r be the interpolant of f through S and b, s the interpolant through
a and S (degree at most #S each), and P the interpolant through a, S and b (degree at most
#S + 1). Then P's leading coefficient is (r's leading coefficient - s's leading coefficient)
divided by (b - a). -/
theorem divided_difference_rule (f : ℝ → ℝ) (S : Finset ℝ) (a b : ℝ) (hab : a ≠ b)
    (ha : a ∉ S) (hb : b ∉ S) (r s P : ℝ[X])
    (hr : r.degree ≤ #S ∧ ∀ t ∈ insert b S, r.eval t = f t)
    (hs : s.degree ≤ #S ∧ ∀ t ∈ insert a S, s.eval t = f t)
    (hP : P.degree ≤ ↑(#S + 1) ∧ ∀ t ∈ insert a (insert b S), P.eval t = f t) :
    P.coeff (#S + 1) = (r.coeff #S - s.coeff #S) / (b - a) := by
  have hSle : ((#S : ℕ) : WithBot ℕ) ≤ ((#S + 1 : ℕ) : WithBot ℕ) := by exact_mod_cast Nat.le_succ _
  have hsc : s.coeff (#S + 1) = 0 :=
    coeff_eq_zero_of_degree_lt (lt_of_le_of_lt hs.1 (by exact_mod_cast Nat.lt_succ_self _))
  have hrc : r.coeff (#S + 1) = 0 :=
    coeff_eq_zero_of_degree_lt (lt_of_le_of_lt hr.1 (by exact_mod_cast Nat.lt_succ_self _))
  have h1 := eq_C_mul_prod_of_eval_eq_zero (insert a S) (P - s) (by
      rw [card_insert_of_notMem ha]
      exact (degree_sub_le _ _).trans (max_le hP.1 (hs.1.trans hSle)))
    (by
      intro t ht
      rw [eval_sub, sub_eq_zero, hs.2 t ht]
      apply hP.2
      rcases mem_insert.1 ht with h | h
      · rw [h]; exact mem_insert_self _ _
      · exact mem_insert_of_mem (mem_insert_of_mem h))
  have h2 := eq_C_mul_prod_of_eval_eq_zero (insert b S) (P - r) (by
      rw [card_insert_of_notMem hb]
      exact (degree_sub_le _ _).trans (max_le hP.1 (hr.1.trans hSle)))
    (by
      intro t ht
      rw [eval_sub, sub_eq_zero, hr.2 t ht]
      exact hP.2 t (mem_insert_of_mem ht))
  rw [card_insert_of_notMem ha, coeff_sub, hsc, sub_zero, prod_insert ha] at h1
  rw [card_insert_of_notMem hb, coeff_sub, hrc, sub_zero, prod_insert hb] at h2
  set M := ∏ t ∈ S, (X - C t) with hM
  set c := P.coeff (#S + 1)
  have hMm : M.Monic := monic_prod_X_sub_C (fun t => t) S
  have hMd : M.natDegree = #S := by
    rw [hM, natDegree_prod_of_monic _ _ (fun t _ => monic_X_sub_C t)]
    simp
  have key : r - s = C (c * (b - a)) * M := by
    have : r - s = (P - s) - (P - r) := by ring
    rw [this, h1, h2, C_mul, C_sub]
    ring
  have hcoef := congrArg (fun q => q.coeff #S) key
  simp only [coeff_sub, coeff_C_mul] at hcoef
  rw [← hMd, hMm.coeff_natDegree, hMd] at hcoef
  rw [hcoef]
  have : b - a ≠ 0 := sub_ne_zero.2 (Ne.symm hab)
  field_simp

/-! Worked numbers from the card: nodes 1, 2, 3, 5, 10 years, quotes 4.20, 3.95, 3.85, 3.90,
4.15 percent, written as exact fractions 21/5, 79/20, 77/20, 39/10, 83/20. -/

-- det V = product of node gaps = 120960.
example : ∏ i : Fin 5, ∏ j ∈ Ioi i, ((![1, 2, 3, 5, 10] : Fin 5 → ℤ) j - ![1, 2, 3, 5, 10] i)
    = 120960 := by decide

-- The monomial form a0 + a1 t + ... + a4 t^4 hits all five quotes and reads 1699/420 at 7 years.
example :
    let p : ℚ → ℚ := fun t => 979/210 - 1489/2520 * t + 89/630 * t^2 - 4/315 * t^3 + 1/2520 * t^4
    p 1 = 21/5 ∧ p 2 = 79/20 ∧ p 3 = 77/20 ∧ p 5 = 39/10 ∧ p 10 = 83/20 ∧ p 7 = 1699/420 := by
  norm_num

-- Divided differences: level 1, then the Newton coefficients 4.20, -0.25, 0.075, -1/120, 1/2520.
example : ((79/20 : ℚ) - 21/5) / (2 - 1) = -1/4 ∧ ((77/20 : ℚ) - 79/20) / (3 - 2) = -1/10 ∧
    ((39/10 : ℚ) - 77/20) / (5 - 3) = 1/40 ∧ ((83/20 : ℚ) - 39/10) / (10 - 5) = 1/20 := by
  norm_num
example : ((-1/10 : ℚ) - -1/4) / (3 - 1) = 3/40 ∧ ((1/40 : ℚ) - -1/10) / (5 - 2) = 1/24 ∧
    ((1/20 : ℚ) - 1/40) / (10 - 3) = 1/280 := by
  norm_num
example : ((1/24 : ℚ) - 3/40) / (5 - 1) = -1/120 ∧ ((1/280 : ℚ) - 1/24) / (10 - 2) = -1/210 ∧
    ((-1/210 : ℚ) - -1/120) / (10 - 1) = 1/2520 := by
  norm_num

-- Newton form at 7 years: 4.2 - 1.5 + 2.25 - 1.0 + 2/21 = 1699/420.
example : (21/5 : ℚ) + (-1/4) * 6 + 3/40 * (6 * 5) + (-1/120) * (6 * 5 * 4)
    + 1/2520 * (6 * 5 * 4 * 2) = 1699/420 := by
  norm_num

-- Lagrange weights at 7 years: -5/3, 6, -45/7, 3, 2/21; they add to 1, and the weighted
-- sum of the quotes is 1699/420.
example :
    let l : ℚ → ℚ → ℚ → ℚ → ℚ → ℚ := fun xj a b c d => (7 - a) * (7 - b) * (7 - c) * (7 - d) /
      ((xj - a) * (xj - b) * (xj - c) * (xj - d))
    l 1 2 3 5 10 = -5/3 ∧ l 2 1 3 5 10 = 6 ∧ l 3 1 2 5 10 = -45/7 ∧ l 5 1 2 3 10 = 3 ∧
      l 10 1 2 3 5 = 2/21 ∧ (-5/3 : ℚ) + 6 + -45/7 + 3 + 2/21 = 1 ∧
      (21/5 : ℚ) * (-5/3) + 79/20 * 6 + 77/20 * (-45/7) + 39/10 * 3 + 83/20 * (2/21) = 1699/420 := by
  norm_num

-- Without the degree cap: omega(7) = -720, so adding omega(x)/10000 moves the 7-year reading
-- to 1699/420 - 720/10000 = 41719/10500 (3.973238...).
example : ((7 : ℚ) - 1) * (7 - 2) * (7 - 3) * (7 - 5) * (7 - 10) = -720 ∧
    (1699/420 : ℚ) + 1/10000 * (-720) = 41719/10500 := by
  norm_num

-- Coefficients rounded to four decimals: the 10-year reading becomes 4.1829, not 4.15.
example : (46619/10000 : ℚ) - 5909/10000 * 10 + 1413/10000 * 10^2 - 127/10000 * 10^3
    + 4/10000 * 10^4 = 41829/10000 := by
  norm_num

-- Extrapolation: the curve reads 1853/20 = 92.65 percent at 30 years.
example : (979/210 : ℚ) - 1489/2520 * 30 + 89/630 * 30^2 - 4/315 * 30^3 + 1/2520 * 30^4
    = 1853/20 := by
  norm_num

#print axioms exists_unique_interpolating_polynomial
#print axioms det_vandermonde_eq_prod_node_gaps
#print axioms divided_difference_rule
