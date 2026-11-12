-- KKT conditions: in a convex problem a point passing the four KKT checks is a global minimum, at a local minimum where LICQ holds exactly one set of KKT multipliers exists, the pump problem's minimum loses its multipliers when the node 1 cap is written squared, and the card's pump numbers check exactly.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Function
import Mathlib.LinearAlgebra.AffineSpace.AffineMap
import Mathlib.Topology.Order.LocalExtr
import Mathlib.Order.Filter.Extr
import Mathlib.Tactic
import Mathlib

open Filter Topology

/-! ### How the card's objects are written here

The choice `x` is a list of `n` real numbers, `EuclideanSpace ℝ (Fin n)`. The cost is `f0`,
the `m` "at most" limits are `f i x ≤ 0` and the `p` "exactly" limits are `h j x = 0`.
`gradient F x` is the gradient `∇F(x)`. A point `xs` with multipliers `lam` and `nu` passes
the KKT conditions when
1. primal feasibility: `f i xs ≤ 0` and `h j xs = 0`;
2. dual feasibility: `0 ≤ lam i`;
3. complementary slackness: `lam i * f i xs = 0` for every `i`;
4. stationarity: `∇f0(xs) + Σ lam i • ∇f i(xs) + Σ nu j • ∇h j(xs) = 0`. -/

lemma kkt_aux_convex_grad_le {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [CompleteSpace E] (f : E → ℝ) (hf : ConvexOn ℝ Set.univ f) (x y : E)
    (hd : DifferentiableAt ℝ f x) : inner ℝ (gradient f x) (y - x) ≤ f y - f x := by
  rw [inner_gradient_left]
  set d := y - x with hdd
  have h1 : HasDerivAt (fun t : ℝ => x + t • d) d 0 := by
    simpa using ((hasDerivAt_id (0:ℝ)).smul_const d).const_add x
  have hφ : HasDerivAt (fun t : ℝ => f (x + t • d)) (fderiv ℝ f x d) 0 :=
    hd.hasFDerivAt.comp_hasDerivAt_of_eq (0:ℝ) h1 (by simp)
  have hs := hφ.tendsto_slope_zero_right
  refine le_of_tendsto hs ?_
  filter_upwards [Ioo_mem_nhdsGT (zero_lt_one' ℝ)] with t ht
  obtain ⟨ht0, ht1⟩ := ht
  have hc := hf.2 (Set.mem_univ x) (Set.mem_univ y) (show (0:ℝ) ≤ 1 - t by linarith)
    ht0.le (by ring)
  have heq : (1 - t) • x + t • y = x + t • d := by
    simp only [hdd, smul_sub, sub_smul, one_smul]; abel
  rw [heq] at hc
  simp only [zero_add, zero_smul, add_zero, smul_eq_mul] at hc ⊢
  rw [inv_mul_le_iff₀ ht0]
  nlinarith

#print axioms kkt_aux_convex_grad_le

lemma kkt_aux_line_deriv {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : E → ℝ) (p v : E) (hd : DifferentiableAt ℝ f p) :
    HasDerivAt (fun t : ℝ => f (p + t • v)) (fderiv ℝ f p v) 0 := by
  have h1 : HasDerivAt (fun t : ℝ => p + t • v) v 0 := by
    simpa using ((hasDerivAt_id (0:ℝ)).smul_const v).const_add p
  exact hd.hasFDerivAt.comp_hasDerivAt_of_eq (0:ℝ) h1 (by simp)

#print axioms kkt_aux_line_deriv

lemma kkt_aux_gram_surj {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    {ι : Type*} [Fintype ι] (g : ι → E) (hg : LinearIndependent ℝ g) (y : ι → ℝ) :
    ∃ v : E, ∀ j, inner ℝ (g j) v = y j := by
  classical
  let S : (ι → ℝ) →ₗ[ℝ] (ι → ℝ) :=
    { toFun := fun c j => inner ℝ (g j) (∑ i, c i • g i)
      map_add' := by
        intro a b; funext j
        simp [add_smul, Finset.sum_add_distrib, inner_add_right]
      map_smul' := by
        intro r a; funext j
        simp [mul_smul, ← Finset.smul_sum, real_inner_smul_right] }
  have hinj : Function.Injective S := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro c hc
    have hc' : ∀ j, inner ℝ (g j) (∑ i, c i • g i) = 0 := fun j => congrFun hc j
    have hself : inner ℝ (∑ i, c i • g i) (∑ i, c i • g i) = 0 := by
      rw [sum_inner]
      simp [real_inner_smul_left, hc']
    have h0 : ∑ i, c i • g i = 0 := inner_self_eq_zero.1 hself
    funext i
    exact Fintype.linearIndependent_iff.1 hg c h0 i
  obtain ⟨c, hc⟩ := (LinearMap.injective_iff_surjective.1 hinj) y
  exact ⟨∑ i, c i • g i, fun j => congrFun hc j⟩

#print axioms kkt_aux_gram_surj

lemma kkt_aux_sign {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [CompleteSpace E] {ι : Type*} [Fintype ι] [DecidableEq ι]
    (f0 : E → ℝ) (G : ι → E → ℝ) (xs : E) (S : Set E) (k : ι)
    (hf0 : DifferentiableAt ℝ f0 xs)
    (hG : ∀ j, HasStrictFDerivAt (G j) (fderiv ℝ (G j) xs) xs)
    (hli : LinearIndependent ℝ (fun j => gradient (G j) xs))
    (hmin : IsLocalMinOn f0 S xs)
    (hfeas : ∀ᶠ x in 𝓝 xs, (∀ j, j ≠ k → G j x = G j xs) → G k x ≤ G k xs → x ∈ S)
    (c : ι → ℝ) (hstat : gradient f0 xs + ∑ j, c j • gradient (G j) xs = 0) : 0 ≤ c k := by
  by_contra hneg
  push Not at hneg
  obtain ⟨w, hw⟩ := kkt_aux_gram_surj (fun j => gradient (G j) xs) hli
    (fun j => if j = k then -1 else 0)
  let ι' := {j : ι // j ≠ k}
  let Ψ : E → (ι' → ℝ) := fun x j => G j.1 x
  let Ψ' : E →L[ℝ] (ι' → ℝ) := ContinuousLinearMap.pi (fun j => fderiv ℝ (G j.1) xs)
  have hΨ : HasStrictFDerivAt Ψ Ψ' xs := hasStrictFDerivAt_pi.2 (fun j => hG j.1)
  have hΨ' : Ψ'.range = ⊤ := by
    rw [LinearMap.range_eq_top]
    intro y
    obtain ⟨v, hv⟩ := kkt_aux_gram_surj (fun j : ι' => gradient (G j.1) xs)
      (hli.comp _ Subtype.val_injective) y
    refine ⟨v, funext fun j => ?_⟩
    simp [Ψ', ← inner_gradient_left, hv j]
  have hwk : w ∈ (Ψ' : E →ₗ[ℝ] (ι' → ℝ)).ker := by
    rw [LinearMap.mem_ker]
    funext j
    have := hw j.1
    simp only [j.2, ite_false] at this
    simp [Ψ', ← inner_gradient_left, this]
  let w' : (Ψ' : E →ₗ[ℝ] (ι' → ℝ)).ker := ⟨w, hwk⟩
  let γ : ℝ → E := fun t => hΨ.implicitFunction Ψ Ψ' hΨ' (Ψ xs) (t • w')
  have hγ0 : γ 0 = xs := by simp [γ]
  have hγd : HasDerivAt γ w 0 := by
    have h1 := hΨ.to_implicitFunction hΨ'
    have h2 : HasDerivAt (fun t : ℝ => t • w') w' 0 := by
      simpa using (hasDerivAt_id (0:ℝ)).smul_const w'
    exact h1.hasFDerivAt.comp_hasDerivAt_of_eq (0:ℝ) h2 (by simp)
  have hγc : Tendsto γ (𝓝 0) (𝓝 xs) := by
    have := hγd.continuousAt.tendsto
    rwa [hγ0] at this
  have hΨγ : ∀ᶠ t in 𝓝 (0:ℝ), Ψ (γ t) = Ψ xs := by
    have hev := hΨ.map_implicitFunction_eq hΨ'
    have ht : Tendsto (fun t : ℝ => (Ψ xs, t • w')) (𝓝 0) (𝓝 (Ψ xs, 0)) := by
      refine tendsto_const_nhds.prodMk_nhds ?_
      have : Continuous (fun t : ℝ => t • w') := continuous_id.smul continuous_const
      simpa using this.tendsto 0
    exact ht.eventually hev
  -- derivatives along the curve
  have hdir0 : fderiv ℝ f0 xs w = c k := by
    have hst := congrArg (fun u => inner ℝ u w) hstat
    simp only [inner_add_left, sum_inner, real_inner_smul_left, hw, inner_zero_left,
      inner_gradient_left] at hst
    simp only [mul_ite, mul_neg, mul_one, mul_zero, Finset.sum_ite_eq', Finset.mem_univ,
      ite_true] at hst
    linarith
  have hdirk : fderiv ℝ (G k) xs w = -1 := by
    have := hw k
    simp only [ite_true] at this
    rw [← inner_gradient_left, this]
  have d0 : HasDerivAt (fun t => f0 (γ t)) (c k) 0 := by
    rw [← hdir0]
    exact hf0.hasFDerivAt.comp_hasDerivAt_of_eq (0:ℝ) hγd hγ0.symm
  have dk : HasDerivAt (fun t => G k (γ t)) (-1) 0 := by
    rw [← hdirk]
    exact (hG k).hasFDerivAt.comp_hasDerivAt_of_eq (0:ℝ) hγd hγ0.symm
  have key : ∀ (φ : ℝ → ℝ) (L : ℝ), HasDerivAt φ L 0 → L < 0 →
      ∀ᶠ t in 𝓝[>] (0:ℝ), φ t < φ 0 := by
    intro φ L hφ hL
    have hs := hφ.tendsto_slope_zero_right
    filter_upwards [hs.eventually (gt_mem_nhds hL), self_mem_nhdsWithin] with t ht htpos
    simp only [zero_add, smul_eq_mul] at ht
    have htpos' : (0:ℝ) < t := htpos
    have := mul_neg_of_pos_of_neg htpos' ht
    rw [← mul_assoc, mul_inv_cancel₀ htpos'.ne', one_mul] at this
    linarith
  have e0 := key _ _ d0 hneg
  have ek := key _ _ dk (by norm_num)
  have hγc' : Tendsto γ (𝓝[>] 0) (𝓝 xs) := hγc.mono_left nhdsWithin_le_nhds
  have hinS : ∀ᶠ t in 𝓝[>] (0:ℝ), γ t ∈ S := by
    filter_upwards [hγc'.eventually hfeas, ek, (hΨγ.filter_mono nhdsWithin_le_nhds)]
      with t hft hkt hΨt
    refine hft (fun j hj => ?_) ?_
    · exact congrFun hΨt ⟨j, hj⟩
    · rw [hγ0] at hkt; exact hkt.le
  have hT : Tendsto γ (𝓝[>] 0) (𝓝[S] xs) := tendsto_nhdsWithin_iff.2 ⟨hγc', hinS⟩
  have hle := hT.eventually hmin
  obtain ⟨t, ht1, ht2⟩ := (hle.and e0).exists
  rw [hγ0] at ht2
  linarith

#print axioms kkt_aux_sign

/-- The sufficiency half, the card's certificate (Step 4). Minimise `f0` subject to
`f i x ≤ 0` and `h j x = 0`, where `f0` and every `f i` are convex and have a gradient at
`xs`, and every `h j` is affine. If `xs` together with multipliers `lam` and `nu` passes all
four KKT checks, then no allowed point costs less: `xs` is a global minimum. -/
theorem kkt_point_is_global_min_of_convex {n m p : ℕ}
    (f0 : EuclideanSpace ℝ (Fin n) → ℝ) (f : Fin m → EuclideanSpace ℝ (Fin n) → ℝ)
    (h : Fin p → EuclideanSpace ℝ (Fin n) →ᵃ[ℝ] ℝ)
    (xs : EuclideanSpace ℝ (Fin n)) (lam : Fin m → ℝ) (nu : Fin p → ℝ)
    (hf0_convex : ConvexOn ℝ Set.univ f0) (hf_convex : ∀ i, ConvexOn ℝ Set.univ (f i))
    (hf0_diff : DifferentiableAt ℝ f0 xs) (hf_diff : ∀ i, DifferentiableAt ℝ (f i) xs)
    (h_primal_ineq : ∀ i, f i xs ≤ 0) (h_primal_eq : ∀ j, h j xs = 0)
    (h_dual : ∀ i, 0 ≤ lam i)
    (h_slack : ∀ i, lam i * f i xs = 0)
    (h_stat : gradient f0 xs + ∑ i, lam i • gradient (f i) xs
        + ∑ j, nu j • gradient (h j) xs = 0) :
    IsMinOn f0 {x | (∀ i, f i x ≤ 0) ∧ ∀ j, h j x = 0} xs := by
  intro y hy
  obtain ⟨hyi, hye⟩ := hy
  show f0 xs ≤ f0 y
  set d := y - xs
  -- affine equalities have zero directional derivative along feasible directions
  have haff : ∀ j, inner ℝ (gradient (h j) xs) d = 0 := by
    intro j
    let L : EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ := LinearMap.toContinuousLinearMap (h j).linear
    have hfd : HasFDerivAt (fun x => (h j) x) L xs := by
      have : (fun x => (h j) x) = fun x => L (x - xs) + h j xs := by
        funext x
        simp only [L, LinearMap.coe_toContinuousLinearMap']
        rw [← vsub_eq_sub, AffineMap.linear_apply_vsub]; simp
      rw [this]
      exact ((L.hasFDerivAt.comp xs ((hasFDerivAt_id xs).sub_const xs))).add_const _ |>.congr_fderiv
        (by ext v; simp)
    rw [inner_gradient_left, hfd.fderiv]
    simp only [L, LinearMap.coe_toContinuousLinearMap', d]
    rw [← vsub_eq_sub, AffineMap.linear_apply_vsub]; simp [hye j, h_primal_eq j]
  have h0 := kkt_aux_convex_grad_le f0 hf0_convex xs y hf0_diff
  have hi : ∀ i, lam i * inner ℝ (gradient (f i) xs) d ≤ 0 := by
    intro i
    have := kkt_aux_convex_grad_le (f i) (hf_convex i) xs y (hf_diff i)
    have h2 := mul_le_mul_of_nonneg_left this (h_dual i)
    have h3 := mul_nonpos_of_nonneg_of_nonpos (h_dual i) (hyi i)
    nlinarith [h_slack i]
  have hst := congrArg (fun w => inner ℝ w d) h_stat
  simp only [inner_add_left, sum_inner, real_inner_smul_left, inner_zero_left, haff,
    mul_zero, Finset.sum_const_zero, add_zero] at hst
  have := Finset.sum_nonpos (fun i _ => hi i) (s := Finset.univ)
  linarith

/-- The necessity half (Karush; Kuhn and Tucker; Nocedal and Wright, Theorem 12.1). Let the
cost `f0`, every limit `f i` and every equality `h j` be smooth (continuously differentiable)
near `xs`. If `xs` obeys every limit, is a local minimum of `f0` among the points that obey
every limit, and LICQ holds there (the gradients of the binding limits, those with
`f i xs = 0`, together with the gradients of all the equalities, are linearly independent),
then there are multipliers `lam` and `nu` passing all four KKT checks, and only one such
pair. -/
theorem exists_unique_kkt_multipliers_of_licq {n m p : ℕ}
    (f0 : EuclideanSpace ℝ (Fin n) → ℝ) (f : Fin m → EuclideanSpace ℝ (Fin n) → ℝ)
    (h : Fin p → EuclideanSpace ℝ (Fin n) → ℝ) (xs : EuclideanSpace ℝ (Fin n))
    (hf0 : ContDiffAt ℝ 1 f0 xs) (hf : ∀ i, ContDiffAt ℝ 1 (f i) xs)
    (hh : ∀ j, ContDiffAt ℝ 1 (h j) xs)
    (h_primal_ineq : ∀ i, f i xs ≤ 0) (h_primal_eq : ∀ j, h j xs = 0)
    (hmin : IsLocalMinOn f0 {x | (∀ i, f i x ≤ 0) ∧ ∀ j, h j x = 0} xs)
    (hlicq : LinearIndependent ℝ
      (Sum.elim (fun i : {i : Fin m // f i xs = 0} => gradient (f i) xs)
        (fun j : Fin p => gradient (h j) xs))) :
    ∃! mult : (Fin m → ℝ) × (Fin p → ℝ),
      (∀ i, 0 ≤ mult.1 i) ∧ (∀ i, mult.1 i * f i xs = 0) ∧
      gradient f0 xs + ∑ i, mult.1 i • gradient (f i) xs
        + ∑ j, mult.2 j • gradient (h j) xs = 0 := by
  classical
  let A := {i : Fin m // f i xs = 0}
  let G : A ⊕ Fin p → EuclideanSpace ℝ (Fin n) → ℝ := Sum.elim (fun a => f a.1) h
  let g : A ⊕ Fin p → EuclideanSpace ℝ (Fin n) := fun j => gradient (G j) xs
  have hg : g = Sum.elim (fun i : A => gradient (f i) xs) (fun j => gradient (h j) xs) := by
    funext j; cases j <;> rfl
  have hli : LinearIndependent ℝ g := hg ▸ hlicq
  have hGs : ∀ j, HasStrictFDerivAt (G j) (fderiv ℝ (G j) xs) xs := by
    intro j
    cases j with
    | inl a => exact (hf a.1).hasStrictFDerivAt one_ne_zero
    | inr j => exact (hh j).hasStrictFDerivAt one_ne_zero
  have hG0 : ∀ j, G j xs = 0 := by
    intro j
    cases j with
    | inl a => exact a.2
    | inr j => exact h_primal_eq j
  have hf0s : HasStrictFDerivAt f0 (fderiv ℝ f0 xs) xs := hf0.hasStrictFDerivAt one_ne_zero
  set S := {x : EuclideanSpace ℝ (Fin n) | (∀ i, f i x ≤ 0) ∧ ∀ j, h j x = 0} with hS
  -- near xs the inactive limits stay strictly negative
  have hU : ∀ᶠ x in 𝓝 xs, ∀ i, f i xs ≠ 0 → f i x < 0 := by
    rw [eventually_all]
    intro i
    by_cases hi : f i xs = 0
    · exact Eventually.of_forall (fun x hx => absurd hi hx)
    · have hlt : f i xs < 0 := lt_of_le_of_ne (h_primal_ineq i) hi
      filter_upwards [(hf i).continuousAt.eventually (gt_mem_nhds hlt)] with x hx _ using hx
  have hfeasU : ∀ᶠ x in 𝓝 xs, (∀ a : A, f a.1 x ≤ 0) → (∀ j, h j x = 0) → x ∈ S := by
    filter_upwards [hU] with x hx ha he
    refine ⟨fun i => ?_, he⟩
    by_cases hi : f i xs = 0
    · exact ha ⟨i, hi⟩
    · exact (hx i hi).le
  -- Lagrange multipliers on the set where every binding limit is an equality
  have hloc : IsLocalMinOn f0 {x | ∀ j, G j x = G j xs} xs := by
    have hmem : S ∈ 𝓝[{x | ∀ j, G j x = G j xs}] xs := by
      rw [mem_nhdsWithin_iff_eventually]
      filter_upwards [hfeasU] with x hx hxT
      refine hx (fun a => ?_) (fun j => ?_)
      · have := hxT (Sum.inl a); rw [hG0] at this; exact this.le
      · have := hxT (Sum.inr j); rw [hG0] at this; exact this
    exact IsMinFilter.filter_mono hmin (nhdsWithin_le_of_mem hmem)
  obtain ⟨Λ, Λ₀, hne, hsum⟩ :=
    IsLocalExtrOn.exists_multipliers_of_hasStrictFDerivAt (Or.inl hloc) hGs hf0s
  have hkey : ∀ v, ∑ j, Λ j * inner ℝ (g j) v + Λ₀ * inner ℝ (gradient f0 xs) v = 0 := by
    intro v
    have := congrArg (fun L => L v) hsum
    simpa [g, inner_gradient_left] using this
  have hvec : ∑ j, Λ j • g j + Λ₀ • gradient f0 xs = 0 := by
    apply ext_inner_right ℝ
    intro v
    simp only [inner_add_left, sum_inner, real_inner_smul_left, inner_zero_left]
    exact hkey v
  have hΛ₀ : Λ₀ ≠ 0 := by
    intro h0
    rw [h0, zero_smul, add_zero] at hvec
    apply hne
    have : Λ = 0 := funext fun j => Fintype.linearIndependent_iff.1 hli Λ hvec j
    rw [this, h0]; rfl
  let c : A ⊕ Fin p → ℝ := fun j => Λ j / Λ₀
  have hc : gradient f0 xs + ∑ j, c j • g j = 0 := by
    have := congrArg (fun u => Λ₀⁻¹ • u) hvec
    simp only [smul_add, Finset.smul_sum, smul_smul, smul_zero] at this
    rw [inv_mul_cancel₀ hΛ₀, one_smul] at this
    rw [← this, add_comm]
    congr 1
    refine Finset.sum_congr rfl fun j _ => ?_
    simp only [c, div_eq_inv_mul]
  -- signs of the multipliers on binding limits
  have hsign : ∀ a : A, 0 ≤ c (Sum.inl a) := by
    intro a
    refine kkt_aux_sign f0 G xs S (Sum.inl a) hf0s.hasFDerivAt.differentiableAt hGs hli hmin
      ?_ c hc
    filter_upwards [hfeasU] with x hx hothers hk
    refine hx (fun b => ?_) (fun j => ?_)
    · by_cases hb : b = a
      · subst hb; have := hk; rw [hG0] at this; exact this
      · have := hothers (Sum.inl b) (by simpa using hb); rw [hG0] at this; exact this.le
    · have := hothers (Sum.inr j) (by simp); rw [hG0] at this; exact this
  -- converting sums over all limits to sums over the binding ones
  have hconv : ∀ (l : Fin m → ℝ) (nu : Fin p → ℝ), (∀ i, f i xs ≠ 0 → l i = 0) →
      ∑ i, l i • gradient (f i) xs + ∑ j, nu j • gradient (h j) xs
        = ∑ j, (Sum.elim (fun a : A => l a.1) nu j) • g j := by
    intro l nu hl
    rw [Fintype.sum_sum_type]
    congr 1
    rw [← Fintype.sum_subtype_add_sum_subtype (fun i => f i xs = 0)]
    have : ∑ i : {i // ¬ f i xs = 0}, l i • gradient (f i) xs = 0 :=
      Finset.sum_eq_zero fun i _ => by rw [hl i.1 i.2, zero_smul]
    rw [this, add_zero]
    rfl
  have hslack0 : ∀ (l : Fin m → ℝ), (∀ i, l i * f i xs = 0) → ∀ i, f i xs ≠ 0 → l i = 0 :=
    fun l hl i hi => (mul_eq_zero.1 (hl i)).resolve_right hi
  have huniq : ∀ m1 m2 : (Fin m → ℝ) × (Fin p → ℝ),
      ((∀ i, m1.1 i * f i xs = 0) ∧ gradient f0 xs + ∑ i, m1.1 i • gradient (f i) xs
        + ∑ j, m1.2 j • gradient (h j) xs = 0) →
      ((∀ i, m2.1 i * f i xs = 0) ∧ gradient f0 xs + ∑ i, m2.1 i • gradient (f i) xs
        + ∑ j, m2.2 j • gradient (h j) xs = 0) → m1 = m2 := by
    rintro ⟨l1, n1⟩ ⟨l2, n2⟩ ⟨hs1, he1⟩ ⟨hs2, he2⟩
    have z1 := hslack0 l1 hs1
    have z2 := hslack0 l2 hs2
    rw [add_assoc, hconv l1 n1 z1] at he1
    rw [add_assoc, hconv l2 n2 z2] at he2
    set D1 := Sum.elim (fun a : A => l1 a.1) n1
    set D2 := Sum.elim (fun a : A => l2 a.1) n2
    have hdiff : ∑ j, (D1 j - D2 j) • g j = 0 := by
      simp only [sub_smul, Finset.sum_sub_distrib]
      have := he1.trans he2.symm
      linear_combination (norm := skip) this
      abel_nf
    have hD : ∀ j, D1 j = D2 j := fun j =>
      sub_eq_zero.1 (Fintype.linearIndependent_iff.1 hli _ hdiff j)
    simp only [Prod.mk.injEq]
    refine ⟨funext fun i => ?_, funext fun j => hD (Sum.inr j)⟩
    by_cases hi : f i xs = 0
    · exact hD (Sum.inl ⟨i, hi⟩)
    · rw [z1 i hi, z2 i hi]
  -- the multipliers
  let lam : Fin m → ℝ := fun i => if hi : f i xs = 0 then c (Sum.inl ⟨i, hi⟩) else 0
  let nu : Fin p → ℝ := fun j => c (Sum.inr j)
  have hlam0 : ∀ i, f i xs ≠ 0 → lam i = 0 := fun i hi => by simp [lam, hi]
  have hslk : ∀ i, lam i * f i xs = 0 := by
    intro i
    by_cases hi : f i xs = 0
    · rw [hi, mul_zero]
    · rw [hlam0 i hi, zero_mul]
  have hst : gradient f0 xs + ∑ i, lam i • gradient (f i) xs
      + ∑ j, nu j • gradient (h j) xs = 0 := by
    rw [add_assoc, hconv lam nu hlam0]
    have : Sum.elim (fun a : A => lam a.1) nu = c := by
      funext j
      cases j with
      | inl a => simp [lam, a.2]
      | inr j => rfl
    rw [this]; exact hc
  refine ⟨(lam, nu), ⟨fun i => ?_, hslk, hst⟩, fun mult hmult => ?_⟩
  · by_cases hi : f i xs = 0
    · simp only [lam, hi, dite_true]; exact hsign _
    · exact (hlam0 i hi).ge
  · exact huniq mult (lam, nu) ⟨hmult.2.1, hmult.2.2⟩ ⟨hslk, hst⟩

/-- When the constraint qualification fails (Step 3). Take the pump cost
`0.3 x₁² + 0.2 x₂²`, the demand `x₁ + x₂ - 10 = 0`, and the node 1 cap written as
`(x₁ + 4x₂ - 25)² ≤ 0`. The split `(5, 5)` is the cheapest allowed split, yet no price
`lam ≥ 0` on the squared cap and no price `nu` on the demand pass the KKT checks there:
the squared cap's gradient is zero at `(5, 5)`. -/
theorem squared_cap_minimum_has_no_kkt_multipliers :
    let f0 := fun x : EuclideanSpace ℝ (Fin 2) => 3 / 10 * x 0 ^ 2 + 2 / 10 * x 1 ^ 2
    let g := fun x : EuclideanSpace ℝ (Fin 2) => (x 0 + 4 * x 1 - 25) ^ 2
    let hd := fun x : EuclideanSpace ℝ (Fin 2) => x 0 + x 1 - 10
    IsMinOn f0 {x | g x ≤ 0 ∧ hd x = 0} !₂[5, 5] ∧
      ¬ ∃ lam nu : ℝ, 0 ≤ lam ∧ lam * g !₂[5, 5] = 0 ∧
        gradient f0 !₂[5, 5] + lam • gradient g !₂[5, 5] + nu • gradient hd !₂[5, 5] = 0 := by
  intro f0 g hd
  refine ⟨?_, ?_⟩
  · intro x hx
    obtain ⟨hg, hh⟩ := hx
    simp only [g, hd] at hg hh
    have h1 : x 0 + 4 * x 1 - 25 = 0 := by
      have := le_antisymm hg (sq_nonneg _)
      exact pow_eq_zero_iff (two_ne_zero) |>.1 this
    have hx0 : x 0 = 5 := by linarith
    have hx1 : x 1 = 5 := by linarith
    show f0 _ ≤ f0 x
    simp [f0, hx0, hx1]
  · rintro ⟨lam, nu, -, -, hstat⟩
    set P : EuclideanSpace ℝ (Fin 2) := !₂[5, 5] with hP
    set v : EuclideanSpace ℝ (Fin 2) := !₂[1, -1] with hv
    have hgmin : IsLocalMin g P := by
      refine Filter.Eventually.of_forall (fun x => ?_)
      have : g P = 0 := by simp [g, P]; norm_num
      rw [this]; exact sq_nonneg _
    have hgg : gradient g P = 0 := by simp [gradient, hgmin.fderiv_eq_zero]
    have hf0d : DifferentiableAt ℝ f0 P := by simp only [f0]; fun_prop
    have hhd : DifferentiableAt ℝ hd P := by simp only [hd]; fun_prop
    have A0 := kkt_aux_line_deriv f0 P v hf0d
    have Ah := kkt_aux_line_deriv hd P v hhd
    have B0 : HasDerivAt (fun t : ℝ => f0 (P + t • v)) 1 0 := by
      have e : (fun t : ℝ => f0 (P + t • v)) = fun t => 25 / 2 + t + 1 / 2 * t ^ 2 := by
        funext t; simp [f0, P, v]; ring
      rw [e]
      have := (((hasDerivAt_id (0:ℝ)).const_add (25 / 2)).add
        (((hasDerivAt_id (0:ℝ)).pow 2).const_mul (1 / 2)))
      convert this using 1
      · funext t; simp
      · simp
    have Bh : HasDerivAt (fun t : ℝ => hd (P + t • v)) 0 0 := by
      have e : (fun t : ℝ => hd (P + t • v)) = fun _ => 0 := by
        funext t; simp [hd, P, v]; ring
      rw [e]; exact hasDerivAt_const _ _
    have e0 := A0.unique B0
    have eh := Ah.unique Bh
    have hst := congrArg (fun w => inner ℝ w v) hstat
    simp only [inner_add_left, real_inner_smul_left, inner_gradient_left, hgg,
      inner_zero_left, e0, eh] at hst
    norm_num at hst

/-! ### The card's worked numbers, exactly

Cost `0.3 x₁² + 0.2 x₂²`, node 1 cap `f1 = x₁ + 4x₂ - 25`, node 2 cap `f2 = 3x₁ + x₂ - 25`,
demand `h = x₁ + x₂ - 10`. The card's `0.3333` and `-3.3333` are `1/3` and `-10/3`. -/

-- Guess "no cap binds": equal slopes 0.6 * 4 = 0.4 * 6, demand 4 + 6 = 10, cost 12.00.
example : (6 / 10 : ℚ) * 4 = 4 / 10 * 6 ∧ (4 : ℚ) + 6 = 10 := by norm_num
example : (3 / 10 : ℚ) * 4 ^ 2 + 2 / 10 * 6 ^ 2 = 12 := by norm_num
-- Node 1 pressure there: 10 + 4 + 4 * 6 = 38 m, over the 35 m cap.
example : (10 + 4 + 4 * 6 : ℕ) = 38 ∧ 35 < 38 := by decide
-- Guess "node 1 binds": x = (5, 5) meets x1 + 4 x2 = 25 and x1 + x2 = 10; cost 12.50.
example : (5 + 4 * 5 : ℕ) = 25 ∧ 5 + 5 = 10 := by decide
example : (3 / 10 : ℚ) * 5 ^ 2 + 2 / 10 * 5 ^ 2 = 25 / 2 := by norm_num
-- Cost slope at (5, 5) is (3, 2).
example : (6 / 10 : ℚ) * 5 = 3 ∧ (4 / 10 : ℚ) * 5 = 2 := by norm_num
-- Stationarity: (3, 2) + (1/3)(1, 4) + (-10/3)(1, 1) = (0, 0).
example : (3 : ℚ) + 1 / 3 * 1 + (-10 / 3) * 1 = 0 ∧ (2 : ℚ) + 1 / 3 * 4 + (-10 / 3) * 1 = 0 := by
  norm_num
-- Node 2 cap at (5, 5): 3 * 5 + 5 - 25 = -5, slack, so lam2 = 0.
example : (3 * 5 + 5 - 25 : ℤ) = -5 := by decide
-- LICQ: the binding gradients (1, 4) and (1, 1) have determinant -3.
example : (1 * 1 - 4 * 1 : ℤ) = -3 := by decide
-- The certificate: at these prices the Lagrangian is 12.50 plus two squares, so q = 12.50.
example (x₁ x₂ : ℚ) :
    3 / 10 * x₁ ^ 2 + 2 / 10 * x₂ ^ 2 + 1 / 3 * (x₁ + 4 * x₂ - 25) + (-10 / 3) * (x₁ + x₂ - 10)
      = 25 / 2 + 3 / 10 * (x₁ - 5) ^ 2 + 2 / 10 * (x₂ - 5) ^ 2 := by ring
-- On the demand line the cost is at least 12.50 - (1/3) f1.
example (x₁ x₂ : ℚ) (hd : x₁ + x₂ - 10 = 0) :
    3 / 10 * x₁ ^ 2 + 2 / 10 * x₂ ^ 2 - (25 / 2 - 1 / 3 * (x₁ + 4 * x₂ - 25))
      = 3 / 10 * (x₁ - 5) ^ 2 + 2 / 10 * (x₂ - 5) ^ 2 := by
  have : x₂ = 10 - x₁ := by linarith
  subst this; ring
-- Drop the sign rule: guess "node 2 binds" gives (7.5, 2.5) at 18.125 with lam2 = -1.75, nu = 0.75.
example : (3 : ℚ) * (15 / 2) + 5 / 2 = 25 ∧ (15 / 2 : ℚ) + 5 / 2 = 10 := by norm_num
example : (3 / 10 : ℚ) * (15 / 2) ^ 2 + 2 / 10 * (5 / 2) ^ 2 = 145 / 8 := by norm_num
example : (6 / 10 : ℚ) * (15 / 2) + (-7 / 4) * 3 + 3 / 4 = 0 ∧
    (4 / 10 : ℚ) * (5 / 2) + (-7 / 4) * 1 + 3 / 4 = 0 := by norm_num
-- Drop complementary slackness: (6, 4) costs 14.00, f1 = -3, lam1 = 2/3, lam1 * f1 = -2.
example : (3 / 10 : ℚ) * 6 ^ 2 + 2 / 10 * 4 ^ 2 = 14 := by norm_num
example : (6 + 4 * 4 - 25 : ℤ) = -3 := by decide
example : (6 / 10 : ℚ) * 6 + 2 / 3 * 1 + (-64 / 15) * 1 = 0 ∧
    (4 / 10 : ℚ) * 4 + 2 / 3 * 4 + (-64 / 15) * 1 = 0 := by norm_num
example : (2 / 3 : ℚ) * (-3) = -2 := by norm_num
-- Both caps as equalities: they cross at (75/11, 50/11), which delivers 125/11 kW, not 10.
example : (75 / 11 : ℚ) + 4 * (50 / 11) = 25 ∧ 3 * (75 / 11 : ℚ) + 50 / 11 = 25 ∧
    (75 / 11 : ℚ) + 50 / 11 = 125 / 11 ∧ (125 / 11 : ℚ) ≠ 10 := by norm_num
-- Squared cap: the best nu = -2.5 leaves residual (0.5, -0.5), squared length 1/2.
example : ((3 : ℚ) + (-5 / 2)) ^ 2 + ((2 : ℚ) + (-5 / 2)) ^ 2 = 1 / 2 := by norm_num
-- Cap sweep: at 37 m, x = (13/3, 17/3), lam1 = 1/9, cost 217/18 (12.056).
example : (13 / 3 : ℚ) + 4 * (17 / 3) = 37 - 10 ∧ (13 / 3 : ℚ) + 17 / 3 = 10 := by norm_num
example : (3 / 10 : ℚ) * (13 / 3) ^ 2 + 2 / 10 * (17 / 3) ^ 2 = 217 / 18 := by norm_num
example : 3 * (1 / 9 : ℚ) = 6 / 10 * (13 / 3) - 4 / 10 * (17 / 3) := by norm_num
-- At 32 m, x = (6, 4), lam1 = 2/3, cost 14.
example : (6 : ℚ) + 4 * 4 = 32 - 10 ∧ 3 * (2 / 3 : ℚ) = 6 / 10 * 6 - 4 / 10 * 4 := by norm_num
-- At 28 m, x = (22/3, 8/3), lam1 = 10/9, cost 158/9 (17.556).
example : (22 / 3 : ℚ) + 4 * (8 / 3) = 28 - 10 ∧ (22 / 3 : ℚ) + 8 / 3 = 10 := by norm_num
example : (3 / 10 : ℚ) * (22 / 3) ^ 2 + 2 / 10 * (8 / 3) ^ 2 = 158 / 9 := by norm_num
example : 3 * (10 / 9 : ℚ) = 6 / 10 * (22 / 3) - 4 / 10 * (8 / 3) := by norm_num
-- At 38 m and above the cap slackens: (4, 6) gives node 1 exactly 38 m.
example : (10 + 4 + 4 * 6 : ℕ) ≤ 38 := by decide

#print axioms kkt_point_is_global_min_of_convex
#print axioms exists_unique_kkt_multipliers_of_licq
#print axioms squared_cap_minimum_has_no_kkt_multipliers
