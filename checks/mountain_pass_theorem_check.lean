-- The mountain pass: an energy with a valley at 0 ringed by higher ground, lower ground beyond the ring and the Palais-Smale condition has a critical point at the pass height, and along the ray t sin x the energy is pi t^2/4 - 3 pi t^4/32 with peak pi/6.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Topology.Path
import Mathlib.Analysis.InnerProductSpace.Dual
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Topology.ContinuousMap.Compact

open Filter Topology

theorem mp_unif_near_compact {α β : Type*} [PseudoMetricSpace α] [PseudoMetricSpace β]
    {K : Set α} (hK : IsCompact K) {f : α → β} (hf : Continuous f) {ε : ℝ} (hε : 0 < ε) :
    ∃ η > 0, ∀ x ∈ K, ∀ z, dist z x < η → dist (f z) (f x) < ε := by
  obtain ⟨η, hη, h⟩ := lebesgue_number_lemma_of_metric hK
    (c := fun i : α => f ⁻¹' Metric.ball (f i) (ε / 2))
    (fun i => Metric.isOpen_ball.preimage hf)
    (fun x _ => Set.mem_iUnion.2 ⟨x, by simp [hε]⟩)
  refine ⟨η, hη, fun x hx z hz => ?_⟩
  obtain ⟨i, hi⟩ := h x hx
  have h1 : f z ∈ Metric.ball (f i) (ε / 2) := hi (Metric.mem_ball.2 hz)
  have h2 : f x ∈ Metric.ball (f i) (ε / 2) := hi (Metric.mem_ball_self hη)
  rw [Metric.mem_ball] at h1 h2
  calc dist (f z) (f x) ≤ dist (f z) (f i) + dist (f x) (f i) := dist_triangle_right _ _ _
    _ < ε := by linarith

#print axioms mp_unif_near_compact

theorem mp_ekeland {X : Type*} [MetricSpace X] [CompleteSpace X] (Φ : X → ℝ) (hΦ : Continuous Φ)
    (b : ℝ) (hb : ∀ x, b ≤ Φ x) (ε : ℝ) (hε : 0 < ε) (x₀ : X) :
    ∃ x, Φ x ≤ Φ x₀ ∧ ∀ y, Φ x ≤ Φ y + ε * dist y x := by
  classical
  set S : X → Set X := fun x => {y | Φ y + ε * dist y x ≤ Φ x} with hS
  have S_refl : ∀ x, x ∈ S x := fun x => by simp [hS]
  have S_trans : ∀ x y z, y ∈ S x → z ∈ S y → z ∈ S x := by
    intro x y z hy hz
    simp only [hS, Set.mem_ofPred_eq] at *
    have := dist_triangle z y x
    nlinarith
  have S_closed : ∀ x, IsClosed (S x) := fun x =>
    isClosed_le (by fun_prop) continuous_const
  have step : ∀ (x : X) (n : ℕ), ∃ x' ∈ S x, ∀ y ∈ S x, Φ x' ≤ Φ y + 1 / ((n : ℝ) + 1) := by
    intro x n
    have hne : (Φ '' S x).Nonempty := ⟨Φ x, x, S_refl x, rfl⟩
    have hbdd : BddBelow (Φ '' S x) := ⟨b, by rintro _ ⟨y, -, rfl⟩; exact hb y⟩
    have hlt : sInf (Φ '' S x) < sInf (Φ '' S x) + 1 / ((n : ℝ) + 1) := by
      have : (0:ℝ) < 1 / ((n : ℝ) + 1) := by positivity
      linarith
    obtain ⟨_, ⟨x', hx', rfl⟩, hx'lt⟩ := exists_lt_of_csInf_lt hne hlt
    refine ⟨x', hx', fun y hy => ?_⟩
    have := csInf_le hbdd ⟨y, hy, rfl⟩
    linarith
  choose nxt hnxtS hnxt using step
  let u : ℕ → X := fun n => Nat.rec x₀ (fun k xk => nxt xk k) n
  have hu0 : u 0 = x₀ := rfl
  have husucc : ∀ n, u (n + 1) = nxt (u n) n := fun n => rfl
  have hmono : ∀ n m, n ≤ m → u m ∈ S (u n) := by
    intro n m hnm
    induction m, hnm using Nat.le_induction with
    | base => exact S_refl _
    | succ m _ ih => rw [husucc]; exact S_trans _ _ _ ih (hnxtS _ _)
  have hdiam : ∀ n m, n + 1 ≤ m → ε * dist (u m) (u (n+1)) ≤ 1 / ((n : ℝ) + 1) := by
    intro n m hnm
    have h1 := hmono (n+1) m hnm
    have h2 := hnxt (u n) n (u m) (S_trans _ _ _ (hnxtS _ _) (husucc n ▸ h1))
    rw [← husucc] at h2
    simp only [hS, Set.mem_ofPred_eq] at h1
    linarith
  have hcauchy : CauchySeq u := by
    rw [Metric.cauchySeq_iff']
    intro δ hδ
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt (show 0 < δ * ε by positivity)
    refine ⟨n + 1, fun m hm => ?_⟩
    have := hdiam n m hm
    by_contra hcon
    push Not at hcon
    nlinarith
  obtain ⟨xb, hxb⟩ := cauchySeq_tendsto_of_complete hcauchy
  have hxbS : ∀ n, xb ∈ S (u n) := fun n =>
    (S_closed _).mem_of_tendsto hxb (eventually_atTop.2 ⟨n, fun m hm => hmono n m hm⟩)
  refine ⟨xb, ?_, ?_⟩
  · have := hxbS 0
    simp only [hS, Set.mem_ofPred_eq, hu0] at this
    nlinarith [dist_nonneg (x := xb) (y := x₀)]
  · intro y
    by_contra hcon
    push Not at hcon
    have hyS : ∀ n, y ∈ S (u n) := fun n =>
      S_trans _ _ _ (hxbS n) (by simp only [hS, Set.mem_ofPred_eq]; linarith)
    have key : ∀ n : ℕ, Φ xb ≤ Φ y + 1 / ((n : ℝ) + 1) := by
      intro n
      have h1 := hnxt (u n) n y (hyS n)
      have h2 := hxbS (n+1)
      rw [husucc] at h2
      simp only [hS, Set.mem_ofPred_eq] at h2
      nlinarith [dist_nonneg (x := xb) (y := nxt (u n) n)]
    have hlt : Φ y < Φ xb := by nlinarith [dist_nonneg (x := y) (y := xb)]
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt (sub_pos.2 hlt)
    linarith [key n]

#print axioms mp_ekeland

theorem mp_sup_continuous {E : Type*} [NormedAddCommGroup E] (J : E → ℝ) (hJ : Continuous J) :
    Continuous (fun f : C(unitInterval, E) => ⨆ s, J (f s)) := by
  have hsup : Continuous (fun f : C(unitInterval, ℝ) => ⨆ s, f s) := by
    refine (LipschitzWith.of_le_add fun f g => ?_).continuous
    have hg : BddAbove (Set.range g) := (isCompact_range g.continuous).bddAbove
    refine ciSup_le fun s => ?_
    have h1 : f s - g s ≤ dist f g := by
      have := ContinuousMap.dist_apply_le_dist (f := f) (g := g) s
      rw [Real.dist_eq] at this
      linarith [le_abs_self (f s - g s)]
    have h2 : g s ≤ ⨆ s, g s := le_ciSup hg s
    linarith
  exact hsup.comp (ContinuousMap.continuous_postcomp ⟨J, hJ⟩)

#print axioms mp_sup_continuous

theorem mp_deform {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]
    (J : E → ℝ) (hJ : ContDiff ℝ 1 J) (γ : C(unitInterval, E)) (M ε δ₀ : ℝ)
    (hM : ∀ s, J (γ s) ≤ M) (hMpos : 0 < M) (hε : 0 < ε) (hδ₀ : 0 < δ₀)
    (h0 : J (γ 0) ≤ 0) (h1 : J (γ 1) ≤ 0)
    (hgrad : ∀ s, M - δ₀ ≤ J (γ s) → 2 * ε ≤ ‖fderiv ℝ J (γ s)‖) :
    ∃ γ' : C(unitInterval, E), γ' 0 = γ 0 ∧ γ' 1 = γ 1 ∧ ∃ t > 0,
      (∀ s, ‖γ' s - γ s‖ ≤ t) ∧ ∀ s, J (γ' s) ≤ M - 3 / 2 * t * ε := by
  have hJd : Differentiable ℝ J := hJ.differentiable one_ne_zero
  have hJ' : Continuous (fderiv ℝ J) := hJ.continuous_fderiv one_ne_zero
  have hJc : Continuous J := hJ.continuous
  obtain ⟨η, hη, hηprop⟩ := mp_unif_near_compact (isCompact_range γ.continuous) hJ' (half_pos hε)
  set t := min (η / 2) (min (δ₀ / (3 * ε)) (M / (6 * ε))) with ht
  have htpos : 0 < t := lt_min (half_pos hη) (lt_min (by positivity) (by positivity))
  have htη : t < η := by have := min_le_left (η / 2) (min (δ₀ / (3 * ε)) (M / (6 * ε))); linarith
  have htδ : 3 * t * ε ≤ δ₀ := by
    have h := (min_le_right (η / 2) _).trans (min_le_left (δ₀ / (3 * ε)) (M / (6 * ε)))
    rw [← ht, le_div_iff₀ (by positivity)] at h
    linarith
  have htM : 3 * t * ε ≤ M / 2 := by
    have h := (min_le_right (η / 2) _).trans (min_le_right (δ₀ / (3 * ε)) (M / (6 * ε)))
    rw [← ht, le_div_iff₀ (by positivity)] at h
    linarith
  set g : unitInterval → E := fun s => (InnerProductSpace.toDual ℝ E).symm (fderiv ℝ J (γ s))
    with hg_def
  set ρ : unitInterval → ℝ := fun s => min 1 (max 0 (2 * J (γ s) / M)) with hρ_def
  set m : unitInterval → ℝ := fun s => max ‖g s‖ (2 * ε) with hm_def
  set w : unitInterval → E := fun s => (ρ s / m s) • g s with hw_def
  have hg : Continuous g :=
    (InnerProductSpace.toDual ℝ E).symm.continuous.comp (hJ'.comp γ.continuous)
  have hρ : Continuous ρ := by
    simp only [hρ_def]; fun_prop
  have hmpos : ∀ s, 0 < m s := fun s => lt_max_of_lt_right (by positivity)
  have hm : Continuous m := (continuous_norm.comp hg).max continuous_const
  have hw : Continuous w := (hρ.div hm fun s => (hmpos s).ne').smul hg
  let γ' : C(unitInterval, E) := ⟨fun s => γ s - t • w s, γ.continuous.sub (continuous_const.smul hw)⟩
  have hγ' : ∀ s, γ' s = γ s - t • w s := fun s => rfl
  have hρ01 : ∀ s, 0 ≤ ρ s ∧ ρ s ≤ 1 := fun s =>
    ⟨le_min zero_le_one (le_max_left _ _), min_le_left _ _⟩
  have hρ0 : ∀ s, J (γ s) ≤ 0 → ρ s = 0 := by
    intro s hs
    have : 2 * J (γ s) / M ≤ 0 := div_nonpos_of_nonpos_of_nonneg (by linarith) hMpos.le
    simp only [hρ_def, max_eq_left this, min_eq_right zero_le_one]
  have hgn : ∀ s, ‖g s‖ = ‖fderiv ℝ J (γ s)‖ := fun s => LinearIsometryEquiv.norm_map _ _
  have hg_apply : ∀ s v, fderiv ℝ J (γ s) v = inner ℝ (g s) v := fun s v =>
    (InnerProductSpace.toDual_symm_apply).symm
  have hwn : ∀ s, ‖w s‖ ≤ 1 := by
    intro s
    rw [hw_def, norm_smul, Real.norm_eq_abs, abs_div, abs_of_nonneg (hρ01 s).1,
      abs_of_pos (hmpos s)]
    have h1 : ‖g s‖ ≤ m s := le_max_left _ _
    calc ρ s / m s * ‖g s‖ ≤ ρ s / m s * m s :=
          mul_le_mul_of_nonneg_left h1 (div_nonneg (hρ01 s).1 (hmpos s).le)
      _ = ρ s := div_mul_cancel₀ _ (hmpos s).ne'
      _ ≤ 1 := (hρ01 s).2
  have hdw : ∀ s, fderiv ℝ J (γ s) (w s) = ρ s / m s * ‖g s‖ ^ 2 := by
    intro s
    rw [hg_apply, hw_def, inner_smul_right, real_inner_self_eq_norm_sq]
  have hdw_nonneg : ∀ s, 0 ≤ ρ s / m s * ‖g s‖ ^ 2 := fun s =>
    mul_nonneg (div_nonneg (hρ01 s).1 (hmpos s).le) (sq_nonneg _)
  refine ⟨γ', ?_, ?_, t, htpos, ?_, ?_⟩
  · rw [hγ', hw_def]; simp only; rw [hρ0 0 h0]; simp
  · rw [hγ', hw_def]; simp only; rw [hρ0 1 h1]; simp
  · intro s
    rw [hγ', sub_sub_cancel_left, norm_neg, norm_smul, Real.norm_eq_abs, abs_of_pos htpos]
    calc t * ‖w s‖ ≤ t * 1 := mul_le_mul_of_nonneg_left (hwn s) htpos.le
      _ = t := mul_one t
  · intro s
    have hdisp : γ' s - γ s = -(t • w s) := by rw [hγ']; abel
    have hnd : ‖γ' s - γ s‖ ≤ t := by
      rw [hdisp, norm_neg, norm_smul, Real.norm_eq_abs, abs_of_pos htpos]
      calc t * ‖w s‖ ≤ t * 1 := mul_le_mul_of_nonneg_left (hwn s) htpos.le
        _ = t := mul_one t
    have hmem : γ' s ∈ Metric.ball (γ s) η := by
      rw [Metric.mem_ball, dist_eq_norm]; linarith
    have mvt := Convex.norm_image_sub_le_of_norm_fderiv_le' (𝕜 := ℝ) (f := J)
      (s := Metric.ball (γ s) η) (φ := fderiv ℝ J (γ s)) (C := ε / 2)
      (fun z _ => hJd z)
      (fun z hz => by
        have := hηprop (γ s) ⟨s, rfl⟩ z (Metric.mem_ball.1 hz)
        rw [dist_eq_norm] at this
        exact this.le)
      (convex_ball _ _) (Metric.mem_ball_self hη) hmem
    have lin : fderiv ℝ J (γ s) (γ' s - γ s) = -(t * (ρ s / m s * ‖g s‖ ^ 2)) := by
      rw [hdisp, map_neg, map_smul, hdw, smul_eq_mul]
    rw [lin] at mvt
    have key : J (γ' s) ≤ J (γ s) - t * (ρ s / m s * ‖g s‖ ^ 2) + ε / 2 * t := by
      have h1 := le_abs_self (J (γ' s) - J (γ s) - -(t * (ρ s / m s * ‖g s‖ ^ 2)))
      rw [← Real.norm_eq_abs] at h1
      have h2 : ε / 2 * ‖γ' s - γ s‖ ≤ ε / 2 * t :=
        mul_le_mul_of_nonneg_left hnd (by positivity)
      linarith
    by_cases hcase : J (γ s) ≤ M - 3 * t * ε
    · have := mul_nonneg htpos.le (hdw_nonneg s)
      nlinarith
    · push Not at hcase
      have hg2 : 2 * ε ≤ ‖g s‖ := by rw [hgn]; exact hgrad s (by linarith)
      have hρ1 : ρ s = 1 := by
        have : 1 ≤ 2 * J (γ s) / M := by
          rw [le_div_iff₀ hMpos]; linarith
        simp only [hρ_def]
        rw [max_eq_right (by linarith), min_eq_left this]
      have hms : m s = ‖g s‖ := max_eq_left hg2
      have hgpos : 0 < ‖g s‖ := by linarith
      have hval : ρ s / m s * ‖g s‖ ^ 2 = ‖g s‖ := by
        rw [hρ1, hms]; field_simp
      rw [hval] at key
      nlinarith [hM s]

#print axioms mp_deform

/-- The mountain pass theorem (Ambrosetti and Rabinowitz). Let `J` be a continuously
differentiable energy on a real Hilbert space that satisfies the Palais-Smale condition: every
sequence with bounded energies whose derivative tends to 0 has a convergent subsequence. Suppose
`J 0 = 0`, `J ≥ β > 0` on the sphere of radius `r₀ > 0` (the ring), and `J u₁ ≤ 0` at some `u₁`
outside that sphere (the lower ground). Then the pass height `c`, the lowest over all paths from
`0` to `u₁` of the highest energy on the path, satisfies `c ≥ β`, and some `u` has `J u = c` and
`J' u = 0`: the pass height is a critical value. -/
theorem mountain_pass_critical_point
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]
    (J : E → ℝ) (hJ : ContDiff ℝ 1 J)
    (hPS : ∀ u : ℕ → E, (∃ C : ℝ, ∀ n, |J (u n)| ≤ C) →
      Tendsto (fun n => ‖fderiv ℝ J (u n)‖) atTop (𝓝 0) →
      ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ v : E, Tendsto (u ∘ φ) atTop (𝓝 v))
    (h0 : J 0 = 0) (r₀ β : ℝ) (hr₀ : 0 < r₀) (hβ : 0 < β)
    (hring : ∀ u : E, ‖u‖ = r₀ → β ≤ J u)
    (u₁ : E) (hu₁ : r₀ < ‖u₁‖) (hJu₁ : J u₁ ≤ 0) :
    β ≤ (⨅ γ : Path (0 : E) u₁, ⨆ s, J (γ s)) ∧
      ∃ u : E, J u = (⨅ γ : Path (0 : E) u₁, ⨆ s, J (γ s)) ∧ fderiv ℝ J u = 0 := by
  have hJc : Continuous J := hJ.continuous
  have hJ' : Continuous (fderiv ℝ J) := hJ.continuous_fderiv one_ne_zero
  have hbdd : ∀ γ : Path (0 : E) u₁, BddAbove (Set.range fun s => J (γ s)) :=
    fun γ => (isCompact_range (hJc.comp γ.continuous)).bddAbove
  have hne : Nonempty (Path (0 : E) u₁) :=
    ⟨{ toFun := fun s => (s : ℝ) • u₁, continuous_toFun := by fun_prop,
       source' := by simp, target' := by simp }⟩
  have hβ_le : ∀ γ : Path (0 : E) u₁, β ≤ ⨆ s, J (γ s) := by
    intro γ
    have hcont : Continuous fun s => ‖γ s‖ := continuous_norm.comp γ.continuous
    have hmem : r₀ ∈ Set.Icc ‖γ 0‖ ‖γ 1‖ := by
      rw [γ.source, γ.target, norm_zero]; exact ⟨hr₀.le, hu₁.le⟩
    obtain ⟨s, hs⟩ := intermediate_value_univ 0 1 hcont hmem
    exact (hring _ hs).trans (le_ciSup (hbdd γ) s)
  set c := ⨅ γ : Path (0 : E) u₁, ⨆ s, J (γ s) with hc
  have hβc : β ≤ c := le_ciInf hβ_le
  have hcbdd : BddBelow (Set.range fun γ : Path (0 : E) u₁ => ⨆ s, J (γ s)) :=
    ⟨β, by rintro _ ⟨γ, rfl⟩; exact hβ_le γ⟩
  refine ⟨hβc, ?_⟩
  have hX : IsClosed {f : C(unitInterval, E) | f 0 = 0 ∧ f 1 = u₁} :=
    (isClosed_eq (continuous_eval_const (0 : unitInterval)) continuous_const).inter
      (isClosed_eq (continuous_eval_const (1 : unitInterval)) continuous_const)
  haveI : CompleteSpace {f : C(unitInterval, E) | f 0 = 0 ∧ f 1 = u₁} := hX.completeSpace_coe
  let toPath : {f : C(unitInterval, E) | f 0 = 0 ∧ f 1 = u₁} → Path (0 : E) u₁ := fun f =>
    { toContinuousMap := f.1, source' := f.2.1, target' := f.2.2 }
  let Φ : {f : C(unitInterval, E) | f 0 = 0 ∧ f 1 = u₁} → ℝ := fun f => ⨆ s, J (f.1 s)
  have hΦc : Continuous Φ := (mp_sup_continuous J hJc).comp continuous_subtype_val
  have hΦc_le : ∀ f, c ≤ Φ f := fun f => ciInf_le hcbdd (toPath f)
  have almost : ∀ ε > 0, ∃ u, c - ε ≤ J u ∧ J u ≤ c + ε ∧ ‖fderiv ℝ J u‖ < 2 * ε := by
    intro ε hε
    obtain ⟨γ₀, hγ₀⟩ := exists_lt_of_ciInf_lt (show c < c + ε by linarith)
    let x₀ : {f : C(unitInterval, E) | f 0 = 0 ∧ f 1 = u₁} :=
      ⟨γ₀.toContinuousMap, γ₀.source, γ₀.target⟩
    obtain ⟨xb, hxb0, hxb⟩ := mp_ekeland Φ hΦc c hΦc_le ε hε x₀
    set M := Φ xb with hM
    have hMc : c ≤ M := hΦc_le xb
    have hMlt : M < c + ε := lt_of_le_of_lt hxb0 hγ₀
    have hMbdd : ∀ s, J (xb.1 s) ≤ M := fun s => le_ciSup (hbdd (toPath xb)) s
    by_contra hcon
    push Not at hcon
    have hgrad : ∀ s, M - ε ≤ J (xb.1 s) → 2 * ε ≤ ‖fderiv ℝ J (xb.1 s)‖ := by
      intro s hs
      exact hcon _ (by linarith) (by linarith [hMbdd s])
    obtain ⟨γ', hγ'0, hγ'1, t, ht, hdist, hval⟩ := mp_deform J hJ xb.1 M ε ε hMbdd
      (by linarith) hε hε (by rw [xb.2.1, h0]) (by rw [xb.2.2]; exact hJu₁) hgrad
    let y : {f : C(unitInterval, E) | f 0 = 0 ∧ f 1 = u₁} :=
      ⟨γ', by rw [hγ'0]; exact xb.2.1, by rw [hγ'1]; exact xb.2.2⟩
    have hΦy : Φ y ≤ M - 3 / 2 * t * ε := ciSup_le hval
    have hd : dist y xb ≤ t := by
      rw [Subtype.dist_eq, ContinuousMap.dist_le ht.le]
      intro s; rw [dist_eq_norm]; exact hdist s
    have := hxb y
    nlinarith
  choose u hu1 hu2 hu3 using fun n : ℕ => almost (1 / ((n : ℝ) + 1)) Nat.one_div_pos_of_nat
  have hsmall : ∀ n : ℕ, 1 / ((n : ℝ) + 1) ≤ 1 := fun n => by
    rw [div_le_one (by positivity)]; linarith [(Nat.cast_nonneg n : (0 : ℝ) ≤ n)]
  have hbddJ : ∃ C : ℝ, ∀ n, |J (u n)| ≤ C := ⟨|c| + 1, fun n => by
    rw [abs_le]
    constructor
    · linarith [hu1 n, hsmall n, neg_abs_le c]
    · linarith [hu2 n, hsmall n, le_abs_self c]⟩
  have hlim0 : Tendsto (fun n : ℕ => 2 * (1 / ((n : ℝ) + 1))) atTop (𝓝 0) := by
    simpa using (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).const_mul 2
  have hgrad0 : Tendsto (fun n => ‖fderiv ℝ J (u n)‖) atTop (𝓝 0) :=
    squeeze_zero (fun n => norm_nonneg _) (fun n => (hu3 n).le) hlim0
  obtain ⟨φ, hφ, v, hv⟩ := hPS u hbddJ hgrad0
  have hφt : Tendsto (fun n => 1 / ((φ n : ℝ) + 1)) atTop (𝓝 0) :=
    (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).comp hφ.tendsto_atTop
  have hJv1 : Tendsto (fun n => J (u (φ n))) atTop (𝓝 (J v)) :=
    (hJc.tendsto v).comp hv
  have hJv2 : Tendsto (fun n => J (u (φ n))) atTop (𝓝 c) := by
    have hl : Tendsto (fun n => c - 1 / ((φ n : ℝ) + 1)) atTop (𝓝 c) := by
      simpa using (tendsto_const_nhds (x := c)).sub hφt
    have hr : Tendsto (fun n => c + 1 / ((φ n : ℝ) + 1)) atTop (𝓝 c) := by
      simpa using (tendsto_const_nhds (x := c)).add hφt
    exact tendsto_of_tendsto_of_tendsto_of_le_of_le hl hr (fun n => hu1 (φ n)) (fun n => hu2 (φ n))
  have hD1 : Tendsto (fun n => fderiv ℝ J (u (φ n))) atTop (𝓝 (fderiv ℝ J v)) :=
    (hJ'.tendsto v).comp hv
  have hD2 : Tendsto (fun n => fderiv ℝ J (u (φ n))) atTop (𝓝 0) := by
    rw [tendsto_zero_iff_norm_tendsto_zero]
    exact hgrad0.comp hφ.tendsto_atTop
  exact ⟨v, tendsto_nhds_unique hJv1 hJv2, tendsto_nhds_unique hD1 hD2⟩

/-- The energy `J(u) = ½∫(u')² − ¼∫u⁴` on `(0, π)` along the ray `u = t sin x` equals
`π t²/4 − 3π t⁴/32`. -/
theorem energy_along_sine_ray (t : ℝ) :
    ∫ x in (0 : ℝ)..Real.pi, ((1 / 2) * (t * Real.cos x) ^ 2 - (1 / 4) * (t * Real.sin x) ^ 4)
      = Real.pi * t ^ 2 / 4 - 3 * Real.pi * t ^ 4 / 32 := by
  have h1 : ∀ x : ℝ, (1 / 2) * (t * Real.cos x) ^ 2 - (1 / 4) * (t * Real.sin x) ^ 4
      = (t ^ 2 / 2) * Real.cos x ^ 2 - (t ^ 4 / 4) * Real.sin x ^ (2 * 2) := by
    intro x; ring
  simp_rw [h1]
  rw [intervalIntegral.integral_sub, intervalIntegral.integral_const_mul,
    intervalIntegral.integral_const_mul, integral_cos_sq, integral_sin_pow_even]
  · simp [Finset.prod_range_succ]
    ring
  · exact (Continuous.intervalIntegrable (by fun_prop) _ _)
  · exact (Continuous.intervalIntegrable (by fun_prop) _ _)

/-- Along the ray `t sin x` the energy `π t²/4 − 3π t⁴/32` never exceeds `π/6`, reaches `π/6`
at `t = 2/√3`, and is below 0 at `t = 2`; so the pass height is at most `π/6`. -/
theorem sine_ray_peak_is_pi_div_six :
    (∀ t : ℝ, Real.pi * t ^ 2 / 4 - 3 * Real.pi * t ^ 4 / 32 ≤ Real.pi / 6) ∧
      Real.pi * (2 / Real.sqrt 3) ^ 2 / 4 - 3 * Real.pi * (2 / Real.sqrt 3) ^ 4 / 32
        = Real.pi / 6 ∧
      Real.pi * 2 ^ 2 / 4 - 3 * Real.pi * 2 ^ 4 / 32 < 0 := by
  refine ⟨fun t => ?_, ?_, ?_⟩
  · nlinarith [mul_nonneg Real.pi_pos.le (sq_nonneg (t ^ 2 - 4 / 3))]
  · have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
    have h4 : (2 / Real.sqrt 3) ^ 2 = 4 / 3 := by rw [div_pow, h3]; norm_num
    have h5 : (2 / Real.sqrt 3) ^ 4 = 16 / 9 := by
      rw [show (4:ℕ) = 2 * 2 from rfl, pow_mul, h4]; norm_num
    rw [h4, h5]; ring
  · nlinarith [Real.pi_pos]

-- The landscape without Palais-Smale: f(x, y) = x² + (1 − x)³ y² is −11 at (4, 1).
example : (4 : ℤ) ^ 2 + (1 - 4) ^ 3 * 1 ^ 2 = -11 := by norm_num

-- The critical exponent 2* = 2d/(d − 2): 6 at d = 3, 4 at d = 4.
example : (2 * 3 : ℚ) / (3 - 2) = 6 ∧ (2 * 4 : ℚ) / (4 - 2) = 4 := by norm_num

-- The arches k u*(k x) with one and two interior zeros have energy k⁴ c: 16 c and 81 c.
example : (2 : ℕ) ^ 4 = 16 ∧ (3 : ℕ) ^ 4 = 81 := by decide

#print axioms mountain_pass_critical_point
#print axioms energy_along_sine_ray
#print axioms sine_ray_peak_is_pi_div_six
