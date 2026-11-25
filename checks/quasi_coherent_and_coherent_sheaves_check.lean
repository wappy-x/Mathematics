-- Quasi-coherent sheaves: the sheaf of a module on Spec R is quasi-coherent with sections M_f over D(f), stalks M_p and global sections M, the forms of degree d in two variables have dimension max(d + 1, 0), and the ideal of a point of the projective line is the polynomial ring shifted by -1.
import Mathlib.AlgebraicGeometry.Modules.Tilde
import Mathlib.RingTheory.MvPolynomial.WeightedHomogeneous
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.LinearAlgebra.Dimension.Constructions
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas

universe u

open AlgebraicGeometry MvPolynomial

lemma weight_one_fin2 (f : Fin 2 →₀ ℕ) :
    Finsupp.weight (fun _ : Fin 2 => (1 : ℤ)) f = (f 0 : ℤ) + f 1 := by
  rw [Finsupp.weight_apply, Finsupp.sum_fintype _ _ (by simp)]
  simp [Fin.sum_univ_two]

noncomputable def degSetEquiv (d : ℤ) :
    {f : Fin 2 →₀ ℕ | Finsupp.weight (fun _ : Fin 2 => (1 : ℤ)) f = d} ≃ Fin (d + 1).toNat where
  toFun f := ⟨f.1 0, by
    have h := f.2
    simp only [Set.mem_ofPred_eq, weight_one_fin2] at h
    omega⟩
  invFun i := ⟨Finsupp.single 0 (i : ℕ) + Finsupp.single 1 ((d + 1).toNat - 1 - i), by
    have := i.2
    simp only [Set.mem_ofPred_eq, weight_one_fin2]
    simp
    omega⟩
  left_inv f := by
    have h := f.2
    simp only [Set.mem_ofPred_eq, weight_one_fin2] at h
    apply Subtype.ext
    ext j
    fin_cases j <;> simp; omega
  right_inv i := by
    ext
    simp

lemma forms_finite (k : Type u) [Field k] (d : ℤ) :
    FiniteDimensional k (weightedHomogeneousSubmodule k (fun _ : Fin 2 => (1 : ℤ)) d) :=
  Module.Finite.equiv ((LinearEquiv.ofEq _ _
    (weightedHomogeneousSubmodule_eq_finsupp_supported k (fun _ : Fin 2 => (1 : ℤ)) d)).trans
    ((AddMonoidAlgebra.supportedEquivFinsupp _).trans (Finsupp.domLCongr (degSetEquiv d)))).symm

lemma line_ne_zero (k : Type u) [Field k] (a b : k) (hP : (a, b) ≠ (0, 0)) :
    (C b * X 0 - C a * X 1 : MvPolynomial (Fin 2) k) ≠ 0 := by
  intro h
  apply hP
  have h0 := congrArg (MvPolynomial.eval ![1, 0]) h
  have h1 := congrArg (MvPolynomial.eval ![0, 1]) h
  simp at h0 h1
  simp [h0, h1]

#print axioms weight_one_fin2
#print axioms degSetEquiv
#print axioms forms_finite
#print axioms line_ne_zero

/-- The sheaf of a module. For a commutative ring `R` with 1 and any `R`-module `M`, the sheaf
`M~` on `Spec R` is quasi-coherent; its sections over the open set `D(f)` where `f` is not zero
are the fractions `M_f` (the map from `M` is a localisation at the powers of `f`); its stalk at
a prime `𝔭` is `M_𝔭` (a localisation at the complement of `𝔭`); and its global sections are
`M` itself (the map from `M` is a bijection). -/
theorem tilde_sections_stalks_and_global_sections (R : CommRingCat.{u}) (M : ModuleCat.{u} R) :
    (tilde M).IsQuasicoherent ∧
    (∀ f : R, IsLocalizedModule (Submonoid.powers f)
      (tilde.toOpen M (PrimeSpectrum.basicOpen f)).hom) ∧
    (∀ x : PrimeSpectrum.Top R, IsLocalizedModule x.asIdeal.primeCompl (tilde.toStalk M x).hom) ∧
    Function.Bijective (tilde.toOpen M ⊤).hom := by
  refine ⟨inferInstance, fun f => inferInstance, fun x => inferInstance, ?_⟩
  exact CategoryTheory.ConcreteCategory.bijective_of_isIso (tilde.toOpen M ⊤)

/-- The global sections of `𝒪(d)` on the projective line over a field `k` are the degree-zero
part of the shifted module `S(d)`, that is the forms of degree `d` in `x` and `y`. With degrees
read as whole numbers (every variable of weight 1), this space has dimension `d + 1` when
`d ≥ 0` and `0` when `d < 0`. -/
theorem finrank_forms_of_degree_eq_twist_sections (k : Type u) [Field k] (d : ℤ) :
    Module.finrank k (weightedHomogeneousSubmodule k (fun _ : Fin 2 => (1 : ℤ)) d) =
      (d + 1).toNat := by
  rw [weightedHomogeneousSubmodule_eq_finsupp_supported,
    (AddMonoidAlgebra.supportedEquivFinsupp _).finrank_eq,
    (Finsupp.domLCongr (degSetEquiv d)).finrank_eq, Module.finrank_finsupp_self, Fintype.card_fin]

/-- The ideal of a point is `S(-1)`. Let `P = (a : b)` be a point of the projective line over a
field `k` (so `a` and `b` are not both zero), and `ℓ = b x - a y` the line through it. In every
degree `n`, multiplying by `ℓ` sends the forms of degree `n - 1` onto exactly the forms of
degree `n` that vanish at `P`, and loses nothing. So the graded ideal of `P` is `S(-1)`, and the
ideal sheaf of `P` is `𝒪(-1)`; in degree 0 it says no nonzero constant vanishes at `P`. -/
theorem ideal_of_point_eq_shift_minus_one (k : Type u) [Field k] (a b : k)
    (hP : (a, b) ≠ (0, 0)) :
    Function.Injective (LinearMap.mulLeft k (C b * X 0 - C a * X 1 : MvPolynomial (Fin 2) k)) ∧
    ∀ n : ℤ,
      (weightedHomogeneousSubmodule k (fun _ : Fin 2 => (1 : ℤ)) (n - 1)).map
          (LinearMap.mulLeft k (C b * X 0 - C a * X 1 : MvPolynomial (Fin 2) k)) =
        weightedHomogeneousSubmodule k (fun _ : Fin 2 => (1 : ℤ)) n ⊓
          LinearMap.ker (MvPolynomial.aeval ![a, b] : MvPolynomial (Fin 2) k →ₐ[k] k).toLinearMap := by
  set ℓ : MvPolynomial (Fin 2) k := C b * X 0 - C a * X 1 with hℓ
  have hinj : Function.Injective (LinearMap.mulLeft k ℓ) := by
    intro p q hpq
    exact mul_left_cancel₀ (line_ne_zero k a b hP) hpq
  refine ⟨hinj, fun n => ?_⟩
  set w : Fin 2 → ℤ := fun _ => 1
  set F := weightedHomogeneousSubmodule k w n
  set T := F ⊓ LinearMap.ker (MvPolynomial.aeval ![a, b] : MvPolynomial (Fin 2) k →ₐ[k] k).toLinearMap
  have hℓhom : ℓ.IsWeightedHomogeneous w 1 := by
    apply IsWeightedHomogeneous.sub
    · simpa using (isWeightedHomogeneous_X k w 0).C_mul b
    · simpa using (isWeightedHomogeneous_X k w 1).C_mul a
  have hle : (weightedHomogeneousSubmodule k w (n - 1)).map (LinearMap.mulLeft k ℓ) ≤ T := by
    rintro _ ⟨p, hp, rfl⟩
    refine ⟨?_, ?_⟩
    · have := hℓhom.mul hp
      rw [add_sub_cancel] at this
      exact this
    · simp [hℓ]
      left
      ring
  have hFfin : Module.finrank k F = (n + 1).toNat := finrank_forms_of_degree_eq_twist_sections k n
  have hmap : Module.finrank k ((weightedHomogeneousSubmodule k w (n - 1)).map
      (LinearMap.mulLeft k ℓ)) = n.toNat := by
    rw [← (Submodule.equivMapOfInjective _ hinj _).finrank_eq,
      finrank_forms_of_degree_eq_twist_sections k (n - 1)]
    congr 1
    ring
  have : FiniteDimensional k F := forms_finite k n
  have : FiniteDimensional k T := Submodule.finiteDimensional_of_le inf_le_left
  refine Submodule.eq_of_le_of_finrank_le hle ?_
  rw [hmap]
  rcases lt_or_ge n 0 with hn | hn
  · have hF0 : F = ⊥ := by
      rw [← Submodule.finrank_eq_zero, hFfin]
      omega
    have hT0 : T = ⊥ := le_bot_iff.mp (hF0 ▸ inf_le_left)
    rw [hT0, finrank_bot]
    exact Nat.zero_le _
  · have key : ∃ p ∈ F, MvPolynomial.aeval ![a, b] p ≠ 0 := by
      by_cases ha : a = 0
      · have hb : b ≠ 0 := by
          intro hb
          exact hP (by simp [ha, hb])
        refine ⟨X 1 ^ n.toNat, ?_, ?_⟩
        · have h := (isWeightedHomogeneous_X k w 1).pow n.toNat
          have hdeg : n.toNat • w 1 = n := by
            simp [w]
            omega
          rw [hdeg] at h
          exact h
        · simp [hb]
      · refine ⟨X 0 ^ n.toNat, ?_, ?_⟩
        · have h := (isWeightedHomogeneous_X k w 0).pow n.toNat
          have hdeg : n.toNat • w 0 = n := by
            simp [w]
            omega
          rw [hdeg] at h
          exact h
        · simp [ha]
    have hlt : T < F := by
      refine lt_of_le_of_ne inf_le_left ?_
      intro hTF
      obtain ⟨p, hpF, hp⟩ := key
      have hpT : p ∈ T := hTF ▸ hpF
      exact hp (LinearMap.mem_ker.mp hpT.2)
    have := Submodule.finrank_lt_finrank_of_lt hlt
    omega

/-! ### The card's worked numbers -/

-- Stalk at (2): the odd bottoms 1, 3, 5 kill 0, 2, 4 in ℤ/6, so 6 / 3 = 2 survive: ℤ/2.
example : (Finset.univ.filter fun m : ZMod 6 =>
    ∃ s ∈ ({1, 3, 5} : Finset (ZMod 6)), s * m = 0).card = 3 := by decide
-- Stalk at (3): the bottoms 1, 2, 4, 5 kill 0 and 3, so 6 / 2 = 3 survive: ℤ/3.
example : (Finset.univ.filter fun m : ZMod 6 =>
    ∃ s ∈ ({1, 2, 4, 5} : Finset (ZMod 6)), s * m = 0).card = 2 := by decide
-- Sections over D(2): the powers 1, 2, 4 of 2 kill 0 and 3, leaving ℤ/3.
example : (Finset.univ.filter fun m : ZMod 6 =>
    ∃ s ∈ ({1, 2, 4} : Finset (ZMod 6)), s * m = 0).card = 2 := by decide
-- Sections over D(3): the powers 1, 3 of 3 kill 0, 2, 4, leaving ℤ/2.
example : (Finset.univ.filter fun m : ZMod 6 =>
    ∃ s ∈ ({1, 3} : Finset (ZMod 6)), s * m = 0).card = 3 := by decide
-- Stalk at (5) and at (0): 6 is a bottom, and 6 is 0, so everything is killed.
example : (Finset.univ.filter fun m : ZMod 6 => ∃ s ∈ ({0, 1} : Finset (ZMod 6)), s * m = 0).card = 6 := by
  decide
-- The cover: D(2) and D(3) cover Spec ℤ, since 1 = (-1)·2 + 1·3.
example : (-1 : ℤ) * 2 + 1 * 3 = 1 := by norm_num
-- Gluing 2 in ℤ/3 with 1 in ℤ/2 gives 2·(-2) + 1·3 = 5 mod 6, which is 2 mod 3 and 1 mod 2.
example : (2 * (-2) + 1 * 3 : ℤ) % 6 = 5 ∧ (5 : ℤ) % 3 = 2 ∧ (5 : ℤ) % 2 = 1 := by norm_num
-- The Chinese remainder gluing: ℤ/6 → ℤ/3 × ℤ/2 hits all 6 pairs once each.
example : Function.Bijective (fun m : ZMod 6 => ((m.val : ZMod 3), (m.val : ZMod 2))) := by decide
-- Fibre M/pM of ℤ/6 at (2), (3), (5): 2, 3 and 1 elements, so dimensions 1, 1, 0.
example : (Finset.univ.image fun m : ZMod 6 => 2 * m).card = 3 ∧
    (Finset.univ.image fun m : ZMod 6 => 3 * m).card = 2 ∧
    (Finset.univ.image fun m : ZMod 6 => 5 * m).card = 6 := by decide
-- 𝒪(2) has 3 global sections: the monomials x², xy, y² of degree 2.
example : ((Finset.range 3 ×ˢ Finset.range 3).filter fun ij => ij.1 + ij.2 = 2).card = 3 := by
  decide
-- x² + 4xy + y² reads 1 + 4t + t² and s² + 4s + 1 on the two charts, and t²·g(1/t) = f(t).
example (t : ℚ) (ht : t ≠ 0) : t ^ 2 * ((1 / t) ^ 2 + 4 * (1 / t) + 1) = 1 + 4 * t + t ^ 2 := by
  field_simp
-- The point P = (1 : 2) lies on the line 2x - y.
example : (2 : ℚ) * 1 - 2 = 0 := by norm_num
-- Over 𝔽₃, the forms of degree 3 vanishing at (1 : 2) number 27 = 3³ of the 81.
example : (Finset.univ.filter fun c : Fin 4 → ZMod 3 =>
    c 0 * 1 + c 1 * 2 + c 2 * 4 + c 3 * 8 = 0).card = 27 := by decide

#print axioms tilde_sections_stalks_and_global_sections
#print axioms finrank_forms_of_degree_eq_twist_sections
#print axioms ideal_of_point_eq_shift_minus_one
