-- Improper integrals: the power rule decides when 1/t^p totals to a finite amount from 1 for ever (p > 1, giving 1/(p - 1)) and up to a spike at 0 (p < 1, giving 1/(1 - p)), and a never-negative rate below a rate with a finite total has a finite total too.
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Tactic.NormNum

open Filter Topology MeasureTheory


lemma pos_of_mem_uIcc_pos {a b t : ℝ} (ha : 0 < a) (hb : 0 < b) (ht : t ∈ Set.uIcc a b) :
    0 < t := by
  rcases Set.mem_uIcc.mp ht with h | h
  · linarith [h.1]
  · linarith [h.1]

lemma one_div_rpow_eq {t p : ℝ} (ht : 0 < t) : 1 / t ^ p = t ^ (-p) := by
  rw [Real.rpow_neg ht.le, one_div]

lemma ii_one_div_rpow {a b p : ℝ} (ha : 0 < a) (hb : 0 < b) :
    IntervalIntegrable (fun t : ℝ => 1 / t ^ p) volume a b := by
  apply intervalIntegral.intervalIntegrable_one_div
  · intro x hx
    exact (Real.rpow_pos_of_pos (pos_of_mem_uIcc_pos ha hb hx) p).ne'
  · exact ContinuousOn.rpow_const continuousOn_id
      (fun x hx => Or.inl (pos_of_mem_uIcc_pos ha hb hx).ne')

lemma integral_one_div_rpow {a b p : ℝ} (ha : 0 < a) (hb : 0 < b) (hp : p ≠ 1) :
    ∫ t in a..b, 1 / t ^ p = (b ^ (1 - p) - a ^ (1 - p)) / (1 - p) := by
  have h1 : ∫ t in a..b, 1 / t ^ p = ∫ t in a..b, t ^ (-p) :=
    intervalIntegral.integral_congr (fun t ht => one_div_rpow_eq (pos_of_mem_uIcc_pos ha hb ht))
  have hnot : (0 : ℝ) ∉ Set.uIcc a b := fun h => lt_irrefl _ (pos_of_mem_uIcc_pos ha hb h)
  rw [h1, integral_rpow (Or.inr ⟨fun h => hp (by linarith), hnot⟩)]
  have : -p + 1 = 1 - p := by ring
  rw [this]

#print axioms pos_of_mem_uIcc_pos
#print axioms one_div_rpow_eq
#print axioms ii_one_div_rpow
#print axioms integral_one_div_rpow

/-- Power rule, endless interval: the total of `1/t^p` from 1 to `B` heads for `1/(p - 1)`
as `B` grows without bound when `p > 1`; when `p ≤ 1` (p = 1 included) it heads for no
finite number at all, so the integral diverges. -/
theorem power_rule_at_infinity (p : ℝ) :
    (1 < p → Tendsto (fun B : ℝ => ∫ t in (1 : ℝ)..B, 1 / t ^ p) atTop (𝓝 (1 / (p - 1)))) ∧
    (p ≤ 1 → ¬ ∃ L : ℝ, Tendsto (fun B : ℝ => ∫ t in (1 : ℝ)..B, 1 / t ^ p) atTop (𝓝 L)) := by
  constructor
  · intro hp
    have hint : IntegrableOn (fun t : ℝ => t ^ (-p)) (Set.Ioi 1) :=
      integrableOn_Ioi_rpow_of_lt (by linarith) one_pos
    have hval : ∫ t in Set.Ioi (1 : ℝ), t ^ (-p) = 1 / (p - 1) := by
      rw [integral_Ioi_rpow_of_lt (by linarith) one_pos, Real.one_rpow]
      have : -p + 1 = -(p - 1) := by ring
      rw [this, div_neg, neg_div, neg_neg]
    have h := intervalIntegral_tendsto_integral_Ioi (μ := volume) 1 hint tendsto_id
    rw [hval] at h
    refine h.congr' ?_
    filter_upwards [eventually_ge_atTop (1 : ℝ)] with B hB
    exact intervalIntegral.integral_congr
      (fun t ht => (one_div_rpow_eq (pos_of_mem_uIcc_pos one_pos (show (0:ℝ) < id B by simp only [id]; linarith) ht)).symm)
  · intro hp ⟨L, hL⟩
    have hlog : Tendsto (fun B : ℝ => ∫ t in (1 : ℝ)..B, 1 / t ^ p) atTop atTop := by
      refine tendsto_atTop_mono' atTop ?_ Real.tendsto_log_atTop
      filter_upwards [eventually_ge_atTop (1 : ℝ)] with B hB
      have hB0 : (0 : ℝ) < B := by linarith
      have e : Real.log B = ∫ t in (1 : ℝ)..B, 1 / t := by
        rw [integral_one_div_of_pos one_pos hB0, div_one]
      rw [e]
      apply intervalIntegral.integral_mono_on hB
      · exact intervalIntegral.intervalIntegrable_one_div
          (fun x hx => (pos_of_mem_uIcc_pos one_pos hB0 hx).ne') continuousOn_id
      · exact ii_one_div_rpow one_pos hB0
      · intro t ht
        have ht0 : 0 < t := by linarith [ht.1]
        apply one_div_le_one_div_of_le (Real.rpow_pos_of_pos ht0 p)
        calc t ^ p ≤ t ^ (1 : ℝ) := Real.rpow_le_rpow_of_exponent_le ht.1 hp
          _ = t := Real.rpow_one t
    exact not_tendsto_nhds_of_tendsto_atTop hlog L hL

/-- Power rule, spike at 0: the total of `1/t^p` from `s` to 1 heads for `1/(1 - p)` as the
gap `s` closes from above when `p < 1`; when `p ≥ 1` (p = 1 included) it heads for no finite
number, so the integral diverges. The rule flips. -/
theorem power_rule_at_spike (p : ℝ) :
    (p < 1 → Tendsto (fun s : ℝ => ∫ t in s..(1 : ℝ), 1 / t ^ p) (𝓝[>] 0) (𝓝 (1 / (1 - p)))) ∧
    (1 ≤ p → ¬ ∃ L : ℝ, Tendsto (fun s : ℝ => ∫ t in s..(1 : ℝ), 1 / t ^ p) (𝓝[>] 0) (𝓝 L)) := by
  constructor
  · intro hp
    have hc : ContinuousAt (fun s : ℝ => s ^ (1 - p)) 0 :=
      Real.continuousAt_rpow_const 0 (1 - p) (Or.inr (by linarith))
    have h0 : Tendsto (fun s : ℝ => (1 - s ^ (1 - p)) / (1 - p)) (𝓝[>] 0) (𝓝 (1 / (1 - p))) := by
      have := ((tendsto_const_nhds (x := (1 : ℝ))).sub hc.tendsto).div_const (1 - p)
      rw [Real.zero_rpow (by linarith), sub_zero] at this
      exact this.mono_left nhdsWithin_le_nhds
    refine h0.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with s hs
    rw [integral_one_div_rpow hs one_pos hp.ne, Real.one_rpow]
  · intro hp ⟨L, hL⟩
    have hlog : Tendsto (fun s : ℝ => ∫ t in s..(1 : ℝ), 1 / t ^ p) (𝓝[>] 0) atTop := by
      refine tendsto_atTop_mono' _ ?_ (tendsto_neg_atBot_atTop.comp Real.tendsto_log_nhdsGT_zero)
      filter_upwards [self_mem_nhdsWithin, Ioo_mem_nhdsGT (show (0 : ℝ) < 1 by norm_num)]
        with s hs hs1
      have hs0 : (0 : ℝ) < s := hs
      have hs1' : s ≤ 1 := hs1.2.le
      have e : (Function.comp Neg.neg Real.log) s = ∫ t in s..(1 : ℝ), 1 / t := by
        rw [integral_one_div_of_pos hs0 one_pos, Function.comp_apply, one_div, Real.log_inv]
      rw [e]
      apply intervalIntegral.integral_mono_on hs1'
      · exact intervalIntegral.intervalIntegrable_one_div
          (fun x hx => (pos_of_mem_uIcc_pos hs0 one_pos hx).ne') continuousOn_id
      · exact ii_one_div_rpow hs0 one_pos
      · intro t ht
        have ht0 : 0 < t := by linarith [ht.1]
        apply one_div_le_one_div_of_le (Real.rpow_pos_of_pos ht0 p)
        calc t ^ p ≤ t ^ (1 : ℝ) := Real.rpow_le_rpow_of_exponent_ge ht0 ht.2 hp
          _ = t := Real.rpow_one t
    exact not_tendsto_nhds_of_tendsto_atTop hlog L hL

/-- Comparison test: let `f` and `g` be integrable from `a` to every `B`, with
`0 ≤ f t ≤ g t` from some point on. If `g`'s total from `a` for ever converges, to `G`, then
`f`'s converges too, to some `L`; and when `0 ≤ f t ≤ g t` holds for every `t ≥ a`,
`L` is at most `G`. (Turned round: an endless total for `f` forces one for `g`.) -/
theorem comparison_test (f g : ℝ → ℝ) (a G : ℝ)
    (hf : ∀ B : ℝ, IntervalIntegrable f volume a B)
    (hg : ∀ B : ℝ, IntervalIntegrable g volume a B)
    (hfg : ∀ᶠ t in atTop, 0 ≤ f t ∧ f t ≤ g t)
    (hG : Tendsto (fun B : ℝ => ∫ t in a..B, g t) atTop (𝓝 G)) :
    ∃ L : ℝ, Tendsto (fun B : ℝ => ∫ t in a..B, f t) atTop (𝓝 L) ∧
      ((∀ t, a ≤ t → 0 ≤ f t ∧ f t ≤ g t) → L ≤ G) := by
  obtain ⟨c₀, hc₀⟩ := eventually_atTop.mp hfg
  set c := max a c₀ with hcdef
  have hac : a ≤ c := le_max_left _ _
  have hc : ∀ t, c ≤ t → 0 ≤ f t ∧ f t ≤ g t := fun t ht => hc₀ t (le_trans (le_max_right _ _) ht)
  have hfc : ∀ B, IntervalIntegrable f volume c B := fun B => (hf c).symm.trans (hf B)
  have hgc : ∀ B, IntervalIntegrable g volume c B := fun B => (hg c).symm.trans (hg B)
  -- tail of g converges
  have hGc : Tendsto (fun B : ℝ => ∫ t in c..B, g t) atTop (𝓝 (G - ∫ t in a..c, g t)) := by
    refine (hG.sub_const (∫ t in a..c, g t)).congr' ?_
    filter_upwards with B
    rw [← intervalIntegral.integral_interval_sub_left (hg B) (hg c)]
  -- bound on tail of g
  have hbound : ∀ B, c ≤ B → ∫ t in c..B, g t ≤ G - ∫ t in a..c, g t := by
    intro B hB
    refine ge_of_tendsto hGc ?_
    filter_upwards [eventually_ge_atTop B] with B' hB'
    rw [← intervalIntegral.integral_add_adjacent_intervals (hgc B) ((hgc B).symm.trans (hgc B'))]
    have : 0 ≤ ∫ t in B..B', g t := by
      apply intervalIntegral.integral_nonneg hB'
      intro t ht
      exact le_trans (hc t (le_trans hB ht.1)).1 (hc t (le_trans hB ht.1)).2
    linarith
  have hfint_c : IntegrableOn f (Set.Ioi c) := by
    refine integrableOn_Ioi_of_intervalIntegral_norm_bounded (G - ∫ t in a..c, g t) c
      (fun B => (hfc B).1) tendsto_id ?_
    filter_upwards [eventually_ge_atTop c] with B hB
    have e : ∫ t in c..B, ‖f t‖ = ∫ t in c..B, f t := by
      apply intervalIntegral.integral_congr
      intro t ht
      rw [Set.uIcc_of_le hB] at ht
      exact Real.norm_of_nonneg (hc t ht.1).1
    rw [e]
    refine le_trans ?_ (hbound B hB)
    apply intervalIntegral.integral_mono_on hB (hfc B) (hgc B)
    intro t ht
    exact (hc t ht.1).2
  have hfint : IntegrableOn f (Set.Ioi a) := by
    have h1 : IntegrableOn f (Set.Ioc a c) := (hf c).1
    have := h1.union hfint_c
    refine this.mono_set ?_
    intro t ht
    by_cases h : t ≤ c
    · exact Or.inl ⟨ht, h⟩
    · exact Or.inr (lt_of_not_ge h)
  refine ⟨∫ t in Set.Ioi a, f t, intervalIntegral_tendsto_integral_Ioi a hfint tendsto_id, ?_⟩
  intro hall
  refine le_of_tendsto_of_tendsto (intervalIntegral_tendsto_integral_Ioi a hfint tendsto_id) hG ?_
  filter_upwards [eventually_ge_atTop a] with B hB
  exact intervalIntegral.integral_mono_on hB (hf B) (hg B) (fun t ht => (hall t ht.1).2)

-- Worked numbers, by hand.
-- The 1/t^2 tap from 1 to B pours 1 - 1/B: at B = 10, 100, 1000 that is 9/10, 99/100, 999/1000 litres.
example : (1 : ℚ) - 1 / 10 = 9 / 10 ∧ (1 : ℚ) - 1 / 100 = 99 / 100 ∧ (1 : ℚ) - 1 / 1000 = 999 / 1000 := by
  norm_num
-- Within 1/1000 of 1: the shortfall 1/B is too big at B = 999 and just enough at B = 1000.
example : (1 : ℚ) / 1000 < 1 / 999 ∧ (1 : ℚ) / 1000 ≤ 1 / 1000 := by norm_num
-- Doubling blocks of 1/t^2: block [2^j, 2^(j+1)] holds 1/2^j - 1/2^(j+1); the first four are 1/2, 1/4, 1/8, 1/16.
example : ((1 : ℚ) - 1 / 2 = 1 / 2) ∧ ((1 : ℚ) / 2 - 1 / 4 = 1 / 4) ∧
    ((1 : ℚ) / 4 - 1 / 8 = 1 / 8) ∧ ((1 : ℚ) / 8 - 1 / 16 = 1 / 16) := by norm_num
-- Ten blocks, minute 1 to 1024: the halving areas add to 1 - 1/1024.
example : (Finset.range 10).sum (fun j => (1 : ℚ) / 2 ^ (j + 1)) = 1 - 1 / 1024 := by norm_num [Finset.sum_range_succ]
-- Power rule at p = 3/2, 2, 3: 1/(p - 1) = 2, 1, 1/2 litres.
example : (1 : ℚ) / (3 / 2 - 1) = 2 ∧ (1 : ℚ) / (2 - 1) = 1 ∧ (1 : ℚ) / (3 - 1) = 1 / 2 := by norm_num
-- Spike 1/√t (p = 1/2): 1/(1 - p) = 2 litres; at gap s = 1/10000, √s = 1/100 and 2 - 2√s = 99/50 (1.98).
example : (1 : ℚ) / (1 - 1 / 2) = 2 ∧ (2 : ℚ) - 2 * (1 / 100) = 99 / 50 := by norm_num
-- Comparison turned round: 1/√t from 1 to B totals 2√B - 2, which is 18 at B = 100 (√B = 10) and 198 at B = 10000 (√B = 100).
example : (2 : ℚ) * 10 - 2 = 18 ∧ (2 : ℚ) * 100 - 2 = 198 := by norm_num
-- The spike of 1/t^2 from 1/1024 to 1: antiderivative -1/t gives -1 - (-1024) = 1023 litres.
example : (-1 : ℚ) / 1 - (-1 / (1 / 1024)) = 1023 := by norm_num
-- The usual mistake: -1/t read across 0 for 1/t^2 on -1 to 1 gives -2, a negative total from a positive rate.
example : (-1 : ℚ) / 1 - (-1 / (-1)) = -2 := by norm_num

#print axioms power_rule_at_infinity
#print axioms power_rule_at_spike
#print axioms comparison_test
