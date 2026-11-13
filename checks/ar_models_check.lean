-- Autoregression: in the model X(t+1) = c + φ·X(t) + shock with independent mean-zero shocks of variance σ² and −1 < φ < 1, the mean settles at c/(1 − φ), the variance settles at σ²/(1 − φ²), readings h days apart have covariance φ^h times the variance, and the h-day forecast c/(1 − φ) + φ^h·(today − c/(1 − φ)) has mean-zero error with variance σ²(1 − φ^(2h))/(1 − φ²).
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecificLimits.Basic

open MeasureTheory ProbabilityTheory Filter Topology

lemma ar1h_cov_affine {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {Y Z W : Ω → ℝ} (a b : ℝ) (hY : MemLp Y 2 P) (hZ : MemLp Z 2 P) (hW : MemLp W 2 P) :
    covariance (fun ω => a + b * Y ω + Z ω) W P = b * covariance Y W P + covariance Z W P := by
  have h1 : (fun ω => a + b * Y ω + Z ω) = (fun ω => a + b * Y ω) + Z := rfl
  have hA : MemLp (fun ω => a + b * Y ω) 2 P := (memLp_const a).add (hY.const_mul b)
  rw [h1, covariance_add_left hA hZ hW,
    covariance_const_add_left ((hY.const_mul b).integrable one_le_two),
    covariance_const_mul_left]

lemma ar1h_int_affine {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {Y Z : Ω → ℝ} (a b : ℝ) (hY : Integrable Y P) (hZ : Integrable Z P) :
    ∫ ω, (a + b * Y ω + Z ω) ∂P = a + b * ∫ ω, Y ω ∂P + ∫ ω, Z ω ∂P := by
  have hA : Integrable (fun ω => a + b * Y ω) P := (integrable_const a).add (hY.const_mul b)
  have hB : Integrable (fun ω => b * Y ω) P := hY.const_mul b
  rw [integral_add hA hZ, integral_add (integrable_const a) hB, integral_const,
    integral_const_mul]
  simp

lemma ar1h_step {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ξ Y : ℕ → Ω → ℝ) (a φ σ : ℝ) (s : ℕ)
    (hind : iIndepFun ξ P) (hL2 : ∀ n, MemLp (ξ n) 2 P)
    (hvar : ∀ t, variance (ξ (t + 1)) P = σ ^ 2)
    (hY0 : MemLp (Y 0) 2 P) (hY0c : ∀ k, s < k → covariance (Y 0) (ξ k) P = 0)
    (hrec : ∀ n ω, Y (n + 1) ω = a + φ * Y n ω + ξ (s + n + 1) ω) :
    (∀ n, MemLp (Y n) 2 P) ∧ (∀ n k, s + n < k → covariance (Y n) (ξ k) P = 0) ∧
      (∀ n, variance (Y (n + 1)) P = φ ^ 2 * variance (Y n) P + σ ^ 2) := by
  have hYfun : ∀ n, Y (n + 1) = fun ω => a + φ * Y n ω + ξ (s + n + 1) ω :=
    fun n => funext (hrec n)
  have hM : ∀ n, MemLp (Y n) 2 P := by
    intro n
    induction n with
    | zero => exact hY0
    | succ n ih =>
      rw [hYfun n]
      exact ((memLp_const a).add (ih.const_mul φ)).add (hL2 _)
  have hC : ∀ n k, s + n < k → covariance (Y n) (ξ k) P = 0 := by
    intro n
    induction n with
    | zero => intro k hk; exact hY0c k (by omega)
    | succ n ih =>
      intro k hk
      rw [hYfun n, ar1h_cov_affine a φ (hM n) (hL2 _) (hL2 k), ih k (by omega),
        (hind.indepFun (show s + n + 1 ≠ k by omega)).covariance_eq_zero (hL2 _) (hL2 _)]
      ring
  refine ⟨hM, hC, fun n => ?_⟩
  have hf : MemLp (fun ω => a + φ * Y n ω + ξ (s + n + 1) ω) 2 P := hYfun n ▸ hM (n + 1)
  have e2 : covariance (Y n) (fun ω => a + φ * Y n ω + ξ (s + n + 1) ω) P =
      φ * covariance (Y n) (Y n) P + covariance (ξ (s + n + 1)) (Y n) P := by
    rw [covariance_comm]; exact ar1h_cov_affine a φ (hM n) (hL2 _) (hM n)
  have e3 : covariance (ξ (s + n + 1)) (fun ω => a + φ * Y n ω + ξ (s + n + 1) ω) P =
      φ * covariance (Y n) (ξ (s + n + 1)) P + covariance (ξ (s + n + 1)) (ξ (s + n + 1)) P := by
    rw [covariance_comm]; exact ar1h_cov_affine a φ (hM n) (hL2 _) (hL2 _)
  have e4 : covariance (ξ (s + n + 1)) (Y n) P = 0 := by
    rw [covariance_comm]; exact hC n _ (by omega)
  have e5 : covariance (Y n) (ξ (s + n + 1)) P = 0 := hC n _ (by omega)
  have e6 : covariance (ξ (s + n + 1)) (ξ (s + n + 1)) P = σ ^ 2 := by
    rw [covariance_self (hL2 _).aemeasurable]; exact hvar _
  rw [← covariance_self (hM (n + 1)).aemeasurable, ← covariance_self (hM n).aemeasurable,
    hYfun n, ar1h_cov_affine a φ (hM n) (hL2 _) hf, e2, e3, e4, e5, e6]
  ring

lemma ar1h_geom (v : ℕ → ℝ) (φ σ : ℝ) (hφ : φ ^ 2 ≠ 1)
    (hv : ∀ n, v (n + 1) = φ ^ 2 * v n + σ ^ 2) (n : ℕ) :
    v n = φ ^ (2 * n) * v 0 + σ ^ 2 * (1 - φ ^ (2 * n)) / (1 - φ ^ 2) := by
  have hne : 1 - φ ^ 2 ≠ 0 := sub_ne_zero.mpr (Ne.symm hφ)
  induction n with
  | zero => simp
  | succ n ih =>
    rw [hv, ih, show 2 * (n + 1) = 2 * n + 2 by ring, pow_add]
    field_simp
    ring

#print axioms ar1h_cov_affine
#print axioms ar1h_int_affine
#print axioms ar1h_step
#print axioms ar1h_geom


/-- **AR(1) settles: fixed mean, fixed spread, geometric memory.** On a probability space,
let `ξ 0, ξ 1, ξ 2, …` be independent random variables with finite variance. `ξ 0` is the
starting reading `X 0`; for each day `t + 1`, `ξ (t + 1)` is that day's shock, with mean 0
and variance `σ²`. The series follows the AR(1) rule `X (t + 1) = c + φ · X t + ξ (t + 1)`.
If the carry-over `φ` lies strictly between −1 and 1, then, whatever the start:
the mean of `X t` tends to `c / (1 − φ)`; the variance of `X t` tends to `σ² / (1 − φ²)`;
and readings `h` days apart have covariance `φ^h` times the variance of the earlier one,
so the autocorrelation fades geometrically. -/
theorem ar1_settles_to_mean_and_spread {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (ξ X : ℕ → Ω → ℝ) (c φ σ : ℝ)
    (hind : iIndepFun ξ P)
    (hL2 : ∀ n, MemLp (ξ n) 2 P)
    (hmean : ∀ t, ∫ ω, ξ (t + 1) ω ∂P = 0)
    (hvar : ∀ t, variance (ξ (t + 1)) P = σ ^ 2)
    (h0 : X 0 = ξ 0)
    (hrule : ∀ t ω, X (t + 1) ω = c + φ * X t ω + ξ (t + 1) ω)
    (hφ : -1 < φ ∧ φ < 1) :
    Tendsto (fun t => ∫ ω, X t ω ∂P) atTop (𝓝 (c / (1 - φ))) ∧
      Tendsto (fun t => variance (X t) P) atTop (𝓝 (σ ^ 2 / (1 - φ ^ 2))) ∧
      ∀ t h, covariance (X (t + h)) (X t) P = φ ^ h * variance (X t) P := by
  have hφ2 : φ ^ 2 ≠ 1 := by nlinarith [hφ.1, hφ.2]
  have hne : 1 - φ ≠ 0 := by linarith [hφ.2]
  have habs : |φ| < 1 := abs_lt.mpr hφ
  obtain ⟨hM, hC, hV⟩ := ar1h_step ξ X c φ σ 0 hind hL2 hvar (h0 ▸ hL2 0)
    (fun k hk => by
      rw [h0]; exact (hind.indepFun (show 0 ≠ k by omega)).covariance_eq_zero (hL2 0) (hL2 k))
    (fun n ω => by rw [hrule, zero_add])
  refine ⟨?_, ?_, ?_⟩
  · have hm : ∀ t, ∫ ω, X t ω ∂P =
        c / (1 - φ) + φ ^ t * (∫ ω, X 0 ω ∂P - c / (1 - φ)) := by
      intro t
      induction t with
      | zero => simp
      | succ t ih =>
        have hX : X (t + 1) = fun ω => c + φ * X t ω + ξ (t + 1) ω := funext (hrule t)
        rw [hX, ar1h_int_affine c φ ((hM t).integrable one_le_two)
          ((hL2 _).integrable one_le_two), ih, hmean, pow_succ]
        field_simp
        ring
    rw [show (fun t => ∫ ω, X t ω ∂P) = fun t =>
        c / (1 - φ) + φ ^ t * (∫ ω, X 0 ω ∂P - c / (1 - φ)) from funext hm]
    have := ((tendsto_pow_atTop_nhds_zero_of_abs_lt_one habs).mul_const
      (∫ ω, X 0 ω ∂P - c / (1 - φ))).const_add (c / (1 - φ))
    simpa using this
  · have hne2 : 1 - φ ^ 2 ≠ 0 := sub_ne_zero.mpr (Ne.symm hφ2)
    have key : ∀ t, variance (X t) P =
        σ ^ 2 / (1 - φ ^ 2) + (φ ^ 2) ^ t * (variance (X 0) P - σ ^ 2 / (1 - φ ^ 2)) := by
      intro t
      rw [ar1h_geom (fun n => variance (X n) P) φ σ hφ2 hV t, ← pow_mul]
      field_simp
      ring
    rw [show (fun t => variance (X t) P) = fun t =>
        σ ^ 2 / (1 - φ ^ 2) + (φ ^ 2) ^ t * (variance (X 0) P - σ ^ 2 / (1 - φ ^ 2))
        from funext key]
    have habs2 : |φ ^ 2| < 1 := by
      rw [abs_of_nonneg (sq_nonneg φ)]; nlinarith [hφ.1, hφ.2]
    have := ((tendsto_pow_atTop_nhds_zero_of_abs_lt_one habs2).mul_const
      (variance (X 0) P - σ ^ 2 / (1 - φ ^ 2))).const_add (σ ^ 2 / (1 - φ ^ 2))
    simpa using this
  · intro t h
    induction h with
    | zero => simp [covariance_self (hM t).aemeasurable]
    | succ h ih =>
      have hX : X (t + h + 1) = fun ω => c + φ * X (t + h) ω + ξ (t + h + 1) ω :=
        funext (hrule (t + h))
      rw [← add_assoc, hX, ar1h_cov_affine c φ (hM _) (hL2 _) (hM t), ih, covariance_comm,
        hC t (t + h + 1) (by omega)]
      ring

/-- **The variance on every day (Step 2).** Under the same model, the variance of the
reading on day `t` is the starting variance times `φ^(2t)`, plus `σ²(1 − φ^(2t))/(1 − φ²)`.
In particular a series started with variance `σ²/(1 − φ²)` keeps exactly that variance
on every day. -/
theorem ar1_variance_eq {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (ξ X : ℕ → Ω → ℝ) (c φ σ : ℝ)
    (hind : iIndepFun ξ P)
    (hL2 : ∀ n, MemLp (ξ n) 2 P)
    (hmean : ∀ t, ∫ ω, ξ (t + 1) ω ∂P = 0)
    (hvar : ∀ t, variance (ξ (t + 1)) P = σ ^ 2)
    (h0 : X 0 = ξ 0)
    (hrule : ∀ t ω, X (t + 1) ω = c + φ * X t ω + ξ (t + 1) ω)
    (hφ : -1 < φ ∧ φ < 1) (t : ℕ) :
    variance (X t) P =
      φ ^ (2 * t) * variance (X 0) P + σ ^ 2 * (1 - φ ^ (2 * t)) / (1 - φ ^ 2) := by
  have hφ2 : φ ^ 2 ≠ 1 := by nlinarith [hφ.1, hφ.2]
  obtain ⟨_, _, hV⟩ := ar1h_step ξ X c φ σ 0 hind hL2 hvar (h0 ▸ hL2 0)
    (fun k hk => by
      rw [h0]; exact (hind.indepFun (show 0 ≠ k by omega)).covariance_eq_zero (hL2 0) (hL2 k))
    (fun n ω => by rw [hrule, zero_add])
  exact ar1h_geom (fun n => variance (X n) P) φ σ hφ2 hV t

/-- **The forecast and its error (Step 5).** Under the same model, stand on day `T` and
forecast `h` days ahead by the long-run mean plus the shrunk gap,
`c/(1 − φ) + φ^h · (X T − c/(1 − φ))`. The forecast error is
`ξ (T + h) + φ · ξ (T + h − 1) + … + φ^(h − 1) · ξ (T + 1)`, the shocks still to come;
it averages zero, and its variance is `σ_h² = σ²(1 − φ^(2h))/(1 − φ²)`. -/
theorem ar1_forecast_error {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (ξ X : ℕ → Ω → ℝ) (c φ σ : ℝ)
    (hind : iIndepFun ξ P)
    (hL2 : ∀ n, MemLp (ξ n) 2 P)
    (hmean : ∀ t, ∫ ω, ξ (t + 1) ω ∂P = 0)
    (hvar : ∀ t, variance (ξ (t + 1)) P = σ ^ 2)
    (h0 : X 0 = ξ 0)
    (hrule : ∀ t ω, X (t + 1) ω = c + φ * X t ω + ξ (t + 1) ω)
    (hφ : -1 < φ ∧ φ < 1) (T h : ℕ) :
    (∀ ω, X (T + h) ω - (c / (1 - φ) + φ ^ h * (X T ω - c / (1 - φ))) =
        ∑ j ∈ Finset.range h, φ ^ j * ξ (T + h - j) ω) ∧
      ∫ ω, (X (T + h) ω - (c / (1 - φ) + φ ^ h * (X T ω - c / (1 - φ)))) ∂P = 0 ∧
      variance (fun ω => X (T + h) ω - (c / (1 - φ) + φ ^ h * (X T ω - c / (1 - φ)))) P =
        σ ^ 2 * (1 - φ ^ (2 * h)) / (1 - φ ^ 2) := by
  have hφ2 : φ ^ 2 ≠ 1 := by nlinarith [hφ.1, hφ.2]
  have hne : 1 - φ ≠ 0 := by linarith [hφ.2]
  set E : ℕ → Ω → ℝ := fun n ω => X (T + n) ω - (c / (1 - φ) + φ ^ n * (X T ω - c / (1 - φ)))
    with hEdef
  have hE0 : E 0 = fun _ => 0 := by funext ω; simp [hEdef]
  have hErec : ∀ n ω, E (n + 1) ω = 0 + φ * E n ω + ξ (T + n + 1) ω := by
    intro n ω
    simp only [hEdef]
    rw [← add_assoc, hrule, pow_succ]
    field_simp
    ring
  have hsum : ∀ n ω, E n ω = ∑ j ∈ Finset.range n, φ ^ j * ξ (T + n - j) ω := by
    intro n
    induction n with
    | zero => intro ω; rw [hE0]; simp
    | succ n ih =>
      intro ω
      rw [hErec, ih, Finset.sum_range_succ', Finset.mul_sum]
      have h1 : ∀ j ∈ Finset.range n, φ * (φ ^ j * ξ (T + n - j) ω) =
          φ ^ (j + 1) * ξ (T + (n + 1) - (j + 1)) ω := by
        intro j _
        rw [show T + (n + 1) - (j + 1) = T + n - j by omega, pow_succ]
        ring
      rw [Finset.sum_congr rfl h1, show T + (n + 1) - 0 = T + n + 1 by omega]
      simp
  obtain ⟨hM, _, hV⟩ := ar1h_step ξ E 0 φ σ T hind hL2 hvar
    (by rw [hE0]; exact memLp_const 0)
    (fun k _ => by rw [hE0]; exact covariance_const_left 0)
    hErec
  refine ⟨fun ω => hsum h ω, ?_, ?_⟩
  · show ∫ ω, E h ω ∂P = 0
    induction h with
    | zero => rw [hE0]; simp
    | succ n ih =>
      rw [show E (n + 1) = fun ω => 0 + φ * E n ω + ξ (T + n + 1) ω from funext (hErec n),
        ar1h_int_affine 0 φ ((hM n).integrable one_le_two) ((hL2 _).integrable one_le_two),
        ih, hmean]
      ring
  · show variance (E h) P = σ ^ 2 * (1 - φ ^ (2 * h)) / (1 - φ ^ 2)
    rw [ar1h_geom (fun n => variance (E n) P) φ σ hφ2 hV h]
    simp only [hE0]
    rw [show (fun _ : Ω => (0 : ℝ)) = 0 from rfl, variance_zero]
    ring

-- The card's station: φ = 4/5 (0.8), c = 1/10 (0.1 °C), σ = 6/5 (1.2 °C), today 9/2 (4.5 °C).
-- Long-run mean: 0.1 / (1 − 0.8) = 0.5 °C.
example : ((1 : ℚ) / 10) / (1 - 4 / 5) = 1 / 2 := by norm_num
-- Stationary variance: 1.44 / (1 − 0.64) = 4, standard deviation 2 °C.
example : ((6 : ℚ) / 5) ^ 2 / (1 - (4 / 5) ^ 2) = 4 := by norm_num
example : (2 : ℚ) ^ 2 = 4 := by norm_num
-- Today's gap from the mean: 4.5 − 0.5 = 4 °C.
example : (9 : ℚ) / 2 - 1 / 2 = 4 := by norm_num
-- Tomorrow's forecast: 0.5 + 0.8 × 4 = 3.7 °C.
example : (1 : ℚ) / 2 + 4 / 5 * 4 = 37 / 10 := by norm_num
-- Tomorrow's error variance is one shock's: σ²(1 − φ²)/(1 − φ²) = 1.44.
example : ((6 : ℚ) / 5) ^ 2 * (1 - (4 / 5) ^ 2) / (1 - (4 / 5) ^ 2) = 36 / 25 := by norm_num
-- Tomorrow's 95% band: 3.7 ± 1.96 × 1.2 = 3.7 ± 2.352, from 1.348 to 6.052 °C.
example : (49 : ℚ) / 25 * (6 / 5) = 294 / 125 := by norm_num
example : (37 : ℚ) / 10 - 294 / 125 = 337 / 250 := by norm_num
example : (37 : ℚ) / 10 + 294 / 125 = 1513 / 250 := by norm_num
-- Two days ahead: 0.5 + 0.64 × 4 = 3.06 °C.
example : (1 : ℚ) / 2 + (4 / 5) ^ 2 * 4 = 153 / 50 := by norm_num
-- Its error variance: 1.44 × (1 + 0.64) = 2.3616, matching σ²(1 − φ⁴)/(1 − φ²).
example : ((6 : ℚ) / 5) ^ 2 * (1 + (4 / 5) ^ 2) = 1476 / 625 := by norm_num
example : ((6 : ℚ) / 5) ^ 2 * (1 - (4 / 5) ^ 4) / (1 - (4 / 5) ^ 2) = 1476 / 625 := by norm_num
-- Ten days ahead: 0.5 + 0.8^10 × 4, about 0.929 °C.
example : ((4 : ℚ) / 5) ^ 10 = 1048576 / 9765625 := by norm_num
example : (1 : ℚ) / 2 + (4 / 5) ^ 10 * 4 = 18154233 / 19531250 := by norm_num
-- Far ahead: the mean ± 1.96 × 2 = 0.5 ± 3.92 °C.
example : (49 : ℚ) / 25 * 2 = 98 / 25 := by norm_num
-- Autocorrelations φ^h at lags 1 and 2: 0.8 and 0.64.
example : ((4 : ℚ) / 5) ^ 1 = 4 / 5 ∧ ((4 : ℚ) / 5) ^ 2 = 16 / 25 := by norm_num
-- Random walk (φ = 1) fed the same shocks: variance after 365 days is 365 × 1.44 = 525.6.
example : (365 : ℚ) * (6 / 5) ^ 2 = 2628 / 5 := by norm_num

#print axioms ar1_settles_to_mean_and_spread
#print axioms ar1_variance_eq
#print axioms ar1_forecast_error
