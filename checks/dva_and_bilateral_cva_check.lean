-- DVA: with first-to-default weights, one party's CVA is the other party's DVA and both sides book the same price, and the card's closed forms for a bought call and for a forward follow.
import Mathlib.Algebra.Order.Group.PosPart
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic

open MeasureTheory

/-! The bilateral formula, as on the card.

A firm keeps its books on a trade whose clean (riskless) value to it at date `t` in the
future `ω` is `U t ω`; `P` is the pricing-world measure and `D(t) = e^{-rt}` the discount
factor. Its counterparty has recovery `R_C` and hazard `λ_C`; the firm itself has recovery
`R_O` and hazard `λ_O`. With `x⁺ = max x 0` and `x⁻ = max (-x) 0` (Mathlib's `posPart` and
`negPart`):

* `EPE(t) = E[D(t) U_t⁺]`, `ENE(t) = E[D(t) U_t⁻]`;
* `CVA = (1 - R_C) ∫₀ᵀ λ_C e^{-(λ_C + λ_O) t} EPE(t) dt`;
* `DVA = (1 - R_O) ∫₀ᵀ λ_O e^{-(λ_C + λ_O) t} ENE(t) dt`;
* `BCVA = CVA - DVA`, and the risky value is `V₀ - BCVA`. -/

/-- The CVA term: loss fraction of the counterparty times the integral over the trade's life
of the counterparty's first-to-default weight times the discounted expected positive
exposure. Arguments: the counterparty's recovery `RC` and hazard `lamC`, then the firm's own
hazard `lamO`. -/
noncomputable def cvaTerm {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (r T : ℝ)
    (U : ℝ → Ω → ℝ) (RC lamC lamO : ℝ) : ℝ :=
  (1 - RC) * ∫ t in (0 : ℝ)..T,
    lamC * Real.exp (-(lamC + lamO) * t) * ∫ ω, Real.exp (-r * t) * (U t ω)⁺ ∂P

/-- The DVA term: the firm's own loss fraction times the integral over the trade's life of
its own first-to-default weight times the discounted expected negative exposure. Arguments:
the firm's own recovery `RO` and hazard `lamO`, then the counterparty's hazard `lamC`. -/
noncomputable def dvaTerm {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (r T : ℝ)
    (U : ℝ → Ω → ℝ) (RO lamO lamC : ℝ) : ℝ :=
  (1 - RO) * ∫ t in (0 : ℝ)..T,
    lamO * Real.exp (-(lamC + lamO) * t) * ∫ ω, Real.exp (-r * t) * (U t ω)⁻ ∂P

/-- One party's CVA is the other's DVA, and netting gives both desks the same price.
The bank values the trade at `V`, Northwind at `-V`. Northwind's counterparty is the bank
(recovery `RO`, hazard `lamO`) and Northwind itself has recovery `RC`, hazard `lamC`. Then
Northwind's CVA is the bank's DVA, Northwind's DVA is the bank's CVA, and the price Northwind
books, `-V₀ - BCVA_N`, is exactly minus the price the bank books, `V₀ - BCVA_B`: one contract,
one price. -/
theorem one_partys_cva_is_the_others_dva
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (r T : ℝ) (V : ℝ → Ω → ℝ)
    (RC RO lamC lamO V₀ : ℝ) :
    cvaTerm P r T (fun t ω => -V t ω) RO lamO lamC = dvaTerm P r T V RO lamO lamC ∧
    dvaTerm P r T (fun t ω => -V t ω) RC lamC lamO = cvaTerm P r T V RC lamC lamO ∧
    (-V₀) - (cvaTerm P r T (fun t ω => -V t ω) RO lamO lamC
              - dvaTerm P r T (fun t ω => -V t ω) RC lamC lamO)
      = -(V₀ - (cvaTerm P r T V RC lamC lamO - dvaTerm P r T V RO lamO lamC)) := by
  have h1 : cvaTerm P r T (fun t ω => -V t ω) RO lamO lamC = dvaTerm P r T V RO lamO lamC := by
    simp only [cvaTerm, dvaTerm, posPart_neg, add_comm lamO lamC]
  have h2 : dvaTerm P r T (fun t ω => -V t ω) RC lamC lamO = cvaTerm P r T V RC lamC lamO := by
    simp only [cvaTerm, dvaTerm, negPart_neg, add_comm lamO lamC]
  refine ⟨h1, h2, ?_⟩
  rw [h1, h2]
  ring

/-- The bought option (Step 4). Once the premium is paid the option is never a debt of the
buyer (`V ≥ 0`), and the discounted average of its value is today's price `C₀` at every date
of its life. Then the buyer's DVA is zero and its bilateral CVA has the closed form
`(1 - R_C) C₀ · λ_C / (λ_C + λ_O) · (1 - e^{-(λ_C + λ_O) T})`, where the last two factors are
the chance that the counterparty defaults first and before `T`. Hazards are rates of default,
so they are not negative. -/
theorem bought_option_bilateral_cva_closed_form_and_zero_dva
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (r T : ℝ) (V : ℝ → Ω → ℝ)
    (RC RO lamC lamO C₀ : ℝ) (hT : 0 ≤ T) (hC : 0 ≤ lamC) (hO : 0 ≤ lamO)
    (hbought : ∀ t ω, 0 ≤ V t ω)
    (hprice : ∀ t ∈ Set.Icc 0 T, ∫ ω, Real.exp (-r * t) * V t ω ∂P = C₀) :
    cvaTerm P r T V RC lamC lamO
        = (1 - RC) * C₀ * (lamC / (lamC + lamO)) * (1 - Real.exp (-(lamC + lamO) * T)) ∧
      dvaTerm P r T V RO lamO lamC = 0 := by
  have hpos : ∀ t ω, (V t ω)⁺ = V t ω := fun t ω => posPart_eq_self.mpr (hbought t ω)
  have hneg : ∀ t ω, (V t ω)⁻ = 0 := fun t ω => negPart_eq_zero.mpr (hbought t ω)
  constructor
  · have hcongr : ∫ t in (0:ℝ)..T, lamC * Real.exp (-(lamC + lamO) * t)
          * ∫ ω, Real.exp (-r * t) * (V t ω)⁺ ∂P
        = ∫ t in (0:ℝ)..T, lamC * C₀ * Real.exp (-(lamC + lamO) * t) := by
      apply intervalIntegral.integral_congr
      intro t ht
      rw [Set.uIcc_of_le hT] at ht
      dsimp only
      simp only [hpos, hprice t ht]
      ring
    unfold cvaTerm
    rw [hcongr, intervalIntegral.integral_const_mul]
    rcases eq_or_lt_of_le (add_nonneg hC hO) with h0 | hkpos
    · have hC0 : lamC = 0 := by linarith
      rw [← h0, hC0]
      simp
    · have hderiv : ∀ x ∈ Set.uIcc 0 T,
          HasDerivAt (fun t => -Real.exp (-(lamC + lamO) * t) / (lamC + lamO))
            (Real.exp (-(lamC + lamO) * x)) x := by
        intro x _
        have := (((hasDerivAt_id x).const_mul (-(lamC + lamO))).exp.neg).div_const (lamC + lamO)
        convert this using 1
        · funext y
          simp only [id, Pi.neg_apply]
        · simp only [id]
          field_simp
      have hint : IntervalIntegrable (fun t => Real.exp (-(lamC + lamO) * t)) volume 0 T :=
        (Real.continuous_exp.comp (continuous_const.mul continuous_id)).intervalIntegrable 0 T
      rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint]
      simp only [mul_zero, Real.exp_zero]
      field_simp
      ring
  · unfold dvaTerm
    simp [hneg]

/-- The forward (Step 5). If the trade's discounted average value stays at zero at every
date of its life (as for a forward struck so it is worth zero today), its expected positive
and negative exposures are equal, so CVA and DVA differ only through hazards and recoveries:
`(1 - R_O) λ_O · CVA = (1 - R_C) λ_C · DVA`. -/
theorem zero_value_trade_cva_dva_differ_only_by_hazard_and_recovery
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (r T : ℝ) (V : ℝ → Ω → ℝ)
    (RC RO lamC lamO : ℝ) (hT : 0 ≤ T)
    (hint : ∀ t ∈ Set.Icc 0 T, Integrable (V t) P)
    (hzero : ∀ t ∈ Set.Icc 0 T, ∫ ω, Real.exp (-r * t) * V t ω ∂P = 0) :
    (1 - RO) * lamO * cvaTerm P r T V RC lamC lamO
      = (1 - RC) * lamC * dvaTerm P r T V RO lamO lamC := by
  have heq : ∀ t ∈ Set.Icc 0 T, ∫ ω, Real.exp (-r * t) * (V t ω)⁺ ∂P
      = ∫ ω, Real.exp (-r * t) * (V t ω)⁻ ∂P := by
    intro t ht
    have hi := hint t ht
    have hp : Integrable (fun ω => (V t ω)⁺) P := hi.pos_part
    have hn : Integrable (fun ω => (V t ω)⁻) P := hi.neg_part
    have hsplit : ∫ ω, V t ω ∂P = ∫ ω, (V t ω)⁺ ∂P - ∫ ω, (V t ω)⁻ ∂P := by
      rw [← integral_sub hp hn]
      simp only [posPart_sub_negPart]
    have hz := hzero t ht
    rw [integral_const_mul] at hz
    rw [integral_const_mul, integral_const_mul]
    have hexp : Real.exp (-r * t) ≠ 0 := (Real.exp_pos _).ne'
    have h0 : ∫ ω, V t ω ∂P = 0 := by
      rcases mul_eq_zero.mp hz with h | h
      · exact absurd h hexp
      · exact h
    rw [hsplit] at h0
    rw [sub_eq_zero.mp h0]
  have hcongr : ∫ t in (0:ℝ)..T, lamC * Real.exp (-(lamC + lamO) * t)
        * ∫ ω, Real.exp (-r * t) * (V t ω)⁺ ∂P
      = lamC * ∫ t in (0:ℝ)..T, Real.exp (-(lamC + lamO) * t)
        * ∫ ω, Real.exp (-r * t) * (V t ω)⁻ ∂P := by
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_congr
    intro t ht
    rw [Set.uIcc_of_le hT] at ht
    dsimp only
    rw [heq t ht]
    ring
  have hcongr2 : ∫ t in (0:ℝ)..T, lamO * Real.exp (-(lamC + lamO) * t)
        * ∫ ω, Real.exp (-r * t) * (V t ω)⁻ ∂P
      = lamO * ∫ t in (0:ℝ)..T, Real.exp (-(lamC + lamO) * t)
        * ∫ ω, Real.exp (-r * t) * (V t ω)⁻ ∂P := by
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_congr
    intro t _
    dsimp only
    ring
  unfold cvaTerm dvaTerm
  rw [hcongr, hcongr2]
  ring

/-- Step 0: Northwind defaults owing $10 with recovery 40%; the bank collects $4 and loses
$6, which is Northwind's saving. -/
example : (40 : ℚ) / 100 * 10 = 4 ∧ (1 - (40 : ℚ) / 100) * 10 = 6 := by norm_num

/-- Hazards 2% (Northwind) and 1% (the bank): Northwind defaults first in the fraction
`λ_C / (λ_C + λ_O) = 2/3` of the default scenarios. -/
example : ((2 : ℚ) / 100) / (2 / 100 + 1 / 100) = 2 / 3 := by norm_num

/-- The forward with both recoveries 40% and hazards 2% and 1%: the relation of the last
theorem makes the CVA exactly twice the DVA (0.0614 against 0.0307 on the card). -/
example (cva dva : ℚ)
    (h : (1 - 40 / 100) * (1 / 100) * cva = (1 - 40 / 100) * (2 / 100) * dva) :
    cva = 2 * dva := by linarith

#print axioms one_partys_cva_is_the_others_dva
#print axioms bought_option_bilateral_cva_closed_form_and_zero_dva
#print axioms zero_value_trade_cva_dva_differ_only_by_hazard_and_recovery
