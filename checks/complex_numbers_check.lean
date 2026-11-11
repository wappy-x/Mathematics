-- Complex numbers: in the complex numbers i times i is -1, adding a + bi and c + di goes part by part, the product is (ac - bd) + (ad + bc)i, multiplying by i turns a point a quarter turn about 0, and no ordering of the complex numbers respects multiplying.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Algebra.Order.Ring.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Complex

/-- The rules of complex arithmetic. The new number i has i × i = -1. For any real numbers
a, b, c, d, the point a + bi plus the point c + di is (a + c) + (b + d)i, and their product is
(ac - bd) + (ad + bc)i: the east part ac minus bd, the north part ad plus bc. -/
theorem complex_add_and_mul_rules (a b c d : ℝ) :
    I * I = -1 ∧
    ((a : ℂ) + b * I) + ((c : ℂ) + d * I) = ((a + c : ℝ) : ℂ) + ((b + d : ℝ) : ℂ) * I ∧
    ((a : ℂ) + b * I) * ((c : ℂ) + d * I) = ((a * c - b * d : ℝ) : ℂ) + ((a * d + b * c : ℝ) : ℂ) * I := by
  refine ⟨Complex.I_mul_I, ?_, ?_⟩
  · push_cast; ring
  · push_cast; ring_nf; rw [Complex.I_sq]; ring

/-- Multiplying by i is a quarter turn. For any real a and b, i(a + bi) = -b + ai: the point
(a, b) moves to (-b, a). It stays the same distance from 0, and the two arrows meet at a square
corner (east times east plus north times north is 0). -/
theorem mul_I_is_quarter_turn (a b : ℝ) :
    I * ((a : ℂ) + b * I) = ((-b : ℝ) : ℂ) + (a : ℂ) * I ∧
    ‖I * ((a : ℂ) + b * I)‖ = ‖(a : ℂ) + b * I‖ ∧
    ((a : ℂ) + b * I).re * (I * ((a : ℂ) + b * I)).re
      + ((a : ℂ) + b * I).im * (I * ((a : ℂ) + b * I)).im = 0 := by
  have h : I * ((a : ℂ) + b * I) = ((-b : ℝ) : ℂ) + (a : ℂ) * I := by
    push_cast; ring_nf; rw [Complex.I_sq]; ring
  refine ⟨h, ?_, ?_⟩
  · rw [norm_mul, Complex.norm_I, one_mul]
  · rw [h]; simp; ring

/-- No "bigger than": no way of putting the complex numbers in a line, smallest to largest,
respects adding and multiplying the way the order of the real numbers does. -/
theorem no_order_respects_multiplying (o : LinearOrder ℂ) :
    ¬ @IsOrderedRing ℂ _ o.toPartialOrder := by
  intro hR
  let _ : LinearOrder ℂ := o
  have h1 : (0 : ℂ) ≤ I * I := mul_self_nonneg I
  rw [Complex.I_mul_I] at h1
  have h2 : (0 : ℂ) ≤ 1 * 1 := mul_self_nonneg 1
  rw [one_mul] at h2
  have h3 : (1 : ℂ) ≤ 0 := by
    have := add_le_add_left h1 1
    simpa using this
  exact one_ne_zero (le_antisymm h3 h2)

-- The drone z = 3 + 4i and the multiplier w = 1 + 2i: sum, difference, and the product -5 + 10i.
example : ((3 : ℂ) + 4 * I) + (1 + 2 * I) = 4 + 6 * I := by
  apply Complex.ext <;> norm_num [pow_two]
example : ((3 : ℂ) + 4 * I) - (1 + 2 * I) = 2 + 2 * I := by
  apply Complex.ext <;> norm_num [pow_two]
example : ((3 : ℂ) + 4 * I) * (1 + 2 * I) = -5 + 10 * I := by
  apply Complex.ext <;> norm_num [pow_two]
-- Turn and add: one copy of z plus two copies of iz lands on the same point.
example : ((3 : ℂ) + 4 * I) + 2 * (I * (3 + 4 * I)) = -5 + 10 * I := by
  apply Complex.ext <;> norm_num [pow_two]
-- Order does not matter: wz is also -5 + 10i.
example : ((1 : ℂ) + 2 * I) * (3 + 4 * I) = -5 + 10 * I := by
  apply Complex.ext <;> norm_num [pow_two]
-- The quarter turn, and four quarter turns bring the drone home.
example : I * ((3 : ℂ) + 4 * I) = -4 + 3 * I := by
  apply Complex.ext <;> norm_num [pow_two]
example : I * (I * ((3 : ℂ) + 4 * I)) = -3 - 4 * I := by
  apply Complex.ext <;> norm_num [pow_two]
example : I * (I * (I * ((3 : ℂ) + 4 * I))) = 4 - 3 * I := by
  apply Complex.ext <;> norm_num [pow_two]
example : I * (I * (I * (I * ((3 : ℂ) + 4 * I)))) = 3 + 4 * I := by
  apply Complex.ext <;> norm_num [pow_two]
-- Real numbers multiply as before: (2 + 0i)(-3 + 0i) = -6.
example : ((2 : ℂ) + 0 * I) * (-3 + 0 * I) = -6 := by
  apply Complex.ext <;> norm_num [pow_two]
-- Grouping does not matter: (zw)i and z(wi) are both -10 - 5i.
example : (((3 : ℂ) + 4 * I) * (1 + 2 * I)) * I = -10 - 5 * I := by
  apply Complex.ext <;> norm_num [pow_two]
example : ((3 : ℂ) + 4 * I) * ((1 + 2 * I) * I) = -10 - 5 * I := by
  apply Complex.ext <;> norm_num [pow_two]
-- x^2 + 2x + 5 = 0: (4i)^2 = -16, and both roots -1 + 2i and -1 - 2i solve it.
example : (4 * I) ^ 2 = -16 := by
  apply Complex.ext <;> norm_num [pow_two]
example : ((-1 : ℂ) + 2 * I) ^ 2 = -3 - 4 * I := by
  apply Complex.ext <;> norm_num [pow_two]
example : ((-1 : ℂ) + 2 * I) ^ 2 + 2 * (-1 + 2 * I) + 5 = 0 := by
  apply Complex.ext <;> norm_num [pow_two]
example : ((-1 : ℂ) - 2 * I) ^ 2 + 2 * (-1 - 2 * I) + 5 = 0 := by
  apply Complex.ext <;> norm_num [pow_two]
-- The three mistakes give 3 + 8i, 11 + 10i and 4 - 3i, none equal to the right answers.
example : ((3 : ℂ) + 4 * I) * (1 + 2 * I) ≠ 3 + 8 * I := by
  rw [Ne, Complex.ext_iff]; norm_num
example : ((3 : ℂ) + 4 * I) * (1 + 2 * I) ≠ 11 + 10 * I := by
  rw [Ne, Complex.ext_iff]; norm_num
example : I * ((3 : ℂ) + 4 * I) ≠ 4 - 3 * I := by
  rw [Ne, Complex.ext_iff]; norm_num

#print axioms complex_add_and_mul_rules
#print axioms mul_I_is_quarter_turn
#print axioms no_order_respects_multiplying
