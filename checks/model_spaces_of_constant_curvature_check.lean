-- Sphere, plane and hyperbolic space: the length rule ds = 2R |dx| / (1 + k r^2) has curvature k / R^2 at every point, the polar charts sin, line and sinh give curvature +1/R^2, 0 and -1/R^2, and the disc's sliding map keeps the disc's length rule.
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Complex.Basic

open Complex

/-- Helper: the second derivative of `ln (2R / (1 + k (s² + c)))` in `s`. -/
theorem log_lam_second_deriv (R k c x : ℝ) (hR : 0 < R) (hx : 0 < 1 + k * (x ^ 2 + c)) :
    deriv (fun a => deriv (fun s => Real.log (2 * R / (1 + k * (s ^ 2 + c)))) a) x
      = (-2 * k * (1 + k * (x ^ 2 + c)) + 4 * k ^ 2 * x ^ 2) / (1 + k * (x ^ 2 + c)) ^ 2 := by
  have hopen : IsOpen {a : ℝ | 0 < 1 + k * (a ^ 2 + c)} :=
    isOpen_lt continuous_const (by fun_prop)
  have hev : (fun a => deriv (fun s => Real.log (2 * R / (1 + k * (s ^ 2 + c)))) a)
      =ᶠ[nhds x] fun a => -(2 * k) * a / (1 + k * (a ^ 2 + c)) := by
    filter_upwards [hopen.mem_nhds hx] with a ha
    have ha' : (1 + k * (a ^ 2 + c)) ≠ 0 := ne_of_gt ha
    have hD : HasDerivAt (fun s : ℝ => 1 + k * (s ^ 2 + c)) (k * (2 * a)) a := by
      have := ((hasDerivAt_pow 2 a).add_const c).const_mul k |>.const_add 1
      simpa using this
    have hL : HasDerivAt (fun s : ℝ => 2 * R / (1 + k * (s ^ 2 + c)))
        (-(2 * R) * (k * (2 * a)) / (1 + k * (a ^ 2 + c)) ^ 2) a := by
      have := (hasDerivAt_const a (2 * R)).div hD ha'
      convert this using 1; ring
    have hne : 2 * R / (1 + k * (a ^ 2 + c)) ≠ 0 := div_ne_zero (by positivity) ha'
    rw [(hL.log hne).deriv]
    field_simp
  rw [hev.deriv_eq]
  have hx' : (1 + k * (x ^ 2 + c)) ≠ 0 := ne_of_gt hx
  have hD : HasDerivAt (fun s : ℝ => 1 + k * (s ^ 2 + c)) (k * (2 * x)) x := by
    have := ((hasDerivAt_pow 2 x).add_const c).const_mul k |>.const_add 1
    simpa using this
  have hN : HasDerivAt (fun s : ℝ => -(2 * k) * s) (-(2 * k)) x := by
    simpa using ((hasDerivAt_id' x).const_mul (-(2 * k)))
  refine (hN.div hD hx').deriv.trans ?_
  field_simp
  ring

#print axioms log_lam_second_deriv

/-- Helper: `|1 - p̄ z|² - |z - p|² = (1 - |z|²)(1 - |p|²)`. -/
theorem disc_norm_identity (p z : ℂ) :
    ‖1 - (starRingEnd ℂ) p * z‖ ^ 2 - ‖z - p‖ ^ 2 = (1 - ‖z‖ ^ 2) * (1 - ‖p‖ ^ 2) := by
  simp only [Complex.sq_norm, Complex.normSq_apply]
  simp
  ring

#print axioms disc_norm_identity

/-- The one length rule `ds = λ |dx|` with `λ = 2R / (1 + k r²)`, where `r² = x² + y²`, has
Gaussian curvature `K = -(∂²/∂x² + ∂²/∂y²) ln λ / λ²` equal to `k / R²` at every point of the
chart (every point where `1 + k r² > 0`). With `k = +1, 0, -1` this is the sphere, the plane and
the Poincaré disc, of curvature `+1/R²`, `0` and `-1/R²`. -/
theorem curvature_of_length_rule_eq_k_div_R_sq (R k x y : ℝ) (hR : 0 < R)
    (hxy : 0 < 1 + k * (x ^ 2 + y ^ 2)) :
    let lam : ℝ → ℝ → ℝ := fun a b => 2 * R / (1 + k * (a ^ 2 + b ^ 2));
    -(deriv (fun a => deriv (fun s => Real.log (lam s y)) a) x
        + deriv (fun b => deriv (fun t => Real.log (lam x t)) b) y) / lam x y ^ 2
      = k / R ^ 2 := by
  intro lam
  have h1 := log_lam_second_deriv R k (y ^ 2) x hR hxy
  have h2 := log_lam_second_deriv R k (x ^ 2) y hR (by linarith [show x ^ 2 + y ^ 2 = y ^ 2 + x ^ 2 by ring])
  have e2 : (fun b => deriv (fun t => Real.log (lam x t)) b)
      = fun a => deriv (fun s => Real.log (2 * R / (1 + k * (s ^ 2 + x ^ 2)))) a := by
    funext b; congr 1; funext t; simp only [lam]; ring_nf
  simp only [lam] at e2 ⊢
  rw [e2, h1, h2]
  have hD : (1 + k * (x ^ 2 + y ^ 2)) ≠ 0 := ne_of_gt hxy
  have hD' : (1 + k * (y ^ 2 + x ^ 2)) = 1 + k * (x ^ 2 + y ^ 2) := by ring
  rw [hD']
  field_simp
  ring

/-- The same curvatures in polar coordinates `ds² = dρ² + f(ρ)² dθ²`, where `K = -f''(ρ)/f(ρ)`:
the sphere's rim function `f = R sin(ρ/R)` gives `+1/R²` (for `0 < ρ < πR`), the plane's `f = ρ`
gives `0`, and the hyperbolic plane's `f = R sinh(ρ/R)` gives `-1/R²` (for `0 < ρ`). -/
theorem polar_chart_curvature (R ρ : ℝ) (hR : 0 < R) (hρ : 0 < ρ) :
    (ρ < Real.pi * R →
      -deriv (deriv fun t => R * Real.sin (t / R)) ρ / (R * Real.sin (ρ / R)) = 1 / R ^ 2) ∧
    -deriv (deriv fun t : ℝ => t) ρ / ρ = 0 ∧
    -deriv (deriv fun t => R * Real.sinh (t / R)) ρ / (R * Real.sinh (ρ / R)) = -1 / R ^ 2 := by
  have hR' : R ≠ 0 := ne_of_gt hR
  refine ⟨fun hlt => ?_, ?_, ?_⟩
  · have e1 : deriv (fun t => R * Real.sin (t / R)) = fun t => Real.cos (t / R) := by
      funext t
      have := (((hasDerivAt_id' t).div_const R).sin).const_mul R
      rw [this.deriv]; field_simp
    have e2 : HasDerivAt (fun t => Real.cos (t / R)) (-Real.sin (ρ / R) * (1 / R)) ρ := by
      have := ((hasDerivAt_id' ρ).div_const R).cos
      simpa using this
    have hs : 0 < Real.sin (ρ / R) := by
      apply Real.sin_pos_of_pos_of_lt_pi (div_pos hρ hR)
      rw [div_lt_iff₀ hR]; exact hlt
    rw [e1, e2.deriv]
    field_simp
  · simp
  · have e1 : deriv (fun t => R * Real.sinh (t / R)) = fun t => Real.cosh (t / R) := by
      funext t
      have := (((hasDerivAt_id' t).div_const R).sinh).const_mul R
      rw [this.deriv]; field_simp
    have e2 : HasDerivAt (fun t => Real.cosh (t / R)) (Real.sinh (ρ / R) * (1 / R)) ρ := by
      have := ((hasDerivAt_id' ρ).div_const R).cosh
      simpa using this
    have hs : 0 < Real.sinh (ρ / R) := Real.sinh_pos_iff.mpr (div_pos hρ hR)
    rw [e1, e2.deriv]
    field_simp

/-- The sliding map `w(z) = (z - p) / (1 - p̄ z)` of the disc, for a disc point `p`, sends `p` to
the centre, keeps disc points in the disc, and keeps the disc's length rule:
`2 |w'(z)| / (1 - |w|²) = 2 / (1 - |z|²)`, so it keeps every true length. -/
theorem disc_slide_keeps_length_rule (p z : ℂ) (hp : ‖p‖ < 1) (hz : ‖z‖ < 1) :
    let w : ℂ → ℂ := fun u => (u - p) / (1 - (starRingEnd ℂ) p * u)
    w p = 0 ∧ ‖w z‖ < 1 ∧
      2 * ‖deriv w z‖ / (1 - ‖w z‖ ^ 2) = 2 / (1 - ‖z‖ ^ 2) := by
  intro w
  have hid := disc_norm_identity p z
  have hp0 := norm_nonneg p
  have hz0 := norm_nonneg z
  have hP : 0 < 1 - ‖p‖ ^ 2 := by nlinarith
  have hZ : 0 < 1 - ‖z‖ ^ 2 := by nlinarith
  have hg : (1 - (starRingEnd ℂ) p * z) ≠ 0 := by
    intro h
    have h1 : (starRingEnd ℂ) p * z = 1 := by linear_combination -h
    have h2 : ‖(starRingEnd ℂ) p * z‖ < 1 := by
      rw [norm_mul, Complex.norm_conj]
      nlinarith
    rw [h1, norm_one] at h2; exact lt_irrefl _ h2
  have hN : 0 < ‖1 - (starRingEnd ℂ) p * z‖ := norm_pos_iff.mpr hg
  have hwz : ‖w z‖ = ‖z - p‖ / ‖1 - (starRingEnd ℂ) p * z‖ := by
    simp only [w, norm_div]
  have hlt : ‖z - p‖ ^ 2 < ‖1 - (starRingEnd ℂ) p * z‖ ^ 2 := by nlinarith [mul_pos hZ hP]
  have hlt' : ‖z - p‖ < ‖1 - (starRingEnd ℂ) p * z‖ :=
    lt_of_pow_lt_pow_left₀ 2 (norm_nonneg _) hlt
  have hder : HasDerivAt w ((1 * (1 - (starRingEnd ℂ) p * z) - (z - p) * (-(starRingEnd ℂ) p))
      / (1 - (starRingEnd ℂ) p * z) ^ 2) z := by
    have hf : HasDerivAt (fun u : ℂ => u - p) 1 z := (hasDerivAt_id z).sub_const p
    have hg' : HasDerivAt (fun u : ℂ => 1 - (starRingEnd ℂ) p * u) (-(starRingEnd ℂ) p) z := by
      simpa using ((hasDerivAt_id z).const_mul ((starRingEnd ℂ) p)).const_sub 1
    exact hf.div hg' hg
  have hnum : (1 * (1 - (starRingEnd ℂ) p * z) - (z - p) * (-(starRingEnd ℂ) p))
      = ((1 - ‖p‖ ^ 2 : ℝ) : ℂ) := by
    have : (starRingEnd ℂ) p * p = ((‖p‖ ^ 2 : ℝ) : ℂ) := by
      rw [Complex.sq_norm, Complex.normSq_eq_conj_mul_self]
    push_cast at this ⊢
    linear_combination (-1 : ℂ) * this
  have hdn : ‖deriv w z‖ = (1 - ‖p‖ ^ 2) / ‖1 - (starRingEnd ℂ) p * z‖ ^ 2 := by
    rw [hder.deriv, hnum, norm_div, norm_pow, Complex.norm_real, Real.norm_eq_abs,
      abs_of_pos hP]
  refine ⟨by simp [w], ?_, ?_⟩
  · rw [hwz, div_lt_one hN]; exact hlt'
  · rw [hdn, hwz]
    have hden : 1 - (‖z - p‖ / ‖1 - (starRingEnd ℂ) p * z‖) ^ 2
        = (1 - ‖z‖ ^ 2) * (1 - ‖p‖ ^ 2) / ‖1 - (starRingEnd ℂ) p * z‖ ^ 2 := by
      have hN2 : ‖1 - (starRingEnd ℂ) p * z‖ ^ 2 ≠ 0 := by positivity
      rw [← hid, div_pow, sub_div, div_self hN2]
    rw [hden]
    field_simp

#print axioms curvature_of_length_rule_eq_k_div_R_sq
#print axioms polar_chart_curvature
#print axioms disc_slide_keeps_length_rule
