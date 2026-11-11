-- Ramsey numbers: when every road between towns is paved or gravel, the threshold for s all-paved or t all-gravel towns is at most the sum of its two feeders (one less when both are even), it is at most C(s+t-2, s-1) so it always exists, and R(3,4) = 9.
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Data.Nat.Choose.Basic

open SimpleGraph

/-- Helper: a clique-or-independent-set guarantee on `W` transfers along an embedding into `V`. -/
theorem ramsey_transfer {W V : Type} {n m : ℕ}
    (h : ∀ G : SimpleGraph W, ∃ S : Finset W, G.IsNClique n S ∨ G.IsNIndepSet m S)
    (f : W ↪ V) (G : SimpleGraph V) :
    ∃ S : Finset W, G.IsNClique n (S.map f) ∨ G.IsNIndepSet m (S.map f) := by
  obtain ⟨S, hS⟩ := h (G.comap f)
  refine ⟨S, ?_⟩
  rcases hS with hS | hS
  · left
    rw [isNClique_iff] at hS ⊢
    refine ⟨?_, by simpa using hS.2⟩
    intro x hx y hy hxy
    simp only [Finset.coe_map, Set.mem_image, Finset.mem_coe] at hx hy
    obtain ⟨x, hx, rfl⟩ := hx
    obtain ⟨y, hy, rfl⟩ := hy
    exact hS.1 hx hy (fun h => hxy (by rw [h]))
  · right
    rw [isNIndepSet_iff] at hS ⊢
    refine ⟨?_, by simpa using hS.2⟩
    intro x hx y hy hxy
    simp only [Finset.coe_map, Set.mem_image, Finset.mem_coe] at hx hy
    obtain ⟨x, hx, rfl⟩ := hx
    obtain ⟨y, hy, rfl⟩ := hy
    exact hS.1 hx hy (fun h => hxy (by rw [h]))

/-- Helper: an embedding of `Fin a` into a finset of size at least `a`. -/
theorem ramsey_embed {V : Type} (T : Finset V) {a : ℕ} (h : a ≤ T.card) :
    ∃ f : Fin a ↪ V, ∀ i, f i ∈ T := by
  obtain ⟨e⟩ := Function.Embedding.nonempty_of_card_le (α := Fin a) (β := T) (by simpa using h)
  exact ⟨e.trans (Function.Embedding.subtype _), fun i => (e i).2⟩

/-- Helper: the guarantee for `Fin 0` is impossible when both sizes are positive. -/
theorem ramsey_feeder_pos {a n m : ℕ} (hn : 1 ≤ n) (hm : 1 ≤ m)
    (h : ∀ G : SimpleGraph (Fin a), ∃ S : Finset (Fin a), G.IsNClique n S ∨ G.IsNIndepSet m S) :
    1 ≤ a := by
  by_contra ha
  obtain rfl : a = 0 := by omega
  obtain ⟨S, hS⟩ := h ⊥
  have : S = ∅ := Finset.eq_empty_of_isEmpty S
  subst this
  rcases hS with hS | hS
  · have := hS.card_eq; simp at this; omega
  · have := hS.card_eq; simp at this; omega

/-- Helper: one step of the recursion at a chosen town `v`. -/
theorem ramsey_step {V : Type} [Fintype V] [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj]
    {s t a b : ℕ} (hs : 2 ≤ s) (ht : 2 ≤ t)
    (ha : ∀ G : SimpleGraph (Fin a), ∃ S : Finset (Fin a), G.IsNClique (s - 1) S ∨ G.IsNIndepSet t S)
    (hb : ∀ G : SimpleGraph (Fin b), ∃ S : Finset (Fin b), G.IsNClique s S ∨ G.IsNIndepSet (t - 1) S)
    (v : V) (hv : a ≤ G.degree v ∨ b ≤ Fintype.card V - 1 - G.degree v) :
    ∃ S : Finset V, G.IsNClique s S ∨ G.IsNIndepSet t S := by
  rcases hv with hv | hv
  · rw [← card_neighborFinset_eq_degree] at hv
    obtain ⟨f, hf⟩ := ramsey_embed _ hv
    obtain ⟨S, hS | hS⟩ := ramsey_transfer ha f G
    · refine ⟨insert v (S.map f), Or.inl ?_⟩
      have := hS.insert (a := v) (fun w hw => by
        obtain ⟨i, -, rfl⟩ := Finset.mem_map.1 hw
        simpa using hf i)
      rwa [show s - 1 + 1 = s by omega] at this
    · exact ⟨_, Or.inr hS⟩
  · set M := (G.neighborFinset v)ᶜ.erase v with hM
    have hcard : M.card = Fintype.card V - 1 - G.degree v := by
      rw [hM, Finset.card_erase_of_mem (by simp), Finset.card_compl, card_neighborFinset_eq_degree]
      omega
    rw [← hcard] at hv
    obtain ⟨f, hf⟩ := ramsey_embed _ hv
    obtain ⟨S, hS | hS⟩ := ramsey_transfer hb f G
    · exact ⟨_, Or.inl hS⟩
    · refine ⟨insert v (S.map f), Or.inr ?_⟩
      rw [← isNClique_compl] at hS ⊢
      have := hS.insert (a := v) (fun w hw => by
        obtain ⟨i, -, rfl⟩ := Finset.mem_map.1 hw
        have := hf i
        rw [hM, Finset.mem_erase, Finset.mem_compl, mem_neighborFinset] at this
        rw [compl_adj]
        exact ⟨Ne.symm this.1, this.2⟩)
      rwa [show t - 1 + 1 = t by omega] at this

/-- Helper: the eight-town county, defined again here so the proof can use it. -/
def eightTownsAux : SimpleGraph (Fin 8) where
  Adj i j := (i.val + 8 - j.val) % 8 = 1 ∨ (i.val + 8 - j.val) % 8 = 4 ∨ (i.val + 8 - j.val) % 8 = 7
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel eightTownsAux.Adj := fun i j =>
  inferInstanceAs (Decidable ((i.val + 8 - j.val) % 8 = 1 ∨ (i.val + 8 - j.val) % 8 = 4 ∨
    (i.val + 8 - j.val) % 8 = 7))

#print axioms ramsey_transfer
#print axioms ramsey_embed
#print axioms ramsey_feeder_pos
#print axioms ramsey_step

/-- The recursion, with its parity step. Towns are the vertices of a finite type `V`; a road is
paved when it is an edge of `G` and gravel when it is not, so every road has exactly one of the
two surfaces. Let `a` towns always force `s - 1` all-paved or `t` all-gravel (that is,
`R(s-1, t) ≤ a`), and `b` towns always force `s` all-paved or `t - 1` all-gravel
(`R(s, t-1) ≤ b`). Then any county of `a + b` or more towns holds `s` towns all joined by paved
roads or `t` towns all joined by gravel: `R(s,t) ≤ R(s-1,t) + R(s,t-1)`. If `a` and `b` are both
even, `a + b - 1` towns already suffice. -/
theorem ramsey_le_sum_of_feeders {s t a b : ℕ} (hs : 2 ≤ s) (ht : 2 ≤ t)
    (ha : ∀ G : SimpleGraph (Fin a), ∃ S : Finset (Fin a), G.IsNClique (s - 1) S ∨ G.IsNIndepSet t S)
    (hb : ∀ G : SimpleGraph (Fin b), ∃ S : Finset (Fin b), G.IsNClique s S ∨ G.IsNIndepSet (t - 1) S) :
    (∀ {V : Type} [Fintype V], a + b ≤ Fintype.card V →
      ∀ G : SimpleGraph V, ∃ S : Finset V, G.IsNClique s S ∨ G.IsNIndepSet t S) ∧
    (Even a → Even b → ∀ {V : Type} [Fintype V], a + b - 1 ≤ Fintype.card V →
      ∀ G : SimpleGraph V, ∃ S : Finset V, G.IsNClique s S ∨ G.IsNIndepSet t S) := by
  classical
  have ha1 : 1 ≤ a := ramsey_feeder_pos (by omega) (by omega) ha
  have part1 : ∀ {V : Type} [Fintype V], a + b ≤ Fintype.card V →
      ∀ G : SimpleGraph V, ∃ S : Finset V, G.IsNClique s S ∨ G.IsNIndepSet t S := by
    intro V _ hV G
    have : Nonempty V := Fintype.card_pos_iff.1 (by omega)
    obtain ⟨v⟩ := this
    have hd := G.degree_lt_card_verts v
    exact ramsey_step G hs ht ha hb v (by omega)
  refine ⟨part1, ?_⟩
  intro hae hbe V _ hV G
  by_cases hV' : a + b ≤ Fintype.card V
  · exact part1 hV' G
  have hVeq : Fintype.card V = a + b - 1 := by omega
  have : ∃ v, G.degree v ≠ a - 1 := by
    by_contra hall
    push Not at hall
    have hsum := G.sum_degrees_eq_twice_card_edges
    simp only [hall, Finset.sum_const, Finset.card_univ, smul_eq_mul] at hsum
    have hev : Even (Fintype.card V * (a - 1)) := ⟨_, hsum.trans (two_mul _)⟩
    rcases Nat.even_mul.1 hev with h | h
    · obtain ⟨x, hx⟩ := hae; obtain ⟨y, hy⟩ := hbe; obtain ⟨k, hk⟩ := h; omega
    · obtain ⟨x, hx⟩ := hae; obtain ⟨k, hk⟩ := h; omega
  obtain ⟨v, hv⟩ := this
  have hd := G.degree_lt_card_verts v
  exact ramsey_step G hs ht ha hb v (by omega)

/-- The binomial ceiling, so every threshold exists: however the roads among
`C(s+t-2, s-1)` or more towns are surfaced, some `s` towns are all joined by paved roads or some
`t` towns are all joined by gravel. That is, `R(s,t) ≤ C(s+t-2, s-1)`. -/
theorem ramsey_le_choose (s t : ℕ) {V : Type} [Fintype V]
    (hV : Nat.choose (s + t - 2) (s - 1) ≤ Fintype.card V) (G : SimpleGraph V) :
    ∃ S : Finset V, G.IsNClique s S ∨ G.IsNIndepSet t S := by
  have key : ∀ n s t : ℕ, s + t ≤ n → ∀ {V : Type} [Fintype V],
      Nat.choose (s + t - 2) (s - 1) ≤ Fintype.card V →
      ∀ G : SimpleGraph V, ∃ S : Finset V, G.IsNClique s S ∨ G.IsNIndepSet t S := by
    intro n
    induction n with
    | zero =>
      intro s t hst V _ _ G
      obtain rfl : s = 0 := by omega
      exact ⟨∅, Or.inl (by simp [isNClique_iff])⟩
    | succ n ih =>
      intro s t hst V _ hV G
      match s, t with
      | 0, _ => exact ⟨∅, Or.inl (by simp [isNClique_iff])⟩
      | _, 0 => exact ⟨∅, Or.inr (by simp [isNIndepSet_iff])⟩
      | 1, t =>
        have : Nonempty V := Fintype.card_pos_iff.1 (by simp at hV; omega)
        obtain ⟨v⟩ := this
        exact ⟨{v}, Or.inl (isNClique_singleton.2 rfl)⟩
      | s + 2, 1 =>
        have : Nonempty V := Fintype.card_pos_iff.1 (by simp at hV; omega)
        obtain ⟨v⟩ := this
        refine ⟨{v}, Or.inr ?_⟩
        rw [← isNClique_compl]
        exact isNClique_singleton.2 rfl
      | s + 2, t + 2 =>
        have ha : ∀ G : SimpleGraph (Fin (Nat.choose (s + t + 1) s)),
            ∃ S : Finset (Fin (Nat.choose (s + t + 1) s)),
              G.IsNClique (s + 2 - 1) S ∨ G.IsNIndepSet (t + 2) S := by
          intro G
          exact ih (s + 1) (t + 2) (by omega)
            (by rw [Fintype.card_fin, show s + 1 + (t + 2) - 2 = s + t + 1 by omega]; simp) G
        have hb : ∀ G : SimpleGraph (Fin (Nat.choose (s + t + 1) (s + 1))),
            ∃ S : Finset (Fin (Nat.choose (s + t + 1) (s + 1))),
              G.IsNClique (s + 2) S ∨ G.IsNIndepSet (t + 2 - 1) S := by
          intro G
          exact ih (s + 2) (t + 1) (by omega)
            (by rw [Fintype.card_fin, show s + 2 + (t + 1) - 2 = s + t + 1 by omega]; simp) G
        refine (ramsey_le_sum_of_feeders (by omega) (by omega) ha hb).1 ?_ G
        rw [show s + 2 + (t + 2) - 2 = (s + t + 1) + 1 by omega, show s + 2 - 1 = s + 1 by omega,
          Nat.choose_succ_succ] at hV
        exact hV
  exact key _ s t le_rfl hV G

/-- `R(3,4) = 9`: nine or more towns always hold a paved trio or a gravel foursome, and some
surfacing of the roads among eight towns has neither. -/
theorem ramsey_three_four_eq_nine :
    (∀ {V : Type} [Fintype V], 9 ≤ Fintype.card V →
      ∀ G : SimpleGraph V, ∃ S : Finset V, G.IsNClique 3 S ∨ G.IsNIndepSet 4 S) ∧
    (∃ G : SimpleGraph (Fin 8), ∀ S : Finset (Fin 8), ¬ G.IsNClique 3 S ∧ ¬ G.IsNIndepSet 4 S) := by
  refine ⟨?_, ?_⟩
  · intro V _ hV G
    have ha : ∀ G : SimpleGraph (Fin 4), ∃ S : Finset (Fin 4), G.IsNClique (3 - 1) S ∨ G.IsNIndepSet 4 S :=
      fun G => ramsey_le_choose 2 4 (by simp) G
    have hb : ∀ G : SimpleGraph (Fin 6), ∃ S : Finset (Fin 6), G.IsNClique 3 S ∨ G.IsNIndepSet (4 - 1) S :=
      fun G => ramsey_le_choose 3 3 (by simp; decide) G
    exact (ramsey_le_sum_of_feeders (by omega) (by omega) ha hb).2 ⟨2, rfl⟩ ⟨3, rfl⟩ (by omega) G
  · refine ⟨eightTownsAux, fun S => ⟨fun h => ?_, fun h => ?_⟩⟩
    · have hc : (eightTownsAux.cliqueFinset 3).card = 0 := by decide
      rw [Finset.card_eq_zero] at hc
      have := (mem_cliqueFinset_iff (G := eightTownsAux)).2 h
      simp [hc] at this
    · have hc : (eightTownsAux.indepSetFinset 4).card = 0 := by decide
      rw [Finset.card_eq_zero] at hc
      have := (mem_indepSetFinset_iff (G := eightTownsAux)).2 h
      simp [hc] at this

/-- The card's eight-town county: towns `0..7` round a ring (A to H), with a paved road when the
gap between two towns, counted round the ring, is 1, 4 or 7: the ring of eight plus the four
roads straight across. -/
def eightTowns : SimpleGraph (Fin 8) where
  Adj i j := (i.val + 8 - j.val) % 8 = 1 ∨ (i.val + 8 - j.val) % 8 = 4 ∨ (i.val + 8 - j.val) % 8 = 7
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel eightTowns.Adj := fun i j =>
  inferInstanceAs (Decidable ((i.val + 8 - j.val) % 8 = 1 ∨ (i.val + 8 - j.val) % 8 = 4 ∨
    (i.val + 8 - j.val) % 8 = 7))

-- Nine towns: C(9,2) = 36 roads and 2^36 = 68719476736 surfacings.
example : Nat.choose 9 2 = 36 ∧ 2 ^ 36 = 68719476736 := by decide
-- The ceiling: R(2,4) + R(3,3) = 4 + 6 = 10 = C(5,2).
example : 4 + 6 = 10 ∧ Nat.choose 5 2 = 10 := by decide
-- At one of nine towns: 4 - 1 = 3 paved at most, 6 - 1 = 5 gravel at most, 3 + 5 = 8 roads;
-- paved road-ends 9 × 3 = 27, odd; ceiling after parity 10 - 1 = 9.
example : 4 - 1 = 3 ∧ 6 - 1 = 5 ∧ 3 + 5 = 8 ∧ 9 * 3 = 27 ∧ ¬ Even 27 ∧ 10 - 1 = 9 := by decide
-- The eight-town county: 12 paved roads, 3 at every town, 0 paved trios of C(8,3) = 56 and
-- 0 gravel foursomes of C(8,4) = 70.
example : eightTowns.edgeFinset.card = 12 ∧ (∀ v, eightTowns.degree v = 3) ∧
    Nat.choose 8 3 = 56 ∧ Nat.choose 8 4 = 70 ∧
    (eightTowns.cliqueFinset 3).card = 0 ∧ (eightTowns.indepSetFinset 4).card = 0 := by decide
-- Binomial ceilings C(s+t-2, s-1) for (3,3), (3,4), (3,5), (4,4), (4,5), (5,5).
example : Nat.choose 4 2 = 6 ∧ Nat.choose 5 2 = 10 ∧ Nat.choose 6 2 = 15 ∧
    Nat.choose 6 3 = 20 ∧ Nat.choose 7 3 = 35 ∧ Nat.choose 8 4 = 70 := by decide
-- The recursion on known values: 3 + 3, 4 + 6, 5 + 9, 9 + 9, 14 + 18, 25 + 25.
example : 3 + 3 = 6 ∧ 4 + 6 = 10 ∧ 5 + 9 = 14 ∧ 9 + 9 = 18 ∧ 14 + 18 = 32 ∧ 25 + 25 = 50 := by
  decide
-- The 17-town and 13-town clocks: C(17,4) = 2380 foursomes, C(13,5) = 1287 five-sets, and the
-- squares mod 17 are the gaps 1, 2, 4, 8, 9, 13, 15, 16.
example : Nat.choose 17 4 = 2380 ∧ Nat.choose 13 5 = 1287 ∧
    (Finset.range 17).filter (fun g => ∃ x ∈ Finset.Ioo 0 17, x * x % 17 = g) =
      {1, 2, 4, 8, 9, 13, 15, 16} := by decide

#print axioms ramsey_le_sum_of_feeders
#print axioms ramsey_le_choose
#print axioms ramsey_three_four_eq_nine
