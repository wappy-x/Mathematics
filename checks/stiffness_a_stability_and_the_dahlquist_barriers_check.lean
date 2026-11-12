-- Stiffness: an A-stable linear multistep method has order at most 2, at order 2 its error constant is at most -1/12, and no method whose one-step factor is a polynomial is A-stable.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Algebra.Polynomial.AlgebraMap
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.RingTheory.Coprime.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Complex.Schwarz
import Mathlib.Analysis.Complex.RemovableSingularity
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.Analysis.RCLike.Lemmas
import Mathlib.Topology.Algebra.Polynomial

/-! Notation. A linear multistep method `∑ a_j y_(n+j) = h ∑ b_j f_(n+j)` is given by its two
polynomials `ρ ζ = ∑ a_j ζ^j` and `σ ζ = ∑ b_j ζ^j`, with real weights. It is a genuine
(irreducible) method when `ρ` and `σ` have no common factor. On the test equation `y' = λ y`
with `z = h λ`, its solutions are combinations of `ζ^n` with `ζ` a root of `ρ - z σ`.

* `z` lies in the stability region `S` when every root `ζ` of `ρ - z σ` has `‖ζ‖ ≤ 1`, and every
  root with `‖ζ‖ = 1` is simple.
* The method is A-stable when `S` contains every `z` with negative real part.
* The method has order `p` when `ρ(e^w) - w σ(e^w) = O(w^(p+1))` as `w → 0`; its error constant
  is `C = C_(p+1) / σ(1)`, where `C_(p+1)` is the coefficient of `w^(p+1)`.
* A one-step method multiplies `y` by `R z` each step; it is A-stable when `‖R z‖ ≤ 1` for every
  `z` with negative real part. -/

open Polynomial Asymptotics Filter Topology

theorem dq_aeval_ofReal (p : ℝ[X]) (x : ℝ) : aeval (x : ℂ) p = ((p.eval x : ℝ) : ℂ) :=
  (Polynomial.ofReal_eval (K := ℂ) p x).symm

#print axioms dq_aeval_ofReal

theorem dq_add_ne {ρ σ : ℝ[X]}
    (hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1)
    {A : ℝ} (hA : 0 < A) {ζ : ℂ} (hζ : 1 < ‖ζ‖) :
    aeval ζ σ + (A : ℂ) * aeval ζ ρ ≠ 0 := by
  intro h
  have hA' : (A : ℂ) ≠ 0 := by exact_mod_cast hA.ne'
  have := hS (-(A : ℂ)⁻¹) (by
    rw [Complex.neg_re, Complex.inv_re, Complex.normSq_ofReal, Complex.ofReal_re]
    have : 0 < A / (A * A) := by positivity
    linarith) ζ (by
      have : aeval ζ ρ - -(A : ℂ)⁻¹ * aeval ζ σ = (aeval ζ σ + (A : ℂ) * aeval ζ ρ) / A := by
        field_simp; ring
      rw [this, h, zero_div])
  linarith

#print axioms dq_add_ne

theorem dq_re_nonneg {ρ σ : ℝ[X]}
    (hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1)
    {ζ : ℂ} (hζ : 1 < ‖ζ‖) :
    0 ≤ (aeval ζ σ * (starRingEnd ℂ) (aeval ζ ρ)).re := by
  by_contra h
  push Not at h
  set a := aeval ζ σ
  set b := aeval ζ ρ
  have ha : a ≠ 0 := by
    intro h0; rw [h0] at h; simp at h
  have hre : (b / a).re < 0 := by
    rw [Complex.div_re]
    have hpos : 0 < Complex.normSq a := Complex.normSq_pos.2 ha
    have : (a * (starRingEnd ℂ) b).re = a.re * b.re + a.im * b.im := by
      simp [Complex.mul_re]
    rw [this] at h
    rw [← add_div, div_neg_iff]
    right; constructor <;> nlinarith
  have := hS (b / a) hre ζ (by field_simp; ring)
  linarith

#print axioms dq_re_nonneg

theorem dq_norm_sub_le {ρ σ : ℝ[X]}
    (hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1)
    {A : ℝ} (hA : 0 < A) {ζ : ℂ} (hζ : 1 < ‖ζ‖) :
    ‖aeval ζ σ - (A : ℂ) * aeval ζ ρ‖ ≤ ‖aeval ζ σ + (A : ℂ) * aeval ζ ρ‖ := by
  have h := dq_re_nonneg hS hζ
  set a := aeval ζ σ
  set b := aeval ζ ρ
  have h' : (a * (starRingEnd ℂ) b).re = a.re * b.re + a.im * b.im := by
    simp [Complex.mul_re]
  rw [h'] at h
  rw [Complex.norm_def, Complex.norm_def]
  apply Real.sqrt_le_sqrt
  simp only [Complex.normSq_apply, Complex.sub_re, Complex.add_re, Complex.mul_re,
    Complex.sub_im, Complex.add_im, Complex.mul_im, Complex.ofReal_re, Complex.ofReal_im]
  nlinarith

#print axioms dq_norm_sub_le

theorem dq_real_nonneg {ρ σ : ℝ[X]}
    (hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1)
    {ξ : ℝ} (hξ : 1 < ξ) : 0 ≤ σ.eval ξ * ρ.eval ξ := by
  by_contra h
  push Not at h
  have hr : ρ.eval ξ ≠ 0 := by rintro h0; rw [h0, mul_zero] at h; exact lt_irrefl _ h
  have hApos : 0 < -(σ.eval ξ / ρ.eval ξ) := by
    rw [neg_pos, div_neg_iff]
    rcases lt_or_gt_of_ne hr with hr | hr
    · left; constructor <;> nlinarith
    · right; constructor <;> nlinarith
  have hn : 1 < ‖(ξ : ℂ)‖ := by
    rw [Complex.norm_real, Real.norm_eq_abs, abs_of_pos (by linarith)]; exact hξ
  apply dq_add_ne hS hApos hn
  rw [dq_aeval_ofReal, dq_aeval_ofReal]
  have hrc : ((ρ.eval ξ : ℝ) : ℂ) ≠ 0 := by exact_mod_cast hr
  push_cast
  field_simp
  ring_nf

#print axioms dq_real_nonneg

theorem dq_mob_norm {ξ : ℝ} (hξ : 1 < ξ) {v : ℂ} (hv : ‖v‖ < 1) (hne : 1 + (ξ : ℂ) * v ≠ 0) :
    1 < ‖((ξ : ℂ) + v) / (1 + (ξ : ℂ) * v)‖ := by
  rw [norm_div, one_lt_div (norm_pos_iff.2 hne), Complex.norm_def, Complex.norm_def]
  apply Real.sqrt_lt_sqrt (Complex.normSq_nonneg _)
  have hv2 : v.re * v.re + v.im * v.im < 1 := by
    have : Complex.normSq v < 1 := by
      rw [Complex.normSq_eq_norm_sq]; nlinarith [norm_nonneg v]
    simpa [Complex.normSq_apply] using this
  simp only [Complex.normSq_apply, Complex.add_re, Complex.add_im, Complex.mul_re,
    Complex.mul_im, Complex.ofReal_re, Complex.ofReal_im, Complex.one_re, Complex.one_im]
  nlinarith [mul_pos (by nlinarith : (0:ℝ) < ξ * ξ - 1) (by linarith : (0:ℝ) < 1 - (v.re * v.re + v.im * v.im))]

#print axioms dq_mob_norm

open Metric Function Set in
theorem dq_pick {ρ σ : ℝ[X]}
    (hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1)
    {ξ₁ ξ₂ A : ℝ} (h1 : 1 < ξ₁) (h12 : ξ₁ < ξ₂) (hA : 0 < A)
    (hA1 : σ.eval ξ₁ = A * ρ.eval ξ₁) :
    |σ.eval ξ₂ - A * ρ.eval ξ₂| ≤
      (ξ₂ - ξ₁) / (ξ₁ * ξ₂ - 1) * |σ.eval ξ₂ + A * ρ.eval ξ₂| := by
  set Φ : ℂ → ℂ := fun ζ => (aeval ζ σ - (A : ℂ) * aeval ζ ρ) / (aeval ζ σ + (A : ℂ) * aeval ζ ρ)
    with hΦ
  set mob : ℂ → ℂ := fun v => ((ξ₁ : ℂ) + v) / (1 + (ξ₁ : ℂ) * v) with hmob
  set k : ℂ → ℂ := fun v => Φ (mob v) with hk
  set c0 : ℂ := ((-1 / ξ₁ : ℝ) : ℂ) with hc0
  have hξ0 : (ξ₁ : ℂ) ≠ 0 := by exact_mod_cast (by linarith : ξ₁ ≠ 0)
  have hden : ∀ v : ℂ, v ≠ c0 → 1 + (ξ₁ : ℂ) * v ≠ 0 := by
    intro v hv h
    apply hv
    rw [hc0]; push_cast
    field_simp
    linear_combination h
  have hc0n : ‖c0‖ < 1 := by
    rw [hc0, Complex.norm_real, Real.norm_eq_abs, abs_div, abs_neg, abs_one,
      abs_of_pos (by linarith), div_lt_one (by linarith)]
    exact h1
  have hball : ball (0 : ℂ) 1 ∈ 𝓝 c0 := isOpen_ball.mem_nhds (mem_ball_zero_iff.2 hc0n)
  have hgood : ∀ v ∈ ball (0 : ℂ) 1 \ {c0}, 1 + (ξ₁ : ℂ) * v ≠ 0 ∧ 1 < ‖mob v‖ := by
    intro v hv
    have h2 := hden v hv.2
    exact ⟨h2, dq_mob_norm h1 (mem_ball_zero_iff.1 hv.1) h2⟩
  have hkd : DifferentiableOn ℂ k (ball (0 : ℂ) 1 \ {c0}) := by
    intro v hv
    obtain ⟨h2, h3⟩ := hgood v hv
    apply DifferentiableAt.differentiableWithinAt
    have hm : DifferentiableAt ℂ mob v := by
      simp only [hmob]
      exact (differentiableAt_const _ |>.add differentiableAt_id).div
        (differentiableAt_const _ |>.add (differentiableAt_const _ |>.mul differentiableAt_id)) h2
    have hΦd : DifferentiableAt ℂ Φ (mob v) := by
      simp only [hΦ]
      exact ((Polynomial.differentiable_aeval σ _).sub
        ((differentiableAt_const _).mul (Polynomial.differentiable_aeval ρ _))).div
        ((Polynomial.differentiable_aeval σ _).add
        ((differentiableAt_const _).mul (Polynomial.differentiable_aeval ρ _)))
        (dq_add_ne hS hA h3)
    exact hΦd.comp v hm
  have hkb : ∀ v ∈ ball (0 : ℂ) 1 \ {c0}, ‖k v‖ ≤ 1 := by
    intro v hv
    obtain ⟨_, h3⟩ := hgood v hv
    simp only [hk, hΦ, norm_div]
    exact div_le_one_of_le₀ (dq_norm_sub_le hS hA h3) (norm_nonneg _)
  set k' := update k c0 (limUnder (𝓝[≠] c0) k) with hk'
  have hk'd : DifferentiableOn ℂ k' (ball (0 : ℂ) 1) :=
    Complex.differentiableOn_update_limUnder_of_bddAbove hball hkd
      ⟨1, by rintro _ ⟨v, hv, rfl⟩; exact hkb v hv⟩
  have h0c : (0 : ℂ) ≠ c0 := by
    rw [hc0]; norm_cast; intro h; field_simp at h; norm_num at h
  have hmob0 : mob 0 = (ξ₁ : ℂ) := by simp [hmob]
  have hk'0 : k' 0 = 0 := by
    rw [hk', update_of_ne h0c]
    simp only [hk, hmob0, hΦ, dq_aeval_ofReal, hA1]
    push_cast; ring
  have hmaps : MapsTo k' (ball (0 : ℂ) 1) (closedBall (k' 0) 1) := by
    intro v hv
    rw [hk'0, mem_closedBall_zero_iff]
    by_cases hvc : v = c0
    · subst hvc
      have hcont : Tendsto k' (𝓝[≠] c0) (𝓝 (k' c0)) :=
        ((hk'd.continuousOn.continuousAt hball).tendsto).mono_left nhdsWithin_le_nhds
      have hev : ∀ᶠ w in 𝓝[≠] c0, ‖k' w‖ ≤ 1 := by
        filter_upwards [nhdsWithin_le_nhds hball, self_mem_nhdsWithin] with w hw hw2
        rw [hk', update_of_ne hw2]
        exact hkb w ⟨hw, hw2⟩
      exact le_of_tendsto hcont.norm hev
    · rw [hk', update_of_ne hvc]
      exact hkb v ⟨hv, hvc⟩
  have hd1 : 0 < ξ₁ * ξ₂ - 1 := by nlinarith
  set r : ℝ := -(ξ₂ - ξ₁) / (ξ₁ * ξ₂ - 1) with hr
  have hrabs : |r| = (ξ₂ - ξ₁) / (ξ₁ * ξ₂ - 1) := by
    rw [hr, abs_div, abs_neg, abs_of_pos (by linarith), abs_of_pos hd1]
  have hrlt : |r| < 1 := by
    rw [hrabs, div_lt_one hd1]; nlinarith
  have hv2 : (r : ℂ) ∈ ball (0 : ℂ) 1 := by
    rw [mem_ball_zero_iff, Complex.norm_real, Real.norm_eq_abs]; exact hrlt
  have hrc : (r : ℂ) ≠ c0 := by
    rw [hc0]; intro h0
    have h : r = -1 / ξ₁ := Complex.ofReal_injective h0
    have e1 : r * (ξ₁ * ξ₂ - 1) = -(ξ₂ - ξ₁) := by rw [hr, div_mul_cancel₀ _ hd1.ne']
    have e2 : r * ξ₁ = -1 := by rw [h, div_mul_cancel₀ _ (by linarith)]
    have : ξ₁ ^ 2 = 1 := by linear_combination (-ξ₁) * e1 + (ξ₁ * ξ₂ - 1) * e2
    nlinarith
  have hmob2 : mob r = (ξ₂ : ℂ) := by
    have h3 : (1 + ξ₁ * r) ≠ 0 := by exact_mod_cast hden r hrc
    have : (ξ₁ + r) / (1 + ξ₁ * r) = ξ₂ := by
      rw [div_eq_iff h3, hr]
      field_simp
      ring
    simp only [hmob]
    rw [← this]; push_cast; rfl
  have hsch := Complex.dist_le_div_mul_dist_of_mapsTo_ball hk'd hmaps hv2
  rw [hk'0, dist_zero_right, dist_zero_right, div_one, one_mul, Complex.norm_real,
    Real.norm_eq_abs, hk', update_of_ne hrc] at hsch
  simp only [hk, hmob2, hΦ, dq_aeval_ofReal] at hsch
  have hne : σ.eval ξ₂ + A * ρ.eval ξ₂ ≠ 0 := by
    have := dq_add_ne hS hA (ζ := (ξ₂ : ℂ)) (by
      rw [Complex.norm_real, Real.norm_eq_abs, abs_of_pos (by linarith)]; linarith)
    rw [dq_aeval_ofReal, dq_aeval_ofReal] at this
    exact_mod_cast this
  have : ‖(((σ.eval ξ₂ - A * ρ.eval ξ₂) / (σ.eval ξ₂ + A * ρ.eval ξ₂) : ℝ) : ℂ)‖ ≤ |r| := by
    push_cast; exact hsch
  rw [Complex.norm_real, Real.norm_eq_abs, abs_div, div_le_iff₀ (abs_pos.2 hne), hrabs] at this
  exact this

#print axioms dq_pick

theorem dq_div_nonneg {ρ σ : ℝ[X]}
    (hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1)
    {ξ : ℝ} (hξ : 1 < ξ) : 0 ≤ σ.eval ξ / ρ.eval ξ := by
  have h := dq_real_nonneg hS hξ
  rcases eq_or_ne (ρ.eval ξ) 0 with h0 | h0
  · rw [h0, div_zero]
  · have : σ.eval ξ / ρ.eval ξ = σ.eval ξ * ρ.eval ξ / (ρ.eval ξ) ^ 2 := by
      field_simp
    rw [this]; positivity

#print axioms dq_div_nonneg

theorem dq_mono {ρ σ : ℝ[X]}
    (hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1)
    {ξ₁ ξ₂ : ℝ} (h1 : 1 < ξ₁) (h12 : ξ₁ < ξ₂) :
    σ.eval ξ₁ / ρ.eval ξ₁ * ((ξ₁ - 1) / (ξ₁ + 1)) ≤
      σ.eval ξ₂ / ρ.eval ξ₂ * ((ξ₂ - 1) / (ξ₂ + 1)) := by
  have hβ0 : 0 ≤ σ.eval ξ₂ / ρ.eval ξ₂ := dq_div_nonneg hS (by linarith)
  have hx1 : 0 < (ξ₁ - 1) / (ξ₁ + 1) := div_pos (by linarith) (by linarith)
  have hx2 : 0 < (ξ₂ - 1) / (ξ₂ + 1) := div_pos (by linarith) (by linarith)
  set A := σ.eval ξ₁ / ρ.eval ξ₁ with hAdef
  set β := σ.eval ξ₂ / ρ.eval ξ₂ with hβdef
  rcases le_or_gt A 0 with hA | hA
  · nlinarith
  have hb : ρ.eval ξ₁ ≠ 0 := by
    intro h0; rw [hAdef, h0, div_zero] at hA; exact lt_irrefl _ hA
  have hp := dq_pick hS h1 h12 hA (by rw [hAdef]; field_simp)
  have hne : σ.eval ξ₂ + A * ρ.eval ξ₂ ≠ 0 := by
    have := dq_add_ne hS hA (ζ := (ξ₂ : ℂ)) (by
      rw [Complex.norm_real, Real.norm_eq_abs, abs_of_pos (by linarith)]; linarith)
    rw [dq_aeval_ofReal, dq_aeval_ofReal] at this
    exact_mod_cast this
  have hD : 0 < ξ₁ * ξ₂ - 1 := by nlinarith
  have hr : ρ.eval ξ₂ ≠ 0 := by
    intro h0
    rw [h0, mul_zero, sub_zero, add_zero] at hp
    rw [h0, mul_zero, add_zero] at hne
    have hd : (ξ₂ - ξ₁) / (ξ₁ * ξ₂ - 1) < 1 := by rw [div_lt_one hD]; nlinarith
    have : |σ.eval ξ₂| ≤ 0 := by nlinarith [abs_nonneg (σ.eval ξ₂)]
    exact hne (abs_nonpos_iff.1 this)
  have hs : σ.eval ξ₂ = β * ρ.eval ξ₂ := by rw [hβdef]; field_simp
  rw [hs, ← sub_mul, ← add_mul, abs_mul, abs_mul, abs_of_nonneg (by linarith : 0 ≤ β + A),
    ← mul_assoc] at hp
  have hk : |β - A| ≤ (ξ₂ - ξ₁) / (ξ₁ * ξ₂ - 1) * (β + A) :=
    le_of_mul_le_mul_right hp (abs_pos.2 hr)
  have hk2 : A - β ≤ (ξ₂ - ξ₁) / (ξ₁ * ξ₂ - 1) * (β + A) :=
    le_trans (by rw [abs_sub_comm]; exact le_abs_self _) hk
  rw [div_mul_eq_mul_div, le_div_iff₀ hD] at hk2
  rw [← mul_div_assoc, ← mul_div_assoc, div_le_div_iff₀ (by linarith) (by linarith)]
  nlinarith

#print axioms dq_mono

theorem dq_exp_taylor :
    Tendsto (fun t : ℝ => (2 * (Real.exp t - 1) - t * (Real.exp t + 1)) / t ^ 3)
      (𝓝[>] 0) (𝓝 (-1 / 6)) := by
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero_norm' ?_ (tendsto_norm_zero.mono_left nhdsWithin_le_nhds)
  filter_upwards [Ioo_mem_nhdsGT (zero_lt_one' ℝ)] with t ht
  obtain ⟨ht0, ht1⟩ := ht
  have hR := Real.exp_bound (x := t) (abs_le.2 ⟨by linarith, by linarith⟩) (n := 4) (by norm_num)
  norm_num [Finset.sum_range_succ, Nat.factorial] at hR
  set R := Real.exp t - (1 + t + t ^ 2 / 2 + t ^ 3 / 6) with hRdef
  have hR' : |R| ≤ t ^ 4 * (5 / 96) := by
    rw [hRdef]; rw [abs_of_pos ht0] at hR
    convert hR using 2
  have he : (2 * (Real.exp t - 1) - t * (Real.exp t + 1)) / t ^ 3 - (-1 / 6)
      = -t / 6 + (2 - t) * (R / t ^ 3) := by
    rw [hRdef]; field_simp; ring
  simp only [Real.norm_eq_abs]
  rw [he, abs_of_pos ht0, abs_abs]
  have ht3 : 0 < t ^ 3 := by positivity
  have hu : |R / t ^ 3| ≤ t * (5 / 96) := by
    rw [abs_div, abs_of_pos ht3, div_le_iff₀ ht3]
    calc |R| ≤ t ^ 4 * (5 / 96) := hR'
      _ = t * (5 / 96) * t ^ 3 := by ring
  obtain ⟨hu1, hu2⟩ := abs_le.1 hu
  rw [abs_le]
  constructor <;> nlinarith

#print axioms dq_exp_taylor

theorem dq_core (ρ σ : ℝ[X]) (hcop : IsCoprime ρ σ)
    (hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1)
    (c : ℝ)
    (horder : (fun w : ℂ => aeval (Complex.exp w) ρ - w * aeval (Complex.exp w) σ - (c : ℂ) * w ^ 3) =O[𝓝 0]
      (fun w : ℂ => w ^ 4)) :
    c / σ.eval 1 ≤ -1 / 12 := by
  set S : ℝ → ℝ := fun t => σ.eval (Real.exp t) with hSdef
  set P : ℝ → ℝ := fun t => ρ.eval (Real.exp t) with hPdef
  set q : ℝ → ℝ := fun t => P t - t * S t with hqdef
  -- the order condition along the real axis
  have hR : (fun t : ℝ => q t - c * t ^ 3) =O[𝓝 0] (fun t : ℝ => t ^ 4) := by
    have h1 := horder.comp_tendsto (Complex.continuous_ofReal.tendsto' 0 0 (by simp))
    have h2 : (fun t : ℝ => (((q t - c * t ^ 3) : ℝ) : ℂ)) =O[𝓝 0]
        (fun t : ℝ => (((t ^ 4 : ℝ)) : ℂ)) := by
      refine h1.congr (fun t => ?_) (fun t => ?_)
      · simp only [Function.comp, hqdef, hPdef, hSdef, ← Complex.ofReal_exp, dq_aeval_ofReal]
        push_cast; ring
      · simp
    rw [← isBigO_norm_norm] at h2
    simp only [Complex.norm_real] at h2
    rwa [isBigO_norm_norm] at h2
  have hq3 : Tendsto (fun t => q t / t ^ 3) (𝓝[>] 0) (𝓝 c) := by
    have h1 := (hR.trans_isLittleO (isLittleO_pow_pow (𝕜 := ℝ) (by norm_num : 3 < 4)))
      |>.tendsto_div_nhds_zero
    have h2 := (h1.mono_left (nhdsWithin_le_nhds (s := Set.Ioi (0 : ℝ)))).add_const c
    rw [zero_add] at h2
    refine h2.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with t ht
    have : t ≠ 0 := ne_of_gt ht
    field_simp; ring
  have hS1 : Tendsto S (𝓝[>] 0) (𝓝 (σ.eval 1)) := by
    have := ((σ.continuous.comp Real.continuous_exp).tendsto 0)
    simp only [Function.comp, Real.exp_zero] at this
    exact this.mono_left nhdsWithin_le_nhds
  have ht2 : Tendsto (fun t : ℝ => t ^ 2) (𝓝[>] 0) (𝓝 0) :=
    ((continuous_pow 2).tendsto' 0 0 (by simp)).mono_left nhdsWithin_le_nhds
  have hP1 : Tendsto (fun t => P t / t) (𝓝[>] 0) (𝓝 (σ.eval 1)) := by
    have h := hS1.add (ht2.mul hq3)
    rw [zero_mul, add_zero] at h
    refine h.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with t ht
    have : t ≠ 0 := ne_of_gt ht
    simp only [hqdef]
    field_simp; ring
  have hρ1 : ρ.eval 1 = 0 := by
    have hPc : Tendsto P (𝓝[>] 0) (𝓝 (ρ.eval 1)) := by
      have := ((ρ.continuous.comp Real.continuous_exp).tendsto 0)
      simp only [Function.comp, Real.exp_zero] at this
      exact this.mono_left nhdsWithin_le_nhds
    have hP0 : Tendsto P (𝓝[>] 0) (𝓝 0) := by
      have h := (tendsto_id.mono_left nhdsWithin_le_nhds :
        Tendsto (fun t : ℝ => t) (𝓝[>] 0) (𝓝 0)).mul hP1
      rw [zero_mul] at h
      refine h.congr' ?_
      filter_upwards [self_mem_nhdsWithin] with t ht
      have ht' : 0 < t := ht
      simp only [id]
      field_simp [ne_of_gt ht']
    exact tendsto_nhds_unique hPc hP0
  have hσ1 : σ.eval 1 ≠ 0 := by
    intro h0
    have h1 : X - C 1 ∣ ρ := dvd_iff_isRoot.2 hρ1
    have h2 : X - C 1 ∣ σ := dvd_iff_isRoot.2 h0
    exact Polynomial.not_isUnit_X_sub_C 1 (hcop.isUnit_of_dvd' h1 h2)
  set m : ℝ → ℝ := fun t => S t / P t * ((Real.exp t - 1) / (Real.exp t + 1)) with hmdef
  have hmono : ∀ t₁ t₂ : ℝ, 0 < t₁ → t₁ < t₂ → m t₁ ≤ m t₂ := by
    intro t₁ t₂ h1 h2
    exact dq_mono hS (by have := Real.exp_lt_exp.2 h1; rwa [Real.exp_zero] at this)
      (Real.exp_lt_exp.2 h2)
  set L : ℝ := (σ.eval 1 * (-1 / 6) - c * (1 + 1)) / (2 * σ.eval 1 * (1 + 1)) with hL
  have hlim : Tendsto (fun t => (m t - 1 / 2) / t ^ 2) (𝓝[>] 0) (𝓝 L) := by
    have he1 : Tendsto (fun t => Real.exp t + 1) (𝓝[>] 0) (𝓝 (1 + 1)) := by
      have := (Real.continuous_exp.tendsto 0).add_const 1
      rw [Real.exp_zero] at this; exact this.mono_left nhdsWithin_le_nhds
    have h := ((hS1.mul dq_exp_taylor).sub (hq3.mul he1)).div ((hP1.const_mul 2).mul he1)
      (mul_ne_zero (mul_ne_zero two_ne_zero hσ1) (by norm_num))
    refine h.congr' ?_
    filter_upwards [self_mem_nhdsWithin, hP1.eventually_ne hσ1] with t ht hPt
    have ht0 : t ≠ 0 := ne_of_gt (show 0 < t from ht)
    have hP0 : P t ≠ 0 := by intro h; rw [h, zero_div] at hPt; exact hPt rfl
    have he : Real.exp t + 1 ≠ 0 := by positivity
    simp only [Pi.div_apply, hmdef, hqdef]
    field_simp
    ring
  have hm : Tendsto m (𝓝[>] 0) (𝓝 (1 / 2)) := by
    have h := (ht2.mul hlim).const_add (1 / 2)
    rw [zero_mul, add_zero] at h
    refine h.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with t ht
    have ht' : 0 < t := ht
    field_simp [ne_of_gt ht']
    ring
  by_contra hcon
  push Not at hcon
  have hLneg : L < 0 := by
    have : L = -(1 / 24) - (c / σ.eval 1) / 2 := by rw [hL]; field_simp; ring
    rw [this]; linarith
  obtain ⟨t₀, ht₀, hpos⟩ := ((hlim.eventually (gt_mem_nhds hLneg)).and self_mem_nhdsWithin).exists
  have hpos' : 0 < t₀ := hpos
  have hm0 : m t₀ < 1 / 2 := by
    have h2 : 0 < t₀ ^ 2 := by positivity
    rw [div_lt_iff₀ h2, zero_mul] at ht₀; linarith
  obtain ⟨t, h1, h2⟩ := ((hm.eventually (lt_mem_nhds hm0)).and (Ioo_mem_nhdsGT hpos')).exists
  exact absurd (hmono t t₀ h2.1 h2.2) (not_le.2 h1)

#print axioms dq_core

/-- The second Dahlquist barrier (Step 7 of the card): an A-stable linear multistep method has
order at most 2. Take a linear multistep method with real weights whose polynomials `ρ` and `σ`
have no common factor. Suppose that for every `z` with negative real part, every root `ζ` of
`ρ - z σ` has size at most 1, and those of size exactly 1 are simple (A-stability). If
`ρ(e^w) - w σ(e^w) = O(w^(p+1))` as `w → 0` (order `p`), then `p ≤ 2`. -/
theorem a_stable_multistep_order_le_two (ρ σ : ℝ[X]) (hcop : IsCoprime ρ σ)
    (hA : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ,
      (ρ.map (algebraMap ℝ ℂ) - C z * σ.map (algebraMap ℝ ℂ)).IsRoot ζ →
        ‖ζ‖ ≤ 1 ∧ (‖ζ‖ = 1 →
          rootMultiplicity ζ (ρ.map (algebraMap ℝ ℂ) - C z * σ.map (algebraMap ℝ ℂ)) = 1))
    (p : ℕ)
    (horder : (fun w : ℂ => aeval (Complex.exp w) ρ - w * aeval (Complex.exp w) σ) =O[𝓝 0]
      (fun w : ℂ => w ^ (p + 1))) :
    p ≤ 2 := by
  by_contra hp
  push Not at hp
  have hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1 :=
    fun z hz ζ h => (hA z hz ζ (by simpa [IsRoot] using h)).1
  have hpow : (fun w : ℂ => w ^ (p + 1)) =O[𝓝 0] (fun w : ℂ => w ^ 4) := by
    rcases Nat.lt_or_ge 3 p with h | h
    · exact (isLittleO_pow_pow (by omega)).isBigO
    · have : p + 1 = 4 := by omega
      rw [this]
  have h4 := horder.trans hpow
  have h0 : (fun w : ℂ => aeval (Complex.exp w) ρ - w * aeval (Complex.exp w) σ
      - ((0 : ℝ) : ℂ) * w ^ 3) =O[𝓝 0] (fun w : ℂ => w ^ 4) := by
    simpa using h4
  have := dq_core ρ σ hcop hS 0 h0
  norm_num at this

/-- The second half of the second barrier (Step E of the card's proof): an A-stable linear
multistep method of order 2 has error constant `C ≤ -1/12`, the trapezoid's value. For the same
kind of method as above, if `ρ(e^w) - w σ(e^w) = c w^3 + O(w^4)` as `w → 0` with `c` real
(order at least 2, leading coefficient `C_3 = c`), then `C = c / σ(1) ≤ -1/12`. -/
theorem a_stable_order_two_error_constant_le (ρ σ : ℝ[X]) (hcop : IsCoprime ρ σ)
    (hA : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ,
      (ρ.map (algebraMap ℝ ℂ) - C z * σ.map (algebraMap ℝ ℂ)).IsRoot ζ →
        ‖ζ‖ ≤ 1 ∧ (‖ζ‖ = 1 →
          rootMultiplicity ζ (ρ.map (algebraMap ℝ ℂ) - C z * σ.map (algebraMap ℝ ℂ)) = 1))
    (c : ℝ)
    (horder : (fun w : ℂ => aeval (Complex.exp w) ρ - w * aeval (Complex.exp w) σ - (c : ℂ) * w ^ 3) =O[𝓝 0]
      (fun w : ℂ => w ^ 4)) :
    c / σ.eval 1 ≤ -1 / 12 := by
  have hS : ∀ z : ℂ, z.re < 0 → ∀ ζ : ℂ, aeval ζ ρ - z * aeval ζ σ = 0 → ‖ζ‖ ≤ 1 :=
    fun z hz ζ h => (hA z hz ζ (by simpa [IsRoot] using h)).1
  exact dq_core ρ σ hcop hS c horder

/-- Step 2 of the card: no explicit method is A-stable. An explicit Runge-Kutta step multiplies
`y` by a polynomial `R z` that is not constant; then some `z` with negative real part has
`‖R z‖ > 1`, so the stability region misses part of the left half-plane. -/
theorem polynomial_stability_function_not_a_stable (R : ℝ[X]) (hR : 0 < R.natDegree) :
    ∃ z : ℂ, z.re < 0 ∧ 1 < ‖aeval z R‖ := by
  have hdeg : 0 < (R.map (algebraMap ℝ ℂ)).degree := by
    rw [degree_map]; exact natDegree_pos_iff_degree_pos.mp hR
  have ht : Tendsto (fun x : ℝ => ‖(R.map (algebraMap ℝ ℂ)).eval (-(x : ℂ))‖) atTop atTop :=
    Polynomial.tendsto_norm_atTop _ hdeg (by
      simp only [norm_neg, Complex.norm_real, Real.norm_eq_abs]
      exact tendsto_abs_atTop_atTop)
  obtain ⟨x, hx1, hx2⟩ := ((ht.eventually_gt_atTop 1).and (eventually_gt_atTop 0)).exists
  refine ⟨-(x : ℂ), by simp [hx2], ?_⟩
  simpa using hx1

/-! The card's worked numbers, in exact fractions. -/

-- The fast part at h = 0.01 s: z = h λ = 0.01 × (−1000000) = −10000.
example : (1 / 100 : ℚ) * (-1000000) = -10000 := by norm_num

-- One step at z = −10000: forward Euler 1 + z = −9999, backward Euler 1/(1 − z) = 1/10001,
-- trapezoid (1 + z/2)/(1 − z/2) = −4999/5001.
example : (1 : ℚ) + (-10000) = -9999 := by norm_num
example : (1 : ℚ) / (1 - (-10000)) = 1 / 10001 := by norm_num
example : ((1 : ℚ) + (-10000) / 2) / (1 - (-10000) / 2) = -4999 / 5001 := by norm_num

-- BDF2 at z = −10000: (3/2 − z) ζ² − 2ζ + 1/2 = 0 has a complex pair whose size squared is the
-- product of the roots, (1/2)/(3/2 − z) = 1/20003; its discriminant 4 − 2(3/2 − z) is negative.
example : ((1 / 2 : ℚ) / (3 / 2 - (-10000))) = 1 / 20003 := by norm_num
example : (4 : ℚ) - 4 * (3 / 2 - (-10000)) * (1 / 2) < 0 := by norm_num

-- Forward Euler's limit: at h = 2/1000000 the factor 1 + h λ is exactly −1; at h = 2.1e-6 s it is −1.1.
example : (1 : ℚ) + 2 / 1000000 * (-1000000) = -1 := by norm_num
example : (1 : ℚ) + 21 / 10000000 * (-1000000) = -11 / 10 := by norm_num

-- RK4 at 360000 steps of four slope evaluations each costs 1440000 evaluations.
example : (360000 : ℕ) * 4 = 1440000 := by norm_num

-- RK4's region meets the imaginary axis at ±2√2 i: with s = y² = 8,
-- |R(iy)|² = (1 − s/2 + s²/24)² + s (1 − s/6)² = 1.
example : ((1 : ℚ) - 8 / 2 + 8 ^ 2 / 24) ^ 2 + 8 * (1 - 8 / 6) ^ 2 = 1 := by norm_num

-- Error constants C = C_(p+1)/σ(1), with C_q = ∑ a_j j^q / q! − ∑ b_j j^(q−1) / (q−1)!:
-- trapezoid −1/12, BDF2 −1/3, AM2 −1/24, BDF3 −1/4.
example : ((-1) * 0 ^ 3 + 1 * 1 ^ 3 : ℚ) / 6 - ((1 / 2) * 0 ^ 2 + (1 / 2) * 1 ^ 2) / 2 = -1 / 12 := by
  norm_num
example : ((1 / 2) * 0 ^ 3 + (-2) * 1 ^ 3 + (3 / 2) * 2 ^ 3 : ℚ) / 6 - (1 * 2 ^ 2) / 2 = -1 / 3 := by
  norm_num
example : ((-1) * 1 ^ 4 + 1 * 2 ^ 4 : ℚ) / 24
    - ((-1 / 12) * 0 ^ 3 + (8 / 12) * 1 ^ 3 + (5 / 12) * 2 ^ 3) / 6 = -1 / 24 := by
  norm_num
example : ((-1 / 3) * 0 ^ 4 + (3 / 2) * 1 ^ 4 + (-3) * 2 ^ 4 + (11 / 6) * 3 ^ 4 : ℚ) / 24
    - (1 * 3 ^ 3) / 6 = -1 / 4 := by
  norm_num

-- BDF3's boundary locus has real part u²(4u − 3)/3 with u = 1 − cos θ; at u = 1/2 it is −1/12.
example : ((1 / 2 : ℚ) ^ 2 * (4 * (1 / 2) - 3)) / 3 = -1 / 12 := by norm_num

#print axioms a_stable_multistep_order_le_two
#print axioms a_stable_order_two_error_constant_le
#print axioms polynomial_stability_function_not_a_stable
