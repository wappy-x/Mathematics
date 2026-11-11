-- Rouche's theorem: if f and g are holomorphic on and inside a circle and |g| < |f| at every point of the circle, then f + g and f have the same number of zeros inside it, counted with multiplicity; so z^5 + 3z + 1 has one root inside the unit circle and all five inside radius 2, and every monic polynomial of degree n has all n roots inside any circle of radius above 1 and above the sum of its lower coefficients' sizes.
import Mathlib.Analysis.Analytic.Order
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Tactic.NormNum
import Mathlib

/-! The plane is `ℂ`. The loop is the circle `Metric.sphere c R` (centre `c`, radius `R`), walked
once anticlockwise; its inside is the open disc `Metric.ball c R`. Mathlib has no inside for a
general simple closed loop, so this file states the theorem for circles, the loops all of the
card's examples use. "Holomorphic on and inside the loop" is `DifferentiableOn ℂ f
(Metric.closedBall c R)`. `analyticOrderNatAt f z` is the multiplicity of `z` as a zero of `f`
(`0` when `f z ≠ 0`), so `∑ᶠ z ∈ Metric.ball c R, analyticOrderNatAt f z` is `N(f)`, the number
of zeros inside, each counted as often as its multiplicity. For a polynomial `p`, `p.roots` lists
its roots with multiplicity, and `(p.roots.filter (‖·‖ < R)).card` counts those inside radius `R`. -/

open Polynomial

namespace RouchesTheorem

section Helpers

open Complex Metric Filter Topology Set Real

lemma aux_order_ne_top {h : ℂ → ℂ} {c : ℂ} {ρ R : ℝ} (hρ : 0 < ρ) (hρR : ρ < R)
    (hd : DifferentiableOn ℂ h (ball c R)) (hne : ∀ z ∈ sphere c ρ, h z ≠ 0) :
    ∀ z ∈ ball c R, analyticOrderAt h z ≠ ⊤ := by
  intro z hz htop
  have han : AnalyticOnNhd ℂ h (ball c R) := hd.analyticOnNhd isOpen_ball
  have h0 := han.eqOn_zero_of_preconnected_of_eventuallyEq_zero (convex_ball c R).isPreconnected hz
    (analyticOrderAt_eq_top.1 htop)
  have hmem : c + ρ ∈ sphere c ρ := by simp [abs_of_pos hρ]
  have hmem' : c + ρ ∈ ball c R := by simp [abs_of_pos hρ, hρR]
  exact hne _ hmem (h0 hmem')

lemma aux_finite {h : ℂ → ℂ} {c : ℂ} {ρ R : ℝ} (hρ : 0 < ρ) (hρR : ρ < R)
    (hd : DifferentiableOn ℂ h (ball c R)) (hne : ∀ z ∈ sphere c ρ, h z ≠ 0) :
    (ball c ρ ∩ Function.support (analyticOrderNatAt h)).Finite := by
  have han : AnalyticOnNhd ℂ h (ball c R) := hd.analyticOnNhd isOpen_ball
  have hsub : ball c ρ ∩ Function.support (analyticOrderNatAt h) ⊆
      {z ∈ closedBall c ρ | h z = 0} := by
    rintro z ⟨hz, hz'⟩
    exact ⟨ball_subset_closedBall hz, apply_eq_zero_of_analyticOrderNatAt_ne_zero hz'⟩
  refine Set.Finite.subset ?_ hsub
  by_contra hinf
  obtain ⟨x, hx, hacc⟩ := Set.Infinite.exists_accPt_of_subset_isCompact hinf
    (isCompact_closedBall c ρ) (fun z hz => hz.1)
  have hxR : x ∈ ball c R := closedBall_subset_ball hρR hx
  have hfreq : ∃ᶠ z in 𝓝[≠] x, h z = 0 :=
    (accPt_iff_frequently_nhdsNE.1 hacc).mono fun z hz => hz.2
  have h0 := han.eqOn_zero_of_preconnected_of_frequently_eq_zero
    (convex_ball c R).isPreconnected hxR hfreq
  have hmem : c + ρ ∈ sphere c ρ := by simp [abs_of_pos hρ]
  have hmem' : c + ρ ∈ ball c R := by simp [abs_of_pos hρ, hρR]
  exact hne _ hmem (h0 hmem')

lemma aux_logDeriv_diffAt {h : ℂ → ℂ} {c z : ℂ} {R : ℝ}
    (hd : DifferentiableOn ℂ h (ball c R)) (hz : z ∈ ball c R) (hne : h z ≠ 0) :
    DifferentiableAt ℂ (logDeriv h) z := by
  have hd' := (hd.deriv isOpen_ball).differentiableAt (isOpen_ball.mem_nhds hz)
  have hh := hd.differentiableAt (isOpen_ball.mem_nhds hz)
  have : logDeriv h = fun x => deriv h x / h x := rfl
  rw [this]
  exact hd'.div hh hne

lemma aux_logDeriv_contOn {h : ℂ → ℂ} {c : ℂ} {R : ℝ} {S : Set ℂ}
    (hd : DifferentiableOn ℂ h (ball c R)) (hS : S ⊆ ball c R) (hne : ∀ z ∈ S, h z ≠ 0) :
    ContinuousOn (logDeriv h) S := fun z hz =>
  (aux_logDeriv_diffAt hd (hS hz) (hne z hz)).continuousAt.continuousWithinAt

lemma aux_order_lin (a z : ℂ) :
    analyticOrderNatAt (fun w => w - a) z = if z = a then 1 else 0 := by
  have han : AnalyticAt ℂ (fun w => w - a) z := analyticAt_id.sub analyticAt_const
  split_ifs with hza
  · subst hza
    have : analyticOrderAt (fun w => w - z) z = (1 : ℕ) := by
      rw [han.analyticOrderAt_eq_natCast]
      exact ⟨fun _ => 1, analyticAt_const, one_ne_zero, Eventually.of_forall fun w => by simp⟩
    simp [analyticOrderNatAt, this]
  · have : analyticOrderAt (fun w => w - a) z = 0 :=
      analyticOrderAt_eq_zero.2 (Or.inr (sub_ne_zero.2 hza))
    simp [analyticOrderNatAt, this]

lemma aux_arg (n : ℕ) : ∀ (h : ℂ → ℂ) (c : ℂ) (ρ R : ℝ), 0 < ρ → ρ < R →
    DifferentiableOn ℂ h (ball c R) → (∀ z ∈ sphere c ρ, h z ≠ 0) →
    ∑ᶠ z ∈ ball c ρ, analyticOrderNatAt h z = n →
    (∮ z in C(c, ρ), logDeriv h z) = 2 * π * I * n := by
  induction n with
  | zero =>
    intro h c ρ R hρ hρR hd hne hsum
    have hfin := aux_finite hρ hρR hd hne
    have htop := aux_order_ne_top hρ hρR hd hne
    have han : AnalyticOnNhd ℂ h (ball c R) := hd.analyticOnNhd isOpen_ball
    have hnz : ∀ z ∈ closedBall c ρ, h z ≠ 0 := by
      intro z hz
      rcases (mem_closedBall.1 hz).lt_or_eq with hlt | heq
      · have hzb : z ∈ ball c ρ := mem_ball.2 hlt
        have hzR : z ∈ ball c R := ball_subset_ball hρR.le hzb
        have h0 : analyticOrderNatAt h z = 0 := by
          by_contra hne0
          have hmem : z ∈ ball c ρ ∩ Function.support (analyticOrderNatAt h) := ⟨hzb, hne0⟩
          rw [← finsum_mem_inter_support, finsum_mem_eq_finite_toFinset_sum _ hfin] at hsum
          exact hne0 (Finset.sum_eq_zero_iff.1 hsum z (hfin.mem_toFinset.2 hmem))
        have h0' : analyticOrderAt h z = 0 := by
          have := htop z hzR
          simp only [analyticOrderNatAt, ENat.toNat_eq_zero] at h0
          tauto
        rcases analyticOrderAt_eq_zero.1 h0' with h1 | h1
        · exact absurd (han z hzR) h1
        · exact h1
      · exact hne z (mem_sphere.2 heq)
    have hcb : closedBall c ρ ⊆ ball c R := closedBall_subset_ball hρR
    rw [Complex.circleIntegral_eq_zero_of_differentiable_on_off_countable hρ.le
      Set.countable_empty (aux_logDeriv_contOn hd hcb hnz)
      (fun z hz => aux_logDeriv_diffAt hd (hcb (ball_subset_closedBall hz.1))
        (hnz z (ball_subset_closedBall hz.1)))]
    simp
  | succ n ih =>
    intro h c ρ R hρ hρR hd hne hsum
    have hfin := aux_finite hρ hρR hd hne
    have htop := aux_order_ne_top hρ hρR hd hne
    obtain ⟨a, ha, ha0⟩ : ∃ a ∈ ball c ρ, analyticOrderNatAt h a ≠ 0 := by
      by_contra hcon
      push Not at hcon
      rw [finsum_mem_congr rfl hcon] at hsum
      simp at hsum
    have haR : a ∈ ball c R := ball_subset_ball hρR.le ha
    have hha : h a = 0 := apply_eq_zero_of_analyticOrderNatAt_ne_zero ha0
    have hkd : DifferentiableOn ℂ (dslope h a) (ball c R) :=
      (differentiableOn_dslope (isOpen_ball.mem_nhds haR)).2 hd
    have hfac : ∀ z, h z = (z - a) * dslope h a z := by
      intro z
      have := sub_smul_dslope h a z
      rw [hha, sub_zero, smul_eq_mul] at this
      exact this.symm
    generalize dslope h a = k at hkd hfac
    have hfun : h = (fun w => w - a) * k := funext hfac
    have hkne : ∀ z ∈ sphere c ρ, k z ≠ 0 := fun z hz hk0 =>
      hne z hz (by rw [hfac, hk0, mul_zero])
    have hkan : AnalyticOnNhd ℂ (k) (ball c R) := hkd.analyticOnNhd isOpen_ball
    have hlin_an : ∀ z, AnalyticAt ℂ (fun w => w - a) z :=
      fun z => analyticAt_id.sub analyticAt_const
    have hktop := aux_order_ne_top hρ hρR hkd hkne
    have hkfin := aux_finite hρ hρR hkd hkne
    have hsplit : ∀ z ∈ ball c ρ, analyticOrderNatAt h z =
        analyticOrderNatAt (fun w => w - a) z + analyticOrderNatAt (k) z := by
      intro z hz
      have hzR := ball_subset_ball hρR.le hz
      have hlt : analyticOrderAt (fun w => w - a) z ≠ ⊤ := fun ht =>
        htop z hzR (by rw [hfun]; exact analyticOrderAt_mul_eq_top_of_left ht)
      rw [hfun]
      exact analyticOrderNatAt_mul (hlin_an z) (hkan z hzR) hlt (hktop z hzR)
    have hlin_sum : ∑ᶠ z ∈ ball c ρ, analyticOrderNatAt (fun w => w - a) z = 1 := by
      rw [← finsum_mem_inter_support]
      have hset : ball c ρ ∩ Function.support (fun z => analyticOrderNatAt (fun w => w - a) z)
          = {a} := by
        ext z
        simp only [Set.mem_inter_iff, Function.mem_support, aux_order_lin, Set.mem_singleton_iff]
        constructor
        · rintro ⟨_, hz⟩
          by_contra hza
          simp [hza] at hz
        · rintro rfl
          simp [ha]
      rw [hset, finsum_mem_singleton, aux_order_lin]
      simp
    have hlinfin : (ball c ρ ∩ Function.support
        (fun z => analyticOrderNatAt (fun w => w - a) z)).Finite := by
      by_contra hinf
      rw [finsum_mem_eq_zero_of_infinite hinf] at hlin_sum
      exact zero_ne_one hlin_sum
    have hksum : ∑ᶠ z ∈ ball c ρ, analyticOrderNatAt (k) z = n := by
      rw [finsum_mem_congr rfl hsplit, finsum_mem_add_distrib' hlinfin hkfin, hlin_sum] at hsum
      omega
    have hik := ih (k) c ρ R hρ hρR hkd hkne hksum
    have hnea : ∀ z ∈ sphere c ρ, z - a ≠ 0 := by
      intro z hz hza
      rw [sub_eq_zero] at hza
      subst hza
      rw [mem_sphere] at hz
      rw [mem_ball] at ha
      linarith
    have heq : EqOn (logDeriv h) (fun z => (z - a)⁻¹ + logDeriv (k) z) (sphere c ρ) := by
      intro z hz
      have hzR : z ∈ ball c R := sphere_subset_closedBall.trans (closedBall_subset_ball hρR) hz
      rw [hfun, logDeriv_mul (f := fun w : ℂ => w - a) (g := k) z (hnea z hz) (hkne z hz)
        (by fun_prop)
        (hkd.differentiableAt (isOpen_ball.mem_nhds hzR))]
      simp [logDeriv_apply]
    have hsphR : sphere c ρ ⊆ ball c R := sphere_subset_closedBall.trans (closedBall_subset_ball hρR)
    have hint1 : CircleIntegrable (fun z => (z - a)⁻¹) c ρ := by
      apply ContinuousOn.circleIntegrable hρ.le
      exact ((continuous_id.sub continuous_const).continuousOn).inv₀ hnea
    have hint2 : CircleIntegrable (logDeriv (k)) c ρ :=
      ContinuousOn.circleIntegrable hρ.le (aux_logDeriv_contOn hkd hsphR hkne)
    rw [circleIntegral.integral_congr hρ.le heq, circleIntegral.integral_add hint1 hint2,
      circleIntegral.integral_sub_inv_of_mem_ball ha, hik]
    push_cast
    ring

lemma aux_rouche (f g : ℂ → ℂ) (c : ℂ) (R : ℝ)
    (hf : DifferentiableOn ℂ f (closedBall c R))
    (hg : DifferentiableOn ℂ g (closedBall c R))
    (hlt : ∀ z ∈ sphere c R, ‖g z‖ < ‖f z‖) :
    ∑ᶠ z ∈ ball c R, analyticOrderNatAt (f + g) z =
      ∑ᶠ z ∈ ball c R, analyticOrderNatAt f z := by
  rcases le_or_gt R 0 with hR | hR
  · simp [ball_eq_empty.2 hR]
  set K := {z ∈ closedBall c R | ‖f z‖ ≤ ‖g z‖} with hK
  have hKc : IsClosed K :=
    IsClosed.isClosed_le isClosed_closedBall hf.continuousOn.norm hg.continuousOn.norm
  have hKsub : K ⊆ ball c R := by
    rintro z ⟨hz, hz'⟩
    rcases (mem_closedBall.1 hz).lt_or_eq with h1 | h1
    · exact mem_ball.2 h1
    · exact absurd hz' (not_le.2 (hlt z (mem_sphere.2 h1)))
  obtain ⟨r, hrR, hKr⟩ := exists_lt_subset_ball hKc hKsub
  set ρ := (max r 0 + R) / 2 with hρdef
  have hρpos : 0 < ρ := by have := le_max_right r 0; rw [hρdef]; linarith
  have hrρ : r < ρ := by have := le_max_left r 0; rw [hρdef]; linarith
  have hρR : ρ < R := by
    have : max r 0 < R := max_lt hrR hR
    rw [hρdef]; linarith
  have hgood : ∀ z ∈ closedBall c R, ρ ≤ dist z c → ‖g z‖ < ‖f z‖ := by
    intro z hz hρz
    by_contra hcon
    have h1 := hKr ⟨hz, not_lt.1 hcon⟩
    rw [mem_ball] at h1
    linarith
  have hfd : DifferentiableOn ℂ f (ball c R) := hf.mono ball_subset_closedBall
  have hFd : DifferentiableOn ℂ (f + g) (ball c R) := (hf.add hg).mono ball_subset_closedBall
  have hgood' : ∀ z ∈ closedBall c R, ρ ≤ dist z c → f z ≠ 0 ∧ (f + g) z ≠ 0 := by
    intro z hz hρz
    have h1 := hgood z hz hρz
    refine ⟨fun h0 => ?_, fun h0 => ?_⟩
    · rw [h0, norm_zero] at h1
      exact (norm_nonneg _).not_gt h1
    · rw [Pi.add_apply, add_eq_zero_iff_eq_neg] at h0
      rw [h0, norm_neg] at h1
      exact lt_irrefl _ h1
  have hsph : ∀ z ∈ sphere c ρ, z ∈ closedBall c R ∧ ρ ≤ dist z c := fun z hz =>
    ⟨sphere_subset_closedBall.trans (closedBall_subset_closedBall hρR.le) hz,
      (mem_sphere.1 hz).ge⟩
  have hred : ∀ φ : ℂ → ℂ, (∀ z ∈ closedBall c R, ρ ≤ dist z c → φ z ≠ 0) →
      ∑ᶠ z ∈ ball c R, analyticOrderNatAt φ z = ∑ᶠ z ∈ ball c ρ, analyticOrderNatAt φ z := by
    intro φ hφ
    rw [← finsum_mem_inter_support, ← finsum_mem_inter_support (s := ball c ρ)]
    have hset : ball c R ∩ Function.support (analyticOrderNatAt φ) =
        ball c ρ ∩ Function.support (analyticOrderNatAt φ) := by
      ext z
      constructor
      · rintro ⟨hz, hz'⟩
        refine ⟨?_, hz'⟩
        by_contra hzρ
        rw [mem_ball, not_lt] at hzρ
        exact hφ z (ball_subset_closedBall hz) hzρ (apply_eq_zero_of_analyticOrderNatAt_ne_zero hz')
      · rintro ⟨hz, hz'⟩
        exact ⟨ball_subset_ball hρR.le hz, hz'⟩
    rw [hset]
  rw [hred (f + g) (fun z hz h' => (hgood' z hz h').2), hred f (fun z hz h' => (hgood' z hz h').1)]
  have hneF : ∀ z ∈ sphere c ρ, (f + g) z ≠ 0 := fun z hz => (hgood' z (hsph z hz).1 (hsph z hz).2).2
  have hnef : ∀ z ∈ sphere c ρ, f z ≠ 0 := fun z hz => (hgood' z (hsph z hz).1 (hsph z hz).2).1
  have h1 := aux_arg _ (f + g) c ρ R hρpos hρR hFd hneF rfl
  have h2 := aux_arg _ f c ρ R hρpos hρR hfd hnef rfl
  have hsphR : sphere c ρ ⊆ ball c R := sphere_subset_closedBall.trans (closedBall_subset_ball hρR)
  have hint1 : CircleIntegrable (logDeriv (f + g)) c ρ :=
    ContinuousOn.circleIntegrable hρpos.le (aux_logDeriv_contOn hFd hsphR hneF)
  have hint2 : CircleIntegrable (logDeriv f) c ρ :=
    ContinuousOn.circleIntegrable hρpos.le (aux_logDeriv_contOn hfd hsphR hnef)
  have hderiv : ∀ z ∈ sphere c ρ, HasDerivWithinAt (fun w => log ((f + g) w / f w))
      (logDeriv (f + g) z - logDeriv f z) (sphere c ρ) z := by
    intro z hz
    have hzR := hsphR hz
    have hFz := (hFd.differentiableAt (isOpen_ball.mem_nhds hzR)).hasDerivAt
    have hfz := (hfd.differentiableAt (isOpen_ball.mem_nhds hzR)).hasDerivAt
    have hf0 := hnef z hz
    have hF0 := hneF z hz
    have hslit : (f + g) z / f z ∈ slitPlane := by
      apply mem_slitPlane_iff.2 (Or.inl _)
      have hq : (f + g) z / f z = 1 + g z / f z := by
        rw [Pi.add_apply]; field_simp
      have hn : ‖g z / f z‖ < 1 := by
        rw [norm_div, div_lt_one (norm_pos_iff.2 hf0)]
        exact hgood z (hsph z hz).1 (hsph z hz).2
      rw [hq, add_re, one_re]
      have := abs_re_le_norm (g z / f z)
      have := neg_abs_le (g z / f z).re
      linarith
    have := (hFz.div hfz hf0).clog hslit
    convert this.hasDerivWithinAt using 1
    rw [logDeriv_apply, logDeriv_apply, Pi.div_apply]
    field_simp
  have h3 := circleIntegral.integral_eq_zero_of_hasDerivWithinAt hρpos.le hderiv
  rw [circleIntegral.integral_sub hint1 hint2, h1, h2, sub_eq_zero] at h3
  have hpi : (2 * (π : ℂ) * I) ≠ 0 := by
    simp [Real.pi_ne_zero, I_ne_zero]
  exact_mod_cast mul_left_cancel₀ hpi h3

lemma aux_order_poly (p : ℂ[X]) (hp : p ≠ 0) (z : ℂ) :
    analyticOrderNatAt (fun w => p.eval w) z = p.rootMultiplicity z := by
  obtain ⟨q, hpq, hndvd⟩ := p.exists_eq_pow_rootMultiplicity_mul_and_not_dvd hp z
  have hq : q.eval z ≠ 0 := fun h0 => hndvd (dvd_iff_isRoot.2 h0)
  have : analyticOrderAt (fun w => p.eval w) z = (p.rootMultiplicity z : ℕ) := by
    rw [(p.differentiable.analyticAt z).analyticOrderAt_eq_natCast]
    refine ⟨fun w => q.eval w, q.differentiable.analyticAt z, hq, Eventually.of_forall fun w => ?_⟩
    conv_lhs => rw [hpq]
    simp [eval_mul, eval_pow]
  simp [analyticOrderNatAt, this]

lemma aux_count_poly (p : ℂ[X]) (hp : p ≠ 0) (R : ℝ) :
    (p.roots.filter (fun z ↦ ‖z‖ < R)).card =
      ∑ᶠ z ∈ ball (0 : ℂ) R, analyticOrderNatAt (fun w => p.eval w) z := by
  classical
  simp_rw [aux_order_poly p hp, ← count_roots]
  rw [finsum_mem_eq_sum_of_inter_support_eq _ (t := (p.roots.filter (fun z ↦ ‖z‖ < R)).toFinset)]
  · rw [← Multiset.toFinset_sum_count_eq]
    refine Finset.sum_congr rfl fun z hz => ?_
    simp [(Multiset.mem_filter.1 (Multiset.mem_toFinset.1 hz)).2]
  · ext z
    simp only [Set.mem_inter_iff, mem_ball_zero_iff, Function.mem_support, Finset.mem_coe,
      Multiset.mem_toFinset, Multiset.mem_filter, ne_eq, Multiset.count_eq_zero, not_not]
    tauto

lemma aux_monic (p : ℂ[X]) (hp : p.Monic) (R : ℝ) (hR1 : 1 < R)
    (hRA : ∑ k ∈ Finset.range p.natDegree, ‖p.coeff k‖ < R) :
    (p.roots.filter (fun z ↦ ‖z‖ < R)).card = p.natDegree := by
  rw [Multiset.filter_eq_self.2, IsAlgClosed.card_roots_eq_natDegree]
  intro z hz
  have hroot : p.eval z = 0 := (mem_roots hp.ne_zero).1 hz
  by_contra hzR
  push Not at hzR
  have hz1 : 1 ≤ ‖z‖ := by linarith
  rw [hp.as_sum] at hroot
  simp only [eval_add, eval_pow, eval_X, eval_finsetSum, eval_mul, eval_C] at hroot
  generalize p.natDegree = n at hroot hRA
  have heq : z ^ n = -∑ i ∈ Finset.range n, p.coeff i * z ^ i := eq_neg_of_add_eq_zero_left hroot
  have hnorm : ‖z‖ ^ n ≤ ∑ i ∈ Finset.range n, ‖p.coeff i‖ * ‖z‖ ^ i := by
    rw [← norm_pow, heq, norm_neg]
    refine (norm_sum_le _ _).trans (le_of_eq ?_)
    simp [norm_pow]
  rcases n with _ | m
  · simp only [pow_zero, Finset.range_zero, Finset.sum_empty] at hnorm
    linarith
  · have hle : ∑ i ∈ Finset.range (m + 1), ‖p.coeff i‖ * ‖z‖ ^ i ≤
        ∑ i ∈ Finset.range (m + 1), ‖p.coeff i‖ * ‖z‖ ^ m := by
      refine Finset.sum_le_sum fun i hi => ?_
      have him : i ≤ m := Nat.lt_succ_iff.1 (Finset.mem_range.1 hi)
      exact mul_le_mul_of_nonneg_left (pow_le_pow_right₀ hz1 him) (norm_nonneg _)
    rw [← Finset.sum_mul] at hle
    have hpos : 0 < ‖z‖ ^ m := pow_pos (by linarith) m
    have hlt : (∑ i ∈ Finset.range (m + 1), ‖p.coeff i‖) * ‖z‖ ^ m < ‖z‖ * ‖z‖ ^ m :=
      mul_lt_mul_of_pos_right (by linarith) hpos
    rw [pow_succ] at hnorm
    linarith

lemma aux_quintic :
    (((X ^ 5 + C 3 * X + 1 : ℂ[X]).roots.filter (fun z ↦ ‖z‖ < 1)).card = 1) ∧
      (((X ^ 5 + C 3 * X + 1 : ℂ[X]).roots.filter (fun z ↦ ‖z‖ < 2)).card = 5) := by
  have hmon : (X ^ 5 + C 3 * X + 1 : ℂ[X]).Monic := by monicity!
  have hdeg : (X ^ 5 + C 3 * X + 1 : ℂ[X]).natDegree = 5 := by compute_degree!
  constructor
  · rw [aux_count_poly _ hmon.ne_zero]
    have hfg : (fun w => (X ^ 5 + C 3 * X + 1 : ℂ[X]).eval w) =
        (fun w => (C 3 * X : ℂ[X]).eval w) + (fun w => (X ^ 5 + 1 : ℂ[X]).eval w) := by
      funext w
      simp
      ring
    rw [hfg, aux_rouche]
    · rw [← aux_count_poly _ (by simp)]
      simp [Multiset.filter_singleton]
    · exact (Polynomial.differentiable _).differentiableOn
    · exact (Polynomial.differentiable _).differentiableOn
    · intro z hz
      rw [mem_sphere_zero_iff_norm] at hz
      simp only [eval_add, eval_pow, eval_X, eval_one, eval_mul, eval_C]
      have h1 : ‖z ^ 5 + 1‖ ≤ 2 := by
        refine (norm_add_le _ _).trans ?_
        simp [norm_pow, hz]
        norm_num
      have h2 : ‖(3 : ℂ) * z‖ = 3 := by simp [hz]
      linarith
  · rw [Multiset.filter_eq_self.2, IsAlgClosed.card_roots_eq_natDegree, hdeg]
    intro z hz
    have hroot := (mem_roots hmon.ne_zero).1 hz
    simp only [IsRoot, eval_add, eval_pow, eval_X, eval_one, eval_mul, eval_C] at hroot
    by_contra h
    push Not at h
    have heq : z ^ 5 = -(3 * z + 1) := by linear_combination hroot
    have h1 : ‖z‖ ^ 5 = ‖3 * z + 1‖ := by rw [← norm_pow, heq, norm_neg]
    have h2 : ‖3 * z + 1‖ ≤ 3 * ‖z‖ + 1 := (norm_add_le _ _).trans (by simp)
    have h3 : (2 : ℝ) ^ 4 ≤ ‖z‖ ^ 4 := pow_le_pow_left₀ (by norm_num) h 4
    have h4 : ‖z‖ ^ 5 = ‖z‖ * ‖z‖ ^ 4 := by ring
    nlinarith

end Helpers

#print axioms aux_order_ne_top
#print axioms aux_finite
#print axioms aux_logDeriv_diffAt
#print axioms aux_logDeriv_contOn
#print axioms aux_order_lin
#print axioms aux_arg
#print axioms aux_rouche
#print axioms aux_order_poly
#print axioms aux_count_poly
#print axioms aux_monic
#print axioms aux_quintic

/-- **Rouché's theorem.** Let `f` and `g` be holomorphic on and inside a circle. If `|g(z)| < |f(z)|`
at every point `z` of the circle, then the sum `f + g` has exactly as many zeros inside the circle
as `f`, each zero counted as often as its multiplicity: `N(f + g) = N(f)`. -/
theorem zero_count_add_eq_zero_count_of_norm_lt_on_circle
    (f g : ℂ → ℂ) (c : ℂ) (R : ℝ)
    (hf : DifferentiableOn ℂ f (Metric.closedBall c R))
    (hg : DifferentiableOn ℂ g (Metric.closedBall c R))
    (hlt : ∀ z ∈ Metric.sphere c R, ‖g z‖ < ‖f z‖) :
    ∑ᶠ z ∈ Metric.ball c R, analyticOrderNatAt (f + g) z =
      ∑ᶠ z ∈ Metric.ball c R, analyticOrderNatAt f z := by
  exact aux_rouche f g c R hf hg hlt

/-- **The quintic.** `z^5 + 3z + 1` has exactly one root inside the unit circle and all five of
its roots, counted with multiplicity, inside the circle of radius 2. -/
theorem quintic_one_root_in_unit_disc_and_five_in_radius_two :
    (((X ^ 5 + C 3 * X + 1 : ℂ[X]).roots.filter (fun z ↦ ‖z‖ < 1)).card = 1) ∧
      (((X ^ 5 + C 3 * X + 1 : ℂ[X]).roots.filter (fun z ↦ ‖z‖ < 2)).card = 5) := by
  exact aux_quintic

/-- **The fundamental theorem of algebra, in two lines.** Let `p = z^n + a_(n−1) z^(n−1) + … + a_0`
be a monic polynomial of degree `n`, and let `A = |a_0| + … + |a_(n−1)|`. On any circle of radius
`R` greater than both 1 and `A`, `p` has as many zeros inside as `z^n`: all `n` of them, counted
with multiplicity. -/
theorem monic_all_roots_in_disc_of_radius_gt_one_and_gt_coeff_sum
    (p : ℂ[X]) (hp : p.Monic) (R : ℝ) (hR1 : 1 < R)
    (hRA : ∑ k ∈ Finset.range p.natDegree, ‖p.coeff k‖ < R) :
    (p.roots.filter (fun z ↦ ‖z‖ < R)).card = p.natDegree := by
  exact aux_monic p hp R hR1 hRA

/-! The card's worked numbers. -/

-- Quintic on radius 1: the lead z^5 + 1 has size at most 1 + 1 = 2, less than the owner |3z| = 3.
example : (1 : ℕ) + 1 = 2 ∧ (2 : ℕ) < 3 := by norm_num
-- No root on the unit circle: there |p| ≥ 3 − 2 = 1.
example : (3 : ℤ) - 2 = 1 := by norm_num
-- Quintic on radius 2: the lead 3z + 1 has size at most 3 × 2 + 1 = 7, less than |z^5| = 2^5 = 32.
example : 3 * 2 + 1 = 7 ∧ 2 ^ 5 = 32 ∧ 7 < 32 := by norm_num
-- Between the circles: 5 − 1 = 4 roots.
example : (5 : ℕ) - 1 = 4 := by norm_num
-- Two-line FTA for the quintic: A = 1 + 3 = 4, so radius 5 suffices (5 > 1 and 5 > 4).
example : (1 : ℕ) + 3 = 4 ∧ 1 < 5 ∧ 4 < 5 := by norm_num
-- z^3 − 1/8 on the unit circle: the lead 1/8 is less than the owner 1.
example : (1 : ℚ) / 8 < 1 := by norm_num
-- Wrong owner z^5 on |z| = 1: |3z + 1| reaches 3 + 1 = 4 > 1.
example : (3 : ℕ) + 1 = 4 ∧ 1 < 4 := by norm_num
-- Silent test: z^5 + 3z + 3 has a lead z^5 + 3 reaching 1 + 3 = 4 > 3.
example : (1 : ℕ) + 3 = 4 ∧ 3 < 4 := by norm_num

#print axioms zero_count_add_eq_zero_count_of_norm_lt_on_circle
#print axioms quintic_one_root_in_unit_disc_and_five_in_radius_two
#print axioms monic_all_roots_in_disc_of_radius_gt_one_and_gt_coeff_sum

end RouchesTheorem
