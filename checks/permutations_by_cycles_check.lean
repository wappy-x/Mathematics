-- Counting shuffles by their loops: the number of rearrangements of n labelled keys whose trace makes exactly k loops (a key left on its own hook counts as a loop of length 1) obeys c(n, k) = (n − 1) c(n − 1, k) + c(n − 1, k − 1) with c(1, 1) = 1, the rearrangements of one cycle type number n! divided by the product of j^(a_j) × a_j!, and the derangements are exactly those with no loop of length 1, with the card's five-key numbers checked.
import Mathlib.GroupTheory.Perm.Cycle.Type
import Mathlib.Combinatorics.Derangements.Finite
import Mathlib.Combinatorics.Enumerative.Stirling
import Mathlib.Logic.Equiv.Fin.Rotate
import Mathlib.GroupTheory.Perm.Fin
import Mathlib.GroupTheory.Perm.Centralizer

open Equiv Finset

theorem loops_card_eq {α : Type*} [Fintype α] [DecidableEq α] (σ : Perm α) :
    σ.partition.parts.card = σ.cycleType.card + (Fintype.card α - #σ.support) := by
  simp [Perm.parts_partition]

theorem loops_card_swap_mul {α : Type*} [Fintype α] [DecidableEq α] (μ : Perm α) (x : α)
    (hx : μ x ≠ x) :
    (swap x (μ x) * μ).partition.parts.card = μ.partition.parts.card + 1 := by
  have hcmem : μ.cycleOf x ∈ μ.cycleFactorsFinset :=
    Perm.cycleOf_mem_cycleFactorsFinset_iff.mpr (Perm.mem_support.mpr hx)
  have hcyc : (μ.cycleOf x).IsCycle := Perm.isCycle_cycleOf μ hx
  have hcx : μ.cycleOf x x = μ x := Perm.cycleOf_apply_self μ x
  generalize μ.cycleOf x = c at hcmem hcyc hcx
  have hdisj : Perm.Disjoint (μ * c⁻¹) c := Perm.disjoint_mul_inv_of_mem_cycleFactorsFinset hcmem
  generalize hr : μ * c⁻¹ = r at hdisj
  have hμ : μ = c * r := by
    rw [← hdisj.commute.eq, ← hr]; simp
  have hcx' : c x ≠ x := by rw [hcx]; exact hx
  have hdsub : (swap x (c x) * c).support ≤ c.support := fun y hy =>
    (Perm.mem_support_swap_mul_imp_mem_support_ne hy).1
  have hdd : Perm.Disjoint (swap x (c x) * c) r := hdisj.symm.mono hdsub le_rfl
  have hτ : swap x (μ x) * μ = (swap x (c x) * c) * r := by
    rw [← hcx]; conv_lhs => rw [hμ]
    rw [mul_assoc]
  rw [hτ, loops_card_eq, loops_card_eq, hdd.cycleType_mul, hdd.card_support_mul, hμ,
    hdisj.symm.cycleType_mul, hdisj.symm.card_support_mul, hcyc.cycleType]
  have hle : #(c * r).support ≤ Fintype.card α := (c * r).support.card_le_univ
  rw [hdisj.symm.card_support_mul] at hle
  have h2 := hcyc.two_le_card_support
  by_cases hccx : c (c x) = x
  · have hc2 : c ^ 2 = 1 := (hcyc.pow_eq_one_iff' hcx').mpr (by simp [pow_two, hccx])
    have hord : #c.support = 2 := by
      rw [← hcyc.orderOf]
      exact le_antisymm (Nat.le_of_dvd (by norm_num) (orderOf_dvd_of_pow_eq_one hc2))
        (hcyc.orderOf ▸ h2)
    obtain ⟨a, b, hab, rfl⟩ := Perm.card_support_eq_two.mp hord
    have hd : swap x (swap a b x) * swap a b = 1 := by
      have hxs : x = a ∨ x = b := by
        by_contra h
        push Not at h
        exact hcx' (swap_apply_of_ne_of_ne h.1 h.2)
      rcases hxs with rfl | rfl
      · simp
      · simp [swap_comm]
    rw [hd]
    simp
    omega
  · have hdc : (swap x (c x) * c).IsCycle := hcyc.swap_mul hcx' hccx
    rw [hdc.cycleType, Perm.support_swap_mul_eq c x hccx]
    have hxm : x ∈ c.support := Perm.mem_support.mpr hcx'
    rw [Finset.card_sdiff_of_subset (by simpa using hxm)]
    simp
    omega

theorem loops_card_lift {n : ℕ} (σ : Perm (Fin n)) :
    (Perm.decomposeFin.symm ((0 : Fin (n + 1)), σ)).partition.parts.card =
      σ.partition.parts.card + 1 := by
  let f : Fin n ≃ {i : Fin (n + 1) // i ≠ 0} :=
    { toFun := fun i => ⟨i.succ, Fin.succ_ne_zero i⟩
      invFun := fun j => j.1.pred j.2
      left_inv := fun i => by simp
      right_inv := fun j => by ext; simp }
  have hlift : Perm.decomposeFin.symm ((0 : Fin (n + 1)), σ) = σ.extendDomain f := by
    ext i
    refine Fin.cases ?_ (fun j => ?_) i
    · rw [Perm.decomposeFin_symm_apply_zero, Perm.extendDomain_apply_not_subtype _ _ (by simp)]
    · rw [Perm.decomposeFin_symm_apply_succ, Perm.extendDomain_apply_subtype (b := j.succ) σ f (Fin.succ_ne_zero j)]
      simp [f]
  rw [hlift, loops_card_eq, loops_card_eq, Perm.cycleType_extendDomain,
    Perm.card_support_extend_domain]
  have := σ.support.card_le_univ
  simp only [Fintype.card_fin] at this ⊢
  omega

theorem loops_card_decompose {n : ℕ} (p : Fin (n + 1)) (σ : Perm (Fin n)) :
    (Perm.decomposeFin.symm (p, σ)).partition.parts.card =
      if p = 0 then σ.partition.parts.card + 1 else σ.partition.parts.card := by
  split_ifs with hp
  · subst hp; exact loops_card_lift σ
  · have hsplit : Perm.decomposeFin.symm (p, σ) =
        swap 0 p * Perm.decomposeFin.symm ((0 : Fin (n + 1)), σ) := by
      ext i
      refine Fin.cases ?_ (fun j => ?_) i
      · simp [Perm.decomposeFin_symm_apply_zero]
      · simp [Perm.decomposeFin_symm_apply_succ]
    set μ := Perm.decomposeFin.symm (p, σ)
    have hμ0 : μ 0 = p := Perm.decomposeFin_symm_apply_zero p σ
    have h := loops_card_swap_mul μ 0 (by rw [hμ0]; exact hp)
    have hback : swap 0 p * μ = Perm.decomposeFin.symm ((0 : Fin (n + 1)), σ) := by
      rw [hsplit, ← mul_assoc, swap_mul_self, one_mul]
    rw [hμ0, hback, loops_card_lift] at h
    omega

/-- `loopCount n k` is the card's `c(n, k)`: the number of rehangs of `n` keys (permutations of
the hooks `Fin n`) whose trace makes exactly `k` loops. `σ.partition.parts` is the multiset of
the loop lengths of `σ`, loops of length 1 (keys left on their own hook) included, so its size
is the number of loops. -/
def loopCount (n k : ℕ) : ℕ :=
  #{σ : Perm (Fin n) | σ.partition.parts.card = k}

/-- The card's main claim. Counting the rehangs of `n` keys by how many loops they make, the
last key either slips into a rehang of the other keys after any one of their hooks (same number
of loops) or hangs on its own (one loop more), so
`c(n + 1, k + 1) = n × c(n, k + 1) + c(n, k)` for every `n` and `k`.
The seeds are `c(1, 1) = 1`, and `c(n, k) = 0` when `k` is above `n` or, for `n ≥ 1`, below 1.
These counts are the unsigned Stirling numbers of the first kind. -/
theorem loop_counts_obey_stirling_first_recurrence :
    loopCount 1 1 = 1 ∧
      (∀ n : ℕ, 1 ≤ n → loopCount n 0 = 0) ∧
      (∀ n k : ℕ, n < k → loopCount n k = 0) ∧
      ∀ n k : ℕ, loopCount (n + 1) (k + 1) = n * loopCount n (k + 1) + loopCount n k := by
  refine ⟨by decide, ?_, ?_, ?_⟩
  · intro n hn
    unfold loopCount
    rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro σ _ h
    have hs := σ.partition.parts_sum
    rw [Multiset.card_eq_zero.mp h] at hs
    simp at hs
    omega
  · intro n k hnk
    unfold loopCount
    rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro σ _ h
    have hle : Multiset.card σ.partition.parts • 1 ≤ σ.partition.parts.sum :=
      Multiset.card_nsmul_le_sum (fun x hx => σ.partition.parts_pos hx)
    rw [σ.partition.parts_sum, h, Fintype.card_fin] at hle
    simp at hle
    omega
  · intro n k
    unfold loopCount
    simp only [Finset.card_filter]
    rw [← (Perm.decomposeFin (n := n)).symm.sum_comp, Fintype.sum_prod_type, Fin.sum_univ_succ]
    simp only [loops_card_decompose, Fin.succ_ne_zero, ite_true, ite_false, Nat.add_right_cancel_iff]
    rw [Finset.sum_const, Finset.card_fin, smul_eq_mul]
    ring

/-- Counting one cycle type. For any finite set of hooks `α` with `n` members and any way `p`
of breaking `n` into loop lengths (parts equal to 1 included), the rehangs whose loop lengths
are exactly `p` number `n!` divided by the product, over each length `j` that occurs, of
`j ^ a_j × a_j!`, where `a_j` is how many loops have length `j`. Stated as a product so that the
division is shown to be exact. -/
theorem card_rehangs_of_cycle_type {α : Type*} [Fintype α] [DecidableEq α]
    (p : (Fintype.card α).Partition) :
    #{σ : Perm α | σ.partition = p} *
        ∏ j ∈ p.parts.toFinset, (j ^ p.parts.count j * (p.parts.count j).factorial) =
      (Fintype.card α).factorial := by
  set m := p.parts.filter (fun n => 2 ≤ n) with hm
  set r := p.parts.filter (fun n => ¬ 2 ≤ n) with hr
  have hr1 : r = Multiset.replicate (Multiset.card r) 1 := Multiset.eq_replicate_card.mpr (by
    intro b hb
    rw [hr, Multiset.mem_filter] at hb
    have := p.parts_pos hb.1
    omega)
  have hsum : m.sum + Multiset.card r = Fintype.card α := by
    rw [← p.parts_sum, ← Multiset.filter_add_not (fun n => 2 ≤ n) p.parts, Multiset.sum_add]
    congr 1
    rw [← hr, hr1]
    simp
  have hiff : ∀ σ : Perm α, σ.partition = p ↔ σ.cycleType = m := by
    intro σ
    constructor
    · rintro rfl
      exact Perm.filter_parts_partition_eq_cycleType.symm
    · intro h
      apply Nat.Partition.ext
      have hsupp : m.sum = #σ.support := by rw [← h, Perm.sum_cycleType]
      have : Fintype.card α - #σ.support = Multiset.card r := by omega
      rw [Perm.parts_partition, h, this, ← hr1, hm, hr, Multiset.filter_add_not]
  have hcard : #{σ : Perm α | σ.partition = p} = #{g : Perm α | g.cycleType = m} := by
    congr 1
    ext σ
    simp [hiff]
  have hcond : m.sum ≤ Fintype.card α ∧ ∀ a ∈ m, 2 ≤ a := by
    refine ⟨by omega, fun a ha => ?_⟩
    rw [hm, Multiset.mem_filter] at ha
    exact ha.2
  have key := Perm.card_of_cycleType_mul_eq (α := α) m
  rw [ite_eq_left_iff.mpr (fun h => absurd hcond h)] at key
  rw [hcard, ← key]
  congr 1
  have hsub : p.parts.toFinset ⊆ insert 1 m.toFinset := by
    intro x hx
    rw [Multiset.mem_toFinset] at hx
    rw [Finset.mem_insert, Multiset.mem_toFinset, hm, Multiset.mem_filter]
    have := p.parts_pos hx
    by_cases h2 : 2 ≤ x
    · exact Or.inr ⟨hx, h2⟩
    · left; omega
  rw [Finset.prod_subset hsub (fun x _ hx => by
    rw [Multiset.mem_toFinset, ← Multiset.count_eq_zero] at hx
    simp [hx])]
  have h1m : 1 ∉ m.toFinset := by
    rw [Multiset.mem_toFinset, hm, Multiset.mem_filter]
    omega
  rw [Finset.prod_insert h1m]
  have hc1 : p.parts.count 1 = Multiset.card r := by
    have : r.count 1 = p.parts.count 1 := by
      rw [hr, Multiset.count_filter_of_pos (by omega)]
    rw [← this, hr1]
    simp
  have hcm : ∀ j ∈ m.toFinset, p.parts.count j = m.count j := by
    intro j hj
    rw [Multiset.mem_toFinset, hm, Multiset.mem_filter] at hj
    rw [hm, Multiset.count_filter_of_pos hj.2]
  rw [Finset.prod_congr rfl (fun j hj => by rw [hcm j hj]), Finset.prod_mul_distrib,
    ← Finset.prod_multiset_count, hc1, show Fintype.card α - m.sum = Multiset.card r by omega]
  simp [mul_assoc]

/-- Derangements are the no-short-loop case: a rehang leaves no key on its own hook exactly
when its trace has no loop of length 1. -/
theorem derangement_iff_no_loop_of_length_one {α : Type*} [Fintype α] [DecidableEq α]
    (σ : Perm α) :
    σ ∈ derangements α ↔ 1 ∉ σ.partition.parts := by
  change (∀ x, σ x ≠ x) ↔ _
  rw [Perm.parts_partition, Multiset.mem_add, Multiset.mem_replicate]
  have h1 : 1 ∉ σ.cycleType := fun h => by
    have := Perm.two_le_of_mem_cycleType h
    omega
  have hiff : (∀ x, σ x ≠ x) ↔ #σ.support = Fintype.card α := by
    rw [Finset.card_eq_iff_eq_univ, Finset.eq_univ_iff_forall]
    simp
  have hle := σ.support.card_le_univ
  rw [hiff]
  constructor
  · intro h
    simp [h1, h]
  · intro h
    simp [h1] at h
    omega

-- Hooks 1 to 5 on the card are 0 to 4 here.
-- The traced rehang: destination list 3 5 1 4 2, the trades (1 3) and (2 5) with hook 4 kept.
example : List.ofFn (⇑(Equiv.swap (0 : Fin 5) 2 * Equiv.swap 1 4 : Perm (Fin 5))) =
    [2, 4, 0, 3, 1] := by
  decide
-- And the rehang 2 3 4 5 1.
example : List.ofFn (⇑(finRotate 5)) = [1, 2, 3, 4, 0] := by decide
-- Its loops have lengths 2, 2 and 1: three loops.
example : (Equiv.swap (0 : Fin 5) 2 * Equiv.swap 1 4).partition.parts = {2, 2, 1} := by decide
-- The rehang 2 3 4 5 1 is one loop of length 5.
example : (finRotate 5).partition.parts = {5} := by decide
-- Rows three and four of the triangle: 2, 3, 1 and 6, 11, 6, 1.
example : loopCount 3 1 = 2 ∧ loopCount 3 2 = 3 ∧ loopCount 3 3 = 1 := by decide
example : loopCount 4 1 = 6 ∧ loopCount 4 2 = 11 ∧ loopCount 4 3 = 6 ∧ loopCount 4 4 = 1 := by
  decide
-- Row five, by listing all 120 rehangs: 24, 50, 35, 10, 1.
example : loopCount 5 1 = 24 ∧ loopCount 5 2 = 50 ∧ loopCount 5 3 = 35 ∧ loopCount 5 4 = 10 ∧
    loopCount 5 5 = 1 := by
  decide
-- Row five from row four by the recurrence: 4 × 6, 4 × 11 + 6, 4 × 6 + 11, 4 × 1 + 6, then 1.
example : 4 * 6 = 24 ∧ 4 * 11 + 6 = 50 ∧ 4 * 6 + 11 = 35 ∧ 4 * 1 + 6 = 10 := by decide
-- The row adds to every rehang: 24 + 50 + 35 + 10 + 1 = 120 = 5!.
example : 24 + 50 + 35 + 10 + 1 = Nat.factorial 5 ∧ Nat.factorial 5 = 5 * 4 * 3 * 2 * 1 ∧
    Fintype.card (Perm (Fin 5)) = 120 := by
  decide
-- The corners: c(5, 1) = 4! = 24 and c(5, 4) = C(5, 2) = 10.
example : Nat.factorial 4 = 24 ∧ Nat.choose 5 2 = 10 := by decide
-- The seven cycle types of five: 5!/5 = 24, 5!/4 = 30, 5!/(3 × 2) = 20, 5!/(3 × 2!) = 20,
-- 5!/(2² × 2!) = 15, 5!/(2 × 3!) = 10, 5!/5! = 1.
example : Nat.factorial 5 / 5 = 24 ∧ Nat.factorial 5 / (4 * 1) = 30 ∧
    Nat.factorial 5 / (3 * 2) = 20 ∧ Nat.factorial 5 / (3 * Nat.factorial 2) = 20 ∧
    Nat.factorial 5 / (2 ^ 2 * Nat.factorial 2 * 1 ^ 1 * Nat.factorial 1) = 15 ∧
    Nat.factorial 5 / (2 * Nat.factorial 3) = 10 ∧ Nat.factorial 5 / Nat.factorial 5 = 1 := by
  decide
-- Type 2 + 2 + 1 holds 15 rehangs, counted directly.
example : #{σ : Perm (Fin 5) | σ.partition.parts = {2, 2, 1}} = 15 := by decide
-- By number of loops: 24; 30 + 20 = 50; 20 + 15 = 35; 10; 1.
example : 30 + 20 = 50 ∧ 20 + 15 = 35 := by decide
-- No loop of length 1: types 5 and 3 + 2, 24 + 20 = 44, the derangements of five keys.
example : 24 + 20 = 44 ∧ numDerangements 5 = 44 := by decide
example : Fintype.card (derangements (Fin 5)) = 44 := by decide
example : #{σ : Perm (Fin 5) | 1 ∉ σ.partition.parts} = 44 := by decide
-- The usual mistakes: the multiplier read as the loop count gives 3 × 6 + 11 = 29, not 35;
-- blocks instead of loops give S(5, 3) = 25.
example : 3 * 6 + 11 = 29 ∧ Nat.stirlingSecond 5 3 = 25 := by decide

#print axioms loops_card_eq
#print axioms loops_card_swap_mul
#print axioms loops_card_lift
#print axioms loops_card_decompose
#print axioms loop_counts_obey_stirling_first_recurrence
#print axioms card_rehangs_of_cycle_type
#print axioms derangement_iff_no_loop_of_length_one
