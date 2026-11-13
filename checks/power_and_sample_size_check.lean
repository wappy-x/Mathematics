-- Power: in the normal-curve power formula for comparing two recovery rates, the power reaches its target exactly when the patients per arm reach (z_{1-α/2} σ₀ + z_{1-β} σ₁)² / δ², and the observed gap between two independent binomial arms has mean δ and variance σ₁² / n exactly.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Distributions.Binomial
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory
open scoped unitInterval

/-! Notation as on the card. `Φ` is the standard bell's area to the left of a point:
`cdf (gaussianReal 0 1)`. The placebo recovers with chance `p₀`, the drug with chance `p₁`,
the gain is `δ = p₁ - p₀`, and `n` is the number of patients in each arm. The false-alarm rate
is `α`, split over both tails, and the miss chance is `β`, so the power is `1 - β`. The cutoffs
`z_{1-α/2}` and `z_{1-β}` are the points where `Φ` reaches `1 - α/2` and `1 - β`. -/

lemma stdCdf_strictMono : StrictMono (cdf (gaussianReal 0 1)) := by
  intro x y hxy
  have hpos : 0 < gaussianReal 0 1 (Set.Ioc x y) := by
    have h1 : volume (Set.Ioc x y) ≠ 0 := by simp [Real.volume_Ioc, hxy]
    exact pos_iff_ne_zero.2 (fun h => h1 (gaussianReal_absolutelyContinuous' 0 one_ne_zero h))
  have hu : gaussianReal 0 1 (Set.Iic y)
      = gaussianReal 0 1 (Set.Iic x) + gaussianReal 0 1 (Set.Ioc x y) := by
    rw [← Set.Iic_union_Ioc_eq_Iic hxy.le,
      measure_union (Set.Iic_disjoint_Ioc le_rfl) measurableSet_Ioc]
  have : ENNReal.ofReal (cdf (gaussianReal 0 1) x) < ENNReal.ofReal (cdf (gaussianReal 0 1) y) := by
    rw [ofReal_cdf, ofReal_cdf, hu]
    exact ENNReal.lt_add_right (measure_ne_top _ _) hpos.ne'
  exact (ENNReal.ofReal_lt_ofReal_iff_of_nonneg (cdf_nonneg _ _)).1 this

#print axioms stdCdf_strictMono

lemma stdCdf_zero : cdf (gaussianReal 0 1) 0 = 1 / 2 := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  set μ := gaussianReal 0 1 with hμ
  have hmap : μ.map (fun x => -x) = μ := by rw [hμ, gaussianReal_map_neg]; simp
  have hsymm : μ (Set.Iic 0) = μ (Set.Ioi 0) := by
    calc μ (Set.Iic 0) = (μ.map (fun x => -x)) (Set.Iic 0) := by rw [hmap]
    _ = μ ((fun x => -x) ⁻¹' Set.Iic 0) := Measure.map_apply measurable_neg measurableSet_Iic
    _ = μ (Set.Ici 0) := by congr 1; ext x; simp
    _ = μ (Set.Ioi 0) := measure_congr Ioi_ae_eq_Ici.symm
  have hsum : μ (Set.Iic 0) + μ (Set.Ioi 0) = 1 := by
    rw [← measure_union (Set.Iic_disjoint_Ioi le_rfl) measurableSet_Ioi,
      Set.Iic_union_Ioi, measure_univ]
  rw [cdf_eq_real, measureReal_def]
  rw [← hsymm] at hsum
  have h2 : μ (Set.Iic 0) = 2⁻¹ := by
    rw [← ENNReal.inv_two_add_inv_two] at hsum
    have := hsum
    rw [← two_mul, ← two_mul] at this
    exact (ENNReal.mul_right_inj two_ne_zero ENNReal.ofNat_ne_top).1 this
  rw [h2]; simp

#print axioms stdCdf_zero

lemma binomial_factorial_sum (x y : ℝ) (m : ℕ) :
    ∑ k ∈ Finset.range (m + 2 + 1),
      ((m + 2).choose k * x ^ k * y ^ (m + 2 - k)) * ((k : ℝ) * ((k : ℝ) - 1)) =
      ((m : ℝ) + 2) * ((m : ℝ) + 1) * x ^ 2 * (x + y) ^ m := by
  rw [Finset.sum_range_succ', Finset.sum_range_succ', add_pow, Finset.mul_sum]
  simp only [Nat.cast_add, Nat.cast_one, CharP.cast_eq_zero, zero_mul, mul_zero,
    add_zero, zero_add, sub_self]
  refine Finset.sum_congr rfl fun k hk => ?_
  have hk' : k ≤ m := Nat.lt_succ_iff.1 (Finset.mem_range.1 hk)
  have e1 : ((m + 2).choose (k + 2) : ℝ) * ((k : ℝ) + 2) * ((k : ℝ) + 1)
      = ((m : ℝ) + 2) * ((m : ℝ) + 1) * (m.choose k) := by
    have a := Nat.add_one_mul_choose_eq (m + 1) (k + 1)
    have b := Nat.add_one_mul_choose_eq m k
    have a' : ((m : ℝ) + 1 + 1) * ((m + 1).choose (k + 1)) = ((m + 2).choose (k + 2)) * ((k : ℝ) + 1 + 1) := by
      exact_mod_cast a
    have b' : ((m : ℝ) + 1) * (m.choose k) = ((m + 1).choose (k + 1)) * ((k : ℝ) + 1) := by
      exact_mod_cast b
    linear_combination (-(k : ℝ) - 1) * a' - ((m : ℝ) + 2) * b'
  have e2 : m + 2 - (k + 1 + 1) = m - k := by omega
  rw [e2]
  linear_combination (x ^ k * x ^ 2 * y ^ (m - k)) * e1

#print axioms binomial_factorial_sum

lemma variance_id_map_cast_binomial (n : ℕ) (p : I) :
    variance id ((binomial n p).map (Nat.cast : ℕ → ℝ)) = n * p * (1 - p) := by
  set μ := (binomial n p).map (Nat.cast : ℕ → ℝ) with hμ
  have hmem : MemLp id 2 μ :=
    (memLp_two_iff_integrable_sq aestronglyMeasurable_id).2 (integrable_map_cast_binomial _)
  have hmean : ∫ x, x ∂μ = p * n := by
    have := integral_of_hasLaw_binomial (HasLaw.id (μ := μ))
    simpa using this
  have hfact : ∫ x, x * (x - 1) ∂μ = n * (n - 1) * (p : ℝ) ^ 2 := by
    rw [hμ, integral_map_cast_binomial]
    rcases n with _ | _ | m
    · rw [← Nat.range_succ_eq_Iic]; simp
    · simp [Finset.sum_range_succ, ← Nat.range_succ_eq_Iic]
    · rw [← Nat.range_succ_eq_Iic]
      simp only [smul_eq_mul]
      rw [binomial_factorial_sum, add_sub_cancel, one_pow]
      push_cast
      ring
  rw [variance_eq_sub hmem]
  have hsq : ∫ x, (id ^ 2 : ℝ → ℝ) x ∂μ = ∫ x, x * (x - 1) ∂μ + ∫ x, x ∂μ := by
    rw [← integral_add (integrable_map_cast_binomial _) (integrable_map_cast_binomial _)]
    congr 1
    ext x
    simp
    ring
  simp only [id] at hsq ⊢
  rw [hsq, hfact, hmean]
  ring

#print axioms variance_id_map_cast_binomial

/-- **The sample size that buys the power.** For a placebo rate `p₀` and a larger drug rate `p₁`
(both strictly between 0 and 1), a false-alarm rate `α` strictly between 0 and 1, and a target
power `1 - β` of at least one half, write `σ₀ = √(2 p̄ (1 - p̄))` with `p̄ = (p₀ + p₁)/2`,
`σ₁ = √(p₀(1 - p₀) + p₁(1 - p₁))`, and `δ = p₁ - p₀`. Then the approximate power with `n`
patients per arm, `Φ((δ √n - z_{1-α/2} σ₀) / σ₁)`, reaches `1 - β` exactly when
`n ≥ (z_{1-α/2} σ₀ + z_{1-β} σ₁)² / δ²`. -/
theorem power_reaches_target_iff_n_ge_sample_size
    (p₀ p₁ α β n zα zβ : ℝ)
    (hp₀ : 0 < p₀) (hp₀₁ : p₀ < p₁) (hp₁ : p₁ < 1)
    (hα₀ : 0 < α) (hα₁ : α < 1) (hβ₀ : 0 < β) (hβ₁ : β ≤ 1 / 2)
    (hn : 0 ≤ n)
    (hzα : cdf (gaussianReal 0 1) zα = 1 - α / 2)
    (hzβ : cdf (gaussianReal 0 1) zβ = 1 - β) :
    let δ := p₁ - p₀
    let pbar := (p₀ + p₁) / 2
    let σ₀ := Real.sqrt (2 * pbar * (1 - pbar))
    let σ₁ := Real.sqrt (p₀ * (1 - p₀) + p₁ * (1 - p₁))
    (1 - β ≤ cdf (gaussianReal 0 1) ((δ * Real.sqrt n - zα * σ₀) / σ₁) ↔
      (zα * σ₀ + zβ * σ₁) ^ 2 / δ ^ 2 ≤ n) := by
  intro δ pbar σ₀ σ₁
  have hδ : 0 < δ := by simp only [δ]; linarith
  have hσ₁ : 0 < σ₁ := Real.sqrt_pos.2 (by nlinarith)
  have hσ₀ : 0 ≤ σ₀ := Real.sqrt_nonneg _
  have hzβ0 : 0 ≤ zβ := by
    by_contra h
    push Not at h
    have := stdCdf_strictMono h
    rw [hzβ, stdCdf_zero] at this
    linarith
  have hzα0 : 0 ≤ zα := by
    by_contra h
    push Not at h
    have := stdCdf_strictMono h
    rw [hzα, stdCdf_zero] at this
    linarith
  have hA : 0 ≤ zα * σ₀ + zβ * σ₁ := by positivity
  have hsq : Real.sqrt n ^ 2 = n := Real.sq_sqrt hn
  have hs : 0 ≤ Real.sqrt n := Real.sqrt_nonneg n
  rw [← hzβ, stdCdf_strictMono.le_iff_le, le_div_iff₀ hσ₁, div_le_iff₀ (by positivity)]
  constructor
  · intro h
    have h' : zα * σ₀ + zβ * σ₁ ≤ δ * Real.sqrt n := by linarith
    have := pow_le_pow_left₀ hA h' 2
    nlinarith
  · intro h
    have h' : (zα * σ₀ + zβ * σ₁) ^ 2 ≤ (δ * Real.sqrt n) ^ 2 := by nlinarith
    have := (pow_le_pow_iff_left₀ hA (by positivity) two_ne_zero).1 h'
    linarith

/-- **The observed gap: its exact mean and variance.** If the placebo arm's recovery count `X₀`
and the drug arm's count `X₁` are independent, each binomial with `n` patients and recovery
chances `p₀` and `p₁`, then the observed gap `D̂ = X₁/n - X₀/n` has mean `δ = p₁ - p₀` and
variance `(p₀(1 - p₀) + p₁(1 - p₁)) / n = σ₁² / n`. -/
theorem observed_gap_mean_and_variance
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (n : ℕ) (hn : 0 < n) (p₀ p₁ : I) (X₀ X₁ : Ω → ℝ)
    (h₀ : HasLaw X₀ (binomial n p₀ |>.map (Nat.cast : ℕ → ℝ)) P)
    (h₁ : HasLaw X₁ (binomial n p₁ |>.map (Nat.cast : ℕ → ℝ)) P)
    (hind : IndepFun X₀ X₁ P) :
    P[fun ω => X₁ ω / n - X₀ ω / n] = (p₁ : ℝ) - p₀ ∧
      variance (fun ω => X₁ ω / n - X₀ ω / n) P =
        ((p₀ : ℝ) * (1 - p₀) + (p₁ : ℝ) * (1 - p₁)) / n := by
  have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  have hmem : ∀ p : I, MemLp id 2 ((binomial n p).map (Nat.cast : ℕ → ℝ)) := fun p =>
    (memLp_two_iff_integrable_sq aestronglyMeasurable_id).2 (integrable_map_cast_binomial _)
  have m₀ : MemLp X₀ 2 P := h₀.memLp (hmem p₀)
  have m₁ : MemLp X₁ 2 P := h₁.memLp (hmem p₁)
  constructor
  · rw [integral_sub ((m₁.integrable one_le_two).div_const _)
      ((m₀.integrable one_le_two).div_const _), integral_div, integral_div,
      integral_of_hasLaw_binomial h₀, integral_of_hasLaw_binomial h₁]
    field_simp
  · have hI : IndepFun (fun ω => X₁ ω / n) (fun ω => -(X₀ ω / n)) P :=
      hind.symm.comp (φ := fun x => x / (n : ℝ)) (ψ := fun x => -(x / (n : ℝ)))
        (by fun_prop) (by fun_prop)
    have hfun : (fun ω => X₁ ω / n - X₀ ω / n)
        = (fun ω => X₁ ω / n) + (fun ω => -(X₀ ω / n)) := by
      ext ω; simp [sub_eq_add_neg]
    rw [hfun, hI.variance_add
      (by simpa [div_eq_mul_inv] using m₁.mul_const ((n : ℝ)⁻¹))
      (by simpa [div_eq_mul_inv, Pi.neg_def] using (m₀.mul_const ((n : ℝ)⁻¹)).neg), variance_fun_neg]
    simp only [div_eq_mul_inv]
    rw [variance_mul_const, variance_mul_const, h₀.variance_eq, h₁.variance_eq,
      variance_id_map_cast_binomial, variance_id_map_cast_binomial]
    field_simp
    ring

/-! The card's worked numbers, as exact fractions: placebo `p₀ = 7/20` (0.35),
drug `p₁ = 9/20` (0.45). -/

-- The average rate is 2/5 (0.40).
example : ((7 / 20 + 9 / 20) / 2 : ℚ) = 2 / 5 := by norm_num

-- σ₀² = 2 × 0.40 × 0.60 = 0.48.
example : (2 * (2 / 5) * (1 - 2 / 5) : ℚ) = 12 / 25 := by norm_num

-- σ₁² = 0.35 × 0.65 + 0.45 × 0.55 = 0.475.
example : ((7 / 20) * (1 - 7 / 20) + (9 / 20) * (1 - 9 / 20) : ℚ) = 19 / 40 := by norm_num

-- Allowing 1 in 20 to drop out turns 376 into 396: the 19 in 20 who stay from 396 still number
-- at least 376, and from 395 they do not.
example : 376 * 20 ≤ 396 * 19 ∧ 395 * 19 < 376 * 20 := by norm_num

-- Booking 400 per arm: if 1 in 20 leave, 380 remain, still above 376.
example : 400 - 400 / 20 = 380 ∧ 376 ≤ 380 := by decide

#print axioms power_reaches_target_iff_n_ge_sample_size
#print axioms observed_gap_mean_and_variance
