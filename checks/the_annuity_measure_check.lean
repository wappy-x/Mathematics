-- The annuity measure: in any one-period curve model without free money, reweighting expiry-date dollars by the annuity makes the swap rate at expiry average exactly today's forward swap rate, the reweighting is a true probability measure, and a payer swaption costs the notional times today's annuity times the annuity-weighted average of a plain call payoff on the swap rate.
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap

open MeasureTheory

/-! Setting. `P` is the measure that counts outcomes in dollars paid at the expiry `T₀`.
The swap pays fixed on `n + 1` dates `T₁, …, Tₙ₊₁` (indexed by `Fin (n + 1)`; the last one is
`Fin.last n`). `τ i` is the accrual fraction of period `i`. `D₀ = D(T₀)` and `D i = D(Tᵢ)` are
today's discount factors. `B i ω = D(T₀, Tᵢ)` is the price at expiry, in the future `ω`, of the
bond paying one dollar at `Tᵢ`. -/

/-- The annuity at expiry: `A_T = ∑ τᵢ D(T₀, Tᵢ)`. -/
noncomputable def annuityAtExpiry {Ω : Type*} {n : ℕ} (τ : Fin (n + 1) → ℝ)
    (B : Fin (n + 1) → Ω → ℝ) (ω : Ω) : ℝ :=
  ∑ i, τ i * B i ω

/-- The annuity today: `A₀ = ∑ τᵢ D(Tᵢ)`. -/
noncomputable def annuityToday {n : ℕ} (τ : Fin (n + 1) → ℝ) (D : Fin (n + 1) → ℝ) : ℝ :=
  ∑ i, τ i * D i

/-- The swap rate at expiry: `S_T = (1 - D(T₀, Tₙ)) / A_T` (the floating leg over the annuity;
the bond maturing at `T₀` is worth exactly 1 at `T₀`). -/
noncomputable def swapRateAtExpiry {Ω : Type*} {n : ℕ} (τ : Fin (n + 1) → ℝ)
    (B : Fin (n + 1) → Ω → ℝ) (ω : Ω) : ℝ :=
  (1 - B (Fin.last n) ω) / annuityAtExpiry τ B ω

/-- The annuity measure: expiry-date dollars tilted by `w = D(T₀) A_T / A₀`. -/
noncomputable def annuityMeasure {Ω : Type*} [MeasurableSpace Ω] {n : ℕ} (P : Measure Ω)
    (τ : Fin (n + 1) → ℝ) (D₀ : ℝ) (D : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ) :
    Measure Ω :=
  P.withDensity (fun ω => ENNReal.ofReal (D₀ * annuityAtExpiry τ B ω / annuityToday τ D))


lemma annuityAtExpiry_pos {Ω : Type*} {n : ℕ} (τ : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ)
    (hτ : ∀ i, 0 < τ i) (hB : ∀ i ω, 0 < B i ω) (ω : Ω) : 0 < annuityAtExpiry τ B ω := by
  unfold annuityAtExpiry
  exact Finset.sum_pos (fun i _ => mul_pos (hτ i) (hB i ω)) Finset.univ_nonempty

lemma annuityAtExpiry_integrable {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) {n : ℕ}
    (τ : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ) (hB_int : ∀ i, Integrable (B i) P) :
    Integrable (annuityAtExpiry τ B) P := by
  unfold annuityAtExpiry
  exact integrable_finsetSum _ (fun i _ => (hB_int i).const_mul (τ i))

lemma annuityAtExpiry_integral {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) {n : ℕ}
    (τ : Fin (n + 1) → ℝ) (D₀ : ℝ) (D : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ)
    (hB_int : ∀ i, Integrable (B i) P) (h_fair : ∀ i, ∫ ω, B i ω ∂P = D i / D₀) :
    ∫ ω, annuityAtExpiry τ B ω ∂P = annuityToday τ D / D₀ := by
  unfold annuityAtExpiry annuityToday
  rw [integral_finsetSum _ (fun i _ => (hB_int i).const_mul (τ i)), Finset.sum_div]
  refine Finset.sum_congr rfl (fun i _ => ?_)
  rw [integral_const_mul, h_fair, mul_div_assoc]

lemma annuityToday_pos {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    {n : ℕ} (τ : Fin (n + 1) → ℝ) (D₀ : ℝ) (D : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ)
    (hτ : ∀ i, 0 < τ i) (hD₀ : 0 < D₀) (hB : ∀ i ω, 0 < B i ω)
    (hB_int : ∀ i, Integrable (B i) P) (h_fair : ∀ i, ∫ ω, B i ω ∂P = D i / D₀) :
    0 < annuityToday τ D := by
  have hint := annuityAtExpiry_integrable P τ B hB_int
  have hpos : 0 < ∫ ω, annuityAtExpiry τ B ω ∂P := by
    rw [integral_pos_iff_support_of_nonneg
      (fun ω => (annuityAtExpiry_pos τ B hτ hB ω).le) hint]
    have : Function.support (annuityAtExpiry τ B) = Set.univ :=
      Set.eq_univ_of_forall (fun ω => (annuityAtExpiry_pos τ B hτ hB ω).ne')
    rw [this, measure_univ]
    exact one_pos
  rw [annuityAtExpiry_integral P τ D₀ D B hB_int h_fair] at hpos
  have := mul_pos hpos hD₀
  rwa [div_mul_cancel₀ _ hD₀.ne'] at this

lemma annuityMeasure_integral {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    {n : ℕ} (τ : Fin (n + 1) → ℝ) (D₀ : ℝ) (D : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ)
    (hτ : ∀ i, 0 < τ i) (hD₀ : 0 < D₀) (hB : ∀ i ω, 0 < B i ω)
    (hB_int : ∀ i, Integrable (B i) P) (h_fair : ∀ i, ∫ ω, B i ω ∂P = D i / D₀) (g : Ω → ℝ) :
    ∫ ω, g ω ∂(annuityMeasure P τ D₀ D B)
      = ∫ ω, (D₀ * annuityAtExpiry τ B ω / annuityToday τ D) * g ω ∂P := by
  have hA₀ := annuityToday_pos P τ D₀ D B hτ hD₀ hB hB_int h_fair
  unfold annuityMeasure
  have hmeas : AEMeasurable
      (fun ω => ENNReal.ofReal (D₀ * annuityAtExpiry τ B ω / annuityToday τ D)) P :=
    (((annuityAtExpiry_integrable P τ B hB_int).aemeasurable.const_mul D₀).div_const _).ennreal_ofReal
  rw [integral_withDensity_eq_integral_toReal_smul₀ hmeas
    (Filter.Eventually.of_forall (fun _ => ENNReal.ofReal_lt_top))]
  refine integral_congr_ae (Filter.Eventually.of_forall (fun ω => ?_))
  simp only [smul_eq_mul]
  rw [ENNReal.toReal_ofReal]
  exact (div_pos (mul_pos hD₀ (annuityAtExpiry_pos τ B hτ hB ω)) hA₀).le

/-- **The forward swap rate has no drift in annuity units.** Take a curve model without free
money: every bond's price at expiry, averaged in expiry-date dollars, equals today's forward
price `D(Tᵢ) / D(T₀)`. The annuity is a positive traded portfolio: positive accruals, positive
bond prices. Then, averaged with the annuity measure's weights, the swap rate at expiry equals
today's forward swap rate: `E^A[S_T] = F = (D(T₀) - D(Tₙ)) / A₀`. -/
theorem forward_swap_rate_driftless_under_annuity_measure {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (n : ℕ)
    (τ : Fin (n + 1) → ℝ) (D₀ : ℝ) (D : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ)
    (hτ : ∀ i, 0 < τ i) (hD₀ : 0 < D₀) (hB : ∀ i ω, 0 < B i ω)
    (hB_int : ∀ i, Integrable (B i) P)
    (h_fair : ∀ i, ∫ ω, B i ω ∂P = D i / D₀) :
    ∫ ω, swapRateAtExpiry τ B ω ∂(annuityMeasure P τ D₀ D B)
      = (D₀ - D (Fin.last n)) / annuityToday τ D := by
  have hA₀ := annuityToday_pos P τ D₀ D B hτ hD₀ hB hB_int h_fair
  rw [annuityMeasure_integral P τ D₀ D B hτ hD₀ hB hB_int h_fair]
  have hcongr : (fun ω => D₀ * annuityAtExpiry τ B ω / annuityToday τ D * swapRateAtExpiry τ B ω)
      = fun ω => (D₀ / annuityToday τ D) * (1 - B (Fin.last n) ω) := by
    funext ω
    have hA := (annuityAtExpiry_pos τ B hτ hB ω).ne'
    unfold swapRateAtExpiry
    field_simp
  rw [hcongr, integral_const_mul, integral_sub (integrable_const 1) (hB_int _), h_fair]
  simp only [integral_const, probReal_univ, smul_eq_mul, one_mul]
  field_simp

/-- **The annuity weights are genuine probabilities.** Under the same conditions, the tilt
`w = D(T₀) A_T / A₀` averages to 1 in expiry-date dollars, so the annuity measure is a
probability measure. -/
theorem annuity_measure_is_probability {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (n : ℕ)
    (τ : Fin (n + 1) → ℝ) (D₀ : ℝ) (D : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ)
    (hτ : ∀ i, 0 < τ i) (hD₀ : 0 < D₀) (hB : ∀ i ω, 0 < B i ω)
    (hB_int : ∀ i, Integrable (B i) P)
    (h_fair : ∀ i, ∫ ω, B i ω ∂P = D i / D₀) :
    IsProbabilityMeasure (annuityMeasure P τ D₀ D B) := by
  have hA₀ := annuityToday_pos P τ D₀ D B hτ hD₀ hB hB_int h_fair
  constructor
  unfold annuityMeasure
  rw [withDensity_apply _ MeasurableSet.univ, Measure.restrict_univ]
  have hint : Integrable (fun ω => D₀ * annuityAtExpiry τ B ω / annuityToday τ D) P :=
    ((annuityAtExpiry_integrable P τ B hB_int).const_mul D₀).div_const _
  rw [← ofReal_integral_eq_lintegral_ofReal hint
    (Filter.Eventually.of_forall (fun ω =>
      (div_pos (mul_pos hD₀ (annuityAtExpiry_pos τ B hτ hB ω)) hA₀).le))]
  rw [integral_div, integral_const_mul, annuityAtExpiry_integral P τ D₀ D B hB_int h_fair]
  rw [mul_div_cancel₀ _ hD₀.ne', div_self hA₀.ne', ENNReal.ofReal_one]

/-- **A payer swaption is today's annuity times a plain call on the swap rate.** A physically
settled payer swaption with notional `L` and strike `K` pays `L A_T (S_T - K)⁺` at expiry. Its
price today, `D(T₀)` times its average in expiry-date dollars, equals
`L A₀ E^A[(S_T - K)⁺]`: the random annuity cancels exactly. -/
theorem payer_swaption_price_in_annuity_units {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (n : ℕ)
    (τ : Fin (n + 1) → ℝ) (D₀ : ℝ) (D : Fin (n + 1) → ℝ) (B : Fin (n + 1) → Ω → ℝ)
    (hτ : ∀ i, 0 < τ i) (hD₀ : 0 < D₀) (hB : ∀ i ω, 0 < B i ω)
    (hB_int : ∀ i, Integrable (B i) P)
    (h_fair : ∀ i, ∫ ω, B i ω ∂P = D i / D₀) (L K : ℝ) :
    D₀ * ∫ ω, L * annuityAtExpiry τ B ω * max (swapRateAtExpiry τ B ω - K) 0 ∂P
      = L * annuityToday τ D *
          ∫ ω, max (swapRateAtExpiry τ B ω - K) 0 ∂(annuityMeasure P τ D₀ D B) := by
  have hA₀ := annuityToday_pos P τ D₀ D B hτ hD₀ hB hB_int h_fair
  rw [annuityMeasure_integral P τ D₀ D B hτ hD₀ hB hB_int h_fair]
  have h1 : (fun ω => L * annuityAtExpiry τ B ω * max (swapRateAtExpiry τ B ω - K) 0)
      = fun ω => L * (annuityAtExpiry τ B ω * max (swapRateAtExpiry τ B ω - K) 0) := by
    funext ω; ring
  have h2 : (fun ω => D₀ * annuityAtExpiry τ B ω / annuityToday τ D *
        max (swapRateAtExpiry τ B ω - K) 0)
      = fun ω => (D₀ / annuityToday τ D) *
          (annuityAtExpiry τ B ω * max (swapRateAtExpiry τ B ω - K) 0) := by
    funext ω; ring
  rw [h1, h2, integral_const_mul, integral_const_mul]
  field_simp

-- The card's curve: forward rates 5.00, 4.60, 4.30, 4.10, 4.00, 3.90 percent, annual compounding.
-- D(1) = 1 / 1.05 = 20/21, which the card prints as 0.952381.
example : (1 : ℚ) / (105 / 100) = 20 / 21 := by norm_num
example : (952380 : ℚ) / 10 ^ 6 < 20 / 21 ∧ (20 : ℚ) / 21 < 952382 / 10 ^ 6 := by norm_num
-- The annuity A₀ = D(2) + ... + D(6) rounds to 4.204423.
example :
    let d1 : ℚ := 1 / (105 / 100)
    let d2 := d1 / (1046 / 1000)
    let d3 := d2 / (1043 / 1000)
    let d4 := d3 / (1041 / 1000)
    let d5 := d4 / (1040 / 1000)
    let d6 := d5 / (1039 / 1000)
    (42044225 : ℚ) / 10 ^ 7 < d2 + d3 + d4 + d5 + d6 ∧ d2 + d3 + d4 + d5 + d6 < 42044235 / 10 ^ 7 := by
  norm_num
-- The forward swap rate F = (D(1) - D(6)) / A₀ rounds to 4.1937 percent.
example :
    let d1 : ℚ := 1 / (105 / 100)
    let d2 := d1 / (1046 / 1000)
    let d3 := d2 / (1043 / 1000)
    let d4 := d3 / (1041 / 1000)
    let d5 := d4 / (1040 / 1000)
    let d6 := d5 / (1039 / 1000)
    (419365 : ℚ) / 10 ^ 7 < (d1 - d6) / (d2 + d3 + d4 + d5 + d6) ∧
      (d1 - d6) / (d2 + d3 + d4 + d5 + d6) < 419375 / 10 ^ 7 := by
  norm_num
-- At the money ln(F/K) = 0, so d₁ = (1/2)σ²T / (σ√T) = 15/100 and d₂ = -15/100 at σ = 30/100, T = 1.
example : ((1 : ℚ) / 2 * (30 / 100) ^ 2 * 1) / ((30 / 100) * 1) = 15 / 100 := by norm_num
example : (15 : ℚ) / 100 - 30 / 100 = -15 / 100 := by norm_num

#print axioms annuityAtExpiry_pos
#print axioms annuityAtExpiry_integrable
#print axioms annuityAtExpiry_integral
#print axioms annuityToday_pos
#print axioms annuityMeasure_integral
#print axioms forward_swap_rate_driftless_under_annuity_measure
#print axioms annuity_measure_is_probability
#print axioms payer_swaption_price_in_annuity_units
