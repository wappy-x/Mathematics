-- Permutations: the one-to-one and onto rearrangements of n labelled places compose into rearrangements, each has an undo, there are n! of them, no rearrangement is both an even and an odd number of swaps, and from three places up the order of composing matters, with the card's three-card and four-corner numbers checked.
import Mathlib.Data.Finite.Perm
import Mathlib.Data.Fintype.Perm
import Mathlib.GroupTheory.Perm.Sign
import Mathlib.GroupTheory.SpecificGroups.Alternating
import Mathlib.Logic.Equiv.Fin.Rotate
import Mathlib.Tactic.NormNum

/-- The card's main claim, for any finite collection `α` of labelled places, a shuffle being a
rule `f : α → α` that is one to one and onto.
Doing one shuffle and then another gives a shuffle; the do-nothing rule is a shuffle; grouping
three shuffles either way gives the same shuffle; every shuffle has an undo that is itself a
shuffle and cancels it from either side. So the shuffles form a group under composition, the
symmetric group, and there are exactly `n! = n × (n − 1) × ⋯ × 1` of them when `α` has `n`
members. -/
theorem shuffles_form_symmetric_group_of_size_factorial {α : Type*} [Finite α] :
    (∀ f g : α → α, Function.Bijective f → Function.Bijective g →
        Function.Bijective (g ∘ f)) ∧
      Function.Bijective (id : α → α) ∧
      (∀ f g h : α → α, (h ∘ g) ∘ f = h ∘ (g ∘ f)) ∧
      (∀ f : α → α, Function.Bijective f →
        ∃ g : α → α, Function.Bijective g ∧ g ∘ f = id ∧ f ∘ g = id) ∧
      Nat.card {f : α → α // Function.Bijective f} = (Nat.card α).factorial := by
  classical
  have : Fintype α := Fintype.ofFinite α
  refine ⟨fun f g hf hg => hg.comp hf, Function.bijective_id, fun f g h => rfl, ?_, ?_⟩
  · intro f hf
    refine ⟨(Equiv.ofBijective f hf).symm, (Equiv.ofBijective f hf).symm.bijective, ?_, ?_⟩
    · funext x
      exact (Equiv.ofBijective f hf).symm_apply_apply x
    · funext x
      exact (Equiv.ofBijective f hf).apply_symm_apply x
  · let e : Equiv.Perm α ≃ {f : α → α // Function.Bijective f} :=
      { toFun := fun σ => ⟨σ, σ.bijective⟩
        invFun := fun f => Equiv.ofBijective f.1 f.2
        left_inv := fun σ => by ext; rfl
        right_inv := fun f => by apply Subtype.ext; rfl }
    rw [← Nat.card_congr e, Nat.card_eq_fintype_card, Fintype.card_perm,
      Nat.card_eq_fintype_card]

/-- No shuffle is both even and odd: if one shuffle of the finite places `α` is written as a
chain of swaps in two ways, the two chains are both even in length or both odd. -/
theorem no_shuffle_is_both_even_and_odd {α : Type*} [Fintype α] [DecidableEq α]
    (l l' : List (Equiv.Perm α)) (hl : ∀ τ ∈ l, τ.IsSwap) (hl' : ∀ τ ∈ l', τ.IsSwap)
    (h : l.prod = l'.prod) :
    Even l.length ↔ Even l'.length := by
  have h1 := Equiv.Perm.sign_prod_list_swap hl
  have h2 := Equiv.Perm.sign_prod_list_swap hl'
  rw [h] at h1
  have h3 : ((-1 : ℤˣ)) ^ l.length = (-1) ^ l'.length := h1.symm.trans h2
  have hne : (-1 : ℤˣ) ≠ 1 := by decide
  rw [← neg_one_pow_eq_one_iff_even hne, ← neg_one_pow_eq_one_iff_even hne, h3]

/-- Order is part of the answer: as soon as there are at least three labelled places, some two
shuffles give different results when done in the two orders. -/
theorem shuffle_order_matters_from_three_places {α : Type*} [Finite α]
    (h : 3 ≤ Nat.card α) :
    ∃ σ τ : Equiv.Perm α, σ * τ ≠ τ * σ := by
  classical
  have : Fintype α := Fintype.ofFinite α
  rw [Nat.card_eq_fintype_card] at h
  obtain ⟨e⟩ : Nonempty (Fin 3 ↪ α) := Function.Embedding.nonempty_of_card_le (by simpa using h)
  have hab : e 0 ≠ e 1 := fun h => by simpa using e.injective h
  have hbc : e 1 ≠ e 2 := fun h => by simpa using e.injective h
  refine ⟨Equiv.swap (e 0) (e 1), Equiv.swap (e 1) (e 2), fun H => ?_⟩
  have := congrArg (fun p : Equiv.Perm α => p (e 0)) H
  have hac : e 0 ≠ e 2 := fun h => by simpa using e.injective h
  simp [Equiv.swap_apply_of_ne_of_ne, hab, hbc, hac, hac.symm] at this

-- Places 1, 2, 3 on the card are 0, 1, 2 here. `r` shifts each card one place along, (1 2 3);
-- `t` swaps places 1 and 2, (1 2). In `r * t` the right-hand shuffle `t` goes first.
-- Shuffles of 1, 2, 3, 4, 5 places: 1, 2, 6, 24, 120, and n! gives the same counts.
example : Fintype.card (Equiv.Perm (Fin 1)) = 1 ∧ Fintype.card (Equiv.Perm (Fin 2)) = 2 ∧
    Fintype.card (Equiv.Perm (Fin 3)) = 6 ∧ Fintype.card (Equiv.Perm (Fin 4)) = 24 ∧
    Fintype.card (Equiv.Perm (Fin 5)) = 120 := by
  decide
example : Nat.factorial 3 = 3 * 2 * 1 ∧ Nat.factorial 3 = 6 ∧ Nat.factorial 4 = 24 ∧
    Nat.factorial 5 = 120 := by
  decide
-- r has destinations 2, 3, 1 and t has destinations 2, 1, 3.
example : (finRotate 3 0, finRotate 3 1, finRotate 3 2) = (1, 2, 0) := by decide
example : (Equiv.swap (0 : Fin 3) 1 0, Equiv.swap (0 : Fin 3) 1 1, Equiv.swap (0 : Fin 3) 1 2) =
    (1, 0, 2) := by
  decide
-- Swap then shift, rt, is (1 3); shift then swap, tr, is (2 3).
example : finRotate 3 * Equiv.swap 0 1 = Equiv.swap 0 2 := by decide
example : Equiv.swap 0 1 * finRotate 3 = Equiv.swap 1 2 := by decide
example : finRotate 3 * Equiv.swap 0 1 ≠ Equiv.swap 0 1 * finRotate 3 := by decide
-- The seven starts in place 1: t then r takes it to place 3, r then t brings it to place 1.
example : (finRotate 3 * Equiv.swap 0 1 : Equiv.Perm (Fin 3)) 0 = 2 ∧
    (Equiv.swap 0 1 * finRotate 3 : Equiv.Perm (Fin 3)) 0 = 0 := by
  decide
-- The undo of r has destinations 3, 1, 2: the cycle (1 3 2).
example : ((finRotate 3)⁻¹ 0, (finRotate 3)⁻¹ 1, (finRotate 3)⁻¹ 2) = (2, 0, 1) := by decide
-- r is the two swaps (1 3)(1 2), right-hand swap first, so it is even; t is one swap, odd.
example : finRotate 3 = Equiv.swap 0 2 * Equiv.swap 0 1 := by decide
example : Equiv.Perm.sign (finRotate 3) = 1 ∧ Equiv.Perm.sign (Equiv.swap (0 : Fin 3) 1) = -1 := by
  decide
-- Out-of-order pairs in the list 2, 3, 1: two.
example : ((Finset.univ : Finset (Fin 3 × Fin 3)).filter
    (fun p => p.1 < p.2 ∧ finRotate 3 p.2 < finRotate 3 p.1)).card = 2 := by
  decide
-- S_3 splits into 3 even and 3 odd shuffles: the even ones are e, (1 2 3), (1 3 2).
example : Fintype.card (alternatingGroup (Fin 3)) = 3 := by decide
-- The four-cycle (1 2 3 4) is three swaps, odd.
example : Equiv.Perm.sign (finRotate 4) = -1 := by decide
-- The square tile: of its 24 corner shuffles, 8 keep neighbouring corners neighbouring.
example : ((Finset.univ : Finset (Equiv.Perm (Fin 4))).filter
    (fun p => ∀ i : Fin 4, p (i + 1) - p i = 1 ∨ p (i + 1) - p i = 3)).card = 8 := by
  decide
-- The list 2, 2, 1 is not a shuffle.
example : ¬ Function.Bijective (![1, 1, 0] : Fin 3 → Fin 3) := by decide

#print axioms shuffles_form_symmetric_group_of_size_factorial
#print axioms no_shuffle_is_both_even_and_odd
#print axioms shuffle_order_matters_from_three_places
