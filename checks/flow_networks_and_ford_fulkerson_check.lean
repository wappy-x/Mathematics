-- Flows: pushing any amount up to the smallest leftover along a source-to-sink route keeps a flow legal and raises its value by that amount, no flow beats any cut, and whole-number capacities always have a best flow in whole loads whose value equals a cut's price.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Prod
import Mathlib.Algebra.BigOperators.Group.Finset.Piecewise
import Mathlib.Algebra.Order.Ring.Defs
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Abel
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.List.Chain
import Mathlib.Logic.Relation
import Mathlib.Data.Finset.Max
import Mathlib.Algebra.BigOperators.Ring.Finset

open Finset

namespace FordFulkerson

/-! The network: a finite set `V` of junctions, a capacity `c u v` for the one-way road from `u`
to `v` (0 where no road runs), a source `s` and a sink `t`. A plan `f u v` is the load on the
road from `u` to `v`. The definitions work for any ordered number system `R`; the theorems use
real numbers, and the worked examples use whole numbers. -/

variable {V R : Type*} [Fintype V] [AddCommGroup R] [PartialOrder R]

/-- A flow: no road carries less than 0 or more than its capacity, and at every junction other
than the source and the sink, what arrives equals what leaves. -/
def IsFlow (c f : V → V → R) (s t : V) : Prop :=
  (∀ u v, 0 ≤ f u v ∧ f u v ≤ c u v) ∧
    ∀ x, x ≠ s → x ≠ t → ∑ u, f u x = ∑ u, f x u

/-- The value `|f|`: loads leaving the source, less loads coming back into it. -/
def value (f : V → V → R) (s : V) : R :=
  ∑ u, f s u - ∑ u, f u s

/-- The leftover on the step from `u` to `v`: spare capacity on the road `u → v`, plus the load on
the road `v → u`, which can be cancelled. -/
def leftover (c f : V → V → R) (u v : V) : R :=
  (c u v - f u v) + f v u

/-- The price of the cut whose source side is `S`: the capacities of the roads leaving `S`. -/
def cutPrice [DecidableEq V] (c : V → V → R) (S : Finset V) : R :=
  ∑ u ∈ S, ∑ v ∈ Sᶜ, c u v

instance [DecidableEq V] [DecidableEq R] [DecidableLE R] (c f : V → V → R) (s t : V) :
    Decidable (IsFlow c f s t) := by
  unfold IsFlow; infer_instance

/-- A route in a relation can be shortened to one that visits no junction twice. -/
theorem exists_nodup_chain {α : Type*} [DecidableEq α] (r : α → α → Prop) {a b : α}
    (h : Relation.ReflTransGen r a b) :
    ∃ l : List α, l.head? = some a ∧ l.getLast? = some b ∧ l.Nodup ∧ l.IsChain r := by
  induction h using Relation.ReflTransGen.head_induction_on with
  | refl => exact ⟨[b], rfl, rfl, List.nodup_singleton b, List.isChain_singleton b⟩
  | head hac hcb ih =>
    rename_i a c
    obtain ⟨l, hh, hl, hn, hc⟩ := ih
    by_cases ha : a ∈ l
    · obtain ⟨l1, l2, rfl⟩ := List.append_of_mem ha
      refine ⟨a :: l2, rfl, ?_, ?_, ?_⟩
      · rw [List.getLast?_append] at hl
        rw [List.getLast?_cons] at hl ⊢
        simpa using hl
      · exact hn.sublist (List.sublist_append_right _ _)
      · exact hc.right_of_append
    · cases l with
      | nil => simp at hh
      | cons d l' =>
        simp only [List.head?_cons, Option.some.injEq] at hh
        subst hh
        refine ⟨a :: d :: l', rfl, by simpa using hl, List.nodup_cons.2 ⟨ha, hn⟩, ?_⟩
        exact List.isChain_cons_cons.2 ⟨hac, hc⟩

#print axioms exists_nodup_chain

/-- Pushing `b` across one step `u → v` with leftover at least `b`. -/
theorem push_edge {K : Type*} [CommRing K] [LinearOrder K] [IsStrictOrderedRing K]
    [DecidableEq V] (c f : V → V → K) (hf : ∀ u v, 0 ≤ f u v ∧ f u v ≤ c u v)
    (u v : V) (huv : u ≠ v) (b : K) (hb : 0 ≤ b) (hroom : b ≤ leftover c f u v) :
    ∃ g : V → V → K, (∀ x y, 0 ≤ g x y ∧ g x y ≤ c x y) ∧
      (∀ x, value g x = value f x + (if x = u then b else 0) - (if x = v then b else 0)) ∧
      (∀ x y, g x y ≠ f x y → (x = u ∧ y = v) ∨ (x = v ∧ y = u)) := by
  set m := min b (f v u) with hm
  refine ⟨fun x y => f x y + (if x = u ∧ y = v then b - m else 0) -
    (if x = v ∧ y = u then m else 0), ?_, ?_, ?_⟩
  · intro x y
    have hm1 : m ≤ b := min_le_left _ _
    have hm2 : m ≤ f v u := min_le_right _ _
    have hm0 : 0 ≤ m := le_min hb (hf v u).1
    unfold leftover at hroom
    by_cases h1 : x = u ∧ y = v
    · obtain ⟨hx, hy⟩ := h1
      subst x; subst y
      have h2 : ¬ (u = v ∧ v = u) := fun h => huv h.1
      simp only [and_self, ite_true, h2, ite_false, sub_zero]
      refine ⟨by linarith [(hf u v).1], ?_⟩
      rcases le_total b (f v u) with h | h
      · have : m = b := min_eq_left h
        rw [this]; linarith [(hf u v).2]
      · have : m = f v u := min_eq_right h
        rw [this]; linarith
    · by_cases h2 : x = v ∧ y = u
      · obtain ⟨hx, hy⟩ := h2
        subst x; subst y
        simp only [h1, ite_false, and_self, ite_true, add_zero]
        exact ⟨by linarith, by linarith [(hf v u).2]⟩
      · simp only [h1, h2, ite_false, add_zero, sub_zero]
        exact hf x y
  · intro x
    simp only [value, Finset.sum_sub_distrib, Finset.sum_add_distrib, ite_and]
    by_cases hxu : x = u
    · subst x
      simp [huv]
      abel
    · by_cases hxv : x = v
      · subst x
        simp [hxu]
        abel
      · simp [hxu, hxv]
  · intro x y hxy
    by_contra hc
    push Not at hc
    apply hxy
    have h1 : ¬ (x = u ∧ y = v) := fun h => by
      obtain ⟨h1, h2⟩ := h; exact absurd h2 (hc.1 h1)
    have h2 : ¬ (x = v ∧ y = u) := fun h => by
      obtain ⟨h1, h2⟩ := h; exact absurd h2 (hc.2 h1)
    simp only [h1, h2, ite_false, add_zero, sub_zero]

#print axioms push_edge

/-- Pushing `b` along a route that visits no junction twice. -/
theorem push_route {K : Type*} [CommRing K] [LinearOrder K] [IsStrictOrderedRing K]
    [DecidableEq V] (c f : V → V → K) (hf : ∀ u v, 0 ≤ f u v ∧ f u v ≤ c u v)
    (b : K) (hb : 0 ≤ b) (z : V) :
    ∀ (p : List V) (a : V), p.head? = some a → p.getLast? = some z → p.Nodup →
      p.IsChain (fun u v => b ≤ leftover c f u v) →
      ∃ g : V → V → K, (∀ x y, 0 ≤ g x y ∧ g x y ≤ c x y) ∧
        (∀ x, value g x = value f x + (if x = a then b else 0) - (if x = z then b else 0)) ∧
        (∀ x y, g x y ≠ f x y → (x, y) ∈ p.zip p.tail ∨ (y, x) ∈ p.zip p.tail) := by
  intro p
  induction p with
  | nil => intro a h; simp at h
  | cons u q ih =>
    intro a hh hl hn hc
    simp only [List.head?_cons, Option.some.injEq] at hh
    subst hh
    cases q with
    | nil =>
      simp only [List.getLast?_singleton, Option.some.injEq] at hl
      subst hl
      refine ⟨f, hf, fun x => (by abel), fun x y h => absurd rfl h⟩
    | cons v rest =>
      rw [List.getLast?_cons_cons] at hl
      have hn' := List.nodup_cons.1 hn
      have hc' := List.isChain_cons_cons.1 hc
      obtain ⟨g1, hg1b, hg1v, hg1c⟩ := ih v rfl hl hn'.2 hc'.2
      have huv : u ≠ v := fun h => hn'.1 (h ▸ List.mem_cons_self)
      have hfix : ∀ x y, (x = u ∨ y = u) → g1 x y = f x y := by
        intro x y hxy
        by_contra hne
        rcases hg1c x y hne with h | h
        · have h1 := List.of_mem_zip h
          rcases hxy with rfl | rfl
          · exact hn'.1 h1.1
          · exact hn'.1 (List.mem_cons_of_mem _ h1.2)
        · have h1 := List.of_mem_zip h
          rcases hxy with rfl | rfl
          · exact hn'.1 (List.mem_cons_of_mem _ h1.2)
          · exact hn'.1 h1.1
      have hroom : b ≤ leftover c g1 u v := by
        unfold leftover
        rw [hfix u v (Or.inl rfl), hfix v u (Or.inr rfl)]
        exact hc'.1
      obtain ⟨g2, hg2b, hg2v, hg2c⟩ := push_edge c g1 hg1b u v huv b hb hroom
      refine ⟨g2, hg2b, fun x => ?_, ?_⟩
      · rw [hg2v, hg1v]
        abel
      · intro x y hxy
        simp only [List.tail_cons, List.zip_cons_cons, List.mem_cons, Prod.mk.injEq]
        by_cases h21 : g2 x y = g1 x y
        · rw [h21] at hxy
          rcases hg1c x y hxy with h | h
          · exact Or.inl (Or.inr h)
          · exact Or.inr (Or.inr h)
        · rcases hg2c x y h21 with h | h
          · exact Or.inl (Or.inl h)
          · exact Or.inr (Or.inl ⟨h.2, h.1⟩)

#print axioms push_route

/-- Summing net outflow over a set of junctions leaves only the roads crossing its edge. -/
theorem sum_value_eq_cross {K : Type*} [AddCommGroup K] [DecidableEq V]
    (f : V → V → K) (S : Finset V) :
    ∑ x ∈ S, value f x = ∑ x ∈ S, ∑ u ∈ Sᶜ, (f x u - f u x) := by
  have h1 : ∀ x, ∑ u, f x u = ∑ u ∈ S, f x u + ∑ u ∈ Sᶜ, f x u :=
    fun x => (Finset.sum_add_sum_compl S _).symm
  have h2 : ∀ x, ∑ u, f u x = ∑ u ∈ S, f u x + ∑ u ∈ Sᶜ, f u x :=
    fun x => (Finset.sum_add_sum_compl S _).symm
  simp only [value, h1, h2, Finset.sum_sub_distrib, Finset.sum_add_distrib]
  rw [Finset.sum_comm (s := S) (t := S) (f := fun x u => f u x)]
  abel

#print axioms sum_value_eq_cross

/-- For a flow and a cut with the source inside and the sink outside, the value is the net load
across the cut. -/
theorem value_eq_cross {K : Type*} [AddCommGroup K] [PartialOrder K] [DecidableEq V]
    (c f : V → V → K) (s t : V) (hf : IsFlow c f s t)
    (S : Finset V) (hs : s ∈ S) (ht : t ∉ S) :
    value f s = ∑ x ∈ S, ∑ u ∈ Sᶜ, (f x u - f u x) := by
  rw [← sum_value_eq_cross, Finset.sum_eq_single_of_mem s hs]
  intro x hx hxs
  have hxt : x ≠ t := fun h => ht (h ▸ hx)
  unfold value
  rw [hf.2 x hxs hxt, sub_self]

#print axioms value_eq_cross

/-- The push along a route keeps a flow a flow and adds `b` to its value. -/
theorem push_flow {K : Type*} [CommRing K] [LinearOrder K] [IsStrictOrderedRing K]
    [DecidableEq V] (c f : V → V → K) (s t : V) (hst : s ≠ t) (hf : IsFlow c f s t)
    (p : List V) (hhead : p.head? = some s) (hlast : p.getLast? = some t) (hp : p.Nodup)
    (b : K) (hb : 0 ≤ b) (hroom : p.IsChain (fun u v => b ≤ leftover c f u v)) :
    ∃ g : V → V → K, IsFlow c g s t ∧ value g s = value f s + b ∧
      ∀ u v, g u v ≠ f u v → (u, v) ∈ p.zip p.tail ∨ (v, u) ∈ p.zip p.tail := by
  obtain ⟨g, hgb, hgv, hgc⟩ := push_route c f hf.1 b hb t p s hhead hlast hp hroom
  refine ⟨g, ⟨hgb, fun x hxs hxt => ?_⟩, ?_, hgc⟩
  · have h := hgv x
    have h0 : value f x = 0 := by unfold value; rw [hf.2 x hxs hxt, sub_self]
    simp only [hxs, hxt, ite_false, h0, add_zero, sub_zero] at h
    unfold value at h
    exact (sub_eq_zero.1 h).symm
  · rw [hgv s]
    simp [hst]

#print axioms push_flow

/-- Step 1, the push. Take a flow and a route from the source to a different sink that visits no
junction twice (the list `p` of its junctions). If an amount `b ≥ 0` is at most the leftover at
every step of the route (the bottleneck is the largest such amount), then pushing `b` along it,
adding to forward loads and cancelling loads that run the other way, gives a flow again; it
changes only roads joining consecutive junctions of the route, and its value is exactly `b`
more. -/
theorem push_along_route_keeps_flow_and_adds_bottleneck [DecidableEq V]
    (c f : V → V → ℝ) (s t : V) (hst : s ≠ t) (hf : IsFlow c f s t)
    (p : List V) (hhead : p.head? = some s) (hlast : p.getLast? = some t) (hp : p.Nodup)
    (b : ℝ) (hb : 0 ≤ b) (hroom : p.IsChain (fun u v => b ≤ leftover c f u v)) :
    ∃ g : V → V → ℝ, IsFlow c g s t ∧ value g s = value f s + b ∧
      ∀ u v, g u v ≠ f u v → (u, v) ∈ p.zip p.tail ∨ (v, u) ∈ p.zip p.tail := by
  exact push_flow c f s t hst hf p hhead hlast hp b hb hroom

/-- Step 2, no plan can beat any cut. For every flow and every split of the junctions with the
source on side `S` and the sink off it, the flow's value is at most the cut's price. -/
theorem flow_value_le_cut_price [DecidableEq V]
    (c f : V → V → ℝ) (s t : V) (hf : IsFlow c f s t)
    (S : Finset V) (hs : s ∈ S) (ht : t ∉ S) :
    value f s ≤ cutPrice c S := by
  rw [value_eq_cross c f s t hf S hs ht]
  unfold cutPrice
  apply Finset.sum_le_sum
  intro x _
  apply Finset.sum_le_sum
  intro u _
  linarith [(hf.1 x u).2, (hf.1 u x).1]

/-- Steps 3 and 4, the integrality theorem. When every capacity is a whole number, there is a
flow carrying a whole number of loads on every road that no flow (whole or fractional) beats, and
some cut's price equals its value, certifying that it is best. -/
theorem whole_capacities_have_best_whole_flow [DecidableEq V]
    (c : V → V → ℕ) (s t : V) (hst : s ≠ t) :
    ∃ n : V → V → ℕ,
      IsFlow (fun u v => (c u v : ℝ)) (fun u v => (n u v : ℝ)) s t ∧
      (∀ g : V → V → ℝ, IsFlow (fun u v => (c u v : ℝ)) g s t →
        value g s ≤ value (fun u v => (n u v : ℝ)) s) ∧
      ∃ S : Finset V, s ∈ S ∧ t ∉ S ∧
        value (fun u v => (n u v : ℝ)) s = cutPrice (fun u v => (c u v : ℝ)) S := by
  classical
  set cZ : V → V → ℤ := fun u v => (c u v : ℤ) with hcZ
  set T : Finset (V → V → ℕ) :=
    Fintype.piFinset (fun u => Fintype.piFinset (fun v => Finset.range (c u v + 1))) with hT
  set F := T.filter (fun n => IsFlow cZ (fun u v => (n u v : ℤ)) s t) with hFdef
  have hF : F.Nonempty := by
    refine ⟨0, ?_⟩
    simp [hFdef, hT, IsFlow, hcZ]
  obtain ⟨n, hnF, hmax⟩ := F.exists_max_image (fun n => value (fun u v => (n u v : ℤ)) s) hF
  have hnflow : IsFlow cZ (fun u v => (n u v : ℤ)) s t := (Finset.mem_filter.1 hnF).2
  set nZ : V → V → ℤ := fun u v => (n u v : ℤ) with hnZ
  set r : V → V → Prop := fun u v => 1 ≤ leftover cZ nZ u v with hr
  set S := Finset.univ.filter (fun v => Relation.ReflTransGen r s v) with hS
  have hsS : s ∈ S := by
    rw [hS, Finset.mem_filter]
    exact ⟨Finset.mem_univ _, Relation.ReflTransGen.refl⟩
  have htS : t ∉ S := by
    intro htS
    have hreach : Relation.ReflTransGen r s t := (Finset.mem_filter.1 htS).2
    obtain ⟨p, hh, hl, hp, hc⟩ := exists_nodup_chain r hreach
    obtain ⟨g, hgf, hgv, -⟩ := push_flow cZ nZ s t hst hnflow p hh hl hp 1 zero_le_one hc
    set n' : V → V → ℕ := fun u v => (g u v).toNat with hn'def
    have hn' : ∀ u v, ((n' u v : ℕ) : ℤ) = g u v :=
      fun u v => Int.toNat_of_nonneg (hgf.1 u v).1
    have hgeq : (fun u v => ((n' u v : ℕ) : ℤ)) = g := by
      funext u v; exact hn' u v
    have hn'F : n' ∈ F := by
      rw [hFdef, Finset.mem_filter, hgeq]
      refine ⟨?_, hgf⟩
      rw [hT]
      simp only [Fintype.mem_piFinset, Finset.mem_range]
      intro u v
      have h1 := hn' u v
      have h2 := (hgf.1 u v).2
      simp only [hcZ] at h2
      omega
    have := hmax n' hn'F
    simp only [hgeq] at this
    rw [hgv] at this
    linarith
  have hcross : ∀ x ∈ S, ∀ u ∈ Sᶜ, nZ x u = cZ x u ∧ nZ u x = 0 := by
    intro x hx u hu
    have hnr : ¬ r x u := by
      intro hxu
      rw [Finset.mem_compl] at hu
      apply hu
      rw [hS, Finset.mem_filter] at hx ⊢
      exact ⟨Finset.mem_univ _, hx.2.tail hxu⟩
    simp only [hr, leftover, not_le] at hnr
    have h1 := hnflow.1 x u
    have h2 := hnflow.1 u x
    constructor <;> linarith
  have hvalZ : value nZ s = cutPrice cZ S := by
    rw [value_eq_cross cZ nZ s t hnflow S hsS htS]
    unfold cutPrice
    apply Finset.sum_congr rfl
    intro x hx
    apply Finset.sum_congr rfl
    intro u hu
    rw [(hcross x hx u hu).1, (hcross x hx u hu).2, sub_zero]
  have hflowR : IsFlow (fun u v => (c u v : ℝ)) (fun u v => (n u v : ℝ)) s t := by
    refine ⟨fun u v => ?_, fun x hxs hxt => ?_⟩
    · have h := (hnflow.1 u v).2
      simp only [hnZ, hcZ] at h
      show (0 : ℝ) ≤ (n u v : ℝ) ∧ (n u v : ℝ) ≤ (c u v : ℝ)
      exact ⟨Nat.cast_nonneg _, by exact_mod_cast h⟩
    · have h := hnflow.2 x hxs hxt
      simp only [hnZ] at h
      show ∑ u, (n u x : ℝ) = ∑ u, (n x u : ℝ)
      exact_mod_cast h
  have hvalR : value (fun u v => (n u v : ℝ)) s = cutPrice (fun u v => (c u v : ℝ)) S := by
    have h := hvalZ
    simp only [value, cutPrice, hnZ, hcZ] at h ⊢
    have h' := congrArg (fun z : ℤ => (z : ℝ)) h
    simp only [Int.cast_sub, Int.cast_sum, Int.cast_natCast] at h'
    exact h'
  refine ⟨n, hflowR, fun g hg => ?_, S, hsS, htS, hvalR⟩
  rw [hvalR]
  exact flow_value_le_cut_price _ g s t hg S hsS htS

/-! The card's diamond: the plant `s` is 0, the north depot `A` is 1, the south depot `B` is 2 and
the port `t` is 3. Capacities: 3 on each outer road, 1 on the cross road `A → B`. -/

/-- The diamond's capacities, row `u`, column `v`. -/
def capD : Fin 4 → Fin 4 → ℤ :=
  ![![0, 3, 3, 0], ![0, 0, 1, 3], ![0, 0, 0, 3], ![0, 0, 0, 0]]

/-- A plan on the diamond: loads `a` on s → A, `b` on s → B, `x` on A → t, `y` on B → t and `e` on
the cross road A → B. -/
def plan (a b x y e : ℤ) : Fin 4 → Fin 4 → ℤ :=
  ![![0, a, b, 0], ![0, 0, e, x], ![0, 0, 0, y], ![0, 0, 0, 0]]

-- The final plan, 3 on each outer road and 0 on the cross, is a flow worth 6.
example : IsFlow capD (plan 3 3 3 3 0) 0 3 ∧ value (plan 3 3 3 3 0) 0 = 6 := by decide

-- After 1 load on s-A-B-t: leftover s→A 2, s→B 3, A→t 3, B→t 2, A→B 0,
-- and backward stubs A→s 1, t→B 1, B→A 1.
example : IsFlow capD (plan 1 0 0 1 1) 0 3 ∧ value (plan 1 0 0 1 1) 0 = 1 ∧
    leftover capD (plan 1 0 0 1 1) 0 1 = 2 ∧ leftover capD (plan 1 0 0 1 1) 0 2 = 3 ∧
    leftover capD (plan 1 0 0 1 1) 1 3 = 3 ∧ leftover capD (plan 1 0 0 1 1) 2 3 = 2 ∧
    leftover capD (plan 1 0 0 1 1) 1 2 = 0 ∧ leftover capD (plan 1 0 0 1 1) 1 0 = 1 ∧
    leftover capD (plan 1 0 0 1 1) 3 2 = 1 ∧ leftover capD (plan 1 0 0 1 1) 2 1 = 1 := by
  decide

-- Cross route first, then s-A-t and s-B-t: a flow worth 5 where every road out of s or into t
-- that could still take a load forward is blocked, but the route s-B-A-t has leftover
-- min(1, 1, 1) = 1 by riding the stub B → A.
example : IsFlow capD (plan 3 2 2 3 1) 0 3 ∧ value (plan 3 2 2 3 1) 0 = 5 ∧
    leftover capD (plan 3 2 2 3 1) 0 2 = 1 ∧ leftover capD (plan 3 2 2 3 1) 2 1 = 1 ∧
    leftover capD (plan 3 2 2 3 1) 1 3 = 1 := by
  decide

-- The four splits price 6, 7, 6 and 6.
example : cutPrice capD {0} = 6 ∧ cutPrice capD {0, 1} = 7 ∧ cutPrice capD {0, 2} = 6 ∧
    cutPrice capD {0, 1, 2} = 6 := by
  decide

-- Of the 4 × 4 × 4 × 4 × 2 = 512 whole-number plans within capacity, 25 strand nothing,
-- and none of them is worth more than 6.
set_option maxRecDepth 20000 in
example : ((univ : Finset (Fin 4 × Fin 4 × Fin 4 × Fin 4 × Fin 2)).filter (fun q =>
      IsFlow capD (plan q.1 q.2.1 q.2.2.1 q.2.2.2.1 q.2.2.2.2) 0 3)).card = 25 := by
  decide

set_option maxRecDepth 20000 in
example : ∀ q : Fin 4 × Fin 4 × Fin 4 × Fin 4 × Fin 2,
    IsFlow capD (plan q.1 q.2.1 q.2.2.1 q.2.2.2.1 q.2.2.2.2) 0 3 →
      value (plan q.1 q.2.1 q.2.2.1 q.2.2.2.1 q.2.2.2.2) 0 ≤ 6 := by
  decide

#print axioms push_along_route_keeps_flow_and_adds_bottleneck
#print axioms flow_value_le_cut_price
#print axioms whole_capacities_have_best_whole_flow

end FordFulkerson
