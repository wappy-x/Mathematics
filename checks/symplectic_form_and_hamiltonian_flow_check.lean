-- Symplectic form: the flow of Hamilton's equations, written as the one form equation ι_X ω = dH, carries the symplectic form ω = dq₁ ∧ dp₁ + … + dqₙ ∧ dpₙ to itself in any number of dimensions, and so keeps volume too, while a stretch can keep volume without keeping ω.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Topology.Algebra.Module.Determinant
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Matrix.Block
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Topology.Instances.Matrix
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.LinearAlgebra.Basis.Prod
import Mathlib.LinearAlgebra.Determinant
import Mathlib.Tactic.LinearCombination
import Mathlib.Topology.Algebra.Module.FiniteDimension

open Real Matrix
open scoped ContDiff

noncomputable section

/-- The phase space of `n` swings: a state is the list of angles `q = (q₁, …, qₙ)` and the list
of momenta `p = (p₁, …, pₙ)`. -/
abbrev PhaseSpace (n : ℕ) := (Fin n → ℝ) × (Fin n → ℝ)

/-- The symplectic form `ω = dq₁ ∧ dp₁ + … + dqₙ ∧ dpₙ`, fed two small changes of state
`u` and `v`: the sum over the swings of the signed areas `u_q v_p - u_p v_q` of their shadows
on each swing's `(q, p)` plane. -/
def omega (n : ℕ) (u v : PhaseSpace n) : ℝ :=
  ∑ i, (u.1 i * v.2 i - u.2 i * v.1 i)

/-- The card's matrix `J`, with blocks `0, Iₙ` on top and `-Iₙ, 0` below, so that
`ω(u, v) = uᵀ J v` with the angles indexed on the left and the momenta on the right. -/
def cardJ (n : ℕ) : Matrix (Fin n ⊕ Fin n) (Fin n ⊕ Fin n) ℝ :=
  Matrix.fromBlocks 0 1 (-1) 0

lemma omega_antisymm (n : ℕ) (a b : PhaseSpace n) : omega n a b = -omega n b a := by
  unfold omega
  rw [← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  ring

lemma cardJ_transpose (n : ℕ) : (cardJ n)ᵀ = -cardJ n := by
  simp [cardJ, Matrix.fromBlocks_transpose, Matrix.fromBlocks_neg]

lemma cardJ_mul_self (n : ℕ) : cardJ n * cardJ n = -1 := by
  simp [cardJ, Matrix.fromBlocks_multiply, ← Matrix.fromBlocks_one, Matrix.fromBlocks_neg]

lemma cardJ_isUnit_det (n : ℕ) : IsUnit (cardJ n).det :=
  Matrix.isUnit_det_of_right_inverse (B := -cardJ n) (by rw [Matrix.mul_neg, cardJ_mul_self, neg_neg])

lemma det_eq_one_of_symplectic_path (n : ℕ) (M : ℝ → Matrix (Fin n ⊕ Fin n) (Fin n ⊕ Fin n) ℝ)
    (hc : ∀ i j, Continuous fun t => M t i j) (h0 : M 0 = 1)
    (hs : ∀ t, (M t)ᵀ * cardJ n * M t = cardJ n) : ∀ t, (M t).det = 1 := by
  have hsq : ∀ t, (M t).det * (M t).det = 1 := by
    intro t
    have h := congrArg Matrix.det (hs t)
    rw [Matrix.det_mul, Matrix.det_mul, Matrix.det_transpose] at h
    have h2 : ((M t).det * (M t).det - 1) * (cardJ n).det = 0 := by linear_combination h
    rcases mul_eq_zero.1 h2 with h3 | h3
    · linarith
    · exact absurd h3 (cardJ_isUnit_det n).ne_zero
  have hcont : Continuous fun t => (M t).det :=
    Continuous.matrix_det (continuous_pi fun i => continuous_pi fun j => hc i j)
  intro t
  by_contra hne
  have hm : (M t).det = -1 := by
    have h := hsq t
    have : ((M t).det - 1) * ((M t).det + 1) = 0 := by linear_combination h
    rcases mul_eq_zero.1 this with h3 | h3
    · exact absurd (by linarith) hne
    · linarith
  have hmem : (0 : ℝ) ∈ Set.uIcc ((M 0).det) ((M t).det) := by
    rw [h0, Matrix.det_one, hm, Set.mem_uIcc]; right; constructor <;> norm_num
  obtain ⟨c, -, hc0⟩ := intermediate_value_uIcc hcont.continuousOn hmem
  have := hsq c
  simp only at hc0
  rw [hc0] at this
  norm_num at this

lemma hasDerivAt_omega (n : ℕ) {f g : ℝ → PhaseSpace n} {f' g' : PhaseSpace n} {r : ℝ}
    (hf : HasDerivAt f f' r) (hg : HasDerivAt g g' r) :
    HasDerivAt (fun x => omega n (f x) (g x)) (omega n f' (g r) + omega n (f r) g') r := by
  have h1 : ∀ {h : ℝ → PhaseSpace n} {h' : PhaseSpace n}, HasDerivAt h h' r →
      ∀ i, HasDerivAt (fun x => (h x).1 i) (h'.1 i) r :=
    fun hh i => hasDerivAt_pi.1 hh.fst i
  have h2 : ∀ {h : ℝ → PhaseSpace n} {h' : PhaseSpace n}, HasDerivAt h h' r →
      ∀ i, HasDerivAt (fun x => (h x).2 i) (h'.2 i) r :=
    fun hh i => hasDerivAt_pi.1 hh.snd i
  unfold omega
  have := HasDerivAt.fun_sum (u := Finset.univ) (fun i _ =>
    ((h1 hf i).mul (h2 hg i)).sub ((h2 hf i).mul (h1 hg i)))
  convert this using 1
  rw [← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  ring

/-- The standard basis of phase space, angles indexed on the left and momenta on the right. -/
def phaseBasis (n : ℕ) : Module.Basis (Fin n ⊕ Fin n) ℝ (PhaseSpace n) :=
  (Pi.basisFun ℝ (Fin n)).prod (Pi.basisFun ℝ (Fin n))

lemma omega_eq_repr (n : ℕ) (a b : PhaseSpace n) :
    omega n a b = ∑ k, ∑ l, (phaseBasis n).repr a k * cardJ n k l * (phaseBasis n).repr b l := by
  simp [omega, phaseBasis, cardJ, Fintype.sum_sum_type, Matrix.one_apply, Finset.sum_sub_distrib]
  ring

lemma toMatrix_symplectic (n : ℕ) (f : PhaseSpace n →ₗ[ℝ] PhaseSpace n)
    (hf : ∀ u v, omega n (f u) (f v) = omega n u v) :
    (LinearMap.toMatrix (phaseBasis n) (phaseBasis n) f)ᵀ * cardJ n *
      LinearMap.toMatrix (phaseBasis n) (phaseBasis n) f = cardJ n := by
  ext i j
  have h := hf (phaseBasis n i) (phaseBasis n j)
  rw [omega_eq_repr, omega_eq_repr] at h
  simp only [Module.Basis.repr_self, Finsupp.single_apply] at h
  simp only [Matrix.mul_apply, Matrix.transpose_apply, LinearMap.toMatrix_apply, Finset.sum_mul]
  rw [Finset.sum_comm]
  convert h using 1
  simp [Finset.sum_ite_eq]

/-- A Hamiltonian flow keeps the symplectic form (Step 3 and the detailed proof). Take `n`
swings with a smooth energy `H` on phase space. Let `X` be the Hamiltonian vector field, given
by the one form equation `ι_X ω = dH`: at every state `z`, `ω(X z, v) = dH_z(v)` for every
small change `v`. Let `φ t` be its flow (where every state is after time `t`), smooth, starting
at the identity and moving each state with velocity `X`. Then at every time `t` and every state
`z`, the flow's derivative carries any two small changes `u`, `v` with the same symplectic area,
`ω(dφ_t u, dφ_t v) = ω(u, v)`, that is `φ_t* ω = ω`; and so it keeps volume too: the
determinant of `dφ_t` is 1 (Liouville's theorem). -/
theorem hamiltonian_flow_preserves_symplectic_form (n : ℕ) (H : PhaseSpace n → ℝ)
    (hH : ContDiff ℝ ∞ H) (X : PhaseSpace n → PhaseSpace n)
    (hX : ∀ z v, omega n (X z) v = fderiv ℝ H z v)
    (φ : ℝ → PhaseSpace n → PhaseSpace n)
    (hφ : ContDiff ℝ ∞ (fun s : ℝ × PhaseSpace n => φ s.1 s.2))
    (hφ0 : ∀ z, φ 0 z = z)
    (hφX : ∀ t z, HasDerivAt (fun s => φ s z) (X (φ t z)) t) :
    ∀ t z, (∀ u v, omega n (fderiv ℝ (φ t) z u) (fderiv ℝ (φ t) z v) = omega n u v) ∧
      (fderiv ℝ (φ t) z).det = 1 := by
  set F : ℝ × PhaseSpace n → PhaseSpace n := fun s => φ s.1 s.2 with hFdef
  have hFd : Differentiable ℝ F := hφ.differentiable (by simp)
  have hDFd : Differentiable ℝ (fderiv ℝ F) :=
    (hφ.fderiv_right (m := ∞) (by simp)).differentiable (by simp)
  have hHd : Differentiable ℝ H := hH.differentiable (by simp)
  have hDHd : Differentiable ℝ (fderiv ℝ H) :=
    (hH.fderiv_right (m := ∞) (by simp)).differentiable (by simp)
  have hsymF : ∀ p, IsSymmSndFDerivAt ℝ F p := fun p =>
    hφ.contDiffAt.isSymmSndFDerivAt (by simp)
  have hsymH : ∀ w, IsSymmSndFDerivAt ℝ H w := fun w =>
    hH.contDiffAt.isSymmSndFDerivAt (by simp)
  -- the space derivative of `φ s` is the derivative of `F` along the state directions
  have hφs : ∀ s w, HasFDerivAt (φ s)
      ((fderiv ℝ F (s, w)).comp (ContinuousLinearMap.inr ℝ ℝ (PhaseSpace n))) w := fun s w =>
    (hFd (s, w)).hasFDerivAt.comp w (hasFDerivAt_prodMk_right s w)
  have hA : ∀ s w u, fderiv ℝ (φ s) w u = fderiv ℝ F (s, w) (0, u) := fun s w u => by
    rw [(hφs s w).fderiv]; rfl
  -- the time derivative of `F` is the Hamiltonian field
  have hX' : ∀ s w, fderiv ℝ F (s, w) (1, 0) = X (φ s w) := by
    intro s w
    have h1 : HasDerivAt (F ∘ fun r => (id r, w)) (fderiv ℝ F (s, w) (1, 0)) s :=
      (hFd (s, w)).hasFDerivAt.comp_hasDerivAt s ((hasDerivAt_id s).prodMk (hasDerivAt_const s w))
    exact h1.unique (hφX s w)
  intro t z
  -- time derivative of `fderiv (φ r) z u`
  have hAderiv : ∀ s u, HasDerivAt (fun r => fderiv ℝ (φ r) z u)
      (fderiv ℝ (fderiv ℝ F) (s, z) (1, 0) (0, u)) s := by
    intro s u
    have hc : HasDerivAt (fun r => fderiv ℝ F (r, z)) (fderiv ℝ (fderiv ℝ F) (s, z) (1, 0)) s :=
      (hDFd (s, z)).hasFDerivAt.comp_hasDerivAt s ((hasDerivAt_id s).prodMk (hasDerivAt_const s z))
    have := hc.clm_apply (hasDerivAt_const s ((0 : ℝ), u))
    simp only [map_zero, add_zero] at this
    simpa only [hA] using this
  -- the key identity: ω(Y u, b) is the second derivative of `H`
  have hY : ∀ s u b, omega n (fderiv ℝ (fderiv ℝ F) (s, z) (1, 0) (0, u)) b =
      fderiv ℝ (fderiv ℝ H) (φ s z) (fderiv ℝ (φ s) z u) b := by
    intro s u b
    rw [hsymF (s, z) (1, 0) (0, u)]
    have hline : HasDerivAt (fun r : ℝ => z + r • u) u 0 := by
      simpa using ((hasDerivAt_id (0 : ℝ)).smul_const u).const_add z
    have hk1 : HasDerivAt (fun r : ℝ => fderiv ℝ F (s, z + r • u))
        (fderiv ℝ (fderiv ℝ F) (s, z) (0, u)) 0 :=
      (hDFd (s, z)).hasFDerivAt.comp_hasDerivAt_of_eq (0 : ℝ)
        ((hasDerivAt_const (0 : ℝ) s).prodMk hline) (by simp)
    have hk := hk1.clm_apply (hasDerivAt_const (0 : ℝ) ((1 : ℝ), (0 : PhaseSpace n)))
    simp only [map_zero, add_zero] at hk
    have hL := hasDerivAt_omega n hk (hasDerivAt_const (0 : ℝ) b)
    have hφline : HasDerivAt (fun r : ℝ => φ s (z + r • u)) (fderiv ℝ (φ s) z u) 0 :=
      (hφs s z).differentiableAt.hasFDerivAt.comp_hasDerivAt_of_eq (0 : ℝ) hline (by simp)
    have hR1 : HasDerivAt (fun r : ℝ => fderiv ℝ H (φ s (z + r • u)))
        (fderiv ℝ (fderiv ℝ H) (φ s z) (fderiv ℝ (φ s) z u)) 0 :=
      (hDHd (φ s z)).hasFDerivAt.comp_hasDerivAt_of_eq (0 : ℝ) hφline (by simp)
    have hR := hR1.clm_apply (hasDerivAt_const (0 : ℝ) b)
    simp only [map_zero, add_zero] at hR
    have heq : (fun r : ℝ => omega n (fderiv ℝ F (s, z + r • u) (1, 0)) b) =
        fun r : ℝ => fderiv ℝ H (φ s (z + r • u)) b := by
      funext r
      rw [hX', hX]
    rw [heq] at hL
    have := hL.unique hR
    have h0 : omega n (fderiv ℝ F (s, z + (0 : ℝ) • u) (1, 0)) 0 = 0 := by simp [omega]
    rw [h0, add_zero] at this
    exact this
  -- ω(A r u, A r v) has zero derivative
  have hpres : ∀ u v r, omega n (fderiv ℝ (φ r) z u) (fderiv ℝ (φ r) z v) = omega n u v := by
    intro u v
    have hd : ∀ s, HasDerivAt (fun r => omega n (fderiv ℝ (φ r) z u) (fderiv ℝ (φ r) z v)) 0 s := by
      intro s
      have := hasDerivAt_omega n (hAderiv s u) (hAderiv s v)
      rw [omega_antisymm n (fderiv ℝ (φ s) z u), hY, hY, hsymH (φ s z), add_neg_cancel] at this
      exact this
    intro r
    have hc : omega n (fderiv ℝ (φ r) z u) (fderiv ℝ (φ r) z v) =
        omega n (fderiv ℝ (φ 0) z u) (fderiv ℝ (φ 0) z v) :=
      is_const_of_deriv_eq_zero (f := fun r => omega n (fderiv ℝ (φ r) z u) (fderiv ℝ (φ r) z v))
        (fun s => (hd s).differentiableAt) (fun s => (hd s).deriv) r 0
    have hid : φ 0 = id := funext hφ0
    rw [hc, hid, fderiv_id]
    rfl
  refine ⟨fun u v => hpres u v t, ?_⟩
  -- the determinant, through the matrix in the standard basis
  set M : ℝ → Matrix (Fin n ⊕ Fin n) (Fin n ⊕ Fin n) ℝ := fun r =>
    LinearMap.toMatrix (phaseBasis n) (phaseBasis n) (fderiv ℝ (φ r) z : PhaseSpace n →ₗ[ℝ] PhaseSpace n)
    with hMdef
  have hMs : ∀ r, (M r)ᵀ * cardJ n * M r = cardJ n := fun r =>
    toMatrix_symplectic n _ (fun u v => hpres u v r)
  have hM0 : M 0 = 1 := by
    have hid : φ 0 = id := funext hφ0
    simp only [hMdef, hid, fderiv_id]
    exact LinearMap.toMatrix_id _
  have hMc : ∀ i j, Continuous fun r => M r i j := by
    intro i j
    simp only [hMdef, LinearMap.toMatrix_apply]
    have hcont : Continuous fun r => fderiv ℝ (φ r) z (phaseBasis n j) :=
      continuous_iff_continuousAt.2 fun r => (hAderiv r _).continuousAt
    exact (((phaseBasis n).coord i).continuous_of_finiteDimensional).comp hcont
  have := det_eq_one_of_symplectic_path n M hMc hM0 hMs t
  rw [ContinuousLinearMap.det, ← LinearMap.det_toMatrix (phaseBasis n)]
  exact this

/-- The detailed proof in matrices. Let `S t` be a symmetric matrix at every time (`H`'s second
slopes along a motion) and let `M t` (the flow's Jacobian matrix) start at the identity and
change by `M' = J S M`, entry by entry. Then at every time `Mᵀ J M = J`, so `M` keeps `ω`, and
`det M = 1`, so `M` keeps volume. -/
theorem jacobian_of_hamiltonian_flow_is_symplectic (n : ℕ)
    (S : ℝ → Matrix (Fin n ⊕ Fin n) (Fin n ⊕ Fin n) ℝ) (hS : ∀ t, (S t)ᵀ = S t)
    (M : ℝ → Matrix (Fin n ⊕ Fin n) (Fin n ⊕ Fin n) ℝ) (hM0 : M 0 = 1)
    (hM : ∀ t i j, HasDerivAt (fun s => M s i j) ((cardJ n * S t * M t) i j) t) :
    ∀ t, (M t)ᵀ * cardJ n * M t = cardJ n ∧ (M t).det = 1 := by
  have hzero : ∀ r, (cardJ n * S r * M r)ᵀ * cardJ n * M r +
      (M r)ᵀ * cardJ n * (cardJ n * S r * M r) = 0 := by
    intro r
    have hJJ : ∀ Y : Matrix (Fin n ⊕ Fin n) (Fin n ⊕ Fin n) ℝ, cardJ n * (cardJ n * Y) = -Y := by
      intro Y; rw [← Matrix.mul_assoc, cardJ_mul_self, Matrix.neg_mul, Matrix.one_mul]
    rw [Matrix.transpose_mul, Matrix.transpose_mul, hS, cardJ_transpose]
    simp only [Matrix.mul_assoc, Matrix.neg_mul, Matrix.mul_neg, hJJ, neg_neg, add_neg_cancel]
  have hN : ∀ s, (M s)ᵀ * cardJ n * M s = cardJ n := by
    intro s
    ext i j
    have hd : ∀ r, HasDerivAt (fun s => ((M s)ᵀ * cardJ n * M s) i j) 0 r := by
      intro r
      have key : HasDerivAt (fun s => ((M s)ᵀ * cardJ n * M s) i j)
          (((cardJ n * S r * M r)ᵀ * cardJ n * M r +
            (M r)ᵀ * cardJ n * (cardJ n * S r * M r)) i j) r := by
        simp only [Matrix.mul_apply, Matrix.add_apply, Matrix.transpose_apply]
        rw [← Finset.sum_add_distrib]
        apply HasDerivAt.fun_sum
        intro x _
        exact (HasDerivAt.fun_sum fun y _ => (hM r y i).mul_const (cardJ n y x)).mul (hM r x j)
      rw [hzero] at key
      exact key
    have h' : ((M s)ᵀ * cardJ n * M s) i j = ((M 0)ᵀ * cardJ n * M 0) i j :=
      is_const_of_deriv_eq_zero (f := fun s => ((M s)ᵀ * cardJ n * M s) i j)
        (fun r => (hd r).differentiableAt) (fun r => (hd r).deriv) s 0
    rw [h', hM0]
    simp
  intro t
  refine ⟨hN t, ?_⟩
  exact det_eq_one_of_symplectic_path n M
    (fun i j => continuous_iff_continuousAt.2 fun r => (hM r i j).continuousAt) hM0 hN t

/-- Hamilton's equations are one form equation (Step 2). At a state `z`, an arrow `X` satisfies
`ι_X ω = dH`, that is `ω(X, v) = dH_z(v)` for every `v`, exactly when, for every swing `i`,
the angle rate is the slope of `H` in `pᵢ` and the momentum rate is minus the slope of `H` in
`qᵢ`: `Xq i = ∂H/∂pᵢ` and `Xp i = -∂H/∂qᵢ`. So the form equation fixes `X` uniquely. -/
theorem form_equation_iff_hamiltons_equations (n : ℕ) (H : PhaseSpace n → ℝ)
    (z X : PhaseSpace n) :
    (∀ v, omega n X v = fderiv ℝ H z v) ↔
      ∀ i, X.1 i = fderiv ℝ H z (0, Pi.single i 1) ∧
        X.2 i = -fderiv ℝ H z (Pi.single i 1, 0) := by
  constructor
  · intro h i
    constructor
    · rw [← h]
      simp [omega, Pi.single_apply]
    · rw [← h]
      simp [omega, Pi.single_apply]
  · intro h v
    have hv : v = ∑ i, (v.1 i • ((Pi.single i 1 : Fin n → ℝ), (0 : Fin n → ℝ)) +
        v.2 i • ((0 : Fin n → ℝ), (Pi.single i 1 : Fin n → ℝ))) := by
      ext j <;> simp [Prod.fst_sum, Prod.snd_sum, Finset.sum_apply, Pi.single_apply]
    conv_rhs => rw [hv]
    rw [map_sum]
    unfold omega
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [map_add, map_smul, map_smul, ← (h i).1, smul_eq_mul, smul_eq_mul,
      show fderiv ℝ H z (Pi.single i 1, 0) = -X.2 i by rw [(h i).2, neg_neg]]
    ring

end

/-! Worked numbers from the card: m = 20 kg, l = 2 m, g = 9.81 = 981/100 m/s², as exact
fractions. -/

-- m l² = 80 kg m² and m g l = 392.4 = 1962/5 J; K/I = 392.4/80 = 4.905 = 981/200 1/s².
example : (20 : ℚ) * 2 ^ 2 = 80 ∧ (20 : ℚ) * (981 / 100) * 2 = 1962 / 5 ∧
    ((1962 / 5 : ℚ) / 80) = 981 / 200 := by norm_num

-- Energy at release: 0²/160 - 392.4 cos(-60°) = -196.2 = -981/5 J.
example : (0 : ℝ) ^ 2 / 160 - 1962 / 5 * cos (-(π / 3)) = -981 / 5 := by
  rw [cos_neg, cos_pi_div_three]; norm_num

-- Velocity at release: X = (0/80, -392.4 sin(-60°)) = (0, 196.2 √3), that is (0, 339.8284).
example : -(1962 / 5 : ℝ) * sin (-(π / 3)) = 981 / 5 * √3 := by
  rw [sin_neg, sin_pi_div_three]; ring

-- At release ι_X ω = dH, both -339.8284 dq: with X = (0, a) and v = (v_q, v_p),
-- ω(X, v) = 0·v_p - a·v_q = -a v_q.
example (a vq vp : ℝ) : omega 1 (fun _ => 0, fun _ => a) (fun _ => vq, fun _ => vp) = -a * vq := by
  simp [omega]

-- The patch at release: edges (4°, 0) = (π/45 rad, 0) and (0, 8 kg m²/s) span ω = 8π/45 J s,
-- that is 0.558505 J s.
example : omega 1 (fun _ => 4 * π / 180, fun _ => 0) (fun _ => 0, fun _ => 8) = 8 * π / 45 := by
  norm_num [omega]; ring

-- The stretch q₁ × 2, q₂ × 1/2 on two swings: its matrix has determinant 1 (volume kept) ...
example : (Matrix.diagonal ![(2 : ℚ), 1 / 2, 1, 1]).det = 1 := by
  norm_num [Matrix.det_diagonal, Fin.prod_univ_four]

-- ... but it doubles ω on swing 1's patch edges: ω(2u, v) = 2 ω(u, v) for u = (e₁, 0) and
-- v = (0, e₁), so 0.558505 J s becomes 1.117011 J s.
example (a b : ℝ) :
    omega 2 (![2 * a, 0], 0) (0, ![b, 0]) = 2 * omega 2 (![a, 0], 0) (0, ![b, 0]) := by
  simp [omega, Fin.sum_univ_two]; ring

#print axioms omega_antisymm
#print axioms cardJ_transpose
#print axioms cardJ_mul_self
#print axioms cardJ_isUnit_det
#print axioms det_eq_one_of_symplectic_path
#print axioms hasDerivAt_omega
#print axioms omega_eq_repr
#print axioms toMatrix_symplectic
#print axioms hamiltonian_flow_preserves_symplectic_form
#print axioms jacobian_of_hamiltonian_flow_is_symplectic
#print axioms form_equation_iff_hamiltons_equations
