-- Osculating circle: at a point of a twice-differentiable plane curve with nonzero speed and nonzero curvature, exactly one circle matches the curve to second order, with radius 1/|κ| and centre 1/κ along the unit normal.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Real

/-- The speed of the plane curve t ↦ (x(t), y(t)) at t: the length √(x'^2 + y'^2) of its
velocity, in metres of path per unit of t. -/
noncomputable def speed (x y : ℝ → ℝ) (t : ℝ) : ℝ :=
  √(deriv x t ^ 2 + deriv y t ^ 2)

/-- The card's signed curvature at t: x' y'' − y' x'' divided by the speed cubed.
Positive means the curve turns left. -/
noncomputable def signedCurvature (x y : ℝ → ℝ) (t : ℝ) : ℝ :=
  (deriv x t * deriv (deriv y) t - deriv y t * deriv (deriv x) t) / speed x y t ^ 3

/-- The unit normal N at t: the unit tangent (x', y') / speed turned a quarter turn left,
that is (−y', x') / speed. -/
noncomputable def unitNormal (x y : ℝ → ℝ) (t : ℝ) : ℝ × ℝ :=
  (-deriv y t / speed x y t, deriv x t / speed x y t)

/-- The card's fit function for a trial circle with centre C and radius R, measured from the
point at parameter t: F(δ) = |r(t + δ) − C|^2 − R^2. It is zero exactly when r(t + δ) is on
the circle. -/
noncomputable def fit (x y : ℝ → ℝ) (t : ℝ) (C : ℝ × ℝ) (R : ℝ) : ℝ → ℝ :=
  fun δ => (x (t + δ) - C.1) ^ 2 + (y (t + δ) - C.2) ^ 2 - R ^ 2

/-- The speed squared is x'^2 + y'^2. -/
lemma speed_sq (x y : ℝ → ℝ) (t : ℝ) : speed x y t ^ 2 = deriv x t ^ 2 + deriv y t ^ 2 := by
  unfold speed
  rw [Real.sq_sqrt (by positivity)]

#print axioms speed_sq

/-- The first derivative of the fit function, at every δ:
F'(δ) = 2 (x(t + δ) − C₁) x'(t + δ) + 2 (y(t + δ) − C₂) y'(t + δ). -/
lemma deriv_fit {x y : ℝ → ℝ} (hx : Differentiable ℝ x) (hy : Differentiable ℝ y)
    (t : ℝ) (C : ℝ × ℝ) (R : ℝ) :
    deriv (fit x y t C R) = fun δ => 2 * (x (t + δ) - C.1) * deriv x (t + δ) +
      2 * (y (t + δ) - C.2) * deriv y (t + δ) := by
  funext δ
  have h1 : HasDerivAt (fun s => x (t + s)) (deriv x (t + δ)) δ :=
    (hx (t + δ)).hasDerivAt.comp_const_add t δ
  have h2 : HasDerivAt (fun s => y (t + s)) (deriv y (t + δ)) δ :=
    (hy (t + δ)).hasDerivAt.comp_const_add t δ
  have h : HasDerivAt (fit x y t C R) _ δ :=
    (((h1.sub_const C.1).pow 2).add ((h2.sub_const C.2).pow 2)).sub_const (R ^ 2)
  rw [h.deriv]
  push_cast
  ring

#print axioms deriv_fit

/-- The second derivative of the fit function at δ = 0:
F''(0) = 2 (x'^2 + (x − C₁) x'' + y'^2 + (y − C₂) y''). -/
lemma deriv2_fit {x y : ℝ → ℝ} (hx : Differentiable ℝ x) (hx2 : Differentiable ℝ (deriv x))
    (hy : Differentiable ℝ y) (hy2 : Differentiable ℝ (deriv y))
    (t : ℝ) (C : ℝ × ℝ) (R : ℝ) :
    deriv (deriv (fit x y t C R)) 0 =
      2 * (deriv x t ^ 2 + (x t - C.1) * deriv (deriv x) t +
        deriv y t ^ 2 + (y t - C.2) * deriv (deriv y) t) := by
  rw [deriv_fit hx hy]
  have h1 : HasDerivAt (fun s => x (t + s)) (deriv x (t + 0)) 0 :=
    (hx (t + 0)).hasDerivAt.comp_const_add t 0
  have h2 : HasDerivAt (fun s => y (t + s)) (deriv y (t + 0)) 0 :=
    (hy (t + 0)).hasDerivAt.comp_const_add t 0
  have g1 : HasDerivAt (fun s => deriv x (t + s)) (deriv (deriv x) (t + 0)) 0 :=
    (hx2 (t + 0)).hasDerivAt.comp_const_add t 0
  have g2 : HasDerivAt (fun s => deriv y (t + s)) (deriv (deriv y) (t + 0)) 0 :=
    (hy2 (t + 0)).hasDerivAt.comp_const_add t 0
  have h : HasDerivAt (fun δ => 2 * (x (t + δ) - C.1) * deriv x (t + δ) +
      2 * (y (t + δ) - C.2) * deriv y (t + δ)) _ 0 :=
    ((((h1.sub_const C.1).const_mul 2).mul g1).add (((h2.sub_const C.2).const_mul 2).mul g2))
  rw [h.deriv]
  simp only [add_zero]
  ring

#print axioms deriv2_fit

/-- The fit function at δ = 0. -/
lemma fit_zero (x y : ℝ → ℝ) (t : ℝ) (C : ℝ × ℝ) (R : ℝ) :
    fit x y t C R 0 = (x t - C.1) ^ 2 + (y t - C.2) ^ 2 - R ^ 2 := by
  simp [fit]

#print axioms fit_zero

/-- The fit function's first derivative at δ = 0. -/
lemma deriv_fit_zero {x y : ℝ → ℝ} (hx : Differentiable ℝ x) (hy : Differentiable ℝ y)
    (t : ℝ) (C : ℝ × ℝ) (R : ℝ) :
    deriv (fit x y t C R) 0 = 2 * ((x t - C.1) * deriv x t + (y t - C.2) * deriv y t) := by
  rw [deriv_fit hx hy]
  simp only [add_zero]
  ring

#print axioms deriv_fit_zero

/-- Helper with the same statement as `tangent_circles_centre_on_normal`, proved here so the
main theorem, which comes first, can use it. -/
lemma tangent_circles_aux {x y : ℝ → ℝ} {t : ℝ}
    (hx : Differentiable ℝ x) (hy : Differentiable ℝ y)
    (hv : speed x y t ≠ 0) (C : ℝ × ℝ) {R : ℝ} (hR : 0 ≤ R) :
    (fit x y t C R 0 = 0 ∧ deriv (fit x y t C R) 0 = 0) ↔
      ∃ l : ℝ, C = (x t, y t) + l • unitNormal x y t ∧ R = |l| := by
  have hv2 := speed_sq x y t
  rw [fit_zero, deriv_fit_zero hx hy]
  obtain ⟨C1, C2⟩ := C
  simp only [unitNormal, Prod.smul_mk, smul_eq_mul, Prod.mk_add_mk, Prod.mk.injEq]
  set a := deriv x t
  set b := deriv y t
  set v := speed x y t
  constructor
  · rintro ⟨h0, h1⟩
    refine ⟨((x t - C1) * b - (y t - C2) * a) / v, ⟨?_, ?_⟩, ?_⟩
    · field_simp
      linear_combination -(x t - C1) * hv2 + (-a / 2) * h1
    · field_simp
      linear_combination -(y t - C2) * hv2 + (-b / 2) * h1
    · have hsq : R ^ 2 = (((x t - C1) * b - (y t - C2) * a) / v) ^ 2 := by
        field_simp
        linear_combination R ^ 2 * hv2 - (a ^ 2 + b ^ 2) * h0 +
          (((x t - C1) * a + (y t - C2) * b) / 2) * h1
      have := (sq_eq_sq_iff_abs_eq_abs _ _).1 hsq
      rwa [abs_of_nonneg hR] at this
  · rintro ⟨l, ⟨hC1, hC2⟩, hRl⟩
    subst hC1 hC2 hRl
    constructor
    · rw [sq_abs]
      field_simp
      linear_combination -(l ^ 2) * hv2
    · field_simp
      ring

#print axioms tangent_circles_aux

/-- Helper with the same statement as `fit_second_deriv_tangent_circle`, proved here so the
main theorem, which comes first, can use it. -/
lemma second_deriv_aux {x y : ℝ → ℝ} {t : ℝ}
    (hx : Differentiable ℝ x) (hx2 : Differentiable ℝ (deriv x))
    (hy : Differentiable ℝ y) (hy2 : Differentiable ℝ (deriv y))
    (hv : speed x y t ≠ 0) (l : ℝ) :
    deriv (deriv (fit x y t ((x t, y t) + l • unitNormal x y t) |l|)) 0 =
      2 * speed x y t ^ 2 * (1 - l * signedCurvature x y t) := by
  have hv2 := speed_sq x y t
  rw [deriv2_fit hx hx2 hy hy2]
  simp only [unitNormal, signedCurvature, Prod.smul_mk, smul_eq_mul, Prod.fst_add,
    Prod.snd_add]
  field_simp
  linear_combination -(speed x y t) * hv2

#print axioms second_deriv_aux

/-- **The osculating circle exists and is unique.** Let r(t) = (x(t), y(t)) be a plane curve
whose coordinates have two derivatives, at a point where the speed is not zero and the signed
curvature κ is not zero. A circle with centre C and radius R ≥ 0 matches the curve's position,
direction and bending there (F(0) = 0, F'(0) = 0 and F''(0) = 0 for the fit function F) if
and only if its centre is C = r + (1/κ) N and its radius is R = 1/|κ|. -/
theorem osculating_circle_unique {x y : ℝ → ℝ} {t : ℝ}
    (hx : Differentiable ℝ x) (hx2 : Differentiable ℝ (deriv x))
    (hy : Differentiable ℝ y) (hy2 : Differentiable ℝ (deriv y))
    (hv : speed x y t ≠ 0) (hk : signedCurvature x y t ≠ 0)
    (C : ℝ × ℝ) {R : ℝ} (hR : 0 ≤ R) :
    (fit x y t C R 0 = 0 ∧ deriv (fit x y t C R) 0 = 0 ∧
        deriv (deriv (fit x y t C R)) 0 = 0) ↔
      (C = (x t, y t) + (1 / signedCurvature x y t) • unitNormal x y t ∧
        R = 1 / |signedCurvature x y t|) := by
  have key := tangent_circles_aux hx hy hv C hR
  constructor
  · rintro ⟨h0, h1, h2⟩
    obtain ⟨l, hC, hRl⟩ := key.1 ⟨h0, h1⟩
    subst hC hRl
    rw [second_deriv_aux hx hx2 hy hy2 hv l] at h2
    have hv2 : speed x y t ^ 2 ≠ 0 := pow_ne_zero 2 hv
    have hlk : l * signedCurvature x y t = 1 := by
      have : 2 * speed x y t ^ 2 ≠ 0 := mul_ne_zero two_ne_zero hv2
      have h3 := (mul_eq_zero.1 h2).resolve_left this
      linarith
    have hl : l = 1 / signedCurvature x y t := eq_one_div_of_mul_eq_one_left hlk
    subst hl
    exact ⟨rfl, by rw [abs_div, abs_one]⟩
  · rintro ⟨hC, hRe⟩
    have hR' : R = |1 / signedCurvature x y t| := by rw [hRe, abs_div, abs_one]
    obtain ⟨h0, h1⟩ := key.2 ⟨1 / signedCurvature x y t, hC, hR'⟩
    refine ⟨h0, h1, ?_⟩
    subst hC hR'
    rw [second_deriv_aux hx hx2 hy hy2 hv]
    field_simp
    ring

/-- **Position and direction put the centre on the normal.** At a point where the speed is not
zero, a circle with centre C and radius R ≥ 0 passes through the point and is tangent to the
curve there (F(0) = 0 and F'(0) = 0) if and only if C = r + λ N for some number λ and
R = |λ|: a whole family of tangent circles, one for each λ. -/
theorem tangent_circles_centre_on_normal {x y : ℝ → ℝ} {t : ℝ}
    (hx : Differentiable ℝ x) (hy : Differentiable ℝ y)
    (hv : speed x y t ≠ 0) (C : ℝ × ℝ) {R : ℝ} (hR : 0 ≤ R) :
    (fit x y t C R 0 = 0 ∧ deriv (fit x y t C R) 0 = 0) ↔
      ∃ l : ℝ, C = (x t, y t) + l • unitNormal x y t ∧ R = |l| := by
  exact tangent_circles_aux hx hy hv C hR

/-- **Every other tangent circle misses at second order.** For the tangent circle with centre
r + λ N and radius |λ|, the second derivative of the fit function at 0 is
F''(0) = 2 v^2 (1 − λ κ), where v is the speed. So it is zero only for λ = 1/κ; any other
tangent circle keeps a δ^2 term in its gap. -/
theorem fit_second_deriv_tangent_circle {x y : ℝ → ℝ} {t : ℝ}
    (hx : Differentiable ℝ x) (hx2 : Differentiable ℝ (deriv x))
    (hy : Differentiable ℝ y) (hy2 : Differentiable ℝ (deriv y))
    (hv : speed x y t ≠ 0) (l : ℝ) :
    deriv (deriv (fit x y t ((x t, y t) + l • unitNormal x y t) |l|)) 0 =
      2 * speed x y t ^ 2 * (1 - l * signedCurvature x y t) := by
  exact second_deriv_aux hx hx2 hy hy2 hv l

-- The bus path r(t) = (20 t^2, 20 (1 − t)^2) m: velocity (40 t, −40 (1 − t)), acceleration (40, 40).
-- The centre is r + (v^2 / (x'y'' − y'x'')) (−y', x'), and the radius squared is (v^2)^3 / (x'y'' − y'x'')^2.
-- Apex t = 1/2: point (5, 5), velocity (20, −20); cross term 1600, speed squared 800.
example : (20 : ℚ) * 40 - (-20) * 40 = 1600 ∧ (20 : ℚ) ^ 2 + (-20) ^ 2 = 800 := by norm_num
-- Apex: centre (15, 15), and radius squared 200, so the radius is √200 = 14.14 m.
example : (5 : ℚ) + 800 / 1600 * 20 = 15 ∧ (5 : ℚ) + 800 / 1600 * 20 = 15 := by norm_num
example : (800 : ℚ) ^ 3 / 1600 ^ 2 = 200 := by norm_num
-- Quarter t = 1/4: point (5/4, 45/4) = (1.25, 11.25), velocity (10, −30); cross term 1600,
-- speed squared 1000, centre (20, 35/2) = (20.00, 17.50).
example : (20 : ℚ) * (1 / 4) ^ 2 = 5 / 4 ∧ (20 : ℚ) * (3 / 4) ^ 2 = 45 / 4 := by norm_num
example : (10 : ℚ) * 40 - (-30) * 40 = 1600 ∧ (10 : ℚ) ^ 2 + (-30) ^ 2 = 1000 := by norm_num
example : (5 / 4 : ℚ) + 1000 / 1600 * 30 = 20 ∧ (45 / 4 : ℚ) + 1000 / 1600 * 10 = 35 / 2 := by
  norm_num
-- Entry t = 0: point (0, 20), velocity (0, −40); cross term 1600, speed squared 1600,
-- centre (40, 20) and radius squared 1600, so the radius is 40 m.
example : (0 : ℚ) * 40 - (-40) * 40 = 1600 ∧ (0 : ℚ) ^ 2 + (-40) ^ 2 = 1600 := by norm_num
example : (0 : ℚ) + 1600 / 1600 * 40 = 40 ∧ (20 : ℚ) + 1600 / 1600 * 0 = 20 := by norm_num
example : (1600 : ℚ) ^ 3 / 1600 ^ 2 = 40 ^ 2 := by norm_num

#print axioms osculating_circle_unique
#print axioms tangent_circles_centre_on_normal
#print axioms fit_second_deriv_tangent_circle
