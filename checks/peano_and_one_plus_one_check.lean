-- Peano's three rules: in any system with a start, a next that is never the start and never shared, and induction, the two rules of plus force 1 + 1 = 2, fix plus completely, and the system is a copy of the counting numbers.
import Mathlib.Data.ZMod.Defs
import Mathlib.Logic.Function.Iterate

/-- 1 + 1 = 2 is a conclusion, not a fact. Take any system of counting numbers: a start
`zero` and a successor `next`, where no next is zero, no two numbers share a next, and
induction holds (nothing else counts as a number). Let `plus` obey the two rules
"anything plus zero is that thing" and "anything plus next(n) is next of (that thing
plus n)". Then 1 + 1 = 2, where 1 = next(zero) and 2 = next(next(zero)). -/
theorem one_add_one_eq_two_from_peano_rules {N : Type*} (zero : N) (next : N → N)
    (next_ne_zero : ∀ n, next n ≠ zero)
    (next_injective : Function.Injective next)
    (induction : ∀ P : N → Prop, P zero → (∀ n, P n → P (next n)) → ∀ n, P n)
    (plus : N → N → N)
    (rule_one : ∀ m, plus m zero = m)
    (rule_two : ∀ m n, plus m (next n) = next (plus m n)) :
    plus (next zero) (next zero) = next (next zero) := by
  rw [rule_two, rule_one]

/-- Addition is a definition, not a fourth rule: the two rules of plus pin it down
completely. Any two ways of adding that both obey rule one and rule two give the same
answer on every pair of numbers, because induction reaches every number. -/
theorem plus_unique_from_two_rules {N : Type*} (zero : N) (next : N → N)
    (induction : ∀ P : N → Prop, P zero → (∀ n, P n → P (next n)) → ∀ n, P n)
    (plus plus' : N → N → N)
    (rule_one : ∀ m, plus m zero = m)
    (rule_two : ∀ m n, plus m (next n) = next (plus m n))
    (rule_one' : ∀ m, plus' m zero = m)
    (rule_two' : ∀ m n, plus' m (next n) = next (plus' m n)) :
    ∀ m n, plus m n = plus' m n := by
  intro m n
  refine induction (fun n => plus m n = plus' m n) ?_ ?_ n
  · show plus m zero = plus' m zero
    rw [rule_one, rule_one']
  · intro k hk
    show plus m (next k) = plus' m (next k)
    rw [rule_two, rule_two']
    exact congrArg next hk

/-- The three rules pin down the counting numbers: any system with a start, a next that
is never the start and never shared, and induction, is a copy of the whole numbers.
Counting k knots from the start reaches every number exactly once. -/
theorem peano_rules_pin_down_counting_numbers {N : Type*} (zero : N) (next : N → N)
    (next_ne_zero : ∀ n, next n ≠ zero)
    (next_injective : Function.Injective next)
    (induction : ∀ P : N → Prop, P zero → (∀ n, P n → P (next n)) → ∀ n, P n) :
    ∃ f : ℕ → N, Function.Bijective f ∧ f 0 = zero ∧ ∀ k, f (k + 1) = next (f k) := by
  have hinj : ∀ k j : ℕ, next^[k] zero = next^[j] zero → k = j := by
    intro k
    induction k with
    | zero =>
      intro j h
      cases j with
      | zero => rfl
      | succ j =>
        exfalso
        rw [Function.iterate_succ_apply'] at h
        exact next_ne_zero _ h.symm
    | succ k ih =>
      intro j h
      cases j with
      | zero =>
        exfalso
        rw [Function.iterate_succ_apply'] at h
        exact next_ne_zero _ h
      | succ j =>
        rw [Function.iterate_succ_apply', Function.iterate_succ_apply'] at h
        exact congrArg Nat.succ (ih j (next_injective h))
  refine ⟨fun k => next^[k] zero, ⟨fun a b h => hinj a b h, ?_⟩, rfl, ?_⟩
  · intro y
    refine induction (fun y => ∃ a : ℕ, next^[a] zero = y) ?_ ?_ y
    · exact ⟨0, rfl⟩
    · rintro n ⟨a, ha⟩
      exact ⟨a + 1, by rw [Function.iterate_succ_apply', ha]⟩
  · intro k
    exact Function.iterate_succ_apply' next k zero

-- The numerals name short ropes: 1 = next(zero), 2 = next(next(zero)), and next(3) = 4.
example : (1 : ℕ) = Nat.succ 0 ∧ (2 : ℕ) = Nat.succ (Nat.succ 0) := by decide
example : Nat.succ 3 = (4 : ℕ) := by decide

-- The unfolding: 1 + 1 = 1 + next(zero) = next(1 + zero) = next(1) = 2.
example : (1 : ℕ) + 1 = 1 + Nat.succ 0 ∧ 1 + Nat.succ 0 = Nat.succ (1 + 0) ∧
    Nat.succ (1 + 0) = Nat.succ 1 ∧ Nat.succ 1 = (2 : ℕ) := by decide

-- The same rules on 2 + 3: next(next(next(2 + zero))) = 5.
example : (2 : ℕ) + 3 = Nat.succ (Nat.succ (Nat.succ (2 + 0))) ∧
    Nat.succ (Nat.succ (Nat.succ (2 + 0))) = (5 : ℕ) := by decide

-- Second road: tie three knots onto 2, one at a time, and land on 5.
example : Nat.succ^[3] 2 = (5 : ℕ) := by decide

-- Drop "no next is zero" (a ring of four): 2 + 3 lands on 1, because 5 and 1 are one rope.
example : (2 : ZMod 4) + 3 = 1 ∧ (5 : ZMod 4) = 1 := by decide

-- Drop "no two ropes share a next" (the far end sticks at 3): three steps from 2 land on 3.
example : (fun k : ℕ => min (k + 1) 3)^[3] 2 = 3 := by decide

#print axioms one_add_one_eq_two_from_peano_rules
#print axioms plus_unique_from_two_rules
#print axioms peano_rules_pin_down_counting_numbers
