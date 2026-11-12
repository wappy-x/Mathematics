-- The SIR model: in S' = -bSI, I' = bSI - gI with positive rates, the ill share grows while S is above 1/R0 = g/b and falls once S is at or below it, the outbreak dies out with a positive share never infected that solves the final-size equation, the peak height is S0 + I0 - (1/R0)(1 + ln(R0 S0)), and z = 1 - e^(-R0 z) has one positive root exactly when R0 > 1.
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Topology.Order.MonotoneConvergence
import Mathlib.Topology.Order.IntermediateValue

open Filter Topology

/-- A positive solution of a linear equation f' = c·f with continuous c stays positive. -/
theorem sir_pos_of_linear {f c : ℝ → ℝ} (hc : ContinuousOn c (Set.Ici 0))
    (hf : ∀ t, 0 ≤ t → HasDerivAt f (c t * f t) t) (h0 : 0 < f 0) :
    ∀ t, 0 ≤ t → 0 < f t := by
  intro t ht
  by_contra hneg
  push Not at hneg
  have hfc : ContinuousOn f (Set.Icc 0 t) := fun x hx =>
    (hf x hx.1).continuousAt.continuousWithinAt
  obtain ⟨τ, hτ, hfτ⟩ : ∃ τ ∈ Set.Icc 0 t, f τ = 0 :=
    intermediate_value_Icc' ht hfc ⟨hneg, h0.le⟩
  obtain ⟨C, hC⟩ := (isCompact_Icc (a := (0:ℝ)) (b := τ)).exists_bound_of_continuousOn
    (hc.mono (fun x hx => (hx.1 : (0:ℝ) ≤ x)))
  have heq : Set.EqOn f (fun _ => (0:ℝ)) (Set.Icc 0 τ) := by
    apply ODE_solution_unique_of_mem_Icc_left (v := fun s x => c s * x) (s := fun _ => Set.univ)
      (K := Real.toNNReal C)
    · intro s hs
      apply LipschitzWith.lipschitzOnWith
      apply LipschitzWith.of_dist_le_mul
      intro x y
      rw [Real.dist_eq, Real.dist_eq, ← mul_sub, abs_mul]
      have := hC s (Set.Ioc_subset_Icc_self hs)
      rw [Real.norm_eq_abs] at this
      exact mul_le_mul_of_nonneg_right (this.trans (Real.le_coe_toNNReal C)) (abs_nonneg _)
    · exact hfc.mono (Set.Icc_subset_Icc_right hτ.2)
    · intro s hs
      exact (hf s hs.1.le).hasDerivWithinAt
    · intro s hs; trivial
    · exact continuousOn_const
    · intro s hs
      simpa using (hasDerivAt_const s (0:ℝ)).hasDerivWithinAt
    · intro s hs; trivial
    · simpa using hfτ
  have := heq (Set.left_mem_Icc.2 hτ.1)
  simp at this
  linarith

/-- In the SIR laws, both shares stay positive. -/
theorem sir_pos {b g : ℝ} {S I : ℝ → ℝ}
    (hS : ∀ t, 0 ≤ t → HasDerivAt S (-b * S t * I t) t)
    (hI : ∀ t, 0 ≤ t → HasDerivAt I (b * S t * I t - g * I t) t)
    (hS0 : 0 < S 0) (hI0 : 0 < I 0) : ∀ t, 0 ≤ t → 0 < S t ∧ 0 < I t := by
  have hSc : ContinuousOn S (Set.Ici 0) := fun t ht => (hS t ht).continuousAt.continuousWithinAt
  have hIc : ContinuousOn I (Set.Ici 0) := fun t ht => (hI t ht).continuousAt.continuousWithinAt
  intro t ht
  constructor
  · refine sir_pos_of_linear (c := fun t => -b * I t) (continuousOn_const.mul hIc)
      (fun s hs => ?_) hS0 t ht
    convert hS s hs using 1
    ring
  · refine sir_pos_of_linear (c := fun t => b * S t - g)
      ((continuousOn_const.mul hSc).sub continuousOn_const) (fun s hs => ?_) hI0 t ht
    convert hI s hs using 1
    ring

/-- In the SIR laws, S + I - ln(S)/R0 stays constant. -/
theorem sir_conserved {b g : ℝ} (hb : 0 < b) (_hg : 0 < g) {S I : ℝ → ℝ}
    (hS : ∀ t, 0 ≤ t → HasDerivAt S (-b * S t * I t) t)
    (hI : ∀ t, 0 ≤ t → HasDerivAt I (b * S t * I t - g * I t) t)
    (hS0 : 0 < S 0) (hI0 : 0 < I 0) :
    ∀ t, 0 ≤ t → S t + I t - Real.log (S t) / (b / g) =
      S 0 + I 0 - Real.log (S 0) / (b / g) := by
  have hpos := sir_pos hS hI hS0 hI0
  have hH : ∀ t, 0 ≤ t →
      HasDerivAt (fun t => S t + I t - Real.log (S t) / (b / g)) 0 t := by
    intro t ht
    have h := ((hS t ht).add (hI t ht)).sub
      (((hS t ht).log (hpos t ht).1.ne').div_const (b / g))
    convert h using 1
    have := (hpos t ht).1.ne'
    field_simp
    ring
  intro t ht
  have := constant_of_has_deriv_right_zero
    (f := fun t => S t + I t - Real.log (S t) / (b / g)) (a := 0) (b := t)
    (fun x hx => (hH x hx.1).continuousAt.continuousWithinAt)
    (fun x hx => (hH x hx.1).hasDerivWithinAt) t ⟨ht, le_refl t⟩
  exact this

#print axioms sir_pos_of_linear
#print axioms sir_pos
#print axioms sir_conserved

/-- **Threshold and burn-out.** Take a contact rate b > 0 and a recovery rate g > 0, fixed in
time, so the reproduction number is R0 = b/g. Let the susceptible share S(t) and the ill share
I(t) follow the SIR laws S' = -b·S·I and I' = b·S·I - g·I for every time t ≥ 0, starting with
some people susceptible and some ill (S(0) > 0, I(0) > 0). Then:
1. both shares stay positive, and the susceptible share only falls;
2. cases multiply while S is above 1/R0: between two times, I rises whenever S is still above
   1/R0 at the later time;
3. once S is at or below 1/R0, the ill share falls from then on;
4. the outbreak dies out (I tends to 0) and S settles at a share S∞ with 0 < S∞ < 1/R0, so a
   fixed share of the town is never infected; that share solves the final-size equation
   S∞ - ln(S∞)/R0 = S0 + I0 - ln(S0)/R0. -/
theorem sir_outbreak_grows_above_threshold_and_burns_out
    {b g : ℝ} (hb : 0 < b) (hg : 0 < g) {S I : ℝ → ℝ}
    (hS : ∀ t, 0 ≤ t → HasDerivAt S (-b * S t * I t) t)
    (hI : ∀ t, 0 ≤ t → HasDerivAt I (b * S t * I t - g * I t) t)
    (hS0 : 0 < S 0) (hI0 : 0 < I 0) :
    (∀ t, 0 ≤ t → 0 < S t ∧ 0 < I t) ∧
    StrictAntiOn S (Set.Ici 0) ∧
    (∀ t₁ t₂, 0 ≤ t₁ → t₁ < t₂ → 1 / (b / g) < S t₂ → I t₁ < I t₂) ∧
    (∀ t₀, 0 ≤ t₀ → S t₀ ≤ 1 / (b / g) → StrictAntiOn I (Set.Ici t₀)) ∧
    Tendsto I atTop (𝓝 0) ∧
    ∃ Sinf, 0 < Sinf ∧ Sinf < 1 / (b / g) ∧ Tendsto S atTop (𝓝 Sinf) ∧
      Sinf - Real.log Sinf / (b / g) = S 0 + I 0 - Real.log (S 0) / (b / g) := by
  have hpos := sir_pos hS hI hS0 hI0
  have hcons := sir_conserved hb hg hS hI hS0 hI0
  have hSc : ContinuousOn S (Set.Ici 0) := fun t ht => (hS t ht).continuousAt.continuousWithinAt
  have hIc : ContinuousOn I (Set.Ici 0) := fun t ht => (hI t ht).continuousAt.continuousWithinAt
  have hR : 0 < b / g := div_pos hb hg
  have hanti : StrictAntiOn S (Set.Ici 0) := by
    apply strictAntiOn_of_deriv_neg (convex_Ici 0) hSc
    intro t ht
    rw [interior_Ici] at ht
    have ht' : 0 ≤ t := le_of_lt ht
    rw [(hS t ht').deriv]
    have := mul_pos (mul_pos hb (hpos t ht').1) (hpos t ht').2
    linarith
  have hgrow : ∀ t₁ t₂, 0 ≤ t₁ → t₁ < t₂ → 1 / (b / g) < S t₂ → I t₁ < I t₂ := by
    intro t₁ t₂ ht₁ ht₁₂ hSt₂
    have hmono : StrictMonoOn I (Set.Icc t₁ t₂) := by
      apply strictMonoOn_of_deriv_pos (convex_Icc t₁ t₂)
        (hIc.mono (fun x hx => le_trans ht₁ hx.1))
      intro t ht
      rw [interior_Icc] at ht
      have ht0 : 0 ≤ t := by linarith [ht.1]
      rw [(hI t ht0).deriv]
      have hlt : S t₂ < S t := hanti (Set.mem_Ici.2 ht0) (Set.mem_Ici.2 (by linarith [ht.2])) ht.2
      have h1 : 1 / (b / g) < S t := lt_trans hSt₂ hlt
      rw [one_div_div, div_lt_iff₀ hb] at h1
      have := mul_pos (sub_pos.2 h1) (hpos t ht0).2
      nlinarith
    exact hmono (Set.left_mem_Icc.2 ht₁₂.le) (Set.right_mem_Icc.2 ht₁₂.le) ht₁₂
  have hshrink : ∀ t₀, 0 ≤ t₀ → S t₀ ≤ 1 / (b / g) → StrictAntiOn I (Set.Ici t₀) := by
    intro t₀ ht₀ hSt₀
    apply strictAntiOn_of_deriv_neg (convex_Ici t₀)
      (hIc.mono (fun x hx => le_trans ht₀ (Set.mem_Ici.1 hx)))
    intro t ht
    rw [interior_Ici] at ht
    have ht0 : 0 ≤ t := le_trans ht₀ (le_of_lt ht)
    rw [(hI t ht0).deriv]
    have hlt : S t < S t₀ := hanti (Set.mem_Ici.2 ht₀) (Set.mem_Ici.2 ht0) ht
    have h1 : S t < 1 / (b / g) := lt_of_lt_of_le hlt hSt₀
    rw [one_div_div, lt_div_iff₀ hb] at h1
    have := mul_pos (sub_pos.2 h1) (hpos t ht0).2
    nlinarith
  set C := S 0 + I 0 - Real.log (S 0) / (b / g) with hC
  have hlow : ∀ t, 0 ≤ t → Real.exp (-(C * (b / g))) < S t := by
    intro t ht
    have h1 := hcons t ht
    have hSt := (hpos t ht).1
    have hIt := (hpos t ht).2
    rw [← Real.lt_log_iff_exp_lt hSt]
    have h2 : -C < Real.log (S t) / (b / g) := by linarith
    have h3 := (lt_div_iff₀ hR).1 h2
    linarith
  set m := Real.exp (-(C * (b / g))) with hm
  have hmpos : 0 < m := Real.exp_pos _
  have hS'anti : Antitone (fun t => S (max t 0)) := by
    intro x y hxy
    exact hanti.antitoneOn (Set.mem_Ici.2 (le_max_right x 0)) (Set.mem_Ici.2 (le_max_right y 0))
      (max_le_max hxy le_rfl)
  have hS'bdd : BddBelow (Set.range (fun t => S (max t 0))) :=
    ⟨m, by rintro _ ⟨t, rfl⟩; exact (hlow _ (le_max_right t 0)).le⟩
  have hS'lim := tendsto_atTop_ciInf hS'anti hS'bdd
  set Sinf := ⨅ t, S (max t 0) with hSinf
  have hSlim : Tendsto S atTop (𝓝 Sinf) := by
    refine Tendsto.congr' ?_ hS'lim
    filter_upwards [eventually_ge_atTop 0] with t ht
    show S (max t 0) = S t
    rw [max_eq_left ht]
  have hSinf_le : ∀ t, 0 ≤ t → Sinf ≤ S t := by
    intro t ht
    have : Sinf ≤ S (max t 0) := ciInf_le hS'bdd t
    rwa [max_eq_left ht] at this
  have hm_le : m ≤ Sinf := le_ciInf (fun t => (hlow _ (le_max_right t 0)).le)
  have hSinfpos : 0 < Sinf := lt_of_lt_of_le hmpos hm_le
  set Iinf := C - Sinf + Real.log Sinf / (b / g) with hIinf
  have hIlim : Tendsto I atTop (𝓝 Iinf) := by
    have h : Tendsto (fun t => C - S t + Real.log (S t) / (b / g)) atTop (𝓝 Iinf) :=
      (tendsto_const_nhds.sub hSlim).add
        (((Real.continuousAt_log hSinfpos.ne').tendsto.comp hSlim).div_const _)
    refine h.congr' ?_
    filter_upwards [eventually_ge_atTop 0] with t ht
    have := hcons t ht
    show C - S t + Real.log (S t) / (b / g) = I t
    linarith
  have hIinf_nonneg : 0 ≤ Iinf := ge_of_tendsto hIlim (by
    filter_upwards [eventually_ge_atTop 0] with t ht
    exact (hpos t ht).2.le)
  have hIinf0 : Iinf = 0 := by
    by_contra hne
    have hIp : 0 < Iinf := lt_of_le_of_ne hIinf_nonneg (Ne.symm hne)
    obtain ⟨T, hT⟩ := eventually_atTop.1 (hIlim.eventually (lt_mem_nhds (half_lt_self hIp)))
    set T' := max T 0 with hT'
    have hT'0 : 0 ≤ T' := le_max_right _ _
    set k := b * m * (Iinf / 2) with hk
    have hkpos : 0 < k := by positivity
    have hd : ∀ t, T' ≤ t → HasDerivAt (fun t => S t + k * t) (-b * S t * I t + k) t := by
      intro t ht
      exact ((hS t (le_trans hT'0 ht)).add ((hasDerivAt_id' t).const_mul k)).congr_deriv
        (by ring)
    have hFanti : AntitoneOn (fun t => S t + k * t) (Set.Ici T') := by
      apply antitoneOn_of_deriv_nonpos (convex_Ici T')
      · intro t ht
        exact (hd t ht).continuousAt.continuousWithinAt
      · intro t ht
        rw [interior_Ici] at ht
        exact (hd t (le_of_lt ht)).differentiableAt.differentiableWithinAt
      · intro t ht
        rw [interior_Ici] at ht
        have ht' : T' ≤ t := le_of_lt ht
        have ht0 : 0 ≤ t := le_trans hT'0 ht'
        rw [(hd t ht').deriv]
        have h1 : Iinf / 2 < I t := hT t (le_trans (le_max_left _ _) ht')
        have h2 : m < S t := hlow t ht0
        have h3 : m * (Iinf / 2) ≤ S t * I t :=
          mul_le_mul h2.le h1.le (by positivity) (hpos t ht0).1.le
        have h4 : b * (m * (Iinf / 2)) ≤ b * (S t * I t) := mul_le_mul_of_nonneg_left h3 hb.le
        rw [hk]
        nlinarith
    have hST'pos := (hpos T' hT'0).1
    have hdiv : 0 ≤ (S T' + 1) / k := div_nonneg (by linarith) hkpos.le
    have htT : T' ≤ T' + (S T' + 1) / k := by linarith
    have hF := hFanti (Set.mem_Ici.2 le_rfl) (Set.mem_Ici.2 htT) htT
    simp only at hF
    have hkt : k * (T' + (S T' + 1) / k) = k * T' + (S T' + 1) := by
      rw [mul_add, mul_div_cancel₀ _ hkpos.ne']
    have := (hpos (T' + (S T' + 1) / k) (le_trans hT'0 htT)).1
    linarith
  have hSinf_lt : Sinf < 1 / (b / g) := by
    by_contra hge
    push Not at hge
    have hgrowall : ∀ t, 1 ≤ t → I 0 < I t := by
      intro t ht
      apply hgrow 0 t le_rfl (by linarith)
      have h1 : S (t + 1) < S t :=
        hanti (Set.mem_Ici.2 (by linarith)) (Set.mem_Ici.2 (by linarith)) (by linarith)
      have h2 := hSinf_le (t + 1) (by linarith)
      linarith
    have : I 0 ≤ Iinf := ge_of_tendsto hIlim (by
      filter_upwards [eventually_ge_atTop 1] with t ht
      exact (hgrowall t ht).le)
    linarith [hpos 0 le_rfl]
  refine ⟨hpos, hanti, hgrow, hshrink, ?_, Sinf, hSinfpos, hSinf_lt, hSlim, ?_⟩
  · rw [hIinf0] at hIlim
    exact hIlim
  · linarith [hIinf, hIinf0]

/-- **The peak (Step 3).** Under the same laws, with positive rates and a start S(0) > 0,
I(0) > 0, if the town starts above the threshold (S(0) > 1/R0), then there is a time when S
reaches exactly 1/R0, the ill share there is the largest it ever gets, and its value is
I_max = S0 + I0 - (1/R0)(1 + ln(R0·S0)). -/
theorem sir_peak_at_threshold
    {b g : ℝ} (hb : 0 < b) (hg : 0 < g) {S I : ℝ → ℝ}
    (hS : ∀ t, 0 ≤ t → HasDerivAt S (-b * S t * I t) t)
    (hI : ∀ t, 0 ≤ t → HasDerivAt I (b * S t * I t - g * I t) t)
    (hS0 : 0 < S 0) (hI0 : 0 < I 0) (habove : 1 / (b / g) < S 0) :
    ∃ tp, 0 ≤ tp ∧ S tp = 1 / (b / g) ∧
      I tp = S 0 + I 0 - 1 / (b / g) * (1 + Real.log (b / g * S 0)) ∧
      ∀ t, 0 ≤ t → I t ≤ I tp := by
  obtain ⟨hpos, hanti, hgrow, hshrink, hIlim, Sinf, hSinfpos, hSinf_lt, hSlim, hfinal⟩ :=
    sir_outbreak_grows_above_threshold_and_burns_out hb hg hS hI hS0 hI0
  have hSc : ContinuousOn S (Set.Ici 0) := fun t ht => (hS t ht).continuousAt.continuousWithinAt
  have hIc : ContinuousOn I (Set.Ici 0) := fun t ht => (hI t ht).continuousAt.continuousWithinAt
  obtain ⟨T, hT⟩ := eventually_atTop.1 (hSlim.eventually (gt_mem_nhds hSinf_lt))
  have hT'0 : 0 ≤ max T 0 := le_max_right _ _
  have hST' : S (max T 0) < 1 / (b / g) := hT (max T 0) (le_max_left _ _)
  obtain ⟨tp, htp, hStp⟩ := intermediate_value_Icc' hT'0
    (hSc.mono (fun x hx => Set.mem_Ici.2 hx.1)) ⟨hST'.le, habove.le⟩
  have htp0 : 0 ≤ tp := htp.1
  refine ⟨tp, htp0, hStp, ?_, ?_⟩
  · have hc := sir_conserved hb hg hS hI hS0 hI0 tp htp0
    rw [hStp] at hc
    have hR : 0 < b / g := div_pos hb hg
    have hlog1 : Real.log (1 / (b / g)) = - Real.log (b / g) := by rw [one_div, Real.log_inv]
    have hlog2 : Real.log (b / g * S 0) = Real.log (b / g) + Real.log (S 0) :=
      Real.log_mul hR.ne' hS0.ne'
    rw [hlog1] at hc
    rw [hlog2]
    linear_combination hc
  · intro t ht
    rcases le_or_gt t tp with h | h
    · have hmono : StrictMonoOn I (Set.Icc 0 tp) := by
        apply strictMonoOn_of_deriv_pos (convex_Icc 0 tp) (hIc.mono (fun x hx => Set.mem_Ici.2 hx.1))
        intro x hx
        rw [interior_Icc] at hx
        have hx0 : 0 ≤ x := hx.1.le
        rw [(hI x hx0).deriv]
        have h1 : S tp < S x := hanti (Set.mem_Ici.2 hx0) (Set.mem_Ici.2 htp0) hx.2
        rw [hStp, one_div_div, div_lt_iff₀ hb] at h1
        have := mul_pos (sub_pos.2 h1) (hpos x hx0).2
        nlinarith
      exact hmono.monotoneOn ⟨ht, h⟩ ⟨htp0, le_rfl⟩ h
    · exact (hshrink tp htp0 hStp.le).antitoneOn (Set.mem_Ici.2 le_rfl) (Set.mem_Ici.2 h.le) h.le

/-- **The final-size equation (Step 4).** For a reproduction number R0 > 0, the equation
z = 1 - e^(-R0·z) has exactly one root z > 0 when R0 > 1, and that root lies below 1 (some
people are never infected); when R0 ≤ 1 its only root with z ≥ 0 is z = 0: no outbreak. -/
theorem final_size_equation_root {R0 : ℝ} (hR0 : 0 < R0) :
    (1 < R0 → ∃ z, 0 < z ∧ z < 1 ∧ z = 1 - Real.exp (-R0 * z) ∧
      ∀ w, 0 < w → w = 1 - Real.exp (-R0 * w) → w = z) ∧
    (R0 ≤ 1 → ∀ z, 0 ≤ z → z = 1 - Real.exp (-R0 * z) → z = 0) := by
  have key : ∀ u v, 0 < u → u < v → u = 1 - Real.exp (-R0 * u) →
      v = 1 - Real.exp (-R0 * v) → False := by
    intro u v hu huv hu' hv'
    have hv : 0 < v := hu.trans huv
    obtain ⟨l, hl⟩ : ∃ l, l = u / v := ⟨_, rfl⟩
    have hl0 : 0 < l := by rw [hl]; exact div_pos hu hv
    have hl1 : l < 1 := by rw [hl]; exact (div_lt_one hv).2 huv
    have hne : -R0 * v ≠ 0 := by
      have : 0 < R0 * v := mul_pos hR0 hv
      intro h
      linarith
    have h := strictConvexOn_exp.2 (Set.mem_univ (-R0 * v)) (Set.mem_univ 0) hne hl0
      (sub_pos.2 hl1) (by ring)
    simp only [smul_eq_mul, mul_zero, add_zero, Real.exp_zero, mul_one] at h
    have hlv : l * v = u := by rw [hl]; exact div_mul_cancel₀ u hv.ne'
    have hlu : l * (-R0 * v) = -R0 * u := by rw [← hlv]; ring
    rw [hlu] at h
    have he1 : Real.exp (-R0 * u) = 1 - u := by linarith
    have he2 : Real.exp (-R0 * v) = 1 - v := by linarith
    rw [he1, he2] at h
    nlinarith
  constructor
  · intro h1
    obtain ⟨ε, hε⟩ : ∃ ε, ε = (R0 - 1) / (2 * R0) := ⟨_, rfl⟩
    have hεpos : 0 < ε := by rw [hε]; exact div_pos (by linarith) (by linarith)
    have hε1 : ε < 1 := by rw [hε, div_lt_one (by linarith)]; linarith
    have hx : R0 * ε = (R0 - 1) / 2 := by
      rw [hε]
      field_simp
    have hexp : Real.exp (-R0 * ε) * (1 + R0 * ε) ≤ 1 := by
      have := Real.add_one_le_exp (R0 * ε)
      calc Real.exp (-R0 * ε) * (1 + R0 * ε) ≤ Real.exp (-R0 * ε) * Real.exp (R0 * ε) :=
            mul_le_mul_of_nonneg_left (by linarith) (Real.exp_pos _).le
        _ = 1 := by rw [← Real.exp_add]; simp
    have hprod : 1 < (1 - ε) * (1 + R0 * ε) := by
      have : (1 - ε) * (1 + R0 * ε) - 1 = (R0 - 1) ^ 2 / (4 * R0) := by
        rw [hx, hε]
        field_simp
        ring
      have : 0 < (R0 - 1) ^ 2 / (4 * R0) := by
        have : 0 < R0 - 1 := by linarith
        positivity
      linarith
    have hfε : 0 < 1 - Real.exp (-R0 * ε) - ε := by
      by_contra hcon
      push Not at hcon
      have hpos1 : 0 < 1 + R0 * ε := by rw [hx]; linarith
      have : (1 - ε) * (1 + R0 * ε) ≤ Real.exp (-R0 * ε) * (1 + R0 * ε) :=
        mul_le_mul_of_nonneg_right (by linarith) hpos1.le
      linarith
    have hfc : ContinuousOn (fun z => 1 - Real.exp (-R0 * z) - z) (Set.Icc ε 1) := by
      fun_prop
    have hf1 : 1 - Real.exp (-R0 * 1) - 1 < 0 := by
      have := Real.exp_pos (-R0 * 1)
      linarith
    obtain ⟨z, hz, hfz⟩ := intermediate_value_Icc' hε1.le hfc ⟨hf1.le, hfε.le⟩
    have hz0 : 0 < z := lt_of_lt_of_le hεpos hz.1
    have hzeq : z = 1 - Real.exp (-R0 * z) := by
      simp only at hfz
      linarith
    refine ⟨z, hz0, ?_, hzeq, ?_⟩
    · have := Real.exp_pos (-R0 * z)
      linarith
    · intro w hw hweq
      rcases lt_trichotomy w z with h | h | h
      · exact (key w z hw h hweq hzeq).elim
      · exact h
      · exact (key z w hz0 h hzeq hweq).elim
  · intro h1 z hz hzeq
    by_contra hne
    have hzpos : 0 < z := lt_of_le_of_ne hz (Ne.symm hne)
    have hne' : -R0 * z ≠ 0 := by
      have := mul_pos hR0 hzpos
      intro h
      linarith
    have := Real.add_one_lt_exp hne'
    nlinarith [mul_nonneg (sub_nonneg.2 h1) hz]

-- The card's flu, in exact fractions: b = 0.625 = 5/8 per day, g = 0.25 = 1/4 per day.
-- R0 = b/g = 5/2, and also b times the 4-day illness: (5/8)·4 = 5/2.
example : (5/8 : ℚ) / (1/4) = 5/2 ∧ (5/8 : ℚ) * 4 = 5/2 := by norm_num
-- The illness lasts 1/g = 4 days.
example : 1 / (1/4 : ℚ) = 4 := by norm_num
-- Early growth rate b - g = 3/8 = 0.375 per day.
example : (5/8 : ℚ) - 1/4 = 3/8 := by norm_num
-- The peak threshold S = 1/R0 = 2/5 = 0.4, and the vaccination target 1 - 1/R0 = 3/5 = 60%.
example : 1 / (5/2 : ℚ) = 2/5 ∧ 1 - 1 / (5/2 : ℚ) = 3/5 := by norm_num
-- One case in a town of 10,000: S0 = 9999/10000, I0 = 1/10000, and the shares add to 1.
example : (9999/10000 : ℚ) + 1/10000 = 1 := by norm_num
-- Jacobian at the untouched town (S, I) = (1, 0): [[-bI, -bS], [bI, bS - g]] = [[0, -5/8], [0, 3/8]];
-- trace 3/8 and determinant 0, so the eigenvalues are 0 and +3/8 = +0.375 per day.
example : (0 : ℚ) + (5/8 * 1 - 1/4) = 3/8 ∧ (0 : ℚ) * (5/8 * 1 - 1/4) - (-(5/8) * 1) * 0 = 0 := by
  norm_num
-- Final count: 8,927 ever ill leaves 1,073 never ill; 60% of the town is 6,000, so 2,927 more
-- are infected after the threshold.
example : (10000 : ℕ) - 8927 = 1073 ∧ 10000 * 60 / 100 = 6000 ∧ (8927 : ℕ) - 6000 = 2927 := by decide
-- Mistake 3: using the period 4 as the rate gives R0 = (5/8)/4 = 5/32 = 0.15625, below 1.
example : (5/8 : ℚ) / 4 = 5/32 ∧ (5/32 : ℚ) < 1 := by norm_num

#print axioms sir_outbreak_grows_above_threshold_and_burns_out
#print axioms sir_peak_at_threshold
#print axioms final_size_equation_root
