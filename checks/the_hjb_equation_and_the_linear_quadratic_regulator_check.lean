-- The HJB equation: for the car x' = u with cost the integral of x^2 + u^2, no control costs less than x0^2, the rule u = -x costs exactly x0^2, the quadratic guess V = P x^2 turns HJB into 1 - P^2 = 0, and P = tanh s solves the deadline Riccati equation.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Order.Bounds.Basic
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Analysis.Calculus.FDeriv.Extend
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

open MeasureTheory Set Filter Topology

theorem hjb_cost_identity (x u : ℝ → ℝ) (x₀ : ℝ) (h0 : x 0 = x₀) (hc : ContinuousOn x (Ici 0))
    (hd : ∀ t, 0 < t → HasDerivAt x (u t) t) (hlim : Tendsto x atTop (𝓝 0))
    (hfin : (∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2)) ≠ ⊤) :
    IntegrableOn (fun t => (x t + u t) ^ 2) (Ioi 0) ∧
    (∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2)) =
      ENNReal.ofReal (x₀ ^ 2 + ∫ t in Ioi 0, (x t + u t) ^ 2) := by
  have hxm : AEStronglyMeasurable x (volume.restrict (Ioi (0:ℝ))) :=
    (hc.mono Ioi_subset_Ici_self).aestronglyMeasurable measurableSet_Ioi
  have hum : AEStronglyMeasurable u (volume.restrict (Ioi (0:ℝ))) := by
    refine (measurable_deriv x).aestronglyMeasurable.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioi] with t ht
    exact (hd t ht).deriv
  have hF : IntegrableOn (fun t => x t ^ 2 + u t ^ 2) (Ioi 0) := by
    refine ⟨(hxm.pow 2).add (hum.pow 2), ?_⟩
    rw [hasFiniteIntegral_iff_ofReal (Eventually.of_forall fun t => by positivity)]
    exact lt_top_iff_ne_top.mpr hfin
  have hP : IntegrableOn (fun t => 2 * x t * u t) (Ioi 0) := by
    refine Integrable.mono' hF ((hxm.const_mul 2).mul hum) (Eventually.of_forall fun t => ?_)
    rw [Real.norm_eq_abs, abs_le]
    constructor <;> nlinarith [sq_nonneg (x t + u t), sq_nonneg (x t - u t)]
  have hFTC : ∫ t in Ioi 0, 2 * x t * u t = 0 - x 0 ^ 2 := by
    refine integral_Ioi_of_hasDerivAt_of_tendsto (f := fun t => x t ^ 2)
      ((hc 0 (mem_Ici.mpr le_rfl)).pow 2) (fun t ht => ?_) hP ?_
    · convert (hd t ht).pow 2 using 1
      push_cast; ring
    · simpa using hlim.pow 2
  have hS : IntegrableOn (fun t => (x t + u t) ^ 2) (Ioi 0) := by
    have := hF.add hP
    refine this.congr_fun (fun t _ => ?_) measurableSet_Ioi
    simp only [Pi.add_apply]; ring
  refine ⟨hS, ?_⟩
  have hsum : ∫ t in Ioi 0, (x t + u t) ^ 2 =
      (∫ t in Ioi 0, (x t ^ 2 + u t ^ 2)) + ∫ t in Ioi 0, 2 * x t * u t := by
    rw [← integral_add hF hP]
    congr 1; funext t; ring
  rw [← ofReal_integral_eq_lintegral_ofReal hF (Eventually.of_forall fun t => by positivity)]
  congr 1
  rw [hsum, hFTC, h0]; ring

#print axioms hjb_cost_identity

theorem tanh_hasDerivAt (s : ℝ) : HasDerivAt Real.tanh (1 - Real.tanh s ^ 2) s := by
  have hc : Real.cosh s ≠ 0 := (Real.cosh_pos s).ne'
  have h := (Real.hasDerivAt_sinh s).div (Real.hasDerivAt_cosh s) hc
  have heq : (Real.sinh / Real.cosh) = Real.tanh := by
    funext y; rw [Pi.div_apply, Real.tanh_eq_sinh_div_cosh]
  rw [heq] at h
  convert h using 1
  rw [Real.tanh_eq_sinh_div_cosh, div_pow]
  field_simp

#print axioms tanh_hasDerivAt

/-- The best cost from speed error `x₀` is `x₀ ^ 2`, and the best control is `u = -x`.
For motion `x' = u` (continuous from time 0, with rate `u t` at every later time) that
returns the error to zero: every control costs at least `x₀ ^ 2` in total `x^2 + u^2`, and
a control that costs exactly `x₀ ^ 2` pushes `u = -x` at almost every time. The feedback
rule `u = -x` costs exactly `x₀ ^ 2`. -/
theorem best_cost_is_square_and_best_push_is_minus_error (x₀ : ℝ) :
    (∀ x u : ℝ → ℝ, x 0 = x₀ → ContinuousOn x (Ici 0) →
        (∀ t, 0 < t → HasDerivAt x (u t) t) → Tendsto x atTop (𝓝 0) →
        ENNReal.ofReal (x₀ ^ 2) ≤ ∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2) ∧
        ((∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2)) = ENNReal.ofReal (x₀ ^ 2) →
          ∀ᵐ t ∂(volume.restrict (Ioi 0)), u t = -x t)) ∧
    (∀ x : ℝ → ℝ, x 0 = x₀ → ContinuousOn x (Ici 0) →
        (∀ t, 0 < t → HasDerivAt x (-x t) t) →
        (∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + (-x t) ^ 2)) = ENNReal.ofReal (x₀ ^ 2)) := by
  refine ⟨fun x u h0 hc hd hlim => ?_, fun x h0 hc hd => ?_⟩
  · by_cases hfin : (∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2)) = ⊤
    · rw [hfin]
      exact ⟨le_top, fun h => absurd h.symm ENNReal.ofReal_ne_top⟩
    obtain ⟨hS, hEq⟩ := hjb_cost_identity x u x₀ h0 hc hd hlim hfin
    have hI : 0 ≤ ∫ t in Ioi 0, (x t + u t) ^ 2 := integral_nonneg fun t => sq_nonneg _
    rw [hEq]
    refine ⟨ENNReal.ofReal_le_ofReal (le_add_of_nonneg_right hI), fun h => ?_⟩
    rw [ENNReal.ofReal_eq_ofReal_iff (by positivity) (by positivity)] at h
    have h2 : ∫ t in Ioi 0, (x t + u t) ^ 2 = 0 := by linarith
    rw [integral_eq_zero_iff_of_nonneg (fun t => sq_nonneg _) hS] at h2
    filter_upwards [h2] with t ht
    have : x t + u t = 0 := by simpa using ht
    linarith
  · have hx : ∀ t, 0 < t → x t = x₀ * Real.exp (-t) := by
      intro t ht
      obtain ⟨c, _, hc'⟩ := exists_hasDerivAt_eq_slope (fun t => x t * Real.exp t) (fun _ => (0:ℝ))
        ht ((hc.mono Icc_subset_Ici_self).mul Real.continuous_exp.continuousOn)
        (fun c hc => by
          convert (hd c hc.1).mul (Real.hasDerivAt_exp c) using 1; ring)
      have hne : t - 0 ≠ 0 := by linarith
      have : x t * Real.exp t = x 0 * Real.exp 0 := by
        field_simp at hc'; linarith
      rw [Real.exp_zero, mul_one, h0] at this
      rw [← this, mul_assoc, ← Real.exp_add]; simp
    rw [setLIntegral_congr_fun measurableSet_Ioi
      (g := fun t => ENNReal.ofReal (2 * x₀ ^ 2 * Real.exp (-2 * t))) (fun t ht => by
        simp only
        rw [hx t ht, show -2 * t = -t + -t by ring, Real.exp_add]; ring_nf)]
    have hint : IntegrableOn (fun t => 2 * x₀ ^ 2 * Real.exp (-2 * t)) (Ioi 0) :=
      (integrableOn_exp_mul_Ioi (by norm_num : (-2:ℝ) < 0) 0).const_mul _
    rw [← ofReal_integral_eq_lintegral_ofReal hint (Eventually.of_forall fun t => by positivity),
      integral_const_mul, integral_exp_mul_Ioi (by norm_num : (-2:ℝ) < 0)]
    congr 1; simp; ring

/-- HJB with the quadratic guess `V = P x^2`, so `V_x = 2 P x`. The smallest cost rate
`x^2 + u^2 + V_x u` over all pushes `u` is `(1 - P^2) x^2`, reached only at the feedback
`u = -P x`. So the no-deadline HJB equation `0 = min_u (x^2 + u^2 + V_x u)` holds at every
state exactly when `P` solves the algebraic Riccati equation `1 - P^2 = 0`. -/
theorem hjb_quadratic_guess_gives_riccati (P : ℝ) :
    (∀ x : ℝ,
        IsLeast (range fun u : ℝ => x ^ 2 + u ^ 2 + 2 * P * x * u) ((1 - P ^ 2) * x ^ 2) ∧
        ∀ u : ℝ, x ^ 2 + u ^ 2 + 2 * P * x * u = (1 - P ^ 2) * x ^ 2 ↔ u = -P * x) ∧
    ((∀ x : ℝ, IsLeast (range fun u : ℝ => x ^ 2 + u ^ 2 + 2 * P * x * u) 0) ↔
        1 - P ^ 2 = 0) := by
  have hmin : ∀ x : ℝ,
      IsLeast (range fun u : ℝ => x ^ 2 + u ^ 2 + 2 * P * x * u) ((1 - P ^ 2) * x ^ 2) := by
    intro x
    refine ⟨⟨-P * x, by ring⟩, ?_⟩
    rintro _ ⟨u, rfl⟩
    nlinarith [sq_nonneg (u + P * x)]
  refine ⟨fun x => ⟨hmin x, fun u => ?_⟩, ⟨fun h => ?_, fun h x => ?_⟩⟩
  · constructor
    · intro h
      have : (u + P * x) ^ 2 = 0 := by linear_combination h
      have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
      linarith
    · rintro rfl; ring
  · have := (h 1).unique (hmin 1)
    linarith
  · have := hmin x
    rwa [h, zero_mul] at this

/-- With a deadline, the coefficient `P` as a function of the time left `s` solves the
Riccati differential equation `dP/ds = 1 - P^2` with `P = 0` when no time is left, and its
solution is `P = tanh s`: `tanh` solves it, and any solution equals `tanh` for `s ≥ 0`. -/
theorem riccati_with_deadline_solution_is_tanh :
    (Real.tanh 0 = 0 ∧ ∀ s : ℝ, HasDerivAt Real.tanh (1 - Real.tanh s ^ 2) s) ∧
    ∀ P : ℝ → ℝ, P 0 = 0 → ContinuousOn P (Ici 0) →
      (∀ s, 0 < s → HasDerivAt P (1 - P s ^ 2) s) → ∀ s, 0 ≤ s → P s = Real.tanh s := by
  refine ⟨⟨Real.tanh_zero, tanh_hasDerivAt⟩, fun P h0 hc hd s hs => ?_⟩
  obtain ⟨C, hC⟩ := isCompact_Icc.exists_bound_of_continuousOn (hc.mono (Icc_subset_Ici_self : Icc (0:ℝ) s ⊆ Ici 0))
  set R : ℝ := max C 1 with hR
  have hR1 : 1 ≤ R := le_max_right _ _
  have hLip : LipschitzOnWith (Real.toNNReal (2 * R)) (fun y : ℝ => 1 - y ^ 2)
      (Metric.closedBall 0 R) := by
    refine LipschitzOnWith.of_dist_le_mul fun y hy z hz => ?_
    rw [Metric.mem_closedBall, Real.dist_eq, sub_zero] at hy hz
    rw [Real.coe_toNNReal _ (by linarith), Real.dist_eq, Real.dist_eq]
    have : (1 - y ^ 2) - (1 - z ^ 2) = (z + y) * (z - y) := by ring
    rw [this, abs_mul, abs_sub_comm z y]
    have : |z + y| ≤ 2 * R := (abs_add_le z y).trans (by linarith)
    exact mul_le_mul_of_nonneg_right this (abs_nonneg _)
  have hP0 : HasDerivWithinAt P 1 (Ici 0) 0 := by
    have hcw : ContinuousWithinAt P (Ioi 0) 0 := (hc 0 (mem_Ici.mpr le_rfl)).mono Ioi_subset_Ici_self
    refine hasDerivWithinAt_Ici_of_tendsto_deriv
      (fun t ht => (hd t ht).differentiableAt.differentiableWithinAt) hcw self_mem_nhdsWithin ?_
    have h1 : Tendsto (fun t => 1 - P t ^ 2) (𝓝[>] 0) (𝓝 1) := by
      simpa [h0] using (hcw.tendsto.pow 2).const_sub 1
    refine h1.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with t ht
    exact (hd t ht).deriv.symm
  have := ODE_solution_unique_of_mem_Icc_right (v := fun _ y => 1 - y ^ 2)
    (s := fun _ => Metric.closedBall (0:ℝ) R) (fun _ _ => hLip)
    (hc.mono Icc_subset_Ici_self)
    (fun t ht => by
      rcases eq_or_lt_of_le ht.1 with h | h
      · subst h; simpa [h0] using hP0
      · exact (hd t h).hasDerivWithinAt)
    (fun t ht => by
      rw [Metric.mem_closedBall, dist_zero_right]
      exact (hC t (Ico_subset_Icc_self ht)).trans (le_max_left _ _))
    (fun t _ => (tanh_hasDerivAt t).continuousAt.continuousWithinAt)
    (fun t _ => (tanh_hasDerivAt t).hasDerivWithinAt)
    (fun t _ => by
      rw [Metric.mem_closedBall, dist_zero_right, Real.norm_eq_abs]
      exact (Real.abs_tanh_lt_one t).le.trans hR1)
    (by rw [h0, Real.tanh_zero])
  exact this ⟨hs, le_rfl⟩

-- The card's car starts 2 m/s too fast: the best cost is 2^2 = 4.
example : (2 : ℝ) ^ 2 = 4 := by norm_num
-- Best push at the start: u = -x₀ = -2.
example : -(1 : ℝ) * 2 = -2 := by norm_num
-- Step 2: at x = 2 with V_x = 4, the push u = -2 makes the HJB bracket zero.
example : (2 : ℝ) ^ 2 + (-2) ^ 2 + 4 * (-2) = 0 := by norm_num
-- The positive root of 1 - P^2 = 0 is P = 1.
example : (1 : ℝ) - 1 ^ 2 = 0 := by norm_num
-- Fixed gains from x₀ = 2, cost x₀^2 (1 + k^2) / (2k): gain 1 costs 4, gains 1/2 and 2 cost 5,
-- gain 1/4 costs 17/2 (the chart's 8.50).
example : (2 : ℚ) ^ 2 * (1 + 1 ^ 2) / (2 * 1) = 4 := by norm_num
example : (2 : ℚ) ^ 2 * (1 + (1 / 2) ^ 2) / (2 * (1 / 2)) = 5 := by norm_num
example : (2 : ℚ) ^ 2 * (1 + 2 ^ 2) / (2 * 2) = 5 := by norm_num
example : (2 : ℚ) ^ 2 * (1 + (1 / 4) ^ 2) / (2 * (1 / 4)) = 17 / 2 := by norm_num

#print axioms best_cost_is_square_and_best_push_is_minus_error
#print axioms hjb_quadratic_guess_gives_riccati
#print axioms riccati_with_deadline_solution_is_tanh
