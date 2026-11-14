-- Hashes and MACs: for an ideal n-bit hash, q tries find a matching pair with chance at most (q choose 2)/2^n and hit a given fingerprint with chance at most q/2^n, a Merkle–Damgård hash collision always contains a compression collision, and pigeonhole forces some fingerprint to be shared.
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Combinatorics.Pigeonhole
import Mathlib.Data.List.Basic
import Mathlib.Data.Finset.Powerset
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open Finset

theorem hash_fiber_card_eq {q N : ℕ} (i : Fin q) (y z : Fin N) :
    (univ.filter (fun g : Fin q → Fin N => g i = y)).card
      = (univ.filter (fun g : Fin q → Fin N => g i = z)).card := by
  refine card_nbij' (fun g => Function.update g i z) (fun g => Function.update g i y) ?_ ?_ ?_ ?_
  · intro g _; simp
  · intro g _; simp
  · intro g hg
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hg
    funext k
    by_cases hk : k = i
    · subst hk; simp [hg]
    · simp [hk]
  · intro g hg
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hg
    funext k
    by_cases hk : k = i
    · subst hk; simp [hg]
    · simp [hk]

#print axioms hash_fiber_card_eq

theorem hash_fiber_card_mul {q N : ℕ} (i : Fin q) (y : Fin N) :
    N * (univ.filter (fun g : Fin q → Fin N => g i = y)).card = N ^ q := by
  have h := card_eq_sum_card_fiberwise (s := (univ : Finset (Fin q → Fin N)))
    (t := (univ : Finset (Fin N))) (f := fun g => g i) (fun _ _ => mem_coe.2 (mem_univ _))
  rw [card_univ, Fintype.card_fun, Fintype.card_fin, Fintype.card_fin] at h
  rw [h]
  simp_rw [hash_fiber_card_eq i _ y]
  simp

#print axioms hash_fiber_card_mul

theorem hash_pair_card_eq {q N : ℕ} (i j : Fin q) (hij : i ≠ j) (y : Fin N) :
    (univ.filter (fun g : Fin q → Fin N => g i = g j)).card
      = (univ.filter (fun g : Fin q → Fin N => g j = y)).card := by
  refine card_nbij' (fun g => Function.update g j y) (fun g => Function.update g j (g i)) ?_ ?_ ?_ ?_
  · intro g _; simp
  · intro g _; simp [hij]
  · intro g hg
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hg
    funext k
    by_cases hk : k = j
    · subst hk; simp [hij, hg]
    · simp [hk]
  · intro g hg
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hg
    funext k
    by_cases hk : k = j
    · subst hk; simp [hg]
    · simp [hk]

#print axioms hash_pair_card_eq

theorem md_fold_collision {S B : Type*} (f : S → B → S) :
    ∀ (l l' : List B) (s s' : S), l.length = l'.length → (s ≠ s' ∨ l ≠ l') →
      l.foldl f s = l'.foldl f s' → ∃ p p' : S × B, p ≠ p' ∧ f p.1 p.2 = f p'.1 p'.2 := by
  intro l
  induction l with
  | nil =>
    intro l' s s' hlen hne hfold
    have : l' = [] := List.eq_nil_of_length_eq_zero hlen.symm
    subst this
    simp at hne hfold
    exact absurd hfold hne
  | cons b t ih =>
    intro l' s s' hlen hne hfold
    cases l' with
    | nil => simp at hlen
    | cons b' t' =>
      simp only [List.foldl_cons] at hfold
      simp only [List.length_cons, Nat.add_right_cancel_iff] at hlen
      by_cases h : f s b ≠ f s' b' ∨ t ≠ t'
      · exact ih t' _ _ hlen h hfold
      · push Not at h
        obtain ⟨h1, h2⟩ := h
        refine ⟨(s, b), (s', b'), ?_, h1⟩
        intro hp
        simp only [Prod.mk.injEq] at hp
        obtain ⟨rfl, rfl⟩ := hp
        subst h2
        simp at hne

#print axioms md_fold_collision

/-- The work bounds for an ideal n-bit hash, one that behaves like a random function.
An attacker who tries q messages sees q fingerprints, each equally likely to be any of the
2^n values, independently: a uniformly random function `g : Fin q → Fin (2^n)`.
Collision: there are q(q-1)/2 pairs, each matching with chance 1/2^n, so the chance that some
two tries share a fingerprint is at most (q choose 2)/2^n; it stays small until q nears 2^(n/2).
Matching a given fingerprint `y` (a preimage, or a second preimage of a fixed contract):
the chance is at most q/2^n; it stays small until q nears 2^n.
Stated as counts over all (2^n)^q equally likely outcomes. -/
theorem ideal_hash_collision_and_preimage_bounds (n q : ℕ) (y : Fin (2 ^ n)) :
    2 ^ n * (univ.filter (fun g : Fin q → Fin (2 ^ n) => ¬ Function.Injective g)).card
        ≤ q.choose 2 * (2 ^ n) ^ q ∧
      2 ^ n * (univ.filter (fun g : Fin q → Fin (2 ^ n) => ∃ i, g i = y)).card
        ≤ q * (2 ^ n) ^ q := by
  constructor
  · have hsub : univ.filter (fun g : Fin q → Fin (2 ^ n) => ¬ Function.Injective g) ⊆
        (powersetCard 2 (univ : Finset (Fin q))).biUnion
          (fun s => univ.filter (fun g : Fin q → Fin (2 ^ n) => ∀ a ∈ s, ∀ b ∈ s, g a = g b)) := by
      intro g hg
      have hg' := (mem_filter.1 hg).2
      simp only [Function.Injective] at hg'
      push Not at hg'
      obtain ⟨i, j, hgij, hij⟩ := hg'
      simp only [mem_biUnion, mem_powersetCard, subset_univ, true_and, mem_filter, mem_univ]
      refine ⟨{i, j}, card_pair hij, ?_⟩
      intro a ha b hb
      simp only [mem_insert, mem_singleton] at ha hb
      rcases ha with rfl | rfl <;> rcases hb with rfl | rfl <;> simp [hgij]
    have hs : ∀ s ∈ powersetCard 2 (univ : Finset (Fin q)),
        2 ^ n * (univ.filter (fun g : Fin q → Fin (2 ^ n) => ∀ a ∈ s, ∀ b ∈ s, g a = g b)).card
          = (2 ^ n) ^ q := by
      intro s hs
      rw [mem_powersetCard, card_eq_two] at hs
      obtain ⟨_, a, b, hab, rfl⟩ := hs
      have : univ.filter (fun g : Fin q → Fin (2 ^ n) => ∀ x ∈ ({a, b} : Finset (Fin q)), ∀ z ∈ ({a, b} : Finset (Fin q)), g x = g z)
          = univ.filter (fun g : Fin q → Fin (2 ^ n) => g a = g b) := by
        ext g
        simp only [mem_filter, mem_univ, true_and, mem_insert, mem_singleton, forall_eq_or_imp, forall_eq]
        constructor
        · intro h; tauto
        · intro h; simp [h]
      rw [this, hash_pair_card_eq a b hab y, hash_fiber_card_mul]
    calc 2 ^ n * (univ.filter (fun g : Fin q → Fin (2 ^ n) => ¬ Function.Injective g)).card
        ≤ 2 ^ n * ∑ s ∈ powersetCard 2 (univ : Finset (Fin q)),
            (univ.filter (fun g : Fin q → Fin (2 ^ n) => ∀ a ∈ s, ∀ b ∈ s, g a = g b)).card :=
          Nat.mul_le_mul_left _ ((card_le_card hsub).trans card_biUnion_le)
      _ = ∑ s ∈ powersetCard 2 (univ : Finset (Fin q)), (2 ^ n) ^ q := by
          rw [mul_sum]; exact sum_congr rfl hs
      _ = q.choose 2 * (2 ^ n) ^ q := by
          rw [sum_const, card_powersetCard, card_univ, Fintype.card_fin, smul_eq_mul]
  · have hsub : univ.filter (fun g : Fin q → Fin (2 ^ n) => ∃ i, g i = y) ⊆
        (univ : Finset (Fin q)).biUnion (fun i => univ.filter (fun g : Fin q → Fin (2 ^ n) => g i = y)) := by
      intro g hg
      simpa using hg
    calc 2 ^ n * (univ.filter (fun g : Fin q → Fin (2 ^ n) => ∃ i, g i = y)).card
        ≤ 2 ^ n * ∑ i : Fin q, (univ.filter (fun g : Fin q → Fin (2 ^ n) => g i = y)).card :=
          Nat.mul_le_mul_left _ ((card_le_card hsub).trans card_biUnion_le)
      _ = ∑ i : Fin q, (2 ^ n) ^ q := by
          rw [mul_sum]; exact sum_congr rfl (fun i _ => hash_fiber_card_mul i y)
      _ = q * (2 ^ n) ^ q := by simp

/-- Merkle–Damgård: a hash collision contains a compression collision.
The hash pads a message into a list of blocks and folds the compression function `f` over
them from the fixed start state `iv`. The padding never loses information (distinct messages
give distinct block lists), always gives at least one block, gives messages of equal length
the same number of blocks, and puts the length in the last block, so messages of different
lengths have different last blocks. Then two different messages with the same fingerprint
force two different (state, block) inputs on which `f` gives the same output. -/
theorem md_hash_collision_gives_compression_collision {α S B : Type*}
    (f : S → B → S) (iv : S) (pad : List α → List B)
    (pad_injective : Function.Injective pad)
    (pad_nonempty : ∀ m, pad m ≠ [])
    (pad_same_length : ∀ m m', m.length = m'.length → (pad m).length = (pad m').length)
    (pad_length_in_last : ∀ m m', m.length ≠ m'.length → (pad m).getLast? ≠ (pad m').getLast?)
    (m m' : List α) (hne : m ≠ m')
    (hcoll : (pad m).foldl f iv = (pad m').foldl f iv) :
    ∃ p p' : S × B, p ≠ p' ∧ f p.1 p.2 = f p'.1 p'.2 := by
  by_cases hlen : m.length = m'.length
  · exact md_fold_collision f (pad m) (pad m') iv iv (pad_same_length m m' hlen)
      (Or.inr (fun h => hne (pad_injective h))) hcoll
  · have hlast := pad_length_in_last m m' hlen
    obtain ⟨l, b, hl⟩ := (List.eq_nil_or_concat (pad m)).resolve_left (pad_nonempty m)
    obtain ⟨l', b', hl'⟩ := (List.eq_nil_or_concat (pad m')).resolve_left (pad_nonempty m')
    rw [hl, hl'] at hlast hcoll
    simp only [List.concat_eq_append, List.getLast?_append, List.getLast?_singleton, Option.some_or, ne_eq, Option.some.injEq] at hlast
    simp only [List.concat_eq_append, List.foldl_append, List.foldl_cons, List.foldl_nil] at hcoll
    refine ⟨(l.foldl f iv, b), (l'.foldl f iv, b'), ?_, hcoll⟩
    intro hp
    simp only [Prod.mk.injEq] at hp
    exact hlast hp.2

/-- Collisions must exist (pigeonhole): for any hash `h` from a finite set of messages `M`
to the 2^n fingerprints, some fingerprint is shared by at least |M|/2^n messages. -/
theorem some_fingerprint_shared_by_many {M : Type*} [Fintype M] (n : ℕ) (h : M → Fin (2 ^ n)) :
    ∃ y, Fintype.card M ≤ 2 ^ n * (univ.filter (fun x => h x = y)).card := by
  by_contra hcon
  push Not at hcon
  have hne : (univ : Finset (Fin (2 ^ n))).Nonempty := ⟨⟨0, pow_pos (by norm_num) n⟩, mem_univ _⟩
  have hlt := sum_lt_sum_of_nonempty hne (fun y _ => hcon y)
  rw [← mul_sum, ← card_eq_sum_card_fiberwise (fun _ _ => mem_coe.2 (mem_univ _)), card_univ,
    sum_const, card_univ, Fintype.card_fin, smul_eq_mul] at hlt
  exact lt_irrefl _ hlt

-- Step 0: there are 2^264 messages of 33 bytes, and 2^264 = 256 · 2^256.
example : Fintype.card (Fin 33 → Fin 256) = 2 ^ 264 := by
  rw [Fintype.card_fun, Fintype.card_fin, Fintype.card_fin, show (256 : ℕ) = 2 ^ 8 by norm_num, ← pow_mul]
example : (2 : ℕ) ^ 264 = 256 * 2 ^ 256 := by
  rw [show (264 : ℕ) = 8 + 256 by norm_num, pow_add]; norm_num
-- The 55-byte contract is 440 bits and fits one 64-byte block: 55 + 1 + 8 = 64.
example : 8 * 55 = 440 ∧ 55 + 1 + 8 = 64 := by norm_num
-- 2^128 is about 3.4028 × 10^38.
example : 34028 * 10 ^ 34 ≤ (2 : ℕ) ^ 128 ∧ (2 : ℕ) ^ 128 < 34029 * 10 ^ 34 := by norm_num
-- Length extension: key 32 bytes + order 37 bytes = 69; glue = 1 + 50 + 8 = 59 bytes; forged order 37 + 59 + 12 = 108.
example : (55 + 64 * 64 - (32 + 37)) % 64 = 50 ∧ 1 + 50 + 8 = 59 ∧ 37 + 59 + 12 = 108 := by norm_num
-- SHA-1: 2^80 promised against 2^63.1 found, short by about 2^17 = 131072.
example : (2 : ℕ) ^ 17 = 131072 := by norm_num
-- PBKDF2 cost per guess at r = 1000: plain 4r = 4000, careful 2r + 2 = 2002.
example : 4 * 1000 = 4000 ∧ 2 * 1000 + 2 = 2002 := by norm_num
-- Eight lower-case letters: 26^8 guesses; at r = 100000, (2r + 2) compressions each; salted over 10^6 customers.
example : (26 : ℕ) ^ 8 = 208827064576 := by norm_num
example : (26 : ℕ) ^ 8 * (2 * 100000 + 2) = 41765830569329152 := by norm_num
example : (26 : ℕ) ^ 8 * (2 * 100000 + 2) * 10 ^ 6 = 41765830569329152000000 := by norm_num

#print axioms ideal_hash_collision_and_preimage_bounds
#print axioms md_hash_collision_gives_compression_collision
#print axioms some_fingerprint_shared_by_many
