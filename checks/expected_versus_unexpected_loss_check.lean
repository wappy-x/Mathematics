-- Expected and unexpected loss: the expected loss of a loan book is the sum of PD × LGD × EAD over its loans whatever the defaults do together, and the least capital that survives with chance at least α is the α-quantile of the loss minus the expected loss.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Integral.IntegrableOn

open MeasureTheory

/-- Expected loss adds loan by loan, with no assumption on how defaults move together.
Loan `i` has a default flag `D i` that is 1 if it fails and 0 if not, a fixed loss given
default `LGD i` and a fixed exposure at default `EAD i`. Its loss is `EAD i * LGD i * D i`,
and its probability of default is the chance its flag is 1. Then the average of the book's
loss is the sum over the loans of `PD i * LGD i * EAD i`. -/
theorem expected_loss_eq_sum_pd_lgd_ead
    {Ω ι : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (s : Finset ι) (D : ι → Ω → ℝ) (hD : ∀ i, Measurable (D i))
    (hflag : ∀ i ω, D i ω = 0 ∨ D i ω = 1) (LGD EAD : ι → ℝ) :
    ∫ ω, (∑ i ∈ s, EAD i * LGD i * D i ω) ∂μ
      = ∑ i ∈ s, μ.real {ω | D i ω = 1} * LGD i * EAD i := by
  rw [integral_finsetSum]
  · refine Finset.sum_congr rfl fun i _ => ?_
    have hset : MeasurableSet {ω | D i ω = 1} := hD i (measurableSet_singleton 1)
    have heq : (fun ω => EAD i * LGD i * D i ω)
        = fun ω => EAD i * LGD i * ({ω | D i ω = 1}.indicator 1 ω) := by
      funext ω
      rcases hflag i ω with h | h <;> simp [Set.indicator, h]
    rw [heq, integral_const_mul, integral_indicator_one hset]
    ring
  · intro i _
    refine Integrable.const_mul ?_ _
    refine Integrable.of_bound (hD i).aestronglyMeasurable 1 (Filter.Eventually.of_forall ?_)
    intro ω
    rcases hflag i ω with h | h <;> simp [h]

/-- Capital covers the unexpected loss. Let `L` be the year's loss, `EL` its average and
`q` the `α`-quantile: the smallest `x` with `P(L ≤ x) ≥ α`. For `0 < α < 1`, the smallest
capital `K` with `P(L ≤ EL + K) ≥ α` is exactly `q - EL`, the unexpected loss at level `α`. -/
theorem least_capital_eq_quantile_sub_expected_loss
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (L : Ω → ℝ) (hL : Measurable L) (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) :
    IsLeast {K : ℝ | α ≤ μ.real {ω | L ω ≤ (∫ ω, L ω ∂μ) + K}}
      (sInf {x : ℝ | α ≤ μ.real {ω | L ω ≤ x}} - ∫ ω, L ω ∂μ) := by
  set F : ℝ → ℝ := fun x => μ.real {ω | L ω ≤ x} with hFdef
  have hF : ∀ x, F x = ProbabilityTheory.cdf (μ.map L) x := by
    intro x
    rw [ProbabilityTheory.cdf_eq_real, map_measureReal_apply hL measurableSet_Iic]
    rfl
  have hFmono : Monotone F := by
    intro x y hxy
    rw [hF, hF]
    exact ProbabilityTheory.monotone_cdf _ hxy
  set S : Set ℝ := {x : ℝ | α ≤ F x} with hSdef
  -- S is nonempty
  have hne : S.Nonempty := by
    have h1 : Filter.Tendsto F Filter.atTop (nhds 1) := by
      have := ProbabilityTheory.tendsto_cdf_atTop (μ.map L)
      exact this.congr (fun x => (hF x).symm)
    obtain ⟨x, hx⟩ := (h1.eventually (lt_mem_nhds hα1)).exists
    exact ⟨x, le_of_lt hx⟩
  -- S is bounded below
  have hbdd : BddBelow S := by
    have h0 : Filter.Tendsto F Filter.atBot (nhds 0) := by
      have := ProbabilityTheory.tendsto_cdf_atBot (μ.map L)
      exact this.congr (fun x => (hF x).symm)
    obtain ⟨x0, hx0⟩ := Filter.eventually_atBot.1 (h0.eventually (gt_mem_nhds hα0))
    refine ⟨x0, fun s hs => ?_⟩
    by_contra hlt
    push Not at hlt
    have := hx0 s hlt.le
    exact absurd hs (not_le.2 this)
  -- sInf S ∈ S by right continuity
  have hmem : sInf S ∈ S := by
    set x := sInf S
    have hright : ∀ y, x < y → α ≤ F y := by
      intro y hy
      obtain ⟨s, hs, hsy⟩ := exists_lt_of_csInf_lt hne hy
      exact le_trans hs (hFmono hsy.le)
    have hcont : ContinuousWithinAt F (Set.Ioi x) x := by
      have := (ProbabilityTheory.cdf (μ.map L)).right_continuous x
      have h2 : ContinuousWithinAt F (Set.Ici x) x := by
        have hfun : F = ProbabilityTheory.cdf (μ.map L) := funext hF
        rw [hfun]; exact this
      exact h2.mono Set.Ioi_subset_Ici_self
    show α ≤ F x
    exact ge_of_tendsto hcont (eventually_nhdsWithin_of_forall fun y hy => hright y hy)
  constructor
  · show α ≤ F ((∫ ω, L ω ∂μ) + (sInf S - ∫ ω, L ω ∂μ))
    rw [add_sub_cancel]
    exact hmem
  · intro K hK
    have hK' : (∫ ω, L ω ∂μ) + K ∈ S := hK
    have := csInf_le hbdd hK'
    linarith

-- The book: 1,000 loans of $1,000,000, PD 2/100, LGD 40/100. EL = $8,000,000.
example : (1000 : ℚ) * (2 / 100) * (40 / 100) * 1000000 = 8000000 := by norm_num

-- One $1,000,000 loan: EL = $8,000.
example : (1000000 : ℚ) * (40 / 100) * (2 / 100) = 8000 := by norm_num

-- Book C's mixture keeps the average PD at 2/100: 9/10 × 1/100 + 1/10 × 11/100.
example : (9 / 10 : ℚ) * (1 / 100) + (1 / 10) * (11 / 100) = 2 / 100 := by norm_num

-- Book C in $ millions: UL = 53.60 - 8.00 = 45.60, written as 5360/100 - 8 = 4560/100.
example : (5360 / 100 : ℚ) - 8 = 4560 / 100 := by norm_num

-- Book A: ten loans of $100 million. Loss per default 40/100 × 100 = 40, EL = 10 × 2/100 × 40 = 8.
example : (40 / 100 : ℚ) * 100 = 40 ∧ (10 : ℚ) * (2 / 100) * 40 = 8 := by norm_num

-- Book A: at most one default has chance below 999/1000, at most two reaches it,
-- so the 99.9% quantile is 2 defaults, $80 million, and UL = 80 - 8 = 72.
example :
    (49 / 50 : ℚ) ^ 10 + 10 * (1 / 50) * (49 / 50) ^ 9 < 999 / 1000 ∧
    999 / 1000 ≤ (49 / 50 : ℚ) ^ 10 + 10 * (1 / 50) * (49 / 50) ^ 9
      + 45 * (1 / 50) ^ 2 * (49 / 50) ^ 8 ∧
    (2 : ℚ) * 40 - 8 = 72 := by
  norm_num

-- What breaks: forgetting LGD gives 2/100 × 1000 = 20 ($ millions);
-- adding 1,000 one-loan ULs gives 1000 × (40/100 - 8/1000) = 392.
example : (2 / 100 : ℚ) * 1000 = 20 ∧ (1000 : ℚ) * (40 / 100 - 8 / 1000) = 392 := by norm_num

#print axioms expected_loss_eq_sum_pd_lgd_ead
#print axioms least_capital_eq_quantile_sub_expected_loss
