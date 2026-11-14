-- Navier-Stokes: rescaling the incompressible Navier-Stokes equations by a speed U and a length D leaves exactly one number, 1/Re with Re = ρUD/μ, in front of the friction term.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.CompMul
import Mathlib.Analysis.Calculus.FDeriv.Symmetric

open InnerProductSpace Laplacian

/-- Points and velocities live in ordinary 3D space. -/
local notation "ℝ³" => EuclideanSpace ℝ (Fin 3)

theorem lap_comp_smul_aux (f : ℝ³ → ℝ³) (D : ℝ) (hD : D ≠ 0) (x : ℝ³) :
    Δ (fun y => f (D • y)) x = (D ^ 2) • Δ f (D • x) := by
  set g : ℝ³ ≃L[ℝ] ℝ³ := ContinuousLinearEquiv.smulLeft (Units.mk0 D hD) with hgdef
  have hg : ∀ y, g y = D • y := fun y => by simp [g, Units.smul_def]
  have hfg : (fun y => f (D • y)) = f ∘ g := by funext y; simp [hg]
  have key := g.iteratedFDerivWithin_comp_right f uniqueDiffOn_univ (Set.mem_univ (g x)) 2
  simp only [Set.preimage_univ, iteratedFDerivWithin_univ] at key
  rw [hfg, laplacian_eq_iteratedFDeriv_stdOrthonormalBasis,
    laplacian_eq_iteratedFDeriv_stdOrthonormalBasis]
  simp only [key, Finset.smul_sum, hg]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [ContinuousMultilinearMap.compContinuousLinearMap_apply]
  have : (fun j => (g : ℝ³ →L[ℝ] ℝ³) (![(stdOrthonormalBasis ℝ ℝ³) i, (stdOrthonormalBasis ℝ ℝ³) i] j))
      = fun j => D • ![(stdOrthonormalBasis ℝ ℝ³) i, (stdOrthonormalBasis ℝ ℝ³) i] j := by
    funext j; simp [hg]
  rw [this, ContinuousMultilinearMap.map_smul_univ]
  simp [sq]

theorem lap_const_smul_aux (f : ℝ³ → ℝ³) (c : ℝ) (hc : c ≠ 0) (x : ℝ³) :
    Δ (fun y => c • f y) x = c • Δ f x := by
  set g : ℝ³ ≃L[ℝ] ℝ³ := ContinuousLinearEquiv.smulLeft (Units.mk0 c hc) with hgdef
  have hg : ∀ y, g y = c • y := fun y => by simp [g, Units.smul_def]
  have hfg : (fun y => c • f y) = g ∘ f := by funext y; simp [hg]
  rw [hfg, laplacian_CLE_comp_left]
  simp [hg]

theorem hasFDerivAt_partial_component_aux (u : ℝ³ → ℝ³) (hu : ContDiff ℝ 2 u) (v : ℝ³)
    (k : Fin 3) (x : ℝ³) :
    HasFDerivAt (fun y => fderiv ℝ u y v k)
      ((EuclideanSpace.proj k : ℝ³ →L[ℝ] ℝ).comp ((fderiv ℝ (fderiv ℝ u) x).flip v)) x := by
  have hdu : Differentiable ℝ (fderiv ℝ u) :=
    (hu.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have h1 : HasFDerivAt (fun y => fderiv ℝ u y v) ((fderiv ℝ (fderiv ℝ u) x).flip v) x := by
    have := (hdu x).hasFDerivAt.clm_apply (hasFDerivAt_const v x)
    simpa using this
  exact (EuclideanSpace.proj k : ℝ³ →L[ℝ] ℝ).hasFDerivAt.comp x h1

#print axioms lap_comp_smul_aux
#print axioms lap_const_smul_aux
#print axioms hasFDerivAt_partial_component_aux

/-- Rescaling Navier-Stokes gives the Reynolds form. Let a fluid of density `ρ` and viscosity
`μ` have velocity `u t x` and pressure `p t x`, obey Newton's law for every parcel,
`ρ (∂u/∂t + (u·∇)u) = -∇p + μ ∇²u` (gravity absorbed into `p`), and not compress (`∇·u = 0`).
Measure speed in units of `U`, length in units of `D`, time in units of `D/U` and pressure in
units of `ρU²`. Then the starred fields obey the same equations with every coefficient equal to
one except the friction term, which carries `1/Re` with `Re = ρUD/μ`; and they still do not
compress. -/
theorem navier_stokes_rescales_to_reynolds_form
    (ρ μ U D : ℝ) (hρ : 0 < ρ) (hμ : 0 < μ) (hU : 0 < U) (hD : 0 < D)
    (u : ℝ → ℝ³ → ℝ³) (p : ℝ → ℝ³ → ℝ)
    (hmom : ∀ t x, ρ • (deriv (fun s => u s x) t + fderiv ℝ (u t) x (u t x))
        = -gradient (p t) x + μ • Δ (u t) x)
    (hdiv : ∀ t x, ∑ k : Fin 3, fderiv ℝ (u t) x (EuclideanSpace.single k 1) k = 0) :
    let Re := ρ * U * D / μ
    let uS : ℝ → ℝ³ → ℝ³ := fun tS xS => U⁻¹ • u (D / U * tS) (D • xS)
    let pS : ℝ → ℝ³ → ℝ := fun tS xS => p (D / U * tS) (D • xS) / (ρ * U ^ 2)
    (∀ tS xS, deriv (fun s => uS s xS) tS + fderiv ℝ (uS tS) xS (uS tS xS)
        = -gradient (pS tS) xS + Re⁻¹ • Δ (uS tS) xS) ∧
    (∀ tS xS, ∑ k : Fin 3, fderiv ℝ (uS tS) xS (EuclideanSpace.single k 1) k = 0) := by
  intro Re uS pS
  have hU0 : U ≠ 0 := hU.ne'
  have hD0 : D ≠ 0 := hD.ne'
  have hρ0 : ρ ≠ 0 := hρ.ne'
  have hμ0 : μ ≠ 0 := hμ.ne'
  have h2 : ∀ tS xS, fderiv ℝ (uS tS) xS = (U⁻¹ * D) • fderiv ℝ (u (D / U * tS)) (D • xS) := by
    intro tS xS
    have : uS tS = U⁻¹ • (fun y => u (D / U * tS) (D • y)) := rfl
    rw [this, fderiv_const_smul_field]
    simp only [Pi.smul_apply]
    rw [fderiv_comp_smul (f := u (D / U * tS)), smul_smul]
  refine ⟨fun tS xS => ?_, fun tS xS => ?_⟩
  · set t := D / U * tS with ht
    set x := D • xS with hx
    have h1 : deriv (fun s => uS s xS) tS = (U⁻¹ * (D / U)) • deriv (fun s => u s x) t := by
      show deriv (U⁻¹ • fun s => u (D / U * s) (D • xS)) tS = _
      rw [deriv_const_smul_field,
        show deriv (fun s => u (D / U * s) (D • xS)) tS = (D / U) • deriv (fun s => u s x) t from
          deriv_comp_mul_left (D / U) (fun s => u s (D • xS)) tS, smul_smul]
    have h3 : gradient (pS tS) xS = (D / (ρ * U ^ 2)) • gradient (p t) x := by
      have : pS tS = (ρ * U ^ 2)⁻¹ • (fun y => p t (D • y)) := by
        funext y; simp [pS, t, div_eq_inv_mul]
      simp only [gradient]
      rw [this, fderiv_const_smul_field]
      simp only [Pi.smul_apply]
      rw [fderiv_comp_smul (f := p t), smul_smul, ← hx]
      simp [div_eq_inv_mul, mul_comm]
    have h4 : Δ (uS tS) xS = (U⁻¹ * D ^ 2) • Δ (u t) x := by
      have : uS tS = fun y => U⁻¹ • (fun z => u t (D • z)) y := rfl
      rw [this, lap_const_smul_aux _ _ (inv_ne_zero hU0), lap_comp_smul_aux _ _ hD0, smul_smul]
    have hv : uS tS xS = U⁻¹ • u t x := rfl
    have key : deriv (fun s => u s x) t + fderiv ℝ (u t) x (u t x)
        = ρ⁻¹ • (-gradient (p t) x + μ • Δ (u t) x) := by
      rw [← hmom t x, smul_smul, inv_mul_cancel₀ hρ0, one_smul]
    rw [h1, h2, h3, h4, hv, ContinuousLinearMap.smul_apply, map_smul, smul_smul]
    have : (U⁻¹ * (D / U)) • deriv (fun s => u s x) t + (U⁻¹ * D * U⁻¹) • fderiv ℝ (u t) x (u t x)
        = (D / U ^ 2) • (deriv (fun s => u s x) t + fderiv ℝ (u t) x (u t x)) := by
      rw [smul_add]; congr 1 <;> congr 1 <;> field_simp
    rw [this, key]
    simp only [Re]
    match_scalars <;> field_simp
  · rw [h2]
    simp only [ContinuousLinearMap.smul_apply, PiLp.smul_apply, smul_eq_mul, ← Finset.mul_sum,
      hdiv, mul_zero]

/-- Re is the ratio of the two term sizes. The inertia scale `ρU²/D` divided by the friction
scale `μU/D²` is `ρUD/μ`, and that equals `UD/ν` with `ν = μ/ρ`. -/
theorem reynolds_number_is_ratio_of_scales
    (ρ μ U D : ℝ) (hρ : 0 < ρ) (hμ : 0 < μ) (hU : 0 < U) (hD : 0 < D) :
    (ρ * U ^ 2 / D) / (μ * U / D ^ 2) = ρ * U * D / μ ∧
      ρ * U * D / μ = U * D / (μ / ρ) := by
  constructor <;> field_simp

/-- The full Newtonian friction stress collapses to `μ ∇²u`. With stresses
`τᵢⱼ = μ (∂ⱼuᵢ + ∂ᵢuⱼ)` (so `τₓₓ = 2μ ∂u/∂x`), the net friction force per unit volume along
direction `i`, `∑ⱼ ∂ⱼτᵢⱼ`, equals `μ (∇²u)ᵢ` when the fluid does not compress. -/
theorem newtonian_stress_divergence_eq_mu_laplacian
    (μ : ℝ) (u : ℝ³ → ℝ³) (hu : ContDiff ℝ 2 u)
    (hdiv : ∀ y, ∑ k : Fin 3, fderiv ℝ u y (EuclideanSpace.single k 1) k = 0)
    (x : ℝ³) (i : Fin 3) :
    ∑ j : Fin 3, fderiv ℝ (fun y => μ * (fderiv ℝ u y (EuclideanSpace.single j 1) i
        + fderiv ℝ u y (EuclideanSpace.single i 1) j)) x (EuclideanSpace.single j 1)
      = μ * Δ u x i := by
  set e : Fin 3 → ℝ³ := fun j => EuclideanSpace.single j 1 with he
  have hsymm : IsSymmSndFDerivAt ℝ u x :=
    hu.contDiffAt.isSymmSndFDerivAt (by simp)
  have hterm : ∀ j, fderiv ℝ (fun y => μ * (fderiv ℝ u y (e j) i + fderiv ℝ u y (e i) j)) x (e j)
      = μ * (fderiv ℝ (fderiv ℝ u) x (e j) (e j) i + fderiv ℝ (fderiv ℝ u) x (e i) (e j) j) := by
    intro j
    have h := ((hasFDerivAt_partial_component_aux u hu (e j) i x).fun_add
      (hasFDerivAt_partial_component_aux u hu (e i) j x)).const_mul μ
    rw [h.fderiv]
    simp [hsymm (e j) (e i), mul_add]
  have hzero : ∑ j, fderiv ℝ (fderiv ℝ u) x (e i) (e j) j = 0 := by
    have hs := HasFDerivAt.fun_sum (u := Finset.univ)
      (fun j _ => hasFDerivAt_partial_component_aux u hu (e j) j x)
    have hconst : (fun y => ∑ j ∈ Finset.univ, fderiv ℝ u y (e j) j) = fun _ => (0 : ℝ) := by
      funext y; exact hdiv y
    rw [hconst] at hs
    have := congrArg (fun L => L (e i)) (hs.unique (hasFDerivAt_const (0 : ℝ) x))
    simpa using this
  rw [laplacian_eq_iteratedFDeriv_orthonormalBasis u (EuclideanSpace.basisFun (Fin 3) ℝ)]
  simp only [EuclideanSpace.basisFun_apply, iteratedFDeriv_two_apply]
  change ∑ j, fderiv ℝ (fun y => μ * (fderiv ℝ u y (e j) i + fderiv ℝ u y (e i) j)) x (e j) = _
  simp only [hterm, ← Finset.mul_sum, Finset.sum_add_distrib, hzero, add_zero]
  simp [e]

#print axioms navier_stokes_rescales_to_reynolds_form
#print axioms reynolds_number_is_ratio_of_scales
#print axioms newtonian_stress_divergence_eq_mu_laplacian
