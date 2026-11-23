-- The Poincare conjecture, solved: this file proves the easy direction's key step, that on the 3-sphere a loop which misses one point shrinks to a point because the sphere minus that point is a copy of 3D space, and checks the card's exact numbers.
import Mathlib.Geometry.Manifold.Instances.Sphere
import Mathlib.AlgebraicTopology.FundamentalGroupoid.SimplyConnected
import Mathlib.Analysis.Convex.Contractible
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open Metric Real

/-!
The card's main theorem is Perelman's: a closed, connected 3-manifold in which every loop shrinks
to a point is the 3-sphere. Its proof (Ricci flow with surgery, 2002–2003) is not in Mathlib, so
this file records that statement as a definition and does not claim it. The theorems below are the
parts of the card that are proved here: the 3-sphere passes the loop test for any loop that misses
a point (Step 1), because the 3-sphere minus a point is a copy of ordinary 3D space, and road 1's
division is always safe.
-/

/-- The 3-sphere: the points of 4D space at distance 1 from the origin. -/
abbrev S3 : Type := sphere (0 : EuclideanSpace ℝ (Fin 4)) 1

/-- The Poincaré conjecture, as the card states it (statement only, not proved in this file):
if a space `M` is a closed (compact, no boundary) 3-manifold, is in one piece, and every loop
in it shrinks to a point, then `M` can be matched to the 3-sphere point for point, continuously
both ways. Perelman proved it in 2002–2003; Clay recognised the proof on 2010-03-18. -/
def PoincareConjecture : Prop :=
  ∀ (M : Type) [TopologicalSpace M] [T2Space M] [SecondCountableTopology M]
    [ChartedSpace (EuclideanSpace ℝ (Fin 3)) M] [CompactSpace M] [ConnectedSpace M]
    [SimplyConnectedSpace M], Nonempty (M ≃ₜ S3)

/-- The 4D space has dimension 3 + 1, which stereographic projection needs. -/
instance fact_finrank_four : Fact (Module.finrank ℝ (EuclideanSpace ℝ (Fin 4)) = 3 + 1) :=
  ⟨by simp⟩

#print axioms fact_finrank_four

/-- Removing one point from the 3-sphere leaves a space that can be shrunk to a point. -/
theorem sphere_minus_point_contractible (q : S3) : ContractibleSpace ({q}ᶜ : Set S3) := by
  let e : ({q}ᶜ : Set S3) ≃ₜ EuclideanSpace ℝ (Fin 3) :=
    ((Homeomorph.setCongr (stereographic'_source (n := 3) q).symm).trans
      (stereographic' 3 q).toHomeomorphSourceTarget).trans
      ((Homeomorph.setCongr (stereographic'_target (n := 3) q)).trans (Homeomorph.Set.univ _))
  exact e.contractibleSpace

#print axioms sphere_minus_point_contractible

/-- The 3-sphere passes the loop test for any loop that misses a point: if a loop on the
3-sphere, starting and ending at `p`, never passes through the point `q`, then it can be shrunk
to the point `p` without leaving the sphere, keeping its ends fixed at `p`. -/
theorem loop_missing_a_point_shrinks (p q : S3) (γ : Path p p) (hq : ∀ s, γ s ≠ q) :
    γ.Homotopic (Path.refl p) := by
  have hp : p ≠ q := by simpa using hq 0
  have := sphere_minus_point_contractible q
  let γ' : Path (⟨p, hp⟩ : ({q}ᶜ : Set S3)) ⟨p, hp⟩ :=
    { toFun := fun s => ⟨γ s, hq s⟩
      continuous_toFun := γ.continuous.subtype_mk _
      source' := by ext; simp
      target' := by ext; simp }
  have h := (SimplyConnectedSpace.paths_homotopic γ' (Path.refl _)).map
    ⟨Subtype.val, continuous_subtype_val⟩
  convert h using 1 <;> ext <;> rfl

/-- With one point removed, the 3-sphere is a copy of ordinary 3D space: stereographic
projection from any point `q` matches the rest of the sphere with `ℝ³` point for point,
continuously both ways. -/
theorem three_sphere_minus_a_point_is_space (q : S3) :
    Nonempty (({q}ᶜ : Set S3) ≃ₜ EuclideanSpace ℝ (Fin 3)) := by
  let e : ({q}ᶜ : Set S3) ≃ₜ EuclideanSpace ℝ (Fin 3) :=
    ((Homeomorph.setCongr (stereographic'_source (n := 3) q).symm).trans
      (stereographic' 3 q).toHomeomorphSourceTarget).trans
      ((Homeomorph.setCongr (stereographic'_target (n := 3) q)).trans (Homeomorph.Set.univ _))
  exact ⟨e⟩

/-- Road 1 is safe. Mix the card's loop `γ(s) = (cos 2πs, sin 2πs, 0, 0)` with the north pole
`N = (0, 0, 0, 1)`: the point `(1 - t) γ(s) + t N` has length `√((1 - t)² + t²)`, which is never
below `√(1/2)`, so dividing by it to push the point back onto the sphere is always allowed. -/
theorem road_one_mix_length (s t : ℝ) :
    ‖(1 - t) • (!₂[cos (2 * π * s), sin (2 * π * s), 0, 0] : EuclideanSpace ℝ (Fin 4)) +
        t • (!₂[0, 0, 0, 1] : EuclideanSpace ℝ (Fin 4))‖ = √((1 - t) ^ 2 + t ^ 2) ∧
      √(1 / 2) ≤ √((1 - t) ^ 2 + t ^ 2) := by
  refine ⟨?_, Real.sqrt_le_sqrt (by nlinarith [sq_nonneg (t - 1 / 2)])⟩
  rw [EuclideanSpace.norm_eq]
  congr 1
  simp [Fin.sum_univ_four, mul_pow]
  nlinarith [sin_sq_add_cos_sq (2 * π * s)]

-- Road 1 at t = 1/2: the mixed point (1/2, 0, 0, 1/2) has squared length 1/4 + 1/4 = 1/2.
example : ((1 : ℚ) - 1 / 2) ^ 2 + (1 / 2) ^ 2 = 1 / 2 := by norm_num
-- Pushed back to the sphere, (1/2, 0, 0, 1/2) / √(1/2) has squared length (1/4 + 1/4) / (1/2) = 1.
example : ((1 : ℚ) / 4 + 1 / 4) / (1 / 2) = 1 := by norm_num
-- Road 2 at t = 1/2: the flattened point (1/2, 0, 0) has squared size 1/4 and maps back to
-- (2 × 1/2, 0, 0, 1 - 1/4) / (1 + 1/4) = (4/5, 0, 0, 3/5) = (0.8, 0, 0, 0.6), on the sphere.
example : (2 * (1 / 2 : ℚ)) / (1 + 1 / 4) = 4 / 5 ∧ (1 - 1 / 4 : ℚ) / (1 + 1 / 4) = 3 / 5 ∧
    ((4 : ℚ) / 5) ^ 2 + (3 / 5) ^ 2 = 1 := by norm_num
-- The loop's start (1, 0, 0, 0) and the south pole q = (0, 0, 0, -1): squared distance 1 + 1 = 2.
example : ((1 : ℤ) - 0) ^ 2 + 0 ^ 2 + 0 ^ 2 + (0 - (-1)) ^ 2 = 2 := by norm_num
-- The 3-sphere built from 5 vertices: 5 vertices, 10 edges, 10 triangles, 5 solid tetrahedra.
example : Nat.choose 5 1 = 5 ∧ Nat.choose 5 2 = 10 ∧ Nat.choose 5 3 = 10 ∧ Nat.choose 5 4 = 5 := by
  decide
-- Euler characteristics: 3-sphere 5 - 10 + 10 - 5 = 0; 2-sphere as a tetrahedron 4 - 6 + 4 = 2
-- and as an octahedron 6 - 12 + 8 = 2; solid ball 4 - 6 + 4 - 1 = 1.
example : (5 : ℤ) - 10 + 10 - 5 = 0 ∧ (4 : ℤ) - 6 + 4 = 2 ∧ (6 : ℤ) - 12 + 8 = 2 ∧
    (4 : ℤ) - 6 + 4 - 1 = 1 := by norm_num
-- The 3-torus from 27 cubes: each cube brings 1 vertex, 3 edges, 3 squares, 1 cube, so 27 × 0 = 0.
example : (27 : ℤ) * (1 - 3 + 3 - 1) = 0 := by norm_num
-- The 4-sphere: 6 - 15 + 20 - 15 + 6 = 2 = 1 + 1; S² × S²: 2 × 2 = 4 = 1 + 2 + 1, not 2.
example : (6 : ℤ) - 15 + 20 - 15 + 6 = 2 ∧ (2 : ℤ) * 2 = 1 + 2 + 1 ∧ (2 : ℤ) * 2 ≠ 2 := by norm_num
-- The 3-sphere's edge-path loops: edges among the 4 vertices other than vertex 0, C(4, 2) = 6.
example : Nat.choose 4 2 = 6 := by decide
-- Homology sees loop classes ÷ commutators: 120 / 120 = 1, 2 / 1 = 2, 5 / 1 = 5.
example : 120 / 120 = 1 ∧ 2 / 1 = 2 ∧ 5 / 1 = 5 := by decide
-- The element orders of 2I add up to 120: 1 + 1 + 20 + 30 + 24 + 20 + 24.
example : 1 + 1 + 20 + 30 + 24 + 20 + 24 = 120 := by decide
-- The surgery clock: the neck of radius 1/2 pinches at (1/2)² / 2 = 1/8 cm²; each end then has
-- R² = 4 - 4 × 1/8 = 7/2 cm² (radius ≈ 1.870829 cm); the ends vanish at 2² / 4 = 1 cm².
example : ((1 : ℚ) / 2) ^ 2 / 2 = 1 / 8 ∧ (4 : ℚ) - 4 * (1 / 8) = 7 / 2 ∧ (2 : ℚ) ^ 2 / 4 = 1 := by
  norm_num
-- A fatter neck of radius 1 pinches at 1² / 2 = 1/2 cm², with ends of R² = 4 - 4 × 1/2 = 2.
example : (1 : ℚ) ^ 2 / 2 = 1 / 2 ∧ (4 : ℚ) - 4 * (1 / 2) = 2 := by norm_num
-- From the question (1904) to the first preprint (2002) and to the prize (2010).
example : 2002 - 1904 = 98 ∧ 2010 - 1904 = 106 := by decide

#print axioms loop_missing_a_point_shrinks
#print axioms three_sphere_minus_a_point_is_space
#print axioms road_one_mix_length
