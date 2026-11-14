-- Electromagnetic waves: in empty space, twice continuously differentiable fields that obey Maxwell's four vacuum equations make the electric field obey the wave equation with speed c = 1/√(μ₀ε₀), and the plane wave E₀ ŷ cos(kx − ωt), (E₀/c) ẑ cos(kx − ωt) with λ = c/f is one such pair of fields.
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

open Real

/-! Space is `Fin 3 → ℝ`: a point `p` has coordinates `p 0 = x`, `p 1 = y`, `p 2 = z`. A vector
field on space is a function `Space → Space`; a field that also changes in time is a function
`ℝ → Space → Space`, time first. The fields are written with Mathlib's derivative `fderiv` in space
and `deriv` in time; curl, divergence, gradient and Laplacian are spelled out component by component,
exactly as on the card. -/

/-- Points of space, and vectors at a point. -/
abbrev Space := Fin 3 → ℝ

/-- The rate of change of a quantity `f` on space along axis `i` at the point `p`: ∂f/∂xᵢ. -/
noncomputable def pd (i : Fin 3) (f : Space → ℝ) (p : Space) : ℝ :=
  fderiv ℝ f p (Pi.single i 1)

/-- Divergence (net outflow): ∇·F = ∂Fx/∂x + ∂Fy/∂y + ∂Fz/∂z. -/
noncomputable def divergence (F : Space → Space) (p : Space) : ℝ :=
  pd 0 (fun q => F q 0) p + pd 1 (fun q => F q 1) p + pd 2 (fun q => F q 2) p

/-- Curl (spin): ∇×F = (∂Fz/∂y − ∂Fy/∂z, ∂Fx/∂z − ∂Fz/∂x, ∂Fy/∂x − ∂Fx/∂y). -/
noncomputable def curl (F : Space → Space) (p : Space) : Space :=
  ![pd 1 (fun q => F q 2) p - pd 2 (fun q => F q 1) p,
    pd 2 (fun q => F q 0) p - pd 0 (fun q => F q 2) p,
    pd 0 (fun q => F q 1) p - pd 1 (fun q => F q 0) p]

/-- Gradient (steepest rise): ∇f = (∂f/∂x, ∂f/∂y, ∂f/∂z). -/
noncomputable def grad (f : Space → ℝ) (p : Space) : Space :=
  ![pd 0 f p, pd 1 f p, pd 2 f p]

/-- Laplacian (bending) of a vector field, component by component:
(∇²F)ⱼ = ∂²Fⱼ/∂x² + ∂²Fⱼ/∂y² + ∂²Fⱼ/∂z². -/
noncomputable def vecLaplacian (F : Space → Space) (p : Space) : Space :=
  fun j => pd 0 (pd 0 (fun q => F q j)) p + pd 1 (pd 1 (fun q => F q j)) p +
    pd 2 (pd 2 (fun q => F q j)) p

/-- The rate of change in time at one fixed point: ∂F/∂t at time `t` and point `p`. -/
noncomputable def timeD (F : ℝ → Space → Space) (t : ℝ) (p : Space) : Space :=
  deriv (fun s => F s p) t

section em_helpers

variable {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]

lemma em_contDiff_fderiv_apply {f : V → ℝ} (hf : ContDiff ℝ 2 f) (v : V) :
    ContDiff ℝ 1 (fun y => fderiv ℝ f y v) :=
  (hf.fderiv_right (m := 1) (by norm_num)).clm_apply contDiff_const

lemma em_fderiv_fderiv_apply {f : V → ℝ} (hf : ContDiff ℝ 2 f) (v w x : V) :
    fderiv ℝ (fun y => fderiv ℝ f y v) x w = fderiv ℝ (fderiv ℝ f) x w v := by
  have h1 : DifferentiableAt ℝ (fderiv ℝ f) x :=
    ((hf.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)) x
  rw [fderiv_clm_apply h1 (differentiableAt_const v)]
  simp

lemma em_symm {f : V → ℝ} (hf : ContDiff ℝ 2 f) (v w x : V) :
    fderiv ℝ (fderiv ℝ f) x w v = fderiv ℝ (fderiv ℝ f) x v w :=
  (hf.contDiffAt.isSymmSndFDerivAt (by simp)) w v

end em_helpers

lemma em_pd_sub {f g : Space → ℝ} {p : Space} (hf : DifferentiableAt ℝ f p)
    (hg : DifferentiableAt ℝ g p) (i : Fin 3) :
    pd i (fun q => f q - g q) p = pd i f p - pd i g p := by
  simp only [pd]
  rw [show (fun q => f q - g q) = f - g from rfl, (hf.hasFDerivAt.sub hg.hasFDerivAt).fderiv]
  simp

lemma em_pd_add3 {f g h : Space → ℝ} {p : Space} (hf : DifferentiableAt ℝ f p)
    (hg : DifferentiableAt ℝ g p) (hh : DifferentiableAt ℝ h p) (i : Fin 3) :
    pd i (fun q => f q + g q + h q) p = pd i f p + pd i g p + pd i h p := by
  simp only [pd]
  rw [show (fun q => f q + g q + h q) = f + g + h from rfl, ((hf.hasFDerivAt.add hg.hasFDerivAt).add hh.hasFDerivAt).fderiv]
  simp

lemma em_pd_neg (f : Space → ℝ) (p : Space) (i : Fin 3) :
    pd i (fun q => -f q) p = -pd i f p := by
  simp [pd]

lemma em_pd_const (a : ℝ) (p : Space) (i : Fin 3) : pd i (fun _ => a) p = 0 := by
  simp [pd]

lemma em_pd_diff {f : Space → ℝ} (hf : ContDiff ℝ 2 f) (i : Fin 3) :
    Differentiable ℝ (pd i f) :=
  (em_contDiff_fderiv_apply hf _).differentiable (by norm_num)

lemma em_pd_comm {f : Space → ℝ} (hf : ContDiff ℝ 2 f) (i j : Fin 3) (p : Space) :
    pd i (pd j f) p = pd j (pd i f) p := by
  show fderiv ℝ (fun y => fderiv ℝ f y (Pi.single j 1)) p (Pi.single i 1) =
    fderiv ℝ (fun y => fderiv ℝ f y (Pi.single i 1)) p (Pi.single j 1)
  rw [em_fderiv_fderiv_apply hf, em_fderiv_fderiv_apply hf, em_symm hf]

lemma em_pd_slice {H : ℝ × Space → ℝ} {s : ℝ} {p : Space} (hH : DifferentiableAt ℝ H (s, p))
    (i : Fin 3) : pd i (fun q => H (s, q)) p = fderiv ℝ H (s, p) (0, Pi.single i 1) := by
  have h := hH.hasFDerivAt.comp p ((hasFDerivAt_const s p).prodMk (hasFDerivAt_id p))
  simp only [pd]
  rw [show (fun q => H (s, q)) = H ∘ (fun q => (s, q)) from rfl, h.fderiv]
  simp

lemma em_deriv_slice {H : ℝ × Space → ℝ} {s : ℝ} {q : Space} (hH : DifferentiableAt ℝ H (s, q)) :
    HasDerivAt (fun s => H (s, q)) (fderiv ℝ H (s, q) (1, 0)) s :=
  hH.hasFDerivAt.comp_hasDerivAt s ((hasDerivAt_id' s).prodMk (hasDerivAt_const s q))

lemma em_mixed {G : ℝ × Space → ℝ} (hG : ContDiff ℝ 2 G) (i : Fin 3) (t : ℝ) (p : Space) :
    HasDerivAt (fun s => pd i (fun q => G (s, q)) p)
      (pd i (fun q => deriv (fun s => G (s, q)) t) p) t := by
  have hd : Differentiable ℝ G := hG.differentiable (by norm_num)
  have hC1 : ∀ v, Differentiable ℝ (fun x => fderiv ℝ G x v) := fun v =>
    (em_contDiff_fderiv_apply hG v).differentiable (by norm_num)
  have e1 : (fun s => pd i (fun q => G (s, q)) p) =
      fun s => (fun x => fderiv ℝ G x (0, Pi.single i 1)) (s, p) := by
    funext s; exact em_pd_slice (hd _) i
  have e2 : (fun q => deriv (fun s => G (s, q)) t) =
      fun q => (fun x => fderiv ℝ G x (1, 0)) (t, q) := by
    funext q; exact (em_deriv_slice (hd _)).deriv
  have key := em_deriv_slice (H := fun x => fderiv ℝ G x (0, Pi.single i 1)) (hC1 _ (t, p))
  rw [e1, e2, em_pd_slice (hC1 _ _)]
  convert key using 1
  rw [em_fderiv_fderiv_apply hG, em_fderiv_fderiv_apply hG, em_symm hG]

lemma em_timeD_apply {X : ℝ → Space → Space}
    (hX : ContDiff ℝ 2 (fun q : ℝ × Space => X q.1 q.2)) (t : ℝ) (q : Space) (j : Fin 3) :
    timeD X t q j = deriv (fun s => X s q j) t := by
  have hd : DifferentiableAt ℝ (fun s => X s q) t :=
    DifferentiableAt.comp (g := fun q : ℝ × Space => X q.1 q.2) (f := fun s => (s, q)) t
      ((hX.differentiable (by norm_num)) (t, q))
      (differentiableAt_id.prodMk (differentiableAt_const q))
  exact ((hasDerivAt_pi.mp hd.hasDerivAt) j).deriv.symm

lemma em_curl_neg (X : Space → Space) (p : Space) : curl (fun q => -X q) p = -curl X p := by
  ext j; fin_cases j <;> simp [curl, em_pd_neg] <;> ring

lemma em_pd_wave (A k ω t : ℝ) (i : Fin 3) (p : Space) :
    pd i (fun q => A * cos (k * q 0 - ω * t)) p =
      -(A * k * sin (k * p 0 - ω * t)) * (Pi.single i (1 : ℝ) : Space) 0 := by
  have hg : HasDerivAt (fun x => A * cos (k * x - ω * t)) (-(A * k * sin (k * p 0 - ω * t))) (p 0) := by
    have := (HasDerivAt.cos (((hasDerivAt_id' (p 0)).const_mul k).sub_const (ω * t))).const_mul A
    convert this using 1; ring
  have h := hg.comp_hasFDerivAt p (hasFDerivAt_apply (𝕜 := ℝ) (F' := fun _ : Fin 3 => ℝ) 0 p)
  simp only [pd]
  rw [show (fun q : Space => A * cos (k * q 0 - ω * t)) =
    (fun x => A * cos (k * x - ω * t)) ∘ (fun f : Space => f 0) from rfl, h.fderiv]
  simp

lemma em_hasDerivAt_wave (A k ω x t : ℝ) :
    HasDerivAt (fun s => A * cos (k * x - ω * s)) (A * ω * sin (k * x - ω * t)) t := by
  have := (HasDerivAt.cos (((hasDerivAt_id' t).const_mul ω).const_sub (k * x))).const_mul A
  convert this using 1; ring

#print axioms em_contDiff_fderiv_apply
#print axioms em_fderiv_fderiv_apply
#print axioms em_symm
#print axioms em_pd_sub
#print axioms em_pd_add3
#print axioms em_pd_neg
#print axioms em_pd_const
#print axioms em_pd_diff
#print axioms em_pd_comm
#print axioms em_pd_slice
#print axioms em_deriv_slice
#print axioms em_mixed
#print axioms em_timeD_apply
#print axioms em_curl_neg
#print axioms em_pd_wave
#print axioms em_hasDerivAt_wave

/-- A twist of a twist is a bend (Step 3). For any smooth vector field F on space (twice
continuously differentiable is enough), the curl of the curl equals the gradient of the divergence
minus the Laplacian: ∇×(∇×F) = ∇(∇·F) − ∇²F. -/
theorem curl_curl_eq_grad_div_sub_laplacian (F : Space → Space) (hF : ContDiff ℝ 2 F)
    (p : Space) :
    curl (curl F) p = grad (divergence F) p - vecLaplacian F p := by
  have hc : ∀ j, ContDiff ℝ 2 (fun q => F q j) := fun j => contDiff_pi.mp hF j
  have hd : ∀ i j, DifferentiableAt ℝ (pd i (fun q => F q j)) p :=
    fun i j => em_pd_diff (hc j) i p
  ext j
  fin_cases j
  · show pd 1 (fun q => pd 0 (fun q => F q 1) q - pd 1 (fun q => F q 0) q) p
        - pd 2 (fun q => pd 2 (fun q => F q 0) q - pd 0 (fun q => F q 2) q) p
      = pd 0 (fun q => pd 0 (fun q => F q 0) q + pd 1 (fun q => F q 1) q
          + pd 2 (fun q => F q 2) q) p
        - (pd 0 (pd 0 (fun q => F q 0)) p + pd 1 (pd 1 (fun q => F q 0)) p
          + pd 2 (pd 2 (fun q => F q 0)) p)
    rw [em_pd_sub (hd _ _) (hd _ _), em_pd_sub (hd _ _) (hd _ _),
      em_pd_add3 (hd _ _) (hd _ _) (hd _ _), em_pd_comm (hc 1) 1 0, em_pd_comm (hc 2) 2 0]
    ring
  · show pd 2 (fun q => pd 1 (fun q => F q 2) q - pd 2 (fun q => F q 1) q) p
        - pd 0 (fun q => pd 0 (fun q => F q 1) q - pd 1 (fun q => F q 0) q) p
      = pd 1 (fun q => pd 0 (fun q => F q 0) q + pd 1 (fun q => F q 1) q
          + pd 2 (fun q => F q 2) q) p
        - (pd 0 (pd 0 (fun q => F q 1)) p + pd 1 (pd 1 (fun q => F q 1)) p
          + pd 2 (pd 2 (fun q => F q 1)) p)
    rw [em_pd_sub (hd _ _) (hd _ _), em_pd_sub (hd _ _) (hd _ _),
      em_pd_add3 (hd _ _) (hd _ _) (hd _ _), em_pd_comm (hc 2) 2 1, em_pd_comm (hc 0) 0 1]
    ring
  · show pd 0 (fun q => pd 2 (fun q => F q 0) q - pd 0 (fun q => F q 2) q) p
        - pd 1 (fun q => pd 1 (fun q => F q 2) q - pd 2 (fun q => F q 1) q) p
      = pd 2 (fun q => pd 0 (fun q => F q 0) q + pd 1 (fun q => F q 1) q
          + pd 2 (fun q => F q 2) q) p
        - (pd 0 (pd 0 (fun q => F q 2)) p + pd 1 (pd 1 (fun q => F q 2)) p
          + pd 2 (pd 2 (fun q => F q 2)) p)
    rw [em_pd_sub (hd _ _) (hd _ _), em_pd_sub (hd _ _) (hd _ _),
      em_pd_add3 (hd _ _) (hd _ _) (hd _ _), em_pd_comm (hc 0) 0 2, em_pd_comm (hc 1) 1 2]
    ring

/-- The two curl equations combine into the wave equation (the card's main claim). In empty space,
with no charge and no current, let the electric field E and the magnetic field B be smooth (twice
continuously differentiable in space and time together) and obey Maxwell's four vacuum equations
∇·E = 0, ∇·B = 0, ∇×E = −∂B/∂t and ∇×B = μ₀ε₀ ∂E/∂t, where the vacuum constants μ₀ and ε₀ are
positive. Then at every time and every point the electric field's acceleration is c² times its
Laplacian, ∂²E/∂t² = c² ∇²E, with speed c = 1/√(μ₀ε₀). -/
theorem vacuum_maxwell_gives_wave_equation (μ₀ ε₀ : ℝ) (hμ₀ : 0 < μ₀) (hε₀ : 0 < ε₀)
    (E B : ℝ → Space → Space)
    (hE : ContDiff ℝ 2 (fun q : ℝ × Space => E q.1 q.2))
    (hB : ContDiff ℝ 2 (fun q : ℝ × Space => B q.1 q.2))
    (gauss_E : ∀ t p, divergence (E t) p = 0)
    (gauss_B : ∀ t p, divergence (B t) p = 0)
    (faraday : ∀ t p, curl (E t) p = -timeD B t p)
    (ampere_maxwell : ∀ t p, curl (B t) p = (μ₀ * ε₀) • timeD E t p) :
    ∀ t p, deriv (fun s => timeD E s p) t = (1 / √(μ₀ * ε₀)) ^ 2 • vecLaplacian (E t) p := by
  intro t p
  have hc : 0 < μ₀ * ε₀ := mul_pos hμ₀ hε₀
  have hBc : ∀ j, ContDiff ℝ 2 (fun q : ℝ × Space => B q.1 q.2 j) := fun j => contDiff_pi.mp hB j
  have hEt : ContDiff ℝ 2 (E t) := hE.comp (contDiff_const.prodMk contDiff_id)
  have h1 : (fun s => timeD E s p) = fun s => (μ₀ * ε₀)⁻¹ • curl (B s) p := by
    funext s; rw [ampere_maxwell, smul_smul, inv_mul_cancel₀ hc.ne', one_smul]
  have eB : ∀ j, (fun q => timeD B t q j) = fun q => deriv (fun s => B s q j) t :=
    fun j => funext fun q => em_timeD_apply hB t q j
  have h2 : HasDerivAt (fun s => curl (B s) p) (curl (timeD B t) p) t := by
    rw [hasDerivAt_pi]; intro j
    fin_cases j
    · show HasDerivAt (fun s => pd 1 (fun q => B s q 2) p - pd 2 (fun q => B s q 1) p)
        (pd 1 (fun q => timeD B t q 2) p - pd 2 (fun q => timeD B t q 1) p) t
      rw [eB, eB]
      exact (em_mixed (hBc 2) 1 t p).sub (em_mixed (hBc 1) 2 t p)
    · show HasDerivAt (fun s => pd 2 (fun q => B s q 0) p - pd 0 (fun q => B s q 2) p)
        (pd 2 (fun q => timeD B t q 0) p - pd 0 (fun q => timeD B t q 2) p) t
      rw [eB, eB]
      exact (em_mixed (hBc 0) 2 t p).sub (em_mixed (hBc 2) 0 t p)
    · show HasDerivAt (fun s => pd 0 (fun q => B s q 1) p - pd 1 (fun q => B s q 0) p)
        (pd 0 (fun q => timeD B t q 1) p - pd 1 (fun q => timeD B t q 0) p) t
      rw [eB, eB]
      exact (em_mixed (hBc 1) 0 t p).sub (em_mixed (hBc 0) 1 t p)
  have hTB : timeD B t = fun q => -curl (E t) q := by
    funext q; rw [faraday, neg_neg]
  have hdiv : divergence (E t) = fun _ => 0 := funext (gauss_E t)
  have hgrad : grad (divergence (E t)) p = 0 := by
    rw [hdiv]; ext j; fin_cases j <;> simp [grad, em_pd_const]
  have h3 : curl (timeD B t) p = vecLaplacian (E t) p := by
    rw [hTB, em_curl_neg, curl_curl_eq_grad_div_sub_laplacian (E t) hEt p, hgrad]
    simp
  rw [h1, show (fun s => (μ₀ * ε₀)⁻¹ • curl (B s) p) = (μ₀ * ε₀)⁻¹ • fun s => curl (B s) p from rfl,
    (h2.const_smul (μ₀ * ε₀)⁻¹).deriv, h3, div_pow, one_pow, sq_sqrt hc.le, one_div]

/-- The station's wave, travelling along x: E = E₀ ŷ cos(kx − ωt), pointing along y. -/
noncomputable def planeE (E₀ k ω : ℝ) (t : ℝ) (p : Space) : Space :=
  ![0, E₀ * cos (k * p 0 - ω * t), 0]

/-- Its magnetic partner: B = (E₀/c) ẑ cos(kx − ωt), pointing along z. -/
noncomputable def planeB (E₀ c k ω : ℝ) (t : ℝ) (p : Space) : Space :=
  ![0, 0, E₀ / c * cos (k * p 0 - ω * t)]

/-- One solution is the wave from the station (Steps 5 and 6). For any peak field E₀ and any
frequency f > 0, with c = 1/√(μ₀ε₀), wavelength λ = c/f, wavenumber k = 2π/λ and angular frequency
ω = 2πf, the plane wave E = E₀ ŷ cos(kx − ωt), B = (E₀/c) ẑ cos(kx − ωt) obeys all four of
Maxwell's vacuum equations at every time and every point. -/
theorem plane_wave_solves_vacuum_maxwell (μ₀ ε₀ E₀ f c lam k ω : ℝ) (hμ₀ : 0 < μ₀)
    (hε₀ : 0 < ε₀) (hf : 0 < f) (hc : c = 1 / √(μ₀ * ε₀)) (hlam : lam = c / f)
    (hk : k = 2 * π / lam) (hω : ω = 2 * π * f) :
    (∀ t p, divergence (planeE E₀ k ω t) p = 0) ∧
      (∀ t p, divergence (planeB E₀ c k ω t) p = 0) ∧
      (∀ t p, curl (planeE E₀ k ω t) p = -timeD (planeB E₀ c k ω) t p) ∧
      (∀ t p, curl (planeB E₀ c k ω t) p = (μ₀ * ε₀) • timeD (planeE E₀ k ω) t p) := by
  have hsq : 0 < √(μ₀ * ε₀) := Real.sqrt_pos.mpr (mul_pos hμ₀ hε₀)
  have hcpos : 0 < c := by rw [hc]; positivity
  have hkc : k = ω / c := by
    rw [hk, hlam, hω]; field_simp
  have hμε : μ₀ * ε₀ = 1 / c ^ 2 := by
    rw [hc, div_pow, one_pow, sq_sqrt (mul_pos hμ₀ hε₀).le, one_div_one_div]
  have hTB : ∀ t p, timeD (planeB E₀ c k ω) t p = ![0, 0, E₀ / c * ω * sin (k * p 0 - ω * t)] := by
    intro t p
    apply HasDerivAt.deriv
    rw [hasDerivAt_pi]; intro j
    fin_cases j
    · exact hasDerivAt_const t (0 : ℝ)
    · exact hasDerivAt_const t (0 : ℝ)
    · exact em_hasDerivAt_wave (E₀ / c) k ω (p 0) t
  have hTE : ∀ t p, timeD (planeE E₀ k ω) t p = ![0, E₀ * ω * sin (k * p 0 - ω * t), 0] := by
    intro t p
    apply HasDerivAt.deriv
    rw [hasDerivAt_pi]; intro j
    fin_cases j
    · exact hasDerivAt_const t (0 : ℝ)
    · exact em_hasDerivAt_wave E₀ k ω (p 0) t
    · exact hasDerivAt_const t (0 : ℝ)
  refine ⟨fun t p => ?_, fun t p => ?_, fun t p => ?_, fun t p => ?_⟩
  · simp [divergence, planeE, em_pd_wave, em_pd_const]
  · simp [divergence, planeB, em_pd_wave, em_pd_const]
  · rw [hTB]
    ext j; fin_cases j <;> simp [curl, planeE, em_pd_wave, em_pd_const]
    rw [hkc]; field_simp; simp
  · rw [hTE]
    ext j; fin_cases j <;> simp [curl, planeB, em_pd_wave, em_pd_const]
    rw [hkc, hμε]; field_simp

-- Worked numbers by hand, exactly (c = 299,792,458 m/s, f = 100 MHz = 100 × 10⁶ Hz).
-- Period 1/f = 10 ns.
example : (1 : ℚ) / (100 * 10 ^ 6) = 10 / 10 ^ 9 := by norm_num
-- Wavelength λ = c/f = 2.99792458 m (the card's 2.9979 m).
example : (299792458 : ℚ) / (100 * 10 ^ 6) = 299792458 / 10 ^ 8 := by norm_num
-- Quarter-wave whip λ/4 = 0.749481145 m (0.7495 m); half-wave dipole λ/2 = 1.49896229 m (1.4990 m).
example : (299792458 : ℚ) / 10 ^ 8 / 4 = 749481145 / 10 ^ 9 := by norm_num
example : (299792458 : ℚ) / 10 ^ 8 / 2 = 149896229 / 10 ^ 8 := by norm_num
-- The crest after 2.5 ns, 5.0 ns, 7.5 ns, 10 ns: 0.749, 1.499, 2.248, 2.998 m; after one period it is one wavelength on.
example : (299792458 : ℚ) * (25 / 10 ^ 10) = 749481145 / 10 ^ 9 := by norm_num
example : (299792458 : ℚ) * (50 / 10 ^ 10) = 149896229 / 10 ^ 8 := by norm_num
example : (299792458 : ℚ) * (75 / 10 ^ 10) = 2248443435 / 10 ^ 9 := by norm_num
example : (299792458 : ℚ) * (10 / 10 ^ 9) = 299792458 / 10 ^ 8 := by norm_num
-- At 50 Hz the wavelength is 5,995,849.16 m, about 5,996 km.
example : (299792458 : ℚ) / 50 = 599584916 / 100 := by norm_num
-- Antenna tilted 60°: voltage × cos 60° = 1/2, power × 1/4.
example : cos (π / 3) = 1 / 2 := by rw [cos_pi_div_three]
example : cos (π / 3) ^ 2 = 1 / 4 := by rw [cos_pi_div_three]; norm_num
-- Polyethylene, permittivity 2.25 ε₀: the wave slows by √2.25 = 1.5.
example : √(9 / 4 : ℝ) = 3 / 2 := by
  rw [show (9 / 4 : ℝ) = (3 / 2) ^ 2 by norm_num, sqrt_sq (by norm_num)]

#print axioms curl_curl_eq_grad_div_sub_laplacian
#print axioms vacuum_maxwell_gives_wave_equation
#print axioms plane_wave_solves_vacuum_maxwell
