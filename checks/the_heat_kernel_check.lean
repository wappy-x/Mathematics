-- The heat kernel: on the whole real line the bell G(x, t) = e^(-x^2/(4κt)) / √(4πκt) solves u_t = κ u_xx with total 1 and mean squared spread 2κt, its blend with any bounded continuous start solves the heat equation and starts at that function, and a step start becomes ½(1 − erf(x/(2√(κt)))).
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.Calculus.ParametricIntegral

open Real MeasureTheory Filter Topology

/-- The heat kernel on the line: G(x, t) = e^(-x^2/(4κt)) / √(4πκt). -/
noncomputable def heatKernel (κ t x : ℝ) : ℝ :=
  Real.exp (-x ^ 2 / (4 * κ * t)) / Real.sqrt (4 * π * κ * t)

/-- The error function, as the card defines it: erf z = (2/√π) ∫₀^z e^(-s^2) ds. -/
noncomputable def erf (z : ℝ) : ℝ :=
  2 / Real.sqrt π * ∫ s in (0 : ℝ)..z, Real.exp (-s ^ 2)

lemma hk_hasDerivAt_x (κ t z : ℝ) :
    HasDerivAt (fun z => heatKernel κ t z)
      (heatKernel κ t z * (-(2 * z) / (4 * κ * t))) z := by
  have h : HasDerivAt (fun z => Real.exp (-z ^ 2 / (4 * κ * t)) / Real.sqrt (4 * π * κ * t)) _ z :=
    (((hasDerivAt_pow 2 z).neg.div_const (4 * κ * t)).exp).div_const (Real.sqrt (4 * π * κ * t))
  refine h.congr_deriv ?_
  unfold heatKernel
  simp only [Pi.neg_apply, Nat.cast_ofNat]; ring

lemma hk1_hasDerivAt_x (κ t z : ℝ) :
    HasDerivAt (fun z => heatKernel κ t z * (-(2 * z) / (4 * κ * t)))
      (heatKernel κ t z * ((2 * z / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t))) z := by
  have h : HasDerivAt (fun z => heatKernel κ t z * (-(2 * z) / (4 * κ * t))) _ z :=
    (hk_hasDerivAt_x κ t z).mul (((hasDerivAt_id z).const_mul 2).neg.div_const (4 * κ * t))
  refine h.congr_deriv ?_
  ring

lemma hk_hasDerivAt_t (κ t z : ℝ) (hκ : 0 < κ) (ht : 0 < t) :
    HasDerivAt (fun s => heatKernel κ s z)
      (heatKernel κ t z * (z ^ 2 / (4 * κ * t ^ 2) - 1 / (2 * t))) t := by
  have h4 : (4 * κ * t) ≠ 0 := by positivity
  have hp : 0 < 4 * π * κ * t := by positivity
  have hs : 0 < Real.sqrt (4 * π * κ * t) := Real.sqrt_pos.2 hp
  have hden : HasDerivAt (fun s => 4 * κ * s) (4 * κ * 1) t := (hasDerivAt_id t).const_mul (4 * κ)
  have hin : HasDerivAt (fun s => -z ^ 2 / (4 * κ * s))
      ((0 * (4 * κ * t) - (-z ^ 2) * (4 * κ * 1)) / (4 * κ * t) ^ 2) t :=
    (hasDerivAt_const t (-z ^ 2)).div hden h4
  have hsq : HasDerivAt (fun s => Real.sqrt (4 * π * κ * s))
      ((4 * π * κ * 1) / (2 * Real.sqrt (4 * π * κ * t))) t :=
    ((hasDerivAt_id t).const_mul (4 * π * κ)).sqrt hp.ne'
  have h : HasDerivAt (fun s => Real.exp (-z ^ 2 / (4 * κ * s)) / Real.sqrt (4 * π * κ * s)) _ t :=
    hin.exp.div hsq hs.ne'
  refine h.congr_deriv ?_
  have hss : Real.sqrt (4 * π * κ * t) ^ 2 = 4 * π * κ * t := Real.sq_sqrt hp.le
  unfold heatKernel
  generalize Real.sqrt (4 * π * κ * t) = S at hss hs ⊢
  field_simp
  linear_combination (4 * κ * t) * hss
lemma sq_mul_exp_neg_le {a : ℝ} (ha : 0 < a) (z : ℝ) :
    z ^ 2 * exp (-z ^ 2 / a) ≤ 2 * a * exp (-(1 / (2 * a)) * z ^ 2) := by
  have h1 := Real.add_one_le_exp (z ^ 2 / (2 * a))
  have hsplit : exp (-z ^ 2 / a) = exp (-(1 / (2 * a)) * z ^ 2) * exp (-(1 / (2 * a)) * z ^ 2) := by
    rw [← Real.exp_add]; congr 1; field_simp; ring
  have hinv : exp (z ^ 2 / (2 * a)) * exp (-(1 / (2 * a)) * z ^ 2) = 1 := by
    rw [← Real.exp_add]; convert Real.exp_zero using 2; field_simp; ring
  have hz : z ^ 2 ≤ 2 * a * exp (z ^ 2 / (2 * a)) := by
    have : z ^ 2 / (2 * a) ≤ exp (z ^ 2 / (2 * a)) := by linarith
    rw [div_le_iff₀ (by positivity)] at this; linarith
  have he : 0 < exp (-(1 / (2 * a)) * z ^ 2) := exp_pos _
  rw [hsplit]
  calc z ^ 2 * (exp (-(1 / (2 * a)) * z ^ 2) * exp (-(1 / (2 * a)) * z ^ 2))
      ≤ (2 * a * exp (z ^ 2 / (2 * a))) * (exp (-(1 / (2 * a)) * z ^ 2) * exp (-(1 / (2 * a)) * z ^ 2)) := by
        gcongr
    _ = 2 * a * exp (-(1 / (2 * a)) * z ^ 2) := by
        rw [show 2 * a * exp (z ^ 2 / (2 * a)) * (exp (-(1 / (2 * a)) * z ^ 2) * exp (-(1 / (2 * a)) * z ^ 2))
          = 2 * a * (exp (z ^ 2 / (2 * a)) * exp (-(1 / (2 * a)) * z ^ 2)) * exp (-(1 / (2 * a)) * z ^ 2) by ring,
          hinv]; ring

lemma poly_mul_exp_neg_le {a A B : ℝ} (ha : 0 < a) (hA : 0 ≤ A) (hB : 0 ≤ B) (z : ℝ) :
    (A + B * z ^ 2) * exp (-z ^ 2 / a) ≤ (A + 2 * a * B) * exp (-(1 / (2 * a)) * z ^ 2) := by
  have h1 : exp (-z ^ 2 / a) ≤ exp (-(1 / (2 * a)) * z ^ 2) := by
    apply Real.exp_le_exp.2
    have : 0 ≤ z ^ 2 := sq_nonneg z
    rw [div_le_iff₀ ha]
    have : -(1 / (2 * a)) * z ^ 2 * a = -z ^ 2 / 2 := by field_simp
    nlinarith
  have h2 := sq_mul_exp_neg_le ha z
  have : (A + B * z ^ 2) * exp (-z ^ 2 / a) = A * exp (-z ^ 2 / a) + B * (z ^ 2 * exp (-z ^ 2 / a)) := by ring
  rw [this]
  have := mul_le_mul_of_nonneg_left h1 hA
  have := mul_le_mul_of_nonneg_left h2 hB
  nlinarith

lemma exp_shift_le {b : ℝ} (hb : 0 < b) (x0 x y : ℝ) (hx : |x - x0| ≤ 1) :
    exp (-b * (x - y) ^ 2) ≤ exp b * exp (-(b / 2) * (y - x0) ^ 2) := by
  rw [← Real.exp_add]
  apply Real.exp_le_exp.2
  have hx2 : (x - x0) ^ 2 ≤ 1 := by
    have := abs_le.1 hx; nlinarith
  have h1 : (y - x0) ^ 2 ≤ 2 * (x - y) ^ 2 + 2 := by nlinarith [sq_nonneg (x - y + (x - x0))]
  nlinarith [mul_le_mul_of_nonneg_left h1 hb.le]

lemma conv_pointwise_bound {g f : ℝ → ℝ} {D b M : ℝ} (hb : 0 < b) (hD : 0 ≤ D) (hM0 : 0 ≤ M)
    (hg : ∀ z, |g z| ≤ D * exp (-b * z ^ 2)) (hM : ∀ y, |f y| ≤ M) (x0 x y : ℝ)
    (hx : |x - x0| ≤ 1) :
    ‖g (x - y) * f y‖ ≤ D * M * exp b * exp (-(b / 2) * (y - x0) ^ 2) := by
  rw [Real.norm_eq_abs, abs_mul]
  have h1 := hg (x - y)
  have h2 := exp_shift_le hb x0 x y hx
  calc |g (x - y)| * |f y| ≤ (D * exp (-b * (x - y) ^ 2)) * M :=
        mul_le_mul h1 (hM y) (abs_nonneg _) (by positivity)
    _ ≤ (D * (exp b * exp (-(b / 2) * (y - x0) ^ 2))) * M := by gcongr
    _ = D * M * exp b * exp (-(b / 2) * (y - x0) ^ 2) := by ring

lemma integrable_shift_bound {b : ℝ} (hb : 0 < b) (K x0 : ℝ) :
    Integrable (fun y => K * exp (-(b / 2) * (y - x0) ^ 2)) :=
  ((integrable_exp_neg_mul_sq (half_pos hb)).comp_sub_right x0).const_mul K

lemma conv_integrable {k : ℝ → ℝ} (hkc : Continuous k)
    {C b : ℝ} (hb : 0 < b) (hbd : ∀ z, |k z| ≤ C * exp (-b * z ^ 2))
    {f : ℝ → ℝ} (hf : Continuous f) {M : ℝ} (hM : ∀ y, |f y| ≤ M) (x0 : ℝ) :
    Integrable (fun y => k (x0 - y) * f y) := by
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  have hC : 0 ≤ C := by have := hbd 0; simp at this; exact (abs_nonneg _).trans this
  exact (integrable_shift_bound hb (C * M * exp b) x0).mono'
      ((hkc.comp (continuous_const.sub continuous_id)).mul hf).aestronglyMeasurable
      (ae_of_all _ fun y => conv_pointwise_bound hb hC hM0 hbd hM x0 x0 y (by simp))

lemma conv_hasDerivAt {k k' : ℝ → ℝ} (hk : ∀ z, HasDerivAt k (k' z) z) (hk'c : Continuous k')
    {C C' b : ℝ} (hb : 0 < b) (hbd : ∀ z, |k z| ≤ C * exp (-b * z ^ 2))
    (hbd' : ∀ z, |k' z| ≤ C' * exp (-b * z ^ 2))
    {f : ℝ → ℝ} (hf : Continuous f) {M : ℝ} (hM : ∀ y, |f y| ≤ M) (x0 : ℝ) :
    HasDerivAt (fun x => ∫ y, k (x - y) * f y) (∫ y, k' (x0 - y) * f y) x0 := by
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  have hC : 0 ≤ C := by have := hbd 0; simp at this; exact (abs_nonneg _).trans this
  have hC' : 0 ≤ C' := by have := hbd' 0; simp at this; exact (abs_nonneg _).trans this
  have hkc : Continuous k := continuous_iff_continuousAt.2 fun z => (hk z).continuousAt
  have key := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun x y => k (x - y) * f y) (F' := fun x y => k' (x - y) * f y) (x₀ := x0)
    (bound := fun y => C' * M * exp b * exp (-(b / 2) * (y - x0) ^ 2))
    (Metric.ball_mem_nhds x0 one_pos)
    (Eventually.of_forall fun x => ((hkc.comp (continuous_const.sub continuous_id)).mul hf).aestronglyMeasurable)
    ((integrable_shift_bound hb (C * M * exp b) x0).mono'
      ((hkc.comp (continuous_const.sub continuous_id)).mul hf).aestronglyMeasurable
      (ae_of_all _ fun y => conv_pointwise_bound hb hC hM0 hbd hM x0 x0 y (by simp)))
    ((hk'c.comp (continuous_const.sub continuous_id)).mul hf).aestronglyMeasurable
    (ae_of_all _ fun y x hx => conv_pointwise_bound hb hC' hM0 hbd' hM x0 x y
      (by rw [Metric.mem_ball, Real.dist_eq] at hx; exact hx.le))
    (integrable_shift_bound hb _ x0)
    (ae_of_all _ fun y x _ => by
      have := ((hk (x - y)).comp x ((hasDerivAt_id x).sub_const y)).mul_const (f y)
      simpa using this)
  exact key.2

lemma conv_continuous {k : ℝ → ℝ} (hkc : Continuous k)
    {C b : ℝ} (hb : 0 < b) (hbd : ∀ z, |k z| ≤ C * exp (-b * z ^ 2))
    {f : ℝ → ℝ} (hf : Continuous f) {M : ℝ} (hM : ∀ y, |f y| ≤ M) :
    Continuous (fun x => ∫ y, k (x - y) * f y) := by
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  have hC : 0 ≤ C := by have := hbd 0; simp at this; exact (abs_nonneg _).trans this
  refine continuous_iff_continuousAt.2 fun x0 => ?_
  refine continuousAt_of_dominated
    (bound := fun y => C * M * exp b * exp (-(b / 2) * (y - x0) ^ 2))
    (Eventually.of_forall fun x => ((hkc.comp (continuous_const.sub continuous_id)).mul hf).aestronglyMeasurable)
    ?_ (integrable_shift_bound hb _ x0)
    (ae_of_all _ fun y => ((hkc.comp (continuous_id.sub continuous_const)).mul continuous_const).continuousAt)
  filter_upwards [Metric.closedBall_mem_nhds x0 one_pos] with x hx
  refine ae_of_all _ fun y => conv_pointwise_bound hb hC hM0 hbd hM x0 x y ?_
  rw [Metric.mem_closedBall, Real.dist_eq] at hx; exact hx

lemma hk_nonneg (κ t z : ℝ) : 0 ≤ heatKernel κ t z :=
  div_nonneg (exp_pos _).le (Real.sqrt_nonneg _)

lemma hk_poly_bound {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) {P : ℝ → ℝ} {A B : ℝ} (hA : 0 ≤ A)
    (hB : 0 ≤ B) (hP : ∀ z, |P z| ≤ A + B * z ^ 2) (z : ℝ) :
    |heatKernel κ t z * P z| ≤
      (A + 2 * (4 * κ * t) * B) / Real.sqrt (4 * π * κ * t) *
        exp (-(1 / (2 * (4 * κ * t))) * z ^ 2) := by
  have ha : 0 < 4 * κ * t := by positivity
  have hs : 0 < Real.sqrt (4 * π * κ * t) := Real.sqrt_pos.2 (by positivity)
  rw [abs_mul, abs_of_nonneg (hk_nonneg κ t z)]
  calc heatKernel κ t z * |P z| ≤ heatKernel κ t z * (A + B * z ^ 2) :=
        mul_le_mul_of_nonneg_left (hP z) (hk_nonneg κ t z)
    _ = (A + B * z ^ 2) * exp (-z ^ 2 / (4 * κ * t)) / Real.sqrt (4 * π * κ * t) := by
        unfold heatKernel; ring
    _ ≤ (A + 2 * (4 * κ * t) * B) * exp (-(1 / (2 * (4 * κ * t))) * z ^ 2) /
          Real.sqrt (4 * π * κ * t) := by
        exact (div_le_div_iff_of_pos_right hs).2 (poly_mul_exp_neg_le ha hA hB z)
    _ = _ := by ring

lemma hk0_bound {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (z : ℝ) :
    |heatKernel κ t z| ≤ (1 + 2 * (4 * κ * t) * 0) / Real.sqrt (4 * π * κ * t) *
        exp (-(1 / (2 * (4 * κ * t))) * z ^ 2) := by
  have := hk_poly_bound hκ ht (P := fun _ => 1) zero_le_one le_rfl (fun z => by simp) z
  simpa using this

lemma hk1_bound {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (z : ℝ) :
    |heatKernel κ t z * (-(2 * z) / (4 * κ * t))| ≤
      (2 / (4 * κ * t) + 2 * (4 * κ * t) * (2 / (4 * κ * t))) / Real.sqrt (4 * π * κ * t) *
        exp (-(1 / (2 * (4 * κ * t))) * z ^ 2) := by
  have ha : 0 < 4 * κ * t := by positivity
  refine hk_poly_bound hκ ht (P := fun z => -(2 * z) / (4 * κ * t)) (A := 2 / (4 * κ * t))
    (B := 2 / (4 * κ * t)) (by positivity)
    (by positivity) (fun z => ?_) z
  rw [abs_div, abs_neg, abs_of_pos ha, abs_mul, abs_two, div_le_iff₀ ha]
  have h1 : |z| ≤ 1 + z ^ 2 := by nlinarith [sq_nonneg (|z| - 1), sq_abs z, abs_nonneg z]
  have : (2 / (4 * κ * t) + 2 / (4 * κ * t) * z ^ 2) * (4 * κ * t) = 2 * (1 + z ^ 2) := by
    field_simp
  rw [this]; linarith

lemma hk2_bound {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (z : ℝ) :
    |heatKernel κ t z * ((2 * z / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t))| ≤
      (2 / (4 * κ * t) + 2 * (4 * κ * t) * (4 / (4 * κ * t) ^ 2)) / Real.sqrt (4 * π * κ * t) *
        exp (-(1 / (2 * (4 * κ * t))) * z ^ 2) := by
  have ha : 0 < 4 * κ * t := by positivity
  refine hk_poly_bound hκ ht (P := fun z => (2 * z / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t))
    (A := 2 / (4 * κ * t)) (B := 4 / (4 * κ * t) ^ 2) (by positivity)
    (by positivity) (fun z => ?_) z
  refine (abs_sub _ _).trans ?_
  rw [abs_of_nonneg (sq_nonneg _), abs_of_pos (by positivity)]
  have : (2 * z / (4 * κ * t)) ^ 2 = 4 / (4 * κ * t) ^ 2 * z ^ 2 := by ring
  linarith

lemma hkt_bound {κ t0 t : ℝ} (hκ : 0 < κ) (ht0 : 0 < t0) (ht1 : t0 / 2 < t) (ht2 : t < 3 * t0 / 2)
    (z : ℝ) :
    |heatKernel κ t z * (z ^ 2 / (4 * κ * t ^ 2) - 1 / (2 * t))| ≤
      (1 / t0 + 2 * (6 * κ * t0) * (1 / (κ * t0 ^ 2))) / Real.sqrt (2 * π * κ * t0) *
        exp (-(1 / (2 * (6 * κ * t0))) * z ^ 2) := by
  have ht : 0 < t := by linarith
  have hb : 0 < 6 * κ * t0 := by positivity
  have hP : |z ^ 2 / (4 * κ * t ^ 2) - 1 / (2 * t)| ≤ 1 / t0 + 1 / (κ * t0 ^ 2) * z ^ 2 := by
    refine (abs_sub _ _).trans ?_
    rw [abs_of_nonneg (by positivity), abs_of_pos (by positivity)]
    have e1 : z ^ 2 / (4 * κ * t ^ 2) ≤ 1 / (κ * t0 ^ 2) * z ^ 2 := by
      rw [one_div_mul_eq_div]
      apply div_le_div_of_nonneg_left (sq_nonneg z) (by positivity)
      have : t0 ^ 2 < 4 * t ^ 2 := by nlinarith
      nlinarith [mul_lt_mul_of_pos_left this hκ]
    have e2 : 1 / (2 * t) ≤ 1 / t0 := one_div_le_one_div_of_le ht0 (by linarith)
    linarith
  have hK : heatKernel κ t z ≤ exp (-z ^ 2 / (6 * κ * t0)) / Real.sqrt (2 * π * κ * t0) := by
    unfold heatKernel
    apply div_le_div₀ (exp_pos _).le
    · apply Real.exp_le_exp.2
      rw [neg_div, neg_div, neg_le_neg_iff]
      apply div_le_div_of_nonneg_left (sq_nonneg z) (by positivity)
      nlinarith
    · exact Real.sqrt_pos.2 (by positivity)
    · apply Real.sqrt_le_sqrt
      have := mul_lt_mul_of_pos_left (show t0 < 2 * t by linarith) (mul_pos pi_pos hκ)
      nlinarith
  rw [abs_mul, abs_of_nonneg (hk_nonneg κ t z)]
  have hs : 0 < Real.sqrt (2 * π * κ * t0) := Real.sqrt_pos.2 (by positivity)
  calc heatKernel κ t z * |z ^ 2 / (4 * κ * t ^ 2) - 1 / (2 * t)|
      ≤ exp (-z ^ 2 / (6 * κ * t0)) / Real.sqrt (2 * π * κ * t0) *
          (1 / t0 + 1 / (κ * t0 ^ 2) * z ^ 2) :=
        mul_le_mul hK hP (abs_nonneg _) (by positivity)
    _ = (1 / t0 + 1 / (κ * t0 ^ 2) * z ^ 2) * exp (-z ^ 2 / (6 * κ * t0)) /
          Real.sqrt (2 * π * κ * t0) := by ring
    _ ≤ (1 / t0 + 2 * (6 * κ * t0) * (1 / (κ * t0 ^ 2))) * exp (-(1 / (2 * (6 * κ * t0))) * z ^ 2) /
          Real.sqrt (2 * π * κ * t0) := by
        exact (div_le_div_iff_of_pos_right hs).2
          (poly_mul_exp_neg_le hb (by positivity) (by positivity) z)
    _ = _ := by ring

lemma conv_hasDerivAt_t {κ : ℝ} (hκ : 0 < κ) {f : ℝ → ℝ} (hf : Continuous f) {M : ℝ}
    (hM : ∀ y, |f y| ≤ M) (x t0 : ℝ) (ht0 : 0 < t0) :
    HasDerivAt (fun s => ∫ y, heatKernel κ s (x - y) * f y)
      (∫ y, heatKernel κ t0 (x - y) * ((x - y) ^ 2 / (4 * κ * t0 ^ 2) - 1 / (2 * t0)) * f y) t0 := by
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  have hb : 0 < 1 / (2 * (6 * κ * t0)) := by positivity
  set D := (1 / t0 + 2 * (6 * κ * t0) * (1 / (κ * t0 ^ 2))) / Real.sqrt (2 * π * κ * t0) with hD
  have hD0 : 0 ≤ D := by positivity
  have hkc : ∀ s, Continuous (fun z => heatKernel κ s z) := fun s => by
    unfold heatKernel; fun_prop
  have hint : Integrable (fun y => D * M * exp (-(1 / (2 * (6 * κ * t0))) * (x - y) ^ 2)) :=
    ((integrable_exp_neg_mul_sq hb).comp_sub_left x).const_mul (D * M)
  have key := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun s y => heatKernel κ s (x - y) * f y)
    (F' := fun s y => heatKernel κ s (x - y) * ((x - y) ^ 2 / (4 * κ * s ^ 2) - 1 / (2 * s)) * f y)
    (x₀ := t0)
    (bound := fun y => D * M * exp (-(1 / (2 * (6 * κ * t0))) * (x - y) ^ 2))
    (Metric.ball_mem_nhds t0 (half_pos ht0))
    (Eventually.of_forall fun s =>
      (((hkc s).comp (continuous_const.sub continuous_id)).mul hf).aestronglyMeasurable)
    (conv_integrable (hkc t0) (by positivity) (hk0_bound hκ ht0) hf hM x)
    (by
      apply Continuous.aestronglyMeasurable
      unfold heatKernel; fun_prop)
    (ae_of_all _ fun y s hs => by
      rw [Metric.mem_ball, Real.dist_eq, abs_lt] at hs
      rw [Real.norm_eq_abs, abs_mul]
      have h1 := hkt_bound hκ ht0 (by linarith) (by linarith) (x - y) (t := s)
      calc _ ≤ D * exp (-(1 / (2 * (6 * κ * t0))) * (x - y) ^ 2) * M :=
            mul_le_mul h1 (hM y) (abs_nonneg _) (by positivity)
        _ = _ := by ring)
    hint
    (ae_of_all _ fun y s hs => by
      rw [Metric.mem_ball, Real.dist_eq, abs_lt] at hs
      exact (hk_hasDerivAt_t κ s (x - y) hκ (by linarith)).mul_const (f y))
  exact key.2

lemma hkc_of (κ t : ℝ) : Continuous (fun z => heatKernel κ t z) := by
  unfold heatKernel; fun_prop

lemma sqrt_four_pi_kt (κ t : ℝ) :
    Real.sqrt (4 * π * κ * t) = Real.sqrt π * (2 * Real.sqrt (κ * t)) := by
  rw [show 4 * π * κ * t = π * (2 ^ 2 * (κ * t)) by ring, Real.sqrt_mul pi_pos.le,
    Real.sqrt_mul (by norm_num), Real.sqrt_sq (by norm_num)]

lemma hk_rescale {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (w : ℝ) :
    2 * Real.sqrt (κ * t) * heatKernel κ t (2 * Real.sqrt (κ * t) * w) =
      1 / Real.sqrt π * exp (-w ^ 2) := by
  have hkt : 0 < Real.sqrt (κ * t) := Real.sqrt_pos.2 (by positivity)
  have hpi : 0 < Real.sqrt π := Real.sqrt_pos.2 pi_pos
  have hsq : Real.sqrt (κ * t) ^ 2 = κ * t := Real.sq_sqrt (by positivity)
  unfold heatKernel
  rw [sqrt_four_pi_kt κ t]
  have : -(2 * Real.sqrt (κ * t) * w) ^ 2 / (4 * κ * t) = -w ^ 2 := by
    rw [mul_pow, mul_pow, hsq]; field_simp; ring
  rw [this]
  field_simp

lemma hk_conv_rescale {κ : ℝ} (hκ : 0 < κ) (f : ℝ → ℝ) (x t : ℝ) (ht : 0 < t) :
    ∫ y, heatKernel κ t (x - y) * f y =
      ∫ w, 1 / Real.sqrt π * exp (-w ^ 2) * f (x - 2 * Real.sqrt (κ * t) * w) := by
  have hσ : 0 < 2 * Real.sqrt (κ * t) := by
    have : 0 < Real.sqrt (κ * t) := Real.sqrt_pos.2 (by positivity)
    linarith
  have h1 := integral_sub_left_eq_self (μ := volume) (fun z => heatKernel κ t z * f (x - z)) x
  simp only [sub_sub_cancel] at h1
  rw [h1]
  have h2 := Measure.integral_comp_mul_left (fun z => heatKernel κ t z * f (x - z))
    (2 * Real.sqrt (κ * t))
  rw [abs_of_pos (inv_pos.2 hσ), smul_eq_mul] at h2
  have h3 : ∫ y, heatKernel κ t y * f (x - y) =
      2 * Real.sqrt (κ * t) * ∫ w, heatKernel κ t (2 * Real.sqrt (κ * t) * w) *
        f (x - 2 * Real.sqrt (κ * t) * w) := by
    rw [h2]; field_simp
  rw [h3, ← integral_const_mul]
  congr 1; funext w
  rw [← hk_rescale hκ ht w]; ring

lemma hk_conv_tendsto {κ : ℝ} (hκ : 0 < κ) {f : ℝ → ℝ} (hf : Continuous f) {M : ℝ}
    (hM : ∀ y, |f y| ≤ M) (x : ℝ) :
    Tendsto (fun t => ∫ y, heatKernel κ t (x - y) * f y) (𝓝[>] 0) (𝓝 (f x)) := by
  have hpi : 0 < Real.sqrt π := Real.sqrt_pos.2 pi_pos
  have hlim : Tendsto (fun t => ∫ w, 1 / Real.sqrt π * exp (-w ^ 2) *
      f (x - 2 * Real.sqrt (κ * t) * w)) (𝓝[>] 0)
      (𝓝 (∫ w, 1 / Real.sqrt π * exp (-w ^ 2) * f x)) := by
    refine tendsto_integral_filter_of_dominated_convergence
      (fun w => 1 / Real.sqrt π * exp (-w ^ 2) * M) ?_ ?_ ?_ ?_
    · exact Eventually.of_forall fun t => by
        apply Continuous.aestronglyMeasurable; fun_prop
    · refine Eventually.of_forall fun t => ae_of_all _ fun w => ?_
      rw [Real.norm_eq_abs, abs_mul, abs_of_pos (by positivity)]
      exact mul_le_mul_of_nonneg_left (hM _) (by positivity)
    · have := (integrable_exp_neg_mul_sq one_pos).const_mul (1 / Real.sqrt π)
      simpa using this.mul_const M
    · refine ae_of_all _ fun w => ?_
      have hc : Continuous fun t : ℝ => 1 / Real.sqrt π * exp (-w ^ 2) *
          f (x - 2 * Real.sqrt (κ * t) * w) := by fun_prop
      convert (hc.tendsto 0).mono_left nhdsWithin_le_nhds using 2
      simp
  have hval : ∫ w, 1 / Real.sqrt π * exp (-w ^ 2) * f x = f x := by
    rw [integral_mul_const, integral_const_mul]
    have := integral_gaussian 1
    simp only [neg_mul, one_mul, div_one] at this
    rw [this]; field_simp
  rw [hval] at hlim
  refine hlim.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with t ht
  exact (hk_conv_rescale hκ f x t ht).symm

/-- On an endless line, with constant diffusivity κ > 0 and forward time t > 0, any bounded
continuous start f evolves into the blend of bells u(x, t) = ∫ G(x − y, t) f(y) dy: this blend
is twice differentiable in x, solves u_t = κ u_xx at every point, and tends to f(x) as t → 0⁺. -/
theorem heat_kernel_blend_solves_heat_equation (κ : ℝ) (hκ : 0 < κ) (f : ℝ → ℝ)
    (hf : Continuous f) (hfb : ∃ M, ∀ y, |f y| ≤ M) :
    let u : ℝ → ℝ → ℝ := fun x t => ∫ y, heatKernel κ t (x - y) * f y
    (∀ t, 0 < t → ContDiff ℝ 2 (fun x => u x t)) ∧
    (∀ x t, 0 < t →
      HasDerivAt (fun s => u x s) (κ * deriv (deriv (fun z => u z t)) x) t) ∧
    (∀ x, Tendsto (fun t => u x t) (𝓝[>] 0) (𝓝 (f x))) := by
  intro u
  obtain ⟨M, hM⟩ := hfb
  have hkc : ∀ t, Continuous (fun z => heatKernel κ t z) := fun t => by
    unfold heatKernel; fun_prop
  have hD1 : ∀ t, 0 < t → ∀ x, HasDerivAt (fun x => ∫ y, heatKernel κ t (x - y) * f y)
      (∫ y, heatKernel κ t (x - y) * (-(2 * (x - y)) / (4 * κ * t)) * f y) x := fun t ht x =>
    conv_hasDerivAt (k := fun z => heatKernel κ t z)
      (k' := fun z => heatKernel κ t z * (-(2 * z) / (4 * κ * t)))
      (hk_hasDerivAt_x κ t) (by have := hkc t; fun_prop)
      (by positivity) (hk0_bound hκ ht) (hk1_bound hκ ht) hf hM x
  have hD2 : ∀ t, 0 < t → ∀ x, HasDerivAt
      (fun x => ∫ y, heatKernel κ t (x - y) * (-(2 * (x - y)) / (4 * κ * t)) * f y)
      (∫ y, heatKernel κ t (x - y) * ((2 * (x - y) / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t)) * f y)
      x := fun t ht x =>
    conv_hasDerivAt (k := fun z => heatKernel κ t z * (-(2 * z) / (4 * κ * t)))
      (k' := fun z => heatKernel κ t z * ((2 * z / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t)))
      (hk1_hasDerivAt_x κ t) (by have := hkc t; fun_prop)
      (by positivity) (hk1_bound hκ ht) (hk2_bound hκ ht) hf hM x
  have hC2 : ∀ t, 0 < t → Continuous
      (fun x => ∫ y, heatKernel κ t (x - y) * ((2 * (x - y) / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t)) *
        f y) := fun t ht =>
    conv_continuous (k := fun z => heatKernel κ t z * ((2 * z / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t)))
      (by have := hkc t; fun_prop) (by positivity) (hk2_bound hκ ht) hf hM
  have hd1 : ∀ t, 0 < t → deriv (fun x => u x t) =
      fun x => ∫ y, heatKernel κ t (x - y) * (-(2 * (x - y)) / (4 * κ * t)) * f y :=
    fun t ht => funext fun x => (hD1 t ht x).deriv
  have hd2 : ∀ t, 0 < t → deriv (deriv (fun x => u x t)) =
      fun x => ∫ y, heatKernel κ t (x - y) * ((2 * (x - y) / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t)) *
        f y := by
    intro t ht
    rw [hd1 t ht]
    exact funext fun x => (hD2 t ht x).deriv
  refine ⟨fun t ht => ?_, fun x t ht => ?_, fun x => hk_conv_tendsto hκ hf hM x⟩
  · rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
    refine ⟨fun x => (hD1 t ht x).differentiableAt, by simp, ?_⟩
    rw [contDiff_one_iff_deriv, hd1 t ht]
    refine ⟨fun x => (hD2 t ht x).differentiableAt, ?_⟩
    rw [show deriv (fun x => ∫ y, heatKernel κ t (x - y) * (-(2 * (x - y)) / (4 * κ * t)) * f y)
      = _ from funext fun x => (hD2 t ht x).deriv]
    exact hC2 t ht
  · rw [hd2 t ht]
    refine (conv_hasDerivAt_t hκ hf hM x t ht).congr_deriv ?_
    rw [← integral_const_mul]
    congr 1; funext y
    field_simp
    ring

/-- A point of dye spreads into a bell curve: for κ > 0 and t > 0 the heat kernel solves
u_t = κ u_xx, encloses total 1, and has mean squared distance 2κt, so its width is √(2κt). -/
theorem heat_kernel_is_bell_of_width (κ t : ℝ) (hκ : 0 < κ) (ht : 0 < t) :
    (∀ x, HasDerivAt (fun s => heatKernel κ s x)
      (κ * deriv (deriv (fun z => heatKernel κ t z)) x) t) ∧
    (∫ x, heatKernel κ t x) = 1 ∧
    (∫ x, x ^ 2 * heatKernel κ t x) = 2 * κ * t := by
  have hd1 : deriv (fun z => heatKernel κ t z) = fun z => heatKernel κ t z * (-(2 * z) / (4 * κ * t)) :=
    funext fun z => (hk_hasDerivAt_x κ t z).deriv
  have hd2 : deriv (deriv (fun z => heatKernel κ t z)) =
      fun z => heatKernel κ t z * ((2 * z / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t)) := by
    rw [hd1]; exact funext fun z => (hk1_hasDerivAt_x κ t z).deriv
  set v : NNReal := Real.toNNReal (2 * κ * t) with hv_def
  have hvc : (v : ℝ) = 2 * κ * t := Real.coe_toNNReal _ (by positivity)
  have hv : v ≠ 0 := by
    rw [ne_eq, ← NNReal.coe_eq_zero, hvc]; positivity
  have hpdf : ∀ x, heatKernel κ t x = ProbabilityTheory.gaussianPDFReal 0 v x := by
    intro x
    simp only [ProbabilityTheory.gaussianPDFReal, hvc, sub_zero, heatKernel]
    rw [div_eq_mul_inv, mul_comm]
    congr 2 <;> ring_nf
  refine ⟨fun x => ?_, ?_, ?_⟩
  · rw [hd2]
    refine (hk_hasDerivAt_t κ t x hκ ht).congr_deriv ?_
    field_simp
    ring
  · simp_rw [hpdf]
    exact ProbabilityTheory.integral_gaussianPDFReal_eq_one 0 hv
  · have h1 := ProbabilityTheory.variance_fun_id_gaussianReal (μ := 0) (v := v)
    rw [ProbabilityTheory.variance_eq_integral measurable_id'.aemeasurable] at h1
    simp only [ProbabilityTheory.integral_id_gaussianReal, sub_zero] at h1
    rw [ProbabilityTheory.integral_gaussianReal_eq_integral_smul hv] at h1
    simp_rw [hpdf]
    simp only [smul_eq_mul] at h1
    rw [show (fun x => x ^ 2 * ProbabilityTheory.gaussianPDFReal 0 v x) =
      fun x => ProbabilityTheory.gaussianPDFReal 0 v x * x ^ 2 from funext fun x => mul_comm _ _]
    rw [h1]; exact hvc

/-- A step start (strength 1 left of 0, clear water right) becomes the error-function profile
u(x, t) = ½(1 − erf(x/(2√(κt)))); at the old edge x = 0 the strength is exactly one half. -/
theorem step_start_gives_erf_profile (κ t : ℝ) (hκ : 0 < κ) (ht : 0 < t) :
    (∀ x, (∫ y, heatKernel κ t (x - y) * (Set.Iic (0 : ℝ)).indicator 1 y)
      = 1 / 2 * (1 - erf (x / (2 * Real.sqrt (κ * t))))) ∧
    (∫ y, heatKernel κ t (0 - y) * (Set.Iic (0 : ℝ)).indicator 1 y) = 1 / 2 := by
  have hint : Integrable (fun z => heatKernel κ t z) := by
    have := conv_integrable (hkc_of κ t) (by positivity : 0 < 1 / (2 * (4 * κ * t)))
      (hk0_bound hκ ht) (f := fun _ => (1 : ℝ)) continuous_const (M := 1) (fun _ => by norm_num) 0
    simpa using this.comp_neg
  have hmain : ∀ x, (∫ y, heatKernel κ t (x - y) * (Set.Iic (0 : ℝ)).indicator 1 y)
      = 1 / 2 * (1 - erf (x / (2 * Real.sqrt (κ * t)))) := by
    intro x
    have h1 := integral_sub_left_eq_self (μ := volume)
      (fun z => heatKernel κ t z * (Set.Iic (0 : ℝ)).indicator 1 (x - z)) x
    simp only [sub_sub_cancel] at h1
    rw [h1]
    have h2 : (fun z => heatKernel κ t z * (Set.Iic (0 : ℝ)).indicator 1 (x - z)) =
        (Set.Ici x).indicator (fun z => heatKernel κ t z) := by
      funext z
      by_cases hz : x ≤ z
      · rw [Set.indicator_of_mem (show x - z ∈ Set.Iic (0 : ℝ) by simp; linarith),
          Set.indicator_of_mem (show z ∈ Set.Ici x from hz)]
        simp
      · rw [Set.indicator_of_notMem (show x - z ∉ Set.Iic (0 : ℝ) by simp; linarith),
          Set.indicator_of_notMem (show z ∉ Set.Ici x from hz)]
        simp
    rw [h2, integral_indicator measurableSet_Ici, integral_Ici_eq_integral_Ioi]
    have h3 := intervalIntegral.integral_Ioi_sub_Ioi' (hint.integrableOn (s := Set.Ioi 0))
      (hint.integrableOn (s := Set.Ioi x))
    have hσ : 0 < 2 * Real.sqrt (κ * t) := by
      have : 0 < Real.sqrt (κ * t) := Real.sqrt_pos.2 (by positivity)
      linarith
    have hpi : 0 < Real.sqrt π := Real.sqrt_pos.2 pi_pos
    have hform : ∀ z, heatKernel κ t z =
        1 / (Real.sqrt π * (2 * Real.sqrt (κ * t))) * exp (-(z / (2 * Real.sqrt (κ * t))) ^ 2) := by
      intro z
      have hsq : Real.sqrt (κ * t) ^ 2 = κ * t := Real.sq_sqrt (by positivity)
      unfold heatKernel
      rw [sqrt_four_pi_kt κ t, div_pow, mul_pow, hsq]
      field_simp
      ring_nf
    have hhalf : ∫ z in Set.Ioi (0 : ℝ), heatKernel κ t z = 1 / 2 := by
      have := integral_gaussian_Ioi (1 / (4 * κ * t))
      simp_rw [heatKernel]
      have e : ∀ z : ℝ, exp (-z ^ 2 / (4 * κ * t)) / Real.sqrt (4 * π * κ * t) =
          1 / Real.sqrt (4 * π * κ * t) * exp (-(1 / (4 * κ * t)) * z ^ 2) := by
        intro z; rw [div_eq_inv_mul, one_div]; congr 2; ring
      simp_rw [e]
      rw [integral_const_mul, this, show π / (1 / (4 * κ * t)) = 4 * π * κ * t by field_simp]
      have : 0 < Real.sqrt (4 * π * κ * t) := Real.sqrt_pos.2 (by positivity)
      field_simp
    have hint0x : ∫ z in (0 : ℝ)..x, heatKernel κ t z =
        1 / Real.sqrt π * ∫ s in (0 : ℝ)..x / (2 * Real.sqrt (κ * t)), exp (-s ^ 2) := by
      simp_rw [hform]
      rw [intervalIntegral.integral_const_mul,
        intervalIntegral.integral_comp_div (fun s => exp (-s ^ 2)) hσ.ne', zero_div, smul_eq_mul]
      field_simp
    unfold erf
    rw [hhalf, hint0x] at h3
    have h4 : ∫ z in Set.Ioi x, heatKernel κ t z =
        1 / 2 - 1 / Real.sqrt π * ∫ s in (0 : ℝ)..x / (2 * Real.sqrt (κ * t)), exp (-s ^ 2) := by
      linarith
    rw [h4]; ring
  refine ⟨hmain, ?_⟩
  rw [hmain 0]
  simp [erf]

-- The card's exact arithmetic, with κ = 1/100 cm^2/s.
-- 4κt at t = 100 s is 4 cm^2.
example : (4 : ℚ) * (1 / 100) * 100 = 4 := by norm_num
-- Squared widths 2κt: 2 cm^2 at 100 s, 4 cm^2 at 200 s, 8 cm^2 at 400 s.
example : (2 : ℚ) * (1 / 100) * 100 = 2 := by norm_num
example : (2 : ℚ) * (1 / 100) * 200 = 4 := by norm_num
example : (2 : ℚ) * (1 / 100) * 400 = 8 := by norm_num
-- Four times the wait, twice the width: √8 = 2√2.
example : Real.sqrt 8 = 2 * Real.sqrt 2 := by
  rw [show (8 : ℝ) = 2 ^ 2 * 2 by norm_num, Real.sqrt_mul (by norm_num), Real.sqrt_sq (by norm_num)]
-- The halving walk: cells a = 1/10 cm, tick a^2/(2κ) = 1/2 s; 200 ticks make 100 s and add 2 cm^2.
example : ((1 : ℚ) / 10) ^ 2 / (2 * (1 / 100)) = 1 / 2 := by norm_num
example : (200 : ℚ) * (1 / 2) = 100 ∧ (200 : ℚ) * (1 / 10) ^ 2 = 2 := by norm_num

#print axioms hk_hasDerivAt_x
#print axioms hk1_hasDerivAt_x
#print axioms hk_hasDerivAt_t
#print axioms sq_mul_exp_neg_le
#print axioms poly_mul_exp_neg_le
#print axioms exp_shift_le
#print axioms conv_pointwise_bound
#print axioms integrable_shift_bound
#print axioms conv_integrable
#print axioms conv_hasDerivAt
#print axioms conv_continuous
#print axioms hk_nonneg
#print axioms hk_poly_bound
#print axioms hk0_bound
#print axioms hk1_bound
#print axioms hk2_bound
#print axioms hkt_bound
#print axioms conv_hasDerivAt_t
#print axioms hkc_of
#print axioms sqrt_four_pi_kt
#print axioms hk_rescale
#print axioms hk_conv_rescale
#print axioms hk_conv_tendsto
#print axioms heat_kernel_blend_solves_heat_equation
#print axioms heat_kernel_is_bell_of_width
#print axioms step_start_gives_erf_profile
