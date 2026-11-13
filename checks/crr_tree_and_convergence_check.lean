-- Cox-Ross-Rubinstein: with branches u = e^(σ√Δt), d = 1/u and up weight p = (e^((r-q)Δt) - d)/(u - d), the n-step tree's call price tends to the Black-Scholes price as n grows, the weight lies strictly between 0 and 1 exactly when |r - q|√Δt < σ, and every tree's average end price is the forward S e^((r-q)T).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Measure.LevyConvergence

open Real MeasureTheory ProbabilityTheory Filter Topology

/-! The model. Today's share price `S`, strike `K`, riskless rate `r` and dividend yield `q`
(both continuously compounded), volatility `σ`, life `T` years, `n` steps of length `Δt = T / n`.
The tree prices a call that pays `max (S_T - K) 0` on the last day only. -/

/-- The up factor on a step of length `Δt`: `u = e^(σ√Δt)`. -/
noncomputable def crrUp (σ Δt : ℝ) : ℝ := exp (σ * √Δt)

/-- The down factor on a step of length `Δt`: `d = 1 / u = e^(-σ√Δt)`. -/
noncomputable def crrDown (σ Δt : ℝ) : ℝ := exp (-(σ * √Δt))

/-- The weight on the up branch: `p = (e^((r-q)Δt) - d) / (u - d)`. -/
noncomputable def crrWeight (r q σ Δt : ℝ) : ℝ :=
  (exp ((r - q) * Δt) - crrDown σ Δt) / (crrUp σ Δt - crrDown σ Δt)

/-- The `n`-step tree's call price, as one weighted sum over the `n + 1` end prices
`S u^k d^(n-k)`: each end weighted by the number of paths reaching it, `n choose k`, times the
weight `p^k (1-p)^(n-k)` each such path carries, and the whole carried back to today by `n`
one-step discounts `e^(-rΔt)`, that is by `e^(-rT)`. -/
noncomputable def crrCallPrice (S K r q σ T : ℝ) (n : ℕ) : ℝ :=
  exp (-(r * T)) * ∑ k ∈ Finset.range (n + 1),
    (n.choose k : ℝ) * crrWeight r q σ (T / n) ^ k * (1 - crrWeight r q σ (T / n)) ^ (n - k) *
      max (S * crrUp σ (T / n) ^ k * crrDown σ (T / n) ^ (n - k) - K) 0

/-- The Black-Scholes call price: the call's payoff averaged over the continuous model's end price
`S e^((r - q - σ²/2) T + σ√T Z)`, with `Z` a standard bell-curve draw, and carried back to today
by `e^(-rT)`. (The Black-Scholes call card shows this average equals
`S e^(-qT) N(d₁) - K e^(-rT) N(d₂)`.) -/
noncomputable def blackScholesCall (S K r q σ T : ℝ) : ℝ :=
  exp (-(r * T)) *
    ∫ z, max (S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z) - K) 0 ∂(gaussianReal 0 1)

/-! Helper lemmas for the proofs below. -/
lemma crr_slope {f : ℝ → ℝ} {c : ℝ} (hf : HasDerivAt f c 0) (h0 : f 0 = 0) :
    Tendsto (fun h => f h / h) (𝓝[≠] 0) (𝓝 c) := by
  have := hasDerivAt_iff_tendsto_slope_zero.1 hf
  simp only [zero_add, h0, sub_zero, smul_eq_mul] at this
  simpa [div_eq_inv_mul] using this

#print axioms crr_slope

lemma crr_lim_sin (c : ℝ) : Tendsto (fun h => sin (c * h) / h) (𝓝[≠] 0) (𝓝 c) := by
  apply crr_slope _ (by simp)
  have := ((hasDerivAt_id (0:ℝ)).const_mul c).sin
  simpa using this

#print axioms crr_lim_sin

lemma crr_lim_sinh (c : ℝ) :
    Tendsto (fun h => (exp (c * h) - exp (-(c * h))) / h) (𝓝[≠] 0) (𝓝 (2 * c)) := by
  apply crr_slope _ (by simp)
  have := ((hasDerivAt_id (0:ℝ)).const_mul c).exp.sub ((hasDerivAt_id (0:ℝ)).const_mul c).neg.exp
  convert this using 1
  · ext x; simp
  · simp; ring

#print axioms crr_lim_sinh

lemma crr_lim_expsq (α : ℝ) :
    Tendsto (fun h => (exp (α * h ^ 2) - 1) / h ^ 2) (𝓝[≠] 0) (𝓝 α) := by
  have h1 : Tendsto (fun y => (exp (α * y) - 1) / y) (𝓝[≠] 0) (𝓝 α) := by
    apply crr_slope _ (by simp)
    simpa using ((hasDerivAt_id (0:ℝ)).const_mul α).exp.sub_const 1
  have h2 : Tendsto (fun h : ℝ => h ^ 2) (𝓝[≠] 0) (𝓝[≠] 0) := by
    refine tendsto_nhdsWithin_iff.2 ⟨?_, eventually_nhdsWithin_of_forall fun h hh => pow_ne_zero 2 hh⟩
    have : Tendsto (fun h : ℝ => h ^ 2) (𝓝 0) (𝓝 0) := by
      simpa using ((continuous_pow 2).tendsto (0:ℝ))
    exact this.mono_left nhdsWithin_le_nhds
  exact h1.comp h2

#print axioms crr_lim_expsq

lemma crr_lim_cos (t : ℝ) :
    Tendsto (fun h => (cos (t * h) - 1) / h ^ 2) (𝓝[≠] 0) (𝓝 (-(t ^ 2 / 2))) := by
  have := ((crr_lim_sin (t / 2)).pow 2).const_mul (-2)
  convert this using 2 with h
  · rw [show t * h = 2 * (t / 2 * h) by ring, cos_two_mul, cos_sq']
    ring
  · ring

#print axioms crr_lim_cos

lemma crr_lim_cosh :
    Tendsto (fun h => (exp h + exp (-h) - 2) / h ^ 2) (𝓝[≠] 0) (𝓝 1) := by
  have := (crr_lim_sinh (1 / 2)).pow 2
  convert this using 2 with h
  · have e1 : exp (1 / 2 * h) ^ 2 = exp h := by rw [← exp_nat_mul]; ring_nf
    have e2 : exp (-(1 / 2 * h)) ^ 2 = exp (-h) := by rw [← exp_nat_mul]; ring_nf
    have e3 : exp (1 / 2 * h) * exp (-(1 / 2 * h)) = 1 := by rw [← exp_add]; simp
    rw [div_pow]
    congr 1
    linear_combination -e1 - e2 + 2 * e3
  · norm_num

#print axioms crr_lim_cosh

lemma crr_lim_weight (α : ℝ) :
    Tendsto (fun h => (2 * ((exp (α * h ^ 2) - exp (-h)) / (exp h - exp (-h))) - 1) / h)
      (𝓝[≠] 0) (𝓝 ((2 * α - 1) / 2)) := by
  have hs := crr_lim_sinh 1
  simp only [one_mul] at hs
  have := (((crr_lim_expsq α).const_mul 2).sub crr_lim_cosh).div hs (by norm_num)
  rw [show (2 * α - 1) / 2 = (2 * α - 1) / (2 * 1) by ring]
  refine this.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with h hh
  have hh' : h ≠ 0 := hh
  have hD : exp h - exp (-h) ≠ 0 := by
    intro H
    have := exp_injective (sub_eq_zero.1 H)
    exact hh' (by linarith)
  simp only [Pi.div_apply]
  field_simp
  ring

#print axioms crr_lim_weight

/-- The tree's law of the log price move `log (S_T / S)`: mass `C(n,k) p^k (1-p)^(n-k)` at
`h k - h (n - k)`. -/
noncomputable def crrLogMeasure (n : ℕ) (p h : ℝ) : Measure ℝ :=
  ∑ k ∈ Finset.range (n + 1), ENNReal.ofReal ((n.choose k : ℝ) * p ^ k * (1 - p) ^ (n - k)) •
    Measure.dirac (h * k - h * ((n - k : ℕ) : ℝ))

#print axioms crrLogMeasure

lemma crr_weight_nonneg (n k : ℕ) {p : ℝ} (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    0 ≤ (n.choose k : ℝ) * p ^ k * (1 - p) ^ (n - k) :=
  mul_nonneg (mul_nonneg (Nat.cast_nonneg _) (pow_nonneg hp0 _)) (pow_nonneg (by linarith) _)

#print axioms crr_weight_nonneg

lemma crr_weights_sum (n : ℕ) (p : ℝ) :
    ∑ k ∈ Finset.range (n + 1), (n.choose k : ℝ) * p ^ k * (1 - p) ^ (n - k) = 1 := by
  calc _ = (p + (1 - p)) ^ n := by
          rw [add_pow]; exact Finset.sum_congr rfl fun k _ => by ring
    _ = 1 := by ring

#print axioms crr_weights_sum

lemma crrLogMeasure_integral {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [CompleteSpace E] (n : ℕ) {p : ℝ} (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (h : ℝ) (f : ℝ → E) :
    ∫ x, f x ∂(crrLogMeasure n p h) = ∑ k ∈ Finset.range (n + 1),
      ((n.choose k : ℝ) * p ^ k * (1 - p) ^ (n - k)) • f (h * k - h * ((n - k : ℕ) : ℝ)) := by
  unfold crrLogMeasure
  rw [integral_finsetSum_measure]
  · refine Finset.sum_congr rfl fun k _ => ?_
    rw [integral_smul_measure, integral_dirac, ENNReal.toReal_ofReal (crr_weight_nonneg n k hp0 hp1)]
  · intro k _
    exact (integrable_dirac (by simp)).smul_measure ENNReal.ofReal_ne_top

#print axioms crrLogMeasure_integral

lemma crrLogMeasure_isProb (n : ℕ) {p : ℝ} (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (h : ℝ) :
    IsProbabilityMeasure (crrLogMeasure n p h) := by
  constructor
  simp only [crrLogMeasure, Measure.finsetSum_apply, Measure.smul_apply, measure_univ,
    smul_eq_mul, mul_one]
  rw [← ENNReal.ofReal_sum_of_nonneg (fun k _ => crr_weight_nonneg n k hp0 hp1), crr_weights_sum]
  simp

#print axioms crrLogMeasure_isProb

lemma crrLogMeasure_charFun (n : ℕ) {p : ℝ} (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (h t : ℝ) :
    charFun (crrLogMeasure n p h) t =
      ((p : ℂ) * Complex.exp (t * h * Complex.I) + (1 - p) * Complex.exp (-(t * h) * Complex.I)) ^ n := by
  rw [charFun_apply_real, crrLogMeasure_integral n hp0 hp1, add_pow]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [Complex.real_smul]
  have : Complex.exp (t * ((h * k - h * ((n - k : ℕ) : ℝ) : ℝ) : ℂ) * Complex.I) =
      Complex.exp (t * h * Complex.I) ^ k * Complex.exp (-(t * h) * Complex.I) ^ (n - k) := by
    rw [← Complex.exp_nat_mul, ← Complex.exp_nat_mul, ← Complex.exp_add]
    congr 1; push_cast; ring
  rw [this, mul_pow, mul_pow]; push_cast; ring

#print axioms crrLogMeasure_charFun

lemma crr_forward (S r q σ T : ℝ) (n : ℕ)
    (hσ : 0 < σ) (hT : 0 < T) (hn : 1 ≤ n) :
    ∑ k ∈ Finset.range (n + 1),
      (n.choose k : ℝ) * crrWeight r q σ (T / n) ^ k * (1 - crrWeight r q σ (T / n)) ^ (n - k) *
        (S * crrUp σ (T / n) ^ k * crrDown σ (T / n) ^ (n - k)) =
      S * exp ((r - q) * T) := by
  have hn' : (n : ℝ) ≠ 0 := Nat.cast_ne_zero.2 (by omega)
  have hΔ : 0 < T / n := div_pos hT (by positivity)
  have hD : crrUp σ (T / n) - crrDown σ (T / n) ≠ 0 := by
    have : 0 < σ * √(T / n) := mul_pos hσ (Real.sqrt_pos.2 hΔ)
    unfold crrUp crrDown; rw [sub_ne_zero]; exact (exp_lt_exp.2 (by linarith)).ne'
  have hE : crrWeight r q σ (T / n) * crrUp σ (T / n) + (1 - crrWeight r q σ (T / n)) *
      crrDown σ (T / n) = exp ((r - q) * (T / n)) := by
    have key : ∀ E u d : ℝ, u - d ≠ 0 → (E - d) / (u - d) * u + (1 - (E - d) / (u - d)) * d = E := by
      intro E u d h; field_simp; ring
    exact key _ _ _ hD
  generalize crrWeight r q σ (T / n) = p at hE ⊢
  generalize crrUp σ (T / n) = u at hE ⊢
  generalize crrDown σ (T / n) = d at hE ⊢
  calc _ = S * ∑ k ∈ Finset.range (n + 1), (p * u) ^ k * ((1 - p) * d) ^ (n - k) * n.choose k := by
          rw [Finset.mul_sum]; refine Finset.sum_congr rfl fun k _ => by rw [mul_pow, mul_pow]; ring
    _ = S * (p * u + (1 - p) * d) ^ n := by rw [add_pow]
    _ = S * exp ((r - q) * T) := by
          rw [hE, ← Real.exp_nat_mul]; congr 2; field_simp

#print axioms crr_forward

/-- **The tree price converges to the Black-Scholes price.** Size the branches from one fixed
volatility `σ > 0` alone, `u = e^(σ√Δt)` and `d = 1/u` with `Δt = T/n`, let the up weight `p`
carry the drift, and price a call used only on the last day, with share price `S > 0`,
strike `K > 0` and life `T > 0`. Then as the number of steps `n` grows, the `n`-step tree's
call price closes on the Black-Scholes price. -/
theorem crr_call_price_tendsto_black_scholes (S K r q σ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun n : ℕ => crrCallPrice S K r q σ T n) atTop
      (𝓝 (blackScholesCall S K r q σ T)) := by
  have hσ2 : σ ^ 2 ≠ 0 := by positivity
  -- the step's log move `h = σ √(T/n)` and the drift ratio `α = (r - q)/σ²`
  set α : ℝ := (r - q) / σ ^ 2 with hα
  set hs : ℕ → ℝ := fun n => σ * √(T / n) with hhs
  have hs_ne : ∀ᶠ n : ℕ in atTop, hs n ≠ 0 := by
    filter_upwards [eventually_ge_atTop 1] with n hn
    have : (0 : ℝ) < n := by exact_mod_cast hn
    exact (mul_pos hσ (sqrt_pos.2 (div_pos hT this))).ne'
  have hs_tend : Tendsto hs atTop (𝓝[≠] 0) := by
    refine tendsto_nhdsWithin_iff.2 ⟨?_, hs_ne⟩
    have h1 : Tendsto (fun n : ℕ => T / (n : ℝ)) atTop (𝓝 0) :=
      tendsto_const_div_atTop_nhds_zero_nat T
    have h2 := ((continuous_sqrt.tendsto 0).comp h1).const_mul σ
    simpa only [sqrt_zero, mul_zero, Function.comp_def] using h2
  have hs_sq : ∀ n : ℕ, 1 ≤ n → (n : ℝ) * hs n ^ 2 = σ ^ 2 * T := by
    intro n hn
    have : (n : ℝ) ≠ 0 := Nat.cast_ne_zero.2 (by omega)
    simp only [hhs]; rw [mul_pow, sq_sqrt (by positivity)]; field_simp
  have hw_eq : ∀ n : ℕ, 1 ≤ n → crrWeight r q σ (T / n) =
      (exp (α * hs n ^ 2) - exp (-hs n)) / (exp (hs n) - exp (-hs n)) := by
    intro n hn
    have : (n : ℝ) ≠ 0 := Nat.cast_ne_zero.2 (by omega)
    have e : (r - q) * (T / n) = α * hs n ^ 2 := by
      simp only [hα, hhs]; rw [mul_pow, sq_sqrt (by positivity)]; field_simp
    unfold crrWeight crrUp crrDown; rw [e]
  -- the up weight: `(2p - 1)/h → (2α - 1)/2`, so `p → 1/2`
  have hP_seq : Tendsto (fun n : ℕ => (2 * crrWeight r q σ (T / n) - 1) / hs n) atTop
      (𝓝 ((2 * α - 1) / 2)) := by
    refine ((crr_lim_weight α).comp hs_tend).congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    simp only [Function.comp, hw_eq n hn]
  have hs0 : Tendsto hs atTop (𝓝 0) := hs_tend.mono_right nhdsWithin_le_nhds
  have hp_half : Tendsto (fun n : ℕ => crrWeight r q σ (T / n)) atTop (𝓝 (1 / 2)) := by
    have h2 : Tendsto (fun n : ℕ => 2 * crrWeight r q σ (T / n) - 1) atTop (𝓝 0) := by
      rw [show (0 : ℝ) = (2 * α - 1) / 2 * 0 by ring]
      refine (hP_seq.mul hs0).congr' ?_
      filter_upwards [hs_ne] with n hn
      field_simp
    have := (h2.add_const 1).div_const 2
    convert this using 2 <;> ring
  have hp_ev : ∀ᶠ n : ℕ in atTop, crrWeight r q σ (T / n) ∈ Set.Icc 0 1 :=
    hp_half.eventually (Icc_mem_nhds (by norm_num) (by norm_num))
  -- clamp the weight into [0, 1] so every tree gives a probability measure
  set pc : ℕ → ℝ := fun n => max 0 (min (crrWeight r q σ (T / n)) 1) with hpc
  have pc0 : ∀ n, 0 ≤ pc n := fun n => le_max_left _ _
  have pc1 : ∀ n, pc n ≤ 1 := fun n => max_le zero_le_one (min_le_right _ _)
  have pc_ev : ∀ᶠ n : ℕ in atTop, pc n = crrWeight r q σ (T / n) := by
    filter_upwards [hp_ev] with n hn
    simp only [hpc]; rw [min_eq_left hn.2, max_eq_right hn.1]
  let ν : ℕ → ProbabilityMeasure ℝ := fun n =>
    ⟨crrLogMeasure n (pc n) (hs n), crrLogMeasure_isProb n (pc0 n) (pc1 n) (hs n)⟩
  -- the Gaussian limit
  set c : ℝ := σ * √T with hc
  have hc2 : c ^ 2 = σ ^ 2 * T := by rw [hc, mul_pow, sq_sqrt hT.le]
  set Y : ℝ → ℝ := fun z => (r - q - σ ^ 2 / 2) * T + c * z with hY
  have hYm : Measurable Y := by fun_prop
  have hYc : Continuous Y := by fun_prop
  let γ : ProbabilityMeasure ℝ :=
    ⟨(gaussianReal 0 1).map Y, inferInstance⟩
  have hγ : (gaussianReal 0 1).map Y =
      gaussianReal (c * 0 + (r - q - σ ^ 2 / 2) * T) (⟨c ^ 2, sq_nonneg _⟩ * 1) := by
    have : Y = (· + (r - q - σ ^ 2 / 2) * T) ∘ (c * ·) := by
      ext z; simp only [hY, Function.comp]; ring
    rw [this, ← Measure.map_map (measurable_add_const _) (measurable_const_mul _),
      gaussianReal_map_const_mul, gaussianReal_map_add_const]
    rfl
  -- weak convergence, by Lévy's theorem
  have hweak : Tendsto ν atTop (𝓝 γ) := by
    rw [ProbabilityMeasure.tendsto_iff_tendsto_charFun]
    intro t
    show Tendsto (fun n => charFun (crrLogMeasure n (pc n) (hs n)) t) atTop
      (𝓝 (charFun ((gaussianReal 0 1).map Y) t))
    rw [hγ, charFun_gaussianReal]
    set A : ℕ → ℝ := fun n => (n : ℝ) * (cos (t * hs n) - 1) with hA
    set B : ℕ → ℝ := fun n =>
      (n : ℝ) * ((2 * crrWeight r q σ (T / n) - 1) * sin (t * hs n)) with hB
    have hAlim : Tendsto A atTop (𝓝 (σ ^ 2 * T * (-(t ^ 2 / 2)))) := by
      refine (((crr_lim_cos t).comp hs_tend).const_mul (σ ^ 2 * T)).congr' ?_
      filter_upwards [eventually_ge_atTop 1, hs_ne] with n hn hn0
      simp only [Function.comp, hA, ← hs_sq n hn]
      field_simp
    have hBlim : Tendsto B atTop (𝓝 (σ ^ 2 * T * ((2 * α - 1) / 2 * t))) := by
      refine ((hP_seq.mul ((crr_lim_sin t).comp hs_tend)).const_mul (σ ^ 2 * T)).congr' ?_
      filter_upwards [eventually_ge_atTop 1, hs_ne] with n hn hn0
      simp only [Function.comp, hB, ← hs_sq n hn]
      field_simp
    have hAB : Tendsto (fun n : ℕ => ((A n : ℝ) : ℂ) + ((B n : ℝ) : ℂ) * Complex.I) atTop
        (𝓝 (((σ ^ 2 * T * (-(t ^ 2 / 2)) : ℝ) : ℂ) +
          ((σ ^ 2 * T * ((2 * α - 1) / 2 * t) : ℝ) : ℂ) * Complex.I)) :=
      ((Complex.continuous_ofReal.tendsto _).comp hAlim).add
        (((Complex.continuous_ofReal.tendsto _).comp hBlim).mul_const _)
    set f : ℕ → ℂ := fun n => (crrWeight r q σ (T / n) : ℂ) * Complex.exp (t * hs n * Complex.I) +
      (1 - crrWeight r q σ (T / n)) * Complex.exp (-(t * hs n) * Complex.I) with hf
    have hf1 : ∀ n : ℕ, (n : ℂ) * (f n - 1) = ((A n : ℝ) : ℂ) + ((B n : ℝ) : ℂ) * Complex.I := by
      intro n
      simp only [hf, hA, hB]
      rw [Complex.exp_mul_I, Complex.exp_mul_I, Complex.cos_neg, Complex.sin_neg]
      push_cast; ring
    have key := Complex.tendsto_one_add_pow_exp_of_tendsto (g := fun n => f n - 1)
      (by simp only [hf1]; exact hAB)
    simp only [add_sub_cancel] at key
    have hlim : ((σ ^ 2 * T * (-(t ^ 2 / 2)) : ℝ) : ℂ) +
          ((σ ^ 2 * T * ((2 * α - 1) / 2 * t) : ℝ) : ℂ) * Complex.I =
        (t : ℂ) * ((c * 0 + (r - q - σ ^ 2 / 2) * T : ℝ) : ℂ) * Complex.I -
          ((((⟨c ^ 2, sq_nonneg _⟩ * 1 : NNReal)) : ℝ) : ℂ) * (t : ℂ) ^ 2 / 2 := by
      have e1 : σ ^ 2 * T * ((2 * α - 1) / 2 * t) = t * (c * 0 + (r - q - σ ^ 2 / 2) * T) := by
        rw [hα]; field_simp; ring
      have e2 : (((⟨c ^ 2, sq_nonneg _⟩ * 1 : NNReal)) : ℝ) = σ ^ 2 * T := by
        show c ^ 2 * 1 = σ ^ 2 * T
        rw [mul_one, hc2]
      rw [e2, e1]; push_cast; ring
    rw [← hlim]
    refine key.congr' ?_
    filter_upwards [pc_ev] with n hn
    rw [crrLogMeasure_charFun n (pc0 n) (pc1 n), hn]
  -- the put payoff `max (K - S e^x) 0` is bounded and continuous
  set g : ℝ → ℝ := fun x => max (K - S * exp x) 0 with hg
  have hg_cont : Continuous g := by fun_prop
  have hg_bd : ∀ x, ‖g x‖ ≤ K := by
    intro x
    rw [Real.norm_eq_abs, abs_of_nonneg (le_max_right _ _)]
    exact max_le (by nlinarith [exp_pos x]) hK.le
  let G : BoundedContinuousFunction ℝ ℝ := BoundedContinuousFunction.ofNormedAddCommGroup g hg_cont K hg_bd
  have hconv := (ProbabilityMeasure.tendsto_iff_forall_integral_tendsto.1 hweak) G
  have hmax : ∀ y : ℝ, max (y - K) 0 = max (K - y) 0 + y - K := by
    intro y
    rcases le_total y K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  -- the tree price, by put-call parity on the tree
  have htree : ∀ᶠ n : ℕ in atTop, crrCallPrice S K r q σ T n =
      exp (-(r * T)) * (∫ x, G x ∂(ν n : Measure ℝ) + S * exp ((r - q) * T) - K) := by
    filter_upwards [pc_ev, eventually_ge_atTop 1] with n hpn hn
    show _ = exp (-(r * T)) * (∫ x, g x ∂(crrLogMeasure n (pc n) (hs n)) + _ - _)
    rw [crrLogMeasure_integral n (pc0 n) (pc1 n), hpn]
    have h3 := crr_forward S r q σ T n hσ hT hn
    have h1 := crr_weights_sum n (crrWeight r q σ (T / n))
    have hy : ∀ k : ℕ, S * crrUp σ (T / n) ^ k * crrDown σ (T / n) ^ (n - k) =
        S * exp (hs n * k - hs n * ((n - k : ℕ) : ℝ)) := by
      intro k
      unfold crrUp crrDown
      rw [← exp_nat_mul, ← exp_nat_mul, mul_assoc, ← exp_add]
      simp only [hhs]; ring_nf
    unfold crrCallPrice
    congr 1
    rw [← h3]
    calc _ = ∑ k ∈ Finset.range (n + 1),
          (((n.choose k : ℝ) * crrWeight r q σ (T / n) ^ k * (1 - crrWeight r q σ (T / n)) ^ (n - k))
            • g (hs n * k - hs n * ((n - k : ℕ) : ℝ)) +
          (n.choose k : ℝ) * crrWeight r q σ (T / n) ^ k * (1 - crrWeight r q σ (T / n)) ^ (n - k) *
            (S * crrUp σ (T / n) ^ k * crrDown σ (T / n) ^ (n - k)) -
          K * ((n.choose k : ℝ) * crrWeight r q σ (T / n) ^ k *
            (1 - crrWeight r q σ (T / n)) ^ (n - k))) := by
          refine Finset.sum_congr rfl fun k _ => ?_
          rw [hmax, smul_eq_mul, hy, hg]; ring
      _ = _ := by
          rw [Finset.sum_sub_distrib, Finset.sum_add_distrib, ← Finset.mul_sum, h1, mul_one]
  -- the Black-Scholes price, by put-call parity under the bell curve
  have hbs : blackScholesCall S K r q σ T =
      exp (-(r * T)) * (∫ x, G x ∂(γ : Measure ℝ) + S * exp ((r - q) * T) - K) := by
    unfold blackScholesCall
    congr 1
    show _ = ∫ x, g x ∂((gaussianReal 0 1).map Y) + _ - _
    rw [integral_map hYm.aemeasurable hg_cont.aestronglyMeasurable]
    have hint1 : Integrable (fun z => g (Y z)) (gaussianReal 0 1) :=
      Integrable.of_bound (hg_cont.comp hYc).aestronglyMeasurable K
        (ae_of_all _ fun z => hg_bd (Y z))
    have hint2 : Integrable (fun z => S * exp (Y z)) (gaussianReal 0 1) := by
      have := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) c).const_mul
        (S * exp ((r - q - σ ^ 2 / 2) * T))
      refine this.congr (ae_of_all _ fun z => ?_)
      simp only [hY, exp_add]; ring
    have hmgf : ∫ z, exp (c * z) ∂(gaussianReal 0 1) = exp (c ^ 2 / 2) := by
      have := congrFun (mgf_fun_id_gaussianReal (μ := 0) (v := 1)) c
      simpa [mgf] using this
    have hE : ∫ z, S * exp (Y z) ∂(gaussianReal 0 1) = S * exp ((r - q) * T) := by
      simp only [hY, exp_add]
      rw [integral_const_mul, integral_const_mul, hmgf, ← exp_add, hc2]
      congr 2; ring
    calc _ = ∫ z, (g (Y z) + S * exp (Y z) - K) ∂(gaussianReal 0 1) := by
          refine integral_congr_ae (ae_of_all _ fun z => ?_)
          simp only [hg, hY, hc]; rw [hmax]
      _ = _ := by
          have hint12 : Integrable (fun z => g (Y z) + S * exp (Y z)) (gaussianReal 0 1) :=
            hint1.add hint2
          rw [integral_sub hint12 (integrable_const K), integral_add hint1 hint2, hE]
          simp
  rw [hbs]
  refine Tendsto.congr' (htree.mono fun n hn => hn.symm) ?_
  exact ((hconv.add_const _).sub_const _).const_mul _

/-- **The weight has to be a weight** (When it holds). On a step of length `Δt > 0` with
volatility `σ > 0`, the up weight `p` lands strictly between 0 and 1 exactly when the size of
`r - q` times the square root of `Δt` stays under `σ`. -/
theorem crr_weight_strictly_between_zero_and_one_iff (r q σ Δt : ℝ) (hσ : 0 < σ) (hΔt : 0 < Δt) :
    (0 < crrWeight r q σ Δt ∧ crrWeight r q σ Δt < 1) ↔ |r - q| * √Δt < σ := by
  have hs : 0 < √Δt := Real.sqrt_pos.2 hΔt
  have hss : √Δt * √Δt = Δt := Real.mul_self_sqrt hΔt.le
  have hD : 0 < crrUp σ Δt - crrDown σ Δt := by
    unfold crrUp crrDown; rw [sub_pos, exp_lt_exp]; nlinarith
  have key : |r - q| * √Δt < σ ↔ -(σ * √Δt) < (r - q) * Δt ∧ (r - q) * Δt < σ * √Δt := by
    have : |r - q| * √Δt = |(r - q) * √Δt| := by rw [abs_mul, abs_of_pos hs]
    rw [this, abs_lt]
    constructor <;> rintro ⟨h1, h2⟩ <;> constructor <;> nlinarith
  rw [key]
  unfold crrWeight
  rw [div_pos_iff_of_pos_right hD, div_lt_one hD, sub_pos, sub_lt_sub_iff_right]
  unfold crrUp crrDown
  rw [exp_lt_exp, exp_lt_exp]

/-- **The tree's average end price is the forward** (Why it works, Step 2). For every tree of
`n ≥ 1` steps over a life `T > 0` with volatility `σ > 0`, averaging the `n + 1` end prices
`S u^k d^(n-k)` with their weights gives exactly the forward price `S e^((r-q)T)`. -/
theorem crr_average_end_price_eq_forward (S r q σ T : ℝ) (n : ℕ)
    (hσ : 0 < σ) (hT : 0 < T) (hn : 1 ≤ n) :
    ∑ k ∈ Finset.range (n + 1),
      (n.choose k : ℝ) * crrWeight r q σ (T / n) ^ k * (1 - crrWeight r q σ (T / n)) ^ (n - k) *
        (S * crrUp σ (T / n) ^ k * crrDown σ (T / n) ^ (n - k)) =
      S * exp ((r - q) * T) := by
  exact crr_forward S r q σ T n hσ hT hn

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- One year-long step: the log move is σ√1 = 0.20, so u = e^0.2 and d = e^(-0.2).
example : (1 / 5 : ℝ) * √1 = 1 / 5 := by norm_num
-- Up then down lands back on the start: the two-step tree's middle end price is exactly 100.
example : (100 : ℝ) * exp (1 / 5 * √(1 / 2)) * exp (-(1 / 5 * √(1 / 2))) = 100 := by
  rw [mul_assoc, ← exp_add]; norm_num
-- Recombining: 2 steps end in 2 + 1 = 3 prices, not 2² = 4; 2,000 steps end in 2,001.
example : 2 + 1 = 3 ∧ 2 ^ 2 = 4 ∧ 2000 + 1 = 2001 := by decide
-- The drift the tree aims at: r - q - σ²/2 = 0.05 - 0.02 - 0.02 = 0.01 a year.
example : (5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2 = 1 / 100 := by norm_num
-- The spread falls short by ((r - q - σ²/2)/σ)² Δt = 0.0025 Δt of σ²Δt.
example : ((1 / 100 : ℚ) / (1 / 5)) ^ 2 = 25 / 10000 := by norm_num
-- On a 10-step tree, Δt = 1/10, the predicted spread is 1 - 0.000250 = 0.999750 of σ²Δt.
example : (1 : ℚ) - 25 / 10000 * (1 / 10) = 99975 / 100000 := by norm_num
-- Acme's weight is a weight: |0.05 - 0.02| √1 = 0.03 < 0.20.
example : |(5 / 100 : ℝ) - 2 / 100| * √1 < 1 / 5 := by
  rw [abs_of_pos (by norm_num)]; norm_num
-- A share with 2 percent volatility on a year-long step fails it: 0.03 is not under 0.02.
example : ¬ (|(5 / 100 : ℝ) - 2 / 100| * √1 < 2 / 100) := by
  rw [abs_of_pos (by norm_num)]; norm_num
-- Consecutive step counts from 10 to 41: the pairs (10, 11), ..., (40, 41) number 31.
example : (Finset.Icc 10 40).card = 31 := by decide

#print axioms crr_call_price_tendsto_black_scholes
#print axioms crr_weight_strictly_between_zero_and_one_iff
#print axioms crr_average_end_price_eq_forward
