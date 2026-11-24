-- Azuma-Hoeffding and McDiarmid: a martingale whose steps each lie in a range of fixed width strays t from its start with chance at most e^(-2t^2/(sum of squared widths)) each way, a function of independent inputs with bounded differences misses its average by t with at most twice that, and moving one ball changes the count of empty boxes by at most 1.
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Probability.Moments.SubGaussian
import Mathlib.Probability.Distributions.Bernoulli
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.MeasureTheory.Integral.Prod

open MeasureTheory ProbabilityTheory Finset

lemma hoeffding_two_point {a c θ : ℝ} (hc : 0 < c) (ha0 : a ≤ 0) (hac : -c ≤ a) :
    ((a + c) * Real.exp (θ * a) - a * Real.exp (θ * (a + c))) / c ≤
      Real.exp (θ ^ 2 * c ^ 2 / 8) := by
  have hp0 : 0 ≤ (a + c) / c := div_nonneg (by linarith) hc.le
  have hp1 : (a + c) / c ≤ 1 := (div_le_one hc).2 (by linarith)
  set p : unitInterval := ⟨(a + c) / c, hp0, hp1⟩
  have hint : ∫ x, id x ∂(bernoulliMeasure a (a + c) p) = 0 := by
    rw [integral_bernoulliMeasure]
    simp only [id, smul_eq_mul, p]
    field_simp
    ring
  have hae : ∀ᵐ x ∂(bernoulliMeasure a (a + c) p), id x ∈ Set.Icc a (a + c) := by
    rw [bernoulliMeasure_def, ae_add_measure_iff]
    constructor <;> apply Measure.ae_smul_measure <;> rw [ae_dirac_eq] <;>
      simp only [Filter.eventually_pure, id, Set.mem_Icc] <;> constructor <;> linarith
  have h := (hasSubgaussianMGF_of_mem_Icc_of_integral_eq_zero aemeasurable_id hae hint).mgf_le θ
  have hmgf : mgf id (bernoulliMeasure a (a + c) p) θ =
      ((a + c) * Real.exp (θ * a) - a * Real.exp (θ * (a + c))) / c := by
    rw [mgf, integral_bernoulliMeasure]
    simp only [id, smul_eq_mul, p]
    field_simp
    ring
  rw [hmgf] at h
  refine h.trans (le_of_eq ?_)
  congr 1
  simp only [NNReal.coe_pow, NNReal.coe_div, coe_nnnorm, Real.norm_eq_abs, add_sub_cancel_left,
    abs_of_pos hc]
  push_cast
  ring

lemma pos_on_null {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} {S : Set Ω} {F : Ω → ℝ}
    (hS : MeasurableSet S) (hF : Integrable F μ) (h0 : ∫ ω in S, F ω ∂μ = 0)
    (hpos : ∀ᵐ ω ∂μ, ω ∈ S → 0 < F ω) : ∀ᵐ ω ∂μ, ω ∉ S := by
  have hnn : 0 ≤ᵐ[μ.restrict S] F := by
    rw [Filter.EventuallyLE, ae_restrict_iff' hS]
    filter_upwards [hpos] with ω h hω using (h hω).le
  have hz := (setIntegral_eq_zero_iff_of_nonneg_ae hnn hF.integrableOn).1 h0
  have hz' : ∀ᵐ ω ∂μ, ω ∈ S → F ω = 0 := (ae_restrict_iff' hS).1 hz
  filter_upwards [hz', hpos] with ω h1 h2 hω
  have := h1 hω
  have := h2 hω
  linarith

lemma step_range {Ω : Type*} {m mΩ : MeasurableSpace Ω} {μ : Measure Ω} [IsFiniteMeasure μ]
    (hm : m ≤ mΩ) {A D : Ω → ℝ} {c : ℝ} (hAm : Measurable[m] A) (hD : Integrable D μ)
    (hDc : μ[D | m] =ᵐ[μ] 0) (hDA : ∀ᵐ ω ∂μ, D ω ∈ Set.Icc (A ω) (A ω + c)) :
    ∀ᵐ ω ∂μ, A ω ∈ Set.Icc (-c) 0 := by
  have hset : ∀ S, MeasurableSet[m] S → ∫ ω in S, D ω ∂μ = 0 := by
    intro S hS
    calc ∫ ω in S, D ω ∂μ = ∫ ω in S, (μ[D | m]) ω ∂μ := (setIntegral_condExp hm hD hS).symm
      _ = ∫ ω in S, (0 : ℝ) ∂μ :=
          setIntegral_congr_ae (hm S hS) (by filter_upwards [hDc] with ω h _ using h)
      _ = 0 := by simp
  have h1 := pos_on_null (hm _ (hAm (measurableSet_Ioi (a := (0:ℝ))))) hD (hset _ (hAm (measurableSet_Ioi (a := (0:ℝ)))))
    (by filter_upwards [hDA] with ω h hω; simp only [Set.mem_preimage, Set.mem_Ioi] at hω; linarith [h.1])
  have h2 := pos_on_null (F := fun ω => -D ω) (hm _ ((hAm.add_const c) (measurableSet_Iio (a := (0:ℝ))))) hD.neg
    (by rw [integral_neg, hset _ ((hAm.add_const c) (measurableSet_Iio (a := (0:ℝ)))), neg_zero])
    (by filter_upwards [hDA] with ω h hω; simp only [Set.mem_preimage, Set.mem_Iio] at hω; linarith [h.2])
  filter_upwards [h1, h2] with ω h1 h2
  simp only [Set.mem_preimage, Set.mem_Ioi, Set.mem_Iio, not_lt] at h1 h2
  constructor <;> linarith

lemma step_mgf {Ω : Type*} {m mΩ : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]
    (hm : m ≤ mΩ) {Z A D : Ω → ℝ} {c θ B : ℝ} (hc : 0 < c)
    (hZm : Measurable[m] Z) (hZ0 : ∀ ω, 0 ≤ Z ω) (hZB : ∀ᵐ ω ∂μ, Z ω ≤ B)
    (hAm : Measurable[m] A) (hA : ∀ᵐ ω ∂μ, A ω ∈ Set.Icc (-c) 0)
    (hD : Integrable D μ) (hDc : μ[D | m] =ᵐ[μ] 0)
    (hDA : ∀ᵐ ω ∂μ, D ω ∈ Set.Icc (A ω) (A ω + c)) :
    ∫ ω, Z ω * Real.exp (θ * D ω) ∂μ ≤ Real.exp (θ ^ 2 * c ^ 2 / 8) * ∫ ω, Z ω ∂μ := by
  set K := Real.exp (θ ^ 2 * c ^ 2 / 8)
  set E := Real.exp (|θ| * c)
  set h : Ω → ℝ := fun ω =>
    ((A ω + c) * Real.exp (θ * A ω) - A ω * Real.exp (θ * (A ω + c))) / c with hh
  set W : Ω → ℝ := fun ω =>
    Z ω * ((Real.exp (θ * (A ω + c)) - Real.exp (θ * A ω)) / c) with hW
  have hexp : ∀ x, |x| ≤ c → Real.exp (θ * x) ≤ E := fun x hx => Real.exp_le_exp.2 (by
      calc θ * x ≤ |θ * x| := le_abs_self _
      _ = |θ| * |x| := abs_mul _ _
      _ ≤ |θ| * c := mul_le_mul_of_nonneg_left hx (abs_nonneg _))
  have hDb : ∀ᵐ ω ∂μ, D ω ∈ Set.Icc (-c) c := by
    filter_upwards [hA, hDA] with ω h1 h2
    constructor <;> linarith [h1.1, h1.2, h2.1, h2.2]
  have hZmΩ : Measurable Z := hZm.mono hm le_rfl
  have hAmΩ : Measurable A := hAm.mono hm le_rfl
  have hpt : ∀ᵐ ω ∂μ, Z ω * Real.exp (θ * D ω) ≤ Z ω * h ω + W ω * D ω := by
    filter_upwards [hDA] with ω hω
    have hw1 : 0 ≤ (A ω + c - D ω) / c := div_nonneg (by linarith [hω.2]) hc.le
    have hw2 : 0 ≤ (D ω - A ω) / c := div_nonneg (by linarith [hω.1]) hc.le
    have hsum : (A ω + c - D ω) / c + (D ω - A ω) / c = 1 := by field_simp; ring
    have hcv := convexOn_exp.2 (Set.mem_univ (θ * A ω)) (Set.mem_univ (θ * (A ω + c))) hw1 hw2 hsum
    simp only [smul_eq_mul] at hcv
    have harg : (A ω + c - D ω) / c * (θ * A ω) + (D ω - A ω) / c * (θ * (A ω + c)) =
        θ * D ω := by
      field_simp; ring
    rw [harg] at hcv
    have : Real.exp (θ * D ω) ≤
        h ω + ((Real.exp (θ * (A ω + c)) - Real.exp (θ * A ω)) / c) * D ω := by
      refine hcv.trans (le_of_eq ?_)
      simp only [hh]; field_simp; ring
    calc Z ω * Real.exp (θ * D ω) ≤
          Z ω * (h ω + ((Real.exp (θ * (A ω + c)) - Real.exp (θ * A ω)) / c) * D ω) :=
          mul_le_mul_of_nonneg_left this (hZ0 ω)
      _ = Z ω * h ω + W ω * D ω := by simp only [hW]; ring
  have hhb : ∀ᵐ ω ∂μ, 0 ≤ h ω ∧ h ω ≤ K := by
    filter_upwards [hA] with ω hω
    refine ⟨div_nonneg ?_ hc.le, hoeffding_two_point hc hω.2 hω.1⟩
    have := Real.exp_pos (θ * A ω)
    have := Real.exp_pos (θ * (A ω + c))
    nlinarith [hω.1, hω.2]
  have hZi : Integrable Z μ := Integrable.of_mem_Icc 0 B hZmΩ.aemeasurable
    (by filter_upwards [hZB] with ω h using ⟨hZ0 ω, h⟩)
  have hZnorm : ∀ᵐ ω ∂μ, ‖Z ω‖ ≤ B := by
    filter_upwards [hZB] with ω h
    rw [Real.norm_eq_abs, abs_of_nonneg (hZ0 ω)]; exact h
  have hexpD : Integrable (fun ω => Real.exp (θ * D ω)) μ :=
    integrable_exp_mul_of_mem_Icc hD.aemeasurable hDb
  have hI1 : Integrable (fun ω => Z ω * Real.exp (θ * D ω)) μ :=
    hexpD.bdd_mul hZmΩ.aestronglyMeasurable hZnorm
  have hhm : Measurable h := by simp only [hh]; fun_prop
  have hI2 : Integrable (fun ω => Z ω * h ω) μ := by
    refine (hZi.bdd_mul (f := h) hhm.aestronglyMeasurable (c := K) ?_).congr
      (ae_of_all _ fun ω => mul_comm _ _)
    filter_upwards [hhb] with ω hω
    rw [Real.norm_eq_abs, abs_of_nonneg hω.1]; exact hω.2
  have hWm' : Measurable[m] W := by
    simp only [hW]
    exact hZm.mul ((((hAm.add_const c).const_mul θ).exp.sub (hAm.const_mul θ).exp).div_const c)
  have hWm : Measurable W := hWm'.mono hm le_rfl
  have hWb : ∀ᵐ ω ∂μ, ‖W ω‖ ≤ B * (2 * E / c) := by
    filter_upwards [hZB, hA] with ω hZ hAω
    have h1 := hexp (A ω) (abs_le.2 ⟨by linarith [hAω.1], by linarith [hAω.2, hc]⟩)
    have h2 := hexp (A ω + c) (abs_le.2 ⟨by linarith [hAω.1], by linarith [hAω.2]⟩)
    have h3 := Real.exp_pos (θ * A ω)
    have h4 := Real.exp_pos (θ * (A ω + c))
    rw [Real.norm_eq_abs, hW, abs_mul, abs_div, abs_of_pos hc, abs_of_nonneg (hZ0 ω)]
    apply mul_le_mul hZ _ (by positivity) (le_trans (hZ0 ω) hZ)
    apply div_le_div_of_nonneg_right _ hc.le
    rw [abs_le]; constructor <;> linarith
  have hI3 : Integrable (fun ω => W ω * D ω) μ := hD.bdd_mul hWm.aestronglyMeasurable hWb
  have hWD : ∫ ω, W ω * D ω ∂μ = 0 := by
    calc ∫ ω, W ω * D ω ∂μ = ∫ ω, (μ[W * D | m]) ω ∂μ := (integral_condExp hm).symm
      _ = ∫ ω, (W * μ[D | m]) ω ∂μ :=
          integral_congr_ae (condExp_mul_of_stronglyMeasurable_left hWm'.stronglyMeasurable hI3 hD)
      _ = ∫ ω, (0 : ℝ) ∂μ := integral_congr_ae (by filter_upwards [hDc] with ω h; simp [h])
      _ = 0 := by simp
  calc ∫ ω, Z ω * Real.exp (θ * D ω) ∂μ ≤ ∫ ω, (Z ω * h ω + W ω * D ω) ∂μ :=
        integral_mono_ae hI1 (hI2.add hI3) hpt
    _ = ∫ ω, Z ω * h ω ∂μ + ∫ ω, W ω * D ω ∂μ := integral_add hI2 hI3
    _ = ∫ ω, Z ω * h ω ∂μ := by rw [hWD, add_zero]
    _ ≤ ∫ ω, Z ω * K ∂μ := integral_mono_ae hI2 (hZi.mul_const K)
        (by filter_upwards [hhb] with ω hω using mul_le_mul_of_nonneg_left hω.2 (hZ0 ω))
    _ = K * ∫ ω, Z ω ∂μ := by rw [integral_mul_const, mul_comm]

lemma azuma_mgf {Ω : Type*} [mΩ : MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] {ℱ : Filtration ℕ mΩ} {M : ℕ → Ω → ℝ}
    (hM : Martingale M ℱ μ) (A : ℕ → Ω → ℝ) (c : ℕ → ℝ)
    (hA : ∀ k, Measurable[ℱ k] (A (k + 1))) (θ : ℝ) (n : ℕ)
    (hstep : ∀ k < n, ∀ᵐ ω ∂μ,
      M (k + 1) ω - M k ω ∈ Set.Icc (A (k + 1) ω) (A (k + 1) ω + c (k + 1))) :
    (∀ᵐ ω ∂μ, |M n ω - M 0 ω| ≤ ∑ k ∈ range n, c (k + 1)) ∧
      ∫ ω, Real.exp (θ * (M n ω - M 0 ω)) ∂μ ≤
        Real.exp (θ ^ 2 * (∑ k ∈ range n, c (k + 1) ^ 2) / 8) := by
  induction n with
  | zero => simp
  | succ n ih =>
    obtain ⟨ihb, ihm⟩ := ih (fun k hk => hstep k (by omega))
    have hmn : ℱ n ≤ mΩ := ℱ.le n
    set D : Ω → ℝ := M (n + 1) - M n with hDdef
    have hD : Integrable D μ := (hM.integrable (n + 1)).sub (hM.integrable n)
    have hMn : StronglyMeasurable[ℱ n] (M n) := hM.1 n
    have hDc : μ[D | ℱ n] =ᵐ[μ] 0 := by
      have h1 := condExp_sub (hM.integrable (n + 1)) (hM.integrable n) (ℱ n) (μ := μ)
      have h2 := hM.condExp_ae_eq (Nat.le_succ n)
      have h3 : μ[M n | ℱ n] = M n := condExp_of_stronglyMeasurable hmn hMn (hM.integrable n)
      filter_upwards [h1, h2] with ω h1 h2
      rw [h1, Pi.sub_apply, h2, h3, Pi.zero_apply, sub_self]
    have hDA : ∀ᵐ ω ∂μ, D ω ∈ Set.Icc (A (n + 1) ω) (A (n + 1) ω + c (n + 1)) :=
      hstep n (Nat.lt_succ_self n)
    have hAr := step_range hmn (hA n) hD hDc hDA
    have hc0 : 0 ≤ c (n + 1) := by
      obtain ⟨ω, hω⟩ := hAr.exists
      linarith [hω.1, hω.2]
    have hDb : ∀ᵐ ω ∂μ, |D ω| ≤ c (n + 1) := by
      filter_upwards [hAr, hDA] with ω h1 h2
      rw [abs_le]; constructor <;> linarith [h1.1, h1.2, h2.1, h2.2]
    have hsplit : ∀ ω, M (n + 1) ω - M 0 ω = (M n ω - M 0 ω) + D ω := by
      intro ω; simp only [hDdef, Pi.sub_apply]; ring
    refine ⟨?_, ?_⟩
    · filter_upwards [ihb, hDb] with ω h1 h2
      rw [sum_range_succ, hsplit]
      exact (abs_add_le _ _).trans (add_le_add h1 h2)
    · rcases hc0.eq_or_lt with h0 | hpos
      · have hD0 : ∀ᵐ ω ∂μ, D ω = 0 := by
          filter_upwards [hDb] with ω h
          rw [← h0] at h; exact abs_nonpos_iff.1 h
        rw [sum_range_succ, ← h0]
        calc ∫ ω, Real.exp (θ * (M (n + 1) ω - M 0 ω)) ∂μ
            = ∫ ω, Real.exp (θ * (M n ω - M 0 ω)) ∂μ :=
              integral_congr_ae (by filter_upwards [hD0] with ω h; rw [hsplit, h, add_zero])
          _ ≤ _ := by simpa using ihm
      · set Z : Ω → ℝ := fun ω => Real.exp (θ * (M n ω - M 0 ω)) with hZ
        have hM0 : StronglyMeasurable[ℱ n] (M 0) := (hM.1 0).mono (ℱ.mono (Nat.zero_le n))
        have hZm : Measurable[ℱ n] Z :=
          ((hMn.measurable.sub hM0.measurable).const_mul θ).exp
        have hZB : ∀ᵐ ω ∂μ, Z ω ≤ Real.exp (|θ| * ∑ k ∈ range n, c (k + 1)) := by
          filter_upwards [ihb] with ω h
          apply Real.exp_le_exp.2
          calc θ * (M n ω - M 0 ω) ≤ |θ * (M n ω - M 0 ω)| := le_abs_self _
            _ = |θ| * |M n ω - M 0 ω| := abs_mul _ _
            _ ≤ _ := mul_le_mul_of_nonneg_left h (abs_nonneg _)
        have hstepb := step_mgf hmn (θ := θ) hpos hZm (fun ω => (Real.exp_pos _).le) hZB (hA n)
          hAr hD hDc hDA
        calc ∫ ω, Real.exp (θ * (M (n + 1) ω - M 0 ω)) ∂μ
            = ∫ ω, Z ω * Real.exp (θ * D ω) ∂μ := by
              congr 1; ext ω; rw [hZ, hsplit, ← Real.exp_add]; ring_nf
          _ ≤ Real.exp (θ ^ 2 * c (n + 1) ^ 2 / 8) * ∫ ω, Z ω ∂μ := hstepb
          _ ≤ Real.exp (θ ^ 2 * c (n + 1) ^ 2 / 8) *
                Real.exp (θ ^ 2 * (∑ k ∈ range n, c (k + 1) ^ 2) / 8) :=
              mul_le_mul_of_nonneg_left ihm (Real.exp_pos _).le
          _ = _ := by rw [← Real.exp_add, sum_range_succ]; ring_nf

lemma tails_of_subgaussian {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] {Y : Ω → ℝ} {V : ℝ} (hV : 0 ≤ V)
    (h : HasSubgaussianMGF Y ⟨V / 4, div_nonneg hV (by norm_num)⟩ μ) {t : ℝ} (ht : 0 < t) :
    μ.real {ω | t ≤ Y ω} ≤ Real.exp (-2 * t ^ 2 / V) ∧
      μ.real {ω | Y ω ≤ -t} ≤ Real.exp (-2 * t ^ 2 / V) ∧
      μ.real {ω | t ≤ |Y ω|} ≤ 2 * Real.exp (-2 * t ^ 2 / V) := by
  have hexpeq : Real.exp (-t ^ 2 / (2 * ((⟨V / 4, div_nonneg hV (by norm_num)⟩ : NNReal) : ℝ))) =
      Real.exp (-2 * t ^ 2 / V) := by
    congr 1
    show -t ^ 2 / (2 * (V / 4)) = -2 * t ^ 2 / V
    rcases hV.eq_or_lt with h0 | hpos
    · rw [← h0]; simp
    · field_simp; ring
  have h1 : μ.real {ω | t ≤ Y ω} ≤ Real.exp (-2 * t ^ 2 / V) := by
    rw [← hexpeq]; exact h.measure_ge_le ht.le
  have hset : {ω | Y ω ≤ -t} = {ω | t ≤ (-Y) ω} := by
    ext ω; simp only [Set.mem_ofPred_eq, Pi.neg_apply]; constructor <;> intro h <;> linarith
  have h2 : μ.real {ω | Y ω ≤ -t} ≤ Real.exp (-2 * t ^ 2 / V) := by
    rw [hset, ← hexpeq]; exact h.neg.measure_ge_le ht.le
  refine ⟨h1, h2, ?_⟩
  calc μ.real {ω | t ≤ |Y ω|} ≤ μ.real ({ω | t ≤ Y ω} ∪ {ω | Y ω ≤ -t}) := by
        refine measureReal_mono ?_ (measure_ne_top _ _)
        intro ω hω
        simp only [Set.mem_ofPred_eq] at hω
        simp only [Set.mem_union, Set.mem_ofPred_eq]
        rcases le_abs'.1 hω with h | h
        · right; exact h
        · left; exact h
    _ ≤ μ.real {ω | t ≤ Y ω} + μ.real {ω | Y ω ≤ -t} := measureReal_union_le _ _
    _ ≤ _ := by linarith


universe u

lemma bdd_of_bdd_diff {ι : Type*} [Fintype ι] [DecidableEq ι] {β : ι → Type*}
    (f : ((i : ι) → β i) → ℝ) (c : ι → ℝ)
    (hc : ∀ i (x y : (j : ι) → β j), (∀ j, j ≠ i → x j = y j) → |f x - f y| ≤ c i)
    (x y : (j : ι) → β j) : |f x - f y| ≤ ∑ i, c i := by
  have key : ∀ s : Finset ι, ∀ x y : (j : ι) → β j, (∀ j, j ∉ s → x j = y j) →
      |f x - f y| ≤ ∑ i ∈ s, c i := by
    intro s
    induction s using Finset.induction_on with
    | empty =>
      intro x y h
      have : x = y := funext fun j => h j (Finset.notMem_empty j)
      simp [this]
    | insert i s hi ih =>
      intro x y h
      rw [sum_insert hi]
      set z := Function.update x i (y i) with hz
      have h1 : |f x - f z| ≤ c i :=
        hc i x z (fun j hj => by rw [hz, Function.update_of_ne hj])
      have h2 : |f z - f y| ≤ ∑ i ∈ s, c i := ih z y (fun j hj => by
        by_cases hji : j = i
        · subst hji; simp [hz]
        · rw [hz, Function.update_of_ne hji]; exact h j (by simp [hji, hj]))
      calc |f x - f y| = |(f x - f z) + (f z - f y)| := by ring_nf
        _ ≤ |f x - f z| + |f z - f y| := abs_add_le _ _
        _ ≤ _ := add_le_add h1 h2
  simpa using key univ x y (fun j hj => absurd (mem_univ j) hj)

lemma mcd_pi_mgf (θ : ℝ) : ∀ (n : ℕ) {β : Fin n → Type u} [∀ i, MeasurableSpace (β i)]
    (ν : (i : Fin n) → Measure (β i)) [∀ i, IsProbabilityMeasure (ν i)]
    (f : ((i : Fin n) → β i) → ℝ), Measurable f → ∀ (c : Fin n → ℝ),
    (∀ i (x y : (j : Fin n) → β j), (∀ j, j ≠ i → x j = y j) → |f x - f y| ≤ c i) →
    ∫ x, Real.exp (θ * (f x - ∫ y, f y ∂Measure.pi ν)) ∂Measure.pi ν ≤
      Real.exp (θ ^ 2 * (∑ i, c i ^ 2) / 8) := by
  intro n
  induction n with
  | zero =>
    intro β _ ν _ f hf c hc
    have h1 : ∀ x, f x - ∫ y, f y ∂Measure.pi ν = 0 := by
      intro x
      have : ∀ y, f y = f x := fun y => congrArg f (Subsingleton.elim y x)
      simp [this]
    simp [h1]
  | succ n ih =>
    intro β _ ν _ f hf c hc
    set e := MeasurableEquiv.piFinSuccAbove β 0 with he
    have hmp := measurePreserving_piFinSuccAbove ν 0
    set P := Measure.pi (fun j : Fin n => ν (Fin.succAbove 0 j)) with hP
    set F : β 0 × ((j : Fin n) → β (Fin.succAbove 0 j)) → ℝ := fun z => f (e.symm z) with hFdef
    have hF : Measurable F := hf.comp e.symm.measurable
    have htrans : ∀ G : ((i : Fin (n + 1)) → β i) → ℝ,
        ∫ x, G x ∂Measure.pi ν = ∫ z, G (e.symm z) ∂((ν 0).prod P) :=
      fun G => ((hmp.symm e).integral_comp' G).symm
    have : ∀ i, Nonempty (β i) := fun i => nonempty_of_isProbabilityMeasure (ν i)
    obtain ⟨x0⟩ : Nonempty ((i : Fin (n + 1)) → β i) := inferInstance
    set S := ∑ i, c i with hS
    have hFb : ∀ z, F z ∈ Set.Icc (f x0 - S) (f x0 + S) := fun z => by
      have := bdd_of_bdd_diff f c hc (e.symm z) x0
      rw [abs_le] at this; constructor <;> linarith [this.1, this.2]
    have hsymm : ∀ x y, e.symm (x, y) = Fin.insertNth 0 x y := fun _ _ => rfl
    have hF0 : ∀ x x' y, |F (x, y) - F (x', y)| ≤ c 0 := by
      intro x x' y
      apply hc 0
      intro i hi
      rcases Fin.eq_self_or_eq_succAbove 0 i with h | ⟨j, rfl⟩
      · exact absurd h hi
      · rw [hsymm, hsymm, Fin.insertNth_apply_succAbove, Fin.insertNth_apply_succAbove]
    have hF1 : ∀ j x (y y' : (j : Fin n) → β (Fin.succAbove 0 j)),
        (∀ j', j' ≠ j → y j' = y' j') → |F (x, y) - F (x, y')| ≤ c (Fin.succAbove 0 j) := by
      intro j x y y' hyy
      apply hc
      intro i hi
      rcases Fin.eq_self_or_eq_succAbove 0 i with rfl | ⟨j', rfl⟩
      · rw [hsymm, hsymm, Fin.insertNth_apply_same, Fin.insertNth_apply_same]
      · rw [hsymm, hsymm, Fin.insertNth_apply_succAbove, Fin.insertNth_apply_succAbove]
        exact hyy j' (fun h => hi (by rw [h]))
    set g : ((j : Fin n) → β (Fin.succAbove 0 j)) → ℝ := fun y => ∫ x, F (x, y) ∂(ν 0)
      with hgdef
    have hg : Measurable g := (hF.stronglyMeasurable.integral_prod_left' (μ := ν 0)).measurable
    have hFi : ∀ y, Integrable (fun x => F (x, y)) (ν 0) := fun y =>
      Integrable.of_mem_Icc (f x0 - S) (f x0 + S) (hF.comp measurable_prodMk_right).aemeasurable
        (ae_of_all _ fun x => hFb (x, y))
    have hgc : ∀ j (y y' : (j : Fin n) → β (Fin.succAbove 0 j)), (∀ j', j' ≠ j → y j' = y' j') →
        |g y - g y'| ≤ c (Fin.succAbove 0 j) := by
      intro j y y' hyy
      simp only [hgdef]
      rw [← integral_sub (hFi y) (hFi y')]
      have := norm_integral_le_of_norm_le_const (μ := ν 0) (C := c (Fin.succAbove 0 j))
        (f := fun x => F (x, y) - F (x, y'))
        (ae_of_all _ fun x => by rw [Real.norm_eq_abs]; exact hF1 j x y y' hyy)
      simpa using this
    have hIH := ih (fun j => ν (Fin.succAbove 0 j)) g hg (fun j => c (Fin.succAbove 0 j)) hgc
    set m := ∫ x, f x ∂Measure.pi ν with hm
    have hFint : Integrable F ((ν 0).prod P) :=
      Integrable.of_mem_Icc _ _ hF.aemeasurable (ae_of_all _ hFb)
    have hmg : m = ∫ y, g y ∂P := by
      rw [hm, htrans f]
      exact integral_prod_symm F hFint
    set K0 := Real.exp (θ ^ 2 * c 0 ^ 2 / 8) with hK0
    have hinner : ∀ y, ∫ x, Real.exp (θ * (F (x, y) - m)) ∂(ν 0) ≤
        Real.exp (θ * (g y - m)) * K0 := by
      intro y
      have hbdd : BddBelow (Set.range fun x => F (x, y)) :=
        ⟨f x0 - S, by rintro _ ⟨x, rfl⟩; exact (hFb _).1⟩
      set a := ⨅ x, F (x, y) with ha
      have hIcc : ∀ x, F (x, y) ∈ Set.Icc a (a + c 0) := by
        intro x
        refine ⟨ciInf_le hbdd x, ?_⟩
        have : F (x, y) - c 0 ≤ a := le_ciInf fun x' => by
          have := hF0 x x' y; rw [abs_le] at this; linarith [this.2]
        linarith
      have hH := (hasSubgaussianMGF_of_mem_Icc (μ := ν 0) (X := fun x => F (x, y))
        (hF.comp measurable_prodMk_right).aemeasurable (ae_of_all _ hIcc)).mgf_le θ
      have hK : Real.exp (((‖a + c 0 - a‖₊ / 2) ^ 2 : NNReal) * θ ^ 2 / 2) = K0 := by
        rw [hK0]
        congr 1
        simp only [NNReal.coe_pow, NNReal.coe_div, coe_nnnorm, Real.norm_eq_abs,
          add_sub_cancel_left]
        push_cast
        rw [div_pow, sq_abs]; ring
      rw [hK] at hH
      calc ∫ x, Real.exp (θ * (F (x, y) - m)) ∂(ν 0)
          = ∫ x, Real.exp (θ * (g y - m)) * Real.exp (θ * (F (x, y) - g y)) ∂(ν 0) := by
            congr 1; ext x; rw [← Real.exp_add]; ring_nf
        _ = Real.exp (θ * (g y - m)) * ∫ x, Real.exp (θ * (F (x, y) - g y)) ∂(ν 0) :=
            integral_const_mul _ _
        _ ≤ Real.exp (θ * (g y - m)) * K0 := mul_le_mul_of_nonneg_left hH (Real.exp_pos _).le
    set y0 : (j : Fin n) → β (Fin.succAbove 0 j) := fun j => x0 (Fin.succAbove 0 j)
    set S' := ∑ j : Fin n, c (Fin.succAbove 0 j)
    have hgi : Integrable (fun y => Real.exp (θ * (g y - m))) P := by
      refine integrable_exp_mul_of_mem_Icc (a := g y0 - S' - m) (b := g y0 + S' - m)
        (hg.sub_const m).aemeasurable (ae_of_all _ fun y => ?_)
      have := bdd_of_bdd_diff g (fun j => c (Fin.succAbove 0 j)) hgc y y0
      rw [abs_le] at this; constructor <;> linarith [this.1, this.2]
    have hexpi : Integrable (fun z => Real.exp (θ * (F z - m))) ((ν 0).prod P) :=
      integrable_exp_mul_of_mem_Icc (a := f x0 - S - m) (b := f x0 + S - m)
        (hF.sub_const m).aemeasurable
        (ae_of_all _ fun z => ⟨by linarith [(hFb z).1], by linarith [(hFb z).2]⟩)
    calc ∫ x, Real.exp (θ * (f x - m)) ∂Measure.pi ν
        = ∫ z, Real.exp (θ * (F z - m)) ∂((ν 0).prod P) :=
          htrans (fun x => Real.exp (θ * (f x - m)))
      _ = ∫ y, ∫ x, Real.exp (θ * (F (x, y) - m)) ∂(ν 0) ∂P := integral_prod_symm _ hexpi
      _ ≤ ∫ y, Real.exp (θ * (g y - m)) * K0 ∂P :=
          integral_mono_of_nonneg
            (ae_of_all _ fun y => integral_nonneg fun x => (Real.exp_pos _).le)
            (hgi.mul_const K0) (ae_of_all _ hinner)
      _ = (∫ y, Real.exp (θ * (g y - m)) ∂P) * K0 := integral_mul_const _ _
      _ ≤ Real.exp (θ ^ 2 * (∑ j : Fin n, c (Fin.succAbove 0 j) ^ 2) / 8) * K0 := by
          apply mul_le_mul_of_nonneg_right _ (Real.exp_pos _).le
          rw [hmg]; exact hIH
      _ = Real.exp (θ ^ 2 * (∑ i, c i ^ 2) / 8) := by
          rw [hK0, ← Real.exp_add, Fin.sum_univ_succAbove _ 0]; ring_nf

#print axioms hoeffding_two_point
#print axioms pos_on_null
#print axioms step_range
#print axioms step_mgf
#print axioms azuma_mgf
#print axioms tails_of_subgaussian
#print axioms bdd_of_bdd_diff
#print axioms mcd_pi_mgf

/-- **The Azuma-Hoeffding inequality.** Let `M 0, M 1, …, M n` be a martingale for the filtration
`ℱ` (`ℱ k` is what is known after step `k`). Suppose each step `M (k+1) - M k` is sure to lie in an
interval `[A (k+1), A (k+1) + c (k+1)]` whose bottom `A (k+1)` may depend on the past (it is known
at step `k`) but whose width `c (k+1)` is a number fixed in advance. Then for every distance
`t > 0`, with `V = c 1 ^ 2 + … + c n ^ 2` the sum of squared widths:
the martingale ends at least `t` above its start with chance at most `exp (-2 t² / V)`,
ends at least `t` below its start with the same ceiling, and strays `t` or more either way with
chance at most twice that. -/
theorem azuma_hoeffding {Ω : Type*} [mΩ : MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] {ℱ : Filtration ℕ mΩ} {M : ℕ → Ω → ℝ}
    (hM : Martingale M ℱ μ) (n : ℕ) (A : ℕ → Ω → ℝ) (c : ℕ → ℝ)
    (hA : ∀ k, Measurable[ℱ k] (A (k + 1)))
    (hstep : ∀ k < n, ∀ᵐ ω ∂μ,
      M (k + 1) ω - M k ω ∈ Set.Icc (A (k + 1) ω) (A (k + 1) ω + c (k + 1)))
    {t : ℝ} (ht : 0 < t) :
    μ.real {ω | t ≤ M n ω - M 0 ω} ≤
        Real.exp (-2 * t ^ 2 / ∑ k ∈ range n, c (k + 1) ^ 2) ∧
      μ.real {ω | M n ω - M 0 ω ≤ -t} ≤
        Real.exp (-2 * t ^ 2 / ∑ k ∈ range n, c (k + 1) ^ 2) ∧
      μ.real {ω | t ≤ |M n ω - M 0 ω|} ≤
        2 * Real.exp (-2 * t ^ 2 / ∑ k ∈ range n, c (k + 1) ^ 2) := by
  have hV : 0 ≤ ∑ k ∈ range n, c (k + 1) ^ 2 := sum_nonneg (fun _ _ => sq_nonneg _)
  apply tails_of_subgaussian hV _ ht
  have hb := (azuma_mgf hM A c hA 0 n hstep).1
  refine ⟨fun θ => ?_, fun θ => ?_⟩
  · refine integrable_exp_mul_of_mem_Icc
      (a := -∑ k ∈ range n, c (k + 1)) (b := ∑ k ∈ range n, c (k + 1))
      ((hM.integrable n).aemeasurable.sub (hM.integrable 0).aemeasurable) ?_
    filter_upwards [hb] with ω h
    exact abs_le.1 h
  · refine (azuma_mgf hM A c hA θ n hstep).2.trans (le_of_eq ?_)
    congr 1
    show _ = (∑ k ∈ range n, c (k + 1) ^ 2) / 4 * θ ^ 2 / 2
    ring

/-- **McDiarmid's inequality** (the bounded-differences inequality). Let `X 0, …, X (n-1)` be
independent inputs and `f` a function of all of them. Suppose changing input `i` alone, with every
other input held fixed, changes `f` by at most `c i`. Then for every distance `t > 0`, the chance
that `f (X 0, …, X (n-1))` misses its average by `t` or more is at most
`2 exp (-2 t² / (c 0 ^ 2 + … + c (n-1) ^ 2))`. -/
theorem mcdiarmid_bounded_differences {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] {n : ℕ} {β : Fin n → Type*} [∀ i, MeasurableSpace (β i)]
    {X : (i : Fin n) → Ω → β i} (hX : ∀ i, Measurable (X i)) (hind : iIndepFun X μ)
    {f : ((i : Fin n) → β i) → ℝ} (hf : Measurable f) (c : Fin n → ℝ)
    (hc : ∀ i (x y : (j : Fin n) → β j), (∀ j, j ≠ i → x j = y j) → |f x - f y| ≤ c i)
    {t : ℝ} (ht : 0 < t) :
    μ.real {ω | t ≤ |f (fun i => X i ω) - ∫ ω', f (fun i => X i ω') ∂μ|} ≤
      2 * Real.exp (-2 * t ^ 2 / ∑ i, c i ^ 2) := by
  set Xv : Ω → ((i : Fin n) → β i) := fun ω i => X i ω with hXvdef
  have hXv : Measurable Xv := Measurable.of_eval hX
  have hlaw : μ.map Xv = Measure.pi (fun i => μ.map (X i)) :=
    hind.map_fun_eq_pi_map (fun i => (hX i).aemeasurable)
  set π := Measure.pi (fun i => μ.map (X i)) with hπ
  have hmean : ∫ ω', f (Xv ω') ∂μ = ∫ x, f x ∂π := by
    rw [← hlaw, integral_map hXv.aemeasurable hf.aestronglyMeasurable]
  set m := ∫ x, f x ∂π with hm
  have hV : 0 ≤ ∑ i, c i ^ 2 := sum_nonneg (fun _ _ => sq_nonneg _)
  obtain ⟨ω0⟩ : Nonempty Ω := nonempty_of_isProbabilityMeasure μ
  have hsgπ : HasSubgaussianMGF (fun x => f x - m)
      ⟨(∑ i, c i ^ 2) / 4, div_nonneg hV (by norm_num)⟩ π := by
    refine ⟨fun θ => ?_, fun θ => ?_⟩
    · refine integrable_exp_mul_of_mem_Icc (a := f (Xv ω0) - (∑ i, c i) - m)
        (b := f (Xv ω0) + (∑ i, c i) - m) (hf.sub_const m).aemeasurable (ae_of_all _ fun x => ?_)
      have := bdd_of_bdd_diff f c hc x (Xv ω0)
      rw [abs_le] at this; constructor <;> linarith [this.1, this.2]
    · refine (mcd_pi_mgf θ n _ f hf c hc).trans (le_of_eq ?_)
      congr 1
      show _ = (∑ i, c i ^ 2) / 4 * θ ^ 2 / 2
      ring
  have hsgμ : HasSubgaussianMGF ((fun x => f x - m) ∘ Xv)
      ⟨(∑ i, c i ^ 2) / 4, div_nonneg hV (by norm_num)⟩ μ :=
    HasSubgaussianMGF.of_map hXv.aemeasurable (by rw [hlaw]; exact hsgπ)
  rw [hmean]
  exact (tails_of_subgaussian hV hsgμ ht).2.2

/-- **One ball moves the empty-box count by at most 1.** Throw `n` balls into `m` boxes: ball `j`
lands in box `x j`. If two throws `x` and `y` differ only in where ball `i` lands, then the numbers
of empty boxes (boxes no ball lands in) differ by at most 1: the old box may empty, the new box may
fill. This is the bounded difference `c i = 1` that McDiarmid's inequality uses for the boxes. -/
theorem empty_boxes_change_by_at_most_one {n m : ℕ} (x y : Fin n → Fin m) (i : Fin n)
    (h : ∀ j, j ≠ i → x j = y j) :
    |((univ.image x)ᶜ.card : ℝ) - ((univ.image y)ᶜ.card : ℝ)| ≤ 1 := by
  have key : ∀ (x y : Fin n → Fin m), (∀ j, j ≠ i → x j = y j) →
      (univ.image x).card ≤ (univ.image y).card + 1 := by
    intro x y h
    calc (univ.image x).card ≤ (insert (x i) (univ.image y)).card := by
          apply card_le_card
          intro b hb
          simp only [mem_image, mem_univ, true_and] at hb
          obtain ⟨j, rfl⟩ := hb
          rw [mem_insert]
          by_cases hj : j = i
          · left; rw [hj]
          · right; rw [h j hj]; exact mem_image_of_mem _ (mem_univ _)
      _ ≤ _ := card_insert_le _ _
  have h1 : ((univ.image x).card : ℝ) ≤ (univ.image y).card + 1 := by exact_mod_cast key x y h
  have h2 : ((univ.image y).card : ℝ) ≤ (univ.image x).card + 1 := by
    exact_mod_cast key y x (fun j hj => (h j hj).symm)
  rw [card_compl, card_compl]
  have hx : (univ.image x).card ≤ Fintype.card (Fin m) := card_le_univ _
  have hy : (univ.image y).card ≤ Fintype.card (Fin m) := card_le_univ _
  rw [Nat.cast_sub hx, Nat.cast_sub hy, abs_le]
  constructor <;> linarith

-- The gambler: 100 rounds, steps of width 2, target 30. Sum of squared widths and the exponent.
example : ∑ _k ∈ range 100, (2 : ℚ) ^ 2 = 400 := by norm_num
example : (2 * 30 ^ 2 : ℚ) / 400 = 9 / 2 := by norm_num
-- The best tilt 4t/V = 0.3 makes the exponent -θt + θ²V/8 equal to -9 + 4.5 = -4.5.
example : (4 * 30 : ℚ) / 400 = 3 / 10 := by norm_num
example : -(3 / 10 : ℚ) * 30 + (3 / 10) ^ 2 * 400 / 8 = -9 / 2 := by norm_num
-- A gain of 30 in 100 rounds means 65 heads or more; the exact chance rounds to 0.001759.
example : (100 + 30) / 2 = 65 := by decide
example : 17585 * 2 ^ 100 ≤ (∑ k ∈ Icc 65 100, Nat.choose 100 k) * 10 ^ 7 ∧
    (∑ k ∈ Icc 65 100, Nat.choose 100 k) * 10 ^ 7 < 17595 * 2 ^ 100 := by
  simp only [Nat.choose_eq_descFactorial_div_factorial]
  decide
-- The boxes: 100 balls, each moving the count by at most 1, distance 15: exponent 2·15²/100 = 4.5.
example : ∑ _i ∈ range 100, (1 : ℚ) ^ 2 = 100 := by norm_num
example : (2 * 15 ^ 2 : ℚ) / 100 = 9 / 2 := by norm_num
-- The 50 independent pairs: exponent 2·15²/50 = 9, so the ceiling is 2e^(-9).
example : (2 * 15 ^ 2 : ℚ) / 50 = 9 := by norm_num
-- Mistakes: the half-width as width gives exponent 2·900/100 = 18; widths not squared, 2·900/200 = 9.
example : (2 * 30 ^ 2 : ℚ) / 100 = 18 := by norm_num
example : (2 * 30 ^ 2 : ℚ) / 200 = 9 := by norm_num
-- The doubling gambler: stakes 1, 2, …, 64 lose 127 in one bust; her worst path over 100 rounds is
-- 14 busts and then losses of 1 and 2, so her steps reach width 128.
example : ∑ k ∈ range 7, 2 ^ k = 127 := by decide
example : 127 * (100 / 7) + 2 ^ (100 % 7) - 1 = 1781 := by decide
example : 2 * 64 = 128 := by decide
-- Try changing: 400 rounds at target 30 gives exponent 1.125; target 40 in 100 rounds gives 8.
example : (2 * 30 ^ 2 : ℚ) / (400 * 2 ^ 2) = 9 / 8 := by norm_num
example : (2 * 40 ^ 2 : ℚ) / (100 * 2 ^ 2) = 8 := by norm_num

#print axioms azuma_hoeffding
#print axioms mcdiarmid_bounded_differences
#print axioms empty_boxes_change_by_at_most_one
