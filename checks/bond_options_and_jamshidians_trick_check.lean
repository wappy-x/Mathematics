-- Bond options: when every zero price falls as the one short rate rises and every payment is positive, a call on a coupon bond pays and costs exactly the same as a bundle of calls on its zeros struck at their prices at the one rate r* where the bond is worth the strike, and in Hull-White that rate exists and is unique.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Integral.Bochner.Basic

open MeasureTheory

/-- Jamshidian's split, payoff form. A coupon bond pays `c i > 0` at its `n` dates after
expiry, and on expiry day the zero for date `i` is worth `P i r` when the short rate is `r`,
with every zero price falling as the rate rises (one random driver). If `r*` is the rate at
which the bond is worth the strike `X`, then for every rate on expiry day the call on the
bond pays exactly what the bundle of calls on the zeros pays, each zero struck at its own
price at `r*`: `max (∑ cᵢ Pᵢ(r) - X) 0 = ∑ cᵢ max (Pᵢ(r) - Pᵢ(r*)) 0`. -/
theorem jamshidian_payoff_split {n : ℕ} (c : Fin n → ℝ) (P : Fin n → ℝ → ℝ)
    (hc : ∀ i, 0 < c i) (hP : ∀ i, Antitone (P i))
    (X rstar : ℝ) (hX : ∑ i, c i * P i rstar = X) (r : ℝ) :
    max (∑ i, c i * P i r - X) 0 = ∑ i, c i * max (P i r - P i rstar) 0 := by
  have hdiff : ∑ i, c i * P i r - X = ∑ i, c i * (P i r - P i rstar) := by
    rw [← hX, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun i _ => by ring
  rw [hdiff]
  rcases le_total r rstar with h | h
  · have hge : ∀ i, 0 ≤ P i r - P i rstar := fun i => sub_nonneg.mpr (hP i h)
    rw [max_eq_left (Finset.sum_nonneg fun i _ => mul_nonneg (hc i).le (hge i))]
    refine Finset.sum_congr rfl fun i _ => by rw [max_eq_left (hge i)]
  · have hle : ∀ i, P i r - P i rstar ≤ 0 := fun i => sub_nonpos.mpr (hP i h)
    rw [max_eq_right (Finset.sum_nonpos fun i _ =>
      mul_nonpos_of_nonneg_of_nonpos (hc i).le (hle i))]
    symm
    refine Finset.sum_eq_zero fun i _ => by rw [max_eq_right (hle i), mul_zero]

/-- Jamshidian's split, price form. Today's price of a payoff is the average, under a
pricing measure `μ`, of the discount `D` along the rate's path times the payoff, where `R ω`
is the short rate on expiry day. Since the payoffs agree on every outcome, the price of the
call on the coupon bond equals the sum of `cᵢ` times the prices of the calls on the zeros,
each struck at `Pᵢ(r*)`. -/
theorem jamshidian_price_split {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    {n : ℕ} (c : Fin n → ℝ) (P : Fin n → ℝ → ℝ)
    (hc : ∀ i, 0 < c i) (hP : ∀ i, Antitone (P i))
    (X rstar : ℝ) (hX : ∑ i, c i * P i rstar = X)
    (R D : Ω → ℝ)
    (hint : ∀ i, Integrable (fun ω => D ω * max (P i (R ω) - P i rstar) 0) μ) :
    ∫ ω, D ω * max (∑ i, c i * P i (R ω) - X) 0 ∂μ =
      ∑ i, c i * ∫ ω, D ω * max (P i (R ω) - P i rstar) 0 ∂μ := by
  have hpt : (fun ω => D ω * max (∑ i, c i * P i (R ω) - X) 0) =
      fun ω => ∑ i, c i * (D ω * max (P i (R ω) - P i rstar) 0) := by
    funext ω
    rw [jamshidian_payoff_split c P hc hP X rstar hX (R ω), Finset.mul_sum]
    refine Finset.sum_congr rfl fun i _ => by ring
  rw [hpt, integral_finsetSum _ fun i _ => (hint i).const_mul (c i)]
  refine Finset.sum_congr rfl fun i _ => integral_const_mul _ _

/-- The critical rate exists and is unique. In Hull-White, on expiry day `T` the zero due
at `Tᵢ > T` is worth `Aᵢ · exp (-B(Tᵢ - T) · r)` with `Aᵢ > 0` and rate sensitivity
`B(τ) = (1 - e^{-aτ}) / a` for reversion speed `a > 0`. For a bond with at least one
payment, all payments positive, and any strike `X > 0`, there is exactly one short rate
`r*` at which the bond is worth `X`. -/
theorem exists_unique_critical_rate {n : ℕ} (hn : 0 < n) (a T X : ℝ) (ha : 0 < a)
    (hX : 0 < X) (c A Ti : Fin n → ℝ) (hc : ∀ i, 0 < c i) (hA : ∀ i, 0 < A i)
    (hT : ∀ i, T < Ti i) :
    ∃! r : ℝ, ∑ i, c i * (A i * Real.exp (-((1 - Real.exp (-(a * (Ti i - T)))) / a) * r)) = X := by
  set B : Fin n → ℝ := fun i => (1 - Real.exp (-(a * (Ti i - T)))) / a with hBdef
  have hB : ∀ i, 0 < B i := by
    intro i
    have h1 : 0 < a * (Ti i - T) := mul_pos ha (sub_pos.mpr (hT i))
    have h2 : Real.exp (-(a * (Ti i - T))) < 1 := Real.exp_lt_one_iff.mpr (by linarith)
    exact div_pos (by linarith) ha
  set f : ℝ → ℝ := fun r => ∑ i, c i * (A i * Real.exp (-B i * r)) with hfdef
  show ∃! r : ℝ, f r = X
  have hcont : Continuous f := by
    simp only [hfdef]; fun_prop
  have hanti : StrictAnti f := by
    intro r s hrs
    have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
    refine Finset.sum_lt_sum_of_nonempty Finset.univ_nonempty fun i _ => ?_
    have hci : 0 < c i * A i := mul_pos (hc i) (hA i)
    have : Real.exp (-B i * s) < Real.exp (-B i * r) :=
      Real.exp_lt_exp.mpr (by nlinarith [hB i])
    nlinarith
  have htop : Filter.Tendsto f Filter.atTop (nhds 0) := by
    have : Filter.Tendsto f Filter.atTop (nhds (∑ _i : Fin n, (0:ℝ))) := by
      refine tendsto_finsetSum _ fun i _ => ?_
      have h1 : Filter.Tendsto (fun r : ℝ => -B i * r) Filter.atTop Filter.atBot :=
        Filter.tendsto_id.const_mul_atTop_of_neg (by linarith [hB i])
      have h2 := (Real.tendsto_exp_atBot.comp h1).const_mul (c i * A i)
      simpa [mul_assoc] using h2
    simpa using this
  have hbot : Filter.Tendsto f Filter.atBot Filter.atTop := by
    let i0 : Fin n := ⟨0, hn⟩
    have h1 : Filter.Tendsto (fun r : ℝ => -B i0 * r) Filter.atBot Filter.atTop :=
      Filter.tendsto_id.const_mul_atBot_of_neg (by linarith [hB i0])
    have h2 : Filter.Tendsto (fun r : ℝ => c i0 * (A i0 * Real.exp (-B i0 * r)))
        Filter.atBot Filter.atTop := by
      have := (Real.tendsto_exp_atTop.comp h1).const_mul_atTop (mul_pos (hc i0) (hA i0))
      simpa [Function.comp_def, mul_assoc] using this
    refine Filter.tendsto_atTop_mono (fun r => ?_) h2
    exact Finset.single_le_sum (f := fun i => c i * (A i * Real.exp (-B i * r)))
      (fun i _ => mul_nonneg (hc i).le (mul_nonneg (hA i).le (Real.exp_pos _).le))
      (Finset.mem_univ i0)
  obtain ⟨r2, hr2⟩ := ((htop.eventually (gt_mem_nhds hX)).and (Filter.eventually_ge_atTop 0)).exists
  obtain ⟨r1, hr1⟩ := ((hbot.eventually (Filter.eventually_gt_atTop X)).and (Filter.eventually_le_atBot 0)).exists
  have hmem : X ∈ Set.uIcc (f r1) (f r2) :=
    Set.mem_uIcc.mpr (Or.inr ⟨hr2.1.le, hr1.1.le⟩)
  obtain ⟨r, -, hr⟩ := intermediate_value_uIcc hcont.continuousOn hmem
  exact ⟨r, hr, fun s hs => hanti.injective (hs.trans hr.symm)⟩

#print axioms jamshidian_payoff_split
#print axioms jamshidian_price_split
#print axioms exists_unique_critical_rate
