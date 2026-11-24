-- Beating n log n, and finding the median in linear time: the median-of-medians recurrence T(n) ≤ T(n/5) + T(7n/10) + cn forces T(n) ≤ 10cn, radix sort built from stable counting passes sorts any keys below b^d and keeps ties in arrival order, and random-pivot quickselect's expected comparisons have Knuth's closed form.
import Mathlib.NumberTheory.Harmonic.Defs
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Finset

/-- Digit number `p` (counting from 0, the last digit) of `x` written in base `b`. -/
def digit (b p x : ℕ) : ℕ := x / b ^ p % b

/-- One counting-sort pass on digit `p` of the key `f a`: bucket `v` receives, in arrival order,
the items whose digit is `v`, and the buckets 0, 1, …, b − 1 are laid end to end. -/
def countingPass {α : Type*} (b p : ℕ) (f : α → ℕ) (l : List α) : List α :=
  (List.range b).flatMap (fun v => l.filter (fun a => digit b p (f a) = v))

/-- Radix sort: `d` counting passes in base `b`, from the last digit (p = 0) to the first. -/
def radixSort {α : Type*} (b d : ℕ) (f : α → ℕ) (l : List α) : List α :=
  (List.range d).foldl (fun acc p => countingPass b p f acc) l

lemma filter_filter_of_imp {α : Type*} (P Q : α → Bool) (hPQ : ∀ x, P x = true → Q x = true)
    (L : List α) : (L.filter Q).filter P = L.filter P := by
  rw [List.filter_filter]
  apply List.filter_congr
  intro x _
  cases hp : P x
  · simp
  · simp [hPQ x hp]

lemma perm_of_filter_eq {α : Type*} (k : α → ℕ) (A B : List α)
    (h : ∀ u, A.filter (fun a => k a = u) = B.filter (fun a => k a = u)) : A.Perm B := by
  classical
  rw [List.perm_iff_count]
  intro x
  have := congrArg (List.count x) (h (k x))
  rwa [List.count_filter (by simp), List.count_filter (by simp)] at this

lemma countingPass_filter {α : Type*} (b p : ℕ) (f : α → ℕ) (P : α → Bool) (c : ℕ) (hc : c < b)
    (hP : ∀ a, P a = true → digit b p (f a) = c) (L : List α) :
    (countingPass b p f L).filter P = L.filter P := by
  unfold countingPass
  rw [List.filter_flatMap]
  have key : ∀ v, (L.filter (fun a => decide (digit b p (f a) = v))).filter P =
      if v = c then L.filter P else [] := by
    intro v
    split_ifs with hv
    · subst hv
      exact filter_filter_of_imp _ _ (fun x hx => by simp [hP x hx]) L
    · rw [List.filter_filter, List.filter_eq_nil_iff]
      intro x _ hx
      simp only [Bool.and_eq_true, decide_eq_true_eq] at hx
      exact hv (hx.2 ▸ hP x hx.1)
  simp only [key]
  have gen : ∀ n, ((List.range n).flatMap fun v => if v = c then L.filter P else []) =
      if c < n then L.filter P else [] := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [List.range_succ, List.flatMap_append, ih]
      simp only [List.flatMap_cons, List.flatMap_nil, List.append_nil]
      by_cases h1 : c < n
      · simp [h1, show n ≠ c by omega, show c < n + 1 by omega]
      · by_cases h2 : c = n
        · subst h2; simp
        · simp [h1, Ne.symm h2, show ¬ c < n + 1 by omega]
  rw [gen]; simp [hc]

lemma countingPass_pairwise {α : Type*} (b p : ℕ) (hb : 0 < b) (f : α → ℕ) (L : List α)
    (h : L.Pairwise (fun x y => f x % b ^ p ≤ f y % b ^ p)) :
    (countingPass b p f L).Pairwise (fun x y => f x % b ^ (p + 1) ≤ f y % b ^ (p + 1)) := by
  unfold countingPass
  rw [List.pairwise_flatMap]
  constructor
  · intro v _
    rw [List.pairwise_filter]
    refine h.imp ?_
    intro x y hxy hx hy
    have hx' := of_decide_eq_true hx
    have hy' := of_decide_eq_true hy
    simp only [digit] at hx' hy'
    rw [Nat.mod_pow_succ, Nat.mod_pow_succ, hx', hy']
    omega
  · refine List.pairwise_lt_range.imp ?_
    intro v w hvw x hx y hy
    have hx' := of_decide_eq_true (List.mem_filter.1 hx).2
    have hy' := of_decide_eq_true (List.mem_filter.1 hy).2
    simp only [digit] at hx' hy'
    rw [Nat.mod_pow_succ, Nat.mod_pow_succ, hx', hy']
    have hlt := Nat.mod_lt (f x) ((Nat.pow_pos (n := p) hb))
    have hm : b ^ p * (v + 1) ≤ b ^ p * w := Nat.mul_le_mul_left _ hvw
    rw [Nat.mul_add, Nat.mul_one] at hm
    linarith [Nat.zero_le (f y % b ^ p)]

lemma radixSort_invariant {α : Type*} (b : ℕ) (hb : 0 < b) (f : α → ℕ) (l : List α) (p : ℕ) :
    ((List.range p).foldl (fun acc q => countingPass b q f acc) l).Pairwise
        (fun x y => f x % b ^ p ≤ f y % b ^ p) ∧
      ∀ u, ((List.range p).foldl (fun acc q => countingPass b q f acc) l).filter
          (fun a => f a % b ^ p = u) = l.filter (fun a => f a % b ^ p = u) := by
  induction p with
  | zero =>
    simp only [List.range_zero, List.foldl_nil, pow_zero, Nat.mod_one]
    exact ⟨List.pairwise_of_forall (fun _ _ => by simp), fun _ => by simp⟩
  | succ p ih =>
    obtain ⟨ihp, ihf⟩ := ih
    rw [List.range_succ, List.foldl_append]
    simp only [List.foldl_cons, List.foldl_nil]
    refine ⟨countingPass_pairwise b p hb f _ ihp, fun u => ?_⟩
    have hbp : 0 < b ^ p := (Nat.pow_pos (n := p) hb)
    rw [countingPass_filter b p f _ (u / b ^ p % b) (Nat.mod_lt _ hb)]
    · rw [← filter_filter_of_imp (fun a => decide (f a % b ^ (p + 1) = u))
          (fun a => decide (f a % b ^ p = u % b ^ p)), ihf, filter_filter_of_imp]
      all_goals
        intro x hx
        simp only [decide_eq_true_eq] at hx ⊢
        rw [← hx, Nat.mod_mod_of_dvd _ (pow_dvd_pow b (Nat.le_succ p))]
    · intro a ha
      simp only [decide_eq_true_eq] at ha
      rw [← ha, Nat.mod_pow_succ, Nat.add_mul_div_left _ _ hbp, Nat.div_eq_of_lt (Nat.mod_lt _ hbp),
        Nat.zero_add, Nat.mod_mod]
      rfl

lemma qs_sum (a b : ℕ) :
    ∑ i ∈ range b, 2 * (((a : ℚ) + i + 2) * harmonic (a + i + 1) - ((i : ℚ) + 3) * harmonic (i + 1)
      - ((a : ℚ) + 3) * harmonic (a + 1) + a + i + 4) =
    2 * ((((a : ℚ) + b + 1) * ((a : ℚ) + b + 2) / 2 * harmonic (a + b + 1)
          - ((a : ℚ) + b + 1) * ((a : ℚ) + b + 4) / 4)
      - (((a : ℚ) + 1) * ((a : ℚ) + 2) / 2 * harmonic (a + 1) - ((a : ℚ) + 1) * ((a : ℚ) + 4) / 4)
      - (((b : ℚ) + 1) * ((b : ℚ) + 2) / 2 * harmonic (b + 1) - ((b : ℚ) + 1) * ((b : ℚ) + 4) / 4)
      - ((b : ℚ) + 1) * harmonic (b + 1) + ((b : ℚ) + 1)
      - (b : ℚ) * ((a : ℚ) + 3) * harmonic (a + 1) + (b : ℚ) * ((a : ℚ) + 3)
      + ((b : ℚ) + 1) * b / 2) := by
  induction b with
  | zero => simp [harmonic]
  | succ b ih =>
    rw [sum_range_succ, ih, show a + (b + 1) + 1 = (a + b + 1) + 1 by ring,
      harmonic_succ (a + b + 1), harmonic_succ (b + 1)]
    have h1 : ((a : ℚ) + b + 2) ≠ 0 := by positivity
    have h2 : ((b : ℚ) + 2) ≠ 0 := by positivity
    push_cast
    field_simp
    ring


lemma qs_Ioc_reindex (g : ℕ → ℚ) (a b : ℕ) :
    ∑ r ∈ Ioc (a + 1) (a + b + 1), g r = ∑ i ∈ range b, g (a + 2 + i) := by
  induction b with
  | zero => simp
  | succ b ih =>
    rw [show a + (b + 1) + 1 = (a + b + 1) + 1 by ring, sum_Ioc_succ_top (by omega), ih,
      sum_range_succ, show a + b + 1 + 1 = a + 2 + b by ring]

/-- Median of medians runs in worst-case linear time. If the most comparisons T(n) the method
can make on n tracks obeys T(n) ≤ T(n/5) + T(7n/10) + cn for every n ≥ 1 (sizes rounded down),
with no work on zero tracks, then T(n) ≤ 10cn for every n. -/
theorem median_of_medians_linear (T : ℕ → ℕ) (c : ℕ) (h0 : T 0 = 0)
    (hrec : ∀ n, 1 ≤ n → T n ≤ T (n / 5) + T (7 * n / 10) + c * n) :
    ∀ n, T n ≤ 10 * c * n := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp [h0]
  have h1 := hrec n hn
  have ha := ih (n / 5) (by omega)
  have hb := ih (7 * n / 10) (by omega)
  have e1 : c * (5 * (n / 5)) ≤ c * n := Nat.mul_le_mul_left c (Nat.mul_div_le n 5)
  have e2 : c * (10 * (7 * n / 10)) ≤ c * (7 * n) := Nat.mul_le_mul_left c (Nat.mul_div_le (7 * n) 10)
  nlinarith

/-- Radix sort is correct. If every key is a whole number below b^d (keys of known width),
then d stable counting passes, last digit first, put the items in order of key, lose and add
nothing, and keep items with equal keys in the order they arrived. -/
theorem radix_sort_sorts_stably {α : Type*} (b d : ℕ) (f : α → ℕ) (l : List α)
    (hw : ∀ a ∈ l, f a < b ^ d) :
    (radixSort b d f l).Pairwise (fun x y => f x ≤ f y) ∧
      (radixSort b d f l).Perm l ∧
      ∀ v, (radixSort b d f l).filter (fun a => f a = v) = l.filter (fun a => f a = v) := by
  rcases Nat.eq_zero_or_pos b with rfl | hb
  · cases d with
    | zero =>
      simp only [radixSort, List.range_zero, List.foldl_nil]
      refine ⟨?_, List.Perm.refl _, by simp⟩
      refine List.Pairwise.imp_of_mem ?_ (List.pairwise_of_forall (R := fun _ _ => True) (fun _ _ => trivial))
      intro x y hx hy _
      have := hw x hx
      have := hw y hy
      simp at *
      omega
    | succ d =>
      cases l with
      | nil => simp [radixSort, List.range_succ, List.foldl_append, countingPass]
      | cons a l => exact absurd (hw a List.mem_cons_self) (by simp)
  · obtain ⟨hpw, hfil⟩ := radixSort_invariant b hb f l d
    have hperm : (radixSort b d f l).Perm l := perm_of_filter_eq _ _ _ hfil
    have hmod : ∀ a ∈ radixSort b d f l, f a % b ^ d = f a :=
      fun a ha => Nat.mod_eq_of_lt (hw a (hperm.subset ha))
    refine ⟨?_, hperm, fun v => ?_⟩
    · refine List.Pairwise.imp_of_mem ?_ hpw
      intro x y hx hy hxy
      rwa [hmod x hx, hmod y hy] at hxy
    · calc (radixSort b d f l).filter (fun a => f a = v)
          = (radixSort b d f l).filter (fun a => f a % b ^ d = v) :=
            List.filter_congr (fun x hx => by rw [hmod x hx])
        _ = l.filter (fun a => f a % b ^ d = v) := hfil v
        _ = l.filter (fun a => f a = v) :=
            List.filter_congr (fun x hx => by rw [Nat.mod_eq_of_lt (hw x hx)])

/-- Quickselect's expected cost, in closed form. Let E(n, k) be the expected comparisons
quickselect makes to find the k-th smallest of n different keys when its pivot is equally likely
to be any of them: n − 1 comparisons for the split, then, if the pivot has rank r, the search
continues among the r − 1 below it when r > k, among the n − r above it (for rank k − r) when
r < k, and stops when r = k. Then for 1 ≤ k ≤ n,
E(n, k) = 2((n + 1)H_n − (n + 3 − k)H_{n+1−k} − (k + 2)H_k + n + 3). -/
theorem quickselect_expected_comparisons (E : ℕ → ℕ → ℚ)
    (hE : ∀ n k, 1 ≤ k → k ≤ n →
      E n k = ((n : ℚ) - 1) + (1 / (n : ℚ)) *
        ((∑ r ∈ Ioc k n, E (r - 1) k) + ∑ r ∈ Ico 1 k, E (n - r) (k - r)))
    (n k : ℕ) (hk : 1 ≤ k) (hkn : k ≤ n) :
    E n k = 2 * (((n : ℚ) + 1) * harmonic n - ((n : ℚ) + 3 - k) * harmonic (n + 1 - k)
      - ((k : ℚ) + 2) * harmonic k + n + 3) := by
  induction n using Nat.strong_induction_on generalizing k with
  | _ n IH =>
  obtain ⟨a, rfl⟩ : ∃ a, k = a + 1 := ⟨k - 1, by omega⟩
  obtain ⟨b, rfl⟩ : ∃ b, n = a + b + 1 := ⟨n - a - 1, by omega⟩
  rw [hE _ _ hk hkn]
  have s1 : ∑ r ∈ Ioc (a + 1) (a + b + 1), E (r - 1) (a + 1) =
      ∑ i ∈ range b, 2 * (((a : ℚ) + i + 2) * harmonic (a + i + 1) - ((i : ℚ) + 3) * harmonic (i + 1)
        - ((a : ℚ) + 3) * harmonic (a + 1) + a + i + 4) := by
    rw [qs_Ioc_reindex]
    refine sum_congr rfl (fun i hi => ?_)
    rw [mem_range] at hi
    rw [show a + 2 + i - 1 = a + i + 1 by omega, IH (a + i + 1) (by omega) (a + 1) (by omega) (by omega),
      show a + i + 1 + 1 - (a + 1) = i + 1 by omega]
    push_cast; ring
  have s2 : ∑ r ∈ Ico 1 (a + 1), E (a + b + 1 - r) (a + 1 - r) =
      ∑ i ∈ range a, 2 * (((b : ℚ) + i + 2) * harmonic (b + i + 1) - ((i : ℚ) + 3) * harmonic (i + 1)
        - ((b : ℚ) + 3) * harmonic (b + 1) + b + i + 4) := by
    rw [sum_Ico_eq_sum_range, show a + 1 - 1 = a by omega,
      ← sum_range_reflect (fun i => 2 * (((b : ℚ) + i + 2) * harmonic (b + i + 1)
        - ((i : ℚ) + 3) * harmonic (i + 1) - ((b : ℚ) + 3) * harmonic (b + 1) + b + i + 4)) a]
    refine sum_congr rfl (fun i hi => ?_)
    rw [mem_range] at hi
    obtain ⟨j, rfl⟩ : ∃ j, a = i + 1 + j := ⟨a - i - 1, by omega⟩
    rw [show i + 1 + j + b + 1 - (1 + i) = j + b + 1 by omega, show i + 1 + j + 1 - (1 + i) = j + 1 by omega,
      IH (j + b + 1) (by omega) (j + 1) (by omega) (by omega),
      show j + b + 1 + 1 - (j + 1) = b + 1 by omega, show i + 1 + j - 1 - i = j by omega,
      show b + j + 1 = j + b + 1 by ring]
    push_cast; ring
  rw [s1, s2, qs_sum, qs_sum, show b + a + 1 = a + b + 1 by ring,
    show a + b + 1 + 1 - (a + 1) = b + 1 by omega]
  have hn : ((a : ℚ) + b + 1) ≠ 0 := by positivity
  push_cast
  field_simp
  ring

-- The eight tracks by hand, radix sort in base 10: pass 1 by the ones digit, then both passes.
example : radixSort 10 1 id [47, 12, 85, 43, 19, 82, 15, 40] = [40, 12, 82, 43, 85, 15, 47, 19] := by
  decide
example : radixSort 10 2 id [47, 12, 85, 43, 19, 82, 15, 40] = [12, 15, 19, 40, 43, 47, 82, 85] := by
  decide
-- Cost d(2n + b): 52 steps for the eight; 4,002,048 for the library in base 1,024; 40,000,040 in
-- base 2 with 20 passes; 3,048,576 in one pass of base 2^20.
example : 2 * (2 * 8 + 10) = 52 := by norm_num
example : 2 * (2 * 1000000 + 1024) = 4002048 := by norm_num
example : 20 * (2 * 1000000 + 2) = 40000040 := by norm_num
example : 1 * (2 * 1000000 + 2 ^ 20) = 3048576 := by norm_num
-- Quickselect's expected cost at the median of the eight: 5861/420, about 13.9548.
example : 2 * (((8 : ℚ) + 1) * harmonic 8 - ((8 : ℚ) + 3 - 4) * harmonic (8 + 1 - 4)
    - ((4 : ℚ) + 2) * harmonic 4 + 8 + 3) = 5861 / 420 := by
  simp [harmonic, Finset.sum_range_succ]
  norm_num
-- First-track pivot on a sorted playlist: k·n − k(k+1)/2 comparisons for the median.
example : 500 * 1000 - 500 * 501 / 2 = 374750 := by norm_num
example : 500000 * 1000000 - 500000 * 500001 / 2 = 374999750000 := by norm_num
-- Median of medians at n = 1,000,000: guaranteed cut 3(⌈⌈n/5⌉/2⌉ − 2) = 299,994; ceiling 10cn with c = 3.
example : 3 * ((1000000 / 5 + 1) / 2 - 2) = 299994 := by norm_num
example : 10 * 3 * 1000000 = 30000000 := by norm_num

#print axioms filter_filter_of_imp
#print axioms perm_of_filter_eq
#print axioms countingPass_filter
#print axioms countingPass_pairwise
#print axioms radixSort_invariant
#print axioms qs_sum
#print axioms qs_Ioc_reindex
#print axioms median_of_medians_linear
#print axioms radix_sort_sorts_stably
#print axioms quickselect_expected_comparisons
