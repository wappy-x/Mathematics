-- Automated market makers: a constant-product pool held at the market price has holdings √(k/P) and √(kP), a concave value 2√(kP) below the held line, gamma −x/(2P), and loses ½V(√R − 1)² per move, which averages to the rate σ²/8 of its value.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Convex.SpecificFunctions.Pow
import Mathlib.Probability.Distributions.Gaussian.Real

open Real MeasureTheory ProbabilityTheory Set

/-- The integral of `exp (t z)` against the standard normal law is `exp (t² / 2)`. -/
theorem gauss_exp_integral (t : ℝ) :
    ∫ z, exp (t * z) ∂(gaussianReal 0 1) = exp (t ^ 2 / 2) := by
  have h := congrFun (mgf_id_gaussianReal (μ := 0) (v := 1)) t
  simp only [mgf, id] at h
  rw [h]; congr 1; push_cast; ring

#print axioms gauss_exp_integral

/-- The constant-product pool as a short-gamma position. A pool holds `x > 0` coins and
`y > 0` dollars with `x * y = k`, and arbitrage keeps its price `y / x` at the market
price `P`. Then the holdings are `x = √(k/P)` and `y = √(kP)`, the value is
`x P + y = 2√(kP)`, and the coin holding falls as the price rises. The value curve
`V(p) = 2√(kp)` is strictly concave, its slope at `P` (the delta) is the coin holding `x`,
its second derivative (the gamma) is `-x / (2P)`, which is negative, and the
option seller's rent `½ |Γ| σ² P²` equals `σ²/8` of the pool's value. -/
theorem constant_product_pool_short_gamma_lvr_rate (k P σ x y : ℝ) (hx : 0 < x) (hy : 0 < y)
    (hrule : x * y = k) (hprice : y / x = P) :
    x = √(k / P) ∧ y = √(k * P) ∧ x * P + y = 2 * √(k * P) ∧
    StrictAntiOn (fun p : ℝ => √(k / p)) (Ioi 0) ∧
    StrictConcaveOn ℝ (Ioi 0) (fun p : ℝ => 2 * √(k * p)) ∧
    HasDerivAt (fun p : ℝ => 2 * √(k * p)) x P ∧
    deriv (deriv (fun p : ℝ => 2 * √(k * p))) P = -x / (2 * P) ∧
    -x / (2 * P) < 0 ∧
    1 / 2 * |-x / (2 * P)| * σ ^ 2 * P ^ 2 = σ ^ 2 / 8 * (x * P + y) := by
  have hP : 0 < P := hprice ▸ div_pos hy hx
  have hyx : y = P * x := by rw [← hprice]; field_simp
  have hk : k = P * x ^ 2 := by rw [← hrule, hyx]; ring
  have hkpos : 0 < k := by rw [hk]; positivity
  have h1 : x = √(k / P) := by
    rw [hk, show P * x ^ 2 / P = x ^ 2 by field_simp, sqrt_sq hx.le]
  have h2 : y = √(k * P) := by
    rw [show k * P = y ^ 2 by rw [hk, hyx]; ring, sqrt_sq hy.le]
  have h3 : x * P + y = 2 * √(k * P) := by rw [← h2, hyx]; ring
  have hD : ∀ p : ℝ, 0 < p → HasDerivAt (fun p : ℝ => 2 * √(k * p)) (k / √(k * p)) p := by
    intro p hp
    have hne : k * p ≠ 0 := (mul_pos hkpos hp).ne'
    have hsq : 0 < √(k * p) := sqrt_pos.mpr (mul_pos hkpos hp)
    have := (((hasDerivAt_id p).const_mul k).sqrt hne).const_mul 2
    refine this.congr_deriv ?_
    simp only [id, mul_one]
    field_simp
  refine ⟨h1, h2, h3, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro a ha b hb hab
    simp only
    exact sqrt_lt_sqrt (div_nonneg hkpos.le hb.le) (div_lt_div_of_pos_left hkpos ha hab)
  · obtain ⟨-, hc⟩ := strictConcaveOn_sqrt.subset Ioi_subset_Ici_self (convex_Ioi (0 : ℝ))
    refine ⟨convex_Ioi 0, fun a ha b hb hab s t hs ht hst => ?_⟩
    have := hc ha hb hab hs ht hst
    have hkk : 0 < √k := sqrt_pos.mpr hkpos
    simp only [smul_eq_mul] at this ⊢
    rw [sqrt_mul hkpos.le, sqrt_mul hkpos.le, sqrt_mul hkpos.le]
    nlinarith [mul_lt_mul_of_pos_left this hkk]
  · refine (hD P hP).congr_deriv ?_
    rw [← h2, div_eq_iff hy.ne', hrule]
  · have hev : deriv (fun p : ℝ => 2 * √(k * p)) =ᶠ[nhds P] fun p => k / √(k * p) := by
      filter_upwards [Ioi_mem_nhds hP] with p hp
      exact (hD p hp).deriv
    rw [hev.deriv_eq]
    have hne : k * P ≠ 0 := (mul_pos hkpos hP).ne'
    have hd : HasDerivAt (fun p : ℝ => k / √(k * p)) _ P := ((hasDerivAt_const P k).div (((hasDerivAt_id P).const_mul k).sqrt hne)
      (sqrt_pos.mpr (mul_pos hkpos hP)).ne')
    rw [hd.deriv]
    simp only [id, mul_one, zero_mul, zero_sub]
    rw [← h2]
    rw [hk, hyx]
    field_simp
  · exact div_neg_of_neg_of_pos (neg_neg_of_pos hx) (by positivity)
  · rw [abs_of_neg (div_neg_of_neg_of_pos (neg_neg_of_pos hx) (by positivity)), hyx]
    field_simp
    ring

/-- Impermanent loss. A pool deposited as `x₀ > 0` coins and `y₀ > 0` dollars at the
price `P₀ = y₀ / x₀` is worth `2√(x₀ y₀ P)` at a market price `P > 0`, never more than
the held value `x₀ P + y₀`, with equality only at `P = P₀`. The loss as a share of the
held value depends only on the price ratio `R = P / P₀`: it is `1 - 2√R / (1 + R)`. -/
theorem constant_product_pool_trails_holding (x₀ y₀ P₀ P : ℝ) (hx₀ : 0 < x₀) (hy₀ : 0 < y₀)
    (hP₀ : y₀ / x₀ = P₀) (hP : 0 < P) :
    2 * √(x₀ * y₀ * P) ≤ x₀ * P + y₀ ∧
    (2 * √(x₀ * y₀ * P) = x₀ * P + y₀ ↔ P = P₀) ∧
    1 - 2 * √(x₀ * y₀ * P) / (x₀ * P + y₀) = 1 - 2 * √(P / P₀) / (1 + P / P₀) := by
  have hxP : 0 < x₀ * P := mul_pos hx₀ hP
  set u := √(x₀ * P) with hu
  set v := √y₀ with hv
  have hu2 : u ^ 2 = x₀ * P := sq_sqrt hxP.le
  have hv2 : v ^ 2 = y₀ := sq_sqrt hy₀.le
  have hu0 : 0 < u := sqrt_pos.mpr hxP
  have hv0 : 0 < v := sqrt_pos.mpr hy₀
  have hs : √(x₀ * y₀ * P) = u * v := by
    rw [hu, hv, ← sqrt_mul hxP.le]; congr 1; ring
  rw [hs]
  refine ⟨?_, ?_, ?_⟩
  · nlinarith [sq_nonneg (u - v)]
  · constructor
    · intro h
      have huv : u = v := by nlinarith [sq_nonneg (u - v)]
      rw [← hP₀, eq_div_iff hx₀.ne', mul_comm, ← hu2, ← hv2, huv]
    · intro h
      have : x₀ * P = y₀ := by rw [h, ← hP₀]; field_simp
      have huv : u = v := by rw [hu, hv, this]
      rw [← hu2, ← hv2, huv]; ring
  · have hr : P / P₀ = x₀ * P / y₀ := by rw [← hP₀]; field_simp
    rw [hr, sqrt_div hxP.le, ← hu, ← hv]
    congr 1
    rw [← hu2, ← hv2]
    field_simp
    ring

/-- Loss-versus-rebalancing over one step, and its average. A rebalancer who holds the
pool's `√(k/P)` coins while the price moves from `P` to `R P` beats the pool, worth
`V(p) = 2√(kp)`, by exactly `½ V(P) (√R - 1)²`. When the step's ratio is
`R = exp(-σ² δt / 2 + σ √δt Z)` with `Z` a standard normal draw (geometric Brownian
motion with no drift over a step of `δt ≥ 0` years), the average of `(√R - 1)²` is
`2 (1 - exp(-σ² δt / 8))`, so the expected step loss is `V (1 - exp(-σ² δt / 8))`. -/
theorem lvr_one_step_loss_and_its_average (k P R σ δt : ℝ) (hk : 0 < k) (hP : 0 < P)
    (hR : 0 < R) (hδt : 0 ≤ δt) :
    √(k / P) * (R * P - P) - (2 * √(k * (R * P)) - 2 * √(k * P)) =
      1 / 2 * (2 * √(k * P)) * (√R - 1) ^ 2 ∧
    ∫ z, (√(exp (-(σ ^ 2 * δt) / 2 + σ * √δt * z)) - 1) ^ 2 ∂(gaussianReal 0 1) =
      2 * (1 - exp (-(σ ^ 2 * δt) / 8)) := by
  refine ⟨?_, ?_⟩
  · have hs : √(k * (R * P)) = √(k * P) * √R := by
      rw [show k * (R * P) = (k * P) * R by ring, sqrt_mul (by positivity)]
    have hq : √(k / P) = √(k * P) / P := by
      rw [eq_div_iff hP.ne', show k * P = k / P * P ^ 2 by field_simp,
        sqrt_mul (div_nonneg hk.le hP.le), sqrt_sq hP.le]
    have hR2 : √R ^ 2 = R := sq_sqrt hR.le
    rw [hs, hq]
    field_simp
    nlinarith [hR2]
  · set a := -(σ ^ 2 * δt) / 2
    set b := σ * √δt
    have hpt : ∀ z : ℝ, (√(exp (a + b * z)) - 1) ^ 2 =
        exp a * exp (b * z) - 2 * exp (a / 2) * exp (b / 2 * z) + 1 := by
      intro z
      rw [← exp_half]
      have h1 : exp ((a + b * z) / 2) ^ 2 = exp a * exp (b * z) := by
        rw [← exp_add, sq, ← exp_add]; congr 1; ring
      have h2 : exp ((a + b * z) / 2) = exp (a / 2) * exp (b / 2 * z) := by
        rw [← exp_add]; congr 1; ring
      rw [sub_sq, h1, h2]; ring
    simp_rw [hpt]
    have i1 : Integrable (fun z => exp a * exp (b * z)) (gaussianReal 0 1) :=
      (integrable_exp_mul_gaussianReal b).const_mul _
    have i2 : Integrable (fun z => 2 * exp (a / 2) * exp (b / 2 * z)) (gaussianReal 0 1) :=
      (integrable_exp_mul_gaussianReal (b / 2)).const_mul _
    have i3 : Integrable (fun z => exp a * exp (b * z) - 2 * exp (a / 2) * exp (b / 2 * z))
        (gaussianReal 0 1) := i1.sub i2
    rw [integral_add i3 (integrable_const _), integral_sub i1 i2,
      integral_const_mul, integral_const_mul, gauss_exp_integral, gauss_exp_integral]
    simp only [integral_const, probReal_univ, smul_eq_mul, one_mul]
    have hb2 : b ^ 2 = σ ^ 2 * δt := by
      simp only [b]; rw [mul_pow, sq_sqrt hδt]
    rw [mul_assoc 2, ← exp_add, ← exp_add, div_pow, hb2]
    simp only [a]
    have e1 : -(σ ^ 2 * δt) / 2 + σ ^ 2 * δt / 2 = 0 := by ring
    have e2 : -(σ ^ 2 * δt) / 2 / 2 + σ ^ 2 * δt / 2 ^ 2 / 2 = -(σ ^ 2 * δt) / 8 := by ring
    rw [e1, e2, exp_zero]; ring

-- The pool's constant: 10 BTC times 600,000 USDC is 6,000,000.
example : 10 * 600000 = 6000000 := by decide

-- At 60,000 the pool holds √(6,000,000 × 60,000) = 600,000 USDC, so it is worth 1,200,000,
-- the same as the wallet: 10 × 60,000 + 600,000.
example : 600000 ^ 2 = 6000000 * 60000 ∧ 2 * 600000 = 1200000 ∧
    10 * 60000 + 600000 = 1200000 := by decide

-- Held value after the move to 66,000, and the chart's wallet line at 30,000 and 120,000.
example : 10 * 66000 + 600000 = 1260000 ∧ 10 * 30000 + 600000 = 900000 ∧
    10 * 120000 + 600000 = 1800000 := by decide

-- Gamma at 60,000: -10 / (2 × 60,000) = -1/12,000 BTC per dollar.
example : -(10 : ℚ) / (2 * 60000) = -1 / 12000 := by norm_num

-- LVR rate at 80% volatility: 0.64 / 8 = 8% a year, 96,000 USD on the 1,200,000 pool,
-- and the gamma rent ½ |Γ| σ² P² gives the same 96,000.
example : (80 / 100 : ℚ) ^ 2 / 8 = 8 / 100 ∧ (80 / 100 : ℚ) ^ 2 / 8 * 1200000 = 96000 := by
  norm_num
example : (1 / 2 : ℚ) * (1 / 12000) * (80 / 100) ^ 2 * 60000 ^ 2 = 96000 := by norm_num

-- At 40% and 120% volatility: 24,000 and 216,000 USD a year.
example : (40 / 100 : ℚ) ^ 2 / 8 * 1200000 = 24000 ∧
    (120 / 100 : ℚ) ^ 2 / 8 * 1200000 = 216000 := by norm_num

-- What breaks: σ²/2 gives 384,000, σ²/4 gives 192,000, σ/8 gives 120,000.
example : (80 / 100 : ℚ) ^ 2 / 2 * 1200000 = 384000 ∧
    (80 / 100 : ℚ) ^ 2 / 4 * 1200000 = 192000 ∧ (80 / 100 : ℚ) / 8 * 1200000 = 120000 := by
  norm_num

-- Fee break-even at 0.30%: 96,000 / 0.003 = 32,000,000 USD of volume a year.
example : (96000 : ℚ) / (3 / 1000) = 32000000 := by norm_num

#print axioms constant_product_pool_short_gamma_lvr_rate
#print axioms constant_product_pool_trails_holding
#print axioms lvr_one_step_loss_and_its_average
