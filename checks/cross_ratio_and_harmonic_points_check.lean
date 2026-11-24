-- Cross-ratio: a projective map x ↦ (px + q)/(rx + s) with ps − qr ≠ 0 keeps the cross-ratio of four different points on a line, so three known points and the cross-ratio fix the fourth, and a projective map that fixes three points moves nothing.
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith

/-- The cross-ratio (A, B; C, D) = (C − A)(D − B) / ((C − B)(D − A)) of four points on a line,
each given by its position along the line. Mathlib has no cross-ratio of real numbers, so the
card's formula is written out here. -/
noncomputable def crossRatio (A B C D : ℝ) : ℝ :=
  (C - A) * (D - B) / ((C - B) * (D - A))

/-- The projective map of the line with numbers p, q, r, s: x ↦ (px + q)/(rx + s). -/
noncomputable def projMap (p q r s x : ℝ) : ℝ :=
  (p * x + q) / (r * x + s)

/-- The gap between two images under the projective map: f(x) − f(y) = (ps − qr)(x − y)/((rx + s)(ry + s)). -/
theorem projMap_sub (p q r s x y : ℝ) (hx : r * x + s ≠ 0) (hy : r * y + s ≠ 0) :
    projMap p q r s x - projMap p q r s y
      = (p * s - q * r) * (x - y) / ((r * x + s) * (r * y + s)) := by
  unfold projMap
  rw [div_sub_div _ _ hx hy]
  congr 1
  ring

#print axioms projMap_sub

/-- Invariance: send four different points of a line through the same projective map
f(x) = (px + q)/(rx + s) with ps − qr ≠ 0, and the cross-ratio comes out unchanged.
(This is the case where no point is sent to the point at infinity, so rX + s ≠ 0 at each.) -/
theorem cross_ratio_invariant_under_projective_map (p q r s A B C D : ℝ)
    (hdet : p * s - q * r ≠ 0)
    (hAB : A ≠ B) (hAC : A ≠ C) (hAD : A ≠ D) (hBC : B ≠ C) (hBD : B ≠ D) (hCD : C ≠ D)
    (hA : r * A + s ≠ 0) (hB : r * B + s ≠ 0) (hC : r * C + s ≠ 0) (hD : r * D + s ≠ 0) :
    crossRatio (projMap p q r s A) (projMap p q r s B) (projMap p q r s C) (projMap p q r s D)
      = crossRatio A B C D := by
  unfold crossRatio
  rw [projMap_sub p q r s C A hC hA, projMap_sub p q r s D B hD hB,
    projMap_sub p q r s C B hC hB, projMap_sub p q r s D A hD hA]
  have h1 : C - A ≠ 0 := sub_ne_zero.mpr (Ne.symm hAC)
  have h2 : D - B ≠ 0 := sub_ne_zero.mpr (Ne.symm hBD)
  have h3 : C - B ≠ 0 := sub_ne_zero.mpr (Ne.symm hBC)
  have h4 : D - A ≠ 0 := sub_ne_zero.mpr (Ne.symm hAD)
  field_simp

/-- Three known points and the cross-ratio fix the fourth: for three different points
A, B, C, two candidate fourth points x and y (each different from A, B and C) that give the
same cross-ratio (A, B; C, ·) are the same point. -/
theorem cross_ratio_fixes_fourth_point (A B C x y : ℝ)
    (hAB : A ≠ B) (hAC : A ≠ C) (hBC : B ≠ C)
    (hxA : x ≠ A) (hxB : x ≠ B) (hxC : x ≠ C) (hyA : y ≠ A) (hyB : y ≠ B) (hyC : y ≠ C)
    (h : crossRatio A B C x = crossRatio A B C y) : x = y := by
  unfold crossRatio at h
  have h1 : C - A ≠ 0 := sub_ne_zero.mpr (Ne.symm hAC)
  have h3 : C - B ≠ 0 := sub_ne_zero.mpr (Ne.symm hBC)
  have h4 : x - A ≠ 0 := sub_ne_zero.mpr hxA
  have h5 : y - A ≠ 0 := sub_ne_zero.mpr hyA
  rw [div_eq_div_iff (mul_ne_zero h3 h4) (mul_ne_zero h3 h5)] at h
  have h6 : (C - A) * (C - B) * ((B - A) * (x - y)) = 0 := by linear_combination h
  have h7 : (C - A) * (C - B) ≠ 0 := mul_ne_zero h1 h3
  have h8 : B - A ≠ 0 := sub_ne_zero.mpr (Ne.symm hAB)
  rcases mul_eq_zero.mp h6 with h9 | h9
  · exact absurd h9 h7
  · rcases mul_eq_zero.mp h9 with h10 | h10
    · exact absurd h10 h8
    · exact sub_eq_zero.mp h10

/-- A projective map x ↦ (px + q)/(rx + s) with ps − qr ≠ 0 that leaves three different
points in place has r = 0, q = 0 and p = s, so it moves nothing. -/
theorem projective_map_fixing_three_points_is_identity (p q r s a b c : ℝ)
    (hdet : p * s - q * r ≠ 0) (hab : a ≠ b) (hac : a ≠ c) (hbc : b ≠ c)
    (ha : r * a + s ≠ 0) (hb : r * b + s ≠ 0) (hc : r * c + s ≠ 0)
    (hfa : projMap p q r s a = a) (hfb : projMap p q r s b = b) (hfc : projMap p q r s c = c) :
    r = 0 ∧ q = 0 ∧ p = s := by
  unfold projMap at hfa hfb hfc
  rw [div_eq_iff ha] at hfa
  rw [div_eq_iff hb] at hfb
  rw [div_eq_iff hc] at hfc
  have hab' : a - b ≠ 0 := sub_ne_zero.mpr hab
  have hac' : a - c ≠ 0 := sub_ne_zero.mpr hac
  have hbc' : b - c ≠ 0 := sub_ne_zero.mpr hbc
  have e1 : (a - b) * (r * (a + b) + (s - p)) = 0 := by linear_combination hfb - hfa
  have e2 : (a - c) * (r * (a + c) + (s - p)) = 0 := by linear_combination hfc - hfa
  have f1 : r * (a + b) + (s - p) = 0 := (mul_eq_zero.mp e1).resolve_left hab'
  have f2 : r * (a + c) + (s - p) = 0 := (mul_eq_zero.mp e2).resolve_left hac'
  have g : (b - c) * r = 0 := by linear_combination f1 - f2
  have hr : r = 0 := (mul_eq_zero.mp g).resolve_left hbc'
  subst hr
  have hps : p = s := by linarith
  subst hps
  refine ⟨rfl, ?_, rfl⟩
  linarith

-- The sleepers 4, 5, 6, 7 m ahead: cross-ratio 4/3.
example : crossRatio 4 5 6 7 = 4 / 3 := by norm_num [crossRatio]

-- Their photo heights 1/4, 1/5, 1/6, 1/7: top 1/210, bottom 1/280, cross-ratio 4/3 again.
example : (1 / 6 - 1 / 4 : ℝ) * (1 / 7 - 1 / 5) = 1 / 210 := by norm_num
example : (1 / 6 - 1 / 5 : ℝ) * (1 / 7 - 1 / 4) = 1 / 280 := by norm_num
example : crossRatio (1 / 4) (1 / 5) (1 / 6) (1 / 7) = 4 / 3 := by norm_num [crossRatio]

-- The level camera is the map with (p, q, r, s) = (0, 1, 1, 0): ps − qr = −1, and 6 m shows at 1/6.
example : (0 : ℝ) * 0 - 1 * 1 = -1 := by norm_num
example : projMap 0 1 1 0 6 = 1 / 6 := by norm_num [projMap]

-- Step 2's difference rule in the photo: 1/6 − 1/4 = −(6 − 4)/(6 × 4) = −1/12.
example : (1 / 6 - 1 / 4 : ℝ) = -(6 - 4) / (6 * 4) ∧ (1 / 6 - 1 / 4 : ℝ) = -1 / 12 := by norm_num

-- Step 3: sleepers 4, 5, 6 and photo cross-ratio 4/3 put the fourth sleeper at 7 m.
example : ((6 - 4) * 5 - 4 / 3 * (6 - 5) * 4 : ℝ) / ((6 - 4) - 4 / 3 * (6 - 5)) = 7 := by norm_num

-- Step 4: in the photo (1/4, 1/6; 1/5, 0) = −1, and 1/5 is the harmonic mean of 1/4 and 1/6.
example : crossRatio (1 / 4) (1 / 6) (1 / 5) 0 = -1 := by norm_num [crossRatio]
example : 2 * (1 / 4 : ℝ) * (1 / 6) / (1 / 4 + 1 / 6) = 1 / 5 := by norm_num

-- The usual mistakes: AC/BC is 2 on the ground but 5/2 in the photo; gaps read in proportion put
-- the fourth sleeper at 43/7 m; order A, C, B, D gives −1/3 and 34/7 m; the photo midpoint 5/24
-- reads as 24/5 m.
example : ((6 - 4) / (6 - 5) : ℝ) = 2 ∧ ((1 / 6 - 1 / 4) / (1 / 6 - 1 / 5) : ℝ) = 5 / 2 := by norm_num
example : (4 + (1 / 4 - 1 / 7) / (1 / 4 - 1 / 5) : ℝ) = 43 / 7 := by norm_num
example : crossRatio 4 6 5 7 = -1 / 3 := by norm_num [crossRatio]
example : ((6 - 4) * 5 - (-1 / 3) * (6 - 5) * 4 : ℝ) / ((6 - 4) - (-1 / 3) * (6 - 5)) = 34 / 7 := by
  norm_num
example : ((1 / 4 + 1 / 6) / 2 : ℝ) = 5 / 24 ∧ (2 / (1 / 4 + 1 / 6) : ℝ) = 24 / 5 := by norm_num

#print axioms cross_ratio_invariant_under_projective_map
#print axioms cross_ratio_fixes_fourth_point
#print axioms projective_map_fixing_three_points_is_identity
