-- The standard maps: the power z ^ (π / α) opens a wedge of angle α onto the upper half plane, the exponential lays the band of heights 0 to π onto it with the principal log as inverse, and the Cayley map (w - i) / (w + i) carries it onto the unit disc, each one-to-one and onto.
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Analysis.Complex.Basic

open Complex

/-! Regions, in Mathlib's terms.
* The wedge of angle `α` is `{z | 0 < arg z ∧ arg z < α}`, where `arg` is the principal
  argument in `(-π, π]`. The point `0` is left out because `arg 0 = 0`.
* The upper half plane is `{w | 0 < w.im}`.
* The corridor is the band `{z | 0 < z.im ∧ z.im < π}`.
* The unit disc is `Metric.ball 0 1`, the points at distance less than 1 from `0`.
Powers `z ^ a` with complex exponent are Mathlib's principal branch `exp (log z * a)`,
and `log` is the principal logarithm. The card's branch rule (every region avoids the
negative real axis, the cut) is the hypothesis `α ≤ π`. -/

theorem helper_arg_mem_of_im_pos {w : ℂ} (hw : 0 < w.im) : 0 < arg w ∧ arg w < Real.pi := by
  refine ⟨lt_of_le_of_ne (arg_nonneg_iff.mpr hw.le) ?_, arg_lt_pi_iff.mpr (Or.inr hw.ne')⟩
  intro h
  have := (arg_eq_zero_iff.mp h.symm).2
  linarith

theorem helper_log_mul_im (z : ℂ) (a : ℝ) : (log z * (a : ℂ)).im = arg z * a := by
  simp [mul_im, log_im]

#print axioms helper_arg_mem_of_im_pos
#print axioms helper_log_mul_im

/-- A power opens a wedge: for an opening angle `α` with `0 < α ≤ π`, the principal power
`z ^ (π / α)` maps the wedge of angle `α` one-to-one onto the upper half plane. -/
theorem power_opens_wedge_onto_upper_half_plane (α : ℝ) (hα : 0 < α) (hαπ : α ≤ Real.pi) :
    Set.BijOn (fun z : ℂ => z ^ ((Real.pi / α : ℝ) : ℂ))
      {z : ℂ | 0 < arg z ∧ arg z < α} {w : ℂ | 0 < w.im} := by
  have hpi := Real.pi_pos
  have ha : 0 < Real.pi / α := div_pos hpi hα
  have hz0 : ∀ z : ℂ, 0 < arg z → z ≠ 0 := by
    rintro z h rfl; simp at h
  -- key: the image angle
  have key : ∀ z : ℂ, 0 < arg z → arg z < α →
      0 < (log z * ((Real.pi / α : ℝ) : ℂ)).im ∧ (log z * ((Real.pi / α : ℝ) : ℂ)).im < Real.pi := by
    intro z h1 h2
    rw [helper_log_mul_im]
    refine ⟨mul_pos h1 ha, ?_⟩
    have : arg z * (Real.pi / α) < α * (Real.pi / α) := mul_lt_mul_of_pos_right h2 ha
    rwa [mul_div_cancel₀ _ hα.ne'] at this
  refine ⟨?_, ?_, ?_⟩
  · rintro z ⟨h1, h2⟩
    simp only [Set.mem_ofPred_eq]
    rw [cpow_def_of_ne_zero (hz0 z h1), exp_im]
    obtain ⟨k1, k2⟩ := key z h1 h2
    exact mul_pos (Real.exp_pos _) (Real.sin_pos_of_pos_of_lt_pi k1 k2)
  · rintro z ⟨h1, h2⟩ w ⟨h3, h4⟩ h
    simp only at h
    rw [cpow_def_of_ne_zero (hz0 z h1), cpow_def_of_ne_zero (hz0 w h3)] at h
    obtain ⟨k1, k2⟩ := key z h1 h2
    obtain ⟨k3, k4⟩ := key w h3 h4
    have e := congrArg log h
    rw [log_exp (by linarith) k2.le, log_exp (by linarith) k4.le] at e
    have hne : ((Real.pi / α : ℝ) : ℂ) ≠ 0 := by exact_mod_cast ha.ne'
    have e2 : log z = log w := mul_right_cancel₀ hne e
    rw [← exp_log (hz0 z h1), ← exp_log (hz0 w h3), e2]
  · intro w hw
    simp only [Set.mem_ofPred_eq] at hw
    obtain ⟨b1, b2⟩ := helper_arg_mem_of_im_pos hw
    have hw0 : w ≠ 0 := by rintro rfl; simp at hw
    set x : ℂ := log w * ((α / Real.pi : ℝ) : ℂ) with hx
    have hxim : x.im = arg w * (α / Real.pi) := helper_log_mul_im w _
    have hb : 0 < α / Real.pi := div_pos hα hpi
    have xi1 : 0 < x.im := by rw [hxim]; exact mul_pos b1 hb
    have xi2 : x.im < α := by
      rw [hxim]
      have : arg w * (α / Real.pi) < Real.pi * (α / Real.pi) := mul_lt_mul_of_pos_right b2 hb
      rwa [mul_div_cancel₀ _ hpi.ne'] at this
    have hlog : log (exp x) = x := log_exp (by linarith) (by linarith)
    have harg : arg (exp x) = x.im := by rw [← log_im, hlog]
    refine ⟨exp x, ⟨by rw [harg]; exact xi1, by rw [harg]; exact xi2⟩, ?_⟩
    simp only
    rw [cpow_def_of_ne_zero (exp_ne_zero x), hlog, hx, mul_assoc, ← ofReal_mul,
      div_mul_div_comm, mul_comm α, div_self (by positivity), ofReal_one, mul_one, exp_log hw0]

/-- The exponential lays the corridor of heights strictly between 0 and π one-to-one onto
the upper half plane, and the principal logarithm is its inverse there. -/
theorem exp_lays_corridor_onto_upper_half_plane :
    Set.BijOn exp {z : ℂ | 0 < z.im ∧ z.im < Real.pi} {w : ℂ | 0 < w.im} ∧
      Set.InvOn log exp {z : ℂ | 0 < z.im ∧ z.im < Real.pi} {w : ℂ | 0 < w.im} := by
  have hpi := Real.pi_pos
  have linv : Set.LeftInvOn log exp {z : ℂ | 0 < z.im ∧ z.im < Real.pi} := by
    rintro z ⟨h1, h2⟩
    exact log_exp (by linarith) h2.le
  have rinv : Set.RightInvOn log exp {w : ℂ | 0 < w.im} := by
    intro w hw
    have hw0 : w ≠ 0 := by rintro rfl; simp at hw
    exact exp_log hw0
  have maps : Set.MapsTo exp {z : ℂ | 0 < z.im ∧ z.im < Real.pi} {w : ℂ | 0 < w.im} := by
    rintro z ⟨h1, h2⟩
    simp only [Set.mem_ofPred_eq, exp_im]
    exact mul_pos (Real.exp_pos _) (Real.sin_pos_of_pos_of_lt_pi h1 h2)
  have lmaps : Set.MapsTo log {w : ℂ | 0 < w.im} {z : ℂ | 0 < z.im ∧ z.im < Real.pi} := by
    intro w hw
    simp only [Set.mem_ofPred_eq, log_im]
    exact helper_arg_mem_of_im_pos hw
  exact ⟨Set.InvOn.bijOn ⟨linv, rinv⟩ maps lmaps, linv, rinv⟩

/-- The Cayley map `C(w) = (w - i) / (w + i)` maps the upper half plane one-to-one onto the
unit disc. -/
theorem cayley_maps_upper_half_plane_onto_disc :
    Set.BijOn (fun w : ℂ => (w - I) / (w + I)) {w : ℂ | 0 < w.im} (Metric.ball (0 : ℂ) 1) := by
  have hne : ∀ w : ℂ, 0 < w.im → w + I ≠ 0 := by
    intro w hw h
    have := congrArg Complex.im h
    simp at this; linarith
  refine ⟨?_, ?_, ?_⟩
  · intro w hw
    simp only [Set.mem_ofPred_eq] at hw
    simp only [Metric.mem_ball, dist_zero_right, norm_div]
    have hp : 0 < ‖w + I‖ := norm_pos_iff.mpr (hne w hw)
    rw [div_lt_one hp]
    have h1 : ‖w - I‖ ^ 2 < ‖w + I‖ ^ 2 := by
      rw [← normSq_eq_norm_sq, ← normSq_eq_norm_sq, normSq_apply, normSq_apply]
      simp; nlinarith
    exact lt_of_pow_lt_pow_left₀ 2 (norm_nonneg _) h1
  · intro w hw v hv h
    simp only at h
    rw [div_eq_div_iff (hne w hw) (hne v hv)] at h
    have : (2 * I) * (w - v) = 0 := by linear_combination h
    rcases mul_eq_zero.mp this with h2 | h2
    · simp at h2
    · exact sub_eq_zero.mp h2
  · intro ζ hζ
    simp only [Metric.mem_ball, dist_zero_right] at hζ
    have hζ2 : ζ.re ^ 2 + ζ.im ^ 2 < 1 := by
      have : normSq ζ < 1 := by rw [normSq_eq_norm_sq]; nlinarith [norm_nonneg ζ]
      rw [normSq_apply] at this; nlinarith
    have h1 : 1 - ζ ≠ 0 := by
      intro h
      have hr := congrArg Complex.re h
      have hi := congrArg Complex.im h
      simp at hr hi
      nlinarith
    refine ⟨I * (1 + ζ) / (1 - ζ), ?_, ?_⟩
    · simp only [Set.mem_ofPred_eq]
      have hd : 0 < normSq (1 - ζ) := normSq_pos.mpr h1
      rw [div_im]
      simp [normSq_apply] at hd ⊢
      rw [div_lt_div_iff_of_pos_right hd]
      nlinarith
    · simp only
      have h2 : I * (1 + ζ) / (1 - ζ) + I = 2 * I / (1 - ζ) := by
        field_simp; ring
      rw [h2]
      have h3 : I * (1 + ζ) / (1 - ζ) - I = 2 * I * ζ / (1 - ζ) := by
        field_simp; ring
      rw [h3]
      field_simp

/-! The card's exact worked examples. -/

-- Squaring the lot's point: (1 + 2i)^2 = -3 + 4i.
example : ((1 : ℂ) + 2 * I) ^ 2 = -3 + 4 * I := by
  ring_nf; rw [I_sq]; ring
-- Cayley at -3 + 4i: (-3 + 3i) / (-3 + 5i) = 24/34 + (6/34) i.
example : ((-3 + 4 * I) - I) / ((-3 + 4 * I) + I) = 24 / 34 + 6 / 34 * I := by
  have h : (-3 + 4 * I) + I ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  rw [div_eq_iff h]
  ring_nf; rw [I_sq]; ring
-- The chain, C after squaring, carries 1 + 2i to 24/34 + (6/34) i.
example : (((1 : ℂ) + 2 * I) ^ 2 - I) / (((1 : ℂ) + 2 * I) ^ 2 + I) = 24 / 34 + 6 / 34 * I := by
  have e : ((1 : ℂ) + 2 * I) ^ 2 = -3 + 4 * I := by ring_nf; rw [I_sq]; ring
  have h : (-3 + 4 * I) + I ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  rw [e, div_eq_iff h]
  ring_nf; rw [I_sq]; ring
-- Its modulus squared is (24^2 + 6^2) / 34^2 = 18/34 < 1: inside the disc.
example : ((24 : ℝ) ^ 2 + 6 ^ 2) / 34 ^ 2 = 18 / 34 ∧ (18 : ℝ) / 34 < 1 := by
  constructor <;> norm_num
-- The corridor's midline: e^(iπ/2) = i, and the Cayley map sends i to the centre 0.
example : exp (↑(Real.pi / 2) * I) = I := by
  rw [exp_mul_I, ← ofReal_cos, ← ofReal_sin, Real.cos_pi_div_two, Real.sin_pi_div_two]; simp
example : (I - I) / (I + I) = 0 := by
  simp
-- The 45-degree wedge's midline point 2e^(iπ/8) goes to 16i under the fourth power.
example : (2 * exp (↑(Real.pi / 8) * I)) ^ 4 = 16 * I := by
  rw [mul_pow, ← exp_nat_mul]
  have : ((4 : ℕ) : ℂ) * (↑(Real.pi / 8) * I) = ↑(Real.pi / 2) * I := by
    push_cast; ring
  rw [this, exp_mul_I, ← ofReal_cos, ← ofReal_sin, Real.cos_pi_div_two, Real.sin_pi_div_two]
  norm_num

#print axioms power_opens_wedge_onto_upper_half_plane
#print axioms exp_lays_corridor_onto_upper_half_plane
#print axioms cayley_maps_upper_half_plane_onto_disc
