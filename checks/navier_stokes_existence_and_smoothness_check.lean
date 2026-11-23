-- Navier-Stokes: for every viscosity Clay's version A or C is true and version B or D is true, the card's toy-world counts hold, and the Taylor-Green flow solves the equations exactly.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Haar.OfBasis
import Mathlib.Analysis.Normed.Lp.MeasurableSpace
import Mathlib.LinearAlgebra.Trace
import Mathlib.Data.Fintype.Powerset
import Mathlib.Analysis.InnerProductSpace.Trace
import Mathlib.Analysis.Calculus.FDeriv.WithLp
import Mathlib.Analysis.Calculus.ContDiff.WithLp

open MeasureTheory Laplacian Gradient
open scoped ContDiff

namespace NavierStokesClay

/-- Three-dimensional space `ℝ³`. -/
abbrev E3 := EuclideanSpace ℝ (Fin 3)

/-- The unit vector `e_j` along axis `j`. -/
noncomputable abbrev unitVec (j : Fin 3) : E3 := EuclideanSpace.single j 1

/-- The closed half-space `ℝ³ × [0, ∞)` where time is not negative. -/
def halfSpace : Set (E3 × ℝ) := {q | 0 ≤ q.2}

/-- The divergence `∇ · v` of a vector field: the trace of its derivative. -/
noncomputable def divergence (v : E3 → E3) (x : E3) : ℝ := LinearMap.trace ℝ E3 (fderiv ℝ v x)

/-- Equations (1), (2), (3) with viscosity `ν`, start `u0`, force `f`, pressure `p` and
velocity `u`: (1) `∂u/∂t + (u · ∇) u = ν Δu − ∇p + f` for `t > 0`; (2) `∇ · u = 0` for
`t ≥ 0`; (3) `u(x, 0) = u0(x)`. -/
def SolvesNS (ν : ℝ) (u0 : E3 → E3) (f : E3 → ℝ → E3) (p : E3 → ℝ → ℝ) (u : E3 → ℝ → E3) :
    Prop :=
  (∀ x t, 0 < t →
      deriv (fun s => u x s) t + fderiv ℝ (fun y => u y t) x (u x t)
        = ν • Δ (fun y => u y t) x - ∇ (fun y => p y t) x + f x t) ∧
  (∀ x t, 0 ≤ t → divergence (fun y => u y t) x = 0) ∧
  (∀ x, u x 0 = u0 x)

/-- Condition (6): `p` and `u` are smooth on `ℝ³ × [0, ∞)`. -/
def SmoothOnHalfSpace (p : E3 → ℝ → ℝ) (u : E3 → ℝ → E3) : Prop :=
  ContDiffOn ℝ ∞ (fun q : E3 × ℝ => p q.1 q.2) halfSpace ∧
  ContDiffOn ℝ ∞ (fun q : E3 × ℝ => u q.1 q.2) halfSpace

/-- Condition (7): the energy `∫ |u(x, t)|² dx` stays below one constant for all `t ≥ 0`. -/
def BoundedEnergy (u : E3 → ℝ → E3) : Prop :=
  ∃ C : ℝ, ∀ t, 0 ≤ t → Integrable (fun x => ‖u x t‖ ^ 2) ∧ ∫ x, ‖u x t‖ ^ 2 < C

/-- An admissible start on all of space: smooth, divergence free, and (4): every derivative
dies away faster than every power, `|∂^α u0(x)| ≤ C_{αK} (1 + |x|)^(−K)`. -/
def AdmissibleStartR3 (u0 : E3 → E3) : Prop :=
  ContDiff ℝ ∞ u0 ∧ (∀ x, divergence u0 x = 0) ∧
  ∀ α K : ℕ, ∃ C : ℝ, ∀ x, ‖iteratedFDeriv ℝ α u0 x‖ ≤ C / (1 + ‖x‖) ^ K

/-- An admissible force on all of space: smooth on `ℝ³ × [0, ∞)`, and (5): every derivative in
space and time satisfies `|∂_x^α ∂_t^m f(x, t)| ≤ C_{αmK} (1 + |x| + t)^(−K)`. -/
def AdmissibleForceR3 (f : E3 → ℝ → E3) : Prop :=
  ContDiffOn ℝ ∞ (fun q : E3 × ℝ => f q.1 q.2) halfSpace ∧
  ∀ n K : ℕ, ∃ C : ℝ, ∀ x t, 0 ≤ t →
    ‖iteratedFDerivWithin ℝ n (fun q : E3 × ℝ => f q.1 q.2) halfSpace (x, t)‖
      ≤ C / (1 + ‖x‖ + t) ^ K

/-- An admissible start in the repeating cube `ℝ³/ℤ³`: smooth, divergence free, and (8): it
repeats when `x` moves by one unit along an axis. -/
def AdmissibleStartT3 (u0 : E3 → E3) : Prop :=
  ContDiff ℝ ∞ u0 ∧ (∀ x, divergence u0 x = 0) ∧ ∀ x j, u0 (x + unitVec j) = u0 x

/-- An admissible force in the repeating cube: smooth on `ℝ³ × [0, ∞)`, repeating in each axis
(8), and (9): `|∂_x^α ∂_t^m f(x, t)| ≤ C_{αmK} (1 + t)^(−K)`. -/
def AdmissibleForceT3 (f : E3 → ℝ → E3) : Prop :=
  ContDiffOn ℝ ∞ (fun q : E3 × ℝ => f q.1 q.2) halfSpace ∧
  (∀ x t j, f (x + unitVec j) t = f x t) ∧
  ∀ n K : ℕ, ∃ C : ℝ, ∀ x t, 0 ≤ t →
    ‖iteratedFDerivWithin ℝ n (fun q : E3 × ℝ => f q.1 q.2) halfSpace (x, t)‖ ≤ C / (1 + t) ^ K

/-- Conditions (10) and (11): the solution repeats in each axis (the pressure too, as in the
erratum) and is smooth on `ℝ³ × [0, ∞)`. -/
def PeriodicSmooth (p : E3 → ℝ → ℝ) (u : E3 → ℝ → E3) : Prop :=
  SmoothOnHalfSpace p u ∧
  ∀ x t j, 0 ≤ t → u (x + unitVec j) t = u x t ∧ p (x + unitVec j) t = p x t

/-- Version A: with no force, every admissible start on all of space has a smooth solution
with bounded energy for all time. -/
def VersionA (ν : ℝ) : Prop :=
  ∀ u0, AdmissibleStartR3 u0 →
    ∃ p u, SolvesNS ν u0 (fun _ _ => 0) p u ∧ SmoothOnHalfSpace p u ∧ BoundedEnergy u

/-- Version B: with no force, every admissible start in the repeating cube has a smooth
repeating solution for all time. -/
def VersionB (ν : ℝ) : Prop :=
  ∀ u0, AdmissibleStartT3 u0 → ∃ p u, SolvesNS ν u0 (fun _ _ => 0) p u ∧ PeriodicSmooth p u

/-- Version C: some admissible start and force on all of space have no smooth solution with
bounded energy for all time. -/
def VersionC (ν : ℝ) : Prop :=
  ∃ u0 f, AdmissibleStartR3 u0 ∧ AdmissibleForceR3 f ∧
    ¬∃ p u, SolvesNS ν u0 f p u ∧ SmoothOnHalfSpace p u ∧ BoundedEnergy u

/-- Version D: some admissible start and force in the repeating cube have no smooth repeating
solution for all time. -/
def VersionD (ν : ℝ) : Prop :=
  ∃ u0 f, AdmissibleStartT3 u0 ∧ AdmissibleForceT3 f ∧
    ¬∃ p u, SolvesNS ν u0 f p u ∧ PeriodicSmooth p u

/-- The Clay problem always has a true answer to prove: for every positive viscosity, version A
or version C is true on all of space, and version B or version D is true in the repeating cube.
The reason is that zero is an allowed force, so a start that breaks down with no force already
proves C (or D). -/
theorem clay_versions_A_or_C_and_B_or_D (ν : ℝ) (hν : 0 < ν) :
    (VersionA ν ∨ VersionC ν) ∧ (VersionB ν ∨ VersionD ν) := by
  have hz : ∀ (n K : ℕ) (x : E3) (t : ℝ),
      ‖iteratedFDerivWithin ℝ n (fun q : E3 × ℝ => (fun _ _ => (0 : E3)) q.1 q.2) halfSpace (x, t)‖
        ≤ 0 / (1 + ‖x‖ + t) ^ K ∧
      ‖iteratedFDerivWithin ℝ n (fun q : E3 × ℝ => (fun _ _ => (0 : E3)) q.1 q.2) halfSpace (x, t)‖
        ≤ 0 / (1 + t) ^ K := by
    intro n K x t
    rcases n with _ | n
    · simp
    · simp [iteratedFDerivWithin_const_of_ne (Nat.succ_ne_zero n)]
  have zR : AdmissibleForceR3 (fun _ _ => 0) :=
    ⟨contDiffOn_const, fun n K => ⟨0, fun x t _ => (hz n K x t).1⟩⟩
  have zT : AdmissibleForceT3 (fun _ _ => 0) :=
    ⟨contDiffOn_const, fun _ _ _ => rfl, fun n K => ⟨0, fun x t _ => (hz n K x t).2⟩⟩
  constructor
  · by_cases hA : VersionA ν
    · exact Or.inl hA
    · right
      obtain ⟨u0, h⟩ := not_forall.mp hA
      obtain ⟨hu0, hno⟩ := not_imp.mp h
      exact ⟨u0, fun _ _ => 0, hu0, zR, hno⟩
  · by_cases hB : VersionB ν
    · exact Or.inl hB
    · right
      obtain ⟨u0, h⟩ := not_forall.mp hB
      obtain ⟨hu0, hno⟩ := not_imp.mp h
      exact ⟨u0, fun _ _ => 0, hu0, zT, hno⟩

/-- The toy world: `D` starts, `F` forces with force `0` the zero force, and a world is the set
of (start, force) pairs that break down. `A` holds when no start breaks with force `0`. -/
abbrev toyA {D F : ℕ} [NeZero F] (W : Finset (Fin D × Fin F)) : Prop :=
  ∀ d : Fin D, (d, (0 : Fin F)) ∉ W

/-- In the toy world, `C` holds when some (start, force) pair breaks down. -/
abbrev toyC {D F : ℕ} (W : Finset (Fin D × Fin F)) : Prop := W.Nonempty

/-- In the toy world, `A` holds exactly when no broken pair uses force `0`. -/
theorem toyA_iff_subset {D F : ℕ} [NeZero F] (W : Finset (Fin D × Fin F)) :
    toyA W ↔ W ⊆ (Finset.univ : Finset (Fin D)) ×ˢ (Finset.univ.erase (0 : Fin F)) := by
  constructor
  · intro h p hp
    simp only [Finset.mem_product, Finset.mem_univ, Finset.mem_erase, ne_eq, and_true, true_and]
    intro h0
    have hp' : (p.1, (0 : Fin F)) = p := Prod.ext rfl h0.symm
    exact h p.1 (hp'.symm ▸ hp)
  · intro h d hd
    have := h hd
    simp at this

/-- The toy-world count: of the `2^(D F)` worlds, none has both A and C false, one has A only,
`2^(D F) − 2^(D (F − 1))` have C only, and `2^(D (F − 1)) − 1` have A and C both true. -/
theorem toy_world_counts (D F : ℕ) [NeZero F] :
    (Finset.univ.filter fun W : Finset (Fin D × Fin F) => ¬toyA W ∧ ¬toyC W).card = 0 ∧
    (Finset.univ.filter fun W : Finset (Fin D × Fin F) => toyA W ∧ ¬toyC W).card = 1 ∧
    (Finset.univ.filter fun W : Finset (Fin D × Fin F) => ¬toyA W ∧ toyC W).card
      = 2 ^ (D * F) - 2 ^ (D * (F - 1)) ∧
    (Finset.univ.filter fun W : Finset (Fin D × Fin F) => toyA W ∧ toyC W).card
      = 2 ^ (D * (F - 1)) - 1 := by
  set T : Finset (Fin D × Fin F) := (Finset.univ : Finset (Fin D)) ×ˢ (Finset.univ.erase 0)
    with hTdef
  have hT : T.card = D * (F - 1) := by
    simp [hTdef, Finset.card_product, Finset.card_erase_of_mem]
  have hAll : Fintype.card (Finset (Fin D × Fin F)) = 2 ^ (D * F) := by
    simp [Fintype.card_finset, Fintype.card_prod]
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    rintro W - ⟨hA, hC⟩
    rw [Finset.not_nonempty_iff_eq_empty] at hC
    subst hC
    exact hA fun d hd => by simp at hd
  · rw [Finset.card_eq_one]
    refine ⟨∅, ?_⟩
    ext W
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_singleton,
      Finset.not_nonempty_iff_eq_empty]
    constructor
    · exact fun h => h.2
    · rintro rfl
      exact ⟨fun d hd => by simp at hd, rfl⟩
  · have hset : (Finset.univ.filter fun W : Finset (Fin D × Fin F) => ¬toyA W ∧ toyC W)
        = Finset.univ \ T.powerset := by
      ext W
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_sdiff,
        Finset.mem_powerset, toyA_iff_subset]
      constructor
      · exact fun h => h.1
      · intro h
        refine ⟨h, ?_⟩
        show W.Nonempty
        rw [Finset.nonempty_iff_ne_empty]
        rintro rfl
        exact h (Finset.empty_subset _)
    rw [hset, Finset.card_univ_sdiff, Finset.card_powerset, hT, hAll]
  · have hset : (Finset.univ.filter fun W : Finset (Fin D × Fin F) => toyA W ∧ toyC W)
        = T.powerset.erase ∅ := by
      ext W
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_erase,
        Finset.mem_powerset, toyA_iff_subset, Finset.nonempty_iff_ne_empty]
      exact and_comm
    rw [hset, Finset.card_erase_of_mem (Finset.empty_mem_powerset _), Finset.card_powerset, hT]

/-- The Taylor-Green velocity `u = (sin 2πx cos 2πy, −cos 2πx sin 2πy, 0) e^(−8π²νt)`. -/
noncomputable def tgU (ν : ℝ) (v : E3) (t : ℝ) : E3 :=
  !₂[Real.sin (2 * Real.pi * v 0) * Real.cos (2 * Real.pi * v 1) *
        Real.exp (-8 * Real.pi ^ 2 * ν * t),
     -(Real.cos (2 * Real.pi * v 0) * Real.sin (2 * Real.pi * v 1)) *
        Real.exp (-8 * Real.pi ^ 2 * ν * t),
     0]

/-- The Taylor-Green pressure `p = ¼ (cos 4πx + cos 4πy) e^(−16π²νt)`. -/
noncomputable def tgP (ν : ℝ) (v : E3) (t : ℝ) : ℝ :=
  (1 / 4) * (Real.cos (4 * Real.pi * v 0) + Real.cos (4 * Real.pi * v 1)) *
    Real.exp (-16 * Real.pi ^ 2 * ν * t)

/-- Derivative of `v ↦ φ(v₀) ψ(v₁)`. -/
theorem hasFDerivAt_prodForm {φ φ' ψ ψ' : ℝ → ℝ}
    (hφ : ∀ a, HasDerivAt φ (φ' a) a) (hψ : ∀ b, HasDerivAt ψ (ψ' b) b) (x : E3) :
    HasFDerivAt (fun v : E3 => φ (v 0) * ψ (v 1))
      ((φ' (x 0) * ψ (x 1)) • (EuclideanSpace.proj (0 : Fin 3) : E3 →L[ℝ] ℝ) +
        (φ (x 0) * ψ' (x 1)) • (EuclideanSpace.proj (1 : Fin 3) : E3 →L[ℝ] ℝ)) x := by
  have h0 : HasFDerivAt (fun v : E3 => φ (v 0))
      (φ' (x 0) • (EuclideanSpace.proj (0 : Fin 3) : E3 →L[ℝ] ℝ)) x :=
    (hφ (x 0)).comp_hasFDerivAt x (PiLp.hasFDerivAt_apply 2 x 0)
  have h1 : HasFDerivAt (fun v : E3 => ψ (v 1))
      (ψ' (x 1) • (EuclideanSpace.proj (1 : Fin 3) : E3 →L[ℝ] ℝ)) x :=
    (hψ (x 1)).comp_hasFDerivAt x (PiLp.hasFDerivAt_apply 2 x 1)
  convert h0.fun_mul h1 using 1
  ext w
  simp
  ring

/-- Derivative of `v ↦ φ(v₀) + ψ(v₁)`. -/
theorem hasFDerivAt_sumForm {φ φ' ψ ψ' : ℝ → ℝ}
    (hφ : ∀ a, HasDerivAt φ (φ' a) a) (hψ : ∀ b, HasDerivAt ψ (ψ' b) b) (x : E3) :
    HasFDerivAt (fun v : E3 => φ (v 0) + ψ (v 1))
      (φ' (x 0) • (EuclideanSpace.proj (0 : Fin 3) : E3 →L[ℝ] ℝ) +
        ψ' (x 1) • (EuclideanSpace.proj (1 : Fin 3) : E3 →L[ℝ] ℝ)) x :=
  ((hφ (x 0)).comp_hasFDerivAt x (PiLp.hasFDerivAt_apply 2 x 0)).fun_add
    ((hψ (x 1)).comp_hasFDerivAt x (PiLp.hasFDerivAt_apply 2 x 1))

theorem fderiv_prodForm {φ φ' ψ ψ' : ℝ → ℝ}
    (hφ : ∀ a, HasDerivAt φ (φ' a) a) (hψ : ∀ b, HasDerivAt ψ (ψ' b) b) (x w : E3) :
    fderiv ℝ (fun v : E3 => φ (v 0) * ψ (v 1)) x w
      = φ' (x 0) * ψ (x 1) * w 0 + φ (x 0) * ψ' (x 1) * w 1 := by
  rw [(hasFDerivAt_prodForm hφ hψ x).fderiv]
  simp

theorem fderiv_sumForm {φ φ' ψ ψ' : ℝ → ℝ}
    (hφ : ∀ a, HasDerivAt φ (φ' a) a) (hψ : ∀ b, HasDerivAt ψ (ψ' b) b) (x w : E3) :
    fderiv ℝ (fun v : E3 => φ (v 0) + ψ (v 1)) x w = φ' (x 0) * w 0 + ψ' (x 1) * w 1 := by
  rw [(hasFDerivAt_sumForm hφ hψ x).fderiv]
  simp

theorem laplacian_prodForm {φ φ' φ'' ψ ψ' ψ'' : ℝ → ℝ}
    (hφ : ∀ a, HasDerivAt φ (φ' a) a) (hφ' : ∀ a, HasDerivAt φ' (φ'' a) a)
    (hψ : ∀ b, HasDerivAt ψ (ψ' b) b) (hψ' : ∀ b, HasDerivAt ψ' (ψ'' b) b) (x : E3) :
    Δ (fun v : E3 => φ (v 0) * ψ (v 1)) x = φ'' (x 0) * ψ (x 1) + φ (x 0) * ψ'' (x 1) := by
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis _
    (EuclideanSpace.basisFun (Fin 3) ℝ)]
  simp only [iteratedFDeriv_two_apply]
  have hD : fderiv ℝ (fun v : E3 => φ (v 0) * ψ (v 1)) = fun y =>
      (φ' (y 0) * ψ (y 1)) • (EuclideanSpace.proj (0 : Fin 3) : E3 →L[ℝ] ℝ) +
        (φ (y 0) * ψ' (y 1)) • (EuclideanSpace.proj (1 : Fin 3) : E3 →L[ℝ] ℝ) := by
    funext y
    exact (hasFDerivAt_prodForm hφ hψ y).fderiv
  have hDD := ((hasFDerivAt_prodForm hφ' hψ x).smul_const
      (EuclideanSpace.proj (0 : Fin 3) : E3 →L[ℝ] ℝ)).fun_add
    ((hasFDerivAt_prodForm hφ hψ' x).smul_const (EuclideanSpace.proj (1 : Fin 3) : E3 →L[ℝ] ℝ))
  rw [hD, hDD.fderiv]
  simp [Fin.sum_univ_three, EuclideanSpace.basisFun_apply]

theorem fderiv_apply_coord {f : E3 → E3} {x : E3} (hf : DifferentiableAt ℝ f x) (w : E3)
    (i : Fin 3) : fderiv ℝ f x w i = fderiv ℝ (fun y => f y i) x w := by
  have h := ((EuclideanSpace.proj i : E3 →L[ℝ] ℝ).hasFDerivAt.comp x hf.hasFDerivAt).fderiv
  have h2 : (⇑(EuclideanSpace.proj i : E3 →L[ℝ] ℝ) ∘ f) = fun y => f y i := rfl
  rw [h2] at h
  rw [h]
  rfl

theorem laplacian_apply_coord {f : E3 → E3} {x : E3} (hf : ContDiffAt ℝ 2 f x) (i : Fin 3) :
    Δ f x i = Δ (fun y => f y i) x :=
  (hf.laplacian_CLM_comp_left (l := (EuclideanSpace.proj i : E3 →L[ℝ] ℝ))).symm

theorem gradient_apply_coord (g : E3 → ℝ) (x : E3) (i : Fin 3) :
    ∇ g x i = fderiv ℝ g x (EuclideanSpace.single i 1) := by
  rw [← inner_gradient_left, EuclideanSpace.inner_single_right]
  simp

theorem deriv_apply_coord {f : ℝ → E3} {t : ℝ} (hf : DifferentiableAt ℝ f t) (i : Fin 3) :
    deriv f t i = deriv (fun s => f s i) t :=
  ((EuclideanSpace.proj i : E3 →L[ℝ] ℝ).hasFDerivAt.comp_hasDerivAt t hf.hasDerivAt).deriv.symm

theorem divergence_eq_sum {f : E3 → E3} {x : E3} (hf : DifferentiableAt ℝ f x) :
    divergence f x = ∑ i, fderiv ℝ (fun y => f y i) x (EuclideanSpace.single i 1) := by
  unfold divergence
  rw [LinearMap.trace_eq_sum_inner _ (EuclideanSpace.basisFun (Fin 3) ℝ)]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [EuclideanSpace.basisFun_apply, EuclideanSpace.inner_single_left]
  simp [fderiv_apply_coord hf]

theorem hasDerivAt_sinForm (c k a : ℝ) :
    HasDerivAt (fun a => c * Real.sin (k * a)) ((c * k) * Real.cos (k * a)) a := by
  have := (((hasDerivAt_id' a).const_mul k).sin).const_mul c
  convert this using 1
  ring

theorem hasDerivAt_cosForm (c k a : ℝ) :
    HasDerivAt (fun a => c * Real.cos (k * a)) (-(c * k) * Real.sin (k * a)) a := by
  have := (((hasDerivAt_id' a).const_mul k).cos).const_mul c
  convert this using 1
  ring

theorem hasDerivAt_expForm (c r s : ℝ) :
    HasDerivAt (fun s => c * Real.exp (r * s)) (c * r * Real.exp (r * s)) s := by
  have := (((hasDerivAt_id' s).const_mul r).exp).const_mul c
  convert this using 1
  ring

theorem tgU_contDiff (ν : ℝ) : ContDiff ℝ ∞ (fun q : E3 × ℝ => tgU ν q.1 q.2) := by
  rw [contDiff_piLp]
  intro i
  fin_cases i <;> simp [tgU] <;> fun_prop

theorem tgP_contDiff (ν : ℝ) : ContDiff ℝ ∞ (fun q : E3 × ℝ => tgP ν q.1 q.2) := by
  unfold tgP
  fun_prop

theorem tgU_space_contDiff (ν t : ℝ) : ContDiff ℝ ∞ (fun y => tgU ν y t) := by
  rw [contDiff_piLp]
  intro i
  fin_cases i <;> simp [tgU] <;> fun_prop

theorem tgU_time_contDiff (ν : ℝ) (x : E3) : ContDiff ℝ ∞ (fun s => tgU ν x s) := by
  rw [contDiff_piLp]
  intro i
  fin_cases i <;> simp [tgU] <;> fun_prop

theorem tgU_coord0 (ν t : ℝ) : (fun y => tgU ν y t 0) = fun y =>
    (Real.exp (-8 * Real.pi ^ 2 * ν * t) * Real.sin (2 * Real.pi * y 0)) *
      (1 * Real.cos (2 * Real.pi * y 1)) := by
  funext y
  simp [tgU]
  ring

theorem tgU_coord1 (ν t : ℝ) : (fun y => tgU ν y t 1) = fun y =>
    (-Real.exp (-8 * Real.pi ^ 2 * ν * t) * Real.cos (2 * Real.pi * y 0)) *
      (1 * Real.sin (2 * Real.pi * y 1)) := by
  funext y
  simp [tgU]
  ring

theorem tgU_coord2 (ν t : ℝ) : (fun y => tgU ν y t 2) = fun _ => 0 := by
  funext y
  simp [tgU]

theorem tgP_sumForm (ν t : ℝ) : (fun y => tgP ν y t) = fun y =>
    (1 / 4 * Real.exp (-16 * Real.pi ^ 2 * ν * t)) * Real.cos (4 * Real.pi * y 0) +
      (1 / 4 * Real.exp (-16 * Real.pi ^ 2 * ν * t)) * Real.cos (4 * Real.pi * y 1) := by
  funext y
  simp [tgP]
  ring

theorem tgU_divergence (ν t : ℝ) (x : E3) : divergence (fun y => tgU ν y t) x = 0 := by
  rw [divergence_eq_sum ((tgU_space_contDiff ν t).differentiable (by simp) x),
    Fin.sum_univ_three, tgU_coord0, tgU_coord1, tgU_coord2,
    fderiv_prodForm (hasDerivAt_sinForm _ _) (hasDerivAt_cosForm _ _),
    fderiv_prodForm (hasDerivAt_cosForm _ _) (hasDerivAt_sinForm _ _)]
  simp
  ring

theorem sin_two_pi_add_one (a : ℝ) :
    Real.sin (2 * Real.pi * (a + 1)) = Real.sin (2 * Real.pi * a) := by
  rw [mul_add, mul_one, Real.sin_add_two_pi]

theorem cos_two_pi_add_one (a : ℝ) :
    Real.cos (2 * Real.pi * (a + 1)) = Real.cos (2 * Real.pi * a) := by
  rw [mul_add, mul_one, Real.cos_add_two_pi]

theorem cos_four_pi_add_one (a : ℝ) :
    Real.cos (4 * Real.pi * (a + 1)) = Real.cos (4 * Real.pi * a) := by
  have h : 4 * Real.pi * (a + 1) = 4 * Real.pi * a + (2 : ℕ) * (2 * Real.pi) := by
    push_cast; ring
  rw [h, Real.cos_add_nat_mul_two_pi]

theorem tgU_periodic (ν t : ℝ) (x : E3) (j : Fin 3) :
    tgU ν (x + unitVec j) t = tgU ν x t := by
  ext i
  fin_cases i <;> fin_cases j <;>
    simp [tgU, unitVec, sin_two_pi_add_one, cos_two_pi_add_one]

theorem tgP_periodic (ν t : ℝ) (x : E3) (j : Fin 3) :
    tgP ν (x + unitVec j) t = tgP ν x t := by
  fin_cases j <;> simp [tgP, unitVec, cos_four_pi_add_one]

theorem tgU_time0 (ν : ℝ) (x : E3) : (fun s => tgU ν x s 0) = fun s =>
    (Real.sin (2 * Real.pi * x 0) * Real.cos (2 * Real.pi * x 1)) *
      Real.exp ((-8 * Real.pi ^ 2 * ν) * s) := by
  funext s
  simp [tgU]

theorem tgU_time1 (ν : ℝ) (x : E3) : (fun s => tgU ν x s 1) = fun s =>
    (-(Real.cos (2 * Real.pi * x 0) * Real.sin (2 * Real.pi * x 1))) *
      Real.exp ((-8 * Real.pi ^ 2 * ν) * s) := by
  funext s
  simp [tgU]

theorem tgU_time2 (ν : ℝ) (x : E3) : (fun s => tgU ν x s 2) = fun _ => 0 := by
  funext s
  simp [tgU]

theorem tgU_momentum (ν t : ℝ) (x : E3) :
    deriv (fun s => tgU ν x s) t + fderiv ℝ (fun y => tgU ν y t) x (tgU ν x t)
      = ν • Δ (fun y => tgU ν y t) x - ∇ (fun y => tgP ν y t) x + (fun _ _ => (0 : E3)) x t := by
  have hdt := (tgU_time_contDiff ν x).differentiable (by simp) t
  have hdx := (tgU_space_contDiff ν t).differentiable (by simp) x
  have hcx : ContDiffAt ℝ 2 (fun y => tgU ν y t) x :=
    ((tgU_space_contDiff ν t).of_le (by simp)).contDiffAt
  have hE2 : Real.exp (-16 * Real.pi ^ 2 * ν * t) = Real.exp (-8 * Real.pi ^ 2 * ν * t) ^ 2 := by
    rw [← Real.exp_nat_mul]
    congr 1
    push_cast
    ring
  have hs4 : ∀ a : ℝ, Real.sin (4 * Real.pi * a)
      = 2 * Real.sin (2 * Real.pi * a) * Real.cos (2 * Real.pi * a) := by
    intro a
    rw [← Real.sin_two_mul]
    ring_nf
  ext i
  simp only [PiLp.add_apply, PiLp.sub_apply, PiLp.smul_apply, smul_eq_mul, PiLp.zero_apply]
  rw [deriv_apply_coord hdt, fderiv_apply_coord hdx, laplacian_apply_coord hcx,
    gradient_apply_coord, tgP_sumForm,
    fderiv_sumForm (hasDerivAt_cosForm _ _) (hasDerivAt_cosForm _ _)]
  fin_cases i
  · simp only [Fin.zero_eta, Fin.isValue]
    rw [tgU_coord0, tgU_time0, (hasDerivAt_expForm _ _ t).deriv,
      fderiv_prodForm (hasDerivAt_sinForm _ _) (hasDerivAt_cosForm _ _),
      laplacian_prodForm (hasDerivAt_sinForm _ _) (hasDerivAt_cosForm _ _)
        (hasDerivAt_cosForm _ _) (hasDerivAt_sinForm _ _)]
    rw [hE2]
    simp [tgU, hs4]
    linear_combination (2 * Real.pi * Real.sin (2 * Real.pi * x 0) * Real.cos (2 * Real.pi * x 0) *
      Real.exp (-(8 * Real.pi ^ 2 * ν * t)) ^ 2) * Real.sin_sq_add_cos_sq (2 * Real.pi * x 1)
  · simp only [Fin.mk_one, Fin.isValue]
    rw [tgU_coord1, tgU_time1, (hasDerivAt_expForm _ _ t).deriv,
      fderiv_prodForm (hasDerivAt_cosForm _ _) (hasDerivAt_sinForm _ _),
      laplacian_prodForm (hasDerivAt_cosForm _ _) (hasDerivAt_sinForm _ _)
        (hasDerivAt_sinForm _ _) (hasDerivAt_cosForm _ _)]
    rw [hE2]
    simp [tgU, hs4]
    linear_combination (2 * Real.pi * Real.sin (2 * Real.pi * x 1) * Real.cos (2 * Real.pi * x 1) *
      Real.exp (-(8 * Real.pi ^ 2 * ν * t)) ^ 2) * Real.sin_sq_add_cos_sq (2 * Real.pi * x 0)
  · simp only [Fin.reduceFinMk, Fin.isValue]
    rw [tgU_coord2, tgU_time2]
    simp

/-- The Taylor-Green flow is an exact smooth solution for all time in the repeating cube: its
start is an admissible version B start, and with no force it solves (1), (2), (3) and
satisfies (10), (11). One solved start is evidence, not a proof of version B. -/
theorem taylor_green_solves_navier_stokes (ν : ℝ) (hν : 0 < ν) :
    AdmissibleStartT3 (fun v => tgU ν v 0) ∧
    SolvesNS ν (fun v => tgU ν v 0) (fun _ _ => 0) (tgP ν) (tgU ν) ∧
    PeriodicSmooth (tgP ν) (tgU ν) := by
  refine ⟨⟨tgU_space_contDiff ν 0, fun x => tgU_divergence ν 0 x, fun x j => tgU_periodic ν 0 x j⟩,
    ⟨fun x t _ => tgU_momentum ν t x, fun x t _ => tgU_divergence ν t x, fun x => rfl⟩,
    ⟨⟨(tgP_contDiff ν).contDiffOn, (tgU_contDiff ν).contDiffOn⟩,
      fun x t j _ => ⟨tgU_periodic ν t x j, tgP_periodic ν t x j⟩⟩⟩

end NavierStokesClay

open NavierStokesClay

/-- The card's toy world with 2 starts and 2 forces: of 16 worlds, 3 have A and C both true,
1 has A only, 12 have C only, and none has neither. -/
example :
    Fintype.card (Finset (Fin 2 × Fin 2)) = 16 ∧
    (Finset.univ.filter fun W : Finset (Fin 2 × Fin 2) => toyA W ∧ toyC W).card = 3 ∧
    (Finset.univ.filter fun W : Finset (Fin 2 × Fin 2) => toyA W ∧ ¬toyC W).card = 1 ∧
    (Finset.univ.filter fun W : Finset (Fin 2 × Fin 2) => ¬toyA W ∧ toyC W).card = 12 ∧
    (Finset.univ.filter fun W : Finset (Fin 2 × Fin 2) => ¬toyA W ∧ ¬toyC W).card = 0 := by
  decide

/-- With 3 starts and 3 forces there are 512 worlds, and `2^6 − 1 = 63` have A and C both true
(the formula of `toy_world_counts`). -/
example : 2 ^ (3 * 3) = 512 ∧ 2 ^ (3 * (3 - 1)) - 1 = 63 := by norm_num

/-- The Taylor-Green flow read on all of space: energy 1/4 per unit cell, so 250,000 in
`100^3` cells. -/
example : (100 : ℚ) ^ 3 * (1 / 4) = 250000 := by norm_num

namespace NavierStokesClay

#print axioms toyA_iff_subset
#print axioms hasFDerivAt_prodForm
#print axioms hasFDerivAt_sumForm
#print axioms fderiv_prodForm
#print axioms fderiv_sumForm
#print axioms laplacian_prodForm
#print axioms fderiv_apply_coord
#print axioms laplacian_apply_coord
#print axioms gradient_apply_coord
#print axioms deriv_apply_coord
#print axioms divergence_eq_sum
#print axioms hasDerivAt_sinForm
#print axioms hasDerivAt_cosForm
#print axioms hasDerivAt_expForm
#print axioms tgU_contDiff
#print axioms tgP_contDiff
#print axioms tgU_space_contDiff
#print axioms tgU_time_contDiff
#print axioms tgU_coord0
#print axioms tgU_coord1
#print axioms tgU_coord2
#print axioms tgP_sumForm
#print axioms tgU_divergence
#print axioms sin_two_pi_add_one
#print axioms cos_two_pi_add_one
#print axioms cos_four_pi_add_one
#print axioms tgU_periodic
#print axioms tgP_periodic
#print axioms tgU_time0
#print axioms tgU_time1
#print axioms tgU_time2
#print axioms tgU_momentum
#print axioms clay_versions_A_or_C_and_B_or_D
#print axioms toy_world_counts
#print axioms taylor_green_solves_navier_stokes

end NavierStokesClay
