-- Suffix arrays: once every suffix of a text is sorted, the neighbours' overlaps count the different substrings, the occurrences of any pattern form one block of ranks, and Kasai's overlap step holds.
import Mathlib.Data.List.Lex
import Mathlib.Data.Set.Card
import Mathlib.Data.Nat.Log
import Mathlib.Data.Char
import Mathlib.Tactic.NormNum
import Mathlib.Data.List.GetD
import Mathlib.Algebra.BigOperators.Group.Finset.Sigma
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.Ring

namespace SuffixArray

variable {α : Type*} [LinearOrder α]

/-- `lcp s t` is the number of first letters the lists `s` and `t` share. -/
def lcp : List α → List α → ℕ
  | a :: s, b :: t => if a = b then lcp s t + 1 else 0
  | _, _ => 0

/-- The LCP array of a text `T` with suffix array `sa`: entry `r` is the number of first letters
the suffix of rank `r` shares with the suffix of rank `r - 1`, and entry 0 is 0. -/
def lcpArray (T : List α) (sa : List ℕ) : List ℕ :=
  0 :: List.zipWith lcp (sa.map T.drop) (sa.map T.drop).tail

theorem lcp_le_length_right : ∀ (a b : List α), lcp a b ≤ b.length
  | [], _ => by simp [lcp]
  | _ :: _, [] => by simp [lcp]
  | x :: a, y :: b => by
    simp only [lcp, List.length_cons]
    split_ifs
    · have := lcp_le_length_right a b; omega
    · omega

theorem lcp_le_length_left : ∀ (a b : List α), lcp a b ≤ a.length
  | [], _ => by simp [lcp]
  | _ :: _, [] => by simp [lcp]
  | x :: a, y :: b => by
    simp only [lcp, List.length_cons]
    split_ifs
    · have := lcp_le_length_left a b; omega
    · omega

theorem length_le_lcp_of_prefix : ∀ (u a b : List α), u <+: a → u <+: b → u.length ≤ lcp a b
  | [], _, _, _, _ => by simp
  | x :: u, a, b, ha, hb => by
    obtain ⟨t, rfl⟩ := ha
    obtain ⟨t', rfl⟩ := hb
    have := length_le_lcp_of_prefix u (u ++ t) (u ++ t') (List.prefix_append _ _)
      (List.prefix_append _ _)
    simp [lcp]
    omega

theorem take_lcp_prefix : ∀ (a b : List α), a.take (lcp a b) <+: b
  | [], _ => by simp [lcp]
  | _ :: _, [] => by simp [lcp]
  | x :: a, y :: b => by
    simp only [lcp]
    split_ifs with h
    · subst h
      simpa using take_lcp_prefix a b
    · simp

theorem take_prefix_of_le_lcp (a b : List α) (k : ℕ) (hk : k ≤ lcp a b) : a.take k <+: b :=
  (List.take_prefix_take_left hk).trans (take_lcp_prefix a b)

theorem cons_lt_or_eq {x y : α} {a b : List α} (h : x :: a < y :: b ∨ x :: a = y :: b) :
    x < y ∨ (x = y ∧ (a < b ∨ a = b)) := by
  rcases h with h | h
  · rw [List.cons_lt_cons_iff] at h
    rcases h with h | ⟨h1, h2⟩
    · exact Or.inl h
    · exact Or.inr ⟨h1, Or.inl h2⟩
  · simp only [List.cons.injEq] at h
    exact Or.inr ⟨h.1, Or.inr h.2⟩

theorem prefix_of_between : ∀ (u a b c : List α), (a < b ∨ a = b) → (b < c ∨ b = c) →
    u <+: a → u <+: c → u <+: b
  | [], _, _, _, _, _, _, _ => List.nil_prefix
  | x :: u, a, b, c, hab, hbc, ha, hc => by
    obtain ⟨t, rfl⟩ := ha
    obtain ⟨t', rfl⟩ := hc
    match b, hab, hbc with
    | [], hab, _ =>
      rcases hab with h | h
      · exact absurd h (List.not_lt_nil _)
      · simp at h
    | y :: b, hab, hbc =>
      simp only [List.cons_append] at hab hbc
      rcases cons_lt_or_eq hab with h1 | ⟨rfl, h1⟩
      · rcases cons_lt_or_eq hbc with h2 | ⟨rfl, _⟩
        · exact absurd (h1.trans h2) (lt_irrefl _)
        · exact absurd h1 (lt_irrefl _)
      · rcases cons_lt_or_eq hbc with h2 | ⟨_, h2⟩
        · exact absurd h2 (lt_irrefl _)
        · exact (List.cons_prefix_cons).2 ⟨rfl, prefix_of_between u (u ++ t) b (u ++ t') h1 h2
            (List.prefix_append _ _) (List.prefix_append _ _)⟩

theorem lcp_comm : ∀ (a b : List α), lcp a b = lcp b a
  | [], [] => rfl
  | [], _ :: _ => rfl
  | _ :: _, [] => rfl
  | x :: a, y :: b => by
    simp only [lcp]
    by_cases h : x = y
    · subst h; simp [lcp_comm a b]
    · simp [h, Ne.symm h]

theorem sa_length {T : List α} {sa : List ℕ} (hperm : sa.Perm (List.range T.length)) :
    sa.length = T.length := by
  simpa using hperm.length_eq

theorem sa_getD_lt {T : List α} {sa : List ℕ} (hperm : sa.Perm (List.range T.length)) {r : ℕ}
    (hr : r < T.length) : sa.getD r 0 < T.length := by
  have hl := sa_length hperm
  have : sa.getD r 0 ∈ sa := by
    rw [List.getD_eq_getElem _ _ (by omega)]; exact List.getElem_mem _
  simpa using hperm.subset this

theorem sa_surj {T : List α} {sa : List ℕ} (hperm : sa.Perm (List.range T.length)) {i : ℕ}
    (hi : i < T.length) : ∃ r < T.length, sa.getD r 0 = i := by
  have hl := sa_length hperm
  have : i ∈ sa := hperm.symm.subset (by simpa using hi)
  obtain ⟨r, hr, rfl⟩ := List.getElem_of_mem this
  exact ⟨r, by omega, List.getD_eq_getElem _ _ hr⟩

theorem sorted_lt {T : List α} {sa : List ℕ} (hperm : sa.Perm (List.range T.length))
    (hsorted : (sa.map T.drop).Pairwise (· < ·)) {r r' : ℕ} (h : r < r') (h' : r' < T.length) :
    T.drop (sa.getD r 0) < T.drop (sa.getD r' 0) := by
  have hl := sa_length hperm
  have := List.pairwise_iff_getElem.mp hsorted r r' (by simp; omega) (by simp; omega) h
  rw [List.getD_eq_getElem _ _ (show r < sa.length by omega),
    List.getD_eq_getElem _ _ (show r' < sa.length by omega)]
  simpa using this

theorem sorted_le {T : List α} {sa : List ℕ} (hperm : sa.Perm (List.range T.length))
    (hsorted : (sa.map T.drop).Pairwise (· < ·)) {r r' : ℕ} (h : r ≤ r') (h' : r' < T.length) :
    T.drop (sa.getD r 0) < T.drop (sa.getD r' 0) ∨ T.drop (sa.getD r 0) = T.drop (sa.getD r' 0) := by
  rcases h.lt_or_eq with h | rfl
  · exact Or.inl (sorted_lt hperm hsorted h h')
  · exact Or.inr rfl

theorem lcpArray_getD_zero (T : List α) (sa : List ℕ) : (lcpArray T sa).getD 0 0 = 0 := by
  simp [lcpArray]

theorem lcpArray_getD_succ {T : List α} {sa : List ℕ} (hl : sa.length = T.length) {r : ℕ}
    (hr : r + 1 < T.length) :
    (lcpArray T sa).getD (r + 1) 0 = lcp (T.drop (sa.getD r 0)) (T.drop (sa.getD (r + 1) 0)) := by
  simp only [lcpArray, List.getD_cons_succ]
  rw [List.getD_eq_getElem?_getD, List.getElem?_zipWith]
  simp [List.getElem?_eq_getElem (show r < sa.length by omega),
    List.getElem?_eq_getElem (show r + 1 < sa.length by omega)]

theorem lcpArray_length {T : List α} {sa : List ℕ} (hl : sa.length = T.length)
    (hn : 0 < T.length) : (lcpArray T sa).length = T.length := by
  simp [lcpArray]; omega

theorem map_sum_eq_range (l : List ℕ) (f : ℕ → ℕ) :
    (l.map f).sum = ∑ i ∈ Finset.range l.length, f (l.getD i 0) := by
  induction l with
  | nil => simp
  | cons a l ih =>
    rw [List.map_cons, List.sum_cons, ih, List.length_cons, Finset.sum_range_succ']
    simp [add_comm]

theorem countP_eq_card (l : List ℕ) (p : ℕ → Bool) :
    l.countP p = ((Finset.range l.length).filter (fun i => p (l.getD i 0) = true)).card := by
  rw [Finset.card_filter]
  induction l with
  | nil => simp
  | cons a l ih =>
    rw [List.countP_cons, ih, List.length_cons, Finset.sum_range_succ']
    simp [add_comm]

theorem sum_range_sub (n : ℕ) : (∑ i ∈ Finset.range n, (n - i)) * 2 = n * (n + 1) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ']
    simp only [Nat.add_sub_add_right, Nat.sub_zero]
    rw [add_mul, ih]; ring

#print axioms lcp_le_length_right
#print axioms lcp_le_length_left
#print axioms length_le_lcp_of_prefix
#print axioms take_lcp_prefix
#print axioms take_prefix_of_le_lcp
#print axioms cons_lt_or_eq
#print axioms prefix_of_between
#print axioms lcp_comm
#print axioms sa_length
#print axioms sa_getD_lt
#print axioms sa_surj
#print axioms sorted_lt
#print axioms sorted_le
#print axioms lcpArray_getD_zero
#print axioms lcpArray_getD_succ
#print axioms lcpArray_length
#print axioms map_sum_eq_range
#print axioms countP_eq_card
#print axioms sum_range_sub

/-- The substring count. Let `sa` be a suffix array of the text `T`: it lists every starting
position 0, ..., n - 1 once, and the suffixes `T[sa[0]..], T[sa[1]..], ...` are in strictly
increasing dictionary order. Then the number D of different nonempty substrings of `T`, plus
the sum of the LCP array, is n(n + 1)/2; that is, D = n(n + 1)/2 - (sum of the LCP array). -/
theorem distinct_substrings_eq_triangle_sub_lcp_sum (T : List α) (sa : List ℕ)
    (hperm : sa.Perm (List.range T.length))
    (hsorted : (sa.map T.drop).Pairwise (· < ·)) :
    {u : List α | u ≠ [] ∧ u <:+: T}.ncard + (lcpArray T sa).sum
      = T.length * (T.length + 1) / 2 := by
  classical
  have hl := sa_length hperm
  set n := T.length with hn
  set s : ℕ → List α := fun r => T.drop (sa.getD r 0) with hs
  set g : ℕ → ℕ := fun r => (lcpArray T sa).getD r 0 with hgdef
  set L : ℕ → ℕ := fun r => n - sa.getD r 0 with hL
  have hsL : ∀ r, (s r).length = L r := by intro r; simp [s, L, n]
  have hg0 : g 0 = 0 := lcpArray_getD_zero T sa
  have hgs : ∀ r, r + 1 < n → g (r + 1) = lcp (s r) (s (r + 1)) :=
    fun r hr => lcpArray_getD_succ hl hr
  have hgL : ∀ r, r < n → g r ≤ L r := by
    intro r hr
    rcases r with _ | r
    · rw [hg0]; exact Nat.zero_le _
    · rw [hgs r hr, ← hsL]; exact lcp_le_length_right _ _
  let S : Finset (Σ _ : ℕ, ℕ) := (Finset.range n).sigma (fun r => Finset.Ioc (g r) (L r))
  let f : (Σ _ : ℕ, ℕ) → List α := fun p => (s p.1).take p.2
  have hmemS : ∀ p, p ∈ S ↔ p.1 < n ∧ g p.1 < p.2 ∧ p.2 ≤ L p.1 := by
    intro p; simp [S, Finset.mem_sigma, Finset.mem_Ioc]
  have key : ∀ r r' k, r < r' → r' < n → g r' < k → k ≤ L r → ¬ ((s r).take k <+: s r') := by
    intro r r' k hrr hr' hk hkL hpre
    obtain ⟨q, rfl⟩ : ∃ q, r' = q + 1 := ⟨r' - 1, by omega⟩
    rw [hgs q hr'] at hk
    have hb := prefix_of_between ((s r).take k) (s r) (s q) (s (q + 1))
      (sorted_le hperm hsorted (show r ≤ q by omega) (by omega))
      (sorted_le hperm hsorted (show q ≤ q + 1 by omega) hr') (List.take_prefix _ _) hpre
    have h1 := length_le_lcp_of_prefix _ _ _ hb hpre
    have hlen : ((s r).take k).length = k := by
      rw [List.length_take, hsL]; omega
    omega
  have hinj : Set.InjOn f S := by
    rintro ⟨r, k⟩ hp ⟨r', k'⟩ hp' heq
    rw [Finset.mem_coe, hmemS] at hp hp'
    simp only [f] at heq hp hp'
    have hkk : k = k' := by
      have := congrArg List.length heq
      rw [List.length_take, List.length_take, hsL, hsL] at this
      omega
    subst hkk
    rcases lt_trichotomy r r' with h | h | h
    · have : (s r).take k <+: s r' := heq ▸ List.take_prefix k (s r')
      exact absurd this (key r r' k h hp'.1 hp'.2.1 hp.2.2)
    · subst h; rfl
    · have : (s r').take k <+: s r := heq.symm ▸ List.take_prefix k (s r)
      exact absurd this (key r' r k h hp.1 hp.2.1 hp'.2.2)
  have himg : {u : List α | u ≠ [] ∧ u <:+: T} = f '' (S : Set _) := by
    ext u
    simp only [Set.mem_ofPred_eq, Set.mem_image, Finset.mem_coe]
    constructor
    · rintro ⟨hne, hinf⟩
      obtain ⟨t, hpt, hst⟩ := List.infix_iff_prefix_suffix.mp hinf
      rw [List.suffix_iff_eq_drop] at hst
      have hi : T.length - t.length < n := by
        by_contra hc
        have : t = [] := by rw [hst]; exact List.drop_eq_nil_of_le (by omega)
        subst this
        exact hne (List.prefix_nil.mp hpt)
      obtain ⟨r0, hr0, hr0i⟩ := sa_surj hperm hi
      have hex : ∃ r, r < n ∧ u <+: s r := ⟨r0, hr0, by simp only [s]; rw [hr0i, ← hst]; exact hpt⟩
      obtain ⟨r, ⟨hrn, hru⟩, hmin⟩ : ∃ r, (r < n ∧ u <+: s r) ∧ ∀ m < r, ¬ (m < n ∧ u <+: s m) :=
        ⟨Nat.find hex, Nat.find_spec hex, fun m hm => Nat.find_min hex hm⟩
      refine ⟨⟨r, u.length⟩, (hmemS _).2 ⟨hrn, ?_, ?_⟩, ?_⟩
      · by_contra hc
        push Not at hc
        simp only at hc
        rcases Nat.eq_zero_or_pos r with h0 | hpos
        · rw [h0, hg0] at hc
          exact hne (List.length_eq_zero_iff.mp (by omega))
        · obtain ⟨q, rfl⟩ : ∃ q, r = q + 1 := ⟨r - 1, by omega⟩
          rw [hgs q hrn] at hc
          have h1 := take_prefix_of_le_lcp (s (q + 1)) (s q) u.length (by rw [lcp_comm]; exact hc)
          rw [← List.prefix_iff_eq_take.mp hru] at h1
          exact hmin q (by omega) ⟨by omega, h1⟩
      · rw [← hsL]; exact hru.length_le
      · simp only [f]; exact (List.prefix_iff_eq_take.mp hru).symm
    · rintro ⟨⟨r, k⟩, hp, rfl⟩
      rw [hmemS] at hp
      simp only at hp
      refine ⟨?_, ?_⟩
      · simp only [f]
        intro h
        have := congrArg List.length h
        rw [List.length_take, hsL] at this
        simp at this
        omega
      · exact (List.take_prefix _ _).isInfix.trans (List.drop_suffix _ _).isInfix
  have hcard : {u : List α | u ≠ [] ∧ u <:+: T}.ncard = ∑ r ∈ Finset.range n, (L r - g r) := by
    rw [himg, hinj.ncard_image, Set.ncard_coe_finset, Finset.card_sigma]
    simp [Nat.card_Ioc]
  have hsumg : (lcpArray T sa).sum = ∑ r ∈ Finset.range n, g r := by
    rcases Nat.eq_zero_or_pos n with h0 | hpos
    · have : sa = [] := List.eq_nil_of_length_eq_zero (by omega)
      rw [h0]; simp [lcpArray, this]
    · have := map_sum_eq_range (lcpArray T sa) id
      rw [List.map_id, lcpArray_length hl hpos] at this
      exact this
  have hsumL : ∑ r ∈ Finset.range n, L r = n * (n + 1) / 2 := by
    have h1 : ∑ r ∈ Finset.range n, L r = (sa.map (fun i => n - i)).sum := by
      rw [map_sum_eq_range, hl]
    have h2 : (sa.map (fun i => n - i)).sum = ((List.range n).map (fun i => n - i)).sum :=
      (hperm.map _).sum_eq
    have h3 : ((List.range n).map (fun i => n - i)).sum = ∑ i ∈ Finset.range n, (n - i) := by
      rw [map_sum_eq_range, List.length_range]
      apply Finset.sum_congr rfl
      intro i hi
      rw [List.getD_eq_getElem _ _ (by simpa using hi), List.getElem_range]
    have h4 := sum_range_sub n
    rw [h1, h2, h3]
    omega
  rw [hcard, hsumg, ← hsumL, ← Finset.sum_add_distrib]
  apply Finset.sum_congr rfl
  intro r hr
  have := hgL r (Finset.mem_range.mp hr)
  omega

/-- The block property. In a suffix array, the ranks whose suffix starts with a pattern `P`
form one unbroken block `lo ≤ r < hi`, and the size of the block, `hi - lo`, is the number of
positions in `T` where `P` occurs. -/
theorem occurrences_form_one_block (T : List α) (sa : List ℕ)
    (hperm : sa.Perm (List.range T.length))
    (hsorted : (sa.map T.drop).Pairwise (· < ·)) (P : List α) :
    ∃ lo hi, lo ≤ hi ∧ hi ≤ T.length ∧
      (∀ r (hr : r < sa.length), P <+: T.drop sa[r] ↔ lo ≤ r ∧ r < hi) ∧
      hi - lo = (List.range T.length).countP (fun i => decide (P <+: T.drop i)) := by
  classical
  have hl := sa_length hperm
  set n := T.length with hn
  let Q : ℕ → Prop := fun r => r < n ∧ P <+: T.drop (sa.getD r 0)
  have key : ∀ r (hr : r < sa.length), (P <+: T.drop sa[r]) ↔ Q r := by
    intro r hr
    simp only [Q, List.getD_eq_getElem _ _ hr]
    exact ⟨fun h => ⟨by omega, h⟩, fun h => h.2⟩
  have hcount : (List.range n).countP (fun i => decide (P <+: T.drop i))
      = ((Finset.range n).filter Q).card := by
    rw [← hperm.countP_eq, countP_eq_card, hl]
    congr 1
    apply Finset.filter_congr
    intro r hr
    simp [Q, Finset.mem_range.mp hr]
  by_cases hex : ∃ r, Q r
  · have hlo : Q (Nat.find hex) := Nat.find_spec hex
    have hg : Q (Nat.findGreatest Q n) := Nat.findGreatest_spec (P := Q) (le_of_lt hlo.1) hlo
    have hiff : ∀ r, Q r ↔ Nat.find hex ≤ r ∧ r < Nat.findGreatest Q n + 1 := by
      intro r
      constructor
      · intro hr
        exact ⟨Nat.find_min' hex hr, Nat.lt_succ_of_le (Nat.le_findGreatest (le_of_lt hr.1) hr)⟩
      · rintro ⟨h1, h2⟩
        have hrn : r < n := by have := hg.1; omega
        exact ⟨hrn, prefix_of_between P _ _ _ (sorted_le hperm hsorted h1 hrn)
          (sorted_le hperm hsorted (show r ≤ Nat.findGreatest Q n by omega) hg.1) hlo.2 hg.2⟩
    refine ⟨Nat.find hex, Nat.findGreatest Q n + 1, ?_, ?_, ?_, ?_⟩
    · have := (hiff _).1 hlo; omega
    · have := hg.1; omega
    · intro r hr; rw [key r hr]; exact hiff r
    · rw [hcount]
      have : (Finset.range n).filter Q = Finset.Ico (Nat.find hex) (Nat.findGreatest Q n + 1) := by
        ext r
        rw [Finset.mem_filter, Finset.mem_Ico, Finset.mem_range, ← hiff]
        exact ⟨fun h => h.2, fun h => ⟨h.1, h⟩⟩
      rw [this, Nat.card_Ico]
  · refine ⟨0, 0, le_rfl, Nat.zero_le _, ?_, ?_⟩
    · intro r hr
      rw [key r hr]
      exact ⟨fun h => absurd ⟨r, h⟩ hex, fun h => absurd h.2 (Nat.not_lt_zero _)⟩
    · rw [hcount]
      symm
      rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
      exact fun r _ h => hex ⟨r, h⟩

/-- Kasai's step. If the suffix `T[i..]` shares h letters with its neighbour above in the sorted
order, then the next suffix `T[i + 1..]` shares at least h - 1 letters with its own neighbour
above. (The rank of position i is its place `sa.idxOf i` in the suffix array.) -/
theorem kasai_overlap_drops_by_at_most_one (T : List α) (sa : List ℕ)
    (hperm : sa.Perm (List.range T.length))
    (hsorted : (sa.map T.drop).Pairwise (· < ·)) (i : ℕ) (hi : i + 1 < T.length) :
    (lcpArray T sa).getD (sa.idxOf i) 0 - 1 ≤ (lcpArray T sa).getD (sa.idxOf (i + 1)) 0 := by
  have hl := sa_length hperm
  have hidx : ∀ k < T.length, sa.idxOf k < T.length ∧ sa.getD (sa.idxOf k) 0 = k := by
    intro k hk
    have hm : k ∈ sa := hperm.symm.subset (by simpa using hk)
    have h1 := List.idxOf_lt_length_iff.mpr hm
    exact ⟨by omega, by rw [List.getD_eq_getElem _ _ h1, List.getElem_idxOf]⟩
  obtain ⟨hr, hri⟩ := hidx i (by omega)
  rcases Nat.eq_zero_or_pos (sa.idxOf i) with h0 | hpos
  · rw [h0, lcpArray_getD_zero]; exact Nat.zero_le _
  obtain ⟨q, hq⟩ : ∃ q, sa.idxOf i = q + 1 := ⟨sa.idxOf i - 1, by omega⟩
  rw [hq] at hri hr
  rw [hq, lcpArray_getD_succ hl hr, hri]
  have hj : sa.getD q 0 < T.length := sa_getD_lt hperm (by omega)
  have hlt := sorted_lt hperm hsorted (show q < q + 1 by omega) hr
  rw [hri] at hlt
  generalize sa.getD q 0 = j at hj hlt
  rw [List.drop_eq_getElem_cons hj, List.drop_eq_getElem_cons (show i < T.length by omega)] at hlt ⊢
  simp only [lcp]
  split_ifs with hx
  · rw [Nat.add_sub_cancel]
    rcases Nat.eq_zero_or_pos (lcp (T.drop (j + 1)) (T.drop (i + 1))) with hz | hpos'
    · rw [hz]; exact Nat.zero_le _
    have hj1 : j + 1 < T.length := by
      by_contra hc
      have h1 : T.drop (j + 1) = [] := List.drop_eq_nil_of_le (by omega)
      have h2 := lcp_le_length_left (T.drop (j + 1)) (T.drop (i + 1))
      rw [h1] at h2 hpos'
      simp at h2
      omega
    have hlt' : T.drop (j + 1) < T.drop (i + 1) := by
      rw [List.cons_lt_cons_iff] at hlt
      rcases hlt with h' | ⟨_, h'⟩
      · rw [hx] at h'; exact absurd h' (lt_irrefl _)
      · exact h'
    obtain ⟨r1lt, hr1⟩ := hidx (i + 1) hi
    obtain ⟨r2lt, hr2⟩ := hidx (j + 1) hj1
    have h21 : sa.idxOf (j + 1) < sa.idxOf (i + 1) := by
      by_contra hc
      push Not at hc
      have := sorted_le hperm hsorted hc r2lt
      rw [hr1, hr2] at this
      rcases this with h' | h'
      · exact lt_asymm h' hlt'
      · rw [h'] at hlt'; exact lt_irrefl _ hlt'
    obtain ⟨p, hp⟩ : ∃ p, sa.idxOf (i + 1) = p + 1 := ⟨sa.idxOf (i + 1) - 1, by omega⟩
    rw [hp] at hr1 r1lt h21
    rw [hp, lcpArray_getD_succ hl r1lt, hr1]
    set h := lcp (T.drop (j + 1)) (T.drop (i + 1)) with hh
    have hu1 : (T.drop (j + 1)).take h <+: T.drop (j + 1) := List.take_prefix _ _
    have hu2 : (T.drop (j + 1)).take h <+: T.drop (i + 1) := take_prefix_of_le_lcp _ _ _ le_rfl
    have hulen : ((T.drop (j + 1)).take h).length = h := by
      rw [List.length_take]
      exact min_eq_left (lcp_le_length_left _ _)
    have hb1 := sorted_le hperm hsorted (show sa.idxOf (j + 1) ≤ p by omega) (by omega)
    rw [hr2] at hb1
    have hb2 := sorted_le hperm hsorted (show p ≤ p + 1 by omega) r1lt
    rw [hr1] at hb2
    have hb := prefix_of_between _ _ _ _ hb1 hb2 hu1 hu2
    have := length_le_lcp_of_prefix _ _ _ hb hu2
    omega
  · exact Nat.zero_le _

/-- The word banana, positions 0 to 5. -/
abbrev banana : List Char := ['b', 'a', 'n', 'a', 'n', 'a']

-- Its suffix array is 5, 3, 1, 0, 4, 2: every start once, suffixes in increasing order.
example : [5, 3, 1, 0, 4, 2].Perm (List.range banana.length) := by decide
example : ([5, 3, 1, 0, 4, 2].map banana.drop).Pairwise (· < ·) := by decide
example : [5, 3, 1, 0, 4, 2].map banana.drop =
    [['a'], ['a', 'n', 'a'], ['a', 'n', 'a', 'n', 'a'], banana, ['n', 'a'], ['n', 'a', 'n', 'a']] := by
  decide

-- Its LCP array is 0, 1, 3, 0, 0, 2, summing to 6.
example : lcpArray banana [5, 3, 1, 0, 4, 2] = [0, 1, 3, 0, 0, 2] := by decide
example : (lcpArray banana [5, 3, 1, 0, 4, 2]).sum = 6 := by decide

-- 21 - 6 = 15 different substrings, and a brute-force list of every substring agrees.
example : 6 * 7 / 2 - 6 = 15 := by norm_num
example : ((banana.tails.flatMap List.inits).filter (· ≠ [])).dedup.length = 15 := by decide

-- "ana" occurs twice, at positions 1 and 3, the starts held by ranks 1 and 2.
example : (List.range banana.length).filter (fun i => decide (['a', 'n', 'a'] <+: banana.drop i))
    = [1, 3] := by decide
example : ([5, 3, 1, 0, 4, 2].map (fun i => decide (['a', 'n', 'a'] <+: banana.drop i)))
    = [false, true, true, false, false, false] := by decide

-- The search promise 2m(⌊log2 n⌋ + 1): 18 for "ana" in banana, 120 for "love" in the
-- 21,510-character log, and 2 · 4 · 24 = 192 for 11,000,000 characters.
example : 2 * 3 * (Nat.log 2 6 + 1) = 18 := by decide
example : 2 * 4 * (Nat.log 2 21510 + 1) = 120 := by decide
example : 2 * 4 * (Nat.log 2 11000000 + 1) = 192 := by decide

-- The play log's substring count: 231,350,805 - 317,105 = 231,033,700.
example : 21510 * 21511 / 2 = 231350805 ∧ 231350805 - 317105 = 231033700 := by norm_num

-- The Burrows–Wheeler transform of banana$ is annb$aa: the letter before each sorted suffix.
example : ([6, 5, 3, 1, 0, 4, 2].map (['b', 'a', 'n', 'a', 'n', 'a', '$'].drop)).Pairwise (· < ·) := by
  decide
example : [6, 5, 3, 1, 0, 4, 2].map
    (fun i => (['b', 'a', 'n', 'a', 'n', 'a', '$'].getD ((i + 6) % 7) ' '))
    = ['a', 'n', 'n', 'b', '$', 'a', 'a'] := by decide

#print axioms distinct_substrings_eq_triangle_sub_lcp_sum
#print axioms occurrences_form_one_block
#print axioms kasai_overlap_drops_by_at_most_one

end SuffixArray
