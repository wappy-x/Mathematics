-- Cohomology and the cup product in outline: the cup product of two cocycles changes only by a coboundary when either factor is shifted by a coboundary, so its reading on a 2-cycle is fixed; over a field cohomology has the same sizes as homology; and on the card's torus the product reads 1 while on the two circles joined to a sphere it reads 0.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination

open Finset
open scoped Matrix

namespace CupOutline

variable {V R : Type*} [CommRing R]

/-! Cochains on a complex whose joints are `V`. A 0-cochain is a number on each joint, a 1-cochain
a number on each ordered pair `[u, v]` (a strut), a 2-cochain a number on each ordered triple
`[u, v, w]` (a panel). Only the values on the complex's own struts and panels are ever read. -/

/-- The coboundary of a 0-cochain: `δf[u, v] = f(v) - f(u)`. -/
def cobd0 (f : V → R) : V → V → R := fun u v => f v - f u

/-- The coboundary of a 1-cochain: `δh[u, v, w] = h[v, w] - h[u, w] + h[u, v]`. -/
def cobd1 (h : V → V → R) : V × V × V → R := fun t => h t.2.1 t.2.2 - h t.1 t.2.2 + h t.1 t.2.1

/-- The cup product of two 1-cochains: front edge times back edge,
`(α ⌣ β)[u, v, w] = α[u, v] * β[v, w]`. -/
def cup11 (α β : V → V → R) : V × V × V → R := fun t => α t.1 t.2.1 * β t.2.1 t.2.2

/-- The cup product of a 0-cochain with a 1-cochain: `(f ⌣ β)[u, v] = f(u) * β[u, v]`. -/
def cup01 (f : V → R) (β : V → V → R) : V → V → R := fun u v => f u * β u v

/-- The cup product of a 0-cochain with a 2-cochain: `(f ⌣ c)[u, v, w] = f(u) * c[u, v, w]`. -/
def cup02 (f : V → R) (c : V × V × V → R) : V × V × V → R := fun t => f t.1 * c t

/-- The boundary of a 2-chain `T` on the panels `F`: each panel `[u, v, w]` with coefficient
`T [u, v, w]` contributes `[v, w] - [u, w] + [u, v]`. Its value on the strut `[x, y]`. -/
def bdry2 [DecidableEq V] (F : Finset (V × V × V)) (T : V × V × V → R) : V → V → R :=
  fun x y => ∑ t ∈ F, T t * ((if (t.2.1, t.2.2) = (x, y) then 1 else 0)
    - (if (t.1, t.2.2) = (x, y) then 1 else 0) + (if (t.1, t.2.1) = (x, y) then 1 else 0))

/-- The pairing `⟨c, T⟩` of a 2-cochain with a 2-chain on the panels `F`. -/
def pair2 (F : Finset (V × V × V)) (c T : V × V × V → R) : R := ∑ t ∈ F, c t * T t

/-- **The cup product is well defined on classes.** Let `α` and `β` be cocycles on the panels `F`
(zero coboundary on every panel). Shift each by a coboundary, `α + δf` and `β + δg`. Then the
product changes by a coboundary `δh` on every panel, and its reading on any 2-cycle `T`
(a 2-chain with no rim left) does not change. -/
theorem cup_product_well_defined_on_classes [DecidableEq V] (F : Finset (V × V × V))
    (α β : V → V → R) (hα : ∀ t ∈ F, cobd1 α t = 0) (hβ : ∀ t ∈ F, cobd1 β t = 0)
    (f g : V → R) :
    (∃ h : V → V → R, ∀ t ∈ F,
        cup11 (α + cobd0 f) (β + cobd0 g) t - cup11 α β t = cobd1 h t) ∧
      ∀ T : V × V × V → R, (∀ x y, bdry2 F T x y = 0) →
        pair2 F (cup11 (α + cobd0 f) (β + cobd0 g)) T = pair2 F (cup11 α β) T := by
  set h : V → V → R := fun u v => -(α u v * g v) + f u * β u v + f u * (g v - g u) with hdef
  have key : ∀ t ∈ F, cup11 (α + cobd0 f) (β + cobd0 g) t - cup11 α β t = cobd1 h t := by
    intro t ht
    have h1 := hα t ht
    have h2 := hβ t ht
    simp only [cup11, cobd0, cobd1, hdef, Pi.add_apply] at h1 h2 ⊢
    linear_combination (g t.2.2) * h1 - (f t.1) * h2
  refine ⟨⟨h, key⟩, ?_⟩
  intro T hT
  have hdiff : pair2 F (cup11 (α + cobd0 f) (β + cobd0 g)) T - pair2 F (cup11 α β) T
      = ∑ t ∈ F, cobd1 h t * T t := by
    unfold pair2
    rw [← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl (fun t ht => ?_)
    rw [← key t ht]; ring
  set S : Finset (V × V) := F.image (fun t => (t.2.1, t.2.2)) ∪ F.image (fun t => (t.1, t.2.2))
    ∪ F.image (fun t => (t.1, t.2.1)) with hS
  have pick : ∀ e ∈ S, ∑ s ∈ S, h s.1 s.2 * (if e = (s.1, s.2) then (1 : R) else 0) = h e.1 e.2 := by
    intro e he
    rw [Finset.sum_eq_single e]
    · simp
    · intro b _ hb
      have : e ≠ (b.1, b.2) := by simpa using (Ne.symm hb)
      simp [this]
    · intro hn; exact absurd he hn
  have hzero : ∑ s ∈ S, h s.1 s.2 * bdry2 F T s.1 s.2 = 0 := by
    simp [hT]
  have hswap : ∑ s ∈ S, h s.1 s.2 * bdry2 F T s.1 s.2 = ∑ t ∈ F, cobd1 h t * T t := by
    unfold bdry2
    simp_rw [Finset.mul_sum]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl (fun t ht => ?_)
    have e1 : (t.2.1, t.2.2) ∈ S := by
      simp only [hS, Finset.mem_union, Finset.mem_image]; left; left; exact ⟨t, ht, rfl⟩
    have e2 : (t.1, t.2.2) ∈ S := by
      simp only [hS, Finset.mem_union, Finset.mem_image]; left; right; exact ⟨t, ht, rfl⟩
    have e3 : (t.1, t.2.1) ∈ S := by
      simp only [hS, Finset.mem_union, Finset.mem_image]; right; exact ⟨t, ht, rfl⟩
    have := pick _ e1
    have := pick _ e2
    have := pick _ e3
    have expand : ∀ s : V × V, h s.1 s.2 * (T t * ((if (t.2.1, t.2.2) = (s.1, s.2) then (1 : R) else 0)
        - (if (t.1, t.2.2) = (s.1, s.2) then 1 else 0) + (if (t.1, t.2.1) = (s.1, s.2) then 1 else 0)))
        = T t * (h s.1 s.2 * (if (t.2.1, t.2.2) = (s.1, s.2) then (1 : R) else 0)
          - h s.1 s.2 * (if (t.1, t.2.2) = (s.1, s.2) then 1 else 0)
          + h s.1 s.2 * (if (t.1, t.2.1) = (s.1, s.2) then 1 else 0)) := fun s => by ring
    rw [Finset.sum_congr rfl (fun s _ => expand s), ← Finset.mul_sum, Finset.sum_add_distrib,
      Finset.sum_sub_distrib, pick _ e1, pick _ e2, pick _ e3]
    simp only [cobd1]; ring
  rw [← sub_eq_zero, hdiff, ← hswap, hzero]

/-- **Cohomology counts the same holes.** Over a field, let `∂ₖ` and `∂ₖ₊₁` be boundary matrices
with `∂ₖ ∂ₖ₊₁ = 0`. The coboundaries are their transposes. Then the k-th cohomology,
cocycles `ker δᵏ` modulo coboundaries `im δᵏ⁻¹`, has the same dimension as the k-th homology,
cycles `ker ∂ₖ` modulo boundaries `im ∂ₖ₊₁`: the Betti number `βₖ`. -/
theorem cohomology_dim_eq_betti_number {K : Type*} [Field K] {m n p : ℕ}
    (dk : Matrix (Fin m) (Fin n) K) (dk1 : Matrix (Fin n) (Fin p) K) (h : dk * dk1 = 0) :
    Module.finrank K (LinearMap.ker (Matrix.toLin' dk1ᵀ) ⧸
        (LinearMap.range (Matrix.toLin' dkᵀ)).comap (LinearMap.ker (Matrix.toLin' dk1ᵀ)).subtype) =
      Module.finrank K (LinearMap.ker (Matrix.toLin' dk) ⧸
        (LinearMap.range (Matrix.toLin' dk1)).comap (LinearMap.ker (Matrix.toLin' dk)).subtype) := by
  have hT : dk1ᵀ * dkᵀ = 0 := by rw [← Matrix.transpose_mul, h, Matrix.transpose_zero]
  have hle1 : LinearMap.range (Matrix.toLin' dkᵀ) ≤ LinearMap.ker (Matrix.toLin' dk1ᵀ) := by
    rintro _ ⟨x, rfl⟩
    simp [LinearMap.mem_ker, Matrix.toLin'_apply, Matrix.mulVec_mulVec, hT]
  have hle2 : LinearMap.range (Matrix.toLin' dk1) ≤ LinearMap.ker (Matrix.toLin' dk) := by
    rintro _ ⟨x, rfl⟩
    simp [LinearMap.mem_ker, Matrix.toLin'_apply, Matrix.mulVec_mulVec, h]
  have q1 := Submodule.finrank_quotient_add_finrank
    ((LinearMap.range (Matrix.toLin' dkᵀ)).comap (LinearMap.ker (Matrix.toLin' dk1ᵀ)).subtype)
  have q2 := Submodule.finrank_quotient_add_finrank
    ((LinearMap.range (Matrix.toLin' dk1)).comap (LinearMap.ker (Matrix.toLin' dk)).subtype)
  rw [(Submodule.comapSubtypeEquivOfLe hle1).finrank_eq] at q1
  rw [(Submodule.comapSubtypeEquivOfLe hle2).finrank_eq] at q2
  have r1 := LinearMap.finrank_range_add_finrank_ker (Matrix.toLin' dk1ᵀ)
  have r2 := LinearMap.finrank_range_add_finrank_ker (Matrix.toLin' dk)
  have k1 : Module.finrank K (LinearMap.range (Matrix.toLin' dk1ᵀ)) = dk1.rank := by
    rw [← Matrix.rank_transpose dk1]; rfl
  have k2 : Module.finrank K (LinearMap.range (Matrix.toLin' dkᵀ)) = dk.rank := by
    rw [← Matrix.rank_transpose dk]; rfl
  have k3 : Module.finrank K (LinearMap.range (Matrix.toLin' dk1)) = dk1.rank := rfl
  have k4 : Module.finrank K (LinearMap.range (Matrix.toLin' dk)) = dk.rank := rfl
  simp only [Module.finrank_fin_fun] at r1 r2
  omega

/-- **The Leibniz rule** (the card's detailed proof): for a 0-cochain `f` and a 1-cochain `β`,
`δ(f ⌣ β) = δf ⌣ β + f ⌣ δβ` on every panel. -/
theorem leibniz_rule (f : V → R) (β : V → V → R) (t : V × V × V) :
    cobd1 (cup01 f β) t = cup11 (cobd0 f) β t + cup02 f (cobd1 β) t := by
  simp only [cobd1, cup01, cup11, cobd0, cup02]; ring

/-! The torus: a 3 × 3 grid of squares, opposite sides glued, joint `(i, j)` numbered `3i + j`,
each square cut into 2 panels: 9 joints, 27 struts, 18 panels. -/

/-- The 9 panels that enter the top cycle `T` with sign +1. -/
def torusPos : Finset (Fin 9 × Fin 9 × Fin 9) :=
  {(0, 1, 6), (0, 2, 3), (0, 3, 4), (0, 6, 8), (1, 2, 7), (1, 4, 5), (3, 5, 6), (3, 6, 7), (4, 7, 8)}

/-- The 9 panels that enter the top cycle `T` with sign -1. -/
def torusNeg : Finset (Fin 9 × Fin 9 × Fin 9) :=
  {(0, 1, 4), (0, 2, 8), (1, 2, 5), (1, 6, 7), (2, 3, 5), (2, 7, 8), (3, 4, 7), (4, 5, 8), (5, 6, 8)}

/-- All 18 panels of the torus. -/
def torusPanels : Finset (Fin 9 × Fin 9 × Fin 9) := torusPos ∪ torusNeg

/-- The torus's top 2-cycle `T`: every panel with sign ±1. -/
def torusTop : Fin 9 × Fin 9 × Fin 9 → ℤ :=
  fun t => if t ∈ torusPos then 1 else if t ∈ torusNeg then -1 else 0

/-- The seam measurement `a`: -1 on a strut that wraps forward from row block 0 to row block 2
of the joint numbering (`u / 3 + 2 = v / 3`), +1 the other way, else 0. -/
def torusA : Fin 9 → Fin 9 → ℤ :=
  fun u v => if u.val / 3 + 2 = v.val / 3 then -1 else if v.val / 3 + 2 = u.val / 3 then 1 else 0

/-- The seam measurement `b`: the same for the other seam (`u % 3` against `v % 3`). -/
def torusB : Fin 9 → Fin 9 → ℤ :=
  fun u v => if u.val % 3 + 2 = v.val % 3 then -1 else if v.val % 3 + 2 = u.val % 3 then 1 else 0

-- T is a 2-cycle: its boundary is zero on every strut.
example : ∀ x y : Fin 9, bdry2 torusPanels torusTop x y = 0 := by decide

-- a and b are cocycles: zero coboundary on every panel.
example : ∀ t ∈ torusPanels, cobd1 torusA t = 0 ∧ cobd1 torusB t = 0 := by
  intro t ht
  simp only [torusPanels, torusPos, torusNeg, Finset.mem_union, Finset.mem_insert,
    Finset.mem_singleton] at ht
  rcases ht with (rfl|rfl|rfl|rfl|rfl|rfl|rfl|rfl|rfl) | (rfl|rfl|rfl|rfl|rfl|rfl|rfl|rfl|rfl) <;> decide

-- On the loop [0,3] + [3,6] - [0,6] and the loop [0,1] + [1,2] - [0,2], a and b read [[1, 0], [0, 1]].
example : torusA 0 3 + torusA 3 6 - torusA 0 6 = 1 ∧ torusA 0 1 + torusA 1 2 - torusA 0 2 = 0 ∧
    torusB 0 3 + torusB 3 6 - torusB 0 6 = 0 ∧ torusB 0 1 + torusB 1 2 - torusB 0 2 = 1 := by decide

-- a ⌣ b is nonzero on one panel only, 068, where it reads (-1) × (-1) = 1.
example : ∀ t ∈ torusPanels, cup11 torusA torusB t = if t = (0, 6, 8) then 1 else 0 := by
  intro t ht
  simp only [torusPanels, torusPos, torusNeg, Finset.mem_union, Finset.mem_insert,
    Finset.mem_singleton] at ht
  rcases ht with (rfl|rfl|rfl|rfl|rfl|rfl|rfl|rfl|rfl) | (rfl|rfl|rfl|rfl|rfl|rfl|rfl|rfl|rfl) <;> decide

-- The product table on T is [[0, 1], [-1, 0]].
example : pair2 torusPanels (cup11 torusA torusA) torusTop = 0 ∧
    pair2 torusPanels (cup11 torusA torusB) torusTop = 1 ∧
    pair2 torusPanels (cup11 torusB torusA) torusTop = -1 ∧
    pair2 torusPanels (cup11 torusB torusB) torusTop = 0 := by decide

-- Its determinant is 0 × 0 - 1 × (-1) = 1.
example : (0 : ℤ) * 0 - 1 * (-1) = 1 := by decide

-- What breaks: b plus 1 on strut [1,4] is not a cocycle, and shifting a by the coboundary of
-- "1 at joint 1" moves the reading on T from 1 to 0.
example : (∃ t ∈ torusPanels, cobd1 (fun u v => torusB u v + if (u, v) = (1, 4) then 1 else 0) t ≠ 0) ∧
    pair2 torusPanels (cup11 torusA (fun u v => torusB u v + if (u, v) = (1, 4) then 1 else 0))
      torusTop = 1 ∧
    pair2 torusPanels (cup11 (torusA + cobd0 (fun u => if u = 1 then 1 else 0))
      (fun u v => torusB u v + if (u, v) = (1, 4) then 1 else 0)) torusTop = 0 := by decide

/-! Two circles and a sphere joined at joint 0: hoops 0-1-2 and 0-3-4, and the surface of the
tetrahedron 0, 5, 6, 7. 8 joints, 12 struts, 4 panels. -/

/-- The 4 panels of the sphere. -/
def wedgePanels : Finset (Fin 8 × Fin 8 × Fin 8) := {(0, 5, 6), (0, 5, 7), (0, 6, 7), (5, 6, 7)}

/-- The sphere's top 2-cycle `S`. -/
def wedgeTop : Fin 8 × Fin 8 × Fin 8 → ℤ := fun t =>
  if t = (5, 6, 7) ∨ t = (0, 5, 7) then 1 else if t = (0, 6, 7) ∨ t = (0, 5, 6) then -1 else 0

/-- `c₁`: 1 on strut [1,2], one strut of the first hoop. -/
def wedgeC1 : Fin 8 → Fin 8 → ℤ := fun u v => if (u, v) = (1, 2) then 1 else 0

/-- `c₂`: 1 on strut [3,4], one strut of the second hoop. -/
def wedgeC2 : Fin 8 → Fin 8 → ℤ := fun u v => if (u, v) = (3, 4) then 1 else 0

-- S is a 2-cycle, and c₁, c₂ are cocycles.
example : (∀ x y : Fin 8, bdry2 wedgePanels wedgeTop x y = 0) ∧
    ∀ t ∈ wedgePanels, cobd1 wedgeC1 t = 0 ∧ cobd1 wedgeC2 t = 0 := by
  refine ⟨by decide, ?_⟩
  intro t ht
  simp only [wedgePanels, Finset.mem_insert, Finset.mem_singleton] at ht
  rcases ht with rfl | rfl | rfl | rfl <;> decide

-- Every product of c₁ and c₂ is the zero cochain, so the table on S is [[0, 0], [0, 0]], determinant 0.
example : ∀ t ∈ wedgePanels, cup11 wedgeC1 wedgeC1 t = 0 ∧ cup11 wedgeC1 wedgeC2 t = 0 ∧
    cup11 wedgeC2 wedgeC1 t = 0 ∧ cup11 wedgeC2 wedgeC2 t = 0 := by
  intro t ht
  simp only [wedgePanels, Finset.mem_insert, Finset.mem_singleton] at ht
  rcases ht with rfl | rfl | rfl | rfl <;> decide

-- Shifted copies c₁' = c₁ + δ(1 at joint 5), c₂' = c₂ + δ(1 at joint 6): the product reads
-- [1, 0, 0, 1] on the panels 056, 057, 067, 567, yet 0 on S.
example :
    let c1' := wedgeC1 + cobd0 (fun u => if u = 5 then 1 else 0)
    let c2' := wedgeC2 + cobd0 (fun u => if u = 6 then 1 else 0)
    cup11 c1' c2' (0, 5, 6) = 1 ∧ cup11 c1' c2' (0, 5, 7) = 0 ∧ cup11 c1' c2' (0, 6, 7) = 0 ∧
      cup11 c1' c2' (5, 6, 7) = 1 ∧ pair2 wedgePanels (cup11 c1' c2') wedgeTop = 0 := by decide

-- Künneth over a field: the circle's Poincaré polynomial is 1 + t; the torus's is (1 + t)² = 1 + 2t + t²,
-- and three circles give 1, 3, 3, 1.
open Polynomial in
example : ((1 + X : ℤ[X]) * (1 + X) = 1 + 2 * X + X ^ 2) ∧
    ((1 + X : ℤ[X]) ^ 3 = 1 + 3 * X + 3 * X ^ 2 + X ^ 3) := by constructor <;> ring

#print axioms cup_product_well_defined_on_classes
#print axioms cohomology_dim_eq_betti_number
#print axioms leibniz_rule

end CupOutline
