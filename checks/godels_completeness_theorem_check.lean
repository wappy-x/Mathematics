-- Godel's completeness theorem: Lindenbaum's step (a consistent theory extends to a maximal consistent one that decides every sentence), the compactness theorem, and the card's order examples.
import Mathlib.ModelTheory.Satisfiability
import Mathlib.Order.Zorn
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Card

/-! Mathlib's model theory has theories, models and satisfiability
(`FirstOrder.Language.Theory.IsSatisfiable`) but no proof calculus, so the completeness theorem
itself (`T ⊨ φ ⟹ T ⊢ φ`) is not stated here. This file states what can be stated exactly:

* Lindenbaum's lemma (the card's Step 3), for any notion of consistency with the two properties
  the card uses: a set is consistent when every finite part is (proofs are finite), and a
  consistent set stays consistent after adding `φ` or after adding `¬φ`. No countability is
  assumed, so this covers the Zorn's-lemma case for uncountable languages too.
* The compactness theorem (the card's Step 7), in Mathlib's first-order terms.
* The term model read back (the card's Step 5): a strict order on the counting numbers that
  holds each witness fact `cᵢ < cᵢ₊₁` is exactly "less than".

The examples check the card's whole-number counts by `decide`. -/

namespace GodelCompleteness

/-- **Lindenbaum's lemma.** Suppose consistency of a set of sentences has the two properties
the card uses: a set is consistent exactly when every finite part of it is (a proof uses
finitely many sentences), and if a consistent set cannot take `φ`, it can take `¬φ` ("one of
the two always works"). Then every consistent theory `T` lies inside a theory `T*` that is
consistent, holds `φ` or `¬φ` for every sentence `φ`, and is maximal: no consistent theory is
strictly bigger. -/
theorem lindenbaum_maximal_consistent_extension {α : Type*} (Con : Set α → Prop) (neg : α → α)
    (proofs_are_finite : ∀ S : Set α, Con S ↔ ∀ F : Finset α, (F : Set α) ⊆ S → Con F)
    (one_of_two_works : ∀ S : Set α, Con S → ∀ φ : α, Con (insert φ S) ∨ Con (insert (neg φ) S))
    {T : Set α} (hT : Con T) :
    ∃ Tstar : Set α, T ⊆ Tstar ∧ Con Tstar ∧ (∀ φ : α, φ ∈ Tstar ∨ neg φ ∈ Tstar) ∧
      ∀ S : Set α, Tstar ⊆ S → Con S → S = Tstar := by
  classical
  obtain ⟨M, hTM, hM⟩ := zorn_subset_nonempty {S | Con S} (fun c hc hchain hne => by
    refine ⟨⋃₀ c, ?_, fun s hs => Set.subset_sUnion_of_mem hs⟩
    show Con (⋃₀ c)
    rw [proofs_are_finite]
    intro F hF
    obtain ⟨t, htc, hFt⟩ :=
      hchain.directedOn.exists_mem_subset_of_finite_of_subset_sUnion hne F.finite_toSet hF
    exact (proofs_are_finite t).1 (hc htc) F hFt) T hT
  have hMcon : Con M := hM.prop
  refine ⟨M, hTM, hMcon, fun φ => ?_, fun S hMS hS => (hM.eq_of_subset hS hMS).symm⟩
  rcases one_of_two_works M hMcon φ with h | h
  · exact Or.inl (Set.insert_subset_iff.1 (hM.eq_of_subset h (Set.subset_insert _ _)).ge).1
  · exact Or.inr (Set.insert_subset_iff.1 (hM.eq_of_subset h (Set.subset_insert _ _)).ge).1

/-- **Compactness.** If every finite part of a first-order theory has a model, the whole theory
has a model. -/
theorem compactness_finite_parts_have_models {L : FirstOrder.Language} (T : L.Theory)
    (h : ∀ T0 : Finset L.Sentence, (T0 : L.Theory) ⊆ T →
      FirstOrder.Language.Theory.IsSatisfiable (T0 : L.Theory)) :
    T.IsSatisfiable := by
  exact FirstOrder.Language.Theory.isSatisfiable_iff_isFinitelySatisfiable.2 h

/-- **The witness chain is a copy of the counting numbers.** If a relation `<` on the names
`c₀, c₁, c₂, …` (indexed by the counting numbers) is irreflexive and transitive and holds each
witness fact `cᵢ < cᵢ₊₁`, then `cᵢ < cⱼ` holds exactly when `i < j`. -/
theorem witness_chain_is_counting_order (r : ℕ → ℕ → Prop) (irrefl : ∀ x, ¬ r x x)
    (trans : ∀ x y z, r x y → r y z → r x z) (witness : ∀ i, r i (i + 1)) :
    ∀ i j : ℕ, r i j ↔ i < j := by
  have up : ∀ i j, i < j → r i j := by
    intro i j hij
    induction hij with
    | refl => exact witness i
    | step _ ih => exact trans _ _ _ ih (witness _)
  intro i j
  refine ⟨fun h => ?_, up i j⟩
  by_contra hne
  rcases (not_lt.1 hne).lt_or_eq with hlt | heq
  · exact irrefl _ (trans _ _ _ h (up _ _ hlt))
  · subst heq; exact irrefl _ h

/-! ### The card's examples -/

/-- The theory T has a model: the counting numbers with "less than". Nothing comes before
itself, "less than" is transitive, and every number has one after it. -/
example : (∀ x : ℕ, ¬ x < x) ∧ (∀ x y z : ℕ, x < y → y < z → x < z) ∧ ∀ x : ℕ, ∃ y, x < y := by
  exact ⟨fun x => lt_irrefl x, fun _ _ _ => lt_trans, fun x => ⟨x + 1, Nat.lt_succ_self x⟩⟩

/-- The cycle theory has no model of any size: irreflexivity and transitivity rule out
`a < b` and `b < a` together (the card's 4-line refutation). -/
example {β : Type*} (r : β → β → Prop) (irrefl : ∀ x, ¬ r x x)
    (trans : ∀ x y z, r x y → r y z → r x z) : ¬ ∃ a b, r a b ∧ r b a := by
  exact fun ⟨a, b, hab, hba⟩ => irrefl a (trans a b a hab hba)

/-- The relations on `n` points that satisfy the first two axioms of T: strict orders. -/
def strictOrders (n : ℕ) : Finset (Fin n → Fin n → Bool) :=
  Finset.univ.filter fun r =>
    (∀ i, r i i = false) ∧ ∀ i j k, r i j = true → r j k = true → r i k = true

/-- The models of T on `n` points: strict orders in which every point has one after it. -/
def modelsOfT (n : ℕ) : Finset (Fin n → Fin n → Bool) :=
  (strictOrders n).filter fun r => ∀ i, ∃ j, r i j = true

/-- The models on `n` points of the cycle theory with transitivity dropped. -/
def cycleNoTransitivity (n : ℕ) : Finset (Fin n → Fin n → Bool) :=
  Finset.univ.filter fun r => (∀ i, r i i = false) ∧ ∃ a b, r a b = true ∧ r b a = true

/-- The atoms `cᵢ < cⱼ` that stage `n` keeps: those with `i < j`. -/
def keptAtoms (n : ℕ) : Finset (Fin n × Fin n) :=
  Finset.univ.filter fun p => p.1 < p.2

-- Stages 1 to 6 decide n² atoms and keep 0, 1, 3, 6, 10, 15 of them.
example : [(keptAtoms 1).card, (keptAtoms 2).card, (keptAtoms 3).card, (keptAtoms 4).card,
    (keptAtoms 5).card, (keptAtoms 6).card] = [0, 1, 3, 6, 10, 15] := by decide
example : Fintype.card (Fin 4 × Fin 4) = 16 := by decide

-- On 4 points there are 2^16 = 65,536 relations.
example : Fintype.card (Fin 4 → Fin 4 → Bool) = 65536 := by simp

-- Strict orders on 1, 2, 3 points: 1, 3, 19 (the card's list continues with 219 on 4 points).
example : (strictOrders 1).card = 1 := by decide
example : (strictOrders 2).card = 3 := by decide
example : (strictOrders 3).card = 19 := by decide

-- T has no model on 1, 2 or 3 points.
example : (modelsOfT 1).card = 0 ∧ (modelsOfT 2).card = 0 ∧ (modelsOfT 3).card = 0 := by decide

-- With transitivity dropped, the cycle theory has 0 models on 1 point and 1 model on 2 points.
example : (cycleNoTransitivity 1).card = 0 ∧ (cycleNoTransitivity 2).card = 1 := by decide

#print axioms lindenbaum_maximal_consistent_extension
#print axioms compactness_finite_parts_have_models
#print axioms witness_chain_is_counting_order

end GodelCompleteness
