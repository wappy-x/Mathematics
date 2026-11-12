-- Second-order conditions under constraints: at a point that passes the KKT test, a Lagrangian that curves strictly upward on every nonzero direction of the critical cone gives a strict local minimum, a regular local minimum whose active constraints all have positive prices has curvature zero or above on that cone, and the pipe's 400 L/s at 40 m is the most power any allowed choice delivers.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.Tactic
import Mathlib

open Finset

/-- The Lagrangian `L = f₀ + Σ λᵢ fᵢ + Σ νⱼ hⱼ` of the problem: minimise `f₀` subject to
`fᵢ ≤ 0` and `hⱼ = 0`, with prices `λ` on the inequalities and `ν` on the equalities. -/
noncomputable def lagrangian {n m p : ℕ} (f₀ : EuclideanSpace ℝ (Fin n) → ℝ)
    (f : Fin m → EuclideanSpace ℝ (Fin n) → ℝ) (h : Fin p → EuclideanSpace ℝ (Fin n) → ℝ)
    (lam : Fin m → ℝ) (nu : Fin p → ℝ) : EuclideanSpace ℝ (Fin n) → ℝ :=
  fun y => f₀ y + ∑ i, lam i * f i y + ∑ j, nu j * h j y

/-- The critical cone at `x`: the directions `d` with `∇hⱼ(x)ᵀd = 0` for every `j`,
`∇fᵢ(x)ᵀd = 0` for every active `fᵢ` with `λᵢ > 0`, and `∇fᵢ(x)ᵀd ≤ 0` for every active `fᵢ`
with `λᵢ = 0`. An active constraint is one with `fᵢ(x) = 0`. -/
def criticalCone {n m p : ℕ} (f : Fin m → EuclideanSpace ℝ (Fin n) → ℝ)
    (h : Fin p → EuclideanSpace ℝ (Fin n) → ℝ) (lam : Fin m → ℝ) (x : EuclideanSpace ℝ (Fin n)) :
    Set (EuclideanSpace ℝ (Fin n)) :=
  {d | (∀ j, fderiv ℝ (h j) x d = 0) ∧
    (∀ i, f i x = 0 → 0 < lam i → fderiv ℝ (f i) x d = 0) ∧
    (∀ i, f i x = 0 → lam i = 0 → fderiv ℝ (f i) x d ≤ 0)}

section Helpers

open Filter Topology Asymptotics

lemma taylor_two_littleO {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : E → ℝ) (x : E) (hg : ContDiffAt ℝ 2 g x) :
    (fun y => g y - g x - fderiv ℝ g x (y - x) -
        (1 / 2) * fderiv ℝ (fderiv ℝ g) x (y - x) (y - x))
      =o[𝓝 x] (fun y => ‖y - x‖ ^ 2) := by
  set B := fderiv ℝ (fderiv ℝ g) x with hBdef
  have hsymm : ∀ v w, B v w = B w v := hg.isSymmSndFDerivAt (by simp)
  have hev : ∀ᶠ z in 𝓝 x, HasFDerivAt g (fderiv ℝ g z) z := by
    filter_upwards [hg.eventually (by simp)] with z hz
    exact (hz.differentiableAt (by simp)).hasFDerivAt
  have h2 : HasFDerivAt (fderiv ℝ g) B x :=
    ((hg.fderiv_right (m := 1) (by norm_num)).differentiableAt (by simp)).hasFDerivAt
  rw [Asymptotics.isLittleO_iff]
  intro c hc
  have hlo := (hasFDerivAt_iff_isLittleO.1 h2)
  rw [Asymptotics.isLittleO_iff] at hlo
  have hb := hlo hc
  obtain ⟨δ, hδ, hball⟩ := Metric.eventually_nhds_iff_ball.1 (hev.and hb)
  filter_upwards [Metric.ball_mem_nhds x hδ] with y hy
  set R : E → ℝ := fun y => g y - g x - fderiv ℝ g x (y - x) -
        (1 / 2) * B (y - x) (y - x) with hRdef
  have hsub : Metric.closedBall x ‖y - x‖ ⊆ Metric.ball x δ := by
    apply Metric.closedBall_subset_ball
    simpa [dist_eq_norm] using hy
  have hR : ∀ z ∈ Metric.closedBall x ‖y - x‖,
      HasFDerivWithinAt R (fderiv ℝ g z - fderiv ℝ g x - B (z - x))
        (Metric.closedBall x ‖y - x‖) z := by
    intro z hz
    have hgz := (hball z (hsub hz)).1
    have hlin : HasFDerivAt (fun y : E => y - x) (ContinuousLinearMap.id ℝ E) z :=
      (hasFDerivAt_id z).sub_const x
    have hq : HasFDerivAt (fun y => B (y - x) (y - x))
        ((B (z - x)).comp (ContinuousLinearMap.id ℝ E) + (B.comp (ContinuousLinearMap.id ℝ E)).flip (z - x)) z :=
      (B.hasFDerivAt.comp z hlin).clm_apply hlin
    have hl : HasFDerivAt (fun y => fderiv ℝ g x (y - x)) ((fderiv ℝ g x).comp (ContinuousLinearMap.id ℝ E)) z :=
      (fderiv ℝ g x).hasFDerivAt.comp z hlin
    have hall := ((hgz.sub_const (g x)).sub hl).sub (hq.const_mul (1 / 2))
    apply HasFDerivAt.hasFDerivWithinAt
    refine hall.congr_fderiv ?_
    ext w
    simp
    rw [hsymm w z, hsymm w x]
    ring
  have bound : ∀ z ∈ Metric.closedBall x ‖y - x‖,
      ‖fderiv ℝ g z - fderiv ℝ g x - B (z - x)‖ ≤ c * ‖y - x‖ := by
    intro z hz
    have := (hball z (hsub hz)).2
    calc _ ≤ c * ‖z - x‖ := this
      _ ≤ c * ‖y - x‖ := by
        apply mul_le_mul_of_nonneg_left _ hc.le
        simpa [dist_eq_norm] using hz
  have key := (convex_closedBall x ‖y - x‖).norm_image_sub_le_of_norm_hasFDerivWithin_le hR bound
    (Metric.mem_closedBall_self (norm_nonneg _))
    (show y ∈ Metric.closedBall x ‖y - x‖ by simp [dist_eq_norm])
  have hRx : R x = 0 := by simp [hRdef]
  rw [hRx, sub_zero] at key
  calc ‖R y‖ ≤ c * ‖y - x‖ * ‖y - x‖ := key
    _ = c * ‖‖y - x‖ ^ 2‖ := by rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]; ring

lemma sub_isBigO_of_tendsto {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {α : Type*}
    {l : Filter α} (x : E) (y : α → E) (s : α → ℝ) (d : E) (hs : ∀ᶠ a in l, s a ≠ 0)
    (hd : Tendsto (fun a => (s a)⁻¹ • (y a - x)) l (𝓝 d)) :
    (fun a => y a - x) =O[l] s := by
  have h1 : (fun a => (s a)⁻¹ • (y a - x)) =O[l] (fun _ => (1 : ℝ)) := hd.isBigO_one ℝ
  have h2 := (isBigO_refl s l).smul h1
  refine h2.congr' ?_ ?_
  · filter_upwards [hs] with a ha
    simp [smul_smul, ha]
  · simp

lemma first_order_limit {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {α : Type*}
    {l : Filter α} (g : E → ℝ) (x : E) (hg : DifferentiableAt ℝ g x) (y : α → E) (s : α → ℝ)
    (d : E) (hy : Tendsto y l (𝓝 x)) (hs : ∀ᶠ a in l, s a ≠ 0)
    (hd : Tendsto (fun a => (s a)⁻¹ • (y a - x)) l (𝓝 d)) :
    Tendsto (fun a => (g (y a) - g x) / s a) l (𝓝 (fderiv ℝ g x d)) := by
  have hO := sub_isBigO_of_tendsto x y s d hs hd
  have hlo := ((hasFDerivAt_iff_isLittleO.1 hg.hasFDerivAt).comp_tendsto hy).trans_isBigO hO
  have ht := hlo.tendsto_div_nhds_zero
  have hc : Tendsto (fun a => fderiv ℝ g x ((s a)⁻¹ • (y a - x))) l (𝓝 (fderiv ℝ g x d)) :=
    ((fderiv ℝ g x).continuous.tendsto d).comp hd
  have := ht.add hc
  rw [zero_add] at this
  refine this.congr' ?_
  filter_upwards [hs] with a ha
  simp only [Function.comp_apply, map_smul, smul_eq_mul]
  field_simp
  ring

lemma second_order_limit {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {α : Type*}
    {l : Filter α} (g : E → ℝ) (x : E) (hg : ContDiffAt ℝ 2 g x) (hstat : fderiv ℝ g x = 0)
    (y : α → E) (s : α → ℝ)
    (d : E) (hy : Tendsto y l (𝓝 x)) (hs : ∀ᶠ a in l, s a ≠ 0)
    (hd : Tendsto (fun a => (s a)⁻¹ • (y a - x)) l (𝓝 d)) :
    Tendsto (fun a => (g (y a) - g x) / s a ^ 2) l
      (𝓝 ((1 / 2) * fderiv ℝ (fderiv ℝ g) x d d)) := by
  set B := fderiv ℝ (fderiv ℝ g) x with hB
  have hO : (fun a => ‖y a - x‖ ^ 2) =O[l] (fun a => s a ^ 2) :=
    (sub_isBigO_of_tendsto x y s d hs hd).norm_left.pow 2
  have hlo := ((taylor_two_littleO g x hg).comp_tendsto hy).trans_isBigO hO
  have ht := hlo.tendsto_div_nhds_zero
  have hBc : Continuous (fun v : E => B v v) := by fun_prop
  have hc : Tendsto (fun a => (1 / 2) * B ((s a)⁻¹ • (y a - x)) ((s a)⁻¹ • (y a - x))) l
      (𝓝 ((1 / 2) * B d d)) :=
    tendsto_const_nhds.mul ((hBc.tendsto d).comp hd)
  have := ht.add hc
  rw [zero_add] at this
  refine this.congr' ?_
  filter_upwards [hs] with a ha
  simp only [Function.comp_apply, map_smul, smul_eq_mul, hstat, ← hB,
    zero_apply, smul_apply]
  field_simp
  ring

end Helpers

lemma lagrangian_contDiffAt {n m p : ℕ} (f₀ : EuclideanSpace ℝ (Fin n) → ℝ)
    (f : Fin m → EuclideanSpace ℝ (Fin n) → ℝ) (h : Fin p → EuclideanSpace ℝ (Fin n) → ℝ)
    (lam : Fin m → ℝ) (nu : Fin p → ℝ) (x : EuclideanSpace ℝ (Fin n))
    (hf₀ : ContDiffAt ℝ 2 f₀ x) (hf : ∀ i, ContDiffAt ℝ 2 (f i) x)
    (hh : ∀ j, ContDiffAt ℝ 2 (h j) x) :
    ContDiffAt ℝ 2 (lagrangian f₀ f h lam nu) x := by
  unfold lagrangian
  have h1 : ContDiffAt ℝ 2 (fun y => ∑ i, lam i * f i y) x :=
    ContDiffAt.sum fun i _ => contDiffAt_const.mul (hf i)
  have h2 : ContDiffAt ℝ 2 (fun y => ∑ j, nu j * h j y) x :=
    ContDiffAt.sum fun j _ => contDiffAt_const.mul (hh j)
  exact (hf₀.add h1).add h2

#print axioms taylor_two_littleO
#print axioms sub_isBigO_of_tendsto
#print axioms first_order_limit
#print axioms second_order_limit
#print axioms lagrangian_contDiffAt

/-- The second-order sufficient condition. Minimise `f₀` over the points of `ℝⁿ` with
`fᵢ ≤ 0` for every `i` and `hⱼ = 0` for every `j`, where the cost and every constraint have
continuous second derivatives near `x`. Suppose `x` passes the KKT test: it is allowed, the
prices `λᵢ` are zero or above, each `λᵢ fᵢ(x)` is zero (complementary slackness), and the
Lagrangian `L = f₀ + Σ λᵢ fᵢ + Σ νⱼ hⱼ` is flat at `x`. If the curvature `dᵀ ∇²L(x) d` of the
Lagrangian is strictly positive for every nonzero `d` in the critical cone, then `x` is a strict
local minimum: every other allowed point close enough to `x` has a strictly larger cost. -/
theorem second_order_sufficient_condition {n m p : ℕ} (f₀ : EuclideanSpace ℝ (Fin n) → ℝ)
    (f : Fin m → EuclideanSpace ℝ (Fin n) → ℝ) (h : Fin p → EuclideanSpace ℝ (Fin n) → ℝ)
    (x : EuclideanSpace ℝ (Fin n)) (lam : Fin m → ℝ) (nu : Fin p → ℝ)
    (hf₀ : ContDiffAt ℝ 2 f₀ x) (hf : ∀ i, ContDiffAt ℝ 2 (f i) x)
    (hh : ∀ j, ContDiffAt ℝ 2 (h j) x)
    (hx_ineq : ∀ i, f i x ≤ 0) (hx_eq : ∀ j, h j x = 0)
    (hlam : ∀ i, 0 ≤ lam i) (hslack : ∀ i, lam i * f i x = 0)
    (hstat : fderiv ℝ (lagrangian f₀ f h lam nu) x = 0)
    (hcurv : ∀ d ∈ criticalCone f h lam x, d ≠ 0 →
      0 < fderiv ℝ (fderiv ℝ (lagrangian f₀ f h lam nu)) x d d) :
    ∃ ε > 0, ∀ y, (∀ i, f i y ≤ 0) → (∀ j, h j y = 0) → y ≠ x → dist y x < ε →
      f₀ x < f₀ y := by
  classical
  have hLc := lagrangian_contDiffAt f₀ f h lam nu x hf₀ hf hh
  set L := lagrangian f₀ f h lam nu with hL
  by_contra H
  push Not at H
  choose y hyf hyh hyne hyd hyle using fun k : ℕ => H (1 / ((k : ℝ) + 1)) (by positivity)
  have hytend : Filter.Tendsto y Filter.atTop (nhds x) := by
    rw [tendsto_iff_dist_tendsto_zero]
    exact squeeze_zero (fun k => dist_nonneg) (fun k => (hyd k).le)
      tendsto_one_div_add_atTop_nhds_zero_nat
  have hu : ∀ k, ‖y k - x‖⁻¹ • (y k - x) ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1 := by
    intro k
    have : y k - x ≠ 0 := sub_ne_zero.2 (hyne k)
    simp [norm_smul, this]
  obtain ⟨d, hdS, φ, hφ, hdlim⟩ := (isCompact_sphere (0 : EuclideanSpace ℝ (Fin n)) 1).tendsto_subseq hu
  have hd0 : d ≠ 0 := by
    rintro rfl
    simp at hdS
  set z := y ∘ φ with hzdef
  have hz : Filter.Tendsto z Filter.atTop (nhds x) := hytend.comp hφ.tendsto_atTop
  set s : ℕ → ℝ := fun k => ‖z k - x‖ with hsdef
  have hs : ∀ᶠ k in Filter.atTop, s k ≠ 0 :=
    Filter.Eventually.of_forall fun k => by simp [s, z, sub_ne_zero.2 (hyne _)]
  have hd : Filter.Tendsto (fun k => (s k)⁻¹ • (z k - x)) Filter.atTop (nhds d) := hdlim
  have hdiff : ∀ g : EuclideanSpace ℝ (Fin n) → ℝ, ContDiffAt ℝ 2 g x → DifferentiableAt ℝ g x :=
    fun g hg => hg.differentiableAt (by simp)
  have lim1 : ∀ g : EuclideanSpace ℝ (Fin n) → ℝ, ContDiffAt ℝ 2 g x →
      Filter.Tendsto (fun k => (g (z k) - g x) / s k) Filter.atTop (nhds (fderiv ℝ g x d)) :=
    fun g hg => first_order_limit g x (hdiff g hg) z s d hz hs hd
  have hhd : ∀ j, fderiv ℝ (h j) x d = 0 := by
    intro j
    have := lim1 (h j) (hh j)
    have h0 : (fun k => (h j (z k) - h j x) / s k) = fun _ => 0 := by
      funext k
      simp [z, hyh, hx_eq]
    rw [h0] at this
    exact tendsto_nhds_unique this tendsto_const_nhds
  have hfd : ∀ i, f i x = 0 → fderiv ℝ (f i) x d ≤ 0 := by
    intro i hi
    refine le_of_tendsto (lim1 (f i) (hf i)) (Filter.Eventually.of_forall fun k => ?_)
    rw [hi, sub_zero]
    exact div_nonpos_of_nonpos_of_nonneg (hyf _ i) (norm_nonneg _)
  have hf0d : fderiv ℝ f₀ x d ≤ 0 := by
    refine le_of_tendsto (lim1 f₀ hf₀) (Filter.Eventually.of_forall fun k => ?_)
    exact div_nonpos_of_nonpos_of_nonneg (sub_nonpos.2 (hyle _)) (norm_nonneg _)
  have hsplit : ∀ k, (L (z k) - L x) / s k = (f₀ (z k) - f₀ x) / s k +
      ∑ i, lam i * ((f i (z k) - f i x) / s k) + ∑ j, nu j * ((h j (z k) - h j x) / s k) := by
    intro k
    simp only [hL, lagrangian, mul_div_assoc', ← Finset.sum_div, mul_sub, Finset.sum_sub_distrib]
    ring
  have hsumlim : Filter.Tendsto (fun k => (L (z k) - L x) / s k) Filter.atTop
      (nhds (fderiv ℝ f₀ x d + ∑ i, lam i * fderiv ℝ (f i) x d +
        ∑ j, nu j * fderiv ℝ (h j) x d)) := by
    have := ((lim1 f₀ hf₀).add (tendsto_finsetSum Finset.univ
      fun i _ => (lim1 (f i) (hf i)).const_mul (lam i))).add
      (tendsto_finsetSum Finset.univ fun j _ => (lim1 (h j) (hh j)).const_mul (nu j))
    exact this.congr fun k => (hsplit k).symm
  have hLlim := lim1 L hLc
  rw [hstat] at hLlim
  have htot := tendsto_nhds_unique hsumlim hLlim
  simp only [hhd, mul_zero, Finset.sum_const_zero, add_zero,
    zero_apply] at htot
  have hterm : ∀ i, lam i * fderiv ℝ (f i) x d ≤ 0 := by
    intro i
    by_cases hi : f i x = 0
    · exact mul_nonpos_of_nonneg_of_nonpos (hlam i) (hfd i hi)
    · have : lam i = 0 := (mul_eq_zero.1 (hslack i)).resolve_right hi
      simp [this]
  have hsum0 : ∑ i, lam i * fderiv ℝ (f i) x d = 0 := by
    have : ∑ i, lam i * fderiv ℝ (f i) x d ≤ 0 := Finset.sum_nonpos fun i _ => hterm i
    linarith
  have hterm0 := (Finset.sum_eq_zero_iff_of_nonpos fun i _ => hterm i).1 hsum0
  have hcone : d ∈ criticalCone f h lam x := by
    refine ⟨hhd, fun i hi hpos => ?_, fun i hi _ => hfd i hi⟩
    have := hterm0 i (Finset.mem_univ _)
    exact (mul_eq_zero.1 this).resolve_left hpos.ne'
  have hpos := hcurv d hcone hd0
  have h2 := second_order_limit L x hLc hstat z s d hz hs hd
  have hLx : L x = f₀ x := by
    simp [hL, lagrangian, hslack, hx_eq]
  have hle : ∀ k, (L (z k) - L x) / s k ^ 2 ≤ 0 := by
    intro k
    apply div_nonpos_of_nonpos_of_nonneg _ (sq_nonneg _)
    rw [hLx]
    have hs1 : ∑ i, lam i * f i (z k) ≤ 0 :=
      Finset.sum_nonpos fun i _ => mul_nonpos_of_nonneg_of_nonpos (hlam i) (hyf _ i)
    have hzk : L (z k) = f₀ (z k) + ∑ i, lam i * f i (z k) := by
      simp [hL, lagrangian, z, hyh]
    rw [hzk]
    have := hyle (φ k)
    simp only [z, Function.comp_apply] at hs1 ⊢
    linarith
  have := le_of_tendsto h2 (Filter.Eventually.of_forall hle)
  linarith

/-- The second-order necessary condition, in the case the card proves. Same problem and the same
smoothness. Suppose `x` is a local minimum of `f₀` among the allowed points, the gradients of the
active constraints (every `fᵢ` with `fᵢ(x) = 0`, and every `hⱼ`) are linearly independent (LICQ),
and `x` passes the KKT test with prices `λ`, `ν` in which every active inequality has a strictly
positive price. Then the curvature `dᵀ ∇²L(x) d` of the Lagrangian is zero or above for every `d`
in the critical cone. -/
theorem second_order_necessary_condition {n m p : ℕ} (f₀ : EuclideanSpace ℝ (Fin n) → ℝ)
    (f : Fin m → EuclideanSpace ℝ (Fin n) → ℝ) (h : Fin p → EuclideanSpace ℝ (Fin n) → ℝ)
    (x : EuclideanSpace ℝ (Fin n)) (lam : Fin m → ℝ) (nu : Fin p → ℝ)
    (hf₀ : ContDiffAt ℝ 2 f₀ x) (hf : ∀ i, ContDiffAt ℝ 2 (f i) x)
    (hh : ∀ j, ContDiffAt ℝ 2 (h j) x)
    (hmin : IsLocalMinOn f₀ {y | (∀ i, f i y ≤ 0) ∧ ∀ j, h j y = 0} x)
    (hx_ineq : ∀ i, f i x ≤ 0) (hx_eq : ∀ j, h j x = 0)
    (hlicq : LinearIndependent ℝ
      (Sum.elim (fun i : {i // f i x = 0} => fderiv ℝ (f i.1) x)
        (fun j : Fin p => fderiv ℝ (h j) x)))
    (hlam : ∀ i, 0 ≤ lam i) (hslack : ∀ i, lam i * f i x = 0)
    (hstat : fderiv ℝ (lagrangian f₀ f h lam nu) x = 0)
    (hpos : ∀ i, f i x = 0 → 0 < lam i) :
    ∀ d ∈ criticalCone f h lam x, 0 ≤ fderiv ℝ (fderiv ℝ (lagrangian f₀ f h lam nu)) x d d := by
  classical
  intro d hd
  obtain ⟨hdh, hdpos, -⟩ := hd
  have hLc := lagrangian_contDiffAt f₀ f h lam nu x hf₀ hf hh
  set L := lagrangian f₀ f h lam nu with hL
  let φ : ({i // f i x = 0} ⊕ Fin p) → EuclideanSpace ℝ (Fin n) → ℝ :=
    Sum.elim (fun i => f i.1) h
  let φ' : ({i // f i x = 0} ⊕ Fin p) → (EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ) :=
    Sum.elim (fun i : {i // f i x = 0} => fderiv ℝ (f i.1) x) (fun j : Fin p => fderiv ℝ (h j) x)
  let c : EuclideanSpace ℝ (Fin n) → ({i // f i x = 0} ⊕ Fin p) → ℝ := fun y k => φ k y
  let c' : EuclideanSpace ℝ (Fin n) →L[ℝ] (({i // f i x = 0} ⊕ Fin p) → ℝ) :=
    ContinuousLinearMap.pi φ'
  have hcs : HasStrictFDerivAt c c' x := by
    apply hasStrictFDerivAt_pi.2
    intro k
    cases k with
    | inl i => exact (hf i.1).hasStrictFDerivAt (by simp)
    | inr j => exact (hh j).hasStrictFDerivAt (by simp)
  have hsurj : c'.range = ⊤ := by
    by_contra hne
    obtain ⟨ψ, hψ0, hψ⟩ :=
      Submodule.exists_dual_map_eq_bot_of_lt_top (lt_top_iff_ne_top.2 hne) inferInstance
    have hψv : ∀ v, ψ (c' v) = 0 := by
      intro v
      have hmem : ψ (c' v) ∈ Submodule.map ψ (c' : EuclideanSpace ℝ (Fin n) →ₗ[ℝ] _).range :=
        Submodule.mem_map_of_mem ⟨v, rfl⟩
      rw [hψ] at hmem
      simpa using hmem
    set μ : ({i // f i x = 0} ⊕ Fin p) → ℝ := fun k => ψ (fun j => if k = j then 1 else 0)
      with hμ
    have hcomb : ∑ k, μ k • φ' k = 0 := by
      ext v
      have := hψv v
      rw [LinearMap.pi_apply_eq_sum_univ] at this
      simpa [c', hμ, mul_comm] using this
    have hμ0 := (Fintype.linearIndependent_iff.1 hlicq) μ hcomb
    apply hψ0
    apply LinearMap.ext
    intro w
    rw [LinearMap.pi_apply_eq_sum_univ, LinearMap.zero_apply]
    refine Finset.sum_eq_zero fun k _ => ?_
    rw [show ψ (fun j => if k = j then 1 else 0) = μ k from rfl, hμ0 k, smul_zero]
  have hdker : d ∈ c'.ker := by
    rw [LinearMap.mem_ker]
    funext k
    cases k with
    | inl i => exact hdpos i.1 i.2 (hpos i.1 i.2)
    | inr j => exact hdh j
  set dk : c'.ker := ⟨d, hdker⟩ with hdk
  set γ : ℝ → EuclideanSpace ℝ (Fin n) := fun t => hcs.implicitFunction c c' hsurj (c x) (t • dk)
    with hγ
  have hγ0 : γ 0 = x := by simp [hγ]
  have hγd : HasDerivAt γ d 0 := by
    have h1 := (hcs.to_implicitFunction hsurj).hasFDerivAt
    have h2 : HasDerivAt (fun t : ℝ => t • dk) dk 0 := by
      simpa using (hasDerivAt_id (0 : ℝ)).smul_const dk
    exact h1.comp_hasDerivAt_of_eq (0 : ℝ) h2 (by simp)
  have hceq : ∀ᶠ t in nhds (0 : ℝ), c (γ t) = c x := by
    have hmap := hcs.map_implicitFunction_eq hsurj
    have ht : Filter.Tendsto (fun t : ℝ => (c x, t • dk)) (nhds 0) (nhds (c x, 0)) := by
      refine tendsto_const_nhds.prodMk_nhds ?_
      have : Filter.Tendsto (fun t : ℝ => t • dk) (nhds 0) (nhds ((0 : ℝ) • dk)) :=
        ((continuous_id.smul continuous_const).tendsto (0 : ℝ))
      simpa using this
    exact ht.eventually hmap
  have hγcont : Filter.Tendsto γ (nhds 0) (nhds x) := by
    have := hγd.continuousAt.tendsto
    rwa [hγ0] at this
  have hineq : ∀ᶠ t in nhds (0 : ℝ), ∀ i, f i (γ t) ≤ 0 ∧ lam i * f i (γ t) = 0 := by
    refine Filter.eventually_all.2 fun i => ?_
    by_cases hi : f i x = 0
    · filter_upwards [hceq] with t ht
      have := congrFun ht (Sum.inl ⟨i, hi⟩)
      simp only [c, φ, Sum.elim_inl] at this
      rw [this, hi]
      simp
    · have hlt : f i x < 0 := lt_of_le_of_ne (hx_ineq i) hi
      have hl0 : lam i = 0 := (mul_eq_zero.1 (hslack i)).resolve_right hi
      have hcont : ContinuousAt (f i) x := (hf i).continuousAt
      filter_upwards [(hcont.tendsto.comp hγcont).eventually (gt_mem_nhds hlt)] with t ht
      exact ⟨ht.le, by simp [hl0]⟩
  have heq : ∀ᶠ t in nhds (0 : ℝ), ∀ j, h j (γ t) = 0 := by
    filter_upwards [hceq] with t ht j
    have := congrFun ht (Sum.inr j)
    simp only [c, φ, Sum.elim_inr] at this
    rw [this, hx_eq]
  have hmin' : ∀ᶠ t in nhds (0 : ℝ), f₀ x ≤ f₀ (γ t) := by
    have hS : Filter.Tendsto γ (nhds 0) (nhdsWithin x {y | (∀ i, f i y ≤ 0) ∧ ∀ j, h j y = 0}) :=
      tendsto_nhdsWithin_iff.2 ⟨hγcont, by
        filter_upwards [hineq, heq] with t h1 h2
        exact ⟨fun i => (h1 i).1, h2⟩⟩
    exact hS.eventually hmin
  have hLx : L x = f₀ x := by
    simp [hL, lagrangian, hslack, hx_eq]
  have hLge : ∀ᶠ t in nhds (0 : ℝ), 0 ≤ (L (γ t) - L x) / id t ^ 2 := by
    filter_upwards [hineq, heq, hmin'] with t h1 h2 h3
    have : L (γ t) = f₀ (γ t) := by
      simp [hL, lagrangian, h2, fun i => (h1 i).2]
    rw [this, hLx]
    exact div_nonneg (sub_nonneg.2 h3) (sq_nonneg _)
  have hd' : Filter.Tendsto (fun t : ℝ => (id t)⁻¹ • (γ t - x)) (nhdsWithin (0 : ℝ) {(0 : ℝ)}ᶜ) (nhds d) := by
    refine (hasDerivAt_iff_tendsto_slope.1 hγd).congr fun t => ?_
    simp [slope_def_module, hγ0]
  have hlim := second_order_limit (l := nhdsWithin (0 : ℝ) {(0 : ℝ)}ᶜ) L x hLc hstat γ id d
    (hγcont.mono_left nhdsWithin_le_nhds) (show ∀ᶠ t in nhdsWithin (0 : ℝ) {(0 : ℝ)}ᶜ, id t ≠ 0 from
      self_mem_nhdsWithin) hd'
  have := ge_of_tendsto hlim (hLge.filter_mono nhdsWithin_le_nhds)
  linarith

/-- The pipe's best point. Flow `q` (L/s) and delivered head `H` (m), neither below zero, with
`H + 0.000125 q² ≤ 60`. The choice `q = 400`, `H = 40` is allowed and delivers
`0.00981 · 400 · 40 = 156.96` kW, and no allowed choice delivers more. -/
theorem pipe_best_point :
    (0 : ℝ) ≤ 400 ∧ (0 : ℝ) ≤ 40 ∧ (40 : ℝ) + 1 / 8000 * 400 ^ 2 ≤ 60 ∧
      981 / 100000 * (400 : ℝ) * 40 = 3924 / 25 ∧
      ∀ q H : ℝ, 0 ≤ q → 0 ≤ H → H + 1 / 8000 * q ^ 2 ≤ 60 → 981 / 100000 * q * H ≤ 3924 / 25 := by
  refine ⟨by norm_num, by norm_num, by norm_num, by norm_num, ?_⟩
  intro q H hq hH hc
  have h1 : q * H ≤ q * (60 - 1 / 8000 * q ^ 2) := mul_le_mul_of_nonneg_left (by linarith) hq
  have h2 : 0 ≤ (q - 400) ^ 2 * (q + 800) := mul_nonneg (sq_nonneg _) (by linarith)
  nlinarith [h1, h2]

-- Constants as fractions: C = 0.00981 = 981/100000 kW per (L/s · m), r = 0.000125 = 1/8000.
-- Slope of power along the surface, C(60 - 3rq²), is zero at q = 400: 3 · (1/8000) · 400² = 60.
example : (3 : ℚ) * (1 / 8000) * 400 ^ 2 = 60 := by norm_num
-- Delivered head 60 - 20 = 40 m; friction 20 m, one third of the 60 m rating.
example : (60 : ℚ) - 1 / 8000 * 400 ^ 2 = 40 ∧ (1 / 8000 : ℚ) * 400 ^ 2 / 60 = 1 / 3 := by norm_num
-- Power 0.00981 · 400 · 40 = 156.96 = 3924/25 kW.
example : (981 / 100000 : ℚ) * 400 * 40 = 3924 / 25 := by norm_num
-- Gradients: ∇f₀ = (-C·40, -C·400) = (-0.3924, -3.924), ∇f₁ = (2r·400, 1) = (0.1, 1).
example : -(981 / 100000 : ℚ) * 40 = -981 / 2500 ∧ -(981 / 100000 : ℚ) * 400 = -981 / 250 ∧
    2 * (1 / 8000 : ℚ) * 400 = 1 / 10 := by norm_num
-- Multiplier λ = 3.924 = 981/250 from the H entry; the q entry checks: -0.3924 + 3.924 · 0.1 = 0.
example : (-981 / 250 : ℚ) + 981 / 250 * 1 = 0 ∧ (-981 / 2500 : ℚ) + 981 / 250 * (1 / 10) = 0 := by
  norm_num
-- Critical cone: 0.1 dq + dH = 0 holds for d = (10, -1).
example : (1 / 10 : ℚ) * 10 + (-1) = 0 := by norm_num
-- Across the surface: outward (10, 1) raises the pump-end head by 2 m; inward (-10, -1) lowers it
-- by 2 m and raises the cost -P by 3.924 · 2 = 7.848 = 981/125 kW at first order.
example : (1 / 10 : ℚ) * 10 + 1 = 2 ∧ (1 / 10 : ℚ) * (-10) + (-1) = -2 ∧
    (-981 / 2500 : ℚ) * (-10) + (-981 / 250) * (-1) = 981 / 125 := by norm_num
-- The cost's own curvature 2 · (-C) · 10 · (-1) = 0.1962, the bend's share
-- λ · 2r · 10² = 0.0981, total 0.2943 = 2943/10000 kW.
example : 2 * (-(981 / 100000 : ℚ)) * 10 * (-1) = 981 / 5000 ∧
    (981 / 250 : ℚ) * (2 * (1 / 8000)) * 10 ^ 2 = 981 / 10000 ∧
    (981 / 5000 : ℚ) + 981 / 10000 = 2943 / 10000 := by norm_num
-- The same number as dᵀWd with W = [[2rλ, -C], [-C, 0]] and d = (10, -1).
example : (2 * (1 / 8000) * (981 / 250) : ℚ) * 10 * 10 + 2 * (-(981 / 100000)) * 10 * (-1) +
    0 * (-1) * (-1) = 2943 / 10000 := by norm_num
-- The bend: acceleration a = (0, -2r · 10²) = (0, -0.025), and ∇f₀ · a = 0.0981.
example : -2 * (1 / 8000 : ℚ) * 10 ^ 2 = -1 / 40 ∧
    (-981 / 2500 : ℚ) * 0 + (-981 / 250) * (-1 / 40) = 981 / 10000 := by norm_num
-- Road 2: the second difference of f₀(q) = -C q (60 - q²/8000) at 390, 400, 410 is 0.2943.
example : (-(981 / 100000) * 390 * (60 - 390 ^ 2 / 8000) : ℚ)
    - 2 * (-(981 / 100000) * 400 * (60 - 400 ^ 2 / 8000))
    + (-(981 / 100000) * 410 * (60 - 410 ^ 2 / 8000)) = 2943 / 10000 := by norm_num
-- Road 3: the bordered Hessian with rows (0, 0.1, 1), (0.1, 0.000981, -0.00981),
-- (1, -0.00981, 0) has determinant -0.002943.
example : let a : ℚ := 0; let b : ℚ := 1 / 10; let c : ℚ := 1
    let e : ℚ := 981 / 1000000; let g : ℚ := -981 / 100000; let k : ℚ := 0
    a * (e * k - g * g) - b * (b * k - g * c) + c * (b * g - e * c) = -2943 / 1000000 := by
  norm_num
-- Mistake 1: the Hessian of f₀ = -P alone, [[0, -C], [-C, 0]], has determinant -C² < 0: a saddle.
example : (0 : ℚ) * 0 - (-(981 / 100000)) * (-(981 / 100000)) < 0 := by norm_num
-- Mistake 4: at q = 300 the surface head is 48.75 = 195/4 m, power still rises
-- (60 - 3r · 300² = 105/4 > 0), yet the curvature is positive, 0.220725 = 8829/40000.
example : (60 : ℚ) - 1 / 8000 * 300 ^ 2 = 195 / 4 ∧ (60 : ℚ) - 3 * (1 / 8000) * 300 ^ 2 = 105 / 4 ∧
    (2 * (1 / 8000) * (981 / 100000 * 300) : ℚ) * 10 * 10 +
      2 * (-(981 / 100000)) * 10 * (-(10 * (2 * (1 / 8000) * 300))) = 8829 / 40000 := by norm_num
-- The floors matter: q = H = -1000 meets the rating with 935 m to spare and gives 9810 kW.
example : (-1000 : ℚ) + 1 / 8000 * (-1000) ^ 2 - 60 = -935 ∧
    (981 / 100000 : ℚ) * (-1000) * (-1000) = 9810 := by norm_num

#print axioms second_order_sufficient_condition
#print axioms second_order_necessary_condition
#print axioms pipe_best_point
