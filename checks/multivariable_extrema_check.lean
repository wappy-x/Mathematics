-- Extrema in several variables: a smooth lowest or highest point inside a region has zero gradient, the two-input second derivative test sorts a flat spot into strict pit, strict peak or saddle by the signs of D = AC - B^2 and A, and the card's 4 cubic metre bin uses least steel, 12 square metres, exactly at the 2 by 2 base.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Order.Filter.Extr
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp

open Set Filter Topology

theorem sdt_mvt_step {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : E → ℝ} {p : E} {H : E →L[ℝ] E →L[ℝ] ℝ}
    (hdiff : ∀ᶠ x in 𝓝 p, DifferentiableAt ℝ f x)
    (hH : HasFDerivAt (fderiv ℝ f) H p) (hflat : fderiv ℝ f p = 0) {ε : ℝ} (hε : 0 < ε) :
    ∀ᶠ q in 𝓝 p, ∃ τ : ℝ, 0 < τ ∧ τ < 1 ∧
      |f q - f p - τ * H (q - p) (q - p)| ≤ τ * ε * ‖q - p‖ ^ 2 := by
  have hlo := hH.isLittleO.bound hε
  obtain ⟨r, hr, hball⟩ := Metric.eventually_nhds_iff_ball.1 (hdiff.and hlo)
  filter_upwards [Metric.ball_mem_nhds p hr] with q hq
  have hseg : ∀ t ∈ Icc (0:ℝ) 1, p + t • (q - p) ∈ Metric.ball p r := by
    intro t ht
    rw [Metric.mem_ball, dist_eq_norm] at hq ⊢
    rw [add_sub_cancel_left, norm_smul, Real.norm_eq_abs, abs_of_nonneg ht.1]
    calc t * ‖q - p‖ ≤ 1 * ‖q - p‖ := by gcongr; exact ht.2
      _ < r := by simpa using hq
  have hderiv : ∀ t ∈ Icc (0:ℝ) 1, HasDerivAt (fun t : ℝ => f (p + t • (q - p)))
      (fderiv ℝ f (p + t • (q - p)) (q - p)) t := by
    intro t ht
    have h1 : HasDerivAt (fun t : ℝ => p + t • (q - p)) (q - p) t := by
      simpa using ((hasDerivAt_id t).smul_const (q - p)).const_add p
    exact ((hball _ (hseg t ht)).1.hasFDerivAt).comp_hasDerivAt t h1
  obtain ⟨τ, hτ, hτeq⟩ := exists_hasDerivAt_eq_slope (fun t : ℝ => f (p + t • (q - p)))
    (fun t => fderiv ℝ f (p + t • (q - p)) (q - p)) zero_lt_one
    (fun t ht => (hderiv t ht).continuousAt.continuousWithinAt)
    (fun t ht => hderiv t (Ioo_subset_Icc_self ht))
  simp only [one_smul, zero_smul, add_zero, add_sub_cancel, sub_zero, div_one] at hτeq
  refine ⟨τ, hτ.1, hτ.2, ?_⟩
  have hb := (hball _ (hseg τ (Ioo_subset_Icc_self hτ))).2
  rw [hflat, sub_zero, add_sub_cancel_left, map_smul] at hb
  rw [← hτeq]
  have : fderiv ℝ f (p + τ • (q - p)) (q - p) - τ * H (q - p) (q - p)
      = (fderiv ℝ f (p + τ • (q - p)) - τ • H (q - p)) (q - p) := by simp
  rw [this]
  calc _ ≤ ‖fderiv ℝ f (p + τ • (q - p)) - τ • H (q - p)‖ * ‖q - p‖ := by
        rw [← Real.norm_eq_abs]; exact ContinuousLinearMap.le_opNorm _ _
    _ ≤ ε * ‖τ • (q - p)‖ * ‖q - p‖ := by gcongr
    _ = τ * ε * ‖q - p‖ ^ 2 := by rw [norm_smul, Real.norm_eq_abs, abs_of_pos hτ.1]; ring

theorem sdt_strict_min {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : E → ℝ} {p : E} {H : E →L[ℝ] E →L[ℝ] ℝ}
    (hdiff : ∀ᶠ x in 𝓝 p, DifferentiableAt ℝ f x)
    (hH : HasFDerivAt (fderiv ℝ f) H p) (hflat : fderiv ℝ f p = 0) {c : ℝ} (hc : 0 < c)
    (hpos : ∀ h, c * ‖h‖ ^ 2 ≤ H h h) : ∀ᶠ q in 𝓝[≠] p, f p < f q := by
  have hstep := sdt_mvt_step hdiff hH hflat (half_pos hc)
  filter_upwards [nhdsWithin_le_nhds hstep, eventually_mem_nhdsWithin] with q hτq hq
  obtain ⟨τ, hτ0, -, hτ⟩ := hτq
  have hq' : 0 < ‖q - p‖ := norm_pos_iff.2 (sub_ne_zero.2 hq)
  have h1 := hpos (q - p)
  have h2 := (abs_le.1 hτ).1
  have h3 := mul_le_mul_of_nonneg_left h1 hτ0.le
  have h4 : 0 < τ * c * ‖q - p‖ ^ 2 := by positivity
  nlinarith

theorem sdt_strict_max {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : E → ℝ} {p : E} {H : E →L[ℝ] E →L[ℝ] ℝ}
    (hdiff : ∀ᶠ x in 𝓝 p, DifferentiableAt ℝ f x)
    (hH : HasFDerivAt (fderiv ℝ f) H p) (hflat : fderiv ℝ f p = 0) {c : ℝ} (hc : 0 < c)
    (hneg : ∀ h, H h h ≤ -(c * ‖h‖ ^ 2)) : ∀ᶠ q in 𝓝[≠] p, f q < f p := by
  have hstep := sdt_mvt_step hdiff hH hflat (half_pos hc)
  filter_upwards [nhdsWithin_le_nhds hstep, eventually_mem_nhdsWithin] with q hτq hq
  obtain ⟨τ, hτ0, -, hτ⟩ := hτq
  have hq' : 0 < ‖q - p‖ := norm_pos_iff.2 (sub_ne_zero.2 hq)
  have h1 := hneg (q - p)
  have h2 := (abs_le.1 hτ).2
  have h3 := mul_le_mul_of_nonneg_left h1 hτ0.le
  have h4 : 0 < τ * c * ‖q - p‖ ^ 2 := by positivity
  nlinarith

theorem sdt_tendsto_line {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (p w : E) :
    Tendsto (fun s : ℝ => p + s • w) (𝓝[≠] 0) (𝓝 p) := by
  have : Tendsto (fun s : ℝ => p + s • w) (𝓝 0) (𝓝 (p + (0:ℝ) • w)) :=
    (continuous_const.add (continuous_id.smul continuous_const)).tendsto 0
  simpa using this.mono_left nhdsWithin_le_nhds

theorem sdt_not_min {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : E → ℝ} {p : E} {H : E →L[ℝ] E →L[ℝ] ℝ}
    (hdiff : ∀ᶠ x in 𝓝 p, DifferentiableAt ℝ f x)
    (hH : HasFDerivAt (fderiv ℝ f) H p) (hflat : fderiv ℝ f p = 0) {w : E}
    (hw : H w w < 0) : ¬ IsLocalMin f p := by
  intro hmin
  have hw0 : w ≠ 0 := by rintro rfl; simp at hw
  have hwn : 0 < ‖w‖ := norm_pos_iff.2 hw0
  have hε : 0 < -H w w / (2 * ‖w‖ ^ 2) := by
    apply div_pos (by linarith) (by positivity)
  have hεw : -H w w / (2 * ‖w‖ ^ 2) * ‖w‖ ^ 2 = -H w w / 2 := by field_simp
  have hmin' : ∀ᶠ y in 𝓝 p, f p ≤ f y := hmin
  obtain ⟨s, hs, ⟨τ, hτ0, -, hτ⟩, hle⟩ := (eventually_mem_nhdsWithin.and
    (((sdt_tendsto_line p w).eventually (sdt_mvt_step hdiff hH hflat hε)).and
      ((sdt_tendsto_line p w).eventually hmin'))).exists
  simp only [add_sub_cancel_left, map_smul, FunLike.coe_smul, Pi.smul_apply, smul_eq_mul,
    norm_smul, Real.norm_eq_abs] at hτ
  have hs2 : 0 < s ^ 2 := by
    have : s ≠ 0 := hs
    positivity
  have h2 := (abs_le.1 hτ).2
  have e1 : |s| ^ 2 = s ^ 2 := sq_abs s
  have e2 : τ * (-H w w / (2 * ‖w‖ ^ 2)) * (|s| * ‖w‖) ^ 2 = τ * s ^ 2 * (-H w w / 2) := by
    rw [mul_pow, e1, ← hεw]; ring
  rw [e2] at h2
  have h5 : 0 < τ * s ^ 2 * (-H w w) := by
    have : 0 < -H w w := by linarith
    positivity
  nlinarith

theorem sdt_not_max {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : E → ℝ} {p : E} {H : E →L[ℝ] E →L[ℝ] ℝ}
    (hdiff : ∀ᶠ x in 𝓝 p, DifferentiableAt ℝ f x)
    (hH : HasFDerivAt (fderiv ℝ f) H p) (hflat : fderiv ℝ f p = 0) {w : E}
    (hw : 0 < H w w) : ¬ IsLocalMax f p := by
  intro hmax
  have hw0 : w ≠ 0 := by rintro rfl; simp at hw
  have hwn : 0 < ‖w‖ := norm_pos_iff.2 hw0
  have hε : 0 < H w w / (2 * ‖w‖ ^ 2) := by
    apply div_pos hw (by positivity)
  have hεw : H w w / (2 * ‖w‖ ^ 2) * ‖w‖ ^ 2 = H w w / 2 := by field_simp
  have hmax' : ∀ᶠ y in 𝓝 p, f y ≤ f p := hmax
  obtain ⟨s, hs, ⟨τ, hτ0, -, hτ⟩, hle⟩ := (eventually_mem_nhdsWithin.and
    (((sdt_tendsto_line p w).eventually (sdt_mvt_step hdiff hH hflat hε)).and
      ((sdt_tendsto_line p w).eventually hmax'))).exists
  simp only [add_sub_cancel_left, map_smul, FunLike.coe_smul, Pi.smul_apply, smul_eq_mul,
    norm_smul, Real.norm_eq_abs] at hτ
  have hs2 : 0 < s ^ 2 := by
    have : s ≠ 0 := hs
    positivity
  have h2 := (abs_le.1 hτ).1
  have e1 : |s| ^ 2 = s ^ 2 := sq_abs s
  have e2 : τ * (H w w / (2 * ‖w‖ ^ 2)) * (|s| * ‖w‖) ^ 2 = τ * s ^ 2 * (H w w / 2) := by
    rw [mul_pow, e1, ← hεw]; ring
  rw [e2] at h2
  have h5 : 0 < τ * s ^ 2 * H w w := by positivity
  nlinarith

theorem sdt_indefinite_neg (A B C : ℝ) (hD : A * C - B ^ 2 < 0) :
    ∃ a b : ℝ, A * a ^ 2 + 2 * B * a * b + C * b ^ 2 < 0 := by
  rcases lt_trichotomy A 0 with hA | hA | hA
  · exact ⟨1, 0, by linarith⟩
  · have hB : B ≠ 0 := by rintro rfl; subst hA; linarith
    refine ⟨(-1 - C) / (2 * B), 1, ?_⟩
    subst hA
    have : 2 * B * ((-1 - C) / (2 * B)) * 1 = -1 - C := by field_simp
    nlinarith
  · refine ⟨-B, A, ?_⟩
    nlinarith

theorem sdt_indefinite_pos (A B C : ℝ) (hD : A * C - B ^ 2 < 0) :
    ∃ a b : ℝ, 0 < A * a ^ 2 + 2 * B * a * b + C * b ^ 2 := by
  obtain ⟨a, b, h⟩ := sdt_indefinite_neg (-A) (-B) (-C) (by nlinarith)
  exact ⟨a, b, by nlinarith⟩

/-- **The second derivative test, two inputs.** Let f be a function of two inputs with
continuous second partial derivatives near the point p (f is twice continuously
differentiable at p), and let p be a flat spot: both slopes of f are zero there (the
derivative of f at p is zero). Write A for the second rate in x, B for the mixed rate
(x then y) and C for the second rate in y, all at p, and D = AC − B^2. Then:
* D > 0 and A > 0: p is a pit, a strict local minimum (every nearby point other than p has a
  larger value);
* D > 0 and A < 0: p is a peak, a strict local maximum (every nearby point other than p has a
  smaller value);
* D < 0: p is a saddle: it is neither a local minimum nor a local maximum, since arbitrarily
  close to p some points lie higher and some lower. -/
theorem second_derivative_test_two_variables {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ}
    (hf : ContDiffAt ℝ 2 f p) (hflat : fderiv ℝ f p = 0) :
    let A := fderiv ℝ (fderiv ℝ f) p (1, 0) (1, 0)
    let B := fderiv ℝ (fderiv ℝ f) p (1, 0) (0, 1)
    let C := fderiv ℝ (fderiv ℝ f) p (0, 1) (0, 1)
    (0 < A * C - B ^ 2 → 0 < A → ∀ᶠ q in 𝓝[≠] p, f p < f q) ∧
    (0 < A * C - B ^ 2 → A < 0 → ∀ᶠ q in 𝓝[≠] p, f q < f p) ∧
    (A * C - B ^ 2 < 0 → ¬ IsLocalMin f p ∧ ¬ IsLocalMax f p) := by
  dsimp only
  have hdiff : ∀ᶠ x in 𝓝 p, DifferentiableAt ℝ f x :=
    (hf.eventually (by simp)).mono fun x hx => hx.differentiableAt (by simp)
  have hH : HasFDerivAt (fderiv ℝ f) (fderiv ℝ (fderiv ℝ f) p) p :=
    ((hf.fderiv_right (m := 1) (by norm_num)).differentiableAt (by simp)).hasFDerivAt
  have hsymm : IsSymmSndFDerivAt ℝ f p := hf.isSymmSndFDerivAt (by simp)
  set H := fderiv ℝ (fderiv ℝ f) p with hHdef
  set A := H (1, 0) (1, 0)
  set B := H (1, 0) (0, 1)
  set C := H (0, 1) (0, 1)
  have hQ : ∀ a b : ℝ, H (a, b) (a, b) = A * a ^ 2 + 2 * B * a * b + C * b ^ 2 := by
    intro a b
    have e : ((a, b) : ℝ × ℝ) = a • ((1 : ℝ), (0 : ℝ)) + b • ((0 : ℝ), (1 : ℝ)) := by simp
    have e2 : H (0, 1) (1, 0) = B := hsymm (0, 1) (1, 0)
    rw [e]
    simp only [map_add, map_smul, FunLike.coe_add, Pi.add_apply, FunLike.coe_smul, Pi.smul_apply,
      smul_eq_mul, e2]
    ring
  have hn : ∀ h : ℝ × ℝ, ‖h‖ ^ 2 ≤ h.1 ^ 2 + h.2 ^ 2 := by
    intro h
    rw [Prod.norm_def, Real.norm_eq_abs, Real.norm_eq_abs]
    rcases max_cases |h.1| |h.2| with ⟨h1, _⟩ | ⟨h1, _⟩ <;> rw [h1] <;>
      nlinarith [sq_abs h.1, sq_abs h.2, sq_nonneg h.1, sq_nonneg h.2]
  refine ⟨fun hD hA => ?_, fun hD hA => ?_, fun hD => ?_⟩
  · have hC : 0 < C := by nlinarith [sq_nonneg B]
    have hAC : 0 < A + C := by linarith
    refine sdt_strict_min hdiff hH hflat (c := (A * C - B ^ 2) / (A + C)) (by positivity) ?_
    rintro ⟨a, b⟩
    rw [hQ, div_mul_eq_mul_div, div_le_iff₀ hAC]
    have := hn (a, b)
    nlinarith [sq_nonneg (A * a + B * b), sq_nonneg (B * a + C * b)]
  · have hC : C < 0 := by nlinarith [sq_nonneg B]
    have hAC : 0 < -(A + C) := by linarith
    refine sdt_strict_max hdiff hH hflat (c := (A * C - B ^ 2) / -(A + C)) (by positivity) ?_
    rintro ⟨a, b⟩
    rw [hQ, div_mul_eq_mul_div, le_neg, div_le_iff₀ hAC]
    have := hn (a, b)
    nlinarith [sq_nonneg (A * a + B * b), sq_nonneg (B * a + C * b)]
  · obtain ⟨a, b, hneg⟩ := sdt_indefinite_neg A B C hD
    obtain ⟨a', b', hpos⟩ := sdt_indefinite_pos A B C hD
    exact ⟨sdt_not_min hdiff hH hflat (w := (a, b)) (by rw [hQ]; exact hneg),
      sdt_not_max hdiff hH hflat (w := (a', b')) (by rw [hQ]; exact hpos)⟩

/-- **A best point inside the region is flat.** Let U be an open region of n-dimensional
space and f a function that has a derivative at the point p of U. If p is a lowest or a
highest point of f among the points of U near p (a local extremum of f on U), then every
partial slope of f at p is zero: the gradient of f at p is the zero vector. -/
theorem gradient_eq_zero_of_local_extremum {n : ℕ} {U : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} {p : EuclideanSpace ℝ (Fin n)}
    (hU : IsOpen U) (hp : p ∈ U) (hf : DifferentiableAt ℝ f p) (hext : IsLocalExtrOn f U p) :
    gradient f p = 0 := by
  have h : fderiv ℝ f p = 0 := (hext.isLocalExtr (hU.mem_nhds hp)).fderiv_eq_zero
  simp [gradient, h]

/-- **The cheapest bin.** An open-top bin holding 4 cubic metres with a base x by y metres
(both positive) and height 4/(xy) uses S(x, y) = xy + 8/x + 8/y square metres of steel.
Over all positive x and y, the least steel is used by the 2 by 2 base: S(2, 2) = 12 is the
global minimum, and no other base reaches it. -/
theorem open_bin_global_minimum :
    let S : ℝ × ℝ → ℝ := fun q => q.1 * q.2 + 8 / q.1 + 8 / q.2
    S (2, 2) = 12 ∧
    IsMinOn S {q | 0 < q.1 ∧ 0 < q.2} (2, 2) ∧
    ∀ q : ℝ × ℝ, 0 < q.1 → 0 < q.2 → S q = 12 → q = (2, 2) := by
  intro S
  have key : ∀ x y : ℝ, 0 < x → 0 < y →
      S (x, y) - 12 = (x ^ 2 * y ^ 2 + 8 * x + 8 * y - 12 * x * y) / (x * y) := by
    intro x y hx hy
    simp only [S]
    field_simp
    ring
  have poly : ∀ x y : ℝ, 0 < x → 0 < y → 0 ≤ x ^ 2 * y ^ 2 + 8 * x + 8 * y - 12 * x * y := by
    intro x y hx hy
    nlinarith [sq_nonneg (x - 2), sq_nonneg (y - 2), sq_nonneg (x - y), sq_nonneg (x * y - 4),
      mul_pos hx hy, mul_pos (mul_pos hx hy) hx, sq_nonneg (x + y - 4)]
  have h12 : S (2, 2) = 12 := by simp only [S]; norm_num
  refine ⟨h12, ?_, ?_⟩
  · rw [isMinOn_iff]
    rintro ⟨x, y⟩ ⟨hx, hy⟩
    have h1 := key x y hx hy
    have h2 : 0 ≤ (x ^ 2 * y ^ 2 + 8 * x + 8 * y - 12 * x * y) / (x * y) :=
      div_nonneg (poly x y hx hy) (mul_pos hx hy).le
    rw [h12]
    linarith
  · rintro ⟨x, y⟩ hx hy hS
    have h1 := key x y hx hy
    rw [hS, sub_self, eq_comm, div_eq_zero_iff] at h1
    have h0 : x ^ 2 * y ^ 2 + 8 * x + 8 * y - 12 * x * y = 0 := by
      rcases h1 with h | h
      · exact h
      · exact absurd h (mul_pos hx hy).ne'
    have hxy : (x - y) ^ 2 = 0 := by
      nlinarith [sq_nonneg (x - 2), sq_nonneg (y - 2), sq_nonneg (x - y), sq_nonneg (x * y - 4),
        mul_pos hx hy, mul_pos (mul_pos hx hy) hx, sq_nonneg (x + y - 4)]
    have hyx : y = x := by nlinarith [pow_eq_zero_iff (n := 2) (two_ne_zero) |>.1 hxy]
    subst hyx
    have hf : y * ((y - 2) ^ 2 * (y + 4)) = 0 := by linear_combination h0
    rcases mul_eq_zero.1 hf with h | h
    · exact absurd h hx.ne'
    rcases mul_eq_zero.1 h with h | h
    · have : y = 2 := by nlinarith [pow_eq_zero_iff (n := 2) (two_ne_zero) |>.1 h]
      subst this; rfl
    · linarith

-- The flat-spot equations y = 8/x^2 and x = 8/y^2 hold at (2, 2): 8/4 = 2, and x^3 = 8.
example : (8 : ℚ) / 2 ^ 2 = 2 ∧ (2 : ℚ) ^ 3 = 8 := by norm_num
-- Height 4/(2 × 2) = 1 metre; steel 4 + 8/2 + 8/2 = 12 square metres, split 4, 4, 4.
example : (4 : ℚ) / (2 * 2) = 1 ∧ (2 : ℚ) * 2 + 8 / 2 + 8 / 2 = 12 := by norm_num
-- Hessian at (2, 2): A = C = 16/2^3 = 2, B = 1; D = 2 × 2 − 1 × 1 = 3 > 0 with A > 0: a pit.
example : (16 : ℚ) / 2 ^ 3 = 2 ∧ (2 : ℤ) * 2 - 1 * 1 = 3 := by norm_num
-- Negated cost: A = −2, D = (−2)(−2) − (−1)^2 = 3 > 0 with A < 0: a peak.
example : (-2 : ℤ) * (-2) - (-1) ^ 2 = 3 := by norm_num
-- Eigenvalues of the table [[2, 1], [1, 2]]: 3 along (1, 1) and 1 along (1, −1).
example : (2 * 1 + 1 * 1 : ℤ) = 3 * 1 ∧ (1 * 1 + 2 * 1 : ℤ) = 3 * 1 ∧
    (2 * 1 + 1 * (-1) : ℤ) = 1 * 1 ∧ (1 * 1 + 2 * (-1) : ℤ) = 1 * (-1) := by norm_num
-- The fence: a side of 8/13 makes its walls 8/(8/13) = 13; the far fence 13^2/8 = 169/8.
example : (8 : ℚ) / (8 / 13) = 13 ∧ (13 : ℚ) ^ 2 / 8 = 169 / 8 := by norm_num
-- Saddle: x^2 + 3xy + y^2 has A = C = 2, B = 3, so D = 2 × 2 − 3^2 = −5 < 0.
example : (2 : ℤ) * 2 - 3 ^ 2 = -5 := by norm_num
-- Local is not global: x^2 + y^2 − x^4 is 0 at (0, 0) but 2^2 + 0^2 − 2^4 = −12 at (2, 0).
example : (2 : ℤ) ^ 2 + 0 ^ 2 - 2 ^ 4 = -12 := by norm_num

#print axioms sdt_mvt_step
#print axioms sdt_strict_min
#print axioms sdt_strict_max
#print axioms sdt_tendsto_line
#print axioms sdt_not_min
#print axioms sdt_not_max
#print axioms sdt_indefinite_neg
#print axioms sdt_indefinite_pos
#print axioms second_derivative_test_two_variables
#print axioms gradient_eq_zero_of_local_extremum
#print axioms open_bin_global_minimum
