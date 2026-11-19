-- Sheaves: a polynomial in t on one chart of the projective line and a polynomial in s = 1/t on the other glue into one global function only when both are the same constant, and under the twisted rule f(t) = t^d g(1/t) the glued pairs form a space of dimension d + 1 when d ≥ 0 and 0 when d < 0.
import Mathlib.Algebra.Polynomial.Laurent
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.FiniteDimensional.Defs
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.RingTheory.Polynomial.Basic
import Mathlib.LinearAlgebra.Dimension.Constructions

open Polynomial LaurentPolynomial

/-- The gluing map for the twist `O(d)` on the projective line over a field `k`. A pair
`(f, g)` is a polynomial `f(t)` on the chart `U₀` and a polynomial `g(s)` on the chart `U₁`.
Both are restricted to the overlap, where sections are Laurent polynomials in `t`: `f` as it
is, and `g` by putting `s = 1/t` (the map `invert`) and multiplying by `t^d`. The map sends the
pair to the difference `f(t) - t^d g(1/t)`; the pairs that glue are exactly its kernel. -/
noncomputable def twistGlue (k : Type*) [Field k] (d : ℤ) : k[X] × k[X] →ₗ[k] k[T;T⁻¹] :=
  (Polynomial.toLaurentAlg (R := k)).toLinearMap ∘ₗ LinearMap.fst k k[X] k[X] -
    LinearMap.mulLeft k (T d : k[T;T⁻¹]) ∘ₗ (invert (R := k)).toLinearMap ∘ₗ
      (Polynomial.toLaurentAlg (R := k)).toLinearMap ∘ₗ LinearMap.snd k k[X] k[X]

theorem lc_nat {k : Type*} [Field k] (p : k[X]) (n : ℕ) :
    (toLaurent p).coeff (n : ℤ) = p.coeff n := by
  rw [coeff_toLaurent]
  have := Finsupp.mapDomain_apply_of_injective (Nat.castEmbedding (R := ℤ)).injective p.toFinsupp.coeff n
  simpa [toFinsupp_apply] using this

theorem lc_neg {k : Type*} [Field k] (p : k[X]) (n : ℤ) (hn : n < 0) :
    (toLaurent p).coeff n = 0 := by
  rw [coeff_toLaurent]
  apply Finsupp.mapDomain_of_notMem_range
  rintro ⟨m, rfl⟩
  simp at hn
  omega

theorem glue_iff {k : Type*} [Field k] (f g : k[X]) (d : ℤ) :
    toLaurent f = T d * invert (toLaurent g) ↔
      ∀ n : ℤ, (toLaurent f).coeff n = (toLaurent g).coeff (d - n) := by
  constructor
  · intro h n
    rw [h, T, AddMonoidAlgebra.coeff_single_mul_apply, invert_apply, one_mul]
    congr 1; ring
  · intro h
    ext n
    rw [h, T, AddMonoidAlgebra.coeff_single_mul_apply, invert_apply, one_mul]
    congr 1; ring

theorem lc_zero_of_lt {k : Type*} [Field k] (p : k[X]) (d : ℤ) (n : ℕ) (h : d < n) :
    (toLaurent p).coeff (d - n) = 0 :=
  lc_neg p _ (by omega)

theorem partner_reflect {k : Type*} [Field k] (d : ℕ) (f : k[X]) (hf : f.degree ≤ d) :
    toLaurent f = T (d : ℤ) * invert (toLaurent (reflect d f)) := by
  rw [glue_iff]
  intro n
  rcases lt_or_ge n 0 with hn | hn
  · rw [lc_neg f n hn]
    obtain ⟨m, hm⟩ : ∃ m : ℕ, (d : ℤ) - n = m := ⟨((d : ℤ) - n).toNat, by omega⟩
    rw [hm, lc_nat, coeff_reflect, revAt_eq_self_of_lt (by omega)]
    exact ((degree_le_iff_coeff_zero f d).1 hf m (by exact_mod_cast (by omega : d < m))).symm
  · obtain ⟨m, rfl⟩ : ∃ m : ℕ, n = m := ⟨n.toNat, by omega⟩
    rw [lc_nat]
    rcases le_or_gt m d with hmd | hmd
    · have : (d : ℤ) - m = ((d - m : ℕ) : ℤ) := by omega
      rw [this, lc_nat, coeff_reflect, revAt_le (by omega)]
      congr 1; omega
    · rw [lc_zero_of_lt _ _ _ (by exact_mod_cast hmd)]
      exact (degree_le_iff_coeff_zero f d).1 hf m (by exact_mod_cast hmd)

theorem partner_unique {k : Type*} [Field k] (d : ℤ) (f g₁ g₂ : k[X])
    (h₁ : toLaurent f = T d * invert (toLaurent g₁))
    (h₂ : toLaurent f = T d * invert (toLaurent g₂)) : g₁ = g₂ := by
  rw [h₁] at h₂
  have := (isUnit_T d).mul_left_cancel h₂
  exact toLaurent_injective (invert.injective this)

theorem coeff_zero_of_glue {k : Type*} [Field k] (d : ℤ) (f g : k[X])
    (h : toLaurent f = T d * invert (toLaurent g)) (m : ℕ) (hm : d < m) : f.coeff m = 0 := by
  rw [← lc_nat, (glue_iff f g d).1 h m]
  exact lc_zero_of_lt g d m hm

theorem mem_ker_twistGlue {k : Type*} [Field k] (d : ℤ) (x : k[X] × k[X]) :
    x ∈ LinearMap.ker (twistGlue k d) ↔ toLaurent x.1 = T d * invert (toLaurent x.2) := by
  simp [twistGlue, sub_eq_zero]

theorem twist_ker_mem_degreeLT {k : Type*} [Field k] (d : ℤ) (x : k[X] × k[X])
    (hx : x ∈ LinearMap.ker (twistGlue k d)) : x.1 ∈ degreeLT k (d + 1).toNat := by
  rw [mem_degreeLT, degree_lt_iff_coeff_zero]
  intro m hm
  exact coeff_zero_of_glue d x.1 x.2 ((mem_ker_twistGlue d x).1 hx) m (by omega)

#print axioms lc_nat
#print axioms lc_neg
#print axioms glue_iff
#print axioms lc_zero_of_lt
#print axioms partner_reflect
#print axioms partner_unique
#print axioms coeff_zero_of_glue
#print axioms mem_ker_twistGlue
#print axioms twist_ker_mem_degreeLT

/-- Global regular functions on the projective line are the constants. Over any field `k`,
a polynomial `f(t)` on the chart `U₀` and a polynomial `g(s)` on the chart `U₁` agree on the
overlap, where `s = 1/t`, exactly when `f` and `g` are the same constant `c`. So
`Γ(P¹, 𝒪) = k`. -/
theorem global_sections_of_projective_line_are_constants {k : Type*} [Field k] (f g : k[X]) :
    toLaurent f = invert (toLaurent g) ↔ ∃ c : k, f = Polynomial.C c ∧ g = Polynomial.C c := by
  constructor
  · intro h
    have h' : toLaurent f = T 0 * invert (toLaurent g) := by rw [T_zero, one_mul, h]
    have hg : toLaurent g = T 0 * invert (toLaurent f) := by
      rw [T_zero, one_mul, h, ← AlgEquiv.trans_apply]
      exact (involutive_invert _).symm
    have hf0 := coeff_zero_of_glue 0 f g h'
    have hg0 := coeff_zero_of_glue 0 g f hg
    have hc : f.coeff 0 = g.coeff 0 := by
      rw [← lc_nat, ← lc_nat, (glue_iff f g 0).1 h' ((0 : ℕ) : ℤ)]
      simp
    refine ⟨f.coeff 0, ?_, ?_⟩
    · ext m
      rcases m with _ | m
      · simp
      · rw [hf0 (m + 1) (by omega), coeff_C]; simp
    · ext m
      rcases m with _ | m
      · simp [hc]
      · rw [hg0 (m + 1) (by omega), coeff_C]; simp
  · rintro ⟨c, rfl, rfl⟩
    simp [toLaurent_C]

/-- The twisted sheaf `O(d)` has `max(d + 1, 0)` global sections. Over any field `k`, the
pairs `(f, g)` of polynomials with `f(t) = t^d g(1/t)` on the overlap form a finite-dimensional
space of dimension `d + 1` when `d ≥ 0` and `0` (only the zero pair) when `d < 0`. -/
theorem twist_global_sections_finrank (k : Type*) [Field k] (d : ℤ) :
    Module.Finite k (LinearMap.ker (twistGlue k d)) ∧
      Module.finrank k (LinearMap.ker (twistGlue k d)) = (d + 1).toNat := by
  let φ : LinearMap.ker (twistGlue k d) →ₗ[k] degreeLT k (d + 1).toNat :=
    ((LinearMap.fst k k[X] k[X]).comp (LinearMap.ker (twistGlue k d)).subtype).codRestrict _
      (fun x => twist_ker_mem_degreeLT d x.1 x.2)
  have hφ : Function.Bijective φ := by
    constructor
    · rintro ⟨⟨f₁, g₁⟩, h₁⟩ ⟨⟨f₂, g₂⟩, h₂⟩ h
      have hf : f₁ = f₂ := congrArg Subtype.val h
      subst hf
      have := partner_unique d f₁ g₁ g₂ ((mem_ker_twistGlue d _).1 h₁)
        ((mem_ker_twistGlue d _).1 h₂)
      subst this
      rfl
    · rintro ⟨f, hf⟩
      rw [mem_degreeLT] at hf
      rcases lt_or_ge d 0 with hd | hd
      · have h0 : (d + 1).toNat = 0 := by omega
        rw [h0, degree_lt_iff_coeff_zero] at hf
        have hf0 : f = 0 := by
          ext m
          simpa using hf m (Nat.zero_le m)
        subst hf0
        exact ⟨0, rfl⟩
      · obtain ⟨n, rfl⟩ : ∃ n : ℕ, d = n := ⟨d.toNat, by omega⟩
        have hle : f.degree ≤ n := by
          rw [degree_le_iff_coeff_zero]
          intro m hm
          rw [degree_lt_iff_coeff_zero] at hf
          exact hf m (by
            have : (n : WithBot ℕ) < m := hm
            have : n < m := by exact_mod_cast this
            omega)
        refine ⟨⟨(f, reflect n f), (mem_ker_twistGlue _ _).2 (partner_reflect n f hle)⟩, rfl⟩
  let e' := (LinearEquiv.ofBijective φ hφ).trans (degreeLTEquiv k (d + 1).toNat)
  refine ⟨Module.Finite.equiv e'.symm, ?_⟩
  rw [e'.finrank_eq]
  exact Module.finrank_fin_fun k

/-- Which sections of `O(d)` on the chart `U₀` extend to the whole line, for `d ≥ 0`: a
polynomial `f(t)` glues with some `g(s)` under `f(t) = t^d g(1/t)` exactly when `f` has degree at
most `d`, and then the partner `g` is unique. -/
theorem twist_section_glues_iff_degree_le {k : Type*} [Field k] (d : ℕ) (f : k[X]) :
    (∃! g : k[X], toLaurent f = T (d : ℤ) * invert (toLaurent g)) ↔ f.degree ≤ d := by
  constructor
  · rintro ⟨g, hg, -⟩
    rw [degree_le_iff_coeff_zero]
    intro m hm
    exact coeff_zero_of_glue d f g hg m (by exact_mod_cast hm)
  · intro hf
    exact ⟨reflect d f, partner_reflect d f hf,
      fun g hg => partner_unique d f g _ hg (partner_reflect d f hf)⟩

-- The candidate 3 + 2t on U₀: 7 at t = 2, then 23, 203, 2003 at t = 10, 100, 1000.
example : (3 + 2 * 2 : ℤ) = 7 ∧ (3 + 2 * 10 : ℤ) = 23 ∧ (3 + 2 * 100 : ℤ) = 203 ∧
    (3 + 2 * 1000 : ℤ) = 2003 := by norm_num
-- The same point in chart U₁: s = 1/2 gives (3s + 2)/s = 7.
example : ((3 * (1 / 2) + 2) / (1 / 2) : ℚ) = 7 := by norm_num

-- Twist 2: 1 + 4t + t² on U₀ glues with 1 + 4s + s² on U₁.
example : toLaurent (1 + 4 * X + X ^ 2 : ℚ[X]) =
    T 2 * invert (toLaurent (1 + 4 * X + X ^ 2 : ℚ[X])) := by
  simp only [map_add, map_mul, map_pow, map_one, map_ofNat, Polynomial.toLaurent_X, invert_T]
  rw [T_pow, T_pow, mul_add, mul_add, ← mul_assoc, mul_comm (T 2 : ℚ[T;T⁻¹]) 4, mul_assoc,
    ← T_add, ← T_add]
  norm_num [T_zero]
  ring

-- Over F₅ with degree at most 2: 5^6 = 15625 pairs in all, and 5^(d + 1) glue for
-- d = 0, 1, 2 (5, 25, 125); 2 · 7 = 14 free coefficients up to degree 6 if the overlap is
-- never checked.
example : (5 : ℕ) ^ 6 = 15625 ∧ (5 : ℕ) ^ 1 = 5 ∧ (5 : ℕ) ^ 2 = 25 ∧ (5 : ℕ) ^ 3 = 125 ∧
    2 * (6 + 1) = 14 := by norm_num

-- Comparing by values misleads over F₅: t⁵ and t agree at every point of F₅ ...
example : ∀ x : ZMod 5, x ^ 5 = x := by decide
-- ... yet differ as polynomials.
example : (X ^ 5 : (ZMod 5)[X]) ≠ X := by
  intro h
  have := congrArg (fun p => Polynomial.coeff p 5) h
  simp [Polynomial.coeff_X] at this
  exact absurd this (by decide)

#print axioms global_sections_of_projective_line_are_constants
#print axioms twist_global_sections_finrank
#print axioms twist_section_glues_iff_degree_le
