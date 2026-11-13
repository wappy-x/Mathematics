-- Implied vol from an Asian quote: the Turnbull-Wakeman price of an Asian call on a futures strip rises strictly with volatility from its zero-volatility floor to its infinite-volatility ceiling, so a quote has an implied vol exactly when it lies strictly inside that band and then exactly one, the vanilla Black-76 formula on the swap price reads back the average's own log-spread instead, and the share of variance an evenly spread average keeps is (n+1)(2n+1)/(6n²), which tends to one third.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Order.Filter.AtTopBot.Basic

open Real ProbabilityTheory Finset Filter Topology Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Black-76 fed a forward `F` and a whole-life log-spread `v`:
`e^(-rT) (F N(e₁) - K N(e₂))` with `e₁ = (ln(F/K) + v²/2) / v` and `e₂ = e₁ - v`. -/
noncomputable def black76OnSpread (F K r T v : ℝ) : ℝ :=
  exp (-r * T) * (F * stdNormalCDF ((log (F / K) + v ^ 2 / 2) / v)
    - K * stdNormalCDF ((log (F / K) + v ^ 2 / 2) / v - v))

/-- The plain (vanilla) Black-76 call on a forward `F` with yearly volatility `s` and expiry `T`:
Black-76 fed the log-spread `s √T`. -/
noncomputable def black76Call (F K r s T : ℝ) : ℝ :=
  black76OnSpread F K r T (s * √T)

/-- `M₁`, the mean of the average, the swap price: the plain average of today's futures prices
`F i` at the `n` fixing dates. -/
noncomputable def stripMean (n : ℕ) (F : Fin n → ℝ) : ℝ :=
  (∑ i, F i) / n

/-- `M₂(σ)`, the average's mean square when one random path moves the whole curve with
volatility `σ`: `(1/n²) Σᵢ Σⱼ Fᵢ Fⱼ e^(σ² min(tᵢ, tⱼ))`. -/
noncomputable def stripMeanSquare (n : ℕ) (F t : Fin n → ℝ) (σ : ℝ) : ℝ :=
  (∑ i, ∑ j, F i * F j * exp (σ ^ 2 * min (t i) (t j))) / (n : ℝ) ^ 2

/-- `v_A(σ) = √(ln(M₂ / M₁²))`, the log-spread a lognormal needs to match both moments. -/
noncomputable def averageLogSpread (n : ℕ) (F t : Fin n → ℝ) (σ : ℝ) : ℝ :=
  √(log (stripMeanSquare n F t σ / stripMean n F ^ 2))

/-- `C_TW(σ)`, the Turnbull-Wakeman (moment-matched) Asian call price: Black-76 fed the
swap price `M₁` and the average's log-spread `v_A(σ)`, discounted from the payment date `T`. -/
noncomputable def turnbullWakemanCall (n : ℕ) (F t : Fin n → ℝ) (K r T σ : ℝ) : ℝ :=
  black76OnSpread (stripMean n F) K r T (averageLogSpread n F t σ)

open MeasureTheory in
lemma stdNormalCDF_eq (x : ℝ) : stdNormalCDF x = ∫ y in Iic x, gaussianPDFReal 0 1 y := by
  unfold stdNormalCDF
  rw [cdf_eq_real, Measure.real, gaussianReal_apply_eq_integral _ one_ne_zero, ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun y _ => gaussianPDFReal_nonneg _ _ y)

open MeasureTheory in
lemma stdNormalCDF_hasDerivAt (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hcont : Continuous (gaussianPDFReal 0 1) := by
    unfold gaussianPDFReal; fun_prop
  have hint : ∀ b : ℝ, IntegrableOn (gaussianPDFReal 0 1) (Iic b) :=
    fun b => (integrable_gaussianPDFReal 0 1).integrableOn
  have h : ∀ y, stdNormalCDF y = stdNormalCDF 0 + ∫ z in (0:ℝ)..y, gaussianPDFReal 0 1 z := by
    intro y
    rw [stdNormalCDF_eq, stdNormalCDF_eq, ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint y)]
    ring
  have hd : HasDerivAt (fun y => ∫ z in (0:ℝ)..y, gaussianPDFReal 0 1 z) (gaussianPDFReal 0 1 x) x :=
    intervalIntegral.integral_hasDerivAt_right (hcont.intervalIntegrable _ _)
      (hcont.stronglyMeasurableAtFilter _ _) hcont.continuousAt
  have hfun : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ z in (0:ℝ)..y, gaussianPDFReal 0 1 z :=
    funext h
  rw [hfun]
  exact hd.const_add _

lemma stdNormalCDF_continuous : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (stdNormalCDF_hasDerivAt x).continuousAt

lemma stdNormalCDF_atTop : Tendsto stdNormalCDF atTop (𝓝 1) := tendsto_cdf_atTop _

lemma stdNormalCDF_atBot : Tendsto stdNormalCDF atBot (𝓝 0) := tendsto_cdf_atBot _

lemma pdf_ratio (F K v : ℝ) (hF : 0 < F) (hK : 0 < K) (hv : v ≠ 0) :
    K * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v - v) =
      F * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v) := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  have hexp : -((log (F / K) + v ^ 2 / 2) / v - v) ^ 2 / 2
      = -((log (F / K) + v ^ 2 / 2) / v) ^ 2 / 2 + log (F / K) := by
    field_simp; ring
  rw [hexp, exp_add, exp_log (div_pos hF hK)]
  field_simp

lemma black76OnSpread_hasDerivAt (F K r T v : ℝ) (hF : 0 < F) (hK : 0 < K) (hv : 0 < v) :
    HasDerivAt (black76OnSpread F K r T)
      (exp (-r * T) * F * gaussianPDFReal 0 1 ((log (F / K) + v ^ 2 / 2) / v)) v := by
  set a := log (F / K) with ha
  have he1 : HasDerivAt (fun v : ℝ => (a + v ^ 2 / 2) / v)
      (((↑2 * v ^ (2 - 1) * 1 / 2) * v - (a + v ^ 2 / 2) * 1) / v ^ 2) v :=
    ((((hasDerivAt_id v).pow 2).div_const 2).const_add a).div (hasDerivAt_id v) hv.ne'
  set d := ((↑2 * v ^ (2 - 1) * 1 / 2) * v - (a + v ^ 2 / 2) * 1) / v ^ 2
  have he2 : HasDerivAt (fun v : ℝ => (a + v ^ 2 / 2) / v - v) (d - 1) v :=
    he1.sub (hasDerivAt_id v)
  have h1 := (stdNormalCDF_hasDerivAt _).comp v he1
  have h2 := (stdNormalCDF_hasDerivAt _).comp v he2
  have h := ((h1.const_mul F).sub (h2.const_mul K)).const_mul (exp (-r * T))
  have hfun : black76OnSpread F K r T = fun v => exp (-r * T) *
      (F * (stdNormalCDF ∘ fun v : ℝ => (a + v ^ 2 / 2) / v) v
        - K * (stdNormalCDF ∘ fun v : ℝ => (a + v ^ 2 / 2) / v - v) v) := by
    funext w; rfl
  rw [hfun]
  convert h using 1
  have key := pdf_ratio F K v hF hK hv.ne'
  rw [← ha] at key
  linear_combination (exp (-r * T) * (d - 1)) * key


lemma black76OnSpread_strictMonoOn (F K r T : ℝ) (hF : 0 < F) (hK : 0 < K) :
    StrictMonoOn (black76OnSpread F K r T) (Ioi 0) := by
  apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
  · intro x hx
    exact (black76OnSpread_hasDerivAt F K r T x hF hK hx).continuousAt.continuousWithinAt
  · intro x hx
    rw [interior_Ioi] at hx
    rw [(black76OnSpread_hasDerivAt F K r T x hF hK hx).deriv]
    have := gaussianPDFReal_pos 0 1 ((log (F / K) + x ^ 2 / 2) / x) one_ne_zero
    positivity

lemma black76OnSpread_continuousOn (F K r T : ℝ) (hF : 0 < F) (hK : 0 < K) :
    ContinuousOn (black76OnSpread F K r T) (Ioi 0) := fun x hx =>
  (black76OnSpread_hasDerivAt F K r T x hF hK hx).continuousAt.continuousWithinAt

lemma black76OnSpread_eq (F K r T v : ℝ) (hv : v ≠ 0) :
    black76OnSpread F K r T v = exp (-r * T) * (F * stdNormalCDF (log (F / K) * v⁻¹ + v / 2)
      - K * stdNormalCDF (log (F / K) * v⁻¹ - v / 2)) := by
  unfold black76OnSpread
  have e1 : (log (F / K) + v ^ 2 / 2) / v = log (F / K) * v⁻¹ + v / 2 := by
    field_simp
  rw [e1, show log (F / K) * v⁻¹ + v / 2 - v = log (F / K) * v⁻¹ - v / 2 by ring]

lemma black76OnSpread_atTop (F K r T : ℝ) :
    Tendsto (black76OnSpread F K r T) atTop (𝓝 (exp (-r * T) * F)) := by
  have hinv : Tendsto (fun v : ℝ => log (F / K) * v⁻¹) atTop (𝓝 0) := by
    simpa using tendsto_inv_atTop_zero.const_mul (log (F / K))
  have hhalf : Tendsto (fun v : ℝ => v / 2) atTop atTop :=
    tendsto_id.atTop_div_const (by norm_num)
  have h1 : Tendsto (fun v : ℝ => log (F / K) * v⁻¹ + v / 2) atTop atTop := hinv.add_atTop hhalf
  have h2 : Tendsto (fun v : ℝ => log (F / K) * v⁻¹ - v / 2) atTop atBot := by
    simpa [sub_eq_add_neg] using hinv.add_atBot (tendsto_neg_atTop_atBot.comp hhalf)
  have hlim := (((stdNormalCDF_atTop.comp h1).const_mul F).sub
    ((stdNormalCDF_atBot.comp h2).const_mul K)).const_mul (exp (-r * T))
  simp only [mul_one, mul_zero, sub_zero] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with v hv
  rw [black76OnSpread_eq F K r T v hv.ne']
  rfl

lemma black76OnSpread_nhdsGT (F K r T : ℝ) (hF : 0 < F) (hK : 0 < K) :
    Tendsto (black76OnSpread F K r T) (𝓝[>] 0) (𝓝 (exp (-r * T) * max (F - K) 0)) := by
  have hhalf : Tendsto (fun v : ℝ => v / 2) (𝓝[>] 0) (𝓝 0) := by
    have : Tendsto (fun v : ℝ => v / 2) (𝓝 0) (𝓝 (0 / 2)) := tendsto_id.div_const 2
    simpa using this.mono_left nhdsWithin_le_nhds
  have heq : ∀ᶠ v in 𝓝[>] (0:ℝ), exp (-r * T) * (F * stdNormalCDF (log (F / K) * v⁻¹ + v / 2)
      - K * stdNormalCDF (log (F / K) * v⁻¹ - v / 2)) = black76OnSpread F K r T v := by
    filter_upwards [self_mem_nhdsWithin] with v hv
    rw [black76OnSpread_eq F K r T v (ne_of_gt hv)]
  refine Tendsto.congr' heq ?_
  rcases lt_trichotomy (log (F / K)) 0 with ha | ha | ha
  · have hFK : F < K := by
      have := (log_neg_iff (div_pos hF hK)).1 ha
      rwa [div_lt_one hK] at this
    rw [max_eq_right (by linarith)]
    have hinv : Tendsto (fun v : ℝ => log (F / K) * v⁻¹) (𝓝[>] 0) atBot :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg ha
    have h1 := hinv.atBot_add hhalf
    have h2 : Tendsto (fun v : ℝ => log (F / K) * v⁻¹ - v / 2) (𝓝[>] 0) atBot := by
      simpa [sub_eq_add_neg] using hinv.atBot_add hhalf.neg
    have := (((stdNormalCDF_atBot.comp h1).const_mul F).sub
      ((stdNormalCDF_atBot.comp h2).const_mul K)).const_mul (exp (-r * T))
    simpa using this
  · have hFK : F = K := by
      have := eq_one_of_pos_of_log_eq_zero (div_pos hF hK) ha
      rwa [div_eq_one_iff_eq hK.ne'] at this
    simp only [ha, zero_mul, zero_add, zero_sub]
    have h1 := (stdNormalCDF_continuous.tendsto 0).comp hhalf
    have h2 := (stdNormalCDF_continuous.tendsto 0).comp (by simpa using hhalf.neg)
    have := ((h1.const_mul F).sub (h2.const_mul K)).const_mul (exp (-r * T))
    convert this using 2 <;> simp [hFK]
  · have hFK : K < F := by
      have := (log_pos_iff (div_pos hF hK).le).1 ha
      rwa [one_lt_div hK] at this
    rw [max_eq_left (by linarith)]
    have hinv : Tendsto (fun v : ℝ => log (F / K) * v⁻¹) (𝓝[>] 0) atTop :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop ha
    have h1 := hinv.atTop_add hhalf
    have h2 : Tendsto (fun v : ℝ => log (F / K) * v⁻¹ - v / 2) (𝓝[>] 0) atTop := by
      simpa [sub_eq_add_neg] using hinv.atTop_add hhalf.neg
    have := (((stdNormalCDF_atTop.comp h1).const_mul F).sub
      ((stdNormalCDF_atTop.comp h2).const_mul K)).const_mul (exp (-r * T))
    simpa using this

lemma stripMean_pos (n : ℕ) (hn : 0 < n) (F : Fin n → ℝ) (hF : ∀ i, 0 < F i) :
    0 < stripMean n F := by
  unfold stripMean
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  have : (0:ℝ) < ∑ i, F i :=
    Finset.sum_pos (fun i _ => hF i) (Finset.univ_nonempty_iff.2 ⟨⟨0, hn⟩⟩)
  positivity

lemma stripMeanSquare_zero (n : ℕ) (F t : Fin n → ℝ) :
    stripMeanSquare n F t 0 = stripMean n F ^ 2 := by
  unfold stripMeanSquare stripMean
  simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, zero_mul, exp_zero, mul_one]
  rw [div_pow, sq (∑ i, F i), Finset.sum_mul_sum]

lemma stripMeanSquare_pos (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) (σ : ℝ) :
    0 < stripMeanSquare n F t σ := by
  unfold stripMeanSquare
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  have hne : (Finset.univ : Finset (Fin n)).Nonempty := Finset.univ_nonempty_iff.2 ⟨⟨0, hn⟩⟩
  have : (0:ℝ) < ∑ i, ∑ j, F i * F j * exp (σ ^ 2 * min (t i) (t j)) :=
    Finset.sum_pos (fun i _ => Finset.sum_pos (fun j _ => by
      have := hF i; have := hF j; positivity) hne) hne
  positivity

lemma stripMeanSquare_strictMonoOn (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i)
    (ht : ∀ i, 0 < t i) : StrictMonoOn (stripMeanSquare n F t) (Ici 0) := by
  intro a ha b hb hab
  unfold stripMeanSquare
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  have hne : (Finset.univ : Finset (Fin n)).Nonempty := Finset.univ_nonempty_iff.2 ⟨⟨0, hn⟩⟩
  rw [div_lt_div_iff_of_pos_right (pow_pos hn' 2)]
  apply Finset.sum_lt_sum_of_nonempty hne
  intro i _
  apply Finset.sum_lt_sum_of_nonempty hne
  intro j _
  have hm : 0 < min (t i) (t j) := lt_min (ht i) (ht j)
  have ha' : (0:ℝ) ≤ a := ha
  have hsq : a ^ 2 < b ^ 2 := by nlinarith
  have := mul_pos (hF i) (hF j)
  gcongr

lemma stripMeanSquare_continuous (n : ℕ) (F t : Fin n → ℝ) :
    Continuous (stripMeanSquare n F t) := by
  unfold stripMeanSquare
  fun_prop

lemma stripMeanSquare_ge (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) (σ : ℝ) :
    F ⟨0, hn⟩ * F ⟨0, hn⟩ * exp (σ ^ 2 * t ⟨0, hn⟩) / (n : ℝ) ^ 2 ≤ stripMeanSquare n F t σ := by
  unfold stripMeanSquare
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  gcongr
  have hnn : ∀ i j, 0 ≤ F i * F j * exp (σ ^ 2 * min (t i) (t j)) := fun i j => by
    have := hF i; have := hF j; positivity
  calc F ⟨0, hn⟩ * F ⟨0, hn⟩ * exp (σ ^ 2 * t ⟨0, hn⟩)
      = F ⟨0, hn⟩ * F ⟨0, hn⟩ * exp (σ ^ 2 * min (t ⟨0, hn⟩) (t ⟨0, hn⟩)) := by rw [min_self]
    _ ≤ ∑ j, F ⟨0, hn⟩ * F j * exp (σ ^ 2 * min (t ⟨0, hn⟩) (t j)) :=
        Finset.single_le_sum (f := fun j => F ⟨0, hn⟩ * F j * exp (σ ^ 2 * min (t ⟨0, hn⟩) (t j)))
          (fun j _ => hnn _ j) (Finset.mem_univ _)
    _ ≤ ∑ i, ∑ j, F i * F j * exp (σ ^ 2 * min (t i) (t j)) :=
        Finset.single_le_sum (f := fun i => ∑ j, F i * F j * exp (σ ^ 2 * min (t i) (t j)))
          (fun i _ => Finset.sum_nonneg fun j _ => hnn i j) (Finset.mem_univ _)

lemma meanRatio_gt_one (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i)
    (ht : ∀ i, 0 < t i) {a b : ℝ} (ha : 0 ≤ a) (hab : a < b) :
    stripMeanSquare n F t a / stripMean n F ^ 2 < stripMeanSquare n F t b / stripMean n F ^ 2 := by
  have hM := stripMean_pos n hn F hF
  rw [div_lt_div_iff_of_pos_right (by positivity)]
  exact stripMeanSquare_strictMonoOn n hn F t hF ht ha (mem_Ici.2 (ha.trans hab.le)) hab

lemma meanRatio_zero (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) :
    stripMeanSquare n F t 0 / stripMean n F ^ 2 = 1 := by
  have hM := stripMean_pos n hn F hF
  rw [stripMeanSquare_zero, div_self (by positivity)]

lemma averageLogSpread_pos (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i)
    (ht : ∀ i, 0 < t i) {σ : ℝ} (hσ : 0 < σ) : 0 < averageLogSpread n F t σ := by
  unfold averageLogSpread
  apply Real.sqrt_pos.2
  apply Real.log_pos
  have := meanRatio_gt_one n hn F t hF ht le_rfl hσ
  rwa [meanRatio_zero n hn F t hF] at this

lemma averageLogSpread_strictMonoOn (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ)
    (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i) :
    StrictMonoOn (averageLogSpread n F t) (Ioi 0) := by
  intro a ha b hb hab
  have ha' : (0:ℝ) < a := ha
  unfold averageLogSpread
  have h1 := meanRatio_gt_one n hn F t hF ht le_rfl ha'
  rw [meanRatio_zero n hn F t hF] at h1
  apply Real.sqrt_lt_sqrt (Real.log_pos h1).le
  exact Real.log_lt_log (by linarith) (meanRatio_gt_one n hn F t hF ht ha'.le hab)

lemma averageLogSpread_continuous (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ)
    (hF : ∀ i, 0 < F i) : Continuous (averageLogSpread n F t) := by
  have hM := stripMean_pos n hn F hF
  unfold averageLogSpread
  apply Real.continuous_sqrt.comp
  apply Continuous.log ((stripMeanSquare_continuous n F t).div_const _)
  intro σ
  have := stripMeanSquare_pos n hn F t hF σ
  positivity

lemma averageLogSpread_nhdsGT (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ)
    (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i) :
    Tendsto (averageLogSpread n F t) (𝓝[>] 0) (𝓝[>] 0) := by
  have h0 : averageLogSpread n F t 0 = 0 := by
    unfold averageLogSpread
    rw [meanRatio_zero n hn F t hF, Real.log_one, Real.sqrt_zero]
  apply tendsto_nhdsWithin_iff.2
  constructor
  · have := (averageLogSpread_continuous n hn F t hF).tendsto 0
    rw [h0] at this
    exact this.mono_left nhdsWithin_le_nhds
  · filter_upwards [self_mem_nhdsWithin] with σ hσ
    exact averageLogSpread_pos n hn F t hF ht hσ

lemma averageLogSpread_atTop (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ)
    (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i) :
    Tendsto (averageLogSpread n F t) atTop atTop := by
  have hM := stripMean_pos n hn F hF
  have hn' : (0:ℝ) < n := Nat.cast_pos.2 hn
  have hF0 := hF ⟨0, hn⟩
  have ht0 := ht ⟨0, hn⟩
  set c := F ⟨0, hn⟩ * F ⟨0, hn⟩ / (n : ℝ) ^ 2 / stripMean n F ^ 2 with hc
  have hcpos : 0 < c := by positivity
  have hlow : ∀ σ : ℝ, log c + σ ^ 2 * t ⟨0, hn⟩
      ≤ log (stripMeanSquare n F t σ / stripMean n F ^ 2) := by
    intro σ
    rw [← Real.log_exp (σ ^ 2 * t ⟨0, hn⟩), ← Real.log_mul hcpos.ne' (exp_pos _).ne']
    apply Real.log_le_log (by positivity)
    have := stripMeanSquare_ge n hn F t hF σ
    rw [hc, le_div_iff₀ (by positivity)]
    calc F ⟨0, hn⟩ * F ⟨0, hn⟩ / ↑n ^ 2 / stripMean n F ^ 2 * rexp (σ ^ 2 * t ⟨0, hn⟩)
          * stripMean n F ^ 2
        = F ⟨0, hn⟩ * F ⟨0, hn⟩ * exp (σ ^ 2 * t ⟨0, hn⟩) / (n : ℝ) ^ 2 := by
          field_simp
      _ ≤ _ := this
  have hsq : Tendsto (fun σ : ℝ => log c + σ ^ 2 * t ⟨0, hn⟩) atTop atTop :=
    tendsto_atTop_add_const_left _ _
      ((tendsto_pow_atTop two_ne_zero).atTop_mul_const ht0)
  have hlog := tendsto_atTop_mono hlow hsq
  exact tendsto_sqrt_atTop.comp hlog

lemma band_of_strictMonoOn {f : ℝ → ℝ} {L U : ℝ}
    (hmono : StrictMonoOn f (Ioi 0)) (hcont : ContinuousOn f (Ioi 0))
    (h0 : Tendsto f (𝓝[>] 0) (𝓝 L)) (hinf : Tendsto f atTop (𝓝 U)) (Q : ℝ) :
    ((∃ σ : ℝ, 0 < σ ∧ f σ = Q) ↔ (L < Q ∧ Q < U)) ∧
    ((L < Q ∧ Q < U) → ∃! σ : ℝ, 0 < σ ∧ f σ = Q) := by
  have hL : ∀ x, 0 < x → L ≤ f x := by
    intro x hx
    apply le_of_tendsto h0
    filter_upwards [Ioo_mem_nhdsGT hx] with y hy
    exact (hmono hy.1 hx hy.2).le
  have hU : ∀ x, 0 < x → f x ≤ U := by
    intro x hx
    apply ge_of_tendsto hinf
    filter_upwards [eventually_ge_atTop x] with y hy
    exact hmono.monotoneOn hx (lt_of_lt_of_le hx hy) hy
  have hex : L < Q ∧ Q < U → ∃ σ : ℝ, 0 < σ ∧ f σ = Q := by
    rintro ⟨hLQ, hQU⟩
    obtain ⟨a, haQ, ha⟩ :=
      ((h0.eventually (gt_mem_nhds hLQ)).and self_mem_nhdsWithin).exists
    obtain ⟨b, hbQ, hb⟩ :=
      ((hinf.eventually (lt_mem_nhds hQU)).and (eventually_gt_atTop 0)).exists
    have ha' : (0:ℝ) < a := ha
    have hab : a ≤ b := by
      by_contra h
      exact absurd (hmono hb ha' (not_le.1 h)) (by linarith)
    obtain ⟨c, hc, hcQ⟩ := intermediate_value_Icc hab
      (hcont.mono fun x hx => lt_of_lt_of_le ha' hx.1) ⟨haQ.le, hbQ.le⟩
    exact ⟨c, lt_of_lt_of_le ha' hc.1, hcQ⟩
  refine ⟨⟨?_, hex⟩, fun h => ?_⟩
  · rintro ⟨σ, hσ, rfl⟩
    refine ⟨?_, ?_⟩
    · exact lt_of_le_of_lt (hL (σ / 2) (by linarith))
        (hmono (show (0:ℝ) < σ / 2 by linarith) hσ (by linarith))
    · exact lt_of_lt_of_le (hmono hσ (show (0:ℝ) < 2 * σ by linarith) (by linarith))
        (hU (2 * σ) (by linarith))
  · obtain ⟨σ, hσ, hfσ⟩ := hex h
    refine ⟨σ, ⟨hσ, hfσ⟩, fun τ ⟨hτ, hfτ⟩ => ?_⟩
    exact hmono.injOn hτ hσ (hfτ.trans hfσ.symm)

lemma sum_Icc_id_two (n : ℕ) : 2 * ∑ j ∈ Icc 1 n, j = n * (n + 1) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), mul_add, ih]
    ring

/-- **One implied vol, exactly when the quote is inside the band.** Take `n ≥ 1` fixings, read
from today's futures prices `F i > 0` at dates `t i > 0` (no fixing banked yet), one volatility
`σ` for every fixing, one random path moving the whole curve, a strike `K > 0`, a bank rate `r`
and a payment date `T`. Then the moment-matched price `C_TW(σ)` rises strictly with volatility
`σ > 0`; it tends to the floor `e^(-rT) (M₁ - K)⁺` as volatility falls to zero and to the
ceiling `e^(-rT) M₁` as volatility grows without bound; a quote `Q` is matched by some
volatility `σ > 0` exactly when `e^(-rT) (M₁ - K)⁺ < Q < e^(-rT) M₁`; and every such quote is
matched by exactly one volatility. -/
theorem asian_quote_in_band_has_one_implied_vol
    (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i)
    (K r T : ℝ) (hK : 0 < K) :
    StrictMonoOn (turnbullWakemanCall n F t K r T) (Ioi 0) ∧
    Tendsto (turnbullWakemanCall n F t K r T) (𝓝[>] 0)
      (𝓝 (exp (-r * T) * max (stripMean n F - K) 0)) ∧
    Tendsto (turnbullWakemanCall n F t K r T) atTop (𝓝 (exp (-r * T) * stripMean n F)) ∧
    ∀ Q : ℝ,
      ((∃ σ : ℝ, 0 < σ ∧ turnbullWakemanCall n F t K r T σ = Q) ↔
        (exp (-r * T) * max (stripMean n F - K) 0 < Q ∧ Q < exp (-r * T) * stripMean n F)) ∧
      ((exp (-r * T) * max (stripMean n F - K) 0 < Q ∧ Q < exp (-r * T) * stripMean n F) →
        ∃! σ : ℝ, 0 < σ ∧ turnbullWakemanCall n F t K r T σ = Q) := by
  have hM := stripMean_pos n hn F hF
  have hfun : turnbullWakemanCall n F t K r T =
      black76OnSpread (stripMean n F) K r T ∘ averageLogSpread n F t := rfl
  have hmaps : MapsTo (averageLogSpread n F t) (Ioi 0) (Ioi 0) :=
    fun σ hσ => averageLogSpread_pos n hn F t hF ht hσ
  have hmono : StrictMonoOn (turnbullWakemanCall n F t K r T) (Ioi 0) := by
    intro a ha b hb hab
    exact black76OnSpread_strictMonoOn _ K r T hM hK (hmaps ha) (hmaps hb)
      (averageLogSpread_strictMonoOn n hn F t hF ht ha hb hab)
  have hcont : ContinuousOn (turnbullWakemanCall n F t K r T) (Ioi 0) := by
    rw [hfun]
    exact (black76OnSpread_continuousOn _ K r T hM hK).comp
      (averageLogSpread_continuous n hn F t hF).continuousOn hmaps
  have h0 : Tendsto (turnbullWakemanCall n F t K r T) (𝓝[>] 0)
      (𝓝 (exp (-r * T) * max (stripMean n F - K) 0)) := by
    rw [hfun]
    exact (black76OnSpread_nhdsGT _ K r T hM hK).comp (averageLogSpread_nhdsGT n hn F t hF ht)
  have hinf : Tendsto (turnbullWakemanCall n F t K r T) atTop
      (𝓝 (exp (-r * T) * stripMean n F)) := by
    rw [hfun]
    exact (black76OnSpread_atTop _ K r T).comp (averageLogSpread_atTop n hn F t hF ht)
  exact ⟨hmono, h0, hinf, band_of_strictMonoOn hmono hcont h0 hinf⟩

/-- **The vanilla formula reads the average's spread, not a fixing's vol** (Step 5). Under the
same conditions, with expiry `T > 0`: at any volatility `σ > 0`, the plain Black-76 call on the
swap price `M₁` reproduces the Turnbull-Wakeman premium `C_TW(σ)` at exactly one volatility
`s > 0`, namely `s = v_A(σ) / √T`: the average's own log-spread, put on a yearly scale. -/
theorem vanilla_on_swap_price_reads_average_spread
    (n : ℕ) (hn : 0 < n) (F t : Fin n → ℝ) (hF : ∀ i, 0 < F i) (ht : ∀ i, 0 < t i)
    (K r T : ℝ) (hK : 0 < K) (hT : 0 < T) (σ : ℝ) (hσ : 0 < σ) :
    ∀ s : ℝ, 0 < s →
      (black76Call (stripMean n F) K r s T = turnbullWakemanCall n F t K r T σ ↔
        s = averageLogSpread n F t σ / √T) := by
  intro s hs
  have hM := stripMean_pos n hn F hF
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hv := averageLogSpread_pos n hn F t hF ht hσ
  unfold black76Call turnbullWakemanCall
  rw [(black76OnSpread_strictMonoOn _ K r T hM hK).injOn.eq_iff
    (show s * √T ∈ Set.Ioi 0 from mul_pos hs hsT)
    (show averageLogSpread n F t σ ∈ Set.Ioi 0 from hv),
    eq_div_iff hsT.ne']

/-- **Where the three comes from** (Step 6). For evenly spaced fixings `tᵢ = iT/n` the
average of the logs keeps the share `c = (1/(n² T)) Σᵢ Σⱼ min(tᵢ, tⱼ)` of the last price's
log-variance. The count is `Σᵢ Σⱼ min(i, j) = n(n+1)(2n+1)/6` for `i, j = 1, …, n`, so
`c = (n+1)(2n+1)/(6n²)`, and `c` tends to one third as the number of fixings grows. -/
theorem average_keeps_one_third_of_variance (n : ℕ) :
    6 * ∑ i ∈ Icc 1 n, ∑ j ∈ Icc 1 n, min i j = n * (n + 1) * (2 * n + 1) ∧
    Tendsto (fun m : ℕ => ((m : ℝ) + 1) * (2 * m + 1) / (6 * (m : ℝ) ^ 2)) atTop
      (𝓝 (1 / 3)) := by
  constructor
  · induction n with
    | zero => simp
    | succ k ih =>
      have hrow : ∑ j ∈ Icc 1 k, min (k + 1) j = ∑ j ∈ Icc 1 k, j :=
        Finset.sum_congr rfl fun j hj => min_eq_right (by simp at hj; omega)
      have hcol : ∑ i ∈ Icc 1 k, min i (k + 1) = ∑ i ∈ Icc 1 k, i :=
        Finset.sum_congr rfl fun i hi => min_eq_left (by simp at hi; omega)
      have hs := sum_Icc_id_two k
      rw [Finset.sum_Icc_succ_top (by omega)]
      simp only [Finset.sum_Icc_succ_top (show 1 ≤ k + 1 by omega)]
      rw [Finset.sum_add_distrib, hcol, hrow, min_self]
      nlinarith [ih, hs]
  · have hinv : Tendsto (fun m : ℕ => ((m : ℝ))⁻¹) atTop (𝓝 0) :=
      tendsto_inv_atTop_zero.comp tendsto_natCast_atTop_atTop
    have hlim : Tendsto (fun m : ℕ => 1 / 3 + (1 / 2) * ((m : ℝ))⁻¹ + (1 / 6) * ((m : ℝ))⁻¹ ^ 2)
        atTop (𝓝 (1 / 3 + (1 / 2) * 0 + (1 / 6) * 0 ^ 2)) :=
      ((tendsto_const_nhds.add (hinv.const_mul _)).add ((hinv.pow 2).const_mul _))
    simp only [mul_zero, add_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow]
      at hlim
    refine hlim.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with m hm
    have hm' : (m : ℝ) ≠ 0 := Nat.cast_ne_zero.2 hm.ne'
    field_simp
    ring

-- The card's 52 weekly fixings: Σᵢ Σⱼ min(i, j) = 52·53·105/6 = 48230.
example : ∑ i ∈ Icc 1 52, ∑ j ∈ Icc 1 52, min i j = 48230 := by decide
example : 52 * 53 * 105 / 6 = 48230 := by norm_num
-- The share kept by 52 weekly fixings: c = 53·105/(6·52²) = 1855/5408 (about 0.343).
example : ((52 + 1) * (2 * 52 + 1) : ℚ) / (6 * 52 ^ 2) = 1855 / 5408 := by norm_num
example : (48230 : ℚ) / 52 ^ 2 / 52 = 1855 / 5408 := by norm_num

#print axioms asian_quote_in_band_has_one_implied_vol
#print axioms vanilla_on_swap_price_reads_average_spread
#print axioms average_keeps_one_third_of_variance
#print axioms stdNormalCDF_eq
#print axioms stdNormalCDF_hasDerivAt
#print axioms stdNormalCDF_continuous
#print axioms stdNormalCDF_atTop
#print axioms stdNormalCDF_atBot
#print axioms pdf_ratio
#print axioms black76OnSpread_hasDerivAt
#print axioms black76OnSpread_strictMonoOn
#print axioms black76OnSpread_continuousOn
#print axioms black76OnSpread_eq
#print axioms black76OnSpread_atTop
#print axioms black76OnSpread_nhdsGT
#print axioms stripMean_pos
#print axioms stripMeanSquare_zero
#print axioms stripMeanSquare_pos
#print axioms stripMeanSquare_strictMonoOn
#print axioms stripMeanSquare_continuous
#print axioms stripMeanSquare_ge
#print axioms meanRatio_gt_one
#print axioms meanRatio_zero
#print axioms averageLogSpread_pos
#print axioms averageLogSpread_strictMonoOn
#print axioms averageLogSpread_continuous
#print axioms averageLogSpread_nhdsGT
#print axioms averageLogSpread_atTop
#print axioms band_of_strictMonoOn
#print axioms sum_Icc_id_two
