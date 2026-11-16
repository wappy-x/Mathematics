-- Vorticity: taking the curl of the incompressible Navier-Stokes equations removes the pressure and leaves the vorticity equation Dω/Dt = (ω·∇)u + νΔω, the Burgers bell solves the bath plug's spin equation whenever its width obeys d(δ²)/dt = 4ν − aδ², and the steady swirl loses energy at ρΓ²a/(8π) per metre whatever the viscosity.
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Gaussian.FourierTransform
import Mathlib.Analysis.InnerProductSpace.PiL2

open Real MeasureTheory

/-! Space is `Fin 3 → ℝ`: a point `x` has coordinates `x 0`, `x 1`, `x 2`. A velocity field that
changes in time is a function `u : ℝ → Space → Space`, time first, and `u t x i` is its part along
axis `i`. A pressure field is a function `p : ℝ → Space → ℝ`. Derivatives are Mathlib's `fderiv` in
space and `deriv` in time; divergence, curl, the carrying term (u·∇) and the Laplacian are spelled
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

/-- The vorticity ω = ∇ × u, part `i`: ∂_{i+1} u_{i+2} − ∂_{i+2} u_{i+1}, the axes counted round
0, 1, 2 (so part 0 is ∂₁u₂ − ∂₂u₁, part 1 is ∂₂u₀ − ∂₀u₂, part 2 is ∂₀u₁ − ∂₁u₀). -/
noncomputable def vorticity (u : Space → Space) (x : Space) (i : Fin 3) : ℝ :=
  pd (i + 1) (fun y => u y (i + 2)) x - pd (i + 2) (fun y => u y (i + 1)) x

/-- Part `i` of the carrying term (v·∇)w: the field `v` times the slope of `w`, Σⱼ vⱼ ∂ⱼwᵢ.
With v = u, w = u it is the inertia term of Navier-Stokes; with v = u, w = ω it carries the spin;
with v = ω, w = u it is the stretching and tilting term (ω·∇)u. -/
noncomputable def carry (v w : Space → Space) (x : Space) (i : Fin 3) : ℝ :=
  ∑ j : Fin 3, v x j * pd j (fun y => w y i) x

lemma slice_pd {F : ℝ × Space → ℝ} (hF : Differentiable ℝ F) (j : Fin 3) (t : ℝ) (x : Space) :
    pd j (fun y => F (t, y)) x = fderiv ℝ F (t, x) (0, Pi.single j 1) := by
  have h := (hF (t, x)).hasFDerivAt.comp x ((hasFDerivAt_const t x).prodMk (hasFDerivAt_id x))
  unfold pd
  rw [show (fun y => F (t, y)) = F ∘ Prod.mk t from rfl, h.fderiv]
  simp

lemma slice_deriv {F : ℝ × Space → ℝ} (hF : Differentiable ℝ F) (t : ℝ) (x : Space) :
    deriv (fun s => F (s, x)) t = fderiv ℝ F (t, x) (1, 0) := by
  have h := (hF (t, x)).hasFDerivAt.comp_hasDerivAt t ((hasDerivAt_id t).prodMk (hasDerivAt_const t x))
  exact h.deriv

lemma fderiv_dir {F : ℝ × Space → ℝ} (hF : ContDiff ℝ 2 F) (v w q : ℝ × Space) :
    fderiv ℝ (fun q => fderiv ℝ F q v) q w = fderiv ℝ (fderiv ℝ F) q w v := by
  have hd : Differentiable ℝ (fderiv ℝ F) :=
    (hF.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  rw [fderiv_clm_apply (hd q) (differentiableAt_const v)]
  simp

lemma dir_comm {F : ℝ × Space → ℝ} (hF : ContDiff ℝ 2 F) (v w q : ℝ × Space) :
    fderiv ℝ (fun q => fderiv ℝ F q v) q w = fderiv ℝ (fun q => fderiv ℝ F q w) q v := by
  rw [fderiv_dir hF, fderiv_dir hF]
  exact (hF.contDiffAt.isSymmSndFDerivAt (by simp)) w v

lemma contDiff_dir {F : ℝ × Space → ℝ} {n : ℕ} (hF : ContDiff ℝ (n + 1) F) (v : ℝ × Space) :
    ContDiff ℝ n (fun q => fderiv ℝ F q v) :=
  (hF.fderiv_right (m := n) le_rfl).clm_apply contDiff_const

lemma curl_algebra (A : Fin 3 → Fin 3 → ℝ) (i : Fin 3) :
    ∑ l : Fin 3, (A l (i + 1) * A (i + 2) l - A l (i + 2) * A (i + 1) l)
      + ∑ j : Fin 3, (A (j + 2) (j + 1) - A (j + 1) (j + 2)) * A i j
      = (A (i + 2) (i + 1) - A (i + 1) (i + 2)) * ∑ l : Fin 3, A l l := by
  fin_cases i <;> simp [Fin.sum_univ_three] <;> ring

#print axioms slice_pd
#print axioms slice_deriv
#print axioms fderiv_dir
#print axioms dir_comm
#print axioms contDiff_dir
#print axioms curl_algebra

/-- The vorticity equation (the card's main claim, Step 1). Take water of constant density `ρ` and
kinematic viscosity `ν`, and a smooth incompressible flow `u` with pressure `p` solving
Navier-Stokes divided by ρ, gravity folded into the pressure:
∂u/∂t + (u·∇)u = −(1/ρ)∇p + νΔu. Smooth means: the velocity has two continuous derivatives in
space and time together, three when there is viscosity, and the pressure two. Then the pressure
drops out, and the vorticity ω = ∇ × u obeys
∂ω/∂t + (u·∇)ω = (ω·∇)u + νΔω, that is Dω/Dt = (ω·∇)u + νΔω, at every time and point.
With ν = 0 this is the vorticity form of the Euler equations. -/
theorem vorticity_equation (ρ ν : ℝ) (u : ℝ → Space → Space) (p : ℝ → Space → ℝ)
    (hu : ContDiff ℝ 2 (fun q : ℝ × Space => u q.1 q.2))
    (hu3 : ν ≠ 0 → ContDiff ℝ 3 (fun q : ℝ × Space => u q.1 q.2))
    (hp : ContDiff ℝ 2 (fun q : ℝ × Space => p q.1 q.2))
    (hdiv : ∀ t x, divergence (u t) x = 0)
    (hNS : ∀ t x (i : Fin 3),
      deriv (fun s => u s x i) t + carry (u t) (u t) x i
        = -(1 / ρ) * pd i (p t) x + ν * laplacian (fun y => u t y i) x) :
    ∀ t x (i : Fin 3),
      deriv (fun s => vorticity (u s) x i) t + carry (u t) (vorticity (u t)) x i
        = carry (vorticity (u t)) (u t) x i + ν * laplacian (fun y => vorticity (u t) y i) x := by
  intro t x i
  let U : Fin 3 → ℝ × Space → ℝ := fun k q => u q.1 q.2 k
  let P : ℝ × Space → ℝ := fun q => p q.1 q.2
  let E : Fin 3 → ℝ × Space := fun j => (0, Pi.single j 1)
  let e0 : ℝ × Space := (1, 0)
  have hU2 : ∀ k, ContDiff ℝ 2 (U k) := fun k => by
    have := (contDiff_apply (𝕜 := ℝ) (F' := fun _ : Fin 3 => ℝ) k).comp hu; exact this
  have hU1 : ∀ k, Differentiable ℝ (U k) := fun k => (hU2 k).differentiable (by norm_num)
  have hDU : ∀ k v, Differentiable ℝ (fun q => fderiv ℝ (U k) q v) := fun k v =>
    (contDiff_dir (n := 1) (hU2 k) v).differentiable (by norm_num)
  have hP1 : Differentiable ℝ P := hp.differentiable (by norm_num)
  have hDP : ∀ v, Differentiable ℝ (fun q => fderiv ℝ P q v) := fun v =>
    (contDiff_dir (n := 1) hp v).differentiable (by norm_num)
  let Lap : Fin 3 → ℝ × Space → ℝ := fun k q =>
    ∑ m : Fin 3, fderiv ℝ (fun q' => fderiv ℝ (U k) q' (E m)) q (E m)
  -- Navier-Stokes as an identity of functions on space-time
  have hNS' : ∀ k, (fun q => fderiv ℝ (U k) q e0 + ∑ l : Fin 3, U l q * fderiv ℝ (U k) q (E l))
      = fun q => -(1 / ρ) * fderiv ℝ P q (E k) + ν * Lap k q := by
    intro k; funext q
    have h := hNS q.1 q.2 k
    have e1 : deriv (fun s => u s q.2 k) q.1 = fderiv ℝ (U k) q e0 := slice_deriv (hU1 k) q.1 q.2
    have e2 : ∀ l, pd l (fun y => u q.1 y k) q.2 = fderiv ℝ (U k) q (E l) := fun l =>
      slice_pd (hU1 k) l q.1 q.2
    have e3 : pd k (p q.1) q.2 = fderiv ℝ P q (E k) := slice_pd hP1 k q.1 q.2
    have e4 : laplacian (fun y => u q.1 y k) q.2 = Lap k q := by
      unfold laplacian
      refine Finset.sum_congr rfl fun m _ => ?_
      have : pd m (fun y => u q.1 y k) = fun y => fderiv ℝ (U k) (q.1, y) (E m) :=
        funext fun y => slice_pd (hU1 k) m q.1 y
      rw [this]
      exact slice_pd (hDU k (E m)) m q.1 q.2
    unfold carry at h
    rw [e1, e3, e4] at h
    simp only [e2] at h
    exact h
  have hL : ∀ k v, fderiv ℝ (fun q => fderiv ℝ (U k) q e0
        + ∑ l : Fin 3, U l q * fderiv ℝ (U k) q (E l)) (t, x) v
      = fderiv ℝ (fun q => fderiv ℝ (U k) q e0) (t, x) v
        + ∑ l : Fin 3, (fderiv ℝ (U l) (t, x) v * fderiv ℝ (U k) (t, x) (E l)
          + U l (t, x) * fderiv ℝ (fun q => fderiv ℝ (U k) q (E l)) (t, x) v) := by
    intro k v
    have hprod : ∀ l, Differentiable ℝ (fun q => U l q * fderiv ℝ (U k) q (E l)) := fun l =>
      (hU1 l).mul (hDU k (E l))
    rw [fderiv_fun_add (hDU k e0 (t, x)) (Differentiable.fun_sum (fun l _ => hprod l) (t, x)),
      fderiv_fun_sum (fun l _ => hprod l (t, x))]
    simp only [ContinuousLinearMap.add_apply, ContinuousLinearMap.sum_apply]
    congr 1
    refine Finset.sum_congr rfl fun l _ => ?_
    rw [fderiv_fun_mul (hU1 l (t, x)) (hDU k (E l) (t, x))]
    simp only [ContinuousLinearMap.add_apply, ContinuousLinearMap.smul_apply, smul_eq_mul]
    ring
  have hR : ∀ k v, fderiv ℝ (fun q => -(1 / ρ) * fderiv ℝ P q (E k) + ν * Lap k q) (t, x) v
      = -(1 / ρ) * fderiv ℝ (fun q => fderiv ℝ P q (E k)) (t, x) v + ν * fderiv ℝ (Lap k) (t, x) v := by
    intro k v
    rcases eq_or_ne ν 0 with h0 | h0
    · subst h0
      simp only [zero_mul, add_zero]
      rw [fderiv_const_mul (hDP _ (t, x))]
      simp
    · have hU3 : ∀ k, ContDiff ℝ 3 (U k) := fun k => by
        have := (contDiff_apply (𝕜 := ℝ) (F' := fun _ : Fin 3 => ℝ) k).comp (hu3 h0); exact this
      have hLap : Differentiable ℝ (Lap k) := Differentiable.fun_sum fun m _ =>
        (contDiff_dir (n := 1) (contDiff_dir (n := 2) (hU3 k) (E m)) (E m)).differentiable
          (by norm_num)
      rw [fderiv_fun_add ((hDP _ (t, x)).const_mul _) ((hLap (t, x)).const_mul _),
        fderiv_const_mul (hDP _ (t, x)), fderiv_const_mul (hLap (t, x))]
      simp
  have hD : ∀ k v, fderiv ℝ (fun q => fderiv ℝ (U k) q e0) (t, x) v
        + ∑ l : Fin 3, (fderiv ℝ (U l) (t, x) v * fderiv ℝ (U k) (t, x) (E l)
          + U l (t, x) * fderiv ℝ (fun q => fderiv ℝ (U k) q (E l)) (t, x) v)
      = -(1 / ρ) * fderiv ℝ (fun q => fderiv ℝ P q (E k)) (t, x) v
        + ν * fderiv ℝ (Lap k) (t, x) v := by
    intro k v; rw [← hL, ← hR, hNS' k]
  have h2 := hD (i + 2) (E (i + 1))
  have h1 := hD (i + 1) (E (i + 2))
  have hPs : fderiv ℝ (fun q => fderiv ℝ P q (E (i + 2))) (t, x) (E (i + 1))
      = fderiv ℝ (fun q => fderiv ℝ P q (E (i + 1))) (t, x) (E (i + 2)) := dir_comm hp _ _ _
  -- the vorticity, written on space-time
  let W : Fin 3 → ℝ × Space → ℝ := fun j q =>
    fderiv ℝ (U (j + 2)) q (E (j + 1)) - fderiv ℝ (U (j + 1)) q (E (j + 2))
  have hW : ∀ j, Differentiable ℝ (W j) := fun j => (hDU _ _).sub (hDU _ _)
  have hWv : ∀ s y j, vorticity (u s) y j = W j (s, y) := by
    intro s y j
    exact congrArg₂ (· - ·) (slice_pd (hU1 (j + 2)) (j + 1) s y)
      (slice_pd (hU1 (j + 1)) (j + 2) s y)
  have hT : deriv (fun s => vorticity (u s) x i) t
      = fderiv ℝ (fun q => fderiv ℝ (U (i + 2)) q e0) (t, x) (E (i + 1))
        - fderiv ℝ (fun q => fderiv ℝ (U (i + 1)) q e0) (t, x) (E (i + 2)) := by
    simp only [hWv]
    rw [slice_deriv (hW i) t x]
    simp only [W]
    rw [fderiv_fun_sub (hDU _ _ _) (hDU _ _ _)]
    simp only [ContinuousLinearMap.sub_apply]
    rw [dir_comm (hU2 _) (E (i + 1)) e0, dir_comm (hU2 _) (E (i + 2)) e0]
  have hC1 : carry (u t) (vorticity (u t)) x i
      = ∑ j : Fin 3, U j (t, x) * (fderiv ℝ (fun q => fderiv ℝ (U (i + 2)) q (E j)) (t, x) (E (i + 1))
          - fderiv ℝ (fun q => fderiv ℝ (U (i + 1)) q (E j)) (t, x) (E (i + 2))) := by
    unfold carry
    refine Finset.sum_congr rfl fun j _ => ?_
    have : pd j (fun y => vorticity (u t) y i) x = fderiv ℝ (W i) (t, x) (E j) := by
      simp only [hWv]; exact slice_pd (hW i) j t x
    rw [this]
    simp only [W]
    rw [fderiv_fun_sub (hDU _ _ _) (hDU _ _ _)]
    simp only [ContinuousLinearMap.sub_apply]
    rw [dir_comm (hU2 _) (E (i + 1)) (E j), dir_comm (hU2 _) (E (i + 2)) (E j)]
  have hC2 : carry (vorticity (u t)) (u t) x i
      = ∑ j : Fin 3, (fderiv ℝ (U (j + 2)) (t, x) (E (j + 1))
          - fderiv ℝ (U (j + 1)) (t, x) (E (j + 2))) * fderiv ℝ (U i) (t, x) (E j) := by
    unfold carry
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [hWv]
    exact congrArg _ (slice_pd (hU1 i) j t x)
  have hdiv' : ∑ l : Fin 3, fderiv ℝ (U l) (t, x) (E l) = 0 := by
    rw [← hdiv t x]
    unfold divergence
    exact Finset.sum_congr rfl fun l _ => (slice_pd (hU1 l) l t x).symm
  -- the viscous part
  have hV : ν * (fderiv ℝ (Lap (i + 2)) (t, x) (E (i + 1)) - fderiv ℝ (Lap (i + 1)) (t, x) (E (i + 2)))
      = ν * laplacian (fun y => vorticity (u t) y i) x := by
    rcases eq_or_ne ν 0 with h0 | h0
    · simp [h0]
    congr 1
    have hU3 : ∀ k, ContDiff ℝ 3 (U k) := fun k => by
      have := (contDiff_apply (𝕜 := ℝ) (F' := fun _ : Fin 3 => ℝ) k).comp (hu3 h0); exact this
    have hDU2 : ∀ k v, ContDiff ℝ 2 (fun q => fderiv ℝ (U k) q v) := fun k v =>
      contDiff_dir (n := 2) (hU3 k) v
    have hDDU : ∀ k v w, Differentiable ℝ (fun q => fderiv ℝ (fun q' => fderiv ℝ (U k) q' v) q w) :=
      fun k v w => (contDiff_dir (n := 1) (hDU2 k v) w).differentiable (by norm_num)
    have hLapD : ∀ k v, fderiv ℝ (Lap k) (t, x) v
        = ∑ m : Fin 3, fderiv ℝ (fun q => fderiv ℝ (fun q' => fderiv ℝ (U k) q' v) q (E m)) (t, x) (E m) := by
      intro k v
      simp only [Lap]
      rw [fderiv_fun_sum (fun m _ => hDDU k (E m) (E m) _)]
      simp only [ContinuousLinearMap.sum_apply]
      refine Finset.sum_congr rfl fun m _ => ?_
      rw [dir_comm (hDU2 k (E m)) (E m) v,
        show (fun q => fderiv ℝ (fun q' => fderiv ℝ (U k) q' (E m)) q v)
          = (fun q => fderiv ℝ (fun q' => fderiv ℝ (U k) q' v) q (E m)) from
          funext fun q => dir_comm (hU2 k) (E m) v q]
    have hWm : ∀ m, (fun q => fderiv ℝ (W i) q (E m))
        = fun q => fderiv ℝ (fun q' => fderiv ℝ (U (i + 2)) q' (E (i + 1))) q (E m)
          - fderiv ℝ (fun q' => fderiv ℝ (U (i + 1)) q' (E (i + 2))) q (E m) := by
      intro m; funext q
      simp only [W]
      rw [fderiv_fun_sub (hDU _ _ _) (hDU _ _ _)]
      rfl
    have hWD : ∀ m, Differentiable ℝ (fun q => fderiv ℝ (W i) q (E m)) := by
      intro m; rw [hWm m]; exact (hDDU _ _ _).sub (hDDU _ _ _)
    rw [show (fun y => vorticity (u t) y i) = fun y => W i (t, y) from funext fun y => hWv t y i]
    unfold laplacian
    have hW2 : ∀ m, pd m (fun y => W i (t, y)) = fun y => fderiv ℝ (W i) (t, y) (E m) :=
      fun m => funext fun y => slice_pd (hW i) m t y
    simp only [hW2]
    rw [Finset.sum_congr rfl fun m _ => slice_pd (hWD m) m t x, hLapD, hLapD,
      ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun m _ => ?_
    rw [hWm m, fderiv_fun_sub (hDDU _ _ _ _) (hDDU _ _ _ _)]
    simp only [ContinuousLinearMap.sub_apply]
    rfl
  rw [hT, hC1, hC2, ← hV]
  have halg := curl_algebra (fun k l => fderiv ℝ (U k) (t, x) (E l)) i
  simp only [Fin.sum_univ_three] at h1 h2 halg hdiv' ⊢
  linear_combination h2 - h1 - halg
    - (fderiv ℝ (U (i + 2)) (t, x) (E (i + 1)) - fderiv ℝ (U (i + 1)) (t, x) (E (i + 2))) * hdiv'
    - (1 / ρ) * hPs

/-- The Burgers bell: vorticity Γ/(π s) · e^(−r²/s) at distance `r` from the swirl's axis, where
`s = δ²` is the square of the core radius and `Γ` the circulation. -/
noncomputable def bell (Γ s r : ℝ) : ℝ :=
  Γ / (π * s) * exp (-r ^ 2 / s)

/-- The bath plug, solved exactly (Step 4). With stretching rate `a`, viscosity `ν` and
circulation `Γ`, let the squared core radius s(t) = δ(t)² stay positive and obey
d(δ²)/dt = 4ν − aδ². Then the bell ω(r, t) = Γ/(πδ²) e^(−r²/δ²) solves the bath's spin equation
∂ω/∂t = (ar/2) ∂ω/∂r + aω + ν(∂²ω/∂r² + (1/r) ∂ω/∂r) at every time and every distance r > 0
from the axis: inflow, stretching and spreading. -/
theorem burgers_vortex_solves_bath_equation (Γ a ν : ℝ) (s : ℝ → ℝ)
    (hs : ∀ t, HasDerivAt s (4 * ν - a * s t) t) (hpos : ∀ t, 0 < s t) :
    ∀ t r, 0 < r →
      deriv (fun τ => bell Γ (s τ) r) t
        = a * r / 2 * deriv (fun y => bell Γ (s t) y) r + a * bell Γ (s t) r
          + ν * (deriv (deriv (fun y => bell Γ (s t) y)) r
                 + (1 / r) * deriv (fun y => bell Γ (s t) y) r) := by
  intro t r hr
  have hs0 : s t ≠ 0 := (hpos t).ne'
  have hπ : π ≠ 0 := Real.pi_pos.ne'
  unfold bell
  have hq : ∀ y, HasDerivAt (fun y => -y ^ 2 / s t) (-(2 * y) / s t) y := by
    intro y
    have := ((hasDerivAt_pow 2 y).neg).div_const (s t)
    convert this using 1
    · push_cast; ring
  have hd1 : deriv (fun y => Γ / (π * s t) * exp (-y ^ 2 / s t))
      = fun y => Γ / (π * s t) * (exp (-y ^ 2 / s t) * (-(2 * y) / s t)) :=
    funext fun y => ((hq y).exp.const_mul _).deriv
  have hlin : HasDerivAt (fun y => -(2 * y) / s t) (-2 / s t) r := by
    have : HasDerivAt (fun y => -(2 * y) / s t) (-(2 * 1) / s t) r :=
      (((hasDerivAt_id r).const_mul 2).neg).div_const (s t)
    rwa [mul_one] at this
  have hd2 : deriv (fun y => Γ / (π * s t) * (exp (-y ^ 2 / s t) * (-(2 * y) / s t))) r
      = Γ / (π * s t) * (exp (-r ^ 2 / s t) * (-(2 * r) / s t) * (-(2 * r) / s t)
        + exp (-r ^ 2 / s t) * (-2 / s t)) :=
    (((hq r).exp.mul hlin).const_mul (Γ / (π * s t))).deriv
  have ht : HasDerivAt (fun τ => Γ / (π * s τ) * exp (-r ^ 2 / s τ))
      ((0 * (π * s t) - Γ * (π * (4 * ν - a * s t))) / (π * s t) ^ 2 * exp (-r ^ 2 / s t)
        + Γ / (π * s t) * (exp (-r ^ 2 / s t)
          * ((0 * s t - -r ^ 2 * (4 * ν - a * s t)) / s t ^ 2))) t := by
    have h1 := (hasDerivAt_const t Γ).div ((hs t).const_mul π) (mul_ne_zero hπ hs0)
    have h2 := ((hasDerivAt_const t (-r ^ 2)).div (hs t) hs0).exp
    exact h1.mul h2
  rw [ht.deriv, hd1, hd2]
  field_simp
  ring


/-- The zero-viscosity limit does not stop the loss (Step 5). For water of density `ρ`, any
viscosity `ν > 0`, stretching rate `a > 0` and circulation `Γ`, the steady bath swirl has core
δ² = 4ν/a, and it loses energy to viscosity at ρν ∫ ω² dA = ρΓ²a/(8π) per metre of its length,
the integral over the whole plane: the viscosity cancels. -/
theorem steady_swirl_energy_loss (ρ Γ a ν : ℝ) (ha : 0 < a) (hν : 0 < ν) :
    ρ * ν * ∫ x : EuclideanSpace ℝ (Fin 2), bell Γ (4 * ν / a) ‖x‖ ^ 2
      = ρ * Γ ^ 2 * a / (8 * π) := by
  have hs : 0 < 4 * ν / a := by positivity
  have h : ∀ x : EuclideanSpace ℝ (Fin 2), bell Γ (4 * ν / a) ‖x‖ ^ 2
      = (Γ / (π * (4 * ν / a))) ^ 2 * exp (-(2 / (4 * ν / a)) * ‖x‖ ^ 2) := by
    intro x
    unfold bell
    rw [mul_pow, ← Real.exp_nat_mul]
    congr 2
    push_cast
    ring
  simp_rw [h]
  rw [integral_const_mul, GaussianFourier.integral_rexp_neg_mul_sq_norm (by positivity)]
  simp [finrank_euclideanSpace]
  field_simp
  ring

-- Worked numbers by hand, exactly: water ν = 10⁻⁶ m²/s, a = 0.04 = 4/100 1/s, Γ = 0.01 = 1/100 m²/s.
-- Core width squared 4ν/a = 10⁻⁴ m², so the core radius is 10 mm.
example : (4 : ℚ) * (1 / 10 ^ 6) / (4 / 100) = 1 / 10 ^ 4 := by norm_num
-- Peak vorticity Γ/(πδ²) = 100/π 1/s (the card's 31.83 1/s).
example : (1 / 100 : ℝ) / (π * (1 / 10 ^ 4)) = 100 / π := by
  field_simp; norm_num
-- On the axis, stretching aω₀ equals spreading ν · 4ω₀/δ²: both are 4/π 1/s² (the card's 1.2732).
example : (4 / 100 : ℝ) * (100 / π) = (1 / 10 ^ 6) * (4 * (100 / π) / (1 / 10 ^ 4)) := by
  field_simp; norm_num
-- Energy lost ρΓ²a/(8π) with ρ = 1000 kg/m³: 1/(2000π) W per metre (the card's 1.592e-04).
example : (1000 : ℝ) * (1 / 100) ^ 2 * (4 / 100) / (8 * π) = 1 / (2000 * π) := by
  field_simp; norm_num
-- Smoke ring, circulation 0.075 m²/s, core 5 mm: core vorticity Γ/(πc²) = 3000/π 1/s (954.9);
-- widened to radius 100 mm with core c² halved, it doubles to 6000/π 1/s (1909.9).
example : (75 / 1000 : ℝ) / (π * (5 / 1000) ^ 2) = 3000 / π := by
  field_simp; norm_num
example : (75 / 1000 : ℝ) / (π * ((5 / 1000) ^ 2 / 2)) = 2 * (3000 / π) := by
  field_simp; norm_num
-- Its core volume 2πR · πc² is the same at R = 50 mm, c² = 25 mm² and R = 100 mm, c² = 12.5 mm².
example : 2 * π * (50 / 1000) * (π * (25 / 10 ^ 6)) = 2 * π * (100 / 1000) * (π * (25 / 2 / 10 ^ 6)) := by
  ring

#print axioms vorticity_equation
#print axioms burgers_vortex_solves_bath_equation
#print axioms steady_swirl_energy_loss
