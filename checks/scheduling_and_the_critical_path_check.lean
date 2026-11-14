-- Scheduling: with fixed whole-day durations, unlimited crews and no loop of arrows, the earliest finish equals the longest chain, each job's earliest and latest starts are longest chains before and after it, its float is the finish minus the longest chain through it, and on one oven shortest-bake-first and earliest-van-first are each best for their own target.
import Mathlib.Logic.Relation
import Mathlib.Order.Bounds.Basic
import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.Rearrangement
import Mathlib.Data.Fintype.Card
import Mathlib.Order.ConditionallyCompleteLattice.Basic
import Mathlib.Order.Lattice.Nat
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open Finset

/-! ### The project

Jobs are the elements of a finite type `α`. Job `j` takes `p j` whole working days.
`prec i j` is an arrow `i → j`: job `i` must finish before job `j` starts.
A schedule gives each job a start day `s j`, counted in working days from handover.
It is valid when every arrow is kept, `s i + p i ≤ s j`; crews are unlimited, so
nothing else limits it. A chain is a list of jobs joined one after another by arrows
(`List.IsChain prec`); its length is the total of its jobs' days. -/

/-- A valid schedule: every arrow `i → j` has job `i` finished by the day job `j` starts. -/
def ValidSchedule {α : Type*} (p : α → ℕ) (prec : α → α → Prop) (s : α → ℕ) : Prop :=
  ∀ i j, prec i j → s i + p i ≤ s j

/-- Under an acyclic precedence relation, a chain never repeats a job. -/
theorem cpm_chain_nodup {α : Type*} (prec : α → α → Prop)
    (hacyclic : ∀ i, ¬ Relation.TransGen prec i i) {c : List α} (hc : c.IsChain prec) :
    c.Nodup := by
  have h1 : c.IsChain (Relation.TransGen prec) := hc.imp fun _ _ h => Relation.TransGen.single h
  have h2 := List.isChain_iff_pairwise.1 h1
  exact h2.imp fun {a b} h hab => by subst hab; exact hacyclic a h

/-- Every chain is at most the total of all durations. -/
theorem cpm_chain_sum_le {α : Type*} [Fintype α] (p : α → ℕ) (prec : α → α → Prop)
    (hacyclic : ∀ i, ¬ Relation.TransGen prec i i) {c : List α} (hc : c.IsChain prec) :
    (c.map p).sum ≤ ∑ j, p j := by
  classical
  rw [← List.sum_toFinset p (cpm_chain_nodup prec hacyclic hc)]
  exact Finset.sum_le_sum_of_subset (Finset.subset_univ _)

/-- In a valid schedule finishing by `F`, a chain starting at `j` fits between `s j` and `F`. -/
theorem cpm_tail_le {α : Type*} (p : α → ℕ) (prec : α → α → Prop) {s : α → ℕ}
    (hs : ValidSchedule p prec s) {F : ℕ} (hF : ∀ k, s k + p k ≤ F) :
    ∀ (c : List α) (j : α), (j :: c).IsChain prec → s j + ((j :: c).map p).sum ≤ F := by
  intro c
  induction c with
  | nil => intro j _; simpa using hF j
  | cons x c ih =>
    intro j hc
    rw [List.isChain_cons_cons] at hc
    have h1 := hs _ _ hc.1
    have h2 := ih x hc.2
    simp only [List.map_cons, List.sum_cons] at h2 ⊢
    omega

/-- In a valid schedule, a chain `x :: c` followed by `j` fits between `s x` and `s j`. -/
theorem cpm_head_le {α : Type*} (p : α → ℕ) (prec : α → α → Prop) {s : α → ℕ}
    (hs : ValidSchedule p prec s) :
    ∀ (c : List α) (x j : α), ((x :: c) ++ [j]).IsChain prec →
      s x + ((x :: c).map p).sum ≤ s j := by
  intro c
  induction c with
  | nil =>
    intro x j hc
    simp only [List.cons_append, List.nil_append, List.isChain_cons_cons,
      List.isChain_singleton, and_true] at hc
    simpa using hs _ _ hc
  | cons y c ih =>
    intro x j hc
    rw [List.cons_append, List.cons_append, List.isChain_cons_cons, ← List.cons_append] at hc
    have h1 := hs _ _ hc.1
    have h2 := ih y j hc.2
    simp only [List.map_cons, List.sum_cons] at h2 ⊢
    omega

/-- In a valid schedule, a chain ending just before `j` fits before `s j`. -/
theorem cpm_before_le {α : Type*} (p : α → ℕ) (prec : α → α → Prop) {s : α → ℕ}
    (hs : ValidSchedule p prec s) (c : List α) (j : α) (hc : (c ++ [j]).IsChain prec) :
    (c.map p).sum ≤ s j := by
  cases c with
  | nil => simp
  | cons x c =>
    have := cpm_head_le p prec hs c x j hc
    omega

/-- Joining a chain ending just before `j` to a chain starting at `j`. -/
theorem cpm_join {α : Type*} (prec : α → α → Prop) {c1 c2 : List α} {j : α}
    (h1 : (c1 ++ [j]).IsChain prec) (h2 : (j :: c2).IsChain prec) :
    (c1 ++ j :: c2).IsChain prec := by
  rw [List.isChain_append] at h1 ⊢
  exact ⟨h1.1, h2, by simpa using h1.2.2⟩

/-- Splitting a chain at a job `j` on it. -/
theorem cpm_split {α : Type*} (prec : α → α → Prop) {c1 c2 : List α} {j : α}
    (h : (c1 ++ j :: c2).IsChain prec) :
    (c1 ++ [j]).IsChain prec ∧ (j :: c2).IsChain prec := by
  rw [List.isChain_append] at h
  refine ⟨?_, h.2.1⟩
  rw [List.isChain_append]
  exact ⟨h.1, List.isChain_singleton j, by simpa using h.2.2⟩

/-- A nonempty set of naturals with an upper bound has a greatest element. -/
theorem cpm_exists_greatest {S : Set ℕ} (hne : S.Nonempty) (B : ℕ) (hB : ∀ x ∈ S, x ≤ B) :
    ∃ T, IsGreatest S T :=
  ⟨sSup S, Nat.sSup_mem hne ⟨B, hB⟩, fun _ hx => le_csSup ⟨B, hB⟩ hx⟩

#print axioms cpm_chain_nodup
#print axioms cpm_chain_sum_le
#print axioms cpm_tail_le
#print axioms cpm_head_le
#print axioms cpm_before_le
#print axioms cpm_join
#print axioms cpm_split
#print axioms cpm_exists_greatest

/-- The critical-path method. For any project whose arrows have no loop, there is one
number `T`, the makespan, that is both the longest chain of must-come-first jobs and the
earliest day any valid schedule can finish. For every job `j`:
* the forward pass: its earliest start `ES` in any valid schedule is the longest chain
  ending just before `j`;
* the backward pass: its latest start `LS` in a valid schedule that still finishes by `T`
  leaves exactly the longest chain from `j` on, so `T - LS` is that chain's length;
* the float: `LS - ES` is `T` minus the longest chain through `j`. So a job has zero float
  exactly when it lies on a longest chain, the critical path. -/
theorem critical_path_makespan_and_float {α : Type*} [Fintype α]
    (p : α → ℕ) (prec : α → α → Prop) (hacyclic : ∀ i, ¬ Relation.TransGen prec i i) :
    ∃ T : ℕ,
      IsGreatest {L | ∃ c : List α, c.IsChain prec ∧ L = (c.map p).sum} T ∧
      IsLeast {F | ∃ s : α → ℕ, ValidSchedule p prec s ∧ ∀ k, s k + p k ≤ F} T ∧
      ∀ j : α, ∃ ES LS : ℕ,
        IsLeast {t | ∃ s : α → ℕ, ValidSchedule p prec s ∧ s j = t} ES ∧
        IsGreatest {L | ∃ c : List α, (c ++ [j]).IsChain prec ∧ L = (c.map p).sum} ES ∧
        IsGreatest {t | ∃ s : α → ℕ, ValidSchedule p prec s ∧ (∀ k, s k + p k ≤ T) ∧ s j = t} LS ∧
        IsGreatest {L | ∃ c : List α, (j :: c).IsChain prec ∧ L = ((j :: c).map p).sum} (T - LS) ∧
        IsGreatest {L | ∃ c : List α, c.IsChain prec ∧ j ∈ c ∧ L = (c.map p).sum}
          (T - (LS - ES)) := by
  classical
  have hsum : ∀ {c : List α}, c.IsChain prec → (c.map p).sum ≤ ∑ j, p j :=
    fun hc => cpm_chain_sum_le p prec hacyclic hc
  obtain ⟨T, hT⟩ := cpm_exists_greatest
    (S := {L | ∃ c : List α, c.IsChain prec ∧ L = (c.map p).sum})
    ⟨0, [], List.isChain_nil, rfl⟩ (∑ j, p j) (by rintro _ ⟨c, hc, rfl⟩; exact hsum hc)
  have hE' : ∀ j, ∃ e, IsGreatest
      {L | ∃ c : List α, (c ++ [j]).IsChain prec ∧ L = (c.map p).sum} e := by
    intro j
    refine cpm_exists_greatest ⟨0, [], by simp, rfl⟩ (∑ j, p j) ?_
    rintro _ ⟨c, hc, rfl⟩
    have := hsum hc
    simp only [List.map_append, List.sum_append] at this
    omega
  choose E hE using hE'
  have hQ' : ∀ j, ∃ q, IsGreatest
      {L | ∃ c : List α, (j :: c).IsChain prec ∧ L = ((j :: c).map p).sum} q := by
    intro j
    refine cpm_exists_greatest ⟨p j, [], List.isChain_singleton j, by simp⟩ (∑ j, p j) ?_
    rintro _ ⟨c, hc, rfl⟩
    exact hsum hc
  choose Q hQ using hQ'
  have hQT : ∀ k, Q k ≤ T := by
    intro k
    obtain ⟨c, hc, he⟩ := (hQ k).1
    exact hT.2 ⟨k :: c, hc, he⟩
  have hpQ : ∀ k, p k ≤ Q k := by
    intro k
    have := (hQ k).2 ⟨[], List.isChain_singleton k, rfl⟩
    simpa using this
  have hEQ : ∀ j, E j + Q j ≤ T := by
    intro j
    obtain ⟨c1, hc1, he1⟩ := (hE j).1
    obtain ⟨c2, hc2, he2⟩ := (hQ j).1
    have := hT.2 ⟨c1 ++ j :: c2, cpm_join prec hc1 hc2, rfl⟩
    simp only [List.map_append, List.sum_append] at this
    omega
  -- The earliest-start schedule.
  have hEvalid : ValidSchedule p prec E := by
    intro i k hik
    obtain ⟨c, hc, he⟩ := (hE i).1
    have hch : ((c ++ [i]) ++ [k]).IsChain prec := by
      have := cpm_join prec hc (c2 := [k]) (List.isChain_cons_cons.2 ⟨hik, List.isChain_singleton k⟩)
      simpa using this
    have := (hE k).2 ⟨c ++ [i], hch, rfl⟩
    simp only [List.map_append, List.sum_append, List.map_cons, List.map_nil, List.sum_cons,
      List.sum_nil] at this
    omega
  have hEfin : ∀ k, E k + p k ≤ T := by
    intro k
    obtain ⟨c, hc, he⟩ := (hE k).1
    have := hT.2 ⟨c ++ [k], hc, rfl⟩
    simp only [List.map_append, List.sum_append, List.map_cons, List.map_nil, List.sum_cons,
      List.sum_nil] at this
    omega
  -- The latest-start schedule.
  have hLvalid : ValidSchedule p prec (fun k => T - Q k) := by
    intro i k hik
    obtain ⟨c, hc, he⟩ := (hQ k).1
    have := (hQ i).2 ⟨k :: c, List.isChain_cons_cons.2 ⟨hik, hc⟩, rfl⟩
    simp only [List.map_cons, List.sum_cons] at this he
    have := hQT i
    show T - Q i + p i ≤ T - Q k
    omega
  have hLfin : ∀ k, T - Q k + p k ≤ T := by
    intro k
    have := hpQ k
    have := hQT k
    omega
  refine ⟨T, hT, ⟨⟨E, hEvalid, hEfin⟩, ?_⟩, ?_⟩
  · rintro F ⟨s, hs, hF⟩
    obtain ⟨c, hc, rfl⟩ := hT.1
    cases c with
    | nil => simp
    | cons j c =>
      have := cpm_tail_le p prec hs hF c j hc
      omega
  intro j
  refine ⟨E j, T - Q j, ⟨⟨E, hEvalid, rfl⟩, ?_⟩, hE j, ⟨⟨fun k => T - Q k, hLvalid, hLfin, rfl⟩, ?_⟩,
    ?_, ?_⟩
  · rintro t ⟨s, hs, rfl⟩
    obtain ⟨c, hc, he⟩ := (hE j).1
    rw [he]
    exact cpm_before_le p prec hs c j hc
  · rintro t ⟨s, hs, hF, rfl⟩
    obtain ⟨c, hc, he⟩ := (hQ j).1
    have := cpm_tail_le p prec hs hF c j hc
    omega
  · rw [show T - (T - Q j) = Q j by have := hQT j; omega]
    exact hQ j
  · rw [show T - (T - Q j - E j) = E j + Q j by have := hEQ j; omega]
    obtain ⟨c1, hc1, he1⟩ := (hE j).1
    obtain ⟨c2, hc2, he2⟩ := (hQ j).1
    refine ⟨⟨c1 ++ j :: c2, cpm_join prec hc1 hc2, by simp, ?_⟩, ?_⟩
    · simp only [List.map_append, List.sum_append]
      omega
    · rintro _ ⟨c, hc, hj, rfl⟩
      obtain ⟨l1, l2, rfl⟩ := List.append_of_mem hj
      obtain ⟨h1, h2⟩ := cpm_split prec hc
      have a := (hE j).2 ⟨l1, h1, rfl⟩
      have b := (hQ j).2 ⟨l2, h2, rfl⟩
      simp only [List.map_append, List.sum_append]
      omega

/-! ### One oven

`n` batches are all ready at minute 0 and each bakes without interruption; batch `b`
takes `p b` minutes and its van leaves at minute `d b`. An order is a permutation
`σ : Equiv.Perm (Fin n)`: position `k` bakes batch `σ k`. The batch in position `k`
comes out at the total bake time of positions `0` to `k`. -/

/-- The completion time of the batch in position `k` of the order `σ`. -/
def completion {n : ℕ} (p : Fin n → ℕ) (σ : Equiv.Perm (Fin n)) (k : Fin n) : ℕ :=
  ∑ i ∈ Iic k, p (σ i)

/-- The total of completion times counts each position's bake once per later-or-equal position. -/
theorem completion_sum_eq {n : ℕ} (p : Fin n → ℕ) (σ : Equiv.Perm (Fin n)) :
    ∑ k, completion p σ k = ∑ i, (univ.filter (fun k => i ≤ k)).card • p (σ i) := by
  unfold completion
  have h : ∀ k : Fin n, Iic k = univ.filter (fun i => i ≤ k) := by
    intro k; ext; simp
  simp_rw [h, Finset.sum_filter]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [← Finset.sum_filter, Finset.sum_const]

#print axioms completion_sum_eq

/-- Shortest processing time first (SPT): an order whose bake times never go down from one
position to the next has a total of completion times no larger than any other order's. -/
theorem shortest_bake_first_minimises_total_wait {n : ℕ} (p : Fin n → ℕ)
    (σ : Equiv.Perm (Fin n)) (hσ : Monotone (p ∘ σ)) (τ : Equiv.Perm (Fin n)) :
    ∑ k, completion p σ k ≤ ∑ k, completion p τ k := by
  rw [completion_sum_eq, completion_sum_eq]
  have hw : Antitone (fun i : Fin n => (univ.filter (fun k => i ≤ k)).card) := by
    intro i j hij
    apply Finset.card_le_card
    intro k hk
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hk ⊢
    exact le_trans hij hk
  have hv := hw.antivary hσ
  have := hv.sum_smul_le_sum_smul_comp_perm (σ := τ.trans σ.symm)
  simpa using this

/-- Earliest due date first (EDD): an order whose van times never go down from one position
to the next has worst lateness no larger than any other order's. Put as bounds: any bound
`L` on every lateness `C - d` in another order `τ` also bounds every lateness in `σ`. -/
theorem earliest_van_first_minimises_worst_lateness {n : ℕ} (p d : Fin n → ℕ)
    (σ : Equiv.Perm (Fin n)) (hσ : Monotone (d ∘ σ)) (τ : Equiv.Perm (Fin n)) (L : ℤ)
    (hτ : ∀ k, (completion p τ k : ℤ) - d (τ k) ≤ L) :
    ∀ k, (completion p σ k : ℤ) - d (σ k) ≤ L := by
  intro k
  obtain ⟨i, hi, hmax⟩ := Finset.exists_max_image (Iic k) (fun i => τ.symm (σ i)) ⟨k, by simp⟩
  have hsub : (Iic k).image σ ⊆ (Iic (τ.symm (σ i))).image τ := by
    intro b hb
    simp only [Finset.mem_image, Finset.mem_Iic] at hb ⊢
    obtain ⟨i', hi', rfl⟩ := hb
    exact ⟨τ.symm (σ i'), hmax i' (by simpa using hi'), by simp⟩
  have hC : completion p σ k ≤ completion p τ (τ.symm (σ i)) := by
    unfold completion
    rw [← Finset.sum_image (f := p) (g := σ) (fun x _ y _ h => σ.injective h),
      ← Finset.sum_image (f := p) (g := τ) (fun x _ y _ h => τ.injective h)]
    exact Finset.sum_le_sum_of_subset hsub
  have hd : d (σ i) ≤ d (σ k) := hσ (by simpa using hi)
  have h := hτ (τ.symm (σ i))
  rw [Equiv.apply_symm_apply] at h
  omega

/-! ### The card's bakery fit-out

Jobs A to I are `0` to `8`: strip out, plumbing, electrics, tiling, ovens, counter,
paint, test bakes, inspection. -/

def shopDays : Fin 9 → ℕ := ![3, 4, 5, 3, 6, 5, 3, 4, 2]

def shopArcs : List (Fin 9 × Fin 9) :=
  [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (5, 6), (4, 7), (6, 8), (7, 8)]

def shopArc (i j : Fin 9) : Prop := (i, j) ∈ shopArcs

instance : DecidableRel shopArc := fun i j => inferInstanceAs (Decidable ((i, j) ∈ shopArcs))

-- Earliest and latest starts from the two passes.
def shopES : Fin 9 → ℕ := ![0, 3, 3, 7, 10, 10, 15, 16, 20]
def shopLS : Fin 9 → ℕ := ![0, 3, 5, 7, 10, 12, 17, 16, 20]

-- The letters A to I are already a topological order: every arrow points forward, so no loop.
example : ∀ i j, shopArc i j → i < j := by decide
-- Every job end to end: 35 days.
example : ∑ j, shopDays j = 35 := by decide
-- Starting every job at its earliest start keeps every arrow and finishes by day 22.
example : ValidSchedule shopDays shopArc shopES := by unfold ValidSchedule; decide
example : ∀ j, shopES j + shopDays j ≤ 22 := by decide
-- The latest starts also keep every arrow and finish by day 22.
example : ValidSchedule shopDays shopArc shopLS := by unfold ValidSchedule; decide
example : ∀ j, shopLS j + shopDays j ≤ 22 := by decide
-- Total float LS - ES: electrics, counter and paint 2 days, the other six 0.
example : (fun j => shopLS j - shopES j) = ![0, 0, 2, 0, 0, 2, 2, 0, 0] := by decide
-- The three chains from strip-out to inspection: 22, 20 and 20 days.
example : [0, 1, 3, 4, 7, 8].IsChain shopArc ∧ (([0, 1, 3, 4, 7, 8] : List (Fin 9)).map shopDays).sum = 22 := by
  decide
example : [0, 1, 3, 5, 6, 8].IsChain shopArc ∧ (([0, 1, 3, 5, 6, 8] : List (Fin 9)).map shopDays).sum = 20 := by
  decide
example : [0, 2, 4, 7, 8].IsChain shopArc ∧ (([0, 2, 4, 7, 8] : List (Fin 9)).map shopDays).sum = 20 := by
  decide
-- Forward pass at the ovens: the longest chain before E is A B D, 10 days.
example : ([0, 1, 3] ++ [4] : List (Fin 9)).IsChain shopArc ∧
    (([0, 1, 3] : List (Fin 9)).map shopDays).sum = 10 := by decide
-- Free float: electrics 10 - 8 = 2, counter 15 - 15 = 0, paint 20 - 18 = 2.
example : shopES 4 - (shopES 2 + shopDays 2) = 2 ∧ shopES 6 - (shopES 5 + shopDays 5) = 0 ∧
    shopES 8 - (shopES 6 + shopDays 6) = 2 := by decide
-- Slip the counter by 2 alone: still a valid schedule finishing by day 22.
example : ValidSchedule (Function.update shopDays 5 7) shopArc ![0, 3, 3, 7, 10, 10, 17, 16, 20] ∧
    ∀ j, (![0, 3, 3, 7, 10, 10, 17, 16, 20] : Fin 9 → ℕ) j + Function.update shopDays 5 7 j ≤ 22 := by
  unfold ValidSchedule; decide
-- Slip both counter and paint by 2: the chain A B D F G I becomes 24 days.
example : (([0, 1, 3, 5, 6, 8] : List (Fin 9)).map
    (Function.update (Function.update shopDays 5 7) 6 5)).sum = 24 := by decide

/-! ### The card's oven

Batches `0` to `4`: croissants, sourdough, baguettes, muffins, birthday cake.
Minutes after 5:00. -/

def bake : Fin 5 → ℕ := ![25, 50, 30, 15, 60]
def van : Fin 5 → ℕ := ![60, 90, 105, 150, 180]

-- SPT: muffins, croissants, baguettes, sourdough, birthday cake.
def sptOrder : Equiv.Perm (Fin 5) := ⟨![3, 0, 2, 1, 4], ![1, 3, 2, 0, 4], by decide, by decide⟩
-- EDD: croissants, sourdough, baguettes, muffins, birthday cake.
def eddOrder : Equiv.Perm (Fin 5) := Equiv.refl _
-- Gut feeling, biggest first: birthday cake, sourdough, baguettes, croissants, muffins.
def gutOrder : Equiv.Perm (Fin 5) := ⟨![4, 1, 2, 0, 3], ![3, 1, 2, 4, 0], by decide, by decide⟩

-- 180 minutes of baking in any order.
example : ∑ b, bake b = 180 := by decide
-- SPT really is shortest first, and EDD earliest van first.
example : ∀ a b : Fin 5, a ≤ b → bake (sptOrder a) ≤ bake (sptOrder b) := by decide
example : ∀ a b : Fin 5, a ≤ b → van (eddOrder a) ≤ van (eddOrder b) := by decide
-- SPT: done at 15, 40, 70, 120, 180; total 425; worst lateness 30 (the sourdough).
example : completion bake sptOrder = ![15, 40, 70, 120, 180] := by decide
example : ∑ k, completion bake sptOrder k = 425 := by decide
example : (∀ k, (completion bake sptOrder k : ℤ) - van (sptOrder k) ≤ 30) ∧
    (completion bake sptOrder 3 : ℤ) - van (sptOrder 3) = 30 := by decide
-- EDD: done at 25, 75, 105, 120, 180; total 505; worst lateness 0.
example : completion bake eddOrder = ![25, 75, 105, 120, 180] := by decide
example : ∑ k, completion bake eddOrder k = 505 := by decide
example : (∀ k, (completion bake eddOrder k : ℤ) - van (eddOrder k) ≤ 0) ∧
    (completion bake eddOrder 2 : ℤ) - van (eddOrder 2) = 0 := by decide
-- Gut: done at 60, 110, 140, 165, 180; total 655; worst lateness 105; 4 vans missed.
example : completion bake gutOrder = ![60, 110, 140, 165, 180] := by decide
example : ∑ k, completion bake gutOrder k = 655 := by decide
example : (∀ k, (completion bake gutOrder k : ℤ) - van (gutOrder k) ≤ 105) ∧
    (completion bake gutOrder 3 : ℤ) - van (gutOrder 3) = 105 := by decide
example : (univ.filter fun k => van (gutOrder k) < completion bake gutOrder k).card = 4 := by decide
-- SPT's total as each bake counted once per batch still waiting.
example : 15 * 5 + 25 * 4 + 30 * 3 + 50 * 2 + 60 * 1 = 425 := by norm_num
-- Sourdough van moved to 120: SPT's worst lateness becomes 0.
example : ∀ k, (completion bake sptOrder k : ℤ) - (Function.update van 1 120) (sptOrder k) ≤ 0 := by
  decide

#print axioms critical_path_makespan_and_float
#print axioms shortest_bake_first_minimises_total_wait
#print axioms earliest_van_first_minimises_worst_lateness
