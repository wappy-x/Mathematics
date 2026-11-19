-- Jacobi field: on a surface, a gap f with f'' + K f = 0, f(0) = 0, f'(0) = α is trapped between the constant-curvature model gaps α sn_khi and α sn_klo when klo ≤ K ≤ khi, and on a sphere of radius R the gap α R sin(s/R) returns to zero at π R.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real Set

/-! The path is run at unit speed, so `s` is distance flown. On a surface the Jacobi field across
the path is one signed length `f s`; `f' s` is its rate and `K s` is the Gaussian curvature at the
point reached. The Jacobi equation `f'' + K f = 0` on the stretch `[0, L]` is written as two
derivative statements: `f` has rate `f'`, and `f'` has rate `-(K f)`. -/

/-- The model space's gap per radian of spread, for constant curvature `k`:
`sin(√k s)/√k` when `k > 0`, `s` when `k = 0`, `sinh(√(-k) s)/√(-k)` when `k < 0`. -/
noncomputable def sn (k s : ℝ) : ℝ :=
  if 0 < k then Real.sin (Real.sqrt k * s) / Real.sqrt k
  else if k < 0 then Real.sinh (Real.sqrt (-k) * s) / Real.sqrt (-k)
  else s

/-- The model gap starts at zero. -/
theorem sn_zero (k : ℝ) : sn k 0 = 0 := by
  simp [sn]

/-- The model gap has a rate `c` with `c 0 = 1`, and that rate changes at `-(k sn_k)`. -/
theorem sn_model (k : ℝ) : ∃ c : ℝ → ℝ, c 0 = 1 ∧ (∀ s, HasDerivAt (sn k) (c s) s) ∧
    (∀ s, HasDerivAt c (-(k * sn k s)) s) := by
  by_cases h1 : 0 < k
  · have hr : 0 < Real.sqrt k := Real.sqrt_pos.2 h1
    have hsq : Real.sqrt k * Real.sqrt k = k := Real.mul_self_sqrt h1.le
    have hfun : sn k = fun s => Real.sin (Real.sqrt k * s) / Real.sqrt k := by
      funext s; simp [sn, h1]
    refine ⟨fun s => Real.cos (Real.sqrt k * s), by simp, fun s => ?_, fun s => ?_⟩
    · rw [hfun]
      have := (((hasDerivAt_id' s).const_mul (Real.sqrt k)).sin).div_const (Real.sqrt k)
      convert this using 1
      field_simp
    · have := ((hasDerivAt_id' s).const_mul (Real.sqrt k)).cos
      convert this using 1
      rw [hfun]
      dsimp only
      generalize Real.sqrt k = r at hr hsq ⊢
      subst hsq
      field_simp
  · by_cases h2 : k < 0
    · have hk : 0 < -k := neg_pos.2 h2
      have hr : 0 < Real.sqrt (-k) := Real.sqrt_pos.2 hk
      have hsq : Real.sqrt (-k) * Real.sqrt (-k) = -k := Real.mul_self_sqrt hk.le
      have hfun : sn k = fun s => Real.sinh (Real.sqrt (-k) * s) / Real.sqrt (-k) := by
        funext s; simp [sn, h1, h2]
      refine ⟨fun s => Real.cosh (Real.sqrt (-k) * s), by simp, fun s => ?_, fun s => ?_⟩
      · rw [hfun]
        have := (((hasDerivAt_id' s).const_mul (Real.sqrt (-k))).sinh).div_const (Real.sqrt (-k))
        convert this using 1
        field_simp
      · have := ((hasDerivAt_id' s).const_mul (Real.sqrt (-k))).cosh
        convert this using 1
        rw [hfun]
        dsimp only
        generalize Real.sqrt (-k) = r at hr hsq ⊢
        obtain rfl : k = -(r * r) := by linarith
        field_simp
    · have hk : k = 0 := le_antisymm (not_lt.1 h1) (not_lt.1 h2)
      have hfun : sn k = fun s => s := by
        funext s; simp [sn, h1, h2]
      refine ⟨fun _ => 1, rfl, fun s => ?_, fun s => ?_⟩
      · rw [hfun]; exact hasDerivAt_id' s
      · rw [hk]; simpa using hasDerivAt_const s (1 : ℝ)

/-- The model gap is positive before the model's first return to zero. -/
theorem sn_pos (k s : ℝ) (hs : 0 < s) (hk : 0 < k → s < π / Real.sqrt k) : 0 < sn k s := by
  unfold sn
  split_ifs with h1 h2
  · have hr : 0 < Real.sqrt k := Real.sqrt_pos.2 h1
    apply div_pos _ hr
    apply Real.sin_pos_of_pos_of_lt_pi (mul_pos hr hs)
    have := hk h1
    rw [lt_div_iff₀ hr] at this
    linarith [mul_comm s (Real.sqrt k)]
  · have hr : 0 < Real.sqrt (-k) := Real.sqrt_pos.2 (neg_pos.2 h2)
    exact div_pos (Real.sinh_pos_iff.2 (mul_pos hr hs)) hr
  · exact hs

open Filter Topology in
/-- A function starting at 0 with right rate `α` has `g u / u → α` as `u → 0⁺`. -/
theorem slope_tendsto (g : ℝ → ℝ) (α T : ℝ) (hT : 0 < T)
    (hg : HasDerivWithinAt g α (Icc 0 T) 0) (hg0 : g 0 = 0) :
    Tendsto (fun u => g u / u) (𝓝[>] 0) (𝓝 α) := by
  have h1 : HasDerivWithinAt g α (Ioi 0) 0 :=
    (hg.mono_of_mem_nhdsWithin (Icc_mem_nhdsGE hT)).mono Ioi_subset_Ici_self
  rw [hasDerivWithinAt_iff_tendsto_slope' (by simp)] at h1
  refine h1.congr' ?_
  filter_upwards with u
  simp [slope_def_field, hg0]

open Filter Topology in
/-- Two functions starting at 0 with the same positive rate have ratio tending to 1. -/
theorem ratio_tendsto (p q : ℝ → ℝ) (α T : ℝ) (hα : 0 < α) (hT : 0 < T)
    (hp : HasDerivWithinAt p α (Icc 0 T) 0) (hq : HasDerivWithinAt q α (Icc 0 T) 0)
    (hp0 : p 0 = 0) (hq0 : q 0 = 0) :
    Tendsto (fun u => p u / q u) (𝓝[>] 0) (𝓝 1) := by
  have := (slope_tendsto p α T hT hp hp0).div (slope_tendsto q α T hT hq hq0) hα.ne'
  rw [div_self hα.ne'] at this
  refine this.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with u (hu : 0 < u)
  exact div_div_div_cancel_right₀ hu.ne' _ _

open Filter Topology in
/-- A function starting at 0 with positive right rate is positive just after 0. -/
theorem pos_near_zero (p : ℝ → ℝ) (α T : ℝ) (hα : 0 < α) (hT : 0 < T)
    (hp : HasDerivWithinAt p α (Icc 0 T) 0) (hp0 : p 0 = 0) :
    ∃ δ > 0, ∀ u ∈ Ioo 0 δ, 0 < p u := by
  have h := (slope_tendsto p α T hT hp hp0).eventually (lt_mem_nhds hα)
  have h2 : ∀ᶠ u in 𝓝[>] (0 : ℝ), 0 < p u := by
    filter_upwards [h, self_mem_nhdsWithin] with u hu (hu0 : 0 < u)
    exact (div_pos_iff_of_pos_right hu0).1 hu
  obtain ⟨δ, hδ, hsub⟩ := mem_nhdsGT_iff_exists_Ioo_subset.1 h2
  exact ⟨δ, hδ, fun u hu => hsub hu⟩

/-- The Wronskian `p' q - p q'` of two solutions of `y'' + a y = 0` and `y'' + b y = 0` that
both start at 0 stays nonnegative while `(b - a) p q ≥ 0`. -/
theorem wronskian_nonneg (p p' q q' a b : ℝ → ℝ) (T : ℝ)
    (hp : ∀ t ∈ Icc 0 T, HasDerivWithinAt p (p' t) (Icc 0 T) t)
    (hp' : ∀ t ∈ Icc 0 T, HasDerivWithinAt p' (-(a t * p t)) (Icc 0 T) t)
    (hq : ∀ t ∈ Icc 0 T, HasDerivWithinAt q (q' t) (Icc 0 T) t)
    (hq' : ∀ t ∈ Icc 0 T, HasDerivWithinAt q' (-(b t * q t)) (Icc 0 T) t)
    (hp0 : p 0 = 0) (hq0 : q 0 = 0)
    (hsign : ∀ t ∈ Ioo 0 T, 0 ≤ (b t - a t) * (p t * q t)) :
    ∀ t ∈ Icc 0 T, 0 ≤ p' t * q t - p t * q' t := by
  intro t ht
  have hW : ∀ x ∈ Icc 0 T, HasDerivWithinAt (fun x => p' x * q x - p x * q' x)
      ((b x - a x) * (p x * q x)) (Icc 0 T) x := by
    intro x hx
    have := ((hp' x hx).mul (hq x hx)).sub ((hp x hx).mul (hq' x hx))
    convert this using 1
    ring
  have mono : MonotoneOn (fun x => p' x * q x - p x * q' x) (Icc 0 T) := by
    apply monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc 0 T)
    · intro x hx; exact (hW x hx).continuousWithinAt
    · rw [interior_Icc]; intro x hx
      exact (hW x (Ioo_subset_Icc_self hx)).mono Ioo_subset_Icc_self
    · rw [interior_Icc]; exact hsign
  have h0 : (0 : ℝ) ∈ Icc 0 T := ⟨le_rfl, ht.1.trans ht.2⟩
  have := mono h0 ht ht.1
  simpa [hp0, hq0] using this

open Filter Topology in
/-- If the Wronskian `p' q - p q'` is nonnegative and `q > 0` on `(0, s)`, then `q s ≤ p s`. -/
theorem ratio_le (p p' q q' : ℝ → ℝ) (α s : ℝ) (hα : 0 < α) (hs : 0 < s)
    (hp : ∀ t ∈ Icc 0 s, HasDerivWithinAt p (p' t) (Icc 0 s) t)
    (hq : ∀ t ∈ Icc 0 s, HasDerivWithinAt q (q' t) (Icc 0 s) t)
    (hp0 : p 0 = 0) (hq0 : q 0 = 0) (hp'0 : p' 0 = α) (hq'0 : q' 0 = α)
    (hqpos : ∀ t ∈ Ioo 0 s, 0 < q t)
    (hW : ∀ t ∈ Ioo 0 s, 0 ≤ p' t * q t - p t * q' t) : q s ≤ p s := by
  have hr : MonotoneOn (fun t => p t / q t) (Ioo 0 s) := by
    apply monotoneOn_of_hasDerivWithinAt_nonneg (convex_Ioo 0 s)
      (f' := fun t => (p' t * q t - p t * q' t) / q t ^ 2)
    · intro t ht
      exact ((hp t (Ioo_subset_Icc_self ht)).continuousWithinAt.mono Ioo_subset_Icc_self).div
        ((hq t (Ioo_subset_Icc_self ht)).continuousWithinAt.mono Ioo_subset_Icc_self)
        (hqpos t ht).ne'
    · rw [interior_Ioo]; intro t ht
      exact ((hp t (Ioo_subset_Icc_self ht)).mono Ioo_subset_Icc_self).div
        ((hq t (Ioo_subset_Icc_self ht)).mono Ioo_subset_Icc_self) (hqpos t ht).ne'
    · rw [interior_Ioo]; intro t ht
      exact div_nonneg (hW t ht) (sq_nonneg _)
  have h0 : (0 : ℝ) ∈ Icc 0 s := ⟨le_rfl, hs.le⟩
  have hlim := ratio_tendsto p q α s hα hs (hp'0 ▸ hp 0 h0) (hq'0 ▸ hq 0 h0) hp0 hq0
  have hge : ∀ t ∈ Ioo 0 s, q t ≤ p t := by
    intro t ht
    have h1 : 1 ≤ p t / q t := by
      apply le_of_tendsto hlim
      filter_upwards [Ioo_mem_nhdsGT ht.1] with u hu
      exact hr ⟨hu.1, hu.2.trans ht.2⟩ ht hu.2.le
    rwa [one_le_div (hqpos t ht)] at h1
  have hcl : s ∈ closure (Ioo 0 s) := by
    rw [closure_Ioo hs.ne]; exact ⟨hs.le, le_rfl⟩
  have hsI : s ∈ Icc 0 s := ⟨hs.le, le_rfl⟩
  exact ContinuousWithinAt.closure_le hcl
    ((hq s hsI).continuousWithinAt.mono Ioo_subset_Icc_self)
    ((hp s hsI).continuousWithinAt.mono Ioo_subset_Icc_self) hge

/-- Sturm comparison. `p'' + a p = 0` and `q'' + b q = 0` on `[0, T]`, both start at 0 with
rate `α > 0`, `a ≤ b`, and `q > 0` on `(0, T)`. Then `q ≤ p` on `[0, T]`. -/
theorem sturm_compare (p p' q q' a b : ℝ → ℝ) (α T : ℝ) (hα : 0 < α)
    (hp : ∀ t ∈ Icc 0 T, HasDerivWithinAt p (p' t) (Icc 0 T) t)
    (hp' : ∀ t ∈ Icc 0 T, HasDerivWithinAt p' (-(a t * p t)) (Icc 0 T) t)
    (hq : ∀ t ∈ Icc 0 T, HasDerivWithinAt q (q' t) (Icc 0 T) t)
    (hq' : ∀ t ∈ Icc 0 T, HasDerivWithinAt q' (-(b t * q t)) (Icc 0 T) t)
    (hp0 : p 0 = 0) (hq0 : q 0 = 0) (hp'0 : p' 0 = α) (hq'0 : q' 0 = α)
    (hab : ∀ t ∈ Icc 0 T, a t ≤ b t) (hqpos : ∀ t ∈ Ioo 0 T, 0 < q t) :
    ∀ t ∈ Icc 0 T, q t ≤ p t := by
  have key : ∀ S, 0 < S → S ≤ T → (∀ t ∈ Ioo 0 S, 0 < p t) → q S ≤ p S := by
    intro S hS hST hpos
    have sub : Icc 0 S ⊆ Icc 0 T := Icc_subset_Icc_right hST
    have r : ∀ {g : ℝ → ℝ} {D : ℝ → ℝ}, (∀ t ∈ Icc 0 T, HasDerivWithinAt g (D t) (Icc 0 T) t) →
        ∀ t ∈ Icc 0 S, HasDerivWithinAt g (D t) (Icc 0 S) t :=
      fun h t ht => (h t (sub ht)).mono sub
    have hqS : ∀ t ∈ Ioo 0 S, 0 < q t := fun t ht => hqpos t ⟨ht.1, ht.2.trans_le hST⟩
    have hW := wronskian_nonneg p p' q q' a b S (r hp) (r hp') (r hq) (r hq') hp0 hq0
      (fun t ht => mul_nonneg (sub_nonneg.2 (hab t (sub (Ioo_subset_Icc_self ht))))
        (mul_nonneg (hpos t ht).le (hqS t ht).le))
    exact ratio_le p p' q q' α S hα hS (r hp) (r hq) hp0 hq0 hp'0 hq'0 hqS
      (fun t ht => hW t (Ioo_subset_Icc_self ht))
  have hppos : ∀ t ∈ Ioo 0 T, 0 < p t := by
    by_contra hcon
    push Not at hcon
    obtain ⟨z, hz, hfz⟩ := hcon
    have hT : 0 < T := hz.1.trans hz.2
    obtain ⟨δ, hδ, hδp⟩ := pos_near_zero p α T hα hT (hp'0 ▸ hp 0 ⟨le_rfl, hT.le⟩) hp0
    set Z : Set ℝ := {t ∈ Ioo 0 T | p t ≤ 0} with hZ
    have hne : Z.Nonempty := ⟨z, hz, hfz⟩
    have hbdd : BddBelow Z := ⟨0, fun t ht => ht.1.1.le⟩
    have hδt1 : δ ≤ sInf Z := le_csInf hne (fun t ht => by
      by_contra h
      push Not at h
      exact absurd ht.2 (not_le.2 (hδp t ⟨ht.1.1, h⟩)))
    have ht1z : sInf Z ≤ z := csInf_le hbdd ⟨hz, hfz⟩
    have ht1 : sInf Z ∈ Ioo 0 T := ⟨hδ.trans_le hδt1, ht1z.trans_lt hz.2⟩
    have hpt1 : p (sInf Z) ≤ 0 := by
      have hc : ContinuousAt p (sInf Z) :=
        (hp _ (Ioo_subset_Icc_self ht1)).continuousWithinAt.continuousAt
          (Icc_mem_nhds ht1.1 ht1.2)
      exact ContinuousWithinAt.closure_le (csInf_mem_closure hne hbdd) hc.continuousWithinAt
        continuousWithinAt_const (fun t ht => ht.2)
    have hpos1 : ∀ t ∈ Ioo 0 (sInf Z), 0 < p t := by
      intro t ht
      by_contra h
      push Not at h
      have : sInf Z ≤ t := csInf_le hbdd ⟨⟨ht.1, ht.2.trans ht1.2⟩, h⟩
      linarith [ht.2]
    have := key (sInf Z) ht1.1 ht1.2.le hpos1
    linarith [hqpos _ ht1]
  intro t ht
  rcases ht.1.eq_or_lt with h | h
  · subst h; rw [hp0, hq0]
  · exact key t h ht.2 (fun u hu => hppos u ⟨hu.1, hu.2.trans_le ht.2⟩)

#print axioms sn_zero
#print axioms sn_model
#print axioms sn_pos
#print axioms slope_tendsto
#print axioms ratio_tendsto
#print axioms pos_near_zero
#print axioms wronskian_nonneg
#print axioms ratio_le
#print axioms sturm_compare

/-- The comparison theorem on a surface. A gap `f` starts at 0 with rate `α > 0` and obeys the
Jacobi equation `f'' + K f = 0` along the whole stretch `[0, L]`, where the curvature stays
between `klo` and `khi`. If the stretch does not pass the point `π/√khi` where the most curved
model's paths meet again, then at every distance `s` along it the gap is trapped between the two
model gaps: `α sn_khi(s) ≤ f(s) ≤ α sn_klo(s)`. -/
theorem jacobi_gap_between_model_gaps (K f f' : ℝ → ℝ) (α klo khi L : ℝ) (hα : 0 < α)
    (hf : ∀ s ∈ Icc 0 L, HasDerivWithinAt f (f' s) (Icc 0 L) s)
    (hf' : ∀ s ∈ Icc 0 L, HasDerivWithinAt f' (-(K s * f s)) (Icc 0 L) s)
    (hf0 : f 0 = 0) (hf'0 : f' 0 = α)
    (hK : ∀ s ∈ Icc 0 L, klo ≤ K s ∧ K s ≤ khi)
    (hL : 0 < khi → L ≤ π / Real.sqrt khi) :
    ∀ s ∈ Icc 0 L, α * sn khi s ≤ f s ∧ f s ≤ α * sn klo s := by
  intro s hs
  obtain ⟨chi, hchi0, hsnhi, hchi⟩ := sn_model khi
  obtain ⟨clo, hclo0, hsnlo, hclo⟩ := sn_model klo
  have hg : ∀ t ∈ Icc 0 L, HasDerivWithinAt (fun t => α * sn khi t) (α * chi t) (Icc 0 L) t :=
    fun t _ => ((hsnhi t).const_mul α).hasDerivWithinAt
  have hg' : ∀ t ∈ Icc 0 L,
      HasDerivWithinAt (fun t => α * chi t) (-(khi * (α * sn khi t))) (Icc 0 L) t := by
    intro t _
    have := ((hchi t).const_mul α).hasDerivWithinAt (s := Icc 0 L)
    convert this using 1; ring
  have hh : ∀ t ∈ Icc 0 L, HasDerivWithinAt (fun t => α * sn klo t) (α * clo t) (Icc 0 L) t :=
    fun t _ => ((hsnlo t).const_mul α).hasDerivWithinAt
  have hh' : ∀ t ∈ Icc 0 L,
      HasDerivWithinAt (fun t => α * clo t) (-(klo * (α * sn klo t))) (Icc 0 L) t := by
    intro t _
    have := ((hclo t).const_mul α).hasDerivWithinAt (s := Icc 0 L)
    convert this using 1; ring
  have lower : ∀ t ∈ Icc 0 L, α * sn khi t ≤ f t :=
    sturm_compare f f' (fun t => α * sn khi t) (fun t => α * chi t) K (fun _ => khi) α L hα
      hf hf' hg hg' hf0 (by simp [sn_zero]) hf'0 (by simp [hchi0])
      (fun t ht => (hK t ht).2)
      (fun t ht => mul_pos hα (sn_pos khi t ht.1 (fun hk => ht.2.trans_le (hL hk))))
  have upper : ∀ t ∈ Icc 0 L, f t ≤ α * sn klo t :=
    sturm_compare (fun t => α * sn klo t) (fun t => α * clo t) f f' (fun _ => klo) K α L hα
      hh hh' hf hf' (by simp [sn_zero]) hf0 (by simp [hclo0]) hf'0
      (fun t ht => (hK t ht).1)
      (fun t ht => lt_of_lt_of_le
        (mul_pos hα (sn_pos khi t ht.1 (fun hk => ht.2.trans_le (hL hk))))
        (lower t (Ioo_subset_Icc_self ht)))
  exact ⟨lower s hs, upper s hs⟩

/-- The upper bound reaches as far as the path's first conjugate point. If the curvature is at
least `klo` along `[0, L]` and the gap `f` stays positive on `(0, L)`, so no conjugate point comes
before `L`, then the gap never exceeds the least curved model's gap: `f(s) ≤ α sn_klo(s)`. -/
theorem jacobi_gap_le_model_gap_before_conjugate (K f f' : ℝ → ℝ) (α klo L : ℝ) (hα : 0 < α)
    (hf : ∀ s ∈ Icc 0 L, HasDerivWithinAt f (f' s) (Icc 0 L) s)
    (hf' : ∀ s ∈ Icc 0 L, HasDerivWithinAt f' (-(K s * f s)) (Icc 0 L) s)
    (hf0 : f 0 = 0) (hf'0 : f' 0 = α)
    (hK : ∀ s ∈ Icc 0 L, klo ≤ K s)
    (hpos : ∀ s ∈ Ioo 0 L, 0 < f s) :
    ∀ s ∈ Icc 0 L, f s ≤ α * sn klo s := by
  obtain ⟨clo, hclo0, hsnlo, hclo⟩ := sn_model klo
  have hh : ∀ t ∈ Icc 0 L, HasDerivWithinAt (fun t => α * sn klo t) (α * clo t) (Icc 0 L) t :=
    fun t _ => ((hsnlo t).const_mul α).hasDerivWithinAt
  have hh' : ∀ t ∈ Icc 0 L,
      HasDerivWithinAt (fun t => α * clo t) (-(klo * (α * sn klo t))) (Icc 0 L) t := by
    intro t _
    have := ((hclo t).const_mul α).hasDerivWithinAt (s := Icc 0 L)
    convert this using 1; ring
  exact sturm_compare (fun t => α * sn klo t) (fun t => α * clo t) f f' (fun _ => klo) K α L hα
    hh hh' hf hf' (by simp [sn_zero]) hf0 (by simp [hclo0]) hf'0 hK hpos

/-- On a sphere of radius `R` (curvature `K = 1/R²`) the model gap is `R sin(s/R)`, and the gap
`f(s) = α R sin(s/R)` solves the Jacobi equation `f'' + f/R² = 0` with `f(0) = 0`, `f'(0) = α`.
It returns to zero at `s = π R`, the opposite point, which is conjugate to the start. -/
theorem sphere_jacobi_field (R α : ℝ) (hR : 0 < R) :
    (∀ s, sn (1 / R ^ 2) s = R * Real.sin (s / R)) ∧
    (∀ s, HasDerivAt (fun t => α * R * Real.sin (t / R)) (α * Real.cos (s / R)) s) ∧
    (∀ s, HasDerivAt (fun t => α * Real.cos (t / R))
      (-((1 / R ^ 2) * (α * R * Real.sin (s / R)))) s) ∧
    α * R * Real.sin (0 / R) = 0 ∧ α * Real.cos (0 / R) = α ∧
    α * R * Real.sin (π * R / R) = 0 := by
  have hR0 : R ≠ 0 := hR.ne'
  refine ⟨fun s => ?_, fun s => ?_, fun s => ?_, by simp, by simp, ?_⟩
  · have hk : (0 : ℝ) < 1 / R ^ 2 := by positivity
    have hsq : Real.sqrt (1 / R ^ 2) = 1 / R := by
      rw [show (1 : ℝ) / R ^ 2 = (1 / R) ^ 2 by ring, Real.sqrt_sq (by positivity)]
    simp only [sn, hk, ite_true, hsq]
    rw [show 1 / R * s = s / R by ring]
    field_simp
  · have := (((hasDerivAt_id' s).div_const R).sin).const_mul (α * R)
    convert this using 1
    field_simp
  · have := (((hasDerivAt_id' s).div_const R).cos).const_mul α
    convert this using 1
    field_simp
  · rw [mul_div_assoc, div_self hR0, mul_one, Real.sin_pi, mul_zero]

#print axioms jacobi_gap_between_model_gaps
#print axioms jacobi_gap_le_model_gap_before_conjugate
#print axioms sphere_jacobi_field
