-- The Poisson formula: a harmonic function on the unit disc that is continuous up to the rim equals the Poisson-kernel weighted average of its rim values, the weights are positive and total 1, and the same average builds a harmonic function from any continuous rim.
import Mathlib.Analysis.Complex.Harmonic.Poisson
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.InnerProductSpace.Harmonic.Constructions

open Complex Metric Filter Topology InnerProductSpace

lemma pois_circleAverage_unit (f : ℂ → ℝ) :
    Real.circleAverage f 0 1 = 1 / (2 * Real.pi) * ∫ s in (0 : ℝ)..2 * Real.pi,
      f (Complex.exp ((s : ℂ) * I)) := by
  simp [Real.circleAverage_def, circleMap, one_div]

#print axioms pois_circleAverage_unit

lemma pois_kernel_unit (w : ℂ) (s : ℝ) :
    poissonKernel 0 w (Complex.exp ((s : ℂ) * I)) =
      (1 - ‖w‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - w‖ ^ 2 := by
  simp [poissonKernel_def, norm_exp_ofReal_mul_I]

#print axioms pois_kernel_unit

lemma pois_norm_sq (r t s : ℝ) :
    ‖Complex.exp ((s : ℂ) * I) - (r : ℂ) * Complex.exp ((t : ℂ) * I)‖ ^ 2 =
      1 - 2 * r * Real.cos (t - s) + r ^ 2 := by
  rw [Complex.sq_norm, Complex.normSq_apply]
  simp [Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im, Real.cos_sub]
  linear_combination (Real.sin_sq_add_cos_sq s) + r ^ 2 * (Real.sin_sq_add_cos_sq t)

#print axioms pois_norm_sq

lemma pois_norm_lower {a : ℂ} (s : ℝ) :
    1 - ‖a‖ ≤ ‖Complex.exp ((s : ℂ) * I) - a‖ := by
  have := norm_sub_norm_le (Complex.exp ((s : ℂ) * I)) a
  rw [norm_exp_ofReal_mul_I] at this
  linarith

#print axioms pois_norm_lower

lemma pois_h_arg {h : ℝ → ℝ} (hper : Function.Periodic h (2 * Real.pi)) (t s : ℝ) :
    h (t + arg (Complex.exp ((s : ℂ) * I) * Complex.exp (-((t : ℂ) * I)))) = h s := by
  have e : Complex.exp ((s : ℂ) * I) * Complex.exp (-((t : ℂ) * I)) =
      Complex.exp (((s - t : ℝ) : ℂ) * I) := by
    rw [← Complex.exp_add]; congr 1; push_cast; ring
  rw [e, arg_exp_mul_I, ← self_sub_toIocDiv_zsmul, zsmul_eq_mul]
  rw [show t + (s - t - (toIocDiv Real.two_pi_pos (-Real.pi) (s - t) : ℝ) * (2 * Real.pi)) =
    s - (toIocDiv Real.two_pi_pos (-Real.pi) (s - t) : ℝ) * (2 * Real.pi) by ring]
  exact hper.sub_int_mul_eq _

#print axioms pois_h_arg

lemma pois_h_arg0 {h : ℝ → ℝ} (hper : Function.Periodic h (2 * Real.pi)) (s : ℝ) :
    h (arg (Complex.exp ((s : ℂ) * I))) = h s := by
  have := pois_h_arg hper 0 s
  simpa using this

#print axioms pois_h_arg0

lemma pois_cont {a : ℂ} (ha : a ∈ ball (0 : ℂ) 1) :
    Continuous (fun s : ℝ => (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2) := by
  have ha' : ‖a‖ < 1 := by simpa using ha
  apply Continuous.div continuous_const (by fun_prop)
  intro s
  have := pois_norm_lower (a := a) s
  have : 0 < ‖Complex.exp ((s : ℂ) * I) - a‖ := by linarith
  positivity

#print axioms pois_cont

lemma pois_total {a : ℂ} (ha : a ∈ ball (0 : ℂ) 1) :
    ∫ s in (0 : ℝ)..2 * Real.pi, (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2
      = 2 * Real.pi := by
  have := (harmonicContOnCl_const (c := (1 : ℝ)) (s := ball (0 : ℂ) 1)).circleAverage_poissonKernel_smul ha
  rw [pois_circleAverage_unit] at this
  simp only [Pi.smul_apply', smul_eq_mul, pois_kernel_unit, mul_one] at this
  field_simp at this
  linarith

#print axioms pois_total

/-- The Poisson formula on the unit disc: if u is harmonic inside the unit disc and continuous up
to the rim, then at the inside point at distance r < 1 from the centre and angle t, the height
u(r e^(it)) is the average over rim angles s from 0 to 2π of the rim height u(e^(is)), each weighted
by (1 − r^2)/(1 − 2r cos(t − s) + r^2). -/
theorem poisson_integral_formula (u : ℂ → ℝ)
    (hharm : HarmonicOnNhd u (ball (0 : ℂ) 1))
    (hcont : ContinuousOn u (closedBall (0 : ℂ) 1))
    (r t : ℝ) (hr0 : 0 ≤ r) (hr1 : r < 1) :
    u ((r : ℂ) * Complex.exp ((t : ℂ) * I)) =
      1 / (2 * Real.pi) * ∫ s in (0 : ℝ)..2 * Real.pi,
        (1 - r ^ 2) / (1 - 2 * r * Real.cos (t - s) + r ^ 2) * u (Complex.exp ((s : ℂ) * I)) := by
  have hw : (r : ℂ) * Complex.exp ((t : ℂ) * I) ∈ ball (0 : ℂ) 1 := by
    simp [norm_exp_ofReal_mul_I, abs_of_nonneg hr0, hr1]
  have := (HarmonicContOnCl.mk_ball hharm hcont).circleAverage_poissonKernel_smul hw
  rw [← this, pois_circleAverage_unit]
  congr 1
  apply intervalIntegral.integral_congr
  intro s _
  simp only [Pi.smul_apply', smul_eq_mul, pois_kernel_unit, pois_norm_sq]
  simp [norm_exp_ofReal_mul_I, abs_of_nonneg hr0]

/-- The weights: for a point strictly inside the unit disc, every Poisson weight
(1 − r^2)/(1 − 2r cos(t − s) + r^2) is positive, and the weights average to 1 round the rim. -/
theorem poisson_kernel_pos_and_total_one (r t : ℝ) (hr0 : 0 ≤ r) (hr1 : r < 1) :
    (∀ s : ℝ, 0 < (1 - r ^ 2) / (1 - 2 * r * Real.cos (t - s) + r ^ 2)) ∧
      1 / (2 * Real.pi) * ∫ s in (0 : ℝ)..2 * Real.pi,
        (1 - r ^ 2) / (1 - 2 * r * Real.cos (t - s) + r ^ 2) = 1 := by
  refine ⟨fun s => ?_, ?_⟩
  · apply div_pos
    · nlinarith
    · nlinarith [Real.cos_le_one (t - s)]
  · have := poisson_integral_formula (fun _ => (1 : ℝ)) (harmonicOnNhd_const 1)
      continuousOn_const r t hr0 hr1
    simpa using this.symm

/-- Building u from the rim: for any continuous rim height h (a function of the rim angle that
repeats every 2π), the Poisson average
U(a) = (1/2π) ∫ (1 − |a|^2)/|e^(is) − a|^2 · h(s) ds is harmonic inside the unit disc, and as the
inside point a moves out to the rim point e^(it), U(a) tends to the rim value h(t). -/
theorem poisson_integral_solves_dirichlet (h : ℝ → ℝ) (hh : Continuous h)
    (hper : Function.Periodic h (2 * Real.pi)) :
    let U : ℂ → ℝ := fun a => 1 / (2 * Real.pi) * ∫ s in (0 : ℝ)..2 * Real.pi,
      (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * h s
    HarmonicOnNhd U (ball (0 : ℂ) 1) ∧
      ∀ t : ℝ, Tendsto U (𝓝[ball (0 : ℂ) 1] Complex.exp ((t : ℂ) * I)) (𝓝 (h t)) := by
  intro U
  constructor
  · let g : ℂ → ℝ := fun ζ => h (arg ζ)
    have hg : CircleIntegrable g 0 1 := by
      unfold CircleIntegrable
      have : (fun θ => g (circleMap 0 1 θ)) = h := by
        funext θ; simp [circleMap, g, pois_h_arg0 hper]
      rw [this]; exact hh.intervalIntegrable _ _
    have hg' : CircleIntegrable (fun ζ => (g ζ : ℂ)) 0 1 := by
      unfold CircleIntegrable
      have : (fun θ => (g (circleMap 0 1 θ) : ℂ)) = fun θ => (h θ : ℂ) := by
        funext θ; simp [circleMap, g, pois_h_arg0 hper]
      rw [this]; exact (Complex.continuous_ofReal.comp hh).intervalIntegrable _ _
    have hF := analyticOnNhd_circleAverage_herglotzRieszKernel_smul hg'
    have key : ∀ a ∈ ball (0 : ℂ) 1, U a =
        (Real.circleAverage (fun ζ ↦ herglotzRieszKernel 0 a ζ • (g ζ : ℂ)) 0 1).re := by
      intro a ha
      have hns : a ∉ sphere (0 : ℂ) |1| := by
        have : ‖a‖ < 1 := by simpa using ha
        simp; linarith
      rw [re_circleAverage_herglotzRieszKernel_smul hg hns, ← poissonKernel_eq_re_herglotzRieszKernel,
        pois_circleAverage_unit]
      simp only [U, Pi.smul_apply', smul_eq_mul, pois_kernel_unit, g, pois_h_arg0 hper]
    intro x hx
    have hx' : x ∈ (sphere (0 : ℂ) |1|)ᶜ := by
      have : ‖x‖ < 1 := by simpa using hx
      simp; linarith
    refine (harmonicAt_congr_nhds ?_).mpr (AnalyticAt.harmonicAt_re (hF x hx'))
    exact Filter.eventuallyEq_of_mem (isOpen_ball.mem_nhds hx) key
  · intro t
    rw [Metric.tendsto_nhdsWithin_nhds]
    intro ε hε
    -- continuity of h, read on the circle near e^{it}
    obtain ⟨δ, hδ, hcl⟩ : ∃ δ > 0, ∀ s : ℝ,
        ‖Complex.exp ((s : ℂ) * I) - Complex.exp ((t : ℂ) * I)‖ < δ → |h s - h t| < ε / 2 := by
      let φ : ℂ → ℝ := fun ζ => h (t + arg (ζ * Complex.exp (-((t : ℂ) * I))))
      have h1 : Complex.exp ((t : ℂ) * I) * Complex.exp (-((t : ℂ) * I)) = 1 := by
        rw [← Complex.exp_add]; simp
      have hφ : ContinuousAt φ (Complex.exp ((t : ℂ) * I)) := by
        apply hh.continuousAt.comp
        apply continuousAt_const.add
        apply ContinuousAt.comp (g := arg)
        · rw [h1]; exact continuousAt_arg (by simp [slitPlane])
        · exact continuousAt_id.mul continuousAt_const
      have hφt : φ (Complex.exp ((t : ℂ) * I)) = h t := by simp [φ, h1]
      obtain ⟨δ, hδ, H⟩ := Metric.continuousAt_iff.1 hφ (ε / 2) (by positivity)
      refine ⟨δ, hδ, fun s hs => ?_⟩
      have := H (x := Complex.exp ((s : ℂ) * I)) (by rwa [dist_eq_norm])
      rw [hφt, Real.dist_eq] at this
      simpa [φ, pois_h_arg hper] using this
    obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn
      (s := Set.Icc (0 : ℝ) (2 * Real.pi)) hh.continuousOn
    have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM 0 ⟨le_rfl, by positivity⟩)
    set C := M + |h t| + 1 with hC
    have hCpos : 0 < C := by positivity
    have hCb : ∀ s ∈ Set.Icc (0 : ℝ) (2 * Real.pi), |h s - h t| ≤ C := by
      intro s hs
      have := hM s hs
      rw [Real.norm_eq_abs] at this
      have := abs_sub (h s) (h t)
      linarith
    refine ⟨min (δ / 2) (ε * δ ^ 2 / (32 * C)), by positivity, ?_⟩
    intro a ha hdist
    rw [dist_eq_norm] at hdist
    have hd1 : ‖a - Complex.exp ((t : ℂ) * I)‖ < δ / 2 := lt_of_lt_of_le hdist (min_le_left _ _)
    have hd2 : ‖a - Complex.exp ((t : ℂ) * I)‖ < ε * δ ^ 2 / (32 * C) :=
      lt_of_lt_of_le hdist (min_le_right _ _)
    have ha' : ‖a‖ < 1 := by simpa using ha
    have hna : 0 ≤ ‖a‖ := norm_nonneg _
    have hnum : 0 ≤ 1 - ‖a‖ ^ 2 := by nlinarith
    -- 1 - |a| ≤ |a - e^{it}|
    have hrad : 1 - ‖a‖ ≤ ‖a - Complex.exp ((t : ℂ) * I)‖ := by
      have := pois_norm_lower (a := a) t
      rwa [norm_sub_rev] at this
    have hnum2 : 1 - ‖a‖ ^ 2 ≤ 2 * ‖a - Complex.exp ((t : ℂ) * I)‖ := by nlinarith
    set B := (1 - ‖a‖ ^ 2) / (δ / 2) ^ 2 * C with hB
    have hB0 : 0 ≤ B := by positivity
    have hBlt : B < ε / 4 := by
      rw [hB, div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
      have : (1 - ‖a‖ ^ 2) * (32 * C) < ε * δ ^ 2 * 2 := by
        have := (lt_div_iff₀ (by positivity : (0:ℝ) < 32 * C)).1 hd2
        nlinarith
      nlinarith
    have hcontP := pois_cont ha
    have hI := pois_total ha
    have hi1 : IntervalIntegrable (fun s : ℝ =>
        (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * h s) MeasureTheory.volume 0
        (2 * Real.pi) := (hcontP.mul hh).intervalIntegrable _ _
    have hi2 : IntervalIntegrable (fun s : ℝ =>
        (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * h t) MeasureTheory.volume 0
        (2 * Real.pi) := (hcontP.mul continuous_const).intervalIntegrable _ _
    have e : U a - h t = 1 / (2 * Real.pi) * ∫ s in (0 : ℝ)..2 * Real.pi,
        (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * (h s - h t) := by
      have hpi : 2 * Real.pi ≠ 0 := by positivity
      show 1 / (2 * Real.pi) * (∫ s in (0 : ℝ)..2 * Real.pi,
        (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * h s) - h t = _
      simp_rw [mul_sub]
      rw [intervalIntegral.integral_sub hi1 hi2, intervalIntegral.integral_mul_const, hI,
        mul_sub, ← mul_assoc, one_div_mul_cancel hpi, one_mul]
    have hbound : ‖∫ s in (0 : ℝ)..2 * Real.pi,
        (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * (h s - h t)‖ ≤
        ∫ s in (0 : ℝ)..2 * Real.pi,
          (ε / 2 * ((1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2) + B) := by
      apply intervalIntegral.norm_integral_le_of_norm_le (by positivity)
      · refine MeasureTheory.ae_of_all _ (fun s hs => ?_)
        have hsI : s ∈ Set.Icc (0 : ℝ) (2 * Real.pi) := ⟨hs.1.le, hs.2⟩
        have hP0 : 0 ≤ (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 := by positivity
        rw [Real.norm_eq_abs, abs_mul, abs_of_nonneg hP0]
        by_cases hs' : ‖Complex.exp ((s : ℂ) * I) - Complex.exp ((t : ℂ) * I)‖ < δ
        · have := hcl s hs'
          have : (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * |h s - h t| ≤
              (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * (ε / 2) :=
            mul_le_mul_of_nonneg_left this.le hP0
          linarith
        · push Not at hs'
          have htri : ‖Complex.exp ((s : ℂ) * I) - Complex.exp ((t : ℂ) * I)‖ ≤
              ‖Complex.exp ((s : ℂ) * I) - a‖ + ‖a - Complex.exp ((t : ℂ) * I)‖ :=
            norm_sub_le_norm_sub_add_norm_sub _ _ _
          have hfar : δ / 2 ≤ ‖Complex.exp ((s : ℂ) * I) - a‖ := by linarith
          have hPle : (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 ≤
              (1 - ‖a‖ ^ 2) / (δ / 2) ^ 2 :=
            div_le_div_of_nonneg_left hnum (by positivity) (by gcongr)
          have : (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * |h s - h t| ≤ B :=
            mul_le_mul hPle (hCb s hsI) (abs_nonneg _) (by positivity)
          have : 0 ≤ ε / 2 * ((1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2) := by
            positivity
          linarith
      · exact ((continuous_const.mul hcontP).add continuous_const).intervalIntegrable _ _
    have hcalc : ∫ s in (0 : ℝ)..2 * Real.pi,
          (ε / 2 * ((1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2) + B) =
        ε / 2 * (2 * Real.pi) + 2 * Real.pi * B := by
      rw [intervalIntegral.integral_add
        (f := fun s : ℝ => ε / 2 * ((1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2))
        (g := fun _ => B) ((continuous_const.mul hcontP).intervalIntegrable _ _)
        intervalIntegrable_const, intervalIntegral.integral_const_mul, hI,
        intervalIntegral.integral_const]
      simp
    rw [Real.dist_eq, e, abs_mul, ← Real.norm_eq_abs (∫ s in (0 : ℝ)..2 * Real.pi, _)]
    have hpi : 0 < Real.pi := Real.pi_pos
    rw [abs_of_pos (by positivity : (0:ℝ) < 1 / (2 * Real.pi))]
    calc 1 / (2 * Real.pi) * ‖∫ s in (0 : ℝ)..2 * Real.pi,
          (1 - ‖a‖ ^ 2) / ‖Complex.exp ((s : ℂ) * I) - a‖ ^ 2 * (h s - h t)‖
        ≤ 1 / (2 * Real.pi) * (ε / 2 * (2 * Real.pi) + 2 * Real.pi * B) := by
          rw [← hcalc]; gcongr
      _ = ε / 2 + B := by field_simp
      _ < ε := by linarith

-- The card's worked numbers, halfway out (r = 1/2, t = 0).
-- Weight of the nearest rim point, s = 0: 3.
example : (1 - (1 / 2 : ℝ) ^ 2) / (1 - 2 * (1 / 2) * Real.cos (0 - 0) + (1 / 2) ^ 2) = 3 := by
  norm_num
-- Weight at s = π/2: 3/5.
example : (1 - (1 / 2 : ℝ) ^ 2) / (1 - 2 * (1 / 2) * Real.cos (0 - Real.pi / 2) + (1 / 2) ^ 2)
    = 3 / 5 := by
  norm_num
-- Weight of the farthest rim point, s = π: 1/3.
example : (1 - (1 / 2 : ℝ) ^ 2) / (1 - 2 * (1 / 2) * Real.cos (0 - Real.pi) + (1 / 2) ^ 2)
    = 1 / 3 := by
  norm_num
-- The drum: u = 20 + 5 r cos t at r = 1/2, t = 0 is 22.5.
example : (20 : ℝ) + 5 * (1 / 2) * Real.cos 0 = 45 / 2 := by
  norm_num
-- The second case: r = 4/5, t = 2π/3 gives 18.
example : (20 : ℝ) + 5 * (4 / 5) * Real.cos (2 * Real.pi / 3) = 18 := by
  have h : Real.cos (2 * Real.pi / 3) = -(1 / 2) := by
    rw [show 2 * Real.pi / 3 = Real.pi - Real.pi / 3 by ring, Real.cos_pi_sub, Real.cos_pi_div_three]
  rw [h]; norm_num
-- Off the drum, r = 2: the kernel is minus the kernel at r = 1/2 (s = 0 gives −3, s = π gives −1/3).
example : (1 - (2 : ℝ) ^ 2) / (1 - 2 * 2 * Real.cos (0 - 0) + 2 ^ 2) = -3 := by
  norm_num
example : (1 - (2 : ℝ) ^ 2) / (1 - 2 * 2 * Real.cos (0 - Real.pi) + 2 ^ 2) = -(1 / 3) := by
  norm_num
-- The Cayley map sends 3i to 1/2.
example : (3 * I - I) / (3 * I + I) = (1 / 2 : ℂ) := by
  rw [show 3 * I - I = 2 * I by ring, show 3 * I + I = 4 * I by ring,
    mul_div_mul_right _ _ I_ne_zero]
  norm_num

#print axioms poisson_integral_formula
#print axioms poisson_kernel_pos_and_total_one
#print axioms poisson_integral_solves_dirichlet
