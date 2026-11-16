-- Method of images: a mirror source in a plane, or an inverted and scaled source for a sphere, gives the Green's function of the half-space and of the ball, whose boundary slope is the Poisson kernel; a mirror heat source holds or insulates a rod's end.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Geometry.Euclidean.Inversion.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Calculus.Deriv.Shift

open Real MeasureTheory Filter Topology InnerProductSpace

/-- `A_d`, the area of the unit sphere in `d` dimensions: `d` times the volume of the unit ball
(`2π` in the plane, `4π` in space). -/
noncomputable def unitSphereArea (d : ℕ) : ℝ :=
  d * (volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1)).toReal

/-- `Φ`, the field of one unit source, with `-ΔΦ = δ`: `-(1/2π) log |z|` in the plane and
`1 / ((d - 2) A_d |z|^(d-2))` for `d ≥ 3`. -/
noncomputable def fundSol (d : ℕ) (z : EuclideanSpace ℝ (Fin d)) : ℝ :=
  if d = 2 then -(1 / (2 * π)) * Real.log ‖z‖
  else 1 / (((d : ℝ) - 2) * unitSphereArea d * ‖z‖ ^ (d - 2))

/-- The image point `x̃ = (x_1, …, x_{d-1}, -x_d)`: the mirror of `x` in the plane `x_d = 0`,
here in dimension `d = n + 1` with last coordinate `Fin.last n`. -/
noncomputable def mirror (n : ℕ) (x : EuclideanSpace ℝ (Fin (n + 1))) :
    EuclideanSpace ℝ (Fin (n + 1)) :=
  x - (2 * x (Fin.last n)) • EuclideanSpace.single (Fin.last n) (1 : ℝ)

/-- The half-space Green's function `G(x, y) = Φ(y - x) - Φ(y - x̃)`. -/
noncomputable def halfGreen (n : ℕ) (x y : EuclideanSpace ℝ (Fin (n + 1))) : ℝ :=
  fundSol (n + 1) (y - x) - fundSol (n + 1) (y - mirror n x)

/-- The ball's Green's function `G(x, y) = Φ(y - x) - (R/|x|)^(d-2) Φ(y - x̃)`, with the image
`x̃ = R² x / |x|²` the inversion of `x` in the sphere of radius `R` about the origin. -/
noncomputable def ballGreen (d : ℕ) (R : ℝ) (x y : EuclideanSpace ℝ (Fin d)) : ℝ :=
  fundSol d (y - x) -
    (R / ‖x‖) ^ (d - 2) * fundSol d (y - EuclideanGeometry.inversion (0 : EuclideanSpace ℝ (Fin d)) R x)

/-- The heat kernel on a line, `Γ(z, t) = e^(-z²/(4κt)) / √(4πκt)`. -/
noncomputable def heatKernel (κ t z : ℝ) : ℝ :=
  Real.exp (-(z ^ 2) / (4 * κ * t)) / Real.sqrt (4 * π * κ * t)

section radial
variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]

lemma radial_hasFDerivAt {F F' : ℝ → ℝ} (a y : E)
    (hF : HasDerivAt F (F' (‖y - a‖ ^ 2)) (‖y - a‖ ^ 2)) :
    HasFDerivAt (fun z => F (‖z - a‖ ^ 2)) ((2 * F' (‖y - a‖ ^ 2)) • innerSL ℝ (y - a)) y := by
  have h1 : HasFDerivAt (fun z : E => ‖z - a‖ ^ 2)
      (2 • (innerSL ℝ (y - a)).comp (ContinuousLinearMap.id ℝ E)) y :=
    HasFDerivAt.norm_sq ((hasFDerivAt_id y).sub_const a)
  have h2 := hF.comp_hasFDerivAt y h1
  refine h2.congr_fderiv ?_
  ext v
  simp
  ring

lemma radial_harmonicAt [FiniteDimensional ℝ E] {F F' F'' : ℝ → ℝ} (a y : E) (hy : y ≠ a)
    (hF : ∀ s > 0, HasDerivAt F (F' s) s) (hF' : ∀ s > 0, HasDerivAt F' (F'' s) s)
    (hC : ∀ s > 0, ContDiffAt ℝ 2 F s)
    (hode : ∀ s > 0, 4 * s * F'' s + 2 * (Module.finrank ℝ E) * F' s = 0) :
    HarmonicAt (fun z => F (‖z - a‖ ^ 2)) y := by
  have hpos : ∀ z : E, z ≠ a → 0 < ‖z - a‖ ^ 2 := fun z hz => by
    have : 0 < ‖z - a‖ := norm_pos_iff.2 (sub_ne_zero.2 hz)
    positivity
  constructor
  · exact (hC _ (hpos y hy)).comp y
      ((contDiff_norm_sq ℝ).comp (contDiff_id.sub contDiff_const)).contDiffAt
  · filter_upwards [isOpen_ne.mem_nhds hy] with z hz
    have hD : fderiv ℝ (fun z => F (‖z - a‖ ^ 2)) =ᶠ[𝓝 z]
        fun w => (2 * F' (‖w - a‖ ^ 2)) • innerSL ℝ (w - a) := by
      filter_upwards [isOpen_ne.mem_nhds hz] with w hw
      exact (radial_hasFDerivAt a w (hF _ (hpos w hw))).fderiv
    have hc : HasFDerivAt (fun w : E => 2 * F' (‖w - a‖ ^ 2))
        (2 • ((2 * F'' (‖z - a‖ ^ 2)) • innerSL ℝ (z - a))) z := by
      have := (radial_hasFDerivAt (F := F') (F' := F'') a z (hF' _ (hpos z hz))).const_mul 2
      convert this using 1
      ext v; simp [smul_eq_mul]
    have hL : HasFDerivAt (fun w : E => innerSL ℝ (w - a))
        ((innerSL ℝ).comp (ContinuousLinearMap.id ℝ E)) z :=
      (innerSL ℝ).hasFDerivAt.comp z ((hasFDerivAt_id z).sub_const a)
    have h3 : HasFDerivAt (fun w => (2 * F' (‖w - a‖ ^ 2)) • innerSL ℝ (w - a)) _ z := hc.smul hL
    have h2 := h3.fderiv
    rw [laplacian_eq_iteratedFDeriv_orthonormalBasis _ (stdOrthonormalBasis ℝ E)]
    simp only [iteratedFDeriv_two_apply, Matrix.cons_val_zero, Matrix.cons_val_one]
    rw [hD.fderiv_eq, h2]
    set b := stdOrthonormalBasis ℝ E
    simp only [ContinuousLinearMap.add_apply, ContinuousLinearMap.coe_smul', Pi.smul_apply,
      ContinuousLinearMap.comp_apply, ContinuousLinearMap.id_apply, innerSL_apply_apply,
      ContinuousLinearMap.smulRight_apply, smul_eq_mul, nsmul_eq_mul]
    have hb1 : ∀ i, ⟪b i, b i⟫_ℝ = 1 := fun i => by
      rw [real_inner_self_eq_norm_sq, b.orthonormal.1 i]; norm_num
    have hb2 : ∑ i, ⟪z - a, b i⟫_ℝ * ⟪z - a, b i⟫_ℝ = ‖z - a‖ ^ 2 := by
      rw [← real_inner_self_eq_norm_sq, ← b.sum_inner_mul_inner (z - a) (z - a)]
      simp [real_inner_comm]
    have : ∀ i, (2 * F' (‖z - a‖ ^ 2) * ⟪b i, b i⟫_ℝ +
        (2 * (2 * F'' (‖z - a‖ ^ 2) * ⟪z - a, b i⟫_ℝ)) * ⟪z - a, b i⟫_ℝ) =
        2 * F' (‖z - a‖ ^ 2) + 4 * F'' (‖z - a‖ ^ 2) * (⟪z - a, b i⟫_ℝ * ⟪z - a, b i⟫_ℝ) := by
      intro i; rw [hb1]; ring
    simp only [Pi.zero_apply, Nat.cast_ofNat]
    simp_rw [this, Finset.sum_add_distrib, ← Finset.mul_sum, hb2, Finset.sum_const,
      Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    linear_combination hode _ (hpos z hz)
end radial


lemma unitSphereArea_pos (d : ℕ) (hd : 1 ≤ d) : 0 < unitSphereArea d := by
  unfold unitSphereArea
  have : Nonempty (Fin d) := ⟨⟨0, hd⟩⟩
  apply mul_pos (by exact_mod_cast hd)
  apply ENNReal.toReal_pos
  · exact (Metric.measure_ball_pos volume _ one_pos).ne'
  · exact measure_ball_lt_top.ne

lemma unitSphereArea_two : unitSphereArea 2 = 2 * π := by
  simp [unitSphereArea, ENNReal.toReal_ofReal pi_pos.le]

lemma norm_sq_rpow (z : EuclideanSpace ℝ (Fin d)) (q : ℝ) : (‖z‖ ^ 2) ^ q = ‖z‖ ^ (2 * q) := by
  rw [← Real.rpow_natCast_mul (norm_nonneg z) 2 q]; norm_num

lemma fundSol_radial (d : ℕ) (hd : 2 ≤ d) : ∃ F F' F'' : ℝ → ℝ,
    (∀ s > 0, HasDerivAt F (F' s) s) ∧ (∀ s > 0, HasDerivAt F' (F'' s) s) ∧
    (∀ s > 0, ContDiffAt ℝ 2 F s) ∧
    (∀ s > 0, 4 * s * F'' s + 2 * (d : ℝ) * F' s = 0) ∧
    (∀ z : EuclideanSpace ℝ (Fin d), z ≠ 0 → fundSol d z = F (‖z‖ ^ 2)) ∧
    (∀ z : EuclideanSpace ℝ (Fin d), z ≠ 0 →
      2 * F' (‖z‖ ^ 2) = -(1 / (unitSphereArea d * ‖z‖ ^ d))) := by
  have hA := unitSphereArea_pos d (by omega)
  rcases (show d = 2 ∨ 3 ≤ d by omega) with rfl | hd3
  · set C : ℝ := -(1 / (2 * π)) / 2
    refine ⟨fun s => C * Real.log s, fun s => C * s⁻¹, fun s => C * (-(s ^ 2)⁻¹),
      fun s hs => (Real.hasDerivAt_log hs.ne').const_mul C,
      fun s hs => (hasDerivAt_inv hs.ne').const_mul C,
      fun s hs => contDiffAt_const.mul (Real.contDiffAt_log.2 hs.ne'),
      fun s hs => ?_, fun z hz => ?_, fun z hz => ?_⟩
    · field_simp; ring
    · simp only [fundSol, if_true, Real.log_pow, C]; push_cast; ring
    · have : 0 < ‖z‖ := norm_pos_iff.2 hz
      rw [unitSphereArea_two]; simp only [C]; field_simp
  · set p : ℝ := -(((d : ℝ) - 2) / 2)
    set C : ℝ := 1 / (((d : ℝ) - 2) * unitSphereArea d)
    have hd2 : (0 : ℝ) < (d : ℝ) - 2 := by
      have : (3 : ℝ) ≤ d := by exact_mod_cast hd3
      linarith
    refine ⟨fun s => C * s ^ p, fun s => C * (p * s ^ (p - 1)),
      fun s => C * (p * ((p - 1) * s ^ (p - 1 - 1))),
      fun s hs => (Real.hasDerivAt_rpow_const (Or.inl hs.ne')).const_mul C,
      fun s hs => ((Real.hasDerivAt_rpow_const (Or.inl hs.ne')).const_mul p).const_mul C,
      fun s hs => contDiffAt_const.mul (Real.contDiffAt_rpow_const_of_ne hs.ne'),
      fun s hs => ?_, fun z hz => ?_, fun z hz => ?_⟩
    · beta_reduce
      rw [Real.rpow_sub_one hs.ne' (p - 1)]
      field_simp
      simp only [p]; ring
    · have : 0 < ‖z‖ := norm_pos_iff.2 hz
      simp only [fundSol, if_neg (show ¬ d = 2 by omega)]
      rw [norm_sq_rpow, show 2 * p = -(((d - 2 : ℕ) : ℕ) : ℝ) by
        simp only [p]; push_cast [show 2 ≤ d by omega]; ring, Real.rpow_neg (norm_nonneg _),
        Real.rpow_natCast]
      simp only [C]; field_simp
    · have : 0 < ‖z‖ := norm_pos_iff.2 hz
      beta_reduce
      rw [norm_sq_rpow, show 2 * (p - 1) = -((d : ℕ) : ℝ) by simp only [p]; ring,
        Real.rpow_neg (norm_nonneg _), Real.rpow_natCast]
      simp only [C, p]; field_simp

lemma fundSol_hasFDerivAt (d : ℕ) (hd : 2 ≤ d) (a y : EuclideanSpace ℝ (Fin d)) (hy : y ≠ a) :
    HasFDerivAt (fun z => fundSol d (z - a))
      ((-(1 / (unitSphereArea d * ‖y - a‖ ^ d))) • innerSL ℝ (y - a)) y := by
  obtain ⟨F, F', F'', hF, -, -, -, heq, hco⟩ := fundSol_radial d hd
  have hya : y - a ≠ 0 := sub_ne_zero.2 hy
  have h := radial_hasFDerivAt (F := F) (F' := F') a y (hF _ (by positivity))
  rw [hco _ hya] at h
  refine h.congr_of_eventuallyEq ?_
  filter_upwards [isOpen_ne.mem_nhds hy] with z hz
  exact heq _ (sub_ne_zero.2 hz)

lemma fundSol_harmonicAt (d : ℕ) (hd : 2 ≤ d) (a y : EuclideanSpace ℝ (Fin d)) (hy : y ≠ a) :
    HarmonicAt (fun z => fundSol d (z - a)) y := by
  obtain ⟨F, F', F'', hF, hF', hC, hode, heq, -⟩ := fundSol_radial d hd
  have h := radial_harmonicAt a y hy hF hF' hC (by simpa [finrank_euclideanSpace_fin] using hode)
  refine (harmonicAt_congr_nhds ?_).2 h
  filter_upwards [isOpen_ne.mem_nhds hy] with z hz
  exact heq _ (sub_ne_zero.2 hz)


lemma fundSol_congr_norm (d : ℕ) (z w : EuclideanSpace ℝ (Fin d)) (h : ‖z‖ = ‖w‖) :
    fundSol d z = fundSol d w := by
  unfold fundSol; rw [h]

lemma tendsto_norm_sub_cocompact (d : ℕ) (a : EuclideanSpace ℝ (Fin d)) :
    Tendsto (fun y => ‖y - a‖) (cocompact _) atTop := by
  refine tendsto_atTop_mono (fun y => norm_sub_norm_le y a) ?_
  simpa [sub_eq_add_neg] using
    tendsto_atTop_add_const_right _ (-‖a‖) (tendsto_norm_cocompact_atTop (E := EuclideanSpace ℝ (Fin d)))

lemma abs_log_sub_log_le (a b K : ℝ) (ha : 0 < a) (hb : 0 < b) (h : |a - b| ≤ K) :
    |Real.log a - Real.log b| ≤ K / a + K / b := by
  have hK : 0 ≤ K := (abs_nonneg _).trans h
  have h1 : Real.log a - Real.log b ≤ K / b := by
    rw [← Real.log_div ha.ne' hb.ne']
    refine (Real.log_le_sub_one_of_pos (div_pos ha hb)).trans ?_
    rw [div_sub_one hb.ne']
    exact div_le_div_of_nonneg_right ((le_abs_self _).trans h) hb.le
  have h2 : Real.log b - Real.log a ≤ K / a := by
    rw [← Real.log_div hb.ne' ha.ne']
    refine (Real.log_le_sub_one_of_pos (div_pos hb ha)).trans ?_
    rw [div_sub_one ha.ne']
    exact div_le_div_of_nonneg_right ((le_abs_self _).trans (by rwa [abs_sub_comm])) ha.le
  have := div_nonneg hK ha.le
  have := div_nonneg hK hb.le
  rw [abs_le]; constructor <;> linarith

lemma fundSol_tendsto_zero (d : ℕ) (hd : 3 ≤ d) (a : EuclideanSpace ℝ (Fin d)) :
    Tendsto (fun y => fundSol d (y - a)) (cocompact _) (𝓝 0) := by
  have hA := unitSphereArea_pos d (by omega)
  have hd2 : (0 : ℝ) < (d : ℝ) - 2 := by
    have : (3 : ℝ) ≤ d := by exact_mod_cast hd
    linarith
  have h1 := ((tendsto_pow_atTop (show d - 2 ≠ 0 by omega)).comp
    (tendsto_norm_sub_cocompact d a)).const_mul_atTop (mul_pos hd2 hA)
  have h2 := h1.inv_tendsto_atTop
  simp only [fundSol, if_neg (show ¬ d = 2 by omega)]
  convert h2 using 1
  funext y
  simp [one_div, Function.comp]



lemma mirror_last (n : ℕ) (x : EuclideanSpace ℝ (Fin (n + 1))) :
    mirror n x (Fin.last n) = -x (Fin.last n) := by
  simp [mirror]; ring

lemma norm_sub_mirror (n : ℕ) (x y : EuclideanSpace ℝ (Fin (n + 1)))
    (hy : y (Fin.last n) = 0) : ‖y - mirror n x‖ = ‖y - x‖ := by
  have h : y - mirror n x = (y - x) + (2 * x (Fin.last n)) • EuclideanSpace.single (Fin.last n) (1 : ℝ) := by
    simp only [mirror]; abel
  rw [← sq_eq_sq₀ (norm_nonneg _) (norm_nonneg _), h, norm_add_sq_real, inner_smul_right,
    EuclideanSpace.inner_single_right, norm_smul]
  simp [hy]
  rw [mul_pow, sq_abs]; ring



lemma inversion_zero_eq (d : ℕ) (R : ℝ) (x : EuclideanSpace ℝ (Fin d)) :
    EuclideanGeometry.inversion (0 : EuclideanSpace ℝ (Fin d)) R x = (R / ‖x‖) ^ 2 • x := by
  simp [EuclideanGeometry.inversion]

lemma norm_sub_inversion (d : ℕ) (R : ℝ) (hR : 0 < R) (x y : EuclideanSpace ℝ (Fin d))
    (hx0 : x ≠ 0) (hy : ‖y‖ = R) :
    ‖y - EuclideanGeometry.inversion (0 : EuclideanSpace ℝ (Fin d)) R x‖ = (R / ‖x‖) * ‖y - x‖ := by
  have hxn : 0 < ‖x‖ := norm_pos_iff.2 hx0
  have hs : (R / ‖x‖) * ‖x‖ = R := by field_simp
  rw [inversion_zero_eq, ← sq_eq_sq₀ (norm_nonneg _) (by positivity), mul_pow,
    norm_sub_sq_real, norm_sub_sq_real, norm_smul, inner_smul_right, hy]
  set s := R / ‖x‖
  simp only [Real.norm_eq_abs, abs_pow, abs_of_pos (show 0 < s by positivity)]
  linear_combination (-(1 - s ^ 2) * (R + s * ‖x‖)) * hs

#print axioms radial_hasFDerivAt
#print axioms radial_harmonicAt
#print axioms unitSphereArea_pos
#print axioms unitSphereArea_two
#print axioms norm_sq_rpow
#print axioms fundSol_radial
#print axioms fundSol_hasFDerivAt
#print axioms fundSol_harmonicAt
#print axioms fundSol_congr_norm
#print axioms tendsto_norm_sub_cocompact
#print axioms abs_log_sub_log_le
#print axioms fundSol_tendsto_zero
#print axioms mirror_last
#print axioms norm_sub_mirror
#print axioms inversion_zero_eq
#print axioms norm_sub_inversion

/-- Half-space, `d = n + 1 ≥ 2`, source at height `x_d > 0`: the source minus its mirror is the
Green's function. It is 0 on the plane `y_d = 0`; what it adds to the free field `Φ(y - x)` is
harmonic in the upper half-space (the image lies outside); it tends to 0 far away; and on the
plane its outward slope gives the Poisson kernel `-∂G/∂n = 2 x_d / (A_d |x - y|^d)`, the outward
normal being `n = -e_d`. -/
theorem half_space_green_by_mirror_image (n : ℕ) (hn : 1 ≤ n)
    (x : EuclideanSpace ℝ (Fin (n + 1))) (hx : 0 < x (Fin.last n)) :
    (∀ y : EuclideanSpace ℝ (Fin (n + 1)), y (Fin.last n) = 0 → halfGreen n x y = 0) ∧
    HarmonicOnNhd (fun y => halfGreen n x y - fundSol (n + 1) (y - x))
      {y | 0 < y (Fin.last n)} ∧
    Tendsto (halfGreen n x) (cocompact _) (𝓝 0) ∧
    (∀ y : EuclideanSpace ℝ (Fin (n + 1)), y (Fin.last n) = 0 →
      -(fderiv ℝ (halfGreen n x) y) (-(EuclideanSpace.single (Fin.last n) (1 : ℝ))) =
        2 * x (Fin.last n) / (unitSphereArea (n + 1) * ‖x - y‖ ^ (n + 1))) := by
  have hml := mirror_last n x
  refine ⟨fun y hy => ?_, ?_, ?_, fun y hy => ?_⟩
  · unfold halfGreen
    rw [fundSol_congr_norm _ _ _ (norm_sub_mirror n x y hy), sub_self]
  · have hfun : (fun y => halfGreen n x y - fundSol (n + 1) (y - x)) =
        fun y => -(fundSol (n + 1) (y - mirror n x)) := by
      funext y; simp [halfGreen]
    rw [hfun]
    intro y hy
    have hne : y ≠ mirror n x := by
      intro h; simp only [Set.mem_setOf_eq] at hy; rw [h, hml] at hy; linarith
    exact (fundSol_harmonicAt (n + 1) (by omega) _ y hne).neg
  · rcases (show n = 1 ∨ 2 ≤ n by omega) with rfl | hn2
    · set K := ‖mirror 1 x - x‖
      have hK : ∀ y, |‖y - x‖ - ‖y - mirror 1 x‖| ≤ K := fun y => by
        refine (abs_norm_sub_norm_le _ _).trans (le_of_eq ?_)
        simp only [K]; congr 1; abel
      have hlim : Tendsto (fun y => K / ‖y - x‖ + K / ‖y - mirror 1 x‖) (cocompact _) (𝓝 0) := by
        simpa using (tendsto_const_nhds.div_atTop (tendsto_norm_sub_cocompact 2 x)).add
          (tendsto_const_nhds.div_atTop (tendsto_norm_sub_cocompact 2 (mirror 1 x)))
      have hlog : Tendsto (fun y => Real.log ‖y - x‖ - Real.log ‖y - mirror 1 x‖)
          (cocompact _) (𝓝 0) := by
        refine squeeze_zero_norm' ?_ hlim
        filter_upwards [(tendsto_norm_sub_cocompact 2 x).eventually_gt_atTop 0,
          (tendsto_norm_sub_cocompact 2 (mirror 1 x)).eventually_gt_atTop 0] with y h1 h2
        rw [Real.norm_eq_abs]
        exact abs_log_sub_log_le _ _ _ h1 h2 (hK y)
      have := hlog.const_mul (-(1 / (2 * π)))
      rw [mul_zero] at this
      convert this using 1
      funext y
      simp [halfGreen, fundSol]
      ring
    · show Tendsto (fun y => fundSol (n + 1) (y - x) - fundSol (n + 1) (y - mirror n x)) _ _
      simpa using (fundSol_tendsto_zero (n + 1) (by omega) x).sub
        (fundSol_tendsto_zero (n + 1) (by omega) (mirror n x))
  · have hyx : y ≠ x := by intro h; rw [h] at hy; linarith
    have hym : y ≠ mirror n x := by intro h; rw [h, hml] at hy; linarith
    have h : HasFDerivAt (halfGreen n x) _ y :=
      (fundSol_hasFDerivAt (n + 1) (by omega) x y hyx).sub
        (fundSol_hasFDerivAt (n + 1) (by omega) (mirror n x) y hym)
    rw [h.fderiv, norm_sub_mirror n x y hy]
    have hA := unitSphereArea_pos (n + 1) (by omega)
    have hr : 0 < ‖y - x‖ := norm_pos_iff.2 (sub_ne_zero.2 hyx)
    simp [EuclideanSpace.inner_single_right, hy, hml, norm_sub_rev x y]
    field_simp
    ring

/-- Ball of radius `R` about the origin, `d ≥ 3`, source `x ≠ 0` inside: the image
`x̃ = R² x/|x|²` lies outside the ball, the source minus the image scaled by `(R/|x|)^(d-2)` is 0 on
the sphere, what the image adds to `Φ(y - x)` is harmonic in the ball, and the outward slope on
the sphere (normal `y/R`) gives the Poisson kernel
`-∂G/∂n = (R² - |x|²) / (A_d R |x - y|^d)`. -/
theorem ball_green_by_inversion_image (d : ℕ) (hd : 3 ≤ d) (R : ℝ) (hR : 0 < R)
    (x : EuclideanSpace ℝ (Fin d)) (hx0 : x ≠ 0) (hx : ‖x‖ < R) :
    R < ‖EuclideanGeometry.inversion (0 : EuclideanSpace ℝ (Fin d)) R x‖ ∧
    (∀ y ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin d)) R, ballGreen d R x y = 0) ∧
    HarmonicOnNhd (fun y => ballGreen d R x y - fundSol d (y - x))
      (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) R) ∧
    (∀ y ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin d)) R,
      -(fderiv ℝ (ballGreen d R x) y) ((1 / R) • y) =
        (R ^ 2 - ‖x‖ ^ 2) / (unitSphereArea d * R * ‖x - y‖ ^ d)) := by
  have hxn : 0 < ‖x‖ := norm_pos_iff.2 hx0
  have hA := unitSphereArea_pos d (by omega)
  set xt := EuclideanGeometry.inversion (0 : EuclideanSpace ℝ (Fin d)) R x with hxt
  have hnt : ‖xt‖ = R ^ 2 / ‖x‖ := by
    rw [hxt, inversion_zero_eq, norm_smul, norm_pow, Real.norm_eq_abs, abs_div, abs_of_pos hR, abs_norm]
    field_simp
  have h1 : R < ‖xt‖ := by
    rw [hnt, lt_div_iff₀ hxn]; nlinarith
  have hsph : ∀ y ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin d)) R, ‖y‖ = R ∧ y ≠ x ∧ y ≠ xt :=
    fun y hy => by
      rw [mem_sphere_zero_iff_norm] at hy
      refine ⟨hy, fun h => ?_, fun h => ?_⟩
      · rw [h] at hy; linarith
      · rw [h] at hy; linarith
  obtain ⟨m, rfl⟩ : ∃ m, d = m + 2 := ⟨d - 2, by omega⟩
  have hm : m + 2 - 2 = m := by omega
  have hc : (0 : ℝ) < ((m + 2 : ℕ) : ℝ) - 2 := by
    have : (3 : ℝ) ≤ ((m + 2 : ℕ) : ℝ) := by exact_mod_cast hd
    linarith
  refine ⟨h1, fun y hy => ?_, ?_, fun y hy => ?_⟩
  · obtain ⟨hyR, hyx, -⟩ := hsph y hy
    have hr : 0 < ‖y - x‖ := norm_pos_iff.2 (sub_ne_zero.2 hyx)
    simp only [ballGreen, fundSol, if_neg (show ¬ m + 2 = 2 by omega)]
    rw [norm_sub_inversion _ R hR x y hx0 hyR, hm, mul_pow]
    field_simp
    ring
  · have hfun : (fun y => ballGreen (m + 2) R x y - fundSol (m + 2) (y - x)) =
        -((R / ‖x‖) ^ (m + 2 - 2) • fun y => fundSol (m + 2) (y - xt)) := by
      funext y; simp [ballGreen, xt]
    rw [hfun]
    intro y hy
    have hne : y ≠ xt := by
      intro h; rw [mem_ball_zero_iff, h] at hy; linarith
    exact (fundSol_harmonicAt (m + 2) (by omega) _ y hne).const_smul.neg
  · obtain ⟨hyR, hyx, hyt⟩ := hsph y hy
    have hr : 0 < ‖y - x‖ := norm_pos_iff.2 (sub_ne_zero.2 hyx)
    have h : HasFDerivAt (ballGreen (m + 2) R x) _ y :=
      (fundSol_hasFDerivAt (m + 2) (by omega) x y hyx).sub
        ((fundSol_hasFDerivAt (m + 2) (by omega) xt y hyt).const_mul ((R / ‖x‖) ^ (m + 2 - 2)))
    rw [h.fderiv, norm_sub_inversion _ R hR x y hx0 hyR, hm, norm_sub_rev x y]
    simp only [hxt, inversion_zero_eq]
    simp [hyR]
    rw [mul_pow, div_pow, div_pow]
    field_simp
    ring

/-- Heat on a rod `x > 0`: the source minus its mirror, `Γ(x - y, t) - Γ(x + y, t)`, is 0 at the
end `x = 0` (end held at room temperature), and the source plus its mirror,
`Γ(x - y, t) + Γ(x + y, t)`, has zero slope there (end insulated). -/
theorem rod_heat_images_hold_or_insulate_end (κ t y : ℝ) :
    heatKernel κ t (0 - y) - heatKernel κ t (0 + y) = 0 ∧
    deriv (fun x => heatKernel κ t (x - y) + heatKernel κ t (x + y)) 0 = 0 := by
  have hΓ : ∀ z, heatKernel κ t (-z) = heatKernel κ t z := by intro z; simp [heatKernel]
  constructor
  · rw [zero_sub, hΓ, zero_add, sub_self]
  · set f := fun x => heatKernel κ t (x - y) + heatKernel κ t (x + y)
    have hf : (fun x => f (-x)) = f := by
      funext x
      simp only [f]
      rw [show -x - y = -(x + y) by ring, show -x + y = -(x - y) by ring, hΓ, hΓ, add_comm]
    have h := deriv_comp_neg (f := f) (x := 0)
    rw [hf, neg_zero] at h
    linarith

-- The sheet point 5 cm to the side of the bead's foot is √50 cm ≈ 7.07 cm from both bead and image.
example : (5 : ℤ) ^ 2 + (0 - 5) ^ 2 = 5 ^ 2 + (0 + 5) ^ 2 ∧ (5 : ℤ) ^ 2 + 5 ^ 2 = 50 := by decide
-- Sphere of radius 10 cm, bead 5 cm from the centre: image at R²/|x| = 20 cm, charge R/|x| = 2 times.
example : (10 : ℚ) ^ 2 / 5 = 20 ∧ (10 : ℚ) / 5 = 2 := by norm_num
-- Every sphere point is twice as far from the image as from the bead: nearest and farthest points.
example : (20 : ℤ) - 10 = 2 * (10 - 5) ∧ (20 : ℤ) + 10 = 2 * (10 + 5) := by decide
-- So the voltages cancel at the nearest point: kq/(5 cm) - 2kq/(10 cm) = 0.
example : (1 : ℚ) / 5 - 2 / 10 = 0 := by norm_num
-- Half the drawn-up charge lies within h√3: h / √(3h² + h²) = 1/2 at h = 5 cm, as 3·25 + 25 = 10².
example : (3 * 5 ^ 2 + 5 ^ 2 : ℕ) = 10 ^ 2 ∧ (5 : ℚ) / 10 = 1 / 2 := by norm_num
-- The disc's weights at r = 1/2 (times 2π): 3 at the nearest rim point, 1/3 at the farthest.
example : (1 - (1 / 2 : ℚ) ^ 2) / (1 - 2 * (1 / 2) * 1 + (1 / 2) ^ 2) = 3 ∧
    (1 - (1 / 2 : ℚ) ^ 2) / (1 - 2 * (1 / 2) * (-1) + (1 / 2) ^ 2) = 1 / 3 := by norm_num

#print axioms half_space_green_by_mirror_image
#print axioms ball_green_by_inversion_image
#print axioms rod_heat_images_hold_or_insulate_end
