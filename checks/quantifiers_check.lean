-- Quantifiers: one thing that works for everyone always gives everyone something that works, the reverse can fail, and the card's office of six people and three keys is a case where it does.
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum

/-- One key everyone has always gives everyone a key: for any group of people, any set of
keys and any rule saying who carries what, if some key is carried by every person, then every
person carries some key. -/
theorem exists_forall_imp_forall_exists {Person Key : Type*} (carries : Person → Key → Prop) :
    (∃ k, ∀ p, carries p k) → ∀ p, ∃ k, carries p k := by
  rintro ⟨k, hk⟩ p
  exact ⟨k, hk p⟩

/-- The reverse can fail: it is not true that for every group of people, every set of keys
and every rule of who carries what, "every person carries some key" gives "some key is carried
by every person". -/
theorem not_forall_exists_imp_exists_forall :
    ¬ ∀ (Person Key : Type) (carries : Person → Key → Prop),
      (∀ p, ∃ k, carries p k) → ∃ k, ∀ p, carries p k := by
  intro h
  obtain ⟨k, hk⟩ := h Bool Bool (fun p k => p = k) (fun p => ⟨p, rfl⟩)
  have := hk (!k)
  cases k <;> simp at this

/-- The office on the card. -/
inductive Person
  | ana | ben | cara | dev | eve | finn
  deriving DecidableEq

inductive Key
  | front | store | server
  deriving DecidableEq

open Person Key

instance : Fintype Person :=
  ⟨{ana, ben, cara, dev, eve, finn}, fun p => by cases p <;> decide⟩

instance : Fintype Key :=
  ⟨{front, store, server}, fun k => by cases k <;> decide⟩

/-- Ana carries front and store, Ben and Dev carry front, Cara and Eve carry front and server,
Finn carries store alone. -/
def carries : Person → Key → Bool
  | ana, front => true
  | ana, store => true
  | ben, front => true
  | cara, front => true
  | cara, server => true
  | dev, front => true
  | eve, front => true
  | eve, server => true
  | finn, store => true
  | _, _ => false

/-- In this office everyone has a key, but there is no one key that everyone has. -/
theorem office_everyone_has_a_key_but_no_master_key :
    (∀ p : Person, ∃ k : Key, carries p k = true) ∧ ¬ ∃ k : Key, ∀ p : Person, carries p k = true := by
  constructor <;> decide

-- Keys carried, person by person: Ana 2, Ben 1, Cara 2, Dev 1, Eve 2, Finn 1.
example : [ana, ben, cara, dev, eve, finn].map
    (fun p => (Finset.univ.filter (fun k => carries p k = true)).card) = [2, 1, 2, 1, 2, 1] := by
  decide

-- People reached, key by key: front 5, store 2, server 2.
example : [front, store, server].map
    (fun k => (Finset.univ.filter (fun p => carries p k = true)).card) = [5, 2, 2] := by
  decide

-- The nine carryings, added across the people and again down the keys.
example : (Finset.univ.filter (fun pk : Person × Key => carries pk.1 pk.2 = true)).card = 9 := by
  decide

example : (2 + 1 + 2 + 1 + 2 + 1 : ℕ) = 9 ∧ (5 + 2 + 2 : ℕ) = 9 := by norm_num

-- Everyone has a key: True.
example : ∀ p : Person, ∃ k : Key, carries p k = true := by decide

-- There is one key everyone has: False. Front misses Finn.
example : ¬ ∃ k : Key, ∀ p : Person, carries p k = true := by decide

example : carries finn front = false := by decide

-- Shrink the office to the five who carry front: there is one key everyone has turns True, 5 of 5.
example : ∃ k : Key, ∀ p ∈ [ana, ben, cara, dev, eve], carries p k = true := by decide

-- "Some" means at least one: Ana carries 2 keys and still counts as having a key.
example : (Finset.univ.filter (fun k => carries ana k = true)).card = 2 ∧
    ∃ k : Key, carries ana k = true := by decide

#print axioms exists_forall_imp_forall_exists
#print axioms not_forall_exists_imp_exists_forall
#print axioms office_everyone_has_a_key_but_no_master_key
