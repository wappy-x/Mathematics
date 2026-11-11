-- Change of variables: a total over places equals the total over addresses weighted by the size of the Jacobian determinant, the polar, cylindrical and spherical factors are r, r and ρ^2 sin φ, and the card's valley takes exactly 60π mm km^2 of rain.
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open MeasureTheory Set Real

noncomputable def e3 : (ℝ × ℝ × ℝ) ≃ₗ[ℝ] (Fin 3 → ℝ) where
  toFun p := ![p.1, p.2.1, p.2.2]
  invFun v := (v 0, v 1, v 2)
  map_add' := by intro x y; ext i; fin_cases i <;> simp
  map_smul' := by intro c x; ext i; fin_cases i <;> simp
  left_inv := by intro p; simp
  right_inv := by intro v; ext i; fin_cases i <;> simp

noncomputable def b3 : Module.Basis (Fin 3) ℝ (ℝ × ℝ × ℝ) := Module.Basis.ofEquivFun e3

lemma det3 (L : (ℝ × ℝ × ℝ) →L[ℝ] (ℝ × ℝ × ℝ)) :
    L.det = Matrix.det (Matrix.of fun i j => e3 (L (e3.symm (Pi.single j 1))) i) := by
  rw [ContinuousLinearMap.det, ← LinearMap.det_toMatrix b3]
  congr 1

lemma valley_angle_iff {θ : ℝ} (h1 : -π < θ) (h2 : θ < π) :
    (0 ≤ sin θ ∧ sin θ ≤ √3 * cos θ) ↔ (0 ≤ θ ∧ θ ≤ π / 3) := by
  have hpi := pi_pos
  have hs3 : sin (θ - π / 3) * 2 = sin θ - √3 * cos θ := by
    rw [sin_sub, cos_pi_div_three, sin_pi_div_three]; ring
  have hsin0 : 0 ≤ sin θ ↔ 0 ≤ θ := by
    constructor
    · intro h
      by_contra hn
      push Not at hn
      linarith [sin_neg_of_neg_of_neg_pi_lt hn h1]
    · intro h
      exact sin_nonneg_of_nonneg_of_le_pi h h2.le
  constructor
  · rintro ⟨ha, hb⟩
    have hθ := hsin0.mp ha
    refine ⟨hθ, ?_⟩
    by_contra hn
    push Not at hn
    have := sin_pos_of_pos_of_lt_pi (x := θ - π / 3) (by linarith) (by linarith)
    linarith
  · rintro ⟨ha, hb⟩
    refine ⟨hsin0.mpr ha, ?_⟩
    have := sin_nonpos_of_nonpos_of_neg_pi_le (x := θ - π / 3) (by linarith) (by linarith)
    linarith

lemma valley_polar_iff {r θ : ℝ} (hr : 0 < r) (h1 : -π < θ) (h2 : θ < π) :
    ((r * cos θ) ^ 2 + (r * sin θ) ^ 2 ≤ 9 ∧ 0 ≤ r * sin θ ∧ r * sin θ ≤ √3 * (r * cos θ)) ↔
      (r ≤ 3 ∧ 0 ≤ θ ∧ θ ≤ π / 3) := by
  have hsq : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 := by
    linear_combination r ^ 2 * cos_sq_add_sin_sq θ
  rw [hsq, ← valley_angle_iff h1 h2]
  have e1 : r ^ 2 ≤ 9 ↔ r ≤ 3 := by
    constructor
    · intro h; nlinarith
    · intro h; nlinarith
  have e2 : 0 ≤ r * sin θ ↔ 0 ≤ sin θ := mul_nonneg_iff_of_pos_left hr
  have e3 : r * sin θ ≤ √3 * (r * cos θ) ↔ sin θ ≤ √3 * cos θ := by
    rw [show √3 * (r * cos θ) = r * (√3 * cos θ) by ring]
    exact ⟨fun h => le_of_mul_le_mul_left h hr, fun h => mul_le_mul_of_nonneg_left h hr.le⟩
  rw [e1, e2, e3]

lemma valley_radial : ∫ r in Ioc (0:ℝ) 3, r * (20 + 10 * r) = 180 := by
  rw [← intervalIntegral.integral_of_le (by norm_num)]
  have hd : ∀ x ∈ uIcc (0:ℝ) 3, HasDerivAt (fun r : ℝ => 10 * r ^ 2 + 10 / 3 * r ^ 3) (x * (20 + 10 * x)) x := by
    intro x _
    have := ((hasDerivAt_pow 2 x).const_mul 10).add ((hasDerivAt_pow 3 x).const_mul (10 / 3))
    convert this using 1
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num

#print axioms e3
#print axioms b3
#print axioms det3
#print axioms valley_angle_iff
#print axioms valley_polar_iff
#print axioms valley_radial

/-- **Change of variables.** A map T sends each address u (a point of n-dimensional space) to a
place T(u). S is a region of addresses (one that has a volume: a measurable set), and
D = T(S) is the places it covers. Suppose:
* T covers each place once, except on a set of zero volume: T is one-to-one on S once some
  set N of zero volume is removed;
* T has continuous partial derivatives (T is continuously differentiable);
* the Jacobian determinant det J_T vanishes only on a set of zero volume inside S;
* the quantity f is continuous on D, and D is bounded.
Then the total of f over the places equals the total over the addresses, each weighted by the
quantity at its place and by the size of the Jacobian determinant there:
∫ over D of f = ∫ over S of f(T(u)) · |det J_T(u)|. -/
theorem integral_image_eq_integral_comp_mul_abs_det_jacobian {n : ℕ}
    (T : (Fin n → ℝ) → (Fin n → ℝ)) (S : Set (Fin n → ℝ)) (f : (Fin n → ℝ) → ℝ)
    (hS : MeasurableSet S)
    (h_once : ∃ N : Set (Fin n → ℝ), volume N = 0 ∧ InjOn T (S \ N))
    (hT : ContDiff ℝ 1 T)
    (h_det : volume {u | u ∈ S ∧ (fderiv ℝ T u).det = 0} = 0)
    (hf : ContinuousOn f (T '' S))
    (hD : Bornology.IsBounded (T '' S)) :
    ∫ x in T '' S, f x = ∫ u in S, f (T u) * |(fderiv ℝ T u).det| := by
  obtain ⟨N, hN, hinj⟩ := h_once
  set M := toMeasurable volume N with hMdef
  have hM : volume M = 0 := by rw [hMdef, measure_toMeasurable]; exact hN
  have hSM : MeasurableSet (S \ M) := hS.diff (measurableSet_toMeasurable _ _)
  have hinj' : InjOn T (S \ M) := hinj.mono (sdiff_subset_sdiff_right (subset_toMeasurable _ _))
  have hdiff : Differentiable ℝ T := hT.differentiable (by norm_num)
  have hderiv : ∀ x ∈ S \ M, HasFDerivWithinAt T (fderiv ℝ T x) (S \ M) x := fun x _ =>
    (hdiff x).hasFDerivAt.hasFDerivWithinAt
  have key := integral_image_eq_integral_abs_det_fderiv_smul volume hSM hderiv hinj' f
  have hS_ae : (S \ M : Set _) =ᵐ[volume] S := sdiff_null_ae_eq_self hM
  have hTM : volume (T '' M) = 0 :=
    addHaar_image_eq_zero_of_differentiableOn_of_addHaar_eq_zero volume hdiff.differentiableOn hM
  have himg : T '' (S \ M) =ᵐ[volume] T '' S := by
    rw [ae_eq_set]
    constructor
    · rw [sdiff_eq_empty.mpr (image_mono sdiff_subset)]; simp
    · refine measure_mono_null ?_ hTM
      rintro y ⟨⟨x, hx, rfl⟩, hy⟩
      refine ⟨x, ?_, rfl⟩
      by_contra hxM
      exact hy ⟨x, ⟨hx, hxM⟩, rfl⟩
  calc ∫ x in T '' S, f x = ∫ x in T '' (S \ M), f x := setIntegral_congr_set himg.symm
    _ = ∫ u in S \ M, |(fderiv ℝ T u).det| • f (T u) := key
    _ = ∫ u in S, |(fderiv ℝ T u).det| • f (T u) := setIntegral_congr_set hS_ae
    _ = ∫ u in S, f (T u) * |(fderiv ℝ T u).det| := by
      congr 1; funext u; rw [smul_eq_mul, mul_comm]

/-- **The table of factors.** The Jacobian determinant of each standard coordinate change, at
every address:
* polar, x = r cos θ, y = r sin θ: the determinant is r, so dA = r dr dθ;
* cylindrical, polar with the height z unchanged: the determinant is r, so dV = r dr dθ dz;
* spherical, x = ρ sin φ cos θ, y = ρ sin φ sin θ, z = ρ cos φ, inputs in the order (ρ, φ, θ):
  the determinant is ρ^2 sin φ, so dV = ρ^2 sin φ dρ dφ dθ. -/
theorem jacobian_det_polar_cylindrical_spherical :
    (∀ r θ : ℝ,
      (fderiv ℝ (fun p : ℝ × ℝ => (p.1 * cos p.2, p.1 * sin p.2)) (r, θ)).det = r) ∧
    (∀ r θ z : ℝ,
      (fderiv ℝ (fun p : ℝ × ℝ × ℝ => (p.1 * cos p.2.1, p.1 * sin p.2.1, p.2.2))
        (r, θ, z)).det = r) ∧
    (∀ ρ φ θ : ℝ,
      (fderiv ℝ (fun p : ℝ × ℝ × ℝ =>
          (p.1 * sin p.2.1 * cos p.2.2, p.1 * sin p.2.1 * sin p.2.2, p.1 * cos p.2.1))
        (ρ, φ, θ)).det = ρ ^ 2 * sin φ) := by
  refine ⟨?_, ?_, ?_⟩
  · intro r θ
    have h : HasFDerivAt (fun p : ℝ × ℝ => (p.1 * cos p.2, p.1 * sin p.2))
        (fderivPolarCoordSymm (r, θ)) (r, θ) := hasFDerivAt_polarCoord_symm (r, θ)
    rw [h.fderiv, det_fderivPolarCoordSymm]
  · intro r θ z
    set x : ℝ × ℝ × ℝ := (r, θ, z)
    have h1 : HasFDerivAt (fun p : ℝ × ℝ × ℝ => p.2.1) _ x := (hasFDerivAt_snd (𝕜 := ℝ) (p := x)).fst
    have h2 : HasFDerivAt (fun p : ℝ × ℝ × ℝ => p.2.2) _ x := (hasFDerivAt_snd (𝕜 := ℝ) (p := x)).snd
    have h0 : HasFDerivAt (fun p : ℝ × ℝ × ℝ => p.1) _ x := hasFDerivAt_fst (𝕜 := ℝ) (p := x)
    have hc := h0.mul ((hasDerivAt_cos θ).comp_hasFDerivAt x h1)
    have hs := h0.mul ((hasDerivAt_sin θ).comp_hasFDerivAt x h1)
    have h : HasFDerivAt (fun p : ℝ × ℝ × ℝ => (p.1 * cos p.2.1, p.1 * sin p.2.1, p.2.2)) _ x :=
      hc.prodMk (hs.prodMk h2)
    rw [h.fderiv, det3]
    simp [Matrix.det_fin_three, e3, x]
    linear_combination r * sin_sq_add_cos_sq θ
  · intro ρ φ θ
    set x : ℝ × ℝ × ℝ := (ρ, φ, θ)
    have h1 : HasFDerivAt (fun p : ℝ × ℝ × ℝ => p.2.1) _ x := (hasFDerivAt_snd (𝕜 := ℝ) (p := x)).fst
    have h2 : HasFDerivAt (fun p : ℝ × ℝ × ℝ => p.2.2) _ x := (hasFDerivAt_snd (𝕜 := ℝ) (p := x)).snd
    have h0 : HasFDerivAt (fun p : ℝ × ℝ × ℝ => p.1) _ x := hasFDerivAt_fst (𝕜 := ℝ) (p := x)
    have hs1 := h0.mul ((hasDerivAt_sin φ).comp_hasFDerivAt x h1)
    have ha := hs1.mul ((hasDerivAt_cos θ).comp_hasFDerivAt x h2)
    have hb := hs1.mul ((hasDerivAt_sin θ).comp_hasFDerivAt x h2)
    have hc := h0.mul ((hasDerivAt_cos φ).comp_hasFDerivAt x h1)
    have h : HasFDerivAt (fun p : ℝ × ℝ × ℝ =>
          (p.1 * sin p.2.1 * cos p.2.2, p.1 * sin p.2.1 * sin p.2.2, p.1 * cos p.2.1)) _ x :=
      ha.prodMk (hb.prodMk hc)
    rw [h.fderiv, det3]
    simp [Matrix.det_fin_three, e3, x]
    linear_combination ρ ^ 2 * sin φ * ((sin φ ^ 2 + cos φ ^ 2) * sin_sq_add_cos_sq θ + sin_sq_add_cos_sq φ)

/-- **The storm on the valley.** The valley floor, in km east (x) and north (y) of the outlet,
is the slice of circle of radius 3 km opening through 60 degrees from the east edge: the points
with x^2 + y^2 ≤ 9 and 0 ≤ y ≤ √3 · x. Rain lies 20 + 10 r mm deep at distance
r = √(x^2 + y^2) km from the outlet. The total over the valley, taken over the east-north
ground with no mention of polar coordinates, is exactly 60π mm km^2 (188,496 cubic metres). -/
theorem valley_rain_total :
    ∫ p in {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ 9 ∧ 0 ≤ p.2 ∧ p.2 ≤ √3 * p.1},
      (20 + 10 * √(p.1 ^ 2 + p.2 ^ 2)) = 60 * π := by
  set A : Set (ℝ × ℝ) := {p | p.1 ^ 2 + p.2 ^ 2 ≤ 9 ∧ 0 ≤ p.2 ∧ p.2 ≤ √3 * p.1} with hA
  set g : ℝ × ℝ → ℝ := fun p => 20 + 10 * √(p.1 ^ 2 + p.2 ^ 2) with hg
  have hAm : MeasurableSet A := by
    have : IsClosed A :=
      IsClosed.inter
        (isClosed_le (f := fun p : ℝ × ℝ => p.1 ^ 2 + p.2 ^ 2) (by fun_prop) continuous_const)
        (IsClosed.inter (isClosed_le (g := fun p : ℝ × ℝ => p.2) continuous_const (by fun_prop))
          (isClosed_le (f := fun p : ℝ × ℝ => p.2) (g := fun p : ℝ × ℝ => √3 * p.1)
            (by fun_prop) (by fun_prop)))
    exact this.measurableSet
  rw [← integral_indicator hAm, ← integral_comp_polarCoord_symm]
  set B : Set (ℝ × ℝ) := Icc 0 3 ×ˢ Icc 0 (π / 3) with hB
  have hpt : EqOn (fun q : ℝ × ℝ => q.1 • A.indicator g (polarCoord.symm q))
      (B.indicator fun q => q.1 * (20 + 10 * q.1)) polarCoord.target := by
    rintro ⟨r, θ⟩ ⟨hr, hθ⟩
    simp only [mem_Ioi, mem_Ioo] at hr hθ
    have hiff := valley_polar_iff hr hθ.1 hθ.2
    have hsq : √((r * cos θ) ^ 2 + (r * sin θ) ^ 2) = r := by
      rw [show (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 by
        linear_combination r ^ 2 * cos_sq_add_sin_sq θ, sqrt_sq hr.le]
    simp only [polarCoord_symm_apply, smul_eq_mul]
    by_cases hm : r ≤ 3 ∧ 0 ≤ θ ∧ θ ≤ π / 3
    · have hA' : (r * cos θ, r * sin θ) ∈ A := hiff.mpr hm
      have hB' : (r, θ) ∈ B := ⟨⟨hr.le, hm.1⟩, hm.2⟩
      rw [indicator_of_mem hA', indicator_of_mem hB']
      simp only [hg, hsq]
    · have hA' : (r * cos θ, r * sin θ) ∉ A := fun h => hm (hiff.mp h)
      have hB' : (r, θ) ∉ B := fun h => hm ⟨h.1.2, h.2⟩
      rw [indicator_of_notMem hA', indicator_of_notMem hB', mul_zero]
  rw [setIntegral_congr_fun polarCoord.open_target.measurableSet hpt,
    setIntegral_indicator (measurableSet_Icc.prod measurableSet_Icc)]
  have hpi := pi_pos
  have hset : polarCoord.target ∩ B = Ioc 0 3 ×ˢ Icc 0 (π / 3) := by
    rw [polarCoord_target, hB, prod_inter_prod]
    congr 1
    · ext r; simp only [mem_inter_iff, mem_Ioi, mem_Icc, mem_Ioc]
      constructor
      · rintro ⟨h1, -, h2⟩; exact ⟨h1, h2⟩
      · rintro ⟨h1, h2⟩; exact ⟨h1, h1.le, h2⟩
    · ext θ; simp only [mem_inter_iff, mem_Ioo, mem_Icc]
      constructor
      · rintro ⟨-, h⟩; exact h
      · rintro ⟨h1, h2⟩; exact ⟨⟨by linarith, by linarith⟩, h1, h2⟩
  rw [hset]
  have := setIntegral_prod_mul (μ := (volume : Measure ℝ)) (ν := (volume : Measure ℝ))
    (fun r : ℝ => r * (20 + 10 * r)) (fun _ : ℝ => (1 : ℝ)) (Ioc 0 3) (Icc 0 (π / 3))
  simp only [mul_one] at this
  rw [Measure.volume_eq_prod, this, valley_radial]
  simp
  rw [max_eq_left (by linarith)]
  ring

-- Worked numbers, by hand: the first piece 10 × 3^2 and the second piece (10/3) × 3^3.
example : (10 : ℚ) * 3 ^ 2 = 90 := by norm_num
example : (10 / 3 : ℚ) * 3 ^ 3 = 90 := by norm_num
-- The angle: (π/3) × (90 + 90) = 60π.
example : π / 3 * (90 + 90) = 60 * π := by norm_num; ring
-- Mean depth: 60π over the valley's area (π/3) × 3^2 / 2 is 40 mm.
example : 60 * π / (π / 3 * 3 ^ 2 / 2) = 40 := by
  field_simp [Real.pi_ne_zero]; norm_num
-- Angle in degrees instead of radians: 60 × (90 + 90) = 10800.
example : (60 : ℕ) * (90 + 90) = 10800 := by norm_num
-- Raindrop of radius 2 mm: 2π × 2 × (2^3 / 3) = 32π/3.
example : 2 * π * 2 * (2 ^ 3 / 3) = 32 * π / 3 := by norm_num; ring
-- Round tank of radius 100 m: 2π × (100^2 / 2) = 10000π cubic metres per metre of depth.
example : 2 * π * (100 ^ 2 / 2) = 10000 * π := by norm_num; ring

#print axioms integral_image_eq_integral_comp_mul_abs_det_jacobian
#print axioms jacobian_det_polar_cylindrical_spherical
#print axioms valley_rain_total
