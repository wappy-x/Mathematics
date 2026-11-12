-- Cauchy's integral formula: for a function with a complex derivative on and inside a circle, the value at any point strictly inside equals 1/(2πi) times the loop integral of f(z)/(z − a) once anticlockwise round the circle, the value at a circle's centre is the plain average of the rim values, and the same loop integral is 0 for a point strictly outside.
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.MeasureTheory.Integral.CircleIntegral

open Complex Metric Real

/-- **Cauchy's integral formula.** Let the loop C be the circle of radius R round the point c,
walked once anticlockwise. If f has a complex derivative at every point on and inside the loop
(f is complex-differentiable on the closed disc of radius R round c) and the point a lies
strictly inside the loop, then the value f(a) equals one over 2πi times the loop integral
of f(z)/(z − a):  f(a) = (1/(2πi)) ∮_C f(z)/(z − a) dz.
(Mathlib's contour integrals run over circles, so the loop here is a circle, as on the card's
pizza stone.) -/
theorem value_inside_eq_loop_integral {f : ℂ → ℂ} {c a : ℂ} {R : ℝ}
    (hf : DifferentiableOn ℂ f (closedBall c R)) (ha : a ∈ ball c R) :
    f a = (1 / (2 * π * I)) * ∮ z in C(c, R), f z / (z - a) := by
  have h := (hf.mono closure_ball_subset_closedBall).diffContOnCl.circleIntegral_sub_inv_smul ha
  have h2 : (∮ z in C(c, R), f z / (z - a)) = 2 * π * I * f a := by
    simpa only [smul_eq_mul, div_eq_inv_mul] using h
  rw [h2]
  have : (2 * π * I : ℂ) ≠ 0 := by simp [Real.pi_ne_zero, I_ne_zero]
  field_simp

/-- **The average form.** If f has a complex derivative on and inside the circle of radius
r > 0 centred at a, then the value at the centre is the plain average of the rim values:
f(a) = (1/(2π)) ∫ from 0 to 2π of f(a + r e^{iθ}) dθ. -/
theorem value_at_centre_eq_rim_average {f : ℂ → ℂ} {a : ℂ} {r : ℝ} (hr : 0 < r)
    (hf : DifferentiableOn ℂ f (closedBall a r)) :
    f a = (1 / (2 * π) : ℂ) * ∫ θ in (0 : ℝ)..2 * π, f (a + r * exp (θ * I)) := by
  have h := value_inside_eq_loop_integral hf (mem_ball_self hr)
  rw [h, circleIntegral]
  have hne : ∀ θ : ℝ, (r : ℂ) * exp (θ * I) ≠ 0 := fun θ => by
    simp [hr.ne', Complex.exp_ne_zero]
  have : ∀ θ : ℝ, deriv (circleMap a r) θ • (f (circleMap a r θ) / (circleMap a r θ - a))
      = I * f (a + r * exp (θ * I)) := by
    intro θ
    rw [deriv_circleMap, smul_eq_mul]
    simp only [circleMap, add_sub_cancel_left, zero_add]
    have hr0 : (r : ℂ) ≠ 0 := by exact_mod_cast hr.ne'
    field_simp [hne θ, hr0]
  simp_rw [this]
  rw [intervalIntegral.integral_const_mul]
  have : (2 * π * I : ℂ) ≠ 0 := by simp [Real.pi_ne_zero, I_ne_zero]
  have : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  field_simp

/-- **A point outside gives 0.** Let the loop be the circle of radius R ≥ 0 round c, walked
once anticlockwise. If f has a complex derivative on and inside the loop (on the closed disc
of radius R round c) and the point a lies strictly outside that closed disc, then the loop
integral of f(z)/(z − a) is 0.
(The radius is required to be at least 0 because Mathlib's circle C(c, R) with R < 0 still
traces the circle of radius |R|, while the disc of radius R would then be empty, so the
hypothesis on f would say nothing about the loop.) -/
theorem loop_integral_eq_zero_of_outside {f : ℂ → ℂ} {c a : ℂ} {R : ℝ} (hR : 0 ≤ R)
    (hf : DifferentiableOn ℂ f (closedBall c R)) (ha : a ∉ closedBall c R) :
    (∮ z in C(c, R), f z / (z - a)) = 0 := by
  have hg : DifferentiableOn ℂ (fun z => f z / (z - a)) (closedBall c R) := by
    refine hf.div (differentiableOn_id.sub_const a) fun z hz h0 => ha ?_
    rw [sub_eq_zero] at h0
    exact h0 ▸ hz
  exact (hg.mono closure_ball_subset_closedBall).diffContOnCl.circleIntegral_eq_zero hR

-- The card's pizza stone is the circle of radius 2 round 0.
-- The centre 0 and the point 0.5 lie strictly inside it.
example : (0 : ℂ) ∈ ball (0 : ℂ) 2 := by norm_num
example : (1 / 2 : ℂ) ∈ ball (0 : ℂ) 2 := by norm_num
-- The point 4 lies strictly outside, and so does the pole at 3 in Step 6.
example : (4 : ℂ) ∉ closedBall (0 : ℂ) 2 := by norm_num
example : (3 : ℂ) ∉ closedBall (0 : ℂ) 2 := by norm_num
-- Road one at the centre: e^0 = 1.
example : Complex.exp 0 = 1 := by norm_num

#print axioms value_inside_eq_loop_integral
#print axioms value_at_centre_eq_rim_average
#print axioms loop_integral_eq_zero_of_outside
