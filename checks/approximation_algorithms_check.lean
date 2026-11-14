-- Approximation: the matching rule and rounding at 1/f each use at most a fixed multiple (2, and f) of the fewest posts, and greedy covering uses at most H(n) times the fewest, with H(n) ≤ 1 + ln n.
import Mathlib.Data.Finset.Card
import Mathlib.Data.Fintype.Powerset
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.NumberTheory.Harmonic.Bounds
import Mathlib.Tactic.NormNum

open Finset

/-! ## Vertex cover: inspectors only at the two ends of each route

A route is a pair `(u, v)` of stations, its two ends; routes may repeat (several routes
on one line). A set of posts `C` checks every route, a **vertex cover**, when each route
has a post at one of its ends. All posts cost the same, so a plan's cost is `C.card`. -/

/-- A set of posts checks every route: each route has a post at one of its two ends. -/
abbrev IsCover {V : Type*} (routes : List (V × V)) (C : Finset V) : Prop :=
  ∀ e ∈ routes, e.1 ∈ C ∨ e.2 ∈ C

/-- The matching rule: go through the routes in order; when a route is still unchecked,
post inspectors at both its ends. -/
def matchingRule {V : Type*} [DecidableEq V] (routes : List (V × V)) : Finset V :=
  routes.foldl (fun posts e => if e.1 ∈ posts ∨ e.2 ∈ posts then posts else insert e.1 (insert e.2 posts)) ∅

/-- One step of the matching rule. -/
def matchingStep {V : Type*} [DecidableEq V] (posts : Finset V) (e : V × V) : Finset V :=
  if e.1 ∈ posts ∨ e.2 ∈ posts then posts else insert e.1 (insert e.2 posts)

theorem matchingStep_superset {V : Type*} [DecidableEq V] (l : List (V × V)) :
    ∀ P : Finset V, P ⊆ l.foldl matchingStep P := by
  induction l with
  | nil => intro P; simp
  | cons e l ih =>
    intro P
    simp only [List.foldl_cons]
    refine subset_trans ?_ (ih _)
    unfold matchingStep
    split_ifs
    · exact subset_refl _
    · intro v hv; simp [hv]

theorem matchingStep_cover {V : Type*} [DecidableEq V] (l : List (V × V)) :
    ∀ P : Finset V, ∀ e ∈ l, e.1 ∈ l.foldl matchingStep P ∨ e.2 ∈ l.foldl matchingStep P := by
  induction l with
  | nil => intro P e he; simp at he
  | cons a l ih =>
    intro P e he
    simp only [List.foldl_cons]
    rcases List.mem_cons.mp he with rfl | he
    · have hs := matchingStep_superset l (matchingStep P e)
      have : e.1 ∈ matchingStep P e ∨ e.2 ∈ matchingStep P e := by
        unfold matchingStep
        split_ifs with h
        · exact h
        · left; simp
      rcases this with h | h
      · exact Or.inl (hs h)
      · exact Or.inr (hs h)
    · exact ih _ e he

theorem matchingStep_card {V : Type*} [DecidableEq V] (l : List (V × V)) (C : Finset V)
    (hC : IsCover l C) :
    ∀ P : Finset V, P.card ≤ 2 * (P ∩ C).card →
      (l.foldl matchingStep P).card ≤ 2 * ((l.foldl matchingStep P) ∩ C).card := by
  induction l with
  | nil => intro P hP; simpa using hP
  | cons e l ih =>
    intro P hP
    simp only [List.foldl_cons]
    apply ih (fun a ha => hC a (List.mem_cons_of_mem _ ha))
    unfold matchingStep
    split_ifs with h
    · exact hP
    · push Not at h
      obtain ⟨h1, h2⟩ := h
      have hcard : (insert e.1 (insert e.2 P)).card ≤ P.card + 2 := by
        calc (insert e.1 (insert e.2 P)).card ≤ (insert e.2 P).card + 1 := card_insert_le _ _
          _ ≤ P.card + 1 + 1 := by gcongr; exact card_insert_le _ _
          _ = P.card + 2 := by ring
      have hcov := hC e (List.mem_cons_self ..)
      have hgain : (P ∩ C).card + 1 ≤ (insert e.1 (insert e.2 P) ∩ C).card := by
        rcases hcov with hc | hc
        · have hsub : insert e.1 (P ∩ C) ⊆ insert e.1 (insert e.2 P) ∩ C := by
            intro v hv
            simp only [mem_insert, mem_inter] at hv ⊢
            rcases hv with rfl | ⟨hv1, hv2⟩
            · exact ⟨Or.inl rfl, hc⟩
            · exact ⟨Or.inr (Or.inr hv1), hv2⟩
          have hnot : e.1 ∉ P ∩ C := fun hm => h1 (mem_inter.mp hm).1
          calc (P ∩ C).card + 1 = (insert e.1 (P ∩ C)).card := (card_insert_of_notMem hnot).symm
            _ ≤ _ := card_le_card hsub
        · have hsub : insert e.2 (P ∩ C) ⊆ insert e.1 (insert e.2 P) ∩ C := by
            intro v hv
            simp only [mem_insert, mem_inter] at hv ⊢
            rcases hv with rfl | ⟨hv1, hv2⟩
            · exact ⟨Or.inr (Or.inl rfl), hc⟩
            · exact ⟨Or.inr (Or.inr hv1), hv2⟩
          have hnot : e.2 ∉ P ∩ C := fun hm => h2 (mem_inter.mp hm).1
          calc (P ∩ C).card + 1 = (insert e.2 (P ∩ C)).card := (card_insert_of_notMem hnot).symm
            _ ≤ _ := card_le_card hsub
      omega

#print axioms matchingStep_superset
#print axioms matchingStep_cover
#print axioms matchingStep_card

/-- The matching rule is a 2-approximation: on every list of routes, each with two ends
and every post costing the same, the posts it chooses check every route, and they number
at most 2 times the posts of any plan that checks every route, so at most 2 × OPT. -/
theorem matching_rule_le_two_mul_opt {V : Type*} [DecidableEq V] (routes : List (V × V)) :
    IsCover routes (matchingRule routes) ∧
      ∀ C : Finset V, IsCover routes C → (matchingRule routes).card ≤ 2 * C.card := by
  have hdef : matchingRule routes = routes.foldl matchingStep ∅ := rfl
  refine ⟨?_, ?_⟩
  · intro e he
    rw [hdef]
    exact matchingStep_cover routes ∅ e he
  · intro C hC
    have := matchingStep_card routes C hC ∅ (by simp)
    rw [hdef]
    calc _ ≤ _ := this
      _ ≤ 2 * C.card := by gcongr; exact inter_subset_right

/-! ## Rounding the fractional plan at 1/f

Each route `i` can be checked at the stations in `route i`, at most `f` of them.
A fractional plan gives each station a fraction `x v` between 0 and 1, with the fractions
at each route's stations adding to at least 1. The cheapest such plan has total LP. -/

/-- Rounding: if every route can be checked at no more than `f` stations and `x` is a
cheapest fractional plan (fractions between 0 and 1, at least 1 in total on each route),
then posting wherever `x v ≥ 1/f` checks every route, uses at most `f × LP` posts, and so
at most `f` times the posts of any plan that checks every route. With two ends per route,
`f = 2` and the threshold is 0.5. -/
theorem lp_rounding_le_f_mul_opt {V ι : Type*} [Fintype V] [DecidableEq V]
    (route : ι → Finset V) (f : ℕ) (hf0 : 0 < f) (hf : ∀ i, (route i).card ≤ f)
    (x : V → ℝ) (hx0 : ∀ v, 0 ≤ x v) (hx1 : ∀ v, x v ≤ 1)
    (hfeas : ∀ i, 1 ≤ ∑ v ∈ route i, x v)
    (hopt : ∀ z : V → ℝ, (∀ v, 0 ≤ z v) → (∀ v, z v ≤ 1) → (∀ i, 1 ≤ ∑ v ∈ route i, z v) →
      ∑ v, x v ≤ ∑ v, z v) :
    (∀ i, ∃ v ∈ route i, (1 : ℝ) / f ≤ x v) ∧
      ((univ.filter fun v => (1 : ℝ) / f ≤ x v).card : ℝ) ≤ f * ∑ v, x v ∧
      ∀ C : Finset V, (∀ i, ∃ v ∈ route i, v ∈ C) →
        ((univ.filter fun v => (1 : ℝ) / f ≤ x v).card : ℝ) ≤ f * C.card := by
  have hfR : (0 : ℝ) < f := by exact_mod_cast hf0
  have hA : ((univ.filter fun v => (1 : ℝ) / f ≤ x v).card : ℝ) ≤ f * ∑ v, x v := by
    have h1 : ((univ.filter fun v => (1 : ℝ) / f ≤ x v).card : ℝ)
        ≤ ∑ v ∈ univ.filter (fun v => (1 : ℝ) / f ≤ x v), (f : ℝ) * x v := by
      rw [Finset.card_eq_sum_ones, Nat.cast_sum]
      apply Finset.sum_le_sum
      intro v hv
      have hv' := (mem_filter.mp hv).2
      rw [div_le_iff₀' hfR] at hv'
      simpa using hv'
    refine h1.trans ?_
    rw [← Finset.mul_sum]
    gcongr
    · exact fun v _ _ => hx0 v
    · exact subset_univ _
  refine ⟨?_, hA, ?_⟩
  · intro i
    by_contra hcon
    push Not at hcon
    have hlt : ∑ v ∈ route i, x v ≤ ∑ v ∈ route i, (1 : ℝ) / f :=
      Finset.sum_le_sum fun v hv => (hcon v hv).le
    have hne : (route i).Nonempty := by
      rw [Finset.nonempty_iff_ne_empty]
      intro he
      have := hfeas i
      rw [he] at this
      norm_num at this
    have hlt' : ∑ v ∈ route i, x v < ∑ v ∈ route i, (1 : ℝ) / f :=
      Finset.sum_lt_sum_of_nonempty hne fun v hv => hcon v hv
    rw [Finset.sum_const, nsmul_eq_mul] at hlt'
    have hc : ((route i).card : ℝ) ≤ f := by exact_mod_cast hf i
    have : ((route i).card : ℝ) * (1 / f) ≤ 1 := by
      rw [mul_one_div, div_le_one hfR]; exact hc
    linarith [hfeas i]
  · intro C hC
    refine hA.trans ?_
    gcongr
    have := hopt (fun v => if v ∈ C then 1 else 0)
      (fun v => by split_ifs <;> norm_num) (fun v => by split_ifs <;> norm_num)
      (by
        intro i
        obtain ⟨v, hv, hvC⟩ := hC i
        calc (1 : ℝ) = (fun v => if v ∈ C then (1 : ℝ) else 0) v := by simp [hvC]
          _ ≤ ∑ w ∈ route i, (fun v => if v ∈ C then (1 : ℝ) else 0) w :=
            Finset.single_le_sum (f := fun v => if v ∈ C then (1 : ℝ) else 0)
              (fun w _ => by positivity) hv)
    refine this.trans (le_of_eq ?_)
    rw [Finset.sum_ite_mem, univ_inter]
    simp

/-! ## Greedy set cover

Each station `k` is the set `S k` of routes calling there; `U` is the set of routes still
to check. A run of greedy is a list of stations: while some route is unchecked, it takes a
station where the most unchecked routes call (ties broken any way), and it stops as soon
as every route is checked. -/

/-- `IsGreedy S picks U`: the list `picks` is a run of greedy that starts with the routes
`U` unchecked and ends with none unchecked. -/
def IsGreedy {α ι : Type*} [DecidableEq α] (S : ι → Finset α) : List ι → Finset α → Prop
  | [], U => U = ∅
  | k :: ks, U => U.Nonempty ∧ (∀ j, (S j ∩ U).card ≤ (S k ∩ U).card) ∧ IsGreedy S ks (U \ S k)

instance IsGreedy.decide {α ι : Type*} [DecidableEq α] [Fintype ι] (S : ι → Finset α) :
    ∀ (picks : List ι) (U : Finset α), Decidable (IsGreedy S picks U)
  | [], U => inferInstanceAs (Decidable (U = ∅))
  | k :: ks, U =>
    have := IsGreedy.decide S ks (U \ S k)
    inferInstanceAs (Decidable (U.Nonempty ∧ (∀ j, (S j ∩ U).card ≤ (S k ∩ U).card) ∧
      IsGreedy S ks (U \ S k)))

/-- Tail of the harmonic sum: `H(a + m) - H(a) ≥ m / (a + m)`. -/
theorem harmonic_tail_ge (a m : ℕ) :
    (m : ℚ) / (a + m) ≤ harmonic (a + m) - harmonic a := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [← add_assoc, harmonic_succ]
    push_cast
    have h1 : (m : ℚ) / (a + m) ≥ m / (a + m + 1) := by
      rcases Nat.eq_zero_or_pos (a + m) with h | h
      · have : m = 0 := by omega
        subst this; simp
      · have hp : (0 : ℚ) < a + m := by exact_mod_cast h
        apply div_le_div_of_nonneg_left (by positivity) hp (by linarith)
    have h2 : ((m : ℚ) + 1) / (a + (m + 1)) = m / (a + m + 1) + (a + m + 1 : ℚ)⁻¹ := by
      have hp : (0 : ℚ) < a + m + 1 := by positivity
      field_simp
      ring
    rw [h2]
    linarith

theorem greedy_main {α ι : Type*} [DecidableEq α] [Fintype ι]
    (S : ι → Finset α) (picks : List ι) :
    ∀ U : Finset α, IsGreedy S picks U → ∀ C : Finset ι, U ⊆ C.biUnion S →
      (picks.length : ℚ) ≤ harmonic U.card * C.card := by
  induction picks with
  | nil =>
    intro U _ C _
    simp only [List.length_nil, Nat.cast_zero]
    have : (0 : ℚ) ≤ harmonic U.card := by
      unfold harmonic; positivity
    positivity
  | cons k ks ih =>
    intro U hg C hC
    obtain ⟨hne, hmax, hrest⟩ := hg
    have hrec := ih (U \ S k) hrest C (subset_trans sdiff_subset hC)
    set n := U.card with hn
    set m := (S k ∩ U).card with hm
    have hrc : (U \ S k).card = n - m := card_sdiff
    have hmn : m ≤ n := card_le_card inter_subset_right
    have hn1 : 1 ≤ n := hne.card_pos
    -- n ≤ |C| * m
    have hcov : n ≤ C.card * m := by
      have hU : U = C.biUnion (fun j => S j ∩ U) := by
        ext a
        constructor
        · intro ha
          obtain ⟨j, hj, haj⟩ := mem_biUnion.mp (hC ha)
          exact mem_biUnion.mpr ⟨j, hj, mem_inter.mpr ⟨haj, ha⟩⟩
        · intro ha
          obtain ⟨j, _, haj⟩ := mem_biUnion.mp ha
          exact (mem_inter.mp haj).2
      calc n = (C.biUnion (fun j => S j ∩ U)).card := by rw [hn]; exact congrArg _ hU
        _ ≤ ∑ j ∈ C, (S j ∩ U).card := card_biUnion_le
        _ ≤ C.card * m := by
          have := Finset.sum_le_card_nsmul C (fun j => (S j ∩ U).card) m (fun j _ => hmax j)
          simpa using this
    have htail := harmonic_tail_ge (n - m) m
    have hnm : n - m + m = n := Nat.sub_add_cancel hmn
    rw [hnm] at htail
    rw [hrc] at hrec
    simp only [List.length_cons]
    push_cast
    have hnQ : (0 : ℚ) < n := by exact_mod_cast hn1
    have hcovQ : (n : ℚ) ≤ C.card * m := by exact_mod_cast hcov
    have hnn : ((n - m : ℕ) : ℚ) + m = n := by exact_mod_cast hnm
    rw [hnn] at htail
    -- (H n - H (n-m)) * |C| ≥ m |C| / n ≥ 1
    have key : 1 ≤ (harmonic n - harmonic (n - m)) * C.card := by
      have hc0 : (0 : ℚ) ≤ C.card := by positivity
      calc (1 : ℚ) ≤ (m : ℚ) / n * C.card := by
            rw [div_mul_eq_mul_div, le_div_iff₀ hnQ]; linarith
        _ ≤ _ := by gcongr
    nlinarith

#print axioms harmonic_tail_ge
#print axioms greedy_main

/-- Greedy is within the harmonic sum: on every set-cover instance, every run of greedy
uses at most `H(n) = 1 + 1/2 + … + 1/n` times the posts of any plan that checks all `n`
routes, so at most `H(n) × OPT`; and `H(n) ≤ 1 + ln n`. -/
theorem greedy_le_harmonic_mul_opt {α ι : Type*} [DecidableEq α] [Fintype ι]
    (S : ι → Finset α) (U : Finset α) (picks : List ι) (hg : IsGreedy S picks U) :
    (∀ C : Finset ι, U ⊆ C.biUnion S → (picks.length : ℝ) ≤ (harmonic U.card : ℝ) * C.card) ∧
      (harmonic U.card : ℝ) ≤ 1 + Real.log U.card := by
  refine ⟨?_, harmonic_le_one_add_log _⟩
  intro C hC
  have := greedy_main S picks U hg C hC
  exact_mod_cast this

/-! ## The card's city

Termini as `Fin 8`: N 0, S 1, A 2, B 3, C 4, D 5, E 6, F 7; interchanges X 8, Y 9, Z 10.
Routes 1-13 leave N, 14-26 leave S, 27-29 run the ring A-B-C, 30 is the N-S express
(here numbered 0 to 29). -/

/-- The 30 routes by their two ends. -/
def cityEnds : List (Fin 8 × Fin 8) :=
  [(0, 5), (0, 6), (0, 7), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 2), (0, 3), (0, 4),
   (0, 5), (1, 6), (1, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 2), (1, 3), (1, 4),
   (1, 5), (1, 6), (2, 3), (3, 4), (4, 2), (0, 1)]

/-- Every station each route calls at: its two ends, then any interchange. -/
def cityStops : List (List (Fin 11)) :=
  [[0, 5, 8], [0, 6, 8], [0, 7, 8], [0, 2, 8], [0, 3, 8], [0, 4, 8], [0, 5, 8], [0, 6, 8],
   [0, 7, 9], [0, 2, 9], [0, 3, 9], [0, 4, 9], [0, 5], [1, 6, 8], [1, 7, 8], [1, 2, 8],
   [1, 3, 8], [1, 4, 8], [1, 5, 8], [1, 6, 8], [1, 7, 8], [1, 2, 9], [1, 3, 9], [1, 4, 9],
   [1, 5, 9], [1, 6], [2, 3, 10], [3, 4, 10], [4, 2, 10], [0, 1]]

/-- Station `k` as the set of routes calling there. -/
def citySees (k : Fin 11) : Finset (Fin 30) :=
  univ.filter fun i => k ∈ cityStops.getD i.val []

-- Trying every set of posts: 2^8 = 256 at termini, 2^11 = 2,048 at any station; 3^8 = 6,561 half-step points.
example : 2 ^ 8 = 256 ∧ 2 ^ 11 = 2048 ∧ 3 ^ 8 = 6561 := by norm_num

-- The matching rule posts N, S, A, B, D, E: 6 posts, and they check every route.
example : matchingRule cityEnds = {0, 1, 2, 3, 5, 6} := by decide +kernel
example : (matchingRule cityEnds).card = 6 := by decide +kernel
example : IsCover cityEnds (matchingRule cityEnds) := by decide +kernel

-- The fewest at termini is 4: N, S, A, B check every route, and no 3 termini do.
example : IsCover cityEnds {0, 1, 2, 3} := by decide +kernel
example : ∀ C : Finset (Fin 8), IsCover cityEnds C → 4 ≤ C.card := by decide +kernel

-- Ratio 6/4 is within 2: 6 ≤ 2 × 4.
example : 6 ≤ 2 * 4 := by norm_num

-- The cheapest fractional plan, in half-units: N 1, S 1, A, B, C 0.5, D, E, F 0, total 3.5;
-- every route's two ends hold at least 1 between them.
example : ∀ e ∈ cityEnds, 2 ≤ (![2, 2, 1, 1, 1, 0, 0, 0] : Fin 8 → ℕ) e.1 + ![2, 2, 1, 1, 1, 0, 0, 0] e.2 := by
  decide
example : ∑ v, (![2, 2, 1, 1, 1, 0, 0, 0] : Fin 8 → ℕ) v = 7 := by decide

-- The packing, in half-units: weight 1 on routes 1 and 14, 0.5 on 27, 28, 29; every station's
-- load is at most 1 and the total is 3.5.
example : ∀ v : Fin 8, ((List.range 30).filter fun i =>
    (cityEnds.getD i (0, 0)).1 = v ∨ (cityEnds.getD i (0, 0)).2 = v).foldl
      (fun s i => s + if i = 0 ∨ i = 13 then 2 else if 26 ≤ i ∧ i < 29 then 1 else 0) 0 ≤ 2 := by
  decide
example : 2 + 2 + 1 + 1 + 1 = 7 := by norm_num

-- Rounding at 0.5 posts N, S, A, B, C: 5 posts, they check every route, and 5 ≤ 2 × 3.5 = 7.
example : IsCover cityEnds {0, 1, 2, 3, 4} := by decide
example : ((univ : Finset (Fin 8)).filter fun v => 1 ≤ (![2, 2, 1, 1, 1, 0, 0, 0] : Fin 8 → ℕ) v)
    = {0, 1, 2, 3, 4} := by decide
example : 5 ≤ 7 := by norm_num

-- Rounding the fractions down instead posts N and S only, and leaves routes 27, 28, 29 unchecked.
example : ¬ IsCover cityEnds {0, 1} := by decide

-- Routes seen per station: N 14, S 14, A 6, B 6, C 6, D 5, E 5, F 4, X 16, Y 8, Z 3.
example : (List.ofFn fun k => (citySees k).card) = [14, 14, 6, 6, 6, 5, 5, 4, 16, 8, 3] := by decide

-- Greedy takes X, Y, Z, N, S: a run of greedy, 5 posts.
example : IsGreedy citySees [8, 9, 10, 0, 1] univ := by decide

-- The fewest at any station is 3: N, S, Z check every route, and no 2 stations do.
example : (({0, 1, 10} : Finset (Fin 11)).biUnion citySees) = univ := by decide
example : ∀ j k : Fin 11, citySees j ∪ citySees k ≠ univ := by decide

-- Each greedy price is within its allowance, OPT/k with OPT = 3: 3 × 16 ≥ 30, 3 × 8 ≥ 14,
-- 3 × 3 ≥ 6, 3 × 2 ≥ 3, 3 × 1 ≥ 1.
example : 30 ≤ 3 * 16 ∧ 14 ≤ 3 * 8 ∧ 6 ≤ 3 * 3 ∧ 3 ≤ 3 * 2 ∧ 1 ≤ 3 * 1 := by norm_num

-- Greedy's 5 posts sit within H(30) × 3, which is under 12.
example : (5 : ℚ) ≤ harmonic 30 * 3 ∧ harmonic 30 * 3 < 12 := by
  norm_num [harmonic, Finset.sum_range_succ]

#print axioms matching_rule_le_two_mul_opt
#print axioms lp_rounding_le_f_mul_opt
#print axioms greedy_le_harmonic_mul_opt
