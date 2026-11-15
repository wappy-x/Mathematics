-- Entropy conditions: for a downward-bending flux, a jump survives a small viscosity only if it passes the Lax test, the Lax test is the same as density rising through the jump, and for the Greenshields traffic flux a tanh-shaped smoothed jump then exists.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Convex.Deriv
import Mathlib.Analysis.SpecialFunctions.Artanh
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Filter Topology

/-- The Greenshields traffic flux `q(ρ) = v_max ρ (1 − ρ/ρ_max)`: cars per unit time past a point. -/
noncomputable def greenshields (vmax ρmax ρ : ℝ) : ℝ := vmax * ρ * (1 - ρ / ρmax)

lemma lax_helper
    (q : ℝ → ℝ) (hq : Differentiable ℝ q) (hconc : StrictConcaveOn ℝ Set.univ q)
    (ρL ρR s : ℝ) (hLR : ρL ≠ ρR) (hs : s = (q ρR - q ρL) / (ρR - ρL)) :
    (deriv q ρL > s ∧ s > deriv q ρR) ↔ ρL < ρR := by
  have hs' : s = slope q ρL ρR := by rw [hs, slope_def_field]
  constructor
  · rintro ⟨h1, _⟩
    by_contra h
    have hlt : ρR < ρL := lt_of_le_of_ne (not_lt.mp h) (Ne.symm hLR)
    have := hconc.deriv_lt_slope (Set.mem_univ _) (Set.mem_univ _) hlt (hq ρL)
    rw [slope_comm, ← hs'] at this
    linarith
  · intro h
    refine ⟨?_, ?_⟩
    · have := hconc.slope_lt_deriv (Set.mem_univ _) (Set.mem_univ _) h (hq ρL)
      rw [← hs'] at this; exact this
    · have := hconc.deriv_lt_slope (Set.mem_univ _) (Set.mem_univ _) h (hq ρR)
      rw [← hs'] at this; exact this

lemma deriv_limit_zero_atBot (R : ℝ → ℝ) (hR : Differentiable ℝ R) (a L : ℝ)
    (h1 : Tendsto R atBot (𝓝 a)) (h2 : Tendsto (deriv R) atBot (𝓝 L)) : L = 0 := by
  have hex : ∀ x : ℝ, ∃ c ∈ Set.Ioo (x - 1) x, deriv R c = (R x - R (x - 1)) / (x - (x - 1)) :=
    fun x => exists_deriv_eq_slope R (by linarith) hR.continuous.continuousOn
      (fun y _ => (hR y).differentiableWithinAt)
  choose c hc hc' using hex
  have hcbot : Tendsto c atBot atBot := tendsto_atBot_mono (fun x => (hc x).2.le) tendsto_id
  have e1 : Tendsto (fun x => deriv R (c x)) atBot (𝓝 L) := h2.comp hcbot
  have hsh : Tendsto (fun x : ℝ => x - 1) atBot atBot := by
    simpa [sub_eq_add_neg] using tendsto_atBot_add_const_right atBot (-1 : ℝ) tendsto_id
  have e2 : Tendsto (fun x => deriv R (c x)) atBot (𝓝 0) := by
    have : Tendsto (fun x => R x - R (x - 1)) atBot (𝓝 (a - a)) := h1.sub (h1.comp hsh)
    rw [sub_self] at this
    refine this.congr (fun x => ?_)
    rw [hc' x]; ring
  exact tendsto_nhds_unique e1 e2

lemma travel_terms (P P1 P2 q : ℝ → ℝ) (hP : ∀ ξ, HasDerivAt P (P1 ξ) ξ)
    (hP1 : ∀ ξ, HasDerivAt P1 (P2 ξ) ξ) (hq : Differentiable ℝ q) (s ε x t : ℝ) :
    deriv (fun τ => P (x - s * τ)) t + deriv (fun y => q (P (y - s * t))) x
        - ε * deriv (fun y => deriv (fun z => P (z - s * t)) y) x
      = -s * P1 (x - s * t) + deriv q (P (x - s * t)) * P1 (x - s * t)
        - ε * P2 (x - s * t) := by
  have h : HasDerivAt (fun τ => x - s * τ) (-s) t := by
    simpa using ((hasDerivAt_id t).const_mul s).const_sub x
  have e1 : HasDerivAt (fun τ => P (x - s * τ)) (P1 (x - s * t) * (-s)) t :=
    (hP (x - s * t)).comp t h
  have e2 : HasDerivAt (fun y => q (P (y - s * t))) (deriv q (P (x - s * t)) * P1 (x - s * t)) x :=
    (hq _).hasDerivAt.comp x ((hP (x - s * t)).comp_sub_const x (s * t))
  have e3 : (fun y => deriv (fun z => P (z - s * t)) y) = fun y => P1 (y - s * t) :=
    funext fun y => ((hP (y - s * t)).comp_sub_const y (s * t)).deriv
  have e4 : HasDerivAt (fun y => P1 (y - s * t)) (P2 (x - s * t)) x :=
    (hP1 _).comp_sub_const x (s * t)
  rw [e1.deriv, e2.deriv, e3, e4.deriv]; ring

lemma hasDerivAt_tanh' (y : ℝ) : HasDerivAt Real.tanh (1 - Real.tanh y ^ 2) y := by
  have hc : Real.cosh y ≠ 0 := (Real.cosh_pos y).ne'
  have h := (Real.hasDerivAt_sinh y).div (Real.hasDerivAt_cosh y) hc
  have hf : Real.tanh = fun x => Real.sinh x / Real.cosh x := funext fun x => Real.tanh_eq_sinh_div_cosh x
  have h' : HasDerivAt (fun x => Real.sinh x / Real.cosh x) (1 - (Real.sinh y / Real.cosh y) ^ 2) y := by
    refine h.congr_deriv ?_
    field_simp
  rw [Real.tanh_eq_sinh_div_cosh y, hf]
  exact h'

lemma tanh_eq_one_sub (x : ℝ) : Real.tanh x = 1 - 2 / (Real.exp (2 * x) + 1) := by
  have h2 : Real.exp (2 * x) = Real.exp x * Real.exp x := by rw [← Real.exp_add]; ring_nf
  have hp := Real.exp_pos x
  rw [Real.tanh_eq, Real.exp_neg, h2]
  field_simp
  ring

lemma tendsto_tanh_atTop' : Tendsto Real.tanh atTop (𝓝 1) := by
  have h1 : Tendsto (fun x : ℝ => Real.exp (2 * x) + 1) atTop atTop :=
    tendsto_atTop_add_const_right _ 1
      (Real.tendsto_exp_atTop.comp (tendsto_id.const_mul_atTop two_pos))
  have h2 : Tendsto (fun x : ℝ => (2 : ℝ) / (Real.exp (2 * x) + 1)) atTop (𝓝 0) :=
    tendsto_const_nhds.div_atTop h1
  have h3 := (tendsto_const_nhds (x := (1 : ℝ))).sub h2
  rw [sub_zero] at h3
  exact h3.congr (fun x => (tanh_eq_one_sub x).symm)

lemma tendsto_tanh_atBot' : Tendsto Real.tanh atBot (𝓝 (-1)) := by
  have h := (tendsto_tanh_atTop'.comp tendsto_neg_atBot_atTop).neg
  refine h.congr (fun x => ?_)
  simp [Real.tanh_neg]

lemma hasDerivAt_greenshields (vmax ρmax ρ : ℝ) (hm : ρmax ≠ 0) :
    HasDerivAt (greenshields vmax ρmax) (vmax * (1 - 2 * ρ / ρmax)) ρ := by
  have h := ((hasDerivAt_id ρ).const_mul vmax).mul (((hasDerivAt_id ρ).div_const ρmax).const_sub 1)
  have hf : greenshields vmax ρmax = fun y => vmax * id y * (1 - id y / ρmax) := rfl
  rw [hf]
  convert h using 1
  simp only [id]
  field_simp
  ring

/-- A smoothed jump exists only if the Lax condition holds.
Let the flux `q` be differentiable and bend downward (strictly concave), let the viscosity `ε`
be positive, and let a jump from `ρL` (behind) to `ρR` (ahead), `ρL ≠ ρR`, move at the speed
`s` given by the jump rule. If a smooth profile `R` makes `ρ(x, t) = R(x − s t)` a solution of the
smoothed equation `ρ_t + q(ρ)_x = ε ρ_xx` with `R → ρL` far behind and `R → ρR` far ahead,
then the wave speed behind the jump is faster than the jump and the wave speed ahead is slower:
`q'(ρL) > s > q'(ρR)`. -/
theorem viscous_profile_only_if_lax
    (q : ℝ → ℝ) (hq : Differentiable ℝ q) (hconc : StrictConcaveOn ℝ Set.univ q)
    (ε : ℝ) (hε : 0 < ε) (ρL ρR s : ℝ) (hLR : ρL ≠ ρR)
    (hs : s = (q ρR - q ρL) / (ρR - ρL))
    (R : ℝ → ℝ) (hR : ContDiff ℝ 2 R)
    (hPDE : ∀ x t : ℝ,
      deriv (fun τ => R (x - s * τ)) t + deriv (fun y => q (R (y - s * t))) x
        = ε * deriv (fun y => deriv (fun z => R (z - s * t)) y) x)
    (hbehind : Tendsto R atBot (𝓝 ρL)) (hahead : Tendsto R atTop (𝓝 ρR)) :
    deriv q ρL > s ∧ s > deriv q ρR := by
  have hRd : Differentiable ℝ R := hR.differentiable (by norm_num)
  have hR'd : Differentiable ℝ (deriv R) := hR.differentiable_deriv_two
  have hode : ∀ x, -s * deriv R x + deriv q (R x) * deriv R x - ε * deriv (deriv R) x = 0 := by
    intro x
    have h1 := travel_terms R (deriv R) (deriv (deriv R)) q (fun ξ => (hRd ξ).hasDerivAt)
      (fun ξ => (hR'd ξ).hasDerivAt) hq s ε x 0
    have h2 := hPDE x 0
    simp only [mul_zero, sub_zero] at h1 h2
    linarith
  -- first integral
  set h : ℝ → ℝ := fun ξ => ε * deriv R ξ - q (R ξ) + s * R ξ with hh
  have hhd : ∀ ξ, HasDerivAt h (ε * deriv (deriv R) ξ - deriv q (R ξ) * deriv R ξ
      + s * deriv R ξ) ξ := by
    intro ξ
    exact ((((hR'd ξ).hasDerivAt.const_mul ε).sub
      ((hq (R ξ)).hasDerivAt.comp ξ (hRd ξ).hasDerivAt)).add
      ((hRd ξ).hasDerivAt.const_mul s))
  have hconst : ∀ ξ, h ξ = h 0 := by
    intro ξ
    refine is_const_of_deriv_eq_zero (fun y => (hhd y).differentiableAt) (fun y => ?_) ξ 0
    rw [(hhd y).deriv]; linarith [hode y]
  set K := h 0 with hK
  have hfirst : ∀ ξ, deriv R ξ = (q (R ξ) - s * R ξ + K) / ε := by
    intro ξ
    have := hconst ξ
    simp only [hh] at this
    field_simp
    linarith
  have hlim : Tendsto (deriv R) atBot (𝓝 ((q ρL - s * ρL + K) / ε)) := by
    have := ((((hq.continuous.tendsto ρL).comp hbehind).sub (hbehind.const_mul s)).add_const K).div_const ε
    exact this.congr (fun ξ => (hfirst ξ).symm)
  have hL0 := deriv_limit_zero_atBot R hRd ρL _ hbehind hlim
  have hKv : K = s * ρL - q ρL := by
    rw [div_eq_zero_iff] at hL0
    rcases hL0 with h0 | h0
    · linarith
    · exact absurd h0 hε.ne'
  -- the reduced flux
  set f : ℝ → ℝ := fun r => q r - s * r - (q ρL - s * ρL) with hf
  have hfc : Continuous f := by
    exact (hq.continuous.sub (continuous_const.mul continuous_id)).sub continuous_const
  have hRf : ∀ ξ, ε * deriv R ξ = f (R ξ) := by
    intro ξ; rw [hfirst ξ, hKv]; simp only [hf]; field_simp; ring
  have hρ : ρL < ρR := by
    by_contra hnot
    have hlt : ρR < ρL := lt_of_le_of_ne (not_lt.mp hnot) (Ne.symm hLR)
    have hdiff : ρL - ρR ≠ 0 := sub_ne_zero.mpr hLR
    have hfpos : ∀ x ∈ Set.Ioo ρR ρL, 0 < f x := by
      rintro x ⟨hx1, hx2⟩
      have hd : 0 < ρL - ρR := by linarith
      have key : ((ρL - x) / (ρL - ρR)) • q ρR + ((x - ρR) / (ρL - ρR)) • q ρL
          < q (((ρL - x) / (ρL - ρR)) • ρR + ((x - ρR) / (ρL - ρR)) • ρL) :=
        hconc.2 (Set.mem_univ ρR) (Set.mem_univ ρL) (Ne.symm hLR)
          (div_pos (by linarith) hd) (div_pos (by linarith) hd) (by field_simp; ring)
      have hx : ((ρL - x) / (ρL - ρR)) • ρR + ((x - ρR) / (ρL - ρR)) • ρL = x := by
        simp only [smul_eq_mul]; field_simp; ring
      rw [hx] at key
      simp only [smul_eq_mul] at key
      simp only [hf]
      have hs2 : s * (ρL - ρR) = q ρL - q ρR := by
        rw [hs]; have : ρR - ρL ≠ 0 := sub_ne_zero.mpr (Ne.symm hLR)
        field_simp; ring
      have e : (ρL - x) / (ρL - ρR) * q ρR + (x - ρR) / (ρL - ρR) * q ρL
          = q ρL - s * (ρL - x) := by
        field_simp
        linear_combination (ρL - x) * hs2
      linarith
    set F : ℝ → ℝ := fun u => ∫ t in ρR..u, f t with hF
    have hFd : ∀ u, HasDerivAt F (f u) u := fun u => (hfc.integral_hasStrictDerivAt ρR u).hasDerivAt
    have hFc : Continuous F := continuous_iff_continuousAt.2 fun u => (hFd u).continuousAt
    have hGd : ∀ ξ, HasDerivAt (fun ξ => F (R ξ)) (f (R ξ) * deriv R ξ) ξ :=
      fun ξ => (hFd (R ξ)).comp ξ (hRd ξ).hasDerivAt
    have hGmono : Monotone (fun ξ => F (R ξ)) := by
      refine monotone_of_deriv_nonneg (fun ξ => (hGd ξ).differentiableAt) (fun ξ => ?_)
      rw [(hGd ξ).deriv, ← hRf ξ]
      have := sq_nonneg (deriv R ξ)
      nlinarith
    have hbot : Tendsto (fun ξ => F (R ξ)) atBot (𝓝 (F ρL)) := (hFc.tendsto ρL).comp hbehind
    have htop : Tendsto (fun ξ => F (R ξ)) atTop (𝓝 (F ρR)) := (hFc.tendsto ρR).comp hahead
    have i1 := hGmono.le_of_tendsto hbot 0
    have i2 := hGmono.ge_of_tendsto htop 0
    have hFR : F ρR = 0 := by simp [hF]
    have hFL : 0 < F ρL :=
      intervalIntegral.intervalIntegral_pos_of_pos_on (hfc.intervalIntegrable _ _) hfpos hlt
    linarith
  exact (lax_helper q hq hconc ρL ρR s hLR hs).2 hρ

/-- For a downward-bending flux, the Lax condition `q'(ρL) > s > q'(ρR)`, with `s` the jump-rule
speed, holds exactly when density rises through the jump: `ρL < ρR`. -/
theorem lax_iff_density_rises
    (q : ℝ → ℝ) (hq : Differentiable ℝ q) (hconc : StrictConcaveOn ℝ Set.univ q)
    (ρL ρR s : ℝ) (hLR : ρL ≠ ρR) (hs : s = (q ρR - q ρL) / (ρR - ρL)) :
    (deriv q ρL > s ∧ s > deriv q ρR) ↔ ρL < ρR := by
  exact lax_helper q hq hconc ρL ρR s hLR hs

/-- For the Greenshields flux, every jump that passes the Lax test has a smoothed version:
`R(ξ) = (ρL + ρR)/2 + (ρR − ρL)/2 · tanh(ξ / w)` with thickness `w = 4ε / (q'(ρL) − q'(ρR)) > 0`
makes `ρ(x, t) = R(x − s t)` solve `ρ_t + q(ρ)_x = ε ρ_xx`, and runs from `ρL` far behind to
`ρR` far ahead. -/
theorem greenshields_tanh_profile
    (vmax ρmax ε : ℝ) (hv : 0 < vmax) (hm : 0 < ρmax) (hε : 0 < ε)
    (ρL ρR s : ℝ) (hLR : ρL ≠ ρR)
    (hs : s = (greenshields vmax ρmax ρR - greenshields vmax ρmax ρL) / (ρR - ρL))
    (hLax : deriv (greenshields vmax ρmax) ρL > s ∧ s > deriv (greenshields vmax ρmax) ρR) :
    let w := 4 * ε / (deriv (greenshields vmax ρmax) ρL - deriv (greenshields vmax ρmax) ρR)
    let R : ℝ → ℝ := fun ξ => (ρL + ρR) / 2 + (ρR - ρL) / 2 * Real.tanh (ξ / w)
    0 < w ∧
    (∀ x t : ℝ,
      deriv (fun τ => R (x - s * τ)) t
          + deriv (fun y => greenshields vmax ρmax (R (y - s * t))) x
        = ε * deriv (fun y => deriv (fun z => R (z - s * t)) y) x) ∧
    Tendsto R atBot (𝓝 ρL) ∧ Tendsto R atTop (𝓝 ρR) := by
  intro w R
  have hgd : ∀ ρ, deriv (greenshields vmax ρmax) ρ = vmax * (1 - 2 * ρ / ρmax) :=
    fun ρ => (hasDerivAt_greenshields vmax ρmax ρ hm.ne').deriv
  have hD : deriv (greenshields vmax ρmax) ρL - deriv (greenshields vmax ρmax) ρR
      = 2 * vmax * (ρR - ρL) / ρmax := by
    rw [hgd, hgd]; field_simp; ring
  have hDpos : 0 < 2 * vmax * (ρR - ρL) / ρmax := by rw [← hD]; linarith [hLax.1, hLax.2]
  have hρ : ρL < ρR := by
    by_contra hn
    have : 2 * vmax * (ρR - ρL) / ρmax ≤ 0 :=
      div_nonpos_of_nonpos_of_nonneg (by nlinarith) hm.le
    linarith
  have hw : w = 2 * ε * ρmax / (vmax * (ρR - ρL)) := by
    simp only [w]; rw [hD]
    have : ρR - ρL ≠ 0 := by linarith
    field_simp; ring
  have hwpos : 0 < w := by rw [hw]; apply div_pos <;> nlinarith
  have hwne : w ≠ 0 := hwpos.ne'
  have hsv : s = vmax * (1 - (ρL + ρR) / ρmax) := by
    rw [hs]; simp only [greenshields]
    have : ρR - ρL ≠ 0 := by linarith
    field_simp; ring
  set m := (ρL + ρR) / 2 with hmdef
  set a := (ρR - ρL) / 2 with hadef
  have hRdef : R = fun ξ => m + a * Real.tanh (ξ / w) := rfl
  set R1 : ℝ → ℝ := fun ξ => a / w * (1 - Real.tanh (ξ / w) ^ 2) with hR1
  set R2 : ℝ → ℝ := fun ξ => a / w * (-(2 * Real.tanh (ξ / w) * ((1 - Real.tanh (ξ / w) ^ 2) / w)))
    with hR2
  have hRD : ∀ ξ, HasDerivAt R (R1 ξ) ξ := by
    intro ξ
    have h := (((hasDerivAt_tanh' (ξ / w)).comp ξ ((hasDerivAt_id ξ).div_const w)).const_mul a).const_add m
    refine h.congr_deriv ?_
    simp only [hR1]; field_simp
  have hR1D : ∀ ξ, HasDerivAt R1 (R2 ξ) ξ := by
    intro ξ
    have ht := (hasDerivAt_tanh' (ξ / w)).comp ξ ((hasDerivAt_id ξ).div_const w)
    have h := (((ht.pow 2).const_sub 1).const_mul (a / w))
    refine h.congr_deriv ?_
    simp only [hR2, id, Function.comp_apply]
    norm_num only [Nat.cast_ofNat, pow_one]
    ring
  refine ⟨hwpos, ?_, ?_, ?_⟩
  · intro x t
    have h1 := travel_terms R R1 R2 (greenshields vmax ρmax) hRD hR1D
      (fun y => (hasDerivAt_greenshields vmax ρmax y hm.ne').differentiableAt) s ε x t
    rw [hgd] at h1
    have key : -s * R1 (x - s * t) + vmax * (1 - 2 * R (x - s * t) / ρmax) * R1 (x - s * t)
        - ε * R2 (x - s * t) = 0 := by
      have hε' : ε = w * vmax * a / ρmax := by
        rw [hw, hadef]; field_simp
      simp only [hR1, hR2, hRdef, hsv, hε', hmdef, hadef]
      field_simp
      ring
    linarith
  · have h1 : Tendsto (fun ξ : ℝ => ξ / w) atBot atBot := tendsto_id.atBot_div_const hwpos
    have h2 := ((tendsto_tanh_atBot'.comp h1).const_mul a).const_add m
    have e : m + a * (-1) = ρL := by simp only [hmdef, hadef]; ring
    rw [← e]
    exact h2
  · have h1 : Tendsto (fun ξ : ℝ => ξ / w) atTop atTop := tendsto_id.atTop_div_const hwpos
    have h2 := ((tendsto_tanh_atTop'.comp h1).const_mul a).const_add m
    have e : m + a * (1) = ρR := by simp only [hmdef, hadef]; ring
    rw [← e]
    exact h2

/- Worked numbers from the card. Speeds in km/h and densities in cars/km for the fluxes
(top speed 90 km/h, jam density 150 cars/km); wave speeds in m/s (top speed 25 m/s). -/

-- Green light: no flux in the queue or on the empty road, so rival A's jump speed is 0.
example : greenshields 90 150 150 = 0 ∧ greenshields 90 150 0 = 0 := by
  norm_num [greenshields]
example : ((0 : ℝ) - 0) / (0 - 150) = 0 := by norm_num

-- Wave speeds q'(ρ) = 25 (1 − 2ρ/150): −25 m/s in the queue, +25 m/s ahead; Lax rejects rival A.
example : (25 : ℝ) * (1 - 2 * 150 / 150) = -25 ∧ (25 : ℝ) * (1 - 2 * 0 / 150) = 25 := by norm_num
example : ¬ ((-25 : ℝ) > 0 ∧ (0 : ℝ) > 25) := by norm_num

-- The fan: 75 cars/km and 3,375 cars/h at the light, so 3,375 × 60/3,600 = 225/4 cars cross in 60 s.
example : (150 : ℝ) / 2 * (1 - 0) = 75 := by norm_num
example : greenshields 90 150 75 = 3375 := by norm_num [greenshields]
example : (3375 : ℝ) * 60 / 3600 = 225 / 4 := by norm_num

-- Fan edges at ±25 × 60 = ±1,500 m; the car 300 m back has 45 cars ahead and starts at 12 s.
example : (25 : ℝ) * 60 = 1500 ∧ (300 : ℝ) * 150 / 1000 = 45 ∧ (300 : ℝ) / 25 = 12 := by norm_num

-- Red light: arrivals at 30 cars/km carry 2,160 cars/h; the jump moves at −18 km/h = −5 m/s.
example : greenshields 90 150 30 = 2160 := by norm_num [greenshields]
example : ((0 : ℝ) - 2160) / (150 - 30) = -18 ∧ (-18 : ℝ) * 1000 / 3600 = -5 := by norm_num

-- Red light Lax test: 25 (1 − 0.4) = 15 > −5 > −25, so the jump is allowed.
example : (25 : ℝ) * (1 - 2 * 30 / 150) = 15 ∧ (15 : ℝ) > -5 ∧ (-5 : ℝ) > -25 := by norm_num

-- Car speeds in place of wave speeds: 20 > −5 > 0 is false, so that mistake rejects the real queue.
example : (25 : ℝ) * (1 - 30 / 150) = 20 ∧ ¬ ((20 : ℝ) > -5 ∧ (-5 : ℝ) > 0) := by norm_num

-- Entropy production with η = ρ²/2, ψ(ρ) = 25 (ρ²/2 − 2ρ³/(3 · 3/20)), in cars/m and m/s:
-- rival A scores +3/32 (fails), the red-light queue scores −6/125 (passes).
example :
    let ψ : ℚ → ℚ := fun r => 25 * (r ^ 2 / 2 - 2 * r ^ 3 / (3 * (3 / 20)))
    (ψ 0 - ψ (3 / 20)) - 0 * ((0 : ℚ) ^ 2 / 2 - (3 / 20) ^ 2 / 2) = 3 / 32 := by
  norm_num
example :
    let ψ : ℚ → ℚ := fun r => 25 * (r ^ 2 / 2 - 2 * r ^ 3 / (3 * (3 / 20)))
    (ψ (3 / 20) - ψ (3 / 100)) - (-5) * ((3 / 20 : ℚ) ^ 2 / 2 - (3 / 100) ^ 2 / 2) = -6 / 125 := by
  norm_num

-- Red-light smoothed jump thickness 4ε/(15 − (−25)): 2 m at ε = 20 m²/s.
example : (4 : ℝ) * 20 / (15 - (-25)) = 2 := by norm_num

#print axioms lax_helper
#print axioms deriv_limit_zero_atBot
#print axioms travel_terms
#print axioms hasDerivAt_tanh'
#print axioms tanh_eq_one_sub
#print axioms tendsto_tanh_atTop'
#print axioms tendsto_tanh_atBot'
#print axioms hasDerivAt_greenshields
#print axioms viscous_profile_only_if_lax
#print axioms lax_iff_density_rises
#print axioms greenshields_tanh_profile
