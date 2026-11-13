-- Swaptions: under a lognormal swap rate the payer and receiver swaptions are worth the annuity times Black's bracket, and in any finite state-price model payer minus receiver equals the forward swap.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open ProbabilityTheory MeasureTheory Real Finset

lemma swaption_tilt (s : ℝ) (E : Set ℝ) (hE : MeasurableSet E) :
    ∫ z in E, Real.exp (s * z - s ^ 2 / 2) ∂(gaussianReal 0 1) = (gaussianReal s 1).real E := by
  rw [← integral_indicator hE, integral_gaussianReal_eq_integral_smul one_ne_zero]
  have h : (fun x => gaussianPDFReal 0 1 x • E.indicator (fun z => Real.exp (s * z - s ^ 2 / 2)) x)
      = E.indicator (gaussianPDFReal s 1) := by
    funext x
    by_cases hx : x ∈ E
    · simp only [Set.indicator_of_mem hx, smul_eq_mul, gaussianPDFReal]
      rw [mul_assoc, ← Real.exp_add]
      congr 2
      push_cast
      ring
    · simp [Set.indicator_of_notMem hx]
  rw [h, integral_indicator hE, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg hE (fun x _ => gaussianPDFReal_nonneg _ _ _)

#print axioms swaption_tilt

lemma swaption_shift (s : ℝ) (E : Set ℝ) (hE : MeasurableSet E) :
    (gaussianReal s 1).real E = (gaussianReal 0 1).real ((· + s) ⁻¹' E) := by
  rw [← zero_add s, ← gaussianReal_map_add_const, map_measureReal_apply (measurable_add_const _) hE]
  simp

#print axioms swaption_shift

lemma swaption_cdf_neg (x : ℝ) :
    cdf (gaussianReal 0 1) (-x) = 1 - cdf (gaussianReal 0 1) x := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [cdf_eq_real, cdf_eq_real]
  have h1 : (gaussianReal 0 1).real (Set.Iic (-x)) = (gaussianReal 0 1).real (Set.Ici x) := by
    conv_lhs => rw [← neg_zero, ← gaussianReal_map_neg]
    rw [map_measureReal_apply measurable_neg measurableSet_Iic]
    congr 1
    ext y; simp
  rw [h1, ← Set.compl_Iio, measureReal_compl measurableSet_Iio, probReal_univ,
    measureReal_congr Iio_ae_eq_Iic]

#print axioms swaption_cdf_neg

lemma swaption_Ioi (a : ℝ) :
    (gaussianReal 0 1).real (Set.Ioi a) = cdf (gaussianReal 0 1) (-a) := by
  rw [swaption_cdf_neg, cdf_eq_real, ← Set.compl_Iic, measureReal_compl measurableSet_Iic,
    probReal_univ]

#print axioms swaption_Ioi

lemma swaption_sum_annuity {Ω : Type*} [Fintype Ω] {n : ℕ}
    (α D : Fin (n + 1) → ℝ) (p : Ω → ℝ) (DT : Ω → Fin (n + 1) → ℝ)
    (hbond : ∀ i, ∑ ω, p ω * DT ω i = D i) :
    ∑ ω, p ω * ∑ i, α i * DT ω i = ∑ i, α i * D i := by
  simp_rw [Finset.mul_sum]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl (fun i _ => ?_)
  rw [← hbond i, Finset.mul_sum]
  exact Finset.sum_congr rfl (fun ω _ => by ring)

#print axioms swaption_sum_annuity

lemma swaption_annuity_pos {Ω : Type*} [Fintype Ω] [Nonempty Ω] {n : ℕ}
    (α D : Fin (n + 1) → ℝ) (p : Ω → ℝ) (DT : Ω → Fin (n + 1) → ℝ)
    (hp : ∀ ω, 0 < p ω) (hα : ∀ i, 0 < α i) (hDT : ∀ ω i, 0 < DT ω i)
    (hbond : ∀ i, ∑ ω, p ω * DT ω i = D i) :
    0 < ∑ i, α i * D i := by
  apply Finset.sum_pos _ Finset.univ_nonempty
  intro i _
  rw [← hbond i]
  exact mul_pos (hα i) (Finset.sum_pos (fun ω _ => mul_pos (hp ω) (hDT ω i)) Finset.univ_nonempty)

#print axioms swaption_annuity_pos

lemma swaption_black_core (F K s : ℝ) (hF : 0 < F) (hK : 0 < K) (hs : 0 < s) :
    (∫ z, max (F * Real.exp (-(s ^ 2 / 2) + s * z) - K) 0 ∂(gaussianReal 0 1)
        = F * cdf (gaussianReal 0 1) ((Real.log (F / K) + s ^ 2 / 2) / s)
          - K * cdf (gaussianReal 0 1) ((Real.log (F / K) + s ^ 2 / 2) / s - s)) ∧
    (∫ z, max (K - F * Real.exp (-(s ^ 2 / 2) + s * z)) 0 ∂(gaussianReal 0 1)
        = K * cdf (gaussianReal 0 1) (-((Real.log (F / K) + s ^ 2 / 2) / s - s))
          - F * cdf (gaussianReal 0 1) (-((Real.log (F / K) + s ^ 2 / 2) / s))) := by
  set c : ℝ := -((Real.log (F / K) + s ^ 2 / 2) / s - s) with hc_def
  have hc : c = (Real.log K - Real.log F + s ^ 2 / 2) / s := by
    rw [hc_def, Real.log_div hF.ne' hK.ne']
    field_simp
    ring
  have hiff : ∀ z, K < F * Real.exp (-(s ^ 2 / 2) + s * z) ↔ c < z := by
    intro z
    rw [← Real.log_lt_log_iff hK (mul_pos hF (Real.exp_pos _)),
      Real.log_mul hF.ne' (Real.exp_pos _).ne', Real.log_exp, hc, div_lt_iff₀ hs]
    constructor <;> intro h <;> nlinarith
  have hexp : ∀ z, F * Real.exp (-(s ^ 2 / 2) + s * z) = F * Real.exp (s * z - s ^ 2 / 2) := by
    intro z; congr 2; ring
  have hint : Integrable (fun z => Real.exp (s * z - s ^ 2 / 2)) (gaussianReal 0 1) := by
    refine ((integrable_exp_mul_gaussianReal (μ := 0) (v := 1) s).mul_const
      (Real.exp (-(s ^ 2 / 2)))).congr (ae_of_all _ (fun z => ?_))
    simp only
    rw [← Real.exp_add]; ring_nf
  constructor
  · have hpt : (fun z => max (F * Real.exp (-(s ^ 2 / 2) + s * z) - K) 0)
        = (Set.Ioi c).indicator (fun z => F * Real.exp (s * z - s ^ 2 / 2) - K) := by
      funext z
      by_cases hz : c < z
      · rw [Set.indicator_of_mem (Set.mem_Ioi.mpr hz), ← hexp,
          max_eq_left (by linarith [(hiff z).mpr hz])]
      · rw [Set.indicator_of_notMem (by simpa using hz),
          max_eq_right (by linarith [show ¬ K < _ from fun h => hz ((hiff z).mp h)] )]
    rw [hpt, integral_indicator measurableSet_Ioi, integral_sub
      ((hint.const_mul F).integrableOn) (integrable_const _).integrableOn,
      integral_const_mul, swaption_tilt s _ measurableSet_Ioi, setIntegral_const,
      swaption_shift s _ measurableSet_Ioi, Set.preimage_add_const_Ioi, swaption_Ioi, swaption_Ioi,
      smul_eq_mul]
    have e1 : -(c - s) = (Real.log (F / K) + s ^ 2 / 2) / s := by rw [hc_def]; ring
    have e2 : -c = (Real.log (F / K) + s ^ 2 / 2) / s - s := by rw [hc_def]; ring
    rw [e1, e2]
    ring
  · have hpt : (fun z => max (K - F * Real.exp (-(s ^ 2 / 2) + s * z)) 0)
        = (Set.Iic c).indicator (fun z => K - F * Real.exp (s * z - s ^ 2 / 2)) := by
      funext z
      by_cases hz : z ≤ c
      · rw [Set.indicator_of_mem (Set.mem_Iic.mpr hz), ← hexp]
        have := mt (hiff z).mp (not_lt.mpr hz)
        rw [max_eq_left (by linarith [not_lt.mp this])]
      · rw [Set.indicator_of_notMem (by simpa using hz)]
        have := (hiff z).mpr (not_le.mp hz)
        rw [max_eq_right (by linarith)]
    rw [hpt, integral_indicator measurableSet_Iic, integral_sub
      (integrable_const _).integrableOn ((hint.const_mul F).integrableOn),
      integral_const_mul, swaption_tilt s _ measurableSet_Iic, setIntegral_const,
      swaption_shift s _ measurableSet_Iic, Set.preimage_add_const_Iic, ← cdf_eq_real,
      ← cdf_eq_real, smul_eq_mul]
    have e3 : c - s = -((Real.log (F / K) + s ^ 2 / 2) / s) := by rw [hc_def]; ring
    rw [e3]
    ring

#print axioms swaption_black_core

/-- Black's formula for swaptions. Take notional `L`, annuity `A`, forward swap rate `F > 0`,
strike `K > 0`, volatility `σ > 0` and expiry `T > 0`. If the swap rate at expiry is lognormal,
`S_T = F · exp(-σ²T/2 + σ√T z)` with `z` a standard bell-curve draw (the model of Step 3), then
the payer swaption `L · A · E[max(S_T - K, 0)]` equals `L · A · (F N(d₁) - K N(d₂))` and the
receiver swaption `L · A · E[max(K - S_T, 0)]` equals `L · A · (K N(-d₂) - F N(-d₁))`, where
`d₁ = (ln(F/K) + σ²T/2)/(σ√T)`, `d₂ = d₁ - σ√T` and `N` is the standard normal distribution
function. -/
theorem swaption_black_formula (L A F K σ T : ℝ)
    (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let N : ℝ → ℝ := fun x => cdf (gaussianReal 0 1) x
    let d₁ := (Real.log (F / K) + σ ^ 2 * T / 2) / (σ * √T)
    let d₂ := d₁ - σ * √T
    let S : ℝ → ℝ := fun z => F * Real.exp (-(σ ^ 2 * T / 2) + σ * √T * z)
    (L * A * ∫ z, max (S z - K) 0 ∂(gaussianReal 0 1)
        = L * A * (F * N d₁ - K * N d₂)) ∧
    (L * A * ∫ z, max (K - S z) 0 ∂(gaussianReal 0 1)
        = L * A * (K * N (-d₂) - F * N (-d₁))) := by
  intro N d₁ d₂ S
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  obtain ⟨h1, h2⟩ := swaption_black_core F K (σ * √T) hF hK hs
  have hs2 : σ ^ 2 * T = (σ * √T) ^ 2 := by rw [mul_pow, Real.sq_sqrt hT.le]
  simp only [N, d₁, d₂, S]
  rw [hs2, h1, h2]
  exact ⟨rfl, rfl⟩

/-- Payer minus receiver is exactly the forward swap, in any model. Finitely many outcomes `ω`
on the expiry date carry positive state prices `p ω` (today's price of one dollar paid at expiry
in that outcome). The swap pays fixed on dates `T₁ … Tₙ` (indexed by `Fin (n+1)`) with positive
accruals `α i`; `DT ω i > 0` is the discount factor to `Tᵢ` as it will stand at expiry, and the
state prices reprice every bond: `∑ p = D₀` and `∑ p · DT i = D i`. With today's annuity
`A = ∑ αᵢ D(Tᵢ)`, forward swap rate `F = (D₀ - D(Tₙ))/A`, expiry annuity `A_T = ∑ αᵢ D_T(Tᵢ)` and
expiry swap rate `S_T = (1 - D_T(Tₙ))/A_T`, the payer (paying `L A_T max(S_T - K, 0)`) minus the
receiver (paying `L A_T max(K - S_T, 0)`) is worth `L · A · (F - K)` today. -/
theorem payer_minus_receiver_eq_forward_swap {Ω : Type*} [Fintype Ω] [Nonempty Ω] {n : ℕ}
    (L K D₀ : ℝ) (α D : Fin (n + 1) → ℝ) (p : Ω → ℝ) (DT : Ω → Fin (n + 1) → ℝ)
    (hp : ∀ ω, 0 < p ω) (hα : ∀ i, 0 < α i) (hDT : ∀ ω i, 0 < DT ω i)
    (hcash : ∑ ω, p ω = D₀) (hbond : ∀ i, ∑ ω, p ω * DT ω i = D i) :
    let A := ∑ i, α i * D i
    let F := (D₀ - D (Fin.last n)) / A
    let AT : Ω → ℝ := fun ω => ∑ i, α i * DT ω i
    let ST : Ω → ℝ := fun ω => (1 - DT ω (Fin.last n)) / AT ω
    (∑ ω, p ω * (L * AT ω * max (ST ω - K) 0))
      - (∑ ω, p ω * (L * AT ω * max (K - ST ω) 0)) = L * A * (F - K) := by
  intro A F AT ST
  have hA : 0 < A := swaption_annuity_pos α D p DT hp hα hDT hbond
  have hAT : ∀ ω, 0 < AT ω := fun ω =>
    Finset.sum_pos (fun i _ => mul_pos (hα i) (hDT ω i)) Finset.univ_nonempty
  have hsumAT : ∑ ω, p ω * AT ω = A := swaption_sum_annuity α D p DT hbond
  have hlast : ∑ ω, p ω * DT ω (Fin.last n) = D (Fin.last n) := hbond _
  rw [← Finset.sum_sub_distrib]
  have hpt : ∀ ω, p ω * (L * AT ω * max (ST ω - K) 0) - p ω * (L * AT ω * max (K - ST ω) 0)
      = L * (p ω - p ω * DT ω (Fin.last n) - K * (p ω * AT ω)) := by
    intro ω
    have hmax : max (ST ω - K) 0 - max (K - ST ω) 0 = ST ω - K := by
      rcases le_total (ST ω) K with h | h
      · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
      · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
    have hST : AT ω * ST ω = 1 - DT ω (Fin.last n) := by
      simp only [ST]; field_simp [(hAT ω).ne']
    calc p ω * (L * AT ω * max (ST ω - K) 0) - p ω * (L * AT ω * max (K - ST ω) 0)
        = p ω * L * AT ω * (max (ST ω - K) 0 - max (K - ST ω) 0) := by ring
      _ = p ω * L * (AT ω * ST ω) - L * K * (p ω * AT ω) := by rw [hmax]; ring
      _ = _ := by rw [hST]; ring
  simp_rw [hpt]
  rw [← Finset.mul_sum, Finset.sum_sub_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
    hcash, hlast, hsumAT]
  simp only [F]
  field_simp

/-- The annuity measure. In the same finite model, the weights `q ω = p ω · A_T(ω) / A` are
positive and add to one, and under them the average of the expiry swap rate `S_T` is today's
forward swap rate `F`: the swap rate has no drift when money is counted in annuities. -/
theorem annuity_measure_forward_swap_rate {Ω : Type*} [Fintype Ω] [Nonempty Ω] {n : ℕ}
    (D₀ : ℝ) (α D : Fin (n + 1) → ℝ) (p : Ω → ℝ) (DT : Ω → Fin (n + 1) → ℝ)
    (hp : ∀ ω, 0 < p ω) (hα : ∀ i, 0 < α i) (hDT : ∀ ω i, 0 < DT ω i)
    (hcash : ∑ ω, p ω = D₀) (hbond : ∀ i, ∑ ω, p ω * DT ω i = D i) :
    let A := ∑ i, α i * D i
    let F := (D₀ - D (Fin.last n)) / A
    let AT : Ω → ℝ := fun ω => ∑ i, α i * DT ω i
    let ST : Ω → ℝ := fun ω => (1 - DT ω (Fin.last n)) / AT ω
    let q : Ω → ℝ := fun ω => p ω * AT ω / A
    (∀ ω, 0 < q ω) ∧ ∑ ω, q ω = 1 ∧ ∑ ω, q ω * ST ω = F := by
  intro A F AT ST q
  have hA : 0 < A := swaption_annuity_pos α D p DT hp hα hDT hbond
  have hAT : ∀ ω, 0 < AT ω := fun ω =>
    Finset.sum_pos (fun i _ => mul_pos (hα i) (hDT ω i)) Finset.univ_nonempty
  have hsumAT : ∑ ω, p ω * AT ω = A := swaption_sum_annuity α D p DT hbond
  have hlast : ∑ ω, p ω * DT ω (Fin.last n) = D (Fin.last n) := hbond _
  refine ⟨fun ω => div_pos (mul_pos (hp ω) (hAT ω)) hA, ?_, ?_⟩
  · simp only [q]
    rw [← Finset.sum_div, hsumAT, div_self hA.ne']
  · have hpt : ∀ ω, q ω * ST ω = (p ω - p ω * DT ω (Fin.last n)) / A := by
      intro ω
      simp only [q, ST]
      field_simp [(hAT ω).ne']
    simp_rw [hpt]
    rw [← Finset.sum_div, Finset.sum_sub_distrib, hcash, hlast]

/-! The card's payoff chart, in basis points: swap rates 3.5 to 5.1 percent at expiry,
strike 4.30 percent. -/

-- payer payoff at each chart point: 0, 0, 0, 0, 0, 20, 40, 60, 80
example : ([350, 370, 390, 410, 430, 450, 470, 490, 510] : List ℤ).map (fun s => max (s - 430) 0)
    = [0, 0, 0, 0, 0, 20, 40, 60, 80] := by decide

-- receiver payoff at each chart point: 80, 60, 40, 20, 0, 0, 0, 0, 0
example : ([350, 370, 390, 410, 430, 450, 470, 490, 510] : List ℤ).map (fun s => max (430 - s) 0)
    = [80, 60, 40, 20, 0, 0, 0, 0, 0] := by decide

-- payer minus receiver is the rate gap at every chart point
example : ([350, 370, 390, 410, 430, 450, 470, 490, 510] : List ℤ).map
    (fun s => max (s - 430) 0 - max (430 - s) 0)
    = [-80, -60, -40, -20, 0, 20, 40, 60, 80] := by decide

#print axioms swaption_black_formula
#print axioms payer_minus_receiver_eq_forward_swap
#print axioms annuity_measure_forward_swap_rate
