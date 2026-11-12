-- Sturm-Liouville: for -(p y')' + q y = λ w y with p and w positive inside, real p, q, w and shared end conditions, two modes with different eigenvalues integrate to zero against the weight w, every eigenvalue is real, and the amount of each mode in a finite sum of modes is its weighted overlap over its weighted size.
import Mathlib.Analysis.RCLike.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Data.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Star

open Set

namespace SturmLiouville

theorem end_det_zero {𝕜 : Type*} [RCLike 𝕜] (α β : ℝ) (h : α ≠ 0 ∨ β ≠ 0) (U PU V PV : 𝕜)
    (hu : (α : 𝕜) * U + (β : 𝕜) * PU = 0) (hv : (α : 𝕜) * V + (β : 𝕜) * PV = 0) :
    PU * V - U * PV = 0 := by
  rcases h with h | h
  · have h' : (α : 𝕜) ≠ 0 := by exact_mod_cast h
    have : (α : 𝕜) * (PU * V - U * PV) = 0 := by linear_combination PU * hv - PV * hu
    exact (mul_eq_zero.mp this).resolve_left h'
  · have h' : (β : 𝕜) ≠ 0 := by exact_mod_cast h
    have : (β : 𝕜) * (PU * V - U * PV) = 0 := by linear_combination V * hu - U * hv
    exact (mul_eq_zero.mp this).resolve_left h'

theorem lagrange_identity_integral {𝕜 : Type*} [RCLike 𝕜] (p q w : ℝ → ℝ)
    (a b α₁ β₁ α₂ β₂ : ℝ) (hab : a ≤ b) (hwc : ContinuousOn w (Icc a b))
    (hend₁ : α₁ ≠ 0 ∨ β₁ ≠ 0) (hend₂ : α₂ ≠ 0 ∨ β₂ ≠ 0)
    (lam mu : 𝕜) (u u' v v' Pu Pv : ℝ → 𝕜)
    (hu : ∀ x ∈ Icc a b, HasDerivWithinAt u (u' x) (Icc a b) x)
    (hv : ∀ x ∈ Icc a b, HasDerivWithinAt v (v' x) (Icc a b) x)
    (hPu : ∀ x ∈ Icc a b, HasDerivWithinAt (fun t => (p t : 𝕜) * u' t) (Pu x) (Icc a b) x)
    (hPv : ∀ x ∈ Icc a b, HasDerivWithinAt (fun t => (p t : 𝕜) * v' t) (Pv x) (Icc a b) x)
    (eu : ∀ x ∈ Ioo a b, -Pu x + (q x : 𝕜) * u x = lam * (w x : 𝕜) * u x)
    (ev : ∀ x ∈ Ioo a b, -Pv x + (q x : 𝕜) * v x = mu * (w x : 𝕜) * v x)
    (bua : (α₁ : 𝕜) * u a + (β₁ : 𝕜) * ((p a : 𝕜) * u' a) = 0)
    (bva : (α₁ : 𝕜) * v a + (β₁ : 𝕜) * ((p a : 𝕜) * v' a) = 0)
    (bub : (α₂ : 𝕜) * u b + (β₂ : 𝕜) * ((p b : 𝕜) * u' b) = 0)
    (bvb : (α₂ : 𝕜) * v b + (β₂ : 𝕜) * ((p b : 𝕜) * v' b) = 0) :
    (mu - lam) * ∫ x in a..b, (w x : 𝕜) * u x * v x = 0 := by
  set W : ℝ → 𝕜 := fun t => ((p t : 𝕜) * u' t) * v t - u t * ((p t : 𝕜) * v' t) with hW
  have hWd : ∀ x ∈ Icc a b, HasDerivWithinAt W
      (Pu x * v x + ((p x : 𝕜) * u' x) * v' x - (u' x * ((p x : 𝕜) * v' x) + u x * Pv x))
      (Icc a b) x := fun x hx =>
    ((hPu x hx).mul (hv x hx)).sub ((hu x hx).mul (hPv x hx))
  have hwk : ContinuousOn (fun x => (w x : 𝕜)) (Icc a b) :=
    (RCLike.continuous_ofReal (K := 𝕜)).comp_continuousOn hwc
  have huc : ContinuousOn u (Icc a b) := fun x hx => (hu x hx).continuousWithinAt
  have hvc : ContinuousOn v (Icc a b) := fun x hx => (hv x hx).continuousWithinAt
  have hint : IntervalIntegrable (fun x => (mu - lam) * ((w x : 𝕜) * u x * v x)) MeasureTheory.volume a b := by
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le hab]
    exact continuousOn_const.mul ((hwk.mul huc).mul hvc)
  have hFTC := intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le hab
    (fun x hx => (hWd x hx).continuousWithinAt) (fun x hx => by
      have hx' : x ∈ Icc a b := Ioo_subset_Icc_self hx
      have hd := ((hWd x hx').hasDerivAt (Icc_mem_nhds hx.1 hx.2)).hasDerivWithinAt (s := Ioi x)
      convert hd using 1
      have h1 := eu x hx
      have h2 := ev x hx
      linear_combination v x * h1 - u x * h2) hint
  rw [intervalIntegral.integral_const_mul] at hFTC
  rw [hFTC]
  have ha := end_det_zero α₁ β₁ hend₁ (u a) ((p a : 𝕜) * u' a) (v a) ((p a : 𝕜) * v' a) bua bva
  have hb := end_det_zero α₂ β₂ hend₂ (u b) ((p b : 𝕜) * u' b) (v b) ((p b : 𝕜) * v' b) bub bvb
  simp only [hW, ha, hb, sub_zero]

theorem integral_pos_of_pos_at (a b : ℝ) (g : ℝ → ℝ) (hg : ContinuousOn g (Icc a b))
    (hg0 : ∀ x ∈ Ioo a b, 0 ≤ g x) (x₁ : ℝ) (hx₁ : x₁ ∈ Ioo a b) (hpos : 0 < g x₁) :
    0 < ∫ x in a..b, g x := by
  have hab : a ≤ b := (hx₁.1.trans hx₁.2).le
  have hca : ContinuousAt g x₁ := hg.continuousAt (Icc_mem_nhds hx₁.1 hx₁.2)
  have hev : {x | 0 < g x ∧ x ∈ Ioo a b} ∈ nhds x₁ :=
    (hca.eventually (lt_mem_nhds hpos)).and (Ioo_mem_nhds hx₁.1 hx₁.2)
  obtain ⟨l, r, hlr, hsub⟩ := mem_nhds_iff_exists_Ioo_subset.mp hev
  set c := (l + x₁) / 2
  set d := (x₁ + r) / 2
  have hc1 : l < c := by simp only [c]; linarith [hlr.1]
  have hc2 : c < x₁ := by simp only [c]; linarith [hlr.1]
  have hd1 : x₁ < d := by simp only [d]; linarith [hlr.2]
  have hd2 : d < r := by simp only [d]; linarith [hlr.2]
  have hcd_sub : Icc c d ⊆ Ioo l r := Icc_subset_Ioo hc1 hd2
  have hcin : c ∈ Ioo a b := (hsub (hcd_sub ⟨le_rfl, by linarith⟩)).2
  have hdin : d ∈ Ioo a b := (hsub (hcd_sub ⟨by linarith, le_rfl⟩)).2
  have hpos' : 0 < ∫ x in c..d, g x := by
    apply intervalIntegral.intervalIntegral_pos_of_pos_on
    · apply ContinuousOn.intervalIntegrable
      rw [uIcc_of_le (by linarith)]
      exact hg.mono (Icc_subset_Icc hcin.1.le hdin.2.le)
    · intro x hx
      exact (hsub (hcd_sub (Ioo_subset_Icc_self hx))).1
    · linarith
  have hmono : (∫ x in c..d, g x) ≤ ∫ x in a..b, g x := by
    apply intervalIntegral.integral_mono_interval hcin.1.le (by linarith) hdin.2.le
    · rw [MeasureTheory.Measure.restrict_congr_set MeasureTheory.Ioo_ae_eq_Ioc.symm]
      exact (MeasureTheory.ae_restrict_iff' measurableSet_Ioo).mpr
        (Filter.Eventually.of_forall hg0)
    · apply ContinuousOn.intervalIntegrable
      rw [uIcc_of_le hab]
      exact hg
  linarith

theorem exists_ne_zero_inside {𝕜 : Type*} [RCLike 𝕜] (a b : ℝ) (hab : a < b) (y : ℝ → 𝕜)
    (hy : ContinuousOn y (Icc a b)) (h : ∃ x ∈ Icc a b, y x ≠ 0) :
    ∃ x ∈ Ioo a b, y x ≠ 0 := by
  obtain ⟨x₀, hx₀, hne⟩ := h
  have hcl : x₀ ∈ closure (Ioo a b) := by rw [closure_Ioo hab.ne]; exact hx₀
  have := mem_closure_iff_nhdsWithin_neBot.mp hcl
  have hc : ContinuousWithinAt y (Ioo a b) x₀ := (hy x₀ hx₀).mono Ioo_subset_Icc_self
  have h1 : ∀ᶠ x in nhdsWithin x₀ (Ioo a b), y x ≠ 0 := hc.eventually_ne hne
  have h2 : ∀ᶠ x in nhdsWithin x₀ (Ioo a b), x ∈ Ioo a b := self_mem_nhdsWithin
  obtain ⟨x, hx1, hx2⟩ := (h2.and h1).exists
  exact ⟨x, hx1, hx2⟩

#print axioms end_det_zero
#print axioms lagrange_identity_integral
#print axioms integral_pos_of_pos_at
#print axioms exists_ne_zero_inside


/-- `y` is a mode of the Sturm-Liouville problem `-(p y')' + q y = lam w y` on `a < x < b`,
with eigenvalue `lam`, under the end conditions `α₁ y + β₁ p y' = 0` at `a` and
`α₂ y + β₂ p y' = 0` at `b`. Here `y` takes values in `𝕜` (the real or the complex numbers),
the coefficients `p, q, w` and the end-condition numbers are real, and `y'` is the slope of `y`.
The definition asks that:
* `y` has slope `y'` at every point of `a ≤ x ≤ b` (one-sided at the ends), so `y` stays finite
  on the closed interval;
* the stiffness times the slope, `p y'`, has a rate of change `P'` on `a ≤ x ≤ b`, and
  `-P' + q y = lam w y` at every point strictly inside;
* the two end conditions hold;
* `y` is not the zero shape on `a ≤ x ≤ b`.
The end conditions cover the card's three kinds: `y = 0` (`β = 0`), `p y' = 0` (`α = 0`), and
a fixed real ratio of the two. At an end where `p` is 0, like the drum's centre, the condition
`p y' = 0` holds automatically, so it asks only that the mode stay finite there. -/
def IsMode {𝕜 : Type*} [RCLike 𝕜] (p q w : ℝ → ℝ) (a b α₁ β₁ α₂ β₂ : ℝ) (lam : 𝕜)
    (y y' : ℝ → 𝕜) : Prop :=
  (∀ x ∈ Icc a b, HasDerivWithinAt y (y' x) (Icc a b) x) ∧
  (∃ P' : ℝ → 𝕜,
    (∀ x ∈ Icc a b, HasDerivWithinAt (fun t => (p t : 𝕜) * y' t) (P' x) (Icc a b) x) ∧
    ∀ x ∈ Ioo a b, -P' x + (q x : 𝕜) * y x = lam * (w x : 𝕜) * y x) ∧
  (α₁ : 𝕜) * y a + (β₁ : 𝕜) * ((p a : 𝕜) * y' a) = 0 ∧
  (α₂ : 𝕜) * y b + (β₂ : 𝕜) * ((p b : 𝕜) * y' b) = 0 ∧
  ∃ x ∈ Icc a b, y x ≠ 0

/-- The card's main claim, perpendicular modes. Put the equation in Sturm-Liouville form
`-(p y')' + q y = λ w y` on `a < x < b`, with `p, q, w` real, `p` and `w` positive inside the
interval, `q` and `w` continuous on `a ≤ x ≤ b`, and one end condition at each end
(`α y + β p y' = 0`, with `α, β` real and not both 0). If `u` is a mode with eigenvalue `λ`
and `v` is a mode with eigenvalue `μ`, under the same end conditions, and `λ ≠ μ`, then
`∫ₐᵇ w u v dx = 0`: two different modes, multiplied and weighted, integrate to zero. -/
theorem modes_with_different_eigenvalues_are_perpendicular_under_weight
    (p q w : ℝ → ℝ) (a b α₁ β₁ α₂ β₂ : ℝ) (hab : a < b)
    (hp : ∀ x ∈ Ioo a b, 0 < p x) (hw : ∀ x ∈ Ioo a b, 0 < w x)
    (hq : ContinuousOn q (Icc a b)) (hwc : ContinuousOn w (Icc a b))
    (hend₁ : α₁ ≠ 0 ∨ β₁ ≠ 0) (hend₂ : α₂ ≠ 0 ∨ β₂ ≠ 0)
    (lam mu : ℝ) (u u' v v' : ℝ → ℝ)
    (hu : IsMode p q w a b α₁ β₁ α₂ β₂ lam u u')
    (hv : IsMode p q w a b α₁ β₁ α₂ β₂ mu v v')
    (hne : lam ≠ mu) :
    ∫ x in a..b, w x * u x * v x = 0 := by
  obtain ⟨hu1, ⟨Pu, hPu, eu⟩, bua, bub, -⟩ := hu
  obtain ⟨hv1, ⟨Pv, hPv, ev⟩, bva, bvb, -⟩ := hv
  have h := lagrange_identity_integral (𝕜 := ℝ) p q w a b α₁ β₁ α₂ β₂ hab.le hwc hend₁ hend₂
    lam mu u u' v v' Pu Pv hu1 hv1 hPu hPv eu ev bua bva bub bvb
  have hne' : mu - lam ≠ 0 := sub_ne_zero.mpr (Ne.symm hne)
  exact (mul_eq_zero.mp h).resolve_left hne'

/-- The card's second claim, real eigenvalues. Under the same conditions (`p, q, w` real,
`p` and `w` positive inside, `q` and `w` continuous on `a ≤ x ≤ b`, real end conditions with
`α, β` not both 0), let `y` be a mode that is allowed to take complex values, with a complex
eigenvalue `λ`. Then `λ` is real: its imaginary part is 0. -/
theorem every_eigenvalue_is_real
    (p q w : ℝ → ℝ) (a b α₁ β₁ α₂ β₂ : ℝ) (hab : a < b)
    (hp : ∀ x ∈ Ioo a b, 0 < p x) (hw : ∀ x ∈ Ioo a b, 0 < w x)
    (hq : ContinuousOn q (Icc a b)) (hwc : ContinuousOn w (Icc a b))
    (hend₁ : α₁ ≠ 0 ∨ β₁ ≠ 0) (hend₂ : α₂ ≠ 0 ∨ β₂ ≠ 0)
    (lam : ℂ) (y y' : ℝ → ℂ)
    (hy : IsMode p q w a b α₁ β₁ α₂ β₂ lam y y') :
    lam.im = 0 := by
  obtain ⟨hy1, ⟨P', hP, ey⟩, ba, bb, hnz⟩ := hy
  have hstar_ofReal : ∀ r : ℝ, star (RCLike.ofReal r : ℂ) = (RCLike.ofReal r : ℂ) :=
    fun r => RCLike.conj_ofReal r
  have h := lagrange_identity_integral (𝕜 := ℂ) p q w a b α₁ β₁ α₂ β₂ hab.le hwc hend₁ hend₂
    lam (star lam) y y' (fun t => star (y t)) (fun t => star (y' t)) P' (fun t => star (P' t))
    hy1 (fun x hx => (hy1 x hx).star)
    hP (fun x hx => by
      have := (hP x hx).star
      convert this using 1
      funext t
      rw [star_mul', hstar_ofReal])
    ey (fun x hx => by
      have := congrArg star (ey x hx)
      simpa only [star_add, star_neg, star_mul', hstar_ofReal] using this)
    ba (by
      have := congrArg star ba
      simpa only [star_add, star_mul', hstar_ofReal, star_zero] using this)
    bb (by
      have := congrArg star bb
      simpa only [star_add, star_mul', hstar_ofReal, star_zero] using this)
  have hyc : ContinuousOn y (Icc a b) := fun x hx => (hy1 x hx).continuousWithinAt
  obtain ⟨x₁, hx₁, hy₁⟩ := exists_ne_zero_inside a b hab y hyc hnz
  have hpos : 0 < ∫ x in a..b, w x * Complex.normSq (y x) := by
    apply integral_pos_of_pos_at a b _ (hwc.mul (Complex.continuous_normSq.comp_continuousOn hyc))
      (fun x hx => mul_nonneg (hw x hx).le (Complex.normSq_nonneg _)) x₁ hx₁
    exact mul_pos (hw x₁ hx₁) (Complex.normSq_pos.mpr hy₁)
  have hI : (∫ x in a..b, (RCLike.ofReal (w x) : ℂ) * y x * star (y x))
      = ((∫ x in a..b, w x * Complex.normSq (y x) : ℝ) : ℂ) := by
    rw [← intervalIntegral.integral_ofReal]
    apply intervalIntegral.integral_congr
    intro x _
    change ((w x : ℝ) : ℂ) * y x * (starRingEnd ℂ) (y x) = (((w x * Complex.normSq (y x)) : ℝ) : ℂ)
    rw [mul_assoc, Complex.mul_conj]
    push_cast
    ring
  rw [hI] at h
  have hne : ((∫ x in a..b, w x * Complex.normSq (y x) : ℝ) : ℂ) ≠ 0 := by
    exact_mod_cast hpos.ne'
  have h0 : star lam - lam = 0 := (mul_eq_zero.mp h).resolve_right hne
  have : (starRingEnd ℂ) lam = lam := sub_eq_zero.mp h0
  exact Complex.conj_eq_iff_im.mp this

/-- The card's Step 5, the amount of each mode. Under the same conditions, take finitely many
modes `y_k` (one for each `k` in `s`) under the same end conditions, with eigenvalues `λ_k`
that are all different. If a shape `f` equals `∑ c_k y_k` on `a ≤ x ≤ b`, then for each `n` in
`s` the amount of mode `n` is its weighted overlap with `f` over its weighted size:
`c_n = (∫ₐᵇ w f y_n dx) / (∫ₐᵇ w y_n² dx)`. (That every shape is such a sum, possibly infinite,
is completeness, which the card states but proves elsewhere.) -/
theorem coefficient_is_weighted_overlap_over_size {ι : Type*}
    (p q w : ℝ → ℝ) (a b α₁ β₁ α₂ β₂ : ℝ) (hab : a < b)
    (hp : ∀ x ∈ Ioo a b, 0 < p x) (hw : ∀ x ∈ Ioo a b, 0 < w x)
    (hq : ContinuousOn q (Icc a b)) (hwc : ContinuousOn w (Icc a b))
    (hend₁ : α₁ ≠ 0 ∨ β₁ ≠ 0) (hend₂ : α₂ ≠ 0 ∨ β₂ ≠ 0)
    (s : Finset ι) (lam : ι → ℝ) (y y' : ι → ℝ → ℝ)
    (hy : ∀ k ∈ s, IsMode p q w a b α₁ β₁ α₂ β₂ (lam k) (y k) (y' k))
    (hdistinct : ∀ j ∈ s, ∀ k ∈ s, j ≠ k → lam j ≠ lam k)
    (c : ι → ℝ) (f : ℝ → ℝ) (hf : ∀ x ∈ Icc a b, f x = ∑ k ∈ s, c k * y k x)
    (n : ι) (hn : n ∈ s) :
    c n = (∫ x in a..b, w x * f x * y n x) / (∫ x in a..b, w x * y n x ^ 2) := by
  have hcont : ∀ k ∈ s, ContinuousOn (y k) (Icc a b) := fun k hk x hx =>
    ((hy k hk).1 x hx).continuousWithinAt
  have hint : ∀ k ∈ s, IntervalIntegrable (fun x => c k * (w x * y k x * y n x))
      MeasureTheory.volume a b := by
    intro k hk
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le hab.le]
    exact continuousOn_const.mul ((hwc.mul (hcont k hk)).mul (hcont n hn))
  have h1 : (∫ x in a..b, w x * f x * y n x) = c n * ∫ x in a..b, w x * y n x ^ 2 := by
    calc (∫ x in a..b, w x * f x * y n x)
        = ∫ x in a..b, ∑ k ∈ s, c k * (w x * y k x * y n x) := by
          apply intervalIntegral.integral_congr
          intro x hx
          rw [uIcc_of_le hab.le] at hx
          simp only
          rw [hf x hx, Finset.mul_sum, Finset.sum_mul]
          apply Finset.sum_congr rfl
          intro k _
          ring
      _ = ∑ k ∈ s, ∫ x in a..b, c k * (w x * y k x * y n x) :=
          intervalIntegral.integral_finsetSum hint
      _ = ∑ k ∈ s, c k * ∫ x in a..b, w x * y k x * y n x := by
          apply Finset.sum_congr rfl
          intro k _
          exact intervalIntegral.integral_const_mul _ _
      _ = c n * ∫ x in a..b, w x * y n x * y n x := by
          apply Finset.sum_eq_single n
          · intro k hk hkn
            rw [modes_with_different_eigenvalues_are_perpendicular_under_weight p q w a b α₁ β₁ α₂
              β₂ hab hp hw hq hwc hend₁ hend₂ (lam k) (lam n) (y k) (y' k) (y n) (y' n) (hy k hk)
              (hy n hn) (hdistinct k hk n hn hkn), mul_zero]
          · intro h
            exact absurd hn h
      _ = c n * ∫ x in a..b, w x * y n x ^ 2 := by
          congr 1
          apply intervalIntegral.integral_congr
          intro x _
          simp only
          ring
  obtain ⟨x₁, hx₁, hy₁⟩ := exists_ne_zero_inside a b hab (y n) (hcont n hn) (hy n hn).2.2.2.2
  have hpos : 0 < ∫ x in a..b, w x * y n x ^ 2 := by
    apply integral_pos_of_pos_at a b _ (hwc.mul ((hcont n hn).pow 2))
      (fun x hx => mul_nonneg (hw x hx).le (sq_nonneg _)) x₁ hx₁
    exact mul_pos (hw x₁ hx₁) (sq_pos_of_ne_zero hy₁)
  rw [h1, mul_div_assoc, div_self hpos.ne', mul_one]

-- The arch x(1 - x) on the string: c_n = 4(1 - (-1)^n)/(nπ)^3. The even amounts vanish,
-- c_2 = 0 and c_4 = 0: the symmetric arch has no even harmonics.
example : (4 * (1 - (-1 : ℤ) ^ 2), 4 * (1 - (-1 : ℤ) ^ 4)) = (0, 0) := by norm_num
-- The odd numerators are 8, so c_1 / c_3 = 3^3 = 27: the third harmonic holds 1/27 of the first.
example : (4 * (1 - (-1 : ℚ) ^ 1) / 1 ^ 3) / (4 * (1 - (-1 : ℚ) ^ 3) / 3 ^ 3) = 27 := by norm_num
-- The usual mistake: c_1 = 8/π³, but leaving out the mode's size 1/2 gives 4/π³, half of it
-- of the true amount. The numerators: 4(1 - (-1)^1) = 8, and half of 8 is 4.
example : (4 * (1 - (-1 : ℤ) ^ 1), 4 * (1 - (-1 : ℤ) ^ 1) / 2) = (8, 4) := by norm_num

#print axioms modes_with_different_eigenvalues_are_perpendicular_under_weight
#print axioms every_eigenvalue_is_real
#print axioms coefficient_is_weighted_overlap_over_size

end SturmLiouville
