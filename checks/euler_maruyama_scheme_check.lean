-- Euler-Maruyama: the term the scheme drops each step averages to zero with spread √2·Δt, so over n steps it sums to a zero-mean error R of variance 2TΔt, while Euler's method on the noise-free share has n times its error tending to S₀e^(μT)μ²T²/2.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Probability.Moments.MGFAnalytic
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open MeasureTheory ProbabilityTheory Filter Topology

/-! The card's main theorem, that the strong error `E|Y_n - X_T|` of Euler-Maruyama is at most
`C √Δt` for every SDE with Lipschitz coefficients, needs Ito integrals and SDE solutions, which
Mathlib does not have. Its simulated numbers come from random draws. What Lean can state exactly is
the engine of the square-root rate: the term the scheme drops.

The model: `Z k` are independent standard bell-curve draws, each with law `gaussianReal 0 1`.
The horizon `T` is split into `n` steps of length `Δt = T / n`, and the Brownian step over step `k`
is `ΔW_k = √Δt * Z k`. The dropped term of step `k` is proportional to `ΔW_k ^ 2 - Δt`,
and `R` is the sum of these over the `n` steps. -/

lemma em_gauss_mgf : mgf id (gaussianReal 0 1) = fun t => Real.exp (t ^ 2 / 2) := by
  rw [mgf_id_gaussianReal]; funext t; simp

lemma em_deriv1 : deriv (fun t : ℝ => Real.exp (t ^ 2 / 2)) = fun t => t * Real.exp (t ^ 2 / 2) := by
  funext t
  have h := ((hasDerivAt_pow 2 t).div_const 2).exp
  convert h.deriv using 1
  push_cast; ring

lemma em_hexp (t : ℝ) : HasDerivAt (fun t : ℝ => Real.exp (t ^ 2 / 2)) (t * Real.exp (t ^ 2 / 2)) t := by
  have h := ((hasDerivAt_pow 2 t).div_const 2).exp
  convert h using 1
  push_cast; ring

lemma em_deriv2 : deriv (fun t : ℝ => t * Real.exp (t ^ 2 / 2)) =
    fun t => (1 + t ^ 2) * Real.exp (t ^ 2 / 2) := by
  funext t
  have h : HasDerivAt (fun t : ℝ => t * Real.exp (t ^ 2 / 2))
      (1 * Real.exp (t ^ 2 / 2) + t * (t * Real.exp (t ^ 2 / 2))) t :=
    (hasDerivAt_id' t).mul (em_hexp t)
  rw [h.deriv]; ring

lemma em_deriv3 : deriv (fun t : ℝ => (1 + t ^ 2) * Real.exp (t ^ 2 / 2)) =
    fun t => (3 * t + t ^ 3) * Real.exp (t ^ 2 / 2) := by
  funext t
  have h1 : HasDerivAt (fun t : ℝ => 1 + t ^ 2) (2 * t) t := by
    convert (hasDerivAt_pow 2 t).const_add 1 using 1; push_cast; ring
  have h : HasDerivAt (fun t : ℝ => (1 + t ^ 2) * Real.exp (t ^ 2 / 2))
      (2 * t * Real.exp (t ^ 2 / 2) + (1 + t ^ 2) * (t * Real.exp (t ^ 2 / 2))) t :=
    h1.mul (em_hexp t)
  rw [h.deriv]; ring

lemma em_deriv4 : deriv (fun t : ℝ => (3 * t + t ^ 3) * Real.exp (t ^ 2 / 2)) =
    fun t => (3 + 6 * t ^ 2 + t ^ 4) * Real.exp (t ^ 2 / 2) := by
  funext t
  have h1 : HasDerivAt (fun t : ℝ => 3 * t + t ^ 3) (3 + 3 * t ^ 2) t := by
    convert ((hasDerivAt_id' t).const_mul 3).add (hasDerivAt_pow 3 t) using 1; push_cast; ring
  have h : HasDerivAt (fun t : ℝ => (3 * t + t ^ 3) * Real.exp (t ^ 2 / 2))
      ((3 + 3 * t ^ 2) * Real.exp (t ^ 2 / 2) + (3 * t + t ^ 3) * (t * Real.exp (t ^ 2 / 2))) t :=
    h1.mul (em_hexp t)
  rw [h.deriv]; ring

lemma em_zero_mem : (0 : ℝ) ∈ interior (integrableExpSet id (gaussianReal 0 1)) := by
  rw [integrableExpSet_id_gaussianReal]; simp

lemma em_moment2 : ∫ x, x ^ 2 ∂(gaussianReal 0 1) = 1 := by
  have h := iteratedDeriv_mgf_zero em_zero_mem 2
  rw [em_gauss_mgf, iteratedDeriv_succ', iteratedDeriv_succ', em_deriv1, em_deriv2] at h
  simp at h
  rw [← h]

lemma em_moment4 : ∫ x, x ^ 4 ∂(gaussianReal 0 1) = 3 := by
  have h := iteratedDeriv_mgf_zero em_zero_mem 4
  rw [em_gauss_mgf, iteratedDeriv_succ', iteratedDeriv_succ', iteratedDeriv_succ',
    iteratedDeriv_succ', em_deriv1, em_deriv2, em_deriv3, em_deriv4] at h
  simp at h
  rw [← h]

lemma em_integrable_pow (k : ℕ) : Integrable (fun x : ℝ => x ^ k) (gaussianReal 0 1) := by
  have h := (memLp_id_gaussianReal (μ := 0) (v := 1) (k : NNReal)).integrable_norm_pow'
  refine h.mono' (by fun_prop) (Eventually.of_forall fun x => ?_)
  simp [norm_pow]

lemma em_poly (a b c : ℝ) :
    ∫ x, (a * x ^ 4 + b * x ^ 2 + c) ∂(gaussianReal 0 1) = 3 * a + b + c := by
  rw [integral_add, integral_add, integral_const_mul, integral_const_mul, em_moment4, em_moment2]
  · simp; ring
  · exact (em_integrable_pow 4).const_mul a
  · exact (em_integrable_pow 2).const_mul b
  · exact ((em_integrable_pow 4).const_mul a).add ((em_integrable_pow 2).const_mul b)
  · exact integrable_const c

lemma em_poly_integrable (a b c : ℝ) :
    Integrable (fun x : ℝ => a * x ^ 4 + b * x ^ 2 + c) (gaussianReal 0 1) :=
  (((em_integrable_pow 4).const_mul a).add ((em_integrable_pow 2).const_mul b)).add
    (integrable_const c)

/-- The step's dropped term as a function of the draw. -/
lemma em_dropped_eq (Δt : ℝ) (hΔt : 0 < Δt) (x : ℝ) :
    (Real.sqrt Δt * x) ^ 2 - Δt = 0 * x ^ 4 + Δt * x ^ 2 + (-Δt) := by
  rw [mul_pow, Real.sq_sqrt hΔt.le]; ring

lemma em_dropped_sq_eq (Δt : ℝ) (hΔt : 0 < Δt) (x : ℝ) :
    ((Real.sqrt Δt * x) ^ 2 - Δt) ^ 2 = Δt ^ 2 * x ^ 4 + (-2 * Δt ^ 2) * x ^ 2 + Δt ^ 2 := by
  rw [mul_pow, Real.sq_sqrt hΔt.le]; ring

lemma em_memLp (Δt : ℝ) (hΔt : 0 < Δt) :
    MemLp (fun x : ℝ => (Real.sqrt Δt * x) ^ 2 - Δt) 2 (gaussianReal 0 1) := by
  rw [memLp_two_iff_integrable_sq (by fun_prop)]
  simp_rw [em_dropped_sq_eq Δt hΔt]
  exact em_poly_integrable _ _ _

/-- One step's dropped term: mean 0, variance `2 Δt ^ 2` (helper copy of the theorem below). -/
lemma em_dropped_term
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (Δt : ℝ) (hΔt : 0 < Δt) (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P) :
    P[fun ω => (Real.sqrt Δt * Z ω) ^ 2 - Δt] = 0 ∧
      Var[fun ω => (Real.sqrt Δt * Z ω) ^ 2 - Δt; P] = 2 * Δt ^ 2 := by
  set f : ℝ → ℝ := fun x => (Real.sqrt Δt * x) ^ 2 - Δt with hf
  have hmeanν : ∫ x, f x ∂(gaussianReal 0 1) = 0 := by
    simp_rw [hf, em_dropped_eq Δt hΔt, em_poly]; ring
  have hmean : P[fun ω => f (Z ω)] = 0 := by
    rw [← hmeanν]
    exact hZ.integral_comp (f := f) (by fun_prop)
  refine ⟨hmean, ?_⟩
  have hvar : Var[fun ω => f (Z ω); P] = Var[f; gaussianReal 0 1] := by
    rw [← hZ.map_eq, variance_map (by rw [hZ.map_eq]; fun_prop) hZ.aemeasurable]
    rfl
  show Var[fun ω => f (Z ω); P] = 2 * Δt ^ 2
  rw [hvar, variance_eq_integral (by fun_prop), hmeanν]
  simp_rw [sub_zero, hf, em_dropped_sq_eq Δt hΔt, em_poly]; ring

lemma em_log_bound (x : ℝ) : ∀ᶠ n : ℕ in atTop,
    |(n : ℝ) * ((n : ℝ) * Real.log (1 + x / n) - x) + x ^ 2 / 2| ≤ 2 * |x| ^ 3 / n := by
  obtain ⟨N, hN⟩ := exists_nat_gt (2 * |x|)
  filter_upwards [eventually_ge_atTop (N + 1)] with n hn
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast (show 1 ≤ n by omega)
  have hnpos : (0 : ℝ) < n := by linarith
  have hNn : (N : ℝ) + 1 ≤ n := by exact_mod_cast hn
  set h := x / n with hh
  have hxh : x = n * h := by rw [hh]; field_simp
  have habs : |h| ≤ 1 / 2 := by
    rw [hh, abs_div, abs_of_pos hnpos, div_le_iff₀ hnpos]; linarith
  have hlt : |-h| < 1 := by rw [abs_neg]; linarith
  have key := Real.abs_log_sub_add_sum_range_le hlt 2
  have hden : 1 / 2 ≤ 1 - |h| := by linarith
  have key2 : |Real.log (1 + h) - h + h ^ 2 / 2| ≤ 2 * |h| ^ 3 := by
    have e : Real.log (1 + h) - h + h ^ 2 / 2 =
        ∑ i ∈ Finset.range 2, (-h) ^ (i + 1) / (i + 1) + Real.log (1 - -h) := by
      simp [Finset.sum_range_succ]; ring
    have e' : |-h| ^ (2 + 1) / (1 - |-h|) = |h| ^ 3 / (1 - |h|) := by
      rw [abs_neg]
    rw [e]
    refine (key.trans_eq e').trans ?_
    rw [div_le_iff₀ (by linarith)]
    have : 0 ≤ |h| ^ 3 := by positivity
    nlinarith
  have e2 : (n : ℝ) * ((n : ℝ) * Real.log (1 + h) - x) + x ^ 2 / 2 =
      (n : ℝ) ^ 2 * (Real.log (1 + h) - h + h ^ 2 / 2) := by
    rw [hxh]; ring
  rw [e2, abs_mul, abs_of_nonneg (by positivity)]
  calc (n : ℝ) ^ 2 * |Real.log (1 + h) - h + h ^ 2 / 2| ≤ (n : ℝ) ^ 2 * (2 * |h| ^ 3) :=
        mul_le_mul_of_nonneg_left key2 (by positivity)
    _ = 2 * |x| ^ 3 / n := by
        rw [hxh, abs_mul, abs_of_pos hnpos]; field_simp

lemma em_nL (x : ℝ) : Tendsto (fun n : ℕ => (n : ℝ) * ((n : ℝ) * Real.log (1 + x / n) - x))
    atTop (𝓝 (-x ^ 2 / 2)) := by
  have h0 : Tendsto (fun n : ℕ => (n : ℝ) * ((n : ℝ) * Real.log (1 + x / n) - x) + x ^ 2 / 2)
      atTop (𝓝 0) := by
    refine squeeze_zero_norm' ?_ (tendsto_const_div_atTop_nhds_zero_nat (2 * |x| ^ 3))
    filter_upwards [em_log_bound x] with n hn
    rwa [Real.norm_eq_abs]
  have := h0.sub_const (x ^ 2 / 2)
  simp only [add_sub_cancel_right, zero_sub] at this
  convert this using 2; ring

lemma em_L (x : ℝ) : Tendsto (fun n : ℕ => (n : ℝ) * Real.log (1 + x / n) - x)
    atTop (𝓝 0) := by
  have := (em_nL x).mul tendsto_one_div_atTop_nhds_zero_nat
  rw [mul_zero] at this
  refine this.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have : (n : ℝ) ≠ 0 := by exact_mod_cast (show n ≠ 0 by omega)
  field_simp

lemma em_n_expm1 (x : ℝ) : Tendsto
    (fun n : ℕ => (n : ℝ) * (Real.exp ((n : ℝ) * Real.log (1 + x / n) - x) - 1))
    atTop (𝓝 (-x ^ 2 / 2)) := by
  set L : ℕ → ℝ := fun n => (n : ℝ) * Real.log (1 + x / n) - x with hL
  have hrem : Tendsto (fun n : ℕ => (n : ℝ) * (Real.exp (L n) - 1 - L n)) atTop (𝓝 0) := by
    have hb : Tendsto (fun n : ℕ => |(n : ℝ) * L n| * |L n|) atTop (𝓝 0) := by
      have := ((em_nL x).abs).mul ((em_L x).abs)
      simpa using this
    refine squeeze_zero_norm' ?_ hb
    have hsmall : ∀ᶠ n : ℕ in atTop, |L n| ≤ 1 := by
      have := (em_L x).abs
      rw [abs_zero] at this
      exact this.eventually (ge_mem_nhds one_pos) |>.mono fun n hn => hn
    filter_upwards [hsmall] with n hn
    rw [Real.norm_eq_abs, abs_mul, abs_mul, Nat.abs_cast, mul_assoc]
    refine mul_le_mul_of_nonneg_left ?_ (by positivity)
    exact (Real.abs_exp_sub_one_sub_id_le hn).trans (le_of_eq (by rw [← sq, sq_abs]))
  have := (em_nL x).add hrem
  rw [add_zero] at this
  convert this using 2 with n
  ring

lemma em_key (x : ℝ) : Tendsto (fun n : ℕ => (n : ℝ) * (Real.exp x - (1 + x / n) ^ n))
    atTop (𝓝 (Real.exp x * x ^ 2 / 2)) := by
  have := (em_n_expm1 x).const_mul (-Real.exp x)
  rw [show -Real.exp x * (-x ^ 2 / 2) = Real.exp x * x ^ 2 / 2 by ring] at this
  refine this.congr' ?_
  obtain ⟨N, hN⟩ := exists_nat_gt (2 * |x|)
  filter_upwards [eventually_ge_atTop (N + 1)] with n hn
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast (show 1 ≤ n by omega)
  have hnpos : (0 : ℝ) < n := by linarith
  have hNn : (N : ℝ) + 1 ≤ n := by exact_mod_cast hn
  have hpos : 0 < 1 + x / n := by
    have : |x / n| < 1 := by
      rw [abs_div, abs_of_pos hnpos, div_lt_one hnpos]; linarith
    linarith [neg_abs_le (x / n)]
  have hpow : (1 + x / n) ^ n = Real.exp ((n : ℝ) * Real.log (1 + x / n)) := by
    rw [Real.exp_nat_mul, Real.exp_log hpos]
  rw [hpow, Real.exp_sub]
  field_simp
  ring

#print axioms em_gauss_mgf
#print axioms em_deriv1
#print axioms em_hexp
#print axioms em_deriv2
#print axioms em_deriv3
#print axioms em_deriv4
#print axioms em_zero_mem
#print axioms em_moment2
#print axioms em_moment4
#print axioms em_integrable_pow
#print axioms em_poly
#print axioms em_poly_integrable
#print axioms em_dropped_eq
#print axioms em_dropped_sq_eq
#print axioms em_memLp
#print axioms em_dropped_term
#print axioms em_log_bound
#print axioms em_nL
#print axioms em_L
#print axioms em_n_expm1
#print axioms em_key

/-- The dropped terms add up like a random walk: with `n` steps of length `Δt = T / n` and
Brownian steps `ΔW_k = √Δt Z_k` from independent standard normal draws `Z_k`, the sum
`R = ∑ (ΔW_k ^ 2 - Δt)` has mean 0 and variance `2 T Δt`, so its size is the square root of the step. -/
theorem dropped_terms_sum_mean_zero_variance_two_T_dt
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (T : ℝ) (hT : 0 < T) (n : ℕ) (hn : 0 < n)
    (Z : ℕ → Ω → ℝ) (hZ : ∀ k, HasLaw (Z k) (gaussianReal 0 1) P) (hind : iIndepFun Z P) :
    P[fun ω => ∑ k ∈ Finset.range n, ((Real.sqrt (T / n) * Z k ω) ^ 2 - T / n)] = 0 ∧
      Var[fun ω => ∑ k ∈ Finset.range n, ((Real.sqrt (T / n) * Z k ω) ^ 2 - T / n); P] =
        2 * T * (T / n) := by
  have hnr : (0 : ℝ) < n := by exact_mod_cast hn
  have hΔt : 0 < T / n := div_pos hT hnr
  set f : ℝ → ℝ := fun x => (Real.sqrt (T / n) * x) ^ 2 - T / n with hf
  set Y : ℕ → Ω → ℝ := fun k => f ∘ Z k with hY
  have hfm : Measurable f := by fun_prop
  have hmem : ∀ k, MemLp (Y k) 2 P := fun k => (hZ k).memLp_comp (em_memLp _ hΔt)
  have hsum : (fun ω => ∑ k ∈ Finset.range n, ((Real.sqrt (T / n) * Z k ω) ^ 2 - T / n)) =
      ∑ k ∈ Finset.range n, Y k := by
    funext ω; simp [hY, hf, Finset.sum_apply]
  constructor
  · refine (integral_finsetSum (f := fun k ω => (Real.sqrt (T / n) * Z k ω) ^ 2 - T / n) _
      (fun k _ => (hmem k).integrable one_le_two)).trans ?_
    refine Finset.sum_eq_zero fun k _ => ?_
    exact (em_dropped_term P _ hΔt (Z k) (hZ k)).1
  · rw [hsum]
    have hind' : iIndepFun Y P := hind.comp (fun _ => f) (fun _ => hfm)
    rw [IndepFun.variance_sum (fun k _ => hmem k)
      (fun i _ j _ hij => hind'.indepFun hij)]
    have : ∀ k ∈ Finset.range n, Var[Y k; P] = 2 * (T / n) ^ 2 := fun k _ =>
      (em_dropped_term P _ hΔt (Z k) (hZ k)).2
    rw [Finset.sum_congr rfl this, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    field_simp

/-- One step's dropped term is the size of the step and zero on average: for a step `Δt` and a
Brownian step `ΔW = √Δt Z` with `Z` a standard normal draw, `ΔW ^ 2 - Δt` has mean 0 and
variance `2 Δt ^ 2`, that is, standard deviation `√2 Δt`. -/
theorem dropped_term_mean_zero_variance_two_dt_sq
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (Δt : ℝ) (hΔt : 0 < Δt) (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P) :
    P[fun ω => (Real.sqrt Δt * Z ω) ^ 2 - Δt] = 0 ∧
      Var[fun ω => (Real.sqrt Δt * Z ω) ^ 2 - Δt; P] = 2 * Δt ^ 2 := by
  exact em_dropped_term P Δt hΔt Z hZ

/-- Euler's method on the noise-free share `dx/dt = μ x` is order one: with `n` steps over `[0, T]`
it ends at `S₀ (1 + μ T / n) ^ n`, and `n` times its error at `T` tends to the leading term
`S₀ e^(μT) μ² T² / 2`. -/
theorem euler_ode_error_times_n_tendsto (S₀ μ T : ℝ) :
    Tendsto (fun n : ℕ => (n : ℝ) * (S₀ * Real.exp (μ * T) - S₀ * (1 + μ * T / n) ^ n))
      atTop (𝓝 (S₀ * Real.exp (μ * T) * μ ^ 2 * T ^ 2 / 2)) := by
  have := (em_key (μ * T)).const_mul S₀
  convert this using 1
  · funext n; ring
  · congr 1; ring

/-! The card's worked numbers, exactly, as fractions: `S₀ = 50`, `μ = 8/100`, `σ = 40/100`,
one quarter-year step `Δt = 1/4`. -/

-- The log drift μ - σ²/2 is 0 for this share.
example : (8 / 100 : ℚ) - 1 / 2 * (40 / 100) ^ 2 = 0 := by norm_num
-- With Z = 2 the Brownian step is ΔW = 2 * √(1/4) = 1, since (1/2)^2 = 1/4.
example : ((1 : ℚ) / 2) ^ 2 = 1 / 4 ∧ (2 : ℚ) * (1 / 2) = 1 := by norm_num
-- Drift over the step: 0.08 × 50 × 0.25 = 1.
example : (8 / 100 : ℚ) * 50 * (1 / 4) = 1 := by norm_num
-- Noise over the step: 0.40 × 50 × 1.0 = 20.
example : (40 / 100 : ℚ) * 50 * 1 = 20 := by norm_num
-- Euler-Maruyama lands at 50 + 1 + 20 = 71.
example : (50 : ℚ) + 8 / 100 * 50 * (1 / 4) + 40 / 100 * 50 * 1 = 71 := by norm_num
-- The dropped term ½σ²S(ΔW² - Δt) = 0.08 × 50 × (1 - 0.25) = 3.
example : (1 / 2 : ℚ) * (40 / 100) ^ 2 * 50 * (1 ^ 2 - 1 / 4) = 3 := by norm_num
-- With Z = 1, ΔW = 1/2 and ΔW² = Δt exactly, so the dropped term is 0.
example : (1 / 2 : ℚ) * (40 / 100) ^ 2 * 50 * ((1 / 2) ^ 2 - 1 / 4) = 0 := by norm_num
-- R has variance 2TΔt: for T = 1 and 256 steps that is 2 × 1 × 1/256 = 1/128.
example : (2 : ℚ) * 256 * (1 / 256) ^ 2 = 2 * 1 * (1 / 256) ∧ (2 : ℚ) * 1 * (1 / 256) = 1 / 128 := by
  norm_num

#print axioms dropped_terms_sum_mean_zero_variance_two_T_dt
#print axioms dropped_term_mean_zero_variance_two_dt_sq
#print axioms euler_ode_error_times_n_tendsto
