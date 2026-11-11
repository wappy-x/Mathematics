-- Perspective: any two distinct lines of the projective plane meet in exactly one point, the cross product of their triples finds it, and parallel scene lines all head for the image of their shared direction, the vanishing point.
import Mathlib.LinearAlgebra.Projectivization.Constructions
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum

open Filter Topology Matrix
open scoped LinearAlgebra.Projectivization


/-- Helper: a triple on two lines whose cross product is nonzero is a multiple of that cross
product. -/
theorem helper_on_both_lines_is_multiple_of_cross {ℓ₁ ℓ₂ p : Fin 3 → ℝ} (hn : ℓ₁ ⨯₃ ℓ₂ ≠ 0)
    (h1 : ℓ₁ ⬝ᵥ p = 0) (h2 : ℓ₂ ⬝ᵥ p = 0) : ∃ c : ℝ, p = c • (ℓ₁ ⨯₃ ℓ₂) := by
  by_cases hp : p = 0
  · exact ⟨0, by simp [hp]⟩
  have hx : p ⨯₃ (ℓ₁ ⨯₃ ℓ₂) = 0 := by
    rw [cross_cross_eq_smul_sub_smul', dotProduct_comm p ℓ₂, h2, h1]
    simp
  obtain ⟨a, ha⟩ := (Projectivization.mk_eq_mk_iff' ℝ p _ hp hn).1
    ((Projectivization.mk_eq_mk_iff_crossProduct_eq_zero hp hn).2 hx)
  exact ⟨a, ha.symm⟩

/-- Helper: `f (a + k b) / (c + k d)` tends to `f b / d` as `k` grows, when `d ≠ 0`. -/
theorem helper_ratio_tendsto (f a b c d : ℝ) (hd : d ≠ 0) :
    Tendsto (fun k : ℝ => f * (a + k * b) / (c + k * d)) atTop (𝓝 (f * b / d)) := by
  have h0 : Tendsto (fun k : ℝ => k⁻¹) atTop (𝓝 0) := tendsto_inv_atTop_zero
  have hc : Tendsto (fun t : ℝ => f * (a * t + b) / (c * t + d)) (𝓝 0) (𝓝 (f * b / d)) := by
    have : ContinuousAt (fun t : ℝ => f * (a * t + b) / (c * t + d)) 0 := by
      apply ContinuousAt.div (by fun_prop) (by fun_prop)
      simpa using hd
    simpa using this.tendsto
  refine (hc.comp h0).congr' ?_
  filter_upwards [eventually_gt_atTop 0] with k hk
  have hk' : k ≠ 0 := hk.ne'
  simp only [Function.comp]
  have e1 : a * k⁻¹ + b = (a + k * b) / k := by field_simp
  have e2 : c * k⁻¹ + d = (c + k * d) / k := by field_simp
  rw [e1, e2, ← mul_div_assoc, div_div_div_cancel_right₀ hk']

/-- The theorem under the method. In the projective plane (triples of real numbers up to a
nonzero scale), a point `p` lies on a line `ℓ` when their dot product is zero. Two distinct
lines meet in exactly one point: there is a point on both, and only one. -/
theorem two_distinct_lines_meet_in_exactly_one_point
    (ℓ₁ ℓ₂ : ℙ ℝ (Fin 3 → ℝ)) (h : ℓ₁ ≠ ℓ₂) :
    ∃! p : ℙ ℝ (Fin 3 → ℝ),
      Projectivization.orthogonal ℓ₁ p ∧ Projectivization.orthogonal ℓ₂ p := by
  refine ⟨Projectivization.cross ℓ₁ ℓ₂,
    ⟨Projectivization.orthogonal_cross_left h, Projectivization.orthogonal_cross_right h⟩, ?_⟩
  rintro q ⟨hq1, hq2⟩
  induction ℓ₁ with | h v hv =>
  induction ℓ₂ with | h w hw =>
  induction q with | h p hp =>
  rw [Projectivization.cross_mk_of_ne hv hw h]
  rw [Projectivization.orthogonal_mk] at hq1 hq2
  obtain ⟨c, hc⟩ := helper_on_both_lines_is_multiple_of_cross
    (mt (Projectivization.mk_eq_mk_iff_crossProduct_eq_zero hv hw).mpr h) hq1 hq2
  rw [Projectivization.mk_eq_mk_iff']
  exact ⟨c, hc.symm⟩

/-- The meet is a cross product. For line triples `ℓ₁`, `ℓ₂`, neither a multiple of the other,
`p = ℓ₁ × ℓ₂` is not `(0, 0, 0)`, lies on both lines, and every triple on both lines is a
multiple of it, so all of them name the one point `p`. -/
theorem cross_product_is_the_meet_of_two_lines
    (ℓ₁ ℓ₂ : Fin 3 → ℝ) (h₁ : ∀ c : ℝ, ℓ₁ ≠ c • ℓ₂) (h₂ : ∀ c : ℝ, ℓ₂ ≠ c • ℓ₁) :
    ℓ₁ ⨯₃ ℓ₂ ≠ 0 ∧ ℓ₁ ⬝ᵥ (ℓ₁ ⨯₃ ℓ₂) = 0 ∧ ℓ₂ ⬝ᵥ (ℓ₁ ⨯₃ ℓ₂) = 0 ∧
      ∀ p : Fin 3 → ℝ, ℓ₁ ⬝ᵥ p = 0 → ℓ₂ ⬝ᵥ p = 0 → ∃ c : ℝ, p = c • (ℓ₁ ⨯₃ ℓ₂) := by
  have hl1 : ℓ₁ ≠ 0 := by simpa using h₁ 0
  have hl2 : ℓ₂ ≠ 0 := by simpa using h₂ 0
  have hn : ℓ₁ ⨯₃ ℓ₂ ≠ 0 := by
    intro hx
    obtain ⟨a, ha⟩ := (Projectivization.mk_eq_mk_iff' ℝ ℓ₁ ℓ₂ hl1 hl2).1
      ((Projectivization.mk_eq_mk_iff_crossProduct_eq_zero hl1 hl2).2 hx)
    exact h₁ a ha.symm
  exact ⟨hn, dot_self_cross _ _, dot_cross_self _ _,
    fun p h1 h2 => helper_on_both_lines_is_multiple_of_cross hn h1 h2⟩

/-- Parallel lines vanish at one point. A camera with focal length `f` sends a scene point
`(X, Y, Z)` to `(f X / Z, f Y / Z)`. Walk out along any line `(X₀, Y₀, Z₀) + k d` whose
direction `d` is not parallel to the sensor (`d_Z ≠ 0`): as `k` grows, its image closes on
`(f d_X / d_Z, f d_Y / d_Z)`, the camera's image of the direction itself. The start point
drops out, so every line parallel to `d` heads for the same vanishing point. -/
theorem parallel_lines_vanish_at_image_of_direction
    (f X₀ Y₀ Z₀ dX dY dZ : ℝ) (hd : dZ ≠ 0) :
    Tendsto (fun k : ℝ => (f * (X₀ + k * dX) / (Z₀ + k * dZ), f * (Y₀ + k * dY) / (Z₀ + k * dZ)))
      atTop (𝓝 (f * dX / dZ, f * dY / dZ)) := by
  exact (helper_ratio_tendsto f X₀ dX Z₀ dZ hd).prodMk_nhds
    (helper_ratio_tendsto f Y₀ dY Z₀ dZ hd)

-- The camera matrix P for f = 50, and the ground-to-photo matrix G for f = 50, h = 3/2.
-- Left rail 10 m out: P (-1/2, -3/2, 10, 1) = (-25, -75, 10), which divides to (-5/2, -15/2).
example : !![(50 : ℚ), 0, 0, 0; 0, 50, 0, 0; 0, 0, 1, 0] *ᵥ ![-1/2, -3/2, 10, 1] = ![-25, -75, 10] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_succ]
example : (-25 : ℚ) / 10 = -5/2 ∧ (-75 : ℚ) / 10 = -15/2 := by norm_num
-- Twice as far along the same ray: (-1, -3, 20) goes to (-50, -150, 20), the same photo spot.
example : !![(50 : ℚ), 0, 0, 0; 0, 50, 0, 0; 0, 0, 1, 0] *ᵥ ![-1, -3, 20, 1] = ![-50, -150, 20] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_succ]
example : (-50 : ℚ) / 20 = -5/2 ∧ (-150 : ℚ) / 20 = -15/2 := by norm_num
-- The rails' image lines, by cross products of their photo points at 10 m and 20 m.
example : ![(-5/2 : ℚ), -15/2, 1] ⨯₃ ![-5/4, -15/4, 1] = ![-15/4, 5/4, 0] := by
  norm_num [cross_apply]
example : ![(5/2 : ℚ), -15/2, 1] ⨯₃ ![5/4, -15/4, 1] = ![-15/4, -5/4, 0] := by
  norm_num [cross_apply]
-- Road 1: the two image lines meet at (0, 0, 75/8) = (0, 0, 9.375), the photo's centre.
example : ![(-15/4 : ℚ), 5/4, 0] ⨯₃ ![-15/4, -5/4, 0] = ![0, 0, 75/8] := by
  norm_num [cross_apply]
-- Photo lines u = 1 and u = 2 meet at (0, 1, 0), a point at infinity.
example : ![(1 : ℚ), 0, -1] ⨯₃ ![1, 0, -2] = ![0, 1, 0] := by
  norm_num [cross_apply]
-- Road 2: the camera on the rails' direction (0, 0, 1, 0) gives (0, 0, 1).
example : !![(50 : ℚ), 0, 0, 0; 0, 50, 0, 0; 0, 0, 1, 0] *ᵥ ![0, 0, 1, 0] = ![0, 0, 1] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_succ]
-- Road 3: the rails X = -1/2 and X = 1/2 meet on the ground at (0, 1, 0); G sends that to (0, 0, 1).
example : ![(1 : ℚ), 0, 1/2] ⨯₃ ![1, 0, -1/2] = ![0, 1, 0] := by
  norm_num [cross_apply]
example : !![(50 : ℚ), 0, 0; 0, 0, -75; 0, 1, 0] *ᵥ ![0, 1, 0] = ![0, 0, 1] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_succ]
-- The branch line's direction (1, 0, 4, 0) goes to (50, 0, 4), the point (25/2, 0) = (12.5, 0).
example : !![(50 : ℚ), 0, 0, 0; 0, 50, 0, 0; 0, 0, 1, 0] *ᵥ ![1, 0, 4, 0] = ![50, 0, 4] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_succ]
example : (50 : ℚ) / 4 = 25/2 := by norm_num
-- The horizon: the line through both vanishing points is (0, 25/2, 0), that is v = 0.
example : ![(0 : ℚ), 0, 1] ⨯₃ ![25/2, 0, 1] = ![0, 25/2, 0] := by
  norm_num [cross_apply]
-- Mistake: joining (5/2, -15/2, 1) to (5, -15, 2), one point twice, gives (0, 0, 0), no line.
example : ![(5/2 : ℚ), -15/2, 1] ⨯₃ ![5, -15, 2] = ![0, 0, 0] := by
  norm_num [cross_apply]
-- Mistake: the sleeper 15 m out sits at v = 50 (-3/2) / 15 = -5, but the photo midpoint of the
-- 10 m and 20 m marks is v = -45/8 = -5.625.
example : (50 : ℚ) * (-3/2) / 15 = -5 ∧ ((-15/2 : ℚ) + (-15/4)) / 2 = -45/8 := by norm_num

#print axioms helper_on_both_lines_is_multiple_of_cross
#print axioms helper_ratio_tendsto
#print axioms two_distinct_lines_meet_in_exactly_one_point
#print axioms cross_product_is_the_meet_of_two_lines
#print axioms parallel_lines_vanish_at_image_of_direction
