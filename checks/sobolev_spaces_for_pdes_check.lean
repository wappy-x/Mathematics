-- Sobolev spaces: on a square sheet of side L held at zero on its rim, the shape's 2-size is at most L/(π√2) times its slope's 2-size (and no smaller constant works), so the slope alone controls the whole H¹ size, and a sheet balancing a load f under tension T has slope size at most L/(π√2)·‖f‖/T.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Trigonometric.ArctanDeriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Function.L2Space

open MeasureTheory Set Real

/-! A shape is a height `u : ℝ × ℝ → ℝ` over the plane; the sheet is the open square
`Ioo 0 L ×ˢ Ioo 0 L`, its rim is that square's frontier. The slope arrow is
`(∂u/∂x, ∂u/∂y) = (fderiv ℝ u p (1, 0), fderiv ℝ u p (0, 1))`, so the squared slope at `p` is
`(fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2`. A 2-size is the square root of an
integral of a square over the sheet. A shape that is continuously differentiable and zero on
the rim lies in `H¹₀`: its trace (rim profile) is its rim values, which are zero. -/

theorem wirtinger_k {L k : ℝ} (hL : 0 < L) (hk0 : 0 ≤ k) (hk : k < π / L) {f f' : ℝ → ℝ}
    (hd : ∀ x, HasDerivAt f (f' x) x) (hc : Continuous f') (h0 : f 0 = 0) (h1 : f L = 0) :
    k ^ 2 * ∫ x in (0:ℝ)..L, f x ^ 2 ≤ ∫ x in (0:ℝ)..L, f' x ^ 2 := by
  have hfc : Continuous f := continuous_iff_continuousAt.2 fun x => (hd x).continuousAt
  set w : ℝ → ℝ := fun x => -k * Real.tan (k * (x - L / 2)) with hw
  have hkL : k * L < π := by rwa [lt_div_iff₀ hL] at hk
  have hcos : ∀ x ∈ Icc 0 L, 0 < Real.cos (k * (x - L / 2)) := by
    intro x hx
    apply Real.cos_pos_of_mem_Ioo
    constructor <;> nlinarith [hx.1, hx.2, Real.pi_pos]
  have hwd : ∀ x ∈ Icc 0 L, HasDerivAt w (-k ^ 2 - w x ^ 2) x := by
    intro x hx
    have h1 : HasDerivAt (fun x => k * (x - L/2)) k x := by
      simpa using ((hasDerivAt_id x).sub_const (L/2)).const_mul k
    have h2 := (Real.hasDerivAt_tan (hcos x hx).ne').comp x h1
    have h3 := h2.const_mul (-k)
    have gen : ∀ θ : ℝ, Real.cos θ ≠ 0 →
        -k * (1 / Real.cos θ ^ 2 * k) = -k ^ 2 - (-k * Real.tan θ) ^ 2 := by
      intro θ hθ
      rw [Real.tan_eq_sin_div_cos]
      have hs := Real.sin_sq_add_cos_sq θ
      field_simp
      linear_combination k^2 * hs
    have e : -k * (1 / Real.cos (k * (x - L / 2)) ^ 2 * k) = -k ^ 2 - w x ^ 2 :=
      gen _ (hcos x hx).ne'
    rw [e] at h3
    exact h3
  have hwc : ContinuousOn w (Icc 0 L) := fun x hx => (hwd x hx).continuousAt.continuousWithinAt
  set g' : ℝ → ℝ := fun x => (-k ^ 2 - w x ^ 2) * f x ^ 2 + w x * (2 * f x * f' x) with hg'
  have hgd : ∀ x ∈ uIcc 0 L, HasDerivAt (fun x => w x * f x ^ 2) (g' x) x := by
    intro x hx
    rw [uIcc_of_le hL.le] at hx
    convert (hwd x hx).mul ((hd x).pow 2) using 1
    simp [hg']
  have hg'c : ContinuousOn g' (Icc 0 L) := by
    simp only [hg']
    exact ((continuousOn_const.sub (hwc.pow 2)).mul (hfc.continuousOn.pow 2)).add
      (hwc.mul ((continuousOn_const.mul hfc.continuousOn).mul hc.continuousOn))
  have hg'i : IntervalIntegrable g' volume 0 L :=
    ContinuousOn.intervalIntegrable (by rwa [uIcc_of_le hL.le])
  have hFTC := intervalIntegral.integral_eq_sub_of_hasDerivAt hgd hg'i
  simp only [h0, h1] at hFTC
  have hqc : ContinuousOn (fun x => (f' x - w x * f x) ^ 2) (Icc 0 L) :=
    ((hc.continuousOn.sub (hwc.mul hfc.continuousOn)).pow 2)
  have hqi : IntervalIntegrable (fun x => (f' x - w x * f x) ^ 2) volume 0 L :=
    ContinuousOn.intervalIntegrable (by rwa [uIcc_of_le hL.le])
  have hid : (fun x => f' x ^ 2 - k ^ 2 * f x ^ 2) = fun x => (f' x - w x * f x) ^ 2 + g' x := by
    funext x; simp only [hg']; ring
  have hnn : 0 ≤ ∫ x in (0:ℝ)..L, (f' x - w x * f x) ^ 2 :=
    intervalIntegral.integral_nonneg hL.le fun x _ => sq_nonneg _
  have key : ∫ x in (0:ℝ)..L, (f' x ^ 2 - k ^ 2 * f x ^ 2) ≥ 0 := by
    rw [hid, intervalIntegral.integral_add hqi hg'i, hFTC]
    simpa using hnn
  rw [intervalIntegral.integral_sub ((by fun_prop : Continuous fun x => f' x ^ 2).intervalIntegrable _ _)
    ((by fun_prop : Continuous fun x => k ^ 2 * f x ^ 2).intervalIntegrable _ _),
    intervalIntegral.integral_const_mul] at key
  linarith

#print axioms wirtinger_k

theorem sharp_of_lt {L A B : ℝ} (hL : 0 < L) (hB : 0 ≤ B)
    (h : ∀ k : ℝ, 0 ≤ k → k < π / L → k ^ 2 * A ≤ B) : (π / L) ^ 2 * A ≤ B := by
  by_contra hc
  rw [not_le] at hc
  have hpL : 0 < π / L := div_pos Real.pi_pos hL
  have hA : 0 < A := by
    by_contra hA; rw [not_lt] at hA
    have : (π / L) ^ 2 * A ≤ 0 := mul_nonpos_of_nonneg_of_nonpos (by positivity) hA
    linarith
  set m := (B / A + (π / L) ^ 2) / 2 with hm
  have hBA : B / A < (π / L) ^ 2 := by rw [div_lt_iff₀ hA]; linarith
  have hm0 : 0 ≤ m := by rw [hm]; positivity
  have hmlt : m < (π / L) ^ 2 := by rw [hm]; linarith
  have hk : Real.sqrt m < π / L := by
    rw [Real.sqrt_lt' hpL]; exact hmlt
  have := h (Real.sqrt m) (Real.sqrt_nonneg _) hk
  rw [Real.sq_sqrt hm0, hm] at this
  have e : (B / A + (π / L) ^ 2) / 2 * A = (B + (π / L) ^ 2 * A) / 2 := by
    field_simp
  rw [e] at this
  linarith

#print axioms sharp_of_lt

theorem wirtinger_Ioo {L : ℝ} (hL : 0 < L) {f f' : ℝ → ℝ}
    (hd : ∀ x, HasDerivAt f (f' x) x) (hc : Continuous f') (h0 : f 0 = 0) (h1 : f L = 0) :
    (π / L) ^ 2 * ∫ x in Ioo 0 L, f x ^ 2 ≤ ∫ x in Ioo 0 L, f' x ^ 2 := by
  rw [← integral_Ioc_eq_integral_Ioo, ← integral_Ioc_eq_integral_Ioo,
    ← intervalIntegral.integral_of_le hL.le, ← intervalIntegral.integral_of_le hL.le]
  exact sharp_of_lt hL (intervalIntegral.integral_nonneg hL.le fun x _ => sq_nonneg _)
    fun k hk0 hk => wirtinger_k hL hk0 hk hd hc h0 h1

#print axioms wirtinger_Ioo

theorem frontier_square {L : ℝ} (hL : 0 < L) :
    frontier (Ioo 0 L ×ˢ Ioo 0 L) = (Icc 0 L ×ˢ Icc 0 L) \ (Ioo 0 L ×ˢ Ioo 0 L) := by
  rw [(isOpen_Ioo.prod isOpen_Ioo).frontier_eq, closure_prod_eq, closure_Ioo hL.ne]

#print axioms frontier_square

theorem hasDerivAt_partial_one {u : ℝ × ℝ → ℝ} (hu : Differentiable ℝ u) (x y : ℝ) :
    HasDerivAt (fun t => u (t, y)) (fderiv ℝ u (x, y) (1, 0)) x := by
  have h : HasDerivAt (fun t : ℝ => (t, y)) (1, 0) x :=
    (hasDerivAt_id x).prodMk (hasDerivAt_const x y)
  exact (hu (x, y)).hasFDerivAt.comp_hasDerivAt x h

#print axioms hasDerivAt_partial_one

theorem hasDerivAt_partial_two {u : ℝ × ℝ → ℝ} (hu : Differentiable ℝ u) (x y : ℝ) :
    HasDerivAt (fun t => u (x, t)) (fderiv ℝ u (x, y) (0, 1)) y := by
  have h : HasDerivAt (fun t : ℝ => (x, t)) (0, 1) y :=
    (hasDerivAt_const y x).prodMk (hasDerivAt_id y)
  exact (hu (x, y)).hasFDerivAt.comp_hasDerivAt y h

#print axioms hasDerivAt_partial_two

theorem integrableOn_square {L : ℝ} {F : ℝ × ℝ → ℝ} (hF : Continuous F) :
    IntegrableOn F (Ioo 0 L ×ˢ Ioo 0 L) :=
  (hF.continuousOn.integrableOn_compact (isCompact_Icc.prod isCompact_Icc)).mono_set
    (prod_mono Ioo_subset_Icc_self Ioo_subset_Icc_self)

#print axioms integrableOn_square

theorem integrable_square_prod {L : ℝ} {F : ℝ × ℝ → ℝ} (hF : Continuous F) :
    Integrable F ((volume.restrict (Ioo (0:ℝ) L)).prod (volume.restrict (Ioo (0:ℝ) L))) := by
  rw [Measure.prod_restrict, ← Measure.volume_eq_prod]
  exact integrableOn_square hF

#print axioms integrable_square_prod

theorem setIntegral_square (L : ℝ) (F : ℝ × ℝ → ℝ) :
    ∫ p in Ioo 0 L ×ˢ Ioo 0 L, F p
      = ∫ p, F p ∂((volume.restrict (Ioo (0:ℝ) L)).prod (volume.restrict (Ioo (0:ℝ) L))) := by
  rw [Measure.prod_restrict, ← Measure.volume_eq_prod]

#print axioms setIntegral_square

theorem poincare_sq {L : ℝ} (hL : 0 < L) {u : ℝ × ℝ → ℝ}
    (hu : ContDiff ℝ 1 u) (hrim : ∀ p ∈ frontier (Ioo 0 L ×ˢ Ioo 0 L), u p = 0) :
    ∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2 ≤ (L / (π * Real.sqrt 2)) ^ 2 *
      ∫ p in Ioo 0 L ×ˢ Ioo 0 L, ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2) := by
  have hd : Differentiable ℝ u := hu.differentiable one_ne_zero
  have hcd : Continuous (fun p => fderiv ℝ u p) := hu.continuous_fderiv one_ne_zero
  have hc1 : Continuous (fun p => fderiv ℝ u p (1, 0)) := hcd.clm_apply continuous_const
  have hc2 : Continuous (fun p => fderiv ℝ u p (0, 1)) := hcd.clm_apply continuous_const
  have huc : Continuous u := hu.continuous
  have hu2 : Continuous fun p => u p ^ 2 := huc.pow 2
  have hc1' : Continuous fun p => fderiv ℝ u p (1, 0) ^ 2 := hc1.pow 2
  have hc2' : Continuous fun p => fderiv ℝ u p (0, 1) ^ 2 := hc2.pow 2
  have hfr : ∀ x y, x ∈ Icc 0 L → y ∈ Icc 0 L → (x = 0 ∨ x = L ∨ y = 0 ∨ y = L) →
      u (x, y) = 0 := by
    intro x y hx hy h
    apply hrim
    rw [frontier_square hL]
    refine ⟨⟨hx, hy⟩, ?_⟩
    rintro ⟨⟨hx1, hx2⟩, hy1, hy2⟩
    rcases h with h | h | h | h <;> subst h <;> linarith
  have hL0 : (0:ℝ) ∈ Icc 0 L := ⟨le_rfl, hL.le⟩
  have hLL : L ∈ Icc 0 L := ⟨hL.le, le_rfl⟩
  have hX : (π / L) ^ 2 * ∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2
      ≤ ∫ p in Ioo 0 L ×ˢ Ioo 0 L, (fderiv ℝ u p (1, 0)) ^ 2 := by
    rw [setIntegral_square, setIntegral_square,
      integral_prod_symm _ (integrable_square_prod hu2),
      integral_prod_symm _ (integrable_square_prod hc1'), ← integral_const_mul]
    apply integral_mono_ae
    · exact ((integrable_square_prod hu2).integral_prod_right).const_mul _
    · exact (integrable_square_prod hc1').integral_prod_right
    · filter_upwards [ae_restrict_mem measurableSet_Ioo] with y hy
      exact wirtinger_Ioo hL (fun x => hasDerivAt_partial_one hd x y)
        (hc1.comp (by fun_prop)) (hfr 0 y hL0 (Ioo_subset_Icc_self hy) (Or.inl rfl))
        (hfr L y hLL (Ioo_subset_Icc_self hy) (Or.inr (Or.inl rfl)))
  have hY : (π / L) ^ 2 * ∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2
      ≤ ∫ p in Ioo 0 L ×ˢ Ioo 0 L, (fderiv ℝ u p (0, 1)) ^ 2 := by
    rw [setIntegral_square, setIntegral_square,
      integral_prod _ (integrable_square_prod hu2),
      integral_prod _ (integrable_square_prod hc2'), ← integral_const_mul]
    apply integral_mono_ae
    · exact ((integrable_square_prod hu2).integral_prod_left).const_mul _
    · exact (integrable_square_prod hc2').integral_prod_left
    · filter_upwards [ae_restrict_mem measurableSet_Ioo] with x hx
      exact wirtinger_Ioo hL (fun y => hasDerivAt_partial_two hd x y)
        (hc2.comp (by fun_prop)) (hfr x 0 (Ioo_subset_Icc_self hx) hL0 (Or.inr (Or.inr (Or.inl rfl))))
        (hfr x L (Ioo_subset_Icc_self hx) hLL (Or.inr (Or.inr (Or.inr rfl))))
  rw [integral_add (integrableOn_square hc1') (integrableOn_square hc2')]
  have hs := Real.sq_sqrt (show (0:ℝ) ≤ 2 by norm_num)
  have hC : (L / (π * Real.sqrt 2)) ^ 2 * (2 * (π / L) ^ 2) = 1 := by
    have := Real.pi_pos
    field_simp
    rw [hs]
  have hG : 2 * (π / L) ^ 2 * ∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2 ≤
      (∫ p in Ioo 0 L ×ˢ Ioo 0 L, (fderiv ℝ u p (1, 0)) ^ 2) +
        ∫ p in Ioo 0 L ×ˢ Ioo 0 L, (fderiv ℝ u p (0, 1)) ^ 2 := by linarith
  calc ∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2
      = (L / (π * Real.sqrt 2)) ^ 2 * (2 * (π / L) ^ 2 * ∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2) := by
        rw [← mul_assoc, hC, one_mul]
    _ ≤ _ := mul_le_mul_of_nonneg_left hG (sq_nonneg _)

#print axioms poincare_sq

/-- Poincare inequality on the held square, and coercivity. Let the sheet be the open square of
side `L > 0`, and let `u` be a continuously differentiable shape that is zero on the rim. Then the
shape's 2-size is at most `C_P = L/(π√2)` times its slope's 2-size, `‖u‖ ≤ C_P ‖∇u‖`; and so the
slope alone controls the whole `H¹` size: `‖∇u‖² ≥ α (‖u‖² + ‖∇u‖²)` with `α = 1/(1 + C_P²)`. -/
theorem poincare_inequality_held_square {L : ℝ} (hL : 0 < L) {u : ℝ × ℝ → ℝ}
    (hu : ContDiff ℝ 1 u) (hrim : ∀ p ∈ frontier (Ioo 0 L ×ˢ Ioo 0 L), u p = 0) :
    Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2)
        ≤ L / (π * Real.sqrt 2) * Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L,
            ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2)) ∧
      1 / (1 + (L / (π * Real.sqrt 2)) ^ 2) *
          ((∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2) + ∫ p in Ioo 0 L ×ˢ Ioo 0 L,
            ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2))
        ≤ ∫ p in Ioo 0 L ×ˢ Ioo 0 L,
            ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2) := by
  have hP := poincare_sq hL hu hrim
  have hU0 : 0 ≤ ∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2 :=
    setIntegral_nonneg (isOpen_Ioo.prod isOpen_Ioo).measurableSet fun p _ => sq_nonneg _
  have hG0 : 0 ≤ ∫ p in Ioo 0 L ×ˢ Ioo 0 L,
      ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2) :=
    setIntegral_nonneg (isOpen_Ioo.prod isOpen_Ioo).measurableSet fun p _ => by positivity
  have hC0 : 0 ≤ L / (π * Real.sqrt 2) := by positivity
  refine ⟨?_, ?_⟩
  · calc Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2)
        ≤ Real.sqrt ((L / (π * Real.sqrt 2)) ^ 2 * ∫ p in Ioo 0 L ×ˢ Ioo 0 L,
            ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2)) := Real.sqrt_le_sqrt hP
      _ = _ := by rw [Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hC0]
  · rw [div_mul_eq_mul_div, one_mul, div_le_iff₀ (by positivity)]
    nlinarith

/-- `L/(π√2)` is the best Poincare constant on the square: if a number `C` makes
`‖u‖ ≤ C ‖∇u‖` true for every continuously differentiable shape `u` that is zero on the rim of
the square of side `L`, then `C ≥ L/(π√2)`. The single bump `sin(πx/L) sin(πy/L)` gives equality. -/
theorem poincare_constant_best_on_square {L : ℝ} (hL : 0 < L) (C : ℝ)
    (hC : ∀ u : ℝ × ℝ → ℝ, ContDiff ℝ 1 u →
      (∀ p ∈ frontier (Ioo 0 L ×ˢ Ioo 0 L), u p = 0) →
      Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2)
        ≤ C * Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L,
            ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2))) :
    L / (π * Real.sqrt 2) ≤ C := by
  set a := π / L with ha
  have ha0 : a ≠ 0 := (div_pos Real.pi_pos hL).ne'
  have haL : a * L = π := by rw [ha]; field_simp
  set u : ℝ × ℝ → ℝ := fun p => Real.sin (a * p.1) * Real.sin (a * p.2) with hu_def
  have hu : ContDiff ℝ 1 u := by
    simp only [hu_def]
    fun_prop
  have hz : ∀ t ∈ Icc 0 L, t ∉ Ioo 0 L → Real.sin (a * t) = 0 := by
    intro t ht hn
    rcases eq_or_lt_of_le ht.1 with h | h
    · rw [← h, mul_zero, Real.sin_zero]
    · rcases eq_or_lt_of_le ht.2 with h' | h'
      · rw [h', haL, Real.sin_pi]
      · exact absurd ⟨h, h'⟩ hn
  have hrim : ∀ p ∈ frontier (Ioo 0 L ×ˢ Ioo 0 L), u p = 0 := by
    rintro ⟨x, y⟩ hp
    rw [frontier_square hL] at hp
    obtain ⟨⟨hx, hy⟩, hn⟩ := hp
    by_cases hxI : x ∈ Ioo 0 L
    · have hyI : y ∉ Ioo 0 L := fun hyI => hn ⟨hxI, hyI⟩
      simp only [hu_def, hz y hy hyI, mul_zero]
    · simp only [hu_def, hz x hx hxI, zero_mul]
  have hd := hu.differentiable one_ne_zero
  have hd1 : ∀ p : ℝ × ℝ, fderiv ℝ u p (1, 0) = a * Real.cos (a * p.1) * Real.sin (a * p.2) := by
    rintro ⟨x, y⟩
    have h1 := hasDerivAt_partial_one hd x y
    have h2 : HasDerivAt (fun t => Real.sin (a * t) * Real.sin (a * y))
        (a * Real.cos (a * x) * Real.sin (a * y)) x := by
      have := (((hasDerivAt_id' x).const_mul a).sin).mul_const (Real.sin (a * y))
      convert this using 1
      ring
    exact h1.unique h2
  have hd2 : ∀ p : ℝ × ℝ, fderiv ℝ u p (0, 1) = a * Real.sin (a * p.1) * Real.cos (a * p.2) := by
    rintro ⟨x, y⟩
    have h1 := hasDerivAt_partial_two hd x y
    have h2 : HasDerivAt (fun t => Real.sin (a * x) * Real.sin (a * t))
        (a * Real.sin (a * x) * Real.cos (a * y)) y := by
      have := (((hasDerivAt_id' y).const_mul a).sin).const_mul (Real.sin (a * x))
      convert this using 1
      ring
    exact h1.unique h2
  have hIs : ∫ x in Ioo 0 L, Real.sin (a * x) ^ 2 = L / 2 := by
    rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hL.le,
      intervalIntegral.integral_comp_mul_left (f := fun x => Real.sin x ^ 2) ha0,
      integral_sin_sq, mul_zero, haL, Real.sin_zero, Real.sin_pi, smul_eq_mul, ha]
    field_simp
    ring
  have hIc : ∫ x in Ioo 0 L, Real.cos (a * x) ^ 2 = L / 2 := by
    rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hL.le,
      intervalIntegral.integral_comp_mul_left (f := fun x => Real.cos x ^ 2) ha0,
      integral_cos_sq, mul_zero, haL, Real.sin_zero, Real.sin_pi, smul_eq_mul, ha]
    field_simp
    ring
  set μ := volume.restrict (Ioo (0:ℝ) L) with hμ
  have hU : ∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2 = (L / 2) ^ 2 := by
    have e := integral_prod_mul (μ := μ) (ν := μ) (fun x => Real.sin (a * x) ^ 2)
      (fun y => Real.sin (a * y) ^ 2)
    rw [setIntegral_square]
    simp only [hu_def, mul_pow]
    rw [e, hIs, sq]
  have hG : ∫ p in Ioo 0 L ×ˢ Ioo 0 L,
      ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2) = (π / Real.sqrt 2) ^ 2 := by
    have e1 := integral_prod_mul (μ := μ) (ν := μ) (fun x => a ^ 2 * Real.cos (a * x) ^ 2)
      (fun y => Real.sin (a * y) ^ 2)
    have e2 := integral_prod_mul (μ := μ) (ν := μ) (fun x => a ^ 2 * Real.sin (a * x) ^ 2)
      (fun y => Real.cos (a * y) ^ 2)
    have hf : (fun p : ℝ × ℝ => (fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2) =
        fun p => a ^ 2 * Real.cos (a * p.1) ^ 2 * Real.sin (a * p.2) ^ 2 +
          a ^ 2 * Real.sin (a * p.1) ^ 2 * Real.cos (a * p.2) ^ 2 := by
      funext p; rw [hd1, hd2]; ring
    rw [hf, setIntegral_square, integral_add (integrable_square_prod (by fun_prop))
      (integrable_square_prod (by fun_prop)), e1, e2, integral_const_mul, integral_const_mul,
      hIs, hIc, ha, div_pow π (Real.sqrt 2) 2, Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2)]
    field_simp
    ring
  have h := hC u hu hrim
  rw [hU, hG, Real.sqrt_sq (by positivity), Real.sqrt_sq (by positivity)] at h
  have hs0 : 0 < Real.sqrt 2 := by positivity
  have hs := Real.sq_sqrt (show (0:ℝ) ≤ 2 by norm_num)
  have h' : L / 2 * Real.sqrt 2 ≤ C * π := by
    have := mul_le_mul_of_nonneg_right h hs0.le
    rwa [show C * (π / Real.sqrt 2) * Real.sqrt 2 = C * π by field_simp] at this
  rw [div_le_iff₀ (by positivity)]
  nlinarith [mul_le_mul_of_nonneg_right h' hs0.le]

/-- The energy bound for the loaded sheet (Step 5). Let the sheet be the open square of side
`L > 0` under tension `T > 0`, and let the load `f` have finite 2-size on it. If a continuously
differentiable shape `u`, zero on the rim, satisfies the weak form
`T ∫ ∇u · ∇v = ∫ f v` for every continuously differentiable test shape `v` zero on the rim,
then, before solving anything, `‖∇u‖ ≤ C_P ‖f‖ / T` and `‖u‖ ≤ C_P² ‖f‖ / T`,
with `C_P = L/(π√2)`. -/
theorem energy_bound_loaded_sheet {L T : ℝ} (hL : 0 < L) (hT : 0 < T) {u f : ℝ × ℝ → ℝ}
    (hf : MemLp f 2 (volume.restrict (Ioo 0 L ×ˢ Ioo 0 L)))
    (hu : ContDiff ℝ 1 u) (hrim : ∀ p ∈ frontier (Ioo 0 L ×ˢ Ioo 0 L), u p = 0)
    (hweak : ∀ v : ℝ × ℝ → ℝ, ContDiff ℝ 1 v →
      (∀ p ∈ frontier (Ioo 0 L ×ˢ Ioo 0 L), v p = 0) →
      T * ∫ p in Ioo 0 L ×ˢ Ioo 0 L,
          (fderiv ℝ u p (1, 0) * fderiv ℝ v p (1, 0) + fderiv ℝ u p (0, 1) * fderiv ℝ v p (0, 1))
        = ∫ p in Ioo 0 L ×ˢ Ioo 0 L, f p * v p) :
    Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L,
          ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2))
        ≤ L / (π * Real.sqrt 2) * Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L, f p ^ 2) / T ∧
      Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L, u p ^ 2)
        ≤ (L / (π * Real.sqrt 2)) ^ 2 * Real.sqrt (∫ p in Ioo 0 L ×ˢ Ioo 0 L, f p ^ 2) / T := by
  set S := Ioo (0:ℝ) L ×ˢ Ioo (0:ℝ) L with hS
  set C := L / (π * Real.sqrt 2) with hCdef
  have hC0 : 0 < C := by positivity
  set F := ∫ p in S, f p ^ 2 with hF
  set U := ∫ p in S, u p ^ 2 with hUdef
  set G := ∫ p in S, ((fderiv ℝ u p (1, 0)) ^ 2 + (fderiv ℝ u p (0, 1)) ^ 2) with hGdef
  have hP : U ≤ C ^ 2 * G := poincare_sq hL hu hrim
  have hF0 : 0 ≤ F := setIntegral_nonneg (isOpen_Ioo.prod isOpen_Ioo).measurableSet
    fun p _ => sq_nonneg _
  have hU0 : 0 ≤ U := setIntegral_nonneg (isOpen_Ioo.prod isOpen_Ioo).measurableSet
    fun p _ => sq_nonneg _
  have hG0 : 0 ≤ G := setIntegral_nonneg (isOpen_Ioo.prod isOpen_Ioo).measurableSet
    fun p _ => by positivity
  have hw := hweak u hu hrim
  simp only [← sq] at hw
  -- hw : T * G = ∫ f u
  set t := C ^ 2 / T with ht
  have ht0 : 0 < t := by positivity
  have hpt : ∀ p, f p * u p ≤ t / 2 * f p ^ 2 + 1 / (2 * t) * u p ^ 2 := by
    intro p
    have e : t / 2 * f p ^ 2 + 1 / (2 * t) * u p ^ 2 - f p * u p
        = (t * f p - u p) ^ 2 / (2 * t) := by
      field_simp
      ring
    have : 0 ≤ (t * f p - u p) ^ 2 / (2 * t) := by positivity
    linarith
  have hu2 : IntegrableOn (fun p => u p ^ 2) S := integrableOn_square (hu.continuous.pow 2)
  have hR : Integrable (fun p => t / 2 * f p ^ 2 + 1 / (2 * t) * u p ^ 2) (volume.restrict S) :=
    (hf.integrable_sq.const_mul _).add (hu2.const_mul _)
  have hfu : ∫ p in S, f p * u p ≤ t / 2 * F + 1 / (2 * t) * U := by
    have hRe : ∫ p in S, (t / 2 * f p ^ 2 + 1 / (2 * t) * u p ^ 2) = t / 2 * F + 1 / (2 * t) * U := by
      rw [integral_add (hf.integrable_sq.const_mul _) (hu2.const_mul _), integral_const_mul,
        integral_const_mul]
    rw [← hRe]
    by_cases hi : Integrable (fun p => f p * u p) (volume.restrict S)
    · exact integral_mono hi hR hpt
    · rw [integral_undef hi]
      exact integral_nonneg_of_ae (Filter.Eventually.of_forall fun p => by positivity) |>.trans_eq' rfl
  have hTG : T * G ≤ t / 2 * F + 1 / (2 * t) * (C ^ 2 * G) := by
    have := mul_le_mul_of_nonneg_left hP (show 0 ≤ 1 / (2 * t) by positivity)
    linarith
  have e : 1 / (2 * t) * (C ^ 2 * G) = T * G / 2 := by
    rw [ht]; field_simp
  rw [e] at hTG
  have hGle : G ≤ (C * Real.sqrt F / T) ^ 2 := by
    rw [div_pow, mul_pow, Real.sq_sqrt hF0, le_div_iff₀ (by positivity)]
    have : T * G ≤ t * F := by linarith
    rw [ht] at this
    have := mul_le_mul_of_nonneg_left this hT.le
    rw [show T * (C ^ 2 / T * F) = C ^ 2 * F by field_simp] at this
    nlinarith
  have h1 : Real.sqrt G ≤ C * Real.sqrt F / T := by
    calc Real.sqrt G ≤ Real.sqrt ((C * Real.sqrt F / T) ^ 2) := Real.sqrt_le_sqrt hGle
      _ = C * Real.sqrt F / T := Real.sqrt_sq (by positivity)
  refine ⟨h1, ?_⟩
  calc Real.sqrt U ≤ Real.sqrt (C ^ 2 * G) := Real.sqrt_le_sqrt hP
    _ = C * Real.sqrt G := by rw [Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hC0.le]
    _ ≤ C * (C * Real.sqrt F / T) := mul_le_mul_of_nonneg_left h1 hC0.le
    _ = C ^ 2 * Real.sqrt F / T := by ring

-- Worked numbers, in exact fractions (metres, newtons, joules): side 1 m, T = 200 N/m,
-- lift b = 1/50 m (2 cm), so b² = 1/2500 m² and T/2 = 100 N/m.
-- Pyramid: slope 2b = 1/25 everywhere, slope squared 1/625 m² (0.001600), energy 4/25 J (0.16 J).
example : (2 * (1 / 50 : ℚ)) ^ 2 * 1 = 1 / 625 ∧ (100 : ℚ) * (1 / 625) = 4 / 25 := by norm_num
-- Bump: size squared b²/4 = 1/10000 m⁴ (1.000e-04).
example : ((1 / 50 : ℚ)) ^ 2 / 4 = 1 / 10000 := by norm_num
-- Pyramid: size squared b²/6 = 1/15000 m⁴ (6.667e-05); size over slope, squared, 1/24 m².
example : ((1 / 50 : ℚ)) ^ 2 / 6 = 1 / 15000 ∧ (1 / 15000 : ℚ) / (1 / 625) = 1 / 24 := by norm_num
-- The pyramid's ratio 1/√24 (0.204124 m) sits below C_P = 1/(π√2): 1/24 < 1/(2π²).
example : (1 : ℝ) / 24 < 1 / (2 * π ^ 2) := by
  have h1 := Real.pi_lt_d2
  have h2 := Real.pi_pos
  rw [div_lt_div_iff₀ (by norm_num) (by positivity)]
  nlinarith
-- Knife edge: energy floor (T/2) × 4b² = 100 × 4 × 1/2500 = 4/25 J (0.160000 J).
example : (100 : ℚ) * (4 * (1 / 50) ^ 2) = 4 / 25 := by norm_num
-- Sag: ‖f‖/T over the unit square with f = 16 N/m², T = 200 N/m is 2/25; the Poincare bound
-- on the slope is C_P × 2/25 (0.018006 m).
example : (16 : ℚ) * 1 / 200 = 2 / 25 := by norm_num
-- Free rim: the sheet raised 2 cm whole has size squared b² × 1 m² = 1/2500 m⁴ (4.000e-04).
example : ((1 / 50 : ℚ)) ^ 2 * 1 = 1 / 2500 := by norm_num

#print axioms poincare_inequality_held_square
#print axioms poincare_constant_best_on_square
#print axioms energy_bound_loaded_sheet
