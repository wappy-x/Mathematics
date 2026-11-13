-- Bayes' rule: for causes that do not overlap and cover every case, the chance of a cause given the evidence is its share of the total chance of the evidence, and in odds form the evidence multiplies the odds by the likelihood ratio.
import Mathlib.Probability.ConditionalProbability
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- Helper: in `ℝ≥0∞`, `(a * c) / (b * d) = (a / b) * (c / d)` when `b` and `d` are nonzero. -/
theorem ennreal_div_mul_div {a b c d : ENNReal} (hb : b ≠ 0) (hd : d ≠ 0) :
    a * c / (b * d) = a / b * (c / d) := by
  rw [div_eq_mul_inv, div_eq_mul_inv, div_eq_mul_inv, ENNReal.mul_inv (Or.inl hb) (Or.inr hd)]
  ring

#print axioms ennreal_div_mul_div

/-- Bayes' rule, general form. Let `H 0, …, H (n-1)` be events that do not overlap, cover every
case, and each have positive chance, and let `E` be evidence with positive chance. Then the chance
of each `H i` given `E` is `P(E | H i) P(H i)` divided by the total `∑ j, P(E | H j) P(H j)`,
and these answers add up to 1. -/
theorem bayes_rule {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    {n : ℕ} (H : Fin n → Set Ω) (E : Set Ω)
    (hH : ∀ i, MeasurableSet (H i)) (hE : MeasurableSet E)
    (hdisj : Pairwise (Function.onFun Disjoint H)) (hcover : ⋃ i, H i = Set.univ)
    (hHpos : ∀ i, μ (H i) ≠ 0) (hEpos : μ E ≠ 0) :
    (∀ i, μ[H i | E] = μ[E | H i] * μ (H i) / ∑ j, μ[E | H j] * μ (H j)) ∧
      ∑ i, μ[H i | E] = 1 := by
  have key : ∀ j, μ[E | H j] * μ (H j) = μ (H j ∩ E) := fun j => cond_mul_eq_inter (hH j) E μ
  have hsum : ∑ j, μ (H j ∩ E) = μ E := by
    have h := measure_iUnion (μ := μ) (f := fun j => H j ∩ E)
      (fun i j hij => (hdisj hij).mono Set.inter_subset_left Set.inter_subset_left)
      (fun j => (hH j).inter hE)
    rw [tsum_fintype] at h
    rw [← h, ← Set.iUnion_inter, hcover, Set.univ_inter]
  have hc : ∀ i, μ[H i | E] = (μ E)⁻¹ * μ (H i ∩ E) := by
    intro i; rw [cond_apply hE, Set.inter_comm]
  simp_rw [key, hsum]
  refine ⟨fun i => ?_, ?_⟩
  · rw [hc, div_eq_mul_inv, mul_comm]
  · simp_rw [hc]
    rw [← Finset.mul_sum, hsum, ENNReal.inv_mul_cancel hEpos (measure_ne_top _ _)]

/-- Bayes' rule, odds form. If the claim `H` and its failure `Hᶜ` both have positive chance, the
evidence `E` has positive chance, and `P(E | Hᶜ) > 0`, then the odds of `H` after the evidence
equal the likelihood ratio `P(E | H) / P(E | Hᶜ)` times the odds of `H` before it. -/
theorem bayes_rule_odds_form {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (H E : Set Ω) (hH : MeasurableSet H) (hE : MeasurableSet E)
    (hHpos : μ H ≠ 0) (hHcpos : μ Hᶜ ≠ 0) (hEpos : μ E ≠ 0) (hL : μ[E | Hᶜ] ≠ 0) :
    μ[H | E] / μ[Hᶜ | E] = (μ[E | H] / μ[E | Hᶜ]) * (μ H / μ Hᶜ) := by
  have h1 : μ[H | E] = (μ E)⁻¹ * μ (E ∩ H) := cond_apply hE μ H
  have h2 : μ[Hᶜ | E] = (μ E)⁻¹ * μ (E ∩ Hᶜ) := cond_apply hE μ Hᶜ
  have h3 : μ[E | H] * μ H = μ (H ∩ E) := cond_mul_eq_inter hH E μ
  have h4 : μ[E | Hᶜ] * μ Hᶜ = μ (Hᶜ ∩ E) := cond_mul_eq_inter hH.compl E μ
  rw [h1, h2, ENNReal.mul_div_mul_left _ _ (ENNReal.inv_ne_zero.2 (measure_ne_top _ _))
    (ENNReal.inv_ne_top.2 hEpos), ← ennreal_div_mul_div hL hHcpos, h3, h4,
    Set.inter_comm E H, Set.inter_comm E Hᶜ]

/-- A second result multiplies the odds again, if it is fresh evidence. If two results `E₁` and
`E₂` are independent given the true state (given `H` and given `Hᶜ`), then the odds of `H` after
both equal the second likelihood ratio `P(E₂ | H) / P(E₂ | Hᶜ)` times the odds after the first. -/
theorem bayes_rule_second_independent_result {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (H E₁ E₂ : Set Ω) (hH : MeasurableSet H)
    (hE₁ : MeasurableSet E₁) (hE₂ : MeasurableSet E₂)
    (hHpos : μ H ≠ 0) (hHcpos : μ Hᶜ ≠ 0) (hEpos : μ (E₁ ∩ E₂) ≠ 0)
    (hL₁ : μ[E₁ | Hᶜ] ≠ 0) (hL₂ : μ[E₂ | Hᶜ] ≠ 0)
    (hind : μ[E₁ ∩ E₂ | H] = μ[E₁ | H] * μ[E₂ | H])
    (hindc : μ[E₁ ∩ E₂ | Hᶜ] = μ[E₁ | Hᶜ] * μ[E₂ | Hᶜ]) :
    μ[H | E₁ ∩ E₂] / μ[Hᶜ | E₁ ∩ E₂] =
      (μ[E₂ | H] / μ[E₂ | Hᶜ]) * (μ[H | E₁] / μ[Hᶜ | E₁]) := by
  have hE₁pos : μ E₁ ≠ 0 := fun h => hEpos (measure_mono_null Set.inter_subset_left h)
  have hL : μ[E₁ ∩ E₂ | Hᶜ] ≠ 0 := by rw [hindc]; exact mul_ne_zero hL₁ hL₂
  rw [bayes_rule_odds_form μ H (E₁ ∩ E₂) hH (hE₁.inter hE₂) hHpos hHcpos hEpos hL,
    bayes_rule_odds_form μ H E₁ hH hE₁ hHpos hHcpos hE₁pos hL₁, hind, hindc,
    ennreal_div_mul_div hL₁ hL₂]
  ring

/-! The card's worked numbers, as exact fractions. -/

-- The tree: of 10,000 people, 100 carry it and 99 of them test positive;
-- 9,900 are clear and 99 of them test positive; 99 of the 198 positives carry it.
example : 10000 / 100 = 100 ∧ 100 * 99 / 100 = 99 ∧ (10000 - 100) / 100 = 99 ∧ 99 + 99 = 198 := by
  decide

-- P(E) = 0.99 × 0.01 + 0.01 × 0.99 = 0.0198.
example : (99 / 100 : ℚ) * (1 / 100) + (1 / 100) * (99 / 100) = 198 / 10000 := by norm_num

-- P(H | E) = 0.0099 / 0.0198 = 1/2.
example : ((99 / 100 : ℚ) * (1 / 100)) / ((99 / 100) * (1 / 100) + (1 / 100) * (99 / 100))
    = 1 / 2 := by norm_num

-- Odds form: L = 99, odds before 1 to 99, odds after 1 to 1, chance 1 / (1 + 1) = 1/2.
example : (99 / 100 : ℚ) / (1 / 100) = 99 ∧ (99 : ℚ) * (1 / 99) = 1 ∧ (1 : ℚ) / (1 + 1) = 1 / 2 := by
  norm_num

-- Base rate 2 percent: 99/148 (0.668919). Base rate 10 percent: 11/12 (91.67 percent).
example : ((99 / 100 : ℚ) * (2 / 100)) / ((99 / 100) * (2 / 100) + (1 / 100) * (98 / 100))
    = 99 / 148 := by norm_num
example : ((99 / 100 : ℚ) * (10 / 100)) / ((99 / 100) * (10 / 100) + (1 / 100) * (90 / 100))
    = 11 / 12 := by norm_num

-- A second independent positive: odds 1 × 99 = 99, chance 99/100; the count gives 9,801 of 9,900.
example : (99 : ℚ) / (1 + 99) = 99 / 100 ∧ (9801 : ℚ) / 9900 = 99 / 100 := by norm_num

-- Two dice: three of the 36 outcomes total 10, and one of those has a first-die 6.
example : (Finset.univ.filter (fun p : Fin 6 × Fin 6 => p.1.val + p.2.val + 2 = 10)).card = 3 := by
  decide
example : (Finset.univ.filter
    (fun p : Fin 6 × Fin 6 => p.1.val + p.2.val + 2 = 10 ∧ p.1.val + 1 = 6)).card = 1 := by
  decide

-- Bayes on the dice: (1/6)(1/6) / (3/36) = 1/3.
example : ((1 / 6 : ℚ) * (1 / 6)) / (3 / 36) = 1 / 3 := by norm_num

#print axioms bayes_rule
#print axioms bayes_rule_odds_form
#print axioms bayes_rule_second_independent_result
