-- Pumping and Myhill-Nerode: a language is regular exactly when its strings fall into finitely many classes by their futures, the smallest complete machine has exactly that many states, every regular language pumps, and matched brackets need unbounded memory while a depth cap d needs exactly d + 2 states.
import Mathlib.Computability.MyhillNerode
import Mathlib.SetTheory.Cardinal.Finite

universe u v

/-- `x ≡_L y`: no ending tells `x` and `y` apart, that is, for every ending `z`,
`x ++ z` is in `L` exactly when `y ++ z` is. It is an equivalence relation. -/
def nerode {α : Type u} (L : Language α) : Setoid (List α) where
  r x y := ∀ z : List α, (x ++ z ∈ L ↔ y ++ z ∈ L)
  iseqv := ⟨fun _ _ => Iff.rfl, fun h z => (h z).symm, fun h₁ h₂ z => (h₁ z).trans (h₂ z)⟩

/-- Two strings that lead a machine to the same state have the same futures. -/
theorem futures_eq_of_eval_eq {α : Type u} {σ : Type v} (M : DFA α σ) {x y : List α}
    (h : M.eval x = M.eval y) (z : List α) : x ++ z ∈ M.accepts ↔ y ++ z ∈ M.accepts := by
  have h' : M.evalFrom M.start x = M.evalFrom M.start y := h
  show M.evalFrom M.start (x ++ z) ∈ M.accept ↔ M.evalFrom M.start (y ++ z) ∈ M.accept
  rw [DFA.evalFrom_of_append, DFA.evalFrom_of_append, h']

#print axioms futures_eq_of_eval_eq

/-- Sending each class to the state its chosen string reaches is one to one. -/
theorem nerode_class_state_injective {α : Type u} {σ : Type v} (M : DFA α σ) :
    Function.Injective (fun q : Quotient (nerode M.accepts) => M.eval q.out) := by
  intro p q h
  rw [← Quotient.out_eq p, ← Quotient.out_eq q]
  exact Quotient.sound (futures_eq_of_eval_eq M h)

#print axioms nerode_class_state_injective

/-- The machine whose states are the classes of `≡_L`. -/
def nerodeDFA {α : Type u} (L : Language α) : DFA α (Quotient (nerode L)) where
  step q a := Quotient.lift (fun x => (Quotient.mk _ (x ++ [a]) : Quotient (nerode L)))
    (fun x y h => Quotient.sound (fun z => by
      simpa only [List.append_assoc, List.singleton_append] using h (a :: z))) q
  start := Quotient.mk _ []
  accept := {q | Quotient.lift (fun x => x ∈ L)
    (fun x y h => propext (by simpa only [List.append_nil] using h [])) q}

theorem nerodeDFA_eval {α : Type u} (L : Language α) (x : List α) :
    (nerodeDFA L).eval x = Quotient.mk _ x := by
  induction x using List.reverseRecOn with
  | nil => rfl
  | append_singleton x a ih => rw [DFA.eval_append_singleton, ih]; rfl

#print axioms nerodeDFA_eval

theorem nerodeDFA_accepts {α : Type u} (L : Language α) : (nerodeDFA L).accepts = L := by
  ext x
  rw [DFA.mem_accepts, nerodeDFA_eval]
  rfl

#print axioms nerodeDFA_accepts

/-- **Myhill-Nerode, with the state count.** A language is regular exactly when `≡_L` has
finitely many classes. Then, with `N` the number of classes, every deterministic, complete
machine (one next state for every state and letter) that accepts `L` has at least `N` states,
and some such machine has exactly `N` states. -/
theorem myhill_nerode_classes_are_the_fewest_states {α : Type u} (L : Language α) :
    (L.IsRegular ↔ Finite (Quotient (nerode L))) ∧
      (L.IsRegular →
        (∀ (σ : Type v) [Fintype σ] (M : DFA α σ), M.accepts = L →
            Nat.card (Quotient (nerode L)) ≤ Fintype.card σ) ∧
          ∃ (σ : Type v) (_ : Fintype σ) (M : DFA α σ),
            M.accepts = L ∧ Fintype.card σ = Nat.card (Quotient (nerode L))) := by
  have hfin : L.IsRegular → Finite (Quotient (nerode L)) := by
    intro hL
    obtain ⟨σ, _, M, hM⟩ := hL
    subst hM
    exact Finite.of_injective _ (nerode_class_state_injective M)
  refine ⟨⟨hfin, fun h => ?_⟩, fun hL => ⟨?_, ?_⟩⟩
  · let _ := Fintype.ofFinite (Quotient (nerode L))
    exact Language.isRegular_iff.mpr ⟨_, inferInstance, nerodeDFA L, nerodeDFA_accepts L⟩
  · intro σ _ M hM
    subst hM
    rw [← Nat.card_eq_fintype_card]
    exact Nat.card_le_card_of_injective _ (nerode_class_state_injective M)
  · have := hfin hL
    let _ := Fintype.ofFinite (Quotient (nerode L))
    let e : Quotient (nerode L) ≃ ULift.{v} (Fin (Fintype.card (Quotient (nerode L)))) :=
      (Fintype.equivFin _).trans Equiv.ulift.symm
    exact ⟨ULift.{v} (Fin (Fintype.card (Quotient (nerode L)))), inferInstance,
      DFA.reindex e (nerodeDFA L), by rw [DFA.accepts_reindex, nerodeDFA_accepts],
      by simp [Nat.card_eq_fintype_card]⟩

/-- A loop read any number of times returns to its state. -/
theorem evalFrom_replicate_loop {α : Type u} {σ : Type v} (M : DFA α σ) {q : σ} {y : List α}
    (h : M.evalFrom q y = q) (i : ℕ) : M.evalFrom q (List.replicate i y).flatten = q := by
  induction i with
  | zero => rfl
  | succ i ih => rw [List.replicate_succ, List.flatten_cons, DFA.evalFrom_of_append, h, ih]

#print axioms evalFrom_replicate_loop

/-- **The pumping lemma.** Every regular language has a pumping length `p`: every string `w`
in the language with `|w| ≥ p` splits as `w = x y z` with `|x y| ≤ p` and `|y| ≥ 1`, so that
`x y^i z` is in the language for every `i ≥ 0` (`y^i` is `i` copies of `y`). -/
theorem regular_language_pumps {α : Type u} (L : Language α) (hL : L.IsRegular) :
    ∃ p : ℕ, ∀ w ∈ L, p ≤ w.length →
      ∃ x y z : List α, w = x ++ y ++ z ∧ (x ++ y).length ≤ p ∧ 1 ≤ y.length ∧
        ∀ i : ℕ, x ++ (List.replicate i y).flatten ++ z ∈ L := by
  obtain ⟨σ, _, M, rfl⟩ := hL
  refine ⟨Fintype.card σ, fun w hw hlen => ?_⟩
  obtain ⟨q, x, y, z, hxyz, hle, hne, hx, hy, hz⟩ := M.evalFrom_split (s := M.start) hlen rfl
  refine ⟨x, y, z, hxyz, by rw [List.length_append]; exact hle, ?_, fun i => ?_⟩
  · cases y with
    | nil => exact absurd rfl hne
    | cons b y => simp
  · rw [DFA.mem_accepts] at hw ⊢
    rw [DFA.eval, DFA.evalFrom_of_append, DFA.evalFrom_of_append, hx,
      evalFrom_replicate_loop M hy, hz]
    exact hw

/-! The bracket checker. The alphabet is the two brackets. -/

/-- The two letters: `op` is `(` and `cl` is `)`. -/
inductive Br
  | op
  | cl
  deriving DecidableEq

open Br

/-- The plain counter with no depth cap: from open count `d`, `(` adds 1 and `)` takes 1 away;
`none` means a `)` came at count 0. The result is the open count at the end. -/
def openCount : ℕ → List Br → Option ℕ
  | d, [] => some d
  | d, op :: w => openCount (d + 1) w
  | 0, cl :: _ => none
  | d + 1, cl :: w => openCount d w

/-- The counter with depth cap `cap`: as `openCount`, but a `(` that would pass the cap
breaks the string (`none`). -/
def cappedCount (cap : ℕ) : ℕ → List Br → Option ℕ
  | d, [] => some d
  | d, op :: w => if d + 1 ≤ cap then cappedCount cap (d + 1) w else none
  | 0, cl :: _ => none
  | d + 1, cl :: w => cappedCount cap d w

/-- Matched brackets, however deep: the count never goes below 0 and ends at 0. -/
def matched : Language Br := {w | openCount 0 w = some 0}

/-- Matched brackets nested at most `cap` deep. -/
def cappedMatched (cap : ℕ) : Language Br := {w | cappedCount cap 0 w = some 0}

theorem openCount_replicate_op (n d : ℕ) (w : List Br) :
    openCount d (List.replicate n op ++ w) = openCount (d + n) w := by
  induction n generalizing d with
  | zero => rfl
  | succ n ih =>
    simp only [List.replicate_succ, List.cons_append, openCount, ih]
    congr 1; omega

#print axioms openCount_replicate_op

theorem openCount_replicate_cl (n d : ℕ) :
    openCount d (List.replicate n cl) = if n ≤ d then some (d - n) else none := by
  induction n generalizing d with
  | zero => simp [openCount]
  | succ n ih =>
    cases d with
    | zero => simp [List.replicate_succ, openCount]
    | succ d => simp [List.replicate_succ, openCount, ih]

#print axioms openCount_replicate_cl

theorem cappedCount_replicate_op (cap n d : ℕ) (w : List Br) (h : d + n ≤ cap) :
    cappedCount cap d (List.replicate n op ++ w) = cappedCount cap (d + n) w := by
  induction n generalizing d with
  | zero => rfl
  | succ n ih =>
    simp only [List.replicate_succ, List.cons_append, cappedCount]
    simp only [show d + 1 ≤ cap by omega, ↓reduceIte]
    rw [ih (d + 1) (by omega)]
    congr 1; omega

#print axioms cappedCount_replicate_op

theorem cappedCount_replicate_cl (cap n d : ℕ) :
    cappedCount cap d (List.replicate n cl) = if n ≤ d then some (d - n) else none := by
  induction n generalizing d with
  | zero => simp [cappedCount]
  | succ n ih =>
    cases d with
    | zero => simp [List.replicate_succ, cappedCount]
    | succ d => simp [List.replicate_succ, cappedCount, ih]

#print axioms cappedCount_replicate_cl

/-- `(^k` followed by `)^j` is matched exactly when `j = k`. -/
theorem openCount_op_cl (j k : ℕ) :
    openCount 0 (List.replicate k op ++ List.replicate j cl) = some 0 ↔ j = k := by
  rw [openCount_replicate_op, Nat.zero_add, openCount_replicate_cl]
  split_ifs with h
  · simp only [Option.some.injEq]; omega
  · simp only [false_iff]; omega

#print axioms openCount_op_cl

/-- With `k ≤ cap`, `(^k` followed by `)^j` passes the capped checker exactly when `j = k`. -/
theorem cappedCount_op_cl (cap j k : ℕ) (hk : k ≤ cap) :
    cappedCount cap 0 (List.replicate k op ++ List.replicate j cl) = some 0 ↔ j = k := by
  rw [cappedCount_replicate_op cap k 0 _ (by omega), Nat.zero_add, cappedCount_replicate_cl]
  split_ifs with h
  · simp only [Option.some.injEq]; omega
  · simp only [false_iff]; omega

#print axioms cappedCount_op_cl

/-- The capped checker as a machine: `some i` is open count `i`, `none` is the dead state. -/
def capStep (d : ℕ) : Option (Fin (d + 1)) → Br → Option (Fin (d + 1))
  | none, _ => none
  | some i, op => if h : i.val + 1 ≤ d then some ⟨i.val + 1, by omega⟩ else none
  | some i, cl => if h : i.val = 0 then none else some ⟨i.val - 1, by omega⟩

def capDFA (d : ℕ) : DFA Br (Option (Fin (d + 1))) where
  step := capStep d
  start := some 0
  accept := {some 0}

theorem capDFA_evalFrom_none (d : ℕ) (w : List Br) : (capDFA d).evalFrom none w = none := by
  induction w with
  | nil => rfl
  | cons a w ih => exact ih

#print axioms capDFA_evalFrom_none

theorem capDFA_evalFrom (d : ℕ) (w : List Br) (i : Fin (d + 1)) :
    ((capDFA d).evalFrom (some i) w).map Fin.val = cappedCount d i.val w := by
  induction w generalizing i with
  | nil => rfl
  | cons a w ih =>
    rw [DFA.evalFrom_cons]
    obtain ⟨k, hk⟩ := i
    cases a with
    | op =>
      by_cases h : k + 1 ≤ d
      · have hs : (capDFA d).step (some ⟨k, hk⟩) op = some ⟨k + 1, by omega⟩ := by
          simp [capDFA, capStep, h]
        rw [hs, ih]
        simp [cappedCount, h]
      · have hs : (capDFA d).step (some ⟨k, hk⟩) op = none := by
          simp [capDFA, capStep, h]
        rw [hs, capDFA_evalFrom_none]
        simp [cappedCount, h]
    | cl =>
      cases k with
      | zero =>
        rw [show (capDFA d).step (some ⟨0, hk⟩) cl = none from rfl, capDFA_evalFrom_none]
        rfl
      | succ k =>
        have hs : (capDFA d).step (some ⟨k + 1, hk⟩) cl = some ⟨k, by omega⟩ := by
          simp [capDFA, capStep]
        rw [hs, ih]
        rfl

#print axioms capDFA_evalFrom

theorem capDFA_accepts (d : ℕ) : (capDFA d).accepts = cappedMatched d := by
  ext w
  show (capDFA d).evalFrom (some 0) w ∈ ({some 0} : Set (Option (Fin (d + 1)))) ↔
    cappedCount d 0 w = some 0
  have h := capDFA_evalFrom d w 0
  simp only [Fin.val_zero] at h
  rw [Set.mem_singleton_iff, ← h]
  cases (capDFA d).evalFrom (some 0) w with
  | none => simp
  | some j =>
    simp only [Option.map_some, Option.some.injEq]
    constructor
    · rintro rfl; simp
    · intro e; exact Fin.ext (by rw [e, Fin.val_zero])

#print axioms capDFA_accepts

/-- The `d + 2` strings `(^0, ..., (^d` and `)`. -/
def capWord (d : ℕ) (j : Fin (d + 2)) : List Br :=
  if j.val ≤ d then List.replicate j.val op else [cl]

theorem capWord_separated (d : ℕ) {j k : Fin (d + 2)}
    (h : ∀ z, capWord d j ++ z ∈ cappedMatched d ↔ capWord d k ++ z ∈ cappedMatched d) :
    j = k := by
  have hdead : ∀ z, ¬ ([cl] ++ z ∈ cappedMatched d) := fun z hz => by
    change cappedCount d 0 (cl :: z) = some 0 at hz
    simp [cappedCount] at hz
  have hmem : ∀ a b : ℕ, a ≤ d →
      (List.replicate a op ++ List.replicate b cl ∈ cappedMatched d ↔ b = a) :=
    fun a b ha => cappedCount_op_cl d b a ha
  have hj := j.isLt
  have hk := k.isLt
  by_cases hjd : j.val ≤ d <;> by_cases hkd : k.val ≤ d
  · have h1 := h (List.replicate j.val cl)
    simp only [capWord, hjd, hkd, ↓reduceIte] at h1
    rw [hmem _ _ hjd, hmem _ _ hkd] at h1
    exact Fin.ext (h1.1 rfl)
  · have h1 := h (List.replicate j.val cl)
    simp only [capWord, hjd, hkd, ↓reduceIte] at h1
    exact absurd (h1.1 ((hmem _ _ hjd).2 rfl)) (hdead _)
  · have h1 := h (List.replicate k.val cl)
    simp only [capWord, hjd, hkd, ↓reduceIte] at h1
    exact absurd (h1.2 ((hmem _ _ hkd).2 rfl)) (hdead _)
  · exact Fin.ext (by omega)

#print axioms capWord_separated

/-- **The bracket checker's two answers.** No finite automaton accepts exactly the matched
bracket strings of every depth. For each depth cap `d`, some deterministic, complete machine
with exactly `d + 2` states accepts the strings matched at most `d` deep, and every such
machine has at least `d + 2` states (5 for the card's cap of 3). -/
theorem brackets_need_unbounded_memory_and_cap_d_needs_d_plus_two_states :
    ¬ matched.IsRegular ∧
      ∀ d : ℕ,
        (∃ (σ : Type) (_ : Fintype σ) (M : DFA Br σ),
            M.accepts = cappedMatched d ∧ Fintype.card σ = d + 2) ∧
          ∀ (σ : Type) [Fintype σ] (M : DFA Br σ),
            M.accepts = cappedMatched d → d + 2 ≤ Fintype.card σ := by
  refine ⟨?_, fun d => ⟨⟨Option (Fin (d + 1)), inferInstance, capDFA d, capDFA_accepts d,
    by simp⟩, ?_⟩⟩
  · intro hreg
    obtain ⟨σ, _, M, hM⟩ := hreg
    have hinj : Function.Injective (fun n : ℕ => M.eval (List.replicate n op)) := by
      intro m n h
      have hf := futures_eq_of_eval_eq M h (List.replicate m cl)
      rw [hM] at hf
      have h1 : List.replicate m op ++ List.replicate m cl ∈ matched := (openCount_op_cl m m).2 rfl
      exact (openCount_op_cl m n).1 (hf.1 h1)
    exact not_injective_infinite_finite _ hinj
  · intro σ _ M hM
    have hinj : Function.Injective (fun j : Fin (d + 2) => M.eval (capWord d j)) := by
      intro j k h
      apply capWord_separated d
      intro z
      rw [← hM]
      exact futures_eq_of_eval_eq M h z
    simpa using Fintype.card_le_of_injective _ hinj

-- The formula =IF(A1>0,SUM((B1+C1)*(D1-E1)),0) keeps the brackets ((()())): the count runs
-- 1, 2, 3, 2, 3, 2, 1, 0, so it passes the depth-3 checker.
example : cappedCount 3 0 [op, op, op, cl, op, cl, cl, cl] = some 0 := by decide

-- Pumping it with x = ((, y = (), z = ())) and i = 0, 1, 2, 3 gives ((())), ((()())),
-- ((()()())) and ((()()()())), all accepted by the depth-3 checker.
example : ∀ i : Fin 4,
    cappedCount 3 0 ([op, op] ++ (List.replicate i [op, cl]).flatten ++ [op, cl, cl, cl]) = some 0 := by
  decide

-- What breaks: the 4-deep formula =ROUND(...,2) keeps (((()()))), which matches,
-- yet the depth-3 checker rejects it.
example : openCount 0 [op, op, op, op, cl, op, cl, cl, cl, cl] = some 0 ∧
    cappedCount 3 0 [op, op, op, op, cl, op, cl, cl, cl, cl] ≠ some 0 := by
  decide

-- The ten pairs from empty, (, ((, (((, ) each told apart, for depth at most 3,
-- by the ending in the card's table.
example : ∀ t ∈ [([], [op], []), ([], [op, op], []), ([], [op, op, op], []), ([], [cl], []),
      ([op], [op, op], [cl]), ([op], [op, op, op], [cl]), ([op], [cl], [cl]),
      ([op, op], [op, op, op], [cl, cl]), ([op, op], [cl], [cl, cl]),
      ([op, op, op], [cl], [cl, cl, cl])],
    (cappedCount 3 0 (t.1 ++ t.2.2) = some 0) ≠ (cappedCount 3 0 (t.2.1 ++ t.2.2) = some 0) := by
  decide

/-- The 15 splits of `((((()))))` with `|x y| ≤ 5` and `|y| ≥ 1`, as (|x|, |y|). -/
def splits5 : List (ℕ × ℕ) :=
  (List.range 6).flatMap fun j =>
    ((List.range 6).filter fun k => 1 ≤ k ∧ j + k ≤ 5).map fun k => (j, k)

-- Unlimited depth, p = 5: there are 15 allowed splits of ((((())))), and every one
-- fails at i = 0 (deleting y leaves unmatched brackets).
example : splits5.length = 15 := by decide

example : ∀ s ∈ splits5,
    openCount 0 ((List.replicate 5 op ++ List.replicate 5 cl).take s.1 ++
      (List.replicate 5 op ++ List.replicate 5 cl).drop (s.1 + s.2)) ≠ some 0 := by
  decide

-- Picking y = () from the middle instead proves nothing: ((((()^i)))) matches for i = 0..4.
example : ∀ i : Fin 5,
    openCount 0 ([op, op, op, op] ++ (List.replicate i [op, cl]).flatten ++ [cl, cl, cl, cl]) =
      some 0 := by
  decide

-- (^0 to (^6 are pairwise told apart: the ending )^j completes (^j and no other.
example : ∀ j k : Fin 7, j ≠ k →
    openCount 0 (List.replicate j op ++ List.replicate j cl) = some 0 ∧
      openCount 0 (List.replicate k op ++ List.replicate j cl) ≠ some 0 := by
  decide

#print axioms myhill_nerode_classes_are_the_fewest_states
#print axioms regular_language_pumps
#print axioms brackets_need_unbounded_memory_and_cap_d_needs_d_plus_two_states
