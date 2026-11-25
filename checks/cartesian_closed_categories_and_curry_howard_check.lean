-- Cartesian closed categories: sets form a cartesian closed category, with the set of functions B → C as the exponential, currying as the match and eval as its counit; groups do not; and the only function A × B → B × A that commutes with every relabelling is swap.
import Mathlib.CategoryTheory.Monoidal.Types.Basic
import Mathlib.CategoryTheory.Limits.Types.Limits
import Mathlib.CategoryTheory.Yoneda
import Mathlib.Algebra.Category.Grp.CartesianMonoidal
import Mathlib.Algebra.Category.Grp.Limits
import Mathlib.Algebra.Category.Grp.Zero
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.ZMod.Defs

open CategoryTheory CategoryTheory.Limits MonoidalCategory Opposite

universe u

/-- Sets form a cartesian closed category. Sets have a terminal object (a one-point set) and a
product `A × B` for any two sets, and for every set `B` the functor "pair with `B`",
`X ↦ X × B`, is left adjoint to "arrows from `B`", `C ↦ C^B`, where `C^B` is the set of all
functions from `B` to `C`: `(- × B) ⊣ (-)^B`. The one-for-one match
`Hom(A × B, C) ≅ Hom(A, C^B)`, natural in `A` and `C`, is currying, sending a two-input rule `f`
to `a ↦ (b ↦ f(a, b))`, and its counit is `eval : C^B × B → C`, `eval(g, b) = g(b)`. -/
theorem sets_form_a_cartesian_closed_category :
    HasTerminal (Type u) ∧ HasBinaryProducts (Type u) ∧
    ∀ B : Type u, ∃ adj : tensorRight B ⊣ coyoneda.obj (op B),
      (∀ (A C : Type u) (f : A ⊗ B ⟶ C) (a : A) (b : B),
        (show B ⟶ C from adj.homEquiv A C f a) b = f (a, b)) ∧
      (∀ (C : Type u) (g : B ⟶ C) (b : B), adj.counit.app C (g, b) = g b) := by
  refine ⟨inferInstance, inferInstance, fun B => ?_⟩
  let adj : tensorRight B ⊣ coyoneda.obj (op B) :=
    { unit := { app Z := ↾fun z ↦ ↾fun x => ⟨z, x⟩ }
      counit := { app _ := ↾fun gx => gx.1.hom gx.2 } }
  refine ⟨adj, ?_, ?_⟩
  · intro A C f a b
    rfl
  · intro C g b
    rfl

/-- Groups are not cartesian closed. Groups have a terminal object (the one-element group) and a
product of any two groups, but some group `B` has no exponential: "pair with `B`",
`X ↦ X × B`, has no right adjoint. -/
theorem groups_not_cartesian_closed :
    HasTerminal GrpCat.{u} ∧ HasBinaryProducts GrpCat.{u} ∧
    ∃ B : GrpCat.{u}, ¬ (tensorRight B).IsLeftAdjoint := by
  refine ⟨inferInstance, inferInstance, ?_⟩
  refine ⟨GrpCat.of (ULift.{u} (Multiplicative (ZMod 2))), ?_⟩
  intro hL
  set B := GrpCat.of (ULift.{u} (Multiplicative (ZMod 2)))
  let adj := Adjunction.ofIsLeftAdjoint (tensorRight B)
  let X : GrpCat.{u} := GrpCat.of PUnit
  have hX : IsZero X := GrpCat.isZero_of_subsingleton _
  have hsub : ∀ (g₁ g₂ : X ⊗ B ⟶ B), g₁ = g₂ := by
    intro g₁ g₂
    apply (adj.homEquiv X B).injective
    exact hX.eq_of_src _ _
  have key := hsub (CartesianMonoidalCategory.snd X B)
    (CartesianMonoidalCategory.fst X B ≫ hX.to_ B)
  have h2 := congrArg (fun g => CartesianMonoidalCategory.lift (hX.from_ B) (𝟙 B) ≫ g) key
  simp only [CartesianMonoidalCategory.lift_snd, CartesianMonoidalCategory.lift_fst_assoc] at h2
  have h3 := congrArg (fun g => (g : B ⟶ B).hom (ULift.up (Multiplicative.ofAdd 1))) h2
  simp at h3
  have h4 : (hX.from_ B).hom (ULift.up (Multiplicative.ofAdd 1)) = 1 := Subsingleton.elim _ _
  rw [h4, MonoidHom.map_one] at h3
  have h5 := congrArg (fun x : ULift.{u} (Multiplicative (ZMod 2)) => Multiplicative.toAdd x.down) h3
  change (1 : ZMod 2) = 0 at h5
  exact absurd h5 (by decide)

/-- A proof is a uniform arrow. Among all functions `f : A × B → B × A`, the only one that is
natural, meaning that relabelling `A` by any function `h : A → A` and `B` by any function
`k : B → B` before `f` gives the same result as after it, is swap, `(a, b) ↦ (b, a)`. -/
theorem natural_pair_reversal_is_swap {A B : Type u} (f : A × B → B × A)
    (hf : ∀ (h : A → A) (k : B → B) (p : A × B),
      f (Prod.map h k p) = Prod.map k h (f p)) :
    f = Prod.swap := by
  funext ⟨a, b⟩
  have := hf (fun _ => a) (fun _ => b) (a, b)
  exact this

-- The refill rule: 2 customer types, 3 cup sizes, answers yes or no.
-- Two-input rules: 2 ^ 6 = 64; menus, the points of C^B: 2 ^ 3 = 8; curried rules: 8 ^ 2 = 64.
example : Fintype.card (Fin 2 × Fin 3 → Fin 2) = 64 := by simp
example : Fintype.card (Fin 3 → Fin 2) = 8 := by simp
example : Fintype.card (Fin 2 → Fin 3 → Fin 2) = 64 := by simp
example : (2 : ℕ) ^ (2 * 3) = 64 ∧ (2 ^ 3) ^ 2 = 64 := by norm_num
-- The power law at the card's three more sizes: 9 and 9, 81 and 81, 64 and 64 are of this form.
example : ∀ a b c : Fin 5, (c : ℕ) ^ ((a : ℕ) * b) = ((c : ℕ) ^ (b : ℕ)) ^ (a : ℕ) := by decide
-- Mistakes: C^B read as B^C gives 3 ^ 2 = 9 points and 9 ^ 2 = 81 curried rules;
-- read as pairs C × B it gives 6 points and 6 ^ 2 = 36 curried rules.
example : Fintype.card (Fin 2 → Fin 3) = 9 := by simp
example : Fintype.card (Fin 2 → Fin 2 → Fin 3) = 81 := by simp
example : Fintype.card (Fin 2 → Fin 2 × Fin 3) = 36 := by simp
-- Groups: Hom(Z_2, Z_2) has 2 members, but Hom(1, Z_2) has only 1, so 2 ≠ 1.
example : ((Finset.univ : Finset (ZMod 2 → ZMod 2)).filter
    (fun f => ∀ x y, f (x + y) = f x + f y)).card = 2 := by decide
example : ((Finset.univ : Finset (ZMod 1 → ZMod 2)).filter
    (fun f => ∀ x y, f (x + y) = f x + f y)).card = 1 := by decide
-- Step 7: 6 ^ 6 = 46,656 functions A × B → B × A; 4 × 27 = 108 relabellings (h, k);
-- 2 × 6 = 12 one-to-one relabellings.
example : Fintype.card (Fin 6 → Fin 6) = 46656 := by simp
example : Fintype.card ((Fin 2 → Fin 2) × (Fin 3 → Fin 3)) = 108 := by simp
example : Fintype.card (Equiv.Perm (Fin 2) × Equiv.Perm (Fin 3)) = 12 := by
  simp [Fintype.card_perm]; decide
-- Step 8, the two-stage Kripke table: values 0 (never), 1 (only later), 2 (from the start);
-- "if A then B" is 2 when A ≤ B, else B. Peirce's law ((P → Q) → P) → P is 2 in 24 of the
-- 27 rows of P, Q, R, but in all 8 truth-table rows (values 0 and 2 only).
example : ((Finset.univ : Finset (Fin 3 × Fin 3 × Fin 3)).filter (fun v =>
    let imp : Fin 3 → Fin 3 → Fin 3 := fun a b => if a ≤ b then 2 else b
    imp (imp (imp v.1 v.2.1) v.1) v.1 = 2)).card = 24 := by decide
example : ((Finset.univ : Finset (Fin 3 × Fin 3 × Fin 3)).filter (fun v =>
    let imp : Fin 3 → Fin 3 → Fin 3 := fun a b => if a ≤ b then 2 else b
    v.1 ≠ 1 ∧ v.2.1 ≠ 1 ∧ v.2.2 ≠ 1 ∧ imp (imp (imp v.1 v.2.1) v.1) v.1 = 2)).card = 8 := by
  decide
-- Swap's formula (P ∧ Q) → (Q ∧ P), with "and" as the smaller value, is 2 in all 27 rows.
example : ((Finset.univ : Finset (Fin 3 × Fin 3 × Fin 3)).filter (fun v =>
    let imp : Fin 3 → Fin 3 → Fin 3 := fun a b => if a ≤ b then 2 else b
    imp (min v.1 v.2.1) (min v.2.1 v.1) = 2)).card = 27 := by decide

#print axioms sets_form_a_cartesian_closed_category
#print axioms groups_not_cartesian_closed
#print axioms natural_pair_reversal_is_swap
