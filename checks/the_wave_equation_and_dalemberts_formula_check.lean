-- The wave equation: d'Alembert's formula solves u_tt = c^2 u_xx on the whole line from a starting shape and velocity, it is the only solution, every solution is a right-moving plus a left-moving profile, and the height at a point depends only on starting data within distance ct.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Prod

open scoped Topology

/-- A function with derivative zero on the interval between `0` and `s` takes the same value
at `s` and at `0`. -/
lemma wave_aux_const {φ φ' : ℝ → ℝ} (hφ : ∀ r, HasDerivAt φ (φ' r) r) (s : ℝ)
    (h0 : ∀ r ∈ Set.uIcc 0 s, φ' r = 0) : φ s = φ 0 := by
  have hcont : Continuous φ := continuous_iff_continuousAt.2 fun r => (hφ r).continuousAt
  rcases le_total 0 s with hs | hs
  · refine constant_of_has_deriv_right_zero (a := 0) (b := s) hcont.continuousOn
      (fun r hr => ?_) s ⟨hs, le_rfl⟩
    have := h0 r (by rw [Set.uIcc_of_le hs]; exact Set.Ico_subset_Icc_self hr)
    rw [← this]; exact (hφ r).hasDerivWithinAt
  · refine (constant_of_has_deriv_right_zero (a := s) (b := 0) hcont.continuousOn
      (fun r hr => ?_) 0 ⟨hs, le_rfl⟩).symm
    have := h0 r (by rw [Set.uIcc_of_ge hs]; exact Set.Ico_subset_Icc_self hr)
    rw [← this]; exact (hφ r).hasDerivWithinAt

lemma wave_hasDerivAt1 {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) {γ : ℝ → ℝ × ℝ} {γ' : ℝ × ℝ}
    {s : ℝ} (hγ : HasDerivAt γ γ' s) :
    HasDerivAt (fun s => W (γ s)) (fderiv ℝ W (γ s) γ') s :=
  ((hW.differentiable (by norm_num)) (γ s)).hasFDerivAt.comp_hasDerivAt s hγ

lemma wave_hasDerivAt2 {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) {γ : ℝ → ℝ × ℝ} {γ' : ℝ × ℝ}
    {s : ℝ} (hγ : HasDerivAt γ γ' s) (v : ℝ × ℝ) :
    HasDerivAt (fun s => fderiv ℝ W (γ s) v) (fderiv ℝ (fderiv ℝ W) (γ s) γ' v) s := by
  have hD : ContDiff ℝ 1 (fderiv ℝ W) := hW.fderiv_right (by norm_num)
  have h1 := ((hD.differentiable (by norm_num)) (γ s)).hasFDerivAt.comp_hasDerivAt s hγ
  have h2 := h1.clm_apply (hasDerivAt_const s v)
  simpa using h2

lemma wave_symm {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) (p v w : ℝ × ℝ) :
    fderiv ℝ (fderiv ℝ W) p v w = fderiv ℝ (fderiv ℝ W) p w v :=
  hW.contDiffAt.isSymmSndFDerivAt (by simp) v w

lemma wave_dt (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2)) (x t : ℝ) :
    HasDerivAt (fun t => w x t) (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (x, t) (0, 1)) t :=
  wave_hasDerivAt1 hw (HasDerivAt.prodMk (hasDerivAt_const t x) (hasDerivAt_id' t))

lemma wave_dx (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2)) (x t : ℝ) :
    HasDerivAt (fun x => w x t) (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (x, t) (1, 0)) x :=
  wave_hasDerivAt1 hw (HasDerivAt.prodMk (hasDerivAt_id' x) (hasDerivAt_const x t))

lemma wave_dtt (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2)) (x t : ℝ) :
    deriv (fun t => deriv (fun t => w x t) t) t =
      fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2)) (x, t) (0, 1) (0, 1) := by
  have e : (fun t => deriv (fun t => w x t) t) =
      fun t => fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (x, t) (0, 1) :=
    funext fun t => (wave_dt w hw x t).deriv
  rw [e]
  exact (wave_hasDerivAt2 hw (HasDerivAt.prodMk (hasDerivAt_const t x) (hasDerivAt_id' t)) (0, 1)).deriv

lemma wave_dxx (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2)) (x t : ℝ) :
    deriv (fun x => deriv (fun x => w x t) x) x =
      fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2)) (x, t) (1, 0) (1, 0) := by
  have e : (fun x => deriv (fun x => w x t) x) =
      fun x => fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (x, t) (1, 0) :=
    funext fun x => (wave_dx w hw x t).deriv
  rw [e]
  exact (wave_hasDerivAt2 hw (HasDerivAt.prodMk (hasDerivAt_id' x) (hasDerivAt_const x t)) (1, 0)).deriv

/-- `u_t - c u_x` is constant along the right-moving lines `x - ct = const`. -/
lemma wave_char_a {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) (c x₁ s : ℝ)
    (hwave : ∀ r ∈ Set.uIcc 0 s, fderiv ℝ (fderiv ℝ W) (x₁ + c * r, r) (0, 1) (0, 1) =
        c ^ 2 * fderiv ℝ (fderiv ℝ W) (x₁ + c * r, r) (1, 0) (1, 0)) :
    fderiv ℝ W (x₁ + c * s, s) (0, 1) - c * fderiv ℝ W (x₁ + c * s, s) (1, 0) =
      fderiv ℝ W (x₁, 0) (0, 1) - c * fderiv ℝ W (x₁, 0) (1, 0) := by
  have hγ : ∀ r, HasDerivAt (fun r : ℝ => ((x₁ + c * r, r) : ℝ × ℝ)) ((c, 1) : ℝ × ℝ) r := by
    intro r
    have := HasDerivAt.prodMk (HasDerivAt.const_add x₁ (HasDerivAt.const_mul c (hasDerivAt_id' r))) (hasDerivAt_id' r)
    simpa using this
  have key := wave_aux_const
    (φ := fun r => fderiv ℝ W (x₁ + c * r, r) (0, 1) - c * fderiv ℝ W (x₁ + c * r, r) (1, 0))
    (φ' := fun r => fderiv ℝ (fderiv ℝ W) (x₁ + c * r, r) (c, 1) (0, 1) -
      c * fderiv ℝ (fderiv ℝ W) (x₁ + c * r, r) (c, 1) (1, 0))
    (fun r => HasDerivAt.sub (wave_hasDerivAt2 hW (hγ r) (0, 1))
      (HasDerivAt.const_mul c (wave_hasDerivAt2 hW (hγ r) (1, 0)))) s
    (fun r hr => by
      have e : ((c, 1) : ℝ × ℝ) = c • ((1 : ℝ), (0 : ℝ)) + ((0 : ℝ), (1 : ℝ)) := by
        ext <;> simp
      have hs := wave_symm hW (x₁ + c * r, r) (1, 0) (0, 1)
      have hwr := hwave r hr
      simp only [e, map_add, map_smul, add_apply,
        smul_apply, smul_eq_mul]
      linear_combination c * hs + hwr)
  simp only [mul_zero, add_zero] at key
  exact key

/-- `u_t + c u_x` is constant along the left-moving lines `x + ct = const`. -/
lemma wave_char_b {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) (c x₁ s : ℝ)
    (hwave : ∀ r ∈ Set.uIcc 0 s, fderiv ℝ (fderiv ℝ W) (x₁ - c * r, r) (0, 1) (0, 1) =
        c ^ 2 * fderiv ℝ (fderiv ℝ W) (x₁ - c * r, r) (1, 0) (1, 0)) :
    fderiv ℝ W (x₁ - c * s, s) (0, 1) + c * fderiv ℝ W (x₁ - c * s, s) (1, 0) =
      fderiv ℝ W (x₁, 0) (0, 1) + c * fderiv ℝ W (x₁, 0) (1, 0) := by
  have hγ : ∀ r, HasDerivAt (fun r : ℝ => ((x₁ - c * r, r) : ℝ × ℝ)) ((-c, 1) : ℝ × ℝ) r := by
    intro r
    have := HasDerivAt.prodMk (HasDerivAt.const_sub x₁ (HasDerivAt.const_mul c (hasDerivAt_id' r))) (hasDerivAt_id' r)
    simpa using this
  have key := wave_aux_const
    (φ := fun r => fderiv ℝ W (x₁ - c * r, r) (0, 1) + c * fderiv ℝ W (x₁ - c * r, r) (1, 0))
    (φ' := fun r => fderiv ℝ (fderiv ℝ W) (x₁ - c * r, r) (-c, 1) (0, 1) +
      c * fderiv ℝ (fderiv ℝ W) (x₁ - c * r, r) (-c, 1) (1, 0))
    (fun r => HasDerivAt.add (wave_hasDerivAt2 hW (hγ r) (0, 1))
      (HasDerivAt.const_mul c (wave_hasDerivAt2 hW (hγ r) (1, 0)))) s
    (fun r hr => by
      have e : ((-c, 1) : ℝ × ℝ) = (-c) • ((1 : ℝ), (0 : ℝ)) + ((0 : ℝ), (1 : ℝ)) := by
        ext <;> simp
      have hs := wave_symm hW (x₁ - c * r, r) (1, 0) (0, 1)
      have hwr := hwave r hr
      simp only [e, map_add, map_smul, add_apply,
        smul_apply, smul_eq_mul]
      linear_combination -c * hs + hwr)
  simp only [mul_zero, sub_zero] at key
  exact key

/-- The time derivative of a solution is determined by the starting data along the two
characteristic lines through the point. -/
lemma wave_ut_formula (c : ℝ) (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2))
    (x t : ℝ)
    (hwave : ∀ x' t', t' ∈ Set.uIcc 0 t → deriv (fun t => deriv (fun t => w x' t) t) t' =
        c ^ 2 * deriv (fun x => deriv (fun x => w x t') x) x') :
    deriv (fun t => w x t) t =
      ((deriv (fun s => w (x - c * t) s) 0 - c * deriv (fun y => w y 0) (x - c * t)) +
       (deriv (fun s => w (x + c * t) s) 0 + c * deriv (fun y => w y 0) (x + c * t))) / 2 := by
  have hw2 : ∀ x' t', t' ∈ Set.uIcc 0 t →
      fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2)) (x', t') (0, 1) (0, 1) =
        c ^ 2 * fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2)) (x', t') (1, 0) (1, 0) := by
    intro x' t' ht'
    have := hwave x' t' ht'
    rwa [wave_dtt w hw, wave_dxx w hw] at this
  have ha := wave_char_a hw c (x - c * t) t (fun r hr => hw2 _ r hr)
  have hb := wave_char_b hw c (x + c * t) t (fun r hr => hw2 _ r hr)
  rw [show x - c * t + c * t = x by ring] at ha
  rw [show x + c * t - c * t = x by ring] at hb
  rw [(wave_dt w hw x t).deriv, (wave_dt w hw (x - c * t) 0).deriv,
    (wave_dt w hw (x + c * t) 0).deriv, (wave_dx w hw (x - c * t) 0).deriv,
    (wave_dx w hw (x + c * t) 0).deriv]
  linear_combination (ha + hb) / 2

/-- Uniqueness: two solutions with the same starting data agree, as long as the wave equation
holds for both at every time between `0` and `t`. -/
lemma wave_uniq_gen (c : ℝ) (u v : ℝ → ℝ → ℝ) (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hv : ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2)) (x t : ℝ)
    (hwu : ∀ x' t', t' ∈ Set.uIcc 0 t → deriv (fun t => deriv (fun t => u x' t) t) t' =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t') x) x')
    (hwv : ∀ x' t', t' ∈ Set.uIcc 0 t → deriv (fun t => deriv (fun t => v x' t) t) t' =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t') x) x')
    (h0 : ∀ y, u y 0 = v y 0)
    (h1 : ∀ y, deriv (fun t => u y t) 0 = deriv (fun t => v y t) 0) :
    u x t = v x t := by
  have hd0 : ∀ z, deriv (fun y => u y 0) z = deriv (fun y => v y 0) z := by
    intro z; rw [show (fun y => u y 0) = (fun y => v y 0) from funext h0]
  have key := wave_aux_const (φ := fun r => u x r - v x r)
    (φ' := fun r => fderiv ℝ (fun p : ℝ × ℝ => u p.1 p.2) (x, r) (0, 1) -
      fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) (x, r) (0, 1))
    (fun r => HasDerivAt.sub (wave_dt u hu x r) (wave_dt v hv x r)) t
    (fun r hr => by
      have hsub : Set.uIcc 0 r ⊆ Set.uIcc 0 t := Set.uIcc_subset_uIcc Set.left_mem_uIcc hr
      have eu := wave_ut_formula c u hu x r (fun x' t' ht' => hwu x' t' (hsub ht'))
      have ev := wave_ut_formula c v hv x r (fun x' t' ht' => hwv x' t' (hsub ht'))
      rw [(wave_dt u hu x r).deriv] at eu
      rw [(wave_dt v hv x r).deriv] at ev
      show _ - _ = (0 : ℝ)
      rw [sub_eq_zero, eu, ev, h1 (x - c * r), h1 (x + c * r), hd0 (x - c * r),
        hd0 (x + c * r)])
  rw [h0 x, sub_self, sub_eq_zero] at key
  exact key

/-- Domain of dependence (same statement as `wave_domain_of_dependence`). -/
lemma wave_dod_aux (c : ℝ) (hc : 0 < c) (u v : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hv : ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2))
    (hwu : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x)
    (hwv : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => v x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x)
    (x₀ t₀ : ℝ) (ht₀ : 0 ≤ t₀)
    (hshape : ∀ y ∈ Set.Icc (x₀ - c * t₀) (x₀ + c * t₀), u y 0 = v y 0)
    (hvel : ∀ y ∈ Set.Icc (x₀ - c * t₀) (x₀ + c * t₀),
        deriv (fun t => u y t) 0 = deriv (fun t => v y t) 0) :
    u x₀ t₀ = v x₀ t₀ := by
  have hd0 : ∀ z ∈ Set.Ioo (x₀ - c * t₀) (x₀ + c * t₀),
      deriv (fun y => u y 0) z = deriv (fun y => v y 0) z := by
    intro z hz
    apply Filter.EventuallyEq.deriv_eq
    filter_upwards [Ioo_mem_nhds hz.1 hz.2] with y hy
    exact hshape y (Set.Ioo_subset_Icc_self hy)
  have hcont : ContinuousOn (fun r => u x₀ r - v x₀ r) (Set.Icc 0 t₀) :=
    (continuous_iff_continuousAt.2 fun r =>
      (HasDerivAt.sub (wave_dt u hu x₀ r) (wave_dt v hv x₀ r)).continuousAt).continuousOn
  have hct : 0 ≤ c * t₀ := mul_nonneg hc.le ht₀
  have key := constant_of_has_deriv_right_zero hcont (fun r hr => ?_) t₀ ⟨ht₀, le_rfl⟩
  · rw [hshape x₀ ⟨by linarith, by linarith⟩, sub_self, sub_eq_zero] at key
    exact key
  · have hd := HasDerivAt.sub (wave_dt u hu x₀ r) (wave_dt v hv x₀ r)
    have hr0 : 0 ≤ r := hr.1
    have hsub : ∀ t' ∈ Set.uIcc 0 r, 0 ≤ t' := by
      intro t' ht'; rw [Set.uIcc_of_le hr0] at ht'; exact ht'.1
    have eu := wave_ut_formula c u hu x₀ r (fun x' t' ht' => hwu x' t' (hsub t' ht'))
    have ev := wave_ut_formula c v hv x₀ r (fun x' t' ht' => hwv x' t' (hsub t' ht'))
    rw [(wave_dt u hu x₀ r).deriv] at eu
    rw [(wave_dt v hv x₀ r).deriv] at ev
    have hcr : c * r < c * t₀ := mul_lt_mul_of_pos_left hr.2 hc
    have hcr0 : 0 ≤ c * r := mul_nonneg hc.le hr0
    have m1 : x₀ - c * r ∈ Set.Ioo (x₀ - c * t₀) (x₀ + c * t₀) :=
      ⟨by linarith, by linarith⟩
    have m2 : x₀ + c * r ∈ Set.Ioo (x₀ - c * t₀) (x₀ + c * t₀) :=
      ⟨by linarith, by linarith⟩
    have hz : fderiv ℝ (fun p : ℝ × ℝ => u p.1 p.2) (x₀, r) (0, 1) -
        fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) (x₀, r) (0, 1) = 0 := by
      rw [sub_eq_zero, eu, ev, hvel _ (Set.Ioo_subset_Icc_self m1),
        hvel _ (Set.Ioo_subset_Icc_self m2), hd0 _ m1, hd0 _ m2]
    rw [hz] at hd
    exact hd.hasDerivWithinAt

/-- A twice-differentiable function of the sliding variables. -/
lemma wave_prof_contDiff {A B : ℝ → ℝ} (hA : ContDiff ℝ 2 A) (hB : ContDiff ℝ 2 B) (c : ℝ) :
    ContDiff ℝ 2 (fun p : ℝ × ℝ => A (p.1 - c * p.2) + B (p.1 + c * p.2)) :=
  (hA.comp (contDiff_fst.sub (contDiff_const.mul contDiff_snd))).add
    (hB.comp (contDiff_fst.add (contDiff_const.mul contDiff_snd)))

lemma wave_lin_t {A : ℝ → ℝ} (hA : Differentiable ℝ A) (c x t : ℝ) :
    HasDerivAt (fun t => A (x - c * t)) (deriv A (x - c * t) * (-c)) t := by
  have h1 : HasDerivAt (fun t => x - c * t) (-c) t := by
    simpa using HasDerivAt.const_sub x (HasDerivAt.const_mul c (hasDerivAt_id' t))
  exact (hA _).hasDerivAt.comp t h1

lemma wave_lin_t' {A : ℝ → ℝ} (hA : Differentiable ℝ A) (c x t : ℝ) :
    HasDerivAt (fun t => A (x + c * t)) (deriv A (x + c * t) * c) t := by
  have h1 : HasDerivAt (fun t => x + c * t) c t := by
    simpa using HasDerivAt.const_add x (HasDerivAt.const_mul c (hasDerivAt_id' t))
  exact (hA _).hasDerivAt.comp t h1

lemma wave_lin_x {A : ℝ → ℝ} (hA : Differentiable ℝ A) (c x t : ℝ) :
    HasDerivAt (fun x => A (x - c * t)) (deriv A (x - c * t)) x := by
  have h1 : HasDerivAt (fun x => x - c * t) 1 x := HasDerivAt.sub_const _ (hasDerivAt_id' x)
  have h2 := (hA _).hasDerivAt.comp x h1
  rw [mul_one] at h2
  exact h2

lemma wave_lin_x' {A : ℝ → ℝ} (hA : Differentiable ℝ A) (c x t : ℝ) :
    HasDerivAt (fun x => A (x + c * t)) (deriv A (x + c * t)) x := by
  have h1 : HasDerivAt (fun x => x + c * t) 1 x := HasDerivAt.add_const _ (hasDerivAt_id' x)
  have h2 := (hA _).hasDerivAt.comp x h1
  rw [mul_one] at h2
  exact h2

lemma wave_prof_dt {A B : ℝ → ℝ} (hA : Differentiable ℝ A) (hB : Differentiable ℝ B)
    (c x t : ℝ) :
    HasDerivAt (fun t => A (x - c * t) + B (x + c * t))
      (deriv A (x - c * t) * (-c) + deriv B (x + c * t) * c) t :=
  HasDerivAt.add (wave_lin_t hA c x t) (wave_lin_t' hB c x t)

lemma wave_d2 {A : ℝ → ℝ} (hA : ContDiff ℝ 2 A) : Differentiable ℝ (deriv A) := by
  have h : ContDiff ℝ (1 + 1) A := by norm_num; exact hA
  exact ((contDiff_succ_iff_deriv.1 h).2.2).differentiable (by norm_num)

/-- A sum of a right-moving and a left-moving profile solves the wave equation. -/
lemma wave_prof_wave {A B : ℝ → ℝ} (hA : ContDiff ℝ 2 A) (hB : ContDiff ℝ 2 B) (c x t : ℝ) :
    deriv (fun t => deriv (fun t => A (x - c * t) + B (x + c * t)) t) t =
      c ^ 2 * deriv (fun x => deriv (fun x => A (x - c * t) + B (x + c * t)) x) x := by
  have hA1 : Differentiable ℝ A := hA.differentiable (by norm_num)
  have hB1 : Differentiable ℝ B := hB.differentiable (by norm_num)
  have hA2 := wave_d2 hA
  have hB2 := wave_d2 hB
  have et : (fun t => deriv (fun t => A (x - c * t) + B (x + c * t)) t) =
      fun t => deriv A (x - c * t) * (-c) + deriv B (x + c * t) * c :=
    funext fun t => (wave_prof_dt hA1 hB1 c x t).deriv
  have ex : (fun x => deriv (fun x => A (x - c * t) + B (x + c * t)) x) =
      fun x => deriv A (x - c * t) + deriv B (x + c * t) :=
    funext fun x => (HasDerivAt.add (wave_lin_x hA1 c x t) (wave_lin_x' hB1 c x t)).deriv
  have h1 : HasDerivAt (fun t => deriv A (x - c * t) * (-c) + deriv B (x + c * t) * c)
      (deriv (deriv A) (x - c * t) * (-c) * (-c) + deriv (deriv B) (x + c * t) * c * c) t :=
    HasDerivAt.add (HasDerivAt.mul_const (wave_lin_t hA2 c x t) (-c))
      (HasDerivAt.mul_const (wave_lin_t' hB2 c x t) c)
  have h2 : HasDerivAt (fun x => deriv A (x - c * t) + deriv B (x + c * t))
      (deriv (deriv A) (x - c * t) + deriv (deriv B) (x + c * t)) x :=
    HasDerivAt.add (wave_lin_x hA2 c x t) (wave_lin_x' hB2 c x t)
  rw [et, ex, h1.deriv, h2.deriv]
  ring

/-- D'Alembert's integral formula, rewritten as a right-moving plus a left-moving profile. -/
lemma wave_dal_profile (c : ℝ) (hc : c ≠ 0) (f g : ℝ → ℝ) (hf : ContDiff ℝ 2 f)
    (hg : ContDiff ℝ 1 g) :
    ∃ A B : ℝ → ℝ, ContDiff ℝ 2 A ∧ ContDiff ℝ 2 B ∧
      (∀ x t, (f (x - c * t) + f (x + c * t)) / 2 +
          1 / (2 * c) * ∫ s in (x - c * t)..(x + c * t), g s = A (x - c * t) + B (x + c * t)) ∧
      (∀ y, A y + B y = f y) ∧
      (∀ y, deriv A y * (-c) + deriv B y * c = g y) := by
  obtain ⟨P, hP⟩ : ∃ P : ℝ → ℝ, P = fun y => ∫ s in (0 : ℝ)..y, g s := ⟨_, rfl⟩
  have hPd : ∀ y, HasDerivAt P (g y) y := by
    intro y; rw [hP]; exact (hg.continuous.integral_hasStrictDerivAt 0 y).hasDerivAt
  have hPc : ContDiff ℝ 2 P := by
    have h : ContDiff ℝ (1 + 1) P := by
      rw [contDiff_succ_iff_deriv]
      refine ⟨fun y => (hPd y).differentiableAt, by simp, ?_⟩
      rw [show deriv P = g from funext fun y => (hPd y).deriv]
      exact hg
    norm_num at h; exact h
  have hf1 : Differentiable ℝ f := hf.differentiable (by norm_num)
  refine ⟨fun y => f y / 2 - P y / (2 * c), fun y => f y / 2 + P y / (2 * c),
    (hf.div_const 2).sub (hPc.div_const _), (hf.div_const 2).add (hPc.div_const _), ?_, ?_, ?_⟩
  · intro x t
    have : ∫ s in (x - c * t)..(x + c * t), g s = P (x + c * t) - P (x - c * t) := by
      rw [hP]
      exact (intervalIntegral.integral_interval_sub_left
        (hg.continuous.intervalIntegrable _ _) (hg.continuous.intervalIntegrable _ _)).symm
    rw [this]
    field_simp
    ring
  · intro y; ring
  · intro y
    have dA : HasDerivAt (fun y => f y / 2 - P y / (2 * c)) (deriv f y / 2 - g y / (2 * c)) y :=
      HasDerivAt.sub ((hf1 y).hasDerivAt.div_const 2) ((hPd y).div_const _)
    have dB : HasDerivAt (fun y => f y / 2 + P y / (2 * c)) (deriv f y / 2 + g y / (2 * c)) y :=
      HasDerivAt.add ((hf1 y).hasDerivAt.div_const 2) ((hPd y).div_const _)
    rw [dA.deriv, dB.deriv]
    field_simp
    ring

#print axioms wave_aux_const
#print axioms wave_hasDerivAt1
#print axioms wave_hasDerivAt2
#print axioms wave_symm
#print axioms wave_dt
#print axioms wave_dx
#print axioms wave_dtt
#print axioms wave_dxx
#print axioms wave_char_a
#print axioms wave_char_b
#print axioms wave_ut_formula
#print axioms wave_uniq_gen
#print axioms wave_dod_aux
#print axioms wave_prof_contDiff
#print axioms wave_lin_t
#print axioms wave_lin_t'
#print axioms wave_lin_x
#print axioms wave_lin_x'
#print axioms wave_prof_dt
#print axioms wave_d2
#print axioms wave_prof_wave
#print axioms wave_dal_profile

/-- D'Alembert's formula. On a whole line with wave speed `c > 0`, take a starting shape `f`
that is twice continuously differentiable and a starting velocity `g` that is once continuously
differentiable. Then
`u(x,t) = (f(x - ct) + f(x + ct)) / 2 + (1 / 2c) ∫_{x-ct}^{x+ct} g(s) ds`
is twice continuously differentiable, solves the wave equation `u_tt = c^2 u_xx`, starts with
shape `f` and velocity `g`, and is the only such solution for `t ≥ 0`: any twice continuously
differentiable `v` solving the wave equation for `t ≥ 0` with the same starting shape and
velocity equals `u` at every `x` and every `t ≥ 0`. In particular, released from rest (`g = 0`)
the motion is two half-copies of `f`, one sliding each way. -/
theorem dalembert_formula (c : ℝ) (hc : 0 < c) (f g : ℝ → ℝ)
    (hf : ContDiff ℝ 2 f) (hg : ContDiff ℝ 1 g) :
    let u : ℝ → ℝ → ℝ := fun x t =>
      (f (x - c * t) + f (x + c * t)) / 2 + 1 / (2 * c) * ∫ s in (x - c * t)..(x + c * t), g s
    ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2) ∧
    (∀ x t, deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x) ∧
    (∀ x, u x 0 = f x) ∧
    (∀ x, deriv (fun t => u x t) 0 = g x) ∧
    (∀ v : ℝ → ℝ → ℝ, ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2) →
      (∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => v x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x) →
      (∀ x, v x 0 = f x) →
      (∀ x, deriv (fun t => v x t) 0 = g x) →
      ∀ x t, 0 ≤ t → v x t = u x t) := by
  intro u
  obtain ⟨A, B, hA, hB, hrep, hsum, hder⟩ := wave_dal_profile c hc.ne' f g hf hg
  have hA1 : Differentiable ℝ A := hA.differentiable (by norm_num)
  have hB1 : Differentiable ℝ B := hB.differentiable (by norm_num)
  have hu : u = fun x t => A (x - c * t) + B (x + c * t) := by
    funext x t; exact hrep x t
  rw [hu]
  refine ⟨wave_prof_contDiff hA hB c, fun x t => wave_prof_wave hA hB c x t, fun x => ?_,
    fun x => ?_, ?_⟩
  · simp [hsum]
  · rw [(wave_prof_dt hA1 hB1 c x 0).deriv]
    simpa using hder x
  · intro v hv hwv hv0 hv1 x t ht
    apply wave_uniq_gen c v (fun x t => A (x - c * t) + B (x + c * t)) hv
      (wave_prof_contDiff hA hB c) x t
    · intro x' t' ht'
      apply hwv
      rw [Set.uIcc_of_le ht] at ht'
      exact ht'.1
    · intro x' t' _
      exact wave_prof_wave hA hB c x' t'
    · intro y
      simp [hv0, hsum]
    · intro y
      rw [hv1, (wave_prof_dt hA1 hB1 c y 0).deriv]
      simpa using (hder y).symm

/-- Every motion is one shape sliding right plus one shape sliding left. If `u` is twice
continuously differentiable on the whole `(x, t)` plane and solves `u_tt = c^2 u_xx` with
`c > 0`, then there are twice continuously differentiable profiles `F` and `G` with
`u(x,t) = F(x - ct) + G(x + ct)` everywhere. -/
theorem wave_solution_eq_sliding_profiles (c : ℝ) (hc : 0 < c) (u : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hwave : ∀ x t, deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x) :
    ∃ F G : ℝ → ℝ, ContDiff ℝ 2 F ∧ ContDiff ℝ 2 G ∧
      ∀ x t, u x t = F (x - c * t) + G (x + c * t) := by
  have hf : ContDiff ℝ 2 (fun y => u y 0) := hu.comp (contDiff_id.prodMk contDiff_const)
  have hg : ContDiff ℝ 1 (fun y => deriv (fun t => u y t) 0) := by
    have e : (fun y => deriv (fun t => u y t) 0) =
        fun y => fderiv ℝ (fun p : ℝ × ℝ => u p.1 p.2) (y, 0) (0, 1) :=
      funext fun y => (wave_dt u hu y 0).deriv
    rw [e]
    have hD : ContDiff ℝ 1 (fderiv ℝ (fun p : ℝ × ℝ => u p.1 p.2)) :=
      hu.fderiv_right (by norm_num)
    exact (hD.comp (contDiff_id.prodMk contDiff_const)).clm_apply contDiff_const
  obtain ⟨A, B, hA, hB, -, hsum, hder⟩ := wave_dal_profile c hc.ne' _ _ hf hg
  have hA1 : Differentiable ℝ A := hA.differentiable (by norm_num)
  have hB1 : Differentiable ℝ B := hB.differentiable (by norm_num)
  refine ⟨A, B, hA, hB, fun x t => ?_⟩
  exact wave_uniq_gen c u (fun x t => A (x - c * t) + B (x + c * t)) hu
    (wave_prof_contDiff hA hB c) x t (fun x' t' _ => hwave x' t')
    (fun x' t' _ => wave_prof_wave hA hB c x' t')
    (fun y => by simp [hsum])
    (fun y => by
      rw [(wave_prof_dt hA1 hB1 c y 0).deriv]
      simpa using (hder y).symm)

/-- Domain of dependence. Take two twice continuously differentiable solutions of
`u_tt = c^2 u_xx` (`c > 0`) for `t ≥ 0`. If their starting shapes and starting velocities agree
on the interval from `x₀ - c t₀` to `x₀ + c t₀`, with `t₀ ≥ 0`, then the two heights agree at
position `x₀` and time `t₀`: a point feels only the starting data within distance `c t₀`. -/
theorem wave_domain_of_dependence (c : ℝ) (hc : 0 < c) (u v : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hv : ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2))
    (hwu : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x)
    (hwv : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => v x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x)
    (x₀ t₀ : ℝ) (ht₀ : 0 ≤ t₀)
    (hshape : ∀ y ∈ Set.Icc (x₀ - c * t₀) (x₀ + c * t₀), u y 0 = v y 0)
    (hvel : ∀ y ∈ Set.Icc (x₀ - c * t₀) (x₀ + c * t₀),
        deriv (fun t => u y t) 0 = deriv (fun t => v y t) 0) :
    u x₀ t₀ = v x₀ t₀ :=
  wave_dod_aux c hc u v hu hv hwu hwv x₀ t₀ ht₀ hshape hvel

-- Rope speed: c = sqrt(T / ρ) with T = 0.05 N = 1/20 N and ρ = 0.2 kg/m = 1/5 kg/m gives 1/2 m/s.
example : Real.sqrt ((1 / 20 : ℝ) / (1 / 5)) = 1 / 2 := by
  rw [show (1 / 20 : ℝ) / (1 / 5) = (1 / 2) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)

-- Rope arrival at 1 m: 1 m ÷ 1/2 m/s = 2 s; the mistake T/ρ = 1/4 m/s would give 4 s.
example : (1 : ℝ) / (1 / 2) = 2 := by norm_num
example : (1 : ℝ) / ((1 / 20) / (1 / 5)) = 4 := by norm_num

-- Pinch exponents ((x - 1/2) / (1/20))^2 in the worked table: 1 at x = 9/20 and 11/20,
-- 64 at x = 9/10, 16 at x = 3/10 and 7/10.
example : (((9 / 20 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 1 := by norm_num
example : (((11 / 20 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 1 := by norm_num
example : (((9 / 10 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 64 := by norm_num
example : (((3 / 10 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 16 := by norm_num
example : (((7 / 10 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 16 := by norm_num

-- Bump peaks start 1/2 m from each held end, so at c = 1 m/s they reach the ends at 1/2 s.
example : ((1 : ℚ) - 1 / 2) / 1 = 1 / 2 := by norm_num

#print axioms dalembert_formula
#print axioms wave_solution_eq_sliding_profiles
#print axioms wave_domain_of_dependence
