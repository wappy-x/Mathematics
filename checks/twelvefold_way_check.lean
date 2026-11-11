-- The twelvefold way: for every n ≥ 1 things and k ≥ 1 boxes, each of the twelve ways of putting the things into the boxes (things named or not, boxes named or not, any number, at most one or at least one per box) is counted by its formula in the card's table.
import Mathlib.Combinatorics.Enumerative.Stirling
import Mathlib.Combinatorics.Enumerative.Partition.Basic
import Mathlib.Order.Partition.Finpartition
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Vector
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.GroupTheory.Perm.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Sym.Card
import Mathlib.Data.Fintype.CardEmbedding
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Finset.Sort

open Finset

-- Helper lemmas for the proofs below.

theorem tw_pow_sum (n k : ℕ) :
    k ^ n = ∑ j ∈ range (k + 1), Nat.choose k j * j.factorial * Nat.stirlingSecond n j := by
  rw [Nat.pow_eq_sum_stirlingSecond_mul_descFactorial]
  have h1 : ∑ j ∈ range (n + 1), Nat.stirlingSecond n j * k.descFactorial j =
      ∑ j ∈ range (n + k + 1), Nat.stirlingSecond n j * k.descFactorial j := by
    apply Finset.sum_subset
    · intro j hj; simp only [mem_range] at hj ⊢; omega
    · intro j _ hj
      simp only [mem_range, not_lt] at hj
      rw [Nat.stirlingSecond_eq_zero_of_lt (by omega), zero_mul]
  have h2 : ∑ j ∈ range (k + 1), Nat.choose k j * j.factorial * Nat.stirlingSecond n j =
      ∑ j ∈ range (n + k + 1), Nat.choose k j * j.factorial * Nat.stirlingSecond n j := by
    apply Finset.sum_subset
    · intro j hj; simp only [mem_range] at hj ⊢; omega
    · intro j _ hj
      simp only [mem_range, not_lt] at hj
      rw [Nat.choose_eq_zero_of_lt (by omega)]; simp
  rw [h1, h2]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [Nat.descFactorial_eq_factorial_mul_choose]; ring

theorem tw_image_count (n : ℕ) {k : ℕ} (T : Finset (Fin k)) :
    #{f : Fin n → Fin k | univ.image f = T} = #{g : Fin n → Fin #T | Function.Surjective g} := by
  set e := T.orderEmbOfFin rfl with he
  have hr : ∀ y, y ∈ T ↔ ∃ t, e t = y := by
    intro y
    have := congrArg (y ∈ ·) (T.range_orderEmbOfFin rfl)
    simp only [Set.mem_range, mem_coe, eq_iff_iff] at this
    exact this.symm
  symm
  refine Finset.card_bij (fun g _ => fun x => e (g x)) ?_ ?_ ?_
  · intro g hg
    have hg' : Function.Surjective g := (mem_filter.1 hg).2
    simp only [mem_filter, mem_univ, true_and]
    ext y
    simp only [mem_image, mem_univ, true_and]
    constructor
    · rintro ⟨x, rfl⟩; exact (hr _).2 ⟨g x, rfl⟩
    · intro hy
      obtain ⟨t, rfl⟩ := (hr y).1 hy
      obtain ⟨x, rfl⟩ := hg' t
      exact ⟨x, rfl⟩
  · intro g _ g' _ h
    funext x
    exact e.injective (congrFun h x)
  · intro f hf
    have hf' : univ.image f = T := (mem_filter.1 hf).2
    have hx : ∀ x, ∃ t, e t = f x := fun x =>
      (hr _).1 (hf' ▸ mem_image_of_mem f (mem_univ x))
    refine ⟨fun x => (hx x).choose, ?_, ?_⟩
    · simp only [mem_filter, mem_univ, true_and]
      intro t
      have : e t ∈ univ.image f := hf' ▸ (hr _).2 ⟨t, rfl⟩
      obtain ⟨x, -, hxt⟩ := mem_image.1 this
      refine ⟨x, e.injective ?_⟩
      rw [(hx x).choose_spec, hxt]
    · funext x
      exact (hx x).choose_spec

theorem tw_pow_surj (n k : ℕ) :
    k ^ n = ∑ j ∈ range (k + 1),
      Nat.choose k j * #{g : Fin n → Fin j | Function.Surjective g} := by
  have h1 : k ^ n = #(univ : Finset (Fin n → Fin k)) := by simp
  rw [h1, card_eq_sum_card_fiberwise (f := fun f => univ.image f)
    (t := (univ : Finset (Fin k)).powerset) (by intro f _; simp)]
  have h2 := sum_powerset_apply_card (fun j => #{g : Fin n → Fin j | Function.Surjective g})
    (x := (univ : Finset (Fin k)))
  simp only [card_univ, Fintype.card_fin, smul_eq_mul] at h2
  rw [← h2]
  exact sum_congr rfl fun T _ => tw_image_count n T

theorem tw_surj (n k : ℕ) :
    #{f : Fin n → Fin k | Function.Surjective f} = k.factorial * Nat.stirlingSecond n k := by
  induction k using Nat.strong_induction_on with
  | _ k ih =>
    have h1 := tw_pow_surj n k
    have h2 := tw_pow_sum n k
    rw [sum_range_succ, Nat.choose_self, one_mul] at h1
    rw [sum_range_succ, Nat.choose_self, one_mul] at h2
    have h3 : ∑ j ∈ range k, Nat.choose k j * #{g : Fin n → Fin j | Function.Surjective g} =
        ∑ j ∈ range k, Nat.choose k j * j.factorial * Nat.stirlingSecond n j :=
      sum_congr rfl fun j hj => by rw [ih j (mem_range.1 hj), mul_assoc]
    omega

/-- The fibers of a map, as an equivalence relation. -/
def twSetoid {n k : ℕ} (f : Fin n → Fin k) : Setoid (Fin n) :=
  ⟨fun a b => f a = f b, ⟨fun _ => rfl, fun h => h.symm, fun h1 h2 => h1.trans h2⟩⟩

instance twSetoidDec {n k : ℕ} (f : Fin n → Fin k) : DecidableRel (twSetoid f).r :=
  fun a b => inferInstanceAs (Decidable (f a = f b))

/-- The grouping of the things made by a loading: things in the same box form a group. -/
def twPartOf {n k : ℕ} (f : Fin n → Fin k) : Finpartition (univ : Finset (Fin n)) :=
  Finpartition.ofSetoid (twSetoid f)

theorem tw_mem_part {n k : ℕ} (f : Fin n → Fin k) (a b : Fin n) :
    b ∈ (twPartOf f).part a ↔ f a = f b :=
  Finpartition.mem_part_ofSetoid_iff_rel

theorem tw_part_eq {n k : ℕ} (f : Fin n → Fin k) (a b : Fin n) :
    (twPartOf f).part a = (twPartOf f).part b ↔ f a = f b := by
  rw [← (twPartOf f).mem_part_iff_part_eq_part (mem_univ a) (mem_univ b), tw_mem_part]
  exact eq_comm

theorem tw_mem_parts_iff {α : Type*} [Fintype α] [DecidableEq α]
    (R : Finpartition (univ : Finset α)) (t : Finset α) :
    t ∈ R.parts ↔ ∃ a, R.part a = t := by
  constructor
  · intro ht
    obtain ⟨a, ha⟩ := R.nonempty_of_mem_parts ht
    exact ⟨a, R.part_eq_of_mem ht ha⟩
  · rintro ⟨a, rfl⟩
    exact R.part_mem.2 (mem_univ a)

theorem tw_fp_eq {α : Type*} [Fintype α] [DecidableEq α] (P Q : Finpartition (univ : Finset α))
    (h : ∀ a, P.part a = Q.part a) : P = Q := by
  ext t
  rw [tw_mem_parts_iff P, tw_mem_parts_iff Q]
  simp only [h]

theorem tw_card_parts {n k : ℕ} (f : Fin n → Fin k) (hf : Function.Surjective f) :
    #(twPartOf f).parts = k := by
  suffices h : #(univ : Finset (Fin k)) = #(twPartOf f).parts by simpa using h.symm
  refine Finset.card_bij (fun c _ => (twPartOf f).part (hf c).choose) ?_ ?_ ?_
  · intro c _
    exact (twPartOf f).part_mem.2 (mem_univ _)
  · intro c _ c' _ h
    rw [tw_part_eq, (hf c).choose_spec, (hf c').choose_spec] at h
    exact h
  · intro t ht
    obtain ⟨a, rfl⟩ := (tw_mem_parts_iff _ t).1 ht
    refine ⟨f a, mem_univ _, ?_⟩
    rw [tw_part_eq, (hf (f a)).choose_spec]

theorem tw_fiber {n k : ℕ} (P : Finpartition (univ : Finset (Fin n))) (hP : #P.parts = k) :
    #{f : Fin n → Fin k | Function.Surjective f ∧ twPartOf f = P} = k.factorial := by
  have hcard : Fintype.card P.parts = k := by simp [hP]
  have e0 : P.parts ≃ Fin k := Fintype.equivFinOfCardEq hcard
  rw [show k.factorial = Fintype.card (P.parts ≃ Fin k) by rw [Fintype.card_equiv e0, hcard],
    ← card_univ]
  have hpm : ∀ x, P.part x ∈ P.parts := fun x => P.part_mem.2 (mem_univ x)
  symm
  refine Finset.card_bij (fun e _ => fun x => e ⟨P.part x, hpm x⟩) ?_ ?_ ?_
  · intro e _
    simp only [mem_filter, mem_univ, true_and]
    constructor
    · intro c
      obtain ⟨a, ha⟩ := P.nonempty_of_mem_parts (e.symm c).2
      refine ⟨a, ?_⟩
      have : (⟨P.part a, hpm a⟩ : P.parts) = e.symm c :=
        Subtype.ext (P.part_eq_of_mem (e.symm c).2 ha)
      simp [this]
    · apply tw_fp_eq
      intro a
      ext b
      rw [tw_mem_part, P.mem_part_iff_part_eq_part (mem_univ b) (mem_univ a), e.apply_eq_iff_eq,
        Subtype.mk.injEq]
      exact eq_comm
  · intro e _ e' _ h
    apply Equiv.ext
    rintro ⟨t, ht⟩
    obtain ⟨a, ha⟩ := P.nonempty_of_mem_parts ht
    have h1 := congrFun h a
    have h2 : (⟨P.part a, hpm a⟩ : P.parts) = ⟨t, ht⟩ := Subtype.ext (P.part_eq_of_mem ht ha)
    simp only [h2] at h1
    exact h1
  · intro f hf
    simp only [mem_filter, mem_univ, true_and] at hf
    obtain ⟨hfs, hfP⟩ := hf
    have key : ∀ a b, f a = f b ↔ P.part a = P.part b := by
      intro a b; rw [← tw_part_eq, hfP]
    let g : P.parts → Fin k := fun t => f (P.nonempty_of_mem_parts t.2).choose
    have hg : ∀ t : P.parts, ∀ a ∈ (t : Finset (Fin n)), g t = f a := by
      intro t a ha
      have hy := (P.nonempty_of_mem_parts t.2).choose_spec
      rw [key, P.part_eq_of_mem t.2 hy, P.part_eq_of_mem t.2 ha]
    have hgb : Function.Bijective g := by
      constructor
      · rintro ⟨t, ht⟩ ⟨t', ht'⟩ h
        obtain ⟨a, ha⟩ := P.nonempty_of_mem_parts ht
        obtain ⟨a', ha'⟩ := P.nonempty_of_mem_parts ht'
        rw [hg _ a ha, hg _ a' ha', key, P.part_eq_of_mem ht ha, P.part_eq_of_mem ht' ha'] at h
        exact Subtype.ext h
      · intro c
        obtain ⟨a, rfl⟩ := hfs c
        exact ⟨⟨P.part a, hpm a⟩, hg _ a (P.mem_part (mem_univ a))⟩
    refine ⟨Equiv.ofBijective g hgb, mem_univ _, ?_⟩
    funext x
    exact hg _ x (P.mem_part (mem_univ x))

theorem tw_surj_eq (n k : ℕ) :
    #{f : Fin n → Fin k | Function.Surjective f} =
      #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k} * k.factorial := by
  rw [card_eq_sum_card_fiberwise (f := twPartOf)
    (t := {P : Finpartition (univ : Finset (Fin n)) | #P.parts = k})]
  · rw [sum_const_nat]
    intro P hP
    rw [filter_filter]
    exact tw_fiber P (mem_filter.1 hP).2
  · intro f hf
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hf ⊢
    exact tw_card_parts f hf

theorem tw_fp_count (n k : ℕ) :
    #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k} = Nat.stirlingSecond n k := by
  have h := (tw_surj_eq n k).symm.trans (tw_surj n k)
  rw [mul_comm] at h
  exact Nat.eq_of_mul_eq_mul_left (Nat.factorial_pos k) h

theorem tw_fp_atmost (n k : ℕ) (hn : 0 < n) :
    #{P : Finpartition (univ : Finset (Fin n)) | #P.parts ≤ k} =
      ∑ j ∈ Icc 1 k, Nat.stirlingSecond n j := by
  rw [card_eq_sum_card_fiberwise (f := fun P : Finpartition (univ : Finset (Fin n)) => #P.parts)
    (t := Icc 1 k)]
  · refine sum_congr rfl fun j hj => ?_
    rw [filter_filter, ← tw_fp_count n j]
    congr 1
    refine filter_congr fun P _ => ?_
    have := (mem_Icc.1 hj).2
    constructor
    · exact fun h => h.2
    · intro h; exact ⟨by omega, h⟩
  · intro P hP
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq, coe_Icc, Set.mem_Icc] at hP ⊢
    refine ⟨?_, hP⟩
    have hne : (univ : Finset (Fin n)) ≠ ⊥ := by
      rw [bot_eq_empty, ← nonempty_iff_ne_empty, univ_nonempty_iff]
      exact ⟨⟨0, hn⟩⟩
    exact card_pos.2 (P.parts_nonempty hne)

theorem tw_fp_ones (n k : ℕ) :
    #{P : Finpartition (univ : Finset (Fin n)) | #P.parts ≤ k ∧ ∀ b ∈ P.parts, #b ≤ 1} =
      (if n ≤ k then 1 else 0) := by
  have hbot : ∀ P : Finpartition (univ : Finset (Fin n)), (∀ b ∈ P.parts, #b ≤ 1) → P = ⊥ := by
    intro P hP
    apply tw_fp_eq
    intro a
    have h1 : P.part a = {a} := by
      rw [eq_singleton_iff_unique_mem]
      refine ⟨P.mem_part (mem_univ a), fun b hb => ?_⟩
      exact card_le_one.1 (hP _ (P.part_mem.2 (mem_univ a))) b hb a (P.mem_part (mem_univ a))
    have h2 : (⊥ : Finpartition (univ : Finset (Fin n))).part a = {a} :=
      Finpartition.part_eq_of_mem _ (Finpartition.mem_bot_iff.2 ⟨a, mem_univ a, rfl⟩)
        (mem_singleton_self a)
    rw [h1, h2]
  have hbotc : #(⊥ : Finpartition (univ : Finset (Fin n))).parts = n := by
    rw [Finpartition.card_bot, card_univ, Fintype.card_fin]
  have hbot1 : ∀ b ∈ (⊥ : Finpartition (univ : Finset (Fin n))).parts, #b ≤ 1 := by
    intro b hb
    obtain ⟨a, -, rfl⟩ := Finpartition.mem_bot_iff.1 hb
    simp
  split_ifs with hnk
  · rw [card_eq_one]
    refine ⟨⊥, ?_⟩
    ext P
    simp only [mem_filter, mem_univ, true_and, mem_singleton]
    constructor
    · exact fun h => hbot P h.2
    · rintro rfl; exact ⟨by rw [hbotc]; exact hnk, hbot1⟩
  · rw [card_eq_zero, filter_eq_empty_iff]
    rintro P - ⟨h1, h2⟩
    rw [hbot P h2, hbotc] at h1
    exact hnk h1

theorem tw_sym_card (n k : ℕ) (hk : 0 < k) :
    Fintype.card (Sym (Fin k) n) = Nat.choose (n + k - 1) (k - 1) := by
  rw [Sym.card_sym_eq_choose, Fintype.card_fin]
  obtain ⟨k, rfl⟩ : ∃ k', k = k' + 1 := ⟨k - 1, by omega⟩
  rw [show k + 1 + n - 1 = n + k by omega, show n + (k + 1) - 1 = n + k by omega,
    Nat.add_sub_cancel, Nat.choose_symm_add]

theorem tw_sym_nodup (n k : ℕ) :
    #{s : Sym (Fin k) n | (s : Multiset (Fin k)).Nodup} = Nat.choose k n := by
  have : Nat.choose k n = #(powersetCard n (univ : Finset (Fin k))) := by
    rw [card_powersetCard, card_univ, Fintype.card_fin]
  rw [this]
  refine Finset.card_bij (fun s hs => ⟨(s : Multiset (Fin k)), (mem_filter.1 hs).2⟩) ?_ ?_ ?_
  · intro s hs
    simp only [mem_powersetCard, subset_univ, true_and]
    exact s.2
  · intro s _ t _ h
    have := congrArg Finset.val h
    exact Sym.coe_injective this
  · intro T hT
    exact ⟨⟨T.val, (mem_powersetCard.1 hT).2⟩, mem_filter.2 ⟨mem_univ _, T.nodup⟩, rfl⟩

theorem tw_sym_onto (n k : ℕ) (hn : 0 < n) (hk : 0 < k) :
    #{s : Sym (Fin k) n | ∀ i : Fin k, i ∈ s} = Nat.choose (n - 1) (k - 1) := by
  rcases lt_or_ge n k with hnk | hnk
  · rw [Nat.choose_eq_zero_of_lt (show n - 1 < k - 1 by omega), Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro s _ h
    have hsub : (univ : Finset (Fin k)) ⊆ (s : Multiset (Fin k)).toFinset := by
      intro i _; simpa using h i
    have := Finset.card_le_card hsub
    rw [card_univ, Fintype.card_fin] at this
    have h2 := Multiset.toFinset_card_le (s : Multiset (Fin k))
    have h3 : Multiset.card (s : Multiset (Fin k)) = n := s.2
    omega
  · have hc : Nat.choose (n - 1) (k - 1) = Fintype.card (Sym (Fin k) (n - k)) := by
      rw [Sym.card_sym_eq_choose, Fintype.card_fin,
        show k + (n - k) - 1 = n - 1 by omega, ← Nat.choose_symm (by omega : k - 1 ≤ n - 1),
        show n - 1 - (k - 1) = n - k by omega]
    rw [hc, ← card_univ]
    symm
    refine Finset.card_bij (fun t _ => Sym.mk ((t : Multiset (Fin k)) + (univ : Finset (Fin k)).val)
      (by rw [Multiset.card_add, Sym.card_coe, Finset.card_val, card_univ, Fintype.card_fin]; omega)) ?_ ?_ ?_
    · intro t _
      simp only [mem_filter, mem_univ, true_and]
      intro i
      show i ∈ (t : Multiset (Fin k)) + (univ : Finset (Fin k)).val
      simp
    · intro s _ t _ h
      have := congrArg (fun x : Sym (Fin k) n => (x : Multiset (Fin k))) h
      exact Sym.coe_injective (add_right_cancel this)
    · intro s hs
      simp only [mem_filter, mem_univ, true_and] at hs
      have hle : (univ : Finset (Fin k)).val ≤ (s : Multiset (Fin k)) := by
        rw [Multiset.le_iff_subset (Finset.nodup _)]
        intro i _; exact hs i
      refine ⟨Sym.mk ((s : Multiset (Fin k)) - (univ : Finset (Fin k)).val) ?_, mem_univ _, ?_⟩
      · rw [Multiset.card_sub hle, Sym.card_coe, Finset.card_val, card_univ, Fintype.card_fin]
      · apply Sym.coe_injective
        show (s : Multiset (Fin k)) - (univ : Finset (Fin k)).val + (univ : Finset (Fin k)).val = s
        exact tsub_add_cancel_of_le hle

theorem tw_inj (n k : ℕ) :
    #{f : Fin n → Fin k | Function.Injective f} = k.descFactorial n := by
  have := Fintype.card_embedding_eq (α := Fin n) (β := Fin k)
  simp only [Fintype.card_fin] at this
  rw [← this, ← card_univ]
  symm
  refine Finset.card_bij (fun e _ => ⇑e) ?_ ?_ ?_
  · intro e _; simpa using e.injective
  · intro e _ e' _ h; exact DFunLike.coe_injective h
  · intro f hf
    exact ⟨⟨f, (mem_filter.1 hf).2⟩, mem_univ _, rfl⟩

theorem tw_lift (n : ℕ) (m : Multiset ℕ) (h : ∀ x ∈ m, x ≤ n) :
    ∃ t : Multiset (Fin (n + 1)), t.map Fin.val = m := by
  induction m using Multiset.induction_on with
  | empty => exact ⟨0, rfl⟩
  | cons a m ih =>
    obtain ⟨t, ht⟩ := ih (fun x hx => h x (Multiset.mem_cons_of_mem hx))
    have ha : a < n + 1 := by have := h a (Multiset.mem_cons_self a m); omega
    exact ⟨⟨a, ha⟩ ::ₘ t, by simp [ht]⟩

theorem tw_vm_inj {n k : ℕ} {s t : Sym (Fin (n + 1)) k}
    (h : (s : Multiset (Fin (n + 1))).map Fin.val = (t : Multiset (Fin (n + 1))).map Fin.val) :
    s = t :=
  Sym.coe_injective (Multiset.map_injective Fin.val_injective h)

theorem tw_split_zeros (m : Multiset ℕ) :
    m = m.filter (· ≠ 0) + Multiset.replicate
      (Multiset.card m - Multiset.card (m.filter (· ≠ 0))) 0 := by
  have h := Multiset.filter_add_not (· ≠ 0) m
  have hz : m.filter (fun a => ¬ a ≠ 0) =
      Multiset.replicate (Multiset.card (m.filter (fun a => ¬ a ≠ 0))) 0 := by
    rw [Multiset.eq_replicate_card]
    intro b hb
    simpa using (Multiset.mem_filter.1 hb).2
  have hc := congrArg Multiset.card h
  rw [Multiset.card_add] at hc
  rw [hz] at h
  conv_lhs => rw [← h]
  congr 2
  omega

theorem tw_sum_filter (m : Multiset ℕ) : (m.filter (· ≠ 0)).sum = m.sum := by
  conv_rhs => rw [tw_split_zeros m]
  simp

theorem tw_le_of_mem_parts {n : ℕ} (p : Nat.Partition n) {x : ℕ} (hx : x ∈ p.parts) : x ≤ n := by
  have := Multiset.le_sum_of_mem hx
  rwa [p.parts_sum] at this

theorem tw_part_exact (n k : ℕ) :
    #{s : Sym (Fin (n + 1)) k | ((s : Multiset (Fin (n + 1))).map Fin.val).sum = n ∧
      ∀ i ∈ s, 1 ≤ i.val} = #{p : Nat.Partition n | Multiset.card p.parts = k} := by
  refine Finset.card_bij (fun s hs => ⟨(s : Multiset (Fin (n + 1))).map Fin.val, fun {i} hi => by
      obtain ⟨j, hj, rfl⟩ := Multiset.mem_map.1 hi
      exact (mem_filter.1 hs).2.2 j (Sym.mem_coe.1 hj), (mem_filter.1 hs).2.1⟩) ?_ ?_ ?_
  · intro s _
    simp [Sym.card_coe]
  · intro s _ t _ h
    exact tw_vm_inj (congrArg Nat.Partition.parts h)
  · intro p hp
    obtain ⟨t, ht⟩ := tw_lift n p.parts (fun x hx => tw_le_of_mem_parts p hx)
    have hct : Multiset.card t = k := by
      rw [← Multiset.card_map Fin.val t, ht]; exact (mem_filter.1 hp).2
    refine ⟨Sym.mk t hct, ?_, ?_⟩
    · simp only [mem_filter, mem_univ, true_and, Sym.coe_mk]
      refine ⟨by rw [ht, p.parts_sum], fun i hi => ?_⟩
      have : i.val ∈ p.parts := by
        rw [← ht]; exact Multiset.mem_map_of_mem _ (Sym.mem_coe.2 hi)
      exact p.parts_pos this
    · ext1; simp [ht]

theorem tw_part_atmost (n k : ℕ) :
    #{s : Sym (Fin (n + 1)) k | ((s : Multiset (Fin (n + 1))).map Fin.val).sum = n} =
      #{p : Nat.Partition n | Multiset.card p.parts ≤ k} := by
  refine Finset.card_bij (fun s hs =>
    ⟨((s : Multiset (Fin (n + 1))).map Fin.val).filter (· ≠ 0), fun {i} hi => by
      have := (Multiset.mem_filter.1 hi).2; omega,
      by rw [tw_sum_filter]; exact (mem_filter.1 hs).2⟩) ?_ ?_ ?_
  · intro s _
    simp only [mem_filter, mem_univ, true_and]
    calc _ ≤ Multiset.card ((s : Multiset (Fin (n + 1))).map Fin.val) :=
          Multiset.card_le_card (Multiset.filter_le _ _)
      _ = k := by simp [Sym.card_coe]
  · intro s _ t _ h
    apply tw_vm_inj
    have h' := congrArg Nat.Partition.parts h
    simp only at h'
    rw [tw_split_zeros ((s : Multiset (Fin (n + 1))).map Fin.val),
      tw_split_zeros ((t : Multiset (Fin (n + 1))).map Fin.val), h']
    simp [Sym.card_coe]
  · intro p hp
    have hp' : Multiset.card p.parts ≤ k := (mem_filter.1 hp).2
    obtain ⟨t, ht⟩ := tw_lift n (p.parts + Multiset.replicate (k - Multiset.card p.parts) 0)
      (fun x hx => by
        rcases Multiset.mem_add.1 hx with hx | hx
        · exact tw_le_of_mem_parts p hx
        · rw [Multiset.eq_of_mem_replicate hx]; omega)
    have hct : Multiset.card t = k := by
      rw [← Multiset.card_map Fin.val t, ht]; simp; omega
    refine ⟨Sym.mk t hct, ?_, ?_⟩
    · simp only [mem_filter, mem_univ, true_and, Sym.coe_mk]
      rw [ht]; simp [p.parts_sum]
    · ext1
      simp only [Sym.coe_mk, ht]
      rw [Multiset.filter_add, Multiset.filter_eq_self.2, Multiset.filter_eq_nil.2]
      · simp
      · intro a ha; simp [Multiset.eq_of_mem_replicate ha]
      · intro a ha; have := p.parts_pos ha; omega

theorem tw_part_ones (n k : ℕ) :
    #{s : Sym (Fin (n + 1)) k | ((s : Multiset (Fin (n + 1))).map Fin.val).sum = n ∧
      ∀ i ∈ s, i.val ≤ 1} = (if n ≤ k then 1 else 0) := by
  -- every such loading reads n ones and k - n zeros
  have key : ∀ s : Sym (Fin (n + 1)) k,
      ((s : Multiset (Fin (n + 1))).map Fin.val).sum = n → (∀ i ∈ s, i.val ≤ 1) →
      n ≤ k ∧ (s : Multiset (Fin (n + 1))).map Fin.val =
        Multiset.replicate n 1 + Multiset.replicate (k - n) 0 := by
    intro s hsum hle
    set m := (s : Multiset (Fin (n + 1))).map Fin.val with hm
    have hcard : Multiset.card m = k := by simp [hm, Sym.card_coe]
    have hones : m.filter (· ≠ 0) =
        Multiset.replicate (Multiset.card (m.filter (· ≠ 0))) 1 := by
      rw [Multiset.eq_replicate_card]
      intro b hb
      obtain ⟨hb1, hb2⟩ := Multiset.mem_filter.1 hb
      obtain ⟨j, hj, rfl⟩ := Multiset.mem_map.1 hb1
      have := hle j (Sym.mem_coe.1 hj)
      omega
    have hsplit := tw_split_zeros m
    have hc : Multiset.card (m.filter (· ≠ 0)) = n := by
      have := tw_sum_filter m
      rw [hones, hsum] at this
      simpa using this
    have hc2 := Multiset.card_le_card (Multiset.filter_le (· ≠ 0) m)
    refine ⟨by omega, ?_⟩
    rw [hsplit, hones, hc, hcard, Multiset.card_replicate]
  split_ifs with hnk
  · obtain ⟨t, ht⟩ := tw_lift n (Multiset.replicate n 1 + Multiset.replicate (k - n) 0)
      (fun x hx => by
        rcases Multiset.mem_add.1 hx with hx | hx
        · have := Multiset.mem_replicate.1 hx; omega
        · have := Multiset.mem_replicate.1 hx; omega)
    have hct : Multiset.card t = k := by
      rw [← Multiset.card_map Fin.val t, ht]; simp; omega
    rw [Finset.card_eq_one]
    refine ⟨Sym.mk t hct, ?_⟩
    ext s
    simp only [mem_filter, mem_univ, true_and, mem_singleton]
    constructor
    · rintro ⟨h1, h2⟩
      apply tw_vm_inj
      rw [(key s h1 h2).2]
      simp [ht]
    · rintro rfl
      simp only [Sym.coe_mk, ht]
      refine ⟨by simp, fun i hi => ?_⟩
      have : i.val ∈ Multiset.replicate n 1 + Multiset.replicate (k - n) 0 := by
        rw [← ht]; exact Multiset.mem_map_of_mem _ (Sym.mem_coe.2 hi)
      rcases Multiset.mem_add.1 this with h | h
      · rw [Multiset.eq_of_mem_replicate h]
      · rw [Multiset.eq_of_mem_replicate h]; omega
  · rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    rintro s - ⟨h1, h2⟩
    exact hnk (key s h1 h2).1

/-- The twelvefold way. Put `n` things into `k` boxes (`n ≥ 1`, `k ≥ 1`: the card's formulas
`C(n − 1, k − 1)`, `C(n + k − 1, k − 1)` and `S(n, 1) + ⋯ + S(n, k)` misread an empty depot).
A loading is recorded as follows, one row per answer to "do the things differ, do the boxes
differ":
* things differ, boxes differ: a box number written on each thing, a map `Fin n → Fin k`;
* things differ, boxes alike: the things sorted into groups, a `Finpartition` of the `n` things
  with at most `k` groups (an empty box leaves no group);
* things alike, boxes differ: how many things each box holds, recorded as the multiset of the
  `n` box numbers, a `Sym (Fin k) n`;
* things alike, boxes alike: the `k` unnamed boxes' counts, a multiset of `k` counts from
  `0` to `n` adding to `n`, a `Sym (Fin (n + 1)) k`.
The three columns ask for any number per box, at most one per box, and at least one per box.
Then the twelve counts are:
`k ^ n`, `k(k − 1)⋯(k − n + 1)`, `k! · S(n, k)`;
`S(n, 1) + ⋯ + S(n, k)`, `1 if n ≤ k else 0`, `S(n, k)`;
`C(n + k − 1, k − 1)`, `C(k, n)`, `C(n − 1, k − 1)`;
`p_{≤k}(n)`, `1 if n ≤ k else 0`, `p_k(n)`,
where `S` is the Stirling number of the second kind and `p_{≤k}(n)`, `p_k(n)` count the ways
of writing `n` as a sum of at most `k`, exactly `k`, positive parts with order ignored. -/
theorem twelvefold_way (n k : ℕ) (hn : 0 < n) (hk : 0 < k) :
    -- things differ, boxes differ
    (Fintype.card (Fin n → Fin k) = k ^ n ∧
      #{f : Fin n → Fin k | Function.Injective f} = k.descFactorial n ∧
      #{f : Fin n → Fin k | Function.Surjective f} = k.factorial * Nat.stirlingSecond n k) ∧
    -- things differ, boxes alike
    (#{P : Finpartition (univ : Finset (Fin n)) | #P.parts ≤ k} =
        ∑ j ∈ Icc 1 k, Nat.stirlingSecond n j ∧
      #{P : Finpartition (univ : Finset (Fin n)) | #P.parts ≤ k ∧ ∀ b ∈ P.parts, #b ≤ 1} =
        (if n ≤ k then 1 else 0) ∧
      #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k} = Nat.stirlingSecond n k) ∧
    -- things alike, boxes differ
    (Fintype.card (Sym (Fin k) n) = Nat.choose (n + k - 1) (k - 1) ∧
      #{s : Sym (Fin k) n | (s : Multiset (Fin k)).Nodup} = Nat.choose k n ∧
      #{s : Sym (Fin k) n | ∀ i : Fin k, i ∈ s} = Nat.choose (n - 1) (k - 1)) ∧
    -- things alike, boxes alike
    (#{s : Sym (Fin (n + 1)) k | ((s : Multiset (Fin (n + 1))).map Fin.val).sum = n} =
        #{p : Nat.Partition n | Multiset.card p.parts ≤ k} ∧
      #{s : Sym (Fin (n + 1)) k | ((s : Multiset (Fin (n + 1))).map Fin.val).sum = n ∧
          ∀ i ∈ s, i.val ≤ 1} = (if n ≤ k then 1 else 0) ∧
      #{s : Sym (Fin (n + 1)) k | ((s : Multiset (Fin (n + 1))).map Fin.val).sum = n ∧
          ∀ i ∈ s, 1 ≤ i.val} = #{p : Nat.Partition n | Multiset.card p.parts = k}) := by
  exact ⟨⟨by simp, tw_inj n k, tw_surj n k⟩,
    ⟨tw_fp_atmost n k hn, tw_fp_ones n k, tw_fp_count n k⟩,
    ⟨tw_sym_card n k hk, tw_sym_nodup n k, tw_sym_onto n k hn hk⟩,
    ⟨tw_part_atmost n k, tw_part_ones n k, tw_part_exact n k⟩⟩

/-- When dividing takes the names off the boxes. With no box empty, the only renaming of the
`k` boxes that leaves a loading unchanged is the one that moves nothing, so the `k!` renamings
of a grouping give `k!` different loadings and the onto maps come `k!` to a grouping. -/
theorem renaming_fixes_onto_loading_only_if_trivial (n k : ℕ) (f : Fin n → Fin k)
    (hf : Function.Surjective f) (σ : Equiv.Perm (Fin k)) (hσ : ∀ i, σ (f i) = f i) :
    σ = 1 := by
  apply Equiv.ext
  intro c
  obtain ⟨i, rfl⟩ := hf c
  exact hσ i

/-- Each "any" cell is its row's "at least one" cell added over how many boxes are used, times
the choice of which boxes: with named things and named boxes,
`k ^ n = Σ_j C(k, j) · j! · S(n, j)`, for every `n` and `k`. -/
theorem pow_eq_sum_choose_mul_factorial_mul_stirlingSecond (n k : ℕ) :
    k ^ n = ∑ j ∈ range (k + 1), Nat.choose k j * j.factorial * Nat.stirlingSecond n j := by
  exact tw_pow_sum n k

-- The depot, five parcels into three vans: the top row 243, 0, 150.
example : 3 ^ 5 = 243 ∧ Nat.descFactorial 3 5 = 0 ∧
    Nat.factorial 3 * Nat.stirlingSecond 5 3 = 150 := by decide
example : #{f : Fin 5 → Fin 3 | Function.Surjective f} = 150 := by decide +kernel
-- Vans alike: 1 + 15 + 25 = 41 with empties allowed, 25 with none idle.
example : Nat.stirlingSecond 5 1 = 1 ∧ Nat.stirlingSecond 5 2 = 15 ∧
    Nat.stirlingSecond 5 3 = 25 ∧ (∑ j ∈ Icc 1 3, Nat.stirlingSecond 5 j) = 41 := by decide
-- Sacks of gravel into named vans: C(7, 2) = 21, C(3, 5) = 0, C(4, 2) = 6.
example : Nat.choose (5 + 3 - 1) (3 - 1) = 21 ∧ Nat.choose 3 5 = 0 ∧
    Nat.choose (5 - 1) (3 - 1) = 6 := by decide
-- The same two counts listed: a multiset of five van numbers from three vans, 21 in all,
-- 6 with every van used.
example : Fintype.card (Sym (Fin 3) 5) = 21 := by decide +kernel
example : #{s : Sym (Fin 3) 5 | ∀ i : Fin 3, i ∈ s} = 6 := by decide +kernel
-- Nothing named: three unnamed vans' counts adding to 5 are 5+0+0, 4+1+0, 3+2+0, 3+1+1, 2+2+1,
-- five ways, two with no van idle.
example : #{s : Sym (Fin 6) 3 | ((s : Multiset (Fin 6)).map Fin.val).sum = 5} = 5 := by
  decide +kernel
example : #{s : Sym (Fin 6) 3 | ((s : Multiset (Fin 6)).map Fin.val).sum = 5 ∧
    ∀ i ∈ s, 1 ≤ i.val} = 2 := by decide +kernel
-- The column of zeros: three vans cannot take five parcels one apiece.
example : ¬ (5 ≤ 3) := by decide
-- Two parcels into three vans, the middle column: 6, 1, 3, 1.
example : Nat.descFactorial 3 2 = 6 ∧ Nat.choose 3 2 = 3 := by decide
-- Dividing 243 by 3! = 6 fails: 6 does not divide 243, and 6 × 41 = 246, not 243.
example : ¬ (6 ∣ 243) ∧ 6 * 41 ≠ 243 ∧ 150 / Nat.factorial 3 = 25 := by decide
-- Each "any" cell split by vans used: 243 = 3 + 90 + 150, 41 = 1 + 15 + 25,
-- 21 = 3 + 12 + 6, 5 = 1 + 2 + 2.
example : Nat.choose 3 1 * Nat.factorial 1 * Nat.stirlingSecond 5 1 = 3 ∧
    Nat.choose 3 2 * Nat.factorial 2 * Nat.stirlingSecond 5 2 = 90 ∧
    3 + 90 + 150 = 243 := by decide
example : 1 + 15 + 25 = 41 ∧ 1 + 2 + 2 = 5 := by decide
example : Nat.choose 3 1 * Nat.choose 4 0 = 3 ∧ Nat.choose 3 2 * Nat.choose 4 1 = 12 ∧
    Nat.choose 3 3 * Nat.choose 4 2 = 6 ∧ 3 + 12 + 6 = 21 := by decide
-- The groups rule by hand: S(5, 3) = 3 · S(4, 3) + S(4, 2) = 18 + 7 = 25.
example : Nat.stirlingSecond 4 3 = 6 ∧ Nat.stirlingSecond 4 2 = 7 ∧ 3 * 6 + 7 = 25 := by decide

#print axioms twelvefold_way
#print axioms renaming_fixes_onto_loading_only_if_trivial
#print axioms pow_eq_sum_choose_mul_factorial_mul_stirlingSecond
#print axioms tw_pow_sum
#print axioms tw_image_count
#print axioms tw_pow_surj
#print axioms tw_surj
#print axioms tw_mem_part
#print axioms tw_part_eq
#print axioms tw_mem_parts_iff
#print axioms tw_fp_eq
#print axioms tw_card_parts
#print axioms tw_fiber
#print axioms tw_surj_eq
#print axioms tw_fp_count
#print axioms tw_fp_atmost
#print axioms tw_fp_ones
#print axioms tw_sym_card
#print axioms tw_sym_nodup
#print axioms tw_sym_onto
#print axioms tw_inj
#print axioms tw_lift
#print axioms tw_vm_inj
#print axioms tw_split_zeros
#print axioms tw_sum_filter
#print axioms tw_le_of_mem_parts
#print axioms tw_part_exact
#print axioms tw_part_atmost
#print axioms tw_part_ones
