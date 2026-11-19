-- Principal bundle and connection: on a coordinate patch, a gauge change turns the curvature F = dA + A ∧ A into g⁻¹ F g, a small square loop leaves I + h² [A_x, A_y], and for a circle group the loop integral of A equals the area integral of F.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Matrix.Normed
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.FDeriv.CompCLM
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.ContDiff.Comp

open Filter Topology NormedSpace


/- Matrices get the operator norm, so that derivatives and the matrix exponential make sense.
Any of Mathlib's matrix norms gives the same topology, so nothing below depends on this choice. -/
attribute [local instance] Matrix.linftyOpNormedRing Matrix.linftyOpNormedAlgebra

variable {n : ℕ}

/-- Partial derivative along the first coordinate x of the patch. -/
noncomputable def dX {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℝ × ℝ → E) (p : ℝ × ℝ) : E :=
  fderiv ℝ f p (1, 0)

/-- Partial derivative along the second coordinate y of the patch. -/
noncomputable def dY {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℝ × ℝ → E) (p : ℝ × ℝ) : E :=
  fderiv ℝ f p (0, 1)

/-- The one part of the curvature two-form on a two-dimensional patch:
`F_xy = ∂_x A_y - ∂_y A_x + [A_x, A_y]`, with the bracket `[X, Y] = XY - YX`. -/
noncomputable def curvatureXY (Ax Ay : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ) (p : ℝ × ℝ) :
    Matrix (Fin n) (Fin n) ℝ :=
  dX Ay p - dY Ax p + (Ax p * Ay p - Ay p * Ax p)

/-- The x part of the gauge field after the gauge change `g`: `A'_x = g⁻¹ A_x g + g⁻¹ ∂_x g`. -/
noncomputable def gaugeX (g Ax : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ) (p : ℝ × ℝ) :
    Matrix (Fin n) (Fin n) ℝ :=
  (g p)⁻¹ * Ax p * g p + (g p)⁻¹ * dX g p

/-- The y part of the gauge field after the gauge change `g`: `A'_y = g⁻¹ A_y g + g⁻¹ ∂_y g`. -/
noncomputable def gaugeY (g Ay : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ) (p : ℝ × ℝ) :
    Matrix (Fin n) (Fin n) ℝ :=
  (g p)⁻¹ * Ay p * g p + (g p)⁻¹ * dY g p

lemma dX_mul' {a b : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (ha : DifferentiableAt ℝ a p) (hb : DifferentiableAt ℝ b p) :
    dX (fun q => a q * b q) p = a p * dX b p + dX a p * b p := by
  unfold dX
  erw [fderiv_fun_mul' ha hb]
  rfl

lemma dY_mul' {a b : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (ha : DifferentiableAt ℝ a p) (hb : DifferentiableAt ℝ b p) :
    dY (fun q => a q * b q) p = a p * dY b p + dY a p * b p := by
  unfold dY
  erw [fderiv_fun_mul' ha hb]
  rfl

lemma dX_add' {a b : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (ha : DifferentiableAt ℝ a p) (hb : DifferentiableAt ℝ b p) :
    dX (fun q => a q + b q) p = dX a p + dX b p := by
  unfold dX
  erw [fderiv_add ha hb]
  rfl

lemma dY_add' {a b : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (ha : DifferentiableAt ℝ a p) (hb : DifferentiableAt ℝ b p) :
    dY (fun q => a q + b q) p = dY a p + dY b p := by
  unfold dY
  erw [fderiv_add ha hb]
  rfl

lemma hasFDerivAt_matrix_inv' {g : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (hg : DifferentiableAt ℝ g p) (hu : IsUnit (g p)) :
    HasFDerivAt (fun q => (g q)⁻¹)
      ((-ContinuousLinearMap.mulLeftRight ℝ (Matrix (Fin n) (Fin n) ℝ) (g p)⁻¹ (g p)⁻¹).comp
        (fderiv ℝ g p)) p := by
  obtain ⟨u, hu⟩ := hu
  have hfun : (fun q => (g q)⁻¹) = Ring.inverse ∘ g :=
    funext fun q => Matrix.nonsing_inv_eq_ringInverse _
  have h1 : HasFDerivAt (Ring.inverse)
      (-ContinuousLinearMap.mulLeftRight ℝ (Matrix (Fin n) (Fin n) ℝ) (g p)⁻¹ (g p)⁻¹) (g p) := by
    rw [← hu, ← Matrix.coe_units_inv]
    exact hasFDerivAt_ringInverse u
  rw [hfun]
  exact h1.comp p hg.hasFDerivAt

lemma differentiableAt_matrix_inv' {g : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (hg : DifferentiableAt ℝ g p) (hu : IsUnit (g p)) :
    DifferentiableAt ℝ (fun q => (g q)⁻¹) p :=
  (hasFDerivAt_matrix_inv' hg hu).differentiableAt

lemma dX_inv' {g : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (hg : DifferentiableAt ℝ g p) (hu : IsUnit (g p)) :
    dX (fun q => (g q)⁻¹) p = -((g p)⁻¹ * dX g p * (g p)⁻¹) := by
  unfold dX
  erw [(hasFDerivAt_matrix_inv' hg hu).fderiv]
  rfl

lemma dY_inv' {g : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (hg : DifferentiableAt ℝ g p) (hu : IsUnit (g p)) :
    dY (fun q => (g q)⁻¹) p = -((g p)⁻¹ * dY g p * (g p)⁻¹) := by
  unfold dY
  erw [(hasFDerivAt_matrix_inv' hg hu).fderiv]
  rfl

lemma fderiv_fderiv_apply' {g : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (h : DifferentiableAt ℝ (fderiv ℝ g) p) (v w : ℝ × ℝ) :
    fderiv ℝ (fun q => fderiv ℝ g q w) p v = fderiv ℝ (fderiv ℝ g) p v w := by
  erw [fderiv_clm_apply h (differentiableAt_const w), fderiv_const]
  exact (congrArg (· + fderiv ℝ (fderiv ℝ g) p v w) (map_zero (fderiv ℝ g p))).trans (zero_add _)

lemma dX_dY_symm' {g : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ} {p : ℝ × ℝ}
    (hgp : ContDiffAt ℝ 2 g p) : dX (dY g) p = dY (dX g) p := by
  have hg2 : DifferentiableAt ℝ (fderiv ℝ g) p :=
    (hgp.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
  unfold dX dY
  erw [fderiv_fderiv_apply' hg2, fderiv_fderiv_apply' hg2]
  exact hgp.isSymmSndFDerivAt (by simp) (1, 0) (0, 1)

lemma exp_second_order (A : Matrix (Fin n) (Fin n) ℝ) :
    (fun h : ℝ => exp (h • A) - (1 + h • A + h ^ 2 • ((1/2 : ℝ) • (A * A))))
      =O[𝓝 0] (fun h : ℝ => h ^ 3) := by
  have H := (exp_hasFPowerSeriesAt_zero (𝕂 := ℝ) (𝔸 := Matrix (Fin n) (Fin n) ℝ)).isBigO_sub_partialSum_pow 3
  have ht : Tendsto (fun h : ℝ => h • A) (𝓝 0) (𝓝 0) := by
    have : Continuous (fun h : ℝ => h • A) := by fun_prop
    simpa using this.tendsto 0
  have H2 := H.comp_tendsto ht
  have H3 : (fun h : ℝ => ‖h • A‖ ^ 3) =O[𝓝 0] (fun h : ℝ => h ^ 3) := by
    refine Asymptotics.IsBigO.of_bound (‖A‖ ^ 3) (Filter.Eventually.of_forall fun h => ?_)
    rw [norm_smul, mul_pow]; simp [mul_comm, norm_pow]
  refine (H2.trans H3).congr_left (fun h => ?_)
  simp [FormalMultilinearSeries.partialSum, Finset.sum_range_succ, expSeries_apply_eq, smul_smul,
    pow_two, mul_comm (2⁻¹ : ℝ)]
  rfl

lemma pow_smul_isBigO_cube (X : Matrix (Fin n) (Fin n) ℝ) (k : ℕ) (hk : 3 ≤ k) :
    (fun h : ℝ => h ^ k • X) =O[𝓝 0] (fun h : ℝ => h ^ 3) := by
  have h1 : (fun h : ℝ => h ^ k • X) =O[𝓝 0] (fun h : ℝ => h ^ k) :=
    Asymptotics.IsBigO.of_bound ‖X‖ (Filter.Eventually.of_forall fun h => by
      rw [norm_smul, mul_comm])
  rcases hk.lt_or_eq with hk | hk
  · exact h1.trans (Asymptotics.isLittleO_pow_pow hk).isBigO
  · subst hk; exact h1

lemma mul_second_order {f g : ℝ → Matrix (Fin n) (Fin n) ℝ} {a b c a' b' c' : Matrix (Fin n) (Fin n) ℝ}
    (hf : (fun h : ℝ => f h - (a + h • b + h ^ 2 • c)) =O[𝓝 0] (fun h : ℝ => h ^ 3))
    (hg : (fun h : ℝ => g h - (a' + h • b' + h ^ 2 • c')) =O[𝓝 0] (fun h : ℝ => h ^ 3)) :
    (fun h : ℝ => f h * g h - (a * a' + h • (a * b' + b * a') + h ^ 2 • (a * c' + b * b' + c * a')))
      =O[𝓝 0] (fun h : ℝ => h ^ 3) := by
  set P : ℝ → Matrix (Fin n) (Fin n) ℝ := fun h => a + h • b + h ^ 2 • c with hP
  set Q : ℝ → Matrix (Fin n) (Fin n) ℝ := fun h => a' + h • b' + h ^ 2 • c' with hQ
  have hPc : Continuous P := by rw [hP]; fun_prop
  have hQc : Continuous Q := by rw [hQ]; fun_prop
  have hP1 : P =O[𝓝 0] (fun _ => (1 : ℝ)) := (hPc.tendsto 0).isBigO_one ℝ
  have hQ1 : Q =O[𝓝 0] (fun _ => (1 : ℝ)) := (hQc.tendsto 0).isBigO_one ℝ
  have hc3 : (fun h : ℝ => h ^ 3) =O[𝓝 0] (fun _ => (1 : ℝ)) :=
    ((continuous_pow 3).tendsto 0).isBigO_one ℝ
  have hR := hf
  have hS := hg
  have t1 : (fun h : ℝ => P h * Q h - (a * a' + h • (a * b' + b * a') + h ^ 2 • (a * c' + b * b' + c * a')))
      =O[𝓝 0] (fun h : ℝ => h ^ 3) := by
    have : (fun h : ℝ => P h * Q h - (a * a' + h • (a * b' + b * a') + h ^ 2 • (a * c' + b * b' + c * a')))
        = fun h : ℝ => h ^ 3 • (b * c' + c * b') + h ^ 4 • (c * c') := by
      funext h
      simp only [hP, hQ, mul_add, add_mul, smul_mul_assoc, mul_smul_comm, smul_smul, smul_add]
      ring_nf
      module
    rw [this]
    exact (pow_smul_isBigO_cube _ 3 le_rfl).add (pow_smul_isBigO_cube _ 4 (by norm_num))
  have t2 := (hP1.mul hS).congr_right (fun h => one_mul (h ^ 3))
  have t3 := (hR.mul hQ1).congr_right (fun h => mul_one (h ^ 3))
  have t4 := (hR.mul (hS.trans hc3)).congr_right (fun h => mul_one (h ^ 3))
  refine (((t1.add t2).add t3).add t4).congr_left (fun h => ?_)
  simp only [hP, hQ]
  noncomm_ring

/-- A gauge change only turns the curvature. On a patch `U` of the base, let the gauge field
`A = A_x dx + A_y dy` (matrix-valued) be smooth, and let the gauge change `g` be a smooth choice of
invertible matrix at each point. Then the new gauge field `A' = g⁻¹ A g + g⁻¹ dg` has curvature
`F' = g⁻¹ F g`, where `F = dA + A ∧ A`. -/
theorem curvature_gauge_change (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (Ax Ay g : ℝ × ℝ → Matrix (Fin n) (Fin n) ℝ)
    (hAx : ContDiffOn ℝ 1 Ax U) (hAy : ContDiffOn ℝ 1 Ay U)
    (hg : ContDiffOn ℝ 2 g U) (hginv : ∀ p ∈ U, IsUnit (g p).det)
    (p : ℝ × ℝ) (hp : p ∈ U) :
    curvatureXY (gaugeX g Ax) (gaugeY g Ay) p = (g p)⁻¹ * curvatureXY Ax Ay p * g p := by
  have hgp : ContDiffAt ℝ 2 g p := hg.contDiffAt (hU.mem_nhds hp)
  have hgd : DifferentiableAt ℝ g p := hgp.differentiableAt (by norm_num)
  have hg2 : DifferentiableAt ℝ (fderiv ℝ g) p :=
    (hgp.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
  have hAxd : DifferentiableAt ℝ Ax p :=
    (hAx.contDiffAt (hU.mem_nhds hp)).differentiableAt one_ne_zero
  have hAyd : DifferentiableAt ℝ Ay p :=
    (hAy.contDiffAt (hU.mem_nhds hp)).differentiableAt one_ne_zero
  have hu : IsUnit (g p) := (Matrix.isUnit_iff_isUnit_det _).mpr (hginv p hp)
  have hid := differentiableAt_matrix_inv' hgd hu
  have hdXg : DifferentiableAt ℝ (dX g) p := hg2.clm_apply (differentiableAt_const _)
  have hdYg : DifferentiableAt ℝ (dY g) p := hg2.clm_apply (differentiableAt_const _)
  have hGG : g p * (g p)⁻¹ = 1 := Matrix.mul_nonsing_inv _ (hginv p hp)
  have e1 : dX (gaugeY g Ay) p =
      -((g p)⁻¹ * dX g p * (g p)⁻¹) * Ay p * g p + (g p)⁻¹ * dX Ay p * g p
        + (g p)⁻¹ * Ay p * dX g p
        + (-((g p)⁻¹ * dX g p * (g p)⁻¹) * dY g p + (g p)⁻¹ * dX (dY g) p) := by
    show dX (fun q => (g q)⁻¹ * Ay q * g q + (g q)⁻¹ * dY g q) p = _
    rw [dX_add' (a := fun q => (g q)⁻¹ * Ay q * g q) (b := fun q => (g q)⁻¹ * dY g q)
        ((hid.mul hAyd).mul hgd) (hid.mul hdYg),
      dX_mul' (a := fun q => (g q)⁻¹ * Ay q) (b := g) (hid.mul hAyd) hgd,
      dX_mul' (a := fun q => (g q)⁻¹) (b := Ay) hid hAyd,
      dX_mul' (a := fun q => (g q)⁻¹) (b := dY g) hid hdYg,
      dX_inv' hgd hu]
    noncomm_ring
  have e2 : dY (gaugeX g Ax) p =
      -((g p)⁻¹ * dY g p * (g p)⁻¹) * Ax p * g p + (g p)⁻¹ * dY Ax p * g p
        + (g p)⁻¹ * Ax p * dY g p
        + (-((g p)⁻¹ * dY g p * (g p)⁻¹) * dX g p + (g p)⁻¹ * dY (dX g) p) := by
    show dY (fun q => (g q)⁻¹ * Ax q * g q + (g q)⁻¹ * dX g q) p = _
    rw [dY_add' (a := fun q => (g q)⁻¹ * Ax q * g q) (b := fun q => (g q)⁻¹ * dX g q)
        ((hid.mul hAxd).mul hgd) (hid.mul hdXg),
      dY_mul' (a := fun q => (g q)⁻¹ * Ax q) (b := g) (hid.mul hAxd) hgd,
      dY_mul' (a := fun q => (g q)⁻¹) (b := Ax) hid hAxd,
      dY_mul' (a := fun q => (g q)⁻¹) (b := dX g) hid hdXg,
      dY_inv' hgd hu]
    noncomm_ring
  unfold curvatureXY
  rw [e1, e2, dX_dY_symm' hgp]
  simp only [gaugeX, gaugeY]
  have hGG' : ∀ X : Matrix (Fin n) (Fin n) ℝ, g p * ((g p)⁻¹ * X) = X := fun X => by
    rw [← mul_assoc, hGG, one_mul]
  simp only [mul_add, add_mul, mul_sub, sub_mul, neg_mul, mul_assoc, hGG']
  abel

/-- The small-loop rule for a constant gauge field (the gimbal loop): carrying a frame round a
square of side `h`, along x, along y, back along x, back along y, leaves the turn
`e^{hA_x} e^{hA_y} e^{-hA_x} e^{-hA_y} = I + h² [A_x, A_y] + (terms of size h³)`. -/
theorem small_square_holonomy (Ax Ay : Matrix (Fin n) (Fin n) ℝ) :
    (fun h : ℝ => exp (h • Ax) * exp (h • Ay) * exp (-(h • Ax)) * exp (-(h • Ay))
        - 1 - h ^ 2 • (Ax * Ay - Ay * Ax)) =O[𝓝 0] (fun h : ℝ => h ^ 3) := by
  have e1 := exp_second_order Ax
  have e2 := exp_second_order Ay
  have e3 : (fun h : ℝ => exp (-(h • Ax)) - (1 + h • (-Ax) + h ^ 2 • ((1/2 : ℝ) • (-Ax * -Ax))))
      =O[𝓝 0] (fun h : ℝ => h ^ 3) := by
    simpa only [smul_neg] using exp_second_order (-Ax)
  have e4 : (fun h : ℝ => exp (-(h • Ay)) - (1 + h • (-Ay) + h ^ 2 • ((1/2 : ℝ) • (-Ay * -Ay))))
      =O[𝓝 0] (fun h : ℝ => h ^ 3) := by
    simpa only [smul_neg] using exp_second_order (-Ay)
  refine (mul_second_order (mul_second_order (mul_second_order e1 e2) e3) e4).congr_left
    (fun h => ?_)
  rw [sub_sub]
  congr 1
  simp only [one_mul, mul_one, neg_mul, mul_neg, neg_neg, add_mul,
    mul_smul_comm, smul_neg, smul_add]
  module

/-- Stokes' rule for a circle group, where `F = dA`: for a smooth real-valued gauge field
`A = A_x dx + A_y dy` on a patch `U` containing the rectangle `[a₁, b₁] × [a₂, b₂]`, the turn
`∮ A` round the rectangle (anticlockwise: along x, along y, back along x, back along y) equals the
area integral `∬ F` of `F_xy = ∂_x A_y - ∂_y A_x`. -/
theorem stokes_circle_group (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (Ax Ay : ℝ × ℝ → ℝ) (hAx : ContDiffOn ℝ 1 Ax U) (hAy : ContDiffOn ℝ 1 Ay U)
    (a₁ b₁ a₂ b₂ : ℝ) (h₁ : a₁ ≤ b₁) (h₂ : a₂ ≤ b₂)
    (hR : Set.Icc a₁ b₁ ×ˢ Set.Icc a₂ b₂ ⊆ U) :
    ((∫ x in a₁..b₁, Ax (x, a₂)) + (∫ y in a₂..b₂, Ay (b₁, y))
        - (∫ x in a₁..b₁, Ax (x, b₂)) - (∫ y in a₂..b₂, Ay (a₁, y)))
      = ∫ x in a₁..b₁, ∫ y in a₂..b₂, (dX Ay (x, y) - dY Ax (x, y)) := by
  have hR' : Set.uIcc a₁ b₁ ×ˢ Set.uIcc a₂ b₂ ⊆ U := by
    rwa [Set.uIcc_of_le h₁, Set.uIcc_of_le h₂]
  have hIoo : Set.Ioo (min a₁ b₁) (max a₁ b₁) ×ˢ Set.Ioo (min a₂ b₂) (max a₂ b₂) ⊆ U := by
    rw [min_eq_left h₁, max_eq_right h₁, min_eq_left h₂, max_eq_right h₂]
    exact (Set.prod_mono Set.Ioo_subset_Icc_self Set.Ioo_subset_Icc_self).trans hR
  have dAx : ∀ q ∈ U, HasFDerivAt Ax (fderiv ℝ Ax q) q := fun q hq =>
    ((hAx.contDiffAt (hU.mem_nhds hq)).differentiableAt one_ne_zero).hasFDerivAt
  have dAy : ∀ q ∈ U, HasFDerivAt Ay (fderiv ℝ Ay q) q := fun q hq =>
    ((hAy.contDiffAt (hU.mem_nhds hq)).differentiableAt one_ne_zero).hasFDerivAt
  have cAx : ContinuousOn (fderiv ℝ Ax) U := hAx.continuousOn_fderiv_of_isOpen hU le_rfl
  have cAy : ContinuousOn (fderiv ℝ Ay) U := hAy.continuousOn_fderiv_of_isOpen hU le_rfl
  have key := MeasureTheory.integral2_divergence_prod_of_hasFDerivAt Ay (fun q => -Ax q)
    (fderiv ℝ Ay) (fun q => -fderiv ℝ Ax q) a₁ a₂ b₁ b₂
    (hAy.continuousOn.mono hR') (hAx.continuousOn.neg.mono hR')
    (fun q hq => dAy q (hIoo hq)) (fun q hq => (dAx q (hIoo hq)).neg) ?_
  · simp only [neg_apply, intervalIntegral.integral_neg] at key
    simp only [dX, dY, ← sub_eq_add_neg] at key ⊢
    rw [key]; ring
  · have hc : ContinuousOn (fun q => fderiv ℝ Ay q (1, 0) + (-fderiv ℝ Ax q) (0, 1)) U := by
      have h1 : ContinuousOn (fun q => fderiv ℝ Ay q (1, 0)) U :=
        (ContinuousLinearMap.apply ℝ ℝ ((1 : ℝ), (0 : ℝ))).continuous.comp_continuousOn cAy
      have h2 : ContinuousOn (fun q => fderiv ℝ Ax q (0, 1)) U :=
        (ContinuousLinearMap.apply ℝ ℝ ((0 : ℝ), (1 : ℝ))).continuous.comp_continuousOn cAx
      simp only [neg_apply, ← sub_eq_add_neg]
      exact h1.sub h2
    exact (hc.mono hR').integrableOn_compact (isCompact_uIcc.prod isCompact_uIcc)

/-- Unit roll, pitch and yaw rates `L_x`, `L_y`, `L_z` (rotation generators about x, y, z). -/
def Lx : Matrix (Fin 3) (Fin 3) ℤ := !![0, 0, 0; 0, 0, -1; 0, 1, 0]
def Ly : Matrix (Fin 3) (Fin 3) ℤ := !![0, 0, 1; 0, 0, 0; -1, 0, 0]
def Lz : Matrix (Fin 3) (Fin 3) ℤ := !![0, -1, 0; 1, 0, 0; 0, 0, 0]

-- The card's bracket: [L_y, L_z] = L_x, pitch then yaw leaves a roll.
example : Ly * Lz - Lz * Ly = Lx := by decide

-- The gimbal: A_x = (1/10) L_y and A_y = (1/10) L_z, so F_xy = [A_x, A_y] = (1/100) L_x, a roll.
example : (!![0, 0, 1/10; 0, 0, 0; -1/10, 0, 0] : Matrix (Fin 3) (Fin 3) ℚ)
        * !![0, -1/10, 0; 1/10, 0, 0; 0, 0, 0]
      - !![0, -1/10, 0; 1/10, 0, 0; 0, 0, 0] * !![0, 0, 1/10; 0, 0, 0; -1/10, 0, 0]
      = !![0, 0, 0; 0, 0, -1/100; 0, 1/100, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_three]


#print axioms curvature_gauge_change
#print axioms small_square_holonomy
#print axioms stokes_circle_group
#print axioms dX_mul'
#print axioms dY_mul'
#print axioms dX_add'
#print axioms dY_add'
#print axioms hasFDerivAt_matrix_inv'
#print axioms differentiableAt_matrix_inv'
#print axioms dX_inv'
#print axioms dY_inv'
#print axioms fderiv_fderiv_apply'
#print axioms dX_dY_symm'
#print axioms exp_second_order
#print axioms pow_smul_isBigO_cube
#print axioms mul_second_order
