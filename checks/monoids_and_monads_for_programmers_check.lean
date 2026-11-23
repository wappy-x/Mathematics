-- Monoids and monads: in a monoid every bracketing of a list gives the left-to-right fold, a fold splits across two tills, and Maybe obeys the three monad laws.
import Mathlib.Algebra.Free
import Mathlib.Algebra.Group.Defs
import Mathlib.Tactic.NormNum

/-- Folding from any start `a` is `a` times the fold from the identity. -/
theorem foldl_mul_start_eq {M : Type*} [Monoid M] (a : M) (l : List M) :
    l.foldl (· * ·) a = a * l.foldl (· * ·) 1 := by
  induction l generalizing a with
  | nil => simp
  | cons x xs ih =>
    simp only [List.foldl_cons, one_mul]
    rw [ih (a * x), ih x, mul_assoc]

#print axioms foldl_mul_start_eq

/-- The fold from the identity splits across an append. -/
theorem foldl_mul_append_eq {M : Type*} [Monoid M] (xs ys : List M) :
    (xs ++ ys).foldl (· * ·) 1 = xs.foldl (· * ·) 1 * ys.foldl (· * ·) 1 := by
  rw [List.foldl_append, foldl_mul_start_eq]

#print axioms foldl_mul_append_eq

/-- In a monoid, every way to put brackets on a list of items gives the same answer as the
fold that starts at the identity and combines the items left to right. A bracketing is a
binary tree of items (`FreeMagma M`); `FreeMagma.lift id` multiplies it out by its brackets,
and its items in order are the head and tail of its image in the free semigroup. -/
theorem every_bracketing_equals_fold {M : Type*} [Monoid M] (t : FreeMagma M) :
    FreeMagma.lift id t =
      ((FreeMagma.toFreeSemigroup t).head :: (FreeMagma.toFreeSemigroup t).tail).foldl
        (· * ·) 1 := by
  induction t with
  | ih1 x =>
    simp [FreeMagma.lift_of, FreeMagma.toFreeSemigroup_of, FreeSemigroup.of]
  | ih2 a b iha ihb =>
    rw [map_mul, map_mul, iha, ihb, FreeSemigroup.head_mul, FreeSemigroup.tail_mul,
      ← List.cons_append, foldl_mul_append_eq]

/-- Two tills: folding a list split into two parts, each started at the identity, and
combining the two answers gives the fold of the whole list; the empty list folds to the
identity. -/
theorem fold_splits_across_two_tills {M : Type*} [Monoid M] (xs ys : List M) :
    (xs ++ ys).foldl (· * ·) 1 = xs.foldl (· * ·) 1 * ys.foldl (· * ·) 1 ∧
      ([] : List M).foldl (· * ·) 1 = 1 := by
  exact ⟨foldl_mul_append_eq xs ys, rfl⟩

/-- Maybe (`Option`) obeys the three monad laws, with unit `some` and `Option.bind` as bind:
binding a wrapped value runs the step on it, binding into the unit changes nothing, and
binding f then g equals binding the combined step "f, then g". -/
theorem maybe_obeys_monad_laws {X : Type*} :
    (∀ (a : X) (f : X → Option X), (some a).bind f = f a) ∧
      (∀ m : Option X, m.bind some = m) ∧
      (∀ (m : Option X) (f g : X → Option X),
        (m.bind f).bind g = m.bind (fun x => (f x).bind g)) := by
  refine ⟨fun a f => rfl, fun m => ?_, fun m f g => ?_⟩
  · cases m <;> rfl
  · cases m <;> rfl

-- The basket, in pence: tea 249, milk 120, coffee 375, bread 89.
example : [249, 120, 375, 89].foldl (· + ·) (0 : ℕ) = 833 := by decide
example : [249, 120, 375].foldl (· + ·) (0 : ℕ) = 744 := by decide
example : (744 : ℕ) + 89 = 833 := by norm_num
example : (833 : ℕ) + 450 = 1283 := by norm_num
example : ([] : List ℕ).foldl (· + ·) 0 = 0 := by decide

-- Running total: 249, 369, 744, 833.
example : [249, 120].foldl (· + ·) (0 : ℕ) = 369 := by decide

-- Subtraction is not associative: left to right gives -335, right to left 415.
example : (((249 : ℤ) - 120) - 375) - 89 = -335 := by norm_num
example : (249 : ℤ) - (120 - (375 - 89)) = 415 := by norm_num

-- Starting the sum at 1 instead of the identity: 834 on one till, 835 on two.
example : [249, 120, 375, 89].foldl (· + ·) (1 : ℕ) = 834 := by decide
example : [249, 120, 375].foldl (· + ·) (1 : ℕ) + [89].foldl (· + ·) 1 = 835 := by decide

-- Maximum with identity 0 finds the dearest item, 375p.
example : [249, 120, 375, 89].foldl max (0 : ℕ) = 375 := by decide

-- (Sum, count) pairs fold to (833, 4).
example : [((249 : ℕ), (1 : ℕ)), (120, 1), (375, 1), (89, 1)].foldl (· + ·) (0, 0) = (833, 4) := by
  decide

-- Joining text keeps order: "LS" then "1" is "LS1", the other order "1LS".
example : "LS" ++ "1" = "LS1" ∧ "1" ++ "LS" = "1LS" := by decide

-- The four lookups for order 1001 give just 450; order 1002 stops at postcode M60.
example :
    (((some "1001").bind (fun k => [("1001", "C17"), ("1002", "C42"), ("1003", "C99")].lookup k)
      |>.bind (fun k => [("C17", "LS1"), ("C42", "M60")].lookup k)
      |>.bind (fun k => [("LS1", "Z2")].lookup k)
      |>.bind (fun k => [("Z1", "299"), ("Z2", "450"), ("Z3", "650")].lookup k))) = some "450" := by
  decide
example :
    (((some "1002").bind (fun k => [("1001", "C17"), ("1002", "C42"), ("1003", "C99")].lookup k)
      |>.bind (fun k => [("C17", "LS1"), ("C42", "M60")].lookup k)
      |>.bind (fun k => [("LS1", "Z2")].lookup k)
      |>.bind (fun k => [("Z1", "299"), ("Z2", "450"), ("Z3", "650")].lookup k))) = none := by
  decide

#print axioms every_bracketing_equals_fold
#print axioms fold_splits_across_two_tills
#print axioms maybe_obeys_monad_laws
