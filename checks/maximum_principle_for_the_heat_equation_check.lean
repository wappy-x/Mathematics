-- Diffusion's maximum principle: on a bounded region in any number of dimensions, a solution of the heat equation with no heat source inside is never larger than its largest value on the start and the sides, so a solution that starts lower and is held lower stays lower, and on the whole space the same holds under a growth condition.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.DerivativeTest
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

open Set Laplacian

/-- The parabolic boundary `Γ_T` of the space-time box `Ω × (0, T]`: the start (the closed
region at time 0) together with the sides (the boundary of the region at every time from 0 to
`T`). The lid, the region at the final time `T`, is not in it. -/
def parabolicBoundary {d : ℕ} (Ω : Set (EuclideanSpace ℝ (Fin d))) (T : ℝ) :
    Set (EuclideanSpace ℝ (Fin d) × ℝ) :=
  (closure Ω ×ˢ {0}) ∪ (frontier Ω ×ˢ Icc 0 T)

open Filter Topology

lemma heat_second_deriv_nonpos_of_isLocalMax {g : ℝ → ℝ} (hmax : IsLocalMax g 0)
    (hc : ContinuousAt g 0) : deriv (deriv g) 0 ≤ 0 := by
  by_contra h
  push Not at h
  have hmin := isLocalMin_of_deriv_deriv_pos h hmax.deriv_eq_zero hc
  have heq : g =ᶠ[𝓝 0] fun _ => g 0 := by
    filter_upwards [hmax, hmin] with y h1 h2
    exact le_antisymm h1 h2
  have h2 : deriv g =ᶠ[𝓝 0] fun _ => 0 := by
    filter_upwards [heq.eventuallyEq_nhds] with y hy
    rw [hy.deriv_eq]
    simp
  rw [h2.deriv_eq] at h
  simp at h

#print axioms heat_second_deriv_nonpos_of_isLocalMax

lemma heat_second_deriv_line {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : E → ℝ} {x : E} (w : E) (hf : ContDiffAt ℝ 2 f x) :
    deriv (deriv (fun s : ℝ => f (x + s • w))) 0 = iteratedFDeriv ℝ 2 f x ![w, w] := by
  have h1 : ∀ᶠ z in 𝓝 x, DifferentiableAt ℝ f z := by
    filter_upwards [hf.eventually (by simp)] with z hz
    exact hz.differentiableAt (by norm_num)
  have hline : ∀ s : ℝ, HasDerivAt (fun s : ℝ => x + s • w) w s := by
    intro s
    simpa using ((hasDerivAt_id s).smul_const w).const_add x
  have hlim : Tendsto (fun s : ℝ => x + s • w) (𝓝 0) (𝓝 x) := by
    have := (hline 0).continuousAt.tendsto
    simpa using this
  have h2 : ∀ᶠ s in 𝓝 (0:ℝ), DifferentiableAt ℝ f (x + s • w) := hlim.eventually h1
  have h3 : deriv (fun s : ℝ => f (x + s • w)) =ᶠ[𝓝 0] fun s => fderiv ℝ f (x + s • w) w := by
    filter_upwards [h2] with s hs
    exact (hs.hasFDerivAt.comp_hasDerivAt s (hline s)).deriv
  rw [Filter.EventuallyEq.deriv_eq h3]
  have h4 : DifferentiableAt ℝ (fderiv ℝ f) x :=
    (hf.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
  have h5 : HasDerivAt (fun s : ℝ => fderiv ℝ f (x + s • w)) (fderiv ℝ (fderiv ℝ f) x w) 0 :=
    h4.hasFDerivAt.comp_hasDerivAt_of_eq 0 (hline 0) (by simp)
  have h6 := h5.clm_apply (hasDerivAt_const (0:ℝ) w)
  simp only [zero_smul, add_zero, map_zero] at h6
  rw [h6.deriv, iteratedFDeriv_two_apply]
  simp

#print axioms heat_second_deriv_line

lemma heat_laplacian_nonpos_of_isLocalMax {d : ℕ} {f : EuclideanSpace ℝ (Fin d) → ℝ}
    {x : EuclideanSpace ℝ (Fin d)} (hf : ContDiffAt ℝ 2 f x) (hmax : IsLocalMax f x) :
    Δ f x ≤ 0 := by
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis f
    (EuclideanSpace.basisFun (Fin d) ℝ)]
  apply Finset.sum_nonpos
  intro i _
  rw [← heat_second_deriv_line _ hf]
  have hc : Continuous (fun s : ℝ => x + s • (EuclideanSpace.basisFun (Fin d) ℝ) i) := by
    fun_prop
  apply heat_second_deriv_nonpos_of_isLocalMax
  · have : IsLocalMax f ((fun s : ℝ => x + s • (EuclideanSpace.basisFun (Fin d) ℝ) i) 0) := by
      simpa using hmax
    exact IsLocalMax.comp_continuous (g := fun s : ℝ => x + s • (EuclideanSpace.basisFun (Fin d) ℝ) i)
      this hc.continuousAt
  · exact (hf.continuousAt.comp_of_eq hc.continuousAt (by simp))

#print axioms heat_laplacian_nonpos_of_isLocalMax

lemma heat_deriv_nonneg_of_max {f : ℝ → ℝ} {f' a b t : ℝ} (hat : a < t) (htb : t ≤ b)
    (hf : HasDerivWithinAt f f' (Icc a b) t) (hmax : ∀ s ∈ Icc a b, f s ≤ f t) : 0 ≤ f' := by
  have hloc : IsLocalMaxOn f (Icc a b) t := Filter.eventually_of_mem self_mem_nhdsWithin hmax
  have hseg : segment ℝ t a ⊆ Icc a b := by
    rw [segment_symm, segment_eq_Icc hat.le]
    exact Icc_subset_Icc le_rfl htb
  have hy := sub_mem_posTangentConeAt_of_segment_subset hseg
  have := hloc.hasFDerivWithinAt_nonpos hf hy
  simp at this
  nlinarith

#print axioms heat_deriv_nonneg_of_max

lemma heat_gauss_line (b c N p : ℝ) :
    deriv (deriv fun s : ℝ => Real.exp (b * (N + 2 * s * p + s ^ 2) + c)) 0 =
      Real.exp (b * N + c) * (4 * b ^ 2 * p ^ 2 + 2 * b) := by
  have hd1 : ∀ s, HasDerivAt (fun s : ℝ => Real.exp (b * (N + 2 * s * p + s ^ 2) + c))
      (Real.exp (b * (N + 2 * s * p + s ^ 2) + c) * (b * (2 * p + 2 * s))) s := by
    intro s
    have hP : HasDerivAt (fun s : ℝ => b * (N + 2 * s * p + s ^ 2) + c) (b * (2 * p + 2 * s)) s := by
      have := (((((hasDerivAt_id' s).const_mul 2).mul_const p).const_add N).add
        (hasDerivAt_pow 2 s)).const_mul b |>.add_const c
      convert this using 1
      norm_num
    exact hP.exp
  have hderiv : deriv (fun s : ℝ => Real.exp (b * (N + 2 * s * p + s ^ 2) + c)) =
      fun s => Real.exp (b * (N + 2 * s * p + s ^ 2) + c) * (b * (2 * p + 2 * s)) :=
    funext fun s => (hd1 s).deriv
  have h' : HasDerivAt (fun s : ℝ => b * (2 * p + 2 * s)) (b * 2) 0 := by
    have := (((hasDerivAt_id' (0:ℝ)).const_mul 2).const_add (2 * p)).const_mul b
    convert this using 1
    ring
  have hd2 : HasDerivAt
      (fun s => Real.exp (b * (N + 2 * s * p + s ^ 2) + c) * (b * (2 * p + 2 * s))) _ 0 :=
    (hd1 0).mul h'
  rw [hderiv, hd2.deriv]
  simp only [mul_zero, zero_mul, add_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true,
    zero_pow]
  ring

#print axioms heat_gauss_line

lemma heat_laplacian_gauss {d : ℕ} (b c : ℝ) (y : EuclideanSpace ℝ (Fin d)) :
    Δ (fun x : EuclideanSpace ℝ (Fin d) => Real.exp (b * ‖x‖ ^ 2 + c)) y =
      Real.exp (b * ‖y‖ ^ 2 + c) * (4 * b ^ 2 * ‖y‖ ^ 2 + 2 * b * d) := by
  have hcd : ContDiffAt ℝ 2 (fun x : EuclideanSpace ℝ (Fin d) => Real.exp (b * ‖x‖ ^ 2 + c)) y :=
    ((contDiff_const.mul (contDiff_norm_sq ℝ)).add contDiff_const).exp.contDiffAt
  have key : ∀ e : EuclideanSpace ℝ (Fin d), ‖e‖ = 1 →
      deriv (deriv fun s : ℝ => Real.exp (b * ‖y + s • e‖ ^ 2 + c)) 0 =
        Real.exp (b * ‖y‖ ^ 2 + c) * (4 * b ^ 2 * (inner ℝ y e) ^ 2 + 2 * b) := by
    intro e he
    have hfun : (fun s : ℝ => Real.exp (b * ‖y + s • e‖ ^ 2 + c)) =
        fun s => Real.exp (b * (‖y‖ ^ 2 + 2 * s * inner ℝ y e + s ^ 2) + c) := by
      funext s
      rw [norm_add_sq_real, real_inner_smul_right, norm_smul, he]
      simp only [Real.norm_eq_abs, mul_one, sq_abs]
      ring_nf
    rw [hfun, heat_gauss_line]
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis _
    (EuclideanSpace.basisFun (Fin d) ℝ)]
  simp only
  rw [Finset.sum_congr rfl fun i _ => (heat_second_deriv_line _ hcd).symm]
  rw [Finset.sum_congr rfl fun i _ => key _ ((EuclideanSpace.basisFun (Fin d) ℝ).orthonormal.1 i)]
  rw [← Finset.mul_sum, Finset.sum_add_distrib, ← Finset.mul_sum,
    (EuclideanSpace.basisFun (Fin d) ℝ).sum_sq_inner_left y]
  simp
  ring

#print axioms heat_laplacian_gauss

lemma heat_wmp_interval {d : ℕ} (κ : ℝ) (hκ : 0 < κ)
    (Ω : Set (EuclideanSpace ℝ (Fin d))) (hΩ : IsOpen Ω) (hΩb : Bornology.IsBounded Ω)
    (t₀ t₁ : ℝ) (u ut : EuclideanSpace ℝ (Fin d) → ℝ → ℝ)
    (hcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2)
      (closure Ω ×ˢ Icc t₀ t₁))
    (hspace : ∀ t ∈ Ioc t₀ t₁, ContDiffOn ℝ 2 (fun x => u x t) Ω)
    (htime : ∀ x ∈ Ω, ∀ t ∈ Ioc t₀ t₁, HasDerivWithinAt (fun s => u x s) (ut x t) (Icc t₀ t₁) t)
    (hsub : ∀ x ∈ Ω, ∀ t ∈ Ioc t₀ t₁, ut x t - κ * Δ (fun y => u y t) x ≤ 0)
    (M : ℝ) (hstart : ∀ x ∈ closure Ω, u x t₀ ≤ M)
    (hside : ∀ x ∈ frontier Ω, ∀ t ∈ Icc t₀ t₁, u x t ≤ M) :
    ∀ x ∈ closure Ω, ∀ t ∈ Icc t₀ t₁, u x t ≤ M := by
  intro x0 hx0 t0 ht0
  by_contra hcon
  push Not at hcon
  have hL : 0 ≤ t₁ - t₀ := by linarith [ht0.1, ht0.2]
  set ε := (u x0 t0 - M) / (2 * (t₁ - t₀ + 1)) with hε
  have hεpos : 0 < ε := by apply div_pos <;> linarith
  have hεL : ε * (t₁ - t₀) < u x0 t0 - M := by
    rw [hε, div_mul_eq_mul_div, div_lt_iff₀ (by linarith)]
    nlinarith
  have hKc : IsCompact (closure Ω ×ˢ Icc t₀ t₁) := hΩb.isCompact_closure.prod isCompact_Icc
  have hwc : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2 - ε * (p.2 - t₀))
      (closure Ω ×ˢ Icc t₀ t₁) :=
    hcont.sub (by fun_prop)
  obtain ⟨p, hpK, hpmax⟩ := hKc.exists_isMaxOn ⟨(x0, t0), hx0, ht0⟩ hwc
  have hmax : ∀ q ∈ closure Ω ×ˢ Icc t₀ t₁, u q.1 q.2 - ε * (q.2 - t₀) ≤ u p.1 p.2 - ε * (p.2 - t₀) :=
    fun q hq => hpmax hq
  have hge := hmax (x0, t0) ⟨hx0, ht0⟩
  simp only at hge
  have hgt : M < u p.1 p.2 - ε * (p.2 - t₀) := by
    have : ε * (t0 - t₀) ≤ ε * (t₁ - t₀) := mul_le_mul_of_nonneg_left (by linarith [ht0.2]) hεpos.le
    linarith
  obtain ⟨hp1, hp2⟩ := hpK
  have hp2' : t₀ < p.2 := by
    rcases eq_or_lt_of_le hp2.1 with h | h
    · exfalso
      rw [← h] at hgt
      have := hstart p.1 hp1
      simp at hgt
      linarith
    · exact h
  have hp1' : p.1 ∈ Ω := by
    by_contra hn
    have hfr : p.1 ∈ frontier Ω := by
      rw [frontier, hΩ.interior_eq]
      exact ⟨hp1, hn⟩
    have := hside p.1 hfr p.2 hp2
    have : 0 ≤ ε * (p.2 - t₀) := mul_nonneg hεpos.le (by linarith)
    linarith
  have hpt : p.2 ∈ Ioc t₀ t₁ := ⟨hp2', hp2.2⟩
  have hlap : Δ (fun y => u y p.2) p.1 ≤ 0 := by
    apply heat_laplacian_nonpos_of_isLocalMax ((hspace p.2 hpt).contDiffAt (hΩ.mem_nhds hp1'))
    filter_upwards [hΩ.mem_nhds hp1'] with y hy
    have := hmax (y, p.2) ⟨subset_closure hy, hp2⟩
    simp only at this
    linarith
  have htd : 0 ≤ ut p.1 p.2 - ε := by
    apply heat_deriv_nonneg_of_max (a := t₀) (b := t₁) (t := p.2) hp2' hp2.2
      (f := fun s => u p.1 s - ε * (s - t₀))
    · have h2 : HasDerivWithinAt (fun s => ε * (s - t₀)) ε (Icc t₀ t₁) p.2 := by
        have := (((hasDerivAt_id' p.2).sub_const t₀).const_mul ε).hasDerivWithinAt (s := Icc t₀ t₁)
        convert this using 1
        ring
      exact (htime p.1 hp1' p.2 hpt).sub h2
    · intro s hs
      exact hmax (p.1, s) ⟨hp1, hs⟩
  have := hsub p.1 hp1' p.2 hpt
  nlinarith

#print axioms heat_wmp_interval

lemma heat_gauss_super {d : ℕ} (κ b c g C : ℝ)
    (hg : 4 * κ * b ^ 2 ≤ g) (hC : 2 * κ * b * d ≤ C) (x : EuclideanSpace ℝ (Fin d)) :
    κ * Δ (fun y : EuclideanSpace ℝ (Fin d) => Real.exp (b * ‖y‖ ^ 2 + c)) x ≤
      Real.exp (b * ‖x‖ ^ 2 + c) * (g * ‖x‖ ^ 2 + C) := by
  rw [heat_laplacian_gauss]
  have hE := Real.exp_pos (b * ‖x‖ ^ 2 + c)
  have : κ * (4 * b ^ 2 * ‖x‖ ^ 2 + 2 * b * d) ≤ g * ‖x‖ ^ 2 + C := by
    have := mul_le_mul_of_nonneg_right hg (sq_nonneg ‖x‖)
    nlinarith
  calc κ * (Real.exp (b * ‖x‖ ^ 2 + c) * (4 * b ^ 2 * ‖x‖ ^ 2 + 2 * b * d))
      = Real.exp (b * ‖x‖ ^ 2 + c) * (κ * (4 * b ^ 2 * ‖x‖ ^ 2 + 2 * b * d)) := by ring
    _ ≤ Real.exp (b * ‖x‖ ^ 2 + c) * (g * ‖x‖ ^ 2 + C) :=
      mul_le_mul_of_nonneg_left this hE.le

#print axioms heat_gauss_super

lemma heat_gauss_hasDerivAt (β γ C t₀ N t : ℝ) :
    HasDerivAt (fun s => Real.exp ((β + γ * (s - t₀)) * N + C * (s - t₀)))
      (Real.exp ((β + γ * (t - t₀)) * N + C * (t - t₀)) * (γ * N + C)) t := by
  have h : HasDerivAt (fun s => (β + γ * (s - t₀)) * N + C * (s - t₀)) (γ * N + C) t := by
    have h1 := ((((hasDerivAt_id' t).sub_const t₀).const_mul γ).const_add β).mul_const N
    have h2 := ((hasDerivAt_id' t).sub_const t₀).const_mul C
    convert h1.add h2 using 1
    ring
  exact h.exp

#print axioms heat_gauss_hasDerivAt

lemma heat_whole_step {d : ℕ} (κ T : ℝ) (hκ : 0 < κ)
    (u ut : EuclideanSpace ℝ (Fin d) → ℝ → ℝ)
    (hcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2)
      (univ ×ˢ Icc 0 T))
    (hspace : ∀ t ∈ Ioc 0 T, ContDiff ℝ 2 (fun x => u x t))
    (htime : ∀ x, ∀ t ∈ Ioc 0 T, HasDerivWithinAt (fun s => u x s) (ut x t) (Icc 0 T) t)
    (heq : ∀ x, ∀ t ∈ Ioc 0 T, ut x t = κ * Δ (fun y => u y t) x)
    (A a : ℝ) (ha : 0 ≤ a)
    (hgrowth : ∀ x, ∀ t ∈ Icc 0 T, u x t ≤ A * Real.exp (a * ‖x‖ ^ 2))
    (M t₀ t₁ : ℝ) (h0 : 0 ≤ t₀) (h01 : t₀ ≤ t₁) (h1T : t₁ ≤ T)
    (hτ : t₁ - t₀ ≤ 1 / (16 * κ * (a + 1)))
    (hstart : ∀ x, u x t₀ ≤ M) :
    ∀ x, u x t₁ ≤ M := by
  intro x0
  set β := a + 1 with hβ
  have hβpos : 0 < β := by linarith
  set γ := 16 * κ * β ^ 2 with hγ
  set C := 4 * κ * β * d with hC
  have hγpos : 0 ≤ γ := by positivity
  have hCpos : 0 ≤ C := by positivity
  -- the bound on the coefficient b(t) = β + γ (t - t₀)
  have hb : ∀ t ∈ Icc t₀ t₁, β ≤ β + γ * (t - t₀) ∧ β + γ * (t - t₀) ≤ 2 * β := by
    intro t ht
    have h1 : 0 ≤ t - t₀ := by linarith [ht.1]
    have h2 : t - t₀ ≤ 1 / (16 * κ * β) := by linarith [ht.2]
    refine ⟨by nlinarith, ?_⟩
    have h3 : γ * (t - t₀) ≤ γ * (1 / (16 * κ * β)) := mul_le_mul_of_nonneg_left h2 hγpos
    have h4 : γ * (1 / (16 * κ * β)) = β := by
      rw [hγ]
      field_simp
    linarith
  have key : ∀ μ : ℝ, 0 < μ → u x0 t₁ - μ * Real.exp ((β + γ * (t₁ - t₀)) * ‖x0‖ ^ 2 +
      C * (t₁ - t₀)) ≤ M := by
    intro μ hμ
    set R := max (‖x0‖ + 1) ((A + |M|) / μ) with hR
    have hR1 : ‖x0‖ + 1 ≤ R := le_max_left _ _
    have hR2 : (A + |M|) / μ ≤ R := le_max_right _ _
    have hRpos : 0 < R := by linarith [norm_nonneg x0]
    have hR1' : 1 ≤ R := by linarith [norm_nonneg x0]
    have hball := heat_wmp_interval κ hκ (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) R)
      Metric.isOpen_ball Metric.isBounded_ball t₀ t₁
      (fun x t => u x t - μ * Real.exp ((β + γ * (t - t₀)) * ‖x‖ ^ 2 + C * (t - t₀)))
      (fun x t => ut x t - μ * (Real.exp ((β + γ * (t - t₀)) * ‖x‖ ^ 2 + C * (t - t₀)) *
        (γ * ‖x‖ ^ 2 + C)))
      (by
        apply ContinuousOn.sub
        · exact hcont.mono (prod_mono (subset_univ _) (Icc_subset_Icc h0 h1T))
        · exact Continuous.continuousOn (by fun_prop))
      (by
        intro t ht
        have hφ : ContDiff ℝ 2 (fun x : EuclideanSpace ℝ (Fin d) =>
            Real.exp ((β + γ * (t - t₀)) * ‖x‖ ^ 2 + C * (t - t₀))) :=
          ((contDiff_const.mul (contDiff_norm_sq ℝ)).add contDiff_const).exp
        exact ((hspace t ⟨by linarith [ht.1], by linarith [ht.2]⟩).sub
          (contDiff_const.mul hφ)).contDiffOn)
      (by
        intro x _ t ht
        have h1 := (htime x t ⟨by linarith [ht.1], by linarith [ht.2]⟩).mono
          (Icc_subset_Icc h0 h1T)
        have h2 := ((heat_gauss_hasDerivAt β γ C t₀ (‖x‖ ^ 2) t).const_mul μ).hasDerivWithinAt
          (s := Icc t₀ t₁)
        exact h1.sub h2)
      (by
        intro x _ t ht
        have htT : t ∈ Ioc 0 T := ⟨by linarith [ht.1], by linarith [ht.2]⟩
        have h1 : ContDiffAt ℝ 2 (fun y => u y t) x := (hspace t htT).contDiffAt
        have hφ : ContDiff ℝ 2 (fun x : EuclideanSpace ℝ (Fin d) =>
            Real.exp ((β + γ * (t - t₀)) * ‖x‖ ^ 2 + C * (t - t₀))) :=
          ((contDiff_const.mul (contDiff_norm_sq ℝ)).add contDiff_const).exp
        have e : (fun y => u y t - μ * Real.exp ((β + γ * (t - t₀)) * ‖y‖ ^ 2 + C * (t - t₀))) =
            (fun y => u y t) - μ • (fun y : EuclideanSpace ℝ (Fin d) =>
              Real.exp ((β + γ * (t - t₀)) * ‖y‖ ^ 2 + C * (t - t₀))) := by
          funext y
          simp [smul_eq_mul]
        have h2 : ContDiffAt ℝ 2 (μ • fun y : EuclideanSpace ℝ (Fin d) =>
            Real.exp ((β + γ * (t - t₀)) * ‖y‖ ^ 2 + C * (t - t₀))) x :=
          (hφ.contDiffAt).const_smul μ
        rw [e, h1.laplacian_sub h2,
          InnerProductSpace.laplacian_smul μ hφ.contDiffAt]
        simp only [smul_eq_mul]
        have hbt := hb t ⟨ht.1.le, ht.2⟩
        have hsup := heat_gauss_super κ (β + γ * (t - t₀)) (C * (t - t₀)) γ C
          (by
            have hb0 : 0 ≤ β + γ * (t - t₀) := by linarith [hbt.1]
            have hsq : (β + γ * (t - t₀)) ^ 2 ≤ (2 * β) ^ 2 := pow_le_pow_left₀ hb0 hbt.2 2
            rw [hγ]
            nlinarith) (by
            have : (0:ℝ) ≤ d := Nat.cast_nonneg d
            rw [hC]
            nlinarith) x
        have hq := heq x t htT
        have := mul_le_mul_of_nonneg_left hsup hμ.le
        nlinarith)
      M
      (by
        intro x _
        have := hstart x
        have hp := Real.exp_pos ((β + γ * (t₀ - t₀)) * ‖x‖ ^ 2 + C * (t₀ - t₀))
        nlinarith)
      (by
        intro x hx t ht
        rw [frontier_ball _ hRpos.ne', mem_sphere_zero_iff_norm] at hx
        have hu := hgrowth x t ⟨by linarith [ht.1], by linarith [ht.2]⟩
        rw [hx] at hu ⊢
        have hbt := hb t ht
        have hexp1 : Real.exp (β * R ^ 2) ≤
            Real.exp ((β + γ * (t - t₀)) * R ^ 2 + C * (t - t₀)) := by
          apply Real.exp_le_exp.2
          have : 0 ≤ C * (t - t₀) := mul_nonneg hCpos (by linarith [ht.1])
          nlinarith [sq_nonneg R]
        have hsplit : Real.exp (β * R ^ 2) = Real.exp (a * R ^ 2) * Real.exp (R ^ 2) := by
          rw [← Real.exp_add]
          congr 1
          rw [hβ]
          ring
        have hE1 : 1 ≤ Real.exp (a * R ^ 2) := Real.one_le_exp (by positivity)
        have hE2 : R ^ 2 + 1 ≤ Real.exp (R ^ 2) := Real.add_one_le_exp _
        have hRR : R ≤ R ^ 2 := by nlinarith
        have hμR : A + |M| ≤ μ * Real.exp (R ^ 2) := by
          have : A + |M| ≤ μ * R := by
            rw [div_le_iff₀ hμ] at hR2
            linarith
          nlinarith
        have hM := neg_abs_le M
        have hMabs := abs_nonneg M
        have h5 : A * Real.exp (a * R ^ 2) - μ * Real.exp (β * R ^ 2) ≤ M := by
          rw [hsplit]
          nlinarith
        have h6 := mul_le_mul_of_nonneg_left hexp1 hμ.le
        linarith)
    exact hball x0 (subset_closure (by
      rw [mem_ball_zero_iff]
      linarith)) t₁ ⟨h01, le_rfl⟩
  set K := Real.exp ((β + γ * (t₁ - t₀)) * ‖x0‖ ^ 2 + C * (t₁ - t₀)) with hK
  have hKpos : 0 < K := Real.exp_pos _
  apply le_of_forall_pos_le_add
  intro ε hε
  have := key (ε / K) (div_pos hε hKpos)
  rw [div_mul_cancel₀ _ hKpos.ne'] at this
  linarith

#print axioms heat_whole_step

/-- The weak maximum principle for the heat equation in `d` space directions. Let `Ω` be a
bounded open region and `κ > 0` (time runs forward). Let `u` be continuous on the closed box
`Ω̄ × [0, T]`, twice differentiable in space and once in time inside the box `Ω × (0, T]`
(the time derivative `ut` taken within `[0, T]`, so from the past at the lid `t = T`), with no
heat source inside: `u_t - κ Δu ≤ 0`. If `u ≤ M` on the parabolic boundary (the start and the
sides), then `u ≤ M` on the whole closed box: the largest value over the whole history sits on
the start or on the sides. -/
theorem heat_weak_maximum_principle {d : ℕ} (κ T : ℝ) (hκ : 0 < κ)
    (Ω : Set (EuclideanSpace ℝ (Fin d))) (hΩ : IsOpen Ω) (hΩb : Bornology.IsBounded Ω)
    (u ut : EuclideanSpace ℝ (Fin d) → ℝ → ℝ)
    (hcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2)
      (closure Ω ×ˢ Icc 0 T))
    (hspace : ∀ t ∈ Ioc 0 T, ContDiffOn ℝ 2 (fun x => u x t) Ω)
    (htime : ∀ x ∈ Ω, ∀ t ∈ Ioc 0 T, HasDerivWithinAt (fun s => u x s) (ut x t) (Icc 0 T) t)
    (hsub : ∀ x ∈ Ω, ∀ t ∈ Ioc 0 T, ut x t - κ * Δ (fun y => u y t) x ≤ 0)
    (M : ℝ) (hΓ : ∀ p ∈ parabolicBoundary Ω T, u p.1 p.2 ≤ M) :
    ∀ x ∈ closure Ω, ∀ t ∈ Icc 0 T, u x t ≤ M := by
  apply heat_wmp_interval κ hκ Ω hΩ hΩb 0 T u ut hcont hspace htime hsub M
  · intro x hx
    exact hΓ (x, 0) (Or.inl ⟨hx, rfl⟩)
  · intro x hx t ht
    exact hΓ (x, t) (Or.inr ⟨hx, ht⟩)

/-- The comparison principle. Under the same conditions on a bounded open region with `κ > 0`:
if `u` is heated no more than `v` inside, `u_t - κ Δu ≤ v_t - κ Δv`, and `u ≤ v` on the start
and the sides, then `u ≤ v` everywhere on the closed box. A temperature that starts no higher,
is held no higher on the sides and is heated no more inside, stays no higher. -/
theorem heat_comparison_principle {d : ℕ} (κ T : ℝ) (hκ : 0 < κ)
    (Ω : Set (EuclideanSpace ℝ (Fin d))) (hΩ : IsOpen Ω) (hΩb : Bornology.IsBounded Ω)
    (u ut v vt : EuclideanSpace ℝ (Fin d) → ℝ → ℝ)
    (hucont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2)
      (closure Ω ×ˢ Icc 0 T))
    (hvcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => v p.1 p.2)
      (closure Ω ×ˢ Icc 0 T))
    (huspace : ∀ t ∈ Ioc 0 T, ContDiffOn ℝ 2 (fun x => u x t) Ω)
    (hvspace : ∀ t ∈ Ioc 0 T, ContDiffOn ℝ 2 (fun x => v x t) Ω)
    (hutime : ∀ x ∈ Ω, ∀ t ∈ Ioc 0 T, HasDerivWithinAt (fun s => u x s) (ut x t) (Icc 0 T) t)
    (hvtime : ∀ x ∈ Ω, ∀ t ∈ Ioc 0 T, HasDerivWithinAt (fun s => v x s) (vt x t) (Icc 0 T) t)
    (hheat : ∀ x ∈ Ω, ∀ t ∈ Ioc 0 T,
      ut x t - κ * Δ (fun y => u y t) x ≤ vt x t - κ * Δ (fun y => v y t) x)
    (hΓ : ∀ p ∈ parabolicBoundary Ω T, u p.1 p.2 ≤ v p.1 p.2) :
    ∀ x ∈ closure Ω, ∀ t ∈ Icc 0 T, u x t ≤ v x t := by
  intro x hx t ht
  have key := heat_weak_maximum_principle κ T hκ Ω hΩ hΩb (fun x t => u x t - v x t)
    (fun x t => ut x t - vt x t) (hucont.sub hvcont)
    (fun t ht => (huspace t ht).sub (hvspace t ht))
    (fun x hx t ht => (hutime x hx t ht).sub (hvtime x hx t ht))
    (by
      intro x hx t ht
      have h1 := ((huspace t ht).contDiffAt (hΩ.mem_nhds hx))
      have h2 := ((hvspace t ht).contDiffAt (hΩ.mem_nhds hx))
      have e : (fun y => u y t - v y t) = (fun y => u y t) - (fun y => v y t) := rfl
      rw [e, h1.laplacian_sub h2]
      have := hheat x hx t ht
      linarith)
    0 (fun p hp => by simpa using hΓ p hp) x hx t ht
  linarith

/-- The endless rod, in `d` space directions: on the whole space there are no sides, only the
start. If `u` solves the heat equation `u_t = κ Δu` with `κ > 0` for `0 < t ≤ T`, is continuous
down to `t = 0`, and obeys the growth condition `u(x, t) ≤ A e^(a |x|²)` for some constants `A`
and `a`, then `u` is never larger than any upper bound `M` of its start: the supremum over the
whole history equals the supremum of the start. -/
theorem heat_maximum_principle_whole_space_of_growth {d : ℕ} (κ T : ℝ) (hκ : 0 < κ)
    (u ut : EuclideanSpace ℝ (Fin d) → ℝ → ℝ)
    (hcont : ContinuousOn (fun p : EuclideanSpace ℝ (Fin d) × ℝ => u p.1 p.2)
      (univ ×ˢ Icc 0 T))
    (hspace : ∀ t ∈ Ioc 0 T, ContDiff ℝ 2 (fun x => u x t))
    (htime : ∀ x, ∀ t ∈ Ioc 0 T, HasDerivWithinAt (fun s => u x s) (ut x t) (Icc 0 T) t)
    (heq : ∀ x, ∀ t ∈ Ioc 0 T, ut x t = κ * Δ (fun y => u y t) x)
    (A a : ℝ) (hgrowth : ∀ x, ∀ t ∈ Icc 0 T, u x t ≤ A * Real.exp (a * ‖x‖ ^ 2))
    (M : ℝ) (hstart : ∀ x, u x 0 ≤ M) :
    ∀ x, ∀ t ∈ Icc 0 T, u x t ≤ M := by
  have hgrowth' : ∀ x, ∀ t ∈ Icc 0 T,
      u x t ≤ max A 0 * Real.exp (max a 0 * ‖x‖ ^ 2) := by
    intro x t ht
    have h1 : Real.exp (a * ‖x‖ ^ 2) ≤ Real.exp (max a 0 * ‖x‖ ^ 2) :=
      Real.exp_le_exp.2 (mul_le_mul_of_nonneg_right (le_max_left _ _) (by positivity))
    have h2 := hgrowth x t ht
    rcases le_or_gt 0 A with hA | hA
    · rw [max_eq_left hA]
      exact h2.trans (mul_le_mul_of_nonneg_left h1 hA)
    · rw [max_eq_right hA.le, zero_mul]
      nlinarith [Real.exp_pos (a * ‖x‖ ^ 2)]
  set τ := 1 / (16 * κ * (max a 0 + 1)) with hτ
  have hτpos : 0 < τ := by
    have : 0 < max a 0 + 1 := by linarith [le_max_right a 0]
    positivity
  have key : ∀ n : ℕ, ∀ x, ∀ t ∈ Icc 0 T, t ≤ n * τ → u x t ≤ M := by
    intro n
    induction n with
    | zero =>
      intro x t ht hle
      have : t = 0 := by simp at hle; linarith [ht.1]
      rw [this]
      exact hstart x
    | succ n ih =>
      intro x t ht hle
      by_cases h : t ≤ n * τ
      · exact ih x t ht h
      · push Not at h
        have hn0 : 0 ≤ (n : ℝ) * τ := by positivity
        exact heat_whole_step κ T hκ u ut hcont hspace htime heq (max A 0) (max a 0)
          (le_max_right _ _) hgrowth' M (n * τ) t hn0 h.le ht.2
          (by push_cast at hle; rw [← hτ]; linarith)
          (fun y => ih y (n * τ) ⟨hn0, by linarith [ht.2]⟩ le_rfl) x
  intro x t ht
  obtain ⟨n, hn⟩ := exists_nat_ge (t / τ)
  exact key n x t ht (by rwa [div_le_iff₀ hτpos] at hn)

-- The tent start at x = 0.45 m: 20 + 80 (1 - 0.05/0.1) = 60 C.
example : (20 : ℚ) + 80 * (1 - |(45 / 100 : ℚ) - 1 / 2| / (1 / 10)) = 60 := by norm_num [abs_of_neg]
-- The tent's peak at x = 0.5 m is 100 C, the hottest point of the parabolic boundary.
example : (20 : ℚ) + 80 * (1 - |(1 / 2 : ℚ) - 1 / 2| / (1 / 10)) = 100 := by norm_num
-- The scaled time unit: (1 m)^2 over copper's κ = 1/9009 m^2/s is 9009 s.
example : (1 : ℚ) / (1 / 9009) = 9009 := by norm_num
-- Tychonoff's g = e^(-1/t^2): g'/g = 2/t^3, which is 16 at t = 1/2 (scaled).
example : (2 : ℚ) / (1 / 2) ^ 3 = 16 := by norm_num
-- Tychonoff's g''/g = 4/t^6 - 6/t^4, which is 256 - 96 = 160 at t = 1/2 (scaled).
example : (4 : ℚ) / (1 / 2) ^ 6 - 6 / (1 / 2) ^ 4 = 160 := by norm_num

#print axioms heat_weak_maximum_principle
#print axioms heat_comparison_principle
#print axioms heat_maximum_principle_whole_space_of_growth
