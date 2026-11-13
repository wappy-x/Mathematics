-- Confidence intervals: for independent normal readings with known spread, the z interval contains the true mean with chance exactly 0.95, the t interval's coverage event is the same event as its pivot landing within the cutoff, and the card's worked whole-number checks hold.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.CharacteristicFunction
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Set
open scoped NNReal

theorem sum_iid_gaussian_law
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (n : ℕ) (X : Fin n → Ω → ℝ) (μ : ℝ) (v : ℝ≥0)
    (hind : iIndepFun X P) (hlaw : ∀ i, HasLaw (X i) (gaussianReal μ v) P) :
    HasLaw (fun ω ↦ ∑ i, X i ω) (gaussianReal (n * μ) (n * v)) P := by
  have hm : AEMeasurable (fun ω ↦ ∑ i, X i ω) P :=
    Finset.aemeasurable_fun_sum _ (fun i _ ↦ (hlaw i).aemeasurable)
  refine ⟨hm, ?_⟩
  apply Measure.ext_of_charFun
  ext t
  rw [hind.charFun_map_fun_sum_eq_prod (fun i ↦ (hlaw i).aemeasurable)]
  simp only [(hlaw _).map_eq, charFun_gaussianReal, Finset.prod_const, Finset.card_univ,
    Fintype.card_fin, Pi.pow_apply]
  rw [← Complex.exp_nat_mul]
  congr 1
  push_cast
  ring

#print axioms sum_iid_gaussian_law

theorem std_gaussian_Icc (c : ℝ) (hc : (gaussianReal 0 1).real (Iic c) = 0.975) :
    (gaussianReal 0 1).real (Icc (-c) c) = 0.95 := by
  set γ := gaussianReal 0 1
  have hsymm : γ.real (Iio (-c)) = 0.025 := by
    have h1 : γ.map (fun x ↦ -x) = γ := by
      simpa using (gaussianReal_map_neg (μ := (0:ℝ)) (v := 1))
    have h2 : γ.real (Iio (-c)) = γ.real (Ioi c) := by
      conv_lhs => rw [← h1]
      rw [map_measureReal_apply (by fun_prop) measurableSet_Iio]
      congr 1
      ext x; simp
    rw [h2, ← compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ, hc]
    norm_num
  have hc0 : 0 ≤ c := by
    by_contra h
    push Not at h
    have : γ.real (Iic c) ≤ γ.real (Iio (-c)) :=
      measureReal_mono (fun x hx ↦ by simp at hx ⊢; linarith)
    rw [hc, hsymm] at this
    norm_num at this
  have hIcc : Icc (-c) c = Iic c \ Iio (-c) := by
    ext x; simp [and_comm]
  rw [hIcc, measureReal_sdiff (fun x hx ↦ by simp at hx ⊢; linarith) measurableSet_Iio, hc,
    hsymm]
  norm_num

#print axioms std_gaussian_Icc

/-- The z interval's promise: take `n ≥ 1` independent readings, each normal with true mean `μ`
and known spread `σ > 0`. Let `c` be the standard bell's 0.975 point, `Φ(c) = 0.975`.
Then, before the readings arrive, the chance that the interval
`average ± c · σ / √n` contains the true mean `μ` is exactly 0.95, whatever `μ` and `σ` are. -/
theorem z_interval_covers_true_mean_95_percent
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (n : ℕ) (hn : 0 < n) (X : Fin n → Ω → ℝ) (μ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (hind : iIndepFun X P) (hlaw : ∀ i, HasLaw (X i) (gaussianReal μ (σ ^ 2)) P)
    (c : ℝ) (hc : (gaussianReal 0 1).real (Iic c) = 0.975) :
    P.real {ω | (∑ i, X i ω) / n - c * σ / Real.sqrt n ≤ μ ∧
                μ ≤ (∑ i, X i ω) / n + c * σ / Real.sqrt n} = 0.95 := by
  have hS := sum_iid_gaussian_law P n X μ (σ ^ 2) hind hlaw
  set r := Real.sqrt n with hr
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  have hrpos : 0 < r := Real.sqrt_pos.mpr hnpos
  have hrr : r ^ 2 = n := Real.sq_sqrt hnpos.le
  have hσr : (0 : ℝ) < σ := by exact_mod_cast hσ
  have hZ := gaussianReal_div_const (gaussianReal_sub_const hS (n * μ)) ((σ : ℝ) * r)
  have hZ' : HasLaw (fun ω ↦ ((∑ i, X i ω) - n * μ) / (σ * r)) (gaussianReal 0 1) P := by
    convert hZ using 2
    · simp
    · apply NNReal.eq
      simp only [NNReal.coe_div, NNReal.coe_mul, NNReal.coe_natCast, NNReal.coe_pow,
        NNReal.coe_mk, NNReal.coe_one]
      rw [mul_pow, hrr]
      field_simp
  have hset : {ω | (∑ i, X i ω) / n - c * σ / r ≤ μ ∧ μ ≤ (∑ i, X i ω) / n + c * σ / r} =
      {ω | (fun x ↦ -c ≤ x ∧ x ≤ c) (((∑ i, X i ω) - n * μ) / (σ * r))} := by
    ext ω
    simp only [mem_ofPred_eq]
    set S := ∑ i, X i ω
    set Z := (S - n * μ) / (σ * r)
    have k_pos : 0 < (σ : ℝ) / r := div_pos hσr hrpos
    have hid : S / n = μ + (σ / r) * Z := by
      simp only [Z]
      rw [← hrr]
      field_simp
      ring
    have hcs : c * σ / r = (σ / r) * c := by ring
    rw [hid, hcs]
    constructor
    · rintro ⟨h1, h2⟩
      constructor <;> nlinarith
    · rintro ⟨h1, h2⟩
      constructor <;> nlinarith
  rw [hset, hZ'.measureReal_eq (p := fun x ↦ -c ≤ x ∧ x ≤ c)
    (measurableSet_le measurable_const measurable_id |>.inter
      (measurableSet_le measurable_id measurable_const))]
  exact std_gaussian_Icc c hc

/-- The flip behind every interval on the card: when the estimated spread `s` is positive,
"the average is within `t` standard errors `s / √n` of `μ`", written as the pivot
`-t ≤ (x̄ - μ) / (s / √n) ≤ t`, is the same statement as
"`μ` lies between `x̄ - t · s / √n` and `x̄ + t · s / √n`". -/
theorem pivot_event_iff_interval_contains_mean
    (n : ℕ) (hn : 0 < n) (xbar μ s t : ℝ) (hs : 0 < s) :
    (-t ≤ (xbar - μ) / (s / Real.sqrt n) ∧ (xbar - μ) / (s / Real.sqrt n) ≤ t) ↔
      (xbar - t * s / Real.sqrt n ≤ μ ∧ μ ≤ xbar + t * s / Real.sqrt n) := by
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  have hk : 0 < s / Real.sqrt n := div_pos hs (Real.sqrt_pos.mpr hnpos)
  have he : t * s / Real.sqrt n = t * (s / Real.sqrt n) := by ring
  rw [le_div_iff₀ hk, div_le_iff₀ hk, he]
  constructor
  · rintro ⟨h1, h2⟩; constructor <;> linarith
  · rintro ⟨h1, h2⟩; constructor <;> linarith

/-- The distances of the readings from their average always add to zero,
so only `n - 1` of them are free: the degrees of freedom. -/
theorem deviations_from_average_sum_to_zero
    (n : ℕ) (hn : 0 < n) (x : Fin n → ℝ) :
    ∑ i, (x i - (∑ j, x j) / n) = 0 := by
  have hnpos : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  rw [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  field_simp
  ring

/-! The card's worked numbers: ten recovery times 12, 9, 15, 7, 14, 13, 17, 11, 12, 14 days. -/

-- The total of the ten is 124 days.
example : ([12, 9, 15, 7, 14, 13, 17, 11, 12, 14] : List ℕ).sum = 124 := by decide

-- The squared distances from the average 124/10 = 12.4 add up to 76.4 = 382/5.
example : (([12, 9, 15, 7, 14, 13, 17, 11, 12, 14] : List ℚ).map
    (fun x => (x - 124 / 10) ^ 2)).sum = 382 / 5 := by norm_num

-- One-pass check: n · Σx² − (Σx)² = 10 · 1614 − 124² = 764.
example : (10 : ℤ) * (([12, 9, 15, 7, 14, 13, 17, 11, 12, 14] : List ℤ).map (· ^ 2)).sum
    - (([12, 9, 15, 7, 14, 13, 17, 11, 12, 14] : List ℤ).sum) ^ 2 = 764 := by decide

-- Only 6 of the 10 patients' own times lie inside the t interval 10.3158 to 14.4842 days.
-- (Bounds scaled by 10000 to stay in whole numbers.)
example : (([12, 9, 15, 7, 14, 13, 17, 11, 12, 14] : List ℕ).filter
    (fun x => decide (103158 ≤ 10000 * x ∧ 10000 * x ≤ 144842))).length = 6 := by decide

-- Planning: ±1 day with σ = 3 needs n ≥ (1.959964 · 3 / 1)² = 34.57..., so 35 patients.
example : 34 * 10 ^ 12 < (1959964 * 3 : ℕ) ^ 2 ∧ (1959964 * 3 : ℕ) ^ 2 ≤ 35 * 10 ^ 12 := by
  norm_num

#print axioms z_interval_covers_true_mean_95_percent
#print axioms pivot_event_iff_interval_contains_mean
#print axioms deviations_from_average_sum_to_zero
