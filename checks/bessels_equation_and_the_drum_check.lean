-- Bessel's equation: the series J0 converges everywhere, equals 1 at the centre and solves x²y'' + xy' + x²y = 0, every solution that stays bounded at the centre is a constant times J0, its coefficients are forced by the Frobenius recurrence, and the substitution y = u/√x turns the equation into u'' + (1 + 1/(4x²))u = 0.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Analysis.Calculus.SmoothSeries
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Deriv

open Set

namespace BesselDrum

/-- The m-th term of the card's series for J0: (-1)^m x^(2m) / (4^m (m!)^2). -/
noncomputable def J0Term (m : ℕ) (x : ℝ) : ℝ :=
  (-1) ^ m * x ^ (2 * m) / (4 ^ m * (m.factorial : ℝ) ^ 2)

/-- Bessel's function of order zero, as the card defines it: the sum of the series
1 - x²/4 + x⁴/64 - x⁶/2304 + ⋯. -/
noncomputable def J0 (x : ℝ) : ℝ := ∑' m : ℕ, J0Term m x

/-- The Frobenius coefficient a_n of x^n in J0: zero for odd n, and
(-1)^m / (4^m (m!)^2) for n = 2m. -/
noncomputable def besselCoeff (n : ℕ) : ℝ :=
  if Even n then (-1) ^ (n / 2) / (4 ^ (n / 2) * ((n / 2).factorial : ℝ) ^ 2) else 0

/-- Helper: first termwise derivative. -/

noncomputable def bdD1 (m : ℕ) (x : ℝ) : ℝ :=
  (-1) ^ m * ((2 * m : ℕ) : ℝ) * x ^ (2 * m - 1) / (4 ^ m * (m.factorial : ℝ) ^ 2)
#print axioms bdD1

/-- Helper: second termwise derivative. -/

noncomputable def bdD2 (m : ℕ) (x : ℝ) : ℝ :=
  (-1) ^ m * ((2 * m : ℕ) : ℝ) * ((2 * m - 1 : ℕ) : ℝ) * x ^ (2 * m - 1 - 1) /
    (4 ^ m * (m.factorial : ℝ) ^ 2)
#print axioms bdD2

/-- Helper: a uniform bound for the terms. -/

theorem bd_key (m k N : ℕ) (hk : k ≤ 2 * m) (hN : N ≤ 4 * 4 ^ m) (S x : ℝ) (hS : 1 ≤ S)
    (hx : |x| ≤ S) :
    |(-1) ^ m * (N : ℝ) * x ^ k / (4 ^ m * (m.factorial : ℝ) ^ 2)| ≤
      4 * (S ^ 2) ^ m / m.factorial := by
  have hf : (1 : ℝ) ≤ m.factorial := by exact_mod_cast Nat.one_le_iff_ne_zero.mpr (Nat.factorial_ne_zero m)
  have h4 : (0 : ℝ) < 4 ^ m := by positivity
  rw [abs_div, abs_mul, abs_mul, abs_pow, abs_neg, abs_one, one_pow, one_mul, abs_pow,
    abs_of_pos (by positivity : (0 : ℝ) < 4 ^ m * (m.factorial : ℝ) ^ 2), Nat.abs_cast]
  have hxk : |x| ^ k ≤ S ^ (2 * m) :=
    (pow_le_pow_left₀ (abs_nonneg x) hx k).trans (pow_le_pow_right₀ hS hk)
  have hN' : (N : ℝ) ≤ 4 * 4 ^ m := by exact_mod_cast hN
  rw [div_le_div_iff₀ (by positivity) (by positivity), ← pow_mul]
  have hS0 : 0 ≤ S ^ (2 * m) := by positivity
  calc (N : ℝ) * |x| ^ k * m.factorial ≤ (4 * 4 ^ m) * S ^ (2 * m) * m.factorial := by
        gcongr
    _ ≤ 4 * S ^ (2 * m) * (4 ^ m * (m.factorial : ℝ) ^ 2) := by
        have : (m.factorial : ℝ) ≤ (m.factorial : ℝ) ^ 2 := by nlinarith
        have h2 : 0 ≤ 4 * S ^ (2 * m) * 4 ^ m := by positivity
        nlinarith
#print axioms bd_key

theorem bd_sq_le (m : ℕ) : m * m ≤ 4 ^ m := by
  have := Nat.lt_two_pow_self (n := m)
  have h : 4 ^ m = 2 ^ m * 2 ^ m := by rw [← mul_pow]; norm_num
  rw [h]; exact Nat.mul_le_mul this.le this.le
#print axioms bd_sq_le

theorem bd_bound0 (m : ℕ) (S x : ℝ) (hS : 1 ≤ S) (hx : |x| ≤ S) :
    ‖J0Term m x‖ ≤ 4 * (S ^ 2) ^ m / m.factorial := by
  have := bd_key m (2 * m) 1 le_rfl (by have := Nat.one_le_pow m 4 (by norm_num); omega) S x hS hx
  have e : J0Term m x = (-1) ^ m * ((1 : ℕ) : ℝ) * x ^ (2 * m) / (4 ^ m * (m.factorial : ℝ) ^ 2) := by
    simp [J0Term]
  rw [Real.norm_eq_abs, e]; exact this
#print axioms bd_bound0

theorem bd_bound1 (m : ℕ) (S x : ℝ) (hS : 1 ≤ S) (hx : |x| ≤ S) :
    ‖bdD1 m x‖ ≤ 4 * (S ^ 2) ^ m / m.factorial := by
  have := bd_key m (2 * m - 1) (2 * m) (by omega) (by have := bd_sq_le m; nlinarith) S x hS hx
  rw [Real.norm_eq_abs]; exact this
#print axioms bd_bound1

theorem bd_bound2 (m : ℕ) (S x : ℝ) (hS : 1 ≤ S) (hx : |x| ≤ S) :
    ‖bdD2 m x‖ ≤ 4 * (S ^ 2) ^ m / m.factorial := by
  have := bd_key m (2 * m - 1 - 1) (2 * m * (2 * m - 1)) (by omega)
    (by have := bd_sq_le m; have : 2 * m * (2 * m - 1) ≤ 2 * m * (2 * m) := Nat.mul_le_mul_left _ (by omega)
        nlinarith) S x hS hx
  rw [Nat.cast_mul] at this
  rw [Real.norm_eq_abs]; unfold bdD2; rw [mul_assoc ((-1 : ℝ) ^ m)]; exact this
#print axioms bd_bound2

theorem bd_summable_u (S : ℝ) : Summable (fun m : ℕ => 4 * (S ^ 2) ^ m / m.factorial) := by
  simpa [mul_div_assoc] using (Real.summable_pow_div_factorial (S ^ 2)).mul_left 4
#print axioms bd_summable_u

theorem bd_hasDerivAt0 (m : ℕ) (x : ℝ) : HasDerivAt (J0Term m) (bdD1 m x) x := by
  show HasDerivAt (fun x => (-1) ^ m * x ^ (2 * m) / (4 ^ m * (m.factorial : ℝ) ^ 2)) _ x
  have := ((hasDerivAt_pow (2 * m) x).const_mul ((-1 : ℝ) ^ m)).div_const
    (4 ^ m * (m.factorial : ℝ) ^ 2)
  convert this using 1
  · unfold bdD1; ring
#print axioms bd_hasDerivAt0

theorem bd_hasDerivAt1 (m : ℕ) (x : ℝ) : HasDerivAt (bdD1 m) (bdD2 m x) x := by
  have := ((hasDerivAt_pow (2 * m - 1) x).const_mul ((-1 : ℝ) ^ m * ((2 * m : ℕ) : ℝ))).div_const
    (4 ^ m * (m.factorial : ℝ) ^ 2)
  convert this using 1
  · ext t; simp [bdD1]
  · simp [bdD2, mul_assoc]
#print axioms bd_hasDerivAt1

theorem bd_summable0 (x : ℝ) : Summable (fun m : ℕ => J0Term m x) :=
  Summable.of_norm_bounded (bd_summable_u (|x| + 1))
    (fun m => bd_bound0 m (|x| + 1) x (by linarith [abs_nonneg x]) (by linarith))
#print axioms bd_summable0

theorem bd_summable1 (x : ℝ) : Summable (fun m : ℕ => bdD1 m x) :=
  Summable.of_norm_bounded (bd_summable_u (|x| + 1))
    (fun m => bd_bound1 m (|x| + 1) x (by linarith [abs_nonneg x]) (by linarith))
#print axioms bd_summable1

theorem bd_summable2 (x : ℝ) : Summable (fun m : ℕ => bdD2 m x) :=
  Summable.of_norm_bounded (bd_summable_u (|x| + 1))
    (fun m => bd_bound2 m (|x| + 1) x (by linarith [abs_nonneg x]) (by linarith))
#print axioms bd_summable2

/-- Helper: the first derivative of J0 as a series. -/

noncomputable def bdJ1 (x : ℝ) : ℝ := ∑' m : ℕ, bdD1 m x
#print axioms bdJ1

/-- Helper: the second derivative of J0 as a series. -/

noncomputable def bdJ2 (x : ℝ) : ℝ := ∑' m : ℕ, bdD2 m x
#print axioms bdJ2

theorem bd_mem_ball {x z : ℝ} (hz : z ∈ Metric.ball (0 : ℝ) (|x| + 1)) : |z| ≤ |x| + 1 := by
  rw [Metric.mem_ball, Real.dist_eq, sub_zero] at hz; exact hz.le
#print axioms bd_mem_ball

theorem bd_hasDerivAt_J0 (x : ℝ) : HasDerivAt J0 (bdJ1 x) x := by
  have hx : x ∈ Metric.ball (0 : ℝ) (|x| + 1) := by
    rw [Metric.mem_ball, Real.dist_eq, sub_zero]; linarith
  exact hasDerivAt_tsum_of_isPreconnected (bd_summable_u (|x| + 1)) Metric.isOpen_ball
    (convex_ball _ _).isPreconnected (fun m z _ => bd_hasDerivAt0 m z)
    (fun m z hz => bd_bound1 m _ z (by linarith [abs_nonneg x]) (bd_mem_ball hz)) hx
    (bd_summable0 x) hx
#print axioms bd_hasDerivAt_J0

theorem bd_hasDerivAt_J1 (x : ℝ) : HasDerivAt bdJ1 (bdJ2 x) x := by
  have hx : x ∈ Metric.ball (0 : ℝ) (|x| + 1) := by
    rw [Metric.mem_ball, Real.dist_eq, sub_zero]; linarith
  exact hasDerivAt_tsum_of_isPreconnected (bd_summable_u (|x| + 1)) Metric.isOpen_ball
    (convex_ball _ _).isPreconnected (fun m z _ => bd_hasDerivAt1 m z)
    (fun m z hz => bd_bound2 m _ z (by linarith [abs_nonneg x]) (bd_mem_ball hz)) hx
    (bd_summable1 x) hx
#print axioms bd_hasDerivAt_J1

theorem bd_continuous_J2 : Continuous bdJ2 := by
  rw [continuous_iff_continuousAt]
  intro x
  have hx : x ∈ Metric.ball (0 : ℝ) (|x| + 1) := by
    rw [Metric.mem_ball, Real.dist_eq, sub_zero]; linarith
  have : ContinuousOn bdJ2 (Metric.ball (0 : ℝ) (|x| + 1)) :=
    continuousOn_tsum (fun m => by unfold bdD2; fun_prop) (bd_summable_u (|x| + 1))
      (fun m z hz => bd_bound2 m _ z (by linarith [abs_nonneg x]) (bd_mem_ball hz))
  exact this.continuousAt (Metric.isOpen_ball.mem_nhds hx)
#print axioms bd_continuous_J2

theorem bd_deriv_J0 : deriv J0 = bdJ1 := funext fun x => (bd_hasDerivAt_J0 x).deriv
#print axioms bd_deriv_J0

theorem bd_deriv_J1 : deriv bdJ1 = bdJ2 := funext fun x => (bd_hasDerivAt_J1 x).deriv
#print axioms bd_deriv_J1

theorem bd_J0_zero : J0 0 = 1 := by
  unfold J0
  rw [tsum_eq_single 0]
  · simp [J0Term]
  · intro m hm
    simp [J0Term, hm]
#print axioms bd_J0_zero

theorem bd_contDiff : ContDiff ℝ 2 J0 := by
  rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
  refine ⟨fun x => (bd_hasDerivAt_J0 x).differentiableAt, by simp, ?_⟩
  rw [bd_deriv_J0, contDiff_one_iff_deriv, bd_deriv_J1]
  exact ⟨fun x => (bd_hasDerivAt_J1 x).differentiableAt, bd_continuous_J2⟩
#print axioms bd_contDiff

theorem bd_coeff_rec (m : ℕ) (x : ℝ) :
    x ^ 2 * bdD2 (m + 1) x + x * bdD1 (m + 1) x = -(x ^ 2 * J0Term m x) := by
  unfold bdD2 bdD1 J0Term
  have e1 : 2 * (m + 1) - 1 = 2 * m + 1 := by omega
  have e2 : 2 * m + 1 - 1 = 2 * m := by omega
  rw [e1, e2, Nat.factorial_succ]
  push_cast
  have : (m.factorial : ℝ) ≠ 0 := by positivity
  field_simp
  ring
#print axioms bd_coeff_rec

theorem bd_bessel (x : ℝ) : x ^ 2 * bdJ2 x + x * bdJ1 x + x ^ 2 * J0 x = 0 := by
  unfold bdJ2 bdJ1 J0
  rw [← tsum_mul_left, ← tsum_mul_left, ← tsum_mul_left,
    ← ((bd_summable2 x).mul_left _).tsum_add ((bd_summable1 x).mul_left _)]
  have hA : Summable (fun m => x ^ 2 * bdD2 m x + x * bdD1 m x) :=
    ((bd_summable2 x).mul_left _).add ((bd_summable1 x).mul_left _)
  rw [hA.tsum_eq_zero_add]
  simp only [bd_coeff_rec, tsum_neg]
  simp [bdD1, bdD2]
#print axioms bd_bessel

theorem bd_anti {f f' : ℝ → ℝ} {p q : ℝ} (hf : ∀ x ∈ Ioo p q, HasDerivAt f (f' x) x)
    (h : ∀ x ∈ Ioo p q, f' x ≤ 0) : AntitoneOn f (Ioo p q) :=
  antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ioo p q)
    (fun x hx => (hf x hx).continuousAt.continuousWithinAt)
    (by rw [interior_Ioo]; exact fun x hx => (hf x hx).hasDerivWithinAt)
    (by rw [interior_Ioo]; exact h)
#print axioms bd_anti

theorem bd_const {f : ℝ → ℝ} {p q : ℝ} (hf : ∀ x ∈ Ioo p q, HasDerivAt f 0 x) :
    ∀ x ∈ Ioo p q, ∀ w ∈ Ioo p q, f x = f w := by
  have h1 := bd_anti (f' := fun _ => 0) hf (fun _ _ => le_rfl)
  have h2 := bd_anti (f := fun t => -f t) (f' := fun _ => 0)
    (fun x hx => by have := (hf x hx).neg; rw [neg_zero] at this; exact this) (fun _ _ => le_rfl)
  intro x hx w hw
  rcases le_total x w with h | h
  · have := h1 hx hw h; have := h2 hx hw h; simp at this; linarith
  · have := h1 hw hx h; have := h2 hw hx h; simp at this; linarith
#print axioms bd_const

theorem bd_unique (F F1 F2 : ℝ → ℝ) (hF : ∀ x, HasDerivAt F (F1 x) x)
    (hF1 : ∀ x, HasDerivAt F1 (F2 x) x) (hE : ∀ x, x ^ 2 * F2 x + x * F1 x + x ^ 2 * F x = 0)
    (hc : Continuous F) (h0 : F 0 = 1) :
    ∀ (a : ℝ) (y y' y'' : ℝ → ℝ), 0 < a →
      (∀ x ∈ Ioo 0 a, HasDerivAt y (y' x) x) →
      (∀ x ∈ Ioo 0 a, HasDerivAt y' (y'' x) x) →
      (∀ x ∈ Ioo 0 a, x ^ 2 * y'' x + x * y' x + x ^ 2 * y x = 0) →
      (∃ M δ : ℝ, 0 < δ ∧ ∀ x ∈ Ioo 0 δ, |y x| ≤ M) →
      ∃ C : ℝ, ∀ x ∈ Ioo 0 a, y x = C * F x := by
  intro a y y' y'' ha hy hy' hode ⟨M, δ, hδ, hM⟩
  -- the scaled Wronskian is constant
  set V : ℝ → ℝ := fun x => x * (y x * F1 x - y' x * F x) with hVdef
  have hV : ∀ x ∈ Ioo 0 a, HasDerivAt V 0 x := by
    intro x hx
    have hx0 : x ≠ 0 := hx.1.ne'
    have h := (hasDerivAt_id' x).mul (((hy x hx).mul (hF1 x)).sub ((hy' x hx).mul (hF x)))
    convert h using 1
    simp only [Pi.mul_apply, Pi.sub_apply]
    apply mul_left_cancel₀ hx0
    linear_combination -(y x) * hE x + F x * hode x hx
  set c := V (a / 2) with hcdef
  have hVc : ∀ x ∈ Ioo 0 a, V x = c := fun x hx =>
    bd_const hV x hx (a / 2) ⟨by linarith, by linarith⟩
  clear_value c
  -- a small interval where F stays between 1/2 and 2
  obtain ⟨η, hη, hηF⟩ := Metric.continuousAt_iff.1 hc.continuousAt (1 / 2) (by norm_num)
  set ε := min η (min δ (a / 2)) with hεdef
  have hε : 0 < ε := lt_min hη (lt_min hδ (by linarith))
  have hεη : ε ≤ η := min_le_left _ _
  have hεδ : ε ≤ δ := (min_le_right _ _).trans (min_le_left _ _)
  have hεa : ε < a := lt_of_le_of_lt ((min_le_right _ _).trans (min_le_right _ _)) (by linarith)
  have hsub : ∀ x ∈ Ioo 0 ε, x ∈ Ioo 0 a := fun x hx => ⟨hx.1, by linarith [hx.2]⟩
  have hFb : ∀ x ∈ Ioo 0 ε, 1 / 2 ≤ F x ∧ F x ≤ 2 := by
    intro x hx
    have : dist x 0 < η := by
      rw [Real.dist_eq, sub_zero, abs_of_pos hx.1]; linarith [hx.2]
    have h := hηF this
    rw [Real.dist_eq, h0] at h
    have := abs_lt.1 h
    constructor <;> linarith
  -- the quotient y / F
  set q : ℝ → ℝ := fun x => y x / F x with hqdef
  have hq : ∀ x ∈ Ioo 0 ε, HasDerivAt q (-c / (x * F x ^ 2)) x := by
    intro x hx
    have hFx : F x ≠ 0 := by linarith [(hFb x hx).1]
    have hx0 : x ≠ 0 := hx.1.ne'
    have h := (hy x (hsub x hx)).div (hF x) hFx
    convert h using 1
    have hv := hVc x (hsub x hx)
    simp only [hVdef] at hv
    field_simp
    linear_combination hv
  -- c must vanish, or y / F would grow like log x near the centre
  have hc0 : c = 0 := by
    by_contra hcne
    set h : ℝ → ℝ := fun x => c * q x + c ^ 2 / 4 * Real.log x with hhdef
    have hh : ∀ x ∈ Ioo 0 ε, HasDerivAt h (c * (-c / (x * F x ^ 2)) + c ^ 2 / 4 * x⁻¹) x :=
      fun x hx => ((hq x hx).const_mul c).add ((Real.hasDerivAt_log hx.1.ne').const_mul _)
    have hanti := bd_anti hh (by
      intro x hx
      have hFx := hFb x hx
      have hFp : 0 < F x := by linarith
      have hx0 := hx.1
      have e : c * (-c / (x * F x ^ 2)) + c ^ 2 / 4 * x⁻¹ =
          c ^ 2 * (F x ^ 2 - 4) / (4 * x * F x ^ 2) := by
        field_simp; ring
      rw [e]
      apply div_nonpos_of_nonpos_of_nonneg
      · apply mul_nonpos_of_nonneg_of_nonpos (sq_nonneg c); nlinarith
      · positivity)
    set x0 := ε / 2 with hx0def
    have hx0 : x0 ∈ Ioo 0 ε := ⟨by linarith, by linarith⟩
    set K := 2 * |c| * M - h x0 with hKdef
    have hc2 : 0 < c ^ 2 := by positivity
    set T := |Real.log x0| + 4 * |K| / c ^ 2 + 1 with hTdef
    set x := Real.exp (-T) with hxdef
    have hxpos : 0 < x := Real.exp_pos _
    have hxlt : x < x0 := by
      rw [hxdef, ← Real.exp_log hx0.1]
      apply Real.exp_lt_exp.2
      have : 0 ≤ 4 * |K| / c ^ 2 := by positivity
      have := neg_abs_le (Real.log x0)
      linarith
    have hxI : x ∈ Ioo 0 ε := ⟨hxpos, by linarith [hx0.2]⟩
    have hmono := hanti hxI hx0 hxlt.le
    have hlog : Real.log x = -T := Real.log_exp _
    have hFx := hFb x hxI
    have hyx : |y x| ≤ M := hM x ⟨hxpos, by linarith [hxI.2]⟩
    have hqx : |c * q x| ≤ 2 * |c| * M := by
      rw [abs_mul, hqdef, abs_div, abs_of_pos (by linarith : 0 < F x)]
      rw [mul_div_assoc', div_le_iff₀ (by linarith)]
      have h1 : |c| * |y x| ≤ |c| * M := mul_le_mul_of_nonneg_left hyx (abs_nonneg c)
      have h2 : 0 ≤ |c| * M := le_trans (by positivity) h1
      nlinarith [mul_le_mul_of_nonneg_left (by linarith : 1 ≤ 2 * F x) h2]
    have h1 : h x0 ≤ c * q x + c ^ 2 / 4 * Real.log x := hmono
    rw [hlog] at h1
    have h2 := (abs_le.1 hqx).2
    have h3 : c ^ 2 / 4 * T ≤ K := by rw [hKdef]; linarith
    have h4 : c ^ 2 / 4 * T = c ^ 2 / 4 * (|Real.log x0| + 1) + |K| := by
      rw [hTdef]; field_simp; ring
    have := abs_nonneg (Real.log x0)
    have := le_abs_self K
    nlinarith
  -- so y / F is constant near the centre
  have hq0 : ∀ x ∈ Ioo 0 ε, HasDerivAt q 0 x := fun x hx => by
    simpa [hc0] using hq x hx
  set C := q (ε / 2) with hCdef
  have hyC : ∀ x ∈ Ioo 0 ε, y x = C * F x := by
    intro x hx
    have h := bd_const hq0 x hx (ε / 2) ⟨by linarith, by linarith⟩
    have hFx : F x ≠ 0 := by linarith [(hFb x hx).1]
    rw [← hCdef, hqdef] at h
    simp only at h
    rw [← h]; field_simp
  -- the energy of z = y - C F cannot grow, and it is zero near the centre
  refine ⟨C, ?_⟩
  set z : ℝ → ℝ := fun x => y x - C * F x with hzdef
  set z' : ℝ → ℝ := fun x => y' x - C * F1 x with hz'def
  have hz : ∀ x ∈ Ioo 0 a, HasDerivAt z (z' x) x := fun x hx =>
    (hy x hx).sub ((hF x).const_mul C)
  have hz' : ∀ x ∈ Ioo 0 a, HasDerivAt z' (y'' x - C * F2 x) x := fun x hx =>
    (hy' x hx).sub ((hF1 x).const_mul C)
  set En : ℝ → ℝ := fun x => z x * z x + z' x * z' x with hEndef
  have hEn : ∀ x ∈ Ioo 0 a, HasDerivAt En
      (z' x * z x + z x * z' x + ((y'' x - C * F2 x) * z' x + z' x * (y'' x - C * F2 x))) x :=
    fun x hx => ((hz x hx).mul (hz x hx)).add ((hz' x hx).mul (hz' x hx))
  have hanti := bd_anti hEn (by
    intro x hx
    have hx0 := hx.1
    have key : x ^ 2 * (z' x * z x + z x * z' x +
        ((y'' x - C * F2 x) * z' x + z' x * (y'' x - C * F2 x))) = -2 * x * z' x ^ 2 := by
      simp only [hzdef, hz'def]
      linear_combination (2 * (y' x - C * F1 x)) * hode x hx - (2 * C * (y' x - C * F1 x)) * hE x
    by_contra hD
    push Not at hD
    have := mul_pos (pow_pos hx0 2) hD
    rw [key] at this
    nlinarith [sq_nonneg (z' x)])
  have hE0 : ∀ x ∈ Ioo 0 ε, En x = 0 := by
    intro x hx
    have hzx : ∀ t ∈ Ioo 0 ε, z t = 0 := fun t ht => by simp [hzdef, hyC t ht]
    have hd : HasDerivAt z 0 x :=
      (hasDerivAt_const x (0 : ℝ)).congr_of_eventuallyEq
        (Filter.eventually_of_mem (Ioo_mem_nhds hx.1 hx.2) (fun t ht => hzx t ht))
    have hz'x : z' x = 0 := (hz x (hsub x hx)).unique hd
    simp [hEndef, hzx x hx, hz'x]
  intro x hx
  set x1 := min x (ε / 2) with hx1def
  have hx1 : x1 ∈ Ioo 0 ε :=
    ⟨lt_min hx.1 (by linarith), lt_of_le_of_lt (min_le_right _ _) (by linarith)⟩
  have hle := hanti (hsub x1 hx1) hx (min_le_left _ _)
  rw [hE0 x1 hx1] at hle
  have hzx : z x = 0 := by
    simp only [hEndef] at hle
    nlinarith [mul_self_nonneg (z x), mul_self_nonneg (z' x)]
  simp only [hzdef] at hzx
  linarith
#print axioms bd_unique

theorem bd_coeff_step (n : ℕ) :
    ((n + 2 : ℕ) : ℝ) ^ 2 * besselCoeff (n + 2) = -besselCoeff n := by
  rcases Nat.even_or_odd n with ⟨k, rfl⟩ | ⟨k, rfl⟩
  · have e1 : Even (k + k + 2) := ⟨k + 1, by omega⟩
    have e2 : Even (k + k) := ⟨k, rfl⟩
    have d1 : (k + k + 2) / 2 = k + 1 := by omega
    have d2 : (k + k) / 2 = k := by omega
    unfold besselCoeff
    simp only [e1, e2, ↓reduceIte]
    rw [d1, d2, Nat.factorial_succ]
    push_cast
    have : (k.factorial : ℝ) ≠ 0 := by positivity
    field_simp
    ring
  · have e1 : ¬ Even (2 * k + 1 + 2) := by
      rw [Nat.not_even_iff_odd]; exact ⟨k + 1, by omega⟩
    have e2 : ¬ Even (2 * k + 1) := by
      rw [Nat.not_even_iff_odd]; exact ⟨k, rfl⟩
    unfold besselCoeff
    simp [e1, e2]
#print axioms bd_coeff_step

/-- The card's main claim. The series J0 converges for every x, equals 1 at the centre, is twice
differentiable and solves Bessel's equation x²y'' + xy' + x²y = 0 everywhere. And it is the one
solution that stays finite at the centre: any solution y of Bessel's equation on an interval
(0, a) that stays bounded near x = 0 is a constant times J0 there. (The other solution, Y0,
carries a logarithm and falls without bound at the centre.) -/
theorem J0_is_the_solution_finite_at_centre :
    (∀ x : ℝ, Summable (fun m : ℕ => J0Term m x)) ∧
    J0 0 = 1 ∧
    ContDiff ℝ 2 J0 ∧
    (∀ x : ℝ, x ^ 2 * deriv (deriv J0) x + x * deriv J0 x + x ^ 2 * J0 x = 0) ∧
    (∀ (a : ℝ) (y y' y'' : ℝ → ℝ), 0 < a →
      (∀ x ∈ Ioo 0 a, HasDerivAt y (y' x) x) →
      (∀ x ∈ Ioo 0 a, HasDerivAt y' (y'' x) x) →
      (∀ x ∈ Ioo 0 a, x ^ 2 * y'' x + x * y' x + x ^ 2 * y x = 0) →
      (∃ M δ : ℝ, 0 < δ ∧ ∀ x ∈ Ioo 0 δ, |y x| ≤ M) →
      ∃ C : ℝ, ∀ x ∈ Ioo 0 a, y x = C * J0 x) := by
  refine ⟨bd_summable0, bd_J0_zero, bd_contDiff, ?_, ?_⟩
  · intro x
    rw [bd_deriv_J0, bd_deriv_J1]
    exact bd_bessel x
  · exact bd_unique J0 bdJ1 bdJ2 bd_hasDerivAt_J0 bd_hasDerivAt_J1 bd_bessel
      bd_contDiff.continuous bd_J0_zero

/-- Frobenius at the centre: with trial power s = 0, matching powers gives a_0 = 1 (chosen),
a_1 = 0 and n² a_n = -a_(n-2) for every later n. These rules have exactly one solution,
and it is the sequence of J0's coefficients. -/
theorem frobenius_recurrence_gives_J0_coefficients (a : ℕ → ℝ) :
    (a 0 = 1 ∧ a 1 = 0 ∧ ∀ n : ℕ, 2 ≤ n → (n : ℝ) ^ 2 * a n = -a (n - 2)) ↔
      a = besselCoeff := by
  constructor
  · rintro ⟨h0, h1, hrec⟩
    funext n
    induction n using Nat.strong_induction_on with
    | _ n ih =>
      match n, ih with
      | 0, _ => simp [h0, besselCoeff]
      | 1, _ => simp [h1, besselCoeff]
      | n + 2, ih =>
        have h := hrec (n + 2) (by omega)
        rw [show n + 2 - 2 = n by omega, ih n (by omega), ← bd_coeff_step n] at h
        have hne : ((n + 2 : ℕ) : ℝ) ^ 2 ≠ 0 := by positivity
        exact mul_left_cancel₀ hne h
  · rintro rfl
    refine ⟨by simp [besselCoeff], by simp [besselCoeff], ?_⟩
    intro n hn
    obtain ⟨k, rfl⟩ : ∃ k, n = k + 2 := ⟨n - 2, by omega⟩
    rw [show k + 2 - 2 = k by omega]
    exact bd_coeff_step k

/-- The substitution y = u/√x: for x > 0 and any u twice differentiable for x > 0,
x²y'' + xy' + x²y = x^(3/2) (u'' + (1 + 1/(4x²)) u). So y solves Bessel's equation exactly when
u solves u'' + (1 + 1/(4x²)) u = 0: the u' terms cancel. -/
theorem bessel_sqrt_substitution (u : ℝ → ℝ) (hu : ContDiffOn ℝ 2 u (Ioi 0)) (x : ℝ)
    (hx : 0 < x) :
    let y : ℝ → ℝ := fun t => u t * t ^ (-(1 : ℝ) / 2)
    x ^ 2 * deriv (deriv y) x + x * deriv y x + x ^ 2 * y x =
      x ^ ((3 : ℝ) / 2) * (deriv (deriv u) x + (1 + 1 / (4 * x ^ 2)) * u x) := by
  intro y
  set p : ℝ := -(1 : ℝ) / 2 with hpdef
  have hdiff : DifferentiableOn ℝ u (Ioi 0) := hu.differentiableOn (by norm_num)
  have hu1 : ∀ t, 0 < t → HasDerivAt u (deriv u t) t := fun t ht =>
    ((hdiff t ht).differentiableAt (Ioi_mem_nhds ht)).hasDerivAt
  have hdu : ContDiffOn ℝ 1 (deriv u) (Ioi 0) :=
    hu.deriv_of_isOpen isOpen_Ioi (by norm_num)
  have hu2 : HasDerivAt (deriv u) (deriv (deriv u) x) x :=
    (((hdu.differentiableOn (by norm_num)) x hx).differentiableAt (Ioi_mem_nhds hx)).hasDerivAt
  have hp : ∀ t, 0 < t → HasDerivAt (fun t : ℝ => t ^ p) (p * t ^ (p - 1)) t := fun t ht =>
    Real.hasDerivAt_rpow_const (Or.inl ht.ne')
  have hp2 : HasDerivAt (fun t : ℝ => p * t ^ (p - 1)) (p * ((p - 1) * x ^ (p - 1 - 1))) x :=
    (Real.hasDerivAt_rpow_const (Or.inl hx.ne')).const_mul p
  have dy : ∀ t, 0 < t → HasDerivAt y (deriv u t * t ^ p + u t * (p * t ^ (p - 1))) t :=
    fun t ht => (hu1 t ht).mul (hp t ht)
  have hev : deriv y =ᶠ[nhds x] fun t => deriv u t * t ^ p + u t * (p * t ^ (p - 1)) :=
    Filter.eventually_of_mem (Ioi_mem_nhds hx) (fun t ht => (dy t ht).deriv)
  have d2 : HasDerivAt (fun t => deriv u t * t ^ p + u t * (p * t ^ (p - 1)))
      (deriv (deriv u) x * x ^ p + deriv u x * (p * x ^ (p - 1)) +
        (deriv u x * (p * x ^ (p - 1)) + u x * (p * ((p - 1) * x ^ (p - 1 - 1))))) x :=
    (hu2.mul (hp x hx)).add ((hu1 x hx).mul hp2)
  rw [hev.deriv_eq, d2.deriv, (dy x hx).deriv]
  have hyx : y x = u x * x ^ p := rfl
  rw [hyx]
  have r1 : x ^ (p - 1) = x ^ p / x := Real.rpow_sub_one hx.ne' p
  have r2 : x ^ (p - 1 - 1) = x ^ p / x / x := by
    rw [Real.rpow_sub_one hx.ne', r1]
  have r3 : x ^ ((3 : ℝ) / 2) = x ^ p * x ^ 2 := by
    rw [show (3 : ℝ) / 2 = p + 2 by rw [hpdef]; norm_num, Real.rpow_add hx, Real.rpow_two]
  rw [r1, r2, r3, hpdef]
  field_simp
  ring

-- The card's coefficients: a_2 = -1/4, a_4 = 1/64, a_6 = -1/2304, a_8 = 1/147456; odd ones vanish.
example : besselCoeff 1 = 0 := by norm_num [besselCoeff]
example : besselCoeff 2 = -1 / 4 := by norm_num [besselCoeff, Nat.factorial, Nat.even_iff]
example : besselCoeff 4 = 1 / 64 := by norm_num [besselCoeff, Nat.factorial, Nat.even_iff]
example : besselCoeff 6 = -1 / 2304 := by norm_num [besselCoeff, Nat.factorial, Nat.even_iff]
example : besselCoeff 8 = 1 / 147456 := by norm_num [besselCoeff, Nat.factorial, Nat.even_iff]
-- The denominators of the series terms: 4^m (m!)^2 for m = 1, 2, 3, 4.
example : (4 ^ 1 * (Nat.factorial 1) ^ 2, 4 ^ 2 * (Nat.factorial 2) ^ 2,
    4 ^ 3 * (Nat.factorial 3) ^ 2, 4 ^ 4 * (Nat.factorial 4) ^ 2) = (4, 64, 2304, 147456) := by decide
-- The large-x estimate puts the n-th zero near (n - 1/4)π, so its ratios are (4n - 1)/3:
-- 7/3 and 11/3, not 2 and 3.
example : ((2 : ℚ) - 1 / 4) / (1 - 1 / 4) = 7 / 3 := by norm_num
example : ((3 : ℚ) - 1 / 4) / (1 - 1 / 4) = 11 / 3 := by norm_num

#print axioms J0_is_the_solution_finite_at_centre
#print axioms frobenius_recurrence_gives_J0_coefficients
#print axioms bessel_sqrt_substitution

end BesselDrum
