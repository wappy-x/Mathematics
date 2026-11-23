-- SAT solvers: DPLL with unit propagation answers every CNF formula correctly within one guess per variable, a forced answer loses no model, a season of n teams needs n - 1 rounds, and the league's own fixture list satisfies its 508 clauses.
import Mathlib.Data.List.Defs
import Mathlib.Data.Sym.Sym2
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Nat.Choose.Basic

/-! Formulas, answers and the solver.

A literal is a variable with a sign: `(v, true)` is `v` and `(v, false)` is `¬v`. A clause is a
list of literals joined by "or"; a CNF formula is a list of clauses joined by "and". A full
assignment `a` gives every variable true or false; a partial one `ρ` may leave a variable unset
(`none`). `dpll` is the card's method: stop at a conflict, stop with a model when every clause is
true, otherwise force a unit clause's last literal, otherwise guess the first unset literal of the
first unsatisfied clause true and, if that branch fails, false. Its first argument is a budget of
steps, so the function always stops; the theorem says a budget of one step per variable, plus one,
is always enough. -/

/-- A literal: a variable and a sign. -/
abbrev Lit (V : Type*) := V × Bool
/-- A clause: literals joined by "or". -/
abbrev Clause (V : Type*) := List (Lit V)
/-- A formula in conjunctive normal form: clauses joined by "and". -/
abbrev CNF (V : Type*) := List (Clause V)
/-- A partial assignment: each variable is true, false or still unset. -/
abbrev Partial (V : Type*) := V → Option Bool

variable {V : Type*}

/-- The full assignment `a` makes the clause true: some literal of it is true. -/
def Clause.Holds (a : V → Bool) (c : Clause V) : Prop := ∃ l ∈ c, a l.1 = l.2

/-- The full assignment `a` is a model of `F`: it makes every clause true. -/
def CNF.Holds (a : V → Bool) (F : CNF V) : Prop := ∀ c ∈ F, c.Holds a

/-- SAT: some assignment makes every clause true. -/
def Satisfiable (F : CNF V) : Prop := ∃ a : V → Bool, F.Holds a

/-- The full assignment `a` agrees with every answer the partial assignment `ρ` has set. -/
def Extends (a : V → Bool) (ρ : Partial V) : Prop := ∀ v b, ρ v = some b → a v = b

instance [DecidableEq V] (a : V → Bool) (c : Clause V) : Decidable (c.Holds a) := by
  unfold Clause.Holds; infer_instance

instance [DecidableEq V] (a : V → Bool) (F : CNF V) : Decidable (F.Holds a) := by
  unfold CNF.Holds; infer_instance

/-- The literal is true under the partial answers. -/
def litTrue (ρ : Partial V) (l : Lit V) : Bool := ρ l.1 == some l.2
/-- The literal is false under the partial answers. -/
def litFalse (ρ : Partial V) (l : Lit V) : Bool := ρ l.1 == some (!l.2)
/-- The literal's variable is still unset. -/
def litFree (ρ : Partial V) (l : Lit V) : Bool := (ρ l.1).isNone

/-- Set the literal true: its variable gets the literal's sign. -/
def setLit [DecidableEq V] (ρ : Partial V) (l : Lit V) : Partial V :=
  fun w => if w = l.1 then some l.2 else ρ w

/-- The clause already has a true literal. -/
def clauseSat (ρ : Partial V) (c : Clause V) : Bool := c.any (litTrue ρ)
/-- Conflict: every literal of the clause is false. -/
def clauseConflict (ρ : Partial V) (c : Clause V) : Bool := c.all (litFalse ρ)

/-- A unit clause: not yet true, and exactly one literal is unset (so all the others are false).
Returns that last literal. -/
def unitOf (ρ : Partial V) (c : Clause V) : Option (Lit V) :=
  if clauseSat ρ c then none else
    match c.filter (litFree ρ) with
    | [l] => some l
    | _ => none

/-- The first unit clause's forced literal, if any. -/
def findUnit (ρ : Partial V) (F : CNF V) : Option (Lit V) := F.findSome? (unitOf ρ)

/-- The guess: the first unset literal of the first clause not yet true. -/
def pickLit (ρ : Partial V) (F : CNF V) : Option (Lit V) :=
  (F.find? fun c => !clauseSat ρ c).bind fun c => c.find? (litFree ρ)

/-- DPLL with a budget of steps: conflict, model, forced literal, or guess true then false. -/
def dpll [DecidableEq V] (F : CNF V) : ℕ → Partial V → Option (Partial V)
  | 0, _ => none
  | n + 1, ρ =>
    if F.any (clauseConflict ρ) then none
    else if F.all (clauseSat ρ) then some ρ
    else match findUnit ρ F with
      | some l => dpll F n (setLit ρ l)
      | none => match pickLit ρ F with
        | some l => match dpll F n (setLit ρ l) with
          | some σ => some σ
          | none => dpll F n (setLit ρ (l.1, !l.2))
        | none => none

/-- `N`, the number of different variables in the formula. -/
def numVars [DecidableEq V] (F : CNF V) : ℕ := ((F.flatten).map Prod.fst).dedup.length

/-- A literal that is neither true nor unset is false. -/
theorem litFalse_of_not_true_not_free (ρ : Partial V) (l : Lit V)
    (ht : litTrue ρ l = false) (hf : litFree ρ l = false) : litFalse ρ l = true := by
  unfold litTrue litFree litFalse at *
  rcases h : ρ l.1 with _ | b
  · rw [h] at hf; simp at hf
  · rw [h] at ht; cases b <;> cases hb : l.2 <;> simp_all

/-- Setting a literal that the full assignment makes true keeps agreement. -/
theorem extends_setLit [DecidableEq V] {a : V → Bool} {ρ : Partial V} {l : Lit V}
    (ha : Extends a ρ) (hl : a l.1 = l.2) : Extends a (setLit ρ l) := by
  intro v b h
  unfold setLit at h
  split_ifs at h with hv
  · subst hv; cases h; exact hl
  · exact ha v b h

/-- A clause true under the partial answers holds for every agreeing full assignment. -/
theorem clause_holds_of_sat {a : V → Bool} {ρ : Partial V} {c : Clause V}
    (h : clauseSat ρ c = true) (ha : Extends a ρ) : c.Holds a := by
  unfold clauseSat at h
  rw [List.any_eq_true] at h
  obtain ⟨l, hl, hlt⟩ := h
  exact ⟨l, hl, ha _ _ (by simpa [litTrue] using hlt)⟩

/-- A clause that holds for an agreeing full assignment is not a conflict. -/
theorem not_conflict_of_holds {a : V → Bool} {ρ : Partial V} {c : Clause V}
    (ha : Extends a ρ) (hc : c.Holds a) : clauseConflict ρ c = false := by
  obtain ⟨l, hl, hal⟩ := hc
  unfold clauseConflict
  rw [List.all_eq_false]
  refine ⟨l, hl, ?_⟩
  intro h
  have h' : ρ l.1 = some (!l.2) := by simpa [litFalse] using h
  have := ha _ _ h'
  rw [hal] at this
  exact absurd this (by cases l.2 <;> decide)

/-- DPLL only returns answers that make every clause true. -/
theorem dpll_sound [DecidableEq V] (F : CNF V) :
    ∀ n ρ σ, dpll F n ρ = some σ → ∀ c ∈ F, clauseSat σ c = true := by
  intro n
  induction n with
  | zero => intro ρ σ h; simp [dpll] at h
  | succ n ih =>
    intro ρ σ h
    simp only [dpll] at h
    split_ifs at h with h1 h2
    · rw [List.all_eq_true] at h2; cases h; exact h2
    · split at h
      · exact ih _ _ h
      · split at h
        · split at h
          · cases h; exact ih _ _ (by assumption)
          · exact ih _ _ h
        · cases h

/-- Forcing a unit clause's literal: it is in the clause, unset, and true in every model that
agrees with the answers. -/
theorem unitOf_spec {a : V → Bool} {ρ : Partial V} {c : Clause V} {l : Lit V}
    (h : unitOf ρ c = some l) (hc : c.Holds a) (ha : Extends a ρ) :
    l ∈ c ∧ litFree ρ l = true ∧ a l.1 = l.2 := by
  unfold unitOf at h
  split_ifs at h with hs
  generalize hf : List.filter (litFree ρ) c = L at h
  rcases L with _ | ⟨l', _ | ⟨x, L⟩⟩ <;> simp at h
  subst h
  have hmem : l' ∈ c.filter (litFree ρ) := by rw [hf]; simp
  rw [List.mem_filter] at hmem
  refine ⟨hmem.1, hmem.2, ?_⟩
  obtain ⟨m, hm, ham⟩ := hc
  by_cases hmf : litFree ρ m = true
  · have : m ∈ c.filter (litFree ρ) := List.mem_filter.mpr ⟨hm, hmf⟩
    rw [hf] at this
    simp at this
    subst this
    exact ham
  · exfalso
    rcases hρ : ρ m.1 with _ | b
    · simp [litFree, hρ] at hmf
    · have hab := ha _ _ hρ
      apply hs
      unfold clauseSat
      rw [List.any_eq_true]
      refine ⟨m, hm, ?_⟩
      simp [litTrue, hρ, ← hab, ham]

/-- The guess is an unset literal of a clause of the formula. -/
theorem pickLit_spec {ρ : Partial V} {F : CNF V} {l : Lit V} (h : pickLit ρ F = some l) :
    ∃ c ∈ F, l ∈ c ∧ litFree ρ l = true := by
  unfold pickLit at h
  rw [Option.bind_eq_some_iff] at h
  obtain ⟨c, hc1, hc2⟩ := h
  exact ⟨c, List.mem_of_find?_eq_some hc1, List.mem_of_find?_eq_some hc2, List.find?_some hc2⟩

/-- With no conflict and some clause not yet true, there is a literal to guess. -/
theorem pickLit_isSome {ρ : Partial V} {F : CNF V} (h1 : ¬ F.any (clauseConflict ρ) = true)
    (h2 : ¬ F.all (clauseSat ρ) = true) (h : pickLit ρ F = none) : False := by
  unfold pickLit at h
  rcases hc : F.find? (fun c => !clauseSat ρ c) with _ | c
  · rw [List.find?_eq_none] at hc
    apply h2
    rw [List.all_eq_true]
    intro x hx
    simpa using hc x hx
  · rw [hc] at h
    simp only [Option.bind_some] at h
    rw [List.find?_eq_none] at h
    have hcs : clauseSat ρ c = false := by simpa using List.find?_some hc
    apply h1
    rw [List.any_eq_true]
    refine ⟨c, List.mem_of_find?_eq_some hc, ?_⟩
    unfold clauseConflict
    rw [List.all_eq_true]
    intro x hx
    apply litFalse_of_not_true_not_free
    · unfold clauseSat at hcs
      rw [List.any_eq_false] at hcs
      simpa using hcs x hx
    · simpa using h x hx

/-- Setting an unset variable of the formula lowers the number of unset variables. -/
theorem free_card_lt [DecidableEq V] (F : CNF V) (ρ : Partial V) (l : Lit V)
    (hv : l.1 ∈ (F.flatten).map Prod.fst) (hn : ρ l.1 = none) :
    (((F.flatten).map Prod.fst).toFinset.filter fun v => setLit ρ l v = none).card <
      (((F.flatten).map Prod.fst).toFinset.filter fun v => ρ v = none).card := by
  apply Finset.card_lt_card
  rw [Finset.ssubset_iff_of_subset]
  · refine ⟨l.1, ?_, ?_⟩
    · simp only [Finset.mem_filter, List.mem_toFinset]; exact ⟨hv, hn⟩
    · simp [setLit]
  · intro x hx
    simp only [Finset.mem_filter, List.mem_toFinset] at hx ⊢
    refine ⟨hx.1, ?_⟩
    have h2 := hx.2
    unfold setLit at h2
    split_ifs at h2 with hxl
    exact h2

/-- DPLL finds an answer whenever a model agrees with the current answers and the budget is
larger than the number of unset variables. -/
theorem dpll_complete [DecidableEq V] (F : CNF V) :
    ∀ n (ρ : Partial V),
      (((F.flatten).map Prod.fst).toFinset.filter fun v => ρ v = none).card < n →
      (∃ a, Extends a ρ ∧ F.Holds a) → (dpll F n ρ).isSome = true := by
  intro n
  induction n with
  | zero => intro ρ h; simp at h
  | succ n ih =>
    rintro ρ hcard ⟨a, ha, hF⟩
    have hle : (((F.flatten).map Prod.fst).toFinset.filter fun v => ρ v = none).card ≤ n :=
      Nat.lt_succ_iff.mp hcard
    have hmem : ∀ c ∈ F, ∀ l ∈ c, l.1 ∈ (F.flatten).map Prod.fst := fun c hc l hl =>
      List.mem_map.mpr ⟨l, List.mem_flatten.mpr ⟨c, hc, hl⟩, rfl⟩
    have hnc : ¬ F.any (clauseConflict ρ) = true := by
      rw [List.any_eq_true]
      rintro ⟨c, hc, hcc⟩
      rw [not_conflict_of_holds ha (hF c hc)] at hcc
      exact Bool.false_ne_true hcc
    simp only [dpll]
    split_ifs with hall
    · rfl
    · split
      · next l hu =>
        obtain ⟨c, hc, hcu⟩ := List.exists_of_findSome?_eq_some hu
        obtain ⟨hlc, hfree, hal⟩ := unitOf_spec hcu (hF c hc) ha
        have hn : ρ l.1 = none := Option.isNone_iff_eq_none.mp hfree
        exact ih _ (lt_of_lt_of_le (free_card_lt F ρ l (hmem c hc l hlc) hn) hle)
          ⟨a, extends_setLit ha hal, hF⟩
      · split
        · next l hp =>
          obtain ⟨c, hc, hlc, hfree⟩ := pickLit_spec hp
          have hn : ρ l.1 = none := Option.isNone_iff_eq_none.mp hfree
          split
          · rfl
          · next hnone =>
            by_cases hal : a l.1 = l.2
            · have := ih _ (lt_of_lt_of_le (free_card_lt F ρ l (hmem c hc l hlc) hn) hle)
                ⟨a, extends_setLit ha hal, hF⟩
              rw [hnone] at this
              cases this
            · have hal' : a (l.1, !l.2).1 = (l.1, !l.2).2 := by
                cases h : a l.1 <;> cases h2 : l.2 <;> simp_all
              exact ih _ (lt_of_lt_of_le
                (free_card_lt F ρ (l.1, !l.2) (hmem c hc l hlc) hn) hle)
                ⟨a, extends_setLit ha hal', hF⟩
        · next hp => exact (pickLit_isSome hnc hall hp).elim

/-- DPLL answers correctly on every formula. Started with no answers set and a budget of one step
per variable plus one, it never claims a false model (every full assignment that agrees with the
answers it returns makes every clause true), and it returns an answer exactly when the formula is
satisfiable, so it never misses a model and always stops. -/
theorem dpll_answers_correctly [DecidableEq V] (F : CNF V) :
    (∀ ρ, dpll F (numVars F + 1) (fun _ => none) = some ρ → ∀ a, Extends a ρ → F.Holds a) ∧
    ((dpll F (numVars F + 1) (fun _ => none)).isSome = true ↔ Satisfiable F) := by
  have sound : ∀ ρ, dpll F (numVars F + 1) (fun _ => none) = some ρ →
      ∀ a, Extends a ρ → F.Holds a := fun ρ h a ha c hc =>
    clause_holds_of_sat (dpll_sound F _ _ _ h c hc) ha
  refine ⟨sound, ⟨fun h => ?_, fun ⟨a, ha⟩ => ?_⟩⟩
  · obtain ⟨σ, hσ⟩ := Option.isSome_iff_exists.mp h
    refine ⟨fun v => (σ v).getD false, sound σ hσ _ ?_⟩
    intro v b hv
    simp [hv]
  · apply dpll_complete
    · apply Nat.lt_succ_of_le
      refine le_trans (Finset.card_filter_le _ _) ?_
      rw [List.card_toFinset]
      rfl
    · exact ⟨a, (fun _ _ h => by simp at h), ha⟩

/-- Propagation loses no model: if every literal of a clause of `F` other than `l` is false under
the current answers, then every model of `F` that agrees with the current answers also makes `l`
true, so forcing `l` removes no model. -/
theorem unit_propagation_loses_no_model [DecidableEq V] (F : CNF V) (ρ : Partial V)
    (c : Clause V) (l : Lit V) (hc : c ∈ F) (hl : l ∈ c)
    (hrest : ∀ m ∈ c, m ≠ l → ρ m.1 = some (!m.2))
    (a : V → Bool) (ha : Extends a ρ) (hF : F.Holds a) :
    Extends a (setLit ρ l) := by
  apply extends_setLit ha
  obtain ⟨m, hm, ham⟩ := hF c hc
  by_cases hml : m = l
  · subst hml; exact ham
  · have := ha _ _ (hrest m hm hml)
    rw [this] at ham
    cases hb : m.2 <;> simp_all

/-- No schedule below n - 1 rounds: if every pair of the `n` teams is given one of `R` rounds and
no team plays two matches in one round, then `R ≥ n - 1`. Team A's `n - 1` matches are the
pigeons and the rounds are the holes. -/
theorem season_needs_n_sub_one_rounds {n R : ℕ} (round : Sym2 (Fin n) → Fin R)
    (honce : ∀ t u v : Fin n, u ≠ t → v ≠ t → round s(t, u) = round s(t, v) → u = v) :
    n - 1 ≤ R := by
  rcases n with _ | k
  · exact Nat.zero_le _
  · have hinj : Function.Injective (fun i : Fin k => round s((0 : Fin (k + 1)), i.succ)) := by
      intro i j hij
      exact Fin.succ_injective _
        (honce 0 i.succ j.succ (Fin.succ_ne_zero i) (Fin.succ_ne_zero j) hij)
    simpa using Fintype.card_le_of_injective _ hinj

/-! The league as clauses. A variable `(t, u, r)` with `t < u` says "teams t and u meet in round
r". Teams A to F are 0 to 5 and rounds 1 to 5 are 0 to 4. -/

/-- The pairs `(i, j)` with `i < j`. -/
def pairsOf (k : ℕ) : List (Fin k × Fin k) :=
  ((List.finRange k).product (List.finRange k)).filter fun p => p.1 < p.2

/-- The literal "t and u meet in round r" (sign true) or its negation (sign false). -/
def meet {n R : ℕ} (t u : Fin n) (r : Fin R) (b : Bool) : Lit (Fin n × Fin n × Fin R) :=
  ((min t u, max t u, r), b)

/-- Every pair meets, no pair meets twice, no team plays twice a round, every team plays every
round. -/
def leagueBase (n R : ℕ) : CNF (Fin n × Fin n × Fin R) :=
  (pairsOf n).map (fun p => (List.finRange R).map fun r => meet p.1 p.2 r true)
  ++ (pairsOf n).flatMap (fun p => (pairsOf R).map fun rs =>
        [meet p.1 p.2 rs.1 false, meet p.1 p.2 rs.2 false])
  ++ (List.finRange n).flatMap (fun t => (List.finRange R).flatMap fun r =>
        ((pairsOf n).filter fun uv => uv.1 ≠ t ∧ uv.2 ≠ t).map fun uv =>
          [meet t uv.1 r false, meet t uv.2 r false])
  ++ (List.finRange n).flatMap (fun t => (List.finRange R).map fun r =>
        ((List.finRange n).filter (· ≠ t)).map fun u => meet t u r true)

/-- The secretary's four rules: the derby, the rematch, the referee and the fair run. -/
def rules : CNF (Fin 6 × Fin 6 × Fin 5) :=
  [[meet 0 1 4 true], [meet 2 5 0 true],
    [meet 3 4 0 false], [meet 3 4 1 false], [meet 3 4 4 false]]
  ++ (List.finRange 4).flatMap fun r =>
    [[meet 1 2 r.castSucc false, meet 1 3 r.succ false],
      [meet 1 3 r.castSucc false, meet 1 2 r.succ false]]

/-- The league formula `F`. -/
def league : CNF (Fin 6 × Fin 6 × Fin 5) := leagueBase 6 5 ++ rules

/-- The card's fixture list, rounds 1 to 5. -/
def cardRounds : List (List (Fin 6 × Fin 6)) :=
  [[(0, 3), (1, 4), (2, 5)], [(0, 4), (1, 2), (3, 5)], [(0, 2), (1, 5), (3, 4)],
    [(0, 5), (1, 3), (2, 4)], [(0, 1), (2, 3), (4, 5)]]

/-- The fixture list read as answers to the 75 questions. -/
def cardAnswers : Fin 6 × Fin 6 × Fin 5 → Bool :=
  fun x => (cardRounds.getD x.2.2.val []).contains (x.1, x.2.1)

-- 75 variables and 15 + 150 + 300 + 30 + 13 = 508 clauses.
example : Nat.choose 6 2 * 5 = 75 := by decide
example : 15 + 15 * Nat.choose 5 2 + 6 * 5 * Nat.choose 5 2 + 6 * 5 + (1 + 1 + 3 + 8) = 508 := by
  decide
set_option maxRecDepth 20000 in
example : numVars league = 75 := by decide +kernel
example : league.length = 508 := by decide +kernel
example : (leagueBase 6 5).length = 495 := by decide +kernel
-- The fixture list satisfies every one of the 508 clauses.
example : league.Holds cardAnswers := by decide +kernel
-- 2^75 is about 3.78 × 10^22: it lies between 3.775 × 10^22 and 3.785 × 10^22.
example : 3775 * 10 ^ 19 < 2 ^ 75 ∧ 2 ^ 75 < 3785 * 10 ^ 19 := by decide
-- 5 set by unit clauses, 4 guesses, 24 + 9 + 7 + 5 + 21 = 66 forced: all 75.
example : 24 + 9 + 7 + 5 + 21 = 66 ∧ 5 + 4 + 66 = 75 := by decide
-- Variables and clauses for a full season of n - 1 rounds, at 4, 6, 8, 10, 12, 16 and 20 teams.
example : [4, 6, 8, 10, 12, 16, 20].map (fun n => Nat.choose n 2 * (n - 1)) =
    [18, 75, 196, 405, 726, 1800, 3610] := by decide
example : [4, 6, 8, 10, 12, 16, 20].map (fun n => Nat.choose n 2 + Nat.choose n 2 * Nat.choose (n - 1) 2
      + n * (n - 1) * Nat.choose (n - 1) 2 + n * (n - 1)) =
    [72, 495, 1848, 4995, 11088, 38160, 98040] := by decide
-- Squeezed into n - 2 rounds: 6 > 4, 15 > 12, 28 > 24, 45 > 40 matches against slots.
example : [4, 6, 8, 10].map (fun n => (Nat.choose n 2, (n - 2) * (n / 2))) =
    [(6, 4), (15, 12), (28, 24), (45, 40)] := by decide
-- DPLL on 4 teams squeezed into 2 rounds answers "no schedule".
example : (dpll (leagueBase 4 2) (numVars (leagueBase 4 2) + 1) (fun _ => none)).isSome = false := by
  decide +kernel
-- DPLL, with the budget the theorem gives, finds a fixture list for the league.
set_option maxRecDepth 20000 in
example : (dpll league (numVars league + 1) (fun _ => none)).isSome = true := by
  decide +kernel

#print axioms litFalse_of_not_true_not_free
#print axioms extends_setLit
#print axioms clause_holds_of_sat
#print axioms not_conflict_of_holds
#print axioms dpll_sound
#print axioms unitOf_spec
#print axioms pickLit_spec
#print axioms pickLit_isSome
#print axioms free_card_lt
#print axioms dpll_complete
#print axioms dpll_answers_correctly
#print axioms unit_propagation_loses_no_model
#print axioms season_needs_n_sub_one_rounds
