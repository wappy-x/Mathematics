-- Logistic growth: the law P' = r P (1 - P/K) from a positive start has exactly one solution, the S-curve K / (1 + A e^(-rt)), which closes in on the ceiling K from its own side, and the rate peaks at rK/4 at half the ceiling.
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Inv

open Filter Topology

lemma logistic_denom_pos (r K P₀ : ℝ) (hr : 0 < r) (hK : 0 < K) (hP₀ : 0 < P₀) (t : ℝ)
    (ht : 0 ≤ t) : 0 < 1 + (K / P₀ - 1) * Real.exp (-r * t) := by
  have he : 0 < Real.exp (-r * t) := Real.exp_pos _
  have he1 : Real.exp (-r * t) ≤ 1 := Real.exp_le_one_iff.mpr (by nlinarith)
  have hKP : 0 < K / P₀ := div_pos hK hP₀
  have : 1 + (K / P₀ - 1) * Real.exp (-r * t) = (1 - Real.exp (-r * t)) + K / P₀ * Real.exp (-r * t) := by ring
  rw [this]
  have := mul_pos hKP he
  linarith

lemma logistic_formula_hasDerivAt (r K P₀ : ℝ) (hr : 0 < r) (hK : 0 < K) (hP₀ : 0 < P₀) (t : ℝ)
    (ht : 0 ≤ t) :
    HasDerivAt (fun s => K / (1 + (K / P₀ - 1) * Real.exp (-r * s)))
      (r * (K / (1 + (K / P₀ - 1) * Real.exp (-r * t))) *
        (1 - (K / (1 + (K / P₀ - 1) * Real.exp (-r * t))) / K)) t := by
  have hD := logistic_denom_pos r K P₀ hr hK hP₀ t ht
  have h1 : HasDerivAt (fun s => -r * s) (-r) t := by
    simpa using (hasDerivAt_id t).const_mul (-r)
  have h2 := ((h1.exp).const_mul (K / P₀ - 1)).const_add 1
  have h3 := HasDerivAt.div (hasDerivAt_const t K) h2 hD.ne'
  convert h3 using 1
  generalize K / P₀ - 1 = a at hD ⊢
  generalize Real.exp (-r * t) = e at hD ⊢
  have hK' := hK.ne'
  have hD' := hD.ne'
  field_simp
  ring

lemma logistic_unique (r K P₀ : ℝ) (hr : 0 < r) (hK : 0 < K) (hP₀ : 0 < P₀) (P : ℝ → ℝ)
    (hP : ∀ t ≥ 0, HasDerivWithinAt P (r * P t * (1 - P t / K)) (Set.Ici 0) t)
    (h0 : P 0 = P₀) (t : ℝ) (ht : 0 ≤ t) :
    P t = K / (1 + (K / P₀ - 1) * Real.exp (-r * t)) := by
  set A := K / P₀ - 1 with hA
  set G : ℝ → ℝ := fun x => (K - P x) * Real.exp (r * x) - A * P x with hG
  have hcont : ContinuousOn P (Set.Icc 0 t) := by
    intro x hx
    exact ((hP x hx.1).continuousWithinAt).mono Set.Icc_subset_Ici_self
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn hcont
  have hGcont : ContinuousOn G (Set.Icc 0 t) := by
    apply ContinuousOn.sub
    · exact (continuousOn_const.sub hcont).mul (Real.continuous_exp.comp (continuous_const.mul continuous_id)).continuousOn
    · exact continuousOn_const.mul hcont
  have hGd : ∀ x ∈ Set.Ico 0 t,
      HasDerivWithinAt G (r * (K - P x) / K * G x) (Set.Ici x) x := by
    intro x hx
    have hPx := (hP x hx.1).mono (Set.Ici_subset_Ici.mpr hx.1)
    have he : HasDerivAt (fun y => Real.exp (r * y)) (Real.exp (r * x) * r) x := by
      simpa using ((hasDerivAt_id x).const_mul r).exp
    have := ((hPx.const_sub K).mul he.hasDerivWithinAt).sub (hPx.const_mul A)
    convert this using 1
    simp only [hG]
    field_simp
    ring
  have hGa : G 0 = 0 := by
    simp only [hG, h0, mul_zero, Real.exp_zero, mul_one, hA]
    field_simp
    ring
  have hbound : ∀ x ∈ Set.Ico 0 t, ‖r * (K - P x) / K * G x‖ ≤ (r * (K + M) / K) * ‖G x‖ := by
    intro x hx
    rw [norm_mul]
    apply mul_le_mul_of_nonneg_right _ (norm_nonneg _)
    have hMx := hM x (Set.Ico_subset_Icc_self hx)
    rw [Real.norm_eq_abs] at hMx ⊢
    rw [abs_div, abs_mul, abs_of_pos hr, abs_of_pos hK]
    apply div_le_div_of_nonneg_right _ hK.le
    apply mul_le_mul_of_nonneg_left _ hr.le
    calc |K - P x| ≤ |K| + |P x| := abs_sub _ _
      _ ≤ K + M := by rw [abs_of_pos hK]; linarith
  have hz := eq_zero_of_abs_deriv_le_mul_abs_self_of_eq_zero_right hGcont hGd hGa hbound t
    ⟨ht, le_rfl⟩
  have hD := logistic_denom_pos r K P₀ hr hK hP₀ t ht
  simp only [hG] at hz
  have hexp : Real.exp (-r * t) * Real.exp (r * t) = 1 := by
    rw [← Real.exp_add]; simp
  have hpos := Real.exp_pos (r * t)
  rw [eq_div_iff hD.ne']
  have : P t * (1 + A * Real.exp (-r * t)) * Real.exp (r * t)
      = K * Real.exp (r * t) := by
    have : P t * (1 + A * Real.exp (-r * t)) * Real.exp (r * t)
        = P t * Real.exp (r * t) + A * P t * (Real.exp (-r * t) * Real.exp (r * t)) := by ring
    rw [this, hexp]
    linarith
  have := mul_right_cancel₀ hpos.ne' (this.trans (one_mul _).symm |>.trans (by ring))
  simpa using this

#print axioms logistic_denom_pos
#print axioms logistic_formula_hasDerivAt
#print axioms logistic_unique

/-- With a positive rate `r`, a positive ceiling `K` and a positive start `P₀`, a function `P`
solves the logistic law `P' = r P (1 - P/K)` for all times `t ≥ 0` with `P(0) = P₀`
exactly when it is the S-curve `P(t) = K / (1 + A e^(-rt))`, where `A = K/P₀ - 1`:
the formula solves the law, and nothing else does, from below or above the ceiling. -/
theorem logistic_solution_is_s_curve (r K P₀ : ℝ) (hr : 0 < r) (hK : 0 < K) (hP₀ : 0 < P₀)
    (P : ℝ → ℝ) :
    ((∀ t ≥ 0, HasDerivWithinAt P (r * P t * (1 - P t / K)) (Set.Ici 0) t) ∧ P 0 = P₀) ↔
      ∀ t ≥ 0, P t = K / (1 + (K / P₀ - 1) * Real.exp (-r * t)) := by
  constructor
  · rintro ⟨hP, h0⟩ t ht
    exact logistic_unique r K P₀ hr hK hP₀ P hP h0 t ht
  · intro hP
    refine ⟨fun t ht => ?_, ?_⟩
    · have h := (logistic_formula_hasDerivAt r K P₀ hr hK hP₀ t ht).hasDerivWithinAt
        (s := Set.Ici 0)
      rw [hP t ht]
      exact h.congr (fun y hy => hP y hy) (hP t ht)
    · rw [hP 0 le_rfl]
      simp only [mul_zero, Real.exp_zero, mul_one]
      have := hK.ne'
      have := hP₀.ne'
      rw [show (1:ℝ) + (K / P₀ - 1) = K / P₀ by ring, div_div_cancel₀ hK.ne']

/-- Every solution of the logistic law from a positive start closes in on the ceiling `K`
(the ceiling attracts, and zero repels), and it never crosses the ceiling: a start below
stays below, a start above stays above. -/
theorem logistic_tends_to_ceiling (r K : ℝ) (hr : 0 < r) (hK : 0 < K) (P : ℝ → ℝ)
    (hP : ∀ t ≥ 0, HasDerivWithinAt P (r * P t * (1 - P t / K)) (Set.Ici 0) t)
    (h0 : 0 < P 0) :
    Tendsto P atTop (𝓝 K) ∧
      (P 0 < K → ∀ t ≥ 0, P t < K) ∧ (K < P 0 → ∀ t ≥ 0, K < P t) := by
  have hform := (logistic_solution_is_s_curve r K (P 0) hr hK h0 P).mp ⟨hP, rfl⟩
  set A := K / P 0 - 1 with hA
  have hKP : 0 < K / P 0 := div_pos hK h0
  refine ⟨?_, ?_, ?_⟩
  · have hlim : Tendsto (fun t : ℝ => Real.exp (-r * t)) atTop (𝓝 0) :=
      Real.tendsto_exp_atBot.comp (tendsto_id.const_mul_atTop_of_neg (by linarith))
    have h2 : Tendsto (fun t : ℝ => K / (1 + A * Real.exp (-r * t))) atTop
        (𝓝 (K / (1 + A * 0))) :=
      tendsto_const_nhds.div (tendsto_const_nhds.add (tendsto_const_nhds.mul hlim)) (by simp)
    simp only [mul_zero, add_zero, div_one] at h2
    refine h2.congr' ?_
    filter_upwards [eventually_ge_atTop 0] with t ht
    exact (hform t ht).symm
  · intro hlt t ht
    rw [hform t ht]
    have hA0 : 0 < A := by
      rw [hA, sub_pos, one_lt_div h0]; exact hlt
    have he := Real.exp_pos (-r * t)
    apply div_lt_self hK
    have := mul_pos hA0 he
    linarith
  · intro hgt t ht
    rw [hform t ht]
    have hA0 : A < 0 := by
      rw [hA, sub_neg, div_lt_one h0]; exact hgt
    have he := Real.exp_pos (-r * t)
    have he1 : Real.exp (-r * t) ≤ 1 := Real.exp_le_one_iff.mpr (by nlinarith)
    have hD := logistic_denom_pos r K (P 0) hr hK h0 t ht
    rw [lt_div_iff₀ hD]
    have : A * Real.exp (-r * t) < 0 := mul_neg_of_neg_of_pos hA0 he
    nlinarith

/-- The logistic rate `r P (1 - P/K)` is largest at half the ceiling, `P = K/2`, and only
there, where it equals `rK/4`: the half-way point is the point of fastest growth. -/
theorem logistic_rate_peaks_at_half_ceiling (r K : ℝ) (hr : 0 < r) (hK : 0 < K) :
    (∀ P : ℝ, r * P * (1 - P / K) ≤ r * K / 4) ∧
      r * (K / 2) * (1 - (K / 2) / K) = r * K / 4 ∧
      (∀ P : ℝ, r * P * (1 - P / K) = r * K / 4 → P = K / 2) := by
  have key : ∀ P : ℝ, r * K / 4 - r * P * (1 - P / K) = r * (P - K / 2) ^ 2 / K := by
    intro P; field_simp; ring
  refine ⟨fun P => ?_, ?_, fun P hP => ?_⟩
  · have := key P
    have : 0 ≤ r * (P - K / 2) ^ 2 / K := by positivity
    linarith
  · field_simp; ring
  · have h := key P
    rw [hP, sub_self] at h
    have h2 : r * (P - K / 2) ^ 2 = 0 := by
      have := h.symm
      rwa [div_eq_zero_iff, or_iff_left hK.ne'] at this
    have : (P - K / 2) ^ 2 = 0 := by
      rcases mul_eq_zero.mp h2 with h | h
      · exact absurd h hr.ne'
      · exact h
    have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
    linarith

-- The rumour: K = 1000 pupils, 10 at the start, so the starting gap is A = 99.
example : (1000 : ℚ) / 10 - 1 = 99 := by norm_num
-- At time 0 the denominator is 1 + 99 = 100, so the curve starts at 10.
example : (1000 : ℚ) / (1 + 99) = 10 := by norm_num
-- Rate on day 0, with r = 4/5 per day: 7.92 = 198/25 pupils per day.
example : (4 / 5 : ℚ) * 10 * (1 - 10 / 1000) = 198 / 25 := by norm_num
-- Fastest spread, at half the school: 200 pupils per day, which is rK/4.
example : (4 / 5 : ℚ) * 500 * (1 - 500 / 1000) = 200 := by norm_num
example : (4 / 5 : ℚ) * 1000 / 4 = 200 := by norm_num
-- A start above the ceiling, 1500: A = -1/3, and the curve starts at 1500.
example : (1000 : ℚ) / 1500 - 1 = -1 / 3 := by norm_num
example : (1000 : ℚ) / (1 + (-1 / 3)) = 1500 := by norm_num
-- Mistake 2: dropping the sign of A gives a start of 750, not 1500.
example : (1000 : ℚ) / (1 + 1 / 3) = 750 := by norm_num
-- Partial fractions: K / (P (K - P)) = 1/P + 1/(K - P), for 0 < P < K.
example (K P : ℝ) (hP : 0 < P) (hPK : P < K) :
    K / (P * (K - P)) = 1 / P + 1 / (K - P) := by
  have h1 : P ≠ 0 := hP.ne'
  have h2 : K - P ≠ 0 := by linarith
  field_simp
  ring

#print axioms logistic_solution_is_s_curve
#print axioms logistic_tends_to_ceiling
#print axioms logistic_rate_peaks_at_half_ceiling
