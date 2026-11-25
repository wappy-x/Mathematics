-- Pseudodifferential operators: dividing the rod operator P u = -(c u')' + u by the main part of its gain inverts it on every test wave up to an error at most a constant over the wavenumber, the composition rule for P holds exactly, and for c = 2 + sin x the error times the wavenumber tends to 1/√3.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Analysis.Complex.RealDeriv
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Basic.Real.Pointwise
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Filter Topology
open scoped ContDiff

namespace PseudodifferentialCard

/-! Mathlib has no pseudodifferential calculus: no symbol classes `S^m`, no quantisation of a
symbol that depends on position, no Calderón-Vaillancourt theorem and no hypoellipticity. So this
file states the card's parametrix exactly where the card measures it: on the test waves
`e_k(x) = e^{ikx}`, where `Op(a) e_k = a(x, k) e_k`, so the operator `Q₀ = Op(q₀)` sends `e_k`
to `q₀(x, k) e_k` and the error of `P Q₀ - I` on `e_k` is `P(q₀ e_k) - e_k`. -/

/-- The rod operator `P u = -(c u')' + u`, for a conductivity `c` along the rod and a
complex-valued temperature profile `u`. -/
noncomputable def rodOp (c : ℝ → ℝ) (u : ℝ → ℂ) (x : ℝ) : ℂ :=
  -deriv (fun y => (c y : ℂ) * deriv u y) x + u x

/-- The test wave `e_k(x) = e^{ikx}`, with `k` the angular wavenumber in radians per metre. -/
noncomputable def wave (k x : ℝ) : ℂ := Complex.exp (Complex.I * k * x)

/-- The first parametrix symbol `q₀(x, k) = 1 / (c(x) k² + 1)`: one over the main part of the
rod's gain `p(x, k) = c(x) k² - i k c'(x) + 1`. -/
noncomputable def q0 (c : ℝ → ℝ) (k x : ℝ) : ℝ := 1 / (c x * k ^ 2 + 1)

/-! Helper lemmas for the proofs below. -/

lemma wave_hasDerivAt (k y : ℝ) :
    HasDerivAt (fun y => wave k y) (wave k y * (Complex.I * k)) y := by
  have h1 : HasDerivAt (fun y : ℝ => ((y : ℝ) : ℂ)) 1 y := by
    simpa using (hasDerivAt_id y).ofReal_comp
  have h2 := (h1.const_mul (Complex.I * k)).cexp
  simpa [wave] using h2

#print axioms wave_hasDerivAt

lemma norm_wave (k x : ℝ) : ‖wave k x‖ = 1 := by
  simp [wave, Complex.norm_exp]

#print axioms norm_wave

lemma rod_composition_rule_aux (c : ℝ → ℝ) (hc : Differentiable ℝ c) (b : ℝ → ℂ)
    (hb : ContDiff ℝ 2 b) (k x : ℝ) :
    rodOp c (fun y => b y * wave k y) x =
      wave k x * (((c x : ℂ) * (k : ℂ) ^ 2 + 1 - Complex.I * k * ((deriv c x : ℝ) : ℂ)) * b x
        - (2 * Complex.I * k * (c x : ℂ) + ((deriv c x : ℝ) : ℂ)) * deriv b x
        - (c x : ℂ) * deriv (deriv b) x) := by
  have hb1 : ContDiff ℝ 1 (deriv b) := hb.deriv'
  have hbd : Differentiable ℝ b := hb.differentiable (by norm_num)
  have hbd' : Differentiable ℝ (deriv b) := hb1.differentiable (by norm_num)
  have hd : ∀ y, HasDerivAt (fun y => b y * wave k y)
      (wave k y * (deriv b y + Complex.I * k * b y)) y := by
    intro y
    have := (hbd y).hasDerivAt.mul (wave_hasDerivAt k y)
    convert this using 1; ring
  have hfun : (fun y => (c y : ℂ) * deriv (fun y => b y * wave k y) y) =
      fun y => (c y : ℂ) * (wave k y * (deriv b y + Complex.I * k * b y)) := by
    funext y; rw [(hd y).deriv]
  have hc' : HasDerivAt (fun y => (c y : ℂ)) ((deriv c x : ℝ) : ℂ) x :=
    (hc x).hasDerivAt.ofReal_comp
  have h3 : HasDerivAt (fun y => (c y : ℂ) * (wave k y * (deriv b y + Complex.I * k * b y)))
      (((deriv c x : ℝ) : ℂ) * (wave k x * (deriv b x + Complex.I * k * b x)) + (c x : ℂ) *
        (wave k x * (Complex.I * k) * (deriv b x + Complex.I * k * b x)
          + wave k x * (deriv (deriv b) x + Complex.I * k * deriv b x))) x :=
    hc'.mul ((wave_hasDerivAt k x).mul
      ((hbd' x).hasDerivAt.add (((hbd x).hasDerivAt).const_mul (Complex.I * k))))
  unfold rodOp
  rw [hfun, h3.deriv]
  linear_combination (-(c x : ℂ) * wave k x * (k : ℂ) ^ 2 * b x) * Complex.I_sq

#print axioms rod_composition_rule_aux

lemma error_eq (c : ℝ → ℝ) (hc : ContDiff ℝ 2 c) (hpos : ∀ y, 0 ≤ c y) (k x : ℝ) :
    rodOp c (fun y => (q0 c k y : ℂ) * wave k y) x - wave k x =
      wave k x * (((k ^ 2 * q0 c k x ^ 2 * (deriv c x ^ 2 * (1 - 2 * c x * k ^ 2 * q0 c k x)
        + c x * deriv (deriv c) x) : ℝ) : ℂ)
        + ((k * deriv c x * q0 c k x * (2 * c x * k ^ 2 * q0 c k x - 1) : ℝ) : ℂ)
          * Complex.I) := by
  have hc1 : Differentiable ℝ c := hc.differentiable (by norm_num)
  have hc2 : Differentiable ℝ (deriv c) := (hc.deriv' : ContDiff ℝ 1 (deriv c)).differentiable
    (by norm_num)
  have hD : ∀ y, 0 < c y * k ^ 2 + 1 := fun y => by have := hpos y; positivity
  have hq1 : ∀ y, HasDerivAt (q0 c k) (-(deriv c y * k ^ 2) * q0 c k y ^ 2) y := by
    intro y
    have := (((hc1 y).hasDerivAt.mul_const (k ^ 2)).add_const 1).inv (hD y).ne'
    convert this using 1
    · funext z; simp [q0]
    · simp only [q0]; field_simp
  have hdq : deriv (q0 c k) = fun y => -(deriv c y * k ^ 2) * q0 c k y ^ 2 :=
    funext fun y => (hq1 y).deriv
  have hq2 : HasDerivAt (fun y => -(deriv c y * k ^ 2) * q0 c k y ^ 2)
      (-(deriv (deriv c) x * k ^ 2) * q0 c k x ^ 2
        + 2 * (deriv c x) ^ 2 * k ^ 4 * q0 c k x ^ 3) x := by
    have := ((hc2 x).hasDerivAt.mul_const (k ^ 2)).neg.mul ((hq1 x).pow 2)
    convert this using 1
    simp; ring
  have hB : ContDiff ℝ 2 (fun y => (q0 c k y : ℂ)) := by
    have hq : ContDiff ℝ 2 (q0 c k) := by
      have : q0 c k = fun y => 1 / (c y * k ^ 2 + 1) := rfl
      rw [this]
      exact contDiff_const.div ((hc.mul contDiff_const).add contDiff_const)
        (fun y => (hD y).ne')
    exact Complex.ofRealCLM.contDiff.comp hq
  have hdB : deriv (fun y => (q0 c k y : ℂ)) =
      fun y => ((-(deriv c y * k ^ 2) * q0 c k y ^ 2 : ℝ) : ℂ) :=
    funext fun y => (hq1 y).ofReal_comp.deriv
  have hddB : deriv (deriv (fun y => (q0 c k y : ℂ))) x =
      ((-(deriv (deriv c) x * k ^ 2) * q0 c k x ^ 2
        + 2 * (deriv c x) ^ 2 * k ^ 4 * q0 c k x ^ 3 : ℝ) : ℂ) := by
    rw [hdB]; exact hq2.ofReal_comp.deriv
  have hu : (q0 c k x : ℂ) * ((c x : ℂ) * (k : ℂ) ^ 2 + 1) = 1 := by
    have : q0 c k x * (c x * k ^ 2 + 1) = 1 := by
      simp only [q0]; rw [one_div, inv_mul_cancel₀ (hD x).ne']
    exact_mod_cast this
  rw [rod_composition_rule_aux c hc1 _ hB k x, hddB, hdB]
  push_cast
  linear_combination (wave k x) * hu

#print axioms error_eq

lemma norm_re_add_im_le (A B : ℝ) : ‖(A : ℂ) + (B : ℂ) * Complex.I‖ ≤ |A| + |B| :=
  (norm_add_le _ _).trans (le_of_eq (by simp [Complex.norm_real]))

#print axioms norm_re_add_im_le

lemma key_bound (k δ c c1 c2 M1 M2 u : ℝ) (hk : 1 ≤ |k|) (hδ : 0 < δ) (hc : δ ≤ c)
    (h1 : |c1| ≤ M1) (h2 : |c2| ≤ M2) (hu : u * (c * k ^ 2 + 1) = 1) :
    |k ^ 2 * u ^ 2 * (c1 ^ 2 * (1 - 2 * c * k ^ 2 * u) + c * c2)|
      + |k * c1 * u * (2 * c * k ^ 2 * u - 1)| ≤ ((M1 + M2) / δ + M1 ^ 2 / δ ^ 2) / |k| := by
  set K := |k| with hKdef
  have hK2 : k ^ 2 = K ^ 2 := (sq_abs k).symm
  have hK0 : 0 < K := by linarith
  have hc0 : 0 < c := by linarith
  have hD : 0 < c * k ^ 2 + 1 := by positivity
  have hu0 : 0 < u := by
    by_contra h
    have h' := not_lt.mp h
    nlinarith
  have hs0 : 0 ≤ c * k ^ 2 * u := by positivity
  have hs1 : c * k ^ 2 * u ≤ 1 := by nlinarith
  have hp : δ * K ^ 2 * u ≤ 1 := by
    rw [← hK2]
    have : δ * (k ^ 2 * u) ≤ c * (k ^ 2 * u) :=
      mul_le_mul_of_nonneg_right hc (by positivity)
    nlinarith
  have hp0 : 0 ≤ δ * K ^ 2 * u := by positivity
  have hsK : c * K ^ 2 * u ≤ 1 := by rw [← hK2]; exact hs1
  have hsK0 : 0 ≤ c * K ^ 2 * u := by positivity
  have hM1 : 0 ≤ M1 := (abs_nonneg _).trans h1
  have hM2 : 0 ≤ M2 := (abs_nonneg _).trans h2
  have hB : |k * c1 * u * (2 * c * k ^ 2 * u - 1)| ≤ K * M1 * u := by
    have e : |2 * c * k ^ 2 * u - 1| ≤ 1 := abs_le.mpr ⟨by nlinarith, by nlinarith⟩
    calc |k * c1 * u * (2 * c * k ^ 2 * u - 1)|
        = K * |c1| * u * |2 * c * k ^ 2 * u - 1| := by
          simp [abs_mul, abs_of_pos hu0, hKdef]
      _ ≤ K * M1 * u * 1 := by gcongr
      _ = K * M1 * u := mul_one _
  have hA : |k ^ 2 * u ^ 2 * (c1 ^ 2 * (1 - 2 * c * k ^ 2 * u) + c * c2)|
      ≤ K ^ 2 * u ^ 2 * (M1 ^ 2 + c * M2) := by
    have e : |1 - 2 * c * k ^ 2 * u| ≤ 1 := abs_le.mpr ⟨by nlinarith, by nlinarith⟩
    have e1 : |c1 ^ 2 * (1 - 2 * c * k ^ 2 * u)| ≤ M1 ^ 2 := by
      rw [abs_mul, abs_pow]
      calc |c1| ^ 2 * |1 - 2 * c * k ^ 2 * u| ≤ M1 ^ 2 * 1 := by gcongr
        _ = M1 ^ 2 := mul_one _
    have e2 : |c * c2| ≤ c * M2 := by
      rw [abs_mul, abs_of_pos hc0]; gcongr
    rw [abs_mul, abs_of_nonneg (by positivity)]
    rw [hK2] at e1 ⊢
    gcongr
    exact (abs_add_le _ _).trans (add_le_add e1 e2)
  have hK34 : K ^ 3 ≤ K ^ 4 := pow_le_pow_right₀ hk (by norm_num)
  have f1 : K ^ 2 * M1 * u * δ ^ 2 ≤ M1 * δ := by
    calc K ^ 2 * M1 * u * δ ^ 2 = (δ * K ^ 2 * u) * (M1 * δ) := by ring
      _ ≤ 1 * (M1 * δ) := by gcongr
      _ = M1 * δ := one_mul _
  have f2 : K ^ 3 * u ^ 2 * δ ^ 2 * M1 ^ 2 ≤ M1 ^ 2 := by
    calc K ^ 3 * u ^ 2 * δ ^ 2 * M1 ^ 2 ≤ K ^ 4 * u ^ 2 * δ ^ 2 * M1 ^ 2 := by gcongr
      _ = (δ * K ^ 2 * u) ^ 2 * M1 ^ 2 := by ring
      _ ≤ 1 ^ 2 * M1 ^ 2 := by gcongr
      _ = M1 ^ 2 := by ring
  have f3 : K ^ 3 * u ^ 2 * δ ^ 2 * (c * M2) ≤ δ * M2 := by
    calc K ^ 3 * u ^ 2 * δ ^ 2 * (c * M2) ≤ K ^ 4 * u ^ 2 * δ ^ 2 * (c * M2) := by gcongr
      _ = (δ * K ^ 2 * u) * (c * K ^ 2 * u) * (δ * M2) := by ring
      _ ≤ 1 * 1 * (δ * M2) := by gcongr
      _ = δ * M2 := by ring
  have hC : (M1 + M2) / δ + M1 ^ 2 / δ ^ 2 = ((M1 + M2) * δ + M1 ^ 2) / δ ^ 2 := by
    field_simp
  rw [hC, div_div, le_div_iff₀ (by positivity)]
  calc (|k ^ 2 * u ^ 2 * (c1 ^ 2 * (1 - 2 * c * k ^ 2 * u) + c * c2)|
        + |k * c1 * u * (2 * c * k ^ 2 * u - 1)|) * (δ ^ 2 * K)
      ≤ (K ^ 2 * u ^ 2 * (M1 ^ 2 + c * M2) + K * M1 * u) * (δ ^ 2 * K) := by gcongr
    _ ≤ (M1 + M2) * δ + M1 ^ 2 := by linear_combination f1 + f2 + f3

#print axioms key_bound

lemma sharp_core (k c s co u : ℝ) (hk : 1 ≤ k) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) (hs : |s| ≤ 1)
    (hco : |co| ≤ 1) (hu : u * (c * k ^ 2 + 1) = 1) :
    |k * ‖(((k ^ 2 * u ^ 2 * (co ^ 2 * (1 - 2 * c * k ^ 2 * u) + c * -s)) : ℝ) : ℂ)
        + ((k * co * u * (2 * c * k ^ 2 * u - 1) : ℝ) : ℂ) * Complex.I‖ - |co| / c|
      ≤ 7 / k := by
  set A := k ^ 2 * u ^ 2 * (co ^ 2 * (1 - 2 * c * k ^ 2 * u) + c * -s) with hA
  set B := k * co * u * (2 * c * k ^ 2 * u - 1) with hB
  have hk0 : 0 < k := by linarith
  have hc0 : 0 < c := by linarith
  have hD : 0 < c * k ^ 2 + 1 := by positivity
  have hu0 : 0 < u := by
    by_contra h
    have h' := not_lt.mp h
    nlinarith
  have hs0 : 0 ≤ c * k ^ 2 * u := by positivity
  have hs1 : c * k ^ 2 * u ≤ 1 := by nlinarith
  have hu1 : u ≤ 1 := by nlinarith
  have hk2u : k ^ 2 * u ≤ 1 := by
    have : 1 * (k ^ 2 * u) ≤ c * (k ^ 2 * u) := mul_le_mul_of_nonneg_right hc1 (by positivity)
    nlinarith
  have hku : k * u ≤ 1 := by nlinarith
  have step1 := abs_sub_le (k * ‖(A : ℂ) + (B : ℂ) * Complex.I‖) (k * abs B) (|co| / c)
  have step2 : |k * ‖(A : ℂ) + (B : ℂ) * Complex.I‖ - k * abs B| ≤ k * |A| := by
    rw [← mul_sub, abs_mul k, abs_of_pos hk0]
    refine mul_le_mul_of_nonneg_left ?_ hk0.le
    have := abs_norm_sub_norm_le ((A : ℂ) + (B : ℂ) * Complex.I) ((B : ℂ) * Complex.I)
    simpa [Complex.norm_real] using this
  have step3 : k * |A| ≤ 4 / k := by
    have e : |1 - 2 * c * k ^ 2 * u| ≤ 1 := abs_le.mpr ⟨by nlinarith, by nlinarith⟩
    have hco2 : co ^ 2 ≤ 1 := by
      rw [← sq_abs]; calc |co| ^ 2 ≤ 1 ^ 2 := by gcongr
        _ = 1 := one_pow 2
    have e1 : |co ^ 2 * (1 - 2 * c * k ^ 2 * u) + c * -s| ≤ 4 := by
      refine (abs_add_le _ _).trans ?_
      rw [abs_mul, abs_mul, abs_neg, abs_of_pos hc0, abs_pow]
      have : |co| ^ 2 * |1 - 2 * c * k ^ 2 * u| ≤ 1 * 1 := by
        rw [sq_abs]; gcongr
      have : c * |s| ≤ 3 * 1 := by gcongr
      linarith
    have hA' : |A| ≤ k ^ 2 * u ^ 2 * 4 := by
      rw [hA, abs_mul, abs_of_nonneg (by positivity)]; gcongr
    rw [le_div_iff₀ hk0]
    calc k * |A| * k ≤ k * (k ^ 2 * u ^ 2 * 4) * k := by gcongr
      _ = (k ^ 2 * u) ^ 2 * 4 := by ring
      _ ≤ 1 ^ 2 * 4 := by gcongr
      _ = 4 := by ring
  have step4 : |k * abs B - |co| / c| ≤ 3 / k := by
    have h1 : k * abs B = |k * B| := by rw [abs_mul k B, abs_of_pos hk0]
    have h2 : |co| / c = |co / c| := by rw [abs_div, abs_of_pos hc0]
    rw [h1, h2]
    refine (abs_abs_sub_abs_le_abs_sub _ _).trans ?_
    have hid : k * B - co / c = co * (u * (2 * u - 3)) / c := by
      rw [hB]
      field_simp
      linear_combination (co * (3 - 4 * u + 2 * (u * c * k ^ 2 + u - 1))) * hu
    rw [hid, abs_div, abs_of_pos hc0, div_le_iff₀ hc0, abs_mul, abs_mul, abs_of_pos hu0]
    have e : |2 * u - 3| ≤ 3 := abs_le.mpr ⟨by linarith, by linarith⟩
    have hu3 : u ≤ 1 / k := by rw [le_div_iff₀ hk0]; linarith
    calc |co| * (u * |2 * u - 3|) ≤ 1 * (u * 3) := by gcongr
      _ = 3 * u * 1 := by ring
      _ ≤ 3 * (1 / k) * c := by gcongr
      _ = 3 / k * c := by ring
  calc _ ≤ _ := step1
    _ ≤ 4 / k + 3 / k := add_le_add (step2.trans step3) step4
    _ = 7 / k := by ring

#print axioms sharp_core

lemma sharp_pointwise (k x : ℝ) (hk : 1 ≤ k) :
    |k * ‖rodOp (fun y => 2 + Real.sin y)
            (fun y => (q0 (fun y => 2 + Real.sin y) k y : ℂ) * wave k y) x - wave k x‖
      - |Real.cos x| / (2 + Real.sin x)| ≤ 7 / k := by
  have hd1 : deriv (fun y => 2 + Real.sin y) = Real.cos := by funext y; simp
  have hd2 : deriv Real.cos = fun y => -Real.sin y := by
    funext y; simp
  rw [error_eq _ (contDiff_const.add Real.contDiff_sin)
    (fun y => by linarith [Real.neg_one_le_sin y]) k x, norm_mul, norm_wave, one_mul, hd1, hd2]
  beta_reduce
  have hD : 0 < (2 + Real.sin x) * k ^ 2 + 1 := by
    have h : 0 ≤ 2 + Real.sin x := by linarith [Real.neg_one_le_sin x]
    nlinarith [mul_nonneg h (sq_nonneg k)]
  refine sharp_core k (2 + Real.sin x) (Real.sin x) (Real.cos x) _ hk
    (by linarith [Real.neg_one_le_sin x]) (by linarith [Real.sin_le_one x])
    (Real.abs_sin_le_one x) (Real.abs_cos_le_one x) ?_
  simp only [q0]; rw [one_div, inv_mul_cancel₀ hD.ne']

#print axioms sharp_pointwise

lemma isGreatest_ratio :
    IsGreatest (Set.range fun x : ℝ => |Real.cos x| / (2 + Real.sin x)) (1 / Real.sqrt 3) := by
  refine ⟨⟨-(Real.pi / 6), ?_⟩, ?_⟩
  · simp only
    rw [Real.cos_neg, Real.sin_neg, Real.cos_pi_div_six, Real.sin_pi_div_six,
      abs_of_pos (by positivity)]
    have h3 : Real.sqrt 3 * Real.sqrt 3 = 3 := Real.mul_self_sqrt (by norm_num)
    have h0 : 0 < Real.sqrt 3 := by positivity
    field_simp
    linarith
  · rintro _ ⟨x, rfl⟩
    have hc : 0 < 2 + Real.sin x := by linarith [Real.neg_one_le_sin x]
    dsimp only
    rw [div_le_div_iff₀ hc (by positivity), one_mul]
    apply (pow_le_pow_iff_left₀ (by positivity) hc.le two_ne_zero).mp
    rw [mul_pow, sq_abs, Real.sq_sqrt (by norm_num)]
    nlinarith [Real.sin_sq_add_cos_sq x, sq_nonneg (2 * Real.sin x + 1)]

#print axioms isGreatest_ratio

/-- **The parametrix error shrinks like one over the frequency.** Let the conductivity `c` be
smooth with every derivative bounded (so the rod's symbol `c k² - i k c' + 1` lies in `S²`), and
let the operator be elliptic: `c ≥ δ` for some `δ > 0`, so the main part `c k²` never vanishes
for large `k`. Then dividing by the main part of the gain, `Q₀ = Op(1/(c k² + 1))`, inverts `P`
on every test wave up to an error of order `-1`: there is one constant `C` with
`|(P Q₀ - I) e_k (x)| ≤ C / |k|` at every position `x` and every wavenumber `|k| ≥ 1`. -/
theorem parametrix_error_le_const_div_wavenumber (c : ℝ → ℝ) (hc : ContDiff ℝ ∞ c)
    (hbdd : ∀ n : ℕ, ∃ M : ℝ, ∀ x : ℝ, |iteratedDeriv n c x| ≤ M)
    (hell : ∃ δ : ℝ, 0 < δ ∧ ∀ x : ℝ, δ ≤ c x) :
    ∃ C : ℝ, ∀ k : ℝ, 1 ≤ |k| → ∀ x : ℝ,
      ‖rodOp c (fun y => (q0 c k y : ℂ) * wave k y) x - wave k x‖ ≤ C / |k| := by
  obtain ⟨δ, hδ, hcδ⟩ := hell
  obtain ⟨M1, hM1⟩ := hbdd 1
  obtain ⟨M2, hM2⟩ := hbdd 2
  refine ⟨(M1 + M2) / δ + M1 ^ 2 / δ ^ 2, fun k hk x => ?_⟩
  have hc2 : ContDiff ℝ 2 c := by exact_mod_cast contDiff_infty.mp hc 2
  have hpos : ∀ y, 0 ≤ c y := fun y => hδ.le.trans (hcδ y)
  rw [error_eq c hc2 hpos k x, norm_mul, norm_wave, one_mul]
  refine (norm_re_add_im_le _ _).trans ?_
  have h1 : |deriv c x| ≤ M1 := by simpa [iteratedDeriv_one] using hM1 x
  have h2 : |deriv (deriv c) x| ≤ M2 := by
    simpa [iteratedDeriv_succ, iteratedDeriv_one] using hM2 x
  have hu : q0 c k x * (c x * k ^ 2 + 1) = 1 := by
    have : 0 < c x * k ^ 2 + 1 := by have := hpos x; positivity
    simp only [q0]; rw [one_div, inv_mul_cancel₀ this.ne']
  exact key_bound k δ (c x) _ _ M1 M2 _ hk hδ (hcδ x) h1 h2 hu

/-- **The composition rule for the rod, exact** (Step 1). For a differentiable conductivity `c`,
any twice continuously differentiable amplitude `b` and any wavenumber `k`, applying `P` to the
wave `b e_k` gives `e_k` times `p # b`:
`P(b e_k) = e_k ((c k² + 1 - i k c') b - (2 i k c + c') b' - c b'')`,
the sum over `α` of `(1/α!) ∂_k^α p · (-i ∂_x)^α b`, with nothing left over. -/
theorem rod_composition_rule (c : ℝ → ℝ) (hc : Differentiable ℝ c) (b : ℝ → ℂ)
    (hb : ContDiff ℝ 2 b) (k x : ℝ) :
    rodOp c (fun y => b y * wave k y) x =
      wave k x * (((c x : ℂ) * (k : ℂ) ^ 2 + 1 - Complex.I * k * ((deriv c x : ℝ) : ℂ)) * b x
        - (2 * Complex.I * k * (c x : ℂ) + ((deriv c x : ℝ) : ℂ)) * deriv b x
        - (c x : ℂ) * deriv (deriv b) x) := by
  exact rod_composition_rule_aux c hc b hb k x

/-- **The sharp constant for the rod `c = 2 + sin x`** (Step 3). The largest error of
`P Q₀ - I` over the rod, times the wavenumber `k`, tends to `1/√3` as `k → ∞`; and `1/√3` is
the largest value of `|cos x| / (2 + sin x)`, the size of the leading error term
`i cos x / ((2 + sin x) k)` times `k`. -/
theorem rod_parametrix_sharp_constant :
    Tendsto (fun k : ℝ => k * ⨆ x : ℝ,
        ‖rodOp (fun y => 2 + Real.sin y)
            (fun y => (q0 (fun y => 2 + Real.sin y) k y : ℂ) * wave k y) x - wave k x‖)
      atTop (𝓝 (1 / Real.sqrt 3)) ∧
    IsGreatest (Set.range fun x : ℝ => |Real.cos x| / (2 + Real.sin x)) (1 / Real.sqrt 3) := by
  refine ⟨?_, isGreatest_ratio⟩
  obtain ⟨x0, hx0⟩ := isGreatest_ratio.1
  have hf : ∀ x, |Real.cos x| / (2 + Real.sin x) ≤ 1 / Real.sqrt 3 :=
    fun x => isGreatest_ratio.2 ⟨x, rfl⟩
  have h0 : Tendsto (fun k : ℝ => 7 / k) atTop (𝓝 0) :=
    tendsto_const_nhds.div_atTop tendsto_id
  have hlow : Tendsto (fun k : ℝ => 1 / Real.sqrt 3 - 7 / k) atTop (𝓝 (1 / Real.sqrt 3)) := by
    simpa using (tendsto_const_nhds (x := 1 / Real.sqrt 3)).sub h0
  have hup : Tendsto (fun k : ℝ => 1 / Real.sqrt 3 + 7 / k) atTop (𝓝 (1 / Real.sqrt 3)) := by
    simpa using (tendsto_const_nhds (x := 1 / Real.sqrt 3)).add h0
  have hbd : ∀ k : ℝ, 1 ≤ k →
      (∀ x, |k * ‖rodOp (fun y => 2 + Real.sin y)
            (fun y => (q0 (fun y => 2 + Real.sin y) k y : ℂ) * wave k y) x - wave k x‖
        - |Real.cos x| / (2 + Real.sin x)| ≤ 7 / k) := fun k hk x => sharp_pointwise k x hk
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlow hup ?_ ?_
  · filter_upwards [eventually_ge_atTop 1] with k hk
    rw [Real.mul_iSup_of_nonneg (by linarith)]
    have hB : BddAbove (Set.range fun x => k * ‖rodOp (fun y => 2 + Real.sin y)
            (fun y => (q0 (fun y => 2 + Real.sin y) k y : ℂ) * wave k y) x - wave k x‖) := by
      refine ⟨1 / Real.sqrt 3 + 7 / k, ?_⟩
      rintro _ ⟨x, rfl⟩
      linarith [(abs_le.mp (hbd k hk x)).2, hf x]
    refine le_trans ?_ (le_ciSup hB x0)
    linarith [(abs_le.mp (hbd k hk x0)).1]
  · filter_upwards [eventually_ge_atTop 1] with k hk
    rw [Real.mul_iSup_of_nonneg (by linarith)]
    exact ciSup_le fun x => by linarith [(abs_le.mp (hbd k hk x)).2, hf x]

/-! The card's exact worked numbers. -/

-- By hand at x = 7π/6, k = 100: c = 2 - 1/2 = 3/2, so c k² + 1 = 15001 and q₀ = 1/15001.
example : (2 : ℚ) - 1 / 2 = 3 / 2 ∧ (3 / 2 : ℚ) * 100 ^ 2 + 1 = 15001 := by norm_num

-- The limit 1/√3: at sin x = -1/2, cos² x = 3/4 and (2 + sin x)² = 9/4, a ratio of 1/3.
example : (1 : ℚ) - (-1 / 2) ^ 2 = 3 / 4 ∧ ((3 : ℚ) / 4) / (2 + (-1 / 2)) ^ 2 = 1 / 3 := by
  norm_num

-- The degenerate model -(x² u')' + u = 0 is solved by |x|^α with α(α + 1) = 1,
-- so α = (√5 - 1)/2.
example : (Real.sqrt 5 - 1) / 2 * ((Real.sqrt 5 - 1) / 2 + 1) = 1 := by
  ring_nf
  norm_num

-- The L² test symbol 1 + (1/2) cos x · k/√(1 + k²): harmonics 1 and 1/4, 1/4, bound 3/2.
example : (1 : ℚ) + 1 / 4 + 1 / 4 = 3 / 2 := by norm_num

#print axioms parametrix_error_le_const_div_wavenumber
#print axioms rod_composition_rule
#print axioms rod_parametrix_sharp_constant

end PseudodifferentialCard
