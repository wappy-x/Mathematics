-- Realised variance: under steady-volatility geometric Brownian motion the sum of squared log returns has mean σ²T plus a drift term of size Δt, variance 2σ⁴TΔt plus a smaller term, and so converges in mean square to the quadratic variation σ²T as the sampling gets finer.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory Filter Topology

lemma rv_gauss_integrable_pow (k : ℕ) :
    Integrable (fun x : ℝ => x ^ k) (gaussianReal 0 1) :=
  integrable_pow_of_mem_interior_integrableExpSet (X := fun x : ℝ => x) (by simp) k

lemma rv_gauss_moment_eq (k : ℕ) :
    ∫ x, x ^ k ∂(gaussianReal 0 1) = iteratedDeriv k (fun t : ℝ => Real.exp (t ^ 2 / 2)) 0 := by
  have h := iteratedDeriv_mgf_zero (X := fun x : ℝ => x) (μ := gaussianReal 0 1) (by simp) k
  rw [mgf_fun_id_gaussianReal] at h
  simp only [zero_mul, zero_add, NNReal.coe_one, one_mul] at h
  rw [h]
  simp [Pi.pow_apply]

lemma rv_deriv1 : deriv (fun t : ℝ => Real.exp (t ^ 2 / 2)) = fun t => t * Real.exp (t ^ 2 / 2) := by
  funext t
  have := ((hasDerivAt_pow 2 t).div_const 2).exp
  rw [this.deriv]
  push_cast
  ring

lemma rv_deriv2 : deriv (fun t : ℝ => t * Real.exp (t ^ 2 / 2))
    = fun t => (1 + t ^ 2) * Real.exp (t ^ 2 / 2) := by
  funext t
  have : HasDerivAt (fun t : ℝ => t * Real.exp (t ^ 2 / 2)) _ t :=
    (hasDerivAt_id t).mul ((hasDerivAt_pow 2 t).div_const 2).exp
  rw [this.deriv]
  push_cast
  simp
  ring

lemma rv_deriv3 : deriv (fun t : ℝ => (1 + t ^ 2) * Real.exp (t ^ 2 / 2))
    = fun t => (3 * t + t ^ 3) * Real.exp (t ^ 2 / 2) := by
  funext t
  have : HasDerivAt (fun t : ℝ => (1 + t ^ 2) * Real.exp (t ^ 2 / 2)) _ t :=
    (((hasDerivAt_pow 2 t).const_add 1)).mul ((hasDerivAt_pow 2 t).div_const 2).exp
  rw [this.deriv]
  push_cast
  ring

lemma rv_deriv4 : deriv (fun t : ℝ => (3 * t + t ^ 3) * Real.exp (t ^ 2 / 2))
    = fun t => (3 + 6 * t ^ 2 + t ^ 4) * Real.exp (t ^ 2 / 2) := by
  funext t
  have : HasDerivAt (fun t : ℝ => (3 * t + t ^ 3) * Real.exp (t ^ 2 / 2)) _ t :=
    ((((hasDerivAt_id t).const_mul 3).add (hasDerivAt_pow 3 t))).mul
    ((hasDerivAt_pow 2 t).div_const 2).exp
  rw [this.deriv]
  push_cast
  simp
  ring

lemma rv_moment1 : ∫ x, x ^ 1 ∂(gaussianReal 0 1) = 0 := by
  rw [rv_gauss_moment_eq]; simp [rv_deriv1]

lemma rv_moment2 : ∫ x, x ^ 2 ∂(gaussianReal 0 1) = 1 := by
  rw [rv_gauss_moment_eq]; simp [iteratedDeriv_succ, rv_deriv1, rv_deriv2]

lemma rv_moment3 : ∫ x, x ^ 3 ∂(gaussianReal 0 1) = 0 := by
  rw [rv_gauss_moment_eq]; simp [iteratedDeriv_succ, rv_deriv1, rv_deriv2, rv_deriv3]

lemma rv_moment4 : ∫ x, x ^ 4 ∂(gaussianReal 0 1) = 3 := by
  rw [rv_gauss_moment_eq]; simp [iteratedDeriv_succ, rv_deriv1, rv_deriv2, rv_deriv3, rv_deriv4]

lemma rv_integrable_sq (a b : ℝ) :
    Integrable (fun x : ℝ => (a + b * x) ^ 2) (gaussianReal 0 1) := by
  have h : (fun x : ℝ => (a + b * x) ^ 2)
      = fun x => a ^ 2 + ((2 * a * b) * x ^ 1 + b ^ 2 * x ^ 2) := by funext x; ring
  rw [h]
  exact (integrable_const _).add
    (((rv_gauss_integrable_pow 1).const_mul _).add ((rv_gauss_integrable_pow 2).const_mul _))

lemma rv_integral_sq (a b : ℝ) :
    ∫ x, (a + b * x) ^ 2 ∂(gaussianReal 0 1) = a ^ 2 + b ^ 2 := by
  have h : (fun x : ℝ => (a + b * x) ^ 2)
      = fun x => a ^ 2 + ((2 * a * b) * x ^ 1 + b ^ 2 * x ^ 2) := by funext x; ring
  have i1 := (rv_gauss_integrable_pow 1).const_mul (2 * a * b)
  have i2 := (rv_gauss_integrable_pow 2).const_mul (b ^ 2)
  have i12 : Integrable (fun x : ℝ => 2 * a * b * x ^ 1 + b ^ 2 * x ^ 2) (gaussianReal 0 1) :=
    i1.add i2
  rw [h, integral_add (integrable_const _) i12, integral_add i1 i2,
    integral_const, integral_const_mul, integral_const_mul, rv_moment1, rv_moment2]
  simp

lemma rv_four_expand (a b : ℝ) : (fun x : ℝ => (a + b * x) ^ 4)
    = fun x => a ^ 4 + ((4 * a ^ 3 * b) * x ^ 1 + ((6 * a ^ 2 * b ^ 2) * x ^ 2
      + ((4 * a * b ^ 3) * x ^ 3 + b ^ 4 * x ^ 4))) := by
  funext x; ring

lemma rv_integrable_four (a b : ℝ) :
    Integrable (fun x : ℝ => (a + b * x) ^ 4) (gaussianReal 0 1) := by
  rw [rv_four_expand]
  exact (integrable_const _).add (((rv_gauss_integrable_pow 1).const_mul _).add
    (((rv_gauss_integrable_pow 2).const_mul _).add
    (((rv_gauss_integrable_pow 3).const_mul _).add ((rv_gauss_integrable_pow 4).const_mul _))))

lemma rv_integral_four (a b : ℝ) :
    ∫ x, (a + b * x) ^ 4 ∂(gaussianReal 0 1) = a ^ 4 + 6 * a ^ 2 * b ^ 2 + 3 * b ^ 4 := by
  rw [rv_four_expand]
  have i1 := (rv_gauss_integrable_pow 1).const_mul (4 * a ^ 3 * b)
  have i2 := (rv_gauss_integrable_pow 2).const_mul (6 * a ^ 2 * b ^ 2)
  have i3 := (rv_gauss_integrable_pow 3).const_mul (4 * a * b ^ 3)
  have i4 := (rv_gauss_integrable_pow 4).const_mul (b ^ 4)
  have i34 : Integrable (fun x : ℝ => 4 * a * b ^ 3 * x ^ 3 + b ^ 4 * x ^ 4)
    (gaussianReal 0 1) := i3.add i4
  have i234 : Integrable (fun x : ℝ => 6 * a ^ 2 * b ^ 2 * x ^ 2
    + (4 * a * b ^ 3 * x ^ 3 + b ^ 4 * x ^ 4)) (gaussianReal 0 1) := i2.add i34
  have i1234 : Integrable (fun x : ℝ => 4 * a ^ 3 * b * x ^ 1 + (6 * a ^ 2 * b ^ 2 * x ^ 2
    + (4 * a * b ^ 3 * x ^ 3 + b ^ 4 * x ^ 4))) (gaussianReal 0 1) := i1.add i234
  rw [integral_add (integrable_const _) i1234,
    integral_add i1 i234, integral_add i2 i34, integral_add i3 i4,
    integral_const, integral_const_mul, integral_const_mul, integral_const_mul,
    integral_const_mul, rv_moment1, rv_moment2, rv_moment3, rv_moment4]
  simp
  ring

section
variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}

lemma rv_measurable_sq (a b : ℝ) : Measurable (fun x : ℝ => (a + b * x) ^ 2) := by fun_prop

lemma rv_omega_integrable (a b : ℝ) {Z : Ω → ℝ} (hZ : HasLaw Z (gaussianReal 0 1) P) :
    Integrable (fun ω => (a + b * Z ω) ^ 2) P :=
  hZ.integrable_comp (f := fun x : ℝ => (a + b * x) ^ 2) (rv_integrable_sq a b)

lemma rv_omega_integral (a b : ℝ) {Z : Ω → ℝ} (hZ : HasLaw Z (gaussianReal 0 1) P) :
    ∫ ω, (a + b * Z ω) ^ 2 ∂P = a ^ 2 + b ^ 2 := by
  have h := hZ.integral_comp (f := fun x : ℝ => (a + b * x) ^ 2)
    (rv_measurable_sq a b).aestronglyMeasurable
  rw [← rv_integral_sq a b, ← h]
  rfl

lemma rv_omega_memLp (a b : ℝ) {Z : Ω → ℝ} (hZ : HasLaw Z (gaussianReal 0 1) P) :
    MemLp (fun ω => (a + b * Z ω) ^ 2) 2 P := by
  have hm : MemLp (fun x : ℝ => (a + b * x) ^ 2) 2 (gaussianReal 0 1) := by
    rw [memLp_two_iff_integrable_sq (rv_measurable_sq a b).aestronglyMeasurable]
    have : (fun x : ℝ => ((a + b * x) ^ 2) ^ 2) = fun x => (a + b * x) ^ 4 := by
      funext x; ring
    rw [this]; exact rv_integrable_four a b
  exact hZ.memLp_comp hm

lemma rv_omega_variance [IsProbabilityMeasure P] (a b : ℝ) {Z : Ω → ℝ} (hZ : HasLaw Z (gaussianReal 0 1) P) :
    Var[fun ω => (a + b * Z ω) ^ 2; P] = 4 * a ^ 2 * b ^ 2 + 2 * (b ^ 2) ^ 2 := by
  rw [variance_eq_sub (rv_omega_memLp a b hZ)]
  have h4 := hZ.integral_comp (f := fun x : ℝ => (a + b * x) ^ 4) (by fun_prop)
  rw [rv_integral_four] at h4
  have e : ((fun ω => (a + b * Z ω) ^ 2) ^ 2) = (fun x : ℝ => (a + b * x) ^ 4) ∘ Z := by
    funext ω; simp only [Pi.pow_apply, Function.comp_apply]; ring
  rw [e, h4, rv_omega_integral a b hZ]
  ring

end

lemma rv_sq_dev {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {S : Ω → ℝ} (hS : MemLp S 2 P) (c : ℝ) :
    ∫ ω, (S ω - c) ^ 2 ∂P = Var[S; P] + (∫ ω, S ω ∂P - c) ^ 2 := by
  have h1 : MemLp (fun ω => S ω - c) 2 P := hS.sub (memLp_const c)
  have h2 := variance_eq_sub h1
  rw [variance_sub_const hS.aestronglyMeasurable] at h2
  have h3 : ∫ ω, (S ω - c) ^ 2 ∂P = ∫ x, ((fun ω => S ω - c) ^ 2) x ∂P := rfl
  rw [h3, h2, integral_sub (hS.integrable one_le_two) (integrable_const c), integral_const]
  simp only [probReal_univ, smul_eq_mul, one_mul]
  ring

lemma rv_mean
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (μ σ T : ℝ) (hT : 0 < T) (n : ℕ) (hn : 0 < n) (Z : Fin n → Ω → ℝ)
    (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P) :
    ∫ ω, ∑ i, ((μ - σ ^ 2 / 2) * (T / n) + σ * Real.sqrt (T / n) * Z i ω) ^ 2 ∂P
      = σ ^ 2 * T + (μ - σ ^ 2 / 2) ^ 2 * T * (T / n) := by
  rw [integral_finsetSum _ (fun i _ => rv_omega_integrable _ _ (hlaw i))]
  simp_rw [rv_omega_integral _ _ (hlaw _)]
  rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
    mul_pow σ, Real.sq_sqrt (by positivity)]
  have : (n : ℝ) ≠ 0 := by positivity
  field_simp
  ring

lemma rv_var
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (μ σ T : ℝ) (hT : 0 < T) (n : ℕ) (Z : Fin n → Ω → ℝ)
    (hind : iIndepFun Z P)
    (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P) :
    Var[fun ω => ∑ i, ((μ - σ ^ 2 / 2) * (T / n) + σ * Real.sqrt (T / n) * Z i ω) ^ 2; P]
      = 2 * σ ^ 4 * T * (T / n) + 4 * (μ - σ ^ 2 / 2) ^ 2 * σ ^ 2 * T * (T / n) ^ 2 := by
  have hY : (fun ω => ∑ i, ((μ - σ ^ 2 / 2) * (T / n) + σ * Real.sqrt (T / n) * Z i ω) ^ 2)
      = ∑ i, (fun ω => ((μ - σ ^ 2 / 2) * (T / n) + σ * Real.sqrt (T / n) * Z i ω) ^ 2) := by
    funext ω; simp [Finset.sum_apply]
  rw [hY, IndepFun.variance_sum (fun i _ => rv_omega_memLp _ _ (hlaw i))]
  · simp_rw [rv_omega_variance _ _ (hlaw _)]
    rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
      mul_pow σ, Real.sq_sqrt (by positivity)]
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    · have : (n : ℝ) ≠ 0 := by positivity
      field_simp
      ring
  · intro i _ j _ hij
    exact (hind.indepFun hij).comp (rv_measurable_sq _ _) (rv_measurable_sq _ _)


/-- The card's main theorem (Why it works, Step 3): keep the window `T` fixed and cut it into `n`
steps of length `Δt = T / n`. Under geometric Brownian motion with steady volatility `σ` and drift
`μ` and no jumps, each log return is `(μ - σ²/2) Δt + σ √Δt Z_i` with `Z_1, …, Z_n` independent
standard bell-curve draws. Then the sum of squared log returns converges in mean square to the
quadratic variation `σ² T`: the average squared distance between them tends to zero as `n` grows. -/
theorem sum_squared_log_returns_tendsto_quadratic_variation
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (μ σ T : ℝ) (hT : 0 < T) (Z : (n : ℕ) → Fin n → Ω → ℝ)
    (hind : ∀ n, iIndepFun (Z n) P)
    (hlaw : ∀ n i, HasLaw (Z n i) (gaussianReal 0 1) P) :
    Tendsto
      (fun n : ℕ => ∫ ω, (∑ i, ((μ - σ ^ 2 / 2) * (T / n) + σ * Real.sqrt (T / n) * Z n i ω) ^ 2
        - σ ^ 2 * T) ^ 2 ∂P)
      atTop (𝓝 0) := by
  have key : ∀ n : ℕ, 0 < n →
      ∫ ω, (∑ i, ((μ - σ ^ 2 / 2) * (T / n) + σ * Real.sqrt (T / n) * Z n i ω) ^ 2
        - σ ^ 2 * T) ^ 2 ∂P
      = (fun d : ℝ => 2 * σ ^ 4 * T * d + 4 * (μ - σ ^ 2 / 2) ^ 2 * σ ^ 2 * T * d ^ 2
          + ((μ - σ ^ 2 / 2) ^ 2 * T * d) ^ 2) (T / n) := by
    intro n hn
    have hS : MemLp (fun ω => ∑ i, ((μ - σ ^ 2 / 2) * (T / n)
        + σ * Real.sqrt (T / n) * Z n i ω) ^ 2) 2 P :=
      memLp_finsetSum _ (fun i _ => rv_omega_memLp _ _ (hlaw n i))
    rw [rv_sq_dev hS, rv_var μ σ T hT n (Z n) (hind n) (hlaw n),
      rv_mean μ σ T hT n hn (Z n) (hlaw n)]
    ring
  have hlim : Tendsto (fun n : ℕ => (fun d : ℝ => 2 * σ ^ 4 * T * d
      + 4 * (μ - σ ^ 2 / 2) ^ 2 * σ ^ 2 * T * d ^ 2
      + ((μ - σ ^ 2 / 2) ^ 2 * T * d) ^ 2) (T / n)) atTop (𝓝 0) := by
    have hc : Continuous (fun d : ℝ => 2 * σ ^ 4 * T * d
        + 4 * (μ - σ ^ 2 / 2) ^ 2 * σ ^ 2 * T * d ^ 2
        + ((μ - σ ^ 2 / 2) ^ 2 * T * d) ^ 2) := by fun_prop
    have h0 := (hc.tendsto 0).comp (tendsto_const_div_atTop_nhds_zero_nat T)
    convert h0 using 2 <;> simp
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with n hn using (key n hn).symm

/-- Mean of the realised sum (Detailed proof): with `n ≥ 1` steps of length `Δt = T / n` and each
log return `(μ - σ²/2) Δt + σ √Δt Z_i` for standard bell-curve draws `Z_i`, the sum of squared log
returns averages `σ² T + (μ - σ²/2)² T Δt`. So realised variance centres on `σ²`, up to a drift
term carrying a factor `Δt`. -/
theorem integral_sum_squared_log_returns
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (μ σ T : ℝ) (hT : 0 < T) (n : ℕ) (hn : 0 < n) (Z : Fin n → Ω → ℝ)
    (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P) :
    ∫ ω, ∑ i, ((μ - σ ^ 2 / 2) * (T / n) + σ * Real.sqrt (T / n) * Z i ω) ^ 2 ∂P
      = σ ^ 2 * T + (μ - σ ^ 2 / 2) ^ 2 * T * (T / n) := by
  exact rv_mean μ σ T hT n hn Z hlaw

/-- Variance of the realised sum (Detailed proof, and Step 2's wobble): with the draws `Z_i`
independent and standard normal, the sum of squared log returns has variance
`2 σ⁴ T Δt + 4 (μ - σ²/2)² σ² T Δt²`, where `Δt = T / n`. Its leading part, relative to the mean
`σ² T`, is the `√(2/n)` wobble. -/
theorem variance_sum_squared_log_returns
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (μ σ T : ℝ) (hT : 0 < T) (n : ℕ) (Z : Fin n → Ω → ℝ)
    (hind : iIndepFun Z P)
    (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P) :
    Var[fun ω => ∑ i, ((μ - σ ^ 2 / 2) * (T / n) + σ * Real.sqrt (T / n) * Z i ω) ^ 2; P]
      = 2 * σ ^ 4 * T * (T / n) + 4 * (μ - σ ^ 2 / 2) ^ 2 * σ ^ 2 * T * (T / n) ^ 2 := by
  exact rv_var μ σ T hT n Z hind hlaw

-- The card's exact worked numbers.
-- Annualising 21 daily returns: 252 / 21 = 12.
example : (252 : ℚ) / 21 = 12 := by norm_num
-- 78 five-minute prints a day for 21 days: 1,638 returns.
example : 21 * 78 = 1638 := by decide
-- Quadratic variation the path delivered: 0.04 × 21/252 = 1/300 (the card's 0.003333).
example : (4 / 100 : ℚ) * (21 / 252) = 1 / 300 := by norm_num
-- Bounce term 2 n h² / T at n = 1638, h = 0.001, T = 21/252: 0.039312.
example : (2 * 1638 * (1 / 1000) ^ 2 / (21 / 252) : ℚ) = 39312 / 1000000 := by norm_num
-- Expected five-minute total: 0.04 + 0.039312 = 0.079312.
example : (4 / 100 + 39312 / 1000000 : ℚ) = 79312 / 1000000 := by norm_num

#print axioms sum_squared_log_returns_tendsto_quadratic_variation
#print axioms integral_sum_squared_log_returns
#print axioms variance_sum_squared_log_returns
#print axioms rv_gauss_integrable_pow
#print axioms rv_gauss_moment_eq
#print axioms rv_deriv1
#print axioms rv_deriv2
#print axioms rv_deriv3
#print axioms rv_deriv4
#print axioms rv_moment1
#print axioms rv_moment2
#print axioms rv_moment3
#print axioms rv_moment4
#print axioms rv_integrable_sq
#print axioms rv_integral_sq
#print axioms rv_four_expand
#print axioms rv_integrable_four
#print axioms rv_integral_four
#print axioms rv_measurable_sq
#print axioms rv_omega_integrable
#print axioms rv_omega_integral
#print axioms rv_omega_memLp
#print axioms rv_omega_variance
#print axioms rv_sq_dev
#print axioms rv_mean
#print axioms rv_var
