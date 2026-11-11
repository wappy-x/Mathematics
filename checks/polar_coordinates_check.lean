-- Polar coordinates: turning a range r > 0 and an angle θ in one turn into grid offsets (r cos θ, r sin θ) and back by Pythagoras and the sign-aware arctangent returns the same pair, and every point other than the centre comes back to itself the other way round.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan
import Mathlib.Algebra.Order.ToIntervalMod
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

open Real

/-! A grid point `(x, y)` is `x` east and `y` north of the centre. A polar point `(r, θ)` is `r`
from the centre in the direction `θ`, measured from east, anticlockwise, in radians, so the
card's 360° is `2 * π` and its window "0° up to, not including, 360°" is `0 ≤ θ < 2 * π`. -/

/-- The card's angle-back rule: due north or south (`x = 0`) the angle is a quarter or three
quarters of a turn; otherwise take the plain arctangent of `y / x`, add a half turn if the point
lies west, or a full turn if it lies east and south. -/
noncomputable def polarAngle (x y : ℝ) : ℝ :=
  if x = 0 then (if 0 < y then π / 2 else 3 * π / 2)
  else if x < 0 then arctan (y / x) + π
  else if y < 0 then arctan (y / x) + 2 * π
  else arctan (y / x)

/-- Helper: the range of a point on a circle of radius `r ≥ 0` is `r`. -/
theorem polar_sqrt_range (r θ : ℝ) (hr : 0 ≤ r) :
    Real.sqrt ((r * cos θ) ^ 2 + (r * sin θ) ^ 2) = r := by
  have h : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 := by
    have := sin_sq_add_cos_sq θ
    linear_combination r ^ 2 * this
  rw [h, Real.sqrt_sq hr]

/-- Helper: the arctangent of `sin φ / cos φ` is `φ` inside a half turn about zero. -/
theorem polar_arctan_sin_div_cos (φ : ℝ) (h1 : -(π / 2) < φ) (h2 : φ < π / 2) :
    arctan (sin φ / cos φ) = φ := by
  rw [← tan_eq_sin_div_cos, arctan_tan h1 h2]

/-- Helper: in terms of a point west or east, the range times cosine and sine of the
plain arctangent of `y / x` gives back `|x|` and `y · |x| / x`. -/
theorem polar_arctan_mul (x y : ℝ) (hx : x ≠ 0) :
    Real.sqrt (x ^ 2 + y ^ 2) * cos (arctan (y / x)) = |x| ∧
      Real.sqrt (x ^ 2 + y ^ 2) * sin (arctan (y / x)) = y / x * |x| := by
  have hx2 : 0 < x ^ 2 := by positivity
  have hax : 0 < |x| := abs_pos.mpr hx
  have hs : Real.sqrt (1 + (y / x) ^ 2) = Real.sqrt (x ^ 2 + y ^ 2) / |x| := by
    rw [show 1 + (y / x) ^ 2 = (x ^ 2 + y ^ 2) / x ^ 2 by field_simp,
      Real.sqrt_div' _ (le_of_lt hx2), Real.sqrt_sq_eq_abs]
  have hpos : 0 < Real.sqrt (x ^ 2 + y ^ 2) := Real.sqrt_pos.mpr (by positivity)
  rw [cos_arctan, sin_arctan, hs]
  constructor <;> field_simp

/-- The two conversions undo each other. Going out: a range `r > 0` and an angle `θ` in the
window `0 ≤ θ < 2π` give the grid point `(r cos θ, r sin θ)`, and Pythagoras with the
sign-aware arctangent bring back exactly `r` and `θ`. Coming back: every grid point `(x, y)`
other than the centre gets the range `√(x² + y²)` and an angle in the window, and cosine and
sine turn that pair into `(x, y)` again. -/
theorem polar_and_grid_conversions_undo_each_other :
    (∀ r θ : ℝ, 0 < r → 0 ≤ θ → θ < 2 * π →
      Real.sqrt ((r * cos θ) ^ 2 + (r * sin θ) ^ 2) = r ∧
        polarAngle (r * cos θ) (r * sin θ) = θ) ∧
    (∀ x y : ℝ, (x, y) ≠ (0, 0) →
      0 ≤ polarAngle x y ∧ polarAngle x y < 2 * π ∧
        Real.sqrt (x ^ 2 + y ^ 2) * cos (polarAngle x y) = x ∧
        Real.sqrt (x ^ 2 + y ^ 2) * sin (polarAngle x y) = y) := by
  have hpi := pi_pos
  refine ⟨fun r θ hr h0 h2 => ⟨polar_sqrt_range r θ hr.le, ?_⟩, fun x y hxy => ?_⟩
  · have hrne : r ≠ 0 := hr.ne'
    have hdiv : r * sin θ / (r * cos θ) = sin θ / cos θ := by
      rw [mul_div_mul_left _ _ hrne]
    unfold polarAngle
    rw [hdiv]
    rcases lt_trichotomy θ (π / 2) with hA | hA | hA
    · -- first quarter (including 0)
      have hc : 0 < cos θ := cos_pos_of_mem_Ioo ⟨by linarith, hA⟩
      have hs : 0 ≤ sin θ := sin_nonneg_of_nonneg_of_le_pi h0 (by linarith)
      have hx : 0 < r * cos θ := mul_pos hr hc
      have hy : 0 ≤ r * sin θ := mul_nonneg hr.le hs
      rw [ite_eq_right hx.ne', ite_eq_right (not_lt.mpr hx.le), ite_eq_right (not_lt.mpr hy),
        polar_arctan_sin_div_cos θ (by linarith) hA]
    · subst hA
      simp [cos_pi_div_two, sin_pi_div_two, hr]
    · rcases lt_trichotomy θ (3 * π / 2) with hB | hB | hB
      · have hc : cos θ < 0 := cos_neg_of_pi_div_two_lt_of_lt hA (by linarith)
        have hx : r * cos θ < 0 := mul_neg_of_pos_of_neg hr hc
        rw [ite_eq_right hx.ne, ite_eq_left hx]
        have : sin θ / cos θ = sin (θ - π) / cos (θ - π) := by
          rw [sin_sub_pi, cos_sub_pi, neg_div_neg_eq]
        rw [this, polar_arctan_sin_div_cos (θ - π) (by linarith) (by linarith)]
        ring
      · subst hB
        have hc : cos (3 * π / 2) = 0 := by
          rw [show 3 * π / 2 = π / 2 + π by ring, cos_add_pi, cos_pi_div_two, neg_zero]
        have hs : sin (3 * π / 2) = -1 := by
          rw [show 3 * π / 2 = π / 2 + π by ring, sin_add_pi, sin_pi_div_two]
        simp only [hc, hs, mul_zero, ite_true]
        rw [ite_eq_right (by nlinarith)]
      · have hc : 0 < cos θ := by
          rw [← cos_sub_two_pi]
          exact cos_pos_of_mem_Ioo ⟨by linarith, by linarith⟩
        have hs : sin θ < 0 := by
          rw [← sin_sub_two_pi]
          exact sin_neg_of_neg_of_neg_pi_lt (by linarith) (by linarith)
        have hx : 0 < r * cos θ := mul_pos hr hc
        have hy : r * sin θ < 0 := mul_neg_of_pos_of_neg hr hs
        rw [ite_eq_right hx.ne', ite_eq_right (not_lt.mpr hx.le), ite_eq_left hy]
        have : sin θ / cos θ = sin (θ - 2 * π) / cos (θ - 2 * π) := by
          rw [sin_sub_two_pi, cos_sub_two_pi]
        rw [this, polar_arctan_sin_div_cos (θ - 2 * π) (by linarith) (by linarith)]
        ring
  · have hlo := neg_pi_div_two_lt_arctan (y / x)
    have hhi := arctan_lt_pi_div_two (y / x)
    unfold polarAngle
    by_cases hx : x = 0
    · subst hx
      have hy : y ≠ 0 := by
        intro hy; exact hxy (by rw [hy])
      rw [ite_eq_left rfl]
      by_cases hyp : 0 < y
      · rw [ite_eq_left hyp, show (0:ℝ) ^ 2 + y ^ 2 = y ^ 2 by ring, Real.sqrt_sq hyp.le,
          cos_pi_div_two, sin_pi_div_two]
        refine ⟨by linarith, by linarith, by ring, by ring⟩
      · have hyn : y < 0 := lt_of_le_of_ne (not_lt.mp hyp) hy
        have hc : cos (3 * π / 2) = 0 := by
          rw [show 3 * π / 2 = π / 2 + π by ring, cos_add_pi, cos_pi_div_two, neg_zero]
        have hs : sin (3 * π / 2) = -1 := by
          rw [show 3 * π / 2 = π / 2 + π by ring, sin_add_pi, sin_pi_div_two]
        rw [ite_eq_right hyp, show (0:ℝ) ^ 2 + y ^ 2 = (-y) ^ 2 by ring,
          Real.sqrt_sq (by linarith), hc, hs]
        refine ⟨by linarith, by linarith, by ring, by ring⟩
    · rw [ite_eq_right hx]
      obtain ⟨hC, hS⟩ := polar_arctan_mul x y hx
      by_cases hxn : x < 0
      · rw [ite_eq_left hxn, cos_add_pi, sin_add_pi]
        rw [abs_of_neg hxn] at hC hS
        refine ⟨by linarith, by linarith, by linarith, ?_⟩
        rw [mul_neg, hS]
        field_simp
      · have hxp : 0 < x := lt_of_le_of_ne (not_lt.mp hxn) (Ne.symm hx)
        rw [ite_eq_right hxn]
        rw [abs_of_pos hxp] at hC hS
        have hS' : Real.sqrt (x ^ 2 + y ^ 2) * sin (arctan (y / x)) = y := by
          rw [hS]; field_simp
        by_cases hyn : y < 0
        · rw [ite_eq_left hyn, cos_add_two_pi, sin_add_two_pi]
          have : arctan (y / x) < 0 := arctan_lt_zero.mpr (div_neg_of_neg_of_pos hyn hxp)
          exact ⟨by linarith, by linarith, hC, hS'⟩
        · rw [ite_eq_right hyn]
          have : 0 ≤ arctan (y / x) :=
            arctan_nonneg.mpr (div_nonneg (not_lt.mp hyn) hxp.le)
          exact ⟨this, by linarith, hC, hS'⟩

/-- A bearing `b` starts at north and turns clockwise. The maths angle is `π/2 − b`, wrapped
into one turn, and with it the east offset is `r sin b` and the north offset is `r cos b`. -/
theorem bearing_gives_east_r_sin_north_r_cos (r b : ℝ) :
    let θ := toIcoMod two_pi_pos 0 (π / 2 - b)
    0 ≤ θ ∧ θ < 2 * π ∧ r * cos θ = r * sin b ∧ r * sin θ = r * cos b := by
  intro θ
  have hmem := toIcoMod_mem_Ico two_pi_pos 0 (π / 2 - b)
  have heq : θ = (π / 2 - b) - (toIcoDiv two_pi_pos 0 (π / 2 - b) : ℝ) * (2 * π) := by
    rw [← zsmul_eq_mul, self_sub_toIcoDiv_zsmul]
  refine ⟨hmem.1, by simpa using hmem.2, ?_, ?_⟩
  · rw [heq, cos_sub_int_mul_two_pi, cos_pi_div_two_sub]
  · rw [heq, sin_sub_int_mul_two_pi, sin_pi_div_two_sub]

/-- The coverage curve with no angle left. A point at range `r ≥ 0` and angle `θ` lies inside
the cardioid `r ≤ 25(1 + cos θ)` exactly when its grid offsets `x = r cos θ`, `y = r sin θ`
satisfy `x² + y² ≤ 25(√(x² + y²) + x)`. -/
theorem inside_cardioid_iff_grid_test (r θ : ℝ) (hr : 0 ≤ r) :
    r ≤ 25 * (1 + cos θ) ↔
      (r * cos θ) ^ 2 + (r * sin θ) ^ 2 ≤
        25 * (Real.sqrt ((r * cos θ) ^ 2 + (r * sin θ) ^ 2) + r * cos θ) := by
  rw [polar_sqrt_range r θ hr]
  have h : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 := by
    have := sin_sq_add_cos_sq θ
    linear_combination r ^ 2 * this
  rw [h]
  have hc := neg_one_le_cos θ
  rcases hr.lt_or_eq with hp | h0
  · constructor
    · intro hle; nlinarith
    · intro hle
      by_contra hcon
      push Not at hcon
      nlinarith
  · subst h0
    constructor <;> intro _ <;> nlinarith

-- Bearing 120° to maths angle: 90 − 120 = −30, plus a turn, 330°.
example : (90 : ℤ) - 120 = -30 ∧ (-30 : ℤ) + 360 = 330 := by decide
-- In radians, the wrapped angle for bearing 120° (2π/3) is 330° = 11π/6.
example : toIcoMod two_pi_pos 0 (π / 2 - 2 * π / 3) = 11 * π / 6 := by
  rw [show π / 2 - 2 * π / 3 = 11 * π / 6 + (-1 : ℤ) • (2 * π) by push_cast; ring]
  rw [toIcoMod_add_zsmul, toIcoMod_eq_self two_pi_pos]
  constructor <;> nlinarith [pi_pos]
-- Plane 1: 40 cos 330° = 20√3 (about 34.64 km east) and 40 sin 330° = −20 (20 km south).
example : 40 * cos (11 * π / 6) = 20 * Real.sqrt 3 ∧ 40 * sin (11 * π / 6) = -20 := by
  rw [show 11 * π / 6 = -(π / 6) + 2 * π by ring, cos_add_two_pi, sin_add_two_pi, cos_neg,
    sin_neg, cos_pi_div_six, sin_pi_div_six]
  constructor <;> ring
-- The range back for plane 1: (20√3)² + (−20)² = 1200 + 400 = 1600 = 40².
example : Real.sqrt ((20 * Real.sqrt 3) ^ 2 + (-20) ^ 2) = 40 := by
  rw [mul_pow, Real.sq_sqrt (by norm_num : (0 : ℝ) ≤ 3),
    show (20 : ℝ) ^ 2 * 3 + (-20) ^ 2 = 40 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
-- Plane 2 at (−30, −40): √(900 + 1600) = 50 km.
example : (-30 : ℤ) ^ 2 + (-40) ^ 2 = 900 + 1600 ∧ (900 : ℤ) + 1600 = 50 ^ 2 := by decide
example : Real.sqrt ((-30) ^ 2 + (-40) ^ 2) = 50 := by
  rw [show ((-30 : ℝ)) ^ 2 + (-40) ^ 2 = 50 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
-- Plane 2 lies west, so the rule adds a half turn: arctan(4/3) + 180°.
example : polarAngle (-30) (-40) = arctan (4 / 3) + π := by
  unfold polarAngle
  norm_num
-- The usual mistake: (−30, −40) and (30, 40) share the ratio 4/3.
example : ((-40 : ℚ) / -30) = 4 / 3 ∧ ((40 : ℚ) / 30) = 4 / 3 := by norm_num
-- The coverage reach 25(1 + cos θ) at 0°, 60°, 90°, 120°, 180°: 50, 37.5, 25, 12.5, 0.
example : 25 * (1 + cos 0) = (50 : ℝ) ∧ 25 * (1 + cos (π / 3)) = (75 / 2 : ℝ) ∧
    25 * (1 + cos (π / 2)) = (25 : ℝ) ∧ 25 * (1 + cos (2 * π / 3)) = (25 / 2 : ℝ) ∧
    25 * (1 + cos π) = (0 : ℝ) := by
  refine ⟨by simp; norm_num, by rw [cos_pi_div_three]; norm_num, by simp, ?_, by simp⟩
  rw [show 2 * π / 3 = π - π / 3 by ring, cos_pi_sub, cos_pi_div_three]
  norm_num
-- Toward plane 2 the cosine is −30/50, so the reach is 25(1 − 3/5) = 10 km, short of its 50 km.
example : (25 : ℚ) * (1 + (-30) / 50) = 10 ∧ (10 : ℚ) < 50 := by norm_num
-- Grid test for plane 2: 2500 ≤ 25(50 + (−30)) = 500 fails, so it is outside.
example : ¬ ((-30 : ℤ) ^ 2 + (-40) ^ 2 ≤ 25 * (50 + (-30))) := by decide
-- Grid test for plane 1: 1600 ≤ 25(40 + 20√3), so it is inside.
example : (20 * Real.sqrt 3) ^ 2 + (-20) ^ 2 ≤ 25 * (40 + 20 * Real.sqrt 3) := by
  have h3 := Real.sq_sqrt (show (0 : ℝ) ≤ 3 by norm_num)
  nlinarith [Real.sqrt_nonneg 3]
-- The coverage circle of range 40: x² + y² = 1600.
example : (40 : ℤ) ^ 2 = 1600 := by decide

#print axioms polar_sqrt_range
#print axioms polar_arctan_sin_div_cos
#print axioms polar_arctan_mul
#print axioms polar_and_grid_conversions_undo_each_other
#print axioms bearing_gives_east_r_sin_north_r_cos
#print axioms inside_cardioid_iff_grid_test
