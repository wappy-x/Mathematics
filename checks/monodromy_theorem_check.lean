-- The monodromy theorem: analytic continuation by chains of discs gives the same final function along any two paths that slide into each other with ends held, square root carried round the unit circle through angle Θ ends at e^(iΘ/2), and on a region with no holes continuation gives one holomorphic function.
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Topology.Homotopy.Basic
import Mathlib.AlgebraicTopology.FundamentalGroupoid.SimplyConnected
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Analytic.Uniqueness
import Mathlib.Order.Filter.Germ.Basic
import Mathlib.Topology.LocallyConstant.Basic
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds

open Metric Filter Topology unitInterval
open scoped Real

/-- A chain of n discs along the path γ(x), 0 ≤ x ≤ 1: times 0 = s₀ < s₁ < ⋯ < sₙ = 1, and for
j = 1, …, n a disc Dⱼ with centre cⱼ and radius rⱼ > 0 holding a holomorphic function fⱼ, such that
the piece γ([sⱼ₋₁, sⱼ]) lies in Dⱼ, and fⱼ = fⱼ₊₁ on Dⱼ ∩ Dⱼ₊₁. The function at the end is fₙ. -/
def IsChainAlong (γ : I → ℂ) (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ)
    (f : ℕ → ℂ → ℂ) : Prop :=
  0 < n ∧ s 0 = 0 ∧ s n = 1 ∧ (∀ j, j < n → s j < s (j + 1)) ∧
  (∀ j, 1 ≤ j → j ≤ n →
    0 < r j ∧ DifferentiableOn ℂ (f j) (ball (c j) (r j)) ∧
    ∀ x : I, s (j - 1) ≤ (x : ℝ) → (x : ℝ) ≤ s j → γ x ∈ ball (c j) (r j)) ∧
  ∀ j, 1 ≤ j → j < n → Set.EqOn (f j) (f (j + 1)) (ball (c j) (r j) ∩ ball (c (j + 1)) (r (j + 1)))

/-- The times of a chain increase weakly. -/
theorem IsChainAlong.s_mono {γ : I → ℂ} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ} {r : ℕ → ℝ}
    {f : ℕ → ℂ → ℂ} (h : IsChainAlong γ n s c r f) {i j : ℕ} (hij : i ≤ j) (hj : j ≤ n) :
    s i ≤ s j := by
  induction j, hij using Nat.le_induction with
  | base => exact le_rfl
  | succ k hik ih => exact (ih (by omega)).trans (h.2.2.2.1 k (by omega)).le

theorem IsChainAlong.s_nonneg {γ : I → ℂ} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ} {r : ℕ → ℝ}
    {f : ℕ → ℂ → ℂ} (h : IsChainAlong γ n s c r f) {j : ℕ} (hj : j ≤ n) : 0 ≤ s j := by
  have := h.s_mono (Nat.zero_le j) hj; rwa [h.2.1] at this

theorem IsChainAlong.s_le_one {γ : I → ℂ} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ} {r : ℕ → ℝ}
    {f : ℕ → ℂ → ℂ} (h : IsChainAlong γ n s c r f) {j : ℕ} (hj : j ≤ n) : s j ≤ 1 := by
  have := h.s_mono hj le_rfl; rwa [h.2.2.1] at this

theorem IsChainAlong.eq_one_of_s_le_zero {γ : I → ℂ} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ}
    {r : ℕ → ℝ} {f : ℕ → ℂ → ℂ} (h : IsChainAlong γ n s c r f) {k : ℕ} (hk1 : 1 ≤ k)
    (hkn : k ≤ n) (hs : s (k - 1) ≤ 0) : k = 1 := by
  by_contra hne
  have h1 : s 0 < s 1 := h.2.2.2.1 0 (by omega)
  have h2 : s 1 ≤ s (k - 1) := h.s_mono (by omega) (by omega)
  rw [h.2.1] at h1
  linarith

theorem IsChainAlong.mem_ball {γ : I → ℂ} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ} {r : ℕ → ℝ}
    {f : ℕ → ℂ → ℂ} (h : IsChainAlong γ n s c r f) {j : ℕ} (hj1 : 1 ≤ j) (hjn : j ≤ n)
    {x : ℝ} (hx1 : s (j - 1) ≤ x) (hx2 : x ≤ s j) :
    γ ⟨x, (h.s_nonneg (by omega)).trans hx1, hx2.trans (h.s_le_one hjn)⟩ ∈ ball (c j) (r j) :=
  (h.2.2.2.2.1 j hj1 hjn).2.2 _ hx1 hx2

theorem IsChainAlong.end_mem {γ : I → ℂ} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ} {r : ℕ → ℝ}
    {f : ℕ → ℂ → ℂ} (h : IsChainAlong γ n s c r f) : γ 1 ∈ ball (c n) (r n) :=
  (h.2.2.2.2.1 n h.1 le_rfl).2.2 1 (h.s_le_one (by omega)) (by rw [h.2.2.1]; rfl)

theorem IsChainAlong.start_mem {γ : I → ℂ} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ} {r : ℕ → ℝ}
    {f : ℕ → ℂ → ℂ} (h : IsChainAlong γ n s c r f) : γ 0 ∈ ball (c 1) (r 1) :=
  (h.2.2.2.2.1 1 le_rfl h.1).2.2 0 (by rw [h.2.1]; rfl) (h.s_nonneg h.1)

/-- Identity principle on the intersection of two discs. -/
theorem eqOn_ball_inter {f g : ℂ → ℂ} {a b : ℂ} {ra rb : ℝ}
    (hf : DifferentiableOn ℂ f (ball a ra)) (hg : DifferentiableOn ℂ g (ball b rb)) {z : ℂ}
    (hz : z ∈ ball a ra ∩ ball b rb) (hfg : f =ᶠ[𝓝 z] g) :
    Set.EqOn f g (ball a ra ∩ ball b rb) := by
  have ho : IsOpen (ball a ra ∩ ball b rb) := isOpen_ball.inter isOpen_ball
  exact AnalyticOnNhd.eqOn_of_preconnected_of_eventuallyEq
    ((hf.mono Set.inter_subset_left).analyticOnNhd ho)
    ((hg.mono Set.inter_subset_right).analyticOnNhd ho)
    ((convex_ball a ra).inter (convex_ball b rb)).isPreconnected hz hfg

/-- Two chains along the same path that start with the same function end with the same
function. -/
theorem IsChainAlong.unique {γ : I → ℂ} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ} {r : ℕ → ℝ}
    {f : ℕ → ℂ → ℂ} {m : ℕ} {s' : ℕ → ℝ} {c' : ℕ → ℂ} {r' : ℕ → ℝ} {g : ℕ → ℂ → ℂ}
    (hf : IsChainAlong γ n s c r f) (hg : IsChainAlong γ m s' c' r' g)
    (h0 : f 1 =ᶠ[𝓝 (γ 0)] g 1) : f n =ᶠ[𝓝 (γ 1)] g m := by
  have key : ∀ N j k, j + k = N → 1 ≤ j → j ≤ n → 1 ≤ k → k ≤ m →
      ∀ x : ℝ, s (j - 1) ≤ x → x ≤ s j → s' (k - 1) ≤ x → x ≤ s' k →
      Set.EqOn (f j) (g k) (ball (c j) (r j) ∩ ball (c' k) (r' k)) := by
    intro N
    induction N using Nat.strong_induction_on with
    | _ N ih =>
    intro j k hN hj1 hjn hk1 hkm x hx1 hx2 hx3 hx4
    have hdf := (hf.2.2.2.2.1 j hj1 hjn).2.1
    have hdg := (hg.2.2.2.2.1 k hk1 hkm).2.1
    by_cases hjk : j = 1 ∧ k = 1
    · obtain ⟨rfl, rfl⟩ := hjk
      refine eqOn_ball_inter hdf hdg ⟨hf.start_mem, hg.start_mem⟩ h0
    rcases le_total (s' (k - 1)) (s (j - 1)) with hle | hle
    · -- the f-piece starts later
      have hj2 : 2 ≤ j := by
        by_contra hj2
        have hj : j = 1 := by omega
        subst hj
        have hk : k = 1 := hg.eq_one_of_s_le_zero hk1 hkm (by simpa [hf.2.1] using hle)
        exact hjk ⟨rfl, hk⟩
      set y := s (j - 1)
      have hy1 : s (j - 1 - 1) ≤ y := hf.s_mono (by omega) (by omega)
      have hprev := ih (j - 1 + k) (by omega) (j - 1) k rfl (by omega) (by omega) hk1 hkm y hy1
        le_rfl hle (hx1.trans hx4)
      have hlink := hf.2.2.2.2.2 (j - 1) (by omega) (by omega)
      rw [show j - 1 + 1 = j by omega] at hlink
      let q : I := ⟨y, hf.s_nonneg (by omega), hf.s_le_one (by omega)⟩
      have hpy1 : γ q ∈ _ := (hf.2.2.2.2.1 (j - 1) (by omega) (by omega)).2.2 q hy1 le_rfl
      have hpy2 : γ q ∈ _ := (hf.2.2.2.2.1 j hj1 hjn).2.2 q le_rfl (hx1.trans hx2)
      have hpy3 : γ q ∈ _ := (hg.2.2.2.2.1 k hk1 hkm).2.2 q hle (hx1.trans hx4)
      have hW : ball (c (j - 1)) (r (j - 1)) ∩ ball (c j) (r j) ∩ ball (c' k) (r' k) ∈ 𝓝 (γ q) :=
        (isOpen_ball.inter isOpen_ball |>.inter isOpen_ball).mem_nhds ⟨⟨hpy1, hpy2⟩, hpy3⟩
      refine eqOn_ball_inter hdf hdg ⟨hpy2, hpy3⟩ ?_
      filter_upwards [hW] with w hw
      rw [← hlink ⟨hw.1.1, hw.1.2⟩]
      exact hprev ⟨hw.1.1, hw.2⟩
    · -- the g-piece starts later
      have hk2 : 2 ≤ k := by
        by_contra hk2
        have hk : k = 1 := by omega
        subst hk
        have hj : j = 1 := hf.eq_one_of_s_le_zero hj1 hjn (by simpa [hg.2.1] using hle)
        exact hjk ⟨hj, rfl⟩
      set y := s' (k - 1)
      have hy1 : s' (k - 1 - 1) ≤ y := hg.s_mono (by omega) (by omega)
      have hprev := ih (j + (k - 1)) (by omega) j (k - 1) rfl hj1 hjn (by omega) (by omega) y
        hle (hx3.trans hx2) hy1 le_rfl
      have hlink := hg.2.2.2.2.2 (k - 1) (by omega) (by omega)
      rw [show k - 1 + 1 = k by omega] at hlink
      let q : I := ⟨y, hg.s_nonneg (by omega), hg.s_le_one (by omega)⟩
      have hpy1 : γ q ∈ _ := (hg.2.2.2.2.1 (k - 1) (by omega) (by omega)).2.2 q hy1 le_rfl
      have hpy2 : γ q ∈ _ := (hg.2.2.2.2.1 k hk1 hkm).2.2 q le_rfl (hx3.trans hx4)
      have hpy3 : γ q ∈ _ := (hf.2.2.2.2.1 j hj1 hjn).2.2 q hle (hx3.trans hx2)
      have hW : ball (c' (k - 1)) (r' (k - 1)) ∩ ball (c' k) (r' k) ∩ ball (c j) (r j) ∈ 𝓝 (γ q) :=
        (isOpen_ball.inter isOpen_ball |>.inter isOpen_ball).mem_nhds ⟨⟨hpy1, hpy2⟩, hpy3⟩
      refine eqOn_ball_inter hdf hdg ⟨hpy3, hpy2⟩ ?_
      filter_upwards [hW] with w hw
      rw [← hlink ⟨hw.1.1, hw.1.2⟩]
      exact hprev ⟨hw.2, hw.1.1⟩
  have hn := hf.1
  have hm := hg.1
  have hE := key (n + m) n m rfl hn le_rfl hm le_rfl 1 (hf.s_le_one (by omega))
    (by rw [hf.2.2.1]) (hg.s_le_one (by omega)) (by rw [hg.2.2.1])
  filter_upwards [(isOpen_ball.inter isOpen_ball).mem_nhds ⟨hf.end_mem, hg.end_mem⟩] with w hw
  exact hE hw

/-- Tube lemma: if a continuous family of paths sends a closed set of times into an open set at
one parameter, it does so for all nearby parameters. -/
theorem eventually_mapsTo_of_closed {X : Type*} [TopologicalSpace X] {Γ : X → I → ℂ}
    (hΓ : Continuous fun p : X × I => Γ p.1 p.2) {x₀ : X} {K : Set I} (hK : IsClosed K)
    {V : Set ℂ} (hV : IsOpen V) (h : ∀ y ∈ K, Γ x₀ y ∈ V) :
    ∀ᶠ x in 𝓝 x₀, ∀ y ∈ K, Γ x y ∈ V :=
  hK.isCompact.eventually_forall_of_forall_eventually fun y hy =>
    (hΓ.continuousAt (x := (x₀, y))).eventually (hV.mem_nhds (h y hy))

/-- A chain of discs along one path of a continuous family is also a chain along every
nearby path of the family. -/
theorem IsChainAlong.eventually {X : Type*} [TopologicalSpace X] {Γ : X → I → ℂ}
    (hΓ : Continuous fun p : X × I => Γ p.1 p.2) {x₀ : X} {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ}
    {r : ℕ → ℝ} {f : ℕ → ℂ → ℂ} (h : IsChainAlong (Γ x₀) n s c r f) :
    ∀ᶠ x in 𝓝 x₀, IsChainAlong (Γ x) n s c r f := by
  have hall : ∀ᶠ x in 𝓝 x₀, ∀ j ∈ Set.Icc 1 n,
      ∀ y ∈ {y : I | s (j - 1) ≤ (y : ℝ) ∧ (y : ℝ) ≤ s j}, Γ x y ∈ ball (c j) (r j) := by
    rw [(Set.finite_Icc 1 n).eventually_all]
    intro j hj
    refine eventually_mapsTo_of_closed hΓ ?_ isOpen_ball ?_
    · exact (isClosed_le continuous_const continuous_subtype_val).inter
        (isClosed_le continuous_subtype_val continuous_const)
    · intro y hy
      exact (h.2.2.2.2.1 j hj.1 hj.2).2.2 y hy.1 hy.2
  filter_upwards [hall] with x hx
  refine ⟨h.1, h.2.1, h.2.2.1, h.2.2.2.1, fun j hj1 hjn => ?_, h.2.2.2.2.2⟩
  exact ⟨(h.2.2.2.2.1 j hj1 hjn).1, (h.2.2.2.2.1 j hj1 hjn).2.1,
    fun y hy1 hy2 => hx j ⟨hj1, hjn⟩ y ⟨hy1, hy2⟩⟩

/-- The branch of the square root near the unit point `e^(ia)`: `e^(ia/2) √(z e^(-ia))`. -/
noncomputable def sqrtBranch (a : ℝ) (z : ℂ) : ℂ :=
  Complex.exp ((Complex.log (z * Complex.exp (-(a : ℂ) * Complex.I)) + a * Complex.I) / 2)

theorem norm_mul_exp_neg_sub_one (a : ℝ) (z : ℂ) :
    ‖z * Complex.exp (-(a : ℂ) * Complex.I) - 1‖ = ‖z - Complex.exp (a * Complex.I)‖ := by
  have h1 : z * Complex.exp (-(a : ℂ) * Complex.I) - 1 =
      (z - Complex.exp (a * Complex.I)) * Complex.exp (-(a : ℂ) * Complex.I) := by
    rw [sub_mul, ← Complex.exp_add, show (a : ℂ) * Complex.I + -(a : ℂ) * Complex.I = 0 by ring,
      Complex.exp_zero]
  rw [h1, norm_mul, show -(a : ℂ) * Complex.I = ((-a : ℝ) : ℂ) * Complex.I by push_cast; ring,
    Complex.norm_exp_ofReal_mul_I, mul_one]

theorem re_pos_of_mem_ball_exp {a : ℝ} {z : ℂ} (hz : z ∈ ball (Complex.exp (a * Complex.I)) 1) :
    0 < (z * Complex.exp (-(a : ℂ) * Complex.I)).re := by
  rw [mem_ball, dist_eq_norm, ← norm_mul_exp_neg_sub_one] at hz
  have := Complex.abs_re_le_norm (z * Complex.exp (-(a : ℂ) * Complex.I) - 1)
  rw [Complex.sub_re, Complex.one_re] at this
  linarith [abs_le.1 this]

theorem differentiableOn_sqrtBranch (a : ℝ) :
    DifferentiableOn ℂ (sqrtBranch a) (ball (Complex.exp (a * Complex.I)) 1) := by
  intro z hz
  have hre := re_pos_of_mem_ball_exp hz
  have hd : DifferentiableAt ℂ (fun z => Complex.log (z * Complex.exp (-(a : ℂ) * Complex.I))) z :=
    (differentiableAt_id.mul_const _).clog (Complex.mem_slitPlane_iff.2 (Or.inl hre))
  exact (((hd.add_const _).div_const 2).cexp).differentiableWithinAt

theorem exp_log_branch {a : ℝ} {z : ℂ} (hz : z ∈ ball (Complex.exp (a * Complex.I)) 1) :
    Complex.exp (Complex.log (z * Complex.exp (-(a : ℂ) * Complex.I)) + a * Complex.I) = z := by
  have hre := re_pos_of_mem_ball_exp hz
  have hne : z * Complex.exp (-(a : ℂ) * Complex.I) ≠ 0 := fun h => by rw [h] at hre; simp at hre
  rw [Complex.exp_add, Complex.exp_log hne, mul_assoc, ← Complex.exp_add]
  simp

theorem abs_im_log_branch {a : ℝ} {z : ℂ} (hz : z ∈ ball (Complex.exp (a * Complex.I)) 1) :
    |(Complex.log (z * Complex.exp (-(a : ℂ) * Complex.I))).im| < π / 2 := by
  rw [Complex.log_im]
  exact Complex.abs_arg_lt_pi_div_two_iff.2 (Or.inl (re_pos_of_mem_ball_exp hz))

theorem sqrtBranch_eqOn {a b : ℝ} (hab : |a - b| < 1) :
    Set.EqOn (sqrtBranch a) (sqrtBranch b)
      (ball (Complex.exp (a * Complex.I)) 1 ∩ ball (Complex.exp (b * Complex.I)) 1) := by
  intro z hz
  have ea := exp_log_branch hz.1
  have eb := exp_log_branch hz.2
  obtain ⟨k, hk⟩ := Complex.exp_eq_exp_iff_exists_int.1 (ea.trans eb.symm)
  have him := congrArg Complex.im hk
  simp only [Complex.add_im, Complex.mul_im, Complex.ofReal_re, Complex.ofReal_im, Complex.I_re,
    Complex.I_im, Complex.intCast_re, Complex.intCast_im, Complex.re_ofNat, Complex.im_ofNat,
    mul_zero, mul_one, zero_mul, add_zero] at him
  have h2 : (2 * (π : ℂ)).re = 2 * π := by simp
  rw [h2] at him
  have ha := abs_lt.1 (abs_im_log_branch hz.1)
  have hb := abs_lt.1 (abs_im_log_branch hz.2)
  have hab' := abs_lt.1 hab
  have hpi := Real.pi_gt_three
  have hk1 : (k : ℝ) < 1 := by nlinarith
  have hk2 : (-1 : ℝ) < k := by nlinarith
  have hk0 : k = 0 := by
    have : k < 1 := by exact_mod_cast hk1
    have : -1 < k := by exact_mod_cast hk2
    omega
  subst hk0
  simp only [Int.cast_zero, zero_mul, add_zero] at hk
  simp only [sqrtBranch]
  rw [hk]

theorem norm_exp_mul_I_sub_le (u v : ℝ) :
    ‖Complex.exp (u * Complex.I) - Complex.exp (v * Complex.I)‖ ≤ |u - v| := by
  have h : Complex.exp (u * Complex.I) - Complex.exp (v * Complex.I) =
      Complex.exp (v * Complex.I) * (Complex.exp (Complex.I * ((u - v : ℝ) : ℂ)) - 1) := by
    rw [mul_sub, ← Complex.exp_add, mul_one]; push_cast; ring_nf
  rw [h, norm_mul, Complex.norm_exp_ofReal_mul_I, one_mul]
  exact (Real.norm_exp_I_mul_ofReal_sub_one_le).trans (le_of_eq (Real.norm_eq_abs _))

theorem sqrtBranch_exp {a u : ℝ} (h : |u - a| < π) :
    sqrtBranch a (Complex.exp (u * Complex.I)) = Complex.exp ((u / 2 : ℝ) * Complex.I) := by
  have h1 : Complex.exp (u * Complex.I) * Complex.exp (-(a : ℂ) * Complex.I) =
      Complex.exp (((u - a : ℝ) : ℂ) * Complex.I) := by
    rw [← Complex.exp_add]; push_cast; ring_nf
  have hb := abs_lt.1 h
  have h2 : Complex.log (Complex.exp (((u - a : ℝ) : ℂ) * Complex.I)) = ((u - a : ℝ) : ℂ) * Complex.I := by
    apply Complex.log_exp <;> simp <;> linarith
  simp only [sqrtBranch]
  rw [h1, h2]
  congr 1
  push_cast
  ring

/-- An explicit chain of discs carrying the principal square root round the circle. -/
theorem sqrt_chain (Θ : ℝ) :
    ∃ (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ) (f : ℕ → ℂ → ℂ),
      IsChainAlong (fun x : I => Complex.exp ((Θ * (x : ℝ) : ℝ) * Complex.I)) n s c r f ∧
        (f 1 =ᶠ[𝓝 1] fun z => z ^ (1 / 2 : ℂ)) ∧
        f n (Complex.exp (Θ * Complex.I)) = Complex.exp ((Θ / 2 : ℝ) * Complex.I) := by
  set N : ℕ := ⌈|Θ|⌉₊ + 1 with hN
  have hNpos : (0 : ℝ) < N := by positivity
  have hΘN : |Θ| < N := by
    have := Nat.le_ceil |Θ|
    rw [hN]; push_cast; linarith
  have hδ : |Θ| / N < 1 := (div_lt_one hNpos).2 hΘN
  let s : ℕ → ℝ := fun j => (j : ℝ) / N
  let a : ℕ → ℝ := fun j => Θ * s (j - 1)
  have hstep : ∀ j, 1 ≤ j → s j - s (j - 1) = 1 / N := by
    intro j hj
    obtain ⟨i, rfl⟩ : ∃ i, j = i + 1 := ⟨j - 1, by omega⟩
    simp only [s, Nat.add_sub_cancel]
    push_cast
    field_simp
    ring
  have ha : ∀ j, 1 ≤ j → |a (j + 1) - a j| = |Θ| / N := by
    intro j hj
    have := hstep j hj
    simp only [a, Nat.add_sub_cancel]
    rw [← mul_sub, this, abs_mul, abs_div, abs_one, abs_of_pos hNpos]
    ring
  refine ⟨N, s, fun j => Complex.exp (a j * Complex.I), fun _ => 1, fun j => sqrtBranch (a j),
    ⟨by omega, by simp [s], by simp [s, hNpos.ne'], fun j _ => ?_, fun j hj1 hjn => ?_,
      fun j hj1 hjn => ?_⟩, ?_, ?_⟩
  · simp only [s]
    exact div_lt_div_of_pos_right (by push_cast; linarith) hNpos
  · refine ⟨one_pos, differentiableOn_sqrtBranch _, fun x hx1 hx2 => ?_⟩
    rw [mem_ball, dist_eq_norm]
    refine (norm_exp_mul_I_sub_le _ _).trans_lt ?_
    have hs := hstep j hj1
    simp only [a]
    rw [← mul_sub, abs_mul, abs_of_nonneg (sub_nonneg.2 hx1)]
    calc |Θ| * ((x : ℝ) - s (j - 1)) ≤ |Θ| * (1 / N) := by
          apply mul_le_mul_of_nonneg_left _ (abs_nonneg _); linarith
      _ = |Θ| / N := by ring
      _ < 1 := hδ
  · have h := sqrtBranch_eqOn (a := a j) (b := a (j + 1)) (by
      rw [abs_sub_comm, ha j hj1]; exact hδ)
    exact h
  · have h1 : a 1 = 0 := by simp [a, s]
    filter_upwards [eventually_ne_nhds (one_ne_zero : (1 : ℂ) ≠ 0)] with z hz
    simp only [h1, sqrtBranch, Complex.ofReal_zero, neg_zero, zero_mul, Complex.exp_zero,
      mul_one, add_zero]
    rw [Complex.cpow_def_of_ne_zero hz]
    ring_nf
  · apply sqrtBranch_exp
    have hNj : a N = Θ * s (N - 1) := rfl
    have hs := hstep N (by omega)
    have : Θ - a N = Θ * (1 / N) := by
      rw [hNj, ← hs, mul_sub]; simp [s, hNpos.ne']
    rw [this, abs_mul, abs_div, abs_one, abs_of_pos hNpos]
    have := Real.pi_gt_three
    calc |Θ| * (1 / N) = |Θ| / N := by ring
      _ < 1 := hδ
      _ < π := by linarith

#print axioms IsChainAlong.s_mono
#print axioms IsChainAlong.s_nonneg
#print axioms IsChainAlong.s_le_one
#print axioms IsChainAlong.eq_one_of_s_le_zero
#print axioms IsChainAlong.mem_ball
#print axioms IsChainAlong.end_mem
#print axioms IsChainAlong.start_mem
#print axioms eqOn_ball_inter
#print axioms IsChainAlong.unique
#print axioms eventually_mapsTo_of_closed
#print axioms IsChainAlong.eventually
#print axioms sqrtBranch
#print axioms norm_mul_exp_neg_sub_one
#print axioms re_pos_of_mem_ball_exp
#print axioms differentiableOn_sqrtBranch
#print axioms exp_log_branch
#print axioms abs_im_log_branch
#print axioms sqrtBranch_eqOn
#print axioms norm_exp_mul_I_sub_le
#print axioms sqrtBranch_exp
#print axioms sqrt_chain

/-- The monodromy theorem. Let the path γ₀ slide into the path γ₁ through paths γₜ(x) = H(t, x),
with both ends held still, and suppose the function f₀, given near the start, can be continued
by a chain of discs along every path γₜ of the slide. Then any chain continuing f₀ along γ₀ and
any chain continuing f₀ along γ₁ end with the same function near the common end point. -/
theorem continuation_eq_of_homotopic {γ₀ γ₁ : C(I, ℂ)} (H : γ₀.HomotopyRel γ₁ {0, 1})
    (f₀ : ℂ → ℂ)
    (hslide : ∀ t : I, ∃ (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ) (f : ℕ → ℂ → ℂ),
      IsChainAlong (fun x => H (t, x)) n s c r f ∧ f 1 =ᶠ[𝓝 (H (t, 0))] f₀)
    {n : ℕ} {s : ℕ → ℝ} {c : ℕ → ℂ} {r : ℕ → ℝ} {f : ℕ → ℂ → ℂ}
    (hf : IsChainAlong γ₀ n s c r f) (hf₀ : f 1 =ᶠ[𝓝 (γ₀ 0)] f₀)
    {m : ℕ} {s' : ℕ → ℝ} {c' : ℕ → ℂ} {r' : ℕ → ℝ} {g : ℕ → ℂ → ℂ}
    (hg : IsChainAlong γ₁ m s' c' r' g) (hg₀ : g 1 =ᶠ[𝓝 (γ₁ 0)] f₀) :
    f n =ᶠ[𝓝 (γ₀ 1)] g m := by
  classical
  choose N S C R F hF hF0 using hslide
  have hend : ∀ t, H (t, 1) = γ₀ 1 := fun t => H.eq_fst t (by simp)
  have hstart : ∀ t, H (t, 0) = γ₀ 0 := fun t => H.eq_fst t (by simp)
  have hend' : γ₁ 1 = γ₀ 1 := by rw [← H.eq_snd 0 (by simp : (1 : I) ∈ ({0, 1} : Set I))]; exact hend 0
  have hstart' : γ₁ 0 = γ₀ 0 := by
    rw [← H.eq_snd 0 (by simp : (0 : I) ∈ ({0, 1} : Set I))]; exact hstart 0
  let φ : I → Germ (𝓝 (γ₀ 1)) ℂ := fun t => ↑(F t (N t))
  have hloc : IsLocallyConstant φ := by
    rw [IsLocallyConstant.iff_eventually_eq]
    intro t
    have hev := IsChainAlong.eventually (Γ := fun t x => H (t, x)) H.continuous (hF t)
    filter_upwards [hev] with t' ht'
    have h0 : F t 1 =ᶠ[𝓝 (H (t', 0))] F t' 1 := by
      have a := hF0 t
      have b := hF0 t'
      rw [hstart] at a b ⊢
      exact a.trans b.symm
    have hu := IsChainAlong.unique ht' (hF t') h0
    rw [hend] at hu
    exact Germ.coe_eq.2 hu.symm
  have hφ := hloc.apply_eq_of_preconnectedSpace 0 1
  have h0eq : (fun x => H (0, x)) = (γ₀ : I → ℂ) := funext fun x => H.apply_zero x
  have h1eq : (fun x => H (1, x)) = (γ₁ : I → ℂ) := funext fun x => H.apply_one x
  have hA : f n =ᶠ[𝓝 (γ₀ 1)] F 0 (N 0) := by
    have hc := hF 0
    have hc0 := hF0 0
    rw [h0eq] at hc
    rw [hstart] at hc0
    exact hf.unique hc (hf₀.trans hc0.symm)
  have hB : F 1 (N 1) =ᶠ[𝓝 (γ₀ 1)] g m := by
    have hc := hF 1
    have hc0 := hF0 1
    rw [h1eq] at hc
    rw [hstart, ← hstart'] at hc0
    have := hc.unique hg (hc0.trans hg₀.symm)
    rwa [hend'] at this
  exact hA.trans ((Germ.coe_eq.1 hφ).trans hB)

/-- Square root round the unit circle. Start with the principal square root near 1 (so √1 = 1)
and walk the circle e^(iθx), 0 ≤ x ≤ 1, through the total angle Θ. A chain of discs carrying √z
along this path exists, and every such chain arrives at e^(iΘ) with the value e^(iΘ/2):
i for the upper half (Θ = π), −i for the lower half (Θ = −π), −1 once round, +1 twice round. -/
theorem sqrt_continuation_round_circle (Θ : ℝ) :
    (∃ (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ) (f : ℕ → ℂ → ℂ),
      IsChainAlong (fun x : I => Complex.exp ((Θ * (x : ℝ) : ℝ) * Complex.I)) n s c r f ∧
        f 1 =ᶠ[𝓝 1] fun z => z ^ (1 / 2 : ℂ)) ∧
    ∀ (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ) (f : ℕ → ℂ → ℂ),
      IsChainAlong (fun x : I => Complex.exp ((Θ * (x : ℝ) : ℝ) * Complex.I)) n s c r f →
      (f 1 =ᶠ[𝓝 1] fun z => z ^ (1 / 2 : ℂ)) →
      f n (Complex.exp (Θ * Complex.I)) = Complex.exp ((Θ / 2 : ℝ) * Complex.I) := by
  obtain ⟨N, S, C, R, F, hc, h1, hend⟩ := sqrt_chain Θ
  refine ⟨⟨N, S, C, R, F, hc, h1⟩, fun n s c r f hf hf1 => ?_⟩
  have h0 : Complex.exp ((Θ * ((0 : I) : ℝ) : ℝ) * Complex.I) = 1 := by simp
  have hu := hf.unique hc (by rw [h0]; exact hf1.trans h1.symm)
  have hpt := hu.eq_of_nhds
  have h1' : Complex.exp ((Θ * ((1 : I) : ℝ) : ℝ) * Complex.I) =
      Complex.exp (Θ * Complex.I) := by simp
  rw [h1'] at hpt
  rw [hpt, hend]

/-- No holes, one function. Let U be an open, simply connected region and z₀ a point of U, and
suppose the function f₀ near z₀ can be continued by a chain of discs along every path in U that
starts at z₀. Then there is one function F, holomorphic on U, such that every chain continuing
f₀ along any path in U from z₀ ends with F near the path's end point: the answer does not
depend on the path. -/
theorem exists_continuation_of_simply_connected {U : Set ℂ} (hU : IsOpen U)
    [SimplyConnectedSpace U] {z₀ : ℂ} (hz₀ : z₀ ∈ U) (f₀ : ℂ → ℂ)
    (hcont : ∀ γ : C(I, ℂ), (∀ x, γ x ∈ U) → γ 0 = z₀ →
      ∃ (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ) (f : ℕ → ℂ → ℂ),
        IsChainAlong γ n s c r f ∧ f 1 =ᶠ[𝓝 z₀] f₀) :
    ∃ F : ℂ → ℂ, DifferentiableOn ℂ F U ∧
      ∀ γ : C(I, ℂ), (∀ x, γ x ∈ U) → γ 0 = z₀ →
      ∀ (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ) (f : ℕ → ℂ → ℂ),
        IsChainAlong γ n s c r f → f 1 =ᶠ[𝓝 z₀] f₀ → f n =ᶠ[𝓝 (γ 1)] F := by
  classical
  -- Path independence.
  have key : ∀ (γ γ' : C(I, ℂ)) (hγ : ∀ x, γ x ∈ U) (hγ' : ∀ x, γ' x ∈ U),
      γ 0 = z₀ → γ' 0 = z₀ → γ' 1 = γ 1 →
      ∀ (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ) (f : ℕ → ℂ → ℂ),
        IsChainAlong γ n s c r f → f 1 =ᶠ[𝓝 z₀] f₀ →
      ∀ (m : ℕ) (s' : ℕ → ℝ) (c' : ℕ → ℂ) (r' : ℕ → ℝ) (g : ℕ → ℂ → ℂ),
        IsChainAlong γ' m s' c' r' g → g 1 =ᶠ[𝓝 z₀] f₀ → f n =ᶠ[𝓝 (γ 1)] g m := by
    intro γ γ' hγ hγ' h0 h0' h1 n s c r f hc hc0 m s' c' r' g hd hd0
    let P : Path (⟨z₀, hz₀⟩ : U) ⟨γ 1, hγ 1⟩ :=
      { toFun := fun x => ⟨γ x, hγ x⟩
        continuous_toFun := γ.continuous.subtype_mk _
        source' := Subtype.ext h0
        target' := rfl }
    let P' : Path (⟨z₀, hz₀⟩ : U) ⟨γ 1, hγ 1⟩ :=
      { toFun := fun x => ⟨γ' x, hγ' x⟩
        continuous_toFun := γ'.continuous.subtype_mk _
        source' := Subtype.ext h0'
        target' := Subtype.ext h1 }
    obtain ⟨Hp⟩ := SimplyConnectedSpace.paths_homotopic P P'
    let v : C(U, ℂ) := ⟨Subtype.val, continuous_subtype_val⟩
    let H : γ.HomotopyRel γ' {0, 1} :=
      (Hp.compContinuousMap v).cast (ContinuousMap.ext fun _ => rfl)
        (ContinuousMap.ext fun _ => rfl)
    have hHU : ∀ t x, H (t, x) ∈ U := fun t x => (Hp (t, x)).2
    have hH0 : ∀ t, H (t, 0) = z₀ := fun t => (H.eq_fst t (by simp)).trans h0
    refine continuation_eq_of_homotopic H f₀ (fun t => ?_) hc (h0 ▸ hc0) hd (h0' ▸ hd0)
    obtain ⟨n, s, c, r, f, h1, h2⟩ :=
      hcont ⟨fun x => H (t, x), H.continuous.comp (Continuous.prodMk_right t)⟩ (hHU t) (hH0 t)
    exact ⟨n, s, c, r, f, h1, (hH0 t).symm ▸ h2⟩
  -- A chosen path and chain to every point of U.
  have hex : ∀ z, z ∈ U → ∃ (γ : C(I, ℂ)) (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ)
      (f : ℕ → ℂ → ℂ), (∀ x, γ x ∈ U) ∧ γ 0 = z₀ ∧ γ 1 = z ∧ IsChainAlong γ n s c r f ∧
        f 1 =ᶠ[𝓝 z₀] f₀ := by
    intro z hz
    let P := PathConnectedSpace.somePath (⟨z₀, hz₀⟩ : U) ⟨z, hz⟩
    let γ : C(I, ℂ) := ⟨fun x => (P x : ℂ), continuous_subtype_val.comp P.continuous⟩
    obtain ⟨n, s, c, r, f, h1, h2⟩ := hcont γ (fun x => (P x).2) (by simp [γ])
    exact ⟨γ, n, s, c, r, f, fun x => (P x).2, by simp [γ], by simp [γ], h1, h2⟩
  choose Γ N S C R Fs hmem h0 h1 hch hst using hex
  let F : ℂ → ℂ := fun z => if hz : z ∈ U then Fs z hz (N z hz) z else 0
  have main : ∀ γ : C(I, ℂ), (∀ x, γ x ∈ U) → γ 0 = z₀ →
      ∀ (n : ℕ) (s : ℕ → ℝ) (c : ℕ → ℂ) (r : ℕ → ℝ) (f : ℕ → ℂ → ℂ),
        IsChainAlong γ n s c r f → f 1 =ᶠ[𝓝 z₀] f₀ → f n =ᶠ[𝓝 (γ 1)] F := by
    intro γ hγ hγ0 n s c r f hc hc0
    let Φ : ℂ → I → ℂ := fun z x => γ x + (x : ℂ) * (z - γ 1)
    have hΦ : Continuous fun p : ℂ × I => Φ p.1 p.2 := by
      simp only [Φ]
      fun_prop
    have hΦ1 : Φ (γ 1) = γ := funext fun x => by simp [Φ]
    have hc' : IsChainAlong (Φ (γ 1)) n s c r f := by rw [hΦ1]; exact hc
    have hev1 := IsChainAlong.eventually hΦ hc'
    have hev2 : ∀ᶠ z in 𝓝 (γ 1), ∀ y ∈ (Set.univ : Set I), Φ z y ∈ U :=
      eventually_mapsTo_of_closed hΦ isClosed_univ hU (fun y _ => by rw [hΦ1]; exact hγ y)
    filter_upwards [hev1, hev2] with z hz1 hz2
    have hzU : z ∈ U := by simpa [Φ] using hz2 1 trivial
    let γz : C(I, ℂ) := ⟨Φ z, by
      have : Continuous fun x : I => Φ z x := by simp only [Φ]; fun_prop
      exact this⟩
    have hγz0 : γz 0 = z₀ := by simp [γz, Φ, hγ0]
    have hγz1 : γz 1 = z := by simp [γz, Φ]
    have := key γz (Γ z hzU) (fun x => hz2 x trivial) (hmem z hzU) hγz0 (h0 z hzU)
      ((h1 z hzU).trans hγz1.symm) n s c r f hz1 hc0 _ _ _ _ _ (hch z hzU) (hst z hzU)
    have := this.eq_of_nhds
    rw [hγz1] at this
    simp only [F, hzU, ↓reduceDIte]
    exact this
  refine ⟨F, fun z hz => ?_, main⟩
  have hE := main (Γ z hz) (hmem z hz) (h0 z hz) _ _ _ _ _ (hch z hz) (hst z hz)
  rw [h1 z hz] at hE
  have hmemb := (hch z hz).end_mem
  rw [h1 z hz] at hmemb
  have hd := ((hch z hz).2.2.2.2.1 (N z hz) (hch z hz).1 le_rfl).2.1
  exact ((hd.differentiableAt (isOpen_ball.mem_nhds hmemb)).congr_of_eventuallyEq
    hE.symm).differentiableWithinAt

-- Worked numbers: the upper half ends at i and the lower half at -i, both square roots of -1;
-- once round is i × i = -1, twice round is (-1) × (-1) = +1.
example : Complex.I ^ 2 = -1 := by norm_num
example : (-Complex.I) ^ 2 = -1 := by norm_num
example : Complex.I * Complex.I = -1 := by norm_num
example : (-1 : ℂ) * (-1) = 1 := by norm_num

#print axioms continuation_eq_of_homotopic
#print axioms sqrt_continuation_round_circle
#print axioms exists_continuation_of_simply_connected
