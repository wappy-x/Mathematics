-- Ricci flow: on a surface, Ricci flow makes the log of the stretch factor and the curvature obey heat equations, and the dumbbell's neck has curvature −(1 − ρ²/(2R²))/ρ², so its 3D rate is −ρ²/R² < 0.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.FDeriv.Symmetric

open Real
open scoped ContDiff

/-- The flat Laplacian `∂²f/∂x² + ∂²f/∂y²` of a function of two variables, at `(x, y)`. -/
noncomputable def flatLaplacian (f : ℝ → ℝ → ℝ) (x y : ℝ) : ℝ :=
  deriv (fun a => deriv (fun b => f b y) a) x + deriv (fun a => deriv (fun b => f x b) a) y

/-- The Laplace-Beltrami operator of the metric `g = e^(2u) (dx² + dy²)`:
`Δ_g f = e^(-2u) (∂²f/∂x² + ∂²f/∂y²)`. -/
noncomputable def conformalLaplacian (u f : ℝ → ℝ → ℝ) (x y : ℝ) : ℝ :=
  exp (-2 * u x y) * flatLaplacian f x y

/-- The Gaussian curvature of the metric `g = e^(2u) (dx² + dy²)` in a flat chart:
`K = -e^(-2u) (∂²u/∂x² + ∂²u/∂y²)`. -/
noncomputable def conformalCurvature (u : ℝ → ℝ → ℝ) (x y : ℝ) : ℝ :=
  -exp (-2 * u x y) * flatLaplacian u x y

lemma ricci_fderiv_apply_comm (G : ℝ × ℝ × ℝ → ℝ) (hG : ContDiff ℝ ∞ G)
    (a b p : ℝ × ℝ × ℝ) :
    fderiv ℝ (fun q => fderiv ℝ G q b) p a = fderiv ℝ (fun q => fderiv ℝ G q a) p b := by
  have h1 : ContDiff ℝ ∞ (fderiv ℝ G) := hG.fderiv_right (by simp)
  have hd : Differentiable ℝ (fderiv ℝ G) := h1.differentiable (by simp)
  have e : ∀ c d : ℝ × ℝ × ℝ,
      fderiv ℝ (fun q => fderiv ℝ G q c) p d = fderiv ℝ (fderiv ℝ G) p d c := by
    intro c d
    rw [((hd p).hasFDerivAt.clm_apply (hasFDerivAt_const c p)).fderiv]
    simp
  rw [e, e]
  exact (hG.contDiffAt.isSymmSndFDerivAt (by simp)).eq a b

lemma ricci_dir_smooth (G : ℝ × ℝ × ℝ → ℝ) (hG : ContDiff ℝ ∞ G) (v : ℝ × ℝ × ℝ) :
    ContDiff ℝ ∞ (fun q => fderiv ℝ G q v) :=
  (hG.fderiv_right (by simp)).clm_apply contDiff_const

lemma ricci_pd1 (G : ℝ × ℝ × ℝ → ℝ) (hG : ContDiff ℝ ∞ G) (t x y : ℝ) :
    HasDerivAt (fun s => G (s, x, y)) (fderiv ℝ G (t, x, y) (1, 0, 0)) t := by
  have h : HasDerivAt (fun s : ℝ => ((s, x, y) : ℝ × ℝ × ℝ)) (1, 0, 0) t :=
    (hasDerivAt_id t).prodMk ((hasDerivAt_const t x).prodMk (hasDerivAt_const t y))
  exact ((hG.differentiable (by simp)) _).hasFDerivAt.comp_hasDerivAt t h

lemma ricci_pd2 (G : ℝ × ℝ × ℝ → ℝ) (hG : ContDiff ℝ ∞ G) (t x y : ℝ) :
    deriv (fun b => G (t, b, y)) x = fderiv ℝ G (t, x, y) (0, 1, 0) := by
  have h : HasDerivAt (fun s : ℝ => ((t, s, y) : ℝ × ℝ × ℝ)) (0, 1, 0) x :=
    (hasDerivAt_const x t).prodMk ((hasDerivAt_id x).prodMk (hasDerivAt_const x y))
  exact (((hG.differentiable (by simp)) _).hasFDerivAt.comp_hasDerivAt x h).deriv

lemma ricci_pd3 (G : ℝ × ℝ × ℝ → ℝ) (hG : ContDiff ℝ ∞ G) (t x y : ℝ) :
    deriv (fun b => G (t, x, b)) y = fderiv ℝ G (t, x, y) (0, 0, 1) := by
  have h : HasDerivAt (fun s : ℝ => ((t, x, s) : ℝ × ℝ × ℝ)) (0, 0, 1) y :=
    (hasDerivAt_const y t).prodMk ((hasDerivAt_const y x).prodMk (hasDerivAt_id y))
  exact (((hG.differentiable (by simp)) _).hasFDerivAt.comp_hasDerivAt y h).deriv

lemma ricci_lap (G : ℝ × ℝ × ℝ → ℝ) (hG : ContDiff ℝ ∞ G) (t x y : ℝ) :
    flatLaplacian (fun a b => G (t, a, b)) x y =
      fderiv ℝ (fun q => fderiv ℝ G q (0, 1, 0)) (t, x, y) (0, 1, 0) +
      fderiv ℝ (fun q => fderiv ℝ G q (0, 0, 1)) (t, x, y) (0, 0, 1) := by
  unfold flatLaplacian
  simp only [ricci_pd2 G hG t, ricci_pd3 G hG t x]
  rw [ricci_pd2 _ (ricci_dir_smooth G hG _), ricci_pd3 _ (ricci_dir_smooth G hG _)]

lemma ricci_lap_neg (f : ℝ → ℝ → ℝ) (x y : ℝ) :
    flatLaplacian (fun a b => -f a b) x y = -flatLaplacian f x y := by
  simp [flatLaplacian]
  ring


lemma ricci_sech_hasDerivAt (R c x : ℝ) :
    HasDerivAt (fun x => R / cosh (x + c)) (-R * sinh (x + c) / cosh (x + c) ^ 2) x := by
  have h := ((hasDerivAt_id' x).add_const c).cosh
  convert (hasDerivAt_const x R).fun_div h (cosh_pos _).ne' using 1
  ring

lemma ricci_sech'_hasDerivAt (R c x : ℝ) :
    HasDerivAt (fun x => -R * sinh (x + c) / cosh (x + c) ^ 2)
      (R * (2 * sinh (x + c) ^ 2 - cosh (x + c) ^ 2) / cosh (x + c) ^ 3) x := by
  have hs := ((hasDerivAt_id' x).add_const c).sinh
  have hc := (((hasDerivAt_id' x).add_const c).cosh).fun_pow 2
  convert (hs.const_mul (-R)).fun_div hc (pow_pos (cosh_pos _) 2).ne' using 1
  have := (cosh_pos (x + c)).ne'
  field_simp
  ring

lemma ricci_dumbbell_aux (R D : ℝ) (hR : 0 < R) (θ : ℝ) :
    conformalCurvature (fun x _ => log (R / cosh (x - D) + R / cosh (x + D))) 0 θ =
      -(1 - (R / cosh (0 - D) + R / cosh (0 + D)) ^ 2 / (2 * R ^ 2)) /
        (R / cosh (0 - D) + R / cosh (0 + D)) ^ 2 := by
  simp only [sub_eq_add_neg]
  set ρ : ℝ → ℝ := fun x => R / cosh (x + -D) + R / cosh (x + D) with hρdef
  set ρ' : ℝ → ℝ := fun x => -R * sinh (x + -D) / cosh (x + -D) ^ 2 +
    -R * sinh (x + D) / cosh (x + D) ^ 2 with hρ'def
  have hpos : ∀ x, 0 < ρ x := fun x => by
    simp only [hρdef]; have := cosh_pos (x + -D); have := cosh_pos (x + D); positivity
  have hρ : ∀ x, HasDerivAt ρ (ρ' x) x := fun x =>
    (ricci_sech_hasDerivAt R (-D) x).add (ricci_sech_hasDerivAt R D x)
  have hρ' : HasDerivAt ρ' (R * (2 * sinh (0 + -D) ^ 2 - cosh (0 + -D) ^ 2) / cosh (0 + -D) ^ 3 +
      R * (2 * sinh (0 + D) ^ 2 - cosh (0 + D) ^ 2) / cosh (0 + D) ^ 3) 0 :=
    (ricci_sech'_hasDerivAt R (-D) 0).add (ricci_sech'_hasDerivAt R D 0)
  have hlogd : deriv (fun b => log (ρ b)) = fun a => ρ' a / ρ a :=
    funext fun a => ((hρ a).log (hpos a).ne').deriv
  have hsecond := (hρ'.fun_div (hρ 0) (hpos 0).ne').deriv
  have hlap : flatLaplacian (fun x _ => log (ρ x)) 0 θ =
      deriv (fun a => ρ' a / ρ a) 0 := by
    unfold flatLaplacian
    simp only [deriv_const]
    rw [show (fun a => deriv (fun b => log (ρ b)) a) = deriv (fun b => log (ρ b)) from rfl,
      hlogd]
    ring
  show -exp (-2 * log (ρ 0)) * flatLaplacian (fun x _ => log (ρ x)) 0 θ = _
  rw [hlap, hsecond]
  have hexp : exp (-2 * log (ρ 0)) = (ρ 0 ^ 2)⁻¹ := by
    rw [show -2 * log (ρ 0) = log ((ρ 0 ^ 2)⁻¹) by rw [log_inv, log_pow]; push_cast; ring,
      exp_log (by have := hpos 0; positivity)]
  rw [hexp]
  simp only [hρdef, hρ'def, zero_add, cosh_neg, sinh_neg]
  have hc := cosh_pos D
  have hs := sinh_sq D
  field_simp
  rw [hs]
  ring

#print axioms ricci_fderiv_apply_comm
#print axioms ricci_dir_smooth
#print axioms ricci_pd1
#print axioms ricci_pd2
#print axioms ricci_pd3
#print axioms ricci_lap
#print axioms ricci_lap_neg
#print axioms ricci_sech_hasDerivAt
#print axioms ricci_sech'_hasDerivAt
#print axioms ricci_dumbbell_aux

/-- On a surface, Ricci flow is a heat equation. Write a smooth family of metrics in a flat
chart as `g(t) = e^(2u(t)) (dx² + dy²)`. On a surface `Ric = K g`, so Ricci flow
`∂g/∂t = -2 Ric` says `∂(e^(2u))/∂t = -2 K e^(2u)`. Then the log of the stretch factor obeys the
heat equation of its own metric, `∂u/∂t = Δ_g u`, and the curvature obeys
`∂K/∂t = Δ_g K + 2K²`: the Laplacian spreads curvature out, and `2K²` feeds positive curvature. -/
theorem ricci_flow_surface_heat_equations (u : ℝ → ℝ → ℝ → ℝ)
    (hsmooth : ContDiff ℝ ∞ (fun p : ℝ × ℝ × ℝ => u p.1 p.2.1 p.2.2))
    (hflow : ∀ t x y, deriv (fun s => exp (2 * u s x y)) t =
      -2 * conformalCurvature (u t) x y * exp (2 * u t x y)) :
    (∀ t x y, deriv (fun s => u s x y) t = conformalLaplacian (u t) (u t) x y) ∧
    (∀ t x y, deriv (fun s => conformalCurvature (u s) x y) t =
      conformalLaplacian (u t) (fun a b => conformalCurvature (u t) a b) x y +
        2 * conformalCurvature (u t) x y ^ 2) := by
  set F : ℝ × ℝ × ℝ → ℝ := fun p => u p.1 p.2.1 p.2.2 with hF
  set D1 : ℝ × ℝ × ℝ → ℝ := fun q => fderiv ℝ F q (1, 0, 0) with hD1def
  set A0 : ℝ × ℝ × ℝ → ℝ := fun q => fderiv ℝ F q (0, 1, 0) with hA0def
  set B0 : ℝ × ℝ × ℝ → ℝ := fun q => fderiv ℝ F q (0, 0, 1) with hB0def
  set A : ℝ × ℝ × ℝ → ℝ := fun q => fderiv ℝ A0 q (0, 1, 0) with hAdef
  set B : ℝ × ℝ × ℝ → ℝ := fun q => fderiv ℝ B0 q (0, 0, 1) with hBdef
  have hA0 : ContDiff ℝ ∞ A0 := ricci_dir_smooth F hsmooth _
  have hB0 : ContDiff ℝ ∞ B0 := ricci_dir_smooth F hsmooth _
  have hA : ContDiff ℝ ∞ A := ricci_dir_smooth A0 hA0 _
  have hB : ContDiff ℝ ∞ B := ricci_dir_smooth B0 hB0 _
  have hD1s : ContDiff ℝ ∞ D1 := ricci_dir_smooth F hsmooth _
  have hL : ContDiff ℝ ∞ (fun q => A q + B q) := hA.add hB
  have hlapu : ∀ s x y, flatLaplacian (u s) x y = A (s, x, y) + B (s, x, y) :=
    fun s x y => ricci_lap F hsmooth s x y
  have hut : ∀ t x y, HasDerivAt (fun s => u s x y) (D1 (t, x, y)) t :=
    fun t x y => ricci_pd1 F hsmooth t x y
  have hD1 : ∀ t x y, D1 (t, x, y) = -conformalCurvature (u t) x y := by
    intro t x y
    have h := hflow t x y
    rw [(((hut t x y).const_mul 2).exp).deriv] at h
    have h2 : exp (2 * u t x y) * (2 * D1 (t, x, y)) =
        exp (2 * u t x y) * (-2 * conformalCurvature (u t) x y) := by rw [h]; ring
    have := mul_left_cancel₀ (exp_pos _).ne' h2
    linarith
  refine ⟨fun t x y => ?_, fun t x y => ?_⟩
  · rw [(hut t x y).deriv, hD1]
    unfold conformalCurvature conformalLaplacian
    ring
  · have hK : (fun s => conformalCurvature (u s) x y) =
        fun s => -exp (-2 * u s x y) * (A (s, x, y) + B (s, x, y)) := by
      funext s
      rw [conformalCurvature, hlapu]
    have hder := ((((hut t x y).const_mul (-2)).exp).fun_neg).fun_mul
      (ricci_pd1 (fun q => A q + B q) hL t x y)
    rw [hK, hder.deriv]
    rw [fderiv_fun_add (hA.differentiable (by simp) _) (hB.differentiable (by simp) _)]
    have hcA : fderiv ℝ A (t, x, y) (1, 0, 0) =
        fderiv ℝ (fun q => fderiv ℝ D1 q (0, 1, 0)) (t, x, y) (0, 1, 0) := by
      rw [hAdef, ricci_fderiv_apply_comm A0 hA0]
      have hfun : (fun q => fderiv ℝ A0 q (1, 0, 0)) = fun q => fderiv ℝ D1 q (0, 1, 0) :=
        funext fun q => ricci_fderiv_apply_comm F hsmooth _ _ q
      rw [hfun]
    have hcB : fderiv ℝ B (t, x, y) (1, 0, 0) =
        fderiv ℝ (fun q => fderiv ℝ D1 q (0, 0, 1)) (t, x, y) (0, 0, 1) := by
      rw [hBdef, ricci_fderiv_apply_comm B0 hB0]
      have hfun : (fun q => fderiv ℝ B0 q (1, 0, 0)) = fun q => fderiv ℝ D1 q (0, 0, 1) :=
        funext fun q => ricci_fderiv_apply_comm F hsmooth _ _ q
      rw [hfun]
    have hLD : fderiv ℝ (fun q => fderiv ℝ D1 q (0, 1, 0)) (t, x, y) (0, 1, 0) +
        fderiv ℝ (fun q => fderiv ℝ D1 q (0, 0, 1)) (t, x, y) (0, 0, 1) =
        -flatLaplacian (fun a b => conformalCurvature (u t) a b) x y := by
      rw [← ricci_lap D1 hD1s t x y, ← ricci_lap_neg]
      congr 1
      funext a b
      exact hD1 t a b
    have hKv : conformalCurvature (u t) x y =
        -exp (-2 * u t x y) * (A (t, x, y) + B (t, x, y)) := by
      rw [conformalCurvature, hlapu]
    simp only [add_apply, hcA, hcB]
    rw [hD1, conformalLaplacian]
    linear_combination (-exp (-2 * u t x y)) * hLD + (-2 * conformalCurvature (u t) x y) * hKv

/-- The dumbbell's neck curvature. Two balls of radius `R > 0`, set `D` apart in the cylinder
chart, give a skin whose circle radius at cylinder coordinate `x` is
`ρ(x) = R / cosh(x - D) + R / cosh(x + D)`, with metric `ρ(x)² (dx² + dθ²)`. At the neck
`x = 0` its Gaussian curvature is `K = -(1 - ρ₀² / (2R²)) / ρ₀²`, where `ρ₀ = ρ(0)`. -/
theorem dumbbell_neck_curvature (R D : ℝ) (hR : 0 < R) (θ : ℝ) :
    let ρ : ℝ → ℝ := fun x => R / cosh (x - D) + R / cosh (x + D)
    conformalCurvature (fun x _ => log (ρ x)) 0 θ = -(1 - ρ 0 ^ 2 / (2 * R ^ 2)) / ρ 0 ^ 2 := by
  intro ρ
  exact ricci_dumbbell_aux R D hR θ

/-- The dumbbell's neck under Ricci flow, on the surface and in three dimensions. On the
surface the neck circle's squared radius changes at `-2ρ₀²K = 2 - ρ₀²/R²`. In three
dimensions the neck sphere's own curvature `1/ρ₀²` adds `-2`, so the rate is exactly
`-ρ₀²/R²`, which is negative: every neck in this family shrinks in three dimensions. -/
theorem dumbbell_neck_rates (R D : ℝ) (hR : 0 < R) (θ : ℝ) :
    let ρ : ℝ → ℝ := fun x => R / cosh (x - D) + R / cosh (x + D)
    let K := conformalCurvature (fun x _ => log (ρ x)) 0 θ;
    -2 * ρ 0 ^ 2 * K = 2 - ρ 0 ^ 2 / R ^ 2 ∧
    -2 * ρ 0 ^ 2 * (K + 1 / ρ 0 ^ 2) = -(ρ 0 ^ 2 / R ^ 2) ∧
    -2 * ρ 0 ^ 2 * (K + 1 / ρ 0 ^ 2) < 0 := by
  intro ρ K
  have hK : K = -(1 - ρ 0 ^ 2 / (2 * R ^ 2)) / ρ 0 ^ 2 := dumbbell_neck_curvature R D hR θ
  have hρ0 : 0 < ρ 0 := by
    have := cosh_pos (0 - D); have := cosh_pos (0 + D)
    show 0 < R / cosh (0 - D) + R / cosh (0 + D)
    positivity
  have h2 : -2 * ρ 0 ^ 2 * (K + 1 / ρ 0 ^ 2) = -(ρ 0 ^ 2 / R ^ 2) := by
    rw [hK]; field_simp; ring
  refine ⟨?_, h2, ?_⟩
  · rw [hK]; field_simp
  · rw [h2]
    have : 0 < ρ 0 ^ 2 / R ^ 2 := by positivity
    linarith

-- An octahedron counts V - E + F = 6 - 12 + 8 = 2, so a sphere-shaped skin has χ = 2.
example : (6 : ℤ) - 12 + 8 = 2 := by norm_num
-- Area lost per unit time is 2 × 2πχ = 4πχ = 8π: the coefficient is 2 × 2 × 2 = 8.
example : (2 : ℕ) * (2 * 2) = 8 := by norm_num
-- A round ball of radius 2 cm on the surface: R² - 2t at t = 1 is 4 - 2 = 2 cm².
example : (2 : ℚ) ^ 2 - 2 * 1 = 2 := by norm_num
-- Flip the sign: R² + 2t at t = 1 is 6, so the ball grows to radius √6.
example : (2 : ℚ) ^ 2 + 2 * 1 = 6 := by norm_num
-- A round 3-sphere of radius 2 cm: R² falls at 4, so it vanishes at t = 4/4 = 1 cm².
example : (2 : ℚ) ^ 2 / 4 = 1 := by norm_num
-- A thin 3D neck of radius 1/2 cm: ρ² falls at 2, so it pinches at t = (1/2)²/2 = 1/8 cm².
example : ((1 : ℚ) / 2) ^ 2 / 2 = 1 / 8 := by norm_num
-- The dumbbell's 3D neck at its start rate ρ²/R² takes ρ² / (ρ²/R²) = R² = 4 cm² of flow time.
example (r : ℚ) (hr : r ≠ 0) : r / (r / 2 ^ 2) = 4 := by field_simp; norm_num

#print axioms ricci_flow_surface_heat_equations
#print axioms dumbbell_neck_curvature
#print axioms dumbbell_neck_rates
