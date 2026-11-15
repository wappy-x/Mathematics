-- Characteristics: near a data curve that crosses the characteristics, a quasilinear first-order equation P u_x + Q u_t = R with smooth coefficients has exactly one classical solution taking the given data, the flow rho v rides unchanged along each car's path, and data given along a characteristic fix nothing off it.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib

open Filter Topology

section MocHelpers

open Set Metric Function
open scoped NNReal


theorem moc_gronwallBound_zero_eq (B δ x : ℝ) :
    gronwallBound 0 B δ x = δ * gronwallBound 0 B 1 x := by
  unfold gronwallBound; split_ifs <;> ring

#print axioms moc_gronwallBound_zero_eq

theorem moc_gronwall_symm {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {e e' : ℝ → V} {T B δ : ℝ} (hB : 0 ≤ B) (hδ : 0 ≤ δ)
    (he : ∀ s ∈ Ioo (-T) T, HasDerivAt e (e' s) s) (h0 : e 0 = 0)
    (hb : ∀ s ∈ Ioo (-T) T, ‖e' s‖ ≤ B * ‖e s‖ + δ) :
    ∀ s ∈ Ioo (-T) T, ‖e s‖ ≤ δ * gronwallBound 0 B 1 T := by
  intro s hs
  have hs1 := hs.1
  have hs2 := hs.2
  have hmono : ∀ x, 0 ≤ x → x ≤ T → δ * gronwallBound 0 B 1 x ≤ δ * gronwallBound 0 B 1 T :=
    fun x _ hx => mul_le_mul_of_nonneg_left (gronwallBound_mono le_rfl zero_le_one hB hx) hδ
  rcases le_total 0 s with h | h
  · have := norm_le_gronwallBound_of_norm_deriv_right_le (f := e) (f' := e') (δ := 0) (K := B)
      (ε := δ) (a := 0) (b := s)
      (fun x hx => (he x ⟨by linarith [hx.1, hs.1], by linarith [hx.2, hs.2]⟩).continuousAt.continuousWithinAt)
      (fun x hx => (he x ⟨by linarith [hx.1, hs.1], by linarith [hx.2, hs.2]⟩).hasDerivWithinAt)
      (by simp [h0])
      (fun x hx => hb x ⟨by linarith [hx.1, hs.1], by linarith [hx.2, hs.2]⟩) s ⟨h, le_rfl⟩
    rw [moc_gronwallBound_zero_eq, sub_zero] at this
    exact this.trans (hmono s h hs.2.le)
  · have := norm_le_gronwallBound_of_norm_deriv_right_le (f := fun σ => e (-σ))
      (f' := fun σ => (-1 : ℝ) • e' (-σ)) (δ := 0) (K := B)
      (ε := δ) (a := 0) (b := -s)
      (fun x hx => ((he (-x) ⟨by linarith [hx.2, hs.1], by linarith [hx.1, hs.2]⟩).scomp x
        (hasDerivAt_neg x)).continuousAt.continuousWithinAt)
      (fun x hx => ((he (-x) ⟨by linarith [hx.2, hs.1], by linarith [hx.1, hs.2]⟩).scomp x
        (hasDerivAt_neg x)).hasDerivWithinAt)
      (by simp [h0])
      (fun x hx => by
        rw [norm_smul]
        simpa using hb (-x) ⟨by linarith [hx.2, hs.1], by linarith [hx.1, hs.2]⟩) (-s)
      ⟨by linarith, le_rfl⟩
    rw [moc_gronwallBound_zero_eq, sub_zero, neg_neg] at this
    exact this.trans (hmono (-s) (by linarith) (by linarith [hs.1]))

#print axioms moc_gronwall_symm

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]

theorem moc_flow_C1 (F : E → E) (hF : ContDiff ℝ 1 F) (y₀ : E) :
    ∃ T > 0, ∃ r > 0, ∃ Φ : ℝ × E → E,
      (∀ y ∈ ball y₀ r, Φ (0, y) = y) ∧
      (∀ s ∈ Ioo (-T) T, ∀ y ∈ ball y₀ r, HasDerivAt (fun σ => Φ (σ, y)) (F (Φ (s, y))) s) ∧
      ContDiffOn ℝ 1 Φ (Ioo (-T) T ×ˢ ball y₀ r) := by
  classical
  obtain ⟨ε, hε, a, r, L, K, hr, hpl⟩ := IsPicardLindelof.of_contDiffAt_one (hF.contDiffAt (x := y₀))
  obtain ⟨α, hα, L', hL'⟩ := (hpl 0).exists_forall_mem_closedBall_eq_hasDerivWithinAt_lipschitzOnWith
  simp only [zero_sub, zero_add] at hα hL'
  set DF := fderiv ℝ F with hDF_def
  have hDFc : Continuous DF := hF.continuous_fderiv one_ne_zero
  have hFd : ∀ z, HasFDerivAt F (DF z) z := fun z =>
    ((hF.differentiable one_ne_zero) z).hasFDerivAt
  obtain ⟨C0, hC0⟩ := (isCompact_closedBall y₀ 1).exists_bound_of_continuousOn hDFc.continuousOn
  set Bd : ℝ≥0 := C0.toNNReal with hBd_def
  have hBd : ∀ z ∈ closedBall y₀ 1, ‖DF z‖ ≤ Bd := fun z hz =>
    (hC0 z hz).trans (Real.le_coe_toNNReal C0)
  have hUC := Metric.uniformContinuousOn_iff.mp
    ((isCompact_closedBall y₀ 1).uniformContinuousOn_of_continuous hDFc.continuousOn)
  -- continuity of α y₀ at 0
  have hα0 : ContinuousAt (α y₀) 0 :=
    ((hα y₀ (mem_closedBall_self r.2)).2 0 ⟨by linarith, by linarith⟩).continuousWithinAt
      |>.continuousAt (Icc_mem_nhds (by linarith) (by linarith))
  obtain ⟨δ₁, hδ₁, hδ₁'⟩ := Metric.continuousAt_iff.mp hα0 (1/2) (by norm_num)
  rw [(hα y₀ (mem_closedBall_self r.2)).1] at hδ₁'
  set r₁ : ℝ := min (r : ℝ) (1 / (2 * ((L' : ℝ) + 1))) with hr₁_def
  have hr₁ : 0 < r₁ := lt_min hr (by positivity)
  set T : ℝ := min (min (ε / 2) (δ₁ / 2)) (1 / (4 * ((Bd : ℝ) + 1))) with hT_def
  have hT : 0 < T := lt_min (lt_min (by linarith) (by linarith)) (by positivity)
  have hTε : T ≤ ε / 2 := (min_le_left _ _).trans (min_le_left _ _)
  have hTδ : T ≤ δ₁ / 2 := (min_le_left _ _).trans (min_le_right _ _)
  have hTB : T ≤ 1 / (4 * ((Bd : ℝ) + 1)) := min_le_right _ _
  have hball_r : ∀ y ∈ ball y₀ r₁, y ∈ closedBall y₀ r := fun y hy =>
    mem_closedBall.2 ((mem_ball.1 hy).le.trans (min_le_left _ _))
  have hIcc : ∀ t ∈ Icc (-T) T, t ∈ Icc (-ε) ε := fun t ht =>
    ⟨by linarith [ht.1], by linarith [ht.2]⟩
  have hin : ∀ y ∈ ball y₀ r₁, ∀ t ∈ Icc (-T) T, α y t ∈ ball y₀ 1 := by
    intro y hy t ht
    have h1 := (hL' t (hIcc t ht)).dist_le_mul y (hball_r y hy) y₀ (mem_closedBall_self r.2)
    have h2 := hδ₁' (x := t) (by rw [Real.dist_eq, sub_zero, abs_lt]; constructor <;> linarith [ht.1, ht.2])
    have h3 : dist y y₀ < r₁ := hy
    have h4 : (L' : ℝ) * r₁ ≤ 1 / 2 := by
      calc (L' : ℝ) * r₁ ≤ L' * (1 / (2 * ((L' : ℝ) + 1))) := by
            gcongr; exact min_le_right _ _
        _ ≤ 1 / 2 := by
            rw [mul_one_div, div_le_div_iff₀ (by positivity) (by norm_num)]; nlinarith
    rw [mem_ball]
    calc dist (α y t) y₀ ≤ dist (α y t) (α y₀ t) + dist (α y₀ t) y₀ := dist_triangle _ _ _
      _ < 1 / 2 + 1 / 2 := by
          apply add_lt_add_of_le_of_lt _ h2
          calc dist (α y t) (α y₀ t) ≤ L' * dist y y₀ := h1
            _ ≤ L' * r₁ := by gcongr
            _ ≤ 1 / 2 := h4
      _ = 1 := by norm_num
  have hαd : ∀ y ∈ ball y₀ r₁, ∀ s ∈ Ioo (-T) T, HasDerivAt (α y) (F (α y s)) s := by
    intro y hy s hs
    exact ((hα y (hball_r y hy)).2 s (hIcc s (Ioo_subset_Icc_self hs))).hasDerivAt
      (Icc_mem_nhds (by linarith [hs.1]) (by linarith [hs.2]))
  have hαc : ∀ y ∈ ball y₀ r₁, ContinuousOn (α y) (Icc (-T) T) := fun y hy t ht =>
    ((hα y (hball_r y hy)).2 t (hIcc t ht)).continuousWithinAt.mono (fun x hx => hIcc x hx)
  have hid : ‖ContinuousLinearMap.id ℝ E‖ ≤ 1 := ContinuousLinearMap.norm_id_le
  have hBdT : (Bd : ℝ) * T ≤ 1 / 4 := by
    calc (Bd : ℝ) * T ≤ Bd * (1 / (4 * ((Bd : ℝ) + 1))) := by gcongr
      _ ≤ 1 / 4 := by
        rw [mul_one_div, div_le_div_iff₀ (by positivity) (by norm_num)]; nlinarith
  have hM : ∀ y, ∃ β : ℝ → (E →L[ℝ] E), y ∈ ball y₀ r₁ →
      β 0 = ContinuousLinearMap.id ℝ E ∧
      ∀ t ∈ Icc (-T) T, HasDerivWithinAt β (DF (α y t) ∘L β t) (Icc (-T) T) t := by
    intro y
    by_cases hy : y ∈ ball y₀ r₁
    swap
    · exact ⟨0, fun h => absurd h hy⟩
    have hpl2 : IsPicardLindelof (fun t (m : E →L[ℝ] E) => DF (α y t) ∘L m)
        (tmin := -T) (tmax := T) ⟨0, ⟨by linarith, by linarith⟩⟩
        (ContinuousLinearMap.id ℝ E) 1 0 (2 * Bd) Bd := by
      refine ⟨?_, ?_, ?_, ?_⟩
      · intro t ht
        apply LipschitzWith.lipschitzOnWith
        apply LipschitzWith.of_dist_le_mul
        intro m m'
        rw [dist_eq_norm, dist_eq_norm, ← ContinuousLinearMap.comp_sub]
        exact (ContinuousLinearMap.opNorm_comp_le _ _).trans
          (mul_le_mul_of_nonneg_right (hBd _ (ball_subset_closedBall (hin y hy t ht)))
            (norm_nonneg _))
      · intro m _
        exact ((hDFc.comp_continuousOn (hαc y hy)).clm_comp continuousOn_const)
      · intro t ht m hm
        have hm1 : ‖m - ContinuousLinearMap.id ℝ E‖ ≤ 1 := by
          simpa [mem_closedBall, dist_eq_norm] using hm
        have hm' : ‖m‖ ≤ 2 := by
          have := norm_le_norm_add_norm_sub' m (ContinuousLinearMap.id ℝ E)
          linarith
        calc ‖DF (α y t) ∘L m‖ ≤ ‖DF (α y t)‖ * ‖m‖ := ContinuousLinearMap.opNorm_comp_le _ _
          _ ≤ Bd * 2 := by
            gcongr
            exact hBd _ (ball_subset_closedBall (hin y hy t ht))
          _ = ((2 * Bd : ℝ≥0) : ℝ) := by push_cast; ring
      · simp only [NNReal.coe_mul, NNReal.coe_ofNat, NNReal.coe_one, NNReal.coe_zero, sub_zero,
          zero_sub, neg_neg, max_self]
        linarith
    obtain ⟨β, hβ0, hβ⟩ := hpl2.exists_eq_forall_mem_Icc_hasDerivWithinAt₀
    exact ⟨β, fun _ => ⟨hβ0, hβ⟩⟩
  choose M hM using hM
  have hMd : ∀ y ∈ ball y₀ r₁, ∀ s ∈ Ioo (-T) T,
      HasDerivAt (M y) (DF (α y s) ∘L M y s) s := by
    intro y hy s hs
    exact ((hM y hy).2 s (Ioo_subset_Icc_self hs)).hasDerivAt (Icc_mem_nhds hs.1 hs.2)
  set G := gronwallBound 0 Bd 1 T with hG_def
  have hG : 0 ≤ G := by
    have := gronwallBound_mono (δ := 0) (ε := 1) (K := Bd) le_rfl zero_le_one Bd.2 hT.le
    simpa [gronwallBound_x0] using this
  have hMb : ∀ y ∈ ball y₀ r₁, ∀ s ∈ Ioo (-T) T, ‖M y s‖ ≤ 1 + Bd * G := by
    intro y hy s hs
    have := moc_gronwall_symm (e := fun s => M y s - ContinuousLinearMap.id ℝ E)
      (e' := fun s => DF (α y s) ∘L M y s) (B := Bd) (δ := Bd) Bd.2 Bd.2
      (fun s hs => (hMd y hy s hs).sub_const _) (by simp [(hM y hy).1])
      (fun s hs => by
        have hA := hBd _ (ball_subset_closedBall (hin y hy s (Ioo_subset_Icc_self hs)))
        have h1 := norm_le_norm_add_norm_sub' (M y s) (ContinuousLinearMap.id ℝ E)
        calc ‖DF (α y s) ∘L M y s‖ ≤ ‖DF (α y s)‖ * ‖M y s‖ :=
              ContinuousLinearMap.opNorm_comp_le _ _
          _ ≤ Bd * (‖M y s - ContinuousLinearMap.id ℝ E‖ + 1) := by
              gcongr; linarith
          _ = Bd * ‖M y s - ContinuousLinearMap.id ℝ E‖ + Bd := by ring) s hs
    have h1 := norm_le_norm_add_norm_sub' (M y s) (ContinuousLinearMap.id ℝ E)
    linarith
  have hLip : ∀ y ∈ ball y₀ r₁, ∀ y' ∈ ball y₀ r₁, ∀ t ∈ Icc (-T) T,
      ‖α y' t - α y t‖ ≤ L' * ‖y' - y‖ := by
    intro y hy y' hy' t ht
    have := (hL' t (hIcc t ht)).dist_le_mul y' (hball_r y' hy') y (hball_r y hy)
    simpa [dist_eq_norm] using this
  have hTay : ∀ η > 0, ∃ δ > 0, ∀ z ∈ ball y₀ 1, ∀ w ∈ ball y₀ 1, ‖z - w‖ < δ →
      ‖F z - F w - DF w (z - w)‖ ≤ η * ‖z - w‖ := by
    intro η hη
    obtain ⟨δ, hδ, hδ'⟩ := hUC η hη
    refine ⟨δ, hδ, fun z hz w hw hzw => ?_⟩
    have hconv : Convex ℝ (ball y₀ 1 ∩ ball w δ) := (convex_ball _ _).inter (convex_ball _ _)
    exact hconv.norm_image_sub_le_of_norm_hasFDerivWithin_le' (f := F) (f' := DF) (φ := DF w)
      (C := η) (fun x _ => (hFd x).hasFDerivWithinAt)
      (fun x hx => by
        have := hδ' x (ball_subset_closedBall hx.1) w (ball_subset_closedBall hw)
          (by simpa using hx.2)
        rw [dist_eq_norm] at this; exact this.le)
      ⟨hw, mem_ball_self hδ⟩ ⟨hz, by rw [mem_ball, dist_eq_norm]; exact hzw⟩
  have hDy : ∀ y ∈ ball y₀ r₁, ∀ s ∈ Ioo (-T) T, HasFDerivAt (fun x => α x s) (M y s) y := by
    intro y hy s hs
    rw [hasFDerivAt_iff_isLittleO_nhds_zero, Asymptotics.isLittleO_iff]
    intro c hc
    set η := c / (((L' : ℝ) + 1) * (G + 1)) with hη_def
    have hη : 0 < η := by positivity
    obtain ⟨δu, hδu, hTay'⟩ := hTay η hη
    have hy' : dist y y₀ < r₁ := hy
    have hρ : 0 < min (r₁ - dist y y₀) (δu / ((L' : ℝ) + 1)) :=
      lt_min (by linarith) (by positivity)
    filter_upwards [ball_mem_nhds (0 : E) hρ] with k hk
    rw [mem_ball, dist_zero_right] at hk
    have hk1 : ‖k‖ < r₁ - dist y y₀ := hk.trans_le (min_le_left _ _)
    have hyk : y + k ∈ ball y₀ r₁ := by
      rw [mem_ball]
      calc dist (y + k) y₀ ≤ dist (y + k) y + dist y y₀ := dist_triangle _ _ _
        _ = ‖k‖ + dist y y₀ := by rw [dist_eq_norm]; simp
        _ < r₁ := by linarith
    have hk2 : (L' : ℝ) * ‖k‖ < δu := by
      have hk' : ‖k‖ < δu / ((L' : ℝ) + 1) := hk.trans_le (min_le_right _ _)
      rw [lt_div_iff₀ (by positivity)] at hk'
      nlinarith [norm_nonneg k]
    have key := moc_gronwall_symm (e := fun σ => α (y + k) σ - α y σ - M y σ k)
      (e' := fun σ => F (α (y + k) σ) - F (α y σ) - (DF (α y σ) ∘L M y σ) k) (B := Bd)
      (δ := η * L' * ‖k‖) Bd.2 (by positivity)
      (fun σ hσ => by
        have := ((hαd (y + k) hyk σ hσ).sub (hαd y hy σ hσ)).sub
          ((hMd y hy σ hσ).clm_apply (hasDerivAt_const σ k))
        convert this using 1
        simp)
      (by simp [(hα _ (hball_r _ hyk)).1, (hα _ (hball_r _ hy)).1, (hM y hy).1])
      (fun σ hσ => by
        have hσ' := Ioo_subset_Icc_self hσ
        have hz := hin _ hyk σ hσ'
        have hw := hin y hy σ hσ'
        have hzw : ‖α (y + k) σ - α y σ‖ ≤ L' * ‖k‖ := by
          simpa using hLip y hy (y + k) hyk σ hσ'
        have h1 := hTay' _ hz _ hw (by linarith)
        have hA := hBd _ (ball_subset_closedBall hw)
        have heq : F (α (y + k) σ) - F (α y σ) - (DF (α y σ) ∘L M y σ) k =
            (F (α (y + k) σ) - F (α y σ) - DF (α y σ) (α (y + k) σ - α y σ)) +
              DF (α y σ) (α (y + k) σ - α y σ - M y σ k) := by
          simp only [ContinuousLinearMap.comp_apply, map_sub]; abel
        rw [heq]
        calc _ ≤ ‖F (α (y + k) σ) - F (α y σ) - DF (α y σ) (α (y + k) σ - α y σ)‖ +
              ‖DF (α y σ) (α (y + k) σ - α y σ - M y σ k)‖ := norm_add_le _ _
          _ ≤ η * ‖α (y + k) σ - α y σ‖ + Bd * ‖α (y + k) σ - α y σ - M y σ k‖ :=
              add_le_add h1 ((DF _).le_opNorm _ |>.trans (by gcongr))
          _ ≤ η * (L' * ‖k‖) + Bd * ‖α (y + k) σ - α y σ - M y σ k‖ := by gcongr
          _ = _ := by ring) s hs
    have hc' : η * ((L' : ℝ) * G) ≤ c := by
      rw [hη_def, div_mul_eq_mul_div, div_le_iff₀ (by positivity)]
      have : (L' : ℝ) * G ≤ ((L' : ℝ) + 1) * (G + 1) := by nlinarith [L'.2]
      nlinarith
    calc ‖α (y + k) s - α y s - M y s k‖ ≤ η * L' * ‖k‖ * G := key
      _ = (η * ((L' : ℝ) * G)) * ‖k‖ := by ring
      _ ≤ c * ‖k‖ := by gcongr
  have hMy : ∀ y ∈ ball y₀ r₁, ∀ c > 0, ∃ δ > 0, ∀ y' ∈ ball y₀ r₁, ‖y' - y‖ < δ →
      ∀ s ∈ Ioo (-T) T, ‖M y' s - M y s‖ ≤ c := by
    intro y hy c hc
    set Mb : ℝ := 1 + Bd * G with hMb_def
    have hMb0 : 0 < Mb := by positivity
    set η := c / (Mb * (G + 1)) with hη_def
    have hη : 0 < η := by positivity
    obtain ⟨δu, hδu, hδu'⟩ := hUC η hη
    refine ⟨δu / ((L' : ℝ) + 1), by positivity, fun y' hy' hyy' s hs => ?_⟩
    have hyy'2 : (L' : ℝ) * ‖y' - y‖ < δu := by
      rw [lt_div_iff₀ (by positivity)] at hyy'
      nlinarith [norm_nonneg (y' - y)]
    have key := moc_gronwall_symm (e := fun σ => M y' σ - M y σ)
      (e' := fun σ => DF (α y' σ) ∘L M y' σ - DF (α y σ) ∘L M y σ) (B := Bd)
      (δ := η * Mb) Bd.2 (by positivity)
      (fun σ hσ => (hMd y' hy' σ hσ).sub (hMd y hy σ hσ))
      (by simp [(hM y hy).1, (hM y' hy').1])
      (fun σ hσ => by
        have hσ' := Ioo_subset_Icc_self hσ
        have hz := hin _ hy' σ hσ'
        have hw := hin y hy σ hσ'
        have hzw : ‖α y' σ - α y σ‖ ≤ L' * ‖y' - y‖ := hLip y hy y' hy' σ hσ'
        have h1 : ‖DF (α y' σ) - DF (α y σ)‖ ≤ η := by
          have := hδu' _ (ball_subset_closedBall hz) _ (ball_subset_closedBall hw)
            (by rw [dist_eq_norm]; linarith)
          rw [dist_eq_norm] at this; exact this.le
        have hA := hBd _ (ball_subset_closedBall hz)
        have hMb' := hMb y hy σ hσ
        have heq : DF (α y' σ) ∘L M y' σ - DF (α y σ) ∘L M y σ =
            DF (α y' σ) ∘L (M y' σ - M y σ) + (DF (α y' σ) - DF (α y σ)) ∘L M y σ := by
          rw [ContinuousLinearMap.comp_sub, ContinuousLinearMap.sub_comp]; abel
        rw [heq]
        calc _ ≤ ‖DF (α y' σ) ∘L (M y' σ - M y σ)‖ + ‖(DF (α y' σ) - DF (α y σ)) ∘L M y σ‖ :=
              norm_add_le _ _
          _ ≤ ‖DF (α y' σ)‖ * ‖M y' σ - M y σ‖ + ‖DF (α y' σ) - DF (α y σ)‖ * ‖M y σ‖ :=
              add_le_add (ContinuousLinearMap.opNorm_comp_le _ _)
                (ContinuousLinearMap.opNorm_comp_le _ _)
          _ ≤ Bd * ‖M y' σ - M y σ‖ + η * Mb := by gcongr
          _ = _ := by ring) s hs
    have hc' : η * Mb * G ≤ c := by
      rw [hη_def, div_mul_eq_mul_div, div_mul_eq_mul_div, div_le_iff₀ (by positivity)]
      have : Mb * G ≤ Mb * (G + 1) := by nlinarith
      nlinarith
    exact key.trans hc'
  have hS : IsOpen (Ioo (-T) T ×ˢ ball y₀ r₁) := isOpen_Ioo.prod isOpen_ball
  have hMc : ∀ p ∈ Ioo (-T) T ×ˢ ball y₀ r₁, ContinuousAt (fun q : ℝ × E => M q.2 q.1) p := by
    rintro ⟨s, y⟩ ⟨hs, hy⟩
    rw [Metric.continuousAt_iff]
    intro c hc
    obtain ⟨δ1, hδ1, h1⟩ := hMy y hy (c / 2) (by positivity)
    obtain ⟨δ2, hδ2, h2⟩ := Metric.continuousAt_iff.mp (hMd y hy s hs).continuousAt (c / 2)
      (by positivity)
    obtain ⟨δ3, hδ3, h3⟩ := Metric.isOpen_iff.mp hS (s, y) ⟨hs, hy⟩
    refine ⟨min δ1 (min δ2 δ3), by positivity, fun {q} hq => ?_⟩
    have hq3 : q ∈ Ioo (-T) T ×ˢ ball y₀ r₁ :=
      h3 (mem_ball.2 (hq.trans_le ((min_le_right _ _).trans (min_le_right _ _))))
    rw [Prod.dist_eq, max_lt_iff] at hq
    obtain ⟨hq1, hq2⟩ := hq
    rw [dist_eq_norm]
    calc ‖M q.2 q.1 - M y s‖ ≤ ‖M q.2 q.1 - M y q.1‖ + ‖M y q.1 - M y s‖ :=
          norm_sub_le_norm_sub_add_norm_sub _ _ _
      _ < c / 2 + c / 2 := by
          apply add_lt_add_of_le_of_lt
          · exact h1 q.2 hq3.2 (by rw [← dist_eq_norm]; exact hq2.trans_le (min_le_left _ _))
              q.1 hq3.1
          · rw [← dist_eq_norm]
            exact h2 (hq1.trans_le ((min_le_right _ _).trans (min_le_left _ _)))
      _ = c := by ring
  have hαjc : ∀ p ∈ Ioo (-T) T ×ˢ ball y₀ r₁, ContinuousAt (fun q : ℝ × E => α q.2 q.1) p := by
    rintro ⟨s, y⟩ ⟨hs, hy⟩
    rw [Metric.continuousAt_iff]
    intro c hc
    obtain ⟨δ2, hδ2, h2⟩ := Metric.continuousAt_iff.mp (hαd y hy s hs).continuousAt (c / 2)
      (by positivity)
    obtain ⟨δ3, hδ3, h3⟩ := Metric.isOpen_iff.mp hS (s, y) ⟨hs, hy⟩
    refine ⟨min (c / 2 / ((L' : ℝ) + 1)) (min δ2 δ3), by positivity, fun {q} hq => ?_⟩
    have hq3 : q ∈ Ioo (-T) T ×ˢ ball y₀ r₁ :=
      h3 (mem_ball.2 (hq.trans_le ((min_le_right _ _).trans (min_le_right _ _))))
    rw [Prod.dist_eq, max_lt_iff] at hq
    obtain ⟨hq1, hq2⟩ := hq
    have hq2' : ‖q.2 - y‖ < c / 2 / ((L' : ℝ) + 1) := by
      rw [← dist_eq_norm]; exact hq2.trans_le (min_le_left _ _)
    rw [lt_div_iff₀ (by positivity)] at hq2'
    rw [dist_eq_norm]
    calc ‖α q.2 q.1 - α y s‖ ≤ ‖α q.2 q.1 - α y q.1‖ + ‖α y q.1 - α y s‖ :=
          norm_sub_le_norm_sub_add_norm_sub _ _ _
      _ < c / 2 + c / 2 := by
          apply add_lt_add_of_le_of_lt
          · calc ‖α q.2 q.1 - α y q.1‖ ≤ L' * ‖q.2 - y‖ :=
                  hLip y hy q.2 hq3.2 q.1 (Ioo_subset_Icc_self hq3.1)
              _ ≤ c / 2 := by nlinarith [norm_nonneg (q.2 - y)]
          · rw [← dist_eq_norm]
            exact h2 (hq1.trans_le ((min_le_right _ _).trans (min_le_left _ _)))
      _ = c := by ring
  have hf1c : ∀ p ∈ Ioo (-T) T ×ˢ ball y₀ r₁, ContinuousAt
      (fun q : ℝ × E => ContinuousLinearMap.toSpanSingleton ℝ (F (α q.2 q.1))) p := by
    intro p hp
    have := (ContinuousLinearMap.toSpanSingletonCLE (𝕜 := ℝ) (E := E)).continuous.continuousAt.comp
      ((hF.continuous.continuousAt).comp (hαjc p hp))
    exact this
  have hstrict : ∀ p ∈ Ioo (-T) T ×ˢ ball y₀ r₁, HasStrictFDerivAt (fun q : ℝ × E => α q.2 q.1)
      ((ContinuousLinearMap.toSpanSingleton ℝ (F (α p.2 p.1))).coprod (M p.2 p.1)) p := by
    intro p hp
    have hev := hS.mem_nhds hp
    exact hasStrictFDerivAt_uncurry_coprod (f := fun s y => α y s)
      (f₁ := fun s y => ContinuousLinearMap.toSpanSingleton ℝ (F (α y s)))
      (f₂ := fun s y => M y s)
      (by filter_upwards [hev] with v hv using hαd v.2 hv.2 v.1 hv.1)
      (by filter_upwards [hev] with v hv using hDy v.2 hv.2 v.1 hv.1)
      (hf1c p hp) (hMc p hp)
  refine ⟨T, hT, r₁, hr₁, fun p => α p.2 p.1, fun y hy => (hα y (hball_r y hy)).1,
    fun s hs y hy => hαd y hy s hs, ?_⟩
  intro p hp
  apply ContDiffAt.contDiffWithinAt
  rw [contDiffAt_one_iff]
  refine ⟨fun q => (ContinuousLinearMap.toSpanSingleton ℝ (F (α q.2 q.1))).coprod (M q.2 q.1),
    Ioo (-T) T ×ˢ ball y₀ r₁, hS.mem_nhds hp, ?_, fun q hq => (hstrict q hq).hasFDerivAt⟩
  intro q hq
  apply ContinuousAt.continuousWithinAt
  have := (ContinuousLinearMap.coprodEquivL (𝕜 := ℝ) (E := ℝ) (F := E) (G := E) ℝ).continuous.continuousAt.comp
    ((hf1c q hq).prodMk (hMc q hq))
  exact this

#print axioms moc_flow_C1

theorem moc_quasilinear_main
    (P Q R : ℝ × ℝ × ℝ → ℝ) (hP : ContDiff ℝ 1 P) (hQ : ContDiff ℝ 1 Q)
    (hR : ContDiff ℝ 1 R)
    (x₀ t₀ h : ℝ → ℝ) (hx₀ : ContDiff ℝ 1 x₀) (ht₀ : ContDiff ℝ 1 t₀)
    (hh : ContDiff ℝ 1 h) (a₀ : ℝ)
    (hJ : P (x₀ a₀, t₀ a₀, h a₀) * deriv t₀ a₀ - Q (x₀ a₀, t₀ a₀, h a₀) * deriv x₀ a₀ ≠ 0) :
    ∃ U : Set (ℝ × ℝ), IsOpen U ∧ (x₀ a₀, t₀ a₀) ∈ U ∧ ∃ ε > 0, ∃ u : ℝ × ℝ → ℝ,
      ContDiffOn ℝ 1 u U ∧
      (∀ p ∈ U, P (p.1, p.2, u p) * deriv (fun y => u (y, p.2)) p.1
          + Q (p.1, p.2, u p) * deriv (fun s => u (p.1, s)) p.2 = R (p.1, p.2, u p)) ∧
      (∀ a : ℝ, |a - a₀| < ε → (x₀ a, t₀ a) ∈ U ∧ u (x₀ a, t₀ a) = h a) ∧
      (∀ W : Set (ℝ × ℝ), IsOpen W → (x₀ a₀, t₀ a₀) ∈ W →
        ∀ v : ℝ × ℝ → ℝ, ContDiffOn ℝ 1 v W →
        (∀ p ∈ W, P (p.1, p.2, v p) * deriv (fun y => v (y, p.2)) p.1
          + Q (p.1, p.2, v p) * deriv (fun s => v (p.1, s)) p.2 = R (p.1, p.2, v p)) →
        (∀ a : ℝ, |a - a₀| < ε → (x₀ a, t₀ a) ∈ W → v (x₀ a, t₀ a) = h a) →
        ∀ᶠ p in 𝓝 (x₀ a₀, t₀ a₀), v p = u p) := by
  classical
  set F : ℝ × ℝ × ℝ → ℝ × ℝ × ℝ := fun y => (P y, Q y, R y) with hF_def
  have hF : ContDiff ℝ 1 F := hP.prodMk (hQ.prodMk hR)
  set γ : ℝ → ℝ × ℝ × ℝ := fun a => (x₀ a, t₀ a, h a) with hγ_def
  have hγ : ContDiff ℝ 1 γ := hx₀.prodMk (ht₀.prodMk hh)
  set y₀ := γ a₀ with hy₀_def
  obtain ⟨T, hT, r, hr, Φ, hΦ0, hΦd, hΦC⟩ := moc_flow_C1 F hF y₀
  set S := Ioo (-T) T ×ˢ ball y₀ r with hS_def
  have hSo : IsOpen S := isOpen_Ioo.prod isOpen_ball
  set g : ℝ × ℝ → ℝ × (ℝ × ℝ × ℝ) := fun p => (p.2, γ p.1) with hg_def
  have hgC : ContDiff ℝ 1 g := contDiff_snd.prodMk (hγ.comp contDiff_fst)
  set B0 := g ⁻¹' S with hB0_def
  have hB0o : IsOpen B0 := hSo.preimage hgC.continuous
  set πL : ℝ × ℝ × ℝ →L[ℝ] ℝ × ℝ := (ContinuousLinearMap.fst ℝ ℝ (ℝ × ℝ)).prod
      ((ContinuousLinearMap.fst ℝ ℝ ℝ).comp (ContinuousLinearMap.snd ℝ ℝ (ℝ × ℝ))) with hπL_def
  set ζ : ℝ × ℝ × ℝ →L[ℝ] ℝ :=
    (ContinuousLinearMap.snd ℝ ℝ ℝ).comp (ContinuousLinearMap.snd ℝ ℝ (ℝ × ℝ)) with hζ_def
  have hπL : ∀ w : ℝ × ℝ × ℝ, πL w = (w.1, w.2.1) := fun w => rfl
  have hζ : ∀ w : ℝ × ℝ × ℝ, ζ w = w.2.2 := fun w => rfl
  set Ψ : ℝ × ℝ → ℝ × ℝ := fun p => πL (Φ (g p)) with hΨ_def
  set Z : ℝ × ℝ → ℝ := fun p => ζ (Φ (g p)) with hZ_def
  have hΦgC : ContDiffOn ℝ 1 (fun p => Φ (g p)) B0 := hΦC.comp hgC.contDiffOn (fun p hp => hp)
  have hΨC : ContDiffOn ℝ 1 Ψ B0 := πL.contDiff.comp_contDiffOn hΦgC
  have hZC : ContDiffOn ℝ 1 Z B0 := ζ.contDiff.comp_contDiffOn hΦgC
  have h0T : (0 : ℝ) ∈ Ioo (-T) T := ⟨by linarith, hT⟩
  have hp0 : (a₀, (0 : ℝ)) ∈ B0 := ⟨h0T, mem_ball_self hr⟩
  have hΦγ : ∀ a, γ a ∈ ball y₀ r → Φ (0, γ a) = γ a := fun a ha => hΦ0 _ ha
  -- derivative of Φ at the data point
  have hΦdiff : HasFDerivAt Φ (fderiv ℝ Φ (0, y₀)) (0, y₀) :=
    (((hΦC.differentiableOn one_ne_zero) _ ⟨h0T, mem_ball_self hr⟩).differentiableAt
      (hSo.mem_nhds ⟨h0T, mem_ball_self hr⟩)).hasFDerivAt
  set D := fderiv ℝ Φ (0, y₀) with hD_def
  have hD1 : D (1, 0) = F y₀ := by
    have h1 := hΦdiff.comp_hasDerivAt (0 : ℝ)
      ((hasDerivAt_id (0 : ℝ)).prodMk (hasDerivAt_const (0 : ℝ) y₀))
    have h2 := hΦd 0 h0T y₀ (mem_ball_self hr)
    rw [hΦ0 y₀ (mem_ball_self hr)] at h2
    exact h1.unique h2
  have hD2 : ∀ v, D (0, v) = v := by
    have h1 := hΦdiff.comp y₀ ((hasFDerivAt_const (0 : ℝ) y₀).prodMk (hasFDerivAt_id y₀))
    have h2 : HasFDerivAt (fun y => Φ (0, y)) (ContinuousLinearMap.id ℝ _) y₀ := by
      apply (hasFDerivAt_id y₀).congr_of_eventuallyEq
      filter_upwards [ball_mem_nhds y₀ hr] with y hy using hΦ0 y hy
    have h3 := h1.unique h2
    intro v
    have := congrArg (fun L : (ℝ × ℝ × ℝ) →L[ℝ] (ℝ × ℝ × ℝ) => L v) h3
    simpa using this
  set x₁ := deriv x₀ a₀ with hx₁_def
  set t₁ := deriv t₀ a₀ with ht₁_def
  set h₁ := deriv h a₀ with hh₁_def
  set P₀ := P y₀ with hP₀_def
  set Q₀ := Q y₀ with hQ₀_def
  have hγd : HasDerivAt γ (x₁, t₁, h₁) a₀ :=
    ((hx₀.differentiable one_ne_zero) a₀).hasDerivAt.prodMk
      (((ht₀.differentiable one_ne_zero) a₀).hasDerivAt.prodMk
        ((hh.differentiable one_ne_zero) a₀).hasDerivAt)
  have hgd : HasFDerivAt g ((ContinuousLinearMap.snd ℝ ℝ ℝ).prod
      ((ContinuousLinearMap.toSpanSingleton ℝ (x₁, t₁, h₁)).comp
        (ContinuousLinearMap.fst ℝ ℝ ℝ))) (a₀, 0) :=
    have hg1 : HasFDerivAt (fun p : ℝ × ℝ => γ p.1)
        ((ContinuousLinearMap.toSpanSingleton ℝ (x₁, t₁, h₁)).comp
          (ContinuousLinearMap.fst ℝ ℝ ℝ)) (a₀, 0) :=
      HasFDerivAt.comp (g := γ) (f := Prod.fst) (a₀, (0 : ℝ)) hγd.hasFDerivAt hasFDerivAt_fst
    hasFDerivAt_snd.prodMk hg1
  have hΨd0 := πL.hasFDerivAt.comp (a₀, (0 : ℝ)) (hΦdiff.comp (a₀, (0 : ℝ)) hgd)
  set L₁ : ℝ × ℝ →L[ℝ] ℝ × ℝ :=
    (x₁ • ContinuousLinearMap.fst ℝ ℝ ℝ + P₀ • ContinuousLinearMap.snd ℝ ℝ ℝ).prod
      (t₁ • ContinuousLinearMap.fst ℝ ℝ ℝ + Q₀ • ContinuousLinearMap.snd ℝ ℝ ℝ) with hL₁_def
  have hL₁ : πL.comp (D.comp ((ContinuousLinearMap.snd ℝ ℝ ℝ).prod
      ((ContinuousLinearMap.toSpanSingleton ℝ (x₁, t₁, h₁)).comp
        (ContinuousLinearMap.fst ℝ ℝ ℝ)))) = L₁ := by
    refine ContinuousLinearMap.ext fun p => ?_
    obtain ⟨α, σ⟩ := p
    have e1 : ((σ, α • (x₁, t₁, h₁)) : ℝ × ℝ × ℝ × ℝ) =
        σ • ((1 : ℝ), (0 : ℝ × ℝ × ℝ)) + ((0 : ℝ), α • (x₁, t₁, h₁)) := by
      ext <;> simp
    simp only [ContinuousLinearMap.comp_apply, ContinuousLinearMap.prod_apply,
      ContinuousLinearMap.coe_snd', ContinuousLinearMap.coe_fst',
      ContinuousLinearMap.toSpanSingleton_apply]
    rw [e1, map_add, map_smul, hD1, hD2]
    ext <;> simp [hπL, hL₁_def, F] <;> ring
  set Dt := x₁ * Q₀ - P₀ * t₁ with hDt_def
  have hDt : Dt ≠ 0 := by
    intro h0; apply hJ; linarith
  set L₂ : ℝ × ℝ →L[ℝ] ℝ × ℝ :=
    ((Q₀ / Dt) • ContinuousLinearMap.fst ℝ ℝ ℝ - (P₀ / Dt) • ContinuousLinearMap.snd ℝ ℝ ℝ).prod
      ((-t₁ / Dt) • ContinuousLinearMap.fst ℝ ℝ ℝ + (x₁ / Dt) • ContinuousLinearMap.snd ℝ ℝ ℝ)
    with hL₂_def
  have hinv1 : Function.LeftInverse L₂ L₁ := by
    rintro ⟨α, σ⟩
    ext <;> simp [hL₁_def, hL₂_def] <;> field_simp <;> ring
  have hinv2 : Function.RightInverse L₂ L₁ := by
    rintro ⟨α, σ⟩
    ext <;> simp [hL₁_def, hL₂_def] <;> field_simp <;> ring
  set Le : (ℝ × ℝ) ≃L[ℝ] (ℝ × ℝ) := ContinuousLinearEquiv.equivOfInverse L₁ L₂ hinv1 hinv2
    with hLe_def
  have hΨd : HasFDerivAt Ψ (Le : ℝ × ℝ →L[ℝ] ℝ × ℝ) (a₀, 0) := by
    have : (Le : ℝ × ℝ →L[ℝ] ℝ × ℝ) = L₁ := rfl
    rw [this, ← hL₁]
    exact hΨd0
  have hΨc : ContDiffAt ℝ 1 Ψ (a₀, 0) := hΨC.contDiffAt (hB0o.mem_nhds hp0)
  set e := hΨc.toOpenPartialHomeomorph Ψ hΨd one_ne_zero with he_def
  have he_coe : ∀ p, e p = Ψ p := fun p => rfl
  have hp0src : (a₀, (0 : ℝ)) ∈ e.source := hΨc.mem_toOpenPartialHomeomorph_source hΨd one_ne_zero
  have hΨγ : ∀ a, γ a ∈ ball y₀ r → Ψ (a, 0) = (x₀ a, t₀ a) := by
    intro a ha
    show πL (Φ (0, γ a)) = _
    rw [hΦ0 _ ha, hπL]
  have hZγ : ∀ a, γ a ∈ ball y₀ r → Z (a, 0) = h a := by
    intro a ha
    show ζ (Φ (0, γ a)) = _
    rw [hΦ0 _ ha, hζ]
  have hq₀ : Ψ (a₀, 0) = (x₀ a₀, t₀ a₀) := hΨγ a₀ (mem_ball_self hr)
  have hsymmC : ContDiffAt ℝ 1 e.symm (Ψ (a₀, 0)) := hΨc.to_localInverse hΨd one_ne_zero
  obtain ⟨tset, htset, htso, hq₀t⟩ := _root_.eventually_nhds_iff.mp (hsymmC.eventually (by simp))
  set U := tset ∩ (e.target ∩ e.symm ⁻¹' B0) with hU_def
  have hUo : IsOpen U := htso.inter (e.isOpen_inter_preimage_symm hB0o)
  set u : ℝ × ℝ → ℝ := fun q => Z (e.symm q) with hu_def
  have hq₀U : (x₀ a₀, t₀ a₀) ∈ U := by
    rw [← hq₀]
    refine ⟨hq₀t, e.map_source hp0src, ?_⟩
    show e.symm (e (a₀, 0)) ∈ B0
    rw [e.left_inv hp0src]; exact hp0
  have huC : ContDiffOn ℝ 1 u U := by
    intro q hq
    have h1 : ContDiffAt ℝ 1 e.symm q := htset q hq.1
    have h2 : ContDiffAt ℝ 1 Z (e.symm q) := hZC.contDiffAt (hB0o.mem_nhds hq.2.2)
    exact (h2.comp q h1).contDiffWithinAt
  have hev : ∀ᶠ a in 𝓝 a₀, (a, (0 : ℝ)) ∈ e.source ∩ B0 ∧ (x₀ a, t₀ a) ∈ tset := by
    have c1 : Tendsto (fun a : ℝ => (a, (0 : ℝ))) (𝓝 a₀) (𝓝 (a₀, 0)) :=
      (continuous_id.prodMk continuous_const).tendsto a₀
    have c2 : Tendsto (fun a => (x₀ a, t₀ a)) (𝓝 a₀) (𝓝 (x₀ a₀, t₀ a₀)) :=
      (hx₀.continuous.prodMk ht₀.continuous).tendsto a₀
    exact (c1.eventually ((e.open_source.inter hB0o).mem_nhds ⟨hp0src, hp0⟩)).and
      (c2.eventually (htso.mem_nhds (hq₀ ▸ hq₀t)))
  obtain ⟨ε, hε, hεa⟩ := Metric.eventually_nhds_iff.mp hev
  have hlin : ∀ (L : ℝ × ℝ →L[ℝ] ℝ) (c d : ℝ), L (c, d) = c * L (1, 0) + d * L (0, 1) := by
    intro L c d
    have : ((c, d) : ℝ × ℝ) = c • ((1 : ℝ), (0 : ℝ)) + d • ((0 : ℝ), (1 : ℝ)) := by
      ext <;> simp
    rw [this, map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul]
  have hslices : ∀ (w : ℝ × ℝ → ℝ) (q : ℝ × ℝ) (L : ℝ × ℝ →L[ℝ] ℝ), HasFDerivAt w L q →
      deriv (fun y => w (y, q.2)) q.1 = L (1, 0) ∧ deriv (fun s => w (q.1, s)) q.2 = L (0, 1) := by
    intro w q L hw
    constructor
    · exact (hw.comp_hasDerivAt q.1 ((hasDerivAt_id q.1).prodMk (hasDerivAt_const q.1 q.2))).deriv
    · exact (hw.comp_hasDerivAt q.2 ((hasDerivAt_const q.2 q.1).prodMk (hasDerivAt_id q.2))).deriv
  refine ⟨U, hUo, hq₀U, ε, hε, u, huC, ?_, ?_, ?_⟩
  · -- the equation
    intro q hq
    set p := e.symm q with hp_def
    have hpB : p ∈ B0 := hq.2.2
    have hpsrc : p ∈ e.source := e.map_target hq.2.1
    have hep : Ψ p = q := e.right_inv hq.2.1
    have hu_diff : HasFDerivAt u (fderiv ℝ u q) q :=
      (((huC q hq).contDiffAt (hUo.mem_nhds hq)).differentiableAt one_ne_zero).hasFDerivAt
    have hcurve : HasDerivAt (fun σ => Ψ (p.1, σ)) (πL (F (Φ (g p)))) p.2 :=
      πL.hasFDerivAt.comp_hasDerivAt p.2 (hΦd p.2 hpB.1 (γ p.1) hpB.2)
    have hZcurve : HasDerivAt (fun σ => Z (p.1, σ)) (ζ (F (Φ (g p)))) p.2 :=
      ζ.hasFDerivAt.comp_hasDerivAt p.2 (hΦd p.2 hpB.1 (γ p.1) hpB.2)
    have hmem : ∀ᶠ σ in 𝓝 p.2, (p.1, σ) ∈ e.source ∩ B0 :=
      (continuous_const.prodMk continuous_id).continuousAt.preimage_mem_nhds
        ((e.open_source.inter hB0o).mem_nhds ⟨hpsrc, hpB⟩)
    have hevq : (fun σ => u (Ψ (p.1, σ))) =ᶠ[𝓝 p.2] (fun σ => Z (p.1, σ)) := by
      filter_upwards [hmem] with σ hσ
      show Z (e.symm (Ψ (p.1, σ))) = Z (p.1, σ)
      rw [show e.symm (Ψ (p.1, σ)) = (p.1, σ) from e.left_inv hσ.1]
    have hu_diff' : HasFDerivAt u (fderiv ℝ u q) (Ψ (p.1, p.2)) := by
      rw [Prod.mk.eta, hep]; exact hu_diff
    have hcomp := hu_diff'.comp_hasDerivAt p.2 hcurve
    have key : fderiv ℝ u q (πL (F (Φ (g p)))) = ζ (F (Φ (g p))) :=
      hcomp.unique (hZcurve.congr_of_eventuallyEq hevq)
    have hw : Φ (g p) = (q.1, q.2, u q) := by
      have h1 : q.1 = (Φ (g p)).1 := by rw [← hep]; rfl
      have h2 : q.2 = (Φ (g p)).2.1 := by rw [← hep]; rfl
      have h3 : u q = (Φ (g p)).2.2 := rfl
      rw [h1, h2, h3]
    obtain ⟨hs1, hs2⟩ := hslices u q _ hu_diff
    rw [hs1, hs2, ← hw]
    rw [hπL, hζ, hlin] at key
    exact key
  · intro a ha
    obtain ⟨⟨hsrc, hB⟩, _⟩ := hεa (by rw [Real.dist_eq]; exact ha)
    have hγa : γ a ∈ ball y₀ r := hB.2
    have hx : e (a, 0) = (x₀ a, t₀ a) := hΨγ a hγa
    refine ⟨?_, ?_⟩
    · rw [← hx]
      refine ⟨?_, e.map_source hsrc, ?_⟩
      · rw [hx]; exact (hεa (by rw [Real.dist_eq]; exact ha)).2
      · show e.symm (e (a, 0)) ∈ B0
        rw [e.left_inv hsrc]; exact hB
    · show Z (e.symm (x₀ a, t₀ a)) = h a
      rw [← hx, e.left_inv hsrc, hZγ a hγa]
  · intro W hWo hq₀W v hvC hvPDE hvdata
    have hv0 : v (x₀ a₀, t₀ a₀) = h a₀ := hvdata a₀ (by simp [hε]) hq₀W
    obtain ⟨LF, hLF⟩ := (hF.contDiffOn (s := closedBall y₀ 1)).exists_lipschitzOnWith one_ne_zero
      (convex_closedBall _ _) (isCompact_closedBall _ _)
    have hvdiff : ∀ q ∈ W, HasFDerivAt v (fderiv ℝ v q) q := fun q hq =>
      (((hvC.differentiableOn one_ne_zero) q hq).differentiableAt (hWo.mem_nhds hq)).hasFDerivAt
    have hDvc : ContinuousAt (fderiv ℝ v) (x₀ a₀, t₀ a₀) :=
      (hvC.continuousOn_fderiv_of_isOpen hWo le_rfl).continuousAt (hWo.mem_nhds hq₀W)
    have hvc : ContinuousAt v (x₀ a₀, t₀ a₀) :=
      hvC.continuousOn.continuousAt (hWo.mem_nhds hq₀W)
    set Dvb := ‖fderiv ℝ v (x₀ a₀, t₀ a₀)‖ + 1 with hDvb_def
    have hGood : ∀ᶠ q in 𝓝 (x₀ a₀, t₀ a₀), q ∈ W ∧ ‖fderiv ℝ v q‖ ≤ Dvb ∧
        (q.1, q.2, v q) ∈ closedBall y₀ 1 := by
      have hc : ContinuousAt (fun q : ℝ × ℝ => (q.1, q.2, v q)) (x₀ a₀, t₀ a₀) :=
        continuousAt_fst.prodMk (continuousAt_snd.prodMk hvc)
      have hev3 : ∀ᶠ q in 𝓝 (x₀ a₀, t₀ a₀), (q.1, q.2, v q) ∈ closedBall y₀ 1 := by
        have : (fun q : ℝ × ℝ => (q.1, q.2, v q)) ⁻¹' closedBall y₀ 1 ∈ 𝓝 (x₀ a₀, t₀ a₀) :=
          hc.preimage_mem_nhds (by
            show closedBall y₀ 1 ∈ 𝓝 (x₀ a₀, t₀ a₀, v (x₀ a₀, t₀ a₀))
            rw [hv0]; exact closedBall_mem_nhds y₀ one_pos)
        exact this
      have hev2 : ∀ᶠ q in 𝓝 (x₀ a₀, t₀ a₀), ‖fderiv ℝ v q‖ ≤ Dvb :=
        (hDvc.norm.eventually (Iio_mem_nhds (lt_add_one _))).mono fun q hq => le_of_lt hq
      exact (hWo.eventually_mem hq₀W).and (hev2.and hev3)
    have hΨt : Tendsto Ψ (𝓝 (a₀, 0)) (𝓝 (x₀ a₀, t₀ a₀)) := by
      rw [← hq₀]; exact hΨc.continuousAt.tendsto
    have hΦgc : ContinuousAt (fun p => Φ (g p)) (a₀, 0) :=
      hΦgC.continuousOn.continuousAt (hB0o.mem_nhds hp0)
    have hΦg0 : Φ (g (a₀, 0)) = y₀ := hΦ0 y₀ (mem_ball_self hr)
    have hBox : ∀ᶠ p in 𝓝 ((a₀, 0) : ℝ × ℝ), p ∈ B0 ∧ dist p.1 a₀ < ε ∧
        Φ (g p) ∈ closedBall y₀ 1 ∧ (Ψ p ∈ W ∧ ‖fderiv ℝ v (Ψ p)‖ ≤ Dvb ∧
        ((Ψ p).1, (Ψ p).2, v (Ψ p)) ∈ closedBall y₀ 1) := by
      have hev2 : ∀ᶠ p in 𝓝 ((a₀, 0) : ℝ × ℝ), dist p.1 a₀ < ε :=
        (continuous_fst.tendsto ((a₀, 0) : ℝ × ℝ)).eventually (ball_mem_nhds a₀ hε)
      have hev3 : ∀ᶠ p in 𝓝 ((a₀, 0) : ℝ × ℝ), Φ (g p) ∈ closedBall y₀ 1 := by
        have : (fun p => Φ (g p)) ⁻¹' closedBall y₀ 1 ∈ 𝓝 ((a₀, 0) : ℝ × ℝ) :=
          hΦgc.preimage_mem_nhds (by
            show closedBall y₀ 1 ∈ 𝓝 (Φ (g (a₀, 0)))
            rw [hΦg0]; exact closedBall_mem_nhds y₀ one_pos)
        exact this
      exact (hB0o.eventually_mem hp0).and (hev2.and (hev3.and (hΨt.eventually hGood)))
    obtain ⟨δ, hδ, hδb⟩ := Metric.eventually_nhds_iff_ball.mp hBox
    have hπn : ∀ x : ℝ × ℝ × ℝ, ‖πL x‖ ≤ ‖x‖ := fun x => by
      rw [hπL]
      exact norm_prod_le_iff.2 ⟨norm_fst_le x, (norm_fst_le x.2).trans (norm_snd_le x)⟩
    have hζn : ∀ x : ℝ × ℝ × ℝ, ‖ζ x‖ ≤ ‖x‖ := fun x => by
      rw [hζ]; exact (norm_snd_le x.2).trans (norm_snd_le x)
    have hclaim : ∀ p ∈ ball ((a₀, 0) : ℝ × ℝ) δ, v (Ψ p) = Z p := by
      intro p hp
      have hp' := hp
      rw [mem_ball, Prod.dist_eq, max_lt_iff] at hp'
      have hbox : ∀ σ ∈ Ioo (-δ) δ, (p.1, σ) ∈ ball ((a₀, 0) : ℝ × ℝ) δ := by
        intro σ hσ
        rw [mem_ball, Prod.dist_eq, max_lt_iff, Real.dist_eq σ 0, sub_zero, abs_lt]
        exact ⟨hp'.1, hσ.1, hσ.2⟩
      have hp2 : p.2 ∈ Ioo (-δ) δ := by
        have := hp'.2
        rw [Real.dist_eq, sub_zero, abs_lt] at this
        exact this
      have hderiv : ∀ σ ∈ Ioo (-δ) δ, HasDerivAt (fun σ => v (Ψ (p.1, σ)) - Z (p.1, σ))
          (fderiv ℝ v (Ψ (p.1, σ)) (πL (F (Φ (g (p.1, σ))))) - ζ (F (Φ (g (p.1, σ))))) σ := by
        intro σ hσ
        obtain ⟨hB, -, -, hW, -, -⟩ := hδb _ (hbox σ hσ)
        have hcurve : HasDerivAt (fun σ => Ψ (p.1, σ)) (πL (F (Φ (g (p.1, σ))))) σ :=
          πL.hasFDerivAt.comp_hasDerivAt σ (hΦd σ hB.1 (γ p.1) hB.2)
        have hZcurve : HasDerivAt (fun σ => Z (p.1, σ)) (ζ (F (Φ (g (p.1, σ))))) σ :=
          ζ.hasFDerivAt.comp_hasDerivAt σ (hΦd σ hB.1 (γ p.1) hB.2)
        exact ((hvdiff _ hW).comp_hasDerivAt σ hcurve).sub hZcurve
      have key := moc_gronwall_symm (e := fun σ => v (Ψ (p.1, σ)) - Z (p.1, σ))
        (e' := fun σ => fderiv ℝ v (Ψ (p.1, σ)) (πL (F (Φ (g (p.1, σ))))) -
          ζ (F (Φ (g (p.1, σ))))) (T := δ) (B := (Dvb + 1) * LF) (δ := 0)
        (by positivity) le_rfl hderiv
        (by
          obtain ⟨hB, hdist, -, hW, -, -⟩ := hδb _ (hbox 0 ⟨by linarith, hδ⟩)
          have hγa : γ p.1 ∈ ball y₀ r := hB.2
          show v (Ψ (p.1, 0)) - Z (p.1, 0) = 0
          rw [hZγ _ hγa]
          rw [hΨγ _ hγa] at hW ⊢
          rw [hvdata p.1 (by rw [← Real.dist_eq]; exact hdist) hW, sub_self])
        (by
          intro σ hσ
          obtain ⟨hB, -, hwb, hW, hDv, hw'b⟩ := hδb _ (hbox σ hσ)
          set w := Φ (g (p.1, σ)) with hw_def
          set q := Ψ (p.1, σ) with hq_def
          set w' : ℝ × ℝ × ℝ := (q.1, q.2, v q) with hw'_def
          have hqw : q = (w.1, w.2.1) := rfl
          have hPDE := hvPDE q hW
          obtain ⟨hs1, hs2⟩ := hslices v q _ (hvdiff q hW)
          rw [hs1, hs2] at hPDE
          have hPDE' : fderiv ℝ v q (πL (F w')) = ζ (F w') := by
            rw [hπL, hζ, hlin]; exact hPDE
          have hsplit : fderiv ℝ v q (πL (F w)) - ζ (F w) =
              fderiv ℝ v q (πL (F w - F w')) - ζ (F w - F w') := by
            rw [map_sub, map_sub, map_sub, hPDE']; ring
          have hww' : ‖w - w'‖ ≤ ‖v q - Z (p.1, σ)‖ := by
            have h1 : w - w' = (0, 0, w.2.2 - v q) := by
              rw [hw'_def, hqw]; ext <;> simp
            rw [h1, norm_sub_rev]
            refine norm_prod_le_iff.2 ⟨by simp, norm_prod_le_iff.2 ⟨by simp, le_rfl⟩⟩
          have hLip := hLF.norm_sub_le hwb hw'b
          show ‖fderiv ℝ v q (πL (F w)) - ζ (F w)‖ ≤
            (Dvb + 1) * LF * ‖v q - Z (p.1, σ)‖ + 0
          rw [hsplit]
          calc ‖fderiv ℝ v q (πL (F w - F w')) - ζ (F w - F w')‖
              ≤ ‖fderiv ℝ v q (πL (F w - F w'))‖ + ‖ζ (F w - F w')‖ := norm_sub_le _ _
            _ ≤ Dvb * ‖F w - F w'‖ + ‖F w - F w'‖ := by
                gcongr
                · exact ((fderiv ℝ v q).le_opNorm _).trans
                    (mul_le_mul hDv (hπn _) (norm_nonneg _) (by positivity))
                · exact hζn _
            _ = (Dvb + 1) * ‖F w - F w'‖ := by ring
            _ ≤ (Dvb + 1) * (LF * ‖w - w'‖) := by gcongr
            _ ≤ (Dvb + 1) * (LF * ‖v q - Z (p.1, σ)‖) := by gcongr
            _ = _ := by ring)
        p.2 hp2
      simp only [zero_mul, norm_le_zero_iff, sub_eq_zero] at key
      exact key
    rw [← hq₀]
    have hq₀tgt : Ψ (a₀, 0) ∈ e.target := e.map_source hp0src
    have hsymm0 : e.symm (Ψ (a₀, 0)) = (a₀, 0) := e.left_inv hp0src
    have hsymm_t : Tendsto e.symm (𝓝 (Ψ (a₀, 0))) (𝓝 (a₀, 0)) := by
      have := (e.continuousAt_symm hq₀tgt).tendsto
      rwa [hsymm0] at this
    filter_upwards [hsymm_t.eventually (ball_mem_nhds _ hδ), e.open_target.mem_nhds hq₀tgt]
      with q hq1 hq2
    have := hclaim _ hq1
    rw [show Ψ (e.symm q) = q from e.right_inv hq2] at this
    exact this

#print axioms moc_quasilinear_main

end MocHelpers

/-- The method of characteristics, local existence and uniqueness. Take a quasilinear
first-order equation `P(x, t, u) u_x + Q(x, t, u) u_t = R(x, t, u)` whose coefficients
`P`, `Q`, `R` have continuous first derivatives, and a data curve `a ↦ (x₀ a, t₀ a)`
carrying values `h a`, all with continuous first derivatives. If the data curve crosses
the characteristics at the label `a₀`, that is `J(a₀) = P t₀'(a₀) - Q x₀'(a₀) ≠ 0`, then
near the data point there is a classical solution `u` (continuous first derivatives)
that solves the equation and equals `h a` on the data curve for labels `a` near `a₀`;
and any other classical solution `v` on an open set around the data point with the same
data equals `u` at every point close enough to the data point. Here `u (x, t)` is the
value at place `x` and time `t`, and the partial derivatives are the derivatives of the
slices `y ↦ u (y, t)` and `s ↦ u (x, s)`. -/
theorem quasilinear_equation_solved_uniquely_by_characteristics
    (P Q R : ℝ × ℝ × ℝ → ℝ) (hP : ContDiff ℝ 1 P) (hQ : ContDiff ℝ 1 Q)
    (hR : ContDiff ℝ 1 R)
    (x₀ t₀ h : ℝ → ℝ) (hx₀ : ContDiff ℝ 1 x₀) (ht₀ : ContDiff ℝ 1 t₀)
    (hh : ContDiff ℝ 1 h) (a₀ : ℝ)
    (hJ : P (x₀ a₀, t₀ a₀, h a₀) * deriv t₀ a₀ - Q (x₀ a₀, t₀ a₀, h a₀) * deriv x₀ a₀ ≠ 0) :
    ∃ U : Set (ℝ × ℝ), IsOpen U ∧ (x₀ a₀, t₀ a₀) ∈ U ∧ ∃ ε > 0, ∃ u : ℝ × ℝ → ℝ,
      ContDiffOn ℝ 1 u U ∧
      (∀ p ∈ U, P (p.1, p.2, u p) * deriv (fun y => u (y, p.2)) p.1
          + Q (p.1, p.2, u p) * deriv (fun s => u (p.1, s)) p.2 = R (p.1, p.2, u p)) ∧
      (∀ a : ℝ, |a - a₀| < ε → (x₀ a, t₀ a) ∈ U ∧ u (x₀ a, t₀ a) = h a) ∧
      (∀ W : Set (ℝ × ℝ), IsOpen W → (x₀ a₀, t₀ a₀) ∈ W →
        ∀ v : ℝ × ℝ → ℝ, ContDiffOn ℝ 1 v W →
        (∀ p ∈ W, P (p.1, p.2, v p) * deriv (fun y => v (y, p.2)) p.1
          + Q (p.1, p.2, v p) * deriv (fun s => v (p.1, s)) p.2 = R (p.1, p.2, v p)) →
        (∀ a : ℝ, |a - a₀| < ε → (x₀ a, t₀ a) ∈ W → v (x₀ a, t₀ a) = h a) →
        ∀ᶠ p in 𝓝 (x₀ a₀, t₀ a₀), v p = u p) := by
  exact moc_quasilinear_main P Q R hP hQ hR x₀ t₀ h hx₀ ht₀ hh a₀ hJ

/-- The work zone: for traffic obeying `ρ_t + (v(x) ρ)_x = 0` with a road speed `v` that has
a continuous slope, the characteristic system is `dx/dt = v(x)`, `dρ/dt = -v'(x) ρ`. Along
any solution of that system the flow `ρ v(x)`, cars per hour, stays the same: the density
itself changes, the flow does not. -/
theorem flow_constant_along_car_path (v : ℝ → ℝ) (hv : ContDiff ℝ 1 v) (x ρ : ℝ → ℝ)
    (hx : ∀ s : ℝ, HasDerivAt x (v (x s)) s)
    (hρ : ∀ s : ℝ, HasDerivAt ρ (-(deriv v (x s)) * ρ s) s) :
    ∀ s : ℝ, ρ s * v (x s) = ρ 0 * v (x 0) := by
  have hd : ∀ s, HasDerivAt (fun s => ρ s * v (x s)) 0 s := by
    intro s
    have hv' : HasDerivAt v (deriv v (x s)) (x s) :=
      ((hv.differentiable one_ne_zero) (x s)).hasDerivAt
    have := (hρ s).mul (hv'.comp s (hx s))
    convert this using 1
    · rfl
    · simp only [Function.comp_apply]; ring
  intro s
  have := is_const_of_deriv_eq_zero (f := fun s => ρ s * v (x s))
    (fun s => (hd s).differentiableAt) (fun s => (hd s).deriv) s 0
  simpa using this

/-- Data along a characteristic fix nothing off it. For `ρ_t + 50 ρ_x = 0` a probe car riding
along `x = 50 t` gives a data curve with `J = 0`. Both `40 e^(-(x - 50 t)^2)` and the constant
`40` solve the equation and both read 40 cars per km along the probe's path, yet at 1 km at
the start one is `40 e^(-1)` and the other is 40. -/
theorem probe_car_data_fix_nothing :
    (∀ x t : ℝ, deriv (fun s => 40 * Real.exp (-(x - 50 * s) ^ 2)) t
        + 50 * deriv (fun y => 40 * Real.exp (-(y - 50 * t) ^ 2)) x = 0) ∧
    (∀ x t : ℝ, deriv (fun _ : ℝ => (40 : ℝ)) t + 50 * deriv (fun _ : ℝ => (40 : ℝ)) x = 0) ∧
    (∀ t : ℝ, 40 * Real.exp (-(50 * t - 50 * t) ^ 2) = 40) ∧
    40 * Real.exp (-((1 : ℝ) - 50 * 0) ^ 2) = 40 * Real.exp (-1) ∧
    40 * Real.exp (-1) ≠ (40 : ℝ) := by
  refine ⟨fun x t => ?_, fun x t => by simp, fun t => by simp, by norm_num, ?_⟩
  · have h1 : HasDerivAt (fun s => 40 * Real.exp (-(x - 50 * s) ^ 2))
        (40 * (Real.exp (-(x - 50 * t) ^ 2) * (-(2 * (x - 50 * t) * (0 - 50 * 1))))) t := by
      apply HasDerivAt.const_mul
      apply HasDerivAt.exp
      have := HasDerivAt.pow (n := 2) ((hasDerivAt_const t x).sub ((hasDerivAt_id t).const_mul 50))
      convert this.neg using 1
      · funext s; simp
      · simp
    have h2 : HasDerivAt (fun y => 40 * Real.exp (-(y - 50 * t) ^ 2))
        (40 * (Real.exp (-(x - 50 * t) ^ 2) * (-(2 * (x - 50 * t) * (1 - 0))))) x := by
      apply HasDerivAt.const_mul
      apply HasDerivAt.exp
      have := HasDerivAt.pow (n := 2) ((hasDerivAt_id x).sub (hasDerivAt_const x (50 * t)))
      convert this.neg using 1
      · funext s; simp
      · simp
    rw [h1.deriv, h2.deriv]; ring
  · intro h
    have : Real.exp (-1) = 1 := by linarith
    rw [Real.exp_eq_one_iff] at this
    norm_num at this

-- The crossing test J = P t₀' - Q x₀' with P = 50, Q = 1: start line (x₀' = 1, t₀' = 0) gives -1,
-- the counter at 0 km (x₀' = 0, t₀' = 1) gives 50, the probe car (x₀' = 50, t₀' = 1) gives 0.
example : (50 : ℤ) * 0 - 1 * 1 = -1 ∧ (50 : ℤ) * 1 - 1 * 0 = 50 ∧ (50 : ℤ) * 1 - 1 * 50 = 0 := by
  norm_num
-- 40 cars per km at 50 km/h is a flow of 2000 cars per hour; at 30 km/h it needs 200/3 = 5/3 of 40.
example : (40 : ℚ) * 50 = 2000 ∧ (2000 : ℚ) / 30 = 5 / 3 * 40 := by norm_num
-- The ramp speed 50 - 20 (x - 2) is 50 km/h at 2 km and 30 km/h at 3 km; the slope is -20 km/h per km.
example : (50 : ℤ) - 20 * (2 - 2) = 50 ∧ (50 : ℤ) - 20 * (3 - 2) = 30 := by norm_num
-- Gaps scale with speed: 30/50 = 3/5.
example : (30 : ℚ) / 50 = 3 / 5 := by norm_num
-- Cars starting at -2, -1, 0, 1, 2 km reach the ramp at 2 km after (2 - a)/50 h: 2/25, 3/50, 1/25, 1/50, 0.
example : ([-2, -1, 0, 1, 2] : List ℚ).map (fun a => (2 - a) / 50) = [2 / 25, 3 / 50, 1 / 25, 1 / 50, 0] := by
  norm_num
-- Crowd model: car speed 60 (1 - ρ/150) gives flow 60ρ - (2/5)ρ², whose slope is c(ρ) = 60 - (4/5)ρ.
example (ρ : ℚ) : ρ * (60 * (1 - ρ / 150)) = 60 * ρ - 2 / 5 * ρ ^ 2 := by ring
-- At 40 cars per km a car drives at 44 km/h but the density value moves at c = 28 km/h.
example : (60 : ℚ) * (1 - 40 / 150) = 44 ∧ (60 : ℚ) - 4 / 5 * 40 = 28 := by norm_num
-- After 1/50 h (0.02 h) the 40 cars/km value sits at 14/25 km (0.56), not 22/25 km (0.88): 8/25 km (0.32) too far.
example : (28 : ℚ) * (1 / 50) = 14 / 25 ∧ (44 : ℚ) * (1 / 50) = 22 / 25 ∧
    (22 : ℚ) / 25 - 14 / 25 = 8 / 25 := by norm_num

#print axioms quasilinear_equation_solved_uniquely_by_characteristics
#print axioms flow_constant_along_car_path
#print axioms probe_car_data_fix_nothing
