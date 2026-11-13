-- A spot price that reverts: if the log price at delivery is normal with the mean and variance the Schwartz model's moment equations give, its average price is the Schwartz futures formula, a future's log moves by e^(-κT) times a move in log spot, and the curve flattens at exp(a + σ²/4κ).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp

open Real MeasureTheory ProbabilityTheory Filter Topology

/-- The Schwartz one-factor futures price for delivery in `T` years, with spot `S`,
level `a` for the log price, speed `κ` and volatility `σ`. -/
noncomputable def schwartzFutures (κ a σ S T : ℝ) : ℝ :=
  Real.exp (Real.exp (-κ * T) * Real.log S + (1 - Real.exp (-κ * T)) * a
    + σ ^ 2 / (4 * κ) * (1 - Real.exp (-2 * κ * T)))

/-- A function continuous on `[0, ∞)` with zero derivative on `(0, ∞)` keeps its value at `0`. -/
lemma const_of_hasDerivAt_zero_pos (g : ℝ → ℝ) (hc : ContinuousOn g (Set.Ici 0))
    (hd : ∀ t, 0 < t → HasDerivAt g 0 t) (T : ℝ) (hT : 0 ≤ T) : g T = g 0 := by
  rcases hT.lt_or_eq with hT | hT
  · obtain ⟨c, hc', hcd⟩ := exists_hasDerivAt_eq_slope g (fun _ => (0 : ℝ)) hT
      (hc.mono Set.Icc_subset_Ici_self) (fun x hx => hd x hx.1)
    have hne : T - 0 ≠ 0 := by linarith
    have := hcd.symm
    rw [div_eq_zero_iff] at this
    rcases this with h | h
    · linarith
    · exact absurd h hne
  · rw [hT]

#print axioms const_of_hasDerivAt_zero_pos

/-- The futures formula. Let the average `m` of the log price obey `dm/dt = κ (a - m)` from
today's log spot, and its variance `v` obey `dv/dt = σ² - 2κv` from zero. If the log price
`X` at delivery `T` is normal with that average and variance, then the pricing-world average
of the delivery price `e^X` (the futures price) is
`exp (e^{-κT} ln S + (1 - e^{-κT}) a + σ²/(4κ) (1 - e^{-2κT}))`. -/
theorem schwartz_futures_formula {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (κ a σ S T : ℝ) (hκ : 0 < κ) (hT : 0 ≤ T)
    (m v : ℝ → ℝ)
    (hm0 : m 0 = Real.log S) (hm_cont : ContinuousOn m (Set.Ici 0))
    (hm : ∀ t, 0 < t → HasDerivAt m (κ * (a - m t)) t)
    (hv0 : v 0 = 0) (hv_cont : ContinuousOn v (Set.Ici 0))
    (hv : ∀ t, 0 < t → HasDerivAt v (σ ^ 2 - 2 * κ * v t) t)
    (X : Ω → ℝ) (hX : HasLaw X (gaussianReal (m T) (v T).toNNReal) P) :
    ∫ ω, Real.exp (X ω) ∂P =
      Real.exp (Real.exp (-κ * T) * Real.log S + (1 - Real.exp (-κ * T)) * a
        + σ ^ 2 / (4 * κ) * (1 - Real.exp (-2 * κ * T))) := by
  have hκ0 : κ ≠ 0 := hκ.ne'
  -- solve the mean equation
  have hmT : m T = a + (Real.log S - a) * Real.exp (-κ * T) := by
    let g : ℝ → ℝ := fun t => (m t - a) * Real.exp (κ * t)
    have hgc : ContinuousOn g (Set.Ici 0) :=
      (hm_cont.sub continuousOn_const).mul (by fun_prop)
    have hgd : ∀ t, 0 < t → HasDerivAt g 0 t := by
      intro t ht
      have he : HasDerivAt (fun x => Real.exp (κ * x)) (Real.exp (κ * t) * κ) t := by
        simpa using ((hasDerivAt_id t).const_mul κ).exp
      have h1 : HasDerivAt g
          (κ * (a - m t) * Real.exp (κ * t) + (m t - a) * (Real.exp (κ * t) * κ)) t :=
        ((hm t ht).sub_const a).mul he
      convert h1 using 1
      ring
    have := const_of_hasDerivAt_zero_pos g hgc hgd T hT
    simp only [g, hm0, mul_zero, Real.exp_zero, mul_one] at this
    have hE : Real.exp (κ * T) * Real.exp (-κ * T) = 1 := by
      rw [← Real.exp_add]; simp
    have : m T - a = (Real.log S - a) * Real.exp (-κ * T) := by
      calc m T - a = (m T - a) * Real.exp (κ * T) * Real.exp (-κ * T) := by
            rw [mul_assoc, hE, mul_one]
        _ = _ := by rw [this]
    linarith
  -- solve the variance equation
  have hvT : v T = σ ^ 2 / (2 * κ) * (1 - Real.exp (-2 * κ * T)) := by
    let g : ℝ → ℝ := fun t => (v t - σ ^ 2 / (2 * κ)) * Real.exp (2 * κ * t)
    have hgc : ContinuousOn g (Set.Ici 0) :=
      (hv_cont.sub continuousOn_const).mul (by fun_prop)
    have hgd : ∀ t, 0 < t → HasDerivAt g 0 t := by
      intro t ht
      have he : HasDerivAt (fun x => Real.exp (2 * κ * x)) (Real.exp (2 * κ * t) * (2 * κ)) t := by
        simpa using ((hasDerivAt_id t).const_mul (2 * κ)).exp
      have h1 : HasDerivAt g
          ((σ ^ 2 - 2 * κ * v t) * Real.exp (2 * κ * t)
            + (v t - σ ^ 2 / (2 * κ)) * (Real.exp (2 * κ * t) * (2 * κ))) t :=
        ((hv t ht).sub_const (σ ^ 2 / (2 * κ))).mul he
      have hc : σ ^ 2 / (2 * κ) * (2 * κ) = σ ^ 2 := by field_simp
      convert h1 using 1
      linear_combination Real.exp (2 * κ * t) * hc
    have := const_of_hasDerivAt_zero_pos g hgc hgd T hT
    simp only [g, hv0, mul_zero, Real.exp_zero, mul_one] at this
    have hE : Real.exp (2 * κ * T) * Real.exp (-2 * κ * T) = 1 := by
      rw [← Real.exp_add]; simp
    have : v T - σ ^ 2 / (2 * κ) = (0 - σ ^ 2 / (2 * κ)) * Real.exp (-2 * κ * T) := by
      calc v T - σ ^ 2 / (2 * κ)
          = (v T - σ ^ 2 / (2 * κ)) * Real.exp (2 * κ * T) * Real.exp (-2 * κ * T) := by
            rw [mul_assoc, hE, mul_one]
        _ = _ := by rw [this]
    linarith
  have hv_nn : 0 ≤ v T := by
    rw [hvT]
    apply mul_nonneg
    · positivity
    · have : Real.exp (-2 * κ * T) ≤ 1 := by
        rw [Real.exp_le_one_iff]; nlinarith
      linarith
  have hint : ∫ ω, Real.exp (X ω) ∂P = mgf X P 1 := by
    simp [mgf]
  rw [hint, mgf_gaussianReal hX, Real.coe_toNNReal _ hv_nn, hmT, hvT]
  congr 1
  field_simp
  ring

/-- The Samuelson effect: any change in log spot changes the log of every future by
`e^{-κT}` times that change, so a future's volatility is `σ e^{-κT}`. -/
theorem log_futures_moves_by_fading_weight (κ a σ T S S' : ℝ) :
    Real.log (schwartzFutures κ a σ S' T) - Real.log (schwartzFutures κ a σ S T) =
      Real.exp (-κ * T) * (Real.log S' - Real.log S) := by
  simp only [schwartzFutures, Real.log_exp]
  ring

/-- Where the curve ends: as delivery runs out to infinity, the futures price tends to
`exp (a + σ²/(4κ))`, above `e^a`, whatever today's spot. -/
theorem futures_curve_long_end (κ a σ S : ℝ) (hκ : 0 < κ) :
    Tendsto (fun T => schwartzFutures κ a σ S T) atTop
      (𝓝 (Real.exp (a + σ ^ 2 / (4 * κ)))) := by
  have h1 : Tendsto (fun T : ℝ => Real.exp (-κ * T)) atTop (𝓝 0) := by
    have : Tendsto (fun T : ℝ => -κ * T) atTop atBot :=
      tendsto_id.const_mul_atTop_of_neg (by linarith)
    exact Real.tendsto_exp_atBot.comp this
  have h2 : Tendsto (fun T : ℝ => Real.exp (-2 * κ * T)) atTop (𝓝 0) := by
    have : Tendsto (fun T : ℝ => -2 * κ * T) atTop atBot :=
      tendsto_id.const_mul_atTop_of_neg (by linarith)
    exact Real.tendsto_exp_atBot.comp this
  unfold schwartzFutures
  apply Real.continuous_exp.continuousAt.tendsto.comp
  have c1 : Tendsto (fun _ : ℝ => (1 : ℝ)) atTop (𝓝 1) := tendsto_const_nhds
  have c2 : Tendsto (fun _ : ℝ => σ ^ 2 / (4 * κ)) atTop (𝓝 (σ ^ 2 / (4 * κ))) :=
    tendsto_const_nhds
  have := ((h1.mul_const (Real.log S)).add ((c1.sub h1).mul_const a)).add
    (c2.mul (c1.sub h2))
  convert this using 2; simp

-- Spot falls from $80 to $70: a move of -12.50 percent.
example : ((70 : ℚ) / 80 - 1) * 100 = -25 / 2 := by norm_num

-- The long-run spread term with σ = 0.30 and κ = 1: σ²/(4κ) = 0.0225.
example : ((3 : ℚ) / 10) ^ 2 / (4 * 1) = 9 / 400 := by norm_num

#print axioms schwartz_futures_formula
#print axioms log_futures_moves_by_fading_weight
#print axioms futures_curve_long_end
