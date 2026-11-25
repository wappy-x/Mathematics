-- Intersection numbers on a surface: in any symmetric pairing where a line misses E and a lifted line through p meets E once, E squared is -1, and on the blow-up lattice ZH + ZE adjunction gives the genus formula and the Hodge index sign rule holds.
import Mathlib.LinearAlgebra.Matrix.SesquilinearForm
import Mathlib.LinearAlgebra.BilinearForm.Properties
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith

open Matrix

/-- The intersection pairing on the plane blown up at one point, Pic(X) = ZH + ZE,
with Gram matrix [[1, 0], [0, -1]] in the basis H, E: a class `![a, b]` is aH + bE. -/
abbrev blowupPairing : LinearMap.BilinForm ℤ (Fin 2 → ℤ) :=
  Matrix.toLinearMap₂' ℤ !![1, 0; 0, -1]

/-- E squared is minus one. Take any symmetric pairing on divisor classes (bilinear, so it
adds up over sums of curves). If a line H misses E (H · E = 0), two lines meet once
(H² = 1), and the strict transform H - E of a line through p meets E exactly once
((H - E) · E = 1), then E² = -1, and two lifted lines through p are disjoint:
(H - E)² = 0. -/
theorem exceptional_curve_self_intersection_eq_neg_one
    {M : Type*} [AddCommGroup M] (B : LinearMap.BilinForm ℤ M) (hB : B.IsSymm)
    (H E : M) (hHH : B H H = 1) (hHE : B H E = 0) (hLE : B (H - E) E = 1) :
    B E E = -1 ∧ B (H - E) (H - E) = 0 := by
  have hEH : B E H = 0 := by rw [hB.eq]; exact hHE
  have h1 : B (H - E) E = B H E - B E E := by simp
  have hEE : B E E = -1 := by linarith
  refine ⟨hEE, ?_⟩
  simp only [map_sub, LinearMap.sub_apply]
  rw [hHH, hHE, hEH, hEE]; norm_num

/-- Adjunction on the blow-up: with K = -3H + E, a curve of degree d with multiplicity m at p
has class C = dH - mE, and C² + K · C = 2g - 2 with g = (d - 1)(d - 2)/2 - m(m - 1)/2. -/
theorem blowup_adjunction_genus (d m : ℤ) :
    blowupPairing ![d, -m] ![d, -m] + blowupPairing ![-3, 1] ![d, -m] =
      (d - 1) * (d - 2) - m * (m - 1) - 2 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec]
  ring

/-- The Hodge index theorem on the blow-up: the pairing has one positive direction.
If A² > 0 and A · D = 0 for a nonzero class D, then D² < 0. -/
theorem blowup_hodge_index (A D : Fin 2 → ℤ) (hA : 0 < blowupPairing A A)
    (hAD : blowupPairing A D = 0) (hD : D ≠ 0) :
    blowupPairing D D < 0 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec] at hA hAD ⊢
  have hd : D 1 ≠ 0 := by
    intro hd
    apply hD
    have ha : A 0 ≠ 0 := by
      intro ha; rw [ha] at hA; nlinarith [sq_nonneg (A 1)]
    have hc : D 0 = 0 := by
      rw [hd] at hAD
      have : A 0 * D 0 = 0 := by linarith
      rcases mul_eq_zero.mp this with h | h
      · exact absurd h ha
      · exact h
    funext i; fin_cases i <;> simp [hc, hd]
  have hd2 : 0 < D 1 * D 1 := mul_self_pos.mpr hd
  have key : A 0 * A 0 * (D 0 * D 0 - D 1 * D 1) = D 1 * D 1 * (A 1 * A 1 - A 0 * A 0) := by
    have : A 0 * D 0 = A 1 * D 1 := by linarith
    linear_combination (A 0 * D 0 + A 1 * D 1) * this
  have hneg : D 1 * D 1 * (A 1 * A 1 - A 0 * A 0) < 0 :=
    mul_neg_of_pos_of_neg hd2 (by nlinarith)
  have hA0 : 0 < A 0 * A 0 := by nlinarith [sq_nonneg (A 1)]
  by_contra hc
  have hc' : 0 ≤ D 0 * D 0 - D 1 * D 1 := by linarith [not_lt.mp hc]
  nlinarith [mul_nonneg hA0.le hc']

-- H² = 1, H · E = 0, E² = -1 on the blow-up lattice.
example : blowupPairing ![1, 0] ![1, 0] = 1 ∧ blowupPairing ![1, 0] ![0, 1] = 0 ∧
    blowupPairing ![0, 1] ![0, 1] = -1 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec]

-- (H - E) · E = 1 and (H - E)² = 0: the lifted line meets E once, two lifted lines are disjoint.
example : blowupPairing ![1, -1] ![0, 1] = 1 ∧ blowupPairing ![1, -1] ![1, -1] = 0 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec]

-- K = -3H + E: K² = 9 - 1 = 8, and Noether K² + e(X) = 8 + 4 = 12.
example : blowupPairing ![-3, 1] ![-3, 1] = 8 ∧ blowupPairing ![-3, 1] ![-3, 1] + 4 = 12 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec]

-- Adjunction for E: E² + K · E = -1 + (-1) = -2, so g = 0.
example : blowupPairing ![0, 1] ![0, 1] + blowupPairing ![-3, 1] ![0, 1] = -2 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec]

-- The nodal cubic 3H - 2E meets E, H - E and H in 2, 1 and 3 points; C² = 5, K · C = -7.
example : blowupPairing ![3, -2] ![0, 1] = 2 ∧ blowupPairing ![3, -2] ![1, -1] = 1 ∧
    blowupPairing ![3, -2] ![1, 0] = 3 ∧ blowupPairing ![3, -2] ![3, -2] = 5 ∧
    blowupPairing ![-3, 1] ![3, -2] = -7 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec]

-- Hodge index example: A = 3H - E has A² = 8, A · (H - 3E) = 0 and (H - 3E)² = -8.
example : blowupPairing ![3, -1] ![3, -1] = 8 ∧ blowupPairing ![3, -1] ![1, -3] = 0 ∧
    blowupPairing ![1, -3] ![1, -3] = -8 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec]

-- Riemann-Roch count of conics through p: 1 + (D² - K · D)/2 = 1 + (3 + 5)/2 = 5.
example : 1 + (blowupPairing ![2, -1] ![2, -1] - blowupPairing ![-3, 1] ![2, -1]) / 2 = 5 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_two, mulVec]

-- Six points blown up (the cubic surface): K = -3H + E₁ + ... + E₆ has K² = 9 - 6 = 3.
example : Matrix.toLinearMap₂' ℤ (Matrix.diagonal ![1, -1, -1, -1, -1, -1, -1])
    ![-3, 1, 1, 1, 1, 1, 1] ![-3, 1, 1, 1, 1, 1, 1] = 3 := by
  simp [Matrix.toLinearMap₂'_apply', dotProduct, Fin.sum_univ_succ, mulVec_diagonal]

#print axioms exceptional_curve_self_intersection_eq_neg_one
#print axioms blowup_adjunction_genus
#print axioms blowup_hodge_index
