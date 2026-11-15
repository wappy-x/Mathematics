-- The heat kernel: in any dimension d the bell G(x, t) = (4πκt)^(-d/2) e^(-|x|²/(4κt)) holds one unit of heat, solves u_t = κΔu and starts as a point mass, convolving a start with it solves the heat equation and tends to that start, and a solution that starts at 0 and grows no faster than M e^(a|x|²) is 0.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.SpecialFunctions.Gaussian.FourierTransform
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.DerivativeTest

open MeasureTheory Filter Topology Real Laplacian
open scoped ContDiff

/-- The heat kernel in `d` dimensions with diffusivity `κ`:
`G(x, t) = (4πκt)^(-d/2) · e^(-|x|²/(4κt))`, the temperature at the point `x` at time `t > 0`
grown from one unit of heat placed at the origin. -/
noncomputable def heatKernel (d : ℕ) (κ : ℝ) (x : EuclideanSpace ℝ (Fin d)) (t : ℝ) : ℝ :=
  (4 * π * κ * t) ^ (-(d : ℝ) / 2) * exp (-‖x‖ ^ 2 / (4 * κ * t))

-- Helper definitions and lemmas used by the three theorems below.

noncomputable def gau {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) : ℝ :=
  exp (β * ‖x - y‖ ^ 2)

noncomputable def innerR (d : ℕ) :
    EuclideanSpace ℝ (Fin d) →L[ℝ] EuclideanSpace ℝ (Fin d) →L[ℝ] ℝ := innerSL ℝ

theorem innerR_apply {d : ℕ} (v w : EuclideanSpace ℝ (Fin d)) : innerR d v w = inner ℝ v w := rfl

noncomputable def Dgau {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    EuclideanSpace ℝ (Fin d) →L[ℝ] ℝ :=
  (2 * β * gau β y x) • innerSL ℝ (x - y)

noncomputable def D2gau {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    EuclideanSpace ℝ (Fin d) →L[ℝ] EuclideanSpace ℝ (Fin d) →L[ℝ] ℝ :=
  (2 * β * gau β y x) • innerR d
    + ((2 * β) • Dgau β y x).smulRight (innerSL ℝ (x - y))

theorem hasFDerivAt_gau {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    HasFDerivAt (gau β y) (Dgau β y x) x := by
  have h1 : HasFDerivAt (fun z : EuclideanSpace ℝ (Fin d) => ‖z - y‖ ^ 2)
      (2 • (innerSL ℝ (x - y)).comp (ContinuousLinearMap.id ℝ _)) x :=
    HasFDerivAt.norm_sq ((hasFDerivAt_id x).sub_const y)
  have h2 := (h1.const_mul β).exp
  refine HasFDerivAt.congr_fderiv h2 ?_
  unfold Dgau
  ext v
  simp [gau]
  ring

theorem hasFDerivAt_Dgau {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    HasFDerivAt (Dgau β y) (D2gau β y x) x := by
  have h1 : HasFDerivAt (fun z : EuclideanSpace ℝ (Fin d) => 2 * β * gau β y z)
      ((2 * β) • Dgau β y x) x := (hasFDerivAt_gau β y x).const_mul (2 * β)
  have h2 : HasFDerivAt (fun z : EuclideanSpace ℝ (Fin d) => innerSL ℝ (z - y))
      (innerSL ℝ) x := by
    have := ((innerSL ℝ (E := EuclideanSpace ℝ (Fin d))).hasFDerivAt (x := x - y)).comp x
      ((hasFDerivAt_id x).sub_const y)
    exact this
  have h3 := h1.smul h2
  exact h3

theorem D2gau_apply {d : ℕ} (β : ℝ) (y x v w : EuclideanSpace ℝ (Fin d)) :
    D2gau β y x v w = (2 * β * gau β y x) * inner ℝ v w
      + 4 * β ^ 2 * gau β y x * (inner ℝ (x - y) v * inner ℝ (x - y) w) := by
  simp [D2gau, Dgau, innerR_apply, inner_sub_left]
  ring

theorem sum_D2gau {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    ∑ i, D2gau β y x (EuclideanSpace.basisFun (Fin d) ℝ i) (EuclideanSpace.basisFun (Fin d) ℝ i)
      = (2 * β * d + 4 * β ^ 2 * ‖x - y‖ ^ 2) * gau β y x := by
  simp only [D2gau_apply, Finset.sum_add_distrib, ← Finset.mul_sum]
  have h1 : ∀ i, inner ℝ (EuclideanSpace.basisFun (Fin d) ℝ i)
      (EuclideanSpace.basisFun (Fin d) ℝ i) = (1 : ℝ) := fun i => by
    simp
  have h2 := (EuclideanSpace.basisFun (Fin d) ℝ).sum_inner_mul_inner (x - y) (x - y)
  simp only [h1, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, mul_one]
  rw [show ∑ i, inner ℝ (x - y) (EuclideanSpace.basisFun (Fin d) ℝ i) *
      inner ℝ (x - y) (EuclideanSpace.basisFun (Fin d) ℝ i) = ‖x - y‖ ^ 2 by
    rw [← real_inner_self_eq_norm_sq, ← h2]
    congr 1; ext i; rw [real_inner_comm (x - y) (EuclideanSpace.basisFun (Fin d) ℝ i)]]
  ring

theorem norm_Dgau_le {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    ‖Dgau β y x‖ ≤ 2 * |β| * ‖x - y‖ * gau β y x := by
  have hg : 0 < gau β y x := exp_pos _
  rw [Dgau, norm_smul, innerSL_apply_norm, Real.norm_eq_abs, abs_mul, abs_mul,
    abs_of_pos hg]
  norm_num
  exact le_of_eq (by ring)

theorem norm_D2gau_le {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    ‖D2gau β y x‖ ≤ (2 * |β| + 4 * β ^ 2 * ‖x - y‖ ^ 2) * gau β y x := by
  have hg : 0 < gau β y x := exp_pos _
  have h1 : ‖innerR d‖ ≤ 1 := norm_innerSL_le ℝ (E := EuclideanSpace ℝ (Fin d))
  have e1 : ‖(2 * β * gau β y x) • innerR d‖ ≤ 2 * |β| * gau β y x := by
    refine (ContinuousLinearMap.opNorm_smul_le _ _).trans ?_
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_of_pos hg]
    have : |(2:ℝ)| = 2 := by norm_num
    rw [this]
    calc 2 * |β| * gau β y x * ‖innerR d‖ ≤ 2 * |β| * gau β y x * 1 := by gcongr
      _ = _ := by ring
  have e2 : ‖((2 * β) • Dgau β y x).smulRight (innerSL ℝ (x - y))‖
      ≤ 4 * β ^ 2 * ‖x - y‖ ^ 2 * gau β y x := by
    rw [ContinuousLinearMap.norm_smulRight_apply, norm_smul, innerSL_apply_norm,
      Real.norm_eq_abs, abs_mul]
    have : |(2:ℝ)| = 2 := by norm_num
    rw [this]
    calc 2 * |β| * ‖Dgau β y x‖ * ‖x - y‖ ≤ 2 * |β| * (2 * |β| * ‖x - y‖ * gau β y x) * ‖x - y‖ := by
          gcongr; exact norm_Dgau_le β y x
      _ = 4 * |β| ^ 2 * ‖x - y‖ ^ 2 * gau β y x := by ring
      _ = _ := by rw [sq_abs]
  unfold D2gau
  refine (norm_add_le (E := EuclideanSpace ℝ (Fin d) →L[ℝ] EuclideanSpace ℝ (Fin d) →L[ℝ] ℝ)
    _ _).trans ?_
  linarith

theorem laplacian_gau {d : ℕ} (A β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    Δ (fun z => A * gau β y z) x = A * ((2 * β * d + 4 * β ^ 2 * ‖x - y‖ ^ 2) * gau β y x) := by
  have hf : fderiv ℝ (fun z => A * gau β y z) = fun z => A • Dgau β y z := by
    ext1 z; exact ((hasFDerivAt_gau β y z).const_mul A).fderiv
  have hf2 : fderiv ℝ (fderiv ℝ (fun z => A * gau β y z)) x = A • D2gau β y x := by
    rw [hf]; exact ((hasFDerivAt_Dgau β y x).const_smul A).fderiv
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis _ (EuclideanSpace.basisFun (Fin d) ℝ)]
  have : ∀ i, iteratedFDeriv ℝ 2 (fun z => A * gau β y z) x
      ![EuclideanSpace.basisFun (Fin d) ℝ i, EuclideanSpace.basisFun (Fin d) ℝ i] =
      A * D2gau β y x (EuclideanSpace.basisFun (Fin d) ℝ i) (EuclideanSpace.basisFun (Fin d) ℝ i) := by
    intro i; rw [iteratedFDeriv_two_apply]; simp only [hf2]; rfl
  simp only [this, ← Finset.mul_sum, sum_D2gau]


noncomputable instance instCENormEuc2 {d : ℕ} :
    ContinuousENorm (EuclideanSpace ℝ (Fin d) →L[ℝ] EuclideanSpace ℝ (Fin d) →L[ℝ] ℝ) := by
  letI : NormedAddCommGroup (EuclideanSpace ℝ (Fin d) →L[ℝ] EuclideanSpace ℝ (Fin d) →L[ℝ] ℝ) :=
    ContinuousLinearMap.toNormedAddCommGroup
  exact inferInstance

theorem D2gau_sub {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    D2gau β y x = D2gau β 0 (x - y) := by
  simp only [D2gau, Dgau, gau, sub_zero]

theorem continuous_D2gau0 {d : ℕ} (β : ℝ) :
    Continuous (D2gau β (0 : EuclideanSpace ℝ (Fin d))) := by
  have hg : ContDiff ℝ ∞ (gau β (0 : EuclideanSpace ℝ (Fin d))) := by
    have : gau β (0 : EuclideanSpace ℝ (Fin d)) = fun x => exp (β * ‖x‖ ^ 2) := by
      ext x; simp [gau]
    rw [this]
    exact ContDiff.exp (contDiff_const.mul (contDiff_norm_sq ℝ))
  have h1 : fderiv ℝ (gau β (0 : EuclideanSpace ℝ (Fin d))) = Dgau β 0 := by
    ext1 z; exact (hasFDerivAt_gau β 0 z).fderiv
  have h2 : fderiv ℝ (Dgau β (0 : EuclideanSpace ℝ (Fin d))) = D2gau β 0 := by
    ext1 z; exact (hasFDerivAt_Dgau β 0 z).fderiv
  have h3 : ContDiff ℝ ∞ (Dgau β (0 : EuclideanSpace ℝ (Fin d))) := by
    rw [← h1]; exact hg.fderiv_right (by simp)
  rw [← h2]
  exact h3.continuous_fderiv (by simp)

theorem Dgau_sub {d : ℕ} (β : ℝ) (y x : EuclideanSpace ℝ (Fin d)) :
    Dgau β y x = Dgau β 0 (x - y) := by
  simp only [Dgau, gau, sub_zero]

theorem continuous_Dgau0 {d : ℕ} (β : ℝ) :
    Continuous (Dgau β (0 : EuclideanSpace ℝ (Fin d))) := by
  have := fun z => (hasFDerivAt_Dgau β (0 : EuclideanSpace ℝ (Fin d)) z).continuousAt
  exact continuous_iff_continuousAt.mpr this

theorem continuous_gau {d : ℕ} (β : ℝ) :
    Continuous (fun p : EuclideanSpace ℝ (Fin d) × EuclideanSpace ℝ (Fin d) => gau β p.2 p.1) := by
  unfold gau; fun_prop


theorem poly_gauss {c s : ℝ} (hc : 0 < c) (hs : 0 ≤ s) :
    (1 + s) * exp (-c * s) ≤ (1 + 2 / c) * exp (-(c / 2) * s) := by
  have h1 : c / 2 * s + 1 ≤ exp (c / 2 * s) := add_one_le_exp _
  have h3 : exp (-c * s) = exp (-(c / 2) * s) * exp (-(c / 2) * s) := by
    rw [← exp_add]; ring_nf
  have h6 : exp (c / 2 * s) * exp (-(c / 2) * s) = 1 := by
    rw [← exp_add]; ring_nf; simp
  have h4 : 0 < exp (-(c / 2) * s) := exp_pos _
  have h5 : 1 + s ≤ (1 + 2 / c) * exp (c / 2 * s) := by
    have : s ≤ 2 / c * exp (c / 2 * s) := by
      rw [div_mul_eq_mul_div, le_div_iff₀ hc]; nlinarith
    nlinarith [one_le_exp (by positivity : 0 ≤ c / 2 * s)]
  have h7 : (1 + s) * exp (-(c / 2) * s) ≤ 1 + 2 / c := by
    calc (1 + s) * exp (-(c / 2) * s) ≤ (1 + 2 / c) * exp (c / 2 * s) * exp (-(c / 2) * s) := by
          gcongr
      _ = 1 + 2 / c := by rw [mul_assoc, h6, mul_one]
  rw [h3, ← mul_assoc]
  gcongr

theorem integrable_gauss {d : ℕ} {b : ℝ} (hb : 0 < b) :
    Integrable (fun x : EuclideanSpace ℝ (Fin d) => exp (-b * ‖x‖ ^ 2)) := by
  have := (GaussianFourier.integrable_cexp_neg_mul_sq_norm_add (V := EuclideanSpace ℝ (Fin d))
    (b := (b : ℂ)) (by simpa using hb) 0 0).norm
  refine this.congr (Eventually.of_forall fun x => ?_)
  simp only [zero_mul, add_zero, Complex.norm_exp]
  congr 1
  simp [← Complex.ofReal_pow]

theorem integral_gauss {d : ℕ} {b : ℝ} (hb : 0 < b) :
    ∫ x : EuclideanSpace ℝ (Fin d), exp (-b * ‖x‖ ^ 2) = (π / b) ^ ((d : ℝ) / 2) := by
  have := GaussianFourier.integral_rexp_neg_mul_sq_norm (V := EuclideanSpace ℝ (Fin d)) hb
  simpa using this

theorem integrable_sq_gauss {d : ℕ} {b : ℝ} (hb : 0 < b) :
    Integrable (fun x : EuclideanSpace ℝ (Fin d) => ‖x‖ ^ 2 * exp (-b * ‖x‖ ^ 2)) := by
  refine ((integrable_gauss (d := d) (half_pos hb)).const_mul (1 + 2 / b)).mono' ?_
    (Eventually.of_forall fun x => ?_)
  · exact (by fun_prop : Continuous fun x : EuclideanSpace ℝ (Fin d) =>
      ‖x‖ ^ 2 * exp (-b * ‖x‖ ^ 2)).aestronglyMeasurable
  · have := poly_gauss hb (sq_nonneg ‖x‖)
    rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
    have h0 : 0 ≤ exp (-b * ‖x‖ ^ 2) := (exp_pos _).le
    nlinarith

theorem integral_sq_gauss {d : ℕ} {b : ℝ} (hb : 0 < b) :
    ∫ x : EuclideanSpace ℝ (Fin d), ‖x‖ ^ 2 * exp (-b * ‖x‖ ^ 2)
      = d / (2 * b) * (π / b) ^ ((d : ℝ) / 2) := by
  -- differentiate b ↦ ∫ exp(-b‖x‖²)
  have hderiv := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun (c : ℝ) (x : EuclideanSpace ℝ (Fin d)) => exp (-c * ‖x‖ ^ 2))
    (F' := fun (c : ℝ) (x : EuclideanSpace ℝ (Fin d)) => -(‖x‖ ^ 2 * exp (-c * ‖x‖ ^ 2)))
    (x₀ := b) (s := Metric.ball b (b / 2))
    (bound := fun x => ‖x‖ ^ 2 * exp (-(b / 2) * ‖x‖ ^ 2))
    (Metric.ball_mem_nhds b (half_pos hb))
    (Eventually.of_forall fun c => (by fun_prop : Continuous fun x : EuclideanSpace ℝ (Fin d) =>
      exp (-c * ‖x‖ ^ 2)).aestronglyMeasurable)
    (integrable_gauss hb)
    ((by fun_prop : Continuous fun x : EuclideanSpace ℝ (Fin d) =>
      -(‖x‖ ^ 2 * exp (-b * ‖x‖ ^ 2))).aestronglyMeasurable)
    (Eventually.of_forall fun x c hc => ?_)
    (integrable_sq_gauss (half_pos hb))
    (Eventually.of_forall fun x c _ => ?_)
  rotate_left
  · rw [norm_neg, Real.norm_eq_abs, abs_of_nonneg (by positivity)]
    have : b / 2 ≤ c := by
      have := Metric.mem_ball.mp hc
      rw [Real.dist_eq] at this
      linarith [(abs_lt.mp this).1]
    gcongr
  · have := ((hasDerivAt_neg c).mul_const (‖x‖ ^ 2)).exp
    convert this using 1
    ring
  have hclosed : HasDerivAt (fun c : ℝ => (π / c) ^ ((d : ℝ) / 2))
      (-(d / (2 * b) * (π / b) ^ ((d : ℝ) / 2))) b := by
    have h1 : HasDerivAt (fun c : ℝ => π / c) (-(π / b ^ 2)) b := by
      have := (hasDerivAt_inv hb.ne').const_mul π
      convert this using 1 <;> [ext; skip] <;> field_simp
    have h2 := h1.rpow_const (p := (d : ℝ) / 2) (Or.inl (by positivity))
    convert h2 using 1
    rw [rpow_sub_one (by positivity)]
    field_simp
  have heq : (fun c : ℝ => ∫ x : EuclideanSpace ℝ (Fin d), exp (-c * ‖x‖ ^ 2))
      =ᶠ[𝓝 b] fun c : ℝ => (π / c) ^ ((d : ℝ) / 2) := by
    filter_upwards [lt_mem_nhds hb] with c hc
    exact integral_gauss hc
  have := hderiv.2.congr_of_eventuallyEq heq.symm
  have huniq := this.unique hclosed
  rw [integral_neg] at huniq
  linarith


theorem sq_add_le_split {P Q e α₁ : ℝ} (he : 0 < e) :
    α₁ * (P + Q) ^ 2 ≤ (α₁ + e) * P ^ 2 + (α₁ + α₁ ^ 2 / e) * Q ^ 2 := by
  have h : 2 * α₁ * P * Q ≤ e * P ^ 2 + α₁ ^ 2 / e * Q ^ 2 := by
    have h1 : 0 ≤ (e * P - α₁ * Q) ^ 2 := sq_nonneg _
    have h2 : e * (2 * α₁ * P * Q) ≤ e * (e * P ^ 2 + α₁ ^ 2 / e * Q ^ 2) := by
      have : e * (α₁ ^ 2 / e * Q ^ 2) = α₁ ^ 2 * Q ^ 2 := by field_simp
      rw [mul_add, this]; nlinarith
    exact le_of_mul_le_mul_left h2 he
  nlinarith

/-- The master domination estimate. -/
theorem master_est {d : ℕ} {α β : ℝ} (hα : 0 ≤ α) (hαβ : α < β) :
    ∃ K L γ : ℝ, 0 < γ ∧ 0 ≤ L ∧ ∀ x y : EuclideanSpace ℝ (Fin d),
      (1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2) * exp (α * ‖y‖ ^ 2)
        ≤ K * exp (L * ‖x‖ ^ 2) * exp (-γ * ‖y‖ ^ 2) := by
  set e := (β - α) / 3 with he_def
  have he : 0 < e := by rw [he_def]; linarith
  set α₁ := α + e
  have hα₁ : 0 ≤ α₁ := by positivity
  refine ⟨1 + 2 / e, α₁ + α₁ ^ 2 / e, e, he, by positivity, fun x y => ?_⟩
  set s := ‖x - y‖ ^ 2
  have hs : 0 ≤ s := sq_nonneg _
  have hpg := poly_gauss he hs
  have hsplit : exp (-β * s) = exp (-e * s) * exp (-(α₁ + e) * s) := by
    rw [← exp_add]; congr 1; simp only [α₁, he_def]; ring
  have hy : ‖y‖ ≤ ‖x - y‖ + ‖x‖ := by
    calc ‖y‖ = ‖x - (x - y)‖ := by congr 1; abel
      _ ≤ ‖x‖ + ‖x - y‖ := norm_sub_le _ _
      _ = _ := by ring
  have hyy : α₁ * ‖y‖ ^ 2 ≤ (α₁ + e) * s + (α₁ + α₁ ^ 2 / e) * ‖x‖ ^ 2 := by
    calc α₁ * ‖y‖ ^ 2 ≤ α₁ * (‖x - y‖ + ‖x‖) ^ 2 := by gcongr
      _ ≤ _ := sq_add_le_split he
  have hexp : exp (-(α₁ + e) * s) * exp (α * ‖y‖ ^ 2)
      ≤ exp ((α₁ + α₁ ^ 2 / e) * ‖x‖ ^ 2) * exp (-e * ‖y‖ ^ 2) := by
    rw [← exp_add, ← exp_add]
    apply exp_le_exp.mpr
    have : α * ‖y‖ ^ 2 = α₁ * ‖y‖ ^ 2 - e * ‖y‖ ^ 2 := by simp only [α₁]; ring
    rw [this]; linarith
  have h2pos : 0 ≤ exp (-(e / 2) * s) := (exp_pos _).le
  have h3 : exp (-(e / 2) * s) ≤ 1 := exp_le_one_iff.mpr (by nlinarith)
  calc (1 + s) * exp (-β * s) * exp (α * ‖y‖ ^ 2)
      = ((1 + s) * exp (-e * s)) * (exp (-(α₁ + e) * s) * exp (α * ‖y‖ ^ 2)) := by
        rw [hsplit]; ring
    _ ≤ ((1 + 2 / e) * exp (-(e / 2) * s)) *
        (exp ((α₁ + α₁ ^ 2 / e) * ‖x‖ ^ 2) * exp (-e * ‖y‖ ^ 2)) := by
        gcongr
    _ ≤ ((1 + 2 / e) * 1) * (exp ((α₁ + α₁ ^ 2 / e) * ‖x‖ ^ 2) * exp (-e * ‖y‖ ^ 2)) := by
        gcongr
    _ = _ := by ring

/-- Domination on a ball, with an integrable bound. -/
theorem dom_bound {d : ℕ} {α β : ℝ} (hα : 0 ≤ α) (hαβ : α < β)
    (x₀ : EuclideanSpace ℝ (Fin d)) :
    ∃ B : EuclideanSpace ℝ (Fin d) → ℝ, Integrable B ∧ Continuous B ∧
      ∀ x ∈ Metric.ball x₀ 1, ∀ y,
        (1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2) * exp (α * ‖y‖ ^ 2) ≤ B y := by
  obtain ⟨K, L, γ, hγ, hL, h⟩ := master_est (d := d) hα hαβ
  refine ⟨fun y => K * exp (L * (‖x₀‖ + 1) ^ 2) * exp (-γ * ‖y‖ ^ 2),
    (integrable_gauss hγ).const_mul _, by fun_prop, fun x hx y => ?_⟩
  have hK : 0 ≤ K := by
    have := h x y
    have h1 : 0 ≤ (1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2) * exp (α * ‖y‖ ^ 2) := by
      positivity
    have h2 : 0 < exp (L * ‖x‖ ^ 2) * exp (-γ * ‖y‖ ^ 2) := by positivity
    by_contra hneg
    rw [not_le] at hneg
    nlinarith [mul_pos_of_neg_of_neg hneg (neg_neg_of_pos h2)]
  refine (h x y).trans ?_
  have hx' : ‖x‖ ≤ ‖x₀‖ + 1 := by
    have := Metric.mem_ball.mp hx
    rw [dist_eq_norm] at this
    calc ‖x‖ = ‖(x - x₀) + x₀‖ := by congr 1; abel
      _ ≤ ‖x - x₀‖ + ‖x₀‖ := norm_add_le _ _
      _ ≤ _ := by linarith
  show K * exp (L * ‖x‖ ^ 2) * exp (-γ * ‖y‖ ^ 2) ≤
    K * exp (L * (‖x₀‖ + 1) ^ 2) * exp (-γ * ‖y‖ ^ 2)
  gcongr

theorem hk_eq_gau {d : ℕ} (κ t : ℝ) (x y : EuclideanSpace ℝ (Fin d)) :
    heatKernel d κ (x - y) t = (4 * π * κ * t) ^ (-(d : ℝ) / 2) * gau (-(1 / (4 * κ * t))) y x := by
  unfold heatKernel gau
  congr 2
  ring

theorem hk_hasDerivAt_time {d : ℕ} {κ s : ℝ} (hκ : 0 < κ) (hs : 0 < s)
    (w : EuclideanSpace ℝ (Fin d)) :
    HasDerivAt (fun s => heatKernel d κ w s)
      ((-(d / (2 * s)) + ‖w‖ ^ 2 / (4 * κ * s ^ 2)) * heatKernel d κ w s) s := by
  have hpos : 0 < 4 * π * κ * s := by positivity
  have h1 : HasDerivAt (fun s : ℝ => 4 * π * κ * s) (4 * π * κ) s := by
    simpa using (hasDerivAt_id s).const_mul (4 * π * κ)
  have h1' := h1.rpow_const (p := -(d : ℝ) / 2) (Or.inl hpos.ne')
  have h2 : HasDerivAt (fun s : ℝ => -‖w‖ ^ 2 / (4 * κ * s))
      ((-‖w‖ ^ 2 / (4 * κ)) * (-(s ^ 2)⁻¹)) s := by
    have := (hasDerivAt_inv hs.ne').const_mul (-‖w‖ ^ 2 / (4 * κ))
    convert this using 1
    ext s'
    field_simp
  have h3 := h1'.mul h2.exp
  unfold heatKernel
  convert h3 using 1
  rw [rpow_sub_one hpos.ne']
  field_simp

theorem hk_time_eq_lap {d : ℕ} {κ s : ℝ} (hκ : 0 < κ) (hs : 0 < s) (ρ : ℝ) :
    -(d / (2 * s)) + ρ / (4 * κ * s ^ 2) =
      κ * (2 * (-(1 / (4 * κ * s))) * d + 4 * (-(1 / (4 * κ * s))) ^ 2 * ρ) := by
  field_simp
  ring


theorem le_one_add_sq (r : ℝ) : r ≤ 1 + r ^ 2 := by nlinarith [sq_nonneg (r - 1 / 2)]

/-- Pointwise bounds on the Gaussian and its first two derivatives. -/
theorem gau_family_bounds {d : ℕ} {β : ℝ} (hβ : 0 < β) (y x : EuclideanSpace ℝ (Fin d)) :
    |gau (-β) y x| ≤ (1 + 2 * β + 4 * β ^ 2) * ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2)) ∧
    ‖Dgau (-β) y x‖ ≤ (1 + 2 * β + 4 * β ^ 2) * ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2)) ∧
    ‖D2gau (-β) y x‖ ≤ (1 + 2 * β + 4 * β ^ 2) * ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2)) := by
  have hg : gau (-β) y x = exp (-β * ‖x - y‖ ^ 2) := rfl
  have hgpos : 0 < exp (-β * ‖x - y‖ ^ 2) := exp_pos _
  have hn := norm_nonneg (x - y)
  have hs := sq_nonneg ‖x - y‖
  have h1 := le_one_add_sq ‖x - y‖
  have hb : |(-β)| = β := by rw [abs_neg, abs_of_pos hβ]
  refine ⟨?_, ?_, ?_⟩
  · rw [hg, abs_of_pos hgpos]
    have : 1 ≤ (1 + 2 * β + 4 * β ^ 2) * (1 + ‖x - y‖ ^ 2) := by nlinarith
    nlinarith
  · refine (norm_Dgau_le _ _ _).trans ?_
    rw [hb, hg]
    have : 2 * β * ‖x - y‖ ≤ (1 + 2 * β + 4 * β ^ 2) * (1 + ‖x - y‖ ^ 2) := by nlinarith
    nlinarith
  · refine (norm_D2gau_le _ _ _).trans ?_
    rw [hb, hg, neg_sq]
    have : 2 * β + 4 * β ^ 2 * ‖x - y‖ ^ 2 ≤ (1 + 2 * β + 4 * β ^ 2) * (1 + ‖x - y‖ ^ 2) := by
      nlinarith
    nlinarith

theorem conv_bound {d : ℕ} {c β M α : ℝ} (hc : 0 ≤ c) (hβ : 0 < β)
    (f : EuclideanSpace ℝ (Fin d) → ℝ) (hfg : ∀ y, |f y| ≤ M * exp (α * ‖y‖ ^ 2))
    {X : ℝ} (y x : EuclideanSpace ℝ (Fin d))
    (hX : X ≤ (1 + 2 * β + 4 * β ^ 2) * ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2))) :
    |c * f y| * X ≤ c * M * (1 + 2 * β + 4 * β ^ 2) *
      ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2) * exp (α * ‖y‖ ^ 2)) := by
  rw [abs_mul, abs_of_nonneg hc]
  have h1 : 0 ≤ (1 + 2 * β + 4 * β ^ 2) * ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2)) := by
    positivity
  calc c * |f y| * X ≤ c * |f y| * ((1 + 2 * β + 4 * β ^ 2) *
        ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2))) := by
        gcongr
    _ ≤ c * (M * exp (α * ‖y‖ ^ 2)) * ((1 + 2 * β + 4 * β ^ 2) *
        ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2))) := by
        gcongr; exact hfg y
    _ = _ := by ring

theorem conv_smooth {d : ℕ} {c β M α : ℝ} (hc : 0 ≤ c) (hβ : 0 < β) (hα : 0 ≤ α) (hαβ : α < β)
    (f : EuclideanSpace ℝ (Fin d) → ℝ) (hf : Continuous f)
    (hfg : ∀ y, |f y| ≤ M * exp (α * ‖y‖ ^ 2)) :
    (∀ x, HasFDerivAt (fun x => ∫ y, (c * f y) * gau (-β) y x)
      (∫ y, (c * f y) • Dgau (-β) y x) x) ∧
    (∀ x, HasFDerivAt (fun x => ∫ y, (c * f y) • Dgau (-β) y x)
      (∫ y, (c * f y) • D2gau (-β) y x) x) ∧
    (∀ x, ContinuousAt (fun x => ∫ y, (c * f y) • D2gau (-β) y x) x) ∧
    (∀ x, Integrable (fun y => (c * f y) • D2gau (-β) y x)) ∧
    (∀ x, Integrable (fun y => (c * f y) * gau (-β) y x)) := by
  set C := c * M * (1 + 2 * β + 4 * β ^ 2)
  -- measurability
  have m0 : ∀ x, AEStronglyMeasurable (fun y => (c * f y) * gau (-β) y x) := fun x =>
    ((continuous_const.mul hf).mul ((continuous_gau (-β)).comp
      (continuous_const.prodMk continuous_id))).aestronglyMeasurable
  have m1 : ∀ x, AEStronglyMeasurable (fun y => (c * f y) • Dgau (-β) y x) := fun x => by
    simp_rw [Dgau_sub (-β) _ x]
    exact ((continuous_const.mul hf).smul ((continuous_Dgau0 (-β)).comp
      (continuous_const.sub continuous_id))).aestronglyMeasurable
  have m2 : ∀ x, AEStronglyMeasurable (fun y => (c * f y) • D2gau (-β) y x) := fun x => by
    simp_rw [D2gau_sub (-β) _ x]
    exact ((continuous_const.mul hf).smul ((continuous_D2gau0 (-β)).comp
      (continuous_const.sub continuous_id))).aestronglyMeasurable
  -- bounds
  have b0 : ∀ x y, ‖(c * f y) * gau (-β) y x‖ ≤ C *
      ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2) * exp (α * ‖y‖ ^ 2)) := fun x y => by
    rw [Real.norm_eq_abs, abs_mul]
    exact conv_bound hc hβ f hfg y x (gau_family_bounds hβ y x).1
  have b1 : ∀ x y, ‖(c * f y) • Dgau (-β) y x‖ ≤ C *
      ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2) * exp (α * ‖y‖ ^ 2)) := fun x y => by
    rw [norm_smul, Real.norm_eq_abs]
    exact conv_bound hc hβ f hfg y x (gau_family_bounds hβ y x).2.1
  have b2 : ∀ x y, ‖(c * f y) • D2gau (-β) y x‖ ≤ C *
      ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2) * exp (α * ‖y‖ ^ 2)) := fun x y => by
    refine (ContinuousLinearMap.opNorm_smul_le _ _).trans ?_
    rw [Real.norm_eq_abs]
    exact conv_bound hc hβ f hfg y x (gau_family_bounds hβ y x).2.2
  have hC : 0 ≤ C := by
    have := (b0 0 0).trans' (norm_nonneg _)
    have hpos : 0 < (1 + ‖(0 : EuclideanSpace ℝ (Fin d)) - 0‖ ^ 2) *
        exp (-β * ‖(0 : EuclideanSpace ℝ (Fin d)) - 0‖ ^ 2) * exp (α * ‖(0 : EuclideanSpace ℝ (Fin d))‖ ^ 2) := by
      positivity
    by_contra h
    rw [not_le] at h
    linarith [mul_neg_of_neg_of_pos h hpos]
  -- domination on balls
  have dom : ∀ x₀ : EuclideanSpace ℝ (Fin d), ∃ B : EuclideanSpace ℝ (Fin d) → ℝ,
      Integrable B ∧ ∀ x ∈ Metric.ball x₀ 1, ∀ y,
        C * ((1 + ‖x - y‖ ^ 2) * exp (-β * ‖x - y‖ ^ 2) * exp (α * ‖y‖ ^ 2)) ≤ B y := by
    intro x₀
    obtain ⟨B, hB, -, hBb⟩ := dom_bound (d := d) hα hαβ x₀
    exact ⟨fun y => C * B y, hB.const_mul C, fun x hx y => mul_le_mul_of_nonneg_left (hBb x hx y) hC⟩
  have int0 : ∀ x, Integrable (fun y => (c * f y) * gau (-β) y x) := fun x => by
    obtain ⟨B, hB, hBb⟩ := dom x
    exact hB.mono' (m0 x) (Eventually.of_forall fun y =>
      (b0 x y).trans (hBb x (Metric.mem_ball_self one_pos) y))
  have int1 : ∀ x, Integrable (fun y => (c * f y) • Dgau (-β) y x) := fun x => by
    obtain ⟨B, hB, hBb⟩ := dom x
    exact hB.mono' (m1 x) (Eventually.of_forall fun y =>
      (b1 x y).trans (hBb x (Metric.mem_ball_self one_pos) y))
  have int2 : ∀ x, Integrable (fun y => (c * f y) • D2gau (-β) y x) := fun x => by
    obtain ⟨B, hB, hBb⟩ := dom x
    refine Integrable.mono' (f := fun y => (c * f y) • D2gau (-β) y x) hB (m2 x) ?_
    refine Eventually.of_forall fun y => ?_
    exact (b2 x y).trans (hBb x (Metric.mem_ball_self one_pos) y)
  refine ⟨fun x₀ => ?_, fun x₀ => ?_, fun x₀ => ?_, int2, int0⟩
  · obtain ⟨B, hB, hBb⟩ := dom x₀
    exact hasFDerivAt_integral_of_dominated_of_fderiv_le (Metric.ball_mem_nhds x₀ one_pos)
      (Eventually.of_forall m0) (int0 x₀) (m1 x₀)
      (Eventually.of_forall fun y x hx => (b1 x y).trans (hBb x hx y)) hB
      (Eventually.of_forall fun y x _ => (hasFDerivAt_gau (-β) y x).const_mul (c * f y))
  · obtain ⟨B, hB, hBb⟩ := dom x₀
    exact hasFDerivAt_integral_of_dominated_of_fderiv_le (Metric.ball_mem_nhds x₀ one_pos)
      (Eventually.of_forall m1) (int1 x₀) (m2 x₀)
      (Eventually.of_forall fun y x hx => (b2 x y).trans (hBb x hx y)) hB
      (Eventually.of_forall fun y x _ => (hasFDerivAt_Dgau (-β) y x).const_smul (c * f y))
  · obtain ⟨B, hB, hBb⟩ := dom x₀
    refine continuousAt_of_dominated (Eventually.of_forall m2) ?_ hB
      (Eventually.of_forall fun y => ?_)
    · filter_upwards [Metric.ball_mem_nhds x₀ one_pos] with x hx
      exact Eventually.of_forall fun y => (b2 x y).trans (hBb x hx y)
    · have : (fun x => (c * f y) • D2gau (-β) y x) = fun x => (c * f y) • D2gau (-β) 0 (x - y) := by
        ext1 x; rw [D2gau_sub]
      rw [this]
      have hc : Continuous fun x => (c * f y) • D2gau (-β) 0 (x - y) :=
        Continuous.smul (continuous_const : Continuous fun _ : EuclideanSpace ℝ (Fin d) => c * f y)
          ((continuous_D2gau0 (-β)).comp (continuous_id.sub continuous_const))
      exact hc.continuousAt


/-- The Laplacian of the Gaussian convolution, and its second-order smoothness. -/
theorem conv_C2_lap {d : ℕ} {c β M α : ℝ} (hc : 0 ≤ c) (hβ : 0 < β) (hα : 0 ≤ α) (hαβ : α < β)
    (f : EuclideanSpace ℝ (Fin d) → ℝ) (hf : Continuous f)
    (hfg : ∀ y, |f y| ≤ M * exp (α * ‖y‖ ^ 2)) (x : EuclideanSpace ℝ (Fin d)) :
    ContDiffAt ℝ 2 (fun x => ∫ y, (c * f y) * gau (-β) y x) x ∧
    Δ (fun x => ∫ y, (c * f y) * gau (-β) y x) x =
      ∫ y, (c * f y) * ((2 * (-β) * d + 4 * (-β) ^ 2 * ‖x - y‖ ^ 2) * gau (-β) y x) := by
  obtain ⟨h1, h2, h3, hint2, -⟩ := conv_smooth hc hβ hα hαβ f hf hfg
  set U := fun x => ∫ y, (c * f y) * gau (-β) y x
  set F1 := fun x => ∫ y, (c * f y) • Dgau (-β) y x
  set F2 := fun x => ∫ y, (c * f y) • D2gau (-β) y x
  refine ⟨?_, ?_⟩
  · show ContDiffAt ℝ ((1 : ℕ) + 1) U x
    rw [contDiffAt_succ_iff_hasFDerivAt]
    refine ⟨F1, ⟨Set.univ, Filter.univ_mem, fun z _ => h1 z⟩, ?_⟩
    show ContDiffAt ℝ ((0 : ℕ) + 1) F1 x
    rw [contDiffAt_succ_iff_hasFDerivAt]
    refine ⟨F2, ⟨Set.univ, Filter.univ_mem, fun z _ => h2 z⟩, ?_⟩
    rw [Nat.cast_zero, contDiffAt_zero]
    exact ⟨Set.univ, Filter.univ_mem, fun z _ => (h3 z).continuousWithinAt⟩
  · have hU : fderiv ℝ U = F1 := by ext1 z; exact (h1 z).fderiv
    have hF1 : fderiv ℝ (fderiv ℝ U) x = F2 x := by rw [hU]; exact (h2 x).fderiv
    rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis _
      (EuclideanSpace.basisFun (Fin d) ℝ)]
    set e := EuclideanSpace.basisFun (Fin d) ℝ
    have key : ∀ i, iteratedFDeriv ℝ 2 U x ![e i, e i] =
        ∫ y, (c * f y) * D2gau (-β) y x (e i) (e i) := by
      intro i
      rw [iteratedFDeriv_two_apply]
      simp only [Matrix.cons_val_zero, Matrix.cons_val_one, hF1]
      show (∫ y, (c * f y) • D2gau (-β) y x) (e i) (e i) = _
      rw [ContinuousLinearMap.integral_apply (hint2 x),
        ContinuousLinearMap.integral_apply ((hint2 x).apply_continuousLinearMap (e i))]
      rfl
    have hint : ∀ i, Integrable (fun y => (c * f y) * D2gau (-β) y x (e i) (e i)) := fun i =>
      ((hint2 x).apply_continuousLinearMap (e i)).apply_continuousLinearMap (e i)
    simp only [key]
    rw [← integral_finsetSum _ (fun i _ => hint i)]
    congr 1
    ext y
    rw [← Finset.mul_sum, sum_D2gau]


theorem time_bound {d : ℕ} {κ t t₁ s : ℝ} (hκ : 0 < κ) (ht : 0 < t) (hs1 : t / 2 < s)
    (hs2 : s ≤ t₁) (w : EuclideanSpace ℝ (Fin d)) :
    |(-(d / (2 * s)) + ‖w‖ ^ 2 / (4 * κ * s ^ 2)) * heatKernel d κ w s| ≤
      (d / t + 1 / (κ * t ^ 2)) * (4 * π * κ * (t / 2)) ^ (-(d : ℝ) / 2) *
        ((1 + ‖w‖ ^ 2) * exp (-(1 / (4 * κ * t₁)) * ‖w‖ ^ 2)) := by
  have hs : 0 < s := by linarith
  set ρ := ‖w‖ ^ 2
  have hρ : 0 ≤ ρ := sq_nonneg _
  have hd : (0 : ℝ) ≤ d := Nat.cast_nonneg d
  have e1 : (4 * π * κ * s) ^ (-(d : ℝ) / 2) ≤ (4 * π * κ * (t / 2)) ^ (-(d : ℝ) / 2) := by
    apply rpow_le_rpow_of_nonpos (by positivity)
    · have := pi_pos; gcongr
    · have : (0 : ℝ) ≤ d := hd
      linarith
  have e2 : exp (-ρ / (4 * κ * s)) ≤ exp (-(1 / (4 * κ * t₁)) * ρ) := by
    apply exp_le_exp.mpr
    have h1 : ρ / (4 * κ * t₁) ≤ ρ / (4 * κ * s) :=
      div_le_div_of_nonneg_left hρ (by positivity) (by nlinarith)
    have h2 : -ρ / (4 * κ * s) = -(ρ / (4 * κ * s)) := by ring
    have h3 : -(1 / (4 * κ * t₁)) * ρ = -(ρ / (4 * κ * t₁)) := by ring
    rw [h2, h3]; linarith
  have e3 : |-(d / (2 * s)) + ρ / (4 * κ * s ^ 2)| ≤ (d / t + 1 / (κ * t ^ 2)) * (1 + ρ) := by
    have a1 : d / (2 * s) ≤ d / t := div_le_div_of_nonneg_left hd ht (by linarith)
    have a2 : ρ / (4 * κ * s ^ 2) ≤ ρ / (κ * t ^ 2) := by
      have : t ^ 2 ≤ 4 * s ^ 2 := by nlinarith
      exact div_le_div_of_nonneg_left hρ (by positivity) (by nlinarith)
    have a3 : 0 ≤ d / (2 * s) := by positivity
    have a4 : 0 ≤ ρ / (4 * κ * s ^ 2) := by positivity
    have a5 : 0 ≤ d / t * ρ := by positivity
    have a6 : 0 ≤ 1 / (κ * t ^ 2) := by positivity
    have a7 : ρ / (κ * t ^ 2) = 1 / (κ * t ^ 2) * ρ := by ring
    calc |-(d / (2 * s)) + ρ / (4 * κ * s ^ 2)| ≤ |-(d / (2 * s))| + |ρ / (4 * κ * s ^ 2)| :=
          abs_add_le _ _
      _ = d / (2 * s) + ρ / (4 * κ * s ^ 2) := by
          rw [abs_neg, abs_of_nonneg a3, abs_of_nonneg a4]
      _ ≤ (d / t + 1 / (κ * t ^ 2)) * (1 + ρ) := by nlinarith
  have hk : heatKernel d κ w s = (4 * π * κ * s) ^ (-(d : ℝ) / 2) * exp (-ρ / (4 * κ * s)) := rfl
  have hkpos : 0 ≤ heatKernel d κ w s := by rw [hk]; positivity
  rw [abs_mul, abs_of_nonneg hkpos, hk]
  have hA : 0 ≤ (d / t + 1 / (κ * t ^ 2)) := by positivity
  calc |-(d / (2 * s)) + ρ / (4 * κ * s ^ 2)| *
        ((4 * π * κ * s) ^ (-(d : ℝ) / 2) * exp (-ρ / (4 * κ * s)))
      ≤ ((d / t + 1 / (κ * t ^ 2)) * (1 + ρ)) *
        ((4 * π * κ * (t / 2)) ^ (-(d : ℝ) / 2) * exp (-(1 / (4 * κ * t₁)) * ρ)) := by
        gcongr
    _ = _ := by ring

theorem exists_t1 {α κ t : ℝ} (hα : 0 ≤ α) (hκ : 0 < κ) (hat : 4 * α * κ * t < 1) :
    ∃ t₁, t < t₁ ∧ 4 * α * κ * t₁ < 1 := by
  set p := 4 * α * κ
  have hp : 0 ≤ p := by positivity
  set q := 1 - p * t
  have hq : 0 < q := by simp only [q, p]; linarith
  refine ⟨t + q / (p + 1), by have : 0 < q / (p + 1) := by positivity
                              linarith, ?_⟩
  have h1 : p * (q / (p + 1)) < q := by
    rw [mul_div_assoc', div_lt_iff₀ (by linarith)]; nlinarith
  show p * (t + q / (p + 1)) < 1
  have : p * t + q = 1 := by simp only [q]; ring
  nlinarith

/-- Part (a) of the convolution theorem: smoothness in space and the heat equation. -/
theorem conv_heat {d : ℕ} {κ M a : ℝ} (hκ : 0 < κ)
    (f : EuclideanSpace ℝ (Fin d) → ℝ) (hf : Continuous f)
    (hgrowth : ∀ y, |f y| ≤ M * exp (a * ‖y‖ ^ 2))
    (x : EuclideanSpace ℝ (Fin d)) (t : ℝ) (ht : 0 < t) (hat : 4 * a * κ * t < 1) :
    ContDiffAt ℝ 2 (fun y => ∫ z, heatKernel d κ (y - z) t * f z) x ∧
      HasDerivAt (fun s => ∫ z, heatKernel d κ (x - z) s * f z)
        (κ * Δ (fun y => ∫ z, heatKernel d κ (y - z) t * f z) x) t := by
  set α := max a 0
  have hα : 0 ≤ α := le_max_right _ _
  have hM : 0 ≤ M := by
    have := hgrowth 0
    simp only [norm_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero,
      exp_zero, mul_one] at this
    linarith [abs_nonneg (f 0)]
  have hfg : ∀ y, |f y| ≤ M * exp (α * ‖y‖ ^ 2) := fun y =>
    (hgrowth y).trans (by gcongr; exact le_max_left _ _)
  have h4 : 0 < 4 * κ * t := by positivity
  have hαt : 4 * α * κ * t < 1 := by
    rcases le_total a 0 with h | h
    · simp only [α, max_eq_right h]; linarith
    · simp only [α, max_eq_left h]; exact hat
  set β := 1 / (4 * κ * t) with hβdef
  have hβ : 0 < β := by positivity
  have hαβ : α < β := by rw [hβdef, lt_div_iff₀ h4]; linarith
  set c := (4 * π * κ * t) ^ (-(d : ℝ) / 2)
  have hc : 0 ≤ c := rpow_nonneg (by positivity) _
  have hU : (fun y => ∫ z, heatKernel d κ (y - z) t * f z) =
      fun y => ∫ z, (c * f z) * gau (-β) z y := by
    ext y; congr 1; ext z; rw [hk_eq_gau]; ring
  obtain ⟨hC2, hlap⟩ := conv_C2_lap hc hβ hα hαβ f hf hfg x
  obtain ⟨-, -, -, -, hint0⟩ := conv_smooth hc hβ hα hαβ f hf hfg
  rw [hU]
  refine ⟨hC2, ?_⟩
  rw [hlap]
  obtain ⟨t₁, htt₁, ht₁⟩ := exists_t1 hα hκ hαt
  have h4₁ : 0 < 4 * κ * t₁ := by nlinarith
  set β₁ := 1 / (4 * κ * t₁) with hβ₁def
  have hαβ₁ : α < β₁ := by rw [hβ₁def, lt_div_iff₀ h4₁]; linarith
  obtain ⟨B, hB, -, hBb⟩ := dom_bound (d := d) hα hαβ₁ x
  set ε := min (t / 2) (t₁ - t)
  have hε : 0 < ε := lt_min (by linarith) (by linarith)
  set K₀ := (d / t + 1 / (κ * t ^ 2)) * (4 * π * κ * (t / 2)) ^ (-(d : ℝ) / 2) * M
  have hK₀ : 0 ≤ K₀ := by positivity
  have hball : ∀ s ∈ Metric.ball t ε, t / 2 < s ∧ s ≤ t₁ := by
    intro s hs
    rw [Metric.mem_ball, Real.dist_eq, abs_lt] at hs
    have := min_le_left (t / 2) (t₁ - t)
    have := min_le_right (t / 2) (t₁ - t)
    constructor <;> linarith
  have hderiv := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun (s : ℝ) (z : EuclideanSpace ℝ (Fin d)) => heatKernel d κ (x - z) s * f z)
    (F' := fun (s : ℝ) (z : EuclideanSpace ℝ (Fin d)) =>
      ((-(d / (2 * s)) + ‖x - z‖ ^ 2 / (4 * κ * s ^ 2)) * heatKernel d κ (x - z) s) * f z)
    (x₀ := t) (s := Metric.ball t ε) (bound := fun z => K₀ * B z)
    (Metric.ball_mem_nhds t hε)
    (Eventually.of_forall fun s => (by unfold heatKernel; fun_prop :
      Continuous fun z => heatKernel d κ (x - z) s * f z).aestronglyMeasurable)
    (by
      have := hint0 x
      refine this.congr (Eventually.of_forall fun z => ?_)
      simp only; rw [hk_eq_gau]; ring)
    ((by unfold heatKernel; fun_prop : Continuous fun z =>
      ((-(d / (2 * t)) + ‖x - z‖ ^ 2 / (4 * κ * t ^ 2)) * heatKernel d κ (x - z) t) * f z)
        |>.aestronglyMeasurable)
    (Eventually.of_forall fun z s hs => ?_)
    (hB.const_mul K₀)
    (Eventually.of_forall fun z s hs => ?_)
  rotate_left
  · obtain ⟨hs1, hs2⟩ := hball s hs
    rw [Real.norm_eq_abs, abs_mul]
    have tb := time_bound (t₁ := t₁) hκ ht hs1 hs2 (x - z)
    have hb := hBb x (Metric.mem_ball_self one_pos) z
    calc |(-(d / (2 * s)) + ‖x - z‖ ^ 2 / (4 * κ * s ^ 2)) * heatKernel d κ (x - z) s| * |f z|
        ≤ ((d / t + 1 / (κ * t ^ 2)) * (4 * π * κ * (t / 2)) ^ (-(d : ℝ) / 2) *
          ((1 + ‖x - z‖ ^ 2) * exp (-(1 / (4 * κ * t₁)) * ‖x - z‖ ^ 2))) *
          (M * exp (α * ‖z‖ ^ 2)) := by
          exact mul_le_mul tb (hfg z) (abs_nonneg _) (by positivity)
      _ = K₀ * ((1 + ‖x - z‖ ^ 2) * exp (-β₁ * ‖x - z‖ ^ 2) * exp (α * ‖z‖ ^ 2)) := by
          simp only [K₀, β₁]; ring
      _ ≤ K₀ * B z := by gcongr
  · obtain ⟨hs1, -⟩ := hball s hs
    exact (hk_hasDerivAt_time hκ (by linarith) (x - z)).mul_const (f z)
  have hval : ∫ z, ((-(d / (2 * t)) + ‖x - z‖ ^ 2 / (4 * κ * t ^ 2)) *
      heatKernel d κ (x - z) t) * f z =
      κ * ∫ y, (c * f y) * ((2 * (-β) * d + 4 * (-β) ^ 2 * ‖x - y‖ ^ 2) * gau (-β) y x) := by
    rw [← integral_const_mul]
    congr 1; ext z
    rw [hk_eq_gau, hk_time_eq_lap hκ ht]
    ring
  rw [← hval]
  exact hderiv.2


theorem integral_g0 {d : ℕ} {κ : ℝ} (hκ : 0 < κ) :
    ∫ v : EuclideanSpace ℝ (Fin d), (4 * π * κ) ^ (-(d : ℝ) / 2) * exp (-(1 / (4 * κ)) * ‖v‖ ^ 2)
      = 1 := by
  rw [integral_const_mul, integral_gauss (by positivity)]
  have : π / (1 / (4 * κ)) = 4 * π * κ := by field_simp
  rw [this, neg_div, rpow_neg (by positivity)]
  exact inv_mul_cancel₀ (by positivity)

theorem hk_scale {d : ℕ} {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (v : EuclideanSpace ℝ (Fin d)) :
    sqrt t ^ d * heatKernel d κ (sqrt t • v) t =
      (4 * π * κ) ^ (-(d : ℝ) / 2) * exp (-(1 / (4 * κ)) * ‖v‖ ^ 2) := by
  unfold heatKernel
  have h1 : ‖sqrt t • v‖ ^ 2 = t * ‖v‖ ^ 2 := by
    rw [norm_smul, mul_pow, Real.norm_eq_abs, sq_abs, sq_sqrt ht.le]
  have h2 : -(t * ‖v‖ ^ 2) / (4 * κ * t) = -(1 / (4 * κ)) * ‖v‖ ^ 2 := by
    field_simp
  rw [h1, h2]
  have h3 : sqrt t ^ d = t ^ ((d : ℝ) / 2) := by
    rw [sqrt_eq_rpow, ← rpow_natCast, ← rpow_mul ht.le]
    congr 1; ring
  have h4 : (4 * π * κ * t) ^ (-(d : ℝ) / 2) =
      (4 * π * κ) ^ (-(d : ℝ) / 2) * t ^ (-(d : ℝ) / 2) :=
    mul_rpow (by positivity) ht.le
  have h5 : t ^ ((d : ℝ) / 2) * t ^ (-(d : ℝ) / 2) = 1 := by
    rw [← rpow_add ht, show (d : ℝ) / 2 + -(d : ℝ) / 2 = 0 by ring, rpow_zero]
  rw [h3, h4]
  calc t ^ ((d : ℝ) / 2) * ((4 * π * κ) ^ (-(d : ℝ) / 2) * t ^ (-(d : ℝ) / 2) *
        exp (-(1 / (4 * κ)) * ‖v‖ ^ 2))
      = (t ^ ((d : ℝ) / 2) * t ^ (-(d : ℝ) / 2)) * ((4 * π * κ) ^ (-(d : ℝ) / 2) *
        exp (-(1 / (4 * κ)) * ‖v‖ ^ 2)) := by ring
    _ = _ := by rw [h5, one_mul]

theorem conv_rescale {d : ℕ} {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t)
    (f : EuclideanSpace ℝ (Fin d) → ℝ) (x : EuclideanSpace ℝ (Fin d)) :
    ∫ y, heatKernel d κ (x - y) t * f y =
      ∫ v, (4 * π * κ) ^ (-(d : ℝ) / 2) * exp (-(1 / (4 * κ)) * ‖v‖ ^ 2) * f (x - sqrt t • v) := by
  have e1 : ∫ y, heatKernel d κ (x - y) t * f y = ∫ w, heatKernel d κ w t * f (x - w) := by
    rw [← integral_sub_left_eq_self (fun y => heatKernel d κ (x - y) t * f y) volume x]
    simp
  have hR : 0 < sqrt t := sqrt_pos.mpr ht
  have e2 := Measure.integral_comp_smul_of_nonneg volume (fun w => heatKernel d κ w t * f (x - w)) (sqrt t)
    (hR := hR.le)
  simp only [finrank_euclideanSpace_fin, smul_eq_mul] at e2
  rw [e1]
  have hpow : sqrt t ^ d ≠ 0 := pow_ne_zero _ hR.ne'
  rw [show (∫ w, heatKernel d κ w t * f (x - w)) =
      sqrt t ^ d * ∫ v, heatKernel d κ (sqrt t • v) t * f (x - sqrt t • v) by
    rw [e2, ← mul_assoc, mul_inv_cancel₀ hpow, one_mul]]
  rw [← integral_const_mul]
  congr 1; ext v
  rw [← hk_scale hκ ht v]; ring

/-- Part (b) of the convolution theorem: the solution tends to its start. -/
theorem conv_limit {d : ℕ} {κ M a : ℝ} (hκ : 0 < κ)
    (f : EuclideanSpace ℝ (Fin d) → ℝ) (hf : Continuous f)
    (hgrowth : ∀ y, |f y| ≤ M * exp (a * ‖y‖ ^ 2)) (x : EuclideanSpace ℝ (Fin d)) :
    Tendsto (fun t => ∫ y, heatKernel d κ (x - y) t * f y) (𝓝[>] 0) (𝓝 (f x)) := by
  set α := max a 0
  have hα : 0 ≤ α := le_max_right _ _
  have hM : 0 ≤ M := by
    have := hgrowth 0
    simp only [norm_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero,
      exp_zero, mul_one] at this
    linarith [abs_nonneg (f 0)]
  have hfg : ∀ y, |f y| ≤ M * exp (α * ‖y‖ ^ 2) := fun y =>
    (hgrowth y).trans (by gcongr; exact le_max_left _ _)
  set c₁ := (4 * π * κ) ^ (-(d : ℝ) / 2)
  have hc₁ : 0 ≤ c₁ := rpow_nonneg (by positivity) _
  set g₀ := fun v : EuclideanSpace ℝ (Fin d) => c₁ * exp (-(1 / (4 * κ)) * ‖v‖ ^ 2)
  have hlim : Tendsto (fun t => ∫ v, g₀ v * f (x - sqrt t • v)) (𝓝[>] 0)
      (𝓝 (∫ v, g₀ v * f x)) := by
    set t₂ := 1 / (16 * κ * (α + 1))
    have ht₂ : 0 < t₂ := by positivity
    refine tendsto_integral_filter_of_dominated_convergence
      (fun v => c₁ * M * exp (2 * α * ‖x‖ ^ 2) * exp (-(1 / (8 * κ)) * ‖v‖ ^ 2))
      (Eventually.of_forall fun t => (by fun_prop : Continuous fun v =>
        g₀ v * f (x - sqrt t • v)).aestronglyMeasurable) ?_
      ((integrable_gauss (by positivity)).const_mul _) ?_
    · filter_upwards [Ioo_mem_nhdsGT ht₂] with t ht
      refine Eventually.of_forall fun v => ?_
      have ht0 : 0 < t := ht.1
      have htt : 16 * κ * (α + 1) * t < 1 := by
        have := ht.2
        rw [show t₂ = 1 / (16 * κ * (α + 1)) from rfl, lt_div_iff₀ (by positivity)] at this
        linarith
      have hn : ‖x - sqrt t • v‖ ^ 2 ≤ 2 * ‖x‖ ^ 2 + 2 * t * ‖v‖ ^ 2 := by
        have h1 : ‖sqrt t • v‖ = sqrt t * ‖v‖ := by
          rw [norm_smul, Real.norm_eq_abs, abs_of_nonneg (sqrt_nonneg _)]
        have h2 := norm_sub_le x (sqrt t • v)
        rw [h1] at h2
        have h3 : (sqrt t * ‖v‖) ^ 2 = t * ‖v‖ ^ 2 := by rw [mul_pow, sq_sqrt ht0.le]
        nlinarith [sq_nonneg (‖x‖ - sqrt t * ‖v‖), norm_nonneg (x - sqrt t • v)]
      have hgpos : 0 ≤ g₀ v := by positivity
      rw [Real.norm_eq_abs, abs_mul, abs_of_nonneg hgpos]
      calc g₀ v * |f (x - sqrt t • v)| ≤ g₀ v * (M * exp (α * (2 * ‖x‖ ^ 2 + 2 * t * ‖v‖ ^ 2))) := by
            gcongr
            exact (hfg _).trans (by gcongr)
        _ = c₁ * M * exp (2 * α * ‖x‖ ^ 2) *
            exp (-(1 / (4 * κ)) * ‖v‖ ^ 2 + 2 * α * t * ‖v‖ ^ 2) := by
            simp only [g₀]; rw [exp_add]
            rw [show α * (2 * ‖x‖ ^ 2 + 2 * t * ‖v‖ ^ 2) = 2 * α * ‖x‖ ^ 2 + 2 * α * t * ‖v‖ ^ 2 by
              ring, exp_add]
            ring
        _ ≤ _ := by
            gcongr
            have hαt : 2 * α * t ≤ 1 / (8 * κ) := by
              rw [le_div_iff₀ (by positivity)]; nlinarith
            have hv := sq_nonneg ‖v‖
            have : -(1 / (4 * κ)) + 2 * α * t ≤ -(1 / (8 * κ)) := by
              have : 1 / (4 * κ) = 2 * (1 / (8 * κ)) := by field_simp; ring
              linarith
            nlinarith
    · refine Eventually.of_forall fun v => ?_
      refine Tendsto.const_mul _ ((hf.tendsto x).comp ?_)
      have : Tendsto (fun t : ℝ => x - sqrt t • v) (𝓝 0) (𝓝 (x - sqrt 0 • v)) :=
        ((continuous_const.sub (continuous_sqrt.smul continuous_const)).tendsto 0)
      simp only [sqrt_zero, zero_smul, sub_zero] at this
      exact this.mono_left nhdsWithin_le_nhds
  have hone : ∫ v, g₀ v * f x = f x := by
    rw [integral_mul_const, integral_g0 hκ, one_mul]
  rw [hone] at hlim
  refine hlim.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with t ht
  exact (conv_rescale hκ ht f x).symm

theorem hk_eq_gau0 {d : ℕ} (κ t : ℝ) (y : EuclideanSpace ℝ (Fin d)) :
    heatKernel d κ y t = (4 * π * κ * t) ^ (-(d : ℝ) / 2) * gau (-(1 / (4 * κ * t))) 0 y := by
  have := hk_eq_gau κ t y 0
  rwa [sub_zero] at this

theorem hk_eq_exp {d : ℕ} (κ t : ℝ) (y : EuclideanSpace ℝ (Fin d)) :
    heatKernel d κ y t =
      (4 * π * κ * t) ^ (-(d : ℝ) / 2) * exp (-(1 / (4 * κ * t)) * ‖y‖ ^ 2) := by
  unfold heatKernel; congr 2; ring



/-- One-dimensional second derivative test at a local maximum. -/
theorem second_deriv_nonpos_of_isLocalMax {g g' : ℝ → ℝ} {D : ℝ}
    (hg : ∀ᶠ s in 𝓝 0, HasDerivAt g (g' s) s) (hg' : HasDerivAt g' D 0) (h0 : g' 0 = 0)
    (hmax : IsLocalMax g 0) : D ≤ 0 := by
  by_contra hD
  rw [not_le] at hD
  have hsign := eventually_nhdsWithin_sign_eq_of_deriv_pos (f := g') (x₀ := 0)
    (by rw [hg'.deriv]; exact hD) h0
  obtain ⟨δ, hδ, hball⟩ := Metric.eventually_nhds_iff.mp ((hg.and hsign).and hmax)
  set s := δ / 2
  have hs : 0 < s := by positivity
  have hsδ : ∀ x, 0 ≤ x → x ≤ s → dist x 0 < δ := by
    intro x hx hxs
    rw [Real.dist_eq, sub_zero, abs_of_nonneg hx]
    have : s = δ / 2 := rfl
    linarith
  have hcont : ContinuousOn g (Set.Icc 0 s) := fun x hx =>
    (hball (hsδ x hx.1 hx.2)).1.1.continuousAt.continuousWithinAt
  obtain ⟨ξ, hξ, hξeq⟩ := exists_hasDerivAt_eq_slope g g' hs hcont
    (fun x hx => (hball (hsδ x hx.1.le hx.2.le)).1.1)
  have hξpos : 0 < g' ξ := by
    have h1 := (hball (hsδ ξ hξ.1.le hξ.2.le)).1.2
    rw [sub_zero, sign_pos hξ.1] at h1
    exact sign_eq_one_iff.mp h1
  have hgs : g s ≤ g 0 := (hball (hsδ s hs.le le_rfl)).2
  rw [hξeq, sub_zero] at hξpos
  have : 0 < g s - g 0 := by
    have := mul_pos hξpos hs
    rwa [div_mul_cancel₀ _ hs.ne'] at this
  linarith

/-- At a local maximum of a `C²` function, every second directional derivative is `≤ 0`. -/
theorem fderiv_fderiv_nonpos_of_isLocalMax {d : ℕ} {f : EuclideanSpace ℝ (Fin d) → ℝ}
    {x₀ : EuclideanSpace ℝ (Fin d)} (hf : ContDiffAt ℝ 2 f x₀) (hmax : IsLocalMax f x₀)
    (v : EuclideanSpace ℝ (Fin d)) : fderiv ℝ (fderiv ℝ f) x₀ v v ≤ 0 := by
  have hev : ∀ᶠ y in 𝓝 x₀, DifferentiableAt ℝ f y :=
    (hf.eventually (by simp)).mono fun y hy => hy.differentiableAt (by simp)
  have hdf : DifferentiableAt ℝ (fderiv ℝ f) x₀ :=
    (hf.fderiv_right (m := 1) (by norm_num)).differentiableAt (by simp)
  set L : ℝ → EuclideanSpace ℝ (Fin d) := fun s => x₀ + s • v
  have hL : ∀ s, HasDerivAt L v s := fun s => by
    have h := ((hasDerivAt_id s).smul_const v).const_add x₀
    simpa only [id, one_smul] using h
  have hL0 : L 0 = x₀ := by simp [L]
  have hLc : Continuous L := by fun_prop
  have hev' : ∀ᶠ s in 𝓝 (0 : ℝ), DifferentiableAt ℝ f (L s) := by
    have := hLc.continuousAt (x := 0)
    rw [ContinuousAt, hL0] at this
    exact this.eventually hev
  refine second_deriv_nonpos_of_isLocalMax (g := f ∘ L) (g' := fun s => fderiv ℝ f (L s) v)
    (hev'.mono fun s hs => hs.hasFDerivAt.comp_hasDerivAt s (hL s)) ?_ ?_ ?_
  · have h1 : HasDerivAt (fun s => fderiv ℝ f (L s)) (fderiv ℝ (fderiv ℝ f) x₀ v) 0 := by
      have := (hL0 ▸ hdf).hasFDerivAt.comp_hasDerivAt (0 : ℝ) (hL 0)
      rw [hL0] at this
      exact this
    have := h1.clm_apply (hasDerivAt_const (0 : ℝ) v)
    simpa using this
  · simp [hL0, hmax.fderiv_eq_zero]
  · exact (hL0 ▸ hmax).comp_continuous hLc.continuousAt

theorem laplacian_nonpos_of_isLocalMax {d : ℕ} {f : EuclideanSpace ℝ (Fin d) → ℝ}
    {x₀ : EuclideanSpace ℝ (Fin d)} (hf : ContDiffAt ℝ 2 f x₀) (hmax : IsLocalMax f x₀) :
    Δ f x₀ ≤ 0 := by
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis _
    (EuclideanSpace.basisFun (Fin d) ℝ)]
  refine Finset.sum_nonpos fun i _ => ?_
  rw [iteratedFDeriv_two_apply]
  exact fderiv_fderiv_nonpos_of_isLocalMax hf hmax _

/-- At a maximum from the left, the derivative is `≥ 0`. -/
theorem deriv_nonneg_of_left_max {g : ℝ → ℝ} {g' t₀ : ℝ} (hg : HasDerivAt g g' t₀)
    (h : ∀ᶠ s in 𝓝[<] t₀, g s ≤ g t₀) : 0 ≤ g' := by
  have ht := (hasDerivAt_iff_tendsto_slope.mp hg).mono_left (nhdsLT_le_nhdsNE t₀)
  refine ge_of_tendsto ht ?_
  filter_upwards [h, self_mem_nhdsWithin] with s hs hlt
  rw [slope_def_field]
  have : s - t₀ < 0 := by have := Set.mem_Iio.mp hlt; linarith
  exact div_nonneg_of_nonpos (by linarith) this.le


/-- Weak maximum principle for the heat equation on a cylinder over a ball. -/
theorem max_principle {d : ℕ} {κ : ℝ} (hκ : 0 < κ) {w : EuclideanSpace ℝ (Fin d) → ℝ → ℝ}
    {y : EuclideanSpace ℝ (Fin d)} {r T' : ℝ} (hT' : 0 ≤ T')
    (hcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => w p.1 p.2)
      (Metric.closedBall y r ×ˢ Set.Icc 0 T'))
    (hsub : ∀ x ∈ Metric.ball y r, ∀ t ∈ Set.Ioc 0 T',
      ContDiffAt ℝ 2 (fun z => w z t) x ∧
        HasDerivAt (fun s => w x s) (κ * Δ (fun z => w z t) x) t)
    (hbot : ∀ x ∈ Metric.closedBall y r, w x 0 ≤ 0)
    (hside : ∀ x, dist x y = r → ∀ t ∈ Set.Icc 0 T', w x t ≤ 0) :
    ∀ x ∈ Metric.closedBall y r, ∀ t ∈ Set.Icc 0 T', w x t ≤ 0 := by
  intro x₁ hx₁ t₁ ht₁
  by_contra hpos
  rw [not_le] at hpos
  set m := w x₁ t₁
  set ε := m / (2 * (T' + 1)) with hεdef
  have hε : 0 < ε := by positivity
  set K := Metric.closedBall y r ×ˢ Set.Icc (0 : ℝ) T'
  have hK : IsCompact K := (isCompact_closedBall y r).prod isCompact_Icc
  have hvc : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => w p.1 p.2 - ε * p.2) K :=
    hcont.sub (continuousOn_const.mul continuous_snd.continuousOn)
  obtain ⟨⟨x₀, t₀⟩, hmem, hmax⟩ := hK.exists_isMaxOn ⟨(x₁, t₁), hx₁, ht₁⟩ hvc
  have hmax' : ∀ x t, x ∈ Metric.closedBall y r → t ∈ Set.Icc 0 T' →
      w x t - ε * t ≤ w x₀ t₀ - ε * t₀ := fun x t hx ht =>
    isMaxOn_iff.mp hmax (x, t) ⟨hx, ht⟩
  have hv1 := hmax' x₁ t₁ hx₁ ht₁
  have hεT : ε * t₁ < m := by
    have h1 : ε * t₁ ≤ ε * T' := mul_le_mul_of_nonneg_left ht₁.2 hε.le
    have h2 : ε * T' < m := by
      rw [hεdef, div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
      nlinarith
    linarith
  have hv0 : 0 < w x₀ t₀ - ε * t₀ := by linarith
  obtain ⟨hx₀, ht₀⟩ : x₀ ∈ Metric.closedBall y r ∧ t₀ ∈ Set.Icc 0 T' := hmem
  have ht₀pos : 0 < t₀ := by
    rcases ht₀.1.eq_or_lt with h | h
    · exfalso
      have := hbot x₀ hx₀
      rw [← h] at hv0
      linarith
    · exact h
  have hx₀b : x₀ ∈ Metric.ball y r := by
    rcases (Metric.mem_closedBall.mp hx₀).eq_or_lt with h | h
    · exfalso
      have := hside x₀ h t₀ ht₀
      nlinarith
    · exact h
  obtain ⟨hC2, hder⟩ := hsub x₀ hx₀b t₀ ⟨ht₀pos, ht₀.2⟩
  have hlm : IsLocalMax (fun z => w z t₀) x₀ := by
    filter_upwards [Metric.isOpen_ball.mem_nhds hx₀b] with z hz
    have := hmax' z t₀ (Metric.ball_subset_closedBall hz) ht₀
    linarith
  have hlap := laplacian_nonpos_of_isLocalMax hC2 hlm
  have hder2 : HasDerivAt (fun s => w x₀ s - ε * s) (κ * Δ (fun z => w z t₀) x₀ - ε) t₀ := by
    have hε' : HasDerivAt (fun s : ℝ => ε * s) ε t₀ := by
      simpa using (hasDerivAt_id t₀).const_mul ε
    exact hder.sub hε'
  have htime : 0 ≤ κ * Δ (fun z => w z t₀) x₀ - ε := by
    refine deriv_nonneg_of_left_max hder2 ?_
    filter_upwards [Ioo_mem_nhdsLT ht₀pos] with s hs
    exact hmax' x₀ s hx₀ ⟨hs.1.le, hs.2.le.trans ht₀.2⟩
  nlinarith [mul_nonpos_of_nonneg_of_nonpos hκ.le hlap]


/-- The comparison function of Tychonoff's argument. -/
noncomputable def psi (d : ℕ) (κ T₀ : ℝ) (y x : EuclideanSpace ℝ (Fin d)) (t : ℝ) : ℝ :=
  (T₀ - t) ^ (-(d : ℝ) / 2) * gau (1 / (4 * κ * (T₀ - t))) y x

theorem psi_pos {d : ℕ} {κ T₀ t : ℝ} (ht : t < T₀) (y x : EuclideanSpace ℝ (Fin d)) :
    0 < psi d κ T₀ y x t := by
  unfold psi gau
  have : 0 < T₀ - t := by linarith
  positivity

theorem psi_contDiff {d : ℕ} (κ T₀ t : ℝ) (y : EuclideanSpace ℝ (Fin d)) :
    ContDiff ℝ 2 (fun z => psi d κ T₀ y z t) := by
  unfold psi gau
  exact contDiff_const.mul (ContDiff.exp (contDiff_const.mul
    ((contDiff_id.sub contDiff_const).norm_sq ℝ)))

theorem psi_heat {d : ℕ} {κ T₀ t : ℝ} (hκ : 0 < κ) (ht : t < T₀)
    (y x : EuclideanSpace ℝ (Fin d)) :
    HasDerivAt (fun s => psi d κ T₀ y x s) (κ * Δ (fun z => psi d κ T₀ y z t) x) t := by
  have hσ : 0 < T₀ - t := by linarith
  set ρ := ‖x - y‖ ^ 2
  have hA : HasDerivAt (fun s => (T₀ - s) ^ (-(d : ℝ) / 2))
      ((-1) * (-(d : ℝ) / 2) * (T₀ - t) ^ (-(d : ℝ) / 2 - 1)) t := by
    have h1 : HasDerivAt (fun s : ℝ => T₀ - s) (-1) t := by
      simpa using (hasDerivAt_id t).const_sub T₀
    exact h1.rpow_const (Or.inl hσ.ne')
  have hB : HasDerivAt (fun s => (4 * κ * (T₀ - s))⁻¹ * ρ)
      (-(4 * κ * (-1)) / (4 * κ * (T₀ - t)) ^ 2 * ρ) t := by
    have h1 : HasDerivAt (fun s : ℝ => 4 * κ * (T₀ - s)) (4 * κ * (-1)) t := by
      have : HasDerivAt (fun s : ℝ => T₀ - s) (-1) t := by
        simpa using (hasDerivAt_id t).const_sub T₀
      exact this.const_mul (4 * κ)
    exact (h1.inv (by positivity)).mul_const ρ
  have hfun : (fun s => psi d κ T₀ y x s) =
      fun s => (T₀ - s) ^ (-(d : ℝ) / 2) * exp ((4 * κ * (T₀ - s))⁻¹ * ρ) := by
    ext s; unfold psi gau; rw [one_div]
  rw [hfun]
  have hlap : Δ (fun z => psi d κ T₀ y z t) x = (T₀ - t) ^ (-(d : ℝ) / 2) *
      ((2 * (1 / (4 * κ * (T₀ - t))) * d + 4 * (1 / (4 * κ * (T₀ - t))) ^ 2 * ρ) *
        gau (1 / (4 * κ * (T₀ - t))) y x) := by
    have := laplacian_gau (d := d) ((T₀ - t) ^ (-(d : ℝ) / 2)) (1 / (4 * κ * (T₀ - t))) y x
    exact this
  rw [hlap]
  convert hA.mul hB.exp using 1
  rw [rpow_sub_one hσ.ne']
  unfold gau
  rw [one_div]
  field_simp
  ring

theorem psi_continuousAt {d : ℕ} {κ T₀ : ℝ} (hκ : 0 < κ) (y : EuclideanSpace ℝ (Fin d))
    (p : EuclideanSpace ℝ (Fin d) × ℝ) (hp : p.2 < T₀) :
    ContinuousAt (fun q : EuclideanSpace ℝ (Fin d) × ℝ => psi d κ T₀ y q.1 q.2) p := by
  have hσ : T₀ - p.2 ≠ 0 := by linarith
  unfold psi gau
  refine ContinuousAt.mul ?_ ?_
  · exact ContinuousAt.rpow_const (by fun_prop) (Or.inl hσ)
  · refine ContinuousAt.rexp (ContinuousAt.mul ?_ (by fun_prop))
    refine ContinuousAt.div continuousAt_const (by fun_prop) ?_
    exact mul_ne_zero (by positivity) hσ


theorem lap_sub_smul {d : ℕ} {f g : EuclideanSpace ℝ (Fin d) → ℝ} {x : EuclideanSpace ℝ (Fin d)}
    (hf : ContDiffAt ℝ 2 f x) (hg : ContDiffAt ℝ 2 g x) (μ : ℝ) :
    Δ (fun z => f z - μ * g z) x = Δ f x - μ * Δ g x := by
  have h1 : (fun z => f z - μ * g z) = f - μ • g := by ext z; simp
  have hg' : ContDiffAt ℝ 2 (μ • g) x := hg.const_smul μ
  rw [h1, hf.laplacian_sub hg', InnerProductSpace.laplacian_smul μ hg, smul_eq_mul]

/-- Uniqueness on a short time slab, one sign. -/
theorem short_time {d : ℕ} {κ M a T : ℝ} (hκ : 0 < κ) (ha : 0 < a) (hM : 0 ≤ M)
    (hT : 32 * a * κ * T ≤ 1)
    (u : EuclideanSpace ℝ (Fin d) → ℝ → ℝ)
    (hcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2)
      (Set.univ ×ˢ Set.Icc 0 T))
    (hspace : ∀ x, ∀ t ∈ Set.Ioo 0 T, ContDiffAt ℝ 2 (fun y => u y t) x)
    (hheat : ∀ x, ∀ t ∈ Set.Ioo 0 T, HasDerivAt (fun s => u x s) (κ * Δ (fun y => u y t) x) t)
    (hstart : ∀ x, u x 0 = 0)
    (hgrowth : ∀ x, ∀ t ∈ Set.Icc 0 T, |u x t| ≤ M * exp (a * ‖x‖ ^ 2)) :
    ∀ x, ∀ t ∈ Set.Icc 0 T, u x t ≤ 0 := by
  set T₀ := 1 / (16 * a * κ) with hT₀def
  have hT₀ : 0 < T₀ := by positivity
  have hTT₀ : 2 * T ≤ T₀ := by
    rw [hT₀def, le_div_iff₀ (by positivity)]; linarith
  have hγ : 1 / (4 * κ * T₀) = 4 * a := by
    rw [hT₀def]; field_simp; norm_num
  have hint : ∀ y, ∀ ts ∈ Set.Ioo 0 T, u y ts ≤ 0 := by
    intro y ts hts
    have hts0 := hts.1
    have htsT := hts.2
    have hσ : 0 < T₀ - ts := by linarith
    have key : ∀ μ > 0, u y ts ≤ μ * (T₀ - ts) ^ (-(d : ℝ) / 2) := by
      intro μ hμ
      set c₀ := μ * T₀ ^ (-(d : ℝ) / 2)
      have hc₀ : 0 < c₀ := by positivity
      set Kc := M * exp (2 * a * ‖y‖ ^ 2) / c₀
      have hKc : 0 ≤ Kc := by positivity
      set r := sqrt (Kc / (2 * a)) + 1
      have hr : 0 < r := by positivity
      have hr2 : Kc ≤ exp (2 * a * r ^ 2) := by
        have h1 : Kc / (2 * a) ≤ r ^ 2 := by
          have hs := sq_sqrt (show 0 ≤ Kc / (2 * a) by positivity)
          have hs0 := sqrt_nonneg (Kc / (2 * a))
          nlinarith
        have h2 : Kc ≤ 2 * a * r ^ 2 := by
          rw [div_le_iff₀ (by positivity)] at h1; linarith
        linarith [add_one_le_exp (2 * a * r ^ 2)]
      set w := fun x t => u x t - μ * psi d κ T₀ y x t
      have hmp := max_principle hκ (w := w) (y := y) (r := r) (T' := ts) hts0.le ?_ ?_ ?_ ?_
      · have := hmp y (Metric.mem_closedBall_self hr.le) ts ⟨hts0.le, le_rfl⟩
        simp only [w, psi, gau, sub_self, norm_zero] at this
        simpa using this
      · -- continuity
        refine (hcont.mono ?_).sub (continuousOn_const.mul fun p hp => ?_)
        · exact Set.prod_mono (Set.subset_univ _) (Set.Icc_subset_Icc le_rfl htsT.le)
        · refine (psi_continuousAt hκ y p ?_).continuousWithinAt
          have := hp.2.2
          linarith
      · -- heat equation for w
        intro x _ t ht
        have htT : t ∈ Set.Ioo 0 T := ⟨ht.1, lt_of_le_of_lt ht.2 htsT⟩
        have htT₀ : t < T₀ := by linarith [ht.2]
        have hC1 := hspace x t htT
        have hC2 := (psi_contDiff (d := d) κ T₀ t y).contDiffAt (x := x)
        refine ⟨hC1.sub (contDiffAt_const.mul hC2), ?_⟩
        have hd := (hheat x t htT).sub ((psi_heat hκ htT₀ y x).const_mul μ)
        convert hd using 1
        show κ * Δ (fun z => u z t - μ * psi d κ T₀ y z t) x = _
        rw [lap_sub_smul hC1 hC2 μ]
        ring
      · -- bottom
        intro x _
        simp only [w, hstart, zero_sub, neg_nonpos]
        exact (mul_pos hμ (psi_pos (by linarith) y x)).le
      · -- side
        intro x hx t ht
        have htT : t ∈ Set.Icc 0 T := ⟨ht.1, ht.2.trans htsT.le⟩
        have htT₀ : t < T₀ := by linarith [ht.2]
        have hσt : 0 < T₀ - t := by linarith
        simp only [w]
        have hxy : ‖x - y‖ = r := by rw [← dist_eq_norm]; exact hx
        have hxn : ‖x‖ ^ 2 ≤ 2 * ‖y‖ ^ 2 + 2 * r ^ 2 := by
          have h1 : ‖x‖ ≤ ‖y‖ + r := by
            calc ‖x‖ = ‖(x - y) + y‖ := by congr 1; abel
              _ ≤ ‖x - y‖ + ‖y‖ := norm_add_le _ _
              _ = ‖y‖ + r := by rw [hxy]; ring
          nlinarith [norm_nonneg x, norm_nonneg y, sq_nonneg (‖y‖ - r)]
        have hu : u x t ≤ M * exp (2 * a * ‖y‖ ^ 2) * exp (2 * a * r ^ 2) := by
          calc u x t ≤ |u x t| := le_abs_self _
            _ ≤ M * exp (a * ‖x‖ ^ 2) := hgrowth x t htT
            _ ≤ M * exp (a * (2 * ‖y‖ ^ 2 + 2 * r ^ 2)) := by gcongr
            _ = M * exp (2 * a * ‖y‖ ^ 2) * exp (2 * a * r ^ 2) := by
                rw [mul_assoc, ← exp_add]; ring_nf
        have hpsi : c₀ * exp (4 * a * r ^ 2) ≤ μ * psi d κ T₀ y x t := by
          unfold psi gau
          rw [hxy]
          have e1 : T₀ ^ (-(d : ℝ) / 2) ≤ (T₀ - t) ^ (-(d : ℝ) / 2) := by
            apply rpow_le_rpow_of_nonpos hσt (by linarith [ht.1])
            have : (0 : ℝ) ≤ d := Nat.cast_nonneg d
            linarith
          have e2 : 4 * a ≤ 1 / (4 * κ * (T₀ - t)) := by
            rw [← hγ]
            apply one_div_le_one_div_of_le (by positivity)
            nlinarith [ht.1]
          have e3 : exp (4 * a * r ^ 2) ≤ exp (1 / (4 * κ * (T₀ - t)) * r ^ 2) := by
            gcongr
          calc c₀ * exp (4 * a * r ^ 2) = μ * (T₀ ^ (-(d : ℝ) / 2) * exp (4 * a * r ^ 2)) := by
                simp only [c₀]; ring
            _ ≤ μ * ((T₀ - t) ^ (-(d : ℝ) / 2) * exp (1 / (4 * κ * (T₀ - t)) * r ^ 2)) := by
                gcongr
        have hfin : M * exp (2 * a * ‖y‖ ^ 2) * exp (2 * a * r ^ 2) ≤ c₀ * exp (4 * a * r ^ 2) := by
          have h4 : exp (4 * a * r ^ 2) = exp (2 * a * r ^ 2) * exp (2 * a * r ^ 2) := by
            rw [← exp_add]; ring_nf
          have hKc' : M * exp (2 * a * ‖y‖ ^ 2) = c₀ * Kc := by
            simp only [Kc]; field_simp
          rw [h4, hKc']
          have := exp_pos (2 * a * r ^ 2)
          calc c₀ * Kc * exp (2 * a * r ^ 2) ≤ c₀ * exp (2 * a * r ^ 2) * exp (2 * a * r ^ 2) := by
                gcongr
            _ = _ := by ring
        linarith
    have hP : 0 < (T₀ - ts) ^ (-(d : ℝ) / 2) := by positivity
    by_contra hneg
    rw [not_le] at hneg
    have := key (u y ts / (2 * (T₀ - ts) ^ (-(d : ℝ) / 2))) (by positivity)
    have e : u y ts / (2 * (T₀ - ts) ^ (-(d : ℝ) / 2)) * (T₀ - ts) ^ (-(d : ℝ) / 2) =
        u y ts / 2 := by field_simp
    rw [e] at this
    linarith
  intro x t ht
  rcases eq_or_lt_of_le ht.1 with h0 | h0
  · rw [← h0, hstart]
  rcases eq_or_lt_of_le ht.2 with hTt | hTt
  · -- t = T: by continuity from the left
    have hc : ContinuousWithinAt (fun s => u x s) (Set.Icc 0 T) T := by
      have h1 : ContinuousOn (fun s => u x s) (Set.Icc 0 T) :=
        hcont.comp (continuous_const.prodMk continuous_id).continuousOn
          (fun s hs => ⟨Set.mem_univ _, hs⟩)
      exact h1 _ ⟨by linarith, le_rfl⟩
    have hT0 : 0 < T := by linarith
    have hlim : Tendsto (fun s => u x s) (𝓝[<] T) (𝓝 (u x T)) := by
      have := (hc.mono Set.Ico_subset_Icc_self).tendsto
      rwa [nhdsWithin_Ico_eq_nhdsLT hT0] at this
    rw [hTt]
    refine le_of_tendsto hlim ?_
    filter_upwards [Ioo_mem_nhdsLT hT0] with s hs
    exact hint x s hs
  · exact hint x t ⟨h0, hTt⟩


theorem slab_le {d : ℕ} {κ M a T : ℝ} (hκ : 0 < κ) (ha : 0 < a) (hM : 0 ≤ M)
    (u : EuclideanSpace ℝ (Fin d) → ℝ → ℝ)
    (hcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2)
      (Set.univ ×ˢ Set.Icc 0 T))
    (hspace : ∀ x, ∀ t ∈ Set.Ioo 0 T, ContDiffAt ℝ 2 (fun y => u y t) x)
    (hheat : ∀ x, ∀ t ∈ Set.Ioo 0 T, HasDerivAt (fun s => u x s) (κ * Δ (fun y => u y t) x) t)
    (hgrowth : ∀ x, ∀ t ∈ Set.Icc 0 T, |u x t| ≤ M * exp (a * ‖x‖ ^ 2))
    {s₀ T₁ : ℝ} (hs₀ : 0 ≤ s₀) (hsum : s₀ + T₁ ≤ T) (hsmall : 32 * a * κ * T₁ ≤ 1)
    (hzero : ∀ x, u x s₀ = 0) :
    ∀ x, ∀ s ∈ Set.Icc 0 T₁, u x (s₀ + s) ≤ 0 := by
  refine short_time hκ ha hM hsmall (fun x s => u x (s₀ + s)) ?_ ?_ ?_ ?_ ?_
  · have hc : Continuous fun p : EuclideanSpace ℝ (Fin d) × ℝ => (p.1, s₀ + p.2) := by fun_prop
    refine hcont.comp (f := fun p : EuclideanSpace ℝ (Fin d) × ℝ => (p.1, s₀ + p.2))
      hc.continuousOn ?_
    intro p hp
    exact ⟨Set.mem_univ _, by simp only; linarith [hp.2.1], by simp only; linarith [hp.2.2]⟩
  · intro x t ht
    exact hspace x (s₀ + t) ⟨by linarith [ht.1], by linarith [ht.2]⟩
  · intro x t ht
    exact (hheat x (s₀ + t) ⟨by linarith [ht.1], by linarith [ht.2]⟩).comp_const_add s₀ t
  · intro x
    simp only [add_zero]
    exact hzero x
  · intro x t ht
    exact hgrowth x (s₀ + t) ⟨by linarith [ht.1], by linarith [ht.2]⟩

#print axioms innerR_apply
#print axioms hasFDerivAt_gau
#print axioms hasFDerivAt_Dgau
#print axioms D2gau_apply
#print axioms sum_D2gau
#print axioms norm_Dgau_le
#print axioms norm_D2gau_le
#print axioms laplacian_gau
#print axioms D2gau_sub
#print axioms continuous_D2gau0
#print axioms Dgau_sub
#print axioms continuous_Dgau0
#print axioms continuous_gau
#print axioms poly_gauss
#print axioms integrable_gauss
#print axioms integral_gauss
#print axioms integrable_sq_gauss
#print axioms integral_sq_gauss
#print axioms sq_add_le_split
#print axioms master_est
#print axioms dom_bound
#print axioms hk_eq_gau
#print axioms hk_hasDerivAt_time
#print axioms hk_time_eq_lap
#print axioms le_one_add_sq
#print axioms gau_family_bounds
#print axioms conv_bound
#print axioms conv_smooth
#print axioms conv_C2_lap
#print axioms time_bound
#print axioms exists_t1
#print axioms conv_heat
#print axioms integral_g0
#print axioms hk_scale
#print axioms conv_rescale
#print axioms conv_limit
#print axioms hk_eq_gau0
#print axioms hk_eq_exp
#print axioms second_deriv_nonpos_of_isLocalMax
#print axioms fderiv_fderiv_nonpos_of_isLocalMax
#print axioms laplacian_nonpos_of_isLocalMax
#print axioms deriv_nonneg_of_left_max
#print axioms max_principle
#print axioms psi_pos
#print axioms psi_contDiff
#print axioms psi_heat
#print axioms psi_continuousAt
#print axioms lap_sub_smul
#print axioms short_time
#print axioms slab_le

/-- Convolving any start with the kernel solves the heat equation. Let the diffusivity `κ` be a
positive constant and the start `f` be continuous with `|f(y)| ≤ M e^(a|y|²)`. Then
`u(x, t) = ∫ G(x - y, t) f(y) dy` is twice differentiable in space and solves `u_t = κ Δu` at
every point, for every time `t > 0` with `4aκt < 1`, and at every point `u(x, t) → f(x)` as
`t → 0` from above. -/
theorem heat_kernel_convolution_solves_cauchy_problem {d : ℕ} {κ M a : ℝ} (hκ : 0 < κ)
    (f : EuclideanSpace ℝ (Fin d) → ℝ) (hf : Continuous f)
    (hgrowth : ∀ y, |f y| ≤ M * exp (a * ‖y‖ ^ 2)) :
    let u : EuclideanSpace ℝ (Fin d) → ℝ → ℝ := fun x t => ∫ y, heatKernel d κ (x - y) t * f y
    (∀ x t, 0 < t → 4 * a * κ * t < 1 →
        ContDiffAt ℝ 2 (fun y => u y t) x ∧
          HasDerivAt (fun s => u x s) (κ * Δ (fun y => u y t) x) t) ∧
      ∀ x, Tendsto (fun t => u x t) (𝓝[>] 0) (𝓝 (f x)) := by
  intro u
  exact ⟨fun x t ht hat => conv_heat hκ f hf hgrowth x t ht hat,
    fun x => conv_limit hκ f hf hgrowth x⟩

/-- The kernel is the answer to a point mass of heat. For a positive diffusivity `κ` and every
time `t > 0`: the kernel holds exactly one unit of heat, its mean squared distance from the spot
is `2dκt` (width `√(2κt)` in each of the `d` directions), and it is smooth in space and solves
`G_t = κ ΔG`. As `t → 0` from above, the average of any smooth bounded shape `φ` against
`G(·, t)` tends to `φ(0)`: the kernel starts as the point mass `δ`. -/
theorem heat_kernel_is_point_source_solution {d : ℕ} {κ : ℝ} (hκ : 0 < κ) :
    (∀ t, 0 < t → ∫ x, heatKernel d κ x t = 1) ∧
      (∀ t, 0 < t → ∫ x, ‖x‖ ^ 2 * heatKernel d κ x t = 2 * d * κ * t) ∧
      (∀ x t, 0 < t →
        ContDiffAt ℝ 2 (fun y => heatKernel d κ y t) x ∧
          HasDerivAt (fun s => heatKernel d κ x s) (κ * Δ (fun y => heatKernel d κ y t) x) t) ∧
      ∀ φ : EuclideanSpace ℝ (Fin d) → ℝ, ContDiff ℝ ∞ φ → (∃ C, ∀ x, |φ x| ≤ C) →
        Tendsto (fun t => ∫ x, heatKernel d κ x t * φ x) (𝓝[>] 0) (𝓝 (φ 0)) := by
  refine ⟨fun t ht => ?_, fun t ht => ?_, fun x t ht => ?_, fun φ hφ ⟨C, hC⟩ => ?_⟩
  · simp_rw [hk_eq_exp κ t]
    rw [integral_const_mul, integral_gauss (by positivity)]
    have : π / (1 / (4 * κ * t)) = 4 * π * κ * t := by field_simp
    rw [this, neg_div, rpow_neg (by positivity)]
    exact inv_mul_cancel₀ (by positivity)
  · simp_rw [hk_eq_exp κ t]
    have : ∀ x : EuclideanSpace ℝ (Fin d), ‖x‖ ^ 2 * ((4 * π * κ * t) ^ (-(d : ℝ) / 2) *
        exp (-(1 / (4 * κ * t)) * ‖x‖ ^ 2)) = (4 * π * κ * t) ^ (-(d : ℝ) / 2) *
        (‖x‖ ^ 2 * exp (-(1 / (4 * κ * t)) * ‖x‖ ^ 2)) := fun x => by ring
    simp_rw [this]
    rw [integral_const_mul, integral_sq_gauss (by positivity)]
    have : π / (1 / (4 * κ * t)) = 4 * π * κ * t := by field_simp
    rw [this, neg_div, rpow_neg (by positivity)]
    have hpos : 0 < (4 * π * κ * t) ^ ((d : ℝ) / 2) := by positivity
    field_simp
    ring
  · have hfun : (fun y => heatKernel d κ y t) =
        fun y => (4 * π * κ * t) ^ (-(d : ℝ) / 2) * gau (-(1 / (4 * κ * t))) 0 y := by
      ext y; exact hk_eq_gau0 κ t y
    refine ⟨?_, ?_⟩
    · rw [hfun]
      have : ContDiff ℝ 2 (fun y : EuclideanSpace ℝ (Fin d) =>
          (4 * π * κ * t) ^ (-(d : ℝ) / 2) * gau (-(1 / (4 * κ * t))) 0 y) := by
        unfold gau
        simp only [sub_zero]
        exact contDiff_const.mul (ContDiff.exp (contDiff_const.mul (contDiff_norm_sq ℝ)))
      exact this.contDiffAt
    · rw [hfun, laplacian_gau]
      have h := hk_hasDerivAt_time (d := d) hκ ht x
      convert h using 1
      rw [hk_eq_gau0 κ t x, hk_time_eq_lap hκ ht, sub_zero]
      ring
  · have hg : ∀ y, |φ y| ≤ C * exp (0 * ‖y‖ ^ 2) := fun y => by simpa using hC y
    have := conv_limit hκ φ hφ.continuous hg 0
    refine this.congr (fun t => ?_)
    congr 1; ext y
    unfold heatKernel
    rw [zero_sub, norm_neg]

/-- Uniqueness with limited growth (Tychonoff). Let `κ > 0`, and let `u` be continuous for all
`x` in `ℝ^d` and `0 ≤ t ≤ T`, with `u_t` and all second space derivatives existing and continuous
for `0 < t < T`. If `u_t = κ Δu` there, `u(x, 0) = 0`, and `|u(x, t)| ≤ M e^(a|x|²)` for all `x`
and `0 ≤ t ≤ T`, then `u = 0` everywhere on `ℝ^d × [0, T]`. Applied to the difference of two
solutions, the solution with limited growth is the only one. -/
theorem heat_equation_unique_with_limited_growth {d : ℕ} {κ M a T : ℝ} (hκ : 0 < κ)
    (u : EuclideanSpace ℝ (Fin d) → ℝ → ℝ)
    (hcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2)
      (Set.univ ×ˢ Set.Icc 0 T))
    (hspace : ∀ x, ∀ t ∈ Set.Ioo 0 T, ContDiffAt ℝ 2 (fun y => u y t) x)
    (hheat : ∀ x, ∀ t ∈ Set.Ioo 0 T, HasDerivAt (fun s => u x s) (κ * Δ (fun y => u y t) x) t)
    (hut : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => deriv (fun s => u p.1 s) p.2)
      (Set.univ ×ˢ Set.Ioo 0 T))
    (huxx : ContinuousOn
      (fun p : EuclideanSpace ℝ (Fin d) × ℝ => iteratedFDeriv ℝ 2 (fun y => u y p.2) p.1)
      (Set.univ ×ˢ Set.Ioo 0 T))
    (hstart : ∀ x, u x 0 = 0)
    (hgrowth : ∀ x, ∀ t ∈ Set.Icc 0 T, |u x t| ≤ M * exp (a * ‖x‖ ^ 2)) :
    ∀ x, ∀ t ∈ Set.Icc 0 T, u x t = 0 := by
  have _ := hut; have _ := huxx
  rcases lt_or_ge T 0 with hT | hT
  · intro x t ht; exact absurd (ht.1.trans ht.2) (not_le.mpr hT)
  have hM : 0 ≤ M := by
    have := hgrowth 0 0 ⟨le_rfl, hT⟩
    rw [hstart] at this
    simp only [abs_zero, norm_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow,
      mul_zero, exp_zero, mul_one] at this
    exact this
  set a' := max a 1
  have ha' : 0 < a' := lt_of_lt_of_le one_pos (le_max_right _ _)
  have hg' : ∀ x, ∀ t ∈ Set.Icc 0 T, |u x t| ≤ M * exp (a' * ‖x‖ ^ 2) := fun x t ht =>
    (hgrowth x t ht).trans (by gcongr; exact le_max_left _ _)
  -- the same facts for `-u`
  have hcont' : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => -u p.1 p.2)
      (Set.univ ×ˢ Set.Icc 0 T) := hcont.neg
  have hspace' : ∀ x, ∀ t ∈ Set.Ioo 0 T, ContDiffAt ℝ 2 (fun y => -u y t) x :=
    fun x t ht => (hspace x t ht).neg
  have hheat' : ∀ x, ∀ t ∈ Set.Ioo 0 T,
      HasDerivAt (fun s => -u x s) (κ * Δ (fun y => -u y t) x) t := by
    intro x t ht
    have h1 : (fun y => -u y t) = -(fun y => u y t) := rfl
    rw [h1, InnerProductSpace.laplacian_neg, Pi.neg_apply, mul_neg]
    exact (hheat x t ht).neg
  have hg'' : ∀ x, ∀ t ∈ Set.Icc 0 T, |-u x t| ≤ M * exp (a' * ‖x‖ ^ 2) := fun x t ht => by
    rw [abs_neg]; exact hg' x t ht
  set τ := 1 / (32 * a' * κ) with hτdef
  have hτ : 0 < τ := by positivity
  have hslab : ∀ n : ℕ, ∀ x, ∀ t ∈ Set.Icc 0 T, t ≤ n * τ → u x t = 0 := by
    intro n
    induction n with
    | zero =>
      intro x t ht htn
      simp only [Nat.cast_zero, zero_mul] at htn
      rw [le_antisymm htn ht.1, hstart]
    | succ n ih =>
      intro x t ht htn
      by_cases hle : t ≤ n * τ
      · exact ih x t ht hle
      rw [not_le] at hle
      set s₀ := (n : ℝ) * τ
      have hs₀ : 0 ≤ s₀ := by positivity
      have hs₀T : s₀ < T := lt_of_lt_of_le hle ht.2
      set T₁ := min τ (T - s₀)
      have hT₁τ : T₁ ≤ τ := min_le_left _ _
      have hsum : s₀ + T₁ ≤ T := by have := min_le_right τ (T - s₀); linarith
      have hsmall : 32 * a' * κ * T₁ ≤ 1 := by
        have : 32 * a' * κ * τ = 1 := by rw [hτdef]; field_simp
        have h32 : 0 ≤ 32 * a' * κ := by positivity
        nlinarith
      have hzero : ∀ x, u x s₀ = 0 := fun x => ih x s₀ ⟨hs₀, hs₀T.le⟩ le_rfl
      have hzero' : ∀ x, -u x s₀ = 0 := fun x => by rw [hzero x, neg_zero]
      have h1 := slab_le hκ ha' hM u hcont hspace hheat hg' hs₀ hsum hsmall hzero
      have h2 := slab_le hκ ha' hM (fun x t => -u x t) hcont' hspace' hheat' hg'' hs₀ hsum
        hsmall hzero'
      have hs : t - s₀ ∈ Set.Icc 0 T₁ := by
        refine ⟨by linarith, le_min ?_ (by linarith [ht.2])⟩
        push_cast at htn
        linarith
      have e : s₀ + (t - s₀) = t := by ring
      have a1 := h1 x (t - s₀) hs
      have a2 := h2 x (t - s₀) hs
      simp only [e] at a1 a2
      linarith
  intro x t ht
  obtain ⟨n, hn⟩ := exists_nat_ge (T / τ)
  refine hslab n x t ht ?_
  have : T ≤ n * τ := by rwa [div_le_iff₀ hτ] at hn
  linarith [ht.2]

-- The card's worked numbers, exactly, for copper (κ = 1.11e-4 m²/s) at t = 10 s.
-- Heat in the slice: 100 K × 0.01 m = 1 K·m.
example : (100 : ℚ) * (1 / 100) = 1 := by norm_num
-- 4κt = 4.44e-3 m²; the variance 2κt = 2.22e-3 m² (width √(2κt) ≈ 4.71 cm).
example : 4 * (111 / 1000000 : ℚ) * 10 = 444 / 100000 := by norm_num
example : 2 * (111 / 1000000 : ℚ) * 10 = 222 / 100000 := by norm_num
-- Mean squared distance 2dκt in a block (d = 3): 6.66e-3 m² (rms ≈ 8.16 cm).
example : 2 * 3 * (111 / 1000000 : ℚ) * 10 = 666 / 100000 := by norm_num
-- From 10 s to 40 s the peak falls by (40/10)^(d/2): 2 for the rod, 4 for the sheet, 8 for the
-- block (2² = 4, 4 = 4¹, 8² = 4³).
example : (2 : ℚ) ^ 2 = 40 / 10 := by norm_num
example : (4 : ℚ) = (40 / 10) ^ 1 := by norm_num
example : (8 : ℚ) ^ 2 = (40 / 10) ^ 3 := by norm_num
-- Grid spacings 1/400, 1/800, 1/1600 m are 2.5, 1.25 and 0.625 mm.
example : (1000 : ℚ) / 400 = 5 / 2 ∧ (1000 : ℚ) / 800 = 5 / 4 ∧ (1000 : ℚ) / 1600 = 5 / 8 := by
  norm_num

#print axioms heat_kernel_convolution_solves_cauchy_problem
#print axioms heat_kernel_is_point_source_solution
#print axioms heat_equation_unique_with_limited_growth
