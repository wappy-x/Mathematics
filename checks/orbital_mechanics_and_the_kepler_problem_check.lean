-- Orbits: under an inverse-square pull toward the origin, a body keeps a fixed turning amount h and moves on a conic with the origin at a focus, its speed obeys the vis-viva equation, and the period of an ellipse is 2π√(a³/μ).
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Pow

lemma kepler_const_of_hasDerivAt_zero {f : ℝ → ℝ} (hf : ∀ t, HasDerivAt f 0 t) :
    ∀ t, f t = f 0 := fun t =>
  is_const_of_deriv_eq_zero (fun s => (hf s).differentiableAt) (fun s => (hf s).deriv) t 0

lemma kepler_normSq_pos {x y : ℝ} (h : (x, y) ≠ (0, 0)) : 0 < x ^ 2 + y ^ 2 := by
  have : x ≠ 0 ∨ y ≠ 0 := by
    by_contra hc
    push Not at hc
    exact h (by simp [hc.1, hc.2])
  rcases this with hx | hy
  · have := sq_pos_of_ne_zero hx; nlinarith [sq_nonneg y]
  · have := sq_pos_of_ne_zero hy; nlinarith [sq_nonneg x]

lemma kepler_radius_hasDerivAt (x y vx vy : ℝ → ℝ) (t : ℝ)
    (hne : (x t, y t) ≠ (0, 0))
    (hx : HasDerivAt x (vx t) t) (hy : HasDerivAt y (vy t) t) :
    HasDerivAt (fun s => Real.sqrt (x s ^ 2 + y s ^ 2))
      ((x t * vx t + y t * vy t) / Real.sqrt (x t ^ 2 + y t ^ 2)) t := by
  have hpos := kepler_normSq_pos hne
  have h1 : HasDerivAt (fun s => x s ^ 2 + y s ^ 2)
      (2 * x t * vx t + 2 * y t * vy t) t := by
    have := (hx.pow 2).add (hy.pow 2)
    convert this using 1
    simp
  convert h1.sqrt hpos.ne' using 1
  have hs : 0 < Real.sqrt (x t ^ 2 + y t ^ 2) := Real.sqrt_pos.mpr hpos
  field_simp

lemma kepler_vis_viva_algebra (μ E H r r1 r2 v v1 v2 : ℝ) (hr : 0 < r) (hr1 : 0 < r1)
    (hr2 : 0 < r2) (hne : r1 ≠ r2) (h1 : v1 * r1 ^ 2 = H ^ 2) (h2 : v2 * r2 ^ 2 = H ^ 2)
    (e1 : v1 / 2 - μ / r1 = E) (e2 : v2 / 2 - μ / r2 = E) (e : v / 2 - μ / r = E) :
    v = μ * (2 / r - 1 / ((r1 + r2) / 2)) := by
  have k1 : 2 * E * r1 ^ 2 = H ^ 2 - 2 * μ * r1 := by
    rw [← e1, ← h1]; field_simp
  have k2 : 2 * E * r2 ^ 2 = H ^ 2 - 2 * μ * r2 := by
    rw [← e2, ← h2]; field_simp
  have key : (r1 - r2) * (E * (r1 + r2) + μ) = 0 := by linear_combination (k1 - k2) / 2
  have hE : E * (r1 + r2) + μ = 0 :=
    (mul_eq_zero.mp key).resolve_left (sub_ne_zero.mpr hne)
  have hv : v = 2 * E + 2 * μ / r := by rw [← e]; ring
  rw [hv]
  have hsum : 0 < r1 + r2 := by linarith
  field_simp
  linear_combination r * hE

/-- Kepler's first and second laws. A body at position `(x t, y t)` with velocity
`(vx t, vy t)` moves under the inverse-square pull `r'' = -μ r / |r|³` toward the origin,
with `μ > 0`, in one plane, and never sits at the origin. Then the turning amount
`h = x vy - y vx` (which equals `r² θ'`, twice the rate of sweeping area) never changes,
and the path is a conic with the origin at a focus: there is a fixed eccentricity
vector `(ex, ey)` with `r + ex x + ey y = h² / μ` at every moment. With `e = |(ex, ey)|`
and `θ` the angle from the direction of `(ex, ey)`, this is `r (1 + e cos θ) = p`,
that is `r = p / (1 + e cos θ)` with `p = h² / μ`. -/
theorem inverse_square_orbit_is_conic_with_constant_h
    (μ : ℝ) (hμ : 0 < μ) (x y vx vy : ℝ → ℝ)
    (hne : ∀ t, (x t, y t) ≠ (0, 0))
    (hx : ∀ t, HasDerivAt x (vx t) t) (hy : ∀ t, HasDerivAt y (vy t) t)
    (hvx : ∀ t, HasDerivAt vx (-μ * x t / Real.sqrt (x t ^ 2 + y t ^ 2) ^ 3) t)
    (hvy : ∀ t, HasDerivAt vy (-μ * y t / Real.sqrt (x t ^ 2 + y t ^ 2) ^ 3) t) :
    ∃ h ex ey : ℝ, ∀ t,
      x t * vy t - y t * vx t = h ∧
      Real.sqrt (x t ^ 2 + y t ^ 2) + (ex * x t + ey * y t) = h ^ 2 / μ := by
  -- the turning amount is constant
  have hH : ∀ t, x t * vy t - y t * vx t = x 0 * vy 0 - y 0 * vx 0 := by
    refine kepler_const_of_hasDerivAt_zero (f := fun t => x t * vy t - y t * vx t) ?_
    intro t
    have := ((hx t).mul (hvy t)).sub ((hy t).mul (hvx t))
    convert this using 1
    ring
  obtain ⟨H, hHdef⟩ : ∃ H, H = x 0 * vy 0 - y 0 * vx 0 := ⟨_, rfl⟩
  rw [← hHdef] at hH
  -- the eccentricity vector is constant
  have hE1 : ∀ t, vy t * H / μ - x t / Real.sqrt (x t ^ 2 + y t ^ 2) =
      vy 0 * H / μ - x 0 / Real.sqrt (x 0 ^ 2 + y 0 ^ 2) := by
    refine kepler_const_of_hasDerivAt_zero
      (f := fun t => vy t * H / μ - x t / Real.sqrt (x t ^ 2 + y t ^ 2)) ?_
    intro t
    have hpos := kepler_normSq_pos (hne t)
    have hs : 0 < Real.sqrt (x t ^ 2 + y t ^ 2) := Real.sqrt_pos.mpr hpos
    have hs2 : Real.sqrt (x t ^ 2 + y t ^ 2) ^ 2 = x t ^ 2 + y t ^ 2 :=
      Real.sq_sqrt hpos.le
    have := (((hvy t).mul_const H).div_const μ).sub
      ((hx t).div (kepler_radius_hasDerivAt x y vx vy t (hne t) (hx t) (hy t)) hs.ne')
    convert this using 1
    rw [← hH t]
    field_simp
    linear_combination (vx t) * hs2
  have hE2 : ∀ t, -vx t * H / μ - y t / Real.sqrt (x t ^ 2 + y t ^ 2) =
      -vx 0 * H / μ - y 0 / Real.sqrt (x 0 ^ 2 + y 0 ^ 2) := by
    refine kepler_const_of_hasDerivAt_zero
      (f := fun t => -vx t * H / μ - y t / Real.sqrt (x t ^ 2 + y t ^ 2)) ?_
    intro t
    have hpos := kepler_normSq_pos (hne t)
    have hs : 0 < Real.sqrt (x t ^ 2 + y t ^ 2) := Real.sqrt_pos.mpr hpos
    have hs2 : Real.sqrt (x t ^ 2 + y t ^ 2) ^ 2 = x t ^ 2 + y t ^ 2 :=
      Real.sq_sqrt hpos.le
    have := ((((hvx t).neg).mul_const H).div_const μ).sub
      ((hy t).div (kepler_radius_hasDerivAt x y vx vy t (hne t) (hx t) (hy t)) hs.ne')
    convert this using 1
    rw [← hH t]
    field_simp
    linear_combination (vy t) * hs2
  refine ⟨H, vy 0 * H / μ - x 0 / Real.sqrt (x 0 ^ 2 + y 0 ^ 2),
    -vx 0 * H / μ - y 0 / Real.sqrt (x 0 ^ 2 + y 0 ^ 2), fun t => ⟨hH t, ?_⟩⟩
  rw [← hE1 t, ← hE2 t]
  have hpos := kepler_normSq_pos (hne t)
  have hs : 0 < Real.sqrt (x t ^ 2 + y t ^ 2) := Real.sqrt_pos.mpr hpos
  have hs2 : Real.sqrt (x t ^ 2 + y t ^ 2) ^ 2 = x t ^ 2 + y t ^ 2 :=
    Real.sq_sqrt hpos.le
  have hh := hH t
  field_simp
  linear_combination μ * hs2 + (Real.sqrt (x t ^ 2 + y t ^ 2) * H) * hh

/-- The vis-viva equation. For the same inverse-square motion, if at two moments `t₁`, `t₂`
the body is at two different distances `r_p ≠ r_a` and moving square to the radius there
(its lowest and highest points), then at every moment its speed obeys
`v² = μ (2 / r - 1 / a)` with long half-axis `a = (r_p + r_a) / 2`. Equivalently the
energy `v² / 2 - μ / r` is the constant `-μ / (2a)`. -/
theorem vis_viva
    (μ : ℝ) (hμ : 0 < μ) (x y vx vy : ℝ → ℝ)
    (hne : ∀ t, (x t, y t) ≠ (0, 0))
    (hx : ∀ t, HasDerivAt x (vx t) t) (hy : ∀ t, HasDerivAt y (vy t) t)
    (hvx : ∀ t, HasDerivAt vx (-μ * x t / Real.sqrt (x t ^ 2 + y t ^ 2) ^ 3) t)
    (hvy : ∀ t, HasDerivAt vy (-μ * y t / Real.sqrt (x t ^ 2 + y t ^ 2) ^ 3) t)
    (t₁ t₂ : ℝ)
    (hdist : Real.sqrt (x t₁ ^ 2 + y t₁ ^ 2) ≠ Real.sqrt (x t₂ ^ 2 + y t₂ ^ 2))
    (hturn₁ : x t₁ * vx t₁ + y t₁ * vy t₁ = 0)
    (hturn₂ : x t₂ * vx t₂ + y t₂ * vy t₂ = 0) :
    ∀ t, vx t ^ 2 + vy t ^ 2 =
      μ * (2 / Real.sqrt (x t ^ 2 + y t ^ 2) -
        1 / ((Real.sqrt (x t₁ ^ 2 + y t₁ ^ 2) + Real.sqrt (x t₂ ^ 2 + y t₂ ^ 2)) / 2)) := by
  intro t
  have hH : ∀ t, x t * vy t - y t * vx t = x 0 * vy 0 - y 0 * vx 0 := by
    refine kepler_const_of_hasDerivAt_zero (f := fun t => x t * vy t - y t * vx t) ?_
    intro t
    have := ((hx t).mul (hvy t)).sub ((hy t).mul (hvx t))
    convert this using 1
    ring
  have hEn : ∀ t, (vx t ^ 2 + vy t ^ 2) / 2 - μ / Real.sqrt (x t ^ 2 + y t ^ 2) =
      (vx 0 ^ 2 + vy 0 ^ 2) / 2 - μ / Real.sqrt (x 0 ^ 2 + y 0 ^ 2) := by
    refine kepler_const_of_hasDerivAt_zero
      (f := fun t => (vx t ^ 2 + vy t ^ 2) / 2 - μ / Real.sqrt (x t ^ 2 + y t ^ 2)) ?_
    intro t
    have hpos := kepler_normSq_pos (hne t)
    have hs : 0 < Real.sqrt (x t ^ 2 + y t ^ 2) := Real.sqrt_pos.mpr hpos
    have hs2 : Real.sqrt (x t ^ 2 + y t ^ 2) ^ 2 = x t ^ 2 + y t ^ 2 :=
      Real.sq_sqrt hpos.le
    have := ((((hvx t).pow 2).add ((hvy t).pow 2)).div_const 2).sub
      ((hasDerivAt_const t μ).div
        (kepler_radius_hasDerivAt x y vx vy t (hne t) (hx t) (hy t)) hs.ne')
    convert this using 1
    field_simp
    linear_combination 0 * hs2
  have hsq : ∀ s, Real.sqrt (x s ^ 2 + y s ^ 2) ^ 2 = x s ^ 2 + y s ^ 2 := fun s =>
    Real.sq_sqrt (kepler_normSq_pos (hne s)).le
  have hrpos : ∀ s, 0 < Real.sqrt (x s ^ 2 + y s ^ 2) := fun s =>
    Real.sqrt_pos.mpr (kepler_normSq_pos (hne s))
  refine kepler_vis_viva_algebra μ _ (x 0 * vy 0 - y 0 * vx 0) _ _ _ _ _ _ (hrpos t)
    (hrpos t₁) (hrpos t₂) hdist ?_ ?_ (hEn t₁) (hEn t₂) (hEn t)
  · rw [hsq, ← hH t₁]
    linear_combination (x t₁ * vx t₁ + y t₁ * vy t₁) * hturn₁
  · rw [hsq, ← hH t₂]
    linear_combination (x t₂ * vx t₂ + y t₂ * vy t₂) * hturn₂

/-- Kepler's third law, Step 5 of the card. An ellipse with long half-axis `a > 0` and
eccentricity `0 ≤ e < 1` has area `π a b` with short half-axis `b = a √(1 - e²)`; the body
sweeps area at the rate `h / 2` with `h = √(μ a (1 - e²))`. So the time for one lap,
area divided by rate, is `2π √(a³ / μ)`: the stretch `e` cancels. -/
theorem kepler_third_law_period (μ a e : ℝ) (hμ : 0 < μ) (ha : 0 < a)
    (he0 : 0 ≤ e) (he1 : e < 1) :
    Real.pi * a * (a * Real.sqrt (1 - e ^ 2)) / (Real.sqrt (μ * a * (1 - e ^ 2)) / 2) =
      2 * Real.pi * Real.sqrt (a ^ 3 / μ) := by
  have h1 : 0 < 1 - e ^ 2 := by nlinarith
  rw [Real.sqrt_mul (by positivity), Real.sqrt_mul hμ.le, Real.sqrt_div (by positivity),
    show a ^ 3 = a ^ 2 * a by ring, Real.sqrt_mul (by positivity), Real.sqrt_sq ha.le]
  have hs1 : 0 < Real.sqrt (1 - e ^ 2) := Real.sqrt_pos.mpr h1
  have hsμ : 0 < Real.sqrt μ := Real.sqrt_pos.mpr hμ
  have hsa : 0 < Real.sqrt a := Real.sqrt_pos.mpr ha
  have hsa2 : Real.sqrt a ^ 2 = a := Real.sq_sqrt ha.le
  field_simp
  linear_combination (-1:ℝ) * hsa2

#print axioms kepler_const_of_hasDerivAt_zero
#print axioms kepler_normSq_pos
#print axioms kepler_radius_hasDerivAt
#print axioms kepler_vis_viva_algebra
#print axioms inverse_square_orbit_is_conic_with_constant_h
#print axioms vis_viva
#print axioms kepler_third_law_period
