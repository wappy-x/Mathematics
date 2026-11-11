-- Splitting into groups: n distinct things go into named piles of fixed sizes in n! / (n₁! n₂! ⋯ n_k!) ways, and with the names taken off the count is divided once more by m! for each size that m piles share, with the card's nine-player numbers checked.
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Factorial.BigOperators
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Order.Partition.Finpartition
import Mathlib.Tactic.NormNum
import Mathlib.GroupTheory.Perm.DomMulAct

open Finset

section SplitHelpers

variable {α : Type*} [Fintype α] [DecidableEq α]

/-- A split of `α` is determined by its parts, and its parts are the parts of the points. -/
theorem split_parts_eq_image (P : Finpartition (univ : Finset α)) :
    P.parts = univ.image P.part := by
  ext p
  simp only [mem_image, mem_univ, true_and]
  constructor
  · intro hp
    obtain ⟨a, -, ha⟩ := P.part_surjOn hp
    exact ⟨a, ha⟩
  · rintro ⟨a, rfl⟩
    exact P.part_mem.2 (mem_univ a)

theorem split_ext {P Q : Finpartition (univ : Finset α)} (h : ∀ a, P.part a = Q.part a) :
    P = Q := by
  ext1
  rw [split_parts_eq_image P, split_parts_eq_image Q]
  congr 1
  funext a
  exact h a

/-- The split of `α` into the non-empty fibres of `f`. -/
noncomputable def fibrePartition {ι : Type*} (f : α → ι) : Finpartition (univ : Finset α) :=
  by classical exact Finpartition.ofSetoid (Setoid.ker f)

theorem mem_part_fibrePartition {ι : Type*} (f : α → ι) (a b : α) :
    b ∈ (fibrePartition f).part a ↔ f a = f b := by
  classical
  unfold fibrePartition
  convert Finpartition.mem_part_ofSetoid_iff_rel (s := Setoid.ker f) (a := a) (b := b)

theorem part_fibrePartition {ι : Type*} [DecidableEq ι] (f : α → ι) (a : α) :
    (fibrePartition f).part a = univ.filter (fun b => f b = f a) := by
  ext b
  simp [mem_part_fibrePartition, eq_comm]

theorem eq_fibrePartition {ι : Type*} (f : α → ι) (P : Finpartition (univ : Finset α))
    (h : ∀ a b, b ∈ P.part a ↔ f a = f b) : P = fibrePartition f := by
  apply split_ext
  intro a
  ext b
  rw [h, mem_part_fibrePartition]

theorem ker_of_fibrePartition_eq {ι κ : Type*} (f : α → ι) (g : α → κ)
    (h : fibrePartition f = fibrePartition g) (a b : α) : f a = f b ↔ g a = g b := by
  rw [← mem_part_fibrePartition f, ← mem_part_fibrePartition g, h]

/-- The permutations `g` with `f0 ∘ g = f0 ∘ h` are as many as those fixing `f0`. -/
theorem card_perm_comp_eq {ι : Type*} [DecidableEq ι] (f0 : α → ι) (h : Equiv.Perm α) :
    (univ.filter (fun g : Equiv.Perm α => f0 ∘ g = f0 ∘ h)).card =
      Fintype.card {g : Equiv.Perm α // f0 ∘ g = f0} := by
  rw [Fintype.card_subtype]
  refine Finset.card_nbij' (fun g => g * h⁻¹) (fun g => g * h) ?_ ?_ ?_ ?_
  · intro g hg
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hg ⊢
    funext a
    have := congrFun hg (h⁻¹ a)
    simpa using this
  · intro g hg
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hg ⊢
    funext a
    have := congrFun hg (h a)
    simpa using this
  · intro g _
    simp
  · intro g _
    simp

end SplitHelpers

#print axioms split_parts_eq_image
#print axioms split_ext
#print axioms fibrePartition
#print axioms mem_part_fibrePartition
#print axioms part_fibrePartition
#print axioms eq_fibrePartition
#print axioms ker_of_fibrePartition_eq
#print axioms card_perm_comp_eq

/-- Named piles (the multinomial coefficient). Split `n` distinct things (the members of `α`)
into `k` piles numbered `0, …, k − 1` whose sizes `s 0, …, s (k − 1)` are fixed in advance and
add up to `n`. A split is a rule sending each thing to the number of its pile, with exactly
`s i` things sent to pile `i`; order inside a pile does not count. The number of such splits
is `n! / (s 0)! ⋯ (s (k − 1))!`. -/
theorem card_named_splits {α : Type*} [Fintype α] [DecidableEq α] {k : ℕ} (s : Fin k → ℕ)
    (hs : ∑ i, s i = Fintype.card α) :
    (univ.filter (fun f : α → Fin k =>
        ∀ i, (univ.filter (fun a => f a = i)).card = s i)).card =
      (Fintype.card α).factorial / ∏ i, (s i).factorial := by
  have hcard : Fintype.card α = Fintype.card (Σ i : Fin k, Fin (s i)) := by
    simp [hs]
  have e : α ≃ Σ i : Fin k, Fin (s i) := Fintype.equivOfCardEq hcard
  obtain ⟨f0, hf0⟩ : ∃ f0 : α → Fin k, ∀ a, f0 a = (e a).1 := ⟨_, fun _ => rfl⟩
  have hf0card : ∀ i, Fintype.card {a // f0 a = i} = s i := by
    intro i
    rw [Fintype.card_congr (e.subtypeEquiv (p := fun a => f0 a = i) (q := fun x => x.1 = i)
      (fun a => by rw [hf0])), Fintype.card_congr (Equiv.sigmaSubtype i)]
    simp
  have key : (Fintype.card α).factorial =
      (univ.filter (fun f : α → Fin k =>
        ∀ i, (univ.filter (fun a => f a = i)).card = s i)).card * ∏ i, (s i).factorial := by
    have h1 : (univ : Finset (Equiv.Perm α)).card = (Fintype.card α).factorial := by
      simp [Fintype.card_perm]
    rw [← h1, card_eq_sum_card_fiberwise (f := fun g : Equiv.Perm α => f0 ∘ g)]
    · apply Finset.sum_const_nat
      intro f hf
      have hf' : ∀ i, Fintype.card {a // f a = i} = Fintype.card {a // f0 a = i} := by
        intro i
        rw [hf0card, Fintype.card_subtype]
        exact (mem_filter.1 hf).2 i
      obtain ⟨h, hh⟩ : ∃ h : Equiv.Perm α, f0 ∘ h = f :=
        ⟨Equiv.ofFiberEquiv (fun i => Fintype.equivOfCardEq (hf' i)),
          funext (Equiv.ofFiberEquiv_map _)⟩
      rw [← hh, card_perm_comp_eq, DomMulAct.stabilizer_card]
      exact prod_congr rfl (fun i _ => by rw [hf0card])
    · intro g _
      simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq]
      intro i
      rw [← Fintype.card_subtype, ← hf0card i]
      exact Fintype.card_congr (g.subtypeEquiv (fun a => Iff.rfl))
  exact (Nat.div_eq_of_eq_mul_left (prod_pos (fun i _ => Nat.factorial_pos _)) key).symm

/-- Unnamed piles, with the intended grouping `(n! / ∏ (s i)!) / ∏ (m_v)!`. -/
theorem card_unnamed_splits_aux {α : Type*} [Fintype α] [DecidableEq α] {k : ℕ} (s : Fin k → ℕ)
    (hs : ∑ i, s i = Fintype.card α) (hpos : ∀ i, 0 < s i) :
    (univ.filter (fun P : Finpartition (univ : Finset α) =>
        P.parts.val.map Finset.card = (univ : Finset (Fin k)).val.map s)).card =
      (Fintype.card α).factorial / (∏ i, (s i).factorial) /
        ∏ v ∈ univ.image s, (univ.filter (fun i => s i = v)).card.factorial := by
  classical
  have hBcard := card_named_splits s hs
  have hsurj : ∀ f ∈ univ.filter (fun f : α → Fin k =>
      ∀ i, (univ.filter (fun a => f a = i)).card = s i), Function.Surjective f := by
    intro f hf i
    have h1 := (mem_filter.1 hf).2 i
    have hne : (univ.filter (fun a => f a = i)).Nonempty := by
      rw [← card_pos, h1]
      exact hpos i
    obtain ⟨a, ha⟩ := hne
    exact ⟨a, (mem_filter.1 ha).2⟩
  have key : (univ.filter (fun f : α → Fin k =>
      ∀ i, (univ.filter (fun a => f a = i)).card = s i)).card =
      (univ.filter (fun P : Finpartition (univ : Finset α) =>
        P.parts.val.map Finset.card = (univ : Finset (Fin k)).val.map s)).card *
        ∏ v ∈ univ.image s, (univ.filter (fun i => s i = v)).card.factorial := by
    rw [card_eq_sum_card_fiberwise (f := fun f : α → Fin k => fibrePartition f)]
    · apply Finset.sum_const_nat
      intro P hP
      have hPC := (mem_filter.1 hP).2
      have hcount : ∀ v, Fintype.card {i : Fin k // s i = v} =
          Fintype.card {p : P.parts // p.1.card = v} := by
        intro v
        have h1 := congrArg (Multiset.count v) hPC
        rw [Multiset.count_map, Multiset.count_map] at h1
        have h2 : (P.parts.filter (fun p => v = p.card)).card =
            (univ.filter (fun i => v = s i)).card := h1
        rw [Fintype.card_subtype, Fintype.card_congr (Equiv.subtypeSubtypeEquivSubtypeInter
          (· ∈ P.parts) (fun p : Finset α => p.card = v)),
          Fintype.card_of_subtype (P.parts.filter (fun p => p.card = v)) (by simp)]
        rw [filter_congr (s := P.parts) (fun p _ => (eq_comm : p.card = v ↔ v = p.card)), h2]
        exact congrArg card (filter_congr (fun i _ => eq_comm))
      obtain ⟨σ, hσ⟩ : ∃ σ : Fin k ≃ P.parts, ∀ i, (σ i).1.card = s i :=
        ⟨@Equiv.ofFiberEquiv _ _ _ s (fun p : P.parts => p.1.card)
          (fun v => Fintype.equivOfCardEq (hcount v)), fun i =>
          @Equiv.ofFiberEquiv_map _ _ _ s (fun p : P.parts => p.1.card) _ i⟩
      obtain ⟨f0, hf0⟩ : ∃ f0 : α → Fin k,
          ∀ a, f0 a = σ.symm ⟨P.part a, P.part_mem.2 (mem_univ a)⟩ := ⟨_, fun _ => rfl⟩
      have hf0i : ∀ a i, f0 a = i ↔ a ∈ (σ i).1 := by
        intro a i
        rw [hf0, Equiv.symm_apply_eq, Subtype.ext_iff]
        exact P.part_eq_iff_mem (σ i).2
      have hf0B : f0 ∈ univ.filter (fun f : α → Fin k =>
          ∀ i, (univ.filter (fun a => f a = i)).card = s i) := by
        rw [mem_filter]
        refine ⟨mem_univ _, fun i => ?_⟩
        rw [← hσ i]
        congr 1
        ext a
        simp [hf0i]
      have hf0P : fibrePartition f0 = P := by
        symm
        apply eq_fibrePartition
        intro a b
        rw [P.mem_part_iff_part_eq_part (mem_univ b) (mem_univ a), hf0, hf0]
        simp only [EmbeddingLike.apply_eq_iff_eq, Subtype.mk.injEq]
        exact eq_comm
      have hT : (univ.filter (fun τ : Equiv.Perm (Fin k) => s ∘ τ = s)).card =
          ∏ v ∈ univ.image s, (univ.filter (fun i => s i = v)).card.factorial := by
        rw [← Fintype.card_subtype, DomMulAct.stabilizer_card']
        exact prod_congr rfl (fun v _ => by rw [Fintype.card_subtype])
      rw [← hT]
      symm
      apply Finset.card_bij (fun (τ : Equiv.Perm (Fin k)) _ => (τ : Fin k → Fin k) ∘ f0)
      · intro τ hτ
        have hτ' := (mem_filter.1 hτ).2
        rw [mem_filter, mem_filter]
        refine ⟨⟨mem_univ _, fun j => ?_⟩, ?_⟩
        · have h3 : univ.filter (fun a => ((τ : Fin k → Fin k) ∘ f0) a = j) =
              univ.filter (fun a => f0 a = τ.symm j) := by
            apply filter_congr
            intro a _
            exact (Equiv.eq_symm_apply τ).symm
          rw [h3, (mem_filter.1 hf0B).2 (τ.symm j)]
          have := congrFun hτ' (τ.symm j)
          simp at this
          exact this.symm
        · rw [← hf0P]
          symm
          apply eq_fibrePartition
          intro a b
          rw [mem_part_fibrePartition]
          simp
      · intro τ₁ _ τ₂ _ h
        ext i
        obtain ⟨a, rfl⟩ := hsurj f0 hf0B i
        exact congrArg Fin.val (congrFun h a)
      · intro f hf
        rw [mem_filter] at hf
        obtain ⟨hfB, hfP⟩ := hf
        have hker : ∀ a b, f0 a = f0 b ↔ f a = f b :=
          ker_of_fibrePartition_eq f0 f (hf0P.trans hfP.symm)
        choose r hr using hsurj f0 hf0B
        have hinj : Function.Injective (fun i => f (r i)) := by
          intro i j hij
          simp only at hij
          rw [← hr i, ← hr j]
          exact (hker _ _).2 hij
        refine ⟨Equiv.ofBijective _ (Finite.injective_iff_bijective.1 hinj), ?_, ?_⟩
        · rw [mem_filter]
          refine ⟨mem_univ _, funext fun i => ?_⟩
          show s (f (r i)) = s i
          rw [← (mem_filter.1 hfB).2 (f (r i)), ← (mem_filter.1 hf0B).2 i]
          congr 1
          ext a
          simp only [mem_filter, mem_univ, true_and]
          rw [← hker, hr]
        · funext a
          show f (r (f0 a)) = f a
          exact (hker _ _).1 (hr (f0 a))
    · intro f hf
      simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq]
      have hparts : (fibrePartition f).parts =
          univ.image (fun i => univ.filter (fun a => f a = i)) := by
        rw [split_parts_eq_image]
        ext p
        simp only [mem_image, mem_univ, true_and, part_fibrePartition]
        constructor
        · rintro ⟨a, rfl⟩
          exact ⟨f a, rfl⟩
        · rintro ⟨i, rfl⟩
          obtain ⟨a, rfl⟩ := hsurj f hf i
          exact ⟨a, rfl⟩
      rw [hparts, image_val_of_injOn, Multiset.map_map]
      · apply Multiset.map_congr rfl
        intro i _
        exact (mem_filter.1 hf).2 i
      · intro i _ j _ hij
        obtain ⟨a, rfl⟩ := hsurj f hf i
        have h4 : a ∈ univ.filter (fun b => f b = f a) := by simp
        simp only at hij
        rw [hij] at h4
        exact (mem_filter.1 h4).2
  rw [← hBcard, key, Nat.mul_div_cancel _ (prod_pos (fun v _ => Nat.factorial_pos _))]

#print axioms card_unnamed_splits_aux

/-- Unnamed piles. Take the same `n` distinct things and pile sizes `s 0, …, s (k − 1)` adding up
to `n`, every pile holding at least one thing, but now the piles carry no numbers: a split is
just a set of disjoint, non-empty piles covering everything (a `Finpartition`), whose list of
sizes is the list `s`. The count is the named count `n! / ∏ (s i)!` divided, for each size `v`
that occurs, by `m!`, where `m` is how many piles share that size. A size used by only one pile
divides by `1! = 1`, so piles of all different sizes give the same count as named piles. -/
theorem card_unnamed_splits {α : Type*} [Fintype α] [DecidableEq α] {k : ℕ} (s : Fin k → ℕ)
    (hs : ∑ i, s i = Fintype.card α) (hpos : ∀ i, 0 < s i) :
    (univ.filter (fun P : Finpartition (univ : Finset α) =>
        P.parts.val.map Finset.card = (univ : Finset (Fin k)).val.map s)).card =
      (Fintype.card α).factorial / (∏ i, (s i).factorial) /
        ∏ v ∈ univ.image s, (univ.filter (fun i => s i = v)).card.factorial := by
  exact card_unnamed_splits_aux s hs hpos

/-- The title's case, divide by `k!`: `k` unnamed piles, every one of the same size `m ≥ 1`,
from `n = k · m` distinct things. The count is `n! / (m!)^k / k!`. -/
theorem card_unnamed_equal_splits {α : Type*} [Fintype α] [DecidableEq α] (k m : ℕ)
    (hm : 0 < m) (hn : k * m = Fintype.card α) :
    (univ.filter (fun P : Finpartition (univ : Finset α) =>
        P.parts.card = k ∧ ∀ p ∈ P.parts, p.card = m)).card =
      (Fintype.card α).factorial / m.factorial ^ k / k.factorial := by
  have h := card_unnamed_splits_aux (α := α) (k := k) (fun _ => m) (by simp [hn]) (fun _ => hm)
  have hL : univ.filter (fun P : Finpartition (univ : Finset α) =>
      P.parts.card = k ∧ ∀ p ∈ P.parts, p.card = m) =
      univ.filter (fun P : Finpartition (univ : Finset α) =>
        P.parts.val.map Finset.card = (univ : Finset (Fin k)).val.map (fun _ => m)) := by
    apply filter_congr
    intro P _
    rw [Multiset.map_const', Multiset.eq_replicate]
    simp
  rw [hL, h]
  rcases Nat.eq_zero_or_pos k with rfl | hk
  · simp
  · have him : univ.image (fun _ : Fin k => m) = {m} :=
      image_const (univ_nonempty_iff.2 ⟨⟨0, hk⟩⟩) m
    simp [him, prod_const]

-- Nine players at three numbered tables of three: 9! = 362,880 line-ups, 3! 3! 3! = 216 per split.
example : Nat.factorial 9 = 362880 := by decide
example : Nat.factorial 3 = 6 ∧ Nat.factorial 3 * Nat.factorial 3 * Nat.factorial 3 = 216 := by
  decide
example : Nat.factorial 9 / (Nat.factorial 3 * Nat.factorial 3 * Nat.factorial 3) = 1680 := by
  decide
-- One table at a time: C(9,3) × C(6,3) × C(3,3) = 84 × 20 × 1 = 1,680.
example : Nat.choose 9 3 = 84 ∧ Nat.choose 6 3 = 20 ∧ Nat.choose 3 3 = 1 := by decide
example : Nat.choose 9 3 * Nat.choose 6 3 * Nat.choose 3 3 = 1680 := by decide
-- Take the table numbers off: 1,680 / 3! = 280.
example : 1680 / Nat.factorial 3 = 280 ∧ 280 * 6 = 1680 := by decide
-- Tables of 4, 3 and 2: 1,260 named or not; dividing by 3! anyway gives 210.
example : Nat.factorial 9 / (Nat.factorial 4 * Nat.factorial 3 * Nat.factorial 2) = 1260 := by
  decide
example : 1260 / Nat.factorial 3 = 210 := by decide
-- The mistakes: forgetting the last pile's 3! gives 10,080; ranking the boards gives 362,880.
example : Nat.factorial 9 / (Nat.factorial 3 * Nat.factorial 3) = 10080 := by decide
-- Every way to hand three table numbers to nine players: 3^9 = 19,683; C(9,3) = 84 is one table only.
example : 3 ^ 9 = 19683 := by decide
-- Try changing: tables of 3, 3, 2, 1 give 5,040 named and 2,520 unnamed; tables of 5, 3, 1 give 504.
example : Nat.factorial 9 /
    (Nat.factorial 3 * Nat.factorial 3 * Nat.factorial 2 * Nat.factorial 1) = 5040 := by decide
example : 5040 / Nat.factorial 2 = 2520 := by decide
example : Nat.factorial 9 / (Nat.factorial 5 * Nat.factorial 3 * Nat.factorial 1) = 504 := by
  decide
-- The cancelling algebra: 9!/(3! 6!) · 6!/(3! 3!) · 3!/(3! 0!) = 9!/(3! 3! 3!).
example : Nat.factorial 9 / (Nat.factorial 3 * Nat.factorial 6) *
    (Nat.factorial 6 / (Nat.factorial 3 * Nat.factorial 3)) *
    (Nat.factorial 3 / (Nat.factorial 3 * Nat.factorial 0)) =
      Nat.factorial 9 / (Nat.factorial 3 * Nat.factorial 3 * Nat.factorial 3) := by decide

#print axioms card_named_splits
#print axioms card_unnamed_splits
#print axioms card_unnamed_equal_splits
