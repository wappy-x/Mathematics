-- Jarrow-Yildirim: when the forward index ratio is lognormal with the Jarrow-Yildirim integrated variance, the zero-coupon floor is Black's put on it discounted with the nominal bond, that variance has a closed form, cap minus floor is the swap, and a floored linker is the indexed principal plus the floor.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

/-- Hull-White bond exposure `B(u) = (1 - e^{-a u}) / a` over time left `u` at speed `a`. -/
noncomputable def jyB (a u : ℝ) : ℝ := (1 - exp (-a * u)) / a

lemma jy_int_exp_mul (t : ℝ) :
    ∫ z, exp (t * z) ∂(gaussianReal 0 1) = exp (t ^ 2 / 2) := by
  have := congrFun (mgf_fun_id_gaussianReal (μ := 0) (v := 1)) t
  unfold mgf at this
  simpa using this

lemma jy_integrable_lognormal (w : ℝ) :
    Integrable (fun z => exp (-w ^ 2 / 2 + w * z)) (gaussianReal 0 1) := by
  have h : (fun z => exp (-w ^ 2 / 2 + w * z)) = fun z => exp (-w ^ 2 / 2) * exp (w * z) := by
    funext z; rw [exp_add]
  rw [h]
  exact (integrable_exp_mul_gaussianReal w).const_mul _

lemma jy_int_lognormal (w : ℝ) :
    ∫ z, exp (-w ^ 2 / 2 + w * z) ∂(gaussianReal 0 1) = 1 := by
  simp_rw [exp_add]
  rw [integral_const_mul, jy_int_exp_mul, ← exp_add]
  ring_nf; simp

lemma jy_set_int_lognormal (w c : ℝ) :
    ∫ z in Set.Iic c, exp (-w ^ 2 / 2 + w * z) ∂(gaussianReal 0 1)
      = cdf (gaussianReal 0 1) (c - w) := by
  rw [← integral_indicator measurableSet_Iic,
    integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hpt : ∀ z, gaussianPDFReal 0 1 z • (Set.Iic c).indicator
      (fun z => exp (-w ^ 2 / 2 + w * z)) z = (Set.Iic c).indicator (gaussianPDFReal w 1) z := by
    intro z
    by_cases hz : z ∈ Set.Iic c
    · rw [Set.indicator_of_mem hz, Set.indicator_of_mem hz, smul_eq_mul]
      simp only [gaussianPDFReal, NNReal.coe_one, mul_one]
      rw [mul_assoc, ← exp_add]
      congr 2
      ring
    · rw [Set.indicator_of_notMem hz, Set.indicator_of_notMem hz, smul_zero]
  simp_rw [hpt]
  rw [integral_indicator measurableSet_Iic]
  have h1 := gaussianReal_apply_eq_integral w (v := 1) one_ne_zero (Set.Iic c)
  have hnn : 0 ≤ ∫ x in Set.Iic c, gaussianPDFReal w 1 x :=
    setIntegral_nonneg measurableSet_Iic (fun x _ => gaussianPDFReal_nonneg _ _ _)
  have h2 : (gaussianReal w 1).real (Set.Iic c) = ∫ x in Set.Iic c, gaussianPDFReal w 1 x := by
    rw [measureReal_def, h1, ENNReal.toReal_ofReal hnn]
  rw [← h2]
  have h3 : (gaussianReal 0 1).map (· + w) = gaussianReal w 1 := by
    simpa using gaussianReal_map_add_const (μ := 0) (v := 1) w
  rw [← h3, map_measureReal_apply (measurable_add_const w) measurableSet_Iic, cdf_eq_real]
  congr 1
  ext y; simp [le_sub_iff_add_le]

lemma jy_put_core (G L w : ℝ) (hG : 0 < G) (hL : 0 < L) (hw : 0 < w) :
    ∫ z, max (L - G * exp (-w ^ 2 / 2 + w * z)) 0 ∂(gaussianReal 0 1)
      = L * cdf (gaussianReal 0 1) ((log (L / G) + w ^ 2 / 2) / w)
        - G * cdf (gaussianReal 0 1) ((log (L / G) + w ^ 2 / 2) / w - w) := by
  set c := (log (L / G) + w ^ 2 / 2) / w with hc
  have hwc : w * c = log (L / G) + w ^ 2 / 2 := by rw [hc]; field_simp
  have hpt : ∀ z, max (L - G * exp (-w ^ 2 / 2 + w * z)) 0
      = (Set.Iic c).indicator (fun z => L - G * exp (-w ^ 2 / 2 + w * z)) z := by
    intro z
    by_cases hz : z ≤ c
    · rw [Set.indicator_of_mem (Set.mem_Iic.mpr hz)]
      apply max_eq_left
      have h1 : -w ^ 2 / 2 + w * z ≤ log (L / G) := by nlinarith
      have h2 : exp (-w ^ 2 / 2 + w * z) ≤ L / G := by
        calc exp (-w ^ 2 / 2 + w * z) ≤ exp (log (L / G)) := exp_le_exp.mpr h1
          _ = L / G := exp_log (div_pos hL hG)
      have h3 : G * exp (-w ^ 2 / 2 + w * z) ≤ L := by
        rw [le_div_iff₀ hG] at h2; linarith
      linarith
    · rw [Set.indicator_of_notMem (by simpa using hz)]
      apply max_eq_right
      push Not at hz
      have h1 : log (L / G) < -w ^ 2 / 2 + w * z := by nlinarith
      have h2 : L / G < exp (-w ^ 2 / 2 + w * z) := by
        calc L / G = exp (log (L / G)) := (exp_log (div_pos hL hG)).symm
          _ < exp (-w ^ 2 / 2 + w * z) := exp_lt_exp.mpr h1
      rw [div_lt_iff₀ hG] at h2; linarith
  simp_rw [hpt]
  rw [integral_indicator measurableSet_Iic, integral_sub, setIntegral_const, integral_const_mul,
    jy_set_int_lognormal, cdf_eq_real, smul_eq_mul, cdf_eq_real]
  · ring
  · exact (integrable_const L).integrableOn
  · exact ((jy_integrable_lognormal w).const_mul G).integrableOn

lemma jy_hd_exp (a T t : ℝ) :
    HasDerivAt (fun t => exp (-a * (T - t))) (a * exp (-a * (T - t))) t := by
  have := (((hasDerivAt_id' t).const_sub T).const_mul (-a)).exp
  convert this using 1
  ring

lemma jy_hd1 (a T t : ℝ) (ha : a ≠ 0) :
    HasDerivAt (fun t => t - exp (-a * (T - t)) / a) (a * jyB a (T - t)) t := by
  have := (hasDerivAt_id' t).sub ((jy_hd_exp a T t).div_const a)
  convert this using 1
  unfold jyB; field_simp

lemma jy_hd2 (a T t : ℝ) (ha : a ≠ 0) :
    HasDerivAt (fun t => t - 2 * exp (-a * (T - t)) / a + exp (-a * (T - t)) ^ 2 / (2 * a))
      (a ^ 2 * jyB a (T - t) ^ 2) t := by
  have h := jy_hd_exp a T t
  have := ((hasDerivAt_id' t).sub ((h.const_mul 2).div_const a)).add ((h.pow 2).div_const (2 * a))
  convert this using 1
  unfold jyB; field_simp; ring

lemma jy_hd3 (a b T t : ℝ) (ha : a ≠ 0) (hb : b ≠ 0) (hab : a + b ≠ 0) :
    HasDerivAt (fun t => t - exp (-a * (T - t)) / a - exp (-b * (T - t)) / b
        + exp (-a * (T - t)) * exp (-b * (T - t)) / (a + b))
      (a * b * jyB a (T - t) * jyB b (T - t)) t := by
  have h1 := jy_hd_exp a T t
  have h2 := jy_hd_exp b T t
  have := (((hasDerivAt_id' t).sub (h1.div_const a)).sub (h2.div_const b)).add
    ((h1.mul h2).div_const (a + b))
  convert this using 1
  unfold jyB; field_simp; ring


lemma jy_parity (G K w : ℝ) :
    ∫ z, max (G * exp (-w ^ 2 / 2 + w * z) - K) 0 ∂(gaussianReal 0 1)
      - ∫ z, max (K - G * exp (-w ^ 2 / 2 + w * z)) 0 ∂(gaussianReal 0 1)
      = G - K := by
  have hi : Integrable (fun z => G * exp (-w ^ 2 / 2 + w * z) - K) (gaussianReal 0 1) :=
    ((jy_integrable_lognormal w).const_mul G).sub (integrable_const K)
  have hi2 : Integrable (fun z => K - G * exp (-w ^ 2 / 2 + w * z)) (gaussianReal 0 1) :=
    (integrable_const K).sub ((jy_integrable_lognormal w).const_mul G)
  rw [← integral_sub hi.pos_part hi2.pos_part]
  have hpt : ∀ z, max (G * exp (-w ^ 2 / 2 + w * z) - K) 0
      - max (K - G * exp (-w ^ 2 / 2 + w * z)) 0
      = G * exp (-w ^ 2 / 2 + w * z) - K := by
    intro z
    rcases le_total (G * exp (-w ^ 2 / 2 + w * z)) K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  simp_rw [hpt]
  rw [integral_sub, integral_const_mul, jy_int_lognormal]
  · simp
  · exact (jy_integrable_lognormal w).const_mul G
  · exact integrable_const K

lemma jy_linker (F w : ℝ) :
    ∫ z, max (F * exp (-w ^ 2 / 2 + w * z)) 1 ∂(gaussianReal 0 1)
      = F + ∫ z, max (1 - F * exp (-w ^ 2 / 2 + w * z)) 0 ∂(gaussianReal 0 1) := by
  have hi : Integrable (fun z => F * exp (-w ^ 2 / 2 + w * z)) (gaussianReal 0 1) :=
    (jy_integrable_lognormal w).const_mul F
  have hi2 : Integrable (fun z => 1 - F * exp (-w ^ 2 / 2 + w * z)) (gaussianReal 0 1) :=
    (integrable_const 1).sub hi
  have hpt : ∀ z, max (F * exp (-w ^ 2 / 2 + w * z)) 1
      = F * exp (-w ^ 2 / 2 + w * z) + max (1 - F * exp (-w ^ 2 / 2 + w * z)) 0 := by
    intro z
    rcases le_total (F * exp (-w ^ 2 / 2 + w * z)) 1 with h | h
    · rw [max_eq_right h, max_eq_left (by linarith)]; ring
    · rw [max_eq_left h, max_eq_right (by linarith)]; ring
  simp_rw [hpt]
  rw [integral_add hi hi2.pos_part, integral_const_mul, jy_int_lognormal, mul_one]

/-- Jarrow-Yildirim zero-coupon floor. Nominal and real rates are Hull-White with speeds
`aN, aR > 0` and noise sizes `σN, σR`; the index wobbles at a fixed `σI`; the three
correlations `ρNR, ρNI, ρRI` are constant. Let `w² = v² T` be the integrated variance of the
forward index ratio,
`∫₀ᵀ [σI² + σN² B_N² + σR² B_R² + 2ρNI σN σI B_N - 2ρRI σR σI B_R - 2ρNR σN σR B_N B_R] dt`
with `B_N = B_N(t,T)`, `B_R = B_R(t,T)`, and `w > 0`. The index ratio at `T` is then
`X(T) = F exp(-w²/2 + w Z)` with `Z` a standard bell-curve draw and `F = P_r(0,T)/P_n(0,T)`.
For strike ratio `K > 0`, the floor paying `100 max(K - X(T), 0)` in dollars at `T`, discounted
with the nominal bond `P_n`, costs `100 P_n [K N(-d₂) - F N(-d₁)]`, where
`d₁ = (ln(F/K) + w²/2) / w` and `d₂ = d₁ - w`. -/
theorem jy_zero_coupon_floor_black
    (aN aR σN σR σI ρNR ρNI ρRI T Pn F K w : ℝ)
    (haN : 0 < aN) (haR : 0 < aR) (hF : 0 < F) (hK : 0 < K) (hw : 0 < w)
    (hvar : w ^ 2 = ∫ t in (0 : ℝ)..T,
      (σI ^ 2 + σN ^ 2 * jyB aN (T - t) ^ 2 + σR ^ 2 * jyB aR (T - t) ^ 2
        + 2 * ρNI * σN * σI * jyB aN (T - t) - 2 * ρRI * σR * σI * jyB aR (T - t)
        - 2 * ρNR * σN * σR * jyB aN (T - t) * jyB aR (T - t))) :
    100 * Pn * ∫ z, max (K - F * exp (-w ^ 2 / 2 + w * z)) 0 ∂(gaussianReal 0 1)
      = 100 * Pn * (K * cdf (gaussianReal 0 1) (-((log (F / K) + w ^ 2 / 2) / w - w))
          - F * cdf (gaussianReal 0 1) (-((log (F / K) + w ^ 2 / 2) / w))) := by
  rw [jy_put_core F K w hF hK hw]
  have hlog : log (K / F) = -log (F / K) := by rw [← log_inv, inv_div]
  rw [hlog]
  generalize log (F / K) = l
  have e1 : (-l + w ^ 2 / 2) / w = -((l + w ^ 2 / 2) / w - w) := by
    field_simp; ring
  have e2 : (-l + w ^ 2 / 2) / w - w = -((l + w ^ 2 / 2) / w) := by
    field_simp; ring
  rw [e2, e1]

/-- The Jarrow-Yildirim variance in closed form: integrating the forward ratio's instantaneous
variance over `t` from `0` to `T`, with `B_N = B_{aN}(T - t)` and `B_R = B_{aR}(T - t)`, gives
`σI² T + σN² (T - 2B_{aN}(T) + B_{2aN}(T))/aN² + σR² (T - 2B_{aR}(T) + B_{2aR}(T))/aR²
 + 2ρNI σN σI (T - B_{aN}(T))/aN - 2ρRI σR σI (T - B_{aR}(T))/aR
 - 2ρNR σN σR (T - B_{aN}(T) - B_{aR}(T) + B_{aN+aR}(T))/(aN aR)`. -/
theorem jy_variance_closed_form
    (aN aR σN σR σI ρNR ρNI ρRI T : ℝ) (haN : 0 < aN) (haR : 0 < aR) :
    ∫ t in (0 : ℝ)..T,
      (σI ^ 2 + σN ^ 2 * jyB aN (T - t) ^ 2 + σR ^ 2 * jyB aR (T - t) ^ 2
        + 2 * ρNI * σN * σI * jyB aN (T - t) - 2 * ρRI * σR * σI * jyB aR (T - t)
        - 2 * ρNR * σN * σR * jyB aN (T - t) * jyB aR (T - t))
      = σI ^ 2 * T
        + σN ^ 2 * (T - 2 * jyB aN T + jyB (2 * aN) T) / aN ^ 2
        + σR ^ 2 * (T - 2 * jyB aR T + jyB (2 * aR) T) / aR ^ 2
        + 2 * ρNI * σN * σI * (T - jyB aN T) / aN
        - 2 * ρRI * σR * σI * (T - jyB aR T) / aR
        - 2 * ρNR * σN * σR * (T - jyB aN T - jyB aR T + jyB (aN + aR) T) / (aN * aR) := by
  have hN : aN ≠ 0 := haN.ne'
  have hR : aR ≠ 0 := haR.ne'
  have hNR : aN + aR ≠ 0 := by positivity
  have hd : ∀ x ∈ Set.uIcc (0 : ℝ) T, HasDerivAt
      (fun t => σI ^ 2 * t
        + σN ^ 2 / aN ^ 2 * (t - 2 * exp (-aN * (T - t)) / aN + exp (-aN * (T - t)) ^ 2 / (2 * aN))
        + σR ^ 2 / aR ^ 2 * (t - 2 * exp (-aR * (T - t)) / aR + exp (-aR * (T - t)) ^ 2 / (2 * aR))
        + 2 * ρNI * σN * σI / aN * (t - exp (-aN * (T - t)) / aN)
        - 2 * ρRI * σR * σI / aR * (t - exp (-aR * (T - t)) / aR)
        - 2 * ρNR * σN * σR / (aN * aR) * (t - exp (-aN * (T - t)) / aN - exp (-aR * (T - t)) / aR
            + exp (-aN * (T - t)) * exp (-aR * (T - t)) / (aN + aR)))
      (σI ^ 2 + σN ^ 2 * jyB aN (T - x) ^ 2 + σR ^ 2 * jyB aR (T - x) ^ 2
        + 2 * ρNI * σN * σI * jyB aN (T - x) - 2 * ρRI * σR * σI * jyB aR (T - x)
        - 2 * ρNR * σN * σR * jyB aN (T - x) * jyB aR (T - x)) x := by
    intro x _
    have := (((((hasDerivAt_id' x).const_mul (σI ^ 2)).add
      ((jy_hd2 aN T x hN).const_mul (σN ^ 2 / aN ^ 2))).add
      ((jy_hd2 aR T x hR).const_mul (σR ^ 2 / aR ^ 2))).add
      ((jy_hd1 aN T x hN).const_mul (2 * ρNI * σN * σI / aN))).sub
      ((jy_hd1 aR T x hR).const_mul (2 * ρRI * σR * σI / aR)) |>.sub
      ((jy_hd3 aN aR T x hN hR hNR).const_mul (2 * ρNR * σN * σR / (aN * aR)))
    convert this using 1
    field_simp
  have hint : IntervalIntegrable (fun x => σI ^ 2 + σN ^ 2 * jyB aN (T - x) ^ 2
        + σR ^ 2 * jyB aR (T - x) ^ 2
        + 2 * ρNI * σN * σI * jyB aN (T - x) - 2 * ρRI * σR * σI * jyB aR (T - x)
        - 2 * ρNR * σN * σR * jyB aN (T - x) * jyB aR (T - x)) MeasureTheory.volume 0 T := by
    apply Continuous.intervalIntegrable
    unfold jyB
    fun_prop
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd hint]
  simp only [sub_self, mul_zero, exp_zero, sub_zero]
  have e1 : exp (-(2 * aN) * T) = exp (-aN * T) ^ 2 := by rw [← exp_nat_mul]; ring_nf
  have e2 : exp (-(2 * aR) * T) = exp (-aR * T) ^ 2 := by rw [← exp_nat_mul]; ring_nf
  have e3 : exp (-(aN + aR) * T) = exp (-aN * T) * exp (-aR * T) := by rw [← exp_add]; ring_nf
  unfold jyB
  rw [e1, e2, e3]
  field_simp
  ring

/-- Cap-floor parity and the linker split. With the index ratio `X(T) = F exp(-w²/2 + w Z)`,
the cap minus the floor at one strike `K` is the zero-coupon swap `100 P_n (F - K)`, which needs
no volatility; and a linker's floored principal `100 max(X(T), 1)` is worth the indexed principal
`100 P_n F = 100 P_r` plus the zero-coupon floor struck at `1`. -/
theorem zc_cap_sub_floor_eq_swap_and_linker_split (Pn F K w : ℝ) :
    (100 * Pn * ∫ z, max (F * exp (-w ^ 2 / 2 + w * z) - K) 0 ∂(gaussianReal 0 1)
        - 100 * Pn * ∫ z, max (K - F * exp (-w ^ 2 / 2 + w * z)) 0 ∂(gaussianReal 0 1)
      = 100 * Pn * (F - K)) ∧
    (100 * Pn * ∫ z, max (F * exp (-w ^ 2 / 2 + w * z)) 1 ∂(gaussianReal 0 1)
      = 100 * Pn * F
        + 100 * Pn * ∫ z, max (1 - F * exp (-w ^ 2 / 2 + w * z)) 0 ∂(gaussianReal 0 1)) := by
  refine ⟨?_, ?_⟩
  · rw [← mul_sub, jy_parity]
  · rw [jy_linker]; ring

-- Forward index ratio at a 1 percent breakeven over 5 years: 1.01^5 = 1.0510100501.
example : (101 / 100 : ℚ) ^ 5 = 10510100501 / 10000000000 := by norm_num
-- At the house 2.5 percent breakeven: 1.025^5 = 115856201/102400000 (1.131408...).
example : (1025 / 1000 : ℚ) ^ 5 = 115856201 / 102400000 := by norm_num
-- The 3 percent cap strike: 1.03^5 = 1.1592740743.
example : (103 / 100 : ℚ) ^ 5 = 11592740743 / 10000000000 := by norm_num
-- Prices up 5 percent: 100 of face repays 105, and the floor pays nothing.
example : (100 : ℚ) * max (105 / 100) 1 = 105 ∧ (100 : ℚ) * max (1 - 105 / 100) 0 = 0 := by
  norm_num
-- Prices down 5 percent: the floor pays 5, so the floored principal is 95 + 5 = 100.
example : (100 : ℚ) * max (1 - 95 / 100) 0 = 5 ∧
    (100 : ℚ) * max (95 / 100) 1 = 100 * (95 / 100) + 100 * max (1 - 95 / 100) 0 := by
  norm_num

#print axioms jy_int_exp_mul
#print axioms jy_integrable_lognormal
#print axioms jy_int_lognormal
#print axioms jy_set_int_lognormal
#print axioms jy_put_core
#print axioms jy_hd_exp
#print axioms jy_hd1
#print axioms jy_hd2
#print axioms jy_hd3
#print axioms jy_parity
#print axioms jy_linker
#print axioms jy_zero_coupon_floor_black
#print axioms jy_variance_closed_form
#print axioms zc_cap_sub_floor_eq_swap_and_linker_split
