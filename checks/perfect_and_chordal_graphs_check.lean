-- Perfect graphs: every finite chordal graph is perfect, odd rings of five or more are not, and a graph is chordal exactly when it has an elimination order.
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.Coloring.Constructions
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Finset.Sort
import Mathlib.Tactic.NormNum

namespace PerfectChordal

open SimpleGraph

variable {V : Type*}

/-- A graph is perfect when every induced subgraph needs exactly as many colours
as its largest clique: `χ(H) = ω(H)` for every induced subgraph `H`. -/
def IsPerfectGraph (G : SimpleGraph V) : Prop :=
  ∀ s : Set V, (G.induce s).chromaticNumber = ((G.induce s).cliqueNum : ℕ∞)

/-- A hole is a ring of four or more dots with no chord, that is, an induced copy
of the cycle graph `C_k` with `k ≥ 4`. A `↪g` embedding keeps lines and non-lines. -/
def HasHole (G : SimpleGraph V) : Prop :=
  ∃ k : ℕ, 4 ≤ k ∧ Nonempty (cycleGraph k ↪g G)

/-- A graph is chordal when it has no hole. -/
def IsChordal (G : SimpleGraph V) : Prop := ¬ HasHole G

/-- An elimination order lists the dots `v_1, ..., v_n` so that each dot's
neighbours later in the list form a clique. -/
def IsEliminationOrder [Fintype V] (G : SimpleGraph V) (σ : V ≃ Fin (Fintype.card V)) :
    Prop :=
  ∀ v : V, G.IsClique {w | G.Adj v w ∧ σ v < σ w}

lemma cyc_adj_val {k : ℕ} (hk : 2 ≤ k) (a b : Fin k) :
    (cycleGraph k).Adj a b ↔ (a.val + 1 = b.val ∨ b.val + 1 = a.val ∨
      (a.val = 0 ∧ b.val + 1 = k) ∨ (b.val = 0 ∧ a.val + 1 = k)) := by
  rw [cycleGraph_adj']
  have ha := a.isLt
  have hb := b.isLt
  rcases lt_or_ge a b with h | h
  · rw [Fin.coe_sub_iff_lt.mpr h, Fin.coe_sub_iff_le.mpr h.le]
    rw [Fin.lt_def] at h
    omega
  · rw [Fin.coe_sub_iff_le.mpr h]
    rcases lt_or_eq_of_le h with h' | h'
    · rw [Fin.coe_sub_iff_lt.mpr h']
      rw [Fin.lt_def] at h'
      omega
    · subst h'
      rw [Fin.coe_sub_iff_le.mpr le_rfl]
      omega

#print axioms cyc_adj_val

lemma hasHole_of_cycle (G : SimpleGraph V) (n : ℕ) (hn : 2 ≤ n) (g : ℕ → V)
    (hinj : ∀ i j, i ≤ n + 1 → j ≤ n + 1 → g i = g j → i = j)
    (hadj : ∀ i j, i ≤ n + 1 → j ≤ n + 1 → (G.Adj (g i) (g j) ↔
      (i + 1 = j ∨ j + 1 = i ∨ (i = 0 ∧ j = n + 1) ∨ (j = 0 ∧ i = n + 1)))) :
    HasHole G := by
  refine ⟨n + 2, by omega, ⟨⟨⟨fun i => g i.val, ?_⟩, ?_⟩⟩⟩
  · intro a b h
    exact Fin.ext (hinj _ _ (by omega) (by omega) h)
  · intro a b
    show G.Adj (g a.val) (g b.val) ↔ _
    rw [hadj _ _ (by omega) (by omega), cyc_adj_val (by omega)]
    have := a.isLt
    have := b.isLt
    omega

#print axioms hasHole_of_cycle

lemma cyc_cliqueNum_le (k : ℕ) (hk : 4 ≤ k) : (cycleGraph k).cliqueNum ≤ 2 := by
  obtain ⟨s, hs⟩ := (cycleGraph k).exists_isNClique_cliqueNum
  by_contra hlt
  replace hlt := not_le.mp hlt
  have h3 : 2 < s.card := by rw [hs.card_eq]; exact hlt
  obtain ⟨a, ha, b, hb, c, hc, hab, hac, hbc⟩ := Finset.two_lt_card.mp h3
  have hab' := hs.isClique ha hb hab
  have hac' := hs.isClique ha hc hac
  have hbc' := hs.isClique hb hc hbc
  rw [cyc_adj_val (by omega)] at hab' hac' hbc'
  have h1 : a.val ≠ b.val := fun h => hab (Fin.ext h)
  have h2 : a.val ≠ c.val := fun h => hac (Fin.ext h)
  have h3 : b.val ≠ c.val := fun h => hbc (Fin.ext h)
  have := a.isLt
  have := b.isLt
  have := c.isLt
  omega

#print axioms cyc_cliqueNum_le

/-- `v` is simplicial in `s`: its neighbours inside `s` are pairwise adjacent. -/
def Simpl (G : SimpleGraph V) (s : Finset V) (v : V) : Prop :=
  ∀ a ∈ s, ∀ b ∈ s, G.Adj v a → G.Adj v b → a ≠ b → G.Adj a b

/-- A walk from `a` to `b` staying inside `D`, written as a function `ℕ → V`. -/
def RIn (G : SimpleGraph V) (D : Finset V) (a b : V) : Prop :=
  ∃ n : ℕ, ∃ p : ℕ → V, p 0 = a ∧ p n = b ∧ (∀ i ≤ n, p i ∈ D) ∧
    ∀ i < n, G.Adj (p i) (p (i + 1))

lemma RIn_refl {G : SimpleGraph V} {D : Finset V} {a : V} (ha : a ∈ D) : RIn G D a a :=
  ⟨0, fun _ => a, rfl, rfl, fun _ _ => ha, fun _ hi => absurd hi (Nat.not_lt_zero _)⟩

#print axioms RIn_refl

lemma RIn_symm {G : SimpleGraph V} {D : Finset V} {a b : V} : RIn G D a b → RIn G D b a := by
  rintro ⟨n, p, h0, hn, hD, hA⟩
  refine ⟨n, fun i => p (n - i), by simpa using hn, by simpa using h0,
    fun i _ => hD _ (by omega), ?_⟩
  intro i hi
  have h := hA (n - i - 1) (by omega)
  have e : n - i - 1 + 1 = n - i := by omega
  have e2 : n - (i + 1) = n - i - 1 := by omega
  rw [e] at h
  simp only [e2]
  exact h.symm

#print axioms RIn_symm

lemma RIn_trans {G : SimpleGraph V} {D : Finset V} {a b c : V} :
    RIn G D a b → RIn G D b c → RIn G D a c := by
  rintro ⟨n, p, h0, hn, hD, hA⟩ ⟨m, q, h0', hm, hD', hA'⟩
  refine ⟨n + m, fun i => if i ≤ n then p i else q (i - n), by simp [h0], ?_, ?_, ?_⟩
  · by_cases hm0 : m = 0
    · subst hm0
      simp only [Nat.add_zero, le_refl, ite_true]
      rw [hn, ← h0', hm]
    · simp only [show ¬ (n + m ≤ n) by omega, ite_false, Nat.add_sub_cancel_left]
      exact hm
  · intro i hi
    dsimp only
    split_ifs with h
    · exact hD i h
    · exact hD' _ (by omega)
  · intro i hi
    dsimp only
    by_cases h1 : i + 1 ≤ n
    · rw [ite_eq_left (by omega), ite_eq_left h1]; exact hA i (by omega)
    · by_cases h2 : i = n
      · subst h2
        rw [ite_eq_left le_rfl, ite_eq_right (by omega), hn, ← h0', show i + 1 - i = 0 + 1 by omega]
        exact hA' 0 (by omega)
      · rw [ite_eq_right (by omega), ite_eq_right h1, show i + 1 - n = (i - n) + 1 by omega]
        exact hA' _ (by omega)

#print axioms RIn_trans

lemma RIn_step {G : SimpleGraph V} {D : Finset V} {a b c : V} (h : RIn G D a b) (hc : c ∈ D)
    (hbc : G.Adj b c) : RIn G D a c := by
  have hb : b ∈ D := by
    obtain ⟨n, p, -, hn, hD, -⟩ := h
    exact hn ▸ hD n le_rfl
  refine RIn_trans h ⟨1, fun i => if i = 0 then b else c, by simp, by simp, ?_, ?_⟩
  · intro i _
    dsimp only
    split_ifs
    · exact hb
    · exact hc
  · intro i hi
    have : i = 0 := by omega
    subst this
    simpa using hbc

#print axioms RIn_step

/-- A path from `x` to `y` of length `n` whose inner dots lie in `C`. -/
def PathVia (G : SimpleGraph V) (C : Finset V) (x y : V) (n : ℕ) (p : ℕ → V) : Prop :=
  p 0 = x ∧ p n = y ∧ (∀ i < n, G.Adj (p i) (p (i + 1))) ∧ ∀ i, 0 < i → i < n → p i ∈ C

lemma chordless_of_min {G : SimpleGraph V} {C : Finset V} {x y : V} {n : ℕ} {p : ℕ → V}
    (hp : PathVia G C x y n p) (hmin : ∀ m q, PathVia G C x y m q → n ≤ m) :
    ∀ i j, i + 2 ≤ j → j ≤ n → ¬ G.Adj (p i) (p j) := by
  intro i j hij hjn hadj
  obtain ⟨h0, hn, hA, hC⟩ := hp
  have key := hmin (n - (j - i - 1)) (fun m => if m ≤ i then p m else p (m + (j - i - 1)))
    ⟨by simp [h0], ?_, ?_, ?_⟩
  · omega
  · dsimp only
    rw [ite_eq_right (by omega), show n - (j - i - 1) + (j - i - 1) = n by omega]
    exact hn
  · intro m hm
    dsimp only
    by_cases h1 : m + 1 ≤ i
    · rw [ite_eq_left (by omega), ite_eq_left h1]; exact hA m (by omega)
    · by_cases h2 : m = i
      · subst h2
        rw [ite_eq_left le_rfl, ite_eq_right (by omega), show m + 1 + (j - m - 1) = j by omega]
        exact hadj
      · rw [ite_eq_right (by omega), ite_eq_right h1, show m + 1 + (j - i - 1) = m + (j - i - 1) + 1 by omega]
        exact hA _ (by omega)
  · intro m hm0 hm
    dsimp only
    split_ifs with h
    · exact hC m hm0 (by omega)
    · exact hC _ (by omega) (by omega)

#print axioms chordless_of_min

lemma hole_from_path {G : SimpleGraph V} {C : Finset V} {u x y : V} (hux : G.Adj u x)
    (huy : G.Adj u y) (hxy : ¬ G.Adj x y) (hxy' : x ≠ y) (hxC : x ∉ C) (hyC : y ∉ C)
    (huC : ∀ c ∈ C, ¬ G.Adj u c ∧ c ≠ u) {n : ℕ} {p : ℕ → V}
    (hp : PathVia G C x y n p) (hmin : ∀ m q, PathVia G C x y m q → n ≤ m) : HasHole G := by
  have hcl := chordless_of_min hp hmin
  obtain ⟨h0, hn, hA, hC⟩ := hp
  have hn2 : 2 ≤ n := by
    rcases Nat.lt_or_ge n 2 with h | h
    · exfalso
      rcases (show n = 0 ∨ n = 1 by omega) with rfl | rfl
      · exact hxy' (h0 ▸ hn)
      · have := hA 0 (by omega)
        rw [h0, hn] at this
        exact hxy this
    · exact h
  have hnu : ∀ i ≤ n, p i ≠ u := by
    intro i hi he
    rcases Nat.eq_zero_or_pos i with h | h
    · subst h; rw [h0] at he; exact hux.ne he.symm
    · rcases Nat.lt_or_ge i n with h' | h'
      · exact (huC _ (hC i h h')).2 he
      · have : i = n := by omega
        subst this; rw [hn] at he; exact huy.ne he.symm
  have hlt : ∀ i j, i < j → j ≤ n → p i ≠ p j := by
    intro i j hij hjn he
    rcases Nat.eq_zero_or_pos i with h | h
    · subst h
      rw [h0] at he
      rcases Nat.lt_or_ge j n with h' | h'
      · exact hxC (he ▸ hC j hij h')
      · have : j = n := by omega
        subst this; rw [hn] at he; exact hxy' he
    · rcases Nat.lt_or_ge j n with h' | h'
      · have h2 := hA (i - 1) (by omega)
        rw [show i - 1 + 1 = i by omega, he] at h2
        exact hcl (i - 1) j (by omega) (by omega) h2
      · have : j = n := by omega
        subst this; rw [hn] at he; exact hyC (he ▸ hC i h (by omega))
  refine hasHole_of_cycle G n hn2 (fun i => if i ≤ n then p i else u) ?_ ?_
  · intro i j hi hj he
    by_contra hne
    rcases Nat.lt_or_gt_of_ne hne with h | h
    · by_cases hjn : j ≤ n
      · rw [ite_eq_left (by omega), ite_eq_left hjn] at he; exact hlt i j h hjn he
      · rw [ite_eq_left (by omega), ite_eq_right hjn] at he; exact hnu i (by omega) he
    · by_cases hin : i ≤ n
      · rw [ite_eq_left hin, ite_eq_left (by omega)] at he; exact hlt j i h hin he.symm
      · rw [ite_eq_right hin, ite_eq_left (by omega)] at he; exact hnu j (by omega) he.symm
  · intro i j hi hj
    have hsym : ∀ a b, a ≤ n → b ≤ n → a + 1 = b → G.Adj (p a) (p b) := by
      intro a b _ hb hab
      subst hab
      exact hA a (by omega)
    have hpu : ∀ a, a ≤ n → (G.Adj (p a) u ↔ (a = 0 ∨ a = n)) := by
      intro a ha
      constructor
      · intro h
        by_contra hne
        exact (huC _ (hC a (by omega) (by omega))).1 h.symm
      · rintro (h | h)
        · subst h; rw [h0]; exact hux.symm
        · subst h; rw [hn]; exact huy.symm
    by_cases hin : i ≤ n <;> by_cases hjn : j ≤ n
    · rw [ite_eq_left hin, ite_eq_left hjn]
      constructor
      · intro h
        by_contra hne
        rcases lt_trichotomy i j with h' | h' | h'
        · exact hcl i j (by omega) hjn h
        · subst h'; exact G.irrefl h
        · exact hcl j i (by omega) hin h.symm
      · rintro (h | h | h | h)
        · exact hsym i j hin hjn h
        · exact (hsym j i hjn hin h).symm
        · omega
        · omega
    · rw [ite_eq_left hin, ite_eq_right hjn, hpu i hin]
      omega
    · rw [ite_eq_right hin, ite_eq_left hjn, G.adj_comm, hpu j hjn]
      omega
    · rw [ite_eq_right hin, ite_eq_right hjn]
      simp only [SimpleGraph.irrefl, false_iff]
      omega

#print axioms hole_from_path

lemma comp_step {G : SimpleGraph V} [DecidableEq V] (hG : IsChordal G) (s : Finset V) (u w : V)
    (hu : u ∈ s) (hw : w ∈ s) (hwu : w ≠ u) (hnadj : ¬ G.Adj u w)
    (IH : ∀ t ⊂ s, ∀ K : Finset V, K ⊆ t → G.IsClique (K : Set V) → (∃ x ∈ t, x ∉ K) →
      ∃ v ∈ t, v ∉ K ∧ Simpl G t v) :
    ∃ v ∈ s, v ≠ u ∧ ¬ G.Adj u v ∧ Simpl G s v := by
  classical
  set D := s.filter (fun z => z ≠ u ∧ ¬ G.Adj u z) with hD
  set C := D.filter (fun z => RIn G D w z) with hC
  set S := s.filter (fun z => z ∉ C ∧ ∃ c ∈ C, G.Adj z c) with hS
  have hDp : ∀ z, z ∈ D ↔ z ∈ s ∧ z ≠ u ∧ ¬ G.Adj u z := fun z => by
    rw [hD, Finset.mem_filter]
  have hCp : ∀ z, z ∈ C ↔ z ∈ D ∧ RIn G D w z := fun z => by
    rw [hC, Finset.mem_filter]
  have hSp : ∀ z, z ∈ S ↔ z ∈ s ∧ z ∉ C ∧ ∃ c ∈ C, G.Adj z c := fun z => by
    rw [hS, Finset.mem_filter]
  have hwD : w ∈ D := (hDp w).2 ⟨hw, hwu, hnadj⟩
  have hwC : w ∈ C := (hCp w).2 ⟨hwD, RIn_refl hwD⟩
  have hCu : ∀ c ∈ C, ¬ G.Adj u c ∧ c ≠ u := by
    intro c hc
    obtain ⟨-, h1, h2⟩ := (hDp c).1 ((hCp c).1 hc).1
    exact ⟨h2, h1⟩
  have closure : ∀ c ∈ C, ∀ z ∈ s, G.Adj c z → z ∈ C ∨ G.Adj u z := by
    intro c hc z hz hcz
    by_cases huz : G.Adj u z
    · exact Or.inr huz
    · left
      have hzu : z ≠ u := by
        rintro rfl
        exact (hCu c hc).1 hcz.symm
      have hzD : z ∈ D := (hDp z).2 ⟨hz, hzu, huz⟩
      exact (hCp z).2 ⟨hzD, RIn_step ((hCp c).1 hc).2 hzD hcz⟩
  have hSu : ∀ x ∈ S, G.Adj u x := by
    intro x hx
    obtain ⟨hxs, hxC, c, hc, hxc⟩ := (hSp x).1 hx
    exact (closure c hc x hxs hxc.symm).resolve_left hxC
  have hRC : ∀ c1 ∈ C, ∀ c2 ∈ C, ∃ m : ℕ, ∃ q : ℕ → V, q 0 = c1 ∧ q m = c2 ∧
      (∀ i ≤ m, q i ∈ C) ∧ ∀ i < m, G.Adj (q i) (q (i + 1)) := by
    intro c1 h1 c2 h2
    have hr := RIn_trans (RIn_symm ((hCp c1).1 h1).2) ((hCp c2).1 h2).2
    obtain ⟨m, q, hq0, hqm, hqD, hqA⟩ := hr
    refine ⟨m, q, hq0, hqm, ?_, hqA⟩
    intro i hi
    refine (hCp _).2 ⟨hqD i hi, RIn_trans ((hCp c1).1 h1).2 ?_⟩
    exact ⟨i, q, hq0, rfl, fun j hj => hqD j (by omega), fun j hj => hqA j (by omega)⟩
  have hScl : G.IsClique (S : Set V) := by
    intro x hx y hy hxy
    by_contra hn
    rw [Finset.mem_coe] at hx hy
    obtain ⟨-, hxC, c1, hc1, hxc1⟩ := (hSp x).1 hx
    obtain ⟨-, hyC, c2, hc2, hyc2⟩ := (hSp y).1 hy
    obtain ⟨m, q, hq0, hqm, hqC, hqA⟩ := hRC c1 hc1 c2 hc2
    have hex : ∃ n, ∃ p, PathVia G C x y n p := by
      refine ⟨m + 2, fun i => if i = 0 then x else if i ≤ m + 1 then q (i - 1) else y,
        by simp, by simp, ?_, ?_⟩
      · intro i hi
        dsimp only
        rcases Nat.eq_zero_or_pos i with h | h
        · subst h
          simp only [ite_true, show ¬ (0 + 1 = 0) by omega, ite_false,
            show 0 + 1 ≤ m + 1 by omega, Nat.add_sub_cancel, hq0]
          exact hxc1
        · rw [ite_eq_right (show ¬ i = 0 by omega), ite_eq_right (show ¬ i + 1 = 0 by omega),
            ite_eq_left (show i ≤ m + 1 by omega)]
          by_cases him : i + 1 ≤ m + 1
          · rw [ite_eq_left him, show i + 1 - 1 = i - 1 + 1 by omega]
            exact hqA _ (by omega)
          · rw [ite_eq_right him, show i - 1 = m by omega, hqm]
            exact hyc2.symm
      · intro i h0 hi
        dsimp only
        rw [ite_eq_right (show ¬ i = 0 by omega), ite_eq_left (show i ≤ m + 1 by omega)]
        exact hqC _ (by omega)
    obtain ⟨p, hp⟩ := Nat.find_spec hex
    exact hG (hole_from_path (hSu x hx) (hSu y hy) hn hxy hxC hyC hCu hp
      (fun m q hq => Nat.find_min' hex ⟨q, hq⟩))
  set T := C ∪ S with hT
  have hTs : T ⊂ s := by
    rw [Finset.ssubset_iff_of_subset]
    · refine ⟨u, hu, ?_⟩
      rw [hT, Finset.mem_union]
      rintro (h | h)
      · exact (hCu u h).2 rfl
      · exact G.irrefl (hSu u h)
    · intro z hz
      rw [hT, Finset.mem_union] at hz
      rcases hz with h | h
      · exact ((hDp z).1 ((hCp z).1 h).1).1
      · exact ((hSp z).1 h).1
  have hwS : w ∉ S := fun h => ((hSp w).1 h).2.1 hwC
  obtain ⟨v, hvT, hvS, hv⟩ := IH T hTs S Finset.subset_union_right hScl
    ⟨w, Finset.mem_union_left _ hwC, hwS⟩
  have hvC : v ∈ C := (Finset.mem_union.mp hvT).resolve_right hvS
  have hmemT : ∀ z ∈ s, G.Adj v z → z ∈ T := by
    intro z hz hvz
    rw [hT, Finset.mem_union]
    by_cases hzC : z ∈ C
    · exact Or.inl hzC
    · exact Or.inr ((hSp z).2 ⟨hz, hzC, v, hvC, hvz.symm⟩)
  refine ⟨v, hTs.subset hvT, (hCu v hvC).2, (hCu v hvC).1, ?_⟩
  intro a ha b hb hva hvb hab
  exact hv a (hmemT a ha hva) b (hmemT b hb hvb) hva hvb hab

#print axioms comp_step

theorem exists_simpl {G : SimpleGraph V} [DecidableEq V] (hG : IsChordal G) (s : Finset V) :
    ∀ K : Finset V, K ⊆ s → G.IsClique (K : Set V) → (∃ x ∈ s, x ∉ K) →
      ∃ v ∈ s, v ∉ K ∧ Simpl G s v := by
  induction s using Finset.strongInduction with
  | H s IH =>
  rintro K hKs hK ⟨x, hxs, hxK⟩
  by_cases hA : ∃ u ∈ s, (∀ k ∈ K, k = u ∨ G.Adj u k) ∧ ∃ w ∈ s, w ≠ u ∧ ¬ G.Adj u w
  · obtain ⟨u, hu, hKu, w, hw, hwu, hnadj⟩ := hA
    obtain ⟨v, hv, hvu, hvadj, hsv⟩ := comp_step hG s u w hu hw hwu hnadj IH
    exact ⟨v, hv, fun hvK => (hKu v hvK).elim hvu hvadj, hsv⟩
  · have hA' : ∀ u ∈ s, (∀ k ∈ K, k = u ∨ G.Adj u k) → ∀ w ∈ s, w ≠ u → G.Adj u w := by
      intro u hu hKu w hw hwu
      by_contra h
      exact hA ⟨u, hu, hKu, w, hw, hwu, h⟩
    by_cases hKe : K = ∅
    · subst hKe
      refine ⟨x, hxs, hxK, ?_⟩
      intro a ha b hb _ _ hab
      exact hA' a ha (by simp) b hb hab.symm
    · have hKuniv : ∀ k ∈ K, ∀ z ∈ s, z ≠ k → G.Adj k z := by
        intro k hk z hz hzk
        refine hA' k (hKs hk) (fun k' hk' => ?_) z hz hzk
        by_cases e : k' = k
        · exact Or.inl e
        · exact Or.inr (hK hk hk' (Ne.symm e))
      have hsub : s \ K ⊂ s :=
        Finset.sdiff_ssubset hKs (Finset.nonempty_iff_ne_empty.mpr hKe)
      obtain ⟨v, hv, -, hsv⟩ := IH (s \ K) hsub ∅ (Finset.empty_subset _) (by simp)
        ⟨x, Finset.mem_sdiff.mpr ⟨hxs, hxK⟩, Finset.notMem_empty _⟩
      refine ⟨v, (Finset.mem_sdiff.mp hv).1, (Finset.mem_sdiff.mp hv).2, ?_⟩
      intro a ha b hb hva hvb hab
      by_cases haK : a ∈ K
      · exact hKuniv a haK b hb (Ne.symm hab)
      by_cases hbK : b ∈ K
      · exact (hKuniv b hbK a ha hab).symm
      exact hsv a (Finset.mem_sdiff.mpr ⟨ha, haK⟩) b (Finset.mem_sdiff.mpr ⟨hb, hbK⟩) hva hvb hab

#print axioms exists_simpl

theorem peo_chordal [Fintype V] (G : SimpleGraph V) (σ : V ≃ Fin (Fintype.card V))
    (hσ : IsEliminationOrder G σ) : IsChordal G := by
  rintro ⟨k, hk, ⟨f⟩⟩
  have hne : (Finset.univ : Finset (Fin k)).Nonempty := ⟨⟨0, by omega⟩, Finset.mem_univ _⟩
  obtain ⟨i, -, hi⟩ := Finset.exists_min_image Finset.univ (fun j => σ (f j)) hne
  have hi' := i.isLt
  obtain ⟨a, ha⟩ : ∃ a : Fin k, (i.val + 1 = k ∧ a.val = 0) ∨ (i.val + 1 < k ∧ a.val = i.val + 1) := by
    by_cases h : i.val + 1 = k
    · exact ⟨⟨0, by omega⟩, Or.inl ⟨h, rfl⟩⟩
    · exact ⟨⟨i.val + 1, by omega⟩, Or.inr ⟨by omega, rfl⟩⟩
  obtain ⟨b, hb⟩ : ∃ b : Fin k, (i.val = 0 ∧ b.val = k - 1) ∨ (0 < i.val ∧ b.val = i.val - 1) := by
    by_cases h : i.val = 0
    · exact ⟨⟨k - 1, by omega⟩, Or.inl ⟨h, rfl⟩⟩
    · exact ⟨⟨i.val - 1, by omega⟩, Or.inr ⟨by omega, rfl⟩⟩
  have hia : (cycleGraph k).Adj i a := by
    rw [cyc_adj_val (by omega)]; omega
  have hib : (cycleGraph k).Adj i b := by
    rw [cyc_adj_val (by omega)]; omega
  have hab : ¬ (cycleGraph k).Adj a b := by
    rw [cyc_adj_val (by omega)]; omega
  have hab' : a ≠ b := by
    intro h
    have h2 := congrArg Fin.val h
    omega
  have hlt : ∀ j, j ≠ i → σ (f i) < σ (f j) := by
    intro j hj
    refine lt_of_le_of_ne (hi j (Finset.mem_univ _)) ?_
    intro h
    exact hj (f.injective (σ.injective h)).symm
  have hcl := hσ (f i)
  have := hcl (show f a ∈ _ from ⟨f.map_rel_iff.mpr hia, hlt a (hia.ne.symm)⟩)
    (show f b ∈ _ from ⟨f.map_rel_iff.mpr hib, hlt b (hib.ne.symm)⟩)
    (fun h => hab' (f.injective h))
  exact hab (f.map_rel_iff.mp this)

#print axioms peo_chordal

lemma exists_rank {G : SimpleGraph V} [DecidableEq V] (hG : IsChordal G) (s : Finset V) :
    ∃ f : V → ℕ, Set.InjOn f s ∧ ∀ v ∈ s, ∀ a ∈ s, ∀ b ∈ s, G.Adj v a → G.Adj v b →
      f v < f a → f v < f b → a ≠ b → G.Adj a b := by
  induction s using Finset.strongInduction with
  | H s IH =>
  rcases s.eq_empty_or_nonempty with hs | ⟨x, hx⟩
  · subst hs
    exact ⟨fun _ => 0, by simp, by simp⟩
  obtain ⟨v, hv, -, hsv⟩ := exists_simpl hG s ∅ (Finset.empty_subset _) (by simp)
    ⟨x, hx, Finset.notMem_empty _⟩
  obtain ⟨f', hf'inj, hf'⟩ := IH (s.erase v) (Finset.erase_ssubset hv)
  refine ⟨fun z => if z = v then 0 else f' z + 1, ?_, ?_⟩
  · intro a ha b hb hab
    dsimp only at hab
    by_cases hav : a = v <;> by_cases hbv : b = v
    · rw [hav, hbv]
    · rw [ite_eq_left hav, ite_eq_right hbv] at hab; omega
    · rw [ite_eq_right hav, ite_eq_left hbv] at hab; omega
    · rw [ite_eq_right hav, ite_eq_right hbv] at hab
      exact hf'inj (Finset.mem_erase.mpr ⟨hav, ha⟩) (Finset.mem_erase.mpr ⟨hbv, hb⟩) (by omega)
  · intro z hz a ha b hb hza hzb hfa hfb hab
    dsimp only at hfa hfb
    by_cases hzv : z = v
    · subst hzv
      exact hsv a ha b hb hza hzb hab
    · rw [ite_eq_right hzv] at hfa hfb
      have hav : a ≠ v := by intro h; rw [ite_eq_left h] at hfa; omega
      have hbv : b ≠ v := by intro h; rw [ite_eq_left h] at hfb; omega
      rw [ite_eq_right hav] at hfa
      rw [ite_eq_right hbv] at hfb
      exact hf' z (Finset.mem_erase.mpr ⟨hzv, hz⟩) a (Finset.mem_erase.mpr ⟨hav, ha⟩) b
        (Finset.mem_erase.mpr ⟨hbv, hb⟩) hza hzb (by omega) (by omega) hab

#print axioms exists_rank

lemma chordal_peo [Fintype V] (G : SimpleGraph V) (hG : IsChordal G) :
    ∃ σ : V ≃ Fin (Fintype.card V), IsEliminationOrder G σ := by
  classical
  obtain ⟨f, hfinj, hf⟩ := exists_rank hG Finset.univ
  have hinj : Function.Injective f := fun a b h =>
    hfinj (Finset.mem_coe.mpr (Finset.mem_univ a)) (Finset.mem_coe.mpr (Finset.mem_univ b)) h
  let _ : LinearOrder V := LinearOrder.lift' f hinj
  refine ⟨(Fintype.orderIsoFinOfCardEq V rfl).symm.toEquiv, ?_⟩
  intro v a ha b hb hab
  obtain ⟨hva, hlta⟩ := ha
  obtain ⟨hvb, hltb⟩ := hb
  have h1 : f v < f a := (Fintype.orderIsoFinOfCardEq V rfl).symm.lt_iff_lt.mp hlta
  have h2 : f v < f b := (Fintype.orderIsoFinOfCardEq V rfl).symm.lt_iff_lt.mp hltb
  exact hf v (Finset.mem_univ _) a (Finset.mem_univ _) b (Finset.mem_univ _) hva hvb h1 h2 hab

#print axioms chordal_peo

lemma chordal_induce (G : SimpleGraph V) (hG : IsChordal G) (s : Set V) :
    IsChordal (G.induce s) := by
  rintro ⟨k, hk, ⟨f⟩⟩
  exact hG ⟨k, hk, ⟨f.trans (SimpleGraph.Embedding.induce s)⟩⟩

#print axioms chordal_induce

lemma chordal_chromatic_eq {W : Type*} [Fintype W] [DecidableEq W] (H : SimpleGraph W)
    (hH : IsChordal H) : H.chromaticNumber = (H.cliqueNum : ℕ∞) := by
  classical
  refine le_antisymm ?_ H.cliqueNum_le_chromaticNumber
  apply Colorable.chromaticNumber_le
  rcases isEmpty_or_nonempty W with hW | hW
  · exact ⟨Coloring.mk (fun v => isEmptyElim v) (fun {v} => isEmptyElim v)⟩
  have hpos : 0 < H.cliqueNum := Nat.pos_of_ne_zero H.cliqueNum_ne_zero_of_finite
  have key : ∀ s : Finset W, ∃ c : W → Fin H.cliqueNum,
      ∀ a ∈ s, ∀ b ∈ s, H.Adj a b → c a ≠ c b := by
    intro s
    induction s using Finset.strongInduction with
    | H s IH =>
    rcases s.eq_empty_or_nonempty with hs | ⟨x, hx⟩
    · subst hs
      exact ⟨fun _ => ⟨0, hpos⟩, by simp⟩
    obtain ⟨v, hv, -, hsv⟩ := exists_simpl hH s ∅ (Finset.empty_subset _) (by simp)
      ⟨x, hx, Finset.notMem_empty _⟩
    obtain ⟨c, hc⟩ := IH (s.erase v) (Finset.erase_ssubset hv)
    set N := s.filter (fun z => H.Adj v z) with hN
    have hNp : ∀ z, z ∈ N ↔ z ∈ s ∧ H.Adj v z := fun z => by rw [hN, Finset.mem_filter]
    have hvN : v ∉ N := fun h => H.irrefl ((hNp v).1 h).2
    have hcl : H.IsClique ((insert v N : Finset W) : Set W) := by
      intro a ha b hb hab
      rw [Finset.mem_coe, Finset.mem_insert] at ha hb
      rcases ha with rfl | ha <;> rcases hb with rfl | hb
      · exact absurd rfl hab
      · exact ((hNp b).1 hb).2
      · exact ((hNp a).1 ha).2.symm
      · exact hsv a ((hNp a).1 ha).1 b ((hNp b).1 hb).1 ((hNp a).1 ha).2 ((hNp b).1 hb).2 hab
    have hcard := hcl.card_le_cliqueNum
    rw [Finset.card_insert_of_notMem hvN] at hcard
    have himg : (N.image c).card < (Finset.univ : Finset (Fin H.cliqueNum)).card := by
      rw [Finset.card_univ, Fintype.card_fin]
      exact lt_of_le_of_lt Finset.card_image_le (by omega)
    obtain ⟨col, -, hcol⟩ := Finset.exists_mem_notMem_of_card_lt_card himg
    refine ⟨Function.update c v col, ?_⟩
    intro a ha b hb hab
    by_cases hav : a = v
    · subst hav
      have hbv : b ≠ a := fun h => H.irrefl (h ▸ hab)
      rw [Function.update_self, Function.update_of_ne hbv]
      intro h
      exact hcol (Finset.mem_image.mpr ⟨b, (hNp b).2 ⟨hb, hab⟩, h.symm⟩)
    by_cases hbv : b = v
    · subst hbv
      rw [Function.update_self, Function.update_of_ne hav]
      intro h
      exact hcol (Finset.mem_image.mpr ⟨a, (hNp a).2 ⟨ha, hab.symm⟩, h⟩)
    rw [Function.update_of_ne hav, Function.update_of_ne hbv]
    exact hc a (Finset.mem_erase.mpr ⟨hav, ha⟩) b (Finset.mem_erase.mpr ⟨hbv, hb⟩) hab
  obtain ⟨c, hc⟩ := key Finset.univ
  exact ⟨Coloring.mk c (fun {a b} hab => hc a (Finset.mem_univ a) b (Finset.mem_univ b) hab)⟩

#print axioms chordal_chromatic_eq

/-- Every (finite) chordal graph is perfect: in every induced subgraph the fewest
colours equals the size of the largest clique. -/
theorem chordal_graph_is_perfect [Finite V] (G : SimpleGraph V) (hG : IsChordal G) :
    IsPerfectGraph G := by
  intro s
  classical
  have : Fintype s := Fintype.ofFinite s
  exact chordal_chromatic_eq (G.induce s) (chordal_induce G hG s)

/-- An odd ring of five or more dots (an odd hole) has largest clique 2, needs 3
colours, and so is not perfect. -/
theorem odd_ring_not_perfect (k : ℕ) (hk : 5 ≤ k) (hodd : Odd k) :
    (cycleGraph k).cliqueNum = 2 ∧ (cycleGraph k).chromaticNumber = 3 ∧
      ¬ IsPerfectGraph (cycleGraph k) := by
  have hle := cyc_cliqueNum_le k (by omega)
  have hge : 2 ≤ (cycleGraph k).cliqueNum := by
    have hc : (cycleGraph k).IsClique ({⟨0, by omega⟩, ⟨1, by omega⟩} : Finset (Fin k)) := by
      rw [Finset.coe_pair]
      apply SimpleGraph.IsClique.insert (SimpleGraph.isClique_singleton _)
      intro b hb hne
      rw [Set.mem_singleton_iff] at hb
      subst hb
      rw [cyc_adj_val (by omega)]
      simp
    have := hc.card_le_cliqueNum
    rwa [Finset.card_pair (by simp [Fin.ext_iff])] at this
  have hchi := chromaticNumber_cycleGraph_of_odd k (by omega) hodd
  refine ⟨le_antisymm hle hge, hchi, ?_⟩
  intro hP
  have h1 := hP Set.univ
  have h2 : (cycleGraph k).chromaticNumber ≤ ((cycleGraph k).induce Set.univ).chromaticNumber :=
    chromaticNumber_mono_of_hom (induceUnivIso (cycleGraph k)).symm.toHom
  have h3 := cliqueNum_induce_le (G := cycleGraph k) Set.univ
  rw [h1, hchi] at h2
  have h4 : (((cycleGraph k).induce Set.univ).cliqueNum : ℕ∞) ≤ 2 := by
    exact_mod_cast h3.trans hle
  have := h2.trans h4
  norm_num at this

/-- A finite graph is chordal exactly when it has an elimination order. -/
theorem chordal_iff_exists_elimination_order [Fintype V] (G : SimpleGraph V) :
    IsChordal G ↔ ∃ σ : V ≃ Fin (Fintype.card V), IsEliminationOrder G σ := by
  constructor
  · exact chordal_peo G
  · rintro ⟨σ, hσ⟩
    exact peo_chordal G σ hσ

/-! ### The card's worked numbers

Times are in half hours after 9:00: Audit 0-4, Budget 2-6, Clients 5-8, Design 7-10.
Dots: 0 Audit, 1 Budget, 2 Clients, 3 Design. -/

/-- Start and end times of the four meetings, in half hours after 9:00. -/
def startT : Fin 4 → ℕ := ![0, 2, 5, 7]
def endT : Fin 4 → ℕ := ![4, 6, 8, 10]

/-- Two different meetings clash when their time intervals overlap. -/
def clash (a b : Fin 4) : Bool := a ≠ b && startT a < endT b && startT b < endT a

-- Three overlapping pairs: Audit-Budget, Budget-Clients, Clients-Design.
example : ((Finset.univ : Finset (Fin 4 × Fin 4)).filter
    (fun p => p.1 < p.2 ∧ clash p.1 p.2 = true)).card = 3 := by decide

-- At most two meetings run at any start time: ω = 2.
example : (Finset.univ.image (fun t : Fin 4 =>
    ((Finset.univ : Finset (Fin 4)).filter
      (fun m => startT m ≤ startT t ∧ startT t < endT m)).card)).max' (by decide) = 2 := by
  decide

-- Audit, Budget, Clients, Design is an elimination order: each meeting's later
-- clashing meetings all clash with each other.
example : ∀ v a b : Fin 4, v < a → v < b → a ≠ b → clash v a = true → clash v b = true →
    clash a b = true := by decide

-- Greedy by start time gives rooms 1, 2, 1, 2: a proper colouring with two rooms.
example : ∀ a b : Fin 4, clash a b = true → (![1, 2, 1, 2] : Fin 4 → ℕ) a ≠ ![1, 2, 1, 2] b := by
  decide

-- The 15 nonempty induced subgraphs of the four meetings.
example : 2 ^ 4 - 1 = 15 := by norm_num

-- The cafe ring: α × ω = 2 × 2 = 4 < 5 dots, so two nights cannot cover it.
example : 2 * 2 < 5 := by norm_num

#print axioms chordal_graph_is_perfect
#print axioms odd_ring_not_perfect
#print axioms chordal_iff_exists_elimination_order

end PerfectChordal
