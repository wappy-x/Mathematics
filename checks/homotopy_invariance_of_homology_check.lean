-- Homotopy invariance: homotopy equivalent spaces have isomorphic integer singular homology and equal Betti numbers in every dimension.
import Mathlib.AlgebraicTopology.SingularHomology.HomotopyInvariance
import Mathlib.Algebra.Category.ModuleCat.Colimits
import Mathlib.Algebra.Category.ModuleCat.Abelian
import Mathlib.Topology.Homotopy.Equiv
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Contractible

open CategoryTheory AlgebraicTopology

namespace HomotopyInvarianceOfHomology

/-- `H k X` is the `k`-th singular homology group of the space `X`, with integer coefficients. -/
noncomputable abbrev H (k : ℕ) (X : Type) [TopologicalSpace X] : ModuleCat ℤ :=
  ((singularHomologyFunctor (ModuleCat ℤ) k).obj (ModuleCat.of ℤ ℤ)).obj (TopCat.of X)

/-- `Hmap k f` is the map `f_*` that a continuous map `f` causes on `k`-th homology. -/
noncomputable abbrev Hmap (k : ℕ) {X Y : Type} [TopologicalSpace X] [TopologicalSpace Y]
    (f : C(X, Y)) : H k X ⟶ H k Y :=
  ((singularHomologyFunctor (ModuleCat ℤ) k).obj (ModuleCat.of ℤ ℤ)).map (TopCat.ofHom f)

/-- Helper: homotopic maps induce equal maps on singular homology (from Mathlib's
`TopCat.Homotopy.congr_homologyMap_singularChainComplexFunctor`). -/
theorem hmap_eq_of_homotopic_aux {X Y : Type} [TopologicalSpace X] [TopologicalSpace Y]
    {f g : C(X, Y)} (h : f.Homotopic g) (k : ℕ) :
    Hmap k f = Hmap k g := by
  obtain ⟨F⟩ := h
  exact TopCat.Homotopy.congr_homologyMap_singularChainComplexFunctor
    (f := TopCat.ofHom f) (g := TopCat.ofHom g) F (ModuleCat.of ℤ ℤ) k

#print axioms hmap_eq_of_homotopic_aux

/-- Homotopy invariance: if two spaces are homotopy equivalent (maps both ways whose round
trips are each homotopic to the identity), then their homology groups are isomorphic in every
dimension `k`, and so their Betti numbers (ranks over the integers) are equal. -/
theorem homology_iso_of_homotopy_equivalent {X Y : Type} [TopologicalSpace X]
    [TopologicalSpace Y] (e : ContinuousMap.HomotopyEquiv X Y) (k : ℕ) :
    Nonempty (H k X ≅ H k Y) ∧ Module.finrank ℤ (H k X) = Module.finrank ℤ (H k Y) := by
  let i : H k X ≅ H k Y :=
    { hom := Hmap k e.toFun
      inv := Hmap k e.invFun
      hom_inv_id := by
        rw [← Functor.map_comp, ← TopCat.ofHom_comp]
        exact (hmap_eq_of_homotopic_aux e.left_inv k).trans (CategoryTheory.Functor.map_id _ _)
      inv_hom_id := by
        rw [← Functor.map_comp, ← TopCat.ofHom_comp]
        exact (hmap_eq_of_homotopic_aux e.right_inv k).trans (CategoryTheory.Functor.map_id _ _) }
  exact ⟨⟨i⟩, i.toLinearEquiv.finrank_eq⟩

/-- Homotopic maps act the same on holes: if `f` and `g` are joined by a homotopy, then
`f_* = g_*` on homology in every dimension `k`. -/
theorem homologyMap_eq_of_homotopic {X Y : Type} [TopologicalSpace X] [TopologicalSpace Y]
    {f g : C(X, Y)} (h : f.Homotopic g) (k : ℕ) :
    Hmap k f = Hmap k g := by
  exact hmap_eq_of_homotopic_aux h k

/-- A solid ball has the homology of a point: the closed ball of any radius `r ≥ 0` in
`m`-dimensional Euclidean space has, in every dimension `k`, homology isomorphic to that of a
one-point space. -/
theorem homology_closedBall_iso_point (m : ℕ) {r : ℝ} (hr : 0 ≤ r) (k : ℕ) :
    Nonempty (H k (Metric.closedBall (0 : EuclideanSpace ℝ (Fin m)) r) ≅ H k PUnit) := by
  have hne : (Metric.closedBall (0 : EuclideanSpace ℝ (Fin m)) r).Nonempty :=
    ⟨0, Metric.mem_closedBall_self hr⟩
  have := (convex_closedBall (0 : EuclideanSpace ℝ (Fin m)) r).contractibleSpace hne
  obtain ⟨e⟩ := ContractibleSpace.hequiv_unit (Metric.closedBall (0 : EuclideanSpace ℝ (Fin m)) r)
  exact (homology_iso_of_homotopy_equivalent e k).1

/- The card's worked numbers. -/
-- Euler characteristic of the solid 3 × 3 × 3 block: 64 − 279 + 378 − 162 = 1.
example : (64 : ℤ) - 279 + 378 - 162 = 1 := by norm_num
-- Euler characteristic of the mug: 80 − 340 + 440 − 180 = 0.
example : (80 : ℤ) - 340 + 440 - 180 = 0 := by norm_num
-- Euler characteristic of the doughnut: 32 − 112 + 128 − 48 = 0.
example : (32 : ℤ) - 112 + 128 - 48 = 0 := by norm_num
-- Euler characteristic of the dome with 3 panels out: 42 − 120 + 77 = −1.
example : (42 : ℤ) - 120 + 77 = -1 := by norm_num
-- Loops of the collapsed cores, edges − corners + pieces: mug 8 − 8 + 1, doughnut 6 − 6 + 1,
-- dome 8 − 7 + 1.
example : (8 : ℤ) - 8 + 1 = 1 ∧ (6 : ℤ) - 6 + 1 = 1 ∧ (8 : ℤ) - 7 + 1 = 2 := by norm_num
-- Alternating Betti sums match: 1 − 0 + 0 − 0 = 1, 1 − 1 + 0 − 0 = 0, 1 − 2 + 0 = −1.
example : (1 : ℤ) - 0 + 0 - 0 = 1 ∧ (1 : ℤ) - 1 + 0 - 0 = 0 ∧ (1 : ℤ) - 2 + 0 = -1 := by norm_num

#print axioms homology_iso_of_homotopy_equivalent
#print axioms homologyMap_eq_of_homotopic
#print axioms homology_closedBall_iso_point

end HomotopyInvarianceOfHomology
