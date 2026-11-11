-- The integral: a continuous or monotone rate on a closed interval has exactly one number between all its lower and upper sums, that number is its integral, no lower sum passes an upper sum, and the card's tank holds 130 litres.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Data.Real.Archimedean
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Set

/-- A partition of `[a, b]` into `n` slices: the cuts `a = t 0 < t 1 < ... < t n = b`. -/
def IsPartition (a b : ℝ) (n : ℕ) (t : Fin (n + 1) → ℝ) : Prop :=
  StrictMono t ∧ t 0 = a ∧ t (Fin.last n) = b

/-- The lower sum `L(P)`: each slice's lowest rate (the infimum of `f` on the slice) times its width. -/
noncomputable def lowerSum (f : ℝ → ℝ) (n : ℕ) (t : Fin (n + 1) → ℝ) : ℝ :=
  ∑ k : Fin n, sInf (f '' Icc (t k.castSucc) (t k.succ)) * (t k.succ - t k.castSucc)

/-- The upper sum `U(P)`: each slice's highest rate (the supremum of `f` on the slice) times its width. -/
noncomputable def upperSum (f : ℝ → ℝ) (n : ℕ) (t : Fin (n + 1) → ℝ) : ℝ :=
  ∑ k : Fin n, sSup (f '' Icc (t k.castSucc) (t k.succ)) * (t k.succ - t k.castSucc)

/-- The `n` equal slices of `[a, b]`: cut `k` sits at `a + (b - a) k / n`. -/
noncomputable def evenCuts (a b : ℝ) (n : ℕ) (k : Fin (n + 1)) : ℝ :=
  a + (b - a) * (k : ℕ) / n

/-- The card's tank: at minute `t` the pump delivers `3 + 2t` litres per minute. -/
def tankRate (t : ℝ) : ℝ := 3 + 2 * t

/-- Every cut of a partition of `[a, b]` lies in `[a, b]`. -/
theorem partition_cut_mem {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    (i : Fin (n + 1)) : t i ∈ Icc a b := by
  obtain ⟨hm, h0, hl⟩ := ht
  refine ⟨?_, ?_⟩
  · rw [← h0]; exact hm.monotone (Fin.zero_le i)
  · rw [← hl]; exact hm.monotone (Fin.le_last i)

#print axioms partition_cut_mem

/-- A partition's endpoints are in order. -/
theorem partition_le {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t) :
    a ≤ b := by
  have := partition_cut_mem ht 0
  exact this.1.trans this.2

#print axioms partition_le

/-- Each slice of a partition lies inside `[a, b]`. -/
theorem partition_slice_subset {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    (k : Fin n) : Icc (t k.castSucc) (t k.succ) ⊆ Icc a b :=
  Icc_subset_Icc (partition_cut_mem ht _).1 (partition_cut_mem ht _).2

#print axioms partition_slice_subset

/-- Each slice has its left cut below its right cut. -/
theorem partition_slice_le {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    (k : Fin n) : t k.castSucc ≤ t k.succ :=
  ht.1.monotone (Fin.castSucc_le_succ k)

#print axioms partition_slice_le

/-- The integral over `[a, b]` of the step function that equals `c k` on slice `k`
is `∑ c k × width`. -/
theorem step_integral {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    (c : Fin n → ℝ) :
    ∫ x in a..b, (∑ k : Fin n, (Ioc (t k.castSucc) (t k.succ)).indicator (fun _ => c k) x) =
      ∑ k : Fin n, c k * (t k.succ - t k.castSucc) := by
  rw [intervalIntegral.integral_of_le (partition_le ht)]
  rw [MeasureTheory.integral_finsetSum _ (fun k _ =>
    (MeasureTheory.integrableOn_const (C := c k) (by simp)).indicator measurableSet_Ioc)]
  refine Finset.sum_congr rfl (fun k _ => ?_)
  rw [MeasureTheory.integral_indicator measurableSet_Ioc,
    MeasureTheory.Measure.restrict_restrict measurableSet_Ioc,
    MeasureTheory.setIntegral_const]
  have hsub : Ioc (t k.castSucc) (t k.succ) ∩ Ioc a b = Ioc (t k.castSucc) (t k.succ) :=
    inter_eq_left.mpr (Ioc_subset_Ioc (partition_cut_mem ht _).1 (partition_cut_mem ht _).2)
  rw [hsub, MeasureTheory.measureReal_def, Real.volume_Ioc,
    ENNReal.toReal_ofReal (sub_nonneg.mpr (partition_slice_le ht k)), smul_eq_mul, mul_comm]

#print axioms step_integral

/-- The step function is integrable on `[a, b]`. -/
theorem step_integrableOn {a b : ℝ} {n : ℕ} (t : Fin (n + 1) → ℝ) (c : Fin n → ℝ) :
    MeasureTheory.IntegrableOn
      (fun x => ∑ k : Fin n, (Ioc (t k.castSucc) (t k.succ)).indicator (fun _ => c k) x)
      (Ioc a b) := by
  refine MeasureTheory.integrable_finsetSum _ (fun k _ => ?_)
  exact (MeasureTheory.integrableOn_const (C := c k) (by simp)).indicator measurableSet_Ioc

#print axioms step_integrableOn

/-- Every point of `(a, b]` lies in some slice, and there the step function takes
that slice's value. -/
theorem step_eval {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    {x : ℝ} (hx : x ∈ Ioc a b) :
    ∃ k : Fin n, x ∈ Icc (t k.castSucc) (t k.succ) ∧ ∀ c : Fin n → ℝ,
      (∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator (fun _ => c j) x) = c k := by
  have hex : ∃ k : Fin n, x ∈ Ioc (t k.castSucc) (t k.succ) := by
    by_contra hne
    push Not at hne
    have hall : ∀ i : Fin (n + 1), t i < x := by
      intro i
      induction i using Fin.induction with
      | zero => rw [ht.2.1]; exact hx.1
      | succ i ih =>
        by_contra hle
        exact hne i ⟨ih, not_lt.mp hle⟩
    have := hall (Fin.last n)
    rw [ht.2.2] at this
    exact absurd hx.2 (not_le.mpr this)
  obtain ⟨k, hk⟩ := hex
  refine ⟨k, Ioc_subset_Icc_self hk, fun c => ?_⟩
  rw [Finset.sum_eq_single k]
  · exact indicator_of_mem hk _
  · intro j _ hjk
    apply indicator_of_notMem
    intro hj
    rcases lt_or_gt_of_ne hjk with h | h
    · have : t j.succ ≤ t k.castSucc := ht.1.monotone (Fin.succ_le_castSucc_iff.mpr h)
      exact absurd (hj.2.trans this) (not_le.mpr hk.1)
    · have : t k.succ ≤ t j.castSucc := ht.1.monotone (Fin.succ_le_castSucc_iff.mpr h)
      exact absurd (hk.2.trans this) (not_le.mpr hj.1)
  · intro h; exact absurd (Finset.mem_univ k) h

#print axioms step_eval

/-- A rate bounded on `[a, b]` is bounded below on each slice. -/
theorem slice_bddBelow {f : ℝ → ℝ} {a b : ℝ} (hf : ∃ C, ∀ x ∈ Icc a b, |f x| ≤ C)
    {p q : ℝ} (hpq : Icc p q ⊆ Icc a b) : BddBelow (f '' Icc p q) := by
  obtain ⟨C, hC⟩ := hf
  refine ⟨-C, ?_⟩
  rintro _ ⟨y, hy, rfl⟩
  have := hC y (hpq hy)
  linarith [(abs_le.mp this).1]

#print axioms slice_bddBelow

/-- A rate bounded on `[a, b]` is bounded above on each slice. -/
theorem slice_bddAbove {f : ℝ → ℝ} {a b : ℝ} (hf : ∃ C, ∀ x ∈ Icc a b, |f x| ≤ C)
    {p q : ℝ} (hpq : Icc p q ⊆ Icc a b) : BddAbove (f '' Icc p q) := by
  obtain ⟨C, hC⟩ := hf
  refine ⟨C, ?_⟩
  rintro _ ⟨y, hy, rfl⟩
  have := hC y (hpq hy)
  linarith [(abs_le.mp this).2]

#print axioms slice_bddAbove

/-- The lower sum is the integral of the lower step function. -/
theorem lowerSum_eq_step (f : ℝ → ℝ) {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ}
    (ht : IsPartition a b n t) :
    lowerSum f n t = ∫ x in a..b, (∑ k : Fin n, (Ioc (t k.castSucc) (t k.succ)).indicator
      (fun _ => sInf (f '' Icc (t k.castSucc) (t k.succ))) x) := by
  rw [step_integral ht]; rfl

#print axioms lowerSum_eq_step

/-- The upper sum is the integral of the upper step function. -/
theorem upperSum_eq_step (f : ℝ → ℝ) {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ}
    (ht : IsPartition a b n t) :
    upperSum f n t = ∫ x in a..b, (∑ k : Fin n, (Ioc (t k.castSucc) (t k.succ)).indicator
      (fun _ => sSup (f '' Icc (t k.castSucc) (t k.succ))) x) := by
  rw [step_integral ht]; rfl

#print axioms upperSum_eq_step

/-- For a bounded, integrable rate, every lower sum is at most the integral. -/
theorem lowerSum_le_integral {f : ℝ → ℝ} {a b : ℝ} (hf : ∃ C, ∀ x ∈ Icc a b, |f x| ≤ C)
    (hi : IntervalIntegrable f MeasureTheory.volume a b) {n : ℕ} {t : Fin (n + 1) → ℝ}
    (ht : IsPartition a b n t) : lowerSum f n t ≤ ∫ x in a..b, f x := by
  have hab := partition_le ht
  rw [lowerSum_eq_step f ht, intervalIntegral.integral_of_le hab,
    intervalIntegral.integral_of_le hab]
  refine MeasureTheory.setIntegral_mono_on (step_integrableOn t _)
    ((intervalIntegrable_iff_integrableOn_Ioc_of_le hab).mp hi) measurableSet_Ioc
    (fun x hx => ?_)
  obtain ⟨k, hk, hc⟩ := step_eval ht hx
  rw [hc]
  exact csInf_le (slice_bddBelow hf (partition_slice_subset ht k)) (mem_image_of_mem f hk)

#print axioms lowerSum_le_integral

/-- For a bounded, integrable rate, the integral is at most every upper sum. -/
theorem integral_le_upperSum {f : ℝ → ℝ} {a b : ℝ} (hf : ∃ C, ∀ x ∈ Icc a b, |f x| ≤ C)
    (hi : IntervalIntegrable f MeasureTheory.volume a b) {n : ℕ} {t : Fin (n + 1) → ℝ}
    (ht : IsPartition a b n t) : ∫ x in a..b, f x ≤ upperSum f n t := by
  have hab := partition_le ht
  rw [upperSum_eq_step f ht, intervalIntegral.integral_of_le hab,
    intervalIntegral.integral_of_le hab]
  refine MeasureTheory.setIntegral_mono_on
    ((intervalIntegrable_iff_integrableOn_Ioc_of_le hab).mp hi) (step_integrableOn t _)
    measurableSet_Ioc (fun x hx => ?_)
  obtain ⟨k, hk, hc⟩ := step_eval ht hx
  rw [hc]
  exact le_csSup (slice_bddAbove hf (partition_slice_subset ht k)) (mem_image_of_mem f hk)

#print axioms integral_le_upperSum

/-- The even cuts form a partition of `[a, b]`. -/
theorem evenCuts_partition {a b : ℝ} (hab : a < b) {n : ℕ} (hn : 0 < n) :
    IsPartition a b n (evenCuts a b n) := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  refine ⟨?_, ?_, ?_⟩
  · intro i j hij
    have hij' : ((i : ℕ) : ℝ) < ((j : ℕ) : ℝ) := by exact_mod_cast hij
    have hba : 0 < b - a := sub_pos.mpr hab
    unfold evenCuts
    have := mul_lt_mul_of_pos_left hij' hba
    have := div_lt_div_of_pos_right this hn'
    linarith
  · simp [evenCuts]
  · simp only [evenCuts, Fin.val_last]
    field_simp
    ring

#print axioms evenCuts_partition

/-- Upper sum minus lower sum is the sum of the slice gaps times the widths. -/
theorem upper_sub_lower (f : ℝ → ℝ) (n : ℕ) (t : Fin (n + 1) → ℝ) :
    upperSum f n t - lowerSum f n t =
      ∑ k : Fin n, (sSup (f '' Icc (t k.castSucc) (t k.succ)) -
        sInf (f '' Icc (t k.castSucc) (t k.succ))) * (t k.succ - t k.castSucc) := by
  unfold upperSum lowerSum
  rw [← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl (fun k _ => ?_)
  ring

#print axioms upper_sub_lower

/-- If the rate never rises by more than `e` within a slice, the slice's highest and lowest
rates differ by at most `e`. -/
theorem slice_gap_le {f : ℝ → ℝ} {p q e : ℝ} (hpq : p ≤ q) (h : ∀ x ∈ Icc p q, ∀ y ∈ Icc p q, f y - f x ≤ e) :
    sSup (f '' Icc p q) - sInf (f '' Icc p q) ≤ e := by
  have hne : (f '' Icc p q).Nonempty := (nonempty_Icc.mpr hpq).image f
  have : sSup (f '' Icc p q) ≤ sInf (f '' Icc p q) + e := by
    refine csSup_le hne ?_
    rintro _ ⟨y, hy, rfl⟩
    have : f y - e ≤ sInf (f '' Icc p q) := by
      refine le_csInf hne ?_
      rintro _ ⟨x, hx, rfl⟩
      linarith [h x hx y hy]
    linarith
  linarith

#print axioms slice_gap_le

/-- For the even cuts, if slice `k` has rise at most `e k`, then upper minus lower sum is at most
`(b - a)/n × ∑ e k`. -/
theorem even_gap_le {f : ℝ → ℝ} {a b : ℝ} (hab : a < b) {n : ℕ} (hn : 0 < n)
    (e : ℕ → ℝ)
    (he : ∀ k : Fin n, ∀ x ∈ Icc (evenCuts a b n k.castSucc) (evenCuts a b n k.succ),
      ∀ y ∈ Icc (evenCuts a b n k.castSucc) (evenCuts a b n k.succ), f y - f x ≤ e k) :
    upperSum f n (evenCuts a b n) - lowerSum f n (evenCuts a b n) ≤
      (b - a) / n * ∑ i ∈ Finset.range n, e i := by
  have ht := evenCuts_partition hab hn
  have hw : ∀ k : Fin n, evenCuts a b n k.succ - evenCuts a b n k.castSucc = (b - a) / n := by
    intro k
    simp only [evenCuts, Fin.val_succ, Fin.val_castSucc]
    push_cast
    ring
  rw [upper_sub_lower, Finset.mul_sum, ← Fin.sum_univ_eq_sum_range]
  refine Finset.sum_le_sum (fun k _ => ?_)
  rw [hw, mul_comm]
  have hw0 : 0 ≤ (b - a) / n := div_nonneg (sub_nonneg.mpr hab.le) (Nat.cast_nonneg n)
  exact mul_le_mul_of_nonneg_left (slice_gap_le (partition_slice_le ht k) (he k)) hw0

#print axioms even_gap_le

/-- Any fixed amount divided by a large enough count is small. -/
theorem exists_nat_div_le (K : ℝ) {ε : ℝ} (hε : 0 < ε) : ∃ n : ℕ, 0 < n ∧ K / n ≤ ε := by
  obtain ⟨N, hN⟩ := exists_nat_gt (K / ε)
  refine ⟨N + 1, Nat.succ_pos N, ?_⟩
  have hN1 : (0 : ℝ) < ((N + 1 : ℕ) : ℝ) := by positivity
  rw [div_le_iff₀ hN1]
  have := (div_lt_iff₀ hε).mp hN
  push_cast
  nlinarith

#print axioms exists_nat_div_le

/-- Two numbers that both lie between every lower and upper sum are equal, once some
partition makes the upper and lower sums as close as we like. -/
theorem eq_of_small_gap {f : ℝ → ℝ} {a b I J : ℝ}
    (hgap : ∀ ε > 0, ∃ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t ∧
      upperSum f n t - lowerSum f n t ≤ ε)
    (hI : ∀ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t →
      lowerSum f n t ≤ I ∧ I ≤ upperSum f n t)
    (hJ : ∀ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t →
      lowerSum f n t ≤ J ∧ J ≤ upperSum f n t) : I = J := by
  apply le_antisymm
  · refine le_of_forall_pos_le_add (fun ε hε => ?_)
    obtain ⟨n, t, ht, hg⟩ := hgap ε hε
    linarith [(hI n t ht).2, (hJ n t ht).1]
  · refine le_of_forall_pos_le_add (fun ε hε => ?_)
    obtain ⟨n, t, ht, hg⟩ := hgap ε hε
    linarith [(hJ n t ht).2, (hI n t ht).1]

#print axioms eq_of_small_gap

/-- `0 + 1 + ... + (n - 1) = n(n - 1)/2` in the reals. -/
theorem sum_range_cast (n : ℕ) : ∑ i ∈ Finset.range n, (i : ℝ) = n * (n - 1) / 2 := by
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_range_succ, ih]; push_cast; ring

#print axioms sum_range_cast

/-- The integral exists for continuous and for monotone rates: if the rate `f` is continuous
on the closed interval `[a, b]`, or only rising there, or only falling there (jumps allowed),
then exactly one number lies above every lower sum and below every upper sum, and that
number is the integral `∫ f(t) dt` from `a` to `b`. -/
theorem continuous_or_monotone_rate_has_integral (f : ℝ → ℝ) (a b : ℝ) (hab : a < b)
    (hf : ContinuousOn f (Icc a b) ∨ MonotoneOn f (Icc a b) ∨ AntitoneOn f (Icc a b))
    (I : ℝ) :
    (∀ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t →
        lowerSum f n t ≤ I ∧ I ≤ upperSum f n t) ↔
      I = ∫ x in a..b, f x := by
  have huIcc : uIcc a b = Icc a b := uIcc_of_le hab.le
  have hba : 0 < b - a := sub_pos.mpr hab
  -- the rate is bounded on `[a, b]`
  have hbound : ∃ C, ∀ x ∈ Icc a b, |f x| ≤ C := by
    rcases hf with h | h | h
    · obtain ⟨C, hC⟩ := isCompact_Icc.exists_bound_of_continuousOn h
      exact ⟨C, fun x hx => by simpa [Real.norm_eq_abs] using hC x hx⟩
    · refine ⟨|f a| + |f b|, fun x hx => abs_le.mpr ⟨?_, ?_⟩⟩
      · have := h (left_mem_Icc.mpr hab.le) hx hx.1
        linarith [neg_abs_le (f a), abs_nonneg (f b)]
      · have := h hx (right_mem_Icc.mpr hab.le) hx.2
        linarith [le_abs_self (f b), abs_nonneg (f a)]
    · refine ⟨|f a| + |f b|, fun x hx => abs_le.mpr ⟨?_, ?_⟩⟩
      · have := h hx (right_mem_Icc.mpr hab.le) hx.2
        linarith [neg_abs_le (f b), abs_nonneg (f a)]
      · have := h (left_mem_Icc.mpr hab.le) hx hx.1
        linarith [le_abs_self (f a), abs_nonneg (f b)]
  -- the rate is integrable on `[a, b]`
  have hint : IntervalIntegrable f MeasureTheory.volume a b := by
    rcases hf with h | h | h
    · exact ContinuousOn.intervalIntegrable (by rwa [huIcc])
    · exact MonotoneOn.intervalIntegrable (by rwa [huIcc])
    · exact AntitoneOn.intervalIntegrable (by rwa [huIcc])
  have hJ : ∀ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t →
      lowerSum f n t ≤ ∫ x in a..b, f x ∧ ∫ x in a..b, f x ≤ upperSum f n t :=
    fun n t ht => ⟨lowerSum_le_integral hbound hint ht, integral_le_upperSum hbound hint ht⟩
  -- the even cuts make the gap between upper and lower sums as small as we like
  have hcut : ∀ {n : ℕ} (k : Fin n) (hn : 0 < n), ∀ x ∈ Icc (evenCuts a b n k.castSucc)
      (evenCuts a b n k.succ), x ∈ Icc a b :=
    fun k hn x hx => partition_slice_subset (evenCuts_partition hab hn) k hx
  have hgap : ∀ ε > 0, ∃ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t ∧
      upperSum f n t - lowerSum f n t ≤ ε := by
    intro ε hε
    rcases hf with h | h | h
    · obtain ⟨δ, hδ, hU⟩ := Metric.uniformContinuousOn_iff.mp
        (isCompact_Icc.uniformContinuousOn_of_continuous h) (ε / (b - a)) (div_pos hε hba)
      obtain ⟨n, hn, hnδ⟩ := exists_nat_div_le (b - a) (half_pos hδ)
      refine ⟨n, evenCuts a b n, evenCuts_partition hab hn, ?_⟩
      have hn' : (0 : ℝ) < n := by exact_mod_cast hn
      refine (even_gap_le hab hn (fun _ => ε / (b - a)) ?_).trans (le_of_eq ?_)
      · intro k x hx y hy
        have hw : evenCuts a b n k.succ - evenCuts a b n k.castSucc = (b - a) / n := by
          simp only [evenCuts, Fin.val_succ, Fin.val_castSucc]
          push_cast
          ring
        have hd : dist y x < δ := by
          rw [Real.dist_eq, abs_lt]
          constructor <;> linarith [hx.1, hx.2, hy.1, hy.2]
        have := hU y (hcut k hn y hy) x (hcut k hn x hx) hd
        rw [Real.dist_eq] at this
        linarith [le_abs_self (f y - f x)]
      · simp only [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
        field_simp
    · obtain ⟨n, hn, hnε⟩ := exists_nat_div_le ((b - a) * (f b - f a)) hε
      refine ⟨n, evenCuts a b n, evenCuts_partition hab hn, ?_⟩
      have hn' : (0 : ℝ) < n := by exact_mod_cast hn
      refine (even_gap_le hab hn
        (fun i => f (a + (b - a) * ((i : ℝ) + 1) / n) - f (a + (b - a) * i / n)) ?_).trans ?_
      · intro k x hx y hy
        have hxab := hcut k hn x hx
        have hyab := hcut k hn y hy
        have h1 := h (hcut k hn _ (left_mem_Icc.mpr (hx.1.trans hx.2))) hxab hx.1
        have h2 := h hyab (hcut k hn _ (right_mem_Icc.mpr (hx.1.trans hx.2))) hy.2
        simp only [evenCuts, Fin.val_succ, Fin.val_castSucc] at h1 h2
        push_cast at h1 h2 ⊢
        linarith
      · have hs := Finset.sum_range_sub (fun i : ℕ => f (a + (b - a) * (i : ℝ) / n)) n
        push_cast at hs
        rw [hs]
        have e1 : a + (b - a) * ((n : ℕ) : ℝ) / n = b := by field_simp; ring
        simp only [mul_zero, zero_div, add_zero]
        rw [e1]
        calc (b - a) / n * (f b - f a) = (b - a) * (f b - f a) / n := by ring
          _ ≤ ε := hnε
    · obtain ⟨n, hn, hnε⟩ := exists_nat_div_le ((b - a) * (f a - f b)) hε
      refine ⟨n, evenCuts a b n, evenCuts_partition hab hn, ?_⟩
      have hn' : (0 : ℝ) < n := by exact_mod_cast hn
      refine (even_gap_le hab hn
        (fun i => f (a + (b - a) * i / n) - f (a + (b - a) * ((i : ℝ) + 1) / n)) ?_).trans ?_
      · intro k x hx y hy
        have hxab := hcut k hn x hx
        have hyab := hcut k hn y hy
        have h1 := h hxab (hcut k hn _ (right_mem_Icc.mpr (hx.1.trans hx.2))) hx.2
        have h2 := h (hcut k hn _ (left_mem_Icc.mpr (hx.1.trans hx.2))) hyab hy.1
        simp only [evenCuts, Fin.val_succ, Fin.val_castSucc] at h1 h2
        push_cast at h1 h2 ⊢
        linarith
      · have hs := Finset.sum_range_sub (fun i : ℕ => f (a + (b - a) * (i : ℝ) / n)) n
        rw [show ∑ i ∈ Finset.range n,
            (f (a + (b - a) * (i : ℝ) / n) - f (a + (b - a) * ((i : ℝ) + 1) / n)) =
            -∑ i ∈ Finset.range n, (f (a + (b - a) * ((i + 1 : ℕ) : ℝ) / n) -
              f (a + (b - a) * (i : ℝ) / n)) by
          rw [← Finset.sum_neg_distrib]
          refine Finset.sum_congr rfl (fun i _ => ?_)
          push_cast
          ring, hs]
        have e1 : a + (b - a) * ((n : ℕ) : ℝ) / n = b := by field_simp; ring
        simp only [Nat.cast_zero, mul_zero, zero_div, add_zero]
        rw [e1]
        calc (b - a) / n * -(f b - f a) = (b - a) * (f a - f b) / n := by ring
          _ ≤ ε := hnε
  constructor
  · intro hI
    exact eq_of_small_gap hgap hI hJ
  · rintro rfl
    exact hJ

/-- Step 0: for a bounded rate on `[a, b]`, a lower total can never pass an upper total,
even when the two come from different slicings. -/
theorem lower_sum_le_upper_sum (f : ℝ → ℝ) (a b : ℝ)
    (hf : ∃ C, ∀ x ∈ Icc a b, |f x| ≤ C)
    (n m : ℕ) (t : Fin (n + 1) → ℝ) (s : Fin (m + 1) → ℝ)
    (ht : IsPartition a b n t) (hs : IsPartition a b m s) :
    lowerSum f n t ≤ upperSum f m s := by
  have hab := partition_le ht
  rw [lowerSum_eq_step f ht, upperSum_eq_step f hs, intervalIntegral.integral_of_le hab,
    intervalIntegral.integral_of_le hab]
  refine MeasureTheory.setIntegral_mono_on (step_integrableOn t _) (step_integrableOn s _)
    measurableSet_Ioc (fun x hx => ?_)
  obtain ⟨k, hk, hc⟩ := step_eval ht hx
  obtain ⟨j, hj, hd⟩ := step_eval hs hx
  rw [hc, hd]
  exact (csInf_le (slice_bddBelow hf (partition_slice_subset ht k)) (mem_image_of_mem f hk)).trans
    (le_csSup (slice_bddAbove hf (partition_slice_subset hs j)) (mem_image_of_mem f hj))

/-- Step 5: cut the tank's 10 minutes into `n` equal slices; the lower sum is
`130 - 100/n` litres and the upper sum is `130 + 100/n` litres, so both close on 130. -/
theorem tank_sums_close_on_130 (n : ℕ) (hn : 0 < n) :
    lowerSum tankRate n (evenCuts 0 10 n) = 130 - 100 / n ∧
      upperSum tankRate n (evenCuts 0 10 n) = 130 + 100 / n := by
  have hmono : Monotone tankRate := fun x y h => by unfold tankRate; linarith
  have ht := evenCuts_partition (by norm_num : (0 : ℝ) < 10) hn
  have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  have hsum := sum_range_cast n
  constructor
  · unfold lowerSum
    simp_rw [(hmono.monotoneOn _).sInf_image_Icc (partition_slice_le ht _)]
    simp only [tankRate, evenCuts, Fin.val_succ, Fin.val_castSucc]
    rw [Fin.sum_univ_eq_sum_range (fun i : ℕ => (3 + 2 * (0 + (10 - 0) * (i : ℝ) / n)) *
      (0 + (10 - 0) * ((i + 1 : ℕ) : ℝ) / n - (0 + (10 - 0) * (i : ℝ) / n))) n]
    rw [show ∑ i ∈ Finset.range n, (3 + 2 * (0 + (10 - 0) * (i : ℝ) / n)) *
        (0 + (10 - 0) * ((i + 1 : ℕ) : ℝ) / n - (0 + (10 - 0) * (i : ℝ) / n)) =
        ∑ i ∈ Finset.range n, (30 / n + 200 / n ^ 2 * (i : ℝ)) by
      refine Finset.sum_congr rfl (fun i _ => ?_)
      push_cast
      field_simp
      ring]
    rw [Finset.sum_add_distrib, ← Finset.mul_sum, hsum]
    simp only [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    field_simp
    ring
  · unfold upperSum
    simp_rw [(hmono.monotoneOn _).sSup_image_Icc (partition_slice_le ht _)]
    simp only [tankRate, evenCuts, Fin.val_succ, Fin.val_castSucc]
    rw [Fin.sum_univ_eq_sum_range (fun i : ℕ => (3 + 2 * (0 + (10 - 0) * ((i + 1 : ℕ) : ℝ) / n)) *
      (0 + (10 - 0) * ((i + 1 : ℕ) : ℝ) / n - (0 + (10 - 0) * (i : ℝ) / n))) n]
    rw [show ∑ i ∈ Finset.range n, (3 + 2 * (0 + (10 - 0) * ((i + 1 : ℕ) : ℝ) / n)) *
        (0 + (10 - 0) * ((i + 1 : ℕ) : ℝ) / n - (0 + (10 - 0) * (i : ℝ) / n)) =
        ∑ i ∈ Finset.range n, ((30 / n + 200 / n ^ 2) + 200 / n ^ 2 * (i : ℝ)) by
      refine Finset.sum_congr rfl (fun i _ => ?_)
      push_cast
      field_simp
      ring]
    rw [Finset.sum_add_distrib, ← Finset.mul_sum, hsum]
    simp only [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    field_simp
    ring

-- Worked numbers, by hand.
-- 5 slices of 2 minutes: the rates at cuts 0, 2, 4, 6, 8, 10 are 3, 7, 11, 15, 19, 23.
example : [0, 2, 4, 6, 8, 10].map (fun t : ℕ => 3 + 2 * t) = [3, 7, 11, 15, 19, 23] := by decide
-- Lower sum 2 × (3 + 7 + 11 + 15 + 19) = 110; upper sum 2 × (7 + 11 + 15 + 19 + 23) = 150; gap 200 / 5 = 40.
example : 2 * (3 + 7 + 11 + 15 + 19) = 110 ∧ 2 * (7 + 11 + 15 + 19 + 23) = 150 ∧ 200 / 5 = 40 := by
  decide
-- 100 slices: 130 - 100/100 = 129 and 130 + 100/100 = 131.
example : (130 : ℚ) - 100 / 100 = 129 ∧ (130 : ℚ) + 100 / 100 = 131 := by norm_num
-- The chart: lower sums 130 - 100/n for n = 1, 2, 4, 5, 10, 20, 50, 100.
example : [1, 2, 4, 5, 10, 20, 50, 100].map (fun n : ℚ => 130 - 100 / n)
    = [30, 80, 105, 110, 120, 125, 128, 129] := by norm_num
-- The chart: upper sums 130 + 100/n.
example : [1, 2, 4, 5, 10, 20, 50, 100].map (fun n : ℚ => 130 + 100 / n)
    = [230, 180, 155, 150, 140, 135, 132, 131] := by norm_num
-- Step 1: cuts 0, 5, 10 give lower 5 × 3 + 5 × 13 = 80 and upper 5 × 13 + 5 × 23 = 180;
-- an extra cut at 2 gives 2 × 3 + 3 × 7 + 5 × 13 = 92 and 2 × 7 + 3 × 13 + 5 × 23 = 168.
example : 5 * 3 + 5 * 13 = 80 ∧ 5 * 13 + 5 * 23 = 180 ∧
    2 * 3 + 3 * 7 + 5 * 13 = 92 ∧ 2 * 7 + 3 * 13 + 5 * 23 = 168 := by decide
-- Step 3: the tank's gap is 10/n × (23 - 3) = 200/n; the valve's is 10/n × (8 - 3) = 50/n.
example : 10 * (23 - 3) = 200 ∧ 10 * (8 - 3) = 50 := by decide
-- Step 5: 0 + 1 + ... + (n - 1) = n(n - 1)/2, checked for n = 5 and n = 100.
example : (Finset.range 5).sum id = 5 * 4 / 2 ∧ (Finset.range 100).sum id = 100 * 99 / 2 := by
  decide
-- Geometry: a 3-by-10 rectangle plus a triangle of base 10 and height 20 holds 30 + 100 = 130.
example : 3 * 10 + 10 * 20 / 2 = 130 := by decide
-- The valve: 3 litres per minute for 4 minutes, then 8 for 6 minutes, traps 3 × 4 + 8 × 6 = 60.
example : 3 * 4 + 8 * 6 = 60 := by decide
-- Mistake 2: the 20 right-end rates 3 + 2(k/2) = 3 + k, k = 1 to 20, add to 270; times the
-- half-minute widths they give the upper sum, 135 litres.
example : (Finset.range 20).sum (fun k => 3 + (k + 1)) = 270 ∧ 270 / 2 = 135 := by decide

#print axioms continuous_or_monotone_rate_has_integral
#print axioms lower_sum_le_upper_sum
#print axioms tank_sums_close_on_130
