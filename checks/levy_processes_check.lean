-- Levy processes: for a process with stationary independent increments that starts at zero and is continuous in probability, the characteristic function at time t is e raised to t times one fixed exponent, and the Brownian and Poisson extremes have the exponents the card gives.
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Filter Topology Complex
open scoped NNReal

lemma levy_small_of_tendsto (f : ℝ≥0 → ℂ) (h0 : f 0 = 1) (hc : Tendsto f (𝓝[>] 0) (𝓝 1))
    (ε : ℝ) (hε : 0 < ε) : ∃ η : ℝ≥0, 0 < η ∧ ∀ s : ℝ≥0, s < η → ‖f s - 1‖ < ε := by
  rw [Metric.tendsto_nhdsWithin_nhds] at hc
  obtain ⟨η, hη, h⟩ := hc ε hε
  refine ⟨η.toNNReal, Real.toNNReal_pos.mpr hη, fun s hs => ?_⟩
  rcases eq_or_ne s 0 with rfl | hs0
  · simp [h0, hε]
  · have hs' : (s : ℝ) < η := (Real.lt_toNNReal_iff_coe_lt).mp hs
    have := h (x := s) (pos_iff_ne_zero.mpr hs0) (by rw [NNReal.dist_eq]; simpa using hs')
    rwa [dist_eq_norm] at this

lemma levy_arg_small {z : ℂ} (hz : ‖z - 1‖ < 1) : z ≠ 0 ∧ |arg z| < Real.pi / 2 := by
  have hre : 0 < z.re := by
    have h1 := Complex.abs_re_le_norm (z - 1)
    have h2 := neg_abs_le (z - 1).re
    simp only [sub_re, one_re] at h1 h2
    linarith
  exact ⟨fun h => by simp [h] at hre, abs_arg_lt_pi_div_two_iff.mpr (Or.inl hre)⟩

lemma levy_cauchy_exp (f : ℝ≥0 → ℂ) (h0 : f 0 = 1) (hmul : ∀ s t, f (s + t) = f s * f t)
    (hc : Tendsto f (𝓝[>] 0) (𝓝 1)) : ∃ c : ℂ, ∀ t : ℝ≥0, f t = cexp ((t : ℂ) * c) := by
  obtain ⟨η, hη, hη1⟩ := levy_small_of_tendsto f h0 hc 1 one_pos
  set δ : ℝ≥0 := η / 2 with hδ
  have hδpos : 0 < δ := by positivity
  have hδη : δ < η := NNReal.half_lt_self hη.ne'
  have hsmall : ∀ s, s ≤ δ → f s ≠ 0 ∧ |arg (f s)| < Real.pi / 2 :=
    fun s hs => levy_arg_small (hη1 s (hs.trans_lt hδη))
  have hlogadd : ∀ s t, s + t ≤ δ → log (f (s + t)) = log (f s) + log (f t) := by
    intro s t hst
    have hs := hsmall s (le_trans le_self_add hst)
    have ht := hsmall t (le_trans le_add_self hst)
    have e : f s * f t = cexp (log (f s) + log (f t)) := by
      rw [Complex.exp_add, exp_log hs.1, exp_log ht.1]
    have a1 := abs_lt.mp hs.2
    have a2 := abs_lt.mp ht.2
    rw [hmul, e, log_exp]
    · simp only [add_im, log_im]; linarith [Real.pi_pos]
    · simp only [add_im, log_im]; linarith [Real.pi_pos]
  have hk : ∀ n : ℕ, 0 < n → ∀ k : ℕ, k ≤ n →
      log (f (k * (δ / n))) = k * log (f (δ / n)) := by
    intro n hn k
    induction k with
    | zero => intro _; simp [h0]
    | succ k ih =>
      intro hkn
      have hn' : (n : ℝ≥0) ≠ 0 := by exact_mod_cast hn.ne'
      have hle : (k : ℝ≥0) * (δ / n) + δ / n ≤ δ := by
        have : ((k + 1 : ℕ) : ℝ≥0) ≤ n := by exact_mod_cast hkn
        calc (k : ℝ≥0) * (δ / n) + δ / n = ((k + 1 : ℕ) : ℝ≥0) * (δ / n) := by push_cast; ring
          _ ≤ n * (δ / n) := by gcongr
          _ = δ := mul_div_cancel₀ δ hn'
      rw [show ((k + 1 : ℕ) : ℝ≥0) * (δ / n) = k * (δ / n) + δ / n by push_cast; ring,
        hlogadd _ _ hle, ih (by omega)]
      push_cast; ring
  set c : ℂ := log (f δ) / (δ : ℂ) with hc_def
  have hδc : (δ : ℂ) ≠ 0 := by exact_mod_cast hδpos.ne'
  have hd : ∀ n : ℕ, 0 < n → f (δ / n) = cexp (((δ / n : ℝ≥0) : ℂ) * c) := by
    intro n hn
    have hn' : (n : ℝ≥0) ≠ 0 := by exact_mod_cast hn.ne'
    have hnc : (n : ℂ) ≠ 0 := by exact_mod_cast hn.ne'
    have h1 := hk n hn n le_rfl
    rw [mul_div_cancel₀ δ hn'] at h1
    have hne := (hsmall (δ / n) (div_le_self (by positivity) (by exact_mod_cast hn))).1
    rw [← exp_log hne]
    congr 1
    rw [hc_def, h1]
    push_cast
    field_simp
  have hgrid : ∀ n : ℕ, 0 < n → ∀ k : ℕ,
      f (k * (δ / n)) = cexp (((k * (δ / n) : ℝ≥0) : ℂ) * c) := by
    intro n hn k
    induction k with
    | zero => simp [h0]
    | succ k ih =>
      rw [show ((k + 1 : ℕ) : ℝ≥0) * (δ / n) = k * (δ / n) + δ / n by push_cast; ring,
        hmul, ih, hd n hn, ← Complex.exp_add]
      congr 1; push_cast; ring
  set g : ℝ≥0 → ℂ := fun s => f s * cexp (-((s : ℂ) * c)) with hg_def
  have hg : ∀ s t, g (s + t) = g s * g t := by
    intro s t
    simp only [hg_def, hmul]
    push_cast
    rw [show -(((s : ℂ) + t) * c) = -(s * c) + -(t * c) by ring, Complex.exp_add]
    ring
  have hg0 : g 0 = 1 := by simp [hg_def, h0]
  have hgc : Tendsto g (𝓝[>] 0) (𝓝 1) := by
    have hcont : Continuous (fun s : ℝ≥0 => cexp (-((s : ℂ) * c))) := by fun_prop
    have := (hcont.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    simpa using hc.mul this
  have hggrid : ∀ n : ℕ, 0 < n → ∀ k : ℕ, g (k * (δ / n)) = 1 := by
    intro n hn k
    simp only [hg_def, hgrid n hn k, ← Complex.exp_add, add_neg_cancel, Complex.exp_zero]
  refine ⟨c, fun t => ?_⟩
  have hgt : g t = 1 := by
    apply eq_of_forall_dist_le
    intro ε hε
    obtain ⟨η', hη'pos, hη'⟩ := levy_small_of_tendsto g hg0 hgc ε hε
    obtain ⟨n, hn⟩ := exists_nat_gt (δ / η')
    have hnpos : 0 < n := by
      have : (0 : ℝ≥0) < n := lt_of_le_of_lt (by positivity) hn
      exact_mod_cast this
    have hn' : (n : ℝ≥0) ≠ 0 := by exact_mod_cast hnpos.ne'
    set d : ℝ≥0 := δ / n with hd_def
    have hdpos : 0 < d := by positivity
    have hdη : d < η' := by
      rw [hd_def, div_lt_iff₀ (by positivity)]
      rw [div_lt_iff₀ hη'pos] at hn
      calc δ < n * η' := hn
        _ = η' * n := mul_comm _ _
    set k := ⌊t / d⌋₊ with hk_def
    have hq : (k : ℝ≥0) * d ≤ t := by
      calc (k : ℝ≥0) * d ≤ t / d * d := by gcongr; exact Nat.floor_le (by positivity)
        _ = t := div_mul_cancel₀ t hdpos.ne'
    have hq2 : t < (k : ℝ≥0) * d + d := by
      have := Nat.lt_floor_add_one (t / d)
      rw [div_lt_iff₀ hdpos] at this
      calc t < (k + 1) * d := this
        _ = k * d + d := by ring
    have hr : t - k * d < d := (tsub_lt_iff_left hq).mpr hq2
    have ht : t = k * d + (t - k * d) := (add_tsub_cancel_of_le hq).symm
    rw [ht, hg, hggrid n hnpos k, one_mul, dist_eq_norm]
    exact (hη' _ (hr.trans hdη)).le
  have : f t * cexp (-((t : ℂ) * c)) = 1 := hgt
  calc f t = f t * cexp (-((t : ℂ) * c)) * cexp ((t : ℂ) * c) := by
        rw [mul_assoc, ← Complex.exp_add, neg_add_cancel, Complex.exp_zero, mul_one]
    _ = cexp ((t : ℂ) * c) := by rw [this, one_mul]

#print axioms levy_small_of_tendsto
#print axioms levy_arg_small
#print axioms levy_cauchy_exp

/-- The characteristic function of a Levy process is an exponential in time. Let X be a
real-valued process indexed by times t ≥ 0 on a probability space with the four Levy
properties: it starts at zero; its increments over windows that do not overlap are
independent; the law of an increment X (t + h) - X t depends on the length h only, not on the
start t; and it is continuous in probability (for every size ε > 0 the chance that
|X (t + h) - X t| > ε goes to 0 as h goes to 0). Then there is one function ψ, the Levy
exponent, with E[exp(i u X t)] = exp(t ψ(u)) for every dial u and every time t. -/
theorem levy_char_fun_exponential_in_time {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℝ≥0 → Ω → ℝ)
    (h_start : ∀ᵐ ω ∂P, X 0 ω = 0)
    (h_indep : ∀ (n : ℕ) (τ : Fin (n + 1) → ℝ≥0), Monotone τ →
      iIndepFun (fun (k : Fin n) (ω : Ω) => X (τ k.succ) ω - X (τ k.castSucc) ω) P)
    (h_stat : ∀ s t h : ℝ≥0,
      IdentDistrib (fun ω => X (s + h) ω - X s ω) (fun ω => X (t + h) ω - X t ω) P P)
    (h_cont : ∀ (t : ℝ≥0) (ε : ℝ), 0 < ε →
      Tendsto (fun h : ℝ≥0 => P {ω | ε < |X (t + h) ω - X t ω|}) (𝓝[>] 0) (𝓝 0)) :
    ∃ ψ : ℝ → ℂ, ∀ (u : ℝ) (t : ℝ≥0),
      ∫ ω, cexp (I * u * X t ω) ∂P = cexp ((t : ℂ) * ψ u) := by
  have hXae : ∀ t, X t =ᵐ[P] fun ω => X t ω - X 0 ω := fun t => by
    filter_upwards [h_start] with ω hω
    simp [hω]
  have hXm : ∀ t, AEMeasurable (X t) P := fun t => by
    have := (h_stat 0 0 t).aemeasurable_fst
    simp only [zero_add] at this
    exact this.congr (hXae t).symm
  have key : ∀ u : ℝ, ∃ c : ℂ, ∀ t : ℝ≥0,
      ∫ ω, cexp (I * u * X t ω) ∂P = cexp ((t : ℂ) * c) := by
    intro u
    have hec : Continuous (fun x : ℝ => cexp (I * u * x)) := by fun_prop
    apply levy_cauchy_exp (fun t => ∫ ω, cexp (I * u * X t ω) ∂P)
    · rw [integral_congr_ae (g := fun _ => (1 : ℂ))]
      · simp
      · filter_upwards [h_start] with ω hω
        simp [hω]
    · intro s t
      have hmono : Monotone (![0, s, s + t] : Fin 3 → ℝ≥0) := by
        rw [Fin.monotone_iff_le_succ]
        intro i
        fin_cases i <;> simp
      have hind : IndepFun (fun ω => X s ω - X 0 ω) (fun ω => X (s + t) ω - X s ω) P := by
        have := (h_indep 2 _ hmono).indepFun (show (0 : Fin 2) ≠ 1 by decide)
        simpa using this
      have hBm : AEMeasurable (fun ω => X s ω - X 0 ω) P := (hXm s).sub (hXm 0)
      have hAm : AEMeasurable (fun ω => X (s + t) ω - X s ω) P := (hXm (s + t)).sub (hXm s)
      have h1 : ∫ ω, cexp (I * u * X (s + t) ω) ∂P
          = ∫ ω, cexp (I * u * ↑(X s ω - X 0 ω)) * cexp (I * u * ↑(X (s + t) ω - X s ω)) ∂P := by
        apply integral_congr_ae
        filter_upwards [h_start] with ω hω
        simp only [hω]
        rw [← Complex.exp_add]
        congr 1
        push_cast
        ring
      rw [h1, hind.integral_fun_comp_mul_comp (f := fun x : ℝ => cexp (I * u * x))
        (g := fun x : ℝ => cexp (I * u * x)) hBm hAm hec.aestronglyMeasurable
        hec.aestronglyMeasurable]
      congr 1
      · apply integral_congr_ae
        filter_upwards [h_start] with ω hω
        simp [hω]
      · have hid := ((h_stat s 0 t).comp hec.measurable).integral_eq
        simp only [Function.comp_def, zero_add] at hid
        rw [hid]
        apply integral_congr_ae
        filter_upwards [h_start] with ω hω
        simp [hω]
    · rw [Metric.tendsto_nhds]
      intro ε hε
      set κ : ℝ := ε / (4 * (|u| + 1)) with hκ
      have hu1 : 0 < |u| + 1 := by positivity
      have hκpos : 0 < κ := by positivity
      have hκu : |u| * κ ≤ ε / 4 := by
        have : (|u| + 1) * κ = ε / 4 := by rw [hκ]; field_simp
        nlinarith [abs_nonneg u]
      have hpr := h_cont 0 κ hκpos
      simp only [zero_add] at hpr
      have hpr' := (ENNReal.tendsto_toReal ENNReal.zero_ne_top).comp hpr
      simp only [ENNReal.toReal_zero] at hpr'
      filter_upwards [hpr'.eventually (gt_mem_nhds (show (0 : ℝ) < ε / 4 by positivity))]
        with h hh
      simp only [Function.comp_apply] at hh
      set S := {ω | κ < |X h ω - X 0 ω|} with hS
      set T := toMeasurable P S with hT
      have hTm : MeasurableSet T := measurableSet_toMeasurable P S
      have hPT : (P T).toReal = (P S).toReal := by rw [hT, measure_toMeasurable]
      have hint : Integrable (fun ω => cexp (I * u * X h ω)) P := by
        refine Integrable.of_bound (hec.measurable.comp_aemeasurable (hXm h)).aestronglyMeasurable
          1 (ae_of_all _ fun ω => ?_)
        rw [show I * (u : ℂ) * (X h ω : ℂ) = I * ((u * X h ω : ℝ) : ℂ) by push_cast; ring,
          norm_exp_I_mul_ofReal]
      have hsub : (∫ ω, cexp (I * u * X h ω) ∂P) - 1
          = ∫ ω, (cexp (I * u * X h ω) - 1) ∂P := by
        rw [integral_sub hint (integrable_const 1)]
        simp
      have hbint : Integrable (fun ω => |u| * κ + T.indicator (fun _ => (2 : ℝ)) ω) P :=
        (integrable_const _).add ((integrable_const _).indicator hTm)
      have hbound : ‖∫ ω, (cexp (I * u * X h ω) - 1) ∂P‖
          ≤ ∫ ω, (|u| * κ + T.indicator (fun _ => (2 : ℝ)) ω) ∂P := by
        apply norm_integral_le_of_norm_le hbint
        filter_upwards [h_start] with ω hω
        have hind0 : 0 ≤ T.indicator (fun _ => (2 : ℝ)) ω :=
          Set.indicator_nonneg (fun _ _ => by norm_num) ω
        rw [show I * (u : ℂ) * (X h ω : ℂ) = I * ((u * X h ω : ℝ) : ℂ) by push_cast; ring]
        by_cases hω' : κ < |X h ω - X 0 ω|
        · have hmem : ω ∈ T := subset_toMeasurable P S hω'
          rw [Set.indicator_of_mem hmem]
          calc ‖cexp (I * ((u * X h ω : ℝ) : ℂ)) - 1‖
              ≤ ‖cexp (I * ((u * X h ω : ℝ) : ℂ))‖ + ‖(1 : ℂ)‖ := norm_sub_le _ _
            _ = 2 := by rw [norm_exp_I_mul_ofReal]; norm_num
            _ ≤ |u| * κ + 2 := by have := mul_nonneg (abs_nonneg u) hκpos.le; linarith
        · push Not at hω'
          rw [hω, sub_zero] at hω'
          calc ‖cexp (I * ((u * X h ω : ℝ) : ℂ)) - 1‖ ≤ ‖u * X h ω‖ :=
                Real.norm_exp_I_mul_ofReal_sub_one_le
            _ = |u| * |X h ω| := by rw [Real.norm_eq_abs, abs_mul]
            _ ≤ |u| * κ := by gcongr
            _ ≤ |u| * κ + T.indicator (fun _ => (2 : ℝ)) ω := by linarith
      have hval : ∫ ω, (|u| * κ + T.indicator (fun _ => (2 : ℝ)) ω) ∂P
          = |u| * κ + 2 * (P S).toReal := by
        rw [integral_add (integrable_const _) ((integrable_const _).indicator hTm),
          integral_indicator_const _ hTm]
        simp [measureReal_def, hPT, mul_comm]
      rw [dist_eq_norm, hsub]
      calc _ ≤ |u| * κ + 2 * (P S).toReal := hbound.trans hval.le
        _ < ε := by linarith
  choose ψ hψ using key
  exact ⟨ψ, hψ⟩

/-- The Poisson extreme. A Poisson count at rate λ has, at time t, the Poisson law with mean
λ t, and its characteristic function is exp(t ψ(u)) with exponent ψ(u) = λ (e^{iu} - 1). -/
theorem poisson_levy_exponent (lam t : ℝ≥0) (u : ℝ) :
    charFun ((poissonMeasure (lam * t)).map (Nat.cast : ℕ → ℝ)) u
      = cexp ((t : ℂ) * ((lam : ℂ) * (cexp (u * I) - 1))) := by
  rw [charFun_map_cast_poissonMeasure]
  congr 1
  push_cast
  ring

/-- The Brownian extreme, with a steady drift. γ t + σ W t is normal with mean γ t and variance
σ² t, and its characteristic function is exp(t ψ(u)) with exponent ψ(u) = i γ u - σ² u² / 2:
the drift adds i γ u, the Brownian part adds -σ² u² / 2. -/
theorem brownian_drift_levy_exponent (γ : ℝ) (σ t : ℝ≥0) (u : ℝ) :
    charFun (gaussianReal (γ * t) (σ ^ 2 * t)) u
      = cexp ((t : ℂ) * (I * γ * u - (σ : ℂ) ^ 2 * (u : ℂ) ^ 2 / 2)) := by
  rw [charFun_gaussianReal]
  congr 1
  push_cast
  ring

-- The share, in exact fractions: γ = 1/4, σ = 1/5, rate 2, jumps of size -1/5 (chance 3/4)
-- and +1/5 (chance 1/4).
-- The Levy measure: 3/2 at -1/5 and 1/2 at +1/5.
example : (2 : ℚ) * (3 / 4) = 3 / 2 ∧ (2 : ℚ) * (1 / 4) = 1 / 2 := by norm_num
-- The triplet's drift b = γ + (small jumps' pull) = 1/4 - 1/5 = 1/20 (the card's 0.05).
example : (1 / 4 : ℚ) + ((3 / 2) * (-1 / 5) + (1 / 2) * (1 / 5)) = 1 / 20 := by norm_num
-- Variance of X_1: σ² + ∫ x² ν = 1/25 + 2/25 = 3/25 (the card's 0.12), two thirds from jumps.
example : (1 / 5 : ℚ) ^ 2 + ((3 / 2) * (-1 / 5) ^ 2 + (1 / 2) * (1 / 5) ^ 2) = 3 / 25 := by
  norm_num
example : ((3 / 2 : ℚ) * (-1 / 5) ^ 2 + (1 / 2) * (1 / 5) ^ 2) / (3 / 25) = 2 / 3 := by norm_num
-- Rate 3 then rate 1 for half a year each: the first half-year's mean is -1/40, the Levy
-- half-year's mean is +1/40 (the card's -0.0250 against 0.0250); one jump averages -1/10.
example : (3 / 4 : ℚ) * (-1 / 5) + (1 / 4) * (1 / 5) = -1 / 10 := by norm_num
example : (1 / 4 : ℚ) * (1 / 2) + 3 * (1 / 2) * (-1 / 10) = -1 / 40 := by norm_num
example : (1 / 4 : ℚ) * (1 / 2) + 2 * (1 / 2) * (-1 / 10) = 1 / 40 := by norm_num
-- Same one-year law: 3 * 1/2 + 1 * 1/2 = 2 jumps a year on average.
example : (3 : ℚ) * (1 / 2) + 1 * (1 / 2) = 2 := by norm_num
-- Random slope with Var X_t = (3/25) t²: Var X_2 = 12/25 (0.48), not 2 * 3/25 = 6/25 (0.24).
example : (3 / 25 : ℚ) * 2 ^ 2 = 12 / 25 ∧ (2 : ℚ) * (3 / 25) = 6 / 25 := by norm_num

#print axioms levy_char_fun_exponential_in_time
#print axioms poisson_levy_exponent
#print axioms brownian_drift_levy_exponent
