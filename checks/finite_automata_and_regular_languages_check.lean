-- Finite automata: no machine with finitely many states accepts exactly the balanced bracket strings, the eight-state coin machine accepts exactly the coin sequences worth 30p, and regular languages are closed under and, or and not.
import Mathlib.Computability.DFA
import Mathlib.Combinatorics.Enumerative.DyckWord

open DyckStep

/-! ## The bracket language

`DyckStep.U` is the open bracket "(" and `DyckStep.D` is the closing bracket ")".
Mathlib's `DyckWord` is a bracket string with as many closes as opens in which no prefix
has more closes than opens: exactly the balanced bracket strings. -/

/-- The balanced bracket strings, as a language over the alphabet `{(, )}`. -/
def balanced : Language DyckStep := {w | ∃ p : DyckWord, p.toList = w}

/-- `n` opens followed by `n` closes is a balanced bracket string. -/
theorem replicate_U_append_replicate_D_mem_balanced (n : ℕ) :
    ∃ p : DyckWord, p.toList = List.replicate n U ++ List.replicate n D := by
  induction n with
  | zero => exact ⟨0, rfl⟩
  | succ n ih =>
    obtain ⟨p, hp⟩ := ih
    refine ⟨p.nest, ?_⟩
    show [U] ++ p.toList ++ [D] = _
    rw [hp, List.replicate_succ, List.replicate_succ']
    simp

#print axioms replicate_U_append_replicate_D_mem_balanced

/-- Fixed memory cannot check brackets of every depth: no finite automaton, that is, no
machine with finitely many states and exactly one move for every state and symbol, reading
its input once and judging it by the state it ends in, accepts exactly the balanced bracket
strings. -/
theorem no_finite_automaton_accepts_balanced_brackets
    {σ : Type*} [Fintype σ] (M : DFA DyckStep σ) : M.accepts ≠ balanced := by
  intro hM
  have hcard : Fintype.card (Fin (Fintype.card σ + 1)) > Fintype.card σ := by simp
  obtain ⟨i, j, hij, heq⟩ := Fintype.exists_ne_map_eq_of_card_lt
    (fun n : Fin (Fintype.card σ + 1) => M.eval (List.replicate n.val U)) hcard
  obtain ⟨p, hp⟩ := replicate_U_append_replicate_D_mem_balanced i.val
  have hacc : List.replicate i.val U ++ List.replicate i.val D ∈ M.accepts := by
    rw [hM]; exact ⟨p, hp⟩
  have hacc' : List.replicate j.val U ++ List.replicate i.val D ∈ M.accepts := by
    rw [DFA.mem_accepts] at hacc ⊢
    simp only [DFA.eval] at hacc ⊢
    rw [DFA.evalFrom_of_append] at hacc ⊢
    simp only [DFA.eval] at heq
    rw [← heq]; exact hacc
  rw [hM] at hacc'
  obtain ⟨q, hq⟩ := hacc'
  have h := q.count_U_eq_count_D
  rw [hq] at h
  simp [List.count_replicate] at h
  exact hij (Fin.ext h.symm)

/-! ## The coin machine

The alphabet is the three coins. A state `some k` means a credit of `5 * k` pence,
for `k = 0, …, 6` (0p to 30p), and `none` is the state "over". That is 8 states. -/

/-- The coins the machine takes: 5p, 10p and 20p. -/
inductive Coin
  | five
  | ten
  | twenty
  deriving DecidableEq

/-- The value of a coin in pence. -/
def Coin.value : Coin → ℕ
  | .five => 5
  | .ten => 10
  | .twenty => 20

/-- The rule δ(q, a): add the coin to the credit, unless that passes 30p or the machine is
already over, in which case go to "over". -/
def coinStep : Option (Fin 7) → Coin → Option (Fin 7)
  | none, _ => none
  | some k, a =>
      if h : 5 * k.val + a.value ≤ 30 then some ⟨(5 * k.val + a.value) / 5, by omega⟩ else none

/-- The coin machine: start at 0p, accept at 30p only. -/
def coinMachine : DFA Coin (Option (Fin 7)) where
  step := coinStep
  start := some 0
  accept := {q | q = some 6}

/-- From credit `5 * k`, the coin machine reaches 30p exactly when the remaining coins add
up to `30 - 5 * k`. -/
theorem coinMachine_evalFrom_some (k : Fin 7) (w : List Coin) :
    coinMachine.evalFrom (some k) w = some 6 ↔ 5 * k.val + (w.map Coin.value).sum = 30 := by
  induction w generalizing k with
  | nil =>
    simp only [DFA.evalFrom_nil, List.map_nil, List.sum_nil, add_zero, Option.some.injEq]
    constructor
    · rintro rfl; rfl
    · intro h; ext; simp; omega
  | cons a w ih =>
    rw [DFA.evalFrom_cons]
    show coinMachine.evalFrom (coinStep (some k) a) w = some 6 ↔ _
    simp only [coinStep, List.map_cons, List.sum_cons]
    split_ifs with h
    · rw [ih]
      simp only
      cases a <;> simp only [Coin.value] at h ⊢ <;> omega
    · have hnone : ∀ v : List Coin, coinMachine.evalFrom none v = none := by
        intro v
        induction v with
        | nil => rfl
        | cons b v ihv => rw [DFA.evalFrom_cons]; exact ihv
      rw [hnone]
      simp only [reduceCtorEq, false_iff]
      omega

#print axioms coinMachine_evalFrom_some

/-- The coin machine accepts exactly the coin sequences worth 30p: a string of coins is
accepted if and only if its coins add up to exactly 30 pence. -/
theorem coinMachine_accepts_iff_worth_30p (w : List Coin) :
    w ∈ coinMachine.accepts ↔ (w.map Coin.value).sum = 30 := by
  rw [DFA.mem_accepts]
  show coinMachine.evalFrom (some 0) w = some 6 ↔ _
  rw [coinMachine_evalFrom_some]
  simp

/-! ## Combining machines -/

/-- Regular languages are closed under intersection, union and complement: if two languages
are each accepted by some finite automaton, then so are the strings in both (`⊓`), the
strings in either (`+`, union of languages), and the strings not in the first (`ᶜ`). -/
theorem regular_closed_under_and_or_not {α : Type*} {L₁ L₂ : Language α}
    (h₁ : L₁.IsRegular) (h₂ : L₂.IsRegular) :
    (L₁ ⊓ L₂).IsRegular ∧ (L₁ + L₂).IsRegular ∧ L₁ᶜ.IsRegular := by
  exact ⟨h₁.inf h₂, h₁.add h₂, h₁.compl⟩

/-! ## The card's worked numbers -/

-- The coin machine has 8 states.
example : Fintype.card (Option (Fin 7)) = 8 := by decide

-- δ(15, 10) = 25: state 3 (15p) on a 10p coin goes to state 5 (25p).
example : coinStep (some 3) .ten = some 5 := by decide

-- Run `10 5 5 10`: 0 → 10 → 15 → 20 → 30, accept.
example : coinMachine.eval [.ten, .five, .five, .ten] = some 6 := by decide

-- Run `20 5 10`: 0 → 20 → 25 → over, reject.
example : coinMachine.eval [.twenty, .five, .ten] = none := by decide

-- Run `10 10`: 0 → 10 → 20, the input ends, reject.
example : coinMachine.eval [.ten, .ten] = some 4 := by decide

/-- Every string of exactly `n` symbols over the alphabet `l`. -/
def stringsOfLength {α : Type*} (l : List α) : ℕ → List (List α)
  | 0 => [[]]
  | n + 1 => (stringsOfLength l n).flatMap fun w => l.map fun a => a :: w

/-- Every coin sequence of 0 to `n` coins. -/
def coinStrings (n : ℕ) : List (List Coin) :=
  (List.range (n + 1)).flatMap (stringsOfLength [.five, .ten, .twenty])

-- There are 1,093 coin sequences of 0 to 6 coins.
example : (coinStrings 6).length = 1093 := by decide +kernel

-- Exactly 18 of them buy the coffee.
example : (coinStrings 6).countP (fun w => coinMachine.eval w = some 6) = 18 := by decide +kernel

-- By length: 2, 4, 6, 5 and 1 accepted strings of 2 to 6 coins.
example : ([2, 3, 4, 5, 6].map fun n =>
    (stringsOfLength [.five, .ten, .twenty] n).countP (fun w => coinMachine.eval w = some 6))
    = [2, 4, 6, 5, 1] := by decide +kernel

-- The complement machine (swap accepting and rejecting states) accepts 1,093 - 18 = 1,075.
example : (coinStrings 6).countP (fun w => coinMachine.eval w ≠ some 6) = 1075 := by decide +kernel

/-- Machine B counts coins: 0, 1, 2, 3, or "4 or more" (state 4); it accepts 3 or fewer. -/
def coinCount : DFA Coin (Fin 5) where
  step k _ := if k.val < 4 then k + 1 else 4
  start := 0
  accept := {k | k.val ≤ 3}

-- The product machine, exactly 30p and at most 3 coins, accepts 6 sequences
-- (its accepting pairs: first part 30p, second part at most 3 coins).
example : (coinStrings 6).countP (fun w =>
    ((coinMachine.inter coinCount).eval w).1 = some 6 ∧
      ((coinMachine.inter coinCount).eval w).2.val ≤ 3) = 6 := by
  decide +kernel

/-- The depth-3 bracket machine: `some k` is k open brackets (k = 0 to 3), `none` is "dead". -/
def depth3 : DFA DyckStep (Option (Fin 4)) where
  step
    | none, _ => none
    | some k, U => if k.val < 3 then some (k + 1) else none
    | some k, D => if k.val = 0 then none else some (k - 1)
  start := some 0
  accept := {q | q = some 0}

-- It has 5 states.
example : Fintype.card (Option (Fin 4)) = 5 := by decide

-- It accepts `(()())`.
example : depth3.eval [U, U, D, U, D, D] = some 0 := by decide

-- It rejects `(((())))`, which is balanced but 4 deep.
example : depth3.eval [U, U, U, U, D, D, D, D] = none := by decide

-- After 0 to 5 opens the states are 0, 1, 2, 3, dead, dead.
example : (List.range 6).map (fun n => depth3.eval (List.replicate n U))
    = [some 0, some 1, some 2, some 3, none, none] := by decide

#print axioms no_finite_automaton_accepts_balanced_brackets
#print axioms coinMachine_accepts_iff_worth_30p
#print axioms regular_closed_under_and_or_not
