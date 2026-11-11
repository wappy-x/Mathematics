-- The unit circle: a point one unit from the origin whose angle from due east is θ (anticlockwise positive, whole turns ignored) is exactly the point (cos θ, sin θ), an arm of length r ends at (r cos θ, r sin θ), and a half turn or a mirror in an axis only flips the signs of cosine and sine.
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Real

/-! The plan is the complex plane: a point `z` sits `z.re` east and `z.im` north of the mast
at `0`. The angle turned from due east is `Complex.arg z`, read as a `Real.Angle`, an angle
counted anticlockwise with whole turns ignored, so a clockwise turn is a negative angle and
`θ`, `θ + 2π` and `θ - 2π` are the same turn. -/

/-- Helper: an arm of length `r > 0` at angle `θ` ends at `(r cos θ, r sin θ)`, both ways. -/
lemma arm_tip_aux (r θ : ℝ) (hr : 0 < r) (z : ℂ) :
    (‖z‖ = r ∧ (z.arg : Real.Angle) = θ) ↔ (z.re = r * cos θ ∧ z.im = r * sin θ) := by
  constructor
  · rintro ⟨h1, h2⟩
    have hc : cos z.arg = cos θ := by rw [← Real.Angle.cos_coe, h2, Real.Angle.cos_coe]
    have hs : sin z.arg = sin θ := by rw [← Real.Angle.sin_coe, h2, Real.Angle.sin_coe]
    rw [← Complex.norm_mul_cos_arg, ← Complex.norm_mul_sin_arg, h1, hc, hs]
    exact ⟨rfl, rfl⟩
  · rintro ⟨h1, h2⟩
    have hz : z = (r : ℂ) * ((Real.Angle.cos θ : ℝ) + (Real.Angle.sin θ : ℝ) * Complex.I) := by
      apply Complex.ext <;>
        simp [h1, h2, Real.Angle.cos_coe, Real.Angle.sin_coe, Complex.cos_ofReal_re,
          Complex.sin_ofReal_re]
    refine ⟨?_, ?_⟩
    · rw [hz, norm_mul, Real.Angle.cos_coe, Real.Angle.sin_coe, Complex.norm_real,
        Real.norm_of_nonneg hr.le]
      have : ‖((cos θ : ℝ) : ℂ) + ((sin θ : ℝ) : ℂ) * Complex.I‖ = 1 := by
        rw [Complex.ofReal_cos, Complex.ofReal_sin, Complex.norm_cos_add_sin_mul_I]
      rw [this, mul_one]
    · rw [hz]
      exact Complex.arg_mul_cos_add_sin_mul_I_coe_angle hr (θ : Real.Angle)

/-- The unit circle definition. Turn an arm of length 1 from due east through any angle `θ`:
its tip is the point one unit from the mast whose angle from due east is `θ`. That tip is
exactly the point whose east position is `cos θ` and whose north position is `sin θ`. Both
directions hold, so such a tip exists at every angle, including the ones no triangle has. -/
theorem unit_arm_tip_is_cos_sin (θ : ℝ) (z : ℂ) :
    (‖z‖ = 1 ∧ (z.arg : Real.Angle) = θ) ↔ (z.re = cos θ ∧ z.im = sin θ) := by
  simpa using arm_tip_aux 1 θ one_pos z

/-- An arm of real length `r` is the unit arm scaled up by `r`: the point `r` from the mast at
angle `θ` from due east is exactly the point `(r cos θ, r sin θ)`. -/
theorem arm_of_length_r_ends_at_r_cos_r_sin (r θ : ℝ) (hr : 0 < r) (z : ℂ) :
    (‖z‖ = r ∧ (z.arg : Real.Angle) = θ) ↔ (z.re = r * cos θ ∧ z.im = r * sin θ) := by
  exact arm_tip_aux r θ hr z

/-- The reference angle gives the sizes, the quadrant the signs. For every angle `α`, the half
turn to `π + α` (180° + α) sends `(cos α, sin α)` to `(−cos α, −sin α)`; the mirror in the
north–south line, to `π − α` (180° − α), gives `(−cos α, sin α)`; the mirror in the east–west
line, to `−α`, gives `(cos α, −sin α)`. -/
theorem half_turn_and_mirrors_flip_signs (α : ℝ) :
    (cos (π + α) = -cos α ∧ sin (π + α) = -sin α) ∧
      (cos (π - α) = -cos α ∧ sin (π - α) = sin α) ∧
      (cos (-α) = cos α ∧ sin (-α) = -sin α) := by
  rw [add_comm π α]
  exact ⟨⟨cos_add_pi α, sin_add_pi α⟩, ⟨cos_pi_sub α, sin_pi_sub α⟩, ⟨cos_neg α, sin_neg α⟩⟩

-- The swing: 210° is 210 × π ÷ 180 = 7π/6 radians.
example : (210 : ℝ) * π / 180 = 7 * π / 6 := by ring
-- Quadrant III, reference angle 210° − 180° = 30°.
example : 180 < 210 ∧ 210 < 270 ∧ 210 - 180 = 30 := by decide
-- The 30° point: half an equilateral triangle of side 1, height √(1 − 1/4) = √3/2.
example : Real.sqrt (1 - 1 / 4) = Real.sqrt 3 / 2 := by
  rw [show (1 : ℝ) - 1 / 4 = 3 / 4 by norm_num, Real.sqrt_div' 3 (by norm_num : (0 : ℝ) ≤ 4)]
  rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num : (0 : ℝ) ≤ 2)]
-- The 30° point is (√3/2, 1/2); the 210° point is both signs flipped: (−√3/2, −1/2).
example : cos (π / 6) = Real.sqrt 3 / 2 ∧ sin (π / 6) = 1 / 2 := by
  exact ⟨cos_pi_div_six, sin_pi_div_six⟩
example : cos (7 * π / 6) = -(Real.sqrt 3 / 2) ∧ sin (7 * π / 6) = -(1 / 2) := by
  rw [show 7 * π / 6 = π / 6 + π by ring, cos_add_pi, sin_add_pi, cos_pi_div_six, sin_pi_div_six]
  exact ⟨rfl, rfl⟩
-- The hook, 30 m arm: 15 m south exactly (30 × −1/2 = −15), and 15√3 m west.
example : 30 * sin (7 * π / 6) = -15 ∧ 30 * cos (7 * π / 6) = -(15 * Real.sqrt 3) := by
  rw [show 7 * π / 6 = π / 6 + π by ring, cos_add_pi, sin_add_pi, cos_pi_div_six, sin_pi_div_six]
  constructor <;> ring
-- The other four at 210°: csc = 1/y = −2, cot = x/y = √3, tan = y/x = 1/√3, sec = 1/x = −2/√3.
example : 1 / sin (7 * π / 6) = -2 ∧ cos (7 * π / 6) / sin (7 * π / 6) = Real.sqrt 3 ∧
    tan (7 * π / 6) = 1 / Real.sqrt 3 ∧ 1 / cos (7 * π / 6) = -2 / Real.sqrt 3 := by
  have h3 : Real.sqrt 3 ≠ 0 := by positivity
  rw [tan_eq_sin_div_cos, show 7 * π / 6 = π / 6 + π by ring, cos_add_pi, sin_add_pi,
    cos_pi_div_six, sin_pi_div_six]
  refine ⟨by norm_num, by ring, ?_, ?_⟩
  · field_simp
  · field_simp
-- Second case: 45° clockwise is −π/4, the point (√2/2, −√2/2) in quadrant IV.
example : cos (-(π / 4)) = Real.sqrt 2 / 2 ∧ sin (-(π / 4)) = -(Real.sqrt 2 / 2) := by
  rw [cos_neg, sin_neg, cos_pi_div_four, sin_pi_div_four]
  exact ⟨rfl, rfl⟩
-- Whole turns change nothing: 150° clockwise and 570° anticlockwise are 210° plus whole turns.
example : (-150 : ℤ) + 360 = 210 ∧ (570 : ℤ) - 360 = 210 := by decide
-- On the axes: at 90° the point is (0, 1), so tan and sec do not exist and cot 90° = 0;
-- at 180° the point is (−1, 0), so csc and cot do not exist and sec 180° = −1.
example : cos (π / 2) = 0 ∧ sin (π / 2) = 1 ∧ cos (π / 2) / sin (π / 2) = 0 := by
  simp
example : cos π = -1 ∧ sin π = 0 ∧ 1 / cos π = -1 := by
  simp
-- Mistake 3: 210 typed in radian mode is 33 whole turns and some more, not one 210° swing.
example : 33 * (2 * π) < 210 ∧ 210 < 34 * (2 * π) := by
  constructor <;> nlinarith [pi_gt_d2, pi_lt_d2]

#print axioms arm_tip_aux
#print axioms unit_arm_tip_is_cos_sin
#print axioms arm_of_length_r_ends_at_r_cos_r_sin
#print axioms half_turn_and_mirrors_flip_signs
