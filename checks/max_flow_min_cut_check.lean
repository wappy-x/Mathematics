-- Max-flow min-cut: in every finite network with capacities at least 0, the largest flow equals the cheapest cut, the side still reachable on leftover when no augmenting route remains is such a cut, and in a two-sided network of capacity 1 the largest flow is the largest pairing.
import Mathlib.Topology.MetricSpace.Pseudo.Lemmas
import Mathlib.Topology.Order.Compact
import Mathlib.Topology.Algebra.Order.Group
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.Group.Subgroup.Defs
import Mathlib.Algebra.BigOperators.Group.Finset.Piecewise
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Sum
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fin.VecNotation
import Mathlib.Logic.Relation
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.DeriveFintype

open Finset

/-! A network has finitely many junctions, a type `V`, and a capacity `c u v` on the road from
`u` to `v` (0 where there is no road). A flow `f` puts `f u v` loads on that road, between 0 and
the capacity, and every junction other than the source `s` and the sink `t` passes on exactly
what it receives. Its value `|f|` is the net count leaving `s`. A cut is a side `S` holding `s`
and not `t`; its price adds the capacities of the roads leaving `S`. The definitions take any
number system `β`, so the worked examples can run on whole numbers; the theorems use `ℝ`. -/

section Defs
variable {V β : Type*} [Fintype V]

/-- `f` is a flow from `s` to `t` within the capacities `c`. -/
def IsFlow [AddCommMonoid β] [LE β] (c : V → V → β) (s t : V) (f : V → V → β) : Prop :=
  (∀ u v, 0 ≤ f u v ∧ f u v ≤ c u v) ∧ ∀ v, v ≠ s → v ≠ t → ∑ u, f u v = ∑ w, f v w

/-- The value of a flow: loads leaving the source minus loads coming back into it. -/
def flowValue [AddCommGroup β] (s : V) (f : V → V → β) : β :=
  ∑ v, f s v - ∑ v, f v s

/-- A cut: a side `S` holding the source and not the sink. -/
def IsCut (s t : V) (S : Finset V) : Prop := s ∈ S ∧ t ∉ S

/-- The price of a cut: the capacities of the roads leaving `S`, `c(S,T)` on the card. -/
def cutCap [AddCommMonoid β] [DecidableEq V] (c : V → V → β) (S : Finset V) : β :=
  ∑ u ∈ S, ∑ v ∈ Sᶜ, c u v

/-- Leftover on the step `u → v`: spare capacity plus any load on `v → u` a push could cancel. -/
def residual [AddCommGroup β] (c f : V → V → β) (u v : V) : β := c u v - f u v + f v u

/-- `v` can be reached from `s` by steps that each have leftover above 0. An augmenting route
exists exactly when the sink can be reached this way. -/
def ResidualReach [AddCommGroup β] [LT β] (c f : V → V → β) (s v : V) : Prop :=
  Relation.ReflTransGen (fun a b => 0 < residual c f a b) s v

open Classical in
/-- The junctions still reachable from the source on leftover: `R` on the card. -/
noncomputable def reachableSide [AddCommGroup β] [LT β] (c f : V → V → β) (s : V) : Finset V :=
  univ.filter fun v => ResidualReach c f s v

instance [AddCommMonoid β] [LE β] [DecidableEq V] [DecidableEq β] [DecidableLE β]
    (c : V → V → β) (s t : V) (f : V → V → β) : Decidable (IsFlow c s t f) := by
  unfold IsFlow; infer_instance

instance [DecidableEq V] (s t : V) (S : Finset V) : Decidable (IsCut s t S) := by
  unfold IsCut; infer_instance

end Defs

/-! Helper lemmas for the proofs below. -/

section Helpers
variable {V : Type*} [Fintype V] [DecidableEq V]

/-- Net inflow at a junction: loads in minus loads out. -/
def netIn (g : V → V → ℝ) (x : V) : ℝ := ∑ u, g u x - ∑ w, g x w

/-- Reachable from `s` on leftover in at most `n` steps. -/
def resReachN (c f : V → V → ℝ) (s : V) : ℕ → V → Prop
  | 0, v => v = s
  | n + 1, v => resReachN c f s n v ∨ ∃ u, resReachN c f s n u ∧ 0 < residual c f u v

lemma flow_across_cut (c : V → V → ℝ) (s t : V) (g : V → V → ℝ) (hg : IsFlow c s t g)
    (S : Finset V) (hS : IsCut s t S) :
    flowValue s g = ∑ u ∈ S, ∑ v ∈ Sᶜ, (g u v - g v u) := by
  have h1 : ∑ u ∈ S, (∑ v, g u v - ∑ v, g v u) = flowValue s g := by
    rw [Finset.sum_eq_single_of_mem s hS.1]
    · rfl
    · intro u hu hus
      rw [hg.2 u hus (fun h => hS.2 (h ▸ hu))]
      ring
  have h2 : ∑ u ∈ S, ∑ v ∈ S, (g u v - g v u) = 0 := by
    have : ∑ u ∈ S, ∑ v ∈ S, g v u = ∑ u ∈ S, ∑ v ∈ S, g u v := Finset.sum_comm
    simp [Finset.sum_sub_distrib, this]
  rw [← h1]
  have h3 : ∀ u, ∑ v, g u v - ∑ v, g v u = ∑ v ∈ S, (g u v - g v u) + ∑ v ∈ Sᶜ, (g u v - g v u) := by
    intro u
    rw [Finset.sum_add_sum_compl S (fun v => g u v - g v u), Finset.sum_sub_distrib]
  simp only [h3, Finset.sum_add_distrib, h2, zero_add]

lemma flow_le_cut (c : V → V → ℝ) (s t : V) (g : V → V → ℝ) (hg : IsFlow c s t g)
    (S : Finset V) (hS : IsCut s t S) : flowValue s g ≤ cutCap c S := by
  rw [flow_across_cut c s t g hg S hS, cutCap]
  refine Finset.sum_le_sum fun u _ => Finset.sum_le_sum fun v _ => ?_
  linarith [(hg.1 u v).2, (hg.1 v u).1]

lemma certificate (c : V → V → ℝ) (s t : V) (f : V → V → ℝ) (hf : IsFlow c s t f)
    (hno : ¬ ResidualReach c f s t) :
    IsCut s t (reachableSide c f s) ∧ flowValue s f = cutCap c (reachableSide c f s) ∧
      (∀ g, IsFlow c s t g → flowValue s g ≤ flowValue s f) ∧
      ∀ S : Finset V, IsCut s t S → cutCap c (reachableSide c f s) ≤ cutCap c S := by
  classical
  have hcut : IsCut s t (reachableSide c f s) := by
    refine ⟨?_, ?_⟩
    · show s ∈ reachableSide c f s
      unfold reachableSide
      exact Finset.mem_filter.2 ⟨Finset.mem_univ _, Relation.ReflTransGen.refl⟩
    · simpa [reachableSide] using hno
  have heq : flowValue s f = cutCap c (reachableSide c f s) := by
    rw [flow_across_cut c s t f hf _ hcut, cutCap]
    refine Finset.sum_congr rfl fun u hu => Finset.sum_congr rfl fun v hv => ?_
    have hu' : ResidualReach c f s u := by simpa [reachableSide] using hu
    have hv' : ¬ ResidualReach c f s v := by simpa [reachableSide] using hv
    have hr : ¬ 0 < residual c f u v := fun h => hv' (Relation.ReflTransGen.tail hu' h)
    have h1 := hf.1 u v
    have h2 := hf.1 v u
    simp only [residual, not_lt] at hr
    have : f v u = 0 := by linarith
    have : f u v = c u v := by linarith
    simp [*]
  refine ⟨hcut, heq, fun g hg => heq ▸ flow_le_cut c s t g hg _ hcut, fun S hS => ?_⟩
  rw [← heq]
  exact flow_le_cut c s t f hf S hS

omit [Fintype V] [DecidableEq V] in
lemma reach_exists_n (c f : V → V → ℝ) (s v : V) (h : ResidualReach c f s v) :
    ∃ n, resReachN c f s n v := by
  induction h with
  | refl => exact ⟨0, rfl⟩
  | tail _ hbc ih =>
    obtain ⟨n, hn⟩ := ih
    exact ⟨n + 1, Or.inr ⟨_, hn, hbc⟩⟩

lemma augment_aux (c f : V → V → ℝ) (s : V) (hf : ∀ a b, 0 ≤ f a b ∧ f a b ≤ c a b)
    (δ : ℝ) (hδ : 0 ≤ δ) (hres : ∀ a b, 0 < residual c f a b → δ ≤ residual c f a b)
    (A : AddSubgroup ℝ) (hfA : ∀ a b, f a b ∈ A) (hδA : δ ∈ A) :
    ∀ n v, resReachN c f s n v → ∃ g : V → V → ℝ, (∀ a b, 0 ≤ g a b ∧ g a b ≤ c a b) ∧
      (∀ x, netIn g x = netIn f x +
        δ * ((if x = v then 1 else 0) - (if x = s then 1 else 0))) ∧
      (∀ a b, g a b ≠ f a b → resReachN c f s n a ∧ resReachN c f s n b) ∧
      ∀ a b, g a b ∈ A := by
  intro n
  induction n with
  | zero =>
    intro v hv
    have hv' : v = s := hv
    subst hv'
    exact ⟨f, hf, fun x => by simp, fun a b h => absurd rfl h, hfA⟩
  | succ n ih =>
    intro v hv
    by_cases hvn : resReachN c f s n v
    · obtain ⟨g, hcap, hnet, hsupp, hA⟩ := ih v hvn
      exact ⟨g, hcap, hnet, fun a b h => ⟨Or.inl (hsupp a b h).1, Or.inl (hsupp a b h).2⟩, hA⟩
    rcases hv with hv | ⟨u, hu, hr⟩
    · exact absurd hv hvn
    obtain ⟨g, hcap, hnet, hsupp, hA⟩ := ih u hu
    have huv : u ≠ v := fun h => hvn (h ▸ hu)
    have hguv : g u v = f u v := by
      by_contra h
      exact hvn (hsupp u v h).2
    have hgvu : g v u = f v u := by
      by_contra h
      exact hvn (hsupp v u h).1
    have hδr : δ ≤ c u v - g u v + g v u := by
      have := hres u v hr
      simp only [residual] at this
      rw [hguv, hgvu]
      exact this
    set y := min δ (g v u) with hy
    have hy0 : 0 ≤ y := le_min hδ (hcap v u).1
    have hyδ : y ≤ δ := min_le_left _ _
    have hyg : y ≤ g v u := min_le_right _ _
    have hx : δ - y ≤ c u v - g u v := by
      rcases min_choice δ (g v u) with h | h
      · rw [← hy] at h
        rw [h]
        linarith [(hcap u v).2]
      · rw [← hy] at h
        rw [h]
        linarith
    refine ⟨fun a b => g a b + (if a = u ∧ b = v then δ - y else 0) -
      (if a = v ∧ b = u then y else 0), ?_, ?_, ?_, ?_⟩
    · intro a b
      by_cases h1 : a = u ∧ b = v
      · obtain ⟨rfl, rfl⟩ := h1
        have h2 : ¬ (a = b ∧ b = a) := fun h => huv h.1
        simp only [and_self, ite_true, h2, ite_false]
        constructor <;> linarith [(hcap a b).1]
      · by_cases h2 : a = v ∧ b = u
        · obtain ⟨rfl, rfl⟩ := h2
          simp only [h1, ite_false, and_self, ite_true]
          constructor <;> linarith [(hcap a b).2]
        · simp only [h1, h2, ite_false]
          simpa using hcap a b
    · intro x
      have key : netIn (fun a b => g a b + (if a = u ∧ b = v then δ - y else 0) -
          (if a = v ∧ b = u then y else 0)) x =
          netIn g x + δ * ((if x = v then 1 else 0) - (if x = u then 1 else 0)) := by
        simp only [netIn, Finset.sum_add_distrib, Finset.sum_sub_distrib, ite_and,
          Finset.sum_ite_eq', Finset.mem_univ, ite_true]
        by_cases hxu : x = u
        · subst hxu
          simp [huv]
          ring
        · by_cases hxv : x = v
          · subst hxv
            simp [hxu]
            ring
          · simp [hxu, hxv]
      rw [key, hnet x]
      ring
    · intro a b h
      by_cases h1 : a = u ∧ b = v
      · obtain ⟨rfl, rfl⟩ := h1
        exact ⟨Or.inl hu, Or.inr ⟨a, hu, hr⟩⟩
      · by_cases h2 : a = v ∧ b = u
        · obtain ⟨rfl, rfl⟩ := h2
          exact ⟨Or.inr ⟨b, hu, hr⟩, Or.inl hu⟩
        · simp only [h1, h2, ite_false, add_zero, sub_zero] at h
          exact ⟨Or.inl (hsupp a b h).1, Or.inl (hsupp a b h).2⟩
    · intro a b
      have hyA : y ∈ A := by
        rcases min_choice δ (g v u) with h | h
        · rw [← hy] at h; rw [h]; exact hδA
        · rw [← hy] at h; rw [h]; exact hA v u
      refine A.sub_mem (A.add_mem (hA a b) ?_) ?_
      · split_ifs
        · exact A.sub_mem hδA hyA
        · exact A.zero_mem
      · split_ifs
        · exact hyA
        · exact A.zero_mem

lemma augment (c f : V → V → ℝ) (s t : V) (hst : s ≠ t) (hf : IsFlow c s t f)
    (δ : ℝ) (hδ : 0 ≤ δ) (hres : ∀ a b, 0 < residual c f a b → δ ≤ residual c f a b)
    (A : AddSubgroup ℝ) (hfA : ∀ a b, f a b ∈ A) (hδA : δ ∈ A)
    (hreach : ResidualReach c f s t) :
    ∃ g, IsFlow c s t g ∧ flowValue s g = flowValue s f + δ ∧ ∀ a b, g a b ∈ A := by
  obtain ⟨n, hn⟩ := reach_exists_n c f s t hreach
  obtain ⟨g, hcap, hnet, -, hA⟩ := augment_aux c f s hf.1 δ hδ hres A hfA hδA n t hn
  refine ⟨g, ⟨hcap, fun v hvs hvt => ?_⟩, ?_, hA⟩
  · have h1 := hnet v
    have h2 := hf.2 v hvs hvt
    simp only [netIn, hvs, hvt, ite_false, mul_zero, add_zero, h2, sub_self] at h1
    linarith
  · have h1 := hnet s
    simp only [netIn, hst, ite_false, ite_true, zero_sub] at h1
    simp only [flowValue]
    linarith

omit [DecidableEq V] in
lemma exists_delta (c f : V → V → ℝ) :
    ∃ δ : ℝ, 0 < δ ∧ ∀ a b, 0 < residual c f a b → δ ≤ residual c f a b := by
  classical
  let S := (Finset.univ : Finset (V × V)).filter fun p => 0 < residual c f p.1 p.2
  by_cases hS : S.Nonempty
  · obtain ⟨p, hp, hmin⟩ := S.exists_min_image (fun p => residual c f p.1 p.2) hS
    exact ⟨_, (Finset.mem_filter.1 hp).2, fun a b hab => hmin (a, b) (by simp [S, hab])⟩
  · exact ⟨1, one_pos, fun a b hab => absurd ⟨(a, b), by simp [S, hab]⟩ hS⟩

omit [Fintype V] [DecidableEq V] in
lemma continuous_finset_sum_aux (T : Finset V) (φ : V → (V → V → ℝ) → ℝ)
    (hφ : ∀ v, Continuous (φ v)) : Continuous fun g => ∑ v ∈ T, φ v g := by
  classical
  induction T using Finset.induction_on with
  | empty => simpa using continuous_const
  | insert a T ha ih =>
    simp only [Finset.sum_insert ha]
    exact (hφ a).add ih

end Helpers

#print axioms flow_across_cut
#print axioms flow_le_cut
#print axioms certificate
#print axioms reach_exists_n
#print axioms augment_aux
#print axioms augment
#print axioms exists_delta
#print axioms continuous_finset_sum_aux

/-- Max-flow min-cut (Ford and Fulkerson, 1956). In a network with finitely many junctions, a
source different from the sink and every capacity at least 0 (real numbers allowed), a largest
flow and a cheapest cut both exist and they are the same number: the most that can be pushed
from source to sink equals the cheapest price of a cut. -/
theorem max_flow_eq_min_cut {V : Type*} [Fintype V] [DecidableEq V] (c : V → V → ℝ)
    (hc : ∀ u v, 0 ≤ c u v) (s t : V) (hst : s ≠ t) :
    ∃ m : ℝ, IsGreatest {x | ∃ f, IsFlow c s t f ∧ x = flowValue s f} m ∧
      IsLeast {x | ∃ S : Finset V, IsCut s t S ∧ x = cutCap c S} m := by
  let F : Set (V → V → ℝ) := {f | IsFlow c s t f}
  have hsub : F ⊆ Set.univ.pi fun u => Set.univ.pi fun v => Set.Icc 0 (c u v) := by
    intro f hf
    simp only [Set.mem_pi, Set.mem_univ, forall_const, Set.mem_Icc]
    exact hf.1
  have hcont : ∀ x y : V, Continuous fun g : V → V → ℝ => g x y := fun x y =>
    (continuous_apply y).comp (continuous_apply x)
  have hclosed : IsClosed F := by
    show IsClosed {f : V → V → ℝ | (∀ u v, 0 ≤ f u v ∧ f u v ≤ c u v) ∧
      ∀ v, v ≠ s → v ≠ t → ∑ u, f u v = ∑ w, f v w}
    simp only [Set.ofPred_and, Set.ofPred_forall]
    refine IsClosed.inter (isClosed_iInter fun u => isClosed_iInter fun v =>
      (isClosed_le continuous_const (hcont u v)).inter
        (isClosed_le (hcont u v) continuous_const)) ?_
    exact isClosed_iInter fun v => isClosed_iInter fun _ => isClosed_iInter fun _ =>
      isClosed_eq (continuous_finset_sum_aux _ _ fun u => hcont u v)
        (continuous_finset_sum_aux _ _ fun w => hcont v w)
  have hcomp : IsCompact F :=
    (isCompact_univ_pi fun u => isCompact_univ_pi fun v => isCompact_Icc).of_isClosed_subset
      hclosed hsub
  have hzero : IsFlow c s t 0 :=
    ⟨fun u v => ⟨le_refl _, hc u v⟩, fun v _ _ => by simp⟩
  have hvc : Continuous fun g : V → V → ℝ => flowValue s g :=
    (continuous_finset_sum_aux _ _ fun v => hcont s v).sub
      (continuous_finset_sum_aux _ _ fun v => hcont v s)
  obtain ⟨f, hfF, hmax⟩ := hcomp.exists_isMaxOn ⟨0, hzero⟩ hvc.continuousOn
  have hf : IsFlow c s t f := hfF
  have hno : ¬ ResidualReach c f s t := by
    intro hr
    obtain ⟨δ, hδ, hres⟩ := exists_delta c f
    obtain ⟨g, hg, hval, -⟩ :=
      augment c f s t hst hf δ hδ.le hres
        { carrier := Set.univ, add_mem' := fun _ _ => trivial, zero_mem' := trivial,
          neg_mem' := fun _ => trivial } (fun _ _ => trivial) trivial hr
    have : flowValue s g ≤ flowValue s f := hmax (show g ∈ F from hg)
    linarith
  obtain ⟨hcut, heq, hfmax, hcmin⟩ := certificate c s t f hf hno
  refine ⟨flowValue s f, ⟨⟨f, hf, rfl⟩, ?_⟩, ⟨⟨_, hcut, heq⟩, ?_⟩⟩
  · rintro x ⟨g, hg, rfl⟩
    exact hfmax g hg
  · rintro x ⟨S, hS, rfl⟩
    rw [heq]
    exact hcmin S hS

/-- The certificate. If a flow leaves no augmenting route (the sink cannot be reached from the
source on leftover), then the junctions still reachable from the source form a cut, its price
equals the flow's value, no flow is larger and no cut is cheaper. -/
theorem no_augmenting_route_reachable_side_is_min_cut {V : Type*} [Fintype V] [DecidableEq V]
    (c : V → V → ℝ) (hc : ∀ u v, 0 ≤ c u v) (s t : V) (f : V → V → ℝ) (hf : IsFlow c s t f)
    (hno : ¬ ResidualReach c f s t) :
    IsCut s t (reachableSide c f s) ∧ flowValue s f = cutCap c (reachableSide c f s) ∧
      (∀ g, IsFlow c s t g → flowValue s g ≤ flowValue s f) ∧
      ∀ S : Finset V, IsCut s t S → cutCap c (reachableSide c f s) ≤ cutCap c S := by
  exact certificate c s t f hf hno

/-! Pairing as a flow. Volunteers form a finite type `P`, tasks a finite type `J`, and `r p j`
says volunteer `p` can do task `j`. The network has a source, one junction per volunteer, one per
task, and a sink; roads of capacity 1 run from the source to every volunteer, from each volunteer
to each task that volunteer can do, and from every task to the sink. -/

/-- The junctions of the pairing network. -/
inductive Node (P J : Type*)
  | src
  | vol (p : P)
  | task (j : J)
  | sink
  deriving DecidableEq, Fintype

/-- Capacity 1 on the roads source → volunteer, volunteer → task they can do, task → sink;
0 everywhere else. -/
def unitCap {P J β : Type*} [Zero β] [One β] (r : P → J → Prop) [DecidableRel r] :
    Node P J → Node P J → β
  | .src, .vol _ => 1
  | .vol p, .task j => if r p j then 1 else 0
  | .task _, .sink => 1
  | _, _ => 0

/-- A pairing: a set of (volunteer, task) pairs, each one a can-do line, with no volunteer and
no task used twice. -/
def IsPairing {P J : Type*} (r : P → J → Prop) (M : Finset (P × J)) : Prop :=
  (∀ e ∈ M, r e.1 e.2) ∧ (∀ a ∈ M, ∀ b ∈ M, a.1 = b.1 → a = b) ∧
    (∀ a ∈ M, ∀ b ∈ M, a.2 = b.2 → a = b)

instance {P J : Type*} [DecidableEq P] [DecidableEq J] (r : P → J → Prop) [DecidableRel r]
    (M : Finset (P × J)) : Decidable (IsPairing r M) := by
  unfold IsPairing; infer_instance

/-! Helper lemmas for the pairing theorem below. -/

section PairingHelpers
variable {P J : Type*}

/-- The junctions of the pairing network, listed as a sum type. -/
def nodeEquiv : (Unit ⊕ P) ⊕ (J ⊕ Unit) ≃ Node P J where
  toFun
    | .inl (.inl _) => .src
    | .inl (.inr p) => .vol p
    | .inr (.inl j) => .task j
    | .inr (.inr _) => .sink
  invFun
    | .src => .inl (.inl ())
    | .vol p => .inl (.inr p)
    | .task j => .inr (.inl j)
    | .sink => .inr (.inr ())
  left_inv := by rintro ((_ | _) | (_ | _)) <;> rfl
  right_inv := by rintro (_ | _ | _ | _) <;> rfl

lemma node_sum [Fintype P] [Fintype J] (F : Node P J → ℝ) :
    ∑ v, F v = F .src + ∑ p, F (.vol p) + ∑ j, F (.task j) + F .sink := by
  rw [← (nodeEquiv (P := P) (J := J)).sum_comp F]
  simp [Fintype.sum_sum_type, nodeEquiv]
  ring

/-- The whole numbers inside the reals, as an additive subgroup. -/
def intSub : AddSubgroup ℝ where
  carrier := {x | ∃ z : ℤ, (z : ℝ) = x}
  add_mem' := by
    rintro _ _ ⟨a, rfl⟩ ⟨b, rfl⟩
    exact ⟨a + b, by push_cast; ring⟩
  zero_mem' := ⟨0, by simp⟩
  neg_mem' := by
    rintro _ ⟨a, rfl⟩
    exact ⟨-a, by push_cast; ring⟩

lemma mem_intSub (x : ℝ) : x ∈ intSub ↔ ∃ z : ℤ, (z : ℝ) = x := Iff.rfl

lemma unitCap_cases (r : P → J → Prop) [DecidableRel r] (a b : Node P J) :
    (unitCap r a b : ℝ) = 0 ∨ (unitCap r a b : ℝ) = 1 := by
  rcases a with _ | p | j | _ <;> rcases b with _ | q | k | _ <;> simp [unitCap]
  all_goals tauto

lemma unitCap_nonneg (r : P → J → Prop) [DecidableRel r] (a b : Node P J) :
    0 ≤ (unitCap r a b : ℝ) := by
  rcases unitCap_cases r a b with h | h <;> simp [h]

lemma unitCap_le_one (r : P → J → Prop) [DecidableRel r] (a b : Node P J) :
    (unitCap r a b : ℝ) ≤ 1 := by
  rcases unitCap_cases r a b with h | h <;> simp [h]

lemma unitCap_mem (r : P → J → Prop) [DecidableRel r] (a b : Node P J) :
    (unitCap r a b : ℝ) ∈ intSub := by
  rcases unitCap_cases r a b with h | h
  · exact ⟨0, by simp [h]⟩
  · exact ⟨1, by simp [h]⟩

/-- The flow carried by a pairing: one load along each chosen pair. -/
def matchFlow [Fintype P] [Fintype J] [DecidableEq P] [DecidableEq J] (M : Finset (P × J)) :
    Node P J → Node P J → ℝ
  | .src, .vol p => ∑ j, if (p, j) ∈ M then 1 else 0
  | .vol p, .task j => if (p, j) ∈ M then 1 else 0
  | .task j, .sink => ∑ p, if (p, j) ∈ M then 1 else 0
  | _, _ => 0

variable [Fintype P] [Fintype J] [DecidableEq P] [DecidableEq J]

omit [Fintype P] in
lemma row_le_one (r : P → J → Prop) (M : Finset (P × J)) (hM : IsPairing r M) (p : P) :
    ∑ j, (if (p, j) ∈ M then (1 : ℝ) else 0) ≤ 1 := by
  rw [Finset.sum_boole]
  have : (Finset.univ.filter fun j => (p, j) ∈ M).card ≤ 1 := by
    refine Finset.card_le_one.2 fun a ha b hb => ?_
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at ha hb
    simpa using congrArg Prod.snd (hM.2.1 _ ha _ hb rfl)
  exact_mod_cast this

omit [Fintype J] in
lemma col_le_one (r : P → J → Prop) (M : Finset (P × J)) (hM : IsPairing r M) (j : J) :
    ∑ p, (if (p, j) ∈ M then (1 : ℝ) else 0) ≤ 1 := by
  rw [Finset.sum_boole]
  have : (Finset.univ.filter fun p => (p, j) ∈ M).card ≤ 1 := by
    refine Finset.card_le_one.2 fun a ha b hb => ?_
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at ha hb
    simpa using congrArg Prod.fst (hM.2.2 _ ha _ hb rfl)
  exact_mod_cast this

lemma matchFlow_isFlow (r : P → J → Prop) [DecidableRel r] (M : Finset (P × J))
    (hM : IsPairing r M) : IsFlow (unitCap r) .src .sink (matchFlow M) := by
  constructor
  · intro a b
    rcases a with _ | p | j | _ <;> rcases b with _ | q | k | _ <;>
      simp only [matchFlow, unitCap, le_refl, and_self]
    · exact ⟨Finset.sum_nonneg fun _ _ => by split_ifs <;> norm_num, row_le_one r M hM q⟩
    · by_cases h : (p, k) ∈ M
      · simp [h, hM.1 _ h]
      · simp only [h, ite_false, le_refl, true_and]
        split_ifs <;> norm_num
    · exact ⟨Finset.sum_nonneg fun _ _ => by split_ifs <;> norm_num, col_le_one r M hM j⟩
  · intro v hs ht
    rcases v with _ | p | j | _
    · exact absurd rfl hs
    · rw [node_sum, node_sum]
      simp [matchFlow]
    · rw [node_sum, node_sum]
      simp [matchFlow]
    · exact absurd rfl ht

lemma matchFlow_value (M : Finset (P × J)) :
    flowValue (.src : Node P J) (matchFlow M) = M.card := by
  unfold flowValue
  rw [node_sum, node_sum]
  simp only [matchFlow, Finset.sum_const_zero, add_zero, zero_add, sub_zero]
  rw [← Fintype.sum_prod_type' (fun p j => if (p, j) ∈ M then (1 : ℝ) else 0)]
  simp

omit [Fintype P] [Fintype J] [DecidableEq P] [DecidableEq J] in
lemma ite_mem_intSub (q : Prop) [Decidable q] : (if q then (1 : ℝ) else 0) ∈ intSub := by
  split_ifs
  · exact ⟨1, by simp⟩
  · exact ⟨0, by simp⟩

omit [Fintype P] [Fintype J] [DecidableEq P] [DecidableEq J] in
lemma sum_mem_intSub {ι : Type*} (s : Finset ι) (φ : ι → ℝ) (h : ∀ i, φ i ∈ intSub) :
    ∑ i ∈ s, φ i ∈ intSub := by
  classical
  induction s using Finset.induction_on with
  | empty => simp
  | insert a s ha ih =>
    rw [Finset.sum_insert ha]
    exact intSub.add_mem (h a) ih

lemma matchFlow_mem (M : Finset (P × J)) (a b : Node P J) : matchFlow M a b ∈ intSub := by
  rcases a with _ | p | j | _ <;> rcases b with _ | q | k | _ <;> simp only [matchFlow] <;>
    first
    | exact intSub.zero_mem
    | exact sum_mem_intSub _ _ fun _ => ite_mem_intSub _
    | exact ite_mem_intSub _


lemma pairing_of_int_flow (r : P → J → Prop) [DecidableRel r] (g : Node P J → Node P J → ℝ)
    (hg : IsFlow (unitCap r) .src .sink g) (hint : ∀ a b, g a b ∈ intSub) :
    ∃ M : Finset (P × J), IsPairing r M ∧ (M.card : ℝ) = flowValue .src g := by
  classical
  have h01 : ∀ a b, g a b = 0 ∨ g a b = 1 := by
    intro a b
    obtain ⟨z, hz⟩ := hint a b
    have h1 := (hg.1 a b).1
    have h2 := (hg.1 a b).2.trans (unitCap_le_one r a b)
    rw [← hz] at h1 h2 ⊢
    have hz0 : (0 : ℤ) ≤ z := by exact_mod_cast h1
    have hz1 : z ≤ 1 := by exact_mod_cast h2
    rcases (by omega : z = 0 ∨ z = 1) with rfl | rfl <;> simp
  have hzero : ∀ a b, (unitCap r a b : ℝ) = 0 → g a b = 0 := fun a b h =>
    le_antisymm (h ▸ (hg.1 a b).2) (hg.1 a b).1
  have zA : ∀ x, g x .src = 0 := fun x => hzero _ _ (by rcases x with _ | _ | _ | _ <;> rfl)
  have zB : ∀ x, g .sink x = 0 := fun x => hzero _ _ (by rcases x with _ | _ | _ | _ <;> rfl)
  have zC : ∀ p q, g (.vol p) (.vol q) = 0 := fun _ _ => hzero _ _ rfl
  have zD : ∀ p, g (.vol p) .sink = 0 := fun _ => hzero _ _ rfl
  have zE : ∀ j k, g (.task j) (.task k) = 0 := fun _ _ => hzero _ _ rfl
  have zF : ∀ j p, g (.task j) (.vol p) = 0 := fun _ _ => hzero _ _ rfl
  have zG : ∀ j, g .src (.task j) = 0 := fun _ => hzero _ _ rfl
  have zH : g .src .sink = 0 := hzero _ _ rfl
  have hvol : ∀ p, ∑ j, g (.vol p) (.task j) = g .src (.vol p) := by
    intro p
    have := hg.2 (.vol p) (by simp) (by simp)
    rw [node_sum, node_sum] at this
    simp only [zA, zB, zC, zD, zF, Finset.sum_const_zero, add_zero, zero_add] at this
    exact this.symm
  have htask : ∀ j, ∑ p, g (.vol p) (.task j) = g (.task j) .sink := by
    intro j
    have := hg.2 (.task j) (by simp) (by simp)
    rw [node_sum, node_sum] at this
    simp only [zA, zB, zE, zF, zG, Finset.sum_const_zero, add_zero, zero_add] at this
    exact this
  let M : Finset (P × J) := Finset.univ.filter fun e => g (.vol e.1) (.task e.2) = 1
  have hmem : ∀ e, e ∈ M ↔ g (.vol e.1) (.task e.2) = 1 := fun e => by simp [M]
  have hnn : ∀ a b, 0 ≤ g a b := fun a b => (hg.1 a b).1
  refine ⟨M, ⟨?_, ?_, ?_⟩, ?_⟩
  · intro e he
    by_contra hr
    have h0 : g (.vol e.1) (.task e.2) = 0 := hzero _ _ (by simp [unitCap, hr])
    rw [(hmem e).1 he] at h0
    norm_num at h0
  · intro a ha b hb hab
    by_contra hne
    have hne2 : a.2 ≠ b.2 := fun h => hne (Prod.ext hab h)
    have hle : ∑ j ∈ {a.2, b.2}, g (.vol a.1) (.task j) ≤ ∑ j, g (.vol a.1) (.task j) :=
      Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _) fun _ _ _ => hnn _ _
    rw [Finset.sum_pair hne2, hvol, (hmem a).1 ha, hab, (hmem b).1 hb] at hle
    have hcap := (hg.1 .src (.vol b.1)).2
    have h1 : (unitCap r .src (.vol b.1) : ℝ) = 1 := rfl
    linarith
  · intro a ha b hb hab
    by_contra hne
    have hne1 : a.1 ≠ b.1 := fun h => hne (Prod.ext h hab)
    have hle : ∑ p ∈ {a.1, b.1}, g (.vol p) (.task a.2) ≤ ∑ p, g (.vol p) (.task a.2) :=
      Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _) fun _ _ _ => hnn _ _
    rw [Finset.sum_pair hne1, htask, (hmem a).1 ha, hab, (hmem b).1 hb] at hle
    have hcap := (hg.1 (.task b.2) .sink).2
    have h1 : (unitCap r (.task b.2) .sink : ℝ) = 1 := rfl
    linarith
  · unfold flowValue
    rw [node_sum, node_sum]
    simp only [zA, zG, zH, Finset.sum_const_zero, add_zero, zero_add, sub_zero]
    simp only [← hvol]
    rw [← Fintype.sum_prod_type' (fun p j => g (.vol p) (.task j))]
    have : ∀ e : P × J, g (.vol e.1) (.task e.2) = if e ∈ M then 1 else 0 := by
      intro e
      rcases h01 (.vol e.1) (.task e.2) with h | h
      · have : e ∉ M := by rw [hmem]; rw [h]; norm_num
        simp [h, this]
      · simp [h, (hmem e).2 h]
    simp only [this, Finset.sum_boole]
    simp

end PairingHelpers

#print axioms node_sum
#print axioms mem_intSub
#print axioms unitCap_cases
#print axioms unitCap_nonneg
#print axioms unitCap_le_one
#print axioms unitCap_mem
#print axioms row_le_one
#print axioms col_le_one
#print axioms matchFlow_isFlow
#print axioms matchFlow_value
#print axioms ite_mem_intSub
#print axioms sum_mem_intSub
#print axioms matchFlow_mem
#print axioms pairing_of_int_flow

/-- Matching is a flow. With finitely many volunteers and tasks, and every can-do line running
from a volunteer to a task, the largest flow through the capacity-1 network is a whole number,
and it equals the size of the largest pairing. -/
theorem max_flow_eq_max_pairing {P J : Type*} [Fintype P] [Fintype J] [DecidableEq P]
    [DecidableEq J] (r : P → J → Prop) [DecidableRel r] :
    ∃ k : ℕ, IsGreatest {x : ℝ | ∃ f, IsFlow (unitCap r) .src .sink f ∧ x = flowValue .src f}
        (k : ℝ) ∧
      IsGreatest {n : ℕ | ∃ M : Finset (P × J), IsPairing r M ∧ M.card = n} k := by
  obtain ⟨M0, hM0, hmax⟩ :=
    (Finset.univ.filter fun M : Finset (P × J) => IsPairing r M).exists_max_image Finset.card
      ⟨∅, Finset.mem_filter.2 ⟨Finset.mem_univ _, by simp [IsPairing]⟩⟩
  have hM0' : IsPairing r M0 := (Finset.mem_filter.1 hM0).2
  have hmax' : ∀ M, IsPairing r M → M.card ≤ M0.card := fun M hM =>
    hmax M (Finset.mem_filter.2 ⟨Finset.mem_univ _, hM⟩)
  have hf0 := matchFlow_isFlow r M0 hM0'
  have hv0 := matchFlow_value (P := P) (J := J) M0
  have hno : ¬ ResidualReach (unitCap r) (matchFlow M0) .src .sink := by
    intro hreach
    have hres : ∀ a b, 0 < residual (unitCap r) (matchFlow M0) a b →
        1 ≤ residual (unitCap r) (matchFlow M0) a b := by
      intro a b h
      obtain ⟨z, hz⟩ : residual (unitCap r) (matchFlow M0) a b ∈ intSub :=
        intSub.add_mem (intSub.sub_mem (unitCap_mem r a b) (matchFlow_mem M0 a b))
          (matchFlow_mem M0 b a)
      rw [← hz] at h ⊢
      have : (0 : ℤ) < z := by exact_mod_cast h
      exact_mod_cast (show (1 : ℤ) ≤ z by omega)
    obtain ⟨g, hg, hval, hgA⟩ := augment (unitCap r) (matchFlow M0) .src .sink (by simp) hf0 1
      zero_le_one hres intSub (matchFlow_mem M0) ⟨1, by simp⟩ hreach
    obtain ⟨M, hM, hcard⟩ := pairing_of_int_flow r g hg hgA
    have h1 := hmax' M hM
    rw [hval, hv0] at hcard
    have h2 : (M.card : ℝ) ≤ M0.card := by exact_mod_cast h1
    linarith
  obtain ⟨-, -, hfmax, -⟩ := certificate (unitCap r) .src .sink (matchFlow M0) hf0 hno
  refine ⟨M0.card, ⟨⟨matchFlow M0, hf0, hv0.symm⟩, ?_⟩, ⟨⟨M0, hM0', rfl⟩, ?_⟩⟩
  · rintro x ⟨g, hg, rfl⟩
    rw [← hv0]
    exact hfmax g hg
  · rintro n ⟨M, hM, rfl⟩
    exact hmax' M hM

/-! The diamond. Junctions 0, 1, 2, 3 are the plant `s`, the north depot A, the south depot B
and the port `t`. Outer roads carry 3 loads, the cross road A → B carries 1. -/

/-- The diamond's capacities, row `u`, column `v`. -/
def diamond : Fin 4 → Fin 4 → ℤ := ![![0, 3, 3, 0], ![0, 0, 1, 3], ![0, 0, 0, 3], ![0, 0, 0, 0]]

/-- The best plan: 3 on each outer road, nothing on the cross road. -/
def diamondFlow : Fin 4 → Fin 4 → ℤ := ![![0, 3, 3, 0], ![0, 0, 0, 3], ![0, 0, 0, 3], ![0, 0, 0, 0]]

-- The four cuts and their prices: {s} 6, {s,A} 7, {s,B} 6, {s,A,B} 6.
example : cutCap diamond {0} = 6 ∧ cutCap diamond {0, 1} = 7 ∧ cutCap diamond {0, 2} = 6 ∧
    cutCap diamond {0, 1, 2} = 6 := by decide
-- Every cut costs at least 6, and exactly 3 of the 4 cuts cost 6.
example : (univ.filter fun S : Finset (Fin 4) => IsCut 0 3 S).card = 4 ∧
    (∀ S : Finset (Fin 4), IsCut 0 3 S → 6 ≤ cutCap diamond S) ∧
    (univ.filter fun S : Finset (Fin 4) => IsCut 0 3 S ∧ cutCap diamond S = 6).card = 3 := by
  decide
-- The best plan is a flow of value 6, the price of {s}.
example : IsFlow diamond 0 3 diamondFlow ∧ flowValue 0 diamondFlow = 6 ∧
    flowValue 0 diamondFlow = cutCap diamond {0} := by decide
-- After the best plan, no road out of s has leftover, so the reachable side is {s}.
example : ∀ v, v ≠ 0 → residual diamond diamondFlow 0 v ≤ 0 := by decide
-- Mistake 1: the cross road alone is 1, not 6.  Mistake 2: {s,B} priced with A → B is 7, not 6.
example : diamond 1 2 = 1 ∧ cutCap diamond {0, 2} + diamond 1 2 = 7 := by decide

/-! The fun run. Volunteers 0 to 4 are Priya, Omar, Lena, Sam, Tomas; tasks 0 to 4 are
registration, first aid, water, parking, timing. -/

/-- The can-do lists. -/
def canDo : Fin 5 → Finset (Fin 5) := ![{0, 1}, {2, 3}, {1, 4}, {2, 3}, {0}]

/-- The same lists with Priya off first aid. -/
def canDoBroken : Fin 5 → Finset (Fin 5) := ![{0}, {2, 3}, {1, 4}, {2, 3}, {0}]

/-- The pairing the pushing method finds: Priya-first aid, Omar-water, Lena-timing,
Sam-parking, Tomas-registration. -/
def fullPairing : Finset (Fin 5 × Fin 5) := {(0, 1), (1, 2), (2, 4), (3, 3), (4, 0)}

/-- The reachable side once Priya is off first aid: s, Priya, Tomas, registration. -/
def brokenSide : Finset (Node (Fin 5) (Fin 5)) := {.src, .vol 0, .vol 4, .task 0}

-- 19 roads of capacity 1 in the fun-run network, 18 once Priya is off first aid.
example : (univ.filter fun e : Node (Fin 5) (Fin 5) × Node (Fin 5) (Fin 5) =>
    unitCap (fun p j => j ∈ canDo p) e.1 e.2 = (1 : ℤ)).card = 19 := by decide
example : (univ.filter fun e : Node (Fin 5) (Fin 5) × Node (Fin 5) (Fin 5) =>
    unitCap (fun p j => j ∈ canDoBroken p) e.1 e.2 = (1 : ℤ)).card = 18 := by decide
-- The full pairing has 5 pairs, everyone placed.
example : IsPairing (fun p j => j ∈ canDo p) fullPairing ∧ fullPairing.card = 5 := by decide
-- Priya off first aid: the reachable side is a cut priced 4.
example : IsCut .src .sink brokenSide ∧
    cutCap (unitCap (fun p j => j ∈ canDoBroken p) : _ → _ → ℤ) brokenSide = 4 := by decide
-- Inside it, Priya and Tomas reach only registration: 2 people, 1 task, and 5 - 2 + 1 = 4.
example : ({0, 4} : Finset (Fin 5)).biUnion canDoBroken = {0} := by decide
example : 5 - 2 + 1 = 4 := by norm_num
-- Priya off first aid: no group of volunteers is short by more than 1, and some group is.
example : (∀ X : Finset (Fin 5), X.card ≤ (X.biUnion canDoBroken).card + 1) ∧
    ∃ X : Finset (Fin 5), X.card = (X.biUnion canDoBroken).card + 1 := by decide

#print axioms max_flow_eq_min_cut
#print axioms no_augmenting_route_reachable_side_is_min_cut
#print axioms max_flow_eq_max_pairing
