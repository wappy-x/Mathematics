-- Friends and strangers: whenever every pair among six or more people is either acquainted or strangers, some three all know each other or some three are all strangers, five people seated in a ring of acquaintance escape this, and six people always hold at least two such trios.
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Factorial.Basic

open SimpleGraph


/-- Every Boolean labelling of the fifteen pairs among six guests has at least two
monochromatic trios (checked by the kernel over all 2^15 labellings). -/
theorem goodman_six_bool : ∀ b01 b02 b03 b04 b05 b12 b13 b14 b15 b23 b24 b25 b34 b35 b45 : Bool,
    2 ≤ ((if (b01 && (b02 && b12)) = true then 1 else 0) +
        ((if (b01 && (b03 && b13)) = true then 1 else 0) +
        ((if (b01 && (b04 && b14)) = true then 1 else 0) +
        ((if (b01 && (b05 && b15)) = true then 1 else 0) +
        ((if (b02 && (b03 && b23)) = true then 1 else 0) +
        ((if (b02 && (b04 && b24)) = true then 1 else 0) +
        ((if (b02 && (b05 && b25)) = true then 1 else 0) +
        ((if (b03 && (b04 && b34)) = true then 1 else 0) +
        ((if (b03 && (b05 && b35)) = true then 1 else 0) +
        ((if (b04 && (b05 && b45)) = true then 1 else 0) +
        ((if (b12 && (b13 && b23)) = true then 1 else 0) +
        ((if (b12 && (b14 && b24)) = true then 1 else 0) +
        ((if (b12 && (b15 && b25)) = true then 1 else 0) +
        ((if (b13 && (b14 && b34)) = true then 1 else 0) +
        ((if (b13 && (b15 && b35)) = true then 1 else 0) +
        ((if (b14 && (b15 && b45)) = true then 1 else 0) +
        ((if (b23 && (b24 && b34)) = true then 1 else 0) +
        ((if (b23 && (b25 && b35)) = true then 1 else 0) +
        ((if (b24 && (b25 && b45)) = true then 1 else 0) +
        ((if (b34 && (b35 && b45)) = true then 1 else 0))))))))))))))))))))) +
      ((if (!b01 && (!b02 && !b12)) = true then 1 else 0) +
        ((if (!b01 && (!b03 && !b13)) = true then 1 else 0) +
        ((if (!b01 && (!b04 && !b14)) = true then 1 else 0) +
        ((if (!b01 && (!b05 && !b15)) = true then 1 else 0) +
        ((if (!b02 && (!b03 && !b23)) = true then 1 else 0) +
        ((if (!b02 && (!b04 && !b24)) = true then 1 else 0) +
        ((if (!b02 && (!b05 && !b25)) = true then 1 else 0) +
        ((if (!b03 && (!b04 && !b34)) = true then 1 else 0) +
        ((if (!b03 && (!b05 && !b35)) = true then 1 else 0) +
        ((if (!b04 && (!b05 && !b45)) = true then 1 else 0) +
        ((if (!b12 && (!b13 && !b23)) = true then 1 else 0) +
        ((if (!b12 && (!b14 && !b24)) = true then 1 else 0) +
        ((if (!b12 && (!b15 && !b25)) = true then 1 else 0) +
        ((if (!b13 && (!b14 && !b34)) = true then 1 else 0) +
        ((if (!b13 && (!b15 && !b35)) = true then 1 else 0) +
        ((if (!b14 && (!b15 && !b45)) = true then 1 else 0) +
        ((if (!b23 && (!b24 && !b34)) = true then 1 else 0) +
        ((if (!b23 && (!b25 && !b35)) = true then 1 else 0) +
        ((if (!b24 && (!b25 && !b45)) = true then 1 else 0) +
        ((if (!b34 && (!b35 && !b45)) = true then 1 else 0))))))))))))))))))))) := by
  decide

/-- Every three-element subset of `Fin 6` is one of the twenty listed trios. -/
theorem triples_fin6 : ∀ s : Finset (Fin 6), s.card = 3 →
    s ∈ ({{0, 1, 2}, {0, 1, 3}, {0, 1, 4}, {0, 1, 5}, {0, 2, 3}, {0, 2, 4}, {0, 2, 5}, {0, 3, 4}, {0, 3, 5}, {0, 4, 5}, {1, 2, 3}, {1, 2, 4}, {1, 2, 5}, {1, 3, 4}, {1, 3, 5}, {1, 4, 5}, {2, 3, 4}, {2, 3, 5}, {2, 4, 5}, {3, 4, 5}} : Finset (Finset (Fin 6))) := by
  decide

theorem cliqueFinset_fin6_eq (G : SimpleGraph (Fin 6)) [DecidableRel G.Adj] :
    G.cliqueFinset 3 =
      ({{0, 1, 2}, {0, 1, 3}, {0, 1, 4}, {0, 1, 5}, {0, 2, 3}, {0, 2, 4}, {0, 2, 5}, {0, 3, 4}, {0, 3, 5}, {0, 4, 5}, {1, 2, 3}, {1, 2, 4}, {1, 2, 5}, {1, 3, 4}, {1, 3, 5}, {1, 4, 5}, {2, 3, 4}, {2, 3, 5}, {2, 4, 5}, {3, 4, 5}} : Finset (Finset (Fin 6))).filter (fun s => G.IsNClique 3 s) := by
  ext s
  simp only [mem_cliqueFinset_iff, Finset.mem_filter]
  exact ⟨fun h => ⟨triples_fin6 s h.card_eq, h⟩, fun h => h.2⟩

theorem indepSetFinset_fin6_eq (G : SimpleGraph (Fin 6)) [DecidableRel G.Adj] :
    G.indepSetFinset 3 =
      ({{0, 1, 2}, {0, 1, 3}, {0, 1, 4}, {0, 1, 5}, {0, 2, 3}, {0, 2, 4}, {0, 2, 5}, {0, 3, 4}, {0, 3, 5}, {0, 4, 5}, {1, 2, 3}, {1, 2, 4}, {1, 2, 5}, {1, 3, 4}, {1, 3, 5}, {1, 4, 5}, {2, 3, 4}, {2, 3, 5}, {2, 4, 5}, {3, 4, 5}} : Finset (Finset (Fin 6))).filter (fun s => G.IsNIndepSet 3 s) := by
  ext s
  simp only [mem_indepSetFinset_iff, Finset.mem_filter]
  exact ⟨fun h => ⟨triples_fin6 s h.card_eq, h⟩, fun h => h.2⟩

theorem is3IndepSet_triple_iff {α : Type*} [DecidableEq α] (G : SimpleGraph α) {a b c : α}
    (hab : a ≠ b) (hac : a ≠ c) (hbc : b ≠ c) :
    G.IsNIndepSet 3 {a, b, c} ↔ ¬ G.Adj a b ∧ ¬ G.Adj a c ∧ ¬ G.Adj b c := by
  rw [← isNClique_compl, is3Clique_triple_iff]
  simp [compl_adj, hab, hac, hbc]

/-- Goodman's bound on `Fin 6`, proved from the Boolean check above. -/
theorem goodman_fin6 (G : SimpleGraph (Fin 6)) [DecidableRel G.Adj] :
    2 ≤ (G.cliqueFinset 3).card + (G.indepSetFinset 3).card := by
  rw [cliqueFinset_fin6_eq, indepSetFinset_fin6_eq, Finset.card_filter, Finset.card_filter]
  simp (disch := decide) only [Finset.sum_insert, Finset.sum_singleton]
  simp (disch := decide) only [is3Clique_triple_iff, is3IndepSet_triple_iff]
  have key := goodman_six_bool (decide (G.Adj 0 1)) (decide (G.Adj 0 2)) (decide (G.Adj 0 3)) (decide (G.Adj 0 4)) (decide (G.Adj 0 5)) (decide (G.Adj 1 2)) (decide (G.Adj 1 3)) (decide (G.Adj 1 4)) (decide (G.Adj 1 5)) (decide (G.Adj 2 3)) (decide (G.Adj 2 4)) (decide (G.Adj 2 5)) (decide (G.Adj 3 4)) (decide (G.Adj 3 5)) (decide (G.Adj 4 5))
  simp only [Bool.and_eq_true, decide_eq_true_eq, Bool.not_eq_true', decide_eq_false_iff_not]
    at key
  exact key


#print axioms goodman_six_bool
#print axioms triples_fin6
#print axioms cliqueFinset_fin6_eq
#print axioms indepSetFinset_fin6_eq
#print axioms is3IndepSet_triple_iff
#print axioms goodman_fin6

/-- Six guests force a trio all alike. Take a party of six or more guests and settle every pair
one way or the other: acquainted (an edge of the graph `G`) or strangers (no edge). Then some
three guests all know one another (a triangle in `G`) or some three are mutual strangers (three
guests with no edge among them). This is the "six is enough" half of `R(3,3) = 6`. -/
theorem six_guests_force_a_trio_all_alike {V : Type*} [Fintype V] (hV : 6 ≤ Fintype.card V)
    (G : SimpleGraph V) :
    ∃ s : Finset V, G.IsNClique 3 s ∨ G.IsNIndepSet 3 s := by
  classical
  obtain ⟨f⟩ : Nonempty (Fin 6 ↪ V) :=
    Function.Embedding.nonempty_of_card_le (by simpa using hV)
  have h2 := goodman_fin6 (G.comap f)
  rcases Nat.eq_zero_or_pos ((G.comap f).cliqueFinset 3).card with hc | hc
  · have hi : 0 < ((G.comap f).indepSetFinset 3).card := by omega
    obtain ⟨s, hs⟩ := Finset.card_pos.mp hi
    rw [mem_indepSetFinset_iff, ← isNClique_compl] at hs
    refine ⟨s.map f, Or.inr ?_⟩
    rw [← isNClique_compl]
    have hle : (G.comap f)ᶜ ≤ Gᶜ.comap f := by
      intro a b h
      simp only [compl_adj, comap_adj] at h ⊢
      exact ⟨fun hab => h.1 (f.injective hab), h.2⟩
    exact ((hs.mono hle).map (f := f)).mono (map_comap_le _ _)
  · obtain ⟨s, hs⟩ := Finset.card_pos.mp hc
    rw [mem_cliqueFinset_iff] at hs
    exact ⟨s.map f, Or.inl ((hs.map (f := f)).mono (map_comap_le _ _))⟩

/-- Five guests are not enough. Seat five guests at a round table where each knows only the two
beside them (the ring `cycleGraph 5`). Then no three all know one another and no three are all
strangers: every trio mixes the two kinds. This is the "five is not enough" half of
`R(3,3) = 6`. -/
theorem five_guests_in_a_ring_escape (s : Finset (Fin 5)) :
    ¬ (cycleGraph 5).IsNClique 3 s ∧ ¬ (cycleGraph 5).IsNIndepSet 3 s := by
  revert s
  decide

/-- Goodman's count for six guests: however the fifteen pairs among six guests are labelled
acquainted or strangers, at least two trios are all alike (trios of mutual acquaintances plus
trios of mutual strangers number at least 2). -/
theorem six_guests_hold_at_least_two_trios_all_alike (G : SimpleGraph (Fin 6))
    [DecidableRel G.Adj] :
    2 ≤ (G.cliqueFinset 3).card + (G.indepSetFinset 3).card := by
  exact goodman_fin6 G

/-- The two-teams party: guests 0, 1, 2 form one team and 3, 4, 5 the other; every pair across
the teams is acquainted and every pair within a team is strangers. -/
def twoTeams : SimpleGraph (Fin 6) where
  Adj i j := (i.val < 3) ≠ (j.val < 3)
  symm := ⟨fun _ _ h => Ne.symm h⟩
  loopless := ⟨fun _ h => h rfl⟩

instance : DecidableRel twoTeams.Adj := fun i j =>
  inferInstanceAs (Decidable ((i.val < 3) ≠ (j.val < 3)))

-- Six guests: 15 pairs, 2^15 = 32768 labellings, 20 trios in each.
example : Nat.choose 6 2 = 15 ∧ 2 ^ 15 = 32768 ∧ Nat.choose 6 3 = 20 := by decide
-- Finn faces 6 - 1 = 5 others; 5 relationships in 2 kinds, rounded up, give 3 alike
-- (rounded down it would be 2); the three hold C(3, 2) = 3 pairs.
example : 6 - 1 = 5 ∧ (5 + 2 - 1) / 2 = 3 ∧ 5 / 2 = 2 ∧ Nat.choose 3 2 = 3 := by decide
-- Five guests: 10 pairs, 2^10 = 1024 labellings, 10 trios; 120 seatings / (5 × 2) = 12 rings.
example : Nat.choose 5 2 = 10 ∧ 2 ^ 10 = 1024 ∧ Nat.choose 5 3 = 10 ∧
    Nat.factorial 5 = 120 ∧ 120 / (5 * 2) = 12 := by decide
-- One pair left undecided: the other 14 pairs have 2^14 = 16384 labellings.
example : 2 ^ (Nat.choose 6 2 - 1) = 16384 := by decide
-- The two-teams party holds 0 trios of friends and 2 trios of strangers.
example : (twoTeams.cliqueFinset 3).card = 0 ∧ (twoTeams.indepSetFinset 3).card = 2 := by
  decide

#print axioms six_guests_force_a_trio_all_alike
#print axioms five_guests_in_a_ring_escape
#print axioms six_guests_hold_at_least_two_trios_all_alike
