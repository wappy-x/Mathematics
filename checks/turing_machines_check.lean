-- Turing machines: the six-row odometer table adds one to every binary reading in exactly n + t + 2 steps, and the ten-row bracket table accepts exactly the balanced bracket strings.
import Mathlib.Computability.TuringMachine.Tape
import Mathlib.Combinatorics.Enumerative.DyckWord
import Mathlib.Data.Nat.Digits.Defs

open Turing

namespace TuringCard

/-! ## The model: a rule table, a tape (Mathlib's `Turing.Tape`) and a head -/

/-- A rule table: for each state `q` and symbol `a` under the head, at most one row
`δ q a = some (b, D, q')`: write `b`, move one cell in direction `D`, go to state `q'`.
`none` means there is no row, and the machine halts. -/
abbrev RuleTable (Q Γ : Type) := Q → Γ → Option (Γ × Dir × Q)

/-- A configuration: the current state and the tape, whose `head` field is the cell under the head. -/
structure Cfg (Q Γ : Type) [Inhabited Γ] where
  state : Q
  tape : Tape Γ

variable {Q Γ : Type} [Inhabited Γ]

/-- One step: look up the row for (state, symbol under the head), write, move, change state.
`none` when the table has no row, so the machine halts. -/
def step (δ : RuleTable Q Γ) (c : Cfg Q Γ) : Option (Cfg Q Γ) :=
  (δ c.state c.tape.head).map fun r => ⟨r.2.2, (c.tape.write r.1).move r.2.1⟩

/-- The configuration after `k` steps from `c`, or `none` if the machine halted before step `k`. -/
def runFor (δ : RuleTable Q Γ) (k : ℕ) (c : Cfg Q Γ) : Option (Cfg Q Γ) :=
  (fun o => o.bind (step δ))^[k] (some c)

/-- The run of `δ` from `c` halts after exactly `k` steps, in configuration `c'`. -/
def HaltsIn (δ : RuleTable Q Γ) (c : Cfg Q Γ) (k : ℕ) (c' : Cfg Q Γ) : Prop :=
  runFor δ k c = some c' ∧ step δ c' = none

/-- The tape holds exactly the string `s` in consecutive cells, and blanks everywhere else. -/
def Reads (T : Tape Γ) (s : List Γ) : Prop :=
  ∃ p : ℤ, ∀ i : ℤ, T.nth i = if 0 ≤ i - p then s.getD (i - p).toNat default else default

/-- The cells `lo, lo + 1, ..., lo + n - 1`, counted from the head (used only in the examples). -/
def cells (T : Tape Γ) (lo : ℤ) (n : ℕ) : List Γ :=
  (List.range n).map fun i => T.nth (lo + i)


/-! ## Helper lemmas about runs and tapes -/

/-- A tape given by two lists: the cells left of the head (nearest first) and the cells from the
head rightwards. -/
def tp (L R : List Γ) : Tape Γ := Tape.mk' (ListBlank.mk L) (ListBlank.mk R)

theorem iter_none (δ : RuleTable Q Γ) (k : ℕ) :
    (fun o : Option (Cfg Q Γ) => o.bind (step δ))^[k] none = none := by
  induction k with
  | zero => rfl
  | succ k ih => rw [Function.iterate_succ_apply]; exact ih

#print axioms iter_none

theorem runFor_succ (δ : RuleTable Q Γ) (k : ℕ) (c c1 : Cfg Q Γ) (h : step δ c = some c1) :
    runFor δ (k + 1) c = runFor δ k c1 := by
  unfold runFor
  rw [Function.iterate_succ_apply]
  change (fun o : Option (Cfg Q Γ) => o.bind (step δ))^[k] (step δ c) = _
  rw [h]

#print axioms runFor_succ

theorem runFor_one (δ : RuleTable Q Γ) (c c1 : Cfg Q Γ) (h : step δ c = some c1) :
    runFor δ 1 c = some c1 := by
  rw [runFor_succ δ 0 c c1 h]; rfl

#print axioms runFor_one

theorem runFor_trans (δ : RuleTable Q Γ) (a b : ℕ) (c c1 c2 : Cfg Q Γ)
    (h1 : runFor δ a c = some c1) (h2 : runFor δ b c1 = some c2) :
    runFor δ (a + b) c = some c2 := by
  unfold runFor at *
  rw [Nat.add_comm, Function.iterate_add_apply, h1]
  exact h2

#print axioms runFor_trans

theorem halts_step (δ : RuleTable Q Γ) (c c1 : Cfg Q Γ) (P : Cfg Q Γ → Prop)
    (h : step δ c = some c1) (H : ∃ k c', HaltsIn δ c1 k c' ∧ P c') :
    ∃ k c', HaltsIn δ c k c' ∧ P c' := by
  obtain ⟨k, c', ⟨h1, h2⟩, h3⟩ := H
  exact ⟨k + 1, c', ⟨by rw [runFor_succ δ k c c1 h]; exact h1, h2⟩, h3⟩

#print axioms halts_step

theorem halts_here (δ : RuleTable Q Γ) (c : Cfg Q Γ) (P : Cfg Q Γ → Prop)
    (h : step δ c = none) (H : P c) : ∃ k c', HaltsIn δ c k c' ∧ P c' :=
  ⟨0, c, ⟨rfl, h⟩, H⟩

#print axioms halts_here

theorem step_right (δ : RuleTable Q Γ) (q : Q) (L R : List Γ) (b : Γ) (q' : Q)
    (h : δ q R.headI = some (b, Dir.right, q')) :
    step δ ⟨q, tp L R⟩ = some ⟨q', tp (b :: L) R.tail⟩ := by
  show (δ q R.headI).map _ = _
  rw [h]; rfl

#print axioms step_right

theorem step_left (δ : RuleTable Q Γ) (q : Q) (L R : List Γ) (b : Γ) (q' : Q)
    (h : δ q R.headI = some (b, Dir.left, q')) :
    step δ ⟨q, tp L R⟩ = some ⟨q', tp L.tail (L.headI :: b :: R.tail)⟩ := by
  show (δ q R.headI).map _ = _
  rw [h]; rfl

#print axioms step_left

theorem move_left_tp (L R : List Γ) :
    (tp L R).move Dir.left = tp L.tail (L.headI :: R) := by
  simp [tp, Tape.move_left_mk']

#print axioms move_left_tp

theorem move_right_tp (L R : List Γ) (a : Γ) :
    (tp L (a :: R)).move Dir.right = tp (a :: L) R := by
  simp [tp, Tape.move_right_mk']

#print axioms move_right_tp

theorem tp_trim (L R : List Γ) : tp L (R ++ [default]) = tp L R := by
  unfold tp
  congr 1
  exact Quotient.sound' (Or.inr ⟨1, rfl⟩)

#print axioms tp_trim

theorem reads_move_right (T : Tape Γ) (s : List Γ) (h : Reads T s) :
    Reads (T.move Dir.right) s := by
  obtain ⟨p, hp⟩ := h
  refine ⟨p - 1, fun i => ?_⟩
  rw [Tape.move_right_nth, hp]
  have : i + 1 - p = i - (p - 1) := by ring
  rw [this]

#print axioms reads_move_right

theorem reads_move_left (T : Tape Γ) (s : List Γ) (h : Reads T s) :
    Reads (T.move Dir.left) s := by
  obtain ⟨p, hp⟩ := h
  refine ⟨p + 1, fun i => ?_⟩
  rw [Tape.move_left_nth, hp]
  have : i - 1 - p = i - (p + 1) := by ring
  rw [this]

#print axioms reads_move_left

theorem reads_tp (A B : List Γ) : Reads (tp A B) (A.reverse ++ B) := by
  induction A generalizing B with
  | nil =>
    refine ⟨0, fun i => ?_⟩
    rcases i with n | n
    · simp only [Int.ofNat_eq_natCast, tp, Tape.mk'_nth_nat, ListBlank.nth_mk]
      simp [List.getI_eq_getElem?_getD]
    · show (ListBlank.mk ([] : List Γ)).nth n = _
      simp
  | cons a A ih =>
    have h := reads_move_right _ _ (ih (a :: B))
    rw [move_right_tp] at h
    simpa using h

#print axioms reads_tp

/-! ## The odometer table -/

/-- Tape symbols for the odometer: the blank ␣, and the digits 0 and 1. -/
inductive Sym
  | blank
  | zero
  | one
  deriving DecidableEq, Repr

instance : Inhabited Sym := ⟨.blank⟩

/-- A binary digit as a tape symbol: `false` is 0, `true` is 1. -/
def digit : Bool → Sym
  | false => .zero
  | true => .one

/-- The odometer's states. -/
inductive OdoState
  | right
  | carry
  | done
  deriving DecidableEq, Repr

/-- The odometer's six-row table (state, read → write, move, next); `done` has no rows. -/
def addOne : RuleTable OdoState Sym
  | .right, .zero => some (.zero, Dir.right, .right)
  | .right, .one => some (.one, Dir.right, .right)
  | .right, .blank => some (.blank, Dir.left, .carry)
  | .carry, .one => some (.zero, Dir.left, .carry)
  | .carry, .zero => some (.one, Dir.left, .done)
  | .carry, .blank => some (.one, Dir.left, .done)
  | _, _ => none

/-- value(s): the number a digit string stands for, leftmost digit most significant. -/
def value (ds : List Bool) : ℕ :=
  Nat.ofDigits 2 (ds.reverse.map Bool.toNat)

/-- t: the number of trailing 1s, the 1s at the right end before the first 0. -/
def trailingOnes (ds : List Bool) : ℕ :=
  (ds.reverse.takeWhile id).length

/-- The start: the digits on the tape, the head on the leftmost digit, in state `right`. -/
def odoStart (ds : List Bool) : Cfg OdoState Sym :=
  ⟨.right, Tape.mk₁ (ds.map digit)⟩


/-! ## Helper lemmas for the odometer -/

theorem odo_right (ds : List Bool) (L : List Sym) :
    runFor addOne ds.length ⟨.right, tp L (ds.map digit)⟩ =
      some ⟨.right, tp ((ds.map digit).reverse ++ L) []⟩ := by
  induction ds generalizing L with
  | nil => rfl
  | cons a ds ih =>
    have hs : step addOne ⟨.right, tp L ((a :: ds).map digit)⟩ =
        some ⟨.right, tp (digit a :: L) (ds.map digit)⟩ :=
      step_right _ _ _ _ _ _ (by cases a <;> rfl)
    rw [List.length_cons, runFor_succ _ _ _ _ hs, ih]
    simp

#print axioms odo_right

theorem odo_turn (L : List Sym) :
    runFor addOne 1 ⟨.right, tp L []⟩ = some ⟨.carry, tp L.tail [L.headI]⟩ := by
  apply runFor_one
  rw [step_left _ _ _ _ Sym.blank OdoState.carry rfl]
  exact congrArg (fun T => some (⟨.carry, T⟩ : Cfg OdoState Sym)) (tp_trim L.tail [L.headI])

#print axioms odo_turn

theorem odo_carry (k : ℕ) (M R : List Sym) :
    runFor addOne k ⟨.carry, tp (List.replicate k Sym.one ++ M).tail
        ((List.replicate k Sym.one ++ M).headI :: R)⟩ =
      some ⟨.carry, tp M.tail (M.headI :: (List.replicate k Sym.zero ++ R))⟩ := by
  induction k generalizing R with
  | zero => rfl
  | succ k ih =>
    have hs : step addOne ⟨.carry, tp (List.replicate (k + 1) Sym.one ++ M).tail
        ((List.replicate (k + 1) Sym.one ++ M).headI :: R)⟩ =
        some ⟨.carry, tp (List.replicate k Sym.one ++ M).tail
          ((List.replicate k Sym.one ++ M).headI :: Sym.zero :: R)⟩ :=
      step_left _ _ _ _ _ _ rfl
    rw [runFor_succ _ _ _ _ hs, ih]
    simp [List.replicate_succ']

#print axioms odo_carry

theorem odo_done (T : Tape Sym) : step addOne ⟨.done, T⟩ = none := by
  show (addOne .done T.head).map _ = none
  generalize T.head = x
  cases x <;> rfl

#print axioms odo_done

theorem bool_list_cases (ds : List Bool) :
    (∃ n, ds = List.replicate n true) ∨ (∃ w t, ds = w ++ false :: List.replicate t true) := by
  induction ds using List.reverseRecOn with
  | nil => exact Or.inl ⟨0, rfl⟩
  | append_singleton l a ih =>
    cases a with
    | false => exact Or.inr ⟨l, 0, rfl⟩
    | true =>
      rcases ih with ⟨n, rfl⟩ | ⟨w, t, rfl⟩
      · exact Or.inl ⟨n + 1, by simp [List.replicate_succ']⟩
      · exact Or.inr ⟨w, t + 1, by simp [List.replicate_succ']⟩

#print axioms bool_list_cases

theorem takeWhile_rep (t : ℕ) (rest : List Bool) :
    (List.replicate t true ++ rest).takeWhile id = List.replicate t true ++ rest.takeWhile id := by
  induction t with
  | zero => rfl
  | succ t ih => simp [List.replicate_succ, ih]

#print axioms takeWhile_rep

theorem trailingOnes_rep (n : ℕ) : trailingOnes (List.replicate n true) = n := by
  have h := takeWhile_rep n []
  simp only [List.append_nil, List.takeWhile_nil] at h
  simp [trailingOnes, h]

#print axioms trailingOnes_rep

theorem trailingOnes_flip (w : List Bool) (t : ℕ) :
    trailingOnes (w ++ false :: List.replicate t true) = t := by
  have h := takeWhile_rep t (false :: w.reverse)
  simp only [List.takeWhile_cons, id, Bool.false_eq_true, ↓reduceIte, List.append_nil] at h
  simp [trailingOnes, h]

#print axioms trailingOnes_flip

theorem ofDigits_ones (t : ℕ) : Nat.ofDigits 2 (List.replicate t 1) + 1 = 2 ^ t := by
  induction t with
  | zero => rfl
  | succ t ih => rw [List.replicate_succ, Nat.ofDigits_cons, pow_succ]; omega

#print axioms ofDigits_ones

theorem ofDigits_zeros (t : ℕ) : Nat.ofDigits 2 (List.replicate t 0) = 0 := by
  induction t with
  | zero => rfl
  | succ t ih => rw [List.replicate_succ, Nat.ofDigits_cons, ih]

#print axioms ofDigits_zeros

theorem value_flip (w : List Bool) (t n : ℕ) :
    value (w ++ false :: List.replicate t true) + 1 = value (w ++ true :: List.replicate t false) ∧
      value (List.replicate n true) + 1 = value (true :: List.replicate n false) := by
  constructor
  · simp only [value, List.reverse_append, List.reverse_cons, List.reverse_replicate,
      List.map_append, List.map_replicate, List.map_cons, List.append_assoc, List.singleton_append,
      Nat.ofDigits_append, Nat.ofDigits_cons, List.length_replicate, Bool.toNat_true,
      Bool.toNat_false, ofDigits_zeros]
    have := ofDigits_ones t
    have h2 : (2:ℕ) ^ t > 0 := by positivity
    nlinarith
  · simp only [value, List.reverse_cons, List.reverse_replicate, List.map_append,
      List.map_replicate, List.map_cons, List.map_nil, Nat.ofDigits_append, Bool.toNat_true,
      Bool.toNat_false, ofDigits_zeros, List.length_replicate, Nat.ofDigits_singleton]
    have := ofDigits_ones n
    omega

#print axioms value_flip

/-- The odometer table adds one. Started in state `right` on the leftmost of the n digits of any
binary reading with t trailing 1s, it halts in `done` after exactly n + t + 2 steps, and the tape
then holds a binary reading whose value is one more: n digits long, or n + 1 when every digit was 1. -/
theorem odometer_adds_one_in_n_plus_t_plus_two_steps (ds : List Bool) :
    ∃ c', HaltsIn addOne (odoStart ds) (ds.length + trailingOnes ds + 2) c' ∧
      c'.state = .done ∧
      ∃ out : List Bool, Reads c'.tape (out.map digit) ∧ value out = value ds + 1 ∧
        out.length = if trailingOnes ds = ds.length then ds.length + 1 else ds.length := by
  rcases bool_list_cases ds with ⟨n, rfl⟩ | ⟨w, t, rfl⟩
  · rw [trailingOnes_rep]
    have h1 := odo_right (List.replicate n true) []
    have hL : ((List.replicate n true).map digit).reverse ++ [] =
        List.replicate n Sym.one ++ [] := by simp [digit]
    rw [hL] at h1
    have h2 := odo_turn (List.replicate n Sym.one ++ [])
    have h3 := odo_carry n [] []
    have h4 : runFor addOne 1 ⟨.carry, tp ([] : List Sym).tail
          (([] : List Sym).headI :: (List.replicate n Sym.zero ++ []))⟩ =
        some ⟨.done, tp ([] : List Sym).tail
          (([] : List Sym).headI :: Sym.one :: (List.replicate n Sym.zero ++ []))⟩ :=
      runFor_one _ _ _ (step_left _ _ _ _ _ _ rfl)
    have hrun := runFor_trans _ _ _ _ _ _
      (runFor_trans _ _ _ _ _ _ (runFor_trans _ _ _ _ _ _ h1 h2) h3) h4
    have e : (List.replicate n true).length + n + 2 = (List.replicate n true).length + 1 + n + 1 := by omega
    rw [e]
    refine ⟨_, ⟨hrun, odo_done _⟩, rfl, true :: List.replicate n false, ?_, ?_, ?_⟩
    · have h := reads_move_left _ _
        (reads_tp ([] : List Sym) (Sym.one :: (List.replicate n Sym.zero ++ [])))
      rw [move_left_tp] at h
      have e : (true :: List.replicate n false).map digit =
          ([] : List Sym).reverse ++ Sym.one :: (List.replicate n Sym.zero ++ []) := by
        simp [digit]
      rw [e]; exact h
    · exact (value_flip [] 0 n).2.symm
    · simp
  · rw [trailingOnes_flip]
    have h1 := odo_right (w ++ false :: List.replicate t true) []
    have hL : ((w ++ false :: List.replicate t true).map digit).reverse ++ [] =
        List.replicate t Sym.one ++ (Sym.zero :: (w.map digit).reverse) := by simp [digit]
    rw [hL] at h1
    have h2 := odo_turn (List.replicate t Sym.one ++ (Sym.zero :: (w.map digit).reverse))
    have h3 := odo_carry t (Sym.zero :: (w.map digit).reverse) []
    have h4 : runFor addOne 1 ⟨.carry, tp (Sym.zero :: (w.map digit).reverse).tail
          ((Sym.zero :: (w.map digit).reverse).headI :: (List.replicate t Sym.zero ++ []))⟩ =
        some ⟨.done, tp (w.map digit).reverse.tail
          ((w.map digit).reverse.headI :: Sym.one :: (List.replicate t Sym.zero ++ []))⟩ :=
      runFor_one _ _ _ (step_left _ _ _ _ _ _ rfl)
    have hrun := runFor_trans _ _ _ _ _ _
      (runFor_trans _ _ _ _ _ _ (runFor_trans _ _ _ _ _ _ h1 h2) h3) h4
    have e : (w ++ false :: List.replicate t true).length + t + 2 = (w ++ false :: List.replicate t true).length + 1 + t + 1 := by omega
    rw [e]
    refine ⟨_, ⟨hrun, odo_done _⟩, rfl, w ++ true :: List.replicate t false, ?_, ?_, ?_⟩
    · have h := reads_move_left _ _
        (reads_tp (w.map digit).reverse (Sym.one :: (List.replicate t Sym.zero ++ [])))
      rw [move_left_tp] at h
      have e : (w ++ true :: List.replicate t false).map digit =
          (w.map digit).reverse.reverse ++ Sym.one :: (List.replicate t Sym.zero ++ []) := by
        simp [digit]
      rw [e]; exact h
    · exact (value_flip w t 0).1.symm
    · split_ifs with h
      · simp at h; omega
      · simp

/-- Adding one in binary flips the trailing 1s and the 0 before them:
value(w 0 1^t) + 1 = value(w 1 0^t), and value(1^n) + 1 = value(1 0^n). -/
theorem value_add_one_flips_trailing_ones (w : List Bool) (t n : ℕ) :
    value (w ++ false :: List.replicate t true) + 1 = value (w ++ true :: List.replicate t false) ∧
      value (List.replicate n true) + 1 = value (true :: List.replicate n false) := by
  exact value_flip w t n

/-! ## The bracket table -/

/-- Tape symbols for the bracket checker: blank, `(`, `)` and the cross-off mark `X`. -/
inductive BSym
  | blank
  | op
  | cl
  | X
  deriving DecidableEq, Repr

instance : Inhabited BSym := ⟨.blank⟩

/-- The bracket checker's states; `accept` and `reject` have no rows. -/
inductive BState
  | seek
  | back
  | check
  | accept
  | reject
  deriving DecidableEq, Repr

/-- The bracket checker's ten-row table. -/
def brackets : RuleTable BState BSym
  | .seek, .op => some (.op, Dir.right, .seek)
  | .seek, .X => some (.X, Dir.right, .seek)
  | .seek, .cl => some (.X, Dir.left, .back)
  | .seek, .blank => some (.blank, Dir.left, .check)
  | .back, .X => some (.X, Dir.left, .back)
  | .back, .op => some (.X, Dir.right, .seek)
  | .back, .blank => some (.blank, Dir.right, .reject)
  | .check, .X => some (.X, Dir.left, .check)
  | .check, .op => some (.op, Dir.right, .reject)
  | .check, .blank => some (.blank, Dir.right, .accept)
  | _, _ => none

/-- A bracket as a tape symbol: Mathlib's `DyckStep.U` is `(` and `DyckStep.D` is `)`. -/
def bracketSym : DyckStep → BSym
  | .U => .op
  | .D => .cl

/-- The start: the brackets on the tape, the head on the leftmost one, in state `seek`. -/
def bracketStart (w : List DyckStep) : Cfg BState BSym :=
  ⟨.seek, Tape.mk₁ (w.map bracketSym)⟩

/-- Balanced: the string is a Dyck word (Mathlib's `DyckWord`): as many `(` as `)`, and no prefix
with more `)` than `(`. -/
def Balanced (w : List DyckStep) : Prop :=
  ∃ d : DyckWord, d.toList = w


/-! ## Helper definitions and lemmas for the bracket checker -/

/-- The brackets still on the tape, read left to right, with the crossed-off cells skipped. -/
def strip : List BSym → List DyckStep
  | [] => []
  | .op :: r => DyckStep.U :: strip r
  | .cl :: r => DyckStep.D :: strip r
  | _ :: r => strip r

/-- `okD n s`: starting with `n` unmatched `(`, the string `s` closes them all and never closes
more than are open. -/
def okD : ℕ → List DyckStep → Prop
  | n, [] => n = 0
  | n, DyckStep.U :: s => okD (n + 1) s
  | 0, DyckStep.D :: _ => False
  | n + 1, DyckStep.D :: s => okD n s

theorem okD_iff (s : List DyckStep) (n : ℕ) :
    okD n s ↔ (s.count DyckStep.D = n + s.count DyckStep.U ∧
      ∀ i, (s.take i).count DyckStep.D ≤ n + (s.take i).count DyckStep.U) := by
  induction s generalizing n with
  | nil =>
    simp only [okD, List.count_nil, List.take_nil]
    constructor
    · intro h; exact ⟨by omega, fun _ => by omega⟩
    · intro h; omega
  | cons x s ih =>
    cases x with
    | U =>
      rw [okD, ih]
      constructor
      · rintro ⟨h1, h2⟩
        refine ⟨by simp; omega, fun i => ?_⟩
        cases i with
        | zero => simp
        | succ i => have := h2 i; simp [List.take_succ_cons]; omega
      · rintro ⟨h1, h2⟩
        refine ⟨by simp at h1; omega, fun i => ?_⟩
        have := h2 (i + 1); simp [List.take_succ_cons] at this; omega
    | D =>
      cases n with
      | zero =>
        simp only [okD, false_iff]
        rintro ⟨h1, h2⟩
        have := h2 1
        simp at this
      | succ n =>
        rw [okD, ih]
        constructor
        · rintro ⟨h1, h2⟩
          refine ⟨by simp; omega, fun i => ?_⟩
          cases i with
          | zero => simp
          | succ i => have := h2 i; simp [List.take_succ_cons]; omega
        · rintro ⟨h1, h2⟩
          refine ⟨by simp at h1; omega, fun i => ?_⟩
          have := h2 (i + 1); simp [List.take_succ_cons] at this; omega

#print axioms okD_iff

theorem balanced_iff (w : List DyckStep) : Balanced w ↔ okD 0 w := by
  rw [okD_iff]
  constructor
  · rintro ⟨d, rfl⟩
    exact ⟨by simp [d.count_U_eq_count_D], fun i => by simpa using d.count_D_le_count_U i⟩
  · rintro ⟨h1, h2⟩
    exact ⟨⟨w, by omega, fun i => by simpa using h2 i⟩, rfl⟩

#print axioms balanced_iff

theorem strip_map (w : List DyckStep) : strip (w.map bracketSym) = w := by
  induction w with
  | nil => rfl
  | cons x w ih => cases x <;> simp [bracketSym, strip, ih]

#print axioms strip_map

/-- The run from `c` halts in `accept` or `reject`, and in `accept` exactly when `T` holds. -/
def BGood (c : Cfg BState BSym) (T : Prop) : Prop :=
  ∃ k c', HaltsIn brackets c k c' ∧
    ((c'.state = .accept ∨ c'.state = .reject) ∧ (c'.state = .accept ↔ T))

theorem bgood_congr (c : Cfg BState BSym) (T T' : Prop) (h : BGood c T) (e : T ↔ T') :
    BGood c T' := by
  obtain ⟨k, c', h1, h2, h3⟩ := h
  exact ⟨k, c', h1, h2, h3.trans e⟩

#print axioms bgood_congr

theorem bgood_step (c c1 : Cfg BState BSym) (T : Prop) (h : step brackets c = some c1)
    (H : BGood c1 T) : BGood c T :=
  halts_step brackets c c1 _ h H

#print axioms bgood_step

theorem brackets_accept (T : Tape BSym) (P : Prop) (hP : P) : BGood ⟨.accept, T⟩ P := by
  refine halts_here brackets _ _ ?_ ⟨Or.inl rfl, iff_of_true rfl hP⟩
  show (brackets .accept T.head).map _ = none
  generalize T.head = x
  cases x <;> rfl

#print axioms brackets_accept

theorem brackets_reject (T : Tape BSym) (P : Prop) (hP : ¬ P) : BGood ⟨.reject, T⟩ P := by
  refine halts_here brackets _ _ ?_ ⟨Or.inr rfl, iff_of_false (by simp) hP⟩
  show (brackets .reject T.head).map _ = none
  generalize T.head = x
  cases x <;> rfl

#print axioms brackets_reject

/-- The cells left of the head hold only `(` and `X`. -/
def LeftOK (L : List BSym) : Prop := ∀ y ∈ L, y = .op ∨ y = .X

/-- The cells from the head rightwards hold no blank. -/
def RightOK (R : List BSym) : Prop := ∀ y ∈ R, y ≠ .blank

theorem check_run (L R : List BSym) (hL : LeftOK L) :
    BGood ⟨.check, tp L.tail (L.headI :: R)⟩ (L.count .op = 0) := by
  induction L generalizing R with
  | nil =>
    exact bgood_step _ _ _ (step_right _ _ _ _ _ _ rfl) (brackets_accept _ _ (by simp))
  | cons y L ih =>
    rcases hL y (by simp) with rfl | rfl
    · exact bgood_step _ _ _ (step_right _ _ _ _ _ _ rfl) (brackets_reject _ _ (by simp))
    · refine bgood_step _ _ _ (step_left _ _ _ _ _ _ rfl) ?_
      refine bgood_congr _ _ _ (ih (.X :: R) (fun z hz => hL z (by simp [hz]))) ?_
      simp

#print axioms check_run

theorem back_run (M : ℕ)
    (hseek : ∀ L R, LeftOK L → RightOK R → R.count .cl = M →
      BGood ⟨.seek, tp L R⟩ (okD (L.count .op) (strip R))) :
    ∀ L R, LeftOK L → RightOK R → R.count .cl = M →
      BGood ⟨.back, tp L.tail (L.headI :: R)⟩ (okD (L.count .op) (DyckStep.D :: strip R)) := by
  intro L
  induction L with
  | nil =>
    intro R _ _ _
    exact bgood_step _ _ _ (step_right _ _ _ _ _ _ rfl) (brackets_reject _ _ (by simp [okD]))
  | cons y L ih =>
    intro R hL hR hM
    rcases hL y (by simp) with rfl | rfl
    · refine bgood_step _ _ _ (step_right _ _ _ _ _ _ rfl) ?_
      have hL' : LeftOK (.X :: L) := by
        intro z hz
        simp only [List.mem_cons] at hz
        rcases hz with rfl | hz
        · exact Or.inr rfl
        · exact hL z (by simp [hz])
      refine bgood_congr _ _ _ (hseek (.X :: L) R hL' hR hM) ?_
      simp [okD]
    · refine bgood_step _ _ _ (step_left _ _ _ _ _ _ rfl) ?_
      have hR' : RightOK (.X :: R) := by
        intro z hz
        simp only [List.mem_cons] at hz
        rcases hz with rfl | hz
        · simp
        · exact hR z hz
      refine bgood_congr _ _ _
        (ih (.X :: R) (fun z hz => hL z (by simp [hz])) hR' (by simp [hM])) ?_
      simp [strip]

#print axioms back_run

theorem seek_run (N : ℕ) :
    ∀ L R, LeftOK L → RightOK R → R.count .cl = N →
      BGood ⟨.seek, tp L R⟩ (okD (L.count .op) (strip R)) := by
  induction N using Nat.strong_induction_on with
  | _ N IH =>
  intro L R
  induction R generalizing L with
  | nil =>
    intro hL _ _
    refine bgood_step _ _ _ (step_left _ _ _ _ _ _ rfl) ?_
    refine bgood_congr _ _ _ (check_run L _ hL) ?_
    simp [okD, strip]
  | cons x R ih =>
    intro hL hR hN
    have hR' : RightOK R := fun z hz => hR z (by simp [hz])
    cases x with
    | blank => exact absurd rfl (hR _ (by simp))
    | op =>
      refine bgood_step _ _ _ (step_right _ _ _ _ _ _ rfl) ?_
      have hL' : LeftOK (.op :: L) := by
        intro z hz
        simp only [List.mem_cons] at hz
        rcases hz with rfl | hz
        · exact Or.inl rfl
        · exact hL z hz
      refine bgood_congr _ _ _ (ih (.op :: L) hL' hR' (by simpa using hN)) ?_
      simp [strip, okD]
    | X =>
      refine bgood_step _ _ _ (step_right _ _ _ _ _ _ rfl) ?_
      have hL' : LeftOK (.X :: L) := by
        intro z hz
        simp only [List.mem_cons] at hz
        rcases hz with rfl | hz
        · exact Or.inr rfl
        · exact hL z hz
      refine bgood_congr _ _ _ (ih (.X :: L) hL' hR' (by simpa using hN)) ?_
      simp [strip]
    | cl =>
      refine bgood_step _ _ _ (step_left _ _ _ _ _ _ rfl) ?_
      have hlt : (BSym.X :: R).count .cl < N := by simp at hN; simp; omega
      have hRX : RightOK (.X :: R) := by
        intro z hz
        simp only [List.mem_cons] at hz
        rcases hz with rfl | hz
        · simp
        · exact hR' z hz
      refine bgood_congr _ _ _
        (back_run _ (IH _ hlt) L (.X :: R) hL hRX rfl) ?_
      simp [strip]

#print axioms seek_run

/-- The bracket table accepts exactly the balanced strings: on every bracket string it halts,
in `accept` or `reject`, and it halts in `accept` exactly when the string is balanced. -/
theorem bracket_table_accepts_exactly_balanced (w : List DyckStep) :
    ∃ k c', HaltsIn brackets (bracketStart w) k c' ∧
      (c'.state = .accept ∨ c'.state = .reject) ∧ (c'.state = .accept ↔ Balanced w) := by
  have hR : RightOK (w.map bracketSym) := by
    intro z hz
    simp only [List.mem_map] at hz
    obtain ⟨a, _, rfl⟩ := hz
    cases a <;> simp [bracketSym]
  obtain ⟨k, c', h1, h2, h3⟩ :=
    seek_run _ [] (w.map bracketSym) (by simp [LeftOK]) hR rfl
  refine ⟨k, c', h1, h2, ?_⟩
  rw [h3, balanced_iff, strip_map]
  simp

/-! ## The card's worked examples, checked exactly -/

open DyckStep

-- 10111 is 23 and 11000 is 24.
example : value [true, false, true, true, true] = 23 ∧ value [true, true, false, false, false] = 24 := by
  decide

-- 10111: t = 3, so n + t + 2 = 5 + 3 + 2 = 10 steps; the tape reads 11000 and the machine is in `done`.
example : trailingOnes [true, false, true, true, true] = 3 := by decide

example : (runFor addOne 10 (odoStart [true, false, true, true, true])).map
      (fun c => (c.state, cells c.tape (-1) 7)) =
    some (.done, [.blank, .one, .one, .zero, .zero, .zero, .blank]) := by
  decide

example : ((runFor addOne 10 (odoStart [true, false, true, true, true])).bind (step addOne)).isNone := by
  decide

-- 11111 becomes 100000 in 12 steps, halting in `done`.
example : (runFor addOne 12 (odoStart [true, true, true, true, true])).map
      (fun c => (c.state, cells c.tape 0 8, (step addOne c).isNone)) =
    some (.done, [.blank, .one, .zero, .zero, .zero, .zero, .zero, .blank], true) := by
  decide

-- All ones: n = 10 halts in `done` after 22 steps, n = 20 after 42.
example : (runFor addOne 22 (odoStart (List.replicate 10 true))).map
      (fun c => (c.state, (step addOne c).isNone)) = some (.done, true) := by
  decide

example : (runFor addOne 42 (odoStart (List.replicate 20 true))).map
      (fun c => (c.state, (step addOne c).isNone)) = some (.done, true) := by
  decide

-- 0 becomes 1 in 3 steps; 0111 becomes 1000 in 9 steps.
example : (runFor addOne 3 (odoStart [false])).map
      (fun c => (c.state, cells c.tape 0 3, (step addOne c).isNone)) =
    some (.done, [.blank, .one, .blank], true) := by
  decide

example : (runFor addOne 9 (odoStart [false, true, true, true])).map
      (fun c => (c.state, cells c.tape 0 6, (step addOne c).isNone)) =
    some (.done, [.blank, .one, .zero, .zero, .zero, .blank], true) := by
  decide

-- What breaks: with a cap of 11 steps, 11111 is still running (a row still applies).
example : ((runFor addOne 11 (odoStart [true, true, true, true, true])).bind (step addOne)).isSome := by
  decide

-- The bracket checker: (()()) is accepted after 28 steps, with tape XXXXXX.
example : (runFor brackets 28 (bracketStart [U, U, D, U, D, D])).map
      (fun c => (c.state, cells c.tape (-1) 8, (step brackets c).isNone)) =
    some (.accept, [.blank, .X, .X, .X, .X, .X, .X, .blank], true) := by
  decide

-- (() is rejected after 9 steps, with tape (XX; ())( is rejected after 8 steps.
example : (runFor brackets 9 (bracketStart [U, U, D])).map
      (fun c => (c.state, cells c.tape (-1) 4, (step brackets c).isNone)) =
    some (.reject, [.op, .X, .X, .blank], true) := by
  decide

example : (runFor brackets 8 (bracketStart [U, D, D, U])).map
      (fun c => (c.state, (step brackets c).isNone)) = some (.reject, true) := by
  decide

#print axioms odometer_adds_one_in_n_plus_t_plus_two_steps
#print axioms value_add_one_flips_trailing_ones
#print axioms bracket_table_accepts_exactly_balanced

end TuringCard
