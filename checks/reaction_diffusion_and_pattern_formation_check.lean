-- Reaction-diffusion: a stable uniform state of two reacting, spreading signals has a growing ripple exactly when Dv fu + Du gv > 2 sqrt(Du Dv det J), and Fisher's equation has a nonnegative front of speed c exactly when c is at least 2 sqrt(r D).
import Mathlib.LinearAlgebra.Eigenspace.Charpoly
import Mathlib.LinearAlgebra.Charpoly.ToMatrix
import Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Analysis.Calculus.UniformLimitsDeriv
import Mathlib.Analysis.Calculus.Deriv.Inverse
import Mathlib.Analysis.Calculus.Deriv.CompMul
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Filter Topology

lemma rd_hasEigenvalue_fin_two_iff (a b c d : ℝ) (σ : ℂ) :
    Module.End.HasEigenvalue (Matrix.toLin' ((!![a, b; c, d]).map (fun x : ℝ => (x : ℂ)))) σ ↔
      σ ^ 2 - ((a + d : ℝ) : ℂ) * σ + ((a * d - b * c : ℝ) : ℂ) = 0 := by
  rw [Module.End.hasEigenvalue_iff_isRoot_charpoly, Matrix.charpoly_toLin',
    Matrix.charpoly_fin_two]
  simp [Matrix.trace_fin_two, Matrix.det_fin_two]

lemma rd_exists_pos_root_iff (t d : ℝ) (ht : t < 0) :
    (∃ σ : ℂ, 0 < σ.re ∧ σ ^ 2 - (t : ℂ) * σ + (d : ℂ) = 0) ↔ d < 0 := by
  constructor
  · rintro ⟨σ, hre, hσ⟩
    have h1 := congrArg Complex.re hσ
    have h2 := congrArg Complex.im hσ
    simp [pow_two] at h1 h2
    have hy : σ.im = 0 := by
      by_contra hne
      have : σ.re * 2 - t = 0 := by
        have : σ.im * (σ.re * 2 - t) = 0 := by linarith
        rcases mul_eq_zero.mp this with h | h
        · exact absurd h hne
        · exact h
      linarith
    rw [hy] at h1
    nlinarith
  · intro hd
    set s := Real.sqrt (t ^ 2 - 4 * d) with hs
    have hs2 : s ^ 2 = t ^ 2 - 4 * d := Real.sq_sqrt (by nlinarith)
    have hs0 : 0 ≤ s := Real.sqrt_nonneg _
    refine ⟨(((t + s) / 2 : ℝ) : ℂ), ?_, ?_⟩
    · simp only [Complex.ofReal_re]
      nlinarith
    · have : ((t + s) / 2) ^ 2 - t * ((t + s) / 2) + d = 0 := by nlinarith
      exact_mod_cast this

lemma rd_sub_le_of_deriv_le {f : ℝ → ℝ} (hf : Differentiable ℝ f) {a C : ℝ}
    (h : ∀ x, a < x → deriv f x ≤ C) {x y : ℝ} (hax : a ≤ x) (hxy : x ≤ y) :
    f y - f x ≤ C * (y - x) :=
  (convex_Ici a).image_sub_le_mul_sub_of_deriv_le hf.continuous.continuousOn
    hf.differentiableOn (fun z hz => h z (by rwa [interior_Ici] at hz)) x hax y
    (hax.trans hxy) hxy

lemma rd_le_sub_of_le_deriv {f : ℝ → ℝ} (hf : Differentiable ℝ f) {a C : ℝ}
    (h : ∀ x, a < x → C ≤ deriv f x) {x y : ℝ} (hax : a ≤ x) (hxy : x ≤ y) :
    C * (y - x) ≤ f y - f x :=
  (convex_Ici a).mul_sub_le_image_sub_of_le_deriv hf.continuous.continuousOn
    hf.differentiableOn (fun z hz => h z (by rwa [interior_Ici] at hz)) x hax y
    (hax.trans hxy) hxy

lemma rd_fisher_speed_ge_of_front (D r c : ℝ) (hD : 0 < D) (hr : 0 < r) (U : ℝ → ℝ)
    (hU : ContDiff ℝ 2 U)
    (hode : ∀ ξ, D * deriv (deriv U) ξ + c * deriv U ξ + r * U ξ * (1 - U ξ) = 0)
    (hbot : Tendsto U atBot (𝓝 1)) (htop : Tendsto U atTop (𝓝 0)) (hnn : ∀ ξ, 0 ≤ U ξ) :
    2 * Real.sqrt (r * D) ≤ c := by
  have h2 : ContDiff ℝ (1 + 1) U := hU
  rw [contDiff_succ_iff_deriv] at h2
  have hUd : Differentiable ℝ U := h2.1
  have hU'd : Differentiable ℝ (deriv U) := h2.2.2.differentiable (by norm_num)
  have hUc : Continuous U := hUd.continuous
  by_contra hcon
  rw [not_le] at hcon
  rcases le_or_gt c 0 with hc | hc
  · -- energy argument
    set E : ℝ → ℝ := fun x => D / 2 * (deriv U x) ^ 2 + r * (U x ^ 2 / 2 - U x ^ 3 / 3) with hEdef
    have hE : ∀ x, HasDerivAt E (-c * (deriv U x) ^ 2) x := by
      intro x
      have h1 := (hU'd x).hasDerivAt
      have h0 := (hUd x).hasDerivAt
      have := ((h1.pow 2).const_mul (D / 2)).add
        ((((h0.pow 2).div_const 2).sub ((h0.pow 3).div_const 3)).const_mul r)
      convert this using 1
      simp only [Nat.cast_ofNat]
      linear_combination (-(deriv U x)) * hode x
    have hEmono : Monotone E :=
      monotone_of_hasDerivAt_nonneg hE (fun x => mul_nonneg (by linarith) (sq_nonneg _))
    set F : ℝ → ℝ := fun u => r * (u ^ 2 / 2 - u ^ 3 / 3) with hF
    have hFc : Continuous F := by fun_prop
    have hF1 : F 1 = r / 6 := by simp only [hF]; ring
    have hF0 : F 0 = 0 := by simp only [hF]; ring
    have hFbot : Tendsto (fun x => F (U x)) atBot (𝓝 (r / 6)) := by
      have := (hFc.tendsto 1).comp hbot
      rw [hF1] at this; exact this
    have hFtop : Tendsto (fun x => F (U x)) atTop (𝓝 0) := by
      have := (hFc.tendsto 0).comp htop
      rw [hF0] at this; exact this
    have hElow : ∀ x, r / 6 ≤ E x := by
      intro x
      apply le_of_tendsto hFbot
      rw [eventually_atBot]
      refine ⟨x, fun y hy => ?_⟩
      have := hEmono hy
      have : F (U y) ≤ E y := by
        simp only [hF, hEdef]; nlinarith [sq_nonneg (deriv U y)]
      linarith
    have ev1 : ∀ᶠ x in atTop, F (U x) < r / 12 := hFtop.eventually (gt_mem_nhds (by positivity))
    have ev2 : ∀ᶠ x in atTop, |U x| < 1 / 4 := by
      have := htop.eventually (Metric.ball_mem_nhds (0 : ℝ) (by norm_num : (0 : ℝ) < 1 / 4))
      filter_upwards [this] with x hx
      simpa [Real.dist_eq] using hx
    obtain ⟨N, hN⟩ := eventually_atTop.mp (ev1.and ev2)
    have hd2 : ∀ x, N ≤ x → r / (6 * D) < (deriv U x) ^ 2 := by
      intro x hx
      have h1 := hElow x
      have h2 := (hN x hx).1
      simp only [hF, hEdef] at h1 h2
      rw [div_lt_iff₀ (by positivity)]
      nlinarith
    set L : ℝ := 1 + 2 * D / r with hL
    have hL1 : 1 ≤ L := by
      have : 0 ≤ 2 * D / r := by positivity
      linarith
    obtain ⟨η, hη, hslope⟩ := exists_deriv_eq_slope U (by linarith : N < N + L)
      hUc.continuousOn hUd.differentiableOn
    have hη2 := hd2 η hη.1.le
    rw [hslope, show N + L - N = L by ring, div_pow, lt_div_iff₀ (by positivity)] at hη2
    have hA := (hN (N + L) (by linarith)).2
    have hB := (hN N le_rfl).2
    have hdiff : (U (N + L) - U N) ^ 2 < 1 / 4 := by
      rw [abs_lt] at hA hB; nlinarith
    have hLr : r / (6 * D) * L ^ 2 ≥ 1 / 4 := by
      have hLL : L ≤ L ^ 2 := by nlinarith
      have h2D : 2 * D / r * r = 2 * D := by field_simp
      have : r / (6 * D) * L ≥ 1 / 4 := by
        rw [hL, ge_iff_le, div_mul_eq_mul_div, le_div_iff₀ (by positivity)]
        nlinarith
      have : r / (6 * D) * L ≤ r / (6 * D) * L ^ 2 :=
        mul_le_mul_of_nonneg_left hLL (by positivity)
      linarith
    linarith
  · -- 0 < c < 2 sqrt (r D): oscillation argument
    have hc2 : c ^ 2 < 4 * (r * D) := by
      have h := (Real.lt_sqrt (by linarith : 0 ≤ c / 2)).mp (by linarith : c / 2 < Real.sqrt (r * D))
      nlinarith
    set θ : ℝ := (4 * (r * D) - c ^ 2) / (8 * (r * D)) with hθ
    have hrD : 0 < r * D := mul_pos hr hD
    have hθ0 : 0 < θ := by rw [hθ]; apply div_pos <;> linarith
    have hθ1 : 8 * (r * D) * θ = 4 * (r * D) - c ^ 2 := by rw [hθ]; field_simp
    set α : ℝ := c / (2 * D) with hα
    set κ : ℝ := r / D * (1 - θ) - α ^ 2 with hκ
    have hκ0 : 0 < κ := by
      have : κ = (4 * (r * D) * (1 - θ) - c ^ 2) / (4 * D ^ 2) := by
        rw [hκ, hα]; field_simp; ring
      rw [this]; apply div_pos _ (by positivity); nlinarith
    -- the point M after which U stays below θ
    obtain ⟨A, hA⟩ := eventually_atBot.mp (hbot.eventually (lt_mem_nhds (by nlinarith : θ < 1)))
    obtain ⟨B, hB⟩ := eventually_atTop.mp (htop.eventually (gt_mem_nhds hθ0))
    set S := Set.Icc A B ∩ {x | θ ≤ U x} with hS
    have hAS : A ∈ S := by
      refine ⟨⟨le_rfl, ?_⟩, (hA A le_rfl).le⟩
      by_contra h; rw [not_le] at h
      have := hB A h.le; have := hA A le_rfl; linarith
    have hScpt : IsCompact S := isCompact_Icc.inter_right (isClosed_le continuous_const hUc)
    obtain ⟨M, hMS, hMgr⟩ := hScpt.exists_isGreatest ⟨A, hAS⟩
    have hUM : θ ≤ U M := hMS.2
    have hlt : ∀ x, M < x → U x < θ := by
      intro x hx
      by_contra h; rw [not_lt] at h
      by_cases hxB : x ≤ B
      · have : x ∈ S := ⟨⟨hMS.1.1.trans hx.le, hxB⟩, h⟩
        have := hMgr this; linarith
      · have := hB x (not_le.mp hxB).le; linarith
    -- v = exp (α x) U x
    set v : ℝ → ℝ := fun x => Real.exp (α * x) * U x with hv
    set v' : ℝ → ℝ := fun x => Real.exp (α * x) * (α * U x + deriv U x) with hv'
    have hexp : ∀ x, HasDerivAt (fun x => Real.exp (α * x)) (Real.exp (α * x) * α) x := by
      intro x
      have := ((hasDerivAt_id x).const_mul α).exp
      simpa [mul_comm] using this
    have hvd : ∀ x, HasDerivAt v (v' x) x := by
      intro x
      have := (hexp x).mul (hUd x).hasDerivAt
      convert this using 1
      simp only [hv']; ring
    have hv'd : ∀ x, HasDerivAt v'
        (Real.exp (α * x) * U x * (α ^ 2 - r / D * (1 - U x))) x := by
      intro x
      have := (hexp x).mul ((((hUd x).hasDerivAt).const_mul α).add (hU'd x).hasDerivAt)
      convert this using 1
      have hode' : deriv (deriv U) x = -(c * deriv U x + r * U x * (1 - U x)) / D := by
        field_simp; linarith [hode x]
      simp only [Pi.add_apply]
      rw [hode', hα]
      field_simp
      ring
    have hvD : Differentiable ℝ v := fun x => (hvd x).differentiableAt
    have hv'D : Differentiable ℝ v' := fun x => (hv'd x).differentiableAt
    have hderv : ∀ x, deriv v x = v' x := fun x => (hvd x).deriv
    have hv0 : ∀ x, 0 ≤ v x := fun x => mul_nonneg (Real.exp_pos _).le (hnn x)
    have hv'' : ∀ x, M < x → deriv v' x ≤ -κ * v x := by
      intro x hx
      rw [(hv'd x).deriv]
      have hux := hlt x hx
      have hU0 := hnn x
      have he := Real.exp_pos (α * x)
      simp only [hv, hκ]
      have : α ^ 2 - r / D * (1 - U x) ≤ -(r / D * (1 - θ) - α ^ 2) := by
        have : r / D * (1 - θ) ≤ r / D * (1 - U x) :=
          mul_le_mul_of_nonneg_left (by linarith) (by positivity)
        linarith
      have h3 : 0 ≤ Real.exp (α * x) * U x := mul_nonneg he.le hU0
      nlinarith
    -- Step 1: v' ≥ 0 after M
    have hstep1 : ∀ x, M < x → 0 ≤ v' x := by
      intro x1 hx1
      by_contra hneg; rw [not_le] at hneg
      have hanti : ∀ y, x1 < y → deriv v y ≤ v' x1 := by
        intro y hy
        rw [hderv]
        have := rd_sub_le_of_deriv_le hv'D (a := x1) (C := 0)
          (fun z hz => (hv'' z (by linarith)).trans
            (by nlinarith [hv0 z, hκ0])) le_rfl hy.le
        linarith
      set y := x1 + (v x1 + 1) / (-v' x1) with hy
      have hpos : 0 < (v x1 + 1) / (-v' x1) := div_pos (by linarith [hv0 x1]) (by linarith)
      have := rd_sub_le_of_deriv_le hvD hanti le_rfl (by linarith : x1 ≤ y)
      have hne : v' x1 ≠ 0 := hneg.ne
      have hkey : v' x1 * (y - x1) = -(v x1 + 1) := by
        rw [hy]; field_simp; ring
      have := hv0 y
      linarith
    -- Step 2: v ≥ v M after M
    have hvM : 0 < v M := mul_pos (Real.exp_pos _) (by linarith)
    have hstep2 : ∀ x, M ≤ x → v M ≤ v x := by
      intro x hx
      have := rd_le_sub_of_le_deriv hvD (a := M) (C := 0)
        (fun z hz => by rw [hderv]; exact hstep1 z hz) le_rfl hx
      linarith
    -- Step 3: v' eventually negative
    set x1 := M + 1
    have hb : ∀ z, x1 < z → deriv v' z ≤ -κ * v M := by
      intro z hz
      have := hv'' z (by linarith)
      have := hstep2 z (by linarith)
      nlinarith
    set y := x1 + (v' x1 + 1) / (κ * v M) with hy
    have hp : 0 ≤ (v' x1 + 1) / (κ * v M) :=
      div_nonneg (by linarith [hstep1 x1 (by linarith)]) (by positivity)
    have := rd_sub_le_of_deriv_le hv'D hb le_rfl (by linarith : x1 ≤ y)
    have hne : κ * v M ≠ 0 := by positivity
    have hkey : -κ * v M * (y - x1) = -(v' x1 + 1) := by
      rw [hy]; field_simp; ring
    have := hstep1 y (by linarith)
    linarith

#print axioms rd_hasEigenvalue_fin_two_iff
#print axioms rd_exists_pos_root_iff
#print axioms rd_sub_le_of_deriv_le
#print axioms rd_le_sub_of_le_deriv
#print axioms rd_fisher_speed_ge_of_front

section rd_front_existence

open Set
lemma rd_fence {a b η : ℝ} (hη : 0 ≤ η) {f f' : ℝ → ℝ}
    (hf : ∀ t ∈ Icc a b, HasDerivWithinAt f (f' t) (Icc a b) t) (ha : f a ≤ 0)
    (h : ∀ t ∈ Ico a b, 0 < f t → f' t ≤ η) : ∀ t ∈ Icc a b, f t ≤ η * (t - a) := by
  intro t ht
  have hc : ContinuousOn f (Icc a b) := fun x hx => (hf x hx).continuousWithinAt
  have hd : ∀ x ∈ Ico a b, HasDerivWithinAt f (f' x) (Ici x) x := fun x hx =>
    (hf x (Ico_subset_Icc_self hx)).mono_of_mem_nhdsWithin
      (mem_of_superset (Icc_mem_nhdsGE hx.2) (Icc_subset_Icc_left hx.1))
  apply le_of_forall_pos_le_add
  intro ε hε
  set θ := ε / (b - a + 1) with hθ
  have hba : a ≤ b := ht.1.trans ht.2
  have hθ0 : 0 < θ := div_pos hε (by linarith)
  have key := image_le_of_deriv_right_lt_deriv_boundary hc hd
    (B := fun x => (η + θ) * (x - a) + θ) (B' := fun _ => η + θ)
    (by simp only [sub_self, mul_zero, zero_add]; linarith)
    (fun x => by
      have := (((hasDerivAt_id x).sub_const a).const_mul (η + θ)).add_const θ
      simpa using this)
    (fun x hx hfx => by
      have h1 : 0 < f x := by
        rw [hfx]; have := hx.1; nlinarith
      have := h x hx h1
      linarith) ht
  have : θ * (t - a + 1) ≤ ε := by
    rw [hθ, div_mul_eq_mul_div, div_le_iff₀ (by linarith)]
    have := ht.2; nlinarith
  nlinarith

lemma rd_abs_sqrt_sub_le (x y : ℝ) : |Real.sqrt x - Real.sqrt y| ≤ Real.sqrt |x - y| := by
  have key : ∀ p q : ℝ, Real.sqrt p ≤ Real.sqrt q + Real.sqrt |p - q| := by
    intro p q
    rcases le_total q 0 with hq | hq
    · rw [Real.sqrt_eq_zero'.2 hq, zero_add]
      exact Real.sqrt_le_sqrt ((le_abs_self _).trans' (by linarith))
    · rw [Real.sqrt_le_iff]
      refine ⟨by positivity, ?_⟩
      have h1 := Real.sq_sqrt hq
      have h2 := Real.sq_sqrt (abs_nonneg (p - q))
      have h3 : 0 ≤ Real.sqrt q * Real.sqrt |p - q| := by positivity
      nlinarith [le_abs_self (p - q)]
  rw [abs_le]
  constructor
  · have := key y x; rw [abs_sub_comm] at this; linarith
  · linarith [key x y]

lemma rd_approx_solution (γ δ : ℝ) (hγ : 0 ≤ γ) (hδ : 0 < δ) (hδ1 : δ ≤ 1) :
    ∃ E : ℝ → ℝ, E (-1) = 0 ∧ ∀ t ∈ Icc (-1 : ℝ) 1, HasDerivWithinAt E
      (max t 0 * (1 - t) - γ * (Real.sqrt (2 * max (min (E t) 1) 0 + δ ^ 2) - δ))
      (Icc (-1) 1) t := by
  set f : ℝ → ℝ → ℝ := fun t x =>
    max t 0 * (1 - t) - γ * (Real.sqrt (2 * max (min x 1) 0 + δ ^ 2) - δ) with hfdef
  have hlip : ∀ t, LipschitzWith (Real.toNNReal (γ / δ)) (f t) := by
    intro t
    apply LipschitzWith.of_dist_le_mul
    intro x y
    rw [Real.dist_eq, Real.dist_eq, Real.coe_toNNReal _ (by positivity)]
    set A := 2 * max (min x 1) 0 + δ ^ 2
    set B := 2 * max (min y 1) 0 + δ ^ 2
    have hcl : |max (min x 1) 0 - max (min y 1) 0| ≤ |x - y| :=
      (abs_max_sub_max_le_abs _ _ _).trans ((abs_min_sub_min_le_max _ _ _ _).trans (by simp))
    have hA : δ ≤ Real.sqrt A := Real.le_sqrt_of_sq_le (by simp only [A]; nlinarith [le_max_right (min x 1) 0])
    have hB : δ ≤ Real.sqrt B := Real.le_sqrt_of_sq_le (by simp only [B]; nlinarith [le_max_right (min y 1) 0])
    have hA2 := Real.sq_sqrt (show 0 ≤ A by positivity)
    have hB2 := Real.sq_sqrt (show 0 ≤ B by positivity)
    have hAB : |Real.sqrt A - Real.sqrt B| * (2 * δ) ≤ 2 * |x - y| := by
      have e : |A - B| = |Real.sqrt A - Real.sqrt B| * (Real.sqrt A + Real.sqrt B) := by
        rw [← abs_of_pos (show 0 < Real.sqrt A + Real.sqrt B by linarith), ← abs_mul]
        congr 1; nlinarith
      have e2 : |A - B| = 2 * |max (min x 1) 0 - max (min y 1) 0| := by
        simp only [A, B]; rw [← abs_two, ← abs_mul, abs_two]; congr 1; ring
      calc |Real.sqrt A - Real.sqrt B| * (2 * δ)
          ≤ |Real.sqrt A - Real.sqrt B| * (Real.sqrt A + Real.sqrt B) :=
            mul_le_mul_of_nonneg_left (by linarith) (abs_nonneg _)
        _ = |A - B| := e.symm
        _ ≤ 2 * |x - y| := by rw [e2]; linarith
    have : f t x - f t y = -γ * (Real.sqrt A - Real.sqrt B) := by simp only [hfdef]; ring
    rw [this, abs_mul, abs_neg, abs_of_nonneg hγ, div_mul_eq_mul_div, le_div_iff₀ hδ]
    nlinarith [abs_nonneg (Real.sqrt A - Real.sqrt B)]
  have hbd : ∀ t ∈ Icc (-1 : ℝ) 1, ∀ x, ‖f t x‖ ≤ 2 + 2 * γ := by
    intro t ht x
    have h1 : 0 ≤ max t 0 * (1 - t) := mul_nonneg (le_max_right _ _) (by linarith [ht.2])
    have h2 : max t 0 * (1 - t) ≤ 2 := by
      have : max t 0 ≤ 1 := max_le ht.2 zero_le_one
      nlinarith [ht.1, le_max_right t 0]
    have hm0 : 0 ≤ max (min x 1) 0 := le_max_right _ _
    have hm1 : max (min x 1) 0 ≤ 1 := max_le (min_le_right _ _) zero_le_one
    have h3 : δ ≤ Real.sqrt (2 * max (min x 1) 0 + δ ^ 2) := Real.le_sqrt_of_sq_le (by nlinarith)
    have h4 : Real.sqrt (2 * max (min x 1) 0 + δ ^ 2) ≤ 2 := by
      rw [Real.sqrt_le_left (by norm_num)]; nlinarith
    rw [Real.norm_eq_abs, abs_le]
    simp only [hfdef]
    constructor <;> nlinarith
  have hPL : IsPicardLindelof f (tmin := -1) (tmax := 1) ⟨-1, by norm_num⟩ 0
      (2 * Real.toNNReal (2 + 2 * γ)) 0 (Real.toNNReal (2 + 2 * γ))
      (Real.toNNReal (γ / δ)) :=
    { lipschitzOnWith := fun t _ => (hlip t).lipschitzOnWith
      continuousOn := fun x _ => by simp only [hfdef]; fun_prop
      norm_le := fun t ht x _ => by rw [Real.coe_toNNReal _ (by positivity)]; exact hbd t ht x
      mul_max_le := by
        push_cast
        rw [Real.coe_toNNReal _ (by positivity)]; norm_num; linarith }
  obtain ⟨E, hE0, hE⟩ := hPL.exists_eq_forall_mem_Icc_hasDerivWithinAt₀
  exact ⟨E, hE0, hE⟩

lemma rd_sqrt_clamp_approx (x δ : ℝ) (hδ : 0 < δ) :
    0 ≤ Real.sqrt (2 * min x 1) - (Real.sqrt (2 * max (min x 1) 0 + δ ^ 2) - δ) ∧
    Real.sqrt (2 * min x 1) - (Real.sqrt (2 * max (min x 1) 0 + δ ^ 2) - δ) ≤ δ := by
  have e : Real.sqrt (2 * min x 1) = Real.sqrt (2 * max (min x 1) 0) := by
    rcases le_total (min x 1) 0 with h | h
    · rw [max_eq_right h, mul_zero, Real.sqrt_zero, Real.sqrt_eq_zero'.2 (by linarith)]
    · rw [max_eq_left h]
  rw [e]
  set y := max (min x 1) 0
  have hy : 0 ≤ y := le_max_right _ _
  have h1 : Real.sqrt (2 * y) ≤ Real.sqrt (2 * y + δ ^ 2) :=
    Real.sqrt_le_sqrt (by nlinarith)
  have h2 : Real.sqrt (2 * y + δ ^ 2) ≤ Real.sqrt (2 * y) + δ := by
    rw [Real.sqrt_le_iff]
    refine ⟨by positivity, ?_⟩
    have := Real.sq_sqrt (show 0 ≤ 2 * y by positivity)
    have : 0 ≤ Real.sqrt (2 * y) := Real.sqrt_nonneg _
    nlinarith
  constructor <;> linarith

lemma rd_limit_solution (γ : ℝ) (hγ : 0 ≤ γ) :
    ∃ E : ℝ → ℝ, ContinuousOn E (Icc (-1) 1) ∧
      (∀ t ∈ Ioo (-1 : ℝ) 1,
        HasDerivAt E (max t 0 * (1 - t) - γ * Real.sqrt (2 * min (E t) 1)) t) ∧
      (∀ t ∈ Icc (-1 : ℝ) 1, 0 ≤ E t) ∧ (∀ t ∈ Icc (-1 : ℝ) 0, E t = 0) := by
  set δ : ℕ → ℝ := fun n => 1 / ((n : ℝ) + 1) with hδdef
  have hδ0 : ∀ n, 0 < δ n := fun n => by simp only [hδdef]; positivity
  have hδ1 : ∀ n, δ n ≤ 1 := fun n => by
    simp only [hδdef]; rw [div_le_one (by positivity)]; linarith [n.cast_nonneg (α := ℝ)]
  have hδmono : ∀ n m, n ≤ m → δ m ≤ δ n := fun n m h => by
    simp only [hδdef]
    exact one_div_le_one_div_of_le (by positivity) (by exact_mod_cast Nat.add_le_add_right h 1)
  have hδlim : Tendsto δ atTop (𝓝 0) := tendsto_one_div_add_atTop_nhds_zero_nat
  choose E hE0 hE using fun n => rd_approx_solution γ (δ n) hγ (hδ0 n) (hδ1 n)
  set s : ℕ → ℝ → ℝ := fun n x => Real.sqrt (2 * max (min x 1) 0 + δ n ^ 2) - δ n with hsdef
  set G : ℝ → ℝ := fun x => Real.sqrt (2 * min x 1) with hGdef
  have hE' : ∀ n, ∀ t ∈ Icc (-1 : ℝ) 1,
      HasDerivWithinAt (E n) (max t 0 * (1 - t) - γ * s n (E n t)) (Icc (-1) 1) t := hE
  clear_value s
  clear hE
  have hGs : ∀ n x, 0 ≤ G x - s n x ∧ G x - s n x ≤ δ n := fun n x => by
    rw [hsdef]; exact rd_sqrt_clamp_approx x (δ n) (hδ0 n)
  have hGmono : Monotone G := fun x y h => Real.sqrt_le_sqrt (by
    have := min_le_min_right 1 h; linarith)
  have hGlip : ∀ x y, |G x - G y| ≤ Real.sqrt (2 * |x - y|) := by
    intro x y
    refine (rd_abs_sqrt_sub_le _ _).trans (Real.sqrt_le_sqrt ?_)
    have := (abs_min_sub_min_le_max x 1 y 1).trans (by simp : max |x - y| |(1 : ℝ) - 1| ≤ |x - y|)
    rw [← mul_sub, abs_mul, abs_two]; linarith
  have hs0 : ∀ n x, x ≤ 0 → s n x = 0 := by
    intro n x hx
    simp only [hsdef]
    rw [max_eq_right (min_le_of_left_le hx), mul_zero, zero_add,
      Real.sqrt_sq (hδ0 n).le, sub_self]
  have hsnn : ∀ n x, 0 ≤ s n x := by
    intro n x
    simp only [hsdef]
    have : δ n ≤ Real.sqrt (2 * max (min x 1) 0 + δ n ^ 2) :=
      Real.le_sqrt_of_sq_le (by nlinarith [le_max_right (min x 1) 0])
    linarith
  -- Cauchy estimate
  have hC : ∀ n m, ∀ t ∈ Icc (-1 : ℝ) 1, E n t - E m t ≤ 2 * γ * δ n := by
    intro n m t ht
    have := rd_fence (η := γ * δ n) (by have := hδ0 n; positivity)
      (f := fun t => E n t - E m t)
      (fun t ht => (hE' n t ht).sub (hE' m t ht)) (by simp [hE0])
      (fun t _ hpos => by
        have h1 := hGs n (E n t)
        have h2 := hGs m (E m t)
        have hpos' : 0 < E n t - E m t := hpos
        have h3 := hGmono (show E m t ≤ E n t by linarith)
        nlinarith) t ht
    have : γ * δ n * (t - -1) ≤ 2 * γ * δ n := by
      have := mul_nonneg (mul_nonneg hγ (hδ0 n).le) (show 0 ≤ 1 - t by linarith [ht.2])
      nlinarith
    linarith
  have hC' : ∀ n m, ∀ t ∈ Icc (-1 : ℝ) 1, |E n t - E m t| ≤ 2 * γ * (δ n + δ m) := by
    intro n m t ht
    rw [abs_le]
    have := hC n m t ht; have := hC m n t ht; have := hδ0 n; have := hδ0 m
    constructor <;> nlinarith
  set El : ℝ → ℝ := fun t => limUnder atTop (fun n => E n t) with hEl
  have hlim : ∀ t ∈ Icc (-1 : ℝ) 1, Tendsto (fun n => E n t) atTop (𝓝 (El t)) := by
    intro t ht
    apply CauchySeq.tendsto_limUnder
    apply cauchySeq_of_le_tendsto_0 (fun N => 4 * γ * δ N)
    · intro n m N hn hm
      rw [Real.dist_eq]
      have := hC' n m t ht
      have := hδmono N n hn; have := hδmono N m hm
      nlinarith
    · simpa using hδlim.const_mul (4 * γ)
  have hbd : ∀ n, ∀ t ∈ Icc (-1 : ℝ) 1, |E n t - El t| ≤ 2 * γ * δ n := by
    intro n t ht
    have h1 : Tendsto (fun m => |E n t - E m t|) atTop (𝓝 (|E n t - El t|)) :=
      ((hlim t ht).const_sub (E n t)).abs
    have h2 : Tendsto (fun m => 2 * γ * (δ n + δ m)) atTop (𝓝 (2 * γ * (δ n + 0))) :=
      (hδlim.const_add (δ n)).const_mul (2 * γ)
    rw [add_zero] at h2
    exact le_of_tendsto_of_tendsto' h1 h2 (fun m => hC' n m t ht)
  have hunif : TendstoUniformlyOn E El atTop (Icc (-1) 1) := by
    rw [Metric.tendstoUniformlyOn_iff]
    intro ε hε
    have : ∀ᶠ n in atTop, 2 * γ * δ n < ε := by
      have := hδlim.const_mul (2 * γ)
      rw [mul_zero] at this
      exact this.eventually (gt_mem_nhds hε)
    filter_upwards [this] with n hn t ht
    rw [Real.dist_eq, abs_sub_comm]
    exact (hbd n t ht).trans_lt hn
  have hcont : ContinuousOn El (Icc (-1) 1) :=
    hunif.continuousOn (Eventually.of_forall fun n =>
      (fun t ht => (hE' n t ht).continuousWithinAt : ContinuousOn (E n) _)).frequently
  refine ⟨El, hcont, ?_, ?_, ?_⟩
  · intro t ht
    apply hasDerivAt_of_tendstoUniformlyOn isOpen_Ioo
      (f' := fun n t => max t 0 * (1 - t) - γ * s n (E n t)) _
      (Eventually.of_forall fun n x hx =>
        (hE' n x (Ioo_subset_Icc_self hx)).hasDerivAt (Icc_mem_nhds hx.1 hx.2))
      (fun x hx => hlim x (Ioo_subset_Icc_self hx)) ht
    rw [Metric.tendstoUniformlyOn_iff]
    intro ε hε
    have hb : Tendsto (fun n => γ * (Real.sqrt (2 * (2 * γ * δ n)) + δ n)) atTop
        (𝓝 (γ * (Real.sqrt (2 * (2 * γ * 0)) + 0))) := by
      apply Tendsto.const_mul
      apply Tendsto.add _ hδlim
      exact (Real.continuous_sqrt.tendsto _).comp ((hδlim.const_mul (2 * γ)).const_mul 2)
    simp only [mul_zero, Real.sqrt_zero, add_zero] at hb
    filter_upwards [hb.eventually (gt_mem_nhds hε)] with n hn x hx
    rw [Real.dist_eq]
    have hx' := Ioo_subset_Icc_self hx
    have h1 := hGlip (El x) (E n x)
    have h2 := hGs n (E n x)
    have h3 : Real.sqrt (2 * |El x - E n x|) ≤ Real.sqrt (2 * (2 * γ * δ n)) :=
      Real.sqrt_le_sqrt (by rw [abs_sub_comm]; linarith [hbd n x hx'])
    have : |max x 0 * (1 - x) - γ * G (El x) - (max x 0 * (1 - x) - γ * s n (E n x))|
        ≤ γ * (Real.sqrt (2 * (2 * γ * δ n)) + δ n) := by
      rw [show max x 0 * (1 - x) - γ * G (El x) - (max x 0 * (1 - x) - γ * s n (E n x))
        = -γ * ((G (El x) - G (E n x)) + (G (E n x) - s n (E n x))) by ring,
        abs_mul, abs_neg, abs_of_nonneg hγ]
      apply mul_le_mul_of_nonneg_left _ hγ
      refine (abs_add_le _ _).trans ?_
      rw [abs_of_nonneg h2.1]
      linarith
    exact this.trans_lt hn
  · intro t ht
    apply ge_of_tendsto' (hlim t ht)
    intro n
    have := rd_fence (η := 0) le_rfl (f := fun t => -E n t)
      (fun t ht => (hE' n t ht).neg) (by simp [hE0])
      (fun t ht hpos => by
        have hpos : 0 < -E n t := hpos
        rw [hs0 n _ (by linarith)]
        have : 0 ≤ max t 0 * (1 - t) := mul_nonneg (le_max_right _ _) (by linarith [ht.2])
        linarith) t ht
    simp only [zero_mul] at this
    linarith
  · intro t ht
    have ht' : t ∈ Icc (-1 : ℝ) 1 := ⟨ht.1, ht.2.trans zero_le_one⟩
    apply le_antisymm
    · apply le_of_tendsto' (hlim t ht')
      intro n
      have := rd_fence (η := 0) le_rfl (f := E n) (a := -1) (b := 0)
        (fun t ht => (hE' n t ⟨ht.1, ht.2.trans zero_le_one⟩).mono
          (Icc_subset_Icc_right zero_le_one)) (by simp [hE0])
        (fun t ht _ => by
          rw [max_eq_right ht.2.le, zero_mul, zero_sub]
          have := hsnn n (E n t)
          nlinarith) t ht
      simpa using this
    · apply ge_of_tendsto' (hlim t ht')
      intro n
      have := rd_fence (η := 0) le_rfl (f := fun t => -E n t)
        (fun t ht => (hE' n t ht).neg) (by simp [hE0])
        (fun t ht hpos => by
          have hpos : 0 < -E n t := hpos
          rw [hs0 n _ (by linarith)]
          have : 0 ≤ max t 0 * (1 - t) := mul_nonneg (le_max_right _ _) (by linarith [ht.2])
          linarith) t ht'
      simp only [zero_mul] at this
      linarith

lemma rd_profile (γ : ℝ) (hγ : 2 ≤ γ) : ∃ P : ℝ → ℝ, ∀ u ∈ Ioo (0 : ℝ) 1,
    0 < P u ∧ P u ≤ γ / 2 * u ∧ P u ≤ 1 - u ∧ HasDerivAt P (γ - u * (1 - u) / P u) u := by
  obtain ⟨E, hEc, hEd, hE0, hEz⟩ := rd_limit_solution γ (by linarith)
  have hsub : Icc (-1 / 2 : ℝ) 1 ⊆ Icc (-1) 1 := Icc_subset_Icc_left (by norm_num)
  have hd : ∀ x ∈ Ico (-1 / 2 : ℝ) 1, HasDerivWithinAt E
      (max x 0 * (1 - x) - γ * Real.sqrt (2 * min (E x) 1)) (Ici x) x := fun x hx =>
    (hEd x ⟨by linarith [hx.1], hx.2⟩).hasDerivWithinAt
  have hc : ContinuousOn E (Icc (-1 / 2 : ℝ) 1) := hEc.mono hsub
  have hEm : E (-1 / 2) = 0 := hEz _ ⟨by norm_num, by norm_num⟩
  -- E x ≤ x² / 2
  have h5 : ∀ x ∈ Icc (0 : ℝ) 1, E x ≤ x ^ 2 / 2 := by
    intro x hx
    apply le_of_forall_pos_le_add
    intro θ hθ
    refine image_le_of_deriv_right_lt_deriv_boundary hc hd
      (B := fun x => x ^ 2 / 2 + θ) (B' := fun x => x) (by rw [hEm]; positivity)
      (fun x => by simpa using ((hasDerivAt_pow 2 x).div_const 2).add_const θ) ?_
      ⟨by linarith [hx.1], hx.2⟩
    intro y hy hEy
    rcases le_or_gt y 0 with h | h
    · rw [hEz y ⟨by linarith [hy.1], h⟩] at hEy; nlinarith
    · rw [max_eq_left h.le]
      have := Real.sqrt_nonneg (2 * min (E y) 1)
      have : 0 ≤ γ * Real.sqrt (2 * min (E y) 1) := by positivity
      nlinarith [hy.2]
  -- E x ≤ γ² (1 - x)² / 8
  have h6 : ∀ x ∈ Icc (0 : ℝ) 1, E x ≤ γ ^ 2 * (1 - x) ^ 2 / 8 := by
    intro x hx
    apply le_of_forall_pos_le_add
    intro θ hθ
    refine image_le_of_deriv_right_lt_deriv_boundary hc hd
      (B := fun x => γ ^ 2 * (1 - x) ^ 2 / 8 + θ) (B' := fun x => -(γ ^ 2 * (1 - x) / 4))
      (by rw [hEm]; positivity)
      (fun x => by
        have h1 : HasDerivAt (fun x : ℝ => 1 - x) (-1) x := by
          simpa using (hasDerivAt_id x).const_sub 1
        have := ((h1.pow 2).const_mul (γ ^ 2)).div_const 8 |>.add_const θ
        convert this using 1; norm_num; ring) ?_
      ⟨by linarith [hx.1], hx.2⟩
    intro y hy hEy
    rcases le_or_gt y 0 with h | h
    · rw [hEz y ⟨by linarith [hy.1], h⟩] at hEy; nlinarith
    · rw [max_eq_left h.le]
      have hy1 : E y ≤ 1 := by have := h5 y ⟨h.le, hy.2.le⟩; nlinarith [hy.2]
      rw [min_eq_left hy1]
      have hs : γ * (1 - y) / 2 ≤ Real.sqrt (2 * E y) :=
        Real.le_sqrt_of_sq_le (by rw [hEy]; nlinarith)
      have h1y : 0 < 1 - y := by linarith [hy.2]
      have : γ * (γ * (1 - y) / 2) ≤ γ * Real.sqrt (2 * E y) :=
        mul_le_mul_of_nonneg_left hs (by linarith)
      have hy4 : y < γ ^ 2 / 4 := by nlinarith [hy.2]
      have : y * (1 - y) < γ ^ 2 * (1 - y) / 4 := by nlinarith [mul_pos (sub_pos.2 hy4) h1y]
      nlinarith
  -- E x > 0 inside
  have h7 : ∀ x ∈ Ioo (0 : ℝ) 1, 0 < E x := by
    intro x hx
    by_contra hneg
    have hx0 : E x = 0 := le_antisymm (not_lt.mp hneg) (hE0 x (Ioo_subset_Icc_self
      ⟨by linarith [hx.1], hx.2⟩))
    have hmin : IsLocalMin E x := by
      filter_upwards [Icc_mem_nhds (show (-1 : ℝ) < x by linarith [hx.1]) hx.2] with y hy
      rw [hx0]; exact hE0 y hy
    have := hmin.hasDerivAt_eq_zero (hEd x ⟨by linarith [hx.1], hx.2⟩)
    rw [hx0, min_eq_left zero_le_one, mul_zero, Real.sqrt_zero, mul_zero, sub_zero,
      max_eq_left hx.1.le] at this
    nlinarith [hx.1, hx.2]
  refine ⟨fun u => Real.sqrt (2 * E (1 - u)), fun u hu => ?_⟩
  have hw : 1 - u ∈ Ioo (0 : ℝ) 1 := ⟨by linarith [hu.2], by linarith [hu.1]⟩
  have hwI : 1 - u ∈ Icc (0 : ℝ) 1 := Ioo_subset_Icc_self hw
  have hpos := h7 _ hw
  have hP0 : 0 < Real.sqrt (2 * E (1 - u)) := Real.sqrt_pos.2 (by linarith)
  refine ⟨hP0, ?_, ?_, ?_⟩
  · rw [Real.sqrt_le_iff]
    refine ⟨by nlinarith [hu.1], ?_⟩
    have := h6 _ hwI
    nlinarith
  · rw [Real.sqrt_le_iff]
    refine ⟨by linarith [hu.2], ?_⟩
    have := h5 _ hwI
    nlinarith
  · have hEw := hEd (1 - u) ⟨by linarith [hw.1], hw.2⟩
    have h1 := (hEw.comp u ((hasDerivAt_const u (1 : ℝ)).sub (hasDerivAt_id u))).const_mul 2
    have h2 := h1.sqrt (by simp only [Function.comp]; positivity)
    have hsq : (1 - u) ^ 2 ≤ 1 := by nlinarith [hw.1, hw.2]
    have hE1 : E (1 - u) ≤ 1 := by linarith [h5 _ hwI]
    have e : (E ∘ HSub.hSub 1) u = E (1 - u) := rfl
    rw [e, max_eq_left hw.1.le, min_eq_left hE1] at h2
    refine h2.congr_deriv ?_
    field_simp
    ring

lemma rd_front_normalized (γ : ℝ) (hγ : 2 ≤ γ) : ∃ U : ℝ → ℝ, ContDiff ℝ 2 U ∧
    (∀ ξ, deriv (deriv U) ξ + γ * deriv U ξ + U ξ * (1 - U ξ) = 0) ∧
    Tendsto U atBot (𝓝 1) ∧ Tendsto U atTop (𝓝 0) ∧ ∀ ξ, 0 ≤ U ξ := by
  obtain ⟨P, hP⟩ := rd_profile γ hγ
  have hγ0 : 0 < γ := by linarith
  have hPc : ContinuousOn P (Ioo 0 1) := fun u hu =>
    (hP u hu).2.2.2.continuousAt.continuousWithinAt
  have hinvc : ContinuousOn (fun s => -(P s)⁻¹) (Ioo 0 1) :=
    (hPc.inv₀ (fun u hu => (hP u hu).1.ne')).neg
  have hhalf : (1 / 2 : ℝ) ∈ Ioo (0 : ℝ) 1 := ⟨by norm_num, by norm_num⟩
  set Ξ : ℝ → ℝ := fun u => ∫ s in (1 / 2 : ℝ)..u, -(P s)⁻¹ with hΞdef
  have hΞd : ∀ u ∈ Ioo (0 : ℝ) 1, HasDerivAt Ξ (-(P u)⁻¹) u := by
    intro u hu
    exact intervalIntegral.integral_hasDerivAt_right
      ((hinvc.mono (ordConnected_Ioo.uIcc_subset hhalf hu)).intervalIntegrable)
      (hinvc.stronglyMeasurableAtFilter isOpen_Ioo u hu)
      (hinvc.continuousAt (Ioo_mem_nhds hu.1 hu.2))
  have hΞc : ContinuousOn Ξ (Ioo 0 1) := fun u hu =>
    (hΞd u hu).continuousAt.continuousWithinAt
  have hΞanti : StrictAntiOn Ξ (Ioo 0 1) := by
    apply strictAntiOn_of_deriv_neg (convex_Ioo 0 1) hΞc
    intro x hx
    rw [interior_Ioo] at hx
    rw [(hΞd x hx).deriv]
    exact neg_neg_of_pos (inv_pos.2 (hP x hx).1)
  -- growth bounds
  have hlow : ∀ u ∈ Ioo (0 : ℝ) 1, u ≤ 1 / 2 →
      Ξ (1 / 2) + 2 / γ * Real.log (1 / 2) - 2 / γ * Real.log u ≤ Ξ u := by
    have hg : ∀ u ∈ Ioo (0 : ℝ) 1, HasDerivAt (fun u => Ξ u + 2 / γ * Real.log u)
        (-(P u)⁻¹ + 2 / γ * u⁻¹) u := fun u hu =>
      (hΞd u hu).add ((Real.hasDerivAt_log hu.1.ne').const_mul _)
    have hanti : AntitoneOn (fun u => Ξ u + 2 / γ * Real.log u) (Ioo 0 1) := by
      apply antitoneOn_of_deriv_nonpos (convex_Ioo 0 1)
        (fun u hu => (hg u hu).continuousAt.continuousWithinAt)
      · intro u hu; rw [interior_Ioo] at hu; exact (hg u hu).differentiableAt.differentiableWithinAt
      · intro u hu
        rw [interior_Ioo] at hu
        rw [(hg u hu).deriv]
        obtain ⟨h1, h2, -, -⟩ := hP u hu
        have : 2 / γ * u⁻¹ ≤ (P u)⁻¹ := by
          rw [show 2 / γ * u⁻¹ = (γ / 2 * u)⁻¹ by field_simp]
          exact inv_anti₀ h1 h2
        linarith
    intro u hu hu2
    have := hanti hu hhalf hu2
    simp only at this
    linarith
  have hup : ∀ u ∈ Ioo (0 : ℝ) 1, 1 / 2 ≤ u →
      Ξ u ≤ Ξ (1 / 2) - Real.log (1 / 2) + Real.log (1 - u) := by
    have hg : ∀ u ∈ Ioo (0 : ℝ) 1, HasDerivAt (fun u => Ξ u - Real.log (1 - u))
        (-(P u)⁻¹ + (1 - u)⁻¹) u := by
      intro u hu
      have h1 : HasDerivAt (fun u : ℝ => 1 - u) (-1) u := by
        simpa using (hasDerivAt_id u).const_sub 1
      have := (hΞd u hu).sub ((Real.hasDerivAt_log (by linarith [hu.2] : (1 - u) ≠ 0)).comp u h1)
      exact this.congr_deriv (by ring)
    have hanti : AntitoneOn (fun u => Ξ u - Real.log (1 - u)) (Ioo 0 1) := by
      apply antitoneOn_of_deriv_nonpos (convex_Ioo 0 1)
        (fun u hu => (hg u hu).continuousAt.continuousWithinAt)
      · intro u hu; rw [interior_Ioo] at hu; exact (hg u hu).differentiableAt.differentiableWithinAt
      · intro u hu
        rw [interior_Ioo] at hu
        rw [(hg u hu).deriv]
        obtain ⟨h1, -, h3, -⟩ := hP u hu
        have : (1 - u)⁻¹ ≤ (P u)⁻¹ := inv_anti₀ h1 h3
        linarith
    intro u hu hu2
    have := hanti hhalf hu hu2
    simp only at this
    linarith
  -- surjectivity
  have hsurj : ∀ ξ : ℝ, ∃ u ∈ Ioo (0 : ℝ) 1, Ξ u = ξ := by
    intro ξ
    set K0 := Ξ (1 / 2) + 2 / γ * Real.log (1 / 2)
    set K1 := Ξ (1 / 2) - Real.log (1 / 2)
    set a := min (1 / 2) (Real.exp (-(γ / 2) * |ξ - K0|)) with ha
    set b := 1 - min (1 / 2) (Real.exp (-|ξ - K1|)) with hb
    have ha0 : 0 < a := lt_min (by norm_num) (Real.exp_pos _)
    have ha1 : a ≤ 1 / 2 := min_le_left _ _
    have hb0 : 0 < min (1 / 2 : ℝ) (Real.exp (-|ξ - K1|)) := lt_min (by norm_num) (Real.exp_pos _)
    have hb1 : min (1 / 2 : ℝ) (Real.exp (-|ξ - K1|)) ≤ 1 / 2 := min_le_left _ _
    have haI : a ∈ Ioo (0 : ℝ) 1 := ⟨ha0, by linarith⟩
    have hbI : b ∈ Ioo (0 : ℝ) 1 := ⟨by linarith, by linarith⟩
    have hla : Real.log a ≤ -(γ / 2) * |ξ - K0| := by
      rw [← Real.log_exp (-(γ / 2) * |ξ - K0|)]
      exact Real.log_le_log ha0 (min_le_right _ _)
    have hlb : Real.log (1 - b) ≤ -|ξ - K1| := by
      rw [← Real.log_exp (-|ξ - K1|), hb, sub_sub_cancel]
      exact Real.log_le_log hb0 (min_le_right _ _)
    have hΞa : ξ ≤ Ξ a := by
      have := hlow a haI ha1
      have h2 : 2 / γ * Real.log a ≤ -|ξ - K0| := by
        calc 2 / γ * Real.log a ≤ 2 / γ * (-(γ / 2) * |ξ - K0|) :=
              mul_le_mul_of_nonneg_left hla (by positivity)
          _ = -|ξ - K0| := by field_simp
      have := le_abs_self (ξ - K0)
      linarith
    have hΞb : Ξ b ≤ ξ := by
      have := hup b hbI (by linarith)
      have := neg_abs_le (ξ - K1)
      linarith
    have hab : a ≤ b := by linarith
    obtain ⟨u, hu, hΞu⟩ := intermediate_value_Icc' hab
      (hΞc.mono (ordConnected_Ioo.out haI hbI)) ⟨hΞb, hΞa⟩
    exact ⟨u, ordConnected_Ioo.out haI hbI hu, hΞu⟩
  choose U hU hΞU using hsurj
  have hUlt : ∀ u0 ∈ Ioo (0 : ℝ) 1, ∀ ξ, ξ < Ξ u0 → u0 < U ξ := by
    intro u0 hu0 ξ hξ
    by_contra h
    have := hΞanti.antitoneOn (hU ξ) hu0 (not_lt.mp h)
    rw [hΞU] at this; linarith
  have hUgt : ∀ u0 ∈ Ioo (0 : ℝ) 1, ∀ ξ, Ξ u0 < ξ → U ξ < u0 := by
    intro u0 hu0 ξ hξ
    by_contra h
    have := hΞanti.antitoneOn hu0 (hU ξ) (not_lt.mp h)
    rw [hΞU] at this; linarith
  have hUanti : Antitone U := by
    intro x y hxy
    by_contra h
    have := hΞanti (hU x) (hU y) (not_le.mp h)
    rw [hΞU, hΞU] at this; linarith
  have hUcont : Continuous U := by
    have hm : Monotone (fun ξ => -U ξ) := fun x y h => neg_le_neg (hUanti h)
    have : Continuous (fun ξ => -U ξ) := by
      refine continuous_iff_continuousAt.2 fun ξ => ?_
      refine continuousAt_of_monotoneOn_of_image_mem_nhds (fun x _ y _ h => hm h) univ_mem ?_
      refine mem_of_superset (Ioo_mem_nhds (show -1 < -U ξ by linarith [(hU ξ).2])
        (show -U ξ < 0 by linarith [(hU ξ).1])) ?_
      intro y hy
      refine ⟨Ξ (-y), mem_univ _, ?_⟩
      have hyI : -y ∈ Ioo (0 : ℝ) 1 := ⟨by linarith [hy.2], by linarith [hy.1]⟩
      have := hΞanti.injOn (hU (Ξ (-y))) hyI (hΞU _)
      simp only [this, neg_neg]
    simpa using this.neg
  have hUd : ∀ ξ, HasDerivAt U (-P (U ξ)) ξ := by
    intro ξ
    have := HasDerivAt.of_local_left_inverse hUcont.continuousAt (hΞd (U ξ) (hU ξ))
      (neg_ne_zero.2 (inv_ne_zero (hP _ (hU ξ)).1.ne')) (Eventually.of_forall hΞU)
    simpa [inv_neg, inv_inv] using this
  have hderiv : deriv U = fun ξ => -P (U ξ) := funext fun ξ => (hUd ξ).deriv
  have hUdd : ∀ ξ, HasDerivAt (fun ξ => -P (U ξ)) (γ * P (U ξ) - U ξ * (1 - U ξ)) ξ := by
    intro ξ
    have := ((hP (U ξ) (hU ξ)).2.2.2.comp ξ (hUd ξ)).neg
    refine this.congr_deriv ?_
    have := (hP (U ξ) (hU ξ)).1.ne'
    field_simp
  have hdd : deriv (deriv U) = fun ξ => γ * P (U ξ) - U ξ * (1 - U ξ) := by
    rw [hderiv]; exact funext fun ξ => (hUdd ξ).deriv
  refine ⟨U, ?_, ?_, ?_, ?_, fun ξ => (hU ξ).1.le⟩
  · show ContDiff ℝ (1 + 1) U
    rw [contDiff_succ_iff_deriv]
    refine ⟨fun ξ => (hUd ξ).differentiableAt, by simp, ?_⟩
    rw [contDiff_one_iff_deriv]
    refine ⟨?_, ?_⟩
    · rw [hderiv]; exact fun ξ => (hUdd ξ).differentiableAt
    · rw [hdd]
      have hc1 : Continuous (fun ξ => -P (U ξ)) :=
        continuous_iff_continuousAt.2 fun ξ => (hUdd ξ).continuousAt
      have := (hc1.const_mul (-γ)).sub
        (hUcont.mul ((continuous_const : Continuous fun _ : ℝ => (1 : ℝ)).sub hUcont))
      convert this using 2 with ξ
      simp only [Pi.sub_apply, Pi.mul_apply]
      ring
  · intro ξ
    rw [hdd, hderiv]
    ring
  · rw [tendsto_order]
    constructor
    · intro a ha
      have hu0 : max a (1 / 2) ∈ Ioo (0 : ℝ) 1 :=
        ⟨lt_max_of_lt_right (by norm_num), max_lt ha (by norm_num)⟩
      rw [eventually_atBot]
      exact ⟨Ξ (max a (1 / 2)) - 1, fun ξ hξ =>
        lt_of_le_of_lt (le_max_left _ _) (hUlt _ hu0 ξ (by linarith))⟩
    · intro a ha
      exact Eventually.of_forall fun ξ => (hU ξ).2.trans ha
  · rw [tendsto_order]
    constructor
    · intro a ha
      exact Eventually.of_forall fun ξ => ha.trans (hU ξ).1
    · intro a ha
      have hu0 : min a (1 / 2) ∈ Ioo (0 : ℝ) 1 :=
        ⟨lt_min ha (by norm_num), min_lt_of_right_lt (by norm_num)⟩
      rw [eventually_atTop]
      exact ⟨Ξ (min a (1 / 2)) + 1, fun ξ hξ =>
        lt_of_lt_of_le (hUgt _ hu0 ξ (by linarith)) (min_le_left _ _)⟩

lemma rd_fisher_front_of_speed (D r c : ℝ) (hD : 0 < D) (hr : 0 < r)
    (hc : 2 * Real.sqrt (r * D) ≤ c) : ∃ U : ℝ → ℝ, ContDiff ℝ 2 U ∧
      (∀ ξ, D * deriv (deriv U) ξ + c * deriv U ξ + r * U ξ * (1 - U ξ) = 0) ∧
      Tendsto U atBot (𝓝 1) ∧ Tendsto U atTop (𝓝 0) ∧ ∀ ξ, 0 ≤ U ξ := by
  set k := Real.sqrt (r / D) with hkdef
  have hk : 0 < k := Real.sqrt_pos.2 (div_pos hr hD)
  have hk2 : k ^ 2 = r / D := Real.sq_sqrt (by positivity)
  set s := Real.sqrt (r * D) with hsdef
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hs2 : s ^ 2 = r * D := Real.sq_sqrt (by positivity)
  have hsk : s * k = r := by
    have h1 : (s * k) ^ 2 = r ^ 2 := by
      rw [mul_pow, hs2, hk2]; field_simp
    nlinarith [mul_nonneg hs0 hk.le]
  set γ := c * k / r with hγdef
  have hγ : 2 ≤ γ := by
    rw [hγdef, le_div_iff₀ hr]
    nlinarith
  obtain ⟨V, hV, hode, hbot, htop, hnn⟩ := rd_front_normalized γ hγ
  have h2 : ContDiff ℝ (1 + 1) V := hV
  rw [contDiff_succ_iff_deriv] at h2
  have hV'd : Differentiable ℝ (deriv V) := h2.2.2.differentiable (by norm_num)
  have hd1 : deriv (fun ξ => V (k * ξ)) = fun ξ => k * deriv V (k * ξ) := by
    funext ξ
    rw [deriv_comp_mul_left, smul_eq_mul]
  have hd2 : deriv (deriv (fun ξ => V (k * ξ))) =
      fun ξ => k ^ 2 * deriv (deriv V) (k * ξ) := by
    rw [hd1]
    funext ξ
    have := ((hV'd (k * ξ)).hasDerivAt.comp ξ ((hasDerivAt_id ξ).const_mul k)).const_mul k
    refine this.deriv.trans ?_
    ring
  refine ⟨fun ξ => V (k * ξ), hV.comp (contDiff_const.mul contDiff_id), ?_, ?_, ?_,
    fun ξ => hnn _⟩
  · intro ξ
    rw [hd2, hd1]
    beta_reduce
    have hDk : D * k ^ 2 = r := by rw [hk2]; field_simp
    have hck : c * k = r * γ := by rw [hγdef]; field_simp
    linear_combination r * hode (k * ξ) + deriv (deriv V) (k * ξ) * hDk +
      deriv V (k * ξ) * hck
  · exact hbot.comp (tendsto_id.const_mul_atBot hk)
  · exact htop.comp (tendsto_id.const_mul_atTop hk)

end rd_front_existence

#print axioms rd_fence
#print axioms rd_abs_sqrt_sub_le
#print axioms rd_approx_solution
#print axioms rd_sqrt_clamp_approx
#print axioms rd_limit_solution
#print axioms rd_profile
#print axioms rd_front_normalized
#print axioms rd_fisher_front_of_speed

/-- Turing's condition for stripes. Two signals `u`, `v` spread at constant diffusivities
`Du > 0`, `Dv > 0` and react with slopes `fu, fv, gu, gv` at the uniform state, so the
matrix of reaction slopes there is `J = !![fu, fv; gu, gv]`. A ripple `cos (k x)` of
wavenumber `k` evolves by the matrix `J_k = !![fu - Du k², fv; gu, gv - Dv k²]`, and it grows
when `J_k` has an eigenvalue with positive real part. The uniform state is stable without
spreading (trace of `J` negative, determinant positive), yet some ripple grows with spreading,
exactly when `fu + gv < 0`, `fu gv - fv gu > 0` and
`Dv fu + Du gv > 2 sqrt (Du Dv (fu gv - fv gu))`. -/
theorem turing_instability_iff (Du Dv fu fv gu gv : ℝ) (hDu : 0 < Du) (hDv : 0 < Dv) :
    (Matrix.trace !![fu, fv; gu, gv] < 0 ∧ 0 < Matrix.det !![fu, fv; gu, gv] ∧
      ∃ k : ℝ, ∃ σ : ℂ, 0 < σ.re ∧
        Module.End.HasEigenvalue
          (Matrix.toLin' ((!![fu - Du * k ^ 2, fv; gu, gv - Dv * k ^ 2]).map
            (fun x : ℝ => (x : ℂ)))) σ) ↔
      (fu + gv < 0 ∧ 0 < fu * gv - fv * gu ∧
        2 * Real.sqrt (Du * Dv * (fu * gv - fv * gu)) < Dv * fu + Du * gv) := by
  simp only [Matrix.trace_fin_two_of, Matrix.det_fin_two_of, rd_hasEigenvalue_fin_two_iff]
  set E := fu * gv - fv * gu with hE
  set s := Real.sqrt (Du * Dv * E) with hs
  have hDD : 0 < Du * Dv := mul_pos hDu hDv
  constructor
  · rintro ⟨htr, hdet, k, σ, hre, hσ⟩
    refine ⟨htr, hdet, ?_⟩
    have hq : 0 ≤ k ^ 2 := sq_nonneg k
    have htk : fu - Du * k ^ 2 + (gv - Dv * k ^ 2) < 0 := by nlinarith
    have hd := (rd_exists_pos_root_iff _ _ htk).mp ⟨σ, hre, hσ⟩
    set q := k ^ 2
    have hs2 : s ^ 2 = Du * Dv * E := Real.sq_sqrt (by positivity)
    have hs0 : 0 ≤ s := Real.sqrt_nonneg _
    have hqpos : 0 < q := by
      rcases hq.lt_or_eq with h | h
      · exact h
      · rw [← h] at hd; nlinarith
    by_contra hcon
    rw [not_lt] at hcon
    nlinarith [sq_nonneg (Du * Dv * q - s), mul_pos hDD hqpos]
  · rintro ⟨htr, hdet, hm⟩
    refine ⟨htr, hdet, ?_⟩
    set m := Dv * fu + Du * gv
    have hs0 : 0 ≤ s := Real.sqrt_nonneg _
    have hs2 : s ^ 2 = Du * Dv * E := Real.sq_sqrt (by positivity)
    have hmpos : 0 < m := by linarith
    set q := m / (2 * (Du * Dv)) with hqdef
    have hq0 : 0 ≤ q := by positivity
    refine ⟨Real.sqrt q, ?_⟩
    rw [Real.sq_sqrt hq0]
    have htk : fu - Du * q + (gv - Dv * q) < 0 := by nlinarith
    apply (rd_exists_pos_root_iff _ _ htk).mpr
    have hq2 : 2 * (Du * Dv) * q = m := by rw [hqdef]; field_simp
    have hlt : 4 * (Du * Dv * E) < m ^ 2 := by nlinarith
    nlinarith

/-- The threshold ratio. With the uniform state stable on its own (`fu + gv < 0`,
`fu gv - fv gu > 0`) and the activator boosting itself (`fu > 0`), Turing's last inequality
holds exactly when the ratio `d = Dv / Du` passes `d_c = s_c²`, where
`s_c = (sqrt (det J) + sqrt (det J - fu gv)) / fu`. -/
theorem turing_threshold_ratio (Du Dv fu fv gu gv : ℝ) (hDu : 0 < Du) (hDv : 0 < Dv)
    (hfu : 0 < fu) (htr : fu + gv < 0) (hdet : 0 < fu * gv - fv * gu) :
    2 * Real.sqrt (Du * Dv * (fu * gv - fv * gu)) < Dv * fu + Du * gv ↔
      ((Real.sqrt (fu * gv - fv * gu) + Real.sqrt (fu * gv - fv * gu - fu * gv)) / fu) ^ 2
        < Dv / Du := by
  set E := fu * gv - fv * gu with hE
  have hgv : gv < 0 := by linarith
  have hF : 0 < E - fu * gv := by nlinarith
  set a := Real.sqrt E
  set b := Real.sqrt (E - fu * gv)
  have ha2 : a ^ 2 = E := Real.sq_sqrt hdet.le
  have hb2 : b ^ 2 = E - fu * gv := Real.sq_sqrt hF.le
  have ha0 : 0 ≤ a := Real.sqrt_nonneg _
  have hb0 : 0 ≤ b := Real.sqrt_nonneg _
  have hab : a < b := by nlinarith
  set x := Real.sqrt (Dv / Du)
  have hx0 : 0 ≤ x := Real.sqrt_nonneg _
  have hx2 : x ^ 2 = Dv / Du := Real.sq_sqrt (by positivity)
  have hDvx : Dv = Du * x ^ 2 := by rw [hx2]; field_simp
  have hsq : Real.sqrt (Du * Dv * E) = Du * x * a := by
    rw [show Du * Dv * E = (Du * x * a) ^ 2 by rw [hDvx]; nlinarith]
    exact Real.sqrt_sq (by positivity)
  rw [hsq, ← hx2, hDvx]
  have hs0 : 0 ≤ (a + b) / fu := by positivity
  rw [sq_lt_sq₀ hs0 hx0, div_lt_iff₀ hfu]
  constructor
  · intro h
    have h1 : 0 < fu * x ^ 2 - 2 * a * x + gv := by nlinarith
    have h2 : 0 < (fu * x - a - b) * (fu * x - a + b) := by nlinarith
    have h3 : 0 < fu * x - a + b := by nlinarith
    nlinarith [(pos_iff_pos_of_mul_pos h2).mpr h3]
  · intro h
    have h3 : 0 < (fu * x - a - b) * (fu * x - a + b) := by
      apply mul_pos <;> nlinarith
    have : 0 < fu * x ^ 2 - 2 * a * x + gv := by
      have : fu * (fu * x ^ 2 - 2 * a * x + gv) = (fu * x - a - b) * (fu * x - a + b) := by
        nlinarith
      nlinarith
    nlinarith

/-- Fisher's minimum front speed. For `u_t = D u_xx + r u (1 - u)` with `D > 0`, `r > 0`,
a front of fixed shape `u = U (x - c t)` that is a density (never negative), full far behind
(`U → 1`) and empty far ahead (`U → 0`) exists exactly when `c ≥ 2 sqrt (r D)`. -/
theorem fisher_front_exists_iff_speed_ge (D r c : ℝ) (hD : 0 < D) (hr : 0 < r) :
    (∃ U : ℝ → ℝ, ContDiff ℝ 2 U ∧
      (∀ ξ, D * deriv (deriv U) ξ + c * deriv U ξ + r * U ξ * (1 - U ξ) = 0) ∧
      Tendsto U atBot (𝓝 1) ∧ Tendsto U atTop (𝓝 0) ∧ ∀ ξ, 0 ≤ U ξ) ↔
      2 * Real.sqrt (r * D) ≤ c := by
  constructor
  · rintro ⟨U, hU, hode, hbot, htop, hnn⟩
    exact rd_fisher_speed_ge_of_front D r c hD hr U hU hode hbot htop hnn
  · intro hc
    exact rd_fisher_front_of_speed D r c hD hr hc

-- Front speed with r = 1 per day, D = 1/100 mm²/day: c* = 2 sqrt(1/100) = 1/5 mm/day,
-- and 5 mm of bare skin takes 5 / (1/5) = 25 days. The wrong speed sqrt(rD) is 1/10 mm/day.
example : 2 * Real.sqrt (1 * (1 / 100)) = 1 / 5 := by
  rw [show (1 : ℝ) * (1 / 100) = (1 / 10) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  norm_num
example : (5 : ℚ) / (1 / 5) = 25 := by norm_num
example : Real.sqrt (1 * (1 / 100)) = 1 / 10 := by
  rw [show (1 : ℝ) * (1 / 100) = (1 / 10) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]

-- Schnakenberg with a = 1/10, b = 9/10: the uniform state u0 = 1, v0 = 9/10 makes both
-- reactions f = a - u + u² v and g = b - u² v zero.
example : (1 / 10 : ℚ) - 1 + 1 ^ 2 * (9 / 10) = 0 ∧ (9 / 10 : ℚ) - 1 ^ 2 * (9 / 10) = 0 := by
  norm_num
-- Slopes fu = -1 + 2 u0 v0 = 4/5, fv = u0² = 1, gu = -2 u0 v0 = -9/5, gv = -u0² = -1.
example : (-1 : ℚ) + 2 * 1 * (9 / 10) = 4 / 5 ∧ (-2 : ℚ) * 1 * (9 / 10) = -9 / 5 := by norm_num
-- Trace -1/5 and determinant 1.
example : Matrix.trace !![(4 / 5 : ℚ), 1; -9 / 5, -1] = -1 / 5 := by
  simp [Matrix.trace_fin_two_of]; norm_num
example : Matrix.det !![(4 / 5 : ℚ), 1; -9 / 5, -1] = 1 := by
  simp [Matrix.det_fin_two_of]; norm_num
-- At d = 20, m = 20 (4/5) - 1 = 15 and m² = 225 > 4 · 20 · 1 = 80: ripples grow.
example : (20 : ℚ) * (4 / 5) - 1 = 15 ∧ (15 : ℚ) ^ 2 > 4 * 20 * 1 := by norm_num
-- Equal spreading, d = 1: m = 4/5 - 1 = -1/5 < 0, so no ripple grows.
example : (1 : ℚ) * (4 / 5) - 1 = -1 / 5 := by norm_num
-- The threshold d_c = 8.57 lies between 8 and 9: at d = 9, m = 31/5 and m² > 4 · 9;
-- at d = 8, m = 27/5 and m² < 4 · 8.
example : (9 : ℚ) * (4 / 5) - 1 = 31 / 5 ∧ (31 / 5 : ℚ) ^ 2 > 4 * 9 * 1 := by norm_num
example : (8 : ℚ) * (4 / 5) - 1 = 27 / 5 ∧ (27 / 5 : ℚ) ^ 2 < 4 * 8 * 1 := by norm_num
-- At d = 20 the scaled ripple q = k² ℓ² = 1/5 has det J_k = -6/5 < 0: it grows.
example : Matrix.det !![(4 / 5 : ℚ) - 1 / 5, 1; -9 / 5, -1 - 20 * (1 / 5)] = -6 / 5 := by
  simp [Matrix.det_fin_two_of]; norm_num

#print axioms turing_instability_iff
#print axioms turing_threshold_ratio
#print axioms fisher_front_exists_iff_speed_ge
