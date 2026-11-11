-- Edge colouring: a finite simple graph's edges need at least its largest degree in colours and at most one more, exactly that many when it is bipartite, and the complete graph on n dots needs n - 1 colours for even n and n for odd n.
import Mathlib.Combinatorics.SimpleGraph.LineGraph
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.Bipartite
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Tactic.NormNum
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Data.Nat.Prime.Basic

open SimpleGraph

namespace ECHelp

section Helpers

open Finset Classical

variable {V : Type*}

def IsCol (H : SimpleGraph V) (K : Finset ℕ) (φ : V → V → ℕ) : Prop :=
  (∀ u v, H.Adj u v → φ u v ∈ K) ∧ (∀ u v, H.Adj u v → φ u v = φ v u) ∧
  (∀ u v w, H.Adj u v → H.Adj u w → v ≠ w → φ u v ≠ φ u w)

noncomputable def miss (H : SimpleGraph V) (φ : V → V → ℕ) (K : Finset ℕ) (y : V) :
    Finset ℕ :=
  K.filter (fun c => ∀ w, H.Adj y w → φ y w ≠ c)

theorem mem_miss {H : SimpleGraph V} {φ : V → V → ℕ} {K : Finset ℕ} {y : V} {c : ℕ} :
    c ∈ miss H φ K y ↔ c ∈ K ∧ ∀ w, H.Adj y w → φ y w ≠ c := by
  unfold miss; exact Finset.mem_filter

theorem miss_subset (H : SimpleGraph V) (φ : V → V → ℕ) (K : Finset ℕ) (y : V) :
    miss H φ K y ⊆ K := fun _ h => (mem_miss.1 h).1

theorem IsCol.mono {H H' : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ} (h : IsCol H K φ)
    (hle : ∀ u v, H'.Adj u v → H.Adj u v) : IsCol H' K φ :=
  ⟨fun u v huv => h.1 u v (hle u v huv), fun u v huv => h.2.1 u v (hle u v huv),
    fun u v w huv huw hvw => h.2.2 u v w (hle u v huv) (hle u w huw) hvw⟩

theorem card_le_miss_add [Fintype V] (H : SimpleGraph V) (φ : V → V → ℕ) (K : Finset ℕ)
    (y : V) : K.card ≤ (miss H φ K y).card + (univ.filter (fun w => H.Adj y w)).card := by
  have hsub : K ⊆ miss H φ K y ∪ (univ.filter (fun w => H.Adj y w)).image (φ y) := by
    intro c hc
    by_cases hm : c ∈ miss H φ K y
    · exact mem_union_left _ hm
    · apply mem_union_right
      simp only [mem_miss, not_and, not_forall, not_not] at hm
      obtain ⟨w, hw, hwc⟩ := hm hc
      exact mem_image.2 ⟨w, by simpa using hw, hwc⟩
  calc K.card ≤ (miss H φ K y ∪ (univ.filter (fun w => H.Adj y w)).image (φ y)).card :=
        card_le_card hsub
    _ ≤ (miss H φ K y).card + ((univ.filter (fun w => H.Adj y w)).image (φ y)).card :=
        card_union_le _ _
    _ ≤ _ := by gcongr; exact card_image_le

/-! Kempe swaps -/

def sw (a b c : ℕ) : ℕ := if c = a then b else if c = b then a else c

theorem sw_sw (a b c : ℕ) : sw a b (sw a b c) = c := by
  unfold sw; split_ifs <;> omega

theorem sw_inj (a b : ℕ) : Function.Injective (sw a b) := fun x y h => by
  simpa [sw_sw] using congrArg (sw a b) h

theorem sw_mem {K : Finset ℕ} {a b c : ℕ} (ha : a ∈ K) (hb : b ∈ K) : sw a b c ∈ K ↔ c ∈ K := by
  unfold sw; split_ifs <;> simp_all

theorem sw_eq_iff (a b c d : ℕ) : sw a b c = d ↔ c = sw a b d := by
  constructor
  · rintro rfl; rw [sw_sw]
  · rintro rfl; rw [sw_sw]

def kg (H : SimpleGraph V) (φ : V → V → ℕ) (a b : ℕ) : SimpleGraph V where
  Adj u v := H.Adj u v ∧ (φ u v = a ∨ φ u v = b) ∧ (φ v u = a ∨ φ v u = b)
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.2, h.2.1⟩⟩
  loopless := ⟨fun _ h => H.irrefl h.1⟩

noncomputable def kswap (H : SimpleGraph V) (φ : V → V → ℕ) (a b : ℕ) (v0 : V) :
    V → V → ℕ :=
  fun u v => if (kg H φ a b).Reachable v0 u then sw a b (φ u v) else φ u v

theorem kswap_col {H : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ} {a b : ℕ} (v0 : V)
    (h : IsCol H K φ) (ha : a ∈ K) (hb : b ∈ K) : IsCol H K (kswap H φ a b v0) := by
  obtain ⟨h1, h2, h3⟩ := h
  refine ⟨fun u v huv => ?_, fun u v huv => ?_, fun u v w huv huw hvw => ?_⟩
  · unfold kswap; split_ifs
    · exact (sw_mem ha hb).2 (h1 u v huv)
    · exact h1 u v huv
  · have key : ∀ u v, H.Adj u v → (kg H φ a b).Reachable v0 u →
        ¬ (kg H φ a b).Reachable v0 v → sw a b (φ u v) = φ v u := by
      intro u v huv hu hv
      by_cases hc : φ u v = a ∨ φ u v = b
      · exfalso; apply hv
        have hk : (kg H φ a b).Adj u v := ⟨huv, hc, by rw [← h2 u v huv]; exact hc⟩
        exact hu.trans hk.reachable
      · push_neg at hc
        unfold sw; rw [if_neg hc.1, if_neg hc.2]; exact h2 u v huv
    unfold kswap
    by_cases hu : (kg H φ a b).Reachable v0 u <;> by_cases hv : (kg H φ a b).Reachable v0 v
    · rw [if_pos hu, if_pos hv, h2 u v huv]
    · rw [if_pos hu, if_neg hv]; exact key u v huv hu hv
    · rw [if_neg hu, if_pos hv]; exact (key v u huv.symm hv hu).symm
    · rw [if_neg hu, if_neg hv]; exact h2 u v huv
  · unfold kswap; split_ifs
    · exact fun e => h3 u v w huv huw hvw (sw_inj a b e)
    · exact h3 u v w huv huw hvw

theorem kswap_mem_miss {H : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ} {a b : ℕ} (v0 : V)
    (ha : a ∈ K) (hb : b ∈ K) (y : V) (c : ℕ) :
    c ∈ miss H (kswap H φ a b v0) K y ↔
      (if (kg H φ a b).Reachable v0 y then sw a b c else c) ∈ miss H φ K y := by
  simp only [mem_miss, kswap]
  split_ifs with hy
  · rw [sw_mem ha hb]
    refine and_congr_right fun _ => forall_congr' fun w => imp_congr_right fun _ => ?_
    rw [Ne, Ne, sw_eq_iff]
  · rfl

theorem kswap_card_miss {H : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ} {a b : ℕ} (v0 : V)
    (ha : a ∈ K) (hb : b ∈ K) (y : V) :
    (miss H (kswap H φ a b v0) K y).card = (miss H φ K y).card := by
  by_cases hy : (kg H φ a b).Reachable v0 y
  · have : miss H (kswap H φ a b v0) K y = (miss H φ K y).image (sw a b) := by
      ext c
      rw [kswap_mem_miss v0 ha hb, if_pos hy, mem_image]
      constructor
      · intro hc; exact ⟨sw a b c, hc, sw_sw a b c⟩
      · rintro ⟨d, hd, rfl⟩; rwa [sw_sw]
    rw [this, card_image_of_injective _ (sw_inj a b)]
  · congr 1
    ext c
    rw [kswap_mem_miss v0 ha hb, if_neg hy]


theorem comp_low [Fintype V] (F : SimpleGraph V) (h2 : ∀ v, F.degree v ≤ 2) (v0 : V) :
    (univ.filter (fun v => F.Reachable v0 v ∧ F.degree v ≤ 1)).card ≤ 2 := by
  set C := F.connectedComponentMk v0 with hC
  have hconn := C.connected_toSimpleGraph
  have h1 := hconn.card_vert_le_card_edgeSet_add_one
  have hsum := C.toSimpleGraph.sum_degrees_eq_twice_card_edges
  have hdeg : ∀ w : C, C.toSimpleGraph.degree w = F.degree w.1 := by
    intro w
    have := degree_induce_of_neighborSet_subset (G := F) (s := C.supp) (v := w)
      (fun z hz => C.mem_supp_of_adj_mem_supp w.2 hz)
    exact this
  set L : Finset C := univ.filter (fun w => F.degree w.1 ≤ 1) with hL
  have hLsum : ∑ w : C, F.degree w.1 + L.card ≤ 2 * Fintype.card C := by
    rw [hL, card_filter, ← sum_add_distrib, ← card_univ, mul_comm, ← smul_eq_mul,
      ← sum_const]
    apply sum_le_sum
    intro w _
    have := h2 w.1
    split_ifs <;> omega
  have hE : Nat.card C.toSimpleGraph.edgeSet = (C.toSimpleGraph.edgeFinset).card := by
    rw [Nat.card_eq_fintype_card, edgeFinset_card]
  rw [Nat.card_eq_fintype_card, hE] at h1
  simp_rw [hdeg] at hsum
  have hLle : L.card ≤ 2 := by omega
  have heq : univ.filter (fun v => F.Reachable v0 v ∧ F.degree v ≤ 1) =
      L.map (Function.Embedding.subtype _) := by
    ext v
    simp only [mem_filter, mem_univ, true_and, mem_map, hL, Function.Embedding.subtype_apply]
    constructor
    · rintro ⟨hr, hd⟩
      refine ⟨⟨v, ?_⟩, hd, rfl⟩
      rw [hC]
      exact (ConnectedComponent.eq.2 hr).symm
    · rintro ⟨w, hw, rfl⟩
      refine ⟨?_, hw⟩
      have hw2 : F.connectedComponentMk w.1 = C := w.2
      exact (ConnectedComponent.eq.1 hw2).symm
  rw [heq, card_map]
  exact hLle

theorem card_colour_le_one [Fintype V] {H : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ}
    (h : IsCol H K φ) (y : V) (c : ℕ) :
    (univ.filter (fun w => H.Adj y w ∧ φ y w = c)).card ≤ 1 := by
  rw [card_le_one]
  intro w1 hw1 w2 hw2
  simp only [mem_filter, mem_univ, true_and] at hw1 hw2
  by_contra hne
  exact h.2.2 y w1 w2 hw1.1 hw2.1 hne (hw1.2.trans hw2.2.symm)

theorem kg_degree_eq [Fintype V] (H : SimpleGraph V) (φ : V → V → ℕ) (a b : ℕ) (y : V) :
    (kg H φ a b).degree y = (univ.filter (fun w => (kg H φ a b).Adj y w)).card := by
  rw [← card_neighborFinset_eq_degree, neighborFinset_eq_filter]

theorem kg_deg_le [Fintype V] {H : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ}
    (h : IsCol H K φ) (a b : ℕ) (y : V) : (kg H φ a b).degree y ≤ 2 := by
  rw [kg_degree_eq]
  calc _ ≤ (univ.filter (fun w => H.Adj y w ∧ φ y w = a) ∪
        univ.filter (fun w => H.Adj y w ∧ φ y w = b)).card := by
        apply card_le_card
        intro w hw
        simp only [mem_filter, mem_univ, true_and, mem_union] at hw ⊢
        rcases hw.2.1 with h' | h'
        · exact Or.inl ⟨hw.1, h'⟩
        · exact Or.inr ⟨hw.1, h'⟩
    _ ≤ _ := card_union_le _ _
    _ ≤ 1 + 1 := add_le_add (card_colour_le_one h y a) (card_colour_le_one h y b)

theorem kg_deg_miss [Fintype V] {H : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ}
    (h : IsCol H K φ) (a b : ℕ) (y : V) (hy : a ∈ miss H φ K y) :
    (kg H φ a b).degree y ≤ 1 := by
  rw [kg_degree_eq]
  calc _ ≤ (univ.filter (fun w => H.Adj y w ∧ φ y w = b)).card := by
        apply card_le_card
        intro w hw
        simp only [mem_filter, mem_univ, true_and] at hw ⊢
        refine ⟨hw.1, ?_⟩
        rcases hw.2.1 with h' | h'
        · exact absurd h' ((mem_miss.1 hy).2 w hw.1)
        · exact h'
    _ ≤ 1 := card_colour_le_one h y b


theorem even_sum' {ι : Type*} (s : Finset ι) (f : ι → ℕ) (h : ∀ i ∈ s, Even (f i)) :
    Even (∑ i ∈ s, f i) := by
  induction s using Finset.induction_on with
  | empty => simp
  | insert a s ha ih =>
    rw [sum_insert ha]
    exact (h a (mem_insert_self a s)).add (ih fun i hi => h i (mem_insert_of_mem hi))

theorem sw_b (a b : ℕ) (hab : a ≠ b) : sw a b b = a := by
  unfold sw; rw [if_neg (Ne.symm hab), if_pos rfl]

theorem core [Fintype V] {H : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ} (N : Finset V)
    (hφ : IsCol H K φ) (hNK : N.card ≤ K.card) (hNne : N.Nonempty)
    (h1 : ∀ y ∈ N, 1 ≤ (miss H φ K y).card)
    (hs : (N.filter (fun y => (miss H φ K y).card ≤ 1)).card ≤ 1) :
    ∃ φ1, IsCol H K φ1 ∧ (∀ y, (miss H φ1 K y).card = (miss H φ K y).card) ∧
      ∃ a ∈ K, ∃ u ∈ N, a ∈ miss H φ1 K u ∧
        (N.filter (fun z => z ≠ u ∧ a ∈ miss H φ1 K z ∧ (miss H φ1 K z).card ≤ 2)).card +
          (N.filter (fun z => (miss H φ1 K z).card ≤ 1)).card ≤ 1 := by
  set Tt := N.filter (fun y => (miss H φ K y).card ≤ 2) with hTt
  set S := N.filter (fun y => (miss H φ K y).card ≤ 1) with hS
  have hSsub : S ⊆ Tt := by
    intro z hz
    rw [hS, mem_filter] at hz
    exact mem_filter.2 ⟨hz.1, by omega⟩
  -- Case 1: no tight neighbours
  by_cases hT : Tt = ∅
  · obtain ⟨y, hy⟩ := hNne
    obtain ⟨a, ha⟩ := card_pos.1 (h1 y hy)
    refine ⟨φ, hφ, fun _ => rfl, a, miss_subset _ _ _ _ ha, y, hy, ha, ?_⟩
    have e1 : N.filter (fun z => z ≠ y ∧ a ∈ miss H φ K z ∧ (miss H φ K z).card ≤ 2) = ∅ := by
      rw [filter_eq_empty_iff]
      rintro z hz ⟨_, _, h2⟩
      have : z ∈ Tt := mem_filter.2 ⟨hz, h2⟩
      rw [hT] at this
      simp at this
    have e2 : S = ∅ := subset_empty.1 (hT ▸ hSsub)
    rw [e1, ← hS, e2]
    simp
  set A : ℕ → ℕ := fun c => (Tt.filter (fun y => c ∈ miss H φ K y)).card with hA
  -- Case 2: a colour already works
  by_cases hc2 : ∃ c ∈ K, 1 ≤ A c ∧ A c + S.card ≤ 2
  · obtain ⟨c, hcK, hc1, hc2⟩ := hc2
    obtain ⟨u, hu⟩ := card_pos.1 hc1
    have hu' := mem_filter.1 hu
    have huN : u ∈ N := (mem_filter.1 hu'.1).1
    refine ⟨φ, hφ, fun _ => rfl, c, hcK, u, huN, hu'.2, ?_⟩
    have hsub : N.filter (fun z => z ≠ u ∧ c ∈ miss H φ K z ∧ (miss H φ K z).card ≤ 2) ⊆
        (Tt.filter (fun y => c ∈ miss H φ K y)).erase u := by
      intro z hz
      simp only [mem_filter] at hz
      exact mem_erase.2 ⟨hz.2.1, mem_filter.2 ⟨mem_filter.2 ⟨hz.1, hz.2.2.2⟩, hz.2.2.1⟩⟩
    have := card_le_card hsub
    rw [card_erase_of_mem hu] at this
    rw [← hS]
    have : A c = (Tt.filter (fun y => c ∈ miss H φ K y)).card := rfl
    omega
  -- Case 3: Kempe swap
  push_neg at hc2
  have hTne : Tt.Nonempty := nonempty_iff_ne_empty.2 hT
  have hSle : S.card ≤ 1 := hs
  have hTN : Tt.card ≤ N.card := card_filter_le _ _
  have hdc : ∑ c ∈ K, A c = ∑ y ∈ Tt, (miss H φ K y).card := by
    simp only [hA, card_filter]
    rw [sum_comm]
    apply sum_congr rfl
    intro y _
    rw [← card_filter, filter_mem_eq_inter, inter_eq_right.2 (miss_subset _ _ _ _)]
  have heq : ∑ y ∈ Tt, (miss H φ K y).card + S.card = 2 * Tt.card := by
    have hSc : S.card = ∑ y ∈ Tt, if (miss H φ K y).card ≤ 1 then 1 else 0 := by
      rw [← card_filter, hS, hTt, filter_filter]
      congr 1
      apply filter_congr
      intro y _
      constructor
      · intro h; exact ⟨by omega, h⟩
      · intro h; exact h.2
    rw [hSc, ← sum_add_distrib, card_eq_sum_ones, mul_sum]
    apply sum_congr rfl
    intro y hy
    have hy1 := h1 y (mem_filter.1 hy).1
    have hy2 := (mem_filter.1 hy).2
    split_ifs <;> omega
  have hK1 : 1 ≤ K.card := lt_of_lt_of_le (card_pos.2 hNne) hNK
  have hb : ∃ b ∈ K, A b = 0 := by
    by_contra hno
    push_neg at hno
    have hge : ∀ c ∈ K, 3 - S.card ≤ A c := fun c hc => by
      have := hc2 c hc (Nat.one_le_iff_ne_zero.2 (hno c hc))
      omega
    have := sum_le_sum hge
    rw [sum_const, smul_eq_mul, hdc] at this
    rcases Nat.le_one_iff_eq_zero_or_eq_one.1 hSle with h | h <;> rw [h] at this heq <;>
      omega
  obtain ⟨b, hbK, hb0⟩ := hb
  have ha : ∃ a ∈ K, 1 ≤ A a ∧ (S.card = 1 → Odd (A a)) := by
    by_cases hS1 : S.card = 1
    · by_contra hno
      push_neg at hno
      have hev : Even (∑ c ∈ K, A c) := by
        apply even_sum'
        intro c hc
        by_cases h : 1 ≤ A c
        · exact Nat.not_odd_iff_even.1 (hno c hc h).2
        · have : A c = 0 := by omega
          rw [this]; exact ⟨0, rfl⟩
      rw [hdc] at hev
      obtain ⟨r, hr⟩ := hev
      omega
    · obtain ⟨y, hy⟩ := hTne
      obtain ⟨a, ha⟩ := card_pos.1 (h1 y (mem_filter.1 hy).1)
      exact ⟨a, miss_subset _ _ _ _ ha, card_pos.2 ⟨y, mem_filter.2 ⟨hy, ha⟩⟩,
        fun h => absurd h hS1⟩
  obtain ⟨a, haK, ha1, haodd⟩ := ha
  have hab : a ≠ b := by
    rintro rfl
    omega
  set F := kg H φ a b with hF
  have hp2 : ∀ y, (Tt.filter (fun z => F.Reachable y z ∧ a ∈ miss H φ K z)).card ≤ 2 := by
    intro y
    refine le_trans (card_le_card ?_) (comp_low F (kg_deg_le hφ a b) y)
    intro z hz
    simp only [mem_filter, mem_univ, true_and] at hz ⊢
    exact ⟨hz.2.1, kg_deg_miss hφ a b z hz.2.2⟩
  have hy : ∃ y ∈ Tt, a ∈ miss H φ K y ∧
      (S.card = 1 → (Tt.filter (fun z => F.Reachable y z ∧ a ∈ miss H φ K z)).card ≠ 2) := by
    by_cases hS1 : S.card = 1
    · by_contra hno
      push_neg at hno
      set X := Tt.filter (fun y => a ∈ miss H φ K y) with hX
      have hXe : Even X.card := by
        rw [card_eq_sum_card_image (fun y => F.connectedComponentMk y) X]
        apply even_sum'
        intro c hc
        obtain ⟨y, hyX, rfl⟩ := mem_image.1 hc
        have hyX' := mem_filter.1 hyX
        have : X.filter (fun z => F.connectedComponentMk z = F.connectedComponentMk y) =
            Tt.filter (fun z => F.Reachable y z ∧ a ∈ miss H φ K z) := by
          ext z
          simp only [hX, mem_filter, ConnectedComponent.eq]
          constructor
          · rintro ⟨⟨h1, h2⟩, h3⟩; exact ⟨h1, h3.symm, h2⟩
          · rintro ⟨h1, h3, h2⟩; exact ⟨⟨h1, h2⟩, h3.symm⟩
        rw [this, (hno y hyX'.1 hyX'.2).2]
        exact even_two
      exact Nat.not_even_iff_odd.2 (haodd hS1) hXe
    · obtain ⟨y, hy⟩ := card_pos.1 ha1
      exact ⟨y, (mem_filter.1 hy).1, (mem_filter.1 hy).2, fun h => absurd h hS1⟩
  obtain ⟨y, hyT, hya, hyp⟩ := hy
  have hyin : y ∈ Tt.filter (fun z => F.Reachable y z ∧ a ∈ miss H φ K z) :=
    mem_filter.2 ⟨hyT, Reachable.refl _, hya⟩
  have hp1 := card_pos.2 ⟨y, hyin⟩
  have hp2y := hp2 y
  refine ⟨kswap H φ a b y, kswap_col y hφ haK hbK, kswap_card_miss y haK hbK, b, hbK, y,
    (mem_filter.1 hyT).1, ?_, ?_⟩
  · rw [kswap_mem_miss y haK hbK, if_pos (Reachable.refl _), sw_b a b hab]
    exact hya
  · simp_rw [kswap_card_miss y haK hbK]
    rw [← hS]
    have hsub : N.filter (fun z => z ≠ y ∧ b ∈ miss H (kswap H φ a b y) K z ∧
        (miss H φ K z).card ≤ 2) ⊆
        (Tt.filter (fun z => F.Reachable y z ∧ a ∈ miss H φ K z)).erase y := by
      intro z hz
      simp only [mem_filter] at hz
      obtain ⟨hzN, hzy, hzb, hz2⟩ := hz
      have hzT : z ∈ Tt := mem_filter.2 ⟨hzN, hz2⟩
      rw [kswap_mem_miss y haK hbK] at hzb
      split_ifs at hzb with hr
      · rw [sw_b a b hab] at hzb
        exact mem_erase.2 ⟨hzy, mem_filter.2 ⟨hzT, hr, hzb⟩⟩
      · exfalso
        have : 0 < A b := card_pos.2 ⟨z, mem_filter.2 ⟨hzT, hzb⟩⟩
        omega
    have := card_le_card hsub
    rw [card_erase_of_mem hyin] at this
    rcases Nat.le_one_iff_eq_zero_or_eq_one.1 hSle with h | h
    · omega
    · have := hyp h
      omega


def Del (G : SimpleGraph V) (x : V) : SimpleGraph V where
  Adj u v := G.Adj u v ∧ u ≠ x ∧ v ≠ x
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.2, h.2.1⟩⟩
  loopless := ⟨fun _ h => G.irrefl h.1⟩

theorem isCol_of_noNbr {G : SimpleGraph V} {x : V} {K : Finset ℕ} {φ : V → V → ℕ}
    (hx : ∀ y, ¬ G.Adj x y) (h : IsCol (Del G x) K φ) : IsCol G K φ :=
  h.mono (fun u v huv => ⟨huv, fun e => hx v (e ▸ huv), fun e => hx u (e ▸ huv.symm)⟩)

def Gp (G : SimpleGraph V) (x u : V) (φ : V → V → ℕ) (a : ℕ) : SimpleGraph V where
  Adj v w := G.Adj v w ∧ ¬(v = x ∧ w = u) ∧ ¬(v = u ∧ w = x) ∧
    ¬(v ≠ x ∧ w ≠ x ∧ (φ v w = a ∨ φ w v = a))
  symm := ⟨fun _ _ h => ⟨h.1.symm, fun h' => h.2.2.1 ⟨h'.2, h'.1⟩,
    fun h' => h.2.1 ⟨h'.2, h'.1⟩, fun h' => h.2.2.2 ⟨h'.2.1, h'.1, h'.2.2.symm⟩⟩⟩
  loopless := ⟨fun _ h => G.irrefl h.1⟩

theorem Gp_cases {G : SimpleGraph V} {x u : V} {φ : V → V → ℕ} {a : ℕ} {K : Finset ℕ}
    (hφ : IsCol (Del G x) K φ) {v w : V} (hvw : G.Adj v w) (hn : ¬ (Gp G x u φ a).Adj v w) :
    (v = x ∧ w = u) ∨ (v = u ∧ w = x) ∨ (v ≠ x ∧ w ≠ x ∧ φ v w = a) := by
  by_cases h1 : v = x ∧ w = u
  · exact Or.inl h1
  by_cases h2 : v = u ∧ w = x
  · exact Or.inr (Or.inl h2)
  have h3 : v ≠ x ∧ w ≠ x ∧ (φ v w = a ∨ φ w v = a) := by
    by_contra h3
    exact hn ⟨hvw, h1, h2, h3⟩
  refine Or.inr (Or.inr ⟨h3.1, h3.2.1, ?_⟩)
  rcases h3.2.2 with h | h
  · exact h
  · rw [hφ.2.1 v w ⟨hvw, h3.1, h3.2.1⟩]; exact h

theorem VL [Fintype V] : ∀ (n : ℕ) (K : Finset ℕ), K.card = n →
    ∀ (G : SimpleGraph V) (x : V) (φ : V → V → ℕ),
    IsCol (Del G x) K φ → (univ.filter (fun y => G.Adj x y)).card ≤ K.card →
    (∀ y, G.Adj x y → 1 ≤ (miss (Del G x) φ K y).card) →
    (univ.filter (fun y => G.Adj x y ∧ (miss (Del G x) φ K y).card ≤ 1)).card ≤ 1 →
    ∃ ψ, IsCol G K ψ := by
  intro n
  induction n with
  | zero =>
    intro K hK G x φ hφ hd _ _
    refine ⟨φ, isCol_of_noNbr (fun y hy => ?_) hφ⟩
    have : 0 < (univ.filter (fun y => G.Adj x y)).card := card_pos.2 ⟨y, by simpa using hy⟩
    omega
  | succ m ih =>
    intro K hK G x φ hφ hd h1 hs
    by_cases hx : ∃ y, G.Adj x y
    swap
    · push_neg at hx
      exact ⟨φ, isCol_of_noNbr hx hφ⟩
    obtain ⟨y0, hy0⟩ := hx
    set N := univ.filter (fun y => G.Adj x y) with hN
    have hmemN : ∀ y, y ∈ N ↔ G.Adj x y := fun y => by simp [hN]
    have hfilt : N.filter (fun y => (miss (Del G x) φ K y).card ≤ 1) =
        univ.filter (fun y => G.Adj x y ∧ (miss (Del G x) φ K y).card ≤ 1) := by
      rw [hN, filter_filter]
    obtain ⟨φ1, hφ1, hc, a, haK, u, huN, hau, hgood⟩ := core N hφ hd ⟨y0, (hmemN y0).2 hy0⟩
      (fun y hy => h1 y ((hmemN y).1 hy)) (by rw [hfilt]; exact hs)
    have hxu : G.Adj x u := (hmemN u).1 huN
    set G' := Gp G x u φ1 a with hG'
    have hDel' : ∀ v w, (Del G' x).Adj v w ↔
        (Del G x).Adj v w ∧ ¬(φ1 v w = a ∨ φ1 w v = a) := by
      intro v w
      constructor
      · rintro ⟨⟨hg, -, -, h3⟩, hv, hw⟩
        exact ⟨⟨hg, hv, hw⟩, fun h => h3 ⟨hv, hw, h⟩⟩
      · rintro ⟨⟨hg, hv, hw⟩, h⟩
        exact ⟨⟨hg, fun h' => hv h'.1, fun h' => hw h'.2, fun h' => h h'.2.2⟩, hv, hw⟩
    have hcol' : IsCol (Del G' x) (K.erase a) φ1 := by
      refine ⟨fun v w h => ?_, fun v w h => hφ1.2.1 v w ((hDel' v w).1 h).1,
        fun v w1 w2 h1 h2 hne => hφ1.2.2 v w1 w2 ((hDel' v w1).1 h1).1 ((hDel' v w2).1 h2).1 hne⟩
      rw [hDel'] at h
      exact mem_erase.2 ⟨fun e => h.2 (Or.inl e), hφ1.1 v w h.1⟩
    have hmiss' : ∀ z, miss (Del G' x) φ1 (K.erase a) z = (miss (Del G x) φ1 K z).erase a := by
      intro z
      ext c
      simp only [mem_miss, mem_erase]
      constructor
      · rintro ⟨⟨hca, hcK⟩, hall⟩
        refine ⟨hca, hcK, fun w hw => ?_⟩
        by_cases e : φ1 z w = a
        · intro h; apply hca; rw [← h, e]
        · refine hall w ((hDel' z w).2 ⟨hw, fun h => h.elim e (fun e' => e ?_)⟩)
          rw [hφ1.2.1 z w hw]; exact e'
      · rintro ⟨hca, hcK, hall⟩
        exact ⟨⟨hca, hcK⟩, fun w hw => hall w ((hDel' z w).1 hw).1⟩
    have hnb' : ∀ y, G'.Adj x y ↔ G.Adj x y ∧ y ≠ u := by
      intro y
      constructor
      · intro h; exact ⟨h.1, fun e => h.2.1 ⟨rfl, e⟩⟩
      · intro h
        refine ⟨h.1, fun e => h.2 e.2, fun e => ?_, fun e => e.1 rfl⟩
        have := h.1
        rw [e.2] at this
        exact G.irrefl this
    have hd' : (univ.filter (fun y => G'.Adj x y)).card ≤ (K.erase a).card := by
      rw [card_erase_of_mem haK]
      have : univ.filter (fun y => G'.Adj x y) = N.erase u := by
        ext y
        simp only [mem_filter, mem_univ, true_and, hnb', mem_erase, hmemN]
        exact and_comm
      rw [this, card_erase_of_mem huN]
      omega
    have h1' : ∀ y, G'.Adj x y → 1 ≤ (miss (Del G' x) φ1 (K.erase a) y).card := by
      intro y hy
      rw [hnb'] at hy
      rw [hmiss']
      have hy1 : 1 ≤ (miss (Del G x) φ1 K y).card := by rw [hc]; exact h1 y hy.1
      by_cases hay : a ∈ miss (Del G x) φ1 K y
      · rw [card_erase_of_mem hay]
        by_contra hlt
        have hle : (miss (Del G x) φ1 K y).card ≤ 1 := by omega
        have e1 : 1 ≤ (N.filter (fun z => z ≠ u ∧ a ∈ miss (Del G x) φ1 K z ∧
            (miss (Del G x) φ1 K z).card ≤ 2)).card :=
          card_pos.2 ⟨y, mem_filter.2 ⟨(hmemN y).2 hy.1, hy.2, hay, by omega⟩⟩
        have e2 : 1 ≤ (N.filter (fun z => (miss (Del G x) φ1 K z).card ≤ 1)).card :=
          card_pos.2 ⟨y, mem_filter.2 ⟨(hmemN y).2 hy.1, hle⟩⟩
        omega
      · rw [erase_eq_of_notMem hay]; exact hy1
    have hs' : (univ.filter (fun y => G'.Adj x y ∧
        (miss (Del G' x) φ1 (K.erase a) y).card ≤ 1)).card ≤ 1 := by
      calc _ ≤ (N.filter (fun z => z ≠ u ∧ a ∈ miss (Del G x) φ1 K z ∧
              (miss (Del G x) φ1 K z).card ≤ 2) ∪
            N.filter (fun z => (miss (Del G x) φ1 K z).card ≤ 1)).card := by
            apply card_le_card
            intro y hy
            simp only [mem_filter, mem_univ, true_and, hnb', hmiss'] at hy
            simp only [mem_union, mem_filter, hmemN]
            by_cases hay : a ∈ miss (Del G x) φ1 K y
            · rw [card_erase_of_mem hay] at hy
              left
              exact ⟨hy.1.1, hy.1.2, hay, by omega⟩
            · rw [erase_eq_of_notMem hay] at hy
              right
              exact ⟨hy.1.1, hy.2⟩
        _ ≤ _ := card_union_le _ _
        _ ≤ 1 := hgood
    obtain ⟨ψ', hψ'⟩ := ih (K.erase a) (by rw [card_erase_of_mem haK, hK]; rfl) G' x φ1
      hcol' hd' h1' hs'
    refine ⟨fun v w => if G'.Adj v w then ψ' v w else a, ?_, ?_, ?_⟩
    · intro v w _
      dsimp only
      split_ifs with h
      · exact mem_of_mem_erase (hψ'.1 v w h)
      · exact haK
    · intro v w _
      dsimp only
      by_cases h : G'.Adj v w
      · rw [if_pos h, if_pos h.symm]; exact hψ'.2.1 v w h
      · rw [if_neg h, if_neg (fun h' => h h'.symm)]
    · intro v w1 w2 hv1 hv2 hne
      dsimp only
      by_cases g1 : G'.Adj v w1 <;> by_cases g2 : G'.Adj v w2
      · rw [if_pos g1, if_pos g2]; exact hψ'.2.2 v w1 w2 g1 g2 hne
      · rw [if_pos g1, if_neg g2]; exact (mem_erase.1 (hψ'.1 v w1 g1)).1
      · rw [if_neg g1, if_pos g2]; exact Ne.symm (mem_erase.1 (hψ'.1 v w2 g2)).1
      · exfalso
        have hux : u ≠ x := hxu.ne.symm
        have hau' := (mem_miss.1 hau).2
        rcases Gp_cases hφ1 hv1 g1 with ⟨hv, hw⟩ | ⟨hv, hw⟩ | ⟨hv, hw, hk1⟩ <;>
          rcases Gp_cases hφ1 hv2 g2 with ⟨hv', hw'⟩ | ⟨hv', hw'⟩ | ⟨hv', hw', hk2⟩
        · exact hne (hw.trans hw'.symm)
        · exact hux (hv'.symm.trans hv)
        · exact hv' hv
        · exact hux (hv.symm.trans hv')
        · exact hne (hw.trans hw'.symm)
        · subst hv
          exact hau' w2 ⟨hv2, hux, hw'⟩ hk2
        · exact hv hv'
        · subst hv'
          exact hau' w1 ⟨hv1, hux, hw⟩ hk1
        · exact hφ1.2.2 v w1 w2 ⟨hv1, hv, hw⟩ ⟨hv2, hv', hw'⟩ hne (hk1.trans hk2.symm)

def GS (G : SimpleGraph V) (S : Finset V) : SimpleGraph V where
  Adj u v := G.Adj u v ∧ u ∈ S ∧ v ∈ S
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.2, h.2.1⟩⟩
  loopless := ⟨fun _ h => G.irrefl h.1⟩

theorem viz_col [Fintype V] (G : SimpleGraph V) (D : ℕ)
    (hD : ∀ v, (univ.filter (fun w => G.Adj v w)).card ≤ D) :
    ∃ φ, IsCol G (range (D + 1)) φ := by
  have key : ∀ S : Finset V, ∃ φ, IsCol (GS G S) (range (D + 1)) φ := by
    intro S
    induction S using Finset.induction_on with
    | empty =>
      exact ⟨fun _ _ => 0, fun u v h => absurd h.2.1 (notMem_empty _),
        fun u v h => absurd h.2.1 (notMem_empty _), fun u v w h => absurd h.2.1 (notMem_empty _)⟩
    | insert x S hx ih =>
      obtain ⟨φ, hφ⟩ := ih
      set G1 := GS G (insert x S) with hG1
      have hcol : IsCol (Del G1 x) (range (D + 1)) φ :=
        hφ.mono (fun u v h => ⟨h.1.1, (mem_insert.1 h.1.2.1).resolve_left h.2.1,
          (mem_insert.1 h.1.2.2).resolve_left h.2.2⟩)
      have h2 : ∀ y, G1.Adj x y → 2 ≤ (miss (Del G1 x) φ (range (D + 1)) y).card := by
        intro y hy
        have hlow := card_le_miss_add (Del G1 x) φ (range (D + 1)) y
        have hsub : univ.filter (fun w => (Del G1 x).Adj y w) ⊂
            univ.filter (fun w => G.Adj y w) := by
          rw [ssubset_iff_of_subset]
          · refine ⟨x, by simpa using hy.1.symm, ?_⟩
            simp only [mem_filter, mem_univ, true_and]
            exact fun h => h.2.2 rfl
          · intro w hw
            simp only [mem_filter, mem_univ, true_and] at hw ⊢
            exact hw.1.1
        have := card_lt_card hsub
        have := hD y
        rw [card_range] at hlow
        omega
      apply VL (range (D + 1)).card (range (D + 1)) rfl G1 x φ hcol
      · rw [card_range]
        refine le_trans (card_le_card (fun y hy => ?_)) ((hD x).trans (Nat.le_succ D))
        simp only [mem_filter, mem_univ, true_and] at hy ⊢
        exact hy.1
      · intro y hy
        have := h2 y hy
        omega
      · rw [card_le_one]
        intro a ha b hb
        simp only [mem_filter, mem_univ, true_and] at ha hb
        have := h2 a ha.1
        omega
  obtain ⟨φ, hφ⟩ := key univ
  exact ⟨φ, hφ.mono (fun u v h => ⟨h, mem_univ _, mem_univ _⟩)⟩


theorem walk_parity {F : SimpleGraph V} (col : V → Fin 2)
    (hF : ∀ u v, F.Adj u v → col u ≠ col v) :
    ∀ {u v : V} (p : F.Walk u v), (Even p.length ↔ col u = col v) := by
  intro u v p
  induction p with
  | nil => simp
  | cons h p ih =>
    rw [Walk.length_cons, Nat.even_add_one, ih]
    have key : ∀ a b c : Fin 2, a ≠ b → ((¬ b = c) ↔ a = c) := by decide
    exact key _ _ _ (hF _ _ h)

theorem alt {H : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ} (hφ : IsCol H K φ) {a b : ℕ}
    (hab : a ≠ b) :
    ∀ {v w : V} (p : (kg H φ a b).Walk v w), p.IsPath → ∀ γ, (γ = a ∨ γ = b) →
      (∀ z, (kg H φ a b).Adj v z → φ v z = γ → z ∉ p.support) → 0 < p.length →
      ∃ z, (kg H φ a b).Adj w z ∧
        φ w z = (if Even p.length then γ else (if γ = a then b else a)) := by
  intro v w p
  induction p with
  | nil => intro _ _ _ _ h; simp at h
  | @cons v v1 w h p ih =>
    intro hpath γ hγ hv _
    rw [Walk.cons_isPath_iff] at hpath
    have hc1 : φ v v1 ≠ γ := fun e => hv v1 h e (by simp)
    have hc1' : φ v v1 = (if γ = a then b else a) := by
      rcases h.2.1 with e | e <;> rcases hγ with g | g <;> subst g
      · exact absurd e hc1
      · rw [if_neg hab.symm]; exact e
      · rw [if_pos rfl]; exact e
      · exact absurd e hc1
    have hsym : φ v v1 = φ v1 v := hφ.2.1 v v1 h.1
    have hoo : (if (if γ = a then b else a) = a then b else a) = γ := by
      rcases hγ with g | g <;> subst g
      · rw [if_pos rfl, if_neg hab.symm]
      · rw [if_neg hab.symm, if_pos rfl]
    by_cases hp0 : p.length = 0
    · have hvw := Walk.eq_of_length_eq_zero hp0
      subst hvw
      refine ⟨v, h.symm, ?_⟩
      rw [Walk.length_cons, hp0, ← hsym, hc1']
      simp
    · have hside : ∀ z, (kg H φ a b).Adj v1 z → φ v1 z = (if γ = a then b else a) →
          z ∉ p.support := by
        intro z hz hzc hzs
        have hzv : z = v := by
          by_contra hne
          exact hφ.2.2 v1 z v hz.1 h.1.symm hne (hzc.trans (hc1'.symm.trans hsym))
        subst hzv
        exact hpath.2 hzs
      obtain ⟨z, hz, hzc⟩ := ih hpath.1 (if γ = a then b else a)
        (by split_ifs <;> simp) hside (Nat.pos_of_ne_zero hp0)
      refine ⟨z, hz, ?_⟩
      rw [hzc, hoo]
      simp only [Walk.length_cons, Nat.even_add_one]
      by_cases he : Even p.length <;> simp [he]

theorem ext_col {H H' : SimpleGraph V} {K : Finset ℕ} {φ : V → V → ℕ} {p q : V} (hpq : p ≠ q)
    (hcov : ∀ u v, H.Adj u v → H'.Adj u v ∨ (u = p ∧ v = q) ∨ (u = q ∧ v = p))
    (hφ : IsCol H' K φ) {c : ℕ} (hc : c ∈ K) (hcp : c ∈ miss H' φ K p)
    (hcq : c ∈ miss H' φ K q) :
    IsCol H K (fun u v => if (u = p ∧ v = q) ∨ (u = q ∧ v = p) then c else φ u v) := by
  have hH' : ∀ u v, H.Adj u v → ¬((u = p ∧ v = q) ∨ (u = q ∧ v = p)) → H'.Adj u v :=
    fun u v h hn => (hcov u v h).resolve_right hn
  refine ⟨fun u v huv => ?_, fun u v huv => ?_, fun u v w huv huw hvw => ?_⟩
  · dsimp only
    split_ifs with h
    · exact hc
    · exact hφ.1 u v (hH' u v huv h)
  · dsimp only
    by_cases h : (u = p ∧ v = q) ∨ (u = q ∧ v = p)
    · have h' : (v = p ∧ u = q) ∨ (v = q ∧ u = p) := by
        rcases h with ⟨h1, h2⟩ | ⟨h1, h2⟩
        · exact Or.inr ⟨h2, h1⟩
        · exact Or.inl ⟨h2, h1⟩
      rw [if_pos h, if_pos h']
    · have h' : ¬((v = p ∧ u = q) ∨ (v = q ∧ u = p)) := by
        rintro (⟨h1, h2⟩ | ⟨h1, h2⟩)
        · exact h (Or.inr ⟨h2, h1⟩)
        · exact h (Or.inl ⟨h2, h1⟩)
      rw [if_neg h, if_neg h']
      exact hφ.2.1 u v (hH' u v huv h)
  · dsimp only
    by_cases hv : (u = p ∧ v = q) ∨ (u = q ∧ v = p) <;>
      by_cases hw : (u = p ∧ w = q) ∨ (u = q ∧ w = p)
    · exfalso
      rcases hv with ⟨h1, h2⟩ | ⟨h1, h2⟩ <;> rcases hw with ⟨h3, h4⟩ | ⟨h3, h4⟩
      · exact hvw (h2.trans h4.symm)
      · exact hpq (h1.symm.trans h3)
      · exact hpq (h3.symm.trans h1)
      · exact hvw (h2.trans h4.symm)
    · rw [if_pos hv, if_neg hw]
      have hw' := hH' u w huw hw
      rcases hv with ⟨h1, _⟩ | ⟨h1, _⟩ <;> subst h1
      · exact fun e => (mem_miss.1 hcp).2 w hw' e.symm
      · exact fun e => (mem_miss.1 hcq).2 w hw' e.symm
    · rw [if_neg hv, if_pos hw]
      have hv' := hH' u v huv hv
      rcases hw with ⟨h1, _⟩ | ⟨h1, _⟩ <;> subst h1
      · exact fun e => (mem_miss.1 hcp).2 v hv' e
      · exact fun e => (mem_miss.1 hcq).2 v hv' e
    · rw [if_neg hv, if_neg hw]
      exact hφ.2.2 u v w (hH' u v huv hv) (hH' u w huw hw) hvw

theorem kon_step [Fintype V] {H H' : SimpleGraph V} {k : ℕ} {φ : V → V → ℕ} {p q : V}
    (col : V → Fin 2) (hcol : ∀ u v, H.Adj u v → col u ≠ col v)
    (hpq : H.Adj p q) (hsub : ∀ u v, H'.Adj u v → H.Adj u v)
    (hcov : ∀ u v, H.Adj u v → H'.Adj u v ∨ (u = p ∧ v = q) ∨ (u = q ∧ v = p))
    (hnot : ¬ H'.Adj p q)
    (hdeg : ∀ v, (univ.filter (fun w => H.Adj v w)).card ≤ k)
    (hφ : IsCol H' (range k) φ) : ∃ ψ, IsCol H (range k) ψ := by
  have hlow : ∀ v w, H.Adj v w → ¬ H'.Adj v w → 1 ≤ (miss H' φ (range k) v).card := by
    intro v w hvw hn
    have h1 := card_le_miss_add H' φ (range k) v
    have hss : univ.filter (fun z => H'.Adj v z) ⊂ univ.filter (fun z => H.Adj v z) := by
      rw [ssubset_iff_of_subset]
      · exact ⟨w, by simpa using hvw, by simpa using hn⟩
      · intro z hz
        simp only [mem_filter, mem_univ, true_and] at hz ⊢
        exact hsub v z hz
    have := card_lt_card hss
    have := hdeg v
    rw [card_range] at h1
    omega
  obtain ⟨α, hα⟩ := card_pos.1 (hlow p q hpq hnot)
  obtain ⟨β, hβ⟩ := card_pos.1 (hlow q p hpq.symm (fun h => hnot h.symm))
  have hαK := miss_subset _ _ _ _ hα
  have hβK := miss_subset _ _ _ _ hβ
  by_cases hαq : α ∈ miss H' φ (range k) q
  · exact ⟨_, ext_col hpq.ne hcov hφ hαK hα hαq⟩
  have hab : α ≠ β := fun e => hαq (e ▸ hβ)
  have hnr : ¬ (kg H' φ α β).Reachable p q := by
    rintro ⟨w⟩
    have hP := w.bypass_isPath
    have hlen : 0 < w.bypass.length := by
      rcases Nat.eq_zero_or_pos w.bypass.length with h0 | h0
      · exact absurd (Walk.eq_of_length_eq_zero h0) hpq.ne
      · exact h0
    obtain ⟨z, hz, hzc⟩ := alt hφ hab w.bypass hP α (Or.inl rfl)
      (fun z hz hzc _ => (mem_miss.1 hα).2 z hz.1 hzc) hlen
    have heven : Even w.bypass.length := by
      by_contra hodd
      rw [if_neg hodd, if_pos rfl] at hzc
      exact (mem_miss.1 hβ).2 z hz.1 hzc
    have := (walk_parity (F := kg H' φ α β) col (fun u v h => hcol u v (hsub u v h.1)) w.bypass).1 heven
    exact hcol p q hpq this
  refine ⟨_, ext_col hpq.ne hcov (kswap_col p hφ hαK hβK) hβK ?_ ?_⟩
  · rw [kswap_mem_miss p hαK hβK, if_pos (Reachable.refl _), sw_b α β hab]
    exact hα
  · rw [kswap_mem_miss p hαK hβK, if_neg hnr]
    exact hβ

def GE (G : SimpleGraph V) (E : Finset (V × V)) : SimpleGraph V where
  Adj u v := G.Adj u v ∧ ((u, v) ∈ E ∨ (v, u) ∈ E)
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.symm⟩⟩
  loopless := ⟨fun _ h => G.irrefl h.1⟩

theorem kon_col [Fintype V] (G : SimpleGraph V) (col : V → Fin 2)
    (hcol : ∀ u v, G.Adj u v → col u ≠ col v) (D : ℕ)
    (hD : ∀ v, (univ.filter (fun w => G.Adj v w)).card ≤ D) :
    ∃ φ, IsCol G (range D) φ := by
  have key : ∀ E : Finset (V × V), ∃ φ, IsCol (GE G E) (range D) φ := by
    intro E
    induction E using Finset.induction_on with
    | empty =>
      refine ⟨fun _ _ => 0, fun u v h => ?_, fun u v h => ?_, fun u v w h => ?_⟩ <;>
        simp [GE] at h
    | insert e E he ih =>
      obtain ⟨φ, hφ⟩ := ih
      obtain ⟨p, q⟩ := e
      by_cases hnew : G.Adj p q ∧ ¬((p, q) ∈ E ∨ (q, p) ∈ E)
      · refine kon_step (H := GE G (insert (p, q) E)) (H' := GE G E) (p := p) (q := q) col
          (fun u v (h : (GE G (insert (p, q) E)).Adj u v) => hcol u v h.1)
          ⟨hnew.1, Or.inl (mem_insert_self _ _)⟩
          (fun u v (h : (GE G E).Adj u v) => ⟨h.1, h.2.imp (fun h' => mem_insert_of_mem h')
            (fun h' => mem_insert_of_mem h')⟩) ?_ (fun h => hnew.2 h.2) ?_ hφ
        · intro u v h
          by_cases h' : (GE G E).Adj u v
          · exact Or.inl h'
          · right
            rcases h.2 with h2 | h2 <;> rw [mem_insert] at h2
            · rcases h2 with h2 | h2
              · simp only [Prod.mk.injEq] at h2; exact Or.inl h2
              · exact absurd ⟨h.1, Or.inl h2⟩ h'
            · rcases h2 with h2 | h2
              · simp only [Prod.mk.injEq] at h2; exact Or.inr ⟨h2.2, h2.1⟩
              · exact absurd ⟨h.1, Or.inr h2⟩ h'
        · intro v
          refine le_trans (card_le_card (fun w hw => ?_)) (hD v)
          simp only [mem_filter, mem_univ, true_and] at hw ⊢
          exact hw.1
      · refine ⟨φ, hφ.mono (fun u v h => ⟨h.1, ?_⟩)⟩
        rcases h.2 with h2 | h2 <;> rw [mem_insert] at h2
        · rcases h2 with h2 | h2
          · simp only [Prod.mk.injEq] at h2
            obtain ⟨rfl, rfl⟩ := h2
            push_neg at hnew
            exact hnew h.1
          · exact Or.inl h2
        · rcases h2 with h2 | h2
          · simp only [Prod.mk.injEq] at h2
            obtain ⟨rfl, rfl⟩ := h2
            push_neg at hnew
            exact (hnew h.1.symm).symm
          · exact Or.inr h2
  obtain ⟨φ, hφ⟩ := key univ
  exact ⟨φ, hφ.mono (fun u v h => ⟨h, Or.inl (mem_univ _)⟩)⟩


theorem line_colorable {G : SimpleGraph V} {k : ℕ} {φ : V → V → ℕ} (h : IsCol G (range k) φ) :
    G.lineGraph.Colorable k := by
  let f : Sym2 V → ℕ := Sym2.lift ⟨fun u v => min (φ u v) (φ v u), fun u v => min_comm _ _⟩
  have hf : ∀ u v, G.Adj u v → f s(u, v) = φ u v := by
    intro u v huv
    simp only [f, Sym2.lift_mk, h.2.1 u v huv, min_self]
  have hlt : ∀ e : G.edgeSet, f e.1 < k := by
    rintro ⟨e, he⟩
    induction e using Sym2.ind with
    | h u v =>
      rw [mem_edgeSet] at he
      rw [hf u v he]
      exact mem_range.1 (h.1 u v he)
  refine ⟨Coloring.mk (fun e => ⟨f e.1, hlt e⟩) ?_⟩
  intro e1 e2 hadj
  rw [lineGraph_adj_iff_exists] at hadj
  obtain ⟨hne, v, hv1, hv2⟩ := hadj
  obtain ⟨w1, hw1⟩ := Sym2.mem_iff_exists.1 hv1
  obtain ⟨w2, hw2⟩ := Sym2.mem_iff_exists.1 hv2
  have ha1 : G.Adj v w1 := by
    have := e1.2
    rw [hw1] at this
    exact this
  have ha2 : G.Adj v w2 := by
    have := e2.2
    rw [hw2] at this
    exact this
  have hw : w1 ≠ w2 := by
    rintro rfl
    exact hne (Subtype.ext (hw1.trans hw2.symm))
  intro heq
  have := congrArg Fin.val heq
  simp only at this
  rw [hw1, hw2, hf v w1 ha1, hf v w2 ha2] at this
  exact h.2.2 v w1 w2 ha1 ha2 hw this

theorem maxDeg_le_line [Fintype V] (G : SimpleGraph V) [DecidableRel G.Adj] :
    (G.maxDegree : ℕ∞) ≤ G.lineGraph.chromaticNumber := by
  cases isEmpty_or_nonempty V
  · rw [maxDegree_of_subsingleton]
    simp
  obtain ⟨v, hv⟩ := G.exists_maximal_degree_vertex
  rw [hv]
  refine le_chromaticNumber_of_pairwise_adj (ι := G.neighborSet v) ?_
    (fun w => (⟨s(v, w.1), w.2⟩ : G.edgeSet)) ?_
  · rw [Nat.card_eq_fintype_card, card_neighborSet_eq_degree]
  · intro w1 w2 hne
    rw [lineGraph_adj_iff_exists]
    refine ⟨fun e => hne (Subtype.ext ?_), v, Sym2.mem_mk_left _ _, Sym2.mem_mk_left _ _⟩
    exact Sym2.congr_right.1 (congrArg Subtype.val e)

theorem filter_card_le_maxDegree [Fintype V] (G : SimpleGraph V) [DecidableRel G.Adj] (v : V) :
    (univ.filter (fun w => G.Adj v w)).card ≤ G.maxDegree := by
  have h := G.degree_le_maxDegree v
  rw [← card_neighborFinset_eq_degree, neighborFinset_eq_filter] at h
  convert h using 2

theorem mod_ne_add {N a b c : ℕ} (hb : b < N) (hc : c < N) (hbc : b ≠ c) :
    (a + b) % N ≠ (a + c) % N := by
  intro h
  have h' : b % N = c % N := Nat.ModEq.add_left_cancel' a h
  rw [Nat.mod_eq_of_lt hb, Nat.mod_eq_of_lt hc] at h'
  exact hbc h'

theorem mod_ne_two {N b c : ℕ} (hN : Odd N) (hb : b < N) (hc : c < N) (hbc : b ≠ c) :
    (2 * b) % N ≠ (2 * c) % N := by
  intro h
  have hg : Nat.gcd N 2 = 1 := Nat.coprime_two_right.2 hN
  have h' : b % N = c % N := Nat.ModEq.cancel_left_of_coprime hg h
  rw [Nat.mod_eq_of_lt hb, Nat.mod_eq_of_lt hc] at h'
  exact hbc h'

theorem rr_col (n : ℕ) (hn : Even n) :
    ∃ φ, IsCol (⊤ : SimpleGraph (Fin n)) (range (n - 1)) φ := by
  rcases Nat.eq_zero_or_pos n with rfl | hpos
  · exact ⟨fun _ _ => 0, fun u => u.elim0, fun u => u.elim0, fun u => u.elim0⟩
  obtain ⟨r, hr⟩ := hn
  set N := n - 1 with hN
  have hNodd : Odd N := ⟨r - 1, by omega⟩
  have hNpos : 0 < N := by omega
  refine ⟨fun i j => if i.val = N then (2 * j.val) % N else if j.val = N then (2 * i.val) % N
    else (i.val + j.val) % N, ?_, ?_, ?_⟩
  · intro i j _
    dsimp only
    split_ifs <;> exact mem_range.2 (Nat.mod_lt _ hNpos)
  · intro i j hij
    have hne : i.val ≠ j.val := fun e => hij.ne (Fin.ext e)
    dsimp only
    split_ifs <;> first | omega | rw [add_comm]
  · intro i j k hij hik hjk
    have hjk' : j.val ≠ k.val := fun e => hjk (Fin.ext e)
    have hij' : i.val ≠ j.val := fun e => hij.ne (Fin.ext e)
    have hik' : i.val ≠ k.val := fun e => hik.ne (Fin.ext e)
    have hi := i.isLt
    have hj := j.isLt
    have hk := k.isLt
    dsimp only
    split_ifs
    all_goals first
      | exact mod_ne_two hNodd (by omega) (by omega) hjk'
      | exact mod_ne_add (by omega) (by omega) hjk'
      | (rw [two_mul]; exact mod_ne_add (by omega) (by omega) (by omega))
      | omega

theorem no_col_odd (n : ℕ) (hodd : Odd n) (h3 : 3 ≤ n) :
    ¬ (⊤ : SimpleGraph (Fin n)).lineGraph.Colorable (n - 1) := by
  rintro ⟨C⟩
  have hmem : ∀ v w : Fin n, v ≠ w → s(v, w) ∈ (⊤ : SimpleGraph (Fin n)).edgeSet := by
    intro v w h
    simpa using h
  let ecol : Fin n → Fin n → ℕ := fun v w =>
    if h : v ≠ w then (C ⟨s(v, w), hmem v w h⟩ : Fin (n - 1)).val else n
  have hecol : ∀ v w (h : v ≠ w), ecol v w = (C ⟨s(v, w), hmem v w h⟩ : Fin (n - 1)).val :=
    fun v w h => dif_pos h
  have hsymm : ∀ v w, ecol v w = ecol w v := by
    intro v w
    by_cases h : v ≠ w
    · rw [hecol v w h, hecol w v (Ne.symm h)]
      exact congrArg (fun e => (C e).val) (Subtype.ext Sym2.eq_swap)
    · have : v = w := not_not.1 h
      subst this
      rfl
  have hlt : ∀ v w, v ≠ w → ecol v w < n - 1 := by
    intro v w h
    rw [hecol v w h]
    exact (C _).isLt
  have hinj : ∀ v w1 w2, v ≠ w1 → v ≠ w2 → w1 ≠ w2 → ecol v w1 ≠ ecol v w2 := by
    intro v w1 w2 h1 h2 h12
    rw [hecol v w1 h1, hecol v w2 h2]
    intro e
    apply C.valid _ (Fin.ext e)
    rw [lineGraph_adj_iff_exists]
    refine ⟨fun e' => h12 ?_, v, Sym2.mem_mk_left _ _, Sym2.mem_mk_left _ _⟩
    exact Sym2.congr_right.1 (congrArg Subtype.val e')
  let Gc : SimpleGraph (Fin n) :=
    { Adj := fun v w => v ≠ w ∧ ecol v w = 0
      symm := ⟨fun v w h => ⟨Ne.symm h.1, (hsymm w v).trans h.2⟩⟩
      loopless := ⟨fun v h => h.1 rfl⟩ }
  have hdeg : ∀ v, Gc.degree v = 1 := by
    intro v
    rw [← card_neighborFinset_eq_degree, neighborFinset_eq_filter, card_eq_one]
    have himg : ((univ.erase v).image (ecol v)) = range (n - 1) := by
      apply eq_of_subset_of_card_le
      · intro c hc
        obtain ⟨w, hw, rfl⟩ := mem_image.1 hc
        exact mem_range.2 (hlt v w (Ne.symm (ne_of_mem_erase hw)))
      · rw [card_range, card_image_of_injOn, card_erase_of_mem (mem_univ _), card_univ,
          Fintype.card_fin]
        intro w1 hw1 w2 hw2 e
        by_contra h12
        exact hinj v w1 w2 (Ne.symm (ne_of_mem_erase hw1)) (Ne.symm (ne_of_mem_erase hw2))
          h12 e
    have h0 : 0 ∈ (univ.erase v).image (ecol v) := by
      rw [himg]
      exact mem_range.2 (by omega)
    obtain ⟨w, hw, hw0⟩ := mem_image.1 h0
    have hvw : v ≠ w := Ne.symm (ne_of_mem_erase hw)
    refine ⟨w, ?_⟩
    ext z
    simp only [mem_filter, mem_univ, true_and, mem_singleton]
    constructor
    · rintro ⟨hvz, hz0⟩
      by_contra hzw
      exact hinj v z w hvz hvw hzw (hz0.trans hw0.symm)
    · rintro rfl
      exact ⟨hvw, hw0⟩
  have hsum := Gc.sum_degrees_eq_twice_card_edges
  simp only [hdeg, sum_const, card_univ, Fintype.card_fin, smul_eq_mul, mul_one] at hsum
  exact (Nat.not_even_iff_odd.2 hodd) ⟨_, hsum.trans (two_mul _)⟩

end Helpers

#print axioms mem_miss
#print axioms miss_subset
#print axioms IsCol.mono
#print axioms card_le_miss_add
#print axioms sw_sw
#print axioms sw_inj
#print axioms sw_mem
#print axioms sw_eq_iff
#print axioms kswap_col
#print axioms kswap_mem_miss
#print axioms kswap_card_miss
#print axioms comp_low
#print axioms card_colour_le_one
#print axioms kg_degree_eq
#print axioms kg_deg_le
#print axioms kg_deg_miss
#print axioms even_sum'
#print axioms sw_b
#print axioms core
#print axioms isCol_of_noNbr
#print axioms Gp_cases
#print axioms VL
#print axioms viz_col
#print axioms walk_parity
#print axioms alt
#print axioms ext_col
#print axioms kon_step
#print axioms kon_col
#print axioms line_colorable
#print axioms maxDeg_le_line
#print axioms filter_card_le_maxDegree
#print axioms mod_ne_add
#print axioms mod_ne_two
#print axioms rr_col
#print axioms no_col_odd

end ECHelp

/-! The chromatic index of `G` is the chromatic number of its line graph: a proper colouring of
the line graph is exactly an edge colouring in which no two edges of one colour meet at a dot.
A `SimpleGraph` has no loops and joins a pair at most once, which is the card's
"no pair meets twice". -/

/-- Vizing's theorem: in a finite network where no pair is joined twice, the lines need at least
as many colours as the busiest dot has lines, and at most one more. -/
theorem vizing_chromatic_index_le_max_degree_add_one {V : Type*} [Fintype V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    (G.maxDegree : ℕ∞) ≤ G.lineGraph.chromaticNumber ∧
      G.lineGraph.chromaticNumber ≤ G.maxDegree + 1 := by
  refine ⟨ECHelp.maxDeg_le_line G, ?_⟩
  obtain ⟨φ, hφ⟩ := ECHelp.viz_col G G.maxDegree
    (fun v => by convert ECHelp.filter_card_le_maxDegree G v using 2; ext w; simp)
  have := (ECHelp.line_colorable hφ).chromaticNumber_le
  exact_mod_cast this

/-- König's theorem: a finite bipartite network never needs the spare colour; its lines need
exactly as many colours as the busiest dot has lines. -/
theorem konig_bipartite_chromatic_index_eq_max_degree {V : Type*} [Fintype V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.IsBipartite) :
    G.lineGraph.chromaticNumber = G.maxDegree := by
  obtain ⟨c⟩ := hG
  obtain ⟨φ, hφ⟩ := ECHelp.kon_col G c (fun u v h => c.valid h) G.maxDegree
    (fun v => by convert ECHelp.filter_card_le_maxDegree G v using 2; ext w; simp)
  exact le_antisymm (ECHelp.line_colorable hφ).chromaticNumber_le (ECHelp.maxDeg_le_line G)

/-- The complete network on `n` dots (everyone plays everyone once): its lines need `n - 1`
colours when `n` is even, and `n` colours when `n` is odd and at least 3. -/
theorem complete_graph_chromatic_index (n : ℕ) :
    (Even n → (⊤ : SimpleGraph (Fin n)).lineGraph.chromaticNumber = ((n - 1 : ℕ) : ℕ∞)) ∧
      (Odd n → 3 ≤ n → (⊤ : SimpleGraph (Fin n)).lineGraph.chromaticNumber = n) := by
  refine ⟨fun hn => ?_, fun hn h3 => ?_⟩
  · obtain ⟨φ, hφ⟩ := ECHelp.rr_col n hn
    refine le_antisymm (ECHelp.line_colorable hφ).chromaticNumber_le ?_
    have := ECHelp.maxDeg_le_line (⊤ : SimpleGraph (Fin n))
    rw [maxDegree_top, Fintype.card_fin] at this
    exact this
  · apply le_antisymm
    · have := (vizing_chromatic_index_le_max_degree_add_one (⊤ : SimpleGraph (Fin n))).2
      rw [maxDegree_top, Fintype.card_fin] at this
      have e : ((n - 1 : ℕ) : ℕ∞) + 1 = (n : ℕ∞) := by
        have h : n - 1 + 1 = n := by omega
        rw [← Nat.cast_succ]
        congr 1
      rw [e] at this
      exact this
    · rw [le_chromaticNumber_iff_colorable]
      intro m hm
      by_contra hlt
      push_neg at hlt
      exact ECHelp.no_col_odd n hn h3 (hm.mono (by omega))

/-! The card's worked numbers. -/

/-- The six-club league's rotation: the pin F (club 5) meets club `i` in weekend `i`, and rotating
clubs `i` and `j` meet in weekend `3(i + j) mod 5`. -/
def weekend (i j : Fin 6) : ℕ :=
  if i.val = 5 then j.val else if j.val = 5 then i.val else 3 * (i.val + j.val) % 5

-- Six clubs: 6 × 5 halved is 15 matches.
example : (⊤ : SimpleGraph (Fin 6)).edgeFinset.card = 15 := by decide
-- Every club has five opponents.
example : ∀ v : Fin 6, (⊤ : SimpleGraph (Fin 6)).degree v = 5 := by decide
-- 15 matches at 3 a weekend fill exactly 5 weekends.
example : 15 / 3 = 5 ∧ 3 * 5 = 15 := by norm_num
-- Five clubs: 10 matches, at most 2 a weekend, so 5 weekends; 4 weekends hold only 8.
example : 5 * 4 / 2 = 10 ∧ 10 / 2 = 5 ∧ 4 * 2 = 8 := by norm_num
-- Squeezing six clubs into 4 weekends gives 12 slots, 3 short of 15.
example : 4 * 3 = 12 ∧ 15 - 12 = 3 := by norm_num
-- Weekend 0 (the picture): A-F, B-E, C-D.
example : weekend 0 5 = 0 ∧ weekend 1 4 = 0 ∧ weekend 2 3 = 0 := by decide
-- A and B add to 1, so they meet in weekend 3, the fourth weekend.
example : weekend 0 1 = 3 := by decide
-- The rotation is symmetric and nothing clashes: two different matches sharing a club
-- never share a weekend.
example : ∀ i j : Fin 6, weekend i j = weekend j i := by decide
example : ∀ a b c : Fin 6, a ≠ b → a ≠ c → b ≠ c → weekend a b ≠ weekend a c := by decide
-- Five weekends, numbered 0 to 4, each holding exactly three of the 15 matches.
example : ∀ k : Fin 5, ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
    (fun p => p.1 < p.2 ∧ weekend p.1 p.2 = k.val)).card = 3 := by decide
-- Rotating all six with no pin schedules only 6 of the 15 matches, and A-B is not among them.
example : ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
    (fun p => p.1 < p.2 ∧ ∃ k : Fin 6, (p.1.val + p.2.val) % 6 = 2 * k.val % 6)).card = 6 := by
  decide
example : ¬ ∃ k : Fin 6, (0 + 1) % 6 = 2 * k.val % 6 := by decide

#print axioms vizing_chromatic_index_le_max_degree_add_one
#print axioms konig_bipartite_chromatic_index_eq_max_degree
#print axioms complete_graph_chromatic_index
