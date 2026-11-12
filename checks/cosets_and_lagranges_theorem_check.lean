-- Cosets and Lagrange's theorem: in a finite group the left cosets of a subgroup are equal-sized blocks that never overlap unless equal, so the group's size is the number of cosets times the subgroup's size, and the subgroup's size and every member's order divide the group's size.
import Mathlib.GroupTheory.Coset.Card
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Algebra.Group.Pointwise.Set.Basic
import Mathlib.Data.Nat.Totient

open Pointwise

/-- Lagrange's theorem, as the card states it: in a finite group G, a subgroup H and its left
slides g * H cut G into blocks, and the size of G is the number of distinct blocks times the
size of H, so the size of H divides the size of G. -/
theorem lagrange_card_eq_cosets_mul_card {G : Type*} [Group G] [Finite G] (H : Subgroup G) :
    Nat.card G = Nat.card (Set.range fun g : G => g • (H : Set G)) * Nat.card H ∧
      Nat.card H ∣ Nat.card G := by
  refine ⟨?_, Subgroup.card_subgroup_dvd_card H⟩
  rw [Subgroup.card_eq_card_quotient_mul_card_subgroup H]
  congr 1
  let F : G ⧸ H → Set G := Quotient.lift (fun g : G => g • (H : Set G)) (by
    intro x y hxy
    exact (leftCoset_eq_iff H).2 (QuotientGroup.leftRel_apply.1 hxy))
  have hF : Function.Injective F := by
    intro p q hpq
    induction p using QuotientGroup.induction_on
    induction q using QuotientGroup.induction_on
    exact QuotientGroup.eq.2 ((leftCoset_eq_iff H).1 hpq)
  have hr : Set.range F = Set.range fun g : G => g • (H : Set G) := by
    ext s
    constructor
    · rintro ⟨q, rfl⟩
      induction q using QuotientGroup.induction_on with
      | H g => exact ⟨g, rfl⟩
    · rintro ⟨g, rfl⟩
      exact ⟨(g : G ⧸ H), rfl⟩
  rw [← hr, Nat.card_range_of_injective hF]

/-- Steps 0 to 2: every left coset g * H holds as many members as H, two left cosets that
share a member are the same set, and every member g lies in its own coset g * H. -/
theorem left_cosets_equal_size_disjoint_or_equal {G : Type*} [Group G] (H : Subgroup G)
    (a b : G) :
    Nat.card ↥(a • (H : Set G) : Set G) = Nat.card H ∧
      (a • (H : Set G) = b • (H : Set G) ∨ Disjoint (a • (H : Set G)) (b • (H : Set G))) ∧
      a ∈ a • (H : Set G) := by
  refine ⟨?_, ?_, mem_own_leftCoset H.toSubmonoid a⟩
  · rw [← Set.image_smul, Nat.card_image_of_injective (MulAction.injective a)]
    rfl
  · by_cases h : Disjoint (a • (H : Set G)) (b • (H : Set G))
    · exact Or.inr h
    · left
      rw [Set.not_disjoint_iff] at h
      obtain ⟨x, hxa, hxb⟩ := h
      rw [mem_leftCoset_iff] at hxa hxb
      rw [leftCoset_eq_iff]
      have : a⁻¹ * b = (a⁻¹ * x) * (b⁻¹ * x)⁻¹ := by simp [mul_assoc]
      rw [this]
      exact H.mul_mem hxa (H.inv_mem hxb)

/-- Step 3: in a finite group, every member's order divides the group's size. -/
theorem order_of_member_dvd_card {G : Type*} [Group G] [Finite G] (g : G) :
    orderOf g ∣ Nat.card G := by
  exact orderOf_dvd_natCard g

-- The clock: H = 0, 3, 6, 9 slid by 1 and by 2.
example : (({0, 3, 6, 9} : Finset ℕ).image fun h => (1 + h) % 12) = {1, 4, 7, 10} := by decide
example : (({0, 3, 6, 9} : Finset ℕ).image fun h => (2 + h) % 12) = {2, 5, 8, 11} := by decide
-- Sliding by 4 names the same block as sliding by 1; sliding by 3 returns H.
example : (({0, 3, 6, 9} : Finset ℕ).image fun h => (4 + h) % 12) =
    (({0, 3, 6, 9} : Finset ℕ).image fun h => (1 + h) % 12) := by decide
example : (({0, 3, 6, 9} : Finset ℕ).image fun h => (3 + h) % 12) = {0, 3, 6, 9} := by decide
-- Twelve slides give exactly 3 distinct blocks, and 3 blocks × 4 hours = 12.
example : ((Finset.range 12).image fun g =>
    ({0, 3, 6, 9} : Finset ℕ).image fun h => (g + h) % 12).card = 3 := by decide
example : 3 * 4 = 12 := by norm_num
-- The units of the 12-clock are 1, 5, 7, 11, and phi(12) = 4.
example : (Finset.range 12).filter (fun a => Nat.Coprime a 12) = {1, 5, 7, 11} := by decide
example : Nat.totient 12 = 4 := by decide
-- Their orders are 1, 2, 2, 2: 5 × 5, 7 × 7 and 11 × 11 each wrap to 1.
example : 5 * 5 % 12 = 1 ∧ 7 * 7 % 12 = 1 ∧ 11 * 11 % 12 = 1 := by norm_num
-- Each unit to the fourth power reads 1.
example : ∀ a ∈ ({1, 5, 7, 11} : Finset ℕ), a ^ 4 % 12 = 1 := by decide
-- Mistakes: 4 × 4 = 16 slots; 0, 3, 6, 7 gives 12 copies, 48 slots; 2 multiplied in 12 times reads 4.
example : 4 * 4 = 16 := by norm_num
example : ((Finset.range 12).image fun g =>
    ({0, 3, 6, 7} : Finset ℕ).image fun h => (g + h) % 12).card = 12 := by decide
example : 12 * 4 = 48 := by norm_num
example : 2 ^ 12 % 12 = 4 := by norm_num

#print axioms lagrange_card_eq_cosets_mul_card
#print axioms left_cosets_equal_size_disjoint_or_equal
#print axioms order_of_member_dvd_card
