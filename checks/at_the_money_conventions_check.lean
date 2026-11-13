-- Three meanings of at-the-money: under Garman-Kohlhagen with positive volatility, a straddle's spot delta is zero exactly at the strike F e^{σ²T/2}, its premium-adjusted delta is zero exactly at F e^{-σ²T/2}, and the call and put cost the same exactly at the forward F.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real

namespace AtTheMoney

/-- The standard normal CDF `N(x)`: the cumulative distribution function of the
Gaussian measure with mean 0 and variance 1 on `ℝ`. -/
noncomputable def N (x : ℝ) : ℝ :=
  ProbabilityTheory.cdf (ProbabilityTheory.gaussianReal 0 1) x

/-- The forward rate `F = S e^{(r_d - r_f) T}`. -/
noncomputable def fwd (S rd rf T : ℝ) : ℝ := S * exp ((rd - rf) * T)

/-- `d₁ = (ln(F/K) + σ²T/2) / (σ√T)`. -/
noncomputable def d1 (S K rd rf σ T : ℝ) : ℝ :=
  (log (fwd S rd rf T / K) + σ ^ 2 * T / 2) / (σ * sqrt T)

/-- `d₂ = d₁ - σ√T`. -/
noncomputable def d2 (S K rd rf σ T : ℝ) : ℝ :=
  d1 S K rd rf σ T - σ * sqrt T

/-- Garman-Kohlhagen call premium, domestic units per unit of foreign:
`C = S e^{-r_f T} N(d₁) - K e^{-r_d T} N(d₂)`. -/
noncomputable def gkCall (S K rd rf σ T : ℝ) : ℝ :=
  S * exp (-rf * T) * N (d1 S K rd rf σ T) - K * exp (-rd * T) * N (d2 S K rd rf σ T)

/-- Garman-Kohlhagen put premium: `P = K e^{-r_d T} N(-d₂) - S e^{-r_f T} N(-d₁)`. -/
noncomputable def gkPut (S K rd rf σ T : ℝ) : ℝ :=
  K * exp (-rd * T) * N (-d2 S K rd rf σ T) - S * exp (-rf * T) * N (-d1 S K rd rf σ T)

/-- The standard normal has no atom at any point. -/
lemma gaussian_singleton (x : ℝ) : ProbabilityTheory.gaussianReal 0 1 {x} = 0 :=
  ProbabilityTheory.gaussianReal_absolutelyContinuous 0 one_ne_zero (by simp)

/-- Symmetry of the standard normal CDF: `N(-x) = 1 - N(x)`. -/
lemma N_neg (x : ℝ) : N (-x) = 1 - N x := by
  open MeasureTheory ProbabilityTheory in
  unfold N
  rw [cdf_eq_real, cdf_eq_real]
  have hmap : (gaussianReal 0 1).map (fun x : ℝ ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg]; simp
  have h1 : (gaussianReal 0 1).real (Set.Iic (-x)) = (gaussianReal 0 1).real (Set.Ici x) := by
    conv_lhs => rw [← hmap]
    rw [map_measureReal_apply measurable_neg measurableSet_Iic]
    congr 1
    ext y; simp
  have h2 : (gaussianReal 0 1).real (Set.Ici x) = 1 - (gaussianReal 0 1).real (Set.Iio x) := by
    rw [← Set.compl_Iio, probReal_compl_eq_one_sub measurableSet_Iio]
  have h3 : (gaussianReal 0 1).real (Set.Iio x) = (gaussianReal 0 1).real (Set.Iic x) := by
    rw [← Set.Iio_union_right, measureReal_union (by simp) (measurableSet_singleton x)]
    simp [measureReal_def, gaussian_singleton]
  rw [h1, h2, h3]

/-- The standard normal CDF is strictly increasing. -/
lemma N_strictMono : StrictMono N := by
  open MeasureTheory ProbabilityTheory in
  intro x y hxy
  unfold N
  rw [cdf_eq_real, cdf_eq_real]
  have hpos : 0 < gaussianReal 0 1 (Set.Ioc x y) := by
    rw [pos_iff_ne_zero]
    intro h
    have := gaussianReal_absolutelyContinuous' 0 one_ne_zero h
    simp [Real.volume_Ioc] at this
    linarith
  have hu : Set.Iic y = Set.Iic x ∪ Set.Ioc x y := (Set.Iic_union_Ioc_eq_Iic hxy.le).symm
  rw [hu, measureReal_union
    (Set.disjoint_left.2 (fun a ha hb => by simp at ha hb; linarith)) measurableSet_Ioc]
  have : 0 < (gaussianReal 0 1).real (Set.Ioc x y) := by
    rw [measureReal_def]; exact ENNReal.toReal_pos hpos.ne' (measure_ne_top _ _)
  linarith

/-- `N(x) = N(-x)` exactly when `x = 0`. -/
lemma N_eq_N_neg_iff (x : ℝ) : N x = N (-x) ↔ x = 0 := by
  constructor
  · intro h
    have := N_strictMono.injective h
    linarith
  · intro h; subst h; simp

/-- With positive `F` and `K`, `log (F/K) = c` exactly when `K = F e^{-c}`. -/
lemma log_div_eq_iff (F K c : ℝ) (hF : 0 < F) (hK : 0 < K) :
    log (F / K) = c ↔ K = F * exp (-c) := by
  constructor
  · intro h
    have := exp_log (div_pos hF hK)
    rw [h] at this
    rw [exp_neg, this]
    field_simp
  · intro h
    rw [h, div_mul_eq_div_div, div_self hF.ne', one_div, ← exp_neg, neg_neg, log_exp]

/-- The forward is positive when spot is positive. -/
lemma fwd_pos (S rd rf T : ℝ) (hS : 0 < S) : 0 < fwd S rd rf T := by
  unfold fwd; positivity

#print axioms gaussian_singleton
#print axioms N_neg
#print axioms N_strictMono
#print axioms N_eq_N_neg_iff
#print axioms log_div_eq_iff
#print axioms fwd_pos

/-- The delta-neutral straddle strike. With positive spot, strike, volatility and time,
the straddle's net spot delta, the call's `e^{-r_f T} N(d₁)` plus the put's
`-e^{-r_f T} N(-d₁)`, is zero exactly when the strike is the forward pushed up by half
the variance, `K = F e^{σ²T/2}`. So the zero exists and is unique. -/
theorem straddle_delta_zero_iff_strike_eq_forward_mul_exp_half_variance
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-rf * T) * N (d1 S K rd rf σ T) + (-(exp (-rf * T) * N (-d1 S K rd rf σ T))) = 0 ↔
      K = fwd S rd rf T * exp (σ ^ 2 * T / 2) := by
  have he : 0 < exp (-rf * T) := exp_pos _
  have hden : 0 < σ * sqrt T := mul_pos hσ (sqrt_pos.2 hT)
  have key : exp (-rf * T) * N (d1 S K rd rf σ T) + (-(exp (-rf * T) * N (-d1 S K rd rf σ T)))
      = exp (-rf * T) * (N (d1 S K rd rf σ T) - N (-d1 S K rd rf σ T)) := by ring
  rw [key, mul_eq_zero, or_iff_right he.ne', sub_eq_zero, N_eq_N_neg_iff]
  unfold d1
  rw [div_eq_zero_iff, or_iff_left hden.ne', add_eq_zero_iff_eq_neg,
    log_div_eq_iff _ _ _ (fwd_pos S rd rf T hS) hK, neg_neg]

/-- Premium paid in the foreign currency. Each leg's premium-adjusted delta is its spot
delta minus its premium divided by spot. The straddle's net premium-adjusted delta is
zero exactly when the strike is the forward pushed down by half the variance,
`K = F e^{-σ²T/2}`. -/
theorem premium_adjusted_straddle_delta_zero_iff_strike_eq_forward_mul_exp_neg_half_variance
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (exp (-rf * T) * N (d1 S K rd rf σ T) - gkCall S K rd rf σ T / S) +
        (-(exp (-rf * T) * N (-d1 S K rd rf σ T)) - gkPut S K rd rf σ T / S) = 0 ↔
      K = fwd S rd rf T * exp (-(σ ^ 2 * T / 2)) := by
  have hS0 : S ≠ 0 := hS.ne'
  have hsq : 0 < sqrt T := sqrt_pos.2 hT
  have hden : 0 < σ * sqrt T := mul_pos hσ hsq
  have key : (exp (-rf * T) * N (d1 S K rd rf σ T) - gkCall S K rd rf σ T / S) +
        (-(exp (-rf * T) * N (-d1 S K rd rf σ T)) - gkPut S K rd rf σ T / S)
      = (K / S * exp (-rd * T)) * (N (d2 S K rd rf σ T) - N (-d2 S K rd rf σ T)) := by
    unfold gkCall gkPut
    field_simp
    ring
  have hc : 0 < K / S * exp (-rd * T) := by positivity
  rw [key, mul_eq_zero, or_iff_right hc.ne', sub_eq_zero, N_eq_N_neg_iff]
  unfold d2 d1
  rw [sub_eq_zero, div_eq_iff hden.ne']
  have hTT : σ * sqrt T * (σ * sqrt T) = σ ^ 2 * T := by
    rw [show σ * sqrt T * (σ * sqrt T) = σ ^ 2 * (sqrt T * sqrt T) by ring,
      mul_self_sqrt hT.le]
  rw [hTT, ← log_div_eq_iff _ _ _ (fwd_pos S rd rf T hS) hK]
  constructor <;> intro h <;> linarith

/-- Forward at-the-money: the Garman-Kohlhagen call and put at the same strike cost the
same exactly when the strike is the forward, `K = F`. -/
theorem call_eq_put_iff_strike_eq_forward
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    gkCall S K rd rf σ T = gkPut S K rd rf σ T ↔ K = fwd S rd rf T := by
  have hdiff : gkCall S K rd rf σ T - gkPut S K rd rf σ T
      = S * exp (-rf * T) - K * exp (-rd * T) := by
    unfold gkCall gkPut
    rw [N_neg (d1 S K rd rf σ T), N_neg (d2 S K rd rf σ T)]
    ring
  rw [← sub_eq_zero, hdiff, sub_eq_zero]
  unfold fwd
  have h1 : exp ((rd - rf) * T) = exp (-rf * T) / exp (-rd * T) := by
    rw [← exp_sub]; ring_nf
  rw [h1]
  have he : 0 < exp (-rd * T) := exp_pos _
  constructor
  · intro h; rw [← mul_div_assoc, eq_div_iff he.ne']; linarith
  · intro h; rw [h]; field_simp

/-! Worked numbers from the card, EURUSD: `S = 1.10`, `r_d = 5%`, `r_f = 3%`,
`σ = 10%`, `T = 1`, written as exact fractions. -/

-- `d₁` at spot ATM (`K = S`) is `0.02/0.10 + 0.05 = 0.25`.
example : d1 (11 / 10) (11 / 10) (1 / 20) (3 / 100) (1 / 10) 1 = 1 / 4 := by
  unfold d1 fwd
  rw [show (11 / 10 : ℝ) * exp ((1 / 20 - 3 / 100) * 1) / (11 / 10) = exp ((1 / 20 - 3 / 100) * 1) by
    field_simp, log_exp, sqrt_one]
  norm_num

-- `d₁` at forward ATM (`K = F`) is `0.05`.
example : d1 (11 / 10) (fwd (11 / 10) (1 / 20) (3 / 100) 1) (1 / 20) (3 / 100) (1 / 10) 1
    = 1 / 20 := by
  unfold d1
  rw [div_self (fwd_pos _ _ _ _ (by norm_num)).ne', log_one, sqrt_one]
  norm_num

-- `d₁` at the DNS strike `F e^{0.005}` is `0`.
example : d1 (11 / 10) (fwd (11 / 10) (1 / 20) (3 / 100) 1 * exp ((1 / 10) ^ 2 * 1 / 2))
    (1 / 20) (3 / 100) (1 / 10) 1 = 0 := by
  unfold d1
  rw [div_mul_cancel_left₀ (fwd_pos _ _ _ _ (by norm_num)).ne', log_inv, log_exp, sqrt_one]
  norm_num

-- `d₁` at the premium-adjusted DNS strike `F e^{-0.005}` is `0.10`.
example : d1 (11 / 10) (fwd (11 / 10) (1 / 20) (3 / 100) 1 * exp (-((1 / 10) ^ 2 * 1 / 2)))
    (1 / 20) (3 / 100) (1 / 10) 1 = 1 / 10 := by
  unfold d1
  rw [div_mul_cancel_left₀ (fwd_pos _ _ _ _ (by norm_num)).ne', log_inv, log_exp, sqrt_one]
  norm_num

-- Try changing: at 20% vol, half the variance (0.02) equals the carry, so the
-- premium-adjusted DNS strike lands exactly on today's rate, 1.1000.
example : fwd (11 / 10) (1 / 20) (3 / 100) 1 * exp (-((1 / 5 : ℝ) ^ 2 * 1 / 2)) = 11 / 10 := by
  unfold fwd
  rw [mul_assoc, ← exp_add]
  norm_num

#print axioms straddle_delta_zero_iff_strike_eq_forward_mul_exp_half_variance
#print axioms premium_adjusted_straddle_delta_zero_iff_strike_eq_forward_mul_exp_neg_half_variance
#print axioms call_eq_put_iff_strike_eq_forward

end AtTheMoney
