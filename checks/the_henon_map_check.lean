-- The Henon map: every step multiplies every area by |b|, its Jacobian has determinant -b everywhere, and at a = 1.4, b = 0.3 both fixed points are saddles.
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Mathlib.Tactic
import Mathlib.Analysis.Calculus.FDeriv.Pow
import Mathlib.Analysis.Calculus.FDeriv.Mul

open MeasureTheory

/-- The Henon map with bend `a` and squeeze `b`: `(x, y) ↦ (1 - a x² + y, b x)`. -/
def henon (a b : ℝ) (p : ℝ × ℝ) : ℝ × ℝ := (1 - a * p.1 ^ 2 + p.2, b * p.1)

/-- The derivative of the Henon map at `p`: `(u, v) ↦ (-2 a p.1 u + v, b u)`. -/
theorem henon_hasFDerivAt (a b : ℝ) (p : ℝ × ℝ) :
    HasFDerivAt (henon a b)
      (((-(2 * a * p.1)) • ContinuousLinearMap.fst ℝ ℝ ℝ + ContinuousLinearMap.snd ℝ ℝ ℝ).prod
        (b • ContinuousLinearMap.fst ℝ ℝ ℝ)) p := by
  have h1 : HasFDerivAt (fun q : ℝ × ℝ => 1 - a * q.1 ^ 2 + q.2)
      ((-(2 * a * p.1)) • ContinuousLinearMap.fst ℝ ℝ ℝ + ContinuousLinearMap.snd ℝ ℝ ℝ) p := by
    have hf : HasFDerivAt (Prod.fst : ℝ × ℝ → ℝ) (ContinuousLinearMap.fst ℝ ℝ ℝ) p := hasFDerivAt_fst
    have := HasFDerivAt.add (HasFDerivAt.const_sub (HasFDerivAt.const_mul (HasFDerivAt.pow hf 2) a) 1)
      (hasFDerivAt_snd : HasFDerivAt (Prod.snd : ℝ × ℝ → ℝ) (ContinuousLinearMap.snd ℝ ℝ ℝ) p)
    convert this using 1
    ext <;> simp; ring
  have h2 : HasFDerivAt (fun q : ℝ × ℝ => b * q.1) (b • ContinuousLinearMap.fst ℝ ℝ ℝ) p := by
    have hf : HasFDerivAt (Prod.fst : ℝ × ℝ → ℝ) (ContinuousLinearMap.fst ℝ ℝ ℝ) p := hasFDerivAt_fst
    have := HasFDerivAt.const_mul hf b
    convert this using 1
  exact h1.prodMk h2

/-- The derivative of the Henon map, applied to a vector. -/
theorem henon_fderiv_apply (a b : ℝ) (p q : ℝ × ℝ) :
    fderiv ℝ (henon a b) p q = (-(2 * a * p.1) * q.1 + q.2, b * q.1) := by
  rw [(henon_hasFDerivAt a b p).fderiv]
  simp

/-- Every area is multiplied by `|b|` each step: for any set `s` in the plane, the area
(Lebesgue measure) of its image under the Henon map is `|b|` times the area of `s`. -/
theorem henon_area_multiplied_by_abs_b (a b : ℝ) (s : Set (ℝ × ℝ)) :
    volume (henon a b '' s) = ENNReal.ofReal |b| * volume s := by
  let e : (ℝ × ℝ) ≃ᵐ (ℝ × ℝ) :=
    { toFun := fun p => (p.1, p.2 + (1 - a * p.1 ^ 2))
      invFun := fun p => (p.1, p.2 - (1 - a * p.1 ^ 2))
      left_inv := fun p => by simp
      right_inv := fun p => by simp
      measurable_toFun := (by fun_prop : Measurable fun p : ℝ × ℝ => (p.1, p.2 + (1 - a * p.1 ^ 2)))
      measurable_invFun := (by fun_prop : Measurable fun p : ℝ × ℝ => (p.1, p.2 - (1 - a * p.1 ^ 2))) }
  have he : MeasurePreserving e volume volume := by
    rw [Measure.volume_eq_prod]
    exact (MeasurePreserving.id volume).skew_product (g := fun x y => y + (1 - a * x ^ 2))
      (by fun_prop) (ae_of_all _ fun x => map_add_right_eq_self volume _)
  let L : ℝ × ℝ →ₗ[ℝ] ℝ × ℝ := LinearMap.prod (LinearMap.snd ℝ ℝ ℝ) (b • LinearMap.fst ℝ ℝ ℝ)
  have hL : LinearMap.det L = -b := by
    rw [← LinearMap.det_toMatrix (Module.Basis.finTwoProd ℝ), Matrix.det_fin_two]
    simp [L, LinearMap.toMatrix_apply]
  have hcomp : henon a b = L ∘ e := by
    funext p
    simp [henon, L, e]
    ring
  have : Measure.IsAddHaarMeasure (volume : Measure (ℝ × ℝ)) :=
    Measure.prod.instIsAddHaarMeasure _ _
  rw [hcomp, Set.image_comp, Measure.addHaar_image_linearMap, hL, abs_neg,
    MeasurableEquiv.image_eq_preimage_symm, he.symm.measure_preimage_equiv]

/-- The Jacobian of the Henon map has determinant `-b` at every point, whatever the bend `a`. -/
theorem henon_jacobian_det (a b : ℝ) (p : ℝ × ℝ) :
    LinearMap.det (fderiv ℝ (henon a b) p : ℝ × ℝ →ₗ[ℝ] ℝ × ℝ) = -b := by
  rw [← LinearMap.det_toMatrix (Module.Basis.finTwoProd ℝ), Matrix.det_fin_two]
  simp [LinearMap.toMatrix_apply, henon_fderiv_apply]

/-- At `a = 1.4`, `b = 0.3`, a fixed point `(x, y)` has `y = 0.3 x` and `1.4 x² + 0.7 x - 1 = 0`,
and it is a saddle: its Jacobian has one real eigenvalue smaller than 1 in size and one larger. -/
theorem henon_fixed_points_are_saddles (x y : ℝ) (h : henon (7 / 5) (3 / 10) (x, y) = (x, y)) :
    y = 3 / 10 * x ∧ 7 / 5 * x ^ 2 + 7 / 10 * x - 1 = 0 ∧
      ∃ μ₁ μ₂ : ℝ, |μ₁| < 1 ∧ 1 < |μ₂| ∧
        Module.End.HasEigenvalue
          (fderiv ℝ (henon (7 / 5) (3 / 10)) (x, y) : ℝ × ℝ →ₗ[ℝ] ℝ × ℝ) μ₁ ∧
        Module.End.HasEigenvalue
          (fderiv ℝ (henon (7 / 5) (3 / 10)) (x, y) : ℝ × ℝ →ₗ[ℝ] ℝ × ℝ) μ₂ := by
  simp only [henon, Prod.mk.injEq] at h
  obtain ⟨h1, h2⟩ := h
  have hy : y = 3 / 10 * x := by linarith
  have hq : 7 / 5 * x ^ 2 + 7 / 10 * x - 1 = 0 := by subst hy; linarith
  refine ⟨hy, hq, ?_⟩
  have key : ∀ μ : ℝ, μ ^ 2 + (2 * (7 / 5) * x) * μ - 3 / 10 = 0 →
      Module.End.HasEigenvalue
        (fderiv ℝ (henon (7 / 5) (3 / 10)) (x, y) : ℝ × ℝ →ₗ[ℝ] ℝ × ℝ) μ := by
    intro μ hμ
    apply Module.End.hasEigenvalue_of_hasEigenvector (x := ((μ, 3 / 10) : ℝ × ℝ))
    refine ⟨?_, ?_⟩
    · rw [Module.End.mem_eigenspace_iff]
      simp only [ContinuousLinearMap.coe_coe, henon_fderiv_apply, Prod.smul_mk, smul_eq_mul,
        Prod.mk.injEq]
      constructor
      · linear_combination -hμ
      · ring
    · simp
  set t := 2 * (7 / 5 : ℝ) * x with ht
  set s := Real.sqrt (t ^ 2 + 6 / 5) with hs
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hs2 : s ^ 2 = t ^ 2 + 6 / 5 := Real.sq_sqrt (by positivity)
  have hra : ((-t + s) / 2) ^ 2 + t * ((-t + s) / 2) - 3 / 10 = 0 := by
    linear_combination hs2 / 4
  have hrb : ((-t - s) / 2) ^ 2 + t * ((-t - s) / 2) - 3 / 10 = 0 := by
    linear_combination hs2 / 4
  rcases lt_or_gt_of_ne (show x ≠ 0 by rintro rfl; norm_num at hq) with hx | hx
  · -- negative root: x < -1
    have hx1 : x < -1 := by nlinarith
    have hst : -t < s := by nlinarith
    refine ⟨(-t - s) / 2, (-t + s) / 2, ?_, ?_, key _ hrb, key _ hra⟩
    · rw [abs_lt]; constructor <;> nlinarith
    · rw [lt_abs]; left; nlinarith
  · -- positive root: x > 1/2
    have hx1 : 1 / 2 < x := by nlinarith
    have hst : t < s := by nlinarith
    refine ⟨(-t + s) / 2, (-t - s) / 2, ?_, ?_, key _ hra, key _ hrb⟩
    · rw [abs_lt]; constructor <;> nlinarith
    · rw [lt_abs]; right; nlinarith

-- The orbit from (0, 0): (1, 0), (-0.4, 0.3), (1.076, -0.12), (-0.7408864, 0.3228).
example : henon (7 / 5) (3 / 10) (0, 0) = (1, 0) := by norm_num [henon]
example : henon (7 / 5) (3 / 10) (1, 0) = (-2 / 5, 3 / 10) := by norm_num [henon]
example : henon (7 / 5) (3 / 10) (-2 / 5, 3 / 10) = (269 / 250, -3 / 25) := by norm_num [henon]
example : henon (7 / 5) (3 / 10) (269 / 250, -3 / 25) = (-231527 / 312500, 807 / 2500) := by
  norm_num [henon]
-- The fixed-point quadratic at a = 1.4, b = 0.3: (1 - b)² + 4a = 6.09.
example : (1 - (3 / 10 : ℚ)) ^ 2 + 4 * (7 / 5) = 609 / 100 := by norm_num
-- The square [-1.5, 1.5]² of area 9: signed area 9 × (-0.3) = -2.7, then × (-0.3) = 0.81.
example : (9 : ℚ) * (-3 / 10) = -27 / 10 ∧ (-27 / 10 : ℚ) * (-3 / 10) = 81 / 100 := by norm_num
-- The escaping start (2, 0): x runs 2, -4.6, -28.024.
example : henon (7 / 5) (3 / 10) (2, 0) = (-23 / 5, 3 / 5) := by norm_num [henon]
example : (henon (7 / 5) (3 / 10) (-23 / 5, 3 / 5)).1 = -3503 / 125 := by norm_num [henon]

#print axioms henon_hasFDerivAt
#print axioms henon_fderiv_apply
#print axioms henon_area_multiplied_by_abs_b
#print axioms henon_jacobian_det
#print axioms henon_fixed_points_are_saddles
