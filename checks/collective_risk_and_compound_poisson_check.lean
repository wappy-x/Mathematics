-- Aggregate claims: a Poisson number of independent, identically distributed claims, independent of the count, has total with mean "expected count × average claim" and variance "expected count × average squared claim"; for any count the variance splits into a size part and a count part; and the Pareto tail index that best fits the large claims is k divided by the sum of ln(x_i / u).
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Probability.HasLaw
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Exponential

open MeasureTheory ProbabilityTheory Real
open scoped NNReal

variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]

lemma poisson_hasSum_exp_aux (r : ℝ≥0) :
    HasSum (fun n : ℕ => (r : ℝ) ^ n / (n.factorial)) (exp r) := by
  rw [exp_eq_exp_ℝ]; exact NormedSpace.expSeries_div_hasSum_exp (r : ℝ)

lemma poisson_hasSum_mean_aux (r : ℝ≥0) :
    HasSum (fun n : ℕ => (n : ℝ) * ((r : ℝ) ^ n / (n.factorial))) (r * exp r) := by
  rw [← hasSum_nat_add_iff' 1]
  simp only [Finset.range_one, Finset.sum_singleton, Nat.cast_zero, zero_mul, sub_zero]
  convert (poisson_hasSum_exp_aux r).mul_left (r : ℝ) using 1
  funext n
  rw [Nat.factorial_succ]; push_cast
  field_simp; ring

lemma poisson_hasSum_sq_aux (r : ℝ≥0) :
    HasSum (fun n : ℕ => (n : ℝ) ^ 2 * ((r : ℝ) ^ n / (n.factorial)))
      (r * (r * exp r + exp r)) := by
  rw [← hasSum_nat_add_iff' 1]
  simp only [Finset.range_one, Finset.sum_singleton, Nat.cast_zero]
  convert ((poisson_hasSum_mean_aux r).add (poisson_hasSum_exp_aux r)).mul_left (r : ℝ) using 1
  · funext n
    rw [Nat.factorial_succ]; push_cast
    field_simp; ring
  · simp

lemma poisson_moments_aux (lam : ℝ≥0) (N : Ω → ℕ) (hN : HasLaw N (poissonMeasure lam) P) :
    MemLp (fun ω => (N ω : ℝ)) 2 P ∧ ∫ ω, (N ω : ℝ) ∂P = lam ∧
      variance (fun ω => (N ω : ℝ)) P = lam := by
  have hee : exp (-(lam : ℝ)) * exp (lam : ℝ) = 1 := by rw [← exp_add]; simp
  have hmean : HasSum (fun n : ℕ => (exp (-(lam : ℝ)) * (lam : ℝ) ^ n / (n.factorial)) • (n : ℝ))
      (lam : ℝ) := by
    convert (poisson_hasSum_mean_aux lam).mul_left (exp (-(lam : ℝ))) using 1
    · funext n; simp only [smul_eq_mul]; ring
    · linear_combination (-(lam : ℝ)) * hee
  have hsq : HasSum (fun n : ℕ => (exp (-(lam : ℝ)) * (lam : ℝ) ^ n / (n.factorial)) • ((n : ℝ) ^ 2))
      ((lam : ℝ) ^ 2 + lam) := by
    convert (poisson_hasSum_sq_aux lam).mul_left (exp (-(lam : ℝ))) using 1
    · funext n; simp only [smul_eq_mul]; ring
    · linear_combination (-((lam : ℝ) ^ 2 + lam)) * hee
  have hint2 : Integrable (fun n : ℕ => (n : ℝ) ^ 2) (poissonMeasure lam) := by
    rw [integrable_poissonMeasure_iff]
    convert hsq.summable using 1
    funext n
    simp [smul_eq_mul]
  have hmem : MemLp (fun n : ℕ => (n : ℝ)) 2 (poissonMeasure lam) :=
    (memLp_two_iff_integrable_sq .of_discrete).2 hint2
  have hmemN : MemLp (fun ω => (N ω : ℝ)) 2 P := hN.memLp_comp hmem
  have hE1 : ∫ ω, (N ω : ℝ) ∂P = lam := by
    have h := hN.integral_comp (f := fun n : ℕ => (n : ℝ)) .of_discrete
    simp only [Function.comp_def] at h
    rw [h, integral_poissonMeasure, hmean.tsum_eq]
  have hE2 : ∫ ω, (N ω : ℝ) ^ 2 ∂P = (lam : ℝ) ^ 2 + lam := by
    have h := hN.integral_comp (f := fun n : ℕ => (n : ℝ) ^ 2) .of_discrete
    simp only [Function.comp_def] at h
    rw [h, integral_poissonMeasure, hsq.tsum_eq]
  refine ⟨hmemN, hE1, ?_⟩
  have hV := variance_eq_sub hmemN
  simp only [Pi.pow_apply] at hV
  rw [hV, hE1, hE2]
  ring

lemma compound_split_aux (N : Ω → ℕ) (X : ℕ → Ω → ℝ)
    (hN_meas : Measurable N) (hX_meas : ∀ i, Measurable (X i))
    (hN_sq : MemLp (fun ω => (N ω : ℝ)) 2 P)
    (hX_ident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hX_indep : iIndepFun X P)
    (hNX_indep : IndepFun N (fun ω i => X i ω) P)
    (hX_sq : MemLp (X 0) 2 P) :
    MemLp (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) 2 P ∧
      ∫ ω, (∑ i ∈ Finset.range (N ω), X i ω) ∂P
        = (∫ ω, (N ω : ℝ) ∂P) * ∫ ω, X 0 ω ∂P ∧
      variance (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) P
        = (∫ ω, (N ω : ℝ) ∂P) * variance (X 0) P
          + variance (fun ω => (N ω : ℝ)) P * (∫ ω, X 0 ω ∂P) ^ 2 := by
  set m := ∫ ω, X 0 ω ∂P with hm
  set v := variance (X 0) P with hv
  have hXmem : ∀ i, MemLp (X i) 2 P := fun i => (hX_ident i).memLp_iff.2 hX_sq
  have hSn_mem : ∀ n : ℕ, MemLp (fun ω => ∑ i ∈ Finset.range n, X i ω) 2 P :=
    fun n => memLp_finsetSum _ (fun i _ => hXmem i)
  have hSn_int : ∀ n : ℕ, ∫ ω, ∑ i ∈ Finset.range n, X i ω ∂P = n * m := by
    intro n
    rw [integral_finsetSum _ (fun i _ => (hXmem i).integrable one_le_two)]
    rw [Finset.sum_congr rfl (fun i _ => (hX_ident i).integral_eq)]
    rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
  have hSn_var : ∀ n : ℕ, variance (fun ω => ∑ i ∈ Finset.range n, X i ω) P = n * v := by
    intro n
    have h := IndepFun.variance_sum (X := X) (s := Finset.range n) (μ := P)
      (fun i _ => hXmem i) (fun i _ j _ hij => hX_indep.indepFun hij)
    rw [show (fun ω => ∑ i ∈ Finset.range n, X i ω) = ∑ i ∈ Finset.range n, X i from by
      ext ω; simp, h]
    rw [Finset.sum_congr rfl (fun i _ => (hX_ident i).variance_eq)]
    rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
  have hSn_sq : ∀ n : ℕ, ∫ ω, (∑ i ∈ Finset.range n, X i ω) ^ 2 ∂P = n * v + (n * m) ^ 2 := by
    intro n
    have h := variance_eq_sub (hSn_mem n)
    rw [hSn_var, hSn_int] at h
    simp only [Pi.pow_apply] at h
    linarith
  set Xs : Ω → (ℕ → ℝ) := fun ω i => X i ω with hXs_def
  have hXs : Measurable Xs := Measurable.of_eval hX_meas
  have hprod := (indepFun_iff_map_prod_eq_prod_map_map hN_meas.aemeasurable
    hXs.aemeasurable).1 hNX_indep
  set μN := P.map N with hμN
  set μX := P.map Xs with hμX
  let F : ℕ × (ℕ → ℝ) → ℝ := fun p => ∑ i ∈ Finset.range p.1, p.2 i
  have hF : Measurable F := measurable_from_prod_countable_right
    (fun n => by
      show Measurable (fun y : ℕ → ℝ => ∑ i ∈ Finset.range n, y i)
      exact Finset.measurable_sum _ (fun i _ => measurable_pi_apply i))
  have hpair : Measurable (fun ω => (N ω, Xs ω)) := hN_meas.prodMk hXs
  have hFn : ∀ n : ℕ, Measurable (fun y => F (n, y)) := fun n => hF.comp measurable_prodMk_left
  have hin1 : ∀ n : ℕ, ∫ y, F (n, y) ∂μX = n * m := by
    intro n
    rw [integral_map hXs.aemeasurable (hFn n).aestronglyMeasurable]
    exact hSn_int n
  have hin2 : ∀ n : ℕ, ∫ y, F (n, y) ^ 2 ∂μX = n * v + (n * m) ^ 2 := by
    intro n
    rw [integral_map hXs.aemeasurable ((hFn n).pow_const 2).aestronglyMeasurable]
    exact hSn_sq n
  have hint_in2 : ∀ n : ℕ, Integrable (fun y => F (n, y) ^ 2) μX := by
    intro n
    rw [integrable_map_measure ((hFn n).pow_const 2).aestronglyMeasurable hXs.aemeasurable]
    exact (hSn_mem n).integrable_sq
  have hNint1 : Integrable (fun ω => (N ω : ℝ)) P := hN_sq.integrable one_le_two
  have hNint2 : Integrable (fun ω => (N ω : ℝ) ^ 2) P := hN_sq.integrable_sq
  have hF2int : Integrable (fun p => F p ^ 2) (μN.prod μX) := by
    rw [integrable_prod_iff ((hF.pow_const 2).aestronglyMeasurable)]
    refine ⟨Filter.Eventually.of_forall hint_in2, ?_⟩
    have h : (fun n => ∫ y, ‖F (n, y) ^ 2‖ ∂μX) = fun n : ℕ => (n : ℝ) * v + ((n : ℝ) * m) ^ 2 := by
      funext n
      simp only [norm_pow, Real.norm_eq_abs, sq_abs]
      exact hin2 n
    rw [h, integrable_map_measure .of_discrete hN_meas.aemeasurable]
    show Integrable (fun ω => (N ω : ℝ) * v + ((N ω : ℝ) * m) ^ 2) P
    refine ((hNint1.mul_const v).add (hNint2.mul_const (m ^ 2))).congr
      (Filter.Eventually.of_forall fun ω => ?_)
    simp only [Pi.add_apply]
    ring
  have hFmem : MemLp F 2 (μN.prod μX) :=
    (memLp_two_iff_integrable_sq hF.aestronglyMeasurable).2 hF2int
  have hFint : Integrable F (μN.prod μX) := hFmem.integrable one_le_two
  have hSmem : MemLp (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) 2 P := by
    have h := (memLp_map_measure_iff hF.aestronglyMeasurable hpair.aemeasurable (p := 2)).1
      (by rw [hprod]; exact hFmem)
    exact h
  have hES : ∫ ω, (∑ i ∈ Finset.range (N ω), X i ω) ∂P = (∫ ω, (N ω : ℝ) ∂P) * m := by
    calc ∫ ω, (∑ i ∈ Finset.range (N ω), X i ω) ∂P
        = ∫ p, F p ∂(P.map (fun ω => (N ω, Xs ω))) :=
          (integral_map hpair.aemeasurable hF.aestronglyMeasurable).symm
      _ = ∫ p, F p ∂(μN.prod μX) := by rw [hprod]
      _ = ∫ n, ∫ y, F (n, y) ∂μX ∂μN := integral_prod _ hFint
      _ = ∫ n, (n : ℝ) * m ∂μN := by simp_rw [hin1]
      _ = ∫ ω, (N ω : ℝ) * m ∂P := integral_map hN_meas.aemeasurable .of_discrete
      _ = (∫ ω, (N ω : ℝ) ∂P) * m := integral_mul_const _ _
  have hES2 : ∫ ω, (∑ i ∈ Finset.range (N ω), X i ω) ^ 2 ∂P
      = (∫ ω, (N ω : ℝ) ∂P) * v + (∫ ω, (N ω : ℝ) ^ 2 ∂P) * m ^ 2 := by
    calc ∫ ω, (∑ i ∈ Finset.range (N ω), X i ω) ^ 2 ∂P
        = ∫ p, F p ^ 2 ∂(P.map (fun ω => (N ω, Xs ω))) :=
          (integral_map hpair.aemeasurable (hF.pow_const 2).aestronglyMeasurable).symm
      _ = ∫ p, F p ^ 2 ∂(μN.prod μX) := by rw [hprod]
      _ = ∫ n, ∫ y, F (n, y) ^ 2 ∂μX ∂μN := integral_prod _ hF2int
      _ = ∫ n, ((n : ℝ) * v + ((n : ℝ) * m) ^ 2) ∂μN := by simp_rw [hin2]
      _ = ∫ ω, ((N ω : ℝ) * v + ((N ω : ℝ) * m) ^ 2) ∂P :=
          integral_map hN_meas.aemeasurable .of_discrete
      _ = ∫ ω, ((N ω : ℝ) * v + (N ω : ℝ) ^ 2 * m ^ 2) ∂P := by
          congr 1; funext ω; ring
      _ = (∫ ω, (N ω : ℝ) ∂P) * v + (∫ ω, (N ω : ℝ) ^ 2 ∂P) * m ^ 2 := by
          rw [integral_add (hNint1.mul_const v) (hNint2.mul_const (m ^ 2)),
            integral_mul_const, integral_mul_const]
  refine ⟨hSmem, hES, ?_⟩
  have hVS := variance_eq_sub hSmem
  have hVN := variance_eq_sub hN_sq
  simp only [Pi.pow_apply] at hVS hVN
  rw [hVS, hVN, hES, hES2]
  ring

#print axioms poisson_hasSum_exp_aux
#print axioms poisson_hasSum_mean_aux
#print axioms poisson_hasSum_sq_aux
#print axioms poisson_moments_aux
#print axioms compound_split_aux

/-- Collective risk model, Poisson count. Let the year's claim count `N` follow the Poisson law
with mean `λ`, let the claim sizes `X 0, X 1, …` be independent of each other, share one size
law, and be independent of the count, and let the average squared claim `E[X²]` be finite. Then
the year's total `S = X 0 + … + X (N - 1)` (zero when `N = 0`) has finite variance, its average
is the expected count times the average claim, `E[S] = λ μ`, and its variance is the expected
count times the average squared claim, `Var(S) = λ E[X²] = λ (σ_X² + μ²)`. -/
theorem compound_poisson_mean_and_variance (lam : ℝ≥0) (N : Ω → ℕ) (X : ℕ → Ω → ℝ)
    (hN_meas : Measurable N) (hX_meas : ∀ i, Measurable (X i))
    (hN : HasLaw N (poissonMeasure lam) P)
    (hX_ident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hX_indep : iIndepFun X P)
    (hNX_indep : IndepFun N (fun ω i => X i ω) P)
    (hX_sq : MemLp (X 0) 2 P) :
    MemLp (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) 2 P ∧
      ∫ ω, (∑ i ∈ Finset.range (N ω), X i ω) ∂P = (lam : ℝ) * ∫ ω, X 0 ω ∂P ∧
      variance (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) P
        = (lam : ℝ) * ∫ ω, (X 0 ω) ^ 2 ∂P ∧
      variance (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) P
        = (lam : ℝ) * (variance (X 0) P + (∫ ω, X 0 ω ∂P) ^ 2) := by
  obtain ⟨hNmem, hEN, hVN⟩ := poisson_moments_aux lam N hN
  obtain ⟨h1, h2, h3⟩ := compound_split_aux N X hN_meas hX_meas hNmem hX_ident hX_indep
    hNX_indep hX_sq
  have hEX2 : ∫ ω, (X 0 ω) ^ 2 ∂P = variance (X 0) P + (∫ ω, X 0 ω ∂P) ^ 2 := by
    have h := variance_eq_sub hX_sq
    simp only [Pi.pow_apply] at h
    linarith
  refine ⟨h1, by rw [h2, hEN], by rw [h3, hEN, hVN, hEX2]; ring, by rw [h3, hEN, hVN]; ring⟩

/-- The variance split for any count. Let the claim count `N` be any random whole number with
finite `E[N²]`, independent of the claim sizes, and let the sizes be independent of each other,
share one law, and have finite `E[X²]`. Then the total `S` has finite variance, its average is
`E[S] = E[N] μ`, and its variance is the size part plus the count part:
`Var(S) = E[N] σ_X² + Var(N) μ²`. -/
theorem compound_sum_variance_split (N : Ω → ℕ) (X : ℕ → Ω → ℝ)
    (hN_meas : Measurable N) (hX_meas : ∀ i, Measurable (X i))
    (hN_sq : MemLp (fun ω => (N ω : ℝ)) 2 P)
    (hX_ident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hX_indep : iIndepFun X P)
    (hNX_indep : IndepFun N (fun ω i => X i ω) P)
    (hX_sq : MemLp (X 0) 2 P) :
    MemLp (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) 2 P ∧
      ∫ ω, (∑ i ∈ Finset.range (N ω), X i ω) ∂P
        = (∫ ω, (N ω : ℝ) ∂P) * ∫ ω, X 0 ω ∂P ∧
      variance (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) P
        = (∫ ω, (N ω : ℝ) ∂P) * variance (X 0) P
          + variance (fun ω => (N ω : ℝ)) P * (∫ ω, X 0 ω ∂P) ^ 2 := by
  exact compound_split_aux N X hN_meas hX_meas hN_sq hX_ident hX_indep hNX_indep hX_sq

/-- The Pareto density above the threshold `u` with tail index `α`: `α u^α x^(-α-1)`. -/
noncomputable def paretoDensity (u α x : ℝ) : ℝ := α * u ^ α * x ^ (-α - 1)

/-- Log-likelihood of the tail index `α` for the large claims `x 0, …, x (k-1)`: the log of the
product of their Pareto densities. -/
noncomputable def paretoLogLik {k : ℕ} (u : ℝ) (x : Fin k → ℝ) (α : ℝ) : ℝ :=
  ∑ i, log (paretoDensity u α (x i))

/-- Maximum likelihood for the Pareto tail. Given at least one large claim, every one above the
threshold `u > 0`, the tail index `α̂ = k / Σ ln(x_i / u)` is positive and is the one peak of the
likelihood: every other positive `α` makes the observed large claims strictly less probable. -/
theorem pareto_tail_index_mle {k : ℕ} (hk : 0 < k) (u : ℝ) (hu : 0 < u) (x : Fin k → ℝ)
    (hx : ∀ i, u < x i) :
    0 < (k : ℝ) / ∑ i, log (x i / u) ∧
      ∀ α : ℝ, 0 < α → α ≠ (k : ℝ) / ∑ i, log (x i / u) →
        paretoLogLik u x α < paretoLogLik u x ((k : ℝ) / ∑ i, log (x i / u)) := by
  have key : ∀ α : ℝ, 0 < α →
      paretoLogLik u x α = k * log α - α * ∑ i, log (x i / u) - ∑ i, log (x i) := by
    intro α hα
    unfold paretoLogLik paretoDensity
    have h : ∀ i, log (α * u ^ α * x i ^ (-α - 1)) = log α - α * log (x i / u) - log (x i) := by
      intro i
      have hxi : 0 < x i := hu.trans (hx i)
      rw [log_mul (by positivity) (by positivity), log_mul (by positivity) (by positivity),
        log_rpow hu, log_rpow hxi, log_div hxi.ne' hu.ne']
      ring
    simp only [h, Finset.sum_sub_distrib, Finset.mul_sum, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul]
  have hT : 0 < ∑ i, log (x i / u) := by
    have : Nonempty (Fin k) := ⟨⟨0, hk⟩⟩
    apply Finset.sum_pos _ Finset.univ_nonempty
    intro i _
    exact log_pos ((one_lt_div hu).2 (hx i))
  have hkpos : (0 : ℝ) < k := by exact_mod_cast hk
  set T := ∑ i, log (x i / u) with hTdef
  have ha : 0 < (k : ℝ) / T := div_pos hkpos hT
  refine ⟨ha, fun α hα hne => ?_⟩
  rw [key α hα, key _ ha]
  set a := (k : ℝ) / T with hadef
  have hkT : (k : ℝ) = a * T := by rw [hadef]; field_simp
  have ht : 0 < α / a := div_pos hα ha
  have ht1 : α / a ≠ 1 := by
    intro h; apply hne; field_simp at h; linarith
  have hlog := log_lt_sub_one_of_pos ht ht1
  rw [log_div hα.ne' ha.ne'] at hlog
  have : (k : ℝ) * (α / a) = α * T := by rw [hkT]; field_simp
  nlinarith

/-! The card's whole-number worked numbers: 50,000 cars, claim chance 5 percent,
median claim $3,000, log-spread σ = 1.2 = 6/5. -/

-- expected claims: λ = 50,000 × 0.05 = 2,500
example : (50000 : ℚ) * (5 / 100) = 2500 := by norm_num
-- individual model: binomial variance of the count 50,000 × 0.05 × 0.95 = 2,375
example : (50000 : ℚ) * (5 / 100) * (95 / 100) = 2375 := by norm_num
-- tail pull exponent σ² / 2 = 0.72, and the square's exponent 2σ² = 2.88
example : ((6 : ℚ) / 5) ^ 2 / 2 = 72 / 100 := by norm_num
example : 2 * ((6 : ℚ) / 5) ^ 2 = 288 / 100 := by norm_num
-- median squared: 3,000² = 9,000,000
example : (3000 : ℕ) ^ 2 = 9000000 := by norm_num
-- mistake: median $3,000 used as the average claim gives 2,500 × 3,000 = $7,500,000
example : (2500 : ℕ) * 3000 = 7500000 := by norm_num
-- a threshold of $50,000 is twice $25,000
example : (50000 : ℕ) = 2 * 25000 := by norm_num

#print axioms compound_poisson_mean_and_variance
#print axioms compound_sum_variance_split
#print axioms pareto_tail_index_mle
