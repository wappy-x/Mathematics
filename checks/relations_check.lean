-- Relations: each of the four tests on a relation (reflexive, symmetric, antisymmetric, transitive) is a condition on its set of ordered pairs, a relation passes both symmetric and antisymmetric exactly when every pair in it is a loop, and "is at least as tall as" is always reflexive and transitive and is antisymmetric exactly when no two heights tie.
import Mathlib.Basic.Rel
import Mathlib.Data.Fintype.Prod

open SetRel

/-- A relation R on a set A is a set of ordered pairs (a, b) from A × A, and each test is a
question about that set. Reflexive: the five loops (a, a) are all in R. Symmetric: reversing every
pair gives R back. Antisymmetric: the pairs that are in R both ways round are all loops.
Transitive: following R twice in a row (the composition) gives only pairs already in R. -/
theorem relation_tests_are_set_conditions {α : Type*} (R : SetRel α α) :
    (R.IsRefl ↔ SetRel.id ⊆ R) ∧
    (R.IsSymm ↔ R.inv = R) ∧
    (Std.Antisymm (· ~[R] ·) ↔ R ∩ R.inv ⊆ SetRel.id) ∧
    (R.IsTrans ↔ R ○ R ⊆ R) := by
  constructor
  · constructor
    · intro h
      rintro ⟨a, b⟩ (rfl : a = b)
      exact h.refl a
    · intro h
      exact ⟨fun a => h (rfl : a = a)⟩
  constructor
  · constructor
    · intro h
      ext ⟨a, b⟩
      exact ⟨fun hab => h.symm _ _ hab, fun hab => h.symm _ _ hab⟩
    · intro h
      refine ⟨fun a b hab => ?_⟩
      have : (b, a) ∈ R.inv := hab
      rwa [h] at this
  constructor
  · constructor
    · intro h
      rintro ⟨a, b⟩ ⟨hab, hba⟩
      exact h.antisymm a b hab hba
    · intro h
      exact ⟨fun a b hab hba => h ⟨hab, hba⟩⟩
  · constructor
    · intro h
      rintro ⟨a, c⟩ ⟨b, hab, hbc⟩
      exact h.trans a b c hab hbc
    · intro h
      exact ⟨fun a b c hab hbc => h ⟨b, hab, hbc⟩⟩

/-- Symmetric and antisymmetric are not opposites. Symmetric wants every link both ways,
antisymmetric wants no two-way link except loops, so a relation passes both exactly when every
pair in it is a loop (a, a). -/
theorem symm_and_antisymm_iff_only_loops {α : Type*} (R : SetRel α α) :
    (R.IsSymm ∧ Std.Antisymm (· ~[R] ·)) ↔ R ⊆ SetRel.id := by
  constructor
  · rintro ⟨hs, ha⟩ ⟨a, b⟩ hab
    exact ha.antisymm a b hab (hs.symm _ _ hab)
  · intro h
    refine ⟨⟨fun a b hab => ?_⟩, ⟨fun a b hab hba => ?_⟩⟩
    · have := h hab
      have h2 : a = b := this
      subst h2
      exact hab
    · have := h hab
      exact this

/-- "Is at least as tall as": a is linked to b when b's height is at most a's. The arithmetic
makes it reflexive and transitive every time, and it is antisymmetric exactly when no two people
have the same height. -/
theorem at_least_as_tall_tests {α β : Type*} [PartialOrder β] (h : α → β) :
    let R : SetRel α α := {p | h p.2 ≤ h p.1}
    R.IsRefl ∧ R.IsTrans ∧ (Std.Antisymm (· ~[R] ·) ↔ Function.Injective h) := by
  intro R
  refine ⟨⟨fun a => le_refl _⟩, ⟨fun a b c hab hbc => le_trans hbc hab⟩, ?_⟩
  constructor
  · intro hA a b hab
    exact hA.antisymm a b (show h b ≤ h a from le_of_eq hab.symm) (le_of_eq hab)
  · intro hinj
    exact ⟨fun a b hab hba => hinj (le_antisymm hba hab)⟩

-- The office: five people, their heights in cm, and the four conversations.
inductive Person | Maya | Jon | Priya | Luis | Kai
  deriving DecidableEq

open Person

instance : Fintype Person :=
  ⟨⟨{Maya, Jon, Priya, Luis, Kai}, by decide⟩, fun x => by cases x <;> decide⟩

def cm : Person → ℕ
  | Maya => 168 | Jon => 175 | Priya => 162 | Luis => 181 | Kai => 170

def talked : Finset (Person × Person) := {(Maya, Jon), (Jon, Priya), (Priya, Luis), (Luis, Kai)}

def email : Finset (Person × Person) :=
  {(Maya, Jon), (Jon, Maya), (Jon, Priya), (Priya, Jon),
   (Priya, Luis), (Luis, Priya), (Luis, Kai), (Kai, Luis)}

def tall : Finset (Person × Person) := Finset.univ.filter (fun p => cm p.2 ≤ cm p.1)

-- Following a list twice in a row: (a, b) then (b, c) gives (a, c).
def twoStep (R : Finset (Person × Person)) : Finset (Person × Person) :=
  ((R ×ˢ R).filter (fun q => q.1.2 = q.2.1)).image (fun q => (q.1.1, q.2.2))

-- 25 ordered pairs to ask about; email is the 4 conversations both ways, 8 pairs.
example : Fintype.card (Person × Person) = 25 := by decide
example : email = talked ∪ talked.image Prod.swap := by decide
example : talked.card = 4 ∧ email.card = 8 := by decide

-- Is at least as tall as: 5 + 4 + 3 + 2 + 1 = 15 pairs, Luis 5, Jon 4, Kai 3, Maya 2, Priya 1.
example : tall.card = 15 ∧ 5 + 4 + 3 + 2 + 1 = 15 := by decide
example : (tall.filter (·.1 = Luis)).card = 5 ∧ (tall.filter (·.1 = Jon)).card = 4 ∧
    (tall.filter (·.1 = Kai)).card = 3 ∧ (tall.filter (·.1 = Maya)).card = 2 ∧
    (tall.filter (·.1 = Priya)).card = 1 := by decide
-- (Luis, Kai) is in, (Kai, Luis) is not.
example : (Luis, Kai) ∈ tall ∧ (Kai, Luis) ∉ tall := by decide

-- Has emailed: fails reflexive, passes symmetric, fails antisymmetric, fails transitive.
example : (Maya, Maya) ∉ email := by decide
example : ∀ a b : Person, (a, b) ∈ email → (b, a) ∈ email := by decide
example : (Maya, Jon) ∈ email ∧ (Jon, Maya) ∈ email ∧ Maya ≠ Jon := by decide
example : (Maya, Jon) ∈ email ∧ (Jon, Priya) ∈ email ∧ (Maya, Priya) ∉ email := by decide

-- Is at least as tall as: passes reflexive, fails symmetric, passes antisymmetric and transitive.
example : ∀ a : Person, (a, a) ∈ tall := by decide
example : (Luis, Jon) ∈ tall ∧ (Jon, Luis) ∉ tall := by decide
example : ∀ a b : Person, (a, b) ∈ tall → (b, a) ∈ tall → a = b := by decide
example : ∀ a b c : Person, (a, b) ∈ tall → (b, c) ∈ tall → (a, c) ∈ tall := by decide

-- Adding the two-step pairs over and over: email grows to all 25 pairs, and then stops.
def closeOnce (R : Finset (Person × Person)) : Finset (Person × Person) := R ∪ twoStep R
example : (closeOnce (closeOnce (closeOnce email))).card = 25 := by decide +kernel
example : twoStep (closeOnce (closeOnce (closeOnce email))) ⊆ closeOnce (closeOnce (closeOnce email)) := by
  decide +kernel

-- The broken lists: one direction only is 4 pairs and fails symmetric;
-- height with Maya's loop left out is 14 pairs and fails reflexive.
example : talked.card = 4 ∧ (Maya, Jon) ∈ talked ∧ (Jon, Maya) ∉ talked := by decide
example : (tall.erase (Maya, Maya)).card = 14 ∧ (Maya, Maya) ∉ tall.erase (Maya, Maya) := by decide

-- Try changing: add the five loops to email, reflexive turns yes and antisymmetric stays no.
example : (∀ a : Person, (a, a) ∈ email ∪ Finset.univ.image (fun a => (a, a))) ∧
    (Maya, Jon) ∈ email ∪ Finset.univ.image (fun a => (a, a)) ∧
    (Jon, Maya) ∈ email ∪ Finset.univ.image (fun a => (a, a)) := by decide
-- Try changing: Priya at 168 cm ties Maya, and antisymmetric turns to no.
def cmTie : Person → ℕ
  | Maya => 168 | Jon => 175 | Priya => 168 | Luis => 181 | Kai => 170
example : cmTie Maya ≤ cmTie Priya ∧ cmTie Priya ≤ cmTie Maya ∧ Maya ≠ Priya := by decide

#print axioms relation_tests_are_set_conditions
#print axioms symm_and_antisymm_iff_only_loops
#print axioms at_least_as_tall_tests
