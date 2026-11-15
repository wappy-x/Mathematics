-- Brouwer and Borsuk-Ulam: every continuous map of the closed disc into itself fixes a point, the disc has no retraction onto its rim, and two continuous readings on the sphere agree at some opposite pair.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.MetricSpace.Pseudo.Defs
import Mathlib.Analysis.Complex.CoveringMap
import Mathlib.Topology.Homotopy.Lifting
import Mathlib.Analysis.SpecialFunctions.Complex.Log

open Metric Set

section helpers
open Complex Real

theorem bb_exp_const (m : ℝ → ℂ) {a b : ℝ} (hab : a ≤ b) (hm : ContinuousOn m (Icc a b))
    (h1 : ∀ t ∈ Icc a b, exp (m t) = 1) : m a = m b := by
  refine isCoveringMap_exp.constOn_of_comp isPreconnected_Icc hm ?_
    (left_mem_Icc.2 hab) (right_mem_Icc.2 hab)
  intro x hx y hy
  exact Subtype.ext (by simp [h1 x hx, h1 y hy])

theorem bb_lift_loop (G : ℂ → ℂ) (hG : ContinuousOn G (closedBall 0 1))
    (hG0 : ∀ z ∈ closedBall (0 : ℂ) 1, G z ≠ 0) :
    ∃ ℓ : ℝ → ℂ, Continuous ℓ ∧
      (∀ t ∈ Icc (0 : ℝ) 1, exp (ℓ t) = G (exp (↑(2 * π * t) * I))) ∧ ℓ 1 = ℓ 0 := by
  let e : unitInterval × unitInterval → ℂ := fun p => ((p.1 : ℝ) : ℂ) * exp (↑(2 * π * (p.2 : ℝ)) * I)
  have he_cont : Continuous e := by fun_prop
  have he_mem : ∀ p, e p ∈ closedBall (0 : ℂ) 1 := by
    intro p
    simp only [e, mem_closedBall_zero_iff, norm_mul, norm_exp_ofReal_mul_I, mul_one,
      Complex.norm_real, Real.norm_eq_abs]
    rw [abs_of_nonneg p.1.2.1]; exact p.1.2.2
  let H : C(unitInterval × unitInterval, {z : ℂ // z ≠ 0}) :=
    ⟨fun p => ⟨G (e p), hG0 _ (he_mem p)⟩,
      (hG.comp_continuous he_cont he_mem).subtype_mk _⟩
  let f : C(unitInterval, ℂ) := ContinuousMap.const _ (log (G 0))
  have H_0 : ∀ a, H (0, a) = (fun z : ℂ ↦ (⟨_, z.exp_ne_zero⟩ : {z : ℂ // z ≠ 0})) (f a) := by
    intro a
    apply Subtype.ext
    simp only [H, f, e, ContinuousMap.coe_mk, ContinuousMap.const_apply, Set.Icc.coe_zero,
      Complex.ofReal_zero, zero_mul]
    rw [exp_log (hG0 0 (by simp))]
  let L := isCoveringMap_exp.liftHomotopy H f H_0
  have hL : ∀ p, exp (L p) = G (e p) := by
    intro p
    have := congrFun (isCoveringMap_exp.liftHomotopy_lifts H f H_0) p
    exact congrArg Subtype.val this
  have hL0 : ∀ a, L (0, a) = log (G 0) := fun a => isCoveringMap_exp.liftHomotopy_zero H f H_0 a
  -- the difference across the seam is constant in s
  have hd : ∀ s : unitInterval, L (s, 1) = L (s, 0) := by
    have hc : Continuous fun s : unitInterval => L (s, 1) - L (s, 0) := by fun_prop
    have h1 : ∀ s : unitInterval, e (s, 1) = e (s, 0) := by
      intro s
      simp only [e, Set.Icc.coe_one, Set.Icc.coe_zero, mul_one, mul_zero, Complex.ofReal_zero,
        zero_mul, Complex.exp_zero]
      rw [show (↑(2 * π) : ℂ) * I = 2 * π * I by push_cast; ring, exp_two_pi_mul_I, mul_one]
    have key := isCoveringMap_exp.const_of_comp hc (fun a a' => by
      apply Subtype.ext
      simp only [Complex.exp_sub, hL]
      rw [h1 a, h1 a', div_self (hG0 _ (he_mem _)), div_self (hG0 _ (he_mem _))])
    intro s
    have := key s 0
    simp only [hL0, sub_self] at this
    exact sub_eq_zero.1 this
  refine ⟨fun t => L (1, projIcc 0 1 zero_le_one t), by fun_prop, ?_, ?_⟩
  · intro t ht
    simp only [projIcc_of_mem _ ht]
    rw [hL]
    simp [e]
  · simp only [projIcc_right, projIcc_left]
    exact hd 1

theorem bb_norm_circle (t : ℝ) : ‖exp (↑(2 * π * t) * I)‖ = 1 := norm_exp_ofReal_mul_I _

theorem bb_no_slit_map (G : ℂ → ℂ) (hG : ContinuousOn G (closedBall 0 1))
    (hG0 : ∀ z ∈ closedBall (0 : ℂ) 1, G z ≠ 0)
    (hslit : ∀ z : ℂ, ‖z‖ = 1 → G z / z ∈ slitPlane) : False := by
  obtain ⟨ℓ, hℓc, hℓ, hℓ1⟩ := bb_lift_loop G hG hG0
  set γ : ℝ → ℂ := fun t => exp (↑(2 * π * t) * I) with hγ
  have hγc : Continuous γ := by fun_prop
  have hγ0 : ∀ t, γ t ≠ 0 := fun t => Complex.exp_ne_zero _
  have hγmem : ∀ t, γ t ∈ closedBall (0 : ℂ) 1 := fun t => by
    rw [mem_closedBall_zero_iff]; exact (bb_norm_circle t).le
  have hℓ' : ∀ t ∈ Icc (0 : ℝ) 1, exp (ℓ t) = G (γ t) := hℓ
  let m : ℝ → ℂ := fun t => ℓ t - ↑(2 * π * t) * I - log (G (γ t) / γ t)
  have hw : ContinuousOn (fun t => G (γ t) / γ t) (Icc 0 1) :=
    ((hG.comp_continuous hγc hγmem).div hγc hγ0).continuousOn
  have hm : ContinuousOn m (Icc 0 1) := by
    refine (hℓc.continuousOn.sub (by fun_prop)).sub (hw.clog fun t _ => hslit _ (bb_norm_circle t))
  have h1 : ∀ t ∈ Icc (0 : ℝ) 1, exp (m t) = 1 := by
    intro t ht
    have hne : G (γ t) / γ t ≠ 0 := div_ne_zero (hG0 _ (hγmem t)) (hγ0 t)
    simp only [m]
    rw [Complex.exp_sub, Complex.exp_sub, hℓ' t ht, exp_log hne]
    exact div_self hne
  have := bb_exp_const m zero_le_one hm h1
  simp only [m, hℓ1, γ] at this
  have e1 : exp (↑(2 * π * (1:ℝ)) * I) = exp (↑(2 * π * (0:ℝ)) * I) := by
    rw [show (↑(2 * π * (1:ℝ)) : ℂ) * I = 2 * π * I by push_cast; ring, exp_two_pi_mul_I]
    simp
  rw [e1] at this
  push_cast at this
  exact two_pi_I_ne_zero (by linear_combination this)

theorem bb_no_odd_map (G : ℂ → ℂ) (hG : ContinuousOn G (closedBall 0 1))
    (hG0 : ∀ z ∈ closedBall (0 : ℂ) 1, G z ≠ 0)
    (hodd : ∀ z : ℂ, ‖z‖ = 1 → G (-z) = - G z) : False := by
  obtain ⟨ℓ, hℓc, hℓ, hℓ1⟩ := bb_lift_loop G hG hG0
  set γ : ℝ → ℂ := fun t => exp (↑(2 * π * t) * I) with hγ
  have hγmem : ∀ t, γ t ∈ closedBall (0 : ℂ) 1 := fun t => by
    rw [mem_closedBall_zero_iff]; exact (bb_norm_circle t).le
  have hℓ' : ∀ t ∈ Icc (0 : ℝ) 1, exp (ℓ t) = G (γ t) := hℓ
  have hhalf : ∀ t, γ (t + 1/2) = - γ t := by
    intro t
    simp only [γ]
    rw [show (↑(2 * π * (t + 1/2)) : ℂ) * I = ↑(2 * π * t) * I + π * I by push_cast; ring,
      Complex.exp_add, exp_pi_mul_I]
    ring
  let m : ℝ → ℂ := fun t => ℓ (t + 1/2) - ℓ t - π * I
  have hm : ContinuousOn m (Icc 0 (1/2)) := by
    refine Continuous.continuousOn ?_
    fun_prop
  have h1 : ∀ t ∈ Icc (0 : ℝ) (1/2), exp (m t) = 1 := by
    intro t ht
    have ht1 : t ∈ Icc (0:ℝ) 1 := ⟨ht.1, by linarith [ht.2]⟩
    have ht2 : t + 1/2 ∈ Icc (0:ℝ) 1 := ⟨by linarith [ht.1], by linarith [ht.2]⟩
    simp only [m]
    rw [Complex.exp_sub, Complex.exp_sub, hℓ' t ht1, hℓ' _ ht2, exp_pi_mul_I, hhalf,
      hodd (γ t) (bb_norm_circle t), neg_div, div_self (hG0 _ (hγmem t))]
    norm_num
  have hconst := bb_exp_const m (by norm_num) hm h1
  obtain ⟨n, hn⟩ := Complex.exp_eq_one_iff.1 (h1 0 ⟨le_refl _, by norm_num⟩)
  simp only [m] at hconst hn
  norm_num at hconst hn
  rw [hℓ1] at hconst
  have key : ((2 * n + 1 : ℤ) : ℂ) * (2 * π * I) = 0 := by
    push_cast
    linear_combination -2 * hn + hconst
  rcases mul_eq_zero.1 key with h | h
  · have : (2 * n + 1 : ℤ) = 0 := by exact_mod_cast h
    omega
  · exact two_pi_I_ne_zero h

theorem bb_one_sub_mem_slit (u : ℂ) (hu : ‖u‖ ≤ 1) (h1 : u ≠ 1) : 1 - u ∈ slitPlane := by
  rw [mem_slitPlane_iff, sub_re, sub_im, one_re, one_im]
  by_contra hcon
  push Not at hcon
  have := Complex.re_le_norm u
  exact h1 (Complex.ext (by simp; linarith [hcon.1]) (by simp; linarith [hcon.2]))

/-- The point of the upper hemisphere of `S²` lying over `z` in the unit disc. -/
noncomputable def bbLift (z : ℂ) : EuclideanSpace ℝ (Fin 3) :=
  WithLp.toLp 2 ![z.re, z.im, √(1 - ‖z‖ ^ 2)]

theorem bbLift_continuous : Continuous bbLift := by
  unfold bbLift
  refine (PiLp.continuous_toLp 2 _).comp ?_
  refine continuous_pi fun i => ?_
  fin_cases i <;> simp <;> fun_prop

theorem bbLift_mem (z : ℂ) (hz : z ∈ closedBall (0 : ℂ) 1) :
    bbLift z ∈ sphere (0 : EuclideanSpace ℝ (Fin 3)) 1 := by
  rw [mem_closedBall_zero_iff] at hz
  have h0 : 0 ≤ 1 - ‖z‖ ^ 2 := by nlinarith [norm_nonneg z]
  rw [mem_sphere_zero_iff_norm, EuclideanSpace.norm_eq, Fin.sum_univ_three]
  simp only [bbLift, Real.norm_eq_abs, sq_abs]
  simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_two,
    Matrix.head_cons, Matrix.tail_cons, Real.sq_sqrt h0]
  have hn : ‖z‖ ^ 2 = z.re ^ 2 + z.im ^ 2 := by
    rw [Complex.sq_norm, Complex.normSq_apply]; ring
  rw [hn, show z.re ^ 2 + z.im ^ 2 + (1 - (z.re ^ 2 + z.im ^ 2)) = 1 by ring, Real.sqrt_one]

theorem bbLift_neg (z : ℂ) (hz : ‖z‖ = 1) : bbLift (-z) = - bbLift z := by
  ext i
  fin_cases i <;> simp [bbLift, hz]

end helpers

#print axioms bb_exp_const
#print axioms bb_lift_loop
#print axioms bb_norm_circle
#print axioms bb_no_slit_map
#print axioms bb_no_odd_map
#print axioms bb_one_sub_mem_slit
#print axioms bbLift_continuous
#print axioms bbLift_mem
#print axioms bbLift_neg

/-- Brouwer's fixed-point theorem in the plane: every continuous map of the closed disc
`D²` into itself leaves some point where it was. -/
theorem brouwer_fixed_point_disc (f : EuclideanSpace ℝ (Fin 2) → EuclideanSpace ℝ (Fin 2))
    (hf : ContinuousOn f (closedBall 0 1)) (hmaps : MapsTo f (closedBall 0 1) (closedBall 0 1)) :
    ∃ x ∈ closedBall (0 : EuclideanSpace ℝ (Fin 2)) 1, f x = x := by
  by_contra hno
  push Not at hno
  set φ := Complex.orthonormalBasisOneI.repr
  have hφ : ∀ z : ℂ, z ∈ closedBall (0 : ℂ) 1 → φ z ∈ closedBall 0 1 := by
    intro z hz; simpa using hz
  refine bb_no_slit_map (fun z => z - φ.symm (f (φ z))) ?_ ?_ ?_
  · exact continuousOn_id.sub
      (φ.symm.continuous.comp_continuousOn (hf.comp φ.continuous.continuousOn hφ))
  · intro z hz h
    apply hno (φ z) (hφ z hz)
    rw [sub_eq_zero] at h
    conv_rhs => rw [h]
    simp
  · intro z hz
    have hz0 : z ≠ 0 := by rintro rfl; simp at hz
    have hw : ‖φ.symm (f (φ z))‖ ≤ 1 := by
      rw [LinearIsometryEquiv.norm_map]
      simpa using hmaps (hφ z (by simp [hz]))
    rw [sub_div, div_self hz0]
    refine bb_one_sub_mem_slit _ (by rw [norm_div, hz, div_one]; exact hw) ?_
    intro h1
    rw [div_eq_one_iff_eq hz0] at h1
    apply hno (φ z) (hφ z (by simp [hz]))
    exact (φ.apply_symm_apply _).symm.trans (congrArg φ h1)

/-- No retraction: there is no continuous map of the closed disc `D²` onto its rim circle `S¹`
that keeps every rim point still. -/
theorem no_retraction_disc_to_circle :
    ¬ ∃ r : EuclideanSpace ℝ (Fin 2) → EuclideanSpace ℝ (Fin 2),
      ContinuousOn r (closedBall 0 1) ∧ MapsTo r (closedBall 0 1) (sphere 0 1) ∧
      ∀ x ∈ sphere (0 : EuclideanSpace ℝ (Fin 2)) 1, r x = x := by
  rintro ⟨r, hr, hmaps, hfix⟩
  set φ := Complex.orthonormalBasisOneI.repr
  have hφ : ∀ z : ℂ, z ∈ closedBall (0 : ℂ) 1 → φ z ∈ closedBall 0 1 := by
    intro z hz; simpa using hz
  refine bb_no_slit_map (fun z => φ.symm (r (φ z))) ?_ ?_ ?_
  · exact φ.symm.continuous.comp_continuousOn (hr.comp φ.continuous.continuousOn hφ)
  · intro z hz h
    have h1 := hmaps (hφ z hz)
    rw [mem_sphere_zero_iff_norm] at h1
    have h2 : ‖φ.symm (r (φ z))‖ = 1 := by rw [LinearIsometryEquiv.norm_map]; exact h1
    rw [h, norm_zero] at h2
    exact zero_ne_one h2
  · intro z hz
    have hz0 : z ≠ 0 := by rintro rfl; simp at hz
    rw [hfix _ (by simpa using hz), LinearIsometryEquiv.symm_apply_apply, div_self hz0]
    exact Complex.one_mem_slitPlane

/-- Borsuk-Ulam on the ordinary sphere: two continuous readings on `S²` (a map into `ℝ²`)
agree at some pair of opposite points `x` and `-x`. -/
theorem borsuk_ulam_sphere_two (g : EuclideanSpace ℝ (Fin 3) → EuclideanSpace ℝ (Fin 2))
    (hg : ContinuousOn g (sphere 0 1)) :
    ∃ x ∈ sphere (0 : EuclideanSpace ℝ (Fin 3)) 1, g x = g (-x) := by
  by_contra hno
  push Not at hno
  set φ := Complex.orthonormalBasisOneI.repr
  have hneg : ∀ z ∈ closedBall (0 : ℂ) 1, -bbLift z ∈ sphere (0 : EuclideanSpace ℝ (Fin 3)) 1 :=
    fun z hz => by simpa using bbLift_mem z hz
  refine bb_no_odd_map (fun z => φ.symm (g (bbLift z) - g (-bbLift z))) ?_ ?_ ?_
  · refine φ.symm.continuous.comp_continuousOn (ContinuousOn.sub ?_ ?_)
    · exact hg.comp bbLift_continuous.continuousOn bbLift_mem
    · exact hg.comp bbLift_continuous.neg.continuousOn hneg
  · intro z hz h
    apply hno _ (bbLift_mem z hz)
    rw [LinearIsometryEquiv.map_eq_zero_iff, sub_eq_zero] at h
    exact h
  · intro z hz
    rw [bbLift_neg z hz, neg_neg, ← map_neg, neg_sub]

-- The sandwich's slices by the shoelace formula (twice the area, in cm²):
-- toast (0,0), (10,0), (10,10), (0,10) has area 100; cheese (13,2), (21,4), (15,11) has area 34.
example : ((0 * 0 - 10 * 0) + (10 * 10 - 10 * 0) + (10 * 10 - 0 * 10) + (0 * 0 - 0 * 10) : ℤ) = 2 * 100 := by
  norm_num
example : ((13 * 4 - 21 * 2) + (21 * 11 - 15 * 4) + (15 * 2 - 13 * 11) : ℤ) = 2 * 34 := by
  norm_num

#print axioms brouwer_fixed_point_disc
#print axioms no_retraction_disc_to_circle
#print axioms borsuk_ulam_sphere_two
