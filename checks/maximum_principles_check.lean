-- Maximum principles: for an elliptic operator with no gain from its surroundings, a solution with no net heating inside never exceeds the larger of its highest boundary value and zero, so lower on the boundary and heated less inside means lower everywhere, and a hand-built bowl caps a heated solution.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Analysis.Calculus.DerivativeTest
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Tactic.NormNum

/-! The region `Ω` is an open, bounded set in `d`-dimensional space `EuclideanSpace ℝ (Fin d)`,
with `d ≥ 1`. Its boundary (the rim) is `frontier Ω` and the closed region is `closure Ω`.
Temperatures are rises above the room, so the room is `0`.

The slope of `u` in direction `i` at `x` is `fderiv ℝ u x eᵢ`, and its second derivative in
directions `i` and `j` is `iteratedFDeriv ℝ 2 u x ![eᵢ, eⱼ]`, where `eᵢ` is the `i`-th unit vector
`EuclideanSpace.single i 1`. The card's operator is

  `L u = - ∑ᵢⱼ aᵢⱼ(x) u_ij + ∑ᵢ bᵢ(x) u_i + c(x) u`. -/

open InnerProductSpace Laplacian


/-- The general second-order operator of the card:
`L u (x) = - ∑ᵢⱼ aᵢⱼ(x) u_ij(x) + ∑ᵢ bᵢ(x) u_i(x) + c(x) u(x)`. -/
noncomputable def ellipticOp {d : ℕ} (a : EuclideanSpace ℝ (Fin d) → Fin d → Fin d → ℝ)
    (b : EuclideanSpace ℝ (Fin d) → Fin d → ℝ) (c : EuclideanSpace ℝ (Fin d) → ℝ)
    (u : EuclideanSpace ℝ (Fin d) → ℝ) (x : EuclideanSpace ℝ (Fin d)) : ℝ :=
  -(∑ i, ∑ j, a x i j *
      iteratedFDeriv ℝ 2 u x ![EuclideanSpace.single i 1, EuclideanSpace.single j 1])
    + ∑ i, b x i * fderiv ℝ u x (EuclideanSpace.single i 1) + c x * u x

open Matrix in
theorem mp_trace_nonpos {d : ℕ} (A H : Matrix (Fin d) (Fin d) ℝ) (hH : H.IsHermitian)
    (hHneg : ∀ ξ : Fin d → ℝ, ∑ i, ∑ j, H i j * ξ i * ξ j ≤ 0)
    (hA : ∀ ξ : Fin d → ℝ, 0 ≤ ∑ i, ∑ j, A i j * ξ i * ξ j) :
    ∑ i, ∑ j, A i j * H i j ≤ 0 := by
  obtain ⟨U, hU⟩ : ∃ U : Matrix (Fin d) (Fin d) ℝ,
      U = (hH.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ) := ⟨_, rfl⟩
  obtain ⟨μ, hμdef⟩ : ∃ μ : Fin d → ℝ, μ = hH.eigenvalues := ⟨_, rfl⟩
  have hspec : H = U * diagonal μ * Uᵀ := by
    have := hH.spectral_theorem
    rw [Unitary.conjStarAlgAut_apply] at this
    rw [hU, hμdef]
    simpa [star_eq_conjTranspose] using this
  have hdiag : diagonal μ = Uᵀ * H * U := by
    have := hH.conjStarAlgAut_star_eigenvectorUnitary
    rw [Unitary.conjStarAlgAut_star_apply] at this
    rw [hU, hμdef]
    simpa [star_eq_conjTranspose] using this.symm
  have hμ : ∀ k, μ k ≤ 0 := by
    intro k
    have h1 : μ k = (Uᵀ * H * U) k k := by rw [← hdiag]; simp
    rw [h1, Matrix.mul_apply]
    have := hHneg (fun i => U i k)
    calc _ = ∑ j, ∑ i, H i j * U i k * U j k := by
            refine Finset.sum_congr rfl fun j _ => ?_
            rw [Matrix.mul_apply, Finset.sum_mul]
            refine Finset.sum_congr rfl fun i _ => ?_
            rw [Matrix.transpose_apply]; ring
      _ = ∑ i, ∑ j, H i j * U i k * U j k := Finset.sum_comm
      _ ≤ 0 := this
  have hentry : ∀ i j, H i j = ∑ k, μ k * (U i k * U j k) := by
    intro i j
    conv_lhs => rw [hspec]
    rw [Matrix.mul_apply]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [Matrix.mul_apply, Matrix.transpose_apply]
    simp only [diagonal_apply, mul_ite, mul_zero, Finset.sum_ite_eq', Finset.mem_univ, ↓reduceIte]
    ring
  calc ∑ i, ∑ j, A i j * H i j = ∑ i, ∑ j, ∑ k, μ k * (A i j * U i k * U j k) := by
        refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
        rw [hentry, Finset.mul_sum]
        exact Finset.sum_congr rfl fun k _ => by ring
    _ = ∑ i, ∑ k, ∑ j, μ k * (A i j * U i k * U j k) :=
        Finset.sum_congr rfl fun i _ => Finset.sum_comm
    _ = ∑ k, ∑ i, ∑ j, μ k * (A i j * U i k * U j k) := Finset.sum_comm
    _ = ∑ k, μ k * ∑ i, ∑ j, A i j * U i k * U j k := by
        simp only [Finset.mul_sum]
    _ ≤ 0 := Finset.sum_nonpos fun k _ => mul_nonpos_of_nonpos_of_nonneg (hμ k) (hA _)

#print axioms mp_trace_nonpos

open Filter Topology in
theorem mp_second_deriv_nonpos {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {v : E → ℝ} {x : E} (hv : ContDiffAt ℝ 2 v x) (hmax : IsLocalMax v x) (ξ : E) :
    fderiv ℝ (fderiv ℝ v) x ξ ξ ≤ 0 := by
  set g : ℝ → ℝ := fun t => v (x + t • ξ) with hg
  have hline : ∀ t : ℝ, HasDerivAt (fun t : ℝ => x + t • ξ) ξ t := fun t => by
    simpa using ((hasDerivAt_id t).smul_const ξ).const_add x
  have hlim : Tendsto (fun t : ℝ => x + t • ξ) (𝓝 0) (𝓝 x) := by
    have := (hline 0).continuousAt.tendsto
    simpa using this
  have hdiff : ∀ᶠ y in 𝓝 x, DifferentiableAt ℝ v y :=
    (hv.eventually (by simp)).mono fun y hy => hy.differentiableAt (by simp)
  have hg' : deriv g =ᶠ[𝓝 0] fun t => fderiv ℝ v (x + t • ξ) ξ :=
    (hlim.eventually hdiff).mono fun t ht => (ht.hasFDerivAt.comp_hasDerivAt t (hline t)).deriv
  have hfd : DifferentiableAt ℝ (fderiv ℝ v) x :=
    (hv.fderiv_right (m := 1) (by norm_num)).differentiableAt (by simp)
  have hd2 : deriv (deriv g) 0 = fderiv ℝ (fderiv ℝ v) x ξ ξ := by
    rw [hg'.deriv_eq]
    have h1 : HasDerivAt (fun t : ℝ => fderiv ℝ v (x + t • ξ)) (fderiv ℝ (fderiv ℝ v) x ξ) 0 := by
      have hfd' : HasFDerivAt (fderiv ℝ v) (fderiv ℝ (fderiv ℝ v) x) (x + (0 : ℝ) • ξ) := by
        simpa using hfd.hasFDerivAt
      exact hfd'.comp_hasDerivAt (0 : ℝ) (hline 0)
    exact (h1.clm_apply (hasDerivAt_const 0 ξ)).deriv.trans (by simp)
  have hgmax : IsLocalMax g 0 := by
    have := hlim.eventually hmax
    simpa [IsLocalMax, IsMaxFilter, hg] using this
  have hgcont : ContinuousAt g 0 := by
    have : ContinuousAt v (x + (0 : ℝ) • ξ) := by simpa using hv.continuousAt
    exact ContinuousAt.comp (f := fun t : ℝ => x + t • ξ) this (hline 0).continuousAt
  by_contra hpos
  push Not at hpos
  have hmin := isLocalMin_of_deriv_deriv_pos (by rw [hd2]; exact hpos) hgmax.deriv_eq_zero hgcont
  have heq : g =ᶠ[𝓝 0] fun _ => g 0 :=
    (hmin.and hgmax).mono fun t ht => le_antisymm ht.2 ht.1
  have hd0 : deriv g =ᶠ[𝓝 0] fun _ => 0 :=
    heq.eventuallyEq_nhds.mono fun t ht => by rw [ht.deriv_eq]; simp
  rw [hd0.deriv_eq] at hd2
  simp at hd2
  linarith

#print axioms mp_second_deriv_nonpos

theorem mp_hess_sum_nonpos {d : ℕ} {v : EuclideanSpace ℝ (Fin d) → ℝ}
    {x : EuclideanSpace ℝ (Fin d)} (hv : ContDiffAt ℝ 2 v x) (hmax : IsLocalMax v x)
    (a : Fin d → Fin d → ℝ) (ha : ∀ ξ : Fin d → ℝ, 0 ≤ ∑ i, ∑ j, a i j * ξ i * ξ j) :
    ∑ i, ∑ j, a i j * fderiv ℝ (fderiv ℝ v) x (EuclideanSpace.single i 1)
      (EuclideanSpace.single j 1) ≤ 0 := by
  set B := fderiv ℝ (fderiv ℝ v) x
  have hsymm := (hv.isSymmSndFDerivAt (by simp))
  let H : Matrix (Fin d) (Fin d) ℝ :=
    Matrix.of fun i j => B (EuclideanSpace.single i 1) (EuclideanSpace.single j 1)
  have hH : H.IsHermitian := by
    ext i j
    simp only [H, Matrix.conjTranspose_apply, Matrix.of_apply, star_trivial]
    exact hsymm.eq _ _
  have hneg : ∀ ξ : Fin d → ℝ, ∑ i, ∑ j, H i j * ξ i * ξ j ≤ 0 := by
    intro ξ
    have h := mp_second_deriv_nonpos hv hmax (∑ i, ξ i • EuclideanSpace.single i (1 : ℝ))
    have : B (∑ i, ξ i • EuclideanSpace.single i (1 : ℝ)) (∑ i, ξ i • EuclideanSpace.single i 1)
        = ∑ i, ∑ j, H i j * ξ i * ξ j := by
      simp only [map_sum, map_smul, FunLike.coe_sum, Finset.sum_apply, FunLike.coe_smul, Pi.smul_apply,
        smul_eq_mul, H, Matrix.of_apply, Finset.mul_sum]
      refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
      rw [show B (EuclideanSpace.single j 1) (EuclideanSpace.single i 1)
          = B (EuclideanSpace.single i 1) (EuclideanSpace.single j 1) from hsymm.eq _ _]
      ring
    rw [← this]; exact h
  exact mp_trace_nonpos (Matrix.of a) H hH hneg ha

#print axioms mp_hess_sum_nonpos

/-- The weak maximum principle. Let `L` be elliptic on a bounded open region `Ω`
(`∑ aᵢⱼ ξᵢ ξⱼ ≥ θ |ξ|²` for every direction `ξ`, with a constant `θ > 0`), with a bounded drift `b`
and no gain from the surroundings (`c ≥ 0`). Let `u` have continuous second derivatives inside
and be continuous up to the rim. If `L u ≤ 0` inside (no net heating), then `u` never exceeds
the larger of its highest rim value and the room: any `M ≥ 0` that is at least `u` on the rim is
at least `u` on the whole closed region, that is `max_{Ω̄} u ≤ max_{∂Ω} u⁺`. -/
theorem weak_maximum_principle {d : ℕ} (hd : 1 ≤ d) {Ω : Set (EuclideanSpace ℝ (Fin d))}
    (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω)
    {a : EuclideanSpace ℝ (Fin d) → Fin d → Fin d → ℝ}
    {b : EuclideanSpace ℝ (Fin d) → Fin d → ℝ} {c : EuclideanSpace ℝ (Fin d) → ℝ}
    {θ : ℝ} (hθ : 0 < θ)
    (hell : ∀ x ∈ Ω, ∀ ξ : Fin d → ℝ, θ * ∑ i, ξ i ^ 2 ≤ ∑ i, ∑ j, a x i j * ξ i * ξ j)
    (hb : ∃ B : ℝ, ∀ x ∈ Ω, ∀ i, |b x i| ≤ B)
    (hc : ∀ x ∈ Ω, 0 ≤ c x)
    {u : EuclideanSpace ℝ (Fin d) → ℝ} (hu2 : ContDiffOn ℝ 2 u Ω)
    (hucont : ContinuousOn u (closure Ω))
    (hLu : ∀ x ∈ Ω, ellipticOp a b c u x ≤ 0)
    {M : ℝ} (hM : 0 ≤ M) (hrim : ∀ y ∈ frontier Ω, u y ≤ M) :
    ∀ x ∈ closure Ω, u x ≤ M := by
  intro x₀ hx₀
  by_contra hlt
  push Not at hlt
  obtain ⟨B, hB⟩ := hb
  set i₀ : Fin d := ⟨0, hd⟩
  set lam : ℝ := (|B| + 1) / θ with hlam
  have hlam_pos : 0 < lam := by positivity
  have hlamθ : lam * θ = |B| + 1 := by rw [hlam]; field_simp
  set K := closure Ω
  have hK : IsCompact K := hbdd.isCompact_closure
  set φ : EuclideanSpace ℝ (Fin d) → ℝ := fun y => Real.exp (lam * y i₀) with hφ
  have hφc : Continuous φ := by
    simp only [hφ]; fun_prop
  obtain ⟨W, hW⟩ : ∃ W, ∀ y ∈ K, φ y ≤ W := by
    obtain ⟨W, hW⟩ := hK.bddAbove_image hφc.continuousOn
    exact ⟨W, fun y hy => hW ⟨y, hy, rfl⟩⟩
  have hWpos : 0 < W := lt_of_lt_of_le (Real.exp_pos _) (hW x₀ hx₀)
  set ε : ℝ := (u x₀ - M) / (2 * W) with hε
  have hεpos : 0 < ε := div_pos (by linarith) (by linarith)
  have hεW : ε * W < u x₀ - M := by
    rw [hε]; field_simp; linarith
  set ψ : EuclideanSpace ℝ (Fin d) → ℝ := fun y => ε * Real.exp (lam * y i₀) with hψ
  set v := u + ψ with hv
  have hvcont : ContinuousOn v K := hucont.add (by simp only [hψ]; fun_prop)
  obtain ⟨x, hxK, hxmax⟩ := hK.exists_isMaxOn ⟨x₀, hx₀⟩ hvcont
  have hvx : u x₀ < v x := by
    have h1 := hxmax hx₀
    simp only [Set.mem_ofPred_eq, hv, Pi.add_apply, hψ] at h1 ⊢
    have := Real.exp_pos (lam * x₀ i₀)
    nlinarith
  have hψxW : ψ x ≤ ε * W := by
    simp only [hψ]
    exact mul_le_mul_of_nonneg_left (hW x hxK) hεpos.le
  have hxΩ : x ∈ Ω := by
    have : x ∉ frontier Ω := by
      intro hfr
      have := hrim x hfr
      simp only [hv, Pi.add_apply] at hvx
      linarith
    have hx' : x ∈ closure Ω \ frontier Ω := ⟨hxK, this⟩
    rwa [closure_sdiff_frontier, hΩ.interior_eq] at hx'
  have hux : 0 ≤ u x := by
    simp only [hv, Pi.add_apply] at hvx
    linarith
  have hxnhds : Ω ∈ nhds x := hΩ.mem_nhds hxΩ
  have hloc : IsLocalMax v x := hxmax.isLocalMax (Filter.mem_of_superset hxnhds subset_closure)
  have huC : ContDiffAt ℝ 2 u x := (hu2 x hxΩ).contDiffAt hxnhds
  set P : EuclideanSpace ℝ (Fin d) →L[ℝ] ℝ := EuclideanSpace.proj i₀
  have hP : ∀ y, P y = y i₀ := fun y => rfl
  have hψC : ContDiff ℝ 2 ψ := by simp only [hψ]; fun_prop
  have hψ1 : ∀ y, HasFDerivAt ψ ((ε * lam * Real.exp (lam * y i₀)) • P) y := by
    intro y
    have := ((P.hasFDerivAt (x := y)).const_mul lam).exp.const_mul ε
    refine this.congr_fderiv ?_
    ext z; simp [hP]; ring
  have hfψ : fderiv ℝ ψ = fun y => (ε * lam * Real.exp (lam * y i₀)) • P :=
    funext fun y => (hψ1 y).fderiv
  have hψ2 : HasFDerivAt (fun y => (ε * lam * Real.exp (lam * y i₀)) • P)
      (((ε * lam * lam * Real.exp (lam * x i₀)) • P).smulRight P) x := by
    have := (((P.hasFDerivAt (x := x)).const_mul lam).exp.const_mul (ε * lam)).smul_const P
    refine this.congr_fderiv ?_
    ext z w; simp [hP]; ring_nf; simp
  have hD2ψ : ∀ i j, fderiv ℝ (fderiv ℝ ψ) x (EuclideanSpace.single i 1)
      (EuclideanSpace.single j 1) = ε * lam * lam * Real.exp (lam * x i₀) *
        ((EuclideanSpace.single i (1 : ℝ) : EuclideanSpace ℝ (Fin d)) i₀) *
        ((EuclideanSpace.single j (1 : ℝ) : EuclideanSpace ℝ (Fin d)) i₀) := by
    intro i j
    rw [hfψ, hψ2.fderiv]
    simp only [ContinuousLinearMap.smulRight_apply, FunLike.coe_smul, Pi.smul_apply, hP,
      smul_eq_mul]
  have hD1ψ : ∀ i, fderiv ℝ ψ x (EuclideanSpace.single i 1) = ε * lam * Real.exp (lam * x i₀) *
        ((EuclideanSpace.single i (1 : ℝ) : EuclideanSpace ℝ (Fin d)) i₀) := by
    intro i
    rw [hfψ]
    simp only [FunLike.coe_smul, Pi.smul_apply, hP, smul_eq_mul]
  have hD2v : ∀ i j, fderiv ℝ (fderiv ℝ v) x (EuclideanSpace.single i 1)
      (EuclideanSpace.single j 1) = fderiv ℝ (fderiv ℝ u) x (EuclideanSpace.single i 1)
      (EuclideanSpace.single j 1) + fderiv ℝ (fderiv ℝ ψ) x (EuclideanSpace.single i 1)
      (EuclideanSpace.single j 1) := by
    intro i j
    have := congrArg (fun T => T ![EuclideanSpace.single i (1 : ℝ), EuclideanSpace.single j 1])
      (iteratedFDeriv_add_apply (i := 2) huC hψC.contDiffAt)
    simpa [iteratedFDeriv_two_apply, hv] using this
  have hD1v : fderiv ℝ v x = 0 := hloc.fderiv_eq_zero
  have hD1u : ∀ i, fderiv ℝ u x (EuclideanSpace.single i 1)
      = - fderiv ℝ ψ x (EuclideanSpace.single i 1) := by
    intro i
    have h := congrArg (fun T => T (EuclideanSpace.single i (1 : ℝ))) hD1v
    rw [hv, fderiv_add (huC.differentiableAt (by simp)) (hψC.contDiffAt.differentiableAt (by simp))]
      at h
    simp at h
    linarith
  have hvC : ContDiffAt ℝ 2 v x := huC.add hψC.contDiffAt
  have ha_pos : ∀ ξ : Fin d → ℝ, 0 ≤ ∑ i, ∑ j, a x i j * ξ i * ξ j := fun ξ =>
    le_trans (by positivity) (hell x hxΩ ξ)
  have hHv := mp_hess_sum_nonpos hvC hloc (a x) ha_pos
  have ha00 : θ ≤ a x i₀ i₀ := by
    have := hell x hxΩ (Pi.single i₀ 1)
    simpa [Pi.single_apply] using this
  have hb0 : b x i₀ ≤ |B| := (le_abs_self _).trans ((hB x hxΩ i₀).trans (le_abs_self _))
  have hL := hLu x hxΩ
  simp only [ellipticOp, iteratedFDeriv_two_apply, Matrix.cons_val_zero, Matrix.cons_val_one,
    ] at hL
  simp only [hD2v] at hHv
  simp only [hD1u] at hL
  set e := Real.exp (lam * x i₀) with he
  have hepos : 0 < e := Real.exp_pos _
  have hs2 : ∑ i, ∑ j, a x i j * fderiv ℝ (fderiv ℝ ψ) x (EuclideanSpace.single i 1)
      (EuclideanSpace.single j 1) = ε * lam * lam * e * a x i₀ i₀ := by
    simp only [hD2ψ, PiLp.single_apply]
    simp [Finset.sum_ite_eq, mul_ite]
    ring
  have hs1 : ∑ i, b x i * -fderiv ℝ ψ x (EuclideanSpace.single i 1)
      = -(ε * lam * e * b x i₀) := by
    simp only [hD1ψ, PiLp.single_apply]
    simp [Finset.sum_ite_eq, mul_ite]
    ring
  simp only [mul_add, Finset.sum_add_distrib] at hHv
  rw [hs2] at hHv
  rw [hs1] at hL
  have hcu : 0 ≤ c x * u x := mul_nonneg (hc x hxΩ) hux
  have h1 : ε * lam * lam * e * θ ≤ ε * lam * lam * e * a x i₀ i₀ :=
    mul_le_mul_of_nonneg_left ha00 (by positivity)
  have h2 : ε * lam * e * b x i₀ ≤ ε * lam * e * |B| :=
    mul_le_mul_of_nonneg_left hb0 (by positivity)
  have h3 : ε * lam * lam * e * θ = ε * lam * e * (|B| + 1) := by
    rw [← hlamθ]; ring
  have h4 : 0 < ε * lam * e := by positivity
  nlinarith

/-- The comparison principle. Under the same conditions on `L` and `Ω`, if `u` and `v` have
continuous second derivatives inside, are continuous up to the rim, `L u ≤ L v` inside and
`u ≤ v` on the rim, then `u ≤ v` on the whole closed region: lower on the rim and heated less
inside means lower everywhere. -/
theorem comparison_principle {d : ℕ} (hd : 1 ≤ d) {Ω : Set (EuclideanSpace ℝ (Fin d))}
    (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω)
    {a : EuclideanSpace ℝ (Fin d) → Fin d → Fin d → ℝ}
    {b : EuclideanSpace ℝ (Fin d) → Fin d → ℝ} {c : EuclideanSpace ℝ (Fin d) → ℝ}
    {θ : ℝ} (hθ : 0 < θ)
    (hell : ∀ x ∈ Ω, ∀ ξ : Fin d → ℝ, θ * ∑ i, ξ i ^ 2 ≤ ∑ i, ∑ j, a x i j * ξ i * ξ j)
    (hb : ∃ B : ℝ, ∀ x ∈ Ω, ∀ i, |b x i| ≤ B)
    (hc : ∀ x ∈ Ω, 0 ≤ c x)
    {u v : EuclideanSpace ℝ (Fin d) → ℝ} (hu2 : ContDiffOn ℝ 2 u Ω) (hv2 : ContDiffOn ℝ 2 v Ω)
    (hucont : ContinuousOn u (closure Ω)) (hvcont : ContinuousOn v (closure Ω))
    (hL : ∀ x ∈ Ω, ellipticOp a b c u x ≤ ellipticOp a b c v x)
    (hrim : ∀ y ∈ frontier Ω, u y ≤ v y) :
    ∀ x ∈ closure Ω, u x ≤ v x := by
  have hLw : ∀ x ∈ Ω, ellipticOp a b c (u - v) x ≤ 0 := by
    intro x hx
    have huC : ContDiffAt ℝ 2 u x := (hu2 x hx).contDiffAt (hΩ.mem_nhds hx)
    have hvC : ContDiffAt ℝ 2 v x := (hv2 x hx).contDiffAt (hΩ.mem_nhds hx)
    have h2 : ∀ m, iteratedFDeriv ℝ 2 (u - v) x m
        = iteratedFDeriv ℝ 2 u x m - iteratedFDeriv ℝ 2 v x m := by
      intro m
      rw [iteratedFDeriv_sub_apply huC hvC]
      rfl
    have h1 : ∀ h, fderiv ℝ (u - v) x h = fderiv ℝ u x h - fderiv ℝ v x h := by
      intro h
      rw [fderiv_sub (huC.differentiableAt (by simp)) (hvC.differentiableAt (by simp))]
      rfl
    have := hL x hx
    simp only [ellipticOp, h2, h1, Pi.sub_apply, mul_sub, Finset.sum_sub_distrib] at this ⊢
    linarith
  have hw := weak_maximum_principle hd hΩ hbdd hθ hell hb hc (hu2.sub hv2)
    (hucont.sub hvcont) hLw le_rfl (fun y hy => by simpa using hrim y hy)
  intro x hx
  have := hw x hx
  have e1 : (u - v) x = u x - v x := rfl
  linarith

/-- The barrier bound. If `-Δu ≤ F` inside, with a constant `F ≥ 0`, the region fits inside a
ball of radius `R` round `x₀`, `u` has continuous second derivatives inside and is continuous up
to the rim, and `M ≥ 0` is at least `u` on the rim (so `M = max_{∂Ω} g⁺` for rim data `g`), then
`u ≤ M + F R² / (2d)` on the whole closed region. -/
theorem barrier_bound {d : ℕ} (hd : 1 ≤ d) {Ω : Set (EuclideanSpace ℝ (Fin d))}
    (hΩ : IsOpen Ω) {x₀ : EuclideanSpace ℝ (Fin d)} {R : ℝ}
    (hball : Ω ⊆ Metric.closedBall x₀ R)
    {u : EuclideanSpace ℝ (Fin d) → ℝ} (hu2 : ContDiffOn ℝ 2 u Ω)
    (hucont : ContinuousOn u (closure Ω))
    {F : ℝ} (hF : 0 ≤ F) (hf : ∀ x ∈ Ω, -(Δ u) x ≤ F)
    {M : ℝ} (hM : 0 ≤ M) (hrim : ∀ y ∈ frontier Ω, u y ≤ M) :
    ∀ x ∈ closure Ω, u x ≤ M + F * R ^ 2 / (2 * d) := by
  have hbdd : Bornology.IsBounded Ω := Metric.isBounded_closedBall.subset hball
  have hdpos : (0 : ℝ) < d := by exact_mod_cast hd
  set k : ℝ := F / (2 * d) with hkdef
  have hk : 0 ≤ k := by positivity
  have hkd : (d : ℝ) * (2 * k) = F := by rw [hkdef]; field_simp
  have hcl : closure Ω ⊆ Metric.closedBall x₀ R :=
    closure_minimal hball Metric.isClosed_closedBall
  set ψ : EuclideanSpace ℝ (Fin d) → ℝ := fun y => k * ‖y - x₀‖ ^ 2 with hψ
  have hψC : ContDiff ℝ 2 ψ := by
    simp only [hψ]
    exact contDiff_const.mul ((contDiff_norm_sq ℝ).comp (contDiff_id.sub contDiff_const))
  have hψ1 : ∀ y, HasFDerivAt ψ ((2 * k) • innerSL ℝ (y - x₀)) y := by
    intro y
    have := (((hasFDerivAt_id y).sub_const x₀).norm_sq).const_mul k
    refine this.congr_fderiv ?_
    ext z; simp; ring
  have hfψ : fderiv ℝ ψ = fun y => (2 * k) • innerSL ℝ (y - x₀) :=
    funext fun y => (hψ1 y).fderiv
  have hD2ψ : ∀ x i, fderiv ℝ (fderiv ℝ ψ) x (EuclideanSpace.single i 1)
      (EuclideanSpace.single i 1) = 2 * k := by
    intro x i
    have h2 : HasFDerivAt (fun y => (2 * k) • innerSL ℝ (y - x₀)) ((2 * k) • innerSL ℝ) x := by
      have := (((innerSL ℝ).hasFDerivAt (x := x - x₀)).comp x
        ((hasFDerivAt_id x).sub_const x₀)).const_smul (2 * k)
      refine this.congr_fderiv ?_
      ext z w; simp
    rw [hfψ, h2.fderiv]
    simp only [FunLike.coe_smul, Pi.smul_apply, smul_eq_mul]
    erw [innerSL_apply_apply]
    simp
  set a : EuclideanSpace ℝ (Fin d) → Fin d → Fin d → ℝ := fun _ i j => if i = j then 1 else 0
    with ha
  have hell : ∀ x ∈ Ω, ∀ ξ : Fin d → ℝ, 1 * ∑ i, ξ i ^ 2 ≤ ∑ i, ∑ j, a x i j * ξ i * ξ j := by
    intro x _ ξ
    simp [ha, ite_mul, sq]
  have hLw : ∀ x ∈ Ω, ellipticOp a (fun _ _ => 0) (fun _ => 0) (u + ψ) x ≤ 0 := by
    intro x hx
    have huC : ContDiffAt ℝ 2 u x := (hu2 x hx).contDiffAt (hΩ.mem_nhds hx)
    have h2 : ∀ m, iteratedFDeriv ℝ 2 (u + ψ) x m
        = iteratedFDeriv ℝ 2 u x m + iteratedFDeriv ℝ 2 ψ x m := by
      intro m
      rw [iteratedFDeriv_add_apply huC hψC.contDiffAt]
      rfl
    have hΔ : Δ u x = ∑ i, iteratedFDeriv ℝ 2 u x
        ![EuclideanSpace.single i 1, EuclideanSpace.single i 1] := by
      rw [laplacian_eq_iteratedFDeriv_orthonormalBasis u (EuclideanSpace.basisFun (Fin d) ℝ)]
      simp [EuclideanSpace.basisFun_apply]
    have hf' := hf x hx
    rw [hΔ] at hf'
    simp only [ellipticOp, h2, ha, ite_mul, one_mul, zero_mul, Finset.sum_ite_eq,
      Finset.mem_univ, ↓reduceIte, add_zero, Finset.sum_const_zero, mul_add,
      Finset.sum_add_distrib]
    simp only [iteratedFDeriv_two_apply, Matrix.cons_val_zero, Matrix.cons_val_one,
      hD2ψ] at hf' ⊢
    simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul] 
    linarith
  have hrimw : ∀ y ∈ frontier Ω, (u + ψ) y ≤ M + k * R ^ 2 := by
    intro y hy
    have hyb : dist y x₀ ≤ R := hcl (frontier_subset_closure hy)
    have hR : ‖y - x₀‖ ^ 2 ≤ R ^ 2 := by
      rw [← dist_eq_norm]
      exact pow_le_pow_left₀ dist_nonneg hyb 2
    simp only [Pi.add_apply, hψ]
    have := hrim y hy
    nlinarith
  have hw := weak_maximum_principle hd hΩ hbdd one_pos hell ⟨0, fun _ _ _ => by simp⟩
    (fun _ _ => le_rfl) (hu2.add hψC.contDiffOn) (hucont.add hψC.continuous.continuousOn) hLw
    (by positivity) hrimw
  intro x hx
  have := hw x hx
  have hψx : 0 ≤ ψ x := by simp only [hψ]; positivity
  have e1 : (u + ψ) x = u x + ψ x := rfl
  have : k * R ^ 2 = F * R ^ 2 / (2 * d) := by rw [hkdef]; ring
  linarith


-- Loss to the air: c = 2 × 10 / (50 × 1/100) = 40 per square metre.
example : (2 * 10 : ℚ) / (50 * (1 / 100)) = 40 := by norm_num
-- Heating over conductivity: f = 5000 / 50 = 100 K per square metre; heat 5000 × 1/100 = 50 W.
example : (5000 : ℚ) / 50 = 100 ∧ (5000 : ℚ) * (1 / 100) = 50 := by norm_num
-- Scene 1, insulated centre: four turns give 80 K, so the centre takes 80 / 4 = 20 K (40 °C).
example : (80 : ℚ) / 4 = 20 ∧ (20 : ℚ) + 20 = 40 := by norm_num
-- Stability: raising the hot bar by 1/2 K moves the insulated centre by (1/2) / 4 = 1/8 K.
example : ((1 : ℚ) / 2) / 4 = 1 / 8 ∧ (1 : ℚ) / 8 ≤ 1 / 2 := by norm_num
-- Scene 2 barriers at the centre: strip 100 × 1/2 × 1/2 / 2 = 25/2 K, outer ball
-- 100 × (1/2) / 4 = 25/2 K, inner bowl 100 × 1/4 / 4 = 25/4 K.
example : (100 : ℚ) * (1 / 2) * (1 / 2) / 2 = 25 / 2 ∧ (100 : ℚ) * (1 / 2) / (2 * 2) = 25 / 2 ∧
    (100 : ℚ) * (1 / 4) / (2 * 2) = 25 / 4 := by norm_num
-- The bound in °C: 20 + 25/4 = 105/4 (26.25 °C) up to 20 + 25/2 = 65/2 (32.5 °C).
example : (20 : ℚ) + 25 / 4 = 105 / 4 ∧ (20 : ℚ) + 25 / 2 = 65 / 2 := by norm_num
-- Floors F / (8d) for the rod, plate and cube, and the common strip cap F / 8.
example : (100 : ℚ) / (8 * 1) = 25 / 2 ∧ (100 : ℚ) / (8 * 2) = 25 / 4 ∧
    (100 : ℚ) / (8 * 3) = 25 / 6 ∧ (100 : ℚ) / 8 = 25 / 2 := by norm_num
-- What breaks: the inner bowl read at a corner, 100 × (1/4 - 1/2) / 4 = -25/4 K, below the 0 K rim.
example : (100 : ℚ) * (1 / 4 - 1 / 2) / 4 = -25 / 4 ∧ (-25 / 4 : ℚ) < 0 := by norm_num

#print axioms weak_maximum_principle
#print axioms comparison_principle
#print axioms barrier_bound
