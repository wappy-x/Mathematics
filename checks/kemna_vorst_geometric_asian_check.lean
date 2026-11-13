-- Kemna-Vorst: when every fixing is a futures price F(0,tᵢ) e^(σWₜᵢ - σ²tᵢ/2) driven by one Brownian path, the log of the geometric average of n equally spaced fixings is normal with centre (1/n)Σ ln F(0,tᵢ) - σ²t̄/2 and variance σ²T(n+1)(2n+1)/(6n²), its mean is the forward F_G, and its call and put are exactly Black-76 fed F_G and σ_G.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open Real MeasureTheory ProbabilityTheory
open scoped NNReal

/-! The model (the card's "When it holds"): under the pricing measure `P`, one Brownian path `W`
(Mathlib's `IsBrownianReal`) moves the whole futures curve; every futures contract that fixes has
the same volatility `σ`; the futures price quoted today for delivery at `t` is `F t`, and the
fixing at `tᵢ = iT/n` (`i = 1, …, n`, today not counted, the last on the expiry `T`) is the
lognormal `Xᵢ = F(tᵢ) e^(σ W_tᵢ - σ² tᵢ/2)`, centred on today's curve. The averaging starts today,
the average is geometric, `G = (X₁ ⋯ Xₙ)^(1/n)`, the strike `K` is fixed, and the payoff is paid
at `T` and discounted at the bank rate `r`. -/

/-- `N(x)`: the bell-curve area to the left of `x`. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The `i`-th fixing date `tᵢ = iT/n`. -/
noncomputable def fixingDate (n : ℕ) (T : ℝ) (i : ℕ) : ℝ := i * T / n

/-- The `i`-th fixing: the futures price for delivery at `tᵢ`, read at `tᵢ`,
`Xᵢ = F(0,tᵢ) e^(σ W_tᵢ - σ² tᵢ/2)`. -/
noncomputable def fixing (F : ℝ → ℝ) (σ T : ℝ) (n : ℕ) {Ω : Type*} (W : ℝ≥0 → Ω → ℝ)
    (i : ℕ) (ω : Ω) : ℝ :=
  F (fixingDate n T i) *
    exp (σ * W (fixingDate n T i).toNNReal ω - σ ^ 2 * fixingDate n T i / 2)

/-- The geometric average of the `n` fixings: multiply them and take the `n`-th root. -/
noncomputable def geomAverage (F : ℝ → ℝ) (σ T : ℝ) (n : ℕ) {Ω : Type*} (W : ℝ≥0 → Ω → ℝ)
    (ω : Ω) : ℝ :=
  (∏ i ∈ Finset.Icc 1 n, fixing F σ T n W i ω) ^ (1 / (n : ℝ))

/-- The centre of the fixing dates, `t̄ = (n+1)T/(2n)`. -/
noncomputable def centreDate (n : ℕ) (T : ℝ) : ℝ := (n + 1) * T / (2 * n)

/-- The volatility of the average, `σ_G = σ √((n+1)(2n+1)/(6n²))`. -/
noncomputable def avgVol (n : ℕ) (σ : ℝ) : ℝ := σ * √((n + 1) * (2 * n + 1) / (6 * n ^ 2))

/-- The forward of the average,
`F_G = (F(0,t₁) ⋯ F(0,tₙ))^(1/n) e^(-(σ² t̄ - σ_G² T)/2)`. -/
noncomputable def avgForward (F : ℝ → ℝ) (σ T : ℝ) (n : ℕ) : ℝ :=
  (∏ i ∈ Finset.Icc 1 n, F (fixingDate n T i)) ^ (1 / (n : ℝ)) *
    exp (-(σ ^ 2 * centreDate n T - avgVol n σ ^ 2 * T) / 2)

/-- Black-76's first distance, `d₁ = (ln(F/K) + σ²T/2) / (σ√T)`; the second is `d₂ = d₁ - σ√T`. -/
noncomputable def black76D1 (F K σ T : ℝ) : ℝ :=
  (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)

/-- The Black-76 call `e^(-rT) [F N(d₁) - K N(d₂)]`. -/
noncomputable def black76Call (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * (F * stdNormalCDF (black76D1 F K σ T)
    - K * stdNormalCDF (black76D1 F K σ T - σ * √T))

/-- The Black-76 put `e^(-rT) [K N(-d₂) - F N(-d₁)]`. -/
noncomputable def black76Put (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * (K * stdNormalCDF (-(black76D1 F K σ T - σ * √T))
    - F * stdNormalCDF (-black76D1 F K σ T))

/-! Helper lemmas. -/

lemma kv_two_sum_id (n : ℕ) : 2 * ∑ i ∈ Finset.Icc 1 n, i = n * (n + 1) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), mul_add, ih]
    ring

lemma kv_six_sum_min (n : ℕ) :
    6 * ∑ i ∈ Finset.Icc 1 n, ∑ j ∈ Finset.Icc 1 n, min i j = n * (n + 1) * (2 * n + 1) := by
  induction n with
  | zero => simp
  | succ k ih =>
    have h1 : ∀ i ∈ Finset.Icc 1 (k + 1),
        ∑ j ∈ Finset.Icc 1 (k + 1), min i j = ∑ j ∈ Finset.Icc 1 k, min i j + min i (k + 1) :=
      fun i _ => Finset.sum_Icc_succ_top (by omega) _
    rw [Finset.sum_congr rfl h1, Finset.sum_Icc_succ_top (by omega), Finset.sum_add_distrib]
    have h2 : ∑ i ∈ Finset.Icc 1 k, min i (k + 1) = ∑ i ∈ Finset.Icc 1 k, i :=
      Finset.sum_congr rfl fun i hi => by
        rw [Finset.mem_Icc] at hi; exact min_eq_left (by omega)
    have h3 : ∑ j ∈ Finset.Icc 1 k, min (k + 1) j = ∑ j ∈ Finset.Icc 1 k, j :=
      Finset.sum_congr rfl fun j hj => by
        rw [Finset.mem_Icc] at hj; exact min_eq_right (by omega)
    rw [h2, h3, min_self]
    have h4 := kv_two_sum_id k
    nlinarith [ih, h4]

lemma kv_sum_fixingDate (n : ℕ) (T : ℝ) (hn : 1 ≤ n) :
    ∑ i ∈ Finset.Icc 1 n, fixingDate n T i = (n + 1) * T / 2 := by
  have h := kv_two_sum_id n
  have h' : (2 : ℝ) * ∑ i ∈ Finset.Icc 1 n, (i : ℝ) = n * (n + 1) := by
    have := congrArg (Nat.cast : ℕ → ℝ) h; push_cast at this; linarith
  have hn' : (n : ℝ) ≠ 0 := by positivity
  unfold fixingDate
  rw [← Finset.sum_div, ← Finset.sum_mul]
  field_simp
  linear_combination T * h'

lemma kv_sum_min_fixingDate (n : ℕ) (T : ℝ) (hn : 1 ≤ n) (hT : 0 < T) :
    ∑ i ∈ Finset.Icc 1 n, ∑ j ∈ Finset.Icc 1 n,
      (((min (fixingDate n T i).toNNReal (fixingDate n T j).toNNReal : ℝ≥0)) : ℝ)
      = T * ((n + 1) * (2 * n + 1)) / 6 := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have h : ∀ i j : ℕ, (((min (fixingDate n T i).toNNReal (fixingDate n T j).toNNReal : ℝ≥0)) : ℝ)
      = T / n * min (i : ℝ) (j : ℝ) := by
    intro i j
    have hi : 0 ≤ fixingDate n T i := by unfold fixingDate; positivity
    have hj : 0 ≤ fixingDate n T j := by unfold fixingDate; positivity
    rw [NNReal.coe_min, Real.coe_toNNReal _ hi, Real.coe_toNNReal _ hj]
    unfold fixingDate
    rw [mul_min_of_nonneg _ _ (by positivity)]
    congr 1 <;> ring
  simp_rw [h, ← Finset.mul_sum]
  have h6 := kv_six_sum_min n
  have h6' : (6 : ℝ) * ∑ i ∈ Finset.Icc 1 n, ∑ j ∈ Finset.Icc 1 n, min (i : ℝ) (j : ℝ)
      = n * (n + 1) * (2 * n + 1) := by
    have := congrArg (Nat.cast : ℕ → ℝ) h6; push_cast at this; linarith
  have hs : ∑ i ∈ Finset.Icc 1 n, ∑ j ∈ Finset.Icc 1 n, min (i : ℝ) (j : ℝ)
      = n * (n + 1) * (2 * n + 1) / 6 := by linarith
  rw [hs]
  field_simp

#print axioms kv_two_sum_id
#print axioms kv_six_sum_min
#print axioms kv_sum_fixingDate
#print axioms kv_sum_min_fixingDate

lemma kv_sum_hasLaw {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (n : ℕ) (T : ℝ) (hn : 1 ≤ n) (hT : 0 < T) :
    HasLaw (fun ω => ∑ i ∈ Finset.Icc 1 n, W (fixingDate n T i).toNNReal ω)
      (gaussianReal 0 (T * ((n + 1) * (2 * n + 1)) / 6).toNNReal) P := by
  have hB := hW.toIsPreBrownianReal
  have hP := hB.isGaussianProcess.isProbabilityMeasure
  have hS : HasGaussianLaw (fun ω => ∑ i ∈ Finset.Icc 1 n, W (fixingDate n T i).toNNReal ω) P :=
    (hB.isGaussianProcess.comp_right (fun i : ℕ => (fixingDate n T i).toNNReal)).hasGaussianLaw_fun_sum
      (I := Finset.Icc 1 n)
  refine ⟨hS.aemeasurable, ?_⟩
  rw [hS.map_eq_gaussianReal]
  congr 1
  · rw [integral_finsetSum _ (fun i _ => hB.integrable_eval _)]
    simp [hB.integral_eval]
  · rw [variance_fun_sum' (fun i _ => (hB.isGaussianProcess.hasGaussianLaw_eval _).memLp_two)]
    simp_rw [hB.covariance_eval]
    rw [kv_sum_min_fixingDate n T hn hT]

#print axioms kv_sum_hasLaw

lemma kv_fixing_pos (F : ℝ → ℝ) (σ T : ℝ) (n : ℕ) {Ω : Type*} (W : ℝ≥0 → Ω → ℝ)
    (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (ω : Ω) :
    ∀ i ∈ Finset.Icc 1 n, 0 < fixing F σ T n W i ω :=
  fun i hi => mul_pos (hF i hi) (exp_pos _)

lemma kv_geomAverage_pos (F : ℝ → ℝ) (σ T : ℝ) (n : ℕ) {Ω : Type*} (W : ℝ≥0 → Ω → ℝ)
    (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (ω : Ω) :
    0 < geomAverage F σ T n W ω :=
  rpow_pos_of_pos (Finset.prod_pos (kv_fixing_pos F σ T n W hF ω)) _

lemma kv_log_geomAverage (F : ℝ → ℝ) (σ T : ℝ) (n : ℕ) {Ω : Type*} (W : ℝ≥0 → Ω → ℝ)
    (hn : 1 ≤ n) (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (ω : Ω) :
    log (geomAverage F σ T n W ω) =
      ((1 / (n : ℝ)) * (∑ i ∈ Finset.Icc 1 n, log (F (fixingDate n T i)))
          - σ ^ 2 * centreDate n T / 2)
        + σ / n * ∑ i ∈ Finset.Icc 1 n, W (fixingDate n T i).toNNReal ω := by
  have hpos := kv_fixing_pos F σ T n W hF ω
  have hn' : (n : ℝ) ≠ 0 := by have : (0 : ℝ) < n := by exact_mod_cast hn
                               exact this.ne'
  unfold geomAverage
  rw [Real.log_rpow (Finset.prod_pos hpos), Real.log_prod (fun i hi => (hpos i hi).ne')]
  have h : ∀ i ∈ Finset.Icc 1 n, log (fixing F σ T n W i ω) =
      log (F (fixingDate n T i)) + (σ * W (fixingDate n T i).toNNReal ω
        - σ ^ 2 * fixingDate n T i / 2) := by
    intro i hi
    unfold fixing
    rw [log_mul (hF i hi).ne' (exp_ne_zero _), log_exp]
  rw [Finset.sum_congr rfl h, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
    ← Finset.sum_div, ← Finset.mul_sum, kv_sum_fixingDate n T hn]
  unfold centreDate
  field_simp
  ring

lemma kv_log_normal {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P)
    (F : ℝ → ℝ) (n : ℕ) (σ T : ℝ) (hn : 1 ≤ n)
    (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (hT : 0 < T) :
    HasLaw (fun ω => log (geomAverage F σ T n W ω))
      (gaussianReal
        ((1 / (n : ℝ)) * (∑ i ∈ Finset.Icc 1 n, log (F (fixingDate n T i)))
          - σ ^ 2 * centreDate n T / 2)
        (σ ^ 2 * T * ((n + 1) * (2 * n + 1) / (6 * n ^ 2))).toNNReal) P := by
  have h := gaussianReal_const_add (gaussianReal_const_mul (kv_sum_hasLaw hW n T hn hT) (σ / n))
    ((1 / (n : ℝ)) * (∑ i ∈ Finset.Icc 1 n, log (F (fixingDate n T i)))
          - σ ^ 2 * centreDate n T / 2)
  have hfun : (fun ω => log (geomAverage F σ T n W ω)) = fun ω =>
      ((1 / (n : ℝ)) * (∑ i ∈ Finset.Icc 1 n, log (F (fixingDate n T i)))
          - σ ^ 2 * centreDate n T / 2)
        + σ / n * ∑ i ∈ Finset.Icc 1 n, W (fixingDate n T i).toNNReal ω :=
    funext (kv_log_geomAverage F σ T n W hn hF)
  rw [hfun]
  convert h using 2
  · simp
  · have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    ext
    simp only [NNReal.coe_mul, NNReal.coe_mk]
    rw [Real.coe_toNNReal _ (by positivity), Real.coe_toNNReal _ (by positivity)]
    field_simp

#print axioms kv_fixing_pos
#print axioms kv_geomAverage_pos
#print axioms kv_log_geomAverage
#print axioms kv_log_normal

lemma kv_gauss_Ici (m : ℝ) {v : ℝ≥0} (hv : v ≠ 0) (a : ℝ) :
    (gaussianReal m v).real (Set.Ici a) = stdNormalCDF ((m - a) / √(v : ℝ)) := by
  have hv' : (0 : ℝ) < v := by positivity
  have hs : 0 < √(v : ℝ) := Real.sqrt_pos.mpr hv'
  have h := gaussianReal_div_const (gaussianReal_const_sub (HasLaw.fun_id (μ := gaussianReal m v)) m)
    (√(v : ℝ))
  replace h : HasLaw (fun x : ℝ => (m - x) / √(v : ℝ)) (gaussianReal 0 1) (gaussianReal m v) := by
    convert h using 2
    · simp
    · rw [← NNReal.coe_inj]
      simp [Real.sq_sqrt hv'.le, hv]
  have h2 := h.measureReal_eq (p := fun z => z ≤ (m - a) / √(v : ℝ)) measurableSet_Iic
  have h3 : {x : ℝ | (m - x) / √(v : ℝ) ≤ (m - a) / √(v : ℝ)} = Set.Ici a := by
    ext x; simp only [Set.mem_ofPred_eq, Set.mem_Ici, div_le_div_iff_of_pos_right hs]
    constructor <;> intro h <;> linarith
  rw [h3] at h2
  rw [h2, stdNormalCDF, cdf_eq_real]
  rfl

lemma kv_gauss_Iic (m : ℝ) {v : ℝ≥0} (hv : v ≠ 0) (a : ℝ) :
    (gaussianReal m v).real (Set.Iic a) = stdNormalCDF ((a - m) / √(v : ℝ)) := by
  have hv' : (0 : ℝ) < v := by positivity
  have hs : 0 < √(v : ℝ) := Real.sqrt_pos.mpr hv'
  have h := gaussianReal_div_const (gaussianReal_sub_const (HasLaw.fun_id (μ := gaussianReal m v)) m)
    (√(v : ℝ))
  replace h : HasLaw (fun x : ℝ => (x - m) / √(v : ℝ)) (gaussianReal 0 1) (gaussianReal m v) := by
    convert h using 2
    · simp
    · rw [← NNReal.coe_inj]
      simp [Real.sq_sqrt hv'.le, hv]
  have h2 := h.measureReal_eq (p := fun z => z ≤ (a - m) / √(v : ℝ)) measurableSet_Iic
  have h3 : {x : ℝ | (x - m) / √(v : ℝ) ≤ (a - m) / √(v : ℝ)} = Set.Iic a := by
    ext x; simp [div_le_div_iff_of_pos_right hs]
  rw [h3] at h2
  rw [h2, stdNormalCDF, cdf_eq_real]
  rfl

lemma kv_gauss_tilt (m : ℝ) {v : ℝ≥0} (hv : v ≠ 0) {S : Set ℝ} (hS : MeasurableSet S) :
    ∫ y, S.indicator exp y ∂gaussianReal m v = exp (m + v / 2) * (gaussianReal (m + v) v).real S := by
  have hv' : (0 : ℝ) < v := by positivity
  rw [← integral_indicator_one hS, integral_gaussianReal_eq_integral_smul hv,
    integral_gaussianReal_eq_integral_smul hv, ← integral_const_mul]
  congr 1 with y
  by_cases hy : y ∈ S
  · simp only [Set.indicator_of_mem hy, Pi.one_apply, smul_eq_mul, mul_one]
    rw [gaussianPDFReal_def, gaussianPDFReal_def]
    simp only
    rw [mul_assoc, ← exp_add, mul_left_comm, ← exp_add]
    congr 2
    field_simp
    ring
  · simp [Set.indicator_of_notMem hy]

#print axioms kv_gauss_Ici
#print axioms kv_gauss_Iic
#print axioms kv_gauss_tilt

lemma kv_gauss_call (m : ℝ) {v : ℝ≥0} (hv : v ≠ 0) {K : ℝ} (hK : 0 < K) :
    ∫ y, max (exp y - K) 0 ∂gaussianReal m v =
      exp (m + v / 2) * stdNormalCDF ((m + v - log K) / √(v : ℝ))
        - K * stdNormalCDF ((m - log K) / √(v : ℝ)) := by
  have hfun : (fun y => max (exp y - K) 0) = fun y =>
      (Set.Ici (log K)).indicator exp y - (Set.Ici (log K)).indicator (fun _ => K) y := by
    funext y
    by_cases h : log K ≤ y
    · rw [Set.indicator_of_mem (Set.mem_Ici.mpr h), Set.indicator_of_mem (Set.mem_Ici.mpr h)]
      apply max_eq_left
      have := exp_le_exp.mpr h
      rw [exp_log hK] at this
      linarith
    · have h' : y ∉ Set.Ici (log K) := by simpa using h
      rw [Set.indicator_of_notMem h', Set.indicator_of_notMem h', sub_zero]
      apply max_eq_right
      have := exp_lt_exp.mpr (not_le.mp h)
      rw [exp_log hK] at this
      linarith
  have hexp : Integrable exp (gaussianReal m v) := by
    simpa using integrable_exp_mul_gaussianReal (μ := m) (v := v) 1
  rw [hfun, integral_sub (hexp.indicator measurableSet_Ici)
    ((integrable_const K).indicator measurableSet_Ici), kv_gauss_tilt m hv measurableSet_Ici,
    integral_indicator_const K measurableSet_Ici, kv_gauss_Ici _ hv, kv_gauss_Ici _ hv, smul_eq_mul]
  ring

lemma kv_gauss_put (m : ℝ) {v : ℝ≥0} (hv : v ≠ 0) {K : ℝ} (hK : 0 < K) :
    ∫ y, max (K - exp y) 0 ∂gaussianReal m v =
      K * stdNormalCDF ((log K - m) / √(v : ℝ))
        - exp (m + v / 2) * stdNormalCDF ((log K - (m + v)) / √(v : ℝ)) := by
  have hfun : (fun y => max (K - exp y) 0) = fun y =>
      (Set.Iic (log K)).indicator (fun _ => K) y - (Set.Iic (log K)).indicator exp y := by
    funext y
    by_cases h : y ≤ log K
    · rw [Set.indicator_of_mem (Set.mem_Iic.mpr h), Set.indicator_of_mem (Set.mem_Iic.mpr h)]
      apply max_eq_left
      have := exp_le_exp.mpr h
      rw [exp_log hK] at this
      linarith
    · have h' : y ∉ Set.Iic (log K) := by simpa using h
      rw [Set.indicator_of_notMem h', Set.indicator_of_notMem h', sub_zero]
      apply max_eq_right
      have := exp_lt_exp.mpr (not_le.mp h)
      rw [exp_log hK] at this
      linarith
  have hexp : Integrable exp (gaussianReal m v) := by
    simpa using integrable_exp_mul_gaussianReal (μ := m) (v := v) 1
  rw [hfun, integral_sub ((integrable_const K).indicator measurableSet_Iic)
    (hexp.indicator measurableSet_Iic), kv_gauss_tilt m hv measurableSet_Iic,
    integral_indicator_const K measurableSet_Iic, kv_gauss_Iic _ hv, kv_gauss_Iic _ hv, smul_eq_mul]
  ring

lemma kv_gauss_mean_exp (m : ℝ) (v : ℝ≥0) :
    ∫ y, exp y ∂gaussianReal m v = exp (m + v / 2) := by
  have h := congrFun (mgf_id_gaussianReal (μ := m) (v := v)) 1
  simp only [mgf, id, one_mul, mul_one, one_pow] at h
  exact h

#print axioms kv_gauss_call
#print axioms kv_gauss_put
#print axioms kv_gauss_mean_exp

lemma kv_black76_of_lognormal (m : ℝ) {v : ℝ≥0} (hv : v ≠ 0) {Fg K r s T : ℝ} (hK : 0 < K)
    (hT : 0 < T) (hs : 0 < s) (hFg : Fg = exp (m + v / 2)) (hvs : (v : ℝ) = s ^ 2 * T) :
    exp (-r * T) * ∫ y, max (exp y - K) 0 ∂gaussianReal m v = black76Call Fg K r s T ∧
      exp (-r * T) * ∫ y, max (K - exp y) 0 ∂gaussianReal m v = black76Put Fg K r s T := by
  subst hFg
  have hsq : √(v : ℝ) = s * √T := by rw [hvs, Real.sqrt_mul (sq_nonneg s), Real.sqrt_sq hs.le]
  have hT' : 0 < √T := Real.sqrt_pos.mpr hT
  have hTT : √T ^ 2 = T := Real.sq_sqrt hT.le
  unfold black76Call black76Put black76D1
  rw [kv_gauss_call m hv hK, kv_gauss_put m hv hK, log_div (exp_ne_zero _) hK.ne', log_exp, hsq]
  have e1 : (m + v - log K) / (s * √T) = (m + v / 2 - log K + s ^ 2 * T / 2) / (s * √T) := by
    rw [hvs]; ring
  have e2 : (m - log K) / (s * √T) =
      (m + v / 2 - log K + s ^ 2 * T / 2) / (s * √T) - s * √T := by
    rw [hvs]; field_simp; linear_combination (2 * s ^ 2) * hTT
  have e3 : (log K - m) / (s * √T) =
      -((m + v / 2 - log K + s ^ 2 * T / 2) / (s * √T) - s * √T) := by
    rw [← neg_sub m (log K), neg_div, e2]
  have e4 : (log K - (m + v)) / (s * √T) =
      -((m + v / 2 - log K + s ^ 2 * T / 2) / (s * √T)) := by
    rw [← e1, ← neg_div]; ring
  rw [e1, e2, e3, e4]
  exact ⟨rfl, rfl⟩

lemma kv_avgForward (F : ℝ → ℝ) (σ T : ℝ) (n : ℕ) (hn : 1 ≤ n)
    (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (hT : 0 < T) :
    avgForward F σ T n =
      exp (((1 / (n : ℝ)) * (∑ i ∈ Finset.Icc 1 n, log (F (fixingDate n T i)))
          - σ ^ 2 * centreDate n T / 2)
        + (((σ ^ 2 * T * ((n + 1) * (2 * n + 1) / (6 * n ^ 2))).toNNReal : ℝ≥0) : ℝ) / 2) := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  unfold avgForward avgVol
  rw [Real.coe_toNNReal _ (by positivity), rpow_def_of_pos (Finset.prod_pos hF),
    Real.log_prod (fun i hi => (hF i hi).ne'), ← exp_add, mul_pow,
    Real.sq_sqrt (by positivity)]
  congr 1
  ring

lemma kv_avgVol_pos (n : ℕ) (σ : ℝ) (hn : 1 ≤ n) (hσ : 0 < σ) : 0 < avgVol n σ := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  unfold avgVol
  exact mul_pos hσ (Real.sqrt_pos.mpr (by positivity))

lemma kv_avgVol_sq (n : ℕ) (σ T : ℝ) (hn : 1 ≤ n) (hT : 0 < T) :
    (((σ ^ 2 * T * ((n + 1) * (2 * n + 1) / (6 * n ^ 2))).toNNReal : ℝ≥0) : ℝ)
      = avgVol n σ ^ 2 * T := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  unfold avgVol
  rw [Real.coe_toNNReal _ (by positivity), mul_pow, Real.sq_sqrt (by positivity)]
  ring

#print axioms kv_black76_of_lognormal
#print axioms kv_avgForward
#print axioms kv_avgVol_pos
#print axioms kv_avgVol_sq

lemma kv_integral_comp {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P)
    (F : ℝ → ℝ) (n : ℕ) (σ T : ℝ) (hn : 1 ≤ n)
    (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (hT : 0 < T)
    (g : ℝ → ℝ) (hg : Continuous g) :
    ∫ ω, g (geomAverage F σ T n W ω) ∂P =
      ∫ y, g (exp y) ∂(gaussianReal
        ((1 / (n : ℝ)) * (∑ i ∈ Finset.Icc 1 n, log (F (fixingDate n T i)))
          - σ ^ 2 * centreDate n T / 2)
        (σ ^ 2 * T * ((n + 1) * (2 * n + 1) / (6 * n ^ 2))).toNNReal) := by
  have hL := kv_log_normal hW F n σ T hn hF hT
  rw [← hL.integral_comp (f := fun y => g (exp y)) (hg.comp continuous_exp).aestronglyMeasurable]
  congr 1
  funext ω
  simp only [Function.comp_apply, exp_log (kv_geomAverage_pos F σ T n W hF ω)]

#print axioms kv_integral_comp

/-- **Kemna-Vorst on a futures curve** (The formula; Why it works, Steps 0 to 5). With one random
path `W` moving the whole curve, one volatility `σ > 0` for every futures contract that fixes,
each fixing lognormal around its own positive futures price `F(0,tᵢ)`, `n ≥ 1` fixings at
`tᵢ = iT/n` from today to the expiry `T > 0`, a geometric average `G`, a strike `K > 0` and
payment at `T` discounted at the bank rate `r`: the call on the average, `e^(-rT)` times the
average of `max(G - K, 0)`, is Black-76 fed the forward of the average `F_G` and the volatility of
the average `σ_G`, `C_G = e^(-rT)[F_G N(d₁) - K N(d₂)]`; and the put,
`e^(-rT)` times the average of `max(K - G, 0)`, is `P_G = e^(-rT)[K N(-d₂) - F_G N(-d₁)]`. -/
theorem kemna_vorst_geometric_asian_is_black76 {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P)
    (F : ℝ → ℝ) (n : ℕ) (K r σ T : ℝ) (hn : 1 ≤ n)
    (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    exp (-r * T) * ∫ ω, max (geomAverage F σ T n W ω - K) 0 ∂P =
        black76Call (avgForward F σ T n) K r (avgVol n σ) T ∧
      exp (-r * T) * ∫ ω, max (K - geomAverage F σ T n W ω) 0 ∂P =
        black76Put (avgForward F σ T n) K r (avgVol n σ) T := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hv : (σ ^ 2 * T * ((n + 1) * (2 * n + 1) / (6 * n ^ 2))).toNNReal ≠ 0 := by
    rw [Ne, Real.toNNReal_eq_zero, not_le]; positivity
  have h1 := kv_integral_comp hW F n σ T hn hF hT (fun x => max (x - K) 0) (by fun_prop)
  have h2 := kv_integral_comp hW F n σ T hn hF hT (fun x => max (K - x) 0) (by fun_prop)
  rw [h1, h2]
  exact kv_black76_of_lognormal _ hv hK hT (kv_avgVol_pos n σ hn hσ)
    (kv_avgForward F σ T n hn hF hT) (kv_avgVol_sq n σ T hn hT)

/-- **The log of the geometric average is normal** (Steps 0, 2 and 3). In the same model, with
`n ≥ 1` fixings, positive futures prices at the fixing dates and `T > 0`, `ln G` is normal with
centre `(1/n) Σ ln F(0,tᵢ) - σ² t̄/2`, where `t̄ = (n+1)T/(2n)`, and variance
`σ²T (n+1)(2n+1)/(6n²) = σ_G² T`. So `G` is lognormal. -/
theorem log_geometric_average_is_normal {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P)
    (F : ℝ → ℝ) (n : ℕ) (σ T : ℝ) (hn : 1 ≤ n)
    (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (hT : 0 < T) :
    HasLaw (fun ω => log (geomAverage F σ T n W ω))
      (gaussianReal
        ((1 / (n : ℝ)) * (∑ i ∈ Finset.Icc 1 n, log (F (fixingDate n T i)))
          - σ ^ 2 * centreDate n T / 2)
        (σ ^ 2 * T * ((n + 1) * (2 * n + 1) / (6 * n ^ 2))).toNNReal) P := by
  exact kv_log_normal hW F n σ T hn hF hT

/-- **The forward of the average** (Step 4). In the same model, the average value of `G` under
the pricing measure is `F_G`: the geometric mean of the curve at the fixing dates, shaved by the
haircut `e^(-(σ² t̄ - σ_G² T)/2)`. -/
theorem forward_of_geometric_average {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P)
    (F : ℝ → ℝ) (n : ℕ) (σ T : ℝ) (hn : 1 ≤ n)
    (hF : ∀ i ∈ Finset.Icc 1 n, 0 < F (fixingDate n T i)) (hT : 0 < T) :
    ∫ ω, geomAverage F σ T n W ω ∂P = avgForward F σ T n := by
  have h := kv_integral_comp hW F n σ T hn hF hT (fun x => x) continuous_id
  rw [h, kv_gauss_mean_exp, kv_avgForward F σ T n hn hF hT]

/-! The card's exact worked numbers, as fractions: 52 weekly fixings, T = 1 year, σ = 1/5. -/

-- 1 + 2 + … + 52 = 52·53/2, so t̄ = 53/104.
example : ∑ m ∈ Finset.Icc 1 52, m = 52 * 53 / 2 := by decide
example : ((52 : ℚ) + 1) * 1 / (2 * 52) = 53 / 104 := by norm_num
-- Step 3: 1² + 2² + … + 52² = 52·53·105/6, and the weights (n - k + 1) squared add to the same.
example : ∑ m ∈ Finset.Icc 1 52, m ^ 2 = 52 * 53 * 105 / 6 := by decide
example : ∑ k ∈ Finset.Icc 1 52, (52 - k + 1) ^ 2 = 52 * 53 * 105 / 6 := by decide
-- Variance fraction 53·105/(6·52²) = 1855/5408 (0.3430).
example : ((52 : ℚ) + 1) * (2 * 52 + 1) / (6 * 52 ^ 2) = 1855 / 5408 := by norm_num
-- Variance of ln G: 0.04 × 1855/5408 = 1855/135200 (0.013720).
example : (1 / 5 : ℚ) ^ 2 * 1 * (1855 / 5408) = 1855 / 135200 := by norm_num
-- Haircut exponent σ² t̄ - σ_G² T = 0.04 × (53/104 - 1855/5408) = 901/135200.
example : (1 / 5 : ℚ) ^ 2 * (53 / 104) - 1855 / 135200 = 901 / 135200 := by norm_num
-- One fixing: t̄ = T and the fraction is 1, the plain call.
example : ((1 : ℚ) + 1) / (2 * 1) = 1 := by norm_num
example : ((1 : ℚ) + 1) * (2 * 1 + 1) / (6 * 1 ^ 2) = 1 := by norm_num

#print axioms kemna_vorst_geometric_asian_is_black76
#print axioms log_geometric_average_is_normal
#print axioms forward_of_geometric_average
