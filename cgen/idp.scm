; General cpu info generator support.
; Copyright (C) 2000, 2002, 2005, 2009 Red Hat, Inc.
; This file is part of CGEN.

; Global state variables.

; Specify which application.
(set! APPLICATION 'IDP)

; String containing copyright text.
(define CURRENT-COPYRIGHT #f)

; String containing text defining the package we're generating code for.
(define CURRENT-PACKAGE #f)

; #t if the scache is being used
(define /with-scache? #f)
(define (with-scache?) /with-scache?)

; Initialize the options.

(define (option-init!)
  (set! /with-scache? #f)
  (set! CURRENT-COPYRIGHT copyright-fsf)
  (set! CURRENT-PACKAGE package-gnu-binutils-gdb)
  *UNSPECIFIED*
)

; #t if the cpu can execute insns parallely.
; This one isn't passed on the command line, but we follow the convention
; of prefixing these things with `with-'.
; While processing operand reading (or writing), parallel execution support
; needs to be turned off, so it is up to the appropriate cgen-foo.c proc to
; set-with-parallel?! appropriately.
(define /with-parallel? #f)
(define (with-parallel?) /with-parallel?)
(define (set-with-parallel?! flag) (set! /with-parallel? flag))

; Handle an option passed in from the command line.

(define (option-set! name value)
  (case name
    ((with-scache) (set! /with-scache? #t))
    ((copyright) (cond ((equal?  value '("fsf"))
			(set! CURRENT-COPYRIGHT copyright-fsf))
		       ((equal? value '("redhat"))
			(set! CURRENT-COPYRIGHT copyright-red-hat))
		       (else (error "invalid copyright value" value))))
    ((package) (cond ((equal?  value '("binutils"))
          (set! CURRENT-PACKAGE package-gnu-binutils-gdb))
         ((equal?  value '("gnusim"))
          (set! CURRENT-PACKAGE package-gnu-simulators))
         ((equal? value '("cygsim"))
          (set! CURRENT-PACKAGE package-red-hat-simulators))
         (else (error "invalid package value" value))))
    (else (error "unknown option" name))
    )
  *UNSPECIFIED*
)


; Create the virtual insns.

(define (/create-virtual-insns!)
  (let ((all (all-isas-attr-value))
  (context (make-prefix-context "virtual insns"))
  ;; Record as a pair so /virtual-insn-add! can update it.
  (ordinal (cons #f -1)))
    (/virtual-insn-add!
     ordinal
     (insn-read context
    '(name x-invalid)
    '(comment "invalid insn handler")
    `(attrs VIRTUAL (ISA ,@all))
    '(syntax "--invalid--")
    (list 'semantics (list 'c-code 'VOID (string-append "\
  {
    break;
  }
")))
    ))
    )
)

; IDP init,finish,analyzer support.

; Initialize any opcodes specific things before loading the .cpu file.

(define (idp-init!)
  (sim-init!)
  (desc-init!)
  (mode-set-biggest-word-bitsizes!)
  *UNSPECIFIED*
)

; Finish any opcodes specific things after loading the .cpu file.
; This is separate from analyze-data! as cpu-load performs some
; consistency checks in between.

(define (idp-finish!)
  (sim-finish!)
  (desc-finish!)
  *UNSPECIFIED*
)

; Compute various needed globals and assign any computed fields of
; the various objects.  This is the standard routine that is called after
; a .cpu file is loaded.

(define (idp-analyze!)
  (sim-analyze!)
  (desc-analyze!)

  ; Initialize the rtl->c translator.
  (rtl-c-config!)

  ; Only include semantic operands when computing the format tables if we're
  ; generating operand instance tables.
  ; ??? Actually, may always be able to exclude the semantic operands.
  ; Still need to traverse the semantics to derive machine computed attributes.
  (arch-analyze-insns! CURRENT-ARCH
		       #t ; include aliases
		       #t) ; include sformat

  *UNSPECIFIED*
)
