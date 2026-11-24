-- Games in turns: on a finite game tree with perfect information, backward induction builds a plan that is subgame perfect, it is the only subgame-perfect plan when nobody is ever indifferent, and in the entry game the empty-threat plan (Out, Fight) is a Nash equilibrium that is not subgame perfect.
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

/-! A finite game played in turns, with perfect information, as a tree. A leaf pays each player
`i : ι` the amount `u i`. A decision node is owned by one player `p`, who sees every earlier move
and picks one of its `n + 1` children (at least one). The tree is an inductive type, so it is
finite: every path from the root reaches a leaf.

A node is named by its path from the root: the list of child numbers taken to reach it. A
strategy profile `σ` is a complete plan: for every node, the child number chosen there, including
nodes that are never reached. A number past the last child means the last child. -/

universe u v

inductive GameTree (ι : Type u) (R : Type v) : Type (max u v) where
  | leaf (u : ι → R) : GameTree ι R
  | node (p : ι) (n : ℕ) (kids : Fin (n + 1) → GameTree ι R) : GameTree ι R

namespace GameTree

variable {ι : Type u} {R : Type v}

/-- A strategy profile: at the node with path `q`, choose child number `σ q`. -/
abbrev Profile := List ℕ → ℕ

/-- The child actually taken when the plan says `k` at a node with `n + 1` children. -/
def pick (n k : ℕ) : Fin (n + 1) := ⟨min k n, Nat.lt_succ_of_le (Nat.min_le_right k n)⟩

/-- The plan seen from the node with path `q`: paths are measured from that node. -/
def shift (σ : Profile) (q : List ℕ) : Profile := fun r => σ (q ++ r)

/-- The payoffs reached when everyone follows the profile `σ` from the root. -/
def outcome : GameTree ι R → Profile → ι → R
  | leaf u, _ => u
  | node _ n kids, σ => outcome (kids (pick n (σ []))) (shift σ [(pick n (σ [])).val])

/-- The subgame starting at the node with path `q`, if that path is in the tree. -/
def subgame : GameTree ι R → List ℕ → Option (GameTree ι R)
  | t, [] => some t
  | leaf _, _ :: _ => none
  | node _ n kids, k :: q => if h : k < n + 1 then subgame (kids ⟨k, h⟩) q else none

/-- A decision node, as opposed to a leaf. -/
def IsDecision : GameTree ι R → Prop
  | leaf _ => False
  | node _ _ _ => True

/-- `σ'` is a change by player `i` alone: it differs from `σ` only at decision nodes of `t`
that `i` owns. -/
def IsDeviation (t : GameTree ι R) (i : ι) (σ σ' : Profile) : Prop :=
  ∀ q, σ' q ≠ σ q → ∃ n kids, t.subgame q = some (node i n kids)

/-- Nash equilibrium: no player gains by changing any of their own moves. -/
def IsNash [Preorder R] (t : GameTree ι R) (σ : Profile) : Prop :=
  ∀ (i : ι) (σ' : Profile), IsDeviation t i σ σ' → t.outcome σ' i ≤ t.outcome σ i

/-- Subgame perfect: for every decision node `h`, the part of `σ` inside the subgame at `h` is a
Nash equilibrium of that subgame. -/
def IsSubgamePerfect [Preorder R] (t : GameTree ι R) (σ : Profile) : Prop :=
  ∀ (q : List ℕ) (s : GameTree ι R), t.subgame q = some s → s.IsDecision →
    IsNash s (shift σ q)

/-- `σ` is a result of backward induction: at every decision node `h` of the tree, the child it
picks, `c*(h)`, has the largest value `V_{P(h)}(c)` for the mover among all children, where the
value `V(c)` of a child is the payoff vector reached by playing `σ` from that child. This is the
card's rule `V(h) = V(c*(h))` with `c*(h) = argmax_{c ∈ C(h)} V_{P(h)}(c)`, with any tie-break. -/
def FollowsBackwardInduction [Preorder R] (t : GameTree ι R) (σ : Profile) : Prop :=
  ∀ (q : List ℕ) (p : ι) (n : ℕ) (kids : Fin (n + 1) → GameTree ι R),
    t.subgame q = some (node p n kids) →
    ∀ c : Fin (n + 1), (kids c).outcome (shift σ (q ++ [c.val])) p ≤
      (kids (pick n (σ q))).outcome (shift σ (q ++ [(pick n (σ q)).val])) p

/-- The first child whose value is largest for player `p` (ties go to the first child). -/
def bestChild [LinearOrder R] (p : ι) : (n : ℕ) → (Fin (n + 1) → ι → R) → Fin (n + 1)
  | 0, _ => 0
  | n + 1, v =>
    let c := bestChild p n (fun j => v j.castSucc)
    if v c.castSucc p < v (Fin.last (n + 1)) p then Fin.last (n + 1) else c.castSucc

/-- The backward-induction value `V(h)`: a leaf is worth its payoffs; any other node is worth
what its best child is worth, judged by the mover (ties to the first child). -/
def biValue [LinearOrder R] : GameTree ι R → ι → R
  | leaf u => u
  | node p n kids =>
    let vs := fun c => biValue (kids c)
    vs (bestChild p n vs)

/-- Nobody is indifferent at a node: at every decision node the mover's values of the
different children are all different. -/
def NoTies [LinearOrder R] (t : GameTree ι R) : Prop :=
  ∀ (q : List ℕ) (p : ι) (n : ℕ) (kids : Fin (n + 1) → GameTree ι R),
    t.subgame q = some (node p n kids) →
    Function.Injective (fun c : Fin (n + 1) => biValue (kids c) p)

/-- Number of nodes, and number of decision nodes. -/
def size : GameTree ι R → ℕ
  | leaf _ => 1
  | node _ _ kids => 1 + (List.ofFn fun c => size (kids c)).sum

def decisions : GameTree ι R → ℕ
  | leaf _ => 0
  | node _ _ kids => 1 + (List.ofFn fun c => decisions (kids c)).sum

/-! Helper lemmas for the proofs below. -/

theorem shift_shift (σ : Profile) (a b : List ℕ) : shift (shift σ a) b = shift σ (a ++ b) := by
  funext r; simp [shift, List.append_assoc]

#print axioms shift_shift

theorem pick_val (n : ℕ) (c : Fin (n + 1)) : pick n c.val = c := by
  apply Fin.ext; simp [pick]; omega

#print axioms pick_val

theorem subgame_append (t s : GameTree ι R) (q r : List ℕ) (h : t.subgame q = some s) :
    t.subgame (q ++ r) = s.subgame r := by
  induction q generalizing t with
  | nil => simp [subgame] at h; subst h; simp
  | cons k q ih =>
    cases t with
    | leaf u => simp [subgame] at h
    | node p n kids =>
      simp only [subgame] at h
      split_ifs at h with hk
      simp only [List.cons_append, subgame, hk, ↓reduceDIte]
      exact ih _ h

#print axioms subgame_append

theorem subgame_kid (p : ι) (n : ℕ) (kids : Fin (n + 1) → GameTree ι R) (c : Fin (n + 1)) :
    (node p n kids).subgame [c.val] = some (kids c) := by
  simp [subgame, c.isLt]

#print axioms subgame_kid

theorem follows_sub [Preorder R] {t s : GameTree ι R} {σ : Profile} {q : List ℕ}
    (h : FollowsBackwardInduction t σ) (hs : t.subgame q = some s) :
    FollowsBackwardInduction s (shift σ q) := by
  intro r p n kids hr c
  have := h (q ++ r) p n kids (by rw [subgame_append t s q r hs, hr]) c
  simp only [shift_shift, List.append_assoc] at this ⊢
  exact this

#print axioms follows_sub

theorem dev_sub {t s : GameTree ι R} {i : ι} {σ σ' : Profile} {q : List ℕ}
    (h : IsDeviation t i σ σ') (hs : t.subgame q = some s) :
    IsDeviation s i (shift σ q) (shift σ' q) := by
  intro r hr
  obtain ⟨n, kids, hk⟩ := h (q ++ r) hr
  exact ⟨n, kids, by rw [← subgame_append t s q r hs, hk]⟩

#print axioms dev_sub

theorem spe_sub [Preorder R] {t s : GameTree ι R} {σ : Profile} {q : List ℕ}
    (h : IsSubgamePerfect t σ) (hs : t.subgame q = some s) :
    IsSubgamePerfect s (shift σ q) := by
  intro r x hr hx
  have := h (q ++ r) x (by rw [subgame_append t s q r hs, hr]) hx
  rw [shift_shift]
  exact this

#print axioms spe_sub

theorem noTies_sub [LinearOrder R] {t s : GameTree ι R} {q : List ℕ}
    (h : NoTies t) (hs : t.subgame q = some s) : NoTies s := by
  intro r p n kids hr
  exact h (q ++ r) p n kids (by rw [subgame_append t s q r hs, hr])

#print axioms noTies_sub

theorem bestChild_max [LinearOrder R] (p : ι) :
    ∀ (n : ℕ) (v : Fin (n + 1) → ι → R) (c : Fin (n + 1)), v c p ≤ v (bestChild p n v) p := by
  intro n
  induction n with
  | zero =>
    intro v c
    have hc : c = bestChild p 0 v :=
      Fin.ext (by have := c.isLt; have := (bestChild p 0 v).isLt; omega)
    rw [hc]
  | succ n ih =>
    intro v c
    simp only [bestChild]
    split_ifs with hlt
    · refine Fin.lastCases le_rfl (fun j => ?_) c
      exact (ih (fun j => v j.castSucc) j).trans hlt.le
    · refine Fin.lastCases (not_lt.mp hlt) (fun j => ?_) c
      exact ih (fun j => v j.castSucc) j

#print axioms bestChild_max

theorem nash_of_follows [Preorder R] (t : GameTree ι R) :
    ∀ σ, FollowsBackwardInduction t σ → IsNash t σ := by
  induction t with
  | leaf u => intro σ _ i σ' _; simp [outcome]
  | node p n kids ih =>
    intro σ h i σ' hd
    simp only [outcome]
    by_cases hp : p = i
    · subst hp
      calc (kids (pick n (σ' []))).outcome (shift σ' [(pick n (σ' [])).val]) p
          ≤ (kids (pick n (σ' []))).outcome (shift σ [(pick n (σ' [])).val]) p :=
            ih _ _ (follows_sub h (subgame_kid p n kids _)) p _
              (dev_sub hd (subgame_kid p n kids _))
        _ ≤ _ := h [] p n kids rfl _
    · have h0 : σ' [] = σ [] := by
        by_contra hne
        obtain ⟨m, ks, hm⟩ := hd [] hne
        simp only [subgame, Option.some.injEq, node.injEq] at hm
        exact hp hm.1
      rw [h0]
      exact ih _ _ (follows_sub h (subgame_kid p n kids _)) i _
        (dev_sub hd (subgame_kid p n kids _))

#print axioms nash_of_follows

/-- The plan built by backward induction: at a decision node, the first best child. -/
def biPlan [LinearOrder R] (t : GameTree ι R) : Profile := fun q =>
  match t.subgame q with
  | some (node p n kids) => (bestChild p n fun c => biValue (kids c)).val
  | _ => 0

theorem biPlan_at [LinearOrder R] {t : GameTree ι R} {q : List ℕ} {p : ι} {n : ℕ}
    {kids : Fin (n + 1) → GameTree ι R} (hq : t.subgame q = some (node p n kids)) :
    biPlan t q = (bestChild p n fun c => biValue (kids c)).val := by
  simp [biPlan, hq]

#print axioms biPlan_at

theorem biPlan_outcome [LinearOrder R] (t : GameTree ι R) :
    ∀ (s : GameTree ι R) (q : List ℕ), t.subgame q = some s →
      s.outcome (shift (biPlan t) q) = biValue s := by
  intro s
  induction s with
  | leaf u => intro q _; simp [outcome, biValue]
  | node p n kids ih =>
    intro q hq
    have hσ : shift (biPlan t) q [] = (bestChild p n fun c => biValue (kids c)).val := by
      simp only [shift, List.append_nil]; exact biPlan_at hq
    simp only [outcome, biValue, hσ, pick_val, shift_shift]
    exact ih _ _ (by rw [subgame_append t _ q _ hq, subgame_kid])

#print axioms biPlan_outcome

theorem biPlan_follows [LinearOrder R] (t : GameTree ι R) :
    FollowsBackwardInduction t (biPlan t) := by
  intro q p n kids hq c
  rw [biPlan_at hq, pick_val]
  have hk : ∀ d : Fin (n + 1), t.subgame (q ++ [d.val]) = some (kids d) := by
    intro d; rw [subgame_append t _ q _ hq, subgame_kid]
  rw [biPlan_outcome t _ _ (hk c), biPlan_outcome t _ _ (hk _)]
  exact bestChild_max p n (fun d => biValue (kids d)) c

#print axioms biPlan_follows

theorem eq_bestChild [LinearOrder R] {p : ι} {n : ℕ} {kids : Fin (n + 1) → GameTree ι R}
    (hinj : Function.Injective (fun c : Fin (n + 1) => biValue (kids c) p)) (c : Fin (n + 1))
    (hc : ∀ d, biValue (kids d) p ≤ biValue (kids c) p) :
    c = bestChild p n (fun d => biValue (kids d)) :=
  hinj (le_antisymm (bestChild_max p n (fun d => biValue (kids d)) c) (hc _))

#print axioms eq_bestChild

theorem root_of_follows [LinearOrder R] {p : ι} {n : ℕ} {kids : Fin (n + 1) → GameTree ι R}
    {τ : Profile} (hties : NoTies (node p n kids))
    (hτ : FollowsBackwardInduction (node p n kids) τ)
    (hkids : ∀ d : Fin (n + 1), (kids d).outcome (shift τ [d.val]) = biValue (kids d)) :
    pick n (τ []) = bestChild p n (fun d => biValue (kids d)) := by
  apply eq_bestChild (hties [] p n kids rfl)
  intro d
  have := hτ [] p n kids rfl d
  simp only [List.nil_append, hkids] at this
  exact this

#print axioms root_of_follows

theorem outcome_of_follows [LinearOrder R] (s : GameTree ι R) :
    ∀ τ, NoTies s → FollowsBackwardInduction s τ → s.outcome τ = biValue s := by
  induction s with
  | leaf u => intro τ _ _; simp [outcome, biValue]
  | node p n kids ih =>
    intro τ hties hτ
    have hkids : ∀ d : Fin (n + 1), (kids d).outcome (shift τ [d.val]) = biValue (kids d) :=
      fun d => ih d _ (noTies_sub hties (subgame_kid p n kids d))
        (follows_sub hτ (subgame_kid p n kids d))
    simp only [outcome, biValue, hkids, root_of_follows hties hτ hkids]

#print axioms outcome_of_follows

theorem root_of_spe [LinearOrder R] {p : ι} {n : ℕ} {kids : Fin (n + 1) → GameTree ι R}
    {σ : Profile} (hties : NoTies (node p n kids))
    (hσ : IsSubgamePerfect (node p n kids) σ)
    (hkids : ∀ d : Fin (n + 1), (kids d).outcome (shift σ [d.val]) = biValue (kids d)) :
    pick n (σ []) = bestChild p n (fun d => biValue (kids d)) := by
  apply eq_bestChild (hties [] p n kids rfl)
  intro d
  have hnash := hσ [] (node p n kids) rfl trivial
  have hshift : shift σ [] = σ := by funext r; simp [shift]
  rw [hshift] at hnash
  let σ' : Profile := fun r => if r = [] then d.val else σ r
  have hdev : IsDeviation (node p n kids) p σ σ' := by
    intro r hr
    by_cases h0 : r = []
    · subst h0; exact ⟨n, kids, rfl⟩
    · exact absurd (by simp [σ', h0]) hr
  have := hnash p σ' hdev
  have h1 : σ' [] = d.val := by simp [σ']
  have h2 : shift σ' [d.val] = shift σ [d.val] := by funext r; simp [shift, σ']
  simp only [outcome, h1, pick_val, h2, hkids] at this
  exact this

#print axioms root_of_spe

theorem outcome_of_spe [LinearOrder R] (s : GameTree ι R) :
    ∀ σ, NoTies s → IsSubgamePerfect s σ → s.outcome σ = biValue s := by
  induction s with
  | leaf u => intro σ _ _; simp [outcome, biValue]
  | node p n kids ih =>
    intro σ hties hσ
    have hkids : ∀ d : Fin (n + 1), (kids d).outcome (shift σ [d.val]) = biValue (kids d) :=
      fun d => ih d _ (noTies_sub hties (subgame_kid p n kids d))
        (spe_sub hσ (subgame_kid p n kids d))
    simp only [outcome, biValue, hkids, root_of_spe hties hσ hkids]

#print axioms outcome_of_spe

/-- **Backward induction gives a subgame-perfect plan.** On any finite game tree with perfect
information, settling each last decision first and repeating back to the root builds at least one
complete plan, and every plan built this way (whatever the tie-break) is subgame perfect: at every
decision node, reached or not, nobody gains by changing their own moves from there on. -/
theorem backward_induction_is_subgame_perfect [LinearOrder R] (t : GameTree ι R) :
    (∃ σ : Profile, FollowsBackwardInduction t σ) ∧
      ∀ σ : Profile, FollowsBackwardInduction t σ → IsSubgamePerfect t σ := by
  refine ⟨⟨biPlan t, biPlan_follows t⟩, ?_⟩
  intro σ h q s hs _
  exact nash_of_follows s _ (follows_sub h hs)

/-- **With no ties, it is the only one.** If nobody is ever indifferent at a node, every
subgame-perfect plan chooses, at every decision node of the tree, the same move as the plan built
by backward induction. -/
theorem subgame_perfect_plan_unique_without_ties [LinearOrder R] (t : GameTree ι R)
    (hties : NoTies t) (σ τ : Profile) (hσ : IsSubgamePerfect t σ)
    (hτ : FollowsBackwardInduction t τ) :
    ∀ (q : List ℕ) (p : ι) (n : ℕ) (kids : Fin (n + 1) → GameTree ι R),
      t.subgame q = some (node p n kids) → pick n (σ q) = pick n (τ q) := by
  intro q p n kids hq
  have hts := noTies_sub hties hq
  have hσs := spe_sub hσ hq
  have hτs := follows_sub hτ hq
  have hσ' := root_of_spe hts hσs fun d =>
    outcome_of_spe _ _ (noTies_sub hts (subgame_kid p n kids d))
      (spe_sub hσs (subgame_kid p n kids d))
  have hτ' := root_of_follows hts hτs fun d =>
    outcome_of_follows _ _ (noTies_sub hts (subgame_kid p n kids d))
      (follows_sub hτs (subgame_kid p n kids d))
  simp only [shift, List.append_nil] at hσ' hτ'
  rw [hσ', hτ']

/-! The entry game, in pounds a month, players `0` = rival and `1` = chain. At the root the
rival picks child `0` = In or `1` = Out; after In the chain picks `0` = Fight or
`1` = Accommodate. -/

/-- The entry game: Out (0, 2000), In-Fight (−1000, −1000), In-Accommodate (1000, 1000). -/
def entryGame : GameTree (Fin 2) ℤ :=
  node 0 1 ![node 1 1 ![leaf ![-1000, -1000], leaf ![1000, 1000]], leaf ![0, 2000]]

/-- The plan (Out; Fight): the rival stays out, the chain would fight after In. -/
def outFight : Profile := fun q => if q = [] then 1 else 0

/-- The plan (In; Accommodate). -/
def inAccommodate : Profile := fun q => if q = [] then 0 else 1

/-- **Fighting is an empty threat.** In the entry game, (Out; Fight) is a Nash equilibrium but
it is not subgame perfect, while (In; Accommodate) is what backward induction builds. -/
theorem entry_game_fight_is_empty_threat :
    IsNash entryGame outFight ∧ ¬ IsSubgamePerfect entryGame outFight ∧
      FollowsBackwardInduction entryGame inAccommodate := by
  refine ⟨?_, ?_, ?_⟩
  · intro i σ' hd
    have fix : ∀ q, (∀ n kids, entryGame.subgame q ≠ some (node i n kids)) →
        σ' q = outFight q := by
      intro q hq
      by_contra h
      obtain ⟨n, kids, hk⟩ := hd q h
      exact hq n kids hk
    fin_cases i
    · have h0 : σ' [0] = 0 := fix [0] (by intro n kids h; simp [entryGame, subgame] at h)
      simp only [entryGame, outcome]
      generalize pick 1 (σ' []) = c
      fin_cases c
      · simp [shift, h0, pick, outcome, outFight]
      · simp [outcome, pick, outFight]
    · have h0 : σ' [] = 1 := fix [] (by intro n kids h; simp [entryGame, subgame] at h)
      simp [entryGame, outcome, h0, pick, outFight]
  · intro h
    let σ' : Profile := fun r => if r = [] then 1 else 0
    have hdev : IsDeviation (node 1 1 ![leaf ![-1000, -1000], leaf ![1000, 1000]]) 1
        (shift outFight [0]) σ' := by
      intro r hr
      by_cases h0 : r = []
      · subst h0; exact ⟨1, _, rfl⟩
      · exact absurd (by simp [σ', h0, shift, outFight]) hr
    have := h [0] _ rfl trivial 1 σ' hdev
    exact absurd this (by decide)
  · intro q p n kids hq c
    rcases q with _ | ⟨_ | _ | a, _ | ⟨_ | _ | b, _ | ⟨d, r⟩⟩⟩
    all_goals simp [entryGame, subgame] at hq
    all_goals obtain ⟨rfl, rfl, rfl⟩ := hq
    all_goals fin_cases c <;> decide

/-- The chain-store game with `towns` towns: rival `k` (player `k`) decides on town `k` in
turn, the chain (player `towns`) answers each entry, and an accommodated entry pays the chain
`accChain`. `chainStoreFrom towns accChain r pay` is the part with `r` towns left to play and
`pay` already earned. -/
def chainStoreFrom (towns : ℕ) (accChain : ℤ) :
    ℕ → (Fin (towns + 1) → ℤ) → GameTree (Fin (towns + 1)) ℤ
  | 0, pay => leaf pay
  | r + 1, pay =>
    let k : Fin (towns + 1) := ⟨towns - (r + 1), by omega⟩
    let add := fun (rv cv : ℤ) => chainStoreFrom towns accChain r
      (fun j => pay j + (if j = k then rv else 0) + (if j = Fin.last towns then cv else 0))
    node k 1 ![node (Fin.last towns) 1 ![add (-1000) (-1000), add 1000 accChain], add 0 2000]

def chainStore (towns : ℕ) (accChain : ℤ) : GameTree (Fin (towns + 1)) ℤ :=
  chainStoreFrom towns accChain towns 0

/-- The centipede game: take at move 1, 2, 3, 4 pays (4, 1), (2, 8), (16, 4), (8, 32);
passing to the end pays (64, 16). Child `0` takes, child `1` passes. -/
def centipede : GameTree (Fin 2) ℤ :=
  node 0 1 ![leaf ![4, 1], node 1 1 ![leaf ![2, 8], node 0 1 ![leaf ![16, 4],
    node 1 1 ![leaf ![8, 32], leaf ![64, 16]]]]]

/-- The ultimatum game over £10 = 1000p in 10p steps: the proposer offers `10 o` pence,
`o = 0, …, 100`; the responder rejects (child `0`, both get 0) or accepts (child `1`). -/
def ultimatum : GameTree (Fin 2) ℤ :=
  node 0 100 fun o => node 1 1 ![leaf ![0, 0], leaf ![1000 - 10 * (o.val : ℤ), 10 * (o.val : ℤ)]]

end GameTree

open GameTree

/-! The card's worked numbers. -/

-- Entry game: the chain accommodates, the rival opens, both earn 1000; 5 nodes.
example : bestChild 1 1 ![![-1000, -1000], ![1000, 1000]] = 1 := by decide
example : biValue entryGame = ![1000, 1000] := by decide
example : entryGame.outcome inAccommodate = ![1000, 1000] := by decide
example : entryGame.outcome outFight = ![0, 2000] := by decide
example : entryGame.size = 5 := by decide

-- The entry game is the one-town chain-store game.
example : biValue (chainStore 1 1000) = ![1000, 1000] := by decide

-- Belief a threat needs: (1000 − 0) / (1000 − (−1000)) = 1/2; at 2/5 opening gains 200, at 3/5 loses 200.
example : ((1000 : ℚ) - 0) / (1000 - (-1000)) = 1 / 2 := by norm_num
example : (3 / 5 : ℚ) * 1000 + 2 / 5 * (-1000) = 200 := by norm_num
example : (2 / 5 : ℚ) * 1000 + 3 / 5 * (-1000) = -200 := by norm_num

-- Commitment: a 2500 penalty makes Fight credible (rival Out, chain 2000); 1500 does not.
example : biValue (chainStore 1 (1000 - 2500)) = ![0, 2000] := by decide
example : biValue (chainStore 1 (1000 - 1500)) = ![1000, -500] := by decide

-- Three towns: 53 nodes, 26 decisions, 2^26 profiles; everyone opens, the chain earns 3000.
example : (chainStore 3 1000).size = 53 := by decide
example : (chainStore 3 1000).decisions = 26 := by decide
example : (2 : ℕ) ^ 26 = 67108864 := by norm_num
example : biValue (chainStore 3 1000) = ![1000, 1000, 1000, 3000] := by decide

-- Centipede: backward induction takes at move 1 with (4, 1); passing to the end pays (64, 16).
example : biValue centipede = ![4, 1] := by decide
example : bestChild 0 1 (fun c => biValue (![leaf ![4, 1], centipede] c)) = 0 := by decide
example : centipede.outcome (fun _ => 1) = ![64, 16] := by decide

-- Ultimatum over 1000p: the proposer offers 10p and keeps 990p; 304 nodes.
set_option maxRecDepth 20000 in
example : biValue ultimatum = ![990, 10] := by decide
example : ultimatum.size = 304 := by decide

#print axioms backward_induction_is_subgame_perfect
#print axioms subgame_perfect_plan_unique_without_ties
#print axioms entry_game_fight_is_empty_threat
