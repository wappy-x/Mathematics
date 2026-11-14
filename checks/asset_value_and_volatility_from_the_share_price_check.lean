-- Backing out the unobservable: in Merton's model every positive equity value and positive equity volatility come from exactly one positive pair of asset value and asset volatility, and the equity always swings harder than the assets.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Gaussian.PoissonSummation

open MeasureTheory ProbabilityTheory Real

/-! The model (Merton, as on the card): `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area
under the standard bell curve to the left of `x`, and `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`,
its height. The firm owes one zero-coupon debt of face `B`, due in `T` years; `r` is the riskless
rate, so the debt's face discounted to today is `B e^(-rT)`. For asset value `V` and asset
volatility `σ`:
`d1 = (ln (V / (B e^(-rT))) + σ² T / 2) / (σ √T)`, `d2 = d1 - σ √T`, and the equity is the call
`E = V N(d1) - B e^(-rT) N(d2)`. The volatility equation is `σ_E E = N(d1) σ V`. -/

namespace AssetsFromShares

/-- How far the assets sit above the discounted debt, in units of `σ √T`, plus half a unit. -/
noncomputable def d1 (V σ B r T : ℝ) : ℝ :=
  (log (V / (B * exp (-(r * T)))) + σ ^ 2 * T / 2) / (σ * √T)

/-- `d2 = d1 - σ √T`. -/
noncomputable def d2 (V σ B r T : ℝ) : ℝ := d1 V σ B r T - σ * √T

/-- Merton's price of the equity: a call on the assets `V` struck at the debt's face `B`. -/
noncomputable def equity (V σ B r T : ℝ) : ℝ :=
  V * cdf (gaussianReal 0 1) (d1 V σ B r T) -
    B * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V σ B r T)

section Helpers

open Filter Topology Set

lemma phi_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma phi_pos (x : ℝ) : 0 < gaussianPDFReal 0 1 x := gaussianPDFReal_pos 0 1 x one_ne_zero

lemma phi_cont : Continuous (gaussianPDFReal 0 1) := by
  have : gaussianPDFReal 0 1 = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext phi_eq
  rw [this]; fun_prop

lemma phi_hasDerivAt (x : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-x * gaussianPDFReal 0 1 x) x := by
  have : gaussianPDFReal 0 1 = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext phi_eq
  rw [this]
  have h1 : HasDerivAt (fun x : ℝ => -x ^ 2 / 2) (-x) x := by
    have := ((hasDerivAt_pow 2 x).neg).div_const 2
    convert this using 1; ring
  convert (h1.exp).const_mul (√(2 * π))⁻¹ using 1
  ring

lemma phi_shift (t s : ℝ) :
    gaussianPDFReal 0 1 (t + s) = gaussianPDFReal 0 1 t * exp (-(t * s + s ^ 2 / 2)) := by
  rw [phi_eq, phi_eq, mul_assoc, ← exp_add]
  congr 2; ring

lemma phi_tendsto : Tendsto (gaussianPDFReal 0 1) atBot (𝓝 0) := by
  have h := (tendsto_rpow_abs_mul_exp_neg_mul_sq_cocompact (a := 1 / 2) (by norm_num) 0).mono_left
    (atBot_le_cocompact (α := ℝ))
  have h2 := h.const_mul (√(2 * π))⁻¹
  rw [mul_zero] at h2
  refine h2.congr (fun x => ?_)
  rw [phi_eq, rpow_zero, one_mul]; congr 2; ring

lemma mul_phi_tendsto : Tendsto (fun x => x * gaussianPDFReal 0 1 x) atBot (𝓝 0) := by
  have h := (tendsto_rpow_abs_mul_exp_neg_mul_sq_cocompact (a := 1 / 2) (by norm_num) 1).mono_left
    (atBot_le_cocompact (α := ℝ))
  have h2 := (h.const_mul (-(√(2 * π))⁻¹))
  rw [mul_zero] at h2
  refine h2.congr' ?_
  filter_upwards [eventually_lt_atBot 0] with x hx
  rw [phi_eq, rpow_one, abs_of_neg hx]
  have : -(1 / 2 : ℝ) * x ^ 2 = -x ^ 2 / 2 := by ring
  rw [this]; ring

lemma cdf_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => (phi_pos t).le)

lemma N_hasDerivAt (x : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 x) x := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : (cdf (gaussianReal 0 1) : ℝ → ℝ) =
      fun u => (∫ t in Iic 0, gaussianPDFReal 0 1 t) + ∫ t in (0:ℝ)..u, gaussianPDFReal 0 1 t := by
    funext u
    rw [cdf_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI u)]
    ring
  rw [heq]
  apply HasDerivAt.const_add
  exact intervalIntegral.integral_hasDerivAt_right
    (phi_cont.intervalIntegrable _ _) (phi_cont.stronglyMeasurableAtFilter _ _) phi_cont.continuousAt

/-- A function with nonnegative slope up to `x`, strictly positive slope on some interval
below `x`, and limit `0` at `-∞` is positive at `x`. -/
lemma pos_of_deriv {F F' : ℝ → ℝ} {x a b : ℝ} (hd : ∀ t, HasDerivAt F (F' t) t)
    (hnn : ∀ t ≤ x, 0 ≤ F' t) (hab : a < b) (hbx : b ≤ x) (hpos : ∀ t ∈ Ioo a b, 0 < F' t)
    (hlim : Tendsto F atBot (𝓝 0)) : 0 < F x := by
  have hmono : MonotoneOn F (Iic x) := by
    refine monotoneOn_of_hasDerivWithinAt_nonneg (convex_Iic x)
      (fun t _ => (hd t).continuousAt.continuousWithinAt)
      (fun t _ => (hd t).hasDerivWithinAt) (fun t ht => hnn t ?_)
    rw [interior_Iic] at ht; exact le_of_lt ht
  have ha : 0 ≤ F a := by
    refine le_of_tendsto hlim ?_
    filter_upwards [eventually_le_atBot a] with t ht
    exact hmono (by simp; linarith) (by simp; linarith) ht
  obtain ⟨ξ, hξ, hξeq⟩ := exists_hasDerivAt_eq_slope F F' hab
    (fun t _ => (hd t).continuousAt.continuousWithinAt) (fun t _ => hd t)
  have h1 := hpos ξ hξ
  rw [hξeq] at h1
  have hb : F a < F b := by
    have := (div_pos_iff_of_pos_right (sub_pos.2 hab)).1 h1
    linarith
  have hbx' : F b ≤ F x := hmono (by simp; linarith) (by simp) hbx
  linarith

lemma N_pos (x : ℝ) : 0 < cdf (gaussianReal 0 1) x :=
  pos_of_deriv (F' := gaussianPDFReal 0 1) N_hasDerivAt (fun t _ => (phi_pos t).le)
    (sub_one_lt x) le_rfl (fun t _ => phi_pos t) (tendsto_cdf_atBot _)

lemma N_le_one (x : ℝ) : cdf (gaussianReal 0 1) x ≤ 1 := cdf_le_one _ x

/-- The truncated-normal variance bracket is positive (used by the main theorem). -/
lemma bracket_pos (x : ℝ) :
    0 < cdf (gaussianReal 0 1) x - x * gaussianPDFReal 0 1 x -
      gaussianPDFReal 0 1 x ^ 2 / cdf (gaussianReal 0 1) x := by
  set n := cdf (gaussianReal 0 1) x with hn
  set p := gaussianPDFReal 0 1 x with hp
  have hn0 : 0 < n := N_pos x
  set c := p / n with hc
  have hc0 : 0 < c := div_pos (phi_pos x) hn0
  let F : ℝ → ℝ := fun t => (1 + c ^ 2) * cdf (gaussianReal 0 1) t - (t + 2 * c) * gaussianPDFReal 0 1 t
  have hd : ∀ t, HasDerivAt F ((t + c) ^ 2 * gaussianPDFReal 0 1 t) t := by
    intro t
    have := ((N_hasDerivAt t).const_mul (1 + c ^ 2)).sub
      (((hasDerivAt_id t).add_const (2 * c)).mul (phi_hasDerivAt t))
    convert this using 1
    · funext y; simp only [F, Pi.sub_apply, Pi.mul_apply, id]
    · simp only [id]; ring
  have hlim : Tendsto F atBot (𝓝 0) := by
    have := (((tendsto_cdf_atBot (gaussianReal 0 1)).const_mul (1 + c ^ 2)).sub
      (mul_phi_tendsto.add (phi_tendsto.const_mul (2 * c))))
    simp only [mul_zero, add_zero, sub_zero] at this
    refine this.congr (fun t => ?_)
    simp only [F]; ring
  have hm : min x (-c) - 1 < min x (-c) := sub_one_lt _
  have hF := pos_of_deriv hd (x := x) (fun t _ => by have := phi_pos t; positivity) hm
    (min_le_left _ _) (fun t ht => by
      have h1 : t < -c := lt_of_lt_of_le ht.2 (min_le_right _ _)
      have h2 : t + c ≠ 0 := by linarith
      have := phi_pos t; positivity) hlim
  have : F x = n - x * p - p ^ 2 / n := by
    simp only [F, ← hn, ← hp, hc]; field_simp; ring
  linarith

/-- If a differentiable function has positive slope wherever it is at or below the level `e`,
it meets the level `e` at most once. -/
lemma eq_of_level {H H' : ℝ → ℝ} {e : ℝ} (hd : ∀ y, HasDerivAt H (H' y) y)
    (hpos : ∀ y, H y ≤ e → 0 < H' y) {y1 y2 : ℝ} (h1 : H y1 = e) (h2 : H y2 = e) :
    y1 = y2 := by
  have main : ∀ a b, a < b → H a = e → H b = e → False := by
    intro a b hab ha hb
    -- a point just left of `b` lies below the level
    have hz : ∃ z ∈ Ioo a b, H z < e := by
      have ht := (hd b).tendsto_slope_zero_left
      have hev : ∀ᶠ t in 𝓝[<] (0:ℝ), 0 < t⁻¹ • (H (b + t) - H b) :=
        ht.eventually (lt_mem_nhds (hpos b hb.le))
      have hev2 : ∀ᶠ t in 𝓝[<] (0:ℝ), t ∈ Ioo (a - b) 0 :=
        Ioo_mem_nhdsLT (by linarith)
      obtain ⟨t, h1, h2⟩ := (hev.and hev2).exists
      refine ⟨b + t, ⟨by linarith [h2.1], by linarith [h2.2]⟩, ?_⟩
      rw [smul_eq_mul, hb] at h1
      have : H (b + t) - e < 0 := by
        by_contra hc
        replace hc := not_lt.1 hc
        have : t⁻¹ * (H (b + t) - e) ≤ 0 :=
          mul_nonpos_of_nonpos_of_nonneg (inv_nonpos.2 h2.2.le) hc
        linarith
      linarith
    obtain ⟨z, hzI, hz⟩ := hz
    have hcont : ContinuousOn H (Icc a b) := fun t _ => (hd t).continuousAt.continuousWithinAt
    obtain ⟨m, hmI, hmin⟩ := isCompact_Icc.exists_isMinOn (nonempty_Icc.2 hab.le) hcont
    have hm : H m < e := lt_of_le_of_lt (hmin (Ioo_subset_Icc_self hzI)) hz
    have hma : m ≠ a := by rintro rfl; linarith
    have hmb : m ≠ b := by rintro rfl; linarith
    have hmI' : m ∈ Ioo a b := ⟨lt_of_le_of_ne hmI.1 (Ne.symm hma), lt_of_le_of_ne hmI.2 hmb⟩
    have hloc : IsLocalMin H m := hmin.isLocalMin (Icc_mem_nhds hmI'.1 hmI'.2)
    have := hloc.hasDerivAt_eq_zero (hd m)
    have := hpos m hm.le
    linarith
  rcases lt_trichotomy y1 y2 with h | h | h
  · exact (main y1 y2 h h1 h2).elim
  · exact h
  · exact (main y2 y1 h h2 h1).elim

/-- `d1 · σ√T = log (V / K) + (σ√T)² / 2`. -/
lemma d1_mul (V σ B r T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    d1 V σ B r T * (σ * √T) = log (V / (B * exp (-(r * T)))) + (σ * √T) ^ 2 / 2 := by
  have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have h2 : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, sq_sqrt hT.le]
  rw [d1, div_mul_cancel₀ _ hs.ne', h2]

/-- The one-variable core. In the coordinates `y = d2` (scaled so the discounted debt is 1),
the volatility equation fixes `σ√T = c e / (e + N(y))`; the price equation then reads
`H(y) = e`, and it has exactly one root. -/
lemma core_unique (e c : ℝ) (he : 0 < e) (hc : 0 < c) :
    ∃! y : ℝ, exp (y * (c * e / (e + cdf (gaussianReal 0 1) y)) +
        (c * e / (e + cdf (gaussianReal 0 1) y)) ^ 2 / 2) *
        cdf (gaussianReal 0 1) (y + c * e / (e + cdf (gaussianReal 0 1) y)) -
        cdf (gaussianReal 0 1) y = e := by
  let N : ℝ → ℝ := fun x => cdf (gaussianReal 0 1) x
  let φ : ℝ → ℝ := gaussianPDFReal 0 1
  let S : ℝ → ℝ := fun y => c * e / (e + N y)
  let H : ℝ → ℝ := fun y => exp (y * S y + S y ^ 2 / 2) * N (y + S y) - N y
  let S' : ℝ → ℝ := fun y => -(c * e * φ y) / (e + N y) ^ 2
  let H' : ℝ → ℝ := fun y =>
    exp (y * S y + S y ^ 2 / 2) * (S y + y * S' y + S y * S' y) * N (y + S y) +
      exp (y * S y + S y ^ 2 / 2) * (φ (y + S y) * (1 + S' y)) - φ y
  have hD : ∀ y, 0 < e + N y := fun y => add_pos he (N_pos y)
  have hd : ∀ y, HasDerivAt H (H' y) y := by
    intro y
    have hS : HasDerivAt S (S' y) y := by
      have := (hasDerivAt_const y (c * e)).div ((N_hasDerivAt y).const_add e) (hD y).ne'
      refine this.congr_deriv ?_
      simp only [S', φ, N]; ring
    have hg : HasDerivAt (fun y => y * S y + S y ^ 2 / 2) (S y + y * S' y + S y * S' y) y := by
      have := ((hasDerivAt_id y).mul hS).add ((hS.pow 2).div_const 2)
      refine this.congr_deriv ?_
      simp only [id]; ring
    have hx : HasDerivAt (fun y => y + S y) (1 + S' y) y := (hasDerivAt_id y).add hS
    have hN2 := (N_hasDerivAt (y + S y)).comp y hx
    have := (hg.exp.mul hN2).sub (N_hasDerivAt y)
    refine this.congr_deriv ?_
    simp only [H', φ, N, Function.comp_apply]
  have hpos : ∀ y, H y ≤ e → 0 < H' y := by
    intro y hy
    have hD0 := hD y
    set n1 := N y with hn1
    set D := e + n1 with hDdef
    set Sy := S y with hSy
    have hSy' : Sy = c * e / D := rfl
    have hSy0 : 0 < Sy := by rw [hSy']; positivity
    set x := y + Sy with hx
    set q := exp (y * Sy + Sy ^ 2 / 2) with hq
    have hq0 : 0 < q := exp_pos _
    set nn := N x with hnn
    have hnn0 : 0 < nn := N_pos x
    set p := φ x with hp
    have hp0 : 0 < p := phi_pos x
    have hpy : φ y = q * p := by
      simp only [hp, hx, φ, phi_shift, hq]
      rw [mul_left_comm, ← exp_add]; simp
    have hbr := bracket_pos x
    change 0 < nn - x * p - p ^ 2 / nn at hbr
    have hbr' : 0 < nn ^ 2 - x * p * nn - p ^ 2 := by
      have := mul_pos hnn0 hbr
      have e1 : nn * (nn - x * p - p ^ 2 / nn) = nn ^ 2 - x * p * nn - p ^ 2 := by
        field_simp
      linarith
    have hyle : q * nn ≤ D := by
      have : H y = q * nn - n1 := rfl
      linarith
    have hkey : 0 < nn * D - q * p * (x * nn + p) := by
      have h1 : q * nn * nn ≤ D * nn := mul_le_mul_of_nonneg_right hyle hnn0.le
      have h2 : 0 < q * (nn ^ 2 - x * p * nn - p ^ 2) := mul_pos hq0 hbr'
      nlinarith
    have heq : H' y = Sy * q / D * (nn * D - q * p * (x * nn + p)) := by
      have : H' y = q * (Sy + y * S' y + Sy * S' y) * nn + q * (p * (1 + S' y)) - φ y := rfl
      rw [this, hpy]
      have hS'y : S' y = -(c * e * (q * p)) / D ^ 2 := by
        simp only [S']; rw [hpy]
      rw [hS'y, hSy', hx, hSy']
      field_simp
      ring
    rw [heq]
    positivity
  have hcont : Continuous H := continuous_iff_continuousAt.2 fun y => (hd y).continuousAt
  -- bounds on `S`
  set s0 := c * e / (e + 1) with hs0
  have hs00 : 0 < s0 := by positivity
  have hSlo : ∀ y, s0 ≤ S y := fun y =>
    div_le_div_of_nonneg_left (by positivity) (hD y) (by linarith [N_le_one y])
  have hShi : ∀ y, S y ≤ c := fun y => by
    calc S y = c * e / (e + N y) := rfl
      _ ≤ c * e / e := div_le_div_of_nonneg_left (by positivity) he (by linarith [N_pos y])
      _ = c := by field_simp
  have hlow : ∃ y, H y ≤ e := by
    refine ⟨min 0 ((log e - c ^ 2 / 2) / s0), ?_⟩
    set y := min 0 ((log e - c ^ 2 / 2) / s0)
    have hy0 : y ≤ 0 := min_le_left _ _
    have hy1 : y * s0 ≤ log e - c ^ 2 / 2 :=
      (le_div_iff₀ hs00).1 (min_le_right _ _)
    have h1 : y * S y ≤ y * s0 := mul_le_mul_of_nonpos_left (hSlo y) hy0
    have h2 : S y ^ 2 ≤ c ^ 2 := pow_le_pow_left₀ (by linarith [hSlo y]) (hShi y) 2
    have h3 : exp (y * S y + S y ^ 2 / 2) ≤ e := by
      calc exp (y * S y + S y ^ 2 / 2) ≤ exp (log e) := by gcongr; linarith
        _ = e := exp_log he
    have h4 : exp (y * S y + S y ^ 2 / 2) * N (y + S y) ≤ exp (y * S y + S y ^ 2 / 2) :=
      mul_le_of_le_one_right (exp_pos _).le (N_le_one _)
    have h5 := N_pos y
    show exp (y * S y + S y ^ 2 / 2) * N (y + S y) - N y ≤ e
    linarith
  have hhigh : ∃ y, e ≤ H y := by
    set n0 := N 0 with hn0
    have hn00 : 0 < n0 := N_pos 0
    refine ⟨max 0 (log ((e + 1) / n0) / s0), ?_⟩
    set y := max 0 (log ((e + 1) / n0) / s0)
    have hy0 : 0 ≤ y := le_max_left _ _
    have hy1 : log ((e + 1) / n0) ≤ y * s0 := (div_le_iff₀ hs00).1 (le_max_right _ _)
    have h1 : y * s0 ≤ y * S y := mul_le_mul_of_nonneg_left (hSlo y) hy0
    have h3 : (e + 1) / n0 ≤ exp (y * S y + S y ^ 2 / 2) := by
      calc (e + 1) / n0 = exp (log ((e + 1) / n0)) := (exp_log (by positivity)).symm
        _ ≤ _ := by gcongr; nlinarith [sq_nonneg (S y)]
    have h4 : n0 ≤ N (y + S y) := monotone_cdf _ (by linarith [hSlo y])
    have h5 : (e + 1) / n0 * n0 ≤ exp (y * S y + S y ^ 2 / 2) * N (y + S y) :=
      mul_le_mul h3 h4 hn00.le (exp_pos _).le
    rw [div_mul_cancel₀ _ hn00.ne'] at h5
    have h6 := N_le_one y
    show e ≤ exp (y * S y + S y ^ 2 / 2) * N (y + S y) - N y
    linarith
  obtain ⟨y0, hy0⟩ := mem_range_of_exists_le_of_exists_ge hcont hlow hhigh
  exact ⟨y0, hy0, fun y hy => eq_of_level hd hpos hy hy0⟩

/-- Proof of the main theorem. -/
lemma exists_unique_aux
    (B r T : ℝ) (hB : 0 < B) (hT : 0 < T) (E σE : ℝ) (hE : 0 < E) (hσE : 0 < σE) :
    ∃! p : ℝ × ℝ, 0 < p.1 ∧ 0 < p.2 ∧
      equity p.1 p.2 B r T = E ∧
      σE * E = cdf (gaussianReal 0 1) (d1 p.1 p.2 B r T) * p.2 * p.1 := by
  set K := B * exp (-(r * T)) with hK
  have hK0 : 0 < K := mul_pos hB (exp_pos _)
  have hsT : 0 < √T := sqrt_pos.2 hT
  set e := E / K with he
  have he0 : 0 < e := div_pos hE hK0
  set c := σE * √T with hc
  have hc0 : 0 < c := mul_pos hσE hsT
  obtain ⟨y0, hy0, huniq⟩ := core_unique e c he0 hc0
  set S0 := c * e / (e + cdf (gaussianReal 0 1) y0) with hS0
  have hD0 : 0 < e + cdf (gaussianReal 0 1) y0 := add_pos he0 (N_pos y0)
  have hS00 : 0 < S0 := div_pos (mul_pos hc0 he0) hD0
  set g0 := y0 * S0 + S0 ^ 2 / 2 with hg0
  refine ⟨(K * exp g0, S0 / √T), ⟨mul_pos hK0 (exp_pos _), div_pos hS00 hsT, ?_, ?_⟩, ?_⟩
  · -- the price equation
    have hs : S0 / √T * √T = S0 := div_mul_cancel₀ _ hsT.ne'
    have hd1 := d1_mul (K * exp g0) (S0 / √T) B r T (div_pos hS00 hsT) hT
    rw [← hK, hs, mul_div_cancel_left₀ _ hK0.ne', log_exp] at hd1
    have hx : d1 (K * exp g0) (S0 / √T) B r T = y0 + S0 := by
      apply mul_right_cancel₀ hS00.ne'
      rw [hd1, hg0]; ring
    have hy : d2 (K * exp g0) (S0 / √T) B r T = y0 := by
      rw [d2, hx, hs]; ring
    simp only [equity, ← hK, hx, hy]
    rw [mul_assoc, ← mul_sub, hy0, he, mul_div_cancel₀ _ hK0.ne']
  · -- the volatility equation
    have hs : S0 / √T * √T = S0 := div_mul_cancel₀ _ hsT.ne'
    have hd1 := d1_mul (K * exp g0) (S0 / √T) B r T (div_pos hS00 hsT) hT
    rw [← hK, hs, mul_div_cancel_left₀ _ hK0.ne', log_exp] at hd1
    have hx : d1 (K * exp g0) (S0 / √T) B r T = y0 + S0 := by
      apply mul_right_cancel₀ hS00.ne'
      rw [hd1, hg0]; ring
    simp only
    rw [hx]
    have hA : exp g0 * cdf (gaussianReal 0 1) (y0 + S0) = e + cdf (gaussianReal 0 1) y0 := by
      linarith
    have hSD : S0 * (e + cdf (gaussianReal 0 1) y0) = c * e := by
      rw [hS0]; field_simp
    calc σE * E = K * (c * e) / √T := by
            rw [hc, he]; field_simp
      _ = K * (S0 * (exp g0 * cdf (gaussianReal 0 1) (y0 + S0))) / √T := by rw [hA, hSD]
      _ = _ := by ring
  · -- uniqueness
    rintro ⟨V, σ⟩ ⟨hV, hσ, heq, hvol⟩
    simp only at hV hσ heq hvol
    set s := σ * √T with hs
    have hs0 : 0 < s := mul_pos hσ hsT
    set x := d1 V σ B r T with hx
    have hd1 := d1_mul V σ B r T hσ hT
    rw [← hK, ← hs, ← hx] at hd1
    set y := x - s with hy
    have hVK : V / K = exp (y * s + s ^ 2 / 2) := by
      rw [← exp_log (div_pos hV hK0)]; congr 1
      rw [hy]; linarith
    have hpr : V * cdf (gaussianReal 0 1) x - K * cdf (gaussianReal 0 1) y = E := by
      rw [← heq]; rfl
    have hvol' : s * (e + cdf (gaussianReal 0 1) y) = c * e := by
      have h1 : s * (E + K * cdf (gaussianReal 0 1) y) = σE * √T * E := by
        rw [hs]; linear_combination (-√T) * hvol + (-(σ * √T)) * hpr
      rw [hc, he]; field_simp
      linear_combination h1
    have hsS : s = c * e / (e + cdf (gaussianReal 0 1) y) := by
      have : 0 < e + cdf (gaussianReal 0 1) y := add_pos he0 (N_pos y)
      field_simp; linarith
    have hcore : exp (y * (c * e / (e + cdf (gaussianReal 0 1) y)) +
        (c * e / (e + cdf (gaussianReal 0 1) y)) ^ 2 / 2) *
        cdf (gaussianReal 0 1) (y + c * e / (e + cdf (gaussianReal 0 1) y)) -
        cdf (gaussianReal 0 1) y = e := by
      have hys : y + s = x := by rw [hy]; ring
      rw [← hsS, ← hVK, hys, he, ← hpr]
      field_simp
    have hyy := huniq y hcore
    have hsS0 : s = S0 := by rw [hsS, hyy]
    have hσ' : σ = S0 / √T := by
      rw [← hsS0, hs, mul_div_cancel_right₀ _ hsT.ne']
    have hV' : V = K * exp g0 := by
      rw [hg0, ← hsS0, ← hyy, ← hVK]; field_simp
    rw [hσ', hV']

/-- Proof of the leverage theorem. -/
lemma leverage_aux
    (V σ B r T : ℝ) (hV : 0 < V) (hσ : 0 < σ) (hB : 0 < B) (hT : 0 < T) :
    0 < equity V σ B r T ∧
      1 < V * cdf (gaussianReal 0 1) (d1 V σ B r T) / equity V σ B r T := by
  set K := B * exp (-(r * T)) with hK
  have hK0 : 0 < K := mul_pos hB (exp_pos _)
  set s := σ * √T with hs
  have hs0 : 0 < s := mul_pos hσ (sqrt_pos.2 hT)
  have hd1 := d1_mul V σ B r T hσ hT
  rw [← hK, ← hs] at hd1
  set x1 := d1 V σ B r T with hx1
  set L := log (V / K) with hL
  have hVK : exp L = V / K := exp_log (div_pos hV hK0)
  have hd2 : d2 V σ B r T = x1 - s := rfl
  -- the key sign fact
  have key : ∀ t, t ≤ x1 - s → K * exp (t * s + s ^ 2 / 2) ≤ V := by
    intro t ht
    have : t * s + s ^ 2 / 2 ≤ L := by nlinarith
    calc K * exp (t * s + s ^ 2 / 2) ≤ K * exp L := by gcongr
      _ = V := by rw [hVK]; field_simp
  have keyS : ∀ t, t < x1 - s → K * exp (t * s + s ^ 2 / 2) < V := by
    intro t ht
    have : t * s + s ^ 2 / 2 < L := by nlinarith
    calc K * exp (t * s + s ^ 2 / 2) < K * exp L := by gcongr
      _ = V := by rw [hVK]; field_simp
  let F : ℝ → ℝ := fun t => V * cdf (gaussianReal 0 1) (t + s) - K * cdf (gaussianReal 0 1) t
  let F' : ℝ → ℝ := fun t => gaussianPDFReal 0 1 t * exp (-(t * s + s ^ 2 / 2)) *
    (V - K * exp (t * s + s ^ 2 / 2))
  have hd : ∀ t, HasDerivAt F (F' t) t := by
    intro t
    have := (((N_hasDerivAt (t + s)).comp t ((hasDerivAt_id t).add_const s)).const_mul V).sub
      ((N_hasDerivAt t).const_mul K)
    refine this.congr_deriv ?_
    simp only [F', mul_one, phi_shift]
    have : exp (-(t * s + s ^ 2 / 2)) * exp (t * s + s ^ 2 / 2) = 1 := by
      rw [← exp_add]; simp
    linear_combination (K * gaussianPDFReal 0 1 t) * this
  have hlim : Tendsto F atBot (𝓝 0) := by
    have h1 : Tendsto (fun t : ℝ => t + s) atBot atBot := tendsto_atBot_add_const_right _ s tendsto_id
    have := (((tendsto_cdf_atBot (gaussianReal 0 1)).comp h1).const_mul V).sub
      ((tendsto_cdf_atBot (gaussianReal 0 1)).const_mul K)
    simpa using this
  have hE : 0 < F (x1 - s) := pos_of_deriv hd
    (fun t ht => by have := key t ht; have := phi_pos t; simp only [F']; positivity)
    (sub_one_lt (x1 - s)) le_rfl
    (fun t ht => by
      have := sub_pos.2 (keyS t ht.2); have := phi_pos t; simp only [F']; positivity) hlim
  have hEq : equity V σ B r T = F (x1 - s) := by
    simp only [equity, F, ← hK, hd2, ← hx1, sub_add_cancel]
  rw [hEq]
  refine ⟨hE, ?_⟩
  rw [one_lt_div hE]
  simp only [F, sub_add_cancel]
  have := mul_pos hK0 (N_pos (x1 - s))
  linarith

#print axioms phi_eq
#print axioms phi_pos
#print axioms phi_cont
#print axioms phi_hasDerivAt
#print axioms phi_shift
#print axioms phi_tendsto
#print axioms mul_phi_tendsto
#print axioms cdf_eq_integral
#print axioms N_hasDerivAt
#print axioms pos_of_deriv
#print axioms N_pos
#print axioms N_le_one
#print axioms bracket_pos
#print axioms eq_of_level
#print axioms d1_mul
#print axioms core_unique
#print axioms exists_unique_aux
#print axioms leverage_aux

end Helpers

/-- **Two observations pin down two hidden inputs** (the card's main claim; Why it works,
Step 4 and the detailed proof). Fix one zero-coupon debt with face `B > 0` due in `T > 0` years
and any riskless rate `r`. Then for every positive equity value `E` and every positive equity
volatility `σ_E` there is exactly one pair of a positive asset value `V` and a positive asset
volatility `σ_V` that solves both equations: Merton's price `E = V N(d1) - B e^(-rT) N(d2)` and
the volatility equation `σ_E E = N(d1) σ_V V`. -/
theorem exists_unique_asset_value_and_volatility
    (B r T : ℝ) (hB : 0 < B) (hT : 0 < T) (E σE : ℝ) (hE : 0 < E) (hσE : 0 < σE) :
    ∃! p : ℝ × ℝ, 0 < p.1 ∧ 0 < p.2 ∧
      equity p.1 p.2 B r T = E ∧
      σE * E = cdf (gaussianReal 0 1) (d1 p.1 p.2 B r T) * p.2 * p.1 := by
  exact exists_unique_aux B r T hB hT E σE hE hσE

/-- **The shares swing harder than the assets** (the formula's `L > 1`; Why it works, Step 3).
With positive assets, debt face, asset volatility and time, the equity is positive and the
leverage multiplier `L = V N(d1) / E` is greater than 1. So whenever the volatility equation
`σ_E = L σ_V` holds, the equity volatility is strictly above the asset volatility. -/
theorem leverage_multiplier_gt_one
    (V σ B r T : ℝ) (hV : 0 < V) (hσ : 0 < σ) (hB : 0 < B) (hT : 0 < T) :
    0 < equity V σ B r T ∧
      1 < V * cdf (gaussianReal 0 1) (d1 V σ B r T) / equity V σ B r T := by
  exact leverage_aux V σ B r T hV hσ hB hT

/-- **The bracket is a variance** (Why it works, detailed proof). For every real `x`,
`N(x) - x φ(x) - φ(x)² / N(x) > 0`. This is the bracket in the slope of the dollar swing along
the price curve, so that slope is positive and the two curves cross only once. -/
theorem truncated_normal_bracket_pos (x : ℝ) :
    0 < cdf (gaussianReal 0 1) x - x * gaussianPDFReal 0 1 x -
      gaussianPDFReal 0 1 x ^ 2 / cdf (gaussianReal 0 1) x := by
  exact bracket_pos x

/-! The card's exact checks. -/

-- Worked numbers: `d2 = d1 - 0.20`, since `σ √T = 0.20` when `σ = 0.20` and `T = 1`.
example : (1 / 5 : ℝ) * √1 = 1 / 5 := by norm_num

-- Worked numbers: `d2 = d1 - σ √T = 1.4657 - 0.20 = 1.2657`.
example : (14657 / 10000 : ℚ) - 1 / 5 = 12657 / 10000 := by norm_num

-- Worked numbers: equity is the asset half minus the debt half, `92.86 - 68.27 = 24.59` ($m).
example : (9286 / 100 : ℚ) - 6827 / 100 = 2459 / 100 := by norm_num

-- What breaks: leaving the debt undiscounted gives `V = E + B = 24.59 + 80 = 104.59` ($m).
example : (2459 / 100 : ℚ) + 80 = 10459 / 100 := by norm_num

#print axioms exists_unique_asset_value_and_volatility
#print axioms leverage_multiplier_gt_one
#print axioms truncated_normal_bracket_pos

end AssetsFromShares
