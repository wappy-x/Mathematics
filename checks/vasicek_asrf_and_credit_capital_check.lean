-- The Basel credit formula: in a one-factor Vasicek book the 99.9% loss is the sum of each loan's loss in the one-in-a-thousand economy, so capital adds up loan by loan.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory

namespace VasicekASRF

/-- `N x`: the bell-curve area to the left of `x` (the standard normal distribution function). -/
noncomputable def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Loan `i`'s large-pool default rate when the economy is at `m`:
`N ((N⁻¹(p) - √R · m) / √(1 - R))`, written with the default threshold `c = N⁻¹(p)`. -/
noncomputable def condDefaultRate (c R m : ℝ) : ℝ :=
  N ((c - Real.sqrt R * m) / Real.sqrt (1 - R))

/-- The whole book's loss when the economy is at `m`: `L(m) = Σ_i E_i g_i q_i(m)`. -/
noncomputable def bookLoss {ι : Type*} [Fintype ι] (E g c R : ι → ℝ) (m : ℝ) : ℝ :=
  ∑ i, E i * g i * condDefaultRate (c i) (R i) m

end VasicekASRF

open VasicekASRF

open Set Filter Topology in
/-- The standard normal distribution function is continuous. -/
lemma N_continuous : Continuous N := by
  have hns : NullSingletonClass (gaussianReal 0 1) :=
    nullSingletonClass_gaussianReal (by norm_num)
  rw [continuous_iff_continuousAt]
  intro a
  set f := cdf (gaussianReal 0 1)
  have hmono : Monotone f := monotone_cdf _
  have h1 : f.measure {a} = 0 := by
    rw [measure_cdf]; exact measure_singleton a
  rw [StieltjesFunction.measure_singleton, ENNReal.ofReal_eq_zero] at h1
  have h2 : Function.leftLim f a = f a :=
    le_antisymm (hmono.leftLim_le le_rfl) (by linarith)
  have hl : ContinuousWithinAt f (Iio a) a :=
    (hmono.continuousWithinAt_Iio_iff_leftLim_eq).2 h2
  have hr : ContinuousWithinAt f (Ici a) a := f.right_continuous a
  exact continuousAt_iff_continuous_left_right.2
    ⟨continuousWithinAt_Iio_iff_Iic.1 hl, hr⟩

open Set in
/-- The standard normal distribution function is strictly increasing. -/
lemma N_strictMono : StrictMono N := by
  intro a b hab
  have hpos : (gaussianReal 0 1) (Ioc a b) ≠ 0 := by
    intro h
    have := gaussianReal_absolutelyContinuous' (0:ℝ) (v := 1) (by norm_num) h
    rw [Real.volume_Ioc] at this
    simp at this; linarith
  have h := (cdf (gaussianReal 0 1)).measure_Ioc a b
  rw [measure_cdf] at h
  rw [h] at hpos
  have : ¬ (cdf (gaussianReal 0 1) b - cdf (gaussianReal 0 1) a ≤ 0) := by
    intro hle; exact hpos (ENNReal.ofReal_eq_zero.2 hle)
  unfold N; linarith

open Set in
/-- The chance that `Z > a` is `1 - N a`. -/
lemma real_Ioi_eq_one_sub_N (a : ℝ) : (gaussianReal 0 1).real (Ioi a) = 1 - N a := by
  rw [← compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic, N, cdf_eq_real]

/-- The book's loss is strictly decreasing in the economy. -/
lemma bookLoss_strictAnti {ι : Type*} [Fintype ι] [Nonempty ι]
    (E g c R : ι → ℝ) (hE : ∀ i, 0 < E i) (hg : ∀ i, 0 < g i)
    (hR : ∀ i, 0 < R i ∧ R i < 1) : StrictAnti (bookLoss E g c R) := by
  intro z w hzw
  unfold bookLoss
  apply Finset.sum_lt_sum_of_nonempty Finset.univ_nonempty
  intro i _
  have hEg : 0 < E i * g i := mul_pos (hE i) (hg i)
  apply mul_lt_mul_of_pos_left _ hEg
  unfold condDefaultRate
  apply N_strictMono
  have h1 : 0 < Real.sqrt (1 - R i) := Real.sqrt_pos.2 (by linarith [(hR i).2])
  have h2 : 0 < Real.sqrt (R i) := Real.sqrt_pos.2 (hR i).1
  apply div_lt_div_of_pos_right _ h1
  nlinarith

/-- The book's loss is continuous in the economy. -/
lemma bookLoss_continuous {ι : Type*} [Fintype ι]
    (E g c R : ι → ℝ) : Continuous (bookLoss E g c R) := by
  unfold bookLoss condDefaultRate
  refine continuous_finsetSum _ (fun i _ => continuous_const.mul ?_)
  exact N_continuous.comp ((continuous_const.sub (continuous_const.mul continuous_id)).div_const _)

#print axioms N_continuous
#print axioms N_strictMono
#print axioms real_Ioi_eq_one_sub_N
#print axioms bookLoss_strictAnti
#print axioms bookLoss_continuous

/-- Portfolio invariance. Take any finite book of loans, loan `i` with size `E_i > 0`,
loss rate `g_i > 0`, default chance `0 < p_i < 1` (default threshold `c_i = N⁻¹(p_i)`) and
correlation `0 < R_i < 1`, all driven by one standard normal economy `Z`. Let `m*` be the
one-in-a-thousand bad economy, `N(m*) = 0.001`. Then the 99.9% point of the book's loss `L(Z)`
(the smallest `x` with `P(L(Z) ≤ x) ≥ 0.999`) is exactly `Σ_i E_i g_i q_i(m*)`, the sum of each
loan's own loss at that one economy. -/
theorem book_loss_quantile_eq_sum_of_loan_stress_losses
    {ι : Type*} [Fintype ι] [Nonempty ι]
    (E g p R c : ι → ℝ)
    (hE : ∀ i, 0 < E i) (hg : ∀ i, 0 < g i)
    (hp : ∀ i, 0 < p i ∧ p i < 1) (hR : ∀ i, 0 < R i ∧ R i < 1)
    (hc : ∀ i, N (c i) = p i)
    (mstar : ℝ) (hm : N mstar = 1 / 1000) :
    IsLeast {x : ℝ | 999 / 1000 ≤ (gaussianReal 0 1).real {z | bookLoss E g c R z ≤ x}}
      (∑ i, E i * g i * condDefaultRate (c i) (R i) mstar) := by
  have hL := bookLoss_strictAnti E g c R hE hg hR
  have hLc := bookLoss_continuous E g c R
  have hval : bookLoss E g c R mstar
      = ∑ i, E i * g i * condDefaultRate (c i) (R i) mstar := rfl
  rw [← hval]
  constructor
  · show 999 / 1000 ≤ (gaussianReal 0 1).real {z | bookLoss E g c R z ≤ bookLoss E g c R mstar}
    calc (999 / 1000 : ℝ) = (gaussianReal 0 1).real (Set.Ioi mstar) := by
          rw [real_Ioi_eq_one_sub_N, hm]; norm_num
      _ ≤ _ := by
          refine measureReal_mono ?_ (measure_ne_top _ _)
          intro z hz
          exact (hL (Set.mem_Ioi.1 hz)).le
  · intro x hx
    simp only [Set.mem_ofPred_eq] at hx
    by_contra hlt
    push Not at hlt
    have hev : ∀ᶠ z in nhdsWithin mstar (Set.Ioi mstar), x < bookLoss E g c R z ∧ mstar < z :=
      ((hLc.continuousAt.eventually (lt_mem_nhds hlt)).filter_mono nhdsWithin_le_nhds).and
        self_mem_nhdsWithin
    obtain ⟨a, ha1, ha2⟩ := hev.exists
    have hsub : {z | bookLoss E g c R z ≤ x} ⊆ Set.Ioi a := by
      intro z hz
      simp only [Set.mem_ofPred_eq] at hz
      by_contra hza
      simp only [Set.mem_Ioi, not_lt] at hza
      have := hL.antitone hza
      linarith
    have h1 := measureReal_mono (μ := gaussianReal 0 1) hsub
    rw [real_Ioi_eq_one_sub_N] at h1
    have h2 := N_strictMono ha2
    rw [hm] at h2
    linarith

/-- Capital adds up loan by loan. In the same book, the book's capital, its 99.9% loss minus its
average loss `Σ_i E_i g_i p_i`, equals the sum of the per-loan charges
`E_i g_i (q_i(m*) - p_i)`, each set by loan `i`'s own numbers. -/
theorem book_capital_eq_sum_of_loan_charges
    {ι : Type*} [Fintype ι] [Nonempty ι]
    (E g p R c : ι → ℝ)
    (hE : ∀ i, 0 < E i) (hg : ∀ i, 0 < g i)
    (hp : ∀ i, 0 < p i ∧ p i < 1) (hR : ∀ i, 0 < R i ∧ R i < 1)
    (hc : ∀ i, N (c i) = p i)
    (mstar : ℝ) (hm : N mstar = 1 / 1000) :
    sInf {x : ℝ | 999 / 1000 ≤ (gaussianReal 0 1).real {z | bookLoss E g c R z ≤ x}}
        - ∑ i, E i * g i * p i
      = ∑ i, E i * g i * (condDefaultRate (c i) (R i) mstar - p i) := by
  rw [(book_loss_quantile_eq_sum_of_loan_stress_losses E g p R c hE hg hp hR hc mstar hm).csInf_eq,
    ← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl (fun i _ => ?_)
  ring

/-- The maturity factor `(1 + (M - 2.5) b) / (1 - 1.5 b)` equals 1 for a one-year loan
(`M = 1`), so a one-year loan gets exactly the one-factor capital. -/
theorem maturity_factor_at_one_year (b : ℝ) (hb : 1 - 3 / 2 * b ≠ 0) :
    (1 + ((1 : ℝ) - 5 / 2) * b) / (1 - 3 / 2 * b) = 1 := by
  rw [div_eq_one_iff_eq hb]
  ring

-- The card's whole-number worked examples.
-- Loss if the family defaults: 40% of $200,000 is $80,000.
example : (200000 : ℚ) * (40 / 100) = 80000 := by norm_num
-- Expected loss: 2% default chance times 40% of $200,000 is $1,600.
example : (200000 : ℚ) * (2 / 100) * (40 / 100) = 1600 := by norm_num
-- 12.5 is 1 divided by the 8% minimum ratio.
example : (1 : ℚ) / (8 / 100) = 25 / 2 := by norm_num
-- The house bank's book: $600 million of home loans plus $400 million of company loans is $1 billion.
example : (600000000 : ℕ) + 400000000 = 1000000000 := by norm_num

#print axioms book_loss_quantile_eq_sum_of_loan_stress_losses
#print axioms book_capital_eq_sum_of_loan_charges
#print axioms maturity_factor_at_one_year
