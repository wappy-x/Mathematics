-- The generator: for the mean-reverting rate, the definition's ratio (E f(r_h) - f(x)) / h tends to drift times slope plus half the squared noise times curvature, powers of a share are eigenfunctions of its generator, and the card's closed form for the exit chance solves Lp = 0 with p = 0 at the bottom edge and 1 at the top.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Probability.Moments.Variance

namespace InfinitesimalGenerator

open MeasureTheory ProbabilityTheory Filter Topology

/-! Mathlib has Brownian motion but no Ito integral and no stochastic differential equations, so
the card's general theorem (for any equation `dX = μ(X) dt + σ(X) dW` with Lipschitz dials) and
Dynkin's formula at a stopping time cannot be written here. This file states the exact parts.

The card's house process is the Ornstein-Uhlenbeck rate `dr = κ(θ - r) dt + σ dW`. Started at `x`,
its value `h` years later has an exact normal law (card "Mean reversion"; the card's code takes
`E_x` under this law): mean `θ + (x - θ) e^(-κh)`, variance `σ²/(2κ) (1 - e^(-2κh))`.
Below, `E_x f(r_h)` is the integral of `f` against that normal law. -/

lemma integral_gaussianReal_eq_std (f : ℝ → ℝ) (hf : Continuous f) (m : ℝ) (v : NNReal) :
    ∫ y, f y ∂gaussianReal m v = ∫ z, f (m + Real.sqrt v * z) ∂gaussianReal 0 1 := by
  have h1 : gaussianReal m v
      = ((gaussianReal 0 1).map (fun z => Real.sqrt v * z)).map (fun y => y + m) := by
    rw [gaussianReal_map_const_mul, gaussianReal_map_add_const]
    congr 1
    · simp
    · ext; simp
  rw [h1, integral_map (by fun_prop) hf.aestronglyMeasurable,
    integral_map (by fun_prop) (by fun_prop)]
  simp [add_comm]

lemma integrable_add_abs_pow_gaussian (A : ℝ) (k : ℕ) :
    Integrable (fun z : ℝ => (A + |z|) ^ k) (gaussianReal 0 1) := by
  have hpow : ∀ j : ℕ, Integrable (fun z : ℝ => |z| ^ j) (gaussianReal 0 1) := by
    intro j
    have := (memLp_id_gaussianReal' (μ := 0) (v := 1) (j : ENNReal) (by simp)).integrable_norm_pow'
    simpa using this
  simp_rw [add_pow]
  refine integrable_finsetSum _ (fun i _ => ?_)
  exact ((hpow (k - i)).const_mul (A ^ i)).mul_const _

lemma taylor_two_bound (f f' f'' : ℝ → ℝ) (hf : ∀ y, HasDerivAt f (f' y) y)
    (hf' : ∀ y, HasDerivAt f' (f'' y) y) (x η ε : ℝ)
    (hη : ∀ y, |y - x| ≤ η → |f'' y - f'' x| ≤ ε) (a t : ℝ)
    (ha : |a - x| ≤ η) (hat : |a + t - x| ≤ η) :
    |f (a + t) - f a - f' a * t - 1 / 2 * f'' x * t ^ 2| ≤ ε * t ^ 2 := by
  have hη0 : 0 ≤ η := le_trans (abs_nonneg _) ha
  have hε0 : 0 ≤ ε := le_trans (abs_nonneg _) (hη x (by simpa using hη0))
  set S := Set.uIcc a (a + t) with hSdef
  have hS : Convex ℝ S := convex_uIcc _ _
  have hSb : ∀ u ∈ S, |u - x| ≤ η := by
    intro u hu
    rw [Set.mem_uIcc] at hu
    rw [abs_le] at ha hat ⊢
    rcases hu with ⟨h1, h2⟩ | ⟨h1, h2⟩ <;> constructor <;> linarith [ha.1, ha.2, hat.1, hat.2]
  have hSd : ∀ u ∈ S, |u - a| ≤ |t| := by
    intro u hu
    rw [Set.mem_uIcc] at hu
    rcases hu with ⟨h1, h2⟩ | ⟨h1, h2⟩
    · rw [abs_of_nonneg (by linarith), abs_of_nonneg (by linarith)]; linarith
    · rw [abs_of_nonpos (by linarith), abs_of_nonpos (by linarith)]; linarith
  have haS : a ∈ S := Set.left_mem_uIcc
  have hbS : a + t ∈ S := Set.right_mem_uIcc
  have step1 : ∀ u ∈ S, |f' u - f' a - f'' x * (u - a)| ≤ ε * |u - a| := by
    intro u hu
    have key := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
      (f := fun y => f' y - f'' x * y) (f' := fun y => f'' y - f'' x) (C := ε)
      (fun y _ => by
        have := (hf' y).sub ((hasDerivAt_id y).const_mul (f'' x))
        refine (this.congr_deriv ?_).hasDerivWithinAt
        simp)
      (fun y hy => by rw [Real.norm_eq_abs]; exact hη y (hSb y hy)) hS haS hu
    rw [Real.norm_eq_abs, Real.norm_eq_abs] at key
    have e : f' u - f' a - f'' x * (u - a) = (f' u - f'' x * u) - (f' a - f'' x * a) := by ring
    rw [e]; exact key
  have key2 := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
      (f := fun u => f u - f' a * u - 1 / 2 * f'' x * (u - a) ^ 2)
      (f' := fun u => f' u - f' a - f'' x * (u - a)) (C := ε * |t|)
      (fun y _ => by
        have := ((hf y).sub ((hasDerivAt_id y).const_mul (f' a))).sub
          ((((hasDerivAt_id y).sub_const a).pow 2).const_mul (1 / 2 * f'' x))
        refine (this.congr_deriv ?_).hasDerivWithinAt
        simp; ring)
      (fun y hy => by
        rw [Real.norm_eq_abs]
        exact (step1 y hy).trans (mul_le_mul_of_nonneg_left (hSd y hy) hε0)) hS haS hbS
  rw [Real.norm_eq_abs, Real.norm_eq_abs] at key2
  have e : f (a + t) - f a - f' a * t - 1 / 2 * f'' x * t ^ 2
      = (f (a + t) - f' a * (a + t) - 1 / 2 * f'' x * (a + t - a) ^ 2)
        - (f a - f' a * a - 1 / 2 * f'' x * (a - a) ^ 2) := by ring
  rw [e]
  calc _ ≤ ε * |t| * |a + t - a| := key2
    _ = ε * t ^ 2 := by rw [add_sub_cancel_left, mul_assoc, ← sq, sq_abs]

lemma gauss_taylor (f : ℝ → ℝ) (hf : ContDiff ℝ 2 f) (C : ℝ) (n : ℕ)
    (hgrowth : ∀ y, |f y| ≤ C * (1 + |y|) ^ n) (x ε : ℝ) (hε : 0 < ε) :
    ∃ δ > 0, ∀ m s : ℝ, |m - x| < δ → 0 ≤ s → s < δ →
      |(∫ z, f (m + s * z) ∂gaussianReal 0 1) - f m - 1 / 2 * deriv (deriv f) x * s ^ 2|
        ≤ ε * s ^ 2 := by
  have tri : ∀ a b : ℝ, |a - b| ≤ |a| + |b| := fun a b => by
    rw [abs_le]; constructor <;> linarith [le_abs_self a, neg_abs_le a, le_abs_self b, neg_abs_le b]
  have hd1 : Differentiable ℝ f := hf.differentiable (by norm_num)
  have hc1 : ContDiff ℝ 1 (deriv f) := ((contDiff_succ_iff_deriv (n := 1)).mp hf).2.2
  have hd2 : Differentiable ℝ (deriv f) := hc1.differentiable one_ne_zero
  have hc2 : Continuous (deriv (deriv f)) := hc1.continuous_deriv le_rfl
  have hfc : Continuous f := hd1.continuous
  set f' := deriv f with hf'def
  set f'' := deriv (deriv f) with hf''def
  have hC : 0 ≤ C := by
    have := hgrowth 0
    simp at this
    linarith [abs_nonneg (f 0)]
  obtain ⟨η₁, hη₁, h1⟩ := Metric.continuous_iff.mp hc2 x (ε / 2) (by positivity)
  obtain ⟨η₂, hη₂, h2⟩ := Metric.continuous_iff.mp hd2.continuous x 1 one_pos
  set η := min (η₁ / 3) (min η₂ 1) with hηdef
  have hη : 0 < η := lt_min (by positivity) (lt_min hη₂ one_pos)
  have hηle1 : η ≤ η₁ / 3 := min_le_left _ _
  have hηle2 : η ≤ η₂ := (min_le_right _ _).trans (min_le_left _ _)
  set A := 2 + |x| with hA
  set K := 2 * C + (|f' x| + 1) + |f'' x| with hK
  have hK0 : 0 ≤ K := by positivity
  set Q : ℝ → ℝ := fun z => K / η ^ 3 * (A + |z|) ^ (n + 5) with hQ
  have hQi : Integrable Q (gaussianReal 0 1) :=
    (integrable_add_abs_pow_gaussian A (n + 5)).const_mul _
  set IQ := ∫ z, Q z ∂gaussianReal 0 1 with hIQdef
  have hIQ : 0 ≤ IQ := integral_nonneg (fun z => by positivity)
  refine ⟨min η (min 1 (ε / (2 * (IQ + 1)))), lt_min hη (lt_min one_pos (by positivity)), ?_⟩
  intro m s hm hs0 hsδ
  have hmη : |m - x| < η := lt_of_lt_of_le hm (min_le_left _ _)
  have hs1 : s ≤ 1 := hsδ.le.trans ((min_le_right _ _).trans (min_le_left _ _))
  have hsε : s ≤ ε / (2 * (IQ + 1)) :=
    hsδ.le.trans ((min_le_right _ _).trans (min_le_right _ _))
  have hm1 : |m| ≤ |x| + 1 := by
    have := abs_sub_abs_le_abs_sub m x
    have : η ≤ 1 := (min_le_right _ _).trans (min_le_right _ _)
    linarith
  have hfm' : |f' m| ≤ |f' x| + 1 := by
    have := h2 m (by rw [Real.dist_eq]; linarith)
    rw [Real.dist_eq] at this
    have := abs_sub_abs_le_abs_sub (f' m) (f' x)
    linarith
  set R : ℝ → ℝ := fun z =>
    f (m + s * z) - f m - f' m * (s * z) - 1 / 2 * f'' x * (s * z) ^ 2 with hR
  have hRb : ∀ z, |R z| ≤ ε / 2 * s ^ 2 * z ^ 2 + s ^ 3 * Q z := by
    intro z
    have hQz : 0 ≤ Q z := by positivity
    by_cases hz : |s * z| ≤ η
    · have := taylor_two_bound f f' f'' (fun y => (hd1 y).hasDerivAt)
        (fun y => (hd2 y).hasDerivAt) x (2 * η) (ε / 2) (fun y hy => by
          have := h1 y (by rw [Real.dist_eq]; linarith)
          rw [Real.dist_eq] at this; exact this.le) m (s * z) (by linarith) (by
            calc |m + s * z - x| = |(m - x) + s * z| := by ring_nf
              _ ≤ |m - x| + |s * z| := abs_add_le _ _
              _ ≤ 2 * η := by linarith)
      have h3 : 0 ≤ s ^ 3 * Q z := by positivity
      calc |R z| ≤ ε / 2 * (s * z) ^ 2 := this
        _ = ε / 2 * s ^ 2 * z ^ 2 := by ring
        _ ≤ _ := by linarith
    · push Not at hz
      have hz0 := abs_nonneg z
      have hx0 := abs_nonneg x
      have hW1 : 1 ≤ A + |z| := by linarith
      have hWz : |z| ≤ A + |z| := by linarith
      have hsz : s * |z| ≤ |z| := by nlinarith
      have e1 : |f (m + s * z)| ≤ C * (A + |z|) ^ n := by
        refine (hgrowth _).trans
          (mul_le_mul_of_nonneg_left (pow_le_pow_left₀ (by positivity) ?_ n) hC)
        have : |m + s * z| ≤ |m| + s * |z| := by
          calc |m + s * z| ≤ |m| + |s * z| := abs_add_le _ _
            _ = |m| + s * |z| := by rw [abs_mul, abs_of_nonneg hs0]
        linarith
      have e2 : |f m| ≤ C * (A + |z|) ^ n := by
        refine (hgrowth _).trans
          (mul_le_mul_of_nonneg_left (pow_le_pow_left₀ (by positivity) ?_ n) hC)
        linarith
      have e3 : |f' m * (s * z)| ≤ (|f' x| + 1) * (A + |z|) := by
        rw [abs_mul, abs_mul, abs_of_nonneg hs0]
        exact mul_le_mul hfm' (by linarith) (by positivity) (by positivity)
      have e4 : |1 / 2 * f'' x * (s * z) ^ 2| ≤ |f'' x| * (A + |z|) ^ 2 := by
        rw [abs_mul, abs_mul, abs_pow, abs_mul, abs_of_nonneg hs0]
        have : s * |z| ≤ A + |z| := by linarith
        have : (s * |z|) ^ 2 ≤ (A + |z|) ^ 2 := pow_le_pow_left₀ (by positivity) this 2
        have h12 : |(1 / 2 : ℝ)| = 1 / 2 := by norm_num
        rw [h12]
        nlinarith [abs_nonneg (f'' x)]
      have eR : |R z| ≤ K * (A + |z|) ^ (n + 2) := by
        have p1 : (A + |z|) ^ n ≤ (A + |z|) ^ (n + 2) := pow_le_pow_right₀ hW1 (by omega)
        have p2 : (A + |z|) ≤ (A + |z|) ^ (n + 2) := by
          calc A + |z| = (A + |z|) ^ 1 := (pow_one _).symm
          _ ≤ _ := pow_le_pow_right₀ hW1 (by omega)
        have p3 : (A + |z|) ^ 2 ≤ (A + |z|) ^ (n + 2) := pow_le_pow_right₀ hW1 (by omega)
        have hsplit : |R z| ≤ |f (m + s * z)| + |f m| + |f' m * (s * z)|
            + |1 / 2 * f'' x * (s * z) ^ 2| := by
          have t1 := tri (f (m + s * z) - f m - f' m * (s * z)) (1 / 2 * f'' x * (s * z) ^ 2)
          have t2 := tri (f (m + s * z) - f m) (f' m * (s * z))
          have t3 := tri (f (m + s * z)) (f m)
          simp only [R]
          linarith
        have hfx1 : 0 ≤ |f' x| + 1 := by positivity
        have q1 := mul_le_mul_of_nonneg_left p1 hC
        have q2 := mul_le_mul_of_nonneg_left p2 hfx1
        have q3 := mul_le_mul_of_nonneg_left p3 (abs_nonneg (f'' x))
        calc |R z| ≤ C * (A + |z|) ^ n + C * (A + |z|) ^ n + (|f' x| + 1) * (A + |z|)
              + |f'' x| * (A + |z|) ^ 2 := by linarith
          _ ≤ C * (A + |z|) ^ (n + 2) + C * (A + |z|) ^ (n + 2)
              + (|f' x| + 1) * (A + |z|) ^ (n + 2) + |f'' x| * (A + |z|) ^ (n + 2) := by
                linarith
          _ = K * (A + |z|) ^ (n + 2) := by simp only [K]; ring
      have hratio : 1 ≤ (s * |z| / η) ^ 3 := by
        apply one_le_pow₀
        rw [le_div_iff₀ hη, one_mul, ← abs_of_nonneg hs0, ← abs_mul]
        exact hz.le
      have h3 : 0 ≤ ε / 2 * s ^ 2 * z ^ 2 := by positivity
      calc |R z| ≤ K * (A + |z|) ^ (n + 2) * (s * |z| / η) ^ 3 :=
            le_mul_of_one_le_right (by positivity) hratio |>.trans' eR
        _ ≤ K * (A + |z|) ^ (n + 2) * (s * (A + |z|) / η) ^ 3 := by gcongr
        _ = s ^ 3 * Q z := by simp only [Q]; field_simp; ring
        _ ≤ _ := by linarith
  have hRc : Continuous R := by simp only [R]; fun_prop
  have hz1 : Integrable (fun z : ℝ => z) (gaussianReal 0 1) :=
    memLp_one_iff_integrable.mp (memLp_id_gaussianReal' (μ := 0) (v := 1) 1 (by simp))
  have hz2 : Integrable (fun z : ℝ => z ^ 2) (gaussianReal 0 1) := by
    refine (integrable_add_abs_pow_gaussian 0 2).congr (ae_of_all _ (fun z => ?_))
    simp
  have hsecond : ∫ z, z ^ 2 ∂gaussianReal 0 1 = 1 := by
    have := variance_fun_id_gaussianReal (μ := 0) (v := 1)
    rw [variance_eq_integral measurable_id'.aemeasurable] at this
    simpa using this
  have hbi : Integrable (fun z => ε / 2 * s ^ 2 * z ^ 2 + s ^ 3 * Q z) (gaussianReal 0 1) :=
    (hz2.const_mul _).add (hQi.const_mul _)
  have hRi : Integrable R (gaussianReal 0 1) :=
    Integrable.mono' hbi hRc.aestronglyMeasurable
      (ae_of_all _ (fun z => by rw [Real.norm_eq_abs]; exact hRb z))
  have hfeq : (fun z => f (m + s * z))
      = fun z => R z + ((f m + (f' m * s) * z) + (1 / 2 * f'' x * s ^ 2) * z ^ 2) := by
    funext z; simp only [R]; ring
  have hint : ∫ z, f (m + s * z) ∂gaussianReal 0 1
      = ∫ z, R z ∂gaussianReal 0 1 + (f m + 1 / 2 * f'' x * s ^ 2) := by
    have i1 : Integrable (fun z => f m + f' m * s * z) (gaussianReal 0 1) :=
      (integrable_const _).add (hz1.const_mul _)
    have i2 : Integrable (fun z => 1 / 2 * f'' x * s ^ 2 * z ^ 2) (gaussianReal 0 1) :=
      hz2.const_mul _
    have i12 : Integrable (fun z => f m + f' m * s * z + 1 / 2 * f'' x * s ^ 2 * z ^ 2)
        (gaussianReal 0 1) := i1.add i2
    have i3 : Integrable (fun z => f' m * s * z) (gaussianReal 0 1) := hz1.const_mul _
    rw [hfeq, integral_add hRi i12, integral_add i1 i2, integral_add (integrable_const _) i3,
      integral_const, integral_const_mul, integral_const_mul, integral_id_gaussianReal, hsecond]
    simp
  have hbound : |∫ z, R z ∂gaussianReal 0 1| ≤ ε / 2 * s ^ 2 + s ^ 3 * IQ := by
    have := norm_integral_le_of_norm_le hbi
      (ae_of_all _ (fun z => by rw [Real.norm_eq_abs]; exact hRb z))
    rw [Real.norm_eq_abs, integral_add (hz2.const_mul _) (hQi.const_mul _), integral_const_mul,
      integral_const_mul, hsecond] at this
    simpa using this
  have hsIQ : s * IQ ≤ ε / 2 := by
    calc s * IQ ≤ ε / (2 * (IQ + 1)) * IQ := mul_le_mul_of_nonneg_right hsε hIQ
      _ ≤ ε / (2 * (IQ + 1)) * (IQ + 1) := by gcongr; linarith
      _ = ε / 2 := by field_simp
  have hs3 : s ^ 3 * IQ ≤ s ^ 2 * (ε / 2) := by
    have : s ^ 3 * IQ = s ^ 2 * (s * IQ) := by ring
    rw [this]; exact mul_le_mul_of_nonneg_left hsIQ (by positivity)
  rw [hint]
  have e : ∫ z, R z ∂gaussianReal 0 1 + (f m + 1 / 2 * f'' x * s ^ 2) - f m
      - 1 / 2 * f'' x * s ^ 2 = ∫ z, R z ∂gaussianReal 0 1 := by ring
  rw [e]
  linarith

#print axioms integral_gaussianReal_eq_std
#print axioms integrable_add_abs_pow_gaussian
#print axioms taylor_two_bound
#print axioms gauss_taylor

/-- The law of the Ornstein-Uhlenbeck rate `h` years after starting at `x`: the normal law with
mean `θ + (x - θ) e^(-κh)` and variance `σ²/(2κ) (1 - e^(-2κh))`. -/
noncomputable def ouLaw (κ θ σ x h : ℝ) : Measure ℝ :=
  gaussianReal (θ + (x - θ) * Real.exp (-κ * h))
    (Real.toNNReal (σ ^ 2 / (2 * κ) * (1 - Real.exp (-2 * κ * h))))

/-- **The generator of the mean-reverting rate.** Take a measurement `f` with two continuous
slopes whose averages exist (it grows at most like a power of the rate). Start the rate at `x`.
Then the definition's ratio, the change in the average of `f` after `h` years per year,
`(E_x f(r_h) - f(x)) / h`, tends as `h` shrinks to drift times slope plus half the squared noise
times curvature: `Lf(x) = κ(θ - x) f'(x) + ½ σ² f''(x)`. -/
theorem ou_generator_eq_drift_slope_add_half_noise_sq_curvature
    (κ θ σ : ℝ) (hκ : 0 < κ) (f : ℝ → ℝ) (hf : ContDiff ℝ 2 f) (C : ℝ) (n : ℕ)
    (hgrowth : ∀ y, |f y| ≤ C * (1 + |y|) ^ n) (x : ℝ) :
    Tendsto (fun h => ((∫ y, f y ∂(ouLaw κ θ σ x h)) - f x) / h) (𝓝[>] 0)
      (𝓝 (κ * (θ - x) * deriv f x + 1 / 2 * σ ^ 2 * deriv (deriv f) x)) := by
  have hd1 : Differentiable ℝ f := hf.differentiable (by norm_num)
  have hfc : Continuous f := hd1.continuous
  set mh : ℝ → ℝ := fun h => θ + (x - θ) * Real.exp (-κ * h) with hmh
  set V : ℝ → ℝ := fun h => σ ^ 2 / (2 * κ) * (1 - Real.exp (-2 * κ * h)) with hV
  set sh : ℝ → ℝ := fun h => Real.sqrt (V h) with hsh
  have hmh0 : mh 0 = x := by simp [mh]
  have hV0 : V 0 = 0 := by simp [V]
  have hmhd : HasDerivAt mh ((x - θ) * (-κ)) 0 := by
    have := ((((hasDerivAt_id (0 : ℝ)).const_mul (-κ)).exp).const_mul (x - θ)).const_add θ
    refine this.congr_deriv ?_
    simp
  have hVd : HasDerivAt V (σ ^ 2) 0 := by
    have := ((((hasDerivAt_id (0 : ℝ)).const_mul (-2 * κ)).exp).const_sub 1).const_mul
      (σ ^ 2 / (2 * κ))
    refine this.congr_deriv ?_
    simp
    field_simp
  have hfm : HasDerivAt (fun h => f (mh h)) (deriv f x * ((x - θ) * (-κ))) 0 := by
    have := (hd1 (mh 0)).hasDerivAt.comp 0 hmhd
    rw [hmh0] at this
    exact this
  have hVnn : ∀ h, 0 ≤ h → 0 ≤ V h := by
    intro h hh
    have : Real.exp (-2 * κ * h) ≤ 1 := Real.exp_le_one_iff.mpr (by nlinarith)
    have : 0 ≤ σ ^ 2 / (2 * κ) := by positivity
    simp only [V]
    nlinarith
  have hVle : ∀ h, 0 ≤ h → V h ≤ σ ^ 2 * h := by
    intro h hh
    have h1 := Real.add_one_le_exp (-2 * κ * h)
    have h2 : 0 ≤ σ ^ 2 / (2 * κ) := by positivity
    have h3 : V h ≤ σ ^ 2 / (2 * κ) * (2 * κ * h) := by
      simp only [V]
      exact mul_le_mul_of_nonneg_left (by linarith) h2
    have h4 : σ ^ 2 / (2 * κ) * (2 * κ * h) = σ ^ 2 * h := by field_simp
    linarith
  -- term 1
  have T1 : Tendsto (fun h => (f (mh h) - f x) / h) (𝓝[>] 0)
      (𝓝 (deriv f x * ((x - θ) * (-κ)))) := by
    refine hfm.tendsto_slope_zero_right.congr (fun h => ?_)
    simp [hmh0, div_eq_inv_mul]
  -- term 3
  have T3 : Tendsto (fun h => V h / h) (𝓝[>] 0) (𝓝 (σ ^ 2)) := by
    refine hVd.tendsto_slope_zero_right.congr (fun h => ?_)
    simp [hV0, div_eq_inv_mul]
  -- term 2
  set E : ℝ → ℝ := fun h => (∫ z, f (mh h + sh h * z) ∂gaussianReal 0 1) - f (mh h)
    - 1 / 2 * deriv (deriv f) x * sh h ^ 2 with hE
  have T2 : Tendsto (fun h => E h / h) (𝓝[>] 0) (𝓝 0) := by
    rw [Metric.tendsto_nhds]
    intro ε hε
    obtain ⟨δ, hδ, hL⟩ := gauss_taylor f hf C n hgrowth x (ε / (2 * (σ ^ 2 + 1))) (by positivity)
    have ev1 : ∀ᶠ h in 𝓝[>] (0 : ℝ), 0 < h := self_mem_nhdsWithin
    have ev2 : ∀ᶠ h in 𝓝[>] (0 : ℝ), dist (mh h) (mh 0) < δ :=
      (Metric.tendsto_nhds.mp hmhd.continuousAt.tendsto δ hδ).filter_mono nhdsWithin_le_nhds
    have hshc : ContinuousAt sh 0 := hVd.continuousAt.sqrt
    have ev3 : ∀ᶠ h in 𝓝[>] (0 : ℝ), dist (sh h) (sh 0) < δ :=
      (Metric.tendsto_nhds.mp hshc.tendsto δ hδ).filter_mono nhdsWithin_le_nhds
    filter_upwards [ev1, ev2, ev3] with h hh h2 h3
    rw [hmh0, Real.dist_eq] at h2
    have hs0 : sh 0 = 0 := by simp [sh, hV0]
    have hshnn : 0 ≤ sh h := Real.sqrt_nonneg _
    rw [hs0, Real.dist_eq, sub_zero, abs_of_nonneg hshnn] at h3
    have hb := hL (mh h) (sh h) h2 hshnn h3
    have hsq : sh h ^ 2 = V h := Real.sq_sqrt (hVnn h hh.le)
    rw [Real.dist_eq, sub_zero, abs_div, abs_of_pos hh, div_lt_iff₀ hh]
    calc |E h| ≤ ε / (2 * (σ ^ 2 + 1)) * sh h ^ 2 := hb
      _ = ε / (2 * (σ ^ 2 + 1)) * V h := by rw [hsq]
      _ ≤ ε / (2 * (σ ^ 2 + 1)) * (σ ^ 2 * h) := by gcongr; exact hVle h hh.le
      _ < ε * h := by
        have : ε / (2 * (σ ^ 2 + 1)) * (σ ^ 2 * h) = ε * h * (σ ^ 2 / (2 * (σ ^ 2 + 1))) := by
          ring
        rw [this]
        have : σ ^ 2 / (2 * (σ ^ 2 + 1)) < 1 := by
          rw [div_lt_one (by positivity)]; nlinarith
        have : 0 < ε * h := by positivity
        nlinarith
  have Tsum := (T1.add T2).add (T3.const_mul (1 / 2 * deriv (deriv f) x))
  have hlim : deriv f x * ((x - θ) * (-κ)) + 0 + 1 / 2 * deriv (deriv f) x * σ ^ 2
      = κ * (θ - x) * deriv f x + 1 / 2 * σ ^ 2 * deriv (deriv f) x := by ring
  rw [hlim] at Tsum
  refine Tsum.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with h (hh : 0 < h)
  have hint : ∫ y, f y ∂(ouLaw κ θ σ x h) = ∫ z, f (mh h + sh h * z) ∂gaussianReal 0 1 := by
    rw [ouLaw, integral_gaussianReal_eq_std f hfc, Real.coe_toNNReal _ (hVnn h hh.le)]
  have hsq : sh h ^ 2 = V h := Real.sq_sqrt (hVnn h hh.le)
  rw [hint]
  simp only [E]
  rw [hsq]
  field_simp
  ring

/-- **Powers are eigenfunctions of the share's generator.** For geometric Brownian motion, with
drift `μ S` and noise `σ S`, the generator applied to the power `S^n` returns the same power times
the number `λ = n μ + ½ n (n - 1) σ²`: `L[S^n] = (n μ + ½ n (n - 1) σ²) S^n`, at every price `S`. -/
theorem gbm_generator_power_eigenfunction (μ σ : ℝ) (n : ℕ) (S : ℝ) :
    μ * S * deriv (fun y : ℝ => y ^ n) S
        + 1 / 2 * σ ^ 2 * S ^ 2 * deriv (deriv (fun y : ℝ => y ^ n)) S
      = (n * μ + 1 / 2 * n * ((n : ℝ) - 1) * σ ^ 2) * S ^ n := by
  have h1 : deriv (fun y : ℝ => y ^ n) = fun y => (n : ℝ) * y ^ (n - 1) := by
    funext y; simp
  rw [h1]
  rcases n with _ | _ | n
  · simp
  · simp
  · have h2 : deriv (fun y : ℝ => ((n + 1 + 1 : ℕ) : ℝ) * y ^ (n + 1 + 1 - 1)) S
        = ((n + 2 : ℕ) : ℝ) * ((n + 1 : ℕ) : ℝ) * S ^ n := by
      simp; ring
    rw [h2]; push_cast; ring

/-- **The exit chance solves its equation (Step 5).** For the mean-reverting rate with pull speed
`κ`, level `θ` and noise `σ ≠ 0`, and a band from `a` to `b > a`, put `c = κ / σ²` and
`p(x) = ∫_a^x e^(c(y-θ)²) dy / ∫_a^b e^(c(y-θ)²) dy`. Then `p(a) = 0`, `p(b) = 1`, and `Lp = 0`
everywhere: `κ(θ - x) p'(x) + ½ σ² p''(x) = 0`. -/
theorem ou_exit_chance_solves_generator_equation (κ θ σ a b : ℝ) (hσ : σ ≠ 0) (hab : a < b) :
    let p : ℝ → ℝ := fun x =>
      (∫ y in a..x, Real.exp (κ / σ ^ 2 * (y - θ) ^ 2)) /
        (∫ y in a..b, Real.exp (κ / σ ^ 2 * (y - θ) ^ 2))
    p a = 0 ∧ p b = 1 ∧
      ∀ x : ℝ, κ * (θ - x) * deriv p x + 1 / 2 * σ ^ 2 * deriv (deriv p) x = 0 := by
  intro p
  set g : ℝ → ℝ := fun y => Real.exp (κ / σ ^ 2 * (y - θ) ^ 2) with hg
  have gc : Continuous g := by fun_prop
  set I := ∫ y in a..b, g y with hIdef
  have hI : 0 < I :=
    intervalIntegral.intervalIntegral_pos_of_pos (gc.intervalIntegrable _ _)
      (fun y => Real.exp_pos _) hab
  have hderiv : ∀ x, HasDerivAt p (g x / I) x := by
    intro x
    have := intervalIntegral.integral_hasDerivAt_right (gc.intervalIntegrable a x)
      (gc.stronglyMeasurableAtFilter _ _) gc.continuousAt
    exact this.div_const I
  have hd : deriv p = fun x => g x / I := funext fun x => (hderiv x).deriv
  have hg' : ∀ x, HasDerivAt g (g x * (κ / σ ^ 2 * (2 * (x - θ)))) x := by
    intro x
    have h0 : HasDerivAt (fun y : ℝ => κ / σ ^ 2 * (y - θ) ^ 2) (κ / σ ^ 2 * (2 * (x - θ))) x := by
      have := ((hasDerivAt_id x).sub_const θ).pow 2
      simpa using this.const_mul (κ / σ ^ 2)
    exact h0.exp
  refine ⟨by simp [p], div_self hI.ne', fun x => ?_⟩
  rw [hd, ((hg' x).div_const I).deriv]
  field_simp
  ring

/-! The card's worked numbers, as exact fractions: rate 6% = 6/100, level θ = 4/100, pull speed
κ = 1/2, noise σ = 2/100; share $100, μ = 5/100 = 1/20, σ = 20/100 = 1/5. -/

-- drift at 6 percent: 0.5 × (0.04 - 0.06) = -0.01
example : (1 / 2 : ℚ) * (4 / 100 - 6 / 100) = -1 / 100 := by norm_num
-- slope of r² at 6 percent: 2 × 0.06 = 0.12
example : (2 : ℚ) * (6 / 100) = 12 / 100 := by norm_num
-- squared noise: 0.02 × 0.02 = 0.0004
example : (2 / 100 : ℚ) * (2 / 100) = 4 / 10000 := by norm_num
-- L[r] at 6 percent: drift times slope 1, curvature 0, gives -0.01
example : (1 / 2 : ℚ) * (4 / 100 - 6 / 100) * 1 + 1 / 2 * (2 / 100) ^ 2 * 0 = -1 / 100 := by
  norm_num
-- L[r²] at 6 percent: -0.0012 + 0.0004 = -0.0008
example : (1 / 2 : ℚ) * (4 / 100 - 6 / 100) * (2 * (6 / 100)) + 1 / 2 * (2 / 100) ^ 2 * 2
    = -8 / 10000 := by norm_num
-- L[(r - θ)²] at 6 percent: -0.01 × 0.04 + 0.0004 = 0
example : (1 / 2 : ℚ) * (4 / 100 - 6 / 100) * (2 * (6 / 100 - 4 / 100)) + 1 / 2 * (2 / 100) ^ 2 * 2
    = 0 := by norm_num
-- the squared gap 0.02² equals the long-run variance σ² / (2κ) = 0.0004
example : (6 / 100 - 4 / 100 : ℚ) ^ 2 = (2 / 100) ^ 2 / (2 * (1 / 2)) := by norm_num
-- the mistakes: no curvature term gives -0.0012 and -0.0004; no half gives -0.0004
example : (1 / 2 : ℚ) * (4 / 100 - 6 / 100) * (2 * (6 / 100)) = -12 / 10000 := by norm_num
example : (1 / 2 : ℚ) * (4 / 100 - 6 / 100) * (2 * (6 / 100 - 4 / 100)) = -4 / 10000 := by norm_num
example : (1 / 2 : ℚ) * (4 / 100 - 6 / 100) * (2 * (6 / 100)) + (2 / 100) ^ 2 * 2
    = -4 / 10000 := by norm_num
-- c = κ / σ² = 0.5 / 0.0004 = 1250
example : (1 / 2 : ℚ) / (2 / 100) ^ 2 = 1250 := by norm_num
-- the tangent line in percent squared: 36 - 8 × 1 = 28 after one year, 20 after two
example : (36 : ℚ) - 8 * 1 = 28 ∧ (36 : ℚ) - 8 * 2 = 20 := by norm_num
-- GBM at $100: L[S] = μ S = 5
example : (1 / 20 : ℚ) * 100 = 5 := by norm_num
-- GBM: L[log S] = μ - σ²/2 = 0.03
example : (1 / 20 : ℚ) - 1 / 2 * (1 / 5) ^ 2 = 3 / 100 := by norm_num
-- GBM at $100: L[S²] = 2 μ S² + σ² S² = 0.14 × 10000 = 1400
example : 2 * (1 / 20 : ℚ) * 100 ^ 2 + (1 / 5) ^ 2 * 100 ^ 2 = 1400 := by norm_num
-- the eigenvalue for n = 2: 2 μ + ½ × 2 × 1 × σ² = 0.14
example : 2 * (1 / 20 : ℚ) + 1 / 2 * 2 * 1 * (1 / 5) ^ 2 = 14 / 100 := by norm_num

#print axioms ou_generator_eq_drift_slope_add_half_noise_sq_curvature
#print axioms gbm_generator_power_eigenfunction
#print axioms ou_exit_chance_solves_generator_equation

end InfinitesimalGenerator
