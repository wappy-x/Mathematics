-- Diffusion smooths instantly, and is felt everywhere at once: for any bounded start on the line, the heat-kernel solution is smooth at every positive time with its k-th space derivative at most c_k M (κt)^(-k/2), where c_1 = 1/√π and c_2 = 2φ(1), and a start that is never negative and not zero warms every point at once.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory Real
open scoped ContDiff

/-- The heat kernel on the line with diffusivity `κ`:
`G(x, t) = (4πκt)^(-1/2) · e^(-x²/(4κt))`, the bell grown by time `t` from one unit of heat. -/
noncomputable def heatKernel (κ x t : ℝ) : ℝ :=
  exp (-x ^ 2 / (4 * κ * t)) / sqrt (4 * π * κ * t)

/-- The kernel's one fixed shape `F(v) = (4π)^(-1/2) · e^(-v²/4)`, read at `v = x/√(κt)`,
so that `G(x, t) = (κt)^(-1/2) F(x/√(κt))`. -/
noncomputable def kernelShape (v : ℝ) : ℝ :=
  exp (-v ^ 2 / 4) / sqrt (4 * π)

/-- The smoothing constant `c_k = ∫ |F⁽ᵏ⁾(v)| dv`, the total size of the shape's `k`-th
derivative. -/
noncomputable def smoothingConst (k : ℕ) : ℝ :=
  ∫ v, |iteratedDeriv k kernelShape v|

/-- The temperature on the endless line: the start `f` blended with the kernel,
`u(x, t) = ∫ G(x - y, t) f(y) dy`. -/
noncomputable def heatSolution (κ : ℝ) (f : ℝ → ℝ) (x t : ℝ) : ℝ :=
  ∫ y, heatKernel κ (x - y) t * f y

lemma one_add_sq_pow_mul_exp_le {c : ℝ} (hc : 0 < c) (N : ℕ) :
    ∃ K, ∀ z : ℝ, (1 + z ^ 2) ^ N * exp (-(c * z ^ 2)) ≤ K := by
  set L : ℝ := max 1 ((N + 1) / c)
  refine ⟨L ^ (N + 1), fun z => ?_⟩
  have hz : 0 ≤ z ^ 2 := sq_nonneg z
  have hN : (0:ℝ) < N + 1 := by positivity
  have hL1 : 1 ≤ L := le_max_left _ _
  have hL2 : (N + 1) / c ≤ L := le_max_right _ _
  set x : ℝ := c * z ^ 2 / (N + 1) with hx
  have hx0 : 0 ≤ x := by positivity
  have h1 : 1 + z ^ 2 ≤ L * (1 + x) := by
    have : z ^ 2 ≤ L * x := by
      calc z ^ 2 = ((N + 1) / c) * x := by rw [hx]; field_simp
        _ ≤ L * x := mul_le_mul_of_nonneg_right hL2 hx0
    nlinarith
  have h2 : (1 + x) ^ (N + 1) ≤ exp (c * z ^ 2) := by
    calc (1 + x) ^ (N + 1) ≤ exp x ^ (N + 1) :=
          pow_le_pow_left₀ (by positivity) (by linarith [add_one_le_exp x]) _
      _ = exp (c * z ^ 2) := by
          rw [← Real.exp_nat_mul]; congr 1; rw [hx]; push_cast; field_simp
  have h3 : (1 + z ^ 2) ^ N ≤ (1 + z ^ 2) ^ (N + 1) :=
    pow_le_pow_right₀ (by linarith) (by omega)
  have h4 : (1 + z ^ 2) ^ (N + 1) ≤ L ^ (N + 1) * (1 + x) ^ (N + 1) := by
    rw [← mul_pow]; exact pow_le_pow_left₀ (by positivity) h1 _
  have hpos : 0 < exp (-(c * z ^ 2)) := exp_pos _
  calc (1 + z ^ 2) ^ N * exp (-(c * z ^ 2))
      ≤ L ^ (N + 1) * exp (c * z ^ 2) * exp (-(c * z ^ 2)) := by
        apply mul_le_mul_of_nonneg_right _ hpos.le
        calc (1 + z ^ 2) ^ N ≤ L ^ (N + 1) * (1 + x) ^ (N + 1) := h3.trans h4
          _ ≤ L ^ (N + 1) * exp (c * z ^ 2) :=
            mul_le_mul_of_nonneg_left h2 (by positivity)
    _ = L ^ (N + 1) := by rw [mul_assoc, ← Real.exp_add]; simp

lemma inv_one_add_sq_le (u w : ℝ) (h : |w - u| < 1) :
    (1 + u ^ 2)⁻¹ ≤ 4 * (1 + w ^ 2)⁻¹ := by
  have hd : (w - u) ^ 2 < 1 := by
    have := sq_abs (w - u); nlinarith [abs_nonneg (w - u)]
  have key : 1 + w ^ 2 ≤ 4 * (1 + u ^ 2) := by nlinarith [sq_nonneg (w - 2 * u)]
  rw [← div_eq_mul_inv, le_div_iff₀ (by positivity), inv_mul_le_iff₀ (by positivity)]
  linarith

lemma poly_eval_abs_le (p : Polynomial ℝ) :
    ∃ S, 0 ≤ S ∧ ∀ w : ℝ, |p.eval w| ≤ S * (1 + w ^ 2) ^ p.natDegree := by
  refine ⟨∑ i ∈ Finset.range (p.natDegree + 1), |p.coeff i|,
    Finset.sum_nonneg fun i _ => abs_nonneg _, fun w => ?_⟩
  rw [Polynomial.eval_eq_sum_range, Finset.sum_mul]
  refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun i hi => ?_)
  rw [abs_mul, abs_pow]
  apply mul_le_mul_of_nonneg_left _ (abs_nonneg _)
  have h1 : |w| ≤ 1 + w ^ 2 := by nlinarith [abs_nonneg w, sq_abs w, sq_nonneg (|w| - 1)]
  calc |w| ^ i ≤ (1 + w ^ 2) ^ i := pow_le_pow_left₀ (abs_nonneg _) h1 i
    _ ≤ (1 + w ^ 2) ^ p.natDegree :=
      pow_le_pow_right₀ (by nlinarith) (by simp at hi; omega)

lemma kernelShape_hasDerivAt (w : ℝ) :
    HasDerivAt kernelShape (kernelShape w * (-w / 2)) w := by
  have h1 : HasDerivAt (fun v : ℝ => -v ^ 2 / 4) (-(2 * w) / 4) w := by
    have := ((hasDerivAt_pow 2 w).neg).div_const 4
    convert this using 1; simp
  have h2 := (h1.exp).div_const (sqrt (4 * π))
  unfold kernelShape
  convert h2 using 1
  ring

lemma kernelShape_contDiff : ContDiff ℝ ∞ kernelShape := by
  unfold kernelShape; fun_prop

lemma kernelShape_iteratedDeriv_poly (k : ℕ) :
    ∃ p : Polynomial ℝ, ∀ w, iteratedDeriv k kernelShape w = p.eval w * kernelShape w := by
  induction k with
  | zero => exact ⟨1, fun w => by simp⟩
  | succ k ih =>
    obtain ⟨p, hp⟩ := ih
    refine ⟨Polynomial.derivative p - Polynomial.C (1 / 2) * Polynomial.X * p, fun w => ?_⟩
    have hfun : iteratedDeriv k kernelShape = fun w => p.eval w * kernelShape w := funext hp
    rw [iteratedDeriv_succ, hfun]
    have : HasDerivAt (fun w => p.eval w * kernelShape w) _ w :=
      (p.hasDerivAt w).mul (kernelShape_hasDerivAt w)
    rw [this.deriv]
    simp; ring

lemma kernelShape_iteratedDeriv_decay (k : ℕ) :
    ∃ C, 0 ≤ C ∧ ∀ w, |iteratedDeriv k kernelShape w| ≤ C * (1 + w ^ 2)⁻¹ := by
  obtain ⟨p, hp⟩ := kernelShape_iteratedDeriv_poly k
  obtain ⟨S, hS0, hS⟩ := poly_eval_abs_le p
  obtain ⟨K, hK⟩ := one_add_sq_pow_mul_exp_le (c := 1 / 4) (by norm_num) (p.natDegree + 1)
  have hK0 : 0 ≤ K := (by positivity : (0:ℝ) ≤ (1 + 0 ^ 2) ^ (p.natDegree + 1) * exp (-(1/4 * 0 ^ 2)))
    |>.trans (hK 0)
  have hs : 0 < sqrt (4 * π) := sqrt_pos.2 (by positivity)
  refine ⟨S * K / sqrt (4 * π), by positivity, fun w => ?_⟩
  have hw : 0 < 1 + w ^ 2 := by positivity
  rw [hp, ← div_eq_mul_inv, le_div_iff₀ hw]
  have hF : kernelShape w = exp (-(1 / 4 * w ^ 2)) / sqrt (4 * π) := by
    unfold kernelShape; congr 2; ring
  rw [abs_mul, hF, abs_of_pos (by positivity : 0 < exp (-(1 / 4 * w ^ 2)) / sqrt (4 * π))]
  calc |p.eval w| * (exp (-(1 / 4 * w ^ 2)) / sqrt (4 * π)) * (1 + w ^ 2)
      ≤ S * (1 + w ^ 2) ^ p.natDegree * (exp (-(1 / 4 * w ^ 2)) / sqrt (4 * π)) * (1 + w ^ 2) := by
        gcongr; exact hS w
    _ = S * ((1 + w ^ 2) ^ (p.natDegree + 1) * exp (-(1 / 4 * w ^ 2))) / sqrt (4 * π) := by
        rw [pow_succ]; ring
    _ ≤ S * K / sqrt (4 * π) := by gcongr; exact hK w

lemma integrable_const_mul_inv_one_add_sq (C r : ℝ) (hr : r ≠ 0) :
    Integrable (fun z : ℝ => C * (1 + (z / r) ^ 2)⁻¹) :=
  (integrable_inv_one_add_sq.comp_div hr).const_mul C

lemma kernelShape_iteratedDeriv_continuous (k : ℕ) : Continuous (iteratedDeriv k kernelShape) :=
  kernelShape_contDiff.continuous_iteratedDeriv k (by exact_mod_cast le_top)

lemma kernelShape_iteratedDeriv_integrable (k : ℕ) : Integrable (iteratedDeriv k kernelShape) := by
  obtain ⟨C, _, hC⟩ := kernelShape_iteratedDeriv_decay k
  refine Integrable.mono' ((integrable_const_mul_inv_one_add_sq C 1 one_ne_zero))
    (kernelShape_iteratedDeriv_continuous k).aestronglyMeasurable (Filter.Eventually.of_forall
      fun w => ?_)
  simpa using hC w

lemma iteratedDeriv_kernelShape_hasDerivAt (k : ℕ) (w : ℝ) :
    HasDerivAt (iteratedDeriv k kernelShape) (iteratedDeriv (k + 1) kernelShape w) w := by
  rw [iteratedDeriv_succ]
  exact ((kernelShape_contDiff.differentiable_iteratedDeriv k
    (by exact_mod_cast ENat.natCast_lt_top k)) w).hasDerivAt

noncomputable def gk (r : ℝ) (k : ℕ) (z : ℝ) : ℝ :=
  (r⁻¹) ^ (k + 1) * iteratedDeriv k kernelShape (z / r)

lemma gk_hasDerivAt (r : ℝ) (k : ℕ) (z : ℝ) : HasDerivAt (gk r k) (gk r (k + 1) z) z := by
  have h := (iteratedDeriv_kernelShape_hasDerivAt k (z / r)).comp z ((hasDerivAt_id z).div_const r)
  have := h.const_mul ((r⁻¹) ^ (k + 1))
  unfold gk
  convert this using 1
  simp only [Function.comp_def, id]
  ring

lemma gk_continuous (r : ℝ) (k : ℕ) : Continuous (gk r k) := by
  unfold gk
  exact continuous_const.mul ((kernelShape_iteratedDeriv_continuous k).comp
    (continuous_id.div_const r))

lemma gk_decay (r : ℝ) (k : ℕ) :
    ∃ C, 0 ≤ C ∧ ∀ z, |gk r k z| ≤ C * (1 + (z / r) ^ 2)⁻¹ := by
  obtain ⟨C, hC0, hC⟩ := kernelShape_iteratedDeriv_decay k
  refine ⟨|r⁻¹| ^ (k + 1) * C, by positivity, fun z => ?_⟩
  unfold gk
  rw [abs_mul, abs_pow, mul_assoc]
  exact mul_le_mul_of_nonneg_left (hC _) (by positivity)

lemma gk_abs_integral (hr : 0 < r) (k : ℕ) :
    ∫ z, |gk r k z| = (r⁻¹) ^ k * smoothingConst k := by
  unfold gk smoothingConst
  simp_rw [abs_mul, abs_pow, abs_inv, abs_of_pos hr]
  rw [integral_const_mul, Measure.integral_comp_div (fun v => |iteratedDeriv k kernelShape v|) r,
    abs_of_pos hr, smul_eq_mul, pow_succ]
  field_simp

lemma conv_hasDerivAt {f : ℝ → ℝ} {M r : ℝ} (hr : 0 < r) (hf : AEStronglyMeasurable f volume)
    (hM : ∀ y, |f y| ≤ M) (k : ℕ) (x0 : ℝ) :
    HasDerivAt (fun x => ∫ y, gk r k (x - y) * f y) (∫ y, gk r (k + 1) (x0 - y) * f y) x0 := by
  obtain ⟨C, hC0, hC⟩ := gk_decay r (k + 1)
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  have hmeas : ∀ (j : ℕ) (x : ℝ), AEStronglyMeasurable (fun y => gk r j (x - y) * f y) volume :=
    fun j x => ((gk_continuous r j).comp (continuous_const.sub continuous_id)).aestronglyMeasurable.mul hf
  have hint : ∀ (j : ℕ) (x : ℝ), Integrable (fun y => gk r j (x - y) * f y) := by
    intro j x
    obtain ⟨D, hD0, hD⟩ := gk_decay r j
    refine Integrable.mono' (((integrable_const_mul_inv_one_add_sq (D * M) r hr.ne').comp_sub_left x))
      (hmeas j x) (Filter.Eventually.of_forall fun y => ?_)
    rw [Real.norm_eq_abs, abs_mul, mul_assoc, mul_comm M, ← mul_assoc]
    exact mul_le_mul (hD _) (hM y) (abs_nonneg _) (by positivity)
  refine (hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun x y => gk r k (x - y) * f y) (F' := fun x y => gk r (k + 1) (x - y) * f y)
    (bound := fun y => (4 * C * M) * (1 + ((x0 - y) / r) ^ 2)⁻¹)
    (Metric.ball_mem_nhds x0 hr) (Filter.Eventually.of_forall fun x => hmeas k x) (hint k x0)
    (hmeas (k + 1) x0) (Filter.Eventually.of_forall fun y x hx => ?_)
    ((integrable_const_mul_inv_one_add_sq (4 * C * M) r hr.ne').comp_sub_left x0)
    (Filter.Eventually.of_forall fun y x _ => ?_)).2
  · rw [Real.norm_eq_abs, abs_mul]
    have h1 : (1 + ((x - y) / r) ^ 2)⁻¹ ≤ 4 * (1 + ((x0 - y) / r) ^ 2)⁻¹ := by
      apply inv_one_add_sq_le
      rw [Metric.mem_ball, Real.dist_eq] at hx
      rw [← sub_div, abs_div, abs_of_pos hr, div_lt_one hr]
      rw [abs_sub_comm]; convert hx using 2; ring
    calc |gk r (k + 1) (x - y)| * |f y| ≤ (C * (1 + ((x - y) / r) ^ 2)⁻¹) * M :=
          mul_le_mul (hC _) (hM y) (abs_nonneg _) (by positivity)
      _ ≤ (C * (4 * (1 + ((x0 - y) / r) ^ 2)⁻¹)) * M := by gcongr
      _ = _ := by ring
  · have := ((gk_hasDerivAt r k (x - y)).comp x ((hasDerivAt_id x).sub_const y)).mul_const (f y)
    rw [mul_one] at this; exact this

lemma conv_iteratedDeriv {f : ℝ → ℝ} {M r : ℝ} (hr : 0 < r) (hf : AEStronglyMeasurable f volume)
    (hM : ∀ y, |f y| ≤ M) (k : ℕ) :
    iteratedDeriv k (fun x => ∫ y, gk r 0 (x - y) * f y) = fun x => ∫ y, gk r k (x - y) * f y := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [iteratedDeriv_succ, ih]
    funext x0
    exact (conv_hasDerivAt hr hf hM k x0).deriv

lemma conv_bound {f : ℝ → ℝ} {M r : ℝ} (hr : 0 < r)
    (hM : ∀ y, |f y| ≤ M) (k : ℕ) (x : ℝ) :
    |∫ y, gk r k (x - y) * f y| ≤ smoothingConst k * M * (r⁻¹) ^ k := by
  obtain ⟨D, hD0, hD⟩ := gk_decay r k
  have hgi : Integrable (gk r k) :=
    Integrable.mono' (integrable_const_mul_inv_one_add_sq D r hr.ne')
      (gk_continuous r k).aestronglyMeasurable (Filter.Eventually.of_forall fun z => hD z)
  have hgi' : Integrable (fun y => |gk r k (x - y)| * M) :=
    (hgi.abs.comp_sub_left x).mul_const M
  calc |∫ y, gk r k (x - y) * f y| ≤ ∫ y, |gk r k (x - y)| * M := by
        rw [← Real.norm_eq_abs]
        refine norm_integral_le_of_norm_le hgi' (Filter.Eventually.of_forall fun y => ?_)
        rw [Real.norm_eq_abs, abs_mul]
        exact mul_le_mul_of_nonneg_left (hM y) (abs_nonneg _)
    _ = (∫ y, |gk r k y|) * M := by
        rw [integral_mul_const, integral_sub_left_eq_self (fun z => |gk r k z|) volume x]
    _ = smoothingConst k * M * (r⁻¹) ^ k := by rw [gk_abs_integral hr]; ring

noncomputable def mono (κ : ℝ) (a b : ℕ) (q : ℝ × ℝ) : ℝ :=
  q.1 ^ a * exp (-(b : ℝ) * q.2 / 2 - q.1 ^ 2 * exp (-q.2) / (4 * κ))

noncomputable def monoD (κ : ℝ) (a b : ℕ) (q : ℝ × ℝ) : ℝ × ℝ →L[ℝ] ℝ :=
  ((a : ℝ) * mono κ (a - 1) b q - 1 / (2 * κ) * mono κ (a + 1) (b + 2) q) •
      ContinuousLinearMap.fst ℝ ℝ ℝ +
    (-((b : ℝ) / 2) * mono κ a b q + 1 / (4 * κ) * mono κ (a + 2) (b + 2) q) •
      ContinuousLinearMap.snd ℝ ℝ ℝ

lemma mono_continuous (κ : ℝ) (a b : ℕ) : Continuous (mono κ a b) := by
  unfold mono; fun_prop

lemma monoD_continuous (κ : ℝ) (a b : ℕ) : Continuous (monoD κ a b) := by
  unfold monoD
  exact ((continuous_const.mul (mono_continuous κ _ _)).sub
    (continuous_const.mul (mono_continuous κ _ _))).smul continuous_const |>.add
    (((continuous_const.mul (mono_continuous κ _ _)).add
    (continuous_const.mul (mono_continuous κ _ _))).smul continuous_const)

lemma mono_shift (κ : ℝ) (a b : ℕ) (q : ℝ × ℝ) :
    mono κ (a + 1) (b + 2) q = q.1 * exp (-q.2) * mono κ a b q ∧
      mono κ (a + 2) (b + 2) q = q.1 ^ 2 * exp (-q.2) * mono κ a b q := by
  unfold mono
  have : exp (-((b + 2 : ℕ) : ℝ) * q.2 / 2 - q.1 ^ 2 * exp (-q.2) / (4 * κ)) =
      exp (-q.2) * exp (-(b : ℝ) * q.2 / 2 - q.1 ^ 2 * exp (-q.2) / (4 * κ)) := by
    rw [← Real.exp_add]; congr 1; push_cast; ring
  rw [this]
  constructor <;> ring

lemma mono_hasFDerivAt (κ : ℝ) (a b : ℕ) (q : ℝ × ℝ) :
    HasFDerivAt (mono κ a b) (monoD κ a b q) q := by
  have h1 : HasFDerivAt (fun q : ℝ × ℝ => q.1) (ContinuousLinearMap.fst ℝ ℝ ℝ) q := hasFDerivAt_fst
  have h2 : HasFDerivAt (fun q : ℝ × ℝ => q.2) (ContinuousLinearMap.snd ℝ ℝ ℝ) q := hasFDerivAt_snd
  have hE := (h2.const_mul (-(b : ℝ) / 2)).add
    (((h1.pow 2).mul (h2.neg.exp)).const_mul (-1 / (4 * κ)))
  have := (h1.pow a).mul hE.exp
  have hfun : mono κ a b = fun q : ℝ × ℝ =>
      q.1 ^ a * exp (-(b : ℝ) / 2 * q.2 + -1 / (4 * κ) * (q.1 ^ 2 * exp (-q.2))) := by
    funext q; unfold mono; congr 2; ring
  rw [hfun]
  refine this.congr_fderiv ?_
  obtain ⟨hs1, hs2⟩ := mono_shift κ a b q
  rw [monoD, hs1, hs2]
  have hE' : -((b : ℝ) * q.2) / 2 - q.1 ^ 2 * exp (-q.2) / (4 * κ) =
      -(b : ℝ) / 2 * q.2 + -1 / (4 * κ) * (q.1 ^ 2 * exp (-q.2)) := by ring
  ext
  · simp [mono]; rw [hE']; ring
  · simp [mono]; rw [hE']; ring

lemma inv_one_add_sq_ball {p p0 : ℝ × ℝ} (hp : p ∈ Metric.ball p0 1) (y : ℝ) :
    (1 + (p.1 - y) ^ 2)⁻¹ ≤ 4 * (1 + (p0.1 - y) ^ 2)⁻¹ := by
  apply inv_one_add_sq_le
  rw [Metric.mem_ball, Prod.dist_eq] at hp
  have := (le_max_left _ _).trans_lt hp
  rw [Real.dist_eq] at this
  rw [abs_sub_comm]; convert this using 2; ring

lemma mono_dom {κ : ℝ} (hκ : 0 < κ) (a b : ℕ) (p0 : ℝ × ℝ) :
    ∃ C, 0 ≤ C ∧ ∀ p ∈ Metric.ball p0 1, ∀ y : ℝ,
      |mono κ a b (p - (y, 0))| ≤ C * (1 + (p0.1 - y) ^ 2)⁻¹ := by
  set c : ℝ := exp (-(p0.2 + 1)) / (4 * κ) with hc
  have hc0 : 0 < c := by positivity
  obtain ⟨K, hK⟩ := one_add_sq_pow_mul_exp_le hc0 (a + 1)
  have hK0 : 0 ≤ K := (by positivity : (0:ℝ) ≤ (1 + 0 ^ 2) ^ (a + 1) * exp (-(c * 0 ^ 2)))
    |>.trans (hK 0)
  set B : ℝ := exp (-(b : ℝ) * (p0.2 - 1) / 2)
  refine ⟨4 * (B * K), by positivity, fun p hp y => ?_⟩
  have hp2 : |p.2 - p0.2| < 1 := by
    rw [Metric.mem_ball, Prod.dist_eq] at hp
    have := (le_max_right _ _).trans_lt hp
    rwa [Real.dist_eq] at this
  set z := p.1 - y
  have hq : p - (y, 0) = (z, p.2) := by ext <;> simp [z]
  rw [hq]
  unfold mono
  simp only
  have hz : 0 < 1 + z ^ 2 := by positivity
  have hexp : -(b : ℝ) * p.2 / 2 - z ^ 2 * exp (-p.2) / (4 * κ) ≤
      -(b : ℝ) * (p0.2 - 1) / 2 + -(c * z ^ 2) := by
    have e1 : -(b : ℝ) * p.2 / 2 ≤ -(b : ℝ) * (p0.2 - 1) / 2 := by
      have : p0.2 - 1 ≤ p.2 := by linarith [(abs_lt.1 hp2).1]
      have hb : (0:ℝ) ≤ b := by positivity
      nlinarith
    have e2 : c * z ^ 2 ≤ z ^ 2 * exp (-p.2) / (4 * κ) := by
      rw [hc, div_mul_eq_mul_div, mul_comm]
      apply div_le_div_of_nonneg_right _ (by positivity)
      apply mul_le_mul_of_nonneg_left _ (sq_nonneg z)
      apply Real.exp_le_exp.2
      linarith [(abs_lt.1 hp2).2]
    linarith
  have habs : |z| ^ a ≤ (1 + z ^ 2) ^ a :=
    pow_le_pow_left₀ (abs_nonneg _) (by nlinarith [abs_nonneg z, sq_abs z, sq_nonneg (|z| - 1)]) a
  rw [abs_mul, abs_pow, abs_of_pos (exp_pos _)]
  have step1 : |z| ^ a * exp (-(b : ℝ) * p.2 / 2 - z ^ 2 * exp (-p.2) / (4 * κ)) ≤
      B * K * (1 + z ^ 2)⁻¹ := by
    rw [← div_eq_mul_inv, le_div_iff₀ hz]
    calc |z| ^ a * exp (-(b : ℝ) * p.2 / 2 - z ^ 2 * exp (-p.2) / (4 * κ)) * (1 + z ^ 2)
        ≤ (1 + z ^ 2) ^ a * exp (-(b : ℝ) * (p0.2 - 1) / 2 + -(c * z ^ 2)) * (1 + z ^ 2) := by
          gcongr
      _ = B * ((1 + z ^ 2) ^ (a + 1) * exp (-(c * z ^ 2))) := by
          rw [Real.exp_add, pow_succ]; ring
      _ ≤ B * K := by gcongr; exact hK z
  calc _ ≤ B * K * (1 + z ^ 2)⁻¹ := step1
    _ ≤ B * K * (4 * (1 + (p0.1 - y) ^ 2)⁻¹) := by
        gcongr; exact inv_one_add_sq_ball hp y
    _ = _ := by ring

noncomputable def Vint (κ : ℝ) (f : ℝ → ℝ) (a b : ℕ) (p : ℝ × ℝ) : ℝ :=
  ∫ y, mono κ a b (p - (y, 0)) * f y

lemma mono_shift_continuous (κ : ℝ) (a b : ℕ) (p : ℝ × ℝ) :
    Continuous (fun y : ℝ => mono κ a b (p - (y, 0))) :=
  (mono_continuous κ a b).comp (continuous_const.sub (continuous_id.prodMk continuous_const))

lemma Vint_integrable {κ M : ℝ} (hκ : 0 < κ) {f : ℝ → ℝ} (hf : AEStronglyMeasurable f volume)
    (hM : ∀ y, |f y| ≤ M) (a b : ℕ) (p : ℝ × ℝ) :
    Integrable (fun y => mono κ a b (p - (y, 0)) * f y) := by
  obtain ⟨C, hC0, hC⟩ := mono_dom hκ a b p
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  refine Integrable.mono' ((integrable_const_mul_inv_one_add_sq (C * M) 1 one_ne_zero).comp_sub_left p.1)
    ((mono_shift_continuous κ a b p).aestronglyMeasurable.mul hf)
    (Filter.Eventually.of_forall fun y => ?_)
  rw [Real.norm_eq_abs, abs_mul, div_one, mul_assoc, mul_comm M, ← mul_assoc]
  exact mul_le_mul (hC p (Metric.mem_ball_self one_pos) y) (hM y) (abs_nonneg _) (by positivity)

lemma monoD_dom {κ : ℝ} (hκ : 0 < κ) (a b : ℕ) (p0 : ℝ × ℝ) :
    ∃ D, 0 ≤ D ∧ ∀ p ∈ Metric.ball p0 1, ∀ y : ℝ,
      ‖monoD κ a b (p - (y, 0))‖ ≤ D * (1 + (p0.1 - y) ^ 2)⁻¹ := by
  obtain ⟨C1, hC1, h1⟩ := mono_dom hκ (a - 1) b p0
  obtain ⟨C2, hC2, h2⟩ := mono_dom hκ (a + 1) (b + 2) p0
  obtain ⟨C3, hC3, h3⟩ := mono_dom hκ a b p0
  obtain ⟨C4, hC4, h4⟩ := mono_dom hκ (a + 2) (b + 2) p0
  refine ⟨(a : ℝ) * C1 + 1 / (2 * κ) * C2 + (b : ℝ) / 2 * C3 + 1 / (4 * κ) * C4,
    by positivity, fun p hp y => ?_⟩
  have hb1 := h1 p hp y
  have hb2 := h2 p hp y
  have hb3 := h3 p hp y
  have hb4 := h4 p hp y
  set w := (1 + (p0.1 - y) ^ 2)⁻¹
  have hw : 0 ≤ w := by positivity
  set m1 := mono κ (a - 1) b (p - (y, 0))
  set m2 := mono κ (a + 1) (b + 2) (p - (y, 0))
  set m3 := mono κ a b (p - (y, 0))
  set m4 := mono κ (a + 2) (b + 2) (p - (y, 0))
  rw [monoD]
  refine (norm_add_le _ _).trans ?_
  rw [norm_smul, norm_smul, Real.norm_eq_abs, Real.norm_eq_abs]
  have hf1 := ContinuousLinearMap.norm_fst_le ℝ ℝ ℝ
  have hs1 := ContinuousLinearMap.norm_snd_le ℝ ℝ ℝ
  have ha1 : |(a : ℝ) * m1 - 1 / (2 * κ) * m2| ≤ (a : ℝ) * (C1 * w) + 1 / (2 * κ) * (C2 * w) := by
    refine (abs_sub _ _).trans ?_
    rw [abs_mul, abs_mul, Nat.abs_cast, abs_of_pos (by positivity : (0:ℝ) < 1 / (2 * κ))]
    gcongr
  have ha2 : |-((b : ℝ) / 2) * m3 + 1 / (4 * κ) * m4| ≤
      (b : ℝ) / 2 * (C3 * w) + 1 / (4 * κ) * (C4 * w) := by
    refine (abs_add_le _ _).trans ?_
    rw [abs_mul, abs_mul, abs_neg, abs_of_nonneg (by positivity : (0:ℝ) ≤ (b : ℝ) / 2),
      abs_of_pos (by positivity : (0:ℝ) < 1 / (4 * κ))]
    gcongr
  calc _ ≤ ((a : ℝ) * (C1 * w) + 1 / (2 * κ) * (C2 * w)) * 1 +
        ((b : ℝ) / 2 * (C3 * w) + 1 / (4 * κ) * (C4 * w)) * 1 := by
        gcongr
    _ = _ := by ring

lemma Vint_fderiv_integral {κ M : ℝ} (hκ : 0 < κ) {f : ℝ → ℝ} (hf : AEStronglyMeasurable f volume)
    (hM : ∀ y, |f y| ≤ M) (a b : ℕ) (p0 : ℝ × ℝ) :
    ∫ y, f y • monoD κ a b (p0 - (y, 0)) =
      ((a : ℝ) * Vint κ f (a - 1) b p0 - 1 / (2 * κ) * Vint κ f (a + 1) (b + 2) p0) •
          ContinuousLinearMap.fst ℝ ℝ ℝ +
        (-((b : ℝ) / 2) * Vint κ f a b p0 + 1 / (4 * κ) * Vint κ f (a + 2) (b + 2) p0) •
          ContinuousLinearMap.snd ℝ ℝ ℝ := by
  have hint := Vint_integrable hκ hf hM
  have e : (fun y => f y • monoD κ a b (p0 - (y, 0))) = fun y =>
      ((a : ℝ) * (mono κ (a - 1) b (p0 - (y, 0)) * f y) -
          1 / (2 * κ) * (mono κ (a + 1) (b + 2) (p0 - (y, 0)) * f y)) •
        ContinuousLinearMap.fst ℝ ℝ ℝ +
      (-((b : ℝ) / 2) * (mono κ a b (p0 - (y, 0)) * f y) +
          1 / (4 * κ) * (mono κ (a + 2) (b + 2) (p0 - (y, 0)) * f y)) •
        ContinuousLinearMap.snd ℝ ℝ ℝ := by
    funext y
    rw [monoD, smul_add, smul_smul, smul_smul]
    congr 2 <;> ring
  rw [e, integral_add, integral_smul_const, integral_smul_const, integral_sub, integral_add,
    integral_const_mul, integral_const_mul, integral_const_mul, integral_const_mul]
  · rfl
  · exact ((hint _ _ _).const_mul _)
  · exact ((hint _ _ _).const_mul _)
  · exact ((hint _ _ _).const_mul _)
  · exact ((hint _ _ _).const_mul _)
  · exact (((hint _ _ _).const_mul _).sub ((hint _ _ _).const_mul _)).smul_const _
  · exact (((hint _ _ _).const_mul _).add ((hint _ _ _).const_mul _)).smul_const _

lemma Vint_hasFDerivAt {κ M : ℝ} (hκ : 0 < κ) {f : ℝ → ℝ} (hf : AEStronglyMeasurable f volume)
    (hM : ∀ y, |f y| ≤ M) (a b : ℕ) (p0 : ℝ × ℝ) :
    HasFDerivAt (Vint κ f a b)
      (((a : ℝ) * Vint κ f (a - 1) b p0 - 1 / (2 * κ) * Vint κ f (a + 1) (b + 2) p0) •
          ContinuousLinearMap.fst ℝ ℝ ℝ +
        (-((b : ℝ) / 2) * Vint κ f a b p0 + 1 / (4 * κ) * Vint κ f (a + 2) (b + 2) p0) •
          ContinuousLinearMap.snd ℝ ℝ ℝ) p0 := by
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  obtain ⟨D, hD, hDb⟩ := monoD_dom hκ a b p0
  rw [← Vint_fderiv_integral hκ hf hM a b p0]
  exact hasFDerivAt_integral_of_dominated_of_fderiv_le (μ := volume)
    (F := fun p y => mono κ a b (p - (y, 0)) * f y)
    (F' := fun p y => f y • monoD κ a b (p - (y, 0)))
    (bound := fun y => (M * D) * (1 + (p0.1 - y) ^ 2)⁻¹)
    (Metric.ball_mem_nhds p0 one_pos)
    (Filter.Eventually.of_forall fun p =>
      (mono_shift_continuous κ a b p).aestronglyMeasurable.mul hf)
    (Vint_integrable hκ hf hM a b p0)
    (hf.smul ((monoD_continuous κ a b).comp
      (continuous_const.sub (continuous_id.prodMk continuous_const))).aestronglyMeasurable)
    (Filter.Eventually.of_forall fun y p hp => by
      rw [norm_smul, Real.norm_eq_abs, mul_assoc]
      exact mul_le_mul (hM y) (hDb p hp y) (norm_nonneg _) hM0)
    (by simpa using
      (integrable_const_mul_inv_one_add_sq (M * D) 1 one_ne_zero).comp_sub_left p0.1)
    (Filter.Eventually.of_forall fun y p _ => by
      have := ((mono_hasFDerivAt κ a b (p - (y, 0))).comp p
        ((hasFDerivAt_id p).sub_const (y, 0))).mul_const (f y)
      simpa using this)

lemma Vint_contDiff {κ M : ℝ} (hκ : 0 < κ) {f : ℝ → ℝ} (hf : AEStronglyMeasurable f volume)
    (hM : ∀ y, |f y| ≤ M) (n : ℕ) : ∀ a b : ℕ, ContDiff ℝ n (Vint κ f a b) := by
  induction n with
  | zero =>
    intro a b
    exact contDiff_zero.2 (continuous_iff_continuousAt.2 fun p =>
      (Vint_hasFDerivAt hκ hf hM a b p).continuousAt)
  | succ n ih =>
    intro a b
    rw [show ((n + 1 : ℕ) : ℕ∞ω) = (n : ℕ∞ω) + 1 by push_cast; rfl, contDiff_succ_iff_fderiv]
    refine ⟨fun p => (Vint_hasFDerivAt hκ hf hM a b p).differentiableAt, fun h => ?_, ?_⟩
    · exact absurd h (by simp)
    · have e : fderiv ℝ (Vint κ f a b) = fun p =>
          ((a : ℝ) * Vint κ f (a - 1) b p - 1 / (2 * κ) * Vint κ f (a + 1) (b + 2) p) •
              ContinuousLinearMap.fst ℝ ℝ ℝ +
            (-((b : ℝ) / 2) * Vint κ f a b p + 1 / (4 * κ) * Vint κ f (a + 2) (b + 2) p) •
              ContinuousLinearMap.snd ℝ ℝ ℝ :=
        funext fun p => (Vint_hasFDerivAt hκ hf hM a b p).fderiv
      rw [e]
      exact (((contDiff_const.mul (ih _ _)).sub (contDiff_const.mul (ih _ _))).smul
        contDiff_const).add (((contDiff_const.mul (ih _ _)).add
          (contDiff_const.mul (ih _ _))).smul contDiff_const)

lemma heatKernel_pos {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (z : ℝ) : 0 < heatKernel κ z t := by
  unfold heatKernel; positivity

lemma heatKernel_continuous (κ t x : ℝ) : Continuous (fun y => heatKernel κ (x - y) t) := by
  unfold heatKernel; fun_prop

lemma heatKernel_integrable {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (x : ℝ) :
    Integrable (fun y => heatKernel κ (x - y) t) := by
  have := ((integrable_exp_neg_mul_sq (b := 1 / (4 * κ * t)) (by positivity)).div_const
    (sqrt (4 * π * κ * t))).comp_sub_left x
  refine this.congr (Filter.Eventually.of_forall fun y => ?_)
  simp only [heatKernel]
  congr 2
  field_simp

lemma heatKernel_eq_gk {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (z : ℝ) :
    heatKernel κ z t = gk (sqrt (κ * t)) 0 z := by
  have hs : sqrt (4 * π * κ * t) = sqrt (4 * π) * sqrt (κ * t) := by
    rw [← sqrt_mul (by positivity)]; ring_nf
  have hr : 0 < sqrt (κ * t) := sqrt_pos.2 (by positivity)
  unfold gk heatKernel kernelShape
  simp only [iteratedDeriv_zero, zero_add, pow_one]
  rw [hs, div_pow, sq_sqrt (by positivity)]
  have : -(z ^ 2 / (κ * t)) / 4 = -z ^ 2 / (4 * κ * t) := by field_simp
  rw [this]
  field_simp

lemma heatSolution_eq_Vint {κ t : ℝ} (hκ : 0 < κ) (f : ℝ → ℝ) (x : ℝ) (ht : 0 < t) :
    heatSolution κ f x t = (sqrt (4 * π * κ))⁻¹ * Vint κ f 0 1 (x, log t) := by
  unfold heatSolution Vint
  rw [← integral_const_mul]
  congr 1
  funext y
  rw [← mul_assoc]
  congr 1
  simp only [Prod.mk_sub_mk, sub_zero, mono, pow_zero, one_mul, Nat.cast_one, heatKernel]
  have h1 : exp (-1 * log t / 2 - (x - y) ^ 2 * exp (-log t) / (4 * κ)) =
      (sqrt t)⁻¹ * exp (-(x - y) ^ 2 / (4 * κ * t)) := by
    rw [sub_eq_add_neg, exp_add, sqrt_eq_rpow, rpow_def_of_pos ht, ← exp_neg, exp_neg (log t),
      exp_log ht]
    congr 2
    · ring
    · field_simp
  have hs : sqrt (4 * π * κ * t) = sqrt (4 * π * κ) * sqrt t := sqrt_mul (by positivity) t
  rw [h1, hs]
  field_simp

lemma heatSolution_undef {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) {f : ℝ → ℝ}
    (hf : ¬ AEStronglyMeasurable f volume) (x : ℝ) : heatSolution κ f x t = 0 := by
  unfold heatSolution
  apply integral_undef
  intro hint
  apply hf
  have hG : ∀ y, heatKernel κ (x - y) t ≠ 0 := fun y => (heatKernel_pos hκ ht _).ne'
  refine (hint.aestronglyMeasurable.mul
    ((heatKernel_continuous κ t x).inv₀ hG).aestronglyMeasurable).congr
    (Filter.Eventually.of_forall fun y => ?_)
  have := hG y
  simp only [Pi.mul_apply, Pi.inv_apply]
  field_simp


lemma kernelShape_nonneg (w : ℝ) : 0 ≤ kernelShape w := by unfold kernelShape; positivity

lemma kernelShape_d1 : iteratedDeriv 1 kernelShape = fun w => kernelShape w * (-w / 2) := by
  rw [iteratedDeriv_one]; funext w; exact (kernelShape_hasDerivAt w).deriv

lemma kernelShape_d1_hasDerivAt (w : ℝ) :
    HasDerivAt (fun w => kernelShape w * (-w / 2)) (kernelShape w * (w ^ 2 / 4 - 1 / 2)) w := by
  have : HasDerivAt (fun w => kernelShape w * (-w / 2)) _ w :=
    (kernelShape_hasDerivAt w).mul ((hasDerivAt_neg w).div_const 2)
  exact this.congr_deriv (by ring)

lemma kernelShape_d2 : iteratedDeriv 2 kernelShape = fun w => kernelShape w * (w ^ 2 / 4 - 1 / 2) := by
  rw [iteratedDeriv_succ, kernelShape_d1]; funext w; exact (kernelShape_d1_hasDerivAt w).deriv

lemma kernelShape_iteratedDeriv_tendsto (k : ℕ) :
    Filter.Tendsto (iteratedDeriv k kernelShape) (Filter.cocompact ℝ) (nhds 0) := by
  obtain ⟨C, _, hC⟩ := kernelShape_iteratedDeriv_decay k
  have h1 : Filter.Tendsto (fun w : ℝ => 1 + w ^ 2) (Filter.cocompact ℝ) Filter.atTop :=
    Filter.tendsto_atTop_mono (fun w => by
      rw [Real.norm_eq_abs]; nlinarith [abs_nonneg w, sq_abs w, sq_nonneg (|w| - 1)])
      tendsto_norm_cocompact_atTop
  have h2 : Filter.Tendsto (fun w : ℝ => C * (1 + w ^ 2)⁻¹) (Filter.cocompact ℝ) (nhds 0) := by
    simpa using h1.inv_tendsto_atTop.const_mul C
  exact squeeze_zero_norm (fun w => by rw [Real.norm_eq_abs]; exact hC w) h2

lemma smoothingConst_one : smoothingConst 1 = 1 / sqrt π := by
  have hint := kernelShape_iteratedDeriv_integrable 1
  have ht := kernelShape_iteratedDeriv_tendsto 0
  have ht' := kernelShape_iteratedDeriv_tendsto 1
  rw [kernelShape_d1] at hint ht'
  simp only [iteratedDeriv_zero] at ht
  unfold smoothingConst
  rw [kernelShape_d1]
  beta_reduce
  rw [← intervalIntegral.integral_Iic_add_Ioi (b := 0) hint.abs.integrableOn hint.abs.integrableOn]
  rw [setIntegral_congr_fun measurableSet_Iic (g := fun w => kernelShape w * (-w / 2))
    (fun w (hw : w ≤ 0) => abs_of_nonneg (mul_nonneg (kernelShape_nonneg w) (by linarith))),
    setIntegral_congr_fun measurableSet_Ioi (g := fun w => -(kernelShape w * (-w / 2)))
    (fun w (hw : 0 < w) => abs_of_nonpos (mul_nonpos_of_nonneg_of_nonpos (kernelShape_nonneg w)
      (by linarith)))]
  rw [integral_Iic_of_hasDerivAt_of_tendsto (f := kernelShape) (m := 0)
      kernelShape_contDiff.continuous.continuousWithinAt
      (fun w _ => kernelShape_hasDerivAt w) hint.integrableOn (ht.mono_left atBot_le_cocompact),
    integral_Ioi_of_hasDerivAt_of_tendsto (f := fun w => -kernelShape w) (m := 0)
      kernelShape_contDiff.continuous.neg.continuousWithinAt
      (fun w _ => (kernelShape_hasDerivAt w).neg) hint.neg.integrableOn
      (by simpa using (ht.mono_left atTop_le_cocompact).neg)]
  have h4 : sqrt (4 * π) = 2 * sqrt π := by
    rw [show (4 : ℝ) * π = 2 ^ 2 * π by norm_num, sqrt_mul (by norm_num), sqrt_sq (by norm_num)]
  have hπ : 0 < sqrt π := sqrt_pos.2 pi_pos
  simp only [kernelShape, h4]
  field_simp
  norm_num

lemma smoothingConst_two :
    smoothingConst 2 = 2 * (exp (-(1 : ℝ) / 2) / sqrt (2 * π)) := by
  have hint := kernelShape_iteratedDeriv_integrable 2
  have ht' := kernelShape_iteratedDeriv_tendsto 1
  rw [kernelShape_d2] at hint
  rw [kernelShape_d1] at ht'
  set s := sqrt 2 with hs_def
  have hs2 : s ^ 2 = 2 := sq_sqrt (by norm_num)
  have hs0 : 0 < s := sqrt_pos.2 (by norm_num)
  set F2 := fun w => kernelShape w * (w ^ 2 / 4 - 1 / 2)
  set F1 := fun w => kernelShape w * (-w / 2)
  have hF1c : Continuous F1 := kernelShape_contDiff.continuous.mul (continuous_neg.div_const 2)
  unfold smoothingConst
  rw [kernelShape_d2]
  beta_reduce
  rw [← intervalIntegral.integral_Iic_add_Ioi (b := -s) hint.abs.integrableOn hint.abs.integrableOn,
    ← Set.Ioc_union_Ioi_eq_Ioi (by linarith : -s ≤ s),
    setIntegral_union Set.Ioc_disjoint_Ioi_same measurableSet_Ioi hint.abs.integrableOn
      hint.abs.integrableOn,
    ← intervalIntegral.integral_of_le (by linarith : -s ≤ s)]
  rw [setIntegral_congr_fun measurableSet_Iic (g := F2)
    (fun w (hw : w ≤ -s) => abs_of_nonneg (mul_nonneg (kernelShape_nonneg w)
      (by nlinarith))),
    setIntegral_congr_fun measurableSet_Ioi (g := F2)
    (fun w (hw : s < w) => abs_of_nonneg (mul_nonneg (kernelShape_nonneg w)
      (by nlinarith))),
    intervalIntegral.integral_congr (g := fun w => -F2 w) (fun w hw => by
      rw [Set.uIcc_of_le (by linarith)] at hw
      exact abs_of_nonpos (mul_nonpos_of_nonneg_of_nonpos (kernelShape_nonneg w)
        (by nlinarith [hw.1, hw.2])))]
  rw [integral_Iic_of_hasDerivAt_of_tendsto (f := F1) (m := 0) hF1c.continuousWithinAt
      (fun w _ => kernelShape_d1_hasDerivAt w) hint.integrableOn (ht'.mono_left atBot_le_cocompact),
    integral_Ioi_of_hasDerivAt_of_tendsto (f := F1) (m := 0) hF1c.continuousWithinAt
      (fun w _ => kernelShape_d1_hasDerivAt w) hint.integrableOn (ht'.mono_left atTop_le_cocompact),
    intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun w => -F1 w)
      (fun w _ => (kernelShape_d1_hasDerivAt w).neg) hint.neg.intervalIntegrable]
  have h4 : sqrt (4 * π) = s * sqrt (2 * π) := by
    rw [hs_def, ← sqrt_mul (by norm_num)]; ring_nf
  have hπ : 0 < sqrt (2 * π) := sqrt_pos.2 (by positivity)
  have he : exp (-(-s) ^ 2 / 4) = exp (-(1 : ℝ) / 2) := by congr 1; rw [neg_sq, hs2]; norm_num
  have he' : exp (-s ^ 2 / 4) = exp (-(1 : ℝ) / 2) := by congr 1; rw [hs2]; norm_num
  simp only [F1, kernelShape, he, he', h4]
  field_simp
  ring

#print axioms one_add_sq_pow_mul_exp_le
#print axioms inv_one_add_sq_le
#print axioms poly_eval_abs_le
#print axioms kernelShape_hasDerivAt
#print axioms kernelShape_contDiff
#print axioms kernelShape_iteratedDeriv_poly
#print axioms kernelShape_iteratedDeriv_decay
#print axioms integrable_const_mul_inv_one_add_sq
#print axioms kernelShape_iteratedDeriv_continuous
#print axioms kernelShape_iteratedDeriv_integrable
#print axioms iteratedDeriv_kernelShape_hasDerivAt
#print axioms gk_hasDerivAt
#print axioms gk_continuous
#print axioms gk_decay
#print axioms gk_abs_integral
#print axioms conv_hasDerivAt
#print axioms conv_iteratedDeriv
#print axioms conv_bound
#print axioms mono_continuous
#print axioms monoD_continuous
#print axioms mono_shift
#print axioms mono_hasFDerivAt
#print axioms inv_one_add_sq_ball
#print axioms mono_dom
#print axioms mono_shift_continuous
#print axioms Vint_integrable
#print axioms monoD_dom
#print axioms Vint_fderiv_integral
#print axioms Vint_hasFDerivAt
#print axioms Vint_contDiff
#print axioms heatKernel_pos
#print axioms heatKernel_continuous
#print axioms heatKernel_integrable
#print axioms heatKernel_eq_gk
#print axioms heatSolution_eq_Vint
#print axioms heatSolution_undef
#print axioms kernelShape_nonneg
#print axioms kernelShape_d1
#print axioms kernelShape_d1_hasDerivAt
#print axioms kernelShape_d2
#print axioms kernelShape_iteratedDeriv_tendsto
#print axioms smoothingConst_one
#print axioms smoothingConst_two

/-- The smoothing law. Let the diffusivity `κ` be a positive constant and the start `f` be
bounded, `|f(y)| ≤ M` for every `y`. Then the temperature `u(x, t) = ∫ G(x - y, t) f(y) dy` is
smooth (has continuous derivatives of every order) in place and time together at every time
`t > 0`, however rough `f` is, and at every `t > 0` its `k`-th rate of change along the line
obeys `|∂ₓᵏ u(x, t)| ≤ c_k · M · (κt)^(-k/2)`: each extra derivative costs a factor
`1/√(κt)`. -/
theorem heat_solution_smooth_with_derivative_bounds {κ M : ℝ} (hκ : 0 < κ) (f : ℝ → ℝ)
    (hbdd : ∀ y, |f y| ≤ M) :
    ContDiffOn ℝ ∞ (fun p : ℝ × ℝ => heatSolution κ f p.1 p.2) {p : ℝ × ℝ | 0 < p.2} ∧
      ∀ t, 0 < t → ∀ (k : ℕ) (x : ℝ),
        |iteratedDeriv k (fun z => heatSolution κ f z t) x|
          ≤ smoothingConst k * M * (κ * t) ^ (-(k : ℝ) / 2) := by
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hbdd 0)
  by_cases hf : AEStronglyMeasurable f volume
  · constructor
    · have hV : ContDiff ℝ ∞ (Vint κ f 0 1) :=
        contDiff_infty.2 fun n => Vint_contDiff hκ hf hbdd n 0 1
      have hg : ContDiffOn ℝ ∞
          (fun p : ℝ × ℝ => (sqrt (4 * π * κ))⁻¹ * Vint κ f 0 1 (p.1, log p.2))
          {p : ℝ × ℝ | 0 < p.2} :=
        contDiffOn_const.mul (hV.comp_contDiffOn (contDiffOn_fst.prodMk
          (Real.contDiffOn_log.comp contDiffOn_snd (fun p (hp : 0 < p.2) => by simpa using hp.ne'))))
      exact hg.congr fun p hp => heatSolution_eq_Vint hκ f p.1 hp
    · intro t ht k x
      have hr : 0 < sqrt (κ * t) := sqrt_pos.2 (mul_pos hκ ht)
      have hfun : (fun z => heatSolution κ f z t) =
          fun x => ∫ y, gk (sqrt (κ * t)) 0 (x - y) * f y := by
        funext z
        unfold heatSolution
        simp_rw [heatKernel_eq_gk hκ ht]
      rw [hfun, conv_iteratedDeriv hr hf hbdd k]
      refine (conv_bound hr hbdd k x).trans (le_of_eq ?_)
      congr 1
      rw [sqrt_eq_rpow, ← rpow_neg (by positivity), ← rpow_natCast, ← rpow_mul (by positivity)]
      congr 1
      ring
  · constructor
    · exact contDiffOn_const.congr fun p hp => heatSolution_undef hκ hp hf p.1
    · intro t ht k x
      have : (fun z => heatSolution κ f z t) = fun _ => 0 :=
        funext fun z => heatSolution_undef hκ ht hf z
      rw [this, iteratedDeriv_const]
      have : 0 ≤ smoothingConst k := integral_nonneg fun _ => abs_nonneg _
      have : 0 ≤ (κ * t) ^ (-(k : ℝ) / 2) := by positivity
      split_ifs <;> simp <;> positivity

/-- The first two smoothing constants, from counting the bell's rises and falls:
`c_1 = 1/√π` (twice the peak height) and `c_2 = 2φ(1)`, where `φ(1) = e^(-1/2)/√(2π)` is the
standard bell's height one unit from its centre. -/
theorem smoothing_constants_first_two :
    smoothingConst 1 = 1 / sqrt π ∧
      smoothingConst 2 = 2 * (exp (-(1 : ℝ) / 2) / sqrt (2 * π)) := by
  exact ⟨smoothingConst_one, smoothingConst_two⟩

/-- Felt everywhere at once. Let `κ > 0` and let the start `f` be bounded, never negative, and
not zero (not zero on a set of positive length). Then at every time `t > 0` the temperature is
strictly positive at every point of the line. -/
theorem heat_solution_positive_everywhere {κ M : ℝ} (hκ : 0 < κ) (f : ℝ → ℝ)
    (hf : Measurable f) (hbdd : ∀ y, |f y| ≤ M) (hnonneg : ∀ y, 0 ≤ f y)
    (hnonzero : ¬ (f =ᵐ[volume] 0)) :
    ∀ x t, 0 < t → 0 < heatSolution κ f x t := by
  intro x t ht
  have hG : ∀ y, 0 < heatKernel κ (x - y) t := fun y => heatKernel_pos hκ ht _
  have hint : Integrable (fun y => heatKernel κ (x - y) t * f y) :=
    (heatKernel_integrable hκ ht x).mul_bdd hf.aestronglyMeasurable
      (Filter.Eventually.of_forall fun y => by rw [Real.norm_eq_abs]; exact hbdd y)
  unfold heatSolution
  rw [integral_pos_iff_support_of_nonneg (fun y => mul_nonneg (hG y).le (hnonneg y)) hint]
  have hs : Function.support (fun y => heatKernel κ (x - y) t * f y) = Function.support f := by
    ext y; simp [(hG y).ne']
  rw [hs, pos_iff_ne_zero]
  intro h0
  apply hnonzero
  rw [Filter.EventuallyEq, ae_iff]
  simpa [Function.support] using h0

-- The tent's slope: H/W = 50 °C over 0.1 m = 500 °C per metre.
example : (50 : ℚ) / (1 / 10) = 500 := by norm_num

-- The tent is (H/W) times three ramps with weights 1, -2, 1 at 0.4, 0.5, 0.6 m. The weights sum
-- to 0 and 0.4 - 2 × 0.5 + 0.6 = 0, so the straight parts cancel beyond the tent.
example : (1 : ℚ) + (-2) + 1 = 0 ∧ (2 / 5 : ℚ) - 2 * (1 / 2) + 3 / 5 = 0 := by norm_num

-- A fourfold wait: the curvature goes like t^(-1/2) and the fourth derivative like t^(-3/2),
-- so the ratios are 4^(1/2) = 2 and 4^(3/2) = 8, that is 2² = 4 and 8² = 4³.
example : (2 : ℕ) ^ 2 = 4 ∧ (8 : ℕ) ^ 2 = 4 ^ 3 := by decide

#print axioms heat_solution_smooth_with_derivative_bounds
#print axioms smoothing_constants_first_two
#print axioms heat_solution_positive_everywhere
