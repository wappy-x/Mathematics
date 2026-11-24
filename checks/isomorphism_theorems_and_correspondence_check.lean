-- The isomorphism theorems: collapsing a group by a normal subgroup K and then by what is left of a larger normal subgroup N gives the same group as collapsing by N at once, what any subgroup H adds on top of a normal N is H over its overlap with N, and the subgroups of a quotient G/N match the subgroups of G that contain N.
import Mathlib.GroupTheory.QuotientGroup.Basic
import Mathlib.GroupTheory.Index
import Mathlib.Algebra.Group.Subgroup.Pointwise
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.Data.ZMod.Basic
import Mathlib.NumberTheory.Divisors
import Mathlib.Tactic.NormNum

open Pointwise DihedralGroup

/-- The third isomorphism theorem: collapsing in two stages is collapsing once. Take two normal
subgroups `K` and `N` of a group `G` with `K` inside `N`. The piles of `K` that lie inside `N`
(Mathlib's `N.map (QuotientGroup.mk' K)`, the card's `N/K`) are exactly the piles `gK` all of
whose names `g` lie in `N`; they form a normal subgroup of `G/K`; and `(G/K)/(N/K)` is a copy of
`G/N`, the two-stage pile of `g` matching the one-stage pile of `g`. -/
theorem collapse_twice_is_collapse_once {G : Type*} [Group G] (K N : Subgroup G)
    [K.Normal] [N.Normal] (hKN : K ≤ N) :
    (∀ x : G ⧸ K, x ∈ N.map (QuotientGroup.mk' K) ↔ ∀ g : G, (g : G ⧸ K) = x → g ∈ N) ∧
    (N.map (QuotientGroup.mk' K)).Normal ∧
    ∃ e : (G ⧸ K) ⧸ N.map (QuotientGroup.mk' K) ≃* G ⧸ N,
      ∀ g : G, e ((g : G ⧸ K) : (G ⧸ K) ⧸ N.map (QuotientGroup.mk' K)) = (g : G ⧸ N) := by
  refine ⟨fun x => ⟨?_, ?_⟩, inferInstance, QuotientGroup.quotientQuotientEquivQuotient K N hKN,
    fun g => rfl⟩
  · rintro ⟨n, hn, rfl⟩ g hg
    have h1 : n⁻¹ * g ∈ K := (QuotientGroup.eq).mp hg.symm
    have h2 : n⁻¹ * g ∈ N := hKN h1
    have : g = n * (n⁻¹ * g) := by group
    rw [this]
    exact N.mul_mem hn h2
  · intro h
    obtain ⟨g, rfl⟩ := QuotientGroup.mk_surjective x
    exact ⟨g, h g rfl, rfl⟩

/-- The second, or diamond, isomorphism theorem. Take any subgroup `H` and a normal subgroup `N`
of a group `G`. Every member of `H` combined with every member of `N`, the set `HN`, is a
subgroup (Mathlib's `H ⊔ N`); `HN/N` is a copy of `H/(H ∩ N)` (Mathlib writes `H ∩ N`, seen
inside `H`, as `N.subgroupOf H`), the pile of `h` in `H/(H ∩ N)` matching the pile `hN`; and,
when `G` is finite, `|HN| = |H| |N| / |H ∩ N|`. -/
theorem diamond_isomorphism_theorem {G : Type*} [Group G] (H N : Subgroup G) [N.Normal] :
    ((H ⊔ N : Subgroup G) : Set G) = (H : Set G) * (N : Set G) ∧
    (∃ e : H ⧸ N.subgroupOf H ≃* (H ⊔ N : Subgroup G) ⧸ N.subgroupOf (H ⊔ N),
      ∀ h : H, e (h : H ⧸ N.subgroupOf H) =
        ((⟨(h : G), Subgroup.mem_sup_left h.2⟩ : (H ⊔ N : Subgroup G)) :
          (H ⊔ N : Subgroup G) ⧸ N.subgroupOf (H ⊔ N))) ∧
    (Finite G → (Nat.card (H ⊔ N : Subgroup G) : ℚ) =
      (Nat.card H : ℚ) * Nat.card N / Nat.card (H ⊓ N : Subgroup G)) := by
  refine ⟨Subgroup.mul_normal H N, ⟨QuotientGroup.quotientInfEquivProdNormalQuotient H N,
    fun h => rfl⟩, fun _ => ?_⟩
  have e1 := Subgroup.relIndex_mul_card N H
  have e2 := Subgroup.relIndex_mul_card N (H ⊔ N)
  rw [Subgroup.relIndex_sup_right, inf_eq_left.mpr le_sup_right] at e2
  have hpos : (0 : ℚ) < Nat.card (H ⊓ N : Subgroup G) := by exact_mod_cast Nat.card_pos
  rw [eq_div_iff hpos.ne', ← e1, ← e2, inf_comm]
  push_cast
  ring

/-- The correspondence theorem. For `N` normal in a group `G`, sending a subgroup `S` that
contains `N` to its piles `S/N` (Mathlib's `S.map (QuotientGroup.mk' N)`) matches those subgroups
one to one with all subgroups of `G/N`. The match keeps containment both ways (an order
isomorphism), keeps the index (number of piles), and keeps normality. -/
theorem subgroups_of_quotient_are_subgroups_above_kernel {G : Type*} [Group G]
    (N : Subgroup G) [N.Normal] :
    ∃ e : {S : Subgroup G // N ≤ S} ≃o Subgroup (G ⧸ N),
      (∀ S, e S = S.1.map (QuotientGroup.mk' N)) ∧
      (∀ S, (e S).index = S.1.index) ∧
      (∀ S, (e S).Normal ↔ S.1.Normal) := by
  refine ⟨(QuotientGroup.comapMk'OrderIso N).symm, fun S => rfl, fun S => ?_, fun S => ?_⟩
  · change (S.1.map (QuotientGroup.mk' N)).index = S.1.index
    exact Subgroup.index_map_eq _ (QuotientGroup.mk'_surjective N)
      (by rw [QuotientGroup.ker_mk']; exact S.2)
  · change (S.1.map (QuotientGroup.mk' N)).Normal ↔ S.1.Normal
    constructor
    · intro h
      have hc : (S.1.map (QuotientGroup.mk' N)).comap (QuotientGroup.mk' N) = S.1 := by
        rw [QuotientGroup.comap_map_mk', sup_eq_right.mpr S.2]
      rw [← hc]
      exact h.comap _
    · intro h
      exact h.map _ (QuotientGroup.mk'_surjective N)

-- The dose clock: 22:00 reads 10 on the 12-hour clock, and 10 is 2 past 8; at once, 22 is
-- 2 past 20. Two stages and one stage give the same reading.
example : (22 : ZMod 12) = 10 ∧ ((10 : ZMod 12).val : ZMod 4) = 2 ∧ (22 : ZMod 4) = 2 := by
  decide
-- Pile counts: 24 / 2 = 12, then 12 / 3 = 4; at once 24 / 6 = 4.
example : 24 / 2 = 12 ∧ 12 / 3 = 4 ∧ 24 / 6 = 4 := by norm_num
-- 0, 4, 8 is not a subgroup of the 24-hour clock: 4 + 8 = 12 falls outside.
example : (4 : ZMod 24) + 8 ∉ ({0, 4, 8} : Finset (ZMod 24)) := by decide
-- The diamond on the clock: H = multiples of 6 (4 members), N = multiples of 4 (6 members),
-- overlap 0 and 12, and H + N has 4 × 6 / 2 = 12 members.
example :
    let H := (Finset.univ : Finset (ZMod 24)).filter (fun x => 6 ∣ x.val)
    let N := (Finset.univ : Finset (ZMod 24)).filter (fun x => 4 ∣ x.val)
    H.card = 4 ∧ N.card = 6 ∧ (H ∩ N).card = 2 ∧ (H + N).card = 12 ∧ 4 * 6 / 2 = 12 := by
  decide +kernel
-- The 12-hour clock has six subgroups, one for each divisor 1, 2, 3, 4, 6, 12 of 12: a search
-- of all 4,096 subsets finds six sets that hold 0 and are closed under adding.
example : Nat.divisors 12 = {1, 2, 3, 4, 6, 12} := by decide
example : ((Finset.univ : Finset (Finset (ZMod 12))).filter
    (fun S => (0 : ZMod 12) ∈ S ∧ ∀ a ∈ S, ∀ b ∈ S, a + b ∈ S)).card = 6 := by
  decide +kernel
-- Subgroups of the 24-hour clock containing 0 and 12: the divisors of 24 that divide 12, six.
example : ((Nat.divisors 24).filter (· ∣ 12)).card = 6 := by decide
-- The square tile: 10 subgroups, 6 of them normal, and 5 contain the half turn `r 2`.
example : ((Finset.univ : Finset (Finset (DihedralGroup 4))).filter
    (fun S => (1 : DihedralGroup 4) ∈ S ∧ ∀ a ∈ S, ∀ b ∈ S, a * b ∈ S)).card = 10 := by
  decide +kernel
example : ((Finset.univ : Finset (Finset (DihedralGroup 4))).filter
    (fun S => (1 : DihedralGroup 4) ∈ S ∧ (∀ a ∈ S, ∀ b ∈ S, a * b ∈ S) ∧
      ∀ g : DihedralGroup 4, ∀ a ∈ S, g * a * g⁻¹ ∈ S)).card = 6 := by
  decide +kernel
example : ((Finset.univ : Finset (Finset (DihedralGroup 4))).filter
    (fun S => (1 : DihedralGroup 4) ∈ S ∧ (∀ a ∈ S, ∀ b ∈ S, a * b ∈ S) ∧
      r 2 ∈ S)).card = 5 := by
  decide +kernel

#print axioms collapse_twice_is_collapse_once
#print axioms diamond_isomorphism_theorem
#print axioms subgroups_of_quotient_are_subgroups_above_kernel
