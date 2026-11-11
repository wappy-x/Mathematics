-- Power series: every power series has a radius R inside which it converges and can be differentiated and integrated term by term and outside which it fails, the coefficient ratios give R = 1/L, and the card's two series 1 + x + x² + ⋯ and x − x²/2 + x³/3 − ⋯ work exactly on −1 < x < 1 and −1 < x ≤ 1.
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.Analytic.OfScalars
import Mathlib.Analysis.Calculus.SmoothSeries
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.Analysis.Complex.AbelLimit
import Mathlib.Analysis.PSeries

open Finset Filter Topology
open scoped ENNReal

/-! Helper lemmas. -/

lemma ps_terms_tendsto_zero (f : ℕ → ℝ)
    (h : ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, f n) atTop (𝓝 s)) :
    Tendsto f atTop (𝓝 0) := by
  obtain ⟨s, hs⟩ := h
  have h1 := (hs.comp (tendsto_add_atTop_nat 1)).sub hs
  rw [sub_self] at h1
  refine h1.congr (fun N => ?_)
  simp [Function.comp, sum_range_succ]

lemma ps_summable_abs (a : ℕ → ℝ) {r : ℝ} (hr : 0 ≤ r)
    (h : ENNReal.ofReal r < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    Summable (fun n : ℕ => |a n| * r ^ n) := by
  have := (FormalMultilinearSeries.ofScalars ℝ a).summable_norm_mul_pow (r := r.toNNReal) h
  simpa [FormalMultilinearSeries.ofScalars_norm, Real.coe_toNNReal _ hr] using this

lemma ps_le_radius (a : ℕ → ℝ) {r : ℝ} (hr : 0 ≤ r)
    (h : Tendsto (fun n : ℕ => |a n| * r ^ n) atTop (𝓝 0)) :
    ENNReal.ofReal r ≤ (FormalMultilinearSeries.ofScalars ℝ a).radius := by
  apply (FormalMultilinearSeries.ofScalars ℝ a).le_radius_of_tendsto (l := 0)
  simpa [FormalMultilinearSeries.ofScalars_norm, Real.coe_toNNReal _ hr] using h

lemma ps_summable_deriv_bound (a : ℕ → ℝ) {r : ℝ} (hr : 0 < r)
    (h : ENNReal.ofReal r < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    Summable (fun n : ℕ => (n : ℝ) * |a n| * r ^ (n - 1)) := by
  obtain ⟨r2, hr2, h1, h2⟩ := ENNReal.lt_iff_exists_real_btwn.1 h
  have hrr2 : r < r2 := (ENNReal.ofReal_lt_ofReal_iff_of_nonneg hr.le).1 h1
  have hr2p : 0 < r2 := hr.trans hrr2
  have hs := (ps_summable_abs a hr2 h2).div_const r
  have hq : Tendsto (fun n : ℕ => (n : ℝ) * (r / r2) ^ n) atTop (𝓝 0) :=
    tendsto_self_mul_const_pow_of_lt_one (by positivity) ((div_lt_one hr2p).2 hrr2)
  have hev : ∀ᶠ n : ℕ in atTop, (n : ℝ) * (r / r2) ^ n ≤ 1 :=
    hq.eventually (ge_mem_nhds zero_lt_one)
  refine Summable.of_norm_bounded_eventually hs ?_
  rw [Nat.cofinite_eq_atTop]
  filter_upwards [hev] with n hn
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
  rcases n with _ | m
  · simp; positivity
  · have key : ((m + 1 : ℕ) : ℝ) * |a (m + 1)| * r ^ (m + 1 - 1)
        = ((m + 1 : ℕ) : ℝ) * (r / r2) ^ (m + 1) * (|a (m + 1)| * r2 ^ (m + 1) / r) := by
      simp only [Nat.add_sub_cancel, div_pow]
      field_simp
      ring
    rw [key]
    calc ((m + 1 : ℕ) : ℝ) * (r / r2) ^ (m + 1) * (|a (m + 1)| * r2 ^ (m + 1) / r)
        ≤ 1 * (|a (m + 1)| * r2 ^ (m + 1) / r) := by gcongr
      _ = |a (m + 1)| * r2 ^ (m + 1) / r := one_mul _
lemma ps_diverge_outside (a : ℕ → ℝ) (c x : ℝ)
    (hx : (FormalMultilinearSeries.ofScalars ℝ a).radius < ENNReal.ofReal |x - c|) :
    ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n * (x - c) ^ n) atTop (𝓝 s) := by
  intro h
  have h0 := (ps_terms_tendsto_zero _ h).abs
  simp only [abs_zero, abs_mul, abs_pow] at h0
  exact (ps_le_radius a (abs_nonneg _) h0).not_gt hx

lemma ps_deriv_diverge_outside (a : ℕ → ℝ) (c x : ℝ)
    (hx : (FormalMultilinearSeries.ofScalars ℝ a).radius < ENNReal.ofReal |x - c|) :
    ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, (n : ℝ) * a n * (x - c) ^ (n - 1))
      atTop (𝓝 s) := by
  intro h
  have h0 := (ps_terms_tendsto_zero _ h).abs
  simp only [abs_zero] at h0
  have h1 := (tendsto_const_div_atTop_nhds_zero_nat |x - c|).mul h0
  rw [mul_zero] at h1
  refine (ps_le_radius a (abs_nonneg _) (h1.congr' ?_)).not_gt hx
  filter_upwards [eventually_ge_atTop 1] with n hn
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  simp only [Nat.add_sub_cancel, abs_mul, abs_pow, Nat.abs_cast]
  push_cast
  field_simp
  ring

lemma ps_integ_diverge_outside (a : ℕ → ℝ) (c x : ℝ)
    (hx : (FormalMultilinearSeries.ofScalars ℝ a).radius < ENNReal.ofReal |x - c|) :
    ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n / (n + 1) * (x - c) ^ (n + 1))
      atTop (𝓝 s) := by
  intro h
  have h0 := (ps_terms_tendsto_zero _ h).abs
  simp only [abs_zero] at h0
  obtain ⟨r', hr'0, h1, h2⟩ := ENNReal.lt_iff_exists_real_btwn.1 hx
  have hlt : r' < |x - c| := (ENNReal.ofReal_lt_ofReal_iff'.1 h2).1
  have hpos : 0 < |x - c| := hr'0.trans_lt hlt
  have hq : Tendsto (fun n : ℕ => (n : ℝ) * (r' / |x - c|) ^ n) atTop (𝓝 0) :=
    tendsto_self_mul_const_pow_of_lt_one (by positivity) ((div_lt_one hpos).2 hlt)
  have hq' : Tendsto (fun n : ℕ => (r' / |x - c|) ^ n) atTop (𝓝 0) :=
    tendsto_pow_atTop_nhds_zero_of_lt_one (by positivity) ((div_lt_one hpos).2 hlt)
  have h3 := ((h0.mul (hq.add hq')).div_const |x - c|)
  simp only [add_zero, mul_zero, zero_div] at h3
  refine (ps_le_radius a hr'0 (h3.congr fun n => ?_)).not_gt h1
  simp only [abs_mul, abs_div, abs_pow, div_pow]
  rw [abs_of_pos (by positivity : (0 : ℝ) < n + 1)]
  field_simp
  ring

lemma ps_summable_inside (a : ℕ → ℝ) (c x : ℝ)
    (hx : ENNReal.ofReal |x - c| < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    Summable (fun n : ℕ => a n * (x - c) ^ n) :=
  (ps_summable_abs a (abs_nonneg _) hx).of_norm_bounded
    (fun n => le_of_eq (by rw [Real.norm_eq_abs, abs_mul, abs_pow]))

lemma ps_hasDeriv_inside (a : ℕ → ℝ) (c x : ℝ)
    (hx : ENNReal.ofReal |x - c| < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    ∃ D : ℝ, HasSum (fun n : ℕ => (n : ℝ) * a n * (x - c) ^ (n - 1)) D ∧
      HasDerivAt (fun y => ∑' n : ℕ, a n * (y - c) ^ n) D x := by
  obtain ⟨r, hr0, h1, h2⟩ := ENNReal.lt_iff_exists_real_btwn.1 hx
  have hlt : |x - c| < r := (ENNReal.ofReal_lt_ofReal_iff'.1 h1).1
  have hrpos : 0 < r := (abs_nonneg _).trans_lt hlt
  have hu := ps_summable_deriv_bound a hrpos h2
  have hxmem : x ∈ Metric.ball c r := by rwa [Metric.mem_ball, Real.dist_eq]
  have hbound : ∀ (n : ℕ) (y : ℝ), y ∈ Metric.ball c r →
      ‖(n : ℝ) * a n * (y - c) ^ (n - 1)‖ ≤ (n : ℝ) * |a n| * r ^ (n - 1) := by
    intro n y hy
    rw [Metric.mem_ball, Real.dist_eq] at hy
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_pow, Nat.abs_cast]
    gcongr
  have hderiv : ∀ (n : ℕ) (y : ℝ), y ∈ Metric.ball c r →
      HasDerivAt (fun z => a n * (z - c) ^ n) ((n : ℝ) * a n * (y - c) ^ (n - 1)) y := by
    intro n y _
    have := ((hasDerivAt_pow n (y - c)).comp_sub_const y c).const_mul (a n)
    convert this using 1
    ring
  refine ⟨_, (hu.of_norm_bounded (fun n => hbound n x hxmem)).hasSum, ?_⟩
  exact hasDerivAt_tsum_of_isPreconnected hu Metric.isOpen_ball (convex_ball c r).isPreconnected
    hderiv hbound hxmem (ps_summable_inside a c x hx) hxmem

lemma ps_integral_inside (a : ℕ → ℝ) (c x : ℝ)
    (hx : ENNReal.ofReal |x - c| < (FormalMultilinearSeries.ofScalars ℝ a).radius) :
    HasSum (fun n : ℕ => a n / (n + 1) * (x - c) ^ (n + 1))
      (∫ t in c..x, ∑' n : ℕ, a n * (t - c) ^ n) := by
  have hs := ps_summable_abs a (abs_nonneg _) hx
  have hb : ∀ n, ∀ t ∈ Set.uIcc c x, ‖a n * (t - c) ^ n‖ ≤ |a n| * |x - c| ^ n := by
    intro n t ht
    rw [Real.norm_eq_abs, abs_mul, abs_pow]
    exact mul_le_mul_of_nonneg_left
      (pow_le_pow_left₀ (abs_nonneg _) (Set.abs_sub_left_of_mem_uIcc ht) n) (abs_nonneg _)
  have h := intervalIntegral.hasSum_integral_of_dominated_convergence
    (μ := MeasureTheory.volume) (a := c) (b := x)
    (F := fun n t => a n * (t - c) ^ n) (f := fun t => ∑' n : ℕ, a n * (t - c) ^ n)
    (fun n _ => |a n| * |x - c| ^ n)
    (fun n => (by fun_prop : Continuous fun t : ℝ => a n * (t - c) ^ n).aestronglyMeasurable)
    (fun n => MeasureTheory.ae_of_all _ fun t ht => hb n t (Set.uIoc_subset_uIcc ht))
    (MeasureTheory.ae_of_all _ fun t _ => hs)
    intervalIntegrable_const
    (MeasureTheory.ae_of_all _ fun t ht =>
      (hs.of_norm_bounded (fun n => hb n t (Set.uIoc_subset_uIcc ht))).hasSum)
  convert h using 1
  funext n
  rw [intervalIntegral.integral_const_mul,
    intervalIntegral.integral_comp_sub_right (fun t => t ^ n), integral_pow]
  simp only [sub_self, ne_eq, Nat.add_eq_zero_iff, one_ne_zero, and_false, not_false_eq_true,
    zero_pow, sub_zero]
  ring

lemma ps_Icc_eq_range (f : ℕ → ℝ) (hf : f 0 = 0) (N : ℕ) :
    ∑ n ∈ Icc (1 : ℕ) N, f n = ∑ n ∈ range (N + 1), f n := by
  induction N with
  | zero => simp [hf]
  | succ N ih => rw [sum_Icc_succ_top (by omega), ih, sum_range_succ _ (N + 1)]

lemma ps_log_hasSum {x : ℝ} (hx : |x| < 1) :
    HasSum (fun n : ℕ => (-1 : ℝ) ^ (n + 1) / n * x ^ n) (Real.log (1 + x)) := by
  have h0 : |-x| < 1 := by rwa [abs_neg]
  have h := (Real.hasSum_pow_div_log_of_abs_lt_one h0).neg
  rw [sub_neg_eq_add, neg_neg] at h
  have h2 : HasSum (fun n : ℕ => (-1 : ℝ) ^ (n + 1 + 1) / ((n + 1 : ℕ) : ℝ) * x ^ (n + 1))
      (Real.log (1 + x)) := by
    refine h.congr_fun (fun n => ?_)
    push_cast
    rw [neg_pow]
    ring
  have h3 := (hasSum_nat_add_iff (f := fun n : ℕ => (-1 : ℝ) ^ (n + 1) / n * x ^ n) 1).mp h2
  simpa using h3

lemma ps_geom_tendsto (x : ℝ) (hx : x ∈ Set.Ioo (-1 : ℝ) 1) :
    Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), x ^ n) atTop (𝓝 (1 / (1 - x))) := by
  have h := (hasSum_geometric_of_abs_lt_one (abs_lt.2 hx)).tendsto_sum_nat
  rw [one_div]
  exact h.comp (tendsto_add_atTop_nat 1)

lemma ps_geom_conv (x : ℝ)
    (h : ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), x ^ n) atTop (𝓝 s)) :
    x ∈ Set.Ioo (-1 : ℝ) 1 := by
  obtain ⟨s, hs⟩ := h
  have h0 := ps_terms_tendsto_zero (fun n => x ^ n)
    ⟨s, (tendsto_add_atTop_iff_nat 1).1 hs⟩
  exact abs_lt.1 (tendsto_pow_atTop_nhds_zero_iff.1 h0)

lemma ps_log_tendsto (x : ℝ) (hx : x ∈ Set.Ioc (-1 : ℝ) 1) :
    Tendsto (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
      atTop (𝓝 (Real.log (1 + x))) := by
  have heq : (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
      = fun N : ℕ => ∑ n ∈ range (N + 1), (-1 : ℝ) ^ (n + 1) / n * x ^ n :=
    funext fun N => ps_Icc_eq_range _ (by simp) N
  rw [heq, tendsto_add_atTop_iff_nat 1
    (f := fun N : ℕ => ∑ n ∈ range N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)]
  rcases hx.2.lt_or_eq with h | rfl
  · exact (ps_log_hasSum (abs_lt.2 ⟨hx.1, h⟩)).tendsto_sum_nat
  · obtain ⟨l, hl⟩ : ∃ l, Tendsto (fun N : ℕ => ∑ n ∈ range N, (-1 : ℝ) ^ (n + 1) / n * 1 ^ n)
        atTop (𝓝 l) := by
      obtain ⟨l, hl⟩ := Antitone.tendsto_alternating_series_of_tendsto_zero
        (f := fun i : ℕ => 1 / ((i : ℝ) + 1))
        (fun i j hij => by
          simp only
          gcongr)
        tendsto_one_div_add_atTop_nhds_zero_nat
      refine ⟨l, (tendsto_add_atTop_iff_nat 1).1 (hl.congr fun N => ?_)⟩
      rw [sum_range_succ']
      simp only [one_pow, mul_one, CharP.cast_eq_zero, div_zero, add_zero]
      refine sum_congr rfl fun i _ => ?_
      push_cast
      ring
    have habel := Real.tendsto_tsum_powerSeries_nhdsWithin_lt
      (f := fun n : ℕ => (-1 : ℝ) ^ (n + 1) / n) (l := l)
      (by simpa only [one_pow, mul_one] using hl)
    have hlog : Tendsto (fun y : ℝ => ∑' n : ℕ, (-1 : ℝ) ^ (n + 1) / n * y ^ n) (𝓝[<] 1)
        (𝓝 (Real.log (1 + 1))) := by
      have hc : Tendsto (fun y : ℝ => Real.log (1 + y)) (𝓝[<] 1) (𝓝 (Real.log (1 + 1))) :=
        ((show ContinuousAt (fun y : ℝ => 1 + y) 1 by fun_prop).log
          (by norm_num)).tendsto.mono_left nhdsWithin_le_nhds
      refine hc.congr' ?_
      filter_upwards [Ioo_mem_nhdsLT (show (0 : ℝ) < 1 by norm_num)] with y hy
      exact ((ps_log_hasSum (abs_lt.2 ⟨by linarith [hy.1], hy.2⟩)).tsum_eq).symm
    rw [← tendsto_nhds_unique habel hlog]
    exact hl

lemma ps_log_conv (x : ℝ)
    (h : ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
      atTop (𝓝 s)) :
    x ∈ Set.Ioc (-1 : ℝ) 1 := by
  obtain ⟨s, hs⟩ := h
  have heq : (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
      = fun N : ℕ => ∑ n ∈ range (N + 1), (-1 : ℝ) ^ (n + 1) / n * x ^ n :=
    funext fun N => ps_Icc_eq_range _ (by simp) N
  rw [heq] at hs
  have hs' := (tendsto_add_atTop_iff_nat 1
    (f := fun N : ℕ => ∑ n ∈ range N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)).1 hs
  have h0 := ps_terms_tendsto_zero _ ⟨s, hs'⟩
  by_contra hx
  have hx' : 1 < |x| ∨ x = -1 := by
    rw [Set.mem_Ioc, not_and_or, not_lt, not_le] at hx
    rcases hx with h | h
    · rcases h.lt_or_eq with h | h
      · left; rw [abs_of_neg (by linarith)]; linarith
      · right; exact h
    · left; rw [abs_of_pos (by linarith)]; exact h
  rcases hx' with hgt | rfl
  · have h1 := tendsto_pow_const_div_const_pow_of_one_lt 1 hgt
    have h2 := h0.abs.mul h1
    rw [abs_zero, zero_mul] at h2
    have h3 : Tendsto (fun _ : ℕ => (1 : ℝ)) atTop (𝓝 0) := by
      refine h2.congr' ?_
      filter_upwards [eventually_ge_atTop 1] with n hn
      have hn' : (n : ℝ) ≠ 0 := by positivity
      have hxn : |x| ^ n ≠ 0 := by positivity
      simp only [abs_mul, abs_div, abs_pow, abs_neg, abs_one, one_pow, Nat.abs_cast, pow_one]
      field_simp
    exact one_ne_zero (tendsto_nhds_unique tendsto_const_nhds h3)
  · have hH := Real.tendsto_sum_range_one_div_nat_succ_atTop
    refine not_tendsto_nhds_of_tendsto_atTop hH (-s) (hs.neg.congr fun N => ?_)
    rw [sum_range_succ']
    simp only [CharP.cast_eq_zero, div_zero, zero_mul, add_zero, ← sum_neg_distrib]
    refine sum_congr rfl fun i _ => ?_
    have h1 : ((-1 : ℝ)) ^ (i + 1 + 1) * (-1) ^ (i + 1) = -1 := by
      rw [← pow_add]
      exact Odd.neg_one_pow ⟨i + 1, by ring⟩
    push_cast
    rw [div_mul_eq_mul_div, h1]
    ring

#print axioms ps_terms_tendsto_zero
#print axioms ps_summable_abs
#print axioms ps_le_radius
#print axioms ps_summable_deriv_bound
#print axioms ps_diverge_outside
#print axioms ps_deriv_diverge_outside
#print axioms ps_integ_diverge_outside
#print axioms ps_summable_inside
#print axioms ps_hasDeriv_inside
#print axioms ps_integral_inside
#print axioms ps_Icc_eq_range
#print axioms ps_log_hasSum
#print axioms ps_geom_tendsto
#print axioms ps_geom_conv
#print axioms ps_log_tendsto
#print axioms ps_log_conv

/-- The radius of convergence. Take any coefficients a₀, a₁, a₂, … and any centre c, and let
f(y) = a₀ + a₁(y − c) + a₂(y − c)² + ⋯ . There is one radius R, a distance from 0 up to
infinity, such that:
* at every input x nearer c than R, the series a₀ + a₁(x − c) + ⋯ converges;
* at every input farther than R, its running totals head for no number at all;
* strictly inside R, f has a slope, and the slope is the differentiated series
  ∑ n aₙ (x − c)^(n−1), which converges there;
* strictly inside R, the area under f from c to x is the integrated series
  ∑ aₙ/(n + 1) (x − c)^(n+1), which converges there;
* farther than R, the differentiated and integrated series fail too, so both have radius R.
At distance exactly R nothing is claimed: the endpoints are tested one by one. -/
theorem power_series_has_radius_of_convergence (a : ℕ → ℝ) (c : ℝ) :
    ∃ R : ℝ≥0∞,
      (∀ x : ℝ, ENNReal.ofReal |x - c| < R →
        Summable (fun n : ℕ => a n * (x - c) ^ n)) ∧
      (∀ x : ℝ, R < ENNReal.ofReal |x - c| →
        ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n * (x - c) ^ n) atTop (𝓝 s)) ∧
      (∀ x : ℝ, ENNReal.ofReal |x - c| < R →
        ∃ D : ℝ, HasSum (fun n : ℕ => (n : ℝ) * a n * (x - c) ^ (n - 1)) D ∧
          HasDerivAt (fun y => ∑' n : ℕ, a n * (y - c) ^ n) D x) ∧
      (∀ x : ℝ, ENNReal.ofReal |x - c| < R →
        HasSum (fun n : ℕ => a n / (n + 1) * (x - c) ^ (n + 1))
          (∫ t in c..x, ∑' n : ℕ, a n * (t - c) ^ n)) ∧
      (∀ x : ℝ, R < ENNReal.ofReal |x - c| →
        (¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, (n : ℝ) * a n * (x - c) ^ (n - 1))
            atTop (𝓝 s)) ∧
        (¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n / (n + 1) * (x - c) ^ (n + 1))
            atTop (𝓝 s))) := by
  exact ⟨(FormalMultilinearSeries.ofScalars ℝ a).radius,
    fun x hx => ps_summable_inside a c x hx,
    fun x hx => ps_diverge_outside a c x hx,
    fun x hx => ps_hasDeriv_inside a c x hx,
    fun x hx => ps_integral_inside a c x hx,
    fun x hx => ⟨ps_deriv_diverge_outside a c x hx, ps_integ_diverge_outside a c x hx⟩⟩

/-- The ratio test measures the fence. If no coefficient is zero and the neighbouring ratios
|aₙ₊₁/aₙ| head for a limit L, then the radius is R = 1/L (with 1/0 read as infinity: L = 0
means no fence): the series converges at every x with |x − c| < 1/L, and its running totals
head for no number at every x with |x − c| > 1/L. -/
theorem radius_is_one_over_ratio_limit (a : ℕ → ℝ) (c L : ℝ) (ha : ∀ n, a n ≠ 0)
    (hL : Tendsto (fun n : ℕ => |a (n + 1) / a n|) atTop (𝓝 L)) :
    (∀ x : ℝ, ENNReal.ofReal |x - c| < (ENNReal.ofReal L)⁻¹ →
      Summable (fun n : ℕ => a n * (x - c) ^ n)) ∧
    (∀ x : ℝ, (ENNReal.ofReal L)⁻¹ < ENNReal.ofReal |x - c| →
      ¬ ∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range N, a n * (x - c) ^ n) atTop (𝓝 s)) := by
  have hL0 : 0 ≤ L := ge_of_tendsto' hL (fun n => abs_nonneg _)
  have hc : Tendsto (fun n : ℕ => ‖a n.succ‖ / ‖a n‖) atTop (𝓝 L) := by
    simpa [Real.norm_eq_abs, abs_div] using hL
  have hR : (FormalMultilinearSeries.ofScalars ℝ a).radius = (ENNReal.ofReal L)⁻¹ := by
    rcases hL0.eq_or_lt with h | h
    · subst h
      rw [ENNReal.ofReal_zero, ENNReal.inv_zero]
      exact FormalMultilinearSeries.ofScalars_radius_eq_top_of_tendsto ℝ a
        (Eventually.of_forall ha) hc
    · have hne : L.toNNReal ≠ 0 := by simpa using h
      rw [FormalMultilinearSeries.ofScalars_radius_eq_inv_of_tendsto ℝ a hne
        (by rwa [Real.coe_toNNReal _ hL0]), ENNReal.coe_inv hne]
      rfl
  rw [← hR]
  exact ⟨fun x hx => ps_summable_inside a c x hx, fun x hx => ps_diverge_outside a c x hx⟩

/-- Same radius, different endpoints. Both of the card's series have radius 1, yet:
the running totals 1 + x + ⋯ + x^N settle on some number exactly when −1 < x < 1, and then
on 1/(1 − x); the running totals x − x²/2 + x³/3 − ⋯ ± x^N/N settle on some number exactly
when −1 < x ≤ 1, and then on ln(1 + x), so at x = 1 on ln 2. -/
theorem geometric_and_log_series_where_they_work :
    (∀ x : ℝ, (∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), x ^ n) atTop (𝓝 s)) ↔
        x ∈ Set.Ioo (-1) 1) ∧
    (∀ x ∈ Set.Ioo (-1 : ℝ) 1,
        Tendsto (fun N : ℕ => ∑ n ∈ range (N + 1), x ^ n) atTop (𝓝 (1 / (1 - x)))) ∧
    (∀ x : ℝ, (∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
          atTop (𝓝 s)) ↔ x ∈ Set.Ioc (-1) 1) ∧
    (∀ x ∈ Set.Ioc (-1 : ℝ) 1,
        Tendsto (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) N, (-1 : ℝ) ^ (n + 1) / n * x ^ n)
          atTop (𝓝 (Real.log (1 + x)))) := by
  exact ⟨fun x => ⟨ps_geom_conv x, fun hx => ⟨_, ps_geom_tendsto x hx⟩⟩, ps_geom_tendsto,
    fun x => ⟨ps_log_conv x, fun hx => ⟨_, ps_log_tendsto x hx⟩⟩, ps_log_tendsto⟩

/-! The card's exact worked numbers. -/

-- 1/(1 − x) at x = 1: through x^99 the sum 1 + 1 + ⋯ + 1 is 100.
example : ∑ n ∈ range 100, (1 : ℤ) ^ n = 100 := by
  norm_num

-- 1/(1 − x) at x = −1: the running totals run 1, 0, 1, 0, 1, 0.
example : (List.range 6).map (fun N : ℕ => ∑ n ∈ range (N + 1), (-1 : ℤ) ^ n) = [1, 0, 1, 0, 1, 0] := by
  decide

-- The log's slope series at x = 1, 1 − 1 + 1 − ⋯ (term n is n · (−1)^(n+1)/n · 1^(n−1)):
-- running totals 1, 0, 1, 0, 1, 0.
example : (List.range 6).map (fun N : ℕ => ∑ n ∈ Icc (1 : ℕ) (N + 1), (-1 : ℤ) ^ (n + 1))
    = [1, 0, 1, 0, 1, 0] := by
  decide

-- Geometric at 1/2 through x^20: 2 − (1/2)^20 (the card's 1.999999046).
example : ∑ n ∈ range 21, (1 / 2 : ℚ) ^ n = 2 - (1 / 2) ^ 20 := by
  norm_num [Finset.sum_range_succ]

-- First four log terms at 1/2: 1/2, −1/8, 1/24, −1/64 (the card's 0.500000, −0.125000,
-- 0.041667, −0.015625).
example : [1, 2, 3, 4].map (fun n : ℕ => (-1 : ℚ) ^ (n + 1) / n * (1 / 2) ^ n)
    = [1 / 2, -1 / 8, 1 / 24, -1 / 64] := by
  norm_num

-- Slope of 1/(1 − x) at 1/2, through 20x^19: 1 + 2(1/2) + ⋯ + 20(1/2)^19 = 4 − 44/2^20
-- (the card's 3.999958038, against 4 = 1/(1 − 1/2)^2).
example : ∑ n ∈ Icc (1 : ℕ) 20, (n : ℚ) * (1 / 2) ^ (n - 1) = 4 - 44 / 2 ^ 20 ∧
    (1 : ℚ) / (1 - 1 / 2) ^ 2 = 4 := by
  norm_num [Finset.sum_Icc_succ_top]

-- Outside the fence at x = 2, 1/(1 − x) is −1 but the terms run 1, 2, 4, 8.
example : (1 : ℚ) / (1 - 2) = -1 ∧ (List.range 4).map (fun n : ℕ => (2 : ℤ) ^ n) = [1, 2, 4, 8] := by
  norm_num [List.range_succ]

#print axioms power_series_has_radius_of_convergence
#print axioms radius_is_one_over_ratio_limit
#print axioms geometric_and_log_series_where_they_work
