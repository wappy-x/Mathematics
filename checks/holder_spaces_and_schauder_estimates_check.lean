-- Schauder estimates: a continuous source that is not Hölder gives an unbounded bend, while the Hölder source r^(1/2) gives a bounded bend whose Hölder exponent is kept, not gained.
import Mathlib.Topology.MetricSpace.Holder
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics

open Filter Topology
open scoped NNReal

namespace Schauder

/-- The plane with its Euclidean distance. -/
abbrev E2 := EuclideanSpace ℝ (Fin 2)

/-- The bend along x: the second partial derivative in the first variable. -/
noncomputable def dxx (u : ℝ → ℝ → ℝ) (x y : ℝ) : ℝ :=
  deriv (fun s => deriv (fun t => u t y) s) x

/-- The bend along y: the second partial derivative in the second variable. -/
noncomputable def dyy (u : ℝ → ℝ → ℝ) (x y : ℝ) : ℝ :=
  deriv (fun s => deriv (fun t => u x t) s) y

/-- Load A's height: u₁ = (x² − y²) √(ln(1/r)), with r = √(x² + y²). -/
noncomputable def u1 (x y : ℝ) : ℝ :=
  (x ^ 2 - y ^ 2) * Real.sqrt (Real.log (1 / Real.sqrt (x ^ 2 + y ^ 2)))

/-- Load A's source f₁ = −Δu₁, read as a function on the Euclidean plane. -/
noncomputable def f1 (p : E2) : ℝ :=
  -(dxx u1 (p 0) (p 1) + dyy u1 (p 0) (p 1))

/-- Load B's source: f₂ = r^(1/2) = (x² + y²)^(1/4). -/
noncomputable def f2 (x y : ℝ) : ℝ := (x ^ 2 + y ^ 2) ^ ((1 : ℝ) / 4)

/-- Load B's Newtonian potential, up to a constant: w = −(4/25) r^(5/2). -/
noncomputable def w (x y : ℝ) : ℝ := -(4 / 25) * (x ^ 2 + y ^ 2) ^ ((5 : ℝ) / 4)

/-- Radial profile of load A. -/
noncomputable def kA (s : ℝ) : ℝ := Real.sqrt (-(Real.log s) / 2)
noncomputable def kA1 (s : ℝ) : ℝ := -1 / (4 * s * kA s)
noncomputable def kA2 (s : ℝ) : ℝ := 1 / (4 * s ^ 2 * kA s) - 1 / (16 * s ^ 2 * kA s ^ 3)

lemma u1_eq_kA (x y : ℝ) : u1 x y = (x ^ 2 - y ^ 2) * kA (x ^ 2 + y ^ 2) := by
  unfold u1 kA
  rw [one_div, Real.log_inv, Real.log_sqrt (by positivity)]
  ring_nf

lemma kA_pos {s : ℝ} (h0 : 0 < s) (h1 : s < 1) : 0 < kA s := by
  unfold kA
  apply Real.sqrt_pos.mpr
  have := Real.log_neg h0 h1
  linarith

lemma hasDerivAt_kA {s : ℝ} (h0 : 0 < s) (h1 : s < 1) : HasDerivAt kA (kA1 s) s := by
  have hk := kA_pos h0 h1
  have hpos : 0 < -(Real.log s) / 2 := by have := Real.log_neg h0 h1; linarith
  have h : HasDerivAt (fun s => -(Real.log s) / 2) (-(s⁻¹) / 2) s :=
    ((Real.hasDerivAt_log h0.ne').neg).div_const 2
  have h2 := h.sqrt hpos.ne'
  unfold kA1
  have e : kA = fun y => √(-Real.log y / 2) := rfl
  rw [e]
  convert h2 using 1
  field_simp
  norm_num

lemma hasDerivAt_kA1 {s : ℝ} (h0 : 0 < s) (h1 : s < 1) : HasDerivAt kA1 (kA2 s) s := by
  have hk := kA_pos h0 h1
  have h : HasDerivAt (fun s => s * kA s) (1 * kA s + s * kA1 s) s :=
    (hasDerivAt_id s).mul (hasDerivAt_kA h0 h1)
  have h2 := (h.inv (by positivity)).const_mul (-1 / 4)
  have he : kA1 = fun s => -1 / 4 * (s * kA s)⁻¹ := by
    funext s; unfold kA1; field_simp
  rw [he]
  convert h2 using 1
  unfold kA2 kA1
  field_simp
  ring

/-- First x-derivative of u1. -/
noncomputable def U1 (y t : ℝ) : ℝ :=
  2 * t * kA (t ^ 2 + y ^ 2) + (t ^ 2 - y ^ 2) * (kA1 (t ^ 2 + y ^ 2) * (2 * t))

lemma hasDerivAt_u1 {t y : ℝ} (h0 : 0 < t ^ 2 + y ^ 2) (h1 : t ^ 2 + y ^ 2 < 1) :
    HasDerivAt (fun t => u1 t y) (U1 y t) t := by
  have hs : HasDerivAt (fun t => t ^ 2 + y ^ 2) (2 * t) t := by
    simpa using (hasDerivAt_pow 2 t).add_const (y ^ 2)
  have hp : HasDerivAt (fun t => t ^ 2 - y ^ 2) (2 * t) t := by
    simpa using (hasDerivAt_pow 2 t).sub_const (y ^ 2)
  have hk := (hasDerivAt_kA h0 h1).comp t hs
  have := hp.mul hk
  have e : (fun t => u1 t y) = (fun t => t ^ 2 - y ^ 2) * kA ∘ fun t => t ^ 2 + y ^ 2 := by
    funext t; simp only [u1_eq_kA, Pi.mul_apply, Function.comp_apply]
  rw [e]
  convert this using 1
  simp only [U1, Function.comp_apply]

lemma hasDerivAt_U1 {t y : ℝ} (h0 : 0 < t ^ 2 + y ^ 2) (h1 : t ^ 2 + y ^ 2 < 1) :
    HasDerivAt (U1 y) (2 * kA (t ^ 2 + y ^ 2) + (10 * t ^ 2 - 2 * y ^ 2) * kA1 (t ^ 2 + y ^ 2)
      + 4 * t ^ 2 * (t ^ 2 - y ^ 2) * kA2 (t ^ 2 + y ^ 2)) t := by
  have hs : HasDerivAt (fun t => t ^ 2 + y ^ 2) (2 * t) t := by
    simpa using (hasDerivAt_pow 2 t).add_const (y ^ 2)
  have hp : HasDerivAt (fun t => t ^ 2 - y ^ 2) (2 * t) t := by
    simpa using (hasDerivAt_pow 2 t).sub_const (y ^ 2)
  have hk := (hasDerivAt_kA h0 h1).comp t hs
  have hk1 := (hasDerivAt_kA1 h0 h1).comp t hs
  have h2t : HasDerivAt (fun t : ℝ => 2 * t) 2 t := by
    simpa using (hasDerivAt_id t).const_mul (2 : ℝ)
  have := (h2t.mul hk).add (hp.mul (hk1.mul h2t))
  convert this using 1
  all_goals (try funext t')
  all_goals (try simp only [U1, Pi.add_apply, Pi.mul_apply, Function.comp_apply])
  all_goals (try ring_nf)

lemma dxx_u1 {x y : ℝ} (h0 : 0 < x ^ 2 + y ^ 2) (h1 : x ^ 2 + y ^ 2 < 1) :
    dxx u1 x y = 2 * kA (x ^ 2 + y ^ 2) + (10 * x ^ 2 - 2 * y ^ 2) * kA1 (x ^ 2 + y ^ 2)
      + 4 * x ^ 2 * (x ^ 2 - y ^ 2) * kA2 (x ^ 2 + y ^ 2) := by
  unfold dxx
  have hc : Continuous (fun t : ℝ => t ^ 2 + y ^ 2) := by fun_prop
  have hopen : IsOpen {t : ℝ | 0 < t ^ 2 + y ^ 2 ∧ t ^ 2 + y ^ 2 < 1} :=
    (isOpen_lt continuous_const hc).inter (isOpen_lt hc continuous_const)
  have hev : (fun s => deriv (fun t => u1 t y) s) =ᶠ[𝓝 x] U1 y := by
    filter_upwards [hopen.mem_nhds ⟨h0, h1⟩] with t ht
    exact (hasDerivAt_u1 ht.1 ht.2).deriv
  rw [hev.deriv_eq, (hasDerivAt_U1 h0 h1).deriv]

lemma dyy_u1_eq (x y : ℝ) : dyy u1 x y = -dxx u1 y x := by
  unfold dyy dxx
  have h1 : (fun t => u1 x t) = fun t => -(u1 t x) := by
    funext t; rw [u1_eq_kA, u1_eq_kA]; ring_nf
  have h2 : (fun s => deriv (fun t => -(u1 t x)) s) = fun s => -deriv (fun t => u1 t x) s := by
    funext s; exact deriv.neg
  rw [h1, h2]
  exact deriv.neg

lemma f1_formula {x y : ℝ} (h0 : 0 < x ^ 2 + y ^ 2) (h1 : x ^ 2 + y ^ 2 < 1) :
    -(dxx u1 x y + dyy u1 x y) = (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) *
      (2 / kA (x ^ 2 + y ^ 2) + 1 / (4 * kA (x ^ 2 + y ^ 2) ^ 3)) := by
  have h0' : 0 < y ^ 2 + x ^ 2 := by linarith
  have h1' : y ^ 2 + x ^ 2 < 1 := by linarith
  rw [dyy_u1_eq, dxx_u1 h0 h1, dxx_u1 h0' h1', add_comm (y ^ 2) (x ^ 2)]
  have hk := kA_pos h0 h1
  unfold kA1 kA2
  field_simp
  ring

lemma sq_add_sq_eq_norm_sq (p : E2) : (p 0) ^ 2 + (p 1) ^ 2 = ‖p‖ ^ 2 := by
  rw [EuclideanSpace.real_norm_sq_eq, Fin.sum_univ_two]

lemma kA_sq (r : ℝ) : kA (r ^ 2) = √(-Real.log r) := by
  unfold kA
  rw [Real.log_pow]
  push_cast
  ring_nf

lemma norm_vec (a b : ℝ) : ‖(!₂[a, b] : E2)‖ = √(a ^ 2 + b ^ 2) := by
  rw [EuclideanSpace.norm_eq, Fin.sum_univ_two]
  simp

lemma f1_on_x_axis {r : ℝ} (h0 : 0 < r) (h1 : r < 1) :
    f1 (!₂[r, 0]) = 2 / kA (r ^ 2) + 1 / (4 * kA (r ^ 2) ^ 3) := by
  unfold f1
  simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_fin_one]
  rw [f1_formula (by positivity) (by nlinarith)]
  have : r ^ 2 ≠ 0 := by positivity
  field_simp
  ring_nf

lemma f1_on_y_axis {r : ℝ} (h0 : 0 < r) (h1 : r < 1) :
    f1 (!₂[0, r]) = -(2 / kA (r ^ 2) + 1 / (4 * kA (r ^ 2) ^ 3)) := by
  unfold f1
  simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_fin_one]
  rw [f1_formula (by positivity) (by nlinarith)]
  have : r ^ 2 ≠ 0 := by positivity
  field_simp
  ring_nf

lemma tendsto_rpow_mul_sqrt_neg_log {α : ℝ} (hα : 0 < α) :
    Tendsto (fun r : ℝ => r ^ α * √(-Real.log r)) (𝓝[>] 0) (𝓝 0) := by
  have h1 : Tendsto (fun r : ℝ => r ^ α) (𝓝[>] 0) (𝓝 0) := by
    have := (Real.continuousAt_rpow_const 0 α (Or.inr hα.le)).tendsto
    rw [Real.zero_rpow hα.ne'] at this
    exact this.mono_left nhdsWithin_le_nhds
  have h2 := tendsto_log_mul_rpow_nhdsGT_zero hα
  have hU : Tendsto (fun r : ℝ => r ^ α - Real.log r * r ^ α) (𝓝[>] 0) (𝓝 0) := by
    simpa using h1.sub h2
  apply squeeze_zero' _ _ hU
  · filter_upwards [self_mem_nhdsWithin] with r hr
    exact mul_nonneg (Real.rpow_nonneg (le_of_lt hr) _) (Real.sqrt_nonneg _)
  · filter_upwards [Ioo_mem_nhdsGT (show (0 : ℝ) < 1 by norm_num)] with r hr
    have hl : 0 ≤ -Real.log r := by have := Real.log_neg hr.1 hr.2; linarith
    have hs : √(-Real.log r) ≤ 1 + -Real.log r := by
      rw [Real.sqrt_le_iff]
      constructor
      · linarith
      · nlinarith
    have hp : 0 ≤ r ^ α := Real.rpow_nonneg hr.1.le _
    nlinarith

/-- First x-derivative of w. -/
noncomputable def W1 (y t : ℝ) : ℝ := -(2 / 5) * t * (t ^ 2 + y ^ 2) ^ ((1 : ℝ) / 4)

lemma hasDerivAt_w (t y : ℝ) : HasDerivAt (fun t => w t y) (W1 y t) t := by
  have hs : HasDerivAt (fun t => t ^ 2 + y ^ 2) (2 * t) t := by
    simpa using (hasDerivAt_pow 2 t).add_const (y ^ 2)
  have h := (hs.rpow_const (p := (5 : ℝ) / 4) (Or.inr (by norm_num))).const_mul (-(4 / 25) : ℝ)
  unfold w W1
  convert h using 1
  rw [show (5 : ℝ) / 4 - 1 = 1 / 4 by norm_num]
  ring

lemma deriv_w (y : ℝ) : deriv (fun t => w t y) = W1 y :=
  funext fun t => (hasDerivAt_w t y).deriv

lemma hasDerivAt_W1 {t y : ℝ} (h : t ^ 2 + y ^ 2 ≠ 0) :
    HasDerivAt (W1 y) (-(2 / 5) * ((t ^ 2 + y ^ 2) ^ ((1 : ℝ) / 4)
      + t * (2 * t * (1 / 4) * (t ^ 2 + y ^ 2) ^ ((1 : ℝ) / 4 - 1)))) t := by
  have hs : HasDerivAt (fun t => t ^ 2 + y ^ 2) (2 * t) t := by
    simpa using (hasDerivAt_pow 2 t).add_const (y ^ 2)
  have h1 := hs.rpow_const (p := (1 : ℝ) / 4) (Or.inl h)
  have h2 := ((hasDerivAt_id t).mul h1).const_mul (-(2 / 5) : ℝ)
  unfold W1
  convert h2 using 1
  · funext t'
    simp only [Pi.mul_apply, id]
    ring
  · simp only [id]
    ring

lemma dxx_w {x y : ℝ} (h : x ^ 2 + y ^ 2 ≠ 0) :
    dxx w x y = -(2 / 5) * (x ^ 2 + y ^ 2) ^ ((1 : ℝ) / 4)
      - (1 / 5) * x ^ 2 * (x ^ 2 + y ^ 2) ^ ((1 : ℝ) / 4) / (x ^ 2 + y ^ 2) := by
  unfold dxx
  rw [deriv_w, (hasDerivAt_W1 h).deriv, Real.rpow_sub_one h]
  field_simp
  ring

lemma dyy_w_eq (x y : ℝ) : dyy w x y = dxx w y x := by
  unfold dyy dxx
  have e : (fun t => w x t) = fun t => w t x := by
    funext t; unfold w; rw [add_comm]
  rw [e]

lemma ne_zero_of_pair {x y : ℝ} (h : (x, y) ≠ (0, 0)) : x ^ 2 + y ^ 2 ≠ 0 := by
  intro hs
  apply h
  have hx : x = 0 := by nlinarith [sq_nonneg x, sq_nonneg y]
  have hy : y = 0 := by nlinarith [sq_nonneg x, sq_nonneg y]
  rw [hx, hy]

lemma abs_sqrt_sub_sqrt_le {a b : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b) :
    |√a - √b| ≤ √|a - b| := by
  have key : ∀ a b : ℝ, 0 ≤ a → 0 ≤ b → √a - √b ≤ √|a - b| := by
    intro a b ha hb
    have h : √a ≤ √b + √|a - b| := by
      rw [Real.sqrt_le_iff]
      refine ⟨by positivity, ?_⟩
      have e1 := Real.sq_sqrt hb
      have e2 := Real.sq_sqrt (abs_nonneg (a - b))
      have := le_abs_self (a - b)
      have := mul_nonneg (Real.sqrt_nonneg b) (Real.sqrt_nonneg |a - b|)
      nlinarith
    linarith
  rw [abs_le]
  constructor
  · have := key b a hb ha
    rw [abs_sub_comm] at this
    linarith
  · exact key a b ha hb

lemma f2_norm (p : E2) : f2 (p 0) (p 1) = √‖p‖ := by
  unfold f2
  rw [sq_add_sq_eq_norm_sq, Real.sqrt_eq_rpow, ← Real.rpow_natCast,
    ← Real.rpow_mul (norm_nonneg _)]
  norm_num

/-- Continuity of the source is not enough (load A). The source f₁ = −Δu₁ of the height
u₁ = (x² − y²)√(ln(1/r)) tends to 0 at the centre, so it is continuous there; it is not
Hölder with any positive exponent on the punctured disc of radius 1/2; and yet the bend
u₁,ₓₓ(0, r) on the y-axis grows without limit as r shrinks to 0. -/
theorem continuous_source_gives_unbounded_bend :
    Tendsto f1 (𝓝[≠] (0 : E2)) (𝓝 0) ∧
    (∀ C α : ℝ≥0, 0 < α → ¬ HolderOnWith C α f1 (Metric.ball (0 : E2) (1 / 2) \ {0})) ∧
    Tendsto (fun r : ℝ => dxx u1 0 r) (𝓝[>] 0) atTop := by
  refine ⟨?_, ?_, ?_⟩
  · have hK : Tendsto (fun p : E2 => kA (‖p‖ ^ 2)) (𝓝[≠] 0) atTop := by
      simp only [kA_sq]
      exact Real.tendsto_sqrt_atTop.comp (tendsto_neg_atBot_atTop.comp
        (Real.tendsto_log_nhdsGT_zero.comp tendsto_norm_nhdsNE_zero))
    have hg : Tendsto (fun p : E2 => 2 * (kA (‖p‖ ^ 2))⁻¹ + 1 / 4 * ((kA (‖p‖ ^ 2))⁻¹) ^ 3)
        (𝓝[≠] 0) (𝓝 0) := by
      have hi := tendsto_inv_atTop_zero.comp hK
      have h := (hi.const_mul 2).add ((hi.pow 3).const_mul (1 / 4))
      rw [show (2 : ℝ) * 0 + 1 / 4 * 0 ^ 3 = 0 by norm_num] at h
      exact h
    apply squeeze_zero_norm' _ hg
    have hev : ∀ᶠ p in 𝓝[≠] (0 : E2), p ≠ 0 ∧ ‖p‖ < 1 := by
      filter_upwards [self_mem_nhdsWithin,
        nhdsWithin_le_nhds (Metric.ball_mem_nhds (0 : E2) one_pos)] with p hp hb
      exact ⟨hp, by simpa using hb⟩
    filter_upwards [hev] with p hp
    have hs := sq_add_sq_eq_norm_sq p
    have hn : 0 < ‖p‖ := norm_pos_iff.mpr hp.1
    have h0 : 0 < ‖p‖ ^ 2 := by positivity
    have h1 : ‖p‖ ^ 2 < 1 := by nlinarith
    have h0' : 0 < (p 0) ^ 2 + (p 1) ^ 2 := by rw [hs]; exact h0
    have h1' : (p 0) ^ 2 + (p 1) ^ 2 < 1 := by rw [hs]; exact h1
    have hK0 := kA_pos h0 h1
    unfold f1
    rw [f1_formula h0' h1', hs, Real.norm_eq_abs, abs_mul]
    have hq : |((p 0) ^ 2 - (p 1) ^ 2) / ‖p‖ ^ 2| ≤ 1 := by
      rw [abs_div, abs_of_pos h0, div_le_one h0, abs_le]
      constructor <;> nlinarith [sq_nonneg (p 0), sq_nonneg (p 1)]
    have heq : 2 / kA (‖p‖ ^ 2) + 1 / (4 * kA (‖p‖ ^ 2) ^ 3)
        = 2 * (kA (‖p‖ ^ 2))⁻¹ + 1 / 4 * ((kA (‖p‖ ^ 2))⁻¹) ^ 3 := by
      field_simp
    have hnn : 0 ≤ 2 / kA (‖p‖ ^ 2) + 1 / (4 * kA (‖p‖ ^ 2) ^ 3) := by positivity
    rw [abs_of_nonneg hnn, ← heq]
    calc _ ≤ 1 * (2 / kA (‖p‖ ^ 2) + 1 / (4 * kA (‖p‖ ^ 2) ^ 3)) :=
          mul_le_mul_of_nonneg_right hq hnn
      _ = _ := one_mul _
  · intro C α hα hH
    have hα' : (0 : ℝ) < α := NNReal.coe_pos.mpr hα
    have key : ∀ r : ℝ, 0 < r → r < 1 / 2 →
        4 ≤ C * 2 ^ (α : ℝ) * (r ^ (α : ℝ) * √(-Real.log r)) := by
      intro r hr0 hr1
      have hnP : ‖(!₂[r, 0] : E2)‖ = r := by
        rw [norm_vec]; simp [Real.sqrt_sq hr0.le]
      have hnQ : ‖(!₂[0, r] : E2)‖ = r := by
        rw [norm_vec]; simp [Real.sqrt_sq hr0.le]
      have hP : (!₂[r, 0] : E2) ∈ Metric.ball (0 : E2) (1 / 2) \ {0} := by
        refine ⟨by simpa [hnP] using hr1, ?_⟩
        intro h
        have : ‖(!₂[r, 0] : E2)‖ = 0 := by rw [Set.mem_singleton_iff.mp h, norm_zero]
        linarith
      have hQ : (!₂[0, r] : E2) ∈ Metric.ball (0 : E2) (1 / 2) \ {0} := by
        refine ⟨by simpa [hnQ] using hr1, ?_⟩
        intro h
        have : ‖(!₂[0, r] : E2)‖ = 0 := by rw [Set.mem_singleton_iff.mp h, norm_zero]
        linarith
      have hd : dist (!₂[r, 0] : E2) (!₂[0, r]) ≤ 2 * r := by
        have := dist_le_norm_add_norm (!₂[r, 0] : E2) (!₂[0, r])
        rw [hnP, hnQ] at this
        linarith
      have hH' := hH.dist_le_of_le hP hQ hd
      rw [f1_on_x_axis hr0 (by linarith), f1_on_y_axis hr0 (by linarith), Real.dist_eq,
        kA_sq] at hH'
      have hK : 0 < √(-Real.log r) := by
        have := kA_pos (s := r ^ 2) (by positivity) (by nlinarith)
        rwa [kA_sq] at this
      set K := √(-Real.log r)
      have hge : 4 / K ≤ |2 / K + 1 / (4 * K ^ 3) - -(2 / K + 1 / (4 * K ^ 3))| := by
        have : 0 ≤ 1 / (4 * K ^ 3) := by positivity
        have : 0 ≤ 2 / K := by positivity
        rw [abs_of_nonneg (by linarith)]
        have : 4 / K = 2 / K + 2 / K := by ring
        linarith
      have h4 : 4 / K ≤ C * (2 * r) ^ (α : ℝ) := hge.trans hH'
      rw [Real.mul_rpow (by norm_num) hr0.le] at h4
      rw [div_le_iff₀ hK] at h4
      linarith
    have hT : Tendsto (fun r : ℝ => C * 2 ^ (α : ℝ) * (r ^ (α : ℝ) * √(-Real.log r)))
        (𝓝[>] 0) (𝓝 0) := by
      simpa using (tendsto_rpow_mul_sqrt_neg_log hα').const_mul ((C : ℝ) * 2 ^ (α : ℝ))
    have hev : ∀ᶠ r in 𝓝[>] (0 : ℝ),
        4 ≤ C * 2 ^ (α : ℝ) * (r ^ (α : ℝ) * √(-Real.log r)) := by
      filter_upwards [Ioo_mem_nhdsGT (show (0 : ℝ) < 1 / 2 by norm_num)] with r hr
      exact key r hr.1 hr.2
    have := ge_of_tendsto hT hev
    norm_num at this
  · have hK : Tendsto (fun r : ℝ => √(-Real.log r)) (𝓝[>] 0) atTop :=
      Real.tendsto_sqrt_atTop.comp (tendsto_neg_atBot_atTop.comp Real.tendsto_log_nhdsGT_zero)
    apply tendsto_atTop_mono' _ _ hK
    filter_upwards [Ioo_mem_nhdsGT (show (0 : ℝ) < 1 by norm_num)] with r hr
    have h0 : 0 < (0 : ℝ) ^ 2 + r ^ 2 := by have := hr.1; positivity
    have h1 : (0 : ℝ) ^ 2 + r ^ 2 < 1 := by nlinarith [hr.1, hr.2]
    rw [dxx_u1 h0 h1]
    have e : (0 : ℝ) ^ 2 + r ^ 2 = r ^ 2 := by ring
    rw [e]
    have hr2 : 0 < r ^ 2 := by have := hr.1; positivity
    have hr21 : r ^ 2 < 1 := by nlinarith [hr.1, hr.2]
    have hk := kA_pos hr2 hr21
    have hk1 : kA1 (r ^ 2) ≤ 0 := by
      unfold kA1
      apply div_nonpos_of_nonpos_of_nonneg (by norm_num) (by positivity)
    rw [kA_sq] at hk ⊢
    nlinarith [sq_nonneg r]

/-- A Hölder source gives a bounded bend (load B). The source f₂ = r^(1/2) is Hölder with
exponent 1/2 and Hölder constant 1 on the plane; w = −(4/25) r^(5/2) solves −Δw = f₂ away
from the centre; and its bends along x and along y are at most (3/5) r^(1/2) in size. -/
theorem holder_source_gives_bounded_bend :
    HolderWith 1 (1 / 2) (fun p : E2 => f2 (p 0) (p 1)) ∧
    (∀ x y : ℝ, (x, y) ≠ (0, 0) → -(dxx w x y + dyy w x y) = f2 x y) ∧
    (∀ x y : ℝ, (x, y) ≠ (0, 0) →
      |dxx w x y| ≤ 3 / 5 * f2 x y ∧ |dyy w x y| ≤ 3 / 5 * f2 x y) := by
  refine ⟨?_, ?_, ?_⟩
  · intro p q
    rw [edist_dist, edist_dist, ENNReal.coe_one, one_mul,
      ENNReal.ofReal_rpow_of_nonneg dist_nonneg (NNReal.coe_nonneg _)]
    apply ENNReal.ofReal_le_ofReal
    simp only [f2_norm, Real.dist_eq]
    have h1 := abs_sqrt_sub_sqrt_le (norm_nonneg p) (norm_nonneg q)
    have h2 : √|‖p‖ - ‖q‖| ≤ √(dist p q) := by
      apply Real.sqrt_le_sqrt
      rw [dist_eq_norm]
      exact abs_norm_sub_norm_le p q
    rw [Real.sqrt_eq_rpow (dist p q)] at h2
    convert h1.trans h2 using 2
    norm_num
  · intro x y hxy
    have h := ne_zero_of_pair hxy
    have h' : y ^ 2 + x ^ 2 ≠ 0 := by rwa [add_comm]
    rw [dyy_w_eq, dxx_w h, dxx_w h', add_comm (y ^ 2) (x ^ 2)]
    unfold f2
    field_simp
    ring
  · intro x y hxy
    have h := ne_zero_of_pair hxy
    have hpos : 0 < x ^ 2 + y ^ 2 := lt_of_le_of_ne (by positivity) (Ne.symm h)
    have h' : y ^ 2 + x ^ 2 ≠ 0 := by rwa [add_comm]
    have ha : 0 < (x ^ 2 + y ^ 2) ^ ((1 : ℝ) / 4) := Real.rpow_pos_of_pos hpos _
    unfold f2
    rw [dyy_w_eq, dxx_w h, dxx_w h', add_comm (y ^ 2) (x ^ 2)]
    set a := (x ^ 2 + y ^ 2) ^ ((1 : ℝ) / 4)
    have bx : x ^ 2 * a / (x ^ 2 + y ^ 2) ≤ a := by
      rw [div_le_iff₀ hpos]; nlinarith [sq_nonneg y]
    have by' : y ^ 2 * a / (x ^ 2 + y ^ 2) ≤ a := by
      rw [div_le_iff₀ hpos]; nlinarith [sq_nonneg x]
    have bx0 : 0 ≤ x ^ 2 * a / (x ^ 2 + y ^ 2) := by positivity
    have by0 : 0 ≤ y ^ 2 * a / (x ^ 2 + y ^ 2) := by positivity
    have ex : 1 / 5 * x ^ 2 * a / (x ^ 2 + y ^ 2) = 1 / 5 * (x ^ 2 * a / (x ^ 2 + y ^ 2)) := by
      ring
    have ey : 1 / 5 * y ^ 2 * a / (x ^ 2 + y ^ 2) = 1 / 5 * (y ^ 2 * a / (x ^ 2 + y ^ 2)) := by
      ring
    rw [ex, ey]
    constructor <;> rw [abs_le] <;> constructor <;> linarith

/-- The exponent is kept, not gained: load B's source is Hölder with exponent 1/2, but the
bend w_xx of its potential is not Hölder with exponent 0.6 = 3/5 for any constant. -/
theorem bend_keeps_exponent_not_more (C : ℝ≥0) :
    ¬ HolderWith C (3 / 5) (fun p : E2 => dxx w (p 0) (p 1)) := by
  intro hH
  set c : ℝ := (C : ℝ)
  have hc : 0 ≤ c := C.coe_nonneg
  set b : ℝ := 1 / (10 * (c + 1))
  have hb : 0 < b := by positivity
  have hbc : b * (10 * (c + 1)) = 1 := by
    simp only [b]; field_simp
  set r : ℝ := b ^ 10
  have hr : 0 < r := by positivity
  have hnP : ‖(!₂[r, 0] : E2)‖ = r := by
    rw [norm_vec]; simp [Real.sqrt_sq hr.le]
  have hnQ : ‖(!₂[0, r] : E2)‖ = r := by
    rw [norm_vec]; simp [Real.sqrt_sq hr.le]
  have hd : dist (!₂[r, 0] : E2) (!₂[0, r]) ≤ 2 * r := by
    have := dist_le_norm_add_norm (!₂[r, 0] : E2) (!₂[0, r])
    rw [hnP, hnQ] at this
    linarith
  have hH' := hH.dist_le_of_le hd
  simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_fin_one] at hH'
  have h1 : r ^ 2 + (0 : ℝ) ^ 2 ≠ 0 := by positivity
  have h2 : (0 : ℝ) ^ 2 + r ^ 2 ≠ 0 := by positivity
  rw [dxx_w h1, dxx_w h2, Real.dist_eq] at hH'
  have e1 : r ^ 2 + (0 : ℝ) ^ 2 = b ^ 20 := by simp only [r]; ring
  have e2 : (0 : ℝ) ^ 2 + r ^ 2 = b ^ 20 := by simp only [r]; ring
  rw [e1, e2] at hH'
  have ea : (b ^ 20) ^ ((1 : ℝ) / 4) = b ^ 5 := by
    rw [show b ^ 20 = (b ^ 5) ^ (4 : ℕ) by ring, ← Real.rpow_natCast (b ^ 5) 4,
      ← Real.rpow_mul (by positivity)]
    norm_num
  rw [ea] at hH'
  have hr6 : r ^ ((3 : ℝ) / 5) = b ^ 6 := by
    simp only [r]
    rw [← Real.rpow_natCast b 10, ← Real.rpow_mul hb.le]
    norm_num
  have hcoe : (((3 / 5 : ℝ≥0)) : ℝ) = 3 / 5 := by norm_num
  have eb : (2 * r) ^ (((3 / 5 : ℝ≥0)) : ℝ) = 2 ^ ((3 : ℝ) / 5) * b ^ 6 := by
    rw [hcoe, Real.mul_rpow (by norm_num) hr.le, hr6]
  rw [eb] at hH'
  have h2le : (2 : ℝ) ^ ((3 : ℝ) / 5) ≤ 2 := by
    have := Real.rpow_le_rpow_of_exponent_le (show (1 : ℝ) ≤ 2 by norm_num)
      (show (3 : ℝ) / 5 ≤ 1 by norm_num)
    simpa using this
  have hb20 : b ^ 20 ≠ 0 := by positivity
  have hdist : |-(2 / 5) * b ^ 5 - 1 / 5 * r ^ 2 * b ^ 5 / b ^ 20 -
      (-(2 / 5) * b ^ 5 - 1 / 5 * 0 ^ 2 * b ^ 5 / b ^ 20)| = 1 / 5 * b ^ 5 := by
    have : r ^ 2 = b ^ 20 := by simp only [r]; ring
    have e : -(2 / 5) * b ^ 5 - 1 / 5 * r ^ 2 * b ^ 5 / b ^ 20 -
        (-(2 / 5) * b ^ 5 - 1 / 5 * 0 ^ 2 * b ^ 5 / b ^ 20) = -(1 / 5 * b ^ 5) := by
      rw [this]
      field_simp
      ring
    rw [e, abs_neg, abs_of_pos (by positivity)]
  rw [hdist] at hH'
  have hb5 : 0 < b ^ 5 := by positivity
  have hk : 1 / 5 * b ^ 5 ≤ c * 2 * b ^ 6 := by
    calc 1 / 5 * b ^ 5 ≤ c * (2 ^ ((3 : ℝ) / 5) * b ^ 6) := hH'
      _ ≤ c * (2 * b ^ 6) := by gcongr
      _ = c * 2 * b ^ 6 := by ring
  have hk2 : 1 / 5 ≤ c * 2 * b := by
    have e : c * 2 * b ^ 6 = (c * 2 * b) * b ^ 5 := by ring
    rw [e] at hk
    nlinarith
  nlinarith

/-! The card's method-of-continuity table: on the model −a_t u'' = 1 with 1 ≤ a ≤ 3, the
factor bound for a step from s to t is |t − s| · 2 / (1 + 2 s). -/
example : (1 / 4 : ℚ) * 2 / (1 + 2 * 0) = 1 / 2 := by norm_num
example : (1 / 4 : ℚ) * 2 / (1 + 2 * (1 / 4)) = 1 / 3 := by norm_num
example : (1 / 4 : ℚ) * 2 / (1 + 2 * (1 / 2)) = 1 / 4 := by norm_num
example : (1 / 4 : ℚ) * 2 / (1 + 2 * (3 / 4)) = 1 / 5 := by norm_num
/-- One step from 0 to 1: the factor bound is 2, above 1, so the map is not a contraction. -/
example : (1 : ℚ) * 2 / (1 + 2 * 0) = 2 ∧ (1 : ℚ) < 2 := by norm_num

#print axioms u1_eq_kA
#print axioms kA_pos
#print axioms hasDerivAt_kA
#print axioms hasDerivAt_kA1
#print axioms hasDerivAt_u1
#print axioms hasDerivAt_U1
#print axioms dxx_u1
#print axioms dyy_u1_eq
#print axioms f1_formula
#print axioms sq_add_sq_eq_norm_sq
#print axioms kA_sq
#print axioms norm_vec
#print axioms f1_on_x_axis
#print axioms f1_on_y_axis
#print axioms tendsto_rpow_mul_sqrt_neg_log
#print axioms hasDerivAt_w
#print axioms deriv_w
#print axioms hasDerivAt_W1
#print axioms dxx_w
#print axioms dyy_w_eq
#print axioms ne_zero_of_pair
#print axioms abs_sqrt_sub_sqrt_le
#print axioms f2_norm
#print axioms continuous_source_gives_unbounded_bend
#print axioms holder_source_gives_bounded_bend
#print axioms bend_keeps_exponent_not_more

end Schauder
