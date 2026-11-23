-- Busy beaver: BB(n), the longest run of any halting n-state, two-symbol tape machine started on a blank tape, decides halting for n-state machines, is computed by no program, and ends up above every computable function.
import Mathlib.Computability.Partrec
import Mathlib.Computability.TuringMachine.ToPartrec
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.Sigma
import Mathlib.Data.Fintype.Option
import Mathlib.Data.Int.Interval
import Mathlib.Order.Lattice.Nat
import Mathlib.Tactic.DeriveFintype
import Mathlib.Tactic.NormNum

namespace BusyBeaver

/-- A head move: one cell left or one cell right. There is no "stay put" move. -/
inductive Move
  | L
  | R
  deriving DecidableEq

instance : Fintype Move := ⟨{.L, .R}, fun m => by cases m <;> simp⟩

/-- One rule of an `n`-state machine: the symbol written (`false` is 0, `true` is 1), the move,
and the next state, where `none` is the halt state Z. -/
structure Rule (n : ℕ) where
  write : Bool
  move : Move
  next : Option (Fin n)
  deriving DecidableEq, Fintype

/-- An `n`-state machine: a rule for each state `q` and each symbol read. States are `Fin n`,
state A being `0`. -/
abbrev Machine (n : ℕ) := Fin n → Bool → Rule n

/-- A configuration: the state (`none` once the machine has halted), the head's cell, and the
tape, one symbol per cell. -/
structure Config (n : ℕ) where
  state : Option (Fin n)
  head : ℤ
  tape : ℤ → Bool

/-- One step: read the head's cell, write, move one cell, go to the next state. A halted machine
stays as it is. -/
def step {n : ℕ} (M : Machine n) (c : Config n) : Config n :=
  match c.state with
  | none => c
  | some q =>
      let r := M q (c.tape c.head)
      { state := r.next
        head := c.head + (match r.move with | .L => -1 | .R => 1)
        tape := Function.update c.tape c.head r.write }

/-- The start: state A on a blank tape (every cell 0), head at cell 0. With no states at all,
the machine counts as halted from the start. -/
def start (n : ℕ) : Config n :=
  { state := if h : 0 < n then some ⟨0, h⟩ else none
    head := 0
    tape := fun _ => false }

/-- The configuration after `k` steps from the blank start. -/
def run {n : ℕ} (M : Machine n) (k : ℕ) : Config n := (step M)^[k] (start n)

/-- `M` halts at step `s`, the halting step counted: it has halted after `s` steps and had not
halted after any fewer. This `s` is the card's `s(M)`. -/
def HaltsAt {n : ℕ} (M : Machine n) (s : ℕ) : Prop :=
  (run M s).state = none ∧ ∀ k < s, (run M k).state ≠ none

/-- Whether `M` halts at step `s` can be checked by running it `s` steps. -/
instance {n : ℕ} (M : Machine n) (s : ℕ) : Decidable (HaltsAt M s) := by
  unfold HaltsAt; infer_instance

/-- The busy beaver number: the most steps any `n`-state machine takes from a blank tape before
it halts, `BB(n) = max {s(M) : M has n states and halts}`. -/
noncomputable def BB (n : ℕ) : ℕ := sSup {s | ∃ M : Machine n, HaltsAt M s}

lemma run_zero' {n : ℕ} (M : Machine n) : run M 0 = start n := rfl

lemma run_succ' {n : ℕ} (M : Machine n) (k : ℕ) : run M (k + 1) = step M (run M k) :=
  Function.iterate_succ_apply' _ _ _

lemma step_of_none {n : ℕ} (M : Machine n) (c : Config n) (h : c.state = none) :
    step M c = c := by
  unfold step; rw [h]

lemma run_stays {n : ℕ} (M : Machine n) {k : ℕ} (h : (run M k).state = none) :
    ∀ j, k ≤ j → run M j = run M k := by
  intro j hj
  induction j, hj using Nat.le_induction with
  | base => rfl
  | succ j _ ih => rw [run_succ', ih, step_of_none _ _ h]

lemma exists_haltsAt_le {n : ℕ} (M : Machine n) {k : ℕ} (h : (run M k).state = none) :
    ∃ s ≤ k, HaltsAt M s := by
  classical
  have hex : ∃ s, (run M s).state = none := ⟨k, h⟩
  refine ⟨Nat.find hex, Nat.find_min' hex h, Nat.find_spec hex, fun j hj => Nat.find_min hex hj⟩

lemma haltsAt_unique {n : ℕ} (M : Machine n) {s t : ℕ} (hs : HaltsAt M s) (ht : HaltsAt M t) :
    s = t := by
  rcases lt_trichotomy s t with h | h | h
  · exact absurd hs.1 (ht.2 s h)
  · exact h
  · exact absurd ht.1 (hs.2 t h)

lemma bb_bddAbove (n : ℕ) : BddAbove {s | ∃ M : Machine n, HaltsAt M s} := by
  classical
  refine (Set.Finite.subset (Set.finite_range
    (fun M : Machine n => if h : ∃ s, HaltsAt M s then Nat.find h else 0)) ?_).bddAbove
  rintro s ⟨M, hM⟩
  have hex : ∃ s, HaltsAt M s := ⟨s, hM⟩
  refine ⟨M, ?_⟩
  simp only [dif_pos hex]
  exact haltsAt_unique M (Nat.find_spec hex) hM

lemma le_bb {n : ℕ} (M : Machine n) {s : ℕ} (h : HaltsAt M s) : s ≤ BB n :=
  le_csSup (bb_bddAbove n) ⟨M, h⟩

lemma run_support {n : ℕ} (M : Machine n) (k : ℕ) :
    ∃ F : Finset ℤ, F.card ≤ k ∧ ∀ i ∉ F, (run M k).tape i = false := by
  classical
  induction k with
  | zero => exact ⟨∅, by simp, fun i _ => rfl⟩
  | succ k ih =>
    obtain ⟨F, hF, hF'⟩ := ih
    refine ⟨insert (run M k).head F, (Finset.card_insert_le _ _).trans (by omega), ?_⟩
    intro i hi
    rw [Finset.mem_insert, not_or] at hi
    rw [run_succ']
    unfold step
    cases hs : (run M k).state with
    | none => exact hF' i hi.2
    | some q =>
      simp only [Function.update_of_ne hi.1]
      exact hF' i hi.2

lemma card_le_bb {n : ℕ} (M : Machine n) {s : ℕ} (h : (run M s).state = none) (F : Finset ℤ)
    (hF : ∀ i ∈ F, (run M s).tape i = true) : F.card ≤ BB n := by
  obtain ⟨s', hs', hH⟩ := exists_haltsAt_le M h
  have he := run_stays M hH.1 s hs'
  obtain ⟨G, hG, hG'⟩ := run_support M s'
  have hsub : F ⊆ G := by
    intro i hi
    by_contra hni
    have := hF i hi
    rw [he, hG' i hni] at this
    exact Bool.false_ne_true this
  exact (Finset.card_le_card hsub).trans (hG.trans (le_bb M hH))


/-! Simulating a Mathlib `TM0` machine over `Bool` by a machine of this file. -/

/-- The state with number `k`, if there is one. -/
noncomputable def fidx {N : ℕ} (k : ℕ) : Option (Fin N) := if h : k < N then some ⟨k, h⟩ else none

lemma fidx_of_lt {N k : ℕ} (h : k < N) : (fidx k : Option (Fin N)) = some ⟨k, h⟩ := by
  simp [fidx, h]

open Classical in
/-- The position of a state in a finite set of states. -/
noncomputable def qIdx {Λ₀ : Type} (S₀ : Finset Λ₀) (q : Λ₀) : ℕ :=
  if h : q ∈ S₀ then (S₀.equivFin ⟨q, h⟩ : ℕ) else 0

/-- The state at a position of a finite set of states. -/
noncomputable def qDec {Λ₀ : Type} (S₀ : Finset Λ₀) (q₀ : Λ₀) (k : ℕ) : Λ₀ :=
  if h : k < S₀.card then (S₀.equivFin.symm ⟨k, h⟩).1 else q₀

lemma qIdx_lt {Λ₀ : Type} {S₀ : Finset Λ₀} {q : Λ₀} (hq : q ∈ S₀) : qIdx S₀ q < S₀.card := by
  simp only [qIdx, hq, dite_true]
  exact (S₀.equivFin ⟨q, hq⟩).2

lemma qDec_qIdx {Λ₀ : Type} {S₀ : Finset Λ₀} (q₀ : Λ₀) {q : Λ₀} (hq : q ∈ S₀) :
    qDec S₀ q₀ (qIdx S₀ q) = q := by
  have h := qIdx_lt hq
  simp only [qDec, h, dite_true]
  simp only [qIdx, hq, dite_true, Fin.eta, Equiv.symm_apply_apply]

/-- The simulating machine: `l.length + 1` states write the list `l` and return, then two
states for each state of the `TM0` machine. -/
noncomputable def simM {Λ₀ : Type} [Inhabited Λ₀] (M₀ : Turing.TM0.Machine Bool Λ₀)
    (S₀ : Finset Λ₀) (q₀ : Λ₀) (l : List Bool) (N : ℕ) : Machine N :=
  fun i b =>
    if i.1 < l.length then ⟨l.getI (l.length - 1 - i.1), .L, fidx (i.1 + 1)⟩
    else if i.1 = l.length then ⟨b, .R, fidx (l.length + 1 + 2 * qIdx S₀ q₀)⟩
    else
      if (i.1 - (l.length + 1)) % 2 = 1 then
        ⟨b, .L, fidx (l.length + 1 + 2 * qIdx S₀ (qDec S₀ q₀ ((i.1 - (l.length + 1)) / 2)))⟩
      else match M₀ (qDec S₀ q₀ ((i.1 - (l.length + 1)) / 2)) b with
        | none => ⟨b, .R, none⟩
        | some (q', .move .left) => ⟨b, .L, fidx (l.length + 1 + 2 * qIdx S₀ q')⟩
        | some (q', .move .right) => ⟨b, .R, fidx (l.length + 1 + 2 * qIdx S₀ q')⟩
        | some (q', .write a) => ⟨a, .R, fidx (l.length + 1 + 2 * qIdx S₀ q' + 1)⟩

/-- The move of a rule as a change of head position. -/
def Move.delta : Move → ℤ
  | .L => -1
  | .R => 1

lemma step_some {n : ℕ} (M : Machine n) (c : Config n) {q : Fin n} (h : c.state = some q) :
    step M c = ⟨(M q (c.tape c.head)).next, c.head + (M q (c.tape c.head)).move.delta,
      Function.update c.tape c.head (M q (c.tape c.head)).write⟩ := by
  unfold step; rw [h]
  simp only
  cases (M q (c.tape c.head)).move <;> rfl

/-- How a configuration matches a `TM0` configuration. -/
def SimRel {Λ₀ : Type} [Inhabited Λ₀] {N : ℕ} (S₀ : Finset Λ₀) (W : ℕ) (c : Config N)
    (d : Turing.TM0.Cfg Bool Λ₀) : Prop :=
  d.q ∈ S₀ ∧ c.state = fidx (W + 2 * qIdx S₀ d.q) ∧ ∀ j : ℤ, c.tape (c.head + j) = d.Tape.nth j


section Sim

variable {Λ₀ : Type} [Inhabited Λ₀] (M₀ : Turing.TM0.Machine Bool Λ₀) (S₀ : Finset Λ₀) (q₀ : Λ₀)
  (l : List Bool) (N : ℕ)

lemma simM_writer {i : ℕ} (hi : i < l.length) (hiN : i < N) (b : Bool) :
    simM M₀ S₀ q₀ l N ⟨i, hiN⟩ b = ⟨l.getI (l.length - 1 - i), .L, fidx (i + 1)⟩ := by
  simp [simM, hi]

lemma simM_ret (hiN : l.length < N) (b : Bool) :
    simM M₀ S₀ q₀ l N ⟨l.length, hiN⟩ b = ⟨b, .R, fidx (l.length + 1 + 2 * qIdx S₀ q₀)⟩ := by
  simp [simM]

lemma simM_aux {q : Λ₀} (hq : q ∈ S₀) (hiN : l.length + 1 + 2 * qIdx S₀ q + 1 < N) (b : Bool) :
    simM M₀ S₀ q₀ l N ⟨l.length + 1 + 2 * qIdx S₀ q + 1, hiN⟩ b =
      ⟨b, .L, fidx (l.length + 1 + 2 * qIdx S₀ q)⟩ := by
  have h1 : ¬ (l.length + 1 + 2 * qIdx S₀ q + 1 < l.length) := by omega
  have h2 : ¬ (l.length + 1 + 2 * qIdx S₀ q + 1 = l.length) := by omega
  have h3 : (l.length + 1 + 2 * qIdx S₀ q + 1 - (l.length + 1)) = 2 * qIdx S₀ q + 1 := by omega
  have h4 : (2 * qIdx S₀ q + 1) % 2 = 1 := by omega
  have h5 : (2 * qIdx S₀ q + 1) / 2 = qIdx S₀ q := by omega
  simp only [simM, h1, h2, h3, h4, h5, if_false, if_true, qDec_qIdx q₀ hq]

lemma simM_main {q : Λ₀} (hq : q ∈ S₀) (hiN : l.length + 1 + 2 * qIdx S₀ q < N) (b : Bool) :
    simM M₀ S₀ q₀ l N ⟨l.length + 1 + 2 * qIdx S₀ q, hiN⟩ b =
      match M₀ q b with
        | none => ⟨b, .R, none⟩
        | some (q', .move .left) => ⟨b, .L, fidx (l.length + 1 + 2 * qIdx S₀ q')⟩
        | some (q', .move .right) => ⟨b, .R, fidx (l.length + 1 + 2 * qIdx S₀ q')⟩
        | some (q', .write a) => ⟨a, .R, fidx (l.length + 1 + 2 * qIdx S₀ q' + 1)⟩ := by
  have h1 : ¬ (l.length + 1 + 2 * qIdx S₀ q < l.length) := by omega
  have h2 : ¬ (l.length + 1 + 2 * qIdx S₀ q = l.length) := by omega
  have h3 : (l.length + 1 + 2 * qIdx S₀ q - (l.length + 1)) = 2 * qIdx S₀ q := by omega
  have h4 : ¬ ((2 * qIdx S₀ q) % 2 = 1) := by omega
  have h5 : (2 * qIdx S₀ q) / 2 = qIdx S₀ q := by omega
  simp only [simM, h1, h2, h3, h4, h5, if_false, qDec_qIdx q₀ hq]

/-- The tape while the list is being written. -/
def writerTape (l : List Bool) (i : ℕ) (x : ℤ) : Bool :=
  if -(i : ℤ) < x ∧ x ≤ 0 then l.getI (l.length - 1 - (-x).toNat) else false

lemma writer_run (hN : l.length < N) :
    ∀ i ≤ l.length, (run (simM M₀ S₀ q₀ l N) i).state = fidx i ∧
      (run (simM M₀ S₀ q₀ l N) i).head = -(i : ℤ) ∧
      ∀ x, (run (simM M₀ S₀ q₀ l N) i).tape x = writerTape l i x := by
  intro i hi
  induction i with
  | zero =>
    refine ⟨?_, rfl, fun x => ?_⟩
    · show (start N).state = _
      have : 0 < N := by omega
      simp [start, this, fidx]
    · show false = _
      simp only [writerTape]
      split_ifs with h
      · omega
      · rfl
  | succ i ih =>
    obtain ⟨hs, hh, ht⟩ := ih (by omega)
    have hiN : i < N := by omega
    rw [fidx_of_lt hiN] at hs
    rw [run_succ', step_some _ _ hs, simM_writer M₀ S₀ q₀ l N (by omega) hiN]
    refine ⟨rfl, ?_, fun x => ?_⟩
    · simp only [hh, Move.delta]; push_cast; omega
    · simp only
      rw [hh]
      by_cases hx : x = -(i : ℤ)
      · subst hx
        simp only [Function.update_self, writerTape]
        rw [if_pos (by constructor <;> push_cast <;> omega)]
        congr 2
        simp
      · rw [Function.update_of_ne hx, ht, writerTape, writerTape]
        have : (-(i : ℤ) < x ∧ x ≤ 0) ↔ (-((i + 1 : ℕ) : ℤ) < x ∧ x ≤ 0) := by
          constructor <;> intro h <;> constructor <;> push_cast at * <;> omega
        simp only [this]

lemma writer_done (hN : l.length + 1 + 2 * S₀.card ≤ N) (hq₀ : q₀ ∈ S₀) (T₀ : Turing.Tape Bool)
    (hT₀ : ∀ j : ℤ, T₀.nth j = if 0 ≤ j then l.getI j.toNat else false) :
    SimRel S₀ (l.length + 1) (run (simM M₀ S₀ q₀ l N) (l.length + 1)) ⟨q₀, T₀⟩ := by
  obtain ⟨hs, hh, ht⟩ := writer_run M₀ S₀ q₀ l N (by omega) l.length le_rfl
  have hiN : l.length < N := by omega
  rw [fidx_of_lt hiN] at hs
  rw [run_succ', step_some _ _ hs, simM_ret M₀ S₀ q₀ l N hiN]
  refine ⟨hq₀, rfl, fun j => ?_⟩
  simp only [Function.update_eq_self]
  simp only [Move.delta]
  rw [hh, ht, hT₀, writerTape]
  by_cases hj : 0 ≤ j
  · by_cases hj2 : j < l.length
    · rw [if_pos (show _ ∧ _ by omega), if_pos hj]; congr 1; omega
    · rw [if_neg (show ¬ (_ ∧ _) by omega), if_pos hj, List.getI_eq_default _ (by omega)]; rfl
  · rw [if_neg (show ¬ (_ ∧ _) by omega), if_neg hj]

lemma sim_step (hN : l.length + 1 + 2 * S₀.card ≤ N)
    (hcl : ∀ {q a q' s}, (q', s) ∈ M₀ q a → q ∈ S₀ → q' ∈ S₀)
    {c : Config N} {d d' : Turing.TM0.Cfg Bool Λ₀} (hr : SimRel S₀ (l.length + 1) c d)
    (hd : d' ∈ Turing.TM0.step M₀ d) :
    ∃ k, SimRel S₀ (l.length + 1) ((step (simM M₀ S₀ q₀ l N))^[k] c) d' := by
  obtain ⟨hq, hs, ht⟩ := hr
  have hlt := qIdx_lt hq
  have hiN : l.length + 1 + 2 * qIdx S₀ d.q < N := by omega
  rw [fidx_of_lt hiN] at hs
  have hhead : c.tape c.head = d.Tape.head := by simpa using ht 0
  obtain ⟨q, T⟩ := d
  simp only [Turing.TM0.step] at hd
  simp only at hq hs ht hhead hiN hlt
  rcases e : M₀ q T.head with _ | ⟨q', s⟩
  · rw [e] at hd; simp at hd
  rw [e] at hd
  simp only [Option.map_some, Option.mem_def, Option.some.injEq] at hd
  subst hd
  have hq' : q' ∈ S₀ := hcl (by rw [e]; rfl) hq
  have hlt' := qIdx_lt hq'
  have hiN' : l.length + 1 + 2 * qIdx S₀ q' < N := by omega
  rcases s with (_ | _) | a
  · refine ⟨1, hq', ?_, ?_⟩
    · simp only [Function.iterate_one, step_some _ _ hs, simM_main M₀ S₀ q₀ l N hq hiN, hhead, e]
    · intro j
      simp only [Function.iterate_one, step_some _ _ hs, simM_main M₀ S₀ q₀ l N hq hiN, hhead, e,
        Move.delta, Turing.Tape.move_left_nth]
      rw [← hhead, Function.update_eq_self, ← ht]
      congr 1; omega
  · refine ⟨1, hq', ?_, ?_⟩
    · simp only [Function.iterate_one, step_some _ _ hs, simM_main M₀ S₀ q₀ l N hq hiN, hhead, e]
    · intro j
      simp only [Function.iterate_one, step_some _ _ hs, simM_main M₀ S₀ q₀ l N hq hiN, hhead, e,
        Move.delta, Turing.Tape.move_right_nth]
      rw [← hhead, Function.update_eq_self, ← ht]
      congr 1; omega
  · have hiA : l.length + 1 + 2 * qIdx S₀ q' + 1 < N := by omega
    have h1 : step (simM M₀ S₀ q₀ l N) c =
        ⟨some ⟨_, hiA⟩, c.head + 1, Function.update c.tape c.head a⟩ := by
      rw [step_some _ _ hs, simM_main M₀ S₀ q₀ l N hq hiN, hhead, e]
      simp [fidx_of_lt hiA, Move.delta]
    have h2 := step_some (simM M₀ S₀ q₀ l N)
      ⟨some ⟨_, hiA⟩, c.head + 1, Function.update c.tape c.head a⟩ (q := ⟨_, hiA⟩) rfl
    rw [simM_aux M₀ S₀ q₀ l N hq' hiA] at h2
    have h12 : (step (simM M₀ S₀ q₀ l N))^[2] c = step (simM M₀ S₀ q₀ l N)
        ⟨some ⟨_, hiA⟩, c.head + 1, Function.update c.tape c.head a⟩ := by
      rw [Function.iterate_succ_apply', Function.iterate_one, h1]
    refine ⟨2, hq', ?_, ?_⟩
    · rw [h12, h2]
    · intro j
      rw [h12, h2]
      simp only [Function.update_eq_self, Move.delta, Turing.Tape.write_nth]
      have : c.head + 1 + -1 + j = c.head + j := by omega
      rw [this]
      by_cases hj : j = 0
      · subst hj; simp
      · rw [if_neg hj, Function.update_of_ne (by omega), ht]

lemma sim_halt (hN : l.length + 1 + 2 * S₀.card ≤ N)
    {c : Config N} {d : Turing.TM0.Cfg Bool Λ₀} (hr : SimRel S₀ (l.length + 1) c d)
    (hd : Turing.TM0.step M₀ d = none) :
    (step (simM M₀ S₀ q₀ l N) c).state = none ∧
      ∀ j : ℤ, (step (simM M₀ S₀ q₀ l N) c).tape (c.head + j) = d.Tape.nth j := by
  obtain ⟨hq, hs, ht⟩ := hr
  have hlt := qIdx_lt hq
  have hiN : l.length + 1 + 2 * qIdx S₀ d.q < N := by omega
  rw [fidx_of_lt hiN] at hs
  have hhead : c.tape c.head = d.Tape.head := by simpa using ht 0
  obtain ⟨q, T⟩ := d
  simp only [Turing.TM0.step] at hd
  simp only at hq hs ht hhead hiN hlt
  have e : M₀ q T.head = none := by
    rcases e : M₀ q T.head with _ | _
    · rfl
    · rw [e] at hd; simp at hd
  rw [step_some _ _ hs, simM_main M₀ S₀ q₀ l N hq hiN, hhead, e]
  refine ⟨rfl, fun j => ?_⟩
  simp only
  rw [← hhead, Function.update_eq_self, ht]

lemma sim_reaches (hN : l.length + 1 + 2 * S₀.card ≤ N)
    (hcl : ∀ {q a q' s}, (q', s) ∈ M₀ q a → q ∈ S₀ → q' ∈ S₀)
    {d₀ d : Turing.TM0.Cfg Bool Λ₀}
    (hR : Relation.ReflTransGen (fun a b => b ∈ Turing.TM0.step M₀ a) d₀ d)
    {k₀ : ℕ} (h₀ : SimRel S₀ (l.length + 1) (run (simM M₀ S₀ q₀ l N) k₀) d₀) :
    ∃ k, SimRel S₀ (l.length + 1) (run (simM M₀ S₀ q₀ l N) k) d := by
  induction hR with
  | refl => exact ⟨k₀, h₀⟩
  | tail _ hbc ih =>
    obtain ⟨k, hk⟩ := ih
    obtain ⟨j, hj⟩ := sim_step M₀ S₀ q₀ l N hN hcl hk hbc
    refine ⟨j + k, ?_⟩
    rw [run, Function.iterate_add_apply]
    exact hj

end Sim

/-! Facts about Mathlib's machine translations. -/

instance instFintypeK' : Fintype Turing.PartrecToTM2.K' :=
  ⟨{.main, .rev, .aux, .stack}, fun k => by cases k <;> simp⟩

lemma length_trPosNum (p : PosNum) : (Turing.PartrecToTM2.trPosNum p).length = p.natSize := by
  induction p with
  | one => rfl
  | bit0 p ih => simp [Turing.PartrecToTM2.trPosNum, PosNum.natSize, ih]
  | bit1 p ih => simp [Turing.PartrecToTM2.trPosNum, PosNum.natSize, ih]

lemma length_trNat (m : ℕ) : (Turing.PartrecToTM2.trNat m).length = Nat.size m := by
  have h : ∀ k : Num, (Turing.PartrecToTM2.trNum k).length = k.natSize := by
    intro k
    cases k with
    | zero => rfl
    | pos p => exact length_trPosNum p
  rw [Turing.PartrecToTM2.trNat, h, Num.natSize_to_nat, Num.to_of_nat]

lemma getI_flatMap {α : Type} [Inhabited α] {n : ℕ} (g : α → List Bool)
    (hg : ∀ a, (g a).length = n) (hd : g default = List.replicate n false) :
    ∀ (ys : List α) (i r : ℕ), r < n →
      (ys.flatMap g).getI (n * i + r) = (g (ys.getI i)).getI r := by
  intro ys
  induction ys with
  | nil =>
    intro i r _
    simp only [List.flatMap_nil, List.getI_nil, hd]
    rw [List.getI_eq_getElem _ (by simpa)]
    simp
  | cons y ys ih =>
    intro i r hr
    rw [List.flatMap_cons]
    cases i with
    | zero =>
      simp only [Nat.mul_zero, Nat.zero_add, List.getI_cons_zero]
      rw [List.getI_append _ _ _ (by rw [hg]; exact hr)]
    | succ i =>
      rw [List.getI_cons_succ, List.getI_append_right _ _ _ (by rw [hg, Nat.mul_succ]; omega), hg]
      rw [show n * (i + 1) + r - n = n * i + r by rw [Nat.mul_succ]; omega]
      exact ih i r hr

lemma listBlank_nth_flatMap {α : Type} [Inhabited α] {n : ℕ} (g : α → List Bool)
    (hg : ∀ a, (g a).length = n) (hd : g default = List.replicate n false) (hf)
    (A : Turing.ListBlank α) (i r : ℕ) (hr : r < n) :
    (A.flatMap g hf).nth (n * i + r) = (g (A.nth i)).getI r := by
  induction A using Turing.ListBlank.induction_on with
  | _ ys =>
    rw [Turing.ListBlank.flatMap_mk, Turing.ListBlank.nth_mk, Turing.ListBlank.nth_mk]
    exact getI_flatMap g hg hd ys i r hr

lemma exists_true_of_ne {G : Type} [Inhabited G] {n : ℕ} (enc : G → List.Vector Bool n)
    (dec : List.Vector Bool n → G) (enc0 : enc default = List.Vector.replicate n false)
    (encdec : ∀ a, dec (enc a) = a) (a : G) (ha : a ≠ default) :
    ∃ r < n, (enc a).toList.getI r = true := by
  by_contra hne0
  have hne : ∀ r < n, (enc a).toList.getI r ≠ true := fun r hr h => hne0 ⟨r, hr, h⟩
  apply ha
  have : enc a = enc default := by
    rw [enc0]
    apply List.Vector.toList_injective
    show _ = List.replicate n false
    apply List.ext_getElem
    · simp
    · intro r h1 h2
      have h1' : r < n := by simpa using h1
      have := hne r h1'
      rw [List.getI_eq_getElem _ h1] at this
      simpa using this
  rw [← encdec a, this, encdec]

lemma length_flatMap_const {α : Type} {n : ℕ} (g : α → List Bool) (hg : ∀ a, (g a).length = n)
    (ys : List α) : (ys.flatMap g).length = ys.length * n := by
  induction ys with
  | nil => simp
  | cons y ys ih => rw [List.flatMap_cons, List.length_append, ih, hg, List.length_cons, Nat.add_mul, Nat.one_mul,
    Nat.add_comm]

lemma tape_nth_mk (lst : List Bool) (j : ℤ) :
    (Turing.Tape.mk' (Turing.ListBlank.mk []) (Turing.ListBlank.mk lst)).nth j =
      if 0 ≤ j then lst.getI j.toNat else false := by
  rcases j with p | p
  · have : (Int.ofNat p) = (p : ℤ) := rfl
    rw [this, Turing.Tape.mk'_nth_nat, Turing.ListBlank.nth_mk, if_pos (by omega)]
    simp
  · rw [if_neg (by omega)]
    show (Turing.ListBlank.mk []).nth p = false
    rw [Turing.ListBlank.nth_mk]
    rfl

lemma stack_proj (xs : List Turing.PartrecToTM2.Γ') (k : Turing.PartrecToTM2.K') :
    (Turing.ListBlank.mk (xs.reverse.map fun a =>
        (Function.update (fun _ => none) Turing.PartrecToTM2.K'.main (some a) :
          Turing.PartrecToTM2.K' → Option Turing.PartrecToTM2.Γ'))).map (Turing.proj k) =
      Turing.ListBlank.mk ((Turing.PartrecToTM2.K'.elim xs [] [] [] k).map some).reverse := by
  apply Turing.ListBlank.ext
  intro i
  rw [Turing.ListBlank.nth_map, Turing.ListBlank.nth_mk, Turing.ListBlank.nth_mk]
  rw [List.getI_eq_getElem?_getD, List.getI_eq_getElem?_getD, List.getElem?_map, ← List.map_reverse,
    List.getElem?_map]
  cases k <;> simp only [Turing.PartrecToTM2.K'.elim] <;> cases xs.reverse[i]? <;> rfl


open Turing in
/-- Every program of Mathlib's `ToPartrec` language becomes, input by input, one of this file's
machines; a machine with `N` states, `N` large against the input's binary length, halts after
writing at least as many 1s as the output has binary digits. -/
lemma chain (c : ToPartrec.Code) : ∃ a b : ℕ, ∀ m x : ℕ, c.eval [m] = pure [x] →
    ∀ N, a * Nat.size m + b ≤ N → Nat.size x + 1 ≤ BB N := by
  classical
  letI : Inhabited PartrecToTM2.Λ' := ⟨PartrecToTM2.trNormal c PartrecToTM2.Cont'.halt⟩
  obtain ⟨n, enc, dec, enc0, encdec⟩ :=
    TM1to1.exists_enc_dec (Γ := TM2to1.Γ' PartrecToTM2.K' (fun _ => PartrecToTM2.Γ'))
  let M1 := TM2to1.tr (K := PartrecToTM2.K') (Γ := fun _ => PartrecToTM2.Γ') PartrecToTM2.tr
  let M2 := TM1to1.tr enc dec M1
  let M0 := TM1to0.tr M2
  let S0 := TM1to0.trStmts M2
    (TM1to1.trSupp M1 (TM2to1.trSupp PartrecToTM2.tr (PartrecToTM2.codeSupp c .halt)))
  have hs0 : TM0.Supports M0 ↑S0 := TM1to0.tr_supports M2 (TM1to1.tr_supports enc dec M1
    (TM2to1.tr_supports PartrecToTM2.tr (PartrecToTM2.tr_supports c .halt)))
  refine ⟨n, n + 1 + 2 * S0.card, ?_⟩
  intro m x hx N hN
  have h2 : PartrecToTM2.halt [x] ∈
      StateTransition.eval (TM2.step PartrecToTM2.tr) (PartrecToTM2.init c [m]) := by
    rw [PartrecToTM2.tr_eval, hx]
    exact Part.mem_map _ (Part.mem_some _)
  let xsL := (PartrecToTM2.trList [m]).reverse.map fun a =>
    (Function.update (fun _ => none) PartrecToTM2.K'.main (some a) :
      PartrecToTM2.K' → Option PartrecToTM2.Γ')
  let b1 : TM1.Cfg (TM2to1.Γ' PartrecToTM2.K' (fun _ => PartrecToTM2.Γ'))
      (TM2to1.Λ' PartrecToTM2.K' (fun _ => PartrecToTM2.Γ') PartrecToTM2.Λ'
        (Option PartrecToTM2.Γ')) (Option PartrecToTM2.Γ') :=
    ⟨some (TM2to1.Λ'.normal (PartrecToTM2.trNormal c .halt)), none,
      Tape.mk' ∅ (TM2to1.addBottom (ListBlank.mk xsL))⟩
  have hTr : TM2to1.TrCfg (PartrecToTM2.init c [m]) b1 :=
    TM2to1.TrCfg.mk _ (stack_proj _)
  obtain ⟨b2, hb2, hb2e⟩ := StateTransition.tr_eval (TM2to1.tr_respects PartrecToTM2.tr) hTr h2
  obtain ⟨L', rfl, hL'⟩ : ∃ L', b2 = ⟨none, none, Tape.mk' ∅ (TM2to1.addBottom L')⟩ ∧
      ∀ k, L'.map (proj k) =
        ListBlank.mk ((PartrecToTM2.K'.elim (PartrecToTM2.trList [x]) [] [] [] k).map some).reverse := by
    unfold PartrecToTM2.halt at hb2
    cases hb2 with
    | mk L hL => exact ⟨L, rfl, hL⟩
  obtain ⟨b3, hb3, hb3e⟩ :=
    StateTransition.tr_eval (TM1to1.tr_respects dec M1 (enc0 := enc0) encdec) rfl hb2e
  obtain ⟨b4, hb4, hb4e⟩ := StateTransition.tr_eval (TM1to0.tr_respects M2) rfl hb3e
  rw [StateTransition.mem_eval] at hb4e
  obtain ⟨hreach, hhalt⟩ := hb4e
  subst hb3 hb4
  -- the starting tape, as a list
  let ys : List (TM2to1.Γ' PartrecToTM2.K' (fun _ => PartrecToTM2.Γ')) :=
    (true, xsL.headI) :: xsL.tail.map (Prod.mk false)
  have hAB : TM2to1.addBottom (ListBlank.mk xsL) = ListBlank.mk ys := by
    simp only [TM2to1.addBottom, ListBlank.head_mk, ListBlank.tail_mk, ListBlank.map_mk, ys]
    rfl
  let g := fun a : TM2to1.Γ' PartrecToTM2.K' (fun _ => PartrecToTM2.Γ') => (enc a).toList
  have hg : ∀ a, (g a).length = n := fun a => (enc a).2
  let lst := ys.flatMap g
  let d0 := TM1to0.trCfg M2 (TM1to1.trCfg enc enc0 b1)
  have hd0T : d0.Tape = Tape.mk' (ListBlank.mk []) (ListBlank.mk lst) := by
    show TM1to1.trTape enc0 (Tape.mk' ∅ (TM2to1.addBottom (ListBlank.mk xsL))) = _
    rw [TM1to1.trTape_mk', hAB]
    rfl
  have hT0 : ∀ j : ℤ, d0.Tape.nth j = if 0 ≤ j then lst.getI j.toNat else false := by
    intro j; rw [hd0T]; exact tape_nth_mk lst j
  have hq0 : d0.q ∈ S0 := hs0.1
  have hxsL : xsL.length = Nat.size m + 1 := by
    simp [xsL, length_trNat]
  have hys : ys.length = Nat.size m + 1 := by
    show ((true, xsL.headI) :: xsL.tail.map (Prod.mk false)).length = _
    rw [List.length_cons, List.length_map, List.length_tail, hxsL]
    omega
  have hlst : lst.length = n * Nat.size m + n := by
    rw [length_flatMap_const g hg, hys, Nat.add_mul, Nat.one_mul, Nat.mul_comm]
  have hN' : lst.length + 1 + 2 * S0.card ≤ N := by omega
  have hwd := writer_done M0 S0 d0.q lst N hN' hq0 d0.Tape hT0
  obtain ⟨k, hk⟩ := sim_reaches M0 S0 d0.q lst N hN' (fun h hq => hs0.2 h hq) hreach hwd
  obtain ⟨hst, htape⟩ := sim_halt M0 S0 d0.q lst N hN' hk hhalt
  -- the final tape holds a 1 in each block of the output
  have hd : g default = List.replicate n false := by
    show (enc default).toList = _
    rw [enc0]; rfl
  have hT4 : ∀ i r, r < n →
      (TM1to0.trCfg M2 (TM1to1.trCfg enc enc0
        ⟨none, none, Tape.mk' ∅ (TM2to1.addBottom L')⟩)).Tape.nth ((n * i + r : ℕ) : ℤ) =
        (g ((TM2to1.addBottom L').nth i)).getI r := by
    intro i r hr
    show (TM1to1.trTape enc0 (Tape.mk' ∅ (TM2to1.addBottom L'))).nth _ = _
    rw [TM1to1.trTape_mk', TM1to1.trTape', Tape.mk'_nth_nat]
    exact listBlank_nth_flatMap g hg hd _ _ i r hr
  let len := (PartrecToTM2.trList [x]).length
  have hlen : len = Nat.size x + 1 := by simp [len, length_trNat]
  have hcell : ∀ i < len, (TM2to1.addBottom L').nth i ≠ default := by
    intro i hi he
    have h1 := TM2to1.addBottom_nth_snd L' i
    rw [he] at h1
    have hm : L'.map (proj PartrecToTM2.K'.main) =
        ListBlank.mk ((PartrecToTM2.trList [x]).map some).reverse := hL' .main
    have h2 := TM2to1.stk_nth_val (K := PartrecToTM2.K') (Γ := fun _ => PartrecToTM2.Γ') i hm
    have h3 : (PartrecToTM2.trList [x]).reverse[i]? ≠ none := by
      rw [ne_eq, List.getElem?_eq_none_iff, List.length_reverse]
      omega
    apply h3
    rw [← h2, ← h1]
    rfl
  have hex : ∀ i, i < len → ∃ r < n, (g ((TM2to1.addBottom L').nth i)).getI r = true :=
    fun i hi => exists_true_of_ne enc dec enc0 encdec _ (hcell i hi)
  let rr : ℕ → ℕ := fun i => if h : i < len then Classical.choose (hex i h) else 0
  have hrr : ∀ i < len, rr i < n ∧ (g ((TM2to1.addBottom L').nth i)).getI (rr i) = true := by
    intro i hi
    simp only [rr, hi, dite_true]
    exact Classical.choose_spec (hex i hi)
  let h0 := (run (simM M0 S0 d0.q lst N) k).head
  let F : Finset ℤ := (Finset.range len).image (fun i => h0 + ((n * i + rr i : ℕ) : ℤ))
  have hinj : Set.InjOn (fun i => h0 + ((n * i + rr i : ℕ) : ℤ)) ↑(Finset.range len) := by
    intro i hi i' hi' he
    simp only [Finset.coe_range, Set.mem_Iio] at hi hi'
    have he1 : ((n * i + rr i : ℕ) : ℤ) = ((n * i' + rr i' : ℕ) : ℤ) := add_left_cancel he
    have he' : n * i + rr i = n * i' + rr i' := by exact_mod_cast he1
    have hn : 0 < n := by have := (hrr i hi).1; omega
    have := congrArg (· / n) he'
    simp only [Nat.mul_add_div hn, Nat.div_eq_of_lt (hrr i hi).1,
      Nat.div_eq_of_lt (hrr i' hi').1] at this
    simpa using this
  have hFcard : F.card = len := by rw [Finset.card_image_of_injOn hinj, Finset.card_range]
  have hFtrue : ∀ z ∈ F, (run (simM M0 S0 d0.q lst N) (k + 1)).tape z = true := by
    intro z hz
    obtain ⟨i, hi, rfl⟩ := Finset.mem_image.1 hz
    rw [Finset.mem_range] at hi
    rw [run_succ', htape, hT4 i (rr i) (hrr i hi).1]
    exact (hrr i hi).2
  have hle := card_le_bb (simM M0 S0 d0.q lst N) (s := k + 1) (by rw [run_succ']; exact hst) F
    hFtrue
  omega


lemma sq_le_two_pow {k : ℕ} (hk : 4 ≤ k) : k * k ≤ 2 ^ k := by
  induction k, hk using Nat.le_induction with
  | base => decide
  | succ k hk ih =>
    have h1 : 4 * k ≤ k * k := Nat.mul_le_mul_right k hk
    have h2 : (k + 1) * (k + 1) = k * k + 2 * k + 1 := by
      rw [Nat.add_mul, Nat.mul_add, Nat.mul_add, Nat.one_mul, Nat.mul_one, Nat.one_mul]
      omega
    rw [h2, Nat.pow_succ]
    omega

lemma eventually_le (a b : ℕ) : ∃ N₀, ∀ N ≥ N₀, a * Nat.size N + b ≤ N := by
  refine ⟨2 ^ (2 * a + 2 * b + 4), fun N hN => ?_⟩
  have hs : 2 * a + 2 * b + 4 < Nat.size N := Nat.lt_size.2 hN
  obtain ⟨t, ht⟩ : ∃ t, Nat.size N = t + 1 := ⟨Nat.size N - 1, by omega⟩
  have hpow : 2 ^ t ≤ N := Nat.lt_size.1 (by omega)
  have htt : t * t ≤ 2 ^ t := sq_le_two_pow (by omega)
  have hK : (2 * a + 2 * b + 4) * t ≤ t * t := Nat.mul_le_mul_right t (by omega)
  have hexp : (2 * a + 2 * b + 4) * t = 2 * (a * t) + 2 * (b * t) + 4 * t := by
    rw [Nat.add_mul, Nat.add_mul, Nat.mul_assoc, Nat.mul_assoc]
  have ha : a ≤ a * t := Nat.le_mul_of_pos_right a (by omega)
  have hb : b ≤ b * t := Nat.le_mul_of_pos_right b (by omega)
  rw [ht, Nat.mul_add, Nat.mul_one]
  omega

#print axioms run_zero'
#print axioms run_succ'
#print axioms step_of_none
#print axioms run_stays
#print axioms exists_haltsAt_le
#print axioms haltsAt_unique
#print axioms bb_bddAbove
#print axioms le_bb
#print axioms run_support
#print axioms card_le_bb
#print axioms fidx_of_lt
#print axioms qIdx_lt
#print axioms qDec_qIdx
#print axioms step_some
#print axioms simM_writer
#print axioms simM_ret
#print axioms simM_aux
#print axioms simM_main
#print axioms writer_run
#print axioms writer_done
#print axioms sim_step
#print axioms sim_halt
#print axioms sim_reaches
#print axioms length_trPosNum
#print axioms length_trNat
#print axioms getI_flatMap
#print axioms listBlank_nth_flatMap
#print axioms exists_true_of_ne
#print axioms length_flatMap_const
#print axioms tape_nth_mk
#print axioms stack_proj
#print axioms chain
#print axioms sq_le_two_pow
#print axioms eventually_le

/-- **BB outgrows every computable function** (Radó, 1962). For every function `f` that a program
computes, there is an `N₀` with `BB(N) > f(N)` for every `N ≥ N₀`. -/
theorem busy_beaver_eventually_exceeds_every_computable_function (f : ℕ → ℕ)
    (hf : Computable f) : ∃ N₀, ∀ N ≥ N₀, f N < BB N := by
  have hpow : Computable (fun m => 2 ^ f m) :=
    ((Primrec.nat_iff.2 Nat.Primrec.pow).to_comp.comp
      (Primrec₂.natPair.to_comp.comp (Computable.const 2) hf)).of_eq
      (fun m => by simp [Nat.unpaired, Nat.unpair_pair])
  have hp : Nat.Partrec' (fun v : List.Vector ℕ 1 =>
      ((fun m => Part.some (2 ^ f m)) : ℕ →. ℕ) v.head) :=
    Nat.Partrec'.part_iff₁.2 hpow.partrec
  obtain ⟨c, hc⟩ := Turing.ToPartrec.Code.exists_code hp
  obtain ⟨a, b, hab⟩ := chain c
  obtain ⟨N₀, hN₀⟩ := eventually_le a b
  refine ⟨N₀, fun N hN => ?_⟩
  have hev : c.eval [N] = pure [2 ^ f N] := by
    have h1 := hc ⟨[N], rfl⟩
    have h2 : List.Vector.head (⟨[N], rfl⟩ : List.Vector ℕ 1) = N := rfl
    rw [h2] at h1
    simpa using h1
  have := hab N (2 ^ f N) hev N (hN₀ N hN)
  rw [Nat.size_pow] at this
  omega

/-- **No program computes BB.** There is no computable function giving `BB(n)` for every `n`. -/
theorem busy_beaver_not_computable : ¬ Computable BB := by
  intro h
  obtain ⟨N₀, hN₀⟩ := busy_beaver_eventually_exceeds_every_computable_function BB h
  exact lt_irrefl _ (hN₀ N₀ le_rfl)

/-- **One number answers every halting question at its size.** An `n`-state machine started on
a blank tape halts at some step if and only if it has halted within `BB(n)` steps. So `BB(n)` is
the largest halting run, and running a machine for `BB(n)` steps is a halting test. -/
theorem halts_iff_halted_within_busy_beaver {n : ℕ} (M : Machine n) :
    (∃ s, HaltsAt M s) ↔ (run M (BB n)).state = none := by
  constructor
  · rintro ⟨s, hs⟩
    rw [run_stays M hs.1 _ (le_bb M hs)]
    exact hs.1
  · intro h
    obtain ⟨s, _, hs⟩ := exists_haltsAt_le M h
    exact ⟨s, hs⟩

/-! The card's own whole-number worked examples. -/

/-- A rule written as on the card, such as `1RB`: symbol written, move, next state. -/
def r {n : ℕ} (w : ℕ) (m : Move) (q : Option (Fin n)) : Rule n := ⟨w = 1, m, q⟩

/-- The number of 1s on the cells `-k` to `k`. After `k` steps from cell 0 the head has visited
no cell outside them, so this is every 1 on the tape. -/
def onesWithin {n : ℕ} (c : Config n) (k : ℕ) : ℕ :=
  ((Finset.Icc (-(k : ℤ)) k).filter (fun i => c.tape i = true)).card

/-- The one-state champion `1RZ1RZ`: it halts at once. -/
def bb1 : Machine 1 := fun _ _ => r 1 .R none

/-- The two-state champion `1RB1LB_1LA1RZ`. -/
def bb2 : Machine 2 := ![fun b : Bool => if b then r 1 .L (some 1) else r 1 .R (some 1),
                         fun b : Bool => if b then r 1 .R none else r 1 .L (some 0)]

/-- The three-state champion `1RB1RZ_1LB0RC_1LC1LA`. -/
def bb3 : Machine 3 := ![fun b : Bool => if b then r 1 .R none else r 1 .R (some 1),
                         fun b : Bool => if b then r 0 .R (some 2) else r 1 .L (some 1),
                         fun b : Bool => if b then r 1 .L (some 0) else r 1 .L (some 2)]

/-- The four-state champion `1RB1LB_1LA0LC_1RZ1LD_1RD0RA`. -/
def bb4 : Machine 4 := ![fun b : Bool => if b then r 1 .L (some 1) else r 1 .R (some 1),
                         fun b : Bool => if b then r 0 .L (some 2) else r 1 .L (some 0),
                         fun b : Bool => if b then r 1 .L (some 3) else r 1 .R none,
                         fun b : Bool => if b then r 0 .R (some 0) else r 1 .R (some 3)]

/-- The never-halting `1RA1RA`. -/
def loop1 : Machine 1 := fun _ _ => r 1 .R (some 0)

-- Choices for one rule, 1 to 5 states: 2 × 2 × (n + 1) = 8, 12, 16, 20, 24.
example : [1, 2, 3, 4, 5].map (fun n => 2 * 2 * (n + 1)) = [8, 12, 16, 20, 24] := by decide

-- Machines with 1 to 5 states, (4(n + 1))^(2n): 64, 20,736, 16,777,216, 25,600,000,000 and
-- 63,403,380,965,376.
example : [1, 2, 3, 4, 5].map (fun n => (4 * (n + 1)) ^ (2 * n)) =
    [64, 20736, 16777216, 25600000000, 63403380965376] := by norm_num

-- The count is exactly the number of rule tables in the definition, for one and two states.
example : Fintype.card (Rule 1) = 8 ∧ Fintype.card (Rule 2) = 12 := by decide
example : Fintype.card (Machine 1) = 64 ∧ Fintype.card (Machine 2) = 20736 := by
  simp only [Fintype.card_fun, Fintype.card_fin, Fintype.card_bool]; decide

-- Two-state tallies: 430 + 10,510 + 12 = 10,952 proved never to halt, and with the 9,784 that halt
-- every one of the 20,736 machines is settled.
example : 430 + 10510 + 12 = 10952 ∧ 9784 + 10952 = 20736 := by norm_num

-- BB(1) = 1: the one-state champion halts at step 1, leaving one 1.
example : HaltsAt bb1 1 ∧ onesWithin (run bb1 1) 1 = 1 := by decide

-- BB(2) = 6: the two-state champion halts at step 6, the halting step counted, leaving four 1s.
example : HaltsAt bb2 6 ∧ onesWithin (run bb2 6) 6 = 4 := by decide

-- Leaving out the halting step: it had not halted after 5 steps.
example : (run bb2 5).state ≠ none := by decide

-- BB(3) = 21: the three-state champion halts at step 21.
example : HaltsAt bb3 21 := by decide +kernel

-- BB(4) = 107: the four-state champion halts at step 107, leaving thirteen 1s.
example : HaltsAt bb4 107 ∧ onesWithin (run bb4 107) 107 = 13 := by decide +kernel

-- What breaks: a 100-step cap finds the four-state champion still running after 100 steps.
example : (run bb4 100).state ≠ none := by decide +kernel

-- What breaks: `1RA1RA` is still running at a 100-step cap, so letting it in makes "most steps"
-- the cap, 100.
example : (run loop1 100).state ≠ none := by decide +kernel

-- BB(4) = 107 is below 4^4 = 256; BB(5) = 47,176,870 is above 5^5 = 3,125.
example : 107 < 4 ^ 4 ∧ 3125 < 47176870 ∧ 5 ^ 5 = 3125 := by norm_num

#print axioms busy_beaver_eventually_exceeds_every_computable_function
#print axioms busy_beaver_not_computable
#print axioms halts_iff_halted_within_busy_beaver

end BusyBeaver
