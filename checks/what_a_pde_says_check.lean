-- A partial differential equation: the family of A u_xx + B u_xy + C u_yy, read from the sign of B^2 - 4AC, survives every change of variables with nonzero Jacobian, and that sign decides whether the direction form A p^2 + B p q + C q^2 takes both signs (hyperbolic) or never vanishes (elliptic).
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp

/-- No change of variables changes the family.  New variables ξ(x, y), η(x, y) with
partial derivatives ξ_x = p, ξ_y = q, η_x = r, η_y = s at a point, and Jacobian
J = p s - q r ≠ 0, turn the top-order part A u_xx + B u_xy + C u_yy into
A' u_ξξ + B' u_ξη + C' u_ηη by the chain rule.  Then B'^2 - 4A'C' has the same sign
as B^2 - 4AC: positive stays hyperbolic, zero stays parabolic, negative stays elliptic. -/
theorem pde_family_unchanged_by_change_of_variables (A B C p q r s : ℝ)
    (hJ : p * s - q * r ≠ 0) :
    let A' := A * p ^ 2 + B * p * q + C * q ^ 2
    let B' := 2 * A * p * r + B * (p * s + q * r) + 2 * C * q * s
    let C' := A * r ^ 2 + B * r * s + C * s ^ 2
    (0 < B' ^ 2 - 4 * A' * C' ↔ 0 < B ^ 2 - 4 * A * C) ∧
    (B' ^ 2 - 4 * A' * C' = 0 ↔ B ^ 2 - 4 * A * C = 0) ∧
    (B' ^ 2 - 4 * A' * C' < 0 ↔ B ^ 2 - 4 * A * C < 0) := by
  intro A' B' C'
  have key : B' ^ 2 - 4 * A' * C' = (p * s - q * r) ^ 2 * (B ^ 2 - 4 * A * C) := by
    simp only [A', B', C']; ring
  have hJ2 : 0 < (p * s - q * r) ^ 2 := by positivity
  rw [key]
  refine ⟨?_, ?_, ?_⟩
  · constructor
    · intro h; exact pos_of_mul_pos_right h hJ2.le
    · intro h; exact mul_pos hJ2 h
  · constructor
    · intro h
      rcases mul_eq_zero.mp h with h' | h'
      · exact absurd h' hJ2.ne'
      · exact h'
    · intro h; rw [h, mul_zero]
  · constructor
    · intro h
      by_contra hc
      rw [not_lt] at hc
      have := mul_nonneg hJ2.le hc
      linarith
    · intro h; exact mul_neg_of_pos_of_neg hJ2 h

/-- Elliptic means no characteristic direction: B^2 - 4AC < 0 exactly when the
direction form Q(p, q) = A p^2 + B p q + C q^2 is nonzero in every direction (p, q) ≠ (0, 0). -/
theorem elliptic_iff_no_characteristic_direction (A B C : ℝ) :
    B ^ 2 - 4 * A * C < 0 ↔
      ∀ p q : ℝ, (p, q) ≠ (0, 0) → A * p ^ 2 + B * p * q + C * q ^ 2 ≠ 0 := by
  constructor
  · intro hD p q hpq hQ
    have hA : A ≠ 0 := by
      intro hA; subst hA; nlinarith [sq_nonneg B]
    have h4 : (2 * A * p + B * q) ^ 2 - (B ^ 2 - 4 * A * C) * q ^ 2 = 0 := by
      linear_combination (4 * A) * hQ
    have hq2 : q ^ 2 = 0 := by
      nlinarith [sq_nonneg (2 * A * p + B * q), sq_nonneg q]
    have hq : q = 0 := by simpa using hq2
    subst hq
    have hp : p = 0 := by
      have : A * p ^ 2 = 0 := by simpa using hQ
      rcases mul_eq_zero.mp this with h | h
      · exact absurd h hA
      · simpa using h
    exact hpq (by simp [hp])
  · intro h
    by_contra hD
    rw [not_lt] at hD
    by_cases hA : A = 0
    · exact h 1 0 (by simp) (by simp [hA])
    · set D := B ^ 2 - 4 * A * C with hDdef
      have hs : Real.sqrt D ^ 2 = D := Real.sq_sqrt hD
      have hp : 2 * A * ((-B + Real.sqrt D) / (2 * A)) = -B + Real.sqrt D := by
        field_simp
      apply h ((-B + Real.sqrt D) / (2 * A)) 1 (by simp)
      have h4 : 4 * A * (A * ((-B + Real.sqrt D) / (2 * A)) ^ 2
          + B * ((-B + Real.sqrt D) / (2 * A)) * 1 + C * 1 ^ 2) = 0 := by
        have e : 4 * A * (A * ((-B + Real.sqrt D) / (2 * A)) ^ 2
            + B * ((-B + Real.sqrt D) / (2 * A)) * 1 + C * 1 ^ 2)
            = (2 * A * ((-B + Real.sqrt D) / (2 * A)) + B) ^ 2 - D := by
          rw [hDdef]; ring
        rw [e, hp, hDdef] at *
        nlinarith [hs]
      rcases mul_eq_zero.mp h4 with h' | h'
      · exact absurd (by linarith : A = 0) hA
      · exact h'

/-- Hyperbolic means the direction form takes both signs: B^2 - 4AC > 0 exactly when
Q(p, q) = A p^2 + B p q + C q^2 is positive in some direction and negative in another. -/
theorem hyperbolic_iff_form_takes_both_signs (A B C : ℝ) :
    0 < B ^ 2 - 4 * A * C ↔
      (∃ p q : ℝ, 0 < A * p ^ 2 + B * p * q + C * q ^ 2) ∧
      (∃ p q : ℝ, A * p ^ 2 + B * p * q + C * q ^ 2 < 0) := by
  constructor
  · intro hD
    rcases lt_trichotomy A 0 with hA | hA | hA
    · refine ⟨⟨-B, 2 * A, ?_⟩, ⟨1, 0, ?_⟩⟩
      · nlinarith [mul_pos (neg_pos.mpr hA) hD]
      · simpa using hA
    · subst hA
      rcases lt_trichotomy C 0 with hC | hC | hC
      · refine ⟨⟨2 * C, -B, ?_⟩, ⟨0, 1, ?_⟩⟩
        · nlinarith [mul_pos (neg_pos.mpr hC) hD]
        · simpa using hC
      · subst hC
        have hB : B ≠ 0 := by rintro rfl; norm_num at hD
        rcases lt_or_gt_of_ne hB with hB | hB
        · exact ⟨⟨1, -1, by nlinarith⟩, ⟨1, 1, by nlinarith⟩⟩
        · exact ⟨⟨1, 1, by nlinarith⟩, ⟨1, -1, by nlinarith⟩⟩
      · refine ⟨⟨0, 1, ?_⟩, ⟨2 * C, -B, ?_⟩⟩
        · simpa using hC
        · nlinarith [mul_pos hC hD]
    · refine ⟨⟨1, 0, ?_⟩, ⟨-B, 2 * A, ?_⟩⟩
      · simpa using hA
      · nlinarith [mul_pos hA hD]
  · rintro ⟨⟨p1, q1, h1⟩, ⟨p2, q2, h2⟩⟩
    by_contra hD
    rw [not_lt] at hD
    have a1 : 0 ≤ A * (A * p1 ^ 2 + B * p1 * q1 + C * q1 ^ 2) := by
      nlinarith [sq_nonneg (2 * A * p1 + B * q1), mul_nonneg (sub_nonneg.mpr hD) (sq_nonneg q1)]
    have a2 : 0 ≤ A * (A * p2 ^ 2 + B * p2 * q2 + C * q2 ^ 2) := by
      nlinarith [sq_nonneg (2 * A * p2 + B * q2), mul_nonneg (sub_nonneg.mpr hD) (sq_nonneg q2)]
    have c1 : 0 ≤ C * (A * p1 ^ 2 + B * p1 * q1 + C * q1 ^ 2) := by
      nlinarith [sq_nonneg (2 * C * q1 + B * p1), mul_nonneg (sub_nonneg.mpr hD) (sq_nonneg p1)]
    have c2 : 0 ≤ C * (A * p2 ^ 2 + B * p2 * q2 + C * q2 ^ 2) := by
      nlinarith [sq_nonneg (2 * C * q2 + B * p2), mul_nonneg (sub_nonneg.mpr hD) (sq_nonneg p2)]
    have hA : A = 0 := by
      have : 0 ≤ A := nonneg_of_mul_nonneg_left a1 h1
      have : A ≤ 0 := by nlinarith
      linarith
    have hC : C = 0 := by
      have : 0 ≤ C := nonneg_of_mul_nonneg_left c1 h1
      have : C ≤ 0 := by nlinarith
      linarith
    subst hA; subst hC
    have hB : B = 0 := by nlinarith [sq_nonneg B]
    subst hB
    simp at h1

-- The card's worked discriminants, B^2 - 4AC, in whole numbers.
-- Rod u_xx - u_t = 0: A = 1, B = 0, C = 0 gives 0, parabolic.
example : (0 : ℤ) ^ 2 - 4 * 1 * 0 = 0 := by norm_num
-- String u_xx - u_tt = 0: A = 1, B = 0, C = -1 gives 4, hyperbolic.
example : (0 : ℤ) ^ 2 - 4 * 1 * (-1) = 4 := by norm_num
-- Plate u_xx + u_yy = 0: A = 1, B = 0, C = 1 gives -4, elliptic.
example : (0 : ℤ) ^ 2 - 4 * 1 * 1 = -4 := by norm_num
-- Tricomi at y = -1: A = -1, B = 0, C = 1 gives 4, hyperbolic.
example : (0 : ℤ) ^ 2 - 4 * (-1) * 1 = 4 := by norm_num
-- The usual mistake, u_xx + 3u_xy + u_yy: 9 - 4 = 5, hyperbolic.
example : (3 : ℤ) ^ 2 - 4 * 1 * 1 = 5 := by norm_num
-- Tilted u_xx + 2u_xy + u_yy: 4 - 4 = 0, parabolic.
example : (2 : ℤ) ^ 2 - 4 * 1 * 1 = 0 := by norm_num
-- The wave with ξ = x + t, η = x - t: p = q = r = 1, s = -1, so J = -2,
-- and A = 1, B = 0, C = -1 becomes A' = 0, B' = 4, C' = 0, that is 4 u_ξη = 0.
example : (1 : ℤ) * (-1) - 1 * 1 = -2 := by norm_num
example : (1 : ℤ) * 1 ^ 2 + 0 * 1 * 1 + (-1) * 1 ^ 2 = 0 := by norm_num
example : 2 * (1 : ℤ) * 1 * 1 + 0 * (1 * (-1) + 1 * 1) + 2 * (-1) * 1 * (-1) = 4 := by norm_num
example : (1 : ℤ) * 1 ^ 2 + 0 * 1 * (-1) + (-1) * (-1) ^ 2 = 0 := by norm_num
-- And the discriminant scales by J^2 = 4: 4^2 - 4 * 0 * 0 = 4 * 4.
example : (4 : ℤ) ^ 2 - 4 * 0 * 0 = (-2) ^ 2 * 4 := by norm_num

#print axioms pde_family_unchanged_by_change_of_variables
#print axioms elliptic_iff_no_characteristic_direction
#print axioms hyperbolic_iff_form_takes_both_signs
