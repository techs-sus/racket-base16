# racket-base16

This is a DrRacket plugin that replaces the current color scheme's colors and
style-delta's with the base16 color configuration found in
`~/.config/stylix/palette.json`. It only supports Stylix with home-manager.

## Usage

Run:

```bash
racket -l drracket -l racket-base16
```

This loads DrRacket normally and then runs racket-base16. This is required
because DrRacket loads tools before it registers initial color schemes.
