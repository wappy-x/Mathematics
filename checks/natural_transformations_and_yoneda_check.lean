-- Natural transformations and Yoneda: list reversal is a natural transformation, a natural family out of the arrows into A is fixed by its answer on the identity arrow, and objects with naturally matching arrows coming in are isomorphic.
import Mathlib.CategoryTheory.Yoneda
import Mathlib.CategoryTheory.Types.Basic
import Mathlib.Data.List.Sort
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.Perm

open CategoryTheory Opposite

universe u v

/-- The Yoneda lemma. For a category `C` whose arrows between two objects form a set, an
object `A`, and any functor `F` from `Cᵒᵖ` into sets, natural transformations
`Hom(-, A) ⇒ F` match the members of `F(A)` one for one, by `η ↦ η_A(id_A)`; in the other
direction a member `a` gives the family whose answer on an arrow `x : X → A` is `F(x)(a)`. -/
theorem yoneda_lemma {C : Type u} [Category.{v} C] (A : C) (F : Cᵒᵖ ⥤ Type v) :
    ∃ e : (yoneda.obj A ⟶ F) ≃ F.obj (op A),
      (∀ η : yoneda.obj A ⟶ F, e η = η.app (op A) (𝟙 A)) ∧
      (∀ (a : F.obj (op A)) (X : Cᵒᵖ) (x : X.unop ⟶ A), (e.symm a).app X x = F.map x.op a) := by
  exact ⟨yonedaEquiv, fun η => rfl, fun a X x => rfl⟩

/-- Reversal is natural: reversing a list, one function at every type, is a natural
transformation from the list functor to itself, so for every function `f` the square
"reverse, then map `f`" equals "map `f`, then reverse". -/
theorem list_reverse_is_natural :
    ∃ η : ofTypeFunctor List ⟶ ofTypeFunctor List,
      ∀ (α : Type u) (l : List α), η.app α l = l.reverse := by
  refine ⟨{ app := fun α => ↾(List.reverse (α := α)), naturality := ?_ }, fun α l => rfl⟩
  intro α β f
  ext l
  exact (List.map_reverse (f := f.hom) (l := l)).symm

/-- An object is known by the arrows into it: a natural isomorphism between `Hom(-, A)` and
`Hom(-, B)` comes from an isomorphism `A ≅ B`, acting on each arrow `x` into `A` by composing
with it. -/
theorem iso_of_natural_iso_of_arrows_into {C : Type u} [Category.{v} C] {A B : C}
    (e : yoneda.obj A ≅ yoneda.obj B) :
    ∃ i : A ≅ B, ∀ (X : Cᵒᵖ) (x : X.unop ⟶ A), e.hom.app X x = x ≫ i.hom := by
  refine ⟨Yoneda.fullyFaithful.preimageIso e, fun X x => ?_⟩
  have h := e.hom.naturality_apply x.op (𝟙 A)
  change _ = x ≫ e.hom.app (op A) (𝟙 A)
  simpa using h

-- Reversing the shelf prices in pence.
example : ([250, 199, 1200] : List ℕ).reverse = [1200, 199, 250] := by decide
-- Reversal commutes with "add 1p" on the prices.
example : (([250, 199, 1200] : List ℕ).reverse.map (· + 1)) =
    (([250, 199, 1200] : List ℕ).map (· + 1)).reverse := by decide
-- Sorting fails the square for f = negate (refunds).
example : (([250, 199, 1200] : List ℤ).insertionSort (· ≤ ·)).map (fun x => -x) =
    [-199, -250, -1200] := by decide
example : (([250, 199, 1200] : List ℤ).map (fun x => -x)).insertionSort (· ≤ ·) =
    [-1200, -250, -199] := by decide
-- Sorting passes the one square for f = add 1p.
example : (([250, 199, 1200] : List ℕ).insertionSort (· ≤ ·)).map (· + 1) = [200, 251, 1201] := by
  decide
example : (([250, 199, 1200] : List ℕ).map (· + 1)).insertionSort (· ≤ ·) = [200, 251, 1201] := by
  decide
-- The generic 3-list [0, 1, 2], reversed.
example : ([0, 1, 2] : List ℕ).reverse = [2, 1, 0] := by decide
-- Reading slots 2, 1, 0 of a 3-list reverses it.
example : ([2, 1, 0] : List ℕ).map (fun i => ([7, 8, 9] : List ℕ).getD i 0) =
    ([7, 8, 9] : List ℕ).reverse := by decide
-- Yoneda's counts: 27 recipes 3 → 3, 4 functions 2 → 2, 256 candidate rules on pairs.
example : Fintype.card (Fin 3 → Fin 3) = 27 := by simp
example : Fintype.card (Fin 2 → Fin 2) = 4 := by simp
example : Fintype.card (Fin 4 → Fin 4) = 256 := by simp
-- The group of 6 rearrangements of 3 slots, and the 6 ^ 6 maps searched.
example : Fintype.card (Equiv.Perm (Fin 3)) = 6 := by simp [Fintype.card_perm, Nat.factorial]
example : Fintype.card (Fin 6 → Fin 6) = 46656 := by simp

#print axioms yoneda_lemma
#print axioms list_reverse_is_natural
#print axioms iso_of_natural_iso_of_arrows_into
