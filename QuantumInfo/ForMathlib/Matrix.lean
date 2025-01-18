import Mathlib.Data.Matrix.Kronecker
import Mathlib.LinearAlgebra.Matrix.PosDef

import QuantumInfo.ForMathlib.Other

open BigOperators
open Classical

variable {n 𝕜 : Type*}
variable [RCLike 𝕜]

namespace RCLike

theorem isSelfAdjoint_re_iff {c : 𝕜} : IsSelfAdjoint c ↔ RCLike.re c = c  :=
  RCLike.conj_eq_iff_re

theorem isSelfAdjoint_im_zero_iff {c : 𝕜} : IsSelfAdjoint c ↔ RCLike.im c = 0  :=
  RCLike.conj_eq_iff_im

open ComplexOrder

theorem inv_nonneg' {x : 𝕜} (h : 0 ≤ x) : 0 ≤ x⁻¹ := by
  by_cases h0 : x = 0
  · subst x
    simp only [_root_.inv_zero, le_refl]
  · exact (RCLike.inv_pos.mpr (lt_of_le_of_ne h (Ne.symm h0))).le

@[simp]
theorem inv_nonneg {x : 𝕜} : 0 ≤ x⁻¹ ↔ 0 ≤ x :=
  ⟨by simpa only [inv_inv] using inv_nonneg' (x := x⁻¹), inv_nonneg'⟩

end RCLike

namespace Matrix

theorem zero_rank_eq_zero {A : Matrix n n 𝕜} [Fintype n] (hA : A.rank = 0) : A = 0 := by
  have h : ∀ v, A.mulVecLin v = 0 := by
    intro v
    rw [Matrix.rank, Module.finrank_zero_iff] at hA
    have := hA.elim ⟨A.mulVecLin v, ⟨v, rfl⟩⟩ ⟨0, ⟨0, by rw [mulVecLin_apply, mulVec_zero]⟩⟩
    simpa only [Subtype.mk.injEq] using this
  rw [← LinearEquiv.map_eq_zero_iff toLin']
  exact LinearMap.ext h

namespace IsHermitian

variable {A : Matrix n n 𝕜} {B : Matrix n n 𝕜}
variable (hA : A.IsHermitian) (hB : B.IsHermitian)

include hA in
theorem smul_selfAdjoint {c : 𝕜} (hc : _root_.IsSelfAdjoint c) : (c • A).IsHermitian := by
  rw [IsHermitian, Matrix.conjTranspose_smul, hc, hA]

include hA in
theorem smul_im_zero {c : 𝕜} (h : RCLike.im c = 0) : (c • A).IsHermitian :=
  hA.smul_selfAdjoint (RCLike.isSelfAdjoint_im_zero_iff.mpr h)

include hA in
theorem smul_real (c : ℝ) : (c • A).IsHermitian := by
  convert hA.smul_im_zero (RCLike.ofReal_im c) using 1
  ext
  simp only [smul_apply, smul_eq_mul, RCLike.real_smul_eq_coe_mul]

def HermitianSubspace (n 𝕜 : Type*) [Fintype n] [RCLike 𝕜] : Subspace ℝ (Matrix n n 𝕜) where
  carrier := { A : Matrix n n 𝕜 | A.IsHermitian }
  add_mem' _ _ := by simp_all only [Set.mem_setOf_eq, IsHermitian.add]
  zero_mem' := by simp only [Set.mem_setOf_eq, isHermitian_zero]
  smul_mem' c A := by
    simp only [Set.mem_setOf_eq]
    intro hA
    exact IsHermitian.smul_real hA c

variable [Fintype n]

include hA in
@[simp]
theorem re_trace_eq_trace : RCLike.re (A.trace) = A.trace := by
  rw [trace, map_sum, RCLike.ofReal_sum, IsHermitian.coe_re_diag hA]

/-- The trace of a Hermitian matrix, as a real number. -/
def rtrace {A : Matrix n n 𝕜} (_ : A.IsHermitian) : ℝ :=
  RCLike.re (A.trace)

include hA in
@[simp]
theorem rtrace_eq_trace : (hA.rtrace : 𝕜) = A.trace :=
  hA.re_trace_eq_trace

section eigenvalues

/-- The sum of the eigenvalues of a Hermitian matrix is equal to its trace. -/
theorem sum_eigenvalues_eq_trace : ∑ i, hA.eigenvalues i = A.trace := by
  nth_rewrite 2 [hA.spectral_theorem]
  rw [Matrix.trace_mul_comm]
  rw [← mul_assoc]
  simp [Matrix.trace_diagonal]

/-- If all eigenvalues are equal to zero, then the matrix is zero. -/
theorem eigenvalues_zero_eq_zero (h : ∀ i, hA.eigenvalues i = 0) : A = 0 := by
  suffices A.rank = 0 from zero_rank_eq_zero this
  simp only [hA.rank_eq_card_non_zero_eigs, h, ne_eq, not_true_eq_false, Fintype.card_eq_zero]

end eigenvalues

end IsHermitian

section Kronecker

open Kronecker

variable [CommRing R] [StarRing R]
variable (A : Matrix m m R) (B : Matrix n n R)

theorem kroneckerMap_conjTranspose : (A ⊗ₖ B)ᴴ = (Aᴴ ⊗ₖ Bᴴ) := by
  ext; simp

variable {A : Matrix m m R} {B : Matrix n n R}
variable (hA : A.IsHermitian) (hB : B.IsHermitian)

include hA hB in
theorem kroneckerMap_IsHermitian : (A ⊗ₖ B).IsHermitian := by
  exact (hA ▸ hB ▸ kroneckerMap_conjTranspose A B : _ = _)

end Kronecker

namespace PosSemidef

open Classical
open Kronecker
open scoped ComplexOrder

variable {m n 𝕜 : Type*}
variable [Fintype m] [Fintype n]
variable [RCLike 𝕜] [DecidableEq n]

section
variable {A : Matrix m m 𝕜} {B : Matrix m m 𝕜}
variable (hA : A.PosSemidef) (hB : B.PosSemidef)

include hA in
theorem diag_nonneg : ∀i, 0 ≤ A.diag i := by
  intro i
  simpa [Matrix.mulVec, Matrix.dotProduct] using hA.2 (fun j ↦ if i = j then 1 else 0)

include hA in
theorem trace_nonneg : 0 ≤ A.trace := by
  rw [Matrix.trace]
  apply Finset.sum_nonneg
  simp_rw [Finset.mem_univ, forall_true_left]
  exact hA.diag_nonneg

include hA in
theorem trace_zero : A.trace = 0 → A = 0 := by
  intro h
  rw [← hA.isHermitian.sum_eigenvalues_eq_trace, RCLike.ofReal_eq_zero] at h
  rw [Finset.sum_eq_zero_iff_of_nonneg (fun i _ ↦ hA.eigenvalues_nonneg i)] at h
  simp only [Finset.mem_univ, diag_apply, forall_const] at h
  exact hA.isHermitian.eigenvalues_zero_eq_zero h

include hA in
@[simp]
theorem trace_zero_iff : A.trace = 0 ↔ A = 0 :=
  ⟨trace_zero hA, (by simp [·])⟩

theorem rtrace_nonneg : 0 ≤ hA.1.rtrace := by
  have := hA.trace_nonneg
  rwa [← hA.1.rtrace_eq_trace, RCLike.ofReal_nonneg] at this

@[simp]
theorem rtrace_zero_iff : hA.1.rtrace = 0 ↔ A = 0 :=
  ⟨fun h ↦ hA.trace_zero_iff.mp (RCLike.ext
    (by simp [show RCLike.re A.trace = 0 from h])
    (by simp [RCLike.nonneg_iff.mp hA.trace_nonneg])),
  (by simp [·, IsHermitian.rtrace])⟩

include hA in
theorem smul {c : 𝕜} (h : 0 ≤ c) : (c • A).PosSemidef := by
  constructor
  · apply hA.1.smul_im_zero (RCLike.nonneg_iff.mp h).2
  · intro x
    rw [Matrix.smul_mulVec_assoc, Matrix.dotProduct_smul]
    exact mul_nonneg h (hA.2 x)

include hA hB in
theorem convex_cone {c₁ c₂ : 𝕜} (hc₁ : 0 ≤ c₁) (hc₂ : 0 ≤ c₂) : (c₁ • A + c₂ • B).PosSemidef :=
  (hA.smul hc₁).add (hB.smul hc₂)

set_option trace.split.failure true

/-- A standard basis matrix (with a positive entry) is positive semidefinite iff the entry is on the diagonal. -/
theorem stdBasisMatrix_iff_eq (i j : m) {c : 𝕜} (hc : 0 < c) : (Matrix.stdBasisMatrix i j c).PosSemidef ↔ i = j := by
  constructor
  · intro ⟨hherm, _⟩
    rw [IsHermitian, ←Matrix.ext_iff] at hherm
    replace hherm := hherm i j
    simp only [stdBasisMatrix, conjTranspose_apply, of_apply, true_and, RCLike.star_def, if_true] at hherm
    apply_fun (starRingEnd 𝕜) at hherm
    have hcstar := RCLike.conj_eq_iff_im.mpr (RCLike.pos_iff.mp hc).right
    rw [starRingEnd_self_apply, hcstar, ite_eq_left_iff] at hherm
    contrapose! hherm
    have hcnezero : 0 ≠ c := by
      by_contra hczero
      subst hczero
      exact (lt_self_iff_false 0).mp hc
    exact ⟨fun _ => hherm.symm, hcnezero⟩
  · intro hij
    subst hij
    constructor
    · ext x y
      simp only [conjTranspose_apply, RCLike.star_def, Matrix.stdBasisMatrix, of_apply]
      split_ifs <;> try tauto
      · exact RCLike.conj_eq_iff_im.mpr (RCLike.pos_iff.1 hc).2
      · exact RingHom.map_zero (starRingEnd 𝕜)
    · intro x
      simp only [dotProduct, Matrix.stdBasisMatrix, of_apply, mulVec]
      convert_to 0 ≤ (star x i) * c * (x i)
      · simp only [Finset.mul_sum]
        rw [←Fintype.sum_prod_type']
        have h₀ : ∀ x_1 : m × m, x_1 ≠ ⟨i, i⟩ → star x x_1.1 * ((if i = x_1.1 ∧ i = x_1.2 then c else 0) * x x_1.2) = 0 := fun z hz => by
          have h₁ : ¬(i = z.1 ∧ i = z.2) := by
            rw [ne_eq, Prod.mk.inj_iff] at hz
            by_contra hz'
            apply hz
            exact ⟨hz'.left.symm, hz'.right.symm⟩
          rw [ite_cond_eq_false _ _ (eq_false h₁)]
          ring
        rw [Fintype.sum_eq_single ⟨i, i⟩ h₀]
        simp only [RCLike.star_def, and_self, reduceIte, mul_assoc]
      · rw [mul_comm, ←mul_assoc]
        have hpos : 0 ≤ x i * star x i := by simp only [Pi.star_apply, RCLike.star_def,
          RCLike.mul_conj, RCLike.ofReal_nonneg, norm_nonneg, pow_nonneg]
        exact (mul_nonneg hpos (le_of_lt hc))

end

variable {A : Matrix m m 𝕜} {B : Matrix n n 𝕜}
variable (hA : A.PosSemidef) (hB : B.PosSemidef)

include hA hB in
theorem PosSemidef_kronecker : (A ⊗ₖ B).PosSemidef := by
  rw [hA.left.spectral_theorem, hB.left.spectral_theorem]
  rw [Matrix.mul_kronecker_mul, Matrix.mul_kronecker_mul]
  rw [Matrix.star_eq_conjTranspose, Matrix.star_eq_conjTranspose]
  rw [← kroneckerMap_conjTranspose]
  rw [Matrix.diagonal_kronecker_diagonal]
  apply mul_mul_conjTranspose_same
  rw [posSemidef_diagonal_iff]
  rintro ⟨i₁, i₂⟩
  convert mul_nonneg (hA.eigenvalues_nonneg i₁) (hB.eigenvalues_nonneg i₂)
  rw [RCLike.nonneg_iff]
  simp

lemma sqrt_eq {A B : Matrix m m 𝕜} (h : A = B) (hA : A.PosSemidef) (hB : B.PosSemidef) :
    hA.sqrt = hB.sqrt := by
  congr!

lemma sqrt_eq' {A B : Matrix m m 𝕜} (h : A = B) (hA : A.PosSemidef) :
    hA.sqrt = (h ▸ hA).sqrt := by
  congr!

@[simp]
theorem sqrt_0 : (Matrix.PosSemidef.zero (n := n) (R := 𝕜)).sqrt = 0 :=
  Eq.symm $ eq_sqrt_of_sq_eq Matrix.PosSemidef.zero _ (by simp)

@[simp]
theorem sqrt_1 : (Matrix.PosSemidef.one (n := n) (R := 𝕜)).sqrt = 1 :=
  Eq.symm $ eq_sqrt_of_sq_eq Matrix.PosSemidef.one _ (by simp)

theorem nonneg_smul {c : 𝕜} (hA : A.PosSemidef) (hc : 0 ≤ c) : (c • A).PosSemidef := by
  constructor
  · simp only [IsHermitian, conjTranspose_smul, RCLike.star_def]
    congr
    exact RCLike.conj_eq_iff_im.mpr (RCLike.nonneg_iff.mp hc).2
    exact hA.1
  · intro x
    rw [Matrix.smul_mulVec_assoc, dotProduct_smul, smul_eq_mul]
    exact Left.mul_nonneg hc (hA.2 x)

theorem pos_smul {c : 𝕜} (hA : (c • A).PosSemidef) (hc : 0 < c) : A.PosSemidef := by
  have : 0 < 1/c := by
    rw [RCLike.pos_iff] at hc ⊢
    aesop
  convert hA.nonneg_smul (c := 1/c) this.le
  rw [smul_smul, one_div, inv_mul_cancel₀ hc.ne', one_smul]

theorem nonneg_smul_Real_smul {c : ℝ} (hA : A.PosSemidef) (hc : 0 ≤ c) : (c • A).PosSemidef := by
  rw [(RCLike.real_smul_eq_coe_smul c A : c • A = (c : 𝕜) • A)]
  exact nonneg_smul hA (RCLike.ofReal_nonneg.mpr hc)

theorem pos_Real_smul {c : ℝ} (hA : (c • A).PosSemidef) (hc : 0 < c) : A.PosSemidef := by
  rw [(RCLike.real_smul_eq_coe_smul c A : c • A = (c : 𝕜) • A)] at hA
  exact pos_smul hA (RCLike.ofReal_pos.mpr hc)

theorem sqrt_nonneg_smul {c : 𝕜} (hA : (c^2 • A).PosSemidef) (hc : 0 < c) :
    hA.sqrt = c • (hA.pos_smul (sq_pos_of_pos hc) : A.PosSemidef).sqrt := by
  apply Eq.symm
  apply eq_sqrt_of_sq_eq
  · apply nonneg_smul ?_ hc.le
    apply posSemidef_sqrt
  rw [pow_two, Algebra.mul_smul_comm, Algebra.smul_mul_assoc, sqrt_mul_self, pow_two, smul_smul]

include hA in
theorem zero_dotProduct_zero_iff : (∀ x : m → 𝕜, 0 = star x ⬝ᵥ A.mulVec x) ↔ A = 0 := by
  constructor
  · intro h0
    replace h0 := fun x ↦(PosSemidef.dotProduct_mulVec_zero_iff hA x).mp (h0 x).symm
    ext i j
    specialize h0 (Pi.single j 1)
    rw [mulVec_single] at h0
    replace h0 := congrFun h0 i
    simp_all only [mul_one, Pi.zero_apply, zero_apply]
  · intro h0
    rw [h0]
    simp only [zero_mulVec, dotProduct_zero, implies_true]

theorem zero_posSemidef_neg_posSemidef_iff : A.PosSemidef ∧ (-A).PosSemidef ↔ A = 0 := by
  constructor
  · intro ⟨hA, hNegA⟩
    have h0 : ∀ x : m → 𝕜, 0 = star x ⬝ᵥ A.mulVec x := fun x ↦ by
      have hNegA' := hNegA.right x
      rw [neg_mulVec, dotProduct_neg, le_neg, neg_zero] at hNegA'
      exact le_antisymm (hA.right x) hNegA'
    exact (zero_dotProduct_zero_iff hA).mp h0
  · intro h0
    rw [h0]
    simp only [neg_zero, and_self, PosSemidef.zero]

noncomputable section log

/-- Matrix logarithm (base e) of a positive semidefinite matrix, as given by the elementwise
  real logarithm of the diagonal in a diagonalized form.

  Note that this means that the nullspace of the image includes all of the nullspace of the
  original matrix. This contrasts to the standard definition, which is only defined for positive
  *definite* matrices, and the nullspace of the image is exactly the (λ=1)-eigenspace of the
  original matrix. It coincides with the standard definition if A is positive definite. -/
def log (hA : A.PosSemidef) : Matrix m m 𝕜 :=
  (hA.1.eigenvectorUnitary : Matrix _ _ _) * diagonal (RCLike.ofReal ∘ Real.log ∘ hA.1.eigenvalues) *
  (star hA.1.eigenvectorUnitary : Matrix _ _ _)

theorem log_IsHermitian (hA : A.PosSemidef) : hA.log.IsHermitian :=
  Matrix.isHermitian_mul_mul_conjTranspose _ (by simp
    [isHermitian_diagonal_iff, RCLike.isSelfAdjoint_re_iff])

--TODO: properties here https://en.wikipedia.org/wiki/Logarithm_of_a_matrix#Properties

end log

end PosSemidef

section frobenius_inner_product
open scoped ComplexOrder
variable {A : Matrix n n 𝕜} {B : Matrix n n 𝕜} [Fintype n]

namespace IsHermitian
open scoped ComplexOrder

variable (hA : A.IsHermitian) (hB : B.IsHermitian)

/-- Real inner product of two square matrices. Only defined for Hermitian matrices,
  as this lets us meaningfully interpret it as a real. -/
def rinner (_ : A.IsHermitian) (_ : B.IsHermitian) : ℝ :=
  RCLike.re (A * B).trace

/-- The inner product for Hermtian matrices is equal to the trace of
  the product. -/
theorem rinner_eq_trace_mul : hA.rinner hB = (A * B).trace := by
  have h₁ := (RCLike.is_real_TFAE (A * B).trace).out 2 0
  rw [rinner, h₁]
  nth_rewrite 1 1 [← hA, ← hB]
  simp [Matrix.trace, Matrix.mul_apply, Finset.sum_comm (f := fun x y ↦ A x y * _)]

theorem rinner_symm : hA.rinner hB = hB.rinner hA := by
  rw [rinner, rinner, Matrix.trace_mul_comm]

@[simp]
theorem rinner_zero_mul : hA.rinner Matrix.isHermitian_zero = 0 := by
  simp [rinner]

@[simp]
theorem rinner_mul_zero : Matrix.isHermitian_zero.rinner hA = 0 := by
  simp [rinner]

@[simp]
theorem rinner_mul_one : hA.rinner Matrix.isHermitian_one = hA.rtrace := by
  simp only [rinner, mul_one, rtrace]

@[simp]
theorem one_rinner_mul : Matrix.isHermitian_one.rinner hA = hA.rtrace := by
  simp only [rinner, one_mul, rtrace]

theorem rinner_smul_selfAdjoint {c : 𝕜} (hc : _root_.IsSelfAdjoint c) :
    (hA.smul_selfAdjoint hc).rinner hB = c * hA.rinner hB := by
  simp [rinner, RCLike.conj_eq_iff_re.mp hc, RCLike.conj_eq_iff_im.mp hc]

theorem smul_rinner_selfAdjoint {c : 𝕜} (hc : _root_.IsSelfAdjoint c) :
    hA.rinner (hB.smul_selfAdjoint hc) = c * hA.rinner hB := by
  rwa [rinner_symm, rinner_symm hA, rinner_smul_selfAdjoint]

@[simp]
theorem rinner_smul_real {c : ℝ} :
    (hA.smul_real c).rinner hB = c * hA.rinner hB := by
  simp [rinner, RCLike.smul_re]

@[simp]
theorem smul_inner_real {c : ℝ} :
    hA.rinner (hB.smul_real c) = c * hA.rinner hB := by
  simp [rinner, RCLike.smul_re]

@[simp]
theorem rinner_add : hA.rinner (IsHermitian.add hB hC) = hA.rinner hB + hA.rinner hC := by
  unfold rinner
  rw [left_distrib, trace_add, map_add]

@[simp]
theorem rinner_sub : hA.rinner (IsHermitian.sub hB hC) = hA.rinner hB - hA.rinner hC := by
  unfold rinner
  rw [sub_eq_add_neg, left_distrib, trace_add, map_add, mul_neg, trace_neg, map_neg, ←sub_eq_add_neg]

end IsHermitian
namespace PosSemidef

variable (hA : A.PosSemidef) (hB : B.PosSemidef)

/-- The inner product for PSD matrices is nonnegative. -/
theorem rinner_ge_zero : 0 ≤ hA.1.rinner hB.1 := by
  rw [IsHermitian.rinner, ← hA.sqrt_mul_self, Matrix.trace_mul_cycle, Matrix.trace_mul_cycle]
  nth_rewrite 1 [← hA.posSemidef_sqrt.left]
  exact (RCLike.nonneg_iff.mp (hB.conjTranspose_mul_mul_same _).trace_nonneg).left

set_option pp.proofs.withType true in
include hA hB in
/-- The inner product for PSD matrices is at most the product of their traces. -/
theorem rinner_le_mul_trace : hA.1.rinner hB.1 ≤ hA.1.rtrace * hB.1.rtrace := by
  wlog ha : A.trace = 1
  · by_cases ha₀ : A.trace = 0
    · have h₁ : A = 0 := hA.trace_zero ha₀
      subst A
      simp
      sorry
    · let A' := A.trace⁻¹ • A
      sorry
      -- have h₁ : A'.PosSemidef := by
      --   apply nonneg_smul hA (RCLike.inv_nonneg' hA.trace_nonneg)
      -- have h₂ : A'.trace = 1 := by
      --   simp [A', inv_mul_cancel₀ ha₀]
      -- specialize this h₁ hB h₂
      -- simp [A'] at this
      -- have h₃ : 0 < A.trace⁻¹ :=
      --   RCLike.inv_pos.mpr (lt_of_le_of_ne hA.trace_nonneg (Ne.symm ha₀))
      -- rw [RCLike.conj_eq_iff_im (z := A.trace).mpr (RCLike.nonneg_iff.mp hA.trace_nonneg).right] at this
      -- clear h₁ h₂ ha hA hB A'
      -- sorry
  wlog hb : B.trace = 1
  · sorry
  replace h : 0 ≤ (((A - B)ᴴ * (A - B)).trace) := by
    exact (posSemidef_conjTranspose_mul_self (A - B)).trace_nonneg
  simp only [conjTranspose_sub, sub_mul, mul_sub, ← sub_add, Matrix.trace_sub,
    Matrix.trace_add] at h
  replace h : (Bᴴ * A).trace + (Aᴴ * B).trace ≤ (Aᴴ * A).trace + (Bᴴ * B).trace := by
    rw [RCLike.le_iff_re_im] at h ⊢
    obtain ⟨h₁, h₂⟩ := h
    simp only [map_add, map_sub, map_zero] at h₁ h₂ ⊢
    constructor <;> linarith
  have : (Aᴴ * A).trace ≤ 1 := by sorry
  have : (Bᴴ * B).trace ≤ 1 := by sorry
  -- rw [ha, hb, one_mul]
  --add, divide by two, symmetrize, transitive.
  sorry

-- /-- The InnerProductSpace on Matrix n n 𝕜 defined by the Frobenius inner product, `Matrix.inner`.-/
-- def MatrixInnerProduct :=
--   InnerProductSpace.ofCore (𝕜 := ℝ) (F := Matrix n n 𝕜) {
--     inner := rinner
--     conj_symm := fun x y ↦ by
--       simp [inner, starRingEnd_apply, ← Matrix.trace_conjTranspose,
--         conjTranspose_mul, conjTranspose_conjTranspose]
--     nonneg_re := fun x ↦ by
--       simp only [inner]
--       exact (RCLike.nonneg_iff.mp x.posSemidef_conjTranspose_mul_self.trace_nonneg).1
--     add_left := by simp [inner, add_mul]
--     smul_left := by simp [inner]
--     definite := sorry
--   }

end PosSemidef
end frobenius_inner_product
