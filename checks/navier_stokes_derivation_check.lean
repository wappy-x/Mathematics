-- Navier-Stokes: for water of fixed density and viscosity, a smooth solution of the incompressible Navier-Stokes equations has a pressure that solves the Poisson equation −Δp = ρ Σᵢⱼ ∂ᵢuⱼ ∂ⱼuᵢ, a quantity whose integral is zero over every ball is zero at every point, and Poiseuille flow in a pipe is an exact solution whose end pressure balances the wall's drag.
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.Deriv.Pi
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.MeasureTheory.Function.LocallyIntegrable
import Mathlib.MeasureTheory.Measure.Haar.OfBasis
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

open Real MeasureTheory

/-! Space is `Fin 3 → ℝ`: a point `x` has coordinates `x 0`, `x 1`, `x 2`. A velocity field that
changes in time is a function `u : ℝ → Space → Space`, time first, and `u t x i` is its part along
axis `i`. A pressure field is a function `p : ℝ → Space → ℝ`. Derivatives are Mathlib's `fderiv` in
space and `deriv` in time; divergence, the convection term (u·∇)u and the Laplacian are spelled
out component by component, exactly as on the card. -/

/-- Points of space, and vectors at a point. -/
abbrev Space := Fin 3 → ℝ

/-- The rate of change of a quantity `f` on space along axis `i` at the point `x`: ∂ᵢf = ∂f/∂xᵢ. -/
noncomputable def pd (i : Fin 3) (f : Space → ℝ) (x : Space) : ℝ :=
  fderiv ℝ f x (Pi.single i 1)

/-- Divergence (net outflow per unit volume): ∇·u = ∂₀u₀ + ∂₁u₁ + ∂₂u₂. -/
noncomputable def divergence (u : Space → Space) (x : Space) : ℝ :=
  ∑ i : Fin 3, pd i (fun y => u y i) x

/-- The Laplacian of a quantity on space: Δf = ∂₀∂₀f + ∂₁∂₁f + ∂₂∂₂f. -/
noncomputable def laplacian (f : Space → ℝ) (x : Space) : ℝ :=
  ∑ j : Fin 3, pd j (pd j f) x

/-- Part `i` of the convection term (u·∇)u: velocity times its own slope, Σⱼ uⱼ ∂ⱼuᵢ. -/
noncomputable def convection (u : Space → Space) (x : Space) (i : Fin 3) : ℝ :=
  ∑ j : Fin 3, u x j * pd j (fun y => u y i) x

/-- The incompressible Navier-Stokes equations for a fluid of fixed density `ρ`, fixed viscosity
`μ` and constant gravity `g`, at every time and every point: the water does not compress,
∇·u = 0, and Newton's law holds for every parcel,
ρ (∂u/∂t + (u·∇)u) = −∇p + μ Δu + ρ g, one equation for each axis `i`. -/
def NavierStokes (ρ μ : ℝ) (g : Space) (u : ℝ → Space → Space) (p : ℝ → Space → ℝ) : Prop :=
  (∀ t x, divergence (u t) x = 0) ∧
  ∀ t x (i : Fin 3),
    ρ * (deriv (fun s => u s x i) t + convection (u t) x i)
      = -pd i (p t) x + μ * laplacian (fun y => u t y i) x + ρ * g i

section NSHelpers
variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]

lemma ns_dir_contDiff {m n : WithTop ℕ∞} {G : E → ℝ} (hG : ContDiff ℝ m G) (hmn : n + 1 ≤ m)
    (v : E) : ContDiff ℝ n (fun y => fderiv ℝ G y v) :=
  (hG.fderiv_right hmn).clm_apply contDiff_const

lemma ns_dir_symm {G : E → ℝ} (hG : ContDiff ℝ 2 G) (q v w : E) :
    fderiv ℝ (fun y => fderiv ℝ G y v) q w = fderiv ℝ (fun y => fderiv ℝ G y w) q v := by
  have hd : DifferentiableAt ℝ (fderiv ℝ G) q :=
    ((hG.fderiv_right (m := 1) (by norm_num)).differentiable one_ne_zero) q
  rw [fderiv_clm_apply hd (differentiableAt_const v), fderiv_clm_apply hd (differentiableAt_const w)]
  simp
  exact (hG.contDiffAt.isSymmSndFDerivAt (by rw [minSmoothness_of_isRCLikeNormedField])) w v

lemma ns_pd_slice {G : ℝ × Space → ℝ} {t : ℝ} {x : Space} (hG : DifferentiableAt ℝ G (t, x))
    (j : Fin 3) : pd j (fun y => G (t, y)) x = fderiv ℝ G (t, x) (0, Pi.single j 1) := by
  have h1 : HasFDerivAt (fun y : Space => (t, y))
      ((0 : Space →L[ℝ] ℝ).prod (ContinuousLinearMap.id ℝ Space)) x :=
    (hasFDerivAt_const t x).prodMk (hasFDerivAt_id x)
  have h2 := hG.hasFDerivAt.comp x h1
  show fderiv ℝ (G ∘ fun y => (t, y)) x _ = _
  rw [h2.fderiv]
  rfl

lemma ns_deriv_slice {G : ℝ × Space → ℝ} {t : ℝ} {x : Space} (hG : DifferentiableAt ℝ G (t, x)) :
    deriv (fun s => G (s, x)) t = fderiv ℝ G (t, x) (1, 0) := by
  have h1 : HasDerivAt (fun s : ℝ => (s, x)) (1, 0) t :=
    (hasDerivAt_id t).prodMk (hasDerivAt_const t x)
  exact (hG.hasFDerivAt.comp_hasDerivAt t h1).deriv

lemma ns_pd_contDiff {m n : WithTop ℕ∞} {f : Space → ℝ} (hf : ContDiff ℝ m f) (hmn : n + 1 ≤ m)
    (i : Fin 3) : ContDiff ℝ n (pd i f) :=
  ns_dir_contDiff hf hmn _

lemma ns_pd_comm {f : Space → ℝ} (hf : ContDiff ℝ 2 f) (i j : Fin 3) (x : Space) :
    pd i (pd j f) x = pd j (pd i f) x :=
  ns_dir_symm hf x _ _

lemma ns_pd_sum {ι : Type*} (s : Finset ι) (f : ι → Space → ℝ) (i : Fin 3) (x : Space)
    (h : ∀ k, DifferentiableAt ℝ (f k) x) :
    pd i (fun y => ∑ k ∈ s, f k y) x = ∑ k ∈ s, pd i (f k) x := by
  unfold pd
  rw [fderiv_fun_sum (fun k _ => h k)]
  simp

lemma ns_pd_mul (f g : Space → ℝ) (i : Fin 3) (x : Space)
    (hf : DifferentiableAt ℝ f x) (hg : DifferentiableAt ℝ g x) :
    pd i (fun y => f y * g y) x = f x * pd i g x + g x * pd i f x := by
  unfold pd
  rw [fderiv_fun_mul hf hg]
  simp

lemma ns_pd_zero (i : Fin 3) : pd i (fun _ => (0 : ℝ)) = fun _ => 0 := by
  funext x; unfold pd; simp

lemma ns_pd_lin (a b c : Space → ℝ) (ρ μ k : ℝ) (i : Fin 3) (x : Space)
    (ha : DifferentiableAt ℝ a x) (hb : DifferentiableAt ℝ b x) (hc : DifferentiableAt ℝ c x) :
    pd i (fun y => -ρ * (a y + b y) + μ * c y + k) x
      = -ρ * (pd i a x + pd i b x) + μ * pd i c x := by
  have h : HasFDerivAt (fun y => -ρ * (a y + b y) + μ * c y + k)
      ((-ρ) • (fderiv ℝ a x + fderiv ℝ b x) + μ • fderiv ℝ c x) x :=
    (((ha.hasFDerivAt.add hb.hasFDerivAt).const_mul (-ρ)).add
      (hc.hasFDerivAt.const_mul μ)).add_const k
  unfold pd
  rw [h.fderiv]
  simp
  ring

lemma ns_space_slice {n : WithTop ℕ∞} {G : ℝ × Space → ℝ} (hG : ContDiff ℝ n G) (s : ℝ) :
    ContDiff ℝ n (fun y : Space => G (s, y)) :=
  hG.comp (contDiff_const.prodMk contDiff_id)

lemma ns_time_slice {n : WithTop ℕ∞} {G : ℝ × Space → ℝ} (hG : ContDiff ℝ n G) (x : Space) :
    ContDiff ℝ n (fun s : ℝ => G (s, x)) :=
  hG.comp (contDiff_id.prodMk contDiff_const)

lemma ns_time_deriv_diff {G : ℝ × Space → ℝ} (hG : ContDiff ℝ 2 G) (t : ℝ) :
    Differentiable ℝ (fun y => deriv (fun s => G (s, y)) t) := by
  have hd : ∀ q, DifferentiableAt ℝ G q := hG.differentiable (by norm_num)
  have h1 : (fun y => deriv (fun s => G (s, y)) t) = fun y => fderiv ℝ G (t, y) (1, 0) :=
    funext fun y => ns_deriv_slice (hd _)
  rw [h1]
  exact (ns_space_slice (ns_dir_contDiff (n := 1) hG (by norm_num) _) t).differentiable
    (by norm_num)

lemma ns_pd_time_diff {G : ℝ × Space → ℝ} (hG : ContDiff ℝ 2 G) (x : Space) (j : Fin 3) :
    Differentiable ℝ (fun s => pd j (fun y => G (s, y)) x) := by
  have hd : ∀ q, DifferentiableAt ℝ G q := hG.differentiable (by norm_num)
  have h2 : (fun s => pd j (fun y => G (s, y)) x)
      = fun s => fderiv ℝ G (s, x) (0, Pi.single j 1) :=
    funext fun s => ns_pd_slice (hd _) j
  rw [h2]
  exact (ns_time_slice (ns_dir_contDiff (n := 1) hG (by norm_num) _) x).differentiable
    (by norm_num)

lemma ns_time_space_comm {G : ℝ × Space → ℝ} (hG : ContDiff ℝ 3 G) (t : ℝ) (x : Space)
    (j : Fin 3) :
    pd j (fun y => deriv (fun s => G (s, y)) t) x = deriv (fun s => pd j (fun y => G (s, y)) x) t := by
  have hd : ∀ q, DifferentiableAt ℝ G q := hG.differentiable (by norm_num)
  have hA : ContDiff ℝ 2 (fun q => fderiv ℝ G q (1, 0)) := ns_dir_contDiff hG (by norm_num) _
  have hB : ContDiff ℝ 2 (fun q => fderiv ℝ G q (0, Pi.single j 1)) :=
    ns_dir_contDiff hG (by norm_num) _
  have h1 : (fun y => deriv (fun s => G (s, y)) t) = fun y => fderiv ℝ G (t, y) (1, 0) :=
    funext fun y => ns_deriv_slice (hd _)
  have h2 : (fun s => pd j (fun y => G (s, y)) x)
      = fun s => fderiv ℝ G (s, x) (0, Pi.single j 1) :=
    funext fun s => ns_pd_slice (hd _) j
  rw [h1, h2]
  calc pd j (fun y => fderiv ℝ G (t, y) (1, 0)) x
      = fderiv ℝ (fun q => fderiv ℝ G q (1, 0)) (t, x) (0, Pi.single j 1) :=
        ns_pd_slice (G := fun q => fderiv ℝ G q (1, 0)) (hA.differentiable (by norm_num) _) j
    _ = fderiv ℝ (fun q => fderiv ℝ G q (0, Pi.single j 1)) (t, x) (1, 0) :=
        ns_dir_symm (hG.of_le (by norm_num)) _ _ _
    _ = deriv (fun s => fderiv ℝ G (s, x) (0, Pi.single j 1)) t :=
        (ns_deriv_slice (G := fun q => fderiv ℝ G q (0, Pi.single j 1))
          (hB.differentiable (by norm_num) _)).symm

end NSHelpers

lemma ns_pos_contra (f : Space → ℝ) (hf : Continuous f)
    (h : ∀ x (r : ℝ), 0 < r → ∫ y in Metric.ball x r, f y = 0) (x : Space) : ¬ 0 < f x := by
  intro hx
  obtain ⟨r, hr, hball⟩ := Metric.mem_nhds_iff.1
    (hf.continuousAt.preimage_mem_nhds (Ioi_mem_nhds (by linarith : f x / 2 < f x)))
  have hint : IntegrableOn f (Metric.ball x r) volume :=
    ((hf.continuousOn).integrableOn_compact (isCompact_closedBall x r)).mono_set
      Metric.ball_subset_closedBall
  have hge := setIntegral_ge_of_const_le_real (c := f x / 2) (μ := volume) measurableSet_ball
    measure_ball_lt_top.ne (fun y hy => le_of_lt (hball hy)) hint
  have hpos : 0 < volume.real (Metric.ball x r) :=
    ENNReal.toReal_pos (Metric.measure_ball_pos volume x hr).ne' measure_ball_lt_top.ne
  rw [h x r hr] at hge
  have : 0 < f x / 2 * volume.real (Metric.ball x r) := mul_pos (by linarith) hpos
  linarith

lemma ns_pd_eq_deriv (f : Space → ℝ) (x : Space) (i : Fin 3) (hf : DifferentiableAt ℝ f x) :
    pd i f x = deriv (fun s => f (Function.update x i s)) (x i) := by
  have hf' : HasFDerivAt f (fderiv ℝ f x) (Function.update x i (x i)) := by
    rw [Function.update_eq_self]; exact hf.hasFDerivAt
  exact (hf'.comp_hasDerivAt (x i) (hasDerivAt_update x i (x i))).deriv.symm

#print axioms ns_dir_contDiff
#print axioms ns_dir_symm
#print axioms ns_pd_slice
#print axioms ns_deriv_slice
#print axioms ns_pd_contDiff
#print axioms ns_pd_comm
#print axioms ns_pd_sum
#print axioms ns_pd_mul
#print axioms ns_pd_zero
#print axioms ns_pd_lin
#print axioms ns_space_slice
#print axioms ns_time_slice
#print axioms ns_time_deriv_diff
#print axioms ns_pd_time_diff
#print axioms ns_time_space_comm
#print axioms ns_pos_contra
#print axioms ns_pd_eq_deriv

/-- The pressure's job (Step 5, the card's main claim). Take water of fixed density `ρ` and
fixed viscosity `μ`, under constant gravity `g`, and a classical solution `u`, `p` of the
incompressible Navier-Stokes equations: the velocity smooth enough for the card's step of taking
the divergence of the momentum equation (three times continuously differentiable in space and time
together) and the pressure continuously differentiable. Then at every instant the pressure is
fixed by the velocity at that instant through its own Poisson equation:
−Δp = ρ Σᵢ Σⱼ (∂uⱼ/∂xᵢ)(∂uᵢ/∂xⱼ). -/
theorem pressure_solves_poisson_equation (ρ μ : ℝ) (g : Space)
    (u : ℝ → Space → Space) (p : ℝ → Space → ℝ)
    (hu : ContDiff ℝ 3 (fun q : ℝ × Space => u q.1 q.2))
    (hp : ContDiff ℝ 1 (fun q : ℝ × Space => p q.1 q.2))
    (hNS : NavierStokes ρ μ g u p) :
    ∀ t x, -laplacian (p t) x
      = ρ * ∑ i : Fin 3, ∑ j : Fin 3, pd i (fun y => u t y j) x * pd j (fun y => u t y i) x := by
  intro t x
  obtain ⟨hdiv, hmom⟩ := hNS
  have hFk : ∀ k, ContDiff ℝ 3 (fun q : ℝ × Space => u q.1 q.2 k) := fun k => contDiff_pi.1 hu k
  have hv : ∀ s k, ContDiff ℝ 3 (fun y => u s y k) := fun s k => ns_space_slice (hFk k) s
  have hv2 : ∀ s k, ContDiff ℝ 2 (fun y => u s y k) := fun s k => (hv s k).of_le (by norm_num)
  have hpd2 : ∀ s k i, ContDiff ℝ 2 (pd i (fun y => u s y k)) :=
    fun s k i => ns_pd_contDiff (hv s k) (by norm_num) i
  have hpd1 : ∀ s k i j, ContDiff ℝ 1 (pd j (pd i (fun y => u s y k))) :=
    fun s k i j => ns_pd_contDiff (hpd2 s k i) (by norm_num) j
  have dv : ∀ s k y, DifferentiableAt ℝ (fun y => u s y k) y :=
    fun s k y => (hv s k).differentiable (by norm_num) y
  have dpd : ∀ s k i y, DifferentiableAt ℝ (pd i (fun y => u s y k)) y :=
    fun s k i y => (hpd2 s k i).differentiable (by norm_num) y
  have dpd2 : ∀ s k i j y, DifferentiableAt ℝ (pd j (pd i (fun y => u s y k))) y :=
    fun s k i j y => (hpd1 s k i j).differentiable (by norm_num) y
  have hdivfun : ∀ s, (fun y => ∑ j : Fin 3, pd j (fun y => u s y j) y) = fun _ => 0 := by
    intro s; funext y; exact hdiv s y
  -- the pressure gradient, read off the momentum equation
  have hP : ∀ j, pd j (p t) = fun y => -ρ * (deriv (fun s => u s y j) t + convection (u t) y j)
      + μ * laplacian (fun y => u t y j) y + ρ * g j := by
    intro j; funext y; have := hmom t y j; linarith
  have hDdiff : ∀ j, DifferentiableAt ℝ (fun y => deriv (fun s => u s y j) t) x :=
    fun j => ns_time_deriv_diff (G := fun q : ℝ × Space => u q.1 q.2 j)
      ((hFk j).of_le (by norm_num)) t x
  have hCdiff : ∀ j, DifferentiableAt ℝ (fun y => convection (u t) y j) x := by
    intro j; unfold convection
    exact DifferentiableAt.fun_sum (fun k _ => (dv t k x).mul (dpd t j k x))
  have hLdiff : ∀ j, DifferentiableAt ℝ (fun y => laplacian (fun y => u t y j) y) x := by
    intro j; unfold laplacian
    exact DifferentiableAt.fun_sum (fun k _ => dpd2 t j k k x)
  -- time part: the time derivative of the divergence, which is zero
  have hT : ∑ j : Fin 3, pd j (fun y => deriv (fun s => u s y j) t) x = 0 := by
    have key : ∀ j : Fin 3, pd j (fun y => deriv (fun s => u s y j) t) x
        = deriv (fun s => pd j (fun y => u s y j) x) t :=
      fun j => ns_time_space_comm (G := fun q : ℝ × Space => u q.1 q.2 j) (hFk j) t x j
    rw [Finset.sum_congr rfl (fun j _ => key j)]
    rw [← deriv_fun_sum (fun j _ => ns_pd_time_diff (G := fun q : ℝ × Space => u q.1 q.2 j)
      ((hFk j).of_le (by norm_num)) x j t)]
    have h0 : (fun s => ∑ j : Fin 3, pd j (fun y => u s y j) x) = fun _ => 0 :=
      funext fun s => hdiv s x
    rw [h0]; simp
  -- convection part
  have hz : ∀ k, ∑ j : Fin 3, pd j (pd k (fun y => u t y j)) x = 0 := by
    intro k
    rw [Finset.sum_congr rfl (fun j _ => ns_pd_comm (hv2 t j) j k x)]
    rw [← ns_pd_sum _ (fun j => pd j (fun y => u t y j)) k x (fun j => dpd t j j x)]
    rw [hdivfun t, ns_pd_zero]
  have hCj : ∀ j, pd j (fun y => convection (u t) y j) x
      = ∑ k : Fin 3, (u t x k * pd j (pd k (fun y => u t y j)) x
          + pd k (fun y => u t y j) x * pd j (fun y => u t y k) x) := by
    intro j; unfold convection
    rw [ns_pd_sum _ (fun k y => u t y k * pd k (fun y => u t y j) y) j x
      (fun k => (dv t k x).mul (dpd t j k x))]
    refine Finset.sum_congr rfl (fun k _ => ?_)
    exact ns_pd_mul (fun y => u t y k) (pd k (fun y => u t y j)) j x (dv t k x) (dpd t j k x)
  have hC : ∑ j : Fin 3, pd j (fun y => convection (u t) y j) x
      = ∑ i : Fin 3, ∑ j : Fin 3, pd i (fun y => u t y j) x * pd j (fun y => u t y i) x := by
    rw [Finset.sum_congr rfl (fun j _ => hCj j)]
    have h0 := hz 0
    have h1 := hz 1
    have h2 := hz 2
    simp only [Fin.sum_univ_three] at h0 h1 h2 ⊢
    linear_combination u t x 0 * h0 + u t x 1 * h1 + u t x 2 * h2
  -- viscous part
  have hz2 : ∀ k, ∑ j : Fin 3, pd k (pd k (pd j (fun y => u t y j))) x = 0 := by
    intro k
    have hf : (fun y => ∑ j : Fin 3, pd k (pd j (fun y => u t y j)) y) = fun _ => 0 := by
      funext y
      rw [← ns_pd_sum _ (fun j => pd j (fun y => u t y j)) k y (fun j => dpd t j j y)]
      rw [hdivfun t, ns_pd_zero]
    rw [← ns_pd_sum _ (fun j => pd k (pd j (fun y => u t y j))) k x (fun j => dpd2 t j j k x)]
    rw [hf, ns_pd_zero]
  have hL : ∑ j : Fin 3, pd j (fun y => laplacian (fun y => u t y j) y) x = 0 := by
    have hLj : ∀ j, pd j (fun y => laplacian (fun y => u t y j) y) x
        = ∑ k : Fin 3, pd k (pd k (pd j (fun y => u t y j))) x := by
      intro j; unfold laplacian
      rw [ns_pd_sum _ (fun k => pd k (pd k (fun y => u t y j))) j x (fun k => dpd2 t j k k x)]
      refine Finset.sum_congr rfl (fun k _ => ?_)
      rw [ns_pd_comm (hpd2 t j k) j k x]
      have hf : pd j (pd k (fun y => u t y j)) = pd k (pd j (fun y => u t y j)) :=
        funext (ns_pd_comm (hv2 t j) j k)
      rw [hf]
    rw [Finset.sum_congr rfl (fun j _ => hLj j), Finset.sum_comm]
    exact Finset.sum_eq_zero (fun k _ => hz2 k)
  -- assemble
  have hstep : ∀ j, pd j (pd j (p t)) x
      = -ρ * (pd j (fun y => deriv (fun s => u s y j) t) x
          + pd j (fun y => convection (u t) y j) x)
        + μ * pd j (fun y => laplacian (fun y => u t y j) y) x := by
    intro j
    rw [hP j]
    exact ns_pd_lin (fun y => deriv (fun s => u s y j) t) (fun y => convection (u t) y j)
      (fun y => laplacian (fun y => u t y j) y) ρ μ (ρ * g j) j x (hDdiff j) (hCdiff j) (hLdiff j)
  show -(∑ j : Fin 3, pd j (pd j (p t)) x) = _
  rw [Finset.sum_congr rfl (fun j _ => hstep j)]
  rw [← hC]
  simp only [Fin.sum_univ_three] at hT hL ⊢
  linear_combination ρ * hT - μ * hL

/-- Zero over every region forces zero at every point (Step 1's folded proof). If a quantity `f`
on space is continuous and its integral over every ball is zero, then `f` is zero at every point.
(Balls here are for the distance of `Space`, the largest coordinate difference, so they are cubes;
every cube is a region, so this is the card's statement.) -/
theorem eq_zero_of_integral_ball_eq_zero (f : Space → ℝ) (hf : Continuous f)
    (h : ∀ x (r : ℝ), 0 < r → ∫ y in Metric.ball x r, f y = 0) :
    ∀ x, f x = 0 := by
  intro x
  by_contra hne
  rcases lt_or_gt_of_ne hne with hlt | hgt
  · refine ns_pos_contra (fun y => -f y) hf.neg (fun z r hr => ?_) x (by simpa using hlt)
    rw [integral_neg, h z r hr, neg_zero]
  · exact ns_pos_contra f hf h x hgt

/-- Poiseuille flow in a pipe of radius `R` along axis 2, mean speed `V`: the speed along the pipe
is 2V(1 − r²/R²) at distance r from the axis, and nothing moves across the pipe. -/
noncomputable def poiseuilleVelocity (V R : ℝ) (_t : ℝ) (x : Space) : Space :=
  ![0, 0, 2 * V * (1 - (x 0 ^ 2 + x 1 ^ 2) / R ^ 2)]

/-- Its pressure: `p₀` at the start, falling by `G` pascals per metre along the pipe. -/
def poiseuillePressure (G p₀ : ℝ) (_t : ℝ) (x : Space) : ℝ :=
  p₀ - G * x 2

/-- Poiseuille flow solves the derived equations (Step 4). For water of any density `ρ` and
viscosity `μ` in a pipe of radius `R > 0` at mean speed `V`, with gravity absorbed into the
pressure, the parabola 2V(1 − r²/R²) with the pressure falling G = 8μV/R² per metre is an exact
solution of the incompressible Navier-Stokes equations; the water sticks to the wall (speed zero at
r = R); and on one metre of pipe the pressure force on the ends, G πR², equals the wall's drag,
τ_w · 2πR, where τ_w = −μ du/dr at the wall. -/
theorem poiseuille_solves_navier_stokes (ρ μ V R p₀ : ℝ) (hR : 0 < R) :
    NavierStokes ρ μ 0 (poiseuilleVelocity V R) (poiseuillePressure (8 * μ * V / R ^ 2) p₀) ∧
      (∀ t x, x 0 ^ 2 + x 1 ^ 2 = R ^ 2 → poiseuilleVelocity V R t x = 0) ∧
      (8 * μ * V / R ^ 2) * π * R ^ 2
        = (-μ * deriv (fun r => 2 * V * (1 - r ^ 2 / R ^ 2)) R) * (2 * π * R) := by
  have hR2 : R ^ 2 ≠ 0 := by positivity
  have hv0 : ∀ t x, poiseuilleVelocity V R t x 0 = 0 := by simp [poiseuilleVelocity]
  have hv1 : ∀ t x, poiseuilleVelocity V R t x 1 = 0 := by simp [poiseuilleVelocity]
  have hv2 : ∀ t x, poiseuilleVelocity V R t x 2 = 2 * V * (1 - (x 0 ^ 2 + x 1 ^ 2) / R ^ 2) := by
    simp [poiseuilleVelocity]
  have hw0 : pd 0 (fun y : Space => 2 * V * (1 - (y 0 ^ 2 + y 1 ^ 2) / R ^ 2))
      = fun y => -4 * V * y 0 / R ^ 2 := by
    funext x
    rw [ns_pd_eq_deriv _ _ _ (by fun_prop)]
    simp only [Function.update_self, Function.update_of_ne (by decide : (1 : Fin 3) ≠ 0)]
    have := ((((hasDerivAt_pow 2 (x 0)).add_const (x 1 ^ 2)).div_const (R ^ 2)).const_sub
      1).const_mul (2 * V)
    rw [this.deriv]
    ring
  have hw1 : pd 1 (fun y : Space => 2 * V * (1 - (y 0 ^ 2 + y 1 ^ 2) / R ^ 2))
      = fun y => -4 * V * y 1 / R ^ 2 := by
    funext x
    rw [ns_pd_eq_deriv _ _ _ (by fun_prop)]
    simp only [Function.update_self, Function.update_of_ne (by decide : (0 : Fin 3) ≠ 1)]
    have := ((((hasDerivAt_pow 2 (x 1)).const_add (x 0 ^ 2)).div_const (R ^ 2)).const_sub
      1).const_mul (2 * V)
    rw [this.deriv]
    ring
  have hw2 : pd 2 (fun y : Space => 2 * V * (1 - (y 0 ^ 2 + y 1 ^ 2) / R ^ 2))
      = fun _ => 0 := by
    funext x
    rw [ns_pd_eq_deriv _ _ _ (by fun_prop)]
    simp only [Function.update_of_ne (by decide : (0 : Fin 3) ≠ 2),
      Function.update_of_ne (by decide : (1 : Fin 3) ≠ 2)]
    exact deriv_const _ _
  have hw00 : pd 0 (fun y : Space => -4 * V * y 0 / R ^ 2) = fun _ => -4 * V / R ^ 2 := by
    funext x
    rw [ns_pd_eq_deriv _ _ _ (by fun_prop)]
    simp only [Function.update_self]
    have := ((hasDerivAt_id' (x 0)).const_mul (-4 * V)).div_const (R ^ 2)
    rw [this.deriv]
    ring
  have hw11 : pd 1 (fun y : Space => -4 * V * y 1 / R ^ 2) = fun _ => -4 * V / R ^ 2 := by
    funext x
    rw [ns_pd_eq_deriv _ _ _ (by fun_prop)]
    simp only [Function.update_self]
    have := ((hasDerivAt_id' (x 1)).const_mul (-4 * V)).div_const (R ^ 2)
    rw [this.deriv]
    ring
  have hp0 : ∀ t, pd 0 (poiseuillePressure (8 * μ * V / R ^ 2) p₀ t) = fun _ => 0 := by
    intro t; funext x
    rw [ns_pd_eq_deriv _ _ _ (by unfold poiseuillePressure; fun_prop)]
    simp only [poiseuillePressure, Function.update_of_ne (by decide : (2 : Fin 3) ≠ 0)]
    exact deriv_const _ _
  have hp1 : ∀ t, pd 1 (poiseuillePressure (8 * μ * V / R ^ 2) p₀ t) = fun _ => 0 := by
    intro t; funext x
    rw [ns_pd_eq_deriv _ _ _ (by unfold poiseuillePressure; fun_prop)]
    simp only [poiseuillePressure, Function.update_of_ne (by decide : (2 : Fin 3) ≠ 1)]
    exact deriv_const _ _
  have hp2 : ∀ t, pd 2 (poiseuillePressure (8 * μ * V / R ^ 2) p₀ t)
      = fun _ => -(8 * μ * V / R ^ 2) := by
    intro t; funext x
    rw [ns_pd_eq_deriv _ _ _ (by unfold poiseuillePressure; fun_prop)]
    simp only [poiseuillePressure, Function.update_self]
    have := ((hasDerivAt_id' (x 2)).const_mul (8 * μ * V / R ^ 2)).const_sub p₀
    rw [this.deriv, mul_one]
  refine ⟨⟨?_, ?_⟩, ?_, ?_⟩
  · intro t x
    simp only [divergence, Fin.sum_univ_three, hv0, hv1, hv2, ns_pd_zero, hw2]
    norm_num
  · intro t x i
    have hi : i = 0 ∨ i = 1 ∨ i = 2 := by fin_cases i <;> simp
    rcases hi with rfl | rfl | rfl <;>
      simp only [convection, laplacian, Fin.sum_univ_three, hv0, hv1, hv2, ns_pd_zero, hw0, hw1,
        hw2, hw00, hw11, hp0, hp1, hp2, deriv_const, Pi.zero_apply] <;>
      field_simp <;> ring
  · intro t x hx
    funext i
    fin_cases i <;> simp [poiseuilleVelocity, hx, hR2]
  · have := (((hasDerivAt_pow 2 R).div_const (R ^ 2)).const_sub 1).const_mul (2 * V)
    rw [this.deriv]
    field_simp
    ring

-- Worked numbers by hand, exactly: water at 20 °C, μ = 1.0016 × 10⁻³ Pa s = 10016/10⁷ Pa s,
-- ρ = 998.207 kg/m³ = 998207/1000 kg/m³, mean speed V = 1 m/s, bore 5 cm so R = 25/1000 m.
-- Pressure drop G = 8μV/R² = 12.82048 Pa/m (the card's 12.8205 Pa/m).
example : (8 : ℚ) * (10016 / 10 ^ 7) * 1 / (25 / 1000) ^ 2 = 1282048 / 10 ^ 5 := by norm_num
-- Wall drag τ_w = 4μV/R = 0.160256 Pa.
example : (4 : ℚ) * (10016 / 10 ^ 7) * 1 / (25 / 1000) = 160256 / 10 ^ 6 := by norm_num
-- Reading 1 m/s as the centre speed halves the drop: 4μV/R² = 6.41024 Pa/m (the card's 6.4102).
example : (4 : ℚ) * (10016 / 10 ^ 7) * 1 / (25 / 1000) ^ 2 = 641024 / 10 ^ 5 := by norm_num
-- Twice the speed doubles the drop (25.64096 Pa/m); twice the bore quarters it (3.20512 Pa/m).
example : (8 : ℚ) * (10016 / 10 ^ 7) * 2 / (25 / 1000) ^ 2 = 2564096 / 10 ^ 5 := by norm_num
example : (8 : ℚ) * (10016 / 10 ^ 7) * 1 / (50 / 1000) ^ 2 = 320512 / 10 ^ 5 := by norm_num
-- Taylor-Green eddy, U = 1 m/s: the pressure ρU²/4 (cos 2kx + cos 2ky) is −499.1035 Pa at an
-- eddy's centre (both angles π) and +499.1035 Pa at a corner (both angles 0).
example : (998207 / 1000 : ℝ) * 1 ^ 2 / 4 * (cos π + cos π) = -4991035 / 10000 := by
  rw [cos_pi]; norm_num
example : (998207 / 1000 : ℝ) * 1 ^ 2 / 4 * (cos 0 + cos 0) = 4991035 / 10000 := by
  rw [cos_zero]; norm_num

#print axioms pressure_solves_poisson_equation
#print axioms eq_zero_of_integral_ball_eq_zero
#print axioms poiseuille_solves_navier_stokes
