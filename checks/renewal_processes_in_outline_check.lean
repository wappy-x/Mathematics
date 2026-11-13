-- Renewal processes: for independent, identically distributed gaps with a finite positive mean, arrivals come at one per mean gap in the long run, and the time-averaged wait for the next arrival is the mean square gap over twice the mean gap.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Notation
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Data.Set.Card
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory ProbabilityTheory Filter Topology


variable {Ω : Type*} [MeasurableSpace Ω]

/-- `busTime X n ω` is $S_n$, the time of bus `n`: the sum of the first `n` gaps.
Gap `X i` is the time between bus `i` and bus `i + 1`, with bus 0 leaving at time 0. -/
noncomputable def busTime (X : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) : ℝ :=
  ∑ i ∈ Finset.range n, X i ω

/-- `arrivalCount X t ω` is $N(t)$: the number of buses `n ≥ 1` with $S_n \le t$. -/
noncomputable def arrivalCount (X : ℕ → Ω → ℝ) (t : ℝ) (ω : Ω) : ℕ :=
  Set.ncard {n : ℕ | 1 ≤ n ∧ busTime X n ω ≤ t}

/-- `wait X s ω` is the wait of a passenger arriving at time `s`: the time of the first bus
after `s`, bus $N(s)+1$, minus `s`. -/
noncomputable def wait (X : ℕ → Ω → ℝ) (s : ℝ) (ω : Ω) : ℝ :=
  busTime X (arrivalCount X s ω + 1) ω - s

lemma rp_busTime_zero (X : ℕ → Ω → ℝ) (ω : Ω) : busTime X 0 ω = 0 := by simp [busTime]

lemma rp_busTime_succ (X : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) :
    busTime X (n + 1) ω = busTime X n ω + X n ω := by
  simp [busTime, Finset.sum_range_succ]

lemma rp_busTime_mono {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω) :
    Monotone (fun n => busTime X n ω) := by
  intro a b hab
  exact Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_mono hab) (fun i _ _ => h0 i)

lemma rp_le_iff {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) (n : ℕ) :
    busTime X n ω ≤ t ↔ n ≤ arrivalCount X t ω := by
  classical
  have hex : ∃ m, t < busTime X m ω := (hunb.eventually_gt_atTop t).exists
  set K := Nat.find hex with hK
  have hS : ∀ m, busTime X m ω ≤ t ↔ m < K := by
    intro m
    constructor
    · intro hm
      by_contra hc
      push Not at hc
      have h1 := rp_busTime_mono h0 hc
      have h2 := Nat.find_spec hex
      simp only at h1
      linarith
    · intro hm
      exact not_lt.1 (Nat.find_min hex hm)
  have hKpos : 0 < K := (hS 0).1 (by simp [rp_busTime_zero, ht])
  have hset : {m : ℕ | 1 ≤ m ∧ busTime X m ω ≤ t} = ((Finset.Ico 1 K : Finset ℕ) : Set ℕ) := by
    ext m; simp [hS m]
  have hN : arrivalCount X t ω = K - 1 := by
    unfold arrivalCount; rw [hset, Set.ncard_coe_finset]; simp
  rw [hS n, hN]; omega

lemma rp_le_t {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    busTime X (arrivalCount X t ω) ω ≤ t :=
  (rp_le_iff h0 hunb ht _).2 le_rfl

lemma rp_lt_next {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    t < busTime X (arrivalCount X t ω + 1) ω := by
  by_contra h
  push Not at h
  have := (rp_le_iff h0 hunb ht _).1 h
  omega

lemma rp_count_mono {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {s t : ℝ} (hs : 0 ≤ s) (hst : s ≤ t) :
    arrivalCount X s ω ≤ arrivalCount X t ω :=
  (rp_le_iff h0 hunb (hs.trans hst) _).1 ((rp_le_t h0 hunb hs).trans hst)

lemma rp_count_tendsto {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) :
    Tendsto (fun t : ℝ => arrivalCount X t ω) atTop atTop := by
  rw [tendsto_atTop]
  intro n
  filter_upwards [eventually_ge_atTop (max 0 (busTime X n ω))] with t ht
  exact (rp_le_iff h0 hunb ((le_max_left _ _).trans ht) n).1 ((le_max_right _ _).trans ht)

lemma rp_ae_good (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0]) :
    ∀ᵐ ω ∂P, (∀ i, 0 ≤ X i ω) ∧ Tendsto (fun n => busTime X n ω) atTop atTop ∧
      Tendsto (fun n : ℕ => busTime X n ω / n) atTop (𝓝 P[X 0]) := by
  have hslln := strong_law_ae_real X hint (fun i j hij => hindep.indepFun hij) hident
  filter_upwards [ae_all_iff.2 hnonneg, hslln] with ω h0 hl
  refine ⟨h0, ?_, hl⟩
  have h2 : Tendsto (fun n : ℕ => busTime X n ω / n * (n : ℝ)) atTop atTop :=
    Tendsto.pos_mul_atTop hpos hl tendsto_natCast_atTop_atTop
  refine h2.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have : (n : ℝ) ≠ 0 := by positivity
  field_simp

lemma rp_ratio_tendsto {X : ℕ → Ω → ℝ} {ω : Ω} {μ : ℝ} (hμ : 0 < μ) (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop)
    (hl : Tendsto (fun n : ℕ => busTime X n ω / n) atTop (𝓝 μ)) :
    Tendsto (fun t : ℝ => (arrivalCount X t ω : ℝ) / t) atTop (𝓝 (1 / μ)) := by
  have hN := rp_count_tendsto h0 hunb
  -- a(n+1) * ((n+1)/n) → μ
  have hl1 : Tendsto (fun n : ℕ => busTime X (n + 1) ω / ((n + 1 : ℕ) : ℝ)) atTop (𝓝 μ) :=
    (tendsto_add_atTop_iff_nat 1).2 hl
  have hr : Tendsto (fun n : ℕ => ((n + 1 : ℕ) : ℝ) / n) atTop (𝓝 1) := by
    have : Tendsto (fun n : ℕ => (1 : ℝ) + 1 / n) atTop (𝓝 (1 + 0)) :=
      tendsto_const_nhds.add tendsto_one_div_atTop_nhds_zero_nat
    rw [add_zero] at this
    refine this.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    have : (n : ℝ) ≠ 0 := by positivity
    push_cast
    field_simp
  have hb : Tendsto (fun n : ℕ => busTime X (n + 1) ω / ((n + 1 : ℕ) : ℝ) * (((n + 1 : ℕ) : ℝ) / n))
      atTop (𝓝 μ) := by simpa using hl1.mul hr
  have hlow := hl.comp hN
  have hup := hb.comp hN
  have hsq : Tendsto (fun t : ℝ => t / (arrivalCount X t ω : ℝ)) atTop (𝓝 μ) := by
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlow hup ?_ ?_
    · filter_upwards [eventually_ge_atTop 0, hN.eventually_ge_atTop 1] with t ht hn
      have hpos : (0 : ℝ) < arrivalCount X t ω := by exact_mod_cast hn
      simp only [Function.comp]
      exact div_le_div_of_nonneg_right (rp_le_t h0 hunb ht) hpos.le
    · filter_upwards [eventually_ge_atTop 0, hN.eventually_ge_atTop 1] with t ht hn
      have hpos : (0 : ℝ) < arrivalCount X t ω := by exact_mod_cast hn
      simp only [Function.comp]
      have hn1 : ((arrivalCount X t ω + 1 : ℕ) : ℝ) ≠ 0 := by positivity
      rw [div_mul_div_cancel₀ hn1]
      exact div_le_div_of_nonneg_right (rp_lt_next h0 hunb ht).le hpos.le
  have := hsq.inv₀ hμ.ne'
  simpa [inv_div, one_div] using this

lemma rp_wait_eq {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {k : ℕ} {s : ℝ}
    (hs1 : busTime X k ω ≤ s) (hs2 : s < busTime X (k + 1) ω) (hs0 : 0 ≤ s) :
    wait X s ω = busTime X (k + 1) ω - s := by
  have hk : arrivalCount X s ω = k := by
    apply le_antisymm
    · by_contra h
      push Not at h
      have := (rp_le_iff h0 hunb hs0 (k + 1)).2 h
      linarith
    · exact (rp_le_iff h0 hunb hs0 k).1 hs1
  simp [wait, hk]

lemma rp_wait_nonneg {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {s : ℝ} (hs : 0 ≤ s) :
    0 ≤ wait X s ω := by
  unfold wait
  linarith [rp_lt_next h0 hunb hs]

lemma rp_busTime_nonneg {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω) (n : ℕ) :
    0 ≤ busTime X n ω := by
  simpa [rp_busTime_zero] using rp_busTime_mono h0 (Nat.zero_le n)

lemma rp_wait_ii {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {a b : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b) :
    IntervalIntegrable (fun s => wait X s ω) volume a b := by
  have hm : MonotoneOn (fun s => busTime X (arrivalCount X s ω + 1) ω) (Set.uIcc a b) := by
    intro x hx y hy hxy
    have hx0 : 0 ≤ x := by
      rcases Set.mem_uIcc.1 hx with h | h
      · linarith [h.1]
      · linarith [h.1]
    exact rp_busTime_mono h0 (Nat.succ_le_succ (rp_count_mono h0 hunb hx0 hxy))
  exact hm.intervalIntegrable.sub (continuous_id.intervalIntegrable a b)

lemma rp_piece {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) (k : ℕ) :
    ∫ s in busTime X k ω..busTime X (k + 1) ω, wait X s ω = X k ω ^ 2 / 2 := by
  have hab : busTime X k ω ≤ busTime X (k + 1) ω := rp_busTime_mono h0 (Nat.le_succ k)
  have hk0 : 0 ≤ busTime X k ω := rp_busTime_nonneg h0 k
  have heq : ∫ s in busTime X k ω..busTime X (k + 1) ω, wait X s ω =
      ∫ s in busTime X k ω..busTime X (k + 1) ω, (busTime X (k + 1) ω - s) := by
    rw [intervalIntegral.integral_of_le hab, intervalIntegral.integral_of_le hab,
      integral_Ioc_eq_integral_Ioo, integral_Ioc_eq_integral_Ioo]
    refine setIntegral_congr_fun measurableSet_Ioo (fun s hs => ?_)
    exact rp_wait_eq h0 hunb hs.1.le hs.2 (hk0.trans hs.1.le)
  rw [heq, intervalIntegral.integral_sub (f := fun _ : ℝ => busTime X (k + 1) ω)
    (g := fun s : ℝ => s) intervalIntegrable_const
    (continuous_id'.intervalIntegrable _ _), intervalIntegral.integral_const, integral_id,
    rp_busTime_succ]
  simp only [smul_eq_mul]
  ring

lemma rp_int_busTime {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) (n : ℕ) :
    ∫ s in (0 : ℝ)..busTime X n ω, wait X s ω = (∑ k ∈ Finset.range n, X k ω ^ 2) / 2 := by
  induction n with
  | zero => simp [rp_busTime_zero]
  | succ n ih =>
    rw [← intervalIntegral.integral_add_adjacent_intervals
      (rp_wait_ii h0 hunb le_rfl (rp_busTime_nonneg h0 n))
      (rp_wait_ii h0 hunb (rp_busTime_nonneg h0 n) (rp_busTime_nonneg h0 (n + 1))), ih,
      rp_piece h0 hunb, Finset.sum_range_succ]
    ring

lemma rp_int_bounds {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    (∑ k ∈ Finset.range (arrivalCount X t ω), X k ω ^ 2) / 2 ≤ ∫ s in (0 : ℝ)..t, wait X s ω ∧
    ∫ s in (0 : ℝ)..t, wait X s ω ≤
      (∑ k ∈ Finset.range (arrivalCount X t ω + 1), X k ω ^ 2) / 2 := by
  constructor
  · rw [← rp_int_busTime h0 hunb]
    refine intervalIntegral.integral_mono_interval le_rfl (rp_busTime_nonneg h0 _)
      (rp_le_t h0 hunb ht) ?_ (rp_wait_ii h0 hunb le_rfl ht)
    exact (ae_restrict_iff' measurableSet_Ioc).2
      (Eventually.of_forall fun s hs => rp_wait_nonneg h0 hunb hs.1.le)
  · rw [← rp_int_busTime h0 hunb]
    refine intervalIntegral.integral_mono_interval le_rfl ht (rp_lt_next h0 hunb ht).le ?_
      (rp_wait_ii h0 hunb le_rfl (rp_busTime_nonneg h0 _))
    exact (ae_restrict_iff' measurableSet_Ioc).2
      (Eventually.of_forall fun s hs => rp_wait_nonneg h0 hunb hs.1.le)

lemma rp_wait_tendsto {X : ℕ → Ω → ℝ} {ω : Ω} {μ m2 : ℝ} (hμ : 0 < μ) (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop)
    (hl : Tendsto (fun n : ℕ => busTime X n ω / n) atTop (𝓝 μ))
    (hq : Tendsto (fun n : ℕ => (∑ k ∈ Finset.range n, X k ω ^ 2) / n) atTop (𝓝 m2)) :
    Tendsto (fun t : ℝ => (∫ s in (0 : ℝ)..t, wait X s ω) / t) atTop (𝓝 (m2 / (2 * μ))) := by
  have hN := rp_count_tendsto h0 hunb
  have hR := rp_ratio_tendsto hμ h0 hunb hl
  have hlow : Tendsto (fun t : ℝ =>
      (∑ k ∈ Finset.range (arrivalCount X t ω), X k ω ^ 2) / (arrivalCount X t ω : ℝ) *
        ((arrivalCount X t ω : ℝ) / t) / 2) atTop (𝓝 (m2 * (1 / μ) / 2)) :=
    ((hq.comp hN).mul hR).div_const 2
  have hN1 : Tendsto (fun t : ℝ => arrivalCount X t ω + 1) atTop atTop :=
    (tendsto_add_atTop_nat 1).comp hN
  have hup : Tendsto (fun t : ℝ =>
      (∑ k ∈ Finset.range (arrivalCount X t ω + 1), X k ω ^ 2) /
        ((arrivalCount X t ω + 1 : ℕ) : ℝ) *
        ((arrivalCount X t ω : ℝ) / t + 1 / t) / 2) atTop (𝓝 (m2 * (1 / μ + 0) / 2)) :=
    ((hq.comp hN1).mul (hR.add (tendsto_const_nhds.div_atTop tendsto_id))).div_const 2
  rw [add_zero] at hup
  have hlim : m2 / (2 * μ) = m2 * (1 / μ) / 2 := by ring
  rw [hlim]
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlow hup ?_ ?_
  · filter_upwards [eventually_gt_atTop 0, hN.eventually_ge_atTop 1] with t ht hn
    have hNpos : (0 : ℝ) < arrivalCount X t ω := by exact_mod_cast hn
    have e : (∑ k ∈ Finset.range (arrivalCount X t ω), X k ω ^ 2) / (arrivalCount X t ω : ℝ) *
        ((arrivalCount X t ω : ℝ) / t) / 2 =
        ((∑ k ∈ Finset.range (arrivalCount X t ω), X k ω ^ 2) / 2) / t := by
      field_simp
    rw [e]
    exact div_le_div_of_nonneg_right (rp_int_bounds h0 hunb ht.le).1 ht.le
  · filter_upwards [eventually_gt_atTop 0] with t ht
    have e : (∑ k ∈ Finset.range (arrivalCount X t ω + 1), X k ω ^ 2) /
        ((arrivalCount X t ω + 1 : ℕ) : ℝ) * ((arrivalCount X t ω : ℝ) / t + 1 / t) / 2 =
        ((∑ k ∈ Finset.range (arrivalCount X t ω + 1), X k ω ^ 2) / 2) / t := by
      have : ((arrivalCount X t ω + 1 : ℕ) : ℝ) ≠ 0 := by positivity
      push_cast at this ⊢
      field_simp
    rw [e]
    exact div_le_div_of_nonneg_right (rp_int_bounds h0 hunb ht.le).2 ht.le

lemma rp_tsum_count {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    ∑' i, (if busTime X i ω ≤ t then (1 : ENNReal) else 0) = (arrivalCount X t ω : ENNReal) + 1 := by
  have e : ∀ i, (if busTime X i ω ≤ t then (1 : ENNReal) else 0) =
      if i ∈ Finset.range (arrivalCount X t ω + 1) then 1 else 0 := by
    intro i
    simp [rp_le_iff h0 hunb ht]
  simp_rw [e]
  rw [tsum_eq_sum (s := Finset.range (arrivalCount X t ω + 1)) (by intro i hi; simp [hi]),
    Finset.sum_ite_of_true (fun i hi => hi)]
  simp

lemma rp_tsum_time {X : ℕ → Ω → ℝ} {ω : Ω} (h0 : ∀ i, 0 ≤ X i ω)
    (hunb : Tendsto (fun n => busTime X n ω) atTop atTop) {t : ℝ} (ht : 0 ≤ t) :
    ∑' i, ENNReal.ofReal (X i ω) * (if busTime X i ω ≤ t then (1 : ENNReal) else 0) =
      ENNReal.ofReal (busTime X (arrivalCount X t ω + 1) ω) := by
  have e : ∀ i, ENNReal.ofReal (X i ω) * (if busTime X i ω ≤ t then (1 : ENNReal) else 0) =
      if i ∈ Finset.range (arrivalCount X t ω + 1) then ENNReal.ofReal (X i ω) else 0 := by
    intro i
    simp [rp_le_iff h0 hunb ht]
  simp_rw [e]
  rw [tsum_eq_sum (s := Finset.range (arrivalCount X t ω + 1)) (by intro i hi; simp [hi]),
    Finset.sum_ite_of_true (fun i hi => hi)]
  rw [busTime, ENNReal.ofReal_sum_of_nonneg (fun i _ => h0 i)]

lemma rp_wald (P : Measure Ω) [IsProbabilityMeasure P] (Y : ℕ → Ω → ℝ) (hindep : iIndepFun Y P)
    (hident : ∀ i, IdentDistrib (Y i) (Y 0) P P)
    (hgood : ∀ᵐ ω ∂P, (∀ i, 0 ≤ Y i ω) ∧ Tendsto (fun n => busTime Y n ω) atTop atTop)
    {t : ℝ} (ht : 0 ≤ t) :
    ∫⁻ ω, ENNReal.ofReal (busTime Y (arrivalCount Y t ω + 1) ω) ∂P =
      (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * (∫⁻ ω, (arrivalCount Y t ω : ENNReal) ∂P + 1) := by
  have hmeas : ∀ i, AEMeasurable (Y i) P := fun i => (hident i).aemeasurable_fst
  set g : ℝ → ENNReal := fun x => if x ≤ t then 1 else 0 with hgdef
  have hg : Measurable g := Measurable.ite measurableSet_Iic measurable_const measurable_const
  have hS : ∀ i, (fun ω => busTime Y i ω) = ∑ j ∈ Finset.range i, Y j := by
    intro i; ext ω; simp [busTime, Finset.sum_apply]
  have hSm : ∀ i, AEMeasurable (fun ω => busTime Y i ω) P := by
    intro i; rw [hS]; exact Finset.aemeasurable_sum _ (fun j _ => hmeas j)
  have hind : ∀ i, IndepFun (fun ω => ENNReal.ofReal (Y i ω)) (fun ω => g (busTime Y i ω)) P := by
    intro i
    have h := (hindep.indepFun_finsetSum_of_notMem₀ hmeas (s := Finset.range i) (i := i)
      (by simp)).symm
    rw [← hS] at h
    exact h.comp ENNReal.measurable_ofReal hg
  have hfm : ∀ i, AEMeasurable (fun ω => ENNReal.ofReal (Y i ω)) P := fun i =>
    ENNReal.measurable_ofReal.comp_aemeasurable (hmeas i)
  have hgm : ∀ i, AEMeasurable (fun ω => g (busTime Y i ω)) P := fun i =>
    hg.comp_aemeasurable (hSm i)
  have hterm : ∀ i, ∫⁻ ω, ENNReal.ofReal (Y i ω) * g (busTime Y i ω) ∂P =
      (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∫⁻ ω, g (busTime Y i ω) ∂P := by
    intro i
    have e : ∫⁻ ω, ENNReal.ofReal (Y i ω) ∂P = ∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P :=
      ((hident i).comp ENNReal.measurable_ofReal).lintegral_eq
    rw [← e]
    exact lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun' (hfm i) (hgm i) (hind i)
  calc ∫⁻ ω, ENNReal.ofReal (busTime Y (arrivalCount Y t ω + 1) ω) ∂P
      = ∫⁻ ω, ∑' i, ENNReal.ofReal (Y i ω) * g (busTime Y i ω) ∂P := by
        apply lintegral_congr_ae
        filter_upwards [hgood] with ω hω
        exact (rp_tsum_time hω.1 hω.2 ht).symm
    _ = ∑' i, ∫⁻ ω, ENNReal.ofReal (Y i ω) * g (busTime Y i ω) ∂P :=
        lintegral_tsum (fun i => (hfm i).mul (hgm i))
    _ = ∑' i, (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∫⁻ ω, g (busTime Y i ω) ∂P :=
        tsum_congr hterm
    _ = (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∑' i, ∫⁻ ω, g (busTime Y i ω) ∂P :=
        ENNReal.tsum_mul_left
    _ = (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∫⁻ ω, ∑' i, g (busTime Y i ω) ∂P := by
        rw [lintegral_tsum hgm]
    _ = (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * ∫⁻ ω, ((arrivalCount Y t ω : ENNReal) + 1) ∂P := by
        congr 1
        apply lintegral_congr_ae
        filter_upwards [hgood] with ω hω
        exact rp_tsum_count hω.1 hω.2 ht
    _ = (∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P) * (∫⁻ ω, (arrivalCount Y t ω : ENNReal) ∂P + 1) := by
        rw [lintegral_add_right _ measurable_const]
        simp

lemma rp_count_aemeas (P : Measure Ω) (Y : ℕ → Ω → ℝ)
    (hident : ∀ i, IdentDistrib (Y i) (Y 0) P P)
    (hgood : ∀ᵐ ω ∂P, (∀ i, 0 ≤ Y i ω) ∧ Tendsto (fun n => busTime Y n ω) atTop atTop)
    {t : ℝ} (ht : 0 ≤ t) :
    AEMeasurable (fun ω => (arrivalCount Y t ω : ℝ)) P := by
  have hmeas : ∀ i, AEMeasurable (Y i) P := fun i => (hident i).aemeasurable_fst
  have hSm : ∀ i, AEMeasurable (fun ω => busTime Y i ω) P := by
    intro i
    have : (fun ω => busTime Y i ω) = ∑ j ∈ Finset.range i, Y j := by
      ext ω; simp [busTime, Finset.sum_apply]
    rw [this]; exact Finset.aemeasurable_sum _ (fun j _ => hmeas j)
  have hg : Measurable (fun x : ℝ => if x ≤ t then (1 : ENNReal) else 0) :=
    Measurable.ite measurableSet_Iic measurable_const measurable_const
  have hm : AEMeasurable (fun ω => (∑' i, (if busTime Y i ω ≤ t then (1 : ENNReal) else 0)).toReal
      - 1) P :=
    ((AEMeasurable.tsum (fun i => hg.comp_aemeasurable (hSm i))).ennreal_toReal).sub_const _
  refine hm.congr ?_
  filter_upwards [hgood] with ω hω
  rw [rp_tsum_count hω.1 hω.2 ht]
  rw [show ((arrivalCount Y t ω : ENNReal) + 1) = ((arrivalCount Y t ω + 1 : ℕ) : ENNReal) by
    push_cast; rfl, ENNReal.toReal_natCast]
  push_cast
  ring

lemma rp_trunc_integrable (P : Measure Ω) (X : ℕ → Ω → ℝ) (hint : Integrable (X 0) P) (c : ℝ)
    [IsFiniteMeasure P] : Integrable (fun ω => min (X 0 ω) c) P :=
  hint.inf (integrable_const c)

lemma rp_trunc_tendsto (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hnonneg0 : ∀ᵐ ω ∂P, 0 ≤ X 0 ω) (hint : Integrable (X 0) P) :
    Tendsto (fun n : ℕ => P[fun ω => min (X 0 ω) (n : ℝ)]) atTop (𝓝 P[X 0]) := by
  refine tendsto_integral_of_dominated_convergence (fun ω => ‖X 0 ω‖)
    (fun n => (rp_trunc_integrable P X hint _).aestronglyMeasurable) hint.norm
    (fun n => ?_) (Eventually.of_forall fun ω => ?_)
  · filter_upwards [hnonneg0] with ω h
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (le_min h (Nat.cast_nonneg n)),
      abs_of_nonneg h]
    exact min_le_left _ _
  · refine tendsto_const_nhds.congr' ?_
    filter_upwards [eventually_ge_atTop ⌈X 0 ω⌉₊] with n hn
    exact (min_eq_left (Nat.ceil_le.1 hn)).symm

lemma rp_upper (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0])
    {t : ℝ} (ht : 0 ≤ t) (n : ℕ) (hposn : 0 < P[fun ω => min (X 0 ω) (n : ℝ)]) :
    ∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P ≠ ⊤ ∧
    P[fun ω => min (X 0 ω) (n : ℝ)] * ((∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P).toReal + 1)
      ≤ t + n := by
  set Y : ℕ → Ω → ℝ := fun i ω => min (X i ω) (n : ℝ) with hYdef
  have hYind : iIndepFun Y P :=
    hindep.comp (fun _ x => min x (n : ℝ)) (fun _ => measurable_id.min measurable_const)
  have hYid : ∀ i, IdentDistrib (Y i) (Y 0) P P := fun i =>
    (hident i).comp (measurable_id.min measurable_const)
  have hYint : Integrable (Y 0) P := rp_trunc_integrable P X hint _
  have hYnn : ∀ i, ∀ᵐ ω ∂P, 0 ≤ Y i ω := by
    intro i
    filter_upwards [hnonneg i] with ω h
    exact le_min h (Nat.cast_nonneg n)
  have hgX := rp_ae_good P X hindep hident hnonneg hint hpos
  have hgY := rp_ae_good P Y hYind hYid hYnn hYint hposn
  have hgX' : ∀ᵐ ω ∂P, (∀ i, 0 ≤ X i ω) ∧ Tendsto (fun n => busTime X n ω) atTop atTop := by
    filter_upwards [hgX] with ω h using ⟨h.1, h.2.1⟩
  have hgY' : ∀ᵐ ω ∂P, (∀ i, 0 ≤ Y i ω) ∧ Tendsto (fun n => busTime Y n ω) atTop atTop := by
    filter_upwards [hgY] with ω h using ⟨h.1, h.2.1⟩
  have hWY := rp_wald P Y hYind hYid hgY' ht
  have hmuY : ∫⁻ ω, ENNReal.ofReal (Y 0 ω) ∂P = ENNReal.ofReal (P[Y 0]) :=
    (ofReal_integral_eq_lintegral_ofReal hYint (hYnn 0)).symm
  set AY := ∫⁻ ω, (arrivalCount Y t ω : ENNReal) ∂P with hAY
  set A := ∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P with hA
  have h2 : ENNReal.ofReal (P[Y 0]) * (AY + 1) ≤ ENNReal.ofReal (t + n) := by
    rw [← hmuY, ← hWY]
    calc ∫⁻ ω, ENNReal.ofReal (busTime Y (arrivalCount Y t ω + 1) ω) ∂P
        ≤ ∫⁻ _, ENNReal.ofReal (t + n) ∂P := by
          apply lintegral_mono_ae
          filter_upwards [hgY'] with ω hω
          apply ENNReal.ofReal_le_ofReal
          rw [rp_busTime_succ]
          have h1 := rp_le_t hω.1 hω.2 ht
          have h3 : Y (arrivalCount Y t ω) ω ≤ n := min_le_right _ _
          linarith
      _ = ENNReal.ofReal (t + n) := by simp
  have h3 : A ≤ AY := by
    apply lintegral_mono_ae
    filter_upwards [hgX', hgY'] with ω hX hY
    have hle : busTime Y (arrivalCount X t ω) ω ≤ busTime X (arrivalCount X t ω) ω :=
      Finset.sum_le_sum (fun i _ => min_le_left _ _)
    have := (rp_le_iff hY.1 hY.2 ht _).1 (hle.trans (rp_le_t hX.1 hX.2 ht))
    exact_mod_cast this
  have hYpos : 0 < ENNReal.ofReal (P[Y 0]) := ENNReal.ofReal_pos.2 hposn
  have hAYtop : AY ≠ ⊤ := by
    intro htop
    rw [htop, top_add, ENNReal.mul_top hYpos.ne'] at h2
    exact ENNReal.ofReal_ne_top (top_le_iff.1 h2)
  have hAtop : A ≠ ⊤ := ne_top_of_le_ne_top hAYtop h3
  refine ⟨hAtop, ?_⟩
  have h4 := ENNReal.toReal_mono ENNReal.ofReal_ne_top h2
  rw [ENNReal.toReal_mul, ENNReal.toReal_add hAYtop ENNReal.one_ne_top,
    ENNReal.toReal_ofReal hposn.le, ENNReal.toReal_ofReal (by positivity), ENNReal.toReal_one] at h4
  have h5 : A.toReal ≤ AY.toReal := ENNReal.toReal_mono hAYtop h3
  calc P[Y 0] * (A.toReal + 1) ≤ P[Y 0] * (AY.toReal + 1) := by gcongr
    _ ≤ t + n := h4

lemma rp_lower (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0])
    {t : ℝ} (ht : 0 ≤ t) (hA : ∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P ≠ ⊤) :
    t ≤ P[X 0] * ((∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P).toReal + 1) := by
  have hgX := rp_ae_good P X hindep hident hnonneg hint hpos
  have hgX' : ∀ᵐ ω ∂P, (∀ i, 0 ≤ X i ω) ∧ Tendsto (fun n => busTime X n ω) atTop atTop := by
    filter_upwards [hgX] with ω h using ⟨h.1, h.2.1⟩
  have hW := rp_wald P X hindep hident hgX' ht
  have hmu : ∫⁻ ω, ENNReal.ofReal (X 0 ω) ∂P = ENNReal.ofReal (P[X 0]) :=
    (ofReal_integral_eq_lintegral_ofReal hint (hnonneg 0)).symm
  have h1 : ENNReal.ofReal t ≤
      ENNReal.ofReal (P[X 0]) * (∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P + 1) := by
    rw [← hmu, ← hW]
    calc ENNReal.ofReal t = ∫⁻ _, ENNReal.ofReal t ∂P := by simp
      _ ≤ _ := by
          apply lintegral_mono_ae
          filter_upwards [hgX'] with ω hω
          exact ENNReal.ofReal_le_ofReal (rp_lt_next hω.1 hω.2 ht).le
  have hne : ENNReal.ofReal (P[X 0]) * (∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P + 1) ≠ ⊤ :=
    ENNReal.mul_ne_top ENNReal.ofReal_ne_top (ENNReal.add_ne_top.2 ⟨hA, ENNReal.one_ne_top⟩)
  have h4 := ENNReal.toReal_mono hne h1
  rwa [ENNReal.toReal_mul, ENNReal.toReal_add hA ENNReal.one_ne_top,
    ENNReal.toReal_ofReal hpos.le, ENNReal.toReal_ofReal ht, ENNReal.toReal_one] at h4

lemma rp_integral_count (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0])
    {t : ℝ} (ht : 0 ≤ t) :
    ∫ ω, (arrivalCount X t ω : ℝ) ∂P = (∫⁻ ω, (arrivalCount X t ω : ENNReal) ∂P).toReal := by
  have hgX := rp_ae_good P X hindep hident hnonneg hint hpos
  have hgX' : ∀ᵐ ω ∂P, (∀ i, 0 ≤ X i ω) ∧ Tendsto (fun n => busTime X n ω) atTop atTop := by
    filter_upwards [hgX] with ω h using ⟨h.1, h.2.1⟩
  rw [integral_eq_lintegral_of_nonneg_ae (Eventually.of_forall fun ω => Nat.cast_nonneg _)
    (rp_count_aemeas P X hident hgX' ht).aestronglyMeasurable]
  simp only [ENNReal.ofReal_natCast]

lemma rp_limit {μ : ℝ} (hμ : 0 < μ) (e : ℝ → ℝ) (μc : ℕ → ℝ) (hμc : Tendsto μc atTop (𝓝 μ))
    (hlow : ∀ t ≥ 0, t ≤ μ * (e t + 1))
    (hup : ∀ t ≥ 0, ∀ n : ℕ, 0 < μc n → μc n * (e t + 1) ≤ t + n) :
    Tendsto (fun t => e t / t) atTop (𝓝 (1 / μ)) := by
  rw [tendsto_order]
  constructor
  · intro a ha
    have hL : Tendsto (fun t : ℝ => 1 / μ - t⁻¹) atTop (𝓝 (1 / μ - 0)) :=
      tendsto_const_nhds.sub tendsto_inv_atTop_zero
    rw [sub_zero] at hL
    filter_upwards [(tendsto_order.1 hL).1 a ha, eventually_gt_atTop 0] with t h1 h2
    refine lt_of_lt_of_le h1 ?_
    have h3 := hlow t h2.le
    rw [le_div_iff₀ h2]
    have : (1 / μ - t⁻¹) * t = t / μ - 1 := by field_simp
    rw [this, sub_le_iff_le_add, div_le_iff₀ hμ]
    linarith
  · intro b hb
    have hinv : Tendsto (fun n => 1 / μc n) atTop (𝓝 (1 / μ)) :=
      tendsto_const_nhds.div hμc hμ.ne'
    obtain ⟨n, hn1, hn2⟩ := ((tendsto_order.1 hinv).2 b hb |>.and
      ((tendsto_order.1 hμc).1 0 hμ)).exists
    have hU : Tendsto (fun t : ℝ => 1 / μc n + (n / μc n - 1) * t⁻¹) atTop
        (𝓝 (1 / μc n + (n / μc n - 1) * 0)) :=
      tendsto_const_nhds.add (tendsto_const_nhds.mul tendsto_inv_atTop_zero)
    rw [mul_zero, add_zero] at hU
    filter_upwards [(tendsto_order.1 hU).2 b hn1, eventually_gt_atTop 0] with t h1 h2
    refine lt_of_le_of_lt ?_ h1
    have h3 := hup t h2.le n hn2
    rw [div_le_iff₀ h2]
    have : (1 / μc n + (n / μc n - 1) * t⁻¹) * t = (t + n) / μc n - 1 := by
      field_simp
      ring
    rw [this, le_sub_iff_add_le, le_div_iff₀ hn2]
    linarith

#print axioms rp_busTime_zero
#print axioms rp_busTime_succ
#print axioms rp_busTime_mono
#print axioms rp_le_iff
#print axioms rp_le_t
#print axioms rp_lt_next
#print axioms rp_count_mono
#print axioms rp_count_tendsto
#print axioms rp_ae_good
#print axioms rp_ratio_tendsto
#print axioms rp_wait_eq
#print axioms rp_wait_nonneg
#print axioms rp_busTime_nonneg
#print axioms rp_wait_ii
#print axioms rp_piece
#print axioms rp_int_busTime
#print axioms rp_int_bounds
#print axioms rp_wait_tendsto
#print axioms rp_tsum_count
#print axioms rp_tsum_time
#print axioms rp_wald
#print axioms rp_count_aemeas
#print axioms rp_trunc_integrable
#print axioms rp_trunc_tendsto
#print axioms rp_upper
#print axioms rp_lower
#print axioms rp_integral_count
#print axioms rp_limit

/-- Elementary renewal theorem, almost-sure form: if the gaps are non-negative, independent,
share one law, and have a finite positive mean $\mu$, then $N(t)/t \to 1/\mu$ on almost every run. -/
theorem elementary_renewal_theorem_ae (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0]) :
    ∀ᵐ ω ∂P, Tendsto (fun t : ℝ => (arrivalCount X t ω : ℝ) / t) atTop (𝓝 (1 / P[X 0])) := by

  filter_upwards [rp_ae_good P X hindep hident hnonneg hint hpos] with ω hω
  exact rp_ratio_tendsto hpos hω.1 hω.2.1 hω.2.2

/-- Elementary renewal theorem, form for averages: under the same hypotheses, the renewal
function $m(t) = E[N(t)]$ satisfies $m(t)/t \to 1/\mu$. -/
theorem elementary_renewal_theorem_mean (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0]) :
    Tendsto (fun t : ℝ => (∫ ω, (arrivalCount X t ω : ℝ) ∂P) / t) atTop (𝓝 (1 / P[X 0])) := by

  have hμc := rp_trunc_tendsto P X (hnonneg 0) hint
  obtain ⟨n0, hn0⟩ := ((tendsto_order.1 hμc).1 0 hpos).exists
  refine rp_limit hpos (fun t => ∫ ω, (arrivalCount X t ω : ℝ) ∂P)
    (fun n : ℕ => P[fun ω => min (X 0 ω) (n : ℝ)]) hμc ?_ ?_
  · intro t ht
    have hA := (rp_upper P X hindep hident hnonneg hint hpos ht n0 hn0).1
    rw [rp_integral_count P X hindep hident hnonneg hint hpos ht]
    exact rp_lower P X hindep hident hnonneg hint hpos ht hA
  · intro t ht n hn
    rw [rp_integral_count P X hindep hident hnonneg hint hpos ht]
    exact (rp_upper P X hindep hident hnonneg hint hpos ht n hn).2

/-- Inspection paradox: if moreover $E[X^2]$ is finite, then on almost every run the wait of a
passenger arriving at a time spread evenly over $[0, t]$ averages, as $t \to \infty$, to
$E[X^2] / (2\mu)$. -/
theorem inspection_paradox_mean_wait (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hnonneg : ∀ i, ∀ᵐ ω ∂P, 0 ≤ X i ω) (hint : Integrable (X 0) P) (hpos : 0 < P[X 0])
    (hint2 : Integrable (fun ω => X 0 ω ^ 2) P) :
    ∀ᵐ ω ∂P, Tendsto (fun t : ℝ => (∫ s in (0 : ℝ)..t, wait X s ω) / t) atTop
      (𝓝 (P[fun ω => X 0 ω ^ 2] / (2 * P[X 0]))) := by

  have hY := strong_law_ae_real (fun i ω => X i ω ^ 2) hint2
    (fun i j hij => (hindep.indepFun hij).comp (measurable_id.pow_const 2)
      (measurable_id.pow_const 2))
    (fun i => (hident i).comp (measurable_id.pow_const 2))
  filter_upwards [rp_ae_good P X hindep hident hnonneg hint hpos, hY] with ω hω hq
  exact rp_wait_tendsto hpos hω.1 hω.2.1 hω.2.2 hq


/-! Worked numbers from the card: gaps of 5 or 15 minutes, each with chance 1/2. -/

-- mean gap 10, mean square gap 125, variance 25
example : (1 / 2 : ℚ) * 5 + 1 / 2 * 15 = 10 := by norm_num
example : (1 / 2 : ℚ) * 5 ^ 2 + 1 / 2 * 15 ^ 2 = 125 := by norm_num
example : (125 : ℚ) - 10 * 10 = 25 := by norm_num
-- rate: 6 buses an hour
example : (60 : ℚ) / 10 = 6 := by norm_num
-- mean wait: 125 / (2 * 10) = 25/4 minutes, and the same as mu/2 + var/(2 mu)
example : (125 : ℚ) / (2 * 10) = 25 / 4 := by norm_num
example : (10 : ℚ) / 2 + 25 / (2 * 10) = 25 / 4 := by norm_num
-- length bias: share of time in 15-minute gaps 3/4, in 5-minute gaps 1/4; wait 1/4 * 5/2 + 3/4 * 15/2
example : (1 / 2 : ℚ) * 15 / 10 = 3 / 4 := by norm_num
example : (1 / 2 : ℚ) * 5 / 10 = 1 / 4 := by norm_num
example : (1 / 4 : ℚ) * (5 / 2) + 3 / 4 * (15 / 2) = 25 / 4 := by norm_num
-- the gap a passenger lands in averages 125 / 10 = 25/2 minutes
example : (125 : ℚ) / 10 = 25 / 2 := by norm_num
-- the sawtooth over one hour, gaps 5 15 5 5 15 15: tooth areas 25/2 and 225/2, area / 60 = 25/4
example : ((5 ^ 2 + 15 ^ 2 + 5 ^ 2 + 5 ^ 2 + 15 ^ 2 + 15 ^ 2 : ℚ) / 2) / 60 = 25 / 4 := by norm_num
-- sandwich at t = 60: 60/10 - 1 = 5 and (60 + 15)/10 - 1 = 13/2
example : (60 : ℚ) / 10 - 1 = 5 ∧ (60 + 15 : ℚ) / 10 - 1 = 13 / 2 := by norm_num
-- brute force over all 4096 patterns of 12 gaps (1 or 3 steps of 5 minutes): buses by minute 60 total 24047
example : (∑ b ∈ Finset.range 4096, ((Finset.Icc 1 12).filter
    (fun n => ∑ i ∈ Finset.range n, (1 + 2 * ((b / 2 ^ i) % 2)) ≤ 12)).card) = 24047 := by
  decide +kernel
-- m(60) = 24047/4096 sits inside the sandwich
example : (5 : ℚ) < 24047 / 4096 ∧ (24047 : ℚ) / 4096 ≤ 13 / 2 := by norm_num
-- passenger on a 5-minute mark: 5 * (1/2 * 0 + 1/2 * 3) / (10/5) = 15/4 minutes
example : (5 : ℚ) * (1 / 2 * (1 * 0 / 2) + 1 / 2 * (3 * 2 / 2)) / (10 / 5) = 15 / 4 := by norm_num
-- every gap a copy of the first: 1/2 * 12 + 1/2 * 4 = 8 buses an hour
example : (1 / 2 : ℚ) * (60 / 5) + 1 / 2 * (60 / 15) = 8 := by norm_num
-- try lines: gaps 1 or 19 give wait 181/20; short gaps with chance 3/4 give rate 8 and wait 5
example : ((1 / 2 : ℚ) * 1 ^ 2 + 1 / 2 * 19 ^ 2) / (2 * 10) = 181 / 20 := by norm_num
example : (60 : ℚ) / (3 / 4 * 5 + 1 / 4 * 15) = 8 ∧
    ((3 / 4 : ℚ) * 5 ^ 2 + 1 / 4 * 15 ^ 2) / (2 * (3 / 4 * 5 + 1 / 4 * 15)) = 5 := by norm_num
-- Poisson case, mean gap 15: E[X^2] = 2 * 15^2, wait 15
example : (2 * 15 ^ 2 : ℚ) / (2 * 15) = 15 := by norm_num

#print axioms elementary_renewal_theorem_ae
#print axioms elementary_renewal_theorem_mean
#print axioms inspection_paradox_mean_wait
