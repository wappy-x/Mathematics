-- Bipartite graphs: a graph's dots split into two sides with every line crossing exactly when it has no cycle of odd length, the parity of the distance from a root gives the sides, a graph in two pieces splits only when both pieces do, and the card's roster, cafes and metro map have the cuts, distances and odd cycle it claims.
import Mathlib.Combinatorics.SimpleGraph.Paths
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Combinatorics.SimpleGraph.Sum
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.Coloring.Constructions

open SimpleGraph

/-- A bipartition of `G` into the heaps `X` and `Y`: every dot sits in `X` or in `Y`, none in
both, and every line joins a dot of `X` to a dot of `Y`. -/
def IsTwoSideCut {V : Type*} (G : SimpleGraph V) (X Y : Set V) : Prop :=
  X ∪ Y = Set.univ ∧ Disjoint X Y ∧ ∀ u v, G.Adj u v → (u ∈ X ∧ v ∈ Y) ∨ (u ∈ Y ∧ v ∈ X)

/-- Without an odd cycle, shortening a walk to a path keeps the parity of its length. -/
theorem bip_bypass_length_mod_two {V : Type*} [DecidableEq V] (G : SimpleGraph V)
    (h : ¬ ∃ (u : V) (c : G.Walk u u), c.IsCycle ∧ Odd c.length) :
    ∀ {a b : V} (p : G.Walk a b), p.bypass.length % 2 = p.length % 2 := by
  intro a b p
  induction p with
  | nil => rfl
  | @cons a c b ha p ih =>
    simp only [Walk.bypass]
    split_ifs with hs
    · have hlen := congrArg Walk.length (p.bypass.take_spec hs)
      rw [Walk.length_append] at hlen
      have hq : (p.bypass.takeUntil a hs).IsPath := (Walk.bypass_isPath p).takeUntil hs
      have hodd : (p.bypass.takeUntil a hs).length % 2 = 1 := by
        by_contra hev
        have hne : (p.bypass.takeUntil a hs).length ≠ 0 := by
          intro h0
          exact ha.ne (Walk.eq_of_length_eq_zero h0).symm
        apply h
        refine ⟨a, Walk.cons ha (p.bypass.takeUntil a hs), ?_, ?_⟩
        · rw [Walk.isCycle_iff_isPath_tail_and_le_length]
          refine ⟨?_, ?_⟩
          · simpa [Walk.tail_cons] using hq
          · simp only [Walk.length_cons]; omega
        · simp only [Walk.length_cons]
          rw [Nat.odd_iff]; omega
      simp only [Walk.length_cons]
      omega
    · simp only [Walk.length_cons]
      omega

/-- Without an odd cycle, every closed walk has even length. -/
theorem bip_even_of_no_odd_cycle {V : Type*} (G : SimpleGraph V)
    (h : ¬ ∃ (u : V) (c : G.Walk u u), c.IsCycle ∧ Odd c.length) (u : V) (w : G.Walk u u) :
    Even w.length := by
  classical
  have h1 := bip_bypass_length_mod_two G h w
  have h2 : w.bypass.length = 0 := (Walk.nil_bypass w).length_eq_zero
  rw [Nat.even_iff]; omega

/-- Along a walk in a graph cut into `X` and its complement, membership in `X` flips at each step. -/
theorem bip_walk_parity {V : Type*} (G : SimpleGraph V) (X : Set V)
    (hX : ∀ u v, G.Adj u v → (u ∈ X ↔ v ∉ X)) :
    ∀ {a b : V} (p : G.Walk a b), ((a ∈ X ↔ b ∈ X) ↔ Even p.length) := by
  intro a b p
  induction p with
  | nil => simp
  | @cons a c b ha p ih =>
    rw [Walk.length_cons, Nat.even_add_one, ← ih]
    have := hX a c ha
    tauto

/-- Distances from a root given by a potential that rises by at most one along each line and
has a predecessor one lower at every other dot. -/
theorem bip_dist_eq_of_potential {V : Type*} (G : SimpleGraph V) (r : V) (f : V → ℕ)
    (h0 : f r = 0) (hadj : ∀ a b, G.Adj a b → f b ≤ f a + 1)
    (hpred : ∀ b, b ≠ r → ∃ a, G.Adj a b ∧ f a + 1 = f b) (v : V) :
    G.dist r v = f v := by
  have hlow : ∀ {a b : V} (p : G.Walk a b), f b ≤ f a + p.length := by
    intro a b p
    induction p with
    | nil => simp
    | @cons a c b ha p ih =>
      have := hadj a c ha
      simp only [Walk.length_cons]; omega
  have hup : ∀ n, ∀ b, f b = n → ∃ p : G.Walk r b, p.length = n := by
    intro n
    induction n with
    | zero =>
      intro b hb
      by_cases hbr : b = r
      · subst hbr; exact ⟨Walk.nil, rfl⟩
      · obtain ⟨a, _, ha⟩ := hpred b hbr; omega
    | succ n ih =>
      intro b hb
      have hbr : b ≠ r := by rintro rfl; omega
      obtain ⟨a, hab, ha⟩ := hpred b hbr
      obtain ⟨p, hp⟩ := ih a (by omega)
      exact ⟨p.concat hab, by simp [hp]⟩
  obtain ⟨p, hp⟩ := hup (f v) v rfl
  have hle := SimpleGraph.dist_le p
  obtain ⟨q, hq⟩ := (p.reachable).exists_walk_length_eq_dist
  have := hlow q
  omega

/-- The theorem of the card. A graph's dots split into two heaps with every line crossing between
them exactly when the graph has no cycle (a closed route repeating no dot) of odd length. -/
theorem two_sides_iff_no_odd_cycle {V : Type*} (G : SimpleGraph V) :
    (∃ X Y : Set V, IsTwoSideCut G X Y) ↔
      ¬ ∃ (u : V) (c : G.Walk u u), c.IsCycle ∧ Odd c.length := by
  constructor
  · rintro ⟨X, Y, hU, hD, hA⟩ ⟨u, c, -, hodd⟩
    have hY : ∀ w, w ∈ Y ↔ w ∉ X := by
      intro w
      constructor
      · intro hw hwX
        exact Set.disjoint_left.mp hD hwX hw
      · intro hw
        have : w ∈ X ∪ Y := by rw [hU]; trivial
        rcases this with h | h
        · exact absurd h hw
        · exact h
    have hX : ∀ u v, G.Adj u v → (u ∈ X ↔ v ∉ X) := by
      intro u v huv
      rcases hA u v huv with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · rw [hY] at h2; tauto
      · rw [hY] at h1; tauto
    exact (Nat.not_even_iff_odd.mpr hodd) ((bip_walk_parity G X hX c).mp Iff.rfl)
  · intro h
    obtain ⟨c⟩ : G.Colorable 2 :=
      two_colorable_iff_forall_loop_even.mpr (bip_even_of_no_odd_cycle G h)
    refine ⟨{v | c v = 0}, {v | c v = 1}, ?_, ?_, ?_⟩
    · ext v
      simp only [Set.mem_union, Set.mem_ofPred_eq, Set.mem_univ, iff_true]
      generalize c v = x
      fin_cases x <;> simp
    · rw [Set.disjoint_left]
      intro v h1 h2
      simp only [Set.mem_ofPred_eq] at h1 h2
      rw [h1] at h2
      exact absurd h2 (by decide)
    · intro u v huv
      have hne := c.valid huv
      simp only [Set.mem_ofPred_eq]
      revert hne
      generalize c u = x
      generalize c v = y
      fin_cases x <;> fin_cases y <;> simp

/-- Colouring by the parity of the distance from a root works. In a graph with no odd cycle, take
any root: for every line from `u` to `v` in the root's piece, the fewest steps from the root to
`u` and to `v` have different remainders on division by two, so no line joins two dots of one
colour. -/
theorem distance_parity_colours_are_the_sides {V : Type*} (G : SimpleGraph V)
    (h : ¬ ∃ (u : V) (c : G.Walk u u), c.IsCycle ∧ Odd c.length) (root u v : V)
    (hu : G.Reachable root u) (huv : G.Adj u v) :
    G.dist root u % 2 ≠ G.dist root v % 2 := by
  have hv : G.Reachable root v := hu.trans huv.reachable
  obtain ⟨p, hp⟩ := hu.exists_walk_length_eq_dist
  obtain ⟨q, hq⟩ := hv.exists_walk_length_eq_dist
  have he := bip_even_of_no_odd_cycle G h root ((p.concat huv).append q.reverse)
  rw [Walk.length_append, Walk.length_concat, Walk.length_reverse, hp, hq, Nat.even_iff] at he
  omega

/-- Every piece of the sheet must cut. Two graphs drawn side by side on one sheet split into two
heaps with every line crossing exactly when each of the two graphs does. -/
theorem side_by_side_cuts_iff_both_cut {V W : Type*} (G : SimpleGraph V) (H : SimpleGraph W) :
    (∃ X Y : Set (V ⊕ W), IsTwoSideCut (G ⊕g H) X Y) ↔
      (∃ X Y : Set V, IsTwoSideCut G X Y) ∧ (∃ X Y : Set W, IsTwoSideCut H X Y) := by
  constructor
  · rintro ⟨X, Y, hU, hD, hA⟩
    refine ⟨⟨Sum.inl ⁻¹' X, Sum.inl ⁻¹' Y, ?_, ?_, ?_⟩,
      ⟨Sum.inr ⁻¹' X, Sum.inr ⁻¹' Y, ?_, ?_, ?_⟩⟩
    · rw [← Set.preimage_union, hU, Set.preimage_univ]
    · exact hD.preimage _
    · intro u v huv
      simpa using hA (Sum.inl u) (Sum.inl v) (by simpa using huv)
    · rw [← Set.preimage_union, hU, Set.preimage_univ]
    · exact hD.preimage _
    · intro u v huv
      simpa using hA (Sum.inr u) (Sum.inr v) (by simpa using huv)
  · rintro ⟨⟨X1, Y1, hU1, hD1, hA1⟩, ⟨X2, Y2, hU2, hD2, hA2⟩⟩
    refine ⟨{s | Sum.elim (· ∈ X1) (· ∈ X2) s}, {s | Sum.elim (· ∈ Y1) (· ∈ Y2) s}, ?_, ?_, ?_⟩
    · ext (a | b)
      · simpa using (Set.ext_iff.mp hU1 a)
      · simpa using (Set.ext_iff.mp hU2 b)
    · rw [Set.disjoint_left]
      rintro (a | b) h1 h2
      · exact Set.disjoint_left.mp hD1 h1 h2
      · exact Set.disjoint_left.mp hD2 h1 h2
    · rintro (a | b) (a' | b') huv
      · simpa using hA1 a a' (by simpa using huv)
      · simp at huv
      · simp at huv
      · simpa using hA2 b b' (by simpa using huv)

/-! The card's graphs. The roster: Ana, Ben, Cleo, Dan, Eve are 0 to 4, and the shifts Mon-am,
Mon-pm, Tue-am, Tue-pm are 5 to 8. The cafes: Bean, Crema, Drip, Grind, Latte are 0 to 4.
The metro map: stations A to F are 0 to 5. In the cut counts, a set `X` of dots stands for the
cut `X` against the rest, and the cut works when every line has one end in `X` and one outside. -/

/-- The nine claims of the roster, each listed once. -/
def rosterLines : List (Fin 9 × Fin 9) :=
  [(0, 5), (0, 6), (1, 5), (1, 7), (2, 6), (2, 8), (3, 7), (3, 8), (4, 5)]

/-- The roster as a graph: a person and a shift are joined when the person claimed the shift. -/
def roster : SimpleGraph (Fin 9) where
  Adj a b := (a, b) ∈ rosterLines ∨ (b, a) ∈ rosterLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel roster.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ rosterLines ∨ (b, a) ∈ rosterLines))

/-- The roster with one line inside a side: Ana covers Ben. -/
def coverLines : List (Fin 9 × Fin 9) := rosterLines ++ [(0, 1)]

def cover : SimpleGraph (Fin 9) where
  Adj a b := (a, b) ∈ coverLines ∨ (b, a) ∈ coverLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cover.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ coverLines ∨ (b, a) ∈ coverLines))

/-- The five rivalries of the cafes, closing a ring. -/
def cafeLines : List (Fin 5 × Fin 5) := [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]

def cafes : SimpleGraph (Fin 5) where
  Adj a b := (a, b) ∈ cafeLines ∨ (b, a) ∈ cafeLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cafes.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ cafeLines ∨ (b, a) ∈ cafeLines))

/-- The eight lines of the metro map. -/
def metroLines : List (Fin 6 × Fin 6) :=
  [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]

def metro : SimpleGraph (Fin 6) where
  Adj a b := (a, b) ∈ metroLines ∨ (b, a) ∈ metroLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel metro.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ metroLines ∨ (b, a) ∈ metroLines))

/-- The odd loop the check prints: Drip, Crema, Bean, Latte, Grind and back to Drip. -/
def cafeLoop : cafes.Walk 2 2 :=
  .cons (v := 1) (by decide) <| .cons (v := 0) (by decide) <| .cons (v := 4) (by decide) <|
    .cons (v := 3) (by decide) <| .cons (v := 2) (by decide) .nil

/-- The 3-line loop made by Ana covering Ben: Ben, Ana, Mon-am and back to Ben. -/
def coverLoop : cover.Walk 1 1 :=
  .cons (v := 0) (by decide) <| .cons (v := 5) (by decide) <| .cons (v := 1) (by decide) .nil

-- The roster: 9 lines, 5 staff with 2 2 2 2 1 lines and 4 shifts with 3 2 2 2, both tallies 9.
example : roster.edgeFinset.card = 9 := by decide
example : (List.ofFn fun i : Fin 9 => roster.degree i) = [2, 2, 2, 2, 1, 3, 2, 2, 2] := by decide
-- Staff against shifts is a working cut.
example : IsTwoSideCut roster {0, 1, 2, 3, 4} {5, 6, 7, 8} := by
  refine ⟨?_, ?_, ?_⟩
  · ext x
    simp only [Set.mem_union, Set.mem_insert_iff, Set.mem_singleton_iff, Set.mem_univ, iff_true]
    revert x
    decide
  · rw [Set.disjoint_left]
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    decide
  · simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    decide
-- Of the 512 cuts of the roster's 9 dots, exactly 2 work: the cut and its mirror.
example : (Finset.univ.filter (fun X : Finset (Fin 9) =>
    ∀ u v, roster.Adj u v → (u ∈ X ↔ v ∉ X))).card = 2 := by decide +kernel
-- The search from Ana: 0 Ana; 1 Mon-am Mon-pm; 2 Ben Cleo Eve; 3 Tue-am Tue-pm; 4 Dan.
example : (List.ofFn fun i : Fin 9 => roster.dist 0 i) = [0, 2, 2, 4, 2, 1, 1, 3, 3] := by
  have key := bip_dist_eq_of_potential roster 0 (![0, 2, 2, 4, 2, 1, 1, 3, 3] : Fin 9 → ℕ) (by decide) (by decide) (by decide)
  simp only [key]
  decide
-- The cafes: none of the 32 cuts works, and there is no triangle.
example : (Finset.univ.filter (fun X : Finset (Fin 5) =>
    ∀ u v, cafes.Adj u v → (u ∈ X ↔ v ∉ X))).card = 0 := by decide +kernel
example : cafes.CliqueFree 3 := by
  unfold CliqueFree
  decide
-- The search from Bean: Crema and Latte 1 step out, Drip and Grind 2.
example : (List.ofFn fun i : Fin 5 => cafes.dist 0 i) = [0, 1, 2, 2, 1] := by
  have key := bip_dist_eq_of_potential cafes 0 (![0, 1, 2, 2, 1] : Fin 5 → ℕ) (by decide) (by decide) (by decide)
  simp only [key]
  decide
-- The clash Drip-Grind closes a loop of 2 + 1 + 2 = 5 lines, a real cycle.
example : cafeLoop.IsCycle ∧ cafeLoop.length = 5 := by
  refine ⟨?_, rfl⟩
  rw [Walk.isCycle_iff_isPath_tail_and_le_length, Walk.isPath_def]
  decide
-- Ana covers Ben: none of the 512 cuts works, and Ben Ana Mon-am is a 3-line cycle.
example : (Finset.univ.filter (fun X : Finset (Fin 9) =>
    ∀ u v, cover.Adj u v → (u ∈ X ↔ v ∉ X))).card = 0 := by decide +kernel
example : coverLoop.IsCycle ∧ coverLoop.length = 3 := by
  refine ⟨?_, rfl⟩
  rw [Walk.isCycle_iff_isPath_tail_and_le_length, Walk.isPath_def]
  decide
-- The metro map: 2 of the 64 cuts work, and A C E against B D F is one of them.
example : (Finset.univ.filter (fun X : Finset (Fin 6) =>
    ∀ u v, metro.Adj u v → (u ∈ X ↔ v ∉ X))).card = 2 := by decide +kernel
example : IsTwoSideCut metro {0, 2, 4} {1, 3, 5} := by
  refine ⟨?_, ?_, ?_⟩
  · ext x
    simp only [Set.mem_union, Set.mem_insert_iff, Set.mem_singleton_iff, Set.mem_univ, iff_true]
    revert x
    decide
  · rw [Set.disjoint_left]
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    decide
  · simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    decide

#print axioms bip_bypass_length_mod_two
#print axioms bip_even_of_no_odd_cycle
#print axioms bip_walk_parity
#print axioms bip_dist_eq_of_potential
#print axioms two_sides_iff_no_odd_cycle
#print axioms distance_parity_colours_are_the_sides
#print axioms side_by_side_cuts_iff_both_cut
