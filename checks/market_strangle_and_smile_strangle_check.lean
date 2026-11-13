-- The broker butterfly: in the Garman-Kohlhagen market with a parabola-in-log-strike smile, a sign change of the strangle gap g(b) on an interval where the smile is defined gives a smile strangle with g(b) = 0, with no tilt the smile strangle equals the broker's butterfly, and the market strangle's legs have deltas +1/4 and -1/4 and equal vegas.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Interval.Set.UnorderedInterval

open Real MeasureTheory ProbabilityTheory Set

namespace BrokerButterfly

/-- The FX market: spot `S` (dollars per euro), dollar rate `rd`, euro rate `rf`, both
continuously compounded, and years to expiry `T`. -/
structure FXMarket where
  S : ℝ
  rd : ℝ
  rf : ℝ
  T : ℝ

/-- `N(x)`: the bell-curve area left of `x`. -/
noncomputable def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The forward `F = S e^((rd - rf) T)`. -/
noncomputable def fwd (m : FXMarket) : ℝ := m.S * exp ((m.rd - m.rf) * m.T)

/-- Garman-Kohlhagen `d₁ = (ln(S/K) + (rd - rf + σ²/2) T) / (σ√T)`. -/
noncomputable def d1 (m : FXMarket) (K σ : ℝ) : ℝ :=
  (log (m.S / K) + (m.rd - m.rf + σ ^ 2 / 2) * m.T) / (σ * √m.T)

/-- Garman-Kohlhagen price of a euro call, dollars per euro. -/
noncomputable def gkCall (m : FXMarket) (K σ : ℝ) : ℝ :=
  m.S * exp (-m.rf * m.T) * N (d1 m K σ) - K * exp (-m.rd * m.T) * N (d1 m K σ - σ * √m.T)

/-- Garman-Kohlhagen price of a euro put, dollars per euro. -/
noncomputable def gkPut (m : FXMarket) (K σ : ℝ) : ℝ :=
  K * exp (-m.rd * m.T) * N (-(d1 m K σ - σ * √m.T)) - m.S * exp (-m.rf * m.T) * N (-(d1 m K σ))

/-- Spot delta of a euro call, premium not adjusted: `e^(-rf T) N(d₁)`. -/
noncomputable def callDelta (m : FXMarket) (K σ : ℝ) : ℝ := exp (-m.rf * m.T) * N (d1 m K σ)

/-- Spot delta of a euro put, premium not adjusted: `-e^(-rf T) N(-d₁)`. -/
noncomputable def putDelta (m : FXMarket) (K σ : ℝ) : ℝ := -(exp (-m.rf * m.T) * N (-(d1 m K σ)))

/-- Vega of a call or a put at strike `K`: `S e^(-rf T) φ(d₁) √T`, with `φ` the bell-curve height. -/
noncomputable def vega (m : FXMarket) (K σ : ℝ) : ℝ :=
  m.S * exp (-m.rf * m.T) * gaussianPDFReal 0 1 (d1 m K σ) * √m.T

/-- The 25-delta strike at vol `σ`: `K = F exp(-w d σ√T + σ² T/2)`, with `w = 1` for the call and
`w = -1` for the put, where `d` solves `e^(-rf T) N(d) = 1/4`. -/
noncomputable def strike25 (m : FXMarket) (d σ w : ℝ) : ℝ :=
  fwd m * exp (-w * d * σ * √m.T + σ ^ 2 * m.T / 2)

/-- The parabola through the three points `(x₀, y₀)`, `(x₁, y₁)`, `(x₂, y₂)`, by Lagrange's formula. -/
noncomputable def lagrange3 (x₀ x₁ x₂ y₀ y₁ y₂ x : ℝ) : ℝ :=
  y₀ * ((x - x₁) * (x - x₂)) / ((x₀ - x₁) * (x₀ - x₂)) +
    y₁ * ((x - x₀) * (x - x₂)) / ((x₁ - x₀) * (x₁ - x₂)) +
    y₂ * ((x - x₀) * (x - x₁)) / ((x₂ - x₀) * (x₂ - x₁))

/-- The smile's put-wing vol with bow `b`: `σ_ATM + b - RR/2`. -/
noncomputable def wingPut (atm rr b : ℝ) : ℝ := atm + b - rr / 2

/-- The smile's call-wing vol with bow `b`: `σ_ATM + b + RR/2`. -/
noncomputable def wingCall (atm rr b : ℝ) : ℝ := atm + b + rr / 2

/-- The put pillar's log-strike `x_p = ln(K_25p / F)`, found at the put wing's own vol. -/
noncomputable def xPut (m : FXMarket) (d atm rr b : ℝ) : ℝ :=
  log (strike25 m d (wingPut atm rr b) (-1) / fwd m)

/-- The ATM pillar's log-strike, the delta-neutral straddle: `x_a = σ_ATM² T / 2`. -/
noncomputable def xAtm (m : FXMarket) (atm : ℝ) : ℝ := atm ^ 2 * m.T / 2

/-- The call pillar's log-strike `x_c = ln(K_25c / F)`, found at the call wing's own vol. -/
noncomputable def xCall (m : FXMarket) (d atm rr b : ℝ) : ℝ :=
  log (strike25 m d (wingCall atm rr b) 1 / fwd m)

/-- The smile `σ(K; b)`: the parabola in `x = ln(K/F)` through the three pillars. -/
noncomputable def smileVol (m : FXMarket) (d atm rr b K : ℝ) : ℝ :=
  lagrange3 (xPut m d atm rr b) (xAtm m atm) (xCall m d atm rr b)
    (wingPut atm rr b) atm (wingCall atm rr b) (log (K / fwd m))

/-- The market strangle's call strike: 25 delta at the one vol `σ_ATM + BF_ms`. -/
noncomputable def msCallStrike (m : FXMarket) (d atm bf : ℝ) : ℝ := strike25 m d (atm + bf) 1

/-- The market strangle's put strike: 25 delta at the one vol `σ_ATM + BF_ms`. -/
noncomputable def msPutStrike (m : FXMarket) (d atm bf : ℝ) : ℝ := strike25 m d (atm + bf) (-1)

/-- The broker's price `V_ms`: both legs priced at the one vol `σ_ATM + BF_ms`. -/
noncomputable def marketStrangle (m : FXMarket) (d atm bf : ℝ) : ℝ :=
  gkCall m (msCallStrike m d atm bf) (atm + bf) + gkPut m (msPutStrike m d atm bf) (atm + bf)

/-- The gap `g(b)`: the smile's price of the market strangle minus the broker's price. -/
noncomputable def gap (m : FXMarket) (d atm rr bf b : ℝ) : ℝ :=
  gkCall m (msCallStrike m d atm bf) (smileVol m d atm rr b (msCallStrike m d atm bf)) +
    gkPut m (msPutStrike m d atm bf) (smileVol m d atm rr b (msPutStrike m d atm bf)) -
    marketStrangle m d atm bf

/-- `N` is continuous: the standard bell curve puts no mass on single points. -/
lemma N_continuous : Continuous N := by
  rw [continuous_iff_continuousAt]
  intro x
  have hmono := monotone_cdf (gaussianReal 0 1)
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have hsing : (cdf (gaussianReal 0 1)).measure {x} = 0 := by
    rw [measure_cdf]; exact measure_singleton x
  rw [StieltjesFunction.measure_singleton, ENNReal.ofReal_eq_zero] at hsing
  have hle := hmono.leftLim_le (le_refl x)
  have hleft : ContinuousWithinAt (cdf (gaussianReal 0 1)) (Iio x) x :=
    hmono.continuousWithinAt_Iio_iff_leftLim_eq.2 (le_antisymm hle (by linarith))
  have hright : ContinuousWithinAt (cdf (gaussianReal 0 1)) (Ici x) x :=
    (cdf (gaussianReal 0 1)).right_continuous x
  exact continuousAt_iff_continuous_left'_right'.2 ⟨hleft, hright.mono Ioi_subset_Ici_self⟩

lemma gaussianPDFReal_std_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal]

lemma fwd_pos (m : FXMarket) (hS : 0 < m.S) : 0 < fwd m := by
  unfold fwd; positivity

lemma log_strike25_div_fwd (m : FXMarket) (hS : 0 < m.S) (d σ w : ℝ) :
    log (strike25 m d σ w / fwd m) = -w * d * σ * √m.T + σ ^ 2 * m.T / 2 := by
  have hF := (fwd_pos m hS).ne'
  unfold strike25
  rw [mul_div_right_comm, div_self hF, one_mul, log_exp]

lemma d1_strike25 (m : FXMarket) (hS : 0 < m.S) (hT : 0 < m.T) (d σ w : ℝ) (hσ : σ ≠ 0) :
    d1 m (strike25 m d σ w) σ = w * d := by
  have hF := fwd_pos m hS
  have hsT : 0 < √m.T := sqrt_pos.2 hT
  have hK : m.S / strike25 m d σ w = exp (-((m.rd - m.rf) * m.T) + (w * d * σ * √m.T - σ ^ 2 * m.T / 2)) := by
    have hK' : strike25 m d σ w =
        m.S * exp ((m.rd - m.rf) * m.T + (-w * d * σ * √m.T + σ ^ 2 * m.T / 2)) := by
      unfold strike25 fwd; simp only [exp_add]; ring
    rw [hK', div_mul_cancel_left₀ hS.ne', ← exp_neg]
    congr 1; ring
  unfold d1
  rw [hK, log_exp]
  field_simp
  ring

lemma lagrange3_at_x0 {x₀ x₁ x₂ y₀ y₁ y₂ : ℝ} (h01 : x₀ ≠ x₁) (h02 : x₀ ≠ x₂) :
    lagrange3 x₀ x₁ x₂ y₀ y₁ y₂ x₀ = y₀ := by
  have a : x₀ - x₁ ≠ 0 := sub_ne_zero.2 h01
  have b : x₀ - x₂ ≠ 0 := sub_ne_zero.2 h02
  unfold lagrange3
  simp [a, b]

lemma lagrange3_at_x2 {x₀ x₁ x₂ y₀ y₁ y₂ : ℝ} (h02 : x₀ ≠ x₂) (h12 : x₁ ≠ x₂) :
    lagrange3 x₀ x₁ x₂ y₀ y₁ y₂ x₂ = y₂ := by
  have a : x₂ - x₀ ≠ 0 := sub_ne_zero.2 h02.symm
  have b : x₂ - x₁ ≠ 0 := sub_ne_zero.2 h12.symm
  unfold lagrange3
  simp [a, b]


lemma gkCall_continuousOn (m : FXMarket) (hT : 0 < m.T) (K : ℝ) {s : Set ℝ} {f : ℝ → ℝ}
    (hf : ContinuousOn f s) (hne : ∀ b ∈ s, f b ≠ 0) :
    ContinuousOn (fun b => gkCall m K (f b)) s := by
  have hsT : 0 < √m.T := sqrt_pos.2 hT
  have hd1 : ContinuousOn (fun b => d1 m K (f b)) s := by
    unfold d1
    exact ContinuousOn.div (by fun_prop) (by fun_prop)
      (fun b hb => mul_ne_zero (hne b hb) hsT.ne')
  have h1 : ContinuousOn (fun b => N (d1 m K (f b))) s := N_continuous.comp_continuousOn hd1
  have h2 : ContinuousOn (fun b => N (d1 m K (f b) - f b * √m.T)) s :=
    N_continuous.comp_continuousOn (hd1.sub (hf.mul continuousOn_const))
  unfold gkCall
  exact (continuousOn_const.mul h1).sub (continuousOn_const.mul h2)

lemma gkPut_continuousOn (m : FXMarket) (hT : 0 < m.T) (K : ℝ) {s : Set ℝ} {f : ℝ → ℝ}
    (hf : ContinuousOn f s) (hne : ∀ b ∈ s, f b ≠ 0) :
    ContinuousOn (fun b => gkPut m K (f b)) s := by
  have hsT : 0 < √m.T := sqrt_pos.2 hT
  have hd1 : ContinuousOn (fun b => d1 m K (f b)) s := by
    unfold d1
    exact ContinuousOn.div (by fun_prop) (by fun_prop)
      (fun b hb => mul_ne_zero (hne b hb) hsT.ne')
  have h1 : ContinuousOn (fun b => N (-(d1 m K (f b)))) s := N_continuous.comp_continuousOn hd1.neg
  have h2 : ContinuousOn (fun b => N (-(d1 m K (f b) - f b * √m.T))) s :=
    N_continuous.comp_continuousOn (hd1.sub (hf.mul continuousOn_const)).neg
  unfold gkPut
  exact (continuousOn_const.mul h2).sub (continuousOn_const.mul h1)

lemma smileVol_continuousOn (m : FXMarket) (hS : 0 < m.S) (d atm rr K : ℝ) {s : Set ℝ}
    (h01 : ∀ b ∈ s, xPut m d atm rr b ≠ xAtm m atm)
    (h12 : ∀ b ∈ s, xAtm m atm ≠ xCall m d atm rr b)
    (h02 : ∀ b ∈ s, xPut m d atm rr b ≠ xCall m d atm rr b) :
    ContinuousOn (fun b => smileVol m d atm rr b K) s := by
  have hP : Continuous (fun b => xPut m d atm rr b) := by
    have : (fun b => xPut m d atm rr b) = fun b =>
        -(-1) * d * wingPut atm rr b * √m.T + wingPut atm rr b ^ 2 * m.T / 2 := by
      funext b; exact log_strike25_div_fwd m hS _ _ _
    rw [this]; unfold wingPut; fun_prop
  have hC : Continuous (fun b => xCall m d atm rr b) := by
    have : (fun b => xCall m d atm rr b) = fun b =>
        -1 * d * wingCall atm rr b * √m.T + wingCall atm rr b ^ 2 * m.T / 2 := by
      funext b; exact log_strike25_div_fwd m hS _ _ _
    rw [this]; unfold wingCall; fun_prop
  have hwP : Continuous (fun b => wingPut atm rr b) := by unfold wingPut; fun_prop
  have hwC : Continuous (fun b => wingCall atm rr b) := by unfold wingCall; fun_prop
  unfold smileVol lagrange3
  refine ContinuousOn.add (ContinuousOn.add ?_ ?_) ?_
  · refine ContinuousOn.div (by fun_prop) (by fun_prop) ?_
    intro b hb
    exact mul_ne_zero (sub_ne_zero.2 (h01 b hb)) (sub_ne_zero.2 (h02 b hb))
  · refine ContinuousOn.div (by fun_prop) (by fun_prop) ?_
    intro b hb
    exact mul_ne_zero (sub_ne_zero.2 (h01 b hb).symm) (sub_ne_zero.2 (h12 b hb))
  · refine ContinuousOn.div (by fun_prop) (by fun_prop) ?_
    intro b hb
    exact mul_ne_zero (sub_ne_zero.2 (h02 b hb).symm) (sub_ne_zero.2 (h12 b hb).symm)

/-- **The smile strangle exists when the gap changes sign** (Step 3, Claim 2). Take an interval of
bows on which both pillar wing vols are positive, the three pillar log-strikes are in order, and the
parabola smile is positive at both market strikes. If one bow in it gives a negative gap and another
a positive one, some bow between them makes the smile reprice the market strangle exactly:
`g(b) = 0`. -/
theorem smile_strangle_exists_of_sign_change (m : FXMarket) (d atm rr bf lo hi b₁ b₂ : ℝ)
    (hS : 0 < m.S) (hT : 0 < m.T) (hd : exp (-m.rf * m.T) * N d = 1 / 4)
    (hdom : ∀ b ∈ Icc lo hi,
      0 < wingCall atm rr b ∧ 0 < wingPut atm rr b ∧
      xPut m d atm rr b < xAtm m atm ∧ xAtm m atm < xCall m d atm rr b ∧
      0 < smileVol m d atm rr b (msCallStrike m d atm bf) ∧
      0 < smileVol m d atm rr b (msPutStrike m d atm bf))
    (hb₁ : b₁ ∈ Icc lo hi) (hb₂ : b₂ ∈ Icc lo hi)
    (hneg : gap m d atm rr bf b₁ < 0) (hpos : 0 < gap m d atm rr bf b₂) :
    ∃ b ∈ uIcc b₁ b₂, gap m d atm rr bf b = 0 := by
  have hsub : uIcc b₁ b₂ ⊆ Icc lo hi := uIcc_subset_Icc hb₁ hb₂
  have h01 : ∀ b ∈ uIcc b₁ b₂, xPut m d atm rr b ≠ xAtm m atm :=
    fun b hb => (hdom b (hsub hb)).2.2.1.ne
  have h12 : ∀ b ∈ uIcc b₁ b₂, xAtm m atm ≠ xCall m d atm rr b :=
    fun b hb => (hdom b (hsub hb)).2.2.2.1.ne
  have h02 : ∀ b ∈ uIcc b₁ b₂, xPut m d atm rr b ≠ xCall m d atm rr b :=
    fun b hb => ((hdom b (hsub hb)).2.2.1.trans (hdom b (hsub hb)).2.2.2.1).ne
  have hsv1 := smileVol_continuousOn m hS d atm rr (msCallStrike m d atm bf) h01 h12 h02
  have hsv2 := smileVol_continuousOn m hS d atm rr (msPutStrike m d atm bf) h01 h12 h02
  have hcont : ContinuousOn (fun b => gap m d atm rr bf b) (uIcc b₁ b₂) := by
    unfold gap
    exact ((gkCall_continuousOn m hT _ hsv1 (fun b hb => (hdom b (hsub hb)).2.2.2.2.1.ne')).add
      (gkPut_continuousOn m hT _ hsv2 (fun b hb => (hdom b (hsub hb)).2.2.2.2.2.ne'))).sub
      continuousOn_const
  have h0 : (0 : ℝ) ∈ uIcc (gap m d atm rr bf b₁) (gap m d atm rr bf b₂) := by
    rw [mem_uIcc]; left; exact ⟨hneg.le, hpos.le⟩
  obtain ⟨b, hb, hgb⟩ := intermediate_value_uIcc hcont h0
  exact ⟨b, hb, hgb⟩

/-- **No tilt means no gap** (Claim 1). With risk reversal 0 and the smile a parabola through three
distinct pillars, the bow equal to the broker's butterfly reprices the market strangle exactly:
`g(BF_ms) = 0`, so the smile strangle equals the market strangle. -/
theorem no_tilt_smile_strangle_eq_market (m : FXMarket) (d atm bf : ℝ)
    (hS : 0 < m.S) (hT : 0 < m.T) (hd : exp (-m.rf * m.T) * N d = 1 / 4)
    (hpa : xPut m d atm 0 bf ≠ xAtm m atm) (hac : xAtm m atm ≠ xCall m d atm 0 bf)
    (hpc : xPut m d atm 0 bf ≠ xCall m d atm 0 bf) :
    gap m d atm 0 bf bf = 0 := by
  have hc : log (msCallStrike m d atm bf / fwd m) = xCall m d atm 0 bf := by
    simp [xCall, msCallStrike, wingCall]
  have hp : log (msPutStrike m d atm bf / fwd m) = xPut m d atm 0 bf := by
    simp [xPut, msPutStrike, wingPut]
  unfold gap smileVol
  rw [hc, hp, lagrange3_at_x2 hpc hac, lagrange3_at_x0 hpa hpc]
  unfold marketStrangle
  simp [wingCall, wingPut]

/-- **The market strangle is delta-neutral with equal vegas** (Step 1). At any vol `σ > 0`, the call
struck at the 25-delta call strike found at `σ` has spot delta `1/4`, the put struck at the 25-delta
put strike found at `σ` has spot delta `-1/4`, so the deltas cancel, and the two legs' vegas are
equal. -/
theorem market_strangle_delta_neutral_equal_vega (m : FXMarket) (d σ : ℝ)
    (hS : 0 < m.S) (hT : 0 < m.T) (hσ : 0 < σ) (hd : exp (-m.rf * m.T) * N d = 1 / 4) :
    callDelta m (strike25 m d σ 1) σ = 1 / 4 ∧
      putDelta m (strike25 m d σ (-1)) σ = -(1 / 4) ∧
      vega m (strike25 m d σ 1) σ = vega m (strike25 m d σ (-1)) σ := by
  have hs := hσ.ne'
  refine ⟨?_, ?_, ?_⟩
  · unfold callDelta
    rw [d1_strike25 m hS hT d σ 1 hs, one_mul]
    exact hd
  · unfold putDelta
    rw [d1_strike25 m hS hT d σ (-1) hs, neg_one_mul, neg_neg, hd]
  · unfold vega
    rw [d1_strike25 m hS hT d σ 1 hs, d1_strike25 m hS hT d σ (-1) hs, one_mul,
      neg_one_mul, gaussianPDFReal_std_neg]

-- The card's house quotes, in hundredths of a vol point: ATM 10.00 = 1000, RR -1.00 = -100,
-- broker BF +0.25 = 25. The market strangle's one vol is 10.25 = 1025.
example : (1000 : ℤ) + 25 = 1025 := by norm_num
-- The naive smile (bow = 25): wings 9.75 = 975 (call) and 10.75 = 1075 (put).
example : (1000 : ℤ) + 25 + (-100) / 2 = 975 ∧ (1000 : ℤ) + 25 - (-100) / 2 = 1075 := by norm_num
-- No tilt (RR = 0): both naive wings equal the market strangle's vol 1025.
example : (1000 : ℤ) + 25 + 0 / 2 = 1025 ∧ (1000 : ℤ) + 25 - 0 / 2 = 1025 := by norm_num

#print axioms N_continuous
#print axioms gaussianPDFReal_std_neg
#print axioms fwd_pos
#print axioms log_strike25_div_fwd
#print axioms d1_strike25
#print axioms lagrange3_at_x0
#print axioms lagrange3_at_x2
#print axioms gkCall_continuousOn
#print axioms gkPut_continuousOn
#print axioms smileVol_continuousOn
#print axioms smile_strangle_exists_of_sign_change
#print axioms no_tilt_smile_strangle_eq_market
#print axioms market_strangle_delta_neutral_equal_vega

end BrokerButterfly
