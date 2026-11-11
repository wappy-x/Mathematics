-- Stirling numbers of the second kind: the number of splits of n named items into exactly k unnamed non-empty groups obeys S(n, k) = k S(n−1, k) + S(n−1, k−1), named groups multiply it by k!, and it matches Mathlib's Stirling table, with the card's five-tool numbers checked.
import Mathlib.Combinatorics.Enumerative.Stirling
import Mathlib.Order.Partition.Finpartition
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Data.Fintype.Perm

open Finset

namespace StirlingAux

/-- The split of `Fin n` into the fibers of `f`. -/
def fib {n k : ℕ} (f : Fin n → Fin k) : Finpartition (univ : Finset (Fin n)) :=
  @Finpartition.ofSetoid (Fin n) _ _ (Setoid.ker f) (fun a b => decEq (f a) (f b))

#print axioms fib

lemma mem_part_fib {n k : ℕ} (f : Fin n → Fin k) (a b : Fin n) :
    b ∈ (fib f).part a ↔ f a = f b := by
  let : DecidableRel (Setoid.ker f) := fun a b => decEq (f a) (f b)
  exact Finpartition.mem_part_ofSetoid_iff_rel

#print axioms mem_part_fib

lemma parts_eq_image {n : ℕ} (P : Finpartition (univ : Finset (Fin n))) :
    P.parts = univ.image P.part := by
  ext t
  simp only [mem_image, mem_univ, true_and]
  constructor
  · intro ht
    obtain ⟨x, hx⟩ := P.nonempty_of_mem_parts ht
    exact ⟨x, P.part_eq_of_mem ht hx⟩
  · rintro ⟨x, rfl⟩
    exact P.part_mem.2 (mem_univ x)

#print axioms parts_eq_image

lemma eq_of_part {n : ℕ} (P Q : Finpartition (univ : Finset (Fin n)))
    (h : ∀ a b, b ∈ P.part a ↔ b ∈ Q.part a) : P = Q := by
  have : P.part = Q.part := funext fun a => Finset.ext (h a)
  apply Finpartition.ext
  rw [parts_eq_image P, parts_eq_image Q, this]

#print axioms eq_of_part

lemma fib_eq_iff {n k : ℕ} (f : Fin n → Fin k) (P : Finpartition (univ : Finset (Fin n))) :
    fib f = P ↔ ∀ a b, b ∈ P.part a ↔ f a = f b := by
  constructor
  · rintro rfl a b
    exact mem_part_fib f a b
  · intro h
    apply eq_of_part
    intro a b
    rw [mem_part_fib, h]

#print axioms fib_eq_iff

/-- Name the parts: a labelling of the parts gives a map. -/
def lab {n k : ℕ} (P : Finpartition (univ : Finset (Fin n))) (e : P.parts ≃ Fin k) :
    Fin n → Fin k :=
  fun x => e ⟨P.part x, P.part_mem.2 (mem_univ x)⟩

#print axioms lab

lemma lab_injective {n k : ℕ} (P : Finpartition (univ : Finset (Fin n))) :
    Function.Injective (lab (k := k) P) := by
  intro e₁ e₂ h
  apply Equiv.ext
  rintro ⟨t, ht⟩
  obtain ⟨x, hx⟩ := P.nonempty_of_mem_parts ht
  have key : (⟨P.part x, P.part_mem.2 (mem_univ x)⟩ : P.parts) = ⟨t, ht⟩ :=
    Subtype.ext (P.part_eq_of_mem ht hx)
  have := congrFun h x
  simp only [lab] at this
  rw [key] at this
  exact this

#print axioms lab_injective

lemma lab_spec {n k : ℕ} (P : Finpartition (univ : Finset (Fin n))) (e : P.parts ≃ Fin k) :
    Function.Surjective (lab P e) ∧ fib (lab P e) = P := by
  constructor
  · intro y
    obtain ⟨x, hx⟩ := P.nonempty_of_mem_parts (e.symm y).2
    refine ⟨x, ?_⟩
    have key : (⟨P.part x, P.part_mem.2 (mem_univ x)⟩ : P.parts) = e.symm y :=
      Subtype.ext (P.part_eq_of_mem (e.symm y).2 hx)
    simp only [lab]
    rw [key, Equiv.apply_symm_apply]
  · rw [fib_eq_iff]
    intro a b
    simp only [lab, e.injective.eq_iff, Subtype.mk.injEq]
    rw [P.mem_part_iff_part_eq_part (mem_univ b) (mem_univ a), eq_comm]

#print axioms lab_spec

lemma exists_lab {n k : ℕ} (P : Finpartition (univ : Finset (Fin n))) (f : Fin n → Fin k)
    (hf : Function.Surjective f) (hP : fib f = P) : ∃ e, lab P e = f := by
  rw [fib_eq_iff] at hP
  let g : P.parts → Fin k := fun t => f (P.nonempty_of_mem_parts t.2).choose
  have hg : ∀ x, g ⟨P.part x, P.part_mem.2 (mem_univ x)⟩ = f x := by
    intro x
    have hc := (P.nonempty_of_mem_parts (P.part_mem.2 (mem_univ x))).choose_spec
    exact ((hP x _).1 hc).symm
  have hbij : Function.Bijective g := by
    constructor
    · rintro ⟨u₁, h₁⟩ ⟨u₂, h₂⟩ h
      have c₁ := (P.nonempty_of_mem_parts h₁).choose_spec
      have c₂ := (P.nonempty_of_mem_parts h₂).choose_spec
      have hm := (hP _ _).2 h
      rw [P.part_eq_of_mem h₁ c₁] at hm
      exact Subtype.ext (P.eq_of_mem_parts h₁ h₂ hm c₂)
    · intro y
      obtain ⟨x, hx⟩ := hf y
      exact ⟨_, (hg x).trans hx⟩
  exact ⟨Equiv.ofBijective g hbij, funext fun x => hg x⟩

#print axioms exists_lab

lemma card_fiber {n k : ℕ} (P : Finpartition (univ : Finset (Fin n))) :
    #{f : Fin n → Fin k | Function.Surjective f ∧ fib f = P} = Fintype.card (P.parts ≃ Fin k) := by
  rw [← Finset.card_univ (α := P.parts ≃ Fin k),
    ← Finset.card_image_of_injective univ (lab_injective P)]
  congr 1
  ext f
  simp only [mem_filter, mem_univ, true_and, mem_image]
  constructor
  · rintro ⟨hf, hP⟩
    exact exists_lab P f hf hP
  · rintro ⟨e, rfl⟩
    exact lab_spec P e

#print axioms card_fiber

lemma card_equiv_fin {n k : ℕ} (P : Finpartition (univ : Finset (Fin n))) :
    Fintype.card (P.parts ≃ Fin k) = if #P.parts = k then k.factorial else 0 := by
  split_ifs with h
  · have e : P.parts ≃ Fin k := (Fintype.equivFinOfCardEq (by simp [h]))
    rw [Fintype.card_equiv e]
    simp [h]
  · rw [Fintype.card_eq_zero_iff]
    refine ⟨fun e => h ?_⟩
    have := Fintype.card_congr e
    simpa using this

#print axioms card_equiv_fin

lemma card_surj_eq (n k : ℕ) :
    #{f : Fin n → Fin k | Function.Surjective f} =
      k.factorial * #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k} := by
  rw [card_eq_sum_card_fiberwise (f := fib) (t := univ) (fun _ _ => mem_coe.2 (mem_univ _))]
  simp_rw [filter_filter, card_fiber, card_equiv_fin]
  rw [sum_ite, sum_const_zero, add_zero, sum_const, mul_comm]
  rfl

#print axioms card_surj_eq

lemma card_cons {n : ℕ} {β : Type*} [Fintype β] [DecidableEq β]
    (p : (Fin (n + 1) → β) → Prop) [DecidablePred p] :
    #{f : Fin (n + 1) → β | p f} =
      ∑ a : β, #{g : Fin n → β | p (Fin.cons a g : Fin (n + 1) → β)} := by
  rw [card_eq_sum_card_fiberwise (f := fun f => f 0) (t := univ)
    (fun _ _ => mem_coe.2 (mem_univ _))]
  refine sum_congr rfl fun a _ => ?_
  apply card_nbij' (fun f => Fin.tail f) (fun g => (Fin.cons a g : Fin (n + 1) → β))
  · intro f hf
    simp only [mem_coe, mem_filter, mem_univ, true_and] at hf ⊢
    obtain ⟨hp, rfl⟩ := hf
    rwa [Fin.cons_self_tail]
  · intro g hg
    simp only [mem_coe, mem_filter, mem_univ, true_and] at hg ⊢
    exact ⟨hg, Fin.cons_zero _ _⟩
  · intro f hf
    simp only [mem_coe, mem_filter, mem_univ, true_and] at hf
    obtain ⟨-, rfl⟩ := hf
    exact Fin.cons_self_tail f
  · intro g _
    exact Fin.tail_cons _ _

#print axioms card_cons

lemma surj_cons_iff {n m : ℕ} (a : Fin m) (g : Fin n → Fin m) :
    Function.Surjective (Fin.cons a g : Fin (n + 1) → Fin m) ↔ ∀ y, a = y ∨ ∃ i, g i = y := by
  simp only [Function.Surjective, Fin.exists_fin_succ, Fin.cons_zero, Fin.cons_succ]

#print axioms surj_cons_iff

lemma card_surj_cons {n k : ℕ} (a : Fin (k + 1)) :
    #{g : Fin n → Fin (k + 1) | Function.Surjective (Fin.cons a g : Fin (n + 1) → Fin (k + 1))} =
      #{g : Fin n → Fin (k + 1) | Function.Surjective g} +
        #{h : Fin n → Fin k | Function.Surjective h} := by
  rw [← card_filter_add_card_filter_not (fun g => Function.Surjective g)]
  congr 1
  · congr 1
    ext g
    simp only [mem_filter, mem_univ, true_and]
    refine ⟨And.right, fun hg => ⟨?_, hg⟩⟩
    rw [surj_cons_iff]
    exact fun y => Or.inr (hg y)
  · symm
    apply card_bij (fun h _ => a.succAbove ∘ h)
    · intro h hh
      simp only [mem_filter, mem_univ, true_and] at hh ⊢
      constructor
      · rw [surj_cons_iff]
        intro y
        by_cases hy : a = y
        · exact Or.inl hy
        · right
          obtain ⟨z, rfl⟩ := Fin.exists_succAbove_eq (Ne.symm hy)
          obtain ⟨i, rfl⟩ := hh z
          exact ⟨i, rfl⟩
      · intro hs
        obtain ⟨i, hi⟩ := hs a
        exact Fin.succAbove_ne a (h i) hi
    · intro h₁ _ h₂ _ heq
      funext i
      exact a.succAbove_right_injective (congrFun heq i)
    · intro g hg
      simp only [mem_filter, mem_univ, true_and] at hg
      have hne : ∀ i, g i ≠ a := by
        intro i hi
        apply hg.2
        intro y
        rcases (surj_cons_iff a g).1 hg.1 y with rfl | h
        · exact ⟨i, hi⟩
        · exact h
      choose h hh using fun i => Fin.exists_succAbove_eq (hne i)
      refine ⟨h, ?_, funext hh⟩
      simp only [mem_filter, mem_univ, true_and]
      intro y
      rcases (surj_cons_iff a g).1 hg.1 (a.succAbove y) with h1 | ⟨i, hi⟩
      · exact absurd h1.symm (Fin.succAbove_ne a y)
      · exact ⟨i, a.succAbove_right_injective (by rw [hh, hi])⟩

#print axioms card_surj_cons

lemma card_surj_succ (n k : ℕ) :
    #{f : Fin (n + 1) → Fin (k + 1) | Function.Surjective f} =
      (k + 1) * (#{g : Fin n → Fin (k + 1) | Function.Surjective g} +
        #{h : Fin n → Fin k | Function.Surjective h}) := by
  rw [card_cons (fun f => Function.Surjective f)]
  simp only [card_surj_cons, sum_const, card_univ, Fintype.card_fin]
  rfl

#print axioms card_surj_succ

lemma card_surj_stirling (n k : ℕ) :
    #{f : Fin n → Fin k | Function.Surjective f} = k.factorial * Nat.stirlingSecond n k := by
  induction n generalizing k with
  | zero =>
    cases k with
    | zero => decide
    | succ k =>
      rw [Nat.stirlingSecond_zero_succ, mul_zero, card_eq_zero, filter_eq_empty_iff]
      intro f _ hf
      obtain ⟨i, _⟩ := hf 0
      exact i.elim0
  | succ n ih =>
    cases k with
    | zero =>
      rw [Nat.stirlingSecond_succ_zero, mul_zero, card_eq_zero, filter_eq_empty_iff]
      intro f _ _
      exact (f 0).elim0
    | succ k =>
      rw [card_surj_succ, ih, ih, Nat.stirlingSecond_succ_succ, Nat.factorial_succ]
      ring

#print axioms card_surj_stirling

lemma card_eq_stirling (n k : ℕ) :
    #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k} = Nat.stirlingSecond n k := by
  have h1 := card_surj_eq n k
  rw [card_surj_stirling] at h1
  exact (Nat.eq_of_mul_eq_mul_left (Nat.factorial_pos k) h1).symm

#print axioms card_eq_stirling

end StirlingAux

/-- The recurrence. Count the splits of `n` named items into exactly `k` unnamed non-empty
groups (a `Finpartition` of the items with `k` parts). Then for `n ≥ 1` and `k ≥ 1`,
`S(n, k) = k · S(n − 1, k) + S(n − 1, k − 1)`: the last item either joins one of the `k`
groups of a split of the rest, or stands alone beside a split of the rest into `k − 1`.
Written here with `n + 1` items and `k + 1` groups. -/
theorem stirling_second_recurrence (n k : ℕ) :
    #{P : Finpartition (univ : Finset (Fin (n + 1))) | #P.parts = k + 1} =
      (k + 1) * #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k + 1} +
        #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k} := by
  rw [StirlingAux.card_eq_stirling, StirlingAux.card_eq_stirling, StirlingAux.card_eq_stirling,
    Nat.stirlingSecond_succ_succ]

/-- Name the groups and the same splits count the onto maps: the rules sending `n` named items
to `k` named boxes with no box left empty number `k! · S(n, k)`. -/
theorem card_surjective_eq_factorial_mul_stirling_second (n k : ℕ) :
    #{f : Fin n → Fin k | Function.Surjective f} =
      k.factorial * #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k} := by
  exact StirlingAux.card_surj_eq n k

/-- The count of splits is the Stirling table built from `S(0, 0) = 1` and the recurrence
(Mathlib's `Nat.stirlingSecond`), for every `n` and `k`, edges included. -/
theorem card_finpartition_eq_stirlingSecond (n k : ℕ) :
    #{P : Finpartition (univ : Finset (Fin n)) | #P.parts = k} = Nat.stirlingSecond n k := by
  exact StirlingAux.card_eq_stirling n k

-- The edges: S(0, 0) = 1, S(n, 0) = 0, S(n, 1) = S(n, n) = 1, S(n, k) = 0 for k > n.
example : Nat.stirlingSecond 0 0 = 1 := by decide
example : Nat.stirlingSecond 5 0 = 0 ∧ Nat.stirlingSecond 5 1 = 1 ∧
    Nat.stirlingSecond 5 5 = 1 ∧ Nat.stirlingSecond 5 6 = 0 := by decide
-- The four tools without the tape measure: 1, 7, 6, 1 across one to four boxes.
example : Nat.stirlingSecond 4 1 = 1 ∧ Nat.stirlingSecond 4 2 = 7 ∧
    Nat.stirlingSecond 4 3 = 6 ∧ Nat.stirlingSecond 4 4 = 1 := by decide
-- Five tools: 15 ways into two boxes, 25 into three; row 1, 15, 25, 10, 1.
example : Nat.stirlingSecond 5 2 = 15 ∧ Nat.stirlingSecond 5 3 = 25 ∧
    Nat.stirlingSecond 5 4 = 10 := by decide
-- The recurrence by hand: 1 + 2 × 7 = 15 and 7 + 3 × 6 = 25.
example : 1 + 2 * 7 = 15 ∧ 7 + 3 * 6 = 25 := by decide
-- The same 15 by shape: 5 splits of sizes 4+1, 10 of sizes 3+2.
example : Nat.choose 5 1 + Nat.choose 5 2 = 15 := by decide
-- The whole row: B(5) = 52; at most three groups: 1 + 15 + 25 = 41.
example : (∑ k ∈ range 6, Nat.stirlingSecond 5 k) = 52 := by decide
example : (∑ k ∈ range 4, Nat.stirlingSecond 5 k) = 41 := by decide
-- Named boxes: 3! × 25 = 150 onto maps; the sieve gives 243 − 96 + 3 = 150; 150 / 6 = 25.
example : Nat.factorial 3 * Nat.stirlingSecond 5 3 = 150 := by decide
example : 3 ^ 5 = 243 ∧ 2 ^ 5 = 32 ∧ 3 ^ 5 - 3 * 2 ^ 5 + 3 = 150 ∧ 150 / Nat.factorial 3 = 25 := by
  decide
-- The onto maps from five tools to three named boxes, listed and counted: 150.
example : #{f : Fin 5 → Fin 3 | Function.Surjective f} = 150 := by decide +kernel
-- The mistakes: Pascal-style 6 + 7 = 13; C(5, 3) = 10, which is S(5, 4).
example : 6 + 7 = 13 ∧ Nat.stirlingSecond 5 3 ≠ 13 := by decide
example : Nat.choose 5 3 = 10 ∧ Nat.choose 5 3 = Nat.stirlingSecond 5 4 := by decide

#print axioms stirling_second_recurrence
#print axioms card_surjective_eq_factorial_mul_stirling_second
#print axioms card_finpartition_eq_stirlingSecond
