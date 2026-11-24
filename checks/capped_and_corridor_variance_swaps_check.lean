-- Capped and corridor variance: the corridor swap's fair strike is the one-over-strike-squared option strip cut to the band's strikes, the capped swap's fair strike is the plain one less a call on realised variance, and the corridor log payoff has dollar gamma 2 inside the band and 0 outside.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.Prod

open MeasureTheory

/-- The card's `c(y)`: a price `y` clamped into the band `[L, U]`. -/
noncomputable def bandClamp (L U y : ℝ) : ℝ := max L (min y U)

/-- The card's helper `J(y)`: `(y - L)/L` below the band, `ln(y/L)` inside it,
and `ln(U/L) + (y - U)/U` above it. -/
noncomputable def corridorJ (L U y : ℝ) : ℝ :=
  if y < L then (y - L) / L
  else if y ≤ U then Real.log (y / L)
  else Real.log (U / L) + (y - U) / U

/-- The corridor log payoff of Why it works, in the card's closed form:
`g(y) = 2 [(y - F)/c(F) - (J(y) - J(F))]`, with `F` the forward. -/
noncomputable def corridorLogPayoff (L U F y : ℝ) : ℝ :=
  2 * ((y - F) / bandClamp L U F - (corridorJ L U y - corridorJ L U F))

lemma corridorJ_hasDerivWithinAt_Iic (L U y : ℝ) (hL : 0 < L) (hLU : L ≤ U) :
    HasDerivWithinAt (corridorJ L U) (1 / bandClamp L U y) (Set.Iic y) y := by
  rcases le_or_gt y L with h1 | h1
  · have hc : bandClamp L U y = L := by
      unfold bandClamp; exact max_eq_left ((min_le_left _ _).trans h1)
    rw [hc]
    have hd : HasDerivAt (fun z : ℝ => (z - L) / L) (1 / L) y := by
      simpa using (hasDerivAt_id y).sub_const L |>.div_const L
    refine hd.hasDerivWithinAt.congr_of_mem (fun z hz => ?_) (Set.mem_Iic.2 le_rfl)
    have hz' : z ≤ L := (Set.mem_Iic.1 hz).trans h1
    unfold corridorJ
    rcases lt_or_eq_of_le hz' with h | h
    · simp [h]
    · subst h; simp [hLU, hL.ne']
  rcases le_or_gt y U with h2 | h2
  · have hc : bandClamp L U y = y := by
      unfold bandClamp; rw [min_eq_left h2]; exact max_eq_right h1.le
    rw [hc]
    have hy0 : y ≠ 0 := (hL.trans h1).ne'
    have hd : HasDerivAt (fun z : ℝ => Real.log z - Real.log L) (1 / y) y := by
      simpa using (Real.hasDerivAt_log hy0).sub_const (Real.log L)
    refine hd.hasDerivWithinAt.congr_of_eventuallyEq ?_ ?_
    · filter_upwards [Ioc_mem_nhdsLE h1] with z hz
      have hz0 : z ≠ 0 := (hL.trans hz.1).ne'
      simp only [corridorJ, not_lt.2 hz.1.le, ite_false, hz.2.trans h2, ite_true]
      rw [Real.log_div hz0 hL.ne']
    · simp only [corridorJ, not_lt.2 h1.le, ite_false, h2, ite_true]
      rw [Real.log_div hy0 hL.ne']
  · have hc : bandClamp L U y = U := by
      unfold bandClamp; rw [min_eq_right h2.le]; exact max_eq_right hLU
    rw [hc]
    have hd : HasDerivAt (fun z : ℝ => Real.log (U / L) + (z - U) / U) (1 / U) y := by
      simpa using ((hasDerivAt_id y).sub_const U |>.div_const U).const_add (Real.log (U / L))
    refine hd.hasDerivWithinAt.congr_of_eventuallyEq ?_ ?_
    · filter_upwards [Ioc_mem_nhdsLE h2] with z hz
      simp only [corridorJ, not_lt.2 (hLU.trans hz.1.le), ite_false, not_le.2 hz.1]
    · simp only [corridorJ, not_lt.2 (hLU.trans h2.le), ite_false, not_le.2 h2]

#print axioms corridorJ_hasDerivWithinAt_Iic

lemma strip_ftc (y p q : ℝ) (hp : 0 < p) (hpq : p ≤ q) :
    ∫ K in p..q, (K - y) / K ^ 2 = (Real.log q + y / q) - (Real.log p + y / p) := by
  have hpos : ∀ x ∈ Set.uIcc p q, 0 < x := by
    intro x hx
    rw [Set.uIcc_of_le hpq] at hx
    exact hp.trans_le hx.1
  refine intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun K => Real.log K + y / K)
    (fun x hx => ?_) ?_
  · have hx0 := (hpos x hx).ne'
    have := (Real.hasDerivAt_log hx0).add ((hasDerivAt_inv hx0).const_mul y)
    convert this using 1
    · funext K; simp [div_eq_mul_inv]
    · field_simp
      ring
  · refine ContinuousOn.intervalIntegrable ?_
    refine ContinuousOn.div (by fun_prop) (by fun_prop) (fun x hx => ?_)
    exact pow_ne_zero 2 (hpos x hx).ne'

#print axioms strip_ftc

lemma strip_intervalIntegrable (g : ℝ → ℝ) (hg : Continuous g) (p q : ℝ) (hp : 0 < p)
    (hpq : p ≤ q) : IntervalIntegrable (fun K => g K / K ^ 2) volume p q := by
  refine ContinuousOn.intervalIntegrable ?_
  refine ContinuousOn.div hg.continuousOn (by fun_prop) (fun x hx => ?_)
  rw [Set.uIcc_of_le hpq] at hx
  exact pow_ne_zero 2 (hp.trans_le hx.1).ne'

#print axioms strip_intervalIntegrable

lemma put_strip (a b y : ℝ) (ha : 0 < a) (hab : a ≤ b) :
    ∫ K in a..b, max (K - y) 0 / K ^ 2 =
      (Real.log b + y / b) - (Real.log (max a (min y b)) + y / max a (min y b)) := by
  rcases le_or_gt y a with h1 | h1
  · have hc : max a (min y b) = a := max_eq_left ((min_le_left _ _).trans h1)
    rw [hc, ← strip_ftc y a b ha hab]
    refine intervalIntegral.integral_congr (fun K hK => ?_)
    rw [Set.uIcc_of_le hab] at hK
    rw [max_eq_left (by linarith [hK.1])]
  rcases le_or_gt y b with h2 | h2
  · have hc : max a (min y b) = y := by rw [min_eq_left h2]; exact max_eq_right h1.le
    rw [hc, ← intervalIntegral.integral_add_adjacent_intervals
      (strip_intervalIntegrable _ (by fun_prop) a y ha h1.le)
      (strip_intervalIntegrable _ (by fun_prop) y b (ha.trans h1) h2)]
    have e1 : ∫ K in a..y, max (K - y) 0 / K ^ 2 = 0 := by
      have : Set.EqOn (fun K => max (K - y) 0 / K ^ 2) (fun _ => (0 : ℝ)) (Set.uIcc a y) := by
        intro K hK
        rw [Set.uIcc_of_le h1.le] at hK
        simp only
        rw [max_eq_right (by linarith [hK.2])]; simp
      rw [intervalIntegral.integral_congr this]
      simp
    rw [e1, zero_add, ← strip_ftc y y b (ha.trans h1) h2]
    refine intervalIntegral.integral_congr (fun K hK => ?_)
    rw [Set.uIcc_of_le h2] at hK
    rw [max_eq_left (by linarith [hK.1])]
  · have hc : max a (min y b) = b := by rw [min_eq_right h2.le]; exact max_eq_right hab
    rw [hc, sub_self]
    have : Set.EqOn (fun K => max (K - y) 0 / K ^ 2) (fun _ => (0 : ℝ)) (Set.uIcc a b) := by
      intro K hK
      rw [Set.uIcc_of_le hab] at hK
      simp only
      rw [max_eq_right (by linarith [hK.2])]; simp
    rw [intervalIntegral.integral_congr this]
    simp

#print axioms put_strip

lemma call_strip (a b y : ℝ) (ha : 0 < a) (hab : a ≤ b) :
    ∫ K in a..b, max (y - K) 0 / K ^ 2 =
      (Real.log a + y / a) - (Real.log (max a (min y b)) + y / max a (min y b)) := by
  have e : ∫ K in a..b, max (y - K) 0 / K ^ 2 =
      ∫ K in a..b, (max (K - y) 0 / K ^ 2 - (K - y) / K ^ 2) := by
    refine intervalIntegral.integral_congr (fun K _ => ?_)
    rw [← sub_div]
    congr 1
    rcases le_total K y with h | h
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
  rw [e, intervalIntegral.integral_sub
    (strip_intervalIntegrable _ (by fun_prop) a b ha hab)
    (strip_intervalIntegrable _ (by fun_prop) a b ha hab), put_strip a b y ha hab,
    strip_ftc y a b ha hab]
  ring

#print axioms call_strip

lemma corridorJ_eq (L U y : ℝ) (hL : 0 < L) (hLU : L ≤ U) :
    corridorJ L U y =
      Real.log (bandClamp L U y) - Real.log L + y / bandClamp L U y - 1 := by
  unfold corridorJ bandClamp
  split_ifs with h1 h2
  · rw [max_eq_left ((min_le_left _ _).trans h1.le)]
    field_simp
    ring
  · rw [min_eq_left h2, max_eq_right (not_lt.1 h1)]
    have hy : 0 < y := hL.trans_le (not_lt.1 h1)
    rw [Real.log_div hy.ne' hL.ne', div_self hy.ne']
    ring
  · rw [min_eq_right (not_le.1 h2).le, max_eq_right hLU]
    have hU : 0 < U := hL.trans_le hLU
    rw [Real.log_div hU.ne' hL.ne']
    field_simp
    ring

#print axioms corridorJ_eq

lemma payoff_eq_strip (L U F y : ℝ) (hL : 0 < L) (hLU : L ≤ U) :
    corridorLogPayoff L U F y =
      2 * ∫ K in L..U, (if K < F then max (K - y) 0 else max (y - K) 0) / K ^ 2 := by
  set m := bandClamp L U F with hm
  have hLm : L ≤ m := le_max_left _ _
  have hmU : m ≤ U := max_le hLU (min_le_right _ _)
  have hm0 : 0 < m := hL.trans_le hLm
  have eq1 : Set.EqOn (fun K => (if K < F then max (K - y) 0 else max (y - K) 0) / K ^ 2)
      (fun K => max (K - y) 0 / K ^ 2) (Set.Ioo L m) := by
    intro K hK
    have : K < F := by
      rcases lt_max_iff.1 hK.2 with h | h
      · exact absurd hK.1 (not_lt.2 h.le)
      · exact h.trans_le (min_le_left _ _)
    simp [this]
  have eq2 : Set.EqOn (fun K => (if K < F then max (K - y) 0 else max (y - K) 0) / K ^ 2)
      (fun K => max (y - K) 0 / K ^ 2) (Set.Ioo m U) := by
    intro K hK
    have : ¬ K < F := by
      have h3 : min F U < K := (le_max_right _ _).trans_lt hK.1
      rcases min_lt_iff.1 h3 with h | h
      · exact not_lt.2 h.le
      · exact absurd hK.2 (not_lt.2 h.le)
    simp [this]
  have i1 := (strip_intervalIntegrable (fun K => max (K - y) 0) (by fun_prop) L m hL hLm).congr_uIoo
    (by rw [Set.uIoo_of_le hLm]; exact eq1.symm)
  have i2 := (strip_intervalIntegrable (fun K => max (y - K) 0) (by fun_prop) m U hm0 hmU).congr_uIoo
    (by rw [Set.uIoo_of_le hmU]; exact eq2.symm)
  rw [← intervalIntegral.integral_add_adjacent_intervals i1 i2,
    intervalIntegral.integral_congr_Ioo_of_le hLm eq1,
    intervalIntegral.integral_congr_Ioo_of_le hmU eq2, put_strip L m y hL hLm,
    call_strip m U y hm0 hmU]
  unfold corridorLogPayoff
  rw [corridorJ_eq L U y hL hLU, corridorJ_eq L U F hL hLU, ← hm]
  have hc0 : 0 < bandClamp L U y := hL.trans_le (le_max_left _ _)
  rcases le_total y m with h | h
  · have ha : max L (min y m) = bandClamp L U y := by
      unfold bandClamp
      rw [min_eq_left h, min_eq_left (h.trans hmU)]
    have hb : max m (min y U) = m := max_eq_left ((min_le_left _ _).trans h)
    rw [ha, hb]
    field_simp
    ring
  · have ha : max L (min y m) = m := by rw [min_eq_right h]; exact max_eq_right hLm
    have hb : max m (min y U) = bandClamp L U y := by
      unfold bandClamp
      rw [max_eq_right (le_min h hmU), max_eq_right (hLm.trans (le_min h hmU))]
    rw [ha, hb]
    field_simp
    ring

#print axioms payoff_eq_strip

/-- The card's main claim, the corridor fair strike (Step 2). Take any pricing-world
distribution `μ` of the final price `S_T` (positive prices, a finite average equal to the
forward `F`), a band `[L, U]` with `0 < L ≤ U`, a rate `r` and `T > 0` years, and options at
every strike inside the band, priced as discounted average payoffs: the put
`P(K) = e^{-rT} E[(K - S_T)^+]` and the call `C(K) = e^{-rT} E[(S_T - K)^+]`. Let `Q(K)` be the
out-of-the-money one, the put below the forward and the call at or above it. Then the fair
corridor strike `(1/T) E[g(S_T)]`, the average of the corridor log payoff, equals
`(2 e^{rT} / T) ∫_L^U Q(K)/K^2 dK`: the plain swap's strip with the strikes outside the band
thrown away. (Step 1, that the hedged corridor log payoff earns corridor variance along a
continuous path, is Ito calculus, which Mathlib does not have; this theorem is Step 2.) -/
theorem corridor_fair_strike_eq_strip_inside_band
    (μ : Measure ℝ) [IsProbabilityMeasure μ] (r T F L U : ℝ) (hT : 0 < T) (hF : 0 < F)
    (hL : 0 < L) (hLU : L ≤ U) (hpos : ∀ᵐ s ∂μ, 0 < s)
    (hint : Integrable (fun s : ℝ => s) μ) (hmean : ∫ s, s ∂μ = F) :
    (1 / T) * ∫ s, corridorLogPayoff L U F s ∂μ =
      2 * Real.exp (r * T) / T *
        ∫ K in L..U,
          (if K < F then Real.exp (-(r * T)) * ∫ s, max (K - s) 0 ∂μ
           else Real.exp (-(r * T)) * ∫ s, max (s - K) 0 ∂μ) / K ^ 2 := by
  set f : ℝ → ℝ → ℝ := fun s K => (if K < F then max (K - s) 0 else max (s - K) 0) / K ^ 2
    with hf
  have hpt : ∀ s, corridorLogPayoff L U F s = 2 * ∫ K in L..U, f s K :=
    fun s => payoff_eq_strip L U F s hL hLU
  have hmeas : Measurable (Function.uncurry f) := by
    refine Measurable.div ?_ (by fun_prop)
    exact Measurable.ite (measurableSet_lt measurable_snd measurable_const) (by fun_prop)
      (by fun_prop)
  have hprod : Integrable (Function.uncurry f) (μ.prod (volume.restrict (Set.Ioc L U))) := by
    refine Integrable.mono' (g := fun p : ℝ × ℝ => (|p.1| + U) / L ^ 2)
      (((hint.abs.add (integrable_const U)).div_const (L ^ 2)).comp_fst _)
      hmeas.aestronglyMeasurable ?_
    have hmem : ∀ᵐ p ∂(μ.prod (volume.restrict (Set.Ioc L U))), p.2 ∈ Set.Ioc L U :=
      (Measure.ae_prod_iff_ae_ae (measurable_snd measurableSet_Ioc)).2
        (Filter.Eventually.of_forall fun _ => ae_restrict_mem measurableSet_Ioc)
    filter_upwards [hmem] with p hp
    obtain ⟨s, K⟩ := p
    have hK : L < K ∧ K ≤ U := hp
    have hK0 : 0 < K := hL.trans hK.1
    have hnum : |(if K < F then max (K - s) 0 else max (s - K) 0)| ≤ |s| + U := by
      split_ifs
      · rw [abs_of_nonneg (le_max_right _ _)]
        exact max_le (by linarith [neg_abs_le s]) (by linarith [abs_nonneg s, hL, hK.1, hK.2])
      · rw [abs_of_nonneg (le_max_right _ _)]
        exact max_le (by linarith [le_abs_self s]) (by linarith [abs_nonneg s])
    simp only [Function.uncurry_apply_pair, hf, Real.norm_eq_abs, abs_div,
      abs_of_pos (pow_pos hK0 2)]
    have hLK : L ^ 2 ≤ K ^ 2 := pow_le_pow_left₀ hL.le hK.1.le 2
    calc |(if K < F then max (K - s) 0 else max (s - K) 0)| / K ^ 2
        ≤ (|s| + U) / K ^ 2 := by gcongr
      _ ≤ (|s| + U) / L ^ 2 := by
        apply div_le_div_of_nonneg_left (by linarith [abs_nonneg s, hL, hK.1, hK.2]) (by positivity) hLK
  simp only [hpt]
  simp only [intervalIntegral.integral_of_le hLU]
  rw [integral_const_mul]
  rw [integral_integral_swap hprod]
  have hinner : ∀ K, (if K < F then Real.exp (-(r * T)) * ∫ s, max (K - s) 0 ∂μ
           else Real.exp (-(r * T)) * ∫ s, max (s - K) 0 ∂μ) / K ^ 2 =
      Real.exp (-(r * T)) * ∫ s, f s K ∂μ := by
    intro K
    by_cases hK : K < F
    · simp only [hf, hK, ite_true, integral_div]; ring
    · simp only [hf, hK, ite_false, integral_div]; ring
  simp only [hinner]
  rw [integral_const_mul, Real.exp_neg]
  have := Real.exp_pos (r * T)
  field_simp

/-- Step 4, the cap: for any distribution `ν` of the year's realised variance `V` with a finite
average, and any cap `V_cap`, the capped swap's fair strike `E[min(V, V_cap)]` equals the plain
fair strike `E[V]` minus the value at expiry of a call on realised variance struck at the cap,
`E[(V - V_cap)^+]`. No model is needed for this split; only the call's value needs one. -/
theorem capped_fair_strike_eq_plain_sub_call_on_variance
    (ν : Measure ℝ) [IsProbabilityMeasure ν] (Vcap : ℝ)
    (hint : Integrable (fun v : ℝ => v) ν) :
    ∫ v, min v Vcap ∂ν = (∫ v, v ∂ν) - ∫ v, max (v - Vcap) 0 ∂ν := by
  have h2 : Integrable (fun v : ℝ => max (v - Vcap) 0) ν :=
    (hint.sub (integrable_const Vcap)).pos_part
  rw [← integral_sub hint h2]
  congr 1
  funext v
  rcases le_total v Vcap with h | h
  · rw [min_eq_left h, max_eq_right (by linarith)]; ring
  · rw [min_eq_right h, max_eq_left (by linarith)]; ring

/-- Steps 0 and 1: the corridor log payoff is zero and flat at the forward, and its dollar
gamma (price squared times curvature) is exactly 2 at every price strictly inside the band and
0 at every price outside it, away from the two edges. So it earns squared moves only while the
price is inside the band. -/
theorem corridor_log_payoff_flat_at_forward_and_dollar_gamma
    (L U F : ℝ) (hL : 0 < L) (hLU : L ≤ U) (hF : 0 < F) :
    corridorLogPayoff L U F F = 0 ∧
      deriv (corridorLogPayoff L U F) F = 0 ∧
      ∀ y : ℝ, y ≠ L → y ≠ U →
        y ^ 2 * deriv (deriv (corridorLogPayoff L U F)) y = if L < y ∧ y < U then 2 else 0 := by
  set m := bandClamp L U F with hm
  set JF := corridorJ L U F with hJF
  refine ⟨by simp [corridorLogPayoff], ?_, ?_⟩
  · by_cases hd : DifferentiableAt ℝ (corridorLogPayoff L U F) F
    · have h1 : HasDerivWithinAt (corridorLogPayoff L U F) 0 (Set.Iic F) F := by
        have := ((((hasDerivAt_id F).sub_const F).div_const m).hasDerivWithinAt.sub
          ((corridorJ_hasDerivWithinAt_Iic L U F hL hLU).sub_const JF)).const_mul 2
        convert this using 1
        · rfl
        · simp [hm]
      exact (uniqueDiffWithinAt_Iic F).eq_deriv _ hd.hasDerivAt.hasDerivWithinAt h1
    · exact deriv_zero_of_not_differentiableAt hd
  · intro y hyL hyU
    rcases lt_or_gt_of_ne hyL with h1 | h1
    · have heq : corridorLogPayoff L U F =ᶠ[nhds y]
          fun z => 2 * ((z - F) / m - ((z - L) / L - JF)) := by
        filter_upwards [Iio_mem_nhds h1] with z hz
        simp [corridorLogPayoff, corridorJ, Set.mem_Iio.1 hz, hm, hJF]
      have hd : deriv (fun z => 2 * ((z - F) / m - ((z - L) / L - JF))) =
          fun _ => 2 * (1 / m - 1 / L) := by
        funext z
        refine HasDerivAt.deriv ?_
        have := ((((hasDerivAt_id z).sub_const F).div_const m).sub
          ((((hasDerivAt_id z).sub_const L).div_const L).sub_const JF)).const_mul 2
        simpa using this
      rw [heq.deriv.deriv_eq, hd, deriv_const]
      simp [not_lt.2 h1.le]
    rcases lt_or_gt_of_ne hyU with h2 | h2
    · have hy0 : 0 < y := hL.trans h1
      have heq : corridorLogPayoff L U F =ᶠ[nhds y]
          fun z => 2 * ((z - F) / m - ((Real.log z - Real.log L) - JF)) := by
        filter_upwards [Ioo_mem_nhds h1 h2] with z hz
        simp only [corridorLogPayoff, corridorJ, not_lt.2 hz.1.le, ite_false, hz.2.le, ite_true, hm, hJF]
        rw [Real.log_div (hL.trans hz.1).ne' hL.ne']
      have hd : deriv (fun z => 2 * ((z - F) / m - ((Real.log z - Real.log L) - JF))) =ᶠ[nhds y]
          fun z => 2 * (1 / m - z⁻¹) := by
        filter_upwards [Ioi_mem_nhds hy0] with z hz
        refine HasDerivAt.deriv ?_
        have := ((((hasDerivAt_id z).sub_const F).div_const m).sub
          (((Real.hasDerivAt_log (ne_of_gt hz)).sub_const (Real.log L)).sub_const JF)).const_mul 2
        simpa using this
      rw [heq.deriv.deriv_eq, hd.deriv_eq]
      have h3 : HasDerivAt (fun z : ℝ => 2 * (1 / m - z⁻¹)) (2 * (0 - -(y ^ 2)⁻¹)) y :=
        ((hasDerivAt_const y (1 / m)).sub (hasDerivAt_inv hy0.ne')).const_mul 2
      rw [h3.deriv]
      simp only [h1, h2, and_self, ite_true]
      field_simp
      ring
    · have heq : corridorLogPayoff L U F =ᶠ[nhds y]
          fun z => 2 * ((z - F) / m - ((Real.log (U / L) + (z - U) / U) - JF)) := by
        filter_upwards [Ioi_mem_nhds h2] with z hz
        have hz' : U < z := hz
        simp only [corridorLogPayoff, corridorJ, not_lt.2 (hLU.trans hz'.le), ite_false,
          not_le.2 hz', hm, hJF]
      have hd : deriv (fun z => 2 * ((z - F) / m - ((Real.log (U / L) + (z - U) / U) - JF))) =
          fun _ => 2 * (1 / m - 1 / U) := by
        funext z
        refine HasDerivAt.deriv ?_
        have := ((((hasDerivAt_id z).sub_const F).div_const m).sub
          (((((hasDerivAt_id z).sub_const U).div_const U).const_add (Real.log (U / L))).sub_const JF)).const_mul 2
        simpa using this
      rw [heq.deriv.deriv_eq, hd, deriv_const]
      simp [not_lt.2 h2.le]

-- Overview: $100,000 per volatility point is $100,000 ÷ (2 × 20) = $2,500 per variance point.
example : (100000 : ℚ) / (2 * 20) = 2500 := by norm_num
-- A crash year at 60 vol against a 20-vol strike: $2,500 × (3,600 − 400) = $8.0 million.
example : (2500 : ℤ) * (3600 - 400) = 8000000 := by decide
-- The cap: 2.5 times the strike in volatility is 2.5² = 6.25 times in variance; 6.25 × 0.04 = 0.25.
example : ((5 : ℚ) / 2) ^ 2 * (4 / 100) = 1 / 4 := by norm_num
-- Applied to variance by mistake, the 2.5 gives 2.5 × 0.04 = 0.10 instead.
example : ((5 : ℚ) / 2) * (4 / 100) = 1 / 10 := by norm_num
-- Plain payoff chart, in $000: at 10 vol 2.5 × (100 − 400) = −750; at 70 vol 2.5 × (4,900 − 400) = 11,250.
example : (5 : ℚ) / 2 * (100 - 400) = -750 ∧ (5 : ℚ) / 2 * (4900 - 400) = 11250 := by norm_num
-- Capped fair strike, in millionths: 0.04 − 0.000282 = 0.039718.
example : (40000 : ℤ) - 282 = 39718 := by decide
-- At 60 vol, in millionths: 0.36 − 0.158858 = 0.201142.
example : (360000 : ℤ) - 158858 = 201142 := by decide
-- Down variance plus up variance, in millionths: 0.021063 + 0.018937 = 0.040000.
example : (21063 : ℤ) + 18937 = 40000 := by decide
-- The four inside strike bands, in hundredths of a thousandth: 4.72 + 10.05 + 12.71 + 6.17 = 33.65.
example : (472 : ℤ) + 1005 + 1271 + 617 = 3365 := by decide

#print axioms corridor_fair_strike_eq_strip_inside_band
#print axioms capped_fair_strike_eq_plain_sub_call_on_variance
#print axioms corridor_log_payoff_flat_at_forward_and_dollar_gamma
