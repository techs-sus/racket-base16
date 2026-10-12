#lang racket

;; Notice
;; To install (from within the package directory):
;;   $ raco pkg install
;; To install (once uploaded to pkgs.racket-lang.org):
;;   $ raco pkg install <<name>>
;; To uninstall:
;;   $ raco pkg remove <<name>>
;; To view documentation:
;;   $ raco docs <<name>>
;;

(require racket/list json)

;; This project only targets Stylix via home-manager.
(define themePath
  (build-path (find-system-path 'home-dir) ".config/stylix/palette.json"))

;; DrRacket color symbol mappings to base16 symbols.
(define base16->drracket
  (list
   ;; canvas, chrome, and generic text
   (list 'framework:basic-canvas-background 'base00)
   (list 'framework:default-text-color 'base05)
   (list 'framework:disabled-background-color 'base01)
   (list 'framework:failed-search-background-color 'base0A)
   (list 'framework:warning-background-color 'base0A)
   (list 'framework:misspelled-text-color 'base08)
   (list 'framework:paren-match-color 'base04)

   ;; line-number gutter
   (list 'framework:line-numbers 'base03)
   (list 'framework:line-numbers-current-line-number-background 'base02)
   (list 'framework:line-numbers-current-line-number-foreground 'base00)
   (list 'framework:line-numbers-when-word-wrapping 'base00)

   (list 'framework:program-contour-current-location-bar 'base0A)

   ;; syntax highlighting (styles)
   (list 'framework:syntax-color:scheme:other 'base05)
   (list 'framework:syntax-color:scheme:text 'base05)
   (list 'framework:syntax-color:scheme:parenthesis 'base05)
   (list 'framework:syntax-color:scheme:constant 'base0A)
   (list 'framework:syntax-color:scheme:hash-colon-keyword 'base09)
   (list 'framework:syntax-color:scheme:keyword 'base0E)
   (list 'framework:syntax-color:scheme:string 'base0B)
   (list 'framework:syntax-color:scheme:symbol 'base0D)
   (list 'framework:syntax-color:scheme:comment 'base03 'italic)
   (list 'framework:syntax-color:scheme:error 'base08 'bold 'underline)

   ;; errors
   (list 'drracket:error-background-highlighting 'base08)
   (list 'drracket:gold-error-background-highlighting 'base0A)

   ;; check-syntax obligation styles
   (list 'drracket:check-syntax:my-obligation-style-pref 'base08)
   (list 'drracket:check-syntax:their-obligation-style-pref 'base0B)
   (list 'drracket:check-syntax:both-obligation-style-pref 'base09)
   (list 'drracket:check-syntax:unk-obligation-style-pref 'base05)
   (list 'drracket:check-syntax:free-variable 'base09)
   (list 'drracket:check-syntax:imported 'base0E)
   (list 'drracket:check-syntax:lexically-bound 'base0D)
   (list 'drracket:check-syntax:set!d 'base08)
   (list 'drracket:check-syntax:unused-require 'base0C)

   ;; the interactions window
   (list 'drracket:language-name-and-memory-use-at-top-of-interactions 'base0B)
   (list 'drracket:read-eval-print-loop:error-color 'base08)
   (list 'drracket:read-eval-print-loop:out-color 'base0B)
   (list 'drracket:read-eval-print-loop:value-color 'base0D)

   ;; arrow / identifier annotations
   (list 'drracket:syncheck:document-identifier 'base03)
   (list 'drracket:syncheck:matching-identifiers 'base0C)
   (list 'drracket:syncheck:unused-identifier 'base0C)
   (list 'drracket:syncheck:untacked 'base09)
   (list 'drracket:syncheck:var-arrow 'base0D)
   (list 'drracket:syncheck:tail-arrow 'base0C)
   (list 'drracket:syncheck:template-arrow 'base0C)

   ;; the stepper
   (list 'stepper:arrow-color 'base0D)
   (list 'stepper:error-color 'base08)
   (list 'stepper:redex-highlight-color 'base0B)
   (list 'stepper:reduct-highlight-color 'base0D)

   ;; BSL test coverage
   (list 'plt:htdp:test-coverage-on 'base05)
   (list 'plt:htdp:test-coverage-off 'base08)
   (list 'plt:module-language:test-coverage-on 'base05)
   (list 'plt:module-language:test-coverage-off 'base08)))

;; Creates a color vector from a RGB hex color string.
;; "1e1b16" or "#1e1b16" becomes #(30 27 22)
(define (hex->rgb s)
  (define digits (if (string-prefix? s "#") (substring s 1) s))
  (define (byte-at i)
    (define byte (string->number (substring digits i (+ i 2)) 16))
    (unless (exact-integer? byte)
      (error 'hex->rgb "not a hex color: ~s is not an integer" s))
    byte)
  (vector (byte-at 0) (byte-at 2) (byte-at 4)))

;; A palette is a hash from 'base00..'base0F to hex strings, as written by
;; Stylix. (`read-json' gives symbol keys, and `hash-ref' preserves the
;; `base0A' casing, so the slot symbols above are spelled to match.)
;; Any other keys, such as 'slug, are ignored.
(define (palette-ref palette slot)
  (hash-ref palette slot
            (lambda ()
              (error 'palette-ref "palette is missing ~a" slot))))

(module+ test
  (require rackunit)

  (check-equal? (hex->rgb "1e1b16") (vector #x1e #x1b #x16)
                "hex without a leading #")
  (check-equal? (hex->rgb "#1e1b16") (vector #x1e #x1b #x16)
                "hex with a leading #")
  (check-exn exn:fail? (lambda () (hex->rgb "kk"))
             "must reject non-hex digits")

  (define palette
    (call-with-input-file themePath read-json))

  (check-equal? (hex->rgb (palette-ref palette 'base00)) (vector #x1e #x1b #x16)
                "must read base00 out of the Stylix palette")

  (check-exn exn:fail? (lambda () (palette-ref palette 'base99))
             "must complain about an unknown base16 slot")

  (for ([row (in-list base16->drracket)])
    (check-true (and (memv (length row) '(2 3 4)) #t)
                (format "row is (entry slot props...): ~s" row)))
  (check-equal? (length base16->drracket)
                (length (remove-duplicates (map car base16->drracket)))
                "a DrRacket entry must never be mapped twice"))

;; The actual DrRacket plugin code.
(module+ main
  (require framework
           racket/class
           racket/gui/base)

  ;; Creates a color% object from a vector.
  (define (rgb->color v)
    (make-object color% (vector-ref v 0) (vector-ref v 1) (vector-ref v 2)))

  ;; A `style-delta%' carrying a foreground color, plus any font-style props the mapping asked for.
  (define (style-delta-of color props)
    (define style-delta (new style-delta%))
    (send style-delta set-delta-foreground color)
    (for ([prop (in-list props)])
      (case prop
        [(bold) (send style-delta set-delta 'change-bold)]
        [(italic) (send style-delta set-delta 'change-italic)]
        [(underline) (send style-delta set-delta 'change-underline #t)]
        [else (error 'style-delta-of "unknown style prop: ~s" prop)]))
    style-delta)

  (define (apply-base16-json path)
    (unless (file-exists? path)
      (eprintf "racket-base16: no palette was found at ~s\n" path)
      (exit 1))

    (define palette (call-with-input-file path read-json))
    (printf "read valid theme path at ~s\n" path)

    ;; Overrides are keyed by color-scheme name, but we need to also know what scheme we are applying to.
    ;; This means we override the default theme, but there is an option to reset it, so it's fine!
    (define scheme (color-prefs:get-current-color-scheme-name))

    (for ([row (in-list base16->drracket)])
      ;; the DrRacket color scheme name
      (define name (car row))
      ;; the base16 mapping
      (define slot (cadr row))
      ;; bold, italic, underline (if it's a style-delta)
      (define props (cddr row))
      (cond
        [(not (color-prefs:known-color-scheme-name? name))
         ;; Unsupported entry for this DrRacket version, so just ignore it.
         (void)]
        [else
         (define color
           (rgb->color
            (hex->rgb
             (palette-ref palette slot))))
         (define new-value
           (if (color-prefs:color-scheme-style-name? name)
               (style-delta-of color props)
               color))
         (color-prefs:set-in-color-scheme name new-value)]))

    (printf "applied base16 to DrRacket color scheme ~a\n" scheme))

  (apply-base16-json themePath)
)
