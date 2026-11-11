-- Gradient: where a function of n real inputs has a tangent plane, its gradient is the list of its partial derivatives, the rate along any direction of length 1 is the gradient dotted with that direction, the steepest climb runs along the gradient at a rate equal to its length, and the gradient meets every level curve through the point at a right angle.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Slope

open Filter Topology InnerProductGeometry
open scoped Gradient RealInnerProductSpace

/-! The map is `EuclideanSpace ℝ (Fin n)`: n inputs, all in one unit and at right angles to
each other (for the skier, n = 2: metres east and metres north). `h` is the height, `p` the
point, and `∇ h p` is Mathlib's gradient of `h` at `p`. "A tangent plane at p" is
`DifferentiableAt ℝ h p`. The partial derivative in coordinate `i` is the rate of `h` along the
`i`-th unit arrow `EuclideanSpace.single i 1`, every other input held fixed. -/

/-- Helper: the rate of `h` along the line through `p` in direction `v` is `fderiv h p v`. -/
theorem gd_line_hasDerivAt {n : ℕ}
    (h : EuclideanSpace ℝ (Fin n) → ℝ) (p v : EuclideanSpace ℝ (Fin n))
    (hh : DifferentiableAt ℝ h p) :
    HasDerivAt (fun s : ℝ => h (p + s • v)) (fderiv ℝ h p v) 0 := by
  have hl : HasDerivAt (fun s : ℝ => p + s • v) v 0 := by
    simpa using ((hasDerivAt_id (0:ℝ)).smul_const v).const_add p
  have hh' : HasFDerivAt h (fderiv ℝ h p) (p + (0:ℝ) • v) := by
    simpa using hh.hasFDerivAt
  exact hh'.comp_hasDerivAt (0:ℝ) hl

/-- The rate in any direction. Where the height `h` has a tangent plane at `p`: the gradient's
`i`-th part is the partial derivative of `h` in coordinate `i`; and for every direction `u` of
length 1, the rate of height per unit travelled from `p` along `u`, the limit of
`(h(p + t u) − h(p)) / t` as `t` shrinks to 0, is the gradient dotted with `u`. That dot product
is the sum of each partial derivative times `u`'s share in that coordinate, and it equals the
gradient's length times the cosine of the angle between the gradient and `u`. -/
theorem directional_derivative_eq_gradient_dot_direction {n : ℕ}
    (h : EuclideanSpace ℝ (Fin n) → ℝ) (p : EuclideanSpace ℝ (Fin n))
    (hh : DifferentiableAt ℝ h p) :
    (∀ i : Fin n, ∇ h p i = deriv (fun s : ℝ => h (p + s • EuclideanSpace.single i 1)) 0) ∧
    ∀ u : EuclideanSpace ℝ (Fin n), ‖u‖ = 1 →
      Tendsto (fun t : ℝ => (h (p + t • u) - h p) / t) (𝓝[≠] 0) (𝓝 ⟪∇ h p, u⟫) ∧
      ⟪∇ h p, u⟫ = ∑ i, ∇ h p i * u i ∧
      ⟪∇ h p, u⟫ = ‖∇ h p‖ * Real.cos (angle (∇ h p) u) := by
  refine ⟨fun i => ?_, fun u hu => ⟨?_, ?_, ?_⟩⟩
  · rw [(gd_line_hasDerivAt h p _ hh).deriv, ← inner_gradient_left,
      EuclideanSpace.inner_single_right]
    simp
  · have hd := hasDerivAt_iff_tendsto_slope.mp (gd_line_hasDerivAt h p u hh)
    rw [← inner_gradient_left] at hd
    refine hd.congr' ?_
    filter_upwards with t
    simp [slope_def_field]
  · rw [PiLp.inner_apply]
    refine Finset.sum_congr rfl fun i _ => ?_
    simp [mul_comm]
  · rw [← cos_angle_mul_norm_mul_norm, hu]
    ring

/-- The steepest climb and the fall line. Where `h` has a tangent plane at `p` and the gradient
there is not zero, every rate `∇h(p) · u` along a direction `u` of length 1 lies between minus
the gradient's length and the gradient's length. The top rate, the gradient's length, is reached
only along the gradient itself (scaled to length 1), and the bottom rate, minus that length,
only straight against it. -/
theorem gradient_points_up_the_steepest_climb {n : ℕ}
    (h : EuclideanSpace ℝ (Fin n) → ℝ) (p : EuclideanSpace ℝ (Fin n))
    (hh : DifferentiableAt ℝ h p) (hg : ∇ h p ≠ 0) :
    ∀ u : EuclideanSpace ℝ (Fin n), ‖u‖ = 1 →
      (-‖∇ h p‖ ≤ ⟪∇ h p, u⟫ ∧ ⟪∇ h p, u⟫ ≤ ‖∇ h p‖) ∧
      (⟪∇ h p, u⟫ = ‖∇ h p‖ ↔ u = ‖∇ h p‖⁻¹ • ∇ h p) ∧
      (⟪∇ h p, u⟫ = -‖∇ h p‖ ↔ u = -(‖∇ h p‖⁻¹ • ∇ h p)) := by
  intro u hu
  set g := ∇ h p with hgdef
  have hgn : ‖g‖ ≠ 0 := norm_ne_zero_iff.mpr hg
  have hb := abs_real_inner_le_norm g u
  rw [hu, mul_one] at hb
  refine ⟨abs_le.mp hb, ?_, ?_⟩
  · have key := @inner_eq_norm_mul_iff_real _ _ _ g u
    rw [hu, mul_one, one_smul] at key
    rw [key]
    constructor
    · intro e
      calc u = ‖g‖⁻¹ • (‖g‖ • u) := by rw [smul_smul, inv_mul_cancel₀ hgn, one_smul]
        _ = ‖g‖⁻¹ • g := by rw [← e]
    · intro e
      rw [e, smul_smul, mul_inv_cancel₀ hgn, one_smul]
  · have key := @inner_eq_norm_mul_iff_real _ _ _ g (-u)
    rw [norm_neg, hu, mul_one, one_smul, inner_neg_right, neg_eq_iff_eq_neg] at key
    rw [key]
    constructor
    · intro e
      calc u = -(‖g‖⁻¹ • (‖g‖ • -u)) := by
            rw [smul_smul, inv_mul_cancel₀ hgn, one_smul, neg_neg]
        _ = -(‖g‖⁻¹ • g) := by rw [← e]
    · intro e
      rw [e, neg_neg, smul_smul, mul_inv_cancel₀ hgn, one_smul]

/-- The right angle to the contours. Where `h` has a tangent plane at `p`, take a contour through
`p`: a curve `c` with `c(0) = p`, staying at the height `h(p)` for every parameter near 0, and
with a non-zero velocity `w = c'(0)` at `p`. Then the gradient at `p` stands at a right angle to
the contour's direction `w`. -/
theorem gradient_perpendicular_to_contour {n : ℕ}
    (h : EuclideanSpace ℝ (Fin n) → ℝ) (p : EuclideanSpace ℝ (Fin n))
    (hh : DifferentiableAt ℝ h p)
    (c : ℝ → EuclideanSpace ℝ (Fin n)) (w : EuclideanSpace ℝ (Fin n))
    (hc0 : c 0 = p) (hc : HasDerivAt c w 0) (hw : w ≠ 0)
    (hlevel : ∀ᶠ τ in 𝓝 0, h (c τ) = h p) :
    angle (∇ h p) w = Real.pi / 2 := by
  rw [← inner_eq_zero_iff_angle_eq_pi_div_two, inner_gradient_left]
  have hh' : HasFDerivAt h (fderiv ℝ h p) (c 0) := by
    rw [hc0]; exact hh.hasFDerivAt
  have h1 : HasDerivAt (fun τ => h (c τ)) (fderiv ℝ h p w) 0 := hh'.comp_hasDerivAt 0 hc
  have h2 : HasDerivAt (fun τ => h (c τ)) 0 0 :=
    (hasDerivAt_const (0:ℝ) (h p)).congr_of_eventuallyEq hlevel
  exact h1.unique h2

/-! The card's worked numbers, exactly, as fractions. The slope is
h(x, y) = 500 − x²/800 − y²/400 and the skier stands at p = (120, 80). -/

-- Height at p: 500 − 14400/800 − 6400/400 = 466 m.
example : (500 : ℚ) - 120 ^ 2 / 800 - 80 ^ 2 / 400 = 466 := by norm_num

-- East rate −x/400 = −0.3 and north rate −y/200 = −0.4 at p.
example : -(120 : ℚ) / 400 = -3 / 10 ∧ -(80 : ℚ) / 200 = -4 / 10 := by norm_num

-- Gradient length: 0.09 + 0.16 = 0.25, the square of 0.5.
example : (-3 / 10 : ℚ) ^ 2 + (-4 / 10) ^ 2 = (1 / 2) ^ 2 := by norm_num

-- The fall line (0.6, 0.8) has length 1, and so does the level direction (−0.8, 0.6).
example : (6 / 10 : ℚ) ^ 2 + (8 / 10) ^ 2 = 1 ∧ (-8 / 10 : ℚ) ^ 2 + (6 / 10) ^ 2 = 1 := by norm_num

-- Rate on the fall line: −0.3 × 0.6 + (−0.4) × 0.8 = −0.5 m per metre.
example : (-3 / 10 : ℚ) * (6 / 10) + (-4 / 10) * (8 / 10) = -1 / 2 := by norm_num

-- Along the contour: −0.3 × (−0.8) + (−0.4) × 0.6 = 0.
example : (-3 / 10 : ℚ) * (-8 / 10) + (-4 / 10) * (6 / 10) = 0 := by norm_num

-- Mistake: the arrow (1, 1) is not of length 1 and gives −0.7, beyond the steepest −0.5.
example : (-3 / 10 : ℚ) * 1 + (-4 / 10) * 1 = -7 / 10 := by norm_num

-- Mistake: skiing along +gradient climbs: −0.3 × (−0.6) + (−0.4) × (−0.8) = +0.5.
example : (-3 / 10 : ℚ) * (-6 / 10) + (-4 / 10) * (-8 / 10) = 1 / 2 := by norm_num

-- Down the fall line, h(p + t u) = 466 − 0.5 t − 0.00205 t² for every step t.
example (t : ℚ) :
    500 - (120 + 6 / 10 * t) ^ 2 / 800 - (80 + 8 / 10 * t) ^ 2 / 400
      = 466 - t / 2 - 205 / 100000 * t ^ 2 := by ring

-- The straight 20 m traverse along (−0.8, 0.6) ends at (104, 92), 0.68 m below 466 m.
example : ((500 : ℚ) - 104 ^ 2 / 800 - 92 ^ 2 / 400) - 466 = -68 / 100 := by norm_num

#print axioms gd_line_hasDerivAt
#print axioms directional_derivative_eq_gradient_dot_direction
#print axioms gradient_points_up_the_steepest_climb
#print axioms gradient_perpendicular_to_contour
