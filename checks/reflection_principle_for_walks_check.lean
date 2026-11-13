-- Reflection principle: for a fair walk with steps of one, the chance of touching a level at or above the start within n rounds equals the chance of ending at or above it plus the chance of ending strictly above it.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Fintype.Pi
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

open Finset

/-! One session of `n` rounds is a win-loss sequence `ω : Fin n → Bool` (`true` = a win of one
chip, `false` = a loss of one chip). All `2^n` sequences are equally likely, each with chance
`1 / 2^n`: this is the fair game with steps of exactly one chip and a deadline fixed in advance. -/

/-- The pile `X_k` after the first `k` rounds, starting from `x0` chips. -/
def walk {n : ℕ} (x0 : ℤ) (ω : Fin n → Bool) (k : ℕ) : ℤ :=
  x0 + ∑ i : Fin n, if (i : ℕ) < k then (if ω i then 1 else -1) else 0

/-- The best pile so far, `M_n`: the largest of `X_0, X_1, …, X_n`. -/
def runMax {n : ℕ} (x0 : ℤ) (ω : Fin n → Bool) : ℤ :=
  (range (n + 1)).sup' nonempty_range_add_one (walk x0 ω)

/-- The chance of an event: the number of win-loss sequences in it over `2^n`. -/
def prob (n : ℕ) (E : (Fin n → Bool) → Prop) [DecidablePred E] : ℚ :=
  (#(univ.filter E) : ℚ) / 2 ^ n

theorem walk_zero {n : ℕ} (x0 : ℤ) (ω : Fin n → Bool) : walk x0 ω 0 = x0 := by
  simp [walk]

#print axioms walk_zero

theorem walk_succ {n : ℕ} (x0 : ℤ) (ω : Fin n → Bool) (k : ℕ) :
    walk x0 ω (k + 1) = walk x0 ω k +
      (if h : k < n then (if ω ⟨k, h⟩ then 1 else -1) else 0) := by
  unfold walk
  have : ∀ i : Fin n, (if (i : ℕ) < k + 1 then (if ω i then (1 : ℤ) else -1) else 0) =
      (if (i : ℕ) < k then (if ω i then 1 else -1) else 0) +
      (if (i : ℕ) = k then (if ω i then 1 else -1) else 0) := by
    intro i
    by_cases h1 : (i : ℕ) < k
    · have : (i : ℕ) ≠ k := by omega
      simp [h1, this, show (i : ℕ) < k + 1 by omega]
    · by_cases h2 : (i : ℕ) = k
      · simp [h2]
      · simp [h1, h2, show ¬ (i : ℕ) < k + 1 by omega]
  rw [Finset.sum_congr rfl (fun i _ => this i), Finset.sum_add_distrib, add_assoc]
  congr 2
  by_cases h : k < n
  · rw [dif_pos h, Finset.sum_eq_single ⟨k, h⟩]
    · simp
    · intro b _ hb
      have : (b : ℕ) ≠ k := fun e => hb (Fin.ext e)
      simp [this]
    · simp
  · simp only [h, dite_false]
    apply Finset.sum_eq_zero
    intro i _
    have : (i : ℕ) ≠ k := by omega
    simp [this]

#print axioms walk_succ

theorem walk_succ_le {n : ℕ} (x0 : ℤ) (ω : Fin n → Bool) (k : ℕ) :
    walk x0 ω (k + 1) ≤ walk x0 ω k + 1 := by
  rw [walk_succ]
  split_ifs <;> omega

#print axioms walk_succ_le

theorem walk_of_ge {n : ℕ} (x0 : ℤ) (ω : Fin n → Bool) (k : ℕ) (hk : n ≤ k) :
    walk x0 ω k = walk x0 ω n := by
  unfold walk
  congr 1
  apply Finset.sum_congr rfl
  intro i _
  have h1 : (i : ℕ) < k := by omega
  simp [h1]

#print axioms walk_of_ge

theorem walk_reflect_le {n : ℕ} (x0 : ℤ) (ω : Fin n → Bool) (t k : ℕ) (hk : k ≤ t) :
    walk x0 (fun i => if (i : ℕ) < t then ω i else !ω i) k = walk x0 ω k := by
  unfold walk
  congr 1
  apply Finset.sum_congr rfl
  intro i _
  by_cases h : (i : ℕ) < k
  · simp [h, show (i : ℕ) < t by omega]
  · simp [h]

#print axioms walk_reflect_le

theorem walk_reflect_ge {n : ℕ} (x0 : ℤ) (ω : Fin n → Bool) (t k : ℕ) (hk : t ≤ k) :
    walk x0 (fun i => if (i : ℕ) < t then ω i else !ω i) k = 2 * walk x0 ω t - walk x0 ω k := by
  unfold walk
  have : ∀ i : Fin n,
      (if (i : ℕ) < k then (if (if (i : ℕ) < t then ω i else !ω i) then (1 : ℤ) else -1) else 0) =
      2 * (if (i : ℕ) < t then (if ω i then 1 else -1) else 0) -
        (if (i : ℕ) < k then (if ω i then 1 else -1) else 0) := by
    intro i
    by_cases h1 : (i : ℕ) < t
    · simp [h1, show (i : ℕ) < k by omega]; split_ifs <;> norm_num
    · by_cases h2 : (i : ℕ) < k
      · simp [h1, h2]; cases ω i <;> simp
      · simp [h1, h2]
  rw [Finset.sum_congr rfl (fun i _ => this i), Finset.sum_sub_distrib, ← Finset.mul_sum]
  ring

#print axioms walk_reflect_ge

theorem le_runMax_iff {n : ℕ} (x0 ℓ : ℤ) (ω : Fin n → Bool) :
    ℓ ≤ runMax x0 ω ↔ ∃ k, k ≤ n ∧ ℓ ≤ walk x0 ω k := by
  unfold runMax
  rw [Finset.le_sup'_iff]
  simp

#print axioms le_runMax_iff

/-- Reflect a run after its first visit to `ℓ` (identity if it never gets there). -/
def reflectAt {n : ℕ} (x0 ℓ : ℤ) (ω : Fin n → Bool) : Fin n → Bool :=
  if h : ∃ k, k ≤ n ∧ ℓ ≤ walk x0 ω k then
    (fun i => if (i : ℕ) < Nat.find h then ω i else !ω i)
  else ω

theorem reflectAt_of {n : ℕ} (x0 ℓ : ℤ) (ω : Fin n → Bool)
    (h : ∃ k, k ≤ n ∧ ℓ ≤ walk x0 ω k) :
    reflectAt x0 ℓ ω = (fun i : Fin n => if (i : ℕ) < Nat.find h then ω i else !ω i) := by
  unfold reflectAt; simp only [h, dite_true]

#print axioms reflectAt_of

theorem walk_find_eq {n : ℕ} (x0 ℓ : ℤ) (ω : Fin n → Bool) (hℓ : x0 ≤ ℓ)
    (h : ∃ k, k ≤ n ∧ ℓ ≤ walk x0 ω k) : walk x0 ω (Nat.find h) = ℓ := by
  have h1 := (Nat.find_spec h).2
  rcases hk : Nat.find h with _ | s
  · rw [hk, walk_zero] at h1; rw [walk_zero]; omega
  · have h2 : ¬ (s ≤ n ∧ ℓ ≤ walk x0 ω s) := Nat.find_min h (by omega)
    have h3 : s ≤ n := by have := (Nat.find_spec h).1; omega
    have h4 := walk_succ_le x0 ω s
    rw [hk] at h1
    have : walk x0 ω s < ℓ := by
      by_contra hc; exact h2 ⟨h3, by omega⟩
    omega

#print axioms walk_find_eq

theorem reflectAt_spec {n : ℕ} (x0 ℓ : ℤ) (ω : Fin n → Bool) (hℓ : x0 ≤ ℓ)
    (h : ℓ ≤ runMax x0 ω) :
    ℓ ≤ runMax x0 (reflectAt x0 ℓ ω) ∧ reflectAt x0 ℓ (reflectAt x0 ℓ ω) = ω ∧
      walk x0 (reflectAt x0 ℓ ω) n = 2 * ℓ - walk x0 ω n := by
  rw [le_runMax_iff] at h
  have ht := walk_find_eq x0 ℓ ω hℓ h
  have htn : Nat.find h ≤ n := (Nat.find_spec h).1
  set t := Nat.find h with t_def
  have hR : reflectAt x0 ℓ ω = (fun i : Fin n => if (i : ℕ) < t then ω i else !ω i) := by
    rw [reflectAt_of x0 ℓ ω h]
  have h' : ∃ k, k ≤ n ∧ ℓ ≤ walk x0 (reflectAt x0 ℓ ω) k :=
    ⟨t, htn, by rw [hR, walk_reflect_le _ _ _ _ le_rfl, ht]⟩
  have ht' : Nat.find h' = t := by
    rw [Nat.find_eq_iff]
    refine ⟨⟨htn, by rw [hR, walk_reflect_le _ _ _ _ le_rfl, ht]⟩, ?_⟩
    intro j hj hc
    have := Nat.find_min h hj
    rw [hR, walk_reflect_le _ _ _ _ hj.le] at hc
    exact this hc
  have hRR : reflectAt x0 ℓ (reflectAt x0 ℓ ω) =
      (fun i : Fin n => if (i : ℕ) < t then reflectAt x0 ℓ ω i else !reflectAt x0 ℓ ω i) := by
    rw [reflectAt_of x0 ℓ _ h', ht']
  refine ⟨(le_runMax_iff _ _ _).2 h', ?_, ?_⟩
  · rw [hRR, hR]
    funext i
    by_cases hi : (i : ℕ) < t <;> simp [hi]
  · rw [hR, walk_reflect_ge _ _ _ _ htn, ht]

#print axioms reflectAt_spec

theorem card_touch_and_end {n : ℕ} (x0 ℓ b : ℤ) (hℓ : x0 ≤ ℓ) (hb : b ≤ ℓ) :
    #(univ.filter (fun ω : Fin n → Bool => ℓ ≤ runMax x0 ω ∧ walk x0 ω n = b)) =
      #(univ.filter (fun ω : Fin n → Bool => walk x0 ω n = 2 * ℓ - b)) := by
  apply Finset.card_nbij' (reflectAt x0 ℓ) (reflectAt x0 ℓ)
  · intro ω hω
    simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω ⊢
    rw [(reflectAt_spec x0 ℓ ω hℓ hω.1).2.2, hω.2]
  · intro ω hω
    simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω ⊢
    have hM : ℓ ≤ runMax x0 ω := (le_runMax_iff _ _ _).2 ⟨n, le_rfl, by omega⟩
    have := reflectAt_spec x0 ℓ ω hℓ hM
    exact ⟨this.1, by rw [this.2.2, hω]; ring⟩
  · intro ω hω
    simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω
    exact (reflectAt_spec x0 ℓ ω hℓ hω.1).2.1
  · intro ω hω
    simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω
    have hM : ℓ ≤ runMax x0 ω := (le_runMax_iff _ _ _).2 ⟨n, le_rfl, by omega⟩
    exact (reflectAt_spec x0 ℓ ω hℓ hM).2.1

#print axioms card_touch_and_end

theorem card_touch {n : ℕ} (x0 ℓ : ℤ) (hℓ : x0 ≤ ℓ) :
    #(univ.filter (fun ω : Fin n → Bool => ℓ ≤ runMax x0 ω)) =
      #(univ.filter (fun ω : Fin n → Bool => ℓ ≤ walk x0 ω n)) +
      #(univ.filter (fun ω : Fin n → Bool => ℓ < walk x0 ω n)) := by
  have e := Finset.card_filter_add_card_filter_not
    (s := univ.filter (fun ω : Fin n → Bool => ℓ ≤ runMax x0 ω)) (fun ω => ℓ ≤ walk x0 ω n)
  rw [Finset.filter_filter, Finset.filter_filter] at e
  have e1 : univ.filter (fun ω : Fin n → Bool => ℓ ≤ runMax x0 ω ∧ ℓ ≤ walk x0 ω n) =
      univ.filter (fun ω : Fin n → Bool => ℓ ≤ walk x0 ω n) := by
    apply Finset.filter_congr
    intro ω _
    exact ⟨fun h => h.2, fun h => ⟨(le_runMax_iff _ _ _).2 ⟨n, le_rfl, h⟩, h⟩⟩
  have e2 : #(univ.filter (fun ω : Fin n → Bool => ℓ ≤ runMax x0 ω ∧ ¬ ℓ ≤ walk x0 ω n)) =
      #(univ.filter (fun ω : Fin n → Bool => ℓ < walk x0 ω n)) := by
    apply Finset.card_nbij' (reflectAt x0 ℓ) (reflectAt x0 ℓ)
    · intro ω hω
      simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω ⊢
      rw [(reflectAt_spec x0 ℓ ω hℓ hω.1).2.2]; omega
    · intro ω hω
      simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω ⊢
      have hM : ℓ ≤ runMax x0 ω := (le_runMax_iff _ _ _).2 ⟨n, le_rfl, by omega⟩
      have := reflectAt_spec x0 ℓ ω hℓ hM
      exact ⟨this.1, by rw [this.2.2]; omega⟩
    · intro ω hω
      simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω
      exact (reflectAt_spec x0 ℓ ω hℓ hω.1).2.1
    · intro ω hω
      simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω
      have hM : ℓ ≤ runMax x0 ω := (le_runMax_iff _ _ _).2 ⟨n, le_rfl, by omega⟩
      exact (reflectAt_spec x0 ℓ ω hℓ hM).2.1
  rw [e1, e2] at e
  omega

#print axioms card_touch

theorem walk_castSucc {m : ℕ} (x0 : ℤ) (ω : Fin (m + 1) → Bool) (k : ℕ) :
    walk x0 ω k = walk x0 (Fin.init ω) k +
      (if m < k then (if ω (Fin.last m) then 1 else -1) else 0) := by
  unfold walk
  rw [Fin.sum_univ_castSucc]
  simp only [Fin.coe_castSucc, Fin.val_last]
  rw [add_assoc]
  rfl

#print axioms walk_castSucc

theorem walk_eq_wins {m : ℕ} (x0 : ℤ) (ω : Fin m → Bool) :
    walk x0 ω m = x0 + 2 * (#(univ.filter (fun i => ω i = true)) : ℤ) - m := by
  unfold walk
  have : ∀ i : Fin m, (if (i : ℕ) < m then (if ω i then (1 : ℤ) else -1) else 0) =
      2 * (if ω i = true then 1 else 0) - 1 := by
    intro i
    simp only [i.isLt, if_true]
    cases ω i <;> simp
  rw [Finset.sum_congr rfl (fun i _ => this i), Finset.sum_sub_distrib, ← Finset.mul_sum,
    Finset.sum_boole]
  simp
  ring

#print axioms walk_eq_wins

theorem card_wins_eq (m h : ℕ) :
    #(univ.filter (fun ω : Fin m → Bool => #(univ.filter (fun i => ω i = true)) = h)) =
      m.choose h := by
  have e := Finset.card_powersetCard h (univ : Finset (Fin m))
  rw [Finset.card_univ, Fintype.card_fin] at e
  rw [← e]
  refine Finset.card_nbij' (fun ω : Fin m → Bool => univ.filter (fun i => ω i = true))
    (fun (s : Finset (Fin m)) (i : Fin m) => decide (i ∈ s)) ?_ ?_ ?_ ?_
  · intro ω hω
    simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω
    simp [Finset.mem_powersetCard, hω]
  · intro s hs
    simp only [mem_coe, Finset.mem_powersetCard] at hs
    simp [hs.2]
  · intro ω _
    funext i
    simp
  · intro s _
    ext i
    simp

#print axioms card_wins_eq

theorem walk_init_le {m : ℕ} (x0 : ℤ) (ω : Fin (m + 1) → Bool) (k : ℕ) (hk : k ≤ m) :
    walk x0 ω k = walk x0 (Fin.init ω) k := by
  rw [walk_castSucc, if_neg (by omega), add_zero]

#print axioms walk_init_le

theorem walk_init_last {m : ℕ} (x0 : ℤ) (ω : Fin (m + 1) → Bool) :
    walk x0 ω (m + 1) = walk x0 (Fin.init ω) m + (if ω (Fin.last m) then 1 else -1) := by
  rw [walk_castSucc, if_pos (by omega), walk_of_ge x0 (Fin.init ω) (m + 1) (by omega)]

#print axioms walk_init_last

theorem card_first_arrival (m : ℕ) (x0 ℓ : ℤ) :
    #(univ.filter (fun ω : Fin (m + 1) → Bool =>
        walk x0 ω (m + 1) = ℓ ∧ ∀ k < m + 1, walk x0 ω k < ℓ)) =
      #(univ.filter (fun ω : Fin m → Bool => walk x0 ω m = ℓ - 1 ∧ ¬ ℓ ≤ runMax x0 ω)) := by
  refine Finset.card_nbij' (fun ω : Fin (m + 1) → Bool => Fin.init ω)
    (fun ω : Fin m → Bool => (Fin.snoc ω true : Fin (m + 1) → Bool)) ?_ ?_ ?_ ?_
  · intro ω hω
    simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω ⊢
    obtain ⟨h1, h2⟩ := hω
    have h3 := h2 m (by omega)
    rw [walk_init_le x0 ω m le_rfl] at h3
    rw [walk_init_last] at h1
    refine ⟨by split_ifs at h1 <;> omega, ?_⟩
    rw [le_runMax_iff]
    rintro ⟨k, hk, hk'⟩
    have := h2 k (by omega)
    rw [walk_init_le x0 ω k hk] at this
    omega
  · intro ω hω
    simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω ⊢
    obtain ⟨h1, h2⟩ := hω
    rw [le_runMax_iff] at h2
    refine ⟨?_, ?_⟩
    · rw [walk_init_last, Fin.init_snoc, Fin.snoc_last, h1]
      simp
    · intro k hk
      rw [walk_init_le x0 _ k (by omega), Fin.init_snoc]
      by_contra hc
      exact h2 ⟨k, by omega, by omega⟩
  · intro ω hω
    simp only [coe_filter, mem_univ, true_and, Set.mem_setOf_eq] at hω
    obtain ⟨h1, h2⟩ := hω
    have h3 := h2 m (by omega)
    rw [walk_init_le x0 ω m le_rfl] at h3
    rw [walk_init_last] at h1
    have hl : ω (Fin.last m) = true := by
      by_contra hc
      rw [if_neg hc] at h1
      omega
    show Fin.snoc (Fin.init ω) true = ω
    rw [← hl, Fin.snoc_init_self]
  · intro ω _
    show Fin.init (Fin.snoc ω true : Fin (m + 1) → Bool) = ω
    rw [Fin.init_snoc]

#print axioms card_first_arrival

theorem card_walk_eq (p h : ℕ) (x0 c : ℤ) (hc : ∀ w : ℕ, x0 + 2 * (w : ℤ) - p = c ↔ w = h) :
    #(univ.filter (fun ω : Fin p → Bool => walk x0 ω p = c)) = p.choose h := by
  rw [← card_wins_eq p h]
  congr 1
  apply Finset.filter_congr
  intro ω _
  rw [walk_eq_wins]
  exact hc _

#print axioms card_walk_eq

theorem card_walk_eq_zero (p : ℕ) (x0 c : ℤ) (hc : ∀ w : ℕ, x0 + 2 * (w : ℤ) - p ≠ c) :
    #(univ.filter (fun ω : Fin p → Bool => walk x0 ω p = c)) = 0 := by
  rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
  intro ω _
  rw [walk_eq_wins]
  exact hc _

#print axioms card_walk_eq_zero

/-- The reflection principle for walks. For a fair walk moving one chip at a time from `x0`,
and any target `ℓ` at or above the start, the chance that the pile has touched `ℓ` by round `n`
(its best pile `M_n` is at least `ℓ`) equals the chance it ends at or above `ℓ` plus the chance
it ends strictly above `ℓ`. -/
theorem prob_touch_level_eq_prob_end_ge_add_prob_end_gt (n : ℕ) (x0 ℓ : ℤ) (hℓ : x0 ≤ ℓ) :
    prob n (fun ω => ℓ ≤ runMax x0 ω) =
      prob n (fun ω => ℓ ≤ walk x0 ω n) + prob n (fun ω => ℓ < walk x0 ω n) := by
  unfold prob
  rw [card_touch x0 ℓ hℓ, Nat.cast_add, add_div]

/-- The reflection principle proper. For a target `ℓ` at or above the start and any ending pile
`b` at or below the target, touching `ℓ` and ending at `b` is exactly as likely as ending at the
mirror image `2ℓ - b`. -/
theorem prob_touch_and_end_eq_prob_end_mirror (n : ℕ) (x0 ℓ b : ℤ) (hℓ : x0 ≤ ℓ) (hb : b ≤ ℓ) :
    prob n (fun ω => ℓ ≤ runMax x0 ω ∧ walk x0 ω n = b) = prob n (fun ω => walk x0 ω n = 2 * ℓ - b) := by
  unfold prob
  rw [card_touch_and_end x0 ℓ b hℓ hb]

/-- The ballot form of first arrival. For a target `ℓ` a gap `a = ℓ - x0 ≥ 1` above the start
and `n ≥ 1` rounds, the chance that the pile first reaches `ℓ` at round `n` (it stands at `ℓ`
after round `n` and was below `ℓ` after every earlier round) is `a / n` times the chance of
standing at `ℓ` after round `n`. -/
theorem prob_first_arrival_eq_gap_div_mul_prob_end (n : ℕ) (x0 ℓ : ℤ) (ha : 1 ≤ ℓ - x0) (hn : 1 ≤ n) :
    prob n (fun ω => walk x0 ω n = ℓ ∧ ∀ k < n, walk x0 ω k < ℓ) =
      ((ℓ - x0 : ℤ) : ℚ) / n * prob n (fun ω => walk x0 ω n = ℓ) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  obtain ⟨j, hj⟩ : ∃ j : ℕ, ℓ - x0 = j := ⟨(ℓ - x0).toNat, by omega⟩
  unfold prob
  rw [card_first_arrival, hj]
  have e := Finset.card_filter_add_card_filter_not
    (s := univ.filter (fun ω : Fin m → Bool => walk x0 ω m = ℓ - 1)) (fun ω => ℓ ≤ runMax x0 ω)
  rw [Finset.filter_filter, Finset.filter_filter] at e
  have e2 : #(univ.filter (fun ω : Fin m → Bool => walk x0 ω m = ℓ - 1 ∧ ℓ ≤ runMax x0 ω)) =
      #(univ.filter (fun ω : Fin m → Bool => walk x0 ω m = ℓ + 1)) := by
    rw [Finset.filter_congr (fun ω _ => and_comm), card_touch_and_end x0 ℓ (ℓ - 1) (by omega) (by omega)]
    congr 1
    apply Finset.filter_congr
    intro ω _
    constructor <;> intro h <;> omega
  rw [e2] at e
  set A := #(univ.filter (fun ω : Fin m → Bool => walk x0 ω m = ℓ - 1 ∧ ¬ ℓ ≤ runMax x0 ω))
  set B := #(univ.filter (fun ω : Fin (m + 1) → Bool => walk x0 ω (m + 1) = ℓ))
  set C1 := #(univ.filter (fun ω : Fin m → Bool => walk x0 ω m = ℓ - 1))
  set C2 := #(univ.filter (fun ω : Fin m → Bool => walk x0 ω m = ℓ + 1))
  have key : (m + 1) * A = j * B := by
    rcases Nat.even_or_odd' (m + 1 + j) with ⟨k, hk | hk⟩
    · have hB : B = (m + 1).choose k := card_walk_eq _ _ _ _ (fun w => by push_cast; omega)
      have hC1 : C1 = m.choose (k - 1) := card_walk_eq _ _ _ _ (fun w => by omega)
      have hC2 : C2 = m.choose k := card_walk_eq _ _ _ _ (fun w => by omega)
      by_cases hkm : k ≤ m + 1
      · have i1 := Nat.add_one_mul_choose_eq m (k - 1)
        have i2 := Nat.choose_mul_succ_eq m k
        rw [show k - 1 + 1 = k by omega] at i1
        rw [hB]
        rw [hC1, hC2] at e
        zify [hkm] at i1 i2 e hk ⊢
        linear_combination (↑m + 1 : ℤ) * e + i1 - i2 - ((m + 1).choose k : ℤ) * hk
      · have : B = 0 := by rw [hB]; exact Nat.choose_eq_zero_of_lt (by omega)
        have h1 : C1 = 0 := by rw [hC1]; exact Nat.choose_eq_zero_of_lt (by omega)
        have hA : A = 0 := by omega
        rw [this, hA, Nat.mul_zero, Nat.mul_zero]
    · have hB : B = 0 := card_walk_eq_zero _ _ _ (fun w => by push_cast; omega)
      have hC1 : C1 = 0 := card_walk_eq_zero _ _ _ (fun w => by omega)
      have hA : A = 0 := by omega
      rw [hB, hA, Nat.mul_zero, Nat.mul_zero]
  have keyQ : ((m + 1 : ℕ) : ℚ) * A = (j : ℚ) * B := by exact_mod_cast key
  have hpos : ((m + 1 : ℕ) : ℚ) ≠ 0 := by positivity
  push_cast at keyQ hpos ⊢
  field_simp
  linear_combination keyQ

-- The gambler: 10 chips, target 15, 20 rounds. With h wins the pile ends at 10 + 2h - 20,
-- which is 15 or more exactly when h is 13 or more.
example : ∀ h ∈ range 21, (15 : ℤ) ≤ 10 + 2 * h - 20 ↔ 13 ≤ h := by decide
-- All runs: 2^20 = 1048576. Runs ending at 15 or more: C(20, 13) + ... + C(20, 20) = 137980.
example : 2 ^ 20 = 1048576 ∧ ∑ h ∈ Icc 13 20, Nat.choose 20 h = 137980 := by decide
-- The pile is even after 20 rounds, so ending above 15 also needs 13 wins: 137980 again,
-- and the runs touching 15 number 137980 + 137980 = 275960.
example : ∀ h ∈ range 21, ((15 : ℤ) < 10 + 2 * h - 20 ↔ 13 ≤ h) ∧ 137980 + 137980 = 275960 := by
  decide
-- One mirror pair: touch 15 and end at 12, against end at 2 * 15 - 12 = 18 (14 wins): C(20, 14) = 38760.
example : 2 * 15 - 12 = 18 ∧ 10 + 2 * 14 - 20 = 18 ∧ Nat.choose 20 14 = 38760 := by decide
-- Never reaching 15 has the chance of ending between 5 and 14 (8 to 12 wins):
-- C(20, 8) + ... + C(20, 12) = 772616 = 1048576 - 275960.
example : ∑ h ∈ Icc 8 12, Nat.choose 20 h = 772616 ∧ 1048576 - 275960 = 772616 := by decide
-- What breaks: target 14. Doubling the runs ending at 14 or more (12 wins) gives 2 * 263950 = 527900;
-- the formula counts 263950 + 137980 = 401930.
example : ∑ h ∈ Icc 12 20, Nat.choose 20 h = 263950 ∧ 2 * 263950 = 527900 ∧
    263950 + 137980 = 401930 := by decide
-- First arrival: (5 / 5) C(5, 5) / 2^5 = 1/32 at round 5, and (5 / 7) C(7, 6) / 2^7 = 5/128 at round 7.
example : (5 : ℚ) / 5 * (Nat.choose 5 5 : ℚ) / 2 ^ 5 = 1 / 32 ∧
    (5 : ℚ) / 7 * (Nat.choose 7 6 : ℚ) / 2 ^ 7 = 5 / 128 := by
  norm_num [Nat.choose]
-- The ballot count at 19 rounds: C(19, 12) = 50388 paths stand at 15, and 5/19 of them,
-- 13260, are there for the first time.
example : Nat.choose 19 12 = 50388 ∧ 5 * 50388 = 19 * 13260 := by decide
-- The law of the best pile: P(M_20 = 11) = P(M_20 = 12) = P(X_20 = 12) = C(20, 11) / 2^20,
-- and P(M_20 = 10) = P(X_20 = 10) = C(20, 10) / 2^20.
example : Nat.choose 20 11 = 167960 ∧ Nat.choose 20 10 = 184756 := by decide

/-- The pictured run: W W L W W W L W W L L W L L W L W L L W. -/
def pictured : Fin 20 → Bool := fun i =>
  [true, true, false, true, true, true, false, true, true, false,
   false, true, false, false, true, false, true, false, false, true].getD i false

-- It first reaches 15 at round 9 and ends at 12.
example : walk 10 pictured 9 = 15 ∧ (∀ k < 9, walk 10 pictured k < 15) ∧ walk 10 pictured 20 = 12 := by
  decide
-- Its mirror after round 9 ends at 2 * 15 - 12 = 18.
example : walk 10 (fun i => if (i : ℕ) < 9 then pictured i else !pictured i) 20 = 18 := by decide

#print axioms prob_touch_level_eq_prob_end_ge_add_prob_end_gt
#print axioms prob_touch_and_end_eq_prob_end_mirror
#print axioms prob_first_arrival_eq_gap_div_mul_prob_end
