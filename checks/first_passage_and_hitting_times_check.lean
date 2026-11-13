-- Hitting times: a fair walk with steps of one reaches every level, its start included, with probability 1 but after an infinite average wait; a tilted walk reaches a level a above with chance 1 or (p/q)^a and returns with chance 1 − |p − q|; and C(2n, n) of the 2^(2n) fair matches of 2n rounds are never level after the start.
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Analysis.PSeries
import Mathlib.Data.Nat.Choose.Central

open MeasureTheory ProbabilityTheory Finset
open scoped ENNReal

/-! The endless match. On a probability space, `X i` is the step of round `i + 1`: +1 when Ana
wins it, −1 when Ben does. The score after `n` rounds is the sum of the first `n` steps. -/

/-- The score `S n` after `n` rounds: the sum of the first `n` steps, so `S 0 = 0`. -/
def walkScore {Ω : Type*} (X : ℕ → Ω → ℤ) (n : ℕ) (ω : Ω) : ℤ :=
  ∑ i ∈ range n, X i ω

/-- The hitting time `τ_a`: the first round `n ≥ 1` on which the score equals `a`, counted in
`ℝ≥0∞` so that it is `∞` when the score never gets there. The return time is `T = τ_0`. -/
noncomputable def hitTime {Ω : Type*} (X : ℕ → Ω → ℤ) (a : ℤ) (ω : Ω) : ℝ≥0∞ :=
  ⨅ (n : ℕ) (_ : 1 ≤ n ∧ walkScore X n ω = a), (n : ℝ≥0∞)

/-- A copy of `fpScore` (defined further down) for the helper lemmas: the score after the
first `k` rounds of a match of `m` rounds. -/
def fpScore {m : ℕ} (ω : Fin m → Bool) (k : ℕ) : ℤ :=
  ∑ i : Fin m, if (i : ℕ) < k then (if ω i then 1 else -1) else 0

/-- A match of `n` rounds whose score is never `a` on rounds 1 to `n`. -/
def fpAvoids {n : ℕ} (a : ℤ) (x : Fin n → Bool) : Prop := ∀ k ∈ Icc 1 n, fpScore x k ≠ a

instance {n : ℕ} (a : ℤ) : DecidablePred (@fpAvoids n a) := fun x =>
  inferInstanceAs (Decidable (∀ k ∈ Icc 1 n, fpScore x k ≠ a))

def fpSg (c : Bool) : ℤ := if c then 1 else -1

lemma fp_sum_split {M : Type*} [AddCommMonoid M] {n : ℕ} (F : (Fin (n+1) → Bool) → M) :
    ∑ x, F x = ∑ y : Fin n → Bool, F (Fin.cons true y) +
      ∑ y : Fin n → Bool, F (Fin.cons false y) := by
  rw [← (Fin.consEquiv fun _ => Bool).sum_comp, Fintype.sum_prod_type, Fintype.sum_bool]
  rfl

lemma fp_ms_zero {m : ℕ} (x : Fin m → Bool) : fpScore x 0 = 0 := by
  simp [fpScore]

lemma fp_ms_cons {m : ℕ} (c : Bool) (y : Fin m → Bool) (k : ℕ) :
    fpScore (Fin.cons c y : Fin (m+1) → Bool) (k+1) = fpSg c + fpScore y k := by
  simp [fpScore, Fin.sum_univ_succ, fpSg]

lemma fp_ms_not {m : ℕ} (x : Fin m → Bool) (k : ℕ) :
    fpScore (fun i => !x i) k = - fpScore x k := by
  simp only [fpScore, ← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  by_cases h : x i = true <;> simp [h] <;> split_ifs <;> simp

lemma fp_forall_le_succ {P : ℕ → Prop} {m : ℕ} :
    (∀ k ≤ m + 1, P k) ↔ P 0 ∧ ∀ j ≤ m, P (j + 1) :=
  ⟨fun h => ⟨h 0 (by omega), fun j hj => h _ (by omega)⟩, fun ⟨h0, h⟩ k hk => by
    cases k with
    | zero => exact h0
    | succ j => exact h j (by omega)⟩

lemma fp_sum_not {M : Type*} [AddCommMonoid M] {n : ℕ} (F : (Fin n → Bool) → M) :
    ∑ x, F x = ∑ x : Fin n → Bool, F (fun i => !x i) := by
  have hinv : Function.Involutive (fun (x : Fin n → Bool) (i : Fin n) => !x i) := by
    intro x; funext i; simp
  exact Fintype.sum_bijective _ hinv.bijective F (fun x : Fin n → Bool => F (fun i => !x i))
    (fun x => by simp)

open Classical in
/-- Count of matches of `m` rounds whose score, shifted up by `h`, never goes below 0. -/
noncomputable def fpN (m : ℕ) (h : ℤ) : ℕ :=
  ∑ x : Fin m → Bool, if (∀ k ≤ m, 0 ≤ h + fpScore x k) then 1 else 0

open Classical in
/-- Count of matches of `m` rounds whose final score lies in `[lo, hi]`. -/
noncomputable def fpM (m : ℕ) (lo hi : ℤ) : ℕ :=
  ∑ x : Fin m → Bool, if lo ≤ fpScore x m ∧ fpScore x m ≤ hi then 1 else 0

lemma fp_cons_exists {m : ℕ} (x : Fin (m+1) → Bool) :
    ∃ c y, x = (Fin.cons c y : Fin (m+1) → Bool) :=
  ⟨x 0, Fin.tail x, (Fin.cons_self_tail x).symm⟩

lemma fp_ms_bounds (m : ℕ) (x : Fin m → Bool) :
    -(m : ℤ) ≤ fpScore x m ∧ fpScore x m ≤ m ∧ (fpScore x m + m) % 2 = 0 := by
  induction m with
  | zero => simp [fpScore]
  | succ m ih =>
    obtain ⟨c, y, rfl⟩ := fp_cons_exists x
    rw [fp_ms_cons]
    have := ih y
    cases c <;> simp [fpSg] <;> omega

lemma fpM_succ (m : ℕ) (lo hi : ℤ) :
    fpM (m+1) lo hi = fpM m (lo - 1) (hi - 1) + fpM m (lo + 1) (hi + 1) := by
  unfold fpM
  rw [fp_sum_split]
  simp only [fp_ms_cons, fpSg]
  congr 1 <;> refine Finset.sum_congr rfl fun y _ => ?_ <;> simp only [Bool.false_eq_true,
    ite_true, ite_false] <;> split_ifs <;> omega

lemma fpM_split (m : ℕ) (lo c hi : ℤ) (h1 : lo ≤ c + 1) (h2 : c ≤ hi) :
    fpM m lo hi = fpM m lo c + fpM m (c + 1) hi := by
  unfold fpM
  rw [← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun y _ => ?_
  split_ifs <;> omega

lemma fpM_zero_of (m : ℕ) (lo hi : ℤ) (h : ∀ x : Fin m → Bool,
    ¬ (lo ≤ fpScore x m ∧ fpScore x m ≤ hi)) : fpM m lo hi = 0 := by
  unfold fpM
  exact Finset.sum_eq_zero fun x _ => if_neg (h x)

lemma fpN_succ (m : ℕ) (h : ℤ) :
    fpN (m+1) h = if 0 ≤ h then fpN m (h + 1) + fpN m (h - 1) else 0 := by
  unfold fpN
  rw [fp_sum_split]
  simp only [fp_forall_le_succ, fp_ms_zero, fp_ms_cons, fpSg, add_zero, Bool.false_eq_true,
    ite_true, ite_false]
  by_cases h0 : 0 ≤ h
  · simp only [h0, true_and, ite_true]
    congr 1 <;> refine Finset.sum_congr rfl fun y _ => ?_ <;> congr 1 <;>
      refine propext (forall_congr' fun j => imp_congr_right fun _ => ?_) <;> constructor <;>
      intro <;> omega
  · simp [h0]

lemma fpN_eq_fpM (m : ℕ) (h : ℤ) (hh : -1 ≤ h) : fpN m h = fpM m (-h) (h + 1) := by
  induction m generalizing h with
  | zero =>
    unfold fpN fpM
    simp only [Finset.univ_unique, Finset.sum_singleton]
    simp only [fpScore, Finset.univ_eq_empty, Finset.sum_empty]
    split_ifs with h1 h2 h2 <;> first | rfl | (exfalso; simp at h1; omega)
  | succ m ih =>
    rw [fpN_succ]
    split_ifs with h0
    · rw [ih (h+1) (by omega), ih (h-1) (by omega), fpM_succ,
        fpM_split m (-(h+1)) h (h+1+1) (by omega) (by omega),
        fpM_split m (-h + 1) h (h + 1 + 1) (by omega) (by omega)]
      have e1 : -(h - 1) = -h + 1 := by ring
      have e2 : h - 1 + 1 = h := by ring
      have e3 : -h - 1 = -(h+1) := by ring
      have e4 : h + 1 - 1 = h := by ring
      rw [e1, e2, e3, e4]
      omega
    · symm
      apply fpM_zero_of
      intro x; omega

lemma fpM_binom (m k : ℕ) (j : ℤ) (hj : j = 2 * (k : ℤ) - m) : fpM m j j = m.choose k := by
  induction m generalizing k j with
  | zero =>
    unfold fpM
    simp only [Finset.univ_unique, Finset.sum_singleton, fpScore, Finset.univ_eq_empty,
      Finset.sum_empty]
    cases k with
    | zero => simp at hj; simp [hj]
    | succ k => simp at hj; rw [if_neg (by omega)]; simp
  | succ m ih =>
    rw [fpM_succ]
    cases k with
    | zero =>
      rw [fpM_zero_of m (j - 1) (j - 1) (fun x => by have := fp_ms_bounds m x; push_cast at hj; omega),
        ih 0 (j + 1) (by push_cast at hj ⊢; omega)]
      simp
    | succ k =>
      rw [ih k (j - 1) (by push_cast at hj ⊢; omega), ih (k + 1) (j + 1) (by push_cast at hj ⊢; omega),
        Nat.choose_succ_succ]

lemma fpM_odd (m : ℕ) (j : ℤ) (hj : (j + m) % 2 = 1) : fpM m j j = 0 :=
  fpM_zero_of m j j (fun x => by have := fp_ms_bounds m x; omega)

lemma fp_forall_Icc_succ {P : ℕ → Prop} {m : ℕ} :
    (∀ k ∈ Icc 1 (m + 1), P k) ↔ ∀ j ≤ m, P (j + 1) :=
  ⟨fun h j hj => h _ (by simp; omega), fun h k hk => by
    simp at hk
    obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
    exact h j (by omega)⟩

lemma fp_ivt (m : ℕ) (y : Fin m → Bool) (h : ℤ) (hh : 0 ≤ h) :
    (∀ j ≤ m, h + 1 + fpScore y j ≠ 0) ↔ (∀ j ≤ m, 0 ≤ h + fpScore y j) := by
  induction m generalizing h with
  | zero =>
    constructor <;> intro _ j hj <;> obtain rfl : j = 0 := (by omega) <;> simp [fp_ms_zero] <;>
      omega
  | succ m ih =>
    obtain ⟨c, t, rfl⟩ := fp_cons_exists y
    rw [fp_forall_le_succ, fp_forall_le_succ]
    simp only [fp_ms_zero, fp_ms_cons]
    cases c
    · simp only [fpSg, Bool.false_eq_true, ite_false]
      rcases eq_or_lt_of_le hh with h0 | h0
      · subst h0
        constructor
        · rintro ⟨_, h2⟩; have := h2 0 (by omega); simp [fp_ms_zero] at this
        · rintro ⟨_, h2⟩; have := h2 0 (by omega); simp [fp_ms_zero] at this
      · have := ih t (h - 1) (by omega)
        constructor
        · rintro ⟨_, h2⟩
          refine ⟨by omega, fun j hj => ?_⟩
          have := this.mp (fun j hj => by have := h2 j hj; omega) j hj
          omega
        · rintro ⟨_, h2⟩
          refine ⟨by omega, fun j hj => ?_⟩
          have := this.mpr (fun j hj => by have := h2 j hj; omega) j hj
          omega
    · simp only [fpSg, ite_true]
      have := ih t (h + 1) (by omega)
      constructor
      · rintro ⟨_, h2⟩
        refine ⟨by omega, fun j hj => ?_⟩
        have := this.mp (fun j hj => by have := h2 j hj; omega) j hj
        omega
      · rintro ⟨_, h2⟩
        refine ⟨by omega, fun j hj => ?_⟩
        have := this.mpr (fun j hj => by have := h2 j hj; omega) j hj
        omega

lemma fp_never_level_succ (m : ℕ) :
    #(univ.filter (fun ω : Fin (m+1) → Bool => fpAvoids 0 ω)) = 2 * fpN m 0 := by
  rw [Finset.card_filter, fp_sum_split]
  simp only [fpAvoids, fp_forall_Icc_succ, fp_ms_cons, fpSg, Bool.false_eq_true, ite_true,
    ite_false]
  have key : ∀ y : Fin m → Bool, (∀ j ≤ m, 1 + fpScore y j ≠ 0) ↔
      (∀ j ≤ m, 0 ≤ 0 + fpScore y j) := by
    intro y
    have := fp_ivt m y 0 le_rfl
    simpa using this
  have h1 : (∑ y : Fin m → Bool, if (∀ j ≤ m, 1 + fpScore y j ≠ 0) then 1 else 0) = fpN m 0 := by
    unfold fpN
    refine Finset.sum_congr rfl fun y _ => ?_
    simp only [key y]
  rw [fp_sum_not (fun y : Fin m → Bool => if (∀ j ≤ m, -1 + fpScore y j ≠ 0) then 1 else 0)]
  simp only [fp_ms_not]
  have h2 : (∑ y : Fin m → Bool, if (∀ j ≤ m, -1 + -fpScore y j ≠ 0) then 1 else 0) =
      (∑ y : Fin m → Bool, if (∀ j ≤ m, 1 + fpScore y j ≠ 0) then 1 else 0) := by
    refine Finset.sum_congr rfl fun y _ => ?_
    congr 1
    refine propext (forall_congr' fun j => imp_congr_right fun _ => ?_)
    constructor <;> intro h <;> omega
  rw [h2, h1]
  ring

lemma fp_card_avoid_zero (n : ℕ) :
    #(univ.filter (fun ω : Fin (2 * n) → Bool => fpAvoids 0 ω)) = Nat.choose (2 * n) n := by
  rcases n with _ | n
  · decide
  · have e : 2 * (n + 1) = (2 * n + 1) + 1 := by ring
    rw [e, fp_never_level_succ, fpN_eq_fpM _ _ (by norm_num), neg_zero, zero_add,
      fpM_split _ 0 0 1 (by norm_num) (by norm_num), fpM_odd _ _ (by push_cast; omega), zero_add, zero_add,
      fpM_binom (2 * n + 1) (n + 1) _ (by push_cast; ring), Nat.choose_succ_succ (2 * n + 1) n,
      Nat.choose_symm_half]
    ring

/-- The chance of one particular win-loss sequence when each round is won with chance `p`. -/
noncomputable def fpW (p : ℝ) {n : ℕ} (x : Fin n → Bool) : ℝ :=
  ∏ i, (if x i then p else 1 - p)

open Classical in
/-- Chance that the score equals `b` on some round from 0 to `n`. -/
noncomputable def fpPhi (p : ℝ) (n : ℕ) (b : ℤ) : ℝ :=
  ∑ x : Fin n → Bool, if (∃ k ≤ n, fpScore x k = b) then fpW p x else 0

open Classical in
/-- Chance that the score equals `a` on some round from 1 to `n`. -/
noncomputable def fpPsi (p : ℝ) (n : ℕ) (a : ℤ) : ℝ :=
  ∑ x : Fin n → Bool, if (∃ k ∈ Icc 1 n, fpScore x k = a) then fpW p x else 0

lemma fpW_cons (p : ℝ) {n : ℕ} (c : Bool) (y : Fin n → Bool) :
    fpW p (Fin.cons c y : Fin (n+1) → Bool) = (if c then p else 1 - p) * fpW p y := by
  simp [fpW, Fin.prod_univ_succ]

lemma fpW_sum (p : ℝ) (n : ℕ) : ∑ x : Fin n → Bool, fpW p x = 1 := by
  induction n with
  | zero => simp [fpW]
  | succ n ih =>
    rw [fp_sum_split]
    simp only [fpW_cons, ite_true, Bool.false_eq_true, ite_false, ← Finset.mul_sum, ih]
    ring

lemma fpW_nonneg (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) {n : ℕ} (x : Fin n → Bool) :
    0 ≤ fpW p x :=
  Finset.prod_nonneg fun i _ => by split_ifs <;> linarith

lemma fp_exists_Icc_succ {P : ℕ → Prop} {m : ℕ} :
    (∃ k ∈ Icc 1 (m + 1), P k) ↔ ∃ j ≤ m, P (j + 1) :=
  ⟨fun ⟨k, hk, h⟩ => by
    simp at hk
    obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
    exact ⟨j, by omega, h⟩, fun ⟨j, hj, h⟩ => ⟨j + 1, by simp; omega, h⟩⟩

lemma fpPhi_eq (p : ℝ) (n : ℕ) (b : ℤ) :
    fpPhi p n b = if b = 0 then 1 else fpPsi p n b := by
  unfold fpPhi fpPsi
  split_ifs with hb
  · subst hb
    rw [← fpW_sum p n]
    exact Finset.sum_congr rfl fun x _ => if_pos ⟨0, Nat.zero_le _, fp_ms_zero x⟩
  · refine Finset.sum_congr rfl fun x _ => ?_
    congr 1
    refine propext ⟨fun ⟨k, hk, h⟩ => ⟨k, ?_, h⟩, fun ⟨k, hk, h⟩ => ⟨k, by simp at hk; omega, h⟩⟩
    rcases k with _ | k
    · rw [fp_ms_zero] at h; exact absurd h.symm hb
    · simp; omega

lemma fpPsi_succ (p : ℝ) (n : ℕ) (a : ℤ) :
    fpPsi p (n+1) a = p * fpPhi p n (a - 1) + (1 - p) * fpPhi p n (a + 1) := by
  unfold fpPsi fpPhi
  rw [fp_sum_split]
  simp only [fp_exists_Icc_succ, fp_ms_cons, fpW_cons, fpSg, ite_true, Bool.false_eq_true,
    ite_false, Finset.mul_sum]
  congr 1 <;> refine Finset.sum_congr rfl fun y _ => ?_ <;> rw [mul_ite, mul_zero] <;> congr 1 <;>
    refine propext (exists_congr fun j => and_congr_right fun _ => ?_) <;> constructor <;>
    intro <;> omega

lemma fpPhi_zero (p : ℝ) (b : ℤ) : fpPhi p 0 b = if b = 0 then 1 else 0 := by
  rw [fpPhi_eq]
  split_ifs
  · rfl
  · unfold fpPsi
    exact Finset.sum_eq_zero fun x _ => if_neg (by simp)

lemma fpPhi_succ (p : ℝ) (n : ℕ) (b : ℤ) :
    fpPhi p (n+1) b = if b = 0 then 1 else p * fpPhi p n (b - 1) + (1 - p) * fpPhi p n (b + 1) := by
  rw [fpPhi_eq, fpPsi_succ]

lemma fpPhi_bounds (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (n : ℕ) (b : ℤ) :
    0 ≤ fpPhi p n b ∧ fpPhi p n b ≤ 1 := by
  induction n generalizing b with
  | zero => rw [fpPhi_zero]; split_ifs <;> norm_num
  | succ n ih =>
    rw [fpPhi_succ]
    split_ifs
    · norm_num
    · have h1 := ih (b - 1); have h2 := ih (b + 1)
      constructor <;> nlinarith

lemma fpPhi_mono (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (n : ℕ) (b : ℤ) :
    fpPhi p n b ≤ fpPhi p (n+1) b := by
  induction n generalizing b with
  | zero =>
    rw [fpPhi_zero, fpPhi_succ]
    split_ifs
    · rfl
    · have h1 := fpPhi_bounds p hp0 hp1 0 (b - 1); have h2 := fpPhi_bounds p hp0 hp1 0 (b + 1)
      nlinarith
  | succ n ih =>
    rw [fpPhi_succ p (n+1), fpPhi_succ p n]
    split_ifs
    · rfl
    · have h1 := ih (b - 1); have h2 := ih (b + 1)
      nlinarith

lemma fpPhi_symm (p : ℝ) (n : ℕ) (b : ℤ) : fpPhi p n b = fpPhi (1 - p) n (-b) := by
  induction n generalizing b with
  | zero => rw [fpPhi_zero, fpPhi_zero]; simp
  | succ n ih =>
    rw [fpPhi_succ, fpPhi_succ, ih (b - 1), ih (b + 1)]
    simp only [neg_eq_zero]
    split_ifs
    · rfl
    · rw [show -(b - 1) = -b + 1 by ring, show -(b + 1) = -b - 1 by ring]
      ring

lemma fpPhi_le (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (φ : ℤ → ℝ) (hφ0 : ∀ b, 0 ≤ φ b)
    (hφ1 : 1 ≤ φ 0) (hφ : ∀ b, b ≠ 0 → p * φ (b - 1) + (1 - p) * φ (b + 1) ≤ φ b)
    (n : ℕ) (b : ℤ) : fpPhi p n b ≤ φ b := by
  induction n generalizing b with
  | zero =>
    rw [fpPhi_zero]
    split_ifs with hb
    · subst hb; exact hφ1
    · exact hφ0 b
  | succ n ih =>
    rw [fpPhi_succ]
    split_ifs with hb
    · subst hb; exact hφ1
    · have h1 := ih (b - 1); have h2 := ih (b + 1); have h3 := hφ b hb
      nlinarith

/-- The chance of ever reaching `b` (time 0 included). -/
noncomputable def fpH (p : ℝ) (b : ℤ) : ℝ := ⨆ n, fpPhi p n b

lemma fpPhi_bdd (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (b : ℤ) :
    BddAbove (Set.range fun n => fpPhi p n b) :=
  ⟨1, by rintro _ ⟨n, rfl⟩; exact (fpPhi_bounds p hp0 hp1 n b).2⟩

lemma fpPhi_tendsto (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (b : ℤ) :
    Filter.Tendsto (fun n => fpPhi p n b) Filter.atTop (nhds (fpH p b)) :=
  tendsto_atTop_ciSup (monotone_nat_of_le_succ fun n => fpPhi_mono p hp0 hp1 n b)
    (fpPhi_bdd p hp0 hp1 b)

lemma fpH_bounds (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (b : ℤ) : 0 ≤ fpH p b ∧ fpH p b ≤ 1 :=
  ⟨le_ciSup_of_le (fpPhi_bdd p hp0 hp1 b) 0 (fpPhi_bounds p hp0 hp1 0 b).1,
    ciSup_le fun n => (fpPhi_bounds p hp0 hp1 n b).2⟩

lemma fpH_zero (p : ℝ) : fpH p 0 = 1 := by
  have : ∀ n, fpPhi p n 0 = 1 := by
    intro n; cases n with
    | zero => rw [fpPhi_zero]; simp
    | succ n => rw [fpPhi_succ]; simp
  simp [fpH, this]

lemma fpH_rec (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (b : ℤ) (hb : b ≠ 0) :
    fpH p b = p * fpH p (b - 1) + (1 - p) * fpH p (b + 1) := by
  have t1 : Filter.Tendsto (fun n => fpPhi p (n + 1) b) Filter.atTop (nhds (fpH p b)) :=
    (fpPhi_tendsto p hp0 hp1 b).comp (Filter.tendsto_add_atTop_nat 1)
  have t2 : Filter.Tendsto (fun n => fpPhi p (n + 1) b) Filter.atTop
      (nhds (p * fpH p (b - 1) + (1 - p) * fpH p (b + 1))) := by
    simp_rw [fpPhi_succ, if_neg hb]
    exact ((fpPhi_tendsto p hp0 hp1 _).const_mul p).add
      ((fpPhi_tendsto p hp0 hp1 _).const_mul (1 - p))
  exact tendsto_nhds_unique t1 t2

lemma fpH_le (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (φ : ℤ → ℝ) (hφ0 : ∀ b, 0 ≤ φ b)
    (hφ1 : 1 ≤ φ 0) (hφ : ∀ b, b ≠ 0 → p * φ (b - 1) + (1 - p) * φ (b + 1) ≤ φ b)
    (b : ℤ) : fpH p b ≤ φ b :=
  ciSup_le fun n => fpPhi_le p hp0 hp1 φ hφ0 hφ1 hφ n b

lemma fpH_symm (p : ℝ) (b : ℤ) : fpH p b = fpH (1 - p) (-b) := by
  unfold fpH
  simp_rw [fpPhi_symm p _ b]

/-- The chance of ever reaching level `n ≥ 0`. -/
noncomputable def fpHN (p : ℝ) (n : ℕ) : ℝ := fpH p n

lemma fpHN_rec (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (n : ℕ) :
    fpHN p (n + 1) = p * fpHN p n + (1 - p) * fpHN p (n + 2) := by
  have := fpH_rec p hp0 hp1 ((n + 1 : ℕ) : ℤ) (by omega)
  unfold fpHN
  convert this using 4 <;> push_cast <;> ring

lemma fpHN_gen (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (hq : 0 < 1 - p) (n : ℕ) :
    fpHN p n = 1 + (fpHN p 1 - 1) * ∑ i ∈ range n, (p / (1 - p)) ^ i := by
  have H0 : fpHN p 0 = 1 := by simp [fpHN, fpH_zero]
  have hD : ∀ n, fpHN p (n + 1) - fpHN p n = (p / (1 - p)) ^ n * (fpHN p 1 - 1) := by
    intro n
    induction n with
    | zero => simp [H0]
    | succ n ih =>
      have key : (1 - p) * (fpHN p (n + 2) - fpHN p (n + 1)) =
          p * (fpHN p (n + 1) - fpHN p n) := by
        linear_combination (-1 : ℝ) * fpHN_rec p hp0 hp1 n
      have key2 : fpHN p (n + 2) - fpHN p (n + 1) = p / (1 - p) * (fpHN p (n + 1) - fpHN p n) := by
        rw [div_mul_eq_mul_div, eq_div_iff hq.ne']
        linarith
      rw [key2, ih]
      ring
  induction n with
  | zero => simp [H0]
  | succ n ih =>
    rw [sum_range_succ]
    have := hD n
    linear_combination this + ih

lemma fpH_level (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (a : ℕ) :
    fpH p a = if 1 / 2 ≤ p then 1 else (p / (1 - p)) ^ a := by
  show fpHN p a = _
  have H0 : fpHN p 0 = 1 := by simp [fpHN, fpH_zero]
  have Hb : ∀ n, 0 ≤ fpHN p n ∧ fpHN p n ≤ 1 := fun n => fpH_bounds p hp0 hp1 n
  by_cases hp : 1 / 2 ≤ p
  · rw [if_pos hp]
    by_cases hp1' : p = 1
    · subst hp1'
      have : ∀ n, fpHN 1 n = 1 := by
        intro n
        induction n with
        | zero => exact H0
        | succ n ih => have := fpHN_rec 1 hp0 hp1 n; rw [this, ih]; ring
      exact this a
    · have hq : 0 < 1 - p := by
        have := lt_of_le_of_ne hp1 hp1'
        linarith
      have hc : fpHN p 1 - 1 = 0 := by
        by_contra hc
        have hcpos : 0 < |fpHN p 1 - 1| := abs_pos.mpr hc
        obtain ⟨N, hN⟩ := exists_nat_gt (1 / |fpHN p 1 - 1|)
        have hR : 1 ≤ p / (1 - p) := by rw [le_div_iff₀ hq]; linarith
        have hG : (N : ℝ) ≤ ∑ i ∈ range N, (p / (1 - p)) ^ i := by
          calc (N : ℝ) = ∑ i ∈ range N, (1 : ℝ) := by simp
            _ ≤ _ := Finset.sum_le_sum fun i _ => one_le_pow₀ hR
        have h1 := fpHN_gen p hp0 hp1 hq N
        have h2 := Hb N
        have h3 : 1 < |fpHN p 1 - 1| * N := by
          rw [div_lt_iff₀ hcpos] at hN; linarith
        have h4 : |fpHN p N - 1| ≤ 1 := by rw [abs_le]; constructor <;> linarith
        rw [h1, add_sub_cancel_left, abs_mul,
          abs_of_nonneg (le_trans (Nat.cast_nonneg N) hG)] at h4
        nlinarith
      have := fpHN_gen p hp0 hp1 hq a
      rw [hc] at this
      simpa using this
  · rw [if_neg hp]
    replace hp := not_le.mp hp
    have hq : 0 < 1 - p := by linarith
    have hr0 : 0 ≤ p / (1 - p) := div_nonneg hp0 hq.le
    have hr1 : p / (1 - p) < 1 := by rw [div_lt_one hq]; linarith
    have hup : ∀ n : ℕ, fpHN p n ≤ (p / (1 - p)) ^ n := by
      intro n
      have := fpH_le p hp0 hp1 (fun b => (p / (1 - p)) ^ b.toNat) (fun b => pow_nonneg hr0 _)
        (by simp) ?_ n
      · simpa [fpHN] using this
      · intro b hb
        rcases lt_or_gt_of_ne hb with hb | hb
        · have e1 : (b - 1).toNat = 0 := by omega
          have e2 : (b + 1).toNat = 0 := by omega
          have e3 : b.toNat = 0 := by omega
          simp only [e1, e2, e3, pow_zero]
          linarith
        · obtain ⟨m, rfl⟩ : ∃ m : ℕ, b = m + 1 := ⟨(b - 1).toNat, by omega⟩
          have e1 : ((m : ℤ) + 1 - 1).toNat = m := by omega
          have e2 : ((m : ℤ) + 1 + 1).toNat = m + 2 := by omega
          have e3 : ((m : ℤ) + 1).toNat = m + 1 := by omega
          simp only [e1, e2, e3]
          have : p + (1 - p) * (p / (1 - p)) ^ 2 = p / (1 - p) := by
            field_simp; ring
          apply le_of_eq
          calc p * (p / (1 - p)) ^ m + (1 - p) * (p / (1 - p)) ^ (m + 2)
              = (p / (1 - p)) ^ m * (p + (1 - p) * (p / (1 - p)) ^ 2) := by ring
            _ = (p / (1 - p)) ^ (m + 1) := by rw [this]; ring
    have hG : ∀ n, (∑ i ∈ range n, (p / (1 - p)) ^ i) * (p / (1 - p) - 1) =
        (p / (1 - p)) ^ n - 1 := fun n => geom_sum_mul _ n
    have hform : ∀ n, fpHN p n = (p / (1 - p)) ^ n +
        (fpHN p 1 - 1 - (p / (1 - p) - 1)) * ∑ i ∈ range n, (p / (1 - p)) ^ i := by
      intro n
      rw [fpHN_gen p hp0 hp1 hq n]
      linear_combination hG n
    have he1 : fpHN p 1 - 1 - (p / (1 - p) - 1) ≤ 0 := by
      have := hup 1
      rw [hform 1] at this
      simp at this
      linarith
    have he : fpHN p 1 - 1 - (p / (1 - p) - 1) = 0 := by
      by_contra hne
      have he' := lt_of_le_of_ne he1 hne
      obtain ⟨N, hN⟩ := exists_pow_lt_of_lt_one (neg_pos.mpr he') hr1
      have hGe : 1 ≤ ∑ i ∈ range (N + 1), (p / (1 - p)) ^ i := by
        rw [sum_range_succ']
        simp only [pow_zero]
        have : 0 ≤ ∑ i ∈ range N, (p / (1 - p)) ^ (i + 1) :=
          Finset.sum_nonneg fun i _ => pow_nonneg hr0 _
        linarith
      have h1 := hform (N + 1)
      have h2 := (Hb (N + 1)).1
      have h3 : (p / (1 - p)) ^ (N + 1) ≤ (p / (1 - p)) ^ N :=
        pow_le_pow_of_le_one hr0 hr1.le (by omega)
      nlinarith
    rw [hform, he]
    simp

lemma fp_return_value (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    p * fpH p (-1) + (1 - p) * fpH p 1 = 1 - |p - (1 - p)| := by
  rw [fpH_symm p (-1), neg_neg]
  have h1 := fpH_level p hp0 hp1 1
  have h2 := fpH_level (1 - p) (by linarith) (by linarith) 1
  push_cast at h1 h2
  rw [h1, h2]
  by_cases hp : 1 / 2 ≤ p
  · rw [if_pos hp]
    by_cases hq : 1 / 2 ≤ 1 - p
    · rw [if_pos hq]
      have : p = 1 / 2 := by linarith
      subst this; norm_num
    · rw [if_neg hq, abs_of_nonneg (by linarith), pow_one]
      have hp' : 0 < p := by linarith
      rw [show 1 - (1 - p) = p by ring]
      field_simp
      ring
  · rw [if_neg hp, if_pos (by linarith), abs_of_neg (by linarith), pow_one]
    have hq : 0 < 1 - p := by linarith
    field_simp
    ring

lemma fpPsi_tendsto_ne (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (a : ℤ) (ha : a ≠ 0) :
    Filter.Tendsto (fun n => fpPsi p n a) Filter.atTop (nhds (fpH p a)) := by
  have := fpPhi_tendsto p hp0 hp1 a
  simp_rw [fpPhi_eq, if_neg ha] at this
  exact this

lemma fpPsi_tendsto_zero (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    Filter.Tendsto (fun n => fpPsi p n 0) Filter.atTop
      (nhds (p * fpH p (-1) + (1 - p) * fpH p 1)) := by
  rw [← Filter.tendsto_add_atTop_iff_nat 1]
  simp_rw [fpPsi_succ, zero_sub, zero_add]
  exact ((fpPhi_tendsto p hp0 hp1 _).const_mul p).add
    ((fpPhi_tendsto p hp0 hp1 _).const_mul (1 - p))

lemma fp_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p) (n : ℕ)
    (Q : (Fin n → Bool) → Prop) [DecidablePred Q] :
    P {ω | Q (fun i => decide (X i ω = 1))} =
      ENNReal.ofReal (∑ x, if Q x then fpW p x else 0) := by
  classical
  have hYm : ∀ i : ℕ, Measurable (fun ω => decide (X i ω = 1)) :=
    fun i => (measurable_of_countable (fun z : ℤ => decide (z = 1))).comp (hmeas i)
  have hY : iIndepFun (fun (i : Fin n) ω => decide (X i ω = 1)) P := by
    have h1 := hind.precomp (g := fun i : Fin n => (i : ℕ)) Fin.val_injective
    exact h1.comp (fun _ z => decide (z = 1)) (fun _ => measurable_of_countable _)
  have hcyl : ∀ x : Fin n → Bool, P {ω | (fun i : Fin n => decide (X i ω = 1)) = x} =
      ENNReal.ofReal (fpW p x) := by
    intro x
    have hset : {ω | (fun i : Fin n => decide (X i ω = 1)) = x} =
        ⋂ i ∈ (univ : Finset (Fin n)), (fun ω => decide (X i ω = 1)) ⁻¹' {x i} := by
      ext ω; simp [funext_iff]
    rw [hset, hY.measure_inter_preimage_eq_mul univ (fun i _ => measurableSet_singleton _)]
    unfold fpW
    rw [ENNReal.ofReal_prod_of_nonneg (fun i _ => by split_ifs <;> linarith)]
    refine Finset.prod_congr rfl fun i _ => ?_
    have hm1 : MeasurableSet {ω | X i ω = 1} := hmeas i (measurableSet_singleton (1 : ℤ))
    cases hx : x i
    · have : (fun ω => decide (X i ω = 1)) ⁻¹' {false} = {ω | X i ω = 1}ᶜ := by
        ext ω; simp
      rw [this, prob_compl_eq_one_sub hm1, hup]
      simp only [Bool.false_eq_true, ite_false]
      rw [ENNReal.ofReal_sub _ hp0, ENNReal.ofReal_one]
    · have : (fun ω => decide (X i ω = 1)) ⁻¹' {true} = {ω | X i ω = 1} := by
        ext ω; simp
      rw [this, hup]
      simp
  have hU : {ω | Q (fun i => decide (X i ω = 1))} =
      ⋃ x ∈ univ.filter Q, {ω | (fun i : Fin n => decide (X i ω = 1)) = x} := by
    ext ω; simp
  rw [hU, measure_biUnion_finset]
  · simp_rw [hcyl]
    rw [← ENNReal.ofReal_sum_of_nonneg (fun x _ => fpW_nonneg p hp0 hp1 x), Finset.sum_filter]
  · intro x _ y _ hxy
    rw [Function.onFun, Set.disjoint_left]
    intro ω h1 h2
    exact hxy (h1.symm.trans h2)
  · intro x _
    exact (measurable_pi_iff.mpr (fun i : Fin n => hYm i)) (measurableSet_singleton x)

lemma fp_ae_pm {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) :
    ∀ᵐ ω ∂P, ∀ i, X i ω = 1 ∨ X i ω = -1 := by
  rw [ae_all_iff]
  intro i
  have hm1 : MeasurableSet {ω | X i ω = 1} := hmeas i (measurableSet_singleton (1 : ℤ))
  have hm2 : MeasurableSet {ω | X i ω = -1} := hmeas i (measurableSet_singleton (-1 : ℤ))
  have hu : P ({ω | X i ω = 1} ∪ {ω | X i ω = -1}) = 1 := by
    rw [measure_union _ hm2, hup, hdown, ← ENNReal.ofReal_add hp0 (by linarith)]
    · simp
    · rw [Set.disjoint_left]; intro ω h1 h2; simp at h1 h2; omega
  have := (prob_compl_eq_zero_iff (hm1.union hm2)).mpr hu
  rw [ae_iff]
  refine measure_mono_null ?_ this
  intro ω hω
  simp only [Set.mem_setOf_eq, not_or] at hω
  simp [hω.1, hω.2]

lemma fp_score_eq {Ω : Type*} (X : ℕ → Ω → ℤ) (ω : Ω) (hω : ∀ i, X i ω = 1 ∨ X i ω = -1)
    (n k : ℕ) (hk : k ≤ n) :
    walkScore X k ω = fpScore (fun i : Fin n => decide (X i ω = 1)) k := by
  unfold walkScore fpScore
  rw [Fin.sum_univ_eq_sum_range
    (fun j => if j < k then (if decide (X j ω = 1) = true then (1 : ℤ) else -1) else 0) n,
    ← Finset.sum_filter]
  have : (range n).filter (· < k) = range k := by
    ext j; simp; omega
  rw [this]
  refine Finset.sum_congr rfl fun i _ => ?_
  rcases hω i with h | h <;> simp [h]

lemma fp_walk_meas {Ω : Type*} [MeasurableSpace Ω] (X : ℕ → Ω → ℤ)
    (hmeas : ∀ i, Measurable (X i)) (k : ℕ) : Measurable (fun ω => walkScore X k ω) :=
  Finset.measurable_sum _ (fun i _ => hmeas i)

lemma fp_event_hit {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) (n : ℕ) (a : ℤ) :
    P {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a} = ENNReal.ofReal (fpPsi p n a) := by
  have h := fp_law X hmeas hind p hp0 hp1 hup n (fun x => ∃ k ∈ Icc (1:ℕ) n, fpScore x k = a)
  have hset : {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a} =ᵐ[P]
      {ω | ∃ k ∈ Icc 1 n, fpScore (fun i : Fin n => decide (X i ω = 1)) k = a} := by
    rw [Filter.eventuallyEq_set]
    filter_upwards [fp_ae_pm X hmeas p hp0 hp1 hup hdown] with ω hω
    constructor
    · rintro ⟨k, hk, h⟩
      exact ⟨k, hk, by rw [← fp_score_eq X ω hω n k (Finset.mem_Icc.mp hk).2]; exact h⟩
    · rintro ⟨k, hk, h⟩
      exact ⟨k, hk, by rw [fp_score_eq X ω hω n k (Finset.mem_Icc.mp hk).2]; exact h⟩
  rw [measure_congr hset, h, fpPsi]
  congr 1
  refine Finset.sum_congr rfl fun x _ => ?_
  congr 1

lemma fp_event_avoid {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) (n : ℕ) (a : ℤ) :
    P {ω | ∀ k ∈ Icc 1 n, walkScore X k ω ≠ a} = ENNReal.ofReal
      (∑ x : Fin n → Bool, if fpAvoids a x then fpW p x else 0) := by
  have h := fp_law X hmeas hind p hp0 hp1 hup n (fpAvoids a)
  have hset : {ω | ∀ k ∈ Icc 1 n, walkScore X k ω ≠ a} =ᵐ[P]
      {ω | fpAvoids a (fun i : Fin n => decide (X i ω = 1))} := by
    rw [Filter.eventuallyEq_set]
    filter_upwards [fp_ae_pm X hmeas p hp0 hp1 hup hdown] with ω hω
    simp only [Set.mem_setOf_eq, fpAvoids]
    constructor
    · intro h k hk
      rw [← fp_score_eq X ω hω n k (Finset.mem_Icc.mp hk).2]; exact h k hk
    · intro h k hk
      rw [fp_score_eq X ω hω n k (Finset.mem_Icc.mp hk).2]; exact h k hk
  rw [measure_congr hset, h]

lemma fp_hit_set {Ω : Type*} (X : ℕ → Ω → ℤ) (a : ℤ) :
    {ω | hitTime X a ω < ∞} = ⋃ n, {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a} := by
  ext ω
  simp only [hitTime, Set.mem_setOf_eq, Set.mem_iUnion, iInf_lt_iff, Finset.mem_Icc]
  constructor
  · rintro ⟨n, ⟨h1, h2⟩, -⟩
    exact ⟨n, n, ⟨h1, le_rfl⟩, h2⟩
  · rintro ⟨n, k, ⟨h1, -⟩, h2⟩
    exact ⟨k, ⟨h1, h2⟩, ENNReal.natCast_lt_top k⟩

lemma fp_hit_prob {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) (a : ℤ) (L : ℝ)
    (hL : Filter.Tendsto (fun n => fpPsi p n a) Filter.atTop (nhds L)) :
    P {ω | hitTime X a ω < ∞} = ENNReal.ofReal L := by
  rw [fp_hit_set]
  have hmono : Monotone (fun n => {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a}) := by
    intro n m hnm ω ⟨k, hk, h⟩
    exact ⟨k, by simp at hk ⊢; omega, h⟩
  have t1 := tendsto_measure_iUnion_atTop (μ := P) hmono
  have t2 : Filter.Tendsto (P ∘ fun n => {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a})
      Filter.atTop (nhds (ENNReal.ofReal L)) := by
    have : (P ∘ fun n => {ω | ∃ k ∈ Icc 1 n, walkScore X k ω = a}) =
        fun n => ENNReal.ofReal (fpPsi p n a) := by
      funext n
      exact fp_event_hit X hmeas hind p hp0 hp1 hup hdown n a
    rw [this]
    exact (ENNReal.continuous_ofReal.tendsto L).comp hL
  exact tendsto_nhds_unique t1 t2


lemma fp_count_avoid (a : ℤ) (m : ℕ) :
    ((2 * m).choose m : ℝ) ≤ ∑ x : Fin (2 * m) → Bool, if fpAvoids a x then (1 : ℝ) else 0 := by
  have base : ((2 * m).choose m : ℝ) ≤ fpN (2 * m) 0 := by
    have : (2 * m).choose m ≤ fpN (2 * m) 0 := by
      rw [fpN_eq_fpM _ _ (by norm_num), neg_zero, zero_add,
        fpM_split (2 * m) 0 0 1 (by norm_num) (by norm_num),
        fpM_binom (2 * m) m 0 (by push_cast; ring)]
      omega
    exact_mod_cast this
  have hpt : ∀ (P Q : Prop) [Decidable P] [Decidable Q], (P → Q) →
      (if P then (1 : ℝ) else 0) ≤ (if Q then (1 : ℝ) else 0) := by
    intro P Q _ _ hPQ
    by_cases hP : P
    · simp [hP, hPQ hP]
    · simp only [hP, if_false]; split_ifs <;> norm_num
  rcases lt_trichotomy a 0 with ha | rfl | ha
  · refine base.trans ?_
    unfold fpN
    push_cast
    refine Finset.sum_le_sum fun x _ => hpt _ _ fun h1 k hk => ?_
    have := h1 k (Finset.mem_Icc.mp hk).2
    omega
  · have := fp_card_avoid_zero m
    rw [Finset.card_filter] at this
    rw [← this]
    push_cast
    exact le_of_eq rfl
  · refine base.trans ?_
    rw [fp_sum_not (fun x : Fin (2 * m) → Bool => if fpAvoids a x then (1 : ℝ) else 0)]
    unfold fpN
    push_cast
    refine Finset.sum_le_sum fun x _ => hpt _ _ fun h1 k hk => ?_
    rw [fp_ms_not]
    have := h1 k (Finset.mem_Icc.mp hk).2
    omega

lemma fp_harmonic_odd : ∑' m : ℕ, ENNReal.ofReal (1 / (2 * (m : ℝ) + 1)) = ∞ := by
  by_contra h
  have h' : Summable (fun m : ℕ => Real.toNNReal (1 / (2 * (m : ℝ) + 1))) :=
    ENNReal.tsum_coe_ne_top_iff_summable.mp h
  have h'' : Summable (fun m : ℕ => 1 / (2 * (m : ℝ) + 1)) := by
    have := NNReal.summable_coe.mpr h'
    refine this.congr fun m => ?_
    simp only [Real.coe_toNNReal _ (by positivity : (0 : ℝ) ≤ 1 / (2 * (m : ℝ) + 1))]
  have h3 : Summable (fun m : ℕ => 1 / ((m + 1 : ℕ) : ℝ)) := by
    refine Summable.of_nonneg_of_le (fun m => by positivity) (fun m => ?_) (h''.mul_left 2)
    push_cast
    rw [mul_one_div, div_le_div_iff₀ (by positivity) (by positivity)]
    nlinarith
  exact Real.not_summable_one_div_natCast ((summable_nat_add_iff 1).mp h3)

#print axioms fp_sum_split
#print axioms fp_ms_zero
#print axioms fp_ms_cons
#print axioms fp_ms_not
#print axioms fp_forall_le_succ
#print axioms fp_sum_not
#print axioms fp_cons_exists
#print axioms fp_ms_bounds
#print axioms fpM_succ
#print axioms fpM_split
#print axioms fpM_zero_of
#print axioms fpN_succ
#print axioms fpN_eq_fpM
#print axioms fpM_binom
#print axioms fpM_odd
#print axioms fp_forall_Icc_succ
#print axioms fp_ivt
#print axioms fp_never_level_succ
#print axioms fp_card_avoid_zero
#print axioms fpW_cons
#print axioms fpW_sum
#print axioms fpW_nonneg
#print axioms fp_exists_Icc_succ
#print axioms fpPhi_eq
#print axioms fpPsi_succ
#print axioms fpPhi_zero
#print axioms fpPhi_succ
#print axioms fpPhi_bounds
#print axioms fpPhi_mono
#print axioms fpPhi_symm
#print axioms fpPhi_le
#print axioms fpPhi_bdd
#print axioms fpPhi_tendsto
#print axioms fpH_bounds
#print axioms fpH_zero
#print axioms fpH_rec
#print axioms fpH_le
#print axioms fpH_symm
#print axioms fpHN_rec
#print axioms fpHN_gen
#print axioms fpH_level
#print axioms fp_return_value
#print axioms fpPsi_tendsto_ne
#print axioms fpPsi_tendsto_zero
#print axioms fp_law
#print axioms fp_ae_pm
#print axioms fp_score_eq
#print axioms fp_walk_meas
#print axioms fp_event_hit
#print axioms fp_event_avoid
#print axioms fp_hit_set
#print axioms fp_hit_prob
#print axioms fp_count_avoid
#print axioms fp_harmonic_odd

/-- **Sure arrival, infinite mean.** Let the rounds be independent, each a step of exactly one
dollar, up with chance 1/2 and down with chance 1/2: the fair walk, with no floor and no
deadline. Then for every level `a` (the start `a = 0` included, which is the return time `T`)
the score reaches `a` with probability 1, and yet the average wait for it is infinite. -/
theorem fair_walk_hits_every_level_surely_with_infinite_mean_wait
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hup : ∀ i, P {ω | X i ω = 1} = 1 / 2) (hdown : ∀ i, P {ω | X i ω = -1} = 1 / 2)
    (a : ℤ) :
    P {ω | hitTime X a ω < ∞} = 1 ∧ ∫⁻ ω, hitTime X a ω ∂P = ∞ := by
  have hhalf : ENNReal.ofReal (1 / 2) = 1 / 2 := by
    rw [ENNReal.ofReal_div_of_pos (by norm_num)]; simp
  have hp0 : (0 : ℝ) ≤ 1 / 2 := by norm_num
  have hp1 : (1 / 2 : ℝ) ≤ 1 := by norm_num
  have hup' : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal (1 / 2) := fun i => by rw [hup, hhalf]
  have hdown' : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - 1 / 2) := fun i => by
    rw [hdown, show (1 : ℝ) - 1 / 2 = 1 / 2 by norm_num, hhalf]
  constructor
  · rcases lt_trichotomy a 0 with ha | rfl | ha
    · rw [fp_hit_prob X hmeas hind _ hp0 hp1 hup' hdown' a _
        (fpPsi_tendsto_ne _ hp0 hp1 a ha.ne), fpH_symm]
      have e : -a = (((-a).toNat : ℕ) : ℤ) := by omega
      rw [e, fpH_level _ (by norm_num) (by norm_num), if_pos (by norm_num)]
      simp
    · rw [fp_hit_prob X hmeas hind _ hp0 hp1 hup' hdown' 0 _ (fpPsi_tendsto_zero _ hp0 hp1),
        fp_return_value _ hp0 hp1]
      norm_num
    · rw [fp_hit_prob X hmeas hind _ hp0 hp1 hup' hdown' a _
        (fpPsi_tendsto_ne _ hp0 hp1 a ha.ne')]
      have e : a = ((a.toNat : ℕ) : ℤ) := by omega
      rw [e, fpH_level _ hp0 hp1, if_pos (by norm_num)]
      simp
  · let A : ℕ → Set Ω := fun j => {ω | ∀ k ∈ Icc (1:ℕ) j, walkScore X k ω ≠ a}
    have hAm : ∀ j, MeasurableSet (A j) := by
      intro j
      have : A j = ⋂ k ∈ Icc (1:ℕ) j, (fun ω => walkScore X k ω) ⁻¹' {a}ᶜ := by
        ext ω; simp [A]
      rw [this]
      exact Finset.measurableSet_biInter _
        (fun k _ => (fp_walk_meas X hmeas k) (measurableSet_singleton a).compl)
    have hle : ∀ ω, ∑' j, (A j).indicator 1 ω ≤ hitTime X a ω := by
      intro ω
      refine ENNReal.tsum_le_of_sum_range_le fun N => ?_
      unfold hitTime
      refine le_iInf₂ fun n hn => ?_
      calc ∑ j ∈ range N, (A j).indicator 1 ω
          ≤ ∑ j ∈ range N, (if j < n then (1 : ℝ≥0∞) else 0) := by
            refine Finset.sum_le_sum fun j _ => ?_
            by_cases hj : j < n
            · rw [if_pos hj]
              unfold Set.indicator
              split_ifs <;> simp
            · rw [if_neg hj]
              have : ω ∉ A j := by
                simp only [A, Set.mem_setOf_eq, not_forall, not_not]
                exact ⟨n, by simp; omega, hn.2⟩
              simp [this]
        _ ≤ n := by
            rw [← Finset.sum_filter, Finset.sum_const, nsmul_eq_mul, mul_one]
            exact_mod_cast (Finset.card_le_card (fun j hj => by simp at hj ⊢; omega)).trans_eq
              (Finset.card_range n)
    have hint : ∑' j, P (A j) ≤ ∫⁻ ω, hitTime X a ω ∂P := by
      calc ∑' j, P (A j) = ∑' j, ∫⁻ ω, (A j).indicator 1 ω ∂P := by
            simp_rw [lintegral_indicator_one (hAm _)]
        _ = ∫⁻ ω, ∑' j, (A j).indicator 1 ω ∂P :=
            (lintegral_tsum fun j => (measurable_one.indicator (hAm j)).aemeasurable).symm
        _ ≤ ∫⁻ ω, hitTime X a ω ∂P := lintegral_mono hle
    have hPA : ∀ m : ℕ, ENNReal.ofReal (1 / (2 * (m : ℝ) + 1)) ≤ P (A (2 * m)) := by
      intro m
      rw [show P (A (2 * m)) = _ from fp_event_avoid X hmeas hind _ hp0 hp1 hup' hdown' (2 * m) a]
      apply ENNReal.ofReal_le_ofReal
      have hW : ∀ x : Fin (2 * m) → Bool, fpW (1 / 2) x = (1 / 4 : ℝ) ^ m := by
        intro x
        unfold fpW
        have : ∀ i, (if x i then (1 / 2 : ℝ) else 1 - 1 / 2) = 1 / 2 := by
          intro i; split_ifs <;> norm_num
        simp only [this, Finset.prod_const, Finset.card_univ, Fintype.card_fin, pow_mul]
        norm_num
      simp_rw [hW]
      have hsplit : ∀ x : Fin (2 * m) → Bool,
          (if fpAvoids a x then (1 / 4 : ℝ) ^ m else 0) =
          (1 / 4 : ℝ) ^ m * (if fpAvoids a x then (1 : ℝ) else 0) := by
        intro x; split_ifs <;> simp
      simp_rw [hsplit]
      rw [← Finset.mul_sum]
      have hc := fp_count_avoid a m
      have h4 := Nat.four_pow_le_two_mul_add_one_mul_centralBinom m
      rw [Nat.centralBinom_eq_two_mul_choose] at h4
      have h4' : (4 : ℝ) ^ m ≤ (2 * m + 1) * ((2 * m).choose m : ℝ) := by exact_mod_cast h4
      have h6 : (0 : ℝ) < 4 ^ m := by positivity
      rw [div_le_iff₀ (by positivity), one_div_pow]
      rw [show ∀ c : ℝ, 1 / 4 ^ m * c * (2 * m + 1) = (2 * m + 1) * c / 4 ^ m by
        intro c; field_simp]
      rw [le_div_iff₀ h6]
      nlinarith
    have hsum : ∑' m : ℕ, P (A (2 * m)) ≤ ∑' j, P (A j) :=
      ENNReal.tsum_comp_le_tsum_of_injective (fun x y h => by simpa using h) (fun j => P (A j))
    refine top_unique ?_
    calc (∞ : ℝ≥0∞) = ∑' m : ℕ, ENNReal.ofReal (1 / (2 * (m : ℝ) + 1)) := fp_harmonic_odd.symm
      _ ≤ ∑' m : ℕ, P (A (2 * m)) := ENNReal.tsum_le_tsum hPA
      _ ≤ ∑' j, P (A j) := hsum
      _ ≤ _ := hint

/-- **Whether it arrives, for any coin.** Let the rounds be independent steps of exactly one
dollar, up with chance `p` and down with chance `q = 1 − p`. For a target `a` of 1 or more,
the chance of ever reaching `a` is 1 when `p ≥ 1/2` and `(p/q)^a` when `p < 1/2`; and the
chance of ever being level again is `1 − |p − q|`. -/
theorem walk_arrival_and_return_chances
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℤ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (p : ℝ) (hp : p ∈ Set.Icc (0 : ℝ) 1)
    (hup : ∀ i, P {ω | X i ω = 1} = ENNReal.ofReal p)
    (hdown : ∀ i, P {ω | X i ω = -1} = ENNReal.ofReal (1 - p)) :
    (∀ a : ℕ, 1 ≤ a → P {ω | hitTime X a ω < ∞} =
        ENNReal.ofReal (if 1 / 2 ≤ p then 1 else (p / (1 - p)) ^ a)) ∧
      P {ω | hitTime X 0 ω < ∞} = ENNReal.ofReal (1 - |p - (1 - p)|) := by
  obtain ⟨hp0, hp1⟩ := hp
  refine ⟨fun a ha => ?_, ?_⟩
  · rw [fp_hit_prob X hmeas hind p hp0 hp1 hup hdown (a : ℤ) _
      (fpPsi_tendsto_ne p hp0 hp1 a (by omega)), fpH_level p hp0 hp1 a]
  · rw [fp_hit_prob X hmeas hind p hp0 hp1 hup hdown 0 _ (fpPsi_tendsto_zero p hp0 hp1),
      fp_return_value p hp0 hp1]

/-! One match of `m` rounds is a win-loss sequence `ω : Fin m → Bool` (`true` = Ana wins the
round). For the fair coin all `2^m` sequences are equally likely, so a count over `2^m` is a
chance. -/

/-- The score after the first `k` rounds of a match of `m` rounds. -/
def matchScore {m : ℕ} (ω : Fin m → Bool) (k : ℕ) : ℤ :=
  ∑ i : Fin m, if (i : ℕ) < k then (if ω i then 1 else -1) else 0

/-- A match of `m` rounds is never level after the start: its score is not 0 on any round
from 1 to `m`. -/
def neverLevel {m : ℕ} (ω : Fin m → Bool) : Prop :=
  ∀ k ∈ Icc 1 m, matchScore ω k ≠ 0

instance {m : ℕ} : DecidablePred (@neverLevel m) := fun ω =>
  inferInstanceAs (Decidable (∀ k ∈ Icc 1 m, matchScore ω k ≠ 0))

/-- **Still waiting after 2n rounds (Step 3).** Of the `2^(2n)` matches of `2n` rounds,
exactly `C(2n, n)` are never level on any round from 1 to `2n`. Dividing by `2^(2n)`:
the chance that the fair return time exceeds `2n` is `u_{2n} = C(2n, n) / 2^(2n)`, the chance
of a tie at round `2n`. -/
theorem card_never_level_eq_choose (n : ℕ) :
    #(univ.filter (fun ω : Fin (2 * n) → Bool => neverLevel ω)) = Nat.choose (2 * n) n := by
  exact fp_card_avoid_zero n

-- Small cases of the count: 2 of the 4 matches of 2 rounds, 6 of the 16 of 4 rounds and
-- 70 of the 256 of 8 rounds are never level; C(2, 1) = 2, C(4, 2) = 6 and C(8, 4) = 70.
example : #(univ.filter (fun ω : Fin 2 → Bool => neverLevel ω)) = Nat.choose 2 1 := by decide
example : #(univ.filter (fun ω : Fin 4 → Bool => neverLevel ω)) = Nat.choose 4 2 := by decide
example : #(univ.filter (fun ω : Fin 8 → Bool => neverLevel ω)) = Nat.choose 8 4 := by decide
-- Worked numbers: u_2, u_4, u_6, u_8, u_10 = C(2n, n) / 2^(2n) are 1/2, 3/8, 5/16, 35/128, 63/256
-- (0.5, 0.375, 0.3125, 0.273438, 0.246094).
example : (Nat.choose 2 1 : ℚ) / 2 ^ 2 = 1 / 2 ∧ (Nat.choose 4 2 : ℚ) / 2 ^ 4 = 3 / 8 ∧
    (Nat.choose 6 3 : ℚ) / 2 ^ 6 = 5 / 16 ∧ (Nat.choose 8 4 : ℚ) / 2 ^ 8 = 35 / 128 ∧
    (Nat.choose 10 5 : ℚ) / 2 ^ 10 = 63 / 256 := by
  norm_num [Nat.choose]
-- Each u is the one before times (2n − 1)/(2n): 1/2 · 3/4 = 3/8, · 5/6 = 5/16, · 7/8 = 35/128, · 9/10 = 63/256.
example : (1 : ℚ) / 2 * (3 / 4) = 3 / 8 ∧ (3 : ℚ) / 8 * (5 / 6) = 5 / 16 ∧
    (5 : ℚ) / 16 * (7 / 8) = 35 / 128 ∧ (35 : ℚ) / 128 * (9 / 10) = 63 / 256 := by norm_num
-- First returns P(T = 2n) = u_{2n−2} − u_{2n}: 1/2, 1/8, 1/16, 5/128 at rounds 2, 4, 6, 8.
example : (1 : ℚ) - 1 / 2 = 1 / 2 ∧ (1 : ℚ) / 2 - 3 / 8 = 1 / 8 ∧ (3 : ℚ) / 8 - 5 / 16 = 1 / 16 ∧
    (5 : ℚ) / 16 - 35 / 128 = 5 / 128 := by norm_num
-- No return in 16 rounds: C(16, 8) = 12870 of the 65536 matches, 6435/32768.
example : Nat.choose 16 8 = 12870 ∧ 2 ^ 16 = 65536 ∧ (12870 : ℚ) / 65536 = 6435 / 32768 := by
  norm_num [Nat.choose]
-- Capped mean at cap 10 (N = 5): 2 (1 + 1/2 + 3/8 + 5/16 + 35/128) = 315/64 = 4.921875,
-- equal to the closed form 2 · 9 · u_8, and at least the square-root floor √5 (its square is at least 5).
example : 2 * ((1 : ℚ) + 1 / 2 + 3 / 8 + 5 / 16 + 35 / 128) = 315 / 64 ∧
    (2 : ℚ) * 9 * (35 / 128) = 315 / 64 ∧ (5 : ℚ) ≤ (315 / 64) ^ 2 := by norm_num
-- Tilted coin p = 2/5, q = 3/5: ever one level up 2/3, ever 3 up (2/3)^3 = 8/27 = 0.296296,
-- ever level again 1 − |p − q| = 4/5.
example : (2 / 5 : ℚ) / (3 / 5) = 2 / 3 ∧ ((2 / 5 : ℚ) / (3 / 5)) ^ 3 = 8 / 27 ∧
    1 - |(2 / 5 : ℚ) - 3 / 5| = 4 / 5 := by norm_num [abs_of_neg]

/-- The pictured match: seven losses, six wins, a loss, two wins. -/
def pictured : Fin 16 → Bool := fun i =>
  [false, false, false, false, false, false, false, true, true, true, true, true, true,
   false, true, true].getD i false

-- It falls to −7 at round 7, is not level on rounds 1 to 15, and is level at round 16: T = 16.
example : matchScore pictured 7 = -7 ∧ (∀ k ∈ Icc 1 15, matchScore pictured k ≠ 0) ∧
    matchScore pictured 16 = 0 := by decide

#print axioms fair_walk_hits_every_level_surely_with_infinite_mean_wait
#print axioms walk_arrival_and_return_chances
#print axioms card_never_level_eq_choose
