-- Mixed-effects models: in the random-intercept model the shrunken mean μ + λ(ȳ - μ), with λ = τ²/(τ² + σ²/n), is the best straight-line predictor of a group's true mean from its raw mean, with error variance λσ²/n, and Henderson's penalised least-squares fit gives these shrunken means around the weighted overall mean.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic

/-! Notation as on the card. One school has `n` pupils. `μ` is the district's overall mean,
`b` the school's random effect, `ε i` pupil `i`'s own gap from the school's true mean.
`τ2` is the between-school variance τ², `σ2` the within-school variance σ².
The school's raw mean is `ȳ = μ + b + (ε 1 + ... + ε n)/n` and its true mean is `θ = μ + b`.
The kept share is `λ = τ²/(τ² + σ²/n)` (`lam` here; `λ` is a reserved word in Lean). -/

open MeasureTheory ProbabilityTheory

noncomputable section

/-- Helper: in the random-intercept model, the mean of a product of two straight-line
combinations of `1`, `b` and `∑ i, ε i` follows from the variances alone. -/
lemma mixed_effects_bilin
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (τ2 σ2 : ℝ)
    (b : Ω → ℝ) (ε : Fin n → Ω → ℝ)
    (hbL2 : MemLp b 2 P) (hεL2 : ∀ i, MemLp (ε i) 2 P)
    (hbmean : ∫ ω, b ω ∂P = 0) (hεmean : ∀ i, ∫ ω, ε i ω ∂P = 0)
    (hbvar : variance b P = τ2) (hεvar : ∀ i, variance (ε i) P = σ2)
    (hind : iIndepFun ε P) (hbind : ∀ i, IndepFun b (ε i) P) (α β γ α' β' γ' : ℝ) :
    ∫ ω, (α + β * b ω + γ * ∑ i, ε i ω) * (α' + β' * b ω + γ' * ∑ i, ε i ω) ∂P
      = α * α' + β * β' * τ2 + γ * γ' * (n * σ2) := by
  set S : Ω → ℝ := ∑ i, ε i with hSdef
  have hSapp : ∀ ω, ∑ i, ε i ω = S ω := fun ω => by simp [hSdef, Finset.sum_apply]
  simp_rw [hSapp]
  have hSL2 : MemLp S 2 P := memLp_finsetSum' _ (fun i _ => hεL2 i)
  have hS1 : ∫ ω, S ω ∂P = 0 := by
    simp_rw [← hSapp]
    rw [integral_finsetSum _ (fun i _ => (hεL2 i).integrable (by norm_num))]
    simp [hεmean]
  have hbb : ∫ ω, b ω * b ω ∂P = τ2 := by
    have h := variance_eq_sub hbL2
    rw [hbvar, hbmean] at h
    rw [h]
    simp [sq]
  have hSvar : variance S P = n * σ2 := by
    rw [hSdef, IndepFun.variance_sum (fun i _ => hεL2 i)
      (fun i _ j _ hij => hind.indepFun hij)]
    simp [hεvar]
  have hSS : ∫ ω, S ω * S ω ∂P = n * σ2 := by
    have h := variance_eq_sub hSL2
    rw [hSvar, hS1] at h
    rw [h]
    simp [sq]
  have hbS : ∫ ω, b ω * S ω ∂P = 0 := by
    have h1 : covariance b S P = 0 := by
      rw [hSdef, covariance_sum_right hεL2 hbL2]
      exact Finset.sum_eq_zero fun i _ => (hbind i).covariance_eq_zero hbL2 (hεL2 i)
    rw [covariance_eq_sub hbL2 hSL2, hbmean, hS1] at h1
    simpa using h1
  have ib : Integrable b P := hbL2.integrable (by norm_num)
  have iS : Integrable S P := hSL2.integrable (by norm_num)
  have ibb : Integrable (fun ω => b ω * b ω) P := hbL2.integrable_mul hbL2
  have iSS : Integrable (fun ω => S ω * S ω) P := hSL2.integrable_mul hSL2
  have ibS : Integrable (fun ω => b ω * S ω) P := hbL2.integrable_mul hSL2
  have hexp : ∀ ω, (α + β * b ω + γ * S ω) * (α' + β' * b ω + γ' * S ω)
      = α * α' + ((α * β' + β * α') * b ω + ((α * γ' + γ * α') * S ω
        + (β * β' * (b ω * b ω) + ((β * γ' + γ * β') * (b ω * S ω)
        + γ * γ' * (S ω * S ω))))) := fun ω => by ring
  simp_rw [hexp]
  rw [integral_add (integrable_const _), integral_add (ib.const_mul _),
    integral_add (iS.const_mul _), integral_add (ibb.const_mul _),
    integral_add (ibS.const_mul _)]
  · simp only [integral_const, integral_const_mul, hbmean, hS1, hbb, hbS, hSS]
    simp
    ring
  all_goals first
    | exact (iSS.const_mul _)
    | exact ((ibS.const_mul _).add (iSS.const_mul _))
    | exact ((ibb.const_mul _).add ((ibS.const_mul _).add (iSS.const_mul _)))
    | exact ((iS.const_mul _).add ((ibb.const_mul _).add ((ibS.const_mul _).add (iSS.const_mul _))))
    | exact ((ib.const_mul _).add ((iS.const_mul _).add ((ibb.const_mul _).add
        ((ibS.const_mul _).add (iSS.const_mul _)))))


/-- **The kept share is the best straight-line predictor** (the card's main claim, Step 2,
and "Normality is not needed for the formula"). In the random-intercept model for one school,
with school effect `b` of average 0 and variance τ², pupil effects `ε i` of average 0 and one
common variance σ², all independent, the shrunken mean `μ + λ (ȳ - μ)` with
`λ = τ²/(τ² + σ²/n)` misses the school's true mean `θ = μ + b` by an average squared error
of exactly `λ σ²/n`, and no other straight-line predictor `a + c ȳ` does better. -/
theorem shrunken_mean_is_best_linear_predictor
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (hn : 0 < n) (μ τ2 σ2 : ℝ)
    (b : Ω → ℝ) (ε : Fin n → Ω → ℝ)
    (hbL2 : MemLp b 2 P) (hεL2 : ∀ i, MemLp (ε i) 2 P)
    (hbmean : ∫ ω, b ω ∂P = 0) (hεmean : ∀ i, ∫ ω, ε i ω ∂P = 0)
    (hbvar : variance b P = τ2) (hεvar : ∀ i, variance (ε i) P = σ2)
    (hind : iIndepFun ε P) (hbind : ∀ i, IndepFun b (ε i) P) :
    let ybar : Ω → ℝ := fun ω => μ + b ω + (∑ i, ε i ω) / n
    let θ : Ω → ℝ := fun ω => μ + b ω
    let lam : ℝ := τ2 / (τ2 + σ2 / n)
    (∫ ω, (θ ω - (μ + lam * (ybar ω - μ))) ^ 2 ∂P = lam * (σ2 / n)) ∧
    ∀ a c : ℝ, ∫ ω, (θ ω - (μ + lam * (ybar ω - μ))) ^ 2 ∂P ≤
      ∫ ω, (θ ω - (a + c * ybar ω)) ^ 2 ∂P := by
  intro ybar θ lam
  have hτ : 0 ≤ τ2 := hbvar ▸ variance_nonneg b P
  have hσ : 0 ≤ σ2 := (hεvar ⟨0, hn⟩) ▸ variance_nonneg _ _
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  have B := mixed_effects_bilin n τ2 σ2 b ε hbL2 hεL2 hbmean hεmean hbvar hεvar hind hbind
  have hgen : ∀ a c : ℝ, ∫ ω, (θ ω - (a + c * ybar ω)) ^ 2 ∂P
      = ((1 - c) * μ - a) ^ 2 + (1 - c) ^ 2 * τ2 + c ^ 2 * (σ2 / n) := by
    intro a c
    have e : ∀ ω, (θ ω - (a + c * ybar ω)) ^ 2
        = (((1 - c) * μ - a) + (1 - c) * b ω + (-(c / n)) * ∑ i, ε i ω)
          * (((1 - c) * μ - a) + (1 - c) * b ω + (-(c / n)) * ∑ i, ε i ω) := fun ω => by
      simp only [θ, ybar]; ring
    simp_rw [e]
    rw [B]
    field_simp
  have hpred : ∀ ω, θ ω - (μ + lam * (ybar ω - μ)) = θ ω - ((1 - lam) * μ + lam * ybar ω) :=
    fun ω => by ring
  simp_rw [hpred, hgen]
  have hs0 : 0 ≤ σ2 / n := div_nonneg hσ hnR.le
  have hD2 : 0 ≤ τ2 * n + σ2 := by positivity
  rcases (add_nonneg hτ hs0).eq_or_lt with hD | hD
  · have h1 : τ2 = 0 := by linarith
    have h2 : σ2 / n = 0 := by linarith
    have hl : lam = 0 := by simp only [lam, h1, h2]; simp
    rw [hl, h1, h2]
    refine ⟨by ring, fun a c => ?_⟩
    nlinarith [sq_nonneg ((1 - c) * μ - a)]
  · have hD3 : τ2 * n + σ2 ≠ 0 := by
      have := mul_pos hD hnR
      rw [add_mul, div_mul_cancel₀ _ hnR.ne'] at this
      exact this.ne'
    refine ⟨?_, fun a c => ?_⟩
    · simp only [lam]
      field_simp
      ring
    · have hq : (1 - c) ^ 2 * τ2 + c ^ 2 * (σ2 / n) - lam * (σ2 / n)
          = (τ2 + σ2 / n) * (c - lam) ^ 2 := by
        simp only [lam]
        field_simp
        ring
      have hlam : (1 - lam) ^ 2 * τ2 + lam ^ 2 * (σ2 / n) = lam * (σ2 / n) := by
        simp only [lam]
        field_simp
        ring
      nlinarith [sq_nonneg ((1 - c) * μ - a), mul_nonneg hD.le (sq_nonneg (c - lam))]

/-- **What the model says about one school's raw mean** (Step 1). Under the same model the raw
mean `ȳ` has variance `τ² + σ²/n`, and its covariance with the school effect `b` is `τ²`. -/
theorem raw_mean_variance_and_covariance
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (hn : 0 < n) (μ τ2 σ2 : ℝ)
    (b : Ω → ℝ) (ε : Fin n → Ω → ℝ)
    (hbL2 : MemLp b 2 P) (hεL2 : ∀ i, MemLp (ε i) 2 P)
    (hbmean : ∫ ω, b ω ∂P = 0) (hεmean : ∀ i, ∫ ω, ε i ω ∂P = 0)
    (hbvar : variance b P = τ2) (hεvar : ∀ i, variance (ε i) P = σ2)
    (hind : iIndepFun ε P) (hbind : ∀ i, IndepFun b (ε i) P) :
    let ybar : Ω → ℝ := fun ω => μ + b ω + (∑ i, ε i ω) / n
    variance ybar P = τ2 + σ2 / n ∧ covariance b ybar P = τ2 := by
  intro ybar
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  have B := mixed_effects_bilin n τ2 σ2 b ε hbL2 hεL2 hbmean hεmean hbvar hεvar hind hbind
  have hmean : ∫ ω, ybar ω ∂P = μ := by
    have e : ∀ ω, ybar ω = (μ + 1 * b ω + (1 / n) * ∑ i, ε i ω)
        * (1 + 0 * b ω + 0 * ∑ i, ε i ω) := fun ω => by simp only [ybar]; ring
    simp_rw [e]
    rw [B]
    ring
  have hm : AEMeasurable ybar P := by
    have h1 := fun i => (hεL2 i).aestronglyMeasurable.aemeasurable
    have h2 := hbL2.aestronglyMeasurable.aemeasurable
    fun_prop
  constructor
  · rw [variance_eq_integral hm, hmean]
    have e : ∀ ω, (ybar ω - μ) ^ 2 = (0 + 1 * b ω + (1 / n) * ∑ i, ε i ω)
        * (0 + 1 * b ω + (1 / n) * ∑ i, ε i ω) := fun ω => by simp only [ybar]; ring
    simp_rw [e]
    rw [B]
    field_simp
    ring
  · unfold covariance
    rw [hmean, hbmean]
    have e : ∀ ω, (b ω - 0) * (ybar ω - μ) = (0 + 1 * b ω + 0 * ∑ i, ε i ω)
        * (0 + 1 * b ω + (1 / n) * ∑ i, ε i ω) := fun ω => by simp only [ybar]; ring
    simp_rw [e]
    rw [B]
    ring

/-- **Henderson's mixed-model equations give the shrinkage formula** (Step 4 and its detailed
proof). For `k` schools, school `j` with `n j ≥ 1` pupils scoring `y j i`, and variances
`σ², τ² > 0`, the penalised sum
`∑ⱼ ∑ᵢ (y j i - μ - b j)² / σ² + ∑ⱼ (b j)² / τ²`
is smallest at the weighted overall mean `μ̂ = ∑ wⱼ ȳⱼ / ∑ wⱼ`, `wⱼ = 1/(τ² + σ²/nⱼ)`, and the
shrunken effects `b j = λⱼ (ȳⱼ - μ̂)`, `λⱼ = τ²/(τ² + σ²/nⱼ)`. -/
theorem henderson_equations_give_shrinkage
    {k : ℕ} (n : Fin k → ℕ) (hn : ∀ j, 0 < n j) (σ2 τ2 : ℝ) (hσ : 0 < σ2) (hτ : 0 < τ2)
    (y : (j : Fin k) → Fin (n j) → ℝ) :
    let ybar : Fin k → ℝ := fun j => (∑ i, y j i) / n j
    let w : Fin k → ℝ := fun j => 1 / (τ2 + σ2 / n j)
    let lam : Fin k → ℝ := fun j => τ2 / (τ2 + σ2 / n j)
    let μhat : ℝ := (∑ j, w j * ybar j) / ∑ j, w j
    let F : ℝ → (Fin k → ℝ) → ℝ := fun m bb =>
      (∑ j, ∑ i, (y j i - m - bb j) ^ 2 / σ2) + ∑ j, bb j ^ 2 / τ2
    ∀ (m : ℝ) (bb : Fin k → ℝ), F μhat (fun j => lam j * (ybar j - μhat)) ≤ F m bb := by
  intro ybar w lam μhat F m bb
  have hnR : ∀ j, (0 : ℝ) < n j := fun j => by exact_mod_cast hn j
  have hD : ∀ j, 0 < τ2 + σ2 / n j := fun j => by have := hnR j; positivity
  have hG : ∀ j (mm bj : ℝ), ∑ i, (y j i - mm - bj) ^ 2 / σ2
      = ((∑ i, y j i ^ 2) - 2 * (mm + bj) * (∑ i, y j i) + n j * (mm + bj) ^ 2) / σ2 := by
    intro j mm bj
    rw [← Finset.sum_div]
    congr 1
    have e : ∀ i, (y j i - mm - bj) ^ 2 = y j i ^ 2 - 2 * (mm + bj) * y j i + (mm + bj) ^ 2 :=
      fun i => by ring
    simp only [e, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
      Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have hsum : ∑ j, w j * (ybar j - μhat) = 0 := by
    simp only [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul]
    by_cases h0 : ∑ j, w j = 0
    · have hw : ∀ j ∈ Finset.univ, w j = 0 :=
        (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => (one_div_pos.2 (hD j)).le)).1 h0
      rw [h0, Finset.sum_eq_zero (fun j hj => by rw [hw j hj, zero_mul])]
      ring
    · simp only [μhat]
      rw [mul_comm (∑ i, w i), div_mul_cancel₀ _ h0, sub_self]
  have key : ∀ j, (∑ i, (y j i - m - bb j) ^ 2 / σ2 + bb j ^ 2 / τ2)
      - (∑ i, (y j i - μhat - lam j * (ybar j - μhat)) ^ 2 / σ2
          + (lam j * (ybar j - μhat)) ^ 2 / τ2)
      = n j * (m - μhat + (bb j - lam j * (ybar j - μhat))) ^ 2 / σ2
        + (bb j - lam j * (ybar j - μhat)) ^ 2 / τ2
        - 2 * (m - μhat) * (w j * (ybar j - μhat)) := by
    intro j
    rw [hG, hG]
    have hy : ∑ i, y j i = n j * ybar j := by
      simp only [ybar]; field_simp [(hnR j).ne']
    rw [hy]
    simp only [w, lam]
    have h1 := hnR j
    have h2 := hD j
    field_simp
    ring
  have hF : ∀ mm (bb' : Fin k → ℝ),
      F mm bb' = ∑ j, (∑ i, (y j i - mm - bb' j) ^ 2 / σ2 + bb' j ^ 2 / τ2) := by
    intro mm bb'
    simp only [F, Finset.sum_add_distrib]
  rw [← sub_nonneg, hF, hF, ← Finset.sum_sub_distrib,
    Finset.sum_congr rfl (fun j _ => key j), Finset.sum_sub_distrib, ← Finset.mul_sum, hsum,
    mul_zero, sub_zero]
  exact Finset.sum_nonneg fun j _ => by have := hnR j; positivity

end

-- The card's schools: means 70, 80, 75 from 4, 25, 9 pupils; σ² = 100, τ² = 25.
-- Luck in each raw mean: 100/4 = 25, 100/25 = 4, 100/9.
example : (100 : ℚ) / 4 = 25 ∧ (100 : ℚ) / 25 = 4 := by norm_num
-- Kept shares: 25/(25 + 25) = 1/2, 25/(25 + 4) = 25/29 (0.862), 25/(25 + 100/9) = 9/13 (0.692).
example : (25 : ℚ) / (25 + 100 / 4) = 1 / 2 ∧ (25 : ℚ) / (25 + 100 / 25) = 25 / 29 ∧
    (25 : ℚ) / (25 + 100 / 9) = 9 / 13 := by norm_num
-- Weights 1/50, 1/29, 9/325, summing to 1549/18850.
example : (1 : ℚ) / (25 + 100 / 4) = 1 / 50 ∧ (1 : ℚ) / (25 + 100 / 25) = 1 / 29 ∧
    (1 : ℚ) / (25 + 100 / 9) = 9 / 325 ∧ (1 : ℚ) / 50 + 1 / 29 + 9 / 325 = 1549 / 18850 := by
  norm_num
-- Overall mean (1/50·70 + 1/29·80 + 9/325·75)/(1549/18850) = 117540/1549 (75.88), its variance
-- 18850/1549 (12.17).
example : ((1 : ℚ) / 50 * 70 + 1 / 29 * 80 + 9 / 325 * 75) / (1549 / 18850) = 117540 / 1549 := by
  norm_num
-- Shrunken means 112985/1549, 123040/1549, 116595/1549 (72.94, 79.43, 75.27).
example : (117540 / 1549 : ℚ) + 1 / 2 * (70 - 117540 / 1549) = 112985 / 1549 ∧
    (117540 / 1549 : ℚ) + 25 / 29 * (80 - 117540 / 1549) = 123040 / 1549 ∧
    (117540 / 1549 : ℚ) + 9 / 13 * (75 - 117540 / 1549) = 116595 / 1549 := by norm_num
-- Error variances λσ²/n + (1 - λ)² Var(μ̂): 24075/1549, 5700/1549, 13700/1549
-- (15.542, 3.680, 8.844), each below the raw 25, 4, 100/9.
example : (1 / 2 : ℚ) * 25 + (1 - 1 / 2) ^ 2 * (18850 / 1549) = 24075 / 1549 ∧
    (25 / 29 : ℚ) * 4 + (1 - 25 / 29) ^ 2 * (18850 / 1549) = 5700 / 1549 ∧
    (9 / 13 : ℚ) * (100 / 9) + (1 - 9 / 13) ^ 2 * (18850 / 1549) = 13700 / 1549 ∧
    (24075 / 1549 : ℚ) < 25 ∧ (5700 / 1549 : ℚ) < 4 ∧ (13700 / 1549 : ℚ) < 100 / 9 := by norm_num
-- Intraclass correlation 25/(25 + 100) = 1/5, also the one-share-for-all mistake; ridge strength 100/25 = 4.
example : (25 : ℚ) / (25 + 100) = 1 / 5 ∧ (100 : ℚ) / 25 = 4 := by norm_num
-- Pupils N = 38; pupil-weighted mean 2955/38 (77.76); MSW = 3500/35 = 100.
example : 4 + 25 + 9 = 38 ∧ 4 * 70 + 25 * 80 + 9 * 75 = 2955 ∧ 3500 / 35 = 100 := by decide
-- n₀ = (38 - (4² + 25² + 9²)/38)/2 = 19/2; MSB = 16525/76 (217.43); τ̂² = (MSB - 100)/n₀ = 8925/722 (12.36).
example : ((38 : ℚ) - (4 ^ 2 + 25 ^ 2 + 9 ^ 2) / 38) / 2 = 19 / 2 ∧
    ((4 : ℚ) * (70 - 2955 / 38) ^ 2 + 25 * (80 - 2955 / 38) ^ 2 + 9 * (75 - 2955 / 38) ^ 2) / 2
      = 16525 / 76 ∧
    ((16525 / 76 : ℚ) - 100) / (19 / 2) = 8925 / 722 := by norm_num

#print axioms mixed_effects_bilin
#print axioms shrunken_mean_is_best_linear_predictor
#print axioms raw_mean_variance_and_covariance
#print axioms henderson_equations_give_shrinkage
