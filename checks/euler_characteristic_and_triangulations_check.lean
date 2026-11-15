-- Euler characteristic: vertices minus edges plus triangles does not change when a triangle or an edge is cut, joining two closed surfaces costs 2, and on a closed surface six minus each degree adds up to six times chi.
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Finset.Card
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Group.Int
import Mathlib.Logic.Relation
import Mathlib.Tactic.NormNum
import Mathlib.Combinatorics.Enumerative.DoubleCounting

/-! A triangulation is stored as on the card: a finite set `K` of triangles, each triangle the
finite set of its corner labels, with the gluing already done (a corner shared after gluing
has one label). Mathlib has no abstract triangulated surface, so the counts are defined here.

* `vertices K`: every corner of every triangle (`V`).
* `edges K`: every two-corner set inside a triangle (`E`).
* `K.card`: the triangles (`F`).
* `eulerChar K = V - E + F`, the Euler characteristic chi, as an integer.
* `degree K v`: the number of edges that meet at `v`.

Bending (homeomorphism invariance) needs Radó's theorem and the common-refinement theorem,
which the card states with a source and does not prove; Mathlib has neither, so this file
states the parts the card proves: the two basic cuts, the connected-sum count and the
degree sum. -/

namespace EulerTriangulation

open Finset

variable {α : Type*} [DecidableEq α]

/-- The corners of a triangulation `K`: `V`. -/
def vertices (K : Finset (Finset α)) : Finset α := K.biUnion id

/-- The edges of a triangulation `K`: every two-corner set inside one of its triangles, counted once. -/
def edges (K : Finset (Finset α)) : Finset (Finset α) := K.biUnion (fun t => t.powersetCard 2)

/-- The Euler characteristic `chi = V - E + F`. -/
def eulerChar (K : Finset (Finset α)) : ℤ :=
  ((vertices K).card : ℤ) - (edges K).card + K.card

/-- The degree of a corner `v`: the number of edges of `K` that meet at `v`. -/
def degree (K : Finset (Finset α)) (v : α) : ℕ := ((edges K).filter (fun e => v ∈ e)).card

/-- A closed surface of triangles, as Step 6 of the card uses it: every piece is a triangle
(three corners) and every edge borders exactly two triangles. -/
def IsClosedTriangleSurface (K : Finset (Finset α)) : Prop :=
  (∀ t ∈ K, t.card = 3) ∧ ∀ e ∈ edges K, (K.filter (fun t => e ⊆ t)).card = 2

/-- The two basic cuts of Step 1, each with a new corner `w` not already in `K`.
* Face cut: a new corner inside the triangle `{a, b, c}`, joined to its three corners.
* Edge cut: a new corner in the middle of the edge `{a, b}`, which borders exactly the two
  triangles `{a, b, c}` and `{a, b, d}`, joined to their far corners `c` and `d`. -/
inductive BasicCut : Finset (Finset α) → Finset (Finset α) → Prop
  | face (K : Finset (Finset α)) (a b c w : α) (hab : a ≠ b) (hac : a ≠ c) (hbc : b ≠ c)
      (ht : ({a, b, c} : Finset α) ∈ K) (hw : w ∉ vertices K) :
      BasicCut K ((K.erase {a, b, c}) ∪ {{a, b, w}, {a, c, w}, {b, c, w}})
  | edge (K : Finset (Finset α)) (a b c d w : α) (hab : a ≠ b) (hac : a ≠ c) (hbc : b ≠ c)
      (had : a ≠ d) (hbd : b ≠ d) (hcd : c ≠ d)
      (hc : ({a, b, c} : Finset α) ∈ K) (hd : ({a, b, d} : Finset α) ∈ K)
      (honly : ∀ s ∈ K, a ∈ s → b ∈ s → s = {a, b, c} ∨ s = {a, b, d})
      (hw : w ∉ vertices K) :
      BasicCut K (((K.erase {a, b, c}).erase {a, b, d}) ∪ {{a, c, w}, {b, c, w}, {a, d, w}, {b, d, w}})

theorem mem_vertices {K : Finset (Finset α)} {v : α} : v ∈ vertices K ↔ ∃ t ∈ K, v ∈ t := by
  simp [vertices]

theorem mem_edges {K : Finset (Finset α)} {e : Finset α} :
    e ∈ edges K ↔ ∃ t ∈ K, e ⊆ t ∧ e.card = 2 := by
  simp [edges, mem_powersetCard]

theorem vertices_union (A B : Finset (Finset α)) :
    vertices (A ∪ B) = vertices A ∪ vertices B := by
  ext v; simp only [mem_vertices, mem_union]; grind

theorem edges_union (A B : Finset (Finset α)) : edges (A ∪ B) = edges A ∪ edges B := by
  ext e; simp only [mem_edges, mem_union]; grind

theorem vertices_insert (t : Finset α) (A : Finset (Finset α)) :
    vertices (insert t A) = t ∪ vertices A := by
  simp [vertices, biUnion_insert]

theorem edges_insert (t : Finset α) (A : Finset (Finset α)) :
    edges (insert t A) = t.powersetCard 2 ∪ edges A := by
  simp [edges, biUnion_insert]

theorem vertices_singleton (t : Finset α) : vertices ({t} : Finset (Finset α)) = t := by
  simp [vertices]

theorem edges_singleton (t : Finset α) : edges ({t} : Finset (Finset α)) = t.powersetCard 2 := by
  simp [edges]

theorem edge_subset_vertices {K : Finset (Finset α)} {e : Finset α} (he : e ∈ edges K) :
    e ⊆ vertices K := by
  obtain ⟨t, ht, het, -⟩ := mem_edges.mp he
  intro v hv
  exact mem_vertices.mpr ⟨t, ht, het hv⟩

theorem pair_mem_of_eq {x y p q : α} (h : ({x, y} : Finset α) = {p, q}) :
    (x = p ∨ x = q) ∧ (y = p ∨ y = q) := by
  have hx : x ∈ ({p, q} : Finset α) := h ▸ (by simp)
  have hy : y ∈ ({p, q} : Finset α) := h ▸ (by simp)
  simp only [mem_insert, mem_singleton] at hx hy
  exact ⟨hx, hy⟩

theorem triple_mem_of_eq {x y z p q r : α} (h : ({x, y, z} : Finset α) = {p, q, r}) :
    (x = p ∨ x = q ∨ x = r) ∧ (y = p ∨ y = q ∨ y = r) ∧ (z = p ∨ z = q ∨ z = r) := by
  have hx : x ∈ ({p, q, r} : Finset α) := h ▸ (by simp)
  have hy : y ∈ ({p, q, r} : Finset α) := h ▸ (by simp)
  have hz : z ∈ ({p, q, r} : Finset α) := h ▸ (by simp)
  simp only [mem_insert, mem_singleton] at hx hy hz
  exact ⟨hx, hy, hz⟩

theorem powersetCard_two_three {x y z : α} (hxy : x ≠ y) (hxz : x ≠ z) (hyz : y ≠ z) :
    ({x, y, z} : Finset α).powersetCard 2 = {{x, y}, {x, z}, {y, z}} := by
  ext e
  simp only [mem_powersetCard, mem_insert, mem_singleton]
  constructor
  · rintro ⟨hs, hc⟩
    obtain ⟨p, q, hpq, rfl⟩ := card_eq_two.mp hc
    have hp : p ∈ ({x, y, z} : Finset α) := hs (by simp)
    have hq : q ∈ ({x, y, z} : Finset α) := hs (by simp)
    simp only [mem_insert, mem_singleton] at hp hq
    rcases hp with rfl | rfl | rfl <;> rcases hq with rfl | rfl | rfl <;>
      simp_all [pair_comm]
  · rintro (rfl | rfl | rfl) <;> refine ⟨?_, card_pair_eq_two_iff.mpr ‹_›⟩ <;>
      intro v hv <;> simp only [mem_insert, mem_singleton] at hv ⊢ <;> tauto

theorem not_mem_of_not_mem_vertices {K : Finset (Finset α)} {w : α} (hw : w ∉ vertices K)
    {s : Finset α} (hs : w ∈ s) : s ∉ K :=
  fun h => hw (mem_vertices.mpr ⟨s, h, hs⟩)

theorem not_mem_edges_of_not_mem_vertices {K : Finset (Finset α)} {w : α}
    (hw : w ∉ vertices K) {s : Finset α} (hs : w ∈ s) : s ∉ edges K :=
  fun h => hw (edge_subset_vertices h hs)

theorem ne_of_not_mem_vertices {K : Finset (Finset α)} {w v : α} {t : Finset α}
    (hw : w ∉ vertices K) (ht : t ∈ K) (hv : v ∈ t) : v ≠ w := by
  rintro rfl
  exact hw (mem_vertices.mpr ⟨t, ht, hv⟩)

theorem eulerChar_face (K : Finset (Finset α)) (a b c w : α) (hab : a ≠ b) (hac : a ≠ c)
    (hbc : b ≠ c) (ht : ({a, b, c} : Finset α) ∈ K) (hw : w ∉ vertices K) :
    eulerChar ((K.erase {a, b, c}) ∪ {{a, b, w}, {a, c, w}, {b, c, w}}) = eulerChar K := by
  have haw : a ≠ w := ne_of_not_mem_vertices hw ht (by simp)
  have hbw : b ≠ w := ne_of_not_mem_vertices hw ht (by simp)
  have hcw : c ≠ w := ne_of_not_mem_vertices hw ht (by simp)
  set R := K.erase {a, b, c} with hR
  have hK : K = insert {a, b, c} R := (insert_erase ht).symm
  have hRw : w ∉ vertices R := by
    rw [hK, vertices_insert, mem_union, not_or] at hw; exact hw.2
  have hV : vertices (R ∪ {{a, b, w}, {a, c, w}, {b, c, w}}) = insert w (vertices K) := by
    rw [hK]; ext v
    simp only [vertices_union, vertices_insert, vertices_singleton, mem_union, mem_insert,
      mem_singleton]
    tauto
  have hE : edges (R ∪ {{a, b, w}, {a, c, w}, {b, c, w}}) =
      insert {a, w} (insert {b, w} (insert {c, w} (edges K))) := by
    rw [hK]; ext e
    simp only [edges_union, edges_insert, edges_singleton, powersetCard_two_three hab haw hbw,
      powersetCard_two_three hac haw hcw, powersetCard_two_three hbc hbw hcw,
      powersetCard_two_three hab hac hbc, mem_union, mem_insert, mem_singleton]
    tauto
  have hF : R ∪ {{a, b, w}, {a, c, w}, {b, c, w}} =
      insert {a, b, w} (insert {a, c, w} (insert {b, c, w} R)) := by
    ext s; simp only [mem_union, mem_insert, mem_singleton]; tauto
  have hEK : ∀ s : Finset α, w ∈ s → s ∉ edges K := fun s hs =>
    not_mem_edges_of_not_mem_vertices hw hs
  have hVc : (vertices (R ∪ {{a, b, w}, {a, c, w}, {b, c, w}})).card = (vertices K).card + 1 := by
    rw [hV, card_insert_of_notMem hw]
  have hEc : (edges (R ∪ {{a, b, w}, {a, c, w}, {b, c, w}})).card = (edges K).card + 3 := by
    rw [hE, card_insert_of_notMem, card_insert_of_notMem, card_insert_of_notMem (hEK _ (by simp))]
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, hEK _ (by simp)⟩
      have := pair_mem_of_eq h; grind
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, fun h => ?_, hEK _ (by simp)⟩
      · have := pair_mem_of_eq h; grind
      · have := pair_mem_of_eq h; grind
  have hFc : (R ∪ {{a, b, w}, {a, c, w}, {b, c, w}}).card = K.card + 2 := by
    have hRK : K.card = R.card + 1 := by rw [hK, card_insert_of_notMem (by simp [hR])]
    have hRn : ∀ s : Finset α, w ∈ s → s ∉ R := fun s hs => not_mem_of_not_mem_vertices hRw hs
    rw [hF, card_insert_of_notMem, card_insert_of_notMem, card_insert_of_notMem (hRn _ (by simp)),
      hRK]
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, hRn _ (by simp)⟩
      have := triple_mem_of_eq h; grind
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, fun h => ?_, hRn _ (by simp)⟩
      · have := triple_mem_of_eq h; grind
      · have := triple_mem_of_eq h; grind
  unfold eulerChar
  rw [hVc, hEc, hFc]
  push_cast; omega

set_option linter.unusedSimpArgs false in
theorem eulerChar_edge (K : Finset (Finset α)) (a b c d w : α) (hab : a ≠ b) (hac : a ≠ c)
    (hbc : b ≠ c) (had : a ≠ d) (hbd : b ≠ d) (hcd : c ≠ d)
    (hc : ({a, b, c} : Finset α) ∈ K) (hd : ({a, b, d} : Finset α) ∈ K)
    (honly : ∀ s ∈ K, a ∈ s → b ∈ s → s = {a, b, c} ∨ s = {a, b, d})
    (hw : w ∉ vertices K) :
    eulerChar (((K.erase {a, b, c}).erase {a, b, d}) ∪
      {{a, c, w}, {b, c, w}, {a, d, w}, {b, d, w}}) = eulerChar K := by
  have haw : a ≠ w := ne_of_not_mem_vertices hw hc (by simp)
  have hbw : b ≠ w := ne_of_not_mem_vertices hw hc (by simp)
  have hcw : c ≠ w := ne_of_not_mem_vertices hw hc (by simp)
  have hdw : d ≠ w := ne_of_not_mem_vertices hw hd (by simp)
  have hcd' : ({a, b, d} : Finset α) ≠ {a, b, c} := by
    intro h; have := triple_mem_of_eq h
    simp [hab, hac, hbc, had, hbd, hcd, haw, hbw, hcw, hdw, hab.symm, hac.symm, hbc.symm, had.symm, hbd.symm, hcd.symm, haw.symm, hbw.symm, hcw.symm, hdw.symm] at this
  set R := (K.erase {a, b, c}).erase {a, b, d} with hR
  have hK1 : K.erase {a, b, c} = insert {a, b, d} R :=
    (insert_erase (mem_erase.mpr ⟨hcd', hd⟩)).symm
  have hK : K = insert {a, b, c} (insert {a, b, d} R) := by
    rw [← hK1]; exact (insert_erase hc).symm
  have hRw : w ∉ vertices R := by
    rw [hK, vertices_insert, vertices_insert, mem_union, mem_union, not_or, not_or] at hw
    exact hw.2.2
  have hRab : ({a, b} : Finset α) ∉ edges R := by
    intro h
    obtain ⟨s, hs, hsub, -⟩ := mem_edges.mp h
    have hsK : s ∈ K := mem_of_mem_erase (mem_of_mem_erase hs)
    rcases honly s hsK (hsub (by simp)) (hsub (by simp)) with rfl | rfl
    · simp [hR] at hs
    · simp [hR] at hs
  set N : Finset (Finset α) := {{a, c, w}, {b, c, w}, {a, d, w}, {b, d, w}} with hN
  have hV : vertices (R ∪ N) = insert w (vertices K) := by
    rw [hK]; ext v
    simp only [hN, vertices_union, vertices_insert, vertices_singleton, mem_union, mem_insert,
      mem_singleton]
    tauto
  have hE : insert {a, b} (edges (R ∪ N)) =
      insert {a, w} (insert {b, w} (insert {c, w} (insert {d, w} (edges K)))) := by
    rw [hK]; ext e
    simp only [hN, edges_union, edges_insert, edges_singleton, powersetCard_two_three hac haw hcw,
      powersetCard_two_three hbc hbw hcw, powersetCard_two_three had haw hdw,
      powersetCard_two_three hbd hbw hdw, powersetCard_two_three hab hac hbc,
      powersetCard_two_three hab had hbd, mem_union, mem_insert, mem_singleton]
    grind
  have hEab : ({a, b} : Finset α) ∉ edges (R ∪ N) := by
    simp only [hN, edges_union, edges_insert, edges_singleton, powersetCard_two_three hac haw hcw,
      powersetCard_two_three hbc hbw hcw, powersetCard_two_three had haw hdw,
      powersetCard_two_three hbd hbw hdw, mem_union, mem_insert, mem_singleton, not_or]
    refine ⟨hRab, ?_⟩
    refine ⟨⟨?_, ?_, ?_⟩, ⟨?_, ?_, ?_⟩, ⟨?_, ?_, ?_⟩, ⟨?_, ?_, ?_⟩⟩ <;>
      intro h <;> have := pair_mem_of_eq h <;>
        simp [hab, hac, hbc, had, hbd, hcd, haw, hbw, hcw, hdw, hab.symm, hac.symm, hbc.symm, had.symm, hbd.symm, hcd.symm, haw.symm, hbw.symm, hcw.symm, hdw.symm] at this
  have hF : R ∪ N = insert {a, c, w} (insert {b, c, w} (insert {a, d, w} (insert {b, d, w} R))) := by
    ext s; simp only [hN, mem_union, mem_insert, mem_singleton]; grind
  have hEK : ∀ s : Finset α, w ∈ s → s ∉ edges K := fun s hs =>
    not_mem_edges_of_not_mem_vertices hw hs
  have hVc : (vertices (R ∪ N)).card = (vertices K).card + 1 := by
    rw [hV, card_insert_of_notMem hw]
  have hEc : (edges (R ∪ N)).card + 1 = (edges K).card + 4 := by
    rw [← card_insert_of_notMem hEab, hE, card_insert_of_notMem, card_insert_of_notMem,
      card_insert_of_notMem, card_insert_of_notMem (hEK _ (by simp))]
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, hEK _ (by simp)⟩
      have := pair_mem_of_eq h
      simp [hab, hac, hbc, had, hbd, hcd, haw, hbw, hcw, hdw, hab.symm, hac.symm, hbc.symm, had.symm, hbd.symm, hcd.symm, haw.symm, hbw.symm, hcw.symm, hdw.symm] at this
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, fun h => ?_, hEK _ (by simp)⟩ <;>
        have := pair_mem_of_eq h <;>
        simp [hab, hac, hbc, had, hbd, hcd, haw, hbw, hcw, hdw, hab.symm, hac.symm, hbc.symm, had.symm, hbd.symm, hcd.symm, haw.symm, hbw.symm, hcw.symm, hdw.symm] at this
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, fun h => ?_, fun h => ?_, hEK _ (by simp)⟩ <;>
        have := pair_mem_of_eq h <;>
        simp [hab, hac, hbc, had, hbd, hcd, haw, hbw, hcw, hdw, hab.symm, hac.symm, hbc.symm, had.symm, hbd.symm, hcd.symm, haw.symm, hbw.symm, hcw.symm, hdw.symm] at this
  have hFc : (R ∪ N).card = K.card + 2 := by
    have hRK : K.card = R.card + 2 := by
      rw [hK, card_insert_of_notMem, card_insert_of_notMem (by simp [hR])]
      simp only [mem_insert, not_or]
      exact ⟨fun h => hcd' h.symm, by simp [hR]⟩
    have hRn : ∀ s : Finset α, w ∈ s → s ∉ R := fun s hs => not_mem_of_not_mem_vertices hRw hs
    rw [hF, card_insert_of_notMem, card_insert_of_notMem, card_insert_of_notMem,
      card_insert_of_notMem (hRn _ (by simp)), hRK]
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, hRn _ (by simp)⟩
      have := triple_mem_of_eq h
      simp [hab, hac, hbc, had, hbd, hcd, haw, hbw, hcw, hdw, hab.symm, hac.symm, hbc.symm, had.symm, hbd.symm, hcd.symm, haw.symm, hbw.symm, hcw.symm, hdw.symm] at this
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, fun h => ?_, hRn _ (by simp)⟩ <;>
        have := triple_mem_of_eq h <;>
        simp [hab, hac, hbc, had, hbd, hcd, haw, hbw, hcw, hdw, hab.symm, hac.symm, hbc.symm, had.symm, hbd.symm, hcd.symm, haw.symm, hbw.symm, hcw.symm, hdw.symm] at this
    · simp only [mem_insert, not_or]
      refine ⟨fun h => ?_, fun h => ?_, fun h => ?_, hRn _ (by simp)⟩ <;>
        have := triple_mem_of_eq h <;>
        simp [hab, hac, hbc, had, hbd, hcd, haw, hbw, hcw, hdw, hab.symm, hac.symm, hbc.symm, had.symm, hbd.symm, hcd.symm, haw.symm, hbw.symm, hcw.symm, hdw.symm] at this
  unfold eulerChar
  rw [hVc, hFc]
  push_cast; omega

theorem eulerChar_basicCut {K K' : Finset (Finset α)} (h : BasicCut K K') :
    eulerChar K' = eulerChar K := by
  cases h with
  | face a b c w hab hac hbc ht hw => exact eulerChar_face K a b c w hab hac hbc ht hw
  | edge a b c d w hab hac hbc had hbd hcd hc hd honly hw =>
    exact eulerChar_edge K a b c d w hab hac hbc had hbd hcd hc hd honly hw

theorem closed_erase_edges {M : Finset (Finset α)} (hM : IsClosedTriangleSurface M)
    {t : Finset α} (_ht : t ∈ M) : edges (M.erase t) = edges M := by
  apply Subset.antisymm
  · intro e he
    obtain ⟨s, hs, hes, hc⟩ := mem_edges.mp he
    exact mem_edges.mpr ⟨s, mem_of_mem_erase hs, hes, hc⟩
  · intro e he
    have h2 := hM.2 e he
    obtain ⟨-, -, -, hc⟩ := mem_edges.mp he
    obtain ⟨s, hs, hst⟩ :=
      exists_mem_ne (by omega : 1 < (M.filter (fun s => e ⊆ s)).card) t
    rw [mem_filter] at hs
    exact mem_edges.mpr ⟨s, mem_erase.mpr ⟨hst, hs.1⟩, hs.2, hc⟩

theorem closed_erase_vertices {M : Finset (Finset α)} (hM : IsClosedTriangleSurface M)
    {t : Finset α} (ht : t ∈ M) : vertices (M.erase t) = vertices M := by
  apply Subset.antisymm
  · intro v hv
    obtain ⟨s, hs, hvs⟩ := mem_vertices.mp hv
    exact mem_vertices.mpr ⟨s, mem_of_mem_erase hs, hvs⟩
  · intro v hv
    obtain ⟨s, hs, hvs⟩ := mem_vertices.mp hv
    obtain ⟨u, hu, huv⟩ := exists_mem_ne (by rw [hM.1 s hs]; omega : 1 < s.card) v
    have he : ({v, u} : Finset α) ∈ edges M := by
      refine mem_edges.mpr ⟨s, hs, ?_, card_pair_eq_two_iff.mpr (Ne.symm huv)⟩
      intro x hx
      simp only [mem_insert, mem_singleton] at hx
      rcases hx with rfl | rfl <;> assumption
    rw [← closed_erase_edges hM ht] at he
    exact edge_subset_vertices he (by simp)

theorem sum_degree_eq (K : Finset (Finset α)) :
    ∑ v ∈ vertices K, degree K v = 2 * (edges K).card := by
  have h := sum_card_bipartiteAbove_eq_sum_card_bipartiteBelow (s := vertices K)
    (t := edges K) (r := fun v e => v ∈ e)
  simp only [bipartiteAbove, bipartiteBelow] at h
  unfold degree
  rw [h, sum_const_nat (m := 2), mul_comm]
  intro e he
  rw [filter_mem_eq_inter, inter_eq_right.mpr (edge_subset_vertices he)]
  exact (mem_edges.mp he).choose_spec.2.2

theorem three_mul_card (K : Finset (Finset α)) (hK : IsClosedTriangleSurface K) :
    3 * K.card = 2 * (edges K).card := by
  have h := sum_card_bipartiteAbove_eq_sum_card_bipartiteBelow (s := K)
    (t := edges K) (r := fun t e => e ⊆ t)
  simp only [bipartiteAbove, bipartiteBelow] at h
  have h1 : ∑ t ∈ K, ((edges K).filter (fun e => e ⊆ t)).card = K.card * 3 := by
    apply sum_const_nat
    intro t ht
    have hf : (edges K).filter (fun e => e ⊆ t) = t.powersetCard 2 := by
      ext e
      simp only [mem_filter, mem_powersetCard]
      constructor
      · rintro ⟨he, hs⟩
        exact ⟨hs, (mem_edges.mp he).choose_spec.2.2⟩
      · rintro ⟨hs, hc⟩
        exact ⟨mem_edges.mpr ⟨t, ht, hs, hc⟩, hs⟩
    rw [hf, card_powersetCard, hK.1 t ht]
    rfl
  have h2 : ∑ e ∈ edges K, (K.filter (fun t => e ⊆ t)).card = (edges K).card * 2 :=
    sum_const_nat (fun e he => hK.2 e he)
  rw [h1, h2] at h
  omega

/-- Cutting a triangulation into a finer one never changes chi: if `K'` comes from `K` by any
number of face cuts and edge cuts, each adding one corner, three edges and two triangles, then
`V - E + F` is the same for `K'` as for `K`. -/
theorem euler_char_unchanged_by_cuts (K K' : Finset (Finset α))
    (h : Relation.ReflTransGen BasicCut K K') :
    eulerChar K' = eulerChar K := by
  induction h with
  | refl => rfl
  | tail _ hstep ih => rw [eulerChar_basicCut hstep, ih]

/-- Joining two closed surfaces costs 2: cut the same triangle `t` out of closed surfaces `M`
and `N` that share only the corners of `t`, and glue along the cut; then
`chi(M # N) = chi(M) + chi(N) - 2`. -/
theorem euler_char_connected_sum (M N : Finset (Finset α)) (t : Finset α)
    (hM : IsClosedTriangleSurface M) (hN : IsClosedTriangleSurface N)
    (htM : t ∈ M) (htN : t ∈ N) (hshare : vertices M ∩ vertices N = t) :
    eulerChar ((M.erase t) ∪ (N.erase t)) = eulerChar M + eulerChar N - 2 := by
  have ht3 : t.card = 3 := hM.1 t htM
  have hVL : (vertices ((M.erase t) ∪ (N.erase t))).card + 3 =
      (vertices M).card + (vertices N).card := by
    rw [vertices_union, closed_erase_vertices hM htM, closed_erase_vertices hN htN, ← ht3,
      ← hshare, card_union_add_card_inter]
  have hEint : edges M ∩ edges N = t.powersetCard 2 := by
    ext e
    simp only [mem_inter, mem_powersetCard]
    constructor
    · rintro ⟨h1, h2⟩
      obtain ⟨-, -, -, hc⟩ := mem_edges.mp h1
      refine ⟨?_, hc⟩
      rw [← hshare]
      exact subset_inter (edge_subset_vertices h1) (edge_subset_vertices h2)
    · rintro ⟨h1, h2⟩
      exact ⟨mem_edges.mpr ⟨t, htM, h1, h2⟩, mem_edges.mpr ⟨t, htN, h1, h2⟩⟩
  have hEL : (edges ((M.erase t) ∪ (N.erase t))).card + 3 =
      (edges M).card + (edges N).card := by
    rw [edges_union, closed_erase_edges hM htM, closed_erase_edges hN htN,
      ← card_union_add_card_inter, hEint, card_powersetCard, ht3]
    rfl
  have hdisj : Disjoint (M.erase t) (N.erase t) := by
    rw [disjoint_left]
    intro s hsM hsN
    obtain ⟨hst, hsM'⟩ := mem_erase.mp hsM
    have hsN' := mem_of_mem_erase hsN
    have hsub : s ⊆ t := by
      rw [← hshare]
      intro v hv
      exact mem_inter.mpr ⟨mem_vertices.mpr ⟨s, hsM', hv⟩, mem_vertices.mpr ⟨s, hsN', hv⟩⟩
    exact hst (eq_of_subset_of_card_le hsub (by rw [ht3, hM.1 s hsM']))
  have hFL : ((M.erase t) ∪ (N.erase t)).card + 2 = M.card + N.card := by
    rw [card_union_of_disjoint hdisj, card_erase_of_mem htM, card_erase_of_mem htN]
    have := card_pos.mpr ⟨t, htM⟩
    have := card_pos.mpr ⟨t, htN⟩
    omega
  unfold eulerChar
  omega

/-- The second road through the corners: on a closed surface of triangles, adding up six minus
each corner's degree, over all corners, gives six times chi. -/
theorem sum_six_sub_degree_eq_six_mul_euler_char (K : Finset (Finset α))
    (hK : IsClosedTriangleSurface K) :
    ∑ v ∈ vertices K, (6 - (degree K v : ℤ)) = 6 * eulerChar K := by
  have hd := sum_degree_eq K
  have h3 := three_mul_card K hK
  rw [sum_sub_distrib, sum_const, ← Nat.cast_sum, hd]
  unfold eulerChar
  simp only [nsmul_eq_mul]
  push_cast
  omega

/-- The inner tube: a 3 × 3 grid of squares, each cut by one diagonal, glued left to right
and bottom to top. Corner `3 i + j` sits at column `i`, row `j`. -/
def tube : Finset (Finset (Fin 9)) :=
  {{0, 3, 4}, {0, 1, 4}, {1, 4, 5}, {1, 2, 5}, {2, 3, 5}, {0, 2, 3}, {3, 6, 7}, {3, 4, 7},
   {4, 7, 8}, {4, 5, 8}, {5, 6, 8}, {3, 5, 6}, {0, 1, 6}, {1, 6, 7}, {1, 2, 7}, {2, 7, 8},
   {0, 2, 8}, {0, 6, 8}}

/-- The icosahedron, the dome's starting solid: top 0, rings 1 to 5 and 6 to 10, bottom 11. -/
def icosahedron : Finset (Finset (Fin 12)) :=
  {{0, 1, 2}, {1, 2, 6}, {2, 6, 7}, {6, 7, 11}, {0, 2, 3}, {2, 3, 7}, {3, 7, 8}, {7, 8, 11},
   {0, 3, 4}, {3, 4, 8}, {4, 8, 9}, {8, 9, 11}, {0, 4, 5}, {4, 5, 9}, {5, 9, 10}, {9, 10, 11},
   {0, 1, 5}, {1, 5, 10}, {1, 6, 10}, {6, 10, 11}}

-- The tube: 9 corners, 27 edges, 18 triangles, chi 0, every corner of degree 6.
example : (vertices tube).card = 9 ∧ (edges tube).card = 27 ∧ tube.card = 18 := by decide +kernel
example : eulerChar tube = 0 := by decide +kernel
example : ∀ v : Fin 9, degree tube v = 6 := by decide +kernel
-- The tube is a closed surface of triangles, and its degree sum is 0 = 6 × 0.
example : (∀ t ∈ tube, t.card = 3) ∧ ∀ e ∈ edges tube, (tube.filter (fun t => e ⊆ t)).card = 2 := by
  decide +kernel
example : ∑ v ∈ vertices tube, (6 - (degree tube v : ℤ)) = 0 := by decide +kernel

-- The icosahedron: 12 − 30 + 20 = 2.
example : (vertices icosahedron).card = 12 ∧ (edges icosahedron).card = 30 ∧
    icosahedron.card = 20 := by decide +kernel
example : eulerChar icosahedron = 2 := by decide +kernel

-- Worked numbers by hand.
example : (12 : ℤ) + 30 = 42 ∧ (2 : ℤ) * 30 + 3 * 20 = 120 ∧ (4 : ℤ) * 20 = 80 := by norm_num
example : (42 : ℤ) - 120 + 80 = 2 := by norm_num
example : (12 : ℤ) * (6 - 5) + 30 * (6 - 6) = 6 * 2 := by norm_num
example : (9 : ℤ) - 27 + 18 = 0 := by norm_num
example : (9 + 9 - 3 : ℤ) = 15 ∧ (27 + 27 - 3 : ℤ) = 51 ∧ (17 + 17 : ℤ) = 34 := by norm_num
example : (15 : ℤ) - 51 + 34 = -2 ∧ (0 : ℤ) + 0 - 2 = -2 := by norm_num
example : (342 : ℤ) - 1020 + 680 = 2 ∧ (309 : ℤ) - 927 + 618 = 0 := by norm_num
-- What breaks: unglued square, struts counted per panel, a missing panel, a 2 × 2 grid.
example : (16 : ℤ) - 33 + 18 = 1 ∧ (42 : ℤ) - 240 + 80 = -118 := by norm_num
example : (42 : ℤ) - 120 + 79 = 1 ∧ (4 : ℤ) - 6 + 8 = 6 := by norm_num

end EulerTriangulation

open EulerTriangulation

#print axioms euler_char_unchanged_by_cuts
#print axioms euler_char_connected_sum
#print axioms sum_six_sub_degree_eq_six_mul_euler_char
#print axioms mem_vertices
#print axioms mem_edges
#print axioms vertices_union
#print axioms edges_union
#print axioms vertices_insert
#print axioms edges_insert
#print axioms vertices_singleton
#print axioms edges_singleton
#print axioms edge_subset_vertices
#print axioms pair_mem_of_eq
#print axioms triple_mem_of_eq
#print axioms powersetCard_two_three
#print axioms not_mem_of_not_mem_vertices
#print axioms not_mem_edges_of_not_mem_vertices
#print axioms ne_of_not_mem_vertices
#print axioms eulerChar_face
#print axioms eulerChar_edge
#print axioms eulerChar_basicCut
#print axioms closed_erase_edges
#print axioms closed_erase_vertices
#print axioms sum_degree_eq
#print axioms three_mul_card
