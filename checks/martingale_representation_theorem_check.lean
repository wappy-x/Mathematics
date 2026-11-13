-- Martingale representation: on a coin-toss tree every payoff of n fair up-or-down steps is its average plus a sum of stakes, each fixed by the earlier tosses and only one way, and the digital's continuous strategy has average square 2500, its variance, as the isometry requires.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Process.Predictable
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.InverseDeriv
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open MeasureTheory ProbabilityTheory Filter
open scoped NNReal ENNReal Topology

/-! Scope. The card's continuous theorem (every Brownian payoff is its average plus an Ito
integral, and every Brownian martingale is its start plus one) needs an Ito integral, which
Mathlib does not have; the card's Python and Rust checks cover it. This file states the parts
Lean can check exactly: the coin-toss version from Step 0, and the digital's isometry from
Step 5. -/

section CoinHelpers

lemma mrt_coin_sum_cons {n : ℕ} (f : (Fin (n + 1) → Bool) → ℝ) :
    ∑ x, f x = ∑ y : Fin n → Bool, f (Fin.cons true y)
      + ∑ y : Fin n → Bool, f (Fin.cons false y) := by
  rw [← (Fin.consEquiv fun _ => Bool).sum_comp, Fintype.sum_prod_type, Fintype.sum_bool]
  rfl

lemma mrt_coin_unique : ∀ (n : ℕ) (D : Fin n → (Fin n → Bool) → ℝ) (c : ℝ),
    (∀ k x y, (∀ i, i < k → x i = y i) → D k x = D k y) →
    (∀ x, ∑ k, D k x * (if x k then 1 else -1) = c) → D = 0 ∧ c = 0
  | 0, D, c, _, h => by
    refine ⟨funext fun k => k.elim0, ?_⟩
    have := h Fin.elim0
    simpa using this.symm
  | n + 1, D, c, hD, h => by
    set d := D 0 (fun _ => true) with hd
    have hD0 : ∀ x, D 0 x = d := fun x =>
      hD 0 x _ (fun i hi => absurd hi (Fin.not_lt_zero i))
    have key : ∀ b : Bool,
        (fun k : Fin n => fun y : Fin n → Bool => D k.succ (Fin.cons b y)) = 0 ∧
          c - d * (if b then 1 else -1) = 0 := by
      intro b
      apply mrt_coin_unique n _ _
      · intro k x y hxy
        apply hD
        intro i hi
        cases i using Fin.cases with
        | zero => rfl
        | succ i => simp only [Fin.cons_succ]; exact hxy i (Fin.succ_lt_succ_iff.mp hi)
      · intro y
        have := h (Fin.cons b y)
        rw [Fin.sum_univ_succ, hD0] at this
        simp only [Fin.cons_zero, Fin.cons_succ] at this
        linarith
    have h1 := (key true).2
    have h2 := (key false).2
    simp only [ite_true, Bool.false_eq_true, ite_false] at h1 h2
    have hc : c = 0 := by linarith
    have hd0 : d = 0 := by linarith
    refine ⟨?_, hc⟩
    funext k x
    cases k using Fin.cases with
    | zero => simpa [hd0] using hD0 x
    | succ k =>
      have := congrFun (congrFun (key (x 0)).1 k) (Fin.tail x)
      simpa [Fin.cons_self_tail] using this

lemma mrt_coin_exists : ∀ (n : ℕ) (V : (Fin n → Bool) → ℝ), ∃ φ : Fin n → (Fin n → Bool) → ℝ,
      (∀ k x y, (∀ i, i < k → x i = y i) → φ k x = φ k y) ∧
      (∀ x, V x = (∑ y, V y) / 2 ^ n + ∑ k, φ k x * (if x k then 1 else -1))
  | 0, V => by
    refine ⟨fun k => k.elim0, fun k => k.elim0, fun x => ?_⟩
    rw [Fintype.sum_subsingleton _ x]
    simp
  | n + 1, V => by
    choose ψ hψp hψr using fun b : Bool => mrt_coin_exists n (fun y => V (Fin.cons b y))
    set A : Bool → ℝ := fun b => ∑ y : Fin n → Bool, V (Fin.cons b y) with hA
    set d : ℝ := (A true - A false) / 2 ^ (n + 1) with hd
    refine ⟨fun k x => Fin.cases d (fun k => ψ (x 0) k (Fin.tail x)) k, ?_, ?_⟩
    · intro k x y hxy
      cases k using Fin.cases with
      | zero => rfl
      | succ k =>
        simp only [Fin.cases_succ]
        have h0 : x 0 = y 0 := hxy 0 (Fin.succ_pos k)
        rw [h0]
        apply hψp
        intro i hi
        exact hxy i.succ (Fin.succ_lt_succ_iff.mpr hi)
    · intro x
      have hr := hψr (x 0) (Fin.tail x)
      rw [Fin.cons_self_tail] at hr
      have hs : ∑ k : Fin n, ψ (x 0) k (Fin.tail x) * (if x k.succ then 1 else -1)
          = V x - A (x 0) / 2 ^ n := by
        simp only [hA]
        change V x = _ + ∑ k : Fin n, ψ (x 0) k (Fin.tail x) * (if x k.succ then 1 else -1) at hr
        linarith
      rw [Fin.sum_univ_succ, mrt_coin_sum_cons]
      simp only [Fin.cases_zero, Fin.cases_succ]
      rw [hs]
      change V x = (A true + A false) / 2 ^ (n + 1) + _
      rcases hx : x 0 with _ | _
      · simp only [hd, Bool.false_eq_true, ite_false]
        field_simp
        ring
      · simp only [hd, ite_true]
        field_simp
        ring

end CoinHelpers

#print axioms mrt_coin_sum_cons
#print axioms mrt_coin_unique
#print axioms mrt_coin_exists

section MRTHelpers

open Real

lemma mrt_integral_exp_neg_sq_div_gaussianReal {v : ℝ≥0} (hv : v ≠ 0) {c : ℝ} (hc : 0 < c) :
    ∫ x, Real.exp (-x ^ 2 / c) ∂(gaussianReal 0 v) = Real.sqrt (c / (c + 2 * v)) := by
  have hv' : (0 : ℝ) < v := by positivity
  rw [integral_gaussianReal_eq_integral_smul hv]
  have h1 : ∀ x : ℝ, gaussianPDFReal 0 v x • Real.exp (-x ^ 2 / c)
      = (Real.sqrt (2 * π * v))⁻¹ * Real.exp (-(1 / c + 1 / (2 * v)) * x ^ 2) := by
    intro x
    rw [gaussianPDFReal, smul_eq_mul, mul_assoc, ← Real.exp_add]
    congr 2
    field_simp
    ring
  simp_rw [h1]
  rw [integral_const_mul, integral_gaussian]
  rw [← Real.sqrt_inv, ← Real.sqrt_mul (by positivity)]
  congr 1
  field_simp
  ring

lemma mrt_digital_inner {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P]
    (W : ℝ≥0 → Ω → ℝ) (hW : IsBrownianReal W P) (T : ℝ≥0) {t : ℝ} (ht0 : 0 < t)
    (htT : t < T) :
    ∫ ω, (100 * gaussianPDFReal 0 1 (W t.toNNReal ω / Real.sqrt (T - t)) / Real.sqrt (T - t)) ^ 2
        ∂P = 10000 / (2 * Real.pi) * (1 / Real.sqrt ((T : ℝ) ^ 2 - t ^ 2)) := by
  have hc : (0 : ℝ) < T - t := by linarith
  have hv : t.toNNReal ≠ 0 := by simpa using ht0
  have hlaw := hW.hasLaw_eval t.toNNReal
  have key : ∀ x : ℝ,
      (100 * gaussianPDFReal 0 1 (x / Real.sqrt (T - t)) / Real.sqrt (T - t)) ^ 2
        = 10000 / (2 * π * (T - t)) * Real.exp (-x ^ 2 / (T - t)) := by
    intro x
    have hs : Real.sqrt (T - t) ^ 2 = T - t := Real.sq_sqrt hc.le
    have hs2 : Real.sqrt (2 * π) ^ 2 = 2 * π := Real.sq_sqrt (by positivity)
    have hspos : 0 < Real.sqrt (T - t) := Real.sqrt_pos.2 hc
    have hpi : 0 < Real.sqrt (2 * π) := Real.sqrt_pos.2 (by positivity)
    rw [gaussianPDFReal]
    simp only [NNReal.coe_one, mul_one, sub_zero]
    rw [div_pow, mul_pow, mul_pow, inv_pow, hs2, ← Real.exp_nat_mul, div_pow, hs]
    rw [show ((2 : ℕ) : ℝ) * (-(x ^ 2 / ((T : ℝ) - t)) / 2) = -x ^ 2 / ((T : ℝ) - t) by
      push_cast; ring]
    field_simp
    norm_num
  have h1 := hlaw.integral_comp (f := fun x : ℝ =>
      (100 * gaussianPDFReal 0 1 (x / Real.sqrt (T - t)) / Real.sqrt (T - t)) ^ 2)
    ((((measurable_gaussianPDFReal 0 1).comp (measurable_id.div_const _)).const_mul 100
      |>.div_const _).pow_const 2).aestronglyMeasurable
  simp only [Function.comp_def] at h1
  rw [h1]
  simp_rw [key]
  rw [integral_const_mul, mrt_integral_exp_neg_sq_div_gaussianReal hv hc]
  rw [Real.coe_toNNReal _ ht0.le]
  have hb : (0 : ℝ) < T + t := by linarith
  have e1 : (T : ℝ) - t + 2 * t = T + t := by ring
  rw [e1, Real.sqrt_div hc.le, show (T : ℝ) ^ 2 - t ^ 2 = (T - t) * (T + t) by ring,
    Real.sqrt_mul hc.le]
  have hsa : 0 < Real.sqrt ((T : ℝ) - t) := Real.sqrt_pos.2 hc
  have hsb : 0 < Real.sqrt ((T : ℝ) + t) := Real.sqrt_pos.2 hb
  have hsq : Real.sqrt ((T : ℝ) - t) ^ 2 = T - t := Real.sq_sqrt hc.le
  field_simp
  rw [hsq]

lemma mrt_integral_inv_sqrt {T : ℝ} (hT : 0 < T) :
    ∫ t in (0 : ℝ)..T, 1 / Real.sqrt (T ^ 2 - t ^ 2) = π / 2 := by
  have hderiv : ∀ x ∈ Set.Ioo (0 : ℝ) T,
      HasDerivAt (fun t => Real.arcsin (t / T)) (1 / Real.sqrt (T ^ 2 - x ^ 2)) x := by
    intro x hx
    have hx1 : x / T ≠ -1 := by
      have : 0 < x / T := div_pos hx.1 hT
      linarith
    have hx2 : x / T ≠ 1 := by
      have : x / T < 1 := (div_lt_one hT).2 hx.2
      exact this.ne
    have h := (Real.hasDerivAt_arcsin hx1 hx2).comp x ((hasDerivAt_id x).div_const T)
    refine h.congr_deriv ?_
    have hpos : 0 < T ^ 2 - x ^ 2 := by nlinarith [hx.1, hx.2]
    have he : 1 - (x / T) ^ 2 = (T ^ 2 - x ^ 2) / T ^ 2 := by field_simp
    rw [he, Real.sqrt_div hpos.le, Real.sqrt_sq hT.le]
    have := Real.sqrt_pos.2 hpos
    field_simp
  have hcont : ContinuousOn (fun t => Real.arcsin (t / T)) (Set.Icc 0 T) := by
    fun_prop
  have hint : IntervalIntegrable (fun x => 1 / Real.sqrt (T ^ 2 - x ^ 2)) volume 0 T := by
    apply intervalIntegral.intervalIntegrable_deriv_of_nonneg (g := fun t => Real.arcsin (t / T))
    · rw [Set.uIcc_of_le hT.le]; exact hcont
    · intro x hx
      rw [min_eq_left hT.le, max_eq_right hT.le] at hx
      exact hderiv x hx
    · intro x _; positivity
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hT.le hcont hderiv hint]
  simp [div_self hT.ne']

lemma mrt_gaussianReal_Ioi_zero {v : ℝ≥0} (hv : v ≠ 0) :
    (gaussianReal 0 v).real (Set.Ioi 0) = 1 / 2 := by
  have := nullSingletonClass_gaussianReal (μ := 0) hv
  have hsym : (gaussianReal 0 v) (Set.Iio 0) = (gaussianReal 0 v) (Set.Ioi 0) := by
    have h := gaussianReal_map_neg (μ := 0) (v := v)
    rw [neg_zero] at h
    conv_lhs => rw [← h]
    rw [Measure.map_apply (by fun_prop) measurableSet_Iio]
    congr 1
    ext x; simp
  have hc : (gaussianReal 0 v) (Set.Ioi 0) + (gaussianReal 0 v) (Set.Iic 0) = 1 := by
    rw [← Set.compl_Ioi, measure_add_measure_compl measurableSet_Ioi, measure_univ]
  rw [← measure_congr Iio_ae_eq_Iic, hsym] at hc
  have h2 : (gaussianReal 0 v) (Set.Ioi 0) = 1 / 2 := by
    rw [ENNReal.eq_div_iff (by norm_num) (by norm_num), two_mul, hc]
  simp [Measure.real, h2]

end MRTHelpers

#print axioms mrt_integral_exp_neg_sq_div_gaussianReal
#print axioms mrt_digital_inner
#print axioms mrt_integral_inv_sqrt
#print axioms mrt_gaussianReal_Ioi_zero

/-- **Step 0: one fork per step.** On a coin-toss tree of `n` fair tosses, each moving the share
up `1` (heads, `true`) or down `1` (tails, `false`) with even chances, every payoff `V` equals its
average over all `2 ^ n` paths plus the gain of a trading strategy: `φ k` units held on toss `k`,
fixed by the tosses before it. The strategy is the only one: any other strategy fixed by the
earlier tosses that gives `V` is the same. -/
theorem coin_toss_payoff_eq_average_add_stakes (n : ℕ) (V : (Fin n → Bool) → ℝ) :
    ∃ φ : Fin n → (Fin n → Bool) → ℝ,
      (∀ k x y, (∀ i, i < k → x i = y i) → φ k x = φ k y) ∧
      (∀ x, V x = (∑ y, V y) / 2 ^ n + ∑ k, φ k x * (if x k then 1 else -1)) ∧
      ∀ φ' : Fin n → (Fin n → Bool) → ℝ,
        (∀ k x y, (∀ i, i < k → x i = y i) → φ' k x = φ' k y) →
        (∀ x, V x = (∑ y, V y) / 2 ^ n + ∑ k, φ' k x * (if x k then 1 else -1)) →
        φ' = φ := by
  obtain ⟨φ, hφp, hφr⟩ := mrt_coin_exists n V
  refine ⟨φ, hφp, hφr, fun φ' hφ'p hφ'r => ?_⟩
  have h := mrt_coin_unique n (fun k x => φ' k x - φ k x) 0
    (fun k x y hxy => by simp only [hφ'p k x y hxy, hφp k x y hxy])
    (fun x => by
      have h1 := hφr x
      have h2 := hφ'r x
      simp only [sub_mul, Finset.sum_sub_distrib]
      linarith)
  funext k x
  have := congrFun (congrFun h.1 k) x
  simp only [Pi.zero_apply] at this
  linarith

/-- **Step 5: the digital's bet has the right size.** The digital pays `100` when the share
`S_T = 100 + σ W_T` ends above `100`, that is when `W_T > 0`. Its strategy in units of `W` is
`φ_t = 100 N'(W_t / √(T - t)) / √(T - t)`, with `N'` the bell-curve height. For every horizon
`T > 0`, the average square of that strategy over the year, `E[∫_0^T φ_t^2 dt]`, is `2500`, and
so is the payoff's variance, as the isometry requires. -/
theorem digital_strategy_avg_square_eq_variance
    {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω) [IsProbabilityMeasure P]
    (W : ℝ≥0 → Ω → ℝ) (hW : IsBrownianReal W P) (T : ℝ≥0) (hT : 0 < T) :
    (∫ t in (0 : ℝ)..T, ∫ ω,
        (100 * gaussianPDFReal 0 1 (W t.toNNReal ω / Real.sqrt (T - t)) / Real.sqrt (T - t)) ^ 2
          ∂P) = 2500 ∧
      Var[fun ω => if 0 < W T ω then (100 : ℝ) else 0; P] = 2500 := by
  constructor
  · have hT' : (0 : ℝ) < T := hT
    have hae : ∀ᵐ t ∂(volume : Measure ℝ), t ∈ Set.uIoc (0 : ℝ) T →
        (∫ ω, (100 * gaussianPDFReal 0 1 (W t.toNNReal ω / Real.sqrt (T - t))
          / Real.sqrt (T - t)) ^ 2 ∂P)
          = 10000 / (2 * Real.pi) * (1 / Real.sqrt ((T : ℝ) ^ 2 - t ^ 2)) := by
      have hne : ∀ᵐ t ∂(volume : Measure ℝ), t ≠ (T : ℝ) := by
        rw [ae_iff]; simp
      filter_upwards [hne] with t htne ht
      rw [Set.uIoc_of_le hT'.le] at ht
      exact mrt_digital_inner P W hW T ht.1 (lt_of_le_of_ne ht.2 htne)
    rw [intervalIntegral.integral_congr_ae hae, intervalIntegral.integral_const_mul,
      mrt_integral_inv_sqrt hT']
    field_simp
    norm_num
  · have hv : T ≠ 0 := hT.ne'
    have hlaw := hW.hasLaw_eval T
    set g : ℝ → ℝ := fun x => if 0 < x then (100 : ℝ) else 0 with hg
    have hgm : Measurable g := by
      exact Measurable.ite measurableSet_Ioi measurable_const measurable_const
    have hcomp : (fun ω => if 0 < W T ω then (100 : ℝ) else 0) = g ∘ W T := rfl
    rw [hcomp, ← variance_map (by rw [hlaw.map_eq]; exact hgm.aemeasurable) hlaw.aemeasurable,
      hlaw.map_eq]
    have hgi : g = (Set.Ioi (0 : ℝ)).indicator (fun _ => (100 : ℝ)) := by
      ext x; by_cases hx : 0 < x <;> simp [hg, Set.indicator, hx]
    have hmem : MemLp g 2 (gaussianReal 0 T) := by
      rw [hgi]
      exact (memLp_const 100).indicator measurableSet_Ioi.nullMeasurableSet
    rw [variance_eq_sub hmem]
    have hsq : g ^ 2 = (Set.Ioi (0 : ℝ)).indicator (fun _ => (10000 : ℝ)) := by
      ext x; by_cases hx : 0 < x <;> norm_num [hg, Set.indicator, hx]
    rw [hsq, hgi, integral_indicator_const _ measurableSet_Ioi,
      integral_indicator_const _ measurableSet_Ioi, mrt_gaussianReal_Ioi_zero hv]
    norm_num

/-! The card's exact worked numbers. -/

-- Fair value at the start: 100 times the chance 1/2 of finishing above the strike.
example : (100 : ℚ) * (1 / 2) = 50 := by norm_num

-- Variance of the digital: 100^2 times 1/2 times 1/2 is 2500.
example : (100 : ℚ) ^ 2 * (1 / 2) * (1 - 1 / 2) = 2500 := by norm_num

-- Adding up the average square over the year: 100^2 / (2 π) times π / 2 is 2500.
example : (100 : ℝ) ^ 2 / (2 * Real.pi) * (Real.pi / 2) = 2500 := by
  field_simp
  norm_num

#print axioms coin_toss_payoff_eq_average_add_stakes
#print axioms digital_strategy_avg_square_eq_variance
