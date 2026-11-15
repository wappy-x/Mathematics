-- Dupire's equation: if the index's density obeys the Fokker-Planck equation, its call prices obey C_T = ½ σ² K² C_KK, while the bend read off quotes carries an error up to 4ε/h² and a narrow ripple of any small height has an unbounded bend.
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Tactic

open Real Filter Topology MeasureTheory

namespace DupireForward

/-! Notation, as on the card, with interest and dividends zero. `p x T` is the density of the
index level `x` on date `T`; `σ x T` is the local volatility at level `x` on date `T`.
The card's `Q` is `x ↦ σ(x, T)² x² p(x, T)`. -/

/-- **A call price is the average payoff** (Why it works, Step 1, item 1): the call with strike
`K` and expiry `T` is worth `C(K, T) = ∫_K^∞ (x - K) p(x, T) dx`. -/
noncomputable def callPrice (p : ℝ → ℝ → ℝ) (K T : ℝ) : ℝ :=
  ∫ x in Set.Ioi K, (x - K) * p x T

lemma hasDerivAt_integral_Ioi_of_continuous {g : ℝ → ℝ} (hc : Continuous g) (hi : Integrable g)
    (k : ℝ) : HasDerivAt (fun k => ∫ x in Set.Ioi k, g x) (-g k) k := by
  have h : (fun k => ∫ x in Set.Ioi k, g x) =
      fun k => (∫ x, g x) - (∫ x in Set.Iic 0, g x) - ∫ x in (0:ℝ)..k, g x := by
    funext k
    rw [← intervalIntegral.integral_Iic_sub_Iic hi.integrableOn hi.integrableOn,
      ← intervalIntegral.integral_Iic_add_Ioi (b := k) hi.integrableOn hi.integrableOn]
    ring
  rw [h]
  have := (hc.integral_hasStrictDerivAt 0 k).hasDerivAt
  simpa using this.const_sub ((∫ x, g x) - (∫ x in Set.Iic 0, g x))

#print axioms hasDerivAt_integral_Ioi_of_continuous

lemma hasDerivAt_callPrice (p : ℝ → ℝ → ℝ) (T : ℝ) (hp_cont : Continuous (fun x => p x T))
    (hp_int : Integrable (fun x => p x T)) (hxp_int : Integrable (fun x => x * p x T)) (k : ℝ) :
    HasDerivAt (fun k => callPrice p k T) (-∫ x in Set.Ioi k, p x T) k := by
  have h : (fun k => callPrice p k T) =
      fun k => (∫ x in Set.Ioi k, x * p x T) - k * ∫ x in Set.Ioi k, p x T := by
    funext k
    unfold callPrice
    rw [← integral_const_mul, ← integral_sub hxp_int.integrableOn
      (hp_int.integrableOn.const_mul k)]
    congr 1; funext x; ring
  rw [h]
  have h1 := hasDerivAt_integral_Ioi_of_continuous (g := fun x => x * p x T) (by fun_prop) hxp_int k
  have h2 := hasDerivAt_integral_Ioi_of_continuous hp_cont hp_int k
  convert h1.sub ((hasDerivAt_id' k).mul h2) using 1
  simp

#print axioms hasDerivAt_callPrice

/-- **Dupire's forward equation, rates zero** (The formula; Why it works, Step 1 and its
detailed proof). Take a strike `K > 0` and a date `T > 0`. Suppose the index's density `p` at
date `T` is continuous, integrable and has a finite mean, and that `Q = σ² x² p` is twice
continuously differentiable in `x`. Suppose the density obeys the Fokker-Planck equation
`p_T = ½ Q_xx` at date `T`, that `Q` and its slope `Q_x` vanish at infinity faster than `x`
grows (`x Q → 0` and `x Q_x → 0`), that `(x - K) Q_xx` is integrable above the strike, and that
the call price may be differentiated in `T` under the integral sign, as the card does. Then the
call price gains value with expiry at half the local variance at its strike, times the strike
squared, times the bend of the price curve in strike:
`C_T(K, T) = ½ σ_loc(K, T)² K² C_KK(K, T)`. -/
theorem dupire_forward_equation
    (σ p : ℝ → ℝ → ℝ) (K T : ℝ) (hK : 0 < K) (hT : 0 < T)
    (hp_cont : Continuous (fun x => p x T))
    (hp_int : Integrable (fun x => p x T))
    (hxp_int : Integrable (fun x => x * p x T))
    (hQ : ContDiff ℝ 2 (fun x => σ x T ^ 2 * x ^ 2 * p x T))
    (hFP : ∀ x, HasDerivAt (fun t => p x t)
      ((1 / 2) * deriv (deriv (fun y => σ y T ^ 2 * y ^ 2 * p y T)) x) T)
    (hQ_lim : Tendsto (fun x => x * (σ x T ^ 2 * x ^ 2 * p x T)) atTop (𝓝 0))
    (hQ'_lim : Tendsto (fun x => x * deriv (fun y => σ y T ^ 2 * y ^ 2 * p y T) x) atTop (𝓝 0))
    (hQ''_int : IntegrableOn
      (fun x => (x - K) * deriv (deriv (fun y => σ y T ^ 2 * y ^ 2 * p y T)) x) (Set.Ioi K))
    (hunder : HasDerivAt (fun t => callPrice p K t)
      (∫ x in Set.Ioi K, (x - K) * deriv (fun t => p x t) T) T) :
    HasDerivAt (fun t => callPrice p K t)
      ((1 / 2) * σ K T ^ 2 * K ^ 2 * deriv (deriv (fun k => callPrice p k T)) K) T := by
  set Q := fun y => σ y T ^ 2 * y ^ 2 * p y T with hQdef
  have hdiff : Differentiable ℝ Q := hQ.differentiable (by norm_num)
  have hQ1 : ContDiff ℝ 1 (deriv Q) := ((contDiff_succ_iff_deriv (n := 1)).mp hQ).2.2
  have hdiff' : Differentiable ℝ (deriv Q) := hQ1.differentiable (by norm_num)
  have hinv : Tendsto (fun x : ℝ => x⁻¹) atTop (𝓝 0) := tendsto_inv_atTop_zero
  have hQlim : Tendsto Q atTop (𝓝 0) := by
    have := hQ_lim.mul hinv
    rw [zero_mul] at this
    refine this.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with x hx
    simp only [hQdef]
    field_simp
  have hQ'lim : Tendsto (deriv Q) atTop (𝓝 0) := by
    have := hQ'_lim.mul hinv
    rw [zero_mul] at this
    refine this.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with x hx
    field_simp
  have hF : Tendsto (fun x => (x - K) * deriv Q x - Q x) atTop (𝓝 0) := by
    have e : (fun x => (x - K) * deriv Q x - Q x) =
        fun x => x * deriv Q x - K * deriv Q x - Q x := by
      funext x; ring
    rw [e]
    simpa using (hQ'_lim.sub (hQ'lim.const_mul K)).sub hQlim
  have hint : ∫ x in Set.Ioi K, (x - K) * deriv (deriv Q) x = Q K := by
    rw [integral_Ioi_of_hasDerivAt_of_tendsto' (f := fun x => (x - K) * deriv Q x - Q x)
      (fun x _ => ?_) hQ''_int hF]
    · simp
    · have := (((hasDerivAt_id' x).sub_const K).mul (hdiff' x).hasDerivAt).sub
        (hdiff x).hasDerivAt
      convert this using 1
      ring
  have hC2 : deriv (deriv (fun k => callPrice p k T)) K = p K T := by
    have e : deriv (fun k => callPrice p k T) = fun k => -∫ x in Set.Ioi k, p x T :=
      funext fun k => (hasDerivAt_callPrice p T hp_cont hp_int hxp_int k).deriv
    rw [e]
    exact ((hasDerivAt_integral_Ioi_of_continuous hp_cont hp_int K).neg).deriv.trans (neg_neg _)
  rw [hC2]
  convert hunder using 1
  have e : ∀ x, deriv (fun t => p x t) T = (1 / 2) * deriv (deriv Q) x :=
    fun x => (hFP x).deriv
  simp_rw [e]
  rw [show (fun x => (x - K) * (1 / 2 * deriv (deriv Q) x)) =
      fun x => (1 / 2) * ((x - K) * deriv (deriv Q) x) by funext x; ring,
    integral_const_mul, hint]
  simp only [hQdef]
  ring

/-- The bend in strike read off three prices `h` apart: `(C(K - h) - 2 C(K) + C(K + h)) / h²`. -/
noncomputable def bend (cm c0 cp h : ℝ) : ℝ := (cm - 2 * c0 + cp) / h ^ 2

/-- **Quote errors reach the bend amplified by `4/h²`** (Why it works, Step 4). If each of three
quotes `h > 0` apart is off by at most `ε`, the bend read from the quotes differs from the bend of
the true prices by at most `4ε/h²`; and when the errors line up (`+ε`, `-ε`, `+ε`) the bend is
off by exactly `4ε/h²`. -/
theorem bend_error_le_four_eps_div_sq
    (cm c0 cp ε h : ℝ) (hh : 0 < h) (hε : 0 ≤ ε) :
    (∀ em e0 ep : ℝ, |em| ≤ ε → |e0| ≤ ε → |ep| ≤ ε →
      |bend (cm + em) (c0 + e0) (cp + ep) h - bend cm c0 cp h| ≤ 4 * ε / h ^ 2) ∧
    |bend (cm + ε) (c0 - ε) (cp + ε) h - bend cm c0 cp h| = 4 * ε / h ^ 2 := by
  have key : ∀ a b c, bend (cm + a) (c0 + b) (cp + c) h - bend cm c0 cp h =
      (a - 2 * b + c) / h ^ 2 := by
    intros; unfold bend; ring
  have hh2 : 0 < h ^ 2 := by positivity
  refine ⟨fun em e0 ep h1 h2 h3 => ?_, ?_⟩
  · rw [key, abs_div, abs_of_pos hh2]
    apply div_le_div_of_nonneg_right _ hh2.le
    rw [abs_le] at h1 h2 h3 ⊢
    constructor <;> linarith [h1.1, h1.2, h2.1, h2.2, h3.1, h3.2]
  · rw [sub_eq_add_neg c0 ε, key, abs_of_nonneg (div_nonneg (by linarith) hh2.le)]
    ring

/-- A ripple of height `ε` and width `w` added to the prices: `x ↦ ε sin(2π x / w)`. -/
noncomputable def ripple (ε w : ℝ) (x : ℝ) : ℝ := ε * Real.sin (2 * π * x / w)

/-- **The inversion is ill posed: a narrow ripple has an unbounded bend** (Why it works, Step 4,
Hadamard's third condition failing). A ripple of height `ε > 0` and width `w > 0` never moves a
price by more than `ε`, yet its bend at its crest `w/4` is `-ε (2π/w)²`; so for every bound `M`
some narrow enough ripple has a bend larger than `M`. -/
theorem narrow_ripple_bend_unbounded (ε : ℝ) (hε : 0 < ε) :
    (∀ w > 0, (∀ x, |ripple ε w x| ≤ ε) ∧
      deriv (deriv (ripple ε w)) (w / 4) = -(ε * (2 * π / w) ^ 2)) ∧
    ∀ M : ℝ, ∃ w > 0, M < |deriv (deriv (ripple ε w)) (w / 4)| := by
  have hd1 : ∀ w x, HasDerivAt (ripple ε w) (ε * (Real.cos (2 * π * x / w) * (2 * π / w))) x := by
    intro w x
    have := ((((hasDerivAt_id' x).const_mul (2 * π)).div_const w).sin).const_mul ε
    show HasDerivAt (fun y => ε * Real.sin (2 * π * y / w)) _ x
    convert this using 1
    ring
  have hd2 : ∀ w x, HasDerivAt (fun x => ε * (Real.cos (2 * π * x / w) * (2 * π / w)))
      (-(ε * Real.sin (2 * π * x / w) * (2 * π / w) ^ 2)) x := by
    intro w x
    have := (((((hasDerivAt_id' x).const_mul (2 * π)).div_const w).cos).mul_const
      (2 * π / w)).const_mul ε
    convert this using 1
    ring
  have hdd : ∀ w, deriv (deriv (ripple ε w)) (w / 4) = -(ε * (2 * π / w) ^ 2) := by
    intro w
    by_cases hw : w = 0
    · subst hw
      have e : deriv (ripple ε 0) = fun x => 0 := funext fun x => by
        rw [(hd1 0 x).deriv]; simp
      rw [e]; simp
    have e : deriv (ripple ε w) = fun x => ε * (Real.cos (2 * π * x / w) * (2 * π / w)) :=
      funext fun x => (hd1 w x).deriv
    rw [e, (hd2 w (w / 4)).deriv]
    have : 2 * π * (w / 4) / w = π / 2 := by field_simp; ring
    rw [this, Real.sin_pi_div_two]
    ring
  refine ⟨fun w _ => ⟨fun x => ?_, hdd w⟩, fun M => ?_⟩
  · unfold ripple
    rw [abs_mul, abs_of_pos hε]
    exact mul_le_of_le_one_right hε.le (Real.abs_sin_le_one _)
  · set t := |M| / ε + 1 with ht
    have ht1 : 1 ≤ t := by have : 0 ≤ |M| / ε := by positivity
                           linarith
    have ht0 : 0 < t := by linarith
    refine ⟨2 * π / t, by positivity, ?_⟩
    rw [hdd, abs_neg, show 2 * π / (2 * π / t) = t by field_simp]
    rw [abs_of_pos (by positivity)]
    have h1 : ε * t = |M| + ε := by rw [ht]; field_simp
    have h2 : ε * t ≤ ε * t ^ 2 := by
      apply mul_le_mul_of_nonneg_left _ hε.le
      nlinarith
    linarith [le_abs_self M]

/-! The card's worked numbers at strike 100, 0.6 years out, in exact fractions of a dollar. -/

-- slope in expiry: (7.11 - 5.05) / 0.4 = 5.15
example : ((711 : ℝ) / 100 - 505 / 100) / (2 / 5) = 103 / 20 := by norm_num

-- bend in strike: (8.96 - 2 × 6.17 + 4.02) / 25 = 0.64 / 25 = 0.0256
example : bend (896 / 100) (617 / 100) (402 / 100) 5 = 16 / 625 := by norm_num [bend]

-- local variance: 2 × 5.15 / (100² × 0.0256) = 0.040234375
example : 2 * ((103 : ℝ) / 20) / (100 ^ 2 * (16 / 625)) = 103 / 2560 := by norm_num

-- worst bend error 4ε/h² with ε = 2.5 cents: 0.0010, 0.0040, 0.0160, 0.1000, 0.4000 at h = 10, 5, 2.5, 1, 0.5
example : 4 * ((1 : ℝ) / 40) / 10 ^ 2 = 1 / 1000 := by norm_num
example : 4 * ((1 : ℝ) / 40) / 5 ^ 2 = 1 / 250 := by norm_num
example : 4 * ((1 : ℝ) / 40) / (5 / 2) ^ 2 = 2 / 125 := by norm_num
example : 4 * ((1 : ℝ) / 40) / 1 ^ 2 = 1 / 10 := by norm_num
example : 4 * ((1 : ℝ) / 40) / (1 / 2) ^ 2 = 2 / 5 := by norm_num

-- at h = 1 the possible error 0.1000 exceeds the true bend of about 0.0256
example : (16 : ℝ) / 625 < 4 * (1 / 40) / 1 ^ 2 := by norm_num

#print axioms dupire_forward_equation
#print axioms bend_error_le_four_eps_div_sq
#print axioms narrow_ripple_bend_unbounded

end DupireForward
