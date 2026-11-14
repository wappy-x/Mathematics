-- Sorting and searching: every sort that only compares pairs of n different keys needs at least log2 n! comparisons on its worst input and on average over all n! orders, and first-pivot quicksort averages exactly 2(n+1)H_n - 4n comparisons over all n! orders.
import Mathlib.GroupTheory.Perm.Fin
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.NumberTheory.Harmonic.Defs
import Mathlib.Tactic.NormNum.NatLog
import Mathlib.Tactic.NormNum.NatFactorial

open Nat

namespace SortingSearching

/-- A comparison sort on `n` items, written out as its tree of questions.
`node i j yes no` asks "is item `i` before item `j`?" and goes on with `yes` or `no`.
`leaf π` stops and rearranges the items: position `k` of the output holds input item `π k`. -/
inductive CompTree (n : ℕ)
  | leaf (π : Equiv.Perm (Fin n))
  | node (i j : Fin n) (yes no : CompTree n)

namespace CompTree

variable {n : ℕ}

/-- The rearrangement the tree outputs when the items have keys `x`. -/
def output (x : Fin n → ℕ) : CompTree n → Equiv.Perm (Fin n)
  | leaf π => π
  | node i j yes no => if x i < x j then yes.output x else no.output x

/-- How many comparisons the tree makes on keys `x`: the questions on the path it follows. -/
def comparisons (x : Fin n → ℕ) : CompTree n → ℕ
  | leaf _ => 0
  | node i j yes no => 1 + if x i < x j then yes.comparisons x else no.comparisons x

/-- The tree is a correct sort: on every list of `n` different keys, its output is in
increasing order. -/
def Sorts (t : CompTree n) : Prop :=
  ∀ x : Fin n → ℕ, Function.Injective x → StrictMono (x ∘ t.output x)

end CompTree

/-- Keys for one of the `n!` arrival orders: item `i` has rank `σ i`. -/
def keysOf {n : ℕ} (σ : Equiv.Perm (Fin n)) : Fin n → ℕ := fun i => (σ i : ℕ)

/-- Quicksort with the first item as pivot, returning its comparison count: the pivot is
compared once with every other item, then each side is sorted the same way. The first
argument is fuel; `qsCount` gives it the list's length, which is always enough. -/
def qsAux : ℕ → List ℕ → ℕ
  | 0, _ => 0
  | _ + 1, [] => 0
  | f + 1, p :: xs =>
      xs.length + qsAux f (xs.filter (fun y => y < p)) + qsAux f (xs.filter (fun y => ¬ y < p))

/-- Comparisons made by first-pivot quicksort on a list. -/
def qsCount (xs : List ℕ) : ℕ := qsAux xs.length xs

/-! ## Helper lemmas -/

/-- Splitting `x + y` items between two subtrees costs at most `x + y` extra questions. -/
theorem split_log_bound (x y : ℝ) (hx : 0 ≤ x) (hy : 0 ≤ y) :
    (x + y) * Real.logb 2 (x + y) ≤ (x + y) + x * Real.logb 2 x + y * Real.logb 2 y := by
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  simp only [Real.logb]
  rcases hx.eq_or_lt with rfl | hx'
  · simp only [zero_add, zero_mul]
    have : 0 ≤ y := hy
    nlinarith
  rcases hy.eq_or_lt with rfl | hy'
  · simp only [add_zero]
    nlinarith
  set s := x + y with hs
  have hs0 : 0 < s := by linarith
  have key : ∀ z : ℝ, 0 < z → z * (Real.log s - Real.log 2 - Real.log z) ≤ s / 2 - z := by
    intro z hz
    have h := Real.log_le_sub_one_of_pos (show 0 < s / (2 * z) by positivity)
    rw [Real.log_div hs0.ne' (by positivity), Real.log_mul (by norm_num) hz.ne'] at h
    have h2 := mul_le_mul_of_nonneg_left h hz.le
    have : z * (s / (2 * z) - 1) = s / 2 - z := by field_simp
    linarith
  have h1 := key x hx'
  have h2 := key y hy'
  have g : s * Real.log s ≤ s * Real.log 2 + x * Real.log x + y * Real.log y := by
    clear_value s
    subst hs
    nlinarith
  have e : s + x * (Real.log x / Real.log 2) + y * (Real.log y / Real.log 2) =
      (s * Real.log 2 + x * Real.log x + y * Real.log y) / Real.log 2 := by
    field_simp
  rw [e, mul_div_assoc', div_le_div_iff_of_pos_right hl2]
  exact g

#print axioms split_log_bound

/-- Average-case core: a tree whose outputs on the inputs in `S` are all different makes
at least `|S| log2 |S|` comparisons in total over `S`. -/
theorem total_comparisons_ge {n : ℕ} {ι : Type*} (f : ι → Fin n → ℕ) (t : CompTree n) :
    ∀ S : Finset ι, Set.InjOn (fun k => t.output (f k)) S →
      (S.card : ℝ) * Real.logb 2 S.card ≤ ∑ k ∈ S, (t.comparisons (f k) : ℝ) := by
  induction t with
  | leaf π =>
    intro S hS
    have hc : S.card ≤ 1 := by
      rw [Finset.card_le_one]
      intro a ha b hb
      exact hS ha hb (by simp [CompTree.output])
    have : (S.card : ℝ) * Real.logb 2 S.card = 0 := by
      rcases Nat.le_one_iff_eq_zero_or_eq_one.1 hc with h | h <;> simp [h]
    rw [this]
    exact Finset.sum_nonneg (fun _ _ => by positivity)
  | node i j yes no ihy ihn =>
    intro S hS
    set S1 := S.filter (fun k => f k i < f k j)
    set S2 := S.filter (fun k => ¬ f k i < f k j)
    have hcard : S1.card + S2.card = S.card := Finset.card_filter_add_card_filter_not _
    have h1 : Set.InjOn (fun k => yes.output (f k)) S1 := by
      intro a ha b hb hab
      have ha' := Finset.mem_filter.1 ha
      have hb' := Finset.mem_filter.1 hb
      apply hS ha'.1 hb'.1
      simp only [CompTree.output, if_pos ha'.2, if_pos hb'.2]
      exact hab
    have h2 : Set.InjOn (fun k => no.output (f k)) S2 := by
      intro a ha b hb hab
      have ha' := Finset.mem_filter.1 ha
      have hb' := Finset.mem_filter.1 hb
      apply hS ha'.1 hb'.1
      simp only [CompTree.output, if_neg ha'.2, if_neg hb'.2]
      exact hab
    have e1 := ihy S1 h1
    have e2 := ihn S2 h2
    have hsum : ∑ k ∈ S, ((CompTree.node i j yes no).comparisons (f k) : ℝ) =
        (S.card : ℝ) + ∑ k ∈ S1, (yes.comparisons (f k) : ℝ) +
          ∑ k ∈ S2, (no.comparisons (f k) : ℝ) := by
      have a1 : ∑ k ∈ S1, ((CompTree.node i j yes no).comparisons (f k) : ℝ) =
          ∑ k ∈ S1, (1 + (yes.comparisons (f k) : ℝ)) :=
        Finset.sum_congr rfl (fun k hk => by
          simp [CompTree.comparisons, (Finset.mem_filter.1 hk).2])
      have a2 : ∑ k ∈ S2, ((CompTree.node i j yes no).comparisons (f k) : ℝ) =
          ∑ k ∈ S2, (1 + (no.comparisons (f k) : ℝ)) :=
        Finset.sum_congr rfl (fun k hk => by
          simp [CompTree.comparisons, (Finset.mem_filter.1 hk).2])
      rw [← Finset.sum_filter_add_sum_filter_not S (fun k => f k i < f k j)]
      change ∑ k ∈ S1, _ + ∑ k ∈ S2, _ = _
      rw [a1, a2, Finset.sum_add_distrib, Finset.sum_add_distrib]
      simp only [Finset.sum_const, nsmul_eq_mul, mul_one]
      rw [← hcard]; push_cast; ring
    rw [hsum]
    have hb := split_log_bound (S1.card : ℝ) (S2.card : ℝ) (by positivity) (by positivity)
    have : (S.card : ℝ) = S1.card + S2.card := by rw [← hcard]; push_cast; ring
    rw [this]
    linarith

#print axioms total_comparisons_ge

/-- A correct sort gives a different output for each of the `n!` arrival orders. -/
theorem output_injective {n : ℕ} (t : CompTree n) (ht : t.Sorts) :
    Function.Injective (fun σ : Equiv.Perm (Fin n) => t.output (keysOf σ)) := by
  intro σ τ h
  simp only at h
  have hσ := ht (keysOf σ) (fun a b hab => σ.injective (Fin.ext hab))
  have hτ := ht (keysOf τ) (fun a b hab => τ.injective (Fin.ext hab))
  rw [h] at hσ
  set π := t.output (keysOf τ)
  have hr : ∀ ρ : Equiv.Perm (Fin n), Set.range (keysOf ρ ∘ π) = Set.range (Fin.val : Fin n → ℕ) := by
    intro ρ
    ext k
    simp only [Set.mem_range, Function.comp, keysOf]
    constructor
    · rintro ⟨i, rfl⟩; exact ⟨_, rfl⟩
    · rintro ⟨i, rfl⟩; exact ⟨π.symm (ρ.symm i), by simp⟩
  have heq := (StrictMono.range_inj_of_wellFoundedLT hσ hτ).1 ((hr σ).trans (hr τ).symm)
  ext i
  have := congrFun heq (π.symm i)
  simpa [keysOf] using this

#print axioms output_injective

theorem sum_ge {n : ℕ} (t : CompTree n) (ht : t.Sorts) :
    (n ! : ℝ) * Real.logb 2 (n ! : ℝ) ≤
      ∑ σ : Equiv.Perm (Fin n), (t.comparisons (keysOf σ) : ℝ) := by
  have := total_comparisons_ge keysOf t Finset.univ ((output_injective t ht).injOn)
  simpa [Finset.card_univ, Fintype.card_perm, Fintype.card_fin] using this

#print axioms sum_ge

/-- The test "is `y` between `a` and `b`?". -/
def inRange (a b : ℕ) : ℕ → Bool := fun y => decide (a ≤ y) && decide (y ≤ b)

/-- 1 when `a < b` are both in `l` and quicksort compares them: the first item of `l` with
a value between `a` and `b` is `a` or `b`. -/
def pairInd (l : List ℕ) (a b : ℕ) : ℕ :=
  if a < b ∧ a ∈ l ∧ b ∈ l ∧
      (l.find? (inRange a b) = some a ∨ l.find? (inRange a b) = some b) then 1 else 0

theorem find_filter_of_imp (q r : ℕ → Bool) (h : ∀ y, r y = true → q y = true) :
    ∀ xs : List ℕ, (xs.filter q).find? r = xs.find? r
  | [] => rfl
  | x :: xs => by
    rw [List.filter_cons]
    by_cases hq : q x = true
    · rw [if_pos hq, List.find?_cons, List.find?_cons, find_filter_of_imp q r h xs]
    · rw [if_neg hq, find_filter_of_imp q r h xs, List.find?_cons]
      have : r x = false := by
        cases hr : r x
        · rfl
        · exact absurd (h x hr) hq
      rw [this]

#print axioms find_filter_of_imp

theorem pairInd_cons (p : ℕ) (xs : List ℕ) (hp : p ∉ xs) (a b : ℕ) :
    pairInd (p :: xs) a b =
      (if a < b ∧ ((a = p ∧ b ∈ xs) ∨ (b = p ∧ a ∈ xs)) then 1 else 0) +
        pairInd (xs.filter (fun y => y < p)) a b +
          pairInd (xs.filter (fun y => ¬ y < p)) a b := by
  unfold pairInd
  by_cases hab : a < b
  swap
  · simp [hab]
  rcases lt_trichotomy a p with hap | rfl | hap
  · rcases lt_trichotomy b p with hbp | rfl | hbp
    · -- both below the pivot
      have hn : inRange a b p = false := by simp [inRange]; omega
      have hf : (xs.filter (fun y => y < p)).find? (inRange a b) = xs.find? (inRange a b) :=
        find_filter_of_imp _ _ (fun y hy => by simp [inRange] at hy ⊢; omega) xs
      rw [List.find?_cons_of_neg (by simp [hn]), hf]
      simp [List.mem_filter, hap, hbp, hap.ne, hbp.ne, not_lt.2 hap.le]
    · -- b is the pivot
      have hy : inRange a b b = true := by simp [inRange]; omega
      rw [List.find?_cons_of_pos (by simp [hy])]
      simp [List.mem_filter, hab, hp, hab.ne]
    · -- pivot strictly between
      have hy : inRange a b p = true := by simp [inRange]; omega
      rw [List.find?_cons_of_pos (by simp [hy])]
      simp [List.mem_filter, hab, hap, hap.ne, hap.ne', hbp.ne, hbp.ne', not_lt.2 hbp.le, not_le.2 hap]
  · -- a is the pivot
    have hy : inRange a b a = true := by simp [inRange]; omega
    rw [List.find?_cons_of_pos (by simp [hy])]
    simp [List.mem_filter, hab, hp, hab.ne']
  · -- both above the pivot
    have hbp : p < b := by omega
    have hn : inRange a b p = false := by simp [inRange]; omega
    have hf : (xs.filter (fun y => ¬ y < p)).find? (inRange a b) = xs.find? (inRange a b) :=
      find_filter_of_imp _ _ (fun y hy => by simp [inRange] at hy ⊢; omega) xs
    rw [List.find?_cons_of_neg (by simp [hn]), hf]
    simp [List.mem_filter, hap.le, hbp.le, hap.ne', hbp.ne', not_lt.2 hap.le, not_lt.2 hbp.le]

#print axioms pairInd_cons

theorem pivot_pairs_sum (N p : ℕ) (xs : List ℕ) (hp : p ∉ xs) (hnd : xs.Nodup) (hpN : p < N)
    (hN : ∀ x ∈ xs, x < N) :
    ∑ a ∈ Finset.range N, ∑ b ∈ Finset.range N,
      (if a < b ∧ ((a = p ∧ b ∈ xs) ∨ (b = p ∧ a ∈ xs)) then 1 else 0) = xs.length := by
  have hpt : ∀ a b, (if a < b ∧ ((a = p ∧ b ∈ xs) ∨ (b = p ∧ a ∈ xs)) then 1 else 0) =
      (if a = p then (if b ∈ xs ∧ p < b then 1 else 0) else 0) +
        (if b = p then (if a ∈ xs ∧ a < p then 1 else 0) else 0) := by
    intro a b
    by_cases ha : a = p <;> by_cases hb : b = p
    · subst ha; subst hb; simp
    · subst ha; simp [hb, and_comm]
    · subst hb; simp [ha, and_comm]
    · simp [ha, hb]
  simp only [hpt, Finset.sum_add_distrib]
  rw [Finset.sum_comm (f := fun a b => if b = p then (if a ∈ xs ∧ a < p then 1 else 0) else 0)]
  simp only [Finset.sum_ite_irrel, Finset.sum_const_zero, Finset.sum_ite_eq', Finset.mem_range, hpN, if_true]
  rw [← Finset.sum_add_distrib]
  have hpt2 : ∀ y, ((if y ∈ xs ∧ p < y then 1 else 0) + (if y ∈ xs ∧ y < p then 1 else 0)) =
      (if y ∈ xs then 1 else 0) := by
    intro y
    by_cases hy : y ∈ xs
    · have : y ≠ p := fun h => hp (h ▸ hy)
      rcases lt_or_gt_of_ne this with h | h
      · simp [hy, h, not_lt.2 h.le]
      · simp [hy, h, not_lt.2 h.le]
    · simp [hy]
  simp only [hpt2]
  rw [Finset.sum_boole, Nat.cast_id, ← List.toFinset_card_of_nodup hnd]
  congr 1
  ext y
  simp only [Finset.mem_filter, Finset.mem_range, List.mem_toFinset]
  constructor
  · exact fun h => h.2
  · exact fun h => ⟨hN y h, h⟩

#print axioms pivot_pairs_sum

/-- Quicksort's count is the number of pairs it compares. -/
theorem qsAux_eq_pairs (N : ℕ) : ∀ (f : ℕ) (l : List ℕ), l.Nodup → l.length ≤ f →
    (∀ x ∈ l, x < N) →
      qsAux f l = ∑ a ∈ Finset.range N, ∑ b ∈ Finset.range N, pairInd l a b := by
  intro f
  induction f with
  | zero =>
    intro l _ hl _
    have : l = [] := List.eq_nil_of_length_eq_zero (Nat.le_zero.1 hl)
    subst this
    simp [qsAux, pairInd]
  | succ f ih =>
    intro l hnd hl hN
    cases l with
    | nil => simp [qsAux, pairInd]
    | cons p xs =>
      rw [List.nodup_cons] at hnd
      simp only [List.length_cons] at hl
      have hxN : ∀ x ∈ xs, x < N := fun x hx => hN x (List.mem_cons_of_mem _ hx)
      simp only [qsAux]
      rw [ih _ (hnd.2.filter _) (le_trans (List.length_filter_le _ _) (by omega))
          (fun x hx => hxN x (List.mem_of_mem_filter hx)),
        ih _ (hnd.2.filter _) (le_trans (List.length_filter_le _ _) (by omega))
          (fun x hx => hxN x (List.mem_of_mem_filter hx))]
      simp only [pairInd_cons p xs hnd.1, Finset.sum_add_distrib]
      rw [pivot_pairs_sum N p xs hnd.1 hnd.2 (hN p List.mem_cons_self) hxN]

#print axioms qsAux_eq_pairs

theorem mem_ofFn_keysOf {n : ℕ} (σ : Equiv.Perm (Fin n)) (a : ℕ) :
    a ∈ List.ofFn (keysOf σ) ↔ a < n := by
  rw [List.mem_ofFn]
  constructor
  · rintro ⟨i, rfl⟩; exact (σ i).isLt
  · intro h; exact ⟨σ.symm ⟨a, h⟩, by simp [keysOf]⟩

#print axioms mem_ofFn_keysOf

theorem qsCount_keysOf {n : ℕ} (σ : Equiv.Perm (Fin n)) :
    qsCount (List.ofFn (keysOf σ)) =
      ∑ a ∈ Finset.range n, ∑ b ∈ Finset.range n, pairInd (List.ofFn (keysOf σ)) a b :=
  qsAux_eq_pairs n _ _
    (List.nodup_ofFn.2 (fun _ _ h => σ.injective (Fin.ext h))) le_rfl
    (fun x hx => (mem_ofFn_keysOf σ x).1 hx)

#print axioms qsCount_keysOf

/-- How many arrival orders put `v` first among the values from `a` to `b`. -/
def firstCount (n a b v : ℕ) : ℚ :=
  ∑ σ : Equiv.Perm (Fin n),
    if (List.ofFn (keysOf σ)).find? (inRange a b) = some v then 1 else 0

/-- Swapping the values `v` and `w` shows each value in the range is first equally often. -/
theorem firstCount_eq {n a b v w : ℕ} (hv : v < n) (hw : w < n)
    (hva : a ≤ v) (hvb : v ≤ b) (hwa : a ≤ w) (hwb : w ≤ b) :
    firstCount n a b v = firstCount n a b w := by
  unfold firstCount
  set τ : Equiv.Perm (Fin n) := Equiv.swap ⟨v, hv⟩ ⟨w, hw⟩
  rw [← Equiv.sum_comp (Equiv.mulLeft τ)]
  refine Finset.sum_congr rfl (fun σ _ => ?_)
  have hl : List.ofFn (keysOf (τ * σ)) = (List.ofFn (keysOf σ)).map (Equiv.swap v w) := by
    rw [List.map_ofFn]
    congr 1
    funext i
    simp only [keysOf, Function.comp, Equiv.Perm.mul_apply, τ]
    exact (Function.Injective.swap_apply Fin.val_injective (⟨v, hv⟩ : Fin n) ⟨w, hw⟩ (σ i)).symm
  have iv : inRange a b v = true := by simp [inRange, hva, hvb]
  have iw : inRange a b w = true := by simp [inRange, hwa, hwb]
  have hp : inRange a b ∘ Equiv.swap v w = inRange a b := by
    funext y
    simp only [Function.comp, Equiv.swap_apply_def]
    split_ifs with h1 h2
    · rw [h1, iw, iv]
    · rw [h2, iv, iw]
    · rfl
  have key : ∀ o : Option ℕ, o.map (Equiv.swap v w) = some v ↔ o = some w := by
    intro o
    rw [Option.map_eq_some_iff]
    constructor
    · rintro ⟨x, hx, hxv⟩
      rw [Equiv.swap_apply_eq_iff, Equiv.swap_apply_left] at hxv
      rw [hx, hxv]
    · intro h
      exact ⟨w, h, Equiv.swap_apply_right v w⟩
  simp only [Equiv.coe_mulLeft, hl, List.find?_map, hp, key]

#print axioms firstCount_eq

theorem firstCount_sum {n a b : ℕ} (hab : a ≤ b) (hb : b < n) :
    ∑ v ∈ Finset.Icc a b, firstCount n a b v = (n ! : ℚ) := by
  unfold firstCount
  rw [Finset.sum_comm]
  have h1 : ∀ σ : Equiv.Perm (Fin n),
      (∑ v ∈ Finset.Icc a b,
        if (List.ofFn (keysOf σ)).find? (inRange a b) = some v then (1 : ℚ) else 0) = 1 := by
    intro σ
    have hne : (List.ofFn (keysOf σ)).find? (inRange a b) ≠ none := by
      rw [Ne, List.find?_eq_none]
      intro h
      exact h a ((mem_ofFn_keysOf σ a).2 (by omega)) (by simp [inRange, hab])
    obtain ⟨u, hu⟩ := Option.ne_none_iff_exists'.1 hne
    have hin := List.find?_some hu
    simp only [inRange, Bool.and_eq_true, decide_eq_true_eq] at hin
    rw [hu]
    simp only [Option.some.injEq]
    rw [Finset.sum_ite_eq]
    simp [hin.1, hin.2]
  simp only [h1, Finset.sum_const, Finset.card_univ, Fintype.card_perm, Fintype.card_fin,
    nsmul_eq_mul, mul_one]

#print axioms firstCount_sum

theorem firstCount_val {n a b v : ℕ} (hb : b < n) (hva : a ≤ v) (hvb : v ≤ b) :
    firstCount n a b v = (n ! : ℚ) / ((b : ℚ) - a + 1) := by
  have hs := firstCount_sum (n := n) (le_trans hva hvb) hb
  rw [Finset.sum_congr rfl (fun w hw => firstCount_eq (n := n) (a := a) (b := b) (v := w) (w := v)
      (by simp at hw; omega) (by omega) (by simp at hw; omega) (by simp at hw; omega) hva hvb)] at hs
  rw [Finset.sum_const, Nat.card_Icc, nsmul_eq_mul] at hs
  have hpos : (0 : ℚ) < (b : ℚ) - a + 1 := by
    have : (a : ℚ) ≤ b := by exact_mod_cast le_trans hva hvb
    linarith
  rw [eq_div_iff hpos.ne', ← hs]
  have : ((b + 1 - a : ℕ) : ℚ) = (b : ℚ) - a + 1 := by
    rw [Nat.cast_sub (by omega)]; push_cast; ring
  rw [this]; ring

#print axioms firstCount_val

theorem pair_sum {n a b : ℕ} (ha : a < n) (hb : b < n) :
    ∑ σ : Equiv.Perm (Fin n), (pairInd (List.ofFn (keysOf σ)) a b : ℚ) =
      if a < b then 2 * (n ! : ℚ) / ((b : ℚ) - a + 1) else 0 := by
  by_cases hab : a < b
  · rw [if_pos hab]
    have hpt : ∀ σ : Equiv.Perm (Fin n), (pairInd (List.ofFn (keysOf σ)) a b : ℚ) =
        (if (List.ofFn (keysOf σ)).find? (inRange a b) = some a then 1 else 0) +
          (if (List.ofFn (keysOf σ)).find? (inRange a b) = some b then 1 else 0) := by
      intro σ
      unfold pairInd
      simp only [mem_ofFn_keysOf, ha, hb, hab, true_and]
      by_cases h1 : (List.ofFn (keysOf σ)).find? (inRange a b) = some a
      · have h2 : (List.ofFn (keysOf σ)).find? (inRange a b) ≠ some b := by
          rw [h1]; simp; omega
        simp [h1, h2, hab.ne]
      · simp [h1]
    simp only [hpt, Finset.sum_add_distrib]
    have e1 := firstCount_val (n := n) (a := a) (b := b) (v := a) hb le_rfl hab.le
    have e2 := firstCount_val (n := n) (a := a) (b := b) (v := b) hb hab.le le_rfl
    unfold firstCount at e1 e2
    rw [e1, e2]; ring
  · rw [if_neg hab]
    apply Finset.sum_eq_zero
    intro σ _
    simp [pairInd, hab]

#print axioms pair_sum

theorem harmonic_tail (n : ℕ) :
    ∑ a ∈ Finset.range n, (1 : ℚ) / ((n : ℚ) - a + 1) = harmonic (n + 1) - 1 := by
  induction n with
  | zero => simp [harmonic]
  | succ n ih =>
    rw [Finset.sum_range_succ', harmonic_succ]
    have : ∀ a ∈ Finset.range n, (1 : ℚ) / (((n + 1 : ℕ) : ℚ) - ((a + 1 : ℕ) : ℚ) + 1) =
        1 / ((n : ℚ) - a + 1) := by
      intro a _; push_cast; ring_nf
    rw [Finset.sum_congr rfl this, ih]
    push_cast
    ring

#print axioms harmonic_tail

theorem pair_total (n : ℕ) :
    ∑ a ∈ Finset.range n, ∑ b ∈ Finset.range n,
      (if a < b then (2 : ℚ) / ((b : ℚ) - a + 1) else 0) = 2 * (n + 1) * harmonic n - 4 * n := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ]
    have h0 : ∑ b ∈ Finset.range (n + 1),
        (if n < b then (2 : ℚ) / ((b : ℚ) - n + 1) else 0) = 0 :=
      Finset.sum_eq_zero (fun b hb => by
        simp only [Finset.mem_range] at hb; rw [if_neg (by omega)])
    rw [h0, add_zero]
    simp only [Finset.sum_range_succ (n := n)]
    rw [Finset.sum_add_distrib, ih]
    have h1 : ∑ a ∈ Finset.range n, (if a < n then (2 : ℚ) / ((n : ℚ) - a + 1) else 0) =
        2 * (harmonic (n + 1) - 1) := by
      rw [← harmonic_tail, Finset.mul_sum]
      refine Finset.sum_congr rfl (fun a ha => ?_)
      simp only [Finset.mem_range] at ha
      rw [if_pos ha]; ring
    rw [h1, harmonic_succ]
    push_cast
    field_simp
    ring

#print axioms pair_total

/-- The n log n floor, worst case: any method that sorts `n` different items only by
comparing pairs has some input on which it makes at least `log2 n!` comparisons. -/
theorem comparison_sort_worst_case_ge_log2_factorial {n : ℕ} (t : CompTree n)
    (ht : t.Sorts) :
    ∃ x : Fin n → ℕ, Function.Injective x ∧
      Real.logb 2 (n ! : ℝ) ≤ (t.comparisons x : ℝ) := by
  have h := sum_ge t ht
  obtain ⟨σ, -, hσ⟩ := Finset.exists_le_of_sum_le (s := (Finset.univ : Finset (Equiv.Perm (Fin n))))
    (f := fun _ => Real.logb 2 (n ! : ℝ)) (g := fun σ => (t.comparisons (keysOf σ) : ℝ))
    Finset.univ_nonempty (by
      simpa [Finset.card_univ, Fintype.card_perm, Fintype.card_fin] using h)
  exact ⟨keysOf σ, fun a b hab => σ.injective (Fin.ext hab), hσ⟩

/-- The n log n floor, on average: averaged over all `n!` arrival orders of `n` different
items, any comparison sort makes at least `log2 n!` comparisons. -/
theorem comparison_sort_average_ge_log2_factorial {n : ℕ} (t : CompTree n)
    (ht : t.Sorts) :
    Real.logb 2 (n ! : ℝ) ≤
      (∑ σ : Equiv.Perm (Fin n), (t.comparisons (keysOf σ) : ℝ)) / (n ! : ℝ) := by
  rw [le_div_iff₀ (by positivity)]
  linarith [sum_ge t ht]

/-- Quicksort's average: with the first item as pivot, over all `n!` arrival orders of
`n` different items, quicksort makes `2(n+1)H_n - 4n` comparisons on average. -/
theorem quicksort_average_comparisons (n : ℕ) :
    (∑ σ : Equiv.Perm (Fin n), (qsCount (List.ofFn (keysOf σ)) : ℚ)) / (n ! : ℚ) =
      2 * (n + 1) * harmonic n - 4 * n := by
  simp only [qsCount_keysOf]
  push_cast
  rw [Finset.sum_comm]
  rw [Finset.sum_congr rfl (fun a _ => Finset.sum_comm)]
  rw [Finset.sum_congr rfl (fun a ha => Finset.sum_congr rfl (fun b hb =>
    pair_sum (Finset.mem_range.1 ha) (Finset.mem_range.1 hb)))]
  rw [← pair_total, Finset.sum_div]
  refine Finset.sum_congr rfl (fun a _ => ?_)
  rw [Finset.sum_div]
  refine Finset.sum_congr rfl (fun b _ => ?_)
  have hf : (n ! : ℚ) ≠ 0 := by positivity
  split_ifs
  · field_simp
  · simp

/-! ## The card's worked numbers -/

-- Eight tracks have 8! = 40,320 orders; 15 answers tell apart only 2^15 = 32,768 of them.
example : 8 ! = 40320 := by decide
example : 2 ^ 15 < 8 ! ∧ 8 ! ≤ 2 ^ 16 := by decide
example : Nat.clog 2 (8 !) = 16 := by norm_num
-- Three tracks: 3! = 6 orders, 2^2 = 4 < 6, so some order needs 3 questions.
example : 3 ! = 6 ∧ 2 ^ 2 < 3 ! := by decide

-- Quicksort, first track as pivot, on the eight tracks: 7 + 2 + 3 + 1 = 13 comparisons.
example : qsCount [214, 187, 263, 198, 305, 241, 176, 229] = 13 := by decide
-- Quicksort on eight tracks already in order: 8 * 7 / 2 = 28.
example : qsCount [176, 187, 198, 214, 229, 241, 263, 305] = 28 := by decide
example : 1000 * 999 / 2 = 499500 := by norm_num
example : 1000000 * 999999 / 2 = 499999500000 := by norm_num
-- Over all 40,320 orders quicksort's total is 682,272 = 40,320 * (2 * 9 * H_8 - 4 * 8).
example : harmonic 8 = 761 / 280 := by
  simp [harmonic, Finset.sum_range_succ]; norm_num
example : (40320 : ℚ) * (2 * 9 * (761 / 280) - 4 * 8) = 682272 := by norm_num

-- Merge sort's worst case n * ceil(log2 n) - 2^ceil(log2 n) + 1: 17 for 8, 18,951,425 for 10^6.
example : Nat.clog 2 8 = 3 ∧ 8 * 3 - 2 ^ 3 + 1 = 17 := by norm_num
example : Nat.clog 2 1000000 = 20 ∧ 1000000 * 20 - 2 ^ 20 + 1 = 18951425 := by norm_num
-- The worked merge sort on the eight tracks: 4 + 3 + 2 + 7 = 16 comparisons.
example : 4 + 3 + 2 + 7 = 16 := by norm_num

-- Binary search, most looks floor(log2 n) + 1: 4 for 8 tracks, 20 for 1,000,000.
example : Nat.log 2 8 + 1 = 4 := by norm_num
example : Nat.log 2 1000000 + 1 = 20 := by norm_num
-- k looks name at most 2^k - 1 positions: 2^19 - 1 < 1,000,000 <= 2^20 - 1.
example : 2 ^ 19 - 1 = 524287 ∧ 2 ^ 19 - 1 < 1000000 ∧ 1000000 ≤ 2 ^ 20 - 1 := by norm_num

#print axioms comparison_sort_worst_case_ge_log2_factorial
#print axioms comparison_sort_average_ge_log2_factorial
#print axioms quicksort_average_comparisons

end SortingSearching
