-- Normal forms: every true-or-false table on n inputs equals the "or" of one "and" per true row (DNF) and the "and" of one clause per false row (CNF), NAND alone builds every table, and "and" with "or" alone cannot build "not".
import Mathlib.Data.Fintype.Pi

theorem ite_bool_eq_true_iff_eq (a b : Bool) : ((if a then b else !b) = true) ↔ a = b := by
  cases a <;> cases b <;> decide

theorem ite_not_bool_eq_true_iff_ne (a b : Bool) : ((if a then !b else b) = true) ↔ a ≠ b := by
  cases a <;> cases b <;> decide

#print axioms ite_bool_eq_true_iff_eq
#print axioms ite_not_bool_eq_true_iff_ne

/-- Every truth table is an "or" of "and"s and an "and" of "or"s. A rule `f` on `n` true-or-false
inputs is fixed by its table. Suppose the table has a true row and a false row. Then on every
input `x`, the rule is true exactly when
* (DNF) some true row `r` has its "and" term true at `x`: the term puts "not" on each input
  that is false in `r`, so it is true only on the row `r`; and exactly when
* (CNF) every false row `r` has its clause true at `x`: the clause puts "not" on each input
  that is true in `r` and joins them with "or", so it is false only on the row `r`. -/
theorem truth_table_eq_dnf_and_cnf {n : ℕ} (f : (Fin n → Bool) → Bool)
    (htrue : ∃ r, f r = true) (hfalse : ∃ r, f r = false) (x : Fin n → Bool) :
    (f x = true ↔
      ∃ r ∈ Finset.univ.filter (fun r => f r = true),
        ∀ i, (if r i then x i else !x i) = true) ∧
    (f x = true ↔
      ∀ r ∈ Finset.univ.filter (fun r => f r = false),
        ∃ i, (if r i then !x i else x i) = true) := by
  simp only [ite_bool_eq_true_iff_eq, ite_not_bool_eq_true_iff_ne, Finset.mem_filter,
    Finset.mem_univ, true_and]
  constructor
  · constructor
    · intro hx
      exact ⟨x, hx, fun i => rfl⟩
    · rintro ⟨r, hr, h⟩
      have : r = x := funext h
      subst this
      exact hr
  · constructor
    · intro hx r hr
      by_contra hc
      simp only [not_exists, not_not] at hc
      have : r = x := funext hc
      subst this
      rw [hx] at hr
      exact Bool.noConfusion hr
    · intro h
      by_contra hx
      simp only [Bool.not_eq_true] at hx
      obtain ⟨i, hi⟩ := h x hx
      exact hi rfl

/-- NAND alone builds every table. Take any collection of rules on `n ≥ 1` inputs that holds
each single input and holds `NAND(g, h)` ("not both") whenever it holds `g` and `h`. Then it
holds every rule on those inputs. -/
theorem nand_builds_every_table {n : ℕ} (hn : 0 < n) (S : Set ((Fin n → Bool) → Bool))
    (hvar : ∀ i, (fun x => x i) ∈ S)
    (hnand : ∀ g ∈ S, ∀ h ∈ S, (fun x => !(g x && h x)) ∈ S)
    (f : (Fin n → Bool) → Bool) : f ∈ S := by
  have h0 : (fun x : Fin n → Bool => x ⟨0, hn⟩) ∈ S := hvar _
  have hnot : ∀ g ∈ S, (fun x => !g x) ∈ S := by
    intro g hg
    convert hnand g hg g hg using 1
    funext x
    simp
  have hand : ∀ g ∈ S, ∀ h ∈ S, (fun x => g x && h x) ∈ S := by
    intro g hg h hh
    convert hnot _ (hnand g hg h hh) using 1
    funext x
    simp
  have hor : ∀ g ∈ S, ∀ h ∈ S, (fun x => g x || h x) ∈ S := by
    intro g hg h hh
    convert hnand _ (hnot g hg) _ (hnot h hh) using 1
    funext x
    cases g x <;> cases h x <;> rfl
  have htrue : (fun _ : Fin n → Bool => true) ∈ S := by
    convert hor _ h0 _ (hnot _ h0) using 1
    funext x
    cases x ⟨0, hn⟩ <;> rfl
  have hfalse : (fun _ : Fin n → Bool => false) ∈ S := by
    convert hnot _ htrue using 1
    funext x
    rfl
  have hlit : ∀ (a : Fin n → Bool) (i : Fin n),
      (fun x : Fin n → Bool => decide (x i = a i)) ∈ S := by
    intro a i
    cases ha : a i
    · convert hnot _ (hvar i) using 1
      funext x
      cases x i <;> rfl
    · convert hvar i using 1
      funext x
      cases x i <;> rfl
  have hpt : ∀ (a : Fin n → Bool) (U : Finset (Fin n)),
      (fun x : Fin n → Bool => decide (∀ i ∈ U, x i = a i)) ∈ S := by
    intro a U
    induction U using Finset.induction_on with
    | empty =>
      convert htrue using 1
      funext x
      simp
    | insert j U hj ih =>
      convert hand _ (hlit a j) _ ih using 1
      funext x
      simp
  have hset : ∀ T : Finset (Fin n → Bool), (fun x => decide (x ∈ T)) ∈ S := by
    intro T
    induction T using Finset.induction_on with
    | empty =>
      convert hfalse using 1
      funext x
      simp
    | insert a T ha ih =>
      convert hor _ (hpt a Finset.univ) _ ih using 1
      funext x
      simp [funext_iff]
  convert hset (Finset.univ.filter (fun r => f r = true)) using 1
  funext x
  cases hfx : f x <;> simp [hfx]

/-- "And" with "or" alone is not complete: on `n ≥ 1` inputs, building from the single inputs
with "and" and "or" never gives "not A" (the first input negated). -/
theorem and_or_cannot_build_not {n : ℕ} (hn : 0 < n) :
    ¬ ∀ S : Set ((Fin n → Bool) → Bool),
        (∀ i, (fun x => x i) ∈ S) →
        (∀ g ∈ S, ∀ h ∈ S, (fun x => g x && h x) ∈ S) →
        (∀ g ∈ S, ∀ h ∈ S, (fun x => g x || h x) ∈ S) →
        (fun x => !x ⟨0, hn⟩) ∈ S := by
  intro h
  have := h {g | g (fun _ => true) = true} (fun i => rfl)
    (fun g hg k hk => by change g _ = true at hg; change k _ = true at hk; show (g _ && k _) = true; rw [hg, hk]; rfl)
    (fun g hg k hk => by change g _ = true at hg; change k _ = true at hk; show (g _ || k _) = true; rw [hg, hk]; rfl)
  exact Bool.noConfusion this

-- Step 4: NAND builds "not", "and" and "or" (NAND(X, Y) is `!(X && Y)`).
example : ∀ x : Bool, !(x && x) = !x := by decide
example : ∀ x y : Bool, !(!(x && y) && !(x && y)) = (x && y) := by decide
example : ∀ x y : Bool, !(!(x && x) && !(y && y)) = (x || y) := by decide

-- The club door, E = not A or I. Its table, rows (A, I) = 11, 10, 01, 00, is 1, 0, 1, 1.
example : [(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => !p.1 || p.2) = [true, false, true, true] := by decide
-- DNF from the three true rows; CNF is the single clause from the one false row.
example : ∀ a i : Bool, ((!a && !i) || (!a && i) || (a && i)) = (!a || i) := by decide
-- NAND(I, I) is 0, 1, 0, 1 down the rows, and NAND(A, NAND(I, I)) gives the rule's column.
example : [true, false, true, false].map (fun i => !(i && i)) = [false, true, false, true] := by
  decide
example : ∀ a i : Bool, !(a && !(i && i)) = (!a || i) := by decide
-- NOR: E is "not" of NOR(not A, I), with not A = NOR(A, A).
example : ∀ a i : Bool,
    let nor := fun x y : Bool => !(x || y)
    nor (nor (nor a a) i) (nor (nor a a) i) = (!a || i) := by decide
-- The four mistakes agree with the rule on 0, 3, 2 and 2 of the 4 rows.
example :
    let rows := [(true, true), (true, false), (false, true), (false, false)]
    let agree := fun m : Bool → Bool → Bool =>
      rows.countP (fun p : Bool × Bool => m p.1 p.2 == (!p.1 || p.2))
    agree (fun a i => (!a || !i) && (a || !i) && (a || i)) = 0 ∧
    agree (fun a i => (!a && !i) || (!a && i)) = 3 ∧
    agree (fun a i => !(a && i)) = 2 ∧
    agree (fun a i => a || !i) = 2 := by decide

#print axioms truth_table_eq_dnf_and_cnf
#print axioms nand_builds_every_table
#print axioms and_or_cannot_build_not
