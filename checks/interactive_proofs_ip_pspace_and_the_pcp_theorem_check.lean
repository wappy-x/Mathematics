-- Interactive proofs: one network drawn twice hides the sceptic's coin, different networks never do, and two different low-power polynomials rarely agree at a random point.
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Data.Fintype.Perm
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Tactic.NormNum

open Polynomial

/-- A graph isomorphism pushes its source graph onto its target graph. -/
theorem iso_map_eq_target {V W : Type*} {G : SimpleGraph V} {G' : SimpleGraph W}
    (e : G ≃g G') : G.map e = G' := by
  ext a b
  constructor
  · rintro ⟨-, u, v, h, rfl, rfl⟩
    exact e.map_adj_iff.mpr h
  · intro h
    refine ⟨h.ne, e.symm a, e.symm b, ?_, by simp, by simp⟩
    rw [← e.map_adj_iff]; simpa using h

#print axioms iso_map_eq_target

/-- Soundness of the map protocol. If the two maps are one network drawn twice
(some renaming turns `G₁` into `G₂`), the sceptic flips a coin `b`
(`false` picks `G₁`, `true` picks `G₂`) and redraws the chosen map under a
renaming `π`. Then every answering strategy `ans`, which sees only the redrawn
map, names the coin on exactly half of the `2 × (number of renamings)` equally
likely pairs `(b, π)`: one network drawn twice hides the coin. -/
theorem renamed_copy_hides_coin {V : Type*} [Fintype V] [DecidableEq V]
    (G₁ G₂ : SimpleGraph V) (h : Nonempty (G₁ ≃g G₂)) (ans : SimpleGraph V → Bool) :
    (Finset.univ.filter (fun bπ : Bool × Equiv.Perm V =>
        ans ((if bπ.1 then G₂ else G₁).map bπ.2) = bπ.1)).card
      = Fintype.card (Equiv.Perm V) := by
  obtain ⟨e⟩ := h
  have key : ∀ π : Equiv.Perm V, G₂.map π = G₁.map (e.toEquiv.trans π) := by
    intro π
    have h1 : (G₁.map e).map π = G₁.map (e.toEquiv.trans π) := by
      rw [SimpleGraph.map_map]; rfl
    rwa [iso_map_eq_target e] at h1
  have c1 : ∀ σ : Equiv.Perm V, e.toEquiv.trans (e.toEquiv.symm.trans σ) = σ := by
    intro σ; rw [← Equiv.trans_assoc, Equiv.self_trans_symm, Equiv.refl_trans]
  have c2 : ∀ σ : Equiv.Perm V, e.toEquiv.symm.trans (e.toEquiv.trans σ) = σ := by
    intro σ; rw [← Equiv.trans_assoc, Equiv.symm_trans_self, Equiv.refl_trans]
  rw [← Finset.card_univ]
  refine Finset.card_nbij' (fun bπ => if bπ.1 then e.toEquiv.trans bπ.2 else bπ.2)
    (fun σ => if ans (G₁.map σ) then (true, e.toEquiv.symm.trans σ) else (false, σ))
    (by simp) ?_ ?_ ?_
  · intro σ _
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq]
    by_cases hs : ans (G₁.map σ) = true
    · simp only [hs, ite_true]
      rw [key, c1]; exact hs
    · simp only [hs]
      simpa using hs
  · rintro ⟨b, π⟩ hb
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hb
    cases b with
    | true =>
      simp only [ite_true] at hb ⊢
      rw [key] at hb
      simp only [hb, ↓reduceIte, c2]
    | false =>
      simp only [Bool.false_eq_true, ite_false] at hb ⊢
      simp [hb]
  · intro σ _
    by_cases hs : ans (G₁.map σ) = true
    · simp only [hs, ite_true]
      exact c1 σ
    · simp [hs]

/-- Completeness of the map protocol. If the two maps are different networks
(no renaming turns `G₁` into `G₂`), an all-powerful prover has an answering
strategy that names the coin correctly for every coin and every renaming. -/
theorem different_networks_always_told_apart {V : Type*} [Fintype V] [DecidableEq V]
    (G₁ G₂ : SimpleGraph V) (h : IsEmpty (G₁ ≃g G₂)) :
    ∃ ans : SimpleGraph V → Bool, ∀ (b : Bool) (π : Equiv.Perm V),
      ans ((if b then G₂ else G₁).map π) = b := by
  classical
  refine ⟨fun H => decide (∃ σ : Equiv.Perm V, H = G₂.map σ), ?_⟩
  intro b π
  cases b with
  | true => simp only [ite_true, decide_eq_true_eq]; exact ⟨π, rfl⟩
  | false =>
    simp only [Bool.false_eq_true, ite_false, decide_eq_false_iff_not, not_exists]
    intro σ hσ
    have i1 : G₁ ≃g G₁.map (π : V ≃ V) := SimpleGraph.Iso.map π G₁
    have i2 : G₂ ≃g G₂.map (σ : V ≃ V) := SimpleGraph.Iso.map σ G₂
    exact h.false ((hσ ▸ i1).trans i2.symm)

/-- The step that catches a liar in sum-check. Over a finite field, two
different polynomials of power at most `d` agree at no more than `d` points;
so a random point exposes a wrong message except with chance at most `d / p`. -/
theorem distinct_low_degree_polys_agree_rarely {F : Type*} [Field F] [Fintype F]
    [DecidableEq F] (d : ℕ) (f g : F[X]) (hfg : f ≠ g)
    (hf : f.natDegree ≤ d) (hg : g.natDegree ≤ d) :
    (Finset.univ.filter (fun r : F => f.eval r = g.eval r)).card ≤ d := by
  have hne : f - g ≠ 0 := sub_ne_zero.mpr hfg
  calc (Finset.univ.filter (fun r : F => f.eval r = g.eval r)).card
      ≤ (f - g).roots.toFinset.card := by
        apply Finset.card_le_card
        intro r hr
        simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hr
        simp [Multiset.mem_toFinset, mem_roots hne, hr]
    _ ≤ (f - g).roots.card := Multiset.toFinset_card_le _
    _ ≤ (f - g).natDegree := card_roots' _
    _ ≤ d := (natDegree_sub_le f g).trans (max_le hf hg)

/-! Worked numbers from the card. -/

/-- The ring map: loop A-B-C-D-E-F-A with crossings B-E and C-F (A to F are 0 to 5). -/
def ringMap : SimpleGraph (Fin 6) := SimpleGraph.fromRel fun a b =>
  (a, b) ∈ [((0 : Fin 6), (1 : Fin 6)), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]

/-- The decoy: two triangles of stations, joined by two lines. -/
def decoyMap : SimpleGraph (Fin 6) := SimpleGraph.fromRel fun a b =>
  (a, b) ∈ [((0 : Fin 6), (1 : Fin 6)), (0, 2), (1, 2), (1, 4), (2, 5), (3, 4), (3, 5), (4, 5)]

instance : DecidableRel ringMap.Adj := fun a b => by unfold ringMap; infer_instance
instance : DecidableRel decoyMap.Adj := fun a b => by unfold decoyMap; infer_instance

-- 720 renamings of 6 stations.
example : Fintype.card (Equiv.Perm (Fin 6)) = 720 := by
  rw [Fintype.card_perm]; decide
-- Shuffled copies: 720 / 8 = 90 for the ring, 720 / 4 = 180 for the decoy; 1,440 (coin, renaming) pairs.
example : 720 / 8 = 90 ∧ 720 / 4 = 180 ∧ 2 * 720 = 1440 ∧ 1440 / 2 = 720 := by norm_num
-- Both maps have 8 lines; the ring has 0 triangles, the decoy 2.
example : ringMap.edgeFinset.card = 8 ∧ decoyMap.edgeFinset.card = 8 := by decide
example : (ringMap.cliqueFinset 3).card = 0 ∧ (decoyMap.cliqueFinset 3).card = 2 := by decide
-- A liar survives 20 rounds with chance 1 in 1,048,576.
example : (1 / 2 : ℚ) ^ 20 = 1 / 1048576 := by norm_num
-- Sum-check: 6 orderings × 2 triangles = 12 = 8 + 4; the liar's 18 = 11 + 7; 2^9 = 512 corners.
example : 6 * 2 = 12 ∧ 8 + 4 = 12 ∧ 11 + 7 = 18 ∧ 2 ^ 9 = 512 := by norm_num
-- Field size p = 2^31 - 1, and the escape bound 9 × 2 / p is under 1 in 119,304,647.
example : 2 ^ 31 - 1 = 2147483647 ∧ 9 * 2 = 18 ∧ 2147483647 / 18 = 119304647 := by norm_num
example : (18 : ℚ) / 2147483647 < 1 / 119304647 := by norm_num
-- Cost at 1,024 stations: 30 rounds, 90 numbers, 1,073,741,824 brute-force terms, 1,048,576 table entries.
example : 2 ^ 10 = 1024 ∧ 3 * 10 = 30 ∧ 9 * 10 = 90 ∧ 8 ^ 10 = 1073741824 ∧ 4 ^ 10 = 1048576 := by
  norm_num
-- Spot checks on the decoy: 2 broken lines of 8 is 1/4; 17 checks reach 99% and 16 do not.
example : (3 / 4 : ℚ) ^ 17 < 1 / 100 ∧ 1 / 100 < (3 / 4 : ℚ) ^ 16 := by norm_num
-- A 3-literal clause holds on 7 of its 8 settings.
example : (Finset.univ.filter (fun x : Bool × Bool × Bool => x.1 || x.2.1 || x.2.2)).card = 7 := by
  decide

#print axioms renamed_copy_hides_coin
#print axioms different_networks_always_told_apart
#print axioms distinct_low_degree_polys_agree_rarely
