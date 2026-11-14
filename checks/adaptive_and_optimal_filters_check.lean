-- Wiener and LMS: the best weighted guess of one signal from others is the one whose error is uncorrelated with every input, which is the linear system R w = p with a single solution when R is invertible; in noise cancelling it is the true path and leaves only the voice, and steepest descent reaches it exactly when every factor 1 − μλ has size below 1.
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.Analysis.Normed.Ring.Lemmas
import Mathlib.Analysis.Matrix.Spectrum

open MeasureTheory Filter Topology Matrix

lemma wf_int_mul {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {f g : Ω → ℝ}
    (hf : MemLp f 2 P) (hg : MemLp g 2 P) : Integrable (fun ω => f ω * g ω) P :=
  hf.integrable_mul hg

lemma wf_memLp_dot {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {n : ℕ}
    (x : Ω → Fin n → ℝ) (hx : ∀ i, MemLp (fun ω => x ω i) 2 P) (v : Fin n → ℝ) :
    MemLp (fun ω => v ⬝ᵥ x ω) 2 P := by
  have : (fun ω => v ⬝ᵥ x ω) = fun ω => ∑ i, v i * x ω i := by
    funext ω; simp [dotProduct]
  rw [this]
  exact memLp_finsetSum _ fun i _ => (hx i).const_mul (v i)

lemma wf_int_dot_mul {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {n : ℕ}
    (x : Ω → Fin n → ℝ) (hx : ∀ i, MemLp (fun ω => x ω i) 2 P) {g : Ω → ℝ}
    (hg : MemLp g 2 P) (u : Fin n → ℝ) :
    ∫ ω, (u ⬝ᵥ x ω) * g ω ∂P = ∑ i, u i * ∫ ω, x ω i * g ω ∂P := by
  simp_rw [dotProduct, Finset.sum_mul]
  rw [integral_finsetSum]
  · refine Finset.sum_congr rfl fun i _ => ?_
    rw [← integral_const_mul]
    congr 1; funext ω; ring
  · intro i _
    have := ((hx i).integrable_mul hg).const_mul (u i)
    refine this.congr (Eventually.of_forall fun ω => ?_)
    simp only [Pi.mul_apply]; ring

lemma wf_int_dot_dot {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {n : ℕ}
    (x : Ω → Fin n → ℝ) (hx : ∀ i, MemLp (fun ω => x ω i) 2 P)
    (R : Matrix (Fin n) (Fin n) ℝ) (hRdef : ∀ i j, R i j = ∫ ω, x ω i * x ω j ∂P)
    (u v : Fin n → ℝ) :
    ∫ ω, (u ⬝ᵥ x ω) * (v ⬝ᵥ x ω) ∂P = u ⬝ᵥ R *ᵥ v := by
  rw [wf_int_dot_mul x hx (wf_memLp_dot x hx v) u]
  simp only [dotProduct, mulVec]
  refine Finset.sum_congr rfl fun i _ => ?_
  congr 1
  have := wf_int_dot_mul x hx (hx i) v
  simp only [dotProduct] at this
  rw [show (fun ω => x ω i * ∑ j, v j * x ω j) = fun ω => (∑ j, v j * x ω j) * x ω i by
    funext ω; ring, this]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [hRdef]; rw [mul_comm]; congr 1; congr 1; funext ω; ring

lemma wf_int_d_dot {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {n : ℕ}
    (x : Ω → Fin n → ℝ) (d : Ω → ℝ) (hx : ∀ i, MemLp (fun ω => x ω i) 2 P) (hd : MemLp d 2 P)
    (p : Fin n → ℝ) (hpdef : ∀ i, p i = ∫ ω, d ω * x ω i ∂P) (v : Fin n → ℝ) :
    ∫ ω, d ω * (v ⬝ᵥ x ω) ∂P = p ⬝ᵥ v := by
  rw [show (fun ω => d ω * (v ⬝ᵥ x ω)) = fun ω => (v ⬝ᵥ x ω) * d ω by funext ω; ring,
    wf_int_dot_mul x hx hd v, dotProduct_comm]
  simp only [dotProduct]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [hpdef]; congr 1; congr 1; funext ω; ring

lemma wf_J_expand {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {n : ℕ}
    (x : Ω → Fin n → ℝ) (d : Ω → ℝ) (hx : ∀ i, MemLp (fun ω => x ω i) 2 P) (hd : MemLp d 2 P)
    (R : Matrix (Fin n) (Fin n) ℝ) (hRdef : ∀ i j, R i j = ∫ ω, x ω i * x ω j ∂P)
    (p : Fin n → ℝ) (hpdef : ∀ i, p i = ∫ ω, d ω * x ω i ∂P) (w : Fin n → ℝ) :
    ∫ ω, (d ω - w ⬝ᵥ x ω) ^ 2 ∂P = ∫ ω, d ω ^ 2 ∂P - 2 * (p ⬝ᵥ w) + w ⬝ᵥ R *ᵥ w := by
  have hw := wf_memLp_dot x hx w
  have h1 : Integrable (fun ω => d ω * d ω) P := wf_int_mul hd hd
  have h2 : Integrable (fun ω => d ω * (w ⬝ᵥ x ω)) P := wf_int_mul hd hw
  have h2' : Integrable (fun ω => 2 * (d ω * (w ⬝ᵥ x ω))) P := h2.const_mul 2
  have h12 : Integrable (fun ω => d ω * d ω - 2 * (d ω * (w ⬝ᵥ x ω))) P := h1.sub h2'
  have h3 : Integrable (fun ω => (w ⬝ᵥ x ω) * (w ⬝ᵥ x ω)) P := wf_int_mul hw hw
  have e : (fun ω => (d ω - w ⬝ᵥ x ω) ^ 2) =
      fun ω => d ω * d ω - 2 * (d ω * (w ⬝ᵥ x ω)) + (w ⬝ᵥ x ω) * (w ⬝ᵥ x ω) := by
    funext ω; ring
  rw [e, integral_add h12 h3, integral_sub h1 h2',
    integral_const_mul, wf_int_d_dot x d hx hd p hpdef w, wf_int_dot_dot x hx R hRdef w w]
  congr 2; congr 1; funext ω; ring

lemma wf_orth {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {n : ℕ}
    (x : Ω → Fin n → ℝ) (d : Ω → ℝ) (hx : ∀ i, MemLp (fun ω => x ω i) 2 P) (hd : MemLp d 2 P)
    (R : Matrix (Fin n) (Fin n) ℝ) (hRdef : ∀ i j, R i j = ∫ ω, x ω i * x ω j ∂P)
    (p : Fin n → ℝ) (hpdef : ∀ i, p i = ∫ ω, d ω * x ω i ∂P) (w : Fin n → ℝ) (i : Fin n) :
    ∫ ω, (d ω - w ⬝ᵥ x ω) * x ω i ∂P = p i - (R *ᵥ w) i := by
  have hw := wf_memLp_dot x hx w
  simp_rw [sub_mul]
  rw [integral_sub (wf_int_mul hd (hx i)) (wf_int_mul hw (hx i)),
    wf_int_dot_mul x hx (hx i) w, hpdef]
  congr 1
  simp only [mulVec, dotProduct]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [hRdef, mul_comm]; congr 1; congr 1; funext ω; ring

lemma wf_R_symm {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {n : ℕ}
    (x : Ω → Fin n → ℝ)
    (R : Matrix (Fin n) (Fin n) ℝ) (hRdef : ∀ i j, R i j = ∫ ω, x ω i * x ω j ∂P) :
    Rᵀ = R := by
  ext i j; simp only [transpose_apply, hRdef]; congr 1; funext ω; ring

lemma wf_quad_nonneg {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {n : ℕ}
    (x : Ω → Fin n → ℝ) (hx : ∀ i, MemLp (fun ω => x ω i) 2 P)
    (R : Matrix (Fin n) (Fin n) ℝ) (hRdef : ∀ i j, R i j = ∫ ω, x ω i * x ω j ∂P)
    (v : Fin n → ℝ) : 0 ≤ v ⬝ᵥ R *ᵥ v := by
  rw [← wf_int_dot_dot x hx R hRdef v v]
  exact integral_nonneg fun ω => mul_self_nonneg _

lemma wf_sym_form {n : ℕ} (R : Matrix (Fin n) (Fin n) ℝ) (hRs : Rᵀ = R) (a b : Fin n → ℝ) :
    a ⬝ᵥ R *ᵥ b = b ⬝ᵥ R *ᵥ a := by
  rw [dotProduct_mulVec, dotProduct_comm, ← mulVec_transpose, hRs]

lemma wf_quad_shift {n : ℕ} (R : Matrix (Fin n) (Fin n) ℝ) (hRs : Rᵀ = R) (c : ℝ)
    (p w v : Fin n → ℝ) :
    c - 2 * (p ⬝ᵥ (w + v)) + (w + v) ⬝ᵥ R *ᵥ (w + v) =
      (c - 2 * (p ⬝ᵥ w) + w ⬝ᵥ R *ᵥ w) + v ⬝ᵥ R *ᵥ v - 2 * (v ⬝ᵥ (p - R *ᵥ w)) := by
  have h1 := wf_sym_form R hRs w v
  have h2 : p ⬝ᵥ v = v ⬝ᵥ p := dotProduct_comm _ _
  simp only [mulVec_add, dotProduct_add, add_dotProduct, dotProduct_sub]
  linarith

#print axioms wf_int_mul
#print axioms wf_memLp_dot
#print axioms wf_int_dot_mul
#print axioms wf_int_dot_dot
#print axioms wf_int_d_dot
#print axioms wf_J_expand
#print axioms wf_orth
#print axioms wf_R_symm
#print axioms wf_quad_nonneg
#print axioms wf_sym_form
#print axioms wf_quad_shift

/-- **The Wiener filter: the best weights solve R w = p.** On a probability space, let the
filter's `n` inputs (taps) be `x ω : Fin n → ℝ` and the desired signal be `d`, all with finite
averages of squares. Let `R i j = E[x_i x_j]` be the tap correlations, `p i = E[d x_i]` each
tap's correlation with `d`, and `J w = E[(d − w·x)²]` the mean squared error of the weights `w`.
If `R` can be inverted, then:
weights give the lowest possible `J` exactly when `R w = p` (the Wiener–Hopf equations);
`R w = p` holds exactly when the error `d − w·x` is uncorrelated with every tap
(the orthogonality principle); there is exactly one best choice of weights; and for the best
weights the lowest error is `J_min = E[d²] − p·w`, while any other weights `w'` cost exactly
`(w' − w)ᵀ R (w' − w)` more. -/
theorem wiener_hopf_best_filter {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {n : ℕ} (x : Ω → Fin n → ℝ) (d : Ω → ℝ)
    (hx : ∀ i, MemLp (fun ω => x ω i) 2 P) (hd : MemLp d 2 P)
    (R : Matrix (Fin n) (Fin n) ℝ) (hRdef : ∀ i j, R i j = ∫ ω, x ω i * x ω j ∂P)
    (p : Fin n → ℝ) (hpdef : ∀ i, p i = ∫ ω, d ω * x ω i ∂P)
    (J : (Fin n → ℝ) → ℝ) (hJdef : ∀ w, J w = ∫ ω, (d ω - w ⬝ᵥ x ω) ^ 2 ∂P)
    (hR : R.det ≠ 0) :
    (∀ w, (∀ w', J w ≤ J w') ↔ R *ᵥ w = p) ∧
      (∀ w, R *ᵥ w = p ↔ ∀ i, ∫ ω, (d ω - w ⬝ᵥ x ω) * x ω i ∂P = 0) ∧
      (∃! w, ∀ w', J w ≤ J w') ∧
      ∀ w, R *ᵥ w = p →
        J w = ∫ ω, d ω ^ 2 ∂P - p ⬝ᵥ w ∧
          ∀ w', J w' = J w + (w' - w) ⬝ᵥ R *ᵥ (w' - w) := by
  have hRs := wf_R_symm x R hRdef
  have hJ : ∀ w, J w = ∫ ω, d ω ^ 2 ∂P - 2 * (p ⬝ᵥ w) + w ⬝ᵥ R *ᵥ w := fun w => by
    rw [hJdef, wf_J_expand x d hx hd R hRdef p hpdef w]
  have hshift : ∀ w v, J (w + v) = J w + v ⬝ᵥ R *ᵥ v - 2 * (v ⬝ᵥ (p - R *ᵥ w)) := by
    intro w v; rw [hJ, hJ, wf_quad_shift R hRs]
  have hq := wf_quad_nonneg x hx R hRdef
  have hU : IsUnit R.det := isUnit_iff_ne_zero.mpr hR
  have hmin : ∀ w, (∀ w', J w ≤ J w') ↔ R *ᵥ w = p := by
    intro w
    constructor
    · intro hw
      set g := p - R *ᵥ w with hg
      have key : ∀ t : ℝ, 0 ≤ t ^ 2 * (g ⬝ᵥ R *ᵥ g) - 2 * t * (g ⬝ᵥ g) := by
        intro t
        have h1 := hw (w + t • g)
        rw [hshift] at h1
        simp only [mulVec_smul, smul_dotProduct, dotProduct_smul, smul_eq_mul] at h1
        nlinarith
      set a := g ⬝ᵥ R *ᵥ g
      set b := g ⬝ᵥ g
      have ha : 0 ≤ a := hq g
      have hk := key (b / (a + 1))
      have ha1 : 0 < a + 1 := by linarith
      have hb : b = 0 := by
        rw [div_pow] at hk
        have e : (b / (a + 1)) = b * (a + 1)⁻¹ := div_eq_mul_inv _ _
        rw [e] at hk
        have hinv : 0 < (a + 1)⁻¹ := inv_pos.mpr ha1
        have hia : (a + 1)⁻¹ * (a + 1) = 1 := inv_mul_cancel₀ ha1.ne'
        have : b ^ 2 / (a + 1) ^ 2 * a - 2 * (b * (a + 1)⁻¹) * b
            = -(b ^ 2 * (a + 2)) * ((a + 1)⁻¹) ^ 2 := by
          field_simp; ring
        rw [this] at hk
        have h3 : 0 < ((a + 1)⁻¹) ^ 2 := by positivity
        have h4 : b ^ 2 * (a + 2) ≤ 0 := by nlinarith
        have h5 : b ^ 2 ≤ 0 := by nlinarith
        nlinarith [sq_nonneg b]
      have hg0 : g = 0 := dotProduct_self_eq_zero.mp hb
      rw [hg] at hg0
      exact (sub_eq_zero.mp hg0).symm
    · intro hw w'
      have := hshift w (w' - w)
      rw [add_sub_cancel, hw, sub_self, dotProduct_zero] at this
      rw [this]; linarith [hq (w' - w)]
  refine ⟨hmin, ?_, ?_, ?_⟩
  · intro w
    simp only [wf_orth x d hx hd R hRdef p hpdef w]
    constructor
    · intro h i; rw [h, sub_self]
    · intro h; funext i; exact (sub_eq_zero.mp (h i)).symm
  · refine ⟨R⁻¹ *ᵥ p, (hmin _).mpr ?_, fun w hw => ?_⟩
    · rw [mulVec_mulVec, mul_nonsing_inv R hU, one_mulVec]
    · have := (hmin w).mp hw
      rw [← this, mulVec_mulVec, nonsing_inv_mul R hU, one_mulVec]
  · intro w hw
    refine ⟨?_, fun w' => ?_⟩
    · rw [hJ, hw, dotProduct_comm w p]; ring
    · have := hshift w (w' - w)
      rw [add_sub_cancel, hw, sub_self, dotProduct_zero] at this
      rw [this]; ring

/-- **Noise cancelling: the best filter is the path, and it leaves only the voice.** Same
setting. Suppose the desired (cabin) signal is a voice `s` plus a fixed weighted sum of the
taps, `d = s + h·x` (the path `h` is linear, fixed, and no longer than the filter), the voice has
finite average square and is uncorrelated with every tap (`E[s x_i] = 0`), and `R` can be
inverted. Then `p = R h`, the one best choice of weights is `h` itself, and the error it leaves,
`J_min`, is the voice power `E[s²]`. -/
theorem wiener_noise_canceller_recovers_path {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {n : ℕ} (x : Ω → Fin n → ℝ) (s d : Ω → ℝ) (h : Fin n → ℝ)
    (hx : ∀ i, MemLp (fun ω => x ω i) 2 P) (hs : MemLp s 2 P)
    (hdh : ∀ ω, d ω = s ω + h ⬝ᵥ x ω)
    (hunc : ∀ i, ∫ ω, s ω * x ω i ∂P = 0)
    (R : Matrix (Fin n) (Fin n) ℝ) (hRdef : ∀ i j, R i j = ∫ ω, x ω i * x ω j ∂P)
    (p : Fin n → ℝ) (hpdef : ∀ i, p i = ∫ ω, d ω * x ω i ∂P)
    (J : (Fin n → ℝ) → ℝ) (hJdef : ∀ w, J w = ∫ ω, (d ω - w ⬝ᵥ x ω) ^ 2 ∂P)
    (hR : R.det ≠ 0) :
    p = R *ᵥ h ∧ (∀ w, (∀ w', J w ≤ J w') ↔ w = h) ∧ J h = ∫ ω, s ω ^ 2 ∂P := by
  have hdeq : d = fun ω => s ω + h ⬝ᵥ x ω := funext hdh
  have hd : MemLp d 2 P := by rw [hdeq]; exact hs.add (wf_memLp_dot x hx h)
  have hU : IsUnit R.det := isUnit_iff_ne_zero.mpr hR
  have hp : p = R *ᵥ h := by
    funext i
    have := wf_orth x d hx hd R hRdef p hpdef h i
    have e : (fun ω => (d ω - h ⬝ᵥ x ω) * x ω i) = fun ω => s ω * x ω i := by
      funext ω; rw [hdh]; ring
    rw [e, hunc] at this
    linarith
  have main := wiener_hopf_best_filter x d hx hd R hRdef p hpdef J hJdef hR
  refine ⟨hp, fun w => ?_, ?_⟩
  · rw [main.1 w, hp]
    constructor
    · intro hw
      have := congrArg (fun v => R⁻¹ *ᵥ v) hw
      simpa [mulVec_mulVec, nonsing_inv_mul R hU] using this
    · intro hw; rw [hw]
  · rw [hJdef]
    congr 1; funext ω; rw [hdh]; ring

/-- **Steepest descent: the step-size rule.** Same setting as the Wiener filter, with `R`
invertible. Steepest descent repeats `w ← w + μ (p − R w)`. Along each eigenvector of `R`
(a direction `v ≠ 0` with `R v = λ v`) one step multiplies the gap to the best weights by
`1 − μλ`. The walk reaches the best weights `R⁻¹ p` from every starting point exactly when
every such factor has size below 1, that is `0 < μ < 2/λ_max`. -/
theorem steepest_descent_converges_iff {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {n : ℕ} (x : Ω → Fin n → ℝ) (d : Ω → ℝ)
    (hx : ∀ i, MemLp (fun ω => x ω i) 2 P) (hd : MemLp d 2 P)
    (R : Matrix (Fin n) (Fin n) ℝ) (hRdef : ∀ i j, R i j = ∫ ω, x ω i * x ω j ∂P)
    (p : Fin n → ℝ) (hpdef : ∀ i, p i = ∫ ω, d ω * x ω i ∂P)
    (hR : R.det ≠ 0) (μ : ℝ) :
    (∀ w : ℕ → Fin n → ℝ, (∀ k, w (k + 1) = w k + μ • (p - R *ᵥ w k)) →
        Tendsto w atTop (𝓝 (R⁻¹ *ᵥ p))) ↔
      ∀ (l : ℝ) (v : Fin n → ℝ), v ≠ 0 → R *ᵥ v = l • v → |1 - μ * l| < 1 := by
  have hRs := wf_R_symm x R hRdef
  have hU : IsUnit R.det := isUnit_iff_ne_zero.mpr hR
  set ws := R⁻¹ *ᵥ p with hwsdef
  have hws : R *ᵥ ws = p := by rw [hwsdef, mulVec_mulVec, mul_nonsing_inv R hU, one_mulVec]
  constructor
  · intro hconv l v hv hRv
    set r := 1 - μ * l
    have hrec : ∀ k : ℕ, ws + r ^ (k + 1) • v =
        (ws + r ^ k • v) + μ • (p - R *ᵥ (ws + r ^ k • v)) := by
      intro k
      simp only [mulVec_add, mulVec_smul, hRv, hws]
      ext i
      simp only [Pi.add_apply, Pi.smul_apply, Pi.sub_apply, smul_eq_mul, pow_succ]
      ring
    have hT := hconv (fun k => ws + r ^ k • v) hrec
    obtain ⟨i, hi⟩ := Function.ne_iff.mp hv
    have hTi := (tendsto_pi_nhds.mp hT) i
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul] at hTi
    have h2 : Tendsto (fun k : ℕ => r ^ k) atTop (𝓝 0) := by
      have h3 := (hTi.sub_const (ws i)).div_const (v i)
      simp only [add_sub_cancel_left, sub_self, zero_div] at h3
      have hi' : v i ≠ 0 := hi
      refine h3.congr fun k => ?_
      exact mul_div_cancel_right₀ _ hi'
    exact tendsto_pow_atTop_nhds_zero_iff.mp h2
  · intro hall w hrec
    have hH : R.IsHermitian := by
      unfold IsHermitian; rw [conjTranspose_eq_transpose_of_trivial, hRs]
    set b := hH.eigenvectorBasis
    have hu : ∀ j, R *ᵥ ⇑(b j) = (hH.eigenvalues j) • ⇑(b j) := hH.mulVec_eigenvectorBasis
    have hne : ∀ j, (⇑(b j) : Fin n → ℝ) ≠ 0 := by
      intro j h0
      have : b j = 0 := by
        apply WithLp.ofLp_injective
        exact h0
      exact b.orthonormal.ne_zero j this
    have hr : ∀ j, |1 - μ * hH.eigenvalues j| < 1 := fun j => hall _ _ (hne j) (hu j)
    set c := fun j => b.repr (WithLp.toLp 2 (w 0 - ws)) j
    have hsum : w 0 - ws = ∑ j, c j • ⇑(b j) := by
      have := congrArg WithLp.ofLp (b.sum_repr (WithLp.toLp 2 (w 0 - ws)))
      simp only [WithLp.ofLp_sum, WithLp.ofLp_smul] at this
      exact this.symm
    have hind : ∀ k, w k - ws =
        ∑ j, (c j * (1 - μ * hH.eigenvalues j) ^ k) • ⇑(b j) := by
      intro k
      induction k with
      | zero => simpa using hsum
      | succ k ih =>
        have e : w (k + 1) - ws = (w k - ws) - μ • (R *ᵥ (w k - ws)) := by
          rw [hrec k, mulVec_sub, hws, smul_sub, smul_sub]; abel
        rw [e, ih, mulVec_sum, Finset.smul_sum, ← Finset.sum_sub_distrib]
        refine Finset.sum_congr rfl fun j _ => ?_
        rw [mulVec_smul, hu, smul_smul, smul_smul, ← sub_smul]
        congr 1; ring
    have hlim : Tendsto (fun k => ws + ∑ j, (c j * (1 - μ * hH.eigenvalues j) ^ k) • ⇑(b j))
        atTop (𝓝 (ws + ∑ j, (c j * 0) • ⇑(b j))) :=
      tendsto_const_nhds.add (tendsto_finsetSum _ fun j _ =>
        ((tendsto_pow_atTop_nhds_zero_of_abs_lt_one (hr j)).const_mul (c j)).smul_const _)
    simp only [mul_zero, zero_smul, Finset.sum_const_zero, add_zero] at hlim
    refine hlim.congr fun k => ?_
    rw [← hind k]; abel

/-! The card's worked numbers: engine taps correlated 1/2, path (4/5, 2/5) = (0.8, 0.4),
voice power 1/4, step size μ = 1/100. -/

-- R = [[1, 1/2], [1/2, 1]] has determinant 3/4 (0.75).
example : (!![1, 1/2; 1/2, 1] : Matrix (Fin 2) (Fin 2) ℚ).det = 3 / 4 := by
  simp [Matrix.det_fin_two]; norm_num
-- p = R h = (1, 4/5), that is (1.0, 0.8).
example : (!![1, 1/2; 1/2, 1] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![4/5, 2/5] = ![1, 4/5] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num
-- Engine noise at the cabin mic, hᵀ R h = 0.64 + 0.16 + 2 × 0.5 × 0.8 × 0.4 = 1.12.
example : (4/5 : ℚ) ^ 2 + (2/5) ^ 2 + 2 * (1/2) * (4/5) * (2/5) = 28 / 25 := by norm_num
-- Cabin mic power E[d²] = 0.25 + 1.12 = 1.37.
example : (1/4 : ℚ) + 28 / 25 = 137 / 100 := by norm_num
-- Cramer's rule: w0 = (1.0 × 1 − 0.5 × 0.8) / 0.75 = 0.8 and w1 = (1 × 0.8 − 0.5 × 1.0) / 0.75 = 0.4.
example : ((1 : ℚ) * 1 - 1/2 * (4/5)) / (3/4) = 4 / 5 := by norm_num
example : ((1 : ℚ) * (4/5) - 1/2 * 1) / (3/4) = 2 / 5 := by norm_num
-- pᵀ w_opt = 1.0 × 0.8 + 0.8 × 0.4 = 1.12, so J_min = 1.37 − 1.12 = 0.25, the voice power.
example : (1 : ℚ) * (4/5) + 4/5 * (2/5) = 28 / 25 := by norm_num
example : (137/100 : ℚ) - 28 / 25 = 1 / 4 := by norm_num
-- One tap only, w0 = 1: J = 1.37 − 2 × 1 × 1 + 1 = 0.37.
example : (137/100 : ℚ) - 2 * (1 * 1) + 1 * 1 * 1 = 37 / 100 := by norm_num
-- Taps solved separately, w = (1, 0.8): J = E[d²] − 2 p·w + wᵀ R w = 0.53.
example : (137/100 : ℚ) - 2 * (1 * 1 + 4/5 * (4/5)) +
    (1 * 1 + (4/5) * (4/5) + 2 * (1/2) * 1 * (4/5)) = 53 / 100 := by norm_num
-- Eigenvectors of R: (1, 1) with stretch 3/2 and (1, −1) with stretch 1/2.
example : (!![1, 1/2; 1/2, 1] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, 1] = (3/2 : ℚ) • ![1, 1] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num
example : (!![1, 1/2; 1/2, 1] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, -1] = (1/2 : ℚ) • ![1, -1] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num
-- Step bound 2 / λ_max = 2 / 1.5 = 1.3333 (4/3).
example : (2 : ℚ) / (3/2) = 4 / 3 := by norm_num
-- With μ = 0.01 the gaps shrink by 0.985 and 0.995 per step.
example : (1 : ℚ) - 1/100 * (3/2) = 197 / 200 := by norm_num
example : (1 : ℚ) - 1/100 * (1/2) = 199 / 200 := by norm_num
-- Time constants 1/(μλ): 66.67 (200/3) steps and 200 steps.
example : (1 : ℚ) / (1/100 * (3/2)) = 200 / 3 := by norm_num
example : (1 : ℚ) / (1/100 * (1/2)) = 200 := by norm_num
-- Step 1.4 is too big: the fast factor is 1 − 1.4 × 1.5 = −1.10, of size above 1.
example : (1 : ℚ) - 7/5 * (3/2) = -11 / 10 ∧ |(1 : ℚ) - 7/5 * (3/2)| > 1 := by norm_num
-- The target splits into a sum 0.8 + 0.4 = 1.2 and a difference 0.8 − 0.4 = 0.4.
example : (4/5 : ℚ) + 2/5 = 6 / 5 ∧ (4/5 : ℚ) - 2/5 = 2 / 5 := by norm_num
-- Misadjustment: J_min μ tr R / 2 = 0.25 × 0.01 × 2 / 2 = 0.0025; output power 0.25 × 1.01 = 0.2525.
example : (1/4 : ℚ) * (1/100) * 2 / 2 = 1 / 400 := by norm_num
example : (1/4 : ℚ) * (1 + 1/100 * 2 / 2) = 101 / 400 := by norm_num

#print axioms wiener_hopf_best_filter
#print axioms wiener_noise_canceller_recovers_path
#print axioms steepest_descent_converges_iff
