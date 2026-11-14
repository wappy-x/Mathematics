-- CVA: when default is independent of the exposure, CVA is the loss fraction times the sum over dates of discounted expected exposure times default chance, the risky price is the clean price minus CVA, and for a bought option it is loss times price times default chance.
import Mathlib.Probability.Independence.Integration
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory ProbabilityTheory

/-- Pointwise: the "value on the default date, if before expiry" is a finite sum of indicators. -/
lemma cva_helper_sum {Ω : Type*} (n : ℕ) (τ : Ω → ℕ) (W : ℕ → Ω → ℝ) (ω : Ω) :
    (if τ ω < n then W (τ ω) ω else 0)
      = ∑ i ∈ Finset.range n, (τ ⁻¹' {i}).indicator (W i) ω := by
  have h : ∀ i, (τ ⁻¹' {i}).indicator (W i) ω = if τ ω = i then W i ω else 0 := by
    intro i
    by_cases h : τ ω = i
    · subst h; simp
    · simp [h]
  simp only [h]
  rw [Finset.sum_ite_eq (Finset.range n) (τ ω) (fun i => W i ω)]
  simp [Finset.mem_range]

/-- The "value on the default date, if before expiry" is integrable. -/
lemma cva_helper_int {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (n : ℕ) (τ : Ω → ℕ) (W : ℕ → Ω → ℝ) (hτ : Measurable τ)
    (hW : ∀ i, Integrable (W i) P) :
    Integrable (fun ω => if τ ω < n then W (τ ω) ω else 0) P := by
  have h : (fun ω => if τ ω < n then W (τ ω) ω else 0)
      = fun ω => ∑ i ∈ Finset.range n, (τ ⁻¹' {i}).indicator (W i) ω := by
    funext ω; exact cva_helper_sum n τ W ω
  rw [h]
  exact integrable_finsetSum _ fun i _ =>
    (hW i).indicator (hτ (measurableSet_singleton i))

/-- CVA as a sum over dates. Dates are numbered `0, 1, …, n-1`; `τ ω = i < n` means the
counterparty defaults on date `i`, and `τ ω ≥ n` means it survives to expiry. `V i` is the
trade's clean value to the bank on date `i`, `D i` the discount factor and `R` the fixed
recovery. The CVA is `(1 - R)` times the discounted amount owed at default, averaged over
the futures where default comes before expiry. When the default date is independent of the
exposure, this equals the loss fraction `1 - R` times the sum, over the deal's dates, of the
discounted expected exposure `D i * E[V⁺(i)]` times the chance of default on that date. -/
theorem cva_eq_loss_times_sum_discounted_exposure_times_default_chance
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (τ : Ω → ℕ) (V : ℕ → Ω → ℝ) (D : ℕ → ℝ) (R : ℝ)
    (hτ : Measurable τ) (hV : ∀ i, Integrable (V i) P)
    (hindep : ∀ i, IndepFun τ (V i) P) :
    (1 - R) * ∫ ω, (if τ ω < n then D (τ ω) * max (V (τ ω) ω) 0 else 0) ∂P
      = (1 - R) * ∑ i ∈ Finset.range n,
          D i * (∫ ω, max (V i ω) 0 ∂P) * P.real {ω | τ ω = i} := by
  congr 1
  have hsum : (fun ω => if τ ω < n then D (τ ω) * max (V (τ ω) ω) 0 else 0)
      = fun ω => ∑ i ∈ Finset.range n,
          (τ ⁻¹' {i}).indicator (fun ω => D i * max (V i ω) 0) ω := by
    funext ω; exact cva_helper_sum n τ (fun i ω => D i * max (V i ω) 0) ω
  rw [hsum, integral_finsetSum _ fun i _ =>
    ((hV i).pos_part.const_mul (D i)).indicator (hτ (measurableSet_singleton i))]
  refine Finset.sum_congr rfl fun i _ => ?_
  have hprod : (fun ω => (τ ⁻¹' {i}).indicator (fun ω => D i * max (V i ω) 0) ω)
      = fun ω => (({i} : Set ℕ).indicator (fun _ => (1 : ℝ)) ∘ τ) ω
          * ((fun x => D i * max x 0) ∘ V i) ω := by
    funext ω
    by_cases h : τ ω = i
    · subst h; simp
    · simp [h]
  have hind : IndepFun (({i} : Set ℕ).indicator (fun _ => (1 : ℝ)) ∘ τ)
      ((fun x => D i * max x 0) ∘ V i) P :=
    (hindep i).comp (measurable_of_countable _) (by fun_prop)
  rw [hprod, hind.integral_fun_mul_eq_mul_integral]
  · have h1 : ∫ ω, (({i} : Set ℕ).indicator (fun _ => (1 : ℝ)) ∘ τ) ω ∂P
        = P.real {ω | τ ω = i} := by
      have : (({i} : Set ℕ).indicator (fun _ => (1 : ℝ)) ∘ τ)
          = (τ ⁻¹' {i}).indicator 1 := by
        funext ω
        by_cases h : τ ω = i
        · subst h; simp
        · simp [h]
      rw [this, integral_indicator_one (hτ (measurableSet_singleton i))]
      rfl
    have h2 : ∫ ω, ((fun x => D i * max x 0) ∘ V i) ω ∂P
        = D i * ∫ ω, max (V i ω) 0 ∂P := by
      simp only [Function.comp]
      exact integral_const_mul _ _
    rw [h1, h2]; ring
  · exact ((measurable_of_countable _).comp hτ).aestronglyMeasurable
  · exact ((hV i).pos_part.const_mul (D i)).aestronglyMeasurable

/-- Risky price = clean price − CVA. The trade pays `X` at expiry, worth `DT * X` today; the
clean price is its average. If the counterparty defaults on date `i` before expiry, the trade
is closed out at its clean value `V i`: the bank collects the fraction `R` of what it is owed
and pays in full what it owes. If `V` is the clean value on the default date (over the
futures with default before expiry, the discounted payoff and the discounted value on the
default date average the same), then the risky price is the clean price minus
`(1 - R) * E[D(τ) V⁺(τ); τ before expiry]`, the CVA. -/
theorem risky_price_eq_clean_price_sub_cva
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (τ : Ω → ℕ) (V : ℕ → Ω → ℝ) (D : ℕ → ℝ) (DT R : ℝ) (X : Ω → ℝ)
    (hτ : Measurable τ) (hV : ∀ i, Integrable (V i) P) (hX : Integrable X P)
    (hclean : ∫ ω in {ω | τ ω < n}, DT * X ω ∂P
      = ∫ ω in {ω | τ ω < n}, D (τ ω) * V (τ ω) ω ∂P) :
    ∫ ω, (if τ ω < n
          then D (τ ω) * (R * max (V (τ ω) ω) 0 - max (-V (τ ω) ω) 0)
          else DT * X ω) ∂P
      = ∫ ω, DT * X ω ∂P
        - (1 - R) * ∫ ω, (if τ ω < n then D (τ ω) * max (V (τ ω) ω) 0 else 0) ∂P := by
  have hA : MeasurableSet {ω | τ ω < n} := hτ measurableSet_Iio
  set F : Ω → ℝ := fun ω => if τ ω < n then D (τ ω) * V (τ ω) ω else 0 with hF
  set G : Ω → ℝ := fun ω => if τ ω < n then D (τ ω) * max (V (τ ω) ω) 0 else 0 with hG
  set H : Ω → ℝ := fun ω => if τ ω < n then 0 else DT * X ω with hH
  have hFi : Integrable F P :=
    cva_helper_int n τ (fun i ω => D i * V i ω) hτ fun i => (hV i).const_mul (D i)
  have hGi : Integrable G P :=
    cva_helper_int n τ (fun i ω => D i * max (V i ω) 0) hτ
      fun i => (hV i).pos_part.const_mul (D i)
  have hHeq : H = ({ω | τ ω < n}ᶜ).indicator (fun ω => DT * X ω) := by
    funext ω; by_cases h : τ ω < n <;> simp [hH, h]
  have hHi : Integrable H P := by
    rw [hHeq]; exact (hX.const_mul DT).indicator hA.compl
  have hFeq : F = ({ω | τ ω < n}).indicator (fun ω => D (τ ω) * V (τ ω) ω) := by
    funext ω; by_cases h : τ ω < n <;> simp [hF, h]
  have hpt : (fun ω => if τ ω < n
          then D (τ ω) * (R * max (V (τ ω) ω) 0 - max (-V (τ ω) ω) 0)
          else DT * X ω) = fun ω => F ω + H ω - (1 - R) * G ω := by
    funext ω
    simp only [hF, hG, hH]
    split_ifs
    · rcases le_total 0 (V (τ ω) ω) with h | h
      · rw [max_eq_left h, max_eq_right (by linarith)]; ring
      · rw [max_eq_right h, max_eq_left (by linarith)]; ring
    · ring
  have hclean' : ∫ ω, DT * X ω ∂P = ∫ ω, F ω ∂P + ∫ ω, H ω ∂P := by
    rw [← integral_add_compl hA (hX.const_mul DT), hclean, hFeq, hHeq,
      integral_indicator hA, integral_indicator hA.compl]
  rw [hpt]
  have hs : ∫ ω, F ω + H ω - (1 - R) * G ω ∂P
      = ∫ ω, F ω + H ω ∂P - ∫ ω, (1 - R) * G ω ∂P :=
    integral_sub (hFi.add hHi) (hGi.const_mul _)
  rw [hs, integral_add hFi hHi, integral_const_mul, hclean']

/-- The closed form for a bought option. A bought option is never worth less than zero, so
its exposure is its value; and in the pricing world its discounted average value at every
date up to expiry `T` is today's price `C₀`. Then the CVA integral with hazard `λ`,
`(1 - R) ∫₀ᵀ D(t) EE(t) λ e^{-λt} dt`, equals loss × price × default chance:
`(1 - R) * C₀ * (1 - e^{-λT})`. -/
theorem cva_bought_option_eq_loss_times_price_times_default_chance
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (V : ℝ → Ω → ℝ) (D : ℝ → ℝ) (R C₀ lam T : ℝ) (hT : 0 ≤ T)
    (hbought : ∀ t ω, 0 ≤ V t ω)
    (hprice : ∀ t ∈ Set.Icc 0 T, D t * ∫ ω, V t ω ∂P = C₀) :
    (1 - R) * ∫ t in (0 : ℝ)..T,
        D t * (∫ ω, max (V t ω) 0 ∂P) * (lam * Real.exp (-lam * t))
      = (1 - R) * C₀ * (1 - Real.exp (-lam * T)) := by
  have hcongr : ∀ t ∈ Set.uIcc (0 : ℝ) T,
      D t * (∫ ω, max (V t ω) 0 ∂P) * (lam * Real.exp (-lam * t))
        = C₀ * (lam * Real.exp (-lam * t)) := by
    intro t ht
    rw [Set.uIcc_of_le hT] at ht
    have hmax : (fun ω => max (V t ω) 0) = V t := by
      funext ω; exact max_eq_left (hbought t ω)
    rw [hmax, hprice t ht]
  rw [intervalIntegral.integral_congr hcongr]
  have hderiv : ∀ x ∈ Set.uIcc (0 : ℝ) T,
      HasDerivAt (fun t => -C₀ * Real.exp (-lam * t)) (C₀ * (lam * Real.exp (-lam * x))) x := by
    intro x _
    have h1 : HasDerivAt (fun t => -lam * t) (-lam) x := by
      simpa using (hasDerivAt_id x).const_mul (-lam)
    have h2 := (h1.exp).const_mul (-C₀)
    convert h2 using 1
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv
    (by apply Continuous.intervalIntegrable; fun_prop)]
  simp
  ring

/-- The card's credit triangle: recovery 40% and hazard 2% a year give a running
spread `(1 - R) λ` of 1.2% a year (120 basis points). -/
example : (1 - (40 : ℚ) / 100) * (2 / 100) = 12 / 1000 := by norm_num

/-- The card's loss given default: recovery 40% leaves 60% lost. -/
example : (1 : ℚ) - 40 / 100 = 60 / 100 := by norm_num

#print axioms cva_helper_sum
#print axioms cva_helper_int
#print axioms cva_eq_loss_times_sum_discounted_exposure_times_default_chance
#print axioms risky_price_eq_clean_price_sub_cva
#print axioms cva_bought_option_eq_loss_times_price_times_default_chance
