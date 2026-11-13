-- Inflation caps and floors in outline: under a shifted lognormal year-on-year rate, the floor and cap premiums equal sums of discounted Black puts and calls on the slid rate and slid strike, cap minus floor is the inflation swap, and the correlated-lognormal convexity factor is exp(rho vI vP).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

lemma infl_int_exp_mul (t : ℝ) :
    ∫ z, exp (t * z) ∂(gaussianReal 0 1) = exp (t ^ 2 / 2) := by
  have := congrFun (mgf_fun_id_gaussianReal (μ := 0) (v := 1)) t
  unfold mgf at this
  simpa using this

lemma infl_integrable_lognormal (w : ℝ) :
    Integrable (fun z => exp (-w ^ 2 / 2 + w * z)) (gaussianReal 0 1) := by
  have h : (fun z => exp (-w ^ 2 / 2 + w * z)) = fun z => exp (-w ^ 2 / 2) * exp (w * z) := by
    funext z; rw [exp_add]
  rw [h]
  exact (integrable_exp_mul_gaussianReal w).const_mul _

lemma infl_int_lognormal (w : ℝ) :
    ∫ z, exp (-w ^ 2 / 2 + w * z) ∂(gaussianReal 0 1) = 1 := by
  simp_rw [exp_add]
  rw [integral_const_mul, infl_int_exp_mul, ← exp_add]
  ring_nf; simp

lemma infl_cdf_neg (x : ℝ) :
    cdf (gaussianReal 0 1) (-x) = 1 - cdf (gaussianReal 0 1) x := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have h : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
    simpa using gaussianReal_map_neg (μ := 0) (v := 1)
  rw [cdf_eq_real, cdf_eq_real]
  conv_lhs => rw [← h]
  rw [map_measureReal_apply measurable_neg measurableSet_Iic]
  have hp : (fun x : ℝ => -x) ⁻¹' Set.Iic (-x) = Set.Ici x := by
    ext y; simp
  rw [hp, measureReal_congr (Ioi_ae_eq_Ici (a := x)).symm, ← Set.compl_Iic,
    probReal_compl_eq_one_sub measurableSet_Iic]

lemma infl_set_int_lognormal (w c : ℝ) :
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

lemma infl_put_core (G L w : ℝ) (hG : 0 < G) (hL : 0 < L) (hw : 0 < w) :
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
    infl_set_int_lognormal, cdf_eq_real, smul_eq_mul, cdf_eq_real]
  · ring
  · exact (integrable_const L).integrableOn
  · exact ((infl_integrable_lognormal w).const_mul G).integrableOn

lemma infl_parity (G a K w : ℝ) :
    ∫ z, max ((G * exp (-w ^ 2 / 2 + w * z) - a) - K) 0 ∂(gaussianReal 0 1)
      - ∫ z, max (K - (G * exp (-w ^ 2 / 2 + w * z) - a)) 0 ∂(gaussianReal 0 1)
      = G - a - K := by
  have hi : Integrable (fun z => G * exp (-w ^ 2 / 2 + w * z) - a - K) (gaussianReal 0 1) :=
    (((infl_integrable_lognormal w).const_mul G).sub (integrable_const a)).sub (integrable_const K)
  have hi2 : Integrable (fun z => K - (G * exp (-w ^ 2 / 2 + w * z) - a)) (gaussianReal 0 1) :=
    (integrable_const K).sub (((infl_integrable_lognormal w).const_mul G).sub (integrable_const a))
  rw [← integral_sub hi.pos_part hi2.pos_part]
  have hpt : ∀ z, max ((G * exp (-w ^ 2 / 2 + w * z) - a) - K) 0
      - max (K - (G * exp (-w ^ 2 / 2 + w * z) - a)) 0
      = G * exp (-w ^ 2 / 2 + w * z) - a - K := by
    intro z
    rcases le_total (G * exp (-w ^ 2 / 2 + w * z) - a) K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  simp_rw [hpt]
  rw [integral_sub, integral_sub, integral_const_mul, infl_int_lognormal]
  · simp
  · exact (infl_integrable_lognormal w).const_mul G
  · exact integrable_const a
  · exact ((infl_integrable_lognormal w).const_mul G).sub (integrable_const a)
  · exact integrable_const K

lemma infl_floorlet (F K a σ t : ℝ) (hG : 0 < F + a) (hL : 0 < K + a) (hσ : 0 < σ) (ht : 0 < t) :
    ∫ z, max (K - ((F + a) * exp (-(σ * √t) ^ 2 / 2 + σ * √t * z) - a)) 0
        ∂(gaussianReal 0 1)
      = (K + a) * cdf (gaussianReal 0 1)
            (-((log ((F + a) / (K + a)) + σ ^ 2 * t / 2) / (σ * √t) - σ * √t))
          - (F + a) * cdf (gaussianReal 0 1)
            (-((log ((F + a) / (K + a)) + σ ^ 2 * t / 2) / (σ * √t))) := by
  have hw : 0 < σ * √t := mul_pos hσ (sqrt_pos.mpr ht)
  have hpt : ∀ z, max (K - ((F + a) * exp (-(σ * √t) ^ 2 / 2 + σ * √t * z) - a)) 0
      = max ((K + a) - (F + a) * exp (-(σ * √t) ^ 2 / 2 + σ * √t * z)) 0 := by
    intro z; congr 1; ring
  simp_rw [hpt]
  rw [infl_put_core (F + a) (K + a) (σ * √t) hG hL hw]
  have ht2 : σ ^ 2 * t = (σ * √t) ^ 2 := by rw [mul_pow, sq_sqrt ht.le]
  have hlog : log ((F + a) / (K + a)) = -log ((K + a) / (F + a)) := by
    rw [← log_inv, inv_div]
  rw [ht2, hlog]
  generalize σ * √t = w at hw ⊢
  generalize log ((K + a) / (F + a)) = l
  have e1 : -((-l + w ^ 2 / 2) / w - w) = (l + w ^ 2 / 2) / w := by
    field_simp; ring
  have e2 : -((-l + w ^ 2 / 2) / w) = (l + w ^ 2 / 2) / w - w := by
    field_simp; ring
  rw [e1, e2]

lemma infl_caplet (F K a σ t : ℝ) (hG : 0 < F + a) (hL : 0 < K + a) (hσ : 0 < σ) (ht : 0 < t) :
    ∫ z, max (((F + a) * exp (-(σ * √t) ^ 2 / 2 + σ * √t * z) - a) - K) 0
        ∂(gaussianReal 0 1)
      = (F + a) * cdf (gaussianReal 0 1)
            ((log ((F + a) / (K + a)) + σ ^ 2 * t / 2) / (σ * √t))
          - (K + a) * cdf (gaussianReal 0 1)
            ((log ((F + a) / (K + a)) + σ ^ 2 * t / 2) / (σ * √t) - σ * √t) := by
  have h1 := infl_parity (F + a) a K (σ * √t)
  have h2 := infl_floorlet F K a σ t hG hL hσ ht
  rw [infl_cdf_neg, infl_cdf_neg] at h2
  linarith

#print axioms infl_int_exp_mul
#print axioms infl_integrable_lognormal
#print axioms infl_int_lognormal
#print axioms infl_cdf_neg
#print axioms infl_set_int_lognormal
#print axioms infl_put_core
#print axioms infl_parity
#print axioms infl_floorlet
#print axioms infl_caplet


/-- Shifted Black formula for year-on-year floors and caps. Year `i`'s rate is
`y_i = G exp(-w²/2 + w Z) - a` with `G = F + a`, `w = σ √T_i` and `Z` a standard
bell-curve draw. With slid strike `L = K + a`, the floor (sum of discounted floorlets,
each paying `max(K - y_i, 0)`) costs `Σ M D(T_i) [L N(-d₂) - G N(-d₁)]`, and the cap
(each caplet paying `max(y_i - K, 0)`) costs `Σ M D(T_i) [G N(d₁) - L N(d₂)]`, where
`d₁ = (ln(G/L) + σ² T_i / 2) / (σ √T_i)` and `d₂ = d₁ - σ √T_i`. -/
theorem yoy_floor_cap_shifted_black
    (n : ℕ) (M F K a σ : ℝ) (T : ℕ → ℝ) (D : ℝ → ℝ)
    (hG : 0 < F + a) (hL : 0 < K + a) (hσ : 0 < σ) (hT : ∀ i, 0 < T i) :
    (∑ i ∈ Finset.Icc 1 n, M * D (T i) *
        ∫ z, max (K - ((F + a) * exp (-(σ * √(T i)) ^ 2 / 2 + σ * √(T i) * z) - a)) 0
          ∂(gaussianReal 0 1)
      = ∑ i ∈ Finset.Icc 1 n, M * D (T i) *
        ((K + a) * cdf (gaussianReal 0 1)
            (-((log ((F + a) / (K + a)) + σ ^ 2 * T i / 2) / (σ * √(T i)) - σ * √(T i)))
          - (F + a) * cdf (gaussianReal 0 1)
            (-((log ((F + a) / (K + a)) + σ ^ 2 * T i / 2) / (σ * √(T i)))))) ∧
    (∑ i ∈ Finset.Icc 1 n, M * D (T i) *
        ∫ z, max (((F + a) * exp (-(σ * √(T i)) ^ 2 / 2 + σ * √(T i) * z) - a) - K) 0
          ∂(gaussianReal 0 1)
      = ∑ i ∈ Finset.Icc 1 n, M * D (T i) *
        ((F + a) * cdf (gaussianReal 0 1)
            ((log ((F + a) / (K + a)) + σ ^ 2 * T i / 2) / (σ * √(T i)))
          - (K + a) * cdf (gaussianReal 0 1)
            ((log ((F + a) / (K + a)) + σ ^ 2 * T i / 2) / (σ * √(T i)) - σ * √(T i)))) := by
  constructor
  · exact Finset.sum_congr rfl fun i _ => by rw [infl_floorlet F K a σ (T i) hG hL hσ (hT i)]
  · exact Finset.sum_congr rfl fun i _ => by rw [infl_caplet F K a σ (T i) hG hL hσ (hT i)]

/-- Cap-floor parity: at one strike `K`, the cap premium minus the floor premium is the
inflation swap `Σ M D(T_i) (F - K)`, with no dependence on the volatility. -/
theorem yoy_cap_sub_floor_eq_swap
    (n : ℕ) (M F K a σ : ℝ) (T : ℕ → ℝ) (D : ℝ → ℝ) :
    (∑ i ∈ Finset.Icc 1 n, M * D (T i) *
        ∫ z, max (((F + a) * exp (-(σ * √(T i)) ^ 2 / 2 + σ * √(T i) * z) - a) - K) 0
          ∂(gaussianReal 0 1))
      - (∑ i ∈ Finset.Icc 1 n, M * D (T i) *
        ∫ z, max (K - ((F + a) * exp (-(σ * √(T i)) ^ 2 / 2 + σ * √(T i) * z) - a)) 0
          ∂(gaussianReal 0 1))
      = ∑ i ∈ Finset.Icc 1 n, M * D (T i) * (F - K) := by
  rw [← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [← mul_sub, infl_parity (F + a) a K (σ * √(T i))]
  ring

/-- The convexity factor of Step 4: for standard bell-curve draws `z₁` and
`z₂ = ρ z₁ + √(1 - ρ²) e` (correlation `ρ`), the average of
`exp(v_I z₁ - v_I²/2) · exp(v_P z₂ - v_P²/2)` is `exp(ρ v_I v_P)`. -/
theorem convexity_factor_correlated_lognormals
    (vI vP ρ : ℝ) (hρ₀ : -1 ≤ ρ) (hρ₁ : ρ ≤ 1) :
    ∫ p : ℝ × ℝ, exp (vI * p.1 - vI ^ 2 / 2) *
        exp (vP * (ρ * p.1 + √(1 - ρ ^ 2) * p.2) - vP ^ 2 / 2)
      ∂((gaussianReal 0 1).prod (gaussianReal 0 1))
      = exp (ρ * vI * vP) := by
  have hs : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := sq_sqrt (by nlinarith)
  have hpt : ∀ p : ℝ × ℝ, exp (vI * p.1 - vI ^ 2 / 2) *
        exp (vP * (ρ * p.1 + √(1 - ρ ^ 2) * p.2) - vP ^ 2 / 2)
      = (exp (-vI ^ 2 / 2 - vP ^ 2 / 2) * exp ((vI + vP * ρ) * p.1))
        * exp ((vP * √(1 - ρ ^ 2)) * p.2) := by
    intro p
    rw [← exp_add, ← exp_add, ← exp_add]
    congr 1; ring
  simp_rw [hpt]
  rw [integral_prod_mul (fun x => exp (-vI ^ 2 / 2 - vP ^ 2 / 2) * exp ((vI + vP * ρ) * x))
    (fun y => exp ((vP * √(1 - ρ ^ 2)) * y)), integral_const_mul, infl_int_exp_mul,
    infl_int_exp_mul, ← exp_add, ← exp_add]
  congr 1
  linear_combination (vP ^ 2 / 2) * hs

-- One year's payment on $1,000,000: prices up 2.5 percent pays $25,000.
example : (1000000 : ℚ) * (25 / 1000) = 25000 := by norm_num
-- Prices down 1 percent: the unfloored payment is minus $10,000.
example : (1000000 : ℚ) * (-1 / 100) = -10000 := by norm_num
-- The 0 percent floorlet pays $30,000 when prices fall 3 percent, nothing when they rise 3.
example : (1000000 : ℚ) * max (0 - (-3) / 100) 0 = 30000 := by norm_num
example : (1000000 : ℚ) * max (0 - 3 / 100) 0 = 0 := by norm_num
-- The 5 percent caplet pays $20,000 at 7 percent inflation and nothing at 5 percent.
example : (1000000 : ℚ) * max (7 / 100 - 5 / 100) 0 = 20000 := by norm_num
example : (1000000 : ℚ) * max (5 / 100 - 5 / 100) 0 = 0 := by norm_num
-- Slid rate and slid strike: 2.5 + 3 = 5.5 percent and 0 + 3 = 3 percent.
example : (25 / 10 : ℚ) + 3 = 55 / 10 ∧ (0 : ℚ) + 3 = 3 := by norm_num
-- The Fisher nominal rate: 1.01 × 1.025 = 1.03525.
example : (101 / 100 : ℚ) * (1025 / 1000) = 103525 / 100000 := by norm_num

#print axioms yoy_floor_cap_shifted_black
#print axioms yoy_cap_sub_floor_eq_swap
#print axioms convexity_factor_correlated_lognormals
