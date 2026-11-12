-- LaSalle's principle: a motion trapped in a closed, bounded region where the energy never rises approaches the largest set of states whose whole motion stays where the energy rate is zero, so the damped swing started below the energy of upside down settles to hanging at rest.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Normed.Module.FiniteDimension
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Topology.NhdsSet
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.UniformLimitsDeriv
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Topology.Order.MonotoneConvergence
import Mathlib.Analysis.Calculus.Deriv.MeanValue

open Filter Topology Set

/-- Two-sided Gronwall estimate for two exact solutions of `y' = f y` that stay in a set where
`f` is Lipschitz. -/
lemma lasalle_gronwall_two_sided {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : E → E) (K : Set E) (L : NNReal) (hL : LipschitzOnWith L f K)
    (u w : ℝ → E) (c S : ℝ)
    (hu : ∀ t ∈ Icc (c - S) (c + S), HasDerivAt u (f (u t)) t)
    (hw : ∀ t ∈ Icc (c - S) (c + S), HasDerivAt w (f (w t)) t)
    (huK : ∀ t ∈ Icc (c - S) (c + S), u t ∈ K) (hwK : ∀ t ∈ Icc (c - S) (c + S), w t ∈ K) :
    ∀ t ∈ Icc (c - S) (c + S), dist (u t) (w t) ≤ dist (u c) (w c) * Real.exp (L * S) := by
  intro t ht
  have hd0 : 0 ≤ dist (u c) (w c) := dist_nonneg
  rcases le_total c t with hct | htc
  · -- forward in time
    have hsub : Icc c (c + S) ⊆ Icc (c - S) (c + S) := Icc_subset_Icc (by linarith [ht.1, ht.2]) le_rfl
    have key := dist_le_of_trajectories_ODE_of_mem (v := fun _ => f) (s := fun _ => K)
      (a := c) (b := c + S) (K := L) (δ := dist (u c) (w c)) (fun _ _ => hL)
      (fun s hs => (hu s (hsub hs)).continuousAt.continuousWithinAt)
      (fun s hs => (hu s (hsub (Ico_subset_Icc_self hs))).hasDerivWithinAt)
      (fun s hs => huK s (hsub (Ico_subset_Icc_self hs)))
      (fun s hs => (hw s (hsub hs)).continuousAt.continuousWithinAt)
      (fun s hs => (hw s (hsub (Ico_subset_Icc_self hs))).hasDerivWithinAt)
      (fun s hs => hwK s (hsub (Ico_subset_Icc_self hs))) le_rfl t ⟨hct, ht.2⟩
    refine key.trans (mul_le_mul_of_nonneg_left (Real.exp_le_exp.2 ?_) hd0)
    exact mul_le_mul_of_nonneg_left (by linarith [ht.2]) L.2
  · -- backward in time: reverse the clock
    have hmem : ∀ τ ∈ Icc 0 S, c - τ ∈ Icc (c - S) (c + S) := fun τ hτ =>
      ⟨by linarith [hτ.2], by linarith [hτ.1, ht.1, ht.2]⟩
    have hLn : LipschitzOnWith L (fun y => -f y) K := by
      refine LipschitzOnWith.of_dist_le_mul fun a ha b hb => ?_
      rw [dist_neg_neg]; exact hL.dist_le_mul a ha b hb
    have hu' : ∀ τ ∈ Icc 0 S, HasDerivAt (fun τ => u (c - τ)) (-f (u (c - τ))) τ :=
      fun τ hτ => HasDerivAt.comp_const_sub c τ (hu _ (hmem τ hτ))
    have hw' : ∀ τ ∈ Icc 0 S, HasDerivAt (fun τ => w (c - τ)) (-f (w (c - τ))) τ :=
      fun τ hτ => HasDerivAt.comp_const_sub c τ (hw _ (hmem τ hτ))
    have key := dist_le_of_trajectories_ODE_of_mem (v := fun _ y => -f y) (s := fun _ => K)
      (f := fun τ => u (c - τ)) (g := fun τ => w (c - τ))
      (a := 0) (b := S) (K := L) (δ := dist (u c) (w c)) (fun _ _ => hLn)
      (fun s hs => (hu' s hs).continuousAt.continuousWithinAt)
      (fun s hs => (hu' s (Ico_subset_Icc_self hs)).hasDerivWithinAt)
      (fun s hs => huK _ (hmem s (Ico_subset_Icc_self hs)))
      (fun s hs => (hw' s hs).continuousAt.continuousWithinAt)
      (fun s hs => (hw' s (Ico_subset_Icc_self hs)).hasDerivWithinAt)
      (fun s hs => hwK _ (hmem s (Ico_subset_Icc_self hs))) (by simp) (c - t)
      ⟨by linarith, by linarith [ht.1]⟩
    simp only [sub_sub_cancel, sub_zero] at key
    refine key.trans (mul_le_mul_of_nonneg_left (Real.exp_le_exp.2 ?_) hd0)
    exact mul_le_mul_of_nonneg_left (by linarith [ht.1]) L.2

#print axioms lasalle_gronwall_two_sided

/-- A limit point of a trapped motion, along times going to infinity, lies on a whole motion
that stays in the trap and on which the energy rate is zero. -/
lemma lasalle_limit_point {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E]
    (f : E → E) (V : E → ℝ) (hV : ContDiff ℝ 1 V)
    (K : Set E) (hKc : IsClosed K) (L : NNReal) (hL : LipschitzOnWith L f K)
    (x : ℝ → E) (hxd : ∀ t, 0 < t → HasDerivAt x (f (x t)) t) (hxK : ∀ t, 0 ≤ t → x t ∈ K)
    (ℓ : ℝ) (hℓ : Tendsto (fun t => V (x t)) atTop (𝓝 ℓ))
    (τ : ℕ → ℝ) (hτ : Tendsto τ atTop atTop) (p : E)
    (hp : Tendsto (fun n => x (τ n)) atTop (𝓝 p)) :
    ∃ γ : ℝ → E, γ 0 = p ∧ (∀ t, HasDerivAt γ (f (γ t)) t) ∧
      ∀ t, γ t ∈ K ∧ fderiv ℝ V (γ t) (f (γ t)) = 0 := by
  have : CompleteSpace E := FiniteDimensional.complete ℝ E
  -- the shifted motions stay close to each other
  have hB : ∀ S : ℝ, ∀ n m, S < τ n → S < τ m → ∀ s ∈ Icc (-S) S,
      dist (x (τ n + s)) (x (τ m + s)) ≤ dist (x (τ n)) (x (τ m)) * Real.exp (L * S) := by
    intro S n m hn hm s hs
    have h := lasalle_gronwall_two_sided f K L hL (fun r => x (τ n + r)) (fun r => x (τ m + r))
      0 S
      (fun r hr => HasDerivAt.comp_const_add (τ n) r (hxd _ (by linarith [hr.1])))
      (fun r hr => HasDerivAt.comp_const_add (τ m) r (hxd _ (by linarith [hr.1])))
      (fun r hr => hxK _ (by linarith [hr.1]))
      (fun r hr => hxK _ (by linarith [hr.1])) s (by simpa using hs)
    simpa using h
  have hcauchy : ∀ s, CauchySeq (fun n => x (τ n + s)) := by
    intro s
    rw [Metric.cauchySeq_iff]
    intro ε hε
    have hexp : 0 < Real.exp (L * |s|) := Real.exp_pos _
    obtain ⟨N1, hN1⟩ := Metric.cauchySeq_iff.1 hp.cauchySeq (ε / Real.exp (L * |s|))
      (div_pos hε hexp)
    obtain ⟨N2, hN2⟩ := eventually_atTop.1 (hτ.eventually_gt_atTop |s|)
    refine ⟨max N1 N2, fun m hm n hn => ?_⟩
    have h := hB |s| m n (hN2 m (le_of_max_le_right hm)) (hN2 n (le_of_max_le_right hn)) s
      ⟨neg_abs_le s, le_abs_self s⟩
    have h2 := hN1 m (le_of_max_le_left hm) n (le_of_max_le_left hn)
    calc dist (x (τ m + s)) (x (τ n + s)) ≤ dist (x (τ m)) (x (τ n)) * Real.exp (L * |s|) := h
      _ < ε / Real.exp (L * |s|) * Real.exp (L * |s|) := mul_lt_mul_of_pos_right h2 hexp
      _ = ε := div_mul_cancel₀ ε hexp.ne'
  choose γ hγlim using fun s => cauchySeq_tendsto_of_complete (hcauchy s)
  have hγ0 : γ 0 = p := tendsto_nhds_unique (by simpa using hγlim 0) hp
  have hγK : ∀ s, γ s ∈ K := fun s =>
    hKc.mem_of_tendsto (hγlim s)
      ((hτ.eventually_ge_atTop (-s)).mono fun n hn => hxK _ (by linarith))
  -- uniform bound on the distance to the limit motion
  have hU : ∀ S : ℝ, ∀ n, S < τ n → ∀ s ∈ Icc (-S) S,
      dist (x (τ n + s)) (γ s) ≤ dist (x (τ n)) p * Real.exp (L * S) := by
    intro S n hn s hs
    refine le_of_tendsto_of_tendsto (tendsto_const_nhds.dist (hγlim s))
      ((tendsto_const_nhds.dist hp).mul_const _) ?_
    exact (hτ.eventually_gt_atTop S).mono fun m hm => hB S n m hn hm s hs
  -- the limit motion solves the rate law
  have hγd : ∀ s, HasDerivAt γ (f (γ s)) s := by
    intro s0
    set S : ℝ := |s0| + 1 with hS
    have hs0 : s0 ∈ Ioo (-S) S := ⟨by linarith [neg_abs_le s0], by linarith [le_abs_self s0]⟩
    refine hasDerivAt_of_tendstoUniformlyOn (l := atTop) (f := fun n r => x (τ n + r))
      (f' := fun n r => f (x (τ n + r))) (g := γ) (g' := fun r => f (γ r)) isOpen_Ioo ?_ ?_
      (fun r _ => hγlim r) hs0
    · rw [Metric.tendstoUniformlyOn_iff]
      intro ε hε
      have hexp : 0 < Real.exp (L * S) := Real.exp_pos _
      have hC : 0 < ((L : ℝ) + 1) * Real.exp (L * S) := by positivity
      have hp' : ∀ᶠ n in atTop, dist (x (τ n)) p < ε / (((L : ℝ) + 1) * Real.exp (L * S)) :=
        (Metric.tendsto_nhds.1 hp) _ (div_pos hε hC)
      filter_upwards [hp', hτ.eventually_gt_atTop S] with n hn hnS r hr
      have h1 := hU S n hnS r (Ioo_subset_Icc_self hr)
      have h2 : dist (f (γ r)) (f (x (τ n + r))) ≤ L * dist (γ r) (x (τ n + r)) :=
        hL.dist_le_mul _ (hγK r) _ (hxK _ (by linarith [hr.1]))
      rw [dist_comm (γ r)] at h2
      have hL0 : (0 : ℝ) ≤ L := L.2
      have hd0 : 0 ≤ dist (x (τ n + r)) (γ r) := dist_nonneg
      have h3 : dist (x (τ n)) p * (((L : ℝ) + 1) * Real.exp (L * S)) < ε := by
        rwa [lt_div_iff₀ hC] at hn
      calc dist (f (γ r)) (f (x (τ n + r))) ≤ L * dist (x (τ n + r)) (γ r) := h2
        _ ≤ ((L : ℝ) + 1) * dist (x (τ n + r)) (γ r) := by nlinarith
        _ ≤ ((L : ℝ) + 1) * (dist (x (τ n)) p * Real.exp (L * S)) :=
            mul_le_mul_of_nonneg_left h1 (by positivity)
        _ = dist (x (τ n)) p * (((L : ℝ) + 1) * Real.exp (L * S)) := by ring
        _ < ε := h3
    · filter_upwards [hτ.eventually_gt_atTop S] with n hn r hr
      exact HasDerivAt.comp_const_add (τ n) r (hxd _ (by linarith [hr.1]))
  -- the energy is constant along the limit motion, so its rate is zero
  have hVγ : ∀ s, V (γ s) = ℓ := fun s =>
    tendsto_nhds_unique ((hV.continuous.tendsto _).comp (hγlim s))
      (hℓ.comp (tendsto_atTop_add_const_right _ s hτ))
  refine ⟨γ, hγ0, hγd, fun s => ⟨hγK s, ?_⟩⟩
  have h1 : HasDerivAt (fun r => V (γ r)) (fderiv ℝ V (γ s) (f (γ s))) s :=
    ((hV.differentiable one_ne_zero) (γ s)).hasFDerivAt.comp_hasDerivAt s (hγd s)
  have h2 : HasDerivAt (fun r => V (γ r)) 0 s := by
    have : (fun r => V (γ r)) = fun _ => ℓ := funext hVγ
    rw [this]; exact hasDerivAt_const s ℓ
  exact h1.unique h2

#print axioms lasalle_limit_point

/-- The energy rate along the damped swing (used by Step 1 and Step 5). -/
lemma damped_energy_rate_aux (c : ℝ) (θ v : ℝ → ℝ) (t : ℝ)
    (hθ : HasDerivAt θ (v t) t) (hv : HasDerivAt v (-Real.sin (θ t) - c * v t) t) :
    HasDerivAt (fun s => v s ^ 2 / 2 + 1 - Real.cos (θ s)) (-c * v t ^ 2) t := by
  have h := (((hv.pow 2).div_const 2).add_const 1).sub hθ.cos
  convert h using 1
  push_cast
  ring

#print axioms damped_energy_rate_aux

/-- The energy rate of the damped swing as a derivative of the energy on the plane. -/
lemma damped_energy_fderiv (c : ℝ) (y : ℝ × ℝ) :
    fderiv ℝ (fun p : ℝ × ℝ => p.2 ^ 2 / 2 + 1 - Real.cos p.1) y
      (y.2, -Real.sin y.1 - c * y.2) = -c * y.2 ^ 2 := by
  have hW : DifferentiableAt ℝ (fun p : ℝ × ℝ => p.2 ^ 2 / 2 + 1 - Real.cos p.1) y := by
    fun_prop
  have hl : HasDerivAt (fun s : ℝ => y + s • ((y.2, -Real.sin y.1 - c * y.2) : ℝ × ℝ))
      (y.2, -Real.sin y.1 - c * y.2) 0 := by
    have := ((hasDerivAt_id (0 : ℝ)).smul_const
      ((y.2, -Real.sin y.1 - c * y.2) : ℝ × ℝ)).const_add y
    simp only [id, one_smul] at this
    exact this
  have h1 := hW.hasFDerivAt.comp_hasDerivAt_of_eq 0 hl (by rw [zero_smul, add_zero])
  have hθ : HasDerivAt (fun s : ℝ => y.1 + s * y.2)
      ((fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2)) 0) 0 := by
    have := ((hasDerivAt_id (0 : ℝ)).mul_const y.2).const_add y.1
    simp only [id, one_mul] at this
    simp only [zero_mul, add_zero]
    exact this
  have hv : HasDerivAt (fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2))
      (-Real.sin ((fun s : ℝ => y.1 + s * y.2) 0)
        - c * (fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2)) 0) 0 := by
    have := ((hasDerivAt_id (0 : ℝ)).mul_const (-Real.sin y.1 - c * y.2)).const_add y.2
    simp only [id, one_mul] at this
    simp only [zero_mul, add_zero]
    exact this
  have h2 := damped_energy_rate_aux c (fun s : ℝ => y.1 + s * y.2)
    (fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2)) 0 hθ hv
  have h3 : HasDerivAt ((fun p : ℝ × ℝ => p.2 ^ 2 / 2 + 1 - Real.cos p.1) ∘
      (fun s : ℝ => y + s • ((y.2, -Real.sin y.1 - c * y.2) : ℝ × ℝ))) (-c * y.2 ^ 2) 0 := by
    have e : ((fun p : ℝ × ℝ => p.2 ^ 2 / 2 + 1 - Real.cos p.1) ∘
        (fun s : ℝ => y + s • ((y.2, -Real.sin y.1 - c * y.2) : ℝ × ℝ))) =
        fun s => (fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2)) s ^ 2 / 2 + 1
          - Real.cos ((fun s : ℝ => y.1 + s * y.2) s) := by
      funext s
      simp only [Function.comp_apply, Prod.snd_add, Prod.fst_add, Prod.smul_mk, smul_eq_mul]
    rw [e]
    simpa only [zero_mul, add_zero] using h2
  exact h1.unique h3

#print axioms damped_energy_fderiv

/-- LaSalle's principle. Take a rate law x' = f(x) and an energy V on a finite-dimensional
real space, both with continuous slopes. Let K be a closed, bounded region that no motion
leaves once inside, with energy rate V'(x) = dV_x(f(x)) ≤ 0 throughout K. Let
Z = {x ∈ K | V'(x) = 0} be the pause set and M the largest invariant set in Z: the states p
whose whole motion, past and future, stays in Z. Then every motion starting in K approaches M
as t → ∞: it is eventually inside every open set that contains M. -/
theorem lasalle_invariance_principle
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    (f : E → E) (V : E → ℝ) (hf : ContDiff ℝ 1 f) (hV : ContDiff ℝ 1 V)
    (K : Set E) (hKc : IsClosed K) (hKb : Bornology.IsBounded K)
    (hK_trap : ∀ (γ : ℝ → E) (T : ℝ),
      (∀ t ∈ Ico 0 T, HasDerivWithinAt γ (f (γ t)) (Ico 0 T) t) →
      γ 0 ∈ K → ∀ t ∈ Ico 0 T, γ t ∈ K)
    (hV_rate : ∀ x ∈ K, fderiv ℝ V x (f x) ≤ 0)
    (x : ℝ → E) (hx : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt x (f (x t)) (Ici 0) t)
    (hx0 : x 0 ∈ K) :
    let Z : Set E := {y ∈ K | fderiv ℝ V y (f y) = 0}
    let M : Set E := {p | ∃ γ : ℝ → E, γ 0 = p ∧
      (∀ t, HasDerivAt γ (f (γ t)) t) ∧ ∀ t, γ t ∈ Z}
    Tendsto x atTop (𝓝ˢ M) := by
  intro Z M
  have hxK : ∀ t, 0 ≤ t → x t ∈ K := fun t ht =>
    hK_trap x (t + 1) (fun s hs => (hx s hs.1).mono Ico_subset_Ici_self) hx0 t
      ⟨ht, by linarith⟩
  have hxd : ∀ t, 0 < t → HasDerivAt x (f (x t)) t := fun t ht =>
    (hx t (le_of_lt ht)).hasDerivAt (Ici_mem_nhds ht)
  have hKcpt : IsCompact K := Metric.isCompact_of_isClosed_isBounded hKc hKb
  obtain ⟨L, hL⟩ :=
    (hf.locallyLipschitz.locallyLipschitzOn (s := K)).exists_lipschitzOnWith_of_compact hKcpt
  -- the energy along the motion never rises
  have hanti : AntitoneOn (fun t => V (x t)) (Ici 0) := by
    refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ici 0)
      (hV.continuous.comp_continuousOn fun t ht => (hx t ht).continuousWithinAt)
      (f' := fun t => fderiv ℝ V (x t) (f (x t))) ?_ ?_
    · intro t ht
      rw [interior_Ici] at ht
      exact (((hV.differentiable one_ne_zero) (x t)).hasFDerivAt.comp_hasDerivAt t
        (hxd t ht)).hasDerivWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      exact hV_rate _ (hxK t (le_of_lt ht))
  let W : ℝ → ℝ := fun t => V (x (max t 0))
  have hWanti : Antitone W := fun a b hab =>
    hanti (show (0 : ℝ) ≤ max a 0 from le_max_right _ _)
      (show (0 : ℝ) ≤ max b 0 from le_max_right _ _) (max_le_max hab le_rfl)
  have hbdd : BddBelow (range W) := by
    obtain ⟨m, hm⟩ := hKcpt.bddBelow_image hV.continuous.continuousOn
    refine ⟨m, ?_⟩
    rintro _ ⟨t, rfl⟩
    exact hm ⟨x (max t 0), hxK _ (le_max_right _ _), rfl⟩
  have hℓ : Tendsto (fun t => V (x t)) atTop (𝓝 (⨅ t, W t)) :=
    (tendsto_atTop_ciInf hWanti hbdd).congr'
      ((eventually_ge_atTop 0).mono fun t ht => by simp [W, max_eq_left ht])
  -- every limit point lies in M, so the motion ends near M
  rw [(hasBasis_nhdsSet M).tendsto_right_iff]
  rintro U ⟨hUo, hMU⟩
  by_contra hcon
  rw [not_eventually] at hcon
  have hfr := frequently_atTop.1 hcon
  choose τ hτge hτU using fun n : ℕ => hfr (n : ℝ)
  have hτ : Tendsto τ atTop atTop := tendsto_atTop_mono hτge tendsto_natCast_atTop_atTop
  obtain ⟨p, -, φ, hφ, hlim⟩ := hKcpt.tendsto_subseq (x := fun n => x (τ n))
    fun n => hxK _ (le_trans (Nat.cast_nonneg n) (hτge n))
  obtain ⟨γ, hγ0, hγd, hγZ⟩ := lasalle_limit_point f V hV K hKc L hL x hxd hxK _ hℓ
    (τ ∘ φ) (hτ.comp hφ.tendsto_atTop) p hlim
  have hpM : p ∈ M := ⟨γ, hγ0, hγd, fun t => hγZ t⟩
  obtain ⟨n, hn⟩ := (hlim.eventually (hUo.mem_nhds (hMU hpM))).exists
  exact hτU (φ n) hn

/-- Step 1: along the damped swing θ'' + c θ' + sin θ = 0, written as θ' = v,
v' = -sin θ - c v, the energy V = v²/2 + 1 - cos θ changes at the rate V' = -c v². -/
theorem damped_swing_energy_rate (c : ℝ) (θ v : ℝ → ℝ) (t : ℝ)
    (hθ : HasDerivAt θ (v t) t) (hv : HasDerivAt v (-Real.sin (θ t) - c * v t) t) :
    HasDerivAt (fun s => v s ^ 2 / 2 + 1 - Real.cos (θ s)) (-c * v t ^ 2) t := by
  exact damped_energy_rate_aux c θ v t hθ hv

/-- Step 5: with drag c > 0, every motion of the damped swing that starts with angle
within ±π and energy V = v²/2 + 1 - cos θ below 2 (the energy of upside down) ends hanging
at rest: θ(t) → 0 and v(t) → 0. -/
theorem damped_swing_below_top_settles (c : ℝ) (hc : 0 < c) (θ v : ℝ → ℝ)
    (hθ : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt θ (v t) (Ici 0) t)
    (hv : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt v (-Real.sin (θ t) - c * v t) (Ici 0) t)
    (hθ0 : |θ 0| ≤ Real.pi)
    (hE0 : v 0 ^ 2 / 2 + 1 - Real.cos (θ 0) < 2) :
    Tendsto θ atTop (𝓝 0) ∧ Tendsto v atTop (𝓝 0) := by
  let E0 : ℝ := v 0 ^ 2 / 2 + 1 - Real.cos (θ 0)
  let F : ℝ × ℝ → ℝ × ℝ := fun p => (p.2, -Real.sin p.1 - c * p.2)
  let W : ℝ × ℝ → ℝ := fun p => p.2 ^ 2 / 2 + 1 - Real.cos p.1
  let K : Set (ℝ × ℝ) := {p | |p.1| ≤ Real.pi ∧ W p ≤ E0}
  have hE0' : E0 < 2 := hE0
  have hF : ContDiff ℝ 1 F := by fun_prop
  have hW : ContDiff ℝ 1 W := by fun_prop
  have hrateY : ∀ y, fderiv ℝ W y (F y) = -c * y.2 ^ 2 := fun y => damped_energy_fderiv c y
  have hKc : IsClosed K := by
    show IsClosed ({p : ℝ × ℝ | |p.1| ≤ Real.pi} ∩ {p | W p ≤ E0})
    exact (isClosed_le (continuous_abs.comp continuous_fst) continuous_const).inter
      (isClosed_le hW.continuous continuous_const)
  have hcos : ∀ p ∈ K, -1 < Real.cos p.1 := by
    intro p hp
    have h2 : p.2 ^ 2 / 2 + 1 - Real.cos p.1 ≤ E0 := hp.2
    nlinarith [sq_nonneg p.2]
  have habs : ∀ p ∈ K, |p.1| < Real.pi := by
    intro p hp
    refine lt_of_le_of_ne hp.1 fun h => ?_
    have := Real.cos_abs p.1
    rw [h, Real.cos_pi] at this
    linarith [hcos p hp]
  have hKb : Bornology.IsBounded K := by
    refine isBounded_iff_forall_norm_le.2 ⟨4, fun p hp => norm_prod_le_iff.2 ⟨?_, ?_⟩⟩
    · rw [Real.norm_eq_abs]; linarith [hp.1, Real.pi_le_four]
    · have h2 : p.2 ^ 2 / 2 + 1 - Real.cos p.1 ≤ E0 := hp.2
      have := Real.cos_le_one p.1
      rw [Real.norm_eq_abs, abs_le]
      constructor <;> nlinarith [sq_nonneg p.2]
  have htrap : ∀ (γ : ℝ → ℝ × ℝ) (T : ℝ),
      (∀ t ∈ Ico 0 T, HasDerivWithinAt γ (F (γ t)) (Ico 0 T) t) →
      γ 0 ∈ K → ∀ t ∈ Ico 0 T, γ t ∈ K := by
    intro γ T hγ hγ0 t ht
    have hcont : ContinuousOn γ (Ico 0 T) := fun s hs => (hγ s hs).continuousWithinAt
    have hWγ : AntitoneOn (fun s => W (γ s)) (Ico 0 T) := by
      refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ico 0 T)
        (hW.continuous.comp_continuousOn hcont) (f' := fun s => -c * (γ s).2 ^ 2) ?_ ?_
      · intro s hs
        rw [interior_Ico] at hs
        have hd : HasDerivAt γ (F (γ s)) s :=
          (hγ s (Ioo_subset_Ico_self hs)).hasDerivAt (Ico_mem_nhds hs.1 hs.2)
        have := ((hW.differentiable one_ne_zero) (γ s)).hasFDerivAt.comp_hasDerivAt s hd
        rw [hrateY] at this
        exact this.hasDerivWithinAt
      · intro s _
        have := sq_nonneg (γ s).2
        nlinarith
    have h0 : (0 : ℝ) ∈ Ico 0 T := ⟨le_rfl, lt_of_le_of_lt ht.1 ht.2⟩
    have hE : ∀ s ∈ Ico 0 T, W (γ s) ≤ E0 := fun s hs => (hWγ h0 hs hs.1).trans hγ0.2
    refine ⟨?_, hE t ht⟩
    by_contra hbig
    replace hbig := not_le.1 hbig
    have hsub : Icc 0 t ⊆ Ico 0 T := Icc_subset_Ico_right ht.2
    have hg : ContinuousOn (fun s => |(γ s).1|) (Icc 0 t) :=
      continuous_abs.comp_continuousOn (continuous_fst.comp_continuousOn (hcont.mono hsub))
    obtain ⟨s, hs, hseq⟩ := intermediate_value_Icc ht.1 hg ⟨hγ0.1, hbig.le⟩
    have hcs : Real.cos (γ s).1 = -1 := by
      have := Real.cos_abs (γ s).1
      simp only at hseq
      rw [hseq, Real.cos_pi] at this
      exact this.symm
    have hWs : (γ s).2 ^ 2 / 2 + 1 - Real.cos (γ s).1 ≤ E0 := hE s (hsub hs)
    rw [hcs] at hWs
    nlinarith [sq_nonneg (γ s).2]
  have hrate : ∀ y ∈ K, fderiv ℝ W y (F y) ≤ 0 := by
    intro y _
    rw [hrateY]
    have := sq_nonneg y.2
    nlinarith
  let X : ℝ → ℝ × ℝ := fun t => (θ t, v t)
  have hX : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt X (F (X t)) (Ici 0) t :=
    fun t ht => (hθ t ht).prodMk (hv t ht)
  have hX0 : X 0 ∈ K := ⟨hθ0, le_rfl⟩
  have h := lasalle_invariance_principle F W hF hW K hKc hKb htrap hrate X hX hX0
  dsimp only at h
  have hM : ∀ p : ℝ × ℝ, (∃ γ : ℝ → ℝ × ℝ, γ 0 = p ∧ (∀ t, HasDerivAt γ (F (γ t)) t) ∧
      ∀ t, γ t ∈ {y ∈ K | fderiv ℝ W y (F y) = 0}) → p = (0, 0) := by
    rintro p ⟨γ, rfl, hγd, hγZ⟩
    have hv0 : ∀ t, (γ t).2 = 0 := by
      intro t
      have h1 := (hγZ t).2
      rw [hrateY] at h1
      have h2 : (γ t).2 ^ 2 = 0 := by
        rcases mul_eq_zero.1 h1 with h | h
        · exact absurd (neg_eq_zero.1 h) hc.ne'
        · exact h
      exact pow_eq_zero_iff two_ne_zero |>.1 h2
    have hd2 : HasDerivAt (fun t => (γ t).2) (F (γ 0)).2 0 := by
      have := (hasFDerivAt_snd (𝕜 := ℝ) (E := ℝ) (F := ℝ) (p := γ 0)).comp_hasDerivAt 0 (hγd 0)
      exact this
    have hd2' : HasDerivAt (fun t => (γ t).2) 0 0 := by
      have : (fun t => (γ t).2) = fun _ => (0 : ℝ) := funext hv0
      rw [this]; exact hasDerivAt_const _ _
    have hsin : Real.sin (γ 0).1 = 0 := by
      have h3 : (F (γ 0)).2 = 0 := hd2.unique hd2'
      have h4 : -Real.sin (γ 0).1 - c * (γ 0).2 = 0 := h3
      rw [hv0 0] at h4
      linarith
    have hK0 := (hγZ 0).1
    have hlt := abs_lt.1 (habs _ hK0)
    have h1 : (γ 0).1 = 0 := (Real.sin_eq_zero_iff_of_lt_of_lt hlt.1 hlt.2).1 hsin
    exact Prod.ext h1 (hv0 0)
  have h' : Tendsto X atTop (𝓝 ((0 : ℝ), (0 : ℝ))) := by
    rw [← nhdsSet_singleton]
    exact h.mono_right (nhdsSet_mono fun p hp => hM p hp)
  exact ⟨(continuous_fst.tendsto _).comp h', (continuous_snd.tendsto _).comp h'⟩

-- The card's exact energies. Released at 60 degrees with zero speed: V = 1 - cos 60° = 1/2.
example : (0 : ℝ) ^ 2 / 2 + 1 - Real.cos (Real.pi / 3) = 1 / 2 := by
  rw [Real.cos_pi_div_three]; norm_num
-- Upside down, at rest: V = 1 - cos 180° = 2.
example : (0 : ℝ) ^ 2 / 2 + 1 - Real.cos Real.pi = 2 := by
  rw [Real.cos_pi]; norm_num
-- A push of speed 3 from the bottom has energy 9/2; a push of 7/2 has energy 49/8.
example : (3 : ℚ) ^ 2 / 2 + 1 - 1 = 9 / 2 ∧ (7 / 2 : ℚ) ^ 2 / 2 + 1 - 1 = 49 / 8 := by norm_num
-- The trap at energy 1/2: the speed is at most 1, since 1²/2 = 1/2.
example : (1 : ℚ) ^ 2 / 2 = 1 / 2 := by norm_num

#print axioms lasalle_invariance_principle
#print axioms damped_swing_energy_rate
#print axioms damped_swing_below_top_settles
