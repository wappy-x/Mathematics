-- Surface area: the area of a patch, the sum over the grid of √(EG − F²), equals the cross-product area and is the same in every one-to-one smooth chart, and the card's roof numbers check exactly.
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Topology.Algebra.Module.FiniteDimension

/-! A grid point is a pair `p = (u, v) : ℝ × ℝ`, and a chart's region `D` is a set of pairs.
A point of space is a list of three real numbers, `Fin 3 → ℝ` (east, north, up). A chart is
a map `r : ℝ × ℝ → Fin 3 → ℝ`. Its tangent arrows at `p` are `r_u = fderiv ℝ r p (1, 0)` and
`r_v = fderiv ℝ r p (0, 1)`. Mathlib's `a ⬝ᵥ b` is the dot product and `a ⨯₃ b` the cross
product. The measuring rule is `E = r_u ⬝ᵥ r_u`, `F = r_u ⬝ᵥ r_v`, `G = r_v ⬝ᵥ r_v`. Integrals
over the grid are Lebesgue integrals for area on the plane. A chart change is a map `φ` from a
new region `D'` onto `D`; `(fderiv ℝ φ p).det` is its Jacobian determinant. -/

open MeasureTheory Set Matrix

/-- `E = r_u · r_u`, the squared length of the `u` arrow. -/
noncomputable def firstFormE (r : ℝ × ℝ → Fin 3 → ℝ) (p : ℝ × ℝ) : ℝ :=
  fderiv ℝ r p (1, 0) ⬝ᵥ fderiv ℝ r p (1, 0)

/-- `F = r_u · r_v`, the dot product of the two arrows. -/
noncomputable def firstFormF (r : ℝ × ℝ → Fin 3 → ℝ) (p : ℝ × ℝ) : ℝ :=
  fderiv ℝ r p (1, 0) ⬝ᵥ fderiv ℝ r p (0, 1)

/-- `G = r_v · r_v`, the squared length of the `v` arrow. -/
noncomputable def firstFormG (r : ℝ × ℝ → Fin 3 → ℝ) (p : ℝ × ℝ) : ℝ :=
  fderiv ℝ r p (0, 1) ⬝ᵥ fderiv ℝ r p (0, 1)

/-- Area = ∬_D √(EG − F²) du dv: the area built from the measuring rule alone. -/
noncomputable def areaFromFirstForm (r : ℝ × ℝ → Fin 3 → ℝ) (D : Set (ℝ × ℝ)) : ℝ :=
  ∫ p in D, √(firstFormE r p * firstFormG r p - firstFormF r p ^ 2)


/-- Determinant of a linear map of the plane, read off from where it sends the two unit arrows. -/
theorem det_plane_clm (L : ℝ × ℝ →L[ℝ] ℝ × ℝ) :
    L.det = (L (1, 0)).1 * (L (0, 1)).2 - (L (0, 1)).1 * (L (1, 0)).2 := by
  have hx : ∀ x : ℝ × ℝ, x = x.1 • ((1 : ℝ), (0 : ℝ)) + x.2 • ((0 : ℝ), (1 : ℝ)) := by
    intro x; ext <;> simp
  have hL : L = (Matrix.toLin (Module.Basis.finTwoProd ℝ) (Module.Basis.finTwoProd ℝ)
      !![(L (1, 0)).1, (L (0, 1)).1; (L (1, 0)).2, (L (0, 1)).2]).toContinuousLinearMap := by
    refine ContinuousLinearMap.ext fun x => ?_
    conv_lhs => rw [hx x]
    rw [map_add, map_smul, map_smul]
    simp only [LinearMap.coe_toContinuousLinearMap', Matrix.toLin_finTwoProd_apply]
    ext <;> simp <;> ring
  conv_lhs => rw [hL]
  simp only [LinearMap.det_toContinuousLinearMap, LinearMap.det_toLin, Matrix.det_fin_two_of]

#print axioms det_plane_clm

/-- A linear map from the plane is fixed by the images of the two unit arrows. -/
theorem plane_clm_apply (M : ℝ × ℝ →L[ℝ] (Fin 3 → ℝ)) (w : ℝ × ℝ) :
    M w = w.1 • M (1, 0) + w.2 • M (0, 1) := by
  have hx : w = w.1 • ((1 : ℝ), (0 : ℝ)) + w.2 • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  conv_lhs => rw [hx]
  rw [map_add, map_smul, map_smul]

#print axioms plane_clm_apply


/-- Helper: the stretch under a change of arrows scales by the absolute determinant. -/
theorem stretch_scales_aux (ru rv : Fin 3 → ℝ) (us ut vs vt : ℝ) :
    √(((us • ru + vs • rv) ⬝ᵥ (us • ru + vs • rv)) * ((ut • ru + vt • rv) ⬝ᵥ (ut • ru + vt • rv))
        - ((us • ru + vs • rv) ⬝ᵥ (ut • ru + vt • rv)) ^ 2)
        = |us * vt - ut * vs| * √((ru ⬝ᵥ ru) * (rv ⬝ᵥ rv) - (ru ⬝ᵥ rv) ^ 2) := by
  have h : ((us • ru + vs • rv) ⬝ᵥ (us • ru + vs • rv)) * ((ut • ru + vt • rv) ⬝ᵥ (ut • ru + vt • rv))
        - ((us • ru + vs • rv) ⬝ᵥ (ut • ru + vt • rv)) ^ 2
      = (us * vt - ut * vs) ^ 2 * ((ru ⬝ᵥ ru) * (rv ⬝ᵥ rv) - (ru ⬝ᵥ rv) ^ 2) := by
    simp only [add_dotProduct, dotProduct_add, smul_dotProduct, dotProduct_smul,
      smul_eq_mul, dotProduct_comm rv ru]
    ring
  rw [h, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq_eq_abs]

#print axioms stretch_scales_aux

/-- **Area does not depend on the chart.** Take a chart `r` on an open grid region `D` that is
smooth (continuous tangent arrows), regular (EG − F² > 0 at every grid point) and covers each
point once. Take a second chart: a smooth map `φ` that sends an open region `D'` one-to-one onto
`D`, so that `r ∘ φ` names the same patch. Then adding √(EG − F²) over the second grid gives
the same area as adding it over the first. -/
theorem area_from_first_form_independent_of_chart
    (r : ℝ × ℝ → Fin 3 → ℝ) (D : Set (ℝ × ℝ)) (hD : IsOpen D)
    (hr : ContDiffOn ℝ 1 r D)
    (h_regular : ∀ p ∈ D, 0 < firstFormE r p * firstFormG r p - firstFormF r p ^ 2)
    (hr_once : InjOn r D)
    (φ : ℝ × ℝ → ℝ × ℝ) (D' : Set (ℝ × ℝ)) (hD' : IsOpen D')
    (hφ : ContDiffOn ℝ 1 φ D') (hφ_once : InjOn φ D') (hφ_onto : φ '' D' = D) :
    areaFromFirstForm (r ∘ φ) D' = areaFromFirstForm r D := by
  have hmeas : MeasurableSet D' := hD'.measurableSet
  have hmaps : ∀ x ∈ D', φ x ∈ D := fun x hx => hφ_onto ▸ mem_image_of_mem φ hx
  have hφd : ∀ x ∈ D', HasFDerivAt φ (fderiv ℝ φ x) x := fun x hx =>
    (((hφ.differentiableOn one_ne_zero) x hx).differentiableAt (hD'.mem_nhds hx)).hasFDerivAt
  have hrd : ∀ y ∈ D, HasFDerivAt r (fderiv ℝ r y) y := fun y hy =>
    (((hr.differentiableOn one_ne_zero) y hy).differentiableAt (hD.mem_nhds hy)).hasFDerivAt
  have : Measure.IsAddHaarMeasure (volume : Measure (ℝ × ℝ)) :=
    Measure.prod.instIsAddHaarMeasure _ _
  unfold areaFromFirstForm
  rw [← hφ_onto, integral_image_eq_integral_abs_det_fderiv_smul volume hmeas
    (fun x hx => (hφd x hx).hasFDerivWithinAt) hφ_once]
  refine setIntegral_congr_fun hmeas (fun x hx => ?_)
  have hcomp : fderiv ℝ (r ∘ φ) x = (fderiv ℝ r (φ x)).comp (fderiv ℝ φ x) :=
    ((hrd _ (hmaps x hx)).comp x (hφd x hx)).fderiv
  simp only [firstFormE, firstFormF, firstFormG, hcomp, ContinuousLinearMap.comp_apply,
    smul_eq_mul]
  rw [plane_clm_apply (fderiv ℝ r (φ x)) (fderiv ℝ φ x (1, 0)),
    plane_clm_apply (fderiv ℝ r (φ x)) (fderiv ℝ φ x (0, 1)), det_plane_clm]
  exact stretch_scales_aux (fderiv ℝ r (φ x) (1, 0))
    (fderiv ℝ r (φ x) (0, 1)) (fderiv ℝ φ x (1, 0)).1 (fderiv ℝ φ x (0, 1)).1
    (fderiv ℝ φ x (1, 0)).2 (fderiv ℝ φ x (0, 1)).2

/-- **The stretch is the cross-product length (Lagrange's identity).** For any two tangent
arrows `a` and `b` in space, with `E = a · a`, `F = a · b`, `G = b · b`, the squared length of
`a × b` is EG − F², so the stretch √(EG − F²) is the area of the parallelogram they span. -/
theorem cross_length_sq_eq_first_form (a b : Fin 3 → ℝ) :
    (a ⨯₃ b) ⬝ᵥ (a ⨯₃ b) = (a ⬝ᵥ a) * (b ⬝ᵥ b) - (a ⬝ᵥ b) ^ 2 ∧
    √((a ⨯₃ b) ⬝ᵥ (a ⨯₃ b)) = √((a ⬝ᵥ a) * (b ⬝ᵥ b) - (a ⬝ᵥ b) ^ 2) := by
  have h : (a ⨯₃ b) ⬝ᵥ (a ⨯₃ b) = (a ⬝ᵥ a) * (b ⬝ᵥ b) - (a ⬝ᵥ b) ^ 2 := by
    simp only [cross_apply, dotProduct, Fin.sum_univ_three]
    simp
    ring
  exact ⟨h, by rw [h]⟩

/-- **The stretch scales by the Jacobian.** Under a chart change `u = u(s, t)`, `v = v(s, t)`
the new arrows are `r̃_s = u_s r_u + v_s r_v` and `r̃_t = u_t r_u + v_t r_v`. Then the new
ẼG̃ − F̃² is (det J)² times EG − F², with det J = u_s v_t − u_t v_s, and the new stretch is
|det J| times the old one. -/
theorem first_form_stretch_scales_by_jacobian (ru rv : Fin 3 → ℝ) (us ut vs vt : ℝ) :
    let rs := us • ru + vs • rv
    let rt := ut • ru + vt • rv
    (rs ⬝ᵥ rs) * (rt ⬝ᵥ rt) - (rs ⬝ᵥ rt) ^ 2
        = (us * vt - ut * vs) ^ 2 * ((ru ⬝ᵥ ru) * (rv ⬝ᵥ rv) - (ru ⬝ᵥ rv) ^ 2) ∧
    √((rs ⬝ᵥ rs) * (rt ⬝ᵥ rt) - (rs ⬝ᵥ rt) ^ 2)
        = |us * vt - ut * vs| * √((ru ⬝ᵥ ru) * (rv ⬝ᵥ rv) - (ru ⬝ᵥ rv) ^ 2) := by
  intro rs rt
  have h : (rs ⬝ᵥ rs) * (rt ⬝ᵥ rt) - (rs ⬝ᵥ rt) ^ 2
      = (us * vt - ut * vs) ^ 2 * ((ru ⬝ᵥ ru) * (rv ⬝ᵥ rv) - (ru ⬝ᵥ rv) ^ 2) := by
    simp only [rs, rt, add_dotProduct, dotProduct_add, smul_dotProduct, dotProduct_smul,
      smul_eq_mul, dotProduct_comm rv ru]
    ring
  refine ⟨h, ?_⟩
  rw [h, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq_eq_abs]

-- The saddle's corner (30, 36) with a = 60: r_x = (1, 0, 1/2), r_y = (0, 1, −3/5), so
-- E = 1.25, F = −0.3, G = 1.36 and EG − F² = 1.7 − 0.09 = 1.61.
example : (![1, 0, 1/2] : Fin 3 → ℚ) ⬝ᵥ ![1, 0, 1/2] = 5/4 ∧
    (![1, 0, 1/2] : Fin 3 → ℚ) ⬝ᵥ ![0, 1, -3/5] = -3/10 ∧
    (![0, 1, -3/5] : Fin 3 → ℚ) ⬝ᵥ ![0, 1, -3/5] = 34/25 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
example : (5/4 : ℚ) * (34/25) = 17/10 ∧ (-3/10 : ℚ) ^ 2 = 9/100 ∧
    (5/4 : ℚ) * (34/25) - (-3/10) ^ 2 = 161/100 := by norm_num
-- Lagrange at the corner: r_x × r_y = (−1/2, 3/5, 1), whose squared length is also 1.61.
example : (![1, 0, 1/2] : Fin 3 → ℚ) ⨯₃ ![0, 1, -3/5] = ![-1/2, 3/5, 1] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
example : (![-1/2, 3/5, 1] : Fin 3 → ℚ) ⬝ᵥ ![-1/2, 3/5, 1] = 161/100 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
-- The cubic chart at the same corner: E = 4500, F = −1296, G = 7050.24, and its EG − F² is
-- 4320² times 1.61, where 4320 = 60 × 72 is the Jacobian determinant there.
example : (60 : ℚ) * 72 = 4320 ∧ (4500 : ℚ) * (176256/25) - (-1296) ^ 2 = 30046464 ∧
    (4320 : ℚ) ^ 2 * (161/100) = 30046464 := by norm_num
-- The diamond shingle, 0.5 m edges at 60°: E = G = 0.25, F = 0.125, EG − F² = 0.046875 = 3/64.
example : (1/4 : ℚ) * (1/4) - (1/8) ^ 2 = 3/64 := by norm_num
-- The dome, R = 60 m, rise h = 12 m: footprint radius 36 (36² + 48² = 60²), cos φ₀ = 48/60 = 0.8,
-- 3600 × (1 − 0.8) = 720 = 60 × 12 (so area 720π = πRh), plan 36²/2 = 648 (plan 648π),
-- ratio 720/648 = 10/9 = 1.111111.
example : 2 * 60 * 12 - 12 ^ 2 = (36 : ℕ) ^ 2 ∧ (36 : ℕ) ^ 2 + 48 ^ 2 = 60 ^ 2 := by norm_num
example : (48 : ℚ) / 60 = 4/5 ∧ (3600 : ℚ) * (1 - 4/5) = 720 ∧ (720 : ℚ) = 60 * 12 ∧
    (36 : ℚ) ^ 2 / 2 = 648 ∧ (720 : ℚ) / 648 = 10/9 := by norm_num
-- Copper sheet 0.6 mm thick at 8960 kg/m³ weighs 5.376 kg per m².
example : (6/10000 : ℚ) * 8960 = 672/125 ∧ (672/125 : ℚ) = 5376/1000 := by norm_num

#print axioms area_from_first_form_independent_of_chart
#print axioms cross_length_sq_eq_first_form
#print axioms first_form_stretch_scales_by_jacobian
