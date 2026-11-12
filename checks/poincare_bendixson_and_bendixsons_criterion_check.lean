-- Poincare-Bendixson: the card's oscillator has a ring from radius 1/2 to 2 that traps every path and holds no resting point, its unit circle is a closed loop with lap 2π, and the divergences are 2 - 4r² for the oscillator and -2 for the shock absorber.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.Ring.Periodic

/-!
This file checks the parts of the card that Lean and Mathlib can prove exactly: the oscillator's
closed loop, its trapping ring, the divergences of the card's two example fields, and the card's
hand arithmetic.

The two theorems themselves, Poincare-Bendixson and Bendixson's criterion, are not stated here.
Mathlib cannot prove them yet: they need the Jordan curve theorem and Green's theorem in the
plane, which Mathlib does not have. They are left to the Python and Rust checks.
-/

/-- The card's oscillator, in volts and milliseconds:
`x' = x - y - x(x² + y²)`, `y' = x + y - y(x² + y²)`. -/
def oscillator (p : ℝ × ℝ) : ℝ × ℝ :=
  (p.1 - p.2 - p.1 * (p.1 ^ 2 + p.2 ^ 2), p.1 + p.2 - p.2 * (p.1 ^ 2 + p.2 ^ 2))

/-- The card's shock absorber, offset `p` in cm and speed `v` in cm/s:
`p' = v`, `v' = -5p - 2v`. -/
def shockAbsorber (q : ℝ × ℝ) : ℝ × ℝ :=
  (q.2, -5 * q.1 - 2 * q.2)

/-- The oscillator has a closed loop at swing size 1 volt: the path `(cos t, sin t)` solves the
oscillator at every time, comes back to its start after one lap of `2π` milliseconds, stays on
the circle of radius 1 (inside the ring from 1/2 to 2), and really moves (it is not a resting
point). -/
theorem oscillator_unit_circle_is_closed_loop :
    (∀ t : ℝ, HasDerivAt (fun s : ℝ => (Real.cos s, Real.sin s))
      (oscillator (Real.cos t, Real.sin t)) t) ∧
    Function.Periodic (fun s : ℝ => (Real.cos s, Real.sin s)) (2 * Real.pi) ∧
    (∀ t : ℝ, Real.cos t ^ 2 + Real.sin t ^ 2 = 1) ∧
    (Real.cos 0, Real.sin 0) ≠ (Real.cos Real.pi, Real.sin Real.pi) := by
  refine ⟨fun t => ?_, fun s => ?_, fun t => Real.cos_sq_add_sin_sq t, ?_⟩
  · have h := (Real.hasDerivAt_cos t).prodMk (Real.hasDerivAt_sin t)
    have hs := Real.cos_sq_add_sin_sq t
    have e : oscillator (Real.cos t, Real.sin t) = (-Real.sin t, Real.cos t) := by
      simp only [oscillator, Prod.mk.injEq]
      constructor
      · linear_combination (-Real.cos t) * hs
      · linear_combination (-Real.sin t) * hs
    rw [e]
    exact h
  · simp [Real.cos_add_two_pi, Real.sin_add_two_pi]
  · simp only [Real.cos_zero, Real.sin_zero, Real.cos_pi, Real.sin_pi, ne_eq, Prod.mk.injEq]
    norm_num

/-- The ring from radius 1/2 to radius 2 traps the oscillator and holds no resting point.
On the inner rim (`x² + y² = 1/4`) every arrow points outward, into the ring; on the outer rim
(`x² + y² = 4`) every arrow points inward, into the ring. Here `x·f + y·g` is `r` times the
radial rate `r'`, so its sign is the sign of `r'`. The only resting point is the origin, which
lies in the ring's hole. -/
theorem oscillator_ring_traps_and_has_no_rest :
    (∀ x y : ℝ, x ^ 2 + y ^ 2 = 1 / 4 →
      0 < x * (oscillator (x, y)).1 + y * (oscillator (x, y)).2) ∧
    (∀ x y : ℝ, x ^ 2 + y ^ 2 = 4 →
      x * (oscillator (x, y)).1 + y * (oscillator (x, y)).2 < 0) ∧
    (∀ x y : ℝ, oscillator (x, y) = 0 → x = 0 ∧ y = 0) := by
  refine ⟨fun x y h => ?_, fun x y h => ?_, fun x y h => ?_⟩
  · have e : x * (oscillator (x, y)).1 + y * (oscillator (x, y)).2
        = (x ^ 2 + y ^ 2) - (x ^ 2 + y ^ 2) ^ 2 := by simp only [oscillator]; ring
    rw [e, h]; norm_num
  · have e : x * (oscillator (x, y)).1 + y * (oscillator (x, y)).2
        = (x ^ 2 + y ^ 2) - (x ^ 2 + y ^ 2) ^ 2 := by simp only [oscillator]; ring
    rw [e, h]; norm_num
  · simp only [oscillator, Prod.mk_eq_zero] at h
    obtain ⟨hf, hg⟩ := h
    have hr : x ^ 2 + y ^ 2 = 0 := by linear_combination (-y) * hf + x * hg
    constructor <;> nlinarith [sq_nonneg x, sq_nonneg y]

/-- The divergences of the card's two fields, `f_x + g_y`, where `f_x` is how fast `f` changes
as `x` moves with `y` held fixed, and `g_y` likewise. For the oscillator it is `2 - 4(x² + y²)`
at every point; for the shock absorber it is `-2` per second at every point. -/
theorem card_fields_divergence :
    (∀ x y : ℝ, deriv (fun x' : ℝ => (oscillator (x', y)).1) x
        + deriv (fun y' : ℝ => (oscillator (x, y')).2) y = 2 - 4 * (x ^ 2 + y ^ 2)) ∧
    (∀ p v : ℝ, deriv (fun p' : ℝ => (shockAbsorber (p', v)).1) p
        + deriv (fun v' : ℝ => (shockAbsorber (p, v')).2) v = -2) := by
  refine ⟨fun x y => ?_, fun p v => ?_⟩
  · have h1 : HasDerivAt (fun x' : ℝ => (oscillator (x', y)).1) (1 - (3 * x ^ 2 + y ^ 2)) x := by
      have := ((hasDerivAt_id x).sub_const y).sub
        ((hasDerivAt_id x).mul (((hasDerivAt_id x).pow 2).add_const (y ^ 2)))
      convert this using 1
      · funext z; simp [oscillator]
      · simp; ring
    have h2 : HasDerivAt (fun y' : ℝ => (oscillator (x, y')).2) (1 - (x ^ 2 + 3 * y ^ 2)) y := by
      have := ((hasDerivAt_id y).const_add x).sub
        ((hasDerivAt_id y).mul (((hasDerivAt_id y).pow 2).const_add (x ^ 2)))
      convert this using 1
      · funext z; simp [oscillator]
      · simp; ring
    rw [h1.deriv, h2.deriv]; ring
  · have h1 : HasDerivAt (fun p' : ℝ => (shockAbsorber (p', v)).1) 0 p := by
      simpa [shockAbsorber] using hasDerivAt_const p v
    have h2 : HasDerivAt (fun v' : ℝ => (shockAbsorber (p, v')).2) (-2) v := by
      have := ((hasDerivAt_id v).const_mul 2).const_sub (-5 * p)
      convert this using 1
      · simp [shockAbsorber]
      · simp
    rw [h1.deriv, h2.deriv]; ring

-- Worked numbers from the card.
-- Inner rim r = 1/2: r' = r(1 - r²) = 3/8 > 0, arrows point outward into the ring.
example : (1 / 2 : ℚ) * (1 - (1 / 2) ^ 2) = 3 / 8 := by norm_num
-- Outer rim r = 2: r' = r(1 - r²) = -6 < 0, arrows point inward into the ring.
example : (2 : ℚ) * (1 - 2 ^ 2) = -6 := by norm_num
-- Shock absorber divergence: slope of v along p, plus slope of -5p - 2v along v: 0 + (-2) = -2.
example : (0 : ℤ) + (-2) = -2 := by norm_num
-- Bendixson on the ring: oscillator divergence 2 - 4r² at r = 0, 1/2, 1, 2 is 2, 1, -2, -14.
example : (2 : ℚ) - 4 * 0 ^ 2 = 2 ∧ (2 : ℚ) - 4 * (1 / 2) ^ 2 = 1 ∧
    (2 : ℚ) - 4 * 1 ^ 2 = -2 ∧ (2 : ℚ) - 4 * 2 ^ 2 = -14 := by norm_num
-- Edge sum round the ellipse 5p² + v² = 25: -2 × π × √5 × 5, which is not 0.
example : -2 * Real.pi * Real.sqrt 5 * 5 ≠ 0 := by norm_num [Real.pi_ne_zero]

#print axioms oscillator_unit_circle_is_closed_loop
#print axioms oscillator_ring_traps_and_has_no_rest
#print axioms card_fields_divergence
