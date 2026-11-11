-- Konig's theorem: in every finite bipartite graph the largest matching has as many lines as the smallest set of dots touching every line.
import Mathlib.Combinatorics.SimpleGraph.Matching
import Mathlib.Combinatorics.SimpleGraph.Bipartite
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Data.Fin.VecNotation
import Mathlib.Combinatorics.Hall.Basic
import Mathlib.Combinatorics.Enumerative.DoubleCounting

open SimpleGraph

/-! A matching is a `Subgraph` of `G` in which every dot it uses has exactly one partner
(Mathlib's `Subgraph.IsMatching`); its size is the number of its lines, `M.edgeSet.ncard`.
"Bipartite" is Mathlib's `G.IsBipartite`: the dots can be split into two sides with every line
crossing between them. -/

/-- A vertex cover (a "cover"): a set `C` of dots meeting every line of `G`. -/
def IsVertexCover {V : Type*} (G : SimpleGraph V) (C : Finset V) : Prop :=
  ∀ ⦃u v : V⦄, G.Adj u v → u ∈ C ∨ v ∈ C

/-- An edge cover: a set `F` of lines of `G` reaching every dot. -/
def IsEdgeCover {V : Type*} (G : SimpleGraph V) (F : Finset (Sym2 V)) : Prop :=
  (∀ e ∈ F, e ∈ G.edgeSet) ∧ ∀ v : V, ∃ e ∈ F, v ∈ e

/-- The matching number ν: the most lines in a matching. -/
noncomputable def matchingNumber {V : Type*} (G : SimpleGraph V) : ℕ :=
  sSup {k | ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet.ncard = k}

/-- The cover number τ: the fewest dots in a vertex cover. -/
noncomputable def coverNumber {V : Type*} (G : SimpleGraph V) : ℕ :=
  sInf {k | ∃ C : Finset V, IsVertexCover G C ∧ C.card = k}

/-- The edge-cover number ρ: the fewest lines in an edge cover. -/
noncomputable def edgeCoverNumber {V : Type*} (G : SimpleGraph V) : ℕ :=
  sInf {k | ∃ F : Finset (Sym2 V), IsEdgeCover G F ∧ F.card = k}

/-! Helper lemmas. A matching is handled as a finite set of lines, no two sharing a dot. -/

/-- A finite set of lines of `G`, no two of which share a dot. -/
def FinMatching {V : Type*} (G : SimpleGraph V) (F : Finset (Sym2 V)) : Prop :=
  (∀ e ∈ F, e ∈ G.edgeSet) ∧ ∀ e ∈ F, ∀ f ∈ F, ∀ v : V, v ∈ e → v ∈ f → e = f

/-- The lines of a matching subgraph form a `FinMatching`. -/
theorem finMatching_of_isMatching {V : Type*} [Fintype V] {G : SimpleGraph V} {M : G.Subgraph}
    (hM : M.IsMatching) : FinMatching G M.edgeSet.toFinite.toFinset := by
  constructor
  · intro e he
    rw [Set.Finite.mem_toFinset] at he
    exact M.edgeSet_subset he
  · intro e he f hf v hve hvf
    rw [Set.Finite.mem_toFinset] at he hf
    induction e using Sym2.ind with
    | _ a b =>
    induction f using Sym2.ind with
    | _ c d =>
    rw [Subgraph.mem_edgeSet] at he hf
    rcases Sym2.mem_iff.mp hve with h1 | h1 <;> rcases Sym2.mem_iff.mp hvf with h2 | h2 <;>
      subst h1 <;> subst h2
    · rw [hM.eq_of_adj_left he hf]
    · rw [hM.eq_of_adj_left he hf.symm, Sym2.eq_swap]
    · rw [hM.eq_of_adj_left he.symm hf, Sym2.eq_swap]
    · rw [hM.eq_of_adj_left he.symm hf.symm]

/-- Every `FinMatching` is the set of lines of a matching subgraph. -/
theorem exists_isMatching_of_finMatching {V : Type*} {G : SimpleGraph V} {F : Finset (Sym2 V)}
    (hF : FinMatching G F) : ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet = ↑F := by
  refine ⟨{ verts := {v | ∃ e ∈ F, v ∈ e}
            Adj := fun u v => s(u, v) ∈ F
            adj_sub := fun h => (G.mem_edgeSet).mp (hF.1 _ h)
            edge_vert := fun h => ⟨_, h, Sym2.mem_mk_left _ _⟩
            symm := ⟨fun u v h => by rw [Sym2.eq_swap]; exact h⟩ }, ?_, ?_⟩
  · intro v hv
    obtain ⟨e, he, hve⟩ := hv
    obtain ⟨w, rfl⟩ := Sym2.mem_iff_exists.mp hve
    refine ⟨w, he, fun w' hw' => ?_⟩
    have := hF.2 _ hw' _ he v (Sym2.mem_mk_left _ _) (Sym2.mem_mk_left _ _)
    exact Sym2.congr_right.mp this
  · ext e
    induction e using Sym2.ind with
    | _ a b => rw [Subgraph.mem_edgeSet, Finset.mem_coe]

/-- A `FinMatching` touches exactly twice as many dots as it has lines. -/
theorem card_covered_finMatching {V : Type*} [Fintype V] [DecidableEq V] {G : SimpleGraph V}
    {F : Finset (Sym2 V)} (hF : FinMatching G F) :
    (Finset.univ.filter (fun v => ∃ e ∈ F, v ∈ e)).card = 2 * F.card := by
  have h1 : Finset.univ.filter (fun v => ∃ e ∈ F, v ∈ e) =
      F.biUnion (fun e => Finset.univ.filter (· ∈ e)) := by
    ext v; simp
  rw [h1, Finset.card_biUnion]
  · rw [Finset.sum_const_nat (m := 2), mul_comm]
    intro e he
    have hd := hF.1 e he
    induction e using Sym2.ind with
    | _ a b =>
      have hab : a ≠ b := G.ne_of_adj hd
      have : Finset.univ.filter (· ∈ s(a, b)) = {a, b} := by ext; simp
      rw [this, Finset.card_pair hab]
  · intro e he f hf hne
    rw [Function.onFun, Finset.disjoint_left]
    intro v hv hv'
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hv hv'
    exact hne (hF.2 e he f hf v hv hv')

/-- A `FinMatching` has no more lines than any vertex cover has dots. -/
theorem finMatching_card_le_cover {V : Type*} {G : SimpleGraph V} {F : Finset (Sym2 V)}
    (hF : FinMatching G F) {C : Finset V} (hC : IsVertexCover G C) : F.card ≤ C.card := by
  refine Finset.card_le_card_of_forall_subsingleton (fun e v => v ∈ e) ?_ ?_
  · intro e he
    have hd := hF.1 e he
    induction e using Sym2.ind with
    | _ a b =>
      rcases hC hd with h | h
      · exact ⟨a, h, Sym2.mem_mk_left _ _⟩
      · exact ⟨b, h, Sym2.mem_mk_right _ _⟩
  · rintro v - e ⟨he, hve⟩ f ⟨hf, hvf⟩
    exact hF.2 e he f hf v hve hvf

/-- Matching sizes, read through `FinMatching`. -/
theorem mem_matchingSet_iff {V : Type*} [Fintype V] (G : SimpleGraph V) (k : ℕ) :
    k ∈ {k | ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet.ncard = k} ↔
      ∃ F : Finset (Sym2 V), FinMatching G F ∧ F.card = k := by
  constructor
  · rintro ⟨M, hM, rfl⟩
    exact ⟨_, finMatching_of_isMatching hM, (Set.ncard_eq_toFinset_card M.edgeSet).symm⟩
  · rintro ⟨F, hF, rfl⟩
    obtain ⟨M, hM, hE⟩ := exists_isMatching_of_finMatching hF
    exact ⟨M, hM, by rw [hE, Set.ncard_coe_finset]⟩

/-- The matching number is reached, and bounds every matching. -/
theorem matchingNumber_spec {V : Type*} [Fintype V] (G : SimpleGraph V) :
    (∃ F : Finset (Sym2 V), FinMatching G F ∧ F.card = matchingNumber G) ∧
      ∀ F : Finset (Sym2 V), FinMatching G F → F.card ≤ matchingNumber G := by
  have hbdd : BddAbove {k | ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet.ncard = k} := by
    refine ⟨Fintype.card V, fun k hk => ?_⟩
    obtain ⟨F, hF, rfl⟩ := (mem_matchingSet_iff G k).mp hk
    have := finMatching_card_le_cover hF (C := Finset.univ) (fun u _ _ => Or.inl (Finset.mem_univ u))
    simpa using this
  have hne : {k | ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet.ncard = k}.Nonempty := by
    refine ⟨0, (mem_matchingSet_iff G 0).mpr ⟨∅, ⟨by simp, by simp⟩, rfl⟩⟩
  refine ⟨(mem_matchingSet_iff G _).mp (Nat.sSup_mem hne hbdd), fun F hF => ?_⟩
  exact le_csSup hbdd ((mem_matchingSet_iff G _).mpr ⟨F, hF, rfl⟩)

/-- The cover number is reached, and is at most the size of every vertex cover. -/
theorem coverNumber_spec {V : Type*} [Fintype V] (G : SimpleGraph V) :
    (∃ C : Finset V, IsVertexCover G C ∧ C.card = coverNumber G) ∧
      ∀ C : Finset V, IsVertexCover G C → coverNumber G ≤ C.card := by
  refine ⟨Nat.sInf_mem (s := {k | ∃ C : Finset V, IsVertexCover G C ∧ C.card = k}) ⟨_, Finset.univ, fun u _ _ => Or.inl (Finset.mem_univ u), rfl⟩,
    fun C hC => Nat.sInf_le ⟨C, hC, rfl⟩⟩

/-- In a finite bipartite graph some vertex cover is no larger than some matching
(Hall's theorem with a deficiency, by adding `d` extra dots joined to the whole left side). -/
theorem exists_cover_le_finMatching {V : Type*} [Fintype V] (G : SimpleGraph V)
    (hG : G.IsBipartite) :
    ∃ C : Finset V, IsVertexCover G C ∧ ∃ F : Finset (Sym2 V), FinMatching G F ∧ C.card ≤ F.card := by
  classical
  obtain ⟨c⟩ := hG
  set L : Finset V := Finset.univ.filter (fun v => c v = 0) with hLdef
  have hLadj : ∀ u v, G.Adj u v → (u ∈ L ↔ v ∉ L) := by
    intro u v h
    have hv := c.valid h
    simp only [hLdef, Finset.mem_filter, Finset.mem_univ, true_and]
    revert hv
    generalize c u = a
    generalize c v = b
    revert a b
    decide
  set N : Finset V → Finset V := fun S => S.biUnion (fun x => G.neighborFinset x) with hNdef
  obtain ⟨S, hSL, hSmax⟩ := Finset.exists_max_image L.powerset
    (fun S => (S.card : ℤ) - (N S).card) ⟨∅, Finset.empty_mem_powerset _⟩
  rw [Finset.mem_powerset] at hSL
  have hd0 : (0 : ℤ) ≤ S.card - (N S).card := by
    simpa [hNdef] using hSmax ∅ (Finset.empty_mem_powerset _)
  set d : ℕ := S.card - (N S).card with hd
  let t : L → Finset (V ⊕ Fin d) := fun x => (G.neighborFinset x).disjSum Finset.univ
  have hall : ∀ s : Finset L, s.card ≤ (s.biUnion t).card := by
    intro s
    rcases s.eq_empty_or_nonempty with rfl | ⟨x0, hx0⟩
    · simp
    set s' : Finset V := s.map (Function.Embedding.subtype _) with hs'
    have hs'L : s' ⊆ L := by
      intro v hv
      simp only [hs', Finset.mem_map, Function.Embedding.coe_subtype] at hv
      obtain ⟨x, -, rfl⟩ := hv
      exact x.2
    have hsub : (N s').disjSum (Finset.univ : Finset (Fin d)) ⊆ s.biUnion t := by
      intro z hz
      rw [Finset.mem_biUnion]
      rcases z with v | i
      · rw [Finset.inl_mem_disjSum] at hz
        simp only [hNdef, Finset.mem_biUnion] at hz
        obtain ⟨x', hx', hvx⟩ := hz
        simp only [hs', Finset.mem_map, Function.Embedding.coe_subtype] at hx'
        obtain ⟨x, hx, rfl⟩ := hx'
        exact ⟨x, hx, Finset.inl_mem_disjSum.mpr hvx⟩
      · exact ⟨x0, hx0, Finset.inr_mem_disjSum.mpr (Finset.mem_univ i)⟩
    have hmax := hSmax s' (Finset.mem_powerset.mpr hs'L)
    have hcard : s'.card = s.card := Finset.card_map _
    have h1 : s.card ≤ (N s').card + d := by
      omega
    calc s.card ≤ (N s').card + d := h1
      _ = ((N s').disjSum (Finset.univ : Finset (Fin d))).card := by
        rw [Finset.card_disjSum, Finset.card_univ, Fintype.card_fin]
      _ ≤ _ := Finset.card_le_card hsub
  obtain ⟨f, hfinj, hft⟩ := (Finset.all_card_le_biUnion_card_iff_exists_injective t).mp hall
  -- the pairs (x, v) with x on the left matched to a real dot v
  set P : Finset (L × V) := Finset.univ.filter (fun p => f p.1 = Sum.inl p.2) with hPdef
  have hPadj : ∀ p ∈ P, G.Adj p.1 p.2 := by
    intro p hp
    simp only [hPdef, Finset.mem_filter, Finset.mem_univ, true_and] at hp
    have := hft p.1
    rw [hp, Finset.inl_mem_disjSum, mem_neighborFinset] at this
    exact this
  have hPnotL : ∀ p ∈ P, p.2 ∉ L := fun p hp => (hLadj _ _ (hPadj p hp)).mp p.1.2
  set F : Finset (Sym2 V) := P.image (fun p => s(p.1.1, p.2)) with hFdef
  -- |L| ≤ |P| + d
  have hLP : L.card ≤ P.card + d := by
    have h1 : (Finset.univ.image f).card = L.card := by
      rw [Finset.card_image_of_injective _ hfinj, Finset.card_univ, Fintype.card_coe]
    have h2 : Finset.univ.image f ⊆ P.image (fun p => Sum.inl p.2) ∪
        (Finset.univ : Finset (Fin d)).image Sum.inr := by
      intro z hz
      rw [Finset.mem_image] at hz
      obtain ⟨x, -, rfl⟩ := hz
      rw [Finset.mem_union, Finset.mem_image, Finset.mem_image]
      rcases hfx : f x with v | i
      · exact Or.inl ⟨(x, v), by simp [hPdef, hfx], rfl⟩
      · exact Or.inr ⟨i, Finset.mem_univ _, rfl⟩
    calc L.card = (Finset.univ.image f).card := h1.symm
      _ ≤ _ := Finset.card_le_card h2
      _ ≤ (P.image (fun p => (Sum.inl p.2 : V ⊕ Fin d))).card +
          ((Finset.univ : Finset (Fin d)).image Sum.inr).card := Finset.card_union_le _ _
      _ ≤ P.card + d := by
        gcongr
        · exact Finset.card_image_le
        · exact Finset.card_image_le.trans (by simp)
  have hFcard : F.card = P.card := by
    rw [hFdef, Finset.card_image_of_injOn]
    intro p hp q hq hpq
    simp only at hpq
    rcases Sym2.eq_iff.mp hpq with ⟨h1, h2⟩ | ⟨h1, h2⟩
    · exact Prod.ext (Subtype.ext h1) h2
    · exact absurd (h1 ▸ p.1.2) (hPnotL q hq)
  have hFm : FinMatching G F := by
    constructor
    · intro e he
      rw [hFdef, Finset.mem_image] at he
      obtain ⟨p, hp, rfl⟩ := he
      exact hPadj p hp
    · intro e he e' he' u hu hu'
      rw [hFdef, Finset.mem_image] at he he'
      obtain ⟨p, hp, rfl⟩ := he
      obtain ⟨q, hq, rfl⟩ := he'
      have hpf : f p.1 = Sum.inl p.2 := by
        simpa [hPdef] using hp
      have hqf : f q.1 = Sum.inl q.2 := by
        simpa [hPdef] using hq
      rcases Sym2.mem_iff.mp hu with h1 | h1 <;> rcases Sym2.mem_iff.mp hu' with h2 | h2
      · have : p.1 = q.1 := Subtype.ext (h1.symm.trans h2)
        have h3 : p.2 = q.2 := by
          rw [this] at hpf
          exact Sum.inl_injective (hpf.symm.trans hqf)
        rw [this, h3]
      · have : q.2 ∈ L := by rw [← h2, h1]; exact p.1.2
        exact absurd this (hPnotL q hq)
      · have : p.2 ∈ L := by rw [← h1, h2]; exact q.1.2
        exact absurd this (hPnotL p hp)
      · have : p.1 = q.1 := hfinj (by rw [hpf, hqf, ← h1, ← h2])
        have h3 : p.2 = q.2 := h1.symm.trans h2
        rw [this, h3]
  refine ⟨(L \ S) ∪ N S, ?_, F, hFm, ?_⟩
  · intro u v h
    have key : ∀ a b, G.Adj a b → a ∈ L → a ∈ (L \ S) ∪ N S ∨ b ∈ (L \ S) ∪ N S := by
      intro a b hab ha
      by_cases haS : a ∈ S
      · right
        rw [Finset.mem_union]
        right
        simp only [hNdef, Finset.mem_biUnion]
        exact ⟨a, haS, (mem_neighborFinset _ _ _).mpr hab⟩
      · left
        exact Finset.mem_union_left _ (Finset.mem_sdiff.mpr ⟨ha, haS⟩)
    by_cases hu : u ∈ L
    · exact key u v h hu
    · have hv : v ∈ L := by
        by_contra hv
        exact hu ((hLadj u v h).mpr hv)
      exact (key v u h.symm hv).symm
  · have h1 := Finset.card_union_le (L \ S) (N S)
    have h2 := Finset.card_sdiff_add_card_eq_card hSL
    omega

#print axioms finMatching_of_isMatching
#print axioms exists_isMatching_of_finMatching
#print axioms card_covered_finMatching
#print axioms finMatching_card_le_cover
#print axioms mem_matchingSet_iff
#print axioms matchingNumber_spec
#print axioms coverNumber_spec
#print axioms exists_cover_le_finMatching

/-- Konig's theorem: in a finite bipartite graph, the largest matching and the smallest vertex
cover have the same size, ν(G) = τ(G). -/
theorem konig_matching_number_eq_cover_number {V : Type*} [Fintype V] (G : SimpleGraph V)
    (hG : G.IsBipartite) :
    matchingNumber G = coverNumber G := by
  obtain ⟨C, hC, F, hF, hCF⟩ := exists_cover_le_finMatching G hG
  obtain ⟨⟨F', hF', hF'c⟩, hν⟩ := matchingNumber_spec G
  obtain ⟨⟨C', hC', hC'c⟩, hτ⟩ := coverNumber_spec G
  apply le_antisymm
  · rw [← hF'c, ← hC'c]
    exact finMatching_card_le_cover hF' hC'
  · exact (hτ C hC).trans (hCF.trans (hν F hF))

/-- Step 0, in every finite graph, two-sided or not: every vertex cover has at least as many dots
as any matching has lines, since each matched line needs a guard of its own (so ν ≤ τ). -/
theorem matching_card_le_vertex_cover_card {V : Type*} [Fintype V] (G : SimpleGraph V)
    (M : G.Subgraph) (hM : M.IsMatching) (C : Finset V) (hC : IsVertexCover G C) :
    M.edgeSet.ncard ≤ C.card := by
  have h := finMatching_card_le_cover (finMatching_of_isMatching hM) hC
  rwa [← Set.ncard_eq_toFinset_card] at h

/-- Gallai's identities, in every finite graph: the independence number plus the cover number is
the number of dots, α + τ = n; and when no dot is without a line, the matching number plus the
edge-cover number is the number of dots, ν + ρ = n. -/
theorem gallai_identities {V : Type*} [Fintype V] (G : SimpleGraph V) :
    G.indepNum + coverNumber G = Fintype.card V ∧
      ((∀ v : V, ∃ w : V, G.Adj v w) → matchingNumber G + edgeCoverNumber G = Fintype.card V) := by
  classical
  obtain ⟨⟨C0, hC0, hC0c⟩, hτ⟩ := coverNumber_spec G
  obtain ⟨⟨F0, hF0, hF0c⟩, hν⟩ := matchingNumber_spec G
  have hn : ∀ s : Finset V, s.card ≤ Fintype.card V := fun s => Finset.card_le_univ s
  refine ⟨?_, fun hiso => ?_⟩
  · obtain ⟨s, hs⟩ := G.exists_isNIndepSet_indepNum
    have h1 : coverNumber G ≤ sᶜ.card := by
      apply hτ
      intro u v huv
      by_contra hcon
      push Not at hcon
      simp only [Finset.mem_compl, not_not] at hcon
      exact hs.isIndepSet hcon.1 hcon.2 (G.ne_of_adj huv) huv
    have h2 : C0ᶜ.card ≤ G.indepNum := by
      apply SimpleGraph.IsIndepSet.card_le_indepNum
      intro u hu v hv _ huv
      simp only [Finset.coe_compl, Set.mem_compl_iff, Finset.mem_coe] at hu hv
      rcases hC0 huv with h | h
      · exact hu h
      · exact hv h
    rw [Finset.card_compl] at h1 h2
    have := hs.card_eq
    have := hn s
    have := hn C0
    omega
  · set U := Finset.univ.filter (fun v => ∃ e ∈ F0, v ∈ e) with hU
    have hUc : U.card = 2 * F0.card := card_covered_finMatching hF0
    let g : V → Sym2 V := fun v => s(v, (hiso v).choose)
    set E := F0 ∪ Uᶜ.image g with hE
    have hEc : IsEdgeCover G E := by
      constructor
      · intro e he
        rcases Finset.mem_union.mp he with he | he
        · exact hF0.1 e he
        · obtain ⟨v, -, rfl⟩ := Finset.mem_image.mp he
          exact (hiso v).choose_spec
      · intro v
        by_cases hv : v ∈ U
        · obtain ⟨e, he, hve⟩ := (Finset.mem_filter.mp hv).2
          exact ⟨e, Finset.mem_union_left _ he, hve⟩
        · exact ⟨g v, Finset.mem_union_right _ (Finset.mem_image.mpr ⟨v, Finset.mem_compl.mpr hv, rfl⟩),
            Sym2.mem_mk_left _ _⟩
    have hρle : edgeCoverNumber G ≤ E.card := Nat.sInf_le ⟨E, hEc, rfl⟩
    have hEcard : E.card ≤ F0.card + Uᶜ.card :=
      (Finset.card_union_le _ _).trans (Nat.add_le_add_left Finset.card_image_le _)
    rw [Finset.card_compl] at hEcard
    have hUn := hn U
    obtain ⟨Fc, hFc, hFcc⟩ : ∃ Fc : Finset (Sym2 V), IsEdgeCover G Fc ∧ Fc.card = edgeCoverNumber G :=
      Nat.sInf_mem (s := {k | ∃ F : Finset (Sym2 V), IsEdgeCover G F ∧ F.card = k}) ⟨_, E, hEc, rfl⟩
    obtain ⟨M, hMmem, hMmax⟩ := Finset.exists_max_image (Fc.powerset.filter (FinMatching G))
      Finset.card ⟨∅, Finset.mem_filter.mpr ⟨Finset.empty_mem_powerset _, by simp [FinMatching]⟩⟩
    rw [Finset.mem_filter, Finset.mem_powerset] at hMmem
    obtain ⟨hMFc, hM⟩ := hMmem
    set W := (Finset.univ.filter (fun v => ∃ e ∈ M, v ∈ e))ᶜ with hW
    have hWc : W.card = Fintype.card V - 2 * M.card := by
      rw [hW, Finset.card_compl, card_covered_finMatching hM]
    have hWle : W.card ≤ (Fc \ M).card := by
      refine Finset.card_le_card_of_forall_subsingleton (fun w e => w ∈ e) ?_ ?_
      · intro w hw
        obtain ⟨e, he, hwe⟩ := hFc.2 w
        refine ⟨e, Finset.mem_sdiff.mpr ⟨he, fun heM => ?_⟩, hwe⟩
        simp only [hW, Finset.mem_compl, Finset.mem_filter, Finset.mem_univ, true_and] at hw
        exact hw ⟨e, heM, hwe⟩
      · rintro e he w1 ⟨hw1, hw1e⟩ w2 ⟨hw2, hw2e⟩
        by_contra hne
        rw [Finset.mem_sdiff] at he
        have hmem : ∀ u, u ∈ e → u ∉ Finset.univ.filter (fun v => ∃ e ∈ M, v ∈ e) := by
          intro u hu
          rw [(Sym2.mem_and_mem_iff hne).mp ⟨hw1e, hw2e⟩, Sym2.mem_iff] at hu
          rcases hu with rfl | rfl
          · exact Finset.mem_compl.mp hw1
          · exact Finset.mem_compl.mp hw2
        have hins : FinMatching G (insert e M) := by
          constructor
          · intro a ha
            rcases Finset.mem_insert.mp ha with rfl | ha
            · exact hFc.1 a he.1
            · exact hM.1 a ha
          · intro a ha b hb u hua hub
            rcases Finset.mem_insert.mp ha with rfl | ha' <;>
              rcases Finset.mem_insert.mp hb with rfl | hb'
            · rfl
            · exact absurd (Finset.mem_filter.mpr ⟨Finset.mem_univ _, b, hb', hub⟩) (hmem u hua)
            · exact absurd (Finset.mem_filter.mpr ⟨Finset.mem_univ _, a, ha', hua⟩) (hmem u hub)
            · exact hM.2 a ha' b hb' u hua hub
        have := hMmax (insert e M) (Finset.mem_filter.mpr
          ⟨Finset.mem_powerset.mpr (Finset.insert_subset he.1 hMFc), hins⟩)
        rw [Finset.card_insert_of_notMem he.2] at this
        omega
    have hsd := Finset.card_sdiff_add_card_eq_card hMFc
    have hMν := hν M hM
    have h2M : 2 * M.card ≤ Fintype.card V := (card_covered_finMatching hM) ▸ hn _
    omega

/-! The card's town plan. West junctions W1-W4 are `0`-`3` on the left, east junctions E1-E4
are `0`-`3` on the right. A street `(w, e)` is a bridge from west junction `w` to east junction
`e`. A matching is a set of streets with no junction used twice; a cover is a west set `A` and
an east set `B` together meeting every street. -/

/-- The eight streets: W1-E1, W1-E2, W2-E1, W2-E2, W3-E2, W4-E2, W4-E3, W4-E4. -/
def streets : Finset (Fin 4 × Fin 4) :=
  {(0, 0), (0, 1), (1, 0), (1, 1), (2, 1), (3, 1), (3, 2), (3, 3)}

/-- The same eight streets, numbered 0 to 7. -/
def street : Fin 8 → Fin 4 × Fin 4 :=
  ![(0, 0), (0, 1), (1, 0), (1, 1), (2, 1), (3, 1), (3, 2), (3, 3)]

example : ∀ i : Fin 8, street i ∈ streets := by decide

/-- A set of streets is a matching when no west and no east junction appears twice. -/
def IsTownMatching (S : Finset (Fin 4 × Fin 4)) : Prop :=
  S ⊆ streets ∧ (∀ a ∈ S, ∀ b ∈ S, a.1 = b.1 → a = b) ∧ (∀ a ∈ S, ∀ b ∈ S, a.2 = b.2 → a = b)

instance (S : Finset (Fin 4 × Fin 4)) : Decidable (IsTownMatching S) := by
  unfold IsTownMatching; infer_instance

/-- Guards at west set `A` and east set `B` watch every street. -/
def IsTownCover (A B : Finset (Fin 4)) : Prop := ∀ s ∈ streets, s.1 ∈ A ∨ s.2 ∈ B

instance (A B : Finset (Fin 4)) : Decidable (IsTownCover A B) := by
  unfold IsTownCover; infer_instance

/-- No street joins two junctions of west set `A` and east set `B`. -/
def IsTownIndep (A B : Finset (Fin 4)) : Prop := ∀ s ∈ streets, ¬ (s.1 ∈ A ∧ s.2 ∈ B)

instance (A B : Finset (Fin 4)) : Decidable (IsTownIndep A B) := by
  unfold IsTownIndep; infer_instance

/-- A set of streets reaches every junction on both banks. -/
def IsTownEdgeCover (F : Finset (Fin 4 × Fin 4)) : Prop :=
  F ⊆ streets ∧ (∀ w : Fin 4, ∃ s ∈ F, s.1 = w) ∧ (∀ e : Fin 4, ∃ s ∈ F, s.2 = e)

instance (F : Finset (Fin 4 × Fin 4)) : Decidable (IsTownEdgeCover F) := by
  unfold IsTownEdgeCover; infer_instance

/-- The east junctions reached by the streets out of west set `S`, Hall's `N(S)`. -/
def reach (S : Finset (Fin 4)) : Finset (Fin 4) := (streets.filter (·.1 ∈ S)).image (·.2)

-- 8 junctions, 8 streets.
example : 4 + 4 = 8 ∧ streets.card = 8 := by decide
-- The matching W1-E2, W2-E1, W4-E3 has 3 streets, and no matching has 4 or more.
example : IsTownMatching {(0, 1), (1, 0), (3, 2)} ∧ ({(0, 1), (1, 0), (3, 2)} : Finset _).card = 3 := by
  decide
-- A matching of 4 streets would give the 4 west junctions 4 different east partners along streets:
-- impossible, since W1, W2, W3 reach only E1 and E2.
example : ∀ a b c d : Fin 4, (0, a) ∈ streets → (1, b) ∈ streets → (2, c) ∈ streets →
    (3, d) ∈ streets → ¬ [a, b, c, d].Nodup := by decide
-- Guards at W4, E1, E2 watch every street, and no 2 guards do.
example : IsTownCover {3} {0, 1} := by decide
example : ∀ A B : Finset (Fin 4), IsTownCover A B → 3 ≤ A.card + B.card := by decide
-- Among the 256 sets of junctions, W4, E1, E2 is the only cover of 3.
example : ∀ A B : Finset (Fin 4), IsTownCover A B → A.card + B.card = 3 → A = {3} ∧ B = {0, 1} := by
  decide
-- Hall: W1, W2, W3 reach only E1, E2, shortfall 3 - 2 = 1, and no west set falls short by more.
example : reach {0, 1, 2} = {0, 1} ∧ ({0, 1, 2} : Finset (Fin 4)).card - (reach {0, 1, 2}).card = 1 := by
  decide
example : ∀ S : Finset (Fin 4), S.card ≤ (reach S).card + 1 := by decide
-- The guards from Hall's set: N(S) together with the west junctions outside S, W4, E1, E2.
example : IsTownCover ({0, 1, 2}ᶜ) (reach {0, 1, 2}) ∧ ({0, 1, 2}ᶜ : Finset (Fin 4)) = {3} := by decide
example : 4 - 1 = 3 := by norm_num
-- The 5 junctions the cover leaves out (W1, W2, W3, E3, E4) are independent; no 6 are.
example : IsTownIndep {0, 1, 2} {2, 3} := by decide
example : ∀ A B : Finset (Fin 4), IsTownIndep A B → A.card + B.card ≤ 5 := by decide
-- An edge cover of 5 streets, and none smaller.
example : IsTownEdgeCover {(0, 1), (1, 0), (3, 2), (2, 1), (3, 3)} := by decide
-- No 4 streets (repeats allowed, so also no 3 or fewer) reach all 8 junctions.
example : ∀ i j k l : Fin 8,
    ¬ ((∀ w : Fin 4, w = (street i).1 ∨ w = (street j).1 ∨ w = (street k).1 ∨ w = (street l).1) ∧
      (∀ e : Fin 4, e = (street i).2 ∨ e = (street j).2 ∨ e = (street k).2 ∨ e = (street l).2)) := by
  decide
-- Gallai: 5 + 3 = 8 and 3 + 5 = 8; Step 4: 3 + 2 = 5 with 8 - 2 * 3 = 2.
example : 5 + 3 = 8 ∧ 3 + 5 = 8 ∧ 8 - 2 * 3 = 2 ∧ 3 + 2 = 5 := by norm_num
-- Mistakes: both ends of each matched street is 6 guards; one whole bank is 4 guards.
example : IsTownCover {0, 1, 3} {1, 0, 2} ∧ ({0, 1, 3} : Finset (Fin 4)).card + ({1, 0, 2} : Finset (Fin 4)).card = 6 := by
  decide
example : IsTownCover Finset.univ ∅ ∧ (Finset.univ : Finset (Fin 4)).card = 4 := by decide

/-! A ring of three junctions, not two-sided: matching 1, but 2 guards. -/

/-- The three streets of the ring, as pairs of junctions `0`, `1`, `2`. -/
def ring : Finset (Fin 3 × Fin 3) := {(0, 1), (1, 2), (0, 2)}

-- Any two streets of the ring share a junction, so a matching has at most 1 street.
example : ∀ a ∈ ring, ∀ b ∈ ring, a ≠ b → (a.1 = b.1 ∨ a.1 = b.2 ∨ a.2 = b.1 ∨ a.2 = b.2) := by decide
-- Every set of junctions meeting all three streets has at least 2.
example : ∀ C : Finset (Fin 3), (∀ s ∈ ring, s.1 ∈ C ∨ s.2 ∈ C) → 2 ≤ C.card := by decide

#print axioms konig_matching_number_eq_cover_number
#print axioms matching_card_le_vertex_cover_card
#print axioms gallai_identities
