-- Adjunctions: the free group is left adjoint to forgetting the group, so homomorphisms out of a free group match choices of where its letters go; multiplying by 3 and dividing by 3 rounded down form a Galois connection; and every right adjoint keeps limits.
import Mathlib.Algebra.Category.Grp.Adjunctions
import Mathlib.CategoryTheory.Adjunction.Limits
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.Order.GaloisConnection.Defs
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Int.Interval

open CategoryTheory CategoryTheory.Limits DihedralGroup

universe u v w u₁ v₁ u₂ v₂

/-- Free against forget. The free group functor `F : Set → Grp` is left adjoint to the
forgetful functor `U : Grp → Set`, `F ⊣ U`: there is an adjunction, a one-for-one match
`Hom_Grp(F S, H) ≅ Hom_Set(S, U H)` natural in the set `S` and the group `H`, under which a
homomorphism `φ` out of the free group on `S` matches the choice sending each letter `s` to
`φ` of the one-letter word `s`, and whose unit puts each letter in as its one-letter word. -/
theorem free_group_left_adjoint_to_forget :
    ∃ adj : GrpCat.free.{u} ⊣ forget GrpCat.{u},
      (∀ (S : Type u) (H : GrpCat.{u}) (φ : GrpCat.free.obj S ⟶ H) (s : S),
        adj.homEquiv S H φ s = φ (FreeGroup.of s)) ∧
      (∀ (S : Type u) (s : S), adj.unit.app S s = FreeGroup.of s) := by
  refine ⟨GrpCat.adj, fun S H φ s => rfl, fun S s => rfl⟩

/-- The Galois connection on whole numbers: `x` packs of 3 boxes fit in `y` boxes of space
exactly when `x` is at most `y / 3` rounded down, that is `3x ≤ y ↔ x ≤ ⌊y/3⌋` for all
integers `x`, `y`, so multiplying by 3 is left adjoint to dividing by 3 rounded down. -/
theorem times_three_galois_floor_div_three :
    GaloisConnection (fun x : ℤ => 3 * x) (fun y : ℤ => Int.fdiv y 3) := by
  intro x y
  show 3 * x ≤ y ↔ x ≤ Int.fdiv y 3
  rw [Int.fdiv_eq_ediv_of_nonneg _ (by norm_num : (0:ℤ) ≤ 3)]
  omega

/-- Right adjoints keep limits: if `F ⊣ G`, then `G` sends every limit, of any shape, to a
limit. -/
theorem right_adjoint_preserves_limits {C : Type u₁} [Category.{v₁} C] {D : Type u₂}
    [Category.{v₂} D] {F : C ⥤ D} {G : D ⥤ C} (adj : F ⊣ G) :
    PreservesLimitsOfSize.{v, w} G := by
  exact adj.rightAdjoint_preservesLimits

-- The tile group: the 8 moves of a square tile, quarter turn r = `r 1`, flip f = `sr 0`.
example : Fintype.card (DihedralGroup 4) = 8 := by simp [DihedralGroup.card]
-- Choices of where the letters a, b go: 8 × 8 = 64.
example : Fintype.card (Fin 2 → DihedralGroup 4) = 64 := by simp [DihedralGroup.card]
-- With a ↦ r, b ↦ f, extending to the free group: the word aab multiplies out to r2f.
example : FreeGroup.lift (fun x : Fin 2 => if x = 0 then r (1 : ZMod 4) else sr 0)
    (FreeGroup.of 0 * FreeGroup.of 0 * FreeGroup.of 1) = r 2 * sr 0 := by
  simp only [map_mul, FreeGroup.lift_apply_of]; decide
-- The same choice sends abAB to the half turn r2, so r and f do not commute.
example : FreeGroup.lift (fun x : Fin 2 => if x = 0 then r (1 : ZMod 4) else sr 0)
    (FreeGroup.of 0 * FreeGroup.of 1 * (FreeGroup.of 0)⁻¹ * (FreeGroup.of 1)⁻¹) = r 2 := by
  simp only [map_mul, map_inv, FreeGroup.lift_apply_of]; decide
-- Moving the problem across: 40 of the 64 pairs of tile moves commute.
example : (Finset.univ.filter
    (fun p : DihedralGroup 4 × DihedralGroup 4 => p.1 * p.2 = p.2 * p.1)).card = 40 := by
  decide
-- The second road: 5 conjugacy classes, and 8 × 5 = 40.
example : (Finset.univ.image (fun x : DihedralGroup 4 =>
    Finset.univ.image (fun g : DihedralGroup 4 => g * x * g⁻¹))).card = 5 := by decide
example : 8 * 5 = 40 := by norm_num
-- Order 3 is not free: of the 8 places to send g, only e satisfies g ^ 3 = e.
example : (Finset.univ.filter (fun g : DihedralGroup 4 => g ^ 3 = 1)).card = 1 := by decide
-- Sides swapped: 2 ^ 8 = 256 functions from the tile's moves to the letters a, b.
example : Fintype.card (DihedralGroup 4 → Fin 2) = 256 := by simp [DihedralGroup.card]
-- Reduced words of lengths 1 to 4: 4, 12, 36, 108; with the empty word, 53 up to length 3.
example : (List.range 4).map (fun n => 4 * 3 ^ n) = [4, 12, 36, 108] := by decide
example : 1 + 4 + 12 + 36 = 53 := by norm_num
-- A van of 20 boxes takes 6 packs of 3; rounding to the nearest gives 7 packs, needing 21.
example : Int.fdiv 20 3 = 6 := by decide
example : 3 * 7 = 21 ∧ ¬ (21 ≤ 20) := by decide
-- Rounding instead of rounding down breaks "exactly when" on 20 of the 3,721 grid pairs.
example : ((Finset.Icc (-30 : ℤ) 30 ×ˢ Finset.Icc (-30 : ℤ) 30).filter
    (fun p => (3 * p.1 ≤ p.2) ≠ (p.1 ≤ Int.fdiv (p.2 + 1) 3))).card = 20 := by decide +kernel
example : 61 * 61 = 3721 := by norm_num

#print axioms free_group_left_adjoint_to_forget
#print axioms times_three_galois_floor_div_three
#print axioms right_adjoint_preserves_limits
