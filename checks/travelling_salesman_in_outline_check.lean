-- The travelling salesman: n towns with a direct two-way road between every pair hold exactly (n - 1)!/2 different rounds, the cheapest connecting tree costs no more than any round and, when no detour beats the direct road, some round costs at most twice the tree, and the card's six-town chart gives 60 rounds, the best at 148 miles, the worst at 267, greed at 160 and the tree at 105.
import Mathlib.Combinatorics.SimpleGraph.Hamiltonian
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Data.Set.Card
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

open SimpleGraph

namespace TSPHelp

variable {V : Type*}

/-- The roads of a route given as a list of towns. -/
def eo : List V → List (Sym2 V)
  | a :: b :: l => s(a, b) :: eo (b :: l)
  | _ => []

theorem walk_edges_eq {G : SimpleGraph V} : ∀ {u v : V} (p : G.Walk u v), p.edges = eo p.support
  | _, _, .nil => rfl
  | _, _, .cons _ .nil => rfl
  | _, _, .cons _ (.cons h p) => by
    have := walk_edges_eq (.cons h p)
    rw [Walk.edges_cons, this]
    simp [eo]

theorem support_cons_tail {G : SimpleGraph V} {u v : V} (p : G.Walk u v) :
    p.support = u :: p.support.tail := by
  cases p <;> simp

theorem mem_of_mem_eo : ∀ (L : List V) {e : Sym2 V} {x : V}, e ∈ eo L → x ∈ e → x ∈ L
  | a :: b :: l, e, x, he, hx => by
    simp only [eo, List.mem_cons] at he
    rcases he with rfl | he
    · rw [Sym2.mem_iff] at hx; rcases hx with rfl | rfl <;> simp
    · exact List.mem_cons_of_mem _ (mem_of_mem_eo _ he hx)
  | [], _, _, he, _ => by simp [eo] at he
  | [_], _, _, he, _ => by simp [eo] at he

theorem exists_walk (z : V) : ∀ (l : List V) (a : V), (a :: (l ++ [z])).Nodup →
    ∃ q : (⊤ : SimpleGraph V).Walk a z, q.support = a :: (l ++ [z])
  | [], a, h => by
    have : a ≠ z := by simpa using h
    exact ⟨Walk.cons (by simpa using this) Walk.nil, by simp⟩
  | b :: l, a, h => by
    have h1 : a ≠ b := by
      intro hab; subst hab; simp at h
    have h2 : (b :: (l ++ [z])).Nodup := (List.nodup_cons.mp h).2
    obtain ⟨q, hq⟩ := exists_walk z l b h2
    exact ⟨Walk.cons (by simpa using h1) q, by simp [hq]⟩

theorem exists_cycle [Fintype V] [DecidableEq V] (r : V) (l : List V) (hnd : l.Nodup)
    (hr : r ∉ l) (hall : ∀ v, v ≠ r → v ∈ l) (hlen : 2 ≤ l.length) :
    ∃ p : (⊤ : SimpleGraph V).Walk r r, p.IsHamiltonianCycle ∧ p.support = r :: (l ++ [r]) := by
  obtain ⟨a, b, m, rfl⟩ : ∃ a b m, l = a :: b :: m := by
    match l, hlen with
    | a :: b :: m, _ => exact ⟨a, b, m, rfl⟩
  have hnd2 : (a :: (b :: m ++ [r])).Nodup := by
    have : (a :: b :: m ++ [r]).Nodup := by
      rw [List.nodup_append]; refine ⟨hnd, by simp, ?_⟩
      intro x hx y hy; simp at hy; subst hy; rintro rfl; exact hr hx
    simpa using this
  obtain ⟨q, hq⟩ := exists_walk r (b :: m) a hnd2
  have hra : r ≠ a := by rintro rfl; simp at hr
  refine ⟨Walk.cons (by simpa using hra) q, ?_, by simp [hq]⟩
  rw [Walk.isHamiltonianCycle_iff_isCycle_and_support_count_tail_eq_one]
  refine ⟨?_, ?_⟩
  · rw [Walk.cons_isCycle_iff]
    refine ⟨(Walk.isPath_def _).2 (hq ▸ hnd2), ?_⟩
    rw [walk_edges_eq, hq]
    intro hmem
    simp only [List.cons_append, eo, List.mem_cons] at hmem
    rcases hmem with h | h
    · rw [Sym2.eq_iff] at h
      rcases h with ⟨h1, _⟩ | ⟨h1, _⟩
      · exact hra h1
      · exact hr (by simp [h1])
    · have := mem_of_mem_eo _ h (Sym2.mem_mk_right r a)
      have hnd3 := (List.nodup_cons.mp hnd2).1
      exact hnd3 (by simpa using this)
  · intro v
    simp only [Walk.support_cons, List.tail_cons, hq]
    apply List.count_eq_one_of_mem
    · simpa using hnd2
    · by_cases hv : v = r
      · simp [hv]
      · have := hall v hv; simp at this ⊢; tauto


theorem eo_append (x : V) (rest : List V) : ∀ pre : List V,
    eo (pre ++ x :: rest) = eo (pre ++ [x]) ++ eo (x :: rest)
  | [] => by simp [eo]
  | [p] => by simp [eo]
  | p :: q :: pre => by
    have := eo_append x rest (q :: pre)
    simp only [List.cons_append] at this ⊢
    simp only [eo, this, List.cons_append]

theorem insert_cost (w : Sym2 V → ℕ)
    (htri : ∀ i j k : V, i ≠ j → w s(i, j) ≤ w s(i, k) + w s(k, j))
    (pre post : List V) (x y c : V) (hyc : y ≠ c) :
    ((eo (pre ++ x :: y :: c :: post)).map w).sum ≤
      ((eo (pre ++ x :: c :: post)).map w).sum + 2 * w s(x, y) := by
  rw [eo_append, eo_append x (c :: post)]
  simp only [eo, List.map_append, List.map_cons, List.sum_append, List.sum_cons]
  have h1 := htri y c x hyc
  have h2 : w s(y, x) = w s(x, y) := by rw [Sym2.eq_swap]
  omega

theorem exists_cross [Fintype V] {G : SimpleGraph V} (hG : G.Connected) (M : List V)
    (hM : M.Nodup) (hlen : M.length < Fintype.card V) (x0 : V) (hx0 : x0 ∈ M) :
    ∃ x ∈ M, ∃ y, y ∉ M ∧ G.Adj x y := by
  classical
  obtain ⟨b, hb⟩ : ∃ b, b ∉ M := by
    by_contra h
    simp only [not_exists, not_not] at h
    have : (Finset.univ : Finset V) ⊆ M.toFinset := fun v _ => by simpa using h v
    have := Finset.card_le_card this
    rw [List.toFinset_card_of_nodup hM, Finset.card_univ] at this
    omega
  obtain ⟨d, -, hd1, hd2⟩ := (hG.preconnected x0 b).some.exists_boundary_dart {v | v ∈ M} hx0 hb
  exact ⟨d.fst, hd1, d.snd, hd2, d.adj⟩


theorem filter_eo_snoc [DecidableEq V] (z : V) : ∀ (m : List V) (a : V), z ∉ a :: m →
    (eo (a :: (m ++ [z]))).filter (fun e => z ∉ e) = eo (a :: m)
  | [], a, h => by
    simp [eo]
  | b :: m, a, h => by
    have hza : z ≠ a := fun h' => h (by simp [h'])
    have hzb : z ≠ b := fun h' => h (by simp [h'])
    have ih := filter_eo_snoc z m b (fun h' => h (List.mem_cons_of_mem _ h'))
    simp only [List.cons_append, eo] at ih ⊢
    rw [List.filter_cons_of_pos (by simp [Sym2.mem_iff, hza, hzb]), ih]

theorem last_edge (z : V) : ∀ (m : List V) (a : V), z ∉ a :: m →
    ∀ e ∈ eo (a :: (m ++ [z])), z ∈ e → e = s((a :: m).getLast (by simp), z)
  | [], a, h, e, he, _ => by simpa [eo] using he
  | b :: m, a, h, e, he, hz => by
    simp only [List.cons_append, eo, List.mem_cons] at he
    rcases he with rfl | he
    · exfalso; rw [Sym2.mem_iff] at hz
      rcases hz with rfl | rfl <;> simp at h
    · rw [List.getLast_cons (by simp)]
      exact last_edge z m b (fun h' => h (List.mem_cons_of_mem _ h')) e he hz

theorem path_unique [DecidableEq V] : ∀ (P Q : List V) (x : V), (x :: P).Nodup → (x :: Q).Nodup →
    (eo (x :: P)).toFinset = (eo (x :: Q)).toFinset → P = Q
  | [], [], _, _, _, _ => rfl
  | [], y :: Q, x, _, _, h => by
    have : s(x, y) ∈ (eo (x :: y :: Q)).toFinset := by simp [eo]
    rw [← h] at this; simp [eo] at this
  | y :: P, [], x, _, _, h => by
    have : s(x, y) ∈ (eo (x :: y :: P)).toFinset := by simp [eo]
    rw [h] at this; simp [eo] at this
  | y :: P, z :: Q, x, hP, hQ, h => by
    have hxP : x ∉ y :: P := (List.nodup_cons.mp hP).1
    have hxQ : x ∉ z :: Q := (List.nodup_cons.mp hQ).1
    have hyz : y = z := by
      have : s(x, y) ∈ (eo (x :: z :: Q)).toFinset := by rw [← h]; simp [eo]
      simp only [eo, List.toFinset_cons, Finset.mem_insert, List.mem_toFinset] at this
      rcases this with h1 | h1
      · rw [Sym2.eq_iff] at h1
        rcases h1 with ⟨_, h2⟩ | ⟨h2, _⟩
        · exact h2
        · exact absurd (h2 ▸ List.mem_cons_self) hxQ
      · exact absurd (mem_of_mem_eo _ h1 (Sym2.mem_mk_left x y)) hxQ
    subst hyz
    have hA : s(x, y) ∉ (eo (y :: P)).toFinset := fun h' => hxP
      (mem_of_mem_eo _ (List.mem_toFinset.mp h') (Sym2.mem_mk_left x y))
    have hB : s(x, y) ∉ (eo (y :: Q)).toFinset := fun h' => hxQ
      (mem_of_mem_eo _ (List.mem_toFinset.mp h') (Sym2.mem_mk_left x y))
    simp only [eo, List.toFinset_cons] at h
    have h' := congrArg (fun s => Finset.erase s s(x, y)) h
    simp only [Finset.erase_insert hA, Finset.erase_insert hB] at h'
    rw [path_unique P Q y (List.nodup_cons.mp hP).2 (List.nodup_cons.mp hQ).2 h']

/-- The roads of the round that leaves `r`, calls at the towns of `l` in order and comes home. -/
def cyc [DecidableEq V] (r : V) (l : List V) : Finset (Sym2 V) := (eo (r :: (l ++ [r]))).toFinset

#print axioms eo
#print axioms walk_edges_eq
#print axioms support_cons_tail
#print axioms mem_of_mem_eo
#print axioms exists_walk
#print axioms exists_cycle
#print axioms eo_append
#print axioms insert_cost
#print axioms exists_cross
#print axioms filter_eo_snoc
#print axioms last_edge
#print axioms path_unique
#print axioms cyc

end TSPHelp

/-- The number of tours. Take n towns with a direct road between every pair (the complete graph
on n towns), each road the same both ways. A tour is a round that calls at every town once and
comes back home, a Hamiltonian cycle; two rounds are the same tour when they drive the same roads,
whatever the starting town and whichever way round. Then there are exactly (n - 1)!/2 tours:
hold home still, order the other n - 1 towns every way, and halve, since a round driven backwards
is the same round. -/
theorem tours_of_n_towns_eq_factorial_div_two (n : ℕ) :
    {s : Finset (Sym2 (Fin n)) | ∃ (u : Fin n) (p : (⊤ : SimpleGraph (Fin n)).Walk u u),
        p.IsHamiltonianCycle ∧ p.edges.toFinset = s}.ncard = (n - 1).factorial / 2 := by
  open TSPHelp in
  rcases lt_or_ge n 3 with hn | hn
  · have hempty : {s : Finset (Sym2 (Fin n)) | ∃ (u : Fin n)
        (p : (⊤ : SimpleGraph (Fin n)).Walk u u), p.IsHamiltonianCycle ∧ p.edges.toFinset = s}
        = ∅ := by
      ext s
      simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_exists, not_and]
      intro u p hp _
      have h1 := hp.isCycle.three_le_length
      have h2 := hp.length_eq
      simp at h2
      omega
    rw [hempty, Set.ncard_empty]
    match n, hn with
    | 0, _ => rfl
    | 1, _ => rfl
    | 2, _ => rfl
  set r : Fin n := ⟨0, by omega⟩
  set b : List (Fin n) := (Finset.univ.erase r).toList
  have hb : b.Nodup := Finset.nodup_toList _
  have hblen : b.length = n - 1 := by simp [b, Finset.card_erase_of_mem]
  have hmemb : ∀ v, v ∈ b ↔ v ≠ r := by simp [b]
  set P := b.permutations.toFinset
  have hPcard : P.card = (n - 1).factorial := by
    rw [List.toFinset_card_of_nodup (List.nodup_permutations b hb), List.length_permutations,
      hblen]
  have hmemP : ∀ l, l ∈ P ↔ l.Perm b := by simp [P, List.mem_permutations]
  have good : ∀ l ∈ P, l.Nodup ∧ r ∉ l ∧ (∀ v, v ≠ r → v ∈ l) ∧ l.length = n - 1 := by
    intro l hl
    rw [hmemP] at hl
    refine ⟨hl.nodup_iff.2 hb, ?_, ?_, ?_⟩
    · rw [hl.mem_iff, hmemb]; exact fun h => h rfl
    · intro v hv; rw [hl.mem_iff, hmemb]; exact hv
    · rw [hl.length_eq, hblen]
  have hcyc : ∀ l ∈ P, ∃ p : (⊤ : SimpleGraph (Fin n)).Walk r r,
      p.IsHamiltonianCycle ∧ p.support = r :: (l ++ [r]) := by
    intro l hl
    obtain ⟨h1, h2, h3, h4⟩ := good l hl
    exact exists_cycle r l h1 h2 h3 (by omega)
  have hφrev : ∀ l ∈ P, cyc r l.reverse = cyc r l := by
    intro l hl
    obtain ⟨p, hp, hps⟩ := hcyc l hl
    have h1 : cyc r l = p.edges.toFinset := by rw [walk_edges_eq, hps]; rfl
    have h2 : cyc r l.reverse = p.reverse.edges.toFinset := by
      rw [walk_edges_eq, Walk.support_reverse, hps]; simp [cyc]
    rw [h1, h2, Walk.edges_reverse, List.toFinset_reverse]
  have hrevP : ∀ l ∈ P, l.reverse ∈ P := by
    intro l hl; rw [hmemP] at hl ⊢; exact (List.reverse_perm l).trans hl
  have hcons : ∀ l ∈ P, ∃ a m, l = a :: m ∧ m ≠ [] := by
    intro l hl
    obtain ⟨-, -, -, h4⟩ := good l hl
    match l, h4 with
    | a :: c :: m, _ => exact ⟨a, c :: m, rfl, by simp⟩
    | [], h4 => simp at h4; omega
    | [a], h4 => simp at h4; omega
  have hfilt : ∀ l ∈ P, (cyc r l).filter (fun e => r ∉ e) = (eo l).toFinset := by
    intro l hl
    obtain ⟨-, h2, -, -⟩ := good l hl
    obtain ⟨a, m, rfl, -⟩ := hcons l hl
    have key : (eo (r :: (a :: m ++ [r]))).filter (fun e => r ∉ e) = eo (a :: m) := by
      simp only [List.cons_append, eo]
      rw [List.filter_cons_of_neg (by simp)]
      have := filter_eo_snoc r m a h2
      simpa only [List.cons_append] using this
    ext e
    rw [cyc, Finset.mem_filter, List.mem_toFinset, List.mem_toFinset, ← key, List.mem_filter]
    simp
  have hsamehead : ∀ l ∈ P, ∀ l' ∈ P, l.head? = l'.head? → cyc r l = cyc r l' → l = l' := by
    intro l hl l' hl' hh hc
    have he : (eo l).toFinset = (eo l').toFinset := by rw [← hfilt l hl, ← hfilt l' hl', hc]
    obtain ⟨a, m, rfl, -⟩ := hcons l hl
    obtain ⟨a', m', rfl, -⟩ := hcons l' hl'
    simp only [List.head?_cons, Option.some.injEq] at hh
    subst hh
    rw [path_unique m m' a (good _ hl).1 (good _ hl').1 he]
  have hfiber : ∀ l ∈ P, ∀ l' ∈ P, cyc r l' = cyc r l → l' = l ∨ l' = l.reverse := by
    intro l hl l' hl' hc
    obtain ⟨a', m', rfl, -⟩ := hcons l' hl'
    obtain ⟨-, h2', -, -⟩ := good _ hl'
    obtain ⟨-, h2, -, -⟩ := good l hl
    obtain ⟨a, m, rfl, -⟩ := hcons l hl
    have hmem : s(r, a') ∈ cyc r (a :: m) := by rw [← hc]; simp [cyc, eo]
    simp only [cyc, List.cons_append, eo, List.toFinset_cons, Finset.mem_insert,
      List.mem_toFinset] at hmem
    rcases hmem with h | h
    · left
      rw [Sym2.eq_iff] at h
      rcases h with ⟨-, h⟩ | ⟨-, h⟩
      · subst h; exact hsamehead _ hl' _ hl rfl hc
      · exact absurd (by simp [h]) h2'
    · right
      have := last_edge r m a h2 _ h (Sym2.mem_mk_left r a')
      rw [Sym2.eq_iff] at this
      rcases this with ⟨-, h3⟩ | ⟨-, h3⟩
      · exact absurd (by simp [h3]) h2'
      · apply hsamehead _ hl' _ (hrevP _ hl)
        · rw [List.head?_reverse, List.getLast?_eq_getLast_of_ne_nil (by simp)]; simp [h3]
        · rw [hφrev _ hl, hc]
  have hne : ∀ l ∈ P, l ≠ l.reverse := by
    intro l hl heq
    obtain ⟨h1, -, -, -⟩ := good l hl
    obtain ⟨a, m, rfl, hm⟩ := hcons l hl
    have : (a :: m).head? = (a :: m).reverse.head? := by rw [← heq]
    rw [List.head?_reverse, List.getLast?_eq_getLast_of_ne_nil (by simp),
      List.getLast_cons hm] at this
    simp only [List.head?_cons, Option.some.injEq] at this
    have hmem : m.getLast hm ∈ m := List.getLast_mem hm
    rw [← this] at hmem
    exact (List.nodup_cons.mp h1).1 hmem
  have hset : {s : Finset (Sym2 (Fin n)) | ∃ (u : Fin n)
      (p : (⊤ : SimpleGraph (Fin n)).Walk u u), p.IsHamiltonianCycle ∧ p.edges.toFinset = s}
      = ↑(P.image (cyc r)) := by
    ext s
    simp only [Set.mem_ofPred_eq, Finset.coe_image, Set.mem_image, Finset.mem_coe]
    constructor
    · rintro ⟨u, p, hp, rfl⟩
      set p' := p.rotate r (hp.mem_support r)
      have hp' : p'.IsHamiltonianCycle := hp.rotate _
      have hE : p'.edges.toFinset = p.edges.toFinset :=
        List.toFinset_eq_of_perm _ _ (p.rotate_edges r _).perm
      have hLnd := hp'.isCycle.support_nodup
      have hLne : p'.support.tail ≠ [] := by
        have h1 := hp'.isCycle.three_le_length
        have h2 : p'.support.tail.length = p'.length := by
          simp [List.length_tail, Walk.length_support]
        intro h
        rw [h] at h2
        simp at h2
        omega
      have hLlast : p'.support.tail.getLast hLne = r := by
        rw [List.getLast_tail]; exact p'.getLast_support
      have hLeq : p'.support.tail = p'.support.tail.dropLast ++ [r] := by
        conv_lhs => rw [← List.dropLast_append_getLast hLne]
        rw [hLlast]
      set l := p'.support.tail.dropLast
      have hsupp : p'.support = r :: (l ++ [r]) := by rw [← hLeq]; exact support_cons_tail p'
      rw [hLeq, List.nodup_append] at hLnd
      have hrl : r ∉ l := fun h => hLnd.2.2 r h r (by simp) rfl
      have hlP : l ∈ P := by
        rw [hmemP, List.perm_ext_iff_of_nodup hLnd.1 hb]
        intro v
        rw [hmemb]
        constructor
        · rintro hv rfl; exact hrl hv
        · intro hv
          have := hp'.mem_support v
          rw [hsupp] at this
          simp [hv] at this
          exact this
      refine ⟨l, hlP, ?_⟩
      rw [← hE, walk_edges_eq, hsupp]; rfl
    · rintro ⟨l, hl, rfl⟩
      obtain ⟨p, hp, hps⟩ := hcyc l hl
      exact ⟨r, p, hp, by rw [walk_edges_eq, hps]; rfl⟩
  rw [hset, Set.ncard_coe_finset]
  have hcount := Finset.card_eq_sum_card_image (cyc r) P
  have hfib2 : ∀ s ∈ P.image (cyc r), (P.filter (fun a => cyc r a = s)).card = 2 := by
    intro s hs
    obtain ⟨l, hl, rfl⟩ := Finset.mem_image.mp hs
    have : P.filter (fun a => cyc r a = cyc r l) = {l, l.reverse} := by
      ext l'
      simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_singleton]
      constructor
      · rintro ⟨hl', he⟩; exact hfiber l hl l' hl' he
      · rintro (rfl | rfl)
        · exact ⟨hl, rfl⟩
        · exact ⟨hrevP _ hl, hφrev _ hl⟩
    rw [this, Finset.card_pair (hne l hl)]
  rw [Finset.sum_congr rfl hfib2, Finset.sum_const, smul_eq_mul, hPcard] at hcount
  omega

open Classical in
/-- The floor: the cheapest connecting tree costs no more than any tour. The chart `w` gives the
miles of each two-way road (a road is an unordered pair of towns, so the chart is symmetric), and
every pair of towns has a road. For every tour there is a tree joining all n towns whose roads add
to no more than the tour's legs: delete one leg of the tour and a spanning tree is left. So the
cheapest tree is at most the cheapest tour, T ≤ L. No triangle inequality is needed. -/
theorem cheapest_tree_at_most_any_tour (n : ℕ) (w : Sym2 (Fin n) → ℕ) (u : Fin n)
    (p : (⊤ : SimpleGraph (Fin n)).Walk u u) (hp : p.IsHamiltonianCycle) :
    ∃ t : SimpleGraph (Fin n), t.IsTree ∧ ∑ e ∈ t.edgeFinset, w e ≤ (p.edges.map w).sum := by
  set G := SimpleGraph.fromEdgeSet {e | e ∈ p.edges} with hG
  have hsub : ∀ e ∈ p.edges, e ∈ G.edgeSet := by
    intro e he
    rw [hG, edgeSet_fromEdgeSet]
    refine ⟨he, ?_⟩
    have := p.edges_subset_edgeSet he
    simpa [Sym2.mem_diagSet] using this
  have hconn : G.Connected := (Walk.isHamiltonianCycle_transfer hsub).2 hp |>.connected
  obtain ⟨t, hle, ht⟩ := hconn.exists_isTree_le
  refine ⟨t, ht, ?_⟩
  rw [← List.sum_toFinset _ hp.isCycle.edges_nodup]
  apply Finset.sum_le_sum_of_subset
  intro e he
  rw [mem_edgeFinset] at he
  have := edgeSet_mono hle he
  rw [hG, edgeSet_fromEdgeSet] at this
  simpa using this.1

open Classical in
/-- The ceiling: when no detour beats the direct road, some tour costs at most twice any
connecting tree. With at least three towns, a direct two-way road between every pair, and a chart
in which going from i to j by way of a third town k is never cheaper than the direct road, every
tree joining all n towns can be walked out and back and then short-cut into a tour costing at most
twice the tree's miles. So the cheapest tour is at most twice the cheapest tree, L ≤ 2T. -/
theorem some_tour_at_most_twice_any_tree (n : ℕ) (hn : 3 ≤ n) (w : Sym2 (Fin n) → ℕ)
    (htri : ∀ i j k : Fin n, i ≠ j → w s(i, j) ≤ w s(i, k) + w s(k, j))
    (t : SimpleGraph (Fin n)) (ht : t.IsTree) :
    ∃ (u : Fin n) (p : (⊤ : SimpleGraph (Fin n)).Walk u u),
      p.IsHamiltonianCycle ∧ (p.edges.map w).sum ≤ 2 * ∑ e ∈ t.edgeFinset, w e := by
  open TSPHelp in
  set r : Fin n := ⟨0, by omega⟩
  have key : ∀ k, 2 ≤ k → k ≤ n → ∃ M : List (Fin n), M.Nodup ∧ M.head? = some r ∧
      M.length = k ∧ ∃ F : Finset (Sym2 (Fin n)), F ⊆ t.edgeFinset ∧
      (∀ e ∈ F, ∀ v ∈ e, v ∈ M) ∧ ((eo (M ++ [r])).map w).sum ≤ 2 * ∑ e ∈ F, w e := by
    intro k hk
    induction k, hk using Nat.le_induction with
    | base =>
      intro h2
      obtain ⟨x, hx, y, hy, hxy⟩ := exists_cross ht.connected [r] (by simp)
        (by simp; omega) r (by simp)
      simp only [List.mem_singleton] at hx hy
      subst hx
      refine ⟨[r, y], by simpa using Ne.symm hy, rfl, rfl, {s(r, y)}, ?_, ?_, ?_⟩
      · simpa using hxy
      · intro e he v hv
        simp only [Finset.mem_singleton] at he; subst he
        rw [Sym2.mem_iff] at hv; rcases hv with rfl | rfl <;> simp
      · simp [eo, Sym2.eq_swap]; omega
    | succ k hk ih =>
      intro hkn
      obtain ⟨M, hMnd, hMh, hMl, F, hF, hFM, hcost⟩ := ih (by omega)
      have hrM : r ∈ M := by
        cases M with
        | nil => simp at hMh
        | cons a M => simp at hMh; simp [hMh]
      obtain ⟨x, hx, y, hy, hxy⟩ := exists_cross ht.connected M hMnd
        (by simp; omega) r hrM
      obtain ⟨A, B, rfl⟩ := List.append_of_mem hx
      obtain ⟨c, post, hc⟩ : ∃ c post, B ++ [r] = c :: post := by
        cases B with
        | nil => exact ⟨r, [], rfl⟩
        | cons b B => exact ⟨b, B ++ [r], rfl⟩
      have hcM : c ∈ A ++ x :: B := by
        have : c ∈ B ++ [r] := by rw [hc]; simp
        simp at this
        rcases this with h | rfl
        · simp [h]
        · exact hrM
      have hyc : y ≠ c := by rintro rfl; exact hy hcM
      have hperm : (A ++ x :: y :: B).Perm (y :: (A ++ x :: B)) := by
        have := @List.perm_middle _ y (A ++ [x]) B
        simpa using this
      refine ⟨A ++ x :: y :: B, ?_, ?_, ?_, insert s(x, y) F, ?_, ?_, ?_⟩
      · rw [hperm.nodup_iff, List.nodup_cons]; exact ⟨hy, hMnd⟩
      · cases A <;> simp_all
      · simp at hMl ⊢; omega
      · intro e he
        rw [Finset.mem_insert] at he
        rcases he with rfl | he
        · simpa using hxy
        · exact hF he
      · intro e he v hv
        rw [Finset.mem_insert] at he
        rcases he with rfl | he
        · rw [Sym2.mem_iff] at hv
          rcases hv with rfl | rfl
          · rw [hperm.mem_iff]; exact List.mem_cons_of_mem _ hx
          · rw [hperm.mem_iff]; simp
        · rw [hperm.mem_iff]; exact List.mem_cons_of_mem _ (hFM e he v hv)
      · have hnot : s(x, y) ∉ F := fun h => hy (hFM _ h y (Sym2.mem_mk_right x y))
        rw [Finset.sum_insert hnot]
        have e1 : A ++ x :: y :: B ++ [r] = A ++ x :: y :: c :: post := by
          simp [← hc]
        have e2 : A ++ x :: B ++ [r] = A ++ x :: c :: post := by
          simp [← hc]
        rw [e2] at hcost
        rw [e1]
        have := insert_cost w htri A post x y c hyc
        omega
  obtain ⟨M, hMnd, hMh, hMl, F, hF, -, hcost⟩ := key n (by omega) le_rfl
  obtain ⟨l, rfl⟩ : ∃ l, M = r :: l := by
    cases M with
    | nil => simp at hMh
    | cons a M => simp at hMh; exact ⟨M, by rw [hMh]⟩
  have hall : ∀ v, v ∈ r :: l := by
    have : (r :: l).toFinset = Finset.univ := by
      apply Finset.eq_univ_of_card
      rw [List.toFinset_card_of_nodup hMnd, hMl, Fintype.card_fin]
    intro v; simpa using (this ▸ Finset.mem_univ v : v ∈ (r :: l).toFinset)
  rw [List.nodup_cons] at hMnd
  obtain ⟨p, hp, hps⟩ := exists_cycle r l hMnd.2 hMnd.1
    (fun v hv => by have := hall v; simp [hv] at this; exact this)
    (by simp at hMl; omega)
  refine ⟨r, p, hp, ?_⟩
  rw [walk_edges_eq, hps]
  calc ((eo (r :: (l ++ [r]))).map w).sum ≤ 2 * ∑ e ∈ F, w e := by simpa using hcost
    _ ≤ 2 * ∑ e ∈ t.edgeFinset, w e := by
      have := Finset.sum_le_sum_of_subset (f := w) hF
      omega

/-! ### The card's worked numbers -/

/-- The rep's chart: miles between towns A to F, numbered 0 to 5. -/
def chart : Fin 6 → Fin 6 → ℕ :=
  ![![0, 34, 42, 18, 28, 19],
    ![34, 0, 28, 51, 26, 35],
    ![42, 28, 0, 58, 14, 54],
    ![18, 51, 58, 0, 44, 25],
    ![28, 26, 14, 44, 0, 42],
    ![19, 35, 54, 25, 42, 0]]

/-- The miles of a round that leaves A (town 0), calls at the five other towns in the order given,
and comes home to A. -/
def roundCost (l : List (Fin 6)) : ℕ :=
  ((0 :: l).zip (l ++ [0])).foldr (fun e acc => chart e.1 e.2 + acc) 0

-- The chart is symmetric, and no detour beats the direct road.
example : ∀ i j : Fin 6, chart i j = chart j i := by decide
example : ∀ i j k : Fin 6, chart i j ≤ chart i k + chart k j := by decide
-- Six towns: 6! = 720 orders, 720 / 6 = 120 with home held still, halved to 60 tours.
example : Nat.factorial 6 = 720 ∧ 720 / 6 = 120 ∧ Nat.factorial 5 = 120 ∧
    Nat.factorial (6 - 1) / 2 = 60 := by decide
/-- Every order of the towns in `rest`, built town by town as in the card's code (`k` counts the
towns still to place). -/
def orders : ℕ → List (Fin 6) → List (List (Fin 6))
  | 0, _ => [[]]
  | k + 1, rest => rest.flatMap fun x => (orders k (rest.erase x)).map (x :: ·)

/-- The 5! orders of the five towns B to F that a round from A can call in. -/
def fiveTownOrders : List (List (Fin 6)) := orders 5 [1, 2, 3, 4, 5]

-- 120 orders, all different, each calling at B, C, D, E and F once.
example : fiveTownOrders.length = 120 ∧ fiveTownOrders.Nodup := by decide +kernel
example : ∀ l ∈ fiveTownOrders, l.Perm [1, 2, 3, 4, 5] := by decide +kernel
-- Each tour appears twice, once each way round: keeping the orders whose first town is below
-- the last leaves 60.
example : (fiveTownOrders.filter (fun l => l.head! < l.getLast!)).length = 60 := by decide +kernel
-- Cheapest, A-D-F-B-C-E-A: 18 + 25 + 35 + 28 + 14 + 28 = 148 miles.
example : roundCost [3, 5, 1, 2, 4] = 148 ∧ 18 + 25 + 35 + 28 + 14 + 28 = 148 := by decide
-- Dearest, A-E-F-C-D-B-A: 28 + 42 + 54 + 58 + 51 + 34 = 267 miles.
example : roundCost [4, 5, 2, 3, 1] = 267 ∧ 28 + 42 + 54 + 58 + 51 + 34 = 267 := by decide
-- Every one of the 120 orders costs between 148 and 267 miles.
example : ∀ l ∈ fiveTownOrders, 148 ≤ roundCost l ∧ roundCost l ≤ 267 := by decide +kernel
-- The nearest-town rule from A, A-D-F-B-E-C-A: 18 + 25 + 35 + 26 + 14 + 42 = 160 miles, 12 more.
example : roundCost [3, 5, 1, 4, 2] = 160 ∧ 160 - 148 = 12 := by decide
-- The cheapest connecting tree, A-D 18, A-F 19, A-E 28, E-C 14, E-B 26: 105 miles.
example : chart 0 3 + chart 0 5 + chart 0 4 + chart 4 2 + chart 4 1 = 105 := by decide
-- The bracket: 105 ≤ 148 ≤ 210, and the tree read as a route is 43 miles short.
example : 105 ≤ 148 ∧ 148 ≤ 2 * 105 ∧ 148 - 105 = 43 := by decide
-- Tours to check as towns are added: 7 → 360, 10 → 181,440, 15 → 43,589,145,600,
-- 20 → 60,822,550,204,416,000.
example : Nat.factorial 6 / 2 = 360 ∧ Nat.factorial 9 / 2 = 181440 ∧
    Nat.factorial 14 / 2 = 43589145600 ∧ Nat.factorial 19 / 2 = 60822550204416000 := by
  norm_num [Nat.factorial]
-- One-way roads: the halving fails and six towns give (6 - 1)! = 120 rounds.
example : Nat.factorial (6 - 1) = 120 := by decide
-- The set-by-set method keeps 5 × 2⁴ = 80 records for six towns, 19 × 2¹⁸ = 4,980,736 for twenty.
example : 5 * 2 ^ 4 = 80 ∧ 19 * 2 ^ 18 = 4980736 := by norm_num

#print axioms tours_of_n_towns_eq_factorial_div_two
#print axioms cheapest_tree_at_most_any_tour
#print axioms some_tour_at_most_twice_any_tree
