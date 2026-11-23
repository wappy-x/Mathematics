-- The language ladder: fixed memory checks a*b*, a stack checks a^n b^n but no DFA does, ww has no context-free grammar, and blank-tape HALT is semidecidable but not decidable.
import Mathlib.Computability.DFA
import Mathlib.Computability.ContextFreeGrammar
import Mathlib.Computability.Halting
import Mathlib.Computability.MyhillNerode
import Mathlib.Data.Set.Finite.Lattice

/-! Mathlib defines regular languages (`Language.IsRegular`, by a DFA), context-free languages
(`Language.IsContextFree`, by a grammar) and semidecidable and decidable predicates (`REPred`,
`ComputablePred`, by partial recursive functions). It has no context-sensitive languages or
linear bounded automata, so rung 1 itself is not stated here: the file states that ww is not
context-free (the lower half of the rung-1 step) and that blank-tape HALT is semidecidable but
not decidable (what the rung-0 step rests on, since every rung-1 language is decidable).
Programs are Mathlib's codes `Nat.Partrec.Code`, and the blank tape is the input 0. -/

/-- The card's two letters: a (a coin, an opening bracket) and b (a button, a closing one). -/
inductive Letter | a | b
  deriving DecidableEq

open Letter

/-- Rung 3's pattern a*b*: every a comes before every b. -/
def abStar : Language Letter := {w | ∃ i j : ℕ, w = List.replicate i a ++ List.replicate j b}

/-- Rung 2's pattern a^n b^n: fully nested brackets, n openings then n closings. -/
def anbn : Language Letter := {w | ∃ n : ℕ, w = List.replicate n a ++ List.replicate n b}

/-- Rung 1's pattern ww: one word written twice. -/
def ww : Language Letter := {w | ∃ u : List Letter, w = u ++ u}

/-- Rung 0's pattern, blank-tape HALT: the programs that stop when started on a blank tape
(input 0). -/
def haltBlank (c : Nat.Partrec.Code) : Prop := (c.eval 0).Dom


namespace LadderAux
open ContextFreeGrammar

/-- Parse forests: `Gen g l w` says the list of symbols `l` yields the terminal word `w`. -/
inductive Gen {T : Type} (g : ContextFreeGrammar T) : List (Symbol T g.NT) → List T → Prop
  | nil : Gen g [] []
  | term (t : T) {l : List (Symbol T g.NT)} {w : List T} :
      Gen g l w → Gen g (Symbol.terminal t :: l) (t :: w)
  | nt (r : ContextFreeRule T g.NT) (hr : r ∈ g.rules) {l : List (Symbol T g.NT)} {v w : List T} :
      Gen g r.output v → Gen g l w → Gen g (Symbol.nonterminal r.input :: l) (v ++ w)

variable {T : Type} {g : ContextFreeGrammar T}

lemma gen_derives {l : List (Symbol T g.NT)} {w : List T} (h : Gen g l w) :
    g.Derives l (w.map Symbol.terminal) := by
  induction h with
  | nil => exact Derives.refl _
  | term t _ ih => simpa using ih.append_left [Symbol.terminal t]
  | @nt r hr l' v w' _ _ ih1 ih2 =>
    have h1 : g.Produces (Symbol.nonterminal r.input :: l') (r.output ++ l') :=
      ⟨r, hr, ContextFreeRule.Rewrites.head l'⟩
    refine h1.single.trans ?_
    rw [List.map_append]
    exact (ih1.append_right _).trans (ih2.append_left _)
#print axioms gen_derives

lemma gen_append {l1 l2 : List (Symbol T g.NT)} {w1 w2 : List T} (h1 : Gen g l1 w1)
    (h2 : Gen g l2 w2) : Gen g (l1 ++ l2) (w1 ++ w2) := by
  induction h1 with
  | nil => simpa using h2
  | term t _ ih => simpa using Gen.term t ih
  | nt r hr _ _ _ ih2 => simpa using Gen.nt r hr ‹_› ih2
#print axioms gen_append

lemma gen_split {l1 l2 : List (Symbol T g.NT)} {w : List T} (h : Gen g (l1 ++ l2) w) :
    ∃ w1 w2, w = w1 ++ w2 ∧ Gen g l1 w1 ∧ Gen g l2 w2 := by
  induction l1 generalizing w with
  | nil => exact ⟨[], w, rfl, Gen.nil, h⟩
  | cons s l ih =>
    cases h with
    | term t h' =>
      obtain ⟨w1, w2, rfl, h1, h2⟩ := ih h'
      exact ⟨t :: w1, w2, rfl, Gen.term t h1, h2⟩
    | nt r hr hv h' =>
      obtain ⟨w1, w2, rfl, h1, h2⟩ := ih h'
      exact ⟨_ ++ w1, w2, by simp, Gen.nt r hr hv h1, h2⟩
#print axioms gen_split

lemma gen_map_terminal (w : List T) : Gen g (w.map Symbol.terminal) w := by
  induction w with
  | nil => exact Gen.nil
  | cons t w ih => exact Gen.term t ih
#print axioms gen_map_terminal

lemma derives_gen {l : List (Symbol T g.NT)} {w : List T}
    (h : g.Derives l (w.map Symbol.terminal)) : Gen g l w := by
  induction h using Relation.ReflTransGen.head_induction_on with
  | refl => exact gen_map_terminal w
  | head hp _ ih =>
    obtain ⟨r, hr, hrw⟩ := hp
    obtain ⟨p, q, rfl, rfl⟩ := hrw.exists_parts
    obtain ⟨w12, w3, rfl, h12, h3⟩ := gen_split ih
    obtain ⟨w1, w2, rfl, h1, h2⟩ := gen_split h12
    have := gen_append h1 (Gen.nt r hr h2 h3)
    simpa using this
#print axioms derives_gen


/-- Pumping down: removing `v` and `y` from `w = u v x y z` leaves a word `l` still yields. -/
def PumpL (g : ContextFreeGrammar T) (p : ℕ) (l : List (Symbol T g.NT)) (w : List T) : Prop :=
  ∃ u v x y z : List T, w = u ++ v ++ x ++ y ++ z ∧ v ++ y ≠ [] ∧ (v ++ x ++ y).length ≤ p ∧
    g.Derives l ((u ++ x ++ z).map Symbol.terminal)

/-- The invariant at one symbol. -/
def SymInv (g : ContextFreeGrammar T) (I : Finset g.NT) (b p : ℕ) (s : Symbol T g.NT)
    (w : List T) : Prop :=
  PumpL g p [s] w ∨ ∃ S ⊆ I, w.length ≤ b ^ S.card ∧
    ∀ Y ∈ S, ∃ u x y : List T, w = u ++ x ++ y ∧
      g.Derives [Symbol.nonterminal Y] (x.map Symbol.terminal)

/-- The invariant at a list of symbols. -/
def ListInv (g : ContextFreeGrammar T) (I : Finset g.NT) (b p : ℕ) (l : List (Symbol T g.NT))
    (w : List T) : Prop :=
  PumpL g p l w ∨ ∃ S ⊆ I, w.length ≤ l.length * b ^ S.card ∧
    ∀ Y ∈ S, ∃ u x y : List T, w = u ++ x ++ y ∧
      g.Derives [Symbol.nonterminal Y] (x.map Symbol.terminal) ∧
      (x.length < w.length ∨ w.length ≤ b ^ S.card)

lemma listInv_nil (I : Finset g.NT) (b p : ℕ) : ListInv g I b p [] [] :=
  Or.inr ⟨∅, Finset.empty_subset _, by simp, by simp⟩
#print axioms listInv_nil

lemma symInv_term (I : Finset g.NT) (b p : ℕ) (t : T) : SymInv g I b p (Symbol.terminal t) [t] :=
  Or.inr ⟨∅, Finset.empty_subset _, by simp, by simp⟩
#print axioms symInv_term

lemma listInv_cons {I : Finset g.NT} {b p : ℕ} (hb : 1 ≤ b) {s : Symbol T g.NT}
    {l : List (Symbol T g.NT)} {w1 w2 : List T}
    (hs : g.Derives [s] (w1.map Symbol.terminal)) (hl : g.Derives l (w2.map Symbol.terminal))
    (h1 : SymInv g I b p s w1) (h2 : ListInv g I b p l w2) :
    ListInv g I b p (s :: l) (w1 ++ w2) := by
  rcases h1 with ⟨u, v, x, y, z, rfl, hvy, hlen, hd⟩ | ⟨S1, hS1, hlen1, hc1⟩
  · left
    refine ⟨u, v, x, y, z ++ w2, by simp, hvy, hlen, ?_⟩
    have := (hd.append_right l).trans (hl.append_left _)
    simpa using this
  rcases h2 with ⟨u, v, x, y, z, rfl, hvy, hlen, hd⟩ | ⟨S2, hS2, hlen2, hc2⟩
  · left
    refine ⟨w1 ++ u, v, x, y, z, by simp, hvy, hlen, ?_⟩
    have := (hs.append_right l).trans (hd.append_left _)
    simpa using this
  right
  simp only [List.length_cons, List.length_append]
  rcases le_total S2.card S1.card with hc | hc
  · have hpow : b ^ S2.card ≤ b ^ S1.card := Nat.pow_le_pow_right hb hc
    refine ⟨S1, hS1, ?_, ?_⟩
    · have := Nat.mul_le_mul_left l.length hpow
      rw [Nat.add_mul, Nat.one_mul]; omega
    · intro Y hY
      obtain ⟨u, x, y, rfl, hd⟩ := hc1 Y hY
      refine ⟨u, x, y ++ w2, by simp, hd, ?_⟩
      simp only [List.length_append] at hlen1 ⊢
      omega
  · have hpow : b ^ S1.card ≤ b ^ S2.card := Nat.pow_le_pow_right hb hc
    refine ⟨S2, hS2, ?_, ?_⟩
    · rw [Nat.add_mul, Nat.one_mul]; omega
    · intro Y hY
      obtain ⟨u, x, y, rfl, hd, hor⟩ := hc2 Y hY
      refine ⟨w1 ++ u, x, y, by simp, hd, ?_⟩
      simp only [List.length_append] at hor ⊢
      omega
#print axioms listInv_cons

lemma symInv_node {I : Finset g.NT} {b p : ℕ} (hb : 1 ≤ b)
    (hbr : ∀ r ∈ g.rules, r.output.length ≤ b) (hI : ∀ r ∈ g.rules, r.input ∈ I)
    (hp : b ^ (I.card + 1) ≤ p) {r : ContextFreeRule T g.NT} (hr : r ∈ g.rules) {v : List T}
    (hv : g.Derives r.output (v.map Symbol.terminal)) (h : ListInv g I b p r.output v) :
    SymInv g I b p (Symbol.nonterminal r.input) v := by
  classical
  have hstep : g.Derives [Symbol.nonterminal r.input] r.output :=
    Produces.single ⟨r, hr, ContextFreeRule.Rewrites.input_output⟩
  rcases h with ⟨u, v', x, y, z, rfl, hvy, hlen, hd⟩ | ⟨S, hS, hlen, hc⟩
  · exact Or.inl ⟨u, v', x, y, z, rfl, hvy, hlen, hstep.trans hd⟩
  have hSI : S.card ≤ I.card := Finset.card_le_card hS
  have hv1 : v.length ≤ b ^ (S.card + 1) := by
    have := Nat.mul_le_mul_right (b ^ S.card) (hbr r hr)
    rw [pow_succ, Nat.mul_comm (b ^ S.card) b]; exact hlen.trans this
  have hvp : v.length ≤ p :=
    hv1.trans ((Nat.pow_le_pow_right hb (by omega)).trans hp)
  by_cases hX : r.input ∈ S
  · obtain ⟨u, x, y, rfl, hd, hor⟩ := hc _ hX
    rcases hor with hlt | hle
    · left
      refine ⟨[], u, x, y, [], by simp, ?_, by simpa using hvp, by simpa using hd⟩
      intro h0
      simp only [List.append_eq_nil_iff] at h0
      obtain ⟨rfl, rfl⟩ := h0
      simp at hlt
    · right
      refine ⟨S, hS, hle, fun Y hY => ?_⟩
      obtain ⟨u', x', y', he, hd', -⟩ := hc Y hY
      exact ⟨u', x', y', he, hd'⟩
  · right
    refine ⟨insert r.input S, Finset.insert_subset (hI r hr) hS, ?_, ?_⟩
    · rw [Finset.card_insert_of_notMem hX]; exact hv1
    · intro Y hY
      rcases Finset.mem_insert.mp hY with rfl | hY
      · exact ⟨[], v, [], by simp, hstep.trans hv⟩
      · obtain ⟨u', x', y', he, hd', -⟩ := hc Y hY
        exact ⟨u', x', y', he, hd'⟩
#print axioms symInv_node

lemma gen_listInv {I : Finset g.NT} {b p : ℕ} (hb : 1 ≤ b)
    (hbr : ∀ r ∈ g.rules, r.output.length ≤ b) (hI : ∀ r ∈ g.rules, r.input ∈ I)
    (hp : b ^ (I.card + 1) ≤ p) {l : List (Symbol T g.NT)} {w : List T} (h : Gen g l w) :
    ListInv g I b p l w := by
  induction h with
  | nil => exact listInv_nil I b p
  | term t hl ih =>
    exact listInv_cons (w1 := [t]) hb (Derives.refl _) (gen_derives hl) (symInv_term I b p t) ih
  | nt r hr hv hl ih1 ih2 =>
    have hd := gen_derives hv
    have hstep : g.Derives [Symbol.nonterminal r.input] r.output :=
      Produces.single ⟨r, hr, ContextFreeRule.Rewrites.input_output⟩
    exact listInv_cons hb (hstep.trans hd) (gen_derives hl)
      (symInv_node hb hbr hI hp hr hd ih1) ih2
#print axioms gen_listInv

/-- The pumping lemma for context-free languages, pumping down only. -/
theorem cf_pump_down (g : ContextFreeGrammar T) : ∃ p : ℕ, 1 ≤ p ∧ ∀ w ∈ g.language,
    p ≤ w.length → ∃ u v x y z : List T, w = u ++ v ++ x ++ y ++ z ∧ v ++ y ≠ [] ∧
      (v ++ x ++ y).length ≤ p ∧ u ++ x ++ z ∈ g.language := by
  classical
  set I := g.rules.image ContextFreeRule.input
  set b := 2 + g.rules.sup (fun r => r.output.length)
  have hb : 1 ≤ b := by omega
  have hb2 : 2 ≤ b := by omega
  have hbr : ∀ r ∈ g.rules, r.output.length ≤ b := fun r hr => by
    have := Finset.le_sup (f := fun r : ContextFreeRule T g.NT => r.output.length) hr
    omega
  have hI : ∀ r ∈ g.rules, r.input ∈ I := fun r hr => Finset.mem_image_of_mem _ hr
  refine ⟨b ^ (I.card + 1), Nat.one_le_pow _ _ (by omega), fun w hw hlen => ?_⟩
  have hg := derives_gen hw
  rcases gen_listInv hb hbr hI le_rfl hg with ⟨u, v, x, y, z, he, hvy, hl, hd⟩ | ⟨S, hS, hl, -⟩
  · exact ⟨u, v, x, y, z, he, hvy, hl, hd⟩
  · exfalso
    have h1 : b ^ S.card ≤ b ^ I.card := Nat.pow_le_pow_right hb (Finset.card_le_card hS)
    have h2 : b ^ I.card < b ^ (I.card + 1) := Nat.pow_lt_pow_right hb2 (by omega)
    simp at hl
    omega
#print axioms cf_pump_down

end LadderAux

namespace LadderAux

lemma W_get (p j : ℕ) :
    (List.replicate p a ++ List.replicate p b ++ (List.replicate p a ++ List.replicate p b))[j]? =
      if j < p then some a else if j < 2 * p then some b else if j < 3 * p then some a
      else if j < 4 * p then some b else none := by
  simp only [List.getElem?_append, List.getElem?_replicate, List.length_append,
    List.length_replicate]
  split_ifs <;> first | rfl | omega
#print axioms W_get

theorem ww_not_cf : ¬ ww.IsContextFree := by
  rintro ⟨g, hg⟩
  obtain ⟨p, hp1, hpump⟩ := cf_pump_down g
  set W := List.replicate p a ++ List.replicate p b ++ (List.replicate p a ++ List.replicate p b)
    with hWdef
  have hWmem : W ∈ g.language := by rw [hg]; exact ⟨_, rfl⟩
  have hWlen : W.length = 4 * p := by simp [hWdef]; omega
  obtain ⟨u, v, x, y, z, hW, hvy, hlen, hmem⟩ := hpump W hWmem (by omega)
  rw [hg] at hmem
  obtain ⟨t, ht⟩ := hmem
  have hvy' : 1 ≤ v.length + y.length := by
    have := List.length_pos_of_ne_nil hvy
    simp only [List.length_append] at this; omega
  have hl1 : u.length + v.length + x.length + y.length + z.length = 4 * p := by
    rw [← hWlen, hW]; simp; omega
  have hl2 : u.length + x.length + z.length = 2 * t.length := by
    have := congrArg List.length ht; simp at this; omega
  simp only [List.length_append] at hlen
  -- reading letters of `u x z`
  have L1 : ∀ i, i < u.length → (u ++ x ++ z)[i]? = W[i]? := by
    intro i hi
    rw [hW, List.append_assoc u x z, List.getElem?_append_left hi]
    simp only [List.append_assoc]
    rw [List.getElem?_append_left hi]
  have L2 : ∀ i, u.length + x.length ≤ i →
      (u ++ x ++ z)[i]? = W[i + v.length + y.length]? := by
    intro i hi
    have e : W = (u ++ v ++ x ++ y) ++ z := by rw [hW]
    rw [e, List.getElem?_append_right (by simpa using hi),
      List.getElem?_append_right (by simp; omega)]
    congr 1; simp; omega
  have L3 : ∀ i, i < t.length → (u ++ x ++ z)[i]? = (u ++ x ++ z)[i + t.length]? := by
    intro i hi
    rw [ht, List.getElem?_append_left hi, List.getElem?_append_right (by omega)]
    congr 1; omega
  have hab : (some a : Option Letter) ≠ some b := by simp
  by_cases hA : 2 * p ≤ u.length
  · have e1 := L3 0 (by omega)
    rw [Nat.zero_add] at e1
    rw [L1 0 (by omega), L1 t.length (by omega), W_get, W_get] at e1
    simp only [show 0 < p by omega, show ¬ t.length < p by omega,
      show t.length < 2 * p by omega, ↓reduceIte] at e1
    exact hab e1
  by_cases hB : u.length + v.length + x.length + y.length ≤ 2 * p
  · have e1 := L3 (t.length - 1) (by omega)
    rw [L2 (t.length - 1) (by omega), L2 (t.length - 1 + t.length) (by omega), W_get,
      W_get] at e1
    simp only [show ¬ t.length - 1 + v.length + y.length < p by omega,
      show ¬ t.length - 1 + v.length + y.length < 2 * p by omega,
      show t.length - 1 + v.length + y.length < 3 * p by omega,
      show ¬ t.length - 1 + t.length + v.length + y.length < p by omega,
      show ¬ t.length - 1 + t.length + v.length + y.length < 2 * p by omega,
      show ¬ t.length - 1 + t.length + v.length + y.length < 3 * p by omega,
      show t.length - 1 + t.length + v.length + y.length < 4 * p by omega,
      ↓reduceIte] at e1
    exact hab e1
  · have e1 := L3 (p - 1) (by omega)
    rw [L1 (p - 1) (by omega), L2 (p - 1 + t.length) (by omega), W_get, W_get] at e1
    simp only [show p - 1 < p by omega,
      show ¬ p - 1 + t.length + v.length + y.length < p by omega,
      show ¬ p - 1 + t.length + v.length + y.length < 2 * p by omega,
      show ¬ p - 1 + t.length + v.length + y.length < 3 * p by omega,
      show p - 1 + t.length + v.length + y.length < 4 * p by omega,
      ↓reduceIte] at e1
    exact hab e1
#print axioms ww_not_cf


/-! Rung 3 inside rung 2: a grammar that copies a DFA's moves. -/

open Classical in
/-- The rules of a DFA's grammar: state `s` rewrites to `c (step s c)`, and to nothing when
`s` accepts. -/
noncomputable def dfaRules {T : Type} [Fintype T] {σ : Type} [Fintype σ] (M : DFA T σ) :
    Finset (ContextFreeRule T σ) :=
  (Finset.univ : Finset (σ × T)).image
      (fun q => ⟨q.1, [Symbol.terminal q.2, Symbol.nonterminal (M.step q.1 q.2)]⟩) ∪
    (Finset.univ.filter (· ∈ M.accept)).image (fun s => ⟨s, []⟩)

/-- The right-linear grammar of a DFA. -/
noncomputable abbrev dfaGrammar {T : Type} [Fintype T] {σ : Type} [Fintype σ] (M : DFA T σ) :
    ContextFreeGrammar T where
  NT := σ
  initial := M.start
  rules := dfaRules M

lemma dfaGrammar_rules {T : Type} [Fintype T] {σ : Type} [Fintype σ] (M : DFA T σ)
    (r : ContextFreeRule T σ) :
    r ∈ (dfaGrammar M).rules ↔ (∃ s c, r = ⟨s, [Symbol.terminal c, Symbol.nonterminal (M.step s c)]⟩) ∨
      (∃ s ∈ M.accept, r = ⟨s, []⟩) := by
  classical
  show r ∈ dfaRules M ↔ _
  simp only [dfaRules, Finset.mem_union, Finset.mem_image, Finset.mem_univ, true_and,
    Finset.mem_filter, Prod.exists]
  constructor
  · rintro (⟨s, c, rfl⟩ | ⟨s, hs, rfl⟩)
    · exact Or.inl ⟨s, c, rfl⟩
    · exact Or.inr ⟨s, hs, rfl⟩
  · rintro (⟨s, c, rfl⟩ | ⟨s, hs, rfl⟩)
    · exact Or.inl ⟨s, c, rfl⟩
    · exact Or.inr ⟨s, hs, rfl⟩
#print axioms dfaGrammar_rules

lemma dfaGrammar_gen {T : Type} [Fintype T] {σ : Type} [Fintype σ] (M : DFA T σ)
    {l : List (Symbol T (dfaGrammar M).NT)} {w : List T} (h : Gen (dfaGrammar M) l w) :
    (l = [] → w = []) ∧ (∀ s, l = [Symbol.nonterminal s] → M.evalFrom s w ∈ M.accept) ∧
      (∀ c s, l = [Symbol.terminal c, Symbol.nonterminal s] →
        ∃ w', w = c :: w' ∧ M.evalFrom s w' ∈ M.accept) := by
  induction h with
  | nil => simp
  | term t _ ih =>
    refine ⟨by simp, by simp, ?_⟩
    intro c s hl
    simp only [List.cons.injEq, Symbol.terminal.injEq] at hl
    obtain ⟨rfl, rfl⟩ := hl
    exact ⟨_, rfl, ih.2.1 s rfl⟩
  | @nt r hr l v w _ _ ih1 ih2 =>
    refine ⟨by simp, ?_, by simp⟩
    intro s hl
    simp only [List.cons.injEq, Symbol.nonterminal.injEq] at hl
    obtain ⟨rfl, rfl⟩ := hl
    rw [ih2.1 rfl, List.append_nil]
    rcases (dfaGrammar_rules M r).mp hr with ⟨s, c, rfl⟩ | ⟨s, hs, rfl⟩
    · obtain ⟨w', rfl, hw'⟩ := ih1.2.2 c _ rfl
      simpa using hw'
    · rw [ih1.1 rfl]; simpa using hs
#print axioms dfaGrammar_gen

lemma dfaGrammar_derives {T : Type} [Fintype T] {σ : Type} [Fintype σ] (M : DFA T σ)
    (w : List T) (s : σ) (h : M.evalFrom s w ∈ M.accept) :
    (dfaGrammar M).Derives [Symbol.nonterminal s] (w.map Symbol.terminal) := by
  induction w generalizing s with
  | nil =>
    have hr : (⟨s, []⟩ : ContextFreeRule T σ) ∈ (dfaGrammar M).rules :=
      (dfaGrammar_rules M _).mpr (Or.inr ⟨s, h, rfl⟩)
    exact ContextFreeGrammar.Produces.single ⟨_, hr, ContextFreeRule.Rewrites.input_output⟩
  | cons c w ih =>
    have hr : (⟨s, [Symbol.terminal c, Symbol.nonterminal (M.step s c)]⟩ :
        ContextFreeRule T σ) ∈ (dfaGrammar M).rules :=
      (dfaGrammar_rules M _).mpr (Or.inl ⟨s, c, rfl⟩)
    have h1 := ContextFreeGrammar.Produces.single ⟨_, hr, ContextFreeRule.Rewrites.input_output⟩
    have h2 := (ih (M.step s c) (by simpa using h)).append_left [Symbol.terminal c]
    exact h1.trans (by simpa using h2)
#print axioms dfaGrammar_derives

lemma isContextFree_of_isRegular {T : Type} [Fintype T] {L : Language T} (hL : L.IsRegular) :
    L.IsContextFree := by
  obtain ⟨σ, _, M, rfl⟩ := hL
  refine ⟨dfaGrammar M, ?_⟩
  ext w
  rw [ContextFreeGrammar.mem_language_iff, DFA.mem_accepts]
  constructor
  · intro h
    exact (dfaGrammar_gen M (derives_gen h)).2.1 _ rfl
  · intro h
    exact dfaGrammar_derives M w M.start h
#print axioms isContextFree_of_isRegular

instance : Fintype Letter := ⟨{a, b}, fun x => by cases x <;> simp⟩

/-! Rung 3: a three-state machine for a*b*. -/

/-- States: 0 still reading a's, 1 reading b's, 2 dead. -/
def abDFA : DFA Letter (Fin 3) where
  step
    | 0, a => 0 | 0, b => 1 | 1, b => 1
    | _, _ => 2
  start := 0
  accept := {0, 1}

lemma abDFA_accept (s : Fin 3) : s ∈ abDFA.accept ↔ s ≠ 2 := by
  show s ∈ ({0, 1} : Set (Fin 3)) ↔ _
  simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
  revert s; decide
#print axioms abDFA_accept

lemma abDFA_two (w : List Letter) : abDFA.evalFrom 2 w = 2 := by
  induction w with
  | nil => rfl
  | cons c w ih => cases c <;> exact ih
#print axioms abDFA_two

lemma abDFA_one (w : List Letter) :
    abDFA.evalFrom 1 w ∈ abDFA.accept ↔ ∃ j, w = List.replicate j b := by
  induction w with
  | nil => exact ⟨fun _ => ⟨0, rfl⟩, fun _ => (abDFA_accept 1).mpr (by decide)⟩
  | cons c w ih =>
    cases c
    · have : abDFA.evalFrom 1 (a :: w) = 2 := abDFA_two w
      rw [this]
      refine ⟨fun h => absurd ((abDFA_accept 2).mp h) (by decide), ?_⟩
      rintro ⟨j, hj⟩
      cases j <;> simp [List.replicate_succ] at hj
    · change abDFA.evalFrom 1 w ∈ abDFA.accept ↔ _
      rw [ih]
      constructor
      · rintro ⟨j, rfl⟩; exact ⟨j + 1, rfl⟩
      · rintro ⟨j, hj⟩
        cases j with
        | zero => simp at hj
        | succ j => simp [List.replicate_succ] at hj; exact ⟨j, hj⟩
#print axioms abDFA_one

lemma abDFA_zero (w : List Letter) :
    abDFA.evalFrom 0 w ∈ abDFA.accept ↔
      ∃ i j, w = List.replicate i a ++ List.replicate j b := by
  induction w with
  | nil => exact ⟨fun _ => ⟨0, 0, rfl⟩, fun _ => (abDFA_accept 0).mpr (by decide)⟩
  | cons c w ih =>
    cases c
    · change abDFA.evalFrom 0 w ∈ abDFA.accept ↔ _
      rw [ih]
      constructor
      · rintro ⟨i, j, rfl⟩; exact ⟨i + 1, j, rfl⟩
      · rintro ⟨i, j, hj⟩
        cases i with
        | zero => cases j <;> simp [List.replicate_succ] at hj
        | succ i => simp [List.replicate_succ] at hj; exact ⟨i, j, hj⟩
    · change abDFA.evalFrom 1 w ∈ abDFA.accept ↔ _
      rw [abDFA_one]
      constructor
      · rintro ⟨j, rfl⟩; exact ⟨0, j + 1, rfl⟩
      · rintro ⟨i, j, hj⟩
        cases i with
        | zero =>
          cases j with
          | zero => simp at hj
          | succ j => simp [List.replicate_succ] at hj; exact ⟨j, hj⟩
        | succ i => simp [List.replicate_succ] at hj
#print axioms abDFA_zero

lemma abStar_isRegular : abStar.IsRegular :=
  ⟨Fin 3, inferInstance, abDFA, by ext w; exact abDFA_zero w⟩
#print axioms abStar_isRegular

/-! Rung 2: the grammar S → a S b | ε. -/

/-- The bracket grammar: one nonterminal, S → a S b and S → ε. -/
abbrev anbnGrammar : ContextFreeGrammar Letter where
  NT := Unit
  initial := ()
  rules := {⟨(), [Symbol.terminal a, Symbol.nonterminal (), Symbol.terminal b]⟩, ⟨(), []⟩}

lemma anbnGrammar_gen {l : List (Symbol Letter anbnGrammar.NT)} {w : List Letter}
    (h : Gen anbnGrammar l w) :
    (l = [] → w = []) ∧ (l = [Symbol.terminal b] → w = [b]) ∧
      (l = [Symbol.nonterminal ()] → w ∈ anbn) ∧
      (l = [Symbol.nonterminal (), Symbol.terminal b] →
        ∃ n, w = List.replicate n a ++ List.replicate n b ++ [b]) ∧
      (l = [Symbol.terminal a, Symbol.nonterminal (), Symbol.terminal b] →
        ∃ n, w = a :: (List.replicate n a ++ List.replicate n b ++ [b])) := by
  induction h with
  | nil => simp
  | term t _ ih =>
    refine ⟨by simp, ?_, by simp, by simp, ?_⟩
    · intro hl
      simp only [List.cons.injEq, Symbol.terminal.injEq] at hl
      obtain ⟨rfl, rfl⟩ := hl
      rw [ih.1 rfl]
    · intro hl
      simp only [List.cons.injEq, Symbol.terminal.injEq] at hl
      obtain ⟨rfl, rfl⟩ := hl
      obtain ⟨n, rfl⟩ := ih.2.2.2.1 rfl
      exact ⟨n, rfl⟩
  | @nt r hr l v w _ _ ih1 ih2 =>
    have hv : v ∈ anbn := by
      have hr' : r = ⟨(), [Symbol.terminal a, Symbol.nonterminal (), Symbol.terminal b]⟩ ∨
          r = ⟨(), []⟩ := by
        rcases Finset.mem_insert.mp hr with h | h
        · exact Or.inl h
        · exact Or.inr (Finset.mem_singleton.mp h)
      rcases hr' with rfl | rfl
      · obtain ⟨n, rfl⟩ := ih1.2.2.2.2 rfl
        exact ⟨n + 1, by rw [List.replicate_succ, List.replicate_succ']; simp⟩
      · rw [ih1.1 rfl]; exact ⟨0, rfl⟩
    refine ⟨by simp, by simp, ?_, ?_, by simp⟩
    · intro hl
      simp only [List.cons.injEq] at hl
      rw [ih2.1 hl.2, List.append_nil]; exact hv
    · intro hl
      simp only [List.cons.injEq] at hl
      obtain ⟨n, rfl⟩ := hv
      refine ⟨n, ?_⟩
      rw [ih2.2.1 hl.2]
#print axioms anbnGrammar_gen

lemma anbnGrammar_derives (n : ℕ) : anbnGrammar.Derives [Symbol.nonterminal ()]
    ((List.replicate n a ++ List.replicate n b).map Symbol.terminal) := by
  induction n with
  | zero =>
    have hr : (⟨(), []⟩ : ContextFreeRule Letter Unit) ∈ anbnGrammar.rules :=
      Finset.mem_insert_of_mem (Finset.mem_singleton_self _)
    exact ContextFreeGrammar.Produces.single ⟨_, hr, ContextFreeRule.Rewrites.input_output⟩
  | succ n ih =>
    have hr : (⟨(), [Symbol.terminal a, Symbol.nonterminal (), Symbol.terminal b]⟩ :
        ContextFreeRule Letter Unit) ∈ anbnGrammar.rules :=
      Finset.mem_insert_self _ _
    have h1 := ContextFreeGrammar.Produces.single ⟨_, hr, ContextFreeRule.Rewrites.input_output⟩
    have h2 := (ih.append_right [Symbol.terminal b]).append_left [Symbol.terminal a]
    have e : List.replicate (n + 1) a ++ List.replicate (n + 1) b =
        [a] ++ (List.replicate n a ++ List.replicate n b) ++ [b] := by
      rw [List.replicate_succ, List.replicate_succ']; simp
    refine h1.trans ?_
    rw [e]
    simpa using h2
#print axioms anbnGrammar_derives

lemma anbn_isContextFree : anbn.IsContextFree := by
  refine ⟨anbnGrammar, ?_⟩
  ext w
  rw [ContextFreeGrammar.mem_language_iff]
  constructor
  · intro h
    exact (anbnGrammar_gen (derives_gen h)).2.2.1 rfl
  · rintro ⟨n, rfl⟩
    exact anbnGrammar_derives n
#print axioms anbn_isContextFree

/-! Rung 2 is above rung 3: no DFA counts the a's. -/

lemma anbn_separates {σ : Type} (M : DFA Letter σ) (hM : M.accepts = anbn) {i j : ℕ}
    (hij : i ≠ j) : M.eval (List.replicate i a) ≠ M.eval (List.replicate j a) := by
  intro he
  have h1 : List.replicate i a ++ List.replicate i b ∈ M.accepts := hM ▸ ⟨i, rfl⟩
  have h2 : List.replicate j a ++ List.replicate i b ∈ M.accepts := by
    rw [DFA.mem_accepts, DFA.eval, DFA.evalFrom_of_append] at h1 ⊢
    rw [← DFA.eval, ← he, DFA.eval]
    exact h1
  rw [hM] at h2
  obtain ⟨n, hn⟩ := h2
  have ha := congrArg (List.count a) hn
  have hb := congrArg (List.count b) hn
  simp [List.count_replicate] at ha hb
  omega
#print axioms anbn_separates

lemma anbn_not_isRegular : ¬ anbn.IsRegular := by
  rintro ⟨σ, _, M, hM⟩
  obtain ⟨i, j, hij, he⟩ :=
    Finite.exists_ne_map_eq_of_infinite (fun n : ℕ => M.eval (List.replicate n a))
  exact anbn_separates M hM hij he
#print axioms anbn_not_isRegular

/-! Finite languages. -/

lemma finite_isRegular {T : Type} (L : Language T) (h : Set.Finite (L : Set (List T))) :
    L.IsRegular := by
  apply Language.IsRegular.of_finite_range_leftQuotient
  have hP : Set.Finite {x : List T | ∃ w ∈ L, x <+: w} := by
    refine Set.Finite.subset (Set.Finite.biUnion h (fun w _ => w.inits.finite_toSet)) ?_
    rintro x ⟨w, hw, hx⟩
    exact Set.mem_biUnion hw (List.mem_inits _ _ |>.mpr hx)
  refine Set.Finite.subset (Set.Finite.insert 0 (Set.Finite.image L.leftQuotient hP)) ?_
  rintro _ ⟨x, rfl⟩
  by_cases hx : ∃ w ∈ L, x <+: w
  · exact Set.mem_insert_of_mem _ ⟨x, hx, rfl⟩
  · refine Set.mem_insert_iff.mpr (Or.inl ?_)
    ext y
    simp only [Language.mem_leftQuotient]
    constructor
    · intro hy; exact absurd ⟨x ++ y, hy, List.prefix_append x y⟩ hx
    · intro hy; exact absurd hy (Language.notMem_zero y)
#print axioms finite_isRegular

end LadderAux

/-- **The language ladder.** Every regular language is context-free; a*b* is regular;
a^n b^n is context-free but not regular, so that inclusion is strict; ww is not context-free;
and blank-tape HALT is semidecidable (a machine says yes on exactly its members) but not
decidable, so it lies above every context-sensitive language. -/
theorem language_ladder :
    (∀ L : Language Letter, L.IsRegular → L.IsContextFree) ∧
    abStar.IsRegular ∧
    (anbn.IsContextFree ∧ ¬ anbn.IsRegular) ∧
    ¬ ww.IsContextFree ∧
    (REPred haltBlank ∧ ¬ ComputablePred haltBlank) := by
  exact ⟨fun L hL => LadderAux.isContextFree_of_isRegular hL, LadderAux.abStar_isRegular,
    ⟨LadderAux.anbn_isContextFree, LadderAux.anbn_not_isRegular⟩, LadderAux.ww_not_cf,
    ComputablePred.halting_problem_re 0, ComputablePred.halting_problem 0⟩

/-- A pattern must be infinite to climb: every finite language is regular, whatever the
alphabet. -/
theorem finite_language_isRegular {T : Type} (L : Language T) (h : Set.Finite (L : Set (List T))) :
    L.IsRegular := by
  exact LadderAux.finite_isRegular L h

/-- Step 2's lower bound: in any DFA for a^n b^n, the beginnings a^i and a^j with i ≠ j end in
different states, since the ending b^i completes one and not the other. So no fixed number of
states is enough. -/
theorem anbn_dfa_separates {σ : Type} (M : DFA Letter σ) (hM : M.accepts = anbn) {i j : ℕ}
    (hij : i ≠ j) : M.eval (List.replicate i a) ≠ M.eval (List.replicate j a) := by
  exact LadderAux.anbn_separates M hM hij

/-! The card's whole-number examples. -/

-- abbaabba is abba written twice; aaaaabbbbb nests five deep; aabbb is in a*b*.
example : [a, b, b, a, a, b, b, a] ∈ ww := ⟨[a, b, b, a], by decide⟩
example : [a, a, a, a, a, b, b, b, b, b] ∈ anbn := ⟨5, by decide⟩
example : [a, a, b, b, b] ∈ abStar := ⟨2, 3, by decide⟩

/-- The card's 8-state checker for fully nested brackets built for depth 3: states 0 to 3 count
the a's, states 4, 5, 6 have 2, 1 or 0 b's still owed, and state 7 is dead. -/
def depth3 : DFA Letter (Fin 8) where
  step
    | 0, a => 1 | 1, a => 2 | 2, a => 3 | 3, a => 7
    | 1, b => 6 | 2, b => 5 | 3, b => 4 | 4, b => 5 | 5, b => 6
    | _, _ => 7
  start := 0
  accept := {0, 6}

-- It accepts aaabbb but sends aaaabbbb, which is in a^n b^n, to the dead state.
example : depth3.eval [a, a, a, b, b, b] = 6 := by decide
example : depth3.eval [a, a, a, a, b, b, b, b] = 7 := by decide
example : [a, a, a, a, b, b, b, b] ∈ anbn := ⟨4, by decide⟩

-- Strings checked for each pattern, lengths 0 to 12: 1 + 2 + 4 + ... + 4,096 = 8,191.
example : ((List.range 13).map (fun n => 2 ^ n)).sum = 8191 := by decide
-- Strings of length 12: 13 in a*b*, and 2^6 = 64 in ww.
example : 12 + 1 = 13 ∧ 2 ^ 6 = 64 := by norm_num
-- Beginnings to tell apart after 8 and 10 letters: 3; k/2 + 2; 2^k.
example : 8 / 2 + 2 = 6 ∧ 2 ^ 8 = 256 ∧ 10 / 2 + 2 = 7 ∧ 2 ^ 10 = 1024 := by norm_num
-- The tape machine on abbaabba: |w|^2 + 3|w| + 1 = 89 steps for |w| = 8.
example : 8 ^ 2 + 3 * 8 + 1 = 89 := by norm_num
-- Configurations of a bounded tape: q |w| g^|w| with q = 10, |w| = 20, g = 4.
example : 10 * 20 * 4 ^ 20 = 219902325555200 := by norm_num
-- 2-state machines: 12 choices per rule, 12^4 = 20,736; 20,736 - 9,784 = 10,952 still running.
example : 2 * 2 * 3 = 12 ∧ 12 ^ 4 = 20736 ∧ 20736 - 9784 = 10952 := by norm_num
-- The depth-3 checker has 4 + 3 + 1 = 8 states; the one for all brackets, 4 + 1 = 5.
example : 4 + 3 + 1 = 8 ∧ 4 + 1 = 5 := by norm_num

#print axioms language_ladder
#print axioms finite_language_isRegular
#print axioms anbn_dfa_separates
