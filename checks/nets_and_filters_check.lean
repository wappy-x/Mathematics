-- Nets and filters: a space is compact exactly when every ultrafilter on it converges, a point is in the closure of a set exactly when a net or a filter from the set converges to it, and a map is continuous at a point exactly when it carries every net converging there to a net converging to the image.
import Mathlib.Topology.Compactness.Compact
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Data.Nat.Totient
import Mathlib.Data.Fintype.Powerset

open Set Filter Topology

universe u v

/-- Helper: a non-trivial filter `ℱ` holding `A` is the limit filter of a net in `A`. -/
theorem net_of_filter_aux {X : Type u} (ℱ : Filter X) [hF : ℱ.NeBot] (A : Set X)
    (hA : A ∈ ℱ) :
    ∃ (D : Type u) (_ : Preorder D) (_ : IsDirected D (· ≤ ·)) (_ : Nonempty D)
      (x : D → X), (∀ d, x d ∈ A) ∧ Tendsto x atTop ℱ ∧
        ∀ S : Set X, (∀ᶠ d in atTop, x d ∈ S) → S ∈ ℱ := by
  classical
  let D := {q : Set X × X // q.1 ∈ ℱ ∧ q.1 ⊆ A ∧ q.2 ∈ q.1}
  let _ : Preorder D := Preorder.lift (fun q : D => OrderDual.toDual q.1.1)
  have hle : ∀ a b : D, a ≤ b ↔ b.1.1 ⊆ a.1.1 := fun _ _ => Iff.rfl
  have hne : ∀ s ∈ ℱ, s.Nonempty := fun s hs => hF.nonempty_of_mem hs
  obtain ⟨y0, hy0⟩ := hne A hA
  have hdir : IsDirected D (· ≤ ·) := by
    refine ⟨fun a b => ?_⟩
    have hmem : a.1.1 ∩ b.1.1 ∈ ℱ := inter_mem a.2.1 b.2.1
    obtain ⟨w, hw⟩ := hne _ hmem
    refine ⟨⟨(a.1.1 ∩ b.1.1, w), hmem, inter_subset_left.trans a.2.2.1, hw⟩, ?_, ?_⟩
    · rw [hle]; exact inter_subset_left
    · rw [hle]; exact inter_subset_right
  have hnon : Nonempty D := ⟨⟨(A, y0), hA, subset_rfl, hy0⟩⟩
  refine ⟨D, inferInstance, hdir, hnon, fun q => q.1.2, fun q => q.2.2.1 q.2.2.2, ?_, ?_⟩
  · rw [tendsto_atTop']
    intro S hS
    have hmem : S ∩ A ∈ ℱ := inter_mem hS hA
    obtain ⟨w, hw⟩ := hne _ hmem
    refine ⟨⟨(S ∩ A, w), hmem, inter_subset_right, hw⟩, fun b hb => ?_⟩
    rw [hle] at hb
    exact (hb b.2.2.2).1
  · intro S hS
    rw [Filter.eventually_atTop] at hS
    obtain ⟨d0, hd0⟩ := hS
    refine mem_of_superset d0.2.1 fun y hy => ?_
    exact hd0 ⟨(d0.1.1, y), d0.2.1, d0.2.2.1, hy⟩ ((hle _ _).2 subset_rfl)

#print axioms net_of_filter_aux

/-- Compact exactly when every ultrafilter converges: a topological space `X` is compact
(every open cover has a finite subcover) exactly when every ultrafilter `𝒰` on `X` converges
to some point `p`, that is, holds every neighbourhood of `p` (`𝒩(p) ⊆ 𝒰`, written `𝒰 ≤ 𝓝 p`). -/
theorem compactSpace_iff_every_ultrafilter_converges {X : Type u} [TopologicalSpace X] :
    CompactSpace X ↔ ∀ 𝒰 : Ultrafilter X, ∃ p : X, (𝒰 : Filter X) ≤ 𝓝 p := by
  rw [← isCompact_univ_iff, isCompact_iff_ultrafilter_le_nhds]
  constructor
  · intro H 𝒰
    obtain ⟨x, -, hx⟩ := H 𝒰 (by simp)
    exact ⟨x, hx⟩
  · intro H 𝒰 _
    obtain ⟨x, hx⟩ := H 𝒰
    exact ⟨x, mem_univ x, hx⟩

/-- Closure by nets and by filters: a point `p` is in the closure of `A` exactly when some net
in `A` converges to `p`, labelled by a non-empty directed set `D` (an order, reflexive and
transitive, in which any two labels have a common later label), and exactly when some filter
holding `A` (never holding the empty set) converges to `p`. -/
theorem mem_closure_iff_net_or_filter_converges {X : Type u} [TopologicalSpace X]
    (A : Set X) (p : X) :
    (p ∈ closure A ↔
      ∃ (D : Type u) (_ : Preorder D) (_ : IsDirected D (· ≤ ·)) (_ : Nonempty D)
        (x : D → X), (∀ d, x d ∈ A) ∧ Tendsto x atTop (𝓝 p)) ∧
    (p ∈ closure A ↔ ∃ ℱ : Filter X, ℱ.NeBot ∧ A ∈ ℱ ∧ ℱ ≤ 𝓝 p) := by
  have key : p ∈ closure A ↔ ∃ ℱ : Filter X, ℱ.NeBot ∧ A ∈ ℱ ∧ ℱ ≤ 𝓝 p := by
    constructor
    · intro hp
      rw [mem_closure_iff_clusterPt] at hp
      exact ⟨𝓝 p ⊓ 𝓟 A, hp, mem_inf_of_right (mem_principal_self A), inf_le_left⟩
    · rintro ⟨ℱ, hF, hA, hle⟩
      exact mem_closure_of_tendsto (f := id) (b := ℱ) hle hA
  refine ⟨⟨fun hp => ?_, ?_⟩, key⟩
  · obtain ⟨ℱ, hF, hA, hle⟩ := key.1 hp
    obtain ⟨D, i1, i2, i3, x, hxA, hx, -⟩ := net_of_filter_aux ℱ A hA
    exact ⟨D, i1, i2, i3, x, hxA, hx.mono_right hle⟩
  · rintro ⟨D, i1, i2, i3, x, hxA, hx⟩
    exact mem_closure_of_tendsto hx (Filter.Eventually.of_forall hxA)

/-- Continuity by nets: a map `h` is continuous at `p` exactly when, for every net `x_d → p`
labelled by a non-empty directed set, the image net `h(x_d)` converges to `h(p)`. -/
theorem continuousAt_iff_preserves_net_limits {X : Type u} {Y : Type v}
    [TopologicalSpace X] [TopologicalSpace Y] (h : X → Y) (p : X) :
    ContinuousAt h p ↔
      ∀ (D : Type u) [Preorder D] [IsDirected D (· ≤ ·)] [Nonempty D] (x : D → X),
        Tendsto x atTop (𝓝 p) → Tendsto (h ∘ x) atTop (𝓝 (h p)) := by
  constructor
  · intro hc D _ _ _ x hx
    exact hc.tendsto.comp hx
  · intro H
    obtain ⟨D, i1, i2, i3, x, -, hx, hmap⟩ := net_of_filter_aux (𝓝 p) univ univ_mem
    intro V hV
    exact hmap _ (H D x hx hV)

-- The net f_F on 8 sample points: the finite sets F holding the 3 probes are 2^(8-3) = 32 of 256.
example : (Finset.univ.filter
    (fun F : Finset (Fin 8) => ({0, 1, 2} : Finset (Fin 8)) ⊆ F)).card = 32 := by decide

-- The sequence g_n: fractions in [0, 1] with bottom at most n number 1 + (totient sum),
-- 33 at n = 10 and 3045 at n = 100.
example : 1 + ∑ k ∈ Finset.Icc 1 10, Nat.totient k = 33 := by decide

set_option maxRecDepth 100000 in
example : 1 + ∑ k ∈ Finset.Icc 1 100, Nat.totient k = 3045 := by decide

-- On {a, b, c}: of the 256 families of subsets, 7 are filters and 3 are ultrafilters.
example : ((Finset.univ : Finset (Finset (Finset (Fin 3)))).filter (fun t =>
    Finset.univ ∈ t ∧ ∅ ∉ t ∧ (∀ s ∈ t, ∀ u ∈ t, s ∩ u ∈ t) ∧
      ∀ s ∈ t, ∀ u, s ⊆ u → u ∈ t)).card = 7 := by decide

example : ((Finset.univ : Finset (Finset (Finset (Fin 3)))).filter (fun t =>
    Finset.univ ∈ t ∧ ∅ ∉ t ∧ (∀ s ∈ t, ∀ u ∈ t, s ∩ u ∈ t) ∧
      (∀ s ∈ t, ∀ u, s ⊆ u → u ∈ t) ∧ ∀ s, s ∈ t ∨ sᶜ ∈ t)).card = 3 := by decide

-- There are 29 topologies on {a, b, c}.
example : ((Finset.univ : Finset (Finset (Finset (Fin 3)))).filter (fun t =>
    ∅ ∈ t ∧ Finset.univ ∈ t ∧ ∀ s ∈ t, ∀ u ∈ t, s ∩ u ∈ t ∧ s ∪ u ∈ t)).card = 29 := by decide

-- Compact, but sequences fail: at x = 4369/16384, the binary digits at places 2, 4, ..., 16
-- read 1 0 1 0 1 0 1 0.
example : (List.range 8).map (fun k => 4369 * 2 ^ (2 * (k + 1)) / 16384 % 2) =
    [1, 0, 1, 0, 1, 0, 1, 0] := by decide

#print axioms compactSpace_iff_every_ultrafilter_converges
#print axioms mem_closure_iff_net_or_filter_converges
#print axioms continuousAt_iff_preserves_net_limits
