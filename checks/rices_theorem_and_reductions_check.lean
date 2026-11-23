-- Rice's theorem: no program decides a non-trivial property of what programs accept, reductions carry decidability backwards, and the stopping question reduces to every such property that the empty language lacks.
import Mathlib.Computability.Halting
import Mathlib.Computability.Reduce
import Mathlib.Tactic.NormNum

open Nat.Partrec (Code)
open Nat.Partrec.Code

/-- The domain of the program "run `M` on `w`, then run `T` on the input" is the domain of `T`
when `M` stops on `w`, and empty otherwise. -/
theorem pair_comp_const_dom (M T : Code) (w x : ℕ) :
    (eval (Code.pair (Code.comp M (Code.const w)) T) x).Dom ↔
      (eval M w).Dom ∧ (eval T x).Dom := by
  simp only [eval, Code.eval_const]
  have e1 : (Part.some w >>= (eval M : ℕ → Part ℕ)) = eval M w := Part.bind_some w _
  rw [e1]
  constructor
  · rintro ⟨h1, h3⟩
    exact ⟨h1, h3⟩
  · rintro ⟨h1, h2⟩
    exact ⟨h1, h2⟩

/-- **Rice's theorem.** Let `P` be a property of languages, where the language of a program `c`
is the set of inputs on which it stops, `(eval c).Dom`. If some program's language has the
property and some program's language does not, then no always-stopping program sorts all
programs by it: the set `{⟨c⟩ : L(c) ∈ P}` is undecidable. -/
theorem rice_nontrivial_language_property_undecidable (P : Set (Set ℕ))
    (hyes : ∃ c : Code, (eval c).Dom ∈ P) (hno : ∃ c : Code, (eval c).Dom ∉ P) :
    ¬ ComputablePred (fun c : Code => (eval c).Dom ∈ P) := by
  intro h
  obtain ⟨c1, hc1⟩ := hyes
  obtain ⟨c2, hc2⟩ := hno
  have key := (ComputablePred.rice₂ {c : Code | (eval c).Dom ∈ P}
    (fun cf cg e => by show (eval cf).Dom ∈ P ↔ (eval cg).Dom ∈ P; rw [e])).1 h
  rcases key with h0 | h1
  · have : c1 ∈ ({c : Code | (eval c).Dom ∈ P} : Set Code) := hc1
    rw [h0] at this
    exact this
  · have : c2 ∈ ({c : Code | (eval c).Dom ∈ P} : Set Code) := by rw [h1]; trivial
    exact hc2 this

/-- **Reductions carry decidability backwards.** If `A ≤_m B`, that is, some computable `f`
has `x ∈ A ↔ f x ∈ B` for every `x`, and `B` is decidable, then `A` is decidable:
convert, then ask `B`'s decider. -/
theorem decidable_of_reduces_to_decidable {α β : Type*} [Primcodable α] [Primcodable β]
    (A : α → Prop) (B : β → Prop)
    (hred : ∃ f : α → β, Computable f ∧ ∀ x, A x ↔ B (f x))
    (hB : ComputablePred B) : ComputablePred A := by
  obtain ⟨f, hf, hAB⟩ := hred
  exact ComputablePred.computable_of_manyOneReducible ⟨f, hf, hAB⟩ hB

/-- **The reduction behind Rice's theorem (Case 1).** If the empty language lacks the property
`P` and some machine `T` has a language with the property, then the stopping question
`HALT = {⟨M, w⟩ : M stops on w}` reduces to the property: `HALT ≤_m {⟨c⟩ : L(c) ∈ P}`. -/
theorem halt_reduces_to_language_property (P : Set (Set ℕ)) (hempty : (∅ : Set ℕ) ∉ P)
    (hT : ∃ T : Code, (eval T).Dom ∈ P) :
    ManyOneReducible (fun p : Code × ℕ => (eval p.1 p.2).Dom)
      (fun c : Code => (eval c).Dom ∈ P) := by
  obtain ⟨T, hTP⟩ := hT
  refine ⟨fun p : Code × ℕ => Code.pair (Code.comp p.1 (Code.const p.2)) T, ?_, ?_⟩
  · exact (Code.primrec₂_pair.comp
      (Code.primrec₂_comp.comp Primrec.fst (Code.primrec_const.comp Primrec.snd))
      (Primrec.const T)).to_comp
  · rintro ⟨M, w⟩
    by_cases hM : (eval M w).Dom
    · have hset : (eval (Code.pair (Code.comp M (Code.const w)) T)).Dom = (eval T).Dom := by
        ext x
        exact (pair_comp_const_dom M T w x).trans (and_iff_right hM)
      show (eval M w).Dom ↔ (eval (Code.pair (Code.comp M (Code.const w)) T)).Dom ∈ P
      rw [hset]
      exact iff_of_true hM hTP
    · have hset : (eval (Code.pair (Code.comp M (Code.const w)) T)).Dom = ∅ := by
        ext x
        exact (pair_comp_const_dom M T w x).trans (iff_of_false (fun h => hM h.1) id)
      show (eval M w).Dom ↔ (eval (Code.pair (Code.comp M (Code.const w)) T)).Dom ∈ P
      rw [hset]
      exact iff_of_false hM hempty

-- The card's worked numbers: the macro f(M, w) deletes at step 2n + k + 1.
-- flip on w = 10: n = 2, k = 3, delete at step 8.
example : 2 * 2 + 3 + 1 = 8 := by norm_num
-- flip-norow on w = 10: n = 2, k = 2, delete at step 7.
example : 2 * 2 + 2 + 1 = 7 := by norm_num
-- bb2 on the blank tape: n = 0, k = 6, delete at step 7.
example : 2 * 0 + 6 + 1 = 7 := by norm_num
-- bb4 on the blank tape: n = 0, k = 107, delete at step 108.
example : 2 * 0 + 107 + 1 = 108 := by norm_num

#print axioms pair_comp_const_dom
#print axioms rice_nontrivial_language_property_undecidable
#print axioms decidable_of_reduces_to_decidable
#print axioms halt_reduces_to_language_property
