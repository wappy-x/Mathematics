-- Surface integrals: the area of a sheet, the sum of the lengths of r_u × r_v over the grid, does not depend on which grid is lifted, the flux, the sum of F · (r_u × r_v), stays the same under a grid change that keeps the side and flips sign under one that swaps it, and the card's taut tarp has 15 m^2 of fabric and catches 120 litres an hour in still air and 165 blown north.
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Data.Fin.VecNotation
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar

/-! A grid point is a pair `p = (u, v) : ℝ × ℝ`, and the grid's region `D` is a set of pairs.
A point of space is a list of three real numbers, `Fin 3 → ℝ` (east, north, up). A sheet is
a map `r : ℝ × ℝ → Fin 3 → ℝ`. Its tangent arrows at `p` are `r_u = fderiv ℝ r p (1, 0)` and
`r_v = fderiv ℝ r p (0, 1)`: how far and which way the point moves per unit of `u`, or of `v`.
Mathlib's `a ⨯₃ b` is the cross product and `a ⬝ᵥ b` the dot product, so the length of an
arrow `a` is `√(a ⬝ᵥ a)`. Integrals over the grid are Lebesgue integrals for area on the plane.
A flow `F` sends each point of space to the arrow of what passes there. A grid change is a map
`φ` from a new region `E` onto `D`; `(fderiv ℝ φ p).det` is its Jacobian determinant J. -/

open MeasureTheory Set Matrix

/-- The area vector `N = r_u × r_v` of the sheet `r` at the grid point `p`. -/
noncomputable def areaVector (r : ℝ × ℝ → Fin 3 → ℝ) (p : ℝ × ℝ) : Fin 3 → ℝ :=
  fderiv ℝ r p (1, 0) ⨯₃ fderiv ℝ r p (0, 1)

/-- Area(S) = ∬_D ‖r_u × r_v‖ du dv. -/
noncomputable def surfaceArea (r : ℝ × ℝ → Fin 3 → ℝ) (D : Set (ℝ × ℝ)) : ℝ :=
  ∫ p in D, √(areaVector r p ⬝ᵥ areaVector r p)

/-- Φ = ∬_D F(r(u, v)) · (r_u × r_v) du dv. -/
noncomputable def flux (F : (Fin 3 → ℝ) → Fin 3 → ℝ) (r : ℝ × ℝ → Fin 3 → ℝ)
    (D : Set (ℝ × ℝ)) : ℝ :=
  ∫ p in D, F (r p) ⬝ᵥ areaVector r p

/-- The determinant of a linear map of the plane, read off from where it sends (1, 0) and (0, 1). -/
lemma det_eq_of_basis (A : ℝ × ℝ →L[ℝ] ℝ × ℝ) :
    A.det = (A (1,0)).1 * (A (0,1)).2 - (A (0,1)).1 * (A (1,0)).2 := by
  rw [ContinuousLinearMap.det, ← LinearMap.det_toMatrix (Module.Basis.finTwoProd ℝ),
    Matrix.det_fin_two]
  simp [LinearMap.toMatrix_apply, Module.Basis.finTwoProd_zero, Module.Basis.finTwoProd_one]

/-- Composing with a linear map `A` of the plane scales the cross product by `det A`. -/
lemma cross_comp_det (L : ℝ × ℝ →L[ℝ] (Fin 3 → ℝ)) (A : ℝ × ℝ →L[ℝ] ℝ × ℝ) :
    L (A (1,0)) ⨯₃ L (A (0,1)) = A.det • (L (1,0) ⨯₃ L (0,1)) := by
  have key : ∀ x : ℝ × ℝ, L x = x.1 • L (1,0) + x.2 • L (0,1) := by
    intro x; rw [← map_smul, ← map_smul, ← map_add]; congr 1; ext <;> simp
  rw [key (A (1,0)), key (A (0,1)), det_eq_of_basis]
  ext i; fin_cases i <;> simp [cross_apply] <;> ring

/-- Under a grid change, the area vector picks up the Jacobian determinant. -/
lemma areaVector_comp (r : ℝ × ℝ → Fin 3 → ℝ) (D : Set (ℝ × ℝ)) (hD : IsOpen D)
    (hr : ContDiffOn ℝ 1 r D) (φ : ℝ × ℝ → ℝ × ℝ) (E : Set (ℝ × ℝ)) (hE : IsOpen E)
    (hφ : ContDiffOn ℝ 1 φ E) (hφ_onto : φ '' E = D) (p : ℝ × ℝ) (hp : p ∈ E) :
    areaVector (r ∘ φ) p = (fderiv ℝ φ p).det • areaVector r (φ p) := by
  have hφd : DifferentiableAt ℝ φ p :=
    (hφ.differentiableOn one_ne_zero p hp).differentiableAt (hE.mem_nhds hp)
  have hq : φ p ∈ D := hφ_onto ▸ mem_image_of_mem φ hp
  have hrd : DifferentiableAt ℝ r (φ p) :=
    (hr.differentiableOn one_ne_zero _ hq).differentiableAt (hD.mem_nhds hq)
  unfold areaVector
  rw [fderiv_comp p hrd hφd]
  simp only [ContinuousLinearMap.comp_apply]
  exact cross_comp_det _ _

/-- The change of variables formula for a grid change. -/
lemma integral_grid_change (φ : ℝ × ℝ → ℝ × ℝ) (E : Set (ℝ × ℝ)) (hE : IsOpen E)
    (hφ : ContDiffOn ℝ 1 φ E) (hφ_once : InjOn φ E) (g : ℝ × ℝ → ℝ) :
    ∫ p in φ '' E, g p = ∫ p in E, |(fderiv ℝ φ p).det| * g (φ p) := by
  haveI : (volume : Measure (ℝ × ℝ)).IsAddHaarMeasure := Measure.prod.instIsAddHaarMeasure _ _
  rw [integral_image_eq_integral_abs_det_fderiv_smul volume hE.measurableSet
    (fun x hx => ((hφ.differentiableOn one_ne_zero x hx).differentiableAt
      (hE.mem_nhds hx)).hasFDerivAt.hasFDerivWithinAt) hφ_once]
  rfl

/-- **Area does not depend on the grid.** Take a sheet `r` on an open grid region `D` that is
smooth (continuous tangent arrows), has an area vector that is never zero, and counts each point
once. Take a second grid: a smooth map `φ` that sends an open region `E` one-to-one onto `D`.
Then lifting the second grid, `r ∘ φ` on `E`, reports the same area as lifting the first. -/
theorem surface_area_independent_of_grid
    (r : ℝ × ℝ → Fin 3 → ℝ) (D : Set (ℝ × ℝ)) (hD : IsOpen D)
    (hr : ContDiffOn ℝ 1 r D) (hN : ∀ p ∈ D, areaVector r p ≠ 0) (hr_once : InjOn r D)
    (φ : ℝ × ℝ → ℝ × ℝ) (E : Set (ℝ × ℝ)) (hE : IsOpen E)
    (hφ : ContDiffOn ℝ 1 φ E) (hφ_once : InjOn φ E) (hφ_onto : φ '' E = D) :
    surfaceArea (r ∘ φ) E = surfaceArea r D := by
  unfold surfaceArea
  rw [← hφ_onto, integral_grid_change φ E hE hφ hφ_once]
  refine setIntegral_congr_fun hE.measurableSet (fun p hp => ?_)
  rw [areaVector_comp r D hD hr φ E hE hφ hφ_onto p hp, smul_dotProduct, dotProduct_smul,
    smul_eq_mul, smul_eq_mul, ← mul_assoc, Real.sqrt_mul (mul_self_nonneg _),
    Real.sqrt_mul_self_eq_abs]

/-- **Flux does not depend on the grid, up to the side.** With the same sheet and grid change,
and any flow `F`: if the Jacobian determinant J of the grid change is positive throughout `E`,
the second grid reports the same flux; if J is negative throughout `E`, the normal has switched
sides and the flux flips sign. -/
theorem flux_independent_of_grid_up_to_side
    (r : ℝ × ℝ → Fin 3 → ℝ) (D : Set (ℝ × ℝ)) (hD : IsOpen D)
    (hr : ContDiffOn ℝ 1 r D) (hN : ∀ p ∈ D, areaVector r p ≠ 0) (hr_once : InjOn r D)
    (φ : ℝ × ℝ → ℝ × ℝ) (E : Set (ℝ × ℝ)) (hE : IsOpen E)
    (hφ : ContDiffOn ℝ 1 φ E) (hφ_once : InjOn φ E) (hφ_onto : φ '' E = D)
    (F : (Fin 3 → ℝ) → Fin 3 → ℝ) :
    ((∀ p ∈ E, 0 < (fderiv ℝ φ p).det) → flux F (r ∘ φ) E = flux F r D) ∧
    ((∀ p ∈ E, (fderiv ℝ φ p).det < 0) → flux F (r ∘ φ) E = -flux F r D) := by
  unfold flux
  have h : ∀ p ∈ E, F ((r ∘ φ) p) ⬝ᵥ areaVector (r ∘ φ) p
      = (fderiv ℝ φ p).det * (F (r (φ p)) ⬝ᵥ areaVector r (φ p)) := by
    intro p hp
    rw [areaVector_comp r D hD hr φ E hE hφ hφ_onto p hp, dotProduct_smul, smul_eq_mul]
    rfl
  rw [← hφ_onto, integral_grid_change φ E hE hφ hφ_once]
  refine ⟨fun hpos => ?_, fun hneg => ?_⟩
  · refine setIntegral_congr_fun hE.measurableSet (fun p hp => ?_)
    rw [h p hp, abs_of_pos (hpos p hp)]
  · rw [← integral_neg]
    refine setIntegral_congr_fun hE.measurableSet (fun p hp => ?_)
    rw [h p hp, abs_of_neg (hneg p hp)]
    ring

/-- **The taut tarp.** The tarp `r(u, v) = (u, v, 0.75 v)` over the ground rectangle 4 m by
3 m has 15 m^2 of fabric. Rain with flow `(0, w, -0.01)` metres of water per hour (falling
10 mm an hour, drifting `w` north) has flux `-(0.12 + 9 w)` cubic metres an hour up through the
top face: −120 litres an hour in still air, −165 blown north at `w = 0.005`, −75 blown south. -/
theorem taut_tarp_area_and_flux :
    surfaceArea (fun p => ![p.1, p.2, 3 / 4 * p.2]) (Icc 0 4 ×ˢ Icc 0 3) = 15 ∧
    ∀ w : ℝ, flux (fun _ => ![0, w, -1 / 100]) (fun p => ![p.1, p.2, 3 / 4 * p.2])
      (Icc 0 4 ×ˢ Icc 0 3) = -(12 / 100 + 9 * w) := by
  set L : ℝ × ℝ →L[ℝ] (Fin 3 → ℝ) := ContinuousLinearMap.pi
    ![ContinuousLinearMap.fst ℝ ℝ ℝ, ContinuousLinearMap.snd ℝ ℝ ℝ,
      (3 / 4 : ℝ) • ContinuousLinearMap.snd ℝ ℝ ℝ] with hLdef
  have hL : (fun p : ℝ × ℝ => ![p.1, p.2, 3 / 4 * p.2]) = ⇑L := by
    funext p i; fin_cases i <;> simp [L]
  have hN : ∀ p, areaVector (fun p : ℝ × ℝ => ![p.1, p.2, 3 / 4 * p.2]) p = ![0, -3/4, 1] := by
    intro p; rw [areaVector, hL, L.fderiv]
    ext i; fin_cases i <;> simp [L, cross_apply] <;> norm_num
  have hvol : volume.real (Icc (0:ℝ) 4 ×ˢ Icc (0:ℝ) 3) = 12 := by
    rw [measureReal_def, Measure.volume_eq_prod, Measure.prod_prod, Real.volume_Icc,
      Real.volume_Icc]
    norm_num [ENNReal.toReal_mul]
  have hsq : √((![0, -3/4, 1] : Fin 3 → ℝ) ⬝ᵥ ![0, -3/4, 1]) = 5 / 4 := by
    rw [show (![0, -3/4, 1] : Fin 3 → ℝ) ⬝ᵥ ![0, -3/4, 1] = (5/4) ^ 2 by
      simp [dotProduct, Fin.sum_univ_succ]; norm_num]
    exact Real.sqrt_sq (by norm_num)
  refine ⟨?_, fun w => ?_⟩
  · unfold surfaceArea
    simp only [hN, hsq, setIntegral_const, hvol, smul_eq_mul]
    norm_num
  · unfold flux
    simp only [hN, setIntegral_const, hvol, smul_eq_mul]
    simp [dotProduct, Fin.sum_univ_succ]
    ring

-- The tarp's tangent arrows (1, 0, 0) and (0, 1, 0.75) have area vector (0, −0.75, 1).
example : (![1, 0, 0] : Fin 3 → ℚ) ⨯₃ ![0, 1, 3/4] = ![0, -3/4, 1] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
-- Its squared length is 0.75^2 + 1 = 1.5625 = 1.25^2, so the stretch is 1.25.
example : (![0, -3/4, 1] : Fin 3 → ℚ) ⬝ᵥ ![0, -3/4, 1] = (5/4) ^ 2 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
example : √((25 / 16 : ℝ)) = 5 / 4 := by
  rw [show (25 / 16 : ℝ) = (5 / 4) ^ 2 by norm_num]; exact Real.sqrt_sq (by norm_num)
-- 1.25 × 12 m^2 = 15 m^2; Pythagoras: 3^2 + 2.25^2 = 3.75^2, and 3.75 × 4 = 15.
example : (5/4 : ℚ) * 12 = 15 ∧ (3 : ℚ) ^ 2 + (9/4) ^ 2 = (15/4) ^ 2 ∧ (15/4 : ℚ) * 4 = 15 := by
  norm_num
-- Rain dotted with the area vector, blown north: 0.005 × (−0.75) + (−0.01) × 1 = −0.01375 m/h,
-- and times 12 m^2 that is −0.165 m^3 = −165 litres an hour.
example : (![0, 1/200, -1/100] : Fin 3 → ℚ) ⬝ᵥ ![0, -3/4, 1] = -11/800 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
example : (-11/800 : ℚ) * 12 * 1000 = -165 := by norm_num
-- Still air: −0.01 × 12 m^2 = −120 litres an hour; blown south: −6.25 mm/h × 12 = −75.
example : (-1/100 : ℚ) * 12 * 1000 = -120 ∧ (-25/4 : ℚ) / 1000 * 12 * 1000 = -75 := by norm_num
-- The shadow, blown north: the top edge lands 3 + 2.25 × 0.5 = 4.125 m out, 4 × 4.125 = 16.5 m^2,
-- and 16.5 m^2 × 10 mm/h = 165 litres an hour. Blown south: 3 − 1.125 = 1.875 m, 7.5 m^2, 75.
example : (3 : ℚ) + 9/4 * (1/2) = 33/8 ∧ 4 * (33/8 : ℚ) = 33/2 ∧ (33/2 : ℚ) * 10 = 165 := by
  norm_num
example : (3 : ℚ) - 9/4 * (1/2) = 15/8 ∧ 4 * (15/8 : ℚ) = 15/2 ∧ (15/2 : ℚ) * 10 = 75 := by
  norm_num
-- The slant grid r(u, s) = (u, 0.8 s, 0.6 s): N = (0, −0.6, 0.8), of length 1, and the grid
-- change v = 0.8 s has J = 0.8, with 0.8 × 1.25 = 1 and 4 × 3.75 = 15.
example : (![1, 0, 0] : Fin 3 → ℚ) ⨯₃ ![0, 4/5, 3/5] = ![0, -3/5, 4/5] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
example : (![0, -3/5, 4/5] : Fin 3 → ℚ) ⬝ᵥ ![0, -3/5, 4/5] = 1 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
example : (4/5 : ℚ) * (5/4) = 1 ∧ (4 : ℚ) * (15/4) = 15 := by norm_num
-- The mistakes: unit normal with ground cells, 12 × 0.01 / 1.25 = 0.096 m^3 = 96 litres;
-- reversing the cross product gives (0, 0.75, −1), and still rain then crosses at +120.
example : (12 : ℚ) * (1/100) / (5/4) * 1000 = 96 := by norm_num
example : (![0, 1, 3/4] : Fin 3 → ℚ) ⨯₃ ![1, 0, 0] = ![0, 3/4, -1] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
example : (![0, 0, -1/100] : Fin 3 → ℚ) ⬝ᵥ ![0, 3/4, -1] * 12 * 1000 = 120 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num

#print axioms det_eq_of_basis
#print axioms cross_comp_det
#print axioms areaVector_comp
#print axioms integral_grid_change
#print axioms surface_area_independent_of_grid
#print axioms flux_independent_of_grid_up_to_side
#print axioms taut_tarp_area_and_flux
