-- Grammars and a stack: a language has a context-free grammar exactly when some stack machine accepts it, and the arch grammar and the hand-built stack machine both pick out exactly the arch songs.
import Mathlib.Computability.ContextFreeGrammar
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.DeriveFintype
import Mathlib.Tactic.NormNum

/-! ## Stack machines

Mathlib has context-free grammars (`ContextFreeGrammar`, `ContextFreeGrammar.language`,
`Language.IsContextFree`) but no stack machines, so the card's stack machine is defined here.
A configuration is (state, letters still to read, pile), with the top of the pile at the head
of the list. -/

/-- A stack machine (pushdown automaton) over the alphabet `T`: finitely many states `Q`,
a finite stack alphabet `Γ`, a start state, a set of accepting states, and a finite table of
moves. A move `(q, a, X, q', γ)` is one choice in δ(q, a, X) ∋ (q', γ): in state `q`, reading
letter `a` (`none` reads nothing, ε), with `X` on top of the pile (`none` looks at nothing),
pop `X`, push the string `γ` (its first symbol ends on top) and go to state `q'`. -/
structure PDA (T : Type) where
  /-- The states. -/
  Q : Type
  /-- The stack alphabet. -/
  Γ : Type
  [finQ : Fintype Q]
  [finΓ : Fintype Γ]
  /-- The start state q₀. -/
  start : Q
  /-- The accepting states F. -/
  accept : Set Q
  /-- The move rule δ, as a finite table of choices. -/
  moves : Finset (Q × Option T × Option Γ × Q × List Γ)

namespace PDA

variable {T : Type}

/-- One move of the machine: a listed move whose letter (if any) is the next letter of the
input and whose popped symbol (if any) is the top of the pile. -/
inductive Step (M : PDA T) : M.Q × List T × List M.Γ → M.Q × List T × List M.Γ → Prop
  | move {q q' : M.Q} {a : Option T} {X : Option M.Γ} {γ : List M.Γ} {w : List T}
      {s : List M.Γ} :
      (q, a, X, q', γ) ∈ M.moves → Step M (q, a.toList ++ w, X.toList ++ s) (q', w, γ ++ s)

/-- `L(M)`: the machine accepts `w` when some run, started in the start state with an empty
pile, reads all of `w` and ends in an accepting state. -/
def language (M : PDA T) : Language T :=
  {w | ∃ q ∈ M.accept, ∃ s : List M.Γ,
    Relation.ReflTransGen M.Step (M.start, w, []) (q, [], s)}

end PDA

theorem pda_step_iff {T : Type} (M : PDA T) (c c' : M.Q × List T × List M.Γ) :
    M.Step c c' ↔ ∃ q a X q' γ w s, (q, a, X, q', γ) ∈ M.moves ∧
      c = (q, a.toList ++ w, X.toList ++ s) ∧ c' = (q', w, γ ++ s) := by
  constructor
  · rintro ⟨hm⟩
    exact ⟨_, _, _, _, _, _, _, hm, rfl, rfl⟩
  · rintro ⟨q, a, X, q', γ, w, s, hm, rfl, rfl⟩
    exact PDA.Step.move hm

theorem pda_reach_lift {T : Type} {M : PDA T} {c c' : M.Q × List T × List M.Γ}
    (h : Relation.ReflTransGen M.Step c c') (u : List T) (s : List M.Γ) :
    Relation.ReflTransGen M.Step (c.1, c.2.1 ++ u, c.2.2 ++ s) (c'.1, c'.2.1 ++ u, c'.2.2 ++ s) := by
  induction h with
  | refl => exact Relation.ReflTransGen.refl
  | tail _ hst ih =>
    refine ih.tail ?_
    rw [pda_step_iff] at hst ⊢
    obtain ⟨q, a, X, q', γ, w, s0, hm, rfl, rfl⟩ := hst
    exact ⟨q, a, X, q', γ, w ++ u, s0 ++ s, hm, by simp, by simp⟩

theorem pda_reach_lift' {T : Type} {M : PDA T} {p q : M.Q} {w w' : List T} {α β : List M.Γ}
    (h : Relation.ReflTransGen M.Step (p, w, α) (q, w', β)) (u : List T) (s : List M.Γ) :
    Relation.ReflTransGen M.Step (p, w ++ u, α ++ s) (q, w' ++ u, β ++ s) :=
  pda_reach_lift h u s

/-- Leftmost derivations. -/
inductive CFGen {T : Type} (g : ContextFreeGrammar T) : List (Symbol T g.NT) → List T → Prop
  | nil : CFGen g [] []
  | term (t : T) {α : List (Symbol T g.NT)} {w : List T} :
      CFGen g α w → CFGen g (.terminal t :: α) (t :: w)
  | nt {r : ContextFreeRule T g.NT} {α : List (Symbol T g.NT)} {w : List T} :
      r ∈ g.rules → CFGen g (r.output ++ α) w → CFGen g (.nonterminal r.input :: α) w

theorem cfgen_terminals {T : Type} {g : ContextFreeGrammar T} (w : List T) :
    CFGen g (w.map .terminal) w := by
  induction w with
  | nil => exact .nil
  | cons t w ih => exact .term t ih

theorem cfgen_expand {T : Type} {g : ContextFreeGrammar T} {r : ContextFreeRule T g.NT}
    (hr : r ∈ g.rules) (q : List (Symbol T g.NT)) {γ : List (Symbol T g.NT)} {w : List T}
    (h : CFGen g γ w) :
    ∀ p, γ = p ++ (r.output ++ q) → CFGen g (p ++ (.nonterminal r.input :: q)) w := by
  induction h with
  | nil =>
    intro p hp
    obtain ⟨rfl, hp'⟩ := List.append_eq_nil_iff.mp hp.symm
    exact .nt hr (by rw [hp']; exact .nil)
  | term t hα ih =>
    intro p hp
    rcases p with _ | ⟨x, p⟩
    · exact .nt hr (by rw [List.nil_append] at hp; rw [← hp]; exact .term t hα)
    · simp only [List.cons_append, List.cons.injEq] at hp
      obtain ⟨rfl, rfl⟩ := hp
      exact .term t (ih p rfl)
  | @nt r' α w hr' hα ih =>
    intro p hp
    rcases p with _ | ⟨x, p⟩
    · exact .nt hr (by rw [List.nil_append] at hp; rw [← hp]; exact .nt hr' hα)
    · simp only [List.cons_append, List.cons.injEq] at hp
      obtain ⟨rfl, rfl⟩ := hp
      have := ih (r'.output ++ p) (by simp)
      exact .nt hr' (by simpa using this)

theorem cfgen_of_derives {T : Type} {g : ContextFreeGrammar T} {α : List (Symbol T g.NT)}
    {w : List T} (h : g.Derives α (w.map .terminal)) : CFGen g α w := by
  induction h using Relation.ReflTransGen.head_induction_on with
  | refl => exact cfgen_terminals w
  | head hp _ ih =>
    obtain ⟨r, hr, hrw⟩ := hp
    obtain ⟨p, q, rfl, rfl⟩ := hrw.exists_parts
    have := cfgen_expand hr q ih p (by simp)
    simpa using this
/-- Nonterminals of the grammar built from a stack machine. -/
inductive PNT (Q Γ : Type)
  | emp (p q : Q)
  | pop (p : Q) (Y : Γ) (q : Q)
  | seq (p : Q) (γ : List Γ) (q : Q)

section PDAGrammar

variable {T : Type} (N : PDA T)

attribute [local instance] PDA.finQ PDA.finΓ

/-- The terminal list read by one move. -/
def tmOf (a : Option T) : List (Symbol T (PNT N.Q N.Γ)) := a.toList.map .terminal

open Classical in
/-- The stack strings that can name a `seq` nonterminal: suffixes of pushed strings. -/
noncomputable def pSuffixes : Finset (List N.Γ) :=
  N.moves.biUnion fun m => m.2.2.2.2.tails.toFinset

open Classical in
/-- The rules contributed by one move. -/
noncomputable def moveRules : N.Q × Option T × Option N.Γ × N.Q × List N.Γ →
    Finset (ContextFreeRule T (PNT N.Q N.Γ))
  | (p, a, none, q, γ) =>
      (Finset.univ : Finset (N.Q × N.Q)).image
        (fun sr => ⟨.emp p sr.2, tmOf N a ++ [.nonterminal (.seq q γ sr.1),
          .nonterminal (.emp sr.1 sr.2)]⟩) ∪
      (Finset.univ : Finset (N.Γ × N.Q × N.Q)).image
        (fun x => ⟨.pop p x.1 x.2.2, tmOf N a ++ [.nonterminal (.seq q γ x.2.1),
          .nonterminal (.pop x.2.1 x.1 x.2.2)]⟩)
  | (p, a, some Y, q, γ) =>
      (Finset.univ : Finset N.Q).image (fun t => ⟨.pop p Y t, tmOf N a ++ [.nonterminal (.seq q γ t)]⟩)

open Classical in
/-- The rules contributed by one suffix. -/
noncomputable def suffixRules : List N.Γ → Finset (ContextFreeRule T (PNT N.Q N.Γ))
  | [] => ∅
  | Y :: β => (Finset.univ : Finset (N.Q × N.Q × N.Q)).image
      (fun x => ⟨.seq x.1 (Y :: β) x.2.2, [.nonterminal (.pop x.1 Y x.2.1), .nonterminal (.seq x.2.1 β x.2.2)]⟩)

open Classical in
/-- The grammar of a stack machine, from state `p₀` with an empty pile to state `r₀` with an
empty pile. -/
noncomputable abbrev pdaGrammar (p₀ r₀ : N.Q) : ContextFreeGrammar T where
  NT := PNT N.Q N.Γ
  initial := .emp p₀ r₀
  rules :=
    (Finset.univ : Finset N.Q).image (fun p => ⟨.emp p p, []⟩) ∪
    (Finset.univ : Finset N.Q).image (fun p => ⟨.seq p [] p, []⟩) ∪
    N.moves.biUnion (moveRules N) ∪
    (pSuffixes N).biUnion (suffixRules N)

/-- Meaning of each nonterminal. -/
def PSem : PNT N.Q N.Γ → List T → Prop
  | .emp p q, w => Relation.ReflTransGen N.Step (p, w, []) (q, [], [])
  | .pop p Y q, w => Relation.ReflTransGen N.Step (p, w, [Y]) (q, [], [])
  | .seq p γ q, w => Relation.ReflTransGen N.Step (p, w, γ) (q, [], [])

/-- Meaning of a sentential form. -/
def FSem : List (Symbol T (PNT N.Q N.Γ)) → List T → Prop
  | [], w => w = []
  | .terminal t :: α, w => ∃ w', w = t :: w' ∧ FSem α w'
  | .nonterminal X :: α, w => ∃ w1 w2, w = w1 ++ w2 ∧ PSem N X w1 ∧ FSem α w2

end PDAGrammar

section PDAGrammarProofs

variable {T : Type} {N : PDA T}

attribute [local instance] PDA.finQ PDA.finΓ

theorem fsem_append (α β : List (Symbol T (PNT N.Q N.Γ))) (w : List T) :
    FSem N (α ++ β) w ↔ ∃ w1 w2, w = w1 ++ w2 ∧ FSem N α w1 ∧ FSem N β w2 := by
  induction α generalizing w with
  | nil => simp [FSem]
  | cons x α ih =>
    cases x with
    | terminal t =>
      simp only [List.cons_append, FSem, ih]
      constructor
      · rintro ⟨w', rfl, w1, w2, rfl, h1, h2⟩
        exact ⟨t :: w1, w2, rfl, ⟨w1, rfl, h1⟩, h2⟩
      · rintro ⟨_, w2, rfl, ⟨w1, rfl, h1⟩, h2⟩
        exact ⟨w1 ++ w2, rfl, w1, w2, rfl, h1, h2⟩
    | nonterminal X =>
      simp only [List.cons_append, FSem, ih]
      constructor
      · rintro ⟨w1, w', rfl, hX, w2, w3, rfl, h2, h3⟩
        exact ⟨w1 ++ w2, w3, by simp, ⟨w1, w2, rfl, hX, h2⟩, h3⟩
      · rintro ⟨_, w3, rfl, ⟨w1, w2, rfl, hX, h2⟩, h3⟩
        exact ⟨w1, w2 ++ w3, by simp, hX, w2, w3, rfl, h2, h3⟩

theorem fsem_tm (a : Option T) (β : List (Symbol T (PNT N.Q N.Γ))) (w : List T) :
    FSem N (tmOf N a ++ β) w ↔ ∃ w', w = a.toList ++ w' ∧ FSem N β w' := by
  cases a with
  | none => simp [tmOf]
  | some t => simp [tmOf, FSem]

theorem fsem_nt2 (X Y : PNT N.Q N.Γ) (w : List T) :
    FSem N [.nonterminal X, .nonterminal Y] w ↔
      ∃ w1 w2, w = w1 ++ w2 ∧ PSem N X w1 ∧ PSem N Y w2 := by
  simp [FSem]

theorem fsem_nt1 (X : PNT N.Q N.Γ) (w : List T) :
    FSem N [.nonterminal X] w ↔ PSem N X w := by
  simp [FSem]

theorem pda_rules_cases {p₀ r₀ : N.Q} (r : ContextFreeRule T (PNT N.Q N.Γ))
    (hr : r ∈ (pdaGrammar N p₀ r₀).rules) :
    (∃ p, r = ⟨.emp p p, []⟩) ∨ (∃ p, r = ⟨.seq p [] p, []⟩) ∨
    (∃ p a q γ, (p, a, none, q, γ) ∈ N.moves ∧
      ((∃ s r', r = ⟨.emp p r', tmOf N a ++ [.nonterminal (.seq q γ s), .nonterminal (.emp s r')]⟩) ∨
       (∃ Y t u, r = ⟨.pop p Y u, tmOf N a ++ [.nonterminal (.seq q γ t),
          .nonterminal (.pop t Y u)]⟩))) ∨
    (∃ p a Y q γ, (p, a, some Y, q, γ) ∈ N.moves ∧
      ∃ t, r = ⟨.pop p Y t, tmOf N a ++ [.nonterminal (.seq q γ t)]⟩) ∨
    (∃ Y β, (Y :: β) ∈ pSuffixes N ∧ ∃ q t s,
      r = ⟨.seq q (Y :: β) s, [.nonterminal (.pop q Y t), .nonterminal (.seq t β s)]⟩) := by
  unfold pdaGrammar at hr
  simp only [Finset.mem_union, Finset.mem_image, Finset.mem_univ, true_and,
    Finset.mem_biUnion] at hr
  rcases hr with ((⟨p, rfl⟩ | ⟨p, rfl⟩) | ⟨⟨p, a, X, q, γ⟩, hm, hr⟩) | ⟨γ, hγ, hr⟩
  · exact Or.inl ⟨p, rfl⟩
  · exact Or.inr (Or.inl ⟨p, rfl⟩)
  · cases X with
    | none =>
      simp only [moveRules, Finset.mem_union, Finset.mem_image, Finset.mem_univ, true_and,
        Prod.exists] at hr
      refine Or.inr (Or.inr (Or.inl ⟨p, a, q, γ, hm, ?_⟩))
      rcases hr with ⟨s, r', rfl⟩ | ⟨Y, t, u, rfl⟩
      · exact Or.inl ⟨s, r', rfl⟩
      · exact Or.inr ⟨Y, t, u, rfl⟩
    | some Y =>
      simp only [moveRules, Finset.mem_image, Finset.mem_univ, true_and] at hr
      obtain ⟨t, rfl⟩ := hr
      exact Or.inr (Or.inr (Or.inr (Or.inl ⟨p, a, Y, q, γ, hm, t, rfl⟩)))
  · cases γ with
    | nil => simp [suffixRules] at hr
    | cons Y β =>
      simp only [suffixRules, Finset.mem_image, Finset.mem_univ, true_and, Prod.exists] at hr
      obtain ⟨q, t, s, rfl⟩ := hr
      exact Or.inr (Or.inr (Or.inr (Or.inr ⟨Y, β, hγ, q, t, s, rfl⟩)))

theorem pda_rule_sound {p₀ r₀ : N.Q} (r : ContextFreeRule T (PNT N.Q N.Γ))
    (hr : r ∈ (pdaGrammar N p₀ r₀).rules) (w : List T) (h : FSem N r.output w) :
    PSem N r.input w := by
  rcases pda_rules_cases r hr with ⟨p, rfl⟩ | ⟨p, rfl⟩ |
    ⟨p, a, q, γ, hm, ⟨s, r', rfl⟩ | ⟨Y, t, u, rfl⟩⟩ | ⟨p, a, Y, q, γ, hm, t, rfl⟩ |
    ⟨Y, β, -, q, t, s, rfl⟩
  · simp only [FSem] at h
    subst h
    exact Relation.ReflTransGen.refl
  · simp only [FSem] at h
    subst h
    exact Relation.ReflTransGen.refl
  · rw [fsem_tm, ] at h
    obtain ⟨w', rfl, h⟩ := h
    rw [fsem_nt2] at h
    obtain ⟨w1, w2, rfl, h1, h2⟩ := h
    have hs : N.Step (p, a.toList ++ (w1 ++ w2), [] ++ []) (q, w1 ++ w2, γ ++ []) :=
      PDA.Step.move (X := none) hm
    have h1' := pda_reach_lift' (h1 : Relation.ReflTransGen N.Step (q, w1, γ) (s, [], [])) w2 []
    simp only [List.append_nil, List.nil_append] at hs h1'
    exact Relation.ReflTransGen.head hs (h1'.trans h2)
  · rw [fsem_tm, ] at h
    obtain ⟨w', rfl, h⟩ := h
    rw [fsem_nt2] at h
    obtain ⟨w1, w2, rfl, h1, h2⟩ := h
    have hs : N.Step (p, a.toList ++ (w1 ++ w2), [] ++ [Y]) (q, w1 ++ w2, γ ++ [Y]) :=
      PDA.Step.move (X := none) hm
    have h1' := pda_reach_lift' (h1 : Relation.ReflTransGen N.Step (q, w1, γ) (t, [], [])) w2 [Y]
    simp only [List.nil_append] at hs h1'
    exact Relation.ReflTransGen.head hs (h1'.trans h2)
  · rw [fsem_tm, ] at h
    obtain ⟨w', rfl, h⟩ := h
    rw [fsem_nt1] at h
    have hs : N.Step (p, a.toList ++ w', [Y] ++ []) (q, w', γ ++ []) :=
      PDA.Step.move (X := some Y) hm
    simp only [List.append_nil] at hs
    exact Relation.ReflTransGen.head hs h
  · rw [fsem_nt2] at h
    obtain ⟨w1, w2, rfl, h1, h2⟩ := h
    have h1' := pda_reach_lift' (h1 : Relation.ReflTransGen N.Step (q, w1, [Y]) (t, [], [])) w2 β
    simp only [List.nil_append, List.singleton_append] at h1'
    exact h1'.trans h2

theorem pda_gen_sound {p₀ r₀ : N.Q} {α : List (Symbol T (pdaGrammar N p₀ r₀).NT)} {w : List T}
    (h : CFGen (pdaGrammar N p₀ r₀) α w) : FSem N α w := by
  induction h with
  | nil => rfl
  | term t _ ih => exact ⟨_, rfl, ih⟩
  | @nt r α w hr _ ih =>
    obtain ⟨w1, w2, rfl, h1, h2⟩ := (fsem_append _ _ _).mp ih
    exact ⟨w1, w2, rfl, pda_rule_sound r hr w1 h1, h2⟩

end PDAGrammarProofs

section PDAGrammarComplete

variable {T : Type} {N : PDA T}

attribute [local instance] PDA.finQ PDA.finΓ

/-- A chain of `pop` nonterminals that empties the pile `α`, from state `p` to state `s`. -/
inductive PChain (N : PDA T) : N.Q → List N.Γ → N.Q → List (Symbol T (PNT N.Q N.Γ)) → Prop
  | nil (p : N.Q) : PChain N p [] p []
  | cons {p : N.Q} {Y : N.Γ} {t : N.Q} {β : List N.Γ} {s : N.Q}
      {F : List (Symbol T (PNT N.Q N.Γ))} :
      PChain N t β s F → PChain N p (Y :: β) s (.nonterminal (.pop p Y t) :: F)

theorem pChain_append {q s : N.Q} {γ β : List N.Γ} {F : List (Symbol T (PNT N.Q N.Γ))}
    (h : PChain N q (γ ++ β) s F) :
    ∃ t F1 F2, F = F1 ++ F2 ∧ PChain N q γ t F1 ∧ PChain N t β s F2 := by
  induction γ generalizing q F with
  | nil => exact ⟨q, [], F, rfl, .nil q, h⟩
  | cons Y γ ih =>
    cases h with
    | @cons _ _ t _ _ F h =>
      obtain ⟨t', F1, F2, rfl, h1, h2⟩ := ih h
      exact ⟨t', _ :: F1, F2, rfl, .cons h1, h2⟩

theorem pda_mem_pSuffixes {γ : List N.Γ}
    (h : ∃ m ∈ N.moves, γ <:+ m.2.2.2.2) : γ ∈ pSuffixes N := by
  classical
  obtain ⟨m, hm, hs⟩ := h
  unfold pSuffixes
  rw [Finset.mem_biUnion]
  exact ⟨m, hm, by simpa [List.mem_tails] using hs⟩

theorem pda_rule_mem {p₀ r₀ : N.Q} :
    (∀ p, (⟨.emp p p, []⟩ : ContextFreeRule T (PNT N.Q N.Γ)) ∈ (pdaGrammar N p₀ r₀).rules) ∧
    (∀ p, (⟨.seq p [] p, []⟩ : ContextFreeRule T (PNT N.Q N.Γ)) ∈ (pdaGrammar N p₀ r₀).rules) ∧
    (∀ p a q γ, (p, a, none, q, γ) ∈ N.moves → ∀ s r',
      (⟨.emp p r', tmOf N a ++ [.nonterminal (.seq q γ s), .nonterminal (.emp s r')]⟩ :
        ContextFreeRule T (PNT N.Q N.Γ)) ∈ (pdaGrammar N p₀ r₀).rules) ∧
    (∀ p a q γ, (p, a, none, q, γ) ∈ N.moves → ∀ Y t u,
      (⟨.pop p Y u, tmOf N a ++ [.nonterminal (.seq q γ t), .nonterminal (.pop t Y u)]⟩ :
        ContextFreeRule T (PNT N.Q N.Γ)) ∈ (pdaGrammar N p₀ r₀).rules) ∧
    (∀ p a Y q γ, (p, a, some Y, q, γ) ∈ N.moves → ∀ t,
      (⟨.pop p Y t, tmOf N a ++ [.nonterminal (.seq q γ t)]⟩ :
        ContextFreeRule T (PNT N.Q N.Γ)) ∈ (pdaGrammar N p₀ r₀).rules) ∧
    (∀ Y β, (Y :: β) ∈ pSuffixes N → ∀ q t s,
      (⟨.seq q (Y :: β) s, [.nonterminal (.pop q Y t), .nonterminal (.seq t β s)]⟩ :
        ContextFreeRule T (PNT N.Q N.Γ)) ∈ (pdaGrammar N p₀ r₀).rules) := by
  unfold pdaGrammar
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro p
    simp only [Finset.mem_union, Finset.mem_image, Finset.mem_univ, true_and]
    exact Or.inl (Or.inl (Or.inl ⟨p, rfl⟩))
  · intro p
    simp only [Finset.mem_union, Finset.mem_image, Finset.mem_univ, true_and]
    exact Or.inl (Or.inl (Or.inr ⟨p, rfl⟩))
  · intro p a q γ hm s r'
    simp only [Finset.mem_union, Finset.mem_biUnion]
    refine Or.inl (Or.inr ⟨_, hm, ?_⟩)
    simp only [moveRules, Finset.mem_union, Finset.mem_image, Finset.mem_univ, true_and]
    exact Or.inl ⟨(s, r'), rfl⟩
  · intro p a q γ hm Y t u
    simp only [Finset.mem_union, Finset.mem_biUnion]
    refine Or.inl (Or.inr ⟨_, hm, ?_⟩)
    simp only [moveRules, Finset.mem_union, Finset.mem_image, Finset.mem_univ, true_and]
    exact Or.inr ⟨(Y, t, u), rfl⟩
  · intro p a Y q γ hm t
    simp only [Finset.mem_union, Finset.mem_biUnion]
    refine Or.inl (Or.inr ⟨_, hm, ?_⟩)
    simp only [moveRules, Finset.mem_image, Finset.mem_univ, true_and]
    exact ⟨t, rfl⟩
  · intro Y β hγ q t s
    simp only [Finset.mem_union, Finset.mem_biUnion]
    refine Or.inr ⟨_, hγ, ?_⟩
    simp only [suffixRules, Finset.mem_image, Finset.mem_univ, true_and]
    exact ⟨(q, t, s), rfl⟩

theorem cfg_produces_of_mem {g : ContextFreeGrammar T} {r : ContextFreeRule T g.NT}
    (hr : r ∈ g.rules) : g.Produces [.nonterminal r.input] r.output :=
  ⟨r, hr, ContextFreeRule.Rewrites.input_output⟩

theorem cfg_derives_expand {g : ContextFreeGrammar T} {X S : g.NT}
    {pre Z rest F1 W : List (Symbol T g.NT)}
    (hP : g.Produces [.nonterminal X] (pre ++ [.nonterminal S] ++ Z))
    (hS : g.Derives [.nonterminal S] F1) (hd : g.Derives (F1 ++ (Z ++ rest)) W) :
    g.Derives (.nonterminal X :: rest) (pre ++ W) := by
  have h1 := (hP.append_right rest).single
  have h2 := ((hS.append_right (Z ++ rest)).append_left pre)
  have h3 := hd.append_left pre
  simp only [List.singleton_append, List.append_assoc] at h1 h2
  exact h1.trans (h2.trans h3)

theorem pChain_seq {p₀ r₀ q t : N.Q} {γ : List N.Γ} {F : List (Symbol T (PNT N.Q N.Γ))}
    (hγ : ∃ m ∈ N.moves, γ <:+ m.2.2.2.2) (h : PChain N q γ t F) :
    (pdaGrammar N p₀ r₀).Derives [.nonterminal (.seq q γ t)] F := by
  induction h with
  | nil p => exact (cfg_produces_of_mem ((pda_rule_mem (p₀ := p₀) (r₀ := r₀)).2.1 p)).single
  | @cons p Y t β s F _ ih =>
    obtain ⟨m, hm, hs⟩ := hγ
    have hmem := (pda_rule_mem (p₀ := p₀) (r₀ := r₀)).2.2.2.2.2 Y β
      (pda_mem_pSuffixes ⟨m, hm, hs⟩) p t s
    have ih' := ih ⟨m, hm, (List.suffix_cons Y β).trans hs⟩
    have h1 := cfg_produces_of_mem hmem
    have := cfg_derives_expand (g := pdaGrammar N p₀ r₀) (X := PNT.seq p (Y :: β) s) (S := PNT.seq t β s)
      (pre := [.nonterminal (.pop p Y t)]) (Z := []) (rest := []) h1 ih'
      (by simpa using Relation.ReflTransGen.refl)
    simpa using this

theorem pda_complete {p₀ r₀ : N.Q} (c : N.Q × List T × List N.Γ)
    (h : Relation.ReflTransGen N.Step c (r₀, [], [])) :
    ∃ s F, PChain N c.1 c.2.2 s F ∧
      (pdaGrammar N p₀ r₀).Derives (F ++ [.nonterminal (.emp s r₀)]) (c.2.1.map .terminal) := by
  have hR := pda_rule_mem (N := N) (p₀ := p₀) (r₀ := r₀)
  induction h using Relation.ReflTransGen.head_induction_on with
  | refl =>
    exact ⟨r₀, [], .nil r₀, (cfg_produces_of_mem (hR.1 r₀)).single⟩
  | head hst _ ih =>
    obtain ⟨s, F, hch, hd⟩ := ih
    rw [pda_step_iff] at hst
    obtain ⟨p, a, X, q, γ, w', β, hm, rfl, rfl⟩ := hst
    obtain ⟨t, F1, F2, rfl, h1, h2⟩ := pChain_append hch
    have hseq : (pdaGrammar N p₀ r₀).Derives [.nonterminal (.seq q γ t)] F1 :=
      pChain_seq ⟨_, hm, List.suffix_refl _⟩ h1
    have hmap : (a.toList ++ w').map (Symbol.terminal (N := PNT N.Q N.Γ)) =
        tmOf N a ++ w'.map .terminal := by simp [tmOf]
    cases X with
    | some Y =>
      refine ⟨s, _, .cons h2, ?_⟩
      have hP := cfg_produces_of_mem (hR.2.2.2.2.1 p a Y q γ hm t)
      have := cfg_derives_expand (g := pdaGrammar N p₀ r₀) (pre := tmOf N a) (Z := []) (rest := F2 ++ [.nonterminal (.emp s r₀)])
        (by simpa using hP) hseq (by simpa using hd)
      simpa [hmap] using this
    | none =>
      cases β with
      | nil =>
        cases h2
        refine ⟨p, [], .nil p, ?_⟩
        have hP := cfg_produces_of_mem (hR.2.2.1 p a q γ hm s r₀)
        have := cfg_derives_expand (g := pdaGrammar N p₀ r₀) (pre := tmOf N a) (Z := [.nonterminal (.emp s r₀)]) (rest := [])
          (by simpa using hP) hseq (by simpa using hd)
        simpa [hmap] using this
      | cons Y β =>
        cases h2 with
        | @cons _ _ u _ _ F3 h3 =>
          refine ⟨s, _, .cons h3, ?_⟩
          have hP := cfg_produces_of_mem (hR.2.2.2.1 p a q γ hm Y t u)
          have := cfg_derives_expand (g := pdaGrammar N p₀ r₀) (pre := tmOf N a) (Z := [.nonterminal (.pop t Y u)])
            (rest := F3 ++ [.nonterminal (.emp s r₀)])
            (by simpa using hP) hseq (by simpa using hd)
          simpa [hmap] using this

theorem pdaGrammar_language (p₀ r₀ : N.Q) :
    (pdaGrammar N p₀ r₀).language =
      {w | Relation.ReflTransGen N.Step (p₀, w, []) (r₀, [], [])} := by
  ext w
  rw [ContextFreeGrammar.mem_language_iff]
  change _ ↔ Relation.ReflTransGen N.Step (p₀, w, []) (r₀, [], [])
  constructor
  · intro h
    have := pda_gen_sound (cfgen_of_derives h)
    obtain ⟨w1, w2, rfl, h1, h2⟩ := this
    simp only [FSem] at h2
    subst h2
    simpa [PSem] using h1
  · intro h
    obtain ⟨s, F, hch, hd⟩ := pda_complete (p₀ := p₀) _ h
    cases hch
    simpa using hd

end PDAGrammarComplete

section PlusPDA

variable {T : Type}

attribute [local instance] PDA.finQ PDA.finΓ

open Classical in
/-- The machine `M` with a drain state `none`: from an accepting state it may jump to `none`,
and there it may pop any symbol. It reaches `none` with an empty pile exactly when `M` accepts. -/
noncomputable abbrev plusPDA (M : PDA T) : PDA T where
  Q := Option M.Q
  Γ := M.Γ
  start := some M.start
  accept := ∅
  moves := M.moves.image (fun m => (some m.1, m.2.1, m.2.2.1, some m.2.2.2.1, m.2.2.2.2)) ∪
    (Finset.univ.filter (· ∈ M.accept)).image (fun f => (some f, none, none, none, [])) ∪
    (Finset.univ : Finset M.Γ).image (fun Y => (none, none, some Y, none, []))

theorem plus_step_cases (M : PDA T) {e e' : Option M.Q × List T × List M.Γ}
    (h : (plusPDA M).Step e e') :
    (∃ p a X q γ w s, (p, a, X, q, γ) ∈ M.moves ∧ e = (some p, a.toList ++ w, X.toList ++ s) ∧
      e' = (some q, w, γ ++ s)) ∨
    (∃ f ∈ M.accept, ∃ w s, e = (some f, w, s) ∧ e' = (none, w, s)) ∨
    (∃ Y w s, e = (none, w, Y :: s) ∧ e' = (none, w, s)) := by
  rw [pda_step_iff] at h
  obtain ⟨q, a, X, q', γ, w, s, hm, rfl, rfl⟩ := h
  simp only [Finset.mem_union, Finset.mem_image, Finset.mem_filter, Finset.mem_univ,
    true_and] at hm
  rcases hm with (⟨⟨p, a', X', q'', γ'⟩, hm, h⟩ | ⟨f, hf, h⟩) | ⟨Y, h⟩
  · simp only [Prod.mk.injEq] at h
    obtain ⟨rfl, rfl, rfl, rfl, rfl⟩ := h
    exact Or.inl ⟨p, a', X', q'', γ', w, s, hm, rfl, rfl⟩
  · simp only [Prod.mk.injEq] at h
    obtain ⟨rfl, rfl, rfl, rfl, rfl⟩ := h
    exact Or.inr (Or.inl ⟨f, hf, w, s, by simp, by simp⟩)
  · simp only [Prod.mk.injEq] at h
    obtain ⟨rfl, rfl, rfl, rfl, rfl⟩ := h
    exact Or.inr (Or.inr ⟨Y, w, s, by simp, by simp⟩)

theorem plus_reach_lift (M : PDA T) {c c' : M.Q × List T × List M.Γ}
    (h : Relation.ReflTransGen M.Step c c') :
    Relation.ReflTransGen (plusPDA M).Step (some c.1, c.2.1, c.2.2) (some c'.1, c'.2.1, c'.2.2) := by
  induction h with
  | refl => exact Relation.ReflTransGen.refl
  | tail _ hst ih =>
    refine ih.tail ?_
    rw [pda_step_iff] at hst
    obtain ⟨q, a, X, q', γ, w, s, hm, rfl, rfl⟩ := hst
    refine PDA.Step.move (M := plusPDA M) ?_
    simp only [Finset.mem_union, Finset.mem_image]
    exact Or.inl (Or.inl ⟨_, hm, rfl⟩)

theorem plus_drain (M : PDA T) (w : List T) (s : List M.Γ) :
    Relation.ReflTransGen (plusPDA M).Step (none, w, s) (none, w, []) := by
  induction s with
  | nil => exact Relation.ReflTransGen.refl
  | cons Y s ih =>
    refine Relation.ReflTransGen.head ?_ ih
    refine PDA.Step.move (M := plusPDA M) (a := none) (X := some Y) (γ := []) ?_
    simp only [Finset.mem_union, Finset.mem_image, Finset.mem_univ, true_and]
    exact Or.inr ⟨Y, rfl⟩

/-- What a run of the drained machine knows about the original machine. -/
def PlusInv (M : PDA T) (w : List T) (e : Option M.Q × List T × List M.Γ) : Prop :=
  (∃ q, e.1 = some q ∧ Relation.ReflTransGen M.Step (M.start, w, []) (q, e.2.1, e.2.2)) ∨
  (e.1 = none ∧ ∃ f ∈ M.accept, ∃ s, Relation.ReflTransGen M.Step (M.start, w, []) (f, e.2.1, s))

theorem plusInv_step (M : PDA T) (w : List T) {e e' : Option M.Q × List T × List M.Γ}
    (he : PlusInv M w e) (h : (plusPDA M).Step e e') : PlusInv M w e' := by
  rcases plus_step_cases M h with ⟨p, a, X, q, γ, w0, s, hm, rfl, rfl⟩ |
    ⟨f, hf, w0, s, rfl, rfl⟩ | ⟨Y, w0, s, rfl, rfl⟩
  · rcases he with ⟨q0, hq, hr⟩ | ⟨hq, -⟩
    · simp only [Option.some.injEq] at hq
      subst hq
      exact Or.inl ⟨q, rfl, hr.tail (PDA.Step.move hm)⟩
    · simp at hq
  · rcases he with ⟨q0, hq, hr⟩ | ⟨hq, -⟩
    · simp only [Option.some.injEq] at hq
      subst hq
      exact Or.inr ⟨rfl, f, hf, s, hr⟩
    · simp at hq
  · rcases he with ⟨q0, hq, -⟩ | ⟨-, f, hf, s', hr⟩
    · simp at hq
    · exact Or.inr ⟨rfl, f, hf, s', hr⟩

theorem plus_language (M : PDA T) :
    M.language = {w | Relation.ReflTransGen (plusPDA M).Step (some M.start, w, []) (none, [], [])} := by
  ext w
  change (∃ q ∈ M.accept, ∃ s : List M.Γ,
    Relation.ReflTransGen M.Step (M.start, w, []) (q, [], s)) ↔ _
  constructor
  · rintro ⟨f, hf, s, h⟩
    have h1 := plus_reach_lift M h
    have h2 : (plusPDA M).Step (some f, [], s) (none, [], s) := by
      refine PDA.Step.move (M := plusPDA M) (a := none) (X := none) (γ := []) (w := []) (s := s) ?_
      simp only [Finset.mem_union, Finset.mem_image, Finset.mem_filter, Finset.mem_univ, true_and]
      exact Or.inl (Or.inr ⟨f, hf, rfl⟩)
    exact (h1.tail h2).trans (plus_drain M [] s)
  · intro h
    have key : ∀ e', Relation.ReflTransGen (plusPDA M).Step (some M.start, w, []) e' →
        PlusInv M w e' := by
      intro e' h
      induction h with
      | refl => exact Or.inl ⟨M.start, rfl, Relation.ReflTransGen.refl⟩
      | tail _ hs ih => exact plusInv_step M w ih hs
    rcases key _ h with ⟨q, hq, -⟩ | ⟨-, f, hf, s, hr⟩
    · simp at hq
    · exact ⟨f, hf, s, hr⟩

end PlusPDA

section GrammarPDA

variable {T : Type}

open Classical in
/-- The finitely many symbols a grammar's rules mention, with its start variable. -/
noncomputable def cfgSyms (g : ContextFreeGrammar T) : Finset (Symbol T g.NT) :=
  insert (.nonterminal g.initial)
    (g.rules.biUnion fun r => insert (.nonterminal r.input) r.output.toFinset)

open Classical in
/-- A symbol as a pile symbol (`none` is the bottom marker). -/
noncomputable def cfgEnc (g : ContextFreeGrammar T) (x : Symbol T g.NT) : Option (cfgSyms g) :=
  if h : x ∈ cfgSyms g then some ⟨x, h⟩ else none

open Classical in
/-- The letters a grammar's rules mention. -/
noncomputable def cfgTerms (g : ContextFreeGrammar T) : Finset T :=
  (cfgSyms g).biUnion fun x => match x with
    | .terminal t => {t}
    | .nonterminal _ => ∅

open Classical in
/-- The stack machine of a grammar: state 0 starts, state 1 expands and matches, state 2
accepts. -/
noncomputable abbrev cfgPDA (g : ContextFreeGrammar T) : PDA T where
  Q := Fin 3
  Γ := Option (cfgSyms g)
  start := 0
  accept := {2}
  moves := insert (0, none, none, 1, [cfgEnc g (.nonterminal g.initial), none])
    (insert (1, none, some none, 2, [])
      (g.rules.image (fun r => (1, none, some (cfgEnc g (.nonterminal r.input)), 1,
          r.output.map (cfgEnc g))) ∪
        (cfgTerms g).image (fun t => (1, some t, some (cfgEnc g (.terminal t)), 1, []))))

theorem cfgSyms_mem (g : ContextFreeGrammar T) :
    Symbol.nonterminal g.initial ∈ cfgSyms g ∧
    ∀ r ∈ g.rules, Symbol.nonterminal r.input ∈ cfgSyms g ∧ ∀ x ∈ r.output, x ∈ cfgSyms g := by
  classical
  unfold cfgSyms
  refine ⟨Finset.mem_insert_self _ _, fun r hr => ⟨?_, fun x hx => ?_⟩⟩
  · exact Finset.mem_insert_of_mem (Finset.mem_biUnion.mpr ⟨r, hr, Finset.mem_insert_self _ _⟩)
  · exact Finset.mem_insert_of_mem (Finset.mem_biUnion.mpr
      ⟨r, hr, Finset.mem_insert_of_mem (List.mem_toFinset.mpr hx)⟩)

theorem cfgTerms_mem (g : ContextFreeGrammar T) (t : T) :
    t ∈ cfgTerms g ↔ Symbol.terminal t ∈ cfgSyms g := by
  classical
  unfold cfgTerms
  rw [Finset.mem_biUnion]
  constructor
  · rintro ⟨x, hx, ht⟩
    cases x with
    | terminal t' =>
      simp only [Finset.mem_singleton] at ht
      subst ht
      exact hx
    | nonterminal _ => simp at ht
  · intro h
    exact ⟨_, h, by simp⟩

theorem cfgEnc_of_mem (g : ContextFreeGrammar T) {x : Symbol T g.NT} (h : x ∈ cfgSyms g) :
    cfgEnc g x = some ⟨x, h⟩ := by
  unfold cfgEnc
  rw [dite_eq_left]

theorem cfgEnc_inj (g : ContextFreeGrammar T) {x y : Symbol T g.NT} (hx : x ∈ cfgSyms g)
    (hy : y ∈ cfgSyms g) (h : cfgEnc g x = cfgEnc g y) : x = y := by
  rw [cfgEnc_of_mem g hx, cfgEnc_of_mem g hy] at h
  simpa using h

theorem cfgEnc_ne_none (g : ContextFreeGrammar T) {x : Symbol T g.NT} (hx : x ∈ cfgSyms g) :
    cfgEnc g x ≠ none := by
  rw [cfgEnc_of_mem g hx]
  simp

theorem cfg_step_cases (g : ContextFreeGrammar T)
    {e e' : Fin 3 × List T × List (Option (cfgSyms g))} (h : (cfgPDA g).Step e e') :
    ∃ w s, (e = (0, w, s) ∧ e' = (1, w, [cfgEnc g (.nonterminal g.initial), none] ++ s)) ∨
      (e = (1, w, none :: s) ∧ e' = (2, w, s)) ∨
      (∃ r ∈ g.rules, e = (1, w, cfgEnc g (.nonterminal r.input) :: s) ∧
        e' = (1, w, r.output.map (cfgEnc g) ++ s)) ∨
      (∃ t, Symbol.terminal t ∈ cfgSyms g ∧ e = (1, t :: w, cfgEnc g (.terminal t) :: s) ∧
        e' = (1, w, s)) := by
  rw [pda_step_iff] at h
  obtain ⟨q, a, X, q', γ, w, s, hm, rfl, rfl⟩ := h
  refine ⟨w, s, ?_⟩
  simp only [Finset.mem_insert, Finset.mem_union, Finset.mem_image, Prod.mk.injEq] at hm
  rcases hm with ⟨rfl, rfl, rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl, rfl, rfl⟩ |
    ⟨r, hr, rfl, rfl, rfl, rfl, rfl⟩ | ⟨t, ht, rfl, rfl, rfl, rfl, rfl⟩
  · exact Or.inl ⟨rfl, rfl⟩
  · exact Or.inr (Or.inl ⟨rfl, rfl⟩)
  · exact Or.inr (Or.inr (Or.inl ⟨r, hr, rfl, rfl⟩))
  · exact Or.inr (Or.inr (Or.inr ⟨t, (cfgTerms_mem g t).mp ht, rfl, rfl⟩))

/-- What a run of the grammar's machine knows. -/
def CfgInv (g : ContextFreeGrammar T) (w : List T)
    (e : Fin 3 × List T × List (Option (cfgSyms g))) : Prop :=
  e = (0, w, []) ∨
  (∃ p α, e.1 = 1 ∧ w = p ++ e.2.1 ∧ (∀ x ∈ α, x ∈ cfgSyms g) ∧
    e.2.2 = α.map (cfgEnc g) ++ [none] ∧
    g.Derives [.nonterminal g.initial] (p.map .terminal ++ α)) ∨
  (∃ p, e.1 = 2 ∧ w = p ++ e.2.1 ∧ g.Derives [.nonterminal g.initial] (p.map .terminal))

theorem cfgInv_step (g : ContextFreeGrammar T) (w : List T)
    {e e' : Fin 3 × List T × List (Option (cfgSyms g))}
    (he : CfgInv g w e) (h : (cfgPDA g).Step e e') : CfgInv g w e' := by
  obtain ⟨w0, s, ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨r, hr, rfl, rfl⟩ | ⟨t, ht, rfl, rfl⟩⟩ :=
    cfg_step_cases g h
  · rcases he with he | ⟨p, α, hq, -⟩ | ⟨p, hq, -⟩
    · simp only [Prod.mk.injEq] at he
      obtain ⟨rfl, rfl⟩ := he.2
      refine Or.inr (Or.inl ⟨[], [.nonterminal g.initial], rfl, by simp, ?_, by simp,
        by simpa using (Relation.ReflTransGen.refl :
          g.Derives [.nonterminal g.initial] [.nonterminal g.initial])⟩)
      simpa using (cfgSyms_mem g).1
    · simp at hq
    · simp at hq
  · -- accept move
    rcases he with he | ⟨p, α, -, hw, hα, hs, hd⟩ | ⟨p, hq, -⟩
    · simp only [Prod.mk.injEq] at he
      exact absurd he.1 (by decide)
    · simp only at hw hs
      rcases α with _ | ⟨x, α⟩
      · simp only [List.map_nil, List.nil_append, List.cons.injEq] at hs
        obtain ⟨-, rfl⟩ := hs
        exact Or.inr (Or.inr ⟨p, rfl, hw, by simpa using hd⟩)
      · simp only [List.map_cons, List.cons_append, List.cons.injEq] at hs
        exact absurd hs.1.symm (cfgEnc_ne_none g (hα x List.mem_cons_self))
    · simp at hq
  · -- expand move
    rcases he with he | ⟨p, α, -, hw, hα, hs, hd⟩ | ⟨p, hq, -⟩
    · simp only [Prod.mk.injEq] at he
      exact absurd he.1 (by decide)
    · simp only at hw hs
      have hA := ((cfgSyms_mem g).2 r hr)
      rcases α with _ | ⟨x, α⟩
      · simp only [List.map_nil, List.nil_append, List.cons.injEq] at hs
        exact absurd hs.1 (cfgEnc_ne_none g hA.1)
      · simp only [List.map_cons, List.cons_append, List.cons.injEq] at hs
        obtain ⟨hx, rfl⟩ := hs
        have hx' := cfgEnc_inj g hA.1 (hα x List.mem_cons_self) hx
        subst hx'
        refine Or.inr (Or.inl ⟨p, r.output ++ α, rfl, hw, ?_, by simp, ?_⟩)
        · intro y hy
          rcases List.mem_append.mp hy with hy | hy
          · exact hA.2 y hy
          · exact hα y (List.mem_cons_of_mem _ hy)
        · refine hd.tail ⟨r, hr, ?_⟩
          have := ContextFreeRule.rewrites_of_exists_parts r (p.map Symbol.terminal) α
          simpa using this
    · simp at hq
  · -- match move
    rcases he with he | ⟨p, α, -, hw, hα, hs, hd⟩ | ⟨p, hq, -⟩
    · simp only [Prod.mk.injEq] at he
      exact absurd he.1 (by decide)
    · simp only at hw hs
      rcases α with _ | ⟨x, α⟩
      · simp only [List.map_nil, List.nil_append, List.cons.injEq] at hs
        exact absurd hs.1 (cfgEnc_ne_none g ht)
      · simp only [List.map_cons, List.cons_append, List.cons.injEq] at hs
        obtain ⟨hx, rfl⟩ := hs
        have hx' := cfgEnc_inj g ht (hα x List.mem_cons_self) hx
        subst hx'
        refine Or.inr (Or.inl ⟨p ++ [t], α, rfl, by simp [hw], fun y hy => hα y
          (List.mem_cons_of_mem _ hy), rfl, by simpa using hd⟩)
    · simp at hq

theorem cfg_run (g : ContextFreeGrammar T) {α : List (Symbol T g.NT)} {w : List T}
    (h : CFGen g α w) : (∀ x ∈ α, x ∈ cfgSyms g) → ∀ u s,
      Relation.ReflTransGen (cfgPDA g).Step (1, w ++ u, α.map (cfgEnc g) ++ s) (1, u, s) := by
  induction h with
  | nil => intro _ u s; exact Relation.ReflTransGen.refl
  | @term t α w _ ih =>
    intro hα u s
    have ht : Symbol.terminal t ∈ cfgSyms g := hα _ List.mem_cons_self
    have hs : (cfgPDA g).Step (1, t :: (w ++ u), cfgEnc g (.terminal t) :: (α.map (cfgEnc g) ++ s))
        (1, w ++ u, α.map (cfgEnc g) ++ s) := by
      refine PDA.Step.move (M := cfgPDA g) (a := some t) (X := some (cfgEnc g (.terminal t)))
        (γ := []) ?_
      simp only [Finset.mem_insert, Finset.mem_union, Finset.mem_image]
      exact Or.inr (Or.inr (Or.inr ⟨t, (cfgTerms_mem g t).mpr ht, rfl⟩))
    exact Relation.ReflTransGen.head hs (ih (fun x hx => hα x (List.mem_cons_of_mem _ hx)) u s)
  | @nt r α w hr _ ih =>
    intro hα u s
    have hA := (cfgSyms_mem g).2 r hr
    have hs : (cfgPDA g).Step (1, w ++ u, cfgEnc g (.nonterminal r.input) :: (α.map (cfgEnc g) ++ s))
        (1, w ++ u, r.output.map (cfgEnc g) ++ (α.map (cfgEnc g) ++ s)) := by
      refine PDA.Step.move (M := cfgPDA g) (a := none)
        (X := some (cfgEnc g (.nonterminal r.input))) (γ := r.output.map (cfgEnc g)) ?_
      simp only [Finset.mem_insert, Finset.mem_union, Finset.mem_image]
      exact Or.inr (Or.inr (Or.inl ⟨r, hr, rfl⟩))
    have := ih (by
      intro y hy
      rcases List.mem_append.mp hy with hy | hy
      · exact hA.2 y hy
      · exact hα y (List.mem_cons_of_mem _ hy)) u s
    rw [List.map_append, List.append_assoc] at this
    exact Relation.ReflTransGen.head hs this

theorem cfgPDA_language (g : ContextFreeGrammar T) : (cfgPDA g).language = g.language := by
  ext w
  change (∃ q ∈ ({2} : Set (Fin 3)), ∃ s : List (Option (cfgSyms g)),
    Relation.ReflTransGen (cfgPDA g).Step (0, w, []) (q, [], s)) ↔
    g.Derives [.nonterminal g.initial] (w.map .terminal)
  constructor
  · rintro ⟨q, hq, s, h⟩
    have key : ∀ e', Relation.ReflTransGen (cfgPDA g).Step (0, w, []) e' → CfgInv g w e' := by
      intro e' h
      induction h with
      | refl => exact Or.inl rfl
      | tail _ hs ih => exact cfgInv_step g w ih hs
    rw [Set.mem_singleton_iff] at hq
    subst hq
    rcases key _ h with he | ⟨p, α, hq, -⟩ | ⟨p, -, hw, hd⟩
    · simp at he
    · simp at hq
    · simp only [List.append_nil] at hw
      subst hw
      exact hd
  · intro h
    refine ⟨2, rfl, [], ?_⟩
    have hgen := cfgen_of_derives h
    have hinit := (cfgSyms_mem g).1
    have h0 : (cfgPDA g).Step (0, w, []) (1, w, [cfgEnc g (.nonterminal g.initial), none]) := by
      refine PDA.Step.move (M := cfgPDA g) (q := 0) (q' := 1) (a := none) (X := none)
        (γ := [cfgEnc g (.nonterminal g.initial), none]) (w := w) (s := []) ?_
      simp only [Finset.mem_insert, Finset.mem_union, Finset.mem_image]
      exact Or.inl trivial
    have h1 := cfg_run g hgen (by simpa using hinit) [] [none]
    simp only [List.append_nil, List.map_cons, List.map_nil, List.cons_append,
      List.nil_append] at h1
    have h2 : (cfgPDA g).Step (1, [], [none]) (2, [], []) := by
      refine PDA.Step.move (M := cfgPDA g) (q := 1) (q' := 2) (a := none) (X := some none)
        (γ := []) (w := []) (s := []) ?_
      simp only [Finset.mem_insert, Finset.mem_union, Finset.mem_image]
      exact Or.inr (Or.inl trivial)
    exact (Relation.ReflTransGen.head h0 h1).tail h2

end GrammarPDA

#print axioms pda_step_iff
#print axioms pda_reach_lift
#print axioms pda_reach_lift'
#print axioms cfgen_terminals
#print axioms cfgen_expand
#print axioms cfgen_of_derives
#print axioms fsem_append
#print axioms fsem_tm
#print axioms fsem_nt2
#print axioms fsem_nt1
#print axioms pda_rules_cases
#print axioms pda_rule_sound
#print axioms pda_gen_sound
#print axioms pChain_append
#print axioms pda_mem_pSuffixes
#print axioms pda_rule_mem
#print axioms cfg_produces_of_mem
#print axioms cfg_derives_expand
#print axioms pChain_seq
#print axioms pda_complete
#print axioms pdaGrammar_language
#print axioms plus_step_cases
#print axioms plus_reach_lift
#print axioms plus_drain
#print axioms plusInv_step
#print axioms plus_language
#print axioms cfgSyms_mem
#print axioms cfgTerms_mem
#print axioms cfgEnc_of_mem
#print axioms cfgEnc_inj
#print axioms cfgEnc_ne_none
#print axioms cfg_step_cases
#print axioms cfgInv_step
#print axioms cfg_run
#print axioms cfgPDA_language

/-- **Grammars and stack machines describe the same languages.** A language has a
context-free grammar (every rule has one variable alone on its left) exactly when some stack
machine (finite states, a pile with no height limit read only at the top, guessing allowed)
accepts it. -/
theorem context_free_iff_stack_machine {T : Type} (L : Language T) :
    L.IsContextFree ↔ ∃ M : PDA T, M.language = L := by
  constructor
  · rintro ⟨g, rfl⟩
    exact ⟨cfgPDA g, cfgPDA_language g⟩
  · rintro ⟨M, rfl⟩
    exact ⟨pdaGrammar (plusPDA M) (some M.start) none,
      (pdaGrammar_language _ _).trans (plus_language M).symm⟩

/-! ## Arch songs -/

/-- The sections of a song: verse, chorus, bridge. -/
inductive SongPart
  | v
  | c
  | b
  deriving DecidableEq

open SongPart

/-- An arch song: the sheet reads the same backwards (a mirror) and has exactly one bridge.
In a mirror the single bridge is forced into the exact middle. -/
def IsArchSong (w : List SongPart) : Prop :=
  w.reverse = w ∧ w.count SongPart.b = 1

instance : DecidablePred IsArchSong := fun w =>
  inferInstanceAs (Decidable (w.reverse = w ∧ w.count SongPart.b = 1))

/-- The arch grammar S → vSv | cSc | b, with one variable `S` (here the single element of
`Unit`). -/
def archGrammar : ContextFreeGrammar SongPart where
  NT := Unit
  initial := ()
  rules :=
    {⟨(), [.terminal v, .nonterminal (), .terminal v]⟩,
     ⟨(), [.terminal c, .nonterminal (), .terminal c]⟩,
     ⟨(), [.terminal b]⟩}

theorem list_append_cons_cancel {α : Type} {a : α} :
    ∀ {x x' y y' : List α}, x ++ a :: y = x' ++ a :: y' → a ∉ x → a ∉ x' → x = x' ∧ y = y'
  | [], [], _, _, h, _, _ => by simpa using h
  | [], z :: x', _, _, h, _, h' => by
      simp only [List.nil_append, List.cons_append, List.cons.injEq] at h
      exact absurd (h.1 ▸ List.mem_cons_self) h'
  | z :: x, [], _, _, h, h1, _ => by
      simp only [List.nil_append, List.cons_append, List.cons.injEq] at h
      exact absurd (h.1 ▸ List.mem_cons_self) h1
  | z :: x, z' :: x', _, _, h, h1, h2 => by
      simp only [List.cons_append, List.cons.injEq] at h
      obtain ⟨rfl, h⟩ := h
      have := list_append_cons_cancel h (fun hm => h1 (List.mem_cons_of_mem _ hm))
        (fun hm => h2 (List.mem_cons_of_mem _ hm))
      exact ⟨by rw [this.1], this.2⟩

theorem list_append_cons_cancel' {α : Type} {a : α} {x x' y y' : List α}
    (h : x ++ a :: y = x' ++ a :: y') (h1 : a ∉ x') (h2 : a ∉ y') : x = x' ∧ y = y' := by
  classical
  have hc := congrArg (List.count a) h
  simp only [List.count_append, List.count_cons_self, List.count_eq_zero.mpr h1,
    List.count_eq_zero.mpr h2] at hc
  exact list_append_cons_cancel h (List.count_eq_zero.mp (by omega)) h1

theorem arch_song_iff (w : List SongPart) :
    IsArchSong w ↔ ∃ u : List SongPart, b ∉ u ∧ w = u ++ b :: u.reverse := by
  constructor
  · rintro ⟨hr, hc⟩
    have hb : b ∈ w := List.count_pos_iff.mp (by omega)
    obtain ⟨s, t, rfl⟩ := List.append_of_mem hb
    simp only [List.count_append, List.count_cons_self] at hc
    have hs : b ∉ s := List.count_eq_zero.mp (by omega)
    have ht : b ∉ t := List.count_eq_zero.mp (by omega)
    refine ⟨s, hs, ?_⟩
    simp only [List.reverse_append, List.reverse_cons, List.append_assoc, List.singleton_append] at hr
    have := list_append_cons_cancel hr (by simpa using ht) hs
    rw [← this.1, List.reverse_reverse]
  · rintro ⟨u, hu, rfl⟩
    refine ⟨by simp, ?_⟩
    simp [List.count_append, List.count_eq_zero.mpr hu, List.count_reverse]

theorem archGrammar_rules_cases (r : ContextFreeRule SongPart archGrammar.NT)
    (hr : r ∈ archGrammar.rules) :
    r = ⟨archGrammar.initial, [.terminal v, .nonterminal archGrammar.initial, .terminal v]⟩ ∨
    r = ⟨archGrammar.initial, [.terminal c, .nonterminal archGrammar.initial, .terminal c]⟩ ∨
    r = ⟨archGrammar.initial, [.terminal b]⟩ := by
  have h : ∀ r : ContextFreeRule SongPart Unit, r ∈ archGrammar.rules →
      r = ⟨(), [.terminal v, .nonterminal (), .terminal v]⟩ ∨
      r = ⟨(), [.terminal c, .nonterminal (), .terminal c]⟩ ∨
      r = ⟨(), [.terminal b]⟩ := by
    intro r hr
    unfold archGrammar at hr
    simp at hr
    exact hr
  exact h r hr

theorem archGrammar_rules_mem (x : SongPart) :
    (⟨archGrammar.initial, [.terminal b]⟩ : ContextFreeRule SongPart archGrammar.NT) ∈
      archGrammar.rules ∧
    (x ≠ b → (⟨archGrammar.initial, [.terminal x, .nonterminal archGrammar.initial, .terminal x]⟩ :
      ContextFreeRule SongPart archGrammar.NT) ∈ archGrammar.rules) := by
  have h : (⟨(), [.terminal b]⟩ : ContextFreeRule SongPart Unit) ∈ archGrammar.rules ∧
      (x ≠ b → (⟨(), [.terminal x, .nonterminal (), .terminal x]⟩ :
        ContextFreeRule SongPart Unit) ∈ archGrammar.rules) := by
    unfold archGrammar
    cases x <;> simp
  exact h

theorem archGrammar_produces_of (r : ContextFreeRule SongPart archGrammar.NT)
    (hr : r ∈ archGrammar.rules) (hin : r.input = archGrammar.initial)
    (P Q : List (Symbol SongPart archGrammar.NT)) :
    archGrammar.Produces (P ++ [.nonterminal archGrammar.initial] ++ Q) (P ++ r.output ++ Q) :=
  ⟨r, hr, hin ▸ ContextFreeRule.rewrites_of_exists_parts _ P Q⟩

def ArchForm (x : List (Symbol SongPart archGrammar.NT)) : Prop :=
  ∃ u : List SongPart, b ∉ u ∧
    (x = u.map .terminal ++ [.nonterminal archGrammar.initial] ++ u.reverse.map .terminal ∨
     x = u.map .terminal ++ [.terminal b] ++ u.reverse.map .terminal)

theorem archForm_produces {x y : List (Symbol SongPart archGrammar.NT)} (hx : ArchForm x)
    (h : archGrammar.Produces x y) : ArchForm y := by
  obtain ⟨r, hr, hrw⟩ := h
  obtain ⟨P, Q, rfl, rfl⟩ := hrw.exists_parts
  obtain ⟨u, hu, hx⟩ := hx
  have hin : r.input = archGrammar.initial := rfl
  rcases hx with hx | hx
  · rw [hin] at hx
    simp only [List.append_assoc, List.singleton_append] at hx
    have hc := list_append_cons_cancel' hx (by simp) (by simp)
    obtain ⟨rfl, rfl⟩ := hc
    rcases archGrammar_rules_cases r hr with rfl | rfl | rfl
    · refine ⟨u ++ [v], by simp [hu], Or.inl ?_⟩
      simp
    · refine ⟨u ++ [c], by simp [hu], Or.inl ?_⟩
      simp
    · exact ⟨u, hu, Or.inr (by simp)⟩
  · exfalso
    have : (Symbol.nonterminal r.input : Symbol SongPart archGrammar.NT) ∈
        u.map .terminal ++ [.terminal b] ++ u.reverse.map .terminal := by
      rw [← hx]; simp
    simp at this

theorem archForm_derives {y : List (Symbol SongPart archGrammar.NT)}
    (h : archGrammar.Derives [.nonterminal archGrammar.initial] y) : ArchForm y := by
  induction h with
  | refl => exact ⟨[], by simp, Or.inl (by simp)⟩
  | tail _ hp ih => exact archForm_produces ih hp

theorem archGrammar_derives_arch (u : List SongPart) (hu : b ∉ u) :
    archGrammar.Derives [.nonterminal archGrammar.initial]
      (u.map .terminal ++ [.nonterminal archGrammar.initial] ++ u.reverse.map .terminal) := by
  induction u with
  | nil => simpa using Relation.ReflTransGen.refl
  | cons x u ih =>
    have hxb : x ≠ b := fun h => hu (h ▸ List.mem_cons_self)
    have ih := ih (fun h => hu (List.mem_cons_of_mem _ h))
    have h1 := archGrammar_produces_of _ ((archGrammar_rules_mem x).2 hxb) rfl [] []
    have h2 := (ih.append_left [.terminal x]).append_right [.terminal x]
    have := h1.trans_derives h2
    simpa using this

#print axioms list_append_cons_cancel
#print axioms list_append_cons_cancel'
#print axioms arch_song_iff
#print axioms archGrammar_rules_cases
#print axioms archGrammar_rules_mem
#print axioms archGrammar_produces_of
#print axioms archForm_produces
#print axioms archForm_derives
#print axioms archGrammar_derives_arch

/-- **The grammar builds exactly the arch songs.** The strings of letters that S → vSv | cSc | b
can reach from S are exactly the arch songs. -/
theorem archGrammar_language_eq_arch_songs :
    archGrammar.language = {w | IsArchSong w} := by
  ext w
  rw [ContextFreeGrammar.mem_language_iff]
  change _ ↔ IsArchSong w
  rw [arch_song_iff]
  constructor
  · intro h
    obtain ⟨u, hu, hx | hx⟩ := archForm_derives h
    · exfalso
      have : (Symbol.nonterminal archGrammar.initial : Symbol SongPart archGrammar.NT) ∈
          w.map .terminal := by rw [hx]; simp
      simp at this
    · refine ⟨u, hu, ?_⟩
      have : w.map (Symbol.terminal (N := archGrammar.NT)) =
          (u ++ b :: u.reverse).map .terminal := by rw [hx]; simp
      exact List.map_injective_iff.mpr (fun _ _ h => Symbol.terminal.inj h) this
  · rintro ⟨u, hu, rfl⟩
    have h1 := archGrammar_derives_arch u hu
    have h2 := archGrammar_produces_of _ (archGrammar_rules_mem b).1 rfl
        (u.map .terminal) (u.reverse.map .terminal)
    have := h1.trans_produces h2
    simpa using this

/-- The states of the hand-built machine: start, up, down, accept. -/
inductive HState
  | start
  | up
  | down
  | accept
  deriving DecidableEq

instance : Fintype HState :=
  ⟨{.start, .up, .down, .accept}, by intro x; cases x <;> simp⟩

/-- The pile symbols of the hand-built machine: v, c and the bottom marker ⊥. -/
inductive HStack
  | v
  | c
  | bot
  deriving DecidableEq

instance : Fintype HStack :=
  ⟨{.v, .c, .bot}, by intro x; cases x <;> simp⟩

/-- The card's hand-built machine. From start, put ⊥ on the pile and go to up. In up, push
every verse or chorus read; the bridge switches to down. In down, each section read must
match the top, which is popped. With the sheet finished and ⊥ on top, pop it and accept. -/
def handMachine : PDA SongPart where
  Q := HState
  Γ := HStack
  start := .start
  accept := {.accept}
  moves :=
    {(.start, none, none, .up, [.bot]),
     (.up, some v, none, .up, [.v]),
     (.up, some c, none, .up, [.c]),
     (.up, some b, none, .down, []),
     (.down, some v, some .v, .down, []),
     (.down, some c, some .c, .down, []),
     (.down, none, some .bot, .accept, [])}

def hsym : SongPart → HStack
  | .v => .v
  | .c => .c
  | .b => .bot

def HInv (w : List SongPart) (cfg : HState × List SongPart × List HStack) : Prop :=
  cfg = (.start, w, []) ∨
  (∃ u : List SongPart, b ∉ u ∧ cfg.1 = .up ∧ w = u ++ cfg.2.1 ∧ cfg.2.2 = u.reverse.map hsym ++ [.bot]) ∨
  (∃ y z : List SongPart, b ∉ y ∧ b ∉ z ∧ cfg.1 = .down ∧ w = z.reverse ++ y.reverse ++ b :: y ++ cfg.2.1 ∧
    cfg.2.2 = z.map hsym ++ [.bot]) ∨
  (∃ u : List SongPart, b ∉ u ∧ cfg.1 = .accept ∧ w = u ++ b :: u.reverse ++ cfg.2.1)

theorem hand_moves_cases (m : HState × Option SongPart × Option HStack × HState × List HStack)
    (hm : m ∈ handMachine.moves) :
    m = (.start, none, none, .up, [.bot]) ∨ m = (.up, some v, none, .up, [.v]) ∨
    m = (.up, some c, none, .up, [.c]) ∨ m = (.up, some b, none, .down, []) ∨
    m = (.down, some v, some .v, .down, []) ∨ m = (.down, some c, some .c, .down, []) ∨
    m = (.down, none, some .bot, .accept, []) := by
  unfold handMachine at hm
  simpa using hm

theorem hand_step_cases {e e' : HState × List SongPart × List HStack}
    (h : handMachine.Step e e') : ∃ (w : List SongPart) (s : List HStack),
    (e = (.start, w, s) ∧ e' = (.up, w, .bot :: s)) ∨
    (e = (.up, v :: w, s) ∧ e' = (.up, w, .v :: s)) ∨
    (e = (.up, c :: w, s) ∧ e' = (.up, w, .c :: s)) ∨
    (e = (.up, b :: w, s) ∧ e' = (.down, w, s)) ∨
    (e = (.down, v :: w, .v :: s) ∧ e' = (.down, w, s)) ∨
    (e = (.down, c :: w, .c :: s) ∧ e' = (.down, w, s)) ∨
    (e = (.down, w, .bot :: s) ∧ e' = (.accept, w, s)) := by
  rcases h with ⟨hm⟩
  rename_i w s
  refine ⟨w, s, ?_⟩
  rcases hand_moves_cases _ hm with h | h | h | h | h | h | h <;> cases h
  · exact Or.inl ⟨rfl, rfl⟩
  · exact Or.inr (Or.inl ⟨rfl, rfl⟩)
  · exact Or.inr (Or.inr (Or.inl ⟨rfl, rfl⟩))
  · exact Or.inr (Or.inr (Or.inr (Or.inl ⟨rfl, rfl⟩)))
  · exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨rfl, rfl⟩))))
  · exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨rfl, rfl⟩)))))
  · exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr ⟨rfl, rfl⟩)))))

theorem hsym_inj {x y : SongPart} (h : hsym x = hsym y) : x = y := by
  cases x <;> cases y <;> first | rfl | exact absurd h (by decide)

theorem hInv_step (w : List SongPart) (e e' : HState × List SongPart × List HStack)
    (hc : HInv w e) (h : handMachine.Step e e') : HInv w e' := by
  obtain ⟨w0, s, ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ |
    ⟨rfl, rfl⟩⟩ := hand_step_cases h <;> unfold HInv at hc ⊢ <;>
    simp only [Prod.mk.injEq, reduceCtorEq, false_and, and_false, false_or, or_false,
      exists_false, true_and] at hc ⊢
  · obtain ⟨rfl, rfl⟩ := hc
    exact ⟨[], by simp, by simp, by simp⟩
  · obtain ⟨u, hu, rfl, rfl⟩ := hc
    exact ⟨u ++ [v], by simp [hu], by simp, by simp [hsym]⟩
  · obtain ⟨u, hu, rfl, rfl⟩ := hc
    exact ⟨u ++ [c], by simp [hu], by simp, by simp [hsym]⟩
  · obtain ⟨u, hu, rfl, rfl⟩ := hc
    exact ⟨[], u.reverse, by simp, by simpa using hu, by simp, rfl⟩
  · obtain ⟨y, z, hy, hz, rfl, hs⟩ := hc
    rcases z with _ | ⟨z0, z⟩
    · simp at hs
    · simp only [List.map_cons, List.cons_append, List.cons.injEq] at hs
      obtain ⟨h0, rfl⟩ := hs
      obtain rfl : z0 = v := hsym_inj (y := v) h0.symm
      exact ⟨y ++ [v], z, by simp [hy], fun h => hz (List.mem_cons_of_mem _ h), by simp, rfl⟩
  · obtain ⟨y, z, hy, hz, rfl, hs⟩ := hc
    rcases z with _ | ⟨z0, z⟩
    · simp at hs
    · simp only [List.map_cons, List.cons_append, List.cons.injEq] at hs
      obtain ⟨h0, rfl⟩ := hs
      obtain rfl : z0 = c := hsym_inj (y := c) h0.symm
      exact ⟨y ++ [c], z, by simp [hy], fun h => hz (List.mem_cons_of_mem _ h), by simp, rfl⟩
  · obtain ⟨y, z, hy, hz, rfl, hs⟩ := hc
    rcases z with _ | ⟨z0, z⟩
    · exact ⟨y.reverse, by simpa using hy, by simp⟩
    · simp only [List.map_cons, List.cons_append, List.cons.injEq] at hs
      obtain rfl : z0 = b := hsym_inj (y := b) hs.1.symm
      exact absurd List.mem_cons_self hz

theorem hand_mem_moves (x : SongPart) (hx : x ≠ b) :
    ((HState.start, none, none, HState.up, [HStack.bot]) :
      HState × Option SongPart × Option HStack × HState × List HStack) ∈ handMachine.moves ∧
    ((HState.up, some x, none, HState.up, [hsym x]) :
      HState × Option SongPart × Option HStack × HState × List HStack) ∈ handMachine.moves ∧
    ((HState.up, some b, none, HState.down, []) :
      HState × Option SongPart × Option HStack × HState × List HStack) ∈ handMachine.moves ∧
    ((HState.down, some x, some (hsym x), HState.down, []) :
      HState × Option SongPart × Option HStack × HState × List HStack) ∈ handMachine.moves ∧
    ((HState.down, none, some HStack.bot, HState.accept, []) :
      HState × Option SongPart × Option HStack × HState × List HStack) ∈ handMachine.moves := by
  unfold handMachine
  cases x <;> simp_all [hsym]

theorem hand_up_run (u : List SongPart) (hu : b ∉ u) (w : List SongPart) (s : List HStack) :
    Relation.ReflTransGen handMachine.Step (HState.up, u ++ w, s)
      (HState.up, w, u.reverse.map hsym ++ s) := by
  induction u generalizing s with
  | nil => exact Relation.ReflTransGen.refl
  | cons x u ih =>
    have hx : x ≠ b := fun h => hu (h ▸ List.mem_cons_self)
    have h1 : handMachine.Step (HState.up, x :: u ++ w, s) (HState.up, u ++ w, hsym x :: s) :=
      PDA.Step.move (M := handMachine) (w := u ++ w) (s := s) (hand_mem_moves x hx).2.1
    have h2 := ih (fun h => hu (List.mem_cons_of_mem _ h)) (hsym x :: s)
    have h3 := Relation.ReflTransGen.head h1 h2
    simpa using h3

theorem hand_down_run (z : List SongPart) (hz : b ∉ z) (w : List SongPart) (s : List HStack) :
    Relation.ReflTransGen handMachine.Step (HState.down, z ++ w, z.map hsym ++ s)
      (HState.down, w, s) := by
  induction z with
  | nil => exact Relation.ReflTransGen.refl
  | cons x z ih =>
    have hx : x ≠ b := fun h => hz (h ▸ List.mem_cons_self)
    have h1 : handMachine.Step (HState.down, x :: z ++ w, hsym x :: (z.map hsym ++ s))
        (HState.down, z ++ w, z.map hsym ++ s) :=
      PDA.Step.move (M := handMachine) (w := z ++ w) (s := z.map hsym ++ s)
        (hand_mem_moves x hx).2.2.2.1
    exact Relation.ReflTransGen.head h1 (ih (fun h => hz (List.mem_cons_of_mem _ h)))

#print axioms hand_moves_cases
#print axioms hand_step_cases
#print axioms hsym_inj
#print axioms hInv_step
#print axioms hand_mem_moves
#print axioms hand_up_run
#print axioms hand_down_run

/-- **The hand-built machine accepts exactly the arch songs.** -/
theorem handMachine_language_eq_arch_songs :
    handMachine.language = {w | IsArchSong w} := by
  ext w
  change (∃ q ∈ handMachine.accept, ∃ s : List handMachine.Γ,
    Relation.ReflTransGen handMachine.Step (handMachine.start, w, []) (q, [], s)) ↔ IsArchSong w
  rw [arch_song_iff]
  constructor
  · rintro ⟨q, hq, s, h⟩
    have key : ∀ e', Relation.ReflTransGen handMachine.Step (HState.start, w, []) e' →
        HInv w e' := by
      intro e' h
      induction h with
      | refl => exact Or.inl rfl
      | tail _ hs ih => exact hInv_step w _ _ ih hs
    have hq' : q = HState.accept := hq
    subst hq'
    have := key _ h
    unfold HInv at this
    simp only [reduceCtorEq, false_and, and_false, false_or, exists_false,
      true_and, List.append_nil] at this
    rcases this with h | h
    · cases h
    · exact h
  · rintro ⟨u, hu, rfl⟩
    have hm := hand_mem_moves v (by decide)
    refine ⟨HState.accept, rfl, [], ?_⟩
    have h0 : handMachine.Step (HState.start, u ++ b :: u.reverse, [])
        (HState.up, u ++ b :: u.reverse, [HStack.bot]) :=
      PDA.Step.move (M := handMachine) (w := u ++ b :: u.reverse) (s := []) hm.1
    have h1 := hand_up_run u hu (b :: u.reverse) [HStack.bot]
    have h2 : handMachine.Step (HState.up, b :: u.reverse, u.reverse.map hsym ++ [HStack.bot])
        (HState.down, u.reverse, u.reverse.map hsym ++ [HStack.bot]) :=
      PDA.Step.move (M := handMachine) (w := u.reverse) (s := u.reverse.map hsym ++ [HStack.bot])
        hm.2.2.1
    have h3 := hand_down_run u.reverse (by simpa using hu) [] [HStack.bot]
    rw [List.append_nil] at h3
    have h4 : handMachine.Step (HState.down, [], [HStack.bot]) (HState.accept, [], []) :=
      PDA.Step.move (M := handMachine) (w := []) (s := []) hm.2.2.2.2
    exact (Relation.ReflTransGen.head h0 h1).trans
      ((Relation.ReflTransGen.head h2 h3).tail h4)

/-! ## The card's worked numbers -/

-- The song sheet vvcbcvv is an arch song; the bad sheet vvcbvcv is not.
example : IsArchSong [v, v, c, b, c, v, v] := by decide
example : ¬ IsArchSong [v, v, c, b, v, c, v] := by decide
-- The depth-4 song vvccbccvv is an arch song; vccv, with no bridge, is not.
example : IsArchSong [v, v, c, c, b, c, c, v, v] := by decide
example : ¬ IsArchSong [v, c, c, v] := by decide
-- Table-method splits: the sum over stretch lengths equals (n³ − n)/6; 56 at 7 sections.
example : ∑ l ∈ Finset.Icc 2 7, (7 - l + 1) * (l - 1) = 56 := by decide
example : ∑ l ∈ Finset.Icc 2 15, (15 - l + 1) * (l - 1) = 560 := by decide
example : (7 ^ 3 - 7) / 6 = 56 ∧ (15 ^ 3 - 15) / 6 = 560 ∧ (101 ^ 3 - 101) / 6 = 171700 := by
  norm_num
-- Arch songs of 1, 3, 5, 7, 9 sections: 1 + 2 + 4 + 8 + 16 = 31; up to 15 sections, 255.
example : ∑ d ∈ Finset.range 5, 2 ^ d = 31 ∧ ∑ d ∈ Finset.range 8, 2 ^ d = 255 := by decide
-- All sheets of 0 to 9 sections over three letters: 29,524.
example : ∑ k ∈ Finset.range 10, 3 ^ k = 29524 := by decide
-- A pile capped at 3 symbols of v or c has 1 + 2 + 4 + 8 = 15 possible contents.
example : ∑ k ∈ Finset.range 4, 2 ^ k = 15 := by decide
-- The ambiguous grammar S → SS | v | c | b: closed form C(12, 6)/7 = 132 parse trees on
-- 7 sections, C(16, 8)/9 = 1430 on 9.
example : Nat.choose 12 6 / 7 = 132 := by decide
example : Nat.choose 16 8 / 9 = 1430 := by decide

#print axioms context_free_iff_stack_machine
#print axioms archGrammar_language_eq_arch_songs
#print axioms handMachine_language_eq_arch_songs
