-- Prices as geometric Brownian motion: the solved price S_T = S_0 exp((mu - sigma^2/2) T + sigma sqrt(T) Z), with Z a standard bell-curve draw, stays positive, has a log-growth that is a bell curve centred on (mu - sigma^2/2) T with variance sigma^2 T, averages S_0 e^(mu T), and has its middle at S_0 e^((mu - sigma^2/2) T).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Tactic.NormNum.RealSqrt

open MeasureTheory ProbabilityTheory Real

/-! The card's model line dS/S = mu dt + sigma dW needs Ito calculus, which Mathlib does not have.
This file starts from the card's solved formula
`S_T = S_0 * exp ((mu - sigma^2/2) * T + sigma * sqrt T * Z)`, with `Z` a standard bell-curve draw
(law `gaussianReal 0 1`), and states the facts the card proves about it. -/

/-- A standard bell curve puts half its weight at or below zero. -/
lemma gaussianReal_std_Iic_zero : (gaussianReal 0 1).real (Set.Iic (0 : ℝ)) = 1 / 2 := by
  have := nullSingletonClass_gaussianReal (μ := (0 : ℝ)) (v := 1) one_ne_zero
  have h0 : (gaussianReal 0 1).real {(0 : ℝ)} = 0 := by simp [Measure.real]
  have hsym : (gaussianReal 0 1).real (Set.Iic (0 : ℝ)) = (gaussianReal 0 1).real (Set.Ici 0) := by
    have h := gaussianReal_map_neg (μ := (0 : ℝ)) (v := 1)
    rw [neg_zero] at h
    conv_lhs => rw [← h]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1
    ext x; simp
  have hu := measureReal_union_add_inter (μ := gaussianReal 0 1) (s := Set.Iic (0 : ℝ))
    (measurableSet_Ici (a := (0 : ℝ)))
  rw [Set.Iic_union_Ici, Set.Iic_inter_Ici, Set.Icc_self, h0,
    probReal_univ] at hu
  linarith

/-- The same fact for the weight at or above zero. -/
lemma gaussianReal_std_Ici_zero : (gaussianReal 0 1).real (Set.Ici (0 : ℝ)) = 1 / 2 := by
  have hsym : (gaussianReal 0 1).real (Set.Iic (0 : ℝ)) = (gaussianReal 0 1).real (Set.Ici 0) := by
    have h := gaussianReal_map_neg (μ := (0 : ℝ)) (v := 1)
    rw [neg_zero] at h
    conv_lhs => rw [← h]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1
    ext x; simp
  rw [← hsym, gaussianReal_std_Iic_zero]

#print axioms gaussianReal_std_Iic_zero
#print axioms gaussianReal_std_Ici_zero

/-- The card's main claim: a price under the model is today's price times a random multiplier.
The price is always positive, and the logarithm of the multiplier is a bell curve centred on the
log drift `(mu - sigma^2/2) * T`, with variance `sigma^2 * T`. -/
theorem log_growth_is_normal {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P)
    (S₀ μ σ T : ℝ) (hS₀ : 0 < S₀) (hT : 0 ≤ T) :
    (∀ ω, 0 < S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω)) ∧
      HasLaw (fun ω => log (S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω) / S₀))
        (gaussianReal ((μ - σ ^ 2 / 2) * T) (σ ^ 2 * T).toNNReal) P := by
  refine ⟨fun ω => by positivity, ?_⟩
  have h1 := gaussianReal_const_add (gaussianReal_const_mul hZ (σ * √T)) ((μ - σ ^ 2 / 2) * T)
  have hfun : (fun ω => log (S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω) / S₀))
      = fun ω => (μ - σ ^ 2 / 2) * T + σ * √T * Z ω := by
    funext ω
    rw [mul_div_cancel_left₀ _ hS₀.ne', log_exp]
  have hlaw : gaussianReal (σ * √T * 0 + (μ - σ ^ 2 / 2) * T)
      (⟨(σ * √T) ^ 2, sq_nonneg _⟩ * 1) = gaussianReal ((μ - σ ^ 2 / 2) * T) (σ ^ 2 * T).toNNReal := by
    congr 1
    · ring
    · apply NNReal.eq
      rw [Real.coe_toNNReal _ (mul_nonneg (sq_nonneg σ) hT)]
      show (σ * √T) ^ 2 * 1 = σ ^ 2 * T
      rw [mul_one, mul_pow, sq_sqrt hT]
  rw [hfun, ← hlaw]
  exact h1

/-- The average outcome: the price's average is `S_0 * e^(mu T)`. The drift is the growth rate of
the average, because the lift `e^(sigma^2 T / 2)` cancels the half-variance in the centre. -/
theorem average_price_eq {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P)
    (S₀ μ σ T : ℝ) (hS₀ : 0 < S₀) (hT : 0 ≤ T) :
    ∫ ω, S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω) ∂P = S₀ * exp (μ * T) := by
  have hm := mgf_gaussianReal hZ (σ * √T)
  simp only [mgf] at hm
  have hsplit : (fun ω => S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω))
      = fun ω => (S₀ * exp ((μ - σ ^ 2 / 2) * T)) * exp (σ * √T * Z ω) := by
    funext ω
    rw [exp_add]; ring
  rw [hsplit, integral_const_mul, hm, mul_assoc, ← exp_add]
  congr 2
  rw [mul_pow, sq_sqrt hT]
  push_cast
  ring

/-- The middle outcome: half the weight ends at or below `S_0 * e^((mu - sigma^2/2) T)` and half at
or above it. This needs a real random kick, so the volatility and the horizon are positive
(with no volatility the price is a fixed number and all the weight sits on it). -/
theorem middle_price_splits_weight {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P)
    (S₀ μ σ T : ℝ) (hS₀ : 0 < S₀) (hσ : 0 < σ) (hT : 0 < T) :
    P.real {ω | S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω) ≤ S₀ * exp ((μ - σ ^ 2 / 2) * T)}
        = 1 / 2 ∧
      P.real {ω | S₀ * exp ((μ - σ ^ 2 / 2) * T) ≤ S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω)}
        = 1 / 2 := by
  have hc : 0 < σ * √T := mul_pos hσ (sqrt_pos.mpr hT)
  constructor
  · have hset : {ω | S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω) ≤ S₀ * exp ((μ - σ ^ 2 / 2) * T)}
        = {ω | Z ω ≤ 0} := by
      ext ω
      simp only [Set.mem_ofPred_eq]
      rw [mul_le_mul_iff_right₀ hS₀, exp_le_exp]
      constructor
      · intro h; nlinarith
      · intro h; nlinarith
    rw [hset, hZ.measureReal_eq (p := fun x => x ≤ 0) measurableSet_Iic]
    exact gaussianReal_std_Iic_zero
  · have hset : {ω | S₀ * exp ((μ - σ ^ 2 / 2) * T) ≤ S₀ * exp ((μ - σ ^ 2 / 2) * T + σ * √T * Z ω)}
        = {ω | 0 ≤ Z ω} := by
      ext ω
      simp only [Set.mem_ofPred_eq]
      rw [mul_le_mul_iff_right₀ hS₀, exp_le_exp]
      constructor
      · intro h; nlinarith
      · intro h; nlinarith
    rw [hset, hZ.measureReal_eq (p := fun x => 0 ≤ x) measurableSet_Ici]
    exact gaussianReal_std_Ici_zero

/-! The card's exact worked arithmetic for Acme: drift 5% = 1/20, volatility 20% = 1/5, one year. -/

-- A rise of 20% then a fall of 20% on 100 dollars leaves 96 dollars.
example : (100 : ℚ) * (1 + 1 / 5) * (1 - 1 / 5) = 96 := by norm_num

-- For any x, (1 + x)(1 - x) = 1 - x^2: the pair of moves loses the square of the move.
example : ∀ x : ℚ, (1 + x) * (1 - x) = 1 - x ^ 2 := by intro x; ring

-- Half the variance: 1/2 * (1/5)^2 = 1/50, that is 2% a year.
example : (1 / 2 : ℚ) * (1 / 5) ^ 2 = 1 / 50 := by norm_num

-- The log drift: 5% less half the variance is 3% a year.
example : (1 / 20 : ℚ) - (1 / 5) ^ 2 / 2 = 3 / 100 := by norm_num

-- Average over middle is e^(sigma^2 T / 2): the exponents differ by 2% a year.
example : (1 / 20 : ℚ) - ((1 / 20) - (1 / 5) ^ 2 / 2) = 1 / 50 := by norm_num

-- The peak of the density sits at exponent mu - 3 sigma^2 / 2 = 5% - 6% = -1% a year.
example : (1 / 20 : ℚ) - 3 * (1 / 5) ^ 2 / 2 = -1 / 100 := by norm_num

-- The log spread at one year: sigma * sqrt 1 = 1/5.
example : (1 / 5 : ℝ) * √1 = 1 / 5 := by norm_num

-- Four years has twice the spread of one year: sqrt 4 = 2 * sqrt 1.
example : √(4 : ℝ) = 2 * √1 := by norm_num

-- The shelf's market: the pricing drift r - q = 5% - 2% is 3%, the same as this card's log drift,
-- because half of Acme's variance equals its 2% dividend yield.
example : (1 / 20 : ℚ) - 1 / 50 = (1 / 20) - (1 / 5) ^ 2 / 2 := by norm_num

#print axioms log_growth_is_normal
#print axioms average_price_eq
#print axioms middle_price_splits_weight
