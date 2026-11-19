-- Curvature: the signed curvature (x'y'' - y'x'') / speed^3 of a plane curve is the turn of its direction angle per metre of track, is +1/R on a circle of radius R traced anticlockwise, and keeps its value under every change of parameter in the same direction while flipping sign when the curve is traced backwards.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.ArctanDeriv
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Real

/-- The card's signed curvature of the plane curve t ↦ (x(t), y(t)) at the parameter value t:
the cross term of velocity (x', y') and acceleration (x'', y''), x' y'' − y' x'', divided by
the speed √(x'^2 + y'^2) cubed. Positive means turning left (anticlockwise). -/
noncomputable def signedCurvature (x y : ℝ → ℝ) (t : ℝ) : ℝ :=
  (deriv x t * deriv (deriv y) t - deriv y t * deriv (deriv x) t) /
    √(deriv x t ^ 2 + deriv y t ^ 2) ^ 3

/-- **Curvature belongs to the track, not to the timing.** Take a plane curve t ↦ (x(t), y(t))
whose coordinates have first and second derivatives, and a re-timing t = g(u), also with first
and second derivatives. At a point where the curve's speed is not zero (the curve is regular
there) and the re-timing's rate λ = g'(u) is not zero, the re-timed curve u ↦ (x(g(u)), y(g(u)))
has the same signed curvature as the original curve at t = g(u) when λ > 0 (same direction of
travel), and the negative of it when λ < 0 (ridden backwards). -/
theorem signed_curvature_independent_of_parametrisation {x y g : ℝ → ℝ} {u : ℝ}
    (hx : Differentiable ℝ x) (hx2 : Differentiable ℝ (deriv x))
    (hy : Differentiable ℝ y) (hy2 : Differentiable ℝ (deriv y))
    (hg : Differentiable ℝ g) (hg2 : Differentiable ℝ (deriv g))
    (hreg : deriv x (g u) ^ 2 + deriv y (g u) ^ 2 ≠ 0) (hrate : deriv g u ≠ 0) :
    (0 < deriv g u → signedCurvature (x ∘ g) (y ∘ g) u = signedCurvature x y (g u)) ∧
    (deriv g u < 0 → signedCurvature (x ∘ g) (y ∘ g) u = -signedCurvature x y (g u)) := by
  have hS : (0:ℝ) ≤ deriv x (g u) ^ 2 + deriv y (g u) ^ 2 := by positivity
  have dcomp : ∀ f : ℝ → ℝ, Differentiable ℝ f →
      deriv (f ∘ g) = fun v => deriv f (g v) * deriv g v := by
    intro f hf
    funext v
    exact deriv_comp v (hf (g v)) (hg v)
  have d2comp : ∀ f : ℝ → ℝ, Differentiable ℝ f → Differentiable ℝ (deriv f) →
      deriv (deriv (f ∘ g)) u =
        deriv (deriv f) (g u) * deriv g u * deriv g u + deriv f (g u) * deriv (deriv g) u := by
    intro f hf hf2
    rw [dcomp f hf]
    have h1 : HasDerivAt (fun v => deriv f (g v))
        (deriv (deriv f) (g u) * deriv g u) u :=
      (hf2 (g u)).hasDerivAt.comp u (hg u).hasDerivAt
    have h2 : HasDerivAt (deriv g) (deriv (deriv g) u) u := (hg2 u).hasDerivAt
    exact (h1.mul h2).deriv
  have key : signedCurvature (x ∘ g) (y ∘ g) u =
      (deriv g u ^ 3 / |deriv g u| ^ 3) * signedCurvature x y (g u) := by
    unfold signedCurvature
    rw [d2comp x hx hx2, d2comp y hy hy2, dcomp x hx, dcomp y hy]
    have hsq : (deriv x (g u) * deriv g u) ^ 2 + (deriv y (g u) * deriv g u) ^ 2 =
        deriv g u ^ 2 * (deriv x (g u) ^ 2 + deriv y (g u) ^ 2) := by ring
    simp only []
    rw [hsq, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq_eq_abs]
    have ha : |deriv g u| ≠ 0 := abs_ne_zero.mpr hrate
    have hs : √(deriv x (g u) ^ 2 + deriv y (g u) ^ 2) ≠ 0 := by
      rw [Ne, Real.sqrt_eq_zero hS]; exact hreg
    field_simp
    ring
  refine ⟨fun h => ?_, fun h => ?_⟩
  · rw [key, abs_of_pos h, div_self (by positivity), one_mul]
  · rw [key, abs_of_neg h]
    have : (-deriv g u) ^ 3 ≠ 0 := pow_ne_zero _ (by linarith)
    rw [show deriv g u ^ 3 = -((-deriv g u) ^ 3) by ring, neg_div, div_self this]
    ring

/-- **Curvature is the turn of the direction per metre.** Where the curve moves eastward
(x'(t) > 0), its direction angle is θ(t) = arctan(y'(t)/x'(t)). The rate of θ per second, divided
by the speed √(x'^2 + y'^2) (metres of track per second), equals the signed curvature: κ = dθ/ds. -/
theorem signed_curvature_eq_turn_of_direction_per_metre {x y : ℝ → ℝ} {t : ℝ}
    (hx : Differentiable ℝ x) (hx2 : Differentiable ℝ (deriv x))
    (hy : Differentiable ℝ y) (hy2 : Differentiable ℝ (deriv y))
    (hpos : 0 < deriv x t) :
    deriv (fun s => arctan (deriv y s / deriv x s)) t / √(deriv x t ^ 2 + deriv y t ^ 2) =
      signedCurvature x y t := by
  have hx2t : HasDerivAt (deriv x) (deriv (deriv x) t) t := (hx2 t).hasDerivAt
  have hy2t : HasDerivAt (deriv y) (deriv (deriv y) t) t := (hy2 t).hasDerivAt
  have hne : deriv x t ≠ 0 := hpos.ne'
  have hq := hy2t.div hx2t hne
  have ha := hq.arctan
  rw [show (fun s => arctan (deriv y s / deriv x s)) = fun s => arctan ((deriv y / deriv x) s)
    from rfl, ha.deriv, Pi.div_apply]
  unfold signedCurvature
  have hS : 0 < deriv x t ^ 2 + deriv y t ^ 2 := by positivity
  have hs : 0 < √(deriv x t ^ 2 + deriv y t ^ 2) := Real.sqrt_pos.mpr hS
  have h3 : √(deriv x t ^ 2 + deriv y t ^ 2) ^ 3 =
      (deriv x t ^ 2 + deriv y t ^ 2) * √(deriv x t ^ 2 + deriv y t ^ 2) := by
    rw [pow_succ, Real.sq_sqrt hS.le]
  rw [h3]
  field_simp

/-- **A circle turns at 1 over its radius.** The circle of radius R > 0 traced anticlockwise,
t ↦ (R cos t, R sin t), has signed curvature +1/R at every point: positive, since it turns left. -/
theorem signed_curvature_of_circle {R : ℝ} (hR : 0 < R) (t : ℝ) :
    signedCurvature (fun s => R * cos s) (fun s => R * sin s) t = 1 / R := by
  have dc : deriv (fun s => R * cos s) = fun s => -(R * sin s) := by
    funext s; simp
  have ds : deriv (fun s => R * sin s) = fun s => R * cos s := by
    funext s; simp
  have dc2 : deriv (fun s => -(R * sin s)) = fun s => -(R * cos s) := by
    funext s; simp
  unfold signedCurvature
  simp only [dc, ds, dc2]
  have h : (-(R * sin t)) ^ 2 + (R * cos t) ^ 2 = R ^ 2 := by
    nlinarith [sin_sq_add_cos_sq t]
  rw [h, Real.sqrt_sq hR.le]
  have : (-(R * sin t)) * (-(R * sin t)) - R * cos t * (-(R * cos t)) = R ^ 2 := by
    nlinarith [sin_sq_add_cos_sq t]
  rw [this]
  field_simp

-- The bend r(t) = (8t − 0.1t^3, 0.09t^3) m, with 0.1 = 1/10 and 0.09 = 9/100.
-- Its velocity (8 − 0.3t^2, 0.27t^2) and acceleration (−0.6t, 0.54t) give the cross term
-- x'y'' − y'x'' = 6 · 8 · 0.09 · t = 4.32t = (108/25)t for every t.
example : ∀ t : ℚ, (8 - 3 / 10 * t ^ 2) * (54 / 100 * t) - (27 / 100 * t ^ 2) * (-(6 / 10) * t) =
    6 * 8 * (9 / 100) * t := by
  intro t; ring
-- At 4 s: position (25.60, 5.76) = (128/5, 144/25) m.
example : (8 : ℚ) * 4 - 1 / 10 * 4 ^ 3 = 128 / 5 ∧ (9 : ℚ) / 100 * 4 ^ 3 = 144 / 25 := by norm_num
-- At 4 s: velocity (3.20, 4.32) = (16/5, 108/25) m/s.
example : (8 : ℚ) - 3 / 10 * 4 ^ 2 = 16 / 5 ∧ (27 : ℚ) / 100 * 4 ^ 2 = 108 / 25 := by norm_num
-- At 4 s: acceleration (−2.40, 2.16) = (−12/5, 54/25) m/s^2.
example : -(6 : ℚ) / 10 * 4 = -12 / 5 ∧ (54 : ℚ) / 100 * 4 = 54 / 25 := by norm_num
-- Cross term at 4 s: 3.20 × 2.16 − 4.32 × (−2.40) = 17.28 = 432/25.
example : (16 : ℚ) / 5 * (54 / 25) - 108 / 25 * (-12 / 5) = 432 / 25 := by norm_num
-- Speed squared at 4 s: 3.20^2 + 4.32^2 = 28.9024 = 18064/625.
example : ((16 : ℚ) / 5) ^ 2 + (108 / 25) ^ 2 = 18064 / 625 := by norm_num
-- The direction at 4 s has tan θ = 4.32 / 3.20 = 1.35 = 27/20, the total turn atan 1.35.
example : ((108 : ℚ) / 25) / (16 / 5) = 27 / 20 := by norm_num
-- The cusp (u^2, u^3): velocity (2u, 3u^2) is (0, 0) at u = 0, so the speed is zero there.
example : (2 : ℚ) * 0 = 0 ∧ (3 : ℚ) * 0 ^ 2 = 0 := by norm_num
-- The slow-start ride t = u^2/4 has rate λ = 2u/4 = u/2, zero only at u = 0.
example : ∀ u : ℚ, 2 * u / 4 = u / 2 := by intro u; ring

#print axioms signed_curvature_independent_of_parametrisation
#print axioms signed_curvature_eq_turn_of_direction_per_metre
#print axioms signed_curvature_of_circle
