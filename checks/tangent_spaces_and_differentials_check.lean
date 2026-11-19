-- Tangent space and differential: the differential of a smooth map between manifolds sends the velocity of each path to the velocity of its image path, in any pair of charts it is the Jacobian matrix times the velocity's components, and differentials obey the chain rule.
import Mathlib.Geometry.Manifold.MFDeriv.Atlas
import Mathlib.Geometry.Manifold.MFDeriv.FDeriv
import Mathlib.Geometry.Manifold.ContMDiff.Atlas
import Mathlib.Analysis.InnerProductSpace.PiL2

open scoped Manifold ContDiff

namespace TangentSpacesAndDifferentials

/-
Setting. `M` is a smooth manifold of dimension `n` and `N` one of dimension `m`, both
without boundary: each is covered by charts with values in `ℝⁿ` (resp. `ℝᵐ`), written
`EuclideanSpace ℝ (Fin n)`. Mathlib's tangent space `TangentSpace 𝓘(ℝ, ℝⁿ) p` is the
space of velocities at `p`, and `mfderiv` is the differential `dF_p`.

A chart `x` of the smooth structure is a member of the maximal smooth atlas. The
components `vⁱ` of a velocity `v` at `p` in the chart `x` are `d(x)_p v`: the chart's own
differential reads off the rates of change of the chart's numbers. A path is a map
`γ : ℝ → M`, and its velocity at `t = 0` is `dγ_0 1`.
-/

variable {n m k : ℕ}
  {M : Type*} [TopologicalSpace M] [ChartedSpace (EuclideanSpace ℝ (Fin n)) M]
  [IsManifold 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) ∞ M]
  {N : Type*} [TopologicalSpace N] [ChartedSpace (EuclideanSpace ℝ (Fin m)) N]
  [IsManifold 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞ N]
  {P : Type*} [TopologicalSpace P] [ChartedSpace (EuclideanSpace ℝ (Fin k)) P]
  [IsManifold 𝓘(ℝ, EuclideanSpace ℝ (Fin k)) ∞ P]

/-- The card's formula. Let `F : M → N` be smooth at `p`. Take any chart `x` of `M` whose
domain contains `p` and any chart `y` of `N` whose domain contains `F p`. Then for every
velocity `v` at `p`, the components of `dF_p v` in the chart `y` are the Jacobian matrix
of `F` read in these charts, `y ∘ F ∘ x⁻¹`, taken at the point `x p`, times the components
of `v` in the chart `x`: `(dF_p v)ᵃ = ∑ᵢ (∂Fᵃ/∂xⁱ) vⁱ`. -/
theorem differential_in_charts_is_jacobian
    {F : M → N} {p : M} (hF : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin n))
      𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞ F p)
    {x : OpenPartialHomeomorph M (EuclideanSpace ℝ (Fin n))}
    (hx : x ∈ IsManifold.maximalAtlas 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) ∞ M)
    (hpx : p ∈ x.source)
    {y : OpenPartialHomeomorph N (EuclideanSpace ℝ (Fin m))}
    (hy : y ∈ IsManifold.maximalAtlas 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞ N)
    (hpy : F p ∈ y.source)
    (v : TangentSpace 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) p) :
    mfderiv 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) y (F p)
        (mfderiv 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) F p v) =
      fderiv ℝ (y ∘ F ∘ x.symm) (x p)
        (mfderiv 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) x p v) := by
  have hn : (∞ : WithTop ℕ∞) ≠ 0 := by decide
  have hxp : x p ∈ x.target := x.map_source hpx
  have hxs : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) ∞
      x.symm (x p) := contMDiffAt_symm_of_mem_maximalAtlas hx hxp
  have hxx : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) ∞
      x p := contMDiffAt_of_mem_maximalAtlas hx hpx
  have hyy : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞
      y (F p) := contMDiffAt_of_mem_maximalAtlas hy hpy
  have hsp : x.symm (x p) = p := x.left_inv hpx
  have hF' : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞
      F (x.symm (x p)) := by rw [hsp]; exact hF
  have hy' : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞
      y (F (x.symm (x p))) := by rw [hsp]; exact hyy
  have hG : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞
      (y ∘ F ∘ x.symm) (x p) := hy'.comp (x p) (hF'.comp (x p) hxs)
  have heq : (y ∘ F) =ᶠ[nhds p] ((y ∘ F ∘ x.symm) ∘ x) := by
    filter_upwards [x.open_source.mem_nhds hpx] with q hq
    simp [Function.comp, x.left_inv hq]
  rw [← mfderiv_comp_apply p (hyy.mdifferentiableAt hn) (hF.mdifferentiableAt hn)]
  rw [heq.mfderiv_eq]
  have hfd : mfderiv 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m))
      (y ∘ F ∘ x.symm) (x p) = fderiv ℝ (y ∘ F ∘ x.symm) (x p) :=
    (hG.mdifferentiableAt hn).differentiableAt.hasFDerivAt.hasMFDerivAt.mfderiv
  rw [mfderiv_comp p (hG.mdifferentiableAt hn) (hxx.mdifferentiableAt hn), hfd]
  rfl

/-- The differential carries velocities to velocities: if `γ` is a smooth path with
`γ 0 = p` and `F` is smooth at `p`, then `dF_p (γ'(0)) = (F ∘ γ)'(0)`. So any two paths
through `p` with the same velocity give the same velocity on the image. -/
theorem differential_sends_velocity_to_velocity
    {F : M → N} {p : M} (hF : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin n))
      𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞ F p)
    {γ : ℝ → M} (hγ : ContMDiffAt 𝓘(ℝ, ℝ) 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) ∞ γ 0)
    (hγp : γ 0 = p) :
    mfderiv 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) F p
        (mfderiv 𝓘(ℝ, ℝ) 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) γ 0 (1 : ℝ)) =
      mfderiv 𝓘(ℝ, ℝ) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) (F ∘ γ) 0 (1 : ℝ) := by
  have hn : (∞ : WithTop ℕ∞) ≠ 0 := by decide
  subst hγp
  exact (mfderiv_comp_apply 0 (hF.mdifferentiableAt hn) (hγ.mdifferentiableAt hn) (1 : ℝ)).symm

/-- The chain rule for differentials: if `F : M → N` is smooth at `p` and `G : N → P` is
smooth at `F p`, then `d(G ∘ F)_p = dG_{F p} ∘ dF_p`. -/
theorem differential_chain_rule
    {F : M → N} {G : N → P} {p : M}
    (hF : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) ∞ F p)
    (hG : ContMDiffAt 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) 𝓘(ℝ, EuclideanSpace ℝ (Fin k)) ∞ G (F p)) :
    mfderiv 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin k)) (G ∘ F) p =
      (mfderiv 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) 𝓘(ℝ, EuclideanSpace ℝ (Fin k)) G (F p)).comp
        (mfderiv 𝓘(ℝ, EuclideanSpace ℝ (Fin n)) 𝓘(ℝ, EuclideanSpace ℝ (Fin m)) F p) := by
  have hn : (∞ : WithTop ℕ∞) ≠ 0 := by decide
  exact mfderiv_comp p (hG.mdifferentiableAt hn) (hF.mdifferentiableAt hn)

#print axioms differential_in_charts_is_jacobian
#print axioms differential_sends_velocity_to_velocity
#print axioms differential_chain_rule

end TangentSpacesAndDifferentials
