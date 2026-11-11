-- Spanning trees: a finite map has a spanning tree exactly when it is in one piece, every spanning tree on n places has n - 1 roads, and the complete map on n named places has n ^ (n - 2) spanning trees (Cayley's formula), with the card's village counts checked.
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Finite
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Tactic.Ring

namespace SpanningTreesAndCayleysFormula

noncomputable section

open SimpleGraph Function Classical

/-- One step along a parent map: `none` stays `none`, `some v` goes to `F v`. -/
def stp {V : Type*} (F : V → Option V) (o : Option V) : Option V := o.bind F

theorem stp_some {V : Type*} (F : V → Option V) (v : V) : stp F (some v) = F v := rfl

theorem iter_none {V : Type*} (F : V → Option V) (m : ℕ) : (stp F)^[m] none = none := by
  induction m with
  | zero => rfl
  | succ m ih => rw [iterate_succ_apply]; exact ih

/-- A parent map is acyclic when every vertex eventually steps off to `none`. -/
def Acyc {V : Type*} (F : V → Option V) : Prop := ∀ v, ∃ m, (stp F)^[m] (some v) = none

/-- `v` reaches `r` along the parent map. -/
def Reach {V : Type*} (F : V → Option V) (v r : V) : Prop := ∃ m, (stp F)^[m] (some v) = some r

theorem exists_min_nat {P : ℕ → Prop} (h : ∃ m, P m) : ∃ m, P m ∧ ∀ k < m, ¬ P k :=
  ⟨Nat.find h, Nat.find_spec h, fun _ hk => Nat.find_min h hk⟩

theorem iter_after_none {V : Type*} (F : V → Option V) {x : Option V} {a b : ℕ} (hab : a ≤ b)
    (h : (stp F)^[a] x = none) : (stp F)^[b] x = none := by
  obtain ⟨c, rfl⟩ := Nat.exists_eq_add_of_le hab
  rw [add_comm, iterate_add_apply, h, iter_none]

theorem exists_root {V : Type*} (F : V → Option V) (hF : Acyc F) (v : V) :
    ∃ r, F r = none ∧ Reach F v r := by
  obtain ⟨m, hm, hmin⟩ := exists_min_nat (hF v)
  cases m with
  | zero => simp at hm
  | succ k =>
    cases hx : (stp F)^[k] (some v) with
    | none => exact absurd hx (hmin k (by omega))
    | some u =>
      refine ⟨u, ?_, k, hx⟩
      rw [iterate_succ_apply', hx, stp_some] at hm
      exact hm

theorem root_unique_aux {V : Type*} (F : V → Option V) {v r1 r2 : V} (h1 : F r1 = none)
    {a b : ℕ} (hab : a ≤ b) (ha : (stp F)^[a] (some v) = some r1)
    (hb : (stp F)^[b] (some v) = some r2) : r1 = r2 := by
  obtain ⟨c, rfl⟩ := Nat.exists_eq_add_of_le hab
  cases c with
  | zero => rw [Nat.add_zero, ha] at hb; exact Option.some_injective _ hb
  | succ c =>
    rw [show a + (c + 1) = c + 1 + a by omega, iterate_add_apply, ha, iterate_succ_apply,
      stp_some, h1, iter_none] at hb
    cases hb

theorem root_unique {V : Type*} (F : V → Option V) {v r1 r2 : V} (h1 : F r1 = none)
    (h2 : F r2 = none) (ha : Reach F v r1) (hb : Reach F v r2) : r1 = r2 := by
  obtain ⟨a, ha⟩ := ha
  obtain ⟨b, hb⟩ := hb
  rcases le_total a b with hab | hab
  · exact root_unique_aux F h1 hab ha hb
  · exact (root_unique_aux F h2 hab hb ha).symm

theorem iter_update_eq {V : Type*} (F : V → Option V) (r : V) (val : Option V) (x : Option V)
    (m : ℕ) (h : ∀ j < m, (stp F)^[j] x ≠ some r) :
    (stp (update F r val))^[m] x = (stp F)^[m] x := by
  induction m with
  | zero => rfl
  | succ m ih =>
    rw [iterate_succ_apply', iterate_succ_apply', ih (fun j hj => h j (by omega))]
    have hm := h m (by omega)
    cases hy : (stp F)^[m] x with
    | none => rfl
    | some y =>
      rw [hy] at hm
      simp only [stp_some]
      exact update_of_ne (by rintro rfl; exact hm rfl) _ _

theorem no_return {V : Type*} (F : V → Option V) (hF : Acyc F) {w u : V} (hw : F w = some u) :
    ¬ Reach F u w := by
  rintro ⟨m, hm⟩
  have hper : (stp F)^[m + 1] (some w) = some w := by
    rw [iterate_succ_apply, stp_some, hw, hm]
  have hall : ∀ t, (stp F)^[t * (m + 1)] (some w) = some w := by
    intro t
    induction t with
    | zero => simp
    | succ t ih => rw [Nat.succ_mul, iterate_add_apply, hper, ih]
  obtain ⟨j, hj⟩ := hF w
  have := iter_after_none F (a := j) (b := j * (m + 1)) (Nat.le_mul_of_pos_right _ (by omega)) hj
  rw [hall] at this
  cases this

theorem no_loop {V : Type*} (F : V → Option V) (hF : Acyc F) (x : V) : F x ≠ some x :=
  fun h => no_return F hF h ⟨0, rfl⟩

theorem no_two_cycle {V : Type*} (F : V → Option V) (hF : Acyc F) {x y : V}
    (hx : F x = some y) (hy : F y = some x) : False :=
  no_return F hF hx ⟨1, by rw [iterate_one, stp_some, hy]⟩

theorem acyc_add {V : Type*} (F : V → Option V) (hF : Acyc F) {r v : V}
    (hv : ¬ Reach F v r) : Acyc (update F r (some v)) := by
  have hvorb : ∀ j, (stp (update F r (some v)))^[j] (some v) = (stp F)^[j] (some v) :=
    fun j => iter_update_eq F r _ _ j (fun i _ hi => hv ⟨i, hi⟩)
  obtain ⟨jv, hjv⟩ := hF v
  intro w
  by_cases hw : Reach F w r
  · obtain ⟨m, hm, hmin⟩ := exists_min_nat hw
    have h1 : (stp (update F r (some v)))^[m] (some w) = some r := by
      rw [iter_update_eq F r _ _ m (fun j hj => hmin j hj)]
      exact hm
    refine ⟨jv + (m + 1), ?_⟩
    rw [iterate_add_apply, iterate_succ_apply', h1, stp_some, update_self, hvorb, hjv]
  · obtain ⟨j, hj⟩ := hF w
    exact ⟨j, by rw [iter_update_eq F r _ _ j (fun i _ hi => hw ⟨i, hi⟩), hj]⟩

theorem acyc_remove {V : Type*} (F : V → Option V) (hF : Acyc F) (w : V) :
    Acyc (update F w none) := by
  intro x
  by_cases hx : Reach F x w
  · obtain ⟨m, hm, hmin⟩ := exists_min_nat hx
    refine ⟨m + 1, ?_⟩
    rw [iterate_succ_apply', iter_update_eq F w none _ m hmin, hm, stp_some, update_self]
  · obtain ⟨j, hj⟩ := hF x
    exact ⟨j, by rw [iter_update_eq F w none _ j (fun i _ hi => hx ⟨i, hi⟩), hj]⟩

theorem not_reach_remove {V : Type*} (F : V → Option V) (hF : Acyc F) {w u : V}
    (hw : F w = some u) : ¬ Reach (update F w none) u w := by
  intro h
  obtain ⟨m, hm, hmin⟩ := exists_min_nat h
  have hG : update (update F w none) w (some u) = F := by
    rw [update_idem, ← hw, update_eq_self]
  apply no_return F hF hw
  refine ⟨m, ?_⟩
  have := iter_update_eq (update F w none) w (some u) (some u) m hmin
  rw [hG] at this
  rw [this, hm]

/-- The roots of a parent map: the vertices with no parent. -/
def roots {V : Type*} [Fintype V] (F : V → Option V) : Finset V :=
  Finset.univ.filter (fun v => F v = none)

/-- Rooted forests on `V` with exactly `k` roots, as parent maps. -/
def forests (V : Type*) [Fintype V] (k : ℕ) : Finset (V → Option V) :=
  Finset.univ.filter (fun F => Acyc F ∧ (roots F).card = k)

theorem mem_roots {V : Type*} [Fintype V] (F : V → Option V) (v : V) :
    v ∈ roots F ↔ F v = none := by
  simp [roots]

theorem mem_forests {V : Type*} [Fintype V] (k : ℕ) (F : V → Option V) :
    F ∈ forests V k ↔ Acyc F ∧ (roots F).card = k := by
  simp [forests]

theorem card_not_reach {V : Type*} [Fintype V] (F : V → Option V) (hF : Acyc F) (k : ℕ)
    (hk : (roots F).card = k + 2) (v : V) :
    ((roots F).filter (fun r => ¬ Reach F v r)).card = k + 1 := by
  have h1 : ((roots F).filter (fun r => Reach F v r)).card = 1 := by
    obtain ⟨r, hr, hreach⟩ := exists_root F hF v
    rw [Finset.card_eq_one]
    refine ⟨r, ?_⟩
    ext x
    simp only [Finset.mem_filter, mem_roots, Finset.mem_singleton]
    constructor
    · rintro ⟨hx, hxr⟩
      exact root_unique F hx hr hxr hreach
    · rintro rfl
      exact ⟨hr, hreach⟩
  have h2 := Finset.card_filter_add_card_filter_not (s := roots F) (fun r => Reach F v r)
  omega

theorem card_nonroots {V : Type*} [Fintype V] (F : V → Option V) :
    (Finset.univ.filter (fun w => F w ≠ none)).card = Fintype.card V - (roots F).card := by
  have h2 := Finset.card_filter_add_card_filter_not (s := (Finset.univ : Finset V))
    (fun w => F w = none)
  rw [Finset.card_univ] at h2
  unfold roots
  simp only [ne_eq]
  omega

theorem forests_rec (V : Type*) [Fintype V] (k : ℕ) :
    (forests V (k + 2)).card * (Fintype.card V * (k + 1)) =
      (forests V (k + 1)).card * (Fintype.card V - (k + 1)) := by
  let A := (forests V (k + 2)).sigma
    (fun F => (Finset.univ : Finset V).sigma (fun v => (roots F).filter (fun r => ¬ Reach F v r)))
  let B := (forests V (k + 1)).sigma (fun F => Finset.univ.filter (fun w => F w ≠ none))
  have hA : A.card = (forests V (k + 2)).card * (Fintype.card V * (k + 1)) := by
    rw [Finset.card_sigma, Finset.sum_congr rfl (g := fun _ => Fintype.card V * (k + 1))]
    · simp
    · intro F hF
      rw [mem_forests] at hF
      rw [Finset.card_sigma, Finset.sum_congr rfl (fun v _ => card_not_reach F hF.1 k hF.2 v)]
      simp
  have hB : B.card = (forests V (k + 1)).card * (Fintype.card V - (k + 1)) := by
    rw [Finset.card_sigma, Finset.sum_congr rfl (g := fun _ => Fintype.card V - (k + 1))]
    · simp
    · intro F hF
      rw [mem_forests] at hF
      rw [card_nonroots, hF.2]
  rw [← hA, ← hB]
  apply Finset.card_nbij'
    (fun a => (⟨update a.1 a.2.2 (some a.2.1), a.2.2⟩ : Σ _ : V → Option V, V))
    (fun b => (⟨update b.1 b.2 none, ⟨(b.1 b.2).getD b.2, b.2⟩⟩ :
      Σ _ : V → Option V, Σ _ : V, V))
  · rintro ⟨F, v, r⟩ ha
    simp only [A, Finset.coe_sigma, Set.mem_sigma_iff, Finset.mem_coe, Finset.mem_univ,
      true_and, Finset.mem_filter, mem_roots, mem_forests] at ha
    obtain ⟨⟨hF, hk⟩, hr, hv⟩ := ha
    simp only [B, Finset.coe_sigma, Set.mem_sigma_iff, Finset.mem_coe, Finset.mem_filter,
      Finset.mem_univ, true_and, mem_forests, update_self]
    refine ⟨⟨acyc_add F hF hv, ?_⟩, by simp⟩
    have : roots (update F r (some v)) = (roots F).erase r := by
      ext x
      simp only [mem_roots, Finset.mem_erase]
      by_cases hx : x = r
      · subst hx; simp
      · simp [hx]
    rw [this, Finset.card_erase_of_mem ((mem_roots _ _).2 hr), hk]
    rfl
  · rintro ⟨F, w⟩ hb
    simp only [B, Finset.coe_sigma, Set.mem_sigma_iff, Finset.mem_coe, Finset.mem_filter,
      Finset.mem_univ, true_and, mem_forests] at hb
    obtain ⟨⟨hF, hk⟩, hw⟩ := hb
    obtain ⟨u, hu⟩ := Option.ne_none_iff_exists'.mp hw
    simp only [A, Finset.coe_sigma, Set.mem_sigma_iff, Finset.mem_coe, Finset.mem_univ,
      true_and, Finset.mem_filter, mem_roots, mem_forests, update_self, hu, Option.getD_some]
    refine ⟨⟨acyc_remove F hF w, ?_⟩, not_reach_remove F hF hu⟩
    have hnot : w ∉ roots F := by rw [mem_roots, hu]; simp
    have : roots (update F w none) = insert w (roots F) := by
      ext x
      simp only [mem_roots, Finset.mem_insert]
      by_cases hx : x = w
      · subst hx; simp
      · simp [hx]
    rw [this, Finset.card_insert_of_notMem hnot, hk]
  · rintro ⟨F, v, r⟩ ha
    simp only [A, Finset.coe_sigma, Set.mem_sigma_iff, Finset.mem_coe, Finset.mem_univ,
      true_and, Finset.mem_filter, mem_roots, mem_forests] at ha
    obtain ⟨_, hr, _⟩ := ha
    have e : update (update F r (some v)) r none = F := by
      rw [update_idem, ← hr, update_eq_self]
    simp only [update_self, Option.getD_some, e]
  · rintro ⟨F, w⟩ hb
    simp only [B, Finset.coe_sigma, Set.mem_sigma_iff, Finset.mem_coe, Finset.mem_filter,
      Finset.mem_univ, true_and, mem_forests] at hb
    obtain ⟨_, hw⟩ := hb
    obtain ⟨u, hu⟩ := Option.ne_none_iff_exists'.mp hw
    have e : update (update F w none) w (some u) = F := by
      rw [update_idem, ← hu, update_eq_self]
    simp only [hu, Option.getD_some, e]

theorem forests_top (V : Type*) [Fintype V] : (forests V (Fintype.card V)).card = 1 := by
  rw [Finset.card_eq_one]
  refine ⟨fun _ => none, ?_⟩
  ext F
  simp only [mem_forests, Finset.mem_singleton]
  constructor
  · rintro ⟨_, hc⟩
    have : roots F = Finset.univ := Finset.eq_univ_of_card _ hc
    funext v
    have hv : v ∈ roots F := by rw [this]; exact Finset.mem_univ v
    exact (mem_roots _ _).1 hv
  · rintro rfl
    refine ⟨fun v => ⟨1, rfl⟩, ?_⟩
    have : roots (fun _ : V => (none : Option V)) = Finset.univ := by
      ext v; simp [mem_roots]
    rw [this, Finset.card_univ]

theorem forests_card (V : Type*) [Fintype V] (j : ℕ) (hj : j + 1 ≤ Fintype.card V) :
    (forests V (Fintype.card V - j)).card =
      (Fintype.card V - 1).choose j * Fintype.card V ^ j := by
  induction j with
  | zero => simp [forests_top]
  | succ j ih =>
    set n := Fintype.card V with hn
    obtain ⟨k, hk⟩ : ∃ k, n = k + j + 2 := ⟨n - j - 2, by omega⟩
    have ih' := ih (by omega)
    have h1 : n - j = k + 2 := by omega
    have h2 : n - (j + 1) = k + 1 := by omega
    rw [h1] at ih'
    rw [h2]
    have hrec := forests_rec V k
    rw [← hn, ih', show n - (k + 1) = j + 1 by omega] at hrec
    have hch := Nat.choose_succ_right_eq (n - 1) j
    rw [show n - 1 - j = k + 1 by omega] at hch
    apply Nat.eq_of_mul_eq_mul_right (show 0 < j + 1 by omega)
    rw [← hrec]
    calc (n - 1).choose j * n ^ j * (n * (k + 1))
        = (n - 1).choose j * (k + 1) * n ^ (j + 1) := by ring
      _ = (n - 1).choose (j + 1) * (j + 1) * n ^ (j + 1) := by rw [hch]
      _ = (n - 1).choose (j + 1) * n ^ (j + 1) * (j + 1) := by ring

theorem forests_one (V : Type*) [Fintype V] [Nonempty V] :
    (forests V 1).card = Fintype.card V ^ (Fintype.card V - 1) := by
  have hpos := Fintype.card_pos (α := V)
  have := forests_card V (Fintype.card V - 1) (by omega)
  rw [show Fintype.card V - (Fintype.card V - 1) = 1 by omega, Nat.choose_self, one_mul] at this
  exact this

/-- The graph of a parent map: join each vertex to its parent. -/
def graphOf {V : Type*} (F : V → Option V) : SimpleGraph V :=
  SimpleGraph.fromRel (fun x y => F x = some y)

theorem graphOf_adj {V : Type*} (F : V → Option V) (x y : V) :
    (graphOf F).Adj x y ↔ x ≠ y ∧ (F x = some y ∨ F y = some x) :=
  fromRel_adj _ _ _

theorem graphOf_reach {V : Type*} (F : V → Option V) (hF : Acyc F) (v : V) :
    ∀ m u, (stp F)^[m] (some v) = some u → (graphOf F).Reachable v u := by
  intro m
  induction m with
  | zero =>
    intro u h
    obtain rfl : v = u := Option.some_injective _ h
    rfl
  | succ m ih =>
    intro u h
    rw [iterate_succ_apply'] at h
    cases hx : (stp F)^[m] (some v) with
    | none => rw [hx] at h; cases h
    | some x =>
      rw [hx, stp_some] at h
      have hadj : (graphOf F).Adj x u := by
        rw [graphOf_adj]
        exact ⟨by rintro rfl; exact no_loop F hF x h, Or.inl h⟩
      exact (ih x hx).trans hadj.reachable

theorem graphOf_connected {V : Type*} (F : V → Option V) (hF : Acyc F) {r : V}
    (hr : ∀ x, F x = none ↔ x = r) : (graphOf F).Connected := by
  have hall : ∀ v, (graphOf F).Reachable v r := by
    intro v
    obtain ⟨r', hr', m, hm⟩ := exists_root F hF v
    obtain rfl := (hr r').1 hr'
    exact graphOf_reach F hF v m _ hm
  have : Nonempty V := ⟨r⟩
  exact ⟨fun a b => (hall a).trans (hall b).symm⟩

theorem roots_iff {V : Type*} [Fintype V] (F : V → Option V) (hc : (roots F).card = 1) {r : V}
    (hr : F r = none) : ∀ x, F x = none ↔ x = r := by
  obtain ⟨a, ha⟩ := Finset.card_eq_one.mp hc
  have : r ∈ roots F := (mem_roots _ _).2 hr
  rw [ha, Finset.mem_singleton] at this
  subst this
  intro x
  rw [← mem_roots, ha, Finset.mem_singleton]

theorem roots_card_one {V : Type*} [Fintype V] (F : V → Option V) {r : V}
    (hr : ∀ x, F x = none ↔ x = r) : (roots F).card = 1 := by
  rw [Finset.card_eq_one]
  exact ⟨r, by ext x; rw [mem_roots, hr, Finset.mem_singleton]⟩

theorem graphOf_isTree {V : Type*} [Fintype V] (F : V → Option V) (hF : Acyc F) {r : V}
    (hr : ∀ x, F x = none ↔ x = r) : (graphOf F).IsTree := by
  have hc := graphOf_connected F hF hr
  rw [isTree_iff_connected_and_card]
  refine ⟨hc, le_antisymm ?_ hc.card_vert_le_card_edgeSet_add_one⟩
  rw [Nat.card_eq_fintype_card, Nat.card_eq_fintype_card, ← edgeFinset_card]
  have hsub : (graphOf F).edgeFinset ⊆ (Finset.univ.filter (fun v => F v ≠ none)).image
      (fun v => s(v, (F v).getD v)) := by
    intro e he
    induction e using Sym2.ind with
    | h x y =>
      rw [mem_edgeFinset, mem_edgeSet, graphOf_adj] at he
      rw [Finset.mem_image]
      rcases he.2 with h | h
      · exact ⟨x, by simp [h], by simp [h]⟩
      · exact ⟨y, by simp [h], by simp [h, Sym2.eq_swap]⟩
  have h1 := (Finset.card_le_card hsub).trans Finset.card_image_le
  rw [card_nonroots, roots_card_one F hr] at h1
  have hpos := Fintype.card_pos_iff.mpr ⟨r⟩
  omega

theorem no_invariant {V : Type*} (F : V → Option V) (hF : Acyc F) (D : V → Prop)
    (hD : ∀ x, D x → ∃ y, D y ∧ F x = some y) (x : V) (hx : D x) : False := by
  have : ∀ m, ∃ y, D y ∧ (stp F)^[m] (some x) = some y := by
    intro m
    induction m with
    | zero => exact ⟨x, hx, rfl⟩
    | succ m ih =>
      obtain ⟨y, hy, he⟩ := ih
      obtain ⟨z, hz, hyz⟩ := hD y hy
      exact ⟨z, hz, by rw [iterate_succ_apply', he, stp_some, hyz]⟩
  obtain ⟨m, hm⟩ := hF x
  obtain ⟨y, _, hy⟩ := this m
  rw [hm] at hy
  cases hy

theorem eq_of_graphOf_eq {V : Type*} (F G : V → Option V) (hF : Acyc F) {r : V}
    (hFr : ∀ x, F x = none ↔ x = r) (hGr : ∀ x, G x = none ↔ x = r)
    (h : graphOf F = graphOf G) : F = G := by
  funext x
  by_contra hne
  apply no_invariant F hF (fun x => F x ≠ G x) _ x hne
  intro x hx
  cases hFx : F x with
  | none => exact absurd (by rw [hFx, (hGr x).2 ((hFr x).1 hFx)]) hx
  | some y =>
    refine ⟨y, ?_, rfl⟩
    have hadj : (graphOf G).Adj x y := by
      rw [← h, graphOf_adj]
      exact ⟨by rintro rfl; exact no_loop F hF x hFx, Or.inl hFx⟩
    rw [graphOf_adj] at hadj
    rcases hadj.2 with h' | h'
    · exact absurd (hFx.trans h'.symm) hx
    · intro hFy
      exact no_two_cycle F hF hFx (hFy.trans h')

theorem exists_closer {V : Type*} (T : SimpleGraph V) (hT : T.Connected) {v r : V}
    (h : v ≠ r) : ∃ u, T.Adj v u ∧ T.dist u r < T.dist v r := by
  obtain ⟨p, hp⟩ := hT.exists_walk_length_eq_dist v r
  cases p with
  | nil => exact absurd rfl h
  | cons hadj q =>
    refine ⟨_, hadj, ?_⟩
    have := SimpleGraph.dist_le q
    rw [Walk.length_cons] at hp
    omega

theorem exists_parent {V : Type*} [Fintype V] (T : SimpleGraph V) (hT : T.IsTree) (r : V) :
    ∃ F : V → Option V, Acyc F ∧ (∀ x, F x = none ↔ x = r) ∧ graphOf F = T := by
  let F : V → Option V := fun v =>
    if h : v = r then none else some (Classical.choose (exists_closer T hT.connected h))
  have hFr : ∀ x, F x = none ↔ x = r := by
    intro x
    by_cases h : x = r <;> simp [F, h]
  have hFv : ∀ v (h : v ≠ r), ∃ u, F v = some u ∧ T.Adj v u ∧ T.dist u r < T.dist v r := by
    intro v h
    exact ⟨_, by simp [F, h], Classical.choose_spec (exists_closer T hT.connected h)⟩
  have hac : Acyc F := by
    have key : ∀ d v, T.dist v r = d → ∃ m, (stp F)^[m] (some v) = none := by
      intro d
      induction d using Nat.strong_induction_on with
      | _ d ih =>
        intro v hv
        by_cases h : v = r
        · exact ⟨1, by rw [iterate_one, stp_some]; exact (hFr v).2 h⟩
        · obtain ⟨u, hu, -, hd⟩ := hFv v h
          obtain ⟨m, hm⟩ := ih _ (hv ▸ hd) u rfl
          exact ⟨m + 1, by rw [iterate_succ_apply, stp_some, hu, hm]⟩
    exact fun v => key _ v rfl
  have hle : graphOf F ≤ T := by
    intro x y hxy
    rw [graphOf_adj] at hxy
    rcases hxy.2 with h | h
    · have hx : x ≠ r := fun hx => by rw [(hFr x).2 hx] at h; cases h
      obtain ⟨u, hu, hadj, -⟩ := hFv x hx
      obtain rfl : u = y := Option.some_injective _ (hu.symm.trans h)
      exact hadj
    · have hy : y ≠ r := fun hy => by rw [(hFr y).2 hy] at h; cases h
      obtain ⟨u, hu, hadj, -⟩ := hFv y hy
      obtain rfl : u = x := Option.some_injective _ (hu.symm.trans h)
      exact hadj.symm
  refine ⟨F, hac, hFr, le_antisymm hle ?_⟩
  exact (isTree_iff_minimal_connected.mp hT).2 (graphOf_connected F hac hFr) hle

theorem trees_mul_card {V : Type*} [Fintype V] [Nonempty V] :
    Nat.card {T : SimpleGraph V // T.IsTree} * Fintype.card V =
      Fintype.card V ^ (Fintype.card V - 1) := by
  have hP : ((forests V 1).sigma (fun F => roots F)).card = (forests V 1).card := by
    rw [Finset.card_sigma, Finset.sum_congr rfl (g := fun _ => 1)]
    · simp
    · intro F hF
      exact ((mem_forests _ _).1 hF).2
  have hQ : ((Finset.univ.filter (fun T : SimpleGraph V => T.IsTree)) ×ˢ
      (Finset.univ : Finset V)).card = Nat.card {T : SimpleGraph V // T.IsTree} *
        Fintype.card V := by
    rw [Finset.card_product, Finset.card_univ, Nat.card_eq_fintype_card, Fintype.card_subtype]
  rw [← hQ, ← forests_one V, ← hP]
  symm
  apply Finset.card_bij (fun a _ => (graphOf a.1, a.2))
  · rintro ⟨F, r⟩ ha
    simp only [Finset.mem_sigma, mem_forests, mem_roots] at ha
    obtain ⟨⟨hF, hc⟩, hr⟩ := ha
    simp only [Finset.mem_product, Finset.mem_filter, Finset.mem_univ, true_and, and_true]
    exact graphOf_isTree F hF (roots_iff F hc hr)
  · rintro ⟨F, r⟩ ha ⟨G, r'⟩ hb he
    simp only [Prod.mk.injEq] at he
    obtain ⟨he, rfl⟩ := he
    simp only [Finset.mem_sigma, mem_forests, mem_roots] at ha hb
    have := eq_of_graphOf_eq F G ha.1.1 (roots_iff F ha.1.2 ha.2) (roots_iff G hb.1.2 hb.2) he
    subst this
    rfl
  · rintro ⟨T, r⟩ hb
    simp only [Finset.mem_product, Finset.mem_filter, Finset.mem_univ, true_and,
      and_true] at hb
    obtain ⟨F, hF, hFr, hFT⟩ := exists_parent T hb r
    refine ⟨⟨F, r⟩, ?_, by simp [hFT]⟩
    simp only [Finset.mem_sigma, mem_forests, mem_roots]
    exact ⟨⟨hF, roots_card_one F hFr⟩, (hFr r).2 rfl⟩

end

#print axioms stp_some
#print axioms iter_none
#print axioms exists_min_nat
#print axioms iter_after_none
#print axioms exists_root
#print axioms root_unique_aux
#print axioms root_unique
#print axioms iter_update_eq
#print axioms no_return
#print axioms no_loop
#print axioms no_two_cycle
#print axioms acyc_add
#print axioms acyc_remove
#print axioms not_reach_remove
#print axioms mem_roots
#print axioms mem_forests
#print axioms card_not_reach
#print axioms card_nonroots
#print axioms forests_rec
#print axioms forests_top
#print axioms forests_card
#print axioms forests_one
#print axioms graphOf_adj
#print axioms graphOf_reach
#print axioms graphOf_connected
#print axioms roots_iff
#print axioms roots_card_one
#print axioms graphOf_isTree
#print axioms no_invariant
#print axioms eq_of_graphOf_eq
#print axioms exists_closer
#print axioms exists_parent
#print axioms trees_mul_card


open SimpleGraph

/-- Cayley's formula. Take `n` named places (a finite type `V` with `n` elements) where every pair
can be joined (the complete map `⊤`), and suppose that map is in one piece. A spanning tree of it is
a choice of roads (a simple graph `T` on all of `V`, every road one of the map's) that reaches every
place and holds no loop (`T.IsTree`). Counting labelled layouts, not shapes, there are exactly
`n ^ (n - 2)` of them. -/
theorem card_spanning_trees_complete_eq_pow {V : Type*} [Fintype V]
    (hconn : (⊤ : SimpleGraph V).Connected) :
    Nat.card {T : SimpleGraph V // T ≤ ⊤ ∧ T.IsTree} =
      Fintype.card V ^ (Fintype.card V - 2) := by
  have : Nonempty V := hconn.nonempty
  have h := trees_mul_card (V := V)
  have e : Nat.card {T : SimpleGraph V // T ≤ ⊤ ∧ T.IsTree} =
      Nat.card {T : SimpleGraph V // T.IsTree} :=
    Nat.card_congr (Equiv.subtypeEquivRight (fun T => by simp))
  rw [e]
  have hpos := Fintype.card_pos (α := V)
  rcases Nat.lt_or_ge (Fintype.card V) 2 with h2 | h2
  · have h1 : Fintype.card V = 1 := by omega
    rw [h1] at h ⊢
    simpa using h
  · apply Nat.eq_of_mul_eq_mul_right hpos
    rw [h, ← pow_succ]
    congr 1
    omega

/-- Step 0: a map has a spanning tree exactly when it is in one piece. Remove one road from each
loop until none is left; the other way round, a spanning tree already joins every place. So a map
in pieces has no spanning tree at all. -/
theorem connected_iff_exists_spanning_tree {V : Type*} [Fintype V] (G : SimpleGraph V) :
    G.Connected ↔ ∃ T : SimpleGraph V, T ≤ G ∧ T.IsTree := by
  exact ⟨fun h => h.exists_isTree_le, fun ⟨T, hle, hT⟩ => hT.connected.mono hle⟩

/-- A spanning tree always holds one road fewer than there are places: a loop-free layout reaching
all `n` places has exactly `n - 1` roads. -/
theorem spanning_tree_card_edges {V : Type*} [Fintype V] [DecidableEq V]
    (T : SimpleGraph V) [DecidableRel T.Adj] (hT : T.IsTree) :
    T.edgeFinset.card = Fintype.card V - 1 := by
  have := hT.card_edgeFinset
  omega

/-! The card's villages: Ayle, Brook, Crag, Dale, Ember are `0` to `4`. -/

/-- The map on `Fin n` whose roads are the pairs in the list `roads`. -/
def plan {n : ℕ} (roads : List (Fin n × Fin n)) : SimpleGraph (Fin n) where
  Adj x y := x ≠ y ∧ ((x, y) ∈ roads ∨ (y, x) ∈ roads)
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.symm⟩⟩
  loopless := ⟨fun _ h => h.1 rfl⟩

instance {n : ℕ} (roads : List (Fin n × Fin n)) : DecidableRel (plan roads).Adj :=
  fun _ _ => inferInstanceAs (Decidable (_ ∧ _))

/-- The six costed roads between four villages: the complete map `K 4`. -/
def k4 : List (Fin 4 × Fin 4) := [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]

/-- The ten costed roads between five villages: the complete map `K 5`. -/
def k5 : List (Fin 5 × Fin 5) :=
  [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]

/-- The sparse five-village map: Ayle-Brook, Ayle-Crag, Brook-Crag, Brook-Dale, Crag-Dale,
Dale-Ember. -/
def sparse : List (Fin 5 × Fin 5) := [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (3, 4)]

/-- The card's test for a layout: `n - 1` roads that reach every village. -/
def layouts {n : ℕ} (roads : List (Fin n × Fin n)) : List (List (Fin n × Fin n)) :=
  roads.sublists.filter (fun s => s.length = n - 1 ∧ (plan s).Connected)

-- Cayley: 4 × 4 = 16 for four villages and 5 × 5 × 5 = 125 for five.
example : 4 ^ (4 - 2) = 16 ∧ 5 ^ (5 - 2) = 125 := by norm_num
-- Four villages: 20 choices of 3 roads from 6, and 16 of them pass.
example : (k4.sublists.filter (fun s => s.length = 3)).length = 20 := by decide
example : (layouts k4).length = 16 := by decide
-- Of the 16 plans, 4 are stars (a village meeting all 3 roads) and 12 are lines.
example : ((layouts k4).filter (fun s => ∃ v : Fin 4, ((plan s).neighborFinset v).card = 3)).length
    = 4 := by decide
-- The line Ayle-Brook-Crag-Dale is one of the plans, and so is the star centred on Ayle.
example : (plan [(0, 1), (1, 2), (2, 3)] : SimpleGraph (Fin 4)).Connected := by decide
example : (plan [(0, 1), (0, 2), (0, 3)] : SimpleGraph (Fin 4)).Connected := by decide
-- A triangle strands a village.
example : ¬ (plan [(0, 1), (0, 2), (1, 2)] : SimpleGraph (Fin 4)).Connected := by decide
-- Five villages, 10 roads: 210 choices of 4, and 125 of them pass.
example : Nat.choose 10 4 = 210 := by decide
example : (layouts k5).length = 125 := by decide +kernel
-- The sparse map, 6 of the 10 roads, allows 8 layouts.
example : (layouts sparse).length = 8 := by decide
-- The flood's layout Ayle-Brook, Ayle-Crag, Brook-Dale, Dale-Ember reaches all five.
example : (plan [(0, 1), (0, 2), (1, 3), (3, 4)] : SimpleGraph (Fin 5)).Connected := by decide
-- Kirchhoff's table for four villages, one row and column cut, has determinant 16.
example : Matrix.det !![(3 : ℤ), -1, -1; -1, 3, -1; -1, -1, 3] = 16 := by
  norm_num [Matrix.det_fin_three]

#print axioms card_spanning_trees_complete_eq_pow
#print axioms connected_iff_exists_spanning_tree
#print axioms spanning_tree_card_edges

end SpanningTreesAndCayleysFormula
