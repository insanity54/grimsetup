; Turn on syntax highlighting
;(add-hook 'c-mode-hook 'turn-on-font-lock)

; Syntax highlighting for Arduino .ino files
(add-to-list 'auto-mode-alist '("\\.ino\\'" . c-mode))