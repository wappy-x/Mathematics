-- The Lebesgue differentiation theorem: for every locally integrable function on the line, almost every point is a Lebesgue point, so window averages shrinking to the point return the function's value there; with the Hardy-Littlewood maximal inequality and the slope of the running total.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.LebesgueDifferentiationThm
import Mathlib.MeasureTheory.Covering.OneDim
import Mathlib.MeasureTheory.Function.LocallyIntegrable
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory Filter Topology

lemma ldt_avg_eq (g : ℝ → ℝ) (x h : ℝ) (hh : 0 < h) :
    ⨍ y in Metric.closedBall x h, g y = (2 * h)⁻¹ * ∫ s in (x - h)..(x + h), g s := by
  rw [setAverage_eq, Real.volume_real_closedBall hh.le, smul_eq_mul,
    intervalIntegral.integral_of_le (by linarith), Real.closedBall_eq_Icc,
    integral_Icc_eq_integral_Ioc]

#print axioms ldt_avg_eq

/-- The Lebesgue differentiation theorem. Let f be a locally integrable function on the real
line (the integral of |f| over every bounded interval is finite). Then at almost every point x
(every point outside a set of length zero), as the half-width h > 0 shrinks to 0:
the average of |f(s) - f(x)| over the window from x - h to x + h tends to 0 (x is a Lebesgue
point), and the window average of f itself tends to f(x). -/
theorem lebesgue_differentiation_theorem (f : ℝ → ℝ) (hf : LocallyIntegrable f volume) :
    ∀ᵐ x ∂volume,
      Tendsto (fun h : ℝ => (2 * h)⁻¹ * ∫ s in (x - h)..(x + h), |f s - f x|)
          (𝓝[>] 0) (𝓝 0) ∧
      Tendsto (fun h : ℝ => (2 * h)⁻¹ * ∫ s in (x - h)..(x + h), f s)
          (𝓝[>] 0) (𝓝 (f x)) := by
  filter_upwards [IsUnifLocDoublingMeasure.ae_tendsto_average_norm_sub (μ := volume) hf 1,
    IsUnifLocDoublingMeasure.ae_tendsto_average (μ := volume) hf 1] with x h1 h2
  have xmem : ∀ᶠ j in 𝓝[>] (0:ℝ), x ∈ Metric.closedBall ((fun _ => x) j) (1 * id j) := by
    filter_upwards [self_mem_nhdsWithin] with j hj
    simpa using (le_of_lt (Set.mem_Ioi.1 hj))
  have hpos : ∀ᶠ j in 𝓝[>] (0:ℝ), 0 < j := self_mem_nhdsWithin
  constructor
  · refine (h1 (fun _ => x) id tendsto_id xmem).congr' ?_
    filter_upwards [hpos] with j hj
    simp only [id, Real.norm_eq_abs]
    exact ldt_avg_eq (fun y => |f y - f x|) x j hj
  · refine (h2 (fun _ => x) id tendsto_id xmem).congr' ?_
    filter_upwards [hpos] with j hj
    exact ldt_avg_eq f x j hj

/-- The Hardy-Littlewood maximal inequality. Let f be integrable on the real line and alpha > 0.
The maximal function Mf(x) is the largest window average of |f| at x, taken over all
half-widths h > 0 (a value in [0, infinity]). The length of the set where Mf beats alpha is at
most 3 / alpha times the total of |f|. -/
theorem hardy_littlewood_maximal_inequality (f : ℝ → ℝ) (hf : Integrable f volume)
    (α : ℝ) (hα : 0 < α) :
    volume {x : ℝ | ENNReal.ofReal α <
        ⨆ (h : ℝ) (_ : 0 < h), ENNReal.ofReal ((2 * h)⁻¹ * ∫ s in (x - h)..(x + h), |f s|)}
      ≤ ENNReal.ofReal (3 / α * ∫ s, |f s|) := by
  set S := {x : ℝ | ENNReal.ofReal α <
        ⨆ (h : ℝ) (_ : 0 < h), ENNReal.ofReal ((2 * h)⁻¹ * ∫ s in (x - h)..(x + h), |f s|)}
    with hS
  set I := ∫ s, |f s| with hI
  have hfa : Integrable (fun s => |f s|) volume := hf.abs
  have key : ∀ x ∈ S, ∃ h : ℝ, 0 < h ∧
      ENNReal.ofReal (2 * h) ≤ ENNReal.ofReal α⁻¹ *
        ∫⁻ s in Metric.closedBall x h, ENNReal.ofReal |f s| ∧ h ≤ I / α := by
    intro x hx
    simp only [S, Set.mem_ofPred_eq, lt_iSup_iff] at hx
    obtain ⟨h, hh, hlt⟩ := hx
    rw [ENNReal.ofReal_lt_ofReal_iff'] at hlt
    obtain ⟨hlt, -⟩ := hlt
    have hint : ∫ s in (x - h)..(x + h), |f s| = ∫ s in Metric.closedBall x h, |f s| := by
      rw [intervalIntegral.integral_of_le (by linarith), Real.closedBall_eq_Icc,
        integral_Icc_eq_integral_Ioc]
    rw [hint] at hlt
    set J := ∫ s in Metric.closedBall x h, |f s| with hJdef
    have h2 : 0 < 2 * h := by linarith
    have hJ : 2 * h * α < J := by
      rw [lt_inv_mul_iff₀ h2] at hlt
      linarith
    have hJI : J ≤ I := setIntegral_le_integral hfa (Eventually.of_forall fun _ => abs_nonneg _)
    refine ⟨h, hh, ?_, ?_⟩
    · rw [← ofReal_integral_eq_lintegral_ofReal hfa.integrableOn
        (Eventually.of_forall fun _ => abs_nonneg _), ← hJdef,
        ← ENNReal.ofReal_mul (inv_nonneg.2 hα.le)]
      apply ENNReal.ofReal_le_ofReal
      rw [le_inv_mul_iff₀ hα]
      linarith
    · rw [le_div_iff₀ hα]
      nlinarith
  choose! r hr0 hr hrI using key
  obtain ⟨u, huS, hdisj, hcov⟩ :=
    Vitali.exists_disjoint_subfamily_covering_enlargement (fun x => Metric.closedBall x (r x))
      S r 2 one_lt_two (fun a ha => (hr0 a ha).le) (I / α) hrI
      (fun a ha => ⟨a, Metric.mem_closedBall_self (hr0 a ha).le⟩)
  have hu : u.Countable := hdisj.countable_of_nonempty_interior fun a ha =>
    ⟨a, Metric.ball_subset_interior_closedBall (Metric.mem_ball_self (hr0 a (huS ha)))⟩
  have hcover : S ⊆ ⋃ b ∈ u, Metric.closedBall b (3 * r b) := by
    intro x hx
    obtain ⟨b, hbu, ⟨z, hz1, hz2⟩, hle⟩ := hcov x hx
    simp only [Set.mem_iUnion]
    refine ⟨b, hbu, ?_⟩
    rw [Metric.mem_closedBall] at hz1 hz2 ⊢
    have := dist_triangle x z b
    rw [dist_comm] at hz1
    linarith
  have : Countable u := hu.to_subtype
  calc volume S ≤ volume (⋃ b ∈ u, Metric.closedBall b (3 * r b)) := measure_mono hcover
    _ ≤ ∑' b : u, volume (Metric.closedBall (b : ℝ) (3 * r b)) := measure_biUnion_le _ hu _
    _ = ∑' b : u, 3 * ENNReal.ofReal (2 * r b) := by
        congr 1; ext b
        rw [Real.volume_closedBall, show 2 * (3 * r b) = 3 * (2 * r b) by ring,
          ENNReal.ofReal_mul (by norm_num), ENNReal.ofReal_ofNat]
    _ ≤ ∑' b : u, 3 * (ENNReal.ofReal α⁻¹ *
          ∫⁻ s in Metric.closedBall (b : ℝ) (r b), ENNReal.ofReal |f s|) := by
        gcongr with b
        exact hr b (huS b.2)
    _ = 3 * ENNReal.ofReal α⁻¹ *
          ∫⁻ s in ⋃ b : u, Metric.closedBall (b : ℝ) (r b), ENNReal.ofReal |f s| := by
        rw [lintegral_iUnion (fun b => measurableSet_closedBall) (hdisj.subtype _ _),
          ENNReal.tsum_mul_left, ENNReal.tsum_mul_left, mul_assoc]
    _ ≤ 3 * ENNReal.ofReal α⁻¹ * ∫⁻ s, ENNReal.ofReal |f s| := by
        exact mul_le_mul_right (setLIntegral_le_lintegral _ _) _
    _ = ENNReal.ofReal (3 / α * I) := by
        rw [← ofReal_integral_eq_lintegral_ofReal hfa
          (Eventually.of_forall fun _ => abs_nonneg _), ← hI,
          ← ENNReal.ofReal_ofNat 3, ← ENNReal.ofReal_mul (by norm_num),
          ← ENNReal.ofReal_mul (by positivity), div_eq_mul_inv]

/-- Integrating and then differentiating returns f almost everywhere. Let f be locally
integrable on the real line and F(x) the integral of f from 0 to x, the running total. Then at
almost every point x, F has derivative f(x). -/
theorem running_total_has_slope_ae (f : ℝ → ℝ) (hf : LocallyIntegrable f volume) :
    ∀ᵐ x ∂volume, HasDerivAt (fun y : ℝ => ∫ s in (0 : ℝ)..y, f s) (f x) x := by
  filter_upwards [LocallyIntegrable.ae_hasDerivAt_integral hf] with x hx using hx 0

-- The demand curve: f(t) = 2 + t^2/200 before minute 20, with running total F(t) = 2t + t^3/600.
-- Window averages at t = 10 are 5/2 + h^2/600: h = 4 (window 6 to 14), h = 2, h = 1.
example : ((2 * 14 + (14 : ℚ) ^ 3 / 600) - (2 * 6 + 6 ^ 3 / 600)) / 8 = 5 / 2 + 4 ^ 2 / 600 := by
  norm_num
example : ((2 * 12 + (12 : ℚ) ^ 3 / 600) - (2 * 8 + 8 ^ 3 / 600)) / 4 = 5 / 2 + 2 ^ 2 / 600 := by
  norm_num
example : ((2 * 11 + (11 : ℚ) ^ 3 / 600) - (2 * 9 + 9 ^ 3 / 600)) / 2 = 5 / 2 + 1 / 600 := by
  norm_num
-- Worked numbers by hand: the window from minute 19 to 21 around the jump at t = 20.
-- Energy 19 to 20 is 2 + (20^3 - 19^3)/600 = 2341/600; 20 to 21 is 5; the average is
-- 5341/1200, which is the closed form 9/2 - h/20 + h^2/1200 at h = 1.
example : (2 + ((20 : ℚ) ^ 3 - 19 ^ 3) / 600) = 2341 / 600 := by norm_num
example : ((2341 / 600 : ℚ) + 5) / 2 = 5341 / 1200 ∧
    (5341 / 1200 : ℚ) = 9 / 2 - 1 / 20 + 1 / 1200 := by norm_num
-- Slope of F just left of t = 20 with q = 1/1000: 4 - q/10 + q^2/600.
example : ((2 * 20 + (20 : ℚ) ^ 3 / 600) - (2 * (20 - 1 / 1000) + (20 - 1 / 1000) ^ 3 / 600))
    / (1 / 1000) = 4 - (1 / 1000) / 10 + (1 / 1000) ^ 2 / 600 := by norm_num
-- Vitali on the meter: chosen windows (20, 22.4) and (45, 49.9); three times their total
-- length is 21.9, inside the bound 3 ||g||_1 / alpha = 3 (3/2) / (1/5) = 22.5.
example : 3 * (((112 / 5 : ℚ) - 20) + ((499 / 10) - 45)) = 219 / 10 ∧
    (219 / 10 : ℚ) ≤ 3 * (3 / 2) / (1 / 5) ∧ 3 * (3 / 2 : ℚ) / (1 / 5) = 45 / 2 := by norm_num
-- Bad-set bound 4 ||g||_1 / alpha with ||g||_1 = 3 delta / 2 and alpha = 1/5:
-- 30 at delta = 1, 15/2 at 1/4, 15/8 at 1/16, 15/512 at 1/1024.
example : 4 * (3 / 2 : ℚ) / (1 / 5) = 30 ∧ 4 * (3 / 2 * (1 / 4) : ℚ) / (1 / 5) = 15 / 2 ∧
    4 * (3 / 2 * (1 / 16) : ℚ) / (1 / 5) = 15 / 8 ∧
    4 * (3 / 2 * (1 / 1024) : ℚ) / (1 / 5) = 15 / 512 := by norm_num
-- Block of height 1 on [0, 1]: Mf = 1/(2x) beyond 1, so Mf > 1/10 on a set of length
-- 1/(1/10) - 1 = 9, against the bound 3 / (1/10) = 30.
example : (1 / (1 / 10) : ℚ) - 1 = 9 ∧ (9 : ℚ) ≤ 3 / (1 / 10) ∧ (3 / (1 / 10) : ℚ) = 30 := by
  norm_num

#print axioms lebesgue_differentiation_theorem
#print axioms hardy_littlewood_maximal_inequality
#print axioms running_total_has_slope_ae
