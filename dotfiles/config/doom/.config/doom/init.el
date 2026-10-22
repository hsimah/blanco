;;; $DOOMDIR/init.el -*- lexical-binding: t; -*-

(doom! :completion
       (corfu +orderless)
       vertico
       :ui
       doom
       dashboard
       hl-todo
       modeline
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       vi-tilde-fringe
       window-select
       :editor
       (evil +everywhere)
       file-templates
       fold
       snippets
       (whitespace +guess +trim)
       :emacs
       dired
       electric
       tramp
       undo
       vc
       :checkers
       syntax
       :tools
       (eval +overlay)
       lookup
       llm
       magit
       tree-sitter
       :os
       (:if (featurep :system 'macos) macos)
       :lang
       emacs-lisp
       json
       markdown
       org
       sh
       yaml
       :config
       (default +bindings +smartparens))
