-- What curves answer: a whole number n > 0 is the area of a right triangle with rational sides exactly when the curve y^2 = x^3 - n^2 x has a rational point with y ≠ 0, by explicit rational maps each way, and the card's triangles and points for 7 and 5 are as it states.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic

open WeierstrassCurve

lemma cn_triangle_to_point (n : ℕ) (a b c : ℚ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c)
    (hright : a ^ 2 + b ^ 2 = c ^ 2) (harea : a * b / 2 = n) :
    let x := (n : ℚ) * (a + c) / b
    let y := 2 * (n : ℚ) ^ 2 * (a + c) / b ^ 2
    y ≠ 0 ∧ (⟨0, 0, 0, -(n : ℚ) ^ 2, 0⟩ : WeierstrassCurve ℚ).toAffine.Equation x y ∧
      (x ^ 2 - (n : ℚ) ^ 2) / y = a ∧ 2 * (n : ℚ) * x / y = b ∧ (x ^ 2 + (n : ℚ) ^ 2) / y = c := by
  intro x y
  have hn : (n : ℚ) = a * b / 2 := harea.symm
  have hac : 0 < a + c := by linarith
  have hx : x = a * (a + c) / 2 := by
    simp only [x, hn]; field_simp
  have hy : y = a ^ 2 * (a + c) / 2 := by
    simp only [y, hn]; field_simp
  rw [hx, hy, hn]
  refine ⟨by positivity, ?_, ?_, ?_, ?_⟩
  · rw [Affine.equation_iff]
    field_simp
    linear_combination (a ^ 3 * c + a ^ 4) * hright
  · field_simp
    linear_combination (-1:ℚ) * hright
  · field_simp
  · field_simp
    linear_combination hright

lemma cn_point_to_triangle (n : ℕ) (x y : ℚ) (hy : y ≠ 0)
    (hE : (⟨0, 0, 0, -(n : ℚ) ^ 2, 0⟩ : WeierstrassCurve ℚ).toAffine.Equation x y) :
    let a := (x ^ 2 - (n : ℚ) ^ 2) / y
    let b := 2 * (n : ℚ) * x / y
    let c := (x ^ 2 + (n : ℚ) ^ 2) / y
    a ^ 2 + b ^ 2 = c ^ 2 ∧ a * b / 2 = n := by
  intro a b c
  rw [Affine.equation_iff] at hE
  refine ⟨?_, ?_⟩
  · simp only [a, b, c]; field_simp; ring
  · simp only [a, b]; field_simp
    linear_combination (-(n:ℚ)) * hE

#print axioms cn_triangle_to_point
#print axioms cn_point_to_triangle

/-- The congruent number dictionary. A whole number `n > 0` is congruent (the area `a * b / 2`
of a right triangle whose legs `a`, `b` and hypotenuse `c` are positive rationals with
`a^2 + b^2 = c^2`) exactly when the curve `E_n : y^2 = x^3 - n^2 x` over `ℚ`, written as the
Weierstrass curve with `a₄ = -n^2` and every other coefficient `0`, has a rational point
`(x, y)` with `y ≠ 0`. -/
theorem congruent_iff_exists_rational_point_with_y_ne_zero (n : ℕ) (hn : 0 < n) :
    (∃ a b c : ℚ, 0 < a ∧ 0 < b ∧ 0 < c ∧ a ^ 2 + b ^ 2 = c ^ 2 ∧ a * b / 2 = n) ↔
      ∃ x y : ℚ, y ≠ 0 ∧
        (⟨0, 0, 0, -(n : ℚ) ^ 2, 0⟩ : WeierstrassCurve ℚ).toAffine.Equation x y := by
  constructor
  · rintro ⟨a, b, c, ha, hb, hc, hright, harea⟩
    obtain ⟨hy, hE, -⟩ := cn_triangle_to_point n a b c ha hb hc hright harea
    exact ⟨_, _, hy, hE⟩
  · rintro ⟨x, y, hy, hE⟩
    obtain ⟨hright, harea⟩ := cn_point_to_triangle n x y hy hE
    set a := (x ^ 2 - (n : ℚ) ^ 2) / y
    set b := 2 * (n : ℚ) * x / y
    set c := (x ^ 2 + (n : ℚ) ^ 2) / y
    have hn : (0 : ℚ) < n := by exact_mod_cast hn
    have hab : a * b ≠ 0 := by intro h; rw [h] at harea; linarith
    have ha : a ≠ 0 := left_ne_zero_of_mul hab
    have hb : b ≠ 0 := right_ne_zero_of_mul hab
    have hc : c ≠ 0 := by
      intro h; rw [h] at hright
      have : 0 < a ^ 2 + b ^ 2 := by positivity
      linarith
    refine ⟨|a|, |b|, |c|, abs_pos.2 ha, abs_pos.2 hb, abs_pos.2 hc, ?_, ?_⟩
    · simpa only [sq_abs] using hright
    · rw [← abs_mul, abs_of_pos (by linarith : 0 < a * b)]
      exact harea

/-- Triangle to point, and back. For a right triangle with positive rational legs `a`, `b`,
hypotenuse `c` and area `n`, the point `x = n(a + c)/b`, `y = 2n^2(a + c)/b^2` lies on
`y^2 = x^3 - n^2 x` with `y ≠ 0`, and the reverse formulas `(x^2 - n^2)/y`, `2nx/y`,
`(x^2 + n^2)/y` give back exactly `a`, `b` and `c`: the two maps undo each other. -/
theorem triangle_to_point_and_back (n : ℕ) (a b c : ℚ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c)
    (hright : a ^ 2 + b ^ 2 = c ^ 2) (harea : a * b / 2 = n) :
    let x := (n : ℚ) * (a + c) / b
    let y := 2 * (n : ℚ) ^ 2 * (a + c) / b ^ 2
    y ≠ 0 ∧ (⟨0, 0, 0, -(n : ℚ) ^ 2, 0⟩ : WeierstrassCurve ℚ).toAffine.Equation x y ∧
      (x ^ 2 - (n : ℚ) ^ 2) / y = a ∧ 2 * (n : ℚ) * x / y = b ∧ (x ^ 2 + (n : ℚ) ^ 2) / y = c := by
  exact cn_triangle_to_point n a b c ha hb hc hright harea

/-- Point to triangle. For any rational point `(x, y)` with `y ≠ 0` on `y^2 = x^3 - n^2 x`, the
three rationals `(x^2 - n^2)/y`, `2nx/y` and `(x^2 + n^2)/y` satisfy `a^2 + b^2 = c^2`, and half
the product of the first two is `n`. (Negative sides are made positive to get the triangle.) -/
theorem point_to_triangle (n : ℕ) (x y : ℚ) (hy : y ≠ 0)
    (hE : (⟨0, 0, 0, -(n : ℚ) ^ 2, 0⟩ : WeierstrassCurve ℚ).toAffine.Equation x y) :
    let a := (x ^ 2 - (n : ℚ) ^ 2) / y
    let b := 2 * (n : ℚ) * x / y
    let c := (x ^ 2 + (n : ℚ) ^ 2) / y
    a ^ 2 + b ^ 2 = c ^ 2 ∧ a * b / 2 = n := by
  exact cn_point_to_triangle n x y hy hE

-- The triangle 24/5, 35/12, 337/60 is right and has area 7.
example : ((24 : ℚ) / 5) ^ 2 + (35 / 12) ^ 2 = (337 / 60) ^ 2 ∧ (24 : ℚ) / 5 * (35 / 12) / 2 = 7 := by
  norm_num
-- a^2 + b^2 and c^2 are both 113569/3600; a + c = 125/12.
example : ((337 : ℚ) / 60) ^ 2 = 113569 / 3600 ∧ (24 : ℚ) / 5 + 337 / 60 = 125 / 12 := by norm_num
-- Triangle to point: x = 7 (125/12) / (35/12) = 25 and y = 2 * 49 (125/12) / (35/12)^2 = 120 = a x.
example : (7 : ℚ) * (125 / 12) / (35 / 12) = 25 ∧ 2 * 7 ^ 2 * ((125 : ℚ) / 12) / (35 / 12) ^ 2 = 120 ∧
    (24 : ℚ) / 5 * 25 = 120 := by norm_num
-- Q = (25, 120) is on y^2 = x^3 - 49x: 25^3 - 49 * 25 = 15625 - 1225 = 14400 = 120^2.
example : (25 : ℤ) ^ 3 - 49 * 25 = 15625 - 1225 ∧ (15625 : ℤ) - 1225 = 14400 ∧ (14400 : ℤ) = 120 ^ 2 := by
  norm_num
-- Point back to triangle: x^2 - 49 = 576, 2nx = 350, x^2 + 49 = 674, each divided by 120.
example : (25 : ℤ) ^ 2 - 49 = 576 ∧ 2 * 7 * 25 = (350 : ℤ) ∧ (25 : ℤ) ^ 2 + 49 = 674 := by norm_num
example : (576 : ℚ) / 120 = 24 / 5 ∧ (350 : ℚ) / 120 = 35 / 12 ∧ (674 : ℚ) / 120 = 337 / 60 := by
  norm_num
-- Three squares spaced 7 apart: (c/2)^2 - 7, (c/2)^2, (c/2)^2 + 7 are (113/120)^2, (337/120)^2, (463/120)^2.
example : ((337 : ℚ) / 120) ^ 2 - 7 = (113 / 120) ^ 2 ∧ ((337 : ℚ) / 60 / 2) ^ 2 = 113569 / 14400 ∧
    ((337 : ℚ) / 120) ^ 2 + 7 = (463 / 120) ^ 2 := by norm_num
-- Doubling Q by the tangent line gives 2Q = (113569/14400, 17631503/1728000).
example : (3 * 25 ^ 2 - 49 : ℚ) / (2 * 120) = 913 / 120 ∧
    ((913 : ℚ) / 120) ^ 2 - 2 * 25 = 113569 / 14400 ∧
    (913 : ℚ) / 120 * (25 - 113569 / 14400) - 120 = 17631503 / 1728000 := by norm_num
-- 2Q lies on y^2 = x^3 - 49x.
example : ((17631503 : ℚ) / 1728000) ^ 2 = (113569 / 14400) ^ 3 - 49 * (113569 / 14400) := by norm_num
-- Square roots back from 2Q: legs 463/120 ± 113/120 and hypotenuse 2 * 337/120.
example : (463 : ℚ) / 120 + 113 / 120 = 24 / 5 ∧ (463 : ℚ) / 120 - 113 / 120 = 35 / 12 ∧
    2 * ((337 : ℚ) / 120) = 337 / 60 := by norm_num
-- Step 2 applied to 2Q gives the new triangle 52319/40440, 566160/52319, 23058557761/2115780360.
example :
    let x : ℚ := 113569 / 14400
    let y : ℚ := 17631503 / 1728000
    |(x ^ 2 - 49) / y| = 52319 / 40440 ∧ |2 * 7 * x / y| = 566160 / 52319 ∧
      |(x ^ 2 + 49) / y| = 23058557761 / 2115780360 := by norm_num
-- The new triangle is right and has area 7.
example : ((52319 : ℚ) / 40440) ^ 2 + (566160 / 52319) ^ 2 = (23058557761 / 2115780360) ^ 2 ∧
    (52319 : ℚ) / 40440 * (566160 / 52319) / 2 = 7 := by norm_num
-- n = 5: the triangle 3/2, 20/3, 41/6 has area 5 and gives (25/4, 75/8) on y^2 = x^3 - 25x.
example : ((3 : ℚ) / 2) ^ 2 + (20 / 3) ^ 2 = (41 / 6) ^ 2 ∧ (3 : ℚ) / 2 * (20 / 3) / 2 = 5 ∧
    (5 : ℚ) * (3 / 2 + 41 / 6) / (20 / 3) = 25 / 4 ∧
    2 * 5 ^ 2 * ((3 : ℚ) / 2 + 41 / 6) / (20 / 3) ^ 2 = 75 / 8 ∧
    ((75 : ℚ) / 8) ^ 2 = (25 / 4) ^ 3 - 25 * (25 / 4) := by norm_num
-- The points with y = 0: (0, 0), (7, 0), (-7, 0) lie on y^2 = x^3 - 49x.
example : (0 : ℤ) ^ 3 - 49 * 0 = 0 ∧ (7 : ℤ) ^ 3 - 49 * 7 = 0 ∧ (-7 : ℤ) ^ 3 - 49 * (-7) = 0 := by
  norm_num
-- Point counts of y^2 = x^3 - 49x mod 3, 11, 19, 23, 31 (affine solutions, plus O): 4, 12, 20, 24, 32.
example : ((Finset.univ : Finset (ZMod 3 × ZMod 3)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - 49 * q.1)).card + 1 = 4 := by decide
example : ((Finset.univ : Finset (ZMod 11 × ZMod 11)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - 49 * q.1)).card + 1 = 12 := by decide
example : ((Finset.univ : Finset (ZMod 19 × ZMod 19)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - 49 * q.1)).card + 1 = 20 := by decide
example : ((Finset.univ : Finset (ZMod 23 × ZMod 23)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - 49 * q.1)).card + 1 = 24 := by decide
example : ((Finset.univ : Finset (ZMod 31 × ZMod 31)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - 49 * q.1)).card + 1 = 32 := by decide
-- Their greatest common divisor is 4.
example : Nat.gcd 4 (Nat.gcd 12 (Nat.gcd 20 (Nat.gcd 24 32))) = 4 := by decide
-- a_p = p + 1 - #E(F_p): mod 5 the count is 4, so a_5 = 2; mod 13 it is 20, so a_13 = -6.
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - 49 * q.1)).card + 1 = 4 := by decide
example : ((Finset.univ : Finset (ZMod 13 × ZMod 13)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - 49 * q.1)).card + 1 = 20 := by decide
example : (5 : ℤ) + 1 - 4 = 2 ∧ (13 : ℤ) + 1 - 20 = -6 := by norm_num
-- The conductor for n = 7: 32 * 7^2 = 1568.
example : 32 * 7 ^ 2 = 1568 := by norm_num
-- Tunnell's counts A (2x^2 + y^2 + 32z^2 = n) and B (2x^2 + y^2 + 8z^2 = n), over -3..3, which holds every solution for n up to 11.
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun t => 2 * t.1 ^ 2 + t.2.1 ^ 2 + 32 * t.2.2 ^ 2 = 1)).card = 2 := by decide
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun t => 2 * t.1 ^ 2 + t.2.1 ^ 2 + 8 * t.2.2 ^ 2 = 1)).card = 2 := by decide
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun t => 2 * t.1 ^ 2 + t.2.1 ^ 2 + 32 * t.2.2 ^ 2 = 3)).card = 4 := by decide
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun t => 2 * t.1 ^ 2 + t.2.1 ^ 2 + 8 * t.2.2 ^ 2 = 3)).card = 4 := by decide
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun t => 2 * t.1 ^ 2 + t.2.1 ^ 2 + 32 * t.2.2 ^ 2 = 7)).card = 0 := by decide
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun t => 2 * t.1 ^ 2 + t.2.1 ^ 2 + 8 * t.2.2 ^ 2 = 7)).card = 0 := by decide
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun t => 2 * t.1 ^ 2 + t.2.1 ^ 2 + 32 * t.2.2 ^ 2 = 11)).card = 4 := by decide
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun t => 2 * t.1 ^ 2 + t.2.1 ^ 2 + 8 * t.2.2 ^ 2 = 11)).card = 12 := by decide
-- The rows y^2 = x^3 - 7x at x = 25: 25^3 - 7 * 25 = 15450, not a square.
example : (25 : ℕ) ^ 3 - 7 * 25 = 15450 := by norm_num
example : ¬ IsSquare (15450 : ℕ) := by decide +kernel

#print axioms congruent_iff_exists_rational_point_with_y_ne_zero
#print axioms triangle_to_point_and_back
#print axioms point_to_triangle
