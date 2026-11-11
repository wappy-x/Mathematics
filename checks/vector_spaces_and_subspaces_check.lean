-- Vector spaces and subspaces: inside any real vector space, a subset that holds the zero and is closed under adding and under scaling by every real number holds every opposite and is a vector space in its own right, a set cut out by "this slot equals c" passes exactly when c is 0, and the never-negative recipes lose their opposites.
import Mathlib.Algebra.Module.Submodule.Defs
import Mathlib.Algebra.Module.Pi
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.LinearAlgebra.Pi

/-! A real vector space is a type `V` with Mathlib's `[AddCommGroup V] [Module ℝ V]`: the
first carries rules 1 to 4 (adding), the second rules 5 to 8 (scaling). A subset of `V` is a
`Set V`, and `↥W` is the type of its members, each remembering the vector of `V` it is.
A list of `n` real numbers is a function `Fin n → ℝ`, added slot by slot and scaled slot by
slot. A recipe is such a list with `n = 3`: slot 0 is flour, slot 1 sugar, slot 2 butter, and
`![300, 100, 200]` is the shortbread. A Mathlib `Submodule ℝ V` is a subspace of `V`. -/

/-- The three checks are enough. Let `W` be a subset of a real vector space `V`. If the zero
vector is in `W`, the sum of any two members of `W` is in `W`, and every member of `W` scaled by
every real number is in `W`, then `W` holds the opposite of each of its members, and `W` with
the adding and scaling it borrows from `V` is a real vector space in its own right: it obeys
all eight rules. -/
theorem three_checks_make_a_vector_space {V : Type*} [AddCommGroup V] [Module ℝ V] (W : Set V)
    (h_zero : (0 : V) ∈ W)
    (h_add : ∀ u ∈ W, ∀ v ∈ W, u + v ∈ W)
    (h_smul : ∀ (a : ℝ), ∀ u ∈ W, a • u ∈ W) :
    (∀ u ∈ W, -u ∈ W) ∧
      ∃ (_ : AddCommGroup W) (_ : Module ℝ W),
        ((0 : W) : V) = 0 ∧
        (∀ x y : W, ((x + y : W) : V) = (x : V) + (y : V)) ∧
        (∀ (a : ℝ) (x : W), ((a • x : W) : V) = a • (x : V)) := by
  let S : Submodule ℝ V :=
    { carrier := W
      add_mem' := fun {a b} ha hb => h_add a ha b hb
      zero_mem' := h_zero
      smul_mem' := fun c x hx => h_smul c x hx }
  refine ⟨fun u hu => by simpa using h_smul (-1) u hu, ?_⟩
  exact ⟨(inferInstance : AddCommGroup S), (inferInstance : Module ℝ S), rfl,
    fun _ _ => rfl, fun _ _ => rfl⟩

/-- A set pinned by one slot closes up only when the pin is zero. For any length `n`, any slot
`i` and any real number `c`, the lists whose slot `i` equals `c` form a subspace exactly when
`c = 0`. Sugar pinned at 0 is a subspace; flour pinned at 200 is not. -/
theorem slot_pinned_set_is_subspace_iff_zero {n : ℕ} (i : Fin n) (c : ℝ) :
    (∃ S : Submodule ℝ (Fin n → ℝ), (S : Set (Fin n → ℝ)) = {u | u i = c}) ↔ c = 0 := by
  constructor
  · rintro ⟨S, hS⟩
    have h0 : (0 : Fin n → ℝ) ∈ (S : Set (Fin n → ℝ)) := S.zero_mem
    rw [hS] at h0
    simpa [eq_comm] using h0
  · rintro rfl
    refine ⟨LinearMap.ker (LinearMap.proj i : (Fin n → ℝ) →ₗ[ℝ] ℝ), ?_⟩
    ext u
    simp

/-- Scaling by positive numbers only is not enough. The recipes with no negative slot hold the
zero recipe, survive adding and survive scaling by every number that is not negative, yet the
shortbread (300, 100, 200) is among them and its opposite (-300, -100, -200) is not: rule 4
fails, so they are not a subspace. -/
theorem never_negative_recipes_lack_opposites :
    let P : Set (Fin 3 → ℝ) := {u | ∀ j, 0 ≤ u j}
    (0 : Fin 3 → ℝ) ∈ P ∧
      (∀ u ∈ P, ∀ v ∈ P, u + v ∈ P) ∧
      (∀ (a : ℝ), 0 ≤ a → ∀ u ∈ P, a • u ∈ P) ∧
      (![300, 100, 200] : Fin 3 → ℝ) ∈ P ∧
      -(![300, 100, 200] : Fin 3 → ℝ) ∉ P ∧
      ¬ ∃ S : Submodule ℝ (Fin 3 → ℝ), (S : Set (Fin 3 → ℝ)) = P := by
  intro P
  refine ⟨fun j => le_refl _, fun u hu v hv j => add_nonneg (hu j) (hv j),
    fun a ha u hu j => mul_nonneg ha (hu j), ?_, ?_, ?_⟩
  · intro j; fin_cases j <;> norm_num
  · intro h
    have := h 0
    norm_num at this
  · rintro ⟨S, hS⟩
    have hmem : (![300, 100, 200] : Fin 3 → ℝ) ∈ (S : Set (Fin 3 → ℝ)) := by
      rw [hS]; intro j; fin_cases j <;> norm_num
    have hneg : -(![300, 100, 200] : Fin 3 → ℝ) ∈ (S : Set (Fin 3 → ℝ)) := S.neg_mem hmem
    rw [hS] at hneg
    have := hneg 0
    norm_num at this

-- Bake both: shortbread plus sponge.
example : (![300, 100, 200] : Fin 3 → ℤ) + ![200, 200, 100] = ![500, 300, 300] := by decide
-- Double the shortbread.
example : (2 : ℤ) • (![300, 100, 200] : Fin 3 → ℤ) = ![600, 200, 400] := by decide
-- Rule 6 at a = 2, b = -3: both sides give the opposite of shortbread.
example : ((2 : ℤ) + -3) • (![300, 100, 200] : Fin 3 → ℤ) = ![-300, -100, -200] := by decide
example : (2 : ℤ) • (![300, 100, 200] : Fin 3 → ℤ) + (-3 : ℤ) • ![300, 100, 200]
    = ![-300, -100, -200] := by decide
-- Sugar-free, added and tripled: the sugar slot stays 0.
example : (![300, 0, 200] : Fin 3 → ℤ) + ![100, 0, 50] = ![400, 0, 250] := by decide
example : (3 : ℤ) • (![300, 0, 200] : Fin 3 → ℤ) = ![900, 0, 600] := by decide
-- 200 g flour, added and tripled: flour 400, then flour 600.
example : (![200, 100, 50] : Fin 3 → ℤ) + ![200, 50, 150] = ![400, 150, 200] := by decide
example : (3 : ℤ) • (![200, 100, 50] : Fin 3 → ℤ) = ![600, 300, 150] := by decide
-- The second road: one slot of the mix 2 u + (-3) v.
example : ((2 : ℤ) • (![300, 0, 200] : Fin 3 → ℤ) + (-3 : ℤ) • ![100, 0, 50] : Fin 3 → ℤ) 1 = 0 := by
  decide
example : ((2 : ℤ) • (![200, 100, 50] : Fin 3 → ℤ) + (-3 : ℤ) • ![200, 50, 150] : Fin 3 → ℤ) 0 = -200 := by
  decide
-- Weights that add to 1, a = 4 and b = -3: the flour of the mix stays at 200.
example : ((4 : ℤ) • (![200, 100, 50] : Fin 3 → ℤ) + (-3 : ℤ) • ![200, 50, 150] : Fin 3 → ℤ) 0 = 200 := by
  decide

#print axioms three_checks_make_a_vector_space
#print axioms slot_pinned_set_is_subspace_iff_zero
#print axioms never_negative_recipes_lack_opposites
