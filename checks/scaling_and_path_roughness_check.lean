-- Brownian paths: stretching time by c squared and position by c turns a Brownian motion into a Brownian motion again, its position at time t is root t times a standard normal number with mean distance root (2t/pi), and with probability one its path has a slope at no time at all.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory Real
open scoped NNReal

/-! Brownian motion is Mathlib's `IsBrownianReal W P`: a process `W : ℝ≥0 → Ω → ℝ` whose
finite-dimensional laws are those of Brownian motion (it starts at 0, its moves over separate
stretches are independent, the move over a stretch of length h is normal with mean 0 and
variance h) and whose paths are continuous with probability one. These are the card's four
defining properties. -/

/-! Helper lemmas for the proofs below. -/

lemma integral_Ioi_mul_exp (v : ℝ) (hv : 0 < v) :
    ∫ x in Set.Ioi (0:ℝ), x * rexp (-x ^ 2 / (2 * v)) = v := by
  have A : ∀ x ∈ Set.Ici (0:ℝ), HasDerivAt (fun x => -v * rexp (-x ^ 2 / (2 * v)))
      (x * rexp (-x ^ 2 / (2 * v))) x := by
    intro x _
    have h1 : HasDerivAt (fun y : ℝ => -y ^ 2 / (2 * v)) (-(2 * x) / (2 * v)) x := by
      have := ((hasDerivAt_pow 2 x).const_mul (-1 : ℝ)).div_const (2 * v)
      convert this using 1
      · ext y; ring
      · simp
    have := h1.exp.const_mul (-v)
    convert this using 1
    field_simp
  have B : Filter.Tendsto (fun x : ℝ => -v * rexp (-x ^ 2 / (2 * v))) Filter.atTop
      (nhds (-v * 0)) := by
    refine Filter.Tendsto.const_mul _ (tendsto_exp_atBot.comp ?_)
    have : Filter.Tendsto (fun x : ℝ => x ^ 2) Filter.atTop Filter.atTop :=
      Filter.tendsto_pow_atTop two_ne_zero
    have h2 := this.atTop_div_const (r := 2 * v) (by positivity)
    simpa [neg_div] using h2
  have hint : IntegrableOn (fun x : ℝ => x * rexp (-x ^ 2 / (2 * v))) (Set.Ioi 0) := by
    have := integrable_mul_exp_neg_mul_sq (b := (2 * v)⁻¹) (by positivity)
    refine (this.congr ?_).integrableOn
    refine Filter.Eventually.of_forall fun x => ?_
    simp only
    congr 2
    field_simp
  rw [integral_Ioi_of_hasDerivAt_of_tendsto' A hint B]
  simp

lemma gaussianReal_abs_le_bound (v : ℝ≥0) (hv : v ≠ 0) (a : ℝ) :
    gaussianReal 0 v {x | |x| ≤ a} ≤ ENNReal.ofReal (2 * a / √(2 * π * v)) := by
  rw [gaussianReal_apply _ hv]
  have hset : {x : ℝ | |x| ≤ a} = Set.Icc (-a) a := by ext x; simp [abs_le]
  rw [hset]
  calc ∫⁻ x in Set.Icc (-a) a, gaussianPDF 0 v x
      ≤ ∫⁻ x in Set.Icc (-a) a, ENNReal.ofReal (√(2 * π * v))⁻¹ := by
        refine lintegral_mono fun x => ?_
        rw [gaussianPDF]
        refine ENNReal.ofReal_le_ofReal ?_
        rw [gaussianPDFReal]
        have h1 : rexp (-(x - 0) ^ 2 / (2 * v)) ≤ 1 := by
          refine Real.exp_le_one_iff.2 ?_
          have : 0 ≤ (x - 0) ^ 2 / (2 * v) := by positivity
          rw [neg_div]; linarith
        have h0 : 0 ≤ (√(2 * π * v))⁻¹ := by positivity
        exact mul_le_of_le_one_right h0 h1
    _ = ENNReal.ofReal (√(2 * π * v))⁻¹ * volume (Set.Icc (-a) a) := setLIntegral_const _ _
    _ = ENNReal.ofReal (2 * a / √(2 * π * v)) := by
        rw [Real.volume_Icc, ← ENNReal.ofReal_mul (by positivity)]
        congr 1; ring

lemma brownian_three_small_moves_prob {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (M N n : ℕ) (hn : 1 ≤ n) :
    P (⋃ k ∈ Finset.range ((N + 1) * n + 1), ⋂ j ∈ Finset.range 3,
        {ω | |W (((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω - W (((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω|
          ≤ 7 * M / n})
      ≤ ENNReal.ofReal (2 * (N + 1) * (14 * M) ^ 3 / √n) := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  have hnr : (0:ℝ) < n := by exact_mod_cast hn
  have hr : 0 < √(n:ℝ) := Real.sqrt_pos.2 hnr
  have hrr : √(n:ℝ) * √(n:ℝ) = n := Real.mul_self_sqrt hnr.le
  have hstep : ∀ k j : ℕ,
      P {ω | |W (((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω - W (((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω|
          ≤ 7 * M / n} ≤ ENNReal.ofReal (14 * M / √n) := by
    intro k j
    have hl := hW.hasLaw_sub (((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0)) (((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0))
    have hv : nndist ((((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0) : ℝ≥0) : ℝ)
        ((((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0) : ℝ≥0) : ℝ) = (n : ℝ≥0)⁻¹ := by
      apply NNReal.eq
      rw [coe_nndist, Real.dist_eq]
      push_cast
      rw [show ((k:ℝ) + (j + 1)) / n - (k + j) / n = (n:ℝ)⁻¹ by field_simp; ring]
      exact abs_of_pos (by positivity)
    replace hl : HasLaw (W (((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0)) - W (((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0)))
        (gaussianReal 0 (n : ℝ≥0)⁻¹) P := by
      convert hl using 2
      exact hv.symm
    have hm := hl.measure_eq (p := fun x => |x| ≤ 7 * M / n)
      (measurableSet_le (by fun_prop) measurable_const)
    simp only [Pi.sub_apply] at hm
    rw [hm]
    refine (gaussianReal_abs_le_bound _ (by simp; omega) _).trans (ENNReal.ofReal_le_ofReal ?_)
    have hs : √(2 * π * (((n : ℝ≥0)⁻¹ : ℝ≥0) : ℝ)) = √(2 * π) / √n := by
      push_cast
      rw [Real.sqrt_mul (by positivity), Real.sqrt_inv]
      ring
    have h1 : 1 ≤ √(2 * π) := by
      rw [Real.one_le_sqrt]; linarith [Real.two_le_pi]
    rw [hs, div_le_div_iff₀ (by positivity) hr]
    have hM : (0:ℝ) ≤ M := by positivity
    rw [show 2 * (7 * (M:ℝ) / n) * √n = 14 * M / √n by
      field_simp
      nlinarith [hrr]]
    rw [← mul_div_assoc]
    exact div_le_div_of_nonneg_right (le_mul_of_one_le_right (by positivity) h1) hr.le
  calc _ ≤ ∑ k ∈ Finset.range ((N + 1) * n + 1), P (⋂ j ∈ Finset.range 3,
        {ω | |W (((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω - W (((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω|
          ≤ 7 * M / n}) := measure_biUnion_finset_le _ _
    _ ≤ ∑ k ∈ Finset.range ((N + 1) * n + 1), ENNReal.ofReal (14 * M / √n) ^ 3 := by
        refine Finset.sum_le_sum fun k _ => ?_
        have hmono : Monotone (fun i : ℕ => ((k + i : ℕ) : ℝ≥0) / (n : ℝ≥0)) := by
          intro i i' hii
          simp only
          gcongr
        have hind := hW.hasIndepIncrements.nat hmono
        rw [hind.meas_biInter (S := Finset.range 3) (s := fun j => {ω |
            |W (((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω - W (((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω|
              ≤ 7 * M / n}) (fun j _ => ⟨{x | |x| ≤ 7 * M / n},
              measurableSet_le (by fun_prop) measurable_const, rfl⟩)]
        calc _ ≤ ENNReal.ofReal (14 * M / √n) ^ (Finset.range 3).card :=
              Finset.prod_le_pow_card _ _ _ fun j _ => hstep k j
          _ = _ := by simp
    _ = ENNReal.ofReal (((N + 1) * n + 1 : ℕ) * (14 * M / √n) ^ 3) := by
        rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul, ENNReal.ofReal_mul (by positivity),
          ENNReal.ofReal_pow (by positivity), ENNReal.ofReal_natCast]
    _ ≤ _ := by
        refine ENNReal.ofReal_le_ofReal ?_
        have hn1 : (1:ℝ) ≤ n := by exact_mod_cast hn
        have hX : (0:ℝ) ≤ (14 * M) ^ 3 := by positivity
        rw [div_pow, mul_div_assoc', div_le_div_iff₀ (by positivity) hr]
        push_cast
        have h3 : √(n:ℝ) ^ 3 = n * √n := by rw [pow_succ, sq, hrr]
        rw [h3]
        have : ((N:ℝ) + 1) * n + 1 ≤ 2 * (N + 1) * n := by nlinarith
        have := mul_le_mul_of_nonneg_right this (mul_nonneg hX hr.le)
        nlinarith

lemma slope_gives_three_small_moves {Ω : Type*} {W : ℝ≥0 → Ω → ℝ} (ω : Ω) (s : ℝ≥0) (D : ℝ)
    (h : HasDerivWithinAt (fun u : ℝ => W u.toNNReal ω) D (Set.Ici (s : ℝ)) s) :
    ∃ M N n0 : ℕ, ∀ n, n0 ≤ n → ω ∈ ⋃ k ∈ Finset.range ((N + 1) * n + 1), ⋂ j ∈ Finset.range 3,
        {ω | |W (((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω - W (((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω|
          ≤ 7 * M / n} := by
  set f := fun u : ℝ => W u.toNNReal ω with hf
  have hev := (hasDerivWithinAt_iff_isLittleO.1 h).def one_pos
  obtain ⟨u, hu, hsub⟩ := mem_nhdsGE_iff_exists_Ico_subset.1 hev
  have hbound : ∀ t ∈ Set.Ico (s : ℝ) u, |f t - f s| ≤ (|D| + 1) * (t - s) := by
    intro t ht
    have h1 := hsub ht
    simp only [Set.mem_ofPred_eq, Real.norm_eq_abs, smul_eq_mul, one_mul] at h1
    have hts : 0 ≤ t - s := sub_nonneg.2 ht.1
    rw [abs_of_nonneg hts] at h1
    have h2 := abs_le.1 h1
    have h3 : (t - s) * D ≤ (t - s) * |D| := mul_le_mul_of_nonneg_left (le_abs_self D) hts
    have h4 : (t - s) * -|D| ≤ (t - s) * D := mul_le_mul_of_nonneg_left (neg_abs_le D) hts
    rw [abs_le]; constructor <;> nlinarith
  refine ⟨⌈|D| + 1⌉₊, ⌈(s : ℝ)⌉₊, ⌈4 / (u - s)⌉₊ + 1, fun n hn => ?_⟩
  have hus : 0 < u - s := sub_pos.2 hu
  have hn' : (⌈4 / (u - s)⌉₊ : ℝ) + 1 ≤ n := by exact_mod_cast hn
  have hceil : 4 / (u - s) ≤ (⌈4 / (u - s)⌉₊ : ℝ) := Nat.le_ceil _
  have hdiv : 0 ≤ 4 / (u - s) := by positivity
  have hnpos : (0 : ℝ) < n := by linarith
  have hn4 : 4 < (u - s) * n := by
    have : 4 / (u - s) < n := by linarith
    rw [div_lt_iff₀ hus] at this; linarith
  have hs0 : (0 : ℝ) ≤ s := s.2
  set k := ⌈(s : ℝ) * n⌉₊ with hkdef
  have hk1 : (s : ℝ) * n ≤ k := Nat.le_ceil _
  have hk2 : (k : ℝ) < s * n + 1 := Nat.ceil_lt_add_one (by positivity)
  have hM : |D| + 1 ≤ (⌈|D| + 1⌉₊ : ℝ) := Nat.le_ceil _
  have hN : (s : ℝ) ≤ ⌈(s : ℝ)⌉₊ := Nat.le_ceil _
  simp only [Set.mem_iUnion, Set.mem_iInter, Finset.mem_range, Set.mem_ofPred_eq]
  refine ⟨k, ?_, fun j hj => ?_⟩
  · have : (k : ℝ) < ((⌈(s : ℝ)⌉₊ + 1) * n + 1 : ℕ) := by
      push_cast; nlinarith
    exact_mod_cast this
  · have hval : ∀ i : ℕ, W ((i : ℝ≥0) / (n : ℝ≥0)) ω = f ((i : ℝ) / n) := by
      intro i
      have : ((i : ℝ) / n) = (((i : ℝ≥0) / (n : ℝ≥0) : ℝ≥0) : ℝ) := by push_cast; rfl
      simp only [hf, this, Real.toNNReal_coe]
    rw [hval, hval]
    have hj' : (j : ℝ) ≤ 2 := by exact_mod_cast (Nat.lt_succ_iff.1 hj)
    have hj0 : (0 : ℝ) ≤ j := by positivity
    set p : ℝ := ((k + j : ℕ) : ℝ) / n with hp
    set q : ℝ := ((k + (j + 1) : ℕ) : ℝ) / n with hq
    have hpn : p * n = k + j := by rw [hp]; push_cast; field_simp
    have hqn : q * n = k + j + 1 := by rw [hq]; push_cast; field_simp; ring
    have hpI : p ∈ Set.Ico (s : ℝ) u := by
      constructor
      · rw [hp, le_div_iff₀ hnpos]; push_cast; linarith
      · rw [hp, div_lt_iff₀ hnpos]; push_cast; nlinarith
    have hqI : q ∈ Set.Ico (s : ℝ) u := by
      constructor
      · rw [hq, le_div_iff₀ hnpos]; push_cast; linarith
      · rw [hq, div_lt_iff₀ hnpos]; push_cast; nlinarith
    have hp3 : p - s ≤ 3 / n := by
      rw [le_div_iff₀ hnpos, sub_mul, hpn]; linarith
    have hq4 : q - s ≤ 4 / n := by
      rw [le_div_iff₀ hnpos, sub_mul, hqn]; linarith
    have e1 := hbound p hpI
    have e2 := hbound q hqI
    have hps : 0 ≤ p - s := sub_nonneg.2 hpI.1
    have hqs : 0 ≤ q - s := sub_nonneg.2 hqI.1
    set Mr : ℝ := (⌈|D| + 1⌉₊ : ℝ)
    calc |f q - f p| ≤ |f q - f s| + |f p - f s| :=
          (abs_sub_le _ _ _).trans_eq (by rw [abs_sub_comm (f s)])
      _ ≤ (|D| + 1) * (q - s) + (|D| + 1) * (p - s) := add_le_add e2 e1
      _ ≤ Mr * (q - s) + Mr * (p - s) := by gcongr
      _ ≤ Mr * (4 / n) + Mr * (3 / n) := by gcongr
      _ = 7 * Mr / n := by ring

/-- **The scaling law.** If `W` is a Brownian motion and `c > 0`, then the zoomed process
`V t = (1/c) W (c² t)`, the clock run c-squared times as fast and every distance shrunk by c,
is again a Brownian motion. -/
theorem scaled_brownian_motion_is_brownian {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (c : ℝ≥0) (hc : 0 < c) :
    IsBrownianReal (fun t ω => (c : ℝ)⁻¹ * W (c ^ 2 * t) ω) P := by
  have h := hW.smul (c := c ^ 2) (pow_ne_zero 2 hc.ne')
  have e : √((c ^ 2 : ℝ≥0) : ℝ) = (c : ℝ) := by
    rw [NNReal.coe_pow]; exact Real.sqrt_sq c.2
  simpa only [e] using h

/-- **The root-t rule.** The position of a Brownian motion at time t has the law of root t
times a standard normal number Z, and its mean distance from the start is `√(2t/π)`. -/
theorem brownian_position_scales_by_root_t {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (t : ℝ≥0) :
    HasLaw (W t) ((gaussianReal 0 1).map (fun z => √(t : ℝ) * z)) P ∧
      ∫ ω, |W t ω| ∂P = √(2 * (t : ℝ) / π) := by
  have hl := hW.hasLaw_eval t
  refine ⟨?_, ?_⟩
  · rw [gaussianReal_map_const_mul]
    convert hl using 2
    · simp
    · ext
      simp
  · have hc := hl.integral_comp (f := fun x => |x|) (by fun_prop)
    simp only [Function.comp_def] at hc
    rw [hc]
    rcases eq_or_ne t 0 with rfl | ht
    · simp
    rw [integral_gaussianReal_eq_integral_smul ht]
    have : (fun x : ℝ => gaussianPDFReal 0 t x • |x|) =
        fun x => (fun y : ℝ => (√(2 * π * t))⁻¹ * (y * rexp (-y ^ 2 / (2 * t)))) |x| := by
      ext x
      simp [gaussianPDFReal, smul_eq_mul, sq_abs]
      ring
    rw [this, integral_comp_abs (f := fun y : ℝ => (√(2 * π * t))⁻¹ * (y * rexp (-y ^ 2 / (2 * t)))),
      integral_const_mul,
      integral_Ioi_mul_exp _ (by positivity)]
    have htp : (0:ℝ) < t := by positivity
    rw [show 2 * (t:ℝ) / π = (2 * t) ^ 2 / (2 * π * t) by field_simp,
      Real.sqrt_div' _ (by positivity), Real.sqrt_sq (by positivity)]
    field_simp

/-- **Smooth nowhere.** With probability one, the path `t ↦ W t` of a Brownian motion has a
finite slope at no time s at all. The slope is read from the right of s (the path is defined
for times from 0 on), so this rules out a two-sided slope at every s > 0 and a right-hand
slope at s = 0, as the card's three-move proof shows. -/
theorem brownian_path_has_slope_nowhere {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) :
    ∀ᵐ ω ∂P, ∀ s : ℝ≥0, ∀ D : ℝ,
      ¬ HasDerivWithinAt (fun u : ℝ => W u.toNNReal ω) D (Set.Ici (s : ℝ)) s := by
  rw [ae_iff]
  simp only [not_forall, not_not]
  refine measure_mono_null (t := ⋃ M : ℕ, ⋃ N : ℕ, ⋃ n0 : ℕ, ⋂ n : ℕ, ⋂ (_ : n0 ≤ n),
      ⋃ k ∈ Finset.range ((N + 1) * n + 1), ⋂ j ∈ Finset.range 3,
        {ω | |W (((k + (j + 1) : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω - W (((k + j : ℕ) : ℝ≥0) / (n : ℝ≥0)) ω|
          ≤ 7 * M / n}) ?_ ?_
  · intro ω hω
    obtain ⟨s, D, h⟩ := hω
    obtain ⟨M, N, n0, H⟩ := slope_gives_three_small_moves ω s D h
    exact Set.mem_iUnion.2 ⟨M, Set.mem_iUnion.2 ⟨N, Set.mem_iUnion.2 ⟨n0, Set.mem_iInter₂.2 H⟩⟩⟩
  · refine measure_iUnion_null fun M => measure_iUnion_null fun N =>
      measure_iUnion_null fun n0 => ?_
    rw [← nonpos_iff_eq_zero]
    have hT : Filter.Tendsto (fun n : ℕ => ENNReal.ofReal (2 * (N + 1) * (14 * M) ^ 3 / √n))
        Filter.atTop (nhds 0) := by
      rw [← ENNReal.ofReal_zero]
      refine ENNReal.tendsto_ofReal ?_
      exact tendsto_const_nhds.div_atTop
        (Real.tendsto_sqrt_atTop.comp tendsto_natCast_atTop_atTop)
    refine ge_of_tendsto hT ?_
    filter_upwards [Filter.eventually_ge_atTop (max n0 1)] with n hn
    refine (measure_mono (Set.iInter₂_subset n (le_of_max_le_left hn))).trans ?_
    exact brownian_three_small_moves_prob hW M N n (le_of_max_le_right hn)

/-! The card's exact worked arithmetic. -/

-- Variance after 4 s is 4; zooming with c = 2 divides it by 2² = 4, back to 1.
example : (4 : ℚ) / 2 ^ 2 = 1 := by norm_num

-- Four times as long means 2 times as far: √4 = 2.
example : √(4 : ℝ) = 2 := by norm_num

-- The blow-up of seconds 8 to 9 uses c = 1/4: time stretched by 16, moves by 4 = √16.
example : ((1 : ℚ) / 4)⁻¹ ^ 2 = 16 ∧ ((1 : ℚ) / 4)⁻¹ = 4 := by norm_num
example : √(16 : ℝ) = 4 := by norm_num

-- Frames 1/4096 s apart: √4096 = 64, so the mean chord speed is 64 times the 1-second value.
example : √(4096 : ℝ) = 64 := by norm_num
example : (64 : ℕ) ^ 2 = 4096 := by norm_num

-- K √h for K = 10 and h = 1/4096 is 10/64 = 0.15625 = 5/32.
example : (10 : ℝ) * √(1 / 4096) = 5 / 32 := by norm_num

-- The three-move bound: each move is at most 4K/n + 3K/n = 7K/n.
example : ∀ K n : ℚ, K * 4 / n + K * 3 / n = 7 * K / n := by intro K n; ring

-- Interval width 2 · 7 = 14, and three moves give 7³ = 343.
example : 2 * 7 = 14 ∧ 7 ^ 3 = 343 := by decide

-- n runs from 4096 = 2¹² to 16,777,216 = 2²⁴ = 4096², and √16777216 = 4096.
example : (2 : ℕ) ^ 12 = 4096 ∧ (2 : ℕ) ^ 24 = 16777216 ∧ (4096 : ℕ) ^ 2 = 16777216 := by norm_num
example : √(16777216 : ℝ) = 4096 := by norm_num

-- Multiplying n by 4 halves 343/√n, since √4 = 2.
example : √((4 : ℝ) * 4096) = 2 * √4096 := by norm_num

#print axioms integral_Ioi_mul_exp
#print axioms gaussianReal_abs_le_bound
#print axioms brownian_three_small_moves_prob
#print axioms slope_gives_three_small_moves
#print axioms scaled_brownian_motion_is_brownian
#print axioms brownian_position_scales_by_root_t
#print axioms brownian_path_has_slope_nowhere
