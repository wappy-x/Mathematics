-- Dijkstra's algorithm: on finitely many points joined by one-way roads whose costs are never below zero, settling the cheapest unsettled point and relaxing its roads, round after round until every point is settled, ends with every guess equal to the cheapest route cost from the start, while one negative cost can leave a wrong answer.
import Mathlib.Algebra.Order.Monoid.WithTop
import Mathlib.Data.Fintype.Pi
import Mathlib.Logic.Relation
import Mathlib.Order.Basic

open Finset

variable {V C : Type*} [Fintype V] [DecidableEq V]
  [AddCommMonoid C] [LinearOrder C] [IsOrderedAddMonoid C]

/-- The cost of a route, given as the list of points it passes in order, under the road costs `w`:
`w u v` is the cost of the road from `u` to `v`, and `⊤` means there is no such road. Costs add
along the route; a route with a missing road costs `⊤`, and a one-point route costs `0`. -/
def routeCost (w : V → V → WithTop C) : List V → WithTop C
  | u :: v :: rest => w u v + routeCost w (v :: rest)
  | _ => 0

/-- `c` is the cheapest cost of a route from `s` to `t`: no route from `s` to `t` costs less than
`c`, and when `c` is not `⊤` some route from `s` to `t` costs exactly `c`. (When `c = ⊤`, no route
reaches `t` at all.) -/
def IsCheapest (w : V → V → WithTop C) (s t : V) (c : WithTop C) : Prop :=
  (∀ l : List V, l.head? = some s → l.getLast? = some t → c ≤ routeCost w l) ∧
    (c ≠ ⊤ → ∃ l : List V, l.head? = some s ∧ l.getLast? = some t ∧ routeCost w l = c)

/-- What the procedure remembers: each point's tentative cost `d v` (`⊤` while no route is known)
and the set of settled points. -/
structure State (V C : Type*) where
  d : V → WithTop C
  settled : Finset V

/-- The start: `0` at the start point `s`, `⊤` elsewhere, nothing settled. -/
def start (s : V) : State V C where
  d v := if v = s then 0 else ⊤
  settled := ∅

/-- `u` is an unsettled point whose guess is the smallest among the unsettled points. -/
def IsSmallestUnsettled (st : State V C) (u : V) : Prop :=
  u ∉ st.settled ∧ ∀ x ∉ st.settled, st.d u ≤ st.d x

instance (st : State V C) (u : V) : Decidable (IsSmallestUnsettled st u) :=
  inferInstanceAs (Decidable (_ ∧ _))

/-- One round with chosen point `u`: settle `u`, then relax every road out of `u` to a point still
unsettled, `d[v] ← min (d[v], d[u] + w(u,v))`. -/
def round (w : V → V → WithTop C) (st : State V C) (u : V) : State V C where
  d v := if v ∈ st.settled ∨ v = u then st.d v else min (st.d v) (st.d u + w u v)
  settled := insert u st.settled

/-- One legal round of Dijkstra's procedure: settle some unsettled point of smallest guess (ties
broken any way) and relax its roads. -/
def Settles (w : V → V → WithTop C) (st st' : State V C) : Prop :=
  ∃ u, IsSmallestUnsettled st u ∧ st' = round w st u

omit [Fintype V] [DecidableEq V] in
theorem routeCost_nonneg_aux (w : V → V → WithTop C) (hw : ∀ u v, 0 ≤ w u v) :
    ∀ l : List V, 0 ≤ routeCost w l
  | u :: v :: rest => by
      rw [routeCost]
      exact add_nonneg (hw u v) (routeCost_nonneg_aux w hw (v :: rest))
  | [_] => by simp [routeCost]
  | [] => by simp [routeCost]

omit [Fintype V] [DecidableEq V] [LinearOrder C] [IsOrderedAddMonoid C] in
theorem routeCost_snoc_aux (w : V → V → WithTop C) (v : V) :
    ∀ (l : List V) (a : V), l.getLast? = some a → routeCost w (l ++ [v]) = routeCost w l + w a v := by
  intro l
  induction l with
  | nil => intro a h; simp at h
  | cons x l' ih =>
    intro a h
    cases l' with
    | nil =>
      simp at h
      subst h
      simp [routeCost]
    | cons y l'' =>
      rw [List.getLast?_cons_cons] at h
      have := ih a h
      simp only [List.cons_append] at this ⊢
      rw [routeCost, this, routeCost, add_assoc]

omit [Fintype V] in
theorem reach_unsettled_aux (w : V → V → WithTop C) (hw : ∀ u v, 0 ≤ w u v) (s : V)
    (st : State V C)
    (hlow : ∀ v ∈ st.settled, ∀ l : List V, l.head? = some s → l.getLast? = some v →
      st.d v ≤ routeCost w l)
    (hrel : ∀ x ∈ st.settled, ∀ v ∉ st.settled, st.d v ≤ st.d x + w x v)
    (hsrc : st.d s ≤ 0) :
    ∀ (l : List V) (t : V), l.head? = some s → l.getLast? = some t →
      (∃ y ∉ st.settled, st.d y ≤ routeCost w l) ∨ t ∈ st.settled := by
  intro l
  induction l using List.reverseRecOn with
  | nil => intro t h; simp at h
  | append_singleton l a ih =>
    intro t hh hl
    rw [List.getLast?_concat] at hl
    cases hl
    rcases List.eq_nil_or_concat l with h0 | ⟨l0, b, rfl⟩
    · subst h0
      simp at hh
      subst hh
      by_cases hs : a ∈ st.settled
      · exact Or.inr hs
      · exact Or.inl ⟨a, hs, by simpa [routeCost] using hsrc⟩
    · rw [List.concat_eq_append] at hh ih ⊢
      have hh' : (l0 ++ [b]).head? = some s := by
        simpa [List.head?_append] using hh
      have hlb : (l0 ++ [b]).getLast? = some b := List.getLast?_concat
      have hc := routeCost_snoc_aux w a (l0 ++ [b]) b hlb
      rw [hc]
      rcases ih b hh' hlb with ⟨y, hy, hyle⟩ | hb
      · exact Or.inl ⟨y, hy, le_trans hyle (le_add_of_nonneg_right (hw b a))⟩
      · by_cases ha : a ∈ st.settled
        · exact Or.inr ha
        · refine Or.inl ⟨a, ha, le_trans (hrel b hb a ha) ?_⟩
          exact add_le_add (hlow b hb _ hh' hlb) le_rfl

omit [Fintype V] in
theorem smallest_le_aux (w : V → V → WithTop C) (hw : ∀ u v, 0 ≤ w u v) (s : V)
    (st : State V C)
    (hlow : ∀ v ∈ st.settled, ∀ l : List V, l.head? = some s → l.getLast? = some v →
      st.d v ≤ routeCost w l)
    (hrel : ∀ x ∈ st.settled, ∀ v ∉ st.settled, st.d v ≤ st.d x + w x v)
    (hsrc : st.d s ≤ 0) (u : V) (hu : IsSmallestUnsettled st u) :
    ∀ l : List V, l.head? = some s → l.getLast? = some u → st.d u ≤ routeCost w l := by
  intro l hh hl
  rcases reach_unsettled_aux w hw s st hlow hrel hsrc l u hh hl with ⟨y, hy, hyle⟩ | hs
  · exact le_trans (hu.2 y hy) hyle
  · exact absurd hs hu.1

omit [Fintype V] in
theorem run_invariant_aux (w : V → V → WithTop C) (hw : ∀ u v, 0 ≤ w u v) (s : V)
    (st : State V C) (hrun : Relation.ReflTransGen (Settles w) (start s) st) :
    (∀ v, st.d v ≠ ⊤ → ∃ l : List V, l.head? = some s ∧ l.getLast? = some v ∧
      routeCost w l = st.d v) ∧
    (∀ v ∈ st.settled, ∀ l : List V, l.head? = some s → l.getLast? = some v →
      st.d v ≤ routeCost w l) ∧
    (∀ x ∈ st.settled, ∀ v ∉ st.settled, st.d v ≤ st.d x + w x v) ∧
    st.d s ≤ 0 := by
  induction hrun with
  | refl =>
    refine ⟨?_, ?_, ?_, ?_⟩
    · intro v hv
      by_cases h : v = s
      · subst h
        exact ⟨[v], by simp, by simp, by simp [routeCost, start]⟩
      · simp [start, h] at hv
    · intro v hv; simp [start] at hv
    · intro x hx; simp [start] at hx
    · simp [start]
  | @tail st1 st2 _ hst ih =>
    obtain ⟨hreal, hlow, hrel, hsrc⟩ := ih
    obtain ⟨u, hu, rfl⟩ := hst
    have key := smallest_le_aux w hw s st1 hlow hrel hsrc u hu
    refine ⟨?_, ?_, ?_, ?_⟩
    · intro v hv
      simp only [round] at hv ⊢
      by_cases hc : v ∈ st1.settled ∨ v = u
      · rw [ite_eq_left hc] at hv ⊢
        exact hreal v hv
      · rw [ite_eq_right hc] at hv ⊢
        rcases le_total (st1.d v) (st1.d u + w u v) with hle | hle
        · rw [min_eq_left hle] at hv ⊢
          exact hreal v hv
        · rw [min_eq_right hle] at hv ⊢
          have hdu : st1.d u ≠ ⊤ := by
            intro h; rw [h, WithTop.top_add] at hv; exact hv rfl
          obtain ⟨l, hlh, hll, hlc⟩ := hreal u hdu
          refine ⟨l ++ [v], ?_, List.getLast?_concat, ?_⟩
          · have : l ≠ [] := by rintro rfl; simp at hlh
            rw [List.head?_append_of_ne_nil _ this]; exact hlh
          · rw [routeCost_snoc_aux w v l u hll, hlc]
    · intro v hv l hh hl
      simp only [round] at hv ⊢
      rw [ite_eq_left (by rcases Finset.mem_insert.1 hv with h | h <;> simp [h])]
      rcases Finset.mem_insert.1 hv with h | h
      · subst h; exact key l hh hl
      · exact hlow v h l hh hl
    · intro x hx v hv
      simp only [round] at hx hv ⊢
      have hv1 : v ∉ st1.settled := fun h => hv (Finset.mem_insert_of_mem h)
      have hv2 : v ≠ u := fun h => hv (h ▸ Finset.mem_insert_self _ _)
      rw [ite_eq_right (by simp [hv1, hv2])]
      rw [ite_eq_left (by rcases Finset.mem_insert.1 hx with h | h <;> simp [h])]
      rcases Finset.mem_insert.1 hx with h | h
      · subst h; exact min_le_right _ _
      · exact le_trans (min_le_left _ _) (hrel x h v hv1)
    · simp only [round]
      split_ifs
      · exact hsrc
      · exact le_trans (min_le_left _ _) hsrc

/-- Dijkstra's algorithm. On finitely many points, with road costs that add along a route and are
never below zero, start with `0` at `s` and `⊤` elsewhere, then settle the cheapest unsettled point
and relax its roads, repeating until nothing is unsettled: every point's final guess is the cheapest
cost of a route from `s` to it, however ties were broken. -/
theorem dijkstra_final_guesses_are_cheapest_costs (w : V → V → WithTop C)
    (hw : ∀ u v, 0 ≤ w u v) (s : V) (st : State V C)
    (hrun : Relation.ReflTransGen (Settles w) (start s) st) (hdone : st.settled = univ) (t : V) :
    IsCheapest w s t (st.d t) := by
  obtain ⟨hreal, hlow, _, _⟩ := run_invariant_aux w hw s st hrun
  exact ⟨fun l hh hl => hlow t (by rw [hdone]; exact Finset.mem_univ t) l hh hl, hreal t⟩

/-- The smallest unsettled guess is already the truth. At every moment of a run with no cost below
zero, an unsettled point whose guess is smallest among the unsettled points has as its guess the
cheapest cost of a route from `s` to it, so settling it is safe. -/
theorem smallest_unsettled_guess_is_cheapest (w : V → V → WithTop C)
    (hw : ∀ u v, 0 ≤ w u v) (s : V) (st : State V C)
    (hrun : Relation.ReflTransGen (Settles w) (start s) st) (u : V)
    (hu : IsSmallestUnsettled st u) :
    IsCheapest w s u (st.d u) := by
  obtain ⟨hreal, hlow, hrel, hsrc⟩ := run_invariant_aux w hw s st hrun
  exact ⟨smallest_le_aux w hw s st hlow hrel hsrc u hu, hreal u⟩

/-- Road costs from a list of one-way roads `(from, to, cost)`; `⊤` where no road is listed. -/
def mapOf {n : ℕ} (R : List (Fin n × Fin n × ℤ)) (u v : Fin n) : WithTop ℤ :=
  match R.find? (fun r => r.1 = u ∧ r.2.1 = v) with
  | some r => (r.2.2 : WithTop ℤ)
  | none => ⊤

/-- The rebate map of Step 4, one-way roads only: depot D = 0, A = 1, B = 2; D to A costs 4,
D to B costs 2, and A to B pays back 3, a cost of `-3`. -/
def rebate : Fin 3 → Fin 3 → WithTop ℤ := mapOf [(0, 1, 4), (0, 2, 2), (1, 2, -3)]

theorem rebate_reach_aux (st : State (Fin 3) ℤ)
    (hrun : Relation.ReflTransGen (Settles rebate) (start 0) st) :
    st = ([] : List (Fin 3)).foldl (round rebate) (start 0) ∨ st = ([0] : List (Fin 3)).foldl (round rebate) (start 0) ∨ st = ([0, 2] : List (Fin 3)).foldl (round rebate) (start 0) ∨
      st = ([0, 2, 1] : List (Fin 3)).foldl (round rebate) (start 0) := by
  induction hrun with
  | refl => exact Or.inl rfl
  | @tail st1 st2 _ hst ih =>
    obtain ⟨u, hu, rfl⟩ := hst
    rcases ih with rfl | rfl | rfl | rfl
    · have h : ∀ u, IsSmallestUnsettled (([] : List (Fin 3)).foldl (round rebate) (start 0)) u → u = 0 := by decide
      obtain rfl := h u hu
      exact Or.inr (Or.inl rfl)
    · have h : ∀ u, IsSmallestUnsettled (([0] : List (Fin 3)).foldl (round rebate) (start 0)) u → u = 2 := by decide
      obtain rfl := h u hu
      exact Or.inr (Or.inr (Or.inl rfl))
    · have h : ∀ u, IsSmallestUnsettled (([0, 2] : List (Fin 3)).foldl (round rebate) (start 0)) u → u = 1 := by decide
      obtain rfl := h u hu
      exact Or.inr (Or.inr (Or.inr rfl))
    · have h : ∀ u, ¬ IsSmallestUnsettled (([0, 2, 1] : List (Fin 3)).foldl (round rebate) (start 0)) u := by decide
      exact absurd hu (h u)

/-- One negative cost and the argument collapses. On the rebate map, every run of the procedure
from the depot that settles all three points ends with B's guess at `2`, yet the route D-A-B
costs `4 - 3 = 1`. -/
theorem negative_cost_breaks_settling (st : State (Fin 3) ℤ)
    (hrun : Relation.ReflTransGen (Settles rebate) (start 0) st) (hdone : st.settled = univ) :
    st.d 2 = 2 ∧ routeCost rebate [0, 1, 2] = 1 := by
  rcases rebate_reach_aux st hrun with rfl | rfl | rfl | rfl
  · revert hdone; decide
  · revert hdone; decide
  · revert hdone; decide
  · exact ⟨by decide, by decide⟩

/-- The van's map, each road running both ways: D = 0, A = 1, B = 2, C = 3, E = 4, S = 5. -/
def roads : List (Fin 6 × Fin 6 × ℤ) :=
  [(0, 1, 4), (0, 2, 2), (2, 1, 1), (1, 3, 5), (2, 3, 8), (2, 4, 10), (3, 4, 2), (3, 5, 6), (4, 5, 3)]
def van : Fin 6 → Fin 6 → WithTop ℤ := mapOf (roads ++ roads.map (fun r => (r.2.1, r.1, r.2.2)))

/-- The state after settling the listed points in order. -/
def runOn {n : ℕ} (w : Fin n → Fin n → WithTop ℤ) (s : Fin n) (us : List (Fin n)) : State (Fin n) ℤ :=
  us.foldl (round w) (start s)

-- Nine roads, no cost below zero.
example : roads.length = 9 ∧ ∀ u v, (0 : WithTop ℤ) ≤ van u v := by decide
-- The way round beats the direct road: D-A costs 4, D-B-A costs 2 + 1 = 3.
example : routeCost van [0, 1] = 4 ∧ routeCost van [0, 2, 1] = 3 := by decide
-- The settling order D, B, A, C, E, S: each point settled is the smallest unsettled guess.
example : IsSmallestUnsettled (runOn van 0 []) 0 ∧ IsSmallestUnsettled (runOn van 0 [0]) 2 ∧
    IsSmallestUnsettled (runOn van 0 [0, 2]) 1 ∧ IsSmallestUnsettled (runOn van 0 [0, 2, 1]) 3 ∧
    IsSmallestUnsettled (runOn van 0 [0, 2, 1, 3]) 4 ∧
    IsSmallestUnsettled (runOn van 0 [0, 2, 1, 3, 4]) 5 := by decide
-- The table, row by row (columns D, A, B, C, E, S; ⊤ for no route yet).
example : List.ofFn (runOn van 0 [0]).d = [0, 4, 2, ⊤, ⊤, ⊤] := by decide
example : List.ofFn (runOn van 0 [0, 2]).d = [0, 3, 2, 10, 12, ⊤] := by decide
example : List.ofFn (runOn van 0 [0, 2, 1]).d = [0, 3, 2, 8, 12, ⊤] := by decide
example : List.ofFn (runOn van 0 [0, 2, 1, 3]).d = [0, 3, 2, 8, 10, 14] := by decide
example : List.ofFn (runOn van 0 [0, 2, 1, 3, 4]).d = [0, 3, 2, 8, 10, 13] := by decide
example : List.ofFn (runOn van 0 [0, 2, 1, 3, 4, 5]).d = [0, 3, 2, 8, 10, 13] ∧
    (runOn van 0 [0, 2, 1, 3, 4, 5]).settled = univ := by decide
-- The route read back, D-B-A-C-E-S: 2 + 1 + 5 + 2 + 3 = 13.
example : routeCost van [0, 2, 1, 3, 4, 5] = 13 ∧ 2 + 1 + 5 + 2 + 3 = 13 := by decide
-- Fewest roads, D-A-C-S: three roads, 4 + 5 + 6 = 15 minutes.
example : routeCost van [0, 1, 3, 5] = 15 := by decide
-- The rebate map: settling D, B, A leaves B at 2; listing finds D-A-B at 4 - 3 = 1.
example : IsSmallestUnsettled (runOn rebate 0 []) 0 ∧ IsSmallestUnsettled (runOn rebate 0 [0]) 2 ∧
    IsSmallestUnsettled (runOn rebate 0 [0, 2]) 1 := by decide
example : (runOn rebate 0 [0, 2, 1]).d 2 = 2 ∧ routeCost rebate [0, 1, 2] = 1 := by decide

#print axioms routeCost_nonneg_aux
#print axioms routeCost_snoc_aux
#print axioms reach_unsettled_aux
#print axioms smallest_le_aux
#print axioms run_invariant_aux
#print axioms rebate_reach_aux
#print axioms dijkstra_final_guesses_are_cheapest_costs
#print axioms smallest_unsettled_guess_is_cheapest
#print axioms negative_cost_breaks_settling
