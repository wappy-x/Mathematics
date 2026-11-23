-- Cook-Levin: the CNF formula written from a fixed tape machine's run on a grid of W cells and t + 1 steps is satisfiable exactly when some allowed certificate is accepted within t steps, it has at most the card's polynomial number of clauses, its satisfying settings are fixed by their start row, and the card's sudoku row checker accepts exactly the fillings 2, 3 and 3, 2.
import Mathlib.Computability.TuringMachine.Tape
import Mathlib.Data.Finset.Dedup
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

open Turing

namespace CookLevin

/-! ## CNF formulas

A literal is a variable with a sign: `pos = true` is the variable, `pos = false` its negation.
A clause is an OR of literals, a CNF formula an AND of clauses. -/

/-- A literal over variables of type `α`. -/
structure Lit (α : Type*) where
  var : α
  pos : Bool

/-- A clause: an OR of literals. -/
abbrev Clause (α : Type*) := List (Lit α)

/-- A CNF formula: an AND of clauses. -/
abbrev CNF (α : Type*) := List (Clause α)

/-- The assignment `a` makes the formula true: every clause has a literal that `a` makes true. -/
def Satisfies {α : Type*} (a : α → Bool) (φ : CNF α) : Prop :=
  ∀ C ∈ φ, ∃ l ∈ C, a l.var = l.pos

/-- SAT's question for one formula: some assignment makes it true. -/
def Satisfiable {α : Type*} (φ : CNF α) : Prop :=
  ∃ a : α → Bool, Satisfies a φ

/-- The literal "v is true". -/
def pos {α : Type*} (v : α) : Lit α := ⟨v, true⟩

/-- The literal "v is false". -/
def neg {α : Type*} (v : α) : Lit α := ⟨v, false⟩

/-- At most one of the listed variables is true: one clause `¬a ∨ ¬b` per pair. -/
def atMostOne {α : Type*} : List α → CNF α
  | [] => []
  | a :: rest => rest.map (fun b => [neg a, neg b]) ++ atMostOne rest

/-- Exactly one of the listed variables is true: one "at least one" clause, then the pairs. -/
def exactlyOne {α : Type*} (xs : List α) : CNF α :=
  xs.map pos :: atMostOne xs

/-! ## The machine on a grid of W cells

A fixed machine: finitely many states `Q` and tape symbols `Γ`, a start state, an accept state
A and a reject state R, and a rule table `δ q s = some (b, d, q')` (write `b`, move one cell in
direction `d`, go to `q'`), `none` where there is no rule. A and R are halting states: once
there, the machine stays put. The tape is the grid's `W` cells; a missing rule, or a move off
the grid, ends the run with no verdict. -/

/-- A fixed tape machine with accept and reject states. -/
structure Machine (Q Γ : Type*) where
  start : Q
  accept : Q
  reject : Q
  δ : Q → Γ → Option (Γ × Dir × Q)

/-- One row of the grid: the state, the head's cell and the tape. -/
structure Config (Q Γ : Type*) (W : ℕ) where
  state : Q
  head : Fin W
  tape : Fin W → Γ

/-- The head's next cell, or `none` for a move off the grid. -/
def moveHead {W : ℕ} (j : Fin W) : Dir → Option (Fin W)
  | .left => if h : 0 < j.val then some ⟨j.val - 1, by omega⟩ else none
  | .right => if h : j.val + 1 < W then some ⟨j.val + 1, h⟩ else none

variable {Q Γ : Type*} [DecidableEq Q] {W : ℕ}

/-- The state halts: it is A or R. -/
def Machine.Halts (M : Machine Q Γ) (q : Q) : Prop := q = M.accept ∨ q = M.reject

instance (M : Machine Q Γ) (q : Q) : Decidable (M.Halts q) := by
  unfold Machine.Halts; infer_instance

/-- One step: a halting state copies the row; otherwise apply the rule for (state, symbol under
the head). `none` when there is no rule or the move leaves the grid. -/
def Machine.step (M : Machine Q Γ) (c : Config Q Γ W) : Option (Config Q Γ W) :=
  if M.Halts c.state then some c else
    match M.δ c.state (c.tape c.head) with
    | none => none
    | some (b, d, q') =>
        (moveHead c.head d).map fun j' => ⟨q', j', Function.update c.tape c.head b⟩

/-- The row after `k` steps from `c`, or `none` if the run broke off before step `k`. -/
def Machine.run (M : Machine Q Γ) : ℕ → Config Q Γ W → Option (Config Q Γ W)
  | 0, c => some c
  | k + 1, c => (M.step c).bind (M.run k)

/-- The machine, started at `c`, is in the accept state A at some step `k ≤ t`. -/
def Machine.AcceptsWithin (M : Machine Q Γ) (t : ℕ) (c : Config Q Γ W) : Prop :=
  ∃ k ≤ t, (M.run k c).map Config.state = some M.accept

instance (M : Machine Q Γ) (t : ℕ) (c : Config Q Γ W) : Decidable (M.AcceptsWithin t c) := by
  unfold Machine.AcceptsWithin; infer_instance

/-! ## The formula φ_x

Variables: `cell i j s` (at step `i`, cell `j` holds `s`), `state i q` (at step `i` the state
is `q`) and `head i j` (at step `i` the head is at cell `j`). The start row is described cell by
cell by `allowed j`, the symbols cell `j` may hold at step 0: one symbol for the input's given
cells, the certificate's symbols for its free cells. A certificate is a start tape `w` with
`w j ∈ allowed j` for every cell. -/

/-- The grid's yes-or-no variables. -/
inductive Var (Q Γ : Type*) (W : ℕ)
  | cell : ℕ → Fin W → Γ → Var Q Γ W
  | state : ℕ → Q → Var Q Γ W
  | head : ℕ → Fin W → Var Q Γ W

variable [Fintype Q] [Fintype Γ] [DecidableEq Γ]

/-- All states, listed once each. -/
noncomputable def allStates (Q : Type*) [Fintype Q] : List Q := (Finset.univ : Finset Q).toList

/-- All tape symbols, listed once each. -/
noncomputable def allSymbols (Γ : Type*) [Fintype Γ] : List Γ := (Finset.univ : Finset Γ).toList

/-- Φ_one: in each of rows 0 to t, every cell holds exactly one symbol, there is exactly one
state and exactly one head position. -/
noncomputable def phiOne (Q Γ : Type*) [Fintype Q] [Fintype Γ] (W t : ℕ) : CNF (Var Q Γ W) :=
  (List.range (t + 1)).flatMap fun i =>
    ((List.finRange W).flatMap fun j => exactlyOne ((allSymbols Γ).map (Var.cell i j))) ++
    exactlyOne ((allStates Q).map (Var.state i)) ++
    exactlyOne ((List.finRange W).map (Var.head i))

/-- Φ_start: row 0 is in the start state with the head at `h0`, and cell `j` holds one of the
symbols `allowed j`. -/
noncomputable def phiStart (M : Machine Q Γ) (allowed : Fin W → Finset Γ) (h0 : Fin W) :
    CNF (Var Q Γ W) :=
  [pos (Var.state 0 M.start)] :: [pos (Var.head 0 h0)] ::
    (List.finRange W).map fun j => (allowed j).toList.map fun s => pos (Var.cell 0 j s)

/-- The clauses for one step `i`, cell `j`, state `q` and symbol `s`. With the premise "head at
`j`, state `q`, cell `j` holds `s`" in front, a halting state copies the cell, the state and the
head; a rule fixes the symbol written, the next state and the new head cell; a pair with no rule,
or a move off the grid, gets one clause saying it never happens. -/
def ruleClauses (M : Machine Q Γ) (i : ℕ) (j : Fin W) (q : Q) (s : Γ) : CNF (Var Q Γ W) :=
  let pre : Clause (Var Q Γ W) :=
    [neg (Var.head i j), neg (Var.state i q), neg (Var.cell i j s)]
  if M.Halts q then
    [pre ++ [pos (Var.cell (i + 1) j s)], pre ++ [pos (Var.state (i + 1) q)],
      pre ++ [pos (Var.head (i + 1) j)]]
  else
    match M.δ q s with
    | none => [pre]
    | some (b, d, q') =>
        match moveHead j d with
        | none => [pre]
        | some j' =>
            [pre ++ [pos (Var.cell (i + 1) j b)], pre ++ [pos (Var.state (i + 1) q')],
              pre ++ [pos (Var.head (i + 1) j')]]

/-- Φ_rule: the rule and no-rule clauses for every step before `t`. -/
noncomputable def phiRule (M : Machine Q Γ) (t : ℕ) : CNF (Var Q Γ W) :=
  (List.range t).flatMap fun i => (List.finRange W).flatMap fun j =>
    (allStates Q).flatMap fun q => (allSymbols Γ).flatMap fun s => ruleClauses M i j q s

/-- Φ_frame: a cell away from the head keeps its symbol. -/
noncomputable def phiFrame (Q Γ : Type*) [Fintype Γ] (W t : ℕ) : CNF (Var Q Γ W) :=
  (List.range t).flatMap fun i => (List.finRange W).flatMap fun j =>
    (allSymbols Γ).map fun s =>
      [pos (Var.head i j), neg (Var.cell i j s), pos (Var.cell (i + 1) j s)]

/-- Φ_accept: the run ends in the accept state. -/
def phiAccept (M : Machine Q Γ) (t : ℕ) : CNF (Var Q Γ W) :=
  [[pos (Var.state t M.accept)]]

/-- The whole formula φ_x = Φ_one ∧ Φ_start ∧ Φ_rule ∧ Φ_frame ∧ Φ_accept. -/
noncomputable def tableau (M : Machine Q Γ) (allowed : Fin W → Finset Γ) (h0 : Fin W) (t : ℕ) :
    CNF (Var Q Γ W) :=
  phiOne Q Γ W t ++ phiStart M allowed h0 ++ phiRule M t ++ phiFrame Q Γ W t ++ phiAccept M t

/-! ## Helper lemmas for the proofs -/

theorem satisfies_append {α : Type*} (a : α → Bool) (φ ψ : CNF α) :
    Satisfies a (φ ++ ψ) ↔ Satisfies a φ ∧ Satisfies a ψ := by
  unfold Satisfies
  simp only [List.mem_append]
  constructor
  · intro h
    exact ⟨fun C hC => h C (Or.inl hC), fun C hC => h C (Or.inr hC)⟩
  · rintro ⟨h1, h2⟩ C (hC | hC)
    exacts [h1 C hC, h2 C hC]

theorem satisfies_cons {α : Type*} (a : α → Bool) (C : Clause α) (φ : CNF α) :
    Satisfies a (C :: φ) ↔ (∃ l ∈ C, a l.var = l.pos) ∧ Satisfies a φ := by
  unfold Satisfies
  simp

theorem satisfies_flatMap {α β : Type*} (a : α → Bool) (l : List β) (f : β → CNF α) :
    Satisfies a (l.flatMap f) ↔ ∀ x ∈ l, Satisfies a (f x) := by
  unfold Satisfies
  simp only [List.mem_flatMap]
  constructor
  · intro h x hx C hC
    exact h C ⟨x, hx, hC⟩
  · rintro h C ⟨x, hx, hC⟩
    exact h x hx C hC

theorem satisfies_atMostOne {α : Type*} (a : α → Bool) (xs : List α) :
    Satisfies a (atMostOne xs) ↔ xs.Pairwise (fun x y => a x = false ∨ a y = false) := by
  induction xs with
  | nil => simp [atMostOne, Satisfies]
  | cons x rest ih =>
    rw [atMostOne, satisfies_append, ih, List.pairwise_cons]
    unfold Satisfies
    simp [neg]

theorem satisfies_exactlyOne {α : Type*} (a : α → Bool) (xs : List α) :
    Satisfies a (exactlyOne xs) ↔
      (∃ x ∈ xs, a x = true) ∧ xs.Pairwise (fun x y => a x = false ∨ a y = false) := by
  rw [exactlyOne, satisfies_cons, satisfies_atMostOne]
  simp [pos]

theorem eq_of_pairwise_true {α : Type*} (a : α → Bool) (xs : List α)
    (h : xs.Pairwise (fun x y => a x = false ∨ a y = false)) (x y : α) (hx : x ∈ xs)
    (hy : y ∈ xs) (hax : a x = true) (hay : a y = true) : x = y := by
  induction xs with
  | nil => simp at hx
  | cons z rest ih =>
    rw [List.pairwise_cons] at h
    rcases List.mem_cons.1 hx with rfl | hx' <;> rcases List.mem_cons.1 hy with rfl | hy'
    · rfl
    · rcases h.1 y hy' with h' | h' <;> simp_all
    · rcases h.1 x hx' with h' | h' <;> simp_all
    · exact ih h.2 hx' hy'

theorem unique_of_exactlyOne {α β : Type*} [DecidableEq β] (a : α → Bool) (f : β → α) (xs : List β)
    (hall : ∀ z, z ∈ xs) (h : Satisfies a (exactlyOne (xs.map f))) :
    ∃ y, ∀ z, a (f z) = decide (y = z) := by
  rw [satisfies_exactlyOne, List.pairwise_map] at h
  obtain ⟨⟨_, hx, hax⟩, hp⟩ := h
  obtain ⟨y, -, rfl⟩ := List.mem_map.1 hx
  refine ⟨y, fun z => ?_⟩
  by_cases hz : y = z
  · subst hz
    simp [hax]
  · simp only [hz, decide_false]
    cases hfz : a (f z)
    · rfl
    · exact absurd (eq_of_pairwise_true (a ∘ f) xs hp y z (hall y) (hall z) hax hfz) hz

theorem satisfies_exactlyOne_of {α β : Type*} [DecidableEq β] (a : α → Bool) (f : β → α) (xs : List β)
    (hnd : xs.Nodup) (y : β) (hy : y ∈ xs) (h : ∀ z, a (f z) = decide (y = z)) :
    Satisfies a (exactlyOne (xs.map f)) := by
  rw [satisfies_exactlyOne, List.pairwise_map]
  refine ⟨⟨f y, List.mem_map_of_mem hy, by simp [h]⟩, hnd.imp fun {x z} hxz => ?_⟩
  simp only [h]
  by_cases hx : y = x
  · subst hx
    right
    simpa using hxz
  · left
    simpa using hx

theorem mem_allSymbols (s : Γ) : s ∈ allSymbols Γ := by
  simp [allSymbols]

theorem mem_allStates (q : Q) : q ∈ allStates Q := by
  simp [allStates]

theorem run_succ' (M : Machine Q Γ) (n : ℕ) (c : Config Q Γ W) :
    M.run (n + 1) c = (M.run n c).bind M.step := by
  induction n generalizing c with
  | zero => simp [Machine.run]
  | succ n ih =>
    show (M.step c).bind (M.run (n + 1)) = ((M.step c).bind (M.run n)).bind M.step
    cases M.step c with
    | none => rfl
    | some c' => exact ih c'

theorem run_add (M : Machine Q Γ) (m n : ℕ) (c : Config Q Γ W) :
    M.run (m + n) c = (M.run m c).bind (M.run n) := by
  induction m generalizing c with
  | zero => simp [Machine.run]
  | succ m ih =>
    rw [Nat.add_right_comm]
    show (M.step c).bind (M.run (m + n)) = ((M.step c).bind (M.run m)).bind (M.run n)
    cases M.step c with
    | none => rfl
    | some c' => exact ih c'

theorem run_of_halts (M : Machine Q Γ) (n : ℕ) (c : Config Q Γ W) (h : M.Halts c.state) :
    M.run n c = some c := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show (M.step c).bind (M.run n) = some c
    simp [Machine.step, h, ih]

theorem config_eq {c c' : Config Q Γ W} (h1 : c.state = c'.state) (h2 : c.head = c'.head)
    (h3 : ∀ j, c.tape j = c'.tape j) : c = c' := by
  cases c
  cases c'
  simp only at h1 h2 h3
  subst h1 h2
  rw [funext h3]

/-- Rows `i` and `i + 1` of a satisfying setting, read as configurations, are one step apart. -/
theorem step_of_satisfies (M : Machine Q Γ) (a : Var Q Γ W → Bool) (i : ℕ)
    (c c' : Config Q Γ W)
    (hcc : ∀ j s, a (Var.cell i j s) = decide (c.tape j = s))
    (hcs : ∀ q, a (Var.state i q) = decide (c.state = q))
    (hch : ∀ j, a (Var.head i j) = decide (c.head = j))
    (hcc' : ∀ j s, a (Var.cell (i + 1) j s) = decide (c'.tape j = s))
    (hcs' : ∀ q, a (Var.state (i + 1) q) = decide (c'.state = q))
    (hch' : ∀ j, a (Var.head (i + 1) j) = decide (c'.head = j))
    (hrule : Satisfies a ((List.finRange W).flatMap fun j =>
      (allStates Q).flatMap fun q => (allSymbols Γ).flatMap fun s => ruleClauses M i j q s))
    (hframe : Satisfies a ((List.finRange W).flatMap fun j =>
      (allSymbols Γ).map fun s =>
        [pos (Var.head i j), neg (Var.cell i j s), pos (Var.cell (i + 1) j s)])) :
    M.step c = some c' := by
  have hfr : ∀ j, j ≠ c.head → c'.tape j = c.tape j := by
    intro j hj
    rw [satisfies_flatMap] at hframe
    have h := hframe j (List.mem_finRange j)
    unfold Satisfies at h
    have h' := h _ (List.mem_map_of_mem (mem_allSymbols (c.tape j)))
    simp [pos, neg, hch, hcc, hcc'] at h'
    rcases h' with h' | h'
    · exact absurd h'.symm hj
    · exact h'
  have hr : Satisfies a (ruleClauses M i c.head c.state (c.tape c.head)) := by
    rw [satisfies_flatMap] at hrule
    have h := hrule c.head (List.mem_finRange _)
    rw [satisfies_flatMap] at h
    have h2 := h c.state (mem_allStates _)
    rw [satisfies_flatMap] at h2
    exact h2 _ (mem_allSymbols _)
  unfold ruleClauses at hr
  unfold Machine.step
  by_cases hH : M.Halts c.state
  · simp only [hH, ite_true] at hr ⊢
    unfold Satisfies at hr
    simp [pos, neg, hch, hcc, hcs, hcc', hcs', hch'] at hr
    obtain ⟨h1, h2, h3⟩ := hr
    congr 1
    refine config_eq h2.symm h3.symm fun j => ?_
    by_cases hj : j = c.head
    · subst hj
      exact h1.symm
    · exact (hfr j hj).symm
  · simp only [hH, ite_false] at hr ⊢
    rcases hδ : M.δ c.state (c.tape c.head) with _ | ⟨b, d, q'⟩
    · simp only [hδ] at hr
      unfold Satisfies at hr
      simp [neg, hch, hcc, hcs] at hr
    · simp only [hδ] at hr ⊢
      rcases hm : moveHead c.head d with _ | j'
      · simp only [hm] at hr
        unfold Satisfies at hr
        simp [neg, hch, hcc, hcs] at hr
      · simp only [hm] at hr ⊢
        unfold Satisfies at hr
        simp [pos, neg, hch, hcc, hcs, hcc', hcs', hch'] at hr
        obtain ⟨h1, h2, h3⟩ := hr
        simp only [Option.map_some]
        congr 1
        refine config_eq h2.symm h3.symm fun j => ?_
        by_cases hj : j = c.head
        · subst hj
          simp [h1]
        · simp [Function.update_of_ne hj, hfr j hj]

/-- Every clause of `ruleClauses` starts with the premise "head at `j`, state `q`, cell `j`
holds `s`". -/
theorem ruleClauses_premise (M : Machine Q Γ) (i : ℕ) (j : Fin W) (q : Q) (s : Γ) :
    ∀ C ∈ ruleClauses M i j q s, neg (Var.head i j) ∈ C ∧ neg (Var.state i q) ∈ C ∧
      neg (Var.cell i j s) ∈ C := by
  unfold ruleClauses
  split_ifs
  · simp
  · split
    · simp
    · split <;> simp

/-- A run step, written as rows `i` and `i + 1`, satisfies that step's rule and frame clauses. -/
theorem satisfies_of_step (M : Machine Q Γ) (a : Var Q Γ W → Bool) (i : ℕ)
    (c c' : Config Q Γ W)
    (hcc : ∀ j s, a (Var.cell i j s) = decide (c.tape j = s))
    (hcs : ∀ q, a (Var.state i q) = decide (c.state = q))
    (hch : ∀ j, a (Var.head i j) = decide (c.head = j))
    (hcc' : ∀ j s, a (Var.cell (i + 1) j s) = decide (c'.tape j = s))
    (hcs' : ∀ q, a (Var.state (i + 1) q) = decide (c'.state = q))
    (hch' : ∀ j, a (Var.head (i + 1) j) = decide (c'.head = j))
    (hstep : M.step c = some c') :
    Satisfies a ((List.finRange W).flatMap fun j =>
      (allStates Q).flatMap fun q => (allSymbols Γ).flatMap fun s => ruleClauses M i j q s) ∧
    Satisfies a ((List.finRange W).flatMap fun j =>
      (allSymbols Γ).map fun s =>
        [pos (Var.head i j), neg (Var.cell i j s), pos (Var.cell (i + 1) j s)]) := by
  have hfr : ∀ j, j ≠ c.head → c'.tape j = c.tape j := by
    intro j hj
    unfold Machine.step at hstep
    split_ifs at hstep with hH
    · simp at hstep
      rw [hstep]
    · split at hstep
      · simp at hstep
      · rename_i b d q' _
        rcases hm : moveHead c.head d with _ | j'
        · simp [hm] at hstep
        · simp [hm] at hstep
          rw [← hstep]
          simp [Function.update_of_ne hj]
  constructor
  · rw [satisfies_flatMap]
    intro j _
    rw [satisfies_flatMap]
    intro q _
    rw [satisfies_flatMap]
    intro s _
    by_cases hpre : c.head = j ∧ c.state = q ∧ c.tape j = s
    · obtain ⟨rfl, rfl, rfl⟩ := hpre
      unfold ruleClauses
      unfold Machine.step at hstep
      by_cases hH : M.Halts c.state
      · simp only [hH, ite_true] at hstep ⊢
        cases hstep
        unfold Satisfies
        simp [pos, hcc', hcs', hch']
      · simp only [hH, ite_false] at hstep ⊢
        rcases hδ : M.δ c.state (c.tape c.head) with _ | ⟨b, d, q'⟩
        · simp [hδ] at hstep
        · simp only [hδ] at hstep ⊢
          rcases hm : moveHead c.head d with _ | j'
          · simp [hm] at hstep
          · simp only [hm, Option.map_some, Option.some.injEq] at hstep ⊢
            subst hstep
            unfold Satisfies
            simp [pos, hcc', hcs', hch']
    · intro C hC
      obtain ⟨h1, h2, h3⟩ := ruleClauses_premise M i j q s C hC
      by_cases hj : c.head = j
      · by_cases hq : c.state = q
        · refine ⟨_, h3, ?_⟩
          have : c.tape j ≠ s := fun h => hpre ⟨hj, hq, h⟩
          simp [neg, hcc, this]
        · exact ⟨_, h2, by simp [neg, hcs, hq]⟩
      · exact ⟨_, h1, by simp [neg, hch, hj]⟩
  · rw [satisfies_flatMap]
    intro j _
    unfold Satisfies
    simp only [List.mem_map]
    rintro C ⟨s, -, rfl⟩
    by_cases hj : c.head = j
    · exact ⟨_, List.mem_cons_self, by simp [pos, hch, hj]⟩
    · by_cases hs : c.tape j = s
      · refine ⟨pos (Var.cell (i + 1) j s), by simp, ?_⟩
        simp [pos, hcc', hfr j (Ne.symm hj), hs]
      · exact ⟨neg (Var.cell i j s), by simp, by simp [neg, hcc, hs]⟩

/-- Each row `i ≤ t` of a setting that satisfies Φ_one reads as one configuration. -/
theorem row_of_phiOne (a : Var Q Γ W → Bool) (t : ℕ) (h : Satisfies a (phiOne Q Γ W t))
    (i : ℕ) (hi : i ≤ t) :
    ∃ c : Config Q Γ W, (∀ j s, a (Var.cell i j s) = decide (c.tape j = s)) ∧
      (∀ q, a (Var.state i q) = decide (c.state = q)) ∧
      (∀ j, a (Var.head i j) = decide (c.head = j)) := by
  rw [phiOne, satisfies_flatMap] at h
  have h' := h i (List.mem_range.2 (by omega))
  rw [satisfies_append, satisfies_append, satisfies_flatMap] at h'
  obtain ⟨⟨hcells, hst⟩, hhd⟩ := h'
  have hc : ∀ j, ∃ y, ∀ z, a (Var.cell i j z) = decide (y = z) := fun j =>
    unique_of_exactlyOne a (Var.cell i j) _ mem_allSymbols (hcells j (List.mem_finRange j))
  choose tape htape using hc
  obtain ⟨q, hq⟩ := unique_of_exactlyOne a (Var.state i) _ mem_allStates hst
  obtain ⟨hd, hhd'⟩ := unique_of_exactlyOne a (Var.head i) _ List.mem_finRange hhd
  exact ⟨⟨q, hd, tape⟩, htape, hq, hhd'⟩

/-- A satisfying setting is a run of the machine from an allowed start row. -/
theorem run_of_satisfies (M : Machine Q Γ) (allowed : Fin W → Finset Γ) (h0 : Fin W) (t : ℕ)
    (a : Var Q Γ W → Bool) (ha : Satisfies a (tableau M allowed h0 t)) :
    ∃ w : Fin W → Γ, (∀ j, w j ∈ allowed j) ∧ (∀ j s, a (Var.cell 0 j s) = decide (w j = s)) ∧
      ∀ i ≤ t, ∃ c, M.run i (⟨M.start, h0, w⟩ : Config Q Γ W) = some c ∧
        (∀ j s, a (Var.cell i j s) = decide (c.tape j = s)) ∧
        (∀ q, a (Var.state i q) = decide (c.state = q)) ∧
        (∀ j, a (Var.head i j) = decide (c.head = j)) := by
  simp only [tableau, satisfies_append] at ha
  obtain ⟨⟨⟨⟨h1, h2⟩, h3⟩, h4⟩, -⟩ := ha
  obtain ⟨c0, hc0c, hc0s, hc0h⟩ := row_of_phiOne a t h1 0 (Nat.zero_le _)
  rw [phiStart, satisfies_cons, satisfies_cons] at h2
  obtain ⟨hs0, hh0, hcl⟩ := h2
  simp [pos, hc0s] at hs0
  simp [pos, hc0h] at hh0
  have hw : ∀ j, c0.tape j ∈ allowed j := by
    intro j
    unfold Satisfies at hcl
    have := hcl _ (List.mem_map_of_mem (List.mem_finRange j))
    simpa [pos, hc0c] using this
  have hc0 : (⟨M.start, h0, c0.tape⟩ : Config Q Γ W) = c0 :=
    config_eq hs0.symm hh0.symm fun _ => rfl
  refine ⟨c0.tape, hw, hc0c, fun i hi => ?_⟩
  induction i with
  | zero => exact ⟨c0, by rw [hc0]; rfl, hc0c, hc0s, hc0h⟩
  | succ n ih =>
    obtain ⟨c, hrun, hcc, hcs, hch⟩ := ih (by omega)
    obtain ⟨c', hcc', hcs', hch'⟩ := row_of_phiOne a t h1 (n + 1) hi
    refine ⟨c', ?_, hcc', hcs', hch'⟩
    rw [run_succ', hrun]
    rw [phiRule, satisfies_flatMap] at h3
    rw [phiFrame, satisfies_flatMap] at h4
    exact step_of_satisfies M a n c c' hcc hcs hch hcc' hcs' hch'
      (h3 n (List.mem_range.2 (by omega))) (h4 n (List.mem_range.2 (by omega)))

/-- A run that is in the accept state at step `t` gives a satisfying setting. -/
theorem satisfies_of_run (M : Machine Q Γ) (allowed : Fin W → Finset Γ) (h0 : Fin W) (t : ℕ)
    (w : Fin W → Γ) (hw : ∀ j, w j ∈ allowed j) (cfg : ℕ → Config Q Γ W)
    (a : Var Q Γ W → Bool)
    (hcell : ∀ i j s, a (Var.cell i j s) = decide ((cfg i).tape j = s))
    (hst : ∀ i q, a (Var.state i q) = decide ((cfg i).state = q))
    (hhd : ∀ i j, a (Var.head i j) = decide ((cfg i).head = j))
    (h0cfg : cfg 0 = ⟨M.start, h0, w⟩)
    (hstep : ∀ i < t, M.step (cfg i) = some (cfg (i + 1)))
    (hacc : (cfg t).state = M.accept) :
    Satisfies a (tableau M allowed h0 t) := by
  simp only [tableau, satisfies_append]
  refine ⟨⟨⟨⟨?_, ?_⟩, ?_⟩, ?_⟩, ?_⟩
  · rw [phiOne, satisfies_flatMap]
    intro i _
    rw [satisfies_append, satisfies_append, satisfies_flatMap]
    refine ⟨⟨fun j _ => ?_, ?_⟩, ?_⟩
    · exact satisfies_exactlyOne_of a (Var.cell i j) _ (Finset.nodup_toList _) _
        (mem_allSymbols _) (hcell i j)
    · exact satisfies_exactlyOne_of a (Var.state i) _ (Finset.nodup_toList _) _
        (mem_allStates _) (hst i)
    · exact satisfies_exactlyOne_of a (Var.head i) _ (List.nodup_finRange W) _
        (List.mem_finRange _) (hhd i)
  · rw [phiStart, satisfies_cons, satisfies_cons]
    refine ⟨⟨_, List.mem_singleton_self _, by simp [pos, hst, h0cfg]⟩,
      ⟨_, List.mem_singleton_self _, by simp [pos, hhd, h0cfg]⟩, ?_⟩
    unfold Satisfies
    simp only [List.mem_map]
    rintro C ⟨j, -, rfl⟩
    exact ⟨pos (Var.cell 0 j (w j)), List.mem_map_of_mem (Finset.mem_toList.2 (hw j)),
      by simp [pos, hcell, h0cfg]⟩
  · rw [phiRule, satisfies_flatMap]
    intro i hi
    exact (satisfies_of_step M a i (cfg i) (cfg (i + 1)) (hcell i) (hst i) (hhd i) (hcell (i + 1))
      (hst (i + 1)) (hhd (i + 1)) (hstep i (List.mem_range.1 hi))).1
  · rw [phiFrame, satisfies_flatMap]
    intro i hi
    exact (satisfies_of_step M a i (cfg i) (cfg (i + 1)) (hcell i) (hst i) (hhd i) (hcell (i + 1))
      (hst (i + 1)) (hhd (i + 1)) (hstep i (List.mem_range.1 hi))).2
  · unfold Satisfies phiAccept
    simp [pos, hst, hacc]

theorem length_atMostOne {α : Type*} (xs : List α) :
    (atMostOne xs).length = xs.length.choose 2 := by
  induction xs with
  | nil => simp [atMostOne]
  | cons x rest ih =>
    rw [atMostOne, List.length_append, List.length_map, ih, List.length_cons]
    show _ = (rest.length + 1).choose (1 + 1)
    rw [Nat.choose_succ_succ, Nat.choose_one_right]

theorem length_exactlyOne {α : Type*} (xs : List α) :
    (exactlyOne xs).length = 1 + xs.length.choose 2 := by
  rw [exactlyOne, List.length_cons, length_atMostOne]
  omega

theorem length_flatMap_le {α β : Type*} (l : List α) (f : α → List β) (n : ℕ)
    (h : ∀ x ∈ l, (f x).length ≤ n) : (l.flatMap f).length ≤ l.length * n := by
  induction l with
  | nil => simp
  | cons x rest ih =>
    rw [List.flatMap_cons, List.length_append, List.length_cons, Nat.succ_mul]
    have h1 := h x List.mem_cons_self
    have h2 := ih fun y hy => h y (List.mem_cons_of_mem _ hy)
    omega

theorem length_ruleClauses_le (M : Machine Q Γ) (i : ℕ) (j : Fin W) (q : Q) (s : Γ) :
    (ruleClauses M i j q s).length ≤ 3 := by
  unfold ruleClauses
  split_ifs
  · simp
  · split
    · simp
    · split <;> simp

theorem length_allSymbols : (allSymbols Γ).length = Fintype.card Γ := by
  simp [allSymbols]

theorem length_allStates : (allStates Q).length = Fintype.card Q := by
  simp [allStates]

/-! ## The theorem and the size count -/

/-- Cook-Levin's construction: for any fixed machine (finitely many states and symbols), any
grid of `W` cells, start head cell `h0`, start-row pattern `allowed` and step bound `t`, the
formula φ_x is satisfiable exactly when some certificate (a start tape allowed cell by cell)
makes the machine accept within `t` steps. -/
theorem tableau_satisfiable_iff_some_certificate_accepted (M : Machine Q Γ)
    (allowed : Fin W → Finset Γ) (h0 : Fin W) (t : ℕ) :
    Satisfiable (tableau M allowed h0 t) ↔
      ∃ w : Fin W → Γ, (∀ j, w j ∈ allowed j) ∧
        M.AcceptsWithin t (⟨M.start, h0, w⟩ : Config Q Γ W) := by
  constructor
  · rintro ⟨a, ha⟩
    obtain ⟨w, hw, -, hrows⟩ := run_of_satisfies M allowed h0 t a ha
    refine ⟨w, hw, t, le_rfl, ?_⟩
    obtain ⟨c, hrun, -, hs, -⟩ := hrows t le_rfl
    have hacc : a (Var.state t M.accept) = true := by
      simp only [tableau, satisfies_append] at ha
      have h5 := ha.2
      unfold Satisfies phiAccept at h5
      simpa [pos] using h5
    rw [hs] at hacc
    rw [hrun]
    simpa using hacc
  · rintro ⟨w, hw, k, hk, hacc⟩
    obtain ⟨c0, hc0⟩ : ∃ c0 : Config Q Γ W, c0 = ⟨M.start, h0, w⟩ := ⟨_, rfl⟩
    rw [← hc0] at hacc
    obtain ⟨c1, hc1, hc1s⟩ : ∃ c1, M.run k c0 = some c1 ∧ c1.state = M.accept := by
      simpa using hacc
    have hrun_t : M.run t c0 = some c1 := by
      obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hk
      rw [run_add, hc1]
      exact run_of_halts M m c1 (Or.inl hc1s)
    obtain ⟨cfg, hcfg⟩ : ∃ cfg : ℕ → Config Q Γ W, ∀ i, cfg i = (M.run i c0).getD c0 :=
      ⟨_, fun _ => rfl⟩
    have hsome : ∀ i ≤ t, M.run i c0 = some (cfg i) := by
      intro i hi
      rw [hcfg]
      cases hr : M.run i c0 with
      | none =>
        obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hi
        rw [run_add, hr] at hrun_t
        simp at hrun_t
      | some c => rfl
    refine ⟨fun v => Var.rec (motive := fun _ => Bool)
      (fun i j s => decide ((cfg i).tape j = s)) (fun i q => decide ((cfg i).state = q))
      (fun i j => decide ((cfg i).head = j)) v, ?_⟩
    refine satisfies_of_run M allowed h0 t w hw cfg _ (fun _ _ _ => rfl) (fun _ _ => rfl)
      (fun _ _ => rfl) ?_ ?_ ?_
    · rw [hcfg, ← hc0]
      rfl
    · intro i hi
      have h1 := hsome (i + 1) hi
      rw [run_succ', hsome i (by omega)] at h1
      exact h1
    · have := hsome t le_rfl
      rw [hrun_t] at this
      cases this
      exact hc1s

/-- The size count: with `S` symbols, `|Q|` states and `W` cells, φ_x has at most
`(t + 1)(W(1 + C(S, 2)) + 1 + C(|Q|, 2) + 1 + C(W, 2)) + t W S (3|Q| + 1) + W + 3` clauses,
a polynomial in `t` once `W = 2t + 1`. -/
theorem tableau_length_le (M : Machine Q Γ) (allowed : Fin W → Finset Γ) (h0 : Fin W)
    (t : ℕ) :
    (tableau M allowed h0 t).length ≤
      (t + 1) * (W * (1 + (Fintype.card Γ).choose 2) + 1 + (Fintype.card Q).choose 2 + 1 +
          W.choose 2) +
        t * W * Fintype.card Γ * (3 * Fintype.card Q + 1) + W + 3 := by
  have hOne : (phiOne Q Γ W t).length ≤ (t + 1) * (W * (1 + (Fintype.card Γ).choose 2) +
      (1 + (Fintype.card Q).choose 2) + (1 + W.choose 2)) := by
    unfold phiOne
    refine le_trans (length_flatMap_le _ _ _ fun i _ => ?_) (by rw [List.length_range])
    simp only [List.length_append, length_exactlyOne, List.length_map, length_allStates,
      List.length_finRange]
    have := length_flatMap_le (List.finRange W)
      (fun j => exactlyOne ((allSymbols Γ).map (Var.cell (Q := Q) i j)))
      (1 + (Fintype.card Γ).choose 2)
      (fun j _ => by simp [length_exactlyOne, length_allSymbols])
    rw [List.length_finRange] at this
    omega
  have hStart : (phiStart M allowed h0).length = W + 2 := by
    simp [phiStart]
  have hRule : (phiRule M t : CNF (Var Q Γ W)).length ≤
      t * (W * (Fintype.card Q * (Fintype.card Γ * 3))) := by
    unfold phiRule
    refine le_trans (length_flatMap_le _ _ _ fun i _ => ?_) (by rw [List.length_range])
    refine le_trans (length_flatMap_le _ _ _ fun j _ => ?_) (by rw [List.length_finRange])
    refine le_trans (length_flatMap_le _ _ _ fun q _ => ?_) (by rw [length_allStates])
    refine le_trans (length_flatMap_le _ _ _ fun s _ => ?_) (by rw [length_allSymbols])
    exact length_ruleClauses_le M i j q s
  have hFrame : (phiFrame Q Γ W t).length ≤ t * (W * Fintype.card Γ) := by
    unfold phiFrame
    refine le_trans (length_flatMap_le _ _ _ fun i _ => ?_) (by rw [List.length_range])
    refine le_trans (length_flatMap_le _ _ _ fun j _ => ?_) (by rw [List.length_finRange])
    simp [length_allSymbols]
  have hAcc : (phiAccept M t : CNF (Var Q Γ W)).length = 1 := rfl
  simp only [tableau, List.length_append]
  nlinarith

/-- A satisfying setting is the machine's own run: two satisfying assignments that agree on the
start row's cells agree on every variable of rows 0 to `t`. So the satisfying settings, read on
the grid, match the accepted certificates one for one. -/
theorem satisfying_assignment_fixed_by_start_row (M : Machine Q Γ)
    (allowed : Fin W → Finset Γ) (h0 : Fin W) (t : ℕ) (a b : Var Q Γ W → Bool)
    (ha : Satisfies a (tableau M allowed h0 t)) (hb : Satisfies b (tableau M allowed h0 t))
    (hrow : ∀ j s, a (Var.cell 0 j s) = b (Var.cell 0 j s)) :
    ∀ i ≤ t, (∀ j s, a (Var.cell i j s) = b (Var.cell i j s)) ∧
      (∀ q, a (Var.state i q) = b (Var.state i q)) ∧
      (∀ j, a (Var.head i j) = b (Var.head i j)) := by
  obtain ⟨wa, -, ha0, hra⟩ := run_of_satisfies M allowed h0 t a ha
  obtain ⟨wb, -, hb0, hrb⟩ := run_of_satisfies M allowed h0 t b hb
  have hw : wa = wb := by
    funext j
    have h1 := ha0 j (wa j)
    rw [hrow, hb0] at h1
    simp at h1
    exact h1.symm
  subst hw
  intro i hi
  obtain ⟨c, hc, hac, has, hah⟩ := hra i hi
  obtain ⟨c', hc', hbc, hbs, hbh⟩ := hrb i hi
  rw [hc] at hc'
  obtain rfl := Option.some.inj hc'
  exact ⟨fun j s => by rw [hac, hbc], fun q => by rw [has, hbs], fun j => by rw [hah, hbh]⟩

/-! ## The card's row checker

The top row of a 4 by 4 sudoku, 1, two empty squares, 4, then the end mark #, on 5 cells.
States P (pick), C1 to C4 (carry a digit), B (back), A (accept), R (reject); symbols the digits
1 to 4, the mark X and the end mark #. -/

/-- The six tape symbols. -/
inductive Sym | one | two | three | four | X | hash
  deriving DecidableEq

instance : Fintype Sym :=
  ⟨⟨[Sym.one, .two, .three, .four, .X, .hash], by decide⟩, fun x => by cases x <;> decide⟩

/-- The eight states. -/
inductive St | P | C1 | C2 | C3 | C4 | B | A | R
  deriving DecidableEq

instance : Fintype St :=
  ⟨⟨[St.P, .C1, .C2, .C3, .C4, .B, .A, .R], by decide⟩, fun x => by cases x <;> decide⟩

/-- The carry state for a digit. -/
def carrier : Sym → Option St
  | .one => some .C1 | .two => some .C2 | .three => some .C3 | .four => some .C4
  | _ => none

/-- Carrying digit `d` in state `q`: another digit moves on, `d` again rejects, # turns back. -/
def carryRule (q : St) (d e : Sym) : Option (Sym × Dir × St) :=
  match e with
  | .X => none
  | .hash => some (.hash, .left, .B)
  | e => if e = d then some (e, .right, .R) else some (e, .right, q)

/-- The rule table of the card's Step 1. -/
def rowRules : St → Sym → Option (Sym × Dir × St)
  | .P, .hash => some (.hash, .left, .A)
  | .P, .X => none
  | .P, s => (carrier s).map fun q => (.X, .right, q)
  | .C1, e => carryRule .C1 .one e
  | .C2, e => carryRule .C2 .two e
  | .C3, e => carryRule .C3 .three e
  | .C4, e => carryRule .C4 .four e
  | .B, .X => some (.X, .right, .P)
  | .B, .hash => none
  | .B, s => some (s, .left, .B)
  | .A, _ => none
  | .R, _ => none

/-- The row checker: start in P, accept in A, reject in R. -/
def rowChecker : Machine St Sym := ⟨.P, .A, .R, rowRules⟩

/-- Row 0 for the filling a, b of the two empty squares, head at cell 0. -/
def startRow (a b : Sym) : Config St Sym 5 := ⟨.P, 0, ![Sym.one, a, b, .four, .hash]⟩

-- The run on the filling 2, 3 (the row 1, 2, 3, 4) reaches A at step 25, not before.
example : (rowChecker.run 25 (startRow .two .three)).map Config.state = some St.A := by
  decide +kernel
example : ¬ rowChecker.AcceptsWithin 24 (startRow .two .three) := by decide +kernel
-- Road 1: of the 16 digit fillings, the checker accepts exactly 2, 3 and 3, 2 within 25 steps.
example : ∀ a b : Sym, a ∈ [Sym.one, .two, .three, .four] → b ∈ [Sym.one, .two, .three, .four] →
    (rowChecker.AcceptsWithin 25 (startRow a b) ↔
      (a = .two ∧ b = .three) ∨ (a = .three ∧ b = .two)) := by
  decide +kernel
-- Break: let the empty squares hold any of the 6 tape symbols, and 11 of the 36 fillings pass.
example : (Finset.univ.filter fun p : Sym × Sym =>
    rowChecker.AcceptsWithin 25 (startRow p.1 p.2)).card = 11 := by
  decide +kernel

-- Worked numbers: 16 fillings, 43 variables per row, 1,118 in all.
example : 4 * 4 = 16 := by norm_num
example : 5 * 6 + 8 + 5 = 43 ∧ 26 * 43 = 1118 := by norm_num
-- Exactly-one clauses per cell, state and head: 1 + 15, 1 + 28, 1 + 10; 3,120 over 26 rows.
example : 1 + Nat.choose 6 2 = 16 ∧ 1 + Nat.choose 8 2 = 29 ∧ 1 + Nat.choose 5 2 = 11 := by
  decide
example : 26 * (5 * 16 + 29 + 11) = 3120 := by norm_num
-- Frame clauses and the total.
example : 25 * 5 * 6 = 750 := by norm_num
example : 3120 + 7 + 13500 + 1500 + 750 + 1 = 18878 := by norm_num
-- The size count at t = 25, W = 5, S = 6, |Q| = 8 is 21,878, above the 18,878 built.
example : (25 + 1) * (5 * (1 + Nat.choose 6 2) + 1 + Nat.choose 8 2 + 1 + Nat.choose 5 2) +
    25 * 5 * 6 * (3 * 8 + 1) + 5 + 3 = 21878 := by
  simp [Nat.choose_two_right]
-- Growth on 2t + 1 cells: variables (t + 1)(7(2t + 1) + 8) and the clause count.
example : (10 + 1) * (7 * 21 + 8) = 1705 ∧ (100 + 1) * (7 * 201 + 8) = 142915 ∧
    (1000 + 1) * (7 * 2001 + 8) = 14029015 := by norm_num
example : (10 + 1) * (21 * (1 + Nat.choose 6 2) + 1 + Nat.choose 8 2 + 1 + Nat.choose 21 2) +
    10 * 21 * 6 * (3 * 8 + 1) + 21 + 3 = 37860 := by
  simp [Nat.choose_two_right]
example : (100 + 1) * (201 * (1 + Nat.choose 6 2) + 1 + Nat.choose 8 2 + 1 + Nat.choose 201 2) +
    100 * 201 * 6 * (3 * 8 + 1) + 201 + 3 = 5373150 := by
  simp [Nat.choose_two_right]
example : (1000 + 1) * (2001 * (1 + Nat.choose 6 2) + 1 + Nat.choose 8 2 + 1 +
    Nat.choose 2001 2) + 1000 * 2001 * 6 * (3 * 8 + 1) + 2001 + 3 = 2335231050 := by
  simp [Nat.choose_two_right]

#print axioms satisfies_append
#print axioms satisfies_cons
#print axioms satisfies_flatMap
#print axioms satisfies_atMostOne
#print axioms satisfies_exactlyOne
#print axioms eq_of_pairwise_true
#print axioms unique_of_exactlyOne
#print axioms satisfies_exactlyOne_of
#print axioms mem_allSymbols
#print axioms mem_allStates
#print axioms run_succ'
#print axioms run_add
#print axioms run_of_halts
#print axioms config_eq
#print axioms step_of_satisfies
#print axioms ruleClauses_premise
#print axioms satisfies_of_step
#print axioms row_of_phiOne
#print axioms run_of_satisfies
#print axioms satisfies_of_run
#print axioms length_atMostOne
#print axioms length_exactlyOne
#print axioms length_flatMap_le
#print axioms length_ruleClauses_le
#print axioms length_allSymbols
#print axioms length_allStates
#print axioms tableau_satisfiable_iff_some_certificate_accepted
#print axioms tableau_length_le
#print axioms satisfying_assignment_fixed_by_start_row

end CookLevin
