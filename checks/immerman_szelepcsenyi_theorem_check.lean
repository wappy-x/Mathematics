-- NL = coNL: on any finite directed graph, an exact count of the reachable rooms lets a guesser certify that no path exists, and that count is built round by round from the previous one.
import Mathlib.Combinatorics.Digraph.Basic
import Mathlib.Data.Fintype.Card
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Logic.Relation
import Mathlib.Tactic.NormNum

open Finset

/-- `reachWithin G s k` is the card's `R_k`: the rooms reachable from `s` by at most `k` doors.
`R_0 = {s}` and `R_{k+1} = R_k ∪ {v : u → v for some u ∈ R_k}`. -/
def reachWithin {V : Type*} [Fintype V] [DecidableEq V] (G : Digraph V) [DecidableRel G.Adj]
    (s : V) : ℕ → Finset V
  | 0 => {s}
  | k + 1 => reachWithin G s k ∪ univ.filter (fun v => ∃ u ∈ reachWithin G s k, G.Adj u v)


section helpers
variable {V : Type*} [Fintype V] [DecidableEq V] (G : Digraph V) [DecidableRel G.Adj] (s : V)

theorem reachWithin_succ_eq (k : ℕ) :
    reachWithin G s (k + 1) =
      reachWithin G s k ∪ univ.filter (fun v => ∃ u ∈ reachWithin G s k, G.Adj u v) := rfl

theorem mem_reachWithin_succ (k : ℕ) (v : V) :
    v ∈ reachWithin G s (k + 1) ↔
      v ∈ reachWithin G s k ∨ ∃ u ∈ reachWithin G s k, G.Adj u v := by
  rw [reachWithin_succ_eq]; simp

theorem reachWithin_subset_succ (k : ℕ) : reachWithin G s k ⊆ reachWithin G s (k + 1) := by
  rw [reachWithin_succ_eq]; exact Finset.subset_union_left

theorem reachWithin_mono {k m : ℕ} (h : k ≤ m) : reachWithin G s k ⊆ reachWithin G s m := by
  induction m, h using Nat.le_induction with
  | base => exact Finset.Subset.refl _
  | succ m _ ih => exact ih.trans (reachWithin_subset_succ G s m)

theorem reachWithin_sound (k : ℕ) (v : V) (hv : v ∈ reachWithin G s k) :
    Relation.ReflTransGen G.Adj s v := by
  induction k generalizing v with
  | zero =>
    have : v = s := by simpa [reachWithin] using hv
    subst this; exact Relation.ReflTransGen.refl
  | succ k ih =>
    rcases (mem_reachWithin_succ G s k v).1 hv with h | ⟨u, hu, huv⟩
    · exact ih v h
    · exact (ih u hu).tail huv

theorem reachWithin_complete (v : V) (hv : Relation.ReflTransGen G.Adj s v) :
    ∃ k, v ∈ reachWithin G s k := by
  induction hv with
  | refl => exact ⟨0, by simp [reachWithin]⟩
  | tail _ hbc ih =>
    obtain ⟨k, hk⟩ := ih
    exact ⟨k + 1, (mem_reachWithin_succ G s k _).2 (Or.inr ⟨_, hk, hbc⟩)⟩

theorem reachWithin_stable (k : ℕ)
    (h : (reachWithin G s (k + 1)).card = (reachWithin G s k).card) :
    ∀ j, reachWithin G s (k + j) = reachWithin G s k := by
  have heq : reachWithin G s (k + 1) = reachWithin G s k :=
    (Finset.eq_of_subset_of_card_le (reachWithin_subset_succ G s k) h.le).symm
  intro j
  induction j with
  | zero => rfl
  | succ j ih =>
    rw [← Nat.add_assoc, reachWithin_succ_eq, ih, ← reachWithin_succ_eq, heq]

end helpers

/-- Counting certifies absence: on a finite directed graph, the target `t` is unreachable from `s`
exactly when there is a list `X` of rooms, each reachable from `s`, whose size equals the number
of reachable rooms, and which does not contain `t`. -/
theorem no_path_iff_count_certificate {V : Type*} [Fintype V] (G : Digraph V) (s t : V) :
    ¬ Relation.ReflTransGen G.Adj s t ↔
      ∃ X : Finset V, (∀ u ∈ X, Relation.ReflTransGen G.Adj s u) ∧
        X.card = Nat.card {v // Relation.ReflTransGen G.Adj s v} ∧ t ∉ X := by
  classical
  constructor
  · intro ht
    refine ⟨univ.filter (fun v => Relation.ReflTransGen G.Adj s v), ?_, ?_, ?_⟩
    · intro u hu; simpa using hu
    · rw [Nat.card_eq_fintype_card, Fintype.card_subtype]
    · simpa using ht
  · rintro ⟨X, hX, hcard, htX⟩ ht
    have hsub : X ⊆ univ.filter (fun v => Relation.ReflTransGen G.Adj s v) := by
      intro u hu; simpa using hX u hu
    have hc : (univ.filter (fun v => Relation.ReflTransGen G.Adj s v)).card ≤ X.card := by
      rw [hcard, Nat.card_eq_fintype_card, Fintype.card_subtype]
    have := Finset.eq_of_subset_of_card_le hsub hc
    apply htX
    rw [this]; simpa using ht

/-- One counting round is correct: if a branch lists rooms `X`, each within `k` doors of `s`,
and the list has exactly `c_k = |R_k|` rooms, then a room `v` is within `k + 1` doors exactly
when some listed room is `v` itself or has a door into `v`. -/
theorem counting_round_correct {V : Type*} [Fintype V] [DecidableEq V] (G : Digraph V)
    [DecidableRel G.Adj] (s : V) (k : ℕ) (X : Finset V)
    (hsub : ∀ u ∈ X, u ∈ reachWithin G s k) (hcard : X.card = (reachWithin G s k).card) (v : V) :
    v ∈ reachWithin G s (k + 1) ↔ ∃ u ∈ X, u = v ∨ G.Adj u v := by
  have hX : X = reachWithin G s k :=
    Finset.eq_of_subset_of_card_le (fun u hu => hsub u hu) hcard.ge
  subst hX
  rw [mem_reachWithin_succ]
  constructor
  · rintro (h | ⟨u, hu, huv⟩)
    · exact ⟨v, h, Or.inl rfl⟩
    · exact ⟨u, hu, Or.inr huv⟩
  · rintro ⟨u, hu, rfl | huv⟩
    · exact Or.inl hu
    · exact Or.inr ⟨u, hu, huv⟩

/-- The count settles: once `c_{k+1} = c_k`, the set `R_k` is every room reachable from `s`;
and on a graph with `n` rooms this has happened by round `n - 1`. -/
theorem count_settles {V : Type*} [Fintype V] [DecidableEq V] (G : Digraph V)
    [DecidableRel G.Adj] (s : V) :
    (∀ k, (reachWithin G s (k + 1)).card = (reachWithin G s k).card →
      ∀ v, v ∈ reachWithin G s k ↔ Relation.ReflTransGen G.Adj s v) ∧
    (∀ v, v ∈ reachWithin G s (Fintype.card V - 1) ↔ Relation.ReflTransGen G.Adj s v) := by
  have part1 : ∀ k, (reachWithin G s (k + 1)).card = (reachWithin G s k).card →
      ∀ v, v ∈ reachWithin G s k ↔ Relation.ReflTransGen G.Adj s v := by
    intro k hk v
    refine ⟨reachWithin_sound G s k v, fun hv => ?_⟩
    obtain ⟨m, hm⟩ := reachWithin_complete G s v hv
    have hst := reachWithin_stable G s k hk (m)
    rw [← hst]
    exact reachWithin_mono G s (Nat.le_add_left m k) hm
  refine ⟨part1, ?_⟩
  set n := Fintype.card V with hn
  have hn1 : 1 ≤ n := Fintype.card_pos_iff.2 ⟨s⟩
  have hex : ∃ k ≤ n - 1, (reachWithin G s (k + 1)).card = (reachWithin G s k).card := by
    by_contra hcon
    push Not at hcon
    have grow : ∀ k ≤ n, k + 1 ≤ (reachWithin G s k).card := by
      intro k
      induction k with
      | zero => intro _; simp [reachWithin]
      | succ k ih =>
        intro hk
        have h1 := ih (by omega)
        have h2 := Finset.card_le_card (reachWithin_subset_succ G s k)
        have h3 := hcon k (by omega)
        omega
    have := grow n le_rfl
    have := Finset.card_le_univ (reachWithin G s n)
    omega
  obtain ⟨k, hk, hc⟩ := hex
  intro v
  refine ⟨reachWithin_sound G s _ v, fun hv => ?_⟩
  exact reachWithin_mono G s hk ((part1 k hc v).2 hv)

/-! The card's building. Room `i + 1` on the card is `i : Fin 6` here: start room 1 is `0`,
exit room 6 is `5`. -/

/-- Maze A: the 9 one-way doors of the card's building. -/
abbrev mazeA : Digraph (Fin 6) := Digraph.mk' fun u v =>
  decide ((u.val + 1, v.val + 1) ∈
    [(1, 2), (1, 3), (2, 4), (3, 4), (4, 1), (5, 6), (6, 5), (5, 2), (6, 3)])

/-- Maze B: maze A plus the door 4 → 5, which makes the exit reachable. -/
abbrev mazeB : Digraph (Fin 6) := Digraph.mk' fun u v =>
  decide ((u.val + 1, v.val + 1) ∈
    [(1, 2), (1, 3), (2, 4), (3, 4), (4, 1), (5, 6), (6, 5), (5, 2), (6, 3), (4, 5)])

/-- The corridor 1 → 2 → 3 → 4 → 5 → 6. -/
abbrev corridor : Digraph (Fin 6) := Digraph.mk' fun u v => decide (v.val = u.val + 1)

-- Maze A: the counts c_0, c_1, c_2, c_3 are 1, 3, 4, 4.
example : (List.range 4).map (fun k => (reachWithin mazeA 0 k).card) = [1, 3, 4, 4] := by
  decide

-- Maze A: R_2 = {1, 2, 3, 4}, and the exit (room 6) is not in the settled set R_3.
example : reachWithin mazeA 0 2 = {0, 1, 2, 3} := by decide
example : (5 : Fin 6) ∉ reachWithin mazeA 0 3 := by decide

-- Maze B: the honest machine counts 1, 3, 4, 5, 6, 6, and the exit is reachable.
example : (List.range 6).map (fun k => (reachWithin mazeB 0 k).card) = [1, 3, 4, 5, 6, 6] := by
  decide
example : (5 : Fin 6) ∈ reachWithin mazeB 0 4 := by decide

-- Maze B, stopped after 2 rounds: the count is 4 and the exit is missing.
example : (reachWithin mazeB 0 2).card = 4 ∧ (5 : Fin 6) ∉ reachWithin mazeB 0 2 := by decide

-- The corridor needs all n - 1 = 5 rounds: counts 1, 2, 3, 4, 5, 6, 6.
example : (List.range 7).map (fun k => (reachWithin corridor 0 k).card) =
    [1, 2, 3, 4, 5, 6, 6] := by
  decide

-- 6 rooms give 2^6 = 64 guessed sets.
example : 2 ^ 6 = 64 := by norm_num

-- Memory: 8 registers of 3 bits plus 1 flag for 6 rooms (2^2 ≤ 6 < 2^3).
example : 2 ^ 2 ≤ 6 ∧ 6 < 2 ^ 3 ∧ 8 * 3 + 1 = 25 := by norm_num

-- Memory: 20-bit registers for 1,000,000 rooms give 161 bits (2^19 ≤ 1,000,000 < 2^20).
example : 2 ^ 19 ≤ 1000000 ∧ 1000000 < 2 ^ 20 ∧ 8 * 20 + 1 = 161 := by norm_num

-- Memory: 30-bit registers for 1,000,000,000 rooms give 241 bits.
example : 2 ^ 29 ≤ 1000000000 ∧ 1000000000 < 2 ^ 30 ∧ 8 * 30 + 1 = 241 := by norm_num

#print axioms reachWithin_succ_eq
#print axioms mem_reachWithin_succ
#print axioms reachWithin_subset_succ
#print axioms reachWithin_mono
#print axioms reachWithin_sound
#print axioms reachWithin_complete
#print axioms reachWithin_stable
#print axioms no_path_iff_count_certificate
#print axioms counting_round_correct
#print axioms count_settles
