-- Monoidal categories: in every monoidal category side by side respects "in turn" (the interchange law), so boxes on different wires slide past each other, and in a symmetric one boxes pass through a crossing and two crossings cancel.
import Mathlib.CategoryTheory.Monoidal.Category
import Mathlib.CategoryTheory.Monoidal.Braided.Basic
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Sum
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.NormNum.Basic

open CategoryTheory MonoidalCategory

/-- The interchange law. In any monoidal category, two stages of side-by-side boxes equal two
lanes of in-turn boxes set side by side: for arrows f : X₁ → Y₁, f' : Y₁ → Z₁ on one wire and
g : X₂ → Y₂, g' : Y₂ → Z₂ on the other, (f' ⊗ g') ∘ (f ⊗ g) = (f' ∘ f) ⊗ (g' ∘ g).
Lean writes `f ≫ f'` for "f first, then f'", the card's f' ∘ f, and `⊗ₘ` for ⊗ on arrows. -/
theorem interchange_law {C : Type*} [Category C] [MonoidalCategory C]
    {X₁ Y₁ Z₁ X₂ Y₂ Z₂ : C} (f : X₁ ⟶ Y₁) (f' : Y₁ ⟶ Z₁) (g : X₂ ⟶ Y₂) (g' : Y₂ ⟶ Z₂) :
    (f ⊗ₘ g) ≫ (f' ⊗ₘ g') = (f ≫ f') ⊗ₘ (g ≫ g') := by
  exact MonoidalCategory.tensorHom_comp_tensorHom f g f' g'

/-- Boxes on different wires slide past each other. In any monoidal category, for
f : X₁ → Y₁ on one wire and g : X₂ → Y₂ on the other,
f ⊗ g = (f ⊗ id) ∘ (id ⊗ g) = (id ⊗ g) ∘ (f ⊗ id): either box may run first. -/
theorem boxes_slide_past_each_other {C : Type*} [Category C] [MonoidalCategory C]
    {X₁ Y₁ X₂ Y₂ : C} (f : X₁ ⟶ Y₁) (g : X₂ ⟶ Y₂) :
    f ⊗ₘ g = (𝟙 X₁ ⊗ₘ g) ≫ (f ⊗ₘ 𝟙 Y₂) ∧
      f ⊗ₘ g = (f ⊗ₘ 𝟙 X₂) ≫ (𝟙 Y₁ ⊗ₘ g) := by
  constructor
  · rw [MonoidalCategory.tensorHom_comp_tensorHom, Category.id_comp, Category.comp_id]
  · rw [MonoidalCategory.tensorHom_comp_tensorHom, Category.id_comp, Category.comp_id]

/-- Crossings in a symmetric monoidal category. Boxes pass through a crossing,
σ ∘ (f ⊗ g) = (g ⊗ f) ∘ σ, and two crossings cancel, σ_{B,A} ∘ σ_{A,B} = id.
Lean writes the swap σ_{A,B} as `(β_ A B).hom`. -/
theorem crossings_in_symmetric_category {C : Type*} [Category C] [MonoidalCategory C]
    [SymmetricCategory C] {X₁ Y₁ X₂ Y₂ : C} (f : X₁ ⟶ Y₁) (g : X₂ ⟶ Y₂) :
    (f ⊗ₘ g) ≫ (β_ Y₁ Y₂).hom = (β_ X₁ X₂).hom ≫ (g ⊗ₘ f) ∧
      (β_ X₁ X₂).hom ≫ (β_ X₂ X₁).hom = 𝟙 (X₁ ⊗ X₂) := by
  exact ⟨BraidedCategory.braiding_naturality f g, SymmetricCategory.symmetry X₁ X₂⟩

-- The depot, in sets: box adds 150 g, wrap adds 50 g, price is 300 p plus 1 p per 10 g.
-- Side by side on sets sends (a, b) to (f a, g b), which is `Prod.map f g`.
-- Stage 1: (1,200, 800) becomes (1,350, 850).
example : Prod.map (fun w : ℕ => w + 150) (fun w : ℕ => w + 50) (1200, 800) = (1350, 850) := by
  decide
-- Stage by stage, lane by lane, and wrap slid before box all give the bills (435, 385).
example : Prod.map (fun w : ℕ => 300 + w / 10) (fun w : ℕ => 300 + w / 10)
    (Prod.map (fun w : ℕ => w + 150) (fun w : ℕ => w + 50) (1200, 800)) = (435, 385) := by
  decide
example : ((fun w : ℕ => 300 + w / 10) ((fun w : ℕ => w + 150) 1200),
    (fun w : ℕ => 300 + w / 10) ((fun w : ℕ => w + 50) 800)) = (435, 385) := by
  decide
example : Prod.map (fun w : ℕ => 300 + w / 10) (fun w : ℕ => 300 + w / 10)
    (Prod.map (fun w : ℕ => w + 150) id (Prod.map id (fun w : ℕ => w + 50) (1200, 800))) =
    (435, 385) := by
  decide
-- Merging the two wires: 435 + 385 = 820 p. Pricing before boxing reads 1,200 g: 420 p.
example : 435 + 385 = 820 := by norm_num
example : 300 + 1200 / 10 = 420 := by norm_num
-- Every function on {0, 1}: interchange and sliding hold on all 256 quadruples and 4 inputs,
-- and boxes pass the swap on every pair of functions.
example : ∀ f g h k : Fin 2 → Fin 2, ∀ p : Fin 2 × Fin 2,
    Prod.map h k (Prod.map f g p) = Prod.map (h ∘ f) (k ∘ g) p := by
  decide
example : ∀ f g : Fin 2 → Fin 2, ∀ p : Fin 2 × Fin 2,
    Prod.map f id (Prod.map id g p) = Prod.map id g (Prod.map f id p) := by
  decide
example : ∀ f g : Fin 2 → Fin 2, ∀ p : Fin 2 × Fin 2,
    (Prod.map f g p).swap = Prod.map g f p.swap ∧ p.swap.swap = p := by
  decide
-- Pentagon in sets: the two re-bracketings of ((a, b), c), d agree on all 16 members.
-- Two moves along the top: α then α. Three along the bottom: α ⊗ id, then α, then id ⊗ α.
example : ∀ x : ((Fin 2 × Fin 2) × Fin 2) × Fin 2,
    Equiv.prodAssoc _ _ _ (Equiv.prodAssoc _ _ _ x) =
      Prod.map id (Equiv.prodAssoc _ _ _)
        (Equiv.prodAssoc _ _ _ (Prod.map (Equiv.prodAssoc _ _ _) id x)) := by
  decide
-- Coordinates: R^2 tensor R^3 has 2 · 3 = 6, the direct sum 2 + 3 = 5.
example : Fintype.card (Fin 2 × Fin 3) = 6 ∧ Fintype.card (Fin 2 ⊕ Fin 3) = 5 := by decide
-- (1, 0, 0, 1) has ad - bc = 1, and no pair of vectors with entries -3 to 3 makes it.
example : (1 : ℤ) * 1 - 0 * 0 = 1 := by norm_num
example : ∀ u₀ u₁ w₀ w₁ : Fin 7,
    ¬ (((u₀ : ℤ) - 3) * ((w₀ : ℤ) - 3) = 1 ∧ ((u₀ : ℤ) - 3) * ((w₁ : ℤ) - 3) = 0 ∧
      ((u₁ : ℤ) - 3) * ((w₀ : ℤ) - 3) = 0 ∧ ((u₁ : ℤ) - 3) * ((w₁ : ℤ) - 3) = 1) := by
  decide
-- Independent lanes: (90, 10) by (80, 20) percent gives 72, 18, 8, 2, with ad - bc = 0.
example : 90 * 80 / 100 = 72 ∧ 90 * 20 / 100 = 18 ∧ 10 * 80 / 100 = 8 ∧ 10 * 20 / 100 = 2 ∧
    (72 : ℤ) * 2 - 18 * 8 = 0 := by norm_num
-- Groups side by side: Z2 x Z3 has 6 members, and (1, 1) first returns to (0, 0) at step 6.
example : Fintype.card (ZMod 2 × ZMod 3) = 6 := by decide
example : (6 : ℕ) • ((1, 1) : ZMod 2 × ZMod 3) = 0 ∧
    ∀ k : Fin 5, ((k : ℕ) + 1) • ((1, 1) : ZMod 2 × ZMod 3) ≠ 0 := by decide

#print axioms interchange_law
#print axioms boxes_slide_past_each_other
#print axioms crossings_in_symmetric_category
