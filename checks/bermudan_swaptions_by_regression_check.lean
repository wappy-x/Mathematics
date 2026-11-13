-- Bermudan swaptions: every legal exercise rule prices the option from below and every fair game with zero start prices it from above, the fair game built from the true value makes the upper bound exact, and the floating leg of a swap is worth one minus the final bond.
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Process.Stopping
import Mathlib.Probability.Martingale.OptionalStopping

open MeasureTheory

variable {Ω : Type*} {m0 : MeasurableSpace Ω}


theorem bermudan_stoppedValue_le_dual
    {μ : Measure Ω} [IsProbabilityMeasure μ] {ℱ : Filtration ℕ m0} {h M : ℕ → Ω → ℝ} {N : ℕ}
    (hN : 1 ≤ N) (hint : ∀ e, 1 ≤ e → e ≤ N → Integrable (h e) μ)
    (hM : Martingale M ℱ μ) (hM0 : M 0 = 0)
    (τ : Ω → WithTop ℕ) (hτ : IsStoppingTime ℱ τ) (hτb : ∀ ω, 1 ≤ τ ω ∧ τ ω ≤ N) :
    ∫ ω, stoppedValue h τ ω ∂μ ≤ ∫ ω, (Finset.Icc 1 N).sup' (Finset.nonempty_Icc.mpr hN)
        (fun e => h e ω - M e ω) ∂μ := by
  -- every path stops at a finite year in `[1, N]`
  have hval : ∀ ω, ∃ n : ℕ, τ ω = n ∧ 1 ≤ n ∧ n ≤ N := by
    intro ω
    obtain ⟨h1, h2⟩ := hτb ω
    cases hτω : τ ω with
    | top => rw [hτω] at h2; simp at h2
    | coe n =>
      rw [hτω] at h1 h2
      exact ⟨n, rfl, WithTop.coe_le_coe.mp h1, WithTop.coe_le_coe.mp h2⟩
  -- integrability of the stopped payoff
  set h' : ℕ → Ω → ℝ := fun e => if 1 ≤ e ∧ e ≤ N then h e else 0 with hh'
  have hh'int : ∀ e, Integrable (h' e) μ := by
    intro e
    by_cases he : 1 ≤ e ∧ e ≤ N
    · simp only [hh', he, and_self, ite_true]; exact hint e he.1 he.2
    · simp only [hh', he, ite_false]; exact integrable_zero _ _ _
  have hsv : stoppedValue h τ = stoppedValue h' τ := by
    funext ω
    obtain ⟨n, hn, h1, h2⟩ := hval ω
    simp only [stoppedValue, hn]
    show h n ω = h' n ω
    simp [hh', h1, h2]
  have hτN : ∀ ω, τ ω ≤ N := fun ω => (hτb ω).2
  have hint_h : Integrable (stoppedValue h τ) μ := by
    rw [hsv]; exact integrable_stoppedValue ℕ hτ hh'int hτN
  have hint_M : Integrable (stoppedValue M τ) μ :=
    hM.submartingale.integrable_stoppedValue hτ hτN
  -- the stopped fair game has mean zero
  have h0 : IsStoppingTime ℱ (fun _ => ((0 : ℕ) : WithTop ℕ)) := isStoppingTime_const ℱ 0
  have hle0 : (fun _ => ((0 : ℕ) : WithTop ℕ)) ≤ τ := fun ω => bot_le
  have hA := hM.submartingale.expected_stoppedValue_mono h0 hτ hle0 hτN
  have hB := hM.neg.submartingale.expected_stoppedValue_mono h0 hτ hle0 hτN
  have hneg : stoppedValue (-M) τ = -stoppedValue M τ := rfl
  have hneg0 : stoppedValue (-M) (fun _ => ((0 : ℕ) : WithTop ℕ)) = -M 0 := rfl
  have hc0 : stoppedValue M (fun _ => ((0 : ℕ) : WithTop ℕ)) = M 0 := rfl
  rw [hc0] at hA
  rw [hneg, hneg0] at hB
  simp only [Pi.neg_apply, integral_neg] at hB
  have hMτ : ∫ ω, stoppedValue M τ ω ∂μ = 0 := by
    rw [hM0] at hA hB; simp at hA hB; linarith
  -- integrability of the dual payoff
  have hsupint : Integrable (fun ω => (Finset.Icc 1 N).sup' (Finset.nonempty_Icc.mpr hN)
        (fun e => h e ω - M e ω)) μ := by
    have : (fun ω => (Finset.Icc 1 N).sup' (Finset.nonempty_Icc.mpr hN)
        (fun e => h e ω - M e ω)) = (Finset.Icc 1 N).sup' (Finset.nonempty_Icc.mpr hN)
        (fun e => h e - M e) := by
      funext ω; rw [Finset.sup'_apply]; rfl
    rw [this]
    refine Finset.sup'_induction _ _ (p := fun f => Integrable f μ) ?_ ?_
    · intro a ha b hb; exact ha.sup hb
    · intro e he
      rw [Finset.mem_Icc] at he
      exact (hint e he.1 he.2).sub (hM.integrable e)
  -- pathwise bound
  have hpath : ∀ ω, stoppedValue h τ ω - stoppedValue M τ ω ≤
      (Finset.Icc 1 N).sup' (Finset.nonempty_Icc.mpr hN) (fun e => h e ω - M e ω) := by
    intro ω
    obtain ⟨n, hn, h1, h2⟩ := hval ω
    have : stoppedValue h τ ω - stoppedValue M τ ω = h n ω - M n ω := by
      simp only [stoppedValue, hn]; rfl
    rw [this]
    exact Finset.le_sup' (fun e => h e ω - M e ω) (Finset.mem_Icc.mpr ⟨h1, h2⟩)
  calc ∫ ω, stoppedValue h τ ω ∂μ
      = ∫ ω, (stoppedValue h τ ω - stoppedValue M τ ω) ∂μ + ∫ ω, stoppedValue M τ ω ∂μ := by
        rw [integral_sub hint_h hint_M]; ring
    _ = ∫ ω, (stoppedValue h τ ω - stoppedValue M τ ω) ∂μ := by rw [hMτ, add_zero]
    _ ≤ _ := integral_mono (hint_h.sub hint_M) hsupint hpath

#print axioms bermudan_stoppedValue_le_dual

/-- **The primal-dual bracket.** Count switching values `h e` (exercise years `1 ≤ e ≤ N`) in
final-bond units, and let `V` be the best average `E[h τ]` over all legal rules: stopping times
`τ` with `1 ≤ τ ≤ N` that decide only from what has been seen so far. Then, times today's bond
price `p = P(0,6) ≥ 0`, any legal rule `τ̂` (such as the frozen regression rule) gives a lower bound
`p E[h τ̂] ≤ p V`, and any martingale (fair game) `M` with `M 0 = 0` gives an upper bound
`p V ≤ p E[max_{1 ≤ e ≤ N} (h e - M e)]`. -/
theorem bermudan_price_between_rule_and_dual_bound
    {μ : Measure Ω} [IsProbabilityMeasure μ] {ℱ : Filtration ℕ m0} {h M : ℕ → Ω → ℝ} {N : ℕ}
    (hN : 1 ≤ N) (hint : ∀ e, 1 ≤ e → e ≤ N → Integrable (h e) μ)
    (hM : Martingale M ℱ μ) (hM0 : M 0 = 0) (p : ℝ) (hp : 0 ≤ p)
    (τhat : Ω → WithTop ℕ) (hτhat : IsStoppingTime ℱ τhat) (hτhat_b : ∀ ω, 1 ≤ τhat ω ∧ τhat ω ≤ N) :
    let V : ℝ := sSup {x : ℝ | ∃ τ : Ω → WithTop ℕ, IsStoppingTime ℱ τ ∧
      (∀ ω, 1 ≤ τ ω ∧ τ ω ≤ N) ∧ x = ∫ ω, stoppedValue h τ ω ∂μ}
    p * ∫ ω, stoppedValue h τhat ω ∂μ ≤ p * V ∧
      p * V ≤ p * ∫ ω, (Finset.Icc 1 N).sup' (Finset.nonempty_Icc.mpr hN)
        (fun e => h e ω - M e ω) ∂μ := by
  intro V
  have hkey := fun τ hτ hb => bermudan_stoppedValue_le_dual (μ := μ) hN hint hM hM0 τ hτ hb
  have hmem : ∫ ω, stoppedValue h τhat ω ∂μ ∈ {x : ℝ | ∃ τ : Ω → WithTop ℕ, IsStoppingTime ℱ τ ∧
      (∀ ω, 1 ≤ τ ω ∧ τ ω ≤ N) ∧ x = ∫ ω, stoppedValue h τ ω ∂μ} := ⟨τhat, hτhat, hτhat_b, rfl⟩
  have hub : ∀ x ∈ {x : ℝ | ∃ τ : Ω → WithTop ℕ, IsStoppingTime ℱ τ ∧
      (∀ ω, 1 ≤ τ ω ∧ τ ω ≤ N) ∧ x = ∫ ω, stoppedValue h τ ω ∂μ},
      x ≤ ∫ ω, (Finset.Icc 1 N).sup' (Finset.nonempty_Icc.mpr hN) (fun e => h e ω - M e ω) ∂μ := by
    rintro x ⟨τ, hτ, hb, rfl⟩
    exact hkey τ hτ hb
  refine ⟨mul_le_mul_of_nonneg_left ?_ hp, mul_le_mul_of_nonneg_left ?_ hp⟩
  · exact le_csSup ⟨_, hub⟩ hmem
  · exact csSup_le ⟨_, hmem⟩ hub

/-- **The bound is exact for the best martingale.** Let `Y` be the true value in final-bond units:
`Y N = h N`, `Y e = max (h e) (E_e[Y (e+1)])` for `1 ≤ e < N`, and `Y 0 = E_0[Y 1]`. Build the
martingale from its increments, `M* e = ∑_{k=1}^{e} (Y k - E_{k-1}[Y k])`, so `M* 0 = 0`. Then on
every path and at every exercise year `1 ≤ e ≤ N`, `h e - M* e ≤ Y 0`. -/
theorem dual_bound_exact_for_value_martingale
    {μ : Measure Ω} {ℱ : Filtration ℕ m0} {h Y Mstar : ℕ → Ω → ℝ} {N : ℕ}
    (hYN : Y N = h N)
    (hY : ∀ e, 1 ≤ e → e < N → ∀ ω, Y e ω = max (h e ω) (μ[Y (e + 1) | ℱ e] ω))
    (hY0 : Y 0 = μ[Y 1 | ℱ 0])
    (hMstar : ∀ e ω, Mstar e ω = ∑ k ∈ Finset.Icc 1 e, (Y k ω - μ[Y k | ℱ (k - 1)] ω)) :
    ∀ ω, ∀ e ∈ Finset.Icc 1 N, h e ω - Mstar e ω ≤ Y 0 ω := by
  intro ω
  -- the value minus the fair game never rises above today's value
  have hstep : ∀ e, 1 ≤ e → e ≤ N → Y e ω - Mstar e ω ≤ Y 0 ω := by
    intro e
    induction e with
    | zero => intro h0; omega
    | succ e ih =>
      intro _ hle
      rcases Nat.eq_zero_or_pos e with rfl | hpos
      · rw [hMstar, hY0]
        simp
      · have hrec : Mstar (e + 1) ω = Mstar e ω + (Y (e + 1) ω - μ[Y (e + 1) | ℱ e] ω) := by
          rw [hMstar, hMstar, Finset.sum_Icc_succ_top (by omega)]
          simp
        have hYe := hY e hpos (by omega) ω
        have hce : μ[Y (e + 1) | ℱ e] ω ≤ Y e ω := by rw [hYe]; exact le_max_right _ _
        have := ih hpos (by omega)
        rw [hrec]
        linarith
  intro e he
  rw [Finset.mem_Icc] at he
  have hhY : h e ω ≤ Y e ω := by
    rcases lt_or_eq_of_le he.2 with hlt | rfl
    · rw [hY e he.1 hlt ω]; exact le_max_left _ _
    · rw [hYN]
  have := hstep e he.1 he.2
  linarith

/-- **The floating leg is worth one minus the final bond.** With positive annual forward rates
`L j`, and the bond price `P(e,m) = 1 / ((1 + L e) ⋯ (1 + L (m-1)))`, the floating payments `L m`
for the years from `e` to `n`, each paid at `m + 1`, are worth `1 - P(e,n)` at year `e`. -/
theorem floating_leg_worth_one_minus_bond (L : ℕ → ℝ) (hL : ∀ j, 0 < L j) (e n : ℕ) :
    ∑ m ∈ Finset.Ico e n, L m * ∏ j ∈ Finset.Ico e (m + 1), (1 + L j)⁻¹
      = 1 - ∏ j ∈ Finset.Ico e n, (1 + L j)⁻¹ := by
  rcases le_or_gt n e with hne | hen
  · rw [Finset.Ico_eq_empty_of_le hne]
    simp
  have hen2 : e ≤ n := hen.le
  clear hen
  induction n, hen2 using Nat.le_induction with
  | base => simp
  | succ n hen' ih =>
    rw [Finset.sum_Ico_succ_top hen', Finset.prod_Ico_succ_top hen', ih]
    have h1 : (1 + L n) ≠ 0 := by have := hL n; positivity
    field_simp
    ring

-- The card's forward swap rate on the flat 5% curve: (1.05⁻¹ - 1.05⁻⁶) / A(0) is exactly 5%,
-- with A(0) = 1.05⁻² + ⋯ + 1.05⁻⁶ and 1.05⁻¹ = 20/21.
example :
    ((20 : ℚ) / 21 - (20 / 21) ^ 6) /
        ((20 / 21) ^ 2 + (20 / 21) ^ 3 + (20 / 21) ^ 4 + (20 / 21) ^ 5 + (20 / 21) ^ 6)
      = 1 / 20 := by
  norm_num

-- The floating leg on the flat 5% curve, years 1 to 6: 5% paid in years 2..6 is worth P(0,1) - P(0,6).
example :
    (1 / 20 : ℚ) * ((20 / 21) ^ 2 + (20 / 21) ^ 3 + (20 / 21) ^ 4 + (20 / 21) ^ 5 + (20 / 21) ^ 6)
      = 20 / 21 - (20 / 21) ^ 6 := by
  norm_num

-- The frozen rule's exercise years on 400,000 fresh curves: years 1 to 5, then never.
example : 73696 + 55043 + 39622 + 30795 + 23489 + 177355 = 400000 := by norm_num

#print axioms bermudan_price_between_rule_and_dual_bound
#print axioms dual_bound_exact_for_value_martingale
#print axioms floating_leg_worth_one_minus_bond
