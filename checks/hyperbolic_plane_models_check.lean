-- Three maps of one hyperbolic plane: the Cayley map carries the Poincaré disc onto the upper half-plane with the same ruler and the same distances, the Klein map keeps distances from the centre and turns disc lines into straight chords, and the half-plane distance obeys the cosh formula.
import Mathlib.Analysis.Complex.UpperHalfPlane.Metric
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

open UpperHalfPlane

theorem cayley_im (p : ℂ) :
    (Complex.I * (1 + p) / (1 - p)).im = (1 - ‖p‖ ^ 2) / ‖1 - p‖ ^ 2 := by
  rw [Complex.sq_norm, Complex.sq_norm, Complex.div_im]
  simp only [Complex.mul_re, Complex.mul_im, Complex.I_re, Complex.I_im, Complex.add_re,
    Complex.add_im, Complex.sub_re, Complex.sub_im, Complex.one_re, Complex.one_im,
    Complex.normSq_apply]
  ring

theorem cayley_sub_I_norm_sq (p : ℂ) (hp1 : p ≠ 1) :
    ‖Complex.I * (1 + p) / (1 - p) - Complex.I‖ ^ 2 = 4 * ‖p‖ ^ 2 / ‖1 - p‖ ^ 2 := by
  have h : (1 - p) ≠ 0 := sub_ne_zero.mpr (Ne.symm hp1)
  have : Complex.I * (1 + p) / (1 - p) - Complex.I = 2 * Complex.I * p / (1 - p) := by
    field_simp; ring
  rw [this, norm_div, norm_mul, norm_mul, Complex.norm_I]
  simp; ring

theorem cosh_log_ratio (r : ℝ) (h0 : 0 ≤ r) (h1 : r < 1) :
    Real.cosh (Real.log ((1 + r) / (1 - r))) = (1 + r ^ 2) / (1 - r ^ 2) := by
  have hpos : 0 < (1 + r) / (1 - r) := by apply div_pos <;> linarith
  rw [Real.cosh_eq, Real.exp_neg, Real.exp_log hpos]
  have : 1 - r ≠ 0 := by linarith
  have : 1 + r ≠ 0 := by linarith
  have : 1 - r ^ 2 ≠ 0 := by nlinarith
  field_simp
  ring

theorem klein_part (r : ℝ) (h1 : r < 1) :
    (1 / 2) * Real.log ((1 + 2 * r / (1 + r ^ 2)) / (1 - 2 * r / (1 + r ^ 2)))
          = Real.log ((1 + r) / (1 - r)) := by
  have h2 : 0 < 1 + r ^ 2 := by positivity
  have : (1 + 2 * r / (1 + r ^ 2)) / (1 - 2 * r / (1 + r ^ 2)) = ((1 + r) / (1 - r)) ^ 2 := by
    have : 1 - r ≠ 0 := by linarith
    have : (1 + r ^ 2) - 2 * r ≠ 0 := by nlinarith
    field_simp
    ring
  rw [this, Real.log_pow]
  push_cast; ring

#print axioms cayley_im
#print axioms cayley_sub_I_norm_sq
#print axioms cosh_log_ratio
#print axioms klein_part

/-- The disc, the half-plane and the Klein disc are one plane. Take a Poincaré disc point `p`
strictly inside the rim, at drawn distance `r = ‖p‖` from the centre. The Cayley map sends it to
`z = i (1 + p) / (1 - p)`, which lies strictly above the real line; its true half-plane distance
from `i` (the image of the centre) is the disc ruler's `ln ((1 + r) / (1 - r))`; the Klein point
at drawn distance `s = 2r / (1 + r²)` has the same true distance `½ ln ((1 + s) / (1 - s))`; and
the Cayley map stretches every short piece at `p` by `|2i / (1 - p)²|` (one complex derivative,
so the same in every direction and angles are kept), which over the height of `z` is the disc
ruler `2 / (1 - r²)`. -/
theorem three_models_one_plane (p : ℂ) (hp : ‖p‖ < 1) :
    ∃ hz : 0 < (Complex.I * (1 + p) / (1 - p)).im,
      dist (⟨Complex.I * (1 + p) / (1 - p), hz⟩ : ℍ) UpperHalfPlane.I
          = Real.log ((1 + ‖p‖) / (1 - ‖p‖)) ∧
      (1 / 2) * Real.log ((1 + 2 * ‖p‖ / (1 + ‖p‖ ^ 2)) / (1 - 2 * ‖p‖ / (1 + ‖p‖ ^ 2)))
          = Real.log ((1 + ‖p‖) / (1 - ‖p‖)) ∧
      HasDerivAt (fun q : ℂ => Complex.I * (1 + q) / (1 - q))
          (2 * Complex.I / (1 - p) ^ 2) p ∧
      ‖2 * Complex.I / (1 - p) ^ 2‖ / (Complex.I * (1 + p) / (1 - p)).im
          = 2 / (1 - ‖p‖ ^ 2) := by
  have hp1 : p ≠ 1 := by rintro rfl; simp at hp
  have h1p : (1 - p) ≠ 0 := sub_ne_zero.mpr (Ne.symm hp1)
  have hn : 0 < ‖1 - p‖ := norm_pos_iff.mpr h1p
  have hr0 : 0 ≤ ‖p‖ := norm_nonneg p
  have hr2 : 0 < 1 - ‖p‖ ^ 2 := by nlinarith
  have him := cayley_im p
  have hz : 0 < (Complex.I * (1 + p) / (1 - p)).im := by rw [him]; positivity
  refine ⟨hz, ?_, klein_part _ hp, ?_, ?_⟩
  · set z : ℍ := ⟨Complex.I * (1 + p) / (1 - p), hz⟩
    have hc := UpperHalfPlane.cosh_dist z UpperHalfPlane.I
    have hzc : (z : ℂ) = Complex.I * (1 + p) / (1 - p) := rfl
    have hzi : z.im = (1 - ‖p‖ ^ 2) / ‖1 - p‖ ^ 2 := him
    rw [Complex.dist_eq, hzc, UpperHalfPlane.coe_I, cayley_sub_I_norm_sq p hp1, hzi,
      UpperHalfPlane.I_im] at hc
    have hc' : Real.cosh (dist z UpperHalfPlane.I)
        = Real.cosh (Real.log ((1 + ‖p‖) / (1 - ‖p‖))) := by
      rw [hc, cosh_log_ratio _ hr0 hp]
      field_simp
      ring
    have hL : 0 ≤ Real.log ((1 + ‖p‖) / (1 - ‖p‖)) := by
      apply Real.log_nonneg
      rw [le_div_iff₀ (by linarith)]; linarith
    have habs : |dist z UpperHalfPlane.I| = |Real.log ((1 + ‖p‖) / (1 - ‖p‖))| :=
      le_antisymm (Real.cosh_le_cosh.mp hc'.le) (Real.cosh_le_cosh.mp hc'.ge)
    rwa [abs_of_nonneg dist_nonneg, abs_of_nonneg hL] at habs
  · have hc : HasDerivAt (fun q : ℂ => Complex.I * (1 + q)) (Complex.I * 1) p :=
      ((hasDerivAt_id p).const_add 1).const_mul Complex.I
    have hd : HasDerivAt (fun q : ℂ => 1 - q) (-1) p := (hasDerivAt_id p).const_sub 1
    convert hc.div hd h1p using 1
    ring
  · rw [him, norm_div, norm_mul, norm_pow, Complex.norm_I, Complex.norm_ofNat]
    field_simp

/-- The half-plane distance formula: for two points `z`, `w` strictly above the real line, the
hyperbolic cosine of their true distance is one plus the squared drawn gap over twice the two
heights multiplied. -/
theorem half_plane_cosh_dist (z w : ℍ) :
    Real.cosh (dist z w) = 1 + ‖(z : ℂ) - w‖ ^ 2 / (2 * z.im * w.im) := by
  rw [UpperHalfPlane.cosh_dist, Complex.dist_eq]

/-- The Klein disc draws lines straight. A disc line is an arc of a circle with centre on the
x-axis at distance `c` from the centre O and radius `k`, meeting the rim square, so
`c² = 1 + k²`. The Klein map scales a point at drawn distance `r` by `2 / (1 + r²)`, and every
point `(x, y)` of the circle lands with first coordinate `1 / c`: on the chord `x = 1 / c`. -/
theorem klein_map_sends_disc_line_to_chord (c k x y : ℝ) (hc : c ^ 2 = 1 + k ^ 2)
    (hxy : (x - c) ^ 2 + y ^ 2 = k ^ 2) :
    2 / (1 + (x ^ 2 + y ^ 2)) * x = 1 / c := by
  have hsum : 1 + (x ^ 2 + y ^ 2) = 2 * c * x := by nlinarith
  have hc0 : c ≠ 0 := by rintro rfl; nlinarith
  have hx0 : x ≠ 0 := by rintro rfl; nlinarith
  rw [hsum]
  field_simp

-- Half-plane, i to 2i: cosh d = 1 + 1² / (2 × 1 × 2) = 5/4, and cosh (ln 2) = (2 + 1/2) / 2 = 5/4.
example : (1 : ℚ) + 1 ^ 2 / (2 * 1 * 2) = 5 / 4 := by norm_num
example : ((2 : ℚ) + 1 / 2) / 2 = 5 / 4 := by norm_num
-- Cayley map: the disc point 1/3 goes to 2i, and back: (2i - i) / (2i + i) = 1/3.
example : Complex.I * (1 + 1 / 3) / (1 - 1 / 3) = 2 * Complex.I := by
  field_simp; ring
example : (2 * Complex.I - Complex.I) / (2 * Complex.I + Complex.I) = 1 / 3 := by
  field_simp; ring
-- Disc ruler, 0 to 1/3: (1 + 1/3) / (1 - 1/3) = 2, so the distance is ln 2.
example : ((1 : ℚ) + 1 / 3) / (1 - 1 / 3) = 2 := by norm_num
-- Klein point: (2/3) / (1 + 1/9) = 3/5; Klein ruler 0 to 3/5: (1 + 3/5) / (1 - 3/5) = 4 = 2².
example : (2 * (1 / 3 : ℚ)) / (1 + (1 / 3) ^ 2) = 3 / 5 := by norm_num
example : ((1 : ℚ) + 3 / 5) / (1 - 3 / 5) = 2 ^ 2 := by norm_num
-- Back from Klein: 1 - (3/5)² = (4/5)², and (3/5) / (1 + 4/5) = 1/3.
example : (1 : ℚ) - (3 / 5) ^ 2 = (4 / 5) ^ 2 := by norm_num
example : (3 / 5 : ℚ) / (1 + 4 / 5) = 1 / 3 := by norm_num
-- Pair i, 1 + i: cosh d = 1 + 1² / (2 × 1 × 1) = 3/2.
example : (1 : ℚ) + 1 ^ 2 / (2 * 1 * 1) = 3 / 2 := by norm_num
-- Angle at A in the Klein drawing, s = 4/5: true tangent 1 × √(1 - (4/5)²) = 3/5.
example : (1 : ℚ) - (4 / 5) ^ 2 = (3 / 5) ^ 2 := by norm_num

#print axioms three_models_one_plane
#print axioms half_plane_cosh_dist
#print axioms klein_map_sends_disc_line_to_chord
