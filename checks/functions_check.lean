-- Functions: a relation is a function exactly when every input appears as a first entry exactly once, the preimage counts of all outputs add up to the number of inputs, and adding an indicator function counts the set it marks.
import Mathlib.Data.Fintype.Card
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Group.Indicator

open Finset

/-- A relation (a set of ordered pairs (input, output)) is a function from the inputs to the
outputs exactly when every input appears as a first entry exactly once: at least once, so no input
goes unanswered, and at most once, so no input is answered twice. -/
theorem relation_is_function_iff_exactly_once {α β : Type*} (R : Set (α × β)) :
    (∃ f : α → β, R = {p | f p.1 = p.2}) ↔ ∀ a : α, ∃! b : β, (a, b) ∈ R := by
  constructor
  · rintro ⟨f, rfl⟩ a
    exact ⟨f a, rfl, fun b hb => hb.symm⟩
  · intro h
    choose f hf using fun a => (h a).exists
    refine ⟨f, ?_⟩
    ext ⟨a, b⟩
    constructor
    · intro hab
      exact (h a).unique (hf a) hab
    · intro hb
      have hb' : f a = b := hb
      subst hb'
      exact hf a

/-- Counting backwards tests forwards: for a function between finite sets, the number of inputs
behind each output, added over every output in the codomain, is the number of inputs. -/
theorem sum_preimage_counts_eq_domain_size {α β : Type*} [Fintype α] [Fintype β] [DecidableEq β]
    (f : α → β) :
    ∑ b : β, (univ.filter (fun a => f a = b)).card = Fintype.card α := by
  have h := Finset.card_eq_sum_card_fiberwise (f := f) (s := (univ : Finset α))
    (t := (univ : Finset β)) (fun _ _ => mem_univ _)
  rw [← Finset.card_univ]
  exact h.symm

/-- The indicator function of a set A sends members of A to 1 and everything else to 0, and adding
its values over the whole finite codomain gives the number of members of A. -/
theorem sum_indicator_eq_card {β : Type*} [Fintype β] (A : Finset β) :
    ∑ x : β, (A : Set β).indicator (fun _ => (1 : ℕ)) x = A.card := by
  classical
  simp [Set.indicator_apply]

-- The vending machine: 6 buttons, 5 snacks stocked, and the wiring.
inductive Button | A1 | A2 | A3 | B1 | B2 | B3
  deriving DecidableEq

inductive Snack | crisps | chocolate | flapjack | gum | mints
  deriving DecidableEq

open Button Snack

instance : Fintype Button :=
  ⟨⟨{A1, A2, A3, B1, B2, B3}, by decide⟩, fun x => by cases x <;> decide⟩

instance : Fintype Snack :=
  ⟨⟨{crisps, chocolate, flapjack, gum, mints}, by decide⟩, fun x => by cases x <;> decide⟩

def wiring : Button → Snack
  | A1 => crisps | A2 => crisps | A3 => chocolate | B1 => flapjack | B2 => gum | B3 => gum

-- The wiring as a list of pairs, and the two broken versions: B3 jams, A1 drops two.
def pairs : Finset (Button × Snack) :=
  {(A1, crisps), (A2, crisps), (A3, chocolate), (B1, flapjack), (B2, gum), (B3, gum)}
def jammed : Finset (Button × Snack) := pairs.filter (fun p => p.1 ≠ B3)
def double : Finset (Button × Snack) := insert (A1, chocolate) pairs

-- Domain 6 buttons, codomain 5 snacks.
example : Fintype.card Button = 6 ∧ Fintype.card Snack = 5 := by decide

-- Every button appears as a first entry exactly once, 6 pairs for 6 buttons.
example : ∀ b : Button, (pairs.filter (fun p => p.1 = b)).card = 1 := by decide
example : pairs.card = 6 := by decide
example : pairs = univ.image (fun b => (b, wiring b)) := by decide

-- Broken: a jammed B3 leaves 5 of 6 answered; A1 dropping two gives 7 pairs for 6 buttons.
example : jammed.card = 5 ∧ (jammed.filter (fun p => p.1 = B3)).card = 0 := by decide
example : double.card = 7 ∧ (double.filter (fun p => p.1 = A1)).card = 2 := by decide

-- The range: crisps, chocolate, flapjack, gum; 4 snacks, never the mints.
example : univ.image wiring = {crisps, chocolate, flapjack, gum} := by decide
example : (univ.image wiring).card = 4 ∧ mints ∉ univ.image wiring := by decide

-- Preimage of crisps is A1 and A2; preimage of mints is empty.
example : univ.filter (fun b => wiring b = crisps) = {A1, A2} := by decide
example : univ.filter (fun b => wiring b = mints) = ∅ := by decide

-- Buttons per snack: 2 + 1 + 1 + 2 + 0 = 6.
example : (univ.filter (fun b => wiring b = crisps)).card = 2 ∧
    (univ.filter (fun b => wiring b = chocolate)).card = 1 ∧
    (univ.filter (fun b => wiring b = flapjack)).card = 1 ∧
    (univ.filter (fun b => wiring b = gum)).card = 2 ∧
    (univ.filter (fun b => wiring b = mints)).card = 0 := by decide
example : ∑ s : Snack, (univ.filter (fun b => wiring b = s)).card = 6 := by decide

-- Image of {A1, A3} is crisps and chocolate: 2 snacks.
example : ({A1, A3} : Finset Button).image wiring = {crisps, chocolate} := by decide

-- Sold out {chocolate, mints}: indicator 0 1 0 0 1, sum 2; only A3 hits it.
def soldOut : Finset Snack := {chocolate, mints}
example : [crisps, chocolate, flapjack, gum, mints].map (fun s => if s ∈ soldOut then 1 else 0)
    = [0, 1, 0, 0, 1] := by decide
example : ∑ s : Snack, (if s ∈ soldOut then 1 else 0) = 2 := by decide
example : univ.filter (fun b => wiring b ∈ soldOut) = {A3} := by decide

#print axioms relation_is_function_iff_exactly_once
#print axioms sum_preimage_counts_eq_domain_size
#print axioms sum_indicator_eq_card
