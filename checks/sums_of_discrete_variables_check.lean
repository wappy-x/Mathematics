-- Adding counts: the chance that two independent whole-number counts add to s is the sum over every split of the product of chances, and independent Poisson counts, or binomial counts with one shared chance of success, add to a count of the same family.
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Probability.Distributions.Binomial
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum

/-! A random count is a measurable function `X : Ω → ℕ` on a probability space `(Ω, P)`.
`P {ω | X ω = k}` is the chance `P(X = k)`. "Independent" is Mathlib's `IndepFun X Y P`.
"`X` follows the Poisson law with average `r`" is `HasLaw X (poissonMeasure r) P`, where
`poissonMeasure r` gives `{k}` the mass `exp (-r) * r ^ k / k!`.
"`X` follows the binomial law with `n` tries and chance `p`" is `HasLaw X (binomial n p) P`,
where `binomial n p` gives `{k}` the mass `C(n, k) * p ^ k * (1 - p) ^ (n - k)`. -/

open MeasureTheory ProbabilityTheory
open scoped NNReal unitInterval

theorem conv_singleton_nat (μ ν : Measure ℕ) [SFinite μ] [SFinite ν] (s : ℕ) :
    (μ ∗ ν) {s} = ∑ k ∈ Finset.range (s + 1), μ {k} * ν {s - k} := by
  rw [Measure.conv, Measure.map_apply measurable_add (measurableSet_singleton s)]
  have hpre : (fun p : ℕ × ℕ => p.1 + p.2) ⁻¹' {s} =
      ((Finset.antidiagonal s : Finset (ℕ × ℕ)) : Set (ℕ × ℕ)) := by
    ext p; simp
  rw [hpre, ← sum_measure_singleton]
  rw [← Finset.Nat.sum_antidiagonal_eq_sum_range_succ (fun a b => μ {a} * ν {b})]
  refine Finset.sum_congr rfl fun p _ => ?_
  rw [← Set.singleton_prod_singleton, Measure.prod_prod]

#print axioms conv_singleton_nat

theorem binomial_real_identity (n m s : ℕ) (p : I) :
    ∑ k ∈ Finset.range (s + 1),
      ((n.choose k : ℝ) * (p : ℝ) ^ k * (1 - (p : ℝ)) ^ (n - k)) *
        ((m.choose (s - k) : ℝ) * (p : ℝ) ^ (s - k) * (1 - (p : ℝ)) ^ (m - (s - k))) =
      ((n + m).choose s : ℝ) * (p : ℝ) ^ s * (1 - (p : ℝ)) ^ (n + m - s) := by
  have hterm : ∀ k ∈ Finset.range (s + 1),
      ((n.choose k : ℝ) * (p : ℝ) ^ k * (1 - (p : ℝ)) ^ (n - k)) *
        ((m.choose (s - k) : ℝ) * (p : ℝ) ^ (s - k) * (1 - (p : ℝ)) ^ (m - (s - k))) =
      ((n.choose k * m.choose (s - k) : ℕ) : ℝ) * ((p : ℝ) ^ s * (1 - (p : ℝ)) ^ (n + m - s)) := by
    intro k hk
    rw [Finset.mem_range] at hk
    by_cases h : k ≤ n ∧ s - k ≤ m
    · have e1 : (p : ℝ) ^ s = (p : ℝ) ^ k * (p : ℝ) ^ (s - k) := by
        rw [← pow_add]; congr 1; omega
      have e2 : (1 - (p : ℝ)) ^ (n + m - s) =
          (1 - (p : ℝ)) ^ (n - k) * (1 - (p : ℝ)) ^ (m - (s - k)) := by
        rw [← pow_add]; congr 1; omega
      rw [e1, e2]; push_cast; ring
    · rcases not_and_or.mp h with h | h
      · rw [Nat.choose_eq_zero_of_lt (by omega)]; simp
      · rw [Nat.choose_eq_zero_of_lt (n := m) (by omega)]; simp
  rw [Finset.sum_congr rfl hterm, ← Finset.sum_mul, ← Nat.cast_sum,
    ← Finset.Nat.sum_antidiagonal_eq_sum_range_succ (fun a b => n.choose a * m.choose b),
    ← Nat.add_choose_eq]
  ring

#print axioms binomial_real_identity

theorem binomial_conv_binomial (n m : ℕ) (p : I) :
    binomial n p ∗ binomial m p = binomial (n + m) p := by
  refine Measure.ext_of_singleton fun s => ?_
  rw [conv_singleton_nat, binomial_singleton]
  simp_rw [binomial_singleton]
  rw [← binomial_real_identity, ENNReal.ofReal_sum_of_nonneg]
  · refine Finset.sum_congr rfl fun k _ => ?_
    rw [ENNReal.ofReal_mul binomial_nonneg]
  · intro k _
    exact mul_nonneg binomial_nonneg binomial_nonneg

#print axioms binomial_conv_binomial

/-- Convolution: for two independent whole-number counts `X` and `Y`, the chance that
`X + Y = s` is the sum, over every split `k = 0, 1, …, s`, of `P(X = k) * P(Y = s - k)`. -/
theorem prob_sum_eq_convolution {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X Y : Ω → ℕ) (hX : Measurable X) (hY : Measurable Y)
    (hXY : IndepFun X Y P) (s : ℕ) :
    P {ω | X ω + Y ω = s} =
      ∑ k ∈ Finset.range (s + 1), P {ω | X ω = k} * P {ω | Y ω = s - k} := by
  have h1 : P {ω | X ω + Y ω = s} = P.map (X + Y) {s} := by
    rw [Measure.map_apply (hX.add hY) (measurableSet_singleton s)]; rfl
  rw [h1, hXY.map_add_eq_map_conv_map hX hY, conv_singleton_nat]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [Measure.map_apply hX (measurableSet_singleton _),
    Measure.map_apply hY (measurableSet_singleton _)]
  rfl

/-- Poisson closure: independent Poisson counts with averages `λ` and `μ` add to a
Poisson count with average `λ + μ`. -/
theorem poisson_add_poisson_is_poisson {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X Y : Ω → ℕ) (lam mu : ℝ≥0)
    (hX : HasLaw X (poissonMeasure lam) P) (hY : HasLaw Y (poissonMeasure mu) P)
    (hXY : IndepFun X Y P) :
    HasLaw (fun ω => X ω + Y ω) (poissonMeasure (lam + mu)) P := by
  exact hXY.hasLaw_add_poissonMeasure hX hY

/-- Binomial closure: independent binomial counts with `n` and `m` tries and the same
chance of success `p` add to a binomial count with `n + m` tries and chance `p`. -/
theorem binomial_add_binomial_is_binomial {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X Y : Ω → ℕ) (n m : ℕ) (p : I)
    (hX : HasLaw X (binomial n p) P) (hY : HasLaw Y (binomial m p) P)
    (hXY : IndepFun X Y P) :
    HasLaw (fun ω => X ω + Y ω) (binomial (n + m) p) P := by
  rw [← binomial_conv_binomial]
  exact hXY.hasLaw_add hX hY

/-! The card's whole-number worked examples. -/

-- The merged inbox: billing averages 5, technical 7, so the merged average is 12.
example : (5 : ℕ) + 7 = 12 := by norm_num
-- Step 2 at the help desks (s = 12, averages 5 and 7): the binomial theorem that turns the
-- thirteen-split convolution into the Poisson mass with rate 12.
example : ∑ k ∈ Finset.range 13, Nat.choose 12 k * 5 ^ k * 7 ^ (12 - k) = 12 ^ 12 := by decide
-- Monday's 20 replies and Tuesday's 30: Vandermonde's count at s = 35 resolved,
-- the count behind "0.122347 by convolution and from the binomial law with 50 tries".
example : ∑ k ∈ Finset.range 36, Nat.choose 20 k * Nat.choose 30 (35 - k) = Nat.choose 50 35 := by
  simp [Finset.sum_range_succ, Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial,
    Nat.factorial]
-- Copied emails: A, B, C average 3, 5, 2; the merged count A + B + 2C has variance 16, not 12.
example : (3 : ℕ) + 5 + 4 * 2 = 16 ∧ (3 : ℕ) + 5 + 2 * 2 = 12 := by norm_num
-- Two dice add to a triangle, not a die: 6 ways to make 7, only 1 way to make 2.
example : ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun q : ℕ × ℕ => q.1 + q.2 = 7)).card = 6 := by
  decide
example : ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun q : ℕ × ℕ => q.1 + q.2 = 2)).card = 1 := by
  decide

#print axioms prob_sum_eq_convolution
#print axioms poisson_add_poisson_is_poisson
#print axioms binomial_add_binomial_is_binomial
