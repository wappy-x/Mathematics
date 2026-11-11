-- Homomorphisms and isomorphisms: a map between groups that respects the operation is one-to-one exactly when only the identity lands on the identity, it always sends the identity to the identity and inverses to inverses with its kernel a subgroup, and when it is also one-to-one and onto its undo respects the operation too.
import Mathlib.Algebra.Group.Subgroup.Defs
import Mathlib.Logic.Function.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Finset.Card

theorem hom_map_one_aux {G H : Type*} [Group G] [Group H]
    (f : G → H) (hf : ∀ a b : G, f (a * b) = f a * f b) : f 1 = 1 := by
  have h := hf 1 1
  rw [one_mul] at h
  exact left_eq_mul.mp h

#print axioms hom_map_one_aux

theorem hom_map_inv_aux {G H : Type*} [Group G] [Group H]
    (f : G → H) (hf : ∀ a b : G, f (a * b) = f a * f b) (a : G) : f a⁻¹ = (f a)⁻¹ := by
  have h := hf a a⁻¹
  rw [mul_inv_cancel, hom_map_one_aux f hf] at h
  exact eq_inv_of_mul_eq_one_right h.symm

#print axioms hom_map_inv_aux

/-- One-to-one exactly when the kernel is only the identity. Take two groups G and H and a map
f from G to H that respects the operation: f(a * b) = f(a) * f(b) for every pair a, b. Then no
two members of G land in the same place exactly when the kernel, the members of G sent to the
identity of H, holds nothing but the identity of G. -/
theorem one_to_one_iff_kernel_is_only_the_identity {G H : Type*} [Group G] [Group H]
    (f : G → H) (hf : ∀ a b : G, f (a * b) = f a * f b) :
    Function.Injective f ↔ {a : G | f a = 1} = {1} := by
  have h1 := hom_map_one_aux f hf
  constructor
  · intro hinj
    ext a
    simp only [Set.mem_setOf_eq, Set.mem_singleton_iff]
    constructor
    · intro ha
      exact hinj (ha.trans h1.symm)
    · intro ha
      rw [ha, h1]
  · intro hk a b hab
    have : f (a * b⁻¹) = 1 := by
      rw [hf, hom_map_inv_aux f hf, hab, mul_inv_cancel]
    have hmem : a * b⁻¹ ∈ {a : G | f a = 1} := this
    rw [hk, Set.mem_singleton_iff] at hmem
    exact mul_inv_eq_one.mp hmem

/-- The identity and the inverses come along free. A map f from a group G to a group H with
f(a * b) = f(a) * f(b) for every pair sends the identity of G to the identity of H, sends the
inverse of every a to the inverse of f(a), and its kernel (the members sent to the identity)
is a subgroup of G. -/
theorem identity_and_inverses_come_free_and_kernel_is_a_subgroup {G H : Type*} [Group G]
    [Group H] (f : G → H) (hf : ∀ a b : G, f (a * b) = f a * f b) :
    f 1 = 1 ∧ (∀ a : G, f a⁻¹ = (f a)⁻¹) ∧
      ∃ K : Subgroup G, (K : Set G) = {a : G | f a = 1} := by
  refine ⟨hom_map_one_aux f hf, hom_map_inv_aux f hf, ?_⟩
  refine ⟨{ carrier := {a : G | f a = 1}
            mul_mem' := ?_
            one_mem' := ?_
            inv_mem' := ?_ }, rfl⟩
  · intro a b ha hb
    simp only [Set.mem_setOf_eq] at *
    rw [hf, ha, hb, one_mul]
  · exact hom_map_one_aux f hf
  · intro a ha
    simp only [Set.mem_setOf_eq] at *
    rw [hom_map_inv_aux f hf, ha, inv_one]

/-- The naming runs both ways. If a map f from a group G to a group H respects the operation and
is one-to-one and onto (an isomorphism), then its undo g, which sends each member of H back to
the one member of G that lands on it, respects the operation too: g(x * y) = g(x) * g(y). -/
theorem inverse_of_an_isomorphism_respects_the_operation {G H : Type*} [Group G] [Group H]
    (f : G → H) (hf : ∀ a b : G, f (a * b) = f a * f b) (hbij : Function.Bijective f) :
    ∃ g : H → G, Function.LeftInverse g f ∧ Function.RightInverse g f ∧
      ∀ x y : H, g (x * y) = g x * g y := by
  refine ⟨Function.surjInv hbij.2, Function.leftInverse_surjInv hbij,
    Function.rightInverse_surjInv hbij.2, ?_⟩
  intro x y
  apply hbij.1
  rw [hf, Function.rightInverse_surjInv hbij.2, Function.rightInverse_surjInv hbij.2,
    Function.rightInverse_surjInv hbij.2]

-- The clock map is the remainder on 12. Evening reading 23 translates to 11.
example : 23 % 12 = 11 := by decide
-- 23 and 5: add first on the station clock, 23 + 5 wraps to 4, which reads 4;
-- translate first, 11 + 5 wraps to 4 on the wall clock. Both routes give 4.
example : (23 + 5) % 24 = 4 ∧ 4 % 12 = 4 ∧ (23 % 12 + 5 % 12) % 12 = 4 := by decide
-- Every pair, 24 readings by 24: both routes agree on all 576.
example : ∀ a b : Fin 24, ((a.val + b.val) % 24) % 12 = (a.val % 12 + b.val % 12) % 12 := by
  decide
example : ((List.range 24).map (fun a => ((List.range 24).filter
    (fun b => ((a + b) % 24) % 12 = (a % 12 + b % 12) % 12)).length)).sum = 576 := by
  decide
-- The kernel, the readings sent to 0, is {0, 12}; 11 and 23 both read 11.
example : (List.range 24).filter (fun x => x % 12 = 0) = [0, 12] := by decide
example : (List.range 24).filter (fun x => x % 12 = 11) = [11, 23] := by decide
-- Readings reached: all 12, and 24 divided by the kernel's size 2 is 12.
example : ((Finset.range 24).image (fun x => x % 12)).card = 12 ∧ 24 / 2 = 12 := by decide
-- Shifting every reading up by one sends 0 to 1, and gets 0 of the 576 pairs right.
example : (0 + 1) % 12 = 1 := by decide
example : ((List.range 24).map (fun a => ((List.range 24).filter
    (fun b => ((a + b) % 24 + 1) % 12 = ((a + 1) % 12 + (b + 1) % 12) % 12)).length)).sum = 0 := by
  decide
-- Aimed at a ten-hour clock, the remainder on 10 gets only 300 of the 576 pairs right.
example : ((List.range 24).map (fun a => ((List.range 24).filter
    (fun b => ((a + b) % 24) % 10 = (a % 10 + b % 10) % 10)).length)).sum = 300 := by
  decide
-- The tile: a quarter turn sends corners 0 1 2 3 to 1 2 3 0, and turning a then b (as corner
-- maps, composed) is the turn labelled a + b on a four-hour clock: all 16 cells agree.
example : [0, 1, 2, 3].map (fun i => (i + 1) % 4) = [1, 2, 3, 0] := by decide
example : ∀ a b i : Fin 4, ((i.val + b.val) % 4 + a.val) % 4 = (i.val + (a.val + b.val) % 4) % 4 := by
  decide
-- Steps home: the four turns need 1, 4, 2, 4; the numbers 1, 3, 5, 7 multiplied with wrapping
-- at 8 need 1, 2, 2, 2. Equal size, different tables.
example : [0, 1, 2, 3].map (fun k => (List.range' 1 8).find? (fun n => n * k % 4 = 0)) =
    [some 1, some 4, some 2, some 4] := by decide
example : [1, 3, 5, 7].map (fun u => (List.range' 1 8).find? (fun n => u ^ n % 8 = 1)) =
    [some 1, some 2, some 2, some 2] := by decide

#print axioms one_to_one_iff_kernel_is_only_the_identity
#print axioms identity_and_inverses_come_free_and_kernel_is_a_subgroup
#print axioms inverse_of_an_isomorphism_respects_the_operation
