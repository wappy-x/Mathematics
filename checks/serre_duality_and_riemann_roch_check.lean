-- Serre duality: on projective space the monomial bases of H^0(O(d)) and H^n(O(-d-n-1)) match one to one, and Riemann-Roch holds for line sections of plane curves.
import Mathlib.Data.Set.Function
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Data.Finsupp.Multiset
import Mathlib.Data.Sym.Card
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

/-- Twice C(k, 2) is k (k - 1), as integers. -/
theorem two_mul_choose_two (k : ℕ) : 2 * (k.choose 2 : ℤ) = k * ((k : ℤ) - 1) := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [Nat.choose_succ_succ, Nat.choose_one_right]
    push_cast
    linarith

/-- Serre duality count on the plane: h^0(O(e)) + h^0(O(-3 - e)) = (e + 1)(e + 2)/2. -/
theorem h0P2_add_dual (e : ℤ) :
    2 * ((Nat.choose (e + 2).toNat 2 : ℤ) + (Nat.choose (-3 - e + 2).toNat 2 : ℤ)) =
      (e + 1) * (e + 2) := by
  rcases le_or_gt (-2) e with h | h
  · rcases le_or_gt 0 e with h' | h'
    · have h1 : ((-3 - e + 2).toNat) = 0 := by omega
      rw [h1, mul_add, two_mul_choose_two]
      simp [Int.toNat_of_nonneg (by omega : 0 ≤ e + 2)]
      ring
    · rw [Nat.choose_eq_zero_of_lt (by omega : (e + 2).toNat < 2),
        Nat.choose_eq_zero_of_lt (by omega : (-3 - e + 2).toNat < 2)]
      have : e = -1 ∨ e = -2 := by omega
      rcases this with rfl | rfl <;> norm_num
  · have h1 : ((e + 2).toNat) = 0 := by omega
    have T := two_mul_choose_two (-3 - e + 2).toNat
    rw [Int.toNat_of_nonneg (by omega : 0 ≤ -3 - e + 2)] at T
    rw [h1]
    simp only [Nat.choose_zero_succ, Nat.cast_zero, zero_add]
    linarith

#print axioms two_mul_choose_two
#print axioms h0P2_add_dual

/-- Serre duality on projective space P^n, by the Cech pairing. The Laurent monomials
x^a = x_0^(a_0) ... x_n^(a_n) spanning H^0(O(d)) are those of degree d with every exponent at
least 0; those spanning H^n(O(-d-n-1)) have degree -d-n-1 and every exponent at most -1. The
product x^a x^b lands on the top class 1/(x_0 ... x_n) exactly when b = -1 - a, and this rule
matches the two bases one to one. So the pairing is perfect and
H^0(O(d)) is dual to H^n(O(-d-n-1)), with K = O(-n-1). -/
theorem cech_pairing_matches_sections_with_top_classes (n : ℕ) (d : ℤ) :
    Set.BijOn (fun a : Fin (n + 1) → ℤ => fun i => -1 - a i)
      {a | (∀ i, 0 ≤ a i) ∧ ∑ i, a i = d}
      {b | (∀ i, b i ≤ -1) ∧ ∑ i, b i = -d - ((n : ℤ) + 1)} := by
  refine ⟨?_, ?_, ?_⟩
  · rintro a ⟨h0, hs⟩
    refine ⟨fun i => by linarith [h0 i], ?_⟩
    simp only [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      hs, nsmul_eq_mul]
    push_cast; ring
  · intro a _ b _ h
    funext i
    have := congrFun h i
    simp only at this
    linarith
  · rintro b ⟨h0, hs⟩
    refine ⟨fun i => -1 - b i, ⟨fun i => by linarith [h0 i], ?_⟩, ?_⟩
    · simp only [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
        hs, nsmul_eq_mul]
      push_cast; ring
    · funext i; simp

/-- The number of monomials of degree d in the n + 1 variables x_0, ..., x_n is the binomial
C(d + n, n): this is h^0(O(d)) on P^n for d ≥ 0. -/
theorem card_monomials_of_degree (n d : ℕ) :
    Nat.card {a : Fin (n + 1) → ℕ // ∑ i, a i = d} = Nat.choose (d + n) n := by
  rw [← Nat.card_congr (Sym.equivNatSumOfFintype (Fin (n + 1)) d), Nat.card_eq_fintype_card,
    Sym.card_sym_eq_choose, Fintype.card_fin]
  rw [show n + 1 + d - 1 = d + n by omega, Nat.choose_symm_add]

/-- Riemann-Roch for D = m line sections on a smooth plane curve C of degree d. Here
h^0(O_C(m)) = h^0(O(m)) - h^0(O(m - d)), with h^0(O(e)) = C(e + 2, 2) on the plane (0 for e < 0),
K = O_C(d - 3), deg D = m d and g = (d - 1)(d - 2)/2. Then
l(D) - l(K - D) = deg D + 1 - g for every whole number m. -/
theorem riemann_roch_plane_curve_line_sections (d : ℕ) (hd : 1 ≤ d) (m : ℤ) :
    let h0P2 : ℤ → ℤ := fun e => (Nat.choose (e + 2).toNat 2 : ℤ)
    let h0C : ℤ → ℤ := fun e => h0P2 e - h0P2 (e - d)
    h0C m - h0C ((d : ℤ) - 3 - m) = m * d + 1 - (((d - 1) * (d - 2) / 2 : ℕ) : ℤ) := by
  intro h0P2 h0C
  obtain ⟨k, rfl⟩ : ∃ k, d = k + 1 := ⟨d - 1, by omega⟩
  have hg : (k + 1 - 1) * (k + 1 - 2) / 2 = k.choose 2 := by
    rw [Nat.choose_two_right]; congr 1
  rw [hg]
  have A := h0P2_add_dual m
  have B := h0P2_add_dual (m - (k + 1 : ℕ))
  have G := two_mul_choose_two k
  have e1 : -3 - (m - ((k + 1 : ℕ) : ℤ)) = ((k + 1 : ℕ) : ℤ) - 3 - m := by ring
  have e2 : ((k + 1 : ℕ) : ℤ) - 3 - m - ((k + 1 : ℕ) : ℤ) = -3 - m := by ring
  rw [e1] at B
  simp only [h0C, h0P2, e2]
  push_cast at *
  linarith

-- P^1 with K = O(-2): h^1(O(-3)) = C(-(-3) - 1, 1) = 2 = h^0(O(1)) = C(1 + 1, 1).
example : Nat.choose ((-(-3 : ℤ) - 1).toNat) 1 = 2 ∧ Nat.choose (1 + 1) 1 = 2 := by decide

-- Plane cubic (d = 3, g = 1, K = O): D a line section, degree 3, has l(D) = C(3, 2) - C(0, 2) = 3.
example : (Nat.choose 3 2 : ℤ) - Nat.choose 0 2 = 3 ∧ (3 - 1) * (3 - 2) / 2 = 1 := by decide

-- Plane quartic (d = 4, g = 3): K is a line section of degree 4 and
-- l(K) = C(3, 2) - 0 = 3 = 4 + 1 - 3 + l(0), with l(0) = 1.
example : (Nat.choose 3 2 : ℤ) = 3 ∧ (4 : ℤ) + 1 - 3 + Nat.choose 2 2 = 3 ∧ (4 - 1) * (4 - 2) / 2 = 3 := by
  decide

#print axioms cech_pairing_matches_sections_with_top_classes
#print axioms card_monomials_of_degree
#print axioms riemann_roch_plane_curve_line_sections
