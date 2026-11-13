-- Dominated convergence: if measurable functions converge almost everywhere under one integrable roof, their total error goes to zero and their integrals converge to the integral of the limit, with bounded convergence and Scheffé's lemma as corollaries.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Integral.DominatedConvergence

open MeasureTheory Filter Topology Finset

/-- Dominated convergence (Lebesgue): on any measure space, let `f n` and `f` be measurable
real functions and `g` a non-negative measurable function with finite integral. If
`f n → f` almost everywhere and `|f n| ≤ g` almost everywhere for every `n`, then the total
error `∫ |f n - f|` goes to 0 and `∫ f n → ∫ f`: the limit may be taken inside the integral. -/
theorem dominated_convergence_total_error_and_integral_tendsto
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) {f : ℕ → Ω → ℝ} {F g : Ω → ℝ}
    (hf_meas : ∀ n, Measurable (f n)) (hF_meas : Measurable F)
    (hg_meas : Measurable g) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hlim : ∀ᵐ x ∂μ, Tendsto (fun n => f n x) atTop (𝓝 (F x)))
    (hbound : ∀ n, ∀ᵐ x ∂μ, |f n x| ≤ g x)
    (hg_fin : ∫⁻ x, ENNReal.ofReal (g x) ∂μ < ⊤) :
    Tendsto (fun n => ∫ x, |f n x - F x| ∂μ) atTop (𝓝 0) ∧
    Tendsto (fun n => ∫ x, f n x ∂μ) atTop (𝓝 (∫ x, F x ∂μ)) := by
  have hg_int : Integrable g μ :=
    ⟨hg_meas.aestronglyMeasurable,
      (hasFiniteIntegral_iff_ofReal (Eventually.of_forall hg_nonneg)).2 hg_fin⟩
  have hFb : ∀ᵐ x ∂μ, |F x| ≤ g x := by
    rw [← ae_all_iff] at hbound
    filter_upwards [hlim, hbound] with x hx hb
    exact le_of_tendsto' ((continuous_abs.tendsto _).comp hx) hb
  refine ⟨?_, ?_⟩
  · have h := tendsto_integral_of_dominated_convergence (μ := μ)
      (F := fun n x => |f n x - F x|) (f := fun _ => (0 : ℝ)) (fun x => 2 * g x)
      (fun n => (continuous_abs.measurable.comp ((hf_meas n).sub hF_meas)).aestronglyMeasurable) (hg_int.const_mul 2)
      (fun n => by
        filter_upwards [hbound n, hFb] with x h1 h2
        rw [Real.norm_eq_abs, abs_abs]
        linarith [abs_sub (f n x) (F x)])
      (by
        filter_upwards [hlim] with x hx
        simpa using (hx.sub_const (F x)).abs)
    simpa using h
  · exact tendsto_integral_of_dominated_convergence g (fun n => (hf_meas n).aestronglyMeasurable)
      hg_int (fun n => by simpa [Real.norm_eq_abs] using hbound n) hlim

/-- Bounded convergence: on a space of finite measure, if measurable `f n → f` almost
everywhere and `|f n| ≤ M` almost everywhere for one number `M` and every `n`, then the total
error `∫ |f n - f|` goes to 0 and `∫ f n → ∫ f`. -/
theorem bounded_convergence_total_error_and_integral_tendsto
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsFiniteMeasure μ]
    {f : ℕ → Ω → ℝ} {F : Ω → ℝ} (M : ℝ)
    (hf_meas : ∀ n, Measurable (f n)) (hF_meas : Measurable F)
    (hlim : ∀ᵐ x ∂μ, Tendsto (fun n => f n x) atTop (𝓝 (F x)))
    (hbound : ∀ n, ∀ᵐ x ∂μ, |f n x| ≤ M) :
    Tendsto (fun n => ∫ x, |f n x - F x| ∂μ) atTop (𝓝 0) ∧
    Tendsto (fun n => ∫ x, f n x ∂μ) atTop (𝓝 (∫ x, F x ∂μ)) := by
  have hFb : ∀ᵐ x ∂μ, |F x| ≤ M := by
    rw [← ae_all_iff] at hbound
    filter_upwards [hlim, hbound] with x hx hb
    exact le_of_tendsto' ((continuous_abs.tendsto _).comp hx) hb
  refine ⟨?_, ?_⟩
  · have h := tendsto_integral_of_dominated_convergence (μ := μ)
      (F := fun n x => |f n x - F x|) (f := fun _ => (0 : ℝ)) (fun _ => 2 * M)
      (fun n => (continuous_abs.measurable.comp ((hf_meas n).sub hF_meas)).aestronglyMeasurable) (integrable_const _)
      (fun n => by
        filter_upwards [hbound n, hFb] with x h1 h2
        rw [Real.norm_eq_abs, abs_abs]
        linarith [abs_sub (f n x) (F x)])
      (by
        filter_upwards [hlim] with x hx
        simpa using (hx.sub_const (F x)).abs)
    simpa using h
  · exact tendsto_integral_of_dominated_convergence (fun _ => M)
      (fun n => (hf_meas n).aestronglyMeasurable)
      (integrable_const _) (fun n => by simpa [Real.norm_eq_abs] using hbound n) hlim

/-- Scheffé's lemma: if `f n ≥ 0` and `f ≥ 0`, `f n → f` almost everywhere, and every `f n`
has the same finite total as `f`, then the total error `∫ |f n - f|` goes to 0, and for every
measurable set `A` the error on `A` is at most half the total error:
`|∫_A f n - ∫_A f| ≤ ½ ∫ |f n - f|`. -/
theorem scheffe_total_error_tendsto_zero_and_half_bound
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) {f : ℕ → Ω → ℝ} {F : Ω → ℝ}
    (hf_int : ∀ n, Integrable (f n) μ) (hF_int : Integrable F μ)
    (hf_nonneg : ∀ n x, 0 ≤ f n x) (hF_nonneg : ∀ x, 0 ≤ F x)
    (hlim : ∀ᵐ x ∂μ, Tendsto (fun n => f n x) atTop (𝓝 (F x)))
    (htot : ∀ n, ∫ x, f n x ∂μ = ∫ x, F x ∂μ) :
    Tendsto (fun n => ∫ x, |f n x - F x| ∂μ) atTop (𝓝 0) ∧
    ∀ n, ∀ A : Set Ω, MeasurableSet A →
      |∫ x in A, f n x ∂μ - ∫ x in A, F x ∂μ| ≤ (1 / 2) * ∫ x, |f n x - F x| ∂μ := by
  -- positive parts of `F - f n` and `f n - F`
  have hp_int : ∀ n, Integrable (fun x => max (F x - f n x) 0) μ :=
    fun n => (hF_int.sub (hf_int n)).pos_part
  have hq_int : ∀ n, Integrable (fun x => max (f n x - F x) 0) μ :=
    fun n => ((hf_int n).sub hF_int).pos_part
  have habs_int : ∀ n, Integrable (fun x => |f n x - F x|) μ :=
    fun n => ((hf_int n).sub hF_int).abs
  have hd_int : ∀ n, Integrable (fun x => f n x - F x) μ := fun n => (hf_int n).sub hF_int
  have hdiff : ∀ n, ∫ x, (f n x - F x) ∂μ = 0 := fun n => by
    rw [integral_sub (hf_int n) hF_int, htot n, sub_self]
  -- `∫ |f n - F| = 2 ∫ (F - f n)⁺`
  have hp_eq : ∀ n, ∫ x, |f n x - F x| ∂μ = 2 * ∫ x, max (F x - f n x) 0 ∂μ := fun n => by
    have hpt : (fun x => |f n x - F x|)
        = fun x => 2 * max (F x - f n x) 0 + (f n x - F x) := by
      funext x
      rcases le_total (f n x) (F x) with h | h
      · rw [abs_of_nonpos (by linarith), max_eq_left (by linarith)]; ring
      · rw [abs_of_nonneg (by linarith), max_eq_right (by linarith)]; ring
    rw [hpt, integral_add ((hp_int n).const_mul 2) (hd_int n), hdiff n,
      integral_const_mul, add_zero]
  -- `∫ |f n - F| = 2 ∫ (f n - F)⁺`
  have hq_eq : ∀ n, ∫ x, |f n x - F x| ∂μ = 2 * ∫ x, max (f n x - F x) 0 ∂μ := fun n => by
    have hpt : (fun x => |f n x - F x|)
        = fun x => 2 * max (f n x - F x) 0 - (f n x - F x) := by
      funext x
      rcases le_total (f n x) (F x) with h | h
      · rw [abs_of_nonpos (by linarith), max_eq_right (by linarith)]; ring
      · rw [abs_of_nonneg (by linarith), max_eq_left (by linarith)]; ring
    rw [hpt, integral_sub ((hq_int n).const_mul 2) (hd_int n), hdiff n,
      integral_const_mul, sub_zero]
  refine ⟨?_, ?_⟩
  · have h := tendsto_integral_of_dominated_convergence (μ := μ)
      (F := fun n x => max (F x - f n x) 0) (f := fun _ => (0 : ℝ)) F
      (fun n => (hp_int n).aestronglyMeasurable) hF_int
      (fun n => Eventually.of_forall fun x => by
        rw [Real.norm_eq_abs, abs_of_nonneg (le_max_right _ _)]
        exact max_le (by linarith [hf_nonneg n x]) (hF_nonneg x))
      (by
        filter_upwards [hlim] with x hx
        have := (((tendsto_const_nhds (x := F x)).sub hx).max (tendsto_const_nhds (x := (0 : ℝ))))
        simpa using this)
    simp only [integral_zero] at h
    have := h.const_mul 2
    rw [mul_zero] at this
    simpa [hp_eq] using this
  · intro n A hA
    rw [← integral_sub (hf_int n).integrableOn hF_int.integrableOn, abs_le]
    constructor
    · have h1 : ∫ x in A, (F x - f n x) ∂μ ≤ ∫ x in A, max (F x - f n x) 0 ∂μ :=
        setIntegral_mono (hF_int.sub (hf_int n)).integrableOn (hp_int n).integrableOn
          (fun x => le_max_left _ _)
      have h2 : ∫ x in A, max (F x - f n x) 0 ∂μ ≤ ∫ x, max (F x - f n x) 0 ∂μ :=
        setIntegral_le_integral (hp_int n) (Eventually.of_forall fun x => le_max_right _ _)
      have h3 : ∫ x in A, (F x - f n x) ∂μ = - ∫ x in A, (f n x - F x) ∂μ := by
        rw [← integral_neg]; congr 1; funext x; ring
      rw [hp_eq n]
      linarith
    · have h1 : ∫ x in A, (f n x - F x) ∂μ ≤ ∫ x in A, max (f n x - F x) 0 ∂μ :=
        setIntegral_mono ((hf_int n).sub hF_int).integrableOn (hq_int n).integrableOn
          (fun x => le_max_left _ _)
      have h2 : ∫ x in A, max (f n x - F x) 0 ∂μ ≤ ∫ x, max (f n x - F x) 0 ∂μ :=
        setIntegral_le_integral (hq_int n) (Eventually.of_forall fun x => le_max_right _ _)
      rw [hq_eq n]
      linarith

/-! The card's hand computation with 10 slots, chance `2/10 = 1/5` each, done in exact
fractions: `p₁₀(k) = C(10,k) (1/5)^k (4/5)^(10-k)`. -/

-- first factor 10 × 9 / 100 = 9/10; roof 2^2/2! = 2; p₁₀(2) = 9/10 × 2 × (4/5)^8
example : (10 * 9 / 100 : ℚ) = 9 / 10 ∧ (2 ^ 2 / Nat.factorial 2 : ℚ) = 2 ∧
    (Nat.choose 10 2 : ℚ) * (1 / 5) ^ 2 * (4 / 5) ^ 8 = 9 / 10 * 2 * (4 / 5) ^ 8 := by
  norm_num [Nat.choose, Nat.factorial]

-- under the roof: p₁₀(2) ≤ 2^2/2! = 2
example : (Nat.choose 10 2 : ℚ) * (1 / 5) ^ 2 * (4 / 5) ^ 8 ≤ 2 ^ 2 / Nat.factorial 2 := by
  norm_num [Nat.choose, Nat.factorial]

-- the roof holds at every count for 10 slots: p₁₀(k) ≤ 2^k/k! for k = 0, …, 10
example : ∀ k ∈ range 11,
    (Nat.choose 10 k : ℚ) * (1 / 5) ^ k * (4 / 5) ^ (10 - k) ≤ 2 ^ k / Nat.factorial k := by
  intro k hk
  rw [mem_range] at hk
  interval_cases k <;> norm_num [Nat.choose, Nat.factorial]

-- the 10-slot chances total 1, their mean is 2, and their average square is 6 - 4/10 = 28/5
example : ∑ k ∈ range 11, (Nat.choose 10 k : ℚ) * (1 / 5) ^ k * (4 / 5) ^ (10 - k) = 1 ∧
    ∑ k ∈ range 11, (k : ℚ) * (Nat.choose 10 k) * (1 / 5) ^ k * (4 / 5) ^ (10 - k) = 2 ∧
    ∑ k ∈ range 11, (k : ℚ) ^ 2 * (Nat.choose 10 k) * (1 / 5) ^ k * (4 / 5) ^ (10 - k) = 28 / 5 := by
  norm_num [sum_range_succ, Nat.choose]

-- variance at 10 slots: 28/5 - 2^2 = 2 (1 - 2/10) = 8/5; Poisson average square 2 + 2^2 = 6
example : (28 / 5 : ℚ) - 2 ^ 2 = 2 * (1 - 2 / 10) ∧ (28 / 5 : ℚ) - 2 ^ 2 = 8 / 5 ∧
    (2 : ℚ) + 2 ^ 2 = 6 := by
  norm_num

#print axioms dominated_convergence_total_error_and_integral_tendsto
#print axioms bounded_convergence_total_error_and_integral_tendsto
#print axioms scheffe_total_error_tendsto_zero_and_half_bound
