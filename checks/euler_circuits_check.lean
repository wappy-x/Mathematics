-- Euler circuits: a finite network whose lines may repeat or loop has a closed route using every line exactly once exactly when its lines sit in one piece and every dot has even degree, with an open route between the two odd dots when there are exactly two, and the card's Königsberg, figure-eight and street-grid numbers check out.
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Data.Sym.Sym2
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Algebra.BigOperators.Ring.Nat

/-! A network is a finite multiset `E` of lines, each line a pair of dots `(a, b)`.
A line may be repeated (Königsberg's doubled bridges) or join a dot to itself (a loop, `(a, a)`).
A route is a list of dots; it walks the lines between consecutive dots. -/

namespace EulerCircuits

variable {V : Type*} [DecidableEq V]

/-- The degree of a dot: its line-ends. A repeated line counts each time, a loop counts twice. -/
def degree (E : Multiset (V × V)) (v : V) : ℕ :=
  (E.map Prod.fst).count v + (E.map Prod.snd).count v

/-- The route walks every line of `E` exactly once: the lines between consecutive dots of the
route, taken without direction, are exactly the lines of `E`, with repeats counted. -/
def UsesEveryLineOnce (E : Multiset (V × V)) (route : List V) : Prop :=
  Multiset.ofList ((route.zip route.tail).map fun p => s(p.1, p.2)) = E.map fun p => s(p.1, p.2)

/-- The lines sit in one piece: any two lines are joined through the network, so an end of one
reaches an end of the other. Dots carrying no line sit out. -/
def LinesInOnePiece (E : Multiset (V × V)) : Prop :=
  ∀ e ∈ E, ∀ f ∈ E, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable e.1 f.1

/-! Helper lemmas for the proofs below. -/

theorem degree_cons (p : V × V) (E : Multiset (V × V)) (v : V) :
    degree (p ::ₘ E) v = degree E v + (if v = p.1 then 1 else 0) + (if v = p.2 then 1 else 0) := by
  simp only [degree, Multiset.map_cons, Multiset.count_cons]
  omega
#print axioms degree_cons

theorem degree_add (E F : Multiset (V × V)) (v : V) :
    degree (E + F) v = degree E v + degree F v := by
  simp only [degree, Multiset.map_add, Multiset.count_add]
  omega
#print axioms degree_add

theorem degree_eq_zero_of (E : Multiset (V × V)) (v : V) (h : ∀ p ∈ E, p.1 ≠ v ∧ p.2 ≠ v) :
    degree E v = 0 := by
  simp only [degree, Nat.add_eq_zero_iff, Multiset.count_eq_zero, Multiset.mem_map]
  constructor
  · rintro ⟨p, hp, rfl⟩
    exact (h p hp).1 rfl
  · rintro ⟨p, hp, rfl⟩
    exact (h p hp).2 rfl
#print axioms degree_eq_zero_of

theorem exists_edge_of_degree_pos (E : Multiset (V × V)) (v : V) (h : 0 < degree E v) :
    ∃ p ∈ E, ∃ x, p = (v, x) ∨ p = (x, v) := by
  by_contra hc
  push Not at hc
  have h0 : degree E v = 0 := degree_eq_zero_of E v (fun p hp =>
    ⟨fun h1 => (hc p hp p.2).1 (Prod.ext h1 rfl), fun h2 => (hc p hp p.1).2 (Prod.ext rfl h2)⟩)
  omega
#print axioms exists_edge_of_degree_pos

theorem degree_eq_sum (E : Multiset (V × V)) (v : V) :
    degree E v = ((E.map fun p => s(p.1, p.2)).map (Sym2.lift
      ⟨fun a b => (if v = a then 1 else 0) + (if v = b then 1 else 0),
        fun _ _ => Nat.add_comm _ _⟩)).sum := by
  induction E using Multiset.induction_on with
  | empty => simp [degree]
  | cons p E ih =>
    rw [degree_cons, ih, Multiset.map_cons, Multiset.map_cons, Multiset.sum_cons, Sym2.lift_mk]
    dsimp only
    omega
#print axioms degree_eq_sum

theorem degree_eq_of_uses (E : Multiset (V × V)) (r : List V) (h : UsesEveryLineOnce E r)
    (v : V) : degree E v = degree (Multiset.ofList (r.zip r.tail)) v := by
  rw [degree_eq_sum E v, degree_eq_sum _ v]
  congr 2
  unfold UsesEveryLineOnce at h
  rw [← h, Multiset.map_coe]
#print axioms degree_eq_of_uses

theorem reach_of_mem (E : Multiset (V × V)) (p : V × V) (hp : p ∈ E) :
    (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable p.1 p.2 := by
  obtain ⟨a, b⟩ := p
  by_cases h : a = b
  · subst h
    exact SimpleGraph.Reachable.refl _
  · exact SimpleGraph.Adj.reachable ((SimpleGraph.fromRel_adj _ _ _).2 ⟨h, Or.inl hp⟩)
#print axioms reach_of_mem

theorem reach_mono {E F : Multiset (V × V)} (h : ∀ p ∈ E, p ∈ F) {a b : V}
    (hr : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable a b) :
    (SimpleGraph.fromRel fun a b => (a, b) ∈ F).Reachable a b :=
  hr.mono (fun x y hxy => by
    rw [SimpleGraph.fromRel_adj] at hxy ⊢
    exact ⟨hxy.1, hxy.2.imp (h _) (h _)⟩)
#print axioms reach_mono

theorem reach_filter (E : Multiset (V × V)) (Q : V → Prop) [DecidablePred Q]
    (hQ : ∀ p ∈ E, (Q p.1 ↔ Q p.2)) {a y : V}
    (h : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable a y) (ha : Q a) :
    Q y ∧ (SimpleGraph.fromRel fun a b => (a, b) ∈ E.filter fun p => Q p.1).Reachable a y := by
  rw [SimpleGraph.reachable_iff_reflTransGen] at h
  induction h with
  | refl => exact ⟨ha, SimpleGraph.Reachable.refl _⟩
  | tail _ hbc ih =>
    obtain ⟨hb, hr⟩ := ih
    rw [SimpleGraph.fromRel_adj] at hbc
    obtain ⟨hne, hbc | hcb⟩ := hbc
    · exact ⟨(hQ _ hbc).1 hb, hr.trans (SimpleGraph.Adj.reachable
        ((SimpleGraph.fromRel_adj _ _ _).2 ⟨hne, Or.inl (Multiset.mem_filter.2 ⟨hbc, hb⟩)⟩))⟩
    · have hc := (hQ _ hcb).2 hb
      exact ⟨hc, hr.trans (SimpleGraph.Adj.reachable
        ((SimpleGraph.fromRel_adj _ _ _).2 ⟨hne, Or.inr (Multiset.mem_filter.2 ⟨hcb, hc⟩)⟩))⟩
#print axioms reach_filter

theorem reach_erase (E : Multiset (V × V)) (p : V × V) (u x : V)
    (hux : p = (u, x) ∨ p = (x, u)) {y : V}
    (h : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u y) :
    (SimpleGraph.fromRel fun a b => (a, b) ∈ E.erase p).Reachable u y ∨
      (SimpleGraph.fromRel fun a b => (a, b) ∈ E.erase p).Reachable x y := by
  rw [SimpleGraph.reachable_iff_reflTransGen] at h
  induction h with
  | refl => exact Or.inl (SimpleGraph.Reachable.refl _)
  | @tail b c _ hbc ih =>
    rw [SimpleGraph.fromRel_adj] at hbc
    obtain ⟨hne, hq⟩ := hbc
    by_cases hin : (b, c) ∈ E.erase p ∨ (c, b) ∈ E.erase p
    · have hadj : (SimpleGraph.fromRel fun a b => (a, b) ∈ E.erase p).Adj b c :=
        (SimpleGraph.fromRel_adj _ _ _).2 ⟨hne, hin⟩
      exact ih.imp (fun h => h.trans hadj.reachable) (fun h => h.trans hadj.reachable)
    · push Not at hin
      have hc : c = u ∨ c = x := by
        rcases hq with hq | hq
        · have hp : (b, c) = p := by
            by_contra hne'
            exact hin.1 ((Multiset.mem_erase_of_ne hne').2 hq)
          rcases hux with rfl | rfl
          · exact Or.inr (Prod.mk.inj hp).2
          · exact Or.inl (Prod.mk.inj hp).2
        · have hp : (c, b) = p := by
            by_contra hne'
            exact hin.2 ((Multiset.mem_erase_of_ne hne').2 hq)
          rcases hux with rfl | rfl
          · exact Or.inl (Prod.mk.inj hp).1
          · exact Or.inr (Prod.mk.inj hp).1
      rcases hc with rfl | rfl
      · exact Or.inl (SimpleGraph.Reachable.refl _)
      · exact Or.inr (SimpleGraph.Reachable.refl _)
#print axioms reach_erase

theorem edge_at_start (E : Multiset (V × V)) (u : V) (e : V × V) (he : e ∈ E)
    (h : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u e.1) :
    ∃ p ∈ E, ∃ x, p = (u, x) ∨ p = (x, u) := by
  rw [SimpleGraph.reachable_iff_reflTransGen] at h
  rcases h.cases_head with h | ⟨c, hc, _⟩
  · exact ⟨e, he, e.2, Or.inl (Prod.ext h.symm rfl)⟩
  · rw [SimpleGraph.fromRel_adj] at hc
    rcases hc.2 with h | h
    · exact ⟨(u, c), h, c, Or.inl rfl⟩
    · exact ⟨(c, u), h, c, Or.inr rfl⟩
#print axioms edge_at_start

theorem degree_erase (E : Multiset (V × V)) (p : V × V) (hp : p ∈ E) (u x : V)
    (hx : p = (u, x) ∨ p = (x, u)) (v : V) :
    degree E v = degree (E.erase p) v + (if v = u then 1 else 0) + (if v = x then 1 else 0) := by
  conv_lhs => rw [← Multiset.cons_erase hp]
  rw [degree_cons]
  rcases hx with rfl | rfl
  · rfl
  · simp only
    omega
#print axioms degree_erase

theorem eq_of_degree_zero (E : Multiset (V × V)) (u w : V) (h0 : degree E u = 0)
    (hpar : (degree E u + (if u = u then 1 else 0) + (if u = w then 1 else 0)) % 2 = 0) :
    u = w := by
  by_contra h
  simp [h0, h] at hpar
#print axioms eq_of_degree_zero

theorem reach_of_parity : ∀ n : ℕ, ∀ (E : Multiset (V × V)) (u w : V), Multiset.card E ≤ n →
    (∀ v, (degree E v + (if v = u then 1 else 0) + (if v = w then 1 else 0)) % 2 = 0) →
    (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u w := by
  intro n
  induction n with
  | zero =>
    intro E u w hc hpar
    have hE : E = 0 := Multiset.card_eq_zero.1 (by omega)
    subst hE
    have := eq_of_degree_zero 0 u w (by simp [degree]) (hpar u)
    subst this
    exact SimpleGraph.Reachable.refl _
  | succ n ih =>
    intro E u w hc hpar
    by_cases hd : degree E u = 0
    · have := eq_of_degree_zero E u w hd (hpar u)
      subst this
      exact SimpleGraph.Reachable.refl _
    · obtain ⟨p, hp, x, hx⟩ := exists_edge_of_degree_pos E u (Nat.pos_of_ne_zero hd)
      have hc' : Multiset.card (E.erase p) ≤ n := by
        rw [Multiset.card_erase_of_mem hp, Nat.pred_eq_sub_one]
        omega
      have hr := ih (E.erase p) x w hc' (fun v => by
        have h1 := hpar v
        have h2 := degree_erase E p hp u x hx v
        omega)
      have hr' := reach_mono (fun q hq => Multiset.mem_of_mem_erase hq) hr
      have hux : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u x := by
        rcases hx with rfl | rfl
        · exact reach_of_mem E _ hp
        · exact (reach_of_mem E _ hp).symm
      exact hux.trans hr'
#print axioms reach_of_parity

theorem lines_append : ∀ (rb ra : List V) (u x : V), rb.getLast? = some u → ra.head? = some x →
    ((rb ++ ra).zip (rb ++ ra).tail).map (fun p => s(p.1, p.2)) =
      (rb.zip rb.tail).map (fun p => s(p.1, p.2)) ++
        s(u, x) :: (ra.zip ra.tail).map (fun p => s(p.1, p.2))
  | [], _, _, _, h, _ => by simp at h
  | [a], ra, u, x, h, h' => by
    cases ra with
    | nil => simp at h'
    | cons c t =>
      simp only [List.getLast?_singleton, Option.some.injEq, List.head?_cons] at h h'
      subst h h'
      simp
  | a :: b :: t, ra, u, x, h, h' => by
    have ih := lines_append (b :: t) ra u x (by rw [List.getLast?_cons_cons] at h; exact h) h'
    simp only [List.cons_append, List.tail_cons, List.zip_cons_cons, List.map_cons] at ih ⊢
    rw [ih]
#print axioms lines_append

theorem uses_append (A B : Multiset (V × V)) (ra rb : List V) (u x : V)
    (hb : UsesEveryLineOnce B rb) (ha : UsesEveryLineOnce A ra)
    (hbl : rb.getLast? = some u) (hah : ra.head? = some x) :
    UsesEveryLineOnce (B + (u, x) ::ₘ A) (rb ++ ra) := by
  unfold UsesEveryLineOnce at *
  rw [lines_append rb ra u x hbl hah, ← Multiset.coe_add, ← Multiset.cons_coe, hb, ha]
  simp [Multiset.map_add]
#print axioms uses_append

theorem route_base (E : Multiset (V × V)) (u w : V) (hE : E = 0)
    (hpar : ∀ v, (degree E v + (if v = u then 1 else 0) + (if v = w then 1 else 0)) % 2 = 0) :
    ∃ r : List V, r.head? = some u ∧ r.getLast? = some w ∧ UsesEveryLineOnce E r := by
  subst hE
  have := eq_of_degree_zero 0 u w (by simp [degree]) (hpar u)
  subst this
  exact ⟨[u], rfl, rfl, by simp [UsesEveryLineOnce]⟩
#print axioms route_base

theorem route_of_parity : ∀ n : ℕ, ∀ (E : Multiset (V × V)) (u w : V), Multiset.card E ≤ n →
    (∀ v, (degree E v + (if v = u then 1 else 0) + (if v = w then 1 else 0)) % 2 = 0) →
    (∀ e ∈ E, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u e.1) →
    ∃ r : List V, r.head? = some u ∧ r.getLast? = some w ∧ UsesEveryLineOnce E r := by
  intro n
  induction n with
  | zero =>
    intro E u w hc hpar _
    exact route_base E u w (Multiset.card_eq_zero.1 (by omega)) hpar
  | succ n ih =>
    intro E u w hc hpar hconn
    classical
    by_cases hE : E = 0
    · exact route_base E u w hE hpar
    obtain ⟨e, he⟩ := Multiset.exists_mem_of_ne_zero hE
    obtain ⟨p, hp, x, hx⟩ := edge_at_start E u e he (hconn e he)
    obtain ⟨E', hE'⟩ : ∃ E', E' = E.erase p := ⟨_, rfl⟩
    have hcons : p ::ₘ E' = E := hE' ▸ Multiset.cons_erase hp
    have hcE' : Multiset.card E' ≤ n := by
      rw [hE', Multiset.card_erase_of_mem hp, Nat.pred_eq_sub_one]
      omega
    have hdeg : ∀ v, degree E v = degree E' v + (if v = u then 1 else 0) +
        (if v = x then 1 else 0) := fun v => hE' ▸ degree_erase E p hp u x hx v
    have hpar' : ∀ v, (degree E' v + (if v = x then 1 else 0) +
        (if v = w then 1 else 0)) % 2 = 0 := fun v => by
      have h1 := hpar v
      have h2 := hdeg v
      omega
    have hxw : (SimpleGraph.fromRel fun a b => (a, b) ∈ E').Reachable x w :=
      reach_of_parity _ E' x w le_rfl hpar'
    obtain ⟨Q, hQdef⟩ : ∃ Q : V → Prop,
        Q = fun v => (SimpleGraph.fromRel fun a b => (a, b) ∈ E').Reachable x v := ⟨_, rfl⟩
    have hQx : Q x := by subst hQdef; exact SimpleGraph.Reachable.refl _
    have hQw : Q w := by rw [hQdef]; exact hxw
    have hQ : ∀ q ∈ E', (Q q.1 ↔ Q q.2) := fun q hq => by
      rw [hQdef]
      exact ⟨fun h => h.trans (reach_of_mem E' q hq),
        fun h => h.trans (reach_of_mem E' q hq).symm⟩
    have hQ' : ∀ q ∈ E', (¬Q q.1 ↔ ¬Q q.2) := fun q hq => not_congr (hQ q hq)
    obtain ⟨A, hA⟩ : ∃ A, A = E'.filter fun q => Q q.1 := ⟨_, rfl⟩
    obtain ⟨B, hB⟩ : ∃ B, B = E'.filter fun q => ¬Q q.1 := ⟨_, rfl⟩
    have hAB : A + B = E' := by rw [hA, hB]; exact Multiset.filter_add_not _ _
    have hdA : ∀ v, ¬Q v → degree A v = 0 := fun v hv => degree_eq_zero_of A v (fun q hq => by
      rw [hA, Multiset.mem_filter] at hq
      exact ⟨fun h => hv (h ▸ hq.2), fun h => hv (h ▸ (hQ q hq.1).1 hq.2)⟩)
    have hdB : ∀ v, Q v → degree B v = 0 := fun v hv => degree_eq_zero_of B v (fun q hq => by
      rw [hB, Multiset.mem_filter] at hq
      exact ⟨fun h => hq.2 (h ▸ hv), fun h => (hQ' q hq.1).1 hq.2 (h ▸ hv)⟩)
    have hdE' : ∀ v, degree E' v = degree A v + degree B v := fun v => by
      rw [← degree_add, hAB]
    have hparA : ∀ v, (degree A v + (if v = x then 1 else 0) +
        (if v = w then 1 else 0)) % 2 = 0 := by
      intro v
      by_cases hv : Q v
      · have h1 := hpar' v
        have h2 := hdE' v
        have h3 := hdB v hv
        omega
      · have h1 : v ≠ x := fun h => hv (h ▸ hQx)
        have h2 : v ≠ w := fun h => hv (h ▸ hQw)
        simp [hdA v hv, h1, h2]
    have hparB : ∀ v, (degree B v + (if v = u then 1 else 0) +
        (if v = u then 1 else 0)) % 2 = 0 := by
      intro v
      by_cases hv : Q v
      · rw [hdB v hv]
        omega
      · have h1 : v ≠ x := fun h => hv (h ▸ hQx)
        have h2 : v ≠ w := fun h => hv (h ▸ hQw)
        have h3 := hpar' v
        have h4 := hdE' v
        have h5 := hdA v hv
        rw [if_neg h1, if_neg h2] at h3
        omega
    have hconnA : ∀ e ∈ A, (SimpleGraph.fromRel fun a b => (a, b) ∈ A).Reachable x e.1 := by
      intro e he
      rw [hA, Multiset.mem_filter] at he
      rw [hA]
      exact (reach_filter E' Q hQ (by rw [hQdef] at he; exact he.2) hQx).2
    have hconnB : ∀ e ∈ B, (SimpleGraph.fromRel fun a b => (a, b) ∈ B).Reachable u e.1 := by
      intro e he
      rw [hB, Multiset.mem_filter] at he
      have heE : e ∈ E := by rw [← hcons]; exact Multiset.mem_cons_of_mem he.1
      have hr := reach_erase E p u x hx (hconn e heE)
      rw [← hE'] at hr
      rcases hr with h | h
      · have hu : ¬Q u := fun hu => he.2 (by
          rw [hQdef] at hu ⊢
          exact hu.trans h)
        rw [hB]
        exact (reach_filter E' (fun v => ¬Q v) hQ' h hu).2
      · exact absurd (by rw [hQdef]; exact h) he.2
    have hcA : Multiset.card A ≤ n := by
      have := Multiset.card_le_card (Multiset.le_iff_exists_add.2 ⟨B, hAB.symm⟩)
      omega
    have hcB : Multiset.card B ≤ n := by
      have := Multiset.card_le_card (Multiset.le_iff_exists_add.2 ⟨A, (add_comm A B ▸ hAB).symm⟩)
      omega
    obtain ⟨ra, ha1, ha2, ha3⟩ := ih A x w hcA hparA hconnA
    obtain ⟨rb, hb1, hb2, hb3⟩ := ih B u u hcB hparB hconnB
    refine ⟨rb ++ ra, by simp [hb1], by simp [ha2], ?_⟩
    have huse := uses_append A B ra rb u x hb3 ha3 hb2 ha1
    unfold UsesEveryLineOnce at huse ⊢
    rw [huse, ← hcons, ← hAB]
    rcases hx with rfl | rfl
    · simp only [Multiset.map_cons, Multiset.map_add, Multiset.add_cons]
      rw [add_comm]
    · simp only [Multiset.map_cons, Multiset.map_add, Multiset.add_cons, Sym2.eq_swap]
      rw [add_comm]
#print axioms route_of_parity

theorem route_parity : ∀ (r : List V) (a b : V), r.head? = some a → r.getLast? = some b → ∀ v,
    (degree (Multiset.ofList (r.zip r.tail)) v + (if v = a then 1 else 0) +
      (if v = b then 1 else 0)) % 2 = 0
  | [], _, _, h, _, _ => by simp at h
  | [c], a, b, ha, hb, v => by
    simp only [List.head?_cons, List.getLast?_singleton, Option.some.injEq] at ha hb
    subst ha hb
    have : degree (Multiset.ofList ([c].zip [c].tail)) v = 0 := by simp [degree]
    rw [this]
    split_ifs <;> omega
  | c :: d :: t, a, b, ha, hb, v => by
    have ih := route_parity (d :: t) d b rfl (by rw [List.getLast?_cons_cons] at hb; exact hb) v
    simp only [List.head?_cons, Option.some.injEq] at ha
    subst ha
    have : (Multiset.ofList ((c :: d :: t).zip (c :: d :: t).tail)) =
        (c, d) ::ₘ Multiset.ofList ((d :: t).zip (d :: t).tail) := rfl
    rw [this, degree_cons]
    simp only at ih ⊢
    omega
#print axioms route_parity

theorem mem_of_uses (E : Multiset (V × V)) (r : List V) (h : UsesEveryLineOnce E r)
    (e : V × V) (he : e ∈ E) : e.1 ∈ r := by
  have hm : s(e.1, e.2) ∈ (Multiset.ofList ((r.zip r.tail).map fun p => s(p.1, p.2))) := by
    unfold UsesEveryLineOnce at h
    rw [h]
    exact Multiset.mem_map_of_mem _ he
  rw [Multiset.mem_coe, List.mem_map] at hm
  obtain ⟨⟨a, b⟩, hab, heq⟩ := hm
  have hz := List.of_mem_zip hab
  rcases Sym2.eq_iff.1 heq with ⟨h1, _⟩ | ⟨_, h2⟩
  · rw [← h1]; exact hz.1
  · rw [← h2]; exact List.mem_of_mem_tail hz.2
#print axioms mem_of_uses

theorem route_reach (E : Multiset (V × V)) : ∀ r : List V,
    (∀ p ∈ r.zip r.tail, s(p.1, p.2) ∈ E.map fun q => s(q.1, q.2)) →
    ∀ a ∈ r, ∀ b ∈ r, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable a b
  | [], _, a, ha, _, _ => by simp at ha
  | [c], _, a, ha, b, hb => by
    simp only [List.mem_singleton] at ha hb
    subst ha hb
    exact SimpleGraph.Reachable.refl _
  | c :: d :: t, h, a, ha, b, hb => by
    have ih := route_reach E (d :: t) (fun p hp => h p (List.mem_cons_of_mem _ hp))
    have hcd : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable c d := by
      have hm := h (c, d) List.mem_cons_self
      simp only [Multiset.mem_map] at hm
      obtain ⟨q, hq, hq'⟩ := hm
      rcases Sym2.eq_iff.1 hq' with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · rw [← h1, ← h2]; exact reach_of_mem E q hq
      · rw [← h1, ← h2]; exact (reach_of_mem E q hq).symm
    have hd : ∀ y ∈ c :: d :: t, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable y d := by
      intro y hy
      rcases List.mem_cons.1 hy with rfl | hy
      · exact hcd
      · exact ih y hy d List.mem_cons_self
    exact (hd a ha).trans (hd b hb).symm
#print axioms route_reach

theorem one_piece_of_uses (E : Multiset (V × V)) (r : List V) (h : UsesEveryLineOnce E r) :
    LinesInOnePiece E := by
  intro e he f hf
  apply route_reach E r _ e.1 (mem_of_uses E r h e he) f.1 (mem_of_uses E r h f hf)
  intro p hp
  unfold UsesEveryLineOnce at h
  rw [← h]
  exact Multiset.mem_coe.2 (List.mem_map.2 ⟨p, hp, rfl⟩)
#print axioms one_piece_of_uses

/-- Euler's and Hierholzer's theorem. A finite network (lines may repeat or loop) has a closed
route using every line exactly once exactly when its lines sit in one piece and every dot has an
even number of line-ends. -/
theorem closed_route_using_every_line_once_iff_one_piece_and_even_degrees
    (E : Multiset (V × V)) :
    (∃ route : List V, route.head? = route.getLast? ∧ UsesEveryLineOnce E route) ↔
      LinesInOnePiece E ∧ ∀ v : V, Even (degree E v) := by
  constructor
  · rintro ⟨r, hhl, hr⟩
    refine ⟨one_piece_of_uses E r hr, fun v => ?_⟩
    rw [degree_eq_of_uses E r hr v]
    cases hh : r.head? with
    | none =>
      have : r = [] := List.head?_eq_none_iff.1 hh
      subst this
      simp [degree]
    | some a =>
      have hl : r.getLast? = some a := hhl.symm.trans hh
      have := route_parity r a a hh hl v
      rw [Nat.even_iff]
      omega
  · rintro ⟨h1, h2⟩
    by_cases hE : E = 0
    · subst hE
      exact ⟨[], rfl, by simp [UsesEveryLineOnce]⟩
    · obtain ⟨e, he⟩ := Multiset.exists_mem_of_ne_zero hE
      obtain ⟨r, ha, hb, hr⟩ := route_of_parity _ E e.1 e.1 le_rfl (fun v => by
        have := Nat.even_iff.1 (h2 v)
        omega) (fun f hf => h1 e he f hf)
      exact ⟨r, by rw [ha, hb], hr⟩

/-- The open twin. For two different dots u and w, a route from u to w using every line exactly
once exists exactly when the lines sit in one piece and u and w are the only dots of odd degree. -/
theorem open_route_using_every_line_once_iff_one_piece_and_two_odd_ends
    (E : Multiset (V × V)) (u w : V) (huw : u ≠ w) :
    (∃ route : List V, route.head? = some u ∧ route.getLast? = some w ∧ UsesEveryLineOnce E route) ↔
      LinesInOnePiece E ∧ ∀ v : V, (Odd (degree E v) ↔ v = u ∨ v = w) := by
  constructor
  · rintro ⟨r, ha, hb, hr⟩
    refine ⟨one_piece_of_uses E r hr, fun v => ?_⟩
    have hp := route_parity r u w ha hb v
    rw [← degree_eq_of_uses E r hr v] at hp
    rw [Nat.odd_iff]
    by_cases hu : v = u
    · subst hu
      rw [if_pos rfl, if_neg huw] at hp
      simp only [true_or, iff_true]
      omega
    · by_cases hw : v = w
      · subst hw
        rw [if_neg hu, if_pos rfl] at hp
        simp only [or_true, iff_true]
        omega
      · rw [if_neg hu, if_neg hw] at hp
        simp only [hu, hw, or_self, iff_false]
        omega
  · rintro ⟨h1, h2⟩
    have hpar : ∀ v, (degree E v + (if v = u then 1 else 0) +
        (if v = w then 1 else 0)) % 2 = 0 := by
      intro v
      have h := h2 v
      rw [Nat.odd_iff] at h
      by_cases hu : v = u
      · subst hu
        rw [if_pos rfl, if_neg huw]
        have := h.2 (Or.inl rfl)
        omega
      · by_cases hw : v = w
        · subst hw
          rw [if_neg hu, if_pos rfl]
          have := h.2 (Or.inr rfl)
          omega
        · rw [if_neg hu, if_neg hw]
          have : ¬degree E v % 2 = 1 := fun hd => (h.1 hd).elim hu hw
          omega
    have hu : 0 < degree E u := ((h2 u).2 (Or.inl rfl)).pos
    obtain ⟨p, hp, x, hx⟩ := exists_edge_of_degree_pos E u hu
    have hconn : ∀ f ∈ E, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u f.1 := by
      intro f hf
      rcases hx with rfl | rfl
      · exact h1 _ hp f hf
      · exact (reach_of_mem E _ hp).symm.trans (h1 _ hp f hf)
    exact route_of_parity _ E u w le_rfl hpar hconn

/-- The handshake count. On finitely many dots the degrees add up to twice the number of lines,
so the number of odd dots is never odd. -/
theorem degrees_add_to_twice_the_lines [Fintype V] (E : Multiset (V × V)) :
    ∑ v, degree E v = 2 * Multiset.card E ∧
      Even (Finset.univ.filter fun v => Odd (degree E v)).card := by
  have hsum : ∑ v, degree E v = 2 * Multiset.card E := by
    induction E using Multiset.induction_on with
    | empty => simp [degree]
    | cons p E ih =>
      simp only [degree_cons, Finset.sum_add_distrib, ih, Multiset.card_cons]
      simp
      omega
  refine ⟨hsum, ?_⟩
  rw [← Finset.even_sum_iff_even_card_odd, hsum]
  exact even_two_mul _

-- Königsberg: A = 0 (island), B = 1 (north bank), C = 2 (south bank), D = 3 (east island).
def konigsberg : Multiset (Fin 4 × Fin 4) :=
  {(0, 1), (0, 1), (0, 2), (0, 2), (0, 3), (1, 3), (2, 3)}

-- Bridge-ends per land: A 5, B 3, C 3, D 3.
example : degree konigsberg 0 = 5 ∧ degree konigsberg 1 = 3 ∧
    degree konigsberg 2 = 3 ∧ degree konigsberg 3 = 3 := by decide
-- The tallies add to 14 = 2 × 7 bridges.
example : ∑ v, degree konigsberg v = 14 ∧ Multiset.card konigsberg = 7 := by decide
-- All four lands are odd: 4 is neither 0 nor 2.
example : (Finset.univ.filter fun v => Odd (degree konigsberg v)) = Finset.univ := by decide
-- An eighth bridge B-C: B and C rise to 4, leaving A and D the odd pair.
example : (Finset.univ.filter fun v => Odd (degree ((1, 2) ::ₘ konigsberg) v)) = {0, 3} := by
  decide

-- Two triangles apart, A-B-C and D-E-F: every degree is 2, so 0 odd dots, yet no route covers both.
example : ∀ v : Fin 6,
    degree ({(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)} : Multiset (Fin 6 × Fin 6)) v = 2 := by
  decide

-- The figure-eight of two squares: A..G = 0..6, the shared corner C = 2.
def figureEight : Multiset (Fin 7 × Fin 7) :=
  {(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 5), (5, 6), (6, 2)}

-- Every dot is even.
example : ∀ v, Even (degree figureEight v) := by decide
-- The route A-B-C-E-F-G-C-D-A uses every line once and closes.
example : UsesEveryLineOnce figureEight [0, 1, 2, 4, 5, 6, 2, 3, 0] := by
  unfold UsesEveryLineOnce; decide

-- The 3 x 3 street grid: junctions A..I = 0..8, 12 streets.
def grid : Multiset (Fin 9 × Fin 9) :=
  {(0, 1), (1, 2), (3, 4), (4, 5), (6, 7), (7, 8),
   (0, 3), (3, 6), (1, 4), (4, 7), (2, 5), (5, 8)}

-- 12 streets; the odd junctions are B, D, F, H.
example : Multiset.card grid = 12 := by decide
example : (Finset.univ.filter fun v => Odd (degree grid v)) = {1, 3, 5, 7} := by decide
-- Repeat the four streets E-F, G-H, D-G, B-E: every junction turns even.
example : ∀ v, Even (degree (grid + {(4, 5), (6, 7), (3, 6), (1, 4)}) v) := by decide
-- The swept route A-B-C-F-E-D-G-H-I-F-E-B-E-H-G-D-A: 16 passes, closed, every street once.
example : UsesEveryLineOnce (grid + {(4, 5), (6, 7), (3, 6), (1, 4)})
    [0, 1, 2, 5, 4, 3, 6, 7, 8, 5, 4, 1, 4, 7, 6, 3, 0] := by
  unfold UsesEveryLineOnce; decide

#print axioms closed_route_using_every_line_once_iff_one_piece_and_even_degrees
#print axioms open_route_using_every_line_once_iff_one_piece_and_two_odd_ends
#print axioms degrees_add_to_twice_the_lines

end EulerCircuits
