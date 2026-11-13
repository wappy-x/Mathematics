-- Monte Carlo pricing: when the invented futures come from independent standard bell-curve draws in the pricing world, the average of the discounted call payments has the true price as its average value and a spread equal to one payment's finite spread over the square root of the number of futures, the n - 1 sample spread measures that payment spread without lean, and the average discounted ending price is the market's S e^(-qT).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance

open Real MeasureTheory ProbabilityTheory Finset

/-- The invented ending price in one future (The formula): today's price `S`, grown at the
pricing world's rate `r - q - σ²/2` for `T` years, then shoved sideways by one bell-curve draw
`z`: `S_T = S exp((r - q - σ²/2) T + σ √T z)`. -/
noncomputable def endingPrice (S r q σ T z : ℝ) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z)

/-- One future's payment, shrunk to today (The formula): `X = e^(-rT) max(S_T - K, 0)`. -/
noncomputable def discountedPayoff (S K r q σ T z : ℝ) : ℝ :=
  exp (-r * T) * max (endingPrice S r q σ T z - K) 0

/-- The call's price (Step 0): the discounted payoff averaged over every possible ending in the
pricing world, that is, over the standard bell curve. -/
noncomputable def callPrice (S K r q σ T : ℝ) : ℝ :=
  ∫ z, discountedPayoff S K r q σ T z ∂(gaussianReal 0 1)

/-- The Monte Carlo estimate after `n` futures: `Ĉ_n = (1/n) Σ_{i<n} e^(-rT) max(S_T⁽ⁱ⁾ - K, 0)`,
the `i`-th future driven by the draw `Z i`. -/
noncomputable def mcEstimate (S K r q σ T : ℝ) {Ω : Type*} (Z : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) : ℝ :=
  (∑ i ∈ range n, discountedPayoff S K r q σ T (Z i ω)) / n

/-- The payments' sample spread, squared (Two helper formulas):
`s_n² = (1/(n-1)) Σ_{i<n} (X_i - Ĉ_n)²`. -/
noncomputable def sampleSpreadSq (S K r q σ T : ℝ) {Ω : Type*} (Z : ℕ → Ω → ℝ) (n : ℕ)
    (ω : Ω) : ℝ :=
  (∑ i ∈ range n,
      (discountedPayoff S K r q σ T (Z i ω) - mcEstimate S K r q σ T Z n ω) ^ 2) / (n - 1)

lemma dp_continuous (S K r q σ T : ℝ) : Continuous (discountedPayoff S K r q σ T) := by
  unfold discountedPayoff endingPrice
  fun_prop

lemma dp_memLp_gauss (S K r q σ T : ℝ) :
    MemLp (discountedPayoff S K r q σ T) 2 (gaussianReal 0 1) := by
  have hc := dp_continuous S K r q σ T
  rw [memLp_two_iff_integrable_sq hc.aestronglyMeasurable]
  have hg : Integrable (fun z ↦ 2 * exp (-r * T) ^ 2 * (S ^ 2 * exp (2 * ((r - q - σ ^ 2 / 2) * T))
      * exp ((2 * (σ * √T)) * z) + K ^ 2)) (gaussianReal 0 1) :=
    (((integrable_exp_mul_gaussianReal (2 * (σ * √T))).const_mul _).add
      (integrable_const _)).const_mul _
  refine hg.mono' (hc.pow 2).aestronglyMeasurable (Filter.Eventually.of_forall fun z ↦ ?_)
  have hP : endingPrice S r q σ T z ^ 2 =
      S ^ 2 * exp (2 * ((r - q - σ ^ 2 / 2) * T)) * exp ((2 * (σ * √T)) * z) := by
    simp only [endingPrice, mul_pow, sq (rexp _)]
    rw [← exp_add, mul_assoc (S ^ 2), ← exp_add]
    congr 2; ring
  set x := endingPrice S r q σ T z
  have hm : max (x - K) 0 ^ 2 ≤ (x - K) ^ 2 := by
    rcases le_total (x - K) 0 with h | h
    · rw [max_eq_right h]; simpa using sq_nonneg (x - K)
    · rw [max_eq_left h]
  have hxk : (x - K) ^ 2 ≤ 2 * (x ^ 2 + K ^ 2) := by nlinarith [sq_nonneg (x + K)]
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
  simp only [discountedPayoff]
  rw [mul_pow, ← hP]
  have he : 0 ≤ exp (-r * T) ^ 2 := by positivity
  nlinarith [mul_le_mul_of_nonneg_left (hm.trans hxk) he]

lemma dp_memLp {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} (S K r q σ T : ℝ) {Y : Ω → ℝ}
    (hY : HasLaw Y (gaussianReal 0 1) P) :
    MemLp (fun ω ↦ discountedPayoff S K r q σ T (Y ω)) 2 P :=
  hY.memLp_comp (dp_memLp_gauss S K r q σ T)

lemma dp_integral {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} (S K r q σ T : ℝ) {Y : Ω → ℝ}
    (hY : HasLaw Y (gaussianReal 0 1) P) :
    ∫ ω, discountedPayoff S K r q σ T (Y ω) ∂P = callPrice S K r q σ T :=
  hY.integral_comp (dp_continuous S K r q σ T).aestronglyMeasurable

lemma dp_variance {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} (S K r q σ T : ℝ) {Y : Ω → ℝ}
    (hY : HasLaw Y (gaussianReal 0 1) P) :
    variance (fun ω ↦ discountedPayoff S K r q σ T (Y ω)) P =
      variance (discountedPayoff S K r q σ T) (gaussianReal 0 1) := by
  rw [← hY.map_eq, variance_map (hY.map_eq ▸ (dp_continuous S K r q σ T).aemeasurable)
    hY.aemeasurable]
  rfl

lemma mc_integral {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (S K r q σ T : ℝ) (Z : ℕ → Ω → ℝ) (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P)
    (n : ℕ) (hn : 0 < n) :
    ∫ ω, mcEstimate S K r q σ T Z n ω ∂P = callPrice S K r q σ T := by
  unfold mcEstimate
  rw [integral_div, integral_finsetSum _ (fun i _ ↦ (dp_memLp S K r q σ T (hlaw i)).integrable
    one_le_two)]
  simp_rw [dp_integral S K r q σ T (hlaw _)]
  rw [sum_const, card_range, nsmul_eq_mul]
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  field_simp

lemma mc_memLp {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (S K r q σ T : ℝ) (Z : ℕ → Ω → ℝ) (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P)
    (n : ℕ) : MemLp (mcEstimate S K r q σ T Z n) 2 P := by
  have := (memLp_finsetSum (range n) (fun i _ ↦ dp_memLp S K r q σ T (hlaw i))).mul_const
    ((n : ℝ)⁻¹)
  convert this using 1
  funext ω
  simp [mcEstimate, div_eq_mul_inv]

lemma mc_variance {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (S K r q σ T : ℝ) (Z : ℕ → Ω → ℝ)
    (hind : iIndepFun Z P) (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P) (n : ℕ) :
    variance (mcEstimate S K r q σ T Z n) P =
      variance (fun ω ↦ discountedPayoff S K r q σ T (Z 0 ω)) P / n := by
  set f := discountedPayoff S K r q σ T with hf
  have hind' : iIndepFun (fun i ↦ f ∘ Z i) P :=
    hind.comp (fun _ ↦ f) (fun _ ↦ (dp_continuous S K r q σ T).measurable)
  have hfun : mcEstimate S K r q σ T Z n = fun ω ↦ (∑ i ∈ range n, f ∘ Z i) ω * (n : ℝ)⁻¹ := by
    funext ω; simp [mcEstimate, Finset.sum_apply, div_eq_mul_inv, hf]
  rw [hfun, variance_mul_const, IndepFun.variance_sum (X := fun i ↦ f ∘ Z i)
    (fun i _ ↦ dp_memLp S K r q σ T (hlaw i))
    (fun i _ j _ hij ↦ hind'.indepFun hij)]
  have hv : ∀ i, variance (f ∘ Z i) P = variance (fun ω ↦ f (Z 0 ω)) P := fun i ↦
    (dp_variance S K r q σ T (hlaw i)).trans (dp_variance S K r q σ T (hlaw 0)).symm
  simp_rw [hv, sum_const, card_range, nsmul_eq_mul]
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  field_simp

lemma sum_sq_dev_identity (x : ℕ → ℝ) (n : ℕ) (hn : 0 < n) (m : ℝ) :
    ∑ i ∈ range n, (x i - (∑ j ∈ range n, x j) / n) ^ 2 =
      ∑ i ∈ range n, (x i - m) ^ 2 - n * ((∑ j ∈ range n, x j) / n - m) ^ 2 := by
  set A := (∑ j ∈ range n, x j) / n with hA
  have hsum : ∑ j ∈ range n, x j = n * A := by
    have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
    rw [hA]; field_simp
  have h1 : ∀ i, (x i - A) ^ 2 = (x i - m) ^ 2 - 2 * (A - m) * (x i - m) + (A - m) ^ 2 := by
    intro i; ring
  simp_rw [h1]
  rw [sum_add_distrib, sum_sub_distrib, ← mul_sum, sum_sub_distrib, hsum, sum_const, sum_const,
    card_range, nsmul_eq_mul, nsmul_eq_mul]
  ring

lemma ending_mean {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (S r q σ T : ℝ) (hT : 0 ≤ T) (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P) :
    ∫ ω, endingPrice S r q σ T (Z ω) ∂P = S * exp ((r - q) * T) := by
  have hm := mgf_gaussianReal hZ (σ * √T)
  simp only [mgf] at hm
  have : ∀ ω, endingPrice S r q σ T (Z ω) =
      (S * exp ((r - q - σ ^ 2 / 2) * T)) * exp (σ * √T * Z ω) := by
    intro ω; simp only [endingPrice, exp_add]; ring
  simp_rw [this]
  rw [integral_const_mul, hm, mul_assoc, ← exp_add, mul_pow, Real.sq_sqrt hT]
  congr 2
  push_cast
  ring

lemma disc_ending_mean {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (S r q σ T : ℝ) (hT : 0 ≤ T) (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P) :
    ∫ ω, exp (-r * T) * endingPrice S r q σ T (Z ω) ∂P = S * exp (-q * T) := by
  rw [integral_const_mul, ending_mean S r q σ T hT Z hZ, mul_left_comm, ← exp_add]
  congr 2; ring

#print axioms dp_continuous
#print axioms dp_memLp_gauss
#print axioms dp_memLp
#print axioms dp_integral
#print axioms dp_variance
#print axioms mc_integral
#print axioms mc_memLp
#print axioms mc_variance
#print axioms sum_sq_dev_identity
#print axioms ending_mean
#print axioms disc_ending_mean

/-- **Monte Carlo pricing: no lean, and the square-root law** (Step 3 and its detailed proof).
Draw the futures in the pricing world from independent standard bell-curve draws `Z 0, Z 1, …`.
Then one payment `X = e^(-rT) max(S_T - K, 0)` has a finite spread (the model guarantees one);
for every count `n ≥ 1` of futures, the estimate `Ĉ_n`, the average of the `n` discounted
payments, has the true price as its average value, so it leans neither high nor low; and its
spread is one payment's spread divided by the square root of `n`. -/
theorem monte_carlo_estimate_unbiased_with_root_n_error
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (S K r q σ T : ℝ) (Z : ℕ → Ω → ℝ)
    (hind : iIndepFun Z P) (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P)
    (n : ℕ) (hn : 0 < n) :
    MemLp (fun ω ↦ discountedPayoff S K r q σ T (Z 0 ω)) 2 P ∧
      ∫ ω, mcEstimate S K r q σ T Z n ω ∂P = callPrice S K r q σ T ∧
      √(variance (mcEstimate S K r q σ T Z n) P) =
        √(variance (fun ω ↦ discountedPayoff S K r q σ T (Z 0 ω)) P) / √n := by
  refine ⟨dp_memLp S K r q σ T (hlaw 0), mc_integral S K r q σ T Z hlaw n hn, ?_⟩
  rw [mc_variance S K r q σ T Z hind hlaw n, Real.sqrt_div' _ (Nat.cast_nonneg n)]

/-- **The same sample measures its own error** (Detailed proof, "Measuring that spread from
the same sample"). With the same independent bell-curve draws and at least two futures, the
sample spread `s_n²`, which divides by `n - 1` because the payments are measured against their
own average, has one payment's true squared spread as its average value. -/
theorem sample_spread_unbiased
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (S K r q σ T : ℝ) (Z : ℕ → Ω → ℝ)
    (hind : iIndepFun Z P) (hlaw : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P)
    (n : ℕ) (hn : 2 ≤ n) :
    ∫ ω, sampleSpreadSq S K r q σ T Z n ω ∂P =
      variance (fun ω ↦ discountedPayoff S K r q σ T (Z 0 ω)) P := by
  have hn0 : 0 < n := by omega
  set f := discountedPayoff S K r q σ T with hf
  set m := callPrice S K r q σ T with hm
  set V := variance (fun ω ↦ f (Z 0 ω)) P with hV
  have hX : ∀ i, MemLp (fun ω ↦ f (Z i ω)) 2 P := fun i ↦ dp_memLp S K r q σ T (hlaw i)
  have hXbar := mc_memLp S K r q σ T Z hlaw n
  have hpt : ∀ ω, sampleSpreadSq S K r q σ T Z n ω =
      (∑ i ∈ range n, (f (Z i ω) - m) ^ 2 - n * (mcEstimate S K r q σ T Z n ω - m) ^ 2)
        / (n - 1) := by
    intro ω
    simp only [sampleSpreadSq, mcEstimate]
    rw [sum_sq_dev_identity (fun i ↦ f (Z i ω)) n hn0 m]
  simp_rw [hpt]
  have hint1 : ∀ i, Integrable (fun ω ↦ (f (Z i ω) - m) ^ 2) P := fun i ↦
    ((hX i).sub (memLp_const m)).integrable_sq
  have hint2 : Integrable (fun ω ↦ (mcEstimate S K r q σ T Z n ω - m) ^ 2) P :=
    (hXbar.sub (memLp_const m)).integrable_sq
  rw [integral_div, integral_sub (integrable_finsetSum _ (fun i _ ↦ hint1 i))
    (hint2.const_mul _), integral_finsetSum _ (fun i _ ↦ hint1 i), integral_const_mul]
  have hvi : ∀ i, ∫ ω, (f (Z i ω) - m) ^ 2 ∂P = V := by
    intro i
    rw [hV, dp_variance S K r q σ T (hlaw 0), ← dp_variance S K r q σ T (hlaw i),
      variance_eq_integral (hX i).aemeasurable, dp_integral S K r q σ T (hlaw i)]
  have hvbar : ∫ ω, (mcEstimate S K r q σ T Z n ω - m) ^ 2 ∂P = V / n := by
    rw [hV, ← mc_variance S K r q σ T Z hind hlaw n, variance_eq_integral hXbar.aemeasurable,
      mc_integral S K r q σ T Z hlaw n hn0]
  simp_rw [hvi, hvbar, sum_const, card_range, nsmul_eq_mul]
  have h1 : (n : ℝ) ≠ 0 := by exact_mod_cast hn0.ne'
  have h2 : (n : ℝ) - 1 ≠ 0 := by
    have : (2 : ℝ) ≤ n := by exact_mod_cast hn
    linarith
  field_simp

/-- **The sampler drifts as the pretend world does** (Step 0, the sampler check, and the forward
in "What breaks"). With one standard bell-curve draw `Z` and a horizon `T ≥ 0`, the pricing world's average ending
price is the forward `S e^((r - q)T)`, and the average discounted ending price is the market's
`S e^(-qT)`: every asset earns the riskless rate `r` in total, dividends included. -/
theorem average_ending_price_is_forward
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (S r q σ T : ℝ) (hT : 0 ≤ T) (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P) :
    ∫ ω, endingPrice S r q σ T (Z ω) ∂P = S * exp ((r - q) * T) ∧
      ∫ ω, exp (-r * T) * endingPrice S r q σ T (Z ω) ∂P = S * exp (-q * T) := by
  exact ⟨ending_mean S r q σ T hT Z hZ, disc_ending_mean S r q σ T hT Z hZ⟩

-- The pricing world's growth for Acme: (0.05 - 0.02 - ½ × 0.20²) × 1 = 0.01.
example : ((5 : ℚ) / 100 - 2 / 100 - 1 / 2 * (20 / 100) ^ 2) * 1 = 1 / 100 := by norm_num
-- One wiggle unit: 0.20 × √1 = 0.20.
example : (20 / 100 : ℝ) * √1 = 1 / 5 := by norm_num
-- Acme's ending price is 100 e^(0.01 + 0.2 z) for a draw z.
example (z : ℝ) : endingPrice 100 (5 / 100) (2 / 100) (1 / 5) 1 z = 100 * exp (1 / 100 + 1 / 5 * z) := by
  simp only [endingPrice, Real.sqrt_one]; norm_num
-- The square-root law: a hundredfold in paths (1,000 to 100,000) shrinks the error tenfold,
-- and four times the paths (25,000 to 100,000) halves it.
example : √((100000 : ℝ) / 1000) = 10 ∧ √((100000 : ℝ) / 25000) = 2 := by
  constructor
  · rw [show (100000 : ℝ) / 1000 = 10 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  · rw [show (100000 : ℝ) / 25000 = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
-- The chart's path marks: the first gap is 4,000 paths, the last is 25,000; the second bar to
-- the fourth cost ninety thousand extra futures.
example : 5000 - 1000 = 4000 ∧ 100000 - 75000 = 25000 ∧ 100000 - 10000 = 90000 := by norm_num

#print axioms monte_carlo_estimate_unbiased_with_root_n_error
#print axioms sample_spread_unbiased
#print axioms average_ending_price_is_forward
