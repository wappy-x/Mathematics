-- Equivalence of categories: a functor has a functor back with both round trips naturally isomorphic to the identity exactly when it is full, faithful and essentially surjective.
import Mathlib.CategoryTheory.Equivalence
import Mathlib.CategoryTheory.Skeletal
import Mathlib.CategoryTheory.IsoCat
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.ZMod.Defs

open CategoryTheory Matrix

universe v₁ v₂ u₁ u₂

/-- The test for an equivalence: a functor `F : C ⥤ D` has a functor `G` back with natural
isomorphisms `η : id ≅ G F` and `ε : F G ≅ id` exactly when `F` is full (every arrow
`F A ⟶ F B` is `F f` for some `f`), faithful (different arrows give different images) and
essentially surjective (every object of `D` is isomorphic to some `F A`). -/
theorem equivalence_iff_full_faithful_essSurj {C : Type u₁} [Category.{v₁} C]
    {D : Type u₂} [Category.{v₂} D] (F : C ⥤ D) :
    (∃ G : D ⥤ C, Nonempty (𝟭 C ≅ F ⋙ G) ∧ Nonempty (G ⋙ F ≅ 𝟭 D)) ↔
      F.Full ∧ F.Faithful ∧ F.EssSurj := by
  constructor
  · rintro ⟨G, ⟨η⟩, ⟨ε⟩⟩
    have h := Functor.IsEquivalence.mk' G η ε
    exact ⟨h.full, h.faithful, h.essSurj⟩
  · rintro ⟨h1, h2, h3⟩
    have : F.IsEquivalence := { faithful := h2, full := h1, essSurj := h3 }
    exact ⟨F.inv, ⟨F.asEquivalence.unitIso⟩, ⟨F.asEquivalence.counitIso⟩⟩

/-- Skeletons: two categories are equivalent exactly when their skeletons (one object from
each isomorphism class, with every arrow between them) are isomorphic as categories, with
both round trips equal to the identity. -/
theorem equivalent_iff_skeletons_isomorphic {C : Type u₁} [Category.{v₁} C]
    {D : Type u₂} [Category.{v₂} D] :
    Nonempty (C ≌ D) ↔ Nonempty (IsoCat (Skeleton C) (Skeleton D)) := by
  constructor
  · rintro ⟨e⟩
    exact ⟨e.skeletonIsoCat⟩
  · rintro ⟨i⟩
    exact ⟨((skeletonEquivalence C).symm.trans i.toEquivalence).trans (skeletonEquivalence D)⟩

/-- Every equivalence can be made an adjoint equivalence: given natural isomorphisms
`η : id ≅ G F` and `ε : F G ≅ id`, the unit can be replaced by another natural isomorphism
`η'` so that both triangle identities of an adjunction hold. -/
theorem exists_adjoint_equivalence {C : Type u₁} [Category.{v₁} C]
    {D : Type u₂} [Category.{v₂} D] (F : C ⥤ D) (G : D ⥤ C)
    (η : 𝟭 C ≅ F ⋙ G) (ε : G ⋙ F ≅ 𝟭 D) :
    ∃ η' : 𝟭 C ≅ F ⋙ G,
      (∀ X : C, F.map (η'.hom.app X) ≫ ε.hom.app (F.obj X) = 𝟙 (F.obj X)) ∧
      (∀ Y : D, η'.hom.app (G.obj Y) ≫ G.map (ε.hom.app Y) = 𝟙 (G.obj Y)) := by
  refine ⟨(CategoryTheory.Equivalence.mk F G η ε).unitIso, fun X => ?_, fun Y => ?_⟩
  · exact (CategoryTheory.Equivalence.mk F G η ε).functor_unit_comp X
  · exact (CategoryTheory.Equivalence.mk F G η ε).unit_inverse_comp Y

/-! The card's worked numbers. -/

-- The derivative of 3 + 5t + 4t^2: the matrix D = [[0, 1, 0], [0, 0, 2]] takes (3, 5, 4) to (5, 8).
example : (!![0, 1, 0; 0, 0, 2] : Matrix (Fin 2) (Fin 3) ℤ) *ᵥ ![3, 5, 4] = ![5, 8] := by
  decide

-- Value at t = 2 after the derivative: E D = [[1, 2]] [[0, 1, 0], [0, 0, 2]] = [[0, 1, 4]].
example : (!![1, 2] : Matrix (Fin 1) (Fin 2) ℤ) * (!![0, 1, 0; 0, 0, 2] : Matrix (Fin 2) (Fin 3) ℤ) =
    !![0, 1, 4] := by
  decide

-- ... which takes (3, 5, 4) to 21.
example : (!![0, 1, 4] : Matrix (Fin 1) (Fin 3) ℤ) *ᵥ ![3, 5, 4] = ![21] := by
  decide

-- The same by central difference: (p(3) - p(1)) / 2 = (54 - 12) / 2 = 21.
example : ((3 + 5 * 3 + 4 * 3 ^ 2) - (3 + 5 * 1 + 4 * 1 ^ 2)) / 2 = (21 : ℤ) := by
  norm_num

-- The mistake: (5, 8) read in the basis 1 + t, 1 - t is 13 - 3t.
example : (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![5, 8] = ![13, -3] := by
  decide

-- Arrows 2 -> 2 over F2: 16 matrices, 6 of them invertible.
example : Fintype.card (Matrix (Fin 2) (Fin 2) (ZMod 2)) = 16 := by
  decide

example : (Finset.univ.filter
    (fun M : Matrix (Fin 2) (Fin 2) (ZMod 2) => M 0 0 * M 1 1 - M 0 1 * M 1 0 ≠ 0)).card = 6 := by
  decide

-- Arrows among the objects 0, 1, 2 over F2: 2^(m n) matrices n -> m, 31 in all.
example : ∑ n ∈ Finset.range 3, ∑ m ∈ Finset.range 3, 2 ^ (m * n) = 31 := by
  decide

-- 7 planes inside F2^3: subsets of 4 vectors containing 0 and closed under addition.
example : ((Finset.univ : Finset (Fin 3 → ZMod 2)).powersetCard 4 |>.filter
    (fun s => (0 : Fin 3 → ZMod 2) ∈ s ∧ ∀ x ∈ s, ∀ y ∈ s, x + y ∈ s)).card = 7 := by
  decide

-- The same count by formula: (8 - 1)(8 - 2) / ((4 - 1)(4 - 2)) = 7.
example : (8 - 1) * (8 - 2) / ((4 - 1) * (4 - 2)) = 7 := by
  norm_num

-- Skeleton of finite sets: 6 two-member subsets of {0, 1, 2, 3}; 3^2 = 9 functions 2 -> 3.
example : ((Finset.univ : Finset (Fin 4)).powersetCard 2).card = 6 := by
  decide

example : Fintype.card (Fin 2 → Fin 3) = 9 := by
  decide

#print axioms equivalence_iff_full_faithful_essSurj
#print axioms equivalent_iff_skeletons_isomorphic
#print axioms exists_adjoint_equivalence
