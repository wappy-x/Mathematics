-- Expectation: the expectation of a sum aX + bY is aE[X] + bE[Y] whenever X and Y have finite expectations, with no independence assumed, and for a random variable with finitely many values the expectation is each value times its chance, added up.
import Mathlib.Probability.Notation
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- Linearity of expectation: for any two random variables `X` and `Y` on the same
chance experiment, each with a finite expectation, and any fixed numbers `a` and `b`,
the expectation of `aX + bY` is `a E[X] + b E[Y]`. Nothing is assumed about how `X`
and `Y` depend on each other. -/
theorem expectation_linear {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {X Y : Ω → ℝ} (hX : Integrable X P) (hY : Integrable Y P)
    (a b : ℝ) :
    ∫ ω, (a * X ω + b * Y ω) ∂P = a * ∫ ω, X ω ∂P + b * ∫ ω, Y ω ∂P := by
  rw [integral_add (hX.const_mul a) (hY.const_mul b), integral_const_mul, integral_const_mul]

/-- The formula: a random variable `X` that takes only finitely many values always has
an expectation, and it is each value `x` times its chance `P(X = x)`, added up. -/
theorem expectation_eq_weighted_sum {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {X : Ω → ℝ} (hX : Measurable X) (hfin : (Set.range X).Finite) :
    Integrable X P ∧ ∫ ω, X ω ∂P = ∑ x ∈ hfin.toFinset, x * P.real (X ⁻¹' {x}) := by
  classical
  let f : SimpleFunc Ω ℝ := ⟨X, fun x => hX (measurableSet_singleton x), hfin⟩
  have hfi : Integrable X P := f.integrable_of_isFiniteMeasure
  refine ⟨hfi, ?_⟩
  have h1 : ∫ ω, X ω ∂P = f.integral P := (SimpleFunc.integral_eq_integral f hfi).symm
  rw [h1, SimpleFunc.integral_eq_sum_of_subset (s := hfin.toFinset)]
  · simp only [smul_eq_mul, mul_comm]; rfl
  · intro x hx
    simp only [Finset.mem_filter, SimpleFunc.mem_range] at hx
    simpa [f] using hx.1

/-- An indicator's expectation is a chance: the number that is 1 when the event `W`
happens and 0 when it does not has expectation `P(W)`. -/
theorem expectation_indicator_eq_prob {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {W : Set Ω} (hW : MeasurableSet W) :
    ∫ ω, W.indicator 1 ω ∂P = P.real W := by
  exact integral_indicator_one hW

/-! The raffle: 100 tickets at $2, one drawn, the winner paid $100. Our ticket is
number 0. Chances are written as fractions of 100, so no decimals appear. -/

-- E[X] as a weighted sum: 0 × 99/100 + 100 × 1/100 = 1.
example : (0 : ℚ) * (99 / 100) + 100 * (1 / 100) = 1 := by norm_num

-- E[X] by counting all 100 draws: one draw pays 100, a total of 100 over 100 draws.
example : (∑ w : Fin 100, (if w.val = 0 then 100 else 0) : ℕ) = 100 := by decide

-- Net gain per ticket: E[X - 2] = 1 - 2 = -1.
example : (0 - 2 : ℚ) * (99 / 100) + (100 - 2) * (1 / 100) = -1 := by norm_num

-- The organiser takes 100 × $2, pays $100, keeps $100.
example : 100 * 2 - 100 = 100 := by norm_num

-- Five tickets in one draw: 5 × E[X] = 5, and counting the draws agrees (500 / 100).
example : (∑ w : Fin 100, (if w.val < 5 then 100 else 0) : ℕ) = 500 := by decide
example : (5 : ℚ) * 1 = 500 / 100 := by norm_num

-- None of the five wins in 95 of the 100 draws.
example : ((Finset.univ : Finset (Fin 100)).filter (fun w => 5 ≤ w.val)).card = 95 := by decide

-- Five tickets in five separate raffles: E[T] = 100 × (expected number of wins) = 5,
-- summed over all 32 win/lose patterns with chances (1/100)^k (99/100)^(5-k).
example : (∑ k ∈ Finset.range 6, (100 : ℚ) * k * (Nat.choose 5 k) * (1 / 100) ^ k * (99 / 100) ^ (5 - k)) = 5 := by
  norm_num [Finset.sum_range_succ, Nat.choose]

-- Two tickets in one draw: both can never win, so E[X1 X2] = 0, not E[X1] E[X2] = 1.
example : (∑ w : Fin 100, (if w.val = 0 then 100 else 0) * (if w.val = 1 then 100 else 0) : ℕ) = 0 := by
  decide

-- E[X^2] = 0^2 × 99/100 + 100^2 × 1/100 = 100, while E[X]^2 = 1.
example : (0 : ℚ) ^ 2 * (99 / 100) + 100 ^ 2 * (1 / 100) = 100 := by norm_num

-- Tail sum: the payout exceeds each level t = 0, ..., 99 with chance 1/100; adding gives 1.
example : (∑ _t ∈ Finset.range 100, (1 : ℚ) / 100) = 1 := by norm_num

-- St Petersburg: 2^j × (1/2)^j = 1 at every level, so 10, 20 and 40 levels give 10, 20, 40.
example : (∑ j ∈ Finset.Icc 1 10, (2 : ℚ) ^ j * (1 / 2) ^ j) = 10 := by
  simp
example : (∑ j ∈ Finset.Icc 1 20, (2 : ℚ) ^ j * (1 / 2) ^ j) = 20 := by
  simp
example : (∑ j ∈ Finset.Icc 1 40, (2 : ℚ) ^ j * (1 / 2) ^ j) = 40 := by
  simp

#print axioms expectation_linear
#print axioms expectation_eq_weighted_sum
#print axioms expectation_indicator_eq_prob
