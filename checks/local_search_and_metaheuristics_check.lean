-- Local search: hill climbing on a timetable makes at most as many improving moves as the clashes it starts with, a move's change in clashes is the partners waiting in the new slot minus those left in the old one, k independent runs that each succeed with chance p succeed at least once with chance 1 - (1 - p)^k, and the card's 8-exam trap checks out.
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Probability.Independence.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Measure.Real

namespace LocalSearchAndMetaheuristics

open Finset

/-! Setting. The exams are a finite type `V` and the slots a type `S`. The clash graph `G` is a
`SimpleGraph V`: two exams are joined when one student sits both. A timetable is a function
`x : V → S` giving each exam its slot. `clashes G x` is `C(x)`: the number of clashing pairs
(edges of `G`) whose two exams sit in the same slot. `partnersIn G x e s` is `n_e(s)`: the
number of exams that clash with `e` and sit in slot `s`. A move sends exam `e` to slot `s'`,
giving the timetable `Function.update x e s'`. -/

variable {V S : Type*} [Fintype V] [DecidableEq V] [DecidableEq S]

/-- `C(x)`: the clashing pairs that share a slot in timetable `x`. -/
def clashes (G : SimpleGraph V) [DecidableRel G.Adj] (x : V → S) : ℕ :=
  #(G.edgeFinset.filter (fun p => Sym2.lift ⟨fun a b => decide (x a = x b),
    fun a b => by simp only [eq_comm]⟩ p = true))

/-- `n_e(s)`: the exams that clash with `e` and sit in slot `s`. -/
def partnersIn (G : SimpleGraph V) [DecidableRel G.Adj] (x : V → S) (e : V) (s : S) : ℕ :=
  #((G.neighborFinset e).filter (fun b => x b = s))

lemma clashes_split (G : SimpleGraph V) [DecidableRel G.Adj] (x : V → S) (e : V) :
    clashes G x =
      #((G.edgeFinset.filter (fun p => Sym2.lift ⟨fun a b => decide (x a = x b),
        fun a b => by simp only [eq_comm]⟩ p = true)).filter (fun p => e ∈ p)) +
      #((G.edgeFinset.filter (fun p => Sym2.lift ⟨fun a b => decide (x a = x b),
        fun a b => by simp only [eq_comm]⟩ p = true)).filter (fun p => e ∉ p)) :=
  (Finset.card_filter_add_card_filter_not _).symm

lemma clashes_at (G : SimpleGraph V) [DecidableRel G.Adj] (y : V → S) (e : V) :
    #((G.edgeFinset.filter (fun p => Sym2.lift ⟨fun a b => decide (y a = y b),
        fun a b => by simp only [eq_comm]⟩ p = true)).filter (fun p => e ∈ p)) =
      #((G.neighborFinset e).filter (fun b => y b = y e)) := by
  symm
  refine Finset.card_bij (fun b _ => s(e, b)) ?_ ?_ ?_
  · intro b hb
    simp only [mem_filter, SimpleGraph.mem_neighborFinset] at hb
    simp only [mem_filter, SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet, Sym2.lift_mk,
      decide_eq_true_eq, Sym2.mem_mk_left, and_true]
    exact ⟨hb.1, hb.2.symm⟩
  · intro a _ b _ h
    exact Sym2.congr_right.1 h
  · intro p hp
    simp only [mem_filter] at hp
    obtain ⟨⟨hpE, hpx⟩, he⟩ := hp
    obtain ⟨b, rfl⟩ := Sym2.mem_iff_exists.1 he
    refine ⟨b, ?_, rfl⟩
    simp only [SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet] at hpE
    simp only [Sym2.lift_mk, decide_eq_true_eq] at hpx
    simp only [mem_filter, SimpleGraph.mem_neighborFinset]
    exact ⟨hpE, hpx.symm⟩

lemma clashes_away (G : SimpleGraph V) [DecidableRel G.Adj] (x : V → S) (e : V) (s' : S) :
    (G.edgeFinset.filter (fun p => Sym2.lift ⟨fun a b => decide (Function.update x e s' a =
        Function.update x e s' b), fun a b => by simp only [eq_comm]⟩ p = true)).filter
        (fun p => e ∉ p) =
      (G.edgeFinset.filter (fun p => Sym2.lift ⟨fun a b => decide (x a = x b),
        fun a b => by simp only [eq_comm]⟩ p = true)).filter (fun p => e ∉ p) := by
  ext p
  induction p using Sym2.ind with
  | h a b =>
    simp only [mem_filter, Sym2.lift_mk, decide_eq_true_eq, Sym2.mem_iff, not_or]
    constructor
    · rintro ⟨⟨h1, h2⟩, ha, hb⟩
      rw [Function.update_of_ne (Ne.symm ha), Function.update_of_ne (Ne.symm hb)] at h2
      exact ⟨⟨h1, h2⟩, ha, hb⟩
    · rintro ⟨⟨h1, h2⟩, ha, hb⟩
      rw [← Function.update_of_ne (Ne.symm ha) s' x, ← Function.update_of_ne (Ne.symm hb) s' x] at h2
      exact ⟨⟨h1, h2⟩, ha, hb⟩

#print axioms clashes_split
#print axioms clashes_at
#print axioms clashes_away

/-- The card's main fact: hill climbing always stops. Clashes are a whole number, never below 0,
and every move hill climbing makes lowers them by at least 1. So any run of timetables
`x₀, x₁, …, x_m` in which each move lowers the clashes has at most `C(x₀)` moves: from 30 clashes,
at most 30 moves, and then the climb must stop. -/
theorem hill_climbing_stops_within_starting_clashes (G : SimpleGraph V) [DecidableRel G.Adj]
    (xs : ℕ → V → S) (m : ℕ)
    (hdown : ∀ i < m, clashes G (xs (i + 1)) < clashes G (xs i)) :
    m ≤ clashes G (xs 0) := by
  have key : ∀ i ≤ m, clashes G (xs i) + i ≤ clashes G (xs 0) := by
    intro i
    induction i with
    | zero => intro _; simp
    | succ n ih =>
      intro h
      have := hdown n (by omega)
      have := ih (by omega)
      omega
  have := key m le_rfl
  omega

/-- The card's formula `Δ = n_e(s') - n_e(s)`: moving exam `e` from its slot `s = x e` to slot
`s'` changes the clashes by the number of clash partners waiting in the new slot minus the number
left behind in the old one. Only exam `e`'s partners matter, because clashes are a sum over pairs. -/
theorem move_change_is_new_partners_minus_old (G : SimpleGraph V) [DecidableRel G.Adj]
    (x : V → S) (e : V) (s' : S) :
    (clashes G (Function.update x e s') : ℤ) - clashes G x =
      (partnersIn G x e s' : ℤ) - partnersIn G x e (x e) := by
  rw [clashes_split G (Function.update x e s') e, clashes_split G x e, clashes_away,
    clashes_at, clashes_at]
  have h : (G.neighborFinset e).filter (fun b => Function.update x e s' b = Function.update x e s' e)
      = (G.neighborFinset e).filter (fun b => x b = s') := by
    apply Finset.filter_congr
    intro b hb
    rw [SimpleGraph.mem_neighborFinset] at hb
    rw [Function.update_self, Function.update_of_ne (G.ne_of_adj hb).symm]
  rw [h]
  unfold partnersIn
  push_cast
  ring

/-- The restart formula. If runs succeed independently, each with chance `p`, then at least one of
`k` runs succeeds with chance `1 - (1 - p)^k`: all `k` fail with chance `(1 - p)^k`. -/
theorem restarts_succeed_with_chance {Ω : Type*} [MeasurableSpace Ω]
    (μ : MeasureTheory.Measure Ω) [MeasureTheory.IsProbabilityMeasure μ]
    (A : ℕ → Set Ω) (hmeas : ∀ i, MeasurableSet (A i))
    (hind : ProbabilityTheory.iIndepSet A μ) (p : ℝ) (hp : ∀ i, μ.real (A i) = p) (k : ℕ) :
    μ.real (⋃ i ∈ range k, A i) = 1 - (1 - p) ^ k := by
  have hU : MeasurableSet (⋃ i ∈ range k, A i) :=
    Finset.measurableSet_biUnion _ (fun i _ => hmeas i)
  have hc : (⋃ i ∈ range k, A i)ᶜ = ⋂ i ∈ range k, (A i)ᶜ := by
    simp only [Set.compl_iUnion]
  have hprod : μ (⋂ i ∈ range k, (A i)ᶜ) = ∏ i ∈ range k, μ (A i)ᶜ :=
    (ProbabilityTheory.iIndepSet_iff A μ).1 hind (range k)
      (fun i _ => (MeasurableSpace.measurableSet_generateFrom rfl).compl)
  have hreal : μ.real (⋂ i ∈ range k, (A i)ᶜ) = (1 - p) ^ k := by
    rw [MeasureTheory.measureReal_def, hprod, ENNReal.toReal_prod]
    have : ∀ i ∈ range k, (μ (A i)ᶜ).toReal = 1 - p := by
      intro i _
      rw [← MeasureTheory.measureReal_def, MeasureTheory.probReal_compl_eq_one_sub (hmeas i), hp i]
    rw [Finset.prod_congr rfl this, Finset.prod_const, Finset.card_range]
  have h1 := MeasureTheory.measureReal_compl (μ := μ) hU
  rw [MeasureTheory.probReal_univ] at h1
  rw [hc, hreal] at h1
  linarith

/-! The card's small case: 8 exams, 13 clashing pairs, 3 slots. -/

/-- The 13 clashing pairs of the card's 8-exam case. -/
def pairs8 : List (ℕ × ℕ) :=
  [(0, 1), (0, 3), (0, 6), (1, 2), (1, 3), (1, 6), (1, 7), (2, 6), (2, 7), (4, 5), (4, 6),
    (5, 6), (5, 7)]

/-- The clash graph of the 8-exam case. -/
def exam8 : SimpleGraph (Fin 8) where
  Adj a b := (a.val, b.val) ∈ pairs8 ∨ (b.val, a.val) ∈ pairs8
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨fun a => by fin_cases a <;> decide⟩

instance : DecidableRel exam8.Adj := fun a b =>
  inferInstanceAs (Decidable ((a.val, b.val) ∈ pairs8 ∨ (b.val, a.val) ∈ pairs8))

/-- The card's trap timetable `[0, 1, 2, 2, 0, 2, 1, 0]`. -/
def trap8 : Fin 8 → Fin 3 := ![0, 1, 2, 2, 0, 2, 1, 0]

-- 8 exams in 3 slots give 3^8 = 6,561 timetables.
example : Fintype.card (Fin 8 → Fin 3) = 6561 := by simp

-- The 8-exam clash graph has 13 clashing pairs.
example : exam8.edgeFinset.card = 13 := by decide

-- The trap has 1 clash.
example : clashes exam8 trap8 = 1 := by decide

-- The trap has 16 moves: 8 exams, 2 other slots each.
example : #(univ.filter (fun m : Fin 8 × Fin 3 => m.2 ≠ trap8 m.1)) = 16 := by decide

-- Every one of those 16 moves adds at least 1 clash, so no level move leads out.
example : ∀ e : Fin 8, ∀ s : Fin 3, s ≠ trap8 e →
    clashes exam8 trap8 + 1 ≤ clashes exam8 (Function.update trap8 e s) := by decide

#print axioms hill_climbing_stops_within_starting_clashes
#print axioms move_change_is_new_partners_minus_old
#print axioms restarts_succeed_with_chance

end LocalSearchAndMetaheuristics
