-- Reflexive spaces: a real Banach space is reflexive (the reading map J from X to X'' is onto) exactly when every bounded sequence has a weakly convergent subsequence, and the bumps e_n in l1 show l1 is not reflexive.
import Mathlib.Analysis.Normed.Module.DoubleDual
import Mathlib.Analysis.Normed.Lp.lpSpace

open Filter Topology NormedSpace

theorem refl_exists_dual_vanish {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (S : Submodule ℝ X) {z : X} (hz : z ∉ S.topologicalClosure) :
    ∃ f : StrongDual ℝ X, (∀ a ∈ S, f a = 0) ∧ f z ≠ 0 := by
  obtain ⟨f, u, hf, hu⟩ := geometric_hahn_banach_closed_point
    (Submodule.convex S.topologicalClosure) S.isClosed_topologicalClosure hz
  have h0 : 0 < u := by simpa using hf 0 S.topologicalClosure.zero_mem
  refine ⟨f, fun a ha => ?_, ?_⟩
  · by_contra hne
    have := hf ((u / f a) • a)
      (S.topologicalClosure.smul_mem _ (S.le_topologicalClosure ha))
    rw [map_smul, smul_eq_mul, div_mul_cancel₀ _ hne] at this
    exact lt_irrefl _ this
  · intro h
    rw [h] at hu
    linarith

theorem refl_goldstine_approx {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (F : StrongDual ℝ (StrongDual ℝ X)) (Φ : Finset (StrongDual ℝ X)) {ε : ℝ} (hε : 0 < ε) :
    ∃ x : X, ‖x‖ ≤ ‖F‖ + 1 ∧ ∀ φ ∈ Φ, |F φ - φ x| < ε := by
  classical
  set r : ℝ := ‖F‖ + 1 with hr
  have hr0 : 0 < r := by positivity
  let T : X →L[ℝ] (Φ → ℝ) := ContinuousLinearMap.pi (fun φ => (φ : StrongDual ℝ X))
  have hT : ∀ x φ, T x φ = (φ : StrongDual ℝ X) x := fun _ _ => rfl
  let v : Φ → ℝ := fun φ => F φ
  have hv : v ∈ closure (T '' Metric.closedBall 0 r) := by
    by_contra hv
    obtain ⟨f, u, hf, hu⟩ := geometric_hahn_banach_closed_point
      (((convex_closedBall (0 : X) r).linear_image T.toLinearMap).closure) isClosed_closure hv
    have hfw : ∀ w : Φ → ℝ, f w = ∑ φ : Φ, w φ * f (Pi.single φ 1) := by
      intro w
      conv_lhs => rw [← Finset.univ_sum_single w]
      rw [map_sum]
      refine Finset.sum_congr rfl fun φ _ => ?_
      rw [← smul_eq_mul, ← map_smul]
      congr 1
      ext j
      simp [Pi.single_apply]
    let ψ : StrongDual ℝ X := ∑ φ : Φ, f (Pi.single φ 1) • (φ : StrongDual ℝ X)
    have hψ : ∀ x, f (T x) = ψ x := by
      intro x
      rw [hfw]
      simp [ψ, hT, mul_comm]
    have hFψ : F ψ = f v := by
      rw [hfw]
      simp [ψ, v, mul_comm]
    have h1 : u < ‖F‖ * ‖ψ‖ := by
      have := F.le_opNorm ψ
      rw [Real.norm_eq_abs] at this
      linarith [le_abs_self (F ψ)]
    have h2 : u / r < ‖ψ‖ := by
      rw [div_lt_iff₀ hr0]
      nlinarith [norm_nonneg ψ]
    obtain ⟨y, hy1, hy2⟩ := ψ.exists_lt_apply_of_lt_opNorm h2
    rw [Real.norm_eq_abs] at hy2
    have key : ∃ x : X, ‖x‖ ≤ r ∧ u ≤ ψ x := by
      rcases le_total 0 (ψ y) with h | h
      · refine ⟨r • y, ?_, ?_⟩
        · rw [norm_smul, Real.norm_eq_abs, abs_of_pos hr0]
          nlinarith [norm_nonneg y]
        · rw [map_smul, smul_eq_mul]
          rw [abs_of_nonneg h, div_lt_iff₀ hr0] at hy2
          linarith
      · refine ⟨(-r) • y, ?_, ?_⟩
        · rw [norm_smul, Real.norm_eq_abs, abs_neg, abs_of_pos hr0]
          nlinarith [norm_nonneg y]
        · rw [map_smul, smul_eq_mul]
          rw [abs_of_nonpos h, div_lt_iff₀ hr0] at hy2
          linarith
    obtain ⟨x, hx, hux⟩ := key
    have := hf (T x) (subset_closure ⟨x, by simpa using hx, rfl⟩)
    rw [hψ] at this
    linarith
  rw [Metric.mem_closure_iff] at hv
  obtain ⟨w, ⟨x, hx, rfl⟩, hd⟩ := hv ε hε
  refine ⟨x, by simpa using hx, fun φ hφ => ?_⟩
  have := dist_le_pi_dist v (T x) ⟨φ, hφ⟩
  rw [Real.dist_eq] at this
  exact lt_of_le_of_lt this hd

theorem refl_finite_norming {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    (E : Submodule ℝ (StrongDual ℝ V)) [FiniteDimensional ℝ E] :
    ∃ Ψ : Finset V, (∀ ψ ∈ Ψ, ‖ψ‖ ≤ 1) ∧ ∀ G ∈ E, ∃ ψ ∈ Ψ, ‖G‖ ≤ 4 * |G ψ| := by
  classical
  have hD : ∀ G : StrongDual ℝ V, ∃ ψ : V, ‖ψ‖ ≤ 1 ∧ ‖G‖ - 1 / 4 < |G ψ| := by
    intro G
    obtain ⟨ψ, h1, h2⟩ := G.exists_lt_apply_of_lt_opNorm (r := ‖G‖ - 1 / 4) (by linarith)
    exact ⟨ψ, h1.le, by simpa [Real.norm_eq_abs] using h2⟩
  choose D hD1 hD2 using hD
  set K : Set (StrongDual ℝ V) := (Subtype.val : E → _) '' Metric.closedBall (0 : E) 1
  have hK : IsCompact K := (isCompact_closedBall (0 : E) 1).image continuous_subtype_val
  obtain ⟨t, -, ht, hKt⟩ := finite_cover_balls_of_compact hK (e := 1 / 4) (by norm_num)
  refine ⟨ht.toFinset.image D, ?_, ?_⟩
  · intro ψ hψ
    obtain ⟨G, -, rfl⟩ := Finset.mem_image.1 hψ
    exact hD1 G
  · intro G hG
    set G' : StrongDual ℝ V := ‖G‖⁻¹ • G with hG'
    have hG'K : G' ∈ K := by
      refine ⟨⟨G', E.smul_mem _ hG⟩, ?_, rfl⟩
      rw [Metric.mem_closedBall, Subtype.dist_eq]
      simp only [ZeroMemClass.coe_zero, dist_zero_right, hG']
      rw [norm_smul, norm_inv, norm_norm]
      rcases eq_or_ne ‖G‖ 0 with h | h
      · simp [h]
      · rw [inv_mul_cancel₀ h]
    obtain ⟨s, hs, hGs⟩ := Set.mem_iUnion₂.1 (hKt hG'K)
    refine ⟨D s, Finset.mem_image.2 ⟨s, ht.mem_toFinset.2 hs, rfl⟩, ?_⟩
    rcases eq_or_ne G 0 with h0 | h0
    · simp [h0]
    have hn : 0 < ‖G‖ := norm_pos_iff.2 h0
    have hG'n : ‖G'‖ = 1 := by
      rw [hG', norm_smul, norm_inv, norm_norm, inv_mul_cancel₀ hn.ne']
    rw [Metric.mem_ball] at hGs
    have hds : ‖G' - s‖ < 1 / 4 := by rwa [← dist_eq_norm]
    have hs1 : 3 / 4 ≤ ‖s‖ := by
      have := norm_sub_norm_le G' s
      linarith
    have hdiff : |G' (D s) - s (D s)| ≤ 1 / 4 := by
      have := (G' - s).le_opNorm (D s)
      rw [sub_apply, Real.norm_eq_abs] at this
      nlinarith [hD1 s, norm_nonneg (G' - s), norm_nonneg (D s)]
    have hGs' : 1 / 4 ≤ |G' (D s)| := by
      have := hD2 s
      have := abs_sub_abs_le_abs_sub (s (D s)) (G' (D s))
      rw [abs_sub_comm] at this
      linarith
    have hGG : G (D s) = ‖G‖ * G' (D s) := by
      rw [hG', smul_apply, smul_eq_mul, mul_inv_cancel_left₀ hn.ne']
    rw [hGG, abs_mul, abs_of_pos hn]
    nlinarith

theorem refl_clusterPt_eq {u : ℕ → ℝ} {a b : ℝ} (h : MapClusterPt a atTop u)
    (hu : Tendsto u atTop (𝓝 b)) : a = b :=
  eq_of_nhds_neBot (ClusterPt.mono h hu)

theorem refl_norming_zero {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (d : ℕ → X) (f : ℕ → StrongDual ℝ X) (hf1 : ∀ j, ‖f j‖ ≤ 1) (hf2 : ∀ j, f j (d j) = ‖d j‖)
    {w : X} (hw : w ∈ closure (Set.range d)) (hfw : ∀ j, f j w = 0) : w = 0 := by
  rw [← norm_le_zero_iff]
  refine le_of_forall_pos_le_add fun ε hε => ?_
  obtain ⟨_, ⟨j, rfl⟩, hj⟩ := Metric.mem_closure_iff.1 hw (ε / 2) (by positivity)
  rw [dist_eq_norm] at hj
  have h1 : ‖d j‖ ≤ ‖w - d j‖ := by
    have := (f j).le_opNorm (d j - w)
    rw [map_sub, hfw, sub_zero, hf2, Real.norm_eq_abs, abs_of_nonneg (norm_nonneg _),
      norm_sub_rev] at this
    nlinarith [hf1 j, norm_nonneg (w - d j)]
  have h2 : ‖w‖ ≤ ‖w - d j‖ + ‖d j‖ := by
    calc ‖w‖ = ‖(w - d j) + d j‖ := by rw [sub_add_cancel]
      _ ≤ _ := norm_add_le _ _
  linarith

theorem refl_forward {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (hJ : Function.Surjective (inclusionInDoubleDual ℝ X))
    (x : ℕ → X) (B : ℝ) (hB : ∀ n, ‖x n‖ ≤ B) :
    ∃ n : ℕ → ℕ, StrictMono n ∧ ∃ x₀ : X,
      ∀ φ : StrongDual ℝ X, Tendsto (fun k => φ (x (n k))) atTop (𝓝 (φ x₀)) := by
  classical
  set S : Submodule ℝ X := Submodule.span ℝ (Set.range x) with hS
  have hsep : TopologicalSpace.IsSeparable (S : Set X) :=
    TopologicalSpace.IsSeparable.span (R := ℝ) (Set.countable_range x).isSeparable
  obtain ⟨c, hc, hSc⟩ := hsep
  have hc_ne : c.Nonempty := by
    by_contra h
    rw [Set.not_nonempty_iff_eq_empty] at h
    have := hSc S.zero_mem
    simp [h] at this
  obtain ⟨d, rfl⟩ := hc.exists_eq_range hc_ne
  choose f hf1 hf2 using fun j => exists_dual_vector'' ℝ (d j)
  have hf2' : ∀ j, f j (d j) = ‖d j‖ := fun j => by simpa using hf2 j
  -- diagonal subsequence
  let u : ℕ → (ℕ → ℝ) := fun n j => f j (x n)
  have hK : IsCompact (Set.pi Set.univ fun _ : ℕ => Set.Icc (-B) B) :=
    isCompact_univ_pi fun _ => isCompact_Icc
  have hu : ∀ n, u n ∈ Set.pi Set.univ fun _ : ℕ => Set.Icc (-B) B := by
    intro n j _
    have := (f j).le_opNorm (x n)
    rw [Real.norm_eq_abs] at this
    exact abs_le.1 (this.trans (by nlinarith [hf1 j, hB n, norm_nonneg (x n), norm_nonneg (f j)]))
  obtain ⟨L, -, σ, hσ, hL⟩ := hK.isSeqCompact hu
  have hLj : ∀ j, Tendsto (fun k => f j (x (σ k))) atTop (𝓝 (L j)) := fun j =>
    ((continuous_apply j).tendsto L).comp hL
  -- weak-star compactness
  let J := inclusionInDoubleDual ℝ X
  let y : ℕ → WeakDual ℝ (StrongDual ℝ X) := fun k => StrongDual.toWeakDual (J (x (σ k)))
  set K2 : Set (WeakDual ℝ (StrongDual ℝ X)) :=
    WeakDual.toStrongDual ⁻¹' Metric.closedBall (0 : StrongDual ℝ (StrongDual ℝ X)) B
  have hK2 : IsCompact K2 := WeakDual.isCompact_closedBall _ _
  have hy : ∀ k, y k ∈ K2 := by
    intro k
    show WeakDual.toStrongDual (StrongDual.toWeakDual (J (x (σ k)))) ∈
      Metric.closedBall (0 : StrongDual ℝ (StrongDual ℝ X)) B
    rw [StrongDual.toStrongDual_toWeakDual]
    have : ‖J (x (σ k))‖ ≤ B := (double_dual_bound ℝ X (x (σ k))).trans (hB _)
    rw [Metric.mem_closedBall]
    exact (dist_zero_right (J (x (σ k)))).le.trans this
  have hxS : ∀ n, x n ∈ S := fun n => Submodule.subset_span ⟨n, rfl⟩
  have hclus : ∀ G : WeakDual ℝ (StrongDual ℝ X), MapClusterPt G atTop y →
      ∃ z : X, StrongDual.toWeakDual (J z) = G ∧ z ∈ S.topologicalClosure ∧
        ∀ j, f j z = L j := by
    intro G hG
    obtain ⟨z, hz⟩ := hJ (WeakDual.toStrongDual G)
    have hzG : StrongDual.toWeakDual (J z) = G := by
      rw [show J z = WeakDual.toStrongDual G from hz, WeakDual.toWeakDual_toStrongDual]
    have hev : ∀ φ : StrongDual ℝ X, MapClusterPt (φ z) atTop (fun k => φ (x (σ k))) := by
      intro φ
      have := hG.continuousAt_comp (WeakDual.eval_continuous φ).continuousAt
      rw [← hzG] at this
      exact this
    refine ⟨z, hzG, ?_, fun j => refl_clusterPt_eq (hev (f j)) (hLj j)⟩
    by_contra hzS
    obtain ⟨φ, hφS, hφz⟩ := refl_exists_dual_vanish S hzS
    apply hφz
    refine refl_clusterPt_eq (hev φ) ?_
    simp only [hφS _ (hxS _)]
    exact tendsto_const_nhds
  obtain ⟨G0, -, hG0⟩ := hK2.exists_mapClusterPt (f := atTop) (u := y)
    (Filter.tendsto_principal.2 (Filter.Eventually.of_forall hy))
  obtain ⟨z0, hz0, hz0S, hz0L⟩ := hclus G0 hG0
  have huniq : ∀ G ∈ K2, MapClusterPt G atTop y → G = G0 := by
    intro G _ hG
    obtain ⟨z, hz, hzS, hzL⟩ := hclus G hG
    have hw : z - z0 = 0 := by
      apply refl_norming_zero d f hf1 hf2'
      · have h1 : (S.topologicalClosure : Set X) ⊆ closure (Set.range d) := by
          rw [Submodule.topologicalClosure_coe]
          exact closure_minimal hSc isClosed_closure
        exact h1 (S.topologicalClosure.sub_mem hzS hz0S)
      · intro j
        rw [map_sub, hzL, hz0L, sub_self]
    rw [sub_eq_zero] at hw
    rw [← hz, ← hz0, hw]
  have hT := hK2.tendsto_nhds_of_unique_mapClusterPt (Filter.Eventually.of_forall hy) huniq
  refine ⟨σ, hσ, z0, fun φ => ?_⟩
  have := ((WeakDual.eval_continuous φ).tendsto G0).comp hT
  rw [← hz0] at this
  exact this

theorem refl_backward {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (h : ∀ x : ℕ → X, (∃ B : ℝ, ∀ n, ‖x n‖ ≤ B) →
        ∃ n : ℕ → ℕ, StrictMono n ∧ ∃ x₀ : X,
          ∀ φ : StrongDual ℝ X, Tendsto (fun k => φ (x (n k))) atTop (𝓝 (φ x₀))) :
    Function.Surjective (inclusionInDoubleDual ℝ X) := by
  classical
  intro F
  set J := inclusionInDoubleDual ℝ X with hJ
  have hpick : ∀ (n : ℕ) (Φ : Finset (StrongDual ℝ X)), ∃ x : X, ‖x‖ ≤ ‖F‖ + 1 ∧
      ∀ φ ∈ Φ, |F φ - φ x| < 1 / ((n : ℝ) + 1) :=
    fun n Φ => refl_goldstine_approx F Φ (by positivity)
  choose pick hpick1 hpick2 using hpick
  have hnorm : ∀ P : Finset X, ∃ Ψ : Finset (StrongDual ℝ X), (∀ ψ ∈ Ψ, ‖ψ‖ ≤ 1) ∧
      ∀ G ∈ Submodule.span ℝ (insert F (J '' (P : Set X))), ∃ ψ ∈ Ψ, ‖G‖ ≤ 4 * |G ψ| := by
    intro P
    have : FiniteDimensional ℝ (Submodule.span ℝ (insert F (J '' (P : Set X)))) :=
      FiniteDimensional.span_of_finite ℝ ((P.finite_toSet.image J).insert F)
    exact refl_finite_norming _
  choose Ψ hΨ1 hΨ2 using hnorm
  let step : ℕ → Finset X × Finset (StrongDual ℝ X) → Finset X × Finset (StrongDual ℝ X) :=
    fun n s => (insert (pick n s.2) s.1, s.2 ∪ Ψ (insert (pick n s.2) s.1))
  let st : ℕ → Finset X × Finset (StrongDual ℝ X) := fun n => Nat.rec (∅, ∅) step n
  have hst : ∀ n, st (n + 1) = step n (st n) := fun n => rfl
  let x : ℕ → X := fun n => pick n (st n).2
  have hst1 : ∀ n, (st (n + 1)).1 = insert (x n) (st n).1 := fun n => by rw [hst]
  have hst2 : ∀ n, (st (n + 1)).2 = (st n).2 ∪ Ψ (st (n + 1)).1 := fun n => by rw [hst]
  have hmono1 : Monotone fun n => (st n).1 := monotone_nat_of_le_succ fun n => by
    simp only [hst1]; exact Finset.subset_insert _ _
  have hmono2 : Monotone fun n => (st n).2 := monotone_nat_of_le_succ fun n => by
    simp only [hst2]; exact Finset.subset_union_left
  have hΨsub : ∀ n, Ψ (st (n + 1)).1 ⊆ (st (n + 1)).2 := fun n => by
    rw [hst2 n]; exact Finset.subset_union_right
  have hxmem : ∀ n, x n ∈ (st (n + 1)).1 := fun n => by rw [hst1]; exact Finset.mem_insert_self _ _
  have hctrl : ∀ n m, n ≤ m → ∀ φ ∈ (st n).2, |F φ - φ (x m)| < 1 / ((m : ℝ) + 1) :=
    fun n m hnm φ hφ => hpick2 m (st m).2 φ (hmono2 hnm hφ)
  obtain ⟨σ, hσ, x0, hx0⟩ := h x ⟨‖F‖ + 1, fun n => hpick1 _ _⟩
  -- every controlled functional sees `F` and `J x0` agree
  have hΦ : ∀ n, ∀ φ ∈ (st n).2, F φ = φ x0 := by
    intro n φ hφ
    have hT : Tendsto (fun k => φ (x (σ k))) atTop (𝓝 (F φ)) := by
      rw [Metric.tendsto_atTop]
      intro ε hε
      obtain ⟨N, hN⟩ := exists_nat_one_div_lt hε
      refine ⟨max n N, fun k hk => ?_⟩
      have hk' : max n N ≤ σ k := hk.trans (hσ.id_le k)
      have h1 := hctrl n (σ k) (le_of_max_le_left hk') φ hφ
      have h2 : 1 / ((σ k : ℝ) + 1) ≤ 1 / ((N : ℝ) + 1) := by
        apply one_div_le_one_div_of_le (by positivity)
        have : (N : ℝ) ≤ σ k := by exact_mod_cast le_of_max_le_right hk'
        linarith
      rw [Real.dist_eq, abs_sub_comm]
      linarith
    exact tendsto_nhds_unique hT (hx0 φ)
  set S : Submodule ℝ X := Submodule.span ℝ (Set.range x) with hS
  have hx0S : x0 ∈ S.topologicalClosure := by
    by_contra hx0S
    obtain ⟨φ, hφS, hφx0⟩ := refl_exists_dual_vanish S hx0S
    apply hφx0
    have hT : Tendsto (fun k => φ (x (σ k))) atTop (𝓝 0) := by
      simp only [hφS _ (Submodule.subset_span ⟨_, rfl⟩)]
      exact tendsto_const_nhds
    exact tendsto_nhds_unique (hx0 φ) hT
  have hfin : ∀ y ∈ S, ∃ n, y ∈ Submodule.span ℝ ((st n).1 : Set X) := by
    intro y hy
    induction hy using Submodule.span_induction with
    | mem y hy =>
      obtain ⟨i, rfl⟩ := hy
      exact ⟨i + 1, Submodule.subset_span (Finset.mem_coe.2 (hxmem i))⟩
    | zero => exact ⟨0, Submodule.zero_mem _⟩
    | add a b _ _ ha hb =>
      obtain ⟨n, hn⟩ := ha
      obtain ⟨m, hm⟩ := hb
      have h1 : Submodule.span ℝ ((st n).1 : Set X) ≤ Submodule.span ℝ ((st (max n m)).1 : Set X) :=
        Submodule.span_mono (Finset.coe_subset.2 (hmono1 (le_max_left n m)))
      have h2 : Submodule.span ℝ ((st m).1 : Set X) ≤ Submodule.span ℝ ((st (max n m)).1 : Set X) :=
        Submodule.span_mono (Finset.coe_subset.2 (hmono1 (le_max_right n m)))
      exact ⟨max n m, Submodule.add_mem _ (h1 hn) (h2 hm)⟩
    | smul c a _ ha =>
      obtain ⟨n, hn⟩ := ha
      exact ⟨n, Submodule.smul_mem _ c hn⟩
  -- the gap `F - J x0` has norm at most `5 ε` for every `ε > 0`
  refine ⟨x0, ?_⟩
  have hsmall : ∀ ε > 0, ‖F - J x0‖ ≤ 5 * ε := by
    intro ε hε
    have hcl : x0 ∈ closure (S : Set X) := by
      rw [← Submodule.topologicalClosure_coe]; exact hx0S
    obtain ⟨y, hyS, hy⟩ := Metric.mem_closure_iff.1 hcl ε hε
    rw [dist_eq_norm] at hy
    obtain ⟨n, hn⟩ := hfin y hyS
    have hn' : y ∈ Submodule.span ℝ ((st (n + 1)).1 : Set X) :=
      Submodule.span_mono (Finset.coe_subset.2 (hmono1 (Nat.le_succ n))) hn
    set P := (st (n + 1)).1
    have hG' : F - J y ∈ Submodule.span ℝ (insert F (J '' (P : Set X))) := by
      refine Submodule.sub_mem _ (Submodule.subset_span (Set.mem_insert _ _)) ?_
      have : J y ∈ Submodule.span ℝ (J '' (P : Set X)) := by
        exact Submodule.apply_mem_span_image_of_mem_span (J : X →ₗ[ℝ] StrongDual ℝ (StrongDual ℝ X)) hn'
      exact Submodule.span_mono (Set.subset_insert _ _) this
    obtain ⟨ψ, hψΨ, hψ⟩ := hΨ2 P _ hG'
    have hψ1 := hΨ1 P ψ hψΨ
    have hψF : F ψ = ψ x0 := hΦ (n + 1) ψ (hΨsub n hψΨ)
    have hval : (F - J y) ψ = ψ (x0 - y) := by
      rw [sub_apply, map_sub, hψF]
      simp [J, NormedSpace.dual_def]
    have h1 : |(F - J y) ψ| ≤ ε := by
      rw [hval]
      have := ψ.le_opNorm (x0 - y)
      rw [Real.norm_eq_abs] at this
      nlinarith [norm_nonneg ψ, norm_nonneg (x0 - y)]
    have h2 : ‖J x0 - J y‖ ≤ ‖x0 - y‖ := by
      rw [← map_sub]; exact NormedSpace.double_dual_bound ℝ X _
    have h3 : ‖F - J x0‖ ≤ ‖F - J y‖ + ‖J x0 - J y‖ := by
      calc ‖F - J x0‖ = ‖(F - J y) - (J x0 - J y)‖ := by congr 1; abel
        _ ≤ _ := norm_sub_le (F - J y) (J x0 - J y)
    linarith
  have h0 : ‖F - J x0‖ ≤ 0 := by
    refine le_of_forall_pos_le_add fun ε hε => ?_
    have := hsmall (ε / 5) (by positivity)
    linarith
  have h00 : F - J x0 = 0 := (norm_le_zero_iff (a := F - J x0)).1 h0
  rw [sub_eq_zero] at h00
  exact h00.symm

/-- Coordinate functional on ℓ¹. -/
noncomputable def ell1Coord (i : ℕ) : StrongDual ℝ (lp (fun _ : ℕ => ℝ) 1) :=
  LinearMap.mkContinuous
    { toFun := fun x => x i
      map_add' := fun x y => by simp
      map_smul' := fun c x => by simp }
    1 (fun x => by
      have := lp.norm_apply_le_norm (p := 1) (by norm_num) x i
      show ‖x i‖ ≤ 1 * ‖x‖
      rw [one_mul]; exact this)

theorem ell1Coord_apply (i : ℕ) (x : lp (fun _ : ℕ => ℝ) 1) : ell1Coord i x = x i := rfl

#print axioms refl_exists_dual_vanish
#print axioms refl_goldstine_approx
#print axioms refl_finite_norming
#print axioms refl_clusterPt_eq
#print axioms refl_norming_zero
#print axioms refl_forward
#print axioms refl_backward
#print axioms ell1Coord_apply
#print axioms ell1Coord

/-- A real Banach space `X` is reflexive, meaning the reading map `J : X → X''`,
`(J x)(φ) = φ(x)`, is onto, exactly when every bounded sequence `x n` has a subsequence
`x (n k)` that converges weakly to some point `x₀` of `X`: every bounded linear
measurement `φ` has `φ (x (n k)) → φ x₀`. -/
theorem reflexive_iff_bounded_seq_has_weakly_convergent_subseq
    (X : Type*) [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X] :
    Function.Surjective (inclusionInDoubleDual ℝ X) ↔
      ∀ x : ℕ → X, (∃ B : ℝ, ∀ n, ‖x n‖ ≤ B) →
        ∃ n : ℕ → ℕ, StrictMono n ∧ ∃ x₀ : X,
          ∀ φ : StrongDual ℝ X, Tendsto (fun k => φ (x (n k))) atTop (𝓝 (φ x₀)) := by
  exact ⟨fun hJ x ⟨B, hB⟩ => refl_forward hJ x B hB, refl_backward⟩

/-- The drifting bumps `e_n` in `ℓ^1` (1 in place `n`, 0 elsewhere) have size 1, yet no
subsequence of them converges weakly to any point of `ℓ^1`. -/
theorem ell1_bumps_have_no_weakly_convergent_subseq :
    ¬ ∃ n : ℕ → ℕ, StrictMono n ∧ ∃ x₀ : lp (fun _ : ℕ => ℝ) 1,
      ∀ φ : StrongDual ℝ (lp (fun _ : ℕ => ℝ) 1),
        Tendsto (fun k => φ (lp.single 1 (n k) (1 : ℝ))) atTop (𝓝 (φ x₀)) := by
  rintro ⟨n, hn, x₀, h⟩
  have hcoord : ∀ i, x₀ i = 0 := by
    intro i
    have h1 := h (ell1Coord i)
    have h2 : Tendsto (fun k => ell1Coord i (lp.single 1 (n k) (1 : ℝ))) atTop (𝓝 0) := by
      apply tendsto_const_nhds.congr'
      filter_upwards [eventually_gt_atTop i] with k hk
      have : n k ≠ i := by
        have : k ≤ n k := hn.id_le k
        omega
      rw [ell1Coord_apply, lp.single_apply]
      simp [Ne.symm this]
    rw [← ell1Coord_apply]
    exact tendsto_nhds_unique h1 h2
  have hx₀ : x₀ = 0 := by
    ext i
    simp [hcoord i]
  have h1 := h (lp.tsumCLM (α := ℕ) (𝕜 := ℝ) (E := ℝ))
  have h2 : Tendsto (fun k => lp.tsumCLM (α := ℕ) (𝕜 := ℝ) (E := ℝ)
      (lp.single 1 (n k) (1 : ℝ))) atTop (𝓝 1) := by
    apply tendsto_const_nhds.congr'
    filter_upwards with k
    simp [lp.tsumCLM_apply, lp.single_apply]
  have := tendsto_nhds_unique h1 h2
  simp [hx₀] at this

/-- `ℓ^1` is not reflexive: the reading map `J : ℓ^1 → (ℓ^1)''` is not onto. -/
theorem ell1_not_reflexive :
    ¬ Function.Surjective (inclusionInDoubleDual ℝ (lp (fun _ : ℕ => ℝ) 1)) := by
  intro hJ
  obtain ⟨n, hn, x₀, h⟩ := (reflexive_iff_bounded_seq_has_weakly_convergent_subseq _).1 hJ
    (fun k => lp.single 1 k (1 : ℝ))
    ⟨1, fun k => by rw [lp.norm_single (by norm_num)]; simp⟩
  exact ell1_bumps_have_no_weakly_convergent_subseq ⟨n, hn, x₀, h⟩

-- The 18:00 bumps on days 1 to 7 sit at hours 18, 42, 66, 90, 114, 138, 162.
example : (List.range 7).map (fun k => 18 + 24 * k) = [18, 42, 66, 90, 114, 138, 162] := by
  decide

-- Six-hour rehearsal: total energy 0.30 + 0.20 + 0 + 0.10 + 0.25 + 0.15 = 1 MWh.
example : (3 / 10 : ℚ) + 2 / 10 + 0 + 1 / 10 + 25 / 100 + 15 / 100 = 1 := by norm_num

-- Revenue at prices 40, 35, 45, 70, 90, 60 is £19.50 = 39/2.
example : (-3 / 10 : ℚ) * 40 + (-2 / 10) * 35 + 0 * 45 + (1 / 10) * 70 + (25 / 100) * 90
    + (15 / 100) * 60 = 39 / 2 := by norm_num

-- The corner list -100, -100, any, 100, 100, 100 earns £100 = 100 × ‖x‖₁.
example : (-3 / 10 : ℚ) * (-100) + (-2 / 10) * (-100) + 0 * 100 + (1 / 10) * 100
    + (25 / 100) * 100 + (15 / 100) * 100 = 100 := by norm_num

-- Worked numbers: flat list gap 50 − 0 = 50; alternating gap 60 − 40 = 20;
-- distance between two bumps in ℓ^1 is 1 + 1 = 2.
example : (50 : ℤ) * 1 - 50 * 0 = 50 ∧ (60 : ℤ) - 40 = 20 ∧ (1 : ℤ) + 1 = 2 := by decide

#print axioms reflexive_iff_bounded_seq_has_weakly_convergent_subseq
#print axioms ell1_bumps_have_no_weakly_convergent_subseq
#print axioms ell1_not_reflexive
