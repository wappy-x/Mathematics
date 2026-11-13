-- Independence as a product: two real random variables on a probability space are independent exactly when the law of the pair is the product of their two laws, and then the average of their product is the product of their averages and the variance of their sum is the sum of their variances.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.Probability.Moments.Variance
import Mathlib.MeasureTheory.Measure.Prod
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- Theorem 2, the joint law is a product. On a probability space `(Ω, F, P)`, two real
random variables `X` and `Y` (measurable maps to the line) are independent, meaning
`P(X ∈ A, Y ∈ B) = P(X ∈ A) P(Y ∈ B)` for all Borel sets `A` and `B`, exactly when the
joint law of the pair `(X, Y)` on the plane equals the product measure `μ_X ⊗ μ_Y` of
their separate laws. -/
theorem indep_iff_joint_law_eq_product_of_laws
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    {X Y : Ω → ℝ} (hX : Measurable X) (hY : Measurable Y) :
    IndepFun X Y P ↔ P.map (fun ω => (X ω, Y ω)) = (P.map X).prod (P.map Y) := by
  exact indepFun_iff_map_prod_eq_prod_map_map hX.aemeasurable hY.aemeasurable

/-- Theorem 3, products. If `X` and `Y` are independent real random variables and each has
a finite average of its absolute value, then their product `XY` also has a finite average,
and `E[XY] = E[X] E[Y]`. -/
theorem integral_mul_eq_mul_integral_of_indep
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    {X Y : Ω → ℝ} (hXY : IndepFun X Y P) (hX : Integrable X P) (hY : Integrable Y P) :
    Integrable (X * Y) P ∧ ∫ ω, (X * Y) ω ∂P = (∫ ω, X ω ∂P) * (∫ ω, Y ω ∂P) := by
  exact ⟨hXY.integrable_mul hX hY,
    hXY.integral_mul_eq_mul_integral hX.aestronglyMeasurable hY.aestronglyMeasurable⟩

/-- Theorem 3, sums. If `X` and `Y` are independent real random variables and each has a
finite average square, then `Var(X + Y) = Var(X) + Var(Y)`. -/
theorem variance_add_of_indep
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    {X Y : Ω → ℝ} (hXY : IndepFun X Y P) (hX : MemLp X 2 P) (hY : MemLp Y 2 P) :
    variance (X + Y) P = variance X P + variance Y P := by
  exact hXY.variance_add hX hY

/-! The card's worked numbers, exactly. -/

-- The dart: E[x] = ∫₀¹ x dx = 1/2 and E[x^2] = ∫₀¹ x^2 dx = 1/3.
example : ∫ x in (0 : ℝ)..1, x = 1 / 2 := by norm_num [integral_id]
example : ∫ x in (0 : ℝ)..1, x ^ 2 = 1 / 3 := by norm_num [integral_pow]

-- Var(x) = 1/3 - (1/2)^2 = 1/12; Var(x + y) = 1/12 + 1/12 = 1/6; E[xy] = 1/2 × 1/2 = 1/4.
example : (1 : ℚ) / 3 - (1 / 2) ^ 2 = 1 / 12 ∧ (1 : ℚ) / 12 + 1 / 12 = 1 / 6 ∧
    (1 / 2 : ℚ) * (1 / 2) = 1 / 4 := by norm_num

-- The pair (x, x + y): the triangle x + y ≤ 1/2 has area 1/2 × 1/2 / 2 = 1/8, against the
-- product 1/2 × 1/8 = 1/16; E[x(x + y)] = 1/3 + 1/4 = 7/12, not 1/2 × 1 = 1/2; gap 1/12.
example : (1 / 2 : ℚ) * (1 / 2) / 2 = 1 / 8 ∧ (1 / 2 : ℚ) * (1 / 8) = 1 / 16 ∧
    (1 / 8 : ℚ) ≠ 1 / 16 ∧ (1 : ℚ) / 3 + 1 / 4 = 7 / 12 ∧ (7 / 12 : ℚ) ≠ 1 / 2 * 1 ∧
    (7 : ℚ) / 12 - 1 / 2 = 1 / 12 := by norm_num

-- Var(x + x) read as Var(x) + Var(x) gives 1/6; the true Var(2x) = 4 × 1/12 = 1/3.
example : (4 : ℚ) * (1 / 12) = 1 / 3 ∧ (1 / 6 : ℚ) ≠ 1 / 3 := by norm_num

-- Step 1, quarters of the board (column, row in {0, 1}, chance 1/4 each). L = left half,
-- B = bottom half, C = bottom-left or top-right. L ∩ C and B ∩ C each hold 1 quarter
-- (1/4 = 1/2 × 1/2), but L ∩ B ∩ C holds 1 quarter (1/4), not 1/8 = 1/4 × 1/2.
example :
    ((Finset.range 2 ×ˢ Finset.range 2).filter (fun c => c.1 = 0 ∧ c.1 = c.2)).card = 1 ∧
    ((Finset.range 2 ×ˢ Finset.range 2).filter (fun c => c.2 = 0 ∧ c.1 = c.2)).card = 1 ∧
    ((Finset.range 2 ×ˢ Finset.range 2).filter
      (fun c => c.1 = 0 ∧ c.2 = 0 ∧ c.1 = c.2)).card = 1 := by decide
example : (1 : ℚ) / 4 = (1 / 2) * (1 / 2) ∧ (1 : ℚ) / 4 ≠ (1 / 4) * (1 / 2) := by norm_num

-- Step 1, the 4 by 4 grid, recorded as (column, row): all 16 × 16 = 256 pairs of events
-- multiply. An event is a set of values, coded as a bit mask; 16 × (cells in both) must
-- equal (cells in the first) × (cells in the second).
example : ((Finset.range 16 ×ˢ Finset.range 16).filter (fun p =>
    16 * ((Finset.range 4 ×ˢ Finset.range 4).filter
      (fun c => p.1.testBit c.1 ∧ p.2.testBit c.2)).card =
    ((Finset.range 4 ×ˢ Finset.range 4).filter (fun c => p.1.testBit c.1)).card *
    ((Finset.range 4 ×ˢ Finset.range 4).filter (fun c => p.2.testBit c.2)).card)).card
    = 256 := by decide +kernel

-- Step 1, the grid recorded as (column, column + row): of the 16 × 128 = 2048 pairs of
-- events, 696 multiply.
example : ((Finset.range 16 ×ˢ Finset.range 128).filter (fun p =>
    16 * ((Finset.range 4 ×ˢ Finset.range 4).filter
      (fun c => p.1.testBit c.1 ∧ p.2.testBit (c.1 + c.2))).card =
    ((Finset.range 4 ×ˢ Finset.range 4).filter (fun c => p.1.testBit c.1)).card *
    ((Finset.range 4 ×ˢ Finset.range 4).filter (fun c => p.2.testBit (c.1 + c.2))).card)).card
    = 696 := by decide +kernel

-- When it holds: on that grid, the rays "column ≤ s" (s = 0..3) and "column + row ≤ t"
-- (t = 0..6) give 28 ray pairs, of which 10 multiply.
example : ((Finset.range 4 ×ˢ Finset.range 7).filter (fun p =>
    16 * ((Finset.range 4 ×ˢ Finset.range 4).filter
      (fun c => c.1 ≤ p.1 ∧ c.1 + c.2 ≤ p.2)).card =
    ((Finset.range 4 ×ˢ Finset.range 4).filter (fun c => c.1 ≤ p.1)).card *
    ((Finset.range 4 ×ˢ Finset.range 4).filter (fun c => c.1 + c.2 ≤ p.2)).card)).card
    = 10 := by decide

-- One failing pair: column 0 has 4 of 16 cells, sum 0 has 1, both have 1, not 4/256.
example : (1 : ℚ) / 16 ≠ (4 / 16) * (1 / 16) := by norm_num

-- Zero covariance is not independence: u = x - 1/2 ≤ -1/4 and w = u^2 ≤ 1/16 cannot
-- both hold (chance 0), while the product of chances is 1/4 × 1/2 = 1/8.
example : (1 / 4 : ℚ) * (1 / 2) = 1 / 8 ∧ (0 : ℚ) ≠ 1 / 8 := by norm_num

#print axioms indep_iff_joint_law_eq_product_of_laws
#print axioms integral_mul_eq_mul_integral_of_indep
#print axioms variance_add_of_indep
