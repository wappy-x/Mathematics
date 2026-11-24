-- Normal families: a locally bounded list of holomorphic functions has a locally uniformly convergent sub-list (Montel), late functions keep the limit's zero count inside a circle (Hurwitz), and a limit of one-to-one maps is one-to-one or constant.
import Mathlib.Analysis.Complex.LocallyUniformLimit
import Mathlib.Analysis.Analytic.Order
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Analysis.Complex.Liouville
import Mathlib.Analysis.Complex.RemovableSingularity
import Mathlib.Analysis.Calculus.LogDeriv
import Mathlib.Analysis.Meromorphic.Divisor
import Mathlib.Analysis.Normed.Module.Ball.Pointwise
import Mathlib.Topology.UniformSpace.Ascoli

open Filter Metric Set

lemma nf_finsum_ne_zero {φ : ℂ → ℕ} {s : Set ℂ} (hfin : (s ∩ Function.support φ).Finite)
    {a : ℂ} (ha : a ∈ s) (hφ : φ a ≠ 0) : ∑ᶠ z ∈ s, φ z ≠ 0 := by
  rw [← finsum_mem_inter_support, finsum_mem_eq_finite_toFinset_sum _ hfin]
  intro h0
  rw [Finset.sum_eq_zero_iff] at h0
  exact hφ (h0 a (by simp [ha, hφ]))

#print axioms nf_finsum_ne_zero

lemma nf_eq_zero_of_order_ne_zero {h : ℂ → ℂ} {z : ℂ} (hz : analyticOrderNatAt h z ≠ 0) :
    h z = 0 := by
  by_contra hne
  by_cases ha : AnalyticAt ℂ h z
  · apply hz; simp [analyticOrderNatAt, (ha.analyticOrderAt_eq_zero).2 hne]
  · apply hz; simp [analyticOrderNatAt, analyticOrderAt_of_not_analyticAt ha]

#print axioms nf_eq_zero_of_order_ne_zero

lemma nf_zeros_finite {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V) (hh : DifferentiableOn ℂ h V)
    {c : ℂ} {r : ℝ} (hC : closedBall c r ⊆ V) :
    (ball c r ∩ Function.support (analyticOrderNatAt h)).Finite := by
  have hm : MeromorphicOn h (closedBall c r) := fun z hz =>
    (hh.analyticAt (hV.mem_nhds (hC hz))).meromorphicAt
  refine ((MeromorphicOn.divisor h (closedBall c r)).finiteSupport
    (isCompact_closedBall c r)).subset ?_
  rintro z ⟨hz, hne⟩
  have hzC : z ∈ closedBall c r := ball_subset_closedBall hz
  have ha := hh.analyticAt (hV.mem_nhds (hC hzC))
  rw [Function.mem_support] at hne
  rw [Function.mem_support, hm.divisor_apply hzC, ha.meromorphicOrderAt_eq]
  unfold analyticOrderNatAt at hne
  cases hk : analyticOrderAt h z with
  | top => simp [hk] at hne
  | coe n => simp_all

#print axioms nf_zeros_finite

lemma nf_logDeriv_differentiableAt {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V)
    (hh : DifferentiableOn ℂ h V) {z : ℂ} (hz : z ∈ V) (hne : h z ≠ 0) :
    DifferentiableAt ℂ (logDeriv h) z := by
  have ha := hh.analyticAt (hV.mem_nhds hz)
  exact ha.deriv.differentiableAt.div ha.differentiableAt hne

#print axioms nf_logDeriv_differentiableAt

lemma nf_circle_logDeriv_zero {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V)
    (hh : DifferentiableOn ℂ h V) {c : ℂ} {r : ℝ} (hr : 0 ≤ r) (hC : closedBall c r ⊆ V)
    (hne : ∀ z ∈ closedBall c r, h z ≠ 0) : (∮ z in C(c, r), logDeriv h z) = 0 := by
  have hd : ∀ z ∈ closedBall c r, DifferentiableAt ℂ (logDeriv h) z := fun z hz =>
    nf_logDeriv_differentiableAt hV hh (hC hz) (hne z hz)
  exact Complex.circleIntegral_eq_zero_of_differentiable_on_off_countable hr countable_empty
    (fun z hz => (hd z hz).continuousAt.continuousWithinAt)
    (fun z hz => hd z (ball_subset_closedBall hz.1))

#print axioms nf_circle_logDeriv_zero

lemma nf_logDeriv_continuousOn {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V)
    (hh : DifferentiableOn ℂ h V) {S : Set ℂ} (hS : S ⊆ V) (hne : ∀ z ∈ S, h z ≠ 0) :
    ContinuousOn (logDeriv h) S := fun z hz =>
  (nf_logDeriv_differentiableAt hV hh (hS hz) (hne z hz)).continuousAt.continuousWithinAt

#print axioms nf_logDeriv_continuousOn

lemma nf_order_sub (a z : ℂ) :
    analyticOrderAt (fun w : ℂ => w - a) z = if z = a then 1 else 0 := by
  have han : AnalyticAt ℂ (fun w : ℂ => w - a) z := analyticAt_id.sub analyticAt_const
  split_ifs with hza
  · subst hza
    simp
  · exact han.analyticOrderAt_eq_zero.2 (sub_ne_zero.2 hza)

#print axioms nf_order_sub

lemma nf_arg_principle_aux {c : ℂ} {r : ℝ} (hr : 0 < r) {V : Set ℂ} (hV : IsOpen V)
    (hC : closedBall c r ⊆ V) (n : ℕ) : ∀ h : ℂ → ℂ, DifferentiableOn ℂ h V →
    (∀ z ∈ sphere c r, h z ≠ 0) → (∀ z ∈ closedBall c r, analyticOrderAt h z ≠ ⊤) →
    ∑ᶠ z ∈ ball c r, analyticOrderNatAt h z = n →
    (∮ z in C(c, r), logDeriv h z) = 2 * Real.pi * Complex.I * n := by
  induction n with
  | zero =>
    intro h hh hs htop hsum
    have hfin := nf_zeros_finite hV hh hC
    have hne : ∀ z ∈ closedBall c r, h z ≠ 0 := by
      intro z hz
      rcases (mem_closedBall.1 hz).lt_or_eq with hlt | heq
      · have hzb : z ∈ ball c r := mem_ball.2 hlt
        have h0 : analyticOrderNatAt h z = 0 := by
          by_contra hne
          exact nf_finsum_ne_zero hfin hzb hne hsum
        have ha := hh.analyticAt (hV.mem_nhds (hC hz))
        rw [← ha.analyticOrderAt_eq_zero, ← ENat.natCast_toNat (htop z hz)]
        simp [analyticOrderNatAt] at h0 ⊢
        exact h0
      · exact hs z (mem_sphere.2 heq)
    rw [nf_circle_logDeriv_zero hV hh hr.le hC hne]
    simp
  | succ n ih =>
    intro h hh hs htop hsum
    have hfin := nf_zeros_finite hV hh hC
    obtain ⟨a, ha, hane⟩ : ∃ a ∈ ball c r, analyticOrderNatAt h a ≠ 0 :=
      exists_ne_zero_of_finsum_mem_ne_zero (by rw [hsum]; exact Nat.succ_ne_zero n)
    have ha0 : h a = 0 := nf_eq_zero_of_order_ne_zero hane
    have haV : a ∈ V := hC (ball_subset_closedBall ha)
    set k := dslope h a with hkdef
    have hk : DifferentiableOn ℂ k V := (Complex.differentiableOn_dslope (hV.mem_nhds haV)).2 hh
    have hhk : h = (fun z => z - a) * k := by
      funext z
      have := sub_smul_dslope h a z
      rw [ha0, sub_zero, smul_eq_mul] at this
      exact this.symm
    have hks : ∀ z ∈ sphere c r, k z ≠ 0 := by
      intro z hz hk0
      apply hs z hz
      rw [hhk]
      simp [hk0]
    have hord : ∀ z ∈ closedBall c r, analyticOrderAt h z =
        (if z = a then 1 else 0) + analyticOrderAt k z := by
      intro z hz
      rw [← nf_order_sub a z, hhk]
      exact analyticOrderAt_mul (analyticAt_id.sub analyticAt_const)
        (hk.analyticAt (hV.mem_nhds (hC hz)))
    have htopk : ∀ z ∈ closedBall c r, analyticOrderAt k z ≠ ⊤ := by
      intro z hz htk
      apply htop z hz
      rw [hord z hz, htk, add_top]
    have hnat : ∀ z ∈ ball c r, analyticOrderNatAt h z =
        (if z = a then 1 else 0) + analyticOrderNatAt k z := by
      intro z hz
      have hz' := ball_subset_closedBall hz
      unfold analyticOrderNatAt
      rw [hord z hz', ENat.toNat_add (by split_ifs <;> simp) (htopk z hz')]
      split_ifs <;> simp
    have hfink : (ball c r ∩ Function.support (analyticOrderNatAt k)).Finite :=
      nf_zeros_finite hV hk hC
    have hsumk : ∑ᶠ z ∈ ball c r, analyticOrderNatAt k z = n := by
      have h1 : ∑ᶠ z ∈ ball c r, analyticOrderNatAt h z =
          ∑ᶠ z ∈ ball c r, (if z = a then 1 else 0) +
            ∑ᶠ z ∈ ball c r, analyticOrderNatAt k z := by
        rw [← finsum_mem_add_distrib' _ hfink]
        · exact finsum_mem_congr rfl hnat
        · exact (finite_singleton a).subset (fun z hz => by
            simp only [mem_inter_iff, Function.mem_support, ne_eq, ite_eq_right_iff,
              one_ne_zero, imp_false, not_not] at hz
            exact hz.2)
      have h2 : ∑ᶠ z ∈ ball c r, (if z = a then 1 else 0) = 1 := by
        rw [finsum_mem_eq_sum_of_inter_support_eq _ (t := {a})]
        · simp
        · ext z
          by_cases hz : z = a <;> simp [hz, ha]
      rw [hsum, h2] at h1
      omega
    have hIk := ih k hk hks htopk hsumk
    have hcongr : EqOn (logDeriv h) (fun z => (z - a)⁻¹ + logDeriv k z) (sphere c r) := by
      intro z hz
      have hza : z ≠ a := by
        rintro rfl
        rw [mem_sphere] at hz
        rw [mem_ball] at ha
        linarith
      rw [hhk, logDeriv_mul (f := fun w : ℂ => w - a) (g := k) z (sub_ne_zero.2 hza) (hks z hz) (differentiableAt_id.sub_const a)
        (hk.differentiableAt (hV.mem_nhds (hC (sphere_subset_closedBall hz))))]
      simp [logDeriv_apply]
    rw [circleIntegral.integral_congr hr.le hcongr, circleIntegral.integral_add, hIk,
      circleIntegral.integral_sub_inv_of_mem_ball ha]
    · push_cast; ring
    · refine ContinuousOn.circleIntegrable hr.le ?_
      refine (continuousOn_id.sub continuousOn_const).inv₀ ?_
      intro z hz h0
      have h0' : z = a := sub_eq_zero.1 h0
      subst h0'
      rw [mem_sphere] at hz
      rw [mem_ball] at ha
      linarith
    · exact ContinuousOn.circleIntegrable hr.le (nf_logDeriv_continuousOn hV hk
        (sphere_subset_closedBall.trans hC) hks)

#print axioms nf_arg_principle_aux

lemma nf_arg_principle {h : ℂ → ℂ} {V : Set ℂ} (hV : IsOpen V) (hh : DifferentiableOn ℂ h V)
    {c : ℂ} {r : ℝ} (hr : 0 < r) (hC : closedBall c r ⊆ V) (hs : ∀ z ∈ sphere c r, h z ≠ 0) :
    (∮ z in C(c, r), logDeriv h z) = 2 * Real.pi * Complex.I * (∑ᶠ z ∈ ball c r, analyticOrderNatAt h z : ℕ) := by
  obtain ⟨δ, hδ, hsub⟩ := (isCompact_closedBall c r).exists_thickening_subset_open hV hC
  rw [thickening_closedBall hδ hr.le] at hsub
  have htop : ∀ z ∈ closedBall c r, analyticOrderAt h z ≠ ⊤ := by
    intro z hz htz
    rw [analyticOrderAt_eq_top] at htz
    have hAn : AnalyticOnNhd ℂ h (ball c (δ + r)) := fun w hw => hh.analyticAt (hV.mem_nhds (hsub hw))
    have hzb : z ∈ ball c (δ + r) := by
      rw [mem_ball]; rw [mem_closedBall] at hz; linarith
    have hEq := hAn.eqOn_zero_of_preconnected_of_eventuallyEq_zero
      (convex_ball c (δ + r)).isPreconnected hzb htz
    obtain ⟨p, hp⟩ := (NormedSpace.sphere_nonempty (x := c)).2 hr.le
    apply hs p hp
    apply hEq
    rw [mem_ball]; rw [mem_sphere] at hp; linarith
  exact nf_arg_principle_aux hr hV hC _ h hh hs htop rfl

#print axioms nf_arg_principle

lemma nf_div_estimate {u v U' V' : ℂ} {m B δ : ℝ} (hm : 0 < m) (hv : m ≤ ‖v‖) (hu : ‖u‖ ≤ B)
    (hU : ‖U' - u‖ ≤ δ) (hV : ‖V' - v‖ ≤ δ) (hδ : δ ≤ m / 2) :
    ‖U' / V' - u / v‖ ≤ 2 * δ * (m + B) / m ^ 2 := by
  have hv0 : v ≠ 0 := by
    intro h0; rw [h0, norm_zero] at hv; linarith
  have hV' : m / 2 ≤ ‖V'‖ := by
    have := norm_sub_norm_le v V'
    rw [norm_sub_rev] at this
    linarith
  have hV0 : V' ≠ 0 := by
    intro h0; rw [h0, norm_zero] at hV'; linarith
  have hδ0 : 0 ≤ δ := (norm_nonneg _).trans hU
  have hB0 : 0 ≤ B := (norm_nonneg _).trans hu
  have heq : U' / V' - u / v = ((U' - u) * v - u * (V' - v)) / (V' * v) := by
    field_simp
    ring
  rw [heq, norm_div, norm_mul]
  have hnum : ‖(U' - u) * v - u * (V' - v)‖ ≤ δ * ‖v‖ + B * δ := by
    calc ‖(U' - u) * v - u * (V' - v)‖ ≤ ‖(U' - u) * v‖ + ‖u * (V' - v)‖ := norm_sub_le _ _
      _ = ‖U' - u‖ * ‖v‖ + ‖u‖ * ‖V' - v‖ := by rw [norm_mul, norm_mul]
      _ ≤ δ * ‖v‖ + B * δ := by gcongr
  have hpos : 0 < ‖V'‖ * ‖v‖ := by positivity
  rw [div_le_div_iff₀ hpos (by positivity)]
  calc ‖(U' - u) * v - u * (V' - v)‖ * m ^ 2 ≤ (δ * ‖v‖ + B * δ) * m ^ 2 := by gcongr
    _ ≤ 2 * δ * (m + B) * (‖V'‖ * ‖v‖) := by
      have h1 : m ≤ 2 * ‖V'‖ := by linarith
      have h2 : (δ * ‖v‖ + B * δ) * m ^ 2 ≤ δ * (m + B) * m * ‖v‖ := by
        have : B * δ * m ^ 2 ≤ B * δ * m * ‖v‖ := by
          have := mul_le_mul_of_nonneg_left hv (mul_nonneg (mul_nonneg hB0 hδ0) hm.le)
          nlinarith
        nlinarith
      have h3 : δ * (m + B) * m * ‖v‖ ≤ δ * (m + B) * (2 * ‖V'‖) * ‖v‖ := by
        gcongr
      nlinarith

#print axioms nf_div_estimate

lemma nf_isolated_zero_ball {h : ℂ → ℂ} {U : Set ℂ} (hU : IsOpen U) (hUc : IsPreconnected U)
    (hh : DifferentiableOn ℂ h U) (hnz : ∃ z ∈ U, h z ≠ 0) {a : ℂ} (ha : a ∈ U) (ha0 : h a = 0)
    {ρ₀ : ℝ} (hρ₀ : 0 < ρ₀) :
    ∃ ρ, 0 < ρ ∧ ρ ≤ ρ₀ ∧ closedBall a ρ ⊆ U ∧ (∀ z ∈ sphere a ρ, h z ≠ 0) ∧
      ∑ᶠ z ∈ ball a ρ, analyticOrderNatAt h z ≠ 0 := by
  have hAn : AnalyticOnNhd ℂ h U := fun z hz => hh.analyticAt (hU.mem_nhds hz)
  rcases (hAn a ha).eventually_eq_zero_or_eventually_ne_zero with hev | hev
  · exfalso
    obtain ⟨z, hz, hz0⟩ := hnz
    exact hz0 (hAn.eqOn_zero_of_preconnected_of_eventuallyEq_zero hUc ha hev hz)
  obtain ⟨ε, hε, hεU⟩ := Metric.isOpen_iff.1 hU a ha
  obtain ⟨η, hη, hηne⟩ := Metric.mem_nhdsWithin_iff.1 hev
  set ρ := min ρ₀ (min (ε / 2) (η / 2)) with hρ_def
  have hρ : 0 < ρ := lt_min hρ₀ (lt_min (by linarith) (by linarith))
  have hρε : ρ ≤ ε / 2 := (min_le_right _ _).trans (min_le_left _ _)
  have hρη : ρ ≤ η / 2 := (min_le_right _ _).trans (min_le_right _ _)
  have hCU : closedBall a ρ ⊆ U := (closedBall_subset_ball (by linarith)).trans hεU
  have hsph : ∀ z ∈ sphere a ρ, h z ≠ 0 := by
    intro z hz
    apply hηne
    refine ⟨?_, ?_⟩
    · rw [mem_ball, mem_sphere.1 hz]; linarith
    · rw [mem_compl_iff, mem_singleton_iff]
      rintro rfl
      rw [mem_sphere, dist_self] at hz
      linarith
  refine ⟨ρ, hρ, min_le_left _ _, hCU, hsph, ?_⟩
  apply nf_finsum_ne_zero (nf_zeros_finite hU hh hCU) (mem_ball_self hρ)
  have hne_top : analyticOrderAt h a ≠ ⊤ := by
    rw [Ne, analyticOrderAt_eq_top]
    intro hev'
    obtain ⟨w, hw⟩ := (hev'.filter_mono nhdsWithin_le_nhds).and hev |>.exists
    exact hw.2 hw.1
  have hne_zero : analyticOrderAt h a ≠ 0 := by
    rw [Ne, (hAn a ha).analyticOrderAt_eq_zero, not_not]
    exact ha0
  unfold analyticOrderNatAt
  intro h0
  rw [ENat.toNat_eq_zero] at h0
  rcases h0 with h0 | h0
  · exact hne_zero h0
  · exact hne_top h0

#print axioms nf_isolated_zero_ball

lemma nf_equicontinuous {U : Set ℂ} (hU : IsOpen U)
    {f : ℕ → ℂ → ℂ} (hf : ∀ n, DifferentiableOn ℂ (f n) U)
    (hbd : ∀ K ⊆ U, IsCompact K → ∃ M : ℝ, ∀ n, ∀ z ∈ K, ‖f n z‖ ≤ M) {x₀ : ℂ} (hx₀ : x₀ ∈ U)
    {ε : ℝ} (hε : 0 < ε) : ∀ᶠ y in nhds x₀, ∀ n, dist (f n x₀) (f n y) < ε := by
  obtain ⟨R0, hR0, hball⟩ := Metric.isOpen_iff.1 hU x₀ hx₀
  set R := R0 / 3 with hR_def
  have hR : 0 < R := by positivity
  have hKU : closedBall x₀ (2 * R) ⊆ U := (closedBall_subset_ball (by linarith)).trans hball
  obtain ⟨M, hM⟩ := hbd _ hKU (isCompact_closedBall _ _)
  have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM 0 x₀ (mem_closedBall_self (by linarith)))
  have hderiv : ∀ n, ∀ y ∈ ball x₀ R, ‖deriv (f n) y‖ ≤ M / R := by
    intro n y hy
    rw [mem_ball] at hy
    have hsub : closedBall y R ⊆ closedBall x₀ (2 * R) := by
      intro z hz
      rw [mem_closedBall] at hz ⊢
      linarith [dist_triangle z y x₀]
    apply Complex.norm_deriv_le_of_forall_mem_sphere_norm_le hR
    · apply DifferentiableOn.diffContOnCl
      rw [closure_ball y hR.ne']
      exact (hf n).mono (hsub.trans hKU)
    · intro z hz
      exact hM n z (hsub (sphere_subset_closedBall hz))
  have hmv : ∀ n, ∀ y ∈ ball x₀ R, ‖f n y - f n x₀‖ ≤ M / R * ‖y - x₀‖ := by
    intro n y hy
    refine Convex.norm_image_sub_le_of_norm_deriv_le (fun z hz => ?_) (hderiv n)
      (convex_ball x₀ R) (mem_ball_self hR) hy
    exact (hf n).differentiableAt (hU.mem_nhds (hKU (ball_subset_closedBall.trans
      (closedBall_subset_closedBall (by linarith)) hz)))
  have hL : 0 < M / R + 1 := by positivity
  have hρ : 0 < min R (ε / (M / R + 1)) := lt_min hR (by positivity)
  filter_upwards [ball_mem_nhds x₀ hρ] with y hy n
  rw [mem_ball] at hy
  have hy1 : dist y x₀ < R := hy.trans_le (min_le_left _ _)
  have hy2 : dist y x₀ < ε / (M / R + 1) := hy.trans_le (min_le_right _ _)
  rw [dist_comm, dist_eq_norm]
  have h1 := hmv n y (mem_ball.2 hy1)
  rw [← dist_eq_norm y x₀] at h1
  rw [lt_div_iff₀ hL] at hy2
  have h2 : M / R * dist y x₀ ≤ (M / R + 1) * dist y x₀ := by
    have := dist_nonneg (x := y) (y := x₀)
    nlinarith
  linarith

#print axioms nf_equicontinuous

/-- Montel's theorem: holomorphic functions on an open set `U` that share one bound on each
compact set inside `U` contain a sub-list converging uniformly on every compact set inside `U`,
and the limit is holomorphic. -/
theorem montel_locally_bounded_has_locally_uniform_subsequence {U : Set ℂ} (hU : IsOpen U)
    {f : ℕ → ℂ → ℂ} (hf : ∀ n, DifferentiableOn ℂ (f n) U)
    (hbd : ∀ K ⊆ U, IsCompact K → ∃ M : ℝ, ∀ n, ∀ z ∈ K, ‖f n z‖ ≤ M) :
    ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ g : ℂ → ℂ, DifferentiableOn ℂ g U ∧
      TendstoLocallyUniformlyOn (fun k => f (φ k)) g atTop U := by
  set 𝔖 : Set (Set ℂ) := {K | K ⊆ U ∧ IsCompact K} with h𝔖
  set t : ℕ → Set ℂ := fun n => closedBall 0 n ∩ (thickening (1 / ((n : ℝ) + 1)) Uᶜ)ᶜ with ht_def
  have ht : ∀ n, t n ∈ 𝔖 := by
    intro n
    refine ⟨?_, (isCompact_closedBall 0 (n : ℝ)).inter_right isOpen_thickening.isClosed_compl⟩
    rintro z ⟨-, hz⟩
    by_contra hzU
    exact hz (self_subset_thickening (by positivity) _ hzU)
  have hmono : Monotone t := by
    intro n m hnm
    have hnm' : (n : ℝ) ≤ m := by exact_mod_cast hnm
    refine inter_subset_inter (closedBall_subset_closedBall hnm') (compl_subset_compl.2 ?_)
    apply thickening_mono
    apply one_div_le_one_div_of_le (by positivity)
    linarith
  have hex : ∀ K ∈ 𝔖, ∃ n, K ⊆ t n := by
    rintro K ⟨hKU, hK⟩
    obtain ⟨δ, hδ, hδU⟩ := hK.exists_thickening_subset_open hU hKU
    obtain ⟨R, hR⟩ := hK.isBounded.subset_closedBall 0
    obtain ⟨n, hn⟩ := exists_nat_gt (max R (1 / δ))
    refine ⟨n, fun z hz => ⟨?_, ?_⟩⟩
    · have := hR hz
      rw [mem_closedBall] at this ⊢
      linarith [le_max_left R (1 / δ)]
    · intro hzt
      rw [mem_thickening_iff] at hzt
      obtain ⟨w, hw, hzw⟩ := hzt
      apply hw
      apply hδU
      rw [mem_thickening_iff]
      refine ⟨z, hz, ?_⟩
      rw [dist_comm]
      refine hzw.trans ?_
      have h1 : 1 / δ < (n : ℝ) + 1 := by linarith [le_max_right R (1 / δ)]
      rw [div_lt_iff₀ (by positivity)]
      rw [div_lt_iff₀ hδ] at h1
      linarith
  have := UniformOnFun.isCountablyGenerated_uniformity (β := ℂ) 𝔖 ht hmono hex
  set u : ℕ → UniformOnFun ℂ ℂ 𝔖 := fun n => UniformOnFun.ofFun 𝔖 (f n) with hu_def
  have hcomp : IsCompact (closure (range u)) := by
    refine ArzelaAscoli.isCompact_closure_of_isClosedEmbedding (F := UniformOnFun.toFun 𝔖) (𝔖 := 𝔖)
      (fun K hK => hK.2) Topology.IsClosedEmbedding.id ?_ ?_
    · intro K hK x hx
      apply EquicontinuousAt.equicontinuousWithinAt
      rw [Metric.equicontinuousAt_iff_right]
      intro ε hε
      filter_upwards [nf_equicontinuous hU hf hbd (hK.1 hx) hε] with y hy
      rintro ⟨i, n, rfl⟩
      exact hy n
    · intro K hK x hx
      obtain ⟨M, hM⟩ := hbd K hK.1 hK.2
      refine ⟨closedBall 0 M, isCompact_closedBall _ _, ?_⟩
      rintro i ⟨n, rfl⟩
      rw [mem_closedBall, dist_zero_right]
      exact hM n x hx
  obtain ⟨a, -, φ, hφ, hlim⟩ := hcomp.tendsto_subseq (x := u)
    (fun n => subset_closure (mem_range_self n))
  have hT : TendstoLocallyUniformlyOn (fun k => f (φ k)) (UniformOnFun.toFun 𝔖 a) atTop U := by
    rw [tendstoLocallyUniformlyOn_iff_forall_isCompact hU]
    intro K hKU hK
    exact UniformOnFun.tendsto_iff_tendstoUniformlyOn.1 hlim K ⟨hKU, hK⟩
  exact ⟨φ, hφ, UniformOnFun.toFun 𝔖 a,
    hT.differentiableOn (Eventually.of_forall fun k => hf (φ k)) hU, hT⟩

/-- Hurwitz's theorem: if holomorphic `f n` converge locally uniformly on `U` to `g`, `g` is not
zero everywhere, and the circle of centre `c` and radius `r` lies with its inside in `U` and carries
no zero of `g`, then for all large `n` the number of zeros of `f n` inside the circle, each counted
with its multiplicity, equals that of `g`. -/
theorem hurwitz_zero_count_eventually_eq {U : Set ℂ} (hU : IsOpen U)
    {f : ℕ → ℂ → ℂ} {g : ℂ → ℂ} (hf : ∀ n, DifferentiableOn ℂ (f n) U)
    (hlim : TendstoLocallyUniformlyOn f g atTop U) (hg : ∃ z ∈ U, g z ≠ 0)
    {c : ℂ} {r : ℝ} (hr : 0 < r) (hC : closedBall c r ⊆ U)
    (hgC : ∀ z ∈ sphere c r, g z ≠ 0) :
    ∀ᶠ n in atTop, (∑ᶠ z ∈ ball c r, analyticOrderNatAt (f n) z) =
      ∑ᶠ z ∈ ball c r, analyticOrderNatAt g z := by
  have _ := hg
  have hgd : DifferentiableOn ℂ g U := hlim.differentiableOn (Eventually.of_forall hf) hU
  have hS : sphere c r ⊆ U := sphere_subset_closedBall.trans hC
  have hSc : IsCompact (sphere c r) := isCompact_sphere c r
  have hSne : (sphere c r).Nonempty := (NormedSpace.sphere_nonempty (x := c)).2 hr.le
  have hu : TendstoUniformlyOn f g atTop (sphere c r) :=
    (tendstoLocallyUniformlyOn_iff_forall_isCompact hU).1 hlim _ hS hSc
  have hu' : TendstoUniformlyOn (deriv ∘ f) (deriv g) atTop (sphere c r) :=
    (tendstoLocallyUniformlyOn_iff_forall_isCompact hU).1
      (hlim.deriv (Eventually.of_forall hf) hU) _ hS hSc
  obtain ⟨x₀, hx₀, hmin⟩ := hSc.exists_isMinOn hSne (hgd.continuousOn.mono hS).norm
  set m := ‖g x₀‖ with hm_def
  have hm : 0 < m := norm_pos_iff.2 (hgC x₀ hx₀)
  have hmle : ∀ z ∈ sphere c r, m ≤ ‖g z‖ := fun z hz => hmin hz
  obtain ⟨B, hB⟩ := hSc.exists_bound_of_continuousOn ((hgd.deriv hU).continuousOn.mono hS)
  have hB0 : 0 ≤ B := (norm_nonneg _).trans (hB x₀ hx₀)
  -- choose the closeness `δ` so that the log-derivatives differ by at most `1 / (2 r)`
  set δ := min (m / 2) (m ^ 2 / (4 * r * (m + B))) with hδ_def
  have hδ : 0 < δ := lt_min (by linarith) (by positivity)
  have hδm : δ ≤ m / 2 := min_le_left _ _
  have hδ2 : 2 * δ * (m + B) / m ^ 2 ≤ 1 / (2 * r) := by
    have h1 : δ ≤ m ^ 2 / (4 * r * (m + B)) := min_le_right _ _
    rw [div_le_div_iff₀ (by positivity) (by positivity)]
    rw [le_div_iff₀ (by positivity)] at h1
    nlinarith
  filter_upwards [Metric.tendstoUniformlyOn_iff.1 hu δ hδ,
    Metric.tendstoUniformlyOn_iff.1 hu' δ hδ] with n hn hn'
  have hfn0 : ∀ z ∈ sphere c r, f n z ≠ 0 := by
    intro z hz h0
    have h1 := hn z hz
    rw [dist_eq_norm, h0, sub_zero] at h1
    have := hmle z hz
    linarith
  have hlog : ∀ z ∈ sphere c r, ‖logDeriv (f n) z - logDeriv g z‖ ≤ 1 / (2 * r) := by
    intro z hz
    rw [logDeriv_apply, logDeriv_apply]
    refine le_trans (nf_div_estimate hm (hmle z hz) (hB z hz) ?_ ?_ hδm) hδ2
    · have := hn' z hz
      rw [dist_comm, dist_eq_norm] at this
      exact this.le
    · have := hn z hz
      rw [dist_comm, dist_eq_norm] at this
      exact this.le
  have hIn := nf_arg_principle hU (hf n) hr hC hfn0
  have hIg := nf_arg_principle hU hgd hr hC hgC
  have hdiff : (∮ z in C(c, r), (logDeriv (f n) z - logDeriv g z)) =
      2 * Real.pi * Complex.I * ((∑ᶠ z ∈ ball c r, analyticOrderNatAt (f n) z : ℕ) -
        (∑ᶠ z ∈ ball c r, analyticOrderNatAt g z : ℕ) : ℂ) := by
    rw [circleIntegral.integral_sub, hIn, hIg, mul_sub]
    · exact ContinuousOn.circleIntegrable hr.le (nf_logDeriv_continuousOn hU (hf n) hS hfn0)
    · exact ContinuousOn.circleIntegrable hr.le (nf_logDeriv_continuousOn hU hgd hS hgC)
  have hbound := circleIntegral.norm_integral_le_of_norm_le_const hr.le hlog
  rw [hdiff] at hbound
  set N₁ := ∑ᶠ z ∈ ball c r, analyticOrderNatAt (f n) z
  set N₂ := ∑ᶠ z ∈ ball c r, analyticOrderNatAt g z
  have hnorm : ‖2 * (Real.pi : ℂ) * Complex.I * ((N₁ : ℂ) - N₂)‖ =
      2 * Real.pi * |(N₁ : ℝ) - N₂| := by
    have : ((N₁ : ℂ) - N₂) = (((N₁ : ℝ) - N₂ : ℝ) : ℂ) := by push_cast; ring
    rw [this, norm_mul, norm_mul, norm_mul, Complex.norm_real, Complex.norm_I, Complex.norm_real]
    simp [Real.norm_eq_abs, abs_of_pos Real.pi_pos]
  rw [hnorm] at hbound
  have hr' : 2 * Real.pi * r * (1 / (2 * r)) = Real.pi := by field_simp
  rw [hr'] at hbound
  have habs : |(N₁ : ℝ) - N₂| < 1 := by
    have := Real.pi_pos
    nlinarith [abs_nonneg ((N₁ : ℝ) - N₂)]
  rw [abs_sub_lt_iff] at habs
  have h1 : (N₁ : ℝ) < N₂ + 1 := by linarith
  have h2 : (N₂ : ℝ) < N₁ + 1 := by linarith
  have h1' : N₁ < N₂ + 1 := by exact_mod_cast h1
  have h2' : N₂ < N₁ + 1 := by exact_mod_cast h2
  omega

/-- Limits of one-to-one maps: on a region (an open set in one piece), a locally uniform limit of
one-to-one holomorphic functions is one-to-one or constant. -/
theorem injOn_or_const_of_tendstoLocallyUniformlyOn {U : Set ℂ} (hU : IsOpen U)
    (hUc : IsPreconnected U) {f : ℕ → ℂ → ℂ} {g : ℂ → ℂ}
    (hf : ∀ n, DifferentiableOn ℂ (f n) U) (hinj : ∀ n, InjOn (f n) U)
    (hlim : TendstoLocallyUniformlyOn f g atTop U) :
    InjOn g U ∨ ∃ w : ℂ, ∀ z ∈ U, g z = w := by
  by_contra hcon
  push Not at hcon
  obtain ⟨hni, hnc⟩ := hcon
  obtain ⟨a, ha, b, hb, hab, hne⟩ : ∃ a ∈ U, ∃ b ∈ U, g a = g b ∧ a ≠ b := by
    simp only [InjOn, not_forall] at hni
    obtain ⟨a, ha, b, hb, hab, hne⟩ := hni
    exact ⟨a, ha, b, hb, hab, hne⟩
  set w := g a with hw
  have hgd : DifferentiableOn ℂ g U := hlim.differentiableOn (Eventually.of_forall hf) hU
  set h : ℂ → ℂ := fun z => g z - w with hh_def
  set F : ℕ → ℂ → ℂ := fun n z => f n z - w with hF_def
  have hhd : DifferentiableOn ℂ h U := hgd.sub_const w
  have hFd : ∀ n, DifferentiableOn ℂ (F n) U := fun n => (hf n).sub_const w
  have hFlim : TendstoLocallyUniformlyOn F h atTop U := by
    rw [Metric.tendstoLocallyUniformlyOn_iff] at hlim ⊢
    intro ε hε x hx
    obtain ⟨t, ht, hev⟩ := hlim ε hε x hx
    refine ⟨t, ht, hev.mono fun n hn y hy => ?_⟩
    simpa [h, F, dist_sub_right] using hn y hy
  have hnz : ∃ z ∈ U, h z ≠ 0 := by
    obtain ⟨z, hz, hz'⟩ := hnc w
    exact ⟨z, hz, sub_ne_zero.2 hz'⟩
  have hd : 0 < dist a b := dist_pos.2 hne
  obtain ⟨ρa, hρa, hρa', hCa, hsa, hNa⟩ :=
    nf_isolated_zero_ball hU hUc hhd hnz ha (by simp [h, w]) (ρ₀ := dist a b / 2) (by linarith)
  obtain ⟨ρb, hρb, hρb', hCb, hsb, hNb⟩ :=
    nf_isolated_zero_ball hU hUc hhd hnz hb (by simp [h, w, hab]) (ρ₀ := dist a b / 2)
      (by linarith)
  have hEa := hurwitz_zero_count_eventually_eq hU hFd hFlim hnz hρa hCa hsa
  have hEb := hurwitz_zero_count_eventually_eq hU hFd hFlim hnz hρb hCb hsb
  obtain ⟨n, hna, hnb⟩ := (hEa.and hEb).exists
  rw [← hna] at hNa
  rw [← hnb] at hNb
  obtain ⟨x, hx, hx0⟩ := exists_ne_zero_of_finsum_mem_ne_zero hNa
  obtain ⟨y, hy, hy0⟩ := exists_ne_zero_of_finsum_mem_ne_zero hNb
  have hFx := nf_eq_zero_of_order_ne_zero hx0
  have hFy := nf_eq_zero_of_order_ne_zero hy0
  have hxU : x ∈ U := hCa (ball_subset_closedBall hx)
  have hyU : y ∈ U := hCb (ball_subset_closedBall hy)
  have hxy : x ≠ y := by
    rintro rfl
    rw [mem_ball] at hx hy
    have := dist_triangle_left a b x
    linarith
  apply hxy
  apply hinj n hxU hyU
  simp only [F, sub_eq_zero] at hFx hFy
  rw [hFx, hFy]

-- The gap of z + z²/n factors as (a - b)(1 + (a + b)/n).
example (a b n : ℂ) (hn : n ≠ 0) :
    (a + a ^ 2 / n) - (b + b ^ 2 / n) = (a - b) * (1 + (a + b) / n) := by
  field_simp
  ring
-- For n = 1 it fails: f₁(-3/10) = f₁(-7/10) = -21/100.
example : ((-3 / 10 : ℚ) + (-3 / 10) ^ 2) = -21 / 100 := by norm_num
example : ((-7 / 10 : ℚ) + (-7 / 10) ^ 2) = -21 / 100 := by norm_num
-- Slope cap M/δ = 1/(1/10) = 10.
example : (1 : ℚ) / (1 / 10) = 10 := by norm_num
-- The zero 1/3 of z - 1/3 lies inside |z| = 1/2.
example : (1 : ℚ) / 3 < 1 / 2 := by norm_num
-- The roots ±i/√5 of z² + 1/5 have size squared 1/5 < (1/2)², so both lie inside |z| = 1/2.
example : (1 : ℚ) / 5 < (1 / 2) ^ 2 := by norm_num
-- Stretch of g₁₀ = (z + z²/10)/(1 + 1/10) at 0 is 10/11.
example : (1 + 1 / 10 : ℚ)⁻¹ = 10 / 11 := by norm_num
-- Worst gap |g₁₀ - z| on the rim, at z = -1: 2/11.
example : ((-1 + (-1) ^ 2 / 10) / (1 + 1 / 10) : ℚ) - (-1) = 2 / 11 := by norm_num

#print axioms montel_locally_bounded_has_locally_uniform_subsequence
#print axioms hurwitz_zero_count_eventually_eq
#print axioms injOn_or_const_of_tendstoLocallyUniformlyOn
