-- Subsets and the power set: a finite set of n members has exactly 2^n subsets, each new member doubles the count, and the subsets that leave out one member are exactly the subsets of what remains.
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Finset.Card

open Finset

/-- A finite set with n members has exactly 2^n subsets: the power set of a finite set s,
the set of every subset of s (the empty set and s itself included), has 2 ^ (number of members
of s) members. -/
theorem card_powerset_eq_two_pow {α : Type*} (s : Finset α) :
    s.powerset.card = 2 ^ s.card := by
  simp [Finset.card_powerset]

/-- Each new member doubles the list: putting a member a that is not already in s up on the
board turns the power set into one exactly twice as big. -/
theorem card_powerset_insert_doubles {α : Type*} [DecidableEq α] (s : Finset α) (a : α)
    (ha : a ∉ s) :
    (insert a s).powerset.card = 2 * s.powerset.card := by
  rw [Finset.card_powerset, Finset.card_powerset, Finset.card_insert_of_notMem ha]
  rw [pow_succ, Nat.mul_comm]

/-- Double inclusion: the subsets of s that leave out a member a (the chilli-free pizzas) are
exactly the subsets of s with a taken off the board. -/
theorem subsets_without_eq_powerset_erase {α : Type*} [DecidableEq α] (s : Finset α) (a : α) :
    s.powerset.filter (fun t => a ∉ t) = (s.erase a).powerset := by
  ext t
  simp only [Finset.mem_filter, Finset.mem_powerset, Finset.subset_erase]

-- The pizza shop: three toppings on the board, and anchovy waiting for the fourth.
inductive Topping | mushroom | olive | chilli | anchovy
  deriving DecidableEq

open Topping

-- Three toppings, eight pizzas: 2 × 2 × 2 = 8.
example : ({mushroom, olive, chilli} : Finset Topping).card = 3 := by decide
example : ({mushroom, olive, chilli} : Finset Topping).powerset.card = 8 := by decide
example : 2 * 2 * 2 = (8 : ℕ) ∧ 2 ^ 3 = (8 : ℕ) := by decide

-- The eight pizzas, listed: plain, the three singles, the three pairs, and the loaded one.
example : ({mushroom, olive, chilli} : Finset Topping).powerset =
    {∅, {mushroom}, {olive}, {mushroom, olive}, {chilli}, {mushroom, chilli}, {olive, chilli},
      {mushroom, olive, chilli}} := by decide

-- The plain pizza and the loaded pizza are both on the menu.
example : (∅ : Finset Topping) ∈ ({mushroom, olive, chilli} : Finset Topping).powerset := by decide
example : ({mushroom, olive, chilli} : Finset Topping) ∈
    ({mushroom, olive, chilli} : Finset Topping).powerset := by decide

-- The menu size after each topping goes up: 1, 2, 4, 8, 16.
example : (∅ : Finset Topping).powerset.card = 1 := by decide
example : ({mushroom} : Finset Topping).powerset.card = 2 := by decide
example : ({mushroom, olive} : Finset Topping).powerset.card = 4 := by decide
example : ({mushroom, olive, chilli} : Finset Topping).powerset.card = 8 := by decide
example : ({mushroom, olive, chilli, anchovy} : Finset Topping).powerset.card = 16 := by decide
example : 1 * 2 = (2 : ℕ) ∧ 2 * 2 = (4 : ℕ) ∧ 4 * 2 = (8 : ℕ) := by decide

-- The chilli-free pizzas are exactly P({mushroom, olive}) = { { }, {mushroom}, {olive},
-- {mushroom, olive} }: four of them, 2 × 2.
example : ({mushroom, olive, chilli} : Finset Topping).powerset.filter (fun t => chilli ∉ t) =
    {∅, {mushroom}, {olive}, {mushroom, olive}} := by decide
example : (({mushroom, olive, chilli} : Finset Topping).powerset.filter
    (fun t => chilli ∉ t)).card = 4 := by decide
example : ({mushroom, olive} : Finset Topping).powerset =
    {∅, {mushroom}, {olive}, {mushroom, olive}} := by decide

-- Pizzas with at least one topping: 8 − 1 = 7.
example : (({mushroom, olive, chilli} : Finset Topping).powerset.filter
    (fun t => t ≠ ∅)).card = 7 := by decide
example : 8 - 1 = (7 : ℕ) := by decide

-- Each member counts once: mushroom written twice is still 3 toppings and 8 pizzas.
example : ({mushroom, mushroom, olive, chilli} : Finset Topping) = {mushroom, olive, chilli} := by
  decide
example : ({mushroom, mushroom, olive, chilli} : Finset Topping).powerset.card = 8 := by decide

-- Order does not matter: mushroom then olive is the same pizza as olive then mushroom.
example : ({mushroom, olive} : Finset Topping) = {olive, mushroom} := by decide

-- The three mistakes: 7 (plain pizza left out), 3 (toppings counted), 6 (2s added).
example : ({mushroom, olive, chilli} : Finset Topping).card = 3 := by decide
example : 2 + 2 + 2 = (6 : ℕ) ∧ 2 + 2 + 2 ≠ (8 : ℕ) := by decide

#print axioms card_powerset_eq_two_pow
#print axioms card_powerset_insert_doubles
#print axioms subsets_without_eq_powerset_erase
