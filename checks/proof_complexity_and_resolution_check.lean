-- Proof complexity: resolution is sound and complete (a refutation exists exactly when no assignment fits, with one of at most 2^N steps over N variables), every rota with one more person than shifts is unsatisfiable, and the café's ten-step refutation of PHP(3, 2) checks line by line.
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Finset.Image
import Mathlib.Data.List.FinRange
import Mathlib.Data.Fintype.Pigeonhole

/-! Clauses, refutations and the rota.

A literal is a variable with a sign: `(v, true)` is `v` and `(v, false)` is `¬v`. A clause is a
finite set of literals joined by "or"; a CNF formula is a list of clauses joined by "and". An
assignment `a` gives every variable true or false.

The resolution rule takes a clause holding `x` and a clause holding `¬x`, removes the pivot from
each, and joins what is left: from `C ∨ x` and `D ∨ ¬x`, conclude `C ∨ D`. A proof is a list of
steps; each step names two earlier lines (numbered from 0, the formula's own clauses first) and a
pivot, and adds their resolvent as a new line. `run` checks the steps in order and returns every
line, or `none` if some step cites a missing line or a pivot its parents do not hold. A refutation
is a proof whose lines include the empty clause; its size is the number of steps. -/

/-- A literal: a variable and a sign. -/
abbrev Lit (V : Type*) := V × Bool
/-- A clause: literals joined by "or". -/
abbrev Clause (V : Type*) := Finset (Lit V)
/-- A formula in conjunctive normal form: clauses joined by "and". -/
abbrev CNF (V : Type*) := List (Clause V)

variable {V : Type*}

/-- The assignment `a` makes the clause true: some literal of it is true. -/
def Clause.Holds (a : V → Bool) (c : Clause V) : Prop := ∃ l ∈ c, a l.1 = l.2

/-- The assignment `a` makes every clause of `F` true. -/
def CNF.Holds (a : V → Bool) (F : CNF V) : Prop := ∀ c ∈ F, c.Holds a

/-- Satisfiable: some assignment makes every clause true. -/
def Satisfiable (F : CNF V) : Prop := ∃ a : V → Bool, F.Holds a

instance [DecidableEq V] (a : V → Bool) (c : Clause V) : Decidable (c.Holds a) := by
  unfold Clause.Holds; infer_instance

instance [DecidableEq V] (a : V → Bool) (F : CNF V) : Decidable (F.Holds a) := by
  unfold CNF.Holds; infer_instance

/-- The resolvent on pivot `x`: drop `x` from `C`, drop `¬x` from `D`, join the rest. -/
def resolvent [DecidableEq V] (x : V) (C D : Clause V) : Clause V :=
  C.erase (x, true) ∪ D.erase (x, false)

/-- One resolution step: two earlier line numbers and the pivot cancelled between them. -/
structure Step (V : Type*) where
  left : ℕ
  right : ℕ
  pivot : V

/-- Check the steps in order. Each step's left line must hold the pivot and its right line must
hold the pivot's negation; the resolvent is then added as a new line. Returns all lines, or `none`
at the first step that breaks the rule. -/
def run [DecidableEq V] (lines : List (Clause V)) : List (Step V) → Option (List (Clause V))
  | [] => some lines
  | s :: rest =>
    match lines[s.left]?, lines[s.right]? with
    | some C, some D =>
      if (s.pivot, true) ∈ C ∧ (s.pivot, false) ∈ D then
        run (lines ++ [resolvent s.pivot C D]) rest
      else none
    | _, _ => none

/-- `π` is a resolution refutation of `F`: every step obeys the rule, and the lines reach the
empty clause. Its size is `π.length`. -/
def Refutes [DecidableEq V] (F : CNF V) (π : List (Step V)) : Prop :=
  ∃ L, run F π = some L ∧ (∅ : Clause V) ∈ L

instance [DecidableEq V] (F : CNF V) (π : List (Step V)) : Decidable (Refutes F π) := by
  unfold Refutes
  cases run F π with
  | none => exact isFalse (by simp)
  | some L => exact decidable_of_iff ((∅ : Clause V) ∈ L) (by simp)

/-- The rota with `n + 1` staff and `n` shifts, the pigeonhole formula PHP(n + 1, n). Variable
`(i, j)` means "staff member i works shift j". First, for each staff member, "works some shift";
then, shift by shift, for each pair `i < k` of staff, "not both on this shift". -/
def php (n : ℕ) : CNF (Fin (n + 1) × Fin n) :=
  (List.finRange (n + 1)).map (fun i => Finset.univ.image fun j : Fin n => ((i, j), true)) ++
  (List.finRange n).flatMap fun j =>
    (List.finRange (n + 1)).flatMap fun i =>
      ((List.finRange (n + 1)).filter fun k => i < k).map fun k =>
        ({((i, j), false), ((k, j), false)} : Clause (Fin (n + 1) × Fin n))

/-- Helper: the resolvent of two true parents is true. -/
theorem resolvent_holds_aux [DecidableEq V] (a : V → Bool) (x : V)
    (C D : Clause V) (hC : C.Holds a) (hD : D.Holds a) :
    (resolvent x C D).Holds a := by
  obtain ⟨l, hl, hal⟩ := hC
  by_cases hlx : l = (x, true)
  · subst hlx
    obtain ⟨m, hm, ham⟩ := hD
    refine ⟨m, ?_, ham⟩
    simp only [resolvent, Finset.mem_union, Finset.mem_erase]
    right
    refine ⟨?_, hm⟩
    rintro rfl
    simp_all
  · exact ⟨l, by simp [resolvent, hlx, hl], hal⟩

/-- Helper: running `p ++ q` is running `p`, then `q` on its lines. -/
theorem run_append_aux [DecidableEq V] (p q : List (Step V)) :
    ∀ (lines L : List (Clause V)), run lines p = some L → run lines (p ++ q) = run L q := by
  induction p with
  | nil => intro lines L h; simp only [run, Option.some.injEq] at h; subst h; rfl
  | cons s rest ih =>
    intro lines L h
    simp only [List.cons_append, run] at h ⊢
    cases hC : lines[s.left]? with
    | none => simp [hC] at h
    | some C =>
      cases hD : lines[s.right]? with
      | none => simp [hC, hD] at h
      | some D =>
        simp only [hC, hD] at h ⊢
        split_ifs at h ⊢ with hp
        exact ih _ _ h

/-- Helper: every line produced from true lines is true. -/
theorem run_sound_aux [DecidableEq V] (a : V → Bool) (π : List (Step V)) :
    ∀ (lines L : List (Clause V)), (∀ c ∈ lines, c.Holds a) → run lines π = some L →
      ∀ c ∈ L, c.Holds a := by
  induction π with
  | nil => intro lines L hl h; simp only [run, Option.some.injEq] at h; subst h; exact hl
  | cons s rest ih =>
    intro lines L hl h
    simp only [run] at h
    cases hC : lines[s.left]? with
    | none => simp [hC] at h
    | some C =>
      cases hD : lines[s.right]? with
      | none => simp [hC, hD] at h
      | some D =>
        simp only [hC, hD] at h
        split_ifs at h with hp
        refine ih _ _ ?_ h
        intro c hc
        rcases List.mem_append.1 hc with hc | hc
        · exact hl c hc
        · rw [List.mem_singleton] at hc
          subst hc
          exact resolvent_holds_aux a s.pivot C D
            (hl C (List.mem_of_getElem? hC)) (hl D (List.mem_of_getElem? hD))

/-- Helper (search tree): if every assignment agreeing with `a` off `S` falsifies a line, then
at most `2 ^ |S| - 1` steps derive a line falsified by `a` that uses no variable of `S`. -/
theorem refute_aux [DecidableEq V] (S : Finset V) : ∀ (a : V → Bool) (lines : List (Clause V)),
    (∀ b : V → Bool, (∀ v ∉ S, b v = a v) → ∃ c ∈ lines, ∀ l ∈ c, b l.1 ≠ l.2) →
    ∃ (π : List (Step V)) (M : List (Clause V)), run lines π = some (lines ++ M) ∧
      π.length + 1 ≤ 2 ^ S.card ∧ ∃ c ∈ lines ++ M, ∀ l ∈ c, l.1 ∉ S ∧ a l.1 ≠ l.2 := by
  induction S using Finset.induction_on with
  | empty =>
    intro a lines h
    obtain ⟨c, hc, hf⟩ := h a (fun _ _ => rfl)
    exact ⟨[], [], by simp [run], by simp, c, by simpa using hc,
      fun l hl => ⟨Finset.notMem_empty _, hf l hl⟩⟩
  | insert x S hx ih =>
    intro a lines h
    have hcard : (insert x S).card = S.card + 1 := Finset.card_insert_of_notMem hx
    have agree : ∀ (t : Bool) (b : V → Bool), (∀ v ∉ S, b v = Function.update a x t v) →
        ∀ v ∉ insert x S, b v = a v := by
      intro t b hb v hv
      rw [Finset.mem_insert, not_or] at hv
      rw [hb v hv.2, Function.update_of_ne hv.1]
    have lift : ∀ (t : Bool) (c : Clause V),
        (∀ l ∈ c, l.1 ∉ S ∧ Function.update a x t l.1 ≠ l.2) →
        ∀ l ∈ c, l ≠ (x, !t) → l.1 ∉ insert x S ∧ a l.1 ≠ l.2 := by
      intro t c hc l hl hne
      obtain ⟨h1, h2⟩ := hc l hl
      by_cases hlx : l.1 = x
      · exfalso
        apply hne
        obtain ⟨v, s⟩ := l
        simp only at hlx
        subst hlx
        rw [Function.update_self] at h2
        revert h2
        cases t <;> cases s <;> simp
      · refine ⟨by simp [hlx, h1], ?_⟩
        rwa [Function.update_of_ne hlx] at h2
    obtain ⟨π1, M1, hr1, hl1, C1, hC1, hf1⟩ :=
      ih (Function.update a x true) lines (fun b hb => h b (agree true b hb))
    by_cases hx1 : (x, false) ∈ C1
    · obtain ⟨π0, M0, hr0, hl0, C0, hC0, hf0⟩ :=
        ih (Function.update a x false) (lines ++ M1) (fun b hb => by
          obtain ⟨c, hc, hf⟩ := h b (agree false b hb)
          exact ⟨c, List.mem_append_left _ hc, hf⟩)
      by_cases hx0 : (x, true) ∈ C0
      · obtain ⟨i, hi⟩ := List.mem_iff_getElem?.1 hC0
        obtain ⟨j, hj⟩ := List.mem_iff_getElem?.1 (List.mem_append_left M0 hC1)
        refine ⟨π1 ++ π0 ++ [⟨i, j, x⟩], M1 ++ M0 ++ [resolvent x C0 C1], ?_, ?_,
          resolvent x C0 C1, by simp, ?_⟩
        · rw [List.append_assoc, run_append_aux _ _ _ _ hr1, run_append_aux _ _ _ _ hr0]
          simp only [run]
          rw [hi, hj]
          simp [hx0, hx1]
        · simp only [List.length_append, List.length_singleton, hcard, pow_succ]
          omega
        · intro l hl
          simp only [resolvent, Finset.mem_union, Finset.mem_erase] at hl
          rcases hl with ⟨hne, hl⟩ | ⟨hne, hl⟩
          · exact lift false C0 hf0 l hl hne
          · exact lift true C1 hf1 l hl hne
      · refine ⟨π1 ++ π0, M1 ++ M0, ?_, ?_, C0, by simpa using hC0,
          fun l hl => lift false C0 hf0 l hl (by rintro rfl; exact hx0 hl)⟩
        · rw [run_append_aux _ _ _ _ hr1, hr0, List.append_assoc]
        · simp only [List.length_append, hcard, pow_succ]
          omega
    · refine ⟨π1, M1, hr1, ?_, C1, hC1, fun l hl => lift true C1 hf1 l hl (by rintro rfl; exact hx1 hl)⟩
      rw [hcard, pow_succ]
      omega

/-- Resolution is sound and complete. Sound: if some list of resolution steps reaches the empty
clause from the clauses of `F`, no assignment makes every clause of `F` true. Complete: if no
assignment makes every clause of `F` true, a resolution refutation exists, read off a failed
search tree, with at most `2 ^ N` steps, where `N` is the number of variables. -/
theorem resolution_sound_and_complete [DecidableEq V] [Fintype V] (F : CNF V) :
    (∀ π : List (Step V), Refutes F π → ¬ Satisfiable F) ∧
    (¬ Satisfiable F → ∃ π : List (Step V), Refutes F π ∧ π.length ≤ 2 ^ Fintype.card V) := by
  refine ⟨fun π hπ hsat => ?_, fun hF => ?_⟩
  · obtain ⟨a, ha⟩ := hsat
    obtain ⟨L, hL, he⟩ := hπ
    obtain ⟨l, hl, _⟩ := run_sound_aux a π F L ha hL ∅ he
    simp at hl
  · obtain ⟨π, M, hr, hlen, c, hc, hf⟩ :=
      refute_aux (Finset.univ : Finset V) (fun _ => false) F (fun b _ => by
        by_contra hne
        exact hF ⟨b, fun c hc => by
          by_contra h'
          exact hne ⟨c, hc, fun l hl he => h' ⟨l, hl, he⟩⟩⟩)
    have hc0 : c = ∅ := by
      ext l
      simp only [Finset.notMem_empty, iff_false]
      exact fun hl => (hf l hl).1 (Finset.mem_univ _)
    rw [Finset.card_univ] at hlen
    exact ⟨π, ⟨F ++ M, hr, hc0 ▸ hc⟩, by omega⟩

/-- One step derives only true clauses: any assignment that makes both parents `C ∨ x` and
`D ∨ ¬x` true also makes their resolvent `C ∨ D` true. -/
theorem resolvent_true_where_parents_true [DecidableEq V] (a : V → Bool) (x : V)
    (C D : Clause V) (hC : C.Holds a) (hD : D.Holds a)
    (hx : (x, true) ∈ C) (hnx : (x, false) ∈ D) :
    (resolvent x C D).Holds a := by
  have _ := hx; have _ := hnx
  exact resolvent_holds_aux a x C D hC hD

/-- No rota fits: for every `n`, no way of answering the questions "does staff member i work
shift j" gives each of the `n + 1` staff a shift with no two sharing one, so PHP(n + 1, n) is
unsatisfiable. -/
theorem pigeonhole_formula_unsatisfiable (n : ℕ) : ¬ Satisfiable (php n) := by
  rintro ⟨a, ha⟩
  have h1 : ∀ i : Fin (n + 1), ∃ j : Fin n, a (i, j) = true := by
    intro i
    obtain ⟨l, hl, hal⟩ := ha _ (List.mem_append_left _ (List.mem_map.2 ⟨i, List.mem_finRange i, rfl⟩))
    simp only [Finset.mem_image, Finset.mem_univ, true_and] at hl
    obtain ⟨j, rfl⟩ := hl
    exact ⟨j, hal⟩
  choose f hf using h1
  obtain ⟨i, k, hne, hik⟩ := Fintype.exists_ne_map_eq_of_card_lt f (by simp)
  have key : ∀ i k, i < k → f i = f k → False := by
    intro i k hlt heq
    have hmem : ({((i, f i), false), ((k, f i), false)} : Clause (Fin (n + 1) × Fin n)) ∈ php n := by
      apply List.mem_append_right
      simp only [List.mem_flatMap, List.mem_map, List.mem_filter, List.mem_finRange, true_and,
        decide_eq_true_eq]
      exact ⟨f i, i, k, hlt, rfl⟩
    obtain ⟨l, hl, hal⟩ := ha _ hmem
    simp only [Finset.mem_insert, Finset.mem_singleton] at hl
    rcases hl with rfl | rfl
    · simp [hf i] at hal
    · simp [heq, hf k] at hal
  rcases lt_or_gt_of_ne hne with h | h
  · exact key i k h hik
  · exact key k i h hik.symm

/-! The café: Ann, Bob and Kim are staff 0, 1 and 2; early and late are shifts 0 and 1. -/

/-- `st i j x`: resolve line (i) with line (j) on pivot `x`, lines numbered from 1 as on the card. -/
def st (i j : ℕ) (x : Fin 3 × Fin 2) : Step (Fin 3 × Fin 2) := ⟨i - 1, j - 1, x⟩

/-- The card's ten-step hand refutation, lines (10) to (19). -/
def cafeProof : List (Step (Fin 3 × Fin 2)) :=
  [st 2 4 (1, 0), st 3 5 (2, 0), st 10 9 (1, 1), st 11 12 (2, 1), st 2 7 (1, 1),
   st 3 8 (2, 1), st 14 6 (1, 0), st 15 16 (2, 0), st 1 13 (0, 0), st 18 17 (0, 1)]

/-- The derived lines (10) to (19) as the card writes them. -/
def cafeLines : List (Clause (Fin 3 × Fin 2)) :=
  [{((0, 0), false), ((1, 1), true)},  -- (10) ¬a1 ∨ b2
   {((0, 0), false), ((2, 1), true)},  -- (11) ¬a1 ∨ k2
   {((0, 0), false), ((2, 1), false)}, -- (12) ¬a1 ∨ ¬k2
   {((0, 0), false)},                  -- (13) ¬a1
   {((0, 1), false), ((1, 0), true)},  -- (14) ¬a2 ∨ b1
   {((0, 1), false), ((2, 0), true)},  -- (15) ¬a2 ∨ k1
   {((0, 1), false), ((2, 0), false)}, -- (16) ¬a2 ∨ ¬k1
   {((0, 1), false)},                  -- (17) ¬a2
   {((0, 1), true)},                   -- (18) a2
   ∅]                                  -- (19) the empty clause

-- PHP(3, 2): 6 variables and 3 + 2 × 3 = 9 clauses.
example : Fintype.card (Fin 3 × Fin 2) = 6 ∧ (php 2).length = 9 := by decide +kernel
-- Brute force: of the 2^6 = 64 assignments, none makes every clause true.
example : Fintype.card (Fin 3 × Fin 2 → Bool) = 64 ∧
    (Finset.univ.filter fun a : Fin 3 × Fin 2 → Bool => (php 2).Holds a).card = 0 := by
  decide +kernel
-- The hand proof: the checker accepts all 10 steps, and they produce exactly lines (10) to (19).
example : run (php 2) cafeProof = some (php 2 ++ cafeLines) := by decide +kernel
example : Refutes (php 2) cafeProof ∧ cafeProof.length = 10 := by decide +kernel
-- Clause (9) dropped: exactly 1 rota fits (Ann early, Bob and Kim both late).
example : (Finset.univ.filter fun a : Fin 3 × Fin 2 → Bool => CNF.Holds a ((php 2).take 8)).card = 1 := by
  decide +kernel
-- Two pivots at once is not resolution: a1 ∨ a2 and ¬a1 ∨ ¬a2 are both true on 2 of the 4
-- assignments to a1, a2.
example : (Finset.univ.filter fun a : Fin 2 → Bool =>
    CNF.Holds a [{(0, true), (1, true)}, {(0, false), (1, false)}]).card = 2 := by decide +kernel
-- Haken's critical assignments for the café: exactly 6 = 3! assignments make exactly one clause
-- false, and that clause is one of the "needs a shift" clauses (1) to (3).
example : (Finset.univ.filter fun a : Fin 3 × Fin 2 → Bool =>
    ((php 2).filter fun c => ¬ c.Holds a).length = 1 ∧
    ∀ c ∈ (php 2).drop 3, c.Holds a).card = 6 := by decide +kernel
-- The rota at 6 shifts: 7 + 6 × 21 = 133 clauses; cutting planes needs 2n(n - 1) + 1 lines,
-- 5 at n = 2 and 61 at n = 6.
example : (php 6).length = 133 := by decide +kernel
example : 2 * 2 * (2 - 1) + 1 = 5 ∧ 2 * 6 * (6 - 1) + 1 = 61 := by decide

#print axioms resolvent_holds_aux
#print axioms run_append_aux
#print axioms run_sound_aux
#print axioms refute_aux
#print axioms resolution_sound_and_complete
#print axioms resolvent_true_where_parents_true
#print axioms pigeonhole_formula_unsatisfiable
