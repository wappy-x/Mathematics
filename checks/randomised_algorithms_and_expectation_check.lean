-- Randomised algorithms: quicksort with a uniformly random pivot makes exactly 2(n + 1)H_n − 4n comparisons on average on every list of n different records.
import Mathlib.NumberTheory.Harmonic.Defs
import Mathlib.Data.List.Permutation
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Data.Finset.Max
import Mathlib.Tactic

open Finset

variable {α : Type*} [LinearOrder α]

/-- Comparisons made by quicksort that always takes the first record as the pivot. The pivot is
compared once with every other record; the smaller ones go left, the rest go right, in order. -/
def firstPivotComparisons : List α → ℕ
  | [] => 0
  | x :: xs =>
      xs.length + firstPivotComparisons (xs.filter (· < x))
        + firstPivotComparisons (xs.filter (fun y => ¬ y < x))
termination_by l => l.length
decreasing_by
  all_goals
    simp only [List.length_cons, List.length_unattach]
    exact Nat.lt_succ_of_le ((List.length_filter_le _ _).trans_eq List.length_attach)

/-- Expected comparisons of randomised quicksort, averaged over its own coins: the pivot is a
uniformly random position of the current stretch (fresh coins every round). That pivot is compared
once with each of the other records, the smaller ones go left and the rest go right, and each side
is sorted the same way with new coins. -/
def expectedComparisons (l : List α) : ℚ :=
  if l = [] then 0 else
    (l.attach.map fun x =>
        (((l.length - 1 : ℕ) : ℚ) + expectedComparisons ((l.erase x.1).filter (· < x.1))
          + expectedComparisons ((l.erase x.1).filter (fun y => ¬ y < x.1)))).sum / l.length
termination_by l.length
decreasing_by
  all_goals
    have hx := x.2
    refine lt_of_le_of_lt (List.length_filter_le _ _) ?_
    rw [List.length_erase_of_mem hx]
    exact Nat.sub_lt (List.length_pos_of_mem hx) Nat.one_pos

/-- The closed form. -/
def qsF (n : ℕ) : ℚ := 2 * ((n : ℚ) + 1) * harmonic n - 4 * n

theorem qsF_rec (n : ℕ) :
    (n : ℚ) * qsF n = n * ((n : ℚ) - 1) + 2 * ∑ k ∈ range n, qsF k := by
  induction n with
  | zero => simp [qsF]
  | succ n ih =>
    rw [sum_range_succ]
    have h1 : ((n : ℚ) + 1) * qsF (n + 1) = ((n:ℚ) + 2) * qsF n + 2 * n := by
      simp only [qsF, harmonic_succ]
      push_cast
      field_simp
      ring
    push_cast
    linear_combination h1 + ih

theorem sum_shift_aux (n : ℕ) :
    ∑ i ∈ Icc 1 n, (2 : ℚ) / (((n + 1 : ℕ) : ℚ) - ((i : ℕ) : ℚ) + 1) = 2 * (harmonic (n + 1) - 1) := by
  have : ∀ n : ℕ, ∑ i ∈ range n, (2 : ℚ) / ((i : ℚ) + 2) = 2 * (harmonic (n + 1) - 1) := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [sum_range_succ, ih, harmonic_succ (n + 1)]
      push_cast
      field_simp
      ring
  rw [← this n, ← sum_range_reflect]
  rw [show Icc 1 n = (range n).map ⟨(· + 1), add_left_injective 1⟩ by
    ext i; simp only [mem_Icc, mem_map, mem_range, Function.Embedding.coeFn_mk]
    constructor
    · intro h; exact ⟨i - 1, by omega, by omega⟩
    · rintro ⟨a, ha, rfl⟩; omega, sum_map]
  refine sum_congr rfl fun i hi => ?_
  simp only [mem_range] at hi
  simp only [Function.Embedding.coeFn_mk]
  congr 1
  have h1 : 1 ≤ n := by omega
  have h2 : i ≤ n - 1 := by omega
  push_cast [h1, h2]
  ring


theorem perms_perm_flatMap (L : List α) (hL : L.Nodup) (hne : L ≠ []) :
    L.permutations.Perm (L.flatMap fun x => (L.erase x).permutations.map (x :: ·)) := by
  rw [List.perm_ext_iff_of_nodup (List.nodup_permutations _ hL)]
  · intro p
    simp only [List.mem_permutations, List.mem_flatMap, List.mem_map]
    constructor
    · intro hp
      cases p with
      | nil => exact absurd (List.Perm.eq_nil hp.symm) hne
      | cons x q =>
        have hx : x ∈ L := hp.subset (List.mem_cons_self ..)
        exact ⟨x, hx, q, ((List.cons_perm_iff_perm_erase).1 hp).2, rfl⟩
    · rintro ⟨x, hx, q, hq, rfl⟩
      exact (List.cons_perm_iff_perm_erase).2 ⟨hx, hq⟩
  · rw [List.nodup_flatMap]
    refine ⟨fun x _ => (List.nodup_permutations _ (hL.erase x)).map (List.cons_injective), ?_⟩
    refine hL.pairwise_of_forall_ne fun a _ b _ hab => ?_
    simp only [Function.onFun]
    rw [List.disjoint_left]
    intro p hpa hpb
    simp only [List.mem_map] at hpa hpb
    obtain ⟨q, _, rfl⟩ := hpa
    obtain ⟨r, _, h⟩ := hpb
    exact hab (List.cons_eq_cons.1 h).1.symm

omit [LinearOrder α] in
theorem sum_map_flatMap_q {β : Type*} (L : List β) (f : β → List (List α)) (g : List α → ℚ) :
    ((L.flatMap f).map g).sum = (L.map fun x => ((f x).map g).sum).sum := by
  induction L with
  | nil => simp
  | cons a t ih => simp [List.flatMap_cons, ih]

theorem sum_map_div_q {β : Type*} (L : List β) (f : β → ℚ) (c : ℚ) :
    (L.map fun x => f x / c).sum = (L.map f).sum / c := by
  induction L with
  | nil => simp
  | cons a t ih => simp [ih, add_div]

/-- Average of `g` over all orders of `L`. -/
noncomputable def avgP (L : List α) (g : List α → ℚ) : ℚ :=
  (L.permutations.map g).sum / (L.length.factorial : ℚ)

theorem avgP_head (L : List α) (hL : L.Nodup) (g : List α → ℚ) :
    (L.length : ℚ) * avgP L g = (L.map fun x => avgP (L.erase x) (fun q => g (x :: q))).sum := by
  rcases L with _ | ⟨a, t⟩
  · simp
  have hperm := perms_perm_flatMap (a :: t) hL (List.cons_ne_nil a t)
  unfold avgP
  rw [(hperm.map g).sum_eq, sum_map_flatMap_q]
  have hlen : ∀ x ∈ a :: t, ((a :: t).erase x).length = t.length := fun x hx => by
    rw [List.length_erase_of_mem hx]; simp
  have hR : ((a :: t).map fun x =>
      (((a :: t).erase x).permutations.map fun q => g (x :: q)).sum
        / ((((a :: t).erase x).length.factorial : ℕ) : ℚ)).sum
      = ((a :: t).map fun x =>
      (((a :: t).erase x).permutations.map fun q => g (x :: q)).sum).sum
        / ((t.length.factorial : ℕ) : ℚ) := by
    rw [← sum_map_div_q]
    congr 1
    apply List.map_congr_left
    intro x hx
    rw [hlen x hx]
  rw [hR]
  simp only [List.map_map, Function.comp_def, List.length_cons, Nat.factorial_succ]
  push_cast
  have : (t.length.factorial : ℚ) ≠ 0 := by positivity
  field_simp

omit [LinearOrder α] in
theorem sum_map_ite_q (p : α → Bool) (L : List α) (A : α → ℚ) (B : ℚ) :
    (L.map fun x => if p x then A x else B).sum
      = ((L.filter p).map A).sum + ((L.filter (!p ·)).length : ℚ) * B := by
  induction L with
  | nil => simp
  | cons a t ih =>
    by_cases ha : p a
    · simp [ha, ih]; ring
    · simp [ha, ih]; ring

theorem avgP_filter (p : α → Bool) (n : ℕ) :
    ∀ L : List α, L.length = n → L.Nodup → ∀ h : List α → ℚ,
      avgP L (fun q => h (q.filter p)) = avgP (L.filter p) h := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro L hLn hL h
  rcases L with _ | ⟨a, t⟩
  · simp [avgP]
  generalize hLdef : a :: t = L at *
  have hpos : (L.length : ℚ) ≠ 0 := by rw [← hLdef]; simp; positivity
  apply mul_left_cancel₀ hpos
  rw [avgP_head _ hL]
  have hterm : ∀ x ∈ L, avgP (L.erase x) (fun q => h ((x :: q).filter p))
      = if p x then avgP ((L.filter p).erase x) (fun q => h (x :: q))
        else avgP (L.filter p) h := by
    intro x hx
    have hlt : (L.erase x).length < n := by
      rw [List.length_erase_of_mem hx, ← hLn]; rw [← hLdef]; simp
    have hnd : (L.erase x).Nodup := hL.erase x
    by_cases hpx : p x
    · simp only [List.filter_cons_of_pos hpx, hpx, ite_true]
      rw [ih _ hlt _ rfl hnd (fun r => h (x :: r)), List.erase_filter]
    · simp only [List.filter_cons_of_neg hpx, hpx, Bool.false_eq_true, ite_false]
      rw [ih _ hlt _ rfl hnd h, ← List.erase_filter, List.erase_of_not_mem]
      simp [hpx]
  rw [List.map_congr_left hterm, sum_map_ite_q, ← avgP_head _ (hL.filter p)]
  rw [List.length_eq_length_filter_add p (l := L)]
  push_cast
  ring

theorem fpc_cons (x : α) (xs : List α) :
    firstPivotComparisons (x :: xs) = xs.length + firstPivotComparisons (xs.filter (· < x))
        + firstPivotComparisons (xs.filter (fun y => ¬ y < x)) := by
  rw [firstPivotComparisons]

omit [LinearOrder α] in
theorem avgP_add (L : List α) (f g : List α → ℚ) :
    avgP L (fun q => f q + g q) = avgP L f + avgP L g := by
  unfold avgP
  rw [List.sum_map_add, add_div]

omit [LinearOrder α] in
theorem avgP_length (L : List α) : avgP L (fun q => (q.length : ℚ)) = L.length := by
  unfold avgP
  rw [List.map_congr_left (g := fun _ => (L.length : ℚ))
    (fun q hq => by rw [(List.mem_permutations.1 hq).length_eq])]
  rw [List.map_const', List.sum_replicate, List.length_permutations, nsmul_eq_mul]
  have : (L.length.factorial : ℚ) ≠ 0 := by positivity
  field_simp

omit [LinearOrder α] in
theorem attach_sum_q (l : List α) (F : α → ℚ) :
    (l.attach.map fun x => F x.1).sum = (l.map F).sum := by
  rw [List.attach_map_val]

theorem expected_eq_avgP (n : ℕ) :
    ∀ l : List α, l.length = n → l.Nodup →
      expectedComparisons l = avgP l (fun q => (firstPivotComparisons q : ℚ)) := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro l hln hl
  by_cases hne : l = []
  · subst hne
    rw [expectedComparisons]
    simp [avgP, firstPivotComparisons]
  have hpos : (l.length : ℚ) ≠ 0 := by
    have := List.length_pos_of_ne_nil hne
    positivity
  rw [expectedComparisons]
  simp only [hne, ↓reduceIte]
  rw [attach_sum_q l (fun x => ((l.length - 1 : ℕ) : ℚ) + expectedComparisons ((l.erase x).filter (· < x))
          + expectedComparisons ((l.erase x).filter (fun y => ¬ y < x)))]
  rw [eq_comm, ← mul_div_cancel_left₀ (avgP l _) hpos, avgP_head _ hl]
  congr 2
  apply List.map_congr_left
  intro x hx
  have hlt : (l.erase x).length < n := by
    rw [List.length_erase_of_mem hx, ← hln]
    exact Nat.sub_lt (List.length_pos_of_mem hx) Nat.one_pos
  have hnd : (l.erase x).Nodup := hl.erase x
  simp only [fpc_cons, Nat.cast_add]
  rw [avgP_add, avgP_add, avgP_length, List.length_erase_of_mem hx,
    avgP_filter (fun y => decide (y < x)) _ _ rfl hnd (fun r => (firstPivotComparisons r : ℚ)),
    avgP_filter (fun y => decide ¬ (y < x)) _ _ rfl hnd (fun r => (firstPivotComparisons r : ℚ)),
    ← ih _ (lt_of_le_of_lt (List.length_filter_le _ _) hlt) _ rfl (hnd.filter _),
    ← ih _ (lt_of_le_of_lt (List.length_filter_le _ _) hlt) _ rfl (hnd.filter _)]

theorem finset_rank_sum (s : Finset α) (g : ℕ → ℚ) :
    ∑ x ∈ s, g (s.filter (· < x)).card = ∑ k ∈ range s.card, g k := by
  induction s using Finset.induction_on_max with
  | empty => simp
  | insert a s hlt ih =>
    have ha : a ∉ s := fun h => lt_irrefl a (hlt a h)
    rw [sum_insert ha, card_insert_of_notMem ha, sum_range_succ]
    have h1 : (insert a s).filter (· < a) = s := by
      ext y; simp only [mem_filter, mem_insert]
      constructor
      · rintro ⟨rfl | hy, h⟩
        · exact absurd h (lt_irrefl _)
        · exact hy
      · intro hy; exact ⟨Or.inr hy, hlt y hy⟩
    have h2 : ∀ x ∈ s, (insert a s).filter (· < x) = s.filter (· < x) := by
      intro x hx
      ext y; simp only [mem_filter, mem_insert]
      constructor
      · rintro ⟨rfl | hy, h⟩
        · exact absurd (lt_trans h (hlt x hx)) (lt_irrefl _)
        · exact ⟨hy, h⟩
      · rintro ⟨hy, h⟩; exact ⟨Or.inr hy, h⟩
    rw [h1, sum_congr rfl (fun x hx => by rw [h2 x hx]), ih]
    ring

theorem list_rank_sum (l : List α) (hl : l.Nodup) (g : ℕ → ℚ) :
    (l.map fun x => g (l.filter (· < x)).length).sum = ∑ k ∈ range l.length, g k := by
  rw [← List.sum_toFinset _ hl, ← List.toFinset_card_of_nodup hl, ← finset_rank_sum]
  refine sum_congr rfl fun x _ => ?_
  rw [← List.toFinset_card_of_nodup (hl.filter _), List.toFinset_filter]
  simp

theorem expected_eq_formula (n : ℕ) :
    ∀ l : List α, l.length = n → l.Nodup → expectedComparisons l = qsF n := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro l hln hl
  by_cases hne : l = []
  · subst hne
    subst hln
    rw [expectedComparisons]
    simp [qsF]
  have hn : 0 < n := hln ▸ List.length_pos_of_ne_nil hne
  rw [expectedComparisons]
  simp only [hne, ↓reduceIte]
  rw [attach_sum_q l (fun x => ((l.length - 1 : ℕ) : ℚ) + expectedComparisons ((l.erase x).filter (· < x))
          + expectedComparisons ((l.erase x).filter (fun y => ¬ y < x)))]
  have hterm : ∀ x ∈ l,
      ((l.length - 1 : ℕ) : ℚ) + expectedComparisons ((l.erase x).filter (· < x))
        + expectedComparisons ((l.erase x).filter (fun y => ¬ y < x))
      = ((n : ℚ) - 1) + qsF (l.filter (· < x)).length
          + qsF (n - 1 - (l.filter (· < x)).length) := by
    intro x hx
    have hnd : (l.erase x).Nodup := hl.erase x
    have hlen : (l.erase x).length = n - 1 := by rw [List.length_erase_of_mem hx, hln]
    have hL : (l.erase x).filter (· < x) = l.filter (· < x) := by
      rw [← List.erase_filter, List.erase_of_not_mem]
      simp
    have hsplit : ((l.erase x).filter (· < x)).length
        + ((l.erase x).filter (fun y => ¬ y < x)).length = n - 1 := by
      rw [← hlen, List.length_eq_length_filter_add (fun y => decide (y < x)) (l := l.erase x)]
      simp only [decide_not]
    rw [ih _ (by omega) _ rfl (hnd.filter _), ih _ (by omega) _ rfl (hnd.filter _), hL]
    rw [hL] at hsplit
    rw [show ((l.erase x).filter (fun y => ¬ y < x)).length = n - 1 - (l.filter (· < x)).length
      by omega, hln]
    push_cast [Nat.one_le_iff_ne_zero.2 hn.ne']
    ring
  rw [List.map_congr_left hterm, List.sum_map_add, List.sum_map_add, List.map_const',
    List.sum_replicate, list_rank_sum _ hl,
    list_rank_sum _ hl (fun k => qsF (n - 1 - k)), hln, sum_range_reflect (fun k => qsF k) n,
    nsmul_eq_mul]
  have hq := qsF_rec n
  have hn' : (n : ℚ) ≠ 0 := by positivity
  field_simp
  linear_combination -hq

#print axioms qsF
#print axioms qsF_rec
#print axioms sum_shift_aux
#print axioms perms_perm_flatMap
#print axioms sum_map_flatMap_q
#print axioms sum_map_div_q
#print axioms avgP
#print axioms avgP_head
#print axioms sum_map_ite_q
#print axioms avgP_filter
#print axioms fpc_cons
#print axioms avgP_add
#print axioms avgP_length
#print axioms attach_sum_q
#print axioms expected_eq_avgP
#print axioms finset_rank_sum
#print axioms list_rank_sum
#print axioms expected_eq_formula

/-- The card's main claim: for every input of n different records, in any order, randomised
quicksort makes on average exactly 2(n + 1)H_n − 4n comparisons, where H_n = 1 + 1/2 + … + 1/n. -/
theorem randomised_quicksort_expected_comparisons (l : List α) (hl : l.Nodup) :
    expectedComparisons l = 2 * ((l.length : ℚ) + 1) * harmonic l.length - 4 * l.length := by
  exact expected_eq_formula _ l rfl hl

/-- Step 4: on n different records, randomised quicksort costs on average the same as
first-record quicksort averaged over all n! orders of those records. -/
theorem expected_comparisons_eq_average_over_orders (l : List α) (hl : l.Nodup) :
    expectedComparisons l
      = ((l.permutations.map firstPivotComparisons).sum : ℚ) / l.permutations.length := by
  rw [expected_eq_avgP _ l rfl hl, avgP, List.length_permutations, Nat.cast_list_sum,
    List.map_map]
  rfl

/-- Steps 1 and 2: adding the chance 2/(j − i + 1) over every pair of ranks i < j gives
2(n + 1)H_n − 4n. -/
theorem pair_chances_sum (n : ℕ) :
    ∑ i ∈ Icc 1 n, ∑ j ∈ Ioc i n, (2 : ℚ) / (((j : ℕ) : ℚ) - ((i : ℕ) : ℚ) + 1)
      = 2 * ((n : ℚ) + 1) * harmonic n - 4 * n := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [sum_Icc_succ_top (by omega)]
    simp only [Ioc_self, sum_empty, add_zero]
    have : ∀ i ∈ Icc 1 n, ∑ j ∈ Ioc i (n + 1), (2 : ℚ) / (((j : ℕ) : ℚ) - ((i : ℕ) : ℚ) + 1)
        = ∑ j ∈ Ioc i n, (2 : ℚ) / (((j : ℕ) : ℚ) - ((i : ℕ) : ℚ) + 1)
          + (2 : ℚ) / (((n + 1 : ℕ) : ℚ) - ((i : ℕ) : ℚ) + 1) := by
      intro i hi
      rw [sum_Ioc_succ_top (by simp at hi; omega)]
    rw [sum_congr rfl this, sum_add_distrib, ih, sum_shift_aux, harmonic_succ]
    push_cast
    field_simp
    ring

-- First record as pivot on a sorted log: every pair is compared, n(n − 1)/2 comparisons.
example : firstPivotComparisons [1, 2, 3, 4, 5, 6, 7, 8] = 28 := by
  simp [firstPivotComparisons]
example : 1000 * 999 / 2 = 499500 := by norm_num
example : 10000000 * 9999999 / 2 = 49999995000000 := by norm_num

-- n = 8: 8! times the formula is 682,272 comparisons over all 40,320 orders.
example : (Nat.factorial 8 : ℚ) * (2 * (8 + 1) * harmonic 8 - 4 * 8) = 682272 := by
  norm_num [harmonic, Finset.sum_range_succ, Nat.factorial]

-- n = 8: ranks 1 and 8 meet in a quarter of the orders, ranks 3 and 5 in two thirds, ranks 4 and 5 in all.
example : (40320 : ℚ) * (2 / (8 - 1 + 1)) = 10080 := by norm_num
example : (40320 : ℚ) * (2 / (5 - 3 + 1)) = 26880 := by norm_num
example : (40320 : ℚ) * (2 / (5 - 4 + 1)) = 40320 := by norm_num

#print axioms randomised_quicksort_expected_comparisons
#print axioms expected_comparisons_eq_average_over_orders
#print axioms pair_chances_sum
