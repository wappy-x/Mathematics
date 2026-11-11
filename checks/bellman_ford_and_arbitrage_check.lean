-- Bellman-Ford: relaxing every arrow n - 1 times leaves every cheapest route cost on the table when no loop has a negative total, one more round improves something exactly when a loop reachable from the start has a negative total, and with positive rates and costs minus their logs a loop's rates multiply above 1 exactly when its costs add below 0.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Order.WithBot
import Mathlib.Algebra.Order.Monoid.WithTop
import Mathlib.Data.Fintype.Card
import Mathlib.Logic.Function.Iterate

namespace BellmanFord

variable {V : Type*}

/-- An arrow `(u, v, w)` runs from `u` to `v` and costs `w`. -/
abbrev Arrow (V : Type*) := V × V × ℝ

/-- `IsRoute E a b p`: the list of arrows `p`, each one quoted in `E`, leads from `a` to `b`,
each arrow starting where the one before it ended. The empty route leads from `a` to `a`. -/
inductive IsRoute (E : List (Arrow V)) : V → V → List (Arrow V) → Prop
  | nil (a : V) : IsRoute E a a []
  | cons {a b c : V} {w : ℝ} {p : List (Arrow V)} :
      (a, b, w) ∈ E → IsRoute E b c p → IsRoute E a c ((a, b, w) :: p)

/-- A route's cost: the costs of its arrows added up. -/
def routeCost (p : List (Arrow V)) : ℝ := (p.map fun e => e.2.2).sum

variable [DecidableEq V]

/-- Relax one arrow `u → v` of cost `w`: `d(v) ← min (d(v), d(u) + w)`. Infinity is `⊤`. -/
def relax (d : V → WithTop ℝ) (e : Arrow V) : V → WithTop ℝ :=
  Function.update d e.2.1 (min (d e.2.1) (d e.1 + (e.2.2 : WithTop ℝ)))

/-- One round: relax every arrow of `E` once, in the list's fixed order. -/
def relaxRound (E : List (Arrow V)) (d : V → WithTop ℝ) : V → WithTop ℝ :=
  E.foldl relax d

/-- The starting table: 0 at the start `s`, infinity everywhere else. -/
def startTable (s : V) : V → WithTop ℝ := fun v => if v = s then 0 else ⊤

/-- The table after `k` rounds of Bellman-Ford from `s`. -/
def table (E : List (Arrow V)) (s : V) (k : ℕ) : V → WithTop ℝ :=
  (relaxRound E)^[k] (startTable s)

end BellmanFord

open BellmanFord

variable {V : Type*} [DecidableEq V]

theorem bf_routeCost_cons (e : Arrow V) (p : List (Arrow V)) :
    routeCost (e :: p) = e.2.2 + routeCost p := by
  simp [routeCost]

theorem bf_routeCost_append (p q : List (Arrow V)) :
    routeCost (p ++ q) = routeCost p + routeCost q := by
  simp [routeCost]

theorem bf_route_append {E : List (Arrow V)} {a b c : V} {p q : List (Arrow V)}
    (hp : IsRoute E a b p) (hq : IsRoute E b c q) : IsRoute E a c (p ++ q) := by
  induction hp with
  | nil => simpa using hq
  | cons he _ ih => exact IsRoute.cons he (ih hq)

theorem bf_route_split {E : List (Arrow V)} {b c : V} {p : List (Arrow V)}
    (hp : IsRoute E b c p) (a : V) (ha : a ∈ p.map Prod.fst ++ [c]) :
    ∃ p1 p2, p = p1 ++ p2 ∧ IsRoute E b a p1 ∧ IsRoute E a c p2 := by
  induction hp with
  | nil x =>
    simp at ha
    subst ha
    exact ⟨[], [], rfl, IsRoute.nil _, IsRoute.nil _⟩
  | @cons x y z w q he hq ih =>
    by_cases hax : a = x
    · subst hax
      exact ⟨[], _, rfl, IsRoute.nil _, IsRoute.cons he hq⟩
    · have ha' : a ∈ q.map Prod.fst ++ [z] := by
        simp only [List.map_cons, List.cons_append, List.mem_cons] at ha
        rcases ha with h | h
        · exact absurd h hax
        · exact h
      obtain ⟨q1, q2, rfl, h1, h2⟩ := ih ha'
      exact ⟨(x, y, w) :: q1, q2, rfl, IsRoute.cons he h1, h2⟩

/-- Cutting loops: with no paying loop reachable from `s`, every route from a reachable
currency can be shortened to one with distinct currencies and no larger cost. -/
theorem bf_route_shorten {E : List (Arrow V)} {s : V}
    (hno : ∀ x q p, IsRoute E s x q → IsRoute E x x p → 0 ≤ routeCost p)
    {a c : V} {p : List (Arrow V)} (hp : IsRoute E a c p) :
    ∀ q, IsRoute E s a q →
      ∃ p', IsRoute E a c p' ∧ routeCost p' ≤ routeCost p ∧ (p'.map Prod.fst ++ [c]).Nodup := by
  induction hp with
  | nil x => intro _ _; exact ⟨[], IsRoute.nil _, le_rfl, by simp⟩
  | @cons x y z w r he hr ih =>
    intro q hq
    have hq' : IsRoute E s y (q ++ [(x, y, w)]) :=
      bf_route_append hq (IsRoute.cons he (IsRoute.nil _))
    obtain ⟨p', hp', hcost, hnd⟩ := ih (q ++ [(x, y, w)]) hq'
    by_cases hx : x ∈ p'.map Prod.fst ++ [z]
    · obtain ⟨p1, p2, rfl, h1, h2⟩ := bf_route_split hp' x hx
      have hloop := hno x q _ hq (IsRoute.cons he h1)
      refine ⟨p2, h2, ?_, ?_⟩
      · rw [bf_routeCost_cons] at hloop ⊢
        rw [bf_routeCost_append] at hcost
        simp only at hloop ⊢
        linarith
      · rw [List.map_append, List.append_assoc] at hnd
        exact (List.nodup_append.1 hnd).2.1
    · refine ⟨(x, y, w) :: p', IsRoute.cons he hp', ?_, ?_⟩
      · rw [bf_routeCost_cons, bf_routeCost_cons]
        simp only
        linarith
      · simp only [List.map_cons, List.cons_append]
        exact List.nodup_cons.2 ⟨hx, hnd⟩

theorem bf_route_length [Fintype V] {p : List (Arrow V)} {c : V}
    (hnd : (p.map Prod.fst ++ [c]).Nodup) : p.length ≤ Fintype.card V - 1 := by
  have := hnd.length_le_card
  simp at this
  omega

theorem bf_relax_le (d : V → WithTop ℝ) (e : Arrow V) (v : V) : relax d e v ≤ d v := by
  unfold relax
  by_cases h : v = e.2.1
  · subst h; simp
  · simp [Function.update_of_ne h]

theorem bf_foldl_le (L : List (Arrow V)) : ∀ (d : V → WithTop ℝ) (v : V),
    L.foldl relax d v ≤ d v := by
  induction L with
  | nil => intro d v; simp
  | cons e L ih =>
    intro d v
    simp only [List.foldl_cons]
    exact (ih _ v).trans (bf_relax_le d e v)

theorem bf_round_le (E : List (Arrow V)) (d : V → WithTop ℝ) (v : V) :
    relaxRound E d v ≤ d v := bf_foldl_le E d v

theorem bf_iterate_le (E : List (Arrow V)) (k : ℕ) : ∀ (d : V → WithTop ℝ) (v : V),
    (relaxRound E)^[k] d v ≤ d v := by
  induction k with
  | zero => intro d v; simp
  | succ k ih =>
    intro d v
    rw [Function.iterate_succ_apply]
    exact (ih _ v).trans (bf_round_le E d v)

theorem bf_foldl_arrow (L : List (Arrow V)) : ∀ (d : V → WithTop ℝ) (e : Arrow V), e ∈ L →
    L.foldl relax d e.2.1 ≤ d e.1 + (e.2.2 : WithTop ℝ) := by
  induction L with
  | nil => intro d e he; simp at he
  | cons e' L ih =>
    intro d e he
    simp only [List.foldl_cons]
    rcases List.mem_cons.1 he with h | h
    · subst h
      refine (bf_foldl_le L _ _).trans ?_
      unfold relax
      simp
    · refine (ih _ e h).trans ?_
      gcongr
      exact bf_relax_le d e' e.1

theorem bf_round_arrow (E : List (Arrow V)) (d : V → WithTop ℝ) {u v : V} {w : ℝ}
    (he : (u, v, w) ∈ E) : relaxRound E d v ≤ d u + (w : WithTop ℝ) :=
  bf_foldl_arrow E d (u, v, w) he

/-- After `k` rounds, the number at the end of a route with at most `k` arrows is no more than
the number at its start plus its cost. -/
theorem bf_iterate_route (E : List (Arrow V)) (k : ℕ) : ∀ (d : V → WithTop ℝ) (a c : V)
    (p : List (Arrow V)), IsRoute E a c p → p.length ≤ k →
    (relaxRound E)^[k] d c ≤ d a + (routeCost p : WithTop ℝ) := by
  induction k with
  | zero =>
    intro d a c p hp hlen
    have : p = [] := List.eq_nil_of_length_eq_zero (by omega)
    subst this
    cases hp
    simp [routeCost]
  | succ k ih =>
    intro d a c p hp hlen
    cases hp with
    | nil =>
      refine (bf_iterate_le E _ d a).trans ?_
      simp [routeCost]
    | @cons _ b _ w q he hq =>
      rw [Function.iterate_succ_apply]
      refine (ih _ b c q hq (by simp at hlen; omega)).trans ?_
      rw [bf_routeCost_cons, WithTop.coe_add, ← add_assoc]
      gcongr
      exact bf_round_arrow E d he

/-- Every number in the table is infinity or the cost of an actual route from the start. -/
def bf_Inv (E : List (Arrow V)) (s : V) (d : V → WithTop ℝ) : Prop :=
  ∀ v, d v = ⊤ ∨ ∃ p, IsRoute E s v p ∧ d v = (routeCost p : WithTop ℝ)

theorem bf_inv_relax {E : List (Arrow V)} {s : V} {d : V → WithTop ℝ} (hd : bf_Inv E s d)
    (e : Arrow V) (he : e ∈ E) : bf_Inv E s (relax d e) := by
  obtain ⟨u, v, w⟩ := e
  intro x
  unfold relax
  by_cases hx : x = v
  · subst hx
    simp only [Function.update_self]
    rcases min_choice (d x) (d u + (w : WithTop ℝ)) with h | h
    · rw [h]; exact hd x
    · rw [h]
      rcases hd u with h' | ⟨p, hp, h'⟩
      · left; rw [h']; simp
      · right
        refine ⟨p ++ [(u, x, w)], bf_route_append hp (IsRoute.cons he (IsRoute.nil _)), ?_⟩
        rw [h', bf_routeCost_append]
        simp [routeCost]
  · simp only [Function.update_of_ne hx]
    exact hd x

theorem bf_inv_foldl {E : List (Arrow V)} {s : V} (L : List (Arrow V)) (hL : ∀ e ∈ L, e ∈ E) :
    ∀ d, bf_Inv E s d → bf_Inv E s (L.foldl relax d) := by
  induction L with
  | nil => intro d hd; simpa using hd
  | cons e L ih =>
    intro d hd
    simp only [List.foldl_cons]
    exact ih (fun e' h => hL e' (List.mem_cons_of_mem _ h)) _
      (bf_inv_relax hd e (hL e (List.mem_cons_self ..)))

theorem bf_inv_table (E : List (Arrow V)) (s : V) (k : ℕ) : bf_Inv E s (table E s k) := by
  induction k with
  | zero =>
    intro v
    simp only [table, Function.iterate_zero, id, startTable]
    by_cases h : v = s
    · subst h; right; exact ⟨[], IsRoute.nil _, by simp [routeCost]⟩
    · left; simp [h]
  | succ k ih =>
    unfold table
    rw [Function.iterate_succ_apply']
    exact bf_inv_foldl E (fun e h => h) _ ih

/-- With no paying loop reachable from the start, the table after `n - 1` rounds is no more
than the cost of any route from the start. -/
theorem bf_table_le_route [Fintype V] (E : List (Arrow V)) (s : V)
    (hno : ∀ x q p, IsRoute E s x q → IsRoute E x x p → 0 ≤ routeCost p) (v : V)
    (p : List (Arrow V)) (hp : IsRoute E s v p) :
    table E s (Fintype.card V - 1) v ≤ (routeCost p : WithTop ℝ) := by
  obtain ⟨p', hp', hcost, hnd⟩ := bf_route_shorten hno hp [] (IsRoute.nil _)
  have h1 := bf_iterate_route E _ (startTable s) s v p' hp' (bf_route_length hnd)
  have h0 : startTable s s = 0 := by simp [startTable]
  rw [h0, zero_add] at h1
  exact h1.trans (WithTop.coe_le_coe.2 hcost)

theorem bf_fixed_route {E : List (Arrow V)} {d : V → WithTop ℝ}
    (hfix : ∀ u v w, (u, v, w) ∈ E → d v ≤ d u + (w : WithTop ℝ))
    {a c : V} {p : List (Arrow V)} (hp : IsRoute E a c p) :
    d c ≤ d a + (routeCost p : WithTop ℝ) := by
  induction hp with
  | nil => simp [routeCost]
  | @cons x y z w q he _ ih =>
    refine ih.trans ?_
    rw [bf_routeCost_cons, WithTop.coe_add, ← add_assoc]
    gcongr
    exact hfix _ _ _ he

#print axioms bf_routeCost_cons
#print axioms bf_routeCost_append
#print axioms bf_route_append
#print axioms bf_route_split
#print axioms bf_route_shorten
#print axioms bf_route_length
#print axioms bf_relax_le
#print axioms bf_foldl_le
#print axioms bf_round_le
#print axioms bf_iterate_le
#print axioms bf_foldl_arrow
#print axioms bf_round_arrow
#print axioms bf_iterate_route
#print axioms bf_inv_relax
#print axioms bf_inv_foldl
#print axioms bf_inv_table
#print axioms bf_table_le_route
#print axioms bf_fixed_route

/-- **Bellman-Ford finds every cheapest route.** On finitely many currencies, n of them, with
any real costs (negative allowed), if no loop pays (every route from a currency back to itself
costs 0 or more), then after n - 1 rounds the table at each currency v is the cheapest route
cost from the start: no route to v costs less, and the number is either infinity (no route)
or the cost of an actual route to v. -/
theorem bellman_ford_n_minus_one_rounds_find_cheapest_routes [Fintype V]
    (E : List (Arrow V)) (s : V)
    (hnoloop : ∀ x p, IsRoute E x x p → 0 ≤ routeCost p) (v : V) :
    (∀ p, IsRoute E s v p → table E s (Fintype.card V - 1) v ≤ (routeCost p : WithTop ℝ)) ∧
    (table E s (Fintype.card V - 1) v = ⊤ ∨
      ∃ p, IsRoute E s v p ∧ table E s (Fintype.card V - 1) v = (routeCost p : WithTop ℝ)) := by
  refine ⟨fun p hp => bf_table_le_route E s (fun x _ p _ hp => hnoloop x p hp) v p hp, ?_⟩
  rcases bf_inv_table E s (Fintype.card V - 1) v with h | h
  · exact Or.inl h
  · exact Or.inr h

/-- **The extra round is a money-machine detector.** On n currencies with any real costs,
the n-th round still lowers some currency's number exactly when some loop reachable from the
start pays: a route from the start reaches a currency x, and a route from x back to x costs
less than 0. -/
theorem extra_round_improves_iff_reachable_loop_pays [Fintype V]
    (E : List (Arrow V)) (s : V) :
    (∃ v, table E s (Fintype.card V) v < table E s (Fintype.card V - 1) v) ↔
      ∃ x q p, IsRoute E s x q ∧ IsRoute E x x p ∧ routeCost p < 0 := by
  constructor
  · rintro ⟨v, hv⟩
    by_contra hcon
    have hno : ∀ x q p, IsRoute E s x q → IsRoute E x x p → 0 ≤ routeCost p := by
      intro x q p hq hp
      by_contra h
      exact hcon ⟨x, q, p, hq, hp, not_le.1 h⟩
    rcases bf_inv_table E s (Fintype.card V) v with h | ⟨p, hp, h⟩
    · rw [h] at hv; exact not_top_lt hv
    · rw [h] at hv
      exact absurd (bf_table_le_route E s hno v p hp) (not_le.2 hv)
  · rintro ⟨x, q, p, hq, hp, hneg⟩
    by_contra hcon
    have hn : 0 < Fintype.card V := Fintype.card_pos_iff.2 ⟨s⟩
    have e : table E s (Fintype.card V) = relaxRound E (table E s (Fintype.card V - 1)) := by
      conv_lhs => rw [show Fintype.card V = (Fintype.card V - 1) + 1 by omega]
      exact Function.iterate_succ_apply' _ _ _
    set d := table E s (Fintype.card V - 1) with hd
    have key : ∀ v, d v ≤ relaxRound E d v := by
      intro v
      have := not_lt.1 (fun h => hcon ⟨v, h⟩)
      rw [e] at this
      exact this
    have hfix : ∀ u v w, (u, v, w) ∈ E → d v ≤ d u + (w : WithTop ℝ) := by
      intro u v w he
      exact (key v).trans (bf_round_arrow E d he)
    have hs : d s ≤ 0 := by
      have := bf_iterate_le E (Fintype.card V - 1) (startTable s) s
      rw [hd]
      unfold table
      simpa [startTable] using this
    have hx : d x ≤ (routeCost q : WithTop ℝ) := by
      have h1 := bf_fixed_route hfix hq
      calc d x ≤ d s + (routeCost q : WithTop ℝ) := h1
        _ ≤ 0 + (routeCost q : WithTop ℝ) := by gcongr
        _ = (routeCost q : WithTop ℝ) := zero_add _
    obtain ⟨r, hr⟩ := WithTop.ne_top_iff_exists.1 (ne_top_of_le_ne_top WithTop.coe_ne_top hx)
    have hl := bf_fixed_route hfix hp
    rw [← hr, ← WithTop.coe_add, WithTop.coe_le_coe] at hl
    linarith

/-- **Profit test and cost test are one test.** For a loop whose rates are all positive,
the rates multiply to more than 1 exactly when the costs, minus the log of each rate,
add to less than 0. -/
theorem rates_multiply_above_one_iff_costs_add_below_zero (rs : List ℝ)
    (hpos : ∀ r ∈ rs, 0 < r) :
    1 < rs.prod ↔ (rs.map fun r => -Real.log r).sum < 0 := by
  have h : ∀ l : List ℝ, (∀ r ∈ l, 0 < r) →
      0 < l.prod ∧ (l.map fun r => -Real.log r).sum = -Real.log l.prod := by
    intro l
    induction l with
    | nil => intro _; simp
    | cons a l ih =>
      intro hl
      obtain ⟨h1, h2⟩ := ih (fun r hr => hl r (List.mem_cons_of_mem _ hr))
      have ha := hl a (List.mem_cons_self ..)
      refine ⟨by rw [List.prod_cons]; exact mul_pos ha h1, ?_⟩
      simp only [List.map_cons, List.sum_cons, List.prod_cons, h2]
      rw [Real.log_mul ha.ne' h1.ne']
      ring
  obtain ⟨h1, h2⟩ := h rs hpos
  rw [h2, neg_lt_zero, Real.log_pos_iff h1.le]

-- The card's market: 0.90 × 0.85 × 1.32 = 1.0098, above 1, so the loop pays.
example : (90 / 100 : ℚ) * (85 / 100) * (132 / 100) = 10098 / 10000 := by norm_num
example : 1 < (90 / 100 : ℚ) * (85 / 100) * (132 / 100) := by norm_num
-- Move the pound-to-dollar rate to 1.30: 0.90 × 0.85 × 1.30 = 0.9945, below 1, no arbitrage.
example : (90 / 100 : ℚ) * (85 / 100) * (130 / 100) = 9945 / 10000 := by norm_num
example : (90 / 100 : ℚ) * (85 / 100) * (130 / 100) < 1 := by norm_num
-- Three currencies: n - 1 = 2 rounds, then one more.
example : 3 - 1 = 2 := by norm_num

#print axioms bellman_ford_n_minus_one_rounds_find_cheapest_routes
#print axioms extra_round_improves_iff_reachable_loop_pays
#print axioms rates_multiply_above_one_iff_costs_add_below_zero
