-- Historical and Monte Carlo VaR: for any n losses and any confidence level α in (0, 1], the ⌈α n⌉-th smallest loss is exactly the α-quantile of the law that weights each loss 1/n, ties included, at most a share 1 - α of losses lie strictly above it, and the j-th smallest loss is at or below a threshold exactly when at least j losses are.
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Real.Archimedean
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.Fin

/-- The `n` scenario losses `L 0, …, L (n-1)` sorted from smallest to largest:
position `j - 1` of this list holds `L_(j)`, the `j`-th smallest loss. -/
noncomputable def sortedLosses {n : ℕ} (L : Fin n → ℝ) : List ℝ :=
  (List.ofFn L).mergeSort (fun a b => decide (a ≤ b))

/-- The replay law's chance of a loss at or below `t`: the count of the `n` losses at or below
`t`, divided by `n` (each loss carries weight `1/n`). -/
noncomputable def shareAtOrBelow {n : ℕ} (L : Fin n → ℝ) (t : ℝ) : ℝ :=
  ((Finset.univ.filter fun i => L i ≤ t).card : ℝ) / n

theorem sortedLosses_pairwise {n : ℕ} (L : Fin n → ℝ) :
    (sortedLosses L).Pairwise (fun a b => a ≤ b) := by
  have := List.pairwise_mergeSort (le := fun a b : ℝ => decide (a ≤ b))
    (fun a b c h1 h2 => by simp at *; linarith)
    (fun a b => by simpa using le_total a b) (List.ofFn L)
  simpa [sortedLosses] using this

theorem sortedLosses_length {n : ℕ} (L : Fin n → ℝ) : (sortedLosses L).length = n := by
  simp [sortedLosses]

theorem sortedLosses_countP {n : ℕ} (L : Fin n → ℝ) (v : ℝ) :
    (sortedLosses L).countP (fun x => decide (x ≤ v))
      = (Finset.univ.filter fun i => L i ≤ v).card := by
  unfold sortedLosses
  rw [(List.mergeSort_perm _ _).countP_eq]
  induction n with
  | zero => simp
  | succ n ih =>
    rw [List.ofFn_succ, List.countP_cons, Fin.card_filter_univ_succ, ih (fun i => L i.succ)]
    by_cases h : L 0 ≤ v <;> simp [h]

theorem sorted_getElem_le_iff_countP (s : List ℝ) (hs : s.Pairwise (fun a b => a ≤ b))
    (v : ℝ) (m : ℕ) (hm : m < s.length) :
    s[m] ≤ v ↔ m + 1 ≤ s.countP (fun x => decide (x ≤ v)) := by
  rw [List.pairwise_iff_getElem] at hs
  constructor
  · intro h
    have h1 : (s.take (m+1)).countP (fun x => decide (x ≤ v)) = m + 1 := by
      rw [List.countP_eq_length.mpr]
      · simp; omega
      · intro x hx
        obtain ⟨i, hi, rfl⟩ := List.getElem_of_mem hx
        simp only [List.getElem_take, decide_eq_true_eq]
        simp at hi
        rcases Nat.lt_or_ge i m with h' | h'
        · exact (hs i m (by omega) hm h').trans h
        · have : i = m := by omega
          subst this; exact h
    have h2 := List.countP_append (p := fun x => decide (x ≤ v)) (l₁ := s.take (m+1)) (l₂ := s.drop (m+1))
    rw [List.take_append_drop] at h2
    omega
  · intro h
    by_contra hc
    push Not at hc
    have h1 : (s.drop m).countP (fun x => decide (x ≤ v)) = 0 := by
      rw [List.countP_eq_zero]
      intro x hx
      obtain ⟨i, hi, rfl⟩ := List.getElem_of_mem hx
      simp only [List.getElem_drop, decide_eq_true_eq, not_le]
      simp at hi
      rcases Nat.eq_zero_or_pos i with h' | h'
      · subst h'; simpa using hc
      · exact lt_of_lt_of_le hc (hs m (m + i) hm (by omega) (by omega))
    have h2 := List.countP_append (p := fun x => decide (x ≤ v)) (l₁ := s.take m) (l₂ := s.drop m)
    rw [List.take_append_drop] at h2
    have h3 := List.countP_le_length (p := fun x => decide (x ≤ v)) (l := s.take m)
    simp at h3
    omega

theorem sorted_rank_le_iff_count_aux (n : ℕ) (L : Fin n → ℝ) (v : ℝ) (j : ℕ) (hj1 : 1 ≤ j)
    (h : j - 1 < (sortedLosses L).length) :
    (sortedLosses L)[j - 1] ≤ v ↔ j ≤ (Finset.univ.filter fun i => L i ≤ v).card := by
  rw [sorted_getElem_le_iff_countP _ (sortedLosses_pairwise L) v (j - 1) h,
    sortedLosses_countP]
  omega

/-- Sorting reads the replay law's quantile exactly. Put weight `1/n` on each of `n` losses
(`n ≥ 1`) and take a confidence level `α` with `0 < α ≤ 1`. With `k = ⌈α n⌉`, the `k`-th smallest
loss `L_(k)` is the smallest threshold `t` at which the share of losses at or below `t` reaches
`α`, even when several losses tie with it. -/
theorem sorted_rank_is_replay_quantile (n : ℕ) (hn : 0 < n) (L : Fin n → ℝ) (α : ℝ)
    (hα0 : 0 < α) (hα1 : α ≤ 1) :
    ∃ h : ⌈α * n⌉₊ - 1 < (sortedLosses L).length,
      IsLeast {t : ℝ | α ≤ shareAtOrBelow L t} ((sortedLosses L)[⌈α * n⌉₊ - 1]) := by
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  have hk1 : 1 ≤ ⌈α * n⌉₊ := Nat.one_le_iff_ne_zero.mpr (Nat.ceil_pos.mpr (by positivity)).ne'
  have hkn : ⌈α * n⌉₊ ≤ n := Nat.ceil_le.mpr (by nlinarith)
  have hle := Nat.le_ceil (α * n)
  have hlen : ⌈α * n⌉₊ - 1 < (sortedLosses L).length := by
    rw [sortedLosses_length]; omega
  refine ⟨hlen, ?_, ?_⟩
  · have hc := (sorted_rank_le_iff_count_aux n L _ _ hk1 hlen).mp le_rfl
    have hc' : (⌈α * n⌉₊ : ℝ) ≤
        ((Finset.univ.filter fun i => L i ≤ (sortedLosses L)[⌈α * n⌉₊ - 1]).card : ℝ) := by
      exact_mod_cast hc
    show α ≤ shareAtOrBelow L _
    unfold shareAtOrBelow
    rw [le_div_iff₀ hnR]
    linarith
  · intro t ht
    have ht' : α ≤ shareAtOrBelow L t := ht
    unfold shareAtOrBelow at ht'
    rw [le_div_iff₀ hnR] at ht'
    exact (sorted_rank_le_iff_count_aux n L t _ hk1 hlen).mpr (Nat.ceil_le.mpr ht')

/-- At most a share `1 - α` of the losses lie strictly above the estimate: for `n ≥ 1` losses
and `0 < α ≤ 1`, the count of losses strictly greater than `L_(k)`, `k = ⌈α n⌉`, divided by `n`,
is at most `1 - α`. -/
theorem share_above_sorted_rank_le (n : ℕ) (hn : 0 < n) (L : Fin n → ℝ) (α : ℝ)
    (hα0 : 0 < α) (hα1 : α ≤ 1) (h : ⌈α * n⌉₊ - 1 < (sortedLosses L).length) :
    ((Finset.univ.filter fun i => (sortedLosses L)[⌈α * n⌉₊ - 1] < L i).card : ℝ) / n
      ≤ 1 - α := by
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  have hk1 : 1 ≤ ⌈α * n⌉₊ := Nat.one_le_iff_ne_zero.mpr (Nat.ceil_pos.mpr (by positivity)).ne'
  have hkn : ⌈α * n⌉₊ ≤ n := Nat.ceil_le.mpr (by nlinarith)
  have hle := Nat.le_ceil (α * n)
  have hc := (sorted_rank_le_iff_count_aux n L _ _ hk1 h).mp le_rfl
  have hsum := Finset.card_filter_add_card_filter_not
    (s := (Finset.univ : Finset (Fin n))) (fun i => (sortedLosses L)[⌈α * n⌉₊ - 1] < L i)
  simp only [not_lt, Finset.card_univ, Fintype.card_fin] at hsum
  have hc' : (⌈α * n⌉₊ : ℝ) ≤ ((Finset.univ.filter fun i => L i ≤ (sortedLosses L)[⌈α * n⌉₊ - 1]).card : ℝ) := by exact_mod_cast hc
  have hsum' : ((Finset.univ.filter fun i => (sortedLosses L)[⌈α * n⌉₊ - 1] < L i).card : ℝ)
      + ((Finset.univ.filter fun i => L i ≤ (sortedLosses L)[⌈α * n⌉₊ - 1]).card : ℝ) = n := by
    exact_mod_cast hsum
  rw [div_le_iff₀ hnR]
  nlinarith

/-- The counting fact behind the replay's error band: for any threshold `v` and any rank `j`
with `1 ≤ j ≤ n`, the `j`-th smallest loss sits at or below `v` exactly when at least `j` of the
losses are at or below `v`. (So the 489th smallest is at or below the true VaR exactly when at
least 489 days are, and the 499th is above it exactly when at most 498 days are.) -/
theorem sorted_rank_le_iff_count (n : ℕ) (L : Fin n → ℝ) (v : ℝ) (j : ℕ) (hj1 : 1 ≤ j)
    (hjn : j ≤ n) (h : j - 1 < (sortedLosses L).length) :
    (sortedLosses L)[j - 1] ≤ v ↔ j ≤ (Finset.univ.filter fun i => L i ≤ v).card := by
  exact sorted_rank_le_iff_count_aux n L v j hj1 h

-- The card's ranks: ⌈0.99 × 500⌉ = 495 and ⌈0.99 × 10,000⌉ = 9,900.
example : ⌈(99 / 100 : ℝ) * 500⌉₊ = 495 := by
  rw [Nat.ceil_eq_iff (by norm_num)]; norm_num
example : ⌈(99 / 100 : ℝ) * 10000⌉₊ = 9900 := by
  rw [Nat.ceil_eq_iff (by norm_num)]; norm_num
-- The scripts' integer form of the same rank, (99 n + 99) / 100 rounded down.
example : (99 * 500 + 99) / 100 = 495 := by decide
example : (99 * 10000 + 99) / 100 = 9900 := by decide
-- With 500 days, rank 495 leaves exactly five days worse; the band runs over ranks 489 to 499.
example : 500 - 495 = 5 := by decide
-- The 5th-worst day is rank 496, not 495.
example : 500 - 5 + 1 = 496 := by decide

#print axioms sorted_rank_is_replay_quantile
#print axioms share_above_sorted_rank_le
#print axioms sorted_rank_le_iff_count
#print axioms sortedLosses_pairwise
#print axioms sortedLosses_length
#print axioms sortedLosses_countP
#print axioms sorted_getElem_le_iff_countP
#print axioms sorted_rank_le_iff_count_aux
