-- Passivity: a belt with a PI speed loop, joined to any friction curve whose chords from the set speed never slope downhill faster than a, returns to its set speed whenever the proportional gain beats a, and the band test reads in frequencies as a disk.
import Mathlib
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Algebra.Order.Field

open Filter Topology Set

theorem belt_energy_rate_aux
    (M Kp Ki a v₀ : ℝ) (F : ℝ → ℝ) (hM : 0 < M)
    (hband : ∀ e : ℝ, e * (F (v₀ + e) - F v₀) ≥ -a * e ^ 2)
    (e z : ℝ → ℝ) (t : ℝ)
    (he : HasDerivWithinAt e ((-Kp * e t - Ki * z t - (F (v₀ + e t) - F v₀)) / M) (Ici 0) t)
    (hz : HasDerivWithinAt z (e t) (Ici 0) t) :
    HasDerivWithinAt (fun s => 1 / 2 * M * e s ^ 2 + 1 / 2 * Ki * z s ^ 2)
        (-Kp * e t ^ 2 - e t * (F (v₀ + e t) - F v₀)) (Ici 0) t ∧
      -Kp * e t ^ 2 - e t * (F (v₀ + e t) - F v₀) ≤ -(Kp - a) * e t ^ 2 := by
  refine ⟨?_, by linarith [hband (e t)]⟩
  have h1 := ((he.pow 2).const_mul (1 / 2 * M)).add ((hz.pow 2).const_mul (1 / 2 * Ki))
  convert h1 using 1
  field_simp
  ring

#print axioms belt_energy_rate_aux

/-- A function whose one-sided derivative on `[0, ∞)` is nonpositive on a convex part `D`
of `[0, ∞)` is antitone on `D`. -/
lemma belt_antitoneOn_of_deriv {f f' : ℝ → ℝ} {D : Set ℝ} (hD : Convex ℝ D)
    (hDs : D ⊆ Ici 0) (h : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt f (f' t) (Ici 0) t)
    (h0 : ∀ t ∈ D, f' t ≤ 0) : AntitoneOn f D :=
  antitoneOn_of_hasDerivWithinAt_nonpos hD
    (fun t ht => (h t (hDs ht)).continuousWithinAt.mono hDs)
    (fun t ht => (h t (hDs (interior_subset ht))).mono (interior_subset.trans hDs))
    (fun t ht => h0 t (interior_subset ht))

#print axioms belt_antitoneOn_of_deriv

/-- Adding a linear term `k * x` adds `k` to the derivative. -/
lemma belt_hasDerivWithinAt_add_lin {f : ℝ → ℝ} {f' k t : ℝ} {s : Set ℝ}
    (h : HasDerivWithinAt f f' s t) :
    HasDerivWithinAt (fun x => f x + k * x) (f' + k) s t := by
  have h2 := (hasDerivWithinAt_id t s).const_mul k
  rw [mul_one] at h2
  exact h.add h2

#print axioms belt_hasDerivWithinAt_add_lin

/-- The band form of the passivity theorem (absolute stability) for the belt loop.
Take a belt of mass M > 0, integral gain K_i > 0, proportional gain K_p, a friction curve
F that depends only on the present speed, and a set speed v₀. Write the friction change as
φ(e) = F(v₀ + e) - F(v₀). If every chord of the friction curve from the set speed has slope
at least -a, that is e·φ(e) ≥ -a·e² for every e, and K_p > a, then every motion of
M e' = -K_p e - K_i z - φ(e), z' = e settles: the speed error e and its running total z
both tend to 0. -/
theorem belt_loop_settles_inside_band
    (M Kp Ki a v₀ : ℝ) (F : ℝ → ℝ) (hM : 0 < M) (hKi : 0 < Ki) (hF : Continuous F)
    (hband : ∀ e : ℝ, e * (F (v₀ + e) - F v₀) ≥ -a * e ^ 2) (hKp : Kp > a)
    (e z : ℝ → ℝ)
    (he : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt e
      ((-Kp * e t - Ki * z t - (F (v₀ + e t) - F v₀)) / M) (Ici 0) t)
    (hz : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt z (e t) (Ici 0) t) :
    Tendsto e atTop (𝓝 0) ∧ Tendsto z atTop (𝓝 0) := by
  have hE := fun t (ht : t ∈ Ici (0 : ℝ)) =>
    belt_energy_rate_aux M Kp Ki a v₀ F hM hband e z t (he t ht) (hz t ht)
  obtain ⟨φ, hφ⟩ : ∃ φ : ℝ → ℝ, ∀ x, φ x = F (v₀ + x) - F v₀ := ⟨_, fun _ => rfl⟩
  have hφc : Continuous φ := by
    have : φ = fun x => F (v₀ + x) - F v₀ := funext hφ
    rw [this]; fun_prop
  have hφ0 : φ 0 = 0 := by simp [hφ]
  simp only [← hφ] at he hband hE
  obtain ⟨V, hV⟩ : ∃ V : ℝ → ℝ, ∀ s, V s = 1 / 2 * M * e s ^ 2 + 1 / 2 * Ki * z s ^ 2 :=
    ⟨_, fun _ => rfl⟩
  have hVeq : (fun s => 1 / 2 * M * e s ^ 2 + 1 / 2 * Ki * z s ^ 2) = V := funext fun s => (hV s).symm
  rw [hVeq] at hE
  clear hVeq
  set c := Kp - a with hc
  have hcpos : 0 < c := by linarith
  have hVnn : ∀ s, 0 ≤ V s := fun s => by rw [hV]; positivity
  -- V is antitone on [0, ∞)
  have hVanti : AntitoneOn V (Ici 0) :=
    belt_antitoneOn_of_deriv (convex_Ici 0) subset_rfl (fun t ht => (hE t ht).1)
      (fun t ht => by nlinarith [(hE t ht).2, sq_nonneg (e t)])
  -- bounds on e and z
  set R := 2 * V 0 / M + 2 * V 0 / Ki + 1 with hR
  have hV0nn := hVnn 0
  have hR1 : 1 ≤ R := by
    have : 0 ≤ 2 * V 0 / M := by positivity
    have : 0 ≤ 2 * V 0 / Ki := by positivity
    linarith
  have hVle0 : ∀ t ∈ Ici (0 : ℝ), V t ≤ V 0 := fun t ht => hVanti (mem_Ici.mpr le_rfl) ht ht
  have he2 : ∀ t ∈ Ici (0 : ℝ), e t ^ 2 ≤ R := by
    intro t ht
    have h1 : e t ^ 2 ≤ 2 * V 0 / M := by
      rw [le_div_iff₀ hM]
      have := hVle0 t ht; rw [hV t] at this; nlinarith [sq_nonneg (z t)]
    have : 0 ≤ 2 * V 0 / Ki := by positivity
    linarith
  have hz2 : ∀ t ∈ Ici (0 : ℝ), z t ^ 2 ≤ R := by
    intro t ht
    have h1 : z t ^ 2 ≤ 2 * V 0 / Ki := by
      rw [le_div_iff₀ hKi]
      have := hVle0 t ht; rw [hV t] at this; nlinarith [sq_nonneg (e t)]
    have : 0 ≤ 2 * V 0 / M := by positivity
    linarith
  have heR : ∀ t ∈ Ici (0 : ℝ), |e t| ≤ R := fun t ht =>
    abs_le.mpr ⟨by nlinarith [he2 t ht, sq_nonneg (e t + 1)],
      by nlinarith [he2 t ht, sq_nonneg (e t - 1)]⟩
  have hzR : ∀ t ∈ Ici (0 : ℝ), |z t| ≤ R := fun t ht =>
    abs_le.mpr ⟨by nlinarith [hz2 t ht, sq_nonneg (z t + 1)],
      by nlinarith [hz2 t ht, sq_nonneg (z t - 1)]⟩
  obtain ⟨Φ, hΦ⟩ := (isCompact_Icc (a := -R) (b := R)).exists_bound_of_continuousOn
    hφc.continuousOn
  have hφR : ∀ t ∈ Ici (0 : ℝ), |φ (e t)| ≤ Φ := fun t ht => by
    have := hΦ (e t) (abs_le.mp (heR t ht))
    rwa [Real.norm_eq_abs] at this
  -- bound on the derivative of e
  set B := (|Kp| * R + Ki * R + Φ) / M + 1 with hB
  have hB1 : ∀ t ∈ Ici (0 : ℝ), |(-Kp * e t - Ki * z t - φ (e t)) / M| ≤ B - 1 := by
    intro t ht
    have h1 : |Kp * e t| ≤ |Kp| * R := by
      rw [abs_mul]; exact mul_le_mul_of_nonneg_left (heR t ht) (abs_nonneg _)
    have h2 : |Ki * z t| ≤ Ki * R := by
      rw [abs_mul, abs_of_pos hKi]; exact mul_le_mul_of_nonneg_left (hzR t ht) hKi.le
    have h3 := hφR t ht
    have hnum : |-Kp * e t - Ki * z t - φ (e t)| ≤ |Kp| * R + Ki * R + Φ := by
      have a1 := abs_le.mp h1; have a2 := abs_le.mp h2; have a3 := abs_le.mp h3
      apply abs_le.mpr; constructor <;> nlinarith
    rw [abs_div, abs_of_pos hM, hB, add_sub_cancel_right]
    exact div_le_div_of_nonneg_right hnum hM.le
  have hBpos : 0 < B := by
    have := hB1 0 (mem_Ici.mpr le_rfl)
    have := abs_nonneg ((-Kp * e 0 - Ki * z 0 - φ (e 0)) / M)
    linarith
  have hLip : ∀ t s, 0 ≤ t → t ≤ s → |e s - e t| ≤ B * (s - t) := by
    intro t s ht hts
    have hs : s ∈ Ici (0 : ℝ) := le_trans ht hts
    have A1 : AntitoneOn (fun x => e x + (-B) * x) (Ici 0) :=
      belt_antitoneOn_of_deriv (convex_Ici 0) subset_rfl
        (fun t ht => belt_hasDerivWithinAt_add_lin (he t ht))
        (fun t ht => by have := abs_le.mp (hB1 t ht); linarith)
    have A2 : AntitoneOn (fun x => -e x + (-B) * x) (Ici 0) :=
      belt_antitoneOn_of_deriv (convex_Ici 0) subset_rfl
        (fun t ht => belt_hasDerivWithinAt_add_lin (he t ht).neg)
        (fun t ht => by have := abs_le.mp (hB1 t ht); linarith)
    have h1 := A1 (show t ∈ Ici (0:ℝ) from ht) hs hts
    have h2 := A2 (show t ∈ Ici (0:ℝ) from ht) hs hts
    simp only at h1 h2
    apply abs_le.mpr; constructor <;> nlinarith
  -- the infimum of V
  have hbdd : BddBelow (V '' Ici 0) := ⟨0, by rintro _ ⟨t, -, rfl⟩; exact hVnn t⟩
  set L := sInf (V '' Ici 0) with hLdef
  have hL : ∀ t ∈ Ici (0 : ℝ), L ≤ V t := fun t ht => csInf_le hbdd ⟨t, ht, rfl⟩
  have hLapprox : ∀ δ > 0, ∃ T ∈ Ici (0 : ℝ), V T < L + δ := by
    intro δ hδ
    obtain ⟨_, ⟨T, hT, rfl⟩, hlt⟩ :=
      exists_lt_of_csInf_lt ((nonempty_Ici).image V) (by linarith : L < L + δ)
    exact ⟨T, hT, hlt⟩
  have hL0 : 0 ≤ L := le_csInf ((nonempty_Ici).image V) (by rintro _ ⟨t, -, rfl⟩; exact hVnn t)
  -- e tends to 0
  have heT : Tendsto e atTop (𝓝 0) := by
    rw [Metric.tendsto_atTop]
    intro ε hε
    set h := ε / (2 * B) with hh
    have hhpos : 0 < h := by positivity
    have hBh : B * h = ε / 2 := by rw [hh]; field_simp
    have hδ : 0 < c * (ε / 2) ^ 2 * h := by positivity
    obtain ⟨T, hT0, hTV⟩ := hLapprox _ hδ
    refine ⟨T, fun t ht => ?_⟩
    rw [Real.dist_eq, sub_zero]
    by_contra hcon
    replace hcon := not_lt.mp hcon
    have ht0 : (0 : ℝ) ≤ t := le_trans hT0 ht
    have hnear : ∀ s ∈ Icc t (t + h), (ε / 2) ^ 2 ≤ e s ^ 2 := by
      intro s hs
      have h1 := hLip t s ht0 hs.1
      have h2 : B * (s - t) ≤ B * h := mul_le_mul_of_nonneg_left (by linarith [hs.2]) hBpos.le
      have h3 : ε / 2 ≤ |e s| := by
        have := abs_sub_abs_le_abs_sub (e t) (e s)
        rw [abs_sub_comm] at this
        linarith
      have := pow_le_pow_left₀ (by positivity) h3 2
      rwa [sq_abs] at this
    have hanti : AntitoneOn (fun x => V x + (c * (ε / 2) ^ 2) * x) (Icc t (t + h)) :=
      belt_antitoneOn_of_deriv (convex_Icc _ _)
        (fun s hs => le_trans ht0 hs.1)
        (fun s hs => belt_hasDerivWithinAt_add_lin (hE s hs).1)
        (fun s hs => by
          have h1 := (hE s (le_trans ht0 hs.1)).2
          have h2 := mul_le_mul_of_nonneg_left (hnear s hs) hcpos.le
          nlinarith)
    have h1 := hanti (left_mem_Icc.mpr (by linarith)) (right_mem_Icc.mpr (by linarith))
      (by linarith)
    simp only at h1
    have h2 := hVanti (show T ∈ Ici (0:ℝ) from hT0) (show t ∈ Ici (0:ℝ) from ht0) ht
    have h3 := hL (t + h) (show (0:ℝ) ≤ t + h by linarith)
    nlinarith
  refine ⟨heT, ?_⟩
  rcases eq_or_lt_of_le hL0 with hL0 | hLpos
  · -- L = 0
    rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨T, hT0, hTV⟩ := hLapprox (Ki * ε ^ 2 / 2) (by positivity)
    refine ⟨T, fun t ht => ?_⟩
    rw [Real.dist_eq, sub_zero]
    have ht0 : (0 : ℝ) ≤ t := le_trans hT0 ht
    have h2 := hVanti (show T ∈ Ici (0:ℝ) from hT0) (show t ∈ Ici (0:ℝ) from ht0) ht
    rw [hV t] at h2
    have h3 : z t ^ 2 < ε ^ 2 := by
      by_contra hcon; replace hcon := not_lt.mp hcon
      nlinarith [sq_nonneg (e t), mul_le_mul_of_nonneg_left hcon hKi.le]
    exact abs_lt_of_sq_lt_sq h3 hε.le
  · exfalso
    set g : ℝ → ℝ := fun x => |Kp| * R * |x| + R * |φ x| + M * x ^ 2 with hg
    have hgc : Continuous g := by rw [hg]; fun_prop
    have hg0 : g 0 = 0 := by simp [hg, hφ0]
    have hgT : Tendsto (g ∘ e) atTop (𝓝 0) := by
      have := (hgc.tendsto 0).comp heT
      rwa [hg0] at this
    obtain ⟨T1, hT1⟩ := eventually_atTop.mp (hgT.eventually (gt_mem_nhds (by linarith : (0:ℝ) < L / 2)))
    set T := max T1 0 with hT
    have hT0 : (0 : ℝ) ≤ T := le_max_right _ _
    have hU : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt (fun s => M * e s * z s + L * s)
        (M * ((-Kp * e t - Ki * z t - φ (e t)) / M) * z t + M * e t * e t + L) (Ici 0) t :=
      fun t ht => belt_hasDerivWithinAt_add_lin (((he t ht).const_mul M).mul (hz t ht))
    have hanti : AntitoneOn (fun s => M * e s * z s + L * s) (Ici T) :=
      belt_antitoneOn_of_deriv (convex_Ici T) (fun s hs => le_trans hT0 hs) hU
        (fun t ht => by
          have ht0 : (0:ℝ) ≤ t := le_trans hT0 ht
          have hg1 : g (e t) < L / 2 := hT1 t (le_trans (le_max_left _ _) ht)
          simp only [hg] at hg1
          have hMM : M * ((-Kp * e t - Ki * z t - φ (e t)) / M) = -Kp * e t - Ki * z t - φ (e t) := by
            field_simp
          rw [hMM]
          have hLV := hL t ht0
          rw [hV t] at hLV
          have k1 : -Kp * e t * z t ≤ |Kp| * R * |e t| := by
            have : |Kp * e t * z t| ≤ |Kp| * R * |e t| := by
              rw [abs_mul, abs_mul]
              have := mul_le_mul_of_nonneg_left (hzR t ht0) (mul_nonneg (abs_nonneg Kp) (abs_nonneg (e t)))
              nlinarith
            have := (abs_le.mp this).1
            linarith
          have k2 : -(φ (e t) * z t) ≤ R * |φ (e t)| := by
            have : |φ (e t) * z t| ≤ R * |φ (e t)| := by
              rw [abs_mul]
              have := mul_le_mul_of_nonneg_left (hzR t ht0) (abs_nonneg (φ (e t)))
              linarith
            have := (abs_le.mp this).1
            linarith
          have k3 : 0 ≤ |Kp| * R * |e t| := by positivity
          have k4 : 0 ≤ R * |φ (e t)| := by positivity
          nlinarith)
    have hUbd : ∀ s ∈ Ici (0 : ℝ), |M * e s * z s| ≤ M * R * R := by
      intro s hs
      rw [abs_mul, abs_mul, abs_of_pos hM]
      have := mul_le_mul (heR s hs) (hzR s hs) (abs_nonneg _) (by linarith)
      have := mul_le_mul_of_nonneg_left this hM.le
      linarith
    set s := T + 2 * M * R * R / L + 1 with hs
    have hsT : T ≤ s := by
      have : 0 ≤ 2 * M * R * R / L := by positivity
      linarith
    have h1 := hanti ((mem_Ici.mpr le_rfl)) (show s ∈ Ici T from hsT) hsT
    simp only at h1
    have b1 := abs_le.mp (hUbd T hT0)
    have b2 := abs_le.mp (hUbd s (le_trans hT0 hsT))
    have : L * (s - T) = 2 * M * R * R + L := by
      rw [hs]; field_simp; ring
    have : L * s - L * T = 2 * M * R * R + L := by rw [← mul_sub]; exact this
    linarith

/-- Steps 1 to 3: along the same loop, the stored energy V = ½ M e² + ½ K_i z² changes at
the rate V' = -K_p e² - e·φ(e), and under the band e·φ(e) ≥ -a·e² this rate is at most
-(K_p - a) e². -/
theorem belt_loop_energy_rate
    (M Kp Ki a v₀ : ℝ) (F : ℝ → ℝ) (hM : 0 < M)
    (hband : ∀ e : ℝ, e * (F (v₀ + e) - F v₀) ≥ -a * e ^ 2)
    (e z : ℝ → ℝ) (t : ℝ)
    (he : HasDerivWithinAt e ((-Kp * e t - Ki * z t - (F (v₀ + e t) - F v₀)) / M) (Ici 0) t)
    (hz : HasDerivWithinAt z (e t) (Ici 0) t) :
    HasDerivWithinAt (fun s => 1 / 2 * M * e s ^ 2 + 1 / 2 * Ki * z s ^ 2)
        (-Kp * e t ^ 2 - e t * (F (v₀ + e t) - F v₀)) (Ici 0) t ∧
      -Kp * e t ^ 2 - e t * (F (v₀ + e t) - F v₀) ≤ -(Kp - a) * e t ^ 2 := by
  exact belt_energy_rate_aux M Kp Ki a v₀ F hM hband e z t he hz

/-- Step 4, the circle criterion's disk: for a band floor a > 0 and any complex value G,
the transformed value G / (1 - a G) has non-negative real part exactly when G lies in the
disk whose diameter runs from 0 to 1/a (centre 1/(2a), radius 1/(2a)). -/
theorem band_is_disk (a : ℝ) (ha : 0 < a) (G : ℂ) :
    0 ≤ (G / (1 - a * G)).re ↔ ‖G - (1 / (2 * a) : ℝ)‖ ≤ 1 / (2 * a) := by
  have hr : (0:ℝ) ≤ 1 / (2 * a) := by positivity
  rw [← sq_le_sq₀ (norm_nonneg _) hr, Complex.sq_norm, Complex.normSq_apply, Complex.div_re,
    Complex.normSq_apply]
  simp only [Complex.sub_re, Complex.sub_im, Complex.ofReal_re, Complex.ofReal_im, Complex.one_re,
    Complex.one_im, Complex.mul_re, Complex.mul_im, sub_zero, zero_mul, zero_sub, add_zero]
  set x := G.re
  set y := G.im
  have key : (x - 1 / (2 * a)) * (x - 1 / (2 * a)) + y * y ≤ (1 / (2 * a)) ^ 2 ↔ a * (x^2 + y^2) ≤ x := by
    have : (x - 1 / (2 * a)) * (x - 1 / (2 * a)) + y * y - (1 / (2 * a)) ^ 2 = (a * (x^2 + y^2) - x) / a := by
      field_simp; ring
    constructor
    · intro h
      have h2 : (a * (x^2 + y^2) - x) / a ≤ 0 := by linarith
      rw [div_nonpos_iff] at h2
      rcases h2 with ⟨_, h3⟩ | ⟨h3, _⟩ <;> linarith
    · intro h
      have h2 : (a * (x^2 + y^2) - x) / a ≤ 0 := div_nonpos_of_nonpos_of_nonneg (by linarith) ha.le
      linarith
  rw [key]
  set N := (1 - a * x) * (1 - a * x) + -(a * y) * -(a * y) with hN
  rw [← add_div]
  rcases eq_or_lt_of_le (show 0 ≤ N by nlinarith [mul_self_nonneg (1 - a * x), mul_self_nonneg (a * y)]) with h0 | hpos
  · rw [← h0]
    simp only [div_zero, le_refl, true_iff]
    have hy : a * y = 0 := by nlinarith [sq_nonneg (1 - a * x), sq_nonneg (a * y)]
    have hx : 1 - a * x = 0 := by nlinarith [sq_nonneg (1 - a * x), sq_nonneg (a * y)]
    have hy0 : y = 0 := by
      rcases mul_eq_zero.mp hy with h | h
      · linarith
      · exact h
    rw [hy0]
    have hax : a * x = 1 := by linarith
    have : a * (x ^ 2 + 0 ^ 2) = x * (a * x) := by ring
    rw [this, hax, mul_one]
  · rw [le_div_iff₀ hpos, zero_mul]
    constructor <;> intro h <;> nlinarith

-- The card's whole-number plant: M = 500 kg, K_p = 2000 N·s/m, K_i = 4000 N/m.
-- Natural frequency squared: ω_n² = K_i / M = 8, so ω_n = 2√2 ≈ 2.8284 rad/s.
example : (4000 : ℚ) / 500 = 8 := by norm_num
-- Damping ratio squared: ζ² = K_p² / (4 K_i M) = 1/2, so ζ = 1/√2 ≈ 0.7071.
example : (2000 : ℚ) ^ 2 / (4 * 4000 * 500) = 1 / 2 := by norm_num
-- Stored energy at the kick e = -3/100 m/s, z = 0: ½ × 500 × (3/100)² = 9/40 J (0.2250 J).
example : (1 / 2 : ℚ) * 500 * (-3 / 100) ^ 2 + 1 / 2 * 4000 * 0 ^ 2 = 9 / 40 := by norm_num
-- Proportional braking at the kick: -2000 × (3/100)² = -9/5 W (-1.8000 W).
example : -(2000 : ℚ) * (-3 / 100) ^ 2 = -9 / 5 := by norm_num

#print axioms belt_loop_settles_inside_band
#print axioms belt_loop_energy_rate
#print axioms band_is_disk
